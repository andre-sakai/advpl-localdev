#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

WSRESTFUL WsIntConfRotas DESCRIPTION "Tecadi Integrações - Configuração de Rotas"

// variaveis
WSDATA pCodEmp AS STRING

// declaracao dos metodos
WSMETHOD GET DESCRIPTION "Tecadi Integrações - Configuração de Rotas" WSSYNTAX "/IntConfRotas || /IntConfRotas/{codigo_empresa}"

END WSRESTFUL

WSMETHOD GET WSRECEIVE pCodEmp WSSERVICE WsIntConfRotas

	// validacao de retorno
	local _lRetOk := .T.

	// variavel de retorno
	local _cRetJson

	// codigo da empresa e CNPJ
	local _cCodEmp := Self:pCodEmp

	// configuracao de rotas
	// 1 - tipo
	// 2 - pasta
	local _aConfRotas := {}
	local _nCfgRota

	// query
	local _cQuery

	// depositantes ativos
	local _aListaDep := {}
	local _nLstDep

//	ConOut(Repl("-", 80))
//	ConOut(PadC("Chamada WsIntConfRotas - GET", 80))
//	ConOut(PadC("Inicio: " + DtoC(Date()) + " " + Time(), 80))
//	ConOut(Repl("-", 80))
//
//	conout("WsIntConfRotas: ValType(_cCodEmp) " + ValType(_cCodEmp) )
//	conout("WsIntConfRotas: ValType(Self:pCodEmp) " + ValType(Self:pCodEmp) )

	// define o tipo de retorno do método
	::SetContentType("application/json; charset=UTF-8;")

	If (_lRetOk) .And. ((ValType(_cCodEmp) != "C"))
		SetRestFault(1000, EncodeUTF8("Obrigatório informar código da empresa."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .And. (Empty(_cCodEmp))
		SetRestFault(1000, EncodeUTF8("Empresa não informada."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .And. (_cCodEmp != "01")
		SetRestFault(1000, EncodeUTF8("Empresa " + AllTrim(_cCodEmp) + " não configurada para uso de Integrações."))
		_lRetOk := .F.
	EndIf

	// prepara o ambiente para o usuario + empresa + filial selecionada
	If (_lRetOk) .And. (cEmpAnt != _cCodEmp)

//		conout("WsIntConfRotas GET " + DtoC(Date()) + " " + Time() + " RpcSetEnv Antes: " + cEmpAnt + " / "+ cFilAnt + " / "+ _cCodEmp + " / "+ _cCodFil + " / " )

		RPCClearEnv()
		RPCSetType(3)

		RpcSetEnv(_cCodEmp, _cCodFil, Nil, Nil, 'WMS',, )

//		conout("WsIntConfRotas GET " + DtoC(Date()) + " " + Time() + " RpcSetEnv Depois: " + cEmpAnt + " / "+ cFilAnt + " / "+ _cCodEmp + " / "+ _cCodFil + " / " )

	EndIf

	// busca depositantes ativos para integracao
	If (_lRetOk)

		// prepara query para buscar ordens de servico pendentes
		_cQuery := " SELECT '01'    COD_EMP, "
		_cQuery += "        A1_COD  COD_CLIENTE, "
		_cQuery += "        A1_LOJA LOJ_CLIENTE, "
		_cQuery += "        A1_NOME NOM_CLIENTE "
		// cab. ordem servico
		_cQuery += " FROM   " + RetSqlTab("SA1")
		// filtro padrao
		_cQuery += " WHERE  " + RetSqlCond("SA1")
		_cQuery += "        AND A1_COD in ('000547','000363') "

//		conout("WsIntConfRotas GET query (_aListaDep): " + _cQuery )

		// dados temporarios
		_aListaDep := U_SqlToVet(_cQuery)

	EndIf

	// valida codigo do CNPJ
	If (_lRetOk)

		_cRetJson := '{'

		_cRetJson += '"configuracao_rotas":['

		// varre todos os depositantes com integracao ativa
		For _nLstDep := 1 to Len(_aListaDep)

			// abre o cadastro de cliente/depositante
			dbSelectArea("SA1")
			SA1->( DbSetOrder(1) ) // 1 - A1_FILIAL, A1_COD + A1_LOJA
			SA1->(DbSeek( xFilial("SA1") + _aListaDep[1][2] + _aListaDep[1][3] ))

			// dados do depositante
			_cRetJson += '{'
			_cRetJson += '"dep_cnpj_cpf":"' + AllTrim(SA1->A1_CGC)  + '",'
			_cRetJson += '"dep_codigo":"'   + AllTrim(SA1->A1_COD)  + '",'
			_cRetJson += '"dep_loja":"'     + AllTrim(SA1->A1_LOJA) + '",'
			_cRetJson += '"dep_nome":"'     + AllTrim(SA1->A1_NOME) + '",'
			_cRetJson += '"dep_email":["suporte1@tecadi.com.br","suporte2@tecadi.com.br"],'

			// tag das rotas
			_cRetJson += '"dep_rotas":['

			// 1 - tipo
			// 2 - pasta
			aAdd(_aConfRotas, {"TXT", "luminatti"})
			aAdd(_aConfRotas, {"XML", "luminatti"})

			// varre todas as rotas ativas por depositante
			For _nCfgRota := 1 to Len(_aConfRotas)

				// prepara string com dados da configuracao da rota
				_cRetJson += '{'
				_cRetJson += '"rota_tipo":"'  + _aConfRotas[_nCfgRota][1] + '",'
				_cRetJson += '"rota_pasta":"' + _aConfRotas[_nCfgRota][2] + '"'
				_cRetJson += '}'

				If (_nCfgRota < Len(_aConfRotas))
					_cRetJson += ','
				EndIf

			Next _nCfgRota

			// fecha array de configuracao de rotas
			_cRetJson += ']}'

			// prepara separacao por depositante
			IF (_nLstDep < Len(_aListaDep))
				_cRetJson += ','
			EndIf

			// proximo depositante
		Next _nCfgRota

		// fecha dados do depositante
		_cRetJson += ']}'

	EndIf

	If (_lRetOk)
		::SetResponse(EncodeUTF8(_cRetJson))
//		ConOut(PadC("Final Sucesso: " + DtoC(Date()) + " " + Time(), 80))
//	Else
//		ConOut(PadC("Final Falha: " + DtoC(Date()) + " " + Time(), 80))
	EndIf

//	ConOut(Repl("-", 80))

Return(_lRetOk)