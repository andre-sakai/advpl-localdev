#INCLUDE "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Pagamento de Fretes                                     !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2010                                                 !
+------------------+--------------------------------------------------------*/

User Function TFINA001

	Local _aBrwCores := {{"!Empty(ZF_NFFORNE)","ENABLE"},{"Empty(ZF_NFFORNE)","BR_AZUL"}}

	// lista de fechamentos
	dbSelectArea("SZF")

	Private cCadastro := "Pagamento de Fretes"

	Private aRotina := { ;
		{ "Pesquisar" , "AxPesqui"       ,0,1},;
		{ "Visualizar", "AxVisual"       ,0,2},;
		{ "Fechamento", "U_FINA001B()"   ,0,3},;
		{ "Relatório" , "U_FINA001C(.f.)",0,4},;
		{ "Legenda"   , "U_FINA001A()"   ,0,2},;
		{ "Estorno"   , "U_FINA001D()"   ,0,5} }

	DbSelectArea("SZF")
	SZF->(DbSetOrder(1))
	mBrowse(6,1,22,75,"SZF",,,,,,_aBrwCores)

Return

// ** funcao que Monta a Legenda
User Function FINA001A()

	BrwLegenda(	cCadastro, "Status do Fechamento",;
		{{"ENABLE","Nota Fiscal Lançada"},{"BR_AZUL","Aguardando Nota Fiscal"}} )

Return .T.

// ** funcao que realiza o fechamento de frete
User Function FINA001B()

	// preguntas
	Local _aPerg := {}
	Local _cPerg := PadR("TFINA001",10)

	// criacao das Perguntas
	aAdd(_aPerg,{"Transportadora?"  , "C", TamSx3("A4_COD")[1],0,"G",,"SA4"})       // mv_par01
	aAdd(_aPerg,{"Veiculo De?"      , "C", TamSx3("DA3_COD")[1],0,"G",,"DA3"})      // mv_par02
	aAdd(_aPerg,{"Veiculo Ate?"     , "C", TamSx3("DA3_COD")[1],0,"G",,"DA3"})      // mv_par03
	aAdd(_aPerg,{"Dt. Movimto. De?" , "D", 8,0,"G",,""})                            // mv_par04
	aAdd(_aPerg,{"Dt. Movimto. Até?", "D", 8,0,"G",,""})                            // mv_par05
	aAdd(_aPerg,{"Filial De?"       , "C", TamSx3("A4_FILIAL")[1],0,"G",,"SM0"})    // mv_par06
	aAdd(_aPerg,{"Filial Até?"      , "C", TamSx3("A4_FILIAL")[1],0,"G",,"SM0"})    // mv_par07
	aAdd(_aPerg,{"% Desconto"       , "N", 1,0,"G",,""})                            // mv_par08
	aAdd(_aPerg,{"Tipo Carga"       , "N", 1,0,"C",{"Container","Carga Solta"},""}) // mv_par09

	// cria grupo de perguntas
	U_FtCriaSX1( _cPerg,_aPerg )

	If ! Pergunte(_cPerg,.T.)
		Return
	EndIf

	// armazena em variaveis
	Private _cCodTransp	:= mv_par01
	Private _cDscTransp	:= ""
	Private _cPlacaDe	:= mv_par02
	Private _cPlacaAte	:= mv_par03
	Private _dMovmtoDe	:= mv_par04
	Private _dMovmtoAte	:= mv_par05
	Private _cFilialDe	:= mv_par06
	Private _cFilialAte	:= mv_par07
	Private _nPercDesc	:= mv_par08

	// verifica se a transportadora foi informada
	If (Empty(_cCodTransp))
		MsgStop("É obrigatório informar a transportadora!")
		Return(.f.)
	EndIf

	// busca as informacoes
	MsgRun("Aguarde. Selecionando Dados...",,{|| sfMntDados() })

Return

// ** funcao que busca os dados conforme os parametros e monta a tela
Static Function sfMntDados()
	Local _cQrySZ3 := ""
	// desconto geral
	Local _nDescGeral := (_nPercDesc > 0)
	// estrutura do arquivo de trabalho e Browse
	Local _aEstrTrb	:= {}
	Local _aHeadBrw	:= {}
	Local _cMarca	:= GetMark()
	// dimensoes da tela
	Local _aSizeDlg	:= MsAdvSize()

	// variavel para exportação para excel
	Local _oBtnExcel

	// fontes utilizadas
	Private _oFntProd := TFont():New("Tahoma",,26,,.t.)
	Private _oFntRoda := TFont():New("Tahoma",,16,,.t.)
	// total a pagar
	Private _nTotPagar	:= 0
	// total de descontos
	Private _nTotDesc	:= 0
	// total de acrescimo
	Private _nTotAcres	:= 0
	// observacoes
	Private _cObserv	:= CriaVar("ZF_OBS")
	
	// FWTemporaryTable
	Private _oArqTmp
	Private _TRBMOV		:= GetNextAlias()

	// pesquisa se a transportadora tem tabela de preco informada
	dbSelectArea("SA4")
	SA4->(dbSetOrder(1)) //1-A4_FILIAL, A4_COD
	If ( ! SA4->(dbSeek( xFilial("SA4")+_cCodTransp )) )
		MsgStop("Transportadora não encontrada!")
		Return(.f.)
	EndIf

	// atualiza nome da transportadora
	_cDscTransp := SA4->A4_NOME

	// tabela de preco
	If (Empty(SA4->A4_TABPREC))
		MsgStop("Tabela de Preço não informado para a Transportadora!")
		Return(.f.)
	EndIf

	// monta o arquivo de trabalho
	aAdd(_aEstrTrb,{"IT_OK"		,"C", 2,0})
	aAdd(_aEstrTrb,{"IT_COR"	,"C", 2,0})
	aAdd(_aEstrTrb,{"Z3_FILIAL" ,"C", TamSx3("Z3_FILIAL")[1],0})
	aAdd(_aEstrTrb,{"Z3_DTMOVIM","D", TamSx3("Z3_DTMOVIM")[1],0})
	aAdd(_aEstrTrb,{"Z3_TPMOVIM","C", 7,0})
	aAdd(_aEstrTrb,{"Z3_DUPLO"	,"C", 7,0})
	aAdd(_aEstrTrb,{"Z3_RIC"	,"C", TamSx3("Z3_RIC")[1],0})
	aAdd(_aEstrTrb,{"Z3_CONTAIN","C", TamSx3("Z3_CONTAIN")[1],0})
	aAdd(_aEstrTrb,{"Z3_TAMCONT","C", TamSx3("Z3_TAMCONT")[1],0})
	aAdd(_aEstrTrb,{"Z3_TIPCONT","C", 12,0})
	aAdd(_aEstrTrb,{"Z3_CONTEUD","C", 5,0})
	aAdd(_aEstrTrb,{"Z3_PRCORIG","C", TamSx3("Z3_PRCORIG")[1],0})
	aAdd(_aEstrTrb,{"IT_PRCORIG","C", TamSx3("ZB_DESCRI")[1],0})
	aAdd(_aEstrTrb,{"Z3_PRCDEST","C", TamSx3("Z3_PRCDEST")[1],0})
	aAdd(_aEstrTrb,{"IT_PRCDEST","C", TamSx3("ZB_DESCRI")[1],0})
	aAdd(_aEstrTrb,{"Z3_PLACA1"	,"C", TamSx3("Z3_PLACA1")[1],0})
	aAdd(_aEstrTrb,{"IT_VLRTAB"	,"N", TamSx3("Z5_VALOR")[1],TamSx3("Z5_VALOR")[2]})
	aAdd(_aEstrTrb,{"IT_VLRPAG"	,"N", TamSx3("Z5_VALOR")[1],TamSx3("Z5_VALOR")[2]})
	aAdd(_aEstrTrb,{"Z3_USRINCL","C", TamSx3("Z3_USRINCL")[1],0})
	aAdd(_aEstrTrb,{"Z3_PROGRAM","C", TamSx3("Z3_PROGRAM")[1],0})
	aAdd(_aEstrTrb,{"Z3_CLIENTE","C", TamSx3("Z3_CLIENTE")[1],0})
	aAdd(_aEstrTrb,{"Z3_LOJA"   ,"C", TamSx3("Z3_LOJA")[1],0})
	aAdd(_aEstrTrb,{"SZ3RECNO"	,"N", 10,0})

	// busca as movimentacoes
	_cQrySZ3 := "SELECT '  ' IT_OK, "
	// define legenda, caso nao tenha tabela de frete
	_cQrySZ3 += "CASE WHEN Z5_VALOR IS NULL THEN '  ' ELSE 'OK' END IT_COR, "
	_cQrySZ3 += "Z3_FILIAL, Z3_DTMOVIM, "
	_cQrySZ3 += "CASE WHEN Z3_TPMOVIM = 'S' THEN 'SAIDA' ELSE 'ENTRADA' END Z3_TPMOVIM, "
	// duplo
	_cQrySZ3 += "CASE WHEN Z3_DUPLO = 'S' THEN 'DUPLO' ELSE 'SIMPLES' END Z3_DUPLO,
	_cQrySZ3 += "Z3_RIC, Z3_CONTAIN, Z3_TAMCONT, "
	// tipo de container
	_cQrySZ3 += "Z3_TIPCONT+'-'+RTRIM(X5_DESCRI) Z3_TIPCONT, "
	// conteudo
	_cQrySZ3 += "CASE WHEN Z3_CONTEUD = 'C' THEN 'CHEIO' "
	_cQrySZ3 += "     WHEN Z3_CONTEUD = 'V' THEN 'VAZIO' "
	_cQrySZ3 += "ELSE 'OUTRO' END Z3_CONTEUD, "
	// praca de origem
	_cQrySZ3 += "Z3_PRCORIG, Z3_PRCORIG+'-'+SZBORIG.ZB_DESCRI IT_PRCORIG, "
	// praca destino
	_cQrySZ3 += "Z3_PRCDEST, Z3_PRCDEST+'-'+SZBDEST.ZB_DESCRI IT_PRCDEST, "
	// placa
	_cQrySZ3 += "Z3_PLACA1, "
	// valor da tabela
	_cQrySZ3 += "ISNULL(Z5_VALOR,0) IT_VLRTAB, "
	// valor pago (com controle de desconto)
	_cQrySZ3 += "ISNULL(Z5_VALOR,0)"+If(_nDescGeral," - (ISNULL(Z5_VALOR,0) * "+Str((_nPercDesc / 100),5,2)+") ","")+" IT_VLRPAG, "
	// usuario resp inclusao
	_cQrySZ3 += "Z3_USRINCL, "
	// programacao
	_cQrySZ3 += "Z3_PROGRAM, "
	// cod e loja cliente
	_cQrySZ3 += "Z3_CLIENTE, Z3_LOJA, "
	// RECNO DO SZ3
	_cQrySZ3 += "SZ3.R_E_C_N_O_ SZ3RECNO "

	// movimentacoes de entrada/saida
	_cQrySZ3 += "FROM "+RetSqlName("SZ3")+" SZ3 "

	// tabela de preco
	_cQrySZ3 += "LEFT JOIN "+RetSqlName("SZ5")+" SZ5 ON "+RetSqlCond("SZ5")+" "
	_cQrySZ3 += "		   AND Z5_CODIGO = '"+SA4->A4_TABPREC+"' "
	_cQrySZ3 += "		   AND ( ((Z5_PRCORIG + '|' + Z5_PRCDEST) LIKE '%'+Z3_PRCORIG+'%') AND ((Z5_PRCORIG + '|' + Z5_PRCDEST) LIKE '%'+Z3_PRCDEST+'%') ) "
	_cQrySZ3 += "		   AND Z5_CONTEUD = Z3_CONTEUD "
	// tipo do container
	_cQrySZ3 += "		   AND Z5_TIPCONT LIKE '%'+Z3_TIPCONT+'%' "

	// descricao da praca de origem
	_cQrySZ3 += "INNER JOIN "+RetSqlName("SZB")+" SZBORIG ON "
	_cQrySZ3 += "		   SZBORIG.ZB_FILIAL = '"+xFilial("SZB")+"' AND SZBORIG.D_E_L_E_T_ = ' ' AND SZBORIG.ZB_CODIGO = Z3_PRCORIG "

	// descricao da praca de destino
	_cQrySZ3 += "INNER JOIN "+RetSqlName("SZB")+" SZBDEST ON "
	_cQrySZ3 += "		   SZBDEST.ZB_FILIAL = '"+xFilial("SZB")+"' AND SZBDEST.D_E_L_E_T_ = ' ' AND SZBDEST.ZB_CODIGO = Z3_PRCDEST "

	// tipo do container
	_cQrySZ3 += "LEFT JOIN "+RetSqlName("SX5")+" SX5 ON "+RetSqlCond("SX5")+" AND X5_TABELA = 'ZA' AND X5_CHAVE = Z3_TIPCONT "

	// filtro da movimentacoes
	_cQrySZ3 += "WHERE Z3_FILIAL BETWEEN '"+_cFilialDe+"' AND '"+_cFilialAte+"' AND SZ3.D_E_L_E_T_ = ' ' "
	// transportadora
	_cQrySZ3 += "AND Z3_TRANSP = '"+_cCodTransp+"' "
	// placa
	_cQrySZ3 += "AND Z3_PLACA1 BETWEEN '"+_cPlacaDe+"' AND '"+_cPlacaAte+"' "
	// data de movimentacao
	_cQrySZ3 += "AND Z3_DTMOVIM BETWEEN '"+DtoS(_dMovmtoDe)+"' AND '"+DtoS(_dMovmtoAte)+"' "
	// data de fechamento
	_cQrySZ3 += "AND Z3_DTPGTOF = ' ' "

	// controle do conteudo da carga
	If (mv_par09 == 1) // container
		_cQrySZ3 += "AND ( Z3_TAMCONT <> 'CS' AND Z3_TIPCONT <> '99') "
	ElseIf (mv_par09 == 2) // carga solta
		_cQrySZ3 += "AND (Z3_TAMCONT   = 'CS' AND Z3_TIPCONT  = '99') "
	EndIf

	// ordem dos dados
	_cQrySZ3 += "ORDER BY Z3_FILIAL, Z3_RIC"

	memowrit("c:\query\tfina001.txt",_cQrySZ3)

	// fecha alias do TRB
	If (Select("_TRBMOV")<>0)
		(_TRBMOV)->(dbSelectArea(_TRBMOV))
		dbCloseArea()
	EndIf

	// criar um arquivo de trabalho
	_oArqTmp := FWTemporaryTable():New(_TRBMOV)
	_oArqTmp:SetFields(_aEstrTrb)
	_oArqTmp:Create()
	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQrySZ3,_aEstrTrb,_TRBMOV)

	// executa funcao para controle do pagamento de movimentacao dupla
	sfPagtoDuplo()

	// inclui detalhes e titulos dos campos do browse
	aAdd(_aHeadBrw,{"IT_OK"		,"","  "})
	aAdd(_aHeadBrw,{"Z3_FILIAL" ,"","Filial"})
	aAdd(_aHeadBrw,{"Z3_DTMOVIM","","Data Movim."})
	aAdd(_aHeadBrw,{"Z3_TPMOVIM","",RetTitle("Z3_TPMOVIM")})
	aAdd(_aHeadBrw,{"Z3_DUPLO"	,"","Dupla/Simples"})
	aAdd(_aHeadBrw,{"Z3_RIC"	,"","Nr. RIC"})
	aAdd(_aHeadBrw,{"Z3_CONTAIN","","Container",PesqPict("SZC","ZC_CODIGO")})
	aAdd(_aHeadBrw,{"Z3_TAMCONT","","Tamanho"})
	aAdd(_aHeadBrw,{"Z3_TIPCONT","","Tipo"})
	aAdd(_aHeadBrw,{"Z3_CONTEUD","","Conteúdo"})
	aAdd(_aHeadBrw,{"IT_PRCORIG","","Praca Origem"})
	aAdd(_aHeadBrw,{"IT_PRCDEST","","Praca Destino"})
	aAdd(_aHeadBrw,{"Z3_PLACA1"	,"","Placa",PesqPict("SZ3","Z3_PLACA1")})
	aAdd(_aHeadBrw,{"IT_VLRTAB"	,"","Vlr. Tabela",PesqPict("SZ5","Z5_VALOR")})
	aAdd(_aHeadBrw,{"IT_VLRPAG"	,"","Vlr. Pago",PesqPict("SZ5","Z5_VALOR")})

	// abre o arquivo de trabalho
	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	(_TRBMOV)->(dbGoTop())

	// monta o dialogo
	_oDlgFrete := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Pagamento de Fretes",,,.F.,,,,,,.T.,,,.T. )
	_oDlgFrete:lMaximized := .T.

	// cria o panel do cabecalho
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgFrete,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// informacoes da transportadora
	_oSayTransp := TSay():New(004,010,{||"Transportadora: "+_cCodTransp+"-"+_cDscTransp },_oPnlCabec,,_oFntProd,.F.,.F.,.F.,.T.)

	// cria o panel do rodape
	_oPnlRodape := TPanel():New(000,000,nil,_oDlgFrete,,.F.,.F.,,,000,040,.T.,.F. )
	_oPnlRodape:Align := CONTROL_ALIGN_BOTTOM
	// total de descontos
	_oSayDesc := TSay():New(005,010,{||"Descontos..." },_oPnlRodape,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetDesc := TGet():New(003,070,{|u| If(PCount()>0,_nTotDesc:=u,_nTotDesc) },_oPnlRodape,060,010,PesqPict("SE1","E1_SALDO"),{||Positivo().and.sfAtuTotal()},,,_oFntRoda,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nTotDesc",,)
	// total de acrescimos
	_oSayAcres := TSay():New(005,164,{||"Acréscimo..." },_oPnlRodape,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetAcres := TGet():New(003,210,{|u| If(PCount()>0,_nTotAcres:=u,_nTotAcres) },_oPnlRodape,060,010,PesqPict("SE1","E1_SALDO"),{||Positivo().and.sfAtuTotal()},,,_oFntRoda,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nTotAcres",,)

	// opcao de visualizar a movimentacao da carga
	_oBtnVisMov := TButton():New(003,363,"Vis. Movim. Carga",_oPnlRodape,{|| U_WMSV002B((_TRBMOV)->Z3_FILIAL,(_TRBMOV)->Z3_RIC ) }                   ,046,012,,,,.T.,,"",,,,.F. )
	_oBtnExcel  := TButton():New(003,293,"Exportar Excel"   ,_oPnlRodape,{|| sfExpExcel() } ,046,012,,,,.T.,,"",,,,.F. )

	// observacoes
	_oSayObs := TSay():New(020,164,{||"Observações" },_oPnlRodape,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetObs := TGet():New(018,210,{|u| If(PCount()>0,_cObserv:=u,_cObserv) },_oPnlRodape,200,010,PesqPict("SZF","ZF_OBS"),,,,_oFntRoda,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cObserv",,)
	// total
	_oSayTotal := TSay():New(020,010,{||"Total a Pagar..." },_oPnlRodape,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetTotal := TGet():New(018,070,{|u| If(PCount()>0,_nTotPagar:=u,_nTotPagar) },_oPnlRodape,060,010,PesqPict("SE1","E1_SALDO"),,,,_oFntRoda,,,.T.,"",,,.F.,.F.,,.t.,.F.,"","_nTotPagar",,)

	// browse com a listagem da movimentacoes
	_oBrwFrete := MsSelect():New(_TRBMOV,"IT_OK",,_aHeadBrw,,_cMarca,{15,1,183,373},,,,,;
		{{"Empty((_TRBMOV)->IT_COR)","DISABLE"},{"!(Empty((_TRBMOV)->IT_COR))","ENABLE"}})
	_oBrwFrete:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwFrete:bMark := {|| sfVldMark(_cMarca) }
	_oBrwFrete:oBrowse:bAllMark := {|| sfMarkAll(_cMarca) }

	// ativa a tela
	ACTIVATE MSDIALOG _oDlgFrete CENTERED ON INIT sfMntEncBar()

	// fecha arquivo de trabalho
	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	dbCloseArea()
	_oArqTmp:Delete()

Return

// ** funcao que monta a EnchoiceBar da tela
Static Function sfMntEncBar()
	local _oBar		:= TBar():New(_oDlgFrete, 025, 025, .T.)
	local _oBtnImpr	:= TBtnBmp():NewBar("RELATORIO"	,,,,,{|| U_FINA001C(.t.) },.F.,_oBar,.F.,,"",.F.,,,,"")
	local _oBtnEdit	:= TBtnBmp():NewBar("EDIT"		,,,,,{|| sfEditVlr() },.F.,_oBar,.F.,,"" ,.F.,,,,"")
	local _oBtnOk	:= TBtnBmp():NewBar("OK"		,,,,,{|| MsgRun("Aguarde... Gerando financeiro...",,{|| sfGeraFin() }) },.F.,_oBar,.F.,,"" ,.F.,,,,"")
	local _oBtnSair	:= TBtnBmp():NewBar("FINAL"		,,,,,{|| _oDlgFrete:End() },.F.,_oBar,.F.,,"" ,.F.,,,,"")
	
	_oBar:bRClicked := {|| AlwaysTrue()}

Return Nil

// ** funcao que calcula os valores totais do radapé
Static Function sfAtuTotal()
	Local _aAreaAtu := (_TRBMOV)->(GetArea())
	// zera variaveis
	_nTotPagar := 0

	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	(_TRBMOV)->(dbGoTop())
	
	While (_TRBMOV)->(!Eof())
		// verifica se esta desmarcado
		If (Empty((_TRBMOV)->IT_OK))
			(_TRBMOV)->(dbSkip())
			Loop
		EndIf
		// atualiza valores
		_nTotPagar += (_TRBMOV)->IT_VLRPAG
		// proximo item
		(_TRBMOV)->(dbSkip())
	EndDo

	// descontos
	_nTotPagar -= _nTotDesc

	// acrescimos
	_nTotPagar += _nTotAcres

	// restaura area inicial
	RestArea(_aAreaAtu)

	// atualiza os campos
	_oGetTotal:Refresh()
	// refresh do browse
	_oBrwFrete:oBrowse:Refresh()

Return(.t.)

// ** funcao que valida a marcacao do item
Static Function sfVldMark(mvMarca)
	// area inicial
	local _aAreaAtu := (_TRBMOV)->(GetArea())

	// se nao tiver valor de tabela de preco
	If (Empty((_TRBMOV)->IT_COR))
		// se for movimentacao dupla, marca os 2
		// mantem o item desmarcado
		(_TRBMOV)->(RecLock(_TRBMOV))
		(_TRBMOV)->IT_OK := Space(2)
		(_TRBMOV)->(MsUnLock())
		// mensagem
		Aviso("TFINA001 -> sfVldMark","Ação não permitida, pois a movimentação não tem valor definido.",{"Fechar"})

		// se for movimentacao dupla, marca o item
	ElseIf (Left((_TRBMOV)->Z3_DUPLO,1)=="D")
		// guarda conteudo
		mvMarca := (_TRBMOV)->IT_OK
		// se for o item com valor, marca o proximo registro
		If ((_TRBMOV)->IT_VLRPAG > 0)
			(_TRBMOV)->(dbSkip())
			// se for sem valor, marca o registro anterior
		ElseIf ((_TRBMOV)->IT_VLRPAG == 0)
			(_TRBMOV)->(dbSkip(-1))
		EndIf

		// muda status da marcacao
		(_TRBMOV)->(RecLock(_TRBMOV))
		(_TRBMOV)->IT_OK := mvMarca
		(_TRBMOV)->(MsUnLock())
	EndIf

	// restaura area inicial
	RestArea(_aAreaAtu)

	// atualiza o valor total
	sfAtuTotal()

Return(.t.)

// ** funcao para alterar o valor a ser pago
Static Function sfEditVlr()
	// controle para nao fechar a tela
	Local _lFixaMain := .F.
	// valor atual
	Private _nVlrInfor := (_TRBMOV)->IT_VLRPAG

	// verifica a permissao para alterar o valor
	If ((_TRBMOV)->IT_VLRTAB == 0).or.((Left((_TRBMOV)->Z3_DUPLO,1)=="D").and.((_TRBMOV)->IT_VLRPAG==0))
		Aviso("TFINA001 -> sfEditVlr","Alteração do valor não permitida.",{"Fechar"})
		Return(.f.)
	EndIf

	// monta a tela para alterar o valor
	_oDlgInfVlr := MSDialog():New(000,000,100,240,"Informe o Valor",,,.F.,,,,,,.T.,,,.T. )
	_oSayValor := TSay():New( 007,010,{||"Valor R$:"},_oDlgInfVlr,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetValor := TGet():New( 005,050,{|u| If(PCount()>0,_nVlrInfor:=u,_nVlrInfor)},_oDlgInfVlr,60,10,PesqPict("SZ5","Z5_VALOR"),{||Positivo()},,,_oFntRoda,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nVlrInfor",,)
	// botao para confirmar
	_oBtnConfirmar := TButton():New(025,040,"Confirmar",_oDlgInfVlr,{||_lFixaMain:=.t.,_oDlgInfVlr:End()},050,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgInfVlr:Activate(,,,.T.,{||_lFixaMain})

	// se foi confirmado
	If (_lFixaMain)
		(_TRBMOV)->(RecLock(_TRBMOV))
		(_TRBMOV)->IT_VLRPAG := _nVlrInfor
		(_TRBMOV)->(MsUnLock())
		// atualiza total
		sfAtuTotal()
	Endif

Return

// ** funcao para gerar o titulo financeiro
Static Function sfGeraFin()
	// numero do fechamento
	Local _cNumFech	:= CriaVar("ZF_NUM",.t.)
	// area inicial
	Local _aAreaAtu := (_TRBMOV)->(GetArea())
	// quantidade de movimentacoes
	Local _nQtdMov	:= 0
	// valor total da tabela de preco
	Local _nTotTab	:= 0

	// verifica se tem saldo a pagar
	If (_nTotPagar <= 0)
		MsgStop("Não há saldo para fechamento!")
		Return(.f.)
	EndIf

	// inicia transacao
	BEGIN TRANSACTION

		// varre todos os itens selecionados
		(_TRBMOV)->(dbSelectArea(_TRBMOV))
		(_TRBMOV)->(dbGoTop())
		While (_TRBMOV)->(!Eof())
			// verifica se esta desmarcado
			If (Empty((_TRBMOV)->IT_OK))
				(_TRBMOV)->(dbSkip())
				Loop
			EndIf
			// marca movimentacao como paga
			dbSelectArea("SZ3")
			SZ3->(dbGoTo((_TRBMOV)->SZ3RECNO))
			RecLock("SZ3")
			SZ3->Z3_NUMFRET	:= _cNumFech
			SZ3->Z3_DTPGTOF	:= dDataBase
			SZ3->Z3_VLRTABE	:= (_TRBMOV)->IT_VLRTAB
			SZ3->Z3_VLRPAGO	:= (_TRBMOV)->IT_VLRPAG
			MsUnLock()

			// quantidade de movimentacoes
			_nQtdMov	+= 1
			// valor total da tabela de preco
			If (Left((_TRBMOV)->Z3_DUPLO,1) != "D").or.((Left((_TRBMOV)->Z3_DUPLO,1) == "D").and.((_TRBMOV)->IT_VLRPAG > 0))
				_nTotTab += (_TRBMOV)->IT_VLRTAB
			EndIf

			// proximo item
			(_TRBMOV)->(dbSelectArea(_TRBMOV))
			(_TRBMOV)->(dbSkip())
		EndDo

		// inclui a linha totalizadora do do fechamento de frete
		dbSelectArea("SZF")
		RecLock("SZF",.t.)
		SZF->ZF_FILIAL	:= xFilial("SZF")
		SZF->ZF_NUM		:= _cNumFech
		SZF->ZF_DATA	:= dDataBase
		SZF->ZF_TRANSP	:= _cCodTransp
		SZF->ZF_VLRTAB	:= _nTotTab
		SZF->ZF_DESC	:= _nTotDesc
		SZF->ZF_ACRESC	:= _nTotAcres
		SZF->ZF_VLRPAG	:= _nTotPagar
		SZF->ZF_QUANT	:= _nQtdMov
		SZF->ZF_USRFECH	:= __cUserId
		SZF->ZF_OBS		:= _cObserv
		MsUnLock()

		// confirma numeracao
		ConfirmSX8()

		// finaliza transacao
	END TRANSACTION

	// fecha a tela
	_oDlgFrete:End()

	MsgInfo("Fechamento Nr "+_cNumFech+" gerado com sucesso!")

Return

// ** funcao responsavel pela emissao do relatorio do fechamento
User Function FINA001C(mvTela)
	// declaracao de Variaveis
	LOCAL cDesc1       := "Relatorio com a relacao da movimentacoes que  "
	LOCAL cDesc2       := "compoe o fechamento do pagamento de fretes    "
	LOCAL cDesc3       := "                                              "
	LOCAL titulo       := "Pagamento de Frete"
	LOCAL Cabec1       := OemToAnsi("Fechamento de Frete")
	LOCAL Cabec2       := OemToAnsi("Seq     "+If(mvTela,"","Filial          ")+"Sentido     Data                 RIC                 Container                    Tamanho         Conteúdo            Duplo               Placa")
	LOCAL imprime      := .T.
	LOCAL aOrd         := {}

	PRIVATE lAbortPrint:= .F.
	PRIVATE limite     := 220
	PRIVATE tamanho    := "G"
	PRIVATE nomeprog   := "FINA001C"
	PRIVATE nTipo      := 18
	PRIVATE lEnd       := .F.

	PRIVATE aReturn    := { "Zebrado", 1, "Administracao", 1, 2, 1, "", 1}
	PRIVATE nLastKey   := 0
	PRIVATE cbtxt      := Space(10)
	PRIVATE cbcont     := 00
	PRIVATE CONTFL     := 01
	PRIVATE m_pag      := 01
	PRIVATE wnrel      := "FINA001C"

	PRIVATE cString    := "SZF"
	
	// define valor padrao para impressao de dados da tela
	Default mvTela := .f.

	wnrel:=SetPrint(cString,wnrel,"",@Titulo,cDesc1,cDesc2,cDesc3,.F.,aOrd,.F.,Tamanho)

	If nLastKey == 27
		Set Filter to
		Return
	Endif

	SetDefault (aReturn, cString)

	If nLastKey == 27
		Set Filter to
		Return
	Endif

	nTipo := IIF(aReturn[4]==1,15,18)

	// impressao dos dados da tela
	If (mvTela)
		RptStatus({|| sfImpTela(wnRel,tamanho,titulo,Cabec1,Cabec2,nTipo)},titulo)
	Else
		RptStatus({|| sfImprimir(wnRel,tamanho,titulo,Cabec1,Cabec2,nTipo)},titulo)
	EndIF

Return()

// ** funcao para impressao dos dados
Static Function sfImprimir(WnRel,tamanho,titulo,Cabec1,Cabec2,nTipo)

	Local _cQuery
	Local _nLin := 80
	Local _nSeq := 0
	// controle de quebra
	Local _cNumFech := ""
	// total a pagar
	Local _nTotPag	:= 0

	// monta a query
	_cQuery := " SELECT ZF_NUM, ZF_DATA, ZF_TRANSP, ZF_VLRPAG, ZF_DESC, ZF_ACRESC, ZF_VLRTAB, ZF_OBS, ZF_NFFORNE, "
	_cQuery += " Z3_FILIAL, Z3_DTMOVIM, Z3_RIC, Z3_CONTAIN, Z3_TAMCONT, Z3_CONTEUD, Z3_DUPLO, Z3_PRCORIG, Z3_PRCDEST, Z3_TPMOVIM, Z3_PLACA1, Z3_VLRTABE, Z3_VLRPAGO "
	// tabela dos fechamentos
	_cQuery += " FROM " + RetSqlTab("SZF") + " (NOLOCK) "
	// movimentacoes
	_cQuery += " INNER JOIN " + RetSqlTab("SZ3") + " (NOLOCK) "
	_cQuery += "		   ON Z3_FILIAL BETWEEN ' ' AND 'ZZZ' AND SZ3.D_E_L_E_T_ = ' ' "
	_cQuery += "		   AND Z3_NUMFRET = ZF_NUM "
	// filtro da tabela de fechamento
	_cQuery += " WHERE " + RetSqlCond("SZF")
	// numero do fechamento
	_cQuery += " AND ZF_NUM = '" + SZF->ZF_NUM + "' "
	// ordem dos dados
	_cQuery += " ORDER BY Z3_FILIAL, Z3_DTMOVIM, Z3_HRMOVIM"

	If (Select("_QRYSZF")<>0)
		dbSelectArea("_QRYSZF")
		dbCloseArea()
	EndIf

	dbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_QRYSZF",.F.,.T.)

	// tratamento para campos data
	TcSetField("_QRYSZF","ZF_DATA","D")
	TcSetField("_QRYSZF","Z3_DTMOVIM","D")

	dbSelectArea("_QRYSZF")
	_QRYSZF->(dbGotop())

	While _QRYSZF->(!Eof())

		If _nLin > 58
			cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
			_nLin := 9
		EndIf

		// quebra por fechamento
		If (_cNumFech<>_QRYSZF->ZF_NUM)
			// define as variaveis iniciais
			_cNumFech := _QRYSZF->ZF_NUM
			_nSeq := 1
			// informacoes do cabecalho
			@_nLin,000 PSAY "Número:             "+_cNumFech
			_nLin++
			@_nLin,000 PSAY "Emissão:            "+DtoC(_QRYSZF->ZF_DATA)
			_nLin++
			@_nLin,000 PSAY "Transportadora:     "+_QRYSZF->ZF_TRANSP+"-"+Posicione("SA4",1, xFilial("SA4")+_QRYSZF->ZF_TRANSP ,"A4_NOME")
			_nLin++
			@_nLin,000 PSAY "Número Nota Fiscal: "+_QRYSZF->ZF_NFFORNE
			_nLin++
			@_nLin,000 PSAY "Observações:        "+_QRYSZF->ZF_OBS
			_nLin++
			@_nLin,000 PSAY __PrtThinLine()
			_nLin++
			// totais
			_nTotPag := _QRYSZF->ZF_VLRPAG
		EndIf

		// impressao dos dados do item
		@_nLin,000 PSAY StrZero(_nSeq,3) +;
			"     Filial: "+_QRYSZF->Z3_FILIAL +;
			"     "+If(_QRYSZF->Z3_TPMOVIM=="E","ENTRADA","SAÍDA  ") +;
			"     Data: "+DtoC(_QRYSZF->Z3_DTMOVIM) +;
			"     RIC: " +_QRYSZF->Z3_RIC +;
			"     Container: "+Transf(_QRYSZF->Z3_CONTAIN,PesqPict("SZC","ZC_CODIGO")) +;
			"     Tamanho: "+_QRYSZF->Z3_TAMCONT +;
			"     Conteúdo: "+If(_QRYSZF->Z3_CONTEUD=="C","CHEIO","VAZIO") +;
			"     Duplo: "+If(_QRYSZF->Z3_DUPLO=="S","DUPLO  ","SIMPLES")+;
			"     Placa: "+_QRYSZF->Z3_PLACA1
		_nLin++
		// informacoes das pracas
		@_nLin,005 PSAY "Prc Origem: " +Posicione("SZB",1, xFilial("SZB")+_QRYSZF->Z3_PRCORIG ,"ZB_DESCRI")+;
			" " +;
			"Prc Destino: "+Posicione("SZB",1, xFilial("SZB")+_QRYSZF->Z3_PRCDEST ,"ZB_DESCRI")+;
			" " +;
			"Valor Tabela R$ " + Transf(_QRYSZF->Z3_VLRTABE,PesqPict("SZ3","Z3_VLRTABE"))+;
			" " +;
			"Valor Pago R$ " + Transf(_QRYSZF->Z3_VLRPAGO,PesqPict("SZ3","Z3_VLRPAGO"))

		// proxima sequencia
		_nSeq ++

		// proximo item
		_QRYSZF->(dbSkip())
		_nLin++

		// rodape com sub-total
		If (_cNumFech<>_QRYSZF->ZF_NUM)
			@_nLin,000 PSAY __PrtThinLine()
			_nLin++
			@_nLin,000 PSAY "Total a Pagar R$  "+Transf(_nTotPag,PesqPict("SE1","E1_SALDO"))
			_nLin++
			@_nLin,000 PSAY __PrtThinLine()
			_nLin++
		EndIf

	EndDo

	// fecha o alias da query
	dbSelectArea("_QRYSZF")
	dbCloseArea()


	SET DEVICE TO SCREEN
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Se impressao em disco, chama o gerenciador de impressao...          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If aReturn[5]==1
		dbCommitAll()
		SET PRINTER TO
		OurSpool(wnrel)
	ENDIF

	MS_FLUSH()

Return

// ** funcao responsavel pelo estorno do fechamento
User Function FINA001D

	// verifica a nota fiscal de entrada
	If (!Empty(SZF->ZF_NFFORNE))
		MsgStop("Estorno não permitido, pois já existe nota fiscal lançada!")
		Return(.f.)
	EndIf

	// solicita confirmacao
	If (!MsgYesNo("Confirma o estorno do Fechamento Nr. "+SZF->ZF_NUM+" ?"))
		Return(.f.)
	EndIf

	// processa estorno
	MsgRun("Aguarde... Estornando Fechamento ...",,{|| sfEstorTit() })

Return

// ** funcao para estorno do fechamento
Static Function sfEstorTit()
	Local _cQrySZ3
	local _aTmpRecno
	local _nX

	// inicia transacao
	BEGIN TRANSACTION

		// monta query para busca da movimentacoes de container
		_cQrySZ3 := "SELECT SZ3.R_E_C_N_O_ SZ3RECNO "
		_cQrySZ3 += "FROM "+RetSqlName("SZ3")+" SZ3 "
		_cQrySZ3 += "WHERE Z3_FILIAL != '999' AND SZ3.D_E_L_E_T_ = ' ' "
		_cQrySZ3 += "AND Z3_NUMFRET = '"+SZF->ZF_NUM+"'"

		// alimenta o vetor com os RECNOs das tabelas
		_aTmpRecno := U_SqlToVet(_cQrySZ3)

		// varre todos os itens para limpar os campos
		For _nX := 1 to Len(_aTmpRecno)
			// posiciona no registro da tabela
			dbSelectArea("SZ3")
			SZ3->(dbGoTo(_aTmpRecno[_nX]))
			RecLock("SZ3")
			SZ3->Z3_NUMFRET	:= CriaVar("Z3_NUMFRET")
			SZ3->Z3_DTPGTOF	:= CriaVar("Z3_DTPGTOF")
			SZ3->Z3_VLRTABE	:= 0
			SZ3->Z3_VLRPAGO	:= 0
			MsUnLock()
		Next _nX

		// exclui o registro do fechamento
		dbSelectArea("SZF")
		RecLock("SZF")
		SZF->(dbDelete())
		MsUnLock()

		// finaliza transacao
	END TRANSACTION

	MsgInfo("Estorno realizado com sucesso!")

Return(.t.)

// ** funcao para impressao dos dados da tela
Static Function sfImpTela(WnRel,tamanho,titulo,Cabec1,Cabec2,nTipo)
	// area inicial do TRB
	Local _aAreaTRB := (_TRBMOV)->(GetArea())
	Local _nLin := 80
	Local _nSeq := 1
	// controle de quebra de pagina por filial
	local _cTmpFilial := ""
	// total por filial
	local _nVlrTotal := 0

	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	(_TRBMOV)->(dbGoTop())

	While (_TRBMOV)->(!Eof())

		If (_nLin > 58).or.(_cTmpFilial <> (_TRBMOV)->Z3_FILIAL)
			// impressao do cabecalho
			cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
			_nLin := 9
			// dados da transportadora
			@_nLin,000 PSAY "Transportadora:    "+_cCodTransp+"-"+Posicione("SA4",1, xFilial("SA4")+_cCodTransp ,"A4_NOME")
			_nLin++
			// periodo do relatorio
			@_nLin,000 PSAY "Data Movimentacao: "+DtoC(_dMovmtoDe)+" até "+DtoC(_dMovmtoAte)
			_nLin++
			// filial
			@_nLin,000 PSAY "Filial:            "+(_TRBMOV)->Z3_FILIAL
			_nLin++
			@_nLin,000 PSAY __PrtThinLine()
			_nLin++
			// controle da quebra de pagina por filial
			If (_cTmpFilial <> (_TRBMOV)->Z3_FILIAL)
				// reinicia contador
				_nSeq := 1
				// chave da filial
				_cTmpFilial := (_TRBMOV)->Z3_FILIAL
				// reinicia o total
				_nVlrTotal := 0
			EndIf
		EndIf

		// impressao dos dados do item
		@_nLin,000 PSAY StrZero(_nSeq,3) +;
			"     "+(_TRBMOV)->Z3_TPMOVIM +;
			"     Data: "+DtoC((_TRBMOV)->Z3_DTMOVIM) +;
			"     RIC: " +(_TRBMOV)->Z3_RIC +;
			"     Container: "+Transf((_TRBMOV)->Z3_CONTAIN,PesqPict("SZC","ZC_CODIGO")) +;
			"     Tamanho: "+(_TRBMOV)->Z3_TAMCONT +;
			"     Conteúdo: "+(_TRBMOV)->Z3_CONTEUD +;
			"     Duplo: "+(_TRBMOV)->Z3_DUPLO +;
			"     Placa: "+(_TRBMOV)->Z3_PLACA1
		_nLin++
		// informacoes das pracas
		@_nLin,005 PSAY "Prc Origem: " +(_TRBMOV)->IT_PRCORIG +;
			"   " +;
			"Prc Destino: "+(_TRBMOV)->IT_PRCDEST +;
			"               Valor R$ " + Transf((_TRBMOV)->IT_VLRPAG,PesqPict("SE1","E1_VALOR"))

		// proxima sequencia
		_nSeq ++

		// controle do valor total
		_nVlrTotal += (_TRBMOV)->IT_VLRPAG

		// proximo item
		(_TRBMOV)->(dbSkip())
		_nLin++

		// sub-total da filial
		If (_cTmpFilial <> (_TRBMOV)->Z3_FILIAL)
			@_nLin,000 PSAY __PrtThinLine()
			_nLin++
			@_nLin,000 PSAY "Valor Total ----->>>> R$ " + Transf(_nVlrTotal,PesqPict("SE1","E1_VALOR"))
			_nLin++
		EndIf

	EndDo

	// restaura area inicial do TRB
	RestArea(_aAreaTRB)

	SET DEVICE TO SCREEN
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Se impressao em disco, chama o gerenciador de impressao...          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If aReturn[5]==1
		dbCommitAll()
		SET PRINTER TO
		OurSpool(wnrel)
	ENDIF

	MS_FLUSH()

Return

// ** funcao para para controle do pagamento de movimentacao dupla
Static Function sfPagtoDuplo()
	// area inicial
	local _aAreaAtu := GetArea()
	// praca de destino
	local _cPrcDest := ""
	// primeira movimentacao
	local _lFirst := .t.

	// varre todos os registro, pesquisando movimentacoes duplas
	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	(_TRBMOV)->(dbGoTop())
	
	While (_TRBMOV)->(!Eof())
		// verifica se o lancamento eh duplo
		If (Left((_TRBMOV)->Z3_DUPLO,1)=="D")
			// se for a primeira movimentacao, armazena praca de destino pra comparar com o proximo registro
			If (_lFirst)
				// praca de destino
				_cPrcDest := (_TRBMOV)->Z3_PRCDEST
				// primeira movimentacao
				_lFirst := .f.

				// na segunda movimentacao
			ElseIf (!_lFirst)
				// compara a praca de destino (se for a mesma praca, zera o valor da movimentacao)
				If ((_TRBMOV)->Z3_PRCDEST == _cPrcDest)
					// zera valor de pagamento
					(_TRBMOV)->(RecLock(_TRBMOV))
					(_TRBMOV)->IT_VLRPAG := 0
					(_TRBMOV)->(MsUnLock())
				EndIf
				// reinicia variaveis
				_cPrcDest := ""
				_lFirst := .t.
			EndIf
		EndIf

		// proximo item
		(_TRBMOV)->(dbSkip())
	EndDo

	// restaura area inicial
	RestArea(_aAreaAtu)
Return

// ** funcao que marca todos os itens quando clicar no header da coluna
Static Function sfMarkAll(mvMarca)
	// area atual
	Local _aAreaAtu := (_TRBMOV)->(GetArea())
	// seleciona o arquivo de trabalho
	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	(_TRBMOV)->(dbGoTop())
	// atualiza o campo Ok
	DbEval ({|| ((_TRBMOV)->(RecLock(_TRBMOV)),;
		(_TRBMOV)->IT_OK := If(Empty((_TRBMOV)->IT_COR),Space(2),If(Empty((_TRBMOV)->IT_OK),mvMarca,Space(2)) ),;
		(_TRBMOV)->(MsUnLock()))})
	// restaura area atual
	RestArea(_aAreaAtu)
	// atualiza o valor total
	sfAtuTotal()
Return(.t.)

// ** funcao para exportar os dados para excel
Static Function sfExpExcel()
	// area atual do TRB
	local _aAreaAtu := (_TRBMOV)->(GetArea())
	// vetor com dados e cabecalhos
	local _aHeadEx := {}, _aColsEx := {}
	// usuario
	local _cUsrMov := ""
	local _cDscUsr := ""
	local _cDscCli := ""

	// header do excel
	aAdd(_aHeadEx,{"Filial"          ,"","Filial"})
	aAdd(_aHeadEx,{"Data Movim."     ,"","Data Movim."})
	aAdd(_aHeadEx,{"Tp Movim."       ,"",RetTitle("Z3_TPMOVIM")})
	aAdd(_aHeadEx,{"Dupla/Simples"   ,"","Dupla/Simples"})
	aAdd(_aHeadEx,{"Nr. RIC"         ,"","Nr. RIC"})
	aAdd(_aHeadEx,{"Container"       ,"","Container",PesqPict("SZC","ZC_CODIGO")})
	aAdd(_aHeadEx,{"Tamanho"         ,"","Tamanho"})
	aAdd(_aHeadEx,{"Tipo"            ,"","Tipo"})
	aAdd(_aHeadEx,{"Conteúdo"        ,"","Conteúdo"})
	aAdd(_aHeadEx,{"Praça de Origem" ,"","Praca Origem"})
	aAdd(_aHeadEx,{"Praça de Destino","","Praca Destino"})
	aAdd(_aHeadEx,{"Placa"           ,"","Placa",PesqPict("SZ3","Z3_PLACA1")})
	aAdd(_aHeadEx,{"Vlr.Tabela"      ,"","Vlr.Tabela",PesqPict("SZ5","Z5_VALOR")})
	aAdd(_aHeadEx,{"Vlr.Pago"        ,"","Vlr.Pago",PesqPict("SZ5","Z5_VALOR")})
	aAdd(_aHeadEx,{"Usuário"         ,"","Usuário",""})
	aAdd(_aHeadEx,{"Programação"     ,"","Programação",""})
	aAdd(_aHeadEx,{"Cliente"         ,"","Cliente",""})

	// seleciona area
	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	(_TRBMOV)->(dbGoTop())
	
	// atualiza nome
	_cDscUsr := AllTrim(UsrFullName(_cUsrMov))

	While (_TRBMOV)->( ! Eof() )

		// valida nome do usuario
		If (_cUsrMov != (_TRBMOV)->Z3_USRINCL)
			// atualiza controle
			_cUsrMov := (_TRBMOV)->Z3_USRINCL
		EndIf

		// nome do cliente
		_cDscCli := Posicione("SA1",1, xFilial("SA1")+(_TRBMOV)->Z3_CLIENTE+(_TRBMOV)->Z3_LOJA ,"A1_NOME")

		// adiciona valores para exportação excel
		aAdd( _aColsEx, { ;
			(_TRBMOV)->Z3_FILIAL  ,;
			(_TRBMOV)->Z3_DTMOVIM ,;
			(_TRBMOV)->Z3_TPMOVIM ,;
			(_TRBMOV)->Z3_DUPLO   ,;
			(_TRBMOV)->Z3_RIC     ,;
			(_TRBMOV)->Z3_CONTAIN ,;
			(_TRBMOV)->Z3_TAMCONT ,;
			(_TRBMOV)->Z3_TIPCONT ,;
			(_TRBMOV)->Z3_CONTEUD ,;
			(_TRBMOV)->IT_PRCORIG ,;
			(_TRBMOV)->IT_PRCDEST ,;
			(_TRBMOV)->Z3_PLACA1  ,;
			(_TRBMOV)->IT_VLRTAB  ,;
			(_TRBMOV)->IT_VLRPAG  ,;
			_cDscUsr            ,;
			(_TRBMOV)->Z3_PROGRAM ,;
			_cDscCli            ,;
			.f.                 })

		// proximo item
		(_TRBMOV)->(dbSkip())
	EndDo

	// verifica se ha dados para exportar
	If (Len(_aColsEx) > 0)
		U_FtExpExc( "Fechamento de Frete", _aHeadEx, _aColsEx)
	EndIf

	// restaura area atual do TRB
	RestArea(_aAreaAtu)
Return