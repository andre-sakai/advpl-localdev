#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#Include 'Protheus.ch'
#Include 'FWMVCDEF.ch'

/* ==== CRIACAO DE TABELA DE SESSION APPFOTOS_SESSION ====

CREATE TABLE [dbo].[APPFOTOS_SESSION](
[SESSION_REG] [int] IDENTITY(1,1) NOT NULL,
[SESSION_ID] [varchar](32) NOT NULL,
[SESSION_DATA] [datetime] NOT NULL,
[SESSION_EXPIRED] [datetime] NOT NULL,
[SESSION_FILIAL] [varchar](3) NOT NULL,
[SESSION_CLIENTE] [varchar](6) NOT NULL,
[SESSION_LOJA] [nchar](2) NOT NULL,
[SESSION_LOGIN] [varchar](30) NOT NULL,
[SESSION_ORIGEM] [varchar](30) NOT NULL,
[SESSION_PCNAME] [varchar](30) NOT NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[APPFOTOS_SESSION] ADD  CONSTRAINT [DF_APPFOTOS_SESSION_SESSIONID]  DEFAULT ('') FOR [SESSION_ID]
GO

ALTER TABLE [dbo].[APPFOTOS_SESSION] ADD  CONSTRAINT [DF_APPFOTOS_SESSION_SESSION_DATA]  DEFAULT (getdate()) FOR [SESSION_DATA]
GO

ALTER TABLE [dbo].[APPFOTOS_SESSION] ADD  CONSTRAINT [DF_APPFOTOS_SESSION_SESSION_EXPIRED]  DEFAULT (dateadd(minute,(5),getdate())) FOR [SESSION_EXPIRED]
GO

ALTER TABLE [dbo].[APPFOTOS_SESSION] ADD  CONSTRAINT [DF_APPFOTOS_SESSION_SESSION_FILIAL]  DEFAULT ('') FOR [SESSION_FILIAL]
GO

ALTER TABLE [dbo].[APPFOTOS_SESSION] ADD  CONSTRAINT [DF_APPFOTOS_SESSION_SESSION_CLIENTE]  DEFAULT ('') FOR [SESSION_CLIENTE]
GO

ALTER TABLE [dbo].[APPFOTOS_SESSION] ADD  CONSTRAINT [DF_APPFOTOS_SESSION_SESSION_LOJA]  DEFAULT ('') FOR [SESSION_LOJA]
GO

ALTER TABLE [dbo].[APPFOTOS_SESSION] ADD  CONSTRAINT [DF_APPFOTOS_SESSION_SESSION_LOGIN]  DEFAULT ('') FOR [SESSION_LOGIN]
GO

ALTER TABLE [dbo].[APPFOTOS_SESSION] ADD  CONSTRAINT [DF_APPFOTOS_SESSION_SESSION_ORIGEM]  DEFAULT ('') FOR [SESSION_ORIGEM]
GO

ALTER TABLE [dbo].[APPFOTOS_SESSION] ADD  CONSTRAINT [DF_APPFOTOS_SESSION_SESSION_PCNAME]  DEFAULT ('') FOR [SESSION_PCNAME]
GO
*/

WSRESTFUL WsAppFotosLogin DESCRIPTION "AppFotos - Validações de Usuários / Senhas"

// variaveis
WSDATA pCodUser AS STRING
WSDATA pPswUser AS STRING

// declaracao dos metodos
WSMETHOD GET DESCRIPTION "Validação do Login do usuário" WSSYNTAX "/AppFotosLogin || /AppFotosLogin/{pCodUser, pPswUser}"

END WSRESTFUL

WSMETHOD GET WSRECEIVE pCodUser, pPswUser WSSERVICE WsAppFotosLogin

	// validacao de retorno
	local _lRetOk := .T.
	local _cMsgOk := ""
	local _lUsrOk := .F.

	// codigo de usuario
	local _cCodUser := Self:pCodUser
	local _cNomUser := IIf(Len(AllTrim(_cCodUser)) == 6, "", _cCodUser )
	Local _cPswUser := Self:pPswUser

	Local _lRet    := .T.
	Local aAux     := {}
	local nAux
	Local oUser    := MPUserAccount():New()
	Local nRetorno := 0
	Local _cUsrAdm := .F.
	Local _cQuery  := ""

	local _cRetJson

	// id da sessao
	local _cIdSession := ""

	// informacoes do usuario
	local _aTmpDados := {}

	// define o tipo de retorno do método
	::SetContentType("application/json;charset=UTF-8")

	If (_lRetOk) .and. ((ValType(_cCodUser) != "C") .or. (ValType(_cPswUser) != "C"))
		SetRestFault(1000, EncodeUTF8("Obrigatório informar usuário e senha para acesso."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk).and.(Empty(_cCodUser))
		SetRestFault(1000, EncodeUTF8("Usuário não informado."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk).and.(Empty(_cPswUser))
		SetRestFault(1000, EncodeUTF8("Senha não informada."))
		_lRetOk := .F.
	EndIf

	// pesquisa pelo codigo do usuario (1 - ID do usuário/grupo / 2 - Nome do usuário/grupo)
	If (_lRetOk) .and. ( Empty(_cNomUser) ) .and. ( ! _lUsrOk )

		// ordem 1-codigo
		PswOrder(1)
		// pesquisa pelo codigo do usuario
		If (PswSeek(_cCodUser, .T.))
			// retorna as informacoes do usuario
			_aTmpDados := PswRet()
			// atualiza nome do usuario (login)
			_cNomUser := _aTmpDados[1][2]
			// usuario encontrado
			_lUsrOk := .t.
		EndIf
	EndIf

	// pesquisa pelo login do usuario (1 - ID do usuário/grupo / 2 - Nome do usuário/grupo)
	If (_lRetOk) .and. ( ! Empty(_cNomUser) ) .and. ( ! _lUsrOk )

		// ordem 2-nome
		PswOrder(2)
		// pesquisa pelo codigo do usuario
		If (PswSeek(_cNomUser, .T.))
			// retorna as informacoes do usuario
			_aTmpDados := PswRet()
			// atualiza nome do usuario (login)
			_cNomUser := _aTmpDados[1][2]
			// variavel de retorno
			_lUsrOk := .t.
		EndIf
	EndIf

	// valida usuario e senha
	If (_lRetOk)

		// Inicializa a classe de autenticação de usuário
		oUser:Activate()

		// Verifica se a autenticação pelo SO é válida
		nRetorno := oUser:SignOnAuthentication(.T.)

		If nRetorno == 0
			nRetorno :=  oUser:Authentication(_cNomUser, _cPswUser)

			If nRetorno == 0
				SetRestFault(1000, EncodeUTF8("Usuário " + _cCodUser + " não autorizado."))
				_lRetOk := .f.
			EndIf
		EndIf

		// valida acessos
		If (_lRetOk)
			// define ordem de pesquisa
			PswOrder(1)

			// pesquisa pelo codigo do usuario
			If (PswSeek(oUser:cUserId, .T.))
				__Ap5NoMv(.T.)
				aUser := PswRet()
				__Ap5NoMv(.F.)
				c_CodUsr := aUser[1,1]
				cUsuario := aUser[1,2]

				// dados auxiliares
				aAux := aClone(sfRetEmpFil(Aclone(aUser[2][6])))

			EndIf
		EndIf

	EndIf


	// gera ID da session do usuario
	If (_lRetOk)
		RPCClearEnv()
		RpcSetEnv(aAux[1][1], aAux[1][3], _cCodUser, _cPswUser, 'WMS',, )
		// gera ID da session do usuario
		_lRetOk := sfRetIdSession(@_cIdSession)

	EndIf

	If (_lRetOk)

		// busca a categoria para saber se pode acessar o menu administrativo
		
		_cQuery  := "SELECT DCD_ZCATEG FROM " + RetSqlTab("DCD") + " WHERE " + RetSqlCond("DCD") + " AND DCD_CODFUN = '" + __cUserId + "'"
		_cUsrAdm := (U_FTQuery(_cQuery) $ "G|S")

		_cRetJson := ''
		_cRetJson += '{'
		_cRetJson += '"user_codigo":"'  + AllTrim(__cUserId)              +'",'
		_cRetJson += '"user_nome":"'    + AllTrim(UsrFullName(__cUserId)) +'",'
		_cRetJson += '"user_session":"' + AllTrim(_cIdSession)            +'",'

		_cRetJson += '"user_filiais":['
		FOR nAux := 1 to Len(aAux)

			_cRetJson += '{'
			_cRetJson += '"cod_empresa":"' + AllTrim(aAux[nAux][1]) + '",'
			_cRetJson += '"nom_empresa":"' + AllTrim(aAux[nAux][2]) + '",'
			_cRetJson += '"cod_filial":"'  + AllTrim(aAux[nAux][3]) + '",'
			_cRetJson += '"nom_filial":"'  + AllTrim(aAux[nAux][4]) + '"'
			_cRetJson += '}'

			IF nAux  < LEN( aAux )
				_cRetJson += ','
			EndIf

		NEXT nAux
		_cRetJson 	+='],'
		_cRetJson   += '"user_admin":"' + IIF(_cUsrAdm, "sim", "nao") + '"'

		_cRetJson 	+='}'

		::SetResponse(EncodeUTF8(_cRetJson))

	EndIf

Return(_lRetOk)

// ** funcao que retorna as empresas/filiais disponiveis por usuario
Static Function sfRetEmpFil(aEmprx)
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
		DbEval({|| Aadd(aEmprx,M0_CODIGO+FWCODFIL())})
	Endif

	If Empty(aEmprx)
		Final("Arquivo Empresa Corrompido") //
	EndIf

	DbGoTop()
	While !Eof()
		If Ascan(aEmprx,M0_CODIGO+FWCODFIL()) <> 0
			Aadd(aChoice,{SM0->M0_CODIGO, Alltrim(Upper(SM0->M0_NOME)), AllTrim(SM0->M0_CODFIL), AllTrim(SM0->M0_FILIAL) })
		EndIf
		DbSkip()
	EndDo

Return aClone(aChoice)

// ** funcao que cria o ID Session
Static Function sfRetIdSession(mvIdSession)
	// ID Session
	local _cTmpId
	// query
	local _cQrySession

	// cria um ID session
	_cTmpId := __cUserId
	_cTmpId += DtoS(Date())
	_cTmpId += Time()
	_cTmpId += StrZero(ThreadID(),10)

	// cript da Id Session
	_cTmpId := Md5(_cTmpId)

	// gera o registro da session
	_cQrySession := "INSERT INTO APPFOTOS_SESSION ("
	_cQrySession += "SESSION_ID, SESSION_FILIAL, SESSION_CLIENTE, SESSION_LOJA, SESSION_LOGIN, SESSION_ORIGEM, SESSION_PCNAME ) "
	_cQrySession += "VALUES ("
	_cQrySession += "'"+_cTmpId+"',"
	_cQrySession += "'',"
	_cQrySession += "'',"
	_cQrySession += "'',"
	_cQrySession += "'" + UsrRetName(__cUserId) + "',"
	_cQrySession += "'',"
	_cQrySession += "'')"

	// grava reg no banco
	TcSQLExec(_cQrySession)

	// define variavel de retorno
	mvIdSession := _cTmpId

Return(.t.)