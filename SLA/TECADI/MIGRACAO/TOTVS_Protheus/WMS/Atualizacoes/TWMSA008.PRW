#Include "Totvs.ch"
#Include "Protheus.ch"
#Include 'FWMVCDEF.CH'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Tela para controle de CESV-Controle de Entrada e Saida  !
!                  ! de Veiculos                                             !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 07/2012 !
+------------------+--------------------------------------------------------*/

User Function TWMSA008

	// dimensoes da tela
	local _aSizeDlg := MsAdvSize()
	// tempo de refresh (segundos)
	local _nSeconds := 30

	// objetos da tela
	local _oBmpExcCesv

	// campos do browse de movimentacao de caminhoes/cargas
	private _aHdMovCarga := {}
	private _cTrMovCarga := ""
	private _aStMovCarga := {}
	private _oBrwMovCarga
	private _cAlTrbMov := GetNextAlias()

	// fontes utilizadas
	Private oFntVerd18 := TFont():New("Verdana",,18,,.t.)

	// filtro para mostrar as saídas já realizadas
	private _lFiltra := .T.

	// busca dados
	sfRfrDados(.t.)

	// monta o dialogo do monitor
	_oDlgMntCESV := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Controle de CESV",,,.F.,,,,,,.T.,,,.T. )
	_oDlgMntCESV:lMaximized := .T.

	// cria o panel do cabecalho - botoes de operacao
	oPnlCabec := TPanel():New(000,000,nil,_oDlgMntCESV,,.F.,.F.,,,000,030,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// INICIO - botoes de operacoes

	// -- chegada de veiculo
	_oBmpCheVeic := TBtnBmp2():New(001,001,040,040,"TMSIMG32",,,,{|| sfCheVeiculo() },oPnlCabec,"Chegada de Veículo",,.T. )
	_oBmpCheVeic:Align := CONTROL_ALIGN_LEFT
	// -- libera entrada
	_oBmpLibEntr := TBtnBmp2():New(001,001,040,040,"SVD",,,,{|| sfLibEntrada(), sfRfrDados(.f.) },oPnlCabec,"Libera Entrada",,.T. )
	_oBmpLibEntr:Align := CONTROL_ALIGN_LEFT
	// -- definicao da doca
	_oBmpDefDoca := TBtnBmp2():New(001,001,040,040,"DBG07",,,,{|| U_WMSA008B((_cAlTrbMov)->ZZ_CESV) , sfRfrDados(.f.) },oPnlCabec,"Define a Doca",,.T. )
	_oBmpDefDoca:Align := CONTROL_ALIGN_LEFT
	// -- libera saida
	_oBmpLibSaid := TBtnBmp2():New(001,001,040,040,"FINALIZA",,,,{|| U_WMSA008C( (_cAlTrbMov)->ZZ_CESV ), sfRfrDados(.f.) },oPnlCabec,"Libera Saída",,.T. )
	_oBmpLibSaid:Align := CONTROL_ALIGN_LEFT
	// -- saída de veiculo
	_oBmpSaiVeic := TBtnBmp2():New(001,001,040,040,"AVGARMAZEM",,,,{|| sfSaiVeiculo() , sfRfrDados(.f.) },oPnlCabec,"Saída de Veículo",,.T. )
	_oBmpSaiVeic:Align := CONTROL_ALIGN_LEFT
	// -- refresh dos dados
	_oBmpRefresh := TBtnBmp2():New(001,001,040,040,"RELOAD",,,,{|| sfRfrDados(.f.) },oPnlCabec,"Refresh",,.T. )
	_oBmpRefresh:Align := CONTROL_ALIGN_LEFT
	// -- botão filtro de saídas já realizadas
	_oBmpFiltro := TBtnBmp2():New(001,001,040,040,"FILTRO",,,,{|| sfFiltSaida(), sfRfrDados(.f.) },oPnlCabec,"Filtro de saídas já realizadas",,.T. )
	_oBmpFiltro:Align := CONTROL_ALIGN_LEFT
	// -- exclui CESV
	_oBmpExcCesv := TBtnBmp2():New(001,001,040,040,"EXCLUIR",,,,{|| U_WMSA008D( (_cAlTrbMov)->ZZ_CESV ), sfRfrDados(.f.) },oPnlCabec,"Excluir Cesv",,.T. )
	_oBmpExcCesv:Align := CONTROL_ALIGN_LEFT
	// -- estorna liberação da saída
	_oBmpEstLibSaid := TBtnBmp2():New(001,001,040,040,"LEFT",,,,{|| U_WMSA008F( (_cAlTrbMov)->ZZ_CESV ) , sfRfrDados(.f.) },oPnlCabec,"Estorna liberação do Veículo",,.T. )
	_oBmpEstLibSaid:Align := CONTROL_ALIGN_LEFT
	// -- estorno da saída de veiculo
	_oBmpEstSaiVeic := TBtnBmp2():New(001,001,040,040,"ESTOMOVI",,,,{|| sfEstSaiVeic() , sfRfrDados(.f.) },oPnlCabec,"Estorno Saída de Veículo",,.T. )
	_oBmpEstSaiVeic:Align := CONTROL_ALIGN_LEFT
	// -- botão sair
	_oBmpSair := TBtnBmp2():New(001,001,040,040,"FINAL",,,,{|| _oDlgMntCESV:End() },oPnlCabec,"Sair",,.T. )
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// FINAL - botoes de operacoes

	// browse com as movimentacoes de carga
	_oBrwMovCarga := MsSelect():New((_cAlTrbMov),,,_aHdMovCarga,,,{001,001,400,1000},,,_oDlgMntCESV)
	_oBrwMovCarga:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// temporizador/Refresh da tela
	_oTimeRefresh := TTimer():New((_nSeconds*1000), {||sfRfrDados(.f.)} ,_oDlgMntCESV)
	_oTimeRefresh:lActive := .T.

	// ativa a tela
	ACTIVATE MSDIALOG _oDlgMntCESV CENTERED

Return

//** funcao usada para atualizar os dados
Static Function sfRfrDados( mvFirst )
	Local lRet := .f.
	MsgRun("Atualizando a Tela do Monitor de Serviços...", "Aguarde...", {|| CursorWait(), lRet := sfSelDados( mvFirst ), CursorArrow()})
Return(lRet)

//** funcao para filtrar servicos de acordo com os parametros e configuracao do operador
Static Function sfSelDados(mvFirst)

	local _cQrySZZ

	// armazena o CESV posicionado
	local _nRecnoTRB := 0

	// abre o alias
	dbSelectArea("SZZ")

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStMovCarga,{"ZZ_CESV"   ,"C", TamSx3("ZZ_CESV")[1],0})   ; aAdd(_aHdMovCarga,{"ZZ_CESV"   ,"","Nr CESV"         ,""})
		aAdd(_aStMovCarga,{"ZZ_OPERACA","C", TamSx3("ZZ_OPERACA")[1],0})
		aAdd(_aStMovCarga,{"ZZ_DSCOPER","C", 16,0})                     ; aAdd(_aHdMovCarga,{"ZZ_DSCOPER","","Operação"        ,""})
		aAdd(_aStMovCarga,{"ZZ_DTCHEG" ,"D", TamSx3("ZZ_DTCHEG")[1],0})
		aAdd(_aStMovCarga,{"ZZ_HRCHEG" ,"C", TamSx3("ZZ_HRCHEG")[1],0})
		aAdd(_aStMovCarga,{"ZZ_CHEGAD" ,"C", 16,0})                     ; aAdd(_aHdMovCarga,{"ZZ_CHEGAD" ,"","Chegada"         ,""})
		aAdd(_aStMovCarga,{"ZZ_DTENT"  ,"D", TamSx3("ZZ_DTENT")[1],0})
		aAdd(_aStMovCarga,{"ZZ_HRENT"  ,"C", TamSx3("ZZ_HRENT")[1],0})
		aAdd(_aStMovCarga,{"ZZ_ENTRAD" ,"C", 16,0})                     ; aAdd(_aHdMovCarga,{"ZZ_ENTRAD" ,"","Entrada"         ,""})
		aAdd(_aStMovCarga,{"ZZ_STATUS" ,"C", TamSx3("ZZ_STATUS")[1],0})
		aAdd(_aStMovCarga,{"ZZ_DSCSTAT","C", 40,0})                     ; aAdd(_aHdMovCarga,{"ZZ_DSCSTAT","","Status"          ,""})
		aAdd(_aStMovCarga,{"ZZ_CLIENTE","C", TamSx3("ZZ_CLIENTE")[1],0})
		aAdd(_aStMovCarga,{"ZZ_LOJA"   ,"C", TamSx3("ZZ_LOJA")[1],0})
		aAdd(_aStMovCarga,{"A1_NOME"   ,"C", TamSx3("A1_NOME")[1],0})   ; aAdd(_aHdMovCarga,{"A1_NOME"   ,"","Nome do Cliente" ,""})
		aAdd(_aStMovCarga,{"ZZ_LOCAL"  ,"C", TamSx3("ZZ_LOCAL")[1],0})  ; aAdd(_aHdMovCarga,{"ZZ_LOCAL"  ,"","Armazém"         ,""})
		aAdd(_aStMovCarga,{"ZZ_DOCA"   ,"C", TamSx3("ZZ_DOCA")[1],0})   ; aAdd(_aHdMovCarga,{"ZZ_DOCA"   ,"","Doca"            ,""})
		aAdd(_aStMovCarga,{"A4_NREDUZ" ,"C", TamSx3("A4_NREDUZ")[1],0}) ; aAdd(_aHdMovCarga,{"A4_NREDUZ" ,"","Transportadora"  ,""})
		aAdd(_aStMovCarga,{"ZZ_PLACA1" ,"C", TamSx3("ZZ_PLACA1")[1],0}) ; aAdd(_aHdMovCarga,{"ZZ_PLACA1" ,"","Placa 1"         ,PesqPict("DA3","DA3_COD")})
		aAdd(_aStMovCarga,{"ZZ_CNTR01" ,"C", TamSx3("ZZ_CNTR01")[1],0}) ; aAdd(_aHdMovCarga,{"ZZ_CNTR01" ,"","Container 1"     ,PesqPict("SZC","ZC_CODIGO")})
		aAdd(_aStMovCarga,{"DA4_NOME"  ,"C", TamSx3("DA4_NOME")[1],0})  ; aAdd(_aHdMovCarga,{"DA4_NOME"  ,"","Motorista"       ,""})
		aAdd(_aStMovCarga,{"ZZ_PROCES" ,"C", TamSx3("ZZ_PROCES")[1],0}) ; aAdd(_aHdMovCarga,{"ZZ_PROCES" ,"","Processo"        ,""})
		aAdd(_aStMovCarga,{"ZZ_ITPROC" ,"C", TamSx3("ZZ_PROCES")[1],0})
		aAdd(_aStMovCarga,{"ZZ_OBS"    ,"C", TamSx3("ZZ_OBS")[1],0})    ; aAdd(_aHdMovCarga,{"ZZ_OBS"    ,"","Observações"     ,""})

		// fecha alias do TRB
		If (Select(_cAlTrbMov)<>0)
			dbSelectArea(_cAlTrbMov)
			dbCloseArea()
		EndIf
		// criar um arquivo de trabalho
		_cTrMovCarga := CriaTrab(_aStMovCarga,.T.)
		dbUseArea(.T.,,_cTrMovCarga,(_cAlTrbMov),.F.,.F.)

	EndIf

	// armazena o CESV posicionado
	If ( ! mvFirst )
		_nRecnoTRB := (_cAlTrbMov)->(RecNo())
	EndIf

	// limpa o conteudo do TRB
	dbSelectArea(_cAlTrbMov)
	__DbZap()

	/*
	--- Possíveis STATUS do CESV e seu significado ---

	ZZ_STATUS = '01' ---> 'AGUARDANDO LIBERACAO'
	ZZ_STATUS = '02' ---> 'VEICULO LIBERADO / NO PATIO'
	ZZ_STATUS = '03' ---> 'DOCA DEFINIDA'
	ZZ_STATUS = '04' ---> 'EM INSPECAO'
	ZZ_STATUS = '05' ---> 'LIBERADO PARA OPERACAO'
	ZZ_STATUS = '06' ---> 'EM PLANEJAMENTO'
	ZZ_STATUS = '07' ---> 'EM OPERACAO'
	ZZ_STATUS = '08' ---> 'INSPECAO EM ANALISE'
	ZZ_STATUS = '09' ---> 'SAIDA LIBERADA'
	ZZ_STATUS = '10' ---> 'SAIDA JA REALIZADA'
	*/

	// busca as movimentacoes
	_cQrySZZ := "SELECT ZZ_CESV, "
	// operacao
	_cQrySZZ += "ZZ_OPERACA, "
	_cQrySZZ += "CASE "
	_cQrySZZ += "  WHEN ZZ_OPERACA = '01' THEN 'RECEBIMENTO' "
	_cQrySZZ += "  WHEN ZZ_OPERACA = '02' THEN 'EXPEDIÇÃO' "
	_cQrySZZ += "  WHEN ZZ_OPERACA = '03' THEN 'CROSS-DOCKING' "
	_cQrySZZ += "  ELSE 'A DEFINIR' "
	_cQrySZZ += "END ZZ_DSCOPER, "
	// data e hora de chegada
	_cQrySZZ += "ZZ_DTCHEG, ZZ_HRCHEG, CONVERT(VARCHAR(10),CAST(ZZ_DTCHEG AS DATETIME),103)+' '+ZZ_HRCHEG ZZ_CHEGAD, "
	// data e hora de entrada
	_cQrySZZ += "ZZ_DTENT, ZZ_HRENT, CASE WHEN ZZ_DTENT != '' THEN CONVERT(VARCHAR(10),CAST(ZZ_DTENT AS DATETIME),103)+' '+ZZ_HRENT ELSE '' END ZZ_ENTRAD, "
	// codigo e descricao do status
	_cQrySZZ += "ZZ_STATUS, "
	_cQrySZZ += "CASE "
	_cQrySZZ += "  WHEN ZZ_STATUS = '01' THEN 'AGUARDANDO LIBERACAO' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '02' THEN 'VEICULO LIBERADO / NO PATIO' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '03' THEN 'DOCA DEFINIDA' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '04' THEN 'EM INSPECAO' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '05' THEN 'LIBERADO PARA OPERACAO' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '06' THEN 'EM PLANEJAMENTO' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '07' THEN 'EM OPERACAO' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '08' THEN 'INSPECAO EM ANALISE' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '09' THEN 'SAIDA LIBERADA' "
	_cQrySZZ += "  WHEN ZZ_STATUS = '10' THEN 'SAIDA JA REALIZADA' "
	_cQrySZZ += "  ELSE '** SEM STATUS **' "
	_cQrySZZ += "END ZZ_DSCSTAT, "
	// cliente
	_cQrySZZ += "ZZ_CLIENTE, ZZ_LOJA, A1_NOME, "
	// local e doca
	_cQrySZZ += "ZZ_LOCAL, ZZ_DOCA, "
	// transportadora
	_cQrySZZ += "CASE WHEN A4_NREDUZ = ' ' THEN A4_NOME ELSE A4_NREDUZ END A4_NREDUZ, ZZ_PLACA1, ZZ_CNTR01, DA4_NOME, "
	// processo ou carga
	_cQrySZZ += "ZZ_PROCES, ZZ_ITPROC, "
	// observacao
	_cQrySZZ += "ZZ_OBS "

	// movimentacao de cargas
	_cQrySZZ += "FROM "+RetSqlName("SZZ")+" SZZ "
	// cad. da transportadora
	_cQrySZZ += "INNER JOIN "+RetSqlName("SA4")+" SA4 ON "+RetSqlCond("SA4")+" AND A4_COD = ZZ_TRANSP "
	// cad. do cliente
	_cQrySZZ += "LEFT  JOIN "+RetSqlName("SA1")+" SA1 ON "+RetSqlCond("SA1")+" AND A1_COD = ZZ_CLIENTE AND A1_LOJA = ZZ_LOJA "
	// cadastro de motoristas
	_cQrySZZ += "LEFT  JOIN "+RetSqlName("DA4")+" DA4 ON "+RetSqlCond("DA4")+" AND DA4_COD = ZZ_MOTORIS "
	// filtro da movimentacoes
	_cQrySZZ += "WHERE "+RetSqlCond("SZZ")+" "
	// status
	IF ( !_lFiltra )    //se não deve filtrar o status 10 - saida ja realizada
		_cQrySZZ += "       AND ( ( ZZ_STATUS NOT IN ( '10' ) )
		_cQrySZZ += "              OR ( ZZ_STATUS = '10' AND ZZ_DTSAI >= '"+ DtoS(Date()-3)+"' ) ) "
	Else
		_cQrySZZ += "       AND ZZ_STATUS NOT IN ( '10' )
	Endif
	// ordem das informacoes
	_cQrySZZ += " ORDER  BY ZZ_CESV "

	memowrit("c:\query\twmsa008_sfSelDados.txt",_cQrySZZ)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQrySZZ,_aStMovCarga,(_cAlTrbMov))

	// abre o arquivo de trabalho
	If (_nRecnoTRB != 0)
		dbSelectArea(_cAlTrbMov)
		(_cAlTrbMov)->(dbGoTo(_nRecnoTRB))
	Else
		dbSelectArea(_cAlTrbMov)
		(_cAlTrbMov)->(dbGoTop())
	EndIf

	// refresh do browse
	If (_oBrwMovCarga <> nil)
		_oBrwMovCarga:oBrowse:Refresh()
	EndIf

Return(.t.)

//** funcao para registrar chegada de caminhoes
Static Function sfCheVeiculo()

	// dados do cliente
	Private _cCodCli	:= CriaVar("A1_COD",.f.)
	Private _cLojCli	:= CriaVar("A1_LOJA",.f.)
	Private _cNomCli	:= CriaVar("A1_NOME",.f.)

	// transportadora da mercadoria
	Private _cCodTransp	:= CriaVar("A4_COD",.f.)
	Private _cNomTransp	:= CriaVar("A4_NOME",.f.)

	// placas
	Private _cPlaca1 := _cPlaca2 := CriaVar("ZZ_PLACA1",.f.)

	// motorista
	Private _cCodMotor	:= CriaVar("DA4_COD",.f.)
	Private _cNomMotor	:= CriaVar("DA4_NOME",.f.)

	// container
	Private _cCntr01	:= CriaVar("ZC_CODIGO",.f.)
	Private _cCntr02	:= CriaVar("ZC_CODIGO",.f.)

	// observacoes
	Private _cObserv	:= CriaVar("ZZ_OBS",.f.)

	// variaveis utilizadas na consulta padrao SZC
	private _lEntrada := .t.

	// opcoes de operacoes
	private _aTpOperacoes := {"01-RECEBIMENTO","02-EXPEDICAO","03-CROSS-DOCKING"}
	private _cTpOperacao := ""

	// definicao da tela
	_oDlgRegCESV := MSDialog():New(000,000,300,700,"Registra Chegada de Veículo",,,.F.,,,,,,.T.,,,.T. )

	// titulo
	_oSayTitulo := TSay():New(010,012,{||"Registro da Chegada de Veículo"},_oDlgRegCESV,,oFntVerd18 ,.F.,.F.,.F.,.T.,CLR_GREEN)

	// operacao
	_oSayTpOperacao := TSay():New(030,012,{||"Operação"},_oDlgRegCESV,,oFntVerd18,.F.,.F.,.F.,.T.)
	_oGetTpOperacao :=  TComboBox():New(028,080,{|u| If(PCount()>0,_cTpOperacao:=u,_cTpOperacao)},_aTpOperacoes,100,011,_oDlgRegCESV,,,,,,.T.,oFntVerd18,"",,,,,,,_cTpOperacao)

	// transportadora
	_oSayTransp := TSay():New(045,012,{||"Transportadora"},_oDlgRegCESV,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCodTransp := TGet():New(043,080,{|u| If(PCount()>0,_cCodTransp:=u,_cCodTransp)},_oDlgRegCESV,050,011,PesqPict("SA4","A4_COD"),{|| (Vazio()) .Or. (ExistCpo("SA4") .and. sfVldTransp()) },,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SA4","_cCodTransp",,)
	oGetNomTransp := TGet():New(043,135,{|u| If(PCount()>0,_cNomTransp:=u,_cNomTransp)},_oDlgRegCESV,200,011,,,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomTransp",,)
	oGetNomTransp:Disable()

	// placa 1 (cavalo)
	oSayPlaca1 := TSay():New(060,012,{||"Placa 1"},_oDlgRegCESV,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetPlaca1 := TGet():New(058,080,{|u| If(PCount()>0,_cPlaca1:=u,_cPlaca1)},_oDlgRegCESV,050,011,PesqPict("DA3","DA3_COD"),{|| Vazio() .Or. ExistCpo("DA3") },,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"DA3","_cPlaca1",,)

	// placa 2 (carreta)
	oSayPlaca2 := TSay():New(060,150,{||"Placa 2"},_oDlgRegCESV,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetPlaca2 := TGet():New(058,198,{|u| If(PCount()>0,_cPlaca2:=u,_cPlaca2)},_oDlgRegCESV,050,011,PesqPict("DA3","DA3_COD"),{|| Vazio() .Or. ExistCpo("DA3") },,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"DA3","_cPlaca2",,)

	// motorista
	oSayMotor := TSay():New(075,012,{||"Motorista"},_oDlgRegCESV,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCodMotor := TGet():New(073,080,{|u| If(PCount()>0,_cCodMotor:=u,_cCodMotor)},_oDlgRegCESV,050,011,PesqPict("DA4","D4_COD"),{|| (Vazio()) .Or. (ExistCpo("DA4") .and. sfVldMotor()) },,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"DA4","_cCodMotor",,)
	oGetNomMotor := TGet():New(073,135,{|u| If(PCount()>0,_cNomMotor:=u,_cNomMotor)},_oDlgRegCESV,200,011,,,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomMotor",,)
	oGetNomMotor:Disable()

	// container 01
	oSayCntr01 := TSay():New(090,012,{||"Container 1"},_oDlgRegCESV,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCntr01 := TGet():New(088,080,{|u| If(PCount()>0,_cCntr01:=u,_cCntr01)},_oDlgRegCESV,080,011,PesqPict("SZC","ZC_CODIGO"),{|| Vazio() .Or. ExistCpo("SZC") },,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SZC","_cCntr01",,)
	//oGetCntr01:BWHEN := {|| (Left(_cTpOperacao,2)=="01") }

	// container 02
	oSayCntr02 := TSay():New(090,197,{||"Container 2"},_oDlgRegCESV,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCntr02 := TGet():New(088,255,{|u| If(PCount()>0,_cCntr02:=u,_cCntr02)},_oDlgRegCESV,080,011,PesqPict("SZC","ZC_CODIGO"),{|| Vazio() .Or. ExistCpo("SZC") },,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SZC","_cCntr02",,)
	oGetCntr02:BWHEN := {|| (Left(_cTpOperacao,2)=="01") }

	// observacao
	oSayObs := TSay():New(105,012,{||"Observação"},_oDlgRegCESV,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetObs := TGet():New(103,080,{|u| If(PCount()>0,_cObserv:=u,_cObserv)},_oDlgRegCESV,257,011,PesqPict("SZZ","ZZ_OBS"),,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cObserv",,)

	// botoes de opcoes
	_oBtnCheOk   := TButton():New(130,225,"Confirma",_oDlgRegCESV,{|| sfConfCheg()      },050,014,,oFntVerd18,,.T.,,"",,,,.F. )
	_oBtnCheSair := TButton():New(130,285,"Cancela",_oDlgRegCESV, {|| _oDlgRegCESV:End() },050,014,,oFntVerd18,,.T.,,"",,,,.F. )

	// ativa o dialogo
	_oDlgRegCESV:Activate(,,,.T.,)

Return

//** funcao que valida os dados da transportadora
Static Function sfVldTransp()
	// cadastro de transportadora
	dbSelectArea("SA4")
	SA4->(dbSetOrder(1)) //1-A4_FILIAL, A4_COD
	If (!SA4->(dbSeek( xFilial("SA4")+_cCodTransp )))
		U_FtWmsMsg("Transportadora não cadastrada!","ATENCAO")
		Return(.f.)
	EndIf
	// nome da transportadora
	_cNomTransp := SA4->A4_NOME
Return(.t.)

//** funcao que valida o dados do motorista
Static Function sfVldMotor()
	// cadastro de motoristas
	dbSelectArea("DA4")
	DA4->(dbSetOrder(1)) //1-DA4_FILIAL, DA4_COD
	If (!DA4->(dbSeek( xFilial("DA4")+_cCodMotor )))
		U_FtWmsMsg("Motorista não cadastrado!","ATENCAO")
		Return(.f.)
	EndIf
	// nome da transportadora
	_cNomMotor := DA4->DA4_NOME
Return(.t.)

//** funcao para confirmar a chegada do caminhao
Static Function sfConfCheg()

	// transportadora e motorista
	If (Empty(_cCodTransp)) .Or. (Empty(_cCodMotor))
		U_FtWmsMsg("Campos Obrigatórios -> Transportadora e Motorista","ATENCAO")
		Return(.f.)
	EndIf

	// placas
	If (Empty(_cPlaca1))
		U_FtWmsMsg("Campos Obrigatórios -> Placa 1","ATENCAO")
		Return(.f.)
	EndIf

	// confirmacao dos dados
	If ( ! MsgYesNo("Confirma Chegada do Caminhão ?", "Confirmação") )
		Return(.f.)
	EndIf

	// grava os dados da movimentacao
	dbSelectArea("SZZ")
	RecLock("SZZ",.t.)
	SZZ->ZZ_FILIAL	:= xFilial("SZZ")
	SZZ->ZZ_CESV	:= GetSxeNum("SZZ","ZZ_CESV", xFilial("SZZ"))
	SZZ->ZZ_DTCHEG	:= Date()
	SZZ->ZZ_HRCHEG	:= Left(Time(),5)
	SZZ->ZZ_CLIENTE	:= _cCodCli
	SZZ->ZZ_LOJA	:= _cLojCli
	SZZ->ZZ_STATUS	:= "01"
	SZZ->ZZ_TRANSP	:= _cCodTransp
	SZZ->ZZ_MOTORIS	:= _cCodMotor
	SZZ->ZZ_PLACA1	:= _cPlaca1
	SZZ->ZZ_PLACA2	:= _cPlaca2
	SZZ->ZZ_OBS		:= _cObserv
	SZZ->ZZ_USRINC	:= __cUserId
	SZZ->ZZ_CNTR01	:= _cCntr01
	SZZ->ZZ_CNTR02	:= _cCntr02
	SZZ->ZZ_OPERACA	:= Left(_cTpOperacao,2)
	SZZ->ZZ_CHAVE   := U_FtChvVld(Len(SZZ->ZZ_CHAVE), .f.)
	SZZ->(MsUnLock())

	// confirma a sequencia
	ConfirmSx8()

	// fecha a tela de apontamento
	_oDlgRegCESV:End()

	// refresh dos dados
	sfRfrDados(.f.)

Return

//** funcao para definicao da doca
User Function WMSA008B( mvCESV )
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SZZ"})
	// variaveis do browse
	local _aHeadDoca := {}
	local _aColsDoca := {}
	local _cQuery := ""
	// controle de confirmacao da tela
	local _lOk := .f.
	// armazem e endereco
	local _cCodArm := CriaVar("BE_LOCAL",.f.)
	local _cCodEnd := CriaVar("BE_LOCALIZ",.f.)

	// objetos
	local _oDlgDefDoca
	local _oPnlCabec1
	local _oBtnConfDoca, _oBtnCancDoca
	local _oBrwDefDoca

	// centraliza tela
	local _lDlgCenter := (Type("_aSizeDlg")=="U")
	// largura da tela
	local _nDlgLarg := If(Type("_aSizeDlg")=="U",190,(_aSizeDlg[1]-6 ))
	// altura da tela
	local _nDlgAltu := If(Type("_aSizeDlg")=="U",240,(_aSizeDlg[2]-20))

	// variavel do armazem padrão do cliente
	Local _cArmPadrao

	// registro do CESV
	dbSelectArea("SZZ")
	SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
	SZZ->(dbSeek( xFilial("SZZ") + mvCESV ))

	// valida o status o CESV (02-VEICULO LIBERADO / NO PATIO)
	If ( ! Empty(SZZ->ZZ_DOCA) ) .Or. ( ! (SZZ->ZZ_STATUS $ "02/06") )
		// mensagem
		U_FtWmsMsg("Definição de doca não permitida","ATENCAO")
		// restaura areas iniciais
		RestOrd(_aAreaIni)
		RestArea(_aArea)
		// retorno
		Return(.f.)
	EndIf

	_cArmPadrao  := U_FtWmsParam("WMS_ARMAZEM_POR_CLIENTE", "C", "", .F., xFilial("SZZ"), SZZ->ZZ_CLIENTE, SZZ->ZZ_LOJA, Nil, Nil)

	// monta a query
	_cQuery := " SELECT BE_LOCAL, BE_LOCALIZ, '.F.' IT_DEL "
	// cad. de enderecos
	_cQuery += " FROM "+RetSqlTab("SBE")
	// cad. estrutura fisica - tipo box/doca
	_cQuery += " INNER JOIN "+RetSqlTab("DC8")+" ON "+RetSqlCond("DC8")+" AND DC8_TPESTR = '5' AND DC8_CODEST = BE_ESTFIS "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("SBE")
	// status do endereco
	_cQuery += " AND BE_STATUS NOT IN ('3') "
	// somente do armazém padrão do cliente
	_cQuery += " AND BE_LOCAL = '" + _cArmPadrao + "'"
	// somente docas disponiveis
	_cQuery += " AND BE_LOCAL + BE_LOCALIZ NOT IN ("
	_cQuery += "   SELECT ZZ_LOCAL+ZZ_DOCA FROM "+RetSqlTab("SZZ")+" WHERE "+RetSqlCond("SZZ")+" AND ZZ_STATUS NOT IN ('10') AND ZZ_DOCA != ' ' "
	_cQuery += "   AND ZZ_DTENT = '"+DtoS(dDataBase)+"' "
	_cQuery += " ) "

	// ordem dos dados
	_cQuery += " ORDER BY BE_LOCAL, BE_LOCALIZ"

	// adiciona o conteudo da query para um array
	_aColsDoca := U_SqlToVet(_cQuery)

	memowrit("c:\query\twmsa008_sfDefDoca.txt",_cQuery)

	// caso nao tenha enderecos disponiveis
	If (Len(_aColsDoca) == 0)
		// mensagem
		U_FtWmsMsg("Não há docas disponíveis.","ATENCAO")
		// restaura areas iniciais
		RestOrd(_aAreaIni)
		RestArea(_aArea)
		// retorno
		Return(.f.)
	EndIf

	// define todos os campos do header
	aAdd(_aHeadDoca,{"Armazém"  ,"BE_LOCAL"   ,PesqPict("SBE","BE_LOCAL")  ,TamSx3("BE_LOCAL")[1]  ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDoca,{"Endereço" ,"BE_LOCALIZ" ,PesqPict("SBE","BE_LOCALIZ"),TamSx3("BE_LOCALIZ")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })

	// definicao da tela
	_oDlgDefDoca := MSDialog():New(000,000,_nDlgAltu,_nDlgLarg,"Define Doca de Operação",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlCabec1 := TPanel():New(000,000,nil,_oDlgDefDoca,,.F.,.F.,,,000,022,.T.,.F. )
	_oPnlCabec1:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBtnConfDoca := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lOk := .t., _oDlgDefDoca:End() },_oPnlCabec1,"Ok",,.T.)
	_oBtnConfDoca:Align := CONTROL_ALIGN_LEFT

	// -- BOTAO SAIR
	_oBtnCancDoca := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _oDlgDefDoca:End() },_oPnlCabec1,"Sair",,.T.)
	_oBtnCancDoca:Align := CONTROL_ALIGN_RIGHT

	// monta o browse
	_oBrwDefDoca := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDoca),'AllwaysTrue()','','AllwaysTrue()',_oDlgDefDoca,_aHeadDoca,_aColsDoca)
	_oBrwDefDoca:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa o dialogo
	_oDlgDefDoca:Activate(,,,(_lDlgCenter),,,)

	If (_lOk)
		// retorna o armazem
		_cCodArm := _oBrwDefDoca:aCols[_oBrwDefDoca:nAt][1]
		// retorna o endereco
		_cCodEnd := _oBrwDefDoca:aCols[_oBrwDefDoca:nAt][2]

		// posiciono no registro da agenda
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
		If SBE->( dbSeek( xFilial("SBE") + _cCodArm + _cCodEnd ) )

			// registro do CESV
			dbSelectArea("SZZ")
			SZZ->( dbSetOrder(1) ) //1-ZZ_FILIAL, ZZ_CESV
			SZZ->( dbSeek( xFilial("SZZ")+mvCESV ) )

			// atualiza as informacoes das tabelas
			dbSelectArea("SZZ")
			RecLock("SZZ")
			SZZ->ZZ_LOCAL	:= SBE->BE_LOCAL
			SZZ->ZZ_DOCA	:= SBE->BE_LOCALIZ

			// somente para operação de entrada é que muda o status
			If ( SZZ->ZZ_OPERACA == "01" )
				SZZ->ZZ_STATUS := "05" // 05-Liberado para operação
			EndIf

			// libera a transação
			SZZ->( MsUnLock() )

			// insere o log da transação para registro
			U_FtGeraLog( cFilAnt, "SZZ", xFilial("SZZ") + SZZ->ZZ_CESV, "Definida " + AllTrim(SBE->BE_LOCALIZ) + " para operação e veículo liberado para operação.", "WMS" )

		EndIf

	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni)
	RestArea(_aArea)

Return(_lOk)

//** funcao para liberar entrada do caminha e relacionar com agenda
Static Function sfLibEntrada()

	// dimensoes da tela
	local _aSizeDlg := MsAdvSize()

	// variaveis do browse
	local _aHeadAgd := {}
	local _aColsAgd := {}
	local _cQuery := ""
	local _lRetEst := .t.

	// validação de estorno
	local _lEstorna := .f.

	// valida o status o CESV
	If ( (_cAlTrbMov)->ZZ_STATUS != "01" ) .and. ( (_cAlTrbMov)->ZZ_STATUS != "02" )
		// mensagem para usuario
		U_FtWmsMsg("Liberação não permitida","ATENCAO")
		// retorno
		Return( .F. )
	EndIf

	// verifica se usuário quer estornar a liberação de entrada
	If ( (_cAlTrbMov)->ZZ_STATUS == "02")

		// solicita confirmacao do usuario
		_lEstorna := MsgYesNo("O veículo já encontra-se com status: VEICULO LIBERADO / NO PATIO. Deseja estornar a Liberação de Entrada?", "Estorno")

		// se quer estornar, prossegue chamando a rotina de estorno
		If ( _lEstorna )
			// chama função de processamento de estorno
			MsgRun("Estornando Registros de Entrada...", "Aguarde...", {|| CursorWait(),  _lRetEst := U_WMSA008E( (_cAlTrbMov)->ZZ_CESV ), CursorArrow()})

			// valida o retorno
			If ( _lRetEst )
				MsgInfo("Estorno da Liberação de Entrada efetuado!", "Info")
			Else
				MsgAlert("Estorno da Liberação de Entrada não realizado!", "Info")
			EndIf
		EndIf

		// volta pra tela anterior
		Return
	EndIf

	// monta a query
	_cQuery := " SELECT CONVERT(VARCHAR(10),CAST(ZY_DTINIC AS DATETIME),103)+' '+ZY_HRINIC ZY_INICIO, A1_NOME, ZY_PROCES, "
	// operacao
	_cQuery += " CASE "
	_cQuery += "   WHEN ZY_OPERACA = '01' THEN 'RECEBIMENTO' "
	_cQuery += "   WHEN ZY_OPERACA = '02' THEN 'EXPEDIÇÃO' "
	_cQuery += "   WHEN ZY_OPERACA = '03' THEN 'CROSS-DOCKING' "
	_cQuery += "   ELSE 'A DEFINIR' "
	_cQuery += " END ZY_DSCOPER, "
	// chave de agendamento
	_cQuery += " ZY_CHAVE, "
	// controle de item deletado
	_cQuery += " SZY.R_E_C_N_O_ SZYRECNO, '.F.' IT_DEL "
	// registros da agenda
	_cQuery += " FROM " + RetSqlTab("SZY")
	// cad. de cliente
	_cQuery += " LEFT  JOIN " + RetSqlTab("SA1") + " ON " + RetSqlCond("SA1") + " AND A1_COD = ZY_CLIENTE AND A1_LOJA = ZY_LOJA "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("SZY")
	// filtros
	_cQuery += " AND ZY_STATUS  = 'A' "
	// data
	_cQuery += " AND ZY_DTINIC  = '" + DtoS(dDataBase) + "' "
	// tipo da operacao
	_cQuery += " AND ZY_OPERACA = '" + (_cAlTrbMov)->ZZ_OPERACA + "' "

	// adiciona o conteudo da query para um array
	_aColsAgd := U_SqlToVet(_cQuery, {"ZY_DTINIC"})

	memowrit("c:\query\twmsa008_sfLibEntrada.txt",_cQuery)

	// define todos os campos do header
	aAdd(_aHeadAgd,{"Data Agenda" , "ZY_INICIO" , ""                         , 16                    , 0, Nil, Nil, "D", Nil, "R",,,".F." })
	aAdd(_aHeadAgd,{"Cliente"     , "A1_NOME"   , ""                         , TamSx3("A1_NOME")[1]  , 0, Nil, Nil, "C", Nil, "R",,,".F." })
	aAdd(_aHeadAgd,{"Processo"    , "ZY_PROCES" , ""                         , TamSx3("ZY_PROCES")[1], 0, Nil, Nil, "C", Nil, "R",,,".F." })
	aAdd(_aHeadAgd,{"Operação"    , "ZY_DSCOPER", ""                         , 15                    , 0, Nil, Nil, "C", Nil, "R",,,".F." })
	aAdd(_aHeadAgd,{"Chave Agenda", "ZY_CHAVE"  , PesqPict("SZY", "ZY_CHAVE"), TamSx3("ZY_CHAVE")[1] , 0, Nil, Nil, "C", Nil, "R",,,".F." })
	aAdd(_aHeadAgd,{"Recno"       , "SZYRECNO"  , ""                         , 10                    , 0, Nil, Nil, "N", Nil, "R",,,".F." })

	// definicao da tela
	_oDlgLibEntr := MSDialog():New(000,000,400,800,"Liberar Entrada de Veículo",,,.F.,,,,,,.T.,,,.T. )
	_oDlgLibEntr:lMaximized := .T.

	// cria o panel do cabecalho - botoes
	_oPnlCabec1 := TPanel():New(000,000,nil,_oDlgLibEntr,,.F.,.F.,,,000,030,.T.,.F. )
	_oPnlCabec1:Align:= CONTROL_ALIGN_TOP

	// botao cancelar
	_oBtnComAgenda := TButton():New(010, 010                  , "Com Agenda", _oPnlCabec1, {|| sfConfLib( .T. )   }, 050, 012,,,,.T.,,"",,,,.F. )
	_oBtnFechar    := TButton():New(010, ((_aSizeDlg[5]/2)-55), "Fechar"    , _oPnlCabec1, {|| _oDlgLibEntr:End() }, 050, 012,,,,.T.,,"",,,,.F. )

	// monta o browse
	_oBrwDetAgd := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsAgd),'AllwaysTrue()','','AllwaysTrue()',_oDlgLibEntr,_aHeadAgd,_aColsAgd)
	_oBrwDetAgd:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa o dialogo
	_oDlgLibEntr:Activate(,,,.T.,,, )

Return

//** funcao para liberar a entrada do veiculo no patio
Static Function sfConfLib(mvComAgenda)

	// RECNO do Agendamento
	local _nRecnoSZY := 0

	// dados adicionais
	local _cCodOpe    := ""
	local _cNrProc    := ""
	local _cItProc    := ""
	local _cCodCli    := ""
	local _cLojCli    := ""
	local _aPedSelect := {}
	local _nX         := 0
	local _cDtReg     := Date()
	local _cHrReg     := Time()

	// seek do Z05
	local _cSeekZ05

	// controle se a programacao de carregamento ocorreu no agendamento
	local _lProgAntec := .F.

	// operacao de atualizacao de registro
	local _lIncPlanej := .T.

	// define o recno e codigo da agenda
	If (Len(_oBrwDetAgd:aCols) > 0) .And. (mvComAgenda)
		// recno
		_nRecnoSZY := _oBrwDetAgd:aCols[_oBrwDetAgd:nAt][Len(_oBrwDetAgd:aHeader)]

		// teste agenda
		If (_nRecnoSZY == 0)
			// mensagem para usuario
			U_FtWmsMsg("Não há agenda disponível.","ATENCAO")
			// retorno
			Return( .F. )
		EndIf

		// posiciono no registro da agenda
		dbSelectArea("SZY")
		SZY->(dbGoTo(_nRecnoSZY))

		// dados adicionais
		_cCodOpe := SZY->ZY_OPERACA
		_cNrProc := SZY->ZY_PROCES
		_cItProc := SZY->ZY_ITPROC
		_cCodCli := SZY->ZY_CLIENTE
		_cLojCli := SZY->ZY_LOJA

		// define os dados adicionais
		If ((SZY->ZY_OPERACA == "01") .And. (Empty(SZY->ZY_PROCES))) .Or. (SZY->ZY_OPERACA == "02")

			// para expedicoes, verifica se ja foi configurado carga no agendamento
			If (SZY->ZY_OPERACA == "02")

				// funcao que busca planejamento de carga do agendamento
				_aPedSelect := sfCargaAge(SZY->ZY_SEQUENC)

				// atualiza controle se a programacao de carregamento ocorreu no agendamento
				_lProgAntec := (Len(_aPedSelect) != 0)

			EndIf

			// se nao tem pedidos planejados no agendamento, apresenta opcao para definicao de dados adicionais do CESV
			If (Len(_aPedSelect) == 0)
				// opcao para definicao de dados adicionais do CESV
				If ( ! sfDefDadAdic(_cCodOpe, @_cNrProc, @_cItProc, _cCodCli, _cLojCli, @_aPedSelect, .F.))
					Return( .F. )
				endIf
			EndIf

			// atualiza os dados da agenda
			dbSelectArea("SZY")
			RecLock("SZY")
			SZY->ZY_PROCES	:= _cNrProc
			SZY->ZY_ITPROC	:= _cItProc
			SZY->(MsUnLock())
		EndIf

		// sem agenda, define o cliente
	ElseIf ( ! mvComAgenda )

		// dados adicionais
		_cCodOpe := (_cAlTrbMov)->ZZ_OPERACA

		// define os dados adicionais
		If ( ! sfDefDadAdic(@_cCodOpe, @_cNrProc, @_cItProc, @_cCodCli, @_cLojCli, @_aPedSelect, .t.))
			Return(.f.)
		EndIf

	EndIf

	// registro do CESV
	dbSelectArea("SZZ")
	SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
	SZZ->(dbSeek( xFilial("SZZ")+(_cAlTrbMov)->ZZ_CESV ))

	// atualiza as informacoes das tabelas
	dbSelectArea("SZZ")
	RecLock("SZZ")
	SZZ->ZZ_DTENT	:= Date()
	SZZ->ZZ_HRENT	:= Left(Time(),5)
	SZZ->ZZ_STATUS	:= "02" // 02-VEICULO LIBERADO / NO PATIO

	// se for com agenda
	If (mvComAgenda) .And. (_nRecnoSZY > 0)
		SZZ->ZZ_AGENDA	:= SZY->ZY_SEQUENC
		SZZ->ZZ_CLIENTE	:= SZY->ZY_CLIENTE
		SZZ->ZZ_LOJA	:= SZY->ZY_LOJA
		SZZ->ZZ_PROCES	:= SZY->ZY_PROCES
		SZZ->ZZ_ITPROC	:= SZY->ZY_ITPROC
		SZZ->ZZ_CARGA   := SZY->ZY_CARGA

		// sem agenda
	ElseIf ( ! mvComAgenda )
		SZZ->ZZ_CLIENTE	:= _cCodCli
		SZZ->ZZ_LOJA	:= _cLojCli
		SZZ->ZZ_PROCES	:= _cNrProc
		SZZ->ZZ_ITPROC	:= _cItProc

	EndIf

	SZZ->(MsUnLock())

	// se for com agenda, atualiza os dados
	If (mvComAgenda) .And. (_nRecnoSZY > 0)
		dbSelectArea("SZY")
		RecLock("SZY")
		SZY->ZY_STATUS := "R"
		SZY->(MsUnLock())
	EndIf

	/* Composição do vetor _aPedSelect
	1-Z05_NUMOS
	2-C9_CARGA
	3-C9_PEDIDO
	4-C5_ZPEDCLI
	5-C5_ZAGRUPA
	6-C5_CLIENTE
	7-C5_LOJACLI
	*/

	// somente para expedição grava a Z43 - Pedidos por CESV
	If (SZZ->ZZ_OPERACA == "02")

		// varro o array e salvo os dados
		For _nX := 1 to Len(_aPedSelect)

			// reinicia variavel
			_lIncPlanej := .T.

			// relacao de pedidos por agendamento/planejamento de carregamento
			dbselectArea("Z43")
			Z43->(dbSetOrder( 5 )) // 5 - Z43_FILIAL, Z43_SEQAGE, Z43_PEDIDO
			If ( Z43->(dbSeek( xFilial("Z43") + SZY->ZY_SEQUENC + _aPedSelect[_nX, 3] )) )
				_lIncPlanej := .F.
			EndIf

			// atualizacao de dados
			Reclock("Z43", _lIncPlanej)
			// campos para inclusao
			If (_lIncPlanej)
				Z43->Z43_FILIAL := xFilial("Z43")
				Z43->Z43_NUMOS  := _aPedSelect[_nX, 1]
				Z43->Z43_CARGA  := _aPedSelect[_nX, 2]
				Z43->Z43_PEDIDO := _aPedSelect[_nX, 3]
				Z43->Z43_CLIENT := _aPedSelect[_nX, 6]
				Z43->Z43_LOJA   := _aPedSelect[_nX, 7]
				Z43->Z43_PEDCLI := _aPedSelect[_nX, 4]
				Z43->Z43_STATUS := "P" // P-PLANEJADO | C-CANCELADO | R-REALIZADO
				Z43->Z43_AGRUPA := _aPedSelect[_nX, 5]
				Z43->Z43_DATA   := _cDtReg
				Z43->Z43_HORA   := _cHrReg
				Z43->Z43_SEQAGE := SZY->ZY_SEQUENC
			EndIf
			// atualiza CESV
			Z43->Z43_CESV   := SZZ->ZZ_CESV
			// confirma gravacao de dados
			Z43->(MsUnlock())

			// necessário gravar o CESV por cada carga que for selecionada
			dbSelectArea("Z05")
			Z05->(dbOrderNickName("Z05_CARGA"))
			Z05->(dbSeek( _cSeekZ05 := xFilial("Z05") + Z43->Z43_CARGA ))
			// varre todas as OSs relacionadas na carga para expedição
			While Z05->( ! Eof() ) .And. ((Z05->Z05_FILIAL + Z05->Z05_CARGA) == _cSeekZ05)
				// atualiza o CESV
				If (Z05->Z05_TPOPER=="S")
					RecLock("Z05")
					Z05->Z05_CESV := SZZ->ZZ_CESV
					Z05->(MsUnLock())
				EndIf
				// proximo item
				Z05->(dbSkip())
			EndDo
		Next _nX
	EndIf

	// fecha tela
	_oDlgLibEntr:End()

Return

// ** funcao para liberacao da saida do veiculo
// (de status "07 - em operação" para "09 - saída liberada")
User Function WMSA008C( mvCesv )
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SZZ"})

	// query pra informação de pedidos não carregados
	local _cQuery   := ""
	local _aQryZ43  := {}
	local _cPedNCar := ""

	// mensagem de confirmacao
	If ( ! MsgYesNo("Libera Saída do Veículo ?", "Liberação") )
		Return(.f.)
	EndIf

	// registro do CESV
	dbSelectArea("SZZ")
	SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
	SZZ->(dbSeek( xFilial("SZZ") + mvCesv ))

	// valida o status do CESV
	If ( SZZ->ZZ_OPERACA != '02' .AND. SZZ->ZZ_STATUS != "07" ) .Or. ( GETMV("TC_OPEXPED") == "S" .AND. SZZ->ZZ_OPERACA == '02' ) .Or. ( SZZ->ZZ_STATUS == "10")
		// mensagem
		U_FtWmsMsg("Liberação da saída não permitida ou veículo já foi liberado!","Erro WMSA008C")
		// restaura areas iniciais
		RestOrd(_aAreaIni)
		RestArea(_aArea)
		// retorno
		Return(.f.)
	EndIf

	//valida se as ordens de serviço vinculadas ao CESV foram finalizadas corretamente
	_cQuery := " SELECT COUNT(Z06_STATUS) AS QUANTIDADE "
	_cQuery += " FROM " + RetSqlTab("Z06")
	_cQuery += " WHERE " + RetSqlCond("Z06")
	_cQuery += "    AND Z06_NUMOS IN (SELECT Z05_NUMOS "
	_cQuery += "                      FROM " + RetSqlTab("Z05")
	_cQuery += "                      WHERE  " + RetSqlCond("Z05")
	_cQuery += "                             AND Z05_CESV = '" + mvCesv + "' "
	_cQuery += "                             AND Z05_TPOPER = 'S' ) "   //somente OS de SAIDA, pois caminhao não pode ser liberado "vazio ou parcial"
	_cQuery += "    AND Z06_STATUS != 'FI' "

	// executa query
	If (U_FtQuery(_cQuery) != 0)
		// mensagem
		MsgStop("O CESV " + mvCesv + " possui ordens de serviço não finalizadas! Verifique!", "Erro TWMSA008 - WMSA008C")
		// retorno
		Return (.F.)
	Endif

	memowrit("C:\query\TWMSA008_WMSA008C_valida_z06.txt",_cQuery)

	// recupero os itens não carregados
	_cQuery := " SELECT Z43_PEDIDO FROM "+RetSqlTab("Z43")
	_cQuery += " WHERE "+RetSqlCond("Z43")
	_cQuery += " AND Z43_CESV = '" + mvCesv + "' "
	_cQuery += " AND Z43_STATUS = 'P' "

	// jogo os dados pra query, pra então validar
	_aQryZ43 := U_SqlToVet(_cQuery)

	// valido se encontrou algum registro
	If (Len(_aQryZ43) > 0)
		If (Len(_aQryZ43) == 1)
			// mensagem
			U_FtWmsMsg("Atenção: O seguinte pedido não foi carregado: " + _aQryZ43[1])
		Else
			// gravo todos os registros na variavel
			aEval(_aQryZ43, { | x | _cPedNCar += ( x + " - " ) })
			// mensagem
			U_FtWmsMsg("Atenção: Os seguintes pedidos não foram carregados: " + _cPedNCar)
		EndIf

		//cancela
		Return(.f.)
	EndIf

	// insere o log
	U_FtGeraLog(cFilAnt, "SZZ", xFilial("SZZ")+SZZ->ZZ_CESV, "Saída do veículo liberada (Status "+SZZ->ZZ_STATUS+" -> 09)", "WMS")

	// atualiza as informacoes das tabelas
	dbSelectArea("SZZ")
	RecLock("SZZ")
	SZZ->ZZ_STATUS := "09" // 09-SAIDA LIBERADA
	SZZ->(MsUnLock())

	// restaura areas iniciais
	RestOrd(_aAreaIni)
	RestArea(_aArea)

Return(.t.)

//** definicao dos dados adicionais (processo ou carga)
Static Function sfDefDadAdic(mvCodOpe, mvNrProc, mvItProc, mvCodCli, mvLojCli, mvPedSelect, mvSemAgenda)

	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"SZZ","SZY","SC5"})
	// controle de confirmacao
	Local _lRet := .f.
	Local _cQuery
	// estrutura do arquivo de trabalho
	Local _aEstruTrb := {}
	// campo do browse
	Local _aCmpBrw := {}
	// arquivo TMP
	Local _cArqTrb
	// select do browse
	local _cMarcaBrw := GetMark()

	// validação para controle de volume
	Private _lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME", "L", .f., .f., Nil, mvCodCli, mvLojCli, Nil, Nil)
	// validação para entrada de caminhão sem NF emitida
	Private _lCESVSemNf := U_FtWmsParam("WMS_LIBERA_CARREGAMENTO_SEM_NF", "L", .f., .f., Nil, mvCodCli, mvLojCli, Nil, Nil)
	// permite o carregamento sem a nota fiscal de venda do cliente
	private _lSemNfVend := U_FtWmsParam("WMS_LIBERA_CARREGAMENTO_SEM_NF_VENDA", "L", .f., .f., "", mvCodCli, mvLojCli, Nil, Nil)

	// default do valor
	default mvSemAgenda := .f.

	// campos do arquivo de trabalho
	If (mvCodOpe=="01") // 01-RECEBIMENTO
		aAdd(_aEstruTrb,{"Z1_CODIGO" ,"C",TamSx3("Z1_CODIGO")[1],0})
		aAdd(_aEstruTrb,{"Z2_ITEM"   ,"C",TamSx3("Z2_ITEM")[1],0})
		aAdd(_aEstruTrb,{"Z2_DOCUMEN","C",TamSx3("Z2_DOCUMEN")[1],0})
		aAdd(_aEstruTrb,{"Z2_TAMCONT","C",TamSx3("Z2_TAMCONT")[1],0})
		aAdd(_aEstruTrb,{"Z2_TIPCONT","C",20,0})
		aAdd(_aEstruTrb,{"Z2_CONTEUD","C",5,0})
		aAdd(_aEstruTrb,{"Z2_QUANT"  ,"N",TamSx3("Z2_QUANT")[1],TamSx3("Z2_QUANT")[2]})
		aAdd(_aEstruTrb,{"Z2_QTDREC" ,"N",TamSx3("Z2_QTDREC")[1],TamSx3("Z2_QTDREC")[2]})

	ElseIf (mvCodOpe=="02") // 02-EXPEDIÇÃO
		// seleciona
		aAdd(_aEstruTrb,{"IT_OK"      ,"C",2,0})
		// numos
		aAdd(_aEstruTrb,{"Z05_NUMOS"  ,"C",TamSx3("Z05_NUMOS")[1],0})
		// carga
		aAdd(_aEstruTrb,{"C9_CARGA"   ,"C",TamSx3("C9_CARGA")[1],0})
		// pedido
		aAdd(_aEstruTrb,{"C9_PEDIDO"  ,"C",TamSx3("C9_PEDIDO")[1],0})
		// pedido do cliente
		aAdd(_aEstruTrb,{"C5_ZPEDCLI" ,"C",TamSx3("C5_ZPEDCLI")[1],0})
		// agrupadora do cliente
		aAdd(_aEstruTrb,{"C5_ZAGRUPA" ,"C",TamSx3("C5_ZAGRUPA")[1],0})
		// documento/nota do cliente
		aAdd(_aEstruTrb,{"C5_ZDOCCLI" ,"C",TamSx3("C5_ZDOCCLI")[1],0})
		// codigo cliente
		aAdd(_aEstruTrb,{"C5_CLIENTE" ,"C",TamSx3("C5_CLIENTE")[1],0})
		// loja cliente
		aAdd(_aEstruTrb,{"C5_LOJACLI" ,"C",TamSx3("C5_LOJACLI")[1],0})

	EndIf

	// verifica se o TRB existe
	If Select("_TRBDADADIC")<>0
		dbSelectArea("_TRBDADADIC")
		dbCloseArea()
	EndIf

	// criar um arquivo de trabalho
	_cArqTrb := CriaTrab(_aEstruTrb,.T.)
	dbUseArea(.T.,,_cArqTrb,"_TRBDADADIC",.F.,.F.)

	// monta a query para filtro dos dados
	If (mvCodOpe == "01") // 01-RECEBIMENTO
		_cQuery := "SELECT Z1_CODIGO, Z2_ITEM, Z2_DOCUMEN, Z2_TAMCONT, "
		// tipo do container
		_cQuery += "X5_DESCRI Z2_TIPCONT, "
		// conteudo
		_cQuery += "CASE WHEN Z2_CONTEUD = 'C' THEN 'CHEIO' ELSE 'VAZIO' END Z2_CONTEUD, "
		_cQuery += "Z2_QUANT, Z2_QTDREC "
		// programacoes
		_cQuery += "FROM "+RetSqlName("SZ1")+" SZ1 "
		// itens da programacao
		_cQuery += "INNER JOIN "+RetSqlName("SZ2")+" SZ2 ON "+RetSqlCond("SZ2")+" AND Z2_CODIGO = Z1_CODIGO "
		// tipo do container
		_cQuery += "INNER JOIN "+RetSqlName("SX5")+" SX5 ON "+RetSqlCond("SX5")+" AND X5_TABELA = 'ZA' AND X5_CHAVE = Z2_TIPCONT "

		// filtro da programacao
		_cQuery += "WHERE "+RetSqlCond("SZ1")+" "

		// se for sem agenda, trás as programações disponíveis para o usuário selecionar
		If ( ! mvSemAgenda )

			_cQuery += "  AND Z1_CLIENTE = '"+mvCodCli+"' AND Z1_LOJA = '"+mvLojCli+"' "
		Else

			// somente os que ainda não atingiram a quantidade necessária
			_cQuery += "  AND Z2_QUANT > Z2_QTDREC "
		EndIf

		// ordem dos dados
		_cQuery += "ORDER BY Z2_CODIGO, Z2_ITEM"

	ElseIf (mvCodOpe == "02") // 02-EXPEDICAO

		_cQuery := " SELECT DISTINCT '  ' IT_OK, Z05_NUMOS, C9_CARGA, C9_PEDIDO, C5_ZPEDCLI, C5_ZAGRUPA, C5_ZDOCCLI, C5_CLIENTE, C5_LOJACLI "
		// pedidos de venda
		_cQuery += " FROM " + RetSqlTab("SC5")
		// itens liberados do pedido
		_cQuery += " INNER JOIN " + RetSqlTab("SC9") + " ON " + RetSqlCond("SC9") + " AND C9_PEDIDO = C5_NUM "
		// OS por carga
		_cQuery += " INNER JOIN " + RetSqlTab("Z05") + " ON "+RetSqlCond("Z05")+" AND Z05_CARGA = C5_ZCARGA "
		// filtro do pedido de venda
		_cQuery += " WHERE " + RetSqlCond("SC5")

		// se for sem agenda, trás os pedidos disponíveis para o usuário selecionar
		If ( ! mvSemAgenda )
			_cQuery += " AND C5_CLIENTE = '" + mvCodCli + "' AND C5_LOJACLI = '" + mvLojCli + "' "
		EndIf

		// tipo do pedido
		_cQuery += " AND C5_TIPOOPE = 'P' "

		// carga não pode estar em branco
		_cQuery += " AND C5_ZCARGA <> '' "

		// data de corte para nova rotina
		_cQuery += " AND C5_EMISSAO >= '20150715' "

		// não pode ter sido carregado ainda
		_cQuery += "  AND C5_ZCARREG <> 'S' "

		// parâmetros específicos para controle de volume
		If (_lCtrVolume)
			// com volumes já montados
			_cQuery += " AND C5_ZMNTVOL = 'S' "
		EndIf

		// documento/nf do cliente ja informado
		If ( ! _lSemNfVend )
			_cQuery += " AND C5_ZDOCCLI <> ' ' "
		EndIf

		// se já teve nota gerada
		If ( ! _lCESVSemNf )
			_cQuery += "  AND C5_NOTA <> '' "
		EndIf

		// não pode ter status Planejado nem Realizado na Z43
		_cQuery += "  AND NOT EXISTS ( "
		_cQuery += "  SELECT * FROM " + RetSqlTab("Z43")
		_cQuery += "  WHERE " + RetSqlCond("Z43")
		_cQuery += "  AND Z43_PEDIDO = C5_NUM "
		_cQuery += "  AND Z43_STATUS IN ( 'P','R' ) "
		_cQuery += " ) "
		// ordem dos dados
		_cQuery += " ORDER BY C9_CARGA "

	EndIf

	// gravo query para consulta ou debug
	memowrit("C:\query\TWMSA008_sfdefda.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQuery,_aEstruTrb,"_TRBDADADIC")

	// verifica os dados
	dbSelectArea("_TRBDADADIC")
	_TRBDADADIC->(dbGoTop())

	// verifica se há programacoes para visualizar
	If (_TRBDADADIC->(RecCount())==0)
		// mensagem para usuario
		U_FtWmsMsg("Não há programações/cargas disponíveis!","ATENCAO")
		// fecha arquivo de trabalho
		dbSelectArea("_TRBDADADIC")
		dbCloseArea()
		fErase(_cArqTrb)
		// restaura area inicial
		RestOrd(_aAreaIni)
		RestArea(_aAreaAtu)
		Return(.f.)
	EndIf

	// alimenta o header
	If (mvCodOpe=="01") // 01-RECEBIMENTO
		aAdd(_aCmpBrw,{"Z1_CODIGO" , PesqPict("SZ1","Z1_CODIGO") , "Código"})
		aAdd(_aCmpBrw,{"Z2_ITEM"   , PesqPict("SZ2","Z2_ITEM")   , "Item"})
		aAdd(_aCmpBrw,{"Z2_DOCUMEN", PesqPict("SZ2","Z2_DOCUMEN"), "Documento"})
		aAdd(_aCmpBrw,{"Z2_TAMCONT", PesqPict("SZ2","Z2_TAMCONT"), "Tam.Container"})
		aAdd(_aCmpBrw,{"Z2_TIPCONT", PesqPict("SZ2","Z2_TIPCONT"), "Tipo Container"})
		aAdd(_aCmpBrw,{"Z2_CONTEUD", PesqPict("SZ2","Z2_CONTEUD"), "Conteúdo?"})
		aAdd(_aCmpBrw,{"Z2_QUANT"  , PesqPict("SZ2","Z2_QUANT")  , "Quantidade"})
		aAdd(_aCmpBrw,{"Z2_QTDREC" , PesqPict("SZ2","Z2_QTDREC") , "Qtd.Recebida"})

	ElseIf (mvCodOpe=="02") // 02-EXPEDICAO
		// seleciona
		aAdd(_aCmpBrw,{"IT_OK"      ,"@!", " "})
		// Número da OS
		aAdd(_aCmpBrw,{"Z05_NUMOS"  ,PesqPict("Z05","Z05_NUMOS"), "Num.OS"})
		// Carga
		aAdd(_aCmpBrw,{"C9_CARGA"   ,PesqPict("SC9","C9_CARGA"),  "Carga"})
		// Pedido
		aAdd(_aCmpBrw,{"C9_PEDIDO"  ,PesqPict("SC9","C9_PEDIDO"), "Pedido"})
		// Pedido do Cliente
		aAdd(_aCmpBrw,{"C5_ZPEDCLI" ,PesqPict("SC5","C5_ZPEDCLI"), "Ped.Cli"})
		// Agrupadora do Cliente
		aAdd(_aCmpBrw,{"C5_ZAGRUPA" ,PesqPict("SC5","C5_ZAGRUPA"), "Agrupadora"})
		// documento/nota fiscal do cliente
		aAdd(_aCmpBrw,{"C5_ZDOCCLI" ,PesqPict("SC5","C5_ZDOCCLI"), "Doc. Cliente"})

	EndIf

	// monta o dialogo
	oDlgProgRec := MSDialog():New(000,000,400,800,"Programação de Recebimentos/Cargas",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho
	oPnlCabec := TPanel():New(000,000,nil,oDlgProgRec,,.F.,.F.,,,000,020,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// botao para detahes do dia
	oBtnProgDet := TButton():New(005,005,"Confirmar",oPnlCabec,{|| _lRet := (mvCodOpe != "01") .Or. (MsgYesNo("Confirma utilização do processo " + _TRBDADADIC->Z1_CODIGO + "/" + _TRBDADADIC->Z2_ITEM + " ?", "Confirmação")) , oDlgProgRec:End() },060,010,,,,.T.,,"",,,,.F. )
	// botao pra fechar
	oBtnProgSair := TButton():New(005,070,"Fechar",oPnlCabec,{||oDlgProgRec:End()},060,010,,,,.T.,,"",,,,.F. )

	// browse com a listagem das programacoes/cargas disponiveis
	oBrwProgRec := MsSelect():New("_TRBDADADIC", IIF(mvCodOpe=="02","IT_OK",Nil),, _aCmpBrw,, _cMarcaBrw, {15,1,183,373})
	// tela cheia
	oBrwProgRec:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG oDlgProgRec CENTERED

	If (_lRet)
		If (mvCodOpe=="01") // 01-RECEBIMENTO
			// programacao
			mvNrProc := _TRBDADADIC->Z1_CODIGO
			mvItProc := _TRBDADADIC->Z2_ITEM

			// para quando não houver agenda, atualiza os dados do cliente e loja
			If ( mvSemAgenda )

				// posiciona na programação para pegar os dados adicionais
				dbSelectArea("SZ1")
				SZ1->( dbSetOrder(1) ) // Z1_FILIAL, Z1_CODIGO, R_E_C_N_O_, D_E_L_E_T_
				If ( SZ1->( dbSeek ( xFilial("SZ1") + _TRBDADADIC->Z1_CODIGO) ) )
					mvCodCli := SZ1->Z1_CLIENTE
					mvLojCli := SZ1->Z1_LOJA
				EndIf
			EndIf

			// fecha o arquivo TRB
			dbSelectArea("_TRBDADADIC")
			dbCloseArea()
			fErase(_cArqTrb)

		ElseIf (mvCodOpe=="02") // 02-EXPEDICAO

			// preencho a variável que levará todos os dados selecionados pra fora da função
			_TRBDADADIC->( dbGotop() )

			While _TRBDADADIC->( ! EOF() )
				// caso o registro esteja selecionado, inclui no array
				If ( _TRBDADADIC->IT_OK == _cMarcaBrw )

					// registros sendo adicionados no array
					aAdd( mvPedSelect, { _TRBDADADIC->Z05_NUMOS, _TRBDADADIC->C9_CARGA, _TRBDADADIC->C9_PEDIDO, _TRBDADADIC->C5_ZPEDCLI, _TRBDADADIC->C5_ZAGRUPA, _TRBDADADIC->C5_CLIENTE, _TRBDADADIC->C5_LOJACLI } )

					// para quando não houver agenda, atualiza os dados do cliente e loja
					If ( mvSemAgenda )
						mvCodCli := _TRBDADADIC->C5_CLIENTE
						mvLojCli := _TRBDADADIC->C5_LOJACLI
					EndIf

				EndIf
				// proximo item
				_TRBDADADIC->( dbSkip() )
			EndDo

			// valido se algum campo for selecionado
			If ( Len(mvPedSelect) == 0 )
				// avisa o usuário
				MsgAlert( "É preciso selecionar pelo menos um registro.", "Info" )
				// variavel de retorno
				_lRet := .F.
			EndIf
		EndIf
	EndIf

	// restaura area inicial
	RestOrd(_aAreaIni)
	RestArea(_aAreaAtu)

Return(_lRet)

//** funcao para registrar a saida do veiculo
Static Function sfSaiVeiculo()
	// query pra informação de pedidos não carregados
	local _cQuery   := ""
	local _aQryZ43  := {}
	local _cPedNCar := ""

	// valida o status o CESV (09-SAIDA LIBERADA)
	If ((_cAlTrbMov)->ZZ_STATUS != "09")
		U_FtWmsMsg("Registro de saída não permitida!","ATENCAO")
		Return(.f.)
	EndIf

	//valida se as ordens de serviço vinculadas ao CESV foram finalizadas corretamente
	_cQuery := " SELECT COUNT(Z06_STATUS) AS QUANTIDADE "
	_cQuery += " FROM " + RetSqlTab("Z06")
	_cQuery += " WHERE " + RetSqlCond("Z06")
	_cQuery += "    AND Z06_NUMOS IN (SELECT Z05_NUMOS "
	_cQuery += "                      FROM " + RetSqlTab("Z05")
	_cQuery += "                      WHERE  " + RetSqlCond("Z05")
	_cQuery += "                             AND Z05_CESV = '" + (_cAlTrbMov)->ZZ_CESV + "' "
	_cQuery += "                             AND Z05_TPOPER = 'S' ) "   //somente OS de SAIDA, pois caminhao não pode ser liberado "vazio ou parcial"
	_cQuery += "    AND Z06_STATUS != 'FI' "

	memowrit("c:\query\twmsa008_sfSaiVeiculo.txt",_cQuery)

	If (U_FTQuery(_cQuery) != 0)
		MsgStop("O CESV " + (_cAlTrbMov)->ZZ_CESV + " possui ordens de serviço não finalizadas! Verifique!", "Erro TWMSA008 - sfSaiVeiculo")
		Return (.F.)
	Endif

	memowrit("C:\query\TWMSA008_sfSaiVeiculo_valida1.txt",_cQuery)

	// confirmacao dos dados
	If ( ! MsgYesNo("Confirma a saída do veículo ?", "Confirmação") )
		Return(.f.)
	EndIf

	// registro do CESV
	dbSelectArea("SZZ")
	SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
	SZZ->(dbSeek( xFilial("SZZ")+(_cAlTrbMov)->ZZ_CESV ))

	// recupero os itens não carregados
	_cQuery := " SELECT Z43_PEDIDO FROM "+RetSqlName("Z43")+" Z43 "
	_cQuery += " WHERE "+RetSqlCond("Z43")
	_cQuery += " AND Z43_CESV = '"+SZZ->ZZ_CESV+"' "
	_cQuery += " AND Z43_STATUS = 'P' "

	// jogo os dados pra query, pra então validar
	_aQryZ43 := U_SqlToVet(_cQuery)

	// valido se encontrou algum registro
	If (Len(_aQryZ43) > 0)
		If (Len(_aQryZ43) == 1)
			U_FtWmsMsg("Atenção: O seguinte pedido não foi carregado: " + _aQryZ43[1])
		Else
			// gravo todos os registros na variavel
			aEval(_aQryZ43, { | x | _cPedNCar += ( x + " - " ) })

			U_FtWmsMsg("Atenção: Os seguintes pedidos não foram carregados: " + _cPedNCar)
		EndIf

		//cancela
		Return(.f.)
	EndIf

	// insere o log
	U_FtGeraLog(cFilAnt, "SZZ", xFilial("SZZ")+SZZ->ZZ_CESV, "Registro de saída do veículo.", "WMS")

	// atualiza as informacoes das tabelas
	dbSelectArea("SZZ")
	RecLock("SZZ")
	SZZ->ZZ_STATUS	:= "10" // 10-REGISTRO DE SAIDA / saida ja liberada
	SZZ->ZZ_DTSAI	:= Date()
	SZZ->ZZ_HRSAI	:= Time()
	SZZ->(MsUnLock())

	// refresh nos dados
	sfRfrDados(.f.)

Return(.t.)

// ** funcao para exclusao de CESV
User Function WMSA008D(mvNrCesv)
	// variavel de retorno
	local _lRet := .F.

	// mensagem solicitando confirmacao
	_lRet := (MsgYesNo("Deseja Excluir o CESV "+mvNrCesv+"?", "Atenção"))

	// se conformado
	If (_lRet)

		// mostra informação de processando para o usuário
		MsgRun("Analisando dados...", "Aguarde", {|| _lRet := sfExcCesv(mvNrCesv) })

		// refresh dos dados
		sfRfrDados(.f.)

	EndIf

Return (_lRet)

// ** funcao que valida e confirma exclusao de CESV
Static Function sfExcCesv(mvNrCesv)
	// variavel de controle
	local _lRet := .t.
	// log de erros
	local _cLog := ""
	// query
	local _cQuery
	// seek Z43
	local _cSeekZ43

	// registro do CESV
	dbSelectArea("SZZ")
	SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
	If ! SZZ->(dbSeek( xFilial("SZZ")+mvNrCesv ))
		MsgInfo("CESV não encontrado no sistema. Comunique o setor de TI! Info: CESV não encontrado na tabela SZZ", "Info")
		_lRet := .t.
	EndIf

	// valida se o veiculo ja teve saida
	If (SZZ->ZZ_STATUS == "10") .Or. ( ! Empty(SZZ->ZZ_DTSAI) )
		// mensagem de aviso
		_cLog += "IMPEDIMENTO: CESV com registro de saída de Veículo" + CRLF
		_cLOG += "SOLUÇÃO: Estornar movimentação de Saída" + CRLF
		_cLog += CRLF
		// atualiza variável de controle
		_lRet := .f.
	EndIf

	// verifica se o CESV está vinculado a algum documento de entrada (tela monitor de serviços)
	dbSelectArea("Z04")
	Z04->( dbSetOrder(1) ) // 1 - Z04_FILIAL, Z04_CESV
	If Z04->(dbSeek( xFilial("Z04") + mvNrCesv ))
		// mensagem de aviso
		_cLog += "IMPEDIMENTO: CESV vinculado a documento" + CRLF
		_cLOG += "SOLUÇÃO: Exclua o vínculo deste CESV com o documento " + Z04->Z04_NF + "/" + Z04->Z04_SERIE + "no monitor de serviços " + CRLF
		_cLog += CRLF
		// atualiza variável de controle
		_lRet := .f.
	EndIf

	// CESV vinculado a pedidos/cargas
	dbSelectArea("Z43")
	Z43->(dbSetOrder(4)) // 4-Z43_FILIAL, Z43_CESV
	Z43->(dbSeek( _cSeekZ43 := xFilial("Z43") + mvNrCesv ))

	// cargas/pedidos relacionados ao CESV
	While Z43->( ! Eof() ) .and. (Z43->(Z43_FILIAL + Z43_CESV) == _cSeekZ43)
		// status do carregamento
		If (Z43->Z43_STATUS != "C")
			// mensagem de aviso
			_cLog += "IMPEDIMENTO: CESV com status de carregamento realizado ou planejado" + CRLF
			_cLOG += "SOLUÇÃO: Estorne o serviço de carregamento da OS: " + Z43->Z43_NUMOS + " / Carga: " + Z43->Z43_CARGA + CRLF
			_cLog += CRLF
			// atualiza variável de controle
			_lRet := .f.
		EndIf
		// proximo item
		Z43->(dbSkip())
	EndDo

	// query para pesquisa de etiquetas já impressar
	_cQuery := " SELECT COUNT(*) IT_ETQ "
	// etiquetas WMS
	_cQuery += " FROM "+RetSqlTab("Z11")
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z11")
	// nr CESV
	_cQuery += " AND Z11_CESV = '"+mvNrCesv+"' "

	memowrit("C:\query\TWMSA008_sfExcCesv_Z11.txt",_cQuery)

	// se encontrou algum registro, não deixa prosseguir
	If (U_FtQuery(_cQuery) > 0)
		_cLog += "IMPEDIMENTO: Foram encontradas etiquetas impressas para este CESV" + CRLF
		_cLOG += "SOLUÇÃO: Exclua as etiquetas relacionadas na OS: "+Z05->Z05_NUMOS+" ou CESV: "+mvNrCesv + CRLF
		_cLog += CRLF
		// atualiza variável de controle
		_lRet := .F.
	EndIf

	// passou da validação, deleta os registros
	If (_lRet)

		// starto a transação
		BeginTran()

		// reposiciona no CESV
		dbSelectArea("SZZ")
		SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
		SZZ->(dbSeek( xFilial("SZZ")+mvNrCesv ))

		// valida se tem agenda vinculada
		If ( ! Empty(SZZ->ZZ_AGENDA) )

			// posiciono no registro da agenda
			dbSelectArea("SZY")
			SZY->(dbSetOrder(1)) // 1-ZY_FILIAL, ZY_SEQUENC
			If SZY->(dbSeek( xFilial("SZY")+SZZ->ZZ_AGENDA ))

				// altera o status da agenda
				RecLock("SZY")
				SZY->ZY_STATUS := "A"
				SZY->(MsUnLock())

				// insere o log
				U_FtGeraLog(cFilAnt, "SZY", xFilial("SZY")+SZY->ZY_SEQUENC, "Realizado estorno do vínculo de CESV x Agenda (Status R->A)", "WMS")

			EndIf
		EndIf

		// exclusao do registro posicionado
		RecLock("SZZ",.F.)
		SZZ->(dbDelete())
		SZZ->(MsUnlock())

		// insere o log
		U_FtGeraLog(cFilAnt, "SZZ", xFilial("SZZ")+mvNrCesv, "Realizado a exclusão do CESV" + mvNrCesv, "WMS")

		// commita a transação
		EndTran()
	EndIf

	// mensagens de retorno
	If (_lRet)
		MsgInfo("CESV excluído com sucesso!", "Info")
	Else
		_cLog += "Exclusão não permitida!"
		HS_MsgInf("LOG:"+CRLF+_cLog,"Log da Exclusão do CESV","Inconsistência na Exclusão do CESV "+mvNrCesv)
	EndIf

Return(_lRet)

// ** função para estornar a liberação de entrada do CESV ** //
User Function WMSA008E ( mvCesv )

	// variavel de controle de retorno
	local _lRet := .t.
	//  area inicial
	local _aAreaIni := GetArea()
	// seek na Z43
	local _cSeekZ43 := ""

	// reposiciona no CESV
	dbSelectArea("SZZ")
	SZZ->( dbSetOrder(1) ) // 1-ZZ_FILIAL, ZZ_CESV
	SZZ->( dbSeek( xFilial("SZZ") + mvCesv ) )

	// starto a transação
	BeginTran()

	// valida se tem agenda vinculada
	If ( ! Empty(SZZ->ZZ_AGENDA) )

		// posiciono no registro da agenda
		dbSelectArea("SZY")
		SZY->( dbSetOrder(1) ) // 1-ZY_FILIAL, ZY_SEQUENC
		If ( SZY->( dbSeek( xFilial("SZY") + SZZ->ZZ_AGENDA ) ) )

			// altera o status da agenda
			RecLock("SZY")
			SZY->ZY_STATUS := "A"
			SZY->(MsUnLock())

			// insere o log
			U_FtGeraLog(cFilAnt, "SZY", xFilial("SZY")+SZY->ZY_SEQUENC, "Realizado estorno do vínculo de CESV x Agenda (Status R->A)", "WMS")

		EndIf
	EndIf

	// CESV vinculado a pedidos/cargas
	dbSelectArea("Z43")
	Z43->( dbSetOrder(4) ) // 4-Z43_FILIAL, Z43_CESV
	Z43->( dbSeek( _cSeekZ43 := xFilial("Z43") + mvCesv ))

	// cargas/pedidos relacionados ao CESV
	While ( Z43->( ! Eof() ) ) .And. ( (Z43->Z43_FILIAL + Z43->Z43_CESV) == _cSeekZ43 )
		// se foi programado pelo agendamento, remove vinculo com CESV
		If ( ! Empty(Z43->Z43_SEQAGE) )
			RecLock( "Z43", .F.)
			Z43->Z43_CESV := ""
			Z43->( MsUnlock() )

		Else
			// exclusao do registro
			RecLock( "Z43", .F.)
			Z43->( dbDelete() )
			Z43->( MsUnlock() )

		EndIf

		// insere o log
		U_FtGeraLog(cFilAnt, "Z43", xFilial("Z43") + Z43->Z43_CESV, "Realizado estorno do vínculo de CESV x CARGA x PEDIDO. Carga: " + Z43->Z43_CARGA + " / Pedido: " + Z43->Z43_PEDIDO, "WMS")

		// proximo item
		Z43->(dbSkip())
	EndDo

	// volto status do CESV
	RecLock( "SZZ", .F. )
	SZZ->ZZ_STATUS  := "01" // CHEGADA DO CAMINHÃO
	SZZ->ZZ_DTENT   := CTOD("//")
	SZZ->ZZ_HRENT   := ""
	SZZ->ZZ_CLIENTE := ""
	SZZ->ZZ_LOJA    := ""
	SZZ->ZZ_AGENDA  := ""
	SZZ->( MsUnlock() )

	// finalizo a transação
	EndTran()

	// restaura area inicial
	RestArea(_aAreaIni)

Return _lRet

// ** funcao para estornar a saida do veiculo
Static Function sfEstSaiVeic()
	// query pra informação de pedidos não carregados
	local _cQuery   := ""
	local _aQryZ43  := {}
	local _cPedNCar := ""

	// valida o status o CESV (10-REGISTRO DE SAIDA)
	If ((_cAlTrbMov)->ZZ_STATUS != "10")
		U_FtWmsMsg("Estorno do registro de saída não permitido!","ATENCAO")
		Return(.f.)
	EndIf

	// confirmacao dos dados
	If ( ! MsgYesNo("Confirma o estorno da saída do veículo ?", "Estorno"))
		Return(.f.)
	EndIf

	// registro do CESV
	dbSelectArea("SZZ")
	SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
	SZZ->(dbSeek( xFilial("SZZ")+(_cAlTrbMov)->ZZ_CESV ))

	// atualiza as informacoes das tabelas
	dbSelectArea("SZZ")
	RecLock("SZZ")
	SZZ->ZZ_STATUS := "09" // 09-SAIDA LIBERADA
	SZZ->ZZ_DTSAI  := CtoD("//")
	SZZ->ZZ_HRSAI  := ""
	SZZ->(MsUnLock())

	// insere o log
	U_FtGeraLog(cFilAnt, "SZZ", xFilial("SZZ")+SZZ->ZZ_CESV, "Estorno de Saída Realizado com Sucesso (Rotina TWMSA008 -> sfEstSaiVeic -> De 10 para 09)", "WMS")

	// refresh nos dados
	sfRfrDados(.f.)

Return(.t.)

// ** funcao para estornar a liberacao da saida do veiculo
// (de status "09 - saida liberada" para "07 - em operação")
User Function WMSA008F( mvCesv )
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SZZ"})

	If ( ! MsgYesNo("Deseja estornar a liberação do veículo (CESV " + mvCesv + ") ?", "Estorno") )
		Return(.f.)
	EndIf

	// registro do CESV
	dbSelectArea("SZZ")
	SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
	SZZ->(dbSeek( xFilial("SZZ") + mvCesv ))

	// valida o status do CESV
	//	If ( SZZ->ZZ_OPERACA != '02' .AND. SZZ->ZZ_STATUS != "09" ) .Or. ( GETMV("TC_OPEXPED") == "S" .AND. SZZ->ZZ_OPERACA == '02' ) .Or. ( SZZ->ZZ_STATUS == "10")
	If ( SZZ->ZZ_STATUS != "09" )
		U_FtWmsMsg("Não foi possível estornar a liberação do veículo (CESV:" + mvCesv + ")! Verifique se o status atual é de saída liberada.","Erro WMSA008F")

		// restaura areas iniciais
		RestOrd(_aAreaIni)
		RestArea(_aArea)
		Return(.f.)
	EndIf

	// insere o log
	U_FtGeraLog(cFilAnt, "SZZ", xFilial("SZZ")+SZZ->ZZ_CESV, "Estorno da liberação do veículo (Status " + SZZ->ZZ_STATUS + " -> 07)", "WMS")

	// atualiza as informacoes das tabelas
	dbSelectArea("SZZ")
	RecLock("SZZ")
	SZZ->ZZ_STATUS := "07" // 07-EM OPERAÇÃO
	SZZ->(MsUnLock())

	// restaura areas iniciais
	RestOrd(_aAreaIni)
	RestArea(_aArea)

Return(.t.)

//** funcao que muda a flag de filtro de saída
Static Function sfFiltSaida()
	_lFiltra := !_lFiltra
Return NIL

// ** funcao que busca planejamento de carga do agendamento
Static Function sfCargaAge(mvSeqAgend)
	// variavel de retorno
	local _aRetPedSel := {}
	// query
	local _cQuery := ""

	// prepara query
	_cQuery += " SELECT Z43_NUMOS, "
	_cQuery += "        Z43_CARGA, "
	_cQuery += "        Z43_PEDIDO, "
	_cQuery += "        Z43_PEDCLI, "
	_cQuery += "        Z43_AGRUPA, "
	_cQuery += "        Z43_CLIENT, "
	_cQuery += "        Z43_LOJA "
	_cQuery += " FROM   " + RetSqlTab("Z43")
	_cQuery += " WHERE  " + RetSqlCond("Z43")
	_cQuery += "        AND Z43_SEQAGE = '" + mvSeqAgend + "' "
	_cQuery += "        AND Z43_STATUS = 'P' "

	// retorna dados
	_aRetPedSel := U_SqlToVet(_cQuery)

Return( _aRetPedSel )

// *****************************************************
// ** NOVA ROTINA DE CONTROLE DE MOVIMENTACAO NO GATE **
// *****************************************************
User Function WMSA008Y

	// objeto browse
	Local _oBrwAgenda := Nil

	// cabecalho
	dbSelectArea("SZZ")

	// titulo
	Private cCadastro := "Controle de Entrada e Saída de Veículo"

	// controle de opcoes do menu
	Private aRotina := MenuDef()

	// campos do browse
	private _aCposGrid := {"Z3_SEQUENC", "Z3_CONTAIN", "Z3_CONTEUD", "Z3_LACRE"}

	// variaveis usadas na consulta padrao SZ2MOV
	private _lEntrada  := .t.
	private _lCargaSol := .f.

	// cria objeto do browse
	_oBrwAgenda := FWMBrowse():New()
	_oBrwAgenda:SetAlias('SZZ')
	_oBrwAgenda:SetDescription(cCadastro)

	// define cores do browse
	//_oBrwAgenda:AddLegend("ZY_STATUS == 'A'", "BR_AZUL" )
	//	_oBrwAgenda:AddLegend("ZY_STATUS == 'R'", "BR_VERDE")
	//_oBrwAgenda:AddLegend("ZY_STATUS == 'C'", "BR_PRETO")

	// cria um filtro fixo para todos
	_oBrwAgenda:AddFilter("Veículos no Pátio"          , "ZZ_STATUS != '10'", .f., .t., "SZZ", .f., {}, "ID_VEIC_AG_PAT" )
	_oBrwAgenda:AddFilter("Aguardando Liberação"       , "ZZ_STATUS == '01'", .f., .f., "SZZ", .f., {}, "ID_VEIC_AG_LIB" )
	_oBrwAgenda:AddFilter("Veículo Liberado / No Pátio", "ZZ_STATUS == '02'", .f., .f., "SZZ", .f., {}, "ID_VEIC_LIB_PAT")
	_oBrwAgenda:AddFilter("Doca Definida"              , "ZZ_STATUS == '03'", .f., .f., "SZZ", .f., {}, "ID_VEIC_DOC_DEF")
	_oBrwAgenda:AddFilter("Em Inspeção"                , "ZZ_STATUS == '04'", .f., .f., "SZZ", .f., {}, "ID_VEIC_EM_INSP")
	_oBrwAgenda:AddFilter("Liberado para Operação"     , "ZZ_STATUS == '05'", .f., .f., "SZZ", .f., {}, "ID_VEIC_LIB_OPE")
	_oBrwAgenda:AddFilter("Em Planejamento"            , "ZZ_STATUS == '06'", .f., .f., "SZZ", .f., {}, "ID_VEIC_EM_PLAN")
	_oBrwAgenda:AddFilter("Em Operação"                , "ZZ_STATUS == '07'", .f., .f., "SZZ", .f., {}, "ID_VEIC_EM_OPER")
	_oBrwAgenda:AddFilter("Inspeção em Análise"        , "ZZ_STATUS == '08'", .f., .f., "SZZ", .f., {}, "ID_VEIC_INSP_AN")
	_oBrwAgenda:AddFilter("Saída Liberada"             , "ZZ_STATUS == '09'", .f., .f., "SZZ", .f., {}, "ID_VEIC_SAI_LIB")
	_oBrwAgenda:AddFilter("Saída Ja Realizada"         , "ZZ_STATUS == '10'", .f., .f., "SZZ", .f., {}, "ID_VEIC_SAI_REA")

	// ativa objeto browse
	_oBrwAgenda:Activate()

Return

// ** funcao para definir o menu
Static Function MenuDef()
	// variavel de retorno
	Local _aRetMenu := {}

	ADD OPTION _aRetMenu TITLE 'Pesquisar'  ACTION 'PesqBrw'          OPERATION 1 ACCESS 0
	ADD OPTION _aRetMenu TITLE 'Visualizar' ACTION 'VIEWDEF.TWMSA008' OPERATION 2 ACCESS 0
	ADD OPTION _aRetMenu TITLE 'Entrada'    ACTION 'VIEWDEF.TWMSA008' OPERATION 3 ACCESS 0
	ADD OPTION _aRetMenu TITLE 'Saída'      ACTION 'VIEWDEF.TWMSA008' OPERATION 4 ACCESS 0
	ADD OPTION _aRetMenu TITLE 'Excluir'    ACTION 'VIEWDEF.TWMSA008' OPERATION 5 ACCESS 0
	//	ADD OPTION _aRetMenu TITLE STR0018	ACTION 'AFA003BLQ' 		  		OPERATION 20 ACCESS 0 //'Bloqueio/Desbloq'
	//	ADD OPTION _aRetMenu TITLE STR0020	ACTION 'AFA003ATU' 		  		OPERATION 30 ACCESS 0 //"Atualiza Aprv."

Return(_aRetMenu)

// ** funcao que Monta a Legenda
User Function WMSA008A()

	BrwLegenda(cCadastro, "Status "+cCadastro,{;
	{"BR_AZUL" , "Agendado"  },;
	{"BR_VERDE", "Realizado" },;
	{"BR_PRETO", "Cancelado" }})

Return .T.

// ModelDef - Modelo padrao para MVC
Static Function ModelDef()
	// variaveis temporarias
	local _nCpo

	// variaveis para modelo
	Local _oModel    := Nil
	Local _oStrCbSZZ := Nil
	Local _oStrItSZ3 := Nil
	Local bPosValid  := { |_oModel| PosVldMdl(_oModel) }
	Local _aRelacSZ3 := {}

	// define estruturas
	_oStrCbSZZ := FwFormStruct( 1, "SZZ", Nil )
	_oStrItSZ3 := FwFormStruct( 1, "SZ3", Nil )//{ |_cCampo| AllTrim(_cCampo) == "Z3_FILIAL" .Or. aScan(_aCposGrid, AllTrim(_cCampo) ) > 0 } )

	// remove obrigatoriedade de todos os campos
	_oStrItSZ3:SetProperty('*', MODEL_FIELD_OBRIGAT, .F.)

	// define campos obrigatorios
	For _nCpo := 1 to Len(_aCposGrid)
		_oStrItSZ3:SetProperty(_aCposGrid[_nCpo], MODEL_FIELD_OBRIGAT, .T.)
	Next _nCpo

	// Cria o formulario
	_oModel := MPFormModel():New("MD_TWMSA008", /*bPreValid*/, { |oModel| bTudoOk(oModel) }, { |oModel| bCommit(oModel) }, /*bCancel*/)
	_oModel:SetDescription(cCadastro)

	// define campos do cabecalho
	_oModel:AddFields("SZZMASTER", Nil, _oStrCbSZZ, /*prevalid*/ ,, /*bCarga*/ )
	_oModel:SetPrimaryKey({'ZZ_FILIAL', 'ZZ_CESV' })

	// modelo do grid
	_oModel:AddGrid("SZ3DETAIL", "SZZMASTER", _oStrItSZ3 , /*bLinePre*/ , /*bLinePost*/ , /*bPre*/ , /*bPost*/, /*bLoad*/)

	// relacionamento da tabela Movimentacao Veiculos x Container
	aAdd(_aRelacSZ3,{'Z3_FILIAL' , 'xFilial("SZ3")'})
	aAdd(_aRelacSZ3,{'Z3_CESV'   , 'ZZ_CESV'       })
	aAdd(_aRelacSZ3,{'Z3_DTMOVIM', 'ZZ_DTENT'      })
	aAdd(_aRelacSZ3,{'Z3_HRMOVIM', 'ZZ_HRENT'      })
	aAdd(_aRelacSZ3,{'Z3_CLIENTE', 'ZZ_CLIENTE'    })
	aAdd(_aRelacSZ3,{'Z3_LOJA'   , 'ZZ_LOJA'       })

	//oModel:GetModel( 'ZA2DETAIL' ):SetOptional( .T. )

	// Faz relaciomaneto entre os compomentes do model
	_oModel:SetRelation("SZ3DETAIL", _aRelacSZ3, SZ3->( IndexKey(7) ))

	// Liga o controle de nao repeticao de linha
	_oModel:GetModel("SZ3DETAIL"):SetUniqueLine( {'Z3_CONTAIN'} )

	// Adiciona a descricao do Componente do Modelo de Dados
	_oModel:GetModel('SZZMASTER'):SetDescription('Detalhes do Veículo e Motorista')
	_oModel:GetModel('SZ3DETAIL'):SetDescription('Detalhes da Composição da Carga')

Return( _oModel )

// ** Função que define a interface do cadastro de Movimentacao de Veiculos para o MVC
Static Function ViewDef()

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local _oModel := FWLoadModel('TWMSA008')
	Local _oView  := Nil
	// Cria a estrutura a ser usada na View
	Local _oStrSZZ := FWFormStruct( 2, 'SZZ', Nil )
	Local _oStrSZ3 := FWFormStruct( 2, 'SZ3', { |_cCampo| AllTrim(_cCampo) == "Z3_FILIAL" .Or. aScan(_aCposGrid, AllTrim(_cCampo) ) > 0 } )

	// Cria o objeto de View
	_oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	_oView:SetModel( _oModel )

	// Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	_oView:AddField('VIEW_SZZ', _oStrSZZ, 'SZZMASTER')

	//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
	_oView:AddGrid('VIEW_SZ3', _oStrSZ3, 'SZ3DETAIL')

	// define campo incremental do grid
	_oView:AddIncrementField('VIEW_SZ3', 'Z3_SEQUENC')

	// Criar "box" horizontal para receber algum elemento da view
	_oView:CreateHorizontalBox('SUPERIOR' , 60 )
	_oView:CreateHorizontalBox('INFERIOR' , 40 )

	// Relaciona o ID da View com o "box" para exibicao
	_oView:SetOwnerView('VIEW_SZZ', 'SUPERIOR')
	_oView:SetOwnerView('VIEW_SZ3', 'INFERIOR')

	// Liga a identificacao do componente
	_oView:EnableTitleView( 'VIEW_SZZ' )
	_oView:EnableTitleView( 'VIEW_SZ3' )

Return(_oView)

// ** funcao dentro do commit para gravacao de dados complementares
Static Function bCommit(oModel)
	// variavel de retorno
	local _lTudoOk := .t.
	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaSZ3 := SZ3->(GetArea())
	// posicao atual das linhas do browse
	Local _aSaveLines := FWSaveRows()
	// variaveis temporarias
	local _nX
	// modelos de cabecalho e itens
	Local _oModelCbSZZ := oModel:GetModel('SZZMASTER')
	Local _oModelItSZ3 := oModel:GetModel('SZ3DETAIL')

	//Operacao executada no modelo de dados.
	local _nOperation := oModel:GetOperation()

	// data de movimentacao
	local _dDtMovim := _oModelCbSZZ:GetValue('ZZ_DTENT')

	//nUltLin:= oModel:GetQtdLine()
	FWFormCommit(_oModelItSZ3)

	// se for exclusao
	If (_lTudoOk) .and. (_nOperation == MODEL_OPERATION_DELETE)
		Return(_lTudoOk)
	EndIf

	//Local nOperation := oModel:GetOperation()   						//Operacao executada no modelo de dados.
	//Local nParMin    := oModel:GetValue( 'MBTDETAIL', 'MBT_MINPAR' ) //Parcela minima.
	//Local nParMax    := oModel:GetValue( 'MBTDETAIL', 'MBT_PARCEL' ) //Parcela maxima.

	//Default oModel := Nil

	//Help( ,, 'Help',, "A quantidade de parcelas deve ser diferente de zero." , 1, 0 )
	//Return .F.

	// varre todos os itens do browse
	For _nX := 1 to _oModelItSZ3:Length( .T. )

		// posiciona na linha do browse
		_oModelItSZ3:GoLine( _nX )

		// testa a linha deletada
		If ( ! _oModelItSZ3:IsDeleted() )

			MsgStop( _oModelItSZ3:GetValue("Z3_SEQUENC") )

		EndIf
	Next _nX

	// abre tabela de dados gravados
	DbSelectArea("SZ3")
	//SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV

	// restaura posicao inicial das linhas
	FWRestRows( _aSaveLine )

	// restaura posicao inicial das tabelas
	RestArea(_aAreaSZ3)
	RestArea(_aAreaAtu)

Return( .T. )

// ** funcao de validacao antes de gravacao
Static Function bTudoOk(oModel)
	// variavel de retorno
	local _lTudoOk := .t.
	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaSZ3 := SZ3->(GetArea())
	// posicao atual das linhas do browse
	Local _aSaveLines := FWSaveRows()
	// variaveis temporarias
	local _nX
	// modelos de cabecalho e itens
	Local _oModelCbSZZ := oModel:GetModel('SZZMASTER')
	Local _oModelItSZ3 := oModel:GetModel('SZ3DETAIL')

	// dados do cabecalho
	local _cCodCli  := _oModelCbSZZ:GetValue('ZZ_CLIENTE')
	local _cLojCli  := _oModelCbSZZ:GetValue('ZZ_LOJA')
	local _cNumProg := _oModelCbSZZ:GetValue('ZZ_PROCES')
	local _cIteProg := _oModelCbSZZ:GetValue('ZZ_ITPROC')

	// dados dos itens
	Local _nQtdMovim := _oModelItSZ3:Length( .T. )

	// dados complementar
	local _dDtMovim := _oModelCbSZZ:GetValue('ZZ_DTENT')

	//Operacao executada no modelo de dados.
	local _nOperation := oModel:GetOperation()

	//Local nParMin    := oModel:GetValue( 'MBTDETAIL', 'MBT_MINPAR' ) //Parcela minima.
	//Local nParMax    := oModel:GetValue( 'MBTDETAIL', 'MBT_PARCEL' ) //Parcela maxima.

	//Default oModel := Nil

	//Help( ,, 'Help',, "A quantidade de parcelas deve ser diferente de zero." , 1, 0 )
	//Return .F.

	MsgStop("bTudoOk - ")

	// se for exclusao
	If (_lTudoOk) .and. (_nOperation == MODEL_OPERATION_DELETE)
		Return(_lTudoOk)
	EndIf

	// valida dados da programacao
	If (_lTudoOk)
		// cabecalho da programacao
		dbSelectArea("SZ1")
		SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
		If ( ! SZ1->(dbSeek( xFilial("SZ1") + _cNumProg )))
			// mensagem
			Help( ,, 'Help',, "Programação de recebimentos não encontrada!" , 1, 0 )
			// variavel de controle
			_lTudoOk := .F.
		EndIf
	EndIf

	// valida se a programacao esta encerrada
	If (_lTudoOk) .and. ( ! Empty(SZ1->Z1_DTFINFA) )
		// mensagem
		Help(,,'Help',,"Programação encontra-se encerrada. Contate o setor de Faturamento.",1,0)
		// variavel de controle
		_lTudoOk := .F.
	EndIf

	// valida itens da programacao
	If (_lTudoOk)
		// itens da programacao
		dbSelectArea("SZ2")
		SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM
		If ( ! SZ2->(dbSeek( xFilial("SZ2") + _cNumProg + IIf(Empty(_cIteProg), Space(Len(SZ2->Z2_ITEM)), _cIteProg) )))
			// mensagem
			Help(,,'Help',,"Item da Programação de Recebimentos não encontrado!",1,0)
			// variavel de controle
			_lTudoOk := .F.
		EndIf
	EndIf

	// verifica o saldo do item
	If (_lTudoOk) .and. (_lEntrada) .and. ((SZ2->Z2_QTDREC + _nQtdMovim) > SZ2->Z2_QUANT)
		// mensagem
		Help(,,'Help',,"Não há mais Saldo à Receber deste Item da Programação!",1,0)
		// variavel de controle
		_lTudoOk := .F.
	EndIf

	// valida item de carga solta
	If (_lTudoOk) .and. (_lCargaSol) .and. (SZ2->Z2_TAMCONT <> "CS")
		// mensagem
		Help(,,'Help',,"O item selecionado da programação é para Containers!",1,0)
		// variavel de controle
		_lTudoOk := .F.
	EndIf

	// valida item nao eh carga solta
	If (_lTudoOk) .and. ( ! _lCargaSol ) .and. (SZ2->Z2_TAMCONT == "CS")
		// mensagem
		Help(,,'Help',,"O item selecionado da programação é para Carga Solta!",1,0)
		// variavel de controle
		_lTudoOk := .F.
	EndIf

	// varre todos os itens do browse
	For _nX := 1 to _oModelItSZ3:Length( .T. )
		// posiciona na linha do browse
		_oModelItSZ3:GoLine( _nX )

		MsgStop("Linha " + Str(_nX))

		// testa a linha deletada
		If ( ! _oModelItSZ3:IsDeleted() )

			MsgStop("Atualizado")

			//_oModelItSZ3:LoadValue("Z3_DTMOVIM", _dDtMovim)

		EndIf
	Next _nX

	// restaura posicao inicial das linhas
	FWRestRows( _aSaveLine )

	// restaura posicao inicial das tabelas
	RestArea(_aAreaSZ3)
	RestArea(_aAreaAtu)

Return( .T. )