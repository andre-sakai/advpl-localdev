#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

WSRESTFUL WsIntSolicitacaoCarga DESCRIPTION "Tecadi Integrações - Solicitação de Cargas"

// variaveis
WSDATA pToken AS STRING

// declaracao dos metodos
WSMETHOD POST DESCRIPTION "Integração de Solicitação de Carga (POST)" WSSYNTAX "/IntSolicitacaoCarga || /IntSolicitacaoCarga/{token}"

END WSRESTFUL

WSMETHOD POST WSRECEIVE pToken WSSERVICE WsIntSolicitacaoCarga

	// validacao de retorno
	local _lRetOk := .T.
	local _cMsgOk := ""
	local _cIdNrSol := ""

	// dados recebidos
	Local _cBody

	// modelo do JSON
	local _cModId := ""
	local _nModVersao := 0

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

	// controle de pedidos
	local _nPedAtu
	local _cCbPedCli   := CriaVar("C5_ZPEDCLI", .F.)
	local _cCbCNPJTra  := CriaVar("A4_CGC", .F.)
	local _cCbPlcTra   := CriaVar("Z50_TRAPLA", .F.)
	local _cCbNrNfVnd  := CriaVar("Z50_NFVNR", .F.)
	local _cCbSrNfVnd  := CriaVar("Z50_NFVSER", .F.)
	local _cCbChvNfVnd := CriaVar("Z50_NFVCHV", .F.)
	local _dCbEmiNfVnd := CriaVar("Z50_NFVEMI", .F.)
	local _nCbVlrNfVnd := CriaVar("Z50_NFVVLR", .F.)
	local _nCbVolNfVnd := CriaVar("Z50_NFVVOL", .F.)
	local _nCbPBNfVnd  := CriaVar("Z50_NFVPBR", .F.)
	local _nCbPLNfVnd  := CriaVar("Z50_NFVPLI", .F.)

	// controle de itens de cada pedido
	local _nItAtu
	local _cPrdCodCli := CriaVar("B1_CODCLI", .F.)
	local _cPrdCodigo := CriaVar("B1_COD", .F.)
	local _lCtrlLote  := .F.
	local _oPrdLotes
	local _nPrdQtdSol := 0

	// saldo geral do produto por armazem
	local _nSaldoSb2 := 0
	local _lTemSaldo := .F.
	local _lVerSaldo := .F. // ### temporario - remover

	// variaveis temporarias
	local _cSeekSB2

	// variaveis para FOR
	local _nArq

	// dados da solicitacao de carga
	local _aCabSolic := {}
	local _aItmSolic := {}
	local _aTmpItem  := {}

	// tratamento de erro ou validacao da rotina automatica
	local _aErroAuto := {}
	local _nCount
	local _cLogErro := ""

	// variaveis para controle dos dados de entrega
	local _cEntCGC  := CriaVar("Z50_ENTCGC", .F.)
	local _cEntNome := CriaVar("Z50_ENTNOM", .F.)
	local _cEntEnde := CriaVar("Z50_ENTEND", .F.)
	local _cEntBair := CriaVar("Z50_ENTBAI", .F.)
	local _cEntMun  := CriaVar("Z50_ENTMUN", .F.)
	local _cEntEst  := CriaVar("Z50_ENTEST", .F.)

	// dados do solicitante
	local _cSolNome := ""

	// nome completo do arquivo
	local _cArqNome := ""

	// codigo da empresa e CNPJ
	//local _cToken := Self:pToken

	// objetos Json ja Deserialize
	private _oArqPed
	private _oListaPed
	private _oListaProd
	private _oDadosEntr
	private _oDadosArq

	// variaveis de controle de rotina automatica
	private lMsErroAuto    := .F.
	Private lAutoErrNoFile := .T.

	// valida informacao do token por cliente
	//If (_lRetOk) .And. ((ValType(_cToken) != "C"))
	//	// mensagem
	//	SetRestFault(1000, EncodeUTF8("Obrigatório informar pToken de conexão."))
	//	// variavel de controle
	//	_lRetOk := .F.
	//EndIf

	// define o tipo de retorno do método
	::SetContentType("application/json;charset=UTF-8")

	// valida conteudo do token por cliente
	//If (_lRetOk) .And. (Empty(_cToken))
	//	// mensagem
	//	SetRestFault(1000, EncodeUTF8("Obrigatório informar Id Token de conexão."))
	//	// variavel de controle
	//	_lRetOk := .F.
	//EndIf

//	conout("WsIntSolicitacaoCarga: Inicio " )

	// pegando conteudo do POST que esta no BODY
	If (_lRetOk)

		// extrai conteudo do POST que esta no BODY
		_cBody := ::GetContent()

//		conout("WsIntSolicitacaoCarga: _cBody " )

		//PASSANDO O POST PARA OBJETO EM ADVPL
		FWJsonDeserialize(_cBody ,@_oArqPed)

//		conout("WsIntSolicitacaoCarga: deu certo" )
	EndIf

//	conout("WsIntSolicitacaoCarga: " + ValType(_oArqPed) )

	// se ha estrutura do XML/JSON
	If (_lRetOk) .And. (ValType(_oArqPed) != "O")
		// mensagem
		SetRestFault(1000, EncodeUTF8("Estrutura de dados está fora do padrão esperado."))
		// variavel de controle
		_lRetOk := .F.
	EndIf

	// valida modelo
	If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oArqPed:mod_id", "mod_id", "C", @_cModId, .T., Nil))

		// pega o modelo do XML
		_cModId := AllTrim(Upper(_oArqPed:mod_id))

		// valida id do modelo
		If ("SOLICITACAO_CARGA" != _cModId)
			// mensagem
			SetRestFault(1000, EncodeUTF8("Tag mod_id: Id " + _cModId + " do Modelo não esperado para este método."))
			// variavel de controle
			_lRetOk := .F.
		EndIf
	EndIf

	// valida versao
	If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oArqPed:mod_versao", "mod_versao", "N", @_nModVersao, .T., Nil))

		// pega o modelo do XML
		_nModVersao := _oArqPed:mod_versao

		// valida id do modelo
		If (_nModVersao < 1) .Or. (_nModVersao > 1)
			// mensagem
			SetRestFault(1000, EncodeUTF8("Tag mod_versao: Versão " + AllTrim(Str(_nModVersao)) + " do Modelo não esperado para este método."))
			// variavel de controle
			_lRetOk := .F.
		EndIf
	EndIf

	// dados da filial
	If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oArqPed:dados_depositante:dep_cnpj_tecadi", "dep_cnpj_tecadi", "C", @_cFilCNPJ, .T., "A1_CGC"))

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

//	conout("WsIntSolicitacaoCarga POST parametros: " + cEmpAnt + " / "+ cFilAnt + " / "+ _cCodEmp + " / "+ _cCodFil )

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

//		conout("WsIntSolicitacaoCarga POST RpcSetEnv Antes: " + cEmpAnt + " / "+ cFilAnt + " / "+ _cCodEmp + " / "+ _cCodFil )

		// zera ambiente atual
		RPCClearEnv()
		RPCSetType(3)

		// conecta novamente em nova empresa / filial
		RpcSetEnv(_cCodEmp, _cCodFil, Nil, Nil, 'WMS',, )

//		conout("WsIntSolicitacaoCarga POST RpcSetEnv Depois: " + cEmpAnt + " / "+ cFilAnt + " / "+ _cCodEmp + " / "+ _cCodFil )

	EndIf

	// dados do cliente
	If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oArqPed:dados_depositante:dep_cnpj_cpf", "dep_cnpj_cpf", "C", @_cCliCNPJ, .T., "A1_CGC"))

		// pesquisa o cliente
		dbSelectArea("SA1")
		SA1->(dbSetOrder(3)) // 3 - A1_FILIAL, A1_CGC
		If ( ! SA1->(dbSeek( xFilial("SA1") + _cCliCNPJ)) )
			// mensagem
			SetRestFault(1001, EncodeUTF8("Depositante com " + _cCliCNPJ + " não disponível ou não cadastrado para operação."))
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
	If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oArqPed:dados_arquivo", "dados_arquivo", "O", @_oDadosArq, .F., Nil))
//		conout( "WsIntSolicitacaoCarga POST dados_arquivo: ok - Type " + ValType(_oDadosArq))
	EndIf

	// dados do arquivo
	If (_lRetOk) .And. (ValType(_oDadosArq) == "O") .And. (_lRetOk := sfValidaTag("_oDadosArq:arq_nome", "arq_nome", "C", @_cArqNome, .F., Nil))
//		conout( "WsIntSolicitacaoCarga POST dados_arquivo: ok" )
	EndIf

	// lista de pedidos
	If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oArqPed:lista_pedidos", "lista_pedidos", "A", @_oListaPed, .T., Nil))
//		conout( "WsIntSolicitacaoCarga POST lista_pedidos: ok" )
	EndIf

	// limita a apenas um pedido por chamada
	If (_lRetOk) .And. (Len(_oListaPed) > 1)
		// mensagem
		SetRestFault(1001, EncodeUTF8("Integração configurada para recepção único pedido."))
		// variavel de controle
		_lRetOk := .F.
	EndIf

	// valida pedido a pedido
	If (_lRetOk)

		// varre todos os pedidos
		For _nPedAtu := 1 to Len(_oListaPed)

			// reinicia variaveis
			_cCbPedCli   := Space(Len(_cCbPedCli))
			_cCbCNPJTra  := Space(Len(_cCbCNPJTra))
			_cCbPlcTra   := Space(Len(_cCbPlcTra))
			_cCbNrNfVnd  := Space(Len(_cCbNrNfVnd))
			_cCbSrNfVnd  := Space(Len(_cCbSrNfVnd))
			_cCbChvNfVnd := Space(Len(_cCbChvNfVnd))
			_dCbEmiNfVnd := CtoD("//")
			_nCbVlrNfVnd := 0
			_nCbVolNfVnd := 0
			_nCbPBNfVnd  := 0
			_nCbPLNfVnd  := 0

			// rotina automatica
			_aCabSolic := {}
			_aItmSolic := {}
			_aTmpItem  := {}

			// define conteudo para rotina automatica
			aAdd(_aCabSolic, {"Z50_CODCLI", _cCliCod , Nil})
			aAdd(_aCabSolic, {"Z50_LOJCLI", _cCliLoj , Nil})
			aAdd(_aCabSolic, {"Z50_USRINC", "000000" , Nil})
			aAdd(_aCabSolic, {"Z50_ARQUIV", _cArqNome, Nil})
			aAdd(_aCabSolic, {"Z50_STATUS", "02"     , Nil}) // 02-Liberado para Integração

			// valida numero do pedido do cliente
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaPed[" + AllTrim(Str(_nPedAtu)) + "]:ped_numero", "ped_numero", "C", @_cCbPedCli, .T., "Z50_PEDCLI"))
				dbSelectArea("SC6")
				SC6->(dbSetOrder(11)) // 11-C6_FILIAL, C6_CLI, C6_LOJA, C6_PEDCLI
				//testa se pedido já existe
				If SC6->(dbSeek(  xFilial("SC6") + _cCliCod + _cCliLoj + _cCbPedCli  ))
					// mensagem
					SetRestFault(1001, EncodeUTF8("Pedido do cliente " + _cCbPedCli + " duplicado / já importado. " ))
					// variavel de controle
					_lRetOk := .F.
				Else
					// define conteudo para rotina automatica
					aAdd(_aCabSolic, {"Z50_PEDCLI", _cCbPedCli, Nil})
//					conout("WsIntSolicitacaoCarga POST Ped " + AllTrim(Str(_nPedAtu)) + ": " + _cCbPedCli)
				EndIf
			EndIf

			// valida CNPJ transportora
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaPed[" + AllTrim(Str(_nPedAtu)) + "]:ped_transp_cnpj", "ped_transp_cnpj", "C", @_cCbCNPJTra, .F., "Z50_TRACGC"))

				// define conteudo para rotina automatica
				aAdd(_aCabSolic, {"Z50_TRACGC", _cCbCNPJTra, Nil})

//				conout("WsIntSolicitacaoCarga POST _cCbCNPJTra " + AllTrim(Str(_nPedAtu)) + ": " + _cCbCNPJTra)

			EndIf

			// valida placa transportora
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaPed[" + AllTrim(Str(_nPedAtu)) + "]:ped_transp_placa", "ped_transp_placa", "C", @_cCbPlcTra, .F., "Z50_TRAPLA"))

				// define conteudo para rotina automatica
				aAdd(_aCabSolic, {"Z50_TRAPLA", _cCbPlcTra, Nil})

//				conout("WsIntSolicitacaoCarga POST _cCbPlcTra " + AllTrim(Str(_nPedAtu)) + ": " + _cCbPlcTra)

			EndIf

			// valida numero nota fiscal de venda
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaPed[" + AllTrim(Str(_nPedAtu)) + "]:ped_nro_nf_venda", "ped_nro_nf_venda", "C", @_cCbNrNfVnd, .F., "Z50_NFVNR"))

				// define conteudo para rotina automatica
				aAdd(_aCabSolic, {"Z50_NFVNR", _cCbNrNfVnd, Nil})

//				conout("WsIntSolicitacaoCarga POST _cCbNrNfVnd " + AllTrim(Str(_nPedAtu)) + ": " + _cCbNrNfVnd)

			EndIf

			// valida serie nota fiscal de venda
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaPed[" + AllTrim(Str(_nPedAtu)) + "]:ped_ser_nf_venda", "ped_ser_nf_venda", "C", @_cCbSrNfVnd, .F., "Z50_NFVSER"))

				// define conteudo para rotina automatica
				aAdd(_aCabSolic, {"Z50_NFVSER", _cCbSrNfVnd, Nil})

//				conout("WsIntSolicitacaoCarga POST _cCbSrNfVnd " + AllTrim(Str(_nPedAtu)) + ": " + _cCbSrNfVnd)

			EndIf

			// valida chave nota fiscal de venda
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaPed[" + AllTrim(Str(_nPedAtu)) + "]:ped_chave_nf_venda", "ped_chave_nf_venda", "C", @_cCbChvNfVnd, .F., "Z50_NFVCHV"))

				// define conteudo para rotina automatica
				aAdd(_aCabSolic, {"Z50_NFVCHV", _cCbChvNfVnd, Nil})

//				conout("WsIntSolicitacaoCarga POST _cCbChvNfVnd " + AllTrim(Str(_nPedAtu)) + ": " + _cCbChvNfVnd)

			EndIf

			// valida data de emissao nota fiscal de venda
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaPed[" + AllTrim(Str(_nPedAtu)) + "]:ped_data_nf_venda", "ped_data_nf_venda", "D", @_dCbEmiNfVnd, .F., "Z50_NFVEMI"))

				// define conteudo para rotina automatica
				aAdd(_aCabSolic, {"Z50_NFVEMI", _dCbEmiNfVnd, Nil})

//				conout("WsIntSolicitacaoCarga POST _dCbEmiNfVnd " + AllTrim(Str(_nPedAtu)) + ": " + DtoC(_dCbEmiNfVnd))

			EndIf

			// valida valor nota fiscal de venda
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaPed[" + AllTrim(Str(_nPedAtu)) + "]:ped_valor_nf_venda", "ped_valor_nf_venda", "N", @_nCbVlrNfVnd, .F., "Z50_NFVVLR"))

				// define conteudo para rotina automatica
				aAdd(_aCabSolic, {"Z50_NFVVLR", _nCbVlrNfVnd, Nil})

//				conout("WsIntSolicitacaoCarga POST _nCbVlrNfVnd " + AllTrim(Str(_nPedAtu)) + ": " + Str(_nCbVlrNfVnd))

			EndIf

			// valida quantidade de volumes nota fiscal de venda
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaPed[" + AllTrim(Str(_nPedAtu)) + "]:ped_qtdvol_nf_venda", "ped_qtdvol_nf_venda", "N", @_nCbVolNfVnd, .F., "Z50_NFVVOL"))

				// define conteudo para rotina automatica
				aAdd(_aCabSolic, {"Z50_NFVVOL", _nCbVolNfVnd, Nil})

//				conout("WsIntSolicitacaoCarga POST _nCbVolNfVnd " + AllTrim(Str(_nPedAtu)) + ": " + Str(_nCbVolNfVnd))

			EndIf

			// valida peso bruto nota fiscal de venda
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaPed[" + AllTrim(Str(_nPedAtu)) + "]:ped_pesobru_nf_venda", "ped_pesobru_nf_venda", "N", @_nCbPBNfVnd, .F., "Z50_NFVPBR"))

				// define conteudo para rotina automatica
				aAdd(_aCabSolic, {"Z50_NFVPBR", _nCbPBNfVnd, Nil})

//				conout("WsIntSolicitacaoCarga POST _nCbPBNfVnd " + AllTrim(Str(_nPedAtu)) + ": " + Str(_nCbPBNfVnd))

			EndIf

			// valida peso bruto nota fiscal de venda
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaPed[" + AllTrim(Str(_nPedAtu)) + "]:ped_pesoliq_nf_venda", "ped_pesoliq_nf_venda", "N", @_nCbPLNfVnd, .F., "Z50_NFVPLI"))

				// define conteudo para rotina automatica
				aAdd(_aCabSolic, {"Z50_NFVPLI", _nCbPLNfVnd, Nil})

//				conout("WsIntSolicitacaoCarga POST _nCbPLNfVnd " + AllTrim(Str(_nPedAtu)) + ": " + Str(_nCbPLNfVnd))

			EndIf

			// valida lista dos dados de entrega
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaPed[" + AllTrim(Str(_nPedAtu)) + "]:dados_entrega", "dados_entrega", "O", @_oDadosEntr, .F., Nil))

//				conout("WsIntSolicitacaoCarga POST _oListaPed[ == " + AllTrim(Str(_nPedAtu)) + " == ]:dados_entrega OK")

				// valida Entrega: CGC
				If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oDadosEntr:ent_cnpj_cpf", "ent_cnpj_cpf", "C", @_cEntCGC, .F., "Z50_ENTCGC"))
//					conout("WsIntSolicitacaoCarga POST Ped " + AllTrim(Str(_nPedAtu)) + " Entrega CGC: " + _cEntCGC)

					// define conteudo para rotina automatica
					aAdd(_aCabSolic, {"Z50_ENTCGC", _cEntCGC, Nil})

				EndIf

				// valida Entrega: Nome
				If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oDadosEntr:ent_nome", "ent_nome", "C", @_cEntNome, .F., "Z50_ENTNOM"))
//					conout("WsIntSolicitacaoCarga POST Ped " + AllTrim(Str(_nPedAtu)) + " Entrega Nome: " + _cEntNome)

					// define conteudo para rotina automatica
					aAdd(_aCabSolic, {"Z50_ENTNOM", _cEntNome, Nil})

				EndIf

				// valida Entrega: Endereco
				If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oDadosEntr:ent_endereco", "ent_endereco", "C", @_cEntEnde, .F., "Z50_ENTEND"))
//					conout("WsIntSolicitacaoCarga POST Ped " + AllTrim(Str(_nPedAtu)) + " Entrega Endereco: " + _cEntEnde)

					// define conteudo para rotina automatica
					aAdd(_aCabSolic, {"Z50_ENTEND", _cEntEnde, Nil})

				EndIf

				// valida Entrega: Bairro
				If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oDadosEntr:ent_bairro", "ent_bairro", "C", @_cEntBair, .F., "Z50_ENTBAI"))
//					conout("WsIntSolicitacaoCarga POST Ped " + AllTrim(Str(_nPedAtu)) + " Entrega Bairro: " + _cEntBair)

					// define conteudo para rotina automatica
					aAdd(_aCabSolic, {"Z50_ENTBAI", _cEntBair, Nil})

				EndIf

				// valida Entrega: Municipio
				If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oDadosEntr:ent_cidade", "ent_cidade", "C", @_cEntMun, .F., "Z50_ENTMUN"))
//					conout("WsIntSolicitacaoCarga POST Ped " + AllTrim(Str(_nPedAtu)) + " Entrega Municipio: " + _cEntMun)

					// define conteudo para rotina automatica
					aAdd(_aCabSolic, {"Z50_ENTMUN", _cEntMun, Nil})

				EndIf

				// valida Entrega: Estado
				If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oDadosEntr:ent_uf", "ent_uf", "C", @_cEntEst, .F., "Z50_ENTEST"))
//					conout("WsIntSolicitacaoCarga POST Ped " + AllTrim(Str(_nPedAtu)) + " Entrega Estado: " + _cEntEst)

					// define conteudo para rotina automatica
					aAdd(_aCabSolic, {"Z50_ENTEST", _cEntEst, Nil})

				EndIf

			EndIf

			// valida a lista de itens de cada pedido
			If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaPed[" + AllTrim(Str(_nPedAtu)) + "]:lista_produtos", "lista_produtos", "A", @_oListaProd, .T., Nil))

//				conout("WsIntSolicitacaoCarga POST _oListaPed[ == " + AllTrim(Str(_nPedAtu)) + " == ]:lista_produtos Quant " + AllTrim(Str(Len(_oListaProd))))

			EndIf

			// valida cada item da lista do pedido
			If (_lRetOk)

				// varre todos os itens do pedido
				For _nItAtu := 1 to Len(_oListaProd)

					// reinicia variaveis
					_cPrdCodCli := Space(Len(_cPrdCodCli))
					_cPrdCodigo := Space(Len(_cPrdCodigo))
					_lCtrlLote  := .F.
					_nPrdQtdSol := 0

					// rotina automatica
					_aTmpItem  := {}

					// inclui item do grid
					aAdd(_aTmpItem, {"Z51_ITEM"  , StrZero(_nItAtu, TamSx3("Z51_ITEM")[1]), Nil })
					aAdd(_aTmpItem, {"Z51_STATUS", "02"                                   , Nil}) // 02-Liberado para Integração

					// valida codigo do produto do cliente
					If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaProd[" + AllTrim(Str(_nItAtu)) + "]:prod_codigo", "prod_codigo", "C", @_cPrdCodCli, .T., "B1_CODCLI"))
//						conout("WsIntSolicitacaoCarga POST Ped " + AllTrim(Str(_nPedAtu)) + " Item " + AllTrim(Str(_nItAtu)) + ": " + _cPrdCodCli)
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

//							conout("WsIntSolicitacaoCarga POST Ped " + AllTrim(Str(_nPedAtu)) + " Item " + AllTrim(Str(_nItAtu)) + " - _cPrdCodCli: " + _cPrdCodCli + " não cadastrada!")

							// mensagem
							SetRestFault(1000, EncodeUTF8("Produto " + AllTrim(_cPrdCodCli)+ ": Não cadastrado."))

							// sai do Loop de itens do produto
							Exit

						EndIf

						// define conteudo para rotina automatica
						aAdd(_aTmpItem, {"Z51_CODPRO", _cPrdCodigo, Nil })

						// verifica controle de lote
						_lCtrlLote := Rastro(_cPrdCodigo, "L")

					EndIf

					// verifica se produto controla Lote, e se a TAG foi informada
					If (_lRetOk) .And. (_lCtrlLote) .And. (_lRetOk := sfValidaTag("_oListaProd[" + AllTrim(Str(_nItAtu)) + "]:lista_lotes", "lista_lotes", "A", @_oPrdLotes, _lCtrlLote, Nil))
//						conout("WsIntSolicitacaoCarga POST Ped " + AllTrim(Str(_nPedAtu)) + " Item " + AllTrim(Str(_nItAtu)) + ": lotes ok")
					EndIf

					// verifica quantidade solicitada
					If (_lRetOk) .And. (_lRetOk := sfValidaTag("_oListaProd[" + AllTrim(Str(_nItAtu)) + "]:prod_quantidade", "prod_quantidade", "N", @_nPrdQtdSol, .T., "Z51_QTDSOL"))
						// define conteudo para rotina automatica
						aAdd(_aTmpItem, {"Z51_QTDSOL", _nPrdQtdSol, Nil})

//						conout("WsIntSolicitacaoCarga POST Ped " + AllTrim(Str(_nPedAtu)) + " Item " + AllTrim(Str(_nItAtu)) + ": " + AllTrim(Str(_nPrdQtdSol,15,4)))

					EndIf

					// verifica saldo do produto por armazem
					If (_lRetOk) .And. (_lVerSaldo)

						// zera variaveis
						_nSaldoSb2 := 0
						_lTemSaldo := .F.

						// saldo por armazem
						dbSelectArea("SB2")
						SB2->(dbsetorder(1)) // 1-B2_FILIAL, B2_COD, B2_LOCAL
						SB2->(dbseek( _cSeekSB2 := xFilial("SB2") + _cPrdCodigo ))

						// varre todos os armazens do produto
						While SB2->( ! Eof() ) .And. ((SB2->B2_FILIAL + SB2->B2_COD) == _cSeekSB2)

							// verifica saldo disponivel no estoque.(SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QACLASS - SB2->B2_QEMP)
							_nSaldoSb2 := SaldoSb2()

							// se nao tem saldo Disponivel, faz outro teste
							If (_nSaldoSb2 == 0) .or. (_nPrdQtdSol > _nSaldoSb2)
								// proximo registro de saldo
								SB2->( dbSkip() )
								// retorna o while
								Loop
							EndIf

							// variavel de controle de saldo
							_lTemSaldo := .T.

							// sai do Loop
							Exit

							// proximo registro de saldo
							SB2->(dbSkip())
						EndDo

						// produto sem saldo
						If ( ! _lTemSaldo )
							// mensagem
							SetRestFault(1005, EncodeUTF8("Produto " + AllTrim(_cPrdCodCli)+ ": Sem saldo. Quantidade Solicitada: " + AllTrim(Str(_nPrdQtdSol,15,4)) + " -> Quantidade Dosponível: " + AllTrim(Str(_nSaldoSb2,15,4)) ))
							// variavel de controle
							_lRetOk := .F.
							// sai do Loop
							Exit
						EndIf

					EndIf

					// se tem saldo, e dados do produto ok
					aAdd(_aItmSolic, _aTmpItem)

				Next _nItAtu

				// padroniza dicionario de dados
				_aItmSolic := FWVetByDic(_aItmSolic, 'Z51', .T.)

			EndIf

		Next _nPedAtu
	EndIf

	// dados ok, realiza tentativa de geracao da solicitacao de carga
	If (_lRetOk)

		// reinicia variaveis
		lMsErroAuto := .F.

		// chama rotina automatica para geracao da solicitacao de carga
		MSExecAuto({|x,y,z| U_TWMSA037(x,y,z)}, _aCabSolic, _aItmSolic, 3)

		// em caso de erro ou validacao
		If ( ! lMsErroAuto)
			// captura id da solicitacao gerada
			_cIdNrSol := Z50->Z50_NUMSOL

		ElseIf (lMsErroAuto)
			// captura dados detalhados da rotina automatica
			_aErroAuto := GetAutoGRLog()
			// varre todas as linhas
			For _nCount := 1 To Len(_aErroAuto)
//				ConOut(_aErroAuto[_nCount])
				//cLogErro += StrTran(StrTran(StrTran(_aErroAuto[_nCount],"<",""),"-",""),"   "," ") + (" ")
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

		::SetResponse(EncodeUTF8('{"status": 1000, "filial":"' + cFilAnt + '", "pedido_id":"' + _cCbPedCli +'", "solicitacao_id":"' + _cIdNrSol +'", "dep_nome":"' + AllTrim(_cCliNome) + '", "dep_cnpj_cpf":"' + AllTrim(_cCliCNPJ) + '", "sol_nome":"' + _cSolNome + '", "mensagem":"Solicitação de Carga Recepcionada. Aguardando Geração de Pedido de Separação." }'))

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

//	conout("WsIntSolicitacaoCarga - sfValidaTag: " + Replicate("-", 40))
//	conout("WsIntSolicitacaoCarga - sfValidaTag: esperado mvTipo " + mvTipo )
//	conout("WsIntSolicitacaoCarga - sfValidaTag: esperado mvIdTag " + mvIdTag )
//	conout("WsIntSolicitacaoCarga - sfValidaTag: esperado mvObjTag " + mvObjTag )
//	conout("WsIntSolicitacaoCarga - sfValidaTag: Type(mvObjTag) " + Type(mvObjTag) )

	// valida tipo do objeto
	If (_lRet) .And. (mvObrigat) .And. ( Type(mvObjTag) != mvTipo )
//		conout("WsIntSolicitacaoCarga - sfValidaTag: recusa" )
		// mensagem
		SetRestFault(1000, EncodeUTF8("Tag " + mvIdTag + ": Não definida na estrutura."))
		// variavel de controle
		_lRet := .F.
	EndIf

	// tratamento e validacao especifico para campo do tipo DATE
	If (_lRet) .And. (mvTipo == "D") .And. (Type(mvObjTag) != "U")
		// atribui o conteudo ao objeto de retorno
		_oObjData := (&(mvObjTag))
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
		If (Asc(cChar) < 32).Or.(Asc(cChar) > 123).Or.(cChar $ '&').Or.(cChar $ '"').Or.(cChar $ "'")
			mvString:=StrTran(mvString,cChar,".")
		Endif
	Next nX

Return(mvString)