#Include "Totvs.ch"
#Include "TopConn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Consulta detalhada da programacao                       !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 07/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSV004(mvProcesso)
	// dimensoes da tela
	local _aSizeDlg := MsAdvSize()
	// pastas do FOLDER
	local _aFolders := {'Dados da Programação','Notas de Entrada','Pedidos de Venda','Notas de Saida','Mov. Carga'}
	// coluna dos botoes
	local _nColBotEnc := 0

	// cores para o browse
	local _aCorPedVen := {{"Empty((_cAlTrbPV)->C6_NOTA)","BR_AMARELO"},{"!Empty((_cAlTrbPV)->C6_NOTA)","DISABLE"}}
	local _aCorFatSrv := {{"(_TRBFAT)->E1_SALDO > 0","ENABLE"},{"(_TRBFAT)->E1_SALDO==0","DISABLE"}}

	// controle de consulta unica (chamada de outras funcoes)
	private _lConsUnica := (ValType(mvProcesso)=="C")
	// permite visualizar a aba de faturamento de servicos
	private _lFatServ := sfVisFatSrv()

	// codigo da programacao
	private _cNumProg := If(_lConsUnica,mvProcesso,CriaVar("Z1_CODIGO",.f.))
	// codigo do cliente
	private _cCodCli := ""
	// loja do cliente
	private _cLojCli := ""
	// referencia
	private _cReferen := Space(20)
	// numero do container
	private _cNumCont := CriaVar("ZC_CODIGO",.f.)

	// fontes utilizadas
	Private _oFnt01 := TFont():New("Tahoma",,18,,.t.)

	// variaveis internas obrigatorias
	private INCLUI   := IIf(_lConsUnica, .f., .t.)
	private ALTERA   := IIf(_lConsUnica, .t., .f.)
	private _lInclui := IIf(_lConsUnica, .f., .t.)
	private _lAltera := IIf(_lConsUnica, .t., .f.)

	// campos do browse (itens da programacao)
	private _aHdItPrg := {}
	private _cTrItPrg
	private _TRBITE   := GetNextAlias()
	private _aStItPrg := {}
	private _oBrwItPrg

	// campos do browse (notas de entrada)
	private _aHdNfEnt := {}
	private _cTrNfEnt
	private _TRBNFE   := GetNextAlias()
	private _aStNfEnt := {}
	private _oBrwNfEnt

	// campos do browse (notas de saida)
	private _aHdNfSai := {}
	private _cTrNfSai
	private _aStNfSai := {}
	private _oBrwNfSai
	private _cAlTrbSai:= GetNextAlias()

	// campos do browse (movimentacao de containers)
	private _aHdMovCnt := {}
	private _cTrMovCnt
	private _aStMovCnt := {}
	private _oBrwMovCnt
	private _cAlTrbMov:= GetNextAlias()

	// campos do browse (faturamento servico)
	private _aHdFatSrv := {}
	private _cTrFatSrv
	private _TRBFAT    := GetNextAlias()
	private _aStFatSrv := {}
	private _oBrwFatSrv

	// campos do browse (pedidos de venda - prog saida)
	private _aHdPedVen := {}
	private _cTrPedVen
	private _aStPedVen := {}
	private _oBrwPedVen
	private _cAlTrbPV  := GetNextAlias()

	// totalizadores das notas de entrada
	private _nEntPesBru := 0
	private _nEntPesLiq := 0
	private _nEntCubage := 0
	// totalizadores das notas de saida
	private _nSaiPesBru := 0
	private _nSaiPesLiq := 0
	private _nSaiCubage := 0
	// saldos
	private _nSldPesBru := 0
	private _nSldPesLiq := 0
	private _nSldCubage := 0

	// valida processo encerrado
	private _lProcEncer := .f.

	// adiciona as pastas do folder
	If (_lFatServ)
		aAdd(_aFolders,'Faturamento Serv.')
	EndIf

	// se for consulta unica, posiciona no registro do SZ1-Cabecalho
	If (_lConsUnica)
		dbSelectArea("SZ1")
		SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
		SZ1->(dbSeek( xFilial("SZ1")+_cNumProg ))
	EndIf

	// cria as variaveis da memoria do SZ1
	dbSelectArea("SZ1")
	RegToMemory("SZ1")

	// executa a selecao da dados a 1a vez
	sfSelDados(.t.)

	// na consulta unica, atualiza os dados
	If (_lConsUnica)
		sfVldNumProg(.f.)
	EndIf

	// monta o dialogo
	_oDlgConsulta := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Consulta detalhada da programação",,,.F.,,,,,,.T.,,,.T. )
	_oDlgConsulta:lMaximized := .T.

	// painel com o titulo
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgConsulta,,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// atualiza cor conforme status da programacao
	If (_lConsUnica)
		_oPnlCabec:nCLRPane := IIf(_lProcEncer,RGB(255,0,0),RGB(154,205,50))
	EndIf

	// numero da programacao
	_oSayNumProg := TSay():New(007,005,{||"Programação:"},_oPnlCabec,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGetNumProg := TGet():New(005,055,{|u| If(PCount()>0,_cNumProg:=u,_cNumProg)},_oPnlCabec,050,012,PesqPict("SZ1","Z1_CODIGO"),{||Vazio().or.((U_FtStrZero()).and.(sfVldNumProg(.f.)))},,,_oFnt01,,,.T.,"",,{|| (!_lConsUnica) },.F.,.F.,,.F.,.F.,"SZ1","_cNumProg",,)

	// se na for consulta de unico processo
	If (!_lConsUnica)
		// referencia
		_oSayReferen := TSay():New(007,120,{||"Referência:"},_oPnlCabec,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGetReferen := TGet():New(005,170,{|u| If(PCount()>0,_cReferen:=u,_cReferen)},_oPnlCabec,100,012,'@!',{||Vazio().or.sfVldNumProg(.t.)},,,_oFnt01,,,.T.,"",,,.F.,.F.,,.F.,.F.,,"_cReferen",,)
		// numero do container
		_oSayNumCont := TSay():New(007,285,{||"Container:"},_oPnlCabec,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGetNumCont := TGet():New(005,335,{|u| If(PCount()>0,_cNumCont:=u,_cNumCont)},_oPnlCabec,070,012,PesqPict("SZC","ZC_CODIGO"),{||Vazio().or.sfVldNumProg(.t.)},,,_oFnt01,,,.T.,"",,,.F.,.F.,,.F.,.F.,,"_cNumCont",,)
	EndIf

	// botao fechar
	_oBtnFechar := TButton():New(005,((_aSizeDlg[5]/2)-35),"Fechar",_oDlgConsulta,{|| _oDlgConsulta:End() },030,015,,_oFnt01,,.T.,,"",,,,.F. )

	// pastas com as opcoes de visualizacao
	_oFolder := TFolder():New(000,000,_aFolders,,_oDlgConsulta,,,,.T.,,500,800)
	_oFolder:Align:= CONTROL_ALIGN_ALLCLIENT

	// 1a pasta - dados da programacao
	// painel superior com as opcoes
	_oPnlFld1Sup := TPanel():New(000,000,nil,_oFolder:aDialogs[1],,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlFld1Sup:Align:= CONTROL_ALIGN_TOP
	// opcao de visualizar a nota de saida
	_oBtnFld1Cons := TButton():New(005,005,"Prog. Aberta",_oPnlFld1Sup,{|| sfProgAberta() },046,012,,,,.T.,,"",,,,.F. )
	// opcao para impressao do mapa de movimentacao de produtos
	_oBtnFld1Mapa := TButton():New(005,056,"Mapa Mov. Prod.",_oPnlFld1Sup,{|| sfImpMapMov() },046,012,,,,.T.,,"",,,,.F. )

	// cria o cabecalho da programacao
	_oPnlFld1Cen := TPanel():New(000,000,nil,_oFolder:aDialogs[1],,.F.,.F.,,,100,100,.T.,.F. )
	_oPnlFld1Cen:Align:= CONTROL_ALIGN_TOP
	// cria a enchoice
	Enchoice("SZ1",,2,,,,,{000,000,100,(_aSizeDlg[5]/2)},,,,,,_oPnlFld1Cen)
	// browse os itens da programacao
	_oBrwItPrg := MsSelect():New(_TRBITE,,,_aHdItPrg,,,{001,001,400,1000},,,_oFolder:aDialogs[1])
	_oBrwItPrg:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// 2a pasta - notas de entrada

	// coluna dos botoes
	_nColBotEnc := 5

	// painel superior com as opcoes
	_oPnlFld2Sup := TPanel():New(000,000,nil,_oFolder:aDialogs[2],,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlFld2Sup:Align:= CONTROL_ALIGN_TOP
	// opcao de visualizar a nota de entrada
	_oBtnFld2Vis := TButton():New(005,_nColBotEnc,"Vis. Documento",_oPnlFld2Sup,{|| sfVisNFE() },046,012,,,,.T.,,"",,,,.F. )
	_nColBotEnc += 51

	// -- botao com recalculo do peso das notas
	If (__cUserID $ AllTrim(SuperGetMV("TC_USRRECA",,"")))
		_oBtnFld2Rat := TButton():New(005,_nColBotEnc,"Rateio Peso",_oPnlFld2Sup,{|| sfRateio(_cNumProg) },046,012,,,,.T.,,"",,,,.F. )
		_nColBotEnc += 51
	EndIf
	// -- botao reabrir programacao
	If (__cUserID $ AllTrim(SuperGetMV("TC_USRREAB",,"")))
	_oBtnFld2Rea := TButton():New(005,_nColBotEnc,"Reabrir",_oPnlFld2Sup,{|| sfReabrir(_cNumProg) },046,012,,,,.T.,,"",,,,.F. )
	_nColBotEnc += 51
	EndIf
	// -- botao definir data de inicio de cobranca
	If (__cUserID $ AllTrim(SuperGetMV("TC_USRDEFD",,"")))
		_oBtnFld2Data := TButton():New(005,_nColBotEnc,"Data Cobrança",_oPnlFld2Sup,{|| sfDefDtCobr() },046,012,,,,.T.,,"",,,,.F. )
		_nColBotEnc += 51
	EndIf
	// -- botao corrigir NF
	If (__cUserID $ AllTrim(SuperGetMV("TC_USRRECA",,"")))
		_oBtnCorrNF := TButton():New(005,_nColBotEnc,"Corrigir NF",_oPnlFld2Sup,{|| sfCorrNF() },046,012,,,,.T.,,"",,,,.F. )
		_nColBotEnc += 51
	EndIf

	// painel inferior - ssub-totais
	_oPnlFld2Rod := TPanel():New(000,000,nil,_oFolder:aDialogs[2],,.F.,.F.,,,50,50,.T.,.F. )
	_oPnlFld2Rod:Align:= CONTROL_ALIGN_BOTTOM
	// titulos - total de entradas
	_oSayTotEnt := TSay():New(010,005,{||"Total Entradas"},_oPnlFld2Rod,,_oFnt01,.F.,.F.,.F.,.T.)
	_oSayTotSai := TSay():New(023,005,{||"Total Saídas"},_oPnlFld2Rod,,_oFnt01,.F.,.F.,.F.,.T.)
	_oSaySaldo  := TSay():New(036,005,{||"Saldo"},_oPnlFld2Rod,,_oFnt01,.F.,.F.,.F.,.T.)
	_oSayTotEntBru := TSay():New(001,060,{||"Peso Bruto"},_oPnlFld2Rod,,,.F.,.F.,.F.,.T.)
	_oSayTotEntLiq := TSay():New(001,140,{||"Peso Liquído"},_oPnlFld2Rod,,,.F.,.F.,.F.,.T.)
	_oSayTotEntCub := TSay():New(001,220,{||"Cubagem"},_oPnlFld2Rod,,,.F.,.F.,.F.,.T.)
	// campos com o total de entradas
	_oGetTotEntBru := TGet():New(008,060,{|u| If(PCount()>0,_nEntPesBru:=u,_nEntPesBru)},_oPnlFld2Rod,070,012,PesqPict("SF1","F1_PBRUTO"),,,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nEntPesBru",,)
	_oGetTotEntLiq := TGet():New(008,140,{|u| If(PCount()>0,_nEntPesLiq:=u,_nEntPesLiq)},_oPnlFld2Rod,070,012,PesqPict("SF1","F1_PLIQUI"),,,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nEntPesLiq",,)
	_oGetTotEntCub := TGet():New(008,220,{|u| If(PCount()>0,_nEntCubage:=u,_nEntCubage)},_oPnlFld2Rod,070,012,PesqPict("SF1","F1_CUBAGEM"),,,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nEntCubage",,)
	// campos com o total de saidas
	_oGetTotSaiBru := TGet():New(021,060,{|u| If(PCount()>0,_nSaiPesBru:=u,_nSaiPesBru)},_oPnlFld2Rod,070,012,PesqPict("SF1","F1_PBRUTO"),,,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nSaiPesBru",,)
	_oGetTotSaiLiq := TGet():New(021,140,{|u| If(PCount()>0,_nSaiPesLiq:=u,_nSaiPesLiq)},_oPnlFld2Rod,070,012,PesqPict("SF1","F1_PLIQUI"),,,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nSaiPesLiq",,)
	_oGetTotSaiCub := TGet():New(021,220,{|u| If(PCount()>0,_nSaiCubage:=u,_nSaiCubage)},_oPnlFld2Rod,070,012,PesqPict("SF1","F1_CUBAGEM"),,,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nSaiCubage",,)
	// campos com os saldos
	_oGetSaldoBru := TGet():New(034,060,{|u| If(PCount()>0,_nSldPesBru:=u,_nSldPesBru)},_oPnlFld2Rod,070,012,PesqPict("SF1","F1_PBRUTO"),,,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nSldPesBru",,)
	_oGetSaldoLiq := TGet():New(034,140,{|u| If(PCount()>0,_nSldPesLiq:=u,_nSldPesLiq)},_oPnlFld2Rod,070,012,PesqPict("SF1","F1_PLIQUI"),,,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nSldPesLiq",,)
	_oGetSaldoCub := TGet():New(034,220,{|u| If(PCount()>0,_nSldCubage:=u,_nSldCubage)},_oPnlFld2Rod,070,012,PesqPict("SF1","F1_CUBAGEM"),,,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nSldCubage",,)

	// browse com as notas de entrada
	_oBrwNfEnt := MsSelect():New(_TRBNFE,,,_aHdNfEnt,,,{001,001,400,1000},,,_oFolder:aDialogs[2])
	_oBrwNfEnt:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwNfEnt:oBrowse:blDblClick := {|| sfVisNFE() }

	// 3a pasta - pedidos de venda (prog saida)
	// painel superior com as opcoes
	_oPnlFld3Sup := TPanel():New(000,000,nil,_oFolder:aDialogs[3],,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlFld3Sup:Align:= CONTROL_ALIGN_TOP
	// opcao de visualizar o pedido de venda
	_oBtnFld3Vis := TButton():New(005,005,"Vis. Pedido",_oPnlFld3Sup,{||sfVisPedVen((_cAlTrbPV)->C6_NUM)},046,012,,,,.T.,,"",,,,.F. )
	//browse com os pedidos de venda
	_oBrwPedVen := MsSelect():New((_cAlTrbPV),,,_aHdPedVen,,,{001,001,400,1000},,,_oFolder:aDialogs[3],,_aCorPedVen)
	_oBrwPedVen:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwPedVen:oBrowse:blDblClick := {|| sfVisPedVen((_cAlTrbPV)->C6_NUM) }

	// 4a pasta - notas de saida
	// painel superior com as opcoes
	_oPnlFld4Sup := TPanel():New(000,000,nil,_oFolder:aDialogs[4],,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlFld4Sup:Align:= CONTROL_ALIGN_TOP
	// opcao de visualizar a nota de saida
	_oBtnFld4Vis := TButton():New(005,005,"Vis. Documento",_oPnlFld4Sup,{|| sfVisNFS((_cAlTrbSai)->F2_DOC,(_cAlTrbSai)->F2_SERIE) },046,012,,,,.T.,,"",,,,.F. )
	//browse com as notas de saida
	_oBrwNfSai := MsSelect():New((_cAlTrbSai),,,_aHdNfSai,,,{001,001,400,1000},,,_oFolder:aDialogs[4])
	_oBrwNfSai:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwNfSai:oBrowse:blDblClick := {|| sfVisNFS((_cAlTrbSai)->F2_DOC,(_cAlTrbSai)->F2_SERIE) }

	// 5a pasta - movimentacao de carga
	// painel superior com as opcoes
	_oPnlFld5Sup := TPanel():New(000,000,nil,_oFolder:aDialogs[5],,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlFld5Sup:Align:= CONTROL_ALIGN_TOP
	// opcao de visualizar a movimentacao da carga
	_oBtnFld5Vis := TButton():New(005,005,"Vis. Movim. Carga",_oPnlFld5Sup,{|| U_WMSV002B(xFilial("SZ3"),(_cAlTrbMov)->Z3_RIC ) },046,012,,,,.T.,,"",,,,.F. )
	//browse com as movimentacoes da carga (containers)
	_oBrwMovCnt := MsSelect():New((_cAlTrbMov),,,_aHdMovCnt,,,{001,001,400,1000},,,_oFolder:aDialogs[5])
	_oBrwMovCnt:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// 6a pasta
	// painel superior com as opcoes
	If (_lFatServ)
		_oPnlFld6Sup := TPanel():New(000,000,nil,_oFolder:aDialogs[6],,.F.,.F.,,,22,22,.T.,.F. )
		_oPnlFld6Sup:Align:= CONTROL_ALIGN_TOP
		// opcao de visualizar o pedido de venda
		_oBtnFld6VisPV  := TButton():New(005,005,"Vis. Ped. Venda",_oPnlFld6Sup,{||sfVisPedVen((_TRBFAT)->C5_NUM)},046,012,,,,.T.,,"",,,,.F. )
		// opcao de visualizar a nota faturada
		_oBtnFld6VisNFS := TButton():New(005,056,"Vis. Documento",_oPnlFld6Sup,{||sfVisNFS((_TRBFAT)->C5_NOTA,(_TRBFAT)->C5_SERIE)},046,012,,,,.T.,,"",,,,.F. )
		// opcao de impressao do detalhe do faturamento do servico
		_oBtnFld6ImpDet := TButton():New(005,107,"Imp. Det. Fat.",_oPnlFld6Sup,{||sfImpDetFat()},046,012,,,,.T.,,"",,,,.F. )
		// opcao de consulta detalhada dos titulos
		_oBtnFld6ImpDet := TButton():New(005,158,"Det. Financeiro",_oPnlFld6Sup,{||sfDetFinanc()},046,012,,,,.T.,,"",,,,.F. )
		// opcao para gerar o faturamento da programacao
		_oBtnFld6FatCon := TButton():New(005,209,"Fat. Contrato",_oPnlFld6Sup,{|| MsgRun("Fat. Contratos...", "Aguarde...", {|| sfFatContrato() } ) },046,012,,,,.T.,,"",,,,.F. )
		//browse com as notas do faturamento se servico
		_oBrwFatSrv := MsSelect():New(_TRBFAT,,,_aHdFatSrv,,,{001,001,400,1000},,,_oFolder:aDialogs[6],,_aCorFatSrv)
		_oBrwFatSrv:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
		// verifica se deve ativar a aba de faturamento de servicos
		//_oFolder:aDialogs[5]:lActive := _lFatServ
	EndIf

	// ativa a tela
	ACTIVATE MSDIALOG _oDlgConsulta CENTERED
	
	// exclui tabelas temporárias
	If ValType(_cTrItPrg) == "O"
		_cTrItPrg:Delete()
	EndIf
	
	If ValType(_cTrNfEnt) == "O"
		_cTrNfEnt:Delete()
	EndIf
	
	If ValType(_cTrPedVen) == "O"
		_cTrPedVen:Delete()
	EndIf
	
	If ValType(_cTrNfSai) == "O"
		_cTrNfSai:Delete()
	EndIf
	
	If ValType(_cTrMovCnt) == "O"
		_cTrMovCnt:Delete()
	EndIf
	
	If ValType(_cTrFatSrv) == "O"
		_cTrFatSrv:Delete()
	EndIf

Return

// ** funcao que faz a validacao do numero da programacao digita
Static Function sfVldNumProg(mvReferen)
	// variavel de retorno
	local _lRet := .t.

	// verifica se a pesquisa eh por referencia
	If (mvReferen)
		// chama a pesquisa por referencia
		If (!sfPesqRef())
			Return(.t.)
		EndIf
	Else
		// limpa a referencia
		_cReferen := Space(20)
		// limpa numero do container
		_cNumCont := CriaVar("ZC_CODIGO",.f.)
	EndIf

	// cabecalho da programacao
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	If (!SZ1->(dbSeek( xFilial("SZ1")+_cNumProg )))
		MsgStop("Programação não encontrada!")
		Return(.f.)
	EndIf

	// atualiza codigo o loja do cliente
	_cCodCli := SZ1->Z1_CLIENTE
	_cLojCli := SZ1->Z1_LOJA

	// atualiza controle de processo encerrado
	_lProcEncer := ( ! Empty(SZ1->Z1_DTFINFA))

	// atualiza cor conforme status da programacao
	If (Type("_oPnlCabec") != "U")
		_oPnlCabec:nCLRPane := IIf(_lProcEncer,RGB(255,0,0),RGB(154,205,50))
	EndIf

	// se encontrar a programacao, atualiza os dados
	sfSelDados(.f.)

Return(_lRet)

// ** funcao que carrega os dados da programacao
Static Function sfSelDados(mvFirst)

	MsgRun("Atualizando informacoes...", "Aguarde...", {||	CursorWait(),;
	sfDetProg(mvFirst) ,;
	sfNfEntrada(mvFirst) ,;
	sfPedVenda(mvFirst) ,;
	sfNfSaida(mvFirst) ,;
	sfMovCarga(mvFirst) ,;
	sfFatServico(mvFirst) ,;
	CursorArrow()})

Return

// ** funcao que busca os detalhes da programacao
Static Function sfDetProg(mvFirst)
	// joga as informacoes do SZ1 para memoria
	If (mvFirst)
		// pesquisa filial que nao existe pra ficar em EOF
		dbSelectArea("SZ1")
		SZ1->(dbSeek("ZZZ"))
	Else
		// atualiza variaveis
		INCLUI := _lInclui := .f.
		ALTERA := _lAltera := .t.
		// atualiza dados da memoria
		RegToMemory("SZ1")
	EndIf
	// funcao que retorna os itens da progracao
	sfItemPrg(mvFirst)

Return

// ** funcao que retora os itens da programacao
Static Function sfItemPrg(mvFirst)
	// area inicial do SX3
	local _aAreaSx3 := SX3->(GetArea())

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		
		// estrutura do TRB
		aAdd(_aStItPrg,{"Z2_ITEM   ", "C", 4, 0})
		aAdd(_aStItPrg,{"Z2_DOCUMEN", "C", 20, 0})
		aAdd(_aStItPrg,{"Z2_TIPCONT", "C", 2, 0})
		aAdd(_aStItPrg,{"Z2_DSTPCON", "C", 20, 0})
		aAdd(_aStItPrg,{"Z2_TAMCONT", "C", 2, 0})
		aAdd(_aStItPrg,{"Z2_CONTEUD", "C", 1, 0})
		aAdd(_aStItPrg,{"Z2_QUANT  ", "N", 3, 0})
		aAdd(_aStItPrg,{"Z2_QTDREC ", "N", 3, 0})
		aAdd(_aStItPrg,{"Z2_PRCORIG", "C", 4, 0})
		aAdd(_aStItPrg,{"Z2_TRACONT", "C", 6, 0})
		aAdd(_aStItPrg,{"Z2_TRANSP ", "C", 6, 0})
		aAdd(_aStItPrg,{"Z2_ATIVO  ", "C", 1, 0})
		aAdd(_aStItPrg,{"Z2_EMISSAO", "D", 8, 0})
		aAdd(_aStItPrg,{"Z2_REFEREN", "C", 40, 0})
		// header
		aAdd(_aHdItPrg,{"Z2_ITEM   ",  "", "Item        " , "@!"})
		aAdd(_aHdItPrg,{"Z2_DOCUMEN",  "", "Documento   " , "@!"})
		aAdd(_aHdItPrg,{"Z2_TIPCONT",  "", "Tip Contain." , ""})
		aAdd(_aHdItPrg,{"Z2_DSTPCON",  "", "Dsc Tip Cont" , "!@"})
		aAdd(_aHdItPrg,{"Z2_TAMCONT",  "", "Tam Contain." , "@!"})
		aAdd(_aHdItPrg,{"Z2_CONTEUD",  "", "Conteudo?   " , ""})
		aAdd(_aHdItPrg,{"Z2_QUANT  ",  "", "Quantidade  " , "@E 999"})
		aAdd(_aHdItPrg,{"Z2_QTDREC ",  "", "Qtd Recebida" , "@E 999"})
		aAdd(_aHdItPrg,{"Z2_PRCORIG",  "", "Praca Origem" , ""})
		aAdd(_aHdItPrg,{"Z2_TRACONT",  "", "Transp.Contr" , "@!"})
		aAdd(_aHdItPrg,{"Z2_TRANSP ",  "", "Transp.     " , "@!"})
		aAdd(_aHdItPrg,{"Z2_ATIVO  ",  "", "Ativo?      " , ""})
		aAdd(_aHdItPrg,{"Z2_EMISSAO",  "", "Emissao     " , ""})
		aAdd(_aHdItPrg,{"Z2_REFEREN",  "", "Referencia  " , "@!"})
		

		// fecha alias do TRB
		If (Select(_TRBITE)<>0)
			dbSelectArea(_TRBITE)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrItPrg := FWTemporaryTable():New( _TRBITE )
		_cTrItPrg:SetFields( _aStItPrg )
		_cTrItPrg:Create()
	EndIf

	// limpa o conteudo do TRB
	(_TRBITE)->(dbSelectArea(_TRBITE))
	(_TRBITE)->(__DbZap())

	If ( ! mvFirst )
		// busca as movimentacoes
		_cQuery := " SELECT * "
		// itens da programacao
		_cQuery += " FROM " + RetSqlTab("SZ2") + " (NOLOCK) "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("SZ2")
		// filtro dos itens da programacao
		_cQuery += " AND Z2_CODIGO = '" + SZ1->Z1_CODIGO + "' "
		// ordem das informacoes
		_cQuery += "ORDER BY Z2_ITEM"

		// adiciona o conteudo da query para o arquivo de trabalho
		U_SqlToTrb(_cQuery, _aStItPrg, _TRBITE)

	EndIf

	// abre o arquivo de trabalho
	(_TRBITE)->(dbSelectArea(_TRBITE))
	(_TRBITE)->(dbGoTop())

	// refresh do browse
	If (_oBrwItPrg <> nil)
		_oBrwItPrg:oBrowse:Refresh()
	EndIf

Return

// ** busca as notas fiscais de entrada
Static Function sfNfEntrada(mvFirst)

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStNfEnt,{"F1_DOC"    ,"C", TamSx3("F1_DOC")[1],0})							; aAdd(_aHdNfEnt,{"F1_DOC","",RetTitle("F1_DOC"),PesqPict("SF1","F1_DOC")})
		aAdd(_aStNfEnt,{"F1_SERIE"  ,"C", TamSx3("F1_SERIE")[1],0})							; aAdd(_aHdNfEnt,{"F1_SERIE","",RetTitle("F1_SERIE"),PesqPict("SF1","F1_SERIE")})
		aAdd(_aStNfEnt,{"F1_EMISSAO","D", TamSx3("F1_EMISSAO")[1],0})						; aAdd(_aHdNfEnt,{"F1_EMISSAO","",RetTitle("F1_EMISSAO"),PesqPict("SF1","F1_EMISSAO")})
		aAdd(_aStNfEnt,{"F1_DTDIGIT","D", TamSx3("F1_DTDIGIT")[1],0})						; aAdd(_aHdNfEnt,{"F1_DTDIGIT","","Dt.Digit.",PesqPict("SF1","F1_DTDIGIT")})
		aAdd(_aStNfEnt,{"F1_HORA   ","C", TamSx3("F1_HORA")[1],0})		    				; aAdd(_aHdNfEnt,{"F1_HORA","","Hora Digit.",PesqPict("SF1","F1_HORA")})
		aAdd(_aStNfEnt,{"F1_PBRUTO" ,"N", TamSx3("F1_PBRUTO")[1],TamSx3("F1_PBRUTO")[2]})	; aAdd(_aHdNfEnt,{"F1_PBRUTO","",RetTitle("F1_PBRUTO"),PesqPict("SF1","F1_PBRUTO")})
		aAdd(_aStNfEnt,{"F1_PLIQUI" ,"N", TamSx3("F1_PLIQUI")[1],TamSx3("F1_PLIQUI")[2]})	; aAdd(_aHdNfEnt,{"F1_PLIQUI","",RetTitle("F1_PLIQUI"),PesqPict("SF1","F1_PLIQUI")})
		aAdd(_aStNfEnt,{"F1_CUBAGEM","N", TamSx3("F1_CUBAGEM")[1],TamSx3("F1_CUBAGEM")[2]})	; aAdd(_aHdNfEnt,{"F1_CUBAGEM","",RetTitle("F1_CUBAGEM"),PesqPict("SF1","F1_CUBAGEM")})

		// fecha alias do TRB
		If (Select(_TRBNFE)<>0)
			dbSelectArea(_TRBNFE)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrNfEnt := FWTemporaryTable():New( _TRBNFE )
		_cTrNfEnt:SetFields( _aStNfEnt )
		_cTrNfEnt:Create()
	EndIf

	// limpa o conteudo do TRB
	(_TRBNFE)->(dbSelectArea(_TRBNFE))
	(_TRBNFE)->(__DbZap())

	If (!mvFirst)
		// busca as movimentacoes
		_cQuery := "SELECT F1_DOC, F1_SERIE, F1_EMISSAO, F1_DTDIGIT, F1_HORA, F1_PBRUTO, F1_PLIQUI, F1_CUBAGEM "
		// notas de entrada
		_cQuery += "FROM "+RetSqlName("SF1")+" SF1 (NOLOCK) "
		_cQuery += "WHERE F1_FILIAL = '"+xFilial("SF1")+"' AND SF1.D_E_L_E_T_ = ' ' "
		_cQuery += "AND F1_PROGRAM = '"+_cNumProg+"' "
		_cQuery += "AND F1_TIPO IN ('B','D') "
		_cQuery += "AND F1_STATUS != ' ' "
		// ordem dos dados
		_cQuery += "ORDER BY F1_DTDIGIT, F1_HORA, F1_DOC"

		// adiciona o conteudo da query para o arquivo de trabalho
		SqlToTrb(_cQuery,_aStNfEnt,_TRBNFE)
	EndIf

	// abre o arquivo de trabalho
	(_TRBNFE)->(dbSelectArea(_TRBNFE))
	(_TRBNFE)->(dbGoTop())

	// refresh do browse
	If (_oBrwNfEnt <> nil)
		_oBrwNfEnt:oBrowse:Refresh()
	EndIf

Return

// ** busca dos pedidos de venda
Static Function sfPedVenda(mvFirst)

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStPedVen,{"C6_NUM"    ,"C", TamSx3("C6_NUM")[1],0})							; aAdd(_aHdPedVen,{"C6_NUM","",RetTitle("C6_NUM"),PesqPict("SC6","C6_NUM")})
		aAdd(_aStPedVen,{"C5_EMISSAO","D", TamSx3("C5_EMISSAO")[1],0})						; aAdd(_aHdPedVen,{"C5_EMISSAO","",RetTitle("C5_EMISSAO"),PesqPict("SC5","C5_EMISSAO")})
		aAdd(_aStPedVen,{"C6_NOTA"   ,"C", TamSx3("C6_NOTA")[1],0})							; aAdd(_aHdPedVen,{"C6_NOTA","",RetTitle("C6_NOTA"),PesqPict("SC6","C6_NOTA")})
		aAdd(_aStPedVen,{"C6_SERIE"  ,"C", TamSx3("C6_SERIE")[1],0})						; aAdd(_aHdPedVen,{"C6_SERIE","",RetTitle("C6_SERIE"),PesqPict("SC6","C6_SERIE")})
		aAdd(_aStPedVen,{"C6_ZPESOB" ,"N", TamSx3("C6_ZPESOB")[1],TamSx3("C6_ZPESOB")[2]})	; aAdd(_aHdPedVen,{"C6_ZPESOB","",RetTitle("C6_ZPESOB"),PesqPict("SC6","C6_ZPESOB")})
		aAdd(_aStPedVen,{"C6_ZPESOL" ,"N", TamSx3("C6_ZPESOL")[1],TamSx3("C6_ZPESOL")[2]})	; aAdd(_aHdPedVen,{"C6_ZPESOL","",RetTitle("C6_ZPESOL"),PesqPict("SC6","C6_ZPESOL")})
		aAdd(_aStPedVen,{"C6_ZCUBAGE","N", TamSx3("C6_ZCUBAGE")[1],TamSx3("C6_ZCUBAGE")[2]}); aAdd(_aHdPedVen,{"C6_ZCUBAGE","",RetTitle("C6_ZCUBAGE"),PesqPict("SC6","C6_ZCUBAGE")})

		// fecha alias do TRB
		If (Select(_cAlTrbPV)<>0)
			dbSelectArea(_cAlTrbPV)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrPedVen := FWTemporaryTable():New( _cAlTrbPV )
		_cTrPedVen:SetFields( _aStPedVen )
		_cTrPedVen:Create()
	EndIf

	// limpa o conteudo do TRB
	(_cAlTrbPV)->(dbSelectArea(_cAlTrbPV))
	(_cAlTrbPV)->(__DbZap())

	If (!mvFirst)
		// busca os pedidos de venda
		_cQuery := "SELECT C6_NUM, C5_EMISSAO, C6_NOTA, C6_SERIE, SUM(C6_ZPESOB) C6_ZPESOB, SUM(C6_ZPESOL) C6_ZPESOL, SUM(C6_ZCUBAGE) C6_ZCUBAGE "
		// notas de saida
		_cQuery += "FROM "+RetSqlName("SC6")+" SC6 (NOLOCK) "
		// cabecalho do pedido
		_cQuery += "INNER JOIN "+RetSqlName("SC5")+" SC5 (NOLOCK) ON C5_FILIAL = C6_FILIAL AND C5_NUM = C6_NUM AND SC5.D_E_L_E_T_ = ' ' "
		// filtro da filial e cliente
		_cQuery += "WHERE C6_FILIAL = '"+xFilial("SD2")+"' AND SC6.D_E_L_E_T_ = ' ' "
		_cQuery += "AND ((C6_CLI = '"+_cCodCli+"' AND C6_LOJA = '"+_cLojCli+"') OR (C6_CLI = '000140')) "
		// notas originais
		_cQuery += "AND C6_NFORI + C6_SERIORI IN ("
		_cQuery += "    SELECT F1_DOC + F1_SERIE FROM "+RetSqlName("SF1")+" SF1 (NOLOCK) "
		_cQuery += "    WHERE F1_FILIAL = '"+xFilial("SF1")+"' AND SF1.D_E_L_E_T_ = ' ' "
		_cQuery += "    AND F1_PROGRAM = '"+_cNumProg+"' "
		_cQuery += "    AND F1_TIPO IN ('B','D') "
		_cQuery += "    AND F1_STATUS != ' ' ) "
		_cQuery += "GROUP BY C6_NUM, C5_EMISSAO, C6_NOTA, C6_SERIE "
		// ordem dos dados
		_cQuery += "ORDER BY C6_NUM, C5_EMISSAO, C6_NOTA, C6_SERIE "

		// adiciona o conteudo da query para o arquivo de trabalho
		SqlToTrb(_cQuery,_aStPedVen,_cAlTrbPV)
	EndIf

	// abre o arquivo de trabalho
	(_cAlTrbPV)->(dbSelectArea(_cAlTrbPV))
	(_cAlTrbPV)->(dbGoTop())

	// refresh do browse
	If (_oBrwPedVen <> nil)
		_oBrwPedVen:oBrowse:Refresh()
	EndIf

Return

// ** busca as notas fiscais de saida
Static Function sfNfSaida(mvFirst)

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStNfSai,{"F2_DOC"    ,"C", TamSx3("F2_DOC")[1],0})							; aAdd(_aHdNfSai,{"F2_DOC","",RetTitle("F2_DOC"),PesqPict("SF2","F2_DOC")})
		aAdd(_aStNfSai,{"F2_SERIE"  ,"C", TamSx3("F2_SERIE")[1],0})							; aAdd(_aHdNfSai,{"F2_SERIE","",RetTitle("F2_SERIE"),PesqPict("SF2","F2_SERIE")})
		aAdd(_aStNfSai,{"F2_EMISSAO","D", TamSx3("F2_EMISSAO")[1],0})						; aAdd(_aHdNfSai,{"F2_EMISSAO","",RetTitle("F2_EMISSAO"),PesqPict("SF2","F2_EMISSAO")})
		aAdd(_aStNfSai,{"D2_ZPESOB" ,"N", TamSx3("D2_ZPESOB")[1],TamSx3("D2_ZPESOB")[2]})	; aAdd(_aHdNfSai,{"D2_ZPESOB","",RetTitle("D2_ZPESOB"),PesqPict("SD2","D2_ZPESOB")})
		aAdd(_aStNfSai,{"D2_ZPESOL" ,"N", TamSx3("D2_ZPESOL")[1],TamSx3("D2_ZPESOL")[2]})	; aAdd(_aHdNfSai,{"D2_ZPESOL","",RetTitle("D2_ZPESOL"),PesqPict("SD2","D2_ZPESOL")})
		aAdd(_aStNfSai,{"D2_ZCUBAGE","N", TamSx3("D2_ZCUBAGE")[1],TamSx3("D2_ZCUBAGE")[2]})	; aAdd(_aHdNfSai,{"D2_ZCUBAGE","",RetTitle("D2_ZCUBAGE"),PesqPict("SD2","D2_ZCUBAGE")})

		// fecha alias do TRB
		If (Select(_cAlTrbSai)<>0)
			dbSelectArea(_cAlTrbSai)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrNfSai := FWTemporaryTable():New( _cAlTrbSai )
		_cTrNfSai:SetFields( _aStNfSai )
		_cTrNfSai:Create()
	EndIf

	// limpa o conteudo do TRB
	(_cAlTrbSai)->(dbSelectArea(_cAlTrbSai))
	(_cAlTrbSai)->(__DbZap())

	If (!mvFirst)
		// busca as movimentacoes
		_cQuery := "SELECT D2_DOC F2_DOC, D2_SERIE F2_SERIE, D2_EMISSAO F2_EMISSAO, SUM(D2_ZPESOB) D2_ZPESOB, SUM(D2_ZPESOL) D2_ZPESOL, SUM(D2_ZCUBAGE) D2_ZCUBAGE "
		// notas de saida
		_cQuery += "FROM "+RetSqlName("SD2")+" SD2 (NOLOCK) "
		// filtro da filial e cliente
		_cQuery += "WHERE D2_FILIAL = '"+xFilial("SD2")+"' AND SD2.D_E_L_E_T_ = ' ' "
		_cQuery += "AND ((D2_CLIENTE = '"+_cCodCli+"' AND D2_LOJA = '"+_cLojCli+"') OR (D2_CLIENTE = '000140')) "
		// notas originais
		_cQuery += "AND D2_NFORI + D2_SERIORI IN ("
		_cQuery += "    SELECT F1_DOC + F1_SERIE FROM "+RetSqlName("SF1")+" SF1 (NOLOCK)"
		_cQuery += "    WHERE F1_FILIAL = '"+xFilial("SF1")+"' AND SF1.D_E_L_E_T_ = ' ' "
		_cQuery += "    AND F1_PROGRAM = '"+_cNumProg+"' "
		_cQuery += "    AND F1_TIPO IN ('B','D') "
		_cQuery += "    AND F1_STATUS != ' ' ) "
		_cQuery += "GROUP BY D2_DOC, D2_SERIE, D2_EMISSAO "
		// ordem dos dados
		_cQuery += "ORDER BY D2_EMISSAO "

		MemoWrit("c:\query\twmsv004_sfNfSaida.txt", _cQuery)

		// adiciona o conteudo da query para o arquivo de trabalho
		SqlToTrb(_cQuery,_aStNfSai,(_cAlTrbSai))
	EndIf

	// funcao para calcula o total de saida e saldo das notas de entrada
	sfCalcSaldo()

	// abre o arquivo de trabalho
	(_cAlTrbSai)->(dbSelectArea(_cAlTrbSai))
	(_cAlTrbSai)->(dbGoTop())

	// refresh do browse
	If (_oBrwNfSai <> nil)
		_oBrwNfSai:oBrowse:Refresh()
	EndIf

Return

// ** busca as movimentacoes da carga
Static Function sfMovCarga(mvFirst)

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStMovCnt,{"Z3_ITEPROG","C", TamSx3("Z3_ITEPROG")[1],0})	; aAdd(_aHdMovCnt,{"Z3_ITEPROG","",RetTitle("Z3_ITEPROG"),PesqPict("SZ3","Z3_ITEPROG")})
		aAdd(_aStMovCnt,{"Z3_DTMOVIM","D", TamSx3("Z3_DTMOVIM")[1],0})	; aAdd(_aHdMovCnt,{"Z3_DTMOVIM","",RetTitle("Z3_DTMOVIM"),PesqPict("SZ3","Z3_DTMOVIM")})
		aAdd(_aStMovCnt,{"Z3_HRMOVIM","C", TamSx3("Z3_HRMOVIM")[1],0})	; aAdd(_aHdMovCnt,{"Z3_HRMOVIM","",RetTitle("Z3_HRMOVIM"),PesqPict("SZ3","Z3_HRMOVIM")})
		aAdd(_aStMovCnt,{"Z3_CONTAIN","C", TamSx3("Z3_CONTAIN")[1],0})	; aAdd(_aHdMovCnt,{"Z3_CONTAIN","",RetTitle("Z3_CONTAIN"),PesqPict("SZ3","Z3_CONTAIN")})
		aAdd(_aStMovCnt,{"Z3_RIC"    ,"C", TamSx3("Z3_RIC")[1],0})
		aAdd(_aStMovCnt,{"Z3_DTSAIDA","D", TamSx3("Z3_DTSAIDA")[1],0})	; aAdd(_aHdMovCnt,{"Z3_DTSAIDA","",RetTitle("Z3_DTSAIDA"),PesqPict("SZ3","Z3_DTSAIDA")})
		aAdd(_aStMovCnt,{"Z3_HRSAIDA","C", TamSx3("Z3_HRSAIDA")[1],0})	; aAdd(_aHdMovCnt,{"Z3_HRSAIDA","",RetTitle("Z3_HRSAIDA"),PesqPict("SZ3","Z3_HRSAIDA")})

		// fecha alias do TRB
		If (Select(_cAlTrbMov)<>0)
			dbSelectArea(_cAlTrbMov)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrMovCnt := FWTemporaryTable():New( _cAlTrbMov )
		_cTrMovCnt:SetFields( _aStMovCnt )
		_cTrMovCnt:Create()
	EndIf

	// limpa o conteudo do TRB
	(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
	(_cAlTrbMov)->(__DbZap())

	If (!mvFirst)
		// busca as movimentacoes
		_cQuery := "SELECT Z3_ITEPROG, Z3_DTMOVIM, Z3_HRMOVIM, Z3_CONTAIN, Z3_RIC, Z3_DTSAIDA, Z3_HRSAIDA "
		// movimentacao de cargas
		_cQuery += "FROM "+RetSqlName("SZ3")+" SZ3 (NOLOCK) "
		// filtro da movimentacoes
		_cQuery += "WHERE Z3_FILIAL = '"+xFilial("SZ3")+"' AND SZ3.D_E_L_E_T_ = ' ' "
		_cQuery += "AND Z3_PROGRAM = '"+_cNumProg+"' "
		_cQuery += "AND Z3_TPMOVIM = 'E' "
		// ordem das informacoes
		_cQuery += "ORDER BY Z3_DTMOVIM, Z3_HRMOVIM"

		// adiciona o conteudo da query para o arquivo de trabalho
		SqlToTrb(_cQuery,_aStMovCnt,(_cAlTrbMov))
	EndIf

	// abre o arquivo de trabalho
	(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
	(_cAlTrbMov)->(dbGoTop())

	// refresh do browse
	If (_oBrwMovCnt <> nil)
		_oBrwMovCnt:oBrowse:Refresh()
	EndIf

Return

// ** busca as notas fiscais de saida referente ao faturamento de servicos
Static Function sfFatServico(mvFirst)

	// verifica se deve processar o faturamento de servicos
	If (!_lFatServ)
		Return(.t.)
	EndIf

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStFatSrv,{"C5_NUM"    ,"C", TamSx3("C5_NUM")[1],0})					    ; aAdd(_aHdFatSrv,{"C5_NUM","","Nr.Pedido","@!"})
		aAdd(_aStFatSrv,{"C5_EMISSAO","D", TamSx3("C5_EMISSAO")[1],0})					; aAdd(_aHdFatSrv,{"C5_EMISSAO","",RetTitle("C5_EMISSAO"),PesqPict("SC5","C5_EMISSAO")})
		aAdd(_aStFatSrv,{"C6_VALOR"  ,"N", TamSx3("C6_VALOR")[1],TamSx3("C6_VALOR")[2]}); aAdd(_aHdFatSrv,{"C6_VALOR","",RetTitle("C6_VALOR"),PesqPict("SC6","C6_VALOR")})
		aAdd(_aStFatSrv,{"C5_NOTA"   ,"C", TamSx3("C5_NOTA")[1],0})						; aAdd(_aHdFatSrv,{"C5_NOTA","",RetTitle("C5_NOTA"),PesqPict("SC5","C5_NOTA")})
		aAdd(_aStFatSrv,{"C5_SERIE"  ,"C", TamSx3("C5_SERIE")[1],0})					; aAdd(_aHdFatSrv,{"C5_SERIE","",RetTitle("C5_SERIE"),PesqPict("SC5","C5_SERIE")})
		aAdd(_aStFatSrv,{"E1_SALDO"  ,"N", TamSx3("E1_SALDO")[1],TamSx3("E1_SALDO")[2]}); aAdd(_aHdFatSrv,{"E1_SALDO","",RetTitle("E1_SALDO"),PesqPict("SE1","E1_SALDO")})
		aAdd(_aStFatSrv,{"C5_CLIENTE","C", TamSx3("C5_CLIENTE")[1],0})
		aAdd(_aStFatSrv,{"C5_LOJACLI","C", TamSx3("C5_LOJACLI")[1],0})

		// fecha alias do TRB
		If (Select(_TRBFAT)<>0)
			dbSelectArea(_TRBFAT)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrFatSrv := FWTemporaryTable():New( _TRBFAT )
		_cTrFatSrv:SetFields( _aStFatSrv )
		_cTrFatSrv:Create()
	EndIf

	// limpa o conteudo do TRB
	(_TRBFAT)->(dbSelectArea(_TRBFAT))
	(_TRBFAT)->(__DbZap())

	If (!mvFirst)
		// novas tabelas de faturamento
		If AliasInDic("SZL")
			// busca os pedidos faturados
			_cQuery := "SELECT DISTINCT C5_NUM, C5_EMISSAO, "
			// busca o valor total por pedido
			_cQuery += "(SELECT SUM(C6_VALOR) FROM "+RetSqlName("SC6")+" (nolock)  WHERE C6_FILIAL = C5_FILIAL AND C6_NUM = C5_NUM AND D_E_L_E_T_ = ' ') C6_VALOR, "
			_cQuery += "C5_NOTA, C5_SERIE, "
			// saldo dos titulos
			_cQuery += "(SELECT ISNULL(SUM(E1_SALDO),0) FROM " + RetSqlName("SE1") + " (NOLOCK) "
			_cQuery += "WHERE E1_FILIAL = '"+xFilial("SE1")+"' AND D_E_L_E_T_ = ' ' "
			_cQuery += "AND E1_PREFIXO = F2_PREFIXO AND E1_NUM = F2_DUPL AND E1_TIPO = 'NF' "
			_cQuery += "AND E1_CLIENTE = '"+_cCodCli+"' AND E1_LOJA = '"+_cLojCli+"') E1_SALDO, "
			// codido e loja do cliente
			_cQuery += "C5_CLIENTE, C5_LOJACLI "
			// itens faturados da programacao
			_cQuery += "FROM "+RetSqlName("SC5")+" SC5 (NOLOCK) "
			// relacionamento com a nota de saida
			_cQuery += "LEFT JOIN  "+RetSqlName("SF2")+" SF2 (NOLOCK) ON F2_FILIAL = '"+xFilial("SF2")+"' AND SC5.D_E_L_E_T_ = ' ' "
			_cQuery += "     AND F2_DOC = C5_NOTA AND F2_SERIE = C5_SERIE "
			_cQuery += "     AND F2_CLIENTE = C5_CLIENT AND F2_LOJA = C5_LOJACLI "
			// filtro das informacoes pelo numero da programacao
			_cQuery += "WHERE "+RetSqlCond("SC5")+" "
			_cQuery += "AND C5_ZPROCES = '"+_cNumProg+"' "
			_cQuery += "AND C5_TIPOOPE = 'S' "
			// ordem das informacoes
			_cQuery += "ORDER BY C5_NUM

			// forma antiga de faturamento de contratos
		Else
			// busca os pedidos faturados
			_cQuery := "SELECT DISTINCT ZS_PEDIDO C5_NUM, C5_EMISSAO, "
			// busca o valor total por pedido
			_cQuery += "(SELECT SUM(C6_VALOR) FROM "+RetSqlName("SC6")+" (nolock)  WHERE C6_FILIAL = C5_FILIAL AND C6_NUM = C5_NUM AND D_E_L_E_T_ = ' ') C6_VALOR, "
			_cQuery += "C5_NOTA, C5_SERIE, "
			// saldo dos titulos
			_cQuery += "(SELECT ISNULL(SUM(E1_SALDO),0) FROM " + RetSqlName("SE1") + " (NOLOCK)"
			_cQuery += "WHERE E1_FILIAL = '"+xFilial("SE1")+"' AND D_E_L_E_T_ = ' ' "
			_cQuery += "AND E1_PREFIXO = F2_PREFIXO AND E1_NUM = F2_DUPL AND E1_TIPO = 'NF' "
			_cQuery += "AND E1_CLIENTE = '"+_cCodCli+"' AND E1_LOJA = '"+_cLojCli+"') E1_SALDO "
			// codido e loja do cliente
			_cQuery += "C5_CLIENTE, C5_LOJACLI "
			// itens faturados da programacao
			_cQuery += "FROM "+RetSqlName("SZS")+" SZS (NOLOCK) "
			// filtro do pedido tipo SERVICO
			_cQuery += "INNER JOIN "+RetSqlName("SC5")+" SC5 (NOLOCK) ON C5_FILIAL = '"+xFilial("SC5")+"' AND C5_NUM = ZS_PEDIDO AND SC5.D_E_L_E_T_ = ' ' "
			_cQuery += "AND C5_TIPOOPE = 'S' "
			// relacionamento com a nota de saida
			_cQuery += "LEFT JOIN  "+RetSqlName("SF2")+" SF2 (NOLOCK) ON F2_FILIAL = '"+xFilial("SF2")+"' AND SC5.D_E_L_E_T_ = ' ' "
			_cQuery += "     AND F2_DOC = C5_NOTA AND F2_SERIE = C5_SERIE "
			_cQuery += "     AND F2_CLIENTE = ZS_CODCLI AND F2_LOJA = ZS_LOJCLI "
			// filtro das informacoes pelo numero da programacao
			_cQuery += "WHERE ZS_FILIAL = '"+xFilial("SZS")+"' AND SZS.D_E_L_E_T_ = ' ' "
			_cQuery += "AND ZS_PROGRAM = '"+_cNumProg+"' "
			// ordem das informacoes
			_cQuery += "ORDER BY ZS_PEDIDO"
		EndIf

		memowrit("c:\query\sfFatServico.txt",_cQuery)

		// adiciona o conteudo da query para o arquivo de trabalho
		SqlToTrb(_cQuery,_aStFatSrv,_TRBFAT)
	EndIf

	// abre o arquivo de trabalho
	(_TRBFAT)->(dbSelectArea(_TRBFAT))
	(_TRBFAT)->(dbGoTop())

	// refresh do browse
	If (_oBrwFatSrv <> nil)
		_oBrwFatSrv:oBrowse:Refresh()
	EndIf

Return

// ** funcao que pesquisa a programacao por referencia / mov container
Static Function sfPesqRef()
	local _cQuery
	// itens do retorno
	local _aItens := {}
	// variavel de retorno
	local _lRet := .f.
	// pesquisa por container
	local _lPesqCnt := (AllTrim(Upper(ReadVar()))=="_CNUMCONT")

	// pesquisa com curinga
	local mvReferen := StrTran(AllTrim(_cReferen),'*','%')

	// monta a query de pesquisa
	_cQuery := "SELECT DISTINCT Z1_CODIGO, Z1_REFEREN, Z2_DOCUMEN, A1_NOME, "+If(_lPesqCnt,"Z3_CONTAIN","''")+" Z3_CONTAIN "
	// cadastro de programacoes
	_cQuery += "FROM "+RetSqlName("SZ1")+" SZ1 (NOLOCK) "
	// itens da programacao
	_cQuery += "INNER JOIN "+RetSqlName("SZ2")+" SZ2 (NOLOCK) ON Z2_FILIAL = '"+xFilial("SZ2")+"' AND SZ2.D_E_L_E_T_ = ' ' AND Z2_CODIGO = Z1_CODIGO "
	// cadastro de cliente
	_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 (NOLOCK) ON A1_FILIAL = '"+xFilial("SA1")+"' AND SA1.D_E_L_E_T_ = ' ' AND A1_COD = Z1_CLIENTE AND A1_LOJA = Z1_LOJA "
	// pesquisa movimentacao de container
	If (_lPesqCnt)
		// movimentacoes de entrada do container
		_cQuery += "INNER JOIN "+RetSqlName("SZ3")+" SZ3 (NOLOCK) ON Z3_FILIAL = '"+xFilial("SZ3")+"' AND SZ3.D_E_L_E_T_ = ' ' "
		_cQuery += "AND Z3_PROGRAM = Z1_CODIGO AND Z3_ITEPROG = Z2_ITEM "
		_cQuery += "AND Z3_CONTAIN = '"+_cNumCont+"' "
		_cQuery += "AND Z3_TPMOVIM = 'E' "
	EndIf
	// filtro da filial da programacao
	_cQuery += "WHERE Z1_FILIAL = '"+xFilial("SZ1")+"' AND SZ1.D_E_L_E_T_ = ' ' "
	// filtro por referencia
	If (!_lPesqCnt)
		_cQuery += "AND (Z1_REFEREN LIKE '"+mvReferen+"' OR Z2_DOCUMEN LIKE '"+mvReferen+"') "
	EndIf
	// ordem das informacoes
	_cQuery += "ORDER BY Z1_CODIGO"
	// retorno dos dados em vetor
	_aItens := U_SqlToVet(_cQuery)

	// se nao encontrou itens
	If (Len(_aItens) == 0)
		Aviso("TWMSV004 -> sfPesqRef","Nenhuma programação encontrada com esta referência.",{"Fechar"})
		Return(.f.)

		// se retornou 1 item
	ElseIf (Len(_aItens) == 1)
		// retorna o numero da programacao
		_cNumProg := _aItens[1][1]
		Return(.t.)

		// se retornou mais de um item, apresenta tela para o usuario escolher
	ElseIf (Len(_aItens) > 1)
		// monta a tela
		_oDlgSelProg := MSDialog():New(000,000,300,500,"Programações...",,,.F.,,,,,,.T.,,,.T. )
		// cria o objeto do brose
		_oBrwProg := TWBrowse():New(000,000,300,500,,{	RetTitle("Z1_CODIGO"),;
		RetTitle("Z1_REFEREN"),;
		RetTitle("Z2_DOCUMEN"),;
		RetTitle("A1_NOME"),;
		RetTitle("ZC_CODIGO") },{20,20,30,30},_oDlgSelProg,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
		_oBrwProg:Align:= CONTROL_ALIGN_ALLCLIENT
		// seta os itens do browse
		_oBrwProg:SetArray(_aItens)
		// escreve as linhas do browse
		_oBrwProg:bLine := {|| {_aItens[_oBrwProg:nAt,01],;
		_aItens[_oBrwProg:nAt,02],;
		_aItens[_oBrwProg:nAt,03],;
		_aItens[_oBrwProg:nAt,04],;
		_aItens[_oBrwProg:nAt,05] }}

		// funcao do duplo-click
		_oBrwProg:bLDblClick := {|| _lRet := .t., _cNumProg := _aItens[_oBrwProg:nAt,01] , _oDlgSelProg:End() }

		// ativa a tela
		ACTIVATE MSDIALOG _oDlgSelProg CENTERED ON INIT EnchoiceBar(_oDlgSelProg,{|| _lRet := .t., _cNumProg := _aItens[_oBrwProg:nAt,01], _oDlgSelProg:End()} ,;
		{|| _oDlgSelProg:End() })
	EndIf

Return(_lRet)

// ** funcao que retorna se o usuario tem permissao para visualizar a aba de faturamento de servicos
Static Function sfVisFatSrv()
	// variavel de retorno
	local _lRet := (__cUserId=="000000")
	// grupos do usuario
	local _aGrupos := {}
	// variavel temporaria
	local _nX

	// se for consulta unica
	If (_lConsUnica)
		Return(.f.)
	EndIf

	// verifica os dados do usuario
	If (!_lRet)
		// busca os grupos do usuario
		_aGrupos := FWSFUsrGrps(__cUserId)
		// varre todos os grupos do usuario
		For _nX := 1 to Len(_aGrupos)
			// se for usuario do grupo FINANCEIRO (000003) , ou com nome "finan-ceiro" ou faturamento (000012)
			If ("000003" $ Upper(_aGrupos[_nX])).or.("FINAN" $ Upper(GRPRetName(_aGrupos[_nX]))).or.("000012" $ Upper(_aGrupos[_nX]))
				_lRet := .t.
				Exit
				// se for usuario ADMINISTRADOR
			ElseIf ("000000" $ Upper(_aGrupos[_nX])).or.("ADMIN" $ Upper(GRPRetName(_aGrupos[_nX])))
				_lRet := .t.
				Exit
			EndIf
		Next _nX
	EndIf
Return(_lRet)

// ** funcao para visualizar a nota de entrada
Static Function sfVisNFE()
	// cria variaveis internas do sistema
	private aRotina := {{"Pesquisar","AxPesqui",0,1},;
	{"Visualizar","A103NFiscal",0,2}}
	private aParamAuto := {}

	// pesquisa a nota de entrada
	dbSelectArea("SF1")
	SF1->(dbSetOrder(1)) //1-F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_FORMUL
	If SF1->(dbSeek( xFilial("SF1")+(_TRBNFE)->(F1_DOC+F1_SERIE)+_cCodCli+_cLojCli ))
		A103NFiscal("SF1",SF1->(RecNo()),1)
	EndIf
Return(.t.)

// ** funcao para visualizar o pedido de venda
Static Function sfVisPedVen(mvPedido)
	// cria variaveis internas do sistema
	private aRotina := {{"Pesquisar","AxPesqui",0,1},;
	{"Visualizar","A410Visual",0,2}}
	private cCadastro := "Pedido de Venda"
	private ALTERA := .f.

	// pesquisa o pedido de venda
	dbSelectArea("SC5")
	SC5->(dbSetOrder(1)) //1-C5_FILIAL, C5_NUM
	If SC5->(dbSeek( xFilial("SC5")+mvPedido ))
		A410Visual("SC5",SC5->(RecNo()),2)
	EndIf
Return(.t.)

// ** funcao para visualizar a nota de entrada
Static Function sfVisNFS(mvNota,mvSerie)

	// se a nota estiver em branco
	If (Empty(mvNota))
		Aviso("TWMSV004 -> sfVisNFS","Não há Nota Fiscal para visualizar.",{"Fechar"})
		Return(.f.)
	EndIf

	// pesquisa a nota fiscal de saida
	dbSelectArea("SF2")
	SF2->(dbSetOrder(1)) //1-F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA
	If SF2->(dbSeek( xFilial("SF2")+mvNota+mvSerie+_cCodCli+_cLojCli ))
		Mc090Visual("SF2",SF2->(RecNo()),2)
	EndIf
Return(.t.)

// ** funcao que imprime o detalhes do faturamento de servicos
Static Function sfImpDetFat()
	U_WMSR004A((_TRBFAT)->C5_NUM,(_TRBFAT)->C5_NUM,nil,nil,nil,nil,nil,nil)
Return

// ** funcao que detalha os titulos a receber da nota
Static Function sfDetFinanc()
	local _cQuery
	// titulos da nota
	local _aTitulos := {}

	// monta a query de pesquisa
	_cQuery := "SELECT E1_PREFIXO, E1_NUM, E1_PARCELA, E1_EMISSAO, E1_VENCREA, E1_VALOR, E1_SALDO, E1_BAIXA, "
	// numero da fatura
	_cQuery += "E1_FATURA, "
	// data da baixa da fatura
	_cQuery += "(SELECT SE1FAT.E1_BAIXA FROM "+RetSqlName("SE1")+" SE1FAT (NOLOCK) WHERE SE1FAT.E1_FILIAL = SE1.E1_FILIAL AND SE1FAT.D_E_L_E_T_ = ' ' "
	_cQuery += "AND SE1FAT.E1_PREFIXO = SE1.E1_FATPREF "
	_cQuery += "AND SE1FAT.E1_NUM     = SE1.E1_FATURA "
	_cQuery += "AND SE1FAT.E1_TIPO    = SE1.E1_TIPOFAT "
	_cQuery += "AND SE1FAT.E1_CLIENTE = SE1.E1_CLIENTE AND SE1FAT.E1_LOJA = SE1.E1_LOJA) DT_PGTO_FT "
	// titulos a receber
	_cQuery += "FROM "+RetSqlName("SE1")+" SE1 (NOLOCK) "
	// filtro dos titulos
	_cQuery += "WHERE "+RetSqlCond("SE1")+" "
	_cQuery += "AND E1_PREFIXO = '"+(_TRBFAT)->C5_SERIE+"'   AND E1_NUM  = '"+(_TRBFAT)->C5_NOTA+"' "
	_cQuery += "AND E1_TIPO    = 'NF' "
	_cQuery += "AND E1_CLIENTE = '"+(_TRBFAT)->C5_CLIENTE+"' AND E1_LOJA = '"+(_TRBFAT)->C5_LOJACLI+"' "
	// retorno dos dados em vetor
	_aTitulos := U_SqlToVet(_cQuery,{"E1_EMISSAO","E1_VENCREA","E1_BAIXA","DT_PGTO_FT"})

	// monta a tela
	_oDlgDetFin := MSDialog():New(000,000,300,500,"Titulos...",,,.F.,,,,,,.T.,,,.T. )
	// cria o objeto do brose
	_oBrwDetFin := TWBrowse():New(000,000,300,500,,{RetTitle("E1_PREFIXO"),;
	RetTitle("E1_NUM"),;
	RetTitle("E1_PARCELA"),;
	RetTitle("E1_EMISSAO"),;
	RetTitle("E1_VENCREA"),;
	RetTitle("E1_VALOR"),;
	RetTitle("E1_SALDO"),;
	RetTitle("E1_BAIXA"),;
	RetTitle("E1_FATURA"),;
	"Dt.Bx.Fat." },{6,20,6,25,25,30,30,25},_oDlgDetFin,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
	_oBrwDetFin:Align:= CONTROL_ALIGN_ALLCLIENT
	// seta os itens do browse
	_oBrwDetFin:SetArray(_aTitulos)
	// escreve as linhas do browse
	_oBrwDetFin:bLine := {|| {_aTitulos[_oBrwDetFin:nAt,01],;
	_aTitulos[_oBrwDetFin:nAt,02],;
	_aTitulos[_oBrwDetFin:nAt,03],;
	_aTitulos[_oBrwDetFin:nAt,04],;
	_aTitulos[_oBrwDetFin:nAt,05],;
	_aTitulos[_oBrwDetFin:nAt,06],;
	_aTitulos[_oBrwDetFin:nAt,07],;
	_aTitulos[_oBrwDetFin:nAt,08],;
	_aTitulos[_oBrwDetFin:nAt,09],;
	_aTitulos[_oBrwDetFin:nAt,10] }}

	// ativa a tela
	ACTIVATE MSDIALOG _oDlgDetFin CENTERED ON INIT EnchoiceBar(_oDlgDetFin,{||_oDlgDetFin:End()},{||_oDlgDetFin:End()})

Return

// ** funcao que visualiza as programacoes em aberto do cliente
Static Function sfProgAberta()
	local _cQuery
	// itens do retorno
	local _aProgAberta := {}
	// variavel de retorno
	local _lRet := .f.
	// codigo do cliente
	local mvCodCli := CriaVar("A1_COD",.f.)
	// loja do cliente
	local mvLojCli := CriaVar("A1_LOJA",.f.)
	// controle da confirmacao da tela
	local _lConfirm := .f.

	// tela para o usuario informar o cliente
	_oDlgInfCli := MSDialog():New(000,000,150,210,"Informe os parametros",,,.F.,,,,,,.T.,,,.T. )
	// codigo do cliente
	_oSayCodCli := TSay():New( 008,004,{||"Cliente:"},_oDlgInfCli,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGetCodCli := TGet():New( 005,050,{|u| If(PCount()>0,mvCodCli:=u,mvCodCli)},_oDlgInfCli,050,014,PesqPict("SA1","A1_COD"),,,,_oFnt01,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SA1","mvCodCli",,)
	// loja do cliente
	_oSayLojCli := TSay():New( 028,004,{||"Loja:"},_oDlgInfCli,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGetLojCli := TGet():New( 025,050,{|u| If(PCount()>0,mvLojCli:=u,mvLojCli)},_oDlgInfCli,030,014,PesqPict("SA1","A1_LOJA"),,,,_oFnt01,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","mvLojCli",,)
	// botao cancelar
	_oBtnConfCli := TButton():New(050,007,"Confirmar",_oDlgInfCli,{|| _lConfirm := .t., _oDlgInfCli:End() },040,012,,,,.T.,,"",,,,.F. )
	// botao para confirmar
	_oBtnCancCli := TButton():New(050,055,"Cancelar",_oDlgInfCli,{|| _oDlgInfCli:End() },040,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgInfCli:Activate(,,,.T.,)

	// caso nao tenha confirmado)
	If (!_lConfirm)
		Return(.f.)
	EndIf

	// monta a query de pesquisa
	_cQuery := "SELECT D1_PROGRAM, Z1_EMISSAO, D1_FORNECE, D1_LOJA, A1_NOME, SUM(D1_QUANT) D1_QUANT, SUM(B6_SALDO) B6_SALDO, D1_DOC, D1_SERIE "
	// saldo poder de terceiros
	_cQuery += "FROM "+RetSqlName("SB6")+" SB6 (NOLOCK) "
	// itens da nota, para pegar a programacao
	_cQuery += "INNER JOIN "+RetSqlName("SD1")+" SD1 (NOLOCK) ON D1_FILIAL = '"+xFilial("SD1")+"' AND D1_IDENTB6 = B6_IDENT AND SD1.D_E_L_E_T_ = ' ' "
	// cabecalho da programacao
	_cQuery += "INNER JOIN "+RetSqlName("SZ1")+" SZ1 (NOLOCK) ON Z1_FILIAL = '"+xFilial("SZ1")+"' AND Z1_CODIGO = D1_PROGRAM AND SZ1.D_E_L_E_T_ = ' ' "
	// cadastro de cliente
	_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 (NOLOCK) ON A1_FILIAL = '"+xFilial("SA1")+"' AND A1_COD = D1_FORNECE AND A1_LOJA = D1_LOJA AND SA1.D_E_L_E_T_ = ' ' "
	// filtro de saldo de terceiros
	_cQuery += "WHERE B6_FILIAL = '"+xFilial("SB6")+"' AND SB6.D_E_L_E_T_ = ' ' "
	_cQuery += "AND B6_PODER3 = 'R' "
	_cQuery += "AND B6_TPCF = 'C' "
	// somente com saldo
	_cQuery += "AND B6_SALDO > 0 "
	// de um cliente especifico
	If (!Empty(mvCodCli))
		_cQuery += "AND B6_CLIFOR = '"+mvCodCli+"' "
		// de uma loja especifica
		If (!Empty(mvLojCli))
			_cQuery += "AND B6_LOJA = '"+mvLojCli+"' "
		EndIf
	EndIF
	// agrupamento e ordem por programacao e emissao
	_cQuery += "GROUP BY D1_PROGRAM, Z1_EMISSAO, D1_FORNECE, D1_LOJA, A1_NOME, D1_DOC, D1_SERIE "
	_cQuery += "ORDER BY D1_PROGRAM"

	// retorno dos dados em vetor
	_aProgAberta := U_SqlToVet(_cQuery,{"Z1_EMISSAO"})

	// se nao encontrou itens
	If (Len(_aProgAberta) == 0)
		Aviso("TWMSV004 -> sfProgAberta","Nenhuma programação em aberto encontrada.",{"Fechar"})
		Return(.f.)

		// se retornou mais de um item, apresenta tela para o usuario escolher
	ElseIf (Len(_aProgAberta) > 0)
		// monta a tela
		_oDlgSelProg := MSDialog():New(000,000,300,700,"Programações em aberto",,,.F.,,,,,,.T.,,,.T. )
		// painel superior com as opcoes
		_oPnlSelProg := TPanel():New(000,000,nil,_oDlgSelProg,,.F.,.F.,,,022,022,.T.,.F. )
		_oPnlSelProg:Align:= CONTROL_ALIGN_TOP
		// opcao para confirmar a tela
		_oBtnPrgAbrConf := TButton():New(005,005,"Confirmar" ,_oPnlSelProg,{|| _lRet := .t., _cNumProg := _aProgAberta[_oBrwProgAberta:nAt,01], _oDlgSelProg:End() },040,010,,,,.T.,,"",,,,.F. )
		// opcao de visualizar a nota de saida
		_oBtnPrgAbrCanc := TButton():New(005,050,"Cancelar"  ,_oPnlSelProg,{|| _oDlgSelProg:End() },040,010,,,,.T.,,"",,,,.F. )
		// opcao de visualizar a nota de saida
		_oBtnPrgAbrConf := TButton():New(005,095,"Exp. Excel",_oPnlSelProg,{|| sfExpExcel(_aProgAberta) },040,010,,,,.T.,,"",,,,.F. )
		// cria o objeto do brose
		_oBrwProgAberta := TWBrowse():New(000,000,300,500,,{RetTitle("D1_PROGRAM"),;
		RetTitle("Z1_EMISSAO"),;
		"Cód. Cliente",;
		"Loja Cliente",;
		"Nome",;
		"Qtd. Entrada",;
		"Saldo da Qtd.",;
		"Nota Fiscal",;
		"Serie" },{20,40,40,20,70,20,20,30,20},_oDlgSelProg,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
		_oBrwProgAberta:Align:= CONTROL_ALIGN_ALLCLIENT
		// seta os itens do browse
		_oBrwProgAberta:SetArray(_aProgAberta)
		// escreve as linhas do browse
		_oBrwProgAberta:bLine := {|| {_aProgAberta[_oBrwProgAberta:nAt,01],;
		_aProgAberta[_oBrwProgAberta:nAt,02],;
		_aProgAberta[_oBrwProgAberta:nAt,03],;
		_aProgAberta[_oBrwProgAberta:nAt,04],;
		_aProgAberta[_oBrwProgAberta:nAt,05],;
		_aProgAberta[_oBrwProgAberta:nAt,06],;
		_aProgAberta[_oBrwProgAberta:nAt,07],;
		_aProgAberta[_oBrwProgAberta:nAt,08],;
		_aProgAberta[_oBrwProgAberta:nAt,09] }}

		// funcao do duplo-click
		_oBrwProgAberta:bLDblClick := {|| _lRet := .t., _cNumProg := _aProgAberta[_oBrwProgAberta:nAt,01] , _oDlgSelProg:End() }

		// ativa a tela
		ACTIVATE MSDIALOG _oDlgSelProg CENTERED

		// foco no campo numero da programacao
		If (_lRet)
			_oGetNumProg:SetFocus()
		EndIf
	EndIf

Return(_lRet)

// ** funcao para exportar para o excel
Static Function sfExpExcel(mvDados)
	DlgToExcel({{"ARRAY","Programacoes em Aberto", {"Nr Prog.","Dt Emissão","Cód. Cliente","Loja Cliente","Nome","Qtd. Entrada","Saldo da Qtd.","Nota Fiscal","Serie"}, mvDados}})
Return

// ** funcao para processar o faturamento do contrato
Static Function sfFatContrato()
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSZ1 := SZ1->(GetArea())
	// nova rotina de faturament
	local _lNewRotFat := AliasInDic("SZL")


	// verifica se tem programacao informada
	If (Empty(_cNumProg))
		Aviso("TWMSV004 -> sfFatContrato","É obrigatório informar uma programação.",{"Fechar"})
		Return(.f.)
	EndIf

	// chama a rotina padrao de faturamento de contratos
	If (_lNewRotFat)
		// chama o grupo de perguntas da rotina de faturamento
		Pergunte("TFATA002",.f.)

		// muda os parametros, de acordo com a programacao em aberto
		// estrutura do grupo de perguntas
		// mv_par01 - Processo de ?
		mv_par01 := _cNumProg
		// mv_par02 - Processo Até?
		mv_par02 := _cNumProg
		// mv_par03 - Cliente de ?
		mv_par03 := _cCodCli
		// mv_par04 - Cliente Até?
		mv_par04 := _cCodCli
		// mv_par05 - Contrato de ?
		mv_par05 := " "
		// mv_par06 - Contrato Até?
		mv_par06 := "ZZ"
		// mv_par07 - Mostra Faturados ?
		mv_par07 := 2 //1-Sim/2-Nao
		// mv_par08 - Tipo de Servico ?
		mv_par08 := "99" //99-Todos
		// mv_par09 - Status do Processo ?
		mv_par09 := 3 //1-Aberto/2-Encerrado/3-Ambos

		// rotina de faturamento de contratos
		U_FATA002A(.f.,.f.)

		// rotina antiga de faturamento
	ElseIf (!_lNewRotFat)
		// chama o grupo de perguntas da rotina de faturamento
		Pergunte("TWMSA004",.f.)

		// muda os parametros, de acordo com a programacao em aberto
		// estrutura do grupo de perguntas
		// mv_par01 - Contrato de ?
		mv_par01 := " "
		// mv_par02 - Contrato Até?
		mv_par02 := "ZZ"
		// mv_par03 - Cliente de ?
		mv_par03 := _cCodCli
		// mv_par04 - Cliente Até?
		mv_par04 := _cCodCli
		// mv_par05 - Processo de ?
		mv_par05 := _cNumProg
		// mv_par06 - Processo Até?
		mv_par06 := _cNumProg
		// mv_par07 - Mostra Faturados ?
		mv_par07 := 2 //1-Sim/2-Nao
		// mv_par08 - Tipo de Servico ?
		mv_par08 := "09" //09-Todos
		// mv_par09 - Status do Processo ?
		mv_par09 := 3 //1-Aberto/2-Encerrado/3-Ambos

		// rotina de faturamento de contratos
		Processa({|| U_WMSA004P(.f.) },"Gerando P.Vendas por Contrato",,.T. )
	EndIf

	// restaura area inicial
	RestArea(_aAreaSZ1)
	RestArea(_aAreaAtu)

	// foco no campo numero da programacao
	_oGetNumProg:SetFocus()

Return(.t.)

// ** funcao para impressao do mapa de movimentacao
Static Function sfImpMapMov()
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSZ1 := SZ1->(GetArea())

	// executa rotina padrao de impressao do mapa de movimentacao de produtos
	U_TWMSR006()

	// restaura area inicial
	RestArea(_aAreaSZ1)
	RestArea(_aAreaAtu)
Return

// ** funcao para calcular o total de saida e saldo das notas de entrada
Static Function sfCalcSaldo()
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaEnt := (_TRBNFE)->(GetArea())
	local _aAreaSai := (_cAlTrbSai)->(GetArea())

	// zera totalizadores das notas de entrada
	_nEntPesBru := 0
	_nEntPesLiq := 0
	_nEntCubage := 0
	// zera totalizadores das notas de saida
	_nSaiPesBru := 0
	_nSaiPesLiq := 0
	_nSaiCubage := 0

	// calcula todo o peso das notas de entrada
	(_TRBNFE)->(dbSelectArea(_TRBNFE))
	(_TRBNFE)->(dbGoTop())
	While (_TRBNFE)->( ! Eof() )
		// soma no total
		_nEntPesBru += (_TRBNFE)->F1_PBRUTO
		_nEntPesLiq += (_TRBNFE)->F1_PLIQUI
		_nEntCubage += (_TRBNFE)->F1_CUBAGEM
		// proxima nota
		(_TRBNFE)->(dbSkip())
	EndDo

	// calcula todo o peso das notas de saida
	(_cAlTrbSai)->(dbSelectArea(_cAlTrbSai))
	(_cAlTrbSai)->(dbGoTop())
	While (_cAlTrbSai)->( ! Eof() )
		// soma no total
		_nSaiPesBru += (_cAlTrbSai)->D2_ZPESOB
		_nSaiPesLiq += (_cAlTrbSai)->D2_ZPESOL
		_nSaiCubage += (_cAlTrbSai)->D2_ZCUBAGE
		// proxima nota
		(_cAlTrbSai)->(dbSkip())
	EndDo

	// saldos
	_nSldPesBru := (_nEntPesBru - _nSaiPesBru)
	_nSldPesLiq := (_nEntPesLiq - _nSaiPesLiq)
	_nSldCubage := (_nEntCubage - _nSaiCubage)

	// restaura area inicial
	RestArea(_aAreaEnt)
	RestArea(_aAreaSai)
	RestArea(_aAreaAtu)

Return(.t.)

// ** funcao para executar o rateio dos pesos e cubagem da programacao
Static Function sfRateio(mvProgram, mvRotAuto)
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSC5 := SC5->(GetArea())
	local _aAreaSC6 := SC6->(GetArea())
	local _aAreaSD1 := SD1->(GetArea())
	local _aAreaSD2 := SD1->(GetArea())
	// controle do retorno
	local _lRet := .t.
	// variavel temporarias
	local _aTmpQtd := {}
	local _cSeekSD1
	local _cQuery
	// quantidade de itens ja rateados (tratamento por causa dos itens deletados)
	local _nQtdItRat := 0
	local _nQtdTotal := 0
	local _nQtdItens := 0
	local _nPercRat := 0
	// produto com peso no cadastro
	local _lPesoCad := .f.
	// produto com peso rateado
	local _lPesoRat := .f.

	// valores padroes
	Default mvRotAuto := .f.

	If ( ! mvRotAuto ).and.( ! MsgYesNo("Confirma o reprocessamento de peso bruto, líquido e cubagem?", "Atenção") )
		Return(.f.)
	EndIf

	// monta query de acordo com o parametro
	_cQuery := "SELECT F1_FILIAL, F1_FORNECE, F1_LOJA, A1_NOME, F1_DOC, F1_SERIE, F1_PROGRAM, F1_PBRUTO, F1_PLIQUI, F1_CUBAGEM "
	_cQuery += "FROM "+RetSqlName("SF1")+" SF1 (NOLOCK) "
	_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 (NOLOCK) ON A1_FILIAL = '"+xFilial("SA1")+"' AND A1_COD = F1_FORNECE AND A1_LOJA = F1_LOJA AND SA1.D_E_L_E_T_ = ' ' "
	_cQuery += "WHERE SF1.D_E_L_E_T_ = ' ' AND F1_FILIAL = '"+xFilial("SF1")+"' "
	_cQuery += "AND F1_TIPO IN ('B','D') "
	_cQuery += "AND F1_STATUS = 'A' "
	_cQuery += "AND F1_PROGRAM = '"+mvProgram+"' "

	MemoWrit("c:\query\twmsv004_sfRateio_1_sf1.txt", _cQuery)

	If (Select("_QRYSF1") <> 0)
		dbSelectArea("_QRYSF1")
		dbCloseArea()
	EndIf

	TcQuery _cQuery New Alias "_QRYSF1"
	dbSelectArea("_QRYSF1")

	BEGIN TRANSACTION

		While _QRYSF1->(!Eof())
			// verifica se o peso esta informado
			If (_QRYSF1->F1_PBRUTO == 0).or.(_QRYSF1->F1_PLIQUI == 0).or.(_QRYSF1->F1_CUBAGEM == 0)
				
				// libera todos os registros
				MsUnLockAll()
				// mensagem
				If ( ! mvRotAuto )
					Aviso("Pesos...","Faltando informacoes do peso e cubagem",{"Fechar"})
				EndIf
				// restaura area inicial
				RestArea(_aAreaSC5)
				RestArea(_aAreaSC6)
				RestArea(_aAreaSD1)
				RestArea(_aAreaSD2)
				RestArea(_aAreaAtu)
				_lRet := .F.
				// rollback
				DisarmTransaction()
				Break
			EndIF

			// retorna a quantidade de itens da nota
			_cQuery := "SELECT SUM(D1_QUANT) D1_QUANT, COUNT(*) QTD_REG, SUM(D1_ZPESOB) D1_ZPESOB "
			_cQuery += "FROM "+RetSqlName("SD1")+" (NOLOCK)  "
			_cQuery += "WHERE D1_FILIAL = '"+_QRYSF1->F1_FILIAL+"' AND D_E_L_E_T_ = ' ' "
			_cQuery += "AND D1_DOC = '"+_QRYSF1->F1_DOC+"' AND D1_SERIE = '"+_QRYSF1->F1_SERIE+"' "
			_cQuery += "AND D1_FORNECE = '"+_QRYSF1->F1_FORNECE+"' AND D1_LOJA = '"+_QRYSF1->F1_LOJA+"' "

			MemoWrit("c:\query\twmsv004_sfRateio_2_sd1.txt", _cQuery)

			_aTmpQtd := U_SqlToVet(_cQuery)

			// quantidade total
			_nQtdTotal := _aTmpQtd[1,1]
			// quantidade de itens
			_nQtdItens := _aTmpQtd[1,2]

			// armazena saldo
			_nSldLiqui := Round(_QRYSF1->F1_PLIQUI , TamSx3("F1_PLIQUI")[2] )
			_nSldBruto := Round(_QRYSF1->F1_PBRUTO , TamSx3("F1_PBRUTO")[2] )
			_nSldCubag := Round(_QRYSF1->F1_CUBAGEM, TamSx3("F1_CUBAGEM")[2])
			// zera variavel
			_nQtdItRat := 0
			_lPesoCad := .f.
			_lPesoRat := .f.
			_lRet := .t.

			// pesquisa os itens da nota
			dbSelectArea("SD1")
			SD1->(dbSetOrder(1)) //1-D1_FILIAL, D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_COD, D1_ITEM
			SD1->(dbSeek( _cSeekSD1 := _QRYSF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) ))
			While SD1->(!Eof()).and.(SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA)==_cSeekSD1)

				// quantidade de itens ja rateado
				_nQtdItRat ++

				// calcula o percentual de rateio do item
				_nPercRat := ((SD1->D1_QUANT * 100) / _nQtdTotal)

				// verifica se o peso esta informado no produto
				dbSelectArea("SB1")
				SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
				SB1->(dbSeek( xFilial("SB1")+SD1->D1_COD ))
				If (SB1->B1_PESO > 0).and.(SB1->B1_PESBRU > 0)
					// atualiza o peso liquido e bruto
					dbSelectArea("SD1")
					RecLock("SD1")
					SD1->D1_ZPESOL	:= NoRound((SD1->D1_QUANT * SB1->B1_PESO)  ,TamSx3("D1_ZPESOL")[2])
					SD1->D1_ZPESOB	:= NoRound((SD1->D1_QUANT * SB1->B1_PESBRU),TamSx3("D1_ZPESOB")[2])
					SD1->(MsUnLock())
					// marca status de produto com peso no cadastro
					_lPesoCad := .t.
				Else
					// atualiza o peso liquido e bruto
					dbSelectArea("SD1")
					RecLock("SD1")
					SD1->D1_ZPESOL	:= NoRound(IIf(_nQtdItens==_nQtdItRat, _nSldLiqui, ((_QRYSF1->F1_PLIQUI * _nPercRat) / 100)), TamSx3("D1_ZPESOL")[2])
					SD1->D1_ZPESOB	:= NoRound(IIf(_nQtdItens==_nQtdItRat, _nSldBruto, ((_QRYSF1->F1_PBRUTO * _nPercRat) / 100)), TamSx3("D1_ZPESOB")[2])
					SD1->(MsUnLock())
					// marca status de produto com peso rateado
					_lPesoRat := .t.
				EndIf

				// atualiza a cubagem
				dbSelectArea("SD1")
				RecLock("SD1")
				SD1->D1_ZCUBAGE := NoRound( IIf(_nQtdItens==_nQtdItRat, _nSldCubag, ((_QRYSF1->F1_CUBAGEM * _nPercRat) / 100)) ,TamSx3("D1_ZCUBAGE")[2])
				SD1->(MsUnLock())

				// atualiza dados das movimentacoes de poder de terceiro (entrada)
				sfAtuSB6(SD1->D1_FORNECE, SD1->D1_LOJA, SD1->D1_COD, SD1->D1_IDENTB6, "R", SD1->D1_DOC, SD1->D1_SERIE, SD1->D1_QUANT)

				// depois que acertar o item da nota de entrada, acerta os itens de devolucao
				sfAtuSC6(mvRotAuto)

				// diminui o saldo do peso
				_nSldLiqui -= SD1->D1_ZPESOL
				_nSldBruto -= SD1->D1_ZPESOB
				_nSldCubag -= SD1->D1_ZCUBAGE

				// proximo item da nota
				dbSelectArea("SD1")
				SD1->(dbSkip())
			EndDo

			// verifica se existe os dois tipos de peso (cadastro e rateado) - NAO PODE
			If (_lRet).and.((_lPesoCad).and.(_lPesoRat))
				// libera todos os registros
				MsUnLockAll()
				// mensagem
				If ( ! mvRotAuto )
					Aviso("Pesos...","Não é permitido o rateio do peso quando houver produtos com o peso informado no cadastro.",{"Fechar"})
				EndIf

				// restaura area inicial
				RestArea(_aAreaSC5)
				RestArea(_aAreaSC6)
				RestArea(_aAreaSD1)
				RestArea(_aAreaSD2)
				RestArea(_aAreaAtu)
				_lRet := .F.
				// rollback
				DisarmTransaction()
				Break
			EndIf

			// verifica se todo o saldo foi rateado corretamente
			If (_lRet).and.((_nSldLiqui <> 0).or.(_nSldBruto <> 0).or.(_nSldCubag <> 0))
				// libera todos os registros
				MsUnLockAll()
				// mensagem
				If ( ! mvRotAuto )
					Aviso("Pesos...","Houve divergência no cálculo do peso bruto, peso liquido ou cubagem.",{"Fechar"})
				EndIf

				// restaura area inicial
				RestArea(_aAreaSC5)
				RestArea(_aAreaSC6)
				RestArea(_aAreaSD1)
				RestArea(_aAreaSD2)
				RestArea(_aAreaAtu)
				_lRet := .F.
				// rollback
				DisarmTransaction()
				Break
			EndIf

			// proxima nota
			dbSelectArea("_QRYSF1")
			_QRYSF1->(dbSkip())
		EndDo

		// fecha o alias principal
		dbSelectArea("_QRYSF1")
		dbCloseArea()

		// gera Log
		U_FtGeraLog(cFilAnt, "SZ1", xFilial("SZ1")+mvProgram, "Realizado o recálculo do peso bruto, líquido e cubagem da programação", "FAT", mvProgram)

	END TRANSACTION

	// libera todos os registros
	MsUnLockAll()

	If _lRet
		// mensagem
		If ( ! mvRotAuto )
			MsgInfo("Cálculo Ok")
		EndIf
	EndIf

	// restaura area inicial
	RestArea(_aAreaSC5)
	RestArea(_aAreaSC6)
	RestArea(_aAreaSD1)
	RestArea(_aAreaSD2)
	RestArea(_aAreaAtu)

Return(_lRet)

// ** funcao para acertar o sc6
Static function sfAtuSC6(mvRotAuto)
	// variavel temporaria
	local _cQuery
	local _nX
	// variaveis do calculo
	local _nPercRat := 0
	local _nRatSD2  := 0
	local _nSldSC6  := 0

	local _nSldPB  := 0
	local _nSldPL  := 0
	local _nSldCB  := 0

	// RECNO do SC6
	local _aRecnoSC6 := {}
	// Seek do SD2
	local _cSeekSD2
	// armazena saldo do item
	local _nSldLiqui := 0
	local _nSldBruto := 0
	local _nSldCubag := 0
	local _nSldQuant := 0

	// update de dados
	local _cUpdate

	// numeros de pedidos de venda
	local _cNumPed := ""

	Default mvRotAuto := .F.

	// busca todos os itens de devolucao
	_cQuery := "SELECT SC6.R_E_C_N_O_ SC6RECNO "
	_cQuery += "FROM "+RetSqlName("SC6")+" SC6 (NOLOCK) "
	_cQuery += "WHERE C6_FILIAL = '"+SD1->D1_FILIAL+"' AND D_E_L_E_T_ = ' ' "
	_cQuery += "AND ((C6_CLI = '"+SD1->D1_FORNECE+"' AND C6_LOJA = '"+SD1->D1_LOJA+"') OR (C6_CLI = '000140')) "
	_cQuery += "AND C6_NFORI = '"+SD1->D1_DOC+"' AND C6_SERIORI = '"+SD1->D1_SERIE+"' AND C6_ITEMORI = '"+SD1->D1_ITEM+"' "
	_cQuery += "AND C6_PRODUTO = '"+SD1->D1_COD+"' "

	MemoWrit("c:\query\twmsv004_sfRateio_sfAtuSC6.txt", _cQuery)

	// joga os RECNO para o vetor
	_aRecnoSC6 := U_SqlToVet(_cQuery)

	// armazena saldo do item
	_nSldLiqui := Round(SD1->D1_ZPESOL , TamSx3("F1_PLIQUI")[2] )
	_nSldBruto := Round(SD1->D1_ZPESOB , TamSx3("F1_PBRUTO")[2] )
	_nSldCubag := Round(SD1->D1_ZCUBAGE, TamSx3("F1_CUBAGEM")[2])
	_nSldQuant := SD1->D1_QUANT

	For _nX := 1 to Len(_aRecnoSC6)

		// posiciona no registro do SC6
		dbSelectArea("SC6")
		SC6->(dbGoTo(_aRecnoSC6[_nX]))

		// atualiza numeros dos pedidos de venda
		_cNumPed += IIf(Empty(_cNumPed),"",",")
		_cNumPed += "'" + SC6->C6_NUM + "'"

		// saldo da quantidade
		_nSldSC6 := SC6->C6_QTDVEN
		// saldo de peso e cubagem por item, para ratear conforme itens da nota
		_nSldPB := SC6->C6_ZPESOB
		_nSldPL := SC6->C6_ZPESOL
		_nSldCB := SC6->C6_ZCUBAGE

		// calcula o percentual de rateio do item
		_nPercRat := ((SC6->C6_QTDVEN * 100) / SD1->D1_QUANT)

		// atualiza o peso
		dbSelectArea("SC6")
		RecLock("SC6")
		SC6->C6_ZPESOB	:= NoRound( IIf(_nSldQuant==SC6->C6_QTDVEN, _nSldBruto, ((SD1->D1_ZPESOB  * _nPercRat) / 100)) , TamSx3("C6_ZPESOB")[2] )
		SC6->C6_ZPESOL	:= NoRound( IIf(_nSldQuant==SC6->C6_QTDVEN, _nSldLiqui, ((SD1->D1_ZPESOL  * _nPercRat) / 100)) , TamSx3("C6_ZPESOL")[2] )
		SC6->C6_ZCUBAGE	:= NoRound( IIf(_nSldQuant==SC6->C6_QTDVEN, _nSldCubag, ((SD1->D1_ZCUBAGE * _nPercRat) / 100)) , TamSx3("C6_ZCUBAGE")[2])
		SC6->(MsUnLock())

		// atualiza os itens nas notas fiscais emitidas
		dbSelectArea("SD2")
		SD2->(dbSetOrder(8)) //8-D2_FILIAL, D2_PEDIDO, D2_ITEMPV
		SD2->(dbSeek( _cSeekSD2 := SC6->(C6_FILIAL+C6_NUM+C6_ITEM) ))
		While SD2->( ! Eof() ).and.(SD2->(D2_FILIAL+D2_PEDIDO+D2_ITEMPV)==_cSeekSD2)

			// se a quantidade de devolucao for igual ao item do pedido
			If (SC6->C6_QTDVEN == SD2->D2_QUANT)
				// atualiza campos dos itens da nota
				RecLock("SD2")
				SD2->D2_ZPESOB	:= SC6->C6_ZPESOB
				SD2->D2_ZPESOL	:= SC6->C6_ZPESOL
				SD2->D2_ZCUBAGE	:= SC6->C6_ZCUBAGE
				SD2->(MsUnLock())

			Else

				// calcula rateio para os itens da nota de saida (pode ter mais em funcao de uso de lote)
				_nRatSD2 := ((SD2->D2_QUANT * 100) / SC6->C6_QTDVEN)

				// atualiza campos dos itens da nota
				RecLock("SD2")
				SD2->D2_ZPESOB	:= NoRound( IIf(_nSldSC6 == SD2->D2_QUANT, _nSldPB, ((SC6->C6_ZPESOB  * _nRatSD2) / 100)), TamSx3("D2_ZPESOB")[2]  )
				SD2->D2_ZPESOL	:= NoRound( IIf(_nSldSC6 == SD2->D2_QUANT, _nSldPL, ((SC6->C6_ZPESOL  * _nRatSD2) / 100)), TamSx3("D2_ZPESOL")[2]  )
				SD2->D2_ZCUBAGE	:= NoRound( IIf(_nSldSC6 == SD2->D2_QUANT, _nSldCB, ((SC6->C6_ZCUBAGE * _nRatSD2) / 100)), TamSx3("D2_ZCUBAGE")[2] )
				SD2->(MsUnLock())

			EndIf

			// atualiza dados das movimentacoes de poder de terceiro (entrada)
			sfAtuSB6(SD2->D2_CLIENTE, SD2->D2_LOJA, SD2->D2_COD, SD2->D2_IDENTB6, "D", SD2->D2_DOC, SD2->D2_SERIE, SD2->D2_QUANT)

			// controle de saldo por item do pedido de venda
			_nSldSC6 -= SD2->D2_QUANT
			_nSldPB  -= SD2->D2_ZPESOB
			_nSldPL  -= SD2->D2_ZPESOL
			_nSldCB  -= SD2->D2_ZCUBAGE

			// proximo item da nota
			SD2->(dbSkip())
		EndDo

		// controle do saldo da quantidade
		_nSldQuant -= SC6->C6_QTDVEN
		// controle do saldo de peso e cubagem
		_nSldLiqui -= SC6->C6_ZPESOL
		_nSldBruto -= SC6->C6_ZPESOB
		_nSldCubag -= SC6->C6_ZCUBAGE

	Next _nX

	If ( !Empty(_cNumPed) )
		// atualiza o total do pedido de venda
		_cUpdate := "UPDATE "+RetSqlName("SC5")+" SET C5_ZPESOB = "
		_cUpdate += "(SELECT ISNULL(SUM(C6_ZPESOB),0) FROM "+RetSqlName("SC6")+" (NOLOCK) WHERE "
		_cUpdate += "C6_FILIAL = C5_FILIAL AND D_E_L_E_T_ = ' ' AND C6_NUM = C5_NUM) "
		_cUpdate += "WHERE D_E_L_E_T_ = ' ' AND C5_TIPOOPE = 'P' AND C5_FILIAL = '" +xFilial("SC5")+ "' AND C5_NUM IN (" + _cNumPed +")"
		// executa UPDATE geral
		If (TcSQLExec(_cUpdate) < 0).and.( ! mvRotAuto )
			MsgStop("*** ERRO NA ATUALIZACAO DO PESO BRUTO NO SC5 ***"+chr(10)+chr(13)+chr(10)+chr(13)+TCSQLError())
		EndIf

		// atualiza o total do pedido de venda
		_cUpdate := "UPDATE "+RetSqlName("SC5")+" SET C5_ZPESOL = "
		_cUpdate += "(SELECT ISNULL(SUM(C6_ZPESOL),0) FROM "+RetSqlName("SC6")+" (NOLOCK) WHERE "
		_cUpdate += "C6_FILIAL = C5_FILIAL AND D_E_L_E_T_ = ' ' AND C6_NUM = C5_NUM) "
		_cUpdate += "WHERE D_E_L_E_T_ = ' ' AND C5_TIPOOPE = 'P' AND C5_FILIAL = '" +xFilial("SC5")+ "' AND C5_NUM IN (" + _cNumPed +")"
		// executa UPDATE geral
		If (TcSQLExec(_cUpdate) < 0).and.( ! mvRotAuto )
			MsgStop("*** ERRO NA ATUALIZACAO DO PESO LIQUIDO NO SC5 ***"+chr(10)+chr(13)+chr(10)+chr(13)+TCSQLError())
		EndIf

		// atualiza o total do pedido de venda
		_cUpdate := "UPDATE "+RetSqlName("SC5")+" SET C5_ZCUB = "
		_cUpdate += "(SELECT ISNULL(SUM(C6_ZCUBAGE),0) FROM "+RetSqlName("SC6")+" (NOLOCK)  WHERE "
		_cUpdate += "C6_FILIAL = C5_FILIAL AND D_E_L_E_T_ = ' ' AND C6_NUM = C5_NUM) "
		_cUpdate += "WHERE D_E_L_E_T_ = ' ' AND C5_TIPOOPE = 'P' AND C5_FILIAL = '" +xFilial("SC5")+ "' AND C5_NUM IN (" + _cNumPed +")"
		// executa UPDATE geral
		If (TcSQLExec(_cUpdate) < 0).and.( ! mvRotAuto )
			MsgStop("*** ERRO NA ATUALIZACAO DA CUBAGEM NO SC5 ***"+chr(10)+chr(13)+chr(10)+chr(13)+TCSQLError())
		EndIf

	EndIf
Return

// ** funcao para reabrir processo para lancamento de notas fiscais
Static Function sfReabrir(mvNumProc)
	If (Empty(mvNumProc))
		MsgStop("Processo não informado!")
		Return(.f.)
	EndIf

	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	If (!SZ1->(dbSeek( xFilial("SZ1")+mvNumProc )))
		MsgStop("Processo não encontrado!")
		Return(.f.)
	EndIf

	// valida se a programacao esta encerrada
	If ( ! Empty(SZ1->Z1_DTFINFA))
		MsgStop("Programação encontra-se encerrada. Contate o setor de Faturamento.")
		Return(.f.)
	EndIf

	If ( ! MsgYesNo("Confirma a reabertura da programação?", "Atenção") )
		Return(.f.)
	EndIf

	RecLock("SZ1")
	SZ1->Z1_DTDOC := CtoD("//")
	MsUnLock()

	// gera Log
	U_FtGeraLog(cFilAnt, "SZ1", xFilial("SZ1")+mvNumProc, "Realizado a reabertura da programação", "FIS", mvNumProc)

Return(.t.)

// ** funcao que atualiza dados das movimentacoes de poder de terceiro (entrada / saida)
Static Function sfAtuSB6(mvCodCli, mvLojCli, mvCodProd, mvIdentB6, mvRemDev, mvDoc, mvSerie, mvQuant)
	// query
	local _cQuery
	// recnos
	local _aRecnoSB6 := {}
	local _nRecnoSB6 := 0

	// monta query
	_cQuery := "SELECT SB6.R_E_C_N_O_ SB6RECNO "
	// poder de terceiros
	_cQuery += "FROM "+RetSqlName("SB6")+" SB6 (NOLOCK) "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SB6")
	// cod e loja do cliente
	_cQuery += "AND ((B6_CLIFOR  = '"+mvCodCli+"' AND B6_LOJA = '"+mvLojCli+"') OR (B6_CLIFOR = '000140')) "
	// cod produto
	_cQuery += "AND B6_PRODUTO = '"+mvCodProd+"' "
	// ident Sb6 (numseq)
	_cQuery += "AND B6_IDENT   = '"+mvIdentB6+"' "
	// controle (D-Dev ou R-Rem)
	_cQuery += "AND B6_PODER3  = '"+mvRemDev+"' "
	// doc e serie
	_cQuery += "AND B6_DOC     = '"+mvDoc+"' AND B6_SERIE = '"+mvSerie+"' "
	// quantidade
	_cQuery += "AND B6_QUANT   = "+AllTrim(Str(mvQuant))

	// atualiza dados
	_aRecnoSB6 := U_SqlToVet(_cQuery)

	// varre todos os registros
	For _nRecnoSB6 := 1 to Len(_aRecnoSB6)
		// posiciona no registro da tabela
		dbSelectArea("SB6")
		SB6->(dbGoTo(_aRecnoSB6[_nRecnoSB6]))

		RecLock("SB6")
		SB6->B6_ZCUBAGE := IIf( mvRemDev == "R", SD1->D1_ZCUBAGE, SD2->D2_ZCUBAGE)
		SB6->B6_ZPESOB  := IIf( mvRemDev == "R", SD1->D1_ZPESOB , SD2->D2_ZPESOB )
		SB6->B6_ZPESOL  := IIf( mvRemDev == "R", SD1->D1_ZPESOL , SD2->D2_ZPESOL )
		SB6->(MsUnLock())

	Next _nRecnoSB6

Return

// -- funcao que permite a definicao da data de inicio de cobranca de Az ou Seguro
Static Function sfDefDtCobr()
	// opcao
	local _nOpcSel := Aviso("TWMSV004 -> sfDefDtCobr","Qual data será definida?"+CRLF+CRLF+"Nota: "+(_TRBNFE)->F1_DOC+"/"+(_TRBNFE)->F1_SERIE,{"Fechar","Seguro","Armazenagem"})
	// data atual
	local _dDataAtu := CtoD("//")
	// nova data
	local _dNovaData := CtoD("//")
	// justificativa
	local _cJustific := Space(100)

	// objetos da tela
	local _oDlgDefData
	local _oSayDtAual, _oSayNovaData, _oSayJustific
	local _oGetNovaData, _oGetJustific
	local _oBtnConf, _oBtnCanc

	// controle de confirmacao
	local _lOk := .f.

	// tipo de cobranca
	local _cTpCobranca := ""

	// se for cancelado
	If (_nOpcSel <= 1)
		Return(.f.)
	EndIf

	// posiciona na nota de entrada
	dbSelectArea("SF1")
	SF1->(dbSetOrder(1)) //1-F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_FORMUL
	If SF1->(dbSeek( xFilial("SF1")+(_TRBNFE)->(F1_DOC+F1_SERIE)+_cCodCli+_cLojCli ))

		// extrai a data atual
		If (_nOpcSel == 2)
			// seguro
			_dDataAtu := SF1->F1_DTFATSE
			// tipo de cobranca
			_cTpCobranca := "Seguro"

		ElseIf (_nOpcSel == 3)
			// Armazenagem
			_dDataAtu := SF1->F1_DTFATPR
			// tipo de cobranca
			_cTpCobranca := "Armazenagem"

		EndIf


		// monta a tela para definir a nova data de cobranca
		_oDlgDefData := MSDialog():New(000,000,160,320,"Data de Cobrança",,,.F.,,,,,,.T.,,,.T. )

		// data atual
		_oSayDtAual := TSay():New(005,010,{||"Data Atual de "+_cTpCobranca+": "+DtoC(_dDataAtu) },_oDlgDefData,,_oFnt01,.F.,.F.,.F.,.T.)

		// nova data
		_oSayNovaData := TSay():New(020,010,{||"Nova Data:"},_oDlgDefData,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGetNovaData := TGet():New(019,055,{|u| If(PCount()>0,_dNovaData:=u,_dNovaData)},_oDlgDefData,060,010,Nil,,,,_oFnt01,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_dNovaData",,)

		// justificativa
		_oSayJustific := TSay():New(035,010,{||"Justificativa:"},_oDlgDefData,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGetJustific := TGet():New(045,010,{|u| If(PCount()>0,_cJustific:=u,_cJustific)},_oDlgDefData,140,010,Nil,,,,_oFnt01,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cJustific",,)

		// botao para confirmar
		_oBtnConf := TButton():New(062,040,"Confirmar",_oDlgDefData,{|| _lOk := .t.,_oDlgDefData:End() },050,012,,,,.T.,,"",,,,.F. )
		// botao para fechar
		_oBtnCanc := TButton():New(062,100,"Fechar",_oDlgDefData,{|| _oDlgDefData:End() },050,012,,,,.T.,,"",,,,.F. )

		// ativacao da tela com validacao
		_oDlgDefData:Activate(,,,.T.,)

		// valida dados
		If (_lOk)
			If ( ! Empty(_dNovaData)).and.(Len(AllTrim(_cJustific)) > 10)
				If MsgYesNo("Confirma a alteração da data de "+DtoC(_dDataAtu)+" para "+DtoC(_dNovaData)+" ?", "Atenção")

					// atualiza os dados da nota
					dbSelectArea("SF1")
					RecLock("SF1")
					If (_nOpcSel == 2) // seguro
						SF1->F1_DTFATSE := _dNovaData
					ElseIf (_nOpcSel == 3) // Armazenagem
						SF1->F1_DTFATPR := _dNovaData
					EndIf
					SF1->(MsUnLock())

					// gera log
					U_FtGeraLog(cFilAnt, "SF1", SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO),"Definido manualmente data de cobrança de "+_cTpCobranca+". De "+DtoC(_dDataAtu)+" para "+DtoC(_dNovaData)+". Justificativa: "+AllTrim(_cJustific), "FAT", _cNumProg)

					MsgInfo("Alteração Realizada com Sucesso!")
				EndIf
			Else
				MsgStop("Informações NÃO foram alteradas.")
			EndIf
		EndIf

	EndIf

Return

// ** funcao para reprocessamento em massa de todas as programacoes com peso bruto incorreto
User Function WMSV004A
	local _cQuery
	local _aProgram
	local _nProgram

	_cQuery := " SELECT * "
	_cQuery += " FROM   (SELECT D1_PROGRAM, "
	_cQuery += "                D1_IDENTB6, "
	_cQuery += "                D1_QUANT, "
	_cQuery += "                ROUND(D1_ZPESOB, 3)          D1_ZPESOB, "
	_cQuery += "                (SELECT ROUND(ISNULL(SUM(D2_ZPESOB), 0), 3) "
	_cQuery += "                 FROM   " + RetSqlTab("SD2") + " (NOLOCK) "
	_cQuery += "                 WHERE  " + RetSqlCond("SD2")
	_cQuery += "                        AND D2_IDENTB6 = D1_IDENTB6) QTD_SAIDA "
	_cQuery += "         FROM   " + RetSqlTab("SD1") + " (NOLOCK) "
	_cQuery += "         WHERE  " + RetSqlCond("SD1") 
	_cQuery += "                AND D1_IDENTB6 != ' ') ANALISE_MOV_NEGATIVA "
	_cQuery += " WHERE  QTD_SAIDA > D1_ZPESOB "

	_aProgram := U_SqlToVet(_cQuery)

	For _nProgram := 1 to Len(_aProgram)
		sfRateio(_aProgram[_nProgram][1], .t.)
	Next _nProgram

Return

Static Function sfCorrNF()
	local _oFntRoda := TFont():New("Tahoma",,16,,.t.)
	local _nPesoBrt := (_TRBNFE)->F1_PBRUTO
	local _nPesoLiq := (_TRBNFE)->F1_PLIQUI
	local _nCubagem := (_TRBNFE)->F1_CUBAGEM
	Private _oDlgInfVlr
	// monta a tela para alterar o peso liquido, peso bruto e cubagem
	_oDlgInfVlr := MSDialog():New(000,000,160,240,"Corrigir dados da NF",,,.F.,,,,,,.T.,,,.T. )
	_oSayCuba := TSay():New(011,010,{||"Peso Bruto:"},_oDlgInfVlr,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetCuba := TGet():New(009,050,{|u| If(PCount()>0,_nPesoBrt:=u,_nPesoBrt)},_oDlgInfVlr,060,010,PesqPict("SF1","F1_PBRUTO"),,,,_oFntRoda,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nPesoBrt",,)

	_oSayCuba := TSay():New(030,010,{||"Peso Liq.:"},_oDlgInfVlr,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetCuba := TGet():New(028,050,{|u| If(PCount()>0,_nPesoLiq:=u,_nPesoLiq)},_oDlgInfVlr,060,010,PesqPict("SF1","F1_PLIQUI"),,,,_oFntRoda,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nPesoLiq",,)

	_oSayCuba := TSay():New(045,010,{||"Cubagem:"},_oDlgInfVlr,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetCuba := TGet():New(043,050,{|u| If(PCount()>0,_nCubagem:=u,_nCubagem)},_oDlgInfVlr,060,010,PesqPict("SF1","F1_CUBAGEM"),,,,_oFntRoda,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nCubagem",,)

	// botao para confirmar
	_oBtnConfirmar := TButton():New(060,040,"Confirmar",_oDlgInfVlr,{||sfGrvCorNF(_nPesoBrt,_nPesoLiq,_nCubagem)},050,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgInfVlr:Activate(,,,.T.,)

Return

Static Function sfGrvCorNF(_nPesoBrt,_nPesoLiq,_nCubagem)
	Local lOK := .T.

	If lOK .And. _nPesoBrt == 0 .Or. _nPesoLiq == 0 .Or. _nCubagem == 0
		MsgAlert("Não podem haver valores zerados para a correção de NF!")
		lOK := .F.
	EndIf

	If lOK .And. _nPesoBrt < _nPesoLiq
		MsgAlert("O Peso Bruto não pode ser menor que o Peso Líquido!")
		lOK := .F.
	EndIf

	If lOK
		dbSelectArea("SF1")
		SF1->(dbSetOrder(1)) //1-F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_FORMUL
		If SF1->(dbSeek( xFilial("SF1")+(_TRBNFE)->(F1_DOC+F1_SERIE)+_cCodCli+_cLojCli ))
			RecLock("SF1",.F.)
			SF1->F1_PBRUTO	:= _nPesoBrt
			SF1->F1_PLIQUI	:= _nPesoLiq
			SF1->F1_CUBAGEM	:= _nCubagem
			SF1->(MsUnLock())
		EndIf

		// chama a função de recálculo de cubagem
		MsgRun("Por Favor Aguarde...Executando recálculo de cubagem!", "Processando...",{|| sfRateio(_cNumProg,.T.)})

		// atualiza a tela
		sfVldNumProg(.f.)

		// Fecha a tela
		_oDlgInfVlr:End()
	EndIf

Return