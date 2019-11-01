#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "PROTHEUS.CH"
#Include 'FWMVCDEF.ch'


WSRESTFUL WsAppTrocaOP DESCRIPTION "AppFotos - Troca de operador atuando na ordem de serviço"

// variaveis
WSDATA pCodEmp    AS STRING
WSDATA pCodFil    AS STRING
WSDATA pCodTab    AS STRING
WSDATA pChaveOS   AS STRING
WSDATA pOpOld     AS STRING
WSDATA pOpNew     AS STRING

// declaracao dos metodos
WSMETHOD PUT DESCRIPTION "AppFotos - PUT Troca operador atuando na ordem de serviço" WSSYNTAX "/AppTrocaOP || /AppTrocaOP/{codigo_empresa, codigo_filial, codigo_tabela, chave_os, op_atual, op_novo}"

END WSRESTFUL


WSMETHOD PUT WSRECEIVE pCodEmp, pCodFil, pCodTab, pChaveOS, pOpOld, pOpNew WSSERVICE WsAppTrocaOP

	local _lRetOk := .T.

	local _cCodEmp    := Self:pCodEmp
	local _cCodFil    := Self:pCodFil
	local _cCodTab    := Self:pCodTab
	local _cChaveOS   := Self:pChaveOS
	local _cOpOld     := Self:pOpOld
	local _cOpNew     := Self:pOpNew

	// numero da ordem de servico
	local _cNrOrdSrv

	// variaveis temporarias
	local _aTmpDados
	local _nRecSZ6

	// query
	local _cQuery

	// define o tipo de retorno do método
	::SetContentType("application/json; charset=UTF-8;")

	If (_lRetOk) .and. ((ValType(_cCodEmp) != "C") .or. (ValType(_cCodFil) != "C") .or. (ValType(_cCodTab) != "C") .or. (ValType(_cChaveOS) != "C")  .or. (ValType(_cOpOld) != "C")  .or. (ValType(_cOpNew) != "C") )
		SetRestFault(1000, EncodeUTF8("Obrigatório informar código da empresa, filial, tabela, chave da OS, código do operador antigo e código do operador novo."))
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

	If (_lRetOk) .and. (Empty(_cCodTab))
		SetRestFault(1000, EncodeUTF8("Tabela não informada."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cChaveOS))
		SetRestFault(1000, EncodeUTF8("Chave da OS não informada."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cOpOld))
		SetRestFault(1000, EncodeUTF8("Operador antigo/atual da OS não informado."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .and. (Empty(_cOpNew))
		SetRestFault(1000, EncodeUTF8("Novo operador da OS não informado."))
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
//			_cQuery += "        AND Z6_FOTO = 'P' "
			_cQuery += "        AND Z6_USRFOTO = '" + _cOpOld + "' "
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

					// altera usuário que está executando a operação de fotos
					RecLock("SZ6")
					SZ6->Z6_USRFOTO := _cOpNew
					SZ6->(MsUnLock())

					// gera log
					U_FtGeraLog(xFilial("SZ6"), "SZ6", SZ6->Z6_FILIAL + SZ6->Z6_NUMOS, "AppFotos: Mudança de operador. Anterior: " + _cOpOld + " / Novo: " + _cOpNew, "WMS", SZ6->Z6_CODIGO, _cOpOld)

				Next _nRecSZ6
			EndIf
		EndIf

	EndIf

	If (_lRetOk)
		::SetResponse(EncodeUTF8('{"status": 1003,"chave_ordsrv":"' + _cChaveOS + '","msg":"Troca de operador recebida com sucesso." }'))
	EndIf

Return(_lRetOk)