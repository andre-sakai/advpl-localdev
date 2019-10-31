#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

WSRESTFUL WsIntCadDepositante DESCRIPTION "Tecadi Integrações - Cadastro de Depositante"

// variaveis
WSDATA pCodEmp  AS STRING
WSDATA pDepCNPJ AS STRING

// declaracao dos metodos
WSMETHOD GET DESCRIPTION "Tecadi Integrações - Cadastro de Depositante" WSSYNTAX "/IntCadDepositante || /IntCadDepositante/{codigo_empresa, dep_cnpj}"

END WSRESTFUL

WSMETHOD GET WSRECEIVE pCodEmp, pDepCNPJ WSSERVICE WsIntCadDepositante

	// validacao de retorno
	local _lRetOk := .T.

	// variavel de retorno
	local _cRetJson

	// codigo da empresa e CNPJ
	local _cCodEmp  := Self:pCodEmp
	local _cCodFil  := "103"
	local _cDepCNPJ := Self:pDepCNPJ

	// relacao de email do depositante
	local _aDepEmail := {}
	local _nMail

//	ConOut(Repl("-", 80))
//	ConOut(PadC("Chamada WsIntCadDepositante - GET", 80))
//	ConOut(PadC("Inicio: " + DtoC(Date()) + " " + Time(), 80))
//	ConOut(Repl("-", 80))

	// define o tipo de retorno do método
	::SetContentType("application/json; charset=UTF-8;")

	If (_lRetOk) .And. ((ValType(_cCodEmp) != "C") .Or. (ValType(_cDepCNPJ) != "C"))
		SetRestFault(1000, EncodeUTF8("Obrigatório informar código da empresa, filial e usuário"))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .And. (Empty(_cCodEmp))
		SetRestFault(1000, EncodeUTF8("Empresa não informada."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .And. (_cCodEmp != "01")
		SetRestFault(1000, EncodeUTF8("Empresa não configurada para uso de Integrações."))
		_lRetOk := .F.
	EndIf

	If (_lRetOk) .And. (Empty(_cDepCNPJ))
		SetRestFault(1000, EncodeUTF8("CNPJ do Depositante não informado."))
		_lRetOk := .F.
	EndIf

	// prepara o ambiente para o usuario + empresa + filial selecionada
	If (_lRetOk) .And. (cEmpAnt != _cCodEmp)

//		conout("WsIntCadDepositante GET " + DtoC(Date()) + " " + Time() + " RpcSetEnv Antes: " + cEmpAnt + " / "+ cFilAnt + " / "+ _cCodEmp + " / "+ _cCodFil + " / " )

		RPCClearEnv()
		RPCSetType(3)

		RpcSetEnv(_cCodEmp, _cCodFil, Nil, Nil, 'WMS',, )

//		conout("WsIntCadDepositante GET " + DtoC(Date()) + " " + Time() + " RpcSetEnv Depois: " + cEmpAnt + " / "+ cFilAnt + " / "+ _cCodEmp + " / "+ _cCodFil + " / " )

	EndIf

	// valida codigo do CNPJ
	If (_lRetOk)

		// abre o cadastro de cliente/depositante
		dbSelectArea("SA1")
		SA1->( DbSetOrder(3) ) // 3 - A1_FILIAL, A1_CGC

		// pesquisa CNPJ
		If ( ! SA1->(DbSeek( xFilial("SA1") + _cDepCNPJ )) )
			SetRestFault(1000, EncodeUTF8("Cadastro de Depositante não localizado com o CNPJ " + _cDepCNPJ))
			_lRetOk := .f.
		EndIf

		// compara toda o conteudo do CNPJ
		If (_lRetOk)

			// compara chave de pesquisa
			If (AllTrim(_cDepCNPJ) != AllTrim(SA1->A1_CGC))
				SetRestFault(1000, EncodeUTF8("Cadastro de Depositante não localizado com o CNPJ " + _cDepCNPJ))
				_lRetOk := .f.
			EndIf

		EndIf

	EndIf

	// valida codigo do CNPJ
	If (_lRetOk)

		_cRetJson := '{'

		_cRetJson += '"dados_depositante":{'

		_cRetJson += '"dep_cnpj_cpf":"' + AllTrim(SA1->A1_CGC)  + '",'
		_cRetJson += '"dep_codigo":"'   + AllTrim(SA1->A1_COD)  + '",'
		_cRetJson += '"dep_loja":"'     + AllTrim(SA1->A1_LOJA) + '",'
		_cRetJson += '"dep_nome":"'     + AllTrim(SA1->A1_NOME) + '",'

		// relacao de email do depositante
		_aDepEmail := sfRetMail(SA1->A1_COD, SA1->A1_LOJA, .T.)

		_cRetJson +='"dep_emails":['

		For _nMail := 1 to Len(_aDepEmail)

			// verifica se o email esta preenchido
			If ( ! Empty(_aDepEmail[_nMail]) )
				_cRetJson += '"' + AllTrim(_aDepEmail[_nMail]) + '"'
			EndIf

			// controle para fechar a string
			If (_nMail < Len(_aDepEmail))
				_cRetJson += ','
			EndIf

		Next _nMail

		_cRetJson 	+=']}}'

	EndIf

	If (_lRetOk)
		::SetResponse(EncodeUTF8(_cRetJson))
//		ConOut(PadC("Final Sucesso: " + DtoC(Date()) + " " + Time(), 80))
//	Else
//		ConOut(PadC("Final Falha: " + DtoC(Date()) + " " + Time(), 80))
	EndIf

//	ConOut(Repl("-", 80))

Return(_lRetOk)

// ** funcao que retorna a relacao de email do depositante
// parametros
// 1 - codigo cliente
// 2 - loja cliente
// 3 - .T. retorno array / .F. retorno texto
Static Function sfRetMail(mvCodCli, mvLojCli, mvRetArray)
	// variavel de retorno
	local _xRetMail

	// variaveis temporarias
	local _cTmpMail := ""
	local _lSepDuplo := .T.
	local _lBaseTeste := ("TESTE" $ Upper(AllTrim(GetEnvServer())))

	// extrai conteudo do campo
	_cTmpMail  := Lower(AllTrim(SA1->A1_USRCONT))
	_cTmpMail  := StrTran(_cTmpMail, CRLF, ";")
	_lSepDuplo := (At(";;", _cTmpMail) != 0)

	// remove ";;"
	While (_lSepDuplo)
		// substitui
		_cTmpMail  := StrTran(_cTmpMail, ";;", ";")
		// revalida
		_lSepDuplo := (At(";;", _cTmpMail) != 0)
	EndDo

	// se for base testes, substitui email
	If (_lBaseTeste)
		_cTmpMail := "ti@tecadi.com.br"
	EndIf

	// converte conteudo em array
	If (mvRetArray)
		_xRetMail := StrTokArr(AllTrim(_cTmpMail), ";")
	ElseIf ( ! mvRetArray )
		_xRetMail := AllTrim(_cTmpMail)
	EndIf

Return ( _xRetMail )