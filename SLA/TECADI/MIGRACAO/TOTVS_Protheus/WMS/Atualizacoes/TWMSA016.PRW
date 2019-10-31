#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para operacao de movimentacao de veiculos (CESV) !
!                  ! - Chamada a partir da rotina TWMSA009/TACDA002          !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 10/2012 !
+------------------+---------------------------------------------------------+
!Observacoes       ! A variavel mvFilCar é usada para definir a rotina de    !
!                  ! carregamento                                            !
+------------------+--------------------------------------------------------*/

User Function TWMSA016(mvTpOper, mvConfTela)

	// variavel de retorno
	local _lRet := .F.

	// objetos da tela
	local _oW01FilVei
	local _oP01ParamCab
	local _oB01Ok, _oB01Sair
	local _oScr01Filtro
	local _oG01IdCesv, _oG01Placa

	// valores padroes
	Default mvTpOper   := ""
	Default mvConfTela := .F.

	// ID etiqueta
	private _nTamIdEtq  := TamSx3("Z11_CODETI")[1]
	private _cIdEtqCesv := Space(_nTamIdEtq)

	// numero do CESV
	private _cNrCesv := CriaVar("ZZ_CESV", .F.)

	// placa do veiculo
	private _cPlaca1    := CriaVar("ZZ_PLACA1", .F.)

	// tipo da operacao
	private _cTipoOper := mvTpOper

	// monta a tela para informar os filtros para pesquisa do veiculo
	_oW01FilVei := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Filtro Veículos",,,.F.,,,,,,.T.,,,.T. )
	_oW01FilVei:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oP01ParamCab := TPanel():New(000,000,nil,_oW01FilVei,,.F.,.F.,,,22,22,.T.,.F.)
	_oP01ParamCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oB01Ok := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRet := .T., _oW01FilVei:End() }, _oP01ParamCab, "Confirmar",,.T.)
	_oB01Ok:Align := CONTROL_ALIGN_LEFT

	// -- SAIR
	_oB01Sair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _lRet := .F., _oW01FilVei:End() }, _oP01ParamCab, "Sair",,.T.)
	_oB01Sair:Align := CONTROL_ALIGN_RIGHT

	// scroll principal com todos as campos disponiveis
	_oScr01Filtro := TScrollBox():New(_oW01FilVei, 000, 000, _aSizeDlg[2], _aSizeDlg[1], .T., .T., .T.)
	_oScr01Filtro:Align := CONTROL_ALIGN_ALLCLIENT

	// id etiqueta cesv
	_oG01IdCesv := TGet():New(002, 002, {|u| If(PCount()>0,_cIdEtqCesv:=u, _cIdEtqCesv)}, _oScr01Filtro, 050, 010, PesqPict("Z11", "Z11_CODETI"), {|| (Vazio()) .Or. (sfVldIdMov()) },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIdEtqCesv" ,,,,,,,"Etiqueta do Veículo", 1)

	// placa
	_oG01Placa  := TGet():New(024, 002, {|u| If(PCount()>0,_cPlaca1   :=u, _cPlaca1   )}, _oScr01Filtro, 040, 010, PesqPict("SZZ", "ZZ_PLACA1") , {|| (Vazio()) .Or. (ExistCpo("DA3")) },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cPlaca1"    ,,,,,,,"Placa do Veículo"   , 1)

	// ativa a tela
	_oW01FilVei:Activate(,,,.F.,,,)

	// se for confirmado, chama tela com dados filtrados
	If ( _lRet )

		// tela principal com os veiculos disponiveis
		_lRet := U_WMSA016B(mvTpOper, mvConfTela)

	EndIf

Return( _lRet )

// ** tela principal com os veiculos disponiveis
User Function WMSA016B(mvTpOper, mvConfTela)
	// variaveis do browse
	local _aHeadVeic := {}
	local _aColsVeic := {}

	// variavel de retorno
	local _lRet := .T.

	// objetos da tela - local
	local _oWndVeiculos
	local _oPnlVeicCab
	local _oBmpVeicConf, _oBmpVeicSair

	private _nPosCesv  := 0
	private _nPosOper  := 0
	private _nPosDoca  := 0
	private _nPosCarga := 0
	
	// numero do CESV
	private _cNrCesv := CriaVar("ZZ_CESV", .F.)

	// placa do veiculo
	private _cPlaca1    := CriaVar("ZZ_PLACA1", .F.)

	// tipo da operacao
	private _cTipoOper := mvTpOper
	

	// objetos da tela - private
	private _oBrwDetVeic

	// define header
	aAdd(_aHeadVeic,{"Nr CESV"    ,"ZZ_CESV"   , ""                         ,TamSx3("ZZ_CESV")[1]   ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadVeic,{"Operação"   ,"ZZ_DSCOPER", ""                         ,16                     ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadVeic,{"Entrada"    ,"ZZ_ENTRAD" , ""                         ,16                     ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadVeic,{"Status"     ,"ZZ_DSCSTAT", ""                         ,40                     ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadVeic,{"Cliente"    ,"A1_NOME"   , ""                         ,TamSx3("A1_NOME")[1]   ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadVeic,{"Transp."    ,"A4_NREDUZ" , ""                         ,TamSx3("A4_NREDUZ")[1] ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadVeic,{"Placa 1"    ,"ZZ_PLACA1" , PesqPict("DA3","DA3_COD")  ,TamSx3("ZZ_PLACA1")[1] ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadVeic,{"Container 1","ZZ_CNTR01" , PesqPict("SZC","ZC_CODIGO"),TamSx3("ZZ_CNTR01")[1] ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadVeic,{"Motorista"  ,"DA4_NOME"  , ""                         ,TamSx3("DA4_NOME")[1]  ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadVeic,{"Processo"   ,"ZZ_PROCES" , ""                         ,TamSx3("ZZ_PROCES")[1] ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadVeic,{"Doca"       ,"ZZ_DOCA"   , ""                         ,TamSx3("ZZ_DOCA")[1]   ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadVeic,{"Carga"      ,"ZZ_CARGA"   , ""                        ,TamSx3("ZZ_CARGA")[1]   ,0,Nil,Nil,"C",Nil,"R" })

	// posicao dos campos no browse
	_nPosCesv  := aScan(_aHeadVeic,{|x| AllTrim(x[2])=="ZZ_CESV"})    //
	_nPosOper  := aScan(_aHeadVeic,{|x| AllTrim(x[2])=="ZZ_DSCOPER"}) //
	_nPosDoca  := aScan(_aHeadVeic,{|x| AllTrim(x[2])=="ZZ_DOCA"})    //
	_nPosCarga := aScan(_aHeadVeic,{|x| AllTrim(x[2])=="ZZ_CARGA"})   //

	// selecionado os dados
	_aColsVeic := sfSelDados(mvConfTela)

	// definicao da tela de consultas
	_oWndVeiculos := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"WMS - Veículos",,,.F.,,,,,,.T.,,,.T. )

	// -- painel com as opcoes disponiveis
	_oPnlVeicCab := TPanel():New(000,000,nil,_oWndVeiculos,,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlVeicCab:Align:= CONTROL_ALIGN_TOP
	_oPnlVeicCab:nClrPane := CLR_HGRAY

	// habilita botao para confirmacao
	If (mvConfTela)
		// -- CONFIRMACAO
		_oBmpVeicConf := TBtnBmp2():New(000,000,030,030,"OK",,,,{|| (_lRet := Len(_oBrwDetVeic:aCols) > 0), _oWndVeiculos:End() },_oPnlVeicCab,"Ok",,.T.)
		_oBmpVeicConf:Align := CONTROL_ALIGN_LEFT
	EndIf

	// -- BOTAO SAIR
	_oBmpVeicSair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _lRet := .F., _oWndVeiculos:End() },_oPnlVeicCab,"Sair",,.T.)
	_oBmpVeicSair:Align := CONTROL_ALIGN_RIGHT

	// browse com os detalhes da consulta
	_oBrwDetVeic := MsNewGetDados():New(000,000,000,000,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsVeic),'AllwaysTrue()','','AllwaysTrue()',_oWndVeiculos,_aHeadVeic,_aColsVeic)
	_oBrwDetVeic:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwDetVeic:oBrowse:oFont := _oFnt02
	_oBrwDetVeic:oBrowse:blDblClick := {|| IIf( mvConfTela, _oBmpVeicConf:Click(), Nil)  }

	_oBrwDetVeic:SetArray(_aColsVeic ,.T. )
	_oBrwDetVeic:oBrowse:Refresh()
	_oBrwDetVeic:ForceRefresh()

	// ativa a tela
	ACTIVATE MSDIALOG _oWndVeiculos


	// confirmacao da tela
	If (_lRet) .And. (Len(_oBrwDetVeic:aCols)>0) .And. (_oBrwDetVeic:nAt > 0)

		// chama a funcao com detalhes do CESV
		_lRet := U_WMSA016A(_oBrwDetVeic:aCols[_oBrwDetVeic:nAt][1], .T.)

	EndIf

Return(_lRet)

// ** funcao para varificar se tem Nota Vinculada. Se estiver Nonta Vinculada ao CESV gera Ordem de serviçp.
Static Function sfGerOSCol(mvCesv,mvOperacao,mvCarga,mvDoca)

	// seek
	local _cSeekZ04

	// documentos vinculados por CESV
	dbSelectArea("Z04")
	Z04->(dbOrderNickName("Z04_CESV")) // Z04_FILIAL, Z04_CESV
	If(Z04->(dbSeek( _cSeekZ04 := xFilial("Z04")+mvCesv )))
		If Alltrim(mvOperacao) == "RECEBIMENTO"
			mvOperacao := '01'
		ElseIf Alltrim(mvOperacao) == "EXPEDIÇÃO"
			mvOperacao := '02'
		EndIf
		U_WMSA009B(mvCesv,mvOperacao,mvCarga,mvDoca, Nil, .F., "003")
	Else
		U_FtWmsMsg("CESV sem nota Vinculada !","ATENCAO")
	EndIF

Return()

// ** funcao para pesquisar a etiqueta e atualizar os detalhes
Static Function sfVldIdMov()

	// variavel de retorno
	local _lRet := .T.

	// pesquisa a existencia da etiqueta
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ( ! Z11->(dbSeek( xFilial("Z11") + _cIdEtqCesv )) )
			// mensagem para usuario
			U_FtWmsMsg("Etiqueta Inválida!", "ATENCAO")
			// retorno
			_lRet := .F.
		EndIf
	EndIf

	// valida tipo da etiqueta
	If (_lRet)
		// tipo etiqueta 06-VEICULO/TRANSPORTADORA
		If (Z11->Z11_TIPO != "06") // 06-VEICULO/TRANSPORTADORA
			// mensagem para usuario
			U_FtWmsMsg("Tipo da Etiqueta inválida!","ATENCAO")
			// retorno
			_lRet := .F.
		EndIf
	EndIf

	// pesquisa os dados do CESV
	If (_lRet)
		// registro do CESV
		dbSelectArea("SZZ")
		SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
		// pesquisa CESV
		If ( ! SZZ->(dbSeek( xFilial("SZZ") + Z11->Z11_CESV )) )
			// mensagem para usuario
			U_FtWmsMsg("Movimentação de veículo não encontrada!","ATENCAO")
			// retorno
			_lRet := .F.
		Else
			// atualiza numero do CESV
			_cNrCesv := Z11->Z11_CESV

		EndIf
	EndIf

Return( _lRet )

// ** funcao para selecionar os dados
Static Function sfSelDados(mvFilCar)
	// variavel de retorno
	local _aRetCols := {}
	local _cQrySZZ

	// busca as movimentacoes
	_cQrySZZ := "SELECT ZZ_CESV, "
	// operacao
	_cQrySZZ += "CASE "
	_cQrySZZ += "  WHEN ZZ_OPERACA = '01' THEN 'RECEBIMENTO' "
	_cQrySZZ += "  WHEN ZZ_OPERACA = '02' THEN 'EXPEDIÇÃO' "
	_cQrySZZ += "  WHEN ZZ_OPERACA = '03' THEN 'CROSS-DOCKING' "
	_cQrySZZ += "  ELSE 'A DEFINIR' "
	_cQrySZZ += "END ZZ_DSCOPER, "
	// data e hora de entrada
	_cQrySZZ += "CASE WHEN ZZ_DTENT != ' ' THEN CONVERT(VARCHAR(10),CAST(ZZ_DTENT AS DATETIME),103)+' '+ZZ_HRENT ELSE '' END ZZ_ENTRAD, "
	// codigo e descricao do status
	_cQrySZZ += "CASE "
	_cQrySZZ += "  WHEN ZZ_STATUS = '01' THEN 'AGUARDANDO LIBERACAO' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '02' THEN 'VEICULO LIBERADO / NO PATIO' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '03' THEN 'EM INSPECAO' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '04' THEN 'DOCA DEFINIDA' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '05' THEN 'LIBERADO PARA OPERACAO' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '06' THEN 'EM PLANEJAMENTO' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '07' THEN 'EM OPERACAO' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '08' THEN 'INSPECAO EM ANALISE' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '09' THEN 'SAIDA LIBERADA' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '10' THEN 'REGISTRO DE SAIDA' "
	_cQrySZZ += "  ELSE '** SEM STATUS **' "
	_cQrySZZ += "END ZZ_DSCSTAT, "
	// cliente
	_cQrySZZ += "A1_NOME, "
	// transportadora
	_cQrySZZ += "A4_NREDUZ, ZZ_PLACA1, ZZ_CNTR01, DA4_NOME, "
	// processo ou pedido
	_cQrySZZ += "ZZ_PROCES, ZZ_DOCA, ZZ_CARGA, "
	// item NAO deletado
	_cQrySZZ += "'.F.' IT_DEL "

	// movimentacao de cargas
	_cQrySZZ += " FROM " + RetSqlTab("SZZ")

	// cad. da transportadora
	_cQrySZZ += " INNER JOIN " + RetSqlTab("SA4") + " ON " + RetSqlCond("SA4") + " AND A4_COD = ZZ_TRANSP "

	// cad. do cliente
	_cQrySZZ += " LEFT  JOIN " + RetSqlTab("SA1") + " ON " + RetSqlCond("SA1") + " AND A1_COD = ZZ_CLIENTE AND A1_LOJA = ZZ_LOJA "

	// cadastro de motoristas
	_cQrySZZ += " LEFT  JOIN " + RetSqlTab("DA4") + " ON " + RetSqlCond("DA4") + " AND DA4_COD = ZZ_MOTORIS "

	// filtro da movimentacoes
	_cQrySZZ += " WHERE " + RetSqlCond("SZZ")

	// filtra pelo numero do CESV
	If ( ! Empty(_cNrCesv) )
		_cQrySZZ += " AND ZZ_CESV = '" + _cNrCesv + "' "
	EndIf

	// filtra pela placa do veiculo
	If ( ! Empty(_cPlaca1) )
		_cQrySZZ += " AND ZZ_PLACA1 = '" + _cPlaca1 + "' "
	EndIf

	// quando a confirmação vier da tela de conferência, não pode mostrar os já liberados
	If (mvFilCar)
		// status
		_cQrySZZ += " AND ZZ_STATUS NOT IN ('09') "
	EndIf

	// status
	_cQrySZZ += " AND ZZ_STATUS NOT IN ('10') "

	// filtro conforme tipo da operacao
	If ( ! Empty(_cTipoOper) )
		// tipo da operacao
		_cQrySZZ += " AND ZZ_OPERACA = '" + _cTipoOper + "' "
	EndIf

	// ordem das informacoes
	_cQrySZZ += " ORDER BY ZZ_CESV"

	memowrit("c:\query\twmsa016_sfSelDados.txt",_cQrySZZ)

	// atualiza a variavel temporaria com os dados da query
	_aRetCols := U_SqlToVet(_cQrySZZ)

Return(_aRetCols)

// ** funcao que abre tela com os detalhes e opcoes de operacao
User Function WMSA016A(mvCESV, mvWndConf)

	// objetos da tela
	local _oWnd02CESV
	local _oPnl02Cabec
	local _oBmp02IniOk, _oBmp02Sair
	local _oBrw02CESV

	// variaveis do browse
	local _aHeadCESV := {}
	local _aColsCESV := {}

	// variavel de confirmacao
	local _lOk := .f.

	// valida o CESV
	If (Empty(mvCESV))
		// mensagem para usuario
		U_FtWmsMsg("Movimentação de veículo não informada!","ATENCAO")
		// retorno
		Return(_lOk)
	EndIf

	// registro do CESV
	dbSelectArea("SZZ")
	SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
	If ! SZZ->(dbSeek( xFilial("SZZ") + mvCESV ))
		// mensagem para usuario
		U_FtWmsMsg("Movimentação de veículo não encontrada!","ATENCAO")
		// retorno
		Return(_lOk)
	EndIf

	// define o header do browse
	aAdd(_aHeadCESV,{"Titulo"   ,"IT_TITULO", "",  10,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadCESV,{"Descrição","IT_DESCRI", "", 100,0,Nil,Nil,"C",Nil,"R" })

	// padroniza o detalhes
	aAdd(_aColsCESV,{"Nr. CESV"    ,SZZ->ZZ_CESV,.f.})
	aAdd(_aColsCESV,{"Dt. Entrada" ,DtoC(SZZ->ZZ_DTENT)+" "+SZZ->ZZ_HRENT,.f.})
	aAdd(_aColsCESV,{"Operação"    ,If(SZZ->ZZ_OPERACA=="01","RECEBIMENTO",If(SZZ->ZZ_OPERACA=="02","EXPEDIÇÃO","CROSS-DOCKING")),.f.})
	aAdd(_aColsCESV,{"Cliente"     ,SZZ->ZZ_CLIENTE+"/"+SZZ->ZZ_LOJA+"-"+AllTrim(Posicione("SA1",1, xFilial("SA1")+SZZ->(ZZ_CLIENTE+ZZ_LOJA),"A1_NOME")),.f.})
	aAdd(_aColsCESV,{"Transp."     ,SZZ->ZZ_TRANSP+"-"+AllTrim(Posicione("SA4",1, xFilial("SA4")+SZZ->ZZ_TRANSP,"A4_NREDUZ")),.f.})
	aAdd(_aColsCESV,{"Placa"       ,Transf(SZZ->ZZ_PLACA1,PesqPict("DA3","DA3_COD")),.f.})
	aAdd(_aColsCESV,{"Motorista"   ,SZZ->ZZ_MOTORIS+"-"+AllTrim(Posicione("DA4",1, xFilial("DA4")+SZZ->ZZ_MOTORIS,"DA4_NOME")),.f.})
	If (SZZ->ZZ_OPERACA=="01")
		aAdd(_aColsCESV,{"Programação",SZZ->ZZ_PROCES,.f.})
		aAdd(_aColsCESV,{"Container"  ,Transf(SZZ->ZZ_CNTR01,PesqPict("SZC","ZC_CODIGO")) + IIf(Empty(SZZ->ZZ_CNTR02),""," / "+Transf(SZZ->ZZ_CNTR02,PesqPict("SZC","ZC_CODIGO"))),.f.})
	EndIf
	aAdd(_aColsCESV,{"Doca"        ,SZZ->ZZ_DOCA,.f.})

	// definicao da tela de consultas
	_oWnd02CESV := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"WMS - Veículos",,,.F.,,,,,,.T.,,,.T. )

	// -- painel com as opcoes disponiveis
	_oPnl02Cabec := TPanel():New(000,000,nil,_oWnd02CESV,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnl02Cabec:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	If (mvWndConf)
		_oBmp02IniOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lOk := .T., _oWnd02CESV:End() },_oPnl02Cabec,"Ok",,.T.)
		_oBmp02IniOk:Align := CONTROL_ALIGN_LEFT
	EndIf

	// -- SAIR
	_oBmp02Sair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _oWnd02CESV:End() },_oPnl02Cabec,"Sair",,.T.)
	_oBmp02Sair:Align := CONTROL_ALIGN_RIGHT

	// browse com os detalhes do CESV
	_oBrw02CESV := MsNewGetDados():New(000,000,600,600,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsCESV),'AllwaysTrue()','','AllwaysTrue()',_oWnd02CESV,_aHeadCESV,_aColsCESV)
	_oBrw02CESV:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrw02CESV:oBrowse:oFont := _oFnt02
	_oBrw02CESV:oBrowse:blDblClick := {|| IIf( mvWndConf, _oBmp02IniOk:Click(), Nil)  }

	// ativa a tela
	ACTIVATE MSDIALOG _oWnd02CESV

Return(_lOk)
