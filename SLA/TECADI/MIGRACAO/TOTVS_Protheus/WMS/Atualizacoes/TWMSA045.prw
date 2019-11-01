#Include 'Protheus.ch'
#Include 'TopConn.ch'

//------------------------------------------------------------------------------//
// Programa: TWMSA045()  |  Autor: Gustavo Schumann -> SLA TI | Data: 01/08/2018//
//------------------------------------------------------------------------------//
// Descrição: Tela de montagem de volumes para Desktop.							//
//------------------------------------------------------------------------------//

User Function TWMSA045()

	Local aTam			:= MsAdvSize()
	Local aInfo			:= {aTam[1],aTam[2],aTam[3],aTam[4],3,3}
	Local aObjects		:= {{ 100 , 100, .T. , .T. , .F. }}
	Local aPosObj		:= MsObjSize(aInfo, aObjects, .T.)
	Local mvQryUsr		:= ""

	Private oFont20n	:= TFont():New('Arial',,-20,,.T.)
	Private oFont20		:= TFont():New('Arial',,-20,,.F.)
	Private oFont30n	:= TFont():New('Arial',,-30,,.T.)
	Private oFont30		:= TFont():New('Arial',,-30,,.F.)
	Private oFont40		:= TFont():New('Arial',,-40,,.F.)

	//Fonte usada no fonte TACDA002
	Private _oFnt02		:= TFont():New("Verdana",,14,,.F.)

	Private _cMskEtiq	:= PesqPict("Z11","Z11_CODETI")
	Private _cMskCodBar	:= PesqPict("SB1","B1_CODBAR")

	Private _nTamEtqInt	:= TamSx3("Z11_CODETI")[1]
	Private _nTamCodPrd	:= TamSx3("B1_COD")[1]

	Private _cEtiqProd	:= CriaVar("Z11_CODETI",.F.)
	Private _cCodUnit	:= CriaVar("DC1_CODUNI",.F.)
	Private _nTamIdPal  := TamSx3("Z11_CODETI")[1]

	Private _cCodProd	:= Space(_nTamCodPrd)
	Private _cNewAgrup	:= Space(_nTamEtqInt)
	Private _cOldAgrup	:= Space(_nTamEtqInt)
	Private _cIdPalete	:= Space(_nTamEtqInt)
	Private _cPltOrig	:= Space(_nTamEtqInt)

	// funcao que monta os dados do operador logado no sistema
	Private _aUsrInfo := U_FtWmsOpe()

	// codigo do unitizador padrao
	Private _cUnitPdr := SuperGetMV('TC_PLTPADR',.F.,"000001")

	// doca do servico
	Private _cDocaSrv := ""

	// codigo do operador
	Private _lUsrColet	:= (_aUsrInfo[2]=="C")
	Private _cCodOper	:= IIf(_lUsrColet, Space(6), __cUserId)

	// tipo de identificacao
	Private _cTpIdEtiq	:= ""
	Private _lEtqIdEAN	:= ""
	Private _lEtqIdDUN	:= ""
	Private _lEtqCod128	:= ""
	Private _lEtqClient	:= ""

	//Mascara campos quantidade
	Private _cMaskQuant := U_FtWmsParam("WMS_MASCARA_CAMPO_QUANTIDADE", "C", PesqPict("SD1","D1_QUANT"), .F., "", Nil, Nil, Nil, Nil)

	// permite conferencia/recebimento por volumes
	Private _lCtrVolume := .F.

	Private _nTamEtqCli	:= ""
	Private _cEtqCodBar	:= ""
	Private _cDscProd	:= ""
	Private _cArmzServ	:= ""
	Private _cNumCESV	:= ""
	Private _cTipoOper	:= ""
	Private _cDscOpera	:= ""
	Private aItem		:= {}
	Private _aColsDet	:= {}
	Private _aColsConf	:= {}
	Private _aColsVPd	:= {}
	Private aGetOS		:= {}
	Private _lNovoVolume:= .T.
	Private _lContConf	:= .T.
	Private _lOk		:= .F.
	Private _lNovoPalete:= .T.
	Private lExit		:= .T.
	Private _nQtdProd	:= 1
	Private _nQtdSegUM	:= 0
	Private _cPedido	:= ""
	Private nQtdVol		:= 0

	// variaveis recebidas de parametro
	Private _cCodServ    := ""
	Private _cCodTaref   := ""
	Private _cCodStatus  := ""
	Private _cNumOrdSrv  := ""
	Private _cSeqOrdSrv  := ""
	Private _cCodCliFor  := ""
	Private _cLojCliFor  := ""

	// controle de numero de contagens
	Private _cNrContagem := ""

	//Objetos visuais
	Private oDlg
	Private oBrwVPed
	Private oBrwPV
	Private oBrwConf
	Private _oSayAgrp1
	Private _oSayAgrp2
	Private _oGetNewAgrupa
	Private _oGetOldAgrupa
	Private _oGetCodProd
	Private _oSayOld1
	Private _oSayOld2
	Private _oSayCPr1
	Private _oSayCPr2
	Private _oBmpEstorno
	Private oDlgMain
	Private oGrpOS
	Private oBrwOS
	Private oDlg
	Private oGrpEtiq
	Private oGrpBar
	Private oProd
	Private oGrpPed
	Private oSayNPed
	Private oGrpVol
	Private oSayNVol
	Private oGrpPV
	Private oBrwPV
	Private oGrpConf
	Private oBrwConf
	Private oDlgMont
	Private oSayMont
	Private oGrpVPed
	Private oBrwVPed
	Private oSayPed

	//=================================================================================================
	oDlgMain	:= MSDialog():new(aTam[1],aTam[2],aTam[6],aTam[5],"Ordens de Serviço",,,,,CLR_BLACK,CLR_WHITE,,,.t.)

	oGrpOS := TGroup():New(aPosObj[1,1],aPosObj[1,2],aPosObj[1,3],aPosObj[1,4],,oDlgMain,,,.T.)

	aGetOS := MontaOS()

	oBrwOS := MsBrGetDBase():new(1,1,445,127,,,,oGrpOS,,,,{||},,{||},,,,,'Ordens de Serviço',.T.,'',.T.,{||},.T.,{||},,)

	oBrwOS:SetArray(aGetOS)

	oBrwOS:AddColumn(TCColumn():new('Num OS'	,{||aGetOS[oBrwOS:nAt,01]},'@!'	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwOS:AddColumn(TCColumn():new('Seq OS'	,{||aGetOS[oBrwOS:nAt,02]},'@!'	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwOS:AddColumn(TCColumn():new('Op.'		,{||aGetOS[oBrwOS:nAt,03]},'@!'	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwOS:AddColumn(TCColumn():new('PG/Crg'	,{||aGetOS[oBrwOS:nAt,04]},'@!'	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwOS:AddColumn(TCColumn():new('Cliente'	,{||aGetOS[oBrwOS:nAt,05]},'@!'	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwOS:AddColumn(TCColumn():new('Pri'		,{||aGetOS[oBrwOS:nAt,06]},'@!'	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwOS:AddColumn(TCColumn():new('End Srv'	,{||aGetOS[oBrwOS:nAt,07]},'@!'	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwOS:AddColumn(TCColumn():new('Serviço'	,{||aGetOS[oBrwOS:nAt,08]},'@!'	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwOS:AddColumn(TCColumn():new('Tarefa'	,{||aGetOS[oBrwOS:nAt,09]},'@!'	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwOS:AddColumn(TCColumn():new('Srv'		,{||aGetOS[oBrwOS:nAt,10]},'@!'	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwOS:AddColumn(TCColumn():new('Trf'		,{||aGetOS[oBrwOS:nAt,11]},'@!'	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwOS:Align := CONTROL_ALIGN_ALLCLIENT
	oBrwOS:Refresh()
	oBrwOS:blDblClick := {|| ViewRes(aGetOS[oBrwOS:nAt,01],aGetOS[oBrwOS:nAt,02]) }

	EnchoiceBar(oDlgMain,{|| ViewRes(aGetOS[oBrwOS:nAt,01],aGetOS[oBrwOS:nAt,02])},{|| oDlgMain:End()},.f.,,/*6*/,/*7*/,.f.,.f.,.f.,.t.,.f.,'TWMSA045')

	oTimer := TTimer():New(15000, {|| aGetOS := MontaOS(), oBrwOS:Refresh() }, oDlgMain )
	oTimer:Activate()
	oDlgMain:Activate()
	//=================================================================================================

Return
//-------------------------------------------------------------------------------------------------
Static Function MainDlg()
	Local aTam		:= MsAdvSize(.F.)
	Local aInfo		:= {aTam[1],aTam[2],aTam[3],aTam[4],3,3}
	Local aObjects	:= {{ 1207 , 350, .T. , .T. , .F. },;
	{ 600 , 350, .T. , .T. , .F. },;
	{ 400 , 250, .F. , .T. , .F. },;
	{ 400 , 250, .F. , .T. , .F. },;
	{ 600 , 650, .F. , .T. , .F. },;
	{ 300 , 450, .F. , .T. , .F. },;
	{ 600 , 150, .F. , .T. , .F. },;
	{ 600 , 450, .F. , .T. , .F. }}
	Local aPosObj	:= MsObjSize(aInfo, aObjects, .T.,.F.)

	//=================================================================================================
	oDlg	:= MSDialog():new(aTam[1],aTam[2],aTam[6],aTam[5],"Montagem de volumes TECADI",,,,,CLR_BLACK,CLR_WHITE,,,.T.)
	//TGroup():New( [ nTop ], [ nLeft ], [ nBottom ], [ nRight ]
	//Quadro Nova Etiqueta
	DlgEtiq(aPosObj[1,1],aPosObj[1,2],aPosObj[1,3],aPosObj[1,4])

	//Quadro Etiqueta volume e código de barras
	DlgBarras(aPosObj[2,1],aPosObj[2,2],aPosObj[2,3],aPosObj[1,4])

	//Quadro pedido
	DlgPed(aPosObj[3,1],aPosObj[3,2],aPosObj[3,3],aPosObj[1,4]/2)

	//Quadro Volume em Montagem
	DlgVol(aPosObj[3,1],(aPosObj[1,4]/2)+3,aPosObj[3,3],aPosObj[1,4])

	//Quadro Itens do pedido de venda
	DlgPV(aPosObj[4,1],aPosObj[1,2],aPosObj[8,3],aPosObj[1,4]/2)

	//Quadro Itens ja conferidos
	DlgConf(aPosObj[4,1],(aPosObj[1,4]/2)+3,aPosObj[6,3],aPosObj[1,4])

	//Quadro Volumes já montados
	DlgMont(aPosObj[7,1],(aPosObj[1,4]/2)+3,aPosObj[7,3],aPosObj[1,4])

	//Quadro Volumes do pedido
	DlgVPed(aPosObj[8,1],(aPosObj[1,4]/2)+3,aPosObj[8,3],aPosObj[1,4])

	oDlg:Activate()
	//=================================================================================================
Return
//-------------------------------------------------------------------------------------------------
Static Function DlgEtiq(x,y,z,k)
	local _lOk := .T.

	//Quadro Nova Etiqueta
	oGrpEtiq := TPanel():New(x,y,,oDlg,,,,,CLR_WHITE,k,z-2,.T.,.T.)

	oBtnPallet := TBtnBmp2():New(000,000,130,025,"ARMIMG32",,,,{|| sfNovoPalete(), AtuBrws(1) },oGrpEtiq,"NOVO PALLET",,.T.)
	oBtnPallet:Align := CONTROL_ALIGN_LEFT

	oBtnVol := TBtnBmp2():New(000,000,130,025,"AVGARMAZEM",,,,{|| sfNovoVolume(), AtuBrws(1) },oGrpEtiq,"NOVO VOLUME",,.T.)
	oBtnVol:Align := CONTROL_ALIGN_LEFT
	//oBtnVol:Disable()

	oBtnEnd := TBtnBmp2():New(000,000,130,025,"FINAL",,,,{|| lExit := .T., SairAtu() },oGrpEtiq,"SAIR",,.T.)
	oBtnEnd:Align := CONTROL_ALIGN_RIGHT

	oBtnOK := TBtnBmp2():New(000,000,130,025,"OK",,,,{|| sfFinalizaOS(@_lOk), SairAtu() },oGrpEtiq,"OK",,.T.)
	oBtnOK:Align := CONTROL_ALIGN_RIGHT

	_oSayAgrp1 := TSay():New(x+10,(k/2)-55,{||"Nova"},oGrpEtiq,, oFont20n,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oSayAgrp2 := TSay():New(x+20,(k/2)-55,{||"Agrupadora"},oGrpEtiq,, oFont20n,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oGetNewAgrupa := TGet():New(x+5,(k/2)+10,{|u| If(PCount()>0,_cNewAgrup:=u,_cNewAgrup)},oGrpEtiq,130,030,_cMskEtiq,{|| (Vazio()) .Or. (sfVldAgrupa(@_lOk, _cNewAgrup, .T.)) },,,oFont40,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNewAgrup")
	_oGetNewAgrupa:bWhen := {|| (_lCtrVolume) }
	_oGetNewAgrupa:lReadOnly := ( ! _lNovoVolume )
	// foco na etq de volume
	_oGetNewAgrupa:SetFocus()

Return
//-------------------------------------------------------------------------------------------------
Static Function DlgBarras(x,y,z,k)

	//Quadro Etiqueta volume e código de barras
	oGrpBar := TPanel():New(x,y,,oDlg,,,,,CLR_WHITE,k,z/2,.T.,.T.)

	// etiqueta agrupadora antiga (origem)
	_oSayOld1 := TSay():New(005,005,{||"Agrupadora"},oGrpBar,,oFont20n,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oSayOld2 := TSay():New(020,005,{||"Origem"},oGrpBar,,oFont20n,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oGetOldAgrupa := TGet():New(009,065,{|u| If(PCount()>0,_cOldAgrup:=u,_cOldAgrup)},oGrpBar,100,020,_cMskEtiq,{|| (Vazio()) .Or. (sfVldAgrupa(@_lOk, _cOldAgrup, .F.)) },,,oFont20n,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cOldAgrup",,)

	// informacoes do produto lido
	_oSayCPr1 := TSay():New(005,k/2,{||"Etiqueta"},oGrpBar,,oFont20n,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oSayCPr2 := TSay():New(020,k/2,{||"Produto (EAN)"},oGrpBar,,oFont20n,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oGetCodProd := TGet():New(009,(k/2)+70,{|u| If(PCount()>0,_cEtqCodBar:=u,_cEtqCodBar)},oGrpBar,100,020, _cMskCodBar, {|| (Vazio()) .Or. (sfVldProd(@oGrpBar, @_lOk, _cTpIdEtiq)) },,,oFont20n,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtqCodBar",,)

	oProd := TSay():New(008,(k/2)+185,{||_cDscProd},oGrpBar,,oFont20,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)

Return
//-------------------------------------------------------------------------------------------------
Static Function DlgPed(x,y,z,k)

	//Quadro pedido
	oGrpPed := TGroup():New(x,y,z,k,,oDlg,,,.T.)

	oSayPed := TSay():New(x+5,005,{||"Pedido: "},oGrpPed,,oFont30n,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)
	oSayNPed:= TSay():New(x+5,060,{||_cPedido},oGrpPed,,oFont30,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)

Return
//-------------------------------------------------------------------------------------------------
Static Function DlgVol(x,y,z,k)
	Local oSayVol

	//Quadro Volume em Montagem
	oGrpVol := TGroup():New(x,y,z,k,,oDlg,,,.T.)

	oSayVol := TSay():New(x+5,y+5,{||"Vol. em Montagem: "},oGrpVol,,oFont30n,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)
	oSayNVol:= TSay():New(x+5,y+165,{||_cNewAgrup},oGrpVol,_cMskEtiq,oFont30,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)

Return
//-------------------------------------------------------------------------------------------------
Static Function DlgPV(x,y,z,k)

	//Quadro Itens do pedido de venda
	oGrpPV := TGroup():New(x,y,z,k,,oDlg,,,.T.)

	oBrwPV := MsBrGetDBase():new(1,1,445,127,,,,oGrpPV,,,,{||},,{||},,,,,'Produtos do Pedido',.T.,'',.T.,{||},.T.,{||},,)

	_aColsDet := GetPV()

	oBrwPV:SetArray(_aColsDet)

	oBrwPV:AddColumn(TCColumn():new('Produto'	,{||_aColsDet[oBrwPV:nAt,01]},'@!'			,,,"LEFT",,.F.,.F.,,,,,))
	oBrwPV:AddColumn(TCColumn():new('Desc Prod'	,{||AllTrim(_aColsDet[oBrwPV:nAt,02])},'@!'	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwPV:AddColumn(TCColumn():new('UM'		,{||_aColsDet[oBrwPV:nAt,03]},'@!'			,,,"LEFT",,.F.,.F.,,,,,))
	oBrwPV:AddColumn(TCColumn():new('Quantidade',{||_aColsDet[oBrwPV:nAt,04]},_cMaskQuant	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwPV:AddColumn(TCColumn():new('Lote'		,{||_aColsDet[oBrwPV:nAt,05]},'@!'			,,,"LEFT",,.F.,.F.,,,,,))
	oBrwPV:Align := CONTROL_ALIGN_ALLCLIENT
	oBrwPV:Refresh()

Return
//-------------------------------------------------------------------------------------------------
Static Function DlgConf(x,y,z,k)

	//Quadro Itens ja conferidos
	oGrpConf := TGroup():New(x,y,z,k,,oDlg,,,.T.)

	oBrwConf := MsBrGetDBase():new(1,1,445,127,,,,oGrpConf,,,,{||},,{||},,,,,'Produtos Conferidos',.T.,'',.T.,{||},.T.,{||},,)

	_aColsConf := GetConf(.T.)

	oBrwConf:SetArray(_aColsConf)

	oBrwConf:AddColumn(TCColumn():new('Etq.Vol'		,{||AllTrim(_aColsConf[oBrwConf:nAt,01])}	,_cMskEtiq	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwConf:AddColumn(TCColumn():new('Produto'		,{||AllTrim(_aColsConf[oBrwConf:nAt,02])}	,'@!'		,,,"LEFT",,.F.,.F.,,,,,))
	oBrwConf:AddColumn(TCColumn():new('Descricao'	,{||AllTrim(_aColsConf[oBrwConf:nAt,03])}	,'@!'		,,,"LEFT",,.F.,.F.,,,,,))
	oBrwConf:AddColumn(TCColumn():new('Quantidade'	,{||_aColsConf[oBrwConf:nAt,04]}			,_cMaskQuant,,,"LEFT",,.F.,.F.,,,,,))
	oBrwConf:AddColumn(TCColumn():new('Qtd Seg UM'	,{||_aColsConf[oBrwConf:nAt,05]}			,_cMaskQuant,,,"LEFT",,.F.,.F.,,,,,))
	oBrwConf:Align := CONTROL_ALIGN_ALLCLIENT
	oBrwConf:Refresh()

Return
//-------------------------------------------------------------------------------------------------
Static Function DlgMont(x,y,z,k)

	//Quadro Volumes já montados
	oDlgMont := TGroup():New(x,y,z,k,,oDlg,,,.T.)

	oSayMont := TSay():New(x+2,y+3,{||"Volume já montados deste pedido: "+AllTrim(Str(nQtdVol))},oDlgMont,,oFont20n,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)

	// -- BOTAO DE ESTORNO
	_oBmpEstorno := TBtnBmp2():New(000,000,030,022,"ESTOMOVI",,,,{|| IIf( sfEstornoVol(AllTrim(_aColsVPd[oBrwVPed:nAt,04])), AtuBrws(1) , Nil) },oDlgMont,"Estornar conferência",,.T.)
	_oBmpEstorno:Align := CONTROL_ALIGN_RIGHT

Return
//-------------------------------------------------------------------------------------------------
Static Function DlgVPed(x,y,z,k)

	//Quadro Volumes do pedido
	oGrpVPed := TGroup():New(x,y,z,k,,oDlg,,,.T.)

	oBrwVPed := MsBrGetDBase():new(1,1,445,127,,,,oGrpVPed,,,,{||},,{||},,,,,'Volumes montados',.T.,'',.T.,{||},.T.,{||},,)

	_aColsVPd := GetVPed(.T.)

	oBrwVPed:SetArray(_aColsVPd)

	oBrwVPed:AddColumn(TCColumn():new('Sts'				,{||AllTrim(_aColsVPd[oBrwVPed:nAt,01])},'@!'		,,,"LEFT",,.F.,.F.,,,,,))
	oBrwVPed:AddColumn(TCColumn():new('Produto'			,{||AllTrim(_aColsVPd[oBrwVPed:nAt,02])},'@!'		,,,"LEFT",,.F.,.F.,,,,,))
	oBrwVPed:AddColumn(TCColumn():new('Desc.Produto'	,{||AllTrim(_aColsVPd[oBrwVPed:nAt,03])},'@!'		,,,"LEFT",,.F.,.F.,,,,,))
	oBrwVPed:AddColumn(TCColumn():new('Etq.Agrupadora'	,{||AllTrim(_aColsVPd[oBrwVPed:nAt,04])},_cMskEtiq	,,,"LEFT",,.F.,.F.,,,,,))
	oBrwVPed:AddColumn(TCColumn():new('Quant'			,{||_aColsVPd[oBrwVPed:nAt,05]}			,_cMaskQuant,,,"LEFT",,.F.,.F.,,,,,))
	oBrwVPed:AddColumn(TCColumn():new('Qtd Seg UM'		,{||_aColsVPd[oBrwVPed:nAt,06]}			,_cMaskQuant,,,"LEFT",,.F.,.F.,,,,,))
	oBrwVPed:AddColumn(TCColumn():new('Lote'			,{||AllTrim(_aColsVPd[oBrwVPed:nAt,07])},'@!'		,,,"LEFT",,.F.,.F.,,,,,))
	oBrwVPed:Align := CONTROL_ALIGN_ALLCLIENT
	oBrwVPed:blDblClick := {|| IIf( sfEstornoVol(AllTrim(_aColsVPd[oBrwVPed:nAt,04])), AtuBrws(1) , Nil) }
	oBrwVPed:Refresh()

Return
//-------------------------------------------------------------------------------------------------
// ** função que valida a etiqueta agrupadora
Static Function sfVldAgrupa(mvOk, mvCodAgrup, mvNovaEtiq)
	// variavel de retorno
	local _lRet := .T.
	// query
	local _cQuery
	// variavel de controle de utilização do volume
	local _cConVol := ""

	// dados do palete original
	local _aPltOrig := {}

	// pesquisa se a etiqueta é valida
	If (_lRet) .And. (mvNovaEtiq)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11")+mvCodAgrup ))
			//U_FtWmsMsg("Identificador da agrupadora não encontrado no sistema!","ATENCAO")
			oGrpEtiq:SetColor(CLR_WHITE,CLR_RED)
			_oSayAgrp1:SetColor(CLR_WHITE,CLR_RED)
			_oSayAgrp2:SetColor(CLR_WHITE,CLR_RED)
			oGrpEtiq:Refresh()
			_lRet := .F.
		ElseIf (Z11->Z11_TIPO != '04')
			//U_FtWmsMsg("Identificador da agrupadora inválido!","ATENCAO")
			oGrpEtiq:SetColor(CLR_WHITE,CLR_RED)
			_oSayAgrp1:SetColor(CLR_WHITE,CLR_RED)
			_oSayAgrp2:SetColor(CLR_WHITE,CLR_RED)
			oGrpEtiq:Refresh()
			_lRet := .F.
		Else
			oGrpEtiq:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayAgrp1:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayAgrp2:SetColor(CLR_BLACK,CLR_WHITE)
			oGrpEtiq:Refresh()
			_lRet := .T.
		EndIf
	EndIf

	// valida se a nota etiqueta esta em uso
	If (_lRet) .And. (mvNovaEtiq)

		// prepara query
		_cQuery := " SELECT COUNT(*) QTD_REG "
		_cQuery += " FROM   "+RetSqlTab("Z16") + " (nolock) "
		_cQuery += " WHERE  "+RetSqlCond("Z16")
		_cQuery += "       AND Z16_ETQVOL = '" + mvCodAgrup + "' "
		_cQuery += "       AND Z16_SALDO != 0 "
		_cQuery += "       AND Z16_PEDIDO != '" + _cPedido + "' "
		_cQuery += "       AND Z16_PEDIDO != ' ' "
		_cQuery += "       AND Z16_ORIGEM = 'VOL' "

		// executa query e validacao
		If (U_FtQuery(_cQuery) != 0)
			// mensagem
			//U_FtWmsMsg("Essa etiqueta de volume já foi utilizada. Favor verificar e utilizar uma nova etiqueta de volume!","ATENCAO")
			oGrpEtiq:SetColor(CLR_WHITE,CLR_RED)
			_oSayAgrp1:SetColor(CLR_WHITE,CLR_RED)
			_oSayAgrp2:SetColor(CLR_WHITE,CLR_RED)
			oGrpEtiq:Refresh()
			// variavel de retorno
			_lRet := .F.
		Else
			oGrpEtiq:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayAgrp1:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayAgrp2:SetColor(CLR_BLACK,CLR_WHITE)
			oGrpEtiq:Refresh()
			_lRet := .T.
		EndIf

	EndIf

	// se o volume já foi usado uma vez na mesma montagem
	If (_lRet) .And. (mvNovaEtiq)

		// query de validação do uso do volume
		_cQuery := " SELECT Z07_PEDIDO "
		// filtro na table de conferência
		_cQuery += " FROM " + RetSqlTab("Z07") + " (nolock) "
		// join pra validar somente as que são do tipo de S-SAÍDA
		_cQuery += " INNER JOIN " + RetSqlTab("Z05") + " (nolock)  ON Z05_NUMOS = Z07_NUMOS AND Z05_TPOPER = 'S' AND " + RetSqlCond("Z05")
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z07")
		// codigo da etiqueta agrupadora
		_cQuery += " AND Z07_ETQVOL = '" + mvCodAgrup + "' "

		// jogo o resultado da query para a variavel para validar
		_cConVol := U_FtQuery(_cQuery)

		// se encontrou algum registro, vai informar ao usuário
		If ( ! Empty(_cConVol))
			// mensagem
			//U_FtWmsMsg("Essa etiqueta de volume já foi usada no pedido "+_cConVol+". Favor verificar!","ATENCAO")
			oGrpEtiq:SetColor(CLR_WHITE,CLR_RED)
			_oSayAgrp1:SetColor(CLR_WHITE,CLR_RED)
			_oSayAgrp2:SetColor(CLR_WHITE,CLR_RED)
			oGrpEtiq:Refresh()
			// variavel de retorno
			_lRet := .F.
		Else
			oGrpEtiq:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayAgrp1:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayAgrp2:SetColor(CLR_BLACK,CLR_WHITE)
			oGrpEtiq:Refresh()
			_lRet := .T.
		EndIf

	EndIf

	// valida se a etiqueta antiga esta disponivel
	If (_lRet) .And. ( ! mvNovaEtiq )

		// funcao que retorna a composicao do palete, conforme etiqueta agrupadora
		//  estrutura:
		//  1- Id Palete
		//  2- Cod. Produto
		//  3- Etq Produto
		//  4- Etq Volume
		//  5. Saldo
		//  6. End. Atual
		//  7. Saldo Atual
		//  8. Tipo de Estoque
		//  9. Lote
		// 10. Validade Lote
		_aPltOrig := sfRetCompos(mvCodAgrup, Nil)

		// valida se encontrou dados
		If (Len(_aPltOrig) == 0)
			// mensagem
			//U_FtWmsMsg("Etiqueta de volume não encontrada!","ATENCAO")
			oGrpBar:SetColor(CLR_WHITE,CLR_RED)
			_oSayOld1:SetColor(CLR_WHITE,CLR_RED)
			_oSayOld2:SetColor(CLR_WHITE,CLR_RED)
			_oSayCPr1:SetColor(CLR_WHITE,CLR_RED)
			_oSayCPr2:SetColor(CLR_WHITE,CLR_RED)
			oGrpBar:Refresh()
			// variavel de retorno
			_lRet := .F.
		Else
			oGrpBar:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayOld1:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayOld2:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayCPr1:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayCPr2:SetColor(CLR_BLACK,CLR_WHITE)
			oGrpBar:Refresh()
		EndIf

		// atualiza variaveis
		If (_lRet) .And. (Len(_aPltOrig) > 0)
			_cPltOrig := _aPltOrig[1][1]
		EndIf

	EndIf

	// pra retornar o parâmetro da rotina
	mvOk := _lRet

	// atualiza objetos
	If (_lRet)
		// quando for leitura de nova etiqueta
		If (mvNovaEtiq)
			// atualiza variaveis de controle
			_lNovoVolume := .F.
			// atualiza objetos
			_oGetNewAgrupa:lReadOnly := ( ! _lNovoVolume)
		EndIf
		oSayNVol:Refresh()
	EndIf

	// retorno a variavel
Return (_lRet)
//-------------------------------------------------------------------------------------------------
// ** funcao para validacao do codigo do produto digitado (lido)
Static Function sfVldProd(mvDlg, mvOk, mvTpIdEtiq)
	// query
	Local _cQuery := ""
	// controla se informa a quantidade manual
	Local _lInfManual := .F.
	// controle de retorno
	local _lRet := .T.
	// num seq do documento de entrada
	local _cNumSeq := ""
	// controle de for
	local _nX := 0

	// dados do palete original
	local _aPltOrig := {}
	//local _nPltOrig

	// verifica se foi informado a etiqueta do produto
	If ( Empty(_cEtqCodBar) )
		// mensagem
		U_FtWmsMsg("É necessário informar a etiqueta do produto!","ATENCAO")
		oGrpBar:SetColor(CLR_WHITE,CLR_RED)
		_oSayOld1:SetColor(CLR_WHITE,CLR_RED)
		_oSayOld2:SetColor(CLR_WHITE,CLR_RED)
		_oSayCPr1:SetColor(CLR_WHITE,CLR_RED)
		_oSayCPr2:SetColor(CLR_WHITE,CLR_RED)
		oGrpBar:Refresh()
		// variavel de controle
		_lRet := .F.
	Else
		oGrpBar:SetColor(CLR_BLACK,CLR_WHITE)
		_oSayOld1:SetColor(CLR_BLACK,CLR_RED)
		_oSayOld2:SetColor(CLR_BLACK,CLR_RED)
		_oSayCPr1:SetColor(CLR_BLACK,CLR_RED)
		_oSayCPr2:SetColor(CLR_BLACK,CLR_RED)
		oGrpBar:Refresh()
		_lRet := .T.
	EndIf

	// verifica se foi informado a etiqueta do novo volumes
	If ( Empty(_cNewAgrup) )
		// mensagem
		U_FtWmsMsg("É necessário informar a etiqueta de DESTINO!","ATENCAO")
		oGrpBar:SetColor(CLR_WHITE,CLR_RED)
		_oSayOld1:SetColor(CLR_WHITE,CLR_RED)
		_oSayOld2:SetColor(CLR_WHITE,CLR_RED)
		_oSayCPr1:SetColor(CLR_WHITE,CLR_RED)
		_oSayCPr2:SetColor(CLR_WHITE,CLR_RED)
		oGrpBar:Refresh()
		// variavel de controle
		_lRet := .F.
	Else
		oGrpBar:SetColor(CLR_BLACK,CLR_WHITE)
		_oSayOld1:SetColor(CLR_BLACK,CLR_RED)
		_oSayOld2:SetColor(CLR_BLACK,CLR_RED)
		_oSayCPr1:SetColor(CLR_BLACK,CLR_RED)
		_oSayCPr2:SetColor(CLR_BLACK,CLR_RED)
		oGrpBar:Refresh()
		_lRet := .T.
	EndIf

	// realiza a pesquisa do produto, podendo ser feita pelo codigo de barras
	If (_lRet) .And. ( ! U_FtCodBar(@_cEtqCodBar, @_cCodProd, @_lInfManual, @_cNumSeq, mvTpIdEtiq, _cCodCliFor))
		// mensagem
		U_FtWmsMsg("Dados do produto não encontrados.","ATENCAO")
		oGrpBar:SetColor(CLR_WHITE,CLR_RED)
		_oSayOld1:SetColor(CLR_WHITE,CLR_RED)
		_oSayOld2:SetColor(CLR_WHITE,CLR_RED)
		_oSayCPr1:SetColor(CLR_WHITE,CLR_RED)
		_oSayCPr2:SetColor(CLR_WHITE,CLR_RED)
		oGrpBar:Refresh()
		// variavel de retorno
		_lRet := .F.
	Else
		oGrpBar:SetColor(CLR_BLACK,CLR_WHITE)
		_oSayOld1:SetColor(CLR_BLACK,CLR_RED)
		_oSayOld2:SetColor(CLR_BLACK,CLR_RED)
		_oSayCPr1:SetColor(CLR_BLACK,CLR_RED)
		_oSayCPr2:SetColor(CLR_BLACK,CLR_RED)
		oGrpBar:Refresh()
		_lRet := .T.
	EndIf

	// valida se o produto lido faz parte do pedido
	If (_lRet)

		// filtra dados do pedido de venda
		_cQuery := " SELECT COUNT(*) QTD_PEDIDO "
		// itens do pedido de venda
		_cQuery += " FROM " + RetSqlTab("SC6") + " (nolock) "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("SC6")
		// numero do pedido
		_cQuery += " AND C6_NUM = '" + _cPedido + "' "
		// codigo do produto
		_cQuery += " AND C6_PRODUTO = '" + _cCodProd + "' "

		// valida quantidade do item conferido
		If (U_FtQuery(_cQuery) == 0)
			// mensagem
			U_FtWmsMsg("Produto não pertence ao pedido " + _cPedido, "ATENCAO")
			oGrpBar:SetColor(CLR_WHITE,CLR_RED)
			_oSayOld1:SetColor(CLR_WHITE,CLR_RED)
			_oSayOld2:SetColor(CLR_WHITE,CLR_RED)
			_oSayCPr1:SetColor(CLR_WHITE,CLR_RED)
			_oSayCPr2:SetColor(CLR_WHITE,CLR_RED)
			oGrpBar:Refresh()
			// variavel de retorno
			_lRet := .F.
		Else
			oGrpBar:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayOld1:SetColor(CLR_BLACK,CLR_RED)
			_oSayOld2:SetColor(CLR_BLACK,CLR_RED)
			_oSayCPr1:SetColor(CLR_BLACK,CLR_RED)
			_oSayCPr2:SetColor(CLR_BLACK,CLR_RED)
			oGrpBar:Refresh()
			_lRet := .T.
		EndIf

	EndIf

	// valida se o produtos compoe a agrupadora
	If (_lRet)

		// funcao que retorna a composicao do palete, conforme etiqueta agrupadora
		//  estrutura:
		//  1- Id Palete
		//  2- Cod. Produto
		//  3- Etq Produto
		//  4- Etq Volume
		//  5. Saldo
		//  6. End. Atual
		//  7. Saldo Atual
		//  8. Tipo de Estoque
		//  9. Lote
		// 10. Validade Lote
		_aPltOrig := sfRetCompos(_cOldAgrup, _cCodProd)

		// valida se encontrou dados
		If (Len(_aPltOrig) == 0)
			// mensagem
			U_FtWmsMsg("Produto não pertence a essa etiqueta de volume!", "ATENCAO")
			oGrpBar:SetColor(CLR_WHITE,CLR_RED)
			_oSayOld1:SetColor(CLR_WHITE,CLR_RED)
			_oSayOld2:SetColor(CLR_WHITE,CLR_RED)
			_oSayCPr1:SetColor(CLR_WHITE,CLR_RED)
			_oSayCPr2:SetColor(CLR_WHITE,CLR_RED)
			oGrpBar:Refresh()
			// variavel de retorno
			_lRet := .F.
		Else
			oGrpBar:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayOld1:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayOld2:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayCPr1:SetColor(CLR_BLACK,CLR_WHITE)
			_oSayCPr2:SetColor(CLR_BLACK,CLR_WHITE)
			oGrpBar:Refresh()
			_lRet := .T.
		EndIf

	EndIf

	// atualiza descricao do produto
	_cDscProd := SB1->B1_DESC

	// reinicia a variavel de quantidade
	_nQtdProd  := 1
	_nQtdSegUM := 0

	// verifica se o produto pode informar quantidades
	If (_lRet) .And. (_lInfManual)
		// tela para informar a quantidade
		sfInfQuant()
	EndIf

	// validação do produto a sua respectiva quantidade
	If (_lRet)
		// para cada registro na composição do pallet, consulta o registro e quantidade
		For _nX := 1 to Len(_aPltOrig)
			// com a comparação do produto
			If( _cCodProd == _aPltOrig[_nX][2])
				// valido se a quantidade solicitada é maior do que a quantidade disponível
				If (_nQtdProd > _aPltOrig[_nX][7])
					// mensagem
					U_FtWmsMsg("A quantidade informada é maior do que o saldo do produto!","ATENCAO")
					// variavel de retorno
					_lRet := .F.
				EndIf
			EndIf
		Next _nX
	EndIf

	// se validou todos os itens, grava item conferido
	If (_lRet) .And. (_nQtdProd > 0)

		// insere quantidade lida na relacao de itens
		For _nPltOrig := 1 to Len(_aPltOrig)
			dbSelectArea("Z07")
			RecLock("Z07",.T.)
			Z07->Z07_FILIAL	:= xFilial("Z07")
			Z07->Z07_NUMOS	:= _cNumOrdSrv
			Z07->Z07_SEQOS	:= _cSeqOrdSrv
			Z07->Z07_CLIENT	:= _cCodCliFor
			Z07->Z07_LOJA	:= _cLojCliFor
			Z07->Z07_ETQPRD	:= _cEtiqProd
			Z07->Z07_PRODUT	:= _cCodProd
			Z07->Z07_NUMSEQ	:= _cNumSeq
			Z07->Z07_LOCAL	:= _cArmzServ
			Z07->Z07_QUANT	:= _nQtdProd
			Z07->Z07_QTSEGU := _nQtdSegUM
			Z07->Z07_NRCONT	:= _cNrContagem
			Z07->Z07_USUARI := _cCodOper
			Z07->Z07_DATA	:= Date()
			Z07->Z07_HORA	:= Time()
			Z07->Z07_PALLET	:= _cIdPalete
			Z07->Z07_PLTORI := _cPltOrig
			Z07->Z07_UNITIZ := _cCodUnit
			Z07->Z07_STATUS	:= "C" // C-EM CONFERENCIA / D-CONFERIDO/DISPONIVEL / M-EM MOVIMENTO / A-ARMAZENADO
			Z07->Z07_ENDATU	:= _cDocaSrv
			Z07->Z07_PEDIDO := _cPedido
			Z07->Z07_ETQVOL := _cNewAgrup
			Z07->Z07_VOLORI := _cOldAgrup
			Z07->Z07_CODBAR := _cEtqCodBar //Z07->Z07_EMBALA := _cTpEmbala
			Z07->Z07_TPESTO := _aPltOrig[_nPltOrig][ 8] // tipo de estoque do pallet de origem
			Z07->Z07_LOTCTL := _aPltOrig[_nPltOrig][ 9] // lote
			Z07->Z07_VLDLOT := _aPltOrig[_nPltOrig][10] // validade lote
			Z07->(MsUnLock())
		Next _nPltOrig

		// atualiza os dados do browse
		AtuBrws(2)
		//sfSelDados(.T.)

	EndIf

	// reinicia variaveis
	_cCodProd   := Space(_nTamCodPrd)
	//_cDscProd   := ""
	_cEtiqProd  := Space(Len(_cEtiqProd))
	_cEtqCodBar := Space(Len(_cEtqCodBar))

	// foca no objeto cod produto
	_oGetCodProd:SetFocus()

Return(.T.)
//-------------------------------------------------------------------------------------------------
// ** funcao que monta a query principal
Static Function sfMontaQuery()
	local _cRetQry := ""

	// busca as movimentacoes
	_cRetQry := "SELECT DISTINCT Z05_NUMOS, Z06_SEQOS, "
	// descricao da operacao
	_cRetQry += "CASE "
	_cRetQry += "  WHEN Z05_TPOPER = 'E' THEN 'REC' "
	_cRetQry += "  WHEN Z05_TPOPER = 'S' THEN 'EXP' "
	_cRetQry += "  WHEN Z05_TPOPER = 'I' THEN 'INT' "
	_cRetQry += "END DSC_OPER, "
	// programacao ou pedido
	_cRetQry += "CASE "
	_cRetQry += "  WHEN Z05_TPOPER = 'E' THEN Z05_PROCES "
	_cRetQry += "  WHEN Z05_TPOPER = 'S' THEN Z05_CARGA "
	_cRetQry += "  WHEN Z05_TPOPER = 'I' THEN ' ' "
	_cRetQry += "END PG_CARGA, "
	// cliente
	_cRetQry += "ISNULL(A1_NREDUZ,'OS INTERNA') A1_NREDUZ, Z06_PRIOR, "
	_cRetQry += "Z06_SERVIC, SX5SRV.X5_DESCRI DSC_SERVIC, Z06_TAREFA, SX5TRF.X5_DESCRI DSC_TAREFA, "
	_cRetQry += "Z06_STATUS, "
	_cRetQry += "Z05_CLIENT, Z05_LOJA, "
	// endereco de servico
	_cRetQry += "CASE WHEN Z06_ENDSRV = 'ZZZ' THEN 'XXX' ELSE Z06_ENDSRV END Z06_ENDSRV "

	// cabecalho da OS
	_cRetQry += " FROM "+RetSqlTab("Z05")+" (NOLOCK) "

	// cad. cliente
	_cRetQry += " LEFT  JOIN "+RetSqlTab("SA1")+" (NOLOCK) ON "+RetSqlCond("SA1")+" AND A1_COD = Z05_CLIENT AND A1_LOJA = Z05_LOJA "

	//Mapa de Separação
	_cRetQry += " LEFT  JOIN "+RetSqlTab("Z08")+" (NOLOCK) ON "+RetSqlCond("Z08")+" AND Z08_NUMOS = Z05_NUMOS "

	// itens da ordem de servicos
	_cRetQry += " INNER JOIN "+RetSqlTab("Z06")+" (NOLOCK) ON "+RetSqlCond("Z06")+" AND Z06_NUMOS = Z05_NUMOS "

	// filtro especifico do usuario logado
	/*If ( ! Empty(cQryFilZ06) )
	_cRetQry += " AND " + cQryFilZ06
	EndIf*/

	// cad. de servicos
	_cRetQry += "INNER JOIN "+RetSqlName("SX5")+" SX5SRV (NOLOCK) ON SX5SRV.X5_FILIAL = '"+xFilial("SX5")+"' AND SX5SRV.D_E_L_E_T_ = ' ' AND SX5SRV.X5_TABELA = 'L4' AND SX5SRV.X5_CHAVE = Z06_SERVIC "
	// cad. de tarefas
	_cRetQry += "INNER JOIN "+RetSqlName("SX5")+" SX5TRF (NOLOCK) ON SX5TRF.X5_FILIAL = '"+xFilial("SX5")+"' AND SX5TRF.D_E_L_E_T_ = ' ' AND SX5TRF.X5_TABELA = 'L2' AND SX5TRF.X5_CHAVE = Z06_TAREFA "

	// filtro da movimentacoes
	_cRetQry += "WHERE "+RetSqlCond("Z05")+" "

	//memowrit("c:\query\tacda002_montaquery.txt", _cRetQry)

Return(_cRetQry)
//-------------------------------------------------------------------------------------------------
Static Function MontaOS()
	Local mvQryUsr	:= sfMontaQuery()

	aGetOS := {}

	// inclui o codigo do servico de conferencia (montagem) na query
	mvQryUsr += " AND Z06_SERVIC = '001' AND Z06_TAREFA = '007' "
	mvQryUsr += " AND Z06_STATUS IN "+FormatIn("EX",";")
	mvQryUsr += " ORDER BY Z06_PRIOR, Z05_NUMOS"

	//memowrit("C:\query\twmsa024_query.txt", mvQryUsr)

	If Select("tSA045") > 0
		DBSelectArea("tSA045")
		tSA045->(DBCloseArea())
	EndIf

	TCQuery mvQryUsr NEW ALIAS "tSA045"

	DBSelectArea("tSA045")
	tSA045->(DBGoTop())

	if !tSA045->(EOF())
		While !tSA045->(EOF())

			aAdd(aGetOS,{ tSA045->Z05_NUMOS,;
			tSA045->Z06_SEQOS,;
			tSA045->DSC_OPER,;
			tSA045->PG_CARGA,;
			tSA045->A1_NREDUZ,;
			tSA045->Z06_PRIOR,;
			tSA045->Z06_ENDSRV,;
			tSA045->DSC_SERVIC,;
			tSA045->DSC_TAREFA,;
			tSA045->Z06_SERVIC,;
			tSA045->Z06_TAREFA,;
			.F.	 })

			tSA045->(DBSkip())
		EndDo
	Else
		Aadd(aGetOS,{"","","","","","","","","","",.F.})
	EndIf

	tSA045->(DBCloseArea())

Return aGetOS
//-------------------------------------------------------------------------------------------------
Static Function ViewRes(cNumOs,cSeqOS)
	Local lRet := .F.
	Private mvCodServ	:= ""
	Private mvCodTaref	:= ""
	Private mvStatus	:= ""
	Private mvNumOS		:= ""
	Private mvSeqOS		:= ""
	Private mvCodCli	:= ""
	Private mvLojCli	:= ""
	Private mvPriori	:= ""

	lRet := U_ACDA002B(cNumOs, cSeqOS, .T.)

	If lRet

		dbSelectArea("SC5")
		SC5->(dbSetOrder(1)) // 1-C5_FILIAL, C5_NUM
		SC5->(dbSeek( xFilial("SC5") + _cPedido ))

		// posiciona na OS
		dbSelectArea("Z05")
		Z05->(dbSetOrder(1)) // 1-Z05_FILIAL, Z05_NUMOS
		Z05->(dbSeek( xFilial("Z05")+cNumOs ))

		// posiciona no item da OS
		dbSelectArea("Z06")
		Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
		Z06->(dbSeek( xFilial("Z06")+cNumOs+cSeqOS ))

		// posiciona no movimentacao de entrada/saida do veiculo
		dbSelectArea("SZZ")
		SZZ->(dbSetOrder(1)) // 1-ZZ_FILIAL, ZZ_CESV
		SZZ->(dbSeek( xFilial("SZZ")+Z05->Z05_CESV ))

		mvCodServ	:= Z06->Z06_SERVIC
		mvCodTaref	:= Z06->Z06_TAREFA
		mvStatus	:= Z06->Z06_STATUS
		mvNumOS		:= Z06->Z06_NUMOS
		mvSeqOS		:= Z06->Z06_SEQOS
		mvCodCli	:= Z05->Z05_CLIENT
		mvLojCli	:= Z05->Z05_LOJA
		mvPriori	:= Z06->Z06_PRIOR
		mvCarga		:= Z05->Z05_CARGA
		mvOndSep	:= Z05->Z05_ONDSEP

		_cCodServ	:= mvCodServ
		_cCodTaref	:= mvCodTaref
		_cCodStatus	:= mvStatus
		_cNumOrdSrv	:= mvNumOS
		_cSeqOrdSrv	:= mvSeqOS
		_cCodCliFor	:= mvCodCli
		_cLojCliFor	:= mvLojCli

		lRet := sfTRetPed(mvCodCli, mvLojCli, mvCarga, mvOndSep)

		// atualiza armazem
		_cArmzServ := Z06->Z06_LOCAL

		// doca do servico
		_cDocaSrv  := Z06->Z06_ENDSRV

		// atualiza pedido do cliente
		_cPedCliente := SC5->C5_ZPEDCLI

		// atualiza CESV
		_cNumCESV  := Z05->Z05_CESV
		// define o tipo da operacao da OS (Sempre será do tipo S)
		_cTipoOper := Z05->Z05_TPOPER
		_cDscOpera := "Expedição"

		// numero da carga
		_cNrCarga := Z05->Z05_CARGA

		// numero da onda de separacao
		_cNrOndSep := Z05->Z05_ONDSEP

		_lCtrVolume	:= U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.F.,.F.,"", Z05->Z05_CLIENT, Z05->Z05_LOJA, "", Z05->Z05_NUMOS)
		_nTamEtqCli	:= U_FtWmsParam("WMS_QUANT_CARACTERES_ETIQUETA_CLIENTE", "N", TamSx3("Z56_ETQCLI")[1], .F., "", mvCodCli, mvLojCli, Nil, Nil)
		_cTpIdEtiq	:= U_FtWmsParam("WMS_PRODUTO_ETIQ_IDENT","C","INTERNA",.F.,"", mvCodCli, mvLojCli, "", mvNumOS)

		//carrega o tipo de código de barras
		_lEtqIdEAN  := (AllTrim(_cTpIdEtiq) == "EAN") .Or. (AllTrim(_cTpIdEtiq) == "EAN13")
		_lEtqIdDUN  := (AllTrim(_cTpIdEtiq) == "DUN14")
		_lEtqCod128 := (AllTrim(_cTpIdEtiq) == "CODE128")
		_lEtqClient := (AllTrim(_cTpIdEtiq) == "CLIENTE")

		// prepara tamanho do codigo de barras
		If (_lEtqIdEAN)
			_cEtqCodBar := Space(13)
			_cMskCodBar := "@R " + Replicate("9", Len(_cEtqCodBar))
		ElseIf (_lEtqCod128)
			_cEtqCodBar := CriaVar("B1_CODBAR", .F.)
			_cMskCodBar := "@!"
		ElseIf (_lEtqIdDUN)
			_cEtqCodBar := Space(14)
			_cMskCodBar := "@R " + Replicate("9", Len(_cEtqCodBar))
		ElseIf (_lEtqClient)
			_cEtqCodBar := Space(_nTamEtqCli)
			_cMskCodBar := "@!"
		EndIf

		//verifica se a OS está em um estado válido (execução) pois pode ter sido alterada por outro conferente ou rotina, ainda que dentro do laço
		If (Z06->Z06_STATUS != 'EX')
			// mensagem
			U_FtWmsMsg("O status da ordem de serviço " + Z06->Z06_NUMOS + " é inválido (" + Z06->Z06_STATUS + "). Verifique com o supervisor. A tela será fechada.","Erro")
			// retorno
			Return(.F.)
		Endif

		If lRet

			// se nao controla por volume, nao permite o uso da funcao
			If ( ! _lCtrVolume )
				U_FtWmsMsg("Rotina disponível somente para contratos com controle de expedição por volume.","Atenção")
				lRet := .F.
				Return (lRet)
			Else
				MainDlg()
			EndIf

		EndIf
	EndIF

Return lRet
//-------------------------------------------------------------------------------------------------
// ** função da tela todos os pedidos daquela carga
Static Function sfTRetPed(mvCodCli, mvLojCli, mvCarga, mvOndSep)

	// variavel de controle
	local _lRet := .F.
	// objetos locais
	local _oBmpOk, _oBmpSair, _oBrwPedidos, _oBmpFim
	local _oPnlPedCab, _oPnlPedRod
	local _oGetChvNfv

	// arrays do browse
	local _aHeadPed  := {}
	// define o acols
	local _aColsPed := sfARetPed(mvCodCli, mvLojCli, mvCarga, mvOndSep)

	// controle se a chave da nota foi encontrada
	local _lChaveOk := .F.

	// chave da nota fiscal de venda
	private _cChvNfVen := CriaVar("C5_ZCHVNFV", .F.)
	private _oWmsPedidos

	// monta o dialogo do monitor
	_oWmsPedidos := MSDialog():New(000,000,300,400,"Pedidos da Carga",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes de operacao
	_oPnlPedCab := TPanel():New(000,000,nil,_oWmsPedidos,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlPedCab:Align:= CONTROL_ALIGN_TOP

	// botao que seleciona um pedido
	_oBmpOk := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| _cPedido := _oBrwPedidos:aCols[_oBrwPedidos:nAt][2], _lRet := VldPedFin(_oBrwPedidos:aCols[_oBrwPedidos:nAt][2]) },_oPnlPedCab,"OK",,.T.)
	_oBmpOk:Align := CONTROL_ALIGN_LEFT

	// botao para encerrar a montagem (se tudo já foi concluído)
	_oBmpFim := TBtnBmp2():New(000,000,060,022,"sdusetdel",,,,{|| IIf (_lRet := sfFimOS(mvCodCli, mvLojCli, mvCarga, mvOndSep) , _oWmsPedidos:End(), Nil ) },_oPnlPedCab,"Finalizar montagem",,.T.)
	_oBmpFim:Align := CONTROL_ALIGN_LEFT

	// botao que sai
	_oBmpSair := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| _lContConf := .F., _oWmsPedidos:End()},_oPnlPedCab,"Sair",,.T.)
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// define array do browse
	aAdd(_aHeadPed,{"Sts"           , "IT_ZMNTVOL" ,"@!" ,2                      ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Pedido"        , "C9_PEDIDO"  ,"@!" ,TamSx3("C9_PEDIDO")[1] ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Agrupador"     , "C5_ZAGRUPA" ,"@!" ,TamSx3("C5_ZAGRUPA")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Ped.Cliente"   , "C5_ZPEDCLI" ,"@!" ,TamSx3("C5_ZPEDCLI")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Chave Nf Venda", "C5_ZCHVNFV" ,"@!" ,TamSx3("C5_ZCHVNFV")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })

	// cria o panel para o campo de confirmacao do endereco
	_oPnlPedRod := TPanel():New(000,000,nil,_oWmsPedidos,,.F.,.F.,,CLR_LIGHTGRAY,22,22,.T.,.F.)
	_oPnlPedRod:Align:= CONTROL_ALIGN_TOP

	// leitura do codigo da chave da nota fiscal
	_oGetChvNfv := TGet():New(001,002,{|u| If(PCount()>0,_cChvNfVen:=u ,_cChvNfVen )}, _oPnlPedRod, 113, 008,'@!',{|| (Vazio()) .Or. (sfVldChvNfv(_cChvNfVen, @_oBrwPedidos, _aHeadPed, @_lChaveOk )), IIf(_lChaveOk, _oBmpOk:Click(), Nil) },,,,,,.T.,"",, Nil,.F.,.F.,,.F.,.F.,""  ,"_cChvNfVen"  ,,,,,, .T. ,"Chave Nota Venda", 1)

	// browse
	_oBrwPedidos := MsNewGetDados():New(078,000,148,118,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsPed),'AllwaysTrue()','','AllwaysTrue()',_oWmsPedidos,_aHeadPed,_aColsPed)
	_oBrwPedidos:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwPedidos:oBrowse:blDblClick := {|| _oBmpOk:Click() }

	// ativacao da tela
	ACTIVATE MSDIALOG _oWmsPedidos

Return (_lRet)
//-------------------------------------------------------------------------------------------------
Static Function VldPedFin(cPedido)
	Local lRet := .T.

	dbSelectArea("SC5")
	SC5->(dbSetOrder(1)) // 1-C5_FILIAL, C5_NUM
	SC5->(dbSeek( xFilial("SC5") + cPedido ))

	If (SC5->C5_ZMNTVOL == "S")
		U_FtWmsMsg("O pedido "+cPedido+" já está finalizado.","Atenção")
		lRet := .F.
	Else
		_oWmsPedidos:End()
	EndIf

Return lRet
//-------------------------------------------------------------------------------------------------
// ** função que retorna o array de pedidos
Static Function sfARetPed(mvCodCli, mvLojCli, mvCarga, mvOndSep)
	// array que vai receber os dados
	local _aPedidos := {}
	// query para busca de pedidos
	local _cQuery := ""

	// busco os pedidos baseado na carga
	_cQuery += " SELECT DISTINCT CASE "
	_cQuery += "                   WHEN C5_ZMNTVOL = 'S' THEN 'OK' "
	_cQuery += "                   ELSE '  ' "
	_cQuery += "                 END   IT_ZMNTVOL, "
	_cQuery += "                 C9_PEDIDO, "
	_cQuery += "                 C5_ZAGRUPA, "
	_cQuery += "                 C5_ZPEDCLI, "
	_cQuery += "                 C5_ZCHVNFV, "
	_cQuery += "                 '.F.' IT_DEL "
	// itens linerados do pedido
	_cQuery += " FROM   " + RetSqlTab("SC9") + " (nolock) "
	// cab. pedido de venda
	_cQuery += "        INNER JOIN " + RetSqlTab("SC5") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("SC5")
	_cQuery += "                   AND C5_TIPOOPE = 'P' "
	_cQuery += "                   AND C5_NUM = C9_PEDIDO "
	// filtro por onda de separacao
	If ( ! Empty(mvOndSep) )
		_cQuery += "                   AND C5_ZONDSEP = '" + mvOndSep + "' "
	EndIf
	// filtro padrao
	_cQuery += " WHERE  " + RetSqlCond("SC9")
	// cliente e loja
	_cQuery += "        AND C9_CLIENTE = '" + mvCodCli + "' "
	_cQuery += "        AND C9_LOJA = '" + mvLojCli + "' "
	// filtro por carga
	If ( ! Empty(mvCarga) )
		_cQuery += "        AND C9_CARGA = '" + mvCarga + "' "
	EndIf
	// ordem dos dados
	_cQuery += " ORDER  BY C9_PEDIDO "

	//memowrit("C:\query\twmsa024_sfARetPed.txt",_cQuery)

	// jogo os dados pro array
	_aPedidos := U_SqlToVet(_cQuery)

	// retorno o array
Return (_aPedidos)
//-------------------------------------------------------------------------------------------------
Static Function GetVPed()
	Local _aCols		:= {}
	Local _nQtdTot		:= 0
	Local _nQtdSegum	:= 0
	Local _nTotPalete	:= 0


	// monta a query
	_cQuery := " SELECT CASE WHEN Z07_STATUS = 'C' THEN '  ' ELSE 'OK' END Z07_STATUS, B1_COD, B1_DESC, Z07_ETQVOL, SUM(Z07_QUANT) Z07_QUANT, SUM(Z07_QTSEGU) Z07_QTSEGU, Z07_LOTCTL, '.F.' IT_DEL "
	// itens conferidos
	_cQuery += " FROM "+RetSqlTab("Z07")+" (nolock) "
	// cad. produtos
	_cQuery += " INNER JOIN "+RetSqlTab("SB1")+" (nolock)  ON "+RetSqlCond("SB1")+" AND B1_COD = Z07_PRODUT "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z07")
	// ordem de servico
	_cQuery += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	// cliente
	_cQuery += " AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
	// pedido
	_cQuery += " AND Z07_PEDIDO = '"+_cPedido+"' "
	// agrupamento dos dados
	_cQuery += " GROUP BY Z07_STATUS, Z07_ETQVOL, B1_COD, B1_DESC, Z07_LOTCTL "
	// ordem dos dados
	_cQuery += " ORDER BY Z07_ETQVOL "

	//memowrit("C:\query\TWSMA024_sfDetConfer.txt",_cQuery)

	// atualiza o vetor do browse
	_aCols := U_SqlToVet(_cQuery)

	// calcula a quantidade total
	aEval(_aCols,{|x| _nQtdTot += x[5], _nQtdSegum += x[6], _nTotPalete ++ })

	nQtdVol := Len(_aCols)


	If Empty(_aCols)
		AADD(_aCols,{"", "", "" , "",0 ,0 , "", .F.})
	EndIf

	// adiciona a linha com o total
	aAdd(_aCols,{"", "", "TOTAL"    , "",_nQtdTot   , _nQtdSegum, "", .F.})
	aAdd(_aCols,{"", "", "TOTAL PLT", "",_nTotPalete, 0         , "", .F.})

Return _aCols
//-------------------------------------------------------------------------------------------------
Static Function GetPV()
	Local _aColsDet	:= {}
	Local _cQuery	:= ""

	// monta a query
	_cQuery := "SELECT "
	_cQuery += "C6_PRODUTO, "
	_cQuery += "B1_DESC, "
	_cQuery += "B1_UM, "
	// quantidade solicitada
	_cQuery += "(SUM(C6_QTDVEN) - IsNull((SELECT SUM(Z07_QUANT) "
	_cQuery += "					FROM "+RetSqlName("Z07")+" Z07 (nolock)  "
	_cQuery += "					where D_E_L_E_T_ = '' "
	_cQuery += "					and Z07_FILIAL = C6_FILIAL "
	_cQuery += "					and Z07_PEDIDO = C6_NUM "
	_cQuery += "					and Z07_PRODUT = C6_PRODUTO "
	_cQuery += "					and Z07_LOTCTL = C6_LOTECTL),0)) C6_QTDVEN, "
	//lote
	_cQuery += "C6_LOTECTL, "
	// controle de item deletado
	_cQuery += "'.F.' IT_DEL "

	// itens do pedido venda
	_cQuery += "FROM "+RetSqlName("SC6")+" SC6 (nolock)  "

	// cad. produtos
	_cQuery += "LEFT JOIN "+RetSqlName("SB1")+" SB1 (nolock)  ON "+RetSqlCond("SB1")+" AND B1_COD = C6_PRODUTO "

	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SC6")+" "

	// filtra numero do pedido
	_cQuery += "AND C6_NUM = '"+_cPedido+"' "

	// agrupa dados
	_cQuery += "GROUP BY C6_PRODUTO, "
	_cQuery += "B1_DESC, "
	_cQuery += "B1_UM, "
	_cQuery += "C6_LOTECTL,C6_FILIAL,C6_NUM "

	// ordem dos dados
	_cQuery += "ORDER BY C6_PRODUTO "

	//memowrit("C:\query\GetPV.txt",_cQuery)

	// atualiza o vetor do browse
	_aColsDet := U_SqlToVet(_cQuery)

Return _aColsDet
//-------------------------------------------------------------------------------------------------
Static Function GetConf(lInicio)
	Local _aCols := {}

	If !lInicio
		// monta a query para buscar os itens já conferidos
		_cQuery := " SELECT Z07_ETQVOL, Z07_PRODUT, B1_DESC, SUM(Z07_QUANT) Z07_QUANT, SUM(Z07_QTSEGU) Z07_QTSEGU "
		// tabela de itens conferidos
		_cQuery += " FROM "+RetSqlTab('Z07')+" (nolock) "
		// cadastro de produtos
		_cQuery += " INNER JOIN "+RetSqlTab('SB1')+" (nolock)  ON "+RetSqlCond("SB1")+" AND B1_COD = Z07_PRODUT "
		// filtros
		_cQuery += " WHERE "+RetSqlCond("Z07")+" "
		_cQuery += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		_cQuery += " AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
		_cQuery += " AND Z07_NRCONT = '"+_cNrContagem+"' "
		_cQuery += " AND Z07_PEDIDO = '"+_cPedido+"' " // somente do pedido selecionado anteriormente

		_cQuery += " AND Z07_ETQVOL = '"+_cNewAgrup+"' "
		// somente que nao C-EM CONFERENCIA
		_cQuery += " AND Z07_STATUS = 'C' "
		// agrupamento de informacoes
		_cQuery += " GROUP BY Z07_ETQVOL, Z07_PRODUT, B1_DESC "
		// ordem dos dados
		_cQuery += " ORDER BY Z07_ETQVOL, Z07_PRODUT "

		//memowrit("c:\query\twmsa024_sfSelDados.txt",_cQuery)

		// atualiza o vetor do browse
		_aCols := U_SqlToVet(_cQuery)
	EndIf

	If Empty(_aCols)
		AADD(_aCols,{"","","",0,0,.F.})
	EndIf

Return _aCols
//-------------------------------------------------------------------------------------------------
// ** funcao que retorna os dados da camposicao do palete, comforme etiqueta agrupadora
Static Function sfRetCompos(mvEtqAgrup, mvCodProd)
	// variavel de retorno
	local _aRet := {}
	// query
	local _cQuery

	// valores padroes
	Default mvEtqAgrup := Space(_nTamEtqInt)
	Default mvCodProd  := Space(_nTamCodPrd)

	// query de validação do uso do volume
	_cQuery := " SELECT Z16_ETQPAL, Z16_CODPRO, Z16_ETQPRD, Z16_ETQVOL, SUM(Z16_SALDO) Z16_SALDO, Z16_ENDATU, "
	// consulta de saldo para que os registros não fiquem  negativos na Z16
	_cQuery += " Isnull(Sum(Z16_SALDO) - "
	_cQuery += " (SELECT Isnull(Sum(Z07_QUANT),0) FROM "+RetSqlTab("Z07")+" (nolock) "
	_cQuery += "  WHERE "+RetSqlCond("Z07")
	_cQuery += "   AND ( Z07_ETQVOL = Z16_ETQVOL "
	_cQuery += "      OR Z07_VOLORI = Z16_ETQVOL ) "
	_cQuery += "   AND Z07_PLTORI = Z16_ETQPAL "
	_cQuery += "   AND Z07_PRODUT = Z16_CODPRO "
	_cQuery += "   AND Z07_ENDATU = Z16_ENDATU "
	_cQuery += "   AND Z07_STATUS = 'C'), 0) SALDOPLT, " // usar somente status C pois o status D já teve o saldo baixado
	// tipo de estoque
	_cQuery += " Z16_TPESTO, "
	// lote ctl
	_cQuery += " Z16_LOTCTL, Z16_VLDLOT "
	// mapa de separacao
	_cQuery += " FROM "+RetSqlTab("Z08")+" (nolock) "
	// composicao de paletes
	_cQuery += " INNER JOIN "+RetSqlTab("Z16")+" (nolock)  ON "+RetSqlCond("Z16")
	// codigo id do palete
	_cQuery += " AND Z16_ETQPAL = (CASE WHEN Z08_NEWPLT <> ' ' THEN Z08_NEWPLT ELSE Z08_PALLET END) "
	// cod. produto
	_cQuery += " AND Z16_CODPRO = Z08_PRODUT "
	// etiqueta do volume
	_cQuery += " AND Z16_ETQVOL = '"+mvEtqAgrup+"' "
	// somente com saldo
	_cQuery += " AND Z16_SALDO > 0 "
	// cadastro produto
	If ( ! Empty(mvCodProd))
		// cad. produto
		_cQuery += " INNER JOIN "+RetSqlTab("SB1")+" (nolock)  ON "+RetSqlCond("SB1")+" AND B1_COD = '"+mvCodProd+"' AND B1_COD = Z16_CODPRO "
		// grupo/sigla
		_cQuery += " AND B1_GRUPO IN (SELECT A1_SIGLA FROM "+RetSqlTab("SA1")+" (nolock)  WHERE "+RetSqlCond("SA1")+" AND A1_COD = '"+_cCodCliFor+"' AND A1_LOJA = '"+_cLojCliFor+"') "
	EndIf
	// filtro do mapa
	_cQuery += " WHERE "+RetSqlCond("Z08")
	// nr da OS
	_cQuery += " AND Z08_NUMOS = '"+_cNumOrdSrv+"' "
	// statuso R=Realizado
	_cQuery += " AND Z08_STATUS = 'R' "
	// agrupa dados
	_cQuery += " GROUP BY Z16_ETQPAL, Z16_CODPRO, Z16_ETQPRD, Z16_ETQVOL, Z16_ENDATU, Z16_TPESTO, Z16_LOTCTL, Z16_VLDLOT "
	// ordem dos dados
	_cQuery += " ORDER BY Z16_ETQPAL"

	MemoWrit("c:\query\twmsa024_sfVldAgrupa_sfRetCompos.txt",_cQuery)

	// dados do palete original
	//  estrutura:
	//  1- Id Palete
	//  2- Cod. Produto
	//  3- Etq Produto
	//  4- Etq Volume
	//  5. Saldo
	//  6. End. Atual
	//  7. Saldo Atual
	//  8. Tipo de Estoque
	//  9. Lote
	// 10. Validade Lote
	_aRet := U_SqlToVet(_cQuery,{"Z16_VLDLOT"})

Return(_aRet)
//-------------------------------------------------------------------------------------------------
Static Function ZeraVars()

	_cEtqCodBar	:= ""
	_cDscProd	:= ""
	_cPedido	:= ""
	mvCodServ	:= ""
	mvCodTaref	:= ""
	mvStatus	:= ""
	mvNumOS		:= ""
	mvSeqOS		:= ""
	mvCodCli	:= ""
	mvLojCli	:= ""
	mvPriori	:= ""
	mvCarga		:= ""
	mvOndSep	:= ""
	_cCodServ	:= ""
	_cCodTaref	:= ""
	_cCodStatus	:= ""
	_cNumOrdSrv	:= ""
	_cSeqOrdSrv	:= ""
	_cCodCliFor	:= ""
	_cLojCliFor	:= ""
	_nTamEtqCli	:= ""
	_cTpIdEtiq	:= ""
	nQtdVol		:= 0
	_nQtdSegUM	:= 0
	_nQtdProd	:= 1
	_aColsDet	:= {}
	_aColsConf	:= {}
	aItem		:= {}
	_lNovoVolume:= .T.
	_lContConf	:= .T.
	_lOk		:= .F.
	_lCtrVolume	:= .F.
	_cCodProd	:= Space(_nTamCodPrd)
	_cNewAgrup	:= Space(_nTamEtqInt)
	_cOldAgrup	:= Space(_nTamEtqInt)
	_cPltOrig	:= Space(_nTamEtqInt)
	_lNovoPalete:= (Empty(_cIdPalete))

Return
//-------------------------------------------------------------------------------------------------
// ** funcao para informar a quantidade manualmente (para produtos de pequeno porte)
Static Function sfInfQuant()
	// objetos
	local _oBtnFoco1
	local _oGetQuant, _oGetQtdSeg
	// controle para nao fechar a tela
	Local _lRetOk := .F.

	// reinicia segunda unidade de medida
	_nQtdSegUM := 0

	// monta a tela para informa a quantidade
	_oWndInfQuant := MSDialog():New(020,020,200,180,"Informe a Quantidade",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlInfQtdCab := TPanel():New(000,000,nil,_oWndInfQuant,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlInfQtdCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpInfQtdOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRetOk := .T.,_oWndInfQuant:End() },_oPnlInfQtdCab,"Ok",,.T.)
	_oBmpInfQtdOk:Align := CONTROL_ALIGN_LEFT

	// botao para usar como foco (nao é usado pra nada)
	_oBtnFoco1 := TButton():New(033,030,"",_oWndInfQuant,{|| Nil },010,010,,,,.T.,,"",,,,.F. )
	_oGetQuant   := TGet():New(025, 005, {|u| If(PCount()>0,_nQtdProd :=u,_nQtdProd )}, _oWndInfQuant, 060, 010, _cMaskQuant, {|| (Positivo()) .And. (sfVldQuant(2)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nQtdProd" ,,,,,,,"Quantidade ("+SB1->B1_UM+"):"   ,1)
	_oGetQtdSeg  := TGet():New(045, 005, {|u| If(PCount()>0,_nQtdSegUM:=u,_nQtdSegUM)}, _oWndInfQuant, 060, 010, _cMaskQuant, {|| (Positivo()) .And. (sfVldQuant(1)) },,,_oFnt02,,,.T.,"",,{|| ! Empty(SB1->B1_SEGUM) },.F.,.F.,,.F.,.F.,"","_nQtdSegUM",,,,,,,"Qtd Seg UM ("+SB1->B1_SEGUM+"):",1)

	// seta o foco na mensagem
	_oGetQuant:SetFocus()

	// ativacao da tela com validacao
	_oWndInfQuant:Activate(,,,.T.,{|| _lRetOk })

Return

//-------------------------------------------------------------------------------------------------

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

Return(.T.)

//-------------------------------------------------------------------------------------------------

// ** funcao para gerar um novo palete
Static Function sfNovoPalete()
	// query
	local _cUpdZ07, _cUpdZ16, _cQryPalete
	local _lRet := .T.

	// mensagem de confirmacao
	If ( ! U_FtYesNoMsg("Confirma novo palete ?"))
		Return(.F.)
	EndIf

	// inicia transacao
	BEGIN TRANSACTION

		// funcao generica para geracao do Id Palete
		_cIdPalete := U_FtGrvEtq("03",{_cUnitPdr,""})
		// define o codigo do unitizador
		_cCodUnit := Z11->Z11_UNITIZ

		// finaliza os itens conferidos
		_cUpdZ07 := "UPDATE "+RetSqlName("Z07")+" "
		// status finalizado
		_cUpdZ07 += "SET Z07_STATUS = 'D', Z07_PALLET = '"+_cIdPalete+"', Z07_UNITIZ = '"+_cCodUnit+"' "
		// filtro padrao
		_cUpdZ07 += "WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
		// filtro da OS especifica
		_cUpdZ07 += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		// nr contagem
		_cUpdZ07 += "AND Z07_NRCONT = '"+_cNrContagem+"' "
		// status C=Em Conferência
		_cUpdZ07 += "AND Z07_STATUS = 'C' "
		// somente do pedido selecionado anteriormente
		_cUpdZ07 += "AND Z07_PEDIDO = '"+_cPedido+"' "

		// executa o update
		If (TcSQLExec(_cUpdZ07) < 0)
			// rollback na transacao
			DisarmTransaction()
			_lRet := .F.
			U_FtWmsMsg("*** ERRO NA ATUALIZACAO DO SALDO POR PALETE (sfNovoPalete.1) ***"+CRLF+CRLF+TCSQLError(),"ATENCAO")
			Break
		EndIf

		If (_lRet)
			// realiza a formacao da composicao do palete selecionado
			_cQryPalete := " SELECT Z07_LOCAL, Z07_PALLET, Z07_PLTORI, Z07_ETQPRD, Z07_PRODUT, Z07_NUMSEQ, Z07_UNITIZ, SUM(Z07_QUANT) QTD_ENDERE, Z07_EMBALA, Z07_TPESTO, Z07_CODBAR, Z07_ETQVOL, Z07_VOLORI, Z07_ENDATU, Z07_LOTCTL, Z07_VLDLOT, SUM(Z07_QTSEGU) Z07_QTSEGU "
			// itens conferidos da OS
			_cQryPalete += " FROM "+RetSqlTab("Z07")+" (nolock) "
			// filtro padrao
			_cQryPalete += " WHERE " + RetSqlCond("Z07")
			// filtro da OS especifica
			_cQryPalete += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
			// nr contagem
			_cQryPalete += " AND Z07_NRCONT = '"+_cNrContagem+"' "
			// status C=Em Conferência
			_cQryPalete += " AND Z07_STATUS = 'D' "
			// somente do pedido selecionado anteriormente
			_cQryPalete += " AND Z07_PEDIDO = '"+_cPedido+"' "
			// ID Palete
			_cQryPalete += " AND Z07_PALLET = '"+_cIdPalete+"' "
			// agrupa dados
			_cQryPalete += " GROUP BY Z07_LOCAL, Z07_PALLET, Z07_PLTORI, Z07_ETQPRD, Z07_PRODUT, Z07_NUMSEQ, Z07_UNITIZ, Z07_EMBALA, Z07_TPESTO, Z07_CODBAR, Z07_ETQVOL, Z07_VOLORI, Z07_ENDATU, Z07_LOTCTL, Z07_VLDLOT "

			// verifica se a query esta aberta
			If (Select("_QRYIDPLT")<>0)
				dbSelectArea("_QRYIDPLT")
				dbCloseArea()
			EndIf

			// executa a query
			dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQryPalete),"_QRYIDPLT",.F.,.T.)
			dbSelectArea("_QRYIDPLT")

			While _QRYIDPLT->(!Eof())

				// grava os dados
				dbSelectArea("Z16")
				RecLock("Z16",.T.)
				Z16->Z16_FILIAL	:= xFilial("Z16")
				Z16->Z16_ETQPAL	:= _QRYIDPLT->Z07_PALLET
				Z16->Z16_PLTORI := _QRYIDPLT->Z07_PLTORI
				Z16->Z16_UNITIZ	:= _QRYIDPLT->Z07_UNITIZ
				Z16->Z16_ETQPRD	:= _QRYIDPLT->Z07_ETQPRD
				Z16->Z16_CODPRO	:= _QRYIDPLT->Z07_PRODUT
				Z16->Z16_QUANT	:= _QRYIDPLT->QTD_ENDERE
				Z16->Z16_QTSEGU := _QRYIDPLT->Z07_QTSEGU
				Z16->Z16_SALDO  := _QRYIDPLT->QTD_ENDERE
				Z16->Z16_NUMSEQ	:= _QRYIDPLT->Z07_NUMSEQ
				Z16->Z16_STATUS	:= "T" // V=Vazio / T=Total / P=Parcial
				Z16->Z16_QTDVOL	:= _QRYIDPLT->QTD_ENDERE
				Z16->Z16_ENDATU := _QRYIDPLT->Z07_ENDATU
				Z16->Z16_ORIGEM := "VOL"
				Z16->Z16_LOCAL  := _QRYIDPLT->Z07_LOCAL
				Z16->Z16_TPESTO := _QRYIDPLT->Z07_TPESTO
				Z16->Z16_CODBAR := _QRYIDPLT->Z07_CODBAR
				Z16->Z16_EMBALA := _QRYIDPLT->Z07_EMBALA
				Z16->Z16_ETQVOL := _QRYIDPLT->Z07_ETQVOL
				Z16->Z16_VOLORI := _QRYIDPLT->Z07_VOLORI
				Z16->Z16_CARGA  := _cNrCarga
				Z16->Z16_ONDSEP := _cNrOndSep
				Z16->Z16_PEDIDO := _cPedido
				Z16->Z16_DATA   := Date()
				Z16->Z16_HORA   := Time()
				Z16->Z16_LOTCTL := _QRYIDPLT->Z07_LOTCTL
				Z16->Z16_VLDLOT := StoD(_QRYIDPLT->Z07_VLDLOT)
				Z16->(MsUnLock())

				// atualiza o saldo do palete de origem
				_cUpdZ16 := "UPDATE "+RetSqlName("Z16")+" SET Z16_SALDO = Z16_SALDO - "+AllTrim(Str(_QRYIDPLT->QTD_ENDERE))+" "
				// filtro padrao
				_cUpdZ16 += "WHERE Z16_FILIAL = '"+xFilial("Z16")+"' AND D_E_L_E_T_ = ' ' "
				// id do palete ORIGEM
				_cUpdZ16 += "AND Z16_ETQPAL = '"+_QRYIDPLT->Z07_PLTORI+"' "
				// etiqueta produto
				_cUpdZ16 += "AND Z16_ETQPRD = '"+_QRYIDPLT->Z07_ETQPRD+"' "
				// codigo do produto
				_cUpdZ16 += "AND Z16_CODPRO = '"+_QRYIDPLT->Z07_PRODUT+"' "
				// etiqueta de volume ORIGEM
				_cUpdZ16 += "AND Z16_ETQVOL = '"+_QRYIDPLT->Z07_VOLORI+"' "

				// executa o update
				If (TcSQLExec(_cUpdZ16) < 0)
					// rollback na transacao
					DisarmTransaction()
					_lRet := .F.
					// mensagem
					U_FtWmsMsg("*** ERRO NA ATUALIZACAO DO SALDO POR PALETE (sfNovoPalete.2) ***"+CRLF+CRLF+TCSQLError(),"ATENCAO")
					// retorno
					Break
				EndIf

				// proximo item
				_QRYIDPLT->(dbSkip())
			EndDo
		EndIf
		// finaliza transacao
	END TRANSACTION

	if (_lRet)
		// atualiza variaveis
		_lNovoPalete := .T.
		_lNovoVolume := .T.
		_cEtiqProd   := Space(Len(_cEtiqProd))
		_cCodProd    := Space(_nTamCodPrd)
		_nQtdProd    := 1
		_nQtdSegUM   := 0
		_cIdPalete   := Space(_nTamIdPal)
		_cPltOrig    := Space(_nTamIdPal)
		_cNewAgrup   := Space(_nTamEtqInt)
		_cOldAgrup   := Space(_nTamEtqInt)

		// atualiza os dados
		//sfSelDados(.T.)

		// foco no campo
		_oGetNewAgrupa:SetFocus()
	EndIf

Return(_lRet)

//-------------------------------------------------------------------------------------------------

// ** funcao para gerar novo volume
Static Function sfNovoVolume()
	// variavel de retorno
	local _lRet := .T.

	// solicita confirmacao
	If (_lRet) .And. ( ! U_FtYesNoMsg("Confirma novo volume?") )
		_lRet := .F.
		Return(_lRet)
	EndIf

	// dados ok
	If (_lRet)
		// reinicia variaveis
		_cCodProd    := Space(Len(_cCodProd))
		_cEtiqProd   := Space(Len(_cEtiqProd))
		_nQtdProd    := 1
		_nQtdSegUM   := 0
		_cNewAgrup   := Space(_nTamEtqInt)
		_cOldAgrup   := Space(_nTamEtqInt)
		_lNovoVolume := .T.

		// atualiza objeto para pemitir novas leituras
		_oGetNewAgrupa:lReadOnly := (!_lCtrVolume) .And. (!_lNovoVolume)

		// atualiza os dados
		//sfSelDados()

		// foco de objetos
		_oGetNewAgrupa:SetFocus()
	EndIf

Return(_lRet)

//-------------------------------------------------------------------------------------------------
Static Function AtuBrws(nOpc)
	//nOPc = 1 atualiza tudo
	//nOpc = 2 atualiza parcialmente para não sobreescrever o estado dos objetos 'em vermelho'
	//nOpc = 3 Atualiza somente o browser inicial das OSs 

	If nOpc == 1
		//recarrega itens do pedido
		_aColsDet := GetPV()

		//recarrega itens já conferidos
		_aColsConf := GetConf()

		//recarrega volumes já montados
		_aColsVPd := GetVPed()

		//força coloração do browser para a padrão, bloco etiqueta
		oGrpEtiq:SetColor(CLR_BLACK,CLR_WHITE)
		_oSayAgrp1:SetColor(CLR_BLACK,CLR_WHITE)
		_oSayAgrp2:SetColor(CLR_BLACK,CLR_WHITE)

		//força coloração do browser para a padrão, bloco codigo de barras
		oGrpBar:SetColor(CLR_BLACK,CLR_WHITE)
		_oSayOld1:SetColor(CLR_BLACK,CLR_WHITE)
		_oSayOld2:SetColor(CLR_BLACK,CLR_WHITE)
		_oSayCPr1:SetColor(CLR_BLACK,CLR_WHITE)
		_oSayCPr2:SetColor(CLR_BLACK,CLR_WHITE)

		//Refresh nos elementos da tela
		oProd:Refresh()
		oBrwPV:Refresh()
		oBrwConf:Refresh()
		oBrwVPed:Refresh()
		oGrpEtiq:Refresh()
		oGrpBar:Refresh()

	ElseIf nOpc == 2

		//recarrega itens do pedido
		_aColsDet := GetPV()

		//recarrega itens já conferidos
		_aColsConf := GetConf()

		//recarrega volumes já montados
		_aColsVPd := GetVPed()

		//Refresh nos elementos da tela
		oProd:Refresh()
		oBrwPV:Refresh()
		oBrwConf:Refresh()
		oBrwVPed:Refresh()

	ElseIf nOpc == 3

		aGetOS := MontaOS()
		oBrwOS:SetArray(aGetOS)
		oBrwOS:Refresh()

	EndIf

Return
//-------------------------------------------------------------------------------------------------

// ** função que permite encerrar a sequencia de montagem de volumes, caso todos os pedidos estejam aptos
Static Function sfFimOS(mvCodCli, mvLojCli, mvCarga, mvOndSep)

	local _nQtd   := 0
	local _cQuery := ""
	local _lRet   := .F.
	local _cTpAgr := IIf(Empty(mvCarga), "Onda de Separação", "Carga")

	// envia e-mail para o cliente avisando que a montagem foi finalizada
	local _lEmailFim := U_FtWmsParam("WMS_EXPEDICAO_EMAIL_FIM_MONTAGEM_VOLUMES", "L", .F., .F. , "", _cCodCliFor, _cLojCliFor, Nil, Nil)


	//pede confirmação
	If ( ! U_FtYesNoMsg("Deseja encerrar a etapa de montagem de volumes da " + _cTpAgr + " " + IIf(Empty(mvCarga), mvOndSep, mvCarga) + " ?"))
		Return( .F. )
	EndIf

	// finaliza OS somente quando todos os pedidos estiverem com os volumes montados
	_cQuery := " SELECT COUNT(*) QTD_PEND "
	// pedidos de venda
	_cQuery += " FROM " + RetSqlTab("SC5") + " (nolock) "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("SC5")
	// cliente, loja e tipo de operacao
	_cQuery += " AND C5_CLIENTE = '" + mvCodCli + "' AND C5_LOJACLI = '" + mvLojCli + "' AND C5_TIPOOPE = 'P' "
	// numero da carga/agrupadora
	If ( ! Empty(mvCarga) )
		_cQuery += " AND C5_ZCARGA = '" + mvCarga + "' "
	EndIf
	// filtro por onda de separacao
	If ( ! Empty(mvOndSep) )
		_cQuery += " AND C5_ZONDSEP = '" + mvOndSep + "' "
	EndIf
	// status da montagem de volume
	_cQuery += " AND C5_ZMNTVOL <> 'S' "

	//memowrit("C:\query\twmsa024_sfFinaliza.txt",_cQuery)

	// joga os dados pro array
	_nQtd := U_FtQuery(_cQuery)

	//se este é o unico pedido pendente, então permite finalizar pois todos os OUTROS pedidos foram montados
	If (_nQtd == 0)
		// atualiza o status do servico para FI-FINALIZADO
		U_FtWmsSta(;
		Z06->Z06_STATUS,;
		"FI"           ,;
		Z06->Z06_NUMOS ,;
		Z06->Z06_SEQOS  )

		//sai do loop principal
		_lContConf := .F.

		//retorna sucesso
		_lRet := .T.

		// envia mensagem de e-mail
		If (_lEmailFim)
			//sfMailRes()
		EndIf

	Else
		U_FtWmsMsg("Erro: ainda existem " + AllTrim(Str(_nQtd)) + " pedidos pendentes/não montados para esta " + _cTpAgr + ". Verifique!", "TWSMA024 - sfFimOS")
	EndIf

Return (_lRet)

//-------------------------------------------------------------------------------------------------

// ** funcao para realizar a finalizacao/encerramento total do servico de conferencia da OS
Static Function sfFinalizaOS(mvTela, mvOk)

	// objetos locais
	local _oWndConFinal
	local _oPnlCfeFinCab1, _oPnlCfeFinCab2
	local _oBmpCfeFinConf, _oBmpCfeFechar
	local _oSayStatus, _oSayTotPB, _oSayTotCB, _oSayTotVL, _oSayNrPed
	local _oBrwFinaliza

	// variaveis temporarias
	Local _cQryConf  := ""
	Local _cQryPed   := ""
	Local cNewAlias  := GetNextAlias()
	Local nX         := 0
	Local _aConf     := {}

	// area atual
	Local aAreaAtu := GetArea()

	// estrutura do arquivo de trabalho e Browse
	Local aEstBrowse := {}
	Local aHeadBrowse := {}
	Local cMarca  := Z07->(GetMark())

	// controle de divergencias
	Local _lDiverg := .F.

	// informacoes do resumo
	local _nTotPesoB  := 0
	local _nTotCubag  := 0
	local _nTotVolume := 0
	local _nTotPalete := 0

	// controle de confirmacao da tela
	local _lOk := .T.

	// cores do browse
	local _aCorBrowse := {}

	private cArqTmp
	private _TRBPED := GetNextAlias()

	lExit := .T.

	// confirmacao do processamento
	If ( ! U_FtYesNoMsg("Finalizar Montagem do pedido " + _cPedido + " ?" ))
		lExit := .F.
		Return( .F. )
	EndIf

	// define cores do browse
	aAdd(_aCorBrowse, {"  Empty((_TRBPED)->IT_COR)","DISABLE"})
	aAdd(_aCorBrowse, {"! Empty((_TRBPED)->IT_COR)","ENABLE" })


	//---INICIO VALIDAÇÕES INICIAS ---

	// verifica se a OS está em um estado válido para finalização
	_cQryConf := "SELECT Z06_STATUS "
	_cQryConf += " FROM " + RetSqlTab("Z06") + " (nolock) "
	_cQryConf += " WHERE " + RetSqlCond("Z06")
	_cQryConf += "       AND Z06_NUMOS  = '" + _cNumOrdSrv + "'  "
	_cQryConf += "       AND Z06_SEQOS  = '" + _cSeqOrdSrv + "'  "

	If (U_FtQuery(_cQryConf) != 'EX')
		U_FtWmsMsg("O status da ordem de serviço " + Z06->Z06_NUMOS + " é inválido (" + Z06->Z06_STATUS + "). Verifique com o supervisor. A tela será fechada.","Erro")

		//se OS com status inválido, não deve selecionar outro pedido na window de pedido, então seta a variavel de controle
		//para fechar a tela no laço principal (1ª tela de seleção de pedidos)
		_lContConf := .F.

		//tela anterior de conferência  (2ª tela - conferência/montagem, já com pedido selecionado)
		//variável retorna TRUE pois é o que mantem a tela aberta
		mvOk := .T.

		//fecha a tela
		//mvTela:End()

		Return( .F. )
	EndIf

	// verifica se tem mais usuarios na mesma contagem em conferencia
	_cQryConf := " SELECT COUNT(*) QTD_ITENS FROM " + RetSqlTab("Z07") + " (nolock) "
	// itens conferidos
	_cQryConf += " WHERE "+RetSqlCond("Z07")
	// numero da OS
	_cQryConf += " AND Z07_NUMOS   = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '" + _cSeqOrdSrv + "' "
	// nr contagem
	_cQryConf += " AND Z07_NRCONT  = '"+_cNrContagem+"' "
	// somente disponiveis
	_cQryConf += " AND Z07_STATUS = 'C' "
	// somente do pedido selecionado anteriormente
	_cQryConf += " AND Z07_PEDIDO = '"+_cPedido+"' "

	// executa a query de verificacao
	If (U_FtQuery(_cQryConf) > 0)
		// mensagem
		U_FtWmsMsg("Existem Operadores com conferência/montagem em aberto. Favor verificar antes de prosseguir.", "Finalizar")
		// retorno
		Return(.F.)
	EndIf

	// verifica se ha algum palete nao finalizado
	_cQryConf := " SELECT COUNT(*) QTD_ITENS FROM "+RetSqlTab("Z07")+" (nolock) "
	_cQryConf += " WHERE "+RetSqlCond("Z07")
	_cQryConf += " AND Z07_NUMOS   = '" + _cNumOrdSrv + "' AND Z07_SEQOS = '" + _cSeqOrdSrv + "' "
	_cQryConf += " AND Z07_NRCONT  = '" + _cNrContagem + "' "
	_cQryConf += " AND Z07_STATUS  = 'C' "                 // somente disponiveis
	_cQryConf += " AND Z07_PEDIDO = '" + _cPedido + "' "   // somente do pedido selecionado anteriormente

	If (U_FtQuery(_cQryConf) > 0)
		U_FtWmsMsg("Há paletes com conferência não finalizada!", "Finalizar")
		Return( .F. )
	EndIf

	// verifica se houve alguma conferência para o pedido/os
	_cQryConf := "SELECT COUNT(Z07_ETQVOL) "
	_cQryConf += " FROM " + RetSqlTab("Z07") + " (nolock) "
	_cQryConf += " WHERE " + RetSqlCond("Z07")
	_cQryConf += "       AND Z07_NUMOS  = '" + _cNumOrdSrv + "'  "
	_cQryConf += "       AND Z07_SEQOS  = '" + _cSeqOrdSrv + "'  "
	_cQryConf += "       AND Z07_PEDIDO = '" + _cPedido +    "'  "
	_cQryConf += "	     AND Z07_STATUS = 'D'         "

	If (U_FtQuery(_cQryConf) == 0)
		U_FtWmsMsg("Nenhum palete montado/conferido para o pedido " + _cPedido + ".","ATENCAO")
		Return( .F. )
	EndIf


	//---FIM VALIDAÇÕES INICIAS ---

	// fecha o alias
	If ( Select(cNewAlias) != 0 )
		dbSelectArea(cNewAlias)
		dbCloseArea()
	EndIf

	//pega as informações do pedido de venda
	_cQryPed := "SELECT 'DI'          IT_OK,      "
	_cQryPed += "       '  '          IT_COR,     "
	_cQryPed += "  LTRIM(RTRIM(C6_NUM)) C6_NUM, "
	_cQryPed += "  LTRIM(RTRIM(C6_PRODUTO)) C6_PRODUTO, "
	_cQryPed += "  LTRIM(RTRIM(SB1.B1_DESC)) B1_DESC, "
	_cQryPed += "	    SB1.B1_UM,                "
	_cQryPed += "       Sum(C6_QTDVEN) QTD,       "
	_cQryPed += "       C6_LOTECTL,               "
	_cQryPed += "       0 QTD_PALETE,             "
	_cQryPed += "	    0 QTD_VOLUME,             "
	_cQryPed += "	    0 Z07_CONF                "
	_cQryPed += " FROM " + RetSqlTab("SC6") + " (nolock) "
	_cQryPed += " LEFT JOIN " + RetSqlTab("SB1") + " (nolock) "
	_cQryPed += "     ON SB1.B1_COD = SC6.C6_PRODUTO
	_cQryPed += "        AND " + RetSqlCond("SB1")
	_cQryPed += " WHERE " + RetSqlCond("SC6")
	_cQryPed += "     AND C6_NUM = '" + _cPedido + "'  "
	_cQryPed += " GROUP  BY C6_PRODUTO,           "
	_cQryPed += "           C6_LOTECTL,           "
	_cQryPed += "           C6_NUM,               "
	_cQryPed += "           B1_DESC,              "
	_cQryPed += "           B1_UM                 "

	memowrit("c:\QUERY\twmsa024_sfFinalizaOS_Pedido.txt",_cQryPed)

	cNewAlias := GetNextAlias()
	dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQryPed),cNewAlias,.F.,.T.)

	// pega a estrutura do select dos pedidos para compor a TRB
	aEstBrowse := (cNewAlias)->(dbStruct())

	// fecha o trb
	If ( Select(_TRBPED) <> 0 )
		dbSelectArea(_TRBPED)
		dbCloseArea()
	EndIf

	// criar um arquivo de trabalho
	cArqTmp := FWTemporaryTable():New( _TRBPED )
	cArqTmp:SetFields( aEstBrowse )
	cArqTmp:AddIndex("01", {"C6_PRODUTO", "C6_LOTECTL"} )
	cArqTmp:Create()

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQryPed, aEstBrowse, _TRBPED)

	// fecha a query
	dbSelectArea(cNewAlias)
	dbCloseArea()

	//consulta tudo que foi conferido para esta OS e pedido
	_cQryConf := "SELECT Z07_NUMOS,                                                "
	_cQryConf += "       Z07_SEQOS,                                                "
	_cQryConf += "       Z07_PRODUT,                                               "
	_cQryConf += "       Z07_LOTCTL,                                               "
	_cQryConf += "       Sum(Z07_QUANT)                           AS Z07_QUANT,    "
	_cQryConf += "       (SELECT Isnull(Count(DISTINCT Z07_ETQVOL), 0)             "
	_cQryConf += "        FROM   " + RetSqlTab("Z07") + " (nolock) "
	_cQryConf += "        WHERE  " + RetSqlCond("Z07")
	_cQryConf += "               AND Z07_NUMOS = CONF.Z07_NUMOS                    "
	_cQryConf += "               AND Z07_SEQOS = CONF.Z07_SEQOS                    "
	_cQryConf += "               AND Z07_PEDIDO = CONF.Z07_PEDIDO) AS 'QTD_VOLUME',"
	_cQryConf += "       (SELECT Isnull(Count(DISTINCT Z07_PALLET), 0)             "
	_cQryConf += "        FROM   " + RetSqlTab("Z07") + " (nolock) "
	_cQryConf += "        WHERE  " + RetSqlCond("Z07")
	_cQryConf += "               AND Z07_NUMOS = CONF.Z07_NUMOS                    "
	_cQryConf += "               AND Z07_SEQOS = CONF.Z07_SEQOS                    "
	_cQryConf += "               AND Z07_PEDIDO = CONF.Z07_PEDIDO) AS 'QTD_PALETE' "
	_cQryConf += "FROM  " + RetSqlName("Z07") + " CONF (nolock)  "
	_cQryConf += "WHERE  CONF.D_E_L_E_T_ = ''                                      "
	_cQryConf += "       AND CONF.Z07_FILIAL = '" + xFilial("Z07") + " '           "
	_cQryConf += "       AND CONF.Z07_NUMOS = '" + _cNumOrdSrv + "'                "
	_cQryConf += "       AND CONF.Z07_SEQOS = '" + _cSeqOrdSrv + "'                "
	_cQryConf += "       AND CONF.Z07_PEDIDO = '" + _cPedido + "'                  "
	_cQryConf += "       AND CONF.Z07_STATUS = 'D'                                 "
	_cQryConf += "GROUP  BY Z07_NUMOS,                                             "
	_cQryConf += "          Z07_SEQOS,                                             "
	_cQryConf += "          Z07_PRODUT,                                            "
	_cQryConf += "          Z07_LOTCTL,                                            "
	_cQryConf += "          Z07_PEDIDO                                             "

	memowrit("c:\QUERY\twmsa024_sfFinalizaOS_Conf.txt",_cQryConf)

	//joga a consulta de tudo que foi conferido em array
	_aConf := U_SqlToVet(_cQryConf)

	/*
	Composição do array _aConf

	[1] - Z07_NUMOS
	[2] - Z07_SEQ0S
	[3] - Z07_PRODUT
	[4] - Z07_LOTCTL
	[5] - Z07_QUANT (SOMADO)
	[6] - QTD_VOLUME
	[7] - QTD_PALETE

	*/

	(_TRBPED)->(dbSelectArea(_TRBPED))
	(_TRBPED)->(dbGoTop())

	//percorre o array comparando o que foi conferido com o previsto no pedido de venda
	For nX := 1 To Len(_aConf)
		If ( (_TRBPED)->( DbSeek(_aConf[nX][3] + _aConf[nX][4])) )   		//se achou produto e lote
			// atualiza o TRB com os dados do produto encontrado
			(_TRBPED)->(RecLock(_TRBPED, .F. ))

			(_TRBPED)->Z07_CONF    := _aConf[nx][5]
			(_TRBPED)->QTD_VOLUME  := _aConf[nx][6]
			(_TRBPED)->QTD_PALETE  := _aConf[nx][7]

			(_TRBPED)->IT_OK  := IIf( ((_TRBPED)->Z07_CONF != (_TRBPED)->QTD), cMarca, Space(2) )
			(_TRBPED)->IT_COR := IIf( ((_TRBPED)->Z07_CONF != (_TRBPED)->QTD), Space(2), cMarca )

			(_TRBPED)->(MsUnLock())
		Else 		//produto ou lote não esperado, vou inserir no TRB para mostrar
			(_TRBPED)->(RecLock(_TRBPED, .T. ))

			//preenche TRB com uma nova linha do produto não esperado
			(_TRBPED)->IT_OK       := cMarca
			(_TRBPED)->IT_COR      := Space(2)         //em branco, bola vermelha "disable" na legenda
			(_TRBPED)->C6_NUM      := "ERRADO"
			(_TRBPED)->C6_PRODUTO  := _aConf[nx][3]
			(_TRBPED)->B1_DESC     := AllTrim( Posicione( "SB1", 1, xFilial("SB1") + _aConf[nx][3], "B1_DESC" ) )
			(_TRBPED)->QTD         := 0                //qtd no pedido de venda. No caso, o produto não é esperado, então é 0
			(_TRBPED)->C6_LOTECTL  := _aConf[nx][4]
			(_TRBPED)->QTD_PALETE  := _aConf[nx][7]
			(_TRBPED)->QTD_VOLUME  := _aConf[nx][6]
			(_TRBPED)->Z07_CONF    := _aConf[nx][5]

			_lDiverg := .T.       //produto não esperado para o pedido, sempre marca a finalização como divergente

			(_TRBPED)->(MsUnLock())
		EndIf

		// atualiza variaveis do resumo
		_nTotVolume := IIf(_lCtrVolume, (_TRBPED)->QTD_VOLUME, _nTotVolume += (_TRBPED)->Z07_QUANT)
		_nTotPalete += (_TRBPED)->QTD_PALETE

	Next nX

	//verifica divergências
	(_TRBPED)->(dbGoTop())
	(_TRBPED)->(DbEval ({|| IIf( (!Empty((_TRBPED)->IT_OK) ), _lDiverg := .T. , Nil )  }))

	//volta para o primeiro para exibir a grid corretamente
	(_TRBPED)->(dbGoTop())

	// atualiza variaveis do resumo
	_nTotCubag := sfRetCubEmb()

	// inclui detalhes e titulos dos campos do browse
	aAdd(aHeadBrowse,{"IT_OK"       ,, "  "          , "@!"        })
	aAdd(aHeadBrowse,{"C6_PRODUTO"  ,, "Cód. Produto", "@!"        })
	aAdd(aHeadBrowse,{"B1_DESC"     ,, "Descrição"   , "@!"        })
	aAdd(aHeadBrowse,{"B1_UM"       ,, "Und.Med."    , "@!"        })
	aAdd(aHeadBrowse,{"QTD"         ,, "Qtd.PV"      , _cMaskQuant })
	aAdd(aHeadBrowse,{"Z07_CONF"    ,, "Qtd.Conf."   , _cMaskQuant })
	aAdd(aHeadBrowse,{"QTD_VOLUME"  ,, "Qtd.Volume"  , _cMaskQuant })
	aAdd(aHeadBrowse,{"QTD_PALETE"  ,, "Qtd.Palete"  , _cMaskQuant })

	// monta a tela com os detalhes da finalizacao total da OS
	_oWndConFinal := MSDialog():New(000,000,450,550,"Mont.Vol/Pedido: "+_cPedido,,,.F.,,,,,,.T.,,,.T. )
	_oWndConFinal:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlCfeFinCab1 := TPanel():New(000,000,nil,_oWndConFinal,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlCfeFinCab1:Align:= CONTROL_ALIGN_TOP

	If ( ! _lDiverg)
		_oBmpCfeFinConf := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| MsgRun("Aguarde. Selecionando Dados...",,{|| _lOk := sfFinServico(@_oWndConFinal, _nTotVolume) }) },_oPnlCfeFinCab,"Finaliza a Conferência",,.T. )
		_oBmpCfeFinConf:Align := CONTROL_ALIGN_LEFT
	EndIf
	// -- BOTAO PARA FECHAR A TELA
	_oBmpCfeFechar := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| lExit := .F.,_lOk := .F., _oWndConFinal:End() },_oPnlCfeFinCab,"Sair",,.T. )
	_oBmpCfeFechar:Align := CONTROL_ALIGN_RIGHT

	// resumo da operacao
	_oPnlCfeFinCab2 := TPanel():New(000,000,nil,_oWndConFinal,,.F.,.F.,,,048,048,.T.,.F.)
	_oPnlCfeFinCab2:Align:= CONTROL_ALIGN_TOP

	// status conferencia
	_oSayStatus := TSay():New(003,004,{||"STATUS: " + IIf(_lDiverg, "DIVERGÊNCIAS", "OK") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T., IIf(_lDiverg, CLR_HRED, CLR_GREEN) )
	// total PESO BRUTO
	_oSayTotPB  := TSay():New(010,004,{||"PESO BRUTO: "+Transf(_nTotPesoB,"@E 999,999.999") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)
	// total CUBAGEM
	_oSayTotCB  := TSay():New(017,004,{||"CUBAGEM: "+Transf(_nTotCubag,"@E 999,999.999") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)
	// total VOLUMES
	_oSayTotVL  := TSay():New(024,004,{||"VOLUMES: "+Transf(_nTotVolume,"@E 999,999,999") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)
	// Nr Pedido
	_oSayNrPed  := TSay():New(038,004,{||"PEDIDO: "+_cPedido+"/"+_cPedCliente },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)

	// browse com a listagem dos produtos conferidos
	_oBrwFinaliza := MsSelect():New( _TRBPED,"IT_OK",,aHeadBrowse,,cMarca,{15,1,183,373},,,,,_aCorBrowse)
	_oBrwFinaliza:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oWndConFinal

	// atualiza variaveis da tela de conferencia
	If (_lOk)
		//para fechar a tela no laço principal (1ª tela de seleção de pedidos)
		_lContConf := .F.

		//fecha telas abertas e volta para menu principal do coletor
		mvOk := .T.
		//mvTela:End()
	EndIf

	// fecha arquivo de trabalho
	cArqTmp:Delete()

	// restaura area inicial
	RestArea(aAreaAtu)

Return(_lOk)

//-------------------------------------------------------------------------------------------------

// ** funcao que calcula a cubagem por embalagem
Static Function sfRetCubEmb()
	// variavel de retorno
	local _nRet := 0
	// query
	local _cQuery
	// dados temporarios
	local _aDadosCub := {}

	// monta a query para buscar os volumes por pedido
	_cQuery := "SELECT Z07_ETQVOL, Z31_CUBAGE "

	// itens conferidos/volumes montados
	_cQuery += "FROM "+RetSqlName("Z07")+" Z07 (nolock)  "

	// cad. clientes
	_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 (nolock)  ON "+RetSqlCond("SA1")+" AND A1_COD = Z07_CLIENT AND A1_LOJA = Z07_LOJA "

	// cad. embalagens
	_cQuery += " INNER JOIN "+RetSqlName("Z31")+" Z31 (nolock)  ON "+RetSqlCond("Z31")+" AND Z31_CODIGO = Z07_EMBALA AND Z31_SIGLA = A1_SIGLA "

	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z07")+" "
	// numero e seq da OS
	_cQuery += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	// cliente e loja
	_cQuery += "AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
	// nr do pedido
	_cQuery += "AND Z07_PEDIDO = '"+_cPedido+"' "

	// agrupa dados
	_cQuery += " GROUP BY Z07_ETQVOL, Z31_CUBAGE "

	memowrit("c:\query\twmsa024_sfRetCubEmb.txt", _cQuery)

	// atualiza vetor
	_aDadosCub := U_SqlToVet(_cQuery)

	// calcula a quantidade total de palete
	aEval(_aDadosCub,{|x| _nRet += x[2] })

Return(_nRet)

//-------------------------------------------------------------------------------------------------

// ** funcao que encerra o servico de montagem de volumes
Static Function sfFinServico(mvWndConFinal, mvTotVolume)
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z05","Z06","SC5"})

	// variavel de retorno
	local _lRet := .T.

	// finaliza OS somente quando todos os pedidos estiverem com os volumes montados
	local _lFinalOS := .F.

	// query
	local _cQuery
	local _cUpdZ07

	// etiquetas de volume
	local _aEtqVolume := {}
	local _nEtqVolume

	// imprime etiqueta de packing logo apos finalizar a montagem de volumes
	local _lImpEtqPacking := U_FtWmsParam("WMS_EXPEDICAO_ETIQUETA_PACKING_IMPRESSAO_COLETOR", "L", .F., .F. , "", _cCodCliFor, _cLojCliFor, Nil, Nil)

	// envia e-mail para o cliente avisando que a montagem foi finalizada
	local _lEmailFim := U_FtWmsParam("WMS_EXPEDICAO_EMAIL_FIM_MONTAGEM_VOLUMES", "L", .F., .F. , "", _cCodCliFor, _cLojCliFor, Nil, Nil)

	// inicia transacao
	BEGIN TRANSACTION

		// finaliza os itens conferidos
		_cUpdZ07 := "UPDATE "+RetSqlName("Z07")+" "
		// status F=Finalizado
		_cUpdZ07 += "SET Z07_STATUS = 'F' "
		// filtro padrao
		_cUpdZ07 += "WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
		// filtro da OS especifica
		_cUpdZ07 += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		// status D=Em Conferência
		_cUpdZ07 += "AND Z07_STATUS = 'D' "
		// somente do pedido selecionado anteriormente
		_cUpdZ07 += "AND Z07_PEDIDO = '"+_cPedido+"' "

		// executa o update
		TcSQLExec(_cUpdZ07)

		// posiciona no pedido
		dbSelectArea("SC5")
		SC5->(dbSetOrder(1)) // 1-C5_FILIAL, C5_NUM
		SC5->(dbSeek( xFilial("SC5")+_cPedido ))

		// atualiza status de conferencia/montagem de volumes
		RecLock("SC5")
		SC5->C5_ZMNTVOL := "S"
		SC5->C5_VOLUME1 := mvTotVolume
		SC5->(MsUnLock())

		// liberacao do pedido de venda
		sfLibPedVen(.F., SC5->C5_NUM, _cDocaSrv, _cArmzServ)

		// atualiza informacoes Volume De->Ate no cadastro de Etiquetadas (usado para impressao)
		_cQuery := "SELECT DISTINCT Z07_ETQVOL "
		// tabela de itens conferidos
		_cQuery += "FROM "+RetSqlName('Z07')+" Z07 (nolock)  "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("Z07")+" "
		// numero e seq da OS
		_cQuery += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		// cliente e loja
		_cQuery += "AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
		// nr do pedido
		_cQuery += "AND Z07_PEDIDO = '"+_cPedido+"' "
		// somente que nao F-Finalizado
		_cQuery += "AND Z07_STATUS = 'F' "
		// ordem dos dados
		_cQuery += "ORDER BY Z07_ETQVOL "

		// atualiza vetor com o codigo das etiquetas
		_aEtqVolume := U_SqlToVet(_cQuery)

		// varre todas as etiquetas para atualizar os dados
		For _nEtqVolume := 1 to Len(_aEtqVolume)

			// pesquisa etiqueta no cadastro
			dbSelectARea("Z11")
			Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
			If Z11->(dbSeek( xFilial("Z11")+_aEtqVolume[_nEtqVolume] ))
				RecLock("Z11")
				Z11->Z11_QTD1 := _nEtqVolume
				Z11->Z11_QTD2 := Len(_aEtqVolume)
				Z11->(MsUnLock())
			EndIf

		Next _nEtqVolume

		// finaliza OS somente quando todos os pedidos estiverem com os volumes montados
		_cQuery := " SELECT COUNT(*) QTD_PEND "
		// pedidos de venda
		_cQuery += " FROM " + RetSqlTab("SC5") + " (nolock) "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("SC5")
		// cliente, loja e tipo de operacao
		_cQuery += " AND C5_CLIENTE = '" + _cCodCliFor + "' AND C5_LOJACLI = '" + _cLojCliFor + "' AND C5_TIPOOPE = 'P' "
		// numero da carga/agrupadora
		If ( ! Empty(_cNrCarga) )
			_cQuery += " AND C5_ZCARGA = '" + _cNrCarga + "' "
		EndIf
		// filtro por onda de separacao
		If ( ! Empty(_cNrOndSep) )
			_cQuery += " AND C5_ZONDSEP = '" + _cNrOndSep + "' "
		EndIf
		// status da montagem de volume
		_cQuery += " AND C5_ZMNTVOL <> 'S' "

		MEMOWRIT("c:\query\twmsa024_sfFinServico_ped_pend.txt",_cQuery)

		// executa a query
		_lFinalOS := (U_FtQuery(_cQuery) == 0)

		// se tudo ok
		If (_lFinalOS)

			// atualiza o status do servico para FI-FINALIZADO
			U_FtWmsSta(_cCodStatus,;
			"FI"        ,;
			_cNumOrdSrv ,;
			_cSeqOrdSrv  )

			// envia mensagem de e-mail
			If ( _lEmailFim )
				//sfMailRes()
			EndiF

		EndIf

		// finaliza transacao
	END TRANSACTION

	// imprimir etiquetas de packing
	If (_lImpEtqPacking) .And. (U_FtYesNoMsg("Confirmar impressão de etiqueta de packing?"))
		// funcao para impressao de etiquetas de packing
		U_WMSR016A( Nil, "  ", "ZZZ", _cPedido, _cNrCarga, "  ", "  ", "  ", _cCodCliFor, _cNrOndSep)
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aArea)

	// fecha tela do resumo
	If (_lRet)
		mvWndConFinal:End()
	EndIf

Return(_lRet)

//-------------------------------------------------------------------------------------------------

// ** funcao para liberacao e analise de estorno do pedido de venda
Static Function sfLibPedVen(mvEstorno, mvPedido, mvEndDest, mvArmDest)

	// variavel de retorno
	local _lRet := .T.

	// query dos itens do pedido
	local _cQrySC6
	local _aRecnoLib := {}
	local _nRecnoLib := 0

	// pedidos liberados
	local _aPedLiber := {}

	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaSC5 := SC5->(GetArea())
	local _aAreaSC6 := SC6->(GetArea())
	local _aAreaSC9 := SC9->(GetArea())

	// monta a query para buscar os itens dos pedidos de venda da carga
	_cQrySC6 := "SELECT SC6.R_E_C_N_O_ SC6RECNO, SC9.R_E_C_N_O_ SC9RECNO "
	// itens liberados
	_cQrySC6 += "FROM "+RetSqlName("SC9")+" SC9 (nolock)  "
	// itens liberados
	_cQrySC6 += "INNER JOIN "+RetSqlName("SC6")+" SC6 (nolock)  ON "+RetSqlCond("SC6")+" AND C6_NUM = C9_PEDIDO AND C6_ITEM = C9_ITEM AND C6_PRODUTO = C9_PRODUTO "
	// filtro padrao
	_cQrySC6 += "WHERE "+RetSqlCond("SC9")+" "
	// nr do pedido
	_cQrySC6 += "AND C9_PEDIDO = '"+mvPedido+"' "
	// sem nota fiscal emitida E sem bloqueio de WMS
	_cQrySC6 += "AND C9_NFISCAL = ' ' AND C9_BLEST IN ('  ','02') AND C9_BLWMS = ' ' "
	// ordem dos dados
	_cQrySC6 += "ORDER BY C6_NUM, C6_ITEM "

	memowrit("c:\query\twmsa022_sfLibPedVen.txt",_cQrySC6)

	// alimenta o vetor com os RECNOs dos itens do pedido
	_aRecnoLib := U_SqlToVet(_cQrySC6)

	// varre todo os itens dos pedidos de venda
	For _nRecnoLib := 1 to len(_aRecnoLib)

		// posiciona no registro do item liberado
		dbSelectArea("SC9")
		SC9->(dbGoTo( _aRecnoLib[_nRecnoLib][2] ))

		// posiciona no registro do item
		dbSelectArea("SC6")
		SC6->(dbGoTo( _aRecnoLib[_nRecnoLib][1] ))

		// posiciona no cabecalho do pedido
		dbSelectArea("SC5")
		SC5->(dbSetOrder( 1 )) // 1-C5_FILIAL, C5_NUM
		SC5->(dbSeek( xFilial("SC5")+SC6->C6_NUM ))

		// pedidos liberados
		If ( aScan(_aPedLiber,{|x| x == SC5->C5_NUM }) == 0 )
			aAdd(_aPedLiber,SC5->C5_NUM)
		EndIf

		// atualiza a doca de retirada
		RecLock("SC6")
		SC6->C6_LOCALIZ := IIf(mvEstorno, SC6->C6_NUM  , mvEndDest)
		SC6->C6_LOCAL   := IIf(mvEstorno, SC6->C6_LOCAL, mvArmDest)
		SC6->(MsUnLock())

		// realiza o estorno da mercadoria empenhada no pedido de venda / necessario para realizar nova liberacao
		a460estorna()

		// liberacao do item do pedido de venda
		MaLibDoFat( SC6->(RecNo()) ,; // recno do SC6
		SC6->C6_QTDVEN             ,; // quantidade liberada da 1a UM
		Nil                        ,; // retorno de bloqueio de credito
		Nil                        ,; // retorno de bloqueio de estoque
		.T.                        ,; // reavalia credito?
		.T.                        ,; // reavalia estoque?
		.F.                        ,; // permite liberacao parcial de pedidos?
		.F.                         ) // transferencia de enderecos automaticamente?

	Next _nRecnoLib

	// atualiza o status do pedido de venda
	SC6->(MaLiberOk(_aPedLiber))

	// restaura area atual
	RestArea(_aAreaSC9)
	RestArea(_aAreaSC6)
	RestArea(_aAreaSC5)
	RestArea(_aAreaAtu)

Return(_lRet)

//-------------------------------------------------------------------------------------------------

// ** funcao que envia email com o resumo da ordem de servico
Static Function sfMailRes()

	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"Z05", "Z06", "SC5", "SA1"})

	// query
	local _cQuery

	// dados do pedido
	local _aTmpDados := {}
	local _nItPed

	// html da mensagem de email
	local _cHtml := ""

	// destinatarios
	local _cDestin := ""

	// prepara query
	_cQuery := " SELECT Z07_PEDIDO, "
	_cQuery += "        C5_ZPEDCLI, "
	_cQuery += "        C5_ZDOCCLI, "
	_cQuery += "        Sum(Z07_QUANT)             QTD_TOTAL, "
	_cQuery += "        Count(DISTINCT Z07_PRODUT) QTD_SKU, "
	_cQuery += "        Count(DISTINCT Z07_ETQVOL) QTD_VOL "
	_cQuery += " FROM   " + RetSqlTab("Z05") + " (nolock) "
	_cQuery += "        INNER JOIN " + RetSqlTab("Z06") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("Z06")
	_cQuery += "                   AND Z06_NUMOS = Z05_NUMOS "
	_cQuery += "                   AND Z06_SEQOS = '" + Z06->Z06_SEQOS + "' "
	_cQuery += "                   AND Z06_SERVIC = '001' "
	_cQuery += "                   AND Z06_TAREFA = '007' "
	_cQuery += "                   AND Z06_STATUS = 'FI' "
	_cQuery += "        INNER JOIN " + RetSqlTab("Z07") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("Z07")
	_cQuery += "                   AND Z07_NUMOS = Z06_NUMOS "
	_cQuery += "                   AND Z07_SEQOS = Z06_SEQOS "
	_cQuery += "        INNER JOIN " + RetSqlTab("SC5") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("SC5")
	_cQuery += "                   AND C5_NUM = Z07_PEDIDO "
	_cQuery += " WHERE  " + RetSqlCond("Z05")
	_cQuery += "        AND Z05_NUMOS = '" + Z06->Z06_NUMOS + "' "
	_cQuery += " GROUP  BY Z07_PEDIDO, "
	_cQuery += "           C5_ZPEDCLI, "
	_cQuery += "           C5_ZDOCCLI "

	// atualiza variavel com dados do pedido
	// estrutura do _aTmpDados
	// 1 - Z07_PEDIDO
	// 2 - C5_ZPEDCLI
	// 3 - C5_ZDOCCLI
	// 4 - Sum(Z07_QUANT)             QTD_TOTAL
	// 5 - Count(DISTINCT Z07_PRODUT) QTD_SKU
	// 6 - Count(DISTINCT Z07_ETQVOL) QTD_VOL
	_aTmpDados := U_SqlToVet(_cQuery)

	// posiciona no cadastro do cliente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
	SA1->(dbSeek( xFilial("SA1") + Z05->Z05_CLIENT + Z05->Z05_LOJA ))

	// inicio da mensagem de email
	_cHtml += '<table width="780px" align="center">'
	_cHtml += '   <tr>'
	_cHtml += '      <td>'
	_cHtml += '         <table style="border-collapse: collapse;font-family: Tahoma; font-size: 12px;" border="1" width="100%" cellpadding="2" cellspacing="0" align="center" >'
	_cHtml += '            <tr>'
	_cHtml += '               <td height="30" colspan="2" style="background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Status de Separação e Preparação de Pedidos</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Filial</td>'
	_cHtml += '               <td width="80%" >' + AllTrim(SM0->M0_CODFIL) + "-" + AllTrim(SM0->M0_FILIAL) + '</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Data/Hora</td>'
	_cHtml += '               <td width="80%" >' + DtoC(Z06->Z06_DTFIM) + ' as ' + Z06->Z06_HRFIM + ' h</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Depositante</td>'
	_cHtml += '               <td width="80%" >' + SA1->A1_COD + ' / ' + SA1->A1_LOJA + ' - ' + AllTrim(SA1->A1_NOME) + '</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Ordem de Serviço</td>'
	_cHtml += '               <td width="80%" >' + Z06->Z06_NUMOS + ' / ' + Z06->Z06_SEQOS + '</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Status</td>'
	_cHtml += '               <td width="80%" ><span style="background-color: #80d22d">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>&nbsp;Pedido separado. Aguardando NF de Venda para carregamento.</td>'
	_cHtml += '            </tr>'
	_cHtml += '         </table>'
	_cHtml += '         <br>'
	_cHtml += '         <table style="border-collapse: collapse;font-family: Tahoma; font-size: 12px;" border="1" width="100%" cellpadding="2" cellspacing="0" align="center" >'
	_cHtml += '            <tr>'
	_cHtml += '               <td height="20" colspan="4" style="background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Composição do Mapa de Separação</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr style="background-color: #87CEEB;">'
	_cHtml += '               <td width="30%" >Pedido do Cliente</td>'
	_cHtml += '               <td width="30%" >Nota Fiscal de Venda</td>'
	_cHtml += '               <td width="20%" >Quantidade de Volumes</td>'
	_cHtml += '               <td width="20%" >Quantidade de SKU</td>'
	_cHtml += '            </tr>'

	// varre todos os itens dos detalhes
	For _nItPed := 1 to Len(_aTmpDados)

		// estrutura do _aTmpDados
		// 1 - Z07_PEDIDO
		// 2 - C5_ZPEDCLI
		// 3 - C5_ZDOCCLI
		// 4 - Sum(Z07_QUANT)             QTD_TOTAL
		// 5 - Count(DISTINCT Z07_PRODUT) QTD_SKU
		// 6 - Count(DISTINCT Z07_ETQVOL) QTD_VOL

		// insere linha na mensagem
		_cHtml += '            <tr>'
		_cHtml += '               <td width="30%" >' + AllTrim(_aTmpDados[_nItPed][2]) + '</td>'
		_cHtml += '               <td width="30%" >' + AllTrim(_aTmpDados[_nItPed][3]) + '</td>'
		_cHtml += '               <td width="20%" align="center" >' + AllTrim(Str(_aTmpDados[_nItPed][6])) + '</td>'
		_cHtml += '               <td width="20%" align="center">' + AllTrim(Str(_aTmpDados[_nItPed][5])) + '</td>'
		_cHtml += '            </tr>'

	Next _nItPed

	_cHtml += '         </table>'
	_cHtml += '         <br>'
	_cHtml += '      </td>'
	_cHtml += '   </tr>'
	_cHtml += '</table>'

	// prepara relacao de destinatarios
	_cDestin := AllTrim(SA1->A1_USRCONT)

	// envio de email
	U_FtMail(_cHtml, "TECADI - Log de Preparação de Pedido - " + DtoC(Date()), _cDestin)

	// restaura areas iniciais
	RestOrd(_aAreaIni, .T.)
	RestArea(_aAreaAtu)

Return( .T. )

//-------------------------------------------------------------------------------------------------

// ** funcao para estorno do palete
Static Function sfEstornoVol(mvIdVolume)
	// query
	local _cQryZ07, _cUpdZ16
	// variaveis temporarias
	local _aTmpRecno := {}
	local _nX
	// variavel de retorno
	local _lRet := .T.

	// valida id do palete
	If ( Empty(mvIdVolume) )
		// mensagem
		U_FtWmsMsg("Não há palete para estorno!","ATENCAO")
		// retorno
		Return( .F. )
	EndIf

	// mensagem para confirmar processo
	If ( ! U_FtYesNoMsg("Confirmar estorno da etiqueta "+Transf(mvIdVolume,_cMskEtiq)+"?"))
		Return( .F. )
	EndIf

	// monta SQL para estornar o palete
	_cQryZ07 := " SELECT Z07.R_E_C_N_O_ Z07RECNO, ISNULL(Z16.R_E_C_N_O_,0) Z16RECNO "
	// itens em conferencia
	_cQryZ07 += " FROM " + RetSqlTab("Z07") + " (nolock) "
	// composicao do palete
	_cQryZ07 += " LEFT JOIN " + RetSqlTab("Z16") + " (nolock)  ON " + RetSqlCond("Z16") + " AND Z16_ETQPAL = Z07_PALLET "
	_cQryZ07 += "      AND Z16_ETQVOL = Z07_ETQVOL AND Z16_ETQPRD = Z07_ETQPRD AND Z16_CODBAR = Z07_CODBAR "
	_cQryZ07 += "      AND Z16_CODPRO = Z07_PRODUT AND Z16_ENDATU = Z07_ENDATU "
	_cQryZ07 += "      AND Z16_LOTCTL = Z07_LOTCTL "

	// filtro padrao
	_cQryZ07 += " WHERE " + RetSqlCond("Z07")
	// filtro por OS
	_cQryZ07 += " AND Z07_NUMOS  = '" + _cNumOrdSrv + "' AND Z07_SEQOS = '" + _cSeqOrdSrv + "' "
	// cliente e loja
	_cQryZ07 += " AND Z07_CLIENT = '" + _cCodCliFor + "'  AND Z07_LOJA  = '" + _cLojCliFor + "' "
	// id do volume
	_cQryZ07 += " AND Z07_ETQVOL = '" + mvIdVolume + "' "
	// status C=EM CONFERENCIA e D=DISPONIVEL
	_cQryZ07 += " AND Z07_STATUS IN ('C','D') "
	// somente do pedido selecionado anteriormente
	_cQryZ07 += " AND Z07_PEDIDO = '" + _cPedido + "' "

	// alimenta o vetor
	_aTmpRecno := U_SqlToVet(_cQryZ07)

	// inicia transacao
	BEGIN TRANSACTION

		// varre todos os recno
		For _nX := 1 to Len(_aTmpRecno)

			If (_lRet)
				// posiciona no registro real
				dbSelectArea("Z07")
				Z07->(dbGoTo( _aTmpRecno[_nX][1] ))

				// atualiza o saldo do palete de origem
				If (Z07->Z07_STATUS == "D") // D-Disponivel (palete montado e saldo atualizado)

					// atualiza o saldo do palete de origem
					_cUpdZ16 := " UPDATE " + RetSqlName("Z16") + " SET Z16_SALDO = Z16_SALDO + " + AllTrim(Str(Z07->Z07_QUANT))
					// filtro padrao
					_cUpdZ16 += " WHERE Z16_FILIAL = '" + xFilial("Z16") + "' AND D_E_L_E_T_ = ' ' "
					// id do palete ORIGEM
					_cUpdZ16 += " AND Z16_ETQPAL = '" + Z07->Z07_PLTORI + "' "
					// etiqueta produto
					_cUpdZ16 += " AND Z16_ETQPRD = '" + Z07->Z07_ETQPRD + "' "
					// codigo do produto
					_cUpdZ16 += " AND Z16_CODPRO = '" + Z07->Z07_PRODUT + "' "
					// etiqueta de volume ORIGEM
					_cUpdZ16 += " AND Z16_ETQVOL = '" + Z07->Z07_VOLORI + "' "
					// lote
					_cUpdZ16 += " AND Z16_LOTCTL = '" + Z07->Z07_LOTCTL + "' "

					// executa o update
					If (TcSQLExec(_cUpdZ16) < 0)
						// rollback na transacao
						DisarmTransaction()
						_lRet := .F.
						// mensagem
						U_FtWmsMsg("*** ERRO NA ATUALIZACAO DO SALDO POR PALETE (sfEstornoVol) ***"+CRLF+CRLF+TCSQLError(),"ATENCAO")
						// retorno
						Break
					EndIf

				EndIf

				// exclui o registro da conferencia
				RecLock("Z07")
				Z07->(dbDelete())
				Z07->(MsUnLock())

				// posiciona no registro real - estrutura do palete
				If (_aTmpRecno[_nX][2] > 0)

					// tabela de composicao do palete
					dbSelectArea("Z16")
					Z16->(dbGoTo( _aTmpRecno[_nX][2] ))

					// exclui o registro
					RecLock("Z16")
					Z16->(dbDelete())
					Z16->(MsUnLock())

				EndIf

			EndIf
		Next _nX

		// finaliza transacao
	END TRANSACTION

	If (_lRet)
		// mensagem
		U_FtWmsMsg("Estorno realizado com sucesso!","ATENCAO")
		// atualiza os dados do browse
		//sfSelDados(.T.)

	EndIf

Return(_lRet)

//-------------------------------------------------------------------------------------------------
Static Function SairAtu()

	If lExit
		ZeraVars()
		oDlg:End()
		AtuBrws(3)
	EndIf

Return