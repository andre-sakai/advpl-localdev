#Include 'Protheus.ch'
#Include 'TopConn.ch'

//--------------------------------------------------------------------------------------//
// Programa: TWMSV011	|	Autor: Gustavo Schumann / SLA TI	|	Data: 07/11/2018	//
//--------------------------------------------------------------------------------------//
// Descrição: Tela de monitoramento e gerenciamento de operadores WMS e OS				//
//--------------------------------------------------------------------------------------//

User Function TWMSV011()

	if cFilAnt != "103"
		MsgAlert("Esta rotina está em testes, liberada apenas para filial 103 - Matriz!","Calma meu jovem!")
		Return()
	EndIf

	// verifica se pode executar a rotina (apenas gerentes ou supervisores)
	If ( !StaticCall(TWMSA010, sfVldUser, "G|S") )
		MsgAlert("É necessária senha de gerente/account para cancelar o carregamento!","Sem permissão")
		Return()
	EndIf

	Processa({|| fProcessa() },"Aguarde...")

Return

Static Function fProcessa()
	Local oPanel,oPanel1,oPanel2,oBitmap1,oBtnMod,oCmbPesq,oSayMod
	Local cTexto	:= space(50)
	Local oSim		:= LoadBitmap(GetResources(), "BR_VERMELHO")
	Local oNao		:= LoadBitmap(GetResources(), "BR_VERDE")
	Local aFiltro	:= {"1=Codigo","2=Nome"}
	Local nFiltro	:= 0
	Local oFont14	:= TFont():New('Arial',,-14,,.F.)

	Private oUsuarios,oOSUser,oDlg,oSayAtu,oSayOnline
	Private nOnline := 0
	Private aUsuarios:= {}
	Private aUsrOS	:= {{"","","","","","",""}}
	Private aUsrOn	:= {}
	Private cAtuUsr	:= "00:00"

	nFiltro := aFiltro[2]

	aSize := MsAdvSize()
	nMargDir := aSize[5] //coluna final

	GetUsers()

	DEFINE MSDIALOG oDlg TITLE "Controle de Usuarios" FROM 0, 0 TO 600, nMargDir-100  PIXEL STYLE DS_MODALFRAME

	@ 024, 000 MSPANEL oPanel1 SIZE 092, 275 OF oDlg COLORS 0, 16777215 
	@ 003, 002 BITMAP oBitmap1 SIZE 087, 087 OF oPanel1 FILENAME "\system\imagens\usuarios.jpg" NOBORDER ADJUST PIXEL

	oSayOnline := tSay():New(094,015,{|| AllTrim(Str(nOnline))+" Usuário(s) Online"},oPanel1,,oFont14,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)

	@ 000, 000 MSPANEL oPanel PROMPT "" SIZE 250, 020 OF oDlg  RAISED
	oSayMod := tSay():New(004,005,{|| "Pesquisar:" },oPanel,,,,,,.T.,CLR_HBLUE,CLR_WHITE,50,9)
	oCmbPesq := tComboBox():New(003,050,{|u|if(PCount()>0,nFiltro:=u,nFiltro)},aFiltro,60,9,oPanel,, { || oUsuarios:SetOrder(Val(nFiltro)),oGetMod:SetFocus() } ,,,,.T.,,,,,,,,,'nFiltro')
	oGetMod := tGet():New(003,120,{|u| if(PCount()>0,cTexto:=u,cTexto)}, oPanel ,70,9,"",{ || fPesquisa(nFiltro,cTexto)  },,,,,,.T.,,, {|| .T. } ,,,,.F.,,,'cTexto')		
	oBtnMod := tButton():New(003,190,'Pesquisar' ,oPanel, {|| fPesquisa(nFiltro,cTexto)  },38,11,,,,.T.)
	@ 000, 058 BITMAP oSair	    SIZE 016, 012 OF oPanel RESOURCE "FINAL" NOBORDER ON CLICK oDlg:End() PIXEL
	oSair:cToolTip	:= "Sair da rotina"
	oSair:Align		:= CONTROL_ALIGN_RIGHT

	//------------------------------------------------------------------------
	@ 000, 000 MSPANEL oPanel2 SIZE 250, 016 OF oDlg COLORS 0, 16777215 RAISED
	//------------------------------------------------------------------------
	@ 000, 000 MSPANEL oPanelA SIZE 250, 120 OF oPanel2 COLORS 0, 16777215 RAISED
	@ 000, 000 MSPANEL oToolBar SIZE 250, 016 OF oPanelA COLORS 0, 16777215 RAISED

	@ 000, 000 BITMAP oAtualiza SIZE 016, 012 OF oToolBar RESOURCE "TK_REFRESH"  NOBORDER ON CLICK Processa({|| fRefresh()}	,"Atualizando usuários... Esta operação pode levar até 3 minutos.") PIXEL
	@ 000, 000 BITMAP oExibeOS SIZE 016, 012 OF oToolBar RESOURCE "S4WB007N"  NOBORDER ON CLICK Processa({|| GetOSUser(aUsuarios[oUsuarios:nAt,02],aUsuarios[oUsuarios:nAt,03]),oOSUser:SetArray(aUsrOS),oOSUser:Refresh()}	,"Atualizando...") PIXEL
	@ 000, 000 BITMAP oAtribOS SIZE 016, 012 OF oToolBar RESOURCE "PEDIDO"  NOBORDER ON CLICK Processa({|| AtribOS(aUsuarios[oUsuarios:nAt,02],aUsuarios[oUsuarios:nAt,03]) }	,"Atualizando...") PIXEL
	@ 000, 000 BITMAP oDerruba  SIZE 016, 012 OF oToolBar RESOURCE "AFASTAMENTO" NOBORDER ON CLICK MsgRun("Processando...","Derrubar",{|| fDerruba(aUsuarios[oUsuarios:nAt,01],aUsuarios[oUsuarios:nAt,02],aUsuarios[oUsuarios:nAt,03]),UpdTime(),oSayOnline:Refresh()}) PIXEL

	oSayAtu := tSay():New(000,005,{|| "Ultima Atualizacao: " + cAtuUsr},oToolBar,,,,,,.T.,CLR_BLACK,CLR_WHITE,50,9)

	oAtualiza:cToolTip	:= "Atualiza lista de conexões"
	oExibeOS:cToolTip	:= "Exibir OS que o usuário está vinculado"
	oAtribOS:cToolTip	:= "Atribuir OS ao usuário"
	oDerruba:cToolTip	:= "Derruba usuario selecionado"

	oUsuarios := TCBrowse():New(010,005,300,150,,,,oPanelA,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	oUsuarios:AddColumn(TCColumn():New(" "					  , {|| IIf(aUsuarios[oUsuarios:nAt,01] == 0,oSim,oNao)},,,,,,.T.,.F.,,,,.F., ) )
	oUsuarios:AddColumn(TCColumn():New("Codigo"				  , {|| aUsuarios[oUsuarios:nAt,02]}                    ,,,,, 030,.F.,.F.,,,,.F., ) )
	oUsuarios:AddColumn(TCColumn():New("Nome"				  , {|| aUsuarios[oUsuarios:nAt,03]}                    ,,,,, 060,.F.,.T.,,,,.F., ) )
	oUsuarios:AddColumn(TCColumn():New("Qtd OS Vinculadas"	  , {|| aUsuarios[oUsuarios:nAt,04]}                    ,,,,"CENTER", 060,.F.,.T.,,,,.F., ) )
	oUsuarios:AddColumn(TCColumn():New("Produtividade Diaria" , {|| aUsuarios[oUsuarios:nAt,05]}                    ,,,,"CENTER", 060,.F.,.T.,,,,.F., ) )
	oUsuarios:AddColumn(TCColumn():New("Produtividade Semanal", {|| aUsuarios[oUsuarios:nAt,06]}                    ,,,,"CENTER", 060,.F.,.T.,,,,.F., ) )
	oUsuarios:SetArray(aUsuarios)
	oUsuarios:bLDblClick   := { || Processa({ || GetOSUser(aUsuarios[oUsuarios:nAt,02],aUsuarios[oUsuarios:nAt,03]),oOSUser:SetArray(aUsrOS),oOSUser:Refresh() },"Atualizando...")}
	oUsuarios:Refresh()

	//------------------------------------------------------------------------

	@ 000, 000 MSPANEL oPanelB SIZE 250, 120 OF oPanel2 COLORS 0, 16777215 RAISED
	@ 000, 000 MSPANEL oBotoes SIZE 250, 016 OF oPanelB COLORS 0, 16777215 RAISED
	@ 000, 000 BITMAP oEditar   SIZE 016, 012 OF oBotoes RESOURCE "VERNOTA" NOBORDER ON CLICK VerUsrOs(aUsrOS[oOSUser:nAt,03]) PIXEL
	@ 000, 000 BITMAP oSuspend   SIZE 016, 012 OF oBotoes RESOURCE "SOLICITA" NOBORDER ON CLICK Processa({|| SuspOSUsr(aUsrOS[oOSUser:nAt,01],aUsrOS[oOSUser:nAt,03],aUsrOS[oOSUser:nAt,04])  }	,"Atualizando...") PIXEL
	oEditar:cToolTip  := "Exibir usuário vinculados a OS selecionada."
	oSuspend:cToolTip	:= "Suspender OS do usuário"

	oOSUser := TCBrowse():New(094,002,088,100,,,,oPanelB,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	oOSUser:AddColumn(TCColumn():New("Codigo"		, {|| aUsrOS[oOSUser:nAt,01]},,,,, 020,.F.,.F.,,,,.F., ) )
	oOSUser:AddColumn(TCColumn():New("Nome"			, {|| aUsrOS[oOSUser:nAt,02]},,,,, 060,.F.,.F.,,,,.F., ) )
	oOSUser:AddColumn(TCColumn():New("OS"			, {|| aUsrOS[oOSUser:nAt,03]},,,,, 040,.F.,.F.,,,,.F., ) )
	oOSUser:AddColumn(TCColumn():New("Sequencia"	, {|| aUsrOS[oOSUser:nAt,04]},,,,, 020,.F.,.F.,,,,.F., ) )
	oOSUser:AddColumn(TCColumn():New("Tp Operacao"	, {|| aUsrOS[oOSUser:nAt,05]},,,,, 040,.F.,.F.,,,,.F., ) )
	oOSUser:AddColumn(TCColumn():New("Servico"		, {|| aUsrOS[oOSUser:nAt,06]},,,,, 040,.F.,.F.,,,,.F., ) )
	oOSUser:AddColumn(TCColumn():New("Tarefa"		, {|| aUsrOS[oOSUser:nAt,07]},,,,, 040,.F.,.F.,,,,.F., ) )
	oOSUser:SetArray(aUsrOS)
	oOSUser:bLDblClick := { || VerUsrOs(aUsrOS[oOSUser:nAt,03]) }
	oOSUser:Refresh()

	oPanel:Align := CONTROL_ALIGN_TOP
	oPanel1:Align := CONTROL_ALIGN_LEFT
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

	oPanelA:Align   := CONTROL_ALIGN_ALLCLIENT
	oToolBar:Align  := CONTROL_ALIGN_TOP
	oAtualiza:Align := CONTROL_ALIGN_LEFT
	oExibeOS:Align := CONTROL_ALIGN_LEFT
	oAtribOS:Align   := CONTROL_ALIGN_LEFT
	oDerruba:Align 	:= CONTROL_ALIGN_LEFT
	oSayAtu:Align   := CONTROL_ALIGN_RIGHT
	oUsuarios:Align := CONTROL_ALIGN_ALLCLIENT

	oPanelB:Align 	:= CONTROL_ALIGN_BOTTOM
	oBotoes:Align 	:= CONTROL_ALIGN_TOP
	oEditar:Align   := CONTROL_ALIGN_LEFT
	oSuspend:Align   := CONTROL_ALIGN_LEFT
	oOSUser:Align 	:= CONTROL_ALIGN_ALLCLIENT

	ACTIVATE MSDIALOG oDlg /*ON INIT EnchoiceBar(oDlg,bOk,bCancela,,aButtons)*/ CENTERED


Return
//-------------------------------------------------------------------------------------------------
Static Function fPesquisa(_nFiltro,_cTexto)
	Local x := 1

	// Pesquisa no array pelo Código
	If _nFiltro == "1"
		For x:=1 To Len(aUsuarios)
			If AllTrim(_cTexto) $ aUsuarios[x][2]
				oUsuarios:GoPosition(x)
				oUsuarios:setFocus()
			EndIf
		Next x
	Else // Pesquisa no array pelo Nome
		For x:=1 To Len(aUsuarios)
			If Upper(AllTrim(_cTexto)) $ Upper(aUsuarios[x][3])
				oUsuarios:GoPosition(x)
				oUsuarios:setFocus()
			EndIf
		Next x
	EndIf

Return
//-------------------------------------------------------------------------------------------------
Static Function fRefresh()
	Local aArea := GetArea()
	Local cHora := ""

	DBSelectArea("SX5")
	DBSetOrder(1)
	If DBSeek(XFilial()+"Z1"+__cUserID)
		If AllTrim( DTOS( Date())) == AllTrim(SX5->X5_DESCSPA)
			cHora	:= zHr2Val(SX5->X5_DESCRI)
			cTime	:= zHr2Val(SubString( Time(),1,5))
			If (cTime - cHora) >= 0.08 // 0.08 convertidos em tempo é igual a 5 minutos
				UsrArray()
				GetUsers()
				oUsuarios:SetArray(aUsuarios)
				oUsuarios:Refresh()
				UpdTime()
				oSayOnline:Refresh()
				RecLock("SX5",.F.)
				SX5->X5_DESCRI	:= SubString( Time(),1,5)
				SX5->X5_DESCSPA	:= DTOS( Date())
				MsUnLock("SX5")
			Else
				MsgAlert("Somente é possível atualizar as conexões a cada 5 minutos. " + CRLF + "Próxima liberação a partir de: "+AllTrim(StrTran(Str(SomaHoras(SX5->X5_DESCRI,"00:05:00")),".",":")))
			EndIf
		Else
			UsrArray()
			GetUsers()
			oUsuarios:SetArray(aUsuarios)
			oUsuarios:Refresh()
			UpdTime()
			oSayOnline:Refresh()
			RecLock("SX5",.F.)
			SX5->X5_DESCRI	:= SubString( Time(),1,5)
			SX5->X5_DESCSPA	:= DTOS( Date())
			MsUnLock("SX5")
		EndIf
	Else
		UsrArray()
		GetUsers()
		oUsuarios:SetArray(aUsuarios)
		oUsuarios:Refresh()
		UpdTime()
		oSayOnline:Refresh()

		RecLock("SX5",.T.)
		SX5->X5_FILIAL	:= xFilial("SX5")
		SX5->X5_TABELA	:= "Z1"
		SX5->X5_CHAVE	:= __cUserID
		SX5->X5_DESCRI	:= SubString( Time(),1,5)
		SX5->X5_DESCSPA	:= DTOS( Date())
		MsUnLock("SX5")

	EndIf
	RestArea(aArea)
Return
//-------------------------------------------------------------------------------------------------
Static Function zHr2Val(cHora)
	Local aArea		:= GetArea()
	Local nAux		:= 0
	Local cMin		:= ""
	Local nValor	:= 0
	Local nPosSep	:= 0
	Local cSep		:= ':'

	//Se tiver a hora
	If !Empty(cHora)
		nPosSep	:= RAt(cSep, cHora)
		nAux	:= Val(SubStr(cHora, nPosSep+1, 2))
		nAux	:= Int(Round((nAux*100)/60, 0))
		cMin	:= Iif(nAux > 10, cValToChar(nAux), "0"+cValToChar(nAux))
		nValor	:= Val(SubStr(cHora, 1, nPosSep-1)+"."+cMin)
	EndIf

	RestArea(aArea)
Return nValor
//-------------------------------------------------------------------------------------------------
Static Function UpdTime()
	cAtuUsr := SubString( Time(),1,5)
	oSayAtu:Refresh()
Return
//-------------------------------------------------------------------------------------------------
Static Function UsrArray()
	local oSrv		:= nil
	local cEnv		:= GetEnvServer() //Ambiente
	local nIdx		:= 0
	local aServers	:= {}
	local aTmp		:= {}
	Local cSrvIp	:= GETSERVERIP()
	Local aPortas	:= {12101,12102,12103,12104,12105,12106,12107} //Base Producao
	//Local aPortas  := {13000} //Base Teste

	IncProc("Localizando balances...")

	// neste caso, quero apenas o balance, que me retorna todos os slaves conectados.
	aadd(aServers, {cSrvIp, aPortas[1]})
	aadd(aServers, {cSrvIp, aPortas[2]})
	aadd(aServers, {cSrvIp, aPortas[3]})
	aadd(aServers, {cSrvIp, aPortas[4]})
	aadd(aServers, {cSrvIp, aPortas[5]})
	aadd(aServers, {cSrvIp, aPortas[6]})
	aadd(aServers, {cSrvIp, aPortas[7]})

	aUsrOn := {}

	For nIdx := 1 to len(aServers)
		IncProc("Ambiente: "+cEnv+" | Servidor: "+aServers[nIdx,1]+"/"+Alltrim(Str(aServers[nIdx,2])))
		// conecta no slave via rpc
		oSrv := TRPC():New( cEnv )
		oSrv:Connect( aServers[nIdx,1], aServers[nIdx,2] )

		if valtype(oSrv) == "O"
			oSrv:callproc("RPCSetType", 3)

			// chama a funcao remotamente no server, retornando a lista de usuarios conectados
			aTmp := oSrv:callproc("GetUserInfoArray")
			aadd(aUsrOn, aclone(aTmp))
			aTmp := nil

			// limpa o ambiente
			oSrv:callproc("RpcClearEnv")

			// fecha a conexao
			oSrv:Disconnect()
		else
			return "Falha ao obter a lista de usuarios."
		endif
		FreeObj(oSrv)
	Next nIdx
Return
//-------------------------------------------------------------------------------------------------
Static Function fDerruba(nConect,cUser,cNome)
	Local x := 1
	Local z := 1
	Local _nCaptcha
	Local _cCaptcha

	If nConect == 1
		If MsgYesNo("Tem certeza que deseja desconectar o usuário "+AllTrim(cNome)+"?")

			_nCaptcha := Randomize(1,32766)
			_cCaptcha := "Insira o número de segurança " + Str(_nCaptcha)

			If ( _nCaptcha != Val(FWInputBox(_cCaptcha,"")) )
				MsgAlert("Falha na verificação do CAPTCHA. Repita a operação e informe o número corretamente","Erro na validação do CAPTCHA")
				Return()
			EndIf

			For x:=1 To Len(aUsrOn)
				For z:=1 To Len(aUsrOn[x])
					If cUser $ aUsrOn[x][z][11]
						KillUser( aUsrOn[x][z][1], aUsrOn[x][z][2], aUsrOn[x][z][3], aUsrOn[x][z][4] ) // Realiza a desconexão
					EndIf
				Next z
			Next x

			UsrArray() // Carrega os usuário conectados nos AppServers
			GetUsers() // Identifica os usuário online com os usuários do WMS
			oUsuarios:SetArray(aUsuarios) // Recarrega o array no aCols dos usuários
			oUsuarios:Refresh() // Refresh no grid dos usuários
			UpdTime()
			oSayOnline:Refresh()
		EndIf
	Else
		MsgAlert("Não foi possível encontrar a conexão do usuário. Abortando!")
	EndIf

Return
//-------------------------------------------------------------------------------------------------
Static Function GetUsers()
	Local aTemp := {}
	Local aTemp2:= {}
	Local nCon	:= 0
	Local x,z,k := 1
	aUsuarios := {}
	nOnline := 0

	If Select("tCDC") > 0
		DBSelectArea("tCDC")
		tCDC->(DBCloseArea())
	EndIf

	cQuery := " select DCD_CODFUN,DCD_NOMFUN,(SELECT count(DISTINCT(Z18_NUMOS)) "
	cQuery += " 							FROM "+RetSQLName("Z18")+" Z18 (NOLOCK) "
	cQuery += " 								INNER JOIN "+RetSQLName("Z06")+" Z06 (NOLOCK) "
	cQuery += " 								ON Z06.D_E_L_E_T_ = '' "
	cQuery += " 								AND Z06_FILIAL = Z18_FILIAL "
	cQuery += " 								AND Z06_NUMOS = Z18_NUMOS "
	cQuery += " 								AND Z06_SEQOS = Z18_SEQOS "
	cQuery += " 								AND Z06_STATUS NOT IN ( 'FI', 'BL', 'CA' ) "
	cQuery += " 							WHERE  Z18.D_E_L_E_T_ = '' "
	cQuery += " 							AND Z18_FILIAL = '"+xFilial("Z18")+"' "
	cQuery += " 							AND Z18_OPERAD = DCD_CODFUN "
	cQuery += " 							AND Z18.D_E_L_E_T_ = '' "
	cQuery += " 							AND Z18_STATUS <> 'B') as QTD_OS, "
	cQuery += " 							IsNull((select  CONVERT(varchar(10), sum(qtd_z07))  + ' / ' + CONVERT(varchar(10), Sum(QTD_Z17)) Prod_Diaria "
	cQuery += " 							From ( "
	cQuery += " 							SELECT distinct Z18_OPERAD, "
	cQuery += " 									(SELECT Count(*) "
	cQuery += "											FROM   "+RetSQLName("Z07")+" (NOLOCK) "
	cQuery += "											WHERE  z07_filial = Z05_FILIAL "
	cQuery += "												AND D_E_L_E_T_ = '' "
	cQuery += "												AND z07_numos = z05_numos "
	cQuery += "												AND Z07_USUARI = Z18_OPERAD) qtd_z07, "
	cQuery += "											(SELECT Count(*) "
	cQuery += "											FROM   "+RetSQLName("Z17")+" (NOLOCK) "
	cQuery += "											WHERE  z17_filial = Z05_FILIAL "
	cQuery += "												AND D_E_L_E_T_ = '' "
	cQuery += "												AND z17_numos = z05_numos "
	cQuery += "												AND Z17_OPERAD = Z18_OPERAD) QTD_Z17 "
	cQuery += "							FROM "+RetSQLName("Z18")+" Z18 (NOLOCK) "
	cQuery += "								INNER JOIN "+RetSQLName("Z06")+" Z06 (NOLOCK) "
	cQuery += "									ON Z06.D_E_L_E_T_ = '' "
	cQuery += "									AND Z06_FILIAL = Z18_FILIAL "
	cQuery += "									AND Z06_NUMOS = Z18_NUMOS "
	cQuery += "									AND Z06_SEQOS = Z18_SEQOS "
	cQuery += "									AND Z06_STATUS = 'FI' "
	cQuery += "								INNER JOIN "+RetSQLName("Z05")+" Z05 (NOLOCK) "
	cQuery += "									ON Z05.D_E_L_E_T_ = '' "
	cQuery += "									AND Z05_FILIAL = Z06_FILIAL "
	cQuery += "									AND Z05_NUMOS = Z06_NUMOS "
	cQuery += "									AND Z05_DTEMIS BETWEEN '"+ DTOS( Date() -1 ) +"' AND '"+ DTOS( Date() ) +"' "
	cQuery += "							WHERE Z18.D_E_L_E_T_ = '' "
	cQuery += "								AND Z18_FILIAL = '"+xFilial("Z18")+"' "
	cQuery += "								AND Z18_OPERAD = DCD_CODFUN "
	cQuery += "								AND Z18_STATUS <> 'B'  "
	cQuery += "							) as x "
	cQuery += "							group by Z18_OPERAD),'0 / 0') Prod_diaria, "
	cQuery += "							IsNull((select  CONVERT(varchar(10), sum(qtd_z07))  + ' / ' + CONVERT(varchar(10), Sum(QTD_Z17)) Prod_Semanal "
	cQuery += "							From ( "
	cQuery += "							SELECT distinct Z18_OPERAD, "
	cQuery += "									(SELECT Count(*) "
	cQuery += "									FROM   "+RetSQLName("Z07")+" (NOLOCK) "
	cQuery += "									WHERE  z07_filial = Z05_FILIAL "
	cQuery += "										AND D_E_L_E_T_ = '' "
	cQuery += "										AND z07_numos = z05_numos "
	cQuery += "										AND Z07_USUARI = Z18_OPERAD) qtd_z07, "
	cQuery += "									(SELECT Count(*) "
	cQuery += "									FROM "+RetSQLName("Z17")+" (NOLOCK) "
	cQuery += "									WHERE Z17_filial = Z05_FILIAL "
	cQuery += "										AND D_E_L_E_T_ = '' "
	cQuery += "										AND Z17_numos = z05_numos "
	cQuery += "										AND Z17_OPERAD = Z18_OPERAD) QTD_Z17 "
	cQuery += "							FROM "+RetSQLName("Z18")+" Z18 (NOLOCK) "
	cQuery += "								INNER JOIN "+RetSQLName("Z06")+" Z06 (NOLOCK) "
	cQuery += "									ON Z06.D_E_L_E_T_ = '' "
	cQuery += "									AND Z06_FILIAL = Z18_FILIAL "
	cQuery += "									AND Z06_NUMOS = Z18_NUMOS "
	cQuery += "									AND Z06_SEQOS = Z18_SEQOS "
	cQuery += "									AND Z06_STATUS = 'FI' "
	cQuery += "							INNER JOIN "+RetSQLName("Z05")+" Z05 (NOLOCK) "
	cQuery += "									ON Z05.D_E_L_E_T_ = '' "
	cQuery += "									AND Z05_FILIAL = Z06_FILIAL "
	cQuery += "									AND Z05_NUMOS = Z06_NUMOS "
	cQuery += "									AND Z05_DTEMIS BETWEEN '"+ DTOS( Date() -7 ) +"' AND '"+ DTOS( Date() ) +"' "
	cQuery += "							WHERE  Z18.D_E_L_E_T_ = '' "
	cQuery += "								AND Z18_FILIAL = '"+xFilial("Z18")+"' "
	cQuery += "								AND Z18_OPERAD = DCD_CODFUN "
	cQuery += "								AND Z18_STATUS <> 'B'  "
	cQuery += "							) as x "
	cQuery += "							group by Z18_OPERAD),'0 / 0') Prod_Semanal "
	cQuery += " from "+RetSQLName("DCD")+" (NOLOCK) "
	cQuery += " where D_E_L_E_T_ = '' "
	cQuery += " and DCD_ZFLDIS like '%"+xFilial("Z18")+"%' "
	cQuery += " and DCD_MSBLQL = '2' "
	cQuery += " and DCD_ZCATEG = 'O' "

	TCQuery cQuery NEW ALIAS "tCDC"

	DBSelectArea("tCDC")
	tCDC->(DBGoTop())

	// Carrega todos as conexões ativas nos AppServers configurados na rotina
	//UsrArray()

	For x:=1 To Len(aUsrOn)
		For z:=1 To Len(aUsrOn[x])
			If AllTrim(aUsrOn[x][z][5]) == "U_TACDA002" // Percorre o array com as conexões e filtra somente as que estão rodando o WMS no coletor
				// se usuário está logado (e não somente na tela inicial aguardando login)
				If ( !Empty(aUsrOn[x][z][11]) )
					// Adiciona ao array aTemp o ID do usuário
					aTemp2 := StrTokArr(aUsrOn[x][z][11],"[]") // Filtra a ID do usuário
					AADD(aTemp,aTemp2[2])
				EndIf 
			EndIf
		Next z
	Next x

	if !tCDC->(EOF())
		While !tCDC->(EOF())

			nCon := 0

			For k:=1 To Len(aTemp)
				If aTemp[k] == tCDC->DCD_CODFUN
					nOnline++
					nCon := 1
				EndIf
			Next k

			Aadd(aUsuarios,{nCon,tCDC->DCD_CODFUN,tCDC->DCD_NOMFUN,tCDC->QTD_OS,tCDC->Prod_Diaria,tCDC->Prod_Semanal,""})

			tCDC->(DBSkip())
		EndDo
	Else
		Aadd(aUsuarios,{.F.,"","","",0,"",""})
	EndIf

	aSort(aUsuarios, , , { | x,y | x[1] > y[1] } )

Return
//-------------------------------------------------------------------------------------------------
Static Function GetOSUser(cUser,cNome)

	aUsrOS := {}

	If Select("tZ18") > 0
		DBSelectArea("tZ18")
		tZ18->(DBCloseArea())
	EndIf

	cQuery := " "
	cQuery += " SELECT Z18_OPERAD USUARIO, "
	cQuery += " 	Z05_NUMOS NUMOS, "
	cQuery += " 	Z06_SEQOS SEQOS, "
	cQuery += " 	CASE "
	cQuery += " 		WHEN Z05_TPOPER = 'E' THEN 'RECEBIMENTO' "
	cQuery += " 		WHEN Z05_TPOPER = 'I' THEN 'INTERNA' "
	cQuery += " 		WHEN Z05_TPOPER = 'S' THEN 'EXPEDIÇÃO' "
	cQuery += " 	END AS 'TIPO_OPERACAO', "
	cQuery += " 	UPPER(SX5A.X5_DESCRI) AS 'SERVICO', "
	cQuery += " 	UPPER(SX5B.X5_DESCRI) AS 'TAREFA' "
	cQuery += " FROM "+RetSQLName("Z18")+" Z18 (NOLOCK) "
	cQuery += " 	INNER JOIN "+RetSQLName("Z06")+" Z06 (NOLOCK) "
	cQuery += " 		ON Z06.D_E_L_E_T_ = '' "
	cQuery += " 		AND Z06_FILIAL = Z18_FILIAL "
	cQuery += " 		AND Z06_NUMOS = Z18_NUMOS "
	cQuery += " 		AND Z06_SEQOS = Z18_SEQOS "
	cQuery += " 		AND Z06_STATUS NOT IN ( 'FI', 'BL', 'CA' ) "
	cQuery += " 	INNER JOIN "+RetSQLName("Z05")+" Z05 (NOLOCK) "
	cQuery += " 		ON Z05.D_E_L_E_T_ = '' "
	cQuery += " 		AND Z05_FILIAL = Z06_FILIAL "
	cQuery += " 		AND Z05_NUMOS = Z06_NUMOS "
	cQuery += " 	LEFT JOIN "+RetSQLName("SX5")+" SX5A (NOLOCK) "
	cQuery += " 		ON SX5A.X5_TABELA = 'L4' "
	cQuery += " 		AND SX5A.X5_CHAVE = Z06_SERVIC "
	cQuery += " 		AND SX5A.D_E_L_E_T_ = '' "
	cQuery += " 	LEFT JOIN "+RetSQLName("SX5")+" SX5B (NOLOCK) "
	cQuery += " 		ON SX5B.X5_TABELA = 'L2' "
	cQuery += " 		AND SX5B.X5_CHAVE = Z06_TAREFA "
	cQuery += " 		AND SX5B.D_E_L_E_T_ = '' "
	cQuery += " WHERE  Z18.D_E_L_E_T_ = '' "
	cQuery += " 	AND Z18_FILIAL = '"+xFilial("Z18")+"' "
	cQuery += " 	AND Z18_OPERAD = '"+cUser+"' "
	cQuery += " 	AND Z18_STATUS <> 'B' "
	cQuery += " 	ORDER BY Z05_NUMOS,Z06_SEQOS "

	TCQuery cQuery NEW ALIAS "tZ18"

	DBSelectArea("tZ18")
	tZ18->(DBGoTop())

	if !tZ18->(EOF())
		While !tZ18->(EOF())

			Aadd(aUsrOS,{tZ18->USUARIO,cNome,tZ18->NUMOS,tZ18->SEQOS,tZ18->TIPO_OPERACAO,tZ18->SERVICO,tZ18->TAREFA,""})

			tZ18->(DBSkip())
		EndDo
	Else
		Aadd(aUsrOS,{"","","","","","","",""})
	EndIf

Return
//-------------------------------------------------------------------------------------------------
Static Function VerUsrOs(cNumOS)
	Local aUsrVinc := {}
	Local oDlgVinc
	Local oSBtExt

	If Select("tUsrOs") > 0
		DBSelectArea("tUsrOs")
		tUsrOs->(DBCloseArea())
	EndIf

	cQuery := " "
	cQuery += " SELECT distinct Z18_NUMOS,Z18_OPERAD,DCD_NOMFUN "
	cQuery += " FROM "+RetSQLName("Z18")+" Z18 "
	cQuery += " 	inner join "+RetSQLName("DCD")+" DCD "
	cQuery += " 	on DCD.D_E_L_E_T_ = '' "
	cQuery += " 	and DCD_CODFUN = Z18_OPERAD "
	cQuery += " where Z18.D_E_L_E_T_ = '' "
	cQuery += " and Z18_NUMOS = '"+AllTrim(cNumOS)+"' "
	cQuery += " and Z18_OPERAD <> '' "
	cQuery += " and Z18_STATUS <> 'B' "

	TCQuery cQuery NEW ALIAS "tUsrOs"

	DBSelectArea("tUsrOs")
	tUsrOs->(DBGoTop())

	if !tUsrOs->(EOF())
		While !tUsrOs->(EOF())

			Aadd(aUsrVinc,{tUsrOs->Z18_NUMOS,tUsrOs->Z18_OPERAD,tUsrOs->DCD_NOMFUN,""})

			tUsrOs->(DBSkip())
		EndDo
	Else
		Aadd(aUsrVinc,{"","","",""})
	EndIf

	oDlgVinc := MSDialog():new(1,1,250,500,'Usuario vinculado a OS '+AllTrim(cNumOS),,,,,CLR_BLACK,CLR_WHITE,,,.t.)

	oUsrVinc := TCBrowse():New(015,002,247,108,,,,oDlgVinc,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	oUsrVinc:AddColumn(TCColumn():New("OS"				, {|| aUsrVinc[oUsrVinc:nAt,01]},,,,, 030,.F.,.F.,,,,.F., ) )
	oUsrVinc:AddColumn(TCColumn():New("Codigo usuario"	, {|| aUsrVinc[oUsrVinc:nAt,02]},,,,, 060,.F.,.T.,,,,.F., ) )
	oUsrVinc:AddColumn(TCColumn():New("Nome usuario"	, {|| aUsrVinc[oUsrVinc:nAt,03]},,,,, 060,.F.,.T.,,,,.F., ) )
	oUsrVinc:SetArray(aUsrVinc)
	oUsrVinc:Refresh()

	oSBtExt	:= SButton():New(002,002,01,{|| oDlgVinc:End() },oDlgVinc,.T.,,)

	oDlgVinc:Activate()

Return
//-------------------------------------------------------------------------------------------------
Static Function SuspOSUsr(cUsuario,cNumOS,cSeq)

	If MsgYesNo("Suspender OS "+cNumOS+" Sequencia "+cSeq+" do usuário "+cUsuario+"?")

		cQuery := ""
		cQuery += " update Z18 Set Z18_STATUS = 'B' "
		cQuery += " from "+RetSQLName("Z18")+" Z18 "
		cQuery += " where D_E_L_E_T_ = '' "
		cQuery += " and Z18_FILIAL = '"+xFilial("Z18")+"' "
		cQuery += " and Z18_OPERAD = '"+cUsuario+"' "
		cQuery += " and Z18_NUMOS = '"+cNumOS+"' "
		cQuery += " and Z18_SEQOS = '"+cSeq+"' "

		nRet := TCSQLEXEC(cQuery)

		If nRet <> 0
			MsgAlert(TcSQLError())
		EndIf

		AtuGridUsr(cUsuario)

		cNome := Posicione("DCD",1,xFilial("DCD")+cUsuario,"DCD_NOMFUN")

		GetOSUser(cUsuario,cNome)
		oOSUser:SetArray(aUsrOS)
		oOSUser:Refresh()

	EndIf

Return
//-------------------------------------------------------------------------------------------------
Static Function AtuGridUsr(cUsuario)

	If Select("tQTDOS") > 0
		DBSelectArea("tQTDOS")
		tQTDOS->(DBCloseArea())
	EndIf

	cQuery := " "
	cQuery += " SELECT count(DISTINCT(Z18_NUMOS)) QTDOS "
	cQuery += " FROM "+RetSQLName("Z18")+" Z18 (NOLOCK)  "
	cQuery += " 	INNER JOIN "+RetSQLName("Z06")+" Z06 (NOLOCK)  "
	cQuery += " 	ON Z06.D_E_L_E_T_ = ''  "
	cQuery += " 	AND Z06_FILIAL = Z18_FILIAL  "
	cQuery += " 	AND Z06_NUMOS = Z18_NUMOS  "
	cQuery += " 	AND Z06_SEQOS = Z18_SEQOS  "
	cQuery += " 	AND Z06_STATUS NOT IN ( 'FI', 'BL', 'CA' ) "
	cQuery += " WHERE  Z18.D_E_L_E_T_ = '' " 
	cQuery += " AND Z18_FILIAL = '"+xFilial("Z18")+"' "
	cQuery += " AND Z18_OPERAD = '"+cUsuario+"' "
	cQuery += " AND Z18.D_E_L_E_T_ = '' " 
	cQuery += " AND Z18_STATUS <> 'B' "

	TCQuery cQuery NEW ALIAS "tQTDOS"

	DBSelectArea("tQTDOS")
	tQTDOS->(DBGoTop())

	if !tQTDOS->(EOF())
		nPos := AScanX(aUsuarios,{|x| x[2] == cUsuario})
		aUsuarios[nPos][4] := tQTDOS->QTDOS
		oUsuarios:SetArray(aUsuarios)
		oUsuarios:Refresh()
	EndIf

Return
//-------------------------------------------------------------------------------------------------
Static Function AtribOS(cUsuario,cNome)
	Local aOpenOS := {}

	If Select("tQRYOS") > 0
		DBSelectArea("tQRYOS")
		tQRYOS->(DBCloseArea())
	EndIf

	cQuery := ""
	cQuery += " SELECT DISTINCT Z05_NUMOS, Z06_SEQOS, CASE   WHEN Z05_TPOPER = 'E' THEN 'REC'   WHEN Z05_TPOPER = 'S' THEN 'EXP' "
	cQuery += " WHEN Z05_TPOPER = 'I' THEN 'INT' END DSC_OPER, CASE   WHEN Z05_TPOPER = 'E' THEN Z05_PROCES   WHEN Z05_TPOPER = 'S' THEN Z05_CARGA "
	cQuery += " WHEN Z05_TPOPER = 'I' THEN ' ' END PG_CARGA, ISNULL(A1_NREDUZ,'OS INTERNA') A1_NREDUZ, Z06_PRIOR, Z06_SERVIC, SX5SRV.X5_DESCRI DSC_SERVIC, "
	cQuery += " Z06_TAREFA, SX5TRF.X5_DESCRI DSC_TAREFA, Z06_STATUS, Z05_CLIENT, Z05_LOJA, CASE WHEN Z06_ENDSRV = 'ZZZ' THEN 'XXX' ELSE Z06_ENDSRV END Z06_ENDSRV "
	cQuery += " FROM  "+RetSQLName("Z05")+" Z05  (NOLOCK)  "
	cQuery += " LEFT  JOIN  "+RetSQLName("SA1")+" SA1  (NOLOCK) ON  A1_FILIAL = '"+xFilial("SA1")+"' AND  SA1.D_E_L_E_T_ = ' '  AND A1_COD = Z05_CLIENT AND A1_LOJA = Z05_LOJA "
	cQuery += " LEFT  JOIN  "+RetSQLName("Z08")+" Z08  (NOLOCK) ON  Z08_FILIAL = '"+xFilial("Z08")+"' AND  Z08.D_E_L_E_T_ = ' '  AND Z08_NUMOS = Z05_NUMOS "
	cQuery += " INNER JOIN  "+RetSQLName("Z06")+" Z06  (NOLOCK) ON  Z06_FILIAL = '"+xFilial("Z06")+"' AND  Z06.D_E_L_E_T_ = ' '  AND Z06_NUMOS = Z05_NUMOS "
	cQuery += " INNER JOIN "+RetSQLName("SX5")+" SX5SRV (NOLOCK) ON SX5SRV.X5_FILIAL = '"+xFilial("SX5")+"' AND SX5SRV.D_E_L_E_T_ = ' ' AND SX5SRV.X5_TABELA = 'L4' AND SX5SRV.X5_CHAVE = Z06_SERVIC "
	cQuery += " INNER JOIN "+RetSQLName("SX5")+" SX5TRF (NOLOCK) ON SX5TRF.X5_FILIAL = '"+xFilial("SX5")+"' AND SX5TRF.D_E_L_E_T_ = ' ' AND SX5TRF.X5_TABELA = 'L2' AND SX5TRF.X5_CHAVE = Z06_TAREFA "
	cQuery += " WHERE  Z05_FILIAL = '"+xFilial("Z05")+"' AND  Z05.D_E_L_E_T_ = ' '   AND Z06_STATUS != 'FI'  AND Z06_STATUS IN ('EX','AG','PL','IN') "
	cQuery += " and Z06_NUMOS+Z06_SEQOS not in (SELECT Z18_NUMOS+Z18_SEQOS NUMSEQOS "
	cQuery += " 								FROM "+RetSQLName("Z18")+" Z18 (NOLOCK) "
	cQuery += " 									INNER JOIN "+RetSQLName("Z06")+" Z06 (NOLOCK) "
	cQuery += " 									ON Z06.D_E_L_E_T_ = '' "
	cQuery += " 									AND Z06_FILIAL = Z18_FILIAL "
	cQuery += " 									AND Z06_NUMOS = Z18_NUMOS "
	cQuery += " 									AND Z06_SEQOS = Z18_SEQOS "
	cQuery += " 									AND Z06_STATUS NOT IN ( 'FI', 'BL', 'CA' ) "
	cQuery += " 								WHERE  Z18.D_E_L_E_T_ = '' "
	cQuery += " 								AND Z18_FILIAL = '"+xFilial("Z18")+"' "
	cQuery += " 								AND Z18_OPERAD = '"+cUsuario+"' "
	cQuery += " 								AND Z18.D_E_L_E_T_ = '' "
	cQuery += " 								AND Z18_STATUS <> 'B' "
	cQuery += " 								group by Z18_NUMOS+Z18_SEQOS) "
	cQuery += " ORDER BY Z06_PRIOR, Z05_NUMOS "

	TCQuery cQuery NEW ALIAS "tQRYOS"

	DBSelectArea("tQRYOS")
	tQRYOS->(DBGoTop())

	if !tQRYOS->(EOF())
		While !tQRYOS->(EOF())

			Aadd(aOpenOS,{tQRYOS->Z05_NUMOS,tQRYOS->Z06_SEQOS,tQRYOS->DSC_OPER,tQRYOS->PG_CARGA,tQRYOS->A1_NREDUZ,;
			tQRYOS->Z06_PRIOR,tQRYOS->Z06_ENDSRV,tQRYOS->DSC_SERVIC,tQRYOS->DSC_TAREFA,tQRYOS->Z06_SERVIC,tQRYOS->Z06_TAREFA,""})

			tQRYOS->(DBSkip())
		EndDo
	Else
		Aadd(aOpenOS,{"","","","","","","","","","","",""})
	EndIf

	DlgVOS	:= MSDialog():new(1,1,350,750,'Atribuir OS ao usuário '+AllTrim(cUsuario)+" - "+AllTrim(cNome),,,,,CLR_BLACK,CLR_WHITE,,,.t.)

	oBrwOSUser := TCBrowse():New(017,002,373,157,,,,DlgVOS,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	oBrwOSUser:AddColumn(TCColumn():New("Num OS"	, {|| aOpenOS[oBrwOSUser:nAt,01]},,,,, 020,.F.,.F.,,,,.F., ) )
	oBrwOSUser:AddColumn(TCColumn():New("Seq OS"	, {|| aOpenOS[oBrwOSUser:nAt,02]},,,,, 010,.F.,.F.,,,,.F., ) )
	oBrwOSUser:AddColumn(TCColumn():New("Op."		, {|| aOpenOS[oBrwOSUser:nAt,03]},,,,, 020,.F.,.F.,,,,.F., ) )
	oBrwOSUser:AddColumn(TCColumn():New("PG/Crg"	, {|| aOpenOS[oBrwOSUser:nAt,04]},,,,, 020,.F.,.F.,,,,.F., ) )
	oBrwOSUser:AddColumn(TCColumn():New("Cliente"	, {|| aOpenOS[oBrwOSUser:nAt,05]},,,,, 040,.F.,.F.,,,,.F., ) )
	oBrwOSUser:AddColumn(TCColumn():New("Pri"		, {|| aOpenOS[oBrwOSUser:nAt,06]},,,,, 020,.F.,.F.,,,,.F., ) )
	oBrwOSUser:AddColumn(TCColumn():New("End Srv"	, {|| aOpenOS[oBrwOSUser:nAt,07]},,,,, 020,.F.,.F.,,,,.F., ) )
	oBrwOSUser:AddColumn(TCColumn():New("Serviço"	, {|| aOpenOS[oBrwOSUser:nAt,08]},,,,, 030,.F.,.F.,,,,.F., ) )
	oBrwOSUser:AddColumn(TCColumn():New("Tarefa"	, {|| aOpenOS[oBrwOSUser:nAt,09]},,,,, 030,.F.,.F.,,,,.F., ) )
	oBrwOSUser:AddColumn(TCColumn():New("Srv"		, {|| aOpenOS[oBrwOSUser:nAt,10]},,,,, 030,.F.,.F.,,,,.F., ) )
	oBrwOSUser:AddColumn(TCColumn():New("Trf"		, {|| aOpenOS[oBrwOSUser:nAt,11]},,,,, 030,.F.,.F.,,,,.F., ) )
	oBrwOSUser:SetArray(aOpenOS)
	oBrwOSUser:Refresh()

	oBtn1 := TBtnBmp2():New( 02,02,26,26,'CHECKOK',,,,{|| GrvOsUsr(aOpenOS[oBrwOSUser:nAt,01],aOpenOS[oBrwOSUser:nAt,02],cUsuario,cNome), DlgVOS:End() },DlgVOS,,,.T. )
	oBtn2 := TBtnBmp2():New( 02,715,26,26,'FINAL',,,,{|| DlgVOS:End() },DlgVOS,,,.T. )

	oBtn1:cToolTip	:= "Confirmar"
	oBtn2:cToolTip	:= "Sair"

	DlgVOS:Activate()

Return
//-------------------------------------------------------------------------------------------------
Static Function GrvOsUsr(cNumOS,cSeqOS,cUsuario,cNome)

	If MsgYesNo("Confirma atribuição da OS "+cNumOS+" seq. "+cSeqOS+" ao usuário "+cUsuario+"?")
		dbSelectArea("Z18")
		RecLock("Z18",.T.)
		Z18->Z18_FILIAL	:= xFilial("Z18")
		Z18->Z18_NUMOS  := cNumOS
		Z18->Z18_SEQOS  := cSeqOS
		Z18->Z18_STATUS := "R" // P=Planejado / R=Realizado / B=Bloqueado
		Z18->Z18_USUARI := __cUserID
		Z18->Z18_OPERAD := cUsuario
		Z18->Z18_CATEG  := "O"
		Z18->(MsUnLock())

		AtuGridUsr(cUsuario)
		GetOSUser(cUsuario,cNome)
		oOSUser:SetArray(aUsrOS)
		oOSUser:Refresh()

		// insere o log
		U_FtGeraLog(xFilial(), "Z18", xFilial("Z18") + cNumOS + cSeqOS, "Definido Operador " + __cUserID, "WMS", "")
	EndIf

Return