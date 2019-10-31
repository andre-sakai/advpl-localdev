#Include "APWEBSRV.CH"
#Include "PROTHEUS.CH"

// criacao do Web Service
WSSERVICE WsCfgLogin DESCRIPTION "Web Service Cfg Para validações de Usuários / Senhas"

	WSDATA RecUsrPortal        AS String
	WSDATA RecPswPortal        AS String
	WSDATA RecPswCriptPortal   AS String
	WSDATA RecIdSessionPortal  AS String
	WSDATA RecEmailPortal      AS String
	WSDATA RecOldPswPortal     AS String
	WSDATA ReNewPswPortal      AS String
	WSDATA RecVldIdChave       AS String
	WSDATA RecVldIdTipo        AS String

	// variaveis de retorno
	WSDATA RetLoginAcessos     AS StrLoginUserStruct
	WSDATA RetSenhaCript       AS String
	WSDATA RetPortalIdSession  AS String
	WSDATA RetIdSessionOk      AS Boolean
	WSDATA RetOk               AS Integer

	// declaracao dos metodos
	WSMETHOD CfgLogin          DESCRIPTION "Validação do Login do usuário"
	WSMETHOD CfgCriptSenha     DESCRIPTION "Validar usuário e senha, criptografando a senha"
	WSMETHOD CfgValidSession   DESCRIPTION "Validar ID Session"
	WSMETHOD CfgRecuperaPsw    DESCRIPTION "Recupera/reinicia senha do portal"
	WSMETHOD CfgGravaNovaPsw   DESCRIPTION "Atualiza senha do portal"
	WSMETHOD CfgValidaAllId    DESCRIPTION "Valida ID diversos"

ENDWSSERVICE

// metodo para criptografar a senha
WSMETHOD CfgCriptSenha WSRECEIVE RecUsrPortal, RecPswPortal WSSEND RetSenhaCript WSSERVICE WsCfgLogin
	// variavel de retorno do metodo
	local _lRet := .f.

	// valida usuario e senha
	If (Empty(::RecUsrPortal)).or.(Empty(::RecPswPortal))
		SetSoapFault("LOGIN INVÁLIDO","Obrigatório informar usuário e senha para acesso.")
		Return(_lRet)
	EndIf

	// pesquisa pelo usuario
	dbSelectArea("AI3")
	AI3->(dbSetOrder(2)) // 2-AI3_FILIAL, AI3_LOGIN
	If ! AI3->( MsSeek( xFilial("AI3")+::RecUsrPortal ))
		setSoapFault("LOGIN INVÁLIDO","Usuário inválido.")
		Return(.f.)
	EndIf

	// gera senha criptografada
	::RetSenhaCript := Md5(AllTrim(::RecPswPortal))
	_lRet := .t.

Return(_lRet)


// metodo para validar e/ou reativar sessao
WSMETHOD CfgValidSession WSRECEIVE RecUsrPortal, RecIdSessionPortal WSSEND RetIdSessionOk WSSERVICE WsCfgLogin
	// variavel de retorno
	local _lRet := .f.
	// objeto de Ws Login
	local _oWsLogin
	// Registro da Session ID
	local _nRegSession := 0
	// insert da session
	local _cQrySession

	// valida usuario e senha
	If (Empty(::RecUsrPortal)).or.(Empty(::RecIdSessionPortal))
		setSoapFault("SESSÃO INVÁLIDA","Obrigatório informar usuário e Id Session!")
		Return(_lRet)
	EndIf

	// prepara query para validar a SESSION e Data de Validade
	_cQrySession := "SELECT SESSION_REG "
	_cQrySession += "  FROM PORTAL_SESSION "
	_cQrySession += " WHERE SESSION_ID       = '"+::RecIdSessionPortal+"' "
	_cQrySession += "   AND SESSION_LOGIN    = '"+::RecUsrPortal+"' "
	_cQrySession += "   AND GETDATE()       <= SESSION_EXPIRED "

	// busca o Registro da ID Session
	_nRegSession := U_FtQuery(_cQrySession)

	// nao ha mais session ativa
	If (_nRegSession == 0)
		setSoapFault("SESSÃO INVÁLIDA","Sessão expirou!")
		Return(.f.)

	Else

		_cQrySession := "UPDATE PORTAL_SESSION "
		_cQrySession += "   SET SESSION_EXPIRED = DATEADD(MI,5,GETDATE()) "
		_cQrySession += " WHERE SESSION_ID      = '"+::RecIdSessionPortal+"' "
		_cQrySession += "   AND SESSION_LOGIN   = '"+::RecUsrPortal+"' "
		_cQrySession += "   AND SESSION_REG     = "+AllTrim(Str(_nRegSession))

		// grava reg no banco
		TcSQLExec(_cQrySession)

		// define variavel de retorno
		::RetIdSessionOk := .T.
		Return(.t.)

	EndIf

Return(.t.)

// metodo para recuperar a senha
WSMETHOD CfgRecuperaPsw WSRECEIVE RecUsrPortal, RecEmailPortal WSSEND RetOk WSSERVICE WsCfgLogin

	Local _aAreaAtu := GetArea()
	local _cChave
	local _cQryChave

	// reinicia variavel
	::RetOk := 0

	// valida usuario e senha
	If (Empty(::RecUsrPortal)).or.(Empty(::RecEmailPortal))
		setSoapFault("LEMBRAR SENHA","Obrigatório informar usuário e e-mail!")
		Return(.f.)
	EndIf

	// pesquisa pelo usuario
	dbSelectArea("AI3")
	AI3->(dbSetOrder(2)) // 2-AI3_FILIAL, AI3_LOGIN
	If AI3->( MsSeek( xFilial("AI3")+::RecUsrPortal ))

		// valida o e-mail
		If (AllTrim(Lower(AI3->AI3_EMAIL)) == AllTrim(Lower(RecEmailPortal)) )

			// cria uma chave aleatoria
			_cChave	:= U_FtGeraPsw(10)

			// gera o registro da session
			_cQryChave := "INSERT INTO PORTAL_VALIDAID ("
			_cQryChave += "ID_CHAVE, ID_TIPO, ID_STATUS, ID_LOGIN ) "
			_cQryChave += "VALUES ("
			_cQryChave += "'"+_cChave+"',"
			_cQryChave += "'01',"
			_cQryChave += "'  ',"
			_cQryChave += "'"+::RecUsrPortal+"'"
			_cQryChave += ")"

			// grava reg no banco
			TcSQLExec(_cQryChave)

			U_FtMail("Solicitação de recuperação de senha"+CRLF+;
				"http://portal.tecadi.com.br/recupera.aspx?userlogin="+AllTrim(::RecUsrPortal)+"&id_chave="+_cChave+"&id_tipo=01",;
				"Portal Tecadi - Recuperação de Senha",AllTrim(Lower(AI3->AI3_EMAIL)))

			// variavel de retorno
			::RetOk := 1

		Else
			setSoapFault("LEMBRAR SENHA","E-mail inválido.")
			Return(.f.)
		EndIf

	Else
		setSoapFault("LEMBRAR SENHA","Usuário inválido.")
		Return(.f.)
	EndIf

	// restata area inicial
	RestArea(_aAreaAtu)

Return(.t.)

// metodo para alterar a senha
WSMETHOD CfgGravaNovaPsw WSRECEIVE RecUsrPortal, RecIdSessionPortal, RecEmailPortal, RecOldPswPortal, ReNewPswPortal WSSEND RetOk WSSERVICE WsCfgLogin

	Local _aAreaAtu := GetArea()
	// objeto para validar sessao
	local _oWsLogin := WSWSCFGLOGIN():New()

	// reinicia variavel
	::RetOk := 0

	// valida usuario e senha
	If (Empty(::RecUsrPortal)).or.(Empty(::RecIdSessionPortal)).or.(Empty(::RecEmailPortal)).or.(Empty(::RecOldPswPortal)).or.(Empty(::ReNewPswPortal))
		setSoapFault("DEFINIÇÃO DE SENHA","Obrigatório informar usuário, e-mail e senha!")
		Return(.f.)
	EndIf

	// valida session
	If ! _oWsLogin:CFGVALIDSESSION(::RecUsrPortal, ::RecIdSessionPortal)
		setSoapFault("DEFINIÇÃO DE SENHA","Sessão Inválida ou Sessão Expirou!")
		Return(.f.)
	EndIf

	// pesquisa pelo usuario
	dbSelectArea("AI3")
	AI3->(dbSetOrder(2)) // 2-AI3_FILIAL, AI3_LOGIN
	If AI3->( MsSeek( xFilial("AI3")+::RecUsrPortal ))
		// valida o e-mail
		If (AllTrim(Lower(AI3->AI3_EMAIL)) == AllTrim(Lower(RecEmailPortal)) )
			// valida senha antiga
			If (AllTrim(AI3->AI3_PSW) == AllTrim(::RecOldPswPortal))

				// atualiza par anova senha
				RecLock("AI3")
				AI3->AI3_PSW  := Md5(AllTrim(::ReNewPswPortal))
				AI3->AI3_ZPSW := ::ReNewPswPortal
				AI3->(MsUnLock())

				// gera log
				U_FtGeraLog(xFilial("AI3"), "AI3", xFilial("AI3")+AI3->AI3_CODUSU , "Alteração de senha por portal", "PRT", "")

				// confirma alteracao por email
				U_FtMail("Senha de "+AllTrim(AI3->AI3_NOME)+" atualizada com sucesso!","Portal Tecadi - Atualização de Senha",AllTrim(Lower(AI3->AI3_EMAIL)))

				::RetOk := 1
			Else
				setSoapFault("DEFINIÇÃO DE SENHA","Senha não confere.")
				Return(.f.)

			EndIf

		Else
			setSoapFault("DEFINIÇÃO DE SENHA","E-mail Inválido")
			Return(.f.)
		EndIf

	Else
		setSoapFault("DEFINIÇÃO DE SENHA","Usuário Inválido")
		Return(.f.)
	EndIf

	// restata area inicial
	RestArea(_aAreaAtu)

Return(.t.)

// metodo para valiar ID diversos
WSMETHOD CfgValidaAllId WSRECEIVE RecUsrPortal, RecVldIdChave, RecVldIdTipo WSSEND RetOk WSSERVICE WsCfgLogin
	// query
	local _cQuery
	local _nNrReg
	// nova senha
	local _cNewPsw
	local _cNewPswCript

	// reinicia variavel
	::RetOk := 0

	// valida usuario e senha
	If (Empty(::RecUsrPortal)).or.(Empty(::RecVldIdChave)).or.(Empty(::RecVldIdTipo))
		setSoapFault("VALIDAÇÃO DE ID","Dados necessários para validação não foram informados.")
		Return(.f.)
	EndIf

	// monta a query
	_cQuery := "SELECT ID_REG "
	_cQuery += "FROM PORTAL_VALIDAID "
	_cQuery += "WHERE ID_CHAVE = '"+::RecVldIdChave+"' "
	_cQuery += "AND ID_TIPO    = '"+::RecVldIdTipo+"' "
	_cQuery += "AND ID_LOGIN   = '"+::RecUsrPortal+"' "
	_cQuery += "AND ID_STATUS  = '  ' "

	_nNrReg := U_FtQuery(_cQuery)

	If (_nNrReg > 0)

		// se for recuperacao de senha
		If (::RecVldIdTipo == "01")

			// pesquisa pelo usuario
			dbSelectArea("AI3")
			AI3->(dbSetOrder(2)) // 2-AI3_FILIAL, AI3_LOGIN
			If AI3->( MsSeek( xFilial("AI3")+::RecUsrPortal ))

				// gera nova senha
				_cNewPsw      := U_FtGeraPsw(6)
				_cNewPswCript := Md5(_cNewPsw)

				RecLock("AI3")
				AI3->AI3_ZPSW := _cNewPsw
				AI3->AI3_PSW  := _cNewPswCript
				AI3->(MsUnLock())

				// manda mensagem da nova senha
				U_FtMail("Login: "+::RecUsrPortal +CRLF+ "Nova senha de acesso: "+_cNewPsw,"Portal Tecadi - Senha temporária",AllTrim(Lower(AI3->AI3_EMAIL)))

			EndIf

		EndIf

		_cQuery := "UPDATE PORTAL_VALIDAID "
		_cQuery += "SET ID_STATUS = 'OK' "
		_cQuery += "WHERE ID_CHAVE = '"+::RecVldIdChave+"' "
		_cQuery += "AND ID_TIPO    = '"+::RecVldIdTipo+"' "
		_cQuery += "AND ID_REG     = "+AllTrim(Str(_nNrReg))+" "
		_cQuery += "AND ID_LOGIN   = '"+::RecUsrPortal+"' "
		_cQuery += "AND ID_STATUS  = ' ' "

		// grava reg no banco
		TcSQLExec(_cQuery)

		::RetOk := 1

	Else
		setSoapFault("VALIDAÇÃO DE ID","A chave informada é inválida.")
		Return(.f.)
	EndIf

Return(.t.)


// ** novo formato login
WSMETHOD CfgLogin WSRECEIVE RecUsrPortal, RecPswPortal WSSEND RetLoginAcessos WSSERVICE WsCfgLogin

	// validacao de retorno
	local _lRetOk := .t.
	local _cMsgOk := ""

	// valida usuario e senha
	dbSelectArea("AI3")
	AI3->(dbSetOrder(2)) // 2-AI3_FILIAL, AI3_LOGIN
	If MsSeek(xFilial("AI3")+::RecUsrPortal)

		/*
		conout("WsCfgLogin xFilial(SA1) "+xFilial("SA1"))
		conout("WsCfgLogin xFilial(SF2) "+xFilial("SF2"))
		conout("WsCfgLogin __cUserId    "+__cUserId)
		conout("WsCfgLogin cUsuario     "+cUsuario)
		conout("WsCfgLogin cEmpAnt      "+cEmpAnt)
		conout("WsCfgLogin cFilAnt      "+cFilAnt)
		conout("WsCfgLogin cModulo      "+cModulo)
		conout("WsCfgLogin SM0          "+SM0->M0_FILIAL)
		conout("WsCfgLogin Login        "+AI3->AI3_LOGIN)

		conout(Replicate("- . ",20))

		//RPCClearEnv()
		//RPCSetType(3)
		//RPCSetEnv("01","105")

		conout("WsCfgLogin xFilial(SA1) "+xFilial("SA1"))
		conout("WsCfgLogin xFilial(SF2) "+xFilial("SF2"))
		conout("WsCfgLogin __cUserId    "+__cUserId)
		conout("WsCfgLogin cUsuario     "+cUsuario)
		conout("WsCfgLogin cEmpAnt      "+cEmpAnt)
		conout("WsCfgLogin cFilAnt      "+cFilAnt)
		conout("WsCfgLogin cModulo      "+cModulo)
		conout("WsCfgLogin SM0          "+SM0->M0_FILIAL)
		conout("WsCfgLogin Login        "+AI3->AI3_LOGIN)
		*/

		// verifica login e senha
		If (AllTrim(::RecUsrPortal) == AllTrim(AI3->AI3_LOGIN)).And.((AllTrim(AI3->AI3_PSW) == AllTrim(::RecPswPortal)))

			// atualiza dados do usuario
			::RetLoginAcessos:USERCODE          := AI3->AI3_CODUSU
			::RetLoginAcessos:USERLOGIN         := AI3->AI3_LOGIN
			::RetLoginAcessos:USERNAME          := AI3->AI3_NOME
			::RetLoginAcessos:USEREMAIL         := AI3->AI3_EMAIL
			::RetLoginAcessos:USERROLES         := VAL(AI3->AI3_ADMIN)

			// prepara as informacoes do ID Sessio
			If ! sfRetIdSession(Self:RetLoginAcessos)
				_cMsgOk += IIf(Empty(_cMsgOk),"",", ")+"ID.SESSION"
				_lRetOk := .f.
			EndIf

			// prepara as informacoes dos clientes relacionados ao login
			If ! sfRetClientes(Self:RetLoginAcessos)
				_cMsgOk += IIf(Empty(_cMsgOk),"",", ")+"CLIENTES"
				_lRetOk := .f.
			EndIf

			// prepara as informacoes das filiais disponiveis
			If ! sfRetFiliais(Self:RetLoginAcessos)
				_cMsgOk += IIf(Empty(_cMsgOk),"",", ")+"FILIAIS"
				_lRetOk := .f.
			EndIf

			// prepara as informacoes do tipo de estoque
			If ! sfRetTpEstoque(Self:RetLoginAcessos)
				_cMsgOk += IIf(Empty(_cMsgOk),"",", ")+"TIPO DE ESTOQUE"
				_lRetOk := .f.
			EndIf

			// prepara as informacoes dos periodos do estoque
			If ! sfRetPerEstoque(Self:RetLoginAcessos)
				_cMsgOk += IIf(Empty(_cMsgOk),"",", ")+"PERIODO DO ESTOQUE"
				_lRetOk := .f.
			EndIf

			// prepara as informacoes do menu do usuario
			If ! sfRetMenus(Self:RetLoginAcessos)
				_cMsgOk += IIf(Empty(_cMsgOk),"",", ")+"MENUS"
				_lRetOk := .f.
			EndIf

			If ( ! _lRetOk)
				SetSoapFault("LOGIN INVALIDO","Erro na definição das configurações do usuário: "+_cMsgOk)
			EndIf

		Else
			SetSoapFault("LOGIN INVALIDO","A senha informada esta incorreta")
			_lRetOk := .F.

		EndIf
	Else
		SetSoapFault("LOGIN INVALIDO","O usuario informado esta incorreto")
		_lRetOk := .F.
	EndIf

Return (_lRetOk)

WSSTRUCT StrLoginUserStruct
	WSDATA USERCODE             		AS String OPTIONAL
	WSDATA USERLOGIN            		AS String
	WSDATA USEREMAIL	    			AS String OPTIONAL
	WSDATA USERWS               		AS String OPTIONAL
	WSDATA USERNAME             		AS String
	WSDATA USERROLES            		AS Integer
	WsData UserClientes        AS Array Of StListaClientes
	WsData UserTipoEstoque     AS Array Of StListaTipoEstoque
	WsData UserPeriodoEstoque  AS Array Of StListaPeriodoEstoque
	WsData UserFiliais         AS Array Of StListaFiliais
	WsData UserMenus           AS Array Of StListaMenu
	WSDATA UserIdSession       AS String
ENDWSSTRUCT

// ** funcao que cria o ID Session
Static Function sfRetIdSession(mvObjRet)
	// ID Session
	local _cIdSession
	// query
	local _cQrySession

	// cria um ID session
	_cIdSession := AI3->AI3_CODUSU
	_cIdSession += DtoS(Date())
	_cIdSession += Time()
	_cIdSession += SuperGetMv("MV_NUMSEQ",.f.,AI3->AI3_CODUSU)

	// cript da Id Session
	_cIdSession := Md5(_cIdSession)

	// gera o registro da session
	_cQrySession := "INSERT INTO PORTAL_SESSION ("
	_cQrySession += "SESSION_ID, SESSION_FILIAL, SESSION_CLIENTE, SESSION_LOJA, SESSION_LOGIN, SESSION_ORIGEM, SESSION_PCNAME ) "
	_cQrySession += "VALUES ("
	_cQrySession += "'"+_cIdSession+"',"
	_cQrySession += "'',"
	_cQrySession += "'',"
	_cQrySession += "'',"
	_cQrySession += "'"+AI3->AI3_LOGIN+"',"
	_cQrySession += "'',"
	_cQrySession += "'')"

	// grava reg no banco
	TcSQLExec(_cQrySession)

	// define variavel de retorno
	mvObjRet:UserIdSession := _cIdSession

Return(.t.)


// ** funcao que atualiza as filiais do login
Static Function sfRetFiliais(mvObjRet)

	// query
	local _cQuery
	local _aTmpDados
	local _nTmpDados
	local _nItem
	// area atual
	local _aAreaSM0 := SM0->(GetArea())

	// variavel de retorno
	local _lRetOk := .f.

	mvObjRet:UserFiliais := {}

	// monta query para buscar as filiais que ha movimentacao para os clientes relacionados do usuario logado
	_cQuery := "SELECT DISTINCT Z1_FILIAL, Z1_CLIENTE, Z1_LOJA "
	// lista de clientes vinculados ao login
	_cQuery += "FROM "+RetSqlName("AI4")+" AI4 "
	// cad. de programacoes
	_cQuery += "INNER JOIN "+RetSqlName("SZ1")+" SZ1 ON Z1_FILIAL != '   ' AND SZ1.D_E_L_E_T_ = '' AND Z1_CLIENTE = AI4_CODCLI AND Z1_LOJA = AI4_LOJCLI "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("AI4")
	// filtro do codigo do usuario
	_cQuery += "AND AI4_CODUSU = '"+AI3->AI3_CODUSU+"' "
	// ordem dos dados
	_cQuery += "ORDER BY 1 "

	// alimenta os dados
	_aTmpDados := U_SqlToVet(_cQuery)

	For _nTmpDados := 1 to Len(_aTmpDados)

		// posiciona na filial
		dbSelectArea("SM0")
		dbSetOrder(1)
		dbSeek(cEmpAnt+_aTmpDados[_nTmpDados][1])

		aAdd(mvObjRet:UserFiliais,WSClassNew("StListaFiliais"))
		_nItem := Len(mvObjRet:UserFiliais)

		mvObjRet:UserFiliais[_nItem]:cCodFilial   := SM0->M0_CODFIL
		mvObjRet:UserFiliais[_nItem]:cDscFilial   := SM0->M0_FILIAL
		mvObjRet:UserFiliais[_nItem]:cEstFilial   := SM0->M0_ESTCOB
		mvObjRet:UserFiliais[_nItem]:cMunFilial   := SM0->M0_CIDCOB
		mvObjRet:UserFiliais[_nItem]:cCodCliente  := _aTmpDados[_nTmpDados][2]
		mvObjRet:UserFiliais[_nItem]:cLojaCliente := _aTmpDados[_nTmpDados][3]

		// variavel de retorno
		_lRetOk := .t.

	Next _nTmpDados

	// devolve posicao inicial
	RestArea(_aAreaSM0)

Return(_lRetOk)

// estrutura retorno de estoque de terceiros por produto
WSSTRUCT StListaFiliais
	WSDATA cCodFilial   As String
	WSDATA cDscFilial   As String
	WSDATA cEstFilial   As String
	WSDATA cMunFilial   As String
	WSDATA cCodCliente  As String
	WSDATA cLojaCliente As String
ENDWSSTRUCT

// ** funcao que retona o tipo de estoque
Static Function sfRetTpEstoque(mvObjRet)
	// variaveis de controle
	local _aOpcoesDisp
	local _cOpcoesSel
	local _nInicPos
	local _nPosOpcao
	local _nItem

	// variavel de retorno
	local _lRetOk := .f.

	// zera a variavel
	mvObjRet:UserTipoEstoque := {}

	// extrai as opcoes disponiveis de tipo de estoque disponiveis
	_aOpcoesDisp := U_TPRTA003(.f., "EST")

	// extrai o conteudo (opcoes selecionadas) do campo "tipo de estoque"
	_cOpcoesSel := AllTrim(AI3->AI3_ZTPEST)

	// varre todas as opcoes selecionadas
	For _nInicPos := 1 to Len(_cOpcoesSel) Step 3

		// pesquisa a opcao selecionada nas opcoes disponiveis
		_nPosOpcao := aScan(_aOpcoesDisp,{|x| (x[1] == SubStr(_cOpcoesSel,_nInicPos,3) ) })

		// caso encontre, adiciona no vetor de retorno
		If (_nPosOpcao > 0)

			// cria linha para incluir os dados do tipo de estoque
			AAdd(mvObjRet:UserTipoEstoque,WSClassNew("StListaTipoEstoque"))
			_nItem := Len(mvObjRet:UserTipoEstoque)

			mvObjRet:UserTipoEstoque[_nItem]:cCodTpEstoque := _aOpcoesDisp[_nPosOpcao][1]
			mvObjRet:UserTipoEstoque[_nItem]:cDscTpEstoque := _aOpcoesDisp[_nPosOpcao][2]

			// variavel de retorno
			_lRetOk := .t.

		EndIf

	Next _nInicPos

Return(_lRetOk)

// estrutura retorno de tipos de estoque
WSSTRUCT StListaTipoEstoque
	WSDATA cCodTpEstoque As String
	WSDATA cDscTpEstoque As String
ENDWSSTRUCT

// ** funcao que retona os clientes relacionados ao login
Static Function sfRetClientes(mvObjRet)

	// variaveis temporarias
	local _nItem
	local _cSeekAI4

	// variavel de retorno
	local _lRetOk := .f.

	// zera a variavel
	mvObjRet:UserClientes := {}

	// pesquisa os clientes relacionados ao login
	dbSelectArea("AI4")
	dbSetOrder(1)
	MsSeek( _cSeekAI4 := xFilial("AI4")+AI3->AI3_CODUSU )

	// varre todos os clientes do login
	While AI4->(!Eof()).And.(AI4->(AI4_FILIAL+AI4_CODUSU) == _cSeekAI4)

		// posiciona no cadastro do cliente
		dbSelectArea("SA1")
		dbSetOrder(1)
		MsSeek( xFilial("SA1")+AI4->AI4_CODCLI+AI4->AI4_LOJCLI )

		// cria linha para incluir os dados do cliente
		AAdd(mvObjRet:UserClientes,WSClassNew("StListaClientes"))
		_nItem := Len(mvObjRet:UserClientes)

		mvObjRet:UserClientes[_nItem]:cCodigoCliente := AI4->AI4_CODCLI
		mvObjRet:UserClientes[_nItem]:cLojaCliente   := AI4->AI4_LOJCLI
		mvObjRet:UserClientes[_nItem]:cNomeCliente   := SA1->A1_NOME
		mvObjRet:UserClientes[_nItem]:cCnpjCliente   := SA1->A1_CGC

		// variavel de retorno
		_lRetOk := .t.

		// proximo cliente
		dbSelectArea("AI4")
		AI4->(dbSkip())
	EndDo

Return(_lRetOk)

WSSTRUCT StListaClientes
	WSDATA cCodigoCliente AS String
	WSDATA cLojaCliente   AS String
	WSDATA cNomeCliente   AS String
	WSDATA cCnpjCliente   AS String
ENDWSSTRUCT

// ** funcao que retona os periodos do estoque
Static Function sfRetPerEstoque(mvObjRet)
	// variaveis de controle
	local _aOpcoesDisp
	local _cOpcoesSel
	local _nInicPos
	local _nPosOpcao
	local _nItem

	// variavel de retorno
	local _lRetOk := .f.

	// zera a variavel
	mvObjRet:UserPeriodoEstoque := {}

	// extrai as opcoes disponiveis
	_aOpcoesDisp := U_TPRTA003(.f., "PER")

	// extrai o conteudo (opcoes selecionadas) do campo "periodo"
	_cOpcoesSel := AllTrim(AI3->AI3_ZPERIO)

	// varre todas as opcoes selecionadas
	For _nInicPos := 1 to Len(_cOpcoesSel) Step 3

		// pesquisa a opcao selecionada nas opcoes disponiveis
		_nPosOpcao := aScan(_aOpcoesDisp,{|x| (x[1] == SubStr(_cOpcoesSel,_nInicPos,3) ) })

		// caso encontre, adiciona no vetor de retorno
		If (_nPosOpcao > 0)

			// cria linha para incluir os dados do periodo de estoque
			AAdd(mvObjRet:UserPeriodoEstoque,WSClassNew("StListaPeriodoEstoque"))
			_nItem := Len(mvObjRet:UserPeriodoEstoque)

			mvObjRet:UserPeriodoEstoque[_nItem]:cCodPeriodo := _aOpcoesDisp[_nPosOpcao][1]
			mvObjRet:UserPeriodoEstoque[_nItem]:cDscPeriodo := _aOpcoesDisp[_nPosOpcao][2]

			// variavel de retorno
			_lRetOk := .t.

		EndIf

	Next _nInicPos

Return(_lRetOk)

// estrutura retorno de periodo de estoque
WSSTRUCT StListaPeriodoEstoque
	WSDATA cCodPeriodo As String
	WSDATA cDscPeriodo As String
ENDWSSTRUCT

// ** funcao que retona o menu do usuario
Static Function sfRetMenus(mvObjRet)
	// query
	local _cQuery
	local _aTmpDados
	local _nTmpDados
	// menu ordenado
	local _aMenuOrd := {}
	local _nPosMenu
	// niveis dos itens do menu
	local _cNivel     := "01"
	local _cSubNivel  := ""
	local _cCodMnuPai := ""
	// variaveis de controle
	local _nItem

	// variavel de retorno
	local _lRetOk := .f.

	// zera a variavel
	mvObjRet:UserMenus := {}

	// monta query para buscar as filiais que ha movimentacao para os clientes relacionados do usuario logado
	_cQuery := "SELECT AI8_CODMNU, AI8_CODPAI, AI8_TEXTO, AI8_ROTINA, AI8_ORDEM "
	// cad. de menus
	_cQuery += "FROM "+RetSqlName("AI8")+" AI8 "
	// menu por usuario
	_cQuery += "INNER JOIN "+RetSqlName("Z28")+" Z28 ON "+RetSqlCond("Z28")+" AND Z28_PORTAL = AI8_PORTAL AND Z28_CODMNU = AI8_CODMNU "
	// codigo do usuario
	_cQuery += "AND Z28_CODUSU = '"+AI3->AI3_CODUSU+"' "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("AI8")
	_cQuery += "  AND AI8_PORTAL = '000011' "
	// ordem dos dados
	_cQuery += "ORDER BY AI8_CODPAI, AI8_ORDEM"

	// alimenta os dados
	_aTmpDados := U_SqlToVet(_cQuery)

	// organiza os dados, na ordem correta
	For _nTmpMenu := 1 to Len(_aTmpDados)

		// pesquisa no VETOR chave existente

		// estrutura _aMenuOrd
		// 1. Chave/Nivel
		// 2. Cod Menu
		// 3. Cod Menu Pai
		// 4. Descricao
		// 5. Nome da Rotina
		// 6. Ordem

		_nPosMenu := aScan(_aMenuOrd,{|x| (x[2] == _aTmpDados[_nTmpMenu][2]) }) // cod do menu pai

		// se encontrou menu pai
		If (_nPosMenu > 0)

			// utiliza o mesmo nivel
			_cNivel := _aMenuOrd[_nPosMenu][1]

			// novo sub-nivel
			If (_cCodMnuPai != _aTmpDados[_nTmpMenu][2])
				_cCodMnuPai := _aTmpDados[_nTmpMenu][2]
				_cSubNivel  := "01"
			Else
				_cSubNivel  := Soma1(_cSubNivel)
			EndIf

		EndIf

		// inclui o registro no vetor
		aAdd(_aMenuOrd,{AllTrim(_cNivel) + AllTrim(_cSubNivel) ,;
			_aTmpDados[_nTmpMenu][1] ,;
			_aTmpDados[_nTmpMenu][2] ,;
			_aTmpDados[_nTmpMenu][3] ,;
			_aTmpDados[_nTmpMenu][4] ,;
			_aTmpDados[_nTmpMenu][5] })

		// proxima sequencia do nivel
		_cNivel := Soma1(_cNivel)

		// variavel de retorno
		_lRetOk := .t.

	Next _nTmpMenu

	// reorganiza vetor conforme chave
	_aMenuOrd := aSort(_aMenuOrd,,, { |x, y| x[1] < y[1] })

	// alimenta vetor de retorno
	For _nTmpDados := 1 to Len(_aMenuOrd)

		// cria linha para incluir os dados do menu do usuario
		AAdd(mvObjRet:UserMenus,WSClassNew("StListaMenu"))
		_nItem := Len(mvObjRet:UserMenus)

		mvObjRet:UserMenus[_nItem]:cCodMenu    := _aMenuOrd[_nTmpDados][2]
		mvObjRet:UserMenus[_nItem]:cCodMenuPai := _aMenuOrd[_nTmpDados][3]
		mvObjRet:UserMenus[_nItem]:cDescricao  := _aMenuOrd[_nTmpDados][4]
		mvObjRet:UserMenus[_nItem]:cRotina     := _aMenuOrd[_nTmpDados][5]
		mvObjRet:UserMenus[_nItem]:cOrdem      := AllTrim(Str(_aMenuOrd[_nTmpDados][6]))

	Next _nTmpDados

Return(_lRetOk)

// estrutura retorno de estoque de terceiros por produto
WSSTRUCT StListaMenu
	WSDATA cCodMenu    As String
	WSDATA cCodMenuPai As String
	WSDATA cDescricao  As String
	WSDATA cRotina     As String
	WSDATA cOrdem      As String
ENDWSSTRUCT