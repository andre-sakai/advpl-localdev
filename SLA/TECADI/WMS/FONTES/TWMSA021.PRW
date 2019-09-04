#Include "Totvs.ch"
#Include "tbiconn.ch"
#Include "topconn.ch"

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
! 14/08/2019 - Andre Sakai - melhoria para tratar os casos de divergência de !
! inventário                                                                 !
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
	TButton():New( 006, 456, "Verificar Divergencias"   , _oPnlRodape,{|| MsgRun("Verificando...", "Aguarde...", {|| CursorWait(), sfPreComPR()    , CursorArrow()}) },060,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 006, 522, "Cancelar"            , _oPnlRodape,{|| _oDlgDetInvent:END() },060,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 006, 588, "advplexec"   , _oPnlRodape,{|| U_ADVPLEXEC()},060,010,,,.F.,.T.,.F.,,.F.,,,.F. )	

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
	If !(_cAlTrbRea)->(EOF()) // comentado -- caso não tenha o realizado não atualiza mais a grid
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


Static Function sfPreComPR()
	Local _xAlias2 := getnextalias()
	Local _aArea := getArea()
	Local _lRet := .T.
	Local _xIdent  := Z06->Z06_NUMOS

	Local cNomeArqD := ''
	Local _aStru:={}
	Local _aCpoBro := {}
	Local _oDlg
	Local _aCores := {}
	
	Local aSize, aObjects
	
	Private _xAlias  := getnextalias()
	Private _lInverte := .F.
	Private _cMark   := GetMark()   
	Private _oMark  
	Private _oMarkB
	Private nOpcA := 0
	Private _aReg :={}
//	Private _aConf :={}
	
	Private oConfDiv
	
	_aStru	:=   {{"OK"	    ,"C",02,0},;
				  { "FILIAL","C",TamSX3('Z19_FILIAL')[1],0},;
				  { "CODIGO","C",TamSX3('Z19_IDENT')[1],0},;
				  { "LOCAL","C",TamSX3('Z19_LOCAL')[1],0},;
				  { "ENDERECO","C",TamSX3('Z19_ENDERE')[1],0},;
				  { "PRODUTO","C",TamSX3('Z19_CODPRO')[1],0},;
				  { "SUMPREV","N",TamSX3('Z19_QUANT')[1],TamSX3('Z19_QUANT')[2]},;
				  { "SUMREAL","N",TamSX3('Z19_QUANT')[1],TamSX3('Z19_QUANT')[2]},;
				  { "CONTAGEM","C",TamSX3('Z19_CONTAG')[1],0},;
				  { "STATUS","C",1,0}}
	

	
	_aCpoBro	:= {{ "OK"			,, "Mark"			,"@!"},;	
					{ "FILIAL"		,, "Filial"			,"@!"},;
					{ "CODIGO"		,, "OS"				,"@!"},;
					{ "LOCAL"		,, "Armazem"		,"@!"},;
					{ "ENDERECO"	,, "Endereco"		,"@!"},;
					{ "PRODUTO"		,, "Produto"		,"@!"},;
					{ "SUMPREV"		,, "Previsto"		,"@E 999,999.9999"},;
					{ "SUMREAL"		,, "Realizado"		,"@E 999,999.9999"},;
					{ "CONTAGEM"	,, "Contagem"		,"@999"},;
					{ "STATUS"	,, "Status"		,"@!"};
					}
	
	If(Select(_xAlias2)<>0)
		(_xAlias2)->(DBCloseArea())
	EndIf
	/*
	BeginSql Alias _xAlias2
		%noparser%
		SELECT '  ' OK, FILIAL, CODIGO, LOCAL, ENDERECO, PRODUTO, SUM(COALESCE(PREVISTO,0)) SUMPREV, SUM(COALESCE(REALIZADO,0)) SUMREAL, CONTAGEM, '3' STATUS,
		(	SELECT 	SUM(Z16_SALDO) 
			FROM 	Z16010 Z16A (NOLOCK) 
			WHERE 	Z16_FILIAL=FILIAL AND Z16_LOCAL=LOCAL AND Z16_ENDATU=ENDERECO AND 
					Z16_CODPRO=PRODUTO AND Z16A.D_E_L_E_T_=' '
		) SALDOZ16,
		(	SELECT SUM(BF_QUANT) 
			FROM SBF010 SBFA (NOLOCK) 
			WHERE 	BF_FILIAL=FILIAL AND BF_LOCAL=LOCAL AND BF_LOCALIZ=ENDERECO AND 
					BF_PRODUTO=PRODUTO AND SBFA.D_E_L_E_T_=' '
		) SALDOSBF
		 
		FROM (
			SELECT Z19_FILIAL FILIAL ,Z19_IDENT CODIGO,Z19_LOCAL "LOCAL",Z19_ENDERE ENDERECO, 
					Z19_CODPRO PRODUTO, 0 AS PREVISTO,Z19_QUANT AS REALIZADO, Z19_CONTAG CONTAGEM 
			FROM %table:Z19% Z19 (NOLOCK)
			WHERE Z19_FILIAL = %EXP:XFILIAL('Z19')% AND Z19_IDENT = %EXP:_xIdent%  AND Z19.D_E_L_E_T_=' '
			AND Z19_CONTAG=COALESCE((SELECT MAX(Z19A.Z19_CONTAG) FROM %table:Z19% Z19A (NOLOCK) WHERE Z19A.Z19_FILIAL=Z19.Z19_FILIAL AND Z19A.Z19_IDENT=Z19.Z19_IDENT AND Z19A.Z19_LOCAL=Z19.Z19_LOCAL AND Z19A.Z19_ENDERE=Z19.Z19_ENDERE AND Z19A.Z19_CODPRO=Z19.Z19_CODPRO AND Z19A.D_E_L_E_T_=' ' ),'001' )
			
			UNION
			
			SELECT Z21_FILIAL FILIAL ,Z21_IDENT CODIGO,Z21_LOCAL "LOCAL",Z21_LOCALI ENDERECO,
					Z21_PROD PRODUTO,Z21_QUANT PREVISTO, 0 REALIADO, Z21_NRCONT CONTAGEM  
			FROM %TABLE:Z21% Z21 (NOLOCK)
			WHERE Z21_FILIAL = %EXP:XFILIAL('Z21')% AND Z21_IDENT = %EXP:_xIdent% AND Z21.D_E_L_E_T_=' ' 
			AND Z21_NRCONT = COALESCE((SELECT MAX(Z21_NRCONT) FROM %TABLE:Z21% Z21A (NOLOCK) WHERE Z21A.Z21_FILIAL=Z21.Z21_FILIAL AND Z21A.Z21_IDENT=Z21.Z21_IDENT AND Z21A.Z21_LOCAL=Z21.Z21_LOCAL AND Z21A.Z21_LOCALI=Z21.Z21_LOCALI AND Z21A.Z21_PROD=Z21.Z21_PROD AND Z21A.D_E_L_E_T_=' ' ),'001')
		) A
		JOIN %TABLE:Z06% Z06 (NOLOCK) ON Z06_FILIAL = FILIAL AND Z06_NUMOS=CODIGO AND Z06_STATUS NOT IN ('CA','AG') AND Z06.D_E_L_E_T_=' '
		GROUP BY FILIAL, CODIGO, LOCAL, ENDERECO, PRODUTO, CONTAGEM
		HAVING SUM(COALESCE(PREVISTO,0)) <> SUM(COALESCE(REALIZADO,0))
		ORDER BY FILIAL, CODIGO, LOCAL, ENDERECO, PRODUTO,CONTAGEM
	EndSql
	
	//copytoclipboard(getlastquery()[2])
	
	(_xAlias2)->(dbclosearea())
	*/
	oConfDiv := TWMSA21A():NEW(Z06->Z06_FILIAL,Z06->Z06_LOCAL,Z06->Z06_NUMOS)
	
	cNomeArqD:=CriaTrab( _aStru, .T. )
	dbUseArea(.T.,__LocalDriver,cNomeArqD,_xAlias,.T.,.F.)

	oDiv := oConfDiv:Retorno:Dados

	for _nI := 1 to len(oDiv)
		RecLock(_xAlias,.T.)
			(_xAlias)->OK := oDiv[_nI]:OK
			(_xAlias)->FILIAL := oDiv[_nI]:FILIAL
			(_xAlias)->CODIGO := oDiv[_nI]:IDENT
			(_xAlias)->LOCAL := oDiv[_nI]:LOCALI
			(_xAlias)->ENDERECO := oDiv[_nI]:ENDERECO
			(_xAlias)->PRODUTO := oDiv[_nI]:PRODUTO
			(_xAlias)->SUMPREV := oDiv[_nI]:PREVISTO
			(_xAlias)->SUMREAL := oDiv[_nI]:REALIZADO
			(_xAlias)->CONTAGEM := oDiv[_nI]:CONTAGEM
			(_xAlias)->STATUS := ''
		(_xAlias)->(msunlock())
	
	next

	//SqlToTrb(getlastquery()[2], _aStru, _xAlias)

	
	aSize := MsAdvSize()
	aObjects := {}
	AAdd( aObjects, { 40, 80, .T., .T. } )
	//AAdd( aObjects, { 40, 80, .T., .T. } )
	
	aInfo := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 }
	aPosObj := MsObjSize( aInfo, aObjects )
	
	
		
	IndRegua(_xAlias,FileNoExt(cNomeArqD),"FILIAL+CODIGO+PRODUTO+LOCAL+ENDERECO",,,"Selecionando Registros...")
	
	
	aCores := {}
	aAdd(_aCores,{_xAlias+"->STATUS == '0'","BR_VERDE"	})
	aAdd(_aCores,{_xAlias+"->STATUS == '1'","BR_AMARELO"	})
	aAdd(_aCores,{_xAlias+"->STATUS == '2'","BR_VERMELHO"})
//	aAdd(_aCores,{_xAlias+"->STATUS == ' ') ","BR_CINZA"})
	
	If((_xAlias)->(EOF()))
		msginfo('Nenhum registro com divergência de quantidade.','Consulta de Divergêcias')
	Else
		DEFINE MSDIALOG _oDlg TITLE "Divergência de Saldo de Produtos" From aSize[7],0 To aSize[6],aSize[5] PIXEL
		DbSelectArea(_xAlias)
		
		/*
		(_xAlias)->(DbGotop())
		While((_xAlias)->(!EOF()))
			msgalert((_xAlias)->(recno()),'teste')
			(_xAlias)->(dbskip())
		EndDo*/
		
		
		(_xAlias)->(DbGotop())

		//Cria a MsSelect
		_oMark := MsSelect():New(_xAlias,"OK","",_aCpoBro,@_lInverte,@_cMark,{aPosObj[1,1],aPosObj[1,2],aPosObj[1,3],aPosObj[1,4]},,,,,_aCores)
		//_oMark:bMark := {|| Disp()} 
		_oMark:oBrowse:lHasMark		  := .T.
		_oMark:oBrowse:lCanAllmark	  := .T.
		_oMark:oBrowse:lAdjustColSize := .T.
		_oMark:oBrowse:lJustific      := .F.
		_oMark:bAval 				  := {|| RMark(.F.,_xAlias,_oMark)}
		_oMark:oBrowse:bAllMark 	  := {|| RMarkAll(_xAlias,_oMark)}
		//Exibe a Dialog
//		ACTIVATE MSDIALOG _oDlg CENTERED ON INIT EnchoiceBar(_oDlg,{|| nOpcA:=1, _oDlg:End()},{|| _oDlg:End()})
	/*
		_aStru2	:=   {{"OK"	    ,"C",02,0},;
				  { "FILIAL","C",TamSX3('Z19_FILIAL')[1],0},;
				  { "CODIGO","C",TamSX3('Z19_IDENT')[1],0},;
				  { "LOCAL","C",TamSX3('Z19_LOCAL')[1],0},;
				  { "ENDERECO","C",TamSX3('Z19_ENDERE')[1],0},;
				  { "PRODUTO","C",TamSX3('Z19_CONTAG')[1],0},;
				  { "CONTAGEM","C",TamSX3('Z19_CODPRO')[1],0},;
				  { "ETIQUETA","C",TamSX3('Z19_ETQVOL')[1],0},;
				  { "PREVISTO","N",TamSX3('Z19_QUANT')[1],TamSX3('Z19_QUANT')[2]},;
				  { "REALIZADO","N",TamSX3('Z19_QUANT')[1],TamSX3('Z19_QUANT')[2]},;
				  { "CALCULADO","N",TamSX3('Z19_QUANT')[1],TamSX3('Z19_QUANT')[2]},;
				  { "STATUS","C",1,0},;
				  { "MENSAGEM","C",100,0}}
	
				  _aCpoBro2	:= {{ "OK"			,, "Mark"			,"@!"},;	
					{ "FILIAL"		,, "Filial"			,"@!"},;
					{ "CODIGO"		,, "OS"				,"@!"},;
					{ "LOCAL"		,, "Armazem"		,"@!"},;
					{ "ENDERECO"	,, "Endereco"		,"@!"},;
					{ "PRODUTO"		,, "Produto"		,"@!"},;
					{ "CONTAGEM" 	,,'CONTAGEM', pesqpict('Z19','Z19_CONTAG')},;
					{ "ETIQUETA"	,,'ETIQUETA', pesqpict('Z19','Z19_QUANT')},;
					{ "PREVISTO"	,,'PREVISTO',, pesqpict('Z19','Z19_QUANT')},;
					{ "REALIZADO"	,,'REALIZADO', pesqpict('Z19','Z19_QUANT')},;
					{ "CALCULADO"	,,'CALCULADO', pesqpict('Z19','Z19_QUANT')},;
					{ "STATUS"		,,'STATUS','@!'},;
					{ "MENSAGEM"	,,'MENSAGEM','@!'}}



		
		//Cria a MsSelect
		_oMarkB := MsSelect():New(_xAliasB,"OK","",_aCpoBroB,@_lInverte,@_cMark,{aPosObj[2,1],aPosObj[2,2],aPosObj[2,3],aPosObj[2,4]},,,,,_aCores)
		//_oMark:bMark := {|| Disp()} 
		_oMarkB:oBrowse:lHasMark		  := .T.
		_oMarkB:oBrowse:lCanAllmark	  := .T.
		_oMarkB:oBrowse:lAdjustColSize := .T.
		_oMarkB:oBrowse:lJustific      := .F.
		_oMarkB:bAval 				  := {|| RMark(.F.,_xAlias,_oMark)}
		_oMarkB:oBrowse:bAllMark 	  := {|| RMarkAll(_xAlias,_oMark)}
		//Exibe a Dialog
		
		*/
		ACTIVATE MSDIALOG _oDlg CENTERED ON INIT EnchoiceBar(_oDlg,{|| nOpcA:=1, _oDlg:End()},{|| _oDlg:End()})
		
		//(_xAlias)->(DbCloseArea())
	EndIf
	/*
	_oDlg := TDialog():New(aSize[7],0,aSize[6],aSize[5],"Baixas Parciais em Lote" ,,,,,,,,,.T.,,,,,)
_oDlg:lCentered := .T.
_oDlg:bInit     := EnchoiceBar(_oDlg, {|| nOpcA:=1, _oDlg:End() },{|| _oDlg:End()},,aButtons)
	*/

	If nOpcA == 1 
		sfCompPR() 
	Endif

	//Fecha a Area e elimina os arquivos de apoio criados em disco.
	Iif(File(cNomeArqD + GetDBExtension()),FErase(cNomeArqD  + GetDBExtension()) ,Nil)
	(_xAlias)->(DbCloseArea())
	RestArea(_aArea)


Return _lRet


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³R515MarkAll³ Autor ³Andre Sakai           ³ Data ³ 18/08/17 ³±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Marca todos os itens                                        º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ FINAT022                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function RMarkAll(cAlias,_oMarkX)

Local nRecno := Recno()
Local lRet   := .T.

dbSelectArea(cAlias)
(cAlias)->(dbGoTop())

While (cAlias)->(!Eof())
	RMark(.T.,cAlias,_oMarkX)
	(cAlias)->(DbSkip())	
Enddo

(cAlias)->(DbGoto(nRecno))

_oMarkX:oBrowse:Refresh()

Return(lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³R515MARK  ºAutor  ³Edinei Sanchez Milekº Data ³  12/09/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Marca item                                                  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ FINAT022                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function RMark(lAll,cAlias,_oMarkX)

Local nRecno:=(cAlias)->(Recno())
Local lRet  := .T.

lAll:=If(lAll==Nil,.F.,lAll)

If !lAll
	If !IsMark("OK",_cMark)
		RecLock(cAlias,.F.)
		(cAlias)->OK := _cMark
		(cAlias)->(MsUnLock())
	Else	
		RecLock(cAlias,.F.)
		(cAlias)->OK       := ' '
		(cAlias)->(MsUnLock())
	Endif

Else
	(cAlias)->(dbGoTop())
	While (cAlias)->(!Eof())
		If !IsMark("OK",_cMark)
			RecLock(cAlias,.F.)
			(cAlias)->OK       := _cMark
			(cAlias)->(MsUnLock())
		Else
			RecLock(cAlias,.F.)
			(cAlias)->OK       := '  '
			(cAlias)->(MsUnLock())
		Endif
		(cAlias)->(dbSkip())
	Enddo
Endif

_oMarkX:oBrowse:Refresh()

Return lRet


Static Function sfCompPR() 
	
	//Local _xAlias  := getnextalias()
	Local _xAlias2 := getnextalias()
	Local _xAlias3 := getnextalias()
	Local _xAlias4 := getnextalias()
//	Local _xIdent  := Z06->Z06_NUMOS
	
	Private _aConf := {}
	
	_nTela := 0
	
	((_xAlias)->(DBGoTop()))
	set filter to OK <>'  '
	((_xAlias)->(DBGoTop()))
	
	If((_xAlias)->(EOF()))
		If(!Z06->Z06_STATUS $ 'EX')
			U_FtWmsMsg("Inventário ainda não foi executado.","Validação de Divergências")
			//msginfo('Inventário ainda não foi executado','Validação de Divergências')
		Else
			U_FtWmsMsg("Nenhuma divergência encontrada.","Validação de Divergências")
			//msginfo('Nenhuma divergência encontrada','Validação de Divergências')
		EndIf
	Else
		While((_xAlias)->(!EOF()))
			_nTela ++
			//if((_xAlias)->OK='  ')
			//	(_xAlias)->(DbSkip())
			//	loop
			//endif
			
			//Consulta saldo atual do produto no endereço informado
			
			If(SELECT(_xAlias2)<>0)
				(_xAlias2)->(DBCLOSEAREA())
			EndIf
			
			BeginSQL ALIAS _xAlias2
				%noparser%
				SELECT 	SUM(Z16_SALDO) AS SUMEST   
				FROM %TABLE:Z16% Z16 (NOLOCK)
				WHERE 	Z16_FILIAL=%EXP:FILIAL% AND Z16_CODPRO=%EXP:(_xAlias)->PRODUTO% AND 
						Z16_LOCAL=%EXP:(_xAlias)->LOCAL% AND Z16_ENDATU=%EXP:(_xAlias)->ENDERECO% AND 
						Z16.D_E_L_E_T_=' '
			EndSQL
			
			_nSaldoAt := (_xAlias2)->SUMEST
			
			(_xAlias2)->(dbCloseArea())
			
			//aadd(_aReg,{'9',{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,0,0,0},'Entrou na validação'})
			
			//Adicionada validação de saldo atual para itens com etiqueta de numero de volume no estoque (Z16) e sem no Realizado (Z19) 
			
			msgalert('<html>Previsto:'+ transform((_xAlias)->SUMPREV,pesqpict('Z19','Z19_QUANT')) + ' <BR>Realizado' + transform((_xAlias)->SUMREAL,pesqpict('Z19','Z19_QUANT'))+ '<BR>Saldo Z16'+ transform(_nSaldoAt,pesqpict('Z19','Z19_QUANT')),'Divergencia')
			
			If((_xAlias)->SUMPREV > (_xAlias)->SUMREAL .AND. _nSaldoAt <> (_xAlias)->SUMREAL)  
				
				
				//Consulta itens da separação para comparar os saldos
				
				BeginSQL ALIAS _xAlias2
					SELECT	COALESCE(Z19_QUANT,0) Z19_QUANT,COALESCE(Z21_QUANT,0) Z21_QUANT, Z16_SALDO, Z21_FILIAL,Z21_PROD,
							Z21_LOCAL,'ZZZ' Z21_PRIOR, Z21_LOCALI, Z21_LOTE ,Z21_NUMLOT,Z21_ESTFIS,Z21_IDENT,Z21_CONTAG,
							Z21_ETQPAL,Z21_ETQPAL,Z21_ETQPRD, Z21_ETQVOL, Z21_ETQCLI,Z21_NUMSEQ,B1_CODBAR,Z16.R_E_C_N_O_ Z16REC
					FROM %TABLE:Z21% Z21 (NOLOCK)
					JOIN %TABLE:Z06% Z06 (NOLOCK) ON Z06_FILIAL = %EXP:XFILIAL('Z06')% AND Z06_NUMOS=Z21_IDENT AND Z06_STATUS NOT IN ('CA','AG') AND Z06.D_E_L_E_T_=' '
					JOIN %TABLE:SB1% SB1 (NOLOCK) ON B1_COD=Z21_PROD AND SB1.D_E_L_E_T_=' '
					LEFT JOIN %TABLE:Z16% Z16 (NOLOCK) ON 	Z16_FILIAL=Z21_FILIAL AND Z16_CODPRO=Z21_PROD AND Z21_LOCAL=Z21_LOCAL AND 
														Z16_ENDATU=Z21_LOCALI AND Z21_ETQPAL=Z21_ETQPAL AND Z21_ETQCLI=Z21_ETQCLI AND 
														Z16_ETQVOL=Z21_ETQVOL AND Z16.D_E_L_E_T_=' '
					LEFT JOIN Z19010 Z19 (NOLOCK) ON 	Z19_FILIAL=Z21_FILIAL AND Z19_CODPRO=Z21_PROD AND Z19_LOCAL=Z21_LOCAL AND 
														Z19_ENDERE=Z21_LOCALI AND Z19_ETQPAL=Z19_ETQPAL AND Z19_ETQCLI=Z19_ETQCLI AND 
														Z19_ETQVOL=Z21_ETQVOL  AND Z19.D_E_L_E_T_=' '
														AND Z19_CONTAG=Z21_NRCONT
														AND Z19_CONTAG=(SELECT MAX(Z19A.Z19_CONTAG) FROM Z19010 Z19A (NOLOCK) WHERE Z19A.Z19_FILIAL=Z19.Z19_FILIAL	AND Z19A.Z19_IDENT=Z19.Z19_IDENT AND Z19A.Z19_LOCAL=Z19.Z19_LOCAL AND 	Z19A.Z19_ENDERE=Z19.Z19_ENDERE AND 	Z19A.Z19_CODPRO=Z19.Z19_CODPRO AND Z19A.D_E_L_E_T_=' '	)
					
					WHERE 	Z21_FILIAL=%EXP:(_xAlias)->FILIAL% AND 
							Z21_IDENT=%EXP:(_xAlias)->CODIGO% AND 
							Z21_PROD=%EXP:(_xAlias)->PRODUTO% AND
							Z21_LOCAL=%EXP:(_xAlias)->LOCAL% AND 
							Z21_LOCALI=%EXP:(_xAlias)->ENDERECO% AND 
							Z21.D_E_L_E_T_=' '
							AND Z21_CONTAG=(SELECT MAX(Z21A.Z21_CONTAG) FROM Z21010 Z21A (NOLOCK) WHERE Z21A.Z21_FILIAL=Z21.Z21_FILIAL	AND Z21A.Z21_IDENT=Z21.Z21_IDENT AND Z21A.Z21_LOCAL=Z21.Z21_LOCAL AND 	Z21A.Z21_LOCALI = Z21_LOCALI AND 	Z21A.Z21_PROD=Z21.Z21_PROD AND Z21A.D_E_L_E_T_=' '	)
				
				EndSQL
				
				
				//Consulta itens da separação para comparar os saldos
				/*
				BeginSQL ALIAS _xAlias2
					%noparser%
					SELECT	Z19_PLTCLI,Z19_DATA,COALESCE(Z19_QUANT,0) Z19_QUANT, Z16_SALDO, Z19_FILIAL,Z19_CODPRO,
							Z19_LOCAL,'ZZZ' Z19_PRIOR, Z19_ENDERE,Z19_LOTCTL ,'' Z19_NUMLOT,'' Z19_ESTFIS,Z19_IDENT,Z19_CONTAG,
							Z19_ETQPAL,Z19_ETQPAL,Z19_ETQPRO, Z19_ETQVOL, Z19_ETQCLI,Z19_NUMSEQ,B1_CODBAR,Z16.R_E_C_N_O_ Z16REC
					FROM %TABLE:Z19% Z19 (NOLOCK)
					JOIN %TABLE:Z06% Z06 (NOLOCK) ON Z06_FILIAL = %EXP:XFILIAL('Z06')% AND Z06_NUMOS=Z19_IDENT AND Z06_STATUS NOT IN ('CA','AG') AND Z06.D_E_L_E_T_=' '
					JOIN %TABLE:SB1% SB1 (NOLOCK) ON B1_COD=Z19_CODPRO AND SB1.D_E_L_E_T_=' '
					LEFT JOIN %TABLE:Z16% Z16 (NOLOCK) ON 	Z16_FILIAL=Z19_FILIAL AND Z16_CODPRO=Z19_CODPRO AND Z16_LOCAL=Z19_LOCAL AND 
														Z16_ENDATU=Z19_ENDERE AND Z16_ETQPAL=Z19_ETQPAL AND Z16_ETQCLI=Z19_ETQCLI AND 
														(Z16_ETQVOL=Z19_ETQVOL OR (Z19_ETQVOL='' AND Z16_ETQVOL<>'' AND Z16_SALDO=Z19_QUANT)) AND Z16.D_E_L_E_T_=' '
					WHERE 	Z19_FILIAL=%EXP:(_xAlias)->FILIAL% AND 
							Z19_IDENT=%EXP:(_xAlias)->CODIGO% AND 
							Z19_CODPRO=%EXP:(_xAlias)->PRODUTO% AND
							Z19_LOCAL=%EXP:(_xAlias)->LOCAL% AND 
							Z19_ENDERE=%EXP:(_xAlias)->ENDERECO% AND 
							Z19.D_E_L_E_T_=' '
							AND Z19_CONTAG=(SELECT MAX(Z19A.Z19_CONTAG) FROM Z19010 Z19A (NOLOCK) WHERE Z19A.Z19_FILIAL=Z19.Z19_FILIAL	AND Z19A.Z19_IDENT=Z19.Z19_IDENT AND Z19A.Z19_LOCAL=Z19.Z19_LOCAL AND 	Z19A.Z19_ENDERE=Z19.Z19_ENDERE AND 	Z19A.Z19_CODPRO=Z19.Z19_CODPRO AND Z19A.D_E_L_E_T_=' '	)
					union
					SELECT * FROM Z21010 WHERE Z21_
				EndSQL*/
//				CopytoClipboard (GETLASTQUERY()[2])
//				msginfo(GETLASTQUERY()[2],'TWMSA021 1 - 2 ')
				//aadd(_aReg,{'9',{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,0,0,0},'Previsto maior que realizado e saldo Z16 confere'})
				
				If((_xAlias2)->(EOF()))
					//Previsto não encontrado
					//Deseja transferir estoque para area de conferencia
					
					//verifica saldo na SBF para saber se movimenta estoque
					BeginSQL Alias _xAlias4 
								select BF_QUANT from %table:SBF% SBF (NOLOCK)
								WHERE BF_FILIAL=%EXP:(_xAlias)->FILIAL%
								AND BF_PRODUTO=%EXP:(_xAlias)->PRODUTO% 
								AND BF_LOCAL=%EXP:(_xAlias)->LOCAL% 
								AND BF_LOCALIZ=%EXP:(_xAlias)->ENDERECO%
								AND SBF.D_E_L_E_T_=' '
								AND BF_QUANT >= %EXP:(_xAlias2)->Z19_QUANT%
					EndSQL 
					
					_nSaldoSBF := 0
					
					If((_xAlias4)->(eof()))
						//altera somente na Z16 - produto pode ser encontrado em outro endereço
						
						//Saldo na SBF não encontrada - transferir para Lost somente a Z16
						_aItens := {(_xAlias2)->Z16REC,,(_xAlias)->ENDERECO}
						aadd(_aConf,{'6',_aItens/*aItens vazio para não fazer transferencia*/,;
									{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT,(_xAlias2)->Z19_QUANT,(_xAlias2)->Z16REC},;
									'Realizar transferência para Quarentena 2?'})
					Else
						//altera endereço para lost e transfere o produto
						//msgalert('<html>'+'altera somente na Z16 - produto pode ser encontrado em outro endereço'+'<br>'+'','entrou 21')
						_aItens := {}
						_aItem  := {}
						BeginSql Alias _xAlias3
							SELECT *,Z16.R_E_C_N_O_ Z16REC 
							FROM %table:Z16% Z16 
							WHERE 	Z16_FILIAL = %EXP:(_xAlias)->FILIAL% AND
									Z16_LOCAL = %EXP:(_xAlias)->LOCAL%  AND
									Z16_ENDATU = %EXP:(_xAlias)->ENDERECO%  AND
									Z16_CODPRO = %EXP:(_xAlias)->PRODUTO%  AND
									Z16_SALDO = %EXP:(_xAlias)->Z16_SALDO%  AND
									Z16.D_E_L_E_T_=' '  
						EndSql
						
						If((_xAlias3)->(EOF()))
							msgalert('entrou 21 1',cvaltochar(_nSaldoAt),'teste')
						
							//produto não encontrado nas etiquetas - trasnferir para Quarentena LOST
							
							//Criar etiqueta Z16 com as informações levantadas na leitura
							
							/*
								produto deve ser levado para a quarentena - etiqueta de volume não associada
							*/
							_aItens := {}
							_aDados := {(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT,0,(_xAlias2)->Z16REC}

							//aADD(_aConf,{'3',_aItens,_aDados,'Produto não encontrado,Deseja transferir para Quarentena - Etiqueta e Estoque?'})
							
							
						Else
							_aItens := {}
							msgalert('entrou 21 2','teste')
							//aADD(_aConf,{'3',_aItens,_aDados,'Produto não encontrado,Deseja transferir para Quarentena - Etiqueta e Estoque?'})
							
						
						EndIf
						
						
						_aItens := {}
						_aItem  := {}	 
					EndIf
					
					(_xAlias4)->(dbclosearea())
				else
				
					_nTSBF := 0 //Saldo Transferido na SBF
					While((_xAlias2)->(!EOF()))
	
						//If((_xAlias2)->Z19_QUANT <> (_xAlias2)->Z16_SALDO)
							//MsgAlert('Previsto divergente do Estoque do produto no endereço, necessária outra conferencia de inventário para o produto: '+alltrim((_xAlias2)->Z21_PROD)+' / endereço: '+alltrim((_xAlias2)->Z21_LOCALI),'')
							//aadd(_aReg,{'3',{},'Previsto divergente do Estoque do produto no endereço'})
						//Else
	
							//Compara previsto com estoque para verificar se correção já foi efetuada
							/*
							BeginSQL ALIAS _xAlias3
								%noparser%
								SELECT	Z19_PLTCLI,Z19_DATA,COALESCE(Z19_QUANT,0) Z19_QUANT, Z19_QUANT, Z16_SALDO, Z19_FILIAL,Z19_CODPRO,Z19_LOCAL,'ZZZ' Z19_PRIOR, Z19_ENDERE,Z19_LOTCTL ,'' Z19_NUMLOT,'' Z19_ESTFIS,Z19_IDENT,Z19_CONTAG,Z19_ETQPAL,Z19_ETQPAL,Z19_ETQPRO, Z19_ETQVOL, Z19_ETQCLI,Z19_NUMSEQ,B1_CODBAR
								FROM %TABLE:Z19% Z19 (NOLOCK)
								JOIN %TABLE:Z06% Z06 (NOLOCK) ON Z06_FILIAL = %EXP:XFILIAL('Z06')% AND Z06_NUMOS=Z19_IDENT AND Z06_STATUS NOT IN ('CA','AG') AND Z06.D_E_L_E_T_=' '
								JOIN %TABLE:SB1% SB1 (NOLOCK) ON B1_COD=Z19_CODPRO AND SB1.D_E_L_E_T_=' '
								LEFT JOIN %TABLE:Z16% Z16 (NOLOCK) ON 	Z16_FILIAL=Z19_FILIAL AND Z16_CODPRO=Z19_CODPRO AND Z16_LOCAL=Z19_LOCAL AND 
																	Z16_ENDATU=Z19_ENDERE AND Z16_ETQPAL=Z19_ETQPAL AND Z16_ETQCLI=Z19_ETQCLI AND 
																	Z16_ETQVOL=Z19_ETQVOL AND Z16.D_E_L_E_T_=' '
								WHERE 	Z19_FILIAL=%EXP:(_xAlias)->FILIAL% AND 
										Z19_IDENT=%EXP:(_xAlias)->CODIGO% AND 
										Z19_CODPRO=%EXP:(_xAlias)->PRODUTO% AND
										Z19_LOCAL=%EXP:(_xAlias)->LOCAL% AND 
										Z19_ENDERE=%EXP:(_xAlias)->ENDERECO% AND 
										Z19.D_E_L_E_T_=' '
										AND Z19_CONTAG=(SELECT MAX(Z21A.Z21_NRCONT) FROM Z21010 Z21A (NOLOCK) WHERE Z21A.Z21_FILIAL=Z19.Z19_FILIAL	AND Z21A.Z21_IDENT=Z19.Z19_IDENT AND Z21A.Z21_LOCAL=Z19.Z19_LOCAL AND 	Z21A.Z21_LOCALI=Z19.Z19_ENDERE AND 	Z21A.Z21_PROD=Z19.Z19_CODPRO AND Z21A.D_E_L_E_T_=' '	)
							EndSQL
							*/
							If((_xAlias2)->Z16_SALDO <> (_xAlias2)->Z19_QUANT .AND. (_xAlias2)->Z19_QUANT = 0)
								//sem saldo no realizado
	
								//Verifica saldo em nota - sbf
								BeginSQL Alias _xAlias4 
									select * from %table:SBF% SBF
									WHERE BF_FILIAL=%EXP:(_xAlias)->FILIAL%
									AND BF_PRODUTO=%EXP:(_xAlias)->PRODUTO% 
									AND BF_LOCAL=%EXP:(_xAlias)->LOCAL% 
									AND BF_LOCALIZ=%EXP:(_xAlias)->ENDERECO%
									AND BF_QUANT >=%EXP:(_xAlias2)->Z19_QUANT%
									AND SBF.D_E_L_E_T_=' '
								EndSQL 
								//msgalert(getlastquery()[2],'saldo bf quant 0')
								aLista := {}								
								If((_xAlias4)->(EOF()))
									//Sem Saldo na SBF	
									msgalert('Sem Saldo na SBF	','(_xAlias2)->Z16_SALDO <> (_xAlias2)->Z19_QUANT .AND. (_xAlias2)->Z19_QUANT = 0')
								Else
									If(((_xAlias4)->BF_QUANT - _nTSBF) >=  (_xAlias2)->Z16_SALDO)
										//msgalert('Sem Saldo na SBF	entrou 1','(_xAlias2)->Z16_SALDO <> (_xAlias2)->Z19_QUANT .AND. (_xAlias2)->Z19_QUANT = 0')
										aLista := {}
										aAdd(aLista ,{	(_xAlias)->CODIGO,;	//produto origem
													(_xAlias)->CODIGO,;	//produto destino
													(_xAlias2)->Z19_QUANT,; //quantidade
													(_xAlias)->LOCAL,; //local Origem
													(_xAlias)->LOCAL,; //local Destino
													(_xAlias)->ENDERECO,; //Endereco Origem
													'LOST',; //Local Destino
													'',; // Numero serie //D3_NUMSERI
													'',; // Lote Origem //D3_LOTECTL
													'',; // sublote origem // D3_NUMLOTE
													'',;//data validade // D3_DTVALID
													'',;//data validade // D3_ZNUMOS
													'',;//data validade // D3_ZSEQOS
													(_xAlias2)->Z16REC;
													}) //Os produtos a serem utilizados
													
										aAdd(_aConf,{	'6',aLista/*dados da transferencia*/,;
														{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT,0,(_xAlias2)->Z16REC}/*log das informações encontradas*/,;
														'Realizar Transferência para Quarentena (LOST)1?'})
										//aadd(_aReg,{'4',{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT,0},'Z16 transferido para Quarentena (Endereço LOST).'})
										_nTSBF += (_xAlias2)->Z19_QUANT									
									Else
										aAdd(aLista ,{	(_xAlias)->CODIGO,;	//produto origem
													(_xAlias)->CODIGO,;	//produto destino
													(_xAlias2)->Z19_QUANT,; //quantidade
													(_xAlias)->LOCAL,; //local Origem
													(_xAlias)->LOCAL,; //local Destino
													(_xAlias)->ENDERECO,; //Endereco Origem
													'LOST',; //Local Destino
													'',; // Numero serie //D3_NUMSERI
													'',; // Lote Origem //D3_LOTECTL
													'',; // sublote origem // D3_NUMLOTE
													'',;//data validade // D3_DTVALID
													'',;//data validade // D3_ZNUMOS
													'',;//data validade // D3_ZSEQOS
													(_xAlias2)->Z16REC;
													}) //Os produtos a serem utilizados
										
										//Transfere a Etiqueta - Z16 para o endereço LOST
										aadd(_aConf,{'6',aLista,{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT,0,(_xAlias2)->Z16REC},;
													 'Realizar Transferência para Quarentena (LOST)3?'})

										_nTSBF += (_xAlias2)->Z19_QUANT	
									EndIf
								EndIf
								//transfere para lost
	
								(_xAlias4)->(dbCloseArea())
	
								
							ElseIf(((_xAlias2)->Z16_SALDO) <> (_xAlias2)->Z19_QUANT)
							
								/*
									verifica saldo na SBF010 
								*/							
								BeginSQL Alias _xAlias4 
									select * from %table:SBF% SBF
									WHERE BF_FILIAL=%EXP:(_xAlias)->FILIAL%
									AND BF_PRODUTO=%EXP:(_xAlias)->PRODUTO% 
									AND BF_LOCAL=%EXP:(_xAlias)->LOCAL% 
									AND BF_LOCALIZ=%EXP:(_xAlias)->ENDERECO%
									AND SBF.D_E_L_E_T_=' '
								EndSQL 
					
								If((_xAlias4)->(EOF()))
									//NÃO EXISTE SALDO SBF
									aadd(_aReg,{'3',{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT,(_xAlias2)->Z16REC},'Não existe saldo em nota no endereço informado.'},)
									
								ElseIf((_xAlias4)->BF_QUANT  = (_xAlias2)->Z19_QUANT)
									//SBF igual ao realizado 
									//msgalert('Z16 errado - corrige saldo Z16','SUMPREV > SUMREAL .AND. _nSaldoAt(Z16) <> (_xAlias)->SUMREAL)    -- ((_xAlias2)->Z16_SALDO <> (_xAlias2)->Z19_QUANT)')
									//verificar regras
									_aItens := {}
									
//									aadd(_aConf,{'5',_aItens,})
									
									aadd(_aConf,{'5',;
									_aItens/*aItens vazio, não faz transferencia*/,;
									{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT,(_xAlias2)->Z19_QUANT,(_xAlias2)->Z16REC},;
									'Saldo da etiqueta é maior que saldo SBF/Realizado, Corrigir saldo para '+transform((_xAlias2)->Z19_QUANT,PESQPICT('Z19','Z19_QUANT'))+'?.'})
									/*
									
									*/
								ElseIf((_xAlias4)->BF_QUANT > (_xAlias2)->Z19_QUANT)
									//Existe saldo na SBF
									//aadd(_aReg,{'3',{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT,0,(_xAlias2)->Z16REC},'Existe saldo na SBF. Tranferir quantidade excedente para quarentena.'})
									
									//Begin Transaction					
									aLista := {}
									aAdd(aLista ,{	(_xAlias)->PRODUTO,;	//produto origem
													(_xAlias)->PRODUTO,;	//produto destino
													(_xAlias2)->(Z16_SALDO-Z19_QUANT),; //quantidade
													(_xAlias)->LOCAL,; //local Origem
													(_xAlias)->LOCAL,; //local Destino
													(_xAlias)->ENDERECO,; //Endereco Origem
													'LOST',; //Local Destino
													'',; // Numero serie //D3_NUMSERI
													'',; // Lote Origem //D3_LOTECTL
													'',; // sublote origem // D3_NUMLOTE
													'',;//data validade // D3_DTVALID
													'',;//data validade // D3_ZNUMOS
													'',;//data validade // D3_ZSEQOS
													(_xAlias2)->Z16REC;
													}) //Os produtos a serem utilizados
									aadd(	_aConf,{'3',;
													aLista,;
													{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z21_QUANT,(_xAlias2)->Z19_QUANT,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z16REC},;
										 'Transferir a diferença para quarentena(LOST) ('+Transform((_xAlias2)->(Z16_SALDO-Z19_QUANT),pesqpict('Z19','Z19_QUANT'))+')?'})				
									//aadd(_aConf,{'6',aLista,{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT,0,(_xAlias2)->Z16REC},'Transferir a diferença para quarentena(LOST) ('+Transform((_xAlias2)->(Z16_SALDO-Z19_QUANT),pesqpict('Z19','Z19_QUANT'))+')?'})				
									//aadd(_aReg,{'1',{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z21_QUANT,(_xAlias2)->Z19_QUANT,(_xAlias2)->(Z16_SALDO), (_xAlias2)->Z16REC},'Transferir a diferença para LOST ('+Transform((_xAlias2)->(Z16_SALDO-Z19_QUANT),pesqpict('Z19','Z19_QUANT'))+')?'})
									
								Else
									//ajusta saldo na Z16
									/* -- em validação
									If(Z16->(DBGOTO((_xAlias2)->Z16REC)))
										//ajusta saldo na Z16 para o saldo lido
										reclock("Z16",.F.)
											Z16->Z16_SALDO := Z19_QUANT
											aadd(_aReg,{'3',{{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT}},'Saldo Tabela de etiquetas na Z16.'})
										Z16->(msunlock())
									EndIf
									
									*/
									//não existe saldo a ser transferido
									aadd(_aReg,{'1',{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT,(_xAlias2)->Z19_QUANT, (_xAlias2)->Z16REC},'Corrigido saldo na Tabela de etiquetas'})
									//aadd(_aConf,{'1',{{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT}},'Corrigido saldo na Tabela de etiquetas'})
									
								EndIf
			
								//SELECT * FROM SBF010 WHERE BF_
			
								//transfere para ARMAZEM 'LOST' e 
								
								//Divide saldo na Z16
									
								//transfere diferença para ARMAZEM 'LOST'
			
								
									
								
								(_xAlias4)->(dbCloseArea())
						
						
							Else
								//msgalert('Entrou no else','linha 2980') //saldo ja corrigido 
								aadd(_aReg,{'1',{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT,(_xAlias2)->Z19_QUANT, (_xAlias2)->Z16REC},'Saldo já corrigido'})
									
							EndIf
							
						//EndIf	
		
						
					(_xAlias2)->(DBSKIP())
					EndDo
				
						
				endif
								
				
				(_xAlias2)->(DBCloseArea())
				//SBF  NO ARMAZEM / DOCAS
				
				//SD3 - MOVIMENTAÇÕES DE RETIRADA RECENTES DESTE PALET
				
				 
				
			ElseIf((_xAlias)->SUMREAL > (_xAlias)->SUMPREV  .AND. _nSaldoAt <> (_xAlias)->SUMREAL) // produtos encontrados a mais

				//Compara previsto com estoque para verificar se correção já foi efetuada

				BeginSQL ALIAS _xAlias2
					%noparser%
					
					SELECT	Z19_QUANT,COALESCE(Z21_QUANT,0) Z21_QUANT, Z16_SALDO, Z21_FILIAL,Z21_PROD,
							Z21_LOCAL,'ZZZ' Z21_PRIOR, Z21_LOCALI, Z21_LOTE ,Z21_NUMLOT,Z21_ESTFIS,Z21_IDENT,Z21_CONTAG,
							Z21_ETQPAL,Z21_ETQPAL,Z21_ETQPRD, Z21_ETQVOL, Z21_ETQCLI,Z21_NUMSEQ,B1_CODBAR,Z16.R_E_C_N_O_ Z16REC
					FROM %TABLE:Z21% Z21 (NOLOCK)
					JOIN %TABLE:Z06% Z06 (NOLOCK) ON Z06_FILIAL = '103' AND Z06_NUMOS=Z21_IDENT AND Z06_STATUS NOT IN ('CA','AG') AND Z06.D_E_L_E_T_=' '
					JOIN %TABLE:SB1% SB1 (NOLOCK) ON B1_COD=Z21_PROD AND SB1.D_E_L_E_T_=' '
					LEFT JOIN %TABLE:Z16% Z16 (NOLOCK) ON 	Z16_FILIAL=Z21_FILIAL AND Z16_CODPRO=Z21_PROD AND Z16_LOCAL=Z21_LOCAL AND 
														Z16_ENDATU=Z21_LOCALI AND Z16_ETQPAL=Z21_ETQPAL AND Z16_ETQCLI=Z21_ETQCLI AND 
														Z16_ETQVOL=Z21_ETQVOL  AND Z16.D_E_L_E_T_=' '
					LEFT JOIN %TABLE:Z19% Z19 (NOLOCK) ON 	Z19_FILIAL=Z21_FILIAL AND Z19_CODPRO=Z21_PROD AND Z19_LOCAL=Z21_LOCAL AND 
														Z19_ENDERE=Z21_LOCALI AND Z19_ETQPAL=Z19_ETQPAL AND Z19_ETQCLI=Z19_ETQCLI AND 
														Z19_ETQVOL=Z21_ETQVOL  AND Z19.D_E_L_E_T_=' '
														AND Z19_CONTAG=Z21_NRCONT
														AND Z19_CONTAG=(SELECT MAX(Z19A.Z19_CONTAG) FROM Z19010 Z19A (NOLOCK) WHERE Z19A.Z19_FILIAL=Z19.Z19_FILIAL	AND Z19A.Z19_IDENT=Z19.Z19_IDENT AND Z19A.Z19_LOCAL=Z19.Z19_LOCAL AND 	Z19A.Z19_ENDERE=Z19.Z19_ENDERE AND 	Z19A.Z19_CODPRO=Z19.Z19_CODPRO AND Z19A.D_E_L_E_T_=' '	)
				 
					WHERE 	Z21_FILIAL=%EXP:(_xAlias)->FILIAL% AND 
							Z21_IDENT=%EXP:(_xAlias)->CODIGO% AND 
							Z21_PROD=%EXP:(_xAlias)->PRODUTO% AND
							Z21_LOCAL=%EXP:(_xAlias)->LOCAL% AND 
							Z21_LOCALI=%EXP:(_xAlias)->ENDERECO% AND 
							Z21.D_E_L_E_T_=' '		
							AND Z21_CONTAG=(SELECT MAX(Z21A.Z21_CONTAG) FROM Z21010 Z21A (NOLOCK) WHERE Z21A.Z21_FILIAL=Z21.Z21_FILIAL	AND Z21A.Z21_IDENT=Z21.Z21_IDENT AND Z21A.Z21_LOCAL=Z21.Z21_LOCAL AND 	Z21A.Z21_LOCALI = Z21_LOCALI AND 	Z21A.Z21_PROD=Z21.Z21_PROD AND Z21A.D_E_L_E_T_=' '	)

				
				EndSQL
					
				/*	
					SELECT	Z19_PLTCLI, Z19_DATA, COALESCE(Z19_QUANT,0) Z19_QUANT, Z19_QUANT, COALESCE(Z16_SALDO,0) Z16_SALDO, Z19_FILIAL, Z19_CODPRO,
							Z19_LOCAL, 'ZZZ' Z19_PRIOR, Z19_ENDERE, Z19_LOTCTL ,'' Z19_NUMLOT,'' Z19_ESTFIS, Z19_IDENT, Z19_CONTAG,
							Z19_ETQPAL, Z19_ETQPAL, Z19_ETQPRO, Z19_ETQVOL, Z19_ETQCLI, Z19_NUMSEQ, B1_CODBAR, Z19.R_E_C_N_O_ Z19REC, Z16.R_E_C_N_O_ Z19REC
					FROM %TABLE:Z19% Z19 (NOLOCK)
					JOIN %TABLE:Z06% Z06 (NOLOCK) ON 	Z06_FILIAL = %EXP:XFILIAL('Z06')% AND Z06_NUMOS=Z19_IDENT AND Z06_STATUS NOT IN ('CA','AG') AND 
														Z06.D_E_L_E_T_=' '
					JOIN %TABLE:SB1% SB1 (NOLOCK) ON B1_COD=Z19_CODPRO AND SB1.D_E_L_E_T_=' '
					LEFT JOIN %TABLE:Z16% Z16 (NOLOCK) ON 	Z16_FILIAL=Z19_FILIAL AND Z16_CODPRO=Z19_CODPRO AND Z16_LOCAL=Z19_LOCAL AND 
															Z16_ENDATU=Z19_ENDERE AND Z16_ETQPAL=Z19_ETQPAL AND Z16_ETQCLI=Z19_ETQCLI AND 
															Z16_ETQVOL=Z19_ETQVOL AND Z16.D_E_L_E_T_=' '
					WHERE 	Z19_FILIAL=%EXP:(_xAlias)->FILIAL% AND 
							Z19_IDENT=%EXP:(_xAlias)->CODIGO% AND 
							Z19_CODPRO=%EXP:(_xAlias)->PRODUTO% AND
							Z19_LOCAL=%EXP:(_xAlias)->LOCAL% AND 
							Z19_ENDERE=%EXP:(_xAlias)->ENDERECO% AND 
							Z19.D_E_L_E_T_=' '
							AND Z19_CONTAG=(SELECT MAX(Z19A.Z19_CONTAG) FROM Z19010 Z19A (NOLOCK) WHERE Z19A.Z19_FILIAL=Z19.Z19_FILIAL	AND Z19A.Z19_IDENT=Z19.Z19_IDENT AND Z19A.Z19_LOCAL=Z19.Z19_LOCAL AND 	Z19A.Z19_ENDERE=Z19.Z19_ENDERE AND 	Z19A.Z19_CODPRO=Z19.Z19_CODPRO AND Z19A.D_E_L_E_T_=' '	)
				*/
				
//				CopytoClipboard (GETLASTQUERY()[2])
//				msginfo(GETLASTQUERY()[2],'TWMSA021 2')
	
	
				While((_xAlias2)->(!EOF()))
					_lEtEndD := .F.
					_lSaldBF := .F.
					_nSlSBF := 0
					
					If((_xAlias2)->Z16_SALDO <> (_xAlias2)->Z19_QUANT)
					
						//PROCURA ETIQUETA DE VOLUME EM OUTRO ENDEREÇO - CASO ESTEJA PREENCHIDA
						If(ALLTRIM((_xAlias2)->Z19_ETQVOL) <> '')
							BeginSQL ALIAS _xAlias3
								%noparser%
								SELECT *, Z16_ENDATU ENDERECO, Z16_ETQVOL VOLUME, Z16_LOCAL LOCAL, Z16_CODPRO PRODUTO, R_E_C_N_O_ Z16REC
								FROM %YABLE:Z16% Z16 (NOLOCK)
								WHERE 	Z16_FILIAL = %EXP:(_xAlias2)->Z19_FILIAL% AND Z16_ETQVOL=%EXP:(_xAlias2)->Z19_ETQVOL% AND 
										Z16_CODPRO=%EXP:(_xAlias2)->Z19_CODPRO% AND Z16_SALDO>=%EXP:(_xAlias2)->Z19_QUANT% AND 
										Z16.D_E_L_E_T_=' ' 		
							EndSQL
							
							If((_xAlias3)->(!EOF()))
								_lEtEndD := .T.
								//PRODUTO ENCONTRADO NO ENDEREÇO XXX DESEJA TRANSFERIR?
								aadd(_aReg,{'3',{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias)->SUMPREV,(_xAlias2)->Z19_QUANT,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z16REC},'Etiqueta encontrada em '+(_xAlias3)->ENDERECO+' - aguardando transferência'})
			
								aLista := { {;
												(_xAlias3)->PRODUTO,;	//produto origem		[01]
												(_xAlias2)->PRODUTO,;	//produto destino	[02]
												(_xAlias2)->Z19_QUANT,; //quantidade			[03]
												(_xAlias3)->LOCAL,; //local Origem				[04]
												(_xAlias2)->Z19_LOCAL,; //local Destino			[05]
												(_xAlias3)->ENDERECO,; //Endereco Origem		[06]
												(_xAlias2)->Z19_ENDERE,; //Local Destino		[07]
												'',; // Numero serie //D3_NUMSERI				[08]
												'',; // Lote Origem //D3_LOTECTL				[09]
												'',; // sublote origem // D3_NUMLOTE			[10]
												'',;//data validade // D3_DTVALID				[11]
												'',;//data validade // D3_ZNUMOS				[12]
												'',;//data validade // D3_ZSEQOS				[13]
												(_xAlias3)->Z16REC;//REGISTRO Z16 A TRANSFERIR	[14]
												} } //Os produtos a serem utilizados
								//transferencia do valor total para o endereço inventariado	
				
								aadd(_aConf,{'3',aLista,{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z19_QUANT,(_xAlias)->SUMREAL,(_xAlias2)->Z19_QUANT-(_xAlias)->SUMREAL,(_xAlias2)->Z16REC},'Realizar Transferência da Quarentena para '+(_xalias2)->Z19_ENDERE+'?'})

								//adiconar produto a lista de transferencias -> Z16, SD3 - CONFERIR SBF - VER SE ENDEREÇO TEM OUTRAS ETIQUETAS

							Else
								//inventário possui etiqueta mas não foi encontrada no estoque
								
								//Solicitica validação para criar etiqueta - Verificar regra para criação de etiqueta
								//aLista := {(_xAlias2)->Z19REC}
								//msgyesno('Etiqueta não encontrada','Criar etiqueta de endereço e transferir para LOST?')
								//aadd(_aConf,{'4',aLista,{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z19_QUANT,(_xAlias)->SUMREAL,0},'Produto não encontrado nas Etiquetas '+CRLF+' Realizar Transferência do Endereço '+AllTrim((_xalias2)->Z19_ENDERE)+' para Quarentena para ?',(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT,(_xAlias2)->Z19_QUANT})
									/*_aConf(status,tranferencias,dadosetq,mensagem) */
								
							EndIf
							
							(_xAlias3)->(DBCloseArea())
							
						EndIf
					Else
//						msginfo('<html>Saldo já corrigido.','Verifica Divergencias')
						aadd(_aReg,{'2',{(_xAlias)->FILIAL,; 	//[1]
										 (_xAlias)->CODIGO,; 	//[2]
										 (_xAlias)->LOCAL,;  	//[3]
										 (_xAlias)->ENDERECO,;	//[4]
										 (_xAlias)->PRODUTO,; 	//[5]
										 (_xAlias2)->Z16_QUANT,; //[6]
										 (_xAlias2)->Z19_QUANT,;//[7]
										 (_xAlias2)->Z16REC;//[7]
										 },'Estoque ok, Verificar Volumes'})
						reclock(_xAlias,.f.)
							(_xAlias)->STATUS := '1'
						(_xAlias)->(msunlock())
					EndIf
					(_xAlias2)->(DBSKIP())
				EndDo
				
				
				
				/*
				//BF_FILIAL	BF_PRODUTO		BF_LOCAL	BF_PRIOR	BF_LOCALIZ		BF_NUMSERI	BF_LOTECTL	BF_NUMLOTE	BF_QUANT	
				//103		SAMSDC6009002   01			ZZZ			53A050418772   	                    	            14	      
				BeginSQL ALIAS _xAlias3
					%noparser%
					SELECT  BF_FILIAL, BF_PRODUTO, BF_LOCAL, BF_PRIOR, BF_LOCALIZ, BF_NUMSERI, BF_LOTECTL, BF_NUMLOTE, BF_QUANT 
					FROM 	SBF010 SBF (NOLOCK)
					WHERE 	BF_FILIAL = %EXP:(_xAlias)->FILIAL% AND BF_LOCAL = %EXP:(_xAlias)->LOCAL% AND BF_LOCALIZ = %EXP:(_xAlias)->ENDERECO% AND
							SBF.D_E_L_E_T_=' ' 		
				EndSQL
					
				CopytoClipboard (GETLASTQUERY()[2])
//				MSGINFO(GETLASTQUERY()[2],'TWMSA021 3-2')
				
				//COMPARA SALDO DO PRODUTO COM SBF
				If((_xAlias3)->(!EOF()))
					If((_xAlias3)->BF_QUANT <> (_xAlias)->SUMREAL)//SALDO DA SBF DIVERGENTE - DESEJA CORRIGIR
						_lSaldBF := .T.
						If(msgyesno('Saldo do produto '+cvaltochar((_xAlias2)->BF_PRODUTO)+' no endereço '+cvaltochar((_xAlias)->Z21_ETQVOL)+;
						' deve ser corrigido? 	')	)						
						EndIf
					EndIf
				Else
					//SALDO NÃO ENCONTRADO NA SBF - VALIDAÇÃO MANUAL
				EndIf
				
				*/
				//(_xAlias3)->(DBCloseArea())
				
				(_xAlias2)->(DBCloseArea())
			Else
				//Consulta itens da separação para comparar os saldos
				BeginSQL ALIAS _xAlias2
					SELECT	Z19_PLTCLI,Z19_DATA,COALESCE(Z19_QUANT,0) Z19_QUANT, COALESCE(Z19_QUANT,0) Z16_SALDO, Z19_FILIAL,Z19_CODPRO,
							Z19_LOCAL,'ZZZ' Z19_PRIOR, Z19_ENDERE,Z19_LOTCTL ,'' Z19_NUMLOT,'' Z19_ESTFIS,Z19_IDENT,Z19_CONTAG,
							Z19_ETQPAL,Z19_ETQPAL,Z19_ETQPRO, Z19_ETQVOL, Z19_ETQCLI,Z19_NUMSEQ,B1_CODBAR,Z16.R_E_C_N_O_ Z16REC
					FROM %TABLE:Z19% Z19 (NOLOCK)
					JOIN %TABLE:Z06% Z06 (NOLOCK) ON Z06_FILIAL = %EXP:XFILIAL('Z06')% AND Z06_NUMOS=Z19_IDENT AND Z06_STATUS NOT IN ('CA','AG') AND Z06.D_E_L_E_T_=' '
					JOIN %TABLE:SB1% SB1 (NOLOCK) ON B1_COD=Z19_CODPRO AND SB1.D_E_L_E_T_=' '
					LEFT JOIN %TABLE:Z16% Z16 (NOLOCK) ON 	Z16_FILIAL=Z19_FILIAL AND Z16_CODPRO=Z19_CODPRO AND Z16_LOCAL=Z19_LOCAL AND 
														Z16_ENDATU=Z19_ENDERE AND Z16_ETQPAL=Z19_ETQPAL AND Z16_ETQCLI=Z19_ETQCLI AND 
														Z16_ETQVOL=Z19_ETQVOL AND Z16.D_E_L_E_T_=' '
					WHERE 	Z19_FILIAL=%EXP:(_xAlias)->FILIAL% AND 
							Z19_IDENT=%EXP:(_xAlias)->CODIGO% AND 
							Z19_CODPRO=%EXP:(_xAlias)->PRODUTO% AND
							Z19_LOCAL=%EXP:(_xAlias)->LOCAL% AND 
							Z19_ENDERE=%EXP:(_xAlias)->ENDERECO% AND 
							Z19.D_E_L_E_T_=' '
							AND Z19_CONTAG=(SELECT MAX(Z19A.Z19_CONTAG) FROM Z19010 Z19A (NOLOCK) WHERE Z19A.Z19_FILIAL=Z19.Z19_FILIAL	AND Z19A.Z19_IDENT=Z19.Z19_IDENT AND Z19A.Z19_LOCAL=Z19.Z19_LOCAL AND 	Z19A.Z19_ENDERE=Z19.Z19_ENDERE AND 	Z19A.Z19_CODPRO=Z19.Z19_CODPRO AND Z19A.D_E_L_E_T_=' '	)
				
				EndSQL
				
				copytoclipboard(getlastquery()[2])
				//msgalert('teste',' previsto > realizado -- else')
				//Caixas sem etiqueta no item do produto
//				msginfo('Saldo do estoque igual ao do inventário. Ocorrência de divergência de volumes serão tratadas posteriormente.','Verificar Divergências')
				aadd(_aReg,{'2',{	(_xAlias)->FILIAL,; //[1]
									(_xAlias)->CODIGO,; //[2]
									(_xAlias)->LOCAL,; //[3]
									(_xAlias)->ENDERECO,; //[4]
									(_xAlias)->PRODUTO,; //[5]
									(_xAlias)->SUMPREV,; //[6]
									(_xAlias2)->Z19_QUANT,; //[7]
									(_xAlias2)->Z16_SALDO,; //[8]
									(_xAlias2)->Z16REC; //[8]
									},'Verificar Volumes <!-- 01 -->'})
				reclock(_xAlias,.f.)
					(_xAlias)->STATUS := '2'
				(_xAlias)->(msunlock())
			EndIf
	
			(_xAlias)->(DbSkip())
		EndDo
			
	EndIf
	
	If(LEN(_aConf)> 0)
		sfTConfDiv(_aConf,_aReg)
		_aConf := {}
	EndIf

	if(LEN(_aReg)> 0)
		sfRDivergencia(_aReg)
		_aReg := {}
	ENDIF

	
	DBSELECTAREA(_xAlias)
	SET FILTER TO
//	(_xAlias)->(DBCloseArea())
	/*
	While((_xAlias)->(!EOF()))
		CONOUT((_xAlias)->(FILIAL+' '+CODIGO+' '+LOCAL+' '+ENDERECO+' '+PRODUTO)+CVALTOCHAR((_xAlias)->SUM_PREV)+CVALTOCHAR((_xAlias)->SUM_REAL))
		If((_xAlias)->SUM_PREV > (_xAlias)->SUM_REAL )
			CONOUT('Verificar transferências do produto para enontrar possível divergência, saldo maior que o estoque')
		ElseIf((_xAlias)->SUM_REAL < (_xAlias)->SUM_PREV )
			CONOUT('Verificar transferências do produto para enontrar possível divergência, esoque maior que o saldo')
		EndIf
		
		(_xAlias)->(DbSkip())
	EndDo
	*/
	
	//Tela de Visualização das Alterações
	
	
Return


STATIC FUNCTION sfAjSaldo()



//busca SALDO NA SBF

//BUSCA SALDO DO PRODUTO NAS DOCAS E VALIDA TRANSFERENCIAS

// VERIFICA SE PRECISA DE ALTERAÇÃO

//BUSCA INFORMAÇÕES DA Z16
//VERIFICA SE PRECISA DE ALTERAÇÃO

//SBE

//

//MATA240 - Movimentos Internos Mod. I

//MATA241 - Movimentos Internos Mod. II

//MATA265 - Endereçamento



return



/*
User Function TMATA265()

Local aCabSDA    := {}
Local aItSDB         := {}
Local _aItensSDB := {} 

Private	lMsErroAuto := .F.
//Cabeçalho com a informação do item e NumSeq que sera endereçado.
aCabSDA := {{"DA_PRODUTO" ,"PROD-ENDER",Nil},;
	  {"DA_NUMSEQ"  ,"001419",Nil}}//Dados do item que será endereçado
	  
aItSDB := {{"DB_ITEM"	  ,"0001"	      ,Nil},;
			{"DB_ESTORNO"  ," "	      ,Nil},;
			{"DB_LOCALIZ"  ,"LOCAL"    ,Nil},;
			{"DB_DATA"	  ,dDataBase    ,Nil},;
			{"DB_QUANT"  ,20                  ,Nil}}       

aadd(_aItensSDB,aitSDB)

//Executa o endereçamento do item

MATA265( aCabSDA, _aItensSDB, 3)
If lMsErroAuto    MostraErro()

Else    MsgAlert("Processamento Ok!")
Endif

Return
//********* EXEMPLO PARA ESTORNAR UM ITEM *********

User Function TMATA265()
Local aCabSDA    := {}
Local aItSDB         := {}
Local _aItensSDB := {} 
Private	lMsErroAuto := .F.
//Cabeçalho com a informação do item e NumSeq que sera endereçado.
aCabSDA := {{"DA_PRODUTO" ,"PROD-ENDER",Nil},;	  
			{"DA_NUMSEQ"  ,"001419",Nil}}
			
//Dados do item que será endereçado
aItSDB := {{"DB_ITEM"	  ,"0001"	      ,Nil},;
			{"DB_ESTORNO"  ,"S "	      ,Nil},;                   
			{"DB_LOCALIZ"  ,"LOCAL"    ,Nil},;                   
			{"DB_DATA"	  ,dDataBase    ,Nil},;                   
			{"DB_QUANT"  ,20                  ,Nil}}       

aadd(_aItensSDB,aitSDB)
//Executa o estorno do item

MATA265( aCabSDA, _aItensSDB, 4)
If lMsErroAuto    
MostraErro()
Else   
 MsgAlert("Processamento Ok!")
 Endif
 
 Return
 
 
 
 
*/
//Teste de transferência - rotina para chamada manual e automatização de teste
USER FUNCTION UF021T()
Local aLista := {}
Local _lRet := .T.

	aLista := { {;
				'DANULM596                  ',;	//produto origem
				'DANULM596                  ',;	//produto destino
				10,; //quantidade
				'01',; //local Origem
				'01',; //local Destino
				'LOST',; //Endereco Origem
				'07A070202234',; //Local Destino
				'',; // Numero serie //D3_NUMSERI
				'',; // Lote Origem //D3_LOTECTL
				'',; // sublote origem // D3_NUMLOTE
				'',;//data validade // D3_DTVALID
				'',;//data validade // D3_ZNUMOS
				'',;//data validade // D3_ZSEQOS
				123;
				} } //Os produtos a serem utilizados

	//MSGALERT(VARINFO('aLista',aLista),'UF021T')
			
	if(sfMata261(aLista))
		//transferencia realizada
		_lRet := .T.
	else
		_lRet := .F.
		//erro ao realizar transferencia, favor verificar saldos
	endif
	//MSGALERT('APOS sfMata261','UF021T')

/*
    aadd(aLinha,{"D3_NUMSERI", "", Nil}) //Numero serie
    aadd(aLinha,{"D3_LOTECTL", "", Nil}) //Lote Origem
    aadd(aLinha,{"D3_NUMLOTE", "", Nil}) //sublote origem
    aadd(aLinha,{"D3_DTVALID", '', Nil}) //data validade
*/
Return _lRet


/*
Funcao: sfMata261
Descricao: execauto de transferência, 
 */
Static Function sfMata261(aLista)
Local aAuto := {}
Local aItem := {}
Local aLinha := {}
/*
É necessario que:
O parametro MV_LOCALIZ = S
O produto com codigo PA001 tenha controle de endereco ativo
O armazem padrao definido no produto deve ter 2 endereços: ENDER01 e ENDER02 
Saldo inicial igual ou superior a 1
E este saldo deve ser enderecçado ao ENDER01
*/
//Local aLista := {'PA001','PA001'} //Os produtos a serem utilizados
Local nX
Local nOpcAuto := 0
Local cDocumen := ""
Local lEstorno := .F.
Local aArea :=  getArea()
Local _lRet :=  .F.

Private lMsErroAuto := .F.

//MSGALERT('ENTROU sfMata261','UF021T')
//conout("Exemplo de inclusão de movimentação multipla")

//Cabecalho a Incluir
cDocumen := GetSxeNum("SD3","D3_DOC")
aadd(aAuto,{cDocumen,dDataBase}) //Cabecalho

//Itens a Incluir
aItem := {}

for nX := 1 to len(aLista)// step 1
    aLinha := {}
    /*
	aLista := { {;
				'SAMSDC6009002                 ',;	//produto origem
				'SAMSDC6009002                 ',;	//produto destino
				7,; //quantidade
				'01',; //local Origem
				'01',; //local Destino
				'53A050418772   ',; //Endereco Origem
				'53A050518773   ',; //Local Destino
				'',; // Numero serie //D3_NUMSERI
				'',; // Lote Origem //D3_LOTECTL
				'',; // sublote origem // D3_NUMLOTE
				'',;//data validade // D3_DTVALID
				'',;//data validade // D3_ZNUMOS
				'';//data validade // D3_ZSEQOS
				} } //Os produtos a serem utilizados
    */
    if (len(aLista[nX])<>14)
    	U_FtWmsMsg("Quantidade de parâmetros inválida, esperados 14 parâmetros.","Transferência de endereço")
    	return .f.
    endif
    
    //Origem
    SB1->(DBSETORDER(1))
    if(!SB1->(DbSeek(xFilial("SB1")+PadR(aLista[nX][1], tamsx3('D3_COD') [1]))))
    	msgalert(xFilial("SB1")+PadR(aLista[nX][1], tamsx3('D3_COD') [1]),'produto não encontrado')
    endif
    aadd(aLinha,{"ITEM",'00'+cvaltochar(nX),Nil})
    aadd(aLinha,{"D3_COD", SB1->B1_COD, Nil}) //Cod Produto origem
    aadd(aLinha,{"D3_DESCRI", SB1->B1_DESC, Nil}) //descr produto origem
    aadd(aLinha,{"D3_UM", SB1->B1_UM, Nil}) //unidade medida origem
    aadd(aLinha,{"D3_LOCAL", aLista[nX][4], Nil}) //armazem origem
    aadd(aLinha,{"D3_LOCALIZ", PadR(aLista[nX][6], tamsx3('D3_LOCALIZ') [1]),Nil}) //Informar endereço origem
    
    //Destino
    SB1->(DbSeek(xFilial("SB1")+PadR(aLista[nX][2], tamsx3('D3_COD') [1])))
    aadd(aLinha,{"D3_COD", SB1->B1_COD, Nil}) //cod produto destino
    aadd(aLinha,{"D3_DESCRI", SB1->B1_DESC, Nil}) //descr produto destino
    aadd(aLinha,{"D3_UM", SB1->B1_UM, Nil}) //unidade medida destino
    aadd(aLinha,{"D3_LOCAL", aLista[nX][5], Nil}) //armazem destino
    aadd(aLinha,{"D3_LOCALIZ", PadR(aLista[nX][7], tamsx3('D3_LOCALIZ') [1]),Nil}) //Informar endereÃ§o destino
    
    aadd(aLinha,{"D3_NUMSERI", aLista[nX][8], Nil}) //Numero serie
    aadd(aLinha,{"D3_LOTECTL", padr(aLista[nX][9],tamsx3('D3_LOTECTL') [1])/*aLista[nX+8]*/, Nil}) //Lote Origem
    aadd(aLinha,{"D3_NUMLOTE", aLista[nX][10], Nil}) //sublote origem
    aadd(aLinha,{"D3_DTVALID", aLista[nX][11], Nil}) //data validade
    aadd(aLinha,{"D3_POTENCI", 0, Nil}) // Potencia
    aadd(aLinha,{"D3_QUANT", aLista[nX][3], Nil}) //Quantidade
    aadd(aLinha,{"D3_QTSEGUM", 0, Nil}) //Seg unidade medida
    aadd(aLinha,{"D3_ESTORNO", "", Nil}) //Estorno
    aadd(aLinha,{"D3_NUMSEQ", "", Nil}) // Numero sequencia D3_NUMSEQ
    
    aadd(aLinha,{"D3_LOTECTL", padr(aLista[nX][9],tamsx3('D3_LOTECTL') [1])/*aLista[nX+8]*/, Nil}) //Lote destino
    aadd(aLinha,{"D3_NUMLOTE", aLista[nX][10], Nil}) //sublote destino
    aadd(aLinha,{"D3_DTVALID", aLista[nX][11], Nil}) //validade lote destino
    aadd(aLinha,{"D3_ITEMGRD", "", Nil}) //Item Grade
    
    /* CAMPOS CONFORME ROTINA DE TRANSFERENCIA MATA261*/
//    aadd(aLinha,{"D3_IDDCF", "", Nil}) //Item Grade
//    aadd(aLinha,{"D3_ZNUMOS", "", Nil}) //Item Grade
//    aadd(aLinha,{"D3_ZSEQOS", "", Nil}) //Item Grade
//    aadd(aLinha,{"D3_ZETQPLT", "", Nil}) //Item Grade


    aAdd(aAuto,aLinha)
    
    	
	//CopytoClipboard (VARINFO('aAuto',aAuto))
    //msgalert('log de erro informações mata261','sd3')
    
Next nX
nOpcAuto := 3 // Inclusao

//eecview(varinfo('aAuto',aAuto),'aAuto mata261')

MSExecAuto({|x,y| mata261(x,y)},aAuto,nOpcAuto)

if lMsErroAuto
	//msgalert('erro','execauto mata261')
    MostraErro()
    EECVIEW(VARINFO('aAuto',aAuto),'MATA261 - 3')
    lEstorno := .F.
    _lRet := .F.
else
    //msgalert('ok','execauto mata261')
    //msgalert("Inclusão de movimentação multipla efetuada com sucesso",'teste transferencia')
    CONOUT('[TWMSA021] Tranferencia - Correção de saldo Inventário - '+DTOC(SD3->D3_EMISSAO))
    CONOUT('[TWMSA021] SD3 - D3_NUMSEQ: '+SD3->D3_NUMSEQ)
    lEstorno := .F.
    _lRet := .T.
EndIf

//msgalert("Finalizado a inclusão de movimentação multipla",'teste transferencia')
/*
If lContinua

    //
    conout("Exemplo de estorno de movimentação multipla baseado na inclusão do movimentação multipla anterior")

    lMsErroAuto := .F.
    for nX := 1 to len(aLista) step 2
    
        //-- Preenchimento dos campos
        aAuto := {}
        aadd(aAuto,{"D3_DOC", cDocumen, Nil})
        aadd(aAuto,{"D3_COD", aLista[nX], Nil})
        
        DbSelectArea("SD3")
        DbSetOrder(2)
        DbSeek(xFilial("SD3")+cDocumen+aLista[nX])
    
        //-- Teste de Estorno
        nOpcAuto := 6 // Estornar
        MSExecAuto({|x,y| mata261(x,y)},aAuto,nOpcAuto)
        
        If lMsErroAuto
            MostraErro()
        Else
            conout("Estorno de movimentação multipla efetuada com sucesso")
        EndIf

    Next nX
    conout("Finalizado a estorno de movimentação multipla")
EndIf
*/

RestArea(aArea)


Return _lRet


static function sfRDivergencia(_aDados)

	// retorna a pasta temporaria da maquina
	local _cPathTemp := AllTrim(GetTempPath())

	// define nome do arquivo temporario
	local _cTmpArquivo := _cPathTemp + "DivInventario_"+Z06->Z06_NUMOS+'_'+dtos(date())+'_'+substr(time(),1,2)+substr(time(),4,2)+substr(time(),7,2)+".html"

	// diferenca na contagem
	local _nDifCont := 0

	// cria e abre arquivo texto
	_nTmpHdl := fCreate(_cTmpArquivo)

	// testa se o arquivo de Saida foi Criado Corretamente
	If (_nTmpHdl == -1)
		MsgAlert("O arquivo de nome " + _cTmpArquivo + " nao pôde ser criado! Verifique os parametros e se possui permissão no sistema de arquivos.","Atenção!")
		Return( .F. )
	Endif
	
	_cTmpLinha := '<html><body>' + CRLF
	_cTmpLinha += '<style>' + CRLF
	_cTmpLinha += '.circle {' + CRLF
	_cTmpLinha += 'display: block;' + CRLF
	_cTmpLinha += 'border-radius: 50%;' + CRLF
	_cTmpLinha += 'height: 20px;' + CRLF
	_cTmpLinha += 'width: 20px;' + CRLF
	_cTmpLinha += 'margin: 0;' + CRLF
	_cTmpLinha += '}' + CRLF
	_cTmpLinha += '</style>' + CRLF
	_cTmpLinha += '<table width="860px" align="center">' + CRLF
	_cTmpLinha += '  <tr>' + CRLF
	_cTmpLinha += '    <td>' + CRLF
	_cTmpLinha += '      <table style="border-collapse: collapse;" border="1" width="100%" cellpadding="3" cellspacing="0" style="font-family: Tahoma; font-size: 12px;">' + CRLF
	_cTmpLinha += '        <tr>'
	_cTmpLinha += '          <td height="30" colspan="2" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Informações do Inventário</td>'
	_cTmpLinha += '        </tr>'
	_cTmpLinha += '        <tr style="font-family: Tahoma; font-size: 12px;">' + CRLF
	_cTmpLinha += '          <td width="20%">Empresa:</td>' + CRLF
	_cTmpLinha += '          <td width="80%">&nbsp;'+AllTrim(Upper(SM0->M0_NOMECOM))+'</td>' + CRLF
	_cTmpLinha += '        </tr>' + CRLF
	_cTmpLinha += '        <tr style="font-family: Tahoma; font-size: 12px;">' + CRLF
	_cTmpLinha += '          <td width="20%">Filial:</td>' + CRLF
	_cTmpLinha += '          <td width="80%">&nbsp;'+AllTrim(Upper(SM0->M0_FILIAL))+'</td>' + CRLF
	_cTmpLinha += '        </tr>' + CRLF
	_cTmpLinha += '        <tr style="font-family: Tahoma; font-size: 12px;">' + CRLF
	_cTmpLinha += '          <td width="20%">Número:</td>' + CRLF
	_cTmpLinha += '          <td width="80%">&nbsp;'+_cNrOsInv+'</td>' + CRLF
	_cTmpLinha += '        </tr>' + CRLF
	_cTmpLinha += '        <tr style="font-family: Tahoma; font-size: 12px;">' + CRLF
	_cTmpLinha += '          <td width="20%">Data de Emissão:</td>' + CRLF
	_cTmpLinha += '          <td width="80%">&nbsp;'+DtoC(Z05->Z05_DTEMIS)+'</td>' + CRLF
	_cTmpLinha += '        </tr>' + CRLF
	_cTmpLinha += '        <tr style="font-family: Tahoma; font-size: 12px;">' + CRLF
	_cTmpLinha += '          <td width="20%">Cliente/Loja - Nome:</td>' + CRLF
	_cTmpLinha += '          <td width="80%">&nbsp;'+Z05->Z05_CLIENT+'/'+Z05->Z05_LOJA+'-'+AllTrim(Posicione('SA1',1, xFilial('SA1')+Z05->Z05_CLIENT+Z05->Z05_LOJA,'A1_NOME'))+'</td>' + CRLF
	_cTmpLinha += '        </tr>' + CRLF
	_cTmpLinha += '        <tr style="font-family: Tahoma; font-size: 12px;">' + CRLF
	_cTmpLinha += '          <td width="20%">Usuário:</td>' + CRLF
	_cTmpLinha += '          <td width="80%">&nbsp;'+AllTrim(UsrFullName(Z06->Z06_USRINC))+'</td>' + CRLF
	_cTmpLinha += '        </tr>' + CRLF
	_cTmpLinha += '        <tr style="font-family: Tahoma; font-size: 12px;">' + CRLF
	_cTmpLinha += '          <td width="20%">Número de Contagens:</td>' + CRLF
	_cTmpLinha += '          <td width="80%">&nbsp;'+Z06->Z06_NRCONT+'</td>' + CRLF
	_cTmpLinha += '        </tr>' + CRLF
	_cTmpLinha += '        <tr style="font-family: Tahoma; font-size: 12px;">' + CRLF
	_cTmpLinha += '          <td width="20%">Data e Hora Inicial:</td>' + CRLF
	_cTmpLinha += '          <td width="80%">&nbsp;'+DtoC(Z06->Z06_DTINIC)+" - "+Z06->Z06_HRINIC+'</td>' + CRLF
	_cTmpLinha += '        </tr>' + CRLF
	_cTmpLinha += '        <tr style="font-family: Tahoma; font-size: 12px;">' + CRLF
	_cTmpLinha += '          <td width="20%">Data e Hora Final:</td>' + CRLF
	_cTmpLinha += '          <td width="80%">&nbsp;'+DtoC(Z06->Z06_DTFIM)+" - "+Z06->Z06_HRFIM+'</td>' + CRLF
	_cTmpLinha += '        </tr>' + CRLF
	_cTmpLinha += '      </table>' + CRLF
	_cTmpLinha += '    </td>'	 + CRLF
	_cTmpLinha += '  </tr>' + CRLF
	_cTmpLinha += '  <tr>' + CRLF
	_cTmpLinha += '    <td>' + CRLF
	_cTmpLinha += '      <table style="border-collapse: collapse;" border="1" width="100%" cellpadding="3" cellspacing="0">' + CRLF
	_cTmpLinha += '        <tr style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; color: #FFFFFF;">' + CRLF
	_cTmpLinha += '          <td>&nbsp;&nbsp;</td>' + CRLF
	_cTmpLinha += '          <td>&nbsp;Local&nbsp;</td>' + CRLF
	_cTmpLinha += '          <td>&nbsp;Endereco&nbsp;</td>' + CRLF
	_cTmpLinha += '          <td>&nbsp;Produto&nbsp;</td>' + CRLF
	_cTmpLinha += '          <td>&nbsp;Previsto&nbsp;</td>' + CRLF
	_cTmpLinha += '          <td>&nbsp;Realizado&nbsp;</td>' + CRLF
	_cTmpLinha += '          <td>&nbsp;Atual&nbsp;</td>' + CRLF
	_cTmpLinha += '          <td>&nbsp;Mensagem&nbsp;</td>' + CRLF
	_cTmpLinha += '        </tr>' + CRLF
	fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))
	
	for _nI := 1 to len(_aDados)
		_cTmpLinha := '        <tr style="font-family: Tahoma; font-size: 12px;">' + CRLF
		If(_aDados[_nI][1] = '1')
			_cColor := 'mediumseagreen'
		ElseIf(_aDados[_nI][1] = '2')
			_cColor := 'yellow'
		Else
			_cColor := 'red'
		EndIf
		//eecview(varinfo('a'+cvaltochar(_ni),_aDados[_nI][2]),'teste')
		_cTmpLinha += '          <td><figure class="circle" style="background: radial-gradient(circle at 10px 10px, '+_cColor+', #000)"></figure></td>' + CRLF
		_cTmpLinha += '          <td>&nbsp;'+alltrim(_aDados[_nI][2][3])+'&nbsp;</td>' + CRLF
		_cTmpLinha += '          <td>&nbsp;'+alltrim(_aDados[_nI][2][4])+'&nbsp;</td>' + CRLF
		_cTmpLinha += '          <td>&nbsp;'+alltrim(_aDados[_nI][2][5])+'&nbsp;</td>' + CRLF
		_cTmpLinha += '          <td>&nbsp;'+alltrim(transform(_aDados[_nI][2][6],pesqpict('Z19','Z19_QUANT')))+'&nbsp;</td>' + CRLF
		_cTmpLinha += '          <td>&nbsp;'+alltrim(transform(_aDados[_nI][2][7],pesqpict('Z19','Z19_QUANT')))+'&nbsp;</td>' + CRLF
		_cTmpLinha += '          <td>&nbsp;'+alltrim(transform(_aDados[_nI][2][8],pesqpict('Z19','Z19_QUANT')))+'&nbsp;</td>' + CRLF
		_cTmpLinha += '          <td>&nbsp;'+alltrim(_aDados[_nI][3])+'&nbsp;</td>' + CRLF
		_cTmpLinha += '        </tr>' + CRLF
		fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))

	next 
	
	_cTmpLinha := '      </table></td>' + CRLF
	_cTmpLinha += '  </tr>' + CRLF
	_cTmpLinha := '</table></body></html>' + CRLF
	fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))
	
	
	
	// fecha arquivo
	fclose(_nTmpHdl)

	// abre o navegador
	ShellExecute("open",_cTmpArquivo,"","",5)	
	

return
//TELA DE CONFIRMAÇÃO DAS DIVEREGENCIAS 

Static Function sfTConfDiv(_aConf,_aReg) 
	Local _xAliasA := getnextalias()
	Local _aArea := getArea()
	Local _lRet := .T.

	Local cNomeArqD := ''
	Local _aStru2:={}
	Local _aCpoBro2 := {}
	Local _oDlg2
	Local _aCores := {}
	
	Local aSize, aObjects
	
	Private _xAlias  := getnextalias()
	Private _lInverte := .F.
//	Private _cMarkA   := GetMark()   
	Private _oMarkA := nil
	Private nOpcA := 0
//	Private _aReg :={}
	
	_aStru2	:=   {{"OK"	    ,"C",02,0},;
				  { "FILIAL","C",TamSX3('Z19_FILIAL')[1],0},;
				  { "CODIGO","C",TamSX3('Z19_IDENT')[1],0},;
				  { "LOCALI","C",TamSX3('Z19_LOCAL')[1],0},;
				  { "ENDERECO","C",TamSX3('Z19_ENDERE')[1],0},;
				  { "PRODUTO","C",TamSX3('Z19_CODPRO')[1],0},;
				  { "SUMPREV","N",TamSX3('Z19_QUANT')[1],TamSX3('Z19_QUANT')[2]},;
				  { "SUMREAL","N",TamSX3('Z19_QUANT')[1],TamSX3('Z19_QUANT')[2]},;
				  { "SUMSBF","N",TamSX3('Z19_QUANT')[1],TamSX3('Z19_QUANT')[2]},;
				  { "CONTAGEM","C",TamSX3('Z19_CONTAG')[1],0},;
				  { "STATUS","C",1,0},;
				  { "MENSAGEM","C",100,0}}
	

	
	_aCpoBro2	:= {{ "OK"			,, "Mark"			,"@!"},;	
					{ "FILIAL"		,, "Filial"			,"@!"},;
					{ "CODIGO"		,, "OS"				,"@!"},;
					{ "LOCALI"		,, "Armazem"		,"@!"},;
					{ "ENDERECO"	,, "Endereco"		,"@!"},;
					{ "PRODUTO"		,, "Produto"		,"@!"},;
					{ "SUMPREV"		,, "Previsto"		,"@E 999,999.9999"},;
					{ "SUMREAL"		,, "Realizado"		,"@E 999,999.9999"},;
					{ "SUMSBF"		,, "Real"			,"@E 999,999.9999"},;
					{ "CONTAGEM"	,, "Contagem"		,"@999"},;
					{ "STATUS"	,, "Status"		,"@!"},;
				    { "MENSAGEM",,"Mensagem","@!"};
					}
	

	cNomeArqD:=CriaTrab( _aStru2, .T. )
	dbUseArea(.T.,__LocalDriver,cNomeArqD,_xAliasA,.T.,.F.)
	

	for _nI:=1 to Len(_aConf)
		If(_aConf[_nI][1]$'56')
			//eecview(varinfo('_aConf5['+cvaltochar(_nI)+']',_aConf))
			//{(_xAlias)->FILIAL,(_xAlias)->CODIGO,(_xAlias)->LOCAL,(_xAlias)->ENDERECO,(_xAlias)->PRODUTO,(_xAlias2)->Z16_SALDO,(_xAlias2)->Z19_QUANT,(_xAlias2)->Z19_QUANT}
			reclock(_xAliasA,.T.)
				(_xAliasA)->OK 		:= ''
				(_xAliasA)->FILIAL 	:= _aConf[_nI][3][1]
				(_xAliasA)->CODIGO 	:= Z06->Z06_NUMOS
				(_xAliasA)->LOCALI 	:= _aConf[_nI][3][3]
				(_xAliasA)->ENDERECO := _aConf[_nI][3][4]
				(_xAliasA)->PRODUTO := _aConf[_nI][3][5]
				(_xAliasA)->SUMPREV := _aConf[_nI][3][6]
				(_xAliasA)->SUMREAL := _aConf[_nI][3][7]
				(_xAliasA)->SUMSBF 	:= _aConf[_nI][3][8]
				(_xAliasA)->CONTAGEM := ''
				(_xAliasA)->STATUS 	:= _aConf[_nI][1]
				(_xAliasA)->MENSAGEM := _aConf[_nI][4]
			(_xAliasA)->(msunlock())
			
			
		Elseif(_aConf[_nI][1]$'34')
			//eecview(varinfo('_aConf346['+cvaltochar(_nI)+']',_aConf))
			for _nj := 1 to len(_aConf[_nI][2])
				reclock(_xAliasA,.T.)
					(_xAliasA)->OK 		:= ''
					(_xAliasA)->FILIAL 	:= xFilial('Z06')
					(_xAliasA)->CODIGO 	:= Z06->Z06_NUMOS
					(_xAliasA)->LOCALI 	:= _aConf[_nI][2][_nJ][4]
					(_xAliasA)->ENDERECO := _aConf[_nI][2][_nJ][6]
					(_xAliasA)->PRODUTO := _aConf[_nI][2][_nJ][1]
					(_xAliasA)->SUMPREV := _aConf[_nI][3][6]
					(_xAliasA)->SUMREAL := _aConf[_nI][3][7]
					(_xAliasA)->SUMSBF 	:= _aConf[_nI][3][8]
					(_xAliasA)->CONTAGEM := ''
					(_xAliasA)->STATUS 	:= _aConf[_nI][1]
					(_xAliasA)->MENSAGEM := _aConf[_nI][4]
				(_xAliasA)->(msunlock())
			next
		
		EndIf
	
	next
	
/*
								aAdd(aLista ,{	(_xAlias)->CODIGO,;	//produto origem
												(_xAlias)->CODIGO,;	//produto destino
												(_xAlias2)->Z19_QUANT - (_xAlias2)->Z16_SALDO,; //quantidade
												(_xAlias)->LOCAL,; //local Origem
												(_xAlias)->LOCAL,; //local Destino
												(_xAlias)->ENDERECO,; //Endereco Origem
												'LOST',; //Local Destino
												'',; // Numero serie //D3_NUMSERI
												'',; // Lote Origem //D3_LOTECTL
												'',; // sublote origem // D3_NUMLOTE
												'',;//data validade // D3_DTVALID
												'',;//data validade // D3_ZNUMOS
												'';//data validade // D3_ZSEQOS
												}) //Os produtos a serem utilizados
*/
	
	aSize := MsAdvSize()
	aObjects := {}
	AAdd( aObjects, { 80, 80, .T., .T. } )
	
	aInfo := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 }
	aPosObj := MsObjSize( aInfo, aObjects )
	
	
		
	IndRegua(_xAliasA,FileNoExt(cNomeArqD),"FILIAL+CODIGO+PRODUTO+LOCALI+ENDERECO",,,"Selecionando Registros...")
	(_xAliasA)->(dbgotop())
	
	aCores := {}
	aAdd(_aCores,{_xAliasA+"->STATUS == '0'","BR_VERDE"	})
	aAdd(_aCores,{_xAliasA+"->STATUS == '1'","BR_AMARELO"	})
	aAdd(_aCores,{_xAliasA+"->STATUS == '2'","BR_VERMELHO"})
	
	If((_xAliasA)->(EOF()))
		msginfo('Nenhum registro com divergência de quantidade.','Consulta de Divergêcias')
	Else
		DEFINE MSDIALOG _oDlg2 TITLE "Divergência de Saldo de Produtos" From aSize[7],0 To aSize[6],aSize[5] PIXEL
		
		//Cria a MsSelect
		//_oMark := MsSelect():New(_xAlias,"OK","",_aCpoBro,@_lInverte,@_cMark,{aPosObj[1,1],aPosObj[1,2],aPosObj[1,3],aPosObj[1,4]},,,,,_aCores)
		
		_oMarkA := MsSelect():New((_xAliasA),"OK","",_aCpoBro2,@_lInverte,@_cMark,{aPosObj[1,1],aPosObj[1,2],aPosObj[1,3],aPosObj[1,4]},,,,,_aCores)
		_oMarkA:oBrowse:lHasMark		  := .T.
		_oMarkA:oBrowse:lCanAllmark	  := .T.
		_oMarkA:oBrowse:lAdjustColSize := .T.
		_oMarkA:oBrowse:lJustific      := .F.
		_oMarkA:bAval 				  := {|| RMark(.F.,_xAliasA,_oMarkA)}
		_oMarkA:oBrowse:bAllMark 	  := {|| RMarkAll(_xAliasA,_oMarkA)}
		//Exibe a Dialog
		ACTIVATE MSDIALOG _oDlg2 CENTERED ON INIT EnchoiceBar(_oDlg2,{|| nOpcA:=1, _oDlg2:End()},{|| _oDlg2:End()})
		
		//(_xAlias)->(DbCloseArea())
	EndIf
	/*
	_oDlg := TDialog():New(aSize[7],0,aSize[6],aSize[5],"Baixas Parciais em Lote" ,,,,,,,,,.T.,,,,,)
_oDlg:lCentered := .T.
_oDlg:bInit     := EnchoiceBar(_oDlg, {|| nOpcA:=1, _oDlg:End() },{|| _oDlg:End()},,aButtons)
	*/

	If nOpcA == 1 
		
		
		(_xAliasA)->(dbgotop())
		While((_xAliasA)->(!EOF()))
			If(!empty((_xAliasA)->OK)) // foi selecionado
				If(_aConf[(_xAliasA)->(Recno())][1]=='3')
					//executa a transferencia do produto
					
					Begin Transaction
						//eecview(varinfo('transf3 - pre',_aConf[(_xAliasA)->(Recno())][2]))
						//If(msgyesno('efetiva transferencia','teste'))
							If(sfMata261(_aConf[(_xAliasA)->(Recno())][2]))
								//altera z16 para o endereço indicado ao fim da transferencia de estoque
								//Posiciona na Z16
								Z16->(dbgoto(_aConf[(_xAliasA)->(Recno())][2][1][14]))

								//Se saldo igual a transferencia (Total) envia a etoqueta para destino 
								If(Z16->Z16_SALDO = _aConf[(_xAliasA)->(Recno())][2][1][3])
									RECLOCK('Z16',.F.)
										Z16->Z16_ENDATU:=_aConf[(_xAliasA)->(Recno())][2][1][7]		
									Z16->(MSUNLOCK())
								Else
									RECLOCK('Z16',.F.)
										Z16->Z16_ENDATU	:= _aConf[(_xAliasA)->(Recno())][2][1][7]		
										Z16->Z16_SALDO	-= _aConf[(_xAliasA)->(Recno())][2][1][3]		
									Z16->(MSUNLOCK())
									sfTransfCriaEtiqueta(_aConf[(_xAliasA)->(Recno())][2][1][6],_aConf[(_xAliasA)->(Recno())][2][1][3])
								EndIf
								
								_aRelat := _aConf[(_xAliasA)->(Recno())][3]

								aAdd(_aReg,{'1',_aConf[(_xAliasA)->(Recno())][3],'Etiqueta Transferida de '+AllTrim(_aConf[(_xAliasA)->(Recno())][2][1][6])+' para '+alltrim(_aConf[(_xAliasA)->(Recno())][2][1][7])+', Quantidade: '+transform(_aConf[(_xAliasA)->(Recno())][2][1][3],pesqpict('Z16','Z16_QUANT'))})						
							Else
								rollbacksx8()
								mostraerro()
								aAdd(_aReg,{'3',_aConf[(_xAliasA)->(Recno())][3],'Erro ao Transferir de '+AllTrim(_aConf[(_xAliasA)->(Recno())][2][1][6])+' para '+alltrim(_aConf[(_xAliasA)->(Recno())][2][1][7])+'.'})							
								
							EndIf
						//EndIf
					End Transaction
					//eecview(varinfo('transf3',_aConf[(_xAliasA)->(Recno())]))
				ElseIf(_aConf[(_xAliasA)->(Recno())][1]=='4')
				
					Begin Transaction
						//em validação 
						//encontrado produto a mais que no endereço / pallet - insere e solicita transferencia para Lost
						dbselectarea("Z16")
						If(Z16->(dbgoto(_aConf[(_xAliasA)->(Recno())][2][1])))
							
							//sfTransfCriaEtiqueta(,Quantidade,etiqueta)	
						
						EndIf
*/
						aadd(_aReg,{'3',_aConf[(_xAliasA)->(Recno())][3],'Etiqueta transferida de '+_aConf[(_xAliasA)->(Recno())][2][2]	+' para '+_aConf[(_xAliasA)->(Recno())][2][3]+' - em validação'})
									
					end transaction

				ElseIf(_aConf[(_xAliasA)->(Recno())][1]=='5')
				//eecview(varinfo('a',_aConf[(_xAliasA)->(Recno())]),'Tipo de correção '+_aConf[(_xAliasA)->(Recno())][1])
				//Corrige saldo Z16
				//_aDados := _aConf[(_xAliasA)->(Recno())][2]
				
				dbselectarea("Z16")
				Z16->(dbgoto(_aConf[(_xAliasA)->(Recno())][3][9]))
				
				BEGIN TRANSACTION

				RECLOCK('Z16',.F.)
					Z16->Z16_SALDO:=_aConf[(_xAliasA)->(Recno())][3][8]			
				Z16->(MSUNLOCK())
				
				END TRANSACTION
				
				
				/*
				Begin Transaction
						//em validação 
						//encontrado produto a mais que no endereço / pallet - insere e solicita transferencia para Lost
						dbselectarea("Z16")
						RECLOCK('Z16',.T.)
							Z16->Z16_FILIAL	:= _aDados[01]
							Z16->Z16_ETQPAL	:= _aDados[02]
							//Z16->Z16_PLTORI := _aDados[03]
							//Z16->Z16_UNITIZ	:= _aDados[04]
							Z16->Z16_ETQPRD	:= _aDados[05]
							Z16->Z16_CODPRO	:= _aDados[06]
							Z16->Z16_QUANT	:= _aDados[07]
							//Z16->Z16_QTSEGU := _aDados[08]
							Z16->Z16_SALDO  := _aDados[09]
							Z16->Z16_NUMSEQ	:= _aDados[10]
							Z16->Z16_STATUS	:= "T" // V=Vazio / T=Total / P=Parcial
							Z16->Z16_QTDVOL	:= 1
							Z16->Z16_ENDATU := _aDados[13]
							Z16->Z16_ORIGEM := "Z19"
							Z16->Z16_LOCAL  := _aDados[15]
							//Z16->Z16_TPESTO := _aDados[16]
							Z16->Z16_CODBAR := _aDados[17]
							Z16->Z16_EMBALA := ''//_aDados[18] VALIDAR (_xAlias2)->Z19_EMBALA
							Z16->Z16_ETQVOL := _aDados[19]
							Z16->Z16_VOLORI := _aDados[20]
							Z16->Z16_PLTCLI := _aDados[21]
							Z16->Z16_CARGA  := _aDados[22]
							Z16->Z16_ONDSEP := _aDados[23]
							Z16->Z16_PEDIDO := _aDados[24]
							Z16->Z16_DATA   := Date()
							Z16->Z16_HORA   := Time()
							Z16->Z16_LOTCTL := _aDados[27]
							//Z16->Z16_VLDLOT := _aDados[28] //StoD((_xAlias2)->Z19_VLDLOT)
							//Z16->Z16_NUMSER := _aDados[29] //(_xAlias2)->Z19_NUMSER //VALIDAR
							//Z16->Z16_DTSERI := _aDados[30] //StoD((_xAlias2)->Z19_DTSERI)//VALIDAR
						Z16->(MsUnLock())		
*/
						aadd(_aReg,{'1',_aConf[(_xAliasA)->(Recno())][3],'Saldo alterado para '+AllTrim(Transform(_aConf[(_xAliasA)->(Recno())][3][8],pesqpict('Z16','Z16_SALDO')))+'.'})
									
				//	end transaction
				
				
					
					//aadd(_aReg,_aConf[(_xAliasA)->(Recno())][3],'em validação - transferencia de etiqueta <br><br>'+varinfo('a',_aConf[(_xAliasA)->(Recno())]))
				ElseIf(_aConf[(_xAliasA)->(Recno())][1]=='6')
					//eecview(varinfo('b',_aConf[(_xAliasA)->(Recno())]),'Tipo de correção '+_aConf[(_xAliasA)->(Recno())][1])
					//Corrige saldo Z16
					
					//COPIA A ETIQUETA ATUAL PARA LOST
					
					
					//aadd(_aReg,{'1',_aConf[(_xAliasA)->(Recno())][3],'Etiqueta Transferida para '+_aConf[(_xAliasA)->(Recno())][2][1][7]	})
				else
					//eecview(varinfo('a',_aConf[(_xAliasA)->(Recno())]),'Tipo de correção '+_aConf[(_xAliasA)->(Recno())][1])
					aadd(_aReg,_aConf[(_xAliasA)->(Recno())][3],'em validação - transferencia de etiqueta <br><br>'+varinfo('a',_aConf[(_xAliasA)->(Recno())]))				
				EndIf
			EndIf
			
			(_xAliasA)->(dbskip())
		EndDo
		

	Endif

	//Fecha a Area e elimina os arquivos de apoio criados em disco.
	Iif(File(cNomeArqD + GetDBExtension()),FErase(cNomeArqD  + GetDBExtension()) ,Nil)
	(_xAliasA)->(DbCloseArea())
	RestArea(_aArea)


Return _lRet

//USER  function UF021E2(_xEnde,_XQuant)
Static function sfTransfCriaEtiqueta(_xEnde,_XQuant,_xEtq,_xPal)


Local _aArea1 := GETAREA()

Default _xEnde := ''
Default _xQuant := 0
Default _xEtq := ''//getsxenum('Z11','Z11_CODETI',xFilial('Z11'))
Default _xPal := ''//getsxenum('Z11','Z11_CODETI',xFilial('Z11'))

Begin Transaction 

	//CRIA ETIQUETA Z11

	//copia da z16 para a variavel de memória
	REGTOMEMORY("Z16",.F.)
	
	//pega os campos da SX3 para preenchimento automático
	dbSelectArea("SX3")
	SX3->(DbSetOrder(1))
	SX3->(DbSeek("Z16"))

	RecLock('Z16',.T.)
		While (SX3->(!EOF() .AND. X3_ARQUIVO = 'Z16'))
			If X3USO(SX3->X3_USADO) //SX3->X3_CAMPO
				&('Z16->'+ALLTRIM(SX3->X3_CAMPO)) := &('M->'+ALLTRIM(SX3->X3_CAMPO))
			EndIf// Z16->Z16_ETQPAL // M->Z16_ETQPAL
			SX3->(DBSKIP())
		EndDo
		
		//Atualiza os campos recebidos por parametro
		Z16->Z16_FILIAL	:= M->Z16_FILIAL
		Z16->Z16_DATA 	:= DATE()
		Z16->Z16_HORA	:= TIME()
		Z16->Z16_ENDATU := _xEnde
		Z16->Z16_SALDO  := _xQuant
		Z16->Z16_VOLORI := M->Z16_ETQVOL
		Z16->Z16_ETQVOL := _xEtq
		Z16->Z16_ETQPAL := _xPal
	
	Z16->(MSUNLOCK())
	
	//MSGALERT('Z16 recno '+CVALTOCHAR(Z16->(RECNO())),'Criada Etiqueta '+_xEtq)
	
	confirmsx8()
End Transaction
	
RESTAREA(_aArea1)
	
RETURN .t.






USER FUNCTION UF021E()
Local aLista := {}
Local _lRet := .T.

	dbselectarea('Z11')
	
	dbselectarea('Z16')
	Z16->(dbsetorder(4)) // 
	If(Z16->(dbseek(Xfilial('Z16')+'0001834048')))
		//MSGALERT(VARINFO('aLista',aLista),'UF021T')
			
		//If(sfTransfCriaEtiqueta('02B10010065501',4))
		If(u_UF021E2('02B10010065501',4))
			//transferencia realizada
			_lRet := .T.
		Else
			_lRet := .F.
			//erro ao realizar transferencia, favor verificar saldos
		EndIf
	//MSGALERT('APOS sfMata261','UF021T')
	EndIf

	

Return _lRet
