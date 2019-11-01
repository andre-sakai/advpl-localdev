#include "totvs.ch"
#Include "colors.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Sistema WMS Tecadi:                                     !
!                  ! - Tela de Login                                         !
!                  ! - Menu principal com as opcoes disponiveis por usuario  !
!                  ! - Funcao ACDA002A para convocao de servicos por usuario !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 09/2012 !
+------------------+--------------------------------------------------------*/

User Function TACDA002()
	// tabelas
	local _aTables := {"Z11","DCD"}
	// controle da conexao
	local _lConOk := .F.

	Local aUser    := {}
	Local dGetData := MsDate()

	// resolucao da tela
	Private _aSizeDlg := GetScreenRes()

	// define se o uso eh pelo WSM Tecadi / ACD
	Private _lWmsIsACD := .T.

	// fontes utilizadas
	Private _oFnt00 := TFont():New("MS Sans Serif",,12)
	Private _oFnt01 := TFont():New("Tahoma",,18,,.T.)
	Private _oFnt02 := TFont():New("Verdana",,14,,.F.)
	Private _oFnt03 := TFont():New("Verdana",,22,,.T.)
	Private _oFnt04 := TFont():New("Courier New",,16,,.F.)
	Private _oFnt05 := TFont():New("Verdana",,16,,.T.)

	Private oShortList
	Private __cInterNet := Nil
	Private nModulo := 99
	Private cModulo := ""
	Private cVersao := GetVersao()
	Private tInicio := TIME()
	Private lMsHelpAuto := .T.

	// janela principal
	PUBLIC oMainWnd

	// redimensiona medidas da resolucao de tela
	If (_aSizeDlg[1] > 400)
		_aSizeDlg[1] := 240
		_aSizeDlg[2] := 320
	Else
		_aSizeDlg[1] -= 8
		_aSizeDlg[2] -= 26
	EndIf

	// cria o objeto principal
	MsApp():New('SIGAWMS',.T.)
	oApp:CreateEnv()
	oApp:cInternet := NIL
	oApp:lIsBlind := .T.

	// chama tela de login
	If ( ! sfAcdLogin(@dGetData, @aUser) )
		// mensagem de aviso
		Final("Login não autorizado!")
		// retorno
		Return(.F.)
	EndIf

	// define mensagem no monitor
	U_FtMsgMon()

	// abertura do cadastro de empresas/filiais
	dbSelectArea("SM0")
	DbSetOrder(1)
	DbSeek( cEmpAnt + cFilAnt)

	// abertura de tela de menus
	sfAcdWindow()

Return

// ** tela de login
Static Function sfAcdLogin(dGetData, aUser)
	Local lRet := .F.
	Local oData
	Local oUsuario
	Local cUsuario	:= Space(15)
	Local opassw
	Local cpassw	:= Space(20)
	Local oEmp
	Local cEmp		:= Space(20)
	Local aEmp		:= {""}
	Local oBmp
	Local _oMainPanel
	Local oDlg

	// monta a janela principal
	_oWndLogin := MSDialog():New(000,000,180,220,'WMS Tecadi - v3.0.1',,,.F.,,,,,,.T.,,,.T. )

	// cria o painel principal
	@00,00 MSPANEL _oMainPanel SIZE 120,25 of _oWndLogin
	_oMainPanel:Align := CONTROL_ALIGN_ALLCLIENT

	// linha ao redor da logo
	@ 002,002 TO 026,109 OF _oMainPanel PIXEL
	// logo da empresa
	_oBmpLogoWMS := TBitmap():New(006,030,100,100,"WMS_LOGO",,.T.,_oMainPanel,nil,,.F.,.F.,,,.F.,,.T.,,.F.)

	@ 26 , 06 Say "Usuario" PIXEL of _oMainPanel
	@ 34 , 06 MSGET oUsuario	VAR cUsuario	SIZE 55,09 Valid (sfVldNome(@cUsuario)) .And. (ValNome(cUsuario)) PIXEL of _oMainPanel

	@ 26 , 64 Say "Senha:" PIXEL of _oMainPanel
	@ 34 , 64 MSGET opassw		VAR cpassw		SIZE 40,09 PASSWORD VALID sfVldUser(@cUsuario, @cPassw, _oWndLogin, @aUser, oEmp) PIXEL of _oMainPanel

	@ 46 , 06 Say "Empresa/Filial" PIXEL of _oMainPanel
	@ 54 , 06 MSCOMBOBOX oEmp VAR cEmp ITEMS aEmp SIZE 100,09 PIXEL of _oMainPanel


	DEFINE SBUTTON FROM 074,050 TYPE 1 ACTION (lRet := AbreArq(oEmp, cUsuario, cPassw, @aUser),_oWndLogin:End()) ENABLE OF _oWndLogin PIXEL	WHEN ! Empty(cEmp)
	DEFINE SBUTTON FROM 074,080 TYPE 2 ACTION (_oWndLogin:End()) ENABLE OF _oWndLogin PIXEL

	ACTIVATE MSDIALOG _oWndLogin Centered

Return lRet

// ** funcao para abertura de tabelas
Static Function AbreArq(oEmp, cUsuario, cPassw, aUser)
	local _aTmpEmp := Separa(oEmp:aItems[oEmp:nAt],"-")
	local _aTmpCodEmp := Separa(AllTrim(_aTmpEmp[1]),"/")
	Local _cNumEmp := AllTrim(_aTmpCodEmp[1])
	Local _cCodFil := AllTrim(_aTmpCodEmp[2])

	// controle de processamento
	local _lRet := .F.

	// processa abertura de tabelas
	Processa({|| _lRet := AbreTabelas(_cNumEmp, _cCodFil, cUsuario, cPassw, @aUser)},,"Abrindo tabelas")

Return(_lRet)

// ** funcao para abertura de tabelas do sistema
Static Function AbreTabelas(mvCodEmp, mvCodFil, cUsuario, cPassw, aUser)

	// padroniza tamanho de variaveis
	mvCodEmp := PadR(mvCodEmp, Len(SM0->M0_CODIGO))
	mvCodFil := PadR(mvCodFil, Len(SM0->M0_CODFIL))

	// abertura do cadastro de empresas/filiais
	dbSelectArea("SM0")
	DbSetOrder(1)
	DbSeek( mvCodEmp + mvCodFil)

	// prepara o ambiente para o usuario + empresa + filial selecionada
	RpcSetEnv(mvCodEmp, mvCodFil, cUsuario, cPassw, 'WMS',, )

	// seta valores padroes do sistema (funcao TOTVS)
	SetsDefault()

	// define mensagem no monitor
	U_FtMsgMon("TACDA002")
	__cInternet := NIL

	// atualiza quantidade de acessos disponiveis por usuario
	__NUSERACS := aUser[1][15]

	// valida a quantidade de acessos
	If ( ! NUSERACS() )
		// mensagem
		MsgAlert("Limite de conexões do Usuário excedido", "Limite de Conexões")
		// retorno
		Return(.F.)
	EndIf

Return(.T.)

// ** funcao para validar usuario e senha
Static Function sfVldUser(cUsuario, cPassw, _oWndLogin, aUser, oEmp)

	Local _lRet := .T.
	Local aAux := {}
	Local oUser   := MPUserAccount():New()
	Local nRetorno:= 0
	Local nEmpArr := 1

	// grupo do usuario
	local _aUsrGrupo := {}
	local _lVldGrupo := .F.

	// conteudo vazio
	If (Empty(cPassw))
		Return(.T.)
	EndIf

	// Inicializa a classe de autenticação de usuário
	oUser:Activate()
	// Verifica se a autenticação pelo SO é válida
	nRetorno := oUser:SignOnAuthentication(.T.)
	If (nRetorno == 0)
		nRetorno :=  oUser:Authentication(cUsuario, cPassw)
		If (nRetorno == 0)
			// mensagem
			MsgAlert("Usuario nao autorizado", "Autorização")
			// variavel de controle
			_lRet := .F.
		EndIf
	EndIf

	// valida acessos
	If (_lRet)
		// define ordem de pesquisa
		PswOrder(1)
		// pesquisa pelo codigo do usuario
		If (PswSeek(oUser:cUserId, .T.))
			__Ap5NoMv(.T.)
			aUser := PswRet()
			__Ap5NoMv(.F.)
			cUsuario := aUser[1,2]

			// extrai grupo do usuario
			_aUsrGrupo := aUser[1][10]

			// se autenticou, valida acesso de grupo 000000-Admin ou 000011-Wms Coletores
			_lVldGrupo := (aScan(_aUsrGrupo, "000000") != 0) .OR. (aScan(_aUsrGrupo, "000011") != 0 )

			// se nao validou grupo, nao permite login
			If ( ! _lVldGrupo )
				// mensagem
				MsgAlert("Usuário não autorizado para utilização de coletores", "Autorização")
				// variavel de controle
				_lRet := .F.
			EndIf

			/*
			If (_lRet) .AND. ((AllTrim(GetComputerName()) != '103VRDS02') .AND. (Ascan(_aUsrGrupo,"000000") == 0))
			// mensagem
			MsgAlert("As rotinas WMS só são permitidas através do coletor de dados!", "Autorização")
			// variavel de controle
			_lRet := .F.
			Endif
			*/

			// dados auxiliares
			If (_lRet)
				aAux:= aClone(aEmpresa(Aclone(aUser[2][6])))
				// descarta outras empresas que não são tecadi armazens (01)
				While (nEmpArr != 0)
					nEmpArr := aScanX(aAux, { |x| Substr(x,1,2) != "01" })
					IIf(nEmpArr != 0, Adel(aAux,nEmpArr), Nil)
					IIf(nEmpArr != 0, ASize(aAux, Len(aAux) - 1), Nil)
				EndDo

				oEmp:SetItems(aClone(aAux))
				oEmp:Refresh()
			EndIf
		EndIf
	EndIf

	If ( ! _lRet )
		cPassw := Space(Len(cpassw))
	EndIf

Return(_lRet)

// ** funcao que valida o nome ou codigo digitado
Static Function sfVldNome(mvUsuario)
	// variavel de retorno
	local _lRet := .F.
	// informacoes do usuario
	local _aTmpDados := {}

	// pesquisa pelo codigo do usuario (1 - ID do usuário/grupo / 2 - Nome do usuário/grupo)
	If ( ! _lRet )
		// ordena pesquisa
		PswOrder(1)
		// pesquisa pelo codigo do usuario
		If (PswSeek(mvUsuario, .T.))
			// retorna as informacoes do usuario
			_aTmpDados := PswRet()
			// atualiza nome do usuario (login)
			mvUsuario := _aTmpDados[1][2]
			// variavel de retorno
			_lRet := .T.
		EndIf
	EndIf

	// pesquisa pelo login do usuario (1 - ID do usuário/grupo / 2 - Nome do usuário/grupo)
	If ( ! _lRet )
		// ordena pesquisa
		PswOrder(2)
		// pesquisa pelo codigo do usuario
		If (PswSeek(mvUsuario, .T.))
			// retorna as informacoes do usuario
			_aTmpDados := PswRet()
			// atualiza nome do usuario (login)
			mvUsuario := _aTmpDados[1][2]
			// variavel de retorno
			_lRet := .T.
		EndIf
	EndIf

	// erro na validacao do usuario
	If ( ! _lRet )
		MsgAlert("Usuário não encontrado", "Autorização")
	EndIf

Return(_lRet)

// ** funcao que retorna as empresas/filiais disponiveis por usuario
Static Function aEmpresa(aEmprx)
	Local aChoice := {}

	OpenSM0()
	DbSelectArea("SM0")
	DbGoTop()
	FWCODFIL()
	//Monta o Arvore de Empresas
	If Empty(aEmprx)
		Final("Usuario nao autorizado")
	EndIf

	If aEmprx[1] == [@@@@]
		aEmprx := {}
		DbEval({|| Aadd(aEmprx, SM0->M0_CODIGO + FWCODFIL() )})
	Endif

	If Empty(aEmprx)
		Final("Arquivo Empresa Corrompido") //
	EndIf

	DbGoTop()
	While !Eof()
		If Ascan(aEmprx, SM0->M0_CODIGO + FWCODFIL()) <> 0
			Aadd(aChoice, SM0->M0_CODIGO + '/' + FWCODFIL() + '-' + Trim(Upper(SM0->M0_NOME)) + ' / ' + Trim(Upper(SM0->M0_FILIAL)))
		EndIf
		DbSkip()
	EndDo

Return aClone(aChoice)

// ** abertura de tela com as opcoes do coletors
Static Function sfAcdWindow()
	// controle de apresentacao dos botoes disponiveis
	local _nBtnLin    := 5
	local _nBtnColIni := 5
	local _nBtnColAtu := _nBtnColIni
	local _nBtnCol    := 0
	local _nBtnColMax := 3
	local _nBtnLarg   := 33
	local _nBtnSepara := 2
	local _nBtnAltu   := 30

	// define array com as opcoes disponiveis
	local _vBtnDisp := {}
	local _nBtnDisp

	// variaveis temporarias
	local _cTmpObjBtn
	local _cTmpFuncao
	local _cTmpImagem
	local _cTmpTexto

	// funcao que monta os dados do operador logado no sistema
	Private _aUsrInfo := U_FtWmsOpe()

	// codigo do operador
	Private _lUsrAccou  := (_aUsrInfo[2]=="A")
	Private _lUsrColet	:= (_aUsrInfo[2]=="C")
	Private _lUsrSuper	:= (_aUsrInfo[2]=="S")
	Private _lUsrLider	:= (_aUsrInfo[2]=="L")
	Private _lUsrGeren  := (_aUsrInfo[2]=="G")
	Private _lUsrMonit  := (_aUsrInfo[2]=="M")
	Private _cCodOper   := IIf(_lUsrColet, Space(6), __cUserId)
	Private _cNomOper   := Space(30) // nome do operador

	// codigo do equipamento
	Private _cCodEquip  := Space(6)
	Private _cTipEquip	:= Space(3)

	// define os botoes disponíveis para operacao
	// -- ORDENS DE SERVIÇO
	aAdd(_vBtnDisp,{"CLOCK01" , "Ord.Serv."  , "U_ACDA002A()   "})
	// -- CONSULTA DE ETIQUETA
	aAdd(_vBtnDisp,{"ACDIMG32", "Cons.Etiq." , "U_TWMSA015()   "})
	// -- FINALIZAR
	aAdd(_vBtnDisp,{"FINAL","Sair","IIf(U_FTYesNoMsg('Deseja Sair?','ATENÇÃO'), oMainWnd:End(), Nil)"})

	// monta a janela principal
	oMainWnd := TWindow():New(000,000,_aSizeDlg[2],_aSizeDlg[1],'WMS Tecadi - v3.0.1',,,,,,,,,,,,,,,,.T. )

	// scroll principal com todos as opcoes disponiveis
	_oScrWndMain := TScrollBox():New(oMainWnd,000,000,_aSizeDlg[2],_aSizeDlg[1],.T.,.T.,.T.)
	_oScrWndMain:Align := CONTROL_ALIGN_ALLCLIENT


	// inclui todos os botoes disponiveis
	For _nBtnDisp := 1 to Len(_vBtnDisp)
		// cria o objeto botao
		_cTmpObjBtn := "_oBtnWnd"+StrZero(_nBtnDisp,2)
		// define a funcao do botao
		_cTmpFuncao := _vBtnDisp[_nBtnDisp][3] + ", U_FtMsgMon('TACDA002')"
		// define a imagem do botao
		_cTmpImagem := _vBtnDisp[_nBtnDisp][1]
		// define o texto do botao
		_cTmpTexto  := CRLF+CRLF+_vBtnDisp[_nBtnDisp][2]
		// controle de coluna
		_nBtnCol    += 1

		// cria objetos
		&(_cTmpObjBtn) := TButton():New(_nBtnLin,_nBtnColAtu,_cTmpTexto,_oScrWndMain,&("{|| "+_cTmpFuncao+" }"),_nBtnLarg,_nBtnAltu,,,.F.,.T.,.F.,,.F.,,,.F. )

		// O CSS abaixo irá inserir uma imagem posicionada à esquerda/superior do botão,
		&(_cTmpObjBtn):SetCss("QPushButton{ background-image: url(rpo:"+_cTmpImagem+".png);"+;
		" background-repeat: none; margin: 2px;"+;
		" background-position: center top; "+;
		" background-color: #CCCCCC; "+;
		" text-align: justify; }")

		// controle da coluna
		_nBtnColAtu += (_nBtnLarg + _nBtnSepara)

		// gera nova linha
		If (_nBtnCol == _nBtnColMax)
			// reinicia o controle de coluna
			_nBtnColAtu := _nBtnColIni
			// incrementa o controle da linha
			_nBtnLin += (_nBtnAltu + _nBtnSepara)
			// zera variavel
			_nBtnCol := 0
		EndIf

	Next _nBtnDisp

	// -- OPCOES DISPONIVEIS

	oMainWnd:SetColor(CLR_BLACK,CLR_WHITE)
	oMainWnd:Cargo := oShortList
	oMainWnd:oFont := _oFnt00
	oMainWnd:lEscClose := .F.
	oMainWnd:ReadClientCoors()

	// cria barra de status
	_oWndMsgBar := TMsgBar():New(oMainWnd,Nil,.F.,.F.,.F.,.F.,RGB(116,116,116),,,.F.)
	_oWndMsgBar:Align := CONTROL_ALIGN_BOTTOM
	_oWndMsgBar:SetMsg("WMS | Empresa: "+AllTrim(cEmpAnt)+" Filial: "+AllTrim(cFilAnt))
	// cria itens da barra de status
	_oWndMsgIt1 := TMsgItem():New(_oWndMsgBar, dDataBase, 60,,CLR_BLACK,,.T.,{||})

	// habilita a janela maximizada
	oMainWnd:Activate('MAXIMIZED')

Return( .T. )


// ** funcao para chamada da rotina de convocacao
User Function ACDA002A()

	// pastas do FOLDER
	local _aFolders := {"&Resumo","&Operação"}

	// objetos
	local _oBmpTrcEquip, _oBmpInicOp
	local _oPnlConvCab
	local _oFldrConv
	local _oScrBtnOp

	// controle de apresentacao dos botoes disponiveis
	local _nBtnLin    := 5
	local _nBtnColIni := 5
	local _nBtnColAtu := _nBtnColIni
	local _nBtnCol    := 0
	local _nBtnColMax := 3
	local _nBtnLarg   := 33
	local _nBtnSepara := 2
	local _nBtnAltu   := 30

	// define array com as opcoes disponiveis
	local _vBtnDisp := {}
	local _nBtnDisp

	// variaveis temporarias
	local _cTmpObjBtn
	local _cTmpFuncao
	local _cTmpImagem
	local _cTmpTexto

	// query para convocacao
	local _cQuery

	// funções WMS do usuário
	local _lOperEmp  := .F.
	local _lInventar := .F.
	local _lConferen := .F.
	local _lOperPal  := .F.
	local _lServGer  := .F.
	local _aFuncoes  := {}

	// controle de processamento da barra de progresso
	Private _nMeter := 0

	// controle de execucao do select de convocacao
	Private _lConvoc := .T.

	// resumo de OS por operador
	Private _aResumoOS := {{0,0,0,0,0,0,0,0}}

	// itens pendentes/selecionados a processar
	Private _aItensOrdSrv := {}

	// timer para atualizacao dos dados
	private _oTimerConv

	// valida se o usuario logado no sistema esta cadastrado como operador do WMS
	If ( ! _aUsrInfo[1])
		Return(.F.)
	EndIf

	// filtro padrao para os servicos
	Private cQryFilZ06 := ""
	// condicao para filtrar somente que o operador é recurso
	Private cQryUsrZ18 := ""
	// enderecos disponiveis para operacao por tipo de equipamento utilizado
	Private _cQryEndEq := ""

	// varivel com a qtd de dias padrão para mostrar OS finalizadas
	private _nDiasPad := IIF(DoW(Date()) == 2, 9, 7)
	// variavel data para validação da finalização das OS
	private _dDtFinOS := (Date() - _nDiasPad)

	// define mensagem no monitor
	U_FtMsgMon()

	// zera variaveis
	_cCodOper   := If(_lUsrColet,Space(6),__cUserId)
	_cNomOper   := Space(30) // nome do operador
	// codigo do equipamento
	_cCodEquip  := Space(6)
	_cTipEquip	:= Space(3)


	// valida se o usuario podera executar este servico (atualiza a variavel cCodOper)
	If ( ! U_FtUsrWms() )
		Return .F.
	EndIf

	// verifica funções WMS que o operador pode executar
	_aFuncoes := U_FTWmsFun(_cCodOper)

	_lOperEmp  := AScan(_aFuncoes, "WMS04") != 0
	_lInventar := AScan(_aFuncoes, "WMS01") != 0
	_lConferen := AScan(_aFuncoes, "WMS02") != 0
	_lOperPal  := AScan(_aFuncoes, "WMS03") != 0
	_lServGer  := AScan(_aFuncoes, "WMS05") != 0

	// define os botoes disponíveis para operacao

	// é operador de paleteira ou empilhadeira
	If (_lOperEmp) .OR. (_lOperPal)
		// -- MOV. PALETE
		aAdd(_vBtnDisp,{"AVGARMAZEM","Mov.Palete" ,"_lConvoc := .T., U_TWMSA011(_cQuery)"     })
		// -- APANHE LIVRE (T09)
		//	aAdd(_vBtnDisp,{"SDUPROP"   ,"Ap. Livre" ,"_lConvoc := .T., U_TWMSA043(_cQuery)"     })
		// -- MOV. LIVRE DE PALETE
		aAdd(_vBtnDisp,{"S4WB014B", "Mov.Livre", "_lConvoc := .T., U_TWMSA033(_cQuery)"})
	EndIf
	// é conferente
	If (_lConferen)
		// -- CONF. RECEBIMENTO
		aAdd(_vBtnDisp,{"PCOIMG32"  ,"Conf.Receb.","_lConvoc := .T., U_TWMSA010(_cQuery, .F.)"})
		// -- CONF. EXPEDICAO
		aAdd(_vBtnDisp,{"QIPIMG32"  ,"Conf.Exped.","_lConvoc := .T., U_TWMSA012(_cQuery)"     })
		// -- CONF. CARREGAMENTO
		aAdd(_vBtnDisp,{"CONTAINR"  ,"Conf.Carreg.","_lConvoc := .T., U_TWMSA020(_cQuery)"    })
		// -- MONTAGEM DE VOLUMES
		aAdd(_vBtnDisp,{"FRTIMG32"  ,"Mont.Volumes","_lConvoc := .T., U_TWMSA024(_cQuery)"})
		// -- DIVISAO DE ESTOQUE/PALETE (retrabalho)
		aAdd(_vBtnDisp,{"ESTIMG32"  ,"Div.Estoque","_lConvoc := .T., U_TWMSA029(_cQuery)"})
		// -- IMPRESSAO DE ETIQUETAS
		aAdd(_vBtnDisp,{"RELATORIO", "Etiquetas", "_lConvoc := .T., sfEtiq()"})
		// -- ARMAZENAMENTO EXPRESSO
		aAdd(_vBtnDisp,{"DBG06", "Arm. Expres", "_lConvoc := .T., Processa({ || U_WMSA051A(_cQuery) },'Processando...',,.T.)"})
	EndIf
	// é inventarista
	If (_lInventar)
		// -- INVENTÁRIO
		aAdd(_vBtnDisp,{"PENDENTE"  ,"Inventário"  ,"U_TWMSA014(_cQuery, .F.)"                })
	EndIf
	// -- DEFINIR RECURSOS DA ORDEM DE SERVICO 
	If (_lUsrGeren) .or. (_lUsrSuper) .OR. ( _lUsrLider )
		aAdd(_vBtnDisp,{"CLIENTE"  ,"Operadores","_lConvoc := .T., U_ACDA002D(_cQuery, Nil)"})
	EndIf
	// -- DEFINE DOCA PARA EXPEDIÇÃO
	If (_lUsrGeren) .or. (_lUsrSuper) .OR. ( _lUsrLider )
		aAdd(_vBtnDisp,{"carga"  ,"Def.Doca","_lConvoc := .T., sfDefDoca(_cQuery)"})
	EndIf
	// -- GERACAO DE MAPA DE ARMAZENAGEM DE OS FINALIZADA
	If (_lUsrGeren) .or. (_lUsrSuper) .OR. ( _lUsrLider )
		aAdd(_vBtnDisp,{"PMSIMG32"  ,"Mapa Armaz.","_lConvoc := .T., U_TWMSA010(_cQuery, .T.)"})
	EndIf
	// -- GERACAO DE OS DE SERVICO DE VALOR AGREGADO
	If (_lUsrGeren)
		aAdd(_vBtnDisp,{"NCO"  ,"OS SVA","U_TWMSA052(_cQuery, .T.)"})
	EndIf

	// -- SELEÇÃO DE PALLETS
	//	aAdd(_vBtnDisp,{"NCO"  ,"Sel.Pallets","_lConvoc := .T., U_TWMSA031(_cQuery)"})
	// -- SELEÇÃO DE PALLETS
	//	aAdd(_vBtnDisp,{"SDUGOTO"  ,"Estufagem","_lConvoc := .T., U_TWMSA032(_cQuery)"})

	// monta a query principal que busca as movimentacoes
	_cQuery := sfMontaQuery()

	// monta o dialogo
	_oWndUsrConv := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"WMS - " + AllTrim(cUserName),,,.F.,,,,,oMainWnd,.T.,,,.T. )
	_oWndUsrConv:lEscClose := .F.

	// painel com as opcoes disponiveis
	_oPnlConvCab := TPanel():New(000,000,nil,_oWndUsrConv,,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlConvCab:Align:= CONTROL_ALIGN_TOP

	// -- botao acionar operacoes
	_oBmpInicOp := TBtnBmp2():New(000,000,040,040,"PLAY",,,,{|| _oFldrConv:SetOption(2) },_oPnlConvCab,"Operação",,.T. )
	_oBmpInicOp:Align := CONTROL_ALIGN_LEFT

	// -- botao troca de equipamento
	_oBmpTrcEquip := TBtnBmp2():New(000,000,040,040,"EMPILHADEIRA",,,,{|| _lConvoc := .T., sfTrocaEquip(@_cQuery) },_oPnlConvCab,"Troca de Equipamento",,.T. )
	_oBmpTrcEquip:Align := CONTROL_ALIGN_LEFT

	// -- botao Sair
	_oBmpConvSair := TBtnBmp2():New(000,000,040,040,"FINAL",,,,{|| IIf(U_FtYesNoMsg("Deseja Sair?", "ATENÇÃO"),_oWndUsrConv:End(),Nil) },_oPnlConvCab,"Sair",,.T. )
	_oBmpConvSair:Align := CONTROL_ALIGN_RIGHT

	// pastas (folders) com as opcoes de visualizacao
	_oFldrConv := TFolder():New(000,000,_aFolders,,_oWndUsrConv,,,,.T.,,100,200)
	_oFldrConv:Align:= CONTROL_ALIGN_ALLCLIENT

	// 1a PASTA - RESUMO

	// -- OS Pendentes
	_oSayOSPend := TSay():New(005,005,{|| "Pendente:"     + CRLF + " -> " + AllTrim(Str(_aResumoOS[1,1])) },_oFldrConv:aDialogs[1],,_oFnt02,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_HRED  ,033,020,,,,,,.T.)
	_oSayOSPend:blClicked := {|| _lConvoc := .T., U_ACDA002C(_cQuery,"AG",.T.,.T.,.F.,.F.) }
	// -- OS Selecionadas
	_oSayOSSele := TSay():New(005,041,{|| "Operação:"     + CRLF + " -> " + AllTrim(Str(_aResumoOS[1,2])) },_oFldrConv:aDialogs[1],,_oFnt02,.F.,.F.,.F.,.T.,CLR_WHITE,CLR_HBLUE ,033,020,,,,,,.T.)
	_oSayOSSele:blClicked := {|| _lConvoc := .T., U_ACDA002C(_cQuery,"EX",.F.,.T.,.T.,.F.) }
	// -- OS Interrompidas
	_oSayOSInte := TSay():New(005,077,{|| "Interromp:"    + CRLF + " -> " + AllTrim(Str(_aResumoOS[1,3])) },_oFldrConv:aDialogs[1],,_oFnt02,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_YELLOW,033,020,,,,,,.T.)
	_oSayOSInte:blClicked := {|| _lConvoc := .T., U_ACDA002C(_cQuery,"IN",.T.,.T.,.F.,.F.) }
	// -- OS Em Analise
	_oSayOSEmAn := TSay():New(028,005,{|| "Análise:"      + CRLF + " -> " + AllTrim(Str(_aResumoOS[1,4])) },_oFldrConv:aDialogs[1],,_oFnt02,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_HGRAY ,033,020,,,,,,.T.)
	_oSayOSEmAn:blClicked := {|| _lConvoc := .T., U_ACDA002C(_cQuery,"AN",.F.,.F.,.F.,.T.) }
	// -- OS bloqueadas
	_oSayOSBloq := TSay():New(028,041,{|| "Bloqueada:"    + CRLF + " -> " + AllTrim(Str(_aResumoOS[1,5])) },_oFldrConv:aDialogs[1],,_oFnt02,.F.,.F.,.F.,.T.,CLR_WHITE,CLR_BLACK ,033,020,,,,,,.T.)
	_oSayOSBloq:blClicked := {|| _lConvoc := .T., U_ACDA002C(_cQuery,"BL",.T.,.T.,.F.,.F.) }
	// -- OS finalizada
	_oSayOSFina := TSay():New(028,077,{|| "Finalizada:"   + CRLF + " -> " + AllTrim(Str(_aResumoOS[1,6])) },_oFldrConv:aDialogs[1],,_oFnt02,.F.,.F.,.F.,.T.,CLR_WHITE,CLR_GREEN ,033,020,,,,,,.T.)
	_oSayOSFina:blClicked := {|| _lConvoc := .T., U_ACDA002C(_cQuery,"FI",.F.,.F.,.F.,.T.) }
	// -- OS planejada
	_oSayOSPlan := TSay():New(051,005,{|| "Planejada:"    + CRLF + " -> " + AllTrim(Str(_aResumoOS[1,7])) },_oFldrConv:aDialogs[1],,_oFnt02,.F.,.F.,.F.,.T.,CLR_WHITE,CLR_CYAN  ,033,020,,,,,,.T.)
	_oSayOSPlan:blClicked := {|| _lConvoc := .T., U_ACDA002C(_cQuery,"PL",.F.,.F.,.F.,.T.) }
	// -- OS cancelada
	_oSayOSCanc := TSay():New(051,041,{|| "Cancelada:"    + CRLF + " -> " + AllTrim(Str(_aResumoOS[1,8])) },_oFldrConv:aDialogs[1],,_oFnt02,.F.,.F.,.F.,.T.,CLR_WHITE,CLR_BROWN ,033,020,,,,,,.T.)
	_oSayOSCanc:blClicked := {|| _lConvoc := .T., U_ACDA002C(_cQuery,"CA",.F.,.F.,.F.,.T.) }

	// temporizador/Refresh da tela
	_oTimerConv := TTimer():New(1000,{|| sfExecServ(_cQuery) },_oWndUsrConv)
	_oTimerConv:lActive := .T.

	// barra de processamento para convocacao
	_oMtrConv := TMeter():New(096,005,{|u|if(Pcount()>0,_nMeter:=u,_nMeter)},0,_oFldrConv:aDialogs[1],104,16,,.T.,,,.F.)
	_oMtrConv:SetTotal(15)


	// 2a PASTA - OPERACAO

	// scroll principal com todos as opcoes disponiveis na aba OPERACOES
	_oScrBtnOp := TScrollBox():New(_oFldrConv:aDialogs[2],000,000,_aSizeDlg[2],_aSizeDlg[1],.T.,.T.,.T.)
	_oScrBtnOp:Align := CONTROL_ALIGN_ALLCLIENT


	// inclui todos os botoes disponiveis
	For _nBtnDisp := 1 to Len(_vBtnDisp)
		// cria o objeto botao
		_cTmpObjBtn := "_oBtnWnd" + StrZero(_nBtnDisp,2)

		// define parametro para PARAR timer
		_cTmpFuncao := "_oTimerConv:lActive := .f., "
		// define a funcao do botao
		_cTmpFuncao += _vBtnDisp[_nBtnDisp][3] + ", "
		// define funcao para atualizar mensagem no monitor
		_cTmpFuncao += "U_FtMsgMon('ACDA002A'), "
		// define parametro para REATIVAR timer
		_cTmpFuncao += "_oTimerConv:lActive := .T. "

		// define a imagem do botao
		_cTmpImagem := _vBtnDisp[_nBtnDisp][1]
		// define o texto do botao
		_cTmpTexto  := CRLF + CRLF + _vBtnDisp[_nBtnDisp][2]
		// controle de coluna
		_nBtnCol    += 1

		// cria objetos
		&(_cTmpObjBtn) := TButton():New(_nBtnLin,_nBtnColAtu,_cTmpTexto,_oScrBtnOp,&("{|| "+_cTmpFuncao+" }"),_nBtnLarg,_nBtnAltu,,,.F.,.T.,.F.,,.F.,,,.F. )

		// O CSS abaixo irá inserir uma imagem posicionada à esquerda/superior do botão,
		&(_cTmpObjBtn):SetCss("QPushButton{ background-image: url(rpo:"+_cTmpImagem+".png);"+;
		" background-repeat: none; margin: 2px;"+;
		" background-position: center top; "+;
		" background-color: #CCCCCC; "+;
		" text-align: justify; }")

		// controle da coluna
		_nBtnColAtu += (_nBtnLarg + _nBtnSepara)

		// gera nova linha
		If (_nBtnCol == _nBtnColMax)
			// reinicia o controle de coluna
			_nBtnColAtu := _nBtnColIni
			// incrementa o controle da linha
			_nBtnLin += (_nBtnAltu + _nBtnSepara)
			// zera variavel
			_nBtnCol := 0
		EndIf

	Next _nBtnDisp

	// ativa a tela
	ACTIVATE MSDIALOG _oWndUsrConv

Return

// ** funcao para controle de atualizacao de dados da tela de convocacao
Static Function sfExecServ(mvQuery)
	// verifica necessidade de convocacao
	If (_lConvoc)
		// zera contador
		_nMeter := 0
		// executa o select de convocacao
		_aItensOrdSrv := sfConvocacao(mvQuery)
	EndIf

	// contador
	_nMeter ++
	// atualiza variavel
	_oMtrConv:Set(_nMeter)

	// nova convocacao
	_lConvoc := (_nMeter == 15)

Return(.T.)

// ** funcao que executa a convocacao dos servicos disponiveis para o operador
Static Function sfConvocacao(mvQuery)
	// retorno de servicos
	local _aRetSrv := {}

	// atualiza o resumo de OS por operador
	_aResumoOS := sfAtuResumo(mvQuery)

	// atualiza variaveis
	_oSayOSPend:Refresh()
	_oSayOSSele:Refresh()
	_oSayOSInte:Refresh()
	_oSayOSEmAn:Refresh()
	_oSayOSBloq:Refresh()
	_oSayOSFina:Refresh()
	_oSayOSPlan:Refresh()
	_oSayOSCanc:Refresh()

	// inclui o filtro somente das OSs selecionadas para o usuario logado
	mvQuery += "AND Z06_STATUS = 'EX' "
	// filtra se o operador eh recurso da OS
	If ( ! Empty(cQryUsrZ18))
		mvQuery += "AND "+cQryUsrZ18
	EndIf

	// complementa a ordem dos dados
	mvQuery += "ORDER BY Z06_PRIOR, Z05_NUMOS"

	memowrit("c:\query\tacda002_sfConvocacao.txt", mvQuery)

	// executa o select e atualiza a variavel de retorno
	_aRetSrv := U_SqlToVet(mvQuery)

Return(_aRetSrv)

// ** funcao para apresentar as ordens de servicos de acordo com o status
User Function ACDA002C(mvQuery, mvStatus, mvConfTela, mvExecSrv, mvInterSrv, mvFiltraSrv)
	// gera novo alias
	local cAliasNew := GetNextAlias()
	// variavel de retorno
	local _lRet := .T.

	// objetos da tela
	local _oWndSrvPend
	local _oPnlPendCab
	local _oBmpPendInter, _oBmpPendConf, _oBmpConvSair, _oBrwOSPend

	// definicao do novo status
	local _cNewStatus := "EX"

	// relacao de ordens de servicos pendentes
	local _aColsPend := {}
	local _aHeadPend := {}

	// query para buscar os dados
	local _cQryOS := mvQuery

	// centraliza tela
	local _lDlgCenter := (Type("_aSizeDlg")=="U")
	// largura da tela
	local _nDlgLarg := If(Type("_aSizeDlg")=="U",340,(_aSizeDlg[1]))
	// altura da tela
	local _nDlgAltu := If(Type("_aSizeDlg")=="U",240,(_aSizeDlg[2]))

	// parametro padrao
	Default mvFiltraSrv := .F.

	// define header do browse
	aAdd(_aHeadPend,{"Num OS"   ,"Z05_NUMOS" , "", TamSx3("Z05_NUMOS")[1] ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadPend,{"Seq OS"   ,"Z06_SEQOS" , "", TamSx3("Z06_SEQOS")[1] ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadPend,{"Op."      ,"DSC_OPER"  , "", 3                      ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadPend,{"PG/Crg"   ,"PG_CARGA"  , "", TamSx3("C5_NUM")[1]    ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadPend,{"Cliente"  ,"A1_NREDUZ" , "", TamSx3("A1_NREDUZ")[1] ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadPend,{"Pri"      ,"Z06_PRIOR" , "", TamSx3("Z06_PRIOR")[1] ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadPend,{"End Srv"  ,"Z06_ENDSRV", "", TamSx3("Z06_ENDSRV")[1],0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadPend,{"Serviço"  ,"DSC_SERVIC", "", 40                     ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadPend,{"Tarefa"   ,"DSC_TAREFA", "", 40                     ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadPend,{"Srv"      ,"Z06_SERVIC", "", TamSx3("Z06_SERVIC")[1],0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadPend,{"Trf"      ,"Z06_TAREFA", "", TamSx3("Z06_TAREFA")[1],0,Nil,Nil,"C",Nil,"R" })

	// verifica se o alias esta aberto
	If (Select(cAliasNew) <> 0)
		dbSelectArea(cAliasNew)
		dbCloseArea()
	EndIf

	// status da OS
	If (mvExecSrv) .or. (mvFiltraSrv)
		_cQryOS += " AND Z06_STATUS IN "+FormatIn(mvStatus,";")
	EndIf

	// na consulta do resumo de OS finalizada, incluir filtro de data
	If ("FI" $ mvStatus) .and. ( ! mvConfTela )
		_cQryOS += " AND (Z06_STATUS = 'FI' AND Z06_DTFIM >= '"+DtoS(_dDtFinOS)+"') "
	EndIf

	// filtro do usuario
	If ( ! Empty(cQryFilZ06) )
		_cQryOS += " AND " + cQryFilZ06
	EndIf

	// se não for um dos tipos especiais abaixo, então filtra servicos somente do operador logado
	If ( ( ! _lUsrGeren ) .and. ( ! _lUsrSuper ) .and. ( ! _lUsrLider ) ) .and. ( ! Empty(cQryUsrZ18) )
		_cQryOS += " AND " + cQryUsrZ18
	EndIf

	// se não for um dos tipos especiais abaixo, filtra servico de acordo com o equipamento
	If ( ( ! _lUsrGeren ) .and. ( ! _lUsrSuper ) .AND. ( ! _lUsrLider ) )
		// filtra servicos / tarefas
		_cQryOS += " AND Z06_SERVIC + Z06_TAREFA IN ( "
		// sub-query
		_cQryOS += "     SELECT DC5_SERVIC + DC5_TAREFA "
		// cad. servico x tarefa
		_cQryOS += "       FROM " + RetSqlTab("DC5")
		// cad. tarefa x atividade
		_cQryOS += "      INNER JOIN "+RetSqlTab("DC6")+" ON "+RetSqlCond("DC6")+" AND DC6_TAREFA = DC5_TAREFA "
		// filtro tipo de equipamento (999-Sem / Diferente de 999-Com equipamento)
		_cQryOS += "      AND DC6_TPREC "+ IIf(Empty(_cCodEquip)," = "," != ")+" '999' "
		// filtro padrao
		_cQryOS += "      WHERE "+RetSqlCond("DC5")+" ) "
	EndIf

	// complementa a ordem dos dados
	_cQryOS += " ORDER BY Z06_PRIOR, Z05_NUMOS"

	memowrit("c:\query\tacda002_U_ACDA002C.txt",_cQryOS)

	// executa o select
	DbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQryOS),cAliasNew,.F.,.T.)
	(cAliasNew)->(DbGoTop())

	// alimenta vetor das OSs pendentes
	While (cAliasNew)->( ! Eof() )

		// atualiza os itens do browse
		aAdd(_aColsPend,{ (cAliasNew)->Z05_NUMOS,;
		(cAliasNew)->Z06_SEQOS,;
		(cAliasNew)->DSC_OPER,;
		(cAliasNew)->PG_CARGA,;
		(cAliasNew)->A1_NREDUZ,;
		(cAliasNew)->Z06_PRIOR,;
		(cAliasNew)->Z06_ENDSRV,;
		(cAliasNew)->DSC_SERVIC,;
		(cAliasNew)->DSC_TAREFA,;
		(cAliasNew)->Z06_SERVIC,;
		(cAliasNew)->Z06_TAREFA,;
		.F.	 })

		// proximo item
		(cAliasNew)->(dbSkip())
	EndDo

	// verifica se ha pendencias
	If (Len(_aColsPend) == 0)
		// mensagem
		U_FtWmsMsg("Não há ordens de serviço disponíveis para esta operação.","Atenção!")
		// retorno
		Return
	EndIf

	// monta o dialogo
	_oWndSrvPend := MSDialog():New(000,000,_nDlgAltu,_nDlgLarg,"WMS - Ord. Serviço",,,.F.,,,,,oMainWnd,.T.,,,.T. )

	// -- painel com as opcoes disponiveis
	_oPnlPendCab := TPanel():New(000,000,nil,_oWndSrvPend,,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlPendCab:Align:= CONTROL_ALIGN_TOP

	// se for OS selecionadas, solicita interrupcao
	If (mvConfTela) .and. (mvInterSrv)
		// -- INTERROMPER
		_oBmpPendInter := TBtnBmp2():New(000,000,030,030,"STOP",,,,{|| (_lRet := Len(_aColsPend) > 0), _oWndSrvPend:End() },_oPnlPendCab,"Interromper",,.T.)
		_oBmpPendInter:Align := CONTROL_ALIGN_LEFT

	EndIf

	// confirma a execucao de servicos
	If (mvConfTela)
		// -- CONFIRMACAO
		// somente o supervisor/lider pode desbloquear OS
		If (mvStatus != "BL") .or. ( (mvStatus == "BL") .and. (_lUsrSuper .or. _lUsrGeren .OR. _lUsrLider) )
			_oBmpPendConf := TBtnBmp2():New(000,000,030,030,"OK",,,,{|| (_lRet := Len(_aColsPend) > 0), _oWndSrvPend:End() },_oPnlPendCab,"Ok",,.T.)
			_oBmpPendConf:Align := CONTROL_ALIGN_LEFT
		EndIf
	EndIf

	// -- BOTAO SAIR
	_oBmpConvSair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _lRet := .F., _oWndSrvPend:End() },_oPnlPendCab,"Sair",,.T.)
	_oBmpConvSair:Align := CONTROL_ALIGN_RIGHT

	// browse com a listagem dos servicos
	_oBrwOSPend := MsNewGetDados():New(000,000,600,600,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsPend),'AllwaysTrue()','','AllwaysTrue()',_oWndSrvPend,_aHeadPend,_aColsPend)
	_oBrwOSPend:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwOSPend:oBrowse:blDblClick := {|| IIf((mvConfTela) .And. ( ! mvInterSrv ), _oBmpPendConf:Click(), Nil)  }

	// ativa a tela
	ACTIVATE MSDIALOG _oWndSrvPend

	// executa a OS
	If (_lRet) .and. (Len(_aColsPend) > 0) .and. (_oBrwOSPend:nAt > 0)

		// posiciona na OS
		dbSelectArea("Z05")
		Z05->(dbSetOrder(1)) // 1-Z05_FILIAL, Z05_NUMOS
		Z05->(dbSeek( xFilial("Z05") + _oBrwOSPend:aCols[_oBrwOSPend:nAt][1] ))

		// posiciona no item da OS
		dbSelectArea("Z06")
		Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
		Z06->(dbSeek( xFilial("Z06") + _oBrwOSPend:aCols[_oBrwOSPend:nAt][1] + _oBrwOSPend:aCols[_oBrwOSPend:nAt][2] ))

		// caso tenha CESV, posiciona
		If ( ! Empty(Z05->Z05_CESV) )
			// atualiza o STATUS
			dbSelectArea("SZZ")
			SZZ->(dbSetOrder(1)) // 1-ZZ_FILIAL, ZZ_CESV
			SZZ->(dbSeek( xFilial("SZZ")+Z05->Z05_CESV ))
		EndIf

		// chama funcao padrao para detalhes da OS
		_lRet := U_ACDA002B(Z06->Z06_NUMOS, Z06->Z06_SEQOS, .T.)

		// se a tela foi confirmada
		If (_lRet)
			// se for OS selecionadas, solicita interrupcao
			If (mvInterSrv)
				// muda o novo status para IN-INTERROMPIDA
				_cNewStatus := "IN"
				// funcao generica para interromper atividade
				U_FtWmsMtInt(Z06->Z06_NUMOS, Z06->Z06_SEQOS)
			EndIf

			// altera status da OS
			If (mvExecSrv) .and. (Z06->Z06_STATUS != _cNewStatus)

				// funcao generica de alteracao do status da ordem de servico
				U_FtWmsSta(Z06->Z06_STATUS,;
				_cNewStatus,;
				Z06->Z06_NUMOS,;
				Z06->Z06_SEQOS)

				// posiciona sobre o CESV e coloca em operação
				If ( mvStatus == "AG" ) .AND. ( !Empty(Z05->Z05_CESV) )
					// atualiza o STATUS
					dbSelectArea("SZZ")
					SZZ->(dbSetOrder(1)) // 1-ZZ_FILIAL, ZZ_CESV
					SZZ->(dbSeek( xFilial("SZZ")+Z05->Z05_CESV ))
					//se doca já definida, coloca em operação
					If ( !Empty(SZZ->ZZ_DOCA) )
						RecLock("SZZ")
						SZZ->ZZ_STATUS := "07" // 07-EM OPERACAO
						SZZ->(MsUnLock())
					Else
						MsgAlert("CESV " + Z05->Z05_CESV + " não está com doca definida e por isso, não foi liberado. " + CRLF + "Comunique ao account ou supervisor.")
					EndIF
				EndIf

			EndIf

		EndIf
	EndIf

Return(_lRet)

// ** funcao que atualiza o resumo por operador
Static Function sfAtuResumo(_cQuery)
	// 1-OS pendentes
	// 2-OS seleciondas
	// 3-OS Interrompida
	// 4-OS Em Analise
	// 5-OS Bloqueada
	// 6-OS Finalizada
	// 7-OS Planejada
	// 8-OS Cancelada
	local _aRet := {{0,0,0,0,0,0,0,0}}
	// query
	local _cQryRes := ""

	_cQryRes := "SELECT "
	// status
	_cQryRes += "SUM(CASE WHEN Z06_STATUS = 'AG' THEN 1 ELSE 0 END) 'AG', "
	_cQryRes += "SUM(CASE WHEN Z06_STATUS = 'EX' THEN 1 ELSE 0 END) 'EX', "
	_cQryRes += "SUM(CASE WHEN Z06_STATUS = 'IN' THEN 1 ELSE 0 END) 'IN', "
	_cQryRes += "SUM(CASE WHEN Z06_STATUS = 'AN' THEN 1 ELSE 0 END) 'AN', "
	_cQryRes += "SUM(CASE WHEN Z06_STATUS = 'BL' THEN 1 ELSE 0 END) 'BL', "
	_cQryRes += "SUM(CASE WHEN Z06_STATUS = 'FI' AND Z06_DTFIM >= '"+DtoS(_dDtFinOS)+"' THEN 1 ELSE 0 END) 'FI', "
	_cQryRes += "SUM(CASE WHEN Z06_STATUS = 'PL' THEN 1 ELSE 0 END) 'PL', "
	_cQryRes += "SUM(CASE WHEN Z06_STATUS = 'CA' AND Z06_DTFIM >= '"+DtoS(_dDtFinOS)+"' THEN 1 ELSE 0 END) 'CA' "
	// itens da OS
	_cQryRes += "FROM " + RetSqlTab("Z06") + " (NOLOCK) "
	// filtro padrao
	_cQryRes += "WHERE "

	// filta status de OS ja encerrada
	_cQryRes += " ( "
	_cQryRes += "   (Z06_STATUS NOT IN ('FI')) "
	_cQryRes += "   OR "
	_cQryRes += "   (Z06_STATUS IN ('FI') AND Z06_DTFIM >= '"+DtoS(_dDtFinOS)+"') "
	_cQryRes += " ) "

	_cQryRes += " AND "

	_cQryRes += " ( "
	_cQryRes += "   (Z06_STATUS NOT IN ('CA')) "
	_cQryRes += "   OR "
	_cQryRes += "   (Z06_STATUS IN ('CA') AND Z06_DTFIM >= '"+DtoS(_dDtFinOS)+"') "
	_cQryRes += " ) "

	// filtro de status
	If ( ( ! _lUsrGeren ) .and. ( ! _lUsrSuper ) .AND. ( ! _lUsrLider ) )
		_cQryRes += " AND ( "
		_cQryRes += "     (Z06_STATUS = 'AG') "
		_cQryRes += "     OR "
		_cQryRes += "     (Z06_STATUS NOT IN ('AG','PL') AND "+cQryUsrZ18+") "
		_cQryRes += "     ) "
	EndIf

	// filtro do usuario
	_cQryRes += " AND " + cQryFilZ06

	// filtra servicos somente do operador
	If ( ( ! _lUsrGeren ) .and. ( ! _lUsrSuper ) .AND. ( ! _lUsrLider ) )
		_cQryRes += "AND " + cQryUsrZ18 + " "
	EndIf

	// filtra servico de acordo com o equipamento
	If ( ( ! _lUsrGeren ) .and. ( ! _lUsrSuper ) .AND. ( ! _lUsrLider ) )
		// filtra servicos / tarefas
		_cQryRes += " AND Z06_SERVIC + Z06_TAREFA IN ( "
		// sub-query
		_cQryRes += "     SELECT DC5_SERVIC + DC5_TAREFA "
		// cad. servico x tarefa
		_cQryRes += "       FROM "+RetSqlTab("DC5")+" (NOLOCK) "
		// cad. tarefa x atividade
		_cQryRes += "      INNER JOIN "+RetSqlTab("DC6")+" (NOLOCK) ON "+RetSqlCond("DC6")+" AND DC6_TAREFA = DC5_TAREFA "
		// filtro tipo de equipamento (999-Sem / Diferente de 999-Com equipamento)
		_cQryRes += "      AND DC6_TPREC "+ IIf(Empty(_cCodEquip)," = "," != ")+" '999' "
		// filtro padrao
		_cQryRes += "      WHERE "+RetSqlCond("DC5")+" ) "
	EndIf

	memowrit("c:\query\tacda002_sfAtuResumo.txt",_cQryRes)

	// atualiza vetor de retorno
	_aRet := U_SqlToVet(_cQryRes)

Return(_aRet)


// ** funcao para troca de equipamento
Static Function sfTrocaEquip(mvQuery)

	// chama funcao generica para atualizar variaveis
	If ( ! U_FtUsrWms())
		Return .F.
	EndIf

	// atualiza a query principal, com as novas definicoes do usuario
	mvQuery := sfMontaQuery()

Return(.T.)

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
	If ( ! Empty(cQryFilZ06) )
		_cRetQry += " AND " + cQryFilZ06
	EndIf

	// cad. de servicos
	_cRetQry += "INNER JOIN "+RetSqlName("SX5")+" SX5SRV (NOLOCK) ON SX5SRV.X5_FILIAL = '"+xFilial("SX5")+"' AND SX5SRV.D_E_L_E_T_ = ' ' AND SX5SRV.X5_TABELA = 'L4' AND SX5SRV.X5_CHAVE = Z06_SERVIC "
	// cad. de tarefas
	_cRetQry += "INNER JOIN "+RetSqlName("SX5")+" SX5TRF (NOLOCK) ON SX5TRF.X5_FILIAL = '"+xFilial("SX5")+"' AND SX5TRF.D_E_L_E_T_ = ' ' AND SX5TRF.X5_TABELA = 'L2' AND SX5TRF.X5_CHAVE = Z06_TAREFA "

	// filtro da movimentacoes
	_cRetQry += "WHERE "+RetSqlCond("Z05")+" "

	memowrit("c:\query\tacda002_montaquery.txt", _cRetQry)

Return(_cRetQry)

// ** funcao generica que apresenta os detalhes da OS
User Function ACDA002B(mvNumOS,mvSeqOS,mvWndConf)
	// posicao inicial das tabelas
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z05","Z06","SZZ"})

	// browse com os detalhes da OS
	local _aColsDetOS := {}
	local _aHeadDetOS := {}

	// objetos do dialogo
	local _oWnd02InSrv
	local _oPnl02InCab
	local _oBmp02InOk, _oBmp02InSair
	local _oBrw02DetIni

	// variavel de retorno
	local _lRet := .F.

	// titulo
	local _cWndTitulo := IIf(mvWndConf, "WMS - Confirmação", "WMS - Cons. Detalhe")

	// centraliza tela
	local _lDlgCenter := (Type("_aSizeDlg")=="U")
	// largura da tela
	local _nDlgLarg := IIf(Type("_aSizeDlg")=="U", 240,(_aSizeDlg[1]))
	// altura da tela
	local _nDlgAltu := IIf(Type("_aSizeDlg")=="U", 320,(_aSizeDlg[2]))

	// define o header do browse
	aAdd(_aHeadDetOS,{"Titulo"   ,"IT_TITULO", "",  10,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadDetOS,{"Descrição","IT_DESCRI", "", 100,0,Nil,Nil,"C",Nil,"R" })

	// posiciona na OS
	dbSelectArea("Z05")
	Z05->(dbSetOrder(1)) // 1-Z05_FILIAL, Z05_NUMOS
	Z05->(dbSeek( xFilial("Z05")+mvNumOS ))

	// posiciona no item da OS
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	Z06->(dbSeek( xFilial("Z06")+mvNumOS+mvSeqOS ))

	// posiciona no movimentacao de entrada/saida do veiculo
	dbSelectArea("SZZ")
	SZZ->(dbSetOrder(1)) // 1-ZZ_FILIAL, ZZ_CESV
	SZZ->(dbSeek( xFilial("SZZ")+Z05->Z05_CESV ))

	// inclui informacoes
	aAdd(_aColsDetOS,{"Nr O.S."    ,Z05->Z05_NUMOS+" / "+Z06->Z06_SEQOS,.F.})
	aAdd(_aColsDetOS,{"Dt.Emissão" ,DtoC(Z05->Z05_DTEMIS)+" "+Z05->Z05_HREMIS,.F.})
	aAdd(_aColsDetOS,{"Serviço"    ,Z06->Z06_SERVIC+" - "+AllTrim(Tabela("L4",Z06->Z06_SERVIC)),.F.})
	aAdd(_aColsDetOS,{"Tarefa"     ,Z06->Z06_TAREFA+" - "+AllTrim(Tabela("L2",Z06->Z06_TAREFA)),.F.})
	aAdd(_aColsDetOS,{"Cliente"    ,Z05->Z05_CLIENT+" / "+Z05->Z05_LOJA+" - "+AllTrim(Posicione("SA1",1, xFilial("SA1")+Z05->(Z05_CLIENT+Z05_LOJA) ,"A1_NOME")),.F.})
	aAdd(_aColsDetOS,{"Operação"   ,If(Z05->Z05_TPOPER=="E","RECEBIMENTO",If(Z05->Z05_TPOPER=="S","EXPEDIÇÃO","INTERNA")),.F.})
	If (Z05->Z05_TPOPER=="E") .AND. (Z06->Z06_SERVIC  == "003")  //Operação de entrada e serviço de recebimento normal
		aAdd(_aColsDetOS,{"Programação",Z05->Z05_PROCES,.F.})
		aAdd(_aColsDetOS,{"Container"  ,Transf(SZZ->ZZ_CNTR01,PesqPict("SZC","ZC_CODIGO"))+If(Empty(SZZ->ZZ_CNTR02),""," / "+Transf(SZZ->ZZ_CNTR02,PesqPict("SZC","ZC_CODIGO"))),.F.})
		aAdd(_aColsDetOS,{"Placa"      ,Transf(SZZ->ZZ_PLACA1,PesqPict("DA3","DA3_COD")),.F.})
	ElseIf (Z05->Z05_TPOPER=="S")
		//aAdd(_aColsDetOS,{"Pedido",Z05->Z05_PEDIDO,.F.})
		aAdd(_aColsDetOS,{"Carga"         , Z05->Z05_CARGA , .F.})
		aAdd(_aColsDetOS,{"Onda Separação", Z05->Z05_ONDSEP, .F.})
	Elseif (Z05->Z05_TPOPER=="E") .AND. (Z06->Z06_SERVIC  == "T03")  //Operação de entrada e serviço de recebimento por cancelamento de carregamento
		aAdd(_aColsDetOS,{"OS original",SubStr(SZZ->ZZ_OBS,40,6),.F.})
		aAdd(_aColsDetOS,{"Pedido org.",SubStr(SZZ->ZZ_OBS,64,6),.F.})
	EndIf

	// definicao do status
	If (Z06->Z06_STATUS=="AG")
		aAdd(_aColsDetOS,{"Status","AGUARDANDO",.F.})
	ElseIf (Z06->Z06_STATUS=="IN")
		aAdd(_aColsDetOS,{"Status","INTERROMPIDA",.F.})
	ElseIf (Z06->Z06_STATUS=="BL")
		aAdd(_aColsDetOS,{"Status","BLOQUEADA",.F.})
	ElseIf (Z06->Z06_STATUS=="EX")
		aAdd(_aColsDetOS,{"Status","EM EXECUCAO",.F.})
	ElseIf (Z06->Z06_STATUS=="FI")
		aAdd(_aColsDetOS,{"Status","FINALIZADA",.F.})
	ElseIf (Z06->Z06_STATUS=="AN")
		aAdd(_aColsDetOS,{"Status","EM ANÁLISE",.F.})
	ElseIf (Z06->Z06_STATUS=="PL")
		aAdd(_aColsDetOS,{"Status","PLANEJADA",.F.})
	Else
		aAdd(_aColsDetOS,{"Status","** ERRO STATUS **",.F.})
	EndIf

	// endereco do servico
	aAdd(_aColsDetOS,{"Armazém" , Z06->Z06_LOCAL                                                   , .F.})
	aAdd(_aColsDetOS,{"Endereço", IIf(AllTrim(Z06->Z06_ENDSRV)=="ZZZ", "DIVERSOS", Z06->Z06_ENDSRV), .F.})

	// CESV
	If (Z05->Z05_TPOPER != "I")
		aAdd(_aColsDetOS,{"Nr. CESV", Z05->Z05_CESV, .F.})
	EndIf

	// se for OS de inventario, incluiu a contagem
	If (Z06->Z06_SERVIC == "T02")
		aAdd(_aColsDetOS,{"Contagem", Z06->Z06_NRCONT, .F.})
	EndIF

	// monta o dialogo
	_oWnd02InSrv := MSDialog():New(000,000,_nDlgAltu,_nDlgLarg,_cWndTitulo,,,.F.,,,,,,.T.,,,.T. )

	// -- painel com as opcoes disponiveis
	_oPnl02InCab := TPanel():New(000,000,nil,_oWnd02InSrv,,.F.,.F.,,,22,22,.T.,.F. )
	_oPnl02InCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	If (mvWndConf)
		_oBmp02InOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRet := .T., _oWnd02InSrv:End() },_oPnl02InCab,"Ok",,.T.)
		_oBmp02InOk:Align := CONTROL_ALIGN_LEFT
	EndIf

	// -- botao Sair
	_oBmp02InSair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _oWnd02InSrv:End() },_oPnl02InCab,"Sair",,.T.)
	_oBmp02InSair:Align := CONTROL_ALIGN_RIGHT

	// browse com a listagem dos servicos
	_oBrw02DetIni := MsNewGetDados():New(000,000,600,600,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDetOS),'AllwaysTrue()','','AllwaysTrue()',_oWnd02InSrv,_aHeadDetOS,_aColsDetOS)
	_oBrw02DetIni:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrw02DetIni:oBrowse:oFont := _oFnt02
	_oBrw02DetIni:oBrowse:blDblClick := {|| IIf((mvWndConf), _oBmp02InOk:Click(), Nil)  }

	// ativa a tela
	ACTIVATE MSDIALOG _oWnd02InSrv

	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aArea)

Return(_lRet)

// ** funcao para definicao de recursos adicionais da OS
User Function ACDA002D(mvQryUsr, mvNumOs)
	// variavel de retorno
	local _lRet := .F.
	// objetos locais
	local _oWndDefRec
	local _oPnlDefRecCab, _oPnlBrwDisp, _oPnlBrwSelec
	local _oBmpDefRecSair, _oBmpAdd, _oBmpRemove, _oBmpRecent
	local _oBrwRecDisp, _oBrwRecSelec

	// define o header do browse de recursos disponiveis
	local _aHeadRecurso := {}
	local _aColsDisp := {}
	local _aColsSele := {}

	// centraliza tela
	local _lDlgCenter := (Type("_aSizeDlg")=="U")
	// largura da tela
	local _nDlgLarg := If(Type("_aSizeDlg")=="U",240,(_aSizeDlg[1]))
	// altura da tela
	local _nDlgAltu := If(Type("_aSizeDlg")=="U",320,(_aSizeDlg[2]))

	// valor padrao
	Default mvNumOs := CriaVar("Z05_NUMOS", .F.)

	// remove as OS finalizadas
	mvQryUsr += " AND Z06_STATUS != 'FI' "

	// se foi informado a OS, complementa o filtro
	If ( ! Empty(mvNumOs) )
		mvQryUsr += " AND Z06_NUMOS = '" + mvNumOs + "' "
	EndIf

	// chama tela com a relacao de servicos
	If ( _lRet := U_ACDA002C(mvQryUsr, "EX;AG;PL;IN", .T., .F., .F., .T.) )

		// atualiza os dados de acordo com a OS selecionada
		_aColsDisp := sfRetRecHum()
		_aColsSele := sfRetRecSel()

		// define o header
		aAdd(_aHeadRecurso,{"Nome"  ,"IT_NOME"  ,"" ,30,0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadRecurso,{"Código","IT_COD"   ,"" , 6,0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadRecurso,{"Status","IT_STATUS","" , 4,0,Nil,Nil,"C",Nil,"R",,,".F." })

		// apresenta tela para definir o endereco atual/origem
		_oWndDefRec := MSDialog():New(000,000,_nDlgAltu,_nDlgLarg,"Define Operadores",,,.F.,,,,,,.T.,,,.T. )
		_oWndDefRec:lEscClose := .F.

		// cria o panel do cabecalho - botoes de operacao
		_oPnlDefRecCab := TPanel():New(000,000,nil,_oWndDefRec,,.F.,.F.,,,22,22,.T.,.F.)
		_oPnlDefRecCab:Align:= CONTROL_ALIGN_TOP

		// -- ADICIONAR RECURSO
		_oBmpAdd := TBtnBmp2():New(000,000,050,050,"WMS_IMG_001",,,,{|| sfAddUser(@_oBrwRecDisp, @_oBrwRecSelec, "+")  },_oPnlDefRecCab,"Incluir",,.T.)
		_oBmpAdd:Align := CONTROL_ALIGN_LEFT

		// -- REMOVER RECURSO
		_oBmpRemove := TBtnBmp2():New(000,000,050,050,"WMS_IMG_002",,,,{|| sfAddUser(@_oBrwRecDisp, @_oBrwRecSelec, "-") },_oPnlDefRecCab,"Bloquear",,.T.)
		_oBmpRemove:Align := CONTROL_ALIGN_LEFT

		// -- ATRIBUI RECURSOS RECENTES
		_oBmpRecent := TBtnBmp2():New(000,000,050,050,"WMS_IMG_003",,,,{|| sfAddUser(@_oBrwRecDisp, @_oBrwRecSelec, "*") },_oPnlDefRecCab,"Recentes",,.T.)
		_oBmpRecent:Align := CONTROL_ALIGN_LEFT

		// -- FECHAR
		_oBmpDefRecSair := TBtnBmp2():New(000,000,050,050,"FINAL",,,,{|| _lRet := .T., _oWndDefRec:End()  },_oPnlDefRecCab,"Sair",,.T.)
		_oBmpDefRecSair:Align := CONTROL_ALIGN_RIGHT

		// cria o panel para o browse
		_oPnlBrwDisp := TPanel():New(000,000,nil,_oWndDefRec,,.F.,.F.,,,70,70,.T.,.F.)
		_oPnlBrwDisp:Align:= CONTROL_ALIGN_TOP

		// browse com a listagem dos recursos disponiveis
		_oBrwRecDisp := MsNewGetDados():New(000,000,400,400,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDisp),'AllwaysTrue()','','AllwaysTrue()',_oPnlBrwDisp,_aHeadRecurso,_aColsDisp)
		_oBrwRecDisp:oBrowse:oFont := _oFnt04
		_oBrwRecDisp:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// browse com a listagem dos recursos selecionados
		_oPnlBrwSelec := TPanel():New(000,000,nil,_oWndDefRec,,.F.,.F.,,CLR_LIGHTGRAY,060,060,.T.,.F.)
		_oPnlBrwSelec:Align:= CONTROL_ALIGN_TOP

		// browse com a listagem dos recursos selecionados
		_oBrwRecSelec := MsNewGetDados():New(000,000,400,400,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsSele),'AllwaysTrue()','','AllwaysTrue()',_oPnlBrwSelec,_aHeadRecurso,_aColsSele)
		_oBrwRecSelec:oBrowse:oFont := _oFnt04
		_oBrwRecSelec:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// ativa a tela
		_oWndDefRec:Activate(,,,(_lDlgCenter),,,)

	EndIf

Return(_lRet)

// ** funcao que retorna os recursos humanos disponiveis
Static Function sfRetRecHum()
	local _aRet := {}
	local _cQryDCD
	LOCAL cFunc := ""

	DBSelectArea("DC6")
	DC6->(DBSetOrder(2))  // 2 - DC6_FILIAL, DC6_TAREFA, DC6_ATIVID, R_E_C_N_O_, D_E_L_E_T_                                                                                                                                 
	If DC6->(MSSeek(xFilial("DC6") + Z06->Z06_TAREFA))
		Do While !DC6->(Eof()) .And. (xFilial("DC6") + Z06->Z06_TAREFA) == DC6->(DC6_FILIAL + DC6_TAREFA)  
			If Z06->Z06_TAREFA == DC6->DC6_TAREFA 
				cFunc := FormatIn(AllTrim(DC6->DC6_FUNCAO),",") 
			EndIf
			DC6->(DBSkip())
		EndDo
	EndIf

	If Empty(cFunc)
		U_FtWmsMsg("Tarefa sem cadastro.","Atenção!")
		Return
	EndIf

	_cQryDCD := " SELECT DISTINCT DCD_NOMFUN, DCD_CODFUN, 'DISP' IT_STATUS, '.F.' IT_DEL "
	// cad. recursos humanos
	_cQryDCD += " FROM "+RetSQLName("DCD")+" DCD "
	// filtro padrao
	_cQryDCD += " WHERE "+RetSqlCond("DCD")
	// status
	_cQryDCD += " AND DCD_STATUS = '1' "
	// bloqueio
	_cQryDCD += " AND DCD_MSBLQL <> '1' "
	// somente da(s) filial(is) que estejam cadastradas para o usuário
	_cQryDCD += " AND DCD_ZFLDIS  LIKE '%" + cFilAnt + "%' "

	// Relaciona o Recurso com a função para filtrar pelas funções, mas também permitir que 
	//cargos G,S e L, sejam relatados mesmo tendo funções diferentes. 11/06/2019 Luiz Fernando
	_cQryDCD += " AND ("
	_cQryDCD += " DCD_ZCATEG IN ('G','S','L') "//G=Gerente;A=Account;S=Supervisor;O=Operador;C=Coletor;M=Monitor;L=Lider
	_cQryDCD +=  " 	OR (SELECT COUNT(1) AS QUANTIDADE FROM "+RetSQLName("DCI")+" DCI " 
	_cQryDCD +=  " 	WHERE "
	_cQryDCD +=  " 	DCI_FILIAL = DCD_FILIAL  "
	_cQryDCD +=  " 	AND DCI_CODFUN = DCD_CODFUN "
	_cQryDCD +=  " 	AND DCI_FUNCAO IN "+cFunc
	_cQryDCD +=  " 	AND DCI.D_E_L_E_T_ != '*' ) >0"
	_cQryDCD += " ) "

	// descarta usuarios ja relacionados
	_cQryDCD += " AND DCD_CODFUN NOT IN (SELECT Z18_OPERAD FROM "+RetSqlTab("Z18")
	_cQryDCD += "                        WHERE "+RetSqlCond("Z18")+" "
	_cQryDCD += "                          AND Z18_NUMOS = '" + Z06->Z06_NUMOS + "' AND Z18_SEQOS = '" + Z06->Z06_SEQOS + "' "
	_cQryDCD += "                          AND Z18_CATEG IN ('G','S','L','O') ) "
	_cQryDCD += " AND DCD.D_E_L_E_T_ = '' "

	// ordem dos dados
	_cQryDCD += " ORDER BY DCD_NOMFUN "

	memowrit("c:\query\tacda002_sfRetRecHum.txt", _cQryDCD)

	// alimenta a variavel de retorno
	_aRet := U_SqlToVet(_cQryDCD)

Return(_aRet)

// ** funcao que retorna os recursos humanos selecionados
Static Function sfRetRecSel()
	local _aRet := {}
	local _cQryDCD

	_cQryDCD := "SELECT DCD_NOMFUN, DCD_CODFUN, CASE WHEN Z18_STATUS = 'B' THEN 'BLOQ' ELSE 'OPER' END Z18_STATUS, '.F.' IT_DEL "
	// recursos da OS
	_cQryDCD += "FROM "+RetSqlTab("Z18")
	// cad. de recursos
	_cQryDCD += "INNER JOIN "+RetSqlTab("DCD")+" ON "+RetSqlCond("DCD")+" AND DCD_CODFUN = Z18_OPERAD "
	// filtro padrao
	_cQryDCD += "WHERE "+RetSqlCond("Z18")+" "
	_cQryDCD += "  AND Z18_NUMOS = '"+Z06->Z06_NUMOS+"' AND Z18_SEQOS = '"+Z06->Z06_SEQOS+"' "
	// ordem dos dados
	_cQryDCD += "ORDER BY DCD_NOMFUN "

	memowrit("c:\query\tacda002_sfRetRecSel.txt", _cQryDCD)

	// alimenta a variavel de retorno
	_aRet := U_SqlToVet(_cQryDCD)

Return(_aRet)

// ** funcao para atualizar os recursos da OS
Static Function sfAddUser(mvBrwDisp, mvBrwSele, mvOper)
	// variaveis do browse
	local _aTmpDisp := {}
	local _aTmpSele := {}
	// seek do Z18
	local _cSeekZ18
	// query de analise do usuário já incluido
	local _cQuery := ""
	// variavel que vai receber o recno para gravar os dados
	local _nRecnoZ18 := 0

	// variaveis para uso na Static Function sfAddRecurso
	// OBS: por limitacao tecnica, foi necessario declarar variaveis locais para usar como parametros
	local _cIxbCodSrv
	local _cIxbCodTrf
	local _cIxbSeqOs
	local _cIxbCodCli
	local _cIxbLojCli
	local _cIxbTpOper

	// adicionar usuario
	If (mvOper == "+")

		// verifica se tem registros no browse de recursos ja atribuidos
		If (Len(mvBrwSele:aCols) > 0)
			// faço um select na Z18 para encontrar o registro do usuário
			_cQuery := " SELECT R_E_C_N_O_ Z18RECNO FROM " + RetSqlTab("Z18")
			_cQuery += " WHERE " + RetSqlCond("Z18")
			_cQuery += " AND Z18_NUMOS  = '" + Z05->Z05_NUMOS + "' "
			_cQuery += " AND Z18_SEQOS  = '" + Z06->Z06_SEQOS + "' "
			_cQuery += " AND Z18_OPERAD = '" + mvBrwSele:aCols[mvBrwSele:nAt][2] + "' "
			_cQuery += " AND Z18_CATEG  = 'O' "
			_cQuery += " AND Z18_STATUS = 'B' "

			// jogo o resultado da query para a variavel pra analisar se está correto
			_nRecnoZ18 := U_FtQuery(_cQuery)
		EndIf

		// se encontrou o registro, somente altera o status, do contrário, grava um novo
		If ( ! Empty(_nRecnoZ18)) .And. ( _nRecnoZ18 > 0 )
			dbSelectArea("Z18")
			Z18->(dbGoTo( _nRecnoZ18 ))
			RecLock("Z18")
			Z18->Z18_STATUS := "R" // P=Planejado / R=Realizado / B=Bloqueado
			Z18->(MsUnLock())
		Else
			// caso não tenha usuário com esse registro, insere uma nova linha
			dbSelectArea("Z18")
			RecLock("Z18",.T.)
			Z18->Z18_FILIAL	:= xFilial("Z18")
			Z18->Z18_NUMOS  := Z05->Z05_NUMOS
			Z18->Z18_SEQOS  := Z06->Z06_SEQOS
			Z18->Z18_STATUS := "R" // P=Planejado / R=Realizado / B=Bloqueado
			Z18->Z18_USUARI := _cCodOper
			Z18->Z18_OPERAD := mvBrwDisp:aCols[mvBrwDisp:nAt][2]
			Z18->Z18_CATEG  := "O"
			Z18->(MsUnLock())

			// insere o log
			U_FtGeraLog(cFilAnt, "Z18", xFilial("Z18") + Z05->Z05_NUMOS + Z06->Z06_SEQOS, "Definido Operador " + _cCodOper, "WMS", "")

		EndIf

		// remover usuario
	ElseIf (mvOper == "-") .And. (Len(mvBrwSele:aCols) > 0)

		dbSelectArea("Z18")
		Z18->(dbSetOrder(1)) // 1-Z18_FILIAL, Z18_NUMOS, Z18_SEQOS, Z18_OPERAD
		Z18->(dbSeek( _cSeekZ18 := xFilial("Z18") + Z05->Z05_NUMOS + Z06->Z06_SEQOS ))
		// varre todos os registro
		While Z18->( ! Eof() ) .and. ((Z18->Z18_FILIAL + Z18->Z18_NUMOS + Z18->Z18_SEQOS) ==_cSeekZ18)
			// veirica categoria e codigo do operador
			If (Z18->Z18_CATEG == "O") .and. (Z18->Z18_OPERAD == mvBrwSele:aCols[mvBrwSele:nAt][2])
				RecLock("Z18")
				Z18->Z18_STATUS := "B" // P=Planejado / R=Realizado / B=Bloqueado
				Z18->(MsUnLock())
			EndIf
			// proximo recurso da OS
			Z18->(dbSkip())
		EndDo

		// atribui recursos recentes
	ElseIf (mvOper == "*")

		// variaveis para uso na Static Function sfAddRecurso
		// OBS: por limitacao tecnica, foi necessario declarar variaveis locais para usar como parametros
		_cIxbCodSrv := Z06->Z06_SERVIC
		_cIxbCodTrf := Z06->Z06_TAREFA
		_cIxbSeqOs  := Z06->Z06_SEQOS
		_cIxbCodCli := Z05->Z05_CLIENT
		_cIxbLojCli := Z05->Z05_LOJA
		_cIxbTpOper := Z05->Z05_TPOPER

		// funcao padrao para atribuir recursos humanos a ordem de servico
		StaticCall(TWMSA009, sfAddRecurso, _cIxbCodSrv, _cIxbCodTrf, _cIxbSeqOs, _cIxbCodCli, _cIxbLojCli, _cIxbTpOper, .F., .T.)

	EndIf

	// consulta recusros
	_aTmpDisp := sfRetRecHum()
	_aTmpSele := sfRetRecSel()

	// atualiza browse
	mvBrwDisp:aCols := aClone(_aTmpDisp)
	mvBrwDisp:Refresh()
	mvBrwSele:aCols := aClone(_aTmpSele)
	mvBrwSele:Refresh()

Return(.T.)

// ** rotina para expedição - definição de doca para operação
Static Function sfDefDoca(mvQryUsr)

	// variável de retorno
	Local _lRet    := .T.
	//	query para update
	Local _cUpdDoca := ""
	// query para validação
	Local _cQryZ17 := ""
	// variável para validação da OS
	Local _nMovOs  := 0
	// variável que recebe o valor da doca
	local _cNewDoca := ""

	// descarta OS interna
	mvQryUsr += " AND Z05_TPOPER NOT IN ('I') "

	// chamo a rotina padrão de OS
	If ( _lRet := U_ACDA002C(mvQryUsr,"AG;EX",.T.,.F.,.F.,.T.) )

		// query para validar movimentação da OS
		If (_lRet)
			_cQryZ17 := " SELECT COUNT(*) FROM "+RetSqlName("Z17")+" Z17 "
			_cQryZ17 += " WHERE "+RetSqlCond("Z17")
			_cQryZ17 += " AND Z17_NUMOS = '"+Z06->Z06_NUMOS+"' "

			// jogo o resultado da query para a variável
			_nMovOs := U_FtQuery(_cQryZ17)

			// se o resultado for maior que zero é pq existe movimentação
			If (_nMovOs > 0)
				// mensagem
				U_FtWmsMsg("Essa OS já possui movimentação. Não é possível alterar a DOCA!","Atenção!")
				// variável de retorno
				_lRet := .F.
			EndIf
		EndIf

		// relação de docas
		If (_lRet)
			// função que traz a relação de docas
			If ( ! sfRetDoca(@_cNewDoca))
				// variável de retorno
				_lRet := .F.
			EndIf
		EndIf

		// se a doca veio preenchida
		If (_lRet) .And. ( ! Empty(_cNewDoca))
			// faço o update no mapa de armazenagem
			_cUpdDoca := " UPDATE "+RetSqlName("Z08")
			// OS de entrada
			If (Z05->Z05_TPOPER == "E")
				_cUpdDoca += " SET Z08_ENDSRV = '"+_cNewDoca+"', "
				_cUpdDoca += " Z08_ENDORI = '"+_cNewDoca+"' "
				// OS de saida
			ElseIf (Z05->Z05_TPOPER == "S")
				_cUpdDoca += " SET Z08_ENDDES = '"+_cNewDoca+"' "
			EndIf
			// filtro padrao
			_cUpdDoca += " WHERE Z08_FILIAL = '"+xFilial("Z08")+"' AND D_E_L_E_T_ = '' "
			// filtro numero da OS
			_cUpdDoca += " AND Z08_NUMOS = '"+Z06->Z06_NUMOS+"' "
			// executa o update
			TcSQLExec(_cUpdDoca)


			// faço o update nos itens da ordem de servico
			_cUpdDoca := " UPDATE "+RetSqlName("Z06")
			_cUpdDoca += " SET Z06_ENDSRV = '"+_cNewDoca+"' "
			// filtro padrao
			_cUpdDoca += " WHERE Z06_FILIAL = '"+xFilial("Z06")+"' AND D_E_L_E_T_ = '' "
			// filtro numero da OS
			_cUpdDoca += " AND Z06_NUMOS = '"+Z06->Z06_NUMOS+"' "
			// executa o update
			TcSQLExec(_cUpdDoca)


			// faço o update na movimentacao do veiculo
			If ( ! Empty(Z05->Z05_CESV))
				_cUpdDoca := " UPDATE "+RetSqlName("SZZ")
				_cUpdDoca += " SET ZZ_DOCA = '"+_cNewDoca+"' "
				// filtro padrao
				_cUpdDoca += " WHERE ZZ_FILIAL = '"+xFilial("SZZ")+"' AND D_E_L_E_T_ = '' "
				// filtro numero do CESV
				_cUpdDoca += " AND ZZ_CESV = '"+Z05->Z05_CESV+"' "
				// executa o update
				TcSQLExec(_cUpdDoca)
			EndIf

			// mensagem
			U_FtWmsMsg("Foi definida a doca: "+AllTrim(_cNewDoca)+" para a OS: "+Z06->Z06_NUMOS+" com sucesso!","Atenção!")

		EndIf

	EndIf

Return(_lRet)

// ** função que retorna as docas por filial
Static Function sfRetDoca(mvNewDoca)

	// variável de retorno
	Local _lRet      := .T.
	// relacao docas
	local _aColsDoca := {}
	local _aHeadDoca := {}
	// variável que receberá a query de update
	Local _cQrySBE   := ""

	aAdd(_aHeadDoca,{"Docas"   ,"BE_LOCALIZ" , "", TamSx3("BE_LOCALIZ")[1] ,0,Nil,Nil,"C",Nil,"R" })

	// Query simples pra trazer todas as DOCAS disponíveis e que não estejam BLOQUEADAS (BE_STATUS = 3)
	_cQrySBE := "SELECT BE_LOCALIZ, '.F.' IT_DEL FROM "+RetSqlName("SBE")+" SBE
	_cQrySBE += " WHERE "+RetSqlCond("SBE")
	_cQrySBE += " AND BE_STATUS != '3' "
	_cQrySBE += " AND SUBSTRING(BE_LOCALIZ,1,4) = 'DOCA' "

	// jogo o resultado da query no array
	_aColsDoca := U_SqlToVet(_cQrySBE)

	// monta o dialogo do monitor
	_oWndDefDoca := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Define Doca",,,.F.,,,,,,.T.,,,.T. )
	_oWndDefDoca:lEscClose := .F.

	// cria o panel do cabecalho - botoes
	_oPnlDefDoca := TPanel():New(000,000,nil,_oWndDefDoca,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlDefDoca:Align:= CONTROL_ALIGN_TOP

	// -- BOTAO DE OK
	_oBmpEstorno := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| mvNewDoca := _oBrwDefDoca:aCols[_oBrwDefDoca:nAt][1], _oWndDefDoca:End() },_oPnlDefDoca,"Definir Doca",,.T.)
	_oBmpEstorno:Align := CONTROL_ALIGN_LEFT
	// -- BOTAO DE SAIDA
	_oBmpDefDoca := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _lRet := .F., _oWndDefDoca:End() },_oPnlDefDoca,"Sair",,.T.)
	_oBmpDefDoca:Align := CONTROL_ALIGN_RIGHT

	// monta o browse
	_oBrwDefDoca := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDoca),'AllwaysTrue()','','AllwaysTrue()',_oWndDefDoca,_aHeadDoca,_aColsDoca)
	_oBrwDefDoca:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa o dialogo
	_oWndDefDoca:Activate(,,,.F.,,,)

Return (_lRet)

// ** função para coleta de parâmetros para impressão de etiquetas de expedição
Static Function sfImpEtqExp()

	// objetos
	local _oWnd01Quant
	local _oPnl01Cabec
	local _oBtn01Conf, _oBtn01Canc
	local _oSay01Qtd, _oSay01Tipo
	local _oGet01Qtd
	// controle para nao fechar a tela
	Local _lRetOk := .F.

	// variaveis para uso e controle
	local _cTipoEtiq := ""

	// quantidade
	private _nQtdEtqExp := 0

	// monta a tela para informa a quantidade
	_oWnd01Quant := MSDialog():New(020,020,164,200,"Etiquetas para Expedição",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnl01Cabec := TPanel():New(000,000,nil,_oWnd01Quant,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnl01Cabec:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBtn01Conf := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRetOk := .T.,_oWnd01Quant:End() },_oPnl01Cabec,"Ok",,.T.)
	_oBtn01Conf:Align := CONTROL_ALIGN_LEFT

	// -- FECHAR
	_oBtn01Canc := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _lRet := .F., _oWnd01Quant:End() },_oPnl01Cabec,"Sair",,.T.)
	_oBtn01Canc:Align := CONTROL_ALIGN_RIGHT

	// titulo do tipo de etiqueta
	_oSay01Tipo := TSay():New(025,005,{||"Tipo Etiqueta"},_oWnd01Quant,,_oFnt02,.F.,.F.,.F.,.T.)

	// tipo de etiqueta
	_oCBxTpEtiq := TComboBox():New(033,030,{|u| If(PCount()>0,_cTipoEtiq:=u,_cTipoEtiq)},{"01-Produto","04-Volumes"},060,010,_oWnd01Quant,,,,,,.T.,,"",,,,,,,_cTipoEtiq )

	// titulo
	_oSay01Qtd := TSay():New(047,005,{||"Quantidade:"},_oWnd01Quant,,_oFnt02,.F.,.F.,.F.,.T.)

	// botao para usar como foco (nao é usado pra nada)
	_oGet01Qtd := TGet():New(055,030,{|u| If(PCount()>0,_nQtdEtqExp:=u,_nQtdEtqExp)},_oWnd01Quant,60,010,"@E 99",{|| Positivo() },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nQtdEtqExp",,)

	// ativacao da tela com validacao
	_oWnd01Quant:Activate(,,,.T.)

	// controle de confirmacao
	If (_lRetOk)
		// processa a rotina que fará a impressão
		Processa({ || sfEtqExp(_cTipoEtiq, _nQtdEtqExp) },"Analisando informações...",,.T.)
	EndIf

Return

// ** função para impressão de etiquetas de expedição
Static Function sfEtqExp(mvTpEtiq, mvQuant)

	// variável que receberá a etiqueta
	local _cTmpEtiq := ""
	// arquivos temporarios
	local _cTmpArquivo, _cTmpBat, _nTmpHdl
	// retorna a pasta temporaria da maquina
	local _cPathTemp := AllTrim(GetTempPath())
	// variavel de controle
	local _lOk := .T.
	// impressora selecionada
	local _cImpSelec := U_FtImpZbr()
	// controle de for
	local _nX := 0
	// número da etiqueta
	local _cNumEtiq := ""
	// array em branco só para reutilizar função de geração de etiquetas
	local _aMonEtiq := {"","","","","","","","","","",0,0,""}
	// impressoras disponíveis
	local _aImpWindows := U_FtRetImp()

	// objetos da tela
	local _oWndSelImp
	local _oCBxTpEtiq
	local _oBtnEtqOk, _oBtnEtqCan

	// controle para execucao da impressao dos dados
	local _lImpressOk := .F.

	// define o conteudo inicial da etiqueta a ser impressa - cabeçalho
	If (Left(mvTpEtiq,2) == "01") // 01-Produto

		// tela para selecionar as impressoras de etiquetas disponiveis
		_oWndSelImp := MSDialog():New(000,000,080,210,"Impressoras de etiquetas",,,.F.,,,,,,.T.,,,.T. )
		_oCBxTpEtiq := TComboBox():New( 004,004,{|u| If(PCount()>0,_cImpSelec:=u,_cImpSelec)},_aImpWindows,100,010,_oWndSelImp,,,,,,.T.,,"",,,,,,,_cImpSelec )
		_oBtnEtqOk  := SButton():New( 021,021,1,{ || _lOk := .T. , _oWndSelImp:End() },_oWndSelImp,,"", )
		_oBtnEtqCan := SButton():New( 021,055,2,{ || _oWndSelImp:End() },_oWndSelImp,,"", )
		_oWndSelImp:Activate(,,,.T.)

		If (_lOk)

			// grava informacoes da impressora selecionada
			U_FtImpZbr(_cImpSelec)

			// remove texto e mantem só o caminho
			_cImpSelec := Separa(_cImpSelec,"|")[2]

			// define o arquivo temporario com o conteudo da etiqueta
			_cTmpArquivo := _cPathTemp+"wms_etiq_plt_frac.txt"

			// cria e abre arquivo texto
			_nTmpHdl := fCreate(_cTmpArquivo)

			// testa se o arquivo de Saida foi Criado Corretamente
			If (_nTmpHdl == -1)
				MsgAlert("O arquivo de nome "+_cTmpArquivo+" nao pode ser executado! Verifique os parametros.","Atencao!")
				Return(.F.)
			Endif
		Else
			// se cancelou a impressão, sai da rotina
			Return(.F.)

		EndIf

		_cTmpEtiq := "CT~~CD,~CC^~CT~"+CRLF
		_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
		_cTmpEtiq += "~DG000.GRF,04608,036,"+CRLF
		_cTmpEtiq += ",:::::::::::::::Q0BE8,O01FIFC0,O0LFE,O017FJF80,R02FHFE0,T05FF8,K03FKFA003FE,J01FNFH01F,J07FOFC0180,J0RFC0,I03FRFE,I03FSF80,I07FTF8,I07FTFC,I0WF,H01FVFC0,H03FWF0,H03FWF8,H07FWFE,"+;
		"H07FWFE0X07FC,H0YFE0I0KF83FIFC003FHF80I0FC0H03FHFE0H03F80,01FYFJ0KF83FIFC007FHFC0I0FC0H01FIF8007F,01FYF80H0KF83FIFE01FIFE0H01FE0H03FIFE003F80,01FYF80H0KF83FIFC03FJFI01FF0H03FJFH03F,"+;
		"03FYFC0H0KF83FIFC07FJF8003FF8003FJF803F80,03FYFC0H0KF83FIFC07FC1FFC003FF8001FJF803F,07FYFE0H0KF83FEAHA0FF807FE003FF8003F83FFC03F80,07FHF50157FQFE0I01FC003FC0H01FF001FE007FF8001F803FC03F,"+;
		"07FE80J0RFE0I03FE003FC0H01FE0H0FE007FFC003F803FE03F80,07C0M07FOFE0I01FC003FC0H01FE0H0HFH07FFC001F801FE03F,0E0I020I07FPFJ03FE003FE0H03FE0H020H0FEFE003F801FE03F80,"+;
		"0C007FIFH07FPFJ01FC003FIFC3FC0L0FCFE001F800FE03F,0803FKF8FQFJ03FE003FIFC3FC0K01FCFE003F800FE03F80,080FLF8FQFJ01FC003FIFC3FC0K01FC7F001F800FF03F,181FLF8FQF80H03FE003FIFC3FC0K03F87F003F800FE03F80,"+;
		"103FLF0FMF7FHFJ01FC003FIFC3FC0K03F87F001F800FF03F,103FLF8FLFE0FHF80H03FE003FIFC3FC0K03F87F803F800FE03F80,H07FLF0FLFE03FF80H01FC003FC0H01FC0K07F03F801F800FE07F,"+;
		"087FLF1FLFE00FF80H03FE003FE0H03FE0H0HF0FF03FC03F801FE03F80,H07FLF1FLFE003F80H01FC003FC0H01FF001FE0FJFC03F801FE03F,H07FKFE1FLFE600F80H03FE003FC0I0HF803FE0FJFE03F803FE03F80,"+;
		"H07FKFE1FLFC780780H01FC003FC0I0HFC07FC1FJFE01F807FC03F,H07FKFE3FLFEFE0380H03FE003FIFE07FJFC1FJFE03FABFFC03F80,H07FKFE1FLFC7F0180H01FC003FIFE07FJF81FKF01FJF803F,"+;
		"H07FKFE3FLF8FF8180H03FE003FIFE03FJF83FKF03FJF803F80,H07FKFC3FLF8FFC080H01FC003FIFE01FIFE03FC007F01FJFH03F,H03FKFC3FLF8FFE080H03FE003FIFE007FHFE07F8007F83FIFE003F80,"+;
		"H03FKFC7FLF8FHF080H01FC003FIFE001FHFH07F8007F81FIF8003F,H03FKF87FLF8FHF080H03FE003FIFE0H0HF800FF8003F83FHFE0H03F80,H03FKF87FLF1FHF,H03FKF87FLF1FFE,H01FKF07FLF1FFE10,H01FKF0FMF1FFE,"+;
		"H01FKF0FLFE1FFC,I0KFE0FLFE3FFC,I0KFE1FLFE7FFC0gN04,I0KFC1FLFE7FF80gN08,I07FIFC1FLFC7FF80N040H04040H040L0404004040040404,I07FIFC3FLFE7FF80J020F9B2FAA9A302A18EBB8C3BAEBB0BBA68E2B80,"+;
		"I03FIF83FLFC7FF0K02105024089028201449H94130690103044A28,I03FIF83FLFCFFE0K0218D2A788A0283C24F9A9A23EA8E1ABEF8B27,I01FIF07FLF8FFE0K0210510088905C203C5169E430581108051F2180,"+;
		"J0JF07FLF8FFE0K0H2E9B2E88BA6C2I2CB6B3E329B30BA2CB3A980,J07FFC07FLF1FFC0K034706070H0C4434434542173641E071745027,J07FFC0FMF9FF80,J03FF80FMF1FF,J01FF01FLFE3FE,K0FE01FLFE3FC,"+;
		"J083803FLFE3F8,N07FLFC7F0,J080H07FLFC7E0,N0NF8F80,J080H0NF8F80,M01FMF8E,J04003FMF18,M07FMF10,J0301FMFE,K0DFNFC,K03FNFC,L01FMF8,M02FKFE0,O07FIFC0,P02FHF80,,::::::::::::::::::::::::::::^XA"+CRLF

		// grava a Linha no Arquivo Texto
		fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

		// for para gerar quantas etiquetas o usuário solicitou
		For _nX := 1 to mvQuant

			_cNumEtiq := U_FtGrvEtq("01",_aMonEtiq)

			// define conteudo no arquivo
			_lImpressOk := .T.

			_cTmpEtiq := "^MMT"+CRLF
			_cTmpEtiq += "^PW759"+CRLF
			_cTmpEtiq += "^LL0440"+CRLF
			_cTmpEtiq += "^LS0"+CRLF
			_cTmpEtiq += "^FT32,128^XG000.GRF,1,1^FS"+CRLF
			_cTmpEtiq += "^BY4,3,116^FT100,396^BCN,,N,N"+CRLF
			_cTmpEtiq += "^FD>:"+_cNumEtiq+"^FS"+CRLF
			_cTmpEtiq += "^FO45,252^GB704,0,1^FS"+CRLF
			_cTmpEtiq += "^FO41,105^GB704,0,1^FS"+CRLF
			_cTmpEtiq += "^FO100,125^GB560,58,58^FS"+CRLF
			_cTmpEtiq += "^FT100,167^A0N,38,60^FR^FH\^FD PALETE FRACIONADO ^FS"+CRLF
			_cTmpEtiq += "^FT301,424^A0N,28,28^FH\^FD"+Transf(_cNumEtiq,"@R 99999-99999")+"^FS"+CRLF
			_cTmpEtiq += "^FT315,32^A0N,23,21^FH\^FDWMS.PALETE FRACIONADO^FS"+CRLF
			_cTmpEtiq += "^FT559,92^A0N,23,21^FH\^FDFilial: "+AllTrim(SM0->M0_CODFIL)+"-"+AllTrim(SM0->M0_FILIAL)+"^FS"+CRLF
			_cTmpEtiq += "^FT315,93^A0N,23,21^FH\^FDDt.Imp: "+DtoC(Date())+"^FS"+CRLF
			_cTmpEtiq += "^FO307,8^GB0,97,2^FS"+CRLF
			_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
			_cTmpEtiq += "^XA"+CRLF
			// grava a Linha no Arquivo Texto
			fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

		Next _nX

		// final do arquivo texto
		_cTmpEtiq := "^XA^ID000.GRF^FS^XZ"+CRLF
		// grava a Linha no Arquivo Texto
		fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

		// fecha arquivo texto
		fClose(_nTmpHdl)

		// define o arquivo .BAT para execucao da impressao da etiqueta
		_cTmpBat := _cPathTemp+"wms_imp_etiq.bat"
		// grava o arquivo .BAT
		MemoWrit(_cTmpBat,"copy "+_cTmpArquivo+" "+_cImpSelec)

		// executa o comando (.BAT) para impressao
		If (_lImpressOk)
			WinExec(_cTmpBat)
		EndIf

	ElseIf (Left(mvTpEtiq,2) == "04") // 04-Volumes

		// chama funcao padrao de impressao de etiquetas de volumes, passando como parametro a mvOperacao 3-Avulso
		U_TWMSR013(;
		""     ,;
		""     ,;
		3      ,;
		Nil    ,;
		Nil    ,;
		Nil    ,;
		mvQuant,;
		1       )

	EndIf

Return ()

// função auxiliar para escolher se gera nova etiqueta ou reimprime
Static function sfEtiq

	local _cOperEtiq := ""

	// pergunta ao usuário a opção desejada
	_cOperEtiq := U_FtMultRet("Gerar novas", "Reimprimir", "gerar", "reimprimir", "Etiquetas", "Escolha a opção desejada:")

	// chama função correspondente
	If (_cOperEtiq == "gerar")
		sfImpEtqExp()
	Elseif (_cOperEtiq == "reimprimir")
		sfReimpEtq()
	EndIf


Return

// ** função para coleta de parâmetros para reimpressão de etiquetas
Static Function sfReimpEtq()

	// objetos
	local _oWndEtiq
	local _oPnl01Cabec
	local _oBtn01Conf, _oBtn01Canc
	local _oSayQtd, _oGetQtd
	local _oSayEtiq, _oGetEtiq

	// controle para nao fechar a tela
	Local _lRetOk := .F.

	// etiqueta a reimprimir
	private _cEtiqR := CriaVar("Z11_CODETI", .F. )

	// quantidade a reimprimir
	private _nQtdR := 1

	// monta a tela para informa a quantidade
	_oWndEtiq := MSDialog():New(020,020,164,200,"Reimpressão de etiqueta de volume",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnl01Cabec := TPanel():New(000,000,nil,_oWndEtiq,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnl01Cabec:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBtn01Conf := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRetOk := .T.,_oWndEtiq:End() },_oPnl01Cabec,"Ok",,.T.)
	_oBtn01Conf:Align := CONTROL_ALIGN_LEFT

	// -- FECHAR
	_oBtn01Canc := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _lRet := .F., _oWndEtiq:End() },_oPnl01Cabec,"Sair",,.T.)
	_oBtn01Canc:Align := CONTROL_ALIGN_RIGHT

	// Etiqueta a reimprimir
	_oSayEtiq := TSay():New(025,005,{||"Etiq. Volume:"}, _oWndEtiq,,_oFnt02,.F.,.F.,.F.,.T.)
	_oGetEtiq := TGet():New(033,030,{|u| If(PCount()>0, _cEtiqR:=u, _cEtiqR)},_oWndEtiq,60,010,PesqPict("Z11", "Z11_CODETI") ,{|| },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtiqR",,)

	// Quantidade
	_oSayQtd := TSay():New(047,005,{||"Quantidade:"}, _oWndEtiq,,_oFnt02,.F.,.F.,.F.,.T.)
	_oGetQtd := TGet():New(055,030,{|u| If(PCount()>0, _nQtdR:=u, _nQtdR)},_oWndEtiq,60,010,"@E 99",{|| Positivo() },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nQtdR",,)

	// ativacao da tela com validacao
	_oWndEtiq:Activate(,,,.T.)

	// controle de confirmacao
	If (_lRetOk)
		// chama funcao padrao de impressao de etiquetas de volumes, passando como parametro a mvOperacao 3-Avulso
		U_TWMSR013(;
		""     ,;
		""     ,;
		2      ,;   // reimprime
		Nil    ,;
		_cEtiqR    ,;  // etiqueta DE
		_cEtiqR    ,;  // etiqueta ATE
		_nQtdR,;       // quantidade
		1       )      // layout 1 - etiqueta unitária (uma coluna)

	EndIf

Return