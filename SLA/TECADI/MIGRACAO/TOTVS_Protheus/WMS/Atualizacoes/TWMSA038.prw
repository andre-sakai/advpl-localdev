#include "totvs.ch"
#Include "RwMake.Ch"
#Include "protheus.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina de conversão de solicitaçao de cargas em pedido  !
!                  ! de venda                                                !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 02/2018 !
+------------------+---------------------------------------------------------+
!Observacoes       ! Z50_STATUS: 01-Em Revisão                               !
!                  !             02-Liberado para Integração                 !
!                  !             03-Com Problemas                            !
!                  !             04-Cancelado                                !
!                  !             05-Integrado com Sucesso                    !
!                  ! Z51_STATUS: 01-Em Revisão                               !
!                  !             02-Liberado para Integração                 !
!                  !             03-Com Problemas                            !
!                  !             04-Cancelado                                !
!                  !             05-Integrado com Sucesso                    !
!                  !             06-Cortado                                  !
+------------------+--------------------------------------------------------*/

User Function TWMSA038(mvRotAuto, mvDerruba, mvNumSol, mvNewPedido)

	// posicao inicial das tabelas
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"Z50", "Z51"})

	// seek
	local _cSeekSC5
	local _cSeekSC6
	local _cSeekZ51

	// tipo do frete padrao
	local _cTpFrete := CriaVar("C5_TPFRETE", .F.)

	// codigo da mensagem padrao
	local _cMensPadr := CriaVar("C5_MENPAD", .F.)

	// valores padroes de especie e volume por cliente
	local _cCliCodEsp := CriaVar("C5_ZCDESP1", .F.)
	local _cCliEspec  := CriaVar("C5_ESPECI1", .F.)
	local _nCliVolum  := CriaVar("C5_VOLUME1", .F.)

	// especies
	local _cCodEspVol := CriaVar("C5_ZCDESP1", .F.)
	local _cEspecie   := CriaVar("C5_ESPECI1", .F.)

	// volumes
	local _nVolumes  := CriaVar("C5_VOLUME1", .F.)

	// numero do pedido do cliente
	local _cNrPedCli := CriaVar("C5_ZPEDCLI", .F.)

	// log do cabecalho
	local _cLogCabec := ""

	// status atual da solicitacao
	local _cAtuStatus := ""

	// horario para tempo de conversao em pedido
	local _cHrIni  := Time()

	// variaveis da rotina padrao do pedido de venda
	private _aCabAuto := {}
	private _aIteAuto := {}

	// item do pedido
	private _cIteAuto := StrZero(1,TamSx3("C6_ITEM")[1])

	// CNPJ e sigla do cliente
	private _cSiglaCli := ""
	private _cCnpjCli  := ""

	// detalhes de entrega do pedido
	private _aDadosEnt := {}

	// controle de validacao completa do arquivo
	private _lImpAllOk  := .T.
	PRIVATE _lAtuStatus := .T.
	private _lClienOk   := .T.
	private _lItensOk   := .T.
	private _lTranspOk  := .T.
	private _lLoteOk    := .T.

	// verifica o uso de referencia agrupadora por cliente
	private _lUsaRefAgrup := .F.

	// valida controle de lote ativo.
	Private _lLotAtivo := .F.

	// controle se deve validar o numero do pedido do cliente
	private _lVldNrPed := .F.

	// controle se deve validar a chave da nota de venda do cliente
	private _lVldChvNfv := .F.

	// controle se deve agrupar todos os XML em unico pedido para separacao
	private _lAgrUnicPed := .T.

	// transportadora
	private _cPedTransp := CriaVar("C5_TRANSP", .F.)
	// placa do veiculo
	private _cPedPlaca := CriaVar("C5_VEICULO", .F.)
	
	// número da solicitação (variável "global" para uso com fonte MT410TOK)
	Private __NRSOLC

	// valor padrao de campos
	Default mvRotAuto   := .F.
	Default mvDerruba   := .F.
	Default mvNumSol    := CriaVar("Z50_NUMSOL", .F.)
	Default mvNewPedido := CriaVar("C5_NUM", .F.)

	// padroniza campos
	mvNumSol := PadR(mvNumSol, TamSx3("Z50_NUMSOL")[1])
	__NRSOLC := mvNumSol

	// valida se o numero da solicitacao foi informado
	If (_lImpAllOk) .And. ( Empty(mvNumSol) )
		// mensagem
		Help(,,'TWMSA038.001',,"Número da solicitação de cargas não informada.",1,0)
		// controle de processamento
		_lImpAllOk := .F.
		// marca pra nao atualizar status
		_lAtuStatus := .F.
	EndIf

	// pesquisa e posiciona sobre a solicitacao de carga
	If (_lImpAllOk) .And. ( ! Empty(mvNumSol) )
		// pesquisa solicitacao
		dbSelectArea("Z50")
		Z50->(dbSetOrder(1)) // 1-Z50_FILIAL, Z50_NUMSOL
		If ( ! Z50->(dbSeek( xFilial("Z50") + mvNumSol )) )
			// mensagem
			Help(,,'TWMSA038.002',,"Número da solicitação de cargas não encontrada.",1,0)
			// controle de processamento
			_lImpAllOk := .F.
			// marca pra nao atualizar status
			_lAtuStatus := .F.
		EndIf
	EndIf

	// valida status da solicitacao
	If (_lImpAllOk) .And. (Z50->Z50_STATUS != "02") // 02-Liberado para Integração
		// status atual da solicitacao
		_cAtuStatus := U_FtX3CBox("Z50_STATUS", Z50->Z50_STATUS, 2, 1)
		// mensagem
		Help(,,'TWMSA038.003',,"Solicitação de cargas não está liberada para integração. Status Atual: " + _cAtuStatus,1,0)
		// controle de processamento
		_lImpAllOk := .F.
		// marca pra nao atualizar status
		_lAtuStatus := .F.
	EndIf

	// realiza tentativa de reservar o registro
	If (_lImpAllOk) .And. ( ! MsrLock() )
		// mensagem
		Help(,,'TWMSA038.004',,"Solicitação de cargas alocada em outro processo de atualização.",1,0)
		// controle de processamento
		_lImpAllOk := .F.
		// marca pra nao atualizar status
		_lAtuStatus := .F.
	EndIf

	// se registro ok, bloqueia registro
	If (_lImpAllOk)
		SoftLock("Z50")
	EndIf

	// pesquisa e valida cliente
	If (_lImpAllOk)

		// cadastro de cliente
		dbSelectArea("SA1")
		SA1->(dbSetOrder(1)) // 1 - A1_FILIAL, A1_COD, A1_LOJA
		If ( ! SA1->(dbSeek( xFilial("SA1") + Z50->Z50_CODCLI + Z50->Z50_LOJCLI )))
			// define log do cabecalho
			_cLogCabec := "Cadastro do cliente não é válido."
			// mensagem
			Help(,,'TWMSA038.005',,"Cadastro do cliente não é válido.",1,0)
			// controle de processamento
			_lImpAllOk := .F.
			// cadastro de cliente
			_lClienOk := .F.

		Endif

		// atualiza variaveis de controle
		_cSiglaCli := SA1->A1_SIGLA
		_cCnpjCli  := SA1->A1_CGC

	EndIf

	// se dados do cliente Ok
	If (_lImpAllOk) .And. (_lClienOk)

		// verifica o uso de referencia agrupadora por cliente
		_lUsaRefAgrup := U_FtWmsParam("WMS_USO_REFERENCIA_AGRUPADORA_PEDIDO", "L", .F., .F., "", Z50->Z50_CODCLI, Z50->Z50_LOJCLI, Nil, Nil)

		// verifica se o controle de lote esta ativo
		_lLotAtivo := U_FtWmsParam("WMS_CONTROLE_POR_LOTE", "L", .F. , .F., Nil, Z50->Z50_CODCLI, Z50->Z50_LOJCLI, Nil, Nil)

		// controle se deve validar o numero do pedido do cliente
		_lVldNrPed := U_FtWmsParam("WMS_PEDIDO_VALIDA_PEDIDO_CLIENTE", "L", .F. , .F., Nil, Z50->Z50_CODCLI, Z50->Z50_LOJCLI, Nil, Nil)

		// controle se deve validar a chave da nota de venda do cliente
		_lVldChvNfv := U_FtWmsParam("WMS_PEDIDO_VALIDA_CHAVE_NOTA_VENDA", "L", .F. , .F., Nil, Z50->Z50_CODCLI, Z50->Z50_LOJCLI, Nil, Nil)

		// controle se deve agrupar todos os XML em unico pedido para separacao
		_lAgrUnicPed := U_FtWmsParam("WMS_PEDIDO_AGRUPAR_XML_UNICO_PEDIDO", "L", .T. , .F., Nil, Z50->Z50_CODCLI, Z50->Z50_LOJCLI, Nil, Nil)

		// define o tipo de frete padrao para o cliente
		_cTpFrete := U_FtWmsParam("WMS_PEDIDO_TIPO_FRETE_PADRAO", "C", _cTpFrete, .F., "", Z50->Z50_CODCLI, Z50->Z50_LOJCLI, Nil, Nil)

		// define o codigo da mensagem padrao para o cliente
		_cMensPadr := U_FtWmsParam("WMS_PEDIDO_MENSAGEM_PADRAO_FORMULA", "C", _cMensPadr, .F., "", Z50->Z50_CODCLI, Z50->Z50_LOJCLI, Nil, Nil)

		// define o codigo da especie dos volumes
		_cCliCodEsp := U_FtWmsParam("WMS_PEDIDO_VOLUME_ESPECIE", "C", _cEspecie, .F., "", Z50->Z50_CODCLI, Z50->Z50_LOJCLI, Nil, Nil)
		_cCliEspec  := Tabela("CL", _cCliCodEsp)

		// define a quantidade de volumes padrao
		_nCliVolum := U_FtWmsParam("WMS_PEDIDO_VOLUME_QUANTIDADE", "N", _nVolumes, .F., "", Z50->Z50_CODCLI, Z50->Z50_LOJCLI, Nil, Nil)

	EndIf

	// nao encontrou a chave da NFe
	If (_lImpAllOk) .And. (_lVldChvNfv) .And. (SuperGetMv("TC_CONSNFE", .F., .T.))

		// chave da nota em branco, nao informada
		If (Empty(Z50->Z50_NFVCHV))
			// define log do cabecalho
			_cLogCabec := "Não foi possível encontrar a chave da nota fiscal."
			// mensagem
			Help(,,'TWMSA038.006',,"Não foi possível encontrar a chave da nota fiscal.",1,0)
			// controle de processamento
			_lImpAllOk := .F.

			// verifica o status da nota no SEFAZ
		ElseIf ( ! Empty(Z50->Z50_NFVCHV) )
			// pesquisa o ID da empresa
			_cIdEnt := RetIdEnti()
			// se nao encontrou o ID da Empresa
			If (Empty(_cIdEnt))
				// define log do cabecalho
				_cLogCabec := "Erro do retorno do ID da Empresa."
				// mensagem
				Help(,,'TWMSA038.007',,"Erro do retorno do ID da Empresa.",1,0)
				// controle de processamento
				_lImpAllOk := .F.
			EndIf
			// consulta o status no SEFAZ
			If ( ! ConsNFeChave(Z50->Z50_NFVCHV, _cIdEnt, @_cLogCabec) )
				// mensagem
				Help(,,'TWMSA038.008',,"Verificar mensagem para falha na consulta da chave da nota fiscal de venda no SEFAZ." + CRLF + _cLogCabec,1,0)
				// controle de processamento
				_lImpAllOk := .F.

			EndIf
		EndIf
	EndIf


	// validacao de transportadora
	If (_lImpAllOk) .And. ( ! Empty(Z50->Z50_TRACGC) )

		// reinicia variaveis
		_cPedTransp := Space(Len(_cPedTransp))
		_cPedPlaca  := Space(Len(_cPedPlaca))

		// valida os dados da transportadora
		If ( ! sfVldTransp(Z50->Z50_TRACGC, Z50->Z50_TRAPLA, @_cLogCabec) )
			// variavel de controle de validacao de transportadora
			_lTranspOk := .F.
			// mensagem
			Help(,,'TWMSA038.009',,_cLogCabec,1,0)
		EndIf

	EndIf

	// pesquisa e valida pedido de venda do cliente
	If (_lImpAllOk) .And. ( ! Empty(Z50->Z50_PEDCLI) ) .And. (_lVldNrPed)

		// padroniza tamanho do campo
		_cNrPedCli := PadR(Z50->Z50_PEDCLI, TamSx3("C5_ZPEDCLI")[1])

		// pesquisa pelo pedido do cliente no cabecalho
		dbSelectArea("SC5")
		SC5->(DbOrderNickName("SC50000001")) // C5_FILIAL+C5_ZPEDCLI

		// Verifica se encontra pedido para fazer a atualização.
		If SC5->(dbSeek( _cSeekSC5 := xFilial("SC5") + _cNrPedCli ))

			// verifica se é do mesmo cliente
			While (_lImpAllOk) .And. (SC5->( ! Eof() )) .And. ((SC5->C5_FILIAL + SC5->C5_ZPEDCLI) == _cSeekSC5)

				// valida se é o mesmo cliente
				If (SC5->C5_CLIENTE == Z50->Z50_CODCLI) .And. (SC5->C5_LOJACLI == Z50->Z50_LOJCLI)
					// define log do cabecalho
					_cLogCabec := "Pedido " + AllTrim(_cNrPedCli) + " já registrado. Número: " + SC5->C5_NUM
					// controle de processamento
					_lImpAllOk := .F.
				EndIf

				// proximo pedido
				SC5->(dbSkip())
			EndDo
		EndIf

		// padroniza tamanho do campo
		_cNrPedCli := PadR(_cNrPedCli, TamSx3("C6_PEDCLI")[1])

		// pesquisa pelo pedido do cliente no cabecalho
		dbSelectArea("SC6")
		SC6->(dbSetOrder(11)) // 11-C6_FILIAL, C6_CLI, C6_LOJA, C6_PEDCLI

		// Verifica se encontra pedido para fazer a atualização.
		If (_lImpAllOk) .And. (SC6->(dbSeek( _cSeekSC6 := xFilial("SC6") + Z50->Z50_CODCLI + Z50->Z50_LOJCLI + _cNrPedCli  )))
			// define log do cabecalho
			_cLogCabec := "Pedido do CLIENTE número " + AllTrim(_cNrPedCli) + " já registrada em outro Pedido de Venda TECADI: " + SC6->C6_NUM + " / Item " + SC6->C6_ITEM
			// controle de processamento
			_lImpAllOk := .F.
		EndIf

	EndIf

	// pesquisa chave da nota fiscal de venda
	If (_lImpAllOk) .And. ( ! Empty(Z50->Z50_NFVCHV) ) .And. (_lVldChvNfv)

		// pesquisa pela chave da nota fiscal de venda do cliente no cabecalho
		dbSelectArea("SC5")
		SC5->(DbOrderNickName("C5_ZCHVNFV")) // C5_FILIAL + C5_ZCHVNFV

		// Verifica se encontra a chave da nota fiscal
		If SC5->(dbSeek( _cSeekSC5 := xFilial("SC5") + Z50->Z50_NFVCHV ))

			// verifica se é do mesmo cliente
			While (_lImpAllOk) .And. (SC5->( ! Eof() )) .And. ((SC5->C5_FILIAL + SC5->C5_ZCHVNFV) == _cSeekSC5)

				// valida se é o mesmo cliente
				If (SC5->C5_CLIENTE == Z50->Z50_CODCLI) .And. (SC5->C5_LOJACLI == Z50->Z50_LOJCLI)
					// define log do cabecalho
					_cLogCabec := "Chave " + AllTrim(Z50->Z50_NFVCHV) + " da Nota Fiscal de Venda já registrada em outro Pedido de Venda TECADI: " + SC5->C5_NUM
					// controle de processamento
					_lImpAllOk := .F.
				EndIf

				// proximo pedido
				SC5->(dbSkip())
			EndDo
		EndIf

	EndIf

	// define informacoes de volumes
	If (_lImpAllOk)

		// atualiza quantidade de volumes
		_nVolumes := Z50->Z50_NFVVOL

		// se nao ha dados de volumes, insere informacao padrao por cliente
		If (_nVolumes == 0)
			_nVolumes := _nCliVolum
		EndIf

		// define especie padrao
		If (Empty(_cEspecie))
			_cCodEspVol := _cCliCodEsp
			_cEspecie   := _cCliEspec
		EndIf

		// em caso de volumes / especies zerados
		If (_nVolumes == 0) .Or. (Empty(_cEspecie))
			// define log do cabecalho
			_cLogCabec := "Pedido do CLIENTE número " + AllTrim(_cNrPedCli) + " sem informações de Volume / Espécie de Volume"
			// controle de processamento
			_lImpAllOk := .F.
		EndIf

	EndIf

	// se todos os dados do cabecalhos estiverem ok, preenche cabecalho do pedido de venda
	If (_lImpAllOk)

		// posiciona no cadastro de cliente
		dbSelectArea("SA1")
		SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
		SA1->(dbSeek( xFilial("SA1") + Z50->Z50_CODCLI + Z50->Z50_LOJCLI ))

		// dados do cabecalho do pedido de venda
		aAdd(_aCabAuto,{"C5_TIPO"	, "N"                                   , Nil}) // Tipo do Pedido - N-Normal
		aAdd(_aCabAuto,{"C5_CLIENTE", Z50->Z50_CODCLI                       , Nil}) // Cod. Cliente
		aAdd(_aCabAuto,{"C5_LOJACLI", Z50->Z50_LOJCLI                       , Nil}) // Loja
		aAdd(_aCabAuto,{"C5_CLIENT"	, Z50->Z50_CODCLI                       , Nil}) // Cod. Cliente Ent
		aAdd(_aCabAuto,{"C5_LOJAENT", Z50->Z50_LOJCLI                       , Nil}) // Loja Ent
		aAdd(_aCabAuto,{"C5_TIPOCLI", SA1->A1_TIPO                          , Nil}) // Tipo do Cliente
		aAdd(_aCabAuto,{"C5_CONDPAG", "001"                                 , Nil}) // Condicao de Pagamento (padrao 001)
		aAdd(_aCabAuto,{"C5_TIPOOPE", "P"                                   , Nil}) // tipo da operacao: P-Produto / S-Servido
		aAdd(_aCabAuto,{"C5_EMISSAO", dDataBase                             , Nil}) // data de emissao
		aAdd(_aCabAuto,{"C5_VOLUME1", _nVolumes                             , Nil}) // volumes
		aAdd(_aCabAuto,{"C5_ZCDESP1", _cCodEspVol                           , Nil}) // codigo da especie do volume
		aAdd(_aCabAuto,{"C5_ESPECI1", _cEspecie                             , Nil}) // descricao especie do volume
		aAdd(_aCabAuto,{"C5_MENNOTA", ""                                    , Nil}) // mensagem para nota fiscal
		aAdd(_aCabAuto,{"C5_MENPAD"	, _cMensPadr                            , Nil}) // codigo da mensagem padrao
		aAdd(_aCabAuto,{"C5_ZDOCCLI", Z50->Z50_NFVNR                        , Nil}) // documento/nota do cliente
		aAdd(_aCabAuto,{"C5_ZCHVNFV", Z50->Z50_NFVCHV                       , Nil}) // chave da NFe para consulta do status no SEFAZ
		aAdd(_aCabAuto,{"C5_ZEMINFV", Z50->Z50_NFVEMI                       , Nil}) // data de emissao da nota fiscal importada
		aAdd(_aCabAuto,{"C5_ZPEDCLI", Z50->Z50_PEDCLI                       , Nil}) // numero do pedido do cliente
		aAdd(_aCabAuto,{"C5_VEICULO", _cPedPlaca                            , Nil}) // placa do veiculo
		aAdd(_aCabAuto,{"C5_TRANSP" , _cPedTransp                           , Nil}) // transportadora
		aAdd(_aCabAuto,{"C5_TPFRETE", _cTpFrete                             , Nil}) // tipo de frete

		// inclui dados de endereco de entrega
		aAdd(_aCabAuto,{"C5_ZCGCENT", Z50->Z50_ENTCGC                       , Nil}) // CGC do cliente de entrega
		aAdd(_aCabAuto,{"C5_ZCLIENT", Z50->Z50_ENTNOM                       , Nil}) // Nome do cliente de entrega
		aAdd(_aCabAuto,{"C5_ZENDENT", Z50->Z50_ENTEND                       , Nil}) // endereco de entrega
		aAdd(_aCabAuto,{"C5_ZCIDENT", Z50->Z50_ENTMUN                       , Nil}) // Nome da Cidade De entrega
		aAdd(_aCabAuto,{"C5_ZUFENTR", Z50->Z50_ENTEST                       , Nil}) // Estado de entrega

		// numero da solicitacao
		aAdd(_aCabAuto,{"C5_ZNUMSOL", Z50->Z50_NUMSOL                       , Nil}) // Numero da Solicitacao

	EndIf

	// valida os itens da nota
	If (_lImpAllOk)
		// funcao que valida os itens da nota
		If ( ! sfVldItens() )
			// controle de processamento
			_lImpAllOk := .F.
			// controle de processamento de itens
			_lItensOk := .F.
		EndIf
	EndIf

	// grava log do cabecalho
	If ( ! _lImpAllOk ) .And. (_lAtuStatus)
		// atualiza dados do cabecalho da solicitacao
		dbSelectArea("Z50")
		RecLock("Z50", .F.)
		Z50->Z50_STATUS := "03" // 03-Com Problemas
		Z50->Z50_LOG    := _cLogCabec
		Z50->Z50_TTCPED := ElapTime(_cHrIni, Time())
		Z50->Z50_NRTENT += 1
		Z50->(MsUnLock())

		// gera log
		U_FtGeraLog(xFilial("Z50"), "Z50", Z50->Z50_FILIAL + Z50->Z50_NUMSOL, "FALHA - Tentativa de conversão em Pedido de Venda. Consultar LOG", "CFG", "")

		// envia mensagem por email
		sfEnviaMail()

		// se tudo Ok, gera pedido de venda
	ElseIf (_lImpAllOk)

		// inicia transacao
		BEGIN TRANSACTION

			// prepara variaveis para rotina automatica
			lMsErroAuto := .F.
			dbSelectArea("SC5")
			dbSelectArea("SC6")

			// rotina automatica do pedido de venda
			MsExecAuto({|x,y,z| Mata410(x,y,z)}, _aCabAuto, _aIteAuto, 3) // 3-inclusao

			// se ocorreu erro na geracao do pedido
			If ( lMsErroAuto )
				// rolback na transação
				DISARMTRANSACTION()
				// libera todos os registros
				MsUnLockAll()
				// apresenta erro
				If (!mvRotAuto)
					MostraErro()
				EndIf
				// controle de processamento
				_lImpAllOk := .F.

				// atualiza dados do cabecalho da solicitacao
				dbSelectArea("Z50")
				RecLock("Z50", .F.)
				Z50->Z50_NRTENT += 1
				IF (Z50->Z50_NRTENT >= 3)   //já tentou 3 vezes esta integração
					Z50->Z50_STATUS := "03"   // Marca solicitação como status 03-Com Problemas
					Z50->Z50_LOG    := "FALHA - Tentativa de conversão em Pedido de Venda. Consultar Departamento Responsável ou tentar integração dentro de alguns minutos."

					// envia mensagem por email
					sfEnviaMail()
				Else 
					// registra log que tentou
					Z50->Z50_LOG    := "FALHA - Tentativa de conversão em Pedido de Venda. Tentativa número: " + Str(Z50->Z50_NRTENT)
					// altera prioridade para o final
					Z50->Z50_PRIORI := "999" 
					// grava log
					MemoWrit("c:\query\TWMSA038_erro_execauto_" + Z50->Z50_NUMSOL + ".txt", U_FTAchaErro() )
				EndIf
				Z50->Z50_TTCPED := ElapTime(_cHrIni, Time())
				Z50->(MsUnLock())

				// gera log
				U_FtGeraLog(xFilial("Z50"), "Z50", Z50->Z50_FILIAL + Z50->Z50_NUMSOL, "FALHA - Tentativa de conversão em Pedido de Venda. Consultar LOG", "CFG", "")



			Else
				// quando ok, atualiza numero do pedido para retorno da funcao
				mvNewPedido := SC5->C5_NUM

				// atualiza dados do cabecalho da solicitacao
				dbSelectArea("Z50")
				RecLock("Z50", .F.)
				Z50->Z50_STATUS := "05" // 05-Integrado com Sucesso
				Z50->Z50_LOG    := "Integrado com Sucesso - Pedido: " + mvNewPedido
				Z50->Z50_PEDIDO := mvNewPedido
				Z50->Z50_DTPED  := Date()
				Z50->Z50_HRPED  := Time()
				Z50->Z50_TTCPED := ElapTime(_cHrIni, Time())
				Z50->Z50_NRTENT += 1
				Z50->(MsUnLock())

				// atualiza saldo dos itens atendidos, conforme itens do pedido de venda
				dbSelectArea("SC6")
				SC6->(dbSetOrder(1)) // 1 - C6_FILIAL, C6_NUM, C6_ITEM, C6_PRODUTO
				SC6->(dbSeek( _cSeekSC6 := xFilial("SC6") + mvNewPedido ))

				// loop em todos os itens do pedido gerado
				While SC6->( ! Eof() ) .And. ((SC6->C6_FILIAL + SC6->C6_NUM) == _cSeekSC6)

					// pesquisa item da solicitacao de carga
					dbSelectArea("Z51")
					Z51->(dbSetOrder(1)) // 1 - Z51_FILIAL, Z51_NUMSOL, Z51_ITEM
					If Z51->(dbSeek( _cSeekZ51 := xFilial("Z51") + SC6->C6_ZNRSOLC + SC6->C6_ZITSOLC ))
						// atualiza campo de controle
						dbSelectArea("Z51")
						RecLock("Z51", .F.)
						Z51->Z51_STATUS := "05" // 05-Integrado com Sucesso
						Z51->Z51_LOG    := "Integrado com Sucesso - Pedido: " + mvNewPedido
						Z51->Z51_QTDENT += SC6->C6_QTDVEN
						Z51->(MsUnLock())
					EndIf

					// proximo item do pedido
					dbSelectArea("SC6")
					SC6->(dbSkip())
				EndDo

				// gera log
				U_FtGeraLog(xFilial("Z50"), "Z50", Z50->Z50_FILIAL + Z50->Z50_NUMSOL, "SUCESSO - Conversão em Pedido de Venda", "CFG", "")

				// envia mensagem por email
				sfEnviaMail()

			EndIf

			// finaliza transacao
		END TRANSACTION

	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni, .T.)
	RestArea(_aAreaAtu)

	// libera todos os registros
	MsUnLockAll()

Return( _lImpAllOk )

// ** funcao que valida os itens da nota
Static Function sfVldItens()

	// posicao inicial das tabelas
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"Z50", "Z51", "SF4"})

	// seek
	local _cSeekZ51

	// controle do retorno
	local _lRet := .T.

	// mensagem de erro
	local _cErroLog := ""

	// log do item
	local _cLogItem := ""

	// controle do item da nota
	local _nItNota
	// relacao de notas de entrada do produto
	local _aNotasEnt := {}

	// saldo a ser atendido da quantidade solicitada
	local _nQtdSolic := 0
	// quantidade utilizada da nota
	local _nQuant := 0

	// TES
	local _cTes := ""

	// linha do item do pedido de venda
	local _aItemPedVen := {}

	// codigo do produto
	local _cCodProd
	// variavel temporaria de lote
	local _cTmpLotPed  := ""
	local _cTmpLotNf   := ""
	local _cTmpLotProd := ""
	local _cTmpLotSeq  := ""
	local _nTmpLotSel  := 0

	// lote soliciado
	local _cLoteSolic := CriaVar("C6_LOTECTL")

	local _nLote

	// variaveis temporarias para controle da informacao de quantidade de paletes e volumes
	local _nTmpQtdPlt := 0
	local _nTmpQtdVol := 0

	// controle de validacao por item
	local _lItemOk := .T.

	// controle de item cortado do pedido
	local _lCortaItem := .F.

	// quantidade do item da nota de armazenagem ja utilizado em outros itens deste mesmo pedido
	local _nQtdJaUti := 0

	// posicao dos campos
	local _nPcPvIdent := 0
	local _nPcPvQuant := 0
	local _nPcNfIdent := 0

	// pesquisa e varre todos os itens da solicitacao de carga
	dbSelectArea("Z51")
	Z51->(dbSetOrder(1)) // 1 - Z51_FILIAL, Z51_NUMSOL, Z51_ITEM
	Z51->(dbSeek( _cSeekZ51 := xFilial("Z51") + Z50->Z50_NUMSOL ))

	// loop dos itens
	While Z51->( ! Eof() ) .And. ((Z51->Z51_FILIAL + Z51->Z51_NUMSOL) == _cSeekZ51)

		// zera variaveis
		_cNrPedCli  := ""
		_lItemOk    := .T.
		_lCortaItem := .F.

		// descarta itens cortados
		If (_lItemOk) .And. (Z51->Z51_STATUS == "06") // 06-Cortado
			// define log do item
			_cLogItem := "Item " + Z51->Z51_ITEM + " do Produto/Sku " + AllTrim(Z51->Z51_CODPRO) + " cortado desta solicitação"
			// controle de item ok
			_lItemOk := .F.
			// controle de item cortado do pedido
			_lCortaItem := .T.
		EndIf

		// verifica se o produto existe
		If (_lItemOk)

			// cadastro do produto
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
			// pesquisa pelo codigo
			If ( ! SB1->(dbSeek( xFilial("SB1") + Z51->Z51_CODPRO )))

				// verifica se existe mais de um codigo para o mesmo produto
				If ( (Z50->Z50_CODCLI == "000316") .And. ( Empty(sfVldNewCod(Z51->Z51_CODPRO)) ) ) .Or. (Z50->Z50_CODCLI != "000316")

					// variavel de retorno
					_lRet := .F.
					// controle de item ok
					_lItemOk := .F.

					// atualiza mensagem de LOG
					_cErroLog += "Incosistência: Item: " + Z50->Z51_ITEM + " - Produto " + AllTrim(Z51->Z51_CODPRO) + " não cadastrado!" + CRLF + CRLF

					// define log do item
					_cLogItem := "Produto " + AllTrim(Z51->Z51_CODPRO) + " não cadastrado!"

				EndIf
			EndIf
		EndIf

		// pesquisa notas fiscais de entrada
		If (_lItemOk)

			// estrutura do vetor _aNotasEnt
			// 1-B6_DOC
			// 2-B6_SERIE
			// 3-D1_ITEM
			// 4-(B6_SALDO - B6_QULIB)
			// 5-D1_VUNIT
			// 6-D1_TES
			// 7-B6_IDENT
			// 8-B6_PRODUTO
			// 9-D1_DESCRIC
			//10-local/armazem
			//11-D1_LOTECTL
			//12-D1_QUANT
			//13-D1_TOTAL

			// funcao que pesquisa notas fiscais de entrada
			If ( ! sfVldNfEnt(Z51->Z51_CODPRO, @_aNotasEnt, Z51->Z51_NFREM, Z51->Z51_SERREM, @_nPcNfIdent) )

				// variavel de retorno
				_lRet := .F.
				// controle de item ok
				_lItemOk := .F.

				// atualiza mensagem de LOG
				_cErroLog += "Inconsistência: Item: " + Z51->Z51_ITEM + " - Não foi possível localizar notas fiscais de entrada com saldo suficiente ou disponível/liberado para o produto " + AllTrim(Z51->Z51_CODPRO) + CRLF + CRLF
				// define log do item
				_cLogItem := "Não foi possível localizar notas fiscais de entrada com saldo suficiente ou disponível/liberado para este Produto/Sku"

			EndIf
		EndIf

		// verifica saldo disponiveis por nota fiscal
		If (_lItemOk)

			// saldo a ser atendido da quantidade solicitada
			_nQtdSolic := Z51->Z51_QTDSOL

			// varre todas as notas ateh atender o saldo solicitado
			For _nItNota := 1 to Len(_aNotasEnt)

				// zera variaveis
				_nQtdJaUti := 0

				// se ja tem definido a posicao dos campos
				If (_nPcPvIdent != 0) .And. (_nPcPvQuant != 0) .And. (_nPcNfIdent != 0)
					// calcula a quantidade do item da nota de armazenagem ja utilizado em outros itens deste mesmo pedido
					aEval(_aIteAuto, {|x| _nQtdJaUti += IIf((x[_nPcPvIdent][2] == _aNotasEnt[_nItNota][_nPcNfIdent]), x[_nPcPvQuant][2], 0) })
				EndIf

				// diminui quantidade do item
				If (_nQtdJaUti > 0)
					_aNotasEnt[_nItNota][4] -= _nQtdJaUti
				EndIf

				// somente notas com saldo
				If (_aNotasEnt[_nItNota][4] == 0)
					// loop dos itens da nota
					Loop
				EndIf

				// zera variavel do lote
				_cLoteSolic := CriaVar("C6_LOTECTL")

				// reinicio a variavel
				_nQuant := 0

				// estrutura do vetor _aNotasEnt
				// 1-B6_DOC
				// 2-B6_SERIE
				// 3-D1_ITEM
				// 4-(B6_SALDO - B6_QULIB)
				// 5-D1_VUNIT
				// 6-D1_TES
				// 7-B6_IDENT
				// 8-B6_PRODUTO
				// 9-D1_DESCRIC
				//10-Local/Armazem
				//11-D1_LOTECTL
				//12-D1_QUANT
				//13-D1_TOTAL

				// verifica o saldo por lote
				If ( _lLotAtivo ) .And. ( Rastro(Z51->Z51_CODPRO, "L") )

					// estrutura do vetor _aLotesSol
					// 1-seq pedido do cliente
					// 2-seq item no arquivo
					// 3-codigo do produto
					// 4-numero do lote
					// 5-ID do palete
					// 6-Quantidade
					// 7-Saldo

					// varre o vetor de lotes para selecionar de acordo com o item
					For _nLote := 1 to Len(_aLotesSol)

						// controle do saldo do lote
						If (_aLotesSol[_nLote][7] != 0)

							// variavel temporária pro lote
							_cTmpLotProd := PadR( AllTrim(_aLotesSol[_nLote][3])   , TamSx3("D1_COD")[1] )
							_cTmpLotPed  := PadR( AllTrim(_aLotesSol[_nLote][4])   , TamSx3("B8_LOTECTL")[1] )
							_cTmpLotNf   := PadR( AllTrim(_aNotasEnt[_nItNota][11]), TamSx3("D1_LOTECTL")[1] )
							_cTmpLotSeq  := _aLotesSol[_nLote][2]

							// se o produto e lote solicitado é o que foi encontrado nas notas
							If( _cCodProd == _cTmpLotProd ) .And. ( _cTmpLotPed == _cTmpLotNf ) .And. (_aItensSol[_nItem][10] == _cTmpLotSeq)

								// define lote
								_cLoteSolic := _cTmpLotPed

								// grava posicao do vetor, para controle de saldo
								_nTmpLotSel := _nLote

								// sai do loop
								Exit
							EndIf
						EndIf

					Next _nLote

				EndIf

				// se controla lote e não encontrou o lote solicitado vai pra próxima nota
				If ( _lLotAtivo ) .And. ( Rastro(_cCodProd,"L") ) .And. ( Empty(_cLoteSolic) )
					// loop dos itens da nota
					Loop
				EndIf

				// se for igual ou menor que o saldo da nota
				If (_nQtdSolic <= _aNotasEnt[_nItNota][4])
					_nQuant := _nQtdSolic
				Else
					_nQuant := _aNotasEnt[_nItNota][4]
				EndIf

				// defino a TES
				_cTes := Posicione("SF4", 1, xFilial("SF4") + _aNotasEnt[_nItNota][6], "F4_TESDV")

				// verifica o cadastro de TES
				If ( Posicione("SF4", 1, xFilial("SF4") + _cTes, "F4_MSBLQL") == "1" )

					// variavel de retorno
					_lRet := .F.
					// controle de item ok
					_lItemOk := .F.

					// atualiza mensagem de LOG
					_cErroLog += "Incosistência: Item: " + Z51->Z51_ITEM + " - TES " + SF4->F4_CODIGO + " bloqueada para uso" + CRLF + CRLF

					// define log do item
					_cLogItem := "TES " + SF4->F4_CODIGO + " bloqueada para uso"

				EndIf

				// se os dados do item estao ok, inclui item no pedido de venda
				If (_lItemOk)

					// zera vetor da linha
					_aItemPedVen := {}

					// alimenta os itens do pedido de venda
					aAdd(_aItemPedVen,{"C6_ITEM"   , _cIteAuto               , Nil}) // item sequencial do pedido de venda
					aAdd(_aItemPedVen,{"C6_PRODUTO", Z51->Z51_CODPRO         , Nil}) // codigo do produto
					aAdd(_aItemPedVen,{"C6_DESCRI" , _aNotasEnt[_nItNota][ 9], Nil}) // descricao do produto
					// quantidade solicitada
					aAdd(_aItemPedVen,{"C6_QTDVEN" , _nQuant                 , Nil}) ; _nPcPvQuant := Len(_aItemPedVen)
					aAdd(_aItemPedVen,{"C6_PRCVEN" , _aNotasEnt[_nItNota][ 5], Nil}) // valor unitario mercadoria
					// tratamento para arredondamento do valor total (conforme cada cliente) - devolucao total
					If (_nQuant == _aNotasEnt[_nItNota][12])
						aAdd(_aItemPedVen,{"C6_VALOR" , _aNotasEnt[_nItNota][13] , Nil})
					EndIf
					aAdd(_aItemPedVen,{"C6_TES"    , _cTes    , Nil})
					aAdd(_aItemPedVen,{"C6_NFORI"  , _aNotasEnt[_nItNota][ 1], Nil}) // numero da nota fiscal de armazenagem
					aAdd(_aItemPedVen,{"C6_SERIORI", _aNotasEnt[_nItNota][ 2], Nil}) // serie da nota fiscal de armazenagem
					aAdd(_aItemPedVen,{"C6_ITEMORI", _aNotasEnt[_nItNota][ 3], Nil}) // item da nota fiscal de armazenagem

					// NUMSEQ da nota fiscal de armazenagem
					aAdd(_aItemPedVen,{"C6_IDENTB6", _aNotasEnt[_nItNota][ 7], Nil}) ; _nPcPvIdent := Len(_aItemPedVen)
					aAdd(_aItemPedVen,{"C6_LOCAL"  , _aNotasEnt[_nItNota][10], Nil}) // local/armazem da nota fiscal de armazenagem
					aAdd(_aItemPedVen,{"C6_LOTECTL", _cLoteSolic             , Nil}) // numero do lote
					aAdd(_aItemPedVen,{"C6_ZTPESTO", "000001"                , Nil}) // tipo de estoque padrao (000001-NORMAL)
					aAdd(_aItemPedVen,{"C6_PEDCLI" , _cNrPedCli              , Nil}) // numero do pedido de venda do cliente
					aAdd(_aItemPedVen,{"C6_ZQTDVOL", _nTmpQtdVol             , Nil}) // quantidade de volumes por produto (uso exclusivo Portobello)
					aAdd(_aItemPedVen,{"C6_ZQTDPLT", _nTmpQtdPlt             , Nil}) // quantidade de paltes por produto (uso exclusivo Portobello)
					aAdd(_aItemPedVen,{"C6_ZNRSOLC", Z51->Z51_NUMSOL         , Nil}) // numero solicitacao de carga
					aAdd(_aItemPedVen,{"C6_ZITSOLC", Z51->Z51_ITEM           , Nil}) // item da solicitacao de carga
					aAdd(_aItemPedVen,{"AUTDELETA" , "N"                     , Nil})

					// atualiza vetor da rotina automatica
					aAdd(_aIteAuto, _aItemPedVen)

					// incrementa proximo item do pedido de venda
					_cIteAuto := SomaIt(_cIteAuto)

					// controle da quantidade atendida
					_nQtdSolic -= _nQuant
					// diminui o saldo da nota
					_aNotasEnt[_nItNota][4] -= _nQuant

					// zera variaveis, para nao duplicar linhas do pedido quando usar o saldo de mais de uma nota fiscal
					_nTmpQtdVol := 0
					_nTmpQtdPlt := 0

					// diminui o saldo do controle do lote
					If ( _lLotAtivo ) .And. ( Rastro(Z51->Z51_CODPRO ,"L") ) .And. ( ! Empty(_cLoteSolic) ) .And. (_nTmpLotSel != 0)
						// reduza controle de saldo do lote
						_aLotesSol[_nTmpLotSel][7] -= _nQuant
					EndIf

					// se o saldo da quantidade solicitada foi atendido
					If ( _nQtdSolic == 0 )
						// sai do loop dos itens das notas fiscais
						Exit

						// se nao tem saldo suficiente para atender a quandidade solicitada
					ElseIf ( _nQtdSolic > 0 ) .And. ( Len(_aNotasEnt) == _nItNota )

						// variavel de retorno
						_lRet := .F.
						// controle de item ok
						_lItemOk := .F.

						// atualiza saldo disponível (já estou posicionado no item)
						dbSelectArea("Z51")
						RecLock("Z51", .F.)
						Z51->Z51_QTDDIS := Z51->Z51_QTDSOL - _nQtdSolic
						Z51->(MsUnLock())

						// atualiza mensagem de LOG
						_cErroLog += "Inconsistência: Item: " + Z51->Z51_ITEM + " - Saldo Insuficiente do produto: " + AllTrim(Z51->Z51_CODPRO) + CRLF + CRLF
						// define log do item
						_cLogItem := "Saldo Insuficiente de Produto/Sku"

					EndIf
				EndIf

			Next _nItNota

			// se mesmo depois de validar o saldo dos itens das notas fiscais ainda nao atendeu o saldo total solicitado
			If ( _nQtdSolic > 0 )

				// variavel de retorno
				_lRet := .F.
				// controle de item ok
				_lItemOk := .F.

				// atualiza saldo disponível (já estou posicionado no item)
				dbSelectArea("Z51")
				RecLock("Z51", .F.)
				Z51->Z51_QTDDIS := Z51->Z51_QTDSOL - _nQtdSolic
				Z51->(MsUnLock())

				// atualiza mensagem de LOG
				_cErroLog += "Inconsistência: Item: " + Z51->Z51_ITEM + " - Saldo Insuficiente do produto: " + AllTrim(Z51->Z51_CODPRO) + CRLF + CRLF
				// define log do item
				_cLogItem := "Saldo Insuficiente de Produto/Sku"

			EndIf

		EndIf

		// atualiza log de item que foi definido como CORTE
		If (_lCortaItem)
			// atualiza campo de controle
			dbSelectArea("Z51")
			RecLock("Z51", .F.)
			Z51->Z51_LOG := _cLogItem
			Z51->(MsUnLock())

			// demais itens, aptos para importacao
		ElseIf ( ! _lCortaItem )

			// se nao passou em alguma das validacoes
			If ( ! _lItemOk )
				// atualiza campo de controle
				dbSelectArea("Z51")
				RecLock("Z51", .F.)
				Z51->Z51_STATUS := "03" // 03-Com Problemas
				Z51->Z51_LOG    := _cLogItem
				Z51->(MsUnLock())

			ElseIf (_lItemOk)
				// define log do item
				_cLogItem := "Estoque Ok"

				// atualiza campo de controle
				dbSelectArea("Z51")
				RecLock("Z51", .F.)
				Z51->Z51_STATUS := "02" // 02-Liberado para Integração
				Z51->Z51_LOG    := _cLogItem
				Z51->(MsUnLock())

			EndIf
		EndIf

		// proximo item
		dbSelectArea("Z51")
		Z51->(dbSkip())

	EndDo

Return(_lRet)

// ** funcao interna padrao do SPEDNFE
// utilizada para consultar o status da NFe no SEFAZ
Static Function ConsNFeChave(cChaveNFe, cIdEnt, mvLogCabec)

	Local cURL      := PadR(GetNewPar("MV_SPEDURL","http://"),250)
	Local cMensagem := ""
	Local _oWS
	local _lRet := .F.

	// prepara objeto de conexao com o WebService TSS
	_oWS := WsNFeSBra():New()
	_oWS:cUserToken := "TOTVS"
	_oWS:cID_ENT    := cIdEnt
	_oWS:cCHVNFE    := cChaveNFe
	_oWS:_URL       := AllTrim(cURL)+"/NFeSBRA.apw"

	// invoca metodo padrao TSS para consulta da chave da nota no SEFAZ
	If (_oWS:ConsultaChaveNFE())

		If ( ! Empty(_oWS:oWSCONSULTACHAVENFERESULT:cVERSAO) )
			cMensagem += "Versão da mensagem: "+_oWS:oWSCONSULTACHAVENFERESULT:cVERSAO+CRLF
		EndIf

		// detalha mensagem
		cMensagem += "Ambiente: " + IIf(_oWS:oWSCONSULTACHAVENFERESULT:nAMBIENTE==1, "Produção", "Homologação") + CRLF
		cMensagem += "Cod.Ret.NFe: " + _oWS:oWSCONSULTACHAVENFERESULT:cCODRETNFE + CRLF
		cMensagem += "Msg.Ret.NFe: " + _oWS:oWSCONSULTACHAVENFERESULT:cMSGRETNFE + CRLF

		// variavel de retorno (nota valida e ambiente producao)
		_lRet := (AllTrim(_oWS:oWSCONSULTACHAVENFERESULT:cCODRETNFE)=="100") .And. (_oWS:oWSCONSULTACHAVENFERESULT:nAMBIENTE==1)

		If ( ! Empty(_oWS:oWSCONSULTACHAVENFERESULT:cPROTOCOLO) )
			cMensagem += "Protocolo: " + _oWS:oWSCONSULTACHAVENFERESULT:cPROTOCOLO+CRLF
		EndIf

		// se for falha na consulta, atualiza mensagem de retorno
		If ( ! _lRet )
			mvLogCabec := cMensagem
		EndIf

	Else
		mvLogCabec := IIf(Empty(GetWscError(3)), GetWscError(1), GetWscError(3))
	EndIf

Return(_lRet)

// ** funcao que pesquisa as notas de entrada para o produto
Static Function sfVldNfEnt(mvCodProd, mvNotasEnt, mvNfEnt, mvSerEnt, mvPcNfIdent)
	// variavel de retorno
	local _lRet := .F.
	// query de pesquisa
	local _cQuery := ""
	// variaveis temporarias
	local _nX
	// novo codigo de produto
	local _cNewCodProd := CriaVar("B1_COD",.F.)

	// zera a variavel
	mvNotasEnt := {}

	// verifica se existe mais de um codigo para o mesmo produto
	If (Z50->Z50_CODCLI == "000316")
		_cNewCodProd := sfVldNewCod(mvCodProd)
	EndIf

	// busca todas as notas de entrada deste produto com saldo
	_cQuery := " SELECT B6_DOC, B6_SERIE, D1_ITEM, "
	_cQuery += " (B6_SALDO - B6_QULIB - Isnull((SELECT Sum(C0_QUANT) FROM " +RetSqlTab("SC0")+ " WHERE SB6.B6_IDENT = C0_ZIDENT AND SB6.B6_DOC = C0_ZNOTA AND SB6.B6_SERIE = C0_ZSERIE AND "+RetSqlCond("SC0")+"),0)) B6_SALDO, "
	_cQuery += " D1_VUNIT, D1_TES, B6_IDENT, B6_PRODUTO, D1_DESCRIC, B6_LOCAL, D1_LOTECTL, D1_QUANT, D1_TOTAL "
	// saldo poder de terceiros
	_cQuery += " FROM " + RetSqlTab("SB6")
	// dados dos itens das notas de entrada
	_cQuery += " INNER JOIN " + RetSqlTab("SD1") + " ON " + RetSqlCond("SD1")
	_cQuery += "       AND D1_DOC = B6_DOC AND D1_SERIE = B6_SERIE AND D1_FORNECE = B6_CLIFOR AND D1_LOJA = B6_LOJA "
	_cQuery += "       AND D1_COD = B6_PRODUTO AND D1_IDENTB6 = B6_IDENT "
	_cQuery += "       AND D1_TIPO = 'B' "
	// filtro do poder de terceiros
	_cQuery += " WHERE " + RetSqlCond("SB6")
	_cQuery += " AND B6_CLIFOR = '" + Z50->Z50_CODCLI + "' AND B6_LOJA = '" + Z50->Z50_LOJCLI + "' "
	_cQuery += " AND ("
	_cQuery += "     B6_PRODUTO = '" + mvCodProd + "' "
	If ( ! Empty(_cNewCodProd) )
		_cQuery += " OR B6_PRODUTO = '" + _cNewCodProd + "' "
	EndIf
	_cQuery += ") "
	// tipo (Cliente ou Fornecedor)
	_cQuery += " AND B6_TPCF = 'C' "
	// poder de 3o - REMESSA
	_cQuery += " AND B6_PODER3 = 'R' "
	// somente com saldo
	_cQuery += " AND (B6_SALDO - B6_QULIB - Isnull((SELECT Sum(C0_QUANT) FROM " +RetSqlName("SC0")+ " SC0 WHERE SB6.B6_IDENT = C0_ZIDENT AND SB6.B6_DOC = C0_ZNOTA AND SB6.B6_SERIE = C0_ZSERIE AND "+RetSqlCond("SC0")+"),0)) > 0 "
	// filtra informacoes por nota, caso tenha sido informado
	If ( ! Empty(mvNfEnt) )
		_cQuery += " AND B6_DOC = '" + mvNfEnt + "' "
	EndIf
	If ( ! Empty(mvSerEnt) )
		_cQuery += " AND B6_SERIE = '" + mvSerEnt + "' "
	EndIf

	// ordem por data de digitacao de documentos
	_cQuery += "ORDER BY B6_DTDIGIT, B6_SERIE, B6_DOC "

	MemoWrit("c:\query\twmsa038_sfVldNfEnt.txt", _cQuery)

	// converte resultado para ARRAY
	mvNotasEnt := U_SqlToVet(_cQuery)
	// variavel de retorno
	_lRet := (Len(mvNotasEnt) > 0)

	// define posicao do campo B6_IDENT
	If (mvPcNfIdent == 0)
		mvPcNfIdent := 7
	EndIf

Return( _lRet )

// ** funcao que valida os dados da transportadora
Static Function sfVldTransp(mvCnpj, mvPlaca, mvLogCabec )

	// variavel de retorno
	local _lRet := .T.

	// posicao inicial das tabelas
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"SA4", "DA3"})

	// valores padroes
	Default mvCnpj  := CriaVar("A4_CGC", .F.)
	Default mvPlaca := CriaVar("C5_VEICULO", .F.)

	// padroniza CNPJ
	mvCnpj := AllTrim(mvCnpj)
	// remove pontos
	mvCnpj := StrTran(mvCnpj,".","")
	// remove barras
	mvCnpj := StrTran(mvCnpj,"/","")
	// remove hifen
	mvCnpj := StrTran(mvCnpj,"-","")

	// padroniza placa
	mvPlaca := AllTrim(Upper(mvPlaca))
	// remove hifen
	mvPlaca := StrTran(mvPlaca,"-","")

	// pesquisa, quando tem CNPJ informado
	If ( ! Empty(mvCnpj) )

		// pesquisa a transportadora
		dbSelectArea("SA4")
		SA4->(dbSetOrder(3)) // 3-A4_FILIAL, A4_CGC
		If ( ! SA4->(dbSeek( xFilial("SA4") + mvCnpj )))
			// mensagem
			mvLogCabec := "Transportadora com CNPJ " + Transf(mvCnpj, PesqPict("SA4","A4_CGC") ) + " não cadastrada."
			// restaura areas iniciais
			RestOrd(_aAreaIni,.T.)
			RestArea(_aAreaAtu)
			// variavel de controle do retorno
			_lRet := .F.
		Else
			// armazena informacoes da transportadora
			_cPedTransp	:= SA4->A4_COD

		EndIf

	EndIf

	// pesquisa, quando tem PLACA informada
	If ( ! Empty(mvPlaca) )
		// pesquisa a placa
		dbSelectArea("DA3")
		DA3->(dbSetOrder(3)) // 3-DA3_FILIAL, DA3_PLACA
		If ( ! DA3->(dbSeek( xFilial("DA3") + mvPlaca )))
			// mensagem
			mvLogCabec := "Veículo com Placa " + Transf(mvPlaca, PesqPict("DA3","DA3_PLACA")) + " não cadastrado."
			// restaura areas iniciais
			RestOrd(_aAreaIni,.T.)
			RestArea(_aAreaAtu)
			// variavel de controle do retorno
			_lRet := .F.
		Else
			// armazena informacoes da transportadora
			_cPedPlaca := DA3->DA3_COD
		EndIf
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aAreaAtu)

Return( _lRet )

// ** funcao que verifica se existe mais de um codigo para o mesmo produto
Static Function sfVldNewCod(mvCodProd)
	// variavel de retorno
	local _cRetCodProd := Space(Len(mvCodProd))
	// query
	local _cQuery

	// monta a query para buscar o codigo de produto relacionado
	_cQuery := " SELECT A7_PRODUTO "
	_cQuery += " FROM " + RetSqlTab("SA7")
	_cQuery += " WHERE " + RetSqlCond("SA7")
	_cQuery += " AND A7_CLIENTE = '" + Z50->Z50_CODCLI + "' AND A7_LOJA = '" + Z50->Z50_LOJCLI + "' "
	_cQuery += " AND A7_CODCLI = '" + mvCodProd + "' "
	// executa a query
	_cRetCodProd := U_FtQuery(_cQuery)

Return(_cRetCodProd)

// ** funcao que prepara mensagem para envio por email
Static Function sfEnviaMail()

	// posicao inicial das tabelas
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"Z50", "Z51", "SA1"})

	// seek
	local _cSeekZ51

	// variavel com conteudo da mensagem
	local _cMailMsg := ""

	// relacao de email do depositante (funcao: sfRetMail | Fonte: WsIntCadDepositante)
	local _cDestMail := StaticCall(WsIntCadDepositante, sfRetMail, Z50->Z50_CODCLI, Z50->Z50_LOJCLI, .F.)

	// mascara para campos quantidade
	local _cMaskQuant := U_FtWmsParam("WMS_MASCARA_CAMPO_QUANTIDADE", "C", PesqPict("SD1","D1_QUANT"), .F., "", Z50->Z50_CODCLI, Z50->Z50_LOJCLI, Nil, Nil)

	// prepara mensagem que sera enviada por email
	_cMailMsg += '<meta http-equiv="Content-Type" content="text/html;charset=ISO-8859-1">'
	_cMailMsg += '<table width="780px" align="center">'
	_cMailMsg += '   <tr>'
	_cMailMsg += '      <td>'
	_cMailMsg += '         <table style="border-collapse: collapse;font-family: Tahoma; font-size: 12px;" border="1" width="100%" cellpadding="2" cellspacing="0" align="center" >'
	_cMailMsg += '            <tr  height="30">'
	_cMailMsg += '               <td colspan="4" style="background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Status de Solicitações de Cargas</td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr>'
	_cMailMsg += '               <td width="15%" >Filial</td>'
	_cMailMsg += '               <td width="35%" >103-TECADI SC</td>'
	_cMailMsg += '               <td width="15%" >Data/Hora</td>'
	_cMailMsg += '               <td width="35%" >' + IIf(Empty(Z50->Z50_DTPED), '', DtoC(Z50->Z50_DTPED) + ' as ' + Z50->Z50_HRPED + ' h') + '</td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr>'
	_cMailMsg += '               <td width="15%">Número Controle</td>'
	_cMailMsg += '               <td width="85%" colspan="3" style="font-weight: bold;">' + Z50->Z50_NUMSOL + '</td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr>'
	_cMailMsg += '               <td width="15%" >Depositante</td>'
	_cMailMsg += '               <td width="85%" colspan="3">' + AllTrim( Posicione('SA1', 1, xFilial('SA1') + Z50->Z50_CODCLI + Z50->Z50_LOJCLI, 'A1_NOME') ) + '</td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr>'
	_cMailMsg += '               <td width="15%" >Arquivo</td>'
	_cMailMsg += '               <td width="85%" colspan="3">' + AllTrim(Z50->Z50_ARQUIV) + '</td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr>'
	_cMailMsg += '               <td width="15%" >Nome do Solicitante</td>'
	_cMailMsg += '               <td width="35%" >' + '</td>'
	_cMailMsg += '               <td width="15%" >e-mail</td>'
	_cMailMsg += '               <td width="35%" >' + '</td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr>'
	_cMailMsg += '               <td width="15%" >Pedido Cliente</td>'
	_cMailMsg += '               <td width="35%" style="font-weight: bold;">' + AllTrim(Z50->Z50_PEDCLI) + '</td>'
	_cMailMsg += '               <td width="15%" >Nota Fiscal Venda</td>'
	_cMailMsg += '               <td width="35%" style="font-weight: bold;">' + AllTrim(Z50->Z50_NFVNR) + '</td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr>'
	_cMailMsg += '               <td width="15%" >Transportadora</td>'
	_cMailMsg += '               <td width="35%" >' + '</td>'
	_cMailMsg += '               <td width="15%" ></td>'
	_cMailMsg += '               <td width="35%" ></td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr>'
	_cMailMsg += '               <td colspan="4" style="background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Dados de Entrega</td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr>'
	_cMailMsg += '               <td width="15%" >Cliente</td>'
	_cMailMsg += '               <td width="85%" colspan="3">' + AllTrim(Z50->Z50_ENTCGC) + ' ' + AllTrim(Z50->Z50_ENTNOM)+ '</td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr>'
	_cMailMsg += '               <td width="15%" >Endereço</td>'
	_cMailMsg += '               <td width="85%" colspan="3">' + AllTrim(Z50->Z50_ENTEND) + '</td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr>'
	_cMailMsg += '               <td width="15%" >Cidade</td>'
	_cMailMsg += '               <td width="35%">' + AllTrim(Z50->Z50_ENTMUN) + '</td>'
	_cMailMsg += '               <td width="15%" >UF</td>'
	_cMailMsg += '               <td width="35%" >' + AllTrim(Z50->Z50_ENTEST) + '</td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr>'
	_cMailMsg += '               <td width="15%" >Bairro</td>'
	_cMailMsg += '               <td width="85%" colspan="3">' + AllTrim(Z50->Z50_ENTBAI) + '</td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr>'
	_cMailMsg += '               <td colspan="4" style="background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Status</td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr height="30">'
	// status da conversao da solicitacao de carga
	If (Z50->Z50_STATUS == "05")
		_cMailMsg += '               <td width="100%" colspan="4"><span style="background-color: #2E8B57">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>&nbsp;Pedido de Separação gerado com Sucesso!  <strong>Número: ' + Z50->Z50_PEDIDO + '</strong></td>'
	ElseIf (Z50->Z50_STATUS != "05")
		_cMailMsg += '               <td width="100%" colspan="4"><span style="background-color: #FF0000">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>&nbsp;Inconsistência na validação dos dados' + IIf(Empty(Z50->Z50_LOG), '', ': ' + AllTrim(Z50->Z50_LOG))+ '</strong></td>'
	EndIf
	_cMailMsg += '            </tr>'
	_cMailMsg += '         </table>'
	_cMailMsg += '         <br>'
	_cMailMsg += '         <table style="border-collapse: collapse;font-family: Tahoma; font-size: 12px;" border="1" width="100%" cellpadding="2" cellspacing="0" align="center" >'
	_cMailMsg += '            <tr height="30">'
	_cMailMsg += '               <td colspan="7" style="background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Itens da Solicitação de Carga</td>'
	_cMailMsg += '            </tr>'
	_cMailMsg += '            <tr style="background-color: #87CEEB;">'
	_cMailMsg += '               <td width="10%">Código/SKU</td>'
	_cMailMsg += '               <td width="45%">Descrição</td>'
	_cMailMsg += '               <td width="5%">UM</td>'
	_cMailMsg += '               <td width="15%">Quant Solicitada</td>'
	_cMailMsg += '               <td width="15%">Quant Disponível</td>'
	_cMailMsg += '               <td width="15%">Quant Entregue</td>'
	_cMailMsg += '               <td width="10%">Status</td>'
	_cMailMsg += '            </tr>'

	// pesquisa item da solicitacao de carga
	dbSelectArea("Z51")
	Z51->(dbSetOrder(1)) // 1 - Z51_FILIAL, Z51_NUMSOL, Z51_ITEM
	Z51->(dbSeek( _cSeekZ51 := xFilial("Z51") + Z50->Z50_NUMSOL ))

	// loop dos itens
	While Z51->( ! Eof() ) .And. ((Z51->Z51_FILIAL + Z51->Z51_NUMSOL) == _cSeekZ51)

		// posiciona no cadastro do item
		dbSelectArea("SB1")
		SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
		SB1->(dbSeek( xFilial("SB1") + Z51->Z51_CODPRO ))

		// incrementa informacos do item
		_cMailMsg += '            <tr ' + IIf(Z51->Z51_STATUS == "03", 'style="background-color: #FFA07A;"', '') + '>'
		_cMailMsg += '               <td>' + AllTrim(SB1->B1_CODCLI) + '</td>'
		_cMailMsg += '               <td>' + AllTrim(SB1->B1_DESC) + '</td>'
		_cMailMsg += '               <td align="center" >' + SB1->B1_UM + '</td>'
		_cMailMsg += '               <td align="center">' + AllTrim( Transf(Z51->Z51_QTDSOL, _cMaskQuant) ) + '</td>'
		_cMailMsg += '               <td align="center">' + AllTrim( Transf(Z51->Z51_QTDDIS, _cMaskQuant) ) + '</td>'
		_cMailMsg += '               <td align="center">' + AllTrim( Transf(Z51->Z51_QTDENT, _cMaskQuant) ) + '</td>'
		_cMailMsg += '               <td align="center">' + AllTrim( Z51->Z51_LOG ) + '</td>'
		_cMailMsg += '            </tr>'

		// proximo item
		dbSelectArea("Z51")
		Z51->(dbSkip())
	EndDo

	// finaliza tabela geral
	_cMailMsg += '         </table>'
	_cMailMsg += '         <br>'
	_cMailMsg += '      </td>'
	_cMailMsg += '   </tr>'
	_cMailMsg += '</table>'

	// restaura areas iniciais
	RestOrd(_aAreaIni, .T.)
	RestArea(_aAreaAtu)

	// registra mensagem de email
	U_FtMail(_cMailMsg, 'TECADI - Status de Solicitação de Cargas', _cDestMail)

Return( Nil )

// ** função para conversao (em massa) de solicitacao de cargas em pedido de venda
User Function WMSA038A(mvScheduler)

	// variavel de controle de transação
	local _lRet := .F.

	// query para consulta dos dados na tabela
	local _cQuery := ""

	// grupo de perguntas
	local _cPerg := PadR("WMSA038A", 10)

	// numero do pedido
	local _cNewPedido := ""

	// variaveis temporarias
	local _aTmpDados := {}
	local _nSolCar

	// hora inicial por Solicitacao
	local _cHrInic := ""

	// valor padrao
	Default mvScheduler := .F.

	// chama tela com parametros
	If ( ! mvScheduler )
		// apresenta perguntas na tela
		If ( ! Pergunte(_cPerg,.T.) )
			Return
		EndIf
	EndIf

	// prepara query que busca solicitacoes disponiveis para conversao
	_cQuery := " SELECT Z50.R_E_C_N_O_ Z50RECNO "
	// cad. solicitacoes de carga
	_cQuery += " FROM   " + RetSqlTab("Z50")
	// filtro padrao
	_cQuery += " WHERE  " + RetSqlCond("Z50")
	// codigo e loja do cliente
	_cQuery += "        AND Z50_CODCLI = '" + mv_par01 + "' AND Z50_LOJCLI = '" + mv_par02 + "' "
	// status - 02-Liberado para Integração
	_cQuery += "        AND Z50_STATUS = '02' "
	// e que não ainda não tentou integrar
	_cQuery += "        AND Z50_NRTENT = 0 "
	// ordem dos dados
	_cQuery += " ORDER  BY Z50_PRIORI, "
	_cQuery += "           Z50.R_E_C_N_O_ "

	// atualiza variavel de controle
	_aTmpDados := U_SqlToVet(_cQuery)

	// varre todas as solicitacoes de cargas
	For _nSolCar := 1 to Len(_aTmpDados)

		// posiciona no registro real
		dbSelectArea("Z50")
		Z50->( DbGoTo( _aTmpDados[_nSolCar]) )

		// realiza tentativa de bloqueio do registro
		If ( ! MsrLock() )
			// em lock então loop para a próxima
			Sleep(5000)
			Loop
		EndIf

		// se registro ok, bloqueia registro
		SoftLock("Z50")

		// hora inicial por Solicitacao
		_cHrInic := Time()

		// zera variaveis
		_cNewPedido := ""

		// chama rotina automatica para conversao da solicitacao em pedido
		U_TWMSA038( .T., .F., Z50->Z50_NUMSOL, @_cNewPedido)

		// libera todos os registros
		MsUnLockAll()

	Next _nSolCar

Return