#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Criação de Rotina de Inventário                         !
+------------------+---------------------------------------------------------+
!Autor             ! David                       ! Data de Criacao ! 09/2013 !
+------------------+---------------------------------------------------------+
!Observacoes       ! Vide informação abaixo                                  !
+------------------+---------------------------------------------------------+
!Atualizações      !                                                         !
+------------------+---------------------------------------------------------+
! 15/10/18 - Luiz Poleza - reformulação de boa parte da rotina, gerando novo !
! tipo de relatório e com outra lógica para fazer a busca no banco. Também   !
! suporta inventário de produtos não previstos..                             !
+------------------+---------------------------------------------------------+
! 17/03/19 - Luiz Poleza - novo tipo de inventário por amostragem            !
+------------------+--------------------------------------------------------*/

User Function TWMSA021

	// objetos da tela
	local _oDlg01Monitor
	local _oPnl01Cabec
	local _oBmp01Planejar, _oBmp01Excluir, _oComboFil, _oBmp01Cancelar

	// lista de pergunta (parametros)
	Local _vPerg := {}

	Private _aItens    := {"TODOS","ENCERRADOS","GERADOS","INICIADOS","FINALIZADOS/EM ANALISE"}
	Private _cCmbStatus // combo status os

	// cores da legenda
	Private _aCoresLeg := {}

	// dimensoes da tela
	Private _aSizeWnd := MsAdvSize()

	// campos do browse das ordens de servico
	Private _aHdOrdServ := {}
	Private _cTrOrdServ
	Private _aStOrdServ := {}
	Private _oBrwOrdServ
	Private _cAlTrOrdServ := GetNextAlias()

	// funcao que monta os dados do operador logado no sistema
	Private _aUsrInfo := U_FtWmsOpe()

	// codigo do Operador
	Private _lUsrAccou  := (_aUsrInfo[2]=="A")
	Private _lUsrColet	:= (_aUsrInfo[2]=="C")
	Private _lUsrSuper	:= (_aUsrInfo[2]=="S")
	Private _lUsrLider	:= (_aUsrInfo[2]=="L")
	Private _lUsrGeren  := (_aUsrInfo[2]=="G")
	Private _lUsrMonit  := (_aUsrInfo[2]=="M")
	Private _cCodOper   := IIf((_lUsrMonit) .Or. (_lUsrColet), Space(6), __cUserId)
	Private _cNomOper   := Space(30) // nome do operador

	// grupo de perguntas
	private _cPerg := PadR("TWMSA021A",10)

	// Valido o usuário para acessar a rotina
	If ! ((_lUsrSuper) .Or. (_lUsrGeren) .Or. (_lUsrAccou) .Or. (_lUsrLider))
		// mensagem
		U_FtWmsMsg("Usuário sem permissão para acessar a rotina de Inventários.","Atenção")
		// retorno
		Return (.F.)
	EndIf

	// titulo da tela principal
	Private cCadastro := "Monitor de Inventários"

	// define as cores da legenda
	aAdd(_aCoresLeg,{"ALLTRIM((_cAlTrOrdServ)->STATUS) == 'GERADO'"               ,"BR_AMARELO"}) // AGUARDANDO
	aAdd(_aCoresLeg,{"ALLTRIM((_cAlTrOrdServ)->STATUS) == 'INICIADO'"             ,"ENABLE"})     // EM EXECUCAO
	aAdd(_aCoresLeg,{"ALLTRIM((_cAlTrOrdServ)->STATUS) == 'FINALIZADO/EM ANÁLISE'","BR_AZUL"})    // BLOQUEADA
	aAdd(_aCoresLeg,{"ALLTRIM((_cAlTrOrdServ)->STATUS) == 'ENCERRADO'"            ,"DISABLE"})    // EXECUTADA
	aAdd(_aCoresLeg,{"ALLTRIM((_cAlTrOrdServ)->STATUS) == 'INTERROMPIDA'"         ,"BR_PRETO"})   // INTERROMPIDA PELO OPERADOR

	// lista de perguntas (parametros)
	aAdd(_vPerg,{"Data De?"     ,"D",8                     ,0,"G",,""   , {{"X1_CNT01","'"+DtoC(dDataBase)+"'" }} }) //mv_par01
	aAdd(_vPerg,{"Data Até?"    ,"D",8                     ,0,"G",,""   , {{"X1_CNT01","'"+DtoC(dDataBase)+"'" }} }) //mv_par02
	aAdd(_vPerg,{"Cliente De?"  ,"C",TamSx3("A1_COD")[1]   ,0,"G",,"SA1", {{"X1_VALID","U_FtStrZero()"}} }) //mv_par03
	aAdd(_vPerg,{"Cliente Até?" ,"C",TamSx3("A1_COD")[1]   ,0,"G",,"SA1", {{"X1_VALID","U_FtStrZero()"}} }) //mv_par04
	aAdd(_vPerg,{"Nº OS De?"    ,"C",TamSx3("Z05_NUMOS")[1],0,"G",,""   , {{"X1_VALID","U_FtStrZero()"}} }) //mv_par05
	aAdd(_vPerg,{"Nº OS Até?"   ,"C",TamSx3("Z05_NUMOS")[1],0,"G",,""   , {{"X1_VALID","U_FtStrZero()"}} }) //mv_par06

	// cria grupo de perguntas
	U_FtCriaSX1( _cPerg, _vPerg )

	// apresenta perguntas na tela
	If ! Pergunte(_cPerg, .t.)
		Return
	EndIf

	// busca dados
	sfRfrDados( .T. )

	// monta o dialogo do monitor
	_oDlg01Monitor := MSDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"Monitor de Inventários",,,.F.,,,,,,.T.,,,.T. )
	_oDlg01Monitor:lMaximized := .T.

	// cria o panel do cabecalho (opcoes da pesquisa)
	_oPnl01Cabec := TPanel():New(000,000,nil,_oDlg01Monitor,,.F.,.F.,,,000,030,.T.,.F. )
	_oPnl01Cabec:Align:= CONTROL_ALIGN_TOP

	// -- criar os
	_oBmp01Planejar := TBtnBmp2():New(001,001,035,040,"PCO_COINC",,,,{|| sfSelType() },_oPnl01Cabec,"Criar Inventário",,.T. )
	_oBmp01Planejar:Align := CONTROL_ALIGN_LEFT
	// -- deletar os
	_oBmp01Excluir := TBtnBmp2():New(001,001,040,040,"pcofxcancel",,,,{|| sfDeletaOs(FIELDGET(1),sfRfrDados(.F.)) },_oPnl01Cabec,"Deletar OS Inventário",,.T. )
	_oBmp01Excluir:Align := CONTROL_ALIGN_LEFT
	// -- cancelar a os
	_oBmp01Cancelar := TBtnBmp2():New(001,001,040,040,"pmsinfo",,,,{|| sfCancelaOs(FIELDGET(1),sfRfrDados(.F.)) },_oPnl01Cabec,"Cancelar a OS de inventário",,.T. )
	_oBmp01Cancelar:Align := CONTROL_ALIGN_LEFT
	// -- refresh dos dados
	_oBmpRefresh := TBtnBmp2():New(001,001,040,040,"RELOAD",,,,{|| sfRfrDados(.F.) },_oPnl01Cabec,"Refresh",,.T. )
	_oBmpRefresh:Align := CONTROL_ALIGN_LEFT

	// -- mostra os finalizadas
	_cCmbStatus := _aItens[1]
	_oComboFil := TComboBox():New(009,105,{|u|if(PCount()>0,_cCmbStatus:=u,_cCmbStatus)},;
	_aItens,100,20,_oBrwOrdServ,,{||sfRfrDados(.F.)};
	,,,,.T.,,,,,,,,,'_cCmbStatus')

	// define o botao Sair
	_oBmpSair := TBtnBmp2():New(001,001,040,040,"FINAL",,,,{|| _oDlg01Monitor:End() },_oPnl01Cabec,"Sair",,.T. )
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// browse com a listagem dos servicos
	_oBrwOrdServ := MsSelect():New((_cAlTrOrdServ),,,_aHdOrdServ,,,{001,001,400,1000},,,_oDlg01Monitor,,_aCoresLeg)
	_oBrwOrdServ:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwOrdServ:oBrowse:bLdblClick := {|| MsgRun("Aguarde...",,{|| sfInfoServ( (_cAlTrOrdServ)->NUMOS ) }) } // info de serviços

	// ativa a tela
	ACTIVATE MSDIALOG _oDlg01Monitor CENTERED

	// fecha e apaga arquivos de trabalho
	If ValType(_cTrOrdServ) == "O"
		_cTrOrdServ:Delete()
	EndIf

Return ()

// seleciona o tipo do inventário que irá ser criado
Static Function sfSelType()
	local _oFntRoda := TFont():New("Tahoma",,16,,.t.)
	local _oDlgInfVlr,_oTButton

	// monta a tela para alterar seleciona o tipo de inventário
	_oDlgInfVlr := MSDialog():New(000,000,160,137,"Tipo de Inventário",,,.F.,,,,,,.T.,,,.T. )

	_oTButton := TButton():New(010,010,"Normal",_oDlgInfVlr,{||sfGeraInv(),_oDlgInfVlr:End()},050,012,,,,.T.,,"",,,,.F. )

	_oTButton := TButton():New(035,010,"Por amostragem",_oDlgInfVlr,{||sfGeraAms(),_oDlgInfVlr:End()},050,012,,,,.T.,,"",,,,.F. )

	_oTButton := TButton():New(060,010,"Cancelar",_oDlgInfVlr,{||_oDlgInfVlr:End()},050,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgInfVlr:Activate(,,,.T.,)

Return

// ** funcao para criação de inventário normal
Static Function sfGeraInv

	// grupo de perguntas (parametros)
	local _aPerg2 := {}
	local _cPerg2 := PadR("TWMSA021",10)

	// criacao das Perguntas
	aAdd(_aPerg2,{"Armazém?"          ,"C",TamSX3("BE_local")[1],  0, "G",                 ,""})
	aAdd(_aPerg2,{"Rua De?"           ,"C",2,                      0, "G",                 ,""})
	aAdd(_aPerg2,{"Rua Até?"          ,"C",2,                      0, "G",                 ,""})
	aAdd(_aPerg2,{"Lado:"             ,"N",1,                      0, "C",{"Ambos","A","B"},,})
	aAdd(_aPerg2,{"Andar De?"         ,"C",2,                      0, "G",                 ,""})
	aAdd(_aPerg2,{"Andar Até?"        ,"C",2,                      0, "G",                 ,""})
	aAdd(_aPerg2,{"Endereço De?"      ,"C",TamSX3("BE_LOCALIZ")[1],0, "G",                 ,""})
	aAdd(_aPerg2,{"Endereço Até?"     ,"C",TamSX3("BE_LOCALIZ")[1],0, "G",                 ,""})
	aAdd(_aPerg2,{"Código do Produto:","C",TamSX3("BF_PRODUTO")[1],0, "G",                 ,"SB1"})
	aAdd(_aPerg2,{"Observações:"      ,"C",30                     ,0, "G",                 ,""})
	aAdd(_aPerg2,{"Cliente?"          ,"C",TamSX3("A1_COD")[1]    ,0, "G",                 ,"SA1",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par11
	aAdd(_aPerg2,{"Loja?"             ,"C",TamSX3("A1_LOJA")[1]   ,0, "G",                 ,""})
	aAdd(_aPerg2,{"Prédio De?"        ,"C",2                      ,0, "G",                 ,""})
	aAdd(_aPerg2,{"Prédio Até?"       ,"C",2                      ,0, "G",                 ,""})

	// cria grupo de perguntas
	U_FtCriaSX1(_cPerg2, _aPerg2)

	If ! Pergunte(_cPerg2, .T.)
		Return ()
	EndIf

	// chama a rotina que mostrara os dados para inventário
	Processa({ || sfBuscaEnd(mv_par01, mv_par02, mv_par03, mv_par04, mv_par05, mv_par06, mv_par07, mv_par08, mv_par09, mv_par10, mv_par11, mv_par12, mv_par13, mv_par14) },"Gerando informações...",,.T.)

	// atualiza dados
	sfRfrDados(.f.)

Return ()

// ** funcao para criação de inventário por amostragem
Static Function sfGeraAms

	// grupo de perguntas (parametros)
	local _aPerg2 := {}
	local _cPerg2 := PadR("TWMSA021B",10)

	// criacao das Perguntas
	aAdd(_aPerg2,{"Armazem?"              ,"C",TamSX3("BE_LOCAL")[1],0, "G",,""})
	aAdd(_aPerg2,{"Cliente?"              ,"C",TamSX3("A1_COD")[1]  ,0, "G",,"SA1",{{"X1_VALID","U_FtStrZero()"}}})
	aAdd(_aPerg2,{"Loja?"                 ,"C",TamSX3("A1_LOJA")[1] ,0, "G",,""})
	aAdd(_aPerg2,{"Qtd End Gerar Invent.?","N",3,0,"G",,""})
	aAdd(_aPerg2,{"Descons. já inventariados?","N",1,0,"C",{"1 - Sim","2 - Não"},""})
	aAdd(_aPerg2,{"Qtd OS Inv. a considerar?","N",2,0,"G",,""})
	aAdd(_aPerg2,{"Observacoes:"      ,"C",30 ,0, "G", ,""})

	// cria grupo de perguntas
	U_FtCriaSX1(_cPerg2, _aPerg2)

	If ! Pergunte(_cPerg2, .T.)
		Return ()
	EndIf

	// chama a rotina que mostrara os dados para inventário
	Processa({ || sfAmostra(mv_par01, mv_par02, mv_par03, mv_par04, mv_par05, mv_par06, mv_par07) },"Gerando informações...",,.T.)

	// atualiza dados
	sfRfrDados(.f.)

Return ()

// ** funcao que filtra os enderecos disponiveis para geracao do inventario
Static Function sfBuscaEnd(mvArmazem, mvRuaDe, mvRuaAte, mvLado, mvAndarDe, mvAndarAte, mvEndComDe, mvEndComAte, mvCodPro, mvObs, mvCodCli, mvLojCli, mvPreDe, mvPreAte)

	// objetos da tela
	local _oDlg02Enderecos
	local _aBrowse := {}
	local _oBrowse := Nil
	local _oBtn02Ok, _oBtn02Cancel

	// posicao dos campos
	local _nP_CdProd := 2
	local _nP_CdEnde := 5
	local _nP_Situac := 19

	// query
	local _cQuery := ""

	// estruturas fisicas disponiveis para geracao do inventario
	local _cEstFisInv := SuperGetMv("TC_ESTFISI",.f.,"000002")

	// valida os parametros
	If (Empty(mvArmazem)) .Or. (Empty(mvObs)) .Or. (Empty(mvCodCli)) .Or. (Empty(mvLojCli))
		// mensagem
		MsgAlert("É obrigatório informar os parâmetros: Armazém, Observação, Código e Loja do Cliente!", "Parâmetros")
		// retorno
		Return(.f.)
	EndIf

	// valida se armazem existe
	dbSelectArea("SB2")
	SB2->(dbSetOrder(2)) // 2-B2_FILIAL, B2_LOCAL, B2_COD
	If ! SB2->(dbSeek( xFilial("SB2") + mvArmazem ))
		// mensagem
		MsgAlert("Código do Armazém não localizado!", "Parâmetros")
		// retorno
		Return(.f.)
	EndIf

	// valida se cliente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1)) // 1-A1_FILIAL, A1_COD, A1_LOJA
	If ! SA1->(dbSeek( xFilial("SA1") + mvCodCli + mvLojCli ))
		// mensagem
		MsgAlert("Cliente não localizado!", "Parâmetros")
		// retorno
		Return(.f.)
	EndIf

	// recebe os parâmetros para filtrar o inventário
	_cQuery := " SELECT BE_FILIAL, "
	_cQuery += "        ISNULL(BF_PRODUTO,'') BF_PRODUTO, "
	_cQuery += "        BE_LOCAL, "
	_cQuery += "        BE_PRIOR, "
	_cQuery += "        BE_LOCALIZ, "
	_cQuery += "        BF_NUMSERI, "
	_cQuery += "        BF_LOTECTL, "
	_cQuery += "        Z16_LOTCTL, "
	_cQuery += "        BF_NUMLOTE, "
	_cQuery += "        BF_QUANT, "
	_cQuery += "        Z16_SALDO, "
	_cQuery += "        BF_EMPENHO, "
	_cQuery += "        BF_QEMPPRE, "
	_cQuery += "        BF_QTSEGUM, "
	_cQuery += "        BF_EMPEN2, "
	_cQuery += "        BF_QEPRE2, "
	_cQuery += "        BF_DATAVEN, "
	_cQuery += "        BE_ESTFIS, "
	_cQuery += "        CASE WHEN BE_STATUS = '1' THEN 'VAZIO' WHEN BE_STATUS = '2' THEN 'CHEIO' WHEN BE_STATUS = '3' THEN 'BLOQUEADO' END BE_STATUS, "
	_cQuery += "        Z16_ETQPAL, "
	_cQuery += "        Z16_ETQPRD, "
	_cQuery += "        Z16_ETQVOL, "
	_cQuery += "        Z16_ETQCLI "

	// cad. de endereços
	_cQuery += " FROM " + RetSqlTab("SBE") + " (nolock) "

	// saldo de produto por endereco
	_cQuery += " LEFT JOIN " + RetSqlTab("SBF") + " (nolock) "
	_cQuery += "  ON " + RetSqlCond("SBF")
	_cQuery += "  AND BF_local = BE_local "
	_cQuery += "  AND BF_localIZ = BE_localIZ "

	// filtra somente produtos do cliente informado
	_cQuery += "  AND BF_PRODUTO IN ("
	_cQuery += "                     SELECT B1_COD FROM "+RetSqlTab("SB1")+" (nolock)  WHERE "+RetSqlCond("SB1")+" AND B1_GRUPO IN "
	_cQuery += "                     (SELECT DISTINCT A1_SIGLA FROM "+RetSqlTab("SA1")+" (nolock)  WHERE "+RetSqlCond("SA1")+" AND A1_COD = '"+mvCodCli+"') "
	_cQuery += "                    ) "

	// saldo por etiqueta
	_cQuery += "        LEFT JOIN "+RetSqlTab("Z16")+" (nolock) "
	_cQuery += "               ON "+RetSqlCond("Z16")
	_cQuery += "                  AND Z16_SALDO != 0 "
	_cQuery += "                  AND Z16_CODPRO = BF_PRODUTO "
	_cQuery += "                  AND Z16_ENDATU = BF_LOCALIZ "
	_cQuery += "                  AND Z16_LOCAL = BF_LOCAL "
	_cQuery += "                  AND Z16_LOTCTL = BF_LOTECTL "

	// filtro padrao do cadastro de enderecos
	_cQuery += " WHERE " + RetSqlCond("SBE")

	// armazém é obrigatório
	_cQuery += " AND BE_local = '" + mvArmazem + "' "

	// se o endereço o usuário definir qual endereço quer inventariar
	_cQuery += " AND BE_LOCALIZ BETWEEN '" + mvEndComDe + "' AND '" + mvEndComAte + "' "

	// rua é obrigatório
	_cQuery += " AND SUBSTRING(BE_LOCALIZ, 1, 2) BETWEEN '" + mvRuaDe + "' AND '" + mvRuaAte + "' "

	// se o lado não for selecionado, a opção AMBOS é escolhida
	If (mvLado == 2)
		_cQuery += " AND SUBSTRING(BE_LOCALIZ, 3, 1) = 'A'  "
	ElseIf (mvLado == 3)
		_cQuery += " AND SUBSTRING(BE_LOCALIZ, 3, 1) = 'B'  "
	EndIf

	// se o andar não for selecionado, a opçao TODOS é escolhida
	_cQuery += " AND SUBSTRING(BE_LOCALIZ, 6, 2) BETWEEN '"+mvAndarDe+"' AND '"+mvAndarAte+"' "

	// predio De-Ate
	_cQuery += " AND SUBSTRING(BE_LOCALIZ, 4, 2) BETWEEN '"+mvPreDe+"' AND '"+mvPreAte+"' "

	// estrutura fisica conforme parametro
	_cQuery += " AND BE_ESTFIS IN "+FormatIn(_cEstFisInv,"/")+" "

	// validação de cliente X endereço
	_cQuery += " AND BE_ZCODCLI = '"+mvCodCli+"' "

	// filtro por produto
	If (!Empty(mvCodPro))
		_cQuery += " AND BF_PRODUTO = '"+mvCodPro+"' "
	EndIf

	// ordena pela localização
	_cQuery += " ORDER BY BE_LOCALIZ ASC "

	// valida se deu certo o select
	If (Empty(_cQuery))
		// mensagem
		U_FtWmsMsg("Nenhum endereço encontrado com os dados informados!","Atenção")
		// retorn
		Return( .F. )
	EndIf

	// Gravamos o log para posterior auditoria
	memowrit("c:\query\twmsa021_sfBuscaEnd.txt",_cQuery)

	// array com elementos do browse
	_aBrowse := U_SqlToVet(_cQuery)

	// valida se deu certo o select
	If (Len(_aBrowse) == 0)
		U_FtWmsMsg("Nenhum endereço encontrado com os dados informados!","Atenção")
		Return(.f.)
	EndIf

	// cria a tela
	DEFINE DIALOG _oDlg02Enderecos TITLE "Endereços - Inventário" FROM 180,180 TO 522,700 PIXEL

	// cria browse
	_oBrowse := TCBrowse():New(01, 01, 260, 156,,{"Produtos","Endereços","Situação"},{50,50},_oDlg02Enderecos,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )

	// seta array para o browse
	_oBrowse:SetArray(_aBrowse)

	// adiciona as colunas
	_oBrowse:AddColumn( TCColumn():New('Produto'  ,{ || _aBrowse[_oBrowse:nAt,_nP_CdProd] },,,,"LEFT",,.F.,.T.,,,,.F.,) )
	_oBrowse:AddColumn( TCColumn():New('Endereço' ,{ || _aBrowse[_oBrowse:nAt,_nP_CdEnde] },,,,"LEFT",,.F.,.T.,,,,.F.,) )
	_oBrowse:AddColumn( TCColumn():New('Situação' ,{ || _aBrowse[_oBrowse:nAt,_nP_Situac] },,,,"LEFT",,.F.,.T.,,,,.F.,) )

	// cria botões
	_oBtn02Ok     := TButton():New( 160, 006, "Gerar Inventário" , _oDlg02Enderecos, {|| { sfGeraOsInv(mvArmazem, mvObs, mvCodCli, mvLojCli, _aBrowse, .F.), sfRfrDados(.F.), _oDlg02Enderecos:End()}, _oBrowse:setFocus() },60,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	_oBtn02Cancel := TButton():New( 160, 076, "Cancelar"         , _oDlg02Enderecos, {|| _oDlg02Enderecos:End() },60,010,,,.F.,.T.,.F.,,.F.,,,.F. )

	// ativa o dialogo
	ACTIVATE DIALOG _oDlg02Enderecos CENTERED

return()

// função responsável por fazer a seleção dos dados(endereços) que serão inventariados, conforme parâmetros
Static Function sfAmostra(mvArmazem, mvCodCli, mvLojCli, mvQtdEnd, mvDesInv,mvQtdDes,mvObs)

	local _aDados := {}
	local _cQuery := ""

	// estruturas fisicas disponiveis para geracao do inventario
	local _cEstFisInv := SuperGetMv("TC_ESTFISI",.f.,"000002")

	// valida os parametros
	If (Empty(mvArmazem)) .Or. (Empty(mvObs)) .Or. (Empty(mvCodCli)) .Or. (Empty(mvLojCli))
		// mensagem
		MsgAlert("É obrigatório informar os parâmetros: Armazém, Observação, Código e Loja do Cliente!", "Parâmetros")
		// retorno
		Return(.f.)
	EndIf

	// valida se armazem existe
	dbSelectArea("SB2")
	SB2->(dbSetOrder(2)) // 2-B2_FILIAL, B2_LOCAL, B2_COD
	If ! SB2->(dbSeek( xFilial("SB2") + mvArmazem ))
		// mensagem
		MsgAlert("Código do Armazém não localizado!", "Parâmetros")
		// retorno
		Return(.f.)
	EndIf

	// valida se cliente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1)) // 1-A1_FILIAL, A1_COD, A1_LOJA
	If ! SA1->(dbSeek( xFilial("SA1") + mvCodCli + mvLojCli ))
		// mensagem
		MsgAlert("Cliente não localizado!", "Parâmetros")
		// retorno
		Return(.f.)
	EndIf

	// recebe os parâmetros para filtrar o inventário
	_cQuery := " SELECT TOP "+Str(mvQtdEnd)+" BE_FILIAL, "
	_cQuery += "        ISNULL(BF_PRODUTO,'') BF_PRODUTO, "
	_cQuery += "        BE_LOCAL, "
	_cQuery += "        BE_PRIOR, "
	_cQuery += "        BE_LOCALIZ, "
	_cQuery += "        BF_NUMSERI, "
	_cQuery += "        BF_LOTECTL, "
	_cQuery += "        Z16_LOTCTL, "
	_cQuery += "        BF_NUMLOTE, "
	_cQuery += "        BF_QUANT, "
	_cQuery += "        Z16_SALDO, "
	_cQuery += "        BF_EMPENHO, "
	_cQuery += "        BF_QEMPPRE, "
	_cQuery += "        BF_QTSEGUM, "
	_cQuery += "        BF_EMPEN2, "
	_cQuery += "        BF_QEPRE2, "
	_cQuery += "        BF_DATAVEN, "
	_cQuery += "        BE_ESTFIS, "
	_cQuery += "        CASE WHEN BE_STATUS = '1' THEN 'VAZIO' WHEN BE_STATUS = '2' THEN 'CHEIO' WHEN BE_STATUS = '3' THEN 'BLOQUEADO' END BE_STATUS, "
	_cQuery += "        Z16_ETQPAL, "
	_cQuery += "        Z16_ETQPRD, "
	_cQuery += "        Z16_ETQVOL, "
	_cQuery += "        Z16_ETQCLI "

	// cad. de endereços
	_cQuery += " FROM " + RetSqlTab("SBE") + " (nolock) "

	// saldo de produto por endereco
	_cQuery += " LEFT JOIN " + RetSqlTab("SBF") + " (nolock) "
	_cQuery += "  ON " + RetSqlCond("SBF")
	_cQuery += "  AND BF_local = BE_local "
	_cQuery += "  AND BF_localIZ = BE_localIZ "

	// filtra somente produtos do cliente informado
	_cQuery += "  AND BF_PRODUTO IN ("
	_cQuery += "                     SELECT B1_COD FROM "+RetSqlTab("SB1")+" (nolock)  WHERE "+RetSqlCond("SB1")+" AND B1_GRUPO IN "
	_cQuery += "                     (SELECT DISTINCT A1_SIGLA FROM "+RetSqlTab("SA1")+" (nolock)  WHERE "+RetSqlCond("SA1")+" AND A1_COD = '"+mvCodCli+"') "
	_cQuery += "                    ) "

	// saldo por etiqueta
	_cQuery += "        LEFT JOIN "+RetSqlTab("Z16")+" (nolock) "
	_cQuery += "               ON "+RetSqlCond("Z16")
	_cQuery += "                  AND Z16_SALDO != 0 "
	_cQuery += "                  AND Z16_CODPRO = BF_PRODUTO "
	_cQuery += "                  AND Z16_ENDATU = BF_LOCALIZ "
	_cQuery += "                  AND Z16_LOCAL = BF_LOCAL "
	_cQuery += "                  AND Z16_LOTCTL = BF_LOTECTL "

	// filtro padrao do cadastro de enderecos
	_cQuery += " WHERE " + RetSqlCond("SBE")

	// armazém é obrigatório
	_cQuery += " AND BE_local = '" + mvArmazem + "' "

	// somente endereços não bloqueados
	_cQuery += " AND BE_STATUS <> '3' "

	// estrutura fisica conforme parametro
	_cQuery += " AND BE_ESTFIS IN "+FormatIn(_cEstFisInv,"/")+" "

	// validação de cliente X endereço
	_cQuery += " AND BE_ZCODCLI = '"+mvCodCli+"' "

	// Se pergunta "Desconsidera Endereçamento Inventarios" for Sim, realiza o filtro desconsiderando todos
	// os endereços utilizados em X numeros de OSs
	If mvDesInv == 1
		_cQuery += " AND be_localiz NOT IN (SELECT DISTINCT Z21_LOCALI "
		_cQuery += " 						FROM "+RetSQLName("Z21")+" Z21 (nolock)  "
		_cQuery += " 						WHERE " + RetSqlCond("Z21")
		_cQuery += " 						AND Z21_FILIAL = '"+xFilial("Z21")+"'  "
		_cQuery += " 						AND Z21_IDENT IN (SELECT TOP "+Str(mvQtdDes)+" Z06_NUMOS  "
		_cQuery += " 										  FROM "+RetSQLName("Z06")+" Z06 (nolock)  "
		_cQuery += " 											inner join "+RetSQLName("Z05")+" Z05 (nolock)  "
		_cQuery += " 											on " + RetSqlCond("Z05")
		_cQuery += " 											and Z05_FILIAL = Z05_FILIAL "
		_cQuery += " 											and Z05_CLIENT = '"+mvCodCli+"'  "
		_cQuery += " 											and Z05_LOJA = '"+mvLojCli+"' "
		_cQuery += " 											and Z05_TPOPER = 'I' "
		_cQuery += " 											and Z05_NUMOS = Z06_NUMOS "
		_cQuery += " 										  WHERE " + RetSqlCond("Z06")
		_cQuery += " 										  AND Z06_SERVIC = 'T02'  "
		_cQuery += " 										  AND Z06_TAREFA = 'T02'  "
		_cQuery += " 										  AND Z06_STATUS = 'FI' "
		_cQuery += " 										  order by Z06_NUMOS desc)) "
	EndIf

	// ordena pela localização
	_cQuery += " ORDER BY NEWID() "

	// valida se deu certo o select
	If (Empty(_cQuery))
		// mensagem
		U_FtWmsMsg("Nenhum endereço encontrado com os dados informados!","Atenção")
		// retorn
		Return( .F. )
	EndIf

	// Gravamos o log para posterior auditoria
	memowrit("c:\query\twmsa021_sfAmostra.txt",_cQuery)

	// array com elementos do browse
	_aDados := U_SqlToVet(_cQuery)

	// valida se deu certo o select
	If (Len(_aDados) == 0)
		U_FtWmsMsg("Nenhum endereço encontrado com os dados informados!","Atenção")
		Return(.f.)
	EndIf

	sfGeraOsInv(mvArmazem, mvObs, mvCodCli, mvLojCli, _aDados,.T.)

return()

// ** função para gerar inventário
Static Function sfGeraOsInv(mvArmazem, mvObs, mvCodCli, mvLojCli, mvBrowse,lInvCic)

	// numero da OS
	local _cNumId := ""

	// variavel de retorno
	local _lOk := .f.

	// variaveis temporarias
	local _nReg

	// mensagem para confirmacao
	If ( ! MsgYesNo("Confirma a geração da Ord. de Serviço do Inventário?", "Confirmação"))
		Return(_lOk)
	EndIf

	// auto-increment
	dbSelectArea("Z05")
	_cNumId := GetSXENum("Z05","Z05_NUMOS")

	// inicio da transação para não salvar se tiver erro
	BEGIN Transaction

		// percorre todos os registros da Query
		for _nReg := 1 to Len(mvBrowse)

			// grava espelho na Z21
			dbSelectArea("Z21")
			RecLock("Z21",.t.)
			Z21->Z21_FILIAL   := xFilial("Z21")
			Z21->Z21_IDENT    := _cNumId
			Z21->Z21_PROD     := mvBrowse[_nReg,  2]
			Z21->Z21_LOCAL    := mvArmazem
			Z21->Z21_PRIOR    := mvBrowse[_nReg,  4]
			Z21->Z21_LOCALIZ  := mvBrowse[_nReg,  5]
			Z21->Z21_NUMSERI  := mvBrowse[_nReg,  6]
			Z21->Z21_LOTE     := mvBrowse[_nReg,  7]
			Z21->Z21_NUMLOTE  := mvBrowse[_nReg,  9]
			Z21->Z21_QUANT    := mvBrowse[_nReg, 11]
			Z21->Z21_EMPENHO  := mvBrowse[_nReg, 12]
			Z21->Z21_QEMPPRE  := mvBrowse[_nReg, 13]
			Z21->Z21_QTSEGUM  := mvBrowse[_nReg, 14]
			Z21->Z21_EMPEN2   := mvBrowse[_nReg, 15]
			Z21->Z21_QEPRE2   := mvBrowse[_nReg, 15]
			Z21->Z21_ESTFIS   := mvBrowse[_nReg, 18]
			Z21->Z21_OBS      := mvObs
			Z21->Z21_CONTAG   := "N"
			Z21->Z21_NRCONT   := "001"
			Z21->Z21_ETQPAL   := mvBrowse[_nReg, 20]
			Z21->Z21_ETQPRD   := mvBrowse[_nReg, 21]
			Z21->Z21_ETQVOL   := mvBrowse[_nReg, 22]
			Z21->Z21_ETQCLI   := mvBrowse[_nReg, 23]
			Z21->(MsUnLock())

		Next _nReg

		// crio a Z05 para OS de Inventario
		dbSelectArea("Z05")
		RECLOCK("Z05", .T.)
		Z05->Z05_FILIAL   := xFilial("Z05")
		Z05->Z05_NUMOS    := _cNumId
		Z05->Z05_CLIENT   := mvCodCli
		Z05->Z05_LOJA     := mvLojCli
		Z05->Z05_DTEMIS   := DATE()
		Z05->Z05_HREMIS   := TIME()
		Z05->Z05_TPOPER   := "I" //I-Inventário
		Z05->(MSUNLOCK())     // Destrava o registro

		// crio a Z06 para OS de Inventario
		dbSelectArea("Z06")
		RECLOCK("Z06", .T.)
		Z06->Z06_FILIAL   := xFilial("Z06")
		Z06->Z06_NUMOS    := _cNumId
		Z06->Z06_SEQOS    := "001"
		Z06->Z06_SERVIC   := "T02" // -inventario
		Z06->Z06_TAREFA	  := "T02" // -inventario
		Z06->Z06_DTEMIS   := DATE()
		Z06->Z06_HREMIS   := TIME()
		Z06->Z06_USRINC   := __cUserId // cod user criador do inventario
		Z06->Z06_STATUS   := "AG" // esse status vai ser convertido para GERADO
		Z06->Z06_PRIOR    := "99"
		Z06->Z06_NRCONT   := "001"
		Z06->Z06_local    := mvArmazem
		Z06->Z06_ATUEST   := "N"
		Z06->Z06_ENDSRV   := "ZZZ"
		If lInvCic
			Z06->Z06_EXTRA    := "INV-C"
		EndIf
		Z06->(MSUNLOCK())     // Destrava o registro

		// criar registro na Z18 para convocação
		dbSelectArea("Z18")
		RECLOCK("Z18", .T.)
		Z18->Z18_FILIAL   := xFilial("Z18")
		Z18->Z18_NUMOS    := _cNumId
		Z18->Z18_SEQOS    := "001"
		Z18->Z18_CATEG    := "O"
		Z18->Z18_STATUS   := "P"
		Z18->Z18_FUNCAO   := "WMS01"
		Z18->(MSUNLOCK())     // Destrava o registro

		// variavel de retorno
		_lOk := .T.

	End Transaction

	// confirma auto-increment
	ConfirmSX8()

	if (_lOk)
		U_FtWmsMsg("OS de inventário gerada com sucesso! ID: "+_cNumId+"","Parabéns")
		return (.T.)
	Else
		U_FtWmsMsg("Erro ao gerar inventário, tente novamente.","Erro")
		return (.F.)
	EndIf

	Return ()

Return (.T.)

// refresh nos dados
Static Function sfRfrDados(mvFirst)
	local lRet := .f.
	MsgRun("Atualizando a Tela do Monitor de Inventários...", "Aguarde...", {|| CursorWait(), lRet := sfSelDados(mvFirst), CursorArrow()})
Return(lRet)


//** funcao para filtrar servicos de acordo com os parametros e configuracao do operador
Static Function sfSelDados(mvFirst)
	local _cQuery := ""
	// area inicial do TRB
	local _aAreaTRB := If(mvFirst,Nil,(_cAlTrOrdServ)->(GetArea()))

	// abre o alias
	dbSelectArea("Z06")

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		// define estrutura do TRB e Colunas do Browse
		aAdd(_aStOrdServ,{"NUMOS"     ,"C",   6,0}) ; aAdd(_aHdOrdServ,{"NUMOS"     ,"","Número O.S."        ,""})
		aAdd(_aStOrdServ,{"DT_EMISSAO","D",   8,0}) ; aAdd(_aHdOrdServ,{"DT_EMISSAO","","Data Emissão"       ,""})
		aAdd(_aStOrdServ,{"STATUS"    ,"C",  30,0}) ; aAdd(_aHdOrdServ,{"STATUS"    ,"","Status"             ,""})
		aAdd(_aStOrdServ,{"CLIENTE"   ,"C",  60,0}) ; aAdd(_aHdOrdServ,{"CLIENTE"   ,"","Cliente"            ,""})
		aAdd(_aStOrdServ,{"REAL"      ,"C",  15,0}) ; aAdd(_aHdOrdServ,{"REAL"      ,"","Planejado/Realizado",""})
		aAdd(_aStOrdServ,{"OBS"       ,"C", 100,0}) ; aAdd(_aHdOrdServ,{"OBS"       ,"","Observações"        ,""})

		// fecha alias do TRB
		If (Select(_cAlTrOrdServ)<>0)
			dbSelectArea(_cAlTrOrdServ)
			dbCloseArea()
		EndIf
		// criar um arquivo de trabalho
		_cTrOrdServ := FWTemporaryTable():New( _cAlTrOrdServ )
		_cTrOrdServ:SetFields( _aStOrdServ )
		_cTrOrdServ:Create()
		
	EndIf

	// limpa o conteudo do TRB
	If (!mvFirst)
		(_cAlTrOrdServ)->(dbSelectArea(_cAlTrOrdServ))
		(_cAlTrOrdServ)->(__DbZap())
	EndIf

	// recria os parametros
	Pergunte(_cPerg, .f.)

	_cQuery := " SELECT DISTINCT Z21_IDENT NUMOS, "
	_cQuery += " Z05_DTEMIS AS DT_EMISSAO, "
	_cQuery += " CASE WHEN "
	_cQuery += " Z06.Z06_STATUS = 'EX' THEN 'INICIADA' WHEN "
	_cQuery += " Z06.Z06_STATUS = 'FI' THEN 'ENCERRADA' WHEN "
	_cQuery += " Z06.Z06_STATUS = 'AG' THEN 'GERADA' WHEN "
	_cQuery += " Z06.Z06_STATUS = 'BL' THEN 'FINALIZADA/EM ANÁLISE' WHEN "
	_cQuery += " Z06.Z06_STATUS = 'CA' THEN 'CANCELADA' WHEN "
	_cQuery += " Z06.Z06_STATUS = 'IN' THEN 'INTERROMPIDA' END STATUS, "
	_cQuery += " A1_NOME CLIENTE, "
	_cQuery += " Z21.Z21_OBS OBS, "
	_cQuery += " CONVERT(VARCHAR(100), ( "
	_cQuery += " SELECT ( COUNT( DISTINCT Z21_LOCALI + Z21_ETQPAL) ) "
	_cQuery += " FROM "+RetSqlName("Z21")+" Z (nolock)  "
	_cQuery += " WHERE Z.Z21_IDENT = Z06_NUMOS "
	_cQuery += " AND Z.Z21_FILIAL = Z06_FILIAL "
	_cQuery += " AND Z.D_E_L_E_T_ = '' "
	_cQuery += " )) + ' / ' + CONVERT(VARCHAR(100), ( "
	_cQuery += " SELECT ( COUNT( DISTINCT Z21_LOCALI + Z21_ETQPAL) )"
	_cQuery += " FROM Z21010 Z (nolock)  "
	_cQuery += " WHERE Z.Z21_CONTAG = 'S' "
	_cQuery += " AND Z.Z21_IDENT = Z06_NUMOS "
	_cQuery += " AND Z.Z21_FILIAL = Z06_FILIAL "
	_cQuery += " AND Z.D_E_L_E_T_ = '' "
	_cQuery += " )) REAL "
	// programacao de inventario
	_cQuery += " FROM "+RetSqlTab("Z21")+" (nolock) "

	// cabecalho da OS
	_cQuery += "       INNER JOIN "+RetSqlTab("Z05")+" (nolock) "
	_cQuery += "               ON "+RetSqlCond("Z05")
	_cQuery += "                  AND Z05_NUMOS = Z21_IDENT "
	// filtro por cliente
	_cQuery += "                  AND Z05_CLIENT BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' "
	// filtro por data
	_cQuery += "                  AND Z05_DTEMIS BETWEEN '"+DtoS(mv_par01)+"' AND '"+DtoS(mv_par02)+"' "
	// filtro por OS
	_cQuery += "                  AND Z05_NUMOS BETWEEN '"+mv_par05+"' AND '"+mv_par06+"' "

	// cad. cliente
	_cQuery += "       LEFT JOIN "+RetSqlTab("SA1")+" (nolock) "
	_cQuery += "              ON "+RetSqlCond("SA1")
	_cQuery += "                 AND A1_COD = Z05_CLIENT "
	_cQuery += "                 AND A1_LOJA = Z05_LOJA "

	// itens da ord. servico
	_cQuery += " INNER JOIN "+RetSqlTab("Z06")+" (nolock)  ON "+RetSqlCond("Z06")+" AND Z06_NUMOS = Z21_IDENT "
	// valida status da OS
	If (!_cCmbStatus == "TODOS")
		If (_cCmbStatus == "ENCERRADOS")
			_cQuery += " AND Z06.Z06_STATUS = 'FI'
		ElseIf (_cCmbStatus == "FINALIZADOS/EM ANALISE")
			_cQuery += " AND Z06.Z06_STATUS = 'BL'
		ElseIf (_cCmbStatus == "GERADOS")
			_cQuery += " AND Z06.Z06_STATUS = 'AG'
		ElseIf (_cCmbStatus == "INICIADOS")
			_cQuery += " AND Z06.Z06_STATUS = 'EX'
		EndIf
	EndIf
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z21")
	// filtro por OS
	_cQuery += " AND Z21_IDENT BETWEEN '"+mv_par05+"' AND '"+mv_par06+"' "

	// numero da OS
	// agrupa dados
	_cQuery += " GROUP BY Z21_IDENT, Z05_DTEMIS, Z06_STATUS, A1_NOME, Z21_OBS, Z06_FILIAL, Z06_NUMOS "
	// ordem dos dados
	_cQuery += " ORDER BY Z21_IDENT "

	memowrit("c:\query\twmsa021_sfSelDados.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aStOrdServ,(_cAlTrOrdServ),{"Z05_DTEMIS"})

	// abre o arquivo de trabalho
	(_cAlTrOrdServ)->(dbSelectArea(_cAlTrOrdServ))
	If (mvFirst)
		(_cAlTrOrdServ)->(dbSelectArea(_cAlTrOrdServ))
		(_cAlTrOrdServ)->(dbGoTop())
	ElseIf (!mvFirst)
		// area inicial do TRB
		RestArea(_aAreaTRB)
	EndIf

	// refresh do browse
	If (_oBrwOrdServ <> nil)
		_oBrwOrdServ:oBrowse:Refresh()
	EndIf

Return (.T.)

// ** funcao que detalha todo o inventario
Static Function sfInfoServ(mvNumOs)

	// estrutura do arquivo de trabalho e Browse
	local _cMarcaZ21 := GetMark()
	local _cQuery   := ""
	local _aBrowse  := {}
	local _oBrowse
	local _cIdOs    := mvNumOs
	local _lValFin  := .T.

	// objetos da tela
	local _oDlgDetInvent
	local _oPnlCabec, _oPnlRodape
	local _oPnlEndere, _oPnlPrdPre, _oPnlPrdRea, _oPnlEndRight, _oPnlCabPPre, _oSayPre, _oPnlCabPRea, _oSayRea
	local _oFldDetInvent
	local _oBrwEnder, _oBrwPrdPre, _oBrwPrdRea

	// pastas do FOLDER
	local _aFolders := { 'Por Endereço' }

	// estrutura do arquivo de trabalho e Browse - Endereco
	local _aStruZ21  := {}
	local _aHeadZ21  := {}
	
	// estrutura do arquivo de trabalho e Browse - Produtos Previstos
	local _aStruPre  := {}
	local _aHeadPre  := {}
	
	// estrutura do arquivo de trabalho e Browse - Produtos Realizados
	local _aStruRea  := {}
	local _aHeadRea  := {}
	
	// css dos panels da aviso
	local _cStyle := "QFrame{ background-color:#587DA7 }"

	// cores do browse
	local _aCorEnder := {}

	// alias utilizados
	private _cTrbZ21
	private _cTrbPre
	private _cTrbRea
	private _cAlTrbZ21 := GetNextAlias()
	private _cAlTrbPre := GetNextAlias()
	private _cAlTrbRea := GetNextAlias()
	

	// numero da OS / Ident
	private _cNrOsInv := mvNumOs

	// Dados do SQL para relatório
	Private _aQryInv := {}

	//posiciona na OS
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1))
	Z06->(DBSeek(xFilial("Z06") + _cNrOsInv))

	If ( Z06->Z06_STATUS == 'CA' )
		U_FtWmsMsg("A ordem de serviço " + _cNrOsInv + " está cancelada. Não é possível ver os detalhes.","Atenção")
		Return ( .F. )
	EndIf

	// -- monta o arquivo de trabalho - Endereco
	aAdd(_aStruZ21,{"Z21_OK"     ,"C", 2                      ,0})
	aAdd(_aStruZ21,{"Z21_STATUS" ,"C", 4                      ,0})
	aAdd(_aStruZ21,{"Z21_NRCONT" ,"C", TamSx3("Z21_NRCONT")[1],0})
	aAdd(_aStruZ21,{"Z21_LOCAL"  ,"C", TamSx3("Z21_LOCAL")[1] ,0})
	aAdd(_aStruZ21,{"Z21_LOCALI" ,"C", TamSx3("Z21_LOCALI")[1],0})
	aAdd(_aStruZ21,{"Z21_ETQPAL" ,"C", TamSx3("Z21_ETQPAL")[1],0})
	
	If (Select(_cAlTrbZ21)<>0)
		dbSelectArea(_cAlTrbZ21)
		dbCloseArea()
	EndIf
	
	// criar um arquivo de trabalho
	_cTrbZ21 := FWTemporaryTable():New( _cAlTrbZ21 )
	_cTrbZ21:SetFields( _aStruZ21 )
	_cTrbZ21:Create()
	

	// define cores da legenda
	aAdd(_aCorEnder, {"AllTrim((_cAlTrbZ21)->Z21_STATUS) == 'DIVE'","BR_VERMELHO" })
	aAdd(_aCorEnder, {"AllTrim((_cAlTrbZ21)->Z21_STATUS) == 'OK'"  ,"BR_VERDE"    })
	aAdd(_aCorEnder, {"AllTrim((_cAlTrbZ21)->Z21_STATUS) == 'PEND'","BR_PRETO"    })
	aAdd(_aCorEnder, {"AllTrim((_cAlTrbZ21)->Z21_STATUS) == 'ETIQ'","BR_AMARELO"  })

	// -- define header
	aAdd(_aHeadZ21,{"Z21_OK"     ,""," "        })
	aAdd(_aHeadZ21,{"Z21_NRCONT" ,"","Nr Cont." })
	aAdd(_aHeadZ21,{"Z21_LOCAL"  ,"","Armazém"  })
	aAdd(_aHeadZ21,{"Z21_LOCALI" ,"","Endereço" })

	// -- monta o arquivo de trabalho - Produtos Previstos
	aAdd(_aStruPre,{"PRE_LOCAL"   ,"C", TamSx3("BE_local")[1]    , 0})
	aAdd(_aStruPre,{"PRE_ENDERE"  ,"C", TamSx3("BE_localIZ")[1]  , 0})
	aAdd(_aStruPre,{"PRE_CODPRO"  ,"C", TamSx3("B1_COD")[1]      , 0})
	aAdd(_aStruPre,{"PRE_DSCPRO"  ,"C", 60                       , 0})
	aAdd(_aStruPre,{"PRE_LOTE"    ,"C", TamSx3("Z21_LOTE")[1]    , 0})
	aAdd(_aStruPre,{"PRE_ETQPRD"   ,"N", TamSx3("Z21_ETQPRD")[1] , TamSx3("Z21_ETQPRD")[2]})
	aAdd(_aStruPre,{"PRE_ETQVOL"   ,"N", TamSx3("Z21_ETQVOL")[1] , TamSx3("Z21_ETQVOL")[2]})
	aAdd(_aStruPre,{"PRE_ETQCLI"   ,"N", TamSx3("Z21_ETQCLI")[1] , TamSx3("Z21_ETQCLI")[2]})
	aAdd(_aStruPre,{"PRE_QUANT"   ,"N", TamSx3("Z21_QUANT")[1]   , TamSx3("Z21_QUANT")[2]})
	aAdd(_aStruPre,{"PRE_ETQPAL"  ,"C", TamSx3("Z21_ETQPAL")[1]  , 0})

	If (Select(_cAlTrbPre)<>0)
		dbSelectArea(_cAlTrbPre)
		dbCloseArea()
	EndIf
	
	// criar um arquivo de trabalho
	_cTrbPre := FWTemporaryTable():New( _cAlTrbPre )
	_cTrbPre:SetFields( _aStruPre )
	_cTrbPre:Create()
	
	// -- define header
	aAdd(_aHeadPre,{"PRE_CODPRO", "", "Cod.Produto"})
	aAdd(_aHeadPre,{"PRE_DSCPRO", "", "Descrição"  })
	aAdd(_aHeadPre,{"PRE_LOTE"  , "", "Lote"       })
	aAdd(_aHeadPre,{"PRE_ETQPRD" , "", "Etq. Prod." })
	aAdd(_aHeadPre,{"PRE_ETQVOL" , "", "Etq. Vol." })
	aAdd(_aHeadPre,{"PRE_ETQCLI" , "", "Etq. Cli." })
	aAdd(_aHeadPre,{"PRE_QUANT" , "", "Quantidade" })

	// -- monta o arquivo de trabalho - Produtos Realizados
	aAdd(_aStruRea,{"REA_LOCAL"   ,"C", TamSx3("BE_LOCAL")[1]   , 0})
	aAdd(_aStruRea,{"REA_ENDERE"  ,"C", TamSx3("BE_LOCALIZ")[1] , 0})
	aAdd(_aStruRea,{"REA_CODPRO"  ,"C", TamSx3("B1_COD")[1]     , 0})
	aAdd(_aStruRea,{"REA_DSCPRO"  ,"C", 60                      , 0})
	aAdd(_aStruRea,{"REA_LOTE"    ,"C", TamSx3("Z19_LOTCTL")[1] , 0})
	aAdd(_aStruRea,{"REA_ETQPRD"  ,"N", TamSx3("Z21_ETQPRD")[1] , TamSx3("Z21_ETQPRD")[2]})
	aAdd(_aStruRea,{"REA_ETQVOL"  ,"N", TamSx3("Z21_ETQVOL")[1] , TamSx3("Z21_ETQVOL")[2]})
	aAdd(_aStruRea,{"REA_ETQCLI"  ,"N", TamSx3("Z21_ETQCLI")[1] , TamSx3("Z21_ETQCLI")[2]})
	aAdd(_aStruRea,{"REA_QUANT"   ,"N", TamSx3("Z21_QUANT")[1]  , TamSx3("Z21_QUANT")[2]})
	aAdd(_aStruRea,{"REA_ETQPAL"  ,"C", TamSx3("Z21_ETQPAL")[1] , 0})

	If (Select(_cAlTrbRea)<>0)
		dbSelectArea(_cAlTrbRea)
		dbCloseArea()
	EndIf
	
	// criar um arquivo de trabalho
	_cTrbRea := FWTemporaryTable():New( _cAlTrbRea )
	_cTrbRea:SetFields( _aStruRea )
	_cTrbRea:Create()

	// -- define header
	aAdd(_aHeadRea,{"REA_CODPRO" ,"","Cod.Produto"})
	aAdd(_aHeadRea,{"REA_DSCPRO" ,"","Descrição"  })
	aAdd(_aHeadRea,{"REA_LOTE"   ,"","Lote"       })
	aAdd(_aHeadRea,{"REA_ETQPRD" , "", "Etq. Prod." })
	aAdd(_aHeadRea,{"REA_ETQVOL" , "", "Etq. Vol." })
	aAdd(_aHeadRea,{"REA_ETQCLI" , "", "Etq. Cli." })
	aAdd(_aHeadRea,{"REA_QUANT"  ,"","Quantidade" })

	// funcao que prepara o resultado do inventario por endereco
	sfResPorEnd(_aStruZ21, @_lValFin)

	// abre o arquivo de trabalho
	(_cAlTrbZ21)->(dbSelectArea(_cAlTrbZ21))
	(_cAlTrbZ21)->(dbGoTop())

	// abre o arquivo de trabalho
	(_cAlTrbPre)->(dbSelectArea(_cAlTrbPre))
	(_cAlTrbPre)->(dbGoTop())

	// abre o arquivo de trabalho
	(_cAlTrbRea)->(dbSelectArea(_cAlTrbRea))
	(_cAlTrbRea)->(dbGoTop())

	// monta o dialogo
	_oDlgDetInvent := MSDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"Detalhes do Inventário - OS: " + mvNumos ,,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgDetInvent,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// cria botões cabecalho
	TButton():New( 006, 006, "Lidos"       , _oPnlCabec,{|| sfFiltraResult(@_oBrwEnder, "OK"  ) },60,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 006, 072, "Não Lidos"   , _oPnlCabec,{|| sfFiltraResult(@_oBrwEnder, "PEND") },60,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 006, 138, "Divergência" , _oPnlCabec,{|| sfFiltraResult(@_oBrwEnder, "DIVE") },60,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 006, 204, "Mostra todos", _oPnlCabec,{|| sfFiltraResult(@_oBrwEnder, "") },60,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 006, 270, "Legenda"     , _oPnlCabec,{|| sfLegenda() }                                  ,60,010,,,.F.,.T.,.F.,,.F.,,,.F. )

	// pastas com as opcoes de visualizacao
	_oFldDetInvent := TFolder():New(000,000,_aFolders,,_oDlgDetInvent,,,,.T.,,(_aSizeWnd[5]),(_aSizeWnd[6]))
	_oFldDetInvent:Align:= CONTROL_ALIGN_ALLCLIENT

	// -- 1A PASTA - POR ENDERECO

	// panel dos enderecos - esquerdo
	_oPnlEndere := TPanel():New(000,000,Nil,_oFldDetInvent:aDialogs[1],,.F.,.F.,,,(_aSizeWnd[5]/6),,.T.,.F. )
	_oPnlEndere:Align := CONTROL_ALIGN_LEFT

	// panel dos enderecos - direito
	_oPnlEndRight := TPanel():New(000,000,Nil,_oFldDetInvent:aDialogs[1],,.F.,.F.,,,(_aSizeWnd[5]/3),,.T.,.F. )
	_oPnlEndRight:Align := CONTROL_ALIGN_RIGHT

	// browse com a listagem de todos os enderecos
	_oBrwEnder := MsSelect():New((_cAlTrbZ21),"Z21_OK",,_aHeadZ21,,_cMarcaZ21,{15,1,183,373},,,_oPnlEndere,,_aCorEnder)

	_oBrwEnder:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	// filtra as informacoes conforme endereco posicionado
	_oBrwEnder:oBrowse:bChange := {|| sfFiltraEnd( (_cAlTrbZ21)->Z21_LOCAL, (_cAlTrbZ21)->Z21_LOCALIZ, @_oBrwPrdPre, @_oBrwPrdRea ) }

	// panel dos produtos previstos
	_oPnlPrdPre := TPanel():New(000,000,"TOP",_oPnlEndRight,,.F.,.F.,,,,(_aSizeWnd[6]/5),.T.,.F. )
	_oPnlPrdPre:Align := CONTROL_ALIGN_TOP

	// informativo de produtos previstos
	_oPnlCabPPre := TPanelCss():New(000,000,nil,_oPnlPrdPre,nil,nil,nil,nil,nil,,010,nil,nil)
	_oPnlCabPPre:setCSS(_cStyle)
	_oPnlCabPPre:Align := CONTROL_ALIGN_TOP

	// informativo
	_oSayPre := TSay():New(02, 02,{||' Produtos Previstos'},_oPnlCabPPre,,,,,,.T.,CLR_WHITE,,200,20)

	// ** PREVISTOS ** //
	// browse com a listagem de todos os produtos previstos
	_oBrwPrdPre := MsSelect():New((_cAlTrbPre),Nil,,_aHeadPre,,Nil,{15,1,183,373},,,_oPnlPrdPre,,)
	_oBrwPrdPre:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// panel dos produtos realizados
	_oPnlPrdRea := TPanel():New(000,000,"BOTTOM",_oPnlEndRight,,.F.,.F.,,,,(_aSizeWnd[6]/5),.T.,.F. )
	_oPnlPrdRea:Align := CONTROL_ALIGN_ALLCLIENT

	// ** REALIZADOS ** //
	// informativo de produtos realizados
	_oPnlCabPRea := TPanelCss():New(000,000,nil,_oPnlPrdRea,nil,nil,nil,nil,nil,,010,nil,nil)
	_oPnlCabPRea:setCSS(_cStyle)
	_oPnlCabPRea:Align := CONTROL_ALIGN_TOP

	// informativo
	_oSayRea := TSay():New(02, 02,{||'Produtos Inventariados'},_oPnlCabPRea,,,,,,.T.,CLR_WHITE,,200,20)

	// browse com a listagem de todos os produtos realizados
	_oBrwPrdRea := MsSelect():New((_cAlTrbRea),Nil,,_aHeadRea,,Nil,{15,1,183,373},,,_oPnlPrdRea,,)
	_oBrwPrdRea:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// cria o panel do rodape
	_oPnlRodape := TPanel():New(000,000,nil,_oDlgDetInvent,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlRodape:Align := CONTROL_ALIGN_BOTTOM

	// cria botões rodape
	TButton():New( 006, 006, "Liberar Nova Leitura", _oPnlRodape,{|| sfLibNovaLeitura() },60,010,,,.F.,.T.,.F., ,.F.,  {|| Z06->Z06_STATUS != "FI" } ,,.F. )
	TButton():New( 006, 072, "Finalizar OS"        , _oPnlRodape,{|| sfFinalizaOs(_cIdOs, _lValFin), _oDlgDetInvent:End() },60,010,,,.F.,.T.,.F.,,.F., {|| Z06->Z06_STATUS != "FI" } ,,.F. )
	TButton():New( 006, 138, "Gerar Relatório p/ conferência (Total)"   , _oPnlRodape,{|| MsgRun("Abrindo Relatório...", "Aguarde...", {|| CursorWait(), sfReport( .F. ), CursorArrow()}) },100,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 006, 244, "Gerar Relatório p/ conferência (Diverg.)" , _oPnlRodape,{|| MsgRun("Abrindo Relatório...", "Aguarde...", {|| CursorWait(), sfReport( .T. ), CursorArrow()}) },100,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 006, 350, "Gerar Relatório p/ assinar (Auditoria)"   , _oPnlRodape,{|| MsgRun("Abrindo Relatório...", "Aguarde...", {|| CursorWait(), sfReport2()    , CursorArrow()}) },100,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 006, 456, "Cancelar"            , _oPnlRodape,{|| _oDlgDetInvent:END() },60,010,,,.F.,.T.,.F.,,.F.,,,.F. )

	// ativa a tela
	ACTIVATE MSDIALOG _oDlgDetInvent CENTERED

	// fecha e apaga arquivos de trabalho
	If ValType(_cTrbZ21) == "O"
		_cTrbZ21:Delete()
	EndIf
	
	If ValType(_cTrbPre) == "O"
		_cTrbPre:Delete()
	EndIf
	
	If ValType(_cAlTrbRea) == "O"
		_cAlTrbRea:Delete()
	EndIf
	
	If ValType(_cTrbRea) == "O"
		_cTrbRea:Delete()
	EndIf

	// atualiza dados
	sfRfrDados(.F.)

Return (.T.)

// ** funcao para gerar o relatório do inventário
Static Function sfReport(mvDiverg)

	// variaveis temporarias
	local _cTmpLinha, _nTmpHdl
	local _cCodUser := ""
	local _cDscUser := ""
	local _nLinha
	local _cOcorren := ""

	// chave para verificar se gera novo bloco de endereço
	local _cChvEnd := ""

	// retorna a pasta temporaria da maquina
	local _cPathTemp := AllTrim(GetTempPath())

	// define nome do arquivo temporario
	local _cTmpArquivo := _cPathTemp + "inventario.htm"

	// diferenca na contagem
	local _nDifCont := 0

	// diferenca no lote
	local _lDifLote := .F.

	// cria e abre arquivo texto
	_nTmpHdl := fCreate(_cTmpArquivo)

	// testa se o arquivo de Saida foi Criado Corretamente
	If (_nTmpHdl == -1)
		MsgAlert("O arquivo de nome " + _cTmpArquivo + " nao pôde ser criado! Verifique os parametros e se possui permissão no sistema de arquivos.","Atenção!")
		Return( .F. )
	Endif

	// posiciona na OS do inventario
	dbSelectArea("Z05")
	Z05->(dbSetOrder(1)) // 1-Z05_FILIAL, Z05_NUMOS
	Z05->(dbSeek( xFilial("Z05") + _cNrOsInv ))

	// posiciona nos itens da OS do inventario
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	Z06->(dbSeek( xFilial("Z06") + _cNrOsInv ))

	// prepara cabecalho
	_cTmpLinha := '<table width="860px" align="center">'
	_cTmpLinha += '  <tr>'
	_cTmpLinha += '    <td>'
	_cTmpLinha += '      <table style="border-collapse: collapse;" border="1" width="100%" cellpadding="3" cellspacing="0" align="center">'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td height="30" colspan="2" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Informações do Inventário</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Empresa:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+AllTrim(Upper(SM0->M0_NOMECOM))+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Filial:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+AllTrim(Upper(SM0->M0_FILIAL))+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Número:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+_cNrOsInv+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Data de Emissão:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+DtoC(Z05->Z05_DTEMIS)+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Cliente/Loja - Nome:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+Z05->Z05_CLIENT+'/'+Z05->Z05_LOJA+'-'+AllTrim(Posicione('SA1',1, xFilial('SA1')+Z05->Z05_CLIENT+Z05->Z05_LOJA,'A1_NOME'))+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Usuário:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+AllTrim(UsrFullName(Z06->Z06_USRINC))+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Número de Contagens:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+Z06->Z06_NRCONT+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Data e Hora Inicial:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+DtoC(Z06->Z06_DTINIC)+" - "+Z06->Z06_HRINIC+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Data e Hora Final:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+DtoC(Z06->Z06_DTFIM)+" - "+Z06->Z06_HRFIM+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Ass Inventarista</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Ass Supervisor</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Ass Resp. Cliente</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Ass Gerência TECADI</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '      </table>'
	_cTmpLinha += '      <br>'
	// grava o cabeçalho no arquivo em disco
	fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))

	// gera as seções de leitura para cada linha retornada pela consulta SQL
	For _nLinha := 1 to Len(_aQryInv)
		// se deve listar apenas divergências
		If (mvDiverg)
			// se a quantidade prevista for igual a quantidade realizada, significa que não é divergente e pode pular
			IF  (_aQryInv[_nLinha][13] == _aQryInv[_nLinha][17]) 
				Loop
			EndIf
		EndIf

		// reinicia variavel que armazena as ocorrencias a cada linha
		_cOcorren := ""

		// cria tabela
		_cTmpLinha := '<table style="border-collapse: collapse;" border="1" width="100%" cellpadding="3" cellspacing="0" align="center">'
		fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))

		// se mudou o endereço, dá salto e cria novo cabeçalho para o endereço
		If (_cChvEnd != (_aQryInv[_nLinha][2] + _aQryInv[_nLinha][3])) .AND. (_aQryInv[_nLinha][1] == "1")

			If (_nLinha > 1)
				// linha separadora entre endereços próximo item
				_cTmpLinha += '<br> <br>'
				_cTmpLinha += '<hr>'
				_cTmpLinha += '<br> <br>'
			EndIf

			// atualiza chave do endereço (local + endereço)
			_cChvEnd := (_aQryInv[_nLinha][2] + _aQryInv[_nLinha][3])

			_cTmpLinha := '    <tr>'
			_cTmpLinha += '        <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="140" align="center">Armazém</td>     '
			_cTmpLinha += '        <td colspan="2" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="140" align="center">' + _aQryInv[_nLinha][2] + '  </td>   '
			_cTmpLinha += '        <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="140" align="center">Endereço</td>     '
			_cTmpLinha += '        <td colspan="5" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="140" align="center">' + _aQryInv[_nLinha][3] + '</td>   '
			_cTmpLinha += '        <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="140" align="center">Contagem</td>     '
			_cTmpLinha += '        <td colspan="2" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="140" align="center">' + _aQryInv[_nLinha][5] + '</td>   '
			_cTmpLinha += '    </tr>'
			_cTmpLinha += '<br/>'

			fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))
		EndIf

		// ---- INICIO CABEÇALHO DO PRODUTO E LOTE ----
		_cTmpLinha := '    <tr> '
		_cTmpLinha += '        <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="140" align="center">Produto</td>'
		// produto não previsto
		If( _aQryInv[_nLinha][1] == '2')
			_cOcorren  += "Produto não previsto para este endereço. "
			_cTmpLinha += '        <td colspan="5" style="font-family: Tahoma; font-size: 12px; background-color: #FFFF00; color: #000000;" width="280" align="center">' + IIf(!Empty(_aQryInv[_nLinha][7]), _aQryInv[_nLinha][7], "*Endereço vazio*") + '</td>'
		Else
			_cTmpLinha += '        <td colspan="5" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="280" align="center">' + IIf(!Empty(_aQryInv[_nLinha][7]), _aQryInv[_nLinha][7], "*Endereço vazio*") + '</td>'
		EndIf
		_cTmpLinha += '        <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="140" align="center">Lote</td>'

		If( _aQryInv[_nLinha][1] == '2')
			_cTmpLinha += '        <td colspan="5" style="font-family: Tahoma; font-size: 12px; background-color: #FFFF00; color: #000000;" width="280" align="center">' + _aQryInv[_nLinha][9] + '</td>'
		Else
			_cTmpLinha += '        <td colspan="5" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="280" align="center">' + _aQryInv[_nLinha][9] + '</td>'
		EndIf
		_cTmpLinha += '    </tr>'
		_cTmpLinha += '</table>'
		// ---- FIM CABEÇALHO DO PRODUTO E LOTE ----


		// ---- INICIO DADOS DO PRODUTO ----
		_cTmpLinha += '<table style="border-collapse: collapse;" border="1" width="100%" cellpadding="3" cellspacing="0" align="center">'
		_cTmpLinha += '        <tr>'
		_cTmpLinha += '            <td colspan="4" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="430" align="center">Previsto</td>'
		_cTmpLinha += '            <td colspan="4" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="430" align="center">Realizado</td>'
		_cTmpLinha += '        </tr> '
		_cTmpLinha += '        <tr> '
		_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="550" align="center">Etiq. Produto</td>'
		_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="550" align="center">Etiq. Volume</td>'
		_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="550" align="center">Etiq. Cliente</td>'
		_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="550" align="center">Quantidade</td>'
		_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="550" align="center">Etiq. Produto</td>'
		_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="550" align="center">Etiq. Volume</td>'
		_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="550" align="center">Etiq. Cliente</td>'
		_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="550" align="center">Quantidade</td>'
		_cTmpLinha += '        </tr>'
		_cTmpLinha += '        <tr>'
		_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="30" align="center">' + Str(_aQryInv[_nLinha][10]) + '</td>'
		_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="30" align="center">' + Str(_aQryInv[_nLinha][11]) + '</td>'
		_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="30" align="center">' + Str(_aQryInv[_nLinha][12]) + '</td>'
		_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="30" align="center">' + Str(_aQryInv[_nLinha][13]) + '</td>'

		// contagens realizadas
		If (_aQryInv[_nLinha][10] != _aQryInv[_nLinha][14] )   // etiqueta produto
			_cOcorren += " Divergência na quantidade de etiquetas de produto contadas. "
			_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #FFFF00; color: #000000;" width="30" align="center">' + Str(_aQryInv[_nLinha][14]) + '</td>'
		Else
			_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="30" align="center">' + Str(_aQryInv[_nLinha][14]) + '</td>'
		EndIf
		If (_aQryInv[_nLinha][11] != _aQryInv[_nLinha][15] )   // etiqueta volume
			_cOcorren += " Divergência na quantidade de etiquetas de volume contadas. "
			_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #FFFF00; color: #000000;" width="30" align="center">' + Str(_aQryInv[_nLinha][15]) + '</td>'
		Else
			_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="30" align="center">' + Str(_aQryInv[_nLinha][15]) + '</td>'
		Endif
		If (_aQryInv[_nLinha][12] != _aQryInv[_nLinha][16] )   // etiqueta cliente
			_cOcorren += " Divergência na quantidade de etiquetas do cliente contadas. "
			_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #FFFF00; color: #000000;" width="30" align="center">' + Str(_aQryInv[_nLinha][16]) + '</td>'
		Else
			_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="30" align="center">' + Str(_aQryInv[_nLinha][16]) + '</td>'
		EndIf	
		If (_aQryInv[_nLinha][13] != _aQryInv[_nLinha][17] )   // quantidade do SKU
			_cOcorren += " Divergência na quantidade da contagem. "
			_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #FFFF00; color: #000000;" width="30" align="center">' + Str(_aQryInv[_nLinha][17]) + '</td>'
		Else
			_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="30" align="center">' + Str(_aQryInv[_nLinha][17]) + '</td>'
		Endif
		// fim contagens realizadas

		_cTmpLinha += '        </tr>'
		_cTmpLinha += '        <tr>'
		_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="140" align="center">Ocorrências</td>'
		_cTmpLinha += '            <td colspan="11" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="280" align="center"> ' + _cOcorren + '</td>'
		_cTmpLinha += '        </tr>'
		_cTmpLinha += '        <tr>'
		_cTmpLinha += '            <td colspan="1" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="140" align="center">Divergências</td>'
		_cTmpLinha += '            <td colspan="11" style="font-family: Tahoma; font-size: 12px; color: #000000;" width="280" align="center">   </td>'
		_cTmpLinha += '        </tr>'
		_cTmpLinha += '</table>'

		// ---- FIM DADOS DO PRODUTO ----

		// grava a seção no arquivo em disco
		fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))

	Next _nLinha

	// finaliza tabela e grava no arquivo em disco
	_cTmpLinha := '</table>'  
	fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))

	// fecha arquivo
	fclose(_nTmpHdl)

	// abre o navegador
	ShellExecute("open",_cTmpArquivo,"","",5)

Return ( .T. )

// função para realizar nova leitura
Static Function sfLibNovaLeitura ()

	local _cQuery := ""
	local _cValLei := ""
	local _lRet := .t.
	// atualizado status da OS
	local _lAtuSts := .T.

	// pergunta pro usuário
	_lRet := MsgYesNo("Deseja liberar nova leitura para o(s) endereço(s) solicitado(s)?", "Nova contagem")

	If ( ! _lRet )
		Return
	EndIf

	If ( _lRet )
		// valida se pode haver alteração
		dbSelectArea("Z06")
		Z06->( dbSetOrder(1) )
		_lRet := ( Z06->( dbSeek( xFilial("Z06") + (_cAlTrOrdServ)->NUMOS ) ) )

	EndIf

	// valida se a OS está disponível para nova leitura
	If ( _lRet ) .And. ( Z06->Z06_STATUS == "BL" )

		// validação quantas vezes já foi lido aquele endereço pra aquela OS
		_cValLei := Z06->Z06_NRCONT

		// limite de 3 leituras por endereço
		If ( _cValLei == "003" )
			// informa o usuário
			U_FtWmsMsg("Só é permitido até 3 leituras por endereço.","Atenção")
			// variavel de controle
			_lRet := .f.
			// retorno
			Return(_lRet)
		EndIf

		// define numercao da proxima leitura
		_cValLei := StrZero( ( Val(_cValLei) + 1 ), 3 )

		// posiciono no inicio do registro
		(_cAlTrbZ21)->(dbGoTop())

		// varro o TRB
		While (_cAlTrbZ21)->( ! Eof() )

			// se tiver marcado
			If ( ! Empty( (_cAlTrbZ21)->Z21_OK) )

				// posiciono no endereço
				dbSelectArea("Z21")
				Z21->( dbSetOrder(8) )    //Z21_FILIAL + Z21_IDENT + Z21_LOCAL + Z21_LOCALI

				Z21->( dbSeek( _cSeekZ21 := xFilial("Z21") + Z06->Z06_NUMOS + Z06->Z06_local + (_cAlTrbZ21)->Z21_LOCALI ) )

				//itera sobre Z21 para liberar todos os volumes desse endereço
				While Z21->( ! Eof() ) .And. (Z21->(Z21_FILIAL + Z21_IDENT + Z21_LOCAL + Z21_LOCALI) == _cSeekZ21)
					// libero a nova leitura do endereço
					Reclock("Z21")
					Z21->Z21_CONTAG := "N"
					Z21->Z21_NRCONT := _cValLei
					Z21->( MsUnlock() )

					//proximo registro
					Z21->(DBSkip())
				EndDo

				// libero registro na Z06, para aparecer pro Operador
				If (_lAtuSts)
					// atualiza status
					Reclock("Z06")
					Z06->Z06_STATUS := "EX"
					Z06->Z06_NRCONT := _cValLei
					Z06->( MsUnlock() )

					// gera Log
					U_FtGeraLog(cFilAnt, "Z06", xFilial("Z06") + (_cAlTrOrdServ)->NUMOS, "Liberado nova contagem (Nr: "+_cValLei+")", "WMS", "")

					// controle de atualizacao de status
					_lAtuSts := .F.

				EndIf

			EndIf

			// prox registro
			(_cAlTrbZ21)->(dbSkip())
		EndDo

	Else
		// informa o usuário
		U_FtWmsMsg("Para realizar nova leitura, o status da OS deve estar como FINALIZADA/EM ANÁLISE.","Atenção")
		_lRet := .f.

	EndIf

	// se deu tudo certo avisa o usuário
	If ( _lRet )
		U_FtWmsMsg("Nova leitura liberada para o(s) endereço(s) informado(s).","Atenção")
	EndIf

	// volto pro primeiro registro
	(_cAlTrbZ21)->(dbGoTop())

	// refresh nos dados
	sfRfrDados(.f.)

Return

// ** funcao que valida e finaliza a OS
Static Function sfFinalizaOs (mvNumId, mvStat)

	// variaveis local
	local _cQuery := ""
	local _cCodStatus := ""

	// se o status for diferente de verde (possui divergência)
	If (!mvStat)
		U_FtWmsMsg("Os não pode ser finalizada!","Atenção")
		Return(.T.)
	EndIf

	// deseja finalizar
	If (!MsgYesNo("Deseja finalizar a OS "+mvNumId+"?", "Finaliza"))
		Return(.T.)
	EndIf

	//Query pra validar a finalização da OS
	_cQuery := " SELECT Z06_STATUS "
	_cQuery += " FROM "+RetSqlTab("Z06")+" (nolock) "
	_cQuery += " WHERE "+RetSqlCond("Z06")
	_cQuery += " AND Z06.Z06_STATUS = 'BL' "
	_cQuery += " AND Z06.Z06_NUMOS = '"+mvNumId+"' "

	memowrit("c:\query\twmsa021_sfFinalizaOs.txt",_cQuery)

	// recebe os valores da query
	_cCodStatus := U_FtQuery(_cQuery)

	If (_cCodStatus <> "BL")
		U_FtWmsMsg("OS não pode ser finalizada por possuir divergências, verifique!","Atenção")
		//Return (.F.)
	Else
		// atualiza o status do servico para FI-FINALIZADO
		U_FtWmsSta(;
		_cCodStatus,;
		"FI"       ,;
		mvNumId    ,;
		"001"       )
		// mensagem
		U_FtWmsMsg("OS finalizada com sucesso.","Atenção")
	EndIF

	// atualiza browse
	sfRfrDados(.F.)

Return (.T.)

// Deleta OS
Static Function sfDeletaOs (mvNumId)

	local _cQuery := ""
	local _nTotNok := 0

	//posiciona na OS
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1))
	Z06->(DBSeek(xFilial("Z06") + mvNumId))

	If ( Z06->Z06_STATUS == 'CA' )
		U_FtWmsMsg("Não é possível excluir uma OS já cancelada.","Atenção")
		Return (.F.)
	EndIf

	If (!MsgYesNo("Deseja deletar a OS "+mvNumId+"?", "Exclusão"))
		Return(.T.)
	EndIf

	//Query pra validar a finalização da OS
	_cQuery := " SELECT COUNT(*)"
	_cQuery += " FROM "+RetSqlName("Z19")+" Z19 (nolock)  "
	_cQuery += " WHERE Z19.Z19_FILIAL = '"+xFilial("Z19")+" '"
	_cQuery += " AND Z19.Z19_IDENT = '"+mvNumId+"' "
	_cQuery += " AND D_E_L_E_T_ = '' "

	memowrit("c:\query\TWMSA021_deletaOS.txt",_cQuery)

	// recebe os valores da query
	_nTotNok := U_FtQuery(_cQuery)

	If (_nTotNok > 0)
		U_FtWmsMsg("OS não pode ser deletada por já ter sido iniciada, verifique!","Atenção")
		//Return (.F.)
	Else
		// Posiciono na OS para finalização
		// cancelado Z06
		_cQuery := " UPDATE "+RetSqlName("Z06")+" SET D_E_L_E_T_ = '*' WHERE Z06_FILIAL = '"+xFilial("Z06")+"' AND Z06_NUMOS = '"+mvNumId+"' AND Z06_SEQOS = '001' "
		TcSQLExec(_cQuery)

		// cancelado Z05
		_cQuery := " UPDATE "+RetSqlName("Z05")+" SET D_E_L_E_T_ = '*' WHERE Z05_FILIAL = '"+xFilial("Z05")+"' AND Z05_NUMOS = '"+mvNumId+"' "
		TcSQLExec(_cQuery)

		// cancelado Z21
		_cQuery := " UPDATE "+RetSqlName("Z21")+" SET D_E_L_E_T_ = '*' WHERE Z21_FILIAL = '"+xFilial("Z21")+"' AND Z21_IDENT = '"+mvNumId+"' "
		TcSQLExec(_cQuery)

		// cancelado Z18
		_cQuery := " UPDATE "+RetSqlName("Z18")+" SET D_E_L_E_T_ = '*' WHERE Z18_FILIAL = '"+xFilial("Z18")+"' AND Z18_NUMOS = '"+mvNumId+"' "
		TcSQLExec(_cQuery)


		U_FtWmsMsg("OS deletada com sucesso.","Atenção")
	EndIF

	// atualiza browse
	sfRfrDados(.F.)

Return (.T.)

// Deleta OS
Static Function sfCancelaOS (mvNumId)

	If ( ! MsgYesNo("Deseja cancelar a OS " + mvNumId + "? Esta operação é irreversível.", "Cancelamento"))
		Return(.T.)
	EndIf

	//posiciona na OS
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1))
	Z06->(DBSeek(xFilial("Z06") + mvNumId))

	If ( Z06->Z06_STATUS != 'BL' )
		U_FtWmsMsg("OS não pode ser cancelada pois está em contagem ou em status inválido. Só é possível cancelar OS com status BLOQUEADA. Encerre a contagem e tente novamente.","Atenção")
		Return (.F.)
	Else
		//altera o status da OS para CA - cancelada
		U_FtWmsSta(Z06->Z06_STATUS,;
		"CA",;
		Z06->Z06_NUMOS,;
		Z06->Z06_SEQOS)

		//mensagem de confirmação
		U_FtWmsMsg("OS " + mvNumID + " cancelada com sucesso.","Sucesso")
	EndIF

	// atualiza browse
	sfRfrDados(.F.)

Return (.T.)

// ** funcao que filtra os enderecos conforme opcao selecionada
Static Function sfFiltraResult(mvBrowse, mvStatus)

	// seleciona o arquivo de trabalho
	(_cAlTrbZ21)->(dbSelectArea(_cAlTrbZ21))
	// cria indice e filtra
	If !(_cAlTrbZ21)->(EOF())
		(_cAlTrbZ21)->(IndRegua((_cAlTrbZ21),(_cTrbZ21),"Z21_LOCALI",, IIF(!Empty(mvStatus), "AllTrim((_cAlTrbZ21)->Z21_STATUS) == '"+mvStatus+"'" , ""),,.f.))
	EndIf
	// refresh no browse
	mvBrowse:oBrowse:Refresh()

Return

// ** funcao que prepara o resultado do inventario por endereco
Static Function sfResPorEnd(mvStruZ21, mvValFin)

	// query
	local _cQuery
	local _nLin

	// controle por endereco
	local _cChvEndere := ""

	// limpa variável que armazena resultado do sql
	_aQryInv := {}

	// monta query - preenche todos TRB´s
	_cQuery := "SELECT *                                                                                      "
	// contagens de itens previstos no inventário
	_cQuery += "FROM   (SELECT '1'                                         TIPO,                              "
	_cQuery += "               Z21.Z21_LOCAL                               LOCAL,                             "
	_cQuery += "               Z21.Z21_LOCALI                              ENDERECO,                          "
	_cQuery += "               Z21.Z21_ETQPAL                              ETQPAL,                            "
	_cQuery += "               Z21.Z21_NRCONT                              CONT,                              "
	_cQuery += "               Z21.Z21_CONTAG                              STATUS,                            "
	_cQuery += "               Z21.Z21_PROD                                PRODUTO,                           "
	_cQuery += "               SB1.B1_DESC                                 'DESC',                            "
	_cQuery += "               Z21.Z21_LOTE                                LOTE,                              "
	_cQuery += "               (SELECT COUNT(DISTINCT Z21_ETQPRD)                                             "
	_cQuery += "                FROM   " + RetSqlName("Z21") + " Z21A (nolock)  "
	_cQuery += "                WHERE  Z21A.Z21_FILIAL = Z21.Z21_FILIAL                                       "
	_cQuery += "                       AND Z21A.D_E_L_E_T_ = ''                                               "
	_cQuery += "                       AND Z21A.Z21_NRCONT = Z21.Z21_NRCONT                                   "
	_cQuery += "                       AND Z21A.Z21_LOCAL = Z21.Z21_LOCAL                                     "
	_cQuery += "                       AND Z21A.Z21_LOCALI = Z21.Z21_LOCALI                                   "
	_cQuery += "                       AND Z21A.Z21_ETQPAL = Z21.Z21_ETQPAL                                   "
	_cQuery += "                       AND Z21A.Z21_ETQPRD != ''                                              "
	_cQuery += "                       AND Z21A.Z21_LOTE = Z21.Z21_LOTE                                       "
	_cQuery += "                       AND Z21A.Z21_PROD = Z21.Z21_PROD                                       "
	_cQuery += "                       AND Z21A.Z21_IDENT = Z21.Z21_IDENT) PRE_ETQPRD,                        "
	_cQuery += "               (SELECT COUNT(DISTINCT Z21_ETQVOL)                                             "
	_cQuery += "                FROM   " + RetSqlName("Z21") + " Z21A (nolock)  "
	_cQuery += "                WHERE  Z21A.Z21_FILIAL = Z21.Z21_FILIAL                                       "
	_cQuery += "                       AND Z21A.D_E_L_E_T_ = ''                                               "
	_cQuery += "                       AND Z21A.Z21_NRCONT = Z21.Z21_NRCONT                                   "
	_cQuery += "                       AND Z21A.Z21_LOCAL = Z21.Z21_LOCAL                                     "
	_cQuery += "                       AND Z21A.Z21_LOCALI = Z21.Z21_LOCALI                                   "
	_cQuery += "                       AND Z21A.Z21_ETQPAL = Z21.Z21_ETQPAL                                   "
	_cQuery += "                       AND Z21A.Z21_IDENT = Z21.Z21_IDENT                                     "
	_cQuery += "                       AND Z21A.Z21_LOTE = Z21.Z21_LOTE                                       "
	_cQuery += "                       AND Z21A.Z21_PROD = Z21.Z21_PROD                                       "
	_cQuery += "                       AND Z21A.Z21_ETQVOL != '')          PRE_ETQVOL,                        "
	_cQuery += "               (SELECT COUNT(DISTINCT Z21_ETQCLI)                                             "
	_cQuery += "                FROM   " + RetSqlName("Z21") + " Z21A (nolock)  "
	_cQuery += "                WHERE  Z21A.Z21_FILIAL = Z21.Z21_FILIAL                                       "
	_cQuery += "                       AND Z21A.D_E_L_E_T_ = ''                                               "
	_cQuery += "                       AND Z21A.Z21_NRCONT = Z21.Z21_NRCONT                                   "
	_cQuery += "                       AND Z21A.Z21_LOCAL = Z21.Z21_LOCAL                                     "
	_cQuery += "                       AND Z21A.Z21_LOCALI = Z21.Z21_LOCALI                                   "
	_cQuery += "                       AND Z21A.Z21_ETQPAL = Z21.Z21_ETQPAL                                   "
	_cQuery += "                       AND Z21A.Z21_IDENT = Z21.Z21_IDENT                                     "
	_cQuery += "                       AND Z21A.Z21_LOTE = Z21.Z21_LOTE                                       "
	_cQuery += "                       AND Z21A.Z21_PROD = Z21.Z21_PROD                                       "
	_cQuery += "                       AND Z21A.Z21_ETQCLI != '')          PRE_ETQCLI,                        "
	_cQuery += "               (SELECT SUM(Z21_QUANT)                                                         "
	_cQuery += "                FROM   " + RetSqlName("Z21") + " Z21A (nolock)  "
	_cQuery += "                WHERE  Z21A.Z21_FILIAL = Z21.Z21_FILIAL                                       "
	_cQuery += "                       AND Z21A.D_E_L_E_T_ = ''                                               "
	_cQuery += "                       AND Z21A.Z21_NRCONT = Z21.Z21_NRCONT                                   "
	_cQuery += "                       AND Z21A.Z21_LOCAL = Z21.Z21_LOCAL                                     "
	_cQuery += "                       AND Z21A.Z21_LOCALI = Z21.Z21_LOCALI                                   "
	_cQuery += "                       AND Z21A.Z21_ETQPAL = Z21.Z21_ETQPAL                                   "
	_cQuery += "                       AND Z21A.Z21_IDENT = Z21.Z21_IDENT                                     "
	_cQuery += "                       AND Z21A.Z21_PROD = Z21.Z21_PROD                                       "
	_cQuery += "                       AND Z21A.Z21_LOTE = Z21.Z21_LOTE)   PRE_QUANT,                         "
	_cQuery += "               (SELECT COUNT(DISTINCT Z19_ETQPRO)                                             "
	_cQuery += "                FROM   " + RetSqlName("Z19") + " Z19A (nolock) "
	_cQuery += "                WHERE  Z19A.Z19_FILIAL = Z21.Z21_FILIAL                                       "
	_cQuery += "                       AND Z19A.D_E_L_E_T_ = ''                                               "
	_cQuery += "                       AND Z19A.Z19_CONTAG = Z21.Z21_NRCONT                                   "
	_cQuery += "                       AND Z19A.Z19_LOCAL = Z21.Z21_LOCAL                                     "
	_cQuery += "                       AND Z19A.Z19_ENDERE = Z21.Z21_LOCALI                                   "
	_cQuery += "                       AND (Z19A.Z19_ETQPAL = Z21.Z21_ETQPAL OR Z19A.Z19_ETQPAL = '')         "
	_cQuery += "                       AND Z19A.Z19_ETQPRO != ''                                              "
	_cQuery += "                       AND Z19A.Z19_LOTCTL = Z21.Z21_LOTE                                     "
	_cQuery += "                       AND Z19A.Z19_CODPRO = Z21.Z21_PROD                                     "
	_cQuery += "                       AND Z19A.Z19_IDENT = Z21.Z21_IDENT) REA_ETQPRD,                        "
	_cQuery += "               (SELECT COUNT(DISTINCT Z19_ETQVOL)                                             "
	_cQuery += "                FROM   " + RetSqlName("Z19") + " Z19A (nolock) "
	_cQuery += "                WHERE  Z19A.Z19_FILIAL = Z21.Z21_FILIAL                                       "
	_cQuery += "                       AND Z19A.D_E_L_E_T_ = ''                                               "
	_cQuery += "                       AND Z19A.Z19_CONTAG = Z21.Z21_NRCONT                                   "
	_cQuery += "                       AND Z19A.Z19_LOCAL = Z21.Z21_LOCAL                                     "
	_cQuery += "                       AND Z19A.Z19_ENDERE = Z21.Z21_LOCALI                                   "
	_cQuery += "                       AND (Z19A.Z19_ETQPAL = Z21.Z21_ETQPAL OR Z19A.Z19_ETQPAL = '')         "
	_cQuery += "                       AND Z19A.Z19_IDENT = Z21.Z21_IDENT                                     "
	_cQuery += "                       AND Z19A.Z19_LOTCTL = Z21.Z21_LOTE                                     "
	_cQuery += "                       AND Z19A.Z19_CODPRO = Z21.Z21_PROD                                     "
	_cQuery += "                       AND Z19A.Z19_ETQVOL != '')          REA_ETQVOL,                        "
	_cQuery += "               (SELECT COUNT(DISTINCT Z19_ETQCLI)                                             "
	_cQuery += "                FROM   " + RetSqlName("Z19") + " Z19A (nolock) "
	_cQuery += "                WHERE  Z19A.Z19_FILIAL = Z21.Z21_FILIAL                                       "
	_cQuery += "                       AND Z19A.D_E_L_E_T_ = ''                                               "
	_cQuery += "                       AND Z19A.Z19_CONTAG = Z21.Z21_NRCONT                                   "
	_cQuery += "                       AND Z19A.Z19_LOCAL = Z21.Z21_LOCAL                                     "
	_cQuery += "                       AND Z19A.Z19_ENDERE = Z21.Z21_LOCALI                                   "
	_cQuery += "                       AND (Z19A.Z19_ETQPAL = Z21.Z21_ETQPAL OR Z19A.Z19_ETQPAL = '')         "
	_cQuery += "                       AND Z19A.Z19_IDENT = Z21.Z21_IDENT                                     "
	_cQuery += "                       AND Z19A.Z19_LOTCTL = Z21.Z21_LOTE                                     "
	_cQuery += "                       AND Z19A.Z19_CODPRO = Z21.Z21_PROD                                     "
	_cQuery += "                       AND Z19A.Z19_ETQCLI != '')          REA_ETQCLI,                        "
	_cQuery += "               (SELECT ISNull(SUM(Z19_QUANT),0)                                               "
	_cQuery += "                FROM   " + RetSqlName("Z19") + " Z19A (nolock) "
	_cQuery += "                WHERE  Z19A.Z19_FILIAL = Z21.Z21_FILIAL                                       "
	_cQuery += "                       AND Z19A.D_E_L_E_T_ = ''                                               "
	_cQuery += "                       AND Z19A.Z19_CONTAG = Z21.Z21_NRCONT                                   "
	_cQuery += "                       AND Z19A.Z19_LOCAL = Z21.Z21_LOCAL                                     "
	_cQuery += "                       AND Z19A.Z19_ENDERE = Z21.Z21_LOCALI                                   "
	_cQuery += "                       AND (Z19A.Z19_ETQPAL = Z21.Z21_ETQPAL OR Z19A.Z19_ETQPAL = '')         "
	_cQuery += "                       AND Z19A.Z19_IDENT = Z21.Z21_IDENT                                     "
	_cQuery += "                       AND Z19A.Z19_LOTCTL = Z21.Z21_LOTE                                     "
	_cQuery += "                       AND Z19A.Z19_CODPRO = Z21.Z21_PROD) REA_QUANT                          "
	_cQuery += "        FROM  " + RetSqlTab("Z21")+" (nolock) "
	_cQuery += "        LEFT JOIN  " + RetSqlTab("SB1")+" (nolock) "
	_cQuery += "           ON SB1.B1_COD = Z21.Z21_PROD "
	_cQuery += "        WHERE " + RetSqlCond("Z21")
	_cQuery += "               AND Z21_IDENT = '" + _cNrOsInv + "'                                            "
	_cQuery += "        GROUP  BY Z21.Z21_LOCAL,                                                              "
	_cQuery += "                  Z21.Z21_LOCALI,                                                             "
	_cQuery += "                  Z21.Z21_ETQPAL,                                                             "
	_cQuery += "                  Z21.Z21_LOTE,                                                               "
	_cQuery += "                  Z21.Z21_NRCONT,                                                             "
	_cQuery += "                  Z21.Z21_CONTAG,                                                             "
	_cQuery += "                  Z21.Z21_FILIAL,                                                             "
	_cQuery += "                  Z21.Z21_IDENT,                                                              "
	_cQuery += "                  Z21.Z21_PROD,                                                               "
	_cQuery += "                  SB1.B1_DESC                                                                 "
	_cQuery += "        UNION ALL                                                                             "
	_cQuery += "        SELECT '2'                        TIPO,                                               "
	_cQuery += "               Z19.Z19_LOCAL              LOCAL,                                              "
	_cQuery += "               Z19.Z19_ENDERE             ENDERECO,                                           "
	_cQuery += "               Z19.Z19_ETQPAL             ETQPAL,                                             "
	_cQuery += "               MAX(Z19.Z19_CONTAG)        CONT,                                               "
	_cQuery += "               'S'                         STATUS,                                            "
	_cQuery += "               Z19.Z19_CODPRO             PRODUTO,                                            "
	_cQuery += "               SB1.B1_DESC                'DESC',                                             "
	_cQuery += "               Z19.Z19_LOTCTL             LOTE,                                               "
	_cQuery += "               0                          PRE_ETQPRD,                                         "
	_cQuery += "               0                          PRE_ETQVOL,                                         "
	_cQuery += "               0                          PRE_ETQCLI,                                         "
	_cQuery += "               0                          PRE_QUANT,                                          "
	_cQuery += "				(SELECT COUNT(DISTINCT Z19_ETQPRO)                            				  "
	_cQuery += "                FROM   " + RetSqlName("Z19") + " Z19A (nolock) "
	_cQuery += "				                WHERE  Z19A.Z19_FILIAL = Z19.Z19_FILIAL                       "
	_cQuery += "				                       AND Z19A.D_E_L_E_T_ = ''                               "
	_cQuery += "				                       AND Z19A.Z19_CONTAG = Z19.Z19_CONTAG                   "
	_cQuery += "				                       AND Z19A.Z19_LOCAL = Z19.Z19_LOCAL                     "
	_cQuery += "				                       AND Z19A.Z19_ENDERE = Z19.Z19_ENDERE                   "
	_cQuery += "				                       AND Z19A.Z19_ETQPAL = Z19.Z19_ETQPAL                   "
	_cQuery += "				                       AND Z19A.Z19_IDENT = Z19.Z19_IDENT                     "
	_cQuery += "				                       AND Z19A.Z19_LOTCTL = Z19.Z19_LOTCTL                   "
	_cQuery += "				                       AND Z19A.Z19_ETQPRO != '') REA_ETQPRD,                 "
	_cQuery += "				(SELECT COUNT(DISTINCT Z19_ETQVOL)                                            "
	_cQuery += "                FROM   " + RetSqlName("Z19") + " Z19A (nolock) "
	_cQuery += "				                WHERE  Z19A.Z19_FILIAL = Z19.Z19_FILIAL                       "
	_cQuery += "				                       AND Z19A.D_E_L_E_T_ = ''                               "
	_cQuery += "				                       AND Z19A.Z19_CONTAG = Z19.Z19_CONTAG                   "
	_cQuery += "				                       AND Z19A.Z19_LOCAL = Z19.Z19_LOCAL                     "
	_cQuery += "				                       AND Z19A.Z19_ENDERE = Z19.Z19_ENDERE                   "
	_cQuery += "				                       AND Z19A.Z19_ETQPAL = Z19.Z19_ETQPAL                   "
	_cQuery += "				                       AND Z19A.Z19_IDENT = Z19.Z19_IDENT                     "
	_cQuery += "				                       AND Z19A.Z19_LOTCTL = Z19.Z19_LOTCTL                   "
	_cQuery += "				                       AND Z19A.Z19_ETQVOL != '') REA_ETQVOL,                 "
	_cQuery += "			   (SELECT COUNT(DISTINCT Z19_ETQCLI)                                             "
	_cQuery += "                FROM   " + RetSqlName("Z19") + " Z19A (nolock) "
	_cQuery += "				                WHERE  Z19A.Z19_FILIAL = Z19.Z19_FILIAL                       "
	_cQuery += "				                       AND Z19A.D_E_L_E_T_ = ''                               "
	_cQuery += "				                       AND Z19A.Z19_CONTAG = Z19.Z19_CONTAG                   "
	_cQuery += "				                       AND Z19A.Z19_LOCAL = Z19.Z19_LOCAL                     "
	_cQuery += "				                       AND Z19A.Z19_ENDERE = Z19.Z19_ENDERE                   "
	_cQuery += "				                       AND Z19A.Z19_ETQPAL = Z19.Z19_ETQPAL                   "
	_cQuery += "				                       AND Z19A.Z19_IDENT = Z19.Z19_IDENT                     "
	_cQuery += "				                       AND Z19A.Z19_LOTCTL = Z19.Z19_LOTCTL                   "
	_cQuery += "				                       AND Z19A.Z19_ETQCLI != '') REA_ETQCLI,                 "
	_cQuery += "               IsNull(SUM(Z19_QUANT),0)             REA_QUANT                                 "
	_cQuery += "        FROM " + RetSqlTab("Z19")+" (nolock) "
	_cQuery += "        LEFT JOIN " + RetSqlTab("SB1")+" (nolock) "
	_cQuery += "           ON SB1.B1_COD = Z19.Z19_CODPRO "
	_cQuery += "        WHERE " + RetSqlCond("Z19")
	_cQuery += "               AND Z19_IDENT = '" + _cNrOsInv + "'                                            "
	_cQuery += "               AND Z19_CONTAG = (SELECT MAX(Z21_NRCONT) FROM " + RetSqlName("Z21") + " (nolock) "
	_cQuery += "                                 WHERE Z21_FILIAL = Z19_FILIAL                                "
	_cQuery += "                                    AND Z21_IDENT = Z19_IDENT                                 "
	_cQuery += "                                    AND Z21_LOCALI = Z19_ENDERE                               "
	_cQuery += "                                    AND Z19_LOCAL = Z21_LOCAL                                 "
	_cQuery += "                                    AND D_E_L_E_T_ = '')                                      "
	_cQuery += "               AND Z19_CODPRO + Z19_LOTCTL NOT IN (SELECT Z21_PROD + Z21_LOTE                 "
	_cQuery += "                                                   FROM " + RetSqlName("Z21")+" (nolock) "
	_cQuery += "                                                   WHERE  Z21_FILIAL = Z19.Z19_FILIAL         "
	_cQuery += "                                                          AND D_E_L_E_T_ = ''                 "
	_cQuery += "                                                          AND Z21_LOCAL = Z19.Z19_LOCAL       "
	_cQuery += "                                                          AND Z21_LOCALI = Z19.Z19_ENDERE)    "
	_cQuery += "        GROUP  BY Z19.Z19_LOCAL,                                                              "
	_cQuery += "                  Z19.Z19_ENDERE,                                                             "
	_cQuery += "                  Z19.Z19_ETQPAL,                                                             "
	_cQuery += "                  Z19.Z19_LOTCTL,                                                             "
	_cQuery += "                  Z19.Z19_CONTAG,                                                             "
	_cQuery += "                  Z19.Z19_FILIAL,                                                             "
	_cQuery += "                  Z19.Z19_IDENT,                                                              "
	_cQuery += "                  Z19.Z19_CODPRO,                                                             "
	_cQuery += "                  SB1.B1_DESC) AS TBL                                                         "
	_cQuery += "ORDER  BY LOCAL,      "
	_cQuery += "          ENDERECO,   "
	_cQuery += "          TIPO        "


	MemoWrit("c:\query\twmsa021_sfResPorEnd.txt",_cQuery)

	// dados temporarios
	_aQryInv := U_SqlToVet(_cQuery)

	// varre todos os itens e insere os registros na tela
	For _nLin := 1 to Len(_aQryInv)

		// verifica codigo do endereco
		If (_cChvEndere != (_aQryInv[_nLin][2] + _aQryInv[_nLin][3])) .AND. (_aQryInv[_nlin][1] == "1")

			// inclui registro do endereco
			(_cAlTrbZ21)->(dbSelectArea(_cAlTrbZ21))
			(_cAlTrbZ21)->(RecLock(_cAlTrbZ21,.t.))
			(_cAlTrbZ21)->Z21_OK     := "  "
			(_cAlTrbZ21)->Z21_LOCAL  := _aQryInv[_nLin][2]
			(_cAlTrbZ21)->Z21_LOCALI := _aQryInv[_nLin][3]
			(_cAlTrbZ21)->Z21_STATUS := "OK"                // todos endereços são inseridos como OK, e status atualizado depois nas comparações
			(_cAlTrbZ21)->Z21_ETQPAL := _aQryInv[_nLin][4]
			(_cAlTrbZ21)->Z21_NRCONT := _aQryInv[_nLin][5]
			(_cAlTrbZ21)->(MsUnLock())

			// atualiza controle de endereco
			_cChvEndere := _aQryInv[_nLin][2] + _aQryInv[_nLin][3]

		EndIf

		// inclui registro de produto previsto
		If (_aQryInv[_nLin][1] == "1") // .AND. (!Empty(_aQryInv[_nLin][7]))
			(_cAlTrbPre)->(dbSelectArea(_cAlTrbPre))
			(_cAlTrbPre)->(RecLock(_cAlTrbPre, .T.))
			(_cAlTrbPre)->PRE_LOCAL    := _aQryInv[_nLin][2]
			(_cAlTrbPre)->PRE_ENDERE   := _aQryInv[_nLin][3]
			(_cAlTrbPre)->PRE_ETQPAL   := _aQryInv[_nLin][4]
			(_cAlTrbPre)->PRE_CODPRO   := IIf(!Empty(_aQryInv[_nLin][7]), _aQryInv[_nLin][7] , "Vazio")
			(_cAlTrbPre)->PRE_DSCPRO   := IIf(!Empty(_aQryInv[_nLin][8]), _aQryInv[_nLin][8] , "Endereço previsto como vazio") 
			(_cAlTrbPre)->PRE_LOTE     := _aQryInv[_nLin][9]
			(_cAlTrbPre)->PRE_ETQPRD    := _aQryInv[_nLin][10]
			(_cAlTrbPre)->PRE_ETQVOL    := _aQryInv[_nLin][11]
			(_cAlTrbPre)->PRE_ETQCLI    := _aQryInv[_nLin][12]
			(_cAlTrbPre)->PRE_QUANT    := _aQryInv[_nLin][13]
			(_cAlTrbPre)->(MsUnLock())
		EndIf

		// inclui registros dos produtos inventariados (previstos ou não)
		// caso tenha ao menos uma leitura de qualquer tipo de etiqueta ou saldo
		If ( (_aQryInv[_nLin][14] != 0) .OR. (_aQryInv[_nLin][15] != 0) .OR. (_aQryInv[_nLin][16] != 0) .OR. (_aQryInv[_nLin][17] != 0) )
			(_cAlTrbRea)->(dbSelectArea(_cAlTrbRea))
			(_cAlTrbRea)->(RecLock(_cAlTrbRea, .T.))
			(_cAlTrbRea)->REA_LOCAL    := _aQryInv[_nLin][2]
			(_cAlTrbRea)->REA_ENDERE   := _aQryInv[_nLin][3]
			(_cAlTrbRea)->REA_ETQPAL   := _aQryInv[_nLin][4]
			(_cAlTrbRea)->REA_CODPRO   := IIf(!Empty(_aQryInv[_nLin][7]), _aQryInv[_nLin][7] , "Vazio")
			(_cAlTrbRea)->REA_DSCPRO   := _aQryInv[_nLin][8]
			(_cAlTrbRea)->REA_LOTE     := _aQryInv[_nLin][9]
			(_cAlTrbRea)->REA_ETQPRD   := _aQryInv[_nLin][14]
			(_cAlTrbRea)->REA_ETQVOL   := _aQryInv[_nLin][15]
			(_cAlTrbRea)->REA_ETQCLI   := _aQryInv[_nLin][16]
			(_cAlTrbRea)->REA_QUANT    := _aQryInv[_nLin][17]
			(_cAlTrbRea)->(MsUnLock())
			// caso endereço lido vazio (todos os resultados = 0)
		Elseif   ( (_aQryInv[_nLin][1] == "2") .AND. (_aQryInv[_nLin][14] == 0) .AND. (_aQryInv[_nLin][15] == 0) .AND. (_aQryInv[_nLin][16] == 0) .AND. (_aQryInv[_nLin][17] == 0) )
			(_cAlTrbRea)->(dbSelectArea(_cAlTrbRea))
			(_cAlTrbRea)->(RecLock(_cAlTrbRea, .T.))
			(_cAlTrbRea)->REA_LOCAL    := _aQryInv[_nLin][2]
			(_cAlTrbRea)->REA_ENDERE   := _aQryInv[_nLin][3]
			(_cAlTrbRea)->REA_CODPRO   := "Vazio"
			(_cAlTrbRea)->REA_DSCPRO   := "Endereço lido como vazio"
			(_cAlTrbRea)->(MsUnLock())
		EndIf

		// ---------   atualiza o status das divergencias    ---------

		// se endereço foi realizado inventário
		If ( (AllTrim(_aQryInv[_nLin][6]) == "S") )
			//			IF ((AllTrim(_aTmpDados[_nLin][4]) != AllTrim(_aTmpDados[_nLin][8])) .Or. (AllTrim(_aTmpDados[_nLin][6]) != AllTrim(_aTmpDados[_nLin][10])) .Or. (_aTmpDados[_nLin][7] != _aTmpDados[_nLin][11])) )

			// se quantidade prevista é diferente da quantidade realizada
			IF  (_aQryInv[_nLin][13] != _aQryInv[_nLin][17])
				// atualiza campo (continuo posicionado no mesmo endereço)
				(_cAlTrbZ21)->(dbSelectArea(_cAlTrbZ21))
				(_cAlTrbZ21)->(RecLock(_cAlTrbZ21))
				(_cAlTrbZ21)->Z21_STATUS := "DIVE"
				(_cAlTrbZ21)->(MsUnLock())

				// validacao geral do inventario / nao permite finalizar
				mvValFin := .F.
				// se quantidade prevista bate com a quantidade realizada, mas diverge na quantidade de etiquetas
			ElseIf (_aQryInv[_nLin][13] == _aQryInv[_nLin][17]) .AND. (( _aQryInv[_nLin][10] != _aQryInv[_nLin][14]) .OR. (_aQryInv[_nLin][11] != _aQryInv[_nLin][15]) .OR. (_aQryInv[_nLin][12] != _aQryInv[_nLin][16]))
				// atualiza campo (continuo posicionado no mesmo endereço)
				(_cAlTrbZ21)->(dbSelectArea(_cAlTrbZ21))
				(_cAlTrbZ21)->(RecLock(_cAlTrbZ21))
				(_cAlTrbZ21)->Z21_STATUS := "ETIQ"
				(_cAlTrbZ21)->(MsUnLock())

				// validacao geral do inventario / nao permite finalizar
				//				mvValFin := .F.
			EndIf
			// endereco nao contado / pendente
		ElseIf ( AllTrim(_aQryInv[_nLin][6]) == "N" )
			// atualiza campo
			(_cAlTrbZ21)->(dbSelectArea(_cAlTrbZ21))
			(_cAlTrbZ21)->(RecLock(_cAlTrbZ21))
			(_cAlTrbZ21)->Z21_STATUS := "PEND"
			(_cAlTrbZ21)->(MsUnLock())
			// validacao geral do inventario / nao permite finalizar
			mvValFin := .F.

		EndIf

	Next _nLin

Return

// ** funcao para filtrar os dados
Static Function sfFiltraEnd(mvlocal, mvlocaliz, mvBrwPrdPre, mvBrwPrdRea)

	// filtra produtos planejados/previstos
	(_cAlTrbPre)->(dbSelectArea(_cAlTrbPre))
	(_cAlTrbPre)->(DbGoTop())
	If !(_cAlTrbPre)->(EOF())
		(_cAlTrbPre)->(IndRegua((_cAlTrbPre),(_cTrbPre),"PRE_LOCAL+PRE_ENDERE+PRE_ETQPAL",,;
		(_cAlTrbPre) + '->PRE_LOCAL  == "' + mvlocal    + '" .And. ' + ;
		(_cAlTrbPre) + '->PRE_ENDERE == "' + mvlocaliz  + '"',;
		"Selecionando Registros...",.f.))
	EndIf


	// atualiza browse
	mvBrwPrdPre:oBrowse:Refresh()

	// filtra produtos realizados / inventariados
	(_cAlTrbRea)->(dbSelectArea(_cAlTrbRea))
	(_cAlTrbRea)->(DbGoTop())
	If !(_cAlTrbRea)->(EOF())
		(_cAlTrbRea)->(IndRegua((_cAlTrbRea),(_cTrbRea),"REA_LOCAL+REA_ENDERE+REA_ETQPAL",,;
		(_cAlTrbRea)+'->REA_LOCAL  == "' + mvlocal    + '" .And. ' + ;
		(_cAlTrbRea)+'->REA_ENDERE == "' + mvlocaliz  + '"',;
		"Selecionando Registros...",.f.))
	EndIf
	
	// atualiza browse
	mvBrwPrdRea:oBrowse:Refresh()

Return

// ** funcao responsavel por exibir a legenda
Static Function sfLegenda
	BrwLegenda(cCadastro, "Status",;
	{{"BR_VERDE"	,"OK - Sem divergências"},;
	{"BR_AMARELO"	,"Saldo OK, porém divergência na quantidade de etiquetas"},;
	{"BR_VERMELHO"	,"Divergência (qualquer tipo)"},;
	{"BR_PRETO","Pendente de inventário"}})
Return


// ** funcao auxiliar para gerar relatório no formato antigo (inventário 1.0)
// utilizado para imprimir e assinar (para auditorias do cliente)
Static Function sfReport2()

	// variaveis temporarias
	local _cTmpLinha, _nTmpHdl
	local _cCodUser := ""
	local _cDscUser := ""
	local _nExc

	// retorna a pasta temporaria da maquina
	local _cPathTemp := AllTrim( GetTempPath() )

	// define nome do arquivo temporario
	local _cTmpArquivo := _cPathTemp + "inventario.htm"

	// diferenca na contagem
	local _nDifCont := 0

	// diferenca no lote
	local _lDifLote := .F.

	// variavel para receber o retorno do SQL
	local _aDadExcel := {}

	// cria e abre arquivo texto
	_nTmpHdl := fCreate(_cTmpArquivo)

	// testa se o arquivo de Saida foi Criado Corretamente
	If (_nTmpHdl == -1)
		MsgAlert(,"Atencao!")
		Help( Nil, Nil, 'TWMSA021.SFREPORT02.001', Nil, "O arquivo de nome " + _cTmpArquivo + " nao pode ser criado!", 1, 0, Nil, Nil, Nil, Nil, Nil,;
		{"Verifique se possui permissão na pasta selecionada."})      
		Return( .F. )
	Endif

	// posiciona na OS do inventario
	dbSelectArea("Z05")
	Z05->(dbSetOrder(1)) // 1-Z05_FILIAL, Z05_NUMOS
	Z05->(dbSeek( xFilial("Z05") + _cNrOsInv ))

	// posiciona nos itens da OS do inventario
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	Z06->(dbSeek( xFilial("Z06") + _cNrOsInv ))

	// consulta inventário realizado X previsto (inventário modelo 1.0 - relatório anterior)
	_cQuery := " SELECT Z21_LOCAL                  ARMAZEM, "
	_cQuery += "        Z21_LOCALI                 ENDERECO, "
	_cQuery += "        Z21_PROD                   PRE_PRODUTO, "
	_cQuery += "        Isnull(SB1PRE.B1_DESC, '') PRE_DSCPROD, "
	_cQuery += "        SUM(Z21_QUANT)             PRE_QUANT, "
	_cQuery += "        Isnull(Z19_CODPRO, '')     REA_PRODUTO, "
	_cQuery += "        Isnull(SB1REA.B1_DESC, '') REA_DSCPROD, "
	_cQuery += "        Isnull(Sum(Z19_QUANT), 0)  REA_QUANT, "
	_cQuery += "        Z21_LOTE                   PRE_LOTE, "
	_cQuery += "        Isnull(Z19_LOTCTL, '')     REA_LOTE, "
	_cQuery += "        CAST( Isnull(Z19_USER, '') AS VARCHAR)       Z19_USER, "
	_cQuery += "        Case When DCD_NOMFUN IS NULL Then 'Cadastrar ID no WMS: '+Z19_USER Else DCD_NOMFUN End as NOME "
	// previsao de inventario
	_cQuery += " FROM   " + RetSqlTab("Z21") + " (NOLOCK) "
	// contagem realizada
	_cQuery += "        LEFT JOIN " + RetSqlTab("Z19") + " (NOLOCK) "
	_cQuery += "               ON " + RetSqlCond("Z19")
	//considera somente a ultima contagem do item (correção chamado 12252 - 26/12/16) - Luiz Poleza
	//melhoria no SQL (correção chamado 12295 - 02/01/17) - Luiz Poleza
	_cQuery += "                  AND Z19.Z19_CONTAG = Z21_NRCONT "
	_cQuery += "                  AND Z19_IDENT = Z21_IDENT "
	_cQuery += "                  AND Z19_LOCAL = Z21_LOCAL "
	_cQuery += "                  AND Z19_ENDERE = Z21_LOCALI "
	_cQuery += "				  AND ( ( Z19_CODPRO = Z21_PROD )"
	_cQuery += "                      OR ( Z19_CODPRO = ''  AND Z19_CODPRO != Z21_PROD ) "
	_cQuery += "                      OR ( Z21_PROD = '' AND Z19_CODPRO != Z21_PROD )   "
	_cQuery += "                      OR ( Z19_CODPRO != Z21_PROD) )  "
	_cQuery += "                  AND ( ( Z19_LOTCTL = Z21_LOTE )"
	_cQuery += "                      OR ( Z19_LOTCTL = '' AND Z19_LOTCTL != Z21_LOTE )  "
	_cQuery += "                      OR ( Z21_LOTE = ''   AND Z19_LOTCTL != Z21_LOTE ) "
	_cQuery += "                      OR ( Z19_LOTCTL != Z21_LOTE ) ) "
	_cQuery += "				  AND ( (Z19_ETQPAL = Z21_ETQPAL) "
	_cQuery += "				      OR (Z19_ETQPAL != '' AND Z21_ETQPAL = '') ) "     // caso seja lido algo, mas é esperado vazio na 21, não terá pallet
	// compara etiqueta de volume
	_cQuery += " AND ( ( Z19_ETQVOL = Z21_ETQVOL )         "
	_cQuery += "        OR ( Z19_ETQVOL != ''              "
	_cQuery += "             AND Z21_ETQVOL = ''           "
	_cQuery += "             AND Z19_DATA <= '20190101'    "
	_cQuery += "     ))"
	// compara etiqueta de produto
	_cQuery += " AND ( ( Z19_ETQPRO = Z21_ETQPRD )         "
	_cQuery += "        OR ( Z19_ETQPRO != ''              "
	_cQuery += "             AND Z21_ETQPRD = ''           "
	_cQuery += "             AND Z19_DATA <= '20190101'"
	_cQuery += "     ))"
	// compara etiqueta de cliente
	_cQuery += " AND ( ( Z19_ETQCLI = Z21_ETQCLI )         "
	_cQuery += "        OR ( Z19_ETQCLI != ''              "
	_cQuery += "             AND Z21_ETQCLI = ''           "
	_cQuery += "             AND Z19_DATA <= '20190101'"
	_cQuery += "     ))"
	// descricao do produto previsto
	_cQuery += "        LEFT JOIN " + RetSqlName("SB1") + " SB1PRE (NOLOCK)"
	_cQuery += "               ON SB1PRE.B1_FILIAL = '" + xFilial("SB1") + "' "
	_cQuery += "                  AND SB1PRE.D_E_L_E_T_ = ' ' "
	_cQuery += "                  AND SB1PRE.B1_COD = Z21_PROD "
	// descricao do produto realizado
	_cQuery += "        LEFT JOIN " + RetSqlName("SB1") + " SB1REA (NOLOCK)" 
	_cQuery += "               ON SB1REA.B1_FILIAL = '" + xFilial("SB1") + "' "
	_cQuery += "                  AND SB1REA.D_E_L_E_T_ = ' ' "
	_cQuery += "                  AND SB1REA.B1_COD = Z19_CODPRO "
	// pega o nome de usuário
	_cQuery += "        LEFT JOIN " + RetSqlName("DCD") + " DCD (NOLOCK) "
	_cQuery += "               ON DCD.D_E_L_E_T_ = '' "
	_cQuery += "               AND DCD_CODFUN = Z19_USER "
	// filtro padrao
	_cQuery += " WHERE  "+RetSqlCond("Z21") 
	// numero da OS
	_cQuery += "        AND Z21_IDENT = '" + _cNrOsInv + "' "
	// compara codigo de produto
	_cQuery += "        AND ( ( Z21_PROD IN ( NULL, '', Z19_CODPRO, Z21_PROD ) ) "
	_cQuery += "               OR ( Z21_PROD <> Z19_CODPRO ) ) "
	// compara lotes
	_cQuery += "        AND ( ( Z21_LOTE IN ( NULL, '', Z19_LOTCTL, Z21_LOTE ) ) "
	_cQuery += "               OR ( Z21_LOTE <> Z19_LOTCTL ) ) "
	// agrupa dados
	_cQuery += " GROUP  BY Z21_IDENT, "
	_cQuery += "           Z21_LOCAL, "
	_cQuery += "           Z21_LOCALI, "
	_cQuery += "           Z21_CONTAG, "
	_cQuery += "           Z21_PROD, "
	_cQuery += "           SB1PRE.B1_DESC, "
	_cQuery += "           Z21_LOTE, "
	_cQuery += "           Z21_QUANT, "
	_cQuery += "           Z19_CODPRO, "
	_cQuery += "           SB1REA.B1_DESC, "
	_cQuery += "           Z19_LOTCTL, "
	_cQuery += "           Z19_USER, "
	_cQuery += "           Z21_NRCONT, "
	_cQuery += "           Z21_ETQPAL, "
	_cQuery += "           Z19_ETQPAL, "
	_cQuery += "           Z19_ETQVOL, "
	_cQuery += "           Z21_ETQVOL, "
	_cQuery += "           DCD_NOMFUN "
	// ordenação
	_cQuery += " ORDER  BY Z21_LOCAL, "
	_cQuery += "           Z21_LOCALI, "
	_cQuery += "           Z21_PROD, "
	_cQuery += "           Z21_LOTE "

	MemoWrit("C:\QUERY\TWMSA021_sfreport2.txt", _cQuery)

	_aDadExcel := U_SqlToVet(_cQuery)

	// estrutura variavel: _aDadExcel
	//  1-Local/Armazem
	//  2-Endereço
	//  3-Prod.Previsto
	//  4-Desc.Previsto
	//  5-Qtd.Previsto
	//  6-Prod.Realizado
	//  7-Desc.Realizado
	//  8-Qtd.Realizado
	//  9-Lote Previsto
	// 10-Lote Realizado
	// 11-Usuário

	// prepara cabecalho
	_cTmpLinha := '<table width="860px" align="center">'
	_cTmpLinha += '  <tr>'
	_cTmpLinha += '    <td>'
	_cTmpLinha += '      <table style="border-collapse: collapse;" border="1" width="100%" cellpadding="3" cellspacing="0" align="center">'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td height="30" colspan="2" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Informações do Inventário</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Empresa:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+AllTrim(Upper(SM0->M0_NOMECOM))+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Filial:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+AllTrim(Upper(SM0->M0_FILIAL))+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Número:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+_cNrOsInv+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Data de Emissão:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+DtoC(Z05->Z05_DTEMIS)+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Cliente/Loja - Nome:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+Z05->Z05_CLIENT+'/'+Z05->Z05_LOJA+'-'+AllTrim(Posicione('SA1',1, xFilial('SA1')+Z05->Z05_CLIENT+Z05->Z05_LOJA,'A1_NOME'))+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Usuário:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+AllTrim(UsrFullName(Z06->Z06_USRINC))+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Número de Contagens:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+Z06->Z06_NRCONT+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Data e Hora Inicial:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+DtoC(Z06->Z06_DTINIC)+" - "+Z06->Z06_HRINIC+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Data e Hora Final:</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;'+DtoC(Z06->Z06_DTFIM)+" - "+Z06->Z06_HRFIM+'</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Ass Inventarista</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Ass Supervisor</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Ass Resp. Cliente</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Ass Gerência TECADI</td>'
	_cTmpLinha += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '      </table>'
	_cTmpLinha += '      <br>'

	// grava a Linha no Arquivo Texto
	fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))

	// prepara 1a linha do cabecalho dos itens
	_cTmpLinha := '      <table style="border-collapse: collapse;" border="1" width="100%" cellpadding="3" cellspacing="0" align="center">'
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td colspan="2" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="120" align="center">Localização</td>'
	_cTmpLinha += '          <td colspan="4" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="370" align="center">Previsto</td>'
	_cTmpLinha += '          <td colspan="6" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="530" align="center">Realizado</td>'
	_cTmpLinha += '        </tr>'

	// grava a Linha no Arquivo Texto
	fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))

	// prepara 2a linha do cabecalho dos itens
	_cTmpLinha := '        <tr>'
	_cTmpLinha += '          <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="30">Armazém</td>'
	_cTmpLinha += '          <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="90">Endereço</td>'
	_cTmpLinha += '          <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="90">Produto</td>'
	_cTmpLinha += '          <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="120">Descrição</td>'
	_cTmpLinha += '          <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="80">Quantidade</td>'
	_cTmpLinha += '          <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="80">Lote</td>'
	_cTmpLinha += '          <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="90">Produto</td>'
	_cTmpLinha += '          <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="120">Descrição</td>'
	_cTmpLinha += '          <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="80">Quantidade</td>'
	_cTmpLinha += '          <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="80">Lote</td>'
	_cTmpLinha += '          <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="80">Diferença</td>'
	_cTmpLinha += '          <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="80">Usuário</td>'
	_cTmpLinha += '        </tr>'

	// grava a Linha no Arquivo Texto
	fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))

	// varre todos os itens pra gerar cada linha
	For _nExc := 1 to Len(_aDadExcel)

		// diferenca na contagem
		_nDifCont := _aDadExcel[_nExc][8] - _aDadExcel[_nExc][5]

		//lote diferente
		_lDifLote := ( AllTrim(_aDadExcel[_nExc][9]) != AllTrim( _aDadExcel[_nExc][10] ) )

		// atualiza nome do usuario
		If ( _cCodUser != _aDadExcel[_nExc][11] )
			// nome
			_cDscUser := _aDadExcel[_nExc][12]
		EndIf

		//Adiciona Linha para exportar informações para o Excel.
		_cTmpLinha := '<tr>'
		_cTmpLinha += '  <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="30" align="center">' + AllTrim(_aDadExcel[_nExc][1]) + '</td>'
		_cTmpLinha += '  <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="90">' + AllTrim(_aDadExcel[_nExc][2]) + '</td>'
		_cTmpLinha += '  <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="90">' + AllTrim(_aDadExcel[_nExc][3]) + '</td>'
		_cTmpLinha += '  <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="120">' + AllTrim(_aDadExcel[_nExc][4]) + '</td>'
		_cTmpLinha += '  <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="80" align="center">' + AllTrim(Transf(_aDadExcel[_nExc][5],PesqPict('Z21','Z21_QUANT'))) + '</td>'

		//lote previsto
		_cTmpLinha += '  <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="80" align="center">' + AllTrim( _aDadExcel[_nExc][9] ) + '</td>'

		_cTmpLinha += '  <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="90" >' + AllTrim(_aDadExcel[_nExc][6]) + '</td>'
		_cTmpLinha += '  <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="120" >' + AllTrim(_aDadExcel[_nExc][7]) + '</td>'
		_cTmpLinha += '  <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="80" align="center">' + AllTrim(Transf(_aDadExcel[_nExc][8],PesqPict('Z21','Z21_QUANT'))) + '</td>'

		//lote realizado
		_cTmpLinha += '  <td style="font-family: Tahoma; font-size: 12px; ' + IIf( _lDifLote , 'background-color: #FFFF00;', '') + 'color: #000000;" width="80" align="center">' + AllTrim( _aDadExcel[_nExc][10] ) + '</td>'

		_cTmpLinha += '  <td style="font-family: Tahoma; font-size: 12px; ' + IIf(_nDifCont != 0, 'background-color: #FFFF00;', '') + 'color: #000000;" width="80" align="center">' + AllTrim(Transf(_nDifCont,PesqPict('Z21','Z21_QUANT'))) + '</td>'
		_cTmpLinha += '  <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="80">' + AllTrim(_cDscUser) + '</td>'
		_cTmpLinha += '</tr>'
		// grava a Linha no Arquivo Texto
		fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))

	Next _nExc

	// finaliza o arquivo
	_cTmpLinha := '      </table>'
	_cTmpLinha += '    </td>'
	_cTmpLinha += '  </tr> '
	_cTmpLinha += '</table> '
	_cTmpLinha += '</table> '

	// grava a Linha no Arquivo Texto
	fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))

	// fecha arquivo
	fclose(_nTmpHdl)

	// abre o navegador
	ShellExecute("open",_cTmpArquivo,"","",5)

Return



