#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

WSRESTFUL WsIntEtiquetaDepositante DESCRIPTION "Tecadi Integrações - Cadastro de Etiquetas do Depositante"

// variaveis
WSDATA pToken AS STRING

// declaracao dos metodos
WSMETHOD POST DESCRIPTION "Integração de Cadastro de Etiquetas do Depositante (POST)" WSSYNTAX "/IntEtiquetaDepositante || /IntEtiquetaDepositante/{token}"

END WSRESTFUL

WSMETHOD POST WSRECEIVE pToken WSSERVICE WsIntEtiquetaDepositante

	// validacao de retorno
	local _lRetOk := .T.
	local _cArqRemessa := ""

	// dados recebidos
	Local _cBody

	// modelo do JSON
	local _cModId := ""
	local _cModTipo := ""

	// dados da filial
	local _cFilCNPJ := ""

	// controle de abetura de cadastro de empresas
	local _cCodEmp
	local _cCodFil
	local _lEmpOk := .F.

	// dados do cliente
	local _cCliCod
	local _cCliLoj
	local _cCliCNPJ
	local _cCliSigla
	local _cCliNome

	// controle de LOOP etiqueta
	local _nEtiqAtu

	// controle de itens de cada remessa de etiquetas
	local _cPrdCodEtq := CriaVar("Z56_CODETQ", .F.)
	local _cPrdCodCli := CriaVar("B1_CODCLI", .F.)
	local _cPrdCodigo := CriaVar("B1_COD", .F.)
	local _cArmNfNum  := CriaVar("Z56_NOTA", .F.)
	local _cArmNfSer  := CriaVar("Z56_SERIE", .F.)
	local _cArmNfItm  := CriaVar("Z56_ITEMNF", .F.)
	local _lCtrlLote  := .F.
	local _nPrdQtdEtq := 0
	local _dDtValid   := CriaVar("Z56_DTVALI", .F.)
	local _dDtFabric  := CriaVar("Z56_DTFABR", .F.)
	local _cInfCompl  := CriaVar("Z56_INFCOM", .F.)

	// dados do arquivo de remessa de etiquetas
	local _aCabEtique := {}
	local _aItmEtique := {}
	local _aTmpEtique := {}

	// tratamento de erro ou validacao da rotina automatica
	local _aErroAuto := {}
	local _nCount
	local _cLogErro := ""

	// nome completo do arquivo
	local _cArqNome := ""

	// objetos Json ja Deserialize
	private _oArqEtique
	private _oListaEtiq
	private _oDadosArq

	// variaveis de controle de rotina automatica
	private lMsErroAuto    := .F.
	Private lAutoErrNoFile := .T.


//	conout("WsIntEtiquetaDepositante: Disparado por webservice " )

	// define o tipo de retorno do método
	::SetContentType("application/json;charset=UTF-8")

	// pegando conteudo do POST que esta no BODY
	_cBody := ::GetContent()

	//PASSANDO O POST PARA OBJETO EM ADVPL
	FWJsonDeserialize(_cBody ,@_oArqEtique)

	// se ha estrutura do XML/JSON
	If (_lRetOk) .And. (ValType(_oArqEtique) != "O")
		// mensagem
		SetRestFault(1000, EncodeUTF8("Estrutura de dados está fora do padrão esperado."))
		// variavel de controle
		_lRetOk := .F.
	EndIf

	// valida modelo
	If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oArqEtique:mod_id", "mod_id", "C", @_cModId, .T., Nil))

		// pega o modelo do XML
		_cModId := AllTrim(Upper(_oArqEtique:mod_id))

		// valida id do modelo
		If ("ETIQUETAS_DEPOSITANTE" != _cModId)
			// mensagem
			SetRestFault(1000, EncodeUTF8("Tag mod_id: Id " + _cModId + " do Modelo não esperado para este método."))
			// variavel de controle
			_lRetOk := .F.
		EndIf
	EndIf

	// valida modelo - tipo
	If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oArqEtique:mod_tipo", "mod_tipo", "C", @_cModTipo, .T., Nil))

		// pega o modelo do XML
		_cModTipo := AllTrim(Upper(_oArqEtique:mod_tipo))

		// valida id do modelo
		If ("IDENTIFICACAO_PRODUTO" != _cModTipo)
			// mensagem
			SetRestFault(1000, EncodeUTF8("Tag mod_tipo: Id " + _cModTipo + " do Modelo não esperado para este método."))
			// variavel de controle
			_lRetOk := .F.
		EndIf
	EndIf

	// dados da filial
	If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oArqEtique:dados_depositante:dep_cnpj_tecadi", "dep_cnpj_tecadi", "C", @_cFilCNPJ, .T., "A1_CGC"))

		// primeiro registro
		dbSelectArea( "SM0" )
		dbGoTop()

		// varre todas as empresas / filiais
		While SM0->( ! EOF() )

			// valida o CNPJ
			If (AllTrim(_cFilCNPJ) == Alltrim(SM0->M0_CGC))
				// filial encontrada
				_cCodEmp := SM0->M0_CODIGO
				_cCodFil := SM0->M0_CODFIL
				// filial ok
				_lEmpOk := .T.
				// sai do Loop
				Exit
			EndIf

			// proximo item
			SM0->( dbSkip() )
		EndDo

		// caso nao encontre CNPJ
		If ( ! _lEmpOk )
			// mensagem
			SetRestFault(1001, EncodeUTF8("CNPJ TECADI " + _cFilCNPJ + " não disponível para operação."))
			// variavel de controle
			_lRetOk := .F.
		EndIf

	EndIf

	// valida a empresa do grupo
	If (_lRetOk) .And. (_lEmpOk) .And. ( AllTrim(_cCodEmp) != "01" )
		// mensagem
		SetRestFault(1000, EncodeUTF8("Empresa TECADI não configurada para uso de integrações."))
		// variavel de controle
		_lRetOk := .F.
	EndIf

	// controle de filiais ativas com operacoes WMS
	If (_lRetOk) .And. (_lEmpOk) .And. ( ! ( AllTrim(_cCodFil) $ "103/105" ) )
		// mensagem
		SetRestFault(1000, EncodeUTF8("Filial / CNPJ TECADI não configurada para uso de integrações."))
		// variavel de controle
		_lRetOk := .F.
	EndIf

	// prepara o ambiente para o usuario + empresa + filial selecionada
	If (_lRetOk) .And. (_lEmpOk) .And. (( AllTrim(cEmpAnt) != AllTrim(_cCodEmp)) .Or. ( AllTrim(cFilAnt) != AllTrim(_cCodFil) ))

		// zera ambiente atual
		RPCClearEnv()
		RPCSetType(3)

		// conecta novamente em nova empresa / filial
		RpcSetEnv(_cCodEmp, _cCodFil, Nil, Nil, 'WMS',, )

	EndIf

	// dados da filial
	If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oArqEtique:dados_depositante:dep_cnpj_cpf", "dep_cnpj_cpf", "C", @_cCliCNPJ, .T., "A1_CGC"))

		// pesquisa o cliente
		dbSelectArea("SA1")
		SA1->(dbSetOrder(3)) // 3 - A1_FILIAL, A1_CGC
		If ( ! SA1->(dbSeek( xFilial("SA1") + _cCliCNPJ)) )
			// mensagem
			SetRestFault(1001, EncodeUTF8("Depositante com " + _cFilCNPJ + " não disponível ou não cadastrado para operação."))
			// variavel de controle
			_lRetOk := .F.
		Else

			// armazena codigo e loja do cliente
			_cCliCod   := SA1->A1_COD
			_cCliLoj   := SA1->A1_LOJA
			_cCliSigla := SA1->A1_SIGLA
			_cCliNome  := SA1->A1_NOME

		EndIf

	EndIf

	// dados do arquivo
	If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oArqEtique:dados_arquivo", "dados_arquivo", "O", @_oDadosArq, .F., Nil))
//		conout( "WsIntEtiquetaDepositante POST dados_arquivo: ok - Type " + ValType(_oDadosArq))
	EndIf

	// dados do arquivo
	If (_lRetOk) .And. (ValType(_oDadosArq) == "O") .And. (_lRetOk := sfValidaTag("_oDadosArq:arq_nome", "arq_nome", "C", @_cArqNome, .F., Nil))
//		conout( "WsIntEtiquetaDepositante POST dados_arquivo: ok" )
	EndIf


	// atualiza dados do cabecalho
	If (_lRetOk)

		// seleciona a crias as tabelas
		dbSelectArea("Z55")
		dbSelectArea("Z56")

		// zera variaveis da rotina automatica
		_aCabEtique := {}
		_aItmEtique := {}
		_aTmpEtique := {}

		// define conteudo para rotina automatica
		aAdd(_aCabEtique, {"Z55_CODCLI", _cCliCod , Nil})
		aAdd(_aCabEtique, {"Z55_LOJCLI", _cCliLoj , Nil})
		aAdd(_aCabEtique, {"Z55_ARQUIV", _cArqNome, Nil})
		aAdd(_aCabEtique, {"Z55_FORENT", "2"      , Nil}) // 2 - Integracao

	EndIf

	// lista de etiquetas
	If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oArqEtique:lista_etiquetas", "lista_etiquetas", "A", @_oListaEtiq, .T., Nil))
//		conout( "WsIntEtiquetaDepositante POST lista_etiquetas: ok" )
	EndIf

	// prepara dados de todas as etiquetas
	If (_lRetOk)

		// varre todas as etiquetas
		For _nEtiqAtu := 1 to Len(_oListaEtiq)

			// reinicia variaveis
			_cPrdCodEtq := Space(Len(_cPrdCodEtq))
			_cPrdCodCli := Space(Len(_cPrdCodCli))
			_cPrdCodigo := Space(Len(_cPrdCodigo))
			_cArmNfNum  := Space(Len(_cArmNfNum))
			_cArmNfSer  := Space(Len(_cArmNfSer))
			_cArmNfItm  := Space(Len(_cArmNfItm))
			_nPrdQtdEtq := 0
			_lCtrlLote  := .F.
			_dDtValid   := CtoD("//")
			_dDtFabric  := CtoD("//")
			_cInfCompl  := Space(Len(_cInfCompl))

			// rotina automatica
			_aTmpEtique  := {}

			// inclui sequencia da etiqueta
			aAdd(_aTmpEtique, {"Z56_SEQUEN", StrZero(_nEtiqAtu, TamSx3("Z56_SEQUEN")[1]), Nil })

			// valida codigo da etiqueta do cliente
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaEtiq[" + AllTrim(Str(_nEtiqAtu)) + "]:etq_codigo ", "etq_codigo ", "C", @_cPrdCodEtq, .T., "Z56_ETQCLI"))
				// define conteudo para rotina automatica
				aAdd(_aTmpEtique, {"Z56_ETQCLI", _cPrdCodEtq, Nil})
			EndIf

			// valida numero da nota fiscal
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaEtiq[" + AllTrim(Str(_nEtiqAtu)) + "]:etq_nro_nf_armaz ", "etq_nro_nf_armaz ", "C", @_cArmNfNum, .F., "Z56_NOTA"))
				// padroniza a variavel (caracteres e zeros)
				If ( ! Empty(_cArmNfNum) )
					// funcao customizada que preenche zeros a esquerda
					U_FtStrZero(Len(_cArmNfNum), @_cArmNfNum)
				EndIf

				// define conteudo para rotina automatica
				aAdd(_aTmpEtique, {"Z56_NOTA", _cArmNfNum, Nil})
			EndIf

			// valida serie da nota fiscal
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaEtiq[" + AllTrim(Str(_nEtiqAtu)) + "]:etq_ser_nf_armaz ", "etq_ser_nf_armaz ", "C", @_cArmNfSer, .F., "Z56_SERIE"))

				// define conteudo para rotina automatica
				aAdd(_aTmpEtique, {"Z56_SERIE", _cArmNfSer, Nil})
			EndIf

			// valida item da nota fiscal
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaEtiq[" + AllTrim(Str(_nEtiqAtu)) + "]:etq_item_nf_armaz ", "etq_item_nf_armaz ", "C", @_cArmNfItm, .F., "Z56_ITEMNF"))

				// define conteudo para rotina automatica
				aAdd(_aTmpEtique, {"Z56_ITEMNF", _cArmNfItm, Nil})
			EndIf

			// valida codigo do produto do cliente
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaEtiq[" + AllTrim(Str(_nEtiqAtu)) + "]:etq_prod_codigo", "etq_prod_codigo", "C", @_cPrdCodCli, .T., "B1_CODCLI"))
//				conout("WsIntEtiquetaDepositante POST " + AllTrim(Str(_nEtiqAtu)) + " Cod Produto: " + _cPrdCodCli)
			EndIf
			
			// valida codigo do produto em nosso cadastro
			If (_lRetOk)

				// padroniza dados
				_cPrdCodCli := sfLimpaStr(_cPrdCodCli, .F.)

				// incrementa a sigla
				_cPrdCodigo := AllTrim(_cCliSigla)
				_cPrdCodigo += _cPrdCodCli

				// padroniza o tamanho do codigo do produto
				_cPrdCodigo := PadR(_cPrdCodigo, TamSx3("B1_COD")[1])

				// verifica se o produto existe
				dbSelectArea("SB1")
				SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD

				// pesquisa pelo codigo
				If ( ! (_lRetOk := SB1->(dbSeek( xFilial("SB1") + _cPrdCodigo ))) )

					// mensagem
					SetRestFault(1000, EncodeUTF8("Produto " + AllTrim(_cPrdCodCli)+ ": Não cadastrado."))

					// sai do Loop de itens do produto
					Exit

				EndIf

				// define conteudo para rotina automatica
				aAdd(_aTmpEtique, {"Z56_CODPRO", _cPrdCodigo, Nil })

				// verifica controle de lote
				_lCtrlLote := Rastro(_cPrdCodigo, "L")

			EndIf

			// verifica quantidade solicitada
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaEtiq[" + AllTrim(Str(_nEtiqAtu)) + "]:etq_prod_quant", "etq_prod_quant", "N", @_nPrdQtdEtq, .T., "Z56_QUANT"))
				// define conteudo para rotina automatica
				aAdd(_aTmpEtique, {"Z56_QUANT", _nPrdQtdEtq, Nil})
			EndIf

			// verifica data de validade
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaEtiq[" + AllTrim(Str(_nEtiqAtu)) + "]:etq_prod_dt_valid", "etq_prod_dt_valid", "D", @_dDtValid, .F., "Z56_DTVALI"))
				// define conteudo para rotina automatica
				aAdd(_aTmpEtique, {"Z56_DTVALI", _dDtValid, Nil})
			EndIf

			// verifica data de fabricacao
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaEtiq[" + AllTrim(Str(_nEtiqAtu)) + "]:etq_prod_dt_fabric", "etq_prod_dt_fabric", "D", @_dDtFabric, .F., "Z56_DTFABR"))
				// define conteudo para rotina automatica
				aAdd(_aTmpEtique, {"Z56_DTFABR", _dDtFabric, Nil})
			EndIf

			// valida informacao complementar
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaEtiq[" + AllTrim(Str(_nEtiqAtu)) + "]:etq_prod_inf_compl", "etq_prod_inf_compl", "C", @_cInfCompl, .F., "Z56_INFCOM"))
				// define conteudo para rotina automatica
				aAdd(_aTmpEtique, {"Z56_INFCOM", _cInfCompl, Nil})
			EndIf

			// se tem saldo, e dados do produto ok
			aAdd(_aItmEtique, _aTmpEtique)

		Next _nEtiqAtu

		// padroniza dicionario de dados
		_aItmEtique := FWVetByDic(_aItmEtique, 'Z56', .T.)

	EndIf

	// dados ok, realiza tentativa de geracao da integração de etiqueta
	If (_lRetOk)

		// reinicia variaveis
		lMsErroAuto := .F.

		// chama rotina automatica para geracao da integração de etiqueta
		MSExecAuto({|x,y,z| U_TWMSA040(x,y,z)}, _aCabEtique, _aItmEtique, 3)

		// em caso de erro ou validacao
		If ( ! lMsErroAuto)
			// captura id da solicitacao gerada
			_cArqRemessa := Z55->Z55_REMESS
		ElseIf (lMsErroAuto)
			// captura dados detalhados da rotina automatica
			_aErroAuto := GetAutoGRLog()
			// varre todas as linhas
			For _nCount := 1 To Len(_aErroAuto)
				_cLogErro += StrTran(StrTran(StrTran(_aErroAuto[_nCount],"<",""),"-",""),"   "," ") + (" ")
			Next _nCount

			// mensagem
			SetRestFault(1005, EncodeUTF8("Log de Validação: " + _cLogErro))
			// variavel de controle
			_lRetOk := .F.

		EndIf

	EndIf

	// gerecao ok
	If (_lRetOk)
		::SetResponse(EncodeUTF8('{"status": 1000, "filial":"' + cFilAnt + '", "solicitacao_id":"' + _cArqRemessa +'", "dep_nome":"' + AllTrim(_cCliNome) + '", "dep_cnpj_cpf":"' + AllTrim(_cCliCNPJ) + '", "mensagem":"Arquivo de remessa registrado com sucesso." }'))

	EndIf

Return(_lRetOk)

// ** funcao que valida existencia de TAG
Static Function sfValidaTag(mvObjTag, mvIdTag, mvTipo, mvVarControle, mvObrigat, mvDicCampo)

	// variavel de retorno
	local _lRet := .T.
	// objeto ok
	local _lObjOk := .F.

	// objeto
	private _oObjTag := Nil
	private _oObjData := Nil

	// valores padroes
	Default mvObjTag      := ""
	Default mvIdTag       := ""
	Default mvTipo        := ""
	Default mvVarControle := Nil
	Default mvObrigat     := .F.
	Default mvDicCampo    := ""

	// valida tipo do objeto
	If (_lRet) .And. (mvObrigat) .And. ( Type(mvObjTag) != mvTipo )
		// mensagem
		SetRestFault(1000, EncodeUTF8("Tag " + mvIdTag + ": Não definida na estrutura."))
		// variavel de controle
		_lRet := .F.
	EndIf

	// tratamento e validacao especifico para campo do tipo DATE
	If (_lRet) .And. (mvTipo == "D") .And. ( Type(mvObjTag) != "U" )

		// atribui o conteudo ao objeto de retorno
		_oObjData := (&(mvObjTag))

		// se foi informado algum conteudo no campo
		If ( ! Empty(_oObjData) )
			// valida tamanho e formato do campo
			If (At("-", _oObjData) == 0) .Or. (Len(AllTrim(_oObjData)) < 10)
				// mensagem
				SetRestFault(1000, EncodeUTF8("Tag " + mvIdTag + ": Tipo do conteúdo não esperado."))
				// variavel de controle
				_lRet := .F.
			EndIf

			// se dados ok
			If (_lRet)
				// pega parte do conteudo
				_oObjData := SubStr(_oObjData, 1, 10)

				// converte a data (Str to Date)
				_oObjData := StoD(StrTran(_oObjData, "-", ""))

				// atualiza conteudo do objeto recebido
				(&(mvObjTag)) := _oObjData
			EndIf
		EndIf

	EndIf

	// converte em objeto
	If (_lRet) .And. ( Type(mvObjTag) == mvTipo )
		// atribui o conteudo ao objeto de retorno
		_oObjTag := (&(mvObjTag))
		// objeto ok
		_lObjOk := .T.
	EndIf

	// valida tipo do objeto
	If (_lRet) .And. (mvObrigat) .And. (ValType(_oObjTag) != mvTipo)
		// mensagem
		SetRestFault(1000, EncodeUTF8("Tag " + mvIdTag + ": Tipo do conteúdo não esperado."))
		// variavel de controle
		_lRet := .F.
	EndIf

	// valida, para obrigatorios, se a informacao foi preenchida
	If (_lRet) .And. (mvObrigat) .And. ( Empty(_oObjTag) )
		// mensagem
		SetRestFault(1000, EncodeUTF8("Tag " + mvIdTag + " obrigatório: Conteúdo não informado."))
		// variavel de controle
		_lRet := .F.
	EndIf

	// para os casos de campos nao obrigatorios e nao informados no JSON
	If (_lRet) .And. ( ! mvObrigat ) .And. ( ! _lObjOk ) .And. ( ! Empty(mvDicCampo) )
		// forca criacao do objeto com conteudo padrao do campo dicionario
		_oObjTag := CriaVar(mvDicCampo, .F.)
		// objeto ok
		_lObjOk := .T.
	EndIf

	// atualiza variavel
	If (_lRet) .And. (_lObjOk)
		// para conteudo CARACTER, padroniza tamannho de campo
		mvVarControle := IIf((mvTipo == "C") .And. ( ! Empty(mvDicCampo) ), PadR(_oObjTag, TamSx3(mvDicCampo)[1]), _oObjTag)
	EndIf

Return(_lRet)

// ** funcao que remove os acentos e caracteres especiais
Static Function sfLimpaStr(mvString, mvRemovSpc)
	Local cChar  := ""
	Local nX     := 0
	Local nY     := 0
	Local cVogal := "AEIOU"
	Local cAgudo := "ÁÉÍÓÚ"
	Local cCircu := "ÂÊÎÔÛ"
	Local cTrema := "ÄËÏÖÜ"
	Local cCrase := "ÀÈÌÒÙ"
	Local cTio   := "ÃÕ"
	Local cCecid := "Ç"

	// define o padrao para nao remover
	default mvRemovSpc := .F.

	// maiusculo
	mvString := Upper(mvString)
	// sem espacos
	mvString := AllTrim(mvString)

	// remove todos os espacos em branco
	If (mvRemovSpc)
		mvString := StrTran(mvString," ","")
	EndIf

	// varre todos os caracteres
	For nX:= 1 To Len(mvString)
		cChar:=SubStr(mvString, nX, 1)
		IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase
			nY:= At(cChar,cAgudo)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCircu)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTrema)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCrase)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTio)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr("AO",nY,1))
			EndIf
			nY:= At(cChar,cCecid)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr("C",nY,1))
			EndIf
		Endif
	Next

	For nX:=1 To Len(mvString)
		cChar:=SubStr(mvString, nX, 1)
		If (Asc(cChar) < 32) .Or. (Asc(cChar) > 123) .Or. (cChar $ '&') .Or. (cChar $ '"') .Or. (cChar $ "'")
			mvString:=StrTran(mvString,cChar,".")
		Endif
	Next nX

Return(mvString)