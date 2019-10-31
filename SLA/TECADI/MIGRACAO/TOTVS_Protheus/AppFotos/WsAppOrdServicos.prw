#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

/*
N = NAO PRECISA
P = PENDENTE ENVIO
R = REALIZADO
C = CANCELADO
O = EM OPERACAO
*/

WSRESTFUL WsAppOrdServicos DESCRIPTION "AppFotos - Relação de Ordens de Servicos Pendentes por Usuário"

// variaveis
WSDATA pCodEmp    AS STRING
WSDATA pCodFil    AS STRING
WSDATA pCodUser   AS STRING
WSDATA pIdSession AS STRING
WSDATA pCodTab    AS STRING
WSDATA pChaveOS   AS STRING

// declaracao dos metodos
WSMETHOD GET DESCRIPTION "AppFotos - GET Relação de Ordens de Servicos Pendentes por Usuário" WSSYNTAX "/AppOrdServicos || /AppOrdServicos/{codigo_empresa, codigo_filial, codigo_usuario, id_session}"
WSMETHOD PUT DESCRIPTION "AppFotos - PUT Relação de Ordens de Servicos Pendentes por Usuário" WSSYNTAX "/AppOrdServicos || /AppOrdServicos/{codigo_empresa, codigo_filial, codigo_tabela, chave_os}"

END WSRESTFUL

WSMETHOD GET WSRECEIVE pCodEmp, pCodFil, pCodUser, pIdSession WSSERVICE WsAppOrdServicos

	// validacao de retorno
	local _lRetOk := .t.
	local _cMsgOk := ""

	Local _lRet := .t.

	local _cRetJson

	// query
	local _cQuery

	// relacao das ordens de servico
	local _aOrdServic := {}
	local _nOrdServic

	// relacao de fotos
	local _aFotos := {}
	local _nFotos

	// codigo de usuario
	local _cCodEmp    := Self:pCodEmp
	local _cCodFil    := Self:pCodFil
	local _cCodUser   := Self:pCodUser
	local _cIdSession := Self:pIdSession

	// define o tipo de retorno do método
	::SetContentType("application/json; charset=UTF-8;")

	If (_lRetOk) .and. ((ValType(_cCodEmp) != "C") .or. (ValType(_cCodFil) != "C") .or. (ValType(_cCodUser) != "C") .or. (ValType(_cIdSession) != "C"))
		SetRestFault(1000, EncodeUTF8("Obrigatório informar código da empresa, filial e usuário"))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cCodEmp))
		SetRestFault(1000, EncodeUTF8("Empresa não informada."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (_cCodEmp != "01")
		SetRestFault(1000, EncodeUTF8("Empresa não configurada para uso de App Fotos."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cCodFil))
		SetRestFault(1000, EncodeUTF8("Filial não informada."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cCodUser))
		SetRestFault(1000, EncodeUTF8("Usuário não informado."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cIdSession))
		SetRestFault(1000, EncodeUTF8("ID Session não informada."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. ( ! (_cCodFil $ "103/104/105/106") )
		SetRestFault(1000, EncodeUTF8("Filial não configurada para uso do App de Fotos."))
		_lRetOk := .F.
	EndIf


	// prepara o ambiente para o usuario + empresa + filial selecionada
	If (_lRetOk) .and. ((cEmpAnt != _cCodEmp) .or. (cFilAnt != _cCodFil))

		RPCClearEnv()
		RPCSetType(3)

		RpcSetEnv(_cCodEmp, _cCodFil, Nil, Nil, 'WMS',, )

	EndIf

	// valida usuario e senha
	If (_lRetOk)

		// prepara query para buscar ordens de servico pendentes
		_cQuery := " SELECT '01'                      COD_EMP, "
		_cQuery += "        Z6_FILIAL                 COD_FILIAL, "
		_cQuery += "        'SZ6'                     COD_TABELA, "
		_cQuery += "        Substring(Z6_NUMOS, 1, 6) CHAVE_OS, "
		_cQuery += "        Z6_CLIENTE                COD_CLIENTE, "
		_cQuery += "        Z6_LOJA                   LOJ_CLIENTE, "
		_cQuery += "        A1_NOME                   NOM_CLIENTE, "
		_cQuery += "        Z6_EMISSAO                DATA_EMISSAO, "
		_cQuery += "        CASE "
		_cQuery += "          WHEN Z6_TIPOMOV = 'E' THEN 'RECEBIMENTO' "
		_cQuery += "          WHEN Z6_TIPOMOV = 'S' THEN 'CARREGAMENTO' "
		_cQuery += "          WHEN Z6_TIPOMOV = 'I' THEN 'INTERNO' "
		_cQuery += "        END                       TIPO_OPER, "
		_cQuery += "        Z6_PLACA1                 PLACA, "
		_cQuery += "        Z6_CONTAIN                NR_CONTAINER, "
		_cQuery += "        Z6_USRINC                 COD_ACCOUNT "
		// cab. ordem servico
		_cQuery += " FROM   " + RetSqlTab("SZ6")
		_cQuery += "        LEFT JOIN " + RetSqlTab("SA1")
		_cQuery += "               ON " + RetSqlCond("SA1")
		_cQuery += "                  AND A1_COD = Z6_CLIENTE "
		_cQuery += "                  AND A1_LOJA = Z6_LOJA "
		// filtro padrao
		_cQuery += " WHERE  " + RetSqlCond("SZ6")
		_cQuery += "        AND Z6_FOTO = 'P' "
		_cQuery += "        AND Z6_USRFOTO = '" + _cCodUser + "' "
		// agrupamento de dados
		_cQuery += " GROUP  BY Z6_FILIAL, "
		_cQuery += "           Substring(Z6_NUMOS, 1, 6), "
		_cQuery += "           Z6_CLIENTE, "
		_cQuery += "           Z6_LOJA, "
		_cQuery += "           A1_NOME, "
		_cQuery += "           Z6_EMISSAO, "
		_cQuery += "           Z6_TIPOMOV, "
		_cQuery += "           Z6_PLACA1, "
		_cQuery += "           Z6_CONTAIN, "
		_cQuery += "           Z6_USRINC "

		// dados temporarios
		_aOrdServic := U_SqlToVet(_cQuery, {"DATA_EMISSAO"})

		// trata retorno
		If (Len(_aOrdServic) == 0)
			SetRestFault(1000, EncodeUTF8("Não há ordens de serviço pendentes"))
			_lRetOk := .f.
		EndIf

		// gera json de retorno
		If (_lRetOk)

			_cRetJson := ''
			_cRetJson += '{'
			_cRetJson += '"user_codigo":"'+_cCodUser+'",'

			_cRetJson += '"rel_ordens_servico":['

			For _nOrdServic := 1 to Len(_aOrdServic)

				// prepara query para buscar fotos x servico x cliente da ordem de servico
				_cQuery := " SELECT DISTINCT Z25_CODFOT, "
				_cQuery += "                 Z23_DESCRI, "
				_cQuery += "                 CONVERT(VARCHAR(8000), CONVERT(VARBINARY(8000), Z23_INSTR)) AS Z23_INSTR, "
				_cQuery += "                 Z25_QUANT, "
				_cQuery += "                 Z25_OBRIGA, "
				_cQuery += "                 Z25_ORDEM "
				_cQuery += " FROM   " + RetSqlTab("SZ7")
				_cQuery += "        INNER JOIN " + RetSqlTab("SZ6")
				_cQuery += "                ON " + RetSqlCond("SZ6")
				_cQuery += "                   AND Z6_NUMOS = Z7_NUMOS "
				_cQuery += "        INNER JOIN " + RetSqlTab("z25")
				_cQuery += "                ON " + RetSqlCond("Z25")
				_cQuery += "                   AND Z25_ORIGEM = 'SZ6' "
				_cQuery += "                   AND Z25_SERVIC = Z7_CODATIV "
				_cQuery += "                   AND Z25_CODCLI = Z6_CLIENTE "
				_cQuery += "                   AND Z25_LOJCLI = Z6_LOJA "
				_cQuery += "        INNER JOIN " + RetSqlTab("Z23")
				_cQuery += "                ON " + RetSqlCond("Z23")
				_cQuery += "                   AND Z23_CODIGO = Z25_CODFOT "
				_cQuery += " WHERE  " + RetSqlCond("SZ7")
				_cQuery += "        AND Substring(Z7_NUMOS, 1, 6) = '" + _aOrdServic[_nOrdServic][4] + "' "
				_cQuery += " ORDER  BY Z25_ORDEM "

				// atualiza relacao de fotos por ordem de servico
				_aFotos := U_SqlToVet(_cQuery)

				// trata retorno
				If (Len(_aFotos) == 0)
					// mensagem de retorno
					SetRestFault(1000, EncodeUTF8("Não há relação de fotos definidas para a Ordem de Serviço " + _aOrdServic[_nOrdServic][4]))
					// controle de processamento
					_lRetOk := .f.
					// sai do loop
					Exit
				EndIf

				_cRetJson += '{"ordem_servico":['

				_cRetJson += '{'
				_cRetJson += '"cod_empresa":"'  + AllTrim(_aOrdServic[_nOrdServic][1])  + '",'
				_cRetJson += '"cod_filial":"'   + AllTrim(_aOrdServic[_nOrdServic][2])  + '",'
				_cRetJson += '"cod_tabela":"'   + AllTrim(_aOrdServic[_nOrdServic][3])  + '",'
				_cRetJson += '"chave_ordsrv":"' + AllTrim(_aOrdServic[_nOrdServic][4])  + '",'
				_cRetJson += '"cod_cliente":"'  + AllTrim(_aOrdServic[_nOrdServic][5])  + '",'
				_cRetJson += '"loj_cliente":"'  + AllTrim(_aOrdServic[_nOrdServic][6])  + '",'
				_cRetJson += '"nom_cliente":"'  + AllTrim(_aOrdServic[_nOrdServic][7])  + '",'
				_cRetJson += '"dt_emissao":"'   + DtoC(_aOrdServic[_nOrdServic][8])     + '",'
				_cRetJson += '"tip_operacao":"' + AllTrim(_aOrdServic[_nOrdServic][9])  + '",'
				_cRetJson += '"placa_1":"'      + AllTrim(_aOrdServic[_nOrdServic][10]) + '",'
				_cRetJson += '"nr_container":"' + AllTrim(_aOrdServic[_nOrdServic][11]) + '",'
				_cRetJson += '"nom_account":"'  + AllTrim(UsrFullName(_aOrdServic[_nOrdServic][12])) + '",'

				_cRetJson 	+='"relacao_fotos":['

				For _nFotos := 1 to Len(_aFotos)

					_cRetJson += '{'
					_cRetJson += '"cod_foto":"'    + AllTrim(_aFotos[_nFotos][1])      + '",'
					_cRetJson += '"desc_foto":"'   + AllTrim(_aFotos[_nFotos][2])      + '",'
					_cRetJson += '"instr_foto":"'  + AllTrim(_aFotos[_nFotos][3])      + '",'
					_cRetJson += '"qtd_foto":'     + AllTrim(Str(_aFotos[_nFotos][4])) + ','
					_cRetJson += '"obrigatorio":"' + AllTrim(_aFotos[_nFotos][5])      + '",'
					_cRetJson += '"ordem":"'       + AllTrim(_aFotos[_nFotos][6])      + '"}'

					IF _nFotos < Len(_aFotos)
						_cRetJson += ','
					EndIf

				Next _nFotos

				// fecha relacao de fotos
				_cRetJson += ']}]}'

				IF _nOrdServic < LEN( _aOrdServic )
					_cRetJson += ','
				EndIf

			NEXT _nOrdServic

			_cRetJson 	+=']}'

		EndIf

	EndIf

	If (_lRetOk)
		::SetResponse(EncodeUTF8(_cRetJson))
	EndIf


Return(_lRetOk)

WSMETHOD PUT WSRECEIVE pCodEmp, pCodFil, pCodUser, pIdSession, pCodTab, pChaveOS WSSERVICE WsAppOrdServicos

	local _lRetOk := .t.

	local _cCodEmp    := Self:pCodEmp
	local _cCodFil    := Self:pCodFil
	local _cCodUser   := Self:pCodUser
	local _cIdSession := Self:pIdSession
	local _cCodTab    := Self:pCodTab
	local _cChaveOS   := Self:pChaveOS

	// numero da ordem de servico
	local _cNrOrdSrv

	// variaveis temporarias
	local _aTmpDados
	local _nRecSZ6

	// query
	local _cQuery

	// define o tipo de retorno do método
	::SetContentType("application/json; charset=UTF-8;")

	If (_lRetOk) .and. ((ValType(_cCodEmp) != "C") .or. (ValType(_cCodFil) != "C") .or. (ValType(_cCodUser) != "C") .or. (ValType(_cIdSession) != "C")  .or. (ValType(_cCodTab) != "C")  .or. (ValType(_cChaveOS) != "C") )
		SetRestFault(1000, EncodeUTF8("Obrigatório informar código da empresa, filial, usuário, id session, código da tabela e chave da ordem de serviço."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cCodEmp))
		SetRestFault(1000, EncodeUTF8("Empresa não informada."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cCodFil))
		SetRestFault(1000, EncodeUTF8("Filial não informada."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cCodUser))
		SetRestFault(1000, EncodeUTF8("Usuário não informado."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cIdSession))
		SetRestFault(1000, EncodeUTF8("ID Session não informada."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cCodTab))
		SetRestFault(1000, EncodeUTF8("Tabela não informada."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cChaveOS))
		SetRestFault(1000, EncodeUTF8("Chave da ordem de serviço não informada."))
		_lRetOk := .F.
	EndIf

	// prepara o ambiente para o usuario + empresa + filial selecionada
	If (_lRetOk) .and. ((cEmpAnt != _cCodEmp) .or. (cFilAnt != _cCodFil))

		RPCClearEnv()
		RPCSetType(3)

		RpcSetEnv(_cCodEmp, _cCodFil, Nil, Nil,'WMS',, )

	EndIf

	If (_lRetOk)

		If (AllTrim(Upper(_cCodTab)) == "SZ6")

			// define o numero da ordem de servico
			_cChaveOS := PadR(_cChaveOS, 6)

			// pesquisa a ordem de servico
			_cQuery := " SELECT SZ6.R_E_C_N_O_ SZ6RECNO "
			_cQuery += " FROM   " + RetSqlTab("SZ6")
			_cQuery += " WHERE  " + RetSqlCond("SZ6")
			_cQuery += "        AND Z6_FOTO = 'P' "
			_cQuery += "        AND Z6_USRFOTO = '" + _cCodUser + "' "
			_cQuery += "        AND Substring(Z6_NUMOS, 1, 6) = '" + _cChaveOS + "' "
			_cQuery += " ORDER  BY SZ6.R_E_C_N_O_ "

			// atualiza variavel temporaria
			_aTmpDados := U_SqlToVet(_cQuery)

			// se nao encontrar dados
			If (Len(_aTmpDados) == 0)
				SetRestFault(2000, EncodeUTF8("Ordem de Serviço " + _cChaveOS + " não localizada."))
				_lRetOk := .F.

			ElseIf (Len(_aTmpDados) != 0)
				// varre todas as sequencias da ordem de servico
				For _nRecSZ6 := 1 to Len(_aTmpDados)

					// posiciona no registro real
					dbSelectArea("SZ6")
					SZ6->(dbGoTo( _aTmpDados[_nRecSZ6] ))

					// marca status de recebido no App
					RecLock("SZ6")
					SZ6->Z6_FOTO := "O" // O=EM OPERACAO
					SZ6->(MsUnLock())

					// gera log
					U_FtGeraLog(xFilial("SZ6"), "SZ6", SZ6->Z6_FILIAL + SZ6->Z6_NUMOS, "AppFotos: Ordem de Serviço Enviada para o Aplicativo. Status EM OPERACAO", "WMS", SZ6->Z6_CODIGO, _cCodUser)

				Next _nRecSZ6
			EndIf
		EndIf

	EndIf

	If (_lRetOk)
		::SetResponse(EncodeUTF8('{"status": 1003,"chave_ordsrv":"' + _cChaveOS + '","msg":"Ord Servico enviada com sucesso." }'))
	EndIf

Return(_lRetOk)