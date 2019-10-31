#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

/*
N = NAO PRECISA
P = PENDENTE ENVIO
R = REALIZADO
C = CANCELADO
O = EM OPERACAO
*/


WSRESTFUL WsAppEnviaFotos DESCRIPTION "AppFotos - Envia Fotos para as Ordens de Servicos"

// variaveis
WSDATA pCodEmp    AS STRING
WSDATA pCodFil    AS STRING
WSDATA pCodUser   AS STRING
WSDATA pIdSession AS STRING
WSDATA pCodTab    AS STRING
WSDATA pChaveOS   AS STRING
WSDATA pStatus    AS STRING
WSDATA pQtdFotos  AS INTEGER
WSDATA pLink      AS STRING
WSDATA pJustCanc  AS STRING


// declaracao dos metodos
WSMETHOD PUT DESCRIPTION "AppFotos - PUT Envia Fotos para as Ordens de Servicos" WSSYNTAX "/AppEnviaFotos || /AppEnviaFotos/{codigo_empresa, codigo_filial, codigo_tabela, chave_os}"

END WSRESTFUL

WSMETHOD PUT WSRECEIVE pCodEmp, pCodFil, pCodUser, pIdSession, pCodTab, pChaveOS, pStatus, pQtdFotos, pLink, pJustCanc WSSERVICE WsAppEnviaFotos

	local _lRetOk := .t.

	local _cCodEmp    := Self:pCodEmp
	local _cCodFil    := Self:pCodFil
	local _cCodUser   := Self:pCodUser
	local _cIdSession := Self:pIdSession
	local _cCodTab    := Self:pCodTab
	local _cChaveOS   := Self:pChaveOS
	local _cStatus    := Self:pStatus
	local _nQtdFotos  := Self:pQtdFotos
	local _cLink      := Self:pLink
	local _cJustCanc  := Self:pJustCanc

	// variaveis temporarias
	local _aTmpDados
	local _nRecSZ6

	// query
	local _cQuery

	// status do Log
	local _cStsLog := ""

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

	If (_lRetOk) .and. (Empty(_cCodTab))
		SetRestFault(1000, EncodeUTF8("Tabela não informada."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cChaveOS))
		SetRestFault(1000, EncodeUTF8("Chave da ordem de serviço não informada."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cStatus))
		SetRestFault(1000, EncodeUTF8("Status da ordem de serviço não informado."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. ( ! (_cStatus $ "C|R") )
		SetRestFault(1000, EncodeUTF8("Status informado não é aceito na ordem de serviço."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. ( _cStatus $ "C" ) .and. ( Empty(_cJustCanc) )
		SetRestFault(1000, EncodeUTF8("Para status de CANCELAMENTO é obrigatório informar uma justificativa/motivo."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. ( _cStatus $ "R" ) .and. ( Empty(_cLink) )
		SetRestFault(1000, EncodeUTF8("Para status de REALIZADO é obrigatório informar o LINK com as fotos."))
		_lRetOk := .F.
	EndIf

	// define status do Log
	If (_cStatus == "R")
		_cStsLog := "REALIZADO"
	ElseIf (_cStatus == "C")
		_cStsLog := "CANCELADO"
	EndIf

	// prepara o ambiente para o usuario + empresa + filial selecionada
	If (_lRetOk) .and. ((cEmpAnt != _cCodEmp) .or. (cFilAnt != _cCodFil))
		RPCClearEnv()
		RPCSetType(3)
		RpcSetEnv(_cCodEmp, _cCodFil, Nil, Nil, 'WMS',, )
	EndIf

	If (_lRetOk)

		If (AllTrim(Upper(_cCodTab)) == "SZ6")

			// define o numero da ordem de servico
			_cChaveOS := PadR(_cChaveOS, 6)

			// pesquisa a ordem de servico
			_cQuery := " SELECT SZ6.R_E_C_N_O_ SZ6RECNO "
			_cQuery += " FROM   " + RetSqlTab("SZ6")
			_cQuery += " WHERE  " + RetSqlCond("SZ6")
			_cQuery += "        AND Z6_FOTO = 'O' "
			_cQuery += " AND ( Z6_USRFOTO = '" + _cCodUser + "'                      "
			_cQuery += "              OR (SELECT R_E_C_N_O_                          "
			_cQuery += "                  FROM " + RetSqlTab("DCD")
			_cQuery += "                  WHERE  DCD_ZCATEG IN ( 'S', 'G' )          "
			_cQuery += "                         AND DCD_CODFUN = '" + _cCodUser + "'"
			_cQuery += "                         AND D_E_L_E_T_ = ''                 "
			_cQuery += "                         AND DCD_MSBLQL = '2') != '' )       "


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
					SZ6->Z6_FOTO    := _cStatus // C=CANCELADO ou R = REALIZADO
					SZ6->Z6_QTDFOTO := _nQtdFotos
					SZ6->Z6_LINKFOT := _cLink
					SZ6->Z6_JUSTFOT := _cJustCanc
					SZ6->(MsUnLock())

					// gera log
					U_FtGeraLog(xFilial("SZ6"), "SZ6", SZ6->Z6_FILIAL + SZ6->Z6_NUMOS, "AppFotos: Retorno de Fotos da Ordem de Serviço. Status " + _cStsLog, "WMS", SZ6->Z6_CODIGO, _cCodUser)

				Next _nRecSZ6
			EndIf
		EndIf

	EndIf

	If (_lRetOk)
		::SetResponse(EncodeUTF8('{"status": 1003,"chave_ordsrv":"' + _cChaveOS + '","msg":"Ord Servico finalizada com sucesso." }'))
	EndIf

Return(_lRetOk)