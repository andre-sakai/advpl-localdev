#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Funcoes Genericas utilizadas no Portal                  !
!                  ! 1. Geracao de senha/session aleatoria                   !
!                  ! 2. Geracao de array com a quebra de datas por periodo   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 09/2011                                                 !
+------------------+--------------------------------------------------------*/

// ** funcao que gera uma senha aleatoria / usada para criar ChaveSession Generica
User Function FtGeraPsw(mvTamanho)
	// variavel base
	local _cTmpCaract := "abcdefghijklmnopqrstuvxyzABCDEFGHIJKLMNOPQRSTUVXYZ0123456789"
	local _nTamSenha  := mvTamanho
	local _nX
	local _nPos
	local _cRetPsw := ""

	// varre o tamanho maximo da senha
	For _nX := 1 to _nTamSenha

		// extrai um numero aleatorio
		_nPos := Randomize (1,Len(_cTmpCaract))
		// complemento da variavel de retorno
		_cRetPsw += SubStr(_cTmpCaract,_nPos,1)

	Next _nX

Return(_cRetPsw)

// ** funcao para gerar periodos
User Function FtPrtPeri(mvDataDe, mvDataAte, mvTipoPer)
	// variavel de retorno
	local _aRetPeriodo := {}
	// variavel de controle
	local _dTmpData
	local _dTmpDtIni
	local _dTmpDtFim
	// data inicial limite
	local _dDtIniLim := CtoD("01/01/2010")
	
	local nStart := Seconds()

	// se a "Data De" for menor que a data inicial limite
	If (mvDataDe < _dDtIniLim)
		mvDataDe := _dDtIniLim
	EndIf

	// se a "Data Até" for maior que a data atual
	If (mvDataAte > Date())
		mvDataAte := Date()
	EndIf


	// prepara vetor para extracao de dados
	If (mvTipoPer == "DIA") // por dia
		// define os periodos para extracao de dados
		aAdd(_aRetPeriodo,{ mvDataDe, mvDataAte, HS_DtoC(mvDataDe,2)+" a "+HS_DtoC(mvDataAte,2) })

	ElseIf (mvTipoPer == "QUI") // por quinzena

		FwLogMsg("INFO", /*cTransactionId*/, "mvTipoPer", FunName(), "", "01", "QUINZENA", 0, (nStart - Seconds()), {}) // nStart é declarada no inicio da função

		// inicia variavel da data
		_dTmpData := mvDataDe

		FwLogMsg("INFO", /*cTransactionId*/, "mvTipoPer", FunName(), "", "01", "QUINZENA -> Date De  "+DtoC(_dTmpData), 0, (nStart - Seconds()), {}) // nStart é declarada no inicio da função
		FwLogMsg("INFO", /*cTransactionId*/, "mvTipoPer", FunName(), "", "01", "QUINZENA -> Date Ate "+DtoC(mvDataAte), 0, (nStart - Seconds()), {}) // nStart é declarada no inicio da função

		// loop enquanto "Data De" for menor que "Data Até"
		While (_dTmpData <= mvDataAte)

			// define data inicial
			_dTmpDtIni := FirstDay(_dTmpData)

			If (_dTmpDtIni < _dTmpData)
				_dTmpDtIni := _dTmpData
			EndIf

			FwLogMsg("INFO", /*cTransactionId*/, "mvTipoPer", FunName(), "", "01", "Data Ini "+DtoC(_dTmpDtIni), 0, (nStart - Seconds()), {}) // nStart é declarada no inicio da função

			// define data final
			If (Day(_dTmpDtIni) < 15)
				_dTmpDtFim := CtoD("15/"+SubS(DtoC(_dTmpDtIni),4))
			Else
				_dTmpDtFim := LastDay(_dTmpDtIni)
			EndIf

			If (_dTmpDtFim > mvDataAte)
				_dTmpDtFim := mvDataAte
			EndIf

			If (_dTmpDtFim > Date())
				_dTmpDtFim := Date()
			EndIf

			FwLogMsg("INFO", /*cTransactionId*/, "mvTipoPer", FunName(), "", "01", "Data Fim "+DtoC(_dTmpDtFim), 0, (nStart - Seconds()), {}) // nStart é declarada no inicio da função

			// adiciona o dia no vetor
			aAdd(_aRetPeriodo,{ _dTmpDtIni, _dTmpDtFim, HS_DtoC(_dTmpDtIni,2)+" a "+HS_DtoC(_dTmpDtFim,2) })

			// incrementa um dia (primeiro dia do mes subsequente)
			_dTmpData := (_dTmpDtFim + 1)

		EndDo

	ElseIf (mvTipoPer == "MES") // por mes

		// inicia variavel da data
		_dTmpData := mvDataDe

		// loop enquanto "Data De" for menor que "Data Até"
		While (_dTmpData <= mvDataAte)

			// define data inicial
			_dTmpDtIni := FirstDay(_dTmpData)

			If (_dTmpDtIni < _dTmpData)
				_dTmpDtIni := _dTmpData
			EndIf

			FwLogMsg("INFO", /*cTransactionId*/, "mvTipoPer", FunName(), "", "01", "Data Ini "+DtoC(_dTmpDtIni), 0, (nStart - Seconds()), {}) // nStart é declarada no inicio da função

			// define data final
			_dTmpDtFim := LastDay(_dTmpData)

			If (_dTmpDtFim > mvDataAte)
				_dTmpDtFim := mvDataAte
			EndIf

			If (_dTmpDtFim > Date())
				_dTmpDtFim := Date()
			EndIf

			FwLogMsg("INFO", /*cTransactionId*/, "mvTipoPer", FunName(), "", "01", "Data Fim "+DtoC(_dTmpDtFim), 0, (nStart - Seconds()), {}) // nStart é declarada no inicio da função

			// adiciona o dia no vetor
			aAdd(_aRetPeriodo,{ _dTmpDtIni, _dTmpDtFim, Left(MesExtenso(_dTmpDtIni),3)+"/"+Str(Year(_dTmpDtIni),4) })

			// incrementa um dia (primeiro dia do mes subsequente)
			_dTmpData := (_dTmpDtFim + 1)

		EndDo

	EndIf

Return(_aRetPeriodo)

// ** funcao que valida os dados do login
// cod cliente
// periodo
// tipo de estoque
User Function FtPrtLgn(mvLogin, mvCodCli, mvLojCli, mvTpPeriodo, mvTpEstoque)
	// variavel de retorno
	local _lRet := .f.
	// query
	local _cQuery

	// dados
	local _aDadosLog := {}

	// valores padroes
	Default mvTpPeriodo := ""
	Default mvTpEstoque := ""

	// monta a query para validar os dados do login
	_cQuery := "SELECT AI3_CODUSU, AI3_LOGIN, AI3_ZPERIO, AI3_ZTPEST, AI4_CODCLI, AI4_LOJCLI "
	// cad. de login
	_cQuery += "FROM "+RetSqlName("AI3")+" AI3 "
	// clientes do login
	_cQuery += "INNER JOIN "+RetSqlName("AI4")+" AI4 ON "+RetSqlCond("AI4")+" AND "
	// cod do usuario
	_cQuery += "AI4_CODUSU = AI3_CODUSU "
	// codigo e loja do cliente
	_cQuery += "AND AI4_CODCLI = '"+mvCodCli+"' AND AI4_LOJCLI = '"+mvLojCli+"' "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("AI3")
	// login
	_cQuery += "AND AI3_LOGIN = '"+AllTrim(mvLogin)+"' "
	// tipo de periodo
	If (! Empty(mvTpPeriodo))
		_cQuery += "AND AI3_ZPERIO LIKE '%"+AllTrim(Upper(mvTpPeriodo))+"%' "
	EndIf
	// tipo de estoque
	If (! Empty(mvTpEstoque))
		_cQuery += "AND AI3_ZTPEST LIKE '%"+AllTrim(Upper(mvTpEstoque))+"%' "
	EndIf

	// alimenta os dados
	_aDadosLog := U_SqlToVet(_cQuery)

	// variavel de retorno
	_lRet := (Len(_aDadosLog) > 0)

Return(_lRet)

// ** funcao que valida acessos do usuario logado no portal
User Function FtPrtVld(mvIdUser)

	// variaveis temporarias
	local _cSeekAI3, _cSeekAI4
	local _nQtdLogin := 0
	local _nQtdCliente := 0
	local _cCodUser

	// variavel de controle
	local _lTudoOk := .T.

	// query
	local _cQrySession

	// Registro da Session ID
	local _nRegSession := 0

	// controle para criar registro do login (ver variavel em SIGAESP)
	local _lAddLogin := ___aPrtLogin[5]

	// valor padrao de variaveis
	Default mvIdUser := Space(Len(__cUserId))

	// zera variaveis publicas
	___aPrtDepos := {}
	___aPrtSigla := {}

	// pesquisa se o cadastro do usuario está correto
	If (_lTudoOk)
		dbSelectArea("AI3")
		AI3->(dbOrderNickName("AI3USRSIS")) // 4-AI3_FILIAL + AI3_USRSIS
		If ! AI3->(dbSeek( _cSeekAI3 := xFilial("AI3") + mvIdUser ))
			// mensagem
			Help(,,'Help',,"Usuário Interno não configurado para este login. Favor acessar o cadastro de usuários do portal de clientes e definir o campo usuário interno.",1,0)
			// variavel de controle
			_lTudoOk := .F.
		EndIf

		// atualiza variavel publica com o email conforme cadastro
		___aPrtLogin[8] := AI3->AI3_EMAIL
	EndIf

	// valida se o login está em apenas um usuario
	If (_lTudoOk)
		While AI3->( ! Eof() ) .And. ((AI3->AI3_FILIAL + AI3->AI3_USRSIS) == _cSeekAI3)
			// controle
			_nQtdLogin ++
			// armazena codigo do usario do portal
			_cCodUser := AI3->AI3_CODUSU
			// proximo registro
			AI3->( dbSkip() )
		EndDo

		// valida quantidade de registros
		If (_nQtdLogin != 1)
			// mensagem
			Help(,,'Help',,"Usuário com múltiplos logins internos definidos. Favor solicitar o agrupamento de cadastro em um único login.",1,0)
			// variavel de controle
			_lTudoOk := .F.
		EndIf
	EndIf

	// pesquisa os clientes relacionados ao login
	If (_lTudoOk)
		dbSelectArea("AI4")
		AI4->(dbSetOrder(1)) // 1-AI4_FILIAL, AI4_CODUSU, AI4_CODCLI, AI4_LOJCLI
		AI4->(MsSeek( _cSeekAI4 := xFilial("AI4") + _cCodUser ))

		// varre todos os clientes do login
		While AI4->( ! Eof() ) .And. ((AI4->AI4_FILIAL + AI4->AI4_CODUSU) == _cSeekAI4)

			// posiciona no cadastro do cliente
			dbSelectArea("SA1")
			SA1->(dbSetOrder(1)) // 1-A1_FILIAL, A1_COD, A1_LOJA
			SA1->(MsSeek( xFilial("SA1") + AI4->AI4_CODCLI + AI4->AI4_LOJCLI ))

			// lida com os dados do cliente
			aAdd(___aPrtDepos,{;
			AI4->AI4_CODCLI ,;
			AI4->AI4_LOJCLI ,;
			SA1->A1_NOME    ,;
			SA1->A1_CGC     })

			// controle
			_nQtdCliente ++

			// verifica relacao de siglas
			If (aScan( ___aPrtSigla, {|x| (x == SA1->A1_SIGLA) } ) == 0)
				aAdd(___aPrtSigla, SA1->A1_SIGLA)
			EndIf

			// proximo cliente
			dbSelectArea("AI4")
			AI4->(dbSkip())
		EndDo

		// valida quantidade de registros
		If (_nQtdCliente == 0)
			// mensagem
			Help(,,'Help',,"Usuário sem cliente/depositante definido. Favor solicitar o cadastro de Cliente x Login.",1,0)
			// variavel de controle
			_lTudoOk := .F.
		EndIf

	EndIf

	// gera IdSession / Token
	If (_lTudoOk) .And. (_lAddLogin)

		// gera o registro da session
		_cQrySession := " INSERT INTO PORTAL_SESSION ( "
		_cQrySession += " SESSION_ID, SESSION_FILIAL, SESSION_CLIENTE, SESSION_LOJA, SESSION_LOGIN, SESSION_ORIGEM, SESSION_PCNAME ) "
		_cQrySession += " VALUES ( "
		_cQrySession += " '" + ___cPrtToken + "', "
		_cQrySession += " '" + cFilAnt + "', "
		_cQrySession += " '', "
		_cQrySession += " '', "
		_cQrySession += " '" + UsrRetName(__cUserId) + "', "
		_cQrySession += " '', "
		_cQrySession += " '" + ___aPrtLogin[4] + "') "

		// grava reg no banco
		TcSqlExec(_cQrySession)

		// marca que o login foi atualizado
		_lAddLogin := .F.

		// marca variavel publica
		___aPrtLogin[5] := _lAddLogin

		// atualiza variavel publica com o codigo do usuario
		___aPrtLogin[6] := __cUserId

		// atualiza variavel publica com o User Name (nome do usuario)
		___aPrtLogin[7] := UsrRetName(__cUserId)


	EndIf

	// atualiza data de expiracao da session do login
	If (_lTudoOk) .And. ( ! _lAddLogin )

		// monta a query
		_cQrySession := "SELECT TOP 1 SESSION_REG "
		_cQrySession += "  FROM PORTAL_SESSION "
		_cQrySession += " WHERE SESSION_ID       = '" + ___cPrtToken + "' "
		_cQrySession += "   AND SESSION_LOGIN    = '" + ___aPrtLogin[7] +"' "

		// busca o Registro da ID Session
		_nRegSession := U_FtQuery(_cQrySession)

		// nao ha mais session ativa
		If (_nRegSession == 0)
			// mensagem
			Help(,,'SESSÃO INVÁLIDA',,"Sessão do Login Expirou. Favor realizar novo login",1,0)
			// variavel de controle
			_lTudoOk := .F.

			// quando encontrar o primeiro acesso, atualiza dados
		ElseIf (_nRegSession != 0)

			// atualiza a data de expiracao do login
			_cQrySession := "UPDATE PORTAL_SESSION "
			_cQrySession += "   SET SESSION_EXPIRED = DATEADD(MI,15,GETDATE()) "
			_cQrySession += " WHERE SESSION_ID      = '" + ___cPrtToken + "' "
			_cQrySession += "   AND SESSION_LOGIN   = '" + UsrRetName(__cUserId) + "' "
			_cQrySession += "   AND SESSION_REG     = " + AllTrim(Str(_nRegSession))

			// grava reg no banco
			TcSQLExec(_cQrySession)

		EndIf

	EndIf

Return(_lTudoOk)