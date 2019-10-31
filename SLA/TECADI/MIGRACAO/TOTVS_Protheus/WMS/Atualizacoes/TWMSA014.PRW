#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para inventario inicial                          !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 10/2012 !
+------------------+--------------------------------------------------------*/

User Function TWMSA014(mvQryUsr)
	// variavel de retorno
	local _lRet := .f.

	// valida se ha equipamento informado
	If ( ! Empty(_cCodEquip) )
		U_FtWmsMsg("No processo de inventário não é necessário equipamento!","ATENCAO")
		Return(.f.)
	EndIf

	// inclui o codigo do servico de inventario
	mvQryUsr += " AND Z06_SERVIC = 'T02' AND Z06_TAREFA = 'T02' "

	// chama funcao para visualizar o resumo da OS
	If ( _lRet := U_ACDA002C(mvQryUsr,"EX",.t.,.t.,.f.,.f.) )

		// rotina generica de invetario
		U_WMSA014A(Z06->Z06_SERVIC, Z06->Z06_TAREFA, Z06->Z06_STATUS, ;
		Z06->Z06_NUMOS, Z06->Z06_SEQOS, ;
		Z05->Z05_CLIENT, Z05->Z05_LOJA, ;
		Z06->Z06_PRIOR)

	EndIf

Return(_lRet)

// ** funcao principal de inventario
User Function WMSA014A(mvCodServ, mvCodTaref, mvStatus, mvNumOS, mvSeqOS, mvCodCli, mvLojCli, mvPriori)

	// controle de while
	local _lRetOk := .t.

	// observação da OS
	local _cObservOS := ""

	// valida identificacao do produto
	local _cTpIdEtiq := U_FtWmsParam("WMS_PRODUTO_ETIQ_IDENT","C","INTERNA",.f.,"", mvCodCli, mvLojCli, "", mvNumOS)

	// objetos da tela
	local _oFldInvent
	local _oBtnPesq
	local _oBmpInvNvVolume
	local _oSayEtqVolume, _oSayTamCaixa
	local _oGetEtqVolume, _oGetEndereco
	local _oPnlInventCab
	local _oCmbTamCaixa

	// sub-menu
	local _oMnuOpcoes := nil
	local _oSbMnOp01 := nil
	local _oSbMnOp02 := nil
	local _oSbMnOp03 := nil
	local _oSbMnOp04 := nil
	local _oSbMnOp05 := nil
	local _oSbMnOp06 := nil
	local _oSbMnOp07 := nil
	local _oSbMnOp08 := nil

	// botoes
	local _oBmpOpcoes

	// pastas do FOLDER
	local _aFolders := {'Inventário','Dados'}

	// variaveis recebidas de parametro
	private _cCodStatus := mvStatus
	private _cNumOrdSrv := mvNumOS
	private _cSeqOrdSrv := mvSeqOS
	private _cCodCliFor := mvCodCli
	private _cLojCliFor := mvLojCli

	// informacoes do produto
	private nTamCodPrd := TamSx3("B1_COD")[1]
	private _cCodProd  := Space(nTamCodPrd)
	private _cNumSeq   := ""

	// Id do palete
	private _nTamIdPal := TamSx3("Z11_CODETI")[1]
	private _cIdPalete := Space(_nTamIdPal)
	private _cMskEtiq  := PesqPict("Z11","Z11_CODETI")
	private _cCodUnit  := CriaVar("DC1_CODUNI",.f.)
	private _cEtqEnder := Space(_nTamIdPal)
	//Tamanho da caixa.
	private _cTamCaixa  := CriaVar("Z31_CODIGO",.f.)
	private _aOpcoesTcx := {}

	private _cArmazem  := CriaVar("B7_LOCAL",.f.)
	private _cEndereco := CriaVar("B7_LOCALIZ",.f.)

	// define novo endereco
	private _lNovoEnder := .t.

	// variaveis do browse
	private _oBrwConfInvent
	private _aHeadConf := {}
	private _aColsConf := {}
	private _nPosCmpEnd := 0
	private _nPosCmpVol := 0
	private _nPosEtqPrd := 0
	private _nPosLote   := 0
	private _nPosEtqCli := 0

	// informacoes do produto
	private _cEtiqProd  := CriaVar("Z11_CODETI",.f.)
	private _nQtdProd   := 1
	private _nQtdSegUM  := 0
	private _cEtqCodBar := ""

	// tipo de identificacao
	private _lEtqIdInt  := (AllTrim(_cTpIdEtiq) == "INTERNA")
	private _lEtqIdEAN  := (AllTrim(_cTpIdEtiq) == "EAN") .Or. (AllTrim(_cTpIdEtiq) == "EAN13")
	private _lEtqIdDUN  := (AllTrim(_cTpIdEtiq) == "DUN14")
	private _lEtqCod128 := (AllTrim(_cTpIdEtiq) == "CODE128")
	private _lEtqClient := (AllTrim(_cTpIdEtiq) == "CLIENTE")

	// controle de mercadoria por volume
	private _lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.f.,.f.,"", _cCodCliFor, _cLojCliFor, "", _cNumOrdSrv)
	// controle de validade de lotes
	private _lCtrVld    := U_FtWmsParam("WMS_CONTROLE_DATA_VALIDADE","L",.f.,.f.,"", _cCodCliFor, _cLojCliFor, "", _cNumOrdSrv)
	// ativa a repeticao de lotes
	private _lRptLot    := U_FtWmsParam("WMS_REPETE_LOTE_NA_CONFERENCIA","L",.f.,.f.,"", _cCodCliFor, _cLojCliFor, "", _cNumOrdSrv)

	// Id etiqueta do volume
	private _cEtqVolume := Space(_nTamIdPal)

	// controle de apontamento de volume
	private _lNovoVolume := .t.

	// numero da contagem
	private _cNrCont := Z06->Z06_NRCONT

	// parametro para ativar a validacao de lastro e camada
	private _lVldLastro := U_FtWmsParam("WMS_INVENTARIO_VALIDA_LASTRO","L",.f.,.f.,"", _cCodCliFor, _cLojCliFor, "", _cNumOrdSrv)

	// mascara para campos quantidade
	private _cMaskQuant := U_FtWmsParam("WMS_MASCARA_CAMPO_QUANTIDADE", "C", PesqPict("SD1","D1_QUANT"), .f., "", _cCodCliFor, _cLojCliFor, "", _cNumOrdSrv)

	// mascara para codigo de barras
	private _cMskCodBar := PesqPict("SB1","B1_CODBAR")

	// parametro para validação do controle de lote
	private _lCtrLote   := .F.
	private _cEtqLote   := CriaVar("B8_LOTECTL",.f.)
	private _cPltClie   := CriaVar("Z07_PLTCLI",.f.)
	private _dVldLote   := CtoD("//")

	// variavel de controle
	private _lInfManual := .T.

	// mascara do campo endereco
	private _cMaskEnd := ""

	// tipo de estoque
	private _aOpcoesEst     := sfRetTpEstoque()
	private _cTpEstoque     := SubStr(_aOpcoesEst[1],1,At("=",_aOpcoesEst[1])-1)
	// tipo de estoque apresentado na tela
	private _cDescTpEstoque := _aOpcoesEst[1]
	private _oSayCodEst

	// endereco de servico
	private _cEndServ := Z06->Z06_ENDSRV

	// endereco de destino
	private _cIdEndDest := Space(_nTamIdPal)
	private _cEndDesti  := CriaVar("BE_LOCALIZ", .f.)

	// controle de inventario para ler etiqueta de produto/volueme e depois endereco
	private _lInvPadrao := (AllTrim(_cEndServ)=="ZZZ")

	// verifica se o controle de lote esta ativo
	Private _lLotAtivo := U_FtWmsParam("WMS_CONTROLE_POR_LOTE","L",.F.,.F.,Nil, _cCodCliFor, _cLojCliFor, "", _cNumOrdSrv)

	//parâmetro que informa se o inventário do cliente é para subida/carga de saldo/produtos
//	Private _lInvIni := ( _cCodCliFor $ SuperGetMv("TC_INVINI", /* .T. */ ,"")  )

	// define quantidade de caracteres da etiqueta do cliente
	private _nTamEtqCli := U_FtWmsParam("WMS_QUANT_CARACTERES_ETIQUETA_CLIENTE", "N", TamSx3("Z56_ETQCLI")[1], .F., "", mvCodCli, mvLojCli, "", Nil)

	// prepara tamanho do codigo de barras
	If (_lEtqIdEAN)
		_cEtqCodBar := Space(13)
		_cMskCodBar := "@R " + Replicate("9", Len(_cEtqCodBar))
	ElseIf (_lEtqCod128)
		_cEtqCodBar := CriaVar("B1_CODBAR", .f.)
		_cMskCodBar := "@!"
	ElseIf (_lEtqIdDUN)
		_cEtqCodBar := Space(14)
		_cMskCodBar := "@R " + Replicate("9", Len(_cEtqCodBar))
	ElseIf (_lEtqClient)
		_cEtqCodBar := Space(_nTamEtqCli)
		_cMskCodBar := "@!"
	EndIf

	// define mensagem no monitor
	U_FtMsgMon()

	// se não controlar validade, já trás o campo preenchido
	If ( ! _lCtrVld )

		// define a data como data atual
		_dVldLote := CtoD("31/12/2049")

	EndIf

	// busca observação da OS
	_cObservOS := sfMostraObs()

	// rotina para visualização da OBS da OS
	If ( ! Empty(_cObservOS) )
		U_FtWmsMsg(_cObservOS,"Observação")
	Else
		U_FtWmsMsg("Nenhuma observação para essa OS","Atenção")
	EndIf

	// seleciona os tipos de estoque disponíveis para conferência
	If (_lCtrVolume)
		_aOpcoesTcx := sfRetTamCx(_cCodCliFor, _cLojCliFor)
	EndIf

	// se nao for inventario padrao, busca etiqueta do endereco de servico
	If ( ! _lInvPadrao )
		_cArmazem   := Z06->Z06_LOCAL
		_cEndereco  := _cEndServ
		_cEtqEnder  := Posicione("SBE", 1, xFilial("SBE")+ Z06->Z06_LOCAL + _cEndServ , "BE_ZIDETIQ")
		_lNovoEnder := .f.
	EndIf

	// leitura do endereco
	While (_lRetOk)

		// reinicia variaveis
		_cCodProd   := Space(Len(_cCodProd))
		_cEtiqProd  := Space(Len(_cEtiqProd))
		_cCodUnit   := Space(Len(_cCodUnit))
		_cIdPalete  := Space(Len(_cIdPalete))
		If (_lInvPadrao)
			_cEtqEnder  := Space(Len(_cEtqEnder))
			_cArmazem   := Space(Len(_cArmazem))
			_cEndereco  := Space(Len(_cEndereco))
		EndIf
		_nQtdProd   := 1
		_nQtdSegUM  := 0
		_cEtqCodBar := Space(Len(_cEtqCodBar))
		_cEtqVolume := Space(Len(_cEtqVolume))

		// atualiza os dados
		sfSelDados()

		// monta o dialogo do inventário
		_oWndInventario := MSDialog():New(000,000,(_aSizeDlg[2]),(_aSizeDlg[1]),"Inventário",,,.F.,,,,,,.T.,,,.T. )
		_oWndInventario:lEscClose := .F.

		// cria o panel do cabecalho - botoes de operacao
		_oPnlInventCab := TPanel():New(000,000,nil,_oWndInventario,,.F.,.F.,,,22,22,.T.,.F.)
		_oPnlInventCab:Align:= CONTROL_ALIGN_TOP

		// cria o panel do Rodapé Legendas
		_oPnlRod := TPanel():New(000,000,"F7|F8",_oWndInventario,,.F.,.F.,,,00,10,.T.,.F.)
		_oPnlRod:Align:= CONTROL_ALIGN_BOTTOM


		// OPCOES DE OPERACOES

		// -- NOVO ENDERECO
		_oBmpInvNvEnd := TBtnBmp2():New(000,000,060,022,"ARMIMG32",,,,{|| sfNovoEndereco(.T., @_oGetEtqVolume, .F.) },_oPnlInventCab,"Novo Palete(F7)",,.T.)
		_oBmpInvNvEnd:Align := CONTROL_ALIGN_LEFT
		// define teclas de atalho
		SetKey(VK_F7,{|| sfNovoEndereco(.T., @_oGetEtqVolume, .F.) } )

		// -- NOVO VOLUME
		If (_lCtrVolume) .And. ( ! _lEtqClient )
			_oBmpInvNvVolume := TBtnBmp2():New(000,000,060,022,"AVGARMAZEM",,,,{|| sfNovoVolume(@_oGetEtqVolume) },_oPnlInventCab,"Novo Volume(F8)",,.T.)
			_oBmpInvNvVolume:Align := CONTROL_ALIGN_LEFT
			// define teclas de atalho
			SetKey(VK_F8,{|| sfNovoVolume(@_oGetEtqVolume) } )
		EndIf

		// -- ENDEREÇO VAZIO
		If (_lInvPadrao)
			_oBmpInvEndVz := TBtnBmp2():New(000,000,060,022,"COLTOT",,,,{|| sfGravaEndVz(@_oGetEtqVolume) },_oPnlInventCab,"Endereço Vazio",,.T.)
			_oBmpInvEndVz:Align := CONTROL_ALIGN_LEFT
		EndIf

		// sub-itens do menus
		_oMnuOpcoes := TMenu():New(0,0,0,0,.T.)
		// adiciona itens no Menu

		// -- CONSULTAR DETALHES DO INVENTARIO
		_oSbMnOp01 := TMenuItem():New(_oMnuOpcoes,"Cons. Detalhe Inventário",,,,{|| MsgRun("Aguarde...",,{|| sfDetInventario() }) },,"NOTE",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOp01)

		// -- CONSULTAR DETALHES DO INVENTARIO NO ENDERECO
		_oSbMnOp02 := TMenuItem():New(_oMnuOpcoes,"Cons. Detalhe Endereço",,,,{|| MsgRun("Aguarde...",,{|| sfDetEndereco() }) },,"NOTE",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOp02)

		// -- FINALIZAR OS
		_oSbMnOp03 := TMenuItem():New(_oMnuOpcoes,"Finalizar OS",,,,{|| sfFinalizaOS(@_oWndInventario) },,"CHECKED",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOp03)

		// -- ESTORNO DE TODO O ENDERECO
		_oSbMnOp04 := TMenuItem():New(_oMnuOpcoes,"Estorna Endereço",,,,{|| sfEstornaLei(@_oGetEtqVolume, _cEndereco, "TOT", Nil) },,"ESTOMOVI",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOp04)

		// -- ESTORNO DO VOLUME
		If (_lCtrVolume)
			If ( ! _lEtqClient )
				_oSbMnOp05 := TMenuItem():New(_oMnuOpcoes,"Estorna Volume",,,,{|| sfEstornaLei(@_oGetEtqVolume, _cEndereco, "VOL", _oBrwConfInvent:aCols[_oBrwConfInvent:nAt][_nPosCmpVol] ) },,"ESTOMOVI",,,,,,,.T.)
			ElseIf ( _lEtqClient )
				_oSbMnOp05 := TMenuItem():New(_oMnuOpcoes,"Estorna Etq Cliente",,,,{|| sfEstornaLei(@_oGetEtqVolume, _cEndereco, "CLI", _oBrwConfInvent:aCols[_oBrwConfInvent:nAt][_nPosEtqCli] ) },,"ESTOMOVI",,,,,,,.T.)
			EndIf
			_oMnuOpcoes:Add(_oSbMnOp05)
		EndIf

		// -- ESTORNO DE ETIQUETA
		If (_lEtqIdInt)
			_oSbMnOp06 := TMenuItem():New(_oMnuOpcoes,"Estorna Etiqueta",,,,{|| sfEstornaLei(@_oGetEtqVolume, _cEndereco, "PRO", _oBrwConfInvent:aCols[_oBrwConfInvent:nAt][_nPosEtqPrd] ) },,"ESTOMOVI",,,,,,,.T.)
			_oMnuOpcoes:Add(_oSbMnOp06)
		EndIf

		// - ALTERA TIPO DE ESTOQUE
		_oSbMnOp07 := TMenuItem():New(_oMnuOpcoes,"Def. Tipo Estoque",,,,{|| sfAltTpEst() },,"FRTIMG32",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOp07)

		// BOTAO SAIR
		_oSbMnOp08 := TMenuItem():New(_oMnuOpcoes,"Sair",,,,{|| IIf(U_FtYesNoMsg("Deseja Sair?","ATENÇÃO"), _oWndInventario:END(),Nil) },,"FINAL",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOp08)

		// -- BOTAO COM MAIS OPCOES
		_oBmpOpcoes := TBtnBmp2():New(000,000,060,022,"SDUAPPEND",,,,{|| Nil },_oPnlInventCab,"",,.T.)
		_oBmpOpcoes:Align := CONTROL_ALIGN_RIGHT
		_oBmpOpcoes:SetPopupMenu(_oMnuOpcoes)

		// pastas com as opcoes de visualizacao
		_oFldInvent := TFolder():New(000,000,_aFolders,,_oWndInventario,,,,.T.,,200,200)
		_oFldInvent:Align:= CONTROL_ALIGN_ALLCLIENT

		// -- PRIMEIRA PASTA --

		// controle por endereco
		_oSayIdEndere := TSay():New(005,003,{||"Id Endereço"},_oFldInvent:aDialogs[1],,,.F.,.F.,.F.,.T.)
		_oGetIdEndere := TGet():New(003,034,{|u| If(PCount()>0,_cEtqEnder:=u,_cEtqEnder)},_oFldInvent:aDialogs[1],048,008,_cMskEtiq,{|| sfVldEndere(@_oGetEtqVolume, @_oGetIdEndere, @_oGetIdProdut, @_oCmbTamCaixa, @_oGetEndereco) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtqEnder",,)
		_oGetIdEndere:lReadOnly := ( ( ! _lNovoEnder ) .And. (_lInvPadrao) )
		_oGetIdEndere:bWhen := {|| _lInvPadrao }

		// endereço
		_oGetEndereco := TGet():New(015,003,{|u| If(PCount()>0,_cEndereco:=u,_cEndereco)},_oFldInvent:aDialogs[1],078,008,_cMaskEnd,{|| Nil },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEndereco",,)
		_oGetEndereco:bWhen := {|| .f. }

		// controle por palete
		_oSayNrPalete := TSay():New(029,003,{||"Id Palete"},_oFldInvent:aDialogs[1],,,.F.,.F.,.F.,.T.)
		_oGetNrPalete := TGet():New(027,034,{|u| If(PCount()>0,_cIdPalete:=u,_cIdPalete)},_oFldInvent:aDialogs[1],048,008,_cMskEtiq,{|| sfVldPalete() },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIdPalete",,)
		_oGetNrPalete:bWhen := {|| .F. }

		// informacoes tamanho da caixa
		_oSayTamCaixa := TSay():New(041,003,{||"Tam. Caixa"},_oFldInvent:aDialogs[1],,,.F.,.F.,.F.,.T.)
		_oCmbTamCaixa := TComboBox():New(039,034,{|u| If(PCount()>0,_cTamCaixa:=u,_cTamCaixa)},_aOpcoesTcx,080,008,_oFldInvent:aDialogs[1],,,,,,.T.,,"",,,,,,,_cTamCaixa)
		_oCmbTamCaixa:bWhen := {|| (_lCtrVolume) .And. (Len(_aOpcoesTcx) != 0)}
		_oCmbTamCaixa:lReadOnly := (( ! _lCtrVolume ) .And. ( ! _lNovoVolume ) .And. (Len(_aOpcoesTcx) != 0))

		// informacoes do id de volume
		_oSayEtqVolume := TSay():New(053,003,{||"Id Volume"},_oFldInvent:aDialogs[1],,,.F.,.F.,.F.,.T.)
		_oGetEtqVolume := TGet():New(051,034,{|u| If(PCount()>0,_cEtqVolume:=u,_cEtqVolume)},_oFldInvent:aDialogs[1],048,008,_cMskEtiq,{|| Vazio().Or.sfVldVolume(@_oGetEtqVolume, @_oGetIdProdut) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtqVolume",,)
		_oGetEtqVolume:bWhen := {|| (_lCtrVolume) .And. ( ! _lEtqClient ) }
		_oGetEtqVolume:lReadOnly := ( ( ! _lCtrVolume ) .And. ( ! _lNovoVolume ) )

		// codigo do produto
		If (_lEtqIdInt) // etiqueta interna
			_oSayIdProdut := TSay():New(065,003,{||"Etiq. Produto"},_oFldInvent:aDialogs[1],,,.F.,.F.,.F.,.T.)
			_oGetIdProdut := TGet():New(063,034,{|u| If(PCount()>0,_cEtiqProd:=u,_cEtiqProd)},_oFldInvent:aDialogs[1],048,008,_cMskEtiq,{|| (Vazio()) .Or. (sfVldProd(_cTpIdEtiq)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtiqProd",,)
			_oGetIdProdut:lReadOnly := (_lNovoEnder)
		ElseIf (_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIDDun) .Or. (_lEtqClient) // ean 13 / code128 / DUN14 / Etiq Cliente
			_oSayIdProdut := TSay():New(065,003,{||"Etiq. Produto"},_oFldInvent:aDialogs[1],,,.F.,.F.,.F.,.T.)
			_oGetIdProdut := TGet():New(063,034,{|u| If(PCount()>0,_cEtqCodBar:=u,_cEtqCodBar)},_oFldInvent:aDialogs[1],065,008, _cMskCodBar,{|| (Vazio()) .Or. (sfVldProd(_cTpIdEtiq)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtqCodBar",,)
			_oGetIdProdut:lReadOnly := (_lNovoEnder)
		EndIf

		// botao que executa a pesquisa por codigo de produto
		_oBtnPesq := TBtnBmp2():New(125,210,020,020,"VERNOTA",,,,{|| sfGetCodProd() },_oFldInvent:aDialogs[1],"Ver Cod Produto",,.F.)

		// opcoes de estoque a opção para alterar está no submenu
		_oSayCodEst := TSay():New(077,003,{ || "Tp.Estoque: " + _cDescTpEstoque},_oFldInvent:aDialogs[1],,,.F.,.F.,.F.,.T.)

		// -- SEGUNDA PASTA --

		// browse com a listagem dos produtos conferidos no endereco
		_oBrwConfInvent := MsNewGetDados():New(000,000,400,400,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsConf),'AllwaysTrue()','','AllwaysTrue()',_oFldInvent:aDialogs[2],_aHeadConf,_aColsConf)
		_oBrwConfInvent:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// ativa a tela, com foco no ID endereco
		_oWndInventario:Activate(,,,.F.,{|| .t. },,{|| _oGetIdEndere:SetFocus() })

		// ao fechar a tela, encerra o loop
		_lRetOk := .f.

	EndDo

	// zera teclas de atalho
	SetKey(VK_F7,{|| Nil})
	SetKey(VK_F8,{|| Nil})

return (.T.)


// ** funcao para filtrar os itens já conferidos
Static Function sfSelDados()
	// campos para o select
	local _cQryZ19 := ""

	// reinicia variaveis dos itens
	_aColsConf := {}

	// fecha alias
	If (Select("QRYCNF") != 0)
		dbSelectArea("QRYCNF")
		dbCloseArea()
	EndIf

	// abre tebela de conferencia
	dbSelectArea("Z19")

	// monta a query
	_cQryZ19 := " SELECT Z19_ENDERE IT_END, "
	_cQryZ19 += " CASE WHEN Z19_CODPRO = '' THEN 'VAZIO' ELSE Z19_CODPRO END Z19_CODPRO, "
	_cQryZ19 += " ISNULL(SUM(Z19_QUANT),0) IT_QUANT, "
	// etiqueta do produto
	_cQryZ19 += " Z19_ETQPRO, "
	// etiqueta do volume
	_cQryZ19 += " Z19_ETQVOL, "
	_cQryZ19 += " Z19_LOTCTL, "
	_cQryZ19 += " Z19_ETQCLI, "
	// controle de deletado
	_cQryZ19 += " '.F.' AS IT_DEL "
	// itens inventariados
	_cQryZ19 += " FROM " + RetSqlTab("Z19")
	// filtro padrao
	_cQryZ19 += " WHERE " + RetSqlCond("Z19")
	// numero da OS
	_cQryZ19 += " AND Z19_IDENT = '"+_cNumOrdSrv+"' "
	// endereco
	_cQryZ19 += " AND Z19_ENDERE = '"+_cEndereco+"' "
	// numero da contagem
	_cQryZ19 += " AND Z19_CONTAG = '"+ _cNrCont +"' "
	// filtra somente dados do usuario logado
	If ( ! _lInvPadrao )
		_cQryZ19 += " AND Z19_USER = '" + __cUserId + "' "
	EndIf
	// agrupa dados
	_cQryZ19 += "GROUP BY Z19_ENDERE, Z19_CODPRO, Z19_ETQPRO, Z19_LOTCTL, Z19_ETQCLI, Z19_ETQVOL "

	memowrit("c:\query\twmsa014_sfSelDados.txt",_cQryZ19)

	// atualiza os dados do vetor
	_aColsConf := U_SqlToVet(_cQryZ19)

	// define header
	If (Len(_aHeadConf)==0)

		aAdd(_aHeadConf,{"Endereço"  , "IT_END"    , "", TamSx3("BE_LOCALIZ")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
		_nPosCmpEnd := Len(_aHeadConf)
		aAdd(_aHeadConf,{"Produto"   , "Z19_CODPRO", ""                          , TamSx3("B1_COD")[1]    ,0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Quant"     , "IT_QUANT"  , _cMaskQuant                 , TamSx3("D1_QUANT")[1]  ,TamSx3("D1_QUANT")[1],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Id Produto", "Z19_ETQPRO", PesqPict("Z19","Z19_ETQPRO"), TamSx3("Z19_ETQPRO")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
		_nPosEtqPrd := Len(_aHeadConf)

		aAdd(_aHeadConf,{"Id Volume" ,"Z19_ETQVOL" ,PesqPict("Z19","Z19_ETQVOL"), TamSx3("Z19_ETQVOL")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
		_nPosCmpVol := Len(_aHeadConf)

		aAdd(_aHeadConf,{"Lote"      ,"Z19_LOTCTL" ,PesqPict("Z19","Z19_LOTCTL"), TamSx3("Z19_LOTCTL")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
		_nPosLote := Len(_aHeadConf)

		aAdd(_aHeadConf,{"Etq Cliente" ,"Z19_ETQCLI" ,PesqPict("Z19","Z19_ETQCLI"), TamSx3("Z19_ETQCLI")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
		_nPosEtqCli := Len(_aHeadConf)

	EndIf

	// se nao tem endereco, reinicia variavel
	If (Empty(_cEndereco))
		_aColsConf := {{"", "", 0, "", "", "", "", .F.}}
	EndIf

	// atualiza os itens do browse
	If (_oBrwConfInvent <> nil)
		_oBrwConfInvent:aCols := aClone(_aColsConf)
		_oBrwConfInvent:Refresh( .T. )
	EndIf

Return(.t.)

// ** funcao para validacao do id do pallet
Static Function sfVldPalete()
	// variavel de retorno
	local _lRet := .t.

	If (Empty(_cIdPalete))
		Return(_lRet)
	EndIf

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11") + _cIdPalete ))
			U_FtWmsMsg("Identificador do pallet inválido!","ATENCAO")
			_lRet := .f.
		EndIf
	EndIf

	// valida o tipo da etiqueta lida
	If (_lRet)
		If (Z11->Z11_TIPO != "03")
			U_FtWmsMsg("Tipo de etiqueta inválida!","ATENCAO")
			_lRet := .f.
		EndIf
	EndIf

	// define o codigo do unitizador
	If (_lRet)
		_cCodUnit := Z11->Z11_UNITIZ
	EndIf

	// foco no ID produto
	If (_lRet)
		_oGetIdProdut:SetFocus()
	EndIf

Return(_lRet)

// ** funcao para gerar novo endereco de inventario
Static Function sfNovoEndereco(mvSolConf, mvGetEtqVolume, mvEstorno)
	// variavel de retorno
	local _lRet := .t.

	// valida se o endereco foi informado
	If (_lRet) .And. (Empty(_cEtqEnder) .Or. Empty(_cEndereco))
		U_FtWmsMsg("É necessário informar a localização!","ATENCAO")
		_lRet := .f.
	EndIf

	// solicita confirmacao
	If (mvSolConf) .And. (_lRet) .And. ( ! U_FtYesNoMsg("Confirma novo endereço ?", "Novo Endereço"))
		// variavel de controle
		_lRet := .f.
		// retorno
		Return(_lRet)
	EndIf

	// reinicia variaveis
	If (_lRet)
		_cCodProd   := Space(Len(_cCodProd))
		_cEtiqProd  := Space(Len(_cEtiqProd))
		_cCodUnit   := Space(Len(_cCodUnit))
		_cIdPalete  := Space(Len(_cIdPalete))
		If (_lInvPadrao)
			_cEtqEnder  := Space(Len(_cEtqEnder))
			_cArmazem   := Space(Len(_cArmazem))
			_cEndereco  := Space(Len(_cEndereco))
			_lNovoEnder := .t.
		EndIf
		_nQtdProd   := 1
		_nQtdSegUM  := 0
		_cEtqCodBar := Space(Len(_cEtqCodBar))
		_cEtqVolume := Space(Len(_cEtqVolume))

		// define se limpa os campos ou não com base no parâmetro
		If ( ! _lRptLot )
			_cEtqLote := Space(Len(_cEtqLote))
			_dVldLote := CtoD("//")
		EndIf

		// se não controlar validade, já trás o campo preenchido
		If ( ! _lCtrVld )

			// define a data como data atual
			_dVldLote := CtoD("31/12/2049")

		EndIf

		// para inventario diferente do padrao (com gate), solicita endereco de destino
		If ( ! _lInvPadrao ) .And. (_cCodCliFor == "000467") .And. ( ! mvEstorno )

			// funcao que solicita endereco de destino
			sfConfDest()

		EndIf

		// define novo volume
		_lNovoVolume := .t.

		// atualiza os dados
		sfSelDados()

		// atualiza objetos
		_oGetIdEndere:lReadOnly := ( ( ! _lNovoEnder ) .And. (_lInvPadrao) )
		_oGetNrPalete:lReadOnly := (_lNovoEnder)
		_oGetIdProdut:lReadOnly := (_lNovoEnder)

		// atualiza objetos
		mvGetEtqVolume:bWhen     := {|| (_lCtrVolume) .And. ( ! _lEtqClient ) }
		mvGetEtqVolume:lReadOnly := ( ( ! _lCtrVolume ) .And. ( ! _lNovoVolume ) )

	EndIf

	// foco para o ID endereco
	_oGetIdEndere:SetFocus()

Return(_lRet)

// ** funcao para gerar novo volume
Static Function sfNovoVolume(mvGetEtqVolume)
	// variavel de retorno
	local _lRet := .t.
	// define o foco do objeto
	local _lFocoVol := .f.
	local _lFocoEnd := .f.

	// valida se o endereco foi informado
	If (_lRet) .And. (Empty(_cEtqEnder) .Or. Empty(_cEndereco))
		// mensagem de validacao
		U_FtWmsMsg("É necessário informar a localização!","ATENCAO")
		// variavel de retorno
		_lRet := .f.
		// foco de objeto
		_lFocoEnd := .t.
	EndIf

	// solicita confirmacao
	If (_lRet) .And. ( ! U_FtYesNoMsg("Confirma novo volume ?", "Novo Volume"))
		_lRet := .f.
		Return(_lRet)
	EndIf

	// dados ok
	If (_lRet)

		// reinicia variaveis
		_cCodProd   := Space(Len(_cCodProd))
		_cEtiqProd  := Space(Len(_cEtiqProd))
		_cCodUnit   := Space(Len(_cCodUnit))
		_nQtdProd   := 1
		_nQtdSegUM  := 0
		_cEtqCodBar := Space(Len(_cEtqCodBar))
		_cEtqVolume := Space(Len(_cEtqVolume))

		// define novo volume
		_lNovoVolume := .t.

		// define o foco de objeto
		_lFocoVol := .t.

		// atualiza os dados
		sfSelDados()

		// atualiza objetos
		_oGetIdEndere:lReadOnly := ( ( ! _lNovoEnder ) .And. (_lInvPadrao) )
		_oGetNrPalete:lReadOnly := ( _lNovoEnder )
		_oGetIdProdut:lReadOnly := ( _lNovoEnder )

		// atualiza campo Etq Volumes
		mvGetEtqVolume:bWhen     := {|| (_lCtrVolume) .And. ( ! _lEtqClient ) }
		mvGetEtqVolume:lReadOnly := ( ( ! _lCtrVolume ) .And. ( ! _lNovoVolume ) )

	EndIf

	// foco de objetos
	If (_lFocoEnd) // para o ID endereco
		_oGetIdEndere:SetFocus()
	ElseIf (_lFocoVol) // para o ID Volume
		mvGetEtqVolume:SetFocus()
	EndIf

Return(_lRet)

// ** funcao que calcula as unidade de medidas
Static Function sfVldQuant(mvUndRet)

	If (_nQtdProd > 0) .Or. (_nQtdSegUM > 0)
		If (!Empty(SB1->B1_SEGUM)) .And. (SB1->B1_CONV>0)
			// retorna a 1a Unid Medida
			If (mvUndRet==1)
				_nQtdProd := ConvUM(SB1->B1_COD, _nQtdProd, _nQtdSegUM, mvUndRet)
				// 2a Unid Medida
			ElseIf (mvUndRet==2)
				_nQtdSegUM := ConvUM(SB1->B1_COD, _nQtdProd, _nQtdSegUM, mvUndRet)
			EndIf
		EndIf
	EndIf

Return(.t.)

// ** funcao que apresenta os detalhes do inventario total
Static Function sfDetInventario()

	// objetos da tela
	local _oDlgDetInv
	local _oPnlDetInv
	local _oBmpSair
	local _oBrwEndInv
	local _oSayTotProg, _oSayTotInv
	local _oMnuOpcoes, _oSbMnOpc1, _oSbMnOpc2, _oSbMnOpc3, _oSbMnOpc4, _oBmpOpcoes

	// variaveis do browse
	local _aHeadEnd := {}

	// resumo do inventario
	private _nTotProgra := 0
	private _nTotInvent := 0

	// acols do browse
	private _aColsEnd := {}

	// campos/colunas do browse
	aAdd(_aHeadEnd,{" "                       ,"Z21_CONTAG" , "@BMP", 2                       ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadEnd,{"Endereços a Inventariar" ,"Z21_LOCALI" , ""    , TamSx3("BE_LOCALIZ")[1] ,0,Nil,Nil,"C",Nil,"R" })

	// monta o dialogo do inventário
	_oDlgDetInv := MSDialog():New(000,000,(_aSizeDlg[2]),(_aSizeDlg[1]),"Endereços do Inventário",,,.F.,,,,,,.T.,,,.T. )
	_oDlgDetInv:lEscClose := .F.

	// atualizo o acols
	sfRetDetInv("", @_aColsEnd)

	// sub-itens do menus
	_oMnuOpcoes := TMenu():New(0,0,0,0,.T.)
	// adiciona itens no Menu

	// -- filtro de endereços a inventariar
	_oSbMnOpc1 := TMenuItem():New(_oMnuOpcoes,"Mostra Pendências",,,,{|| sfFiltraBrw("PENDENTE", _oBrwEndInv)  },,"FILTRO",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc1)

	// -- filtro de endereços lidos
	_oSbMnOpc2 := TMenuItem():New(_oMnuOpcoes,"Mostra Lidos",,,,{|| sfFiltraBrw("LIDO", _oBrwEndInv)  },,"FILTRO",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc2)

	// -- mostra tudo
	_oSbMnOpc3 := TMenuItem():New(_oMnuOpcoes,"Mostra Tudo",,,,{|| sfFiltraBrw("", _oBrwEndInv) },,"FILTRO",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc3)

	// -- opção para sair
	_oSbMnOpc4 := TMenuItem():New(_oMnuOpcoes,"Sair",,,,{|| _oDlgDetInv:END() },,"FINAL",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc4)

	// cria o panel do cabecalho - botoes de operacao
	_oPnlDetInv := TPanel():New(000,000,nil,_oDlgDetInv,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlDetInv:Align:= CONTROL_ALIGN_TOP

	// resumo do inventario
	_oSayTotProg := TSay():New(004,003,{||"Total Programado: "+AllTrim(Str(_nTotProgra)) },_oPnlDetInv,,,.F.,.F.,.F.,.T.)
	_oSayTotInv  := TSay():New(013,003,{||"Total Realizado: "+AllTrim(Str(_nTotInvent)) },_oPnlDetInv,,,.F.,.F.,.F.,.T.)

	// -- BOTAO COM MAIS OPCOES
	_oBmpOpcoes := TBtnBmp2():New(000,000,060,022,"SDUAPPEND",,,,{|| Nil },_oPnlDetInv,"",,.T.)
	_oBmpOpcoes:Align := CONTROL_ALIGN_RIGHT
	_oBmpOpcoes:SetPopupMenu(_oMnuOpcoes)

	// browse com os enderecos
	_oBrwEndInv := MsNewGetDados():New(078,000,148,118,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsEnd),'AllwaysTrue()','','AllwaysTrue()',_oDlgDetInv,_aHeadEnd,_aColsEnd)
	_oBrwEndInv:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	_oDlgDetInv:Activate(,,,.F.,{|| .t. },,)

Return(.t.)

// ** função que retorna os detalhes do inventário
Static Function sfRetDetInv(mvFiltra, mvACols)

	// variaveis do browse
	local _cQuery := ""
	local _aEndInvent := {}

	// variaveis temporias
	local _nX

	// default do parametro
	Default mvFiltra := ""

	// limpo o acols
	mvACols := {}

	// monta a query
	_cQuery := " SELECT DISTINCT "
	// status se ja foi inventariado
	_cQuery += " Z21_CONTAG,
	// legenda
	_cQuery += " CASE WHEN Z21_CONTAG = 'S' THEN 'BR_VERDE' ELSE 'BR_VERMELHO' END IT_LEGEND, "
	// endereco
	_cQuery += " Z21_LOCALI, "
	// id do palete
	_cQuery += " Z21_ETQPAL "
	// mapa de inventario
	_cQuery += " FROM "+RetSqlTab("Z21")
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z21")
	// numero da OS
	_cQuery += " AND Z21_IDENT = '"+_cNumOrdSrv+"' "

	// se estiver filtrando as pendências
	If ( ! Empty(mvFiltra) )
		If (mvFiltra == "PENDENTE")
			// status do endereço
			_cQuery += " and Z21_CONTAG != 'S' "
		Elseif (mvFiltra == "LIDO")
			// status do endereço
			_cQuery += " AND Z21_CONTAG = 'S' "
		EndIf
	EndIf

	// ordem dos dados
	_cQuery += " ORDER BY Z21_LOCALI "

	memowrit("c:\query\twmsa014_sfDetInventario.txt", _cQuery)

	// atualiza o vetor do browse
	_aEndInvent := U_SqlToVet(_cQuery)

	If (Empty(mvFiltra))
		// define o total programado
		_nTotProgra := Len(_aEndInvent)
	EndIf

	// for pra pegar os valores do array
	for _nX := 1 to len(_aEndInvent)
		// só atualiza quando não for filtrar
		If (Empty(mvFiltra))
			// atualiza total inventariado
			If (_aEndInvent[_nX][1] == "S")
				_nTotInvent += 1
			EndIf
		EndIf

		// inclui item no browse, informando a legenda
		aAdd(mvACols,{LoadBitMap(GetResources(), _aEndInvent[_nX][2]),;
		sfTransfEnd(_aEndInvent[_nX][3]),;
		.f.})
	Next _nX

Return ()

// ** função para mostrar as divergências
Static Function sfFiltraBrw(mvFiltro, mvBrowse)

	local _cFiltra := mvFiltro

	// atualizo o acols do browse
	sfRetDetInv(_cFiltra, @_aColsEnd)

	// seto o array no browse
	mvBrowse:SetArray(_aColsEnd)
	mvBrowse:oBrowse:Refresh()

Return ()

// ** função para formatar o endereço ** //
Static Function sfTransfEnd(mvEnd)

	// endereço
	local _cEndPar := mvEnd
	If ("BLOCO" $ mvEnd)
		_cEndPar := transf(_cEndPar,"@R AAAAA 999 99")
	Else
		_cEndPar := transf(_cEndPar,"@R 99.A.99.99.99999")
	EndIf

Return (_cEndPar)

// ** funcao que valida e finaliza a OS
Static Function sfFinalizaOs(mvWndInventario)
	// variavel de retorno
	local _lRet := .t.
	// query
	local _cQuery := ""

	// solicita confirmacao
	If (_lRet) .And. ( ! U_FtYesNoMsg("Finalizar Inventário?", "Finalizar"))
		// variavel de retorno
		_lRet := .f.
		// finaliza
		Return(_lRet)
	EndIf

	// query pra validar a finalização da OS
	If (_lRet)
		_cQuery := " SELECT COUNT(*) QTD_PEND "
		// enderecos programados
		_cQuery += " FROM "+RetSqlTab("Z21")
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("Z21")
		// numero da OS
		_cQuery += " AND Z21_IDENT = '"+_cNumOrdSrv+"' "
		// enderecos não lidos
		_cQuery += " AND Z21_CONTAG = 'N' "

		memowrit("c:\query\twmsa014_sfFinalizaOs.txt",_cQuery)

		// recebe os valores da query
		If (U_FtQuery(_cQuery) > 0)
			IF (( ! _lUsrGeren ) .And. ( ! _lUsrAccou ) .And. ( ! _lUsrSuper ))
				// mensagem de validacao
				U_FtWmsMsg("OS não pode ser finalizada. Favor inventariar todos os endereços.","Atenção")
				// variavel de retorno
				_lRet := .f.
				// visualizar detalhes da rua
				If (U_FtYesNoMsg("Visualizar Detalhes do Inventário?","ATENÇÃO"))
					// chama funcao dos detalhes do inventario
					MsgRun("Aguarde...",,{|| sfDetInventario() })
				EndIf
			Else
				//chama validação se é gerente ou supervisor
				IF ! StaticCall(TWMSA010, sfVldUser, "G|S|L")
					// variavel de retorno
					_lRet := .f.
					// finaliza
					Return(_lRet)
				Endif

			Endif
		EndIf
	EndIf

	// se tudo ok
	If (_lRet)

		// atualiza o status do servico para BL-BLOQUEADO (para analise)
		U_FtWmsSta(_cCodStatus,;
		"BL",;
		_cNumOrdSrv,;
		_cSeqOrdSrv)

		// mensagem de confirmacao
		U_FtWmsMsg("OS Finalizada com sucesso!","Sucesso")

		// fecha a tela/dialogo
		mvWndInventario:End()

	EndIf

Return(_lRet)

// ** função pra validar o endereco
Static Function sfVldEndere(mvGetEtqVolume, mvGetIdEndere, mvGetIdProdut, mvCmbTamCaixa, mvGetEndereco)

	// variavel de retorno
	local _lRet := .t.
	local _cQuery := ""
	local _cQryEnd := ""

	// zera variaveis
	_cArmazem  := Space(Len(_cArmazem))
	_cEndereco := Space(Len(_cEndereco))

	// etiqueta em branco
	If (_lRet) .And. (Empty(_cEtqEnder))
		Return(_lRet)
	EndIf

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11")+_cEtqEnder ))
			U_FtWmsMsg("Identificador do endereço inválido!","ATENCAO")
			_lRet := .f.
		EndIf
	EndIf

	// valida o tipo da etiqueta lida
	If (_lRet)
		If (Z11->Z11_TIPO != "02")
			U_FtWmsMsg("Tipo de etiqueta inválida!","ATENCAO")
			_lRet := .f.
		EndIf
	EndIf

	// valida e atualiza o endereco
	If (_lRet)

		// atualiza variaveis de retorno
		_cArmazem  := Z11->Z11_LOCAL
		_cEndereco := Z11->Z11_ENDERE

	EndIf

	// valida se o endereco esta programado para inventario
	If (_lRet)
		// monta a query
		_cQuery := " SELECT COUNT(*) QTD_MAPA "
		// enderecos programados para inventario
		_cQuery += " FROM "+RetSqlTab("Z21")
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("Z21")
		// numero da OS
		_cQuery += " AND Z21_IDENT = '"+_cNumOrdSrv+"' "
		// endereco
		_cQuery += " AND Z21_LOCALI = '"+_cEndereco+"' "
		// numero da contagem
		_cQuery += " AND Z21_NRCONT = '" +_cNrCont+ "' "

		memowrit("c:\query\twmsa014_sfVldEndere.txt",_cQuery)

		// executa validacao
		If (U_FtQuery(_cQuery) == 0)
			// mensagem
			U_FtWmsMsg("Endereço não programado para este inventário!","ATENCAO")
			// zera variaveis
			_cArmazem  := Space(Len(_cArmazem))
			_cEndereco := Space(Len(_cEndereco))
			// variavel de controle
			_lRet := .f.
		EndIf

	EndIf

	// pesquisa se o endereco eh valido
	If (_lRet)
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ, BE_ESTFIS
		If ! SBE->(dbSeek( xFilial("SBE") + _cArmazem + _cEndereco ))
			// mensagem
			U_FtWmsMsg("Endereço não cadastrado! (Arm: " + _cArmazem + "/" + AllTrim(_cEndereco) + ")!","ATENCAO")
			// variavel de controle
			_lRet := .f.
		EndIf

		// pesquisa da estrutura fisica
		If (_lRet)
			// pesquisa mascara do endereco no tipo de estrutura
			dbSelectArea("DC8")
			DC8->(dbSetOrder(1)) // 1-DC8_FILIAL, DC8_CODEST
			If DC8->(dbSeek( xFilial("DC8") + SBE->BE_ESTFIS ))
				// atualiza mascara
				_cMaskEnd := DC8->DC8_ZMASCA
			EndIf
		EndIf

	EndIf

	// quando ok, atualiza variaveis e dados
	If (_lRet)
		// atualiza variaveis
		_lNovoEnder := .f.

		// atualiza objetos
		mvGetIdEndere:lReadOnly := ( ! _lNovoEnder)
		mvGetIdProdut:lReadOnly := ( _lNovoEnder )
		mvGetEndereco:Refresh()

		// atualiza os dados
		sfSelDados()

		// foco no proximo objeto
		If ( ! _lCtrVolume )
			mvGetIdProdut:SetFocus()
		ElseIf (_lCtrVolume)
			mvCmbTamCaixa:SetFocus()
		EndIf

	EndIf

Return (_lRet)

// ** função pra gravar os novos dados do inventário
Static Function sfGravaEndVz(mvGetEtqVolume)

	// variavel de retorno
	local _lRet     := .t.
	local _cQryEnd  := ""

	// etiqueta em branco
	If (_lRet) .And. (Empty(_cEtqEnder) .Or. Empty(_cEndereco))
		U_FtWmsMsg("É necessário informar a localização!","ATENCAO")
		_lRet := .f.
	EndIf

	If (_lRet) .And. ( ! U_FtYesNoMsg("Confirma endereço vazio ?", "Endereço Vazio"))
		Return(.f.)
	EndIf

	// valida se o endereco ja foi lido
	If (_lRet)
		_cQryEnd := " SELECT COUNT(*) QTD_LEIT FROM "+RetSqlTab("Z19")
		// filtro padrao
		_cQryEnd += " WHERE "+RetSqlCond("Z19")
		// numero da OS
		_cQryEnd += " AND Z19_IDENT = '"+_cNumOrdSrv+"' "
		// armazem
		_cQryEnd += " AND Z19_LOCAL = '"+_cArmazem+"' "
		// endereco
		_cQryEnd += " AND Z19_ENDERE = '"+_cEndereco+"' "
		// validação da contagem
		_cQryEnd += " AND Z19_CONTAG = '" + _cNrCont + "' "

		// valida se endereço já foi lido
		If (U_FtQuery(_cQryEnd) > 0)
			U_FtWmsMsg("Endereço já lido para esse inventário!","Atenção")
			_lRet := .f.
		EndIf
	EndIf

	// grava registro na z19 quando o flag de VAZIO estiver ativo
	If (_lRet)
		dbSelectArea("Z19")
		RECLOCK("Z19", .T.)
		Z19->Z19_FILIAL   := xFilial("Z19")
		Z19->Z19_IDENT    := _cNumOrdSrv
		Z19->Z19_CODPRO   := ""
		Z19->Z19_LOCAL    := _cArmazem
		Z19->Z19_ENDERE   := _cEndereco
		Z19->Z19_DATA     := DATE()
		Z19->Z19_HORA     := TIME()
		Z19->Z19_CONTAG   := _cNrCont
		Z19->Z19_USER     := __cUserId
		Z19->Z19_ETQEND   := _cEtqEnder
		Z19->Z19_TPEMBA   := _cTamCaixa
		Z19->(MsUnLock())// Destrava o registro

		// update para informar a Z21 que o endereço já foi inventariado
		_cQryEnd := "UPDATE "+RetSqlName("Z21")+" SET Z21_CONTAG = 'S' "
		// filtro padrao
		_cQryEnd += "WHERE Z21_FILIAL = '"+xFilial("Z21")+"' AND D_E_L_E_T_ = ' ' "
		// ordem de servico
		_cQryEnd += "AND Z21_IDENT = '"+_cNumOrdSrv+"' "
		// armazem
		_cQryEnd += "AND Z21_LOCAL = '"+_cArmazem+"' "
		// endereco
		_cQryEnd += "AND Z21_LOCALI = '"+_cEndereco+"' "
		// executa update
		If (TcSQLExec(_cQryEnd) < 0)
			U_FtWmsMsg("*** ERRO NA ATUALIZACAO sfGravaEndVz ***" +CRLF+CRLF+ TCSQLError() )
			MemoWrit("c:\query\twmsa014_sfGravaEndVz_update_erro.txt",_cQryEnd +CRLF+CRLF+ TCSQLError())
		EndIf

		// gera novo endereco
		sfNovoEndereco(.F., @mvGetEtqVolume, .F.)

	EndIf

Return(_lRet)

// ** funcao para validacao do codigo do produto digitado (lido)
Static Function sfVldProd(mvTpIdEtiq)
	// query
	Local _cQuery := ""

	// informa quantidade manual
	local _lInfQtdMan := .f.

	// controle de retorno
	local _lRet := .t.

	// quantidade maxima do produto por palete
	local _nQtdMaxPallet := 0

	// chave de pesquisa
	local _cChvPesq := ""

	Local _aRetPal := {}

	If (_lEtqIdInt) // ident interna
		_cChvPesq := _cEtiqProd
	ElseIf (_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIdDUN) .Or. (_lEtqClient) // ean 13 / code128 / DUN14 / Etiq Cliente
		_cChvPesq := _cEtqCodBar
	EndIf

	// reinicia variavel
	_nQtdProd  := 1
	_nQtdSegUM := 0

	// valida se o endereco foi informado
	If (_lRet) .And. (Empty(_cEtqEnder) .Or. Empty(_cEndereco))
		U_FtWmsMsg("É necessário informar a localização!","ATENCAO")
		_lRet := .f.
	EndIf

	// valida se o produto foi informado
	If (_lRet) .And. (((_lEtqIdInt) .And. Empty(_cEtiqProd)) .Or. (( (_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIdDUN) .Or. (_lEtqClient) ) .And. Empty(_cEtqCodBar)))
		U_FtWmsMsg("É necessário informar a etiqueta do produto!","ATENCAO")
		_lRet := .f.
	EndIf

	// controle por volume
	If (_lRet) .And. ( ! _lEtqClient ) .And. ((_lCtrVolume) .And. (Empty(_cEtqVolume)))
		U_FtWmsMsg("É necessário informar a etiqueta do volume!","ATENCAO")
		_lRet := .f.
	EndIf

	// realiza a pesquisa do produto, podendo ser feita pelo codigo de barras
	If (_lRet) .And. ( ! U_FtCodBar(_cChvPesq, @_cCodProd, @_lInfQtdMan, @_cNumSeq, mvTpIdEtiq, _cCodCliFor, @_nQtdProd) )
		// variavel de retorno
		_lRet := .F.
	EndIf

	// verifica se o item já foi lido
	If (_lRet) .And. (_lEtqIdInt)

		_cQuery := " SELECT COUNT(*) QTD_LEIT FROM " + RetSqlTab("Z19")
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z19")
		// filtro por OS
		_cQuery += " AND Z19_IDENT  = '" + _cNumOrdSrv + "' "
		// etiqueta de produto
		_cQuery += " AND Z19_ETQPRO = '" + _cChvPesq + "' "
		// validação da contagem
		_cQuery += " AND Z19_CONTAG = '" + _cNrCont + "' "

		// se encontrou registro
		If (U_FtQuery(_cQuery) > 0)
			// endereço já inventario
			U_FtWmsMsg("Endereço e/ou etiqueta já lidos para esse inventário!","Atenção")
			_lRet := .f.
		EndIf
	EndIf

	//Validação de leitura duplicada de SKU no mesmo endereço e volume.
	If (_lRet) .And. ((_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIdDUN) ) .And. (_lCtrVolume)
		_cQuery := " SELECT COUNT(*) QTD FROM "+RetSqlTab("Z19")
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("Z19")
		// filtro por OS
		_cQuery += " AND Z19_IDENT  = '"+_cNumOrdSrv+"' "
		// filtro Endereço
		_cQuery += " AND Z19_ETQEND  = '"+_cEtqEnder+"' "
		// filtro ID Volume
		_cQuery += " AND Z19_ETQVOL  = '"+_cEtqVolume+"' "
		// filtro Produto
		_cQuery += " AND Z19_CODEAN  = '"+_cChvPesq+"' "
		// validação da contagem
		_cQuery += " AND Z19_CONTAG = '" + _cNrCont + "' "
		// se encontrou registro
		If (U_FtQuery(_cQuery) > 0)
			// endereço já inventario
			U_FtWmsMsg("Produto já digitado neste endereço e volume!","Atenção")
			// variavel de controle
			_lRet := .f.
		EndIf
	EndIf

	// validação de leitura duplicada de etiqueta do cliente
	If (_lRet) .And. (_lEtqClient) .And. (_lCtrVolume)
		// prepara query
		_cQuery := " SELECT COUNT(*) QTD FROM " + RetSqlTab("Z19")
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z19")
		// filtro por OS
		_cQuery += " AND Z19_IDENT  = '" + _cNumOrdSrv + "' "
		// filtro Endereço
		_cQuery += " AND Z19_ETQEND  = '" + _cEtqEnder + "' "
		// filtro etiqueta do cliente
		_cQuery += " AND Z19_ETQCLI  = '" + _cChvPesq + "' "
		// validação da contagem
		_cQuery += " AND Z19_CONTAG = '" + _cNrCont + "' "
		// se encontrou registro
		If (U_FtQuery(_cQuery) > 0)
			// endereço já inventario
			U_FtWmsMsg("Etiqueta de Cliente já digitada neste endereço!","Atenção")
			// variavel de controle
			_lRet := .f.
		EndIf
	EndIf

	If (_lRet)
		// valida o controle de lote
		_lCtrLote := (SB1->B1_RASTRO == "L")
	EndIf

	// verifica se o produto pode informar quantidades
	// alterado em 09/10/18 por solicitação do Flávio durante testes Samsonite. O intuito é
	// que farão inventário apenas bipando UM volume e informando a quantidade do pallet, porém caso a flag esteja
	// ativa no cadastro do produto, ele bipa apenas quantidade = 1 e com isso, cai por terra o inventário "rápido"
	If (_lRet) // .And. ( _lInfQtdMan )

		// tela para informar informações Adicionais
		sfInfAdici()

	EndIf

	// valida quantidade informada
	If (_lRet) .And. (_nQtdProd <= 0)
		// mensagem
		U_FtWmsMsg("Favor informar a quantidade.","Atenção")
		// variavel de controle
		_lRet := .f.
	EndIf

	// validacao de lastro x camada
	If (_lRet) .And. (_lVldLastro)
		// estrutura do retorno
		// 1-Quantidade Total de Palete
		// 2-Quantidade de Paletes Cheios
		// 3-Quantidade de Paletes Fracionados
		// 4-Quantidade Maxima de SKU/Volumes por Palete
		// 5-Tipo do Calculo (Q-Quant Unitarios / P-Quant Palete Informado)
		_aRetPal := U_FtWmsNorma(_cCodProd, _cArmazem, Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)

		// atualiza variavel de controle de acordo com o calculo da funcao FtWmsNorma
		_nQtdMaxPallet := _aRetPal[4]

		// se nao tem norma definida, valida o retorno
		_lRet := (_nQtdMaxPallet > 0)
	EndIf

	// valida se o endereco nao foi informado como VAZIO
	If (_lRet)

		_cQuery := " SELECT COUNT(*) QTD_LEIT FROM "+RetSqlTab("Z19")
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("Z19")
		// filtro da OS
		_cQuery += " AND Z19_IDENT  = '"+_cNumOrdSrv+"' "
		// endereco
		_cQuery += " AND Z19_ENDERE = '"+_cEndereco+"' "
		// quantidade 0 Zero
		_cQuery += " AND Z19_QUANT  = 0 "
		// validação da contagem
		_cQuery += " AND Z19_CONTAG = '" + _cNrCont + "' "

		// valido se o endereço já foi lido
		If (U_FtQuery(_cQuery) > 0)
			U_FtWmsMsg("Endereço já inventariado.","Atenção")
			_lRet := .f.
		EndIf

	EndIf

	// busca e valida id do palete
	If (_lRet) .And. (_lInvPadrao) //.And. (!_lInvIni)

		// chama funcao para retornar ID do palete
		_cIdPalete := sfRetNrPalete(_cChvPesq, _cEndereco)

//		// se nao encontrou palete
//		_lRet := ( ! Empty(_cIdPalete) )

	EndIf

	// grava os dados do inventario
	If (_lRet)

		// posiciona no produto
		dbSelectArea("Z19")
		RECLOCK("Z19", .T.)
		Z19->Z19_FILIAL   := xFilial("Z19")
		Z19->Z19_IDENT    := _cNumOrdSrv
		Z19->Z19_CODPRO   := _cCodProd
		Z19->Z19_LOCAL    := _cArmazem
		Z19->Z19_ENDERE   := _cEndereco
		Z19->Z19_QUANT    := _nQtdProd
		Z19->Z19_QTSEGU   := _nQtdSegUM
		Z19->Z19_DATA	  := DATE()
		Z19->Z19_HORA     := TIME()
		Z19->Z19_CONTAG   := _cNrCont
		Z19->Z19_USER     := __cUserId
		Z19->Z19_ETQPRO   := _cEtiqProd
		Z19->Z19_ETQEND   := _cEtqEnder
		Z19->Z19_CODEAN   := _cEtqCodBar
		Z19->Z19_ETQVOL   := _cEtqVolume
		Z19->Z19_TPEMBA   := _cTamCaixa
		Z19->Z19_PLTCLI   := _cPltClie
		Z19->Z19_LOTCTL   := AllTrim(_cEtqLote)
		Z19->Z19_VLDLOT   := _dVldLote
		Z19->Z19_TPESTO   := _cTpEstoque
		Z19->Z19_ETQPAL   := _cIdPalete
		If ( _lEtqClient )
			Z19->Z19_ETQCLI := _cEtqCodBar
		EndIf
		Z19->(MsUnLock()) // Destrava o registro

		// update para informar a Z21 que o endereço já foi inventariado
		_cQryEnd := " UPDATE "+RetSqlName("Z21")+" SET Z21_CONTAG = 'S' "
		_cQryEnd += " WHERE Z21_FILIAL = '"+xFilial("Z21")+"' AND D_E_L_E_T_ = ' ' "
		_cQryEnd += " AND Z21_IDENT = '"+_cNumOrdSrv+"' AND Z21_LOCALI = '"+_cEndereco+"' "
		If ( ! Empty(_cIdPalete) )
			_cQryEnd += " AND Z21_ETQPAL = '" +_cIdPalete+ "' "
		EndIf
		// executa update
		If (TcSQLExec(_cQryEnd) < 0)
			U_FtWmsMsg("*** ERRO NA ATUALIZACAO sfVldProd ***" +CRLF+CRLF+ TCSQLError() )
			MemoWrit("c:\query\twmsa014_sfVldProd_update_erro.txt",_cQryEnd +CRLF+CRLF+ TCSQLError())
		EndIf

		MemoWrit("c:\query\twmsa014_sfVldProd_update.txt",_cQryEnd)

	EndIf

	// zera as variaveis
	_cEtiqProd  := Space(Len(_cEtiqProd))
	_cEtqCodBar := Space(Len(_cEtqCodBar))
	_cPltClie   := Space(Len(_cPltClie))

	// define se limpa os campos ou não com base no parâmetro
	If ( ! _lRptLot )
		_cEtqLote := Space(Len(_cEtqLote))
		_dVldLote := CtoD("//")
	EndIf

	// se não controlar validade, já trás o campo preenchido
	If ( ! _lCtrVld )

		// define a data como data atual
		_dVldLote := CtoD("31/12/2049")

	EndIf

	// atualiza os dados
	If (_lRet)
		sfSelDados()
	EndIf

	// foco no ID produto
	_oGetIdProdut:Refresh()
	_oGetIdProdut:SetFocus()

Return(_lRet)

// ** função que traz a informação escrita pelo criador da OS
Static Function sfMostraObs()

	local _cQuery := ""
	local _cRetObs := ""

	_cQuery := " SELECT DISTINCT Z21_OBS "
	_cQuery += " FROM "+RetSqlTab("Z21")
	_cQuery += " WHERE "+RetSqlCond("Z21")
	_cQuery += " AND Z21_IDENT = '"+_cNumOrdSrv+"' "
	_cQuery += " AND Z21_NRCONT = '"+_cNrCont+"' "

	// observacao de retorno
	_cRetObs := AllTrim(U_FtQuery(_cQuery))

	// incrementa a contagem
	_cRetObs += CRLF+CRLF
	_cRetObs += "Número Contagem: "+_cNrCont

Return(_cRetObs)

// ** função para estornar leitura
Static Function sfEstornaLei(mvGetEtqVolume, mvEndereco, mvTipoEst, mvChvPesq)

	Local _cQuery  := ""
	Local _lRet := .t.

	// valores padroes
	Default mvEndereco := CriaVar("BE_LOCALIZ", .f.)
	Default mvChvPesq  := ""

	// valida o endereco
	If (_lRet) .And. (Empty(mvEndereco))
		U_FtWmsMsg("Endereço não informado!","Atenção")
		_lRet := .f.
	EndIf

	// valida estorno de enderecos do tipo BLOCADO
	If (_lRet) .And. (mvTipoEst == "TOT") .And. (SubStr(mvEndereco,1,5) == 'BLOCO')
		U_FtWmsMsg("Não é permitido o estorno total de endereços do tipo BLOCADO!","Atenção")
		_lRet := .f.
	EndIf

	// valida volume
	If (_lRet) .And. (mvTipoEst $ "VOL|PRO|CLI") .And. (Empty(mvChvPesq))
		U_FtWmsMsg("Etiqueta de Volume, Produto ou Cliente não informada!","Atenção")
		_lRet := .f.
	EndIf

	// mensagem de confirmacao
	If (_lRet)
		If (mvTipoEst == "TOT") .And. ( U_FtYesNoMsg("Estornar leitura TOTAL do endereço " + mvEndereco + " ?") )
			_lRet := .T.
		ElseIf (mvTipoEst $ "VOL|PRO|CLI") .And. ( U_FtYesNoMsg("Estornar leitura da Etiqueta " + AllTrim(mvChvPesq) + " ?") )
			_lRet := .t.
		Else
			_lRet := .F.
		EndIf
	EndIf

	// se encontrou o endereço, realizado as operações
	If (_lRet)

		// deleto registro na z19 - contagem
		_cQuery := " UPDATE " + RetSqlName("Z19") + " SET D_E_L_E_T_ = '*' "
		// filtro padrao
		_cQuery += " WHERE Z19_FILIAL = '" + xFilial("Z19") + "' AND D_E_L_E_T_ = ' ' "
		// numero da OS
		_cQuery += " AND Z19_IDENT  = '" + _cNumOrdSrv + "' "
		// contagem
		_cQuery += " AND Z19_CONTAG = '" + _cNrCont + "' "
		// endereco
		_cQuery += " AND Z19_ENDERE = '" + mvEndereco + "' "
		// volume
		If (mvTipoEst == "VOL")
			// campo de etiqueta de volume
			_cQuery += " AND Z19_ETQVOL = '" + mvChvPesq + "' "
			// produto
		ElseIf (mvTipoEst == "PRO")
			// campo de etiqueta de produto
			_cQuery += " AND Z19_ETQPRO = '" + mvChvPesq + "' "
			// etiqueta de cliente
		ElseIf (mvTipoEst == "CLI")
			// campo de etiqueta de cliente
			_cQuery += " AND Z19_ETQCLI = '" + mvChvPesq + "' "
		EndIf
		// filtra somente dados do usuario logado
		If ( ! _lInvPadrao )
			_cQuery += " AND Z19_USER = '" + __cUserId + "' "
		EndIf

		MemoWrit("c:\query\twmsa014_sfEstornaLei_Z19_update.txt", _cQuery)

		// executa update
		If (TcSQLExec(_cQuery) < 0)
			U_FtWmsMsg("*** ERRO NA ATUALIZACAO sfEstornaLei ***" + CRLF + CRLF + TCSQLError() )
			MemoWrit("c:\query\twmsa014_sfEstornaLei_Z19_update_erro.txt", _cQuery + CRLF + CRLF + TCSQLError() )
		EndIf

		// update na Z21
		_cQuery := " UPDATE " + RetSqlName("Z21") + " SET Z21_CONTAG = ( "
		// sub-query para buscar outros itens inventariados no mesmo endereco
		_cQuery += " SELECT CASE WHEN COUNT(*) > 0 THEN 'S' ELSE 'N' END "
		_cQuery += " FROM " + RetSqlTab("Z19") + " WHERE " + RetSqlCond("Z19")
		_cQuery += " AND Z19_IDENT  = Z21_IDENT "
		_cQuery += " AND Z19_LOCAL  = Z21_LOCAL "
		_cQuery += " AND Z19_ENDERE = Z21_LOCALI "
		_cQuery += " AND Z19_ETQPAL = Z21_ETQPAL "
		_cQuery += " ) "
		// filtro padrao
		_cQuery += " WHERE Z21_FILIAL = '" + xFilial("Z21") + "' AND D_E_L_E_T_ = ' ' "
		// numero da OS
		_cQuery += " AND Z21_IDENT  = '" + _cNumOrdSrv + "' "
		// endereco
		_cQuery += " AND Z21_LOCALI = '" + mvEndereco + "' "
		// contagem
		_cQuery += " AND Z21_NRCONT = '" + _cNrCont + "' "

		MemoWrit("c:\query\twmsa014_sfEstornaLei_Z21_update.txt",_cQuery)

		// executa update
		If (TcSQLExec(_cQuery) < 0)
			U_FtWmsMsg("*** ERRO NA ATUALIZACAO sfEstornaLei ***" + CRLF + CRLF + TCSQLError() )
			MemoWrit("c:\query\twmsa014_sfEstornaLei_Z21_update_erro.txt", _cQuery + CRLF + CRLF + TCSQLError() )
		EndIf

		// se foi bem sucedido, mostra mensagem para o usuário
		U_FtWmsMsg("Estorno realizado com sucesso!","SUCESSO")

		// gera novo endereco
		sfNovoEndereco( .F., @mvGetEtqVolume, .T.)

	EndIf

Return(_lRet)

// ** função para pegar o código do produto
Static Function sfGetCodProd()

	// variaveis do browse
	local _oBrwProd
	local _aHead     := {}
	local _aCols     := {}
	local _cChvPesq  := Space(TamSx3("B1_DESC")[1])

	// objetos da tela
	local _oSayCodPro
	local _oGetCodPro

	// valida endereço
	If (Empty(_cEtqEnder) .Or. Empty(_cEndereco))
		U_FtWmsMsg("Endereço inválido ou não informado.","Atenção")
		Return(.T.)
	EndIf

	// cabecalho do browse
	aAdd(_aHead,{"Cod"       ,"B1_COD"  , "", TamSx3("B1_COD")[1]  ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHead,{"Descrição" ,"B1_DESC" , "", TamSx3("B1_DESC")[1] ,0,Nil,Nil,"C",Nil,"R" })

	// monta o dialogo do inventário
	_oDlgBroEnd := MSDialog():New(000,000,(_aSizeDlg[2]),(_aSizeDlg[1]),"Produtos",,,.F.,,,,,,.T.,,,.T. )
	_oDlgBroEnd:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oBroCab := TPanel():New(000,000,nil,_oDlgBroEnd,,.F.,.F.,,,22,22,.T.,.F.)
	_oBroCab:Align:= CONTROL_ALIGN_TOP

	// código do produto
	_oSayCodPro := TSay():New(007,005,{||"Pesquisa:"},_oBroCab,,,.F.,.F.,.F.,.T.)
	_oGetCodPro := TGet():New(005,030,{|u|If(PCount()>0,_cChvPesq:=u,_cChvPesq) },_oBroCab,70,010,"@!",{|| sfRetDesc(_cChvPesq, @_oBrwProd) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cChvPesq",,)

	// -- BOTAO SAIR
	_oBmpSair := TBtnBmp2():New(000,000,035,001,"FINAL",,,,{|| _oDlgBroEnd:END() },_oBroCab,"Sair",,.T. )
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// browse
	_oBrwProd := MsNewGetDados():New(000,000,500,500,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aCols),'AllwaysTrue()','','AllwaysTrue()',_oDlgBroEnd,_aHead,_aCols)
	_oBrwProd:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwProd:oBrowse:bLdblClick := {|| _cCodProd := _oBrwProd:aCols[_oBrwProd:nAt,1], sfSemEtiq(), _oDlgBroEnd:END()}

	// ativa dialogo
	_oDlgBroEnd:Activate(,,,.F.,{|| .t. },,)

Return

// função realiza pesquisa descrição
Static Function sfRetDesc(mvChvPesq, mvBrowse)

	// variaveis locais
	local _cQuery := ""
	local _aColsPesq  := {}

	// se o campo estiver em branco, não faz a consulta
	If (Empty(mvChvPesq))
		Return (.T.)
	EndIf

	// para realizar a pesquisa mesmo com espaço entre as palavras
	mvChvPesq := STRTRAN(ALLTRIM(mvChvPesq)," ","%")

	// monta a query
	_cQuery := " SELECT B1_COD, B1_DESC, '.F.' IT_DEL FROM "+RetSqlTab("SB1")
	_cQuery += " WHERE "+RetSqlCond("SB1")
	// somente produtos do cliente da OS
	_cQuery += " AND B1_GRUPO IN (SELECT DISTINCT A1_SIGLA FROM "+RetSqlTab("SA1")+" WHERE "+RetSqlCond("SA1")+" AND A1_COD = '"+_cCodCliFor+"') "
	// filtra codigo ou descricao
	_cQuery += " AND (B1_DESC LIKE UPPER('%"+mvChvPesq+"%') OR B1_COD LIKE UPPER('%"+mvChvPesq+"%')) "
	// somente produtos de A-Armazenagem
	_cQuery += " AND B1_ZTIPPRO = 'A' "

	// arquivo para verificação da query
	memowrit("c:\query\twmsa014_sfGetCodPro.txt", _cQuery)

	// atualiza o vetor do browse
	_aColsPesq := U_SqlToVet(_cQuery)

	if (len(_aColsPesq) == 0)
		U_FtWmsMsg("Nenhum código encontrado. Pesquise novamente.","Atenção")
		mvBrowse:Refresh()
		Return (.T.)
	EndIf

	// seto o array no browse
	mvBrowse:SetArray(_aColsPesq)
	mvBrowse:oBrowse:Refresh()

Return (.T.)

// ** função para registrar leitura de pallet sem etiqueta
Static Function sfSemEtiq()
	Local _cQuery := ""
	// controle de retorno
	local _lRet := .t.

	// reinicia variavel
	_nQtdProd  := 1
	_nQtdSegUM := 0

	// grava os dados do inventario
	If (_lRet)

		// tela para informar a quantidade
		sfInfAdici()

		// posiciona no produto
		dbSelectArea("Z19")
		RECLOCK("Z19", .T.)
		Z19->Z19_FILIAL   := xFilial("Z19")
		Z19->Z19_IDENT    := _cNumOrdSrv
		Z19->Z19_CODPRO   := _cCodProd
		Z19->Z19_LOCAL    := _cArmazem
		Z19->Z19_ENDERE   := _cEndereco
		Z19->Z19_QUANT    := _nQtdProd
		Z19->Z19_QTSEGU   := _nQtdSegUM
		Z19->Z19_DATA     := DATE()
		Z19->Z19_HORA     := TIME()
		Z19->Z19_CONTAG   := _cNrCont
		Z19->Z19_USER     := __cUserId
		Z19->Z19_ETQPRO   := ""
		Z19->Z19_ETQEND   := _cEtqEnder
		Z19->Z19_CODEAN   := _cEtqCodBar
		Z19->Z19_ETQVOL   := _cEtqVolume
		Z19->Z19_TPEMBA   := _cTamCaixa
		Z19->(MsUnLock()) // Destrava o registro

		// update para informar a Z21 que o endereço já foi inventariado
		_cQryEnd := "UPDATE "+RetSqlName("Z21")+" SET Z21_CONTAG = 'S' "
		_cQryEnd += "WHERE Z21_FILIAL = '"+xFilial("Z21")+"' AND D_E_L_E_T_ = ' ' "
		_cQryEnd += "AND Z21_IDENT ='"+_cNumOrdSrv+"' AND Z21_LOCALI = '"+_cEndereco+"' "
		// executa update
		If (TcSQLExec(_cQryEnd) < 0)
			U_FtWmsMsg("*** ERRO NA ATUALIZACAO sfSemEtiq ***" +CRLF+CRLF+ TCSQLError() )
			MemoWrit("c:\query\twmsa014_sfSemEtiq_update_erro.txt",_cQryEnd +CRLF+CRLF+ TCSQLError())
		EndIf

	EndIf

	// atualiza os dados
	sfSelDados()

Return

// ** funcao para validacao do codigo do ID de volume
Static Function sfVldVolume(mvGetEtqVolume, mvGetIdProdut)
	// query
	local _cQuery := ""
	// controle de retorno
	local _lRet := .t.

	// valida conteudo da etiqueta
	If (Empty(_cEtqVolume))
		// mensagem
		U_FtWmsMsg("É necessário informar a etiqueta do volume!","ATENCAO")
		// variavel de controle
		_lRet := .f.
	EndIf

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11")+_cEtqVolume ))
			// mensagem
			U_FtWmsMsg("Identificador de volume inválido!","ATENCAO")
			// variavel de controle
			_lRet := .f.
		EndIf
	EndIf

	// valida o tipo da etiqueta lida
	If (_lRet)
		If (Z11->Z11_TIPO != "04")
			// mensagem
			U_FtWmsMsg("Tipo de etiqueta de volume inválida!","ATENCAO")
			// variavel de controle
			_lRet := .f.
		EndIf
	EndIf

	// valida se o endereco nao foi informado como VAZIO
	If (_lRet)

		_cQuery := " SELECT COUNT(*) QTD_LEIT FROM " + RetSqlTab("Z19")
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z19")
		// filtro da OS
		_cQuery += " AND Z19_IDENT  = '" + _cNumOrdSrv + "' "
		// endereco
		_cQuery += " AND Z19_ENDERE = '" + _cEndereco + "' "
		// quantidade 0 Zero
		_cQuery += " AND Z19_QUANT  = 0 "
		// numero de contagem
		_cQuery += " AND Z19_CONTAG = '" + _cNrCont + "' "

		// valido se o endereço já foi lido
		If (U_FtQuery(_cQuery) > 0)
			// mensagem
			U_FtWmsMsg("Endereço já inventariado","Atenção")
			// variavel de controle
			_lRet := .f.
		EndIf

	EndIf

	// valida se a etiqueta do volume esta em mais de um palete/endereco
	If (_lRet)
		_cQuery := " SELECT COUNT(*) QTD_ETQ_VLM "
		// itens inventariados
		_cQuery += " FROM "+RetSqlTab("Z19")
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("Z19")
		// filtra numero da OS
		_cQuery += " AND Z19_IDENT = '"+_cNumOrdSrv+"' "
		// filtra etiqueta de volume
		_cQuery += " AND Z19_ETQVOL = '"+_cEtqVolume+"' "
		// numero de contagem
		_cQuery += " AND Z19_CONTAG = '"+_cNrCont+"' "

		// valida a etiqueta de volume em outro palete
		If (U_FtQuery(_cQuery) > 0)
			// mensagem
			U_FtWmsMsg("Identificador de volume já está em uso!","ATENCAO")
			// variavel de controle
			_lRet := .f.
		EndIf

	EndIf

	If ( ! _lRet )
		// reinicia variaveis
		_cEtqVolume := Space(Len(_cEtqVolume))
		// foco na etiqueta de volume
		mvGetEtqVolume:SetFocus()
	EndIf

	// atualiza objetos da tela
	If (_lRet)
		// atualiza a quantidade de leitura
		RecLock("Z11")
		Z11->Z11_QTDLEI += 1
		Z11->(MsUnLock())
		// atualiza variaveis de controle
		_lNovoVolume := .f.
		// atualiza objetos
		mvGetEtqVolume:lReadOnly := ( ( ! _lCtrVolume ) .And. ( ! _lNovoVolume ) )
		// foco no objeto ID do produto
		mvGetIdProdut:SetFocus()
	EndIf

Return(_lRet)

// ** funcao que apresenta os detalhes do inventario no endereco
Static Function sfDetEndereco()

	// variavel de retorno
	local _lRet := .t.

	// variaveis do browse
	local _cQuery := ""
	local _aColsDet := {}
	local _aHeadDet := {}

	// objetos
	local _oDlgDetEnd
	local _oPnlCabec
	local _oBmpSair
	local _oBrwDetEnd

	// visualizar por volume
	local _lVisVolume := .f.

	// total de volume
	local _nTotVolume := 0
	local _cChvVolume := ""

	// variaveis temporias
	local _nCont := 0

	// total de produtos
	local _nTotProd := 0

	// posicao de campos
	local _nPosVol := 0
	local _nPosQtd := 0

	// valida se o endereco foi informado
	If (_lRet) .And. (Empty(_cEtqEnder) .Or. Empty(_cEndereco))
		U_FtWmsMsg("É necessário informar a localização!","ATENCAO")
		Return(.f.)
	EndIf

	// solicita visualizacao por volume
	If (_lRet) .And. (_lCtrVolume) .And. (U_FtYesNoMsg("Visualizar por Volume?","ATENÇÃO"))
		_lVisVolume := .T.
	EndIf

	// define cabecalho do browse
	If (_lVisVolume) // por volume
		If ( ! _lEtqClient )
			aAdd(_aHeadDet,{"ID Volume"  ,"Z19_ETQVOL" , PesqPict("Z19", "Z19_ETQVOL"), TamSx3("Z19_ETQVOL")[1] ,0,Nil,Nil,"C",Nil,"R" })
		ElseIf ( _lEtqClient )
			aAdd(_aHeadDet,{"Etq.Cliente","Z19_ETQCLI" , PesqPict("Z19", "Z19_ETQCLI"), TamSx3("Z19_ETQCLI")[1] ,0,Nil,Nil,"C",Nil,"R" })
		EndIf
		// posicao de campos
		_nPosVol := Len(_aHeadDet)
	EndIf
	// demais campos
	aAdd(_aHeadDet,{"Cod.Produto","Z19_CODPRO" , PesqPict("Z19","Z19_CODPRO"), TamSx3("Z19_CODPRO")[1] ,                      0, Nil, Nil,"C",Nil,"R" })
	aAdd(_aHeadDet,{"Descrição"  ,"B1_DESC"    , PesqPict("SB1","B1_DESC")   , TamSx3("B1_DESC")[1]    ,                      0, Nil, Nil,"C",Nil,"R" })
	aAdd(_aHeadDet,{"Quantidade" ,"Z19_QUANT"  , _cMaskQuant                 , TamSx3("Z19_QUANT")[1]  , TamSx3("Z19_QUANT")[2], Nil, Nil,"N",Nil,"R" })
	// posicao de campos
	_nPosQtd := Len(_aHeadDet)

	// monta a query para buscar os dados
	_cQuery := " SELECT "
	// id de volume
	If (_lVisVolume)
		If ( ! _lEtqClient )
			_cQuery += " Z19_ETQVOL, "
		ElseIf ( _lEtqClient )
			_cQuery += " Z19_ETQCLI, "
		EndIf
	EndIf
	// demais campos
	_cQuery += " Z19_CODPRO, B1_DESC, SUM(Z19_QUANT) Z19_QUANT, "
	// controle de deletado
	_cQuery += " '.F.' AS IT_DEL "
	// itens invetariados
	_cQuery += " FROM "+RetSqlTab("Z19")
	// cad. de produtos
	_cQuery += " INNER JOIN "+RetSqlTab("SB1")+" ON "+RetSqlCond("SB1")+" AND B1_COD = Z19_CODPRO "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z19")
	// numero da OS
	_cQuery += " AND Z19_IDENT = '"+_cNumOrdSrv+"' "
	// armazem
	_cQuery += " AND Z19_LOCAL = '"+_cArmazem+"' "
	// endereco
	_cQuery += " AND Z19_ENDERE = '"+_cEndereco+"' "
	// validação da contagem
	_cQuery += " AND Z19_CONTAG = '" + _cNrCont + "' "
	// filtra somente dados do usuario logado
	If ( ! _lInvPadrao )
		_cQuery += " AND Z19_USER = '" + __cUserId + "' "
	EndIf
	// agrupamento
	_cQuery += " GROUP BY "
	// id de volume
	If (_lVisVolume)
		_cQuery += " Z19_ETQVOL, Z19_ETQCLI, "
	EndIf
	// demais campos
	_cQuery += " Z19_CODPRO, B1_DESC "
	// ordem de dados, por id de volume
	If (_lVisVolume)
		_cQuery += " ORDER BY 1 "
	EndIf

	memowrit("c:\query\twmsa014_sfDetEndereco.txt", _cQuery)

	// atualiza o vetor do browse
	_aColsDet := U_SqlToVet(_cQuery)

	// varre todos os itens
	For _nCont := 1 to Len(_aColsDet)
		// se visualizar por volume, calcula total de volume
		If (_lVisVolume)
			// valida id de volume
			If (_cChvVolume <> _aColsDet[_nCont][_nPosVol])
				// total
				_nTotVolume += 1
				// controle
				_cChvVolume := _aColsDet[_nCont][_nPosVol]
			EndIf
		EndIf

		// total de produtos
		_nTotProd += _aColsDet[_nCont][_nPosQtd]

	Next _nCont

	// inclui o total
	If (_lVisVolume)
		aAdd(_aColsDet,{"", AllTrim(Str(_nTotVolume))+" VOLUME(S)", "", _nTotProd, .f.})
	Else
		aAdd(_aColsDet,{"", "", _nTotProd, .f.})
	EndIf

	// monta o dialogo do inventário
	_oDlgDetEnd := MSDialog():New(000,000,(_aSizeDlg[2]),(_aSizeDlg[1]),"Detalhes por Endereços",,,.F.,,,,,,.T.,,,.T. )
	_oDlgDetEnd:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgDetEnd,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// -- BOTAO SAIR
	_oBmpSair := TBtnBmp2():New(000,000,035,001,"FINAL",,,,{|| _oDlgDetEnd:END() },_oPnlCabec,"Sair",,.T. )
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// browse com os detalhes do endereco
	_oBrwDetEnd := MsNewGetDados():New(000,000,400,400,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDet),'AllwaysTrue()','','AllwaysTrue()',_oDlgDetEnd,_aHeadDet,_aColsDet)
	_oBrwDetEnd:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	_oDlgDetEnd:Activate(,,,.F.,{|| .t. },,)

Return(.t.)

// ** função que retorna array com os tamanhos de volumes
Static Function sfRetTamCx(mvCodCli, mvLojCli)

	// query para consulta
	local _cQuery := ""
	// array pra retorno
	local _aTpCaixa := {}

	// posiciona no cadastro do cliente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
	If SA1->(dbSeek( xFilial("SA1")+mvCodCli+mvLojCli ))

		// consulto os tipos de estoque disponíveis na tabela
		_cQuery := "SELECT Z31_CODIGO +'='+Z31_DESCRI TAMCAIXA FROM " + RetSqlTab("Z31") + " WHERE " + RetSqlCond("Z31") + " AND Z31_SIGLA = '" + SA1->A1_SIGLA + "' ORDER BY Z31_CODIGO"

		// jogo os dados pro array
		_aTpCaixa := U_SqlToVet(_cQuery)
	EndIf

Return (_aTpCaixa)

// ** funcao para informar a informações adicionais(Quantidade,Palete Cliente,Lote) ** //
Static Function sfInfAdici()
	// controle para nao fechar a tela
	Local _lRetOk := .f.
	// objetos da tela
	local _oGetQtdSeg

	// reinicia segunda unidade de medida
	_nQtdSegUM := 1

	// monta a tela para informa a quantidade
	_oWndInfQuant := MSDialog():New(020,020,270,220,"Informações Adicionais",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlInfQtdCab := TPanel():New(000,000,nil,_oWndInfQuant,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlInfQtdCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpInfQtdOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRetOk := sfVldObg(), IIf(_lRetOk, _oWndInfQuant:End(), Nil) },_oPnlInfQtdCab,"Ok",,.T.)
	_oBmpInfQtdOk:Align := CONTROL_ALIGN_LEFT

	_oGetQuant   := TGet():New(025, 005, {|u| If(PCount()>0,_nQtdProd :=u,_nQtdProd )}, _oWndInfQuant, 060, 010, _cMaskQuant, {|| (sfVldQuant(2)) .And. (sfValIndAd("1")) },,,_oFnt02,,,.T.,"",,                                                    ,.F.,.F.,,.F.,.F.,"","_nQtdProd" ,,,,,,,"Quantidade ("+SB1->B1_UM+"):"   ,1)
	_oGetQtdSeg  := TGet():New(045, 005, {|u| If(PCount()>0,_nQtdSegUM:=u,_nQtdSegUM)}, _oWndInfQuant, 060, 010, _cMaskQuant, {|| (sfVldQuant(1)) .And. (sfValIndAd("2")) },,,_oFnt02,,,.T.,"",,{|| ! Empty(SB1->B1_SEGUM) }                        ,.F.,.F.,,.F.,.F.,"","_nQtdSegUM",,,,,,,"Qtd Seg UM ("+SB1->B1_SEGUM+"):",1)
	_oGetLotProd := TGet():New(065, 005, {|u| If(PCount()>0,_cEtqLote :=u,_cEtqLote )}, _oWndInfQuant, 060, 010, "@!"       , {|| sfValIndAd("3")                       },,,_oFnt02,,,.T.,"",,{|| (_lLotAtivo) .Or. (_lCtrLote) }                   ,.F.,.F.,,.F.,.F.,"","_cEtqLote" ,,,,,,,"Lote"                           ,1)
	_oGetVldLote := TGet():New(085, 005, {|u| If(PCount()>0,_dVldLote :=u,_dVldLote )}, _oWndInfQuant, 060, 010, ""         , {|| sfValIndAd("4")                       },,,_oFnt02,,,.T.,"",,{|| ((_lLotAtivo) .Or. (_lCtrLote)) .And. (_lCtrVld) },.F.,.F.,,.F.,.F.,"","_dVldLote" ,,,,,,,"Dt. Validade Lote"              ,1)
	_oGetPalCli  := TGet():New(105, 005, {|u| If(PCount()>0,_cPltClie :=u,_cPltClie )}, _oWndInfQuant, 060, 010, "@!"       , {|| sfValIndAd("5")                       },,,_oFnt02,,,.T.,"",,                                                    ,.F.,.F.,,.F.,.F.,"","_cPltClie" ,,,,,,,"Plt. Clie."                     ,1)

	If !(_lInfManual)
		_oGetQuant:Disable()
	EndIf

	If !(_lCtrLote)
		_oGetLotProd:Disable()
		_oGetVldLote:Disable()
	EndIf

	// ativacao da tela com validacao
	_oWndInfQuant:Activate(,,,.T.,{|| _lRetOk })

Return

// ** validade preenchimento de lote e data de validade
Static Function sfVldObg()

	If (Empty(_cEtqLote)) .And. (_lCtrLote)
		U_FtWmsMsg("O lote precisa ser informado.","Atenção")
		Return (.F.)
	EndIf

	If (Empty(_dVldLote)) .And. (_lCtrLote)
		U_FtWmsMsg("A validade do lote precisa ser informada.","Atenção")
		Return (.F.)
	EndIf

Return (.T.)


// ** função que valida dados adicionais ** //
Static Function sfValIndAd(mvCampoVal)

	Local _lRet        := .T.
	Default mvCampoVal := 0 //1=Quantidade | 2= Lote | 3= Data Validade Lote | 4=Palete Cliente

	// 1=Quantidade
	If (mvCampoVal == "1")

		If (_lInfManual)
			If _nQtdProd <= 0
				_lRet := .F.
				U_FtWmsMsg("Informar Quantidade Maior que 0 !","ATENCAO")
				_oGetQuant:SetFocus()
				Return(_lRet)
			EndIf
		EndIf

		// 2=Quantidade Seg UM
	ElseIf (mvCampoVal == "2")

		If (_lInfManual)
			If (_nQtdSegUM <= 0)
				_lRet := .F.
				U_FtWmsMsg("Informar Quantidade Maior que 0 !","ATENCAO")
				_oGetQuant:SetFocus()
				Return(_lRet)
			EndIf
		EndIf

		// 3=Lote
	ElseIf (mvCampoVal == "3")

		If (_lCtrLote)
			If Empty(_cEtqLote)
				_lRet := .F.
				U_FtWmsMsg("Obrigatório informar Lote !","ATENCAO")
				_oGetLotProd:SetFocus()
				Return(_lRet)
			EndIf
		EndIf

		// 4=Data Validade Lote
	ElseIf (mvCampoVal == "4")

		If (_lCtrLote)
			If Empty(_dVldLote)
				_lRet := .F.
				U_FtWmsMsg("Obrigatório informar Validade do Lote !","ATENCAO")
				_oGetVldLote:SetFocus()
				Return(_lRet)
			EndIf
		EndIf

		// 4=Palete Cliente
	ElseIf (mvCampoVal == "5")


	EndIf

Return(_lRet)

// ** função que retorna array que contem tipos de estoque
Static Function sfRetTpEstoque()

	// query para consulta
	local _cQuery := ""
	// array pra retorno
	local _aTpEstoque := {}

	// consulto os tipos de estoque disponíveis na tabela
	_cQuery := " SELECT Z34_CODIGO+'='+Z34_DESCRI TPESTOQUE from "+RetSqlTab("Z34")+" WHERE "+RetSqlCond("Z34")+" ORDER BY Z34_CODIGO"

	// jogo os dados pro array
	_aTpEstoque := U_SqlToVet(_cQuery)

Return (_aTpEstoque)

// ** funcao para informar o tipo de estoque retornando a descrição
Static Function sfAltTpEst()

	// objetos
	local _oWndAltTpEst
	local _oPnlInfTpEstCab
	local _oBmpInfTpEstOk
	local _oSayTpEst
	local _oCmbCodEst
	// controle para nao fechar a tela
	Local _lRetOk  := .f.
	// Variavel Temp. For
	Local _nX := 0

	// validacao de endereco livre
	If (_lInvPadrao) .And. ( ! _lNovoEnder ) .Or. ( ! Empty(_cEndereco) )
		// mensagem
		U_FtWmsMsg("Ainda há pallets em conferência para a OS e endereço informado! Finalize o pallet primeiro antes de mudar o tipo de estoque.","ATENCAO")
		// variavel de retorno
		_lRetOk := .f.
		// retorno
		Return(_lRetOk)
	EndIf

	// monta a tela para informa a quantidade
	_oWndAltTpEst := MSDialog():New(020,020,120,200,"Tipo de Estoque",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlInfTpEstCab := TPanel():New(000,000,nil,_oWndAltTpEst,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlInfTpEstCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpInfTpEstOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRetOk := .t., _oWndAltTpEst:End() },_oPnlInfTpEstCab,"Ok",,.T.)
	_oBmpInfTpEstOk:Align := CONTROL_ALIGN_LEFT

	// titulo
	_oSayTpEst := TSay():New(025,005,{||"Tp.Estoque:"},_oWndAltTpEst,,_oFnt02,.F.,.F.,.F.,.T.)
	// combo de opções de tipos de estoque carregados anteriormente
	_oCmbCodEst := TComboBox():New(035,005,{|u| If(PCount()>0, _cTpEstoque:=u,_cTpEstoque) },_aOpcoesEst,080,008,_oWndAltTpEst,,,,,,.T.,,"",,,,,,,_cTpEstoque)

	// ativacao da tela com validacao
	_oWndAltTpEst:Activate(,,,.T.,{|| _lRetOk })

	// caso o campo tenha sido preenchido, busca no array o correspondente e atualiza a label
	If (! Empty(_cTpEstoque))
		For _nX := 1 to Len(_aOpcoesEst)
			If (_cTpEstoque $ _aOpcoesEst[_nX])
				_cDescTpEstoque := _aOpcoesEst[_nX]
				_oSayCodEst:Refresh()
			EndIf
		Next
	EndIf

Return (.T.)

// ** funcao que pesquisa o palete pela etiqueta do produto
Static Function sfRetNrPalete(mvIdEtqPrd, mvEndere)
	// variavel de retorno
	local _cRetIdPal := Space(_nTamIdPal)
	local _cQryPlt

	// prepara query
	_cQryPlt := " SELECT DISTINCT Z16_ETQPAL "
	// composicao de palete
	_cQryPlt += " FROM "+RetSqlTab("Z16")
	// filtro padrao
	_cQryPlt += " WHERE "+RetSqlCond("Z16")

	If (_lEtqIdInt) // etiqueta interna
		_cQryPlt += " AND Z16_ETQPRD = '"+mvIdEtqPrd+"' "
	ElseIf (_lCtrVolume) // Agrupadora
		_cQryPlt += " AND Z16_ETQVOL = '"+_cEtqVolume+"' "
	EndIf

	// saldo na Z16 tem que ser maior que zero
	_cQryPlt += " AND Z16_SALDO != 0 "

	// endereco atual
	_cQryPlt += " AND Z16_ENDATU = '" +mvEndere+ "' "

	memowrit("c:\query\twmsa014_sfRetNrPalete.txt", _cQryPlt)

	// executa a query
	_cRetIdPal := U_FtQuery(_cQryPlt)

	If (Empty(_cRetIdPal))
		U_FtWmsMsg("ID Pallet não localizado! Leitura será registrada, mas indica divergência.","ATENÇÃO")
	EndIf

Return(_cRetIdPal)

// ** funcao que valida saldo fiscal
Static Function sfVldSldFiscal()
	// variavel de retorno
	local _lRet := .t.
	// query
	local _cQuery
	// dados fiscais
	local _aTmpSaldo := {}

	// query para consulta saldo do produto + lote
	_cQuery := " SELECT B8_PRODUTO, "
	_cQuery += "        B8_LOTECTL, "
	_cQuery += "        SUM(B8_SALDO) B8_SALDO, "
	// total conferido
	_cQuery += "        (SELECT Isnull(Sum(Z19_QUANT), 0) "
	_cQuery += "         FROM   " + RetSqlTab("Z19")
	_cQuery += "         WHERE  " + RetSqlCond("Z19")
	_cQuery += "                AND Z19_CODPRO = B8_PRODUTO "
	_cQuery += "                AND Z19_LOTCTL = B8_LOTECTL) SALDO_INVET "
	// saldo por lote
	_cQuery += " FROM   " + RetSqlTab("SB8")
	// filtro padrao
	_cQuery += " WHERE  " + RetSqlCond("SB8")
	_cQuery += "        AND B8_PRODUTO LIKE '" +_cCodProd+ "%' "
	_cQuery += "        AND B8_LOTECTL = '" +_cEtqLote+ "' "
	_cQuery += "        AND B8_SALDO != 0 "
	// agrupa dados
	_cQuery += " GROUP  BY B8_PRODUTO, "
	_cQuery += "           B8_LOTECTL "

	MemoWrit("c:\query\twmsa014_sfVldSldFiscal.txt", _cQuery)

	// atualiza saldo por produto + lote
	_aTmpSaldo := U_SqlToVet(_cQuery)

	// verifica se tem algum saldo fiscal
	If (Len(_aTmpSaldo) == 0)
		// mensagem
		U_FtWmsMsg("Não há saldo fiscal:" + CRLF + "Produto: " + AllTrim(_cCodProd) + CRLF + "Lote: " + AllTrim(_cEtqLote),"Saldo Fiscal")
		// variavel de retorno
		_lRet := .f.

	ElseIf (Len(_aTmpSaldo) != 0)

		// verifica sem tem saldo fiscal, mas o inventario ja consumiu tudo
		If ((_aTmpSaldo[1][3] - _aTmpSaldo[1][4]) < _nQtdProd)
			// mensagem
			U_FtWmsMsg("Atenção: O saldo fiscal já está comprometido:" + CRLF + "Produto: " + AllTrim(_cCodProd) + CRLF + "Lote: " + AllTrim(_cEtqLote),"Saldo Fiscal")
		EndIf

	EndIf

Return(_lRet)

// ** funcao para validar/confirmar o endereco de destino
Static Function sfConfDest()
	// controle de confirmacao da tela
	local _lFixaWnd := .f.
	// variavel de retorno
	local _lRet := .f.
	// objetos locais
	local _oWndEndDest
	local _oPnlEndDestCab, _oPnlEndDest
	local _oGetEndDest
	local _oBrwEndDest

	// define o header para detalhes do endereco
	local _aHeadEnd := {{"Endereço","IT_DETALHE" ,"" ,30,0,Nil,Nil,"C",Nil,"R",,,".F." }}
	local _aColsEnd := {}
	local _aBrwEnd  := {}

	// query update
	local _cUpdZ19
	local _cUpdZ21

	// zera variaveis
	_cIdEndDest := Space(_nTamIdPal)
	_cEndDesti  := Space(Len(_cEndDesti))

	// preencho o browse para indicar ao usuário qual endereço ele quer deixar a mercadoria
	aAdd(_aBrwEnd, {"Informe o endereço desejado!",.f.})
	_aColsEnd := aClone(_aBrwEnd)

	// apresenta tela para definir o endereco atual/origem
	_oWndEndDest := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Endereçamento",,,.F.,,,,,,.T.,,,.T. )
	_oWndEndDest:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlEndDestCab := TPanel():New(000,000,nil,_oWndEndDest,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlEndDestCab:Align:= CONTROL_ALIGN_TOP

	// cria o panel para o browse
	_oPnlDefEndBrw := TPanel():New(000,000,nil,_oWndEndDest,,.F.,.F.,,,100,100,.T.,.F.)
	_oPnlDefEndBrw:Align:= CONTROL_ALIGN_ALLCLIENT

	// browse com a listagem das OS's selecionadas
	_oBrwEndDest := MsNewGetDados():New(000,000,400,400,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsEnd),'AllwaysTrue()','','AllwaysTrue()',_oPnlDefEndBrw,_aHeadEnd,_aColsEnd)
	_oBrwEndDest:oBrowse:oFont := _oFnt04
	_oBrwEndDest:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// cria o panel para o campo de confirmacao do endereco
	_oPnlEndDest := TPanel():New(000,000,nil,_oWndEndDest,,.F.,.F.,,CLR_LIGHTGRAY,22,22,.T.,.F.)
	_oPnlEndDest:Align:= CONTROL_ALIGN_BOTTOM

	// confirmacao do endereco de origem
	_oGetEndDest := TGet():New(001,005,{|u| If(PCount()>0,_cIdEndDest:=u,_cIdEndDest)},_oPnlEndDest,050,010,_cMskEtiq,{|| Vazio().Or.sfVldEndDes(_cIdEndDest, @_lRet, _oWndEndDest, @_lFixaWnd) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIdEndDest",,,,,,,"Confirme o endereço:",1)

	// seta o foco no id palete
	_oGetEndDest:SetFocus()

	// ativa a tela
	_oWndEndDest:Activate(,,,.F.,{|| _lFixaWnd },,)

	// se validou, e dados de acordo, atualiza palete conferido para novo endereco
	If (_lRet)

		// update para trocar o endereco, para o novo informado
		_cUpdZ19 := " UPDATE " +RetSqlName("Z19")+ " SET Z19_ENDERE = '" + _cEndDesti + "', Z19_ETQEND = '" + _cIdEndDest + "' "
		_cUpdZ19 += " WHERE  Z19_FILIAL = '" + xFilial("Z19") + "' AND D_E_L_E_T_ = ' ' "
		_cUpdZ19 += "        AND Z19_IDENT  = '" + _cNumOrdSrv + "' "
		_cUpdZ19 += "        AND Z19_CONTAG = '"+ _cNrCont +"' "
		_cUpdZ19 += " 	     AND Z19_ENDERE = '" + _cEndereco + "' "
		_cUpdZ19 += " 	     AND Z19_USER   = '" + __cUserId + "' "

		// executa update
		If (TcSQLExec(_cUpdZ19) < 0)
			U_FtWmsMsg("*** ERRO NA ATUALIZACAO sfConfDest ***" +CRLF+CRLF+ TCSQLError() )
			MemoWrit("c:\query\twmsa014_sfConfDest_update_Z19_erro.txt",_cUpdZ19 +CRLF+CRLF+ TCSQLError())
		EndIf

		// update para informar a Z21 que o endereço já foi inventariado
		_cUpdZ21 := " UPDATE "+RetSqlName("Z21")+" SET Z21_CONTAG = 'S' "
		// filtro padrao
		_cUpdZ21 += " WHERE  Z21_FILIAL = '"+xFilial("Z21")+"' AND D_E_L_E_T_ = ' ' "
		// ordem de servico
		_cUpdZ21 += "        AND Z21_IDENT  = '" + _cNumOrdSrv + "' "
		// armazem
		_cUpdZ21 += "        AND Z21_LOCAL  = '" + _cArmazem + "' "
		// endereco
		_cUpdZ21 += "        AND Z21_LOCALI = '" + _cEndDesti + "' "
		// executa update
		If (TcSQLExec(_cUpdZ21) < 0)
			U_FtWmsMsg("*** ERRO NA ATUALIZACAO sfConfDest ***" +CRLF+CRLF+ TCSQLError() )
			MemoWrit("c:\query\twmsa014_sfConfDest_update_erro.txt",_cUpdZ21 +CRLF+CRLF+ TCSQLError())
		EndIf

	EndIf

Return(_lRet)

// ** funcao para validacao do id do endereco de destino
Static Function sfVldEndDes(mvIdEtq, mvContProc, mvWndOrig, mvFechaTela)
	// variavel de retorno
	local _lRet := .t.
	// query
	local _cQuery

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11")+mvIdEtq ))
			// mensagem
			U_FtWmsMsg("Endereço inválido!","ATENCAO")
			// varivel de controle
			_lRet := .f.
		EndIf
	EndIf

	// valida o tipo da etiqueta lida
	If (_lRet) .And. (Z11->Z11_TIPO != "02")
		// mensagem
		U_FtWmsMsg("Etiqueta de endereço inválida!","ATENCAO")
		// varivel de controle
		_lRet := .f.
	EndIf

	// atualiza endereco de destino
	If (_lRet)
		_cEndDesti := Z11->Z11_ENDERE
	EndIf

	// variavel de retorno para continuacao do processo
	mvContProc := _lRet
	// permite fechar a tela
	mvFechaTela := _lRet

	// se existir o objeto, fecha
	If (mvWndOrig <> nil) .And. (_lRet)
		mvWndOrig:End()
	EndIf

Return(_lRet)


// ** funcao especifica para o cliente klabin, no inventario inicial, para atualizar informacoes de lote conforme planilha encaminahda pelo cliente
Static Function sfLoteKlabin(mvQtdKlab)
	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaZ11 := Z11->(GetArea())

	// query
	local _cQuery
	// dados da planilha Klabin
	local _aTmpDados

	//controle de processamento
	local _lRetKlab := .T.

	// monta query para buscar dados da planilha Klabin
	_cQuery := "SELECT Z_LOTE,  "    // 1
	_cQuery += "       Z_QUANT, "    // 2
	_cQuery += "       F1_TIPO, "    // 3
	_cQuery += "       F1_DOC, "     // 4
	_cQuery += "       F1_SERIE, "   // 5
	_cQuery += "       F1_FORNECE, " // 6
	_cQuery += "       F1_LOJA, "    // 7
	_cQuery += "       D1_COD, "     // 8
	_cQuery += "       D1_ITEM, "    // 9
	_cQuery += "       D1_IDENTB6, " // 10
	_cQuery += "       F1_PROGRAM "  // 11
	_cQuery += "FROM   TMP_LOTE_KLABIN "
	_cQuery += "       INNER JOIN "+RetSqlTab("SF1")
	_cQuery += "               ON "+RetSqlCond("SF1")
	_cQuery += "                  AND F1_DOC = Z_NOTA "
	_cQuery += "                  AND F1_LOJA = Z_LOJA "
	_cQuery += "                  AND F1_FORNECE = '"+_cCodCliFor+"' "
	_cQuery += "       INNER JOIN "+RetSqlTab("SD1")
	_cQuery += "               ON "+RetSqlCond("SD1")
	_cQuery += "                  AND D1_DOC = Z_NOTA "
	_cQuery += "                  AND D1_LOJA = Z_LOJA "
	_cQuery += "                  AND D1_FORNECE = '"+_cCodCliFor+"' "
	_cQuery += "                  AND D1_COD = Z_PRODUTO "
	_cQuery += "WHERE  Z_LOTE = '" + _cEtqLote + "' "
	_cQuery += "AND Z_DATA = (select max(z_data) from tmp_lote_klabin where z_lote = '" + _cEtqLote + "')"

	memowrit("c:\query\twmsa014_sfLoteKlabin.txt", _cQuery)

	// atualiza variavel
	_aTmpDados := U_SqlToVet(_cQuery)

	// se nao encontrou dados
	If (Len(_aTmpDados) == 0)
		U_FtWmsMsg("Dados não encontrados. Anotar lote, quantidade e número da etiqueta para informar setor de atendimento.","ATENCAO")
		_lRetKlab := .F.

	ElseIf (Len(_aTmpDados) > 1)
		U_FtWmsMsg("Duplicidade detectada! Anotar lote, quantidade e número da etiqueta para informar setor de atendimento.","ATENCAO")
		_lRetKlab := .F.

	ElseIf (Len(_aTmpDados) == 1)

		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If Z11->(dbSeek( xFilial("Z11")+_cEtiqProd ))

			// atualiza dados
			RecLock("Z11")
			Z11->Z11_TIPO   := "01" // 01 - PRODUTO
			Z11->Z11_CLIENT	:= _aTmpDados[1][ 6]
			Z11->Z11_LOJA	:= _aTmpDados[1][ 7]
			Z11->Z11_TIPONF	:= _aTmpDados[1][ 3]
			Z11->Z11_DOC	:= _aTmpDados[1][ 4]
			Z11->Z11_SERIE	:= _aTmpDados[1][ 5]
			Z11->Z11_ITEMNF	:= _aTmpDados[1][ 9]
			Z11->Z11_CODPRO	:= _aTmpDados[1][ 8]
			Z11->Z11_NUMSEQ	:= _aTmpDados[1][10]
			Z11->Z11_PROCES	:= _aTmpDados[1][11]
			Z11->(MsUnLock())

			// atualiza codigo do produto
			_cCodProd := _aTmpDados[1][ 8]
			mvQtdKlab := Val(_aTmpDados[1][ 2])

			DbSelectArea("SB1")
			DbSetOrder(1)
			If ( ! DBSeek(xFilial("SB1") + _cCodProd))
				U_FtWmsMsg("Produto não cadastrado! Anotar lote, quantidade e número da etiqueta para informar setor de atendimento.","ATENCAO")
				_lRetKlab := .F.
			EndIf
		EndIf
	EndIf

	// restaura area inicial
	RestArea(_aAreaZ11)
	RestArea(_aAreaAtu)

Return ( _lRetKlab )