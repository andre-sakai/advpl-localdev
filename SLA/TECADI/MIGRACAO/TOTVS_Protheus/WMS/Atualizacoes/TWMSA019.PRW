#include "protheus.ch"
#INCLUDE "RWMAKE.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina geracao da OS de Expedicao                       !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 01/2013 !
+------------------+--------------------------------------------------------*/

User Function TWMSA019(mvCarga, mvOndaSep, mvRotAuto)

	// dimensoes da tela
	local _aSizeDlg	:= MsAdvSize()

	// objetos
	local _oWndWmsExp
	local _oPnlBtnOpr, _oPnlBrwSC6, _oPnlBrwDisp
	local _oBrwSC6, _oBrwMovPlt
	local _oBrwDisp1, _oBrwDisp2, _oBrwDisp3
	local _oBtnConfInt, _oBtnGeraEnd, _oBtnEstorno, _oBtnImpMapa, _oBtnFechar
	local _oSayNrCarga, _oSayEndDes, _oGetEndDes
	local _oCkBxLibNf
	local _oFolder

	// pastas do FOLDER
	local _aFolders := {'End.Nota Fiscal', 'End.Sem Etiqueta', 'End.Agrupadoras'}

	// estrutura do arquivo de trabalho e Browse - Itens PV
	local _cQrySC6
	Local _aStruSC6  := {}
	Local _aHeadSC6  := {}
	Local _cTrbSC6
	Local _aCorSC6   := {}

	// estrutura do arquivo de trabalho e Browse - Enderecos Disponiveis COM Etiqueta
	Local _aStruEnd1 := {}
	Local _aHeadEnd1 := {}
	Local _aCorEnd1  := {}

	// estrutura do arquivo de trabalho e Browse - Enderecos Disponiveis SEM Etiqueta
	Local _aStruEnd2 := {}
	Local _aHeadEnd2 := {}
	Local _aCorEnd2  := {}

	// estrutura do arquivo de trabalho e Browse - Enderecos Disponiveis Agrupadora
	Local _aStruEnd3 := {}
	Local _aHeadEnd3 := {}
	Local _aCorEnd3  := {}

	// estrutura do arquivo de trabalho e Browse - Movimentacao de Paletes
	Local _aStruMov := {}
	Local _aHeadMov := {}

	// seek
	local _cSeekDAK
	local _cSeekZ58

	// tudo ok para geracao de OS
	local _lTudoOk := .F.

	// permite a impressao do mapa
	local _lImprMapa := .F.

	// permite gerar mapa
	local _lGeraMapa := .T.

	// dados do cliente
	local _cChvCliente := ""

	// valida se o WMS esta ativo por cliente
	local _lWmsAtivo := .F.

	// busca o armazem padrao por cliente
	local _cArmzPadrao := CriaVar("BE_LOCAL",.F.)

	// estruturas fisicas de Picking
	local _aEstPicking := U_SqlToVet("SELECT DC8_CODEST FROM " + RetSqlTab("DC8") + " (nolock) WHERE " + RetSqlCond("DC8") + " AND DC8_TPESTR = '2'")

	// valores padroes
	Default mvCarga     := CriaVar("DAK_COD"   , .F.)
	Default mvOndaSep   := CriaVar("Z57_CODIGO", .F.)
	Default mvRotAuto   := .F.

	// controle para novo WMS
	PRIVATE _lWmsNovo := .F.

	// alias utilizados
	private _cAlTrbSC6 := GetNextAlias()
	private _cAlTrb1   := GetNextAlias()
	private _cTrbEnd1
	private _cAlTrb2   := GetNextAlias()
	private _cTrbEnd2
	private _cAlTrb3   := GetNextAlias()
	private _cTrbEnd3
	private _cAlTrbMov := GetNextAlias()
	private _cTrbMov

	// fontes utilizadas
	private _oFnt01 := TFont():New("Tahoma",,18,,.T.)

	// endereco de destino
	private _cEndDest := CriaVar("BE_LOCALIZ",.F.)

	// numero da carga
	private _cNumCarga := mvCarga

	// numero da onda de separacap
	private _cNrOndSep := mvOndaSep

	// controle de enderecamento para liberar emissao de nota fiscal
	private _lLibNota := .F.

	// mapa de apanhe com todos os enderecos para movimentacao da expedicao
	private _aMapaApanhe := {}

	// log de processamento
	private _cLogMapa := ""

	// permite completar a carga com produtos de outras notas fiscais
	private _lCompCarga := .F.

	// permite conferencia/recebimento por volumes
	private _lCtrVolume := .F.

	// valida identificacao do produto
	private _cTpIdEtiq := "INTERNA"

	// tipo de identificacao
	private _lEtqIdInt  := .T.
	private _lEtqIdEAN  := .F.
	private _lEtqCod128 := .F.
	private _lEtqIDDun  := .F.

	// estruturas fisicas disponiveis para geracao de mapa de separacao
	private _cEstFisMapa := ""

	// estruturas fisicas de Picking
	private _cEstPicking := ""

	// variavel que controlará os endereços de retirada da mercadoria no caso de lote
	private _lLotAtivo := .F.
	// variavel de controle para quantidade total ou variavel
	private _lUsaSldPlt := .F.
	// número do pedido com base nos itens da carga
	private _cNumPed  := ""
	// query
	private _cQuery   := ""
	// dados do cliente
	private _cCodCli := ""
	private _cLojCli := ""

	// controle se a busca de itens para expedicao ira expedir volumes com Sku distintos
	private _lBuscaAgrup := .F.

	// controle de expede/busca em Kit/Agrupado
	private _lExpEmKit := .F.

	// verifica se o lote eh obrigatorio na saida da nota
	private _lLotObrSai := .F.

	// controle de prioridade para expedicao de paletes
	private _cPriExpPlt := ""
	private _cQryOrdPlt := ""

	// volumes (caixas) ja selecionados no pedido de venda
	private _lVolJaDef := .F.

	// relacao de RECNO bloqueados
	private _aRegLock := {}

	// define origem dos dados
	private _lPorCarga := ((_cNumCarga != Nil) .And. ( ! Empty(_cNumCarga) ))
	private _lPorOnda  := ((_cNrOndSep != Nil) .And. ( ! Empty(_cNrOndSep) ))

	// referencia de pesquisa de parametros
	private _cChvParam := IIf(_lPorCarga, _cNumCarga, _cNrOndSep)
	private _nIndParam := IIf(_lPorCarga, 2, 4)

	// controle se eh chamada por rotina automatica
	private _lRotAuto := mvRotAuto

	// controle para geracao do mapa de expedicao, reservando enderecos de origem
	private _lResEndOri := .F.

	// variáveis de troca de produto no mapa
	private lAltMapa    := .F. //Controle se pode alterar os endereços do mapa de apanhe
	private lTela       := .F. //Controle para forçar mostrar a tela de montagem do mapa de apanhe.
	Private _aTrocaMapa := {}

	// funcao que monta os dados do operador logado no sistema
	Private _aUsrInfo := U_FtWmsOpe()
	// codigo do operador
	Private _lUsrGeren  := (_aUsrInfo[2] == "G")
	
	// range limite para diferentes datas (em dias) no mesmo palete
	Private _nRangeDt := SuperGetMV("TC_LIMISER",.F.,30)

	// verifica se a rotina recebeu parametros corretamente
	If (Empty(_cNumCarga + _cNrOndSep))
		// avisa usuario
		Help( ,, 'TWMSA019.F01.001',, "Processo específico para uso com Cargas ou Onda de Separação. Verifique os parâmetros ou tipo da operação.", 1, 0 )
		// retorno
		Return( .F. )
	EndIf

	// atualiza variavel de estutura fisica de picking
	aEval(_aEstPicking,{|x| _cEstPicking += (x) + "/" })

	// se for mapa por carga
	If ( _lPorCarga ) .And. ( ! _lPorOnda )

		// posiciona na carga selecionada
		dbSelectArea("DAK")
		DAK->(dbSetOrder(1)) // 1-DAK_FILIAL, DAK_COD, DAK_SEQCAR
		If ( ! DAK->(dbSeek( xFilial("DAK") + _cNumCarga )) )
			MsgStop("Carga " + _cNumCarga + " não encontrada!")
			Return(.F.)
		EndIf

		// valida se ha mais de um cliente na mesma carga
		dbSelectArea("DAI")
		DAI->(dbSetOrder(1)) // 1-DAI_FILIAL, DAI_COD, DAI_SEQCAR, DAI_SEQUEN, DAI_PEDIDO
		DAI->(dbSeek( _cSeekDAK := DAK->DAK_FILIAL + DAK->DAK_COD ))
		While DAI->(!Eof()) .And. (DAI->DAI_FILIAL + DAI->DAI_COD == _cSeekDAK)

			// atualiza codigo do cliente
			If (Empty(_cChvCliente))
				// chave de controle
				_cChvCliente := DAI->DAI_CLIENT + DAI->DAI_LOJA
				// codigo e loja
				_cCodCli := DAI->DAI_CLIENT
				_cLojCli := DAI->DAI_LOJA
			EndIf

			// nao permite multiplos clientes na mesma carga
			If (_cChvCliente <> (DAI->DAI_CLIENT + DAI->DAI_LOJA))
				MsgStop("Não é permitido geração de carga para múltiplos clientes.")
				Return(.F.)
			EndIf

			// vou adicionando o números dos pedidos
			_cNumPed += DAI->DAI_PEDIDO + "/"

			// proximo item
			DAI->(dbSkip())
		EndDo

		// se for mapa por onda
	ElseIf ( ! _lPorCarga ) .And. ( _lPorOnda )

		// posiciona na onda selecionada
		dbSelectArea("Z57")
		Z57->(dbSetOrder(1)) // 1 - Z57_FILIAL, Z57_CODIGO
		If ( ! Z57->(dbSeek( xFilial("Z57") + _cNrOndSep )) )
			// avisa usuario
			Help( ,, 'TWMSA019.F01.002',, "Onda de Separação " + _cNrOndSep + " não localizada.", 1, 0 )
			// retorno
			Return(.F.)
		EndIf

		// valida se ha mais de um cliente na mesma onda (temporario - rever em versoes posteriores)
		dbSelectArea("Z58")
		Z58->(dbSetOrder(1)) // 1 - Z58_FILIAL, Z58_CODIGO, Z58_SEQUEN
		Z58->(dbSeek( _cSeekZ58 := Z57->Z57_FILIAL + Z57->Z57_CODIGO ))

		// varre todos os pedidos da onda
		While Z58->( ! Eof() ) .And. (Z58->Z58_FILIAL + Z58->Z58_CODIGO == _cSeekZ58)

			// atualiza codigo do cliente
			If (Empty(_cChvCliente))
				// chave de controle
				_cChvCliente := Z58->Z58_CODCLI + Z58->Z58_LOJCLI
				// codigo e loja
				_cCodCli := Z58->Z58_CODCLI
				_cLojCli := Z58->Z58_LOJCLI
			EndIf

			// nao permite multiplos clientes na mesma carga
			If (_cChvCliente <> (Z58->Z58_CODCLI + Z58->Z58_LOJCLI))
				// avisa usuario
				Help( ,, 'TWMSA019.F01.003',, "Não é permitido geração de mapa de expedição para múltiplos clientes.", 1, 0 )
				// retorno
				Return(.F.)
			EndIf

			// vou adicionando o números dos pedidos
			_cNumPed += Z58->Z58_PEDIDO + "/"

			// proximo item
			Z58->(dbSkip())
		EndDo
	EndIf

	// verifica a configuracao do WMS novo
	_lWmsNovo := (U_FtWmsParam("WMS_VERSAO", "N", 1, .F., "", _cCodCli, _cLojCli, Nil, Nil) == 2)

	// controle de enderecamento para liberar emissao de nota fiscal
	_lLibNota := U_FtWmsParam("WMS_EXPEDICAO_LIBERA_EMISSAO_NF","L",.F.,.F.,"", _cCodCli, _cLojCli, "", "")

	// verifica se o WMS esta ativo
	_lWmsAtivo := U_FtVldCtr(_cCodCli, _cLojCli, "WMS_ATIVO_POR_CLIENTE", _nIndParam, _cChvParam, "L")

	// permite conferencia/recebimento por volumes
	_lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.F.,.F.,"", _cCodCli, _cLojCli, Nil, Nil)

	// valida identificacao do produto
	_cTpIdEtiq := U_FtWmsParam("WMS_PRODUTO_ETIQ_IDENT","C","INTERNA",.F.,"", _cCodCli, _cLojCli, Nil, Nil)

	// controle se a busca de itens para expedicao ira expedir volumes com Sku distintos
	_lBuscaAgrup := U_FtWmsParam("WMS_EXPEDICAO_MAPA_APANHE_AGRUPADO","L",.F.,.F.,Nil, _cCodCli, _cLojCli, Nil, Nil)

	// estruturas fisicas disponiveis para geracao de mapa de separacao
	_cEstFisMapa := U_FtWmsParam("WMS_EXPEDICAO_MAPA_APANHE_ESTRUTURA_FISICA","C","000002/000003/000007",.F.,"", _cCodCli, _cLojCli, Nil, Nil)

	// verifica se o lote eh obrigatorio na saida da nota
	_lLotObrSai := U_FtWmsParam("WMS_LOTE_OBRIGATORIO_SAIDA","L",.F.,.F.,Nil, _cCodCli, _cLojCli, Nil, Nil)

	// obtém a informação do parâmetro que permite quebrar o FIFO na geração do mapa de apanhe (ou seja, se ativo, NÃO RESPEITA a nota informada no pedido de venda)
	_lQbFIFO := U_FtWmsParam("WMS_EXPEDICAO_MAPA_APANHE_QUEBRA_FIFO","L",.F.,.F.,Nil, _cCodCli, _cLojCli, Nil, Nil)

	// controle por número de série
	_lSerieAtv := U_FtWmsParam("WMS_CONTROLE_POR_NUMERO_SERIE","L",.F.,.F.,Nil, _cCodCli, _cLojCli, Nil, Nil)

	//Busca se pode alterar os endereços do mapara de apanhe.
	lAltMapa := U_FtWmsParam("WMS_EXPEDICAO_ALTERA_MAPA_APANHE","L",.F.,.F.,Nil, _cCodCli, _cLojCli, Nil, Nil)

	//Verifica se força a exibição da tela quando a variavel _lRotAuto estiver com conteúdo para executar automaticamente sem interface.
	lTela    := U_FtWmsParam("WMS_EXPEDICAO_MAPA_APANHE_MOSTRA_TELA","L",.F.,.F.,Nil, _cCodCli, _cLojCli, Nil, Nil)
	If lTela
		_lRotAuto := .F.
	EndIf

	// tipo de identificacao
	_lEtqIdInt  := (AllTrim(_cTpIdEtiq) == "INTERNA")
	_lEtqIdEAN  := (AllTrim(_cTpIdEtiq) == "EAN") .Or. (AllTrim(_cTpIdEtiq) == "EAN13")
	_lEtqIdDun  := (AllTrim(_cTpIdEtiq) == "DUN14")
	_lEtqCod128 := (AllTrim(_cTpIdEtiq) == "CODE128")

	// controle de prioridade para expedicao de paletes
	_cPriExpPlt := U_FtWmsParam("WMS_EXPEDICAO_PRIORIZA_PALETE", "C", "ID_PALETE", .F., "", _cCodCli, _cLojCli, Nil, Nil)

	// define o campo para ordenar os dados
	If (AllTrim(_cPriExpPlt) == "ID_PALETE")
		_cQryOrdPlt := "Z16_ETQPAL"
	ElseIf (AllTrim(_cPriExpPlt) == "MENOR_SALDO")
		_cQryOrdPlt := "Z16_SALDO"
	ElseIf (AllTrim(_cPriExpPlt) == "MAIOR_SALDO")
		_cQryOrdPlt := "Z16_SALDO DESC"
	EndIf

	// se nao usa WMS, nao permite usar a rotina
	If ( ! _lWmsAtivo )
		// mensagem
		MsgStop("WMS não está habilitado para este cliente!")
		// retorno
		Return(.F.)
	EndIf

	// valida se o cliente está configurado para WMS versão 2
	If (_lWmsNovo) .AND. (_lPorCarga)
		// avisa usuario
		Help( ,, 'TWMSA019.F01.005',, "Cliente " + AllTrim(_cCodCli) + " não configurado para utilizar OS gerada por carga (WMS 1.0).",;
		1, 0, NIL, NIL, NIL, NIL, NIL, {"Utilize a geração de ordem de serviço no formato ONDA DE SEPARAÇÃO"} )
		// retorno
		Return(.F.)
	EndIf

	// atualiza o armazem padrao do cliente
	_cArmzPadrao := U_FtVldCtr(_cCodCli, _cLojCli, "WMS_ARMAZEM_POR_CLIENTE", _nIndParam, _cChvParam, "C")

	// valido o armazem do cliente
	If (_cArmzPadrao == Nil) .Or. (Empty(_cArmzPadrao))
		// não deixa prosseguir e as mensagem são mostradas dentro da função
		MsgStop("WMSPARAM -> Erro ao consultar contrato armazém padrão do cliente! Verifique!")
		// retorno
		Return .F.
	EndIf

	// Valores permitidos para o parametro mvVar
	// 1 - PROGRAMAÇÃO
	// 2 - CARGA
	// 3 - PEDIDO

	// Valores permitidos para o parametro mvTpRet
	// "L" - Lógico
	// "C" - Caraceter

	// valida se permite completar a carga com produtos de outras notas fiscais baseado no contrato
	_lCompCarga := U_FtVldCtr(_cCodCli, _cLojCli, "WMS_EXPEDICAO_MAPA_APANHE_AGRUPA_NOTAS", _nIndParam, _cChvParam, "L")

	// valida se pode ou não completar carga com outras notas fiscais
	If (_lCompCarga != .T.) .And. (_lCompCarga != .F.)
		// não deixa prosseguir e as mensagem são mostradas dentro da função
		MsgStop("TWMSA019 -> Erro ao consultar parâmetro de complemento de carga! Verifique com gerente de projetos!")
		// retorno
		Return .F.
	EndIf

	// valido o controle de lote por contrato
	_lLotAtivo := U_FtVldCtr(_cCodCli, _cLojCli, "WMS_CONTROLE_POR_LOTE", _nIndParam, _cChvParam, "L")

	// valido o controle de lote
	If (_lLotAtivo != .T.) .And. (_lLotAtivo != .F.)
		// não deixa prosseguir e as mensagem são mostradas dentro da função
		MsgStop("WMSPARAM ->Erro ao consultar controle de lote! Verifique!")
		Return .F.
	EndIf

	// valido o contrato para verificar se o saldo será o do pallet ou variável
	_lUsaSldPlt := U_FtVldCtr(_cCodCli, _cLojCli, "WMS_CONSIDERA_SALDO_PALLET", _nIndParam, _cChvParam, "L")

	// valido o controle de lote
	If (_lUsaSldPlt != .T.) .And. (_lUsaSldPlt != .F.)
		// não deixa prosseguir e as mensagem são mostradas dentro da função
		MsgStop("WMSPARAM ->Erro ao consultar definição de saldo por pallet! Verifique!")
		Return .F.
	EndIf

	// define se o controle de expedicao/busca sera em Kit/Agrupado
	_lExpEmKit := (_lCtrVolume) .And. (_lBuscaAgrup)

	// volumes (caixas) ja selecionados no pedido de venda
	_lVolJaDef := U_FtWmsParam("WMS_EXPEDICAO_ESCOLHE_VOLUMES", "L", .F., .F., Nil, _cCodCli, _cLojCli, Nil, Nil)

	// controle para geracao do mapa de expedicao, reservando enderecos de origem
	_lResEndOri := U_FtWmsParam("WMS_EXPEDICAO_ONDA_SEPARACAO_RESERVA_ENDERECO", "L", .T., .F., Nil, _cCodCli, _cLojCli, Nil, Nil)

	// -- monta o arquivo de trabalho - Itens PV
	aAdd(_aStruSC6,{"C6_PRODUTO" ,"C", TamSx3("C6_PRODUTO")[1],0})
	aAdd(_aStruSC6,{"B1_DESC"    ,"C", TamSx3("B1_DESC")[1]   ,0})
	aAdd(_aStruSC6,{"C6_QTDVEN"  ,"N", TamSx3("C6_QTDVEN")[1] ,TamSx3("C6_QTDVEN")[2]})
	aAdd(_aStruSC6,{"C6_UNSVEN"  ,"N", TamSx3("C6_UNSVEN")[1] ,TamSx3("C6_UNSVEN")[2]})
	aAdd(_aStruSC6,{"C6_SALDO"   ,"N", TamSx3("C6_QTDVEN")[1] ,TamSx3("C6_QTDVEN")[2]})
	aAdd(_aStruSC6,{"C6_SERIORI" ,"C", TamSx3("C6_SERIORI")[1],0})
	aAdd(_aStruSC6,{"C6_NFORI"   ,"C", TamSx3("C6_NFORI")[1]  ,0})
	aAdd(_aStruSC6,{"C6_ITEMORI" ,"C", TamSx3("C6_ITEMORI")[1],0})
	aAdd(_aStruSC6,{"D1_DTDIGIT" ,"D", TamSx3("D1_DTDIGIT")[1],0})
	aAdd(_aStruSC6,{"D1_NUMSEQ"  ,"C", TamSx3("D1_NUMSEQ")[1] ,0})
	aAdd(_aStruSC6,{"C6_ZTPESTO" ,"C", TamSx3("C6_ZTPESTO")[1],0})
	aAdd(_aStruSC6,{"C6_LOTECTL" ,"C", TamSx3("C6_LOTECTL")[1],0})

	If (Select(_cAlTrbSC6)<>0)
		dbSelectArea(_cAlTrbSC6)
		dbCloseArea()
	EndIf
	// criar um arquivo de trabalho
	_cTrbSC6 := FWTemporaryTable():New( _cAlTrbSC6 )
	_cTrbSC6:SetFields( _aStruSC6 )
	_cTrbSC6:AddIndex("01", {"C6_PRODUTO","C6_LOTECTL"} )
	_cTrbSC6:Create()

	// -- define header
	aAdd(_aHeadSC6,{"C6_PRODUTO","","Produto"  ,""})
	aAdd(_aHeadSC6,{"B1_DESC"   ,"","Descrição",""})
	aAdd(_aHeadSC6,{"C6_QTDVEN" ,"","Quant."   ,PesqPict("SC6","C6_QTDVEN")})
	aAdd(_aHeadSC6,{"C6_SALDO"  ,"","Saldo"    ,PesqPict("SC6","C6_QTDVEN")})
	If ( ! _lExpEmKit )
		aAdd(_aHeadSC6,{"C6_SERIORI","","Serie NF"    ,""})
		aAdd(_aHeadSC6,{"C6_NFORI"  ,"","NF Orig"     ,""})
		aAdd(_aHeadSC6,{"C6_ITEMORI","","It.NF.Orig"  ,""})
		aAdd(_aHeadSC6,{"D1_DTDIGIT","","Dt.Dig.NF"   ,""})
		aAdd(_aHeadSC6,{"D1_NUMSEQ" ,"","Num.Seq."    ,""})
		aAdd(_aHeadSC6,{"C6_ZTPESTO","","Tipo Estoque",""})
		aAdd(_aHeadSC6,{"C6_LOTECTL","","Lote"        ,""})
	EndIf
	aAdd(_aHeadSC6,{"C6_UNSVEN" ,"","Qtd.Seg.UM",PesqPict("SC6","C6_UNSVEN")})

	// define cores da legenda do browse
	aAdd(_aCorSC6,{"(_cAlTrbSC6)->C6_SALDO <> 0","BR_VERMELHO"})
	aAdd(_aCorSC6,{"(_cAlTrbSC6)->C6_SALDO == 0","BR_VERDE"   })

	// -- monta o arquivo de trabalho - Enderecos Disponiveis COM Etiqueta
	aAdd(_aStruEnd1,{"ET1_COR"    ,"C", 2 ,0})
	aAdd(_aStruEnd1,{"ET1_ORIG"   ,"C", 3 ,0})
	aAdd(_aStruEnd1,{"ET1_QRY"    ,"C", 1 ,0})
	aAdd(_aStruEnd1,{"ET1_TPBUSC" ,"C", 1 ,0})
	aAdd(_aStruEnd1,{"ET1_PROD"   ,"C", TamSx3("C6_PRODUTO")[1] ,0})
	aAdd(_aStruEnd1,{"ET1_LOCAL"  ,"C", TamSx3("BE_LOCAL")[1] ,0})
	aAdd(_aStruEnd1,{"ET1_ENDORI" ,"C", TamSx3("BE_LOCALIZ")[1] ,0})
	aAdd(_aStruEnd1,{"ET1_SALDO"  ,"N", TamSx3("BF_QUANT")[1],TamSx3("BF_QUANT")[2]})
	aAdd(_aStruEnd1,{"ET1_QUANT"  ,"N", TamSx3("BF_QUANT")[1],TamSx3("BF_QUANT")[2]})
	aAdd(_aStruEnd1,{"ET1_QTSEGU" ,"N", TamSx3("BF_QTSEGUM")[1],TamSx3("BF_QTSEGUM")[2]})
	aAdd(_aStruEnd1,{"ET1_SERORI" ,"C", TamSx3("C6_SERIORI")[1],0})
	aAdd(_aStruEnd1,{"ET1_NFORI"  ,"C", TamSx3("C6_NFORI")[1],0})
	aAdd(_aStruEnd1,{"ET1_ITEORI" ,"C", TamSx3("C6_ITEMORI")[1],0})
	aAdd(_aStruEnd1,{"ET1_NUMSEQ" ,"C", TamSx3("D1_NUMSEQ")[1],0})
	aAdd(_aStruEnd1,{"ET1_SEQ"    ,"C", 4 ,0})
	aAdd(_aStruEnd1,{"ET1_CODKIT" ,"C", TamSx3("Z29_CODKIT")[1],0})
	aAdd(_aStruEnd1,{"ET1_LOTCTL" ,"C", TamSx3("Z16_LOTCTL")[1],0})
	aAdd(_aStruEnd1,{"ET1_TPESTO" ,"C", TamSx3("Z16_TPESTO")[1],0})
	aAdd(_aStruEnd1,{"ET1_ETQPAL" ,"C", TamSx3("Z08_PALLET")[1],0})

	If (Select(_cAlTrb1)<>0)
		dbSelectArea(_cAlTrb1)
		dbCloseArea()
	EndIf

	// criar um arquivo de trabalho
	_cTrbEnd1 := FWTemporaryTable():New( _cAlTrb1 )
	_cTrbEnd1:SetFields( _aStruEnd1 )
	_cTrbEnd1:Create()

	// define header
	aAdd(_aHeadEnd1,{"ET1_PROD"  ,"", "Produto"})
	aAdd(_aHeadEnd1,{"ET1_ENDORI","", "End.Orig." , PesqPict("SBF","BF_LOCALIZ") })
	aAdd(_aHeadEnd1,{"ET1_SALDO" ,"", "Saldo End.", PesqPict("SBF","BF_QUANT")   })
	aAdd(_aHeadEnd1,{"ET1_QUANT" ,"", "Quant."    , PesqPict("SBF","BF_QUANT")   })
	aAdd(_aHeadEnd1,{"ET1_SEQ"   ,"", "Seq"})
	aAdd(_aHeadEnd1,{"ET1_CODKIT","", "Cod.Agrup."})
	aAdd(_aHeadEnd1,{"ET1_LOTCTL","", "Lote"})
	aAdd(_aHeadEnd1,{"ET1_QTSEGU","", "Qtd.Seg.UM", PesqPict("SBF","BF_QTSEGUM") })
	aAdd(_aHeadEnd1,{"ET1_ETQPAL","", "Id.Palete" , PesqPict("Z08","Z08_PALLET") })
	aAdd(_aHeadEnd1,{"ET1_ORIG"  ,"", "Orig."  })
	aAdd(_aHeadEnd1,{"ET1_QRY"   ,"", "Sql"    })
	aAdd(_aHeadEnd1,{"ET1_TPBUSC","", "TpBusca"})

	// define cores da legenda do browse
	aAdd(_aCorEnd1,{"Empty((_cAlTrb1)->ET1_COR)"   ,"BR_VERMELHO"})
	aAdd(_aCorEnd1,{" ! Empty((_cAlTrb1)->ET1_COR)","BR_VERDE"   })

	// -- monta o arquivo de trabalho - Enderecos Disponiveis SEM Etiqueta
	aAdd(_aStruEnd2,{"ET2_COR"    ,"C", 2 ,0})
	aAdd(_aStruEnd2,{"ET2_ORIG"   ,"C", 3 ,0})
	aAdd(_aStruEnd2,{"ET2_QRY"    ,"C", 1 ,0})
	aAdd(_aStruEnd2,{"ET2_TPBUSC" ,"C", 1 ,0})
	aAdd(_aStruEnd2,{"ET2_PROD"   ,"C", TamSx3("C6_PRODUTO")[1] ,0})
	aAdd(_aStruEnd2,{"ET2_ENDORI" ,"C", TamSx3("BE_LOCALIZ")[1] ,0})
	aAdd(_aStruEnd2,{"ET2_SALDO"  ,"N", TamSx3("BF_QUANT")[1],TamSx3("BF_QUANT")[2]})
	aAdd(_aStruEnd2,{"ET2_QUANT"  ,"N", TamSx3("BF_QUANT")[1],TamSx3("BF_QUANT")[2]})
	aAdd(_aStruEnd2,{"ET2_QTSEGU" ,"N", TamSx3("BF_QTSEGUM")[1],TamSx3("BF_QTSEGUM")[2]})
	aAdd(_aStruEnd2,{"ET2_SERORI" ,"C", TamSx3("C6_SERIORI")[1],0})
	aAdd(_aStruEnd2,{"ET2_NFORI"  ,"C", TamSx3("C6_NFORI")[1],0})
	aAdd(_aStruEnd2,{"ET2_ITEORI" ,"C", TamSx3("C6_ITEMORI")[1],0})
	aAdd(_aStruEnd2,{"ET2_NUMSEQ" ,"C", TamSx3("D1_NUMSEQ")[1],0})
	aAdd(_aStruEnd2,{"ET2_SEQ"    ,"C", 4 ,0})
	aAdd(_aStruEnd2,{"ET2_CODKIT" ,"C", TamSx3("Z29_CODKIT")[1],0})
	aAdd(_aStruEnd2,{"ET2_LOTCTL" ,"C", TamSx3("Z16_LOTCTL")[1],0})
	aAdd(_aStruEnd2,{"ET2_TPESTO" ,"C", TamSx3("Z16_TPESTO")[1],0})
	aAdd(_aStruEnd2,{"ET2_ETQPAL" ,"C", TamSx3("Z08_PALLET")[1],0})

	If (Select(_cAlTrb2)<>0)
		dbSelectArea(_cAlTrb2)
		dbCloseArea()
	EndIf
	// criar um arquivo de trabalho
	_cTrbEnd2 := FWTemporaryTable():New( _cAlTrb2 )
	_cTrbEnd2:SetFields( _aStruEnd2 )
	_cTrbEnd2:Create()

	// define header
	aAdd(_aHeadEnd2,{"ET2_PROD"  ,"", "Produto"})
	aAdd(_aHeadEnd2,{"ET2_ENDORI","", "End.Orig." , PesqPict("SBF","BF_LOCALIZ") })
	aAdd(_aHeadEnd2,{"ET2_SALDO" ,"", "Saldo End.", PesqPict("SBF","BF_QUANT")   })
	aAdd(_aHeadEnd2,{"ET2_QUANT" ,"", "Quant."    , PesqPict("SBF","BF_QUANT")   })
	aAdd(_aHeadEnd2,{"ET2_SEQ"   ,"", "Seq"})
	aAdd(_aHeadEnd2,{"ET2_CODKIT","", "Cod.Agrup."})
	aAdd(_aHeadEnd2,{"ET2_LOTCTL","", "Lote"})
	aAdd(_aHeadEnd2,{"ET2_QTSEGU","", "Qtd.Seg.UM", PesqPict("SBF","BF_QTSEGUM") })
	aAdd(_aHeadEnd2,{"ET2_ETQPAL","", "Id.Palete" , PesqPict("Z08","Z08_PALLET") })
	aAdd(_aHeadEnd2,{"ET2_ORIG"  ,"", "Orig."  })
	aAdd(_aHeadEnd2,{"ET2_QRY"   ,"", "Sql"    })
	aAdd(_aHeadEnd2,{"ET2_TPBUSC","", "TpBusca"})

	// define cores da legenda do browse
	aAdd(_aCorEnd2,{"Empty((_cAlTrb2)->ET2_COR)"   ,"BR_VERMELHO"})
	aAdd(_aCorEnd2,{" ! Empty((_cAlTrb2)->ET2_COR)","BR_VERDE"   })

	// -- monta o arquivo de trabalho - Enderecos Disponiveis com AGRUPADORAS
	aAdd(_aStruEnd3,{"ET3_COR"    ,"C", 2 ,0})
	aAdd(_aStruEnd3,{"ET3_ORIG"   ,"C", 3 ,0})
	aAdd(_aStruEnd3,{"ET3_QRY"    ,"C", 1 ,0})
	aAdd(_aStruEnd3,{"ET3_TPBUSC" ,"C", 1 ,0})
	aAdd(_aStruEnd3,{"ET3_PROD"   ,"C", TamSx3("C6_PRODUTO")[1] ,0})
	aAdd(_aStruEnd3,{"ET3_ENDORI" ,"C", TamSx3("BE_LOCALIZ")[1] ,0})
	aAdd(_aStruEnd3,{"ET3_SALDO"  ,"N", TamSx3("BF_QUANT")[1],TamSx3("BF_QUANT")[2]})
	aAdd(_aStruEnd3,{"ET3_QUANT"  ,"N", TamSx3("BF_QUANT")[1],TamSx3("BF_QUANT")[2]})
	aAdd(_aStruEnd3,{"ET3_QTSEGU" ,"N", TamSx3("BF_QTSEGUM")[1],TamSx3("BF_QTSEGUM")[2]})
	aAdd(_aStruEnd3,{"ET3_NUMSEQ" ,"C", TamSx3("D1_NUMSEQ")[1],0})
	aAdd(_aStruEnd3,{"ET3_SEQ"    ,"C", 4 ,0})
	aAdd(_aStruEnd3,{"ET3_CODKIT" ,"C", TamSx3("Z29_CODKIT")[1],0})
	aAdd(_aStruEnd3,{"ET3_LOTCTL" ,"C", TamSx3("Z16_LOTCTL")[1],0})
	aAdd(_aStruEnd3,{"ET3_TPESTO" ,"C", TamSx3("Z16_TPESTO")[1],0})
	aAdd(_aStruEnd3,{"ET3_ETQPAL" ,"C", TamSx3("Z08_PALLET")[1],0})

	If (Select(_cAlTrb3)<>0)
		dbSelectArea(_cAlTrb3)
		dbCloseArea()
	EndIf

	// criar um arquivo de trabalho
	_cTrbEnd3 := FWTemporaryTable():New( _cAlTrb3 )
	_cTrbEnd3:SetFields( _aStruEnd3 )
	_cTrbEnd3:Create()

	// define header
	aAdd(_aHeadEnd3,{"ET3_PROD"  ,"", "Produto"})
	aAdd(_aHeadEnd3,{"ET3_ENDORI","", "End.Orig." , PesqPict("SBF","BF_LOCALIZ") })
	aAdd(_aHeadEnd3,{"ET3_SALDO" ,"", "Saldo End.", PesqPict("SBF","BF_QUANT")   })
	aAdd(_aHeadEnd3,{"ET3_QUANT" ,"", "Quant."    , PesqPict("SBF","BF_QUANT")   })
	aAdd(_aHeadEnd3,{"ET3_SEQ"   ,"", "Seq"})
	aAdd(_aHeadEnd3,{"ET3_CODKIT","", "Cod.Agrup."})
	aAdd(_aHeadEnd3,{"ET3_LOTCTL","", "Lote"})
	aAdd(_aHeadEnd3,{"ET3_QTSEGU","", "Qtd.Seg.UM", PesqPict("SBF","BF_QTSEGUM") })
	aAdd(_aHeadEnd3,{"ET3_ETQPAL","", "Id.Palete" , PesqPict("Z08","Z08_PALLET") })
	aAdd(_aHeadEnd3,{"ET3_ORIG"  ,"", "Orig."  })
	aAdd(_aHeadEnd3,{"ET3_QRY"   ,"", "Sql"    })
	aAdd(_aHeadEnd3,{"ET3_TPBUSC","", "TpBusca"})

	// define cores da legenda do browse
	aAdd(_aCorEnd3,{"Empty((_cAlTrb3)->ET3_COR)"   ,"BR_VERMELHO"})
	aAdd(_aCorEnd3,{" ! Empty((_cAlTrb3)->ET3_COR)","BR_VERDE"   })

	// -- monta o arquivo de trabalho - enderecos selecionados
	aAdd(_aStruMov,{"MOV_SEQ"   ,"C", 4 ,0})
	aAdd(_aStruMov,{"MOV_PROD"  ,"C", TamSx3("C6_PRODUTO")[1],0})
	aAdd(_aStruMov,{"MOV_LOCAL" ,"C", TamSx3("BE_LOCAL")[1]  ,0})
	aAdd(_aStruMov,{"MOV_ENDORI","C", TamSx3("BE_LOCALIZ")[1],0})
	aAdd(_aStruMov,{"MOV_QUANT" ,"N", TamSx3("BF_QUANT")[1]  ,TamSx3("BF_QUANT")[2]})
	aAdd(_aStruMov,{"MOV_QTSEGU","N", TamSx3("BF_QTSEGUM")[1],TamSx3("BF_QTSEGUM")[2]})
	aAdd(_aStruMov,{"MOV_ENDDES","C", TamSx3("BE_LOCALIZ")[1],0})
	aAdd(_aStruMov,{"MOV_PALETE","C", TamSx3("Z08_PALLET")[1],0})
	aAdd(_aStruMov,{"MOV_FRAPLT","C", TamSx3("Z08_FRAPLT")[1],0})
	aAdd(_aStruMov,{"MOV_FRAVOL","C", TamSx3("Z08_FRAPLT")[1],0})
	aAdd(_aStruMov,{"MOV_CARGA" ,"C", TamSx3("DAK_COD")[1]   ,0})
	aAdd(_aStruMov,{"MOV_SERORI","C", TamSx3("C6_SERIORI")[1],0})
	aAdd(_aStruMov,{"MOV_NFORI" ,"C", TamSx3("C6_NFORI")[1]  ,0})
	aAdd(_aStruMov,{"MOV_ITEORI","C", TamSx3("C6_ITEMORI")[1],0})
	aAdd(_aStruMov,{"MOV_NUMSEQ","C", TamSx3("D1_NUMSEQ")[1] ,0})
	aAdd(_aStruMov,{"MOV_SLDEND","N", TamSx3("BF_QUANT")[1]  ,TamSx3("BF_QUANT")[2]})
	aAdd(_aStruMov,{"MOV_VOLUME","C", TamSx3("Z16_ETQVOL")[1],0})
	aAdd(_aStruMov,{"MOV_CODKIT","C", TamSx3("Z29_CODKIT")[1],0})
	aAdd(_aStruMov,{"MOV_STATUS","C", TamSx3("Z08_STATUS")[1],0})
	aAdd(_aStruMov,{"MOV_LOTCTL","C", TamSx3("Z16_LOTCTL")[1],0})
	aAdd(_aStruMov,{"MOV_TPESTO","C", TamSx3("Z16_TPESTO")[1],0})

	If (Select(_cAlTrbMov)<>0)
		dbSelectArea(_cAlTrbMov)
		dbCloseArea()
	EndIf

	// criar um arquivo de trabalho
	_cTrbMov := FWTemporaryTable():New( _cAlTrbMov )
	_cTrbMov:SetFields( _aStruMov )
	_cTrbMov:AddIndex("01", {"MOV_PROD","MOV_LOCAL","MOV_ENDORI","MOV_PALETE","MOV_LOTCTL"} )
	_cTrbMov:Create()

	// define header
	aAdd(_aHeadMov,{"MOV_SEQ"   ,"","Seq"         })
	aAdd(_aHeadMov,{"MOV_PROD"  ,"","Produto"     })
	aAdd(_aHeadMov,{"MOV_LOCAL" ,"","Armz"        })
	aAdd(_aHeadMov,{"MOV_ENDORI","","End.Origem", PesqPict("SBF","BF_LOCALIZ") })
	aAdd(_aHeadMov,{"MOV_QUANT" ,"","Quant.Mov.", PesqPict("SBF","BF_QUANT")   })
	aAdd(_aHeadMov,{"MOV_ENDDES","","End.Destino" })
	aAdd(_aHeadMov,{"MOV_PALETE","","Id.Palete"   })
	aAdd(_aHeadMov,{"MOV_FRAPLT","","Frac.Plt.?"  })
	aAdd(_aHeadMov,{"MOV_FRAVOL","","Frac.Vol.?"  })
	aAdd(_aHeadMov,{"MOV_NUMSEQ","","Num.Seq."    })
	aAdd(_aHeadMov,{"MOV_VOLUME","","Id.Volume"   })
	aAdd(_aHeadMov,{"MOV_CODKIT","","Cod.Agrup."  })
	aAdd(_aHeadMov,{"MOV_LOTCTL","","Lote"        })
	aAdd(_aHeadMov,{"MOV_TPESTO","","Tipo Estoque"})
	aAdd(_aHeadMov,{"MOV_QTSEGU","","Qtd.Seg.UM", PesqPict("SBF","BF_QTSEGUM") })

	// verifica se ja tem mapa de expedicao gerado
	If (_lPorCarga) .And. ( ! _lPorOnda )

		// por carga
		dbSelectArea("Z05")
		Z05->(dbOrderNickName("Z05_CARGA"))
		If Z05->(dbSeek( xFilial("Z05") + _cNumCarga ))
			// busca os dados
			sfBuscaMapa(Z05->Z05_NUMOS, _aStruMov, @_lTudoOk)
			// nao permite gerar mapa
			_lGeraMapa := .F.
			// permite impressao do mapa
			_lImprMapa := .T.
		EndIf

	ElseIf ( ! _lPorCarga ) .And. ( _lPorOnda)

		// por onda
		dbSelectArea("Z05")
		Z05->(dbOrderNickName("Z05ONDSEP"))
		If Z05->(dbSeek( xFilial("Z05") + _cNrOndSep ))
			// busca os dados
			sfBuscaMapa(Z05->Z05_NUMOS, _aStruMov, @_lTudoOk)
			// nao permite gerar mapa
			_lGeraMapa := .F.
			// permite impressao do mapa
			_lImprMapa := .T.
		EndIf

	EndIf

	// verifica se continua a geracao de mapa de expedicao para clientes que utilizam nova versão de WMS (por onda de separação)
	If (_lWmsNovo) .And. (_lGeraMapa) .AND. !(mvRotAuto)
		// avisa usuario
		Help( Nil, Nil, 'TWMSA019.F01.004', Nil, "Não é permitido geração de mapa de expedição para este cliente desta forma.", 1, 0, Nil, Nil, Nil, Nil, Nil, {"Utilize a rotina de planejamento e geração de 'Onda de Separação'."})
		// retorno
		Return(.F.)
	EndIf

	// executa o select buscando os itens dos pedidos de venda da carga
	_cQrySC6 := " SELECT C6_PRODUTO, B1_DESC, SUM(C6_QTDVEN) C6_QTDVEN, SUM(C6_UNSVEN) C6_UNSVEN, "
	_cQrySC6 += If(_lGeraMapa," SUM(C6_QTDVEN)","0")+" C6_SALDO, "
	If ( ! _lExpEmKit )
		_cQrySC6 += " C6_SERIORI, C6_NFORI, C6_ITEMORI, D1_DTDIGIT, D1_NUMSEQ, C6_ZTPESTO, C6_LOTECTL "
	ElseIf (_lExpEmKit)
		_cQrySC6 += " '' C6_SERIORI, '' C6_NFORI, '' C6_ITEMORI, '' D1_DTDIGIT, '' D1_NUMSEQ, C6_ZTPESTO, C6_LOTECTL "
	EndIf
	// itens liberados
	_cQrySC6 += " FROM " + RetSqlTab("SC9") + " (nolock) "
	// cab pedido de venda
	_cQrySC6 += " INNER JOIN " + RetSqlTab("SC5") + " (nolock)  ON " + RetSqlCond("SC5") + " AND C5_NUM = C9_PEDIDO "
	// por onda
	If ( ! _lPorCarga) .And. ( _lPorOnda )
		_cQrySC6 += " AND C5_ZONDSEP = '" + _cNrOndSep + "' "
	EndIf
	// itens liberados
	_cQrySC6 += " INNER JOIN " + RetSqlTab("SC6") + " (nolock)  ON " + RetSqlCond("SC6") + " AND C6_NUM = C9_PEDIDO AND C6_ITEM = C9_ITEM AND C6_PRODUTO = C9_PRODUTO "
	// cad. de produtos
	_cQrySC6 += " INNER JOIN " + RetSqlTab("SB1") + " (nolock)  ON " + RetSqlCond("SB1") + " AND B1_COD = C6_PRODUTO "
	// itens nota fiscal de entrada
	If ( ! _lExpEmKit )
		_cQrySC6 += " INNER JOIN " + RetSqlTab("SD1") + " (nolock)  ON " + RetSqlCond("SD1") + " AND D1_DOC = C6_NFORI AND D1_SERIE = C6_SERIORI "
		_cQrySC6 += " AND D1_FORNECE = C6_CLI     AND D1_LOJA = C6_LOJA "
		_cQrySC6 += " AND D1_COD     = C6_PRODUTO AND D1_ITEM = C6_ITEMORI "
	EndIf
	// filtro padrao
	_cQrySC6 += " WHERE " + RetSqlCond("SC9")
	// por carga
	If (_lPorCarga) .And. ( ! _lPorOnda )
		_cQrySC6 += " AND C9_CARGA = '" + _cNumCarga + "' "
	EndIf
	// sem nota fiscal emitida E sem bloqueio de WMS
	If (_lGeraMapa)
		_cQrySC6 += " AND C9_NFISCAL = ' ' AND C9_BLEST = '02' AND C9_BLWMS = ' ' "
	EndIf
	// agrupa itens por produto, nota e serie origem
	_cQrySC6 += " GROUP BY C6_PRODUTO, B1_DESC, C6_ZTPESTO, C6_LOTECTL " + IIf((!_lExpEmKit),", C6_SERIORI, C6_NFORI, C6_ITEMORI, D1_DTDIGIT, D1_NUMSEQ ","")
	// ordem dos dados
	_cQrySC6 += " ORDER BY C6_PRODUTO, C6_SERIORI, C6_NFORI, C6_ITEMORI "

	memowrit("c:\query\twmsa019.txt",_cQrySC6)

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQrySC6, _aStruSC6, (_cAlTrbSC6))

	// abre o arquivo de trabalho
	(_cAlTrbSC6)->(dbSelectArea(_cAlTrbSC6))
	(_cAlTrbSC6)->(dbGoTop())
	If (_cAlTrbSC6)->(!EOF())
		(_cAlTrbSC6)->(IndRegua((_cAlTrbSC6),(_cTrbSC6),"C6_PRODUTO",,,"Selecionando Registros..."))
		//(_cAlTrbSC6)->(dbSetOrder(1))
	EndIf
	(_cAlTrbSC6)->(dbGoTop())

	// abre o arquivo de trabalho
	(_cAlTrb1)->(dbSelectArea(_cAlTrb1))
	(_cAlTrb1)->(dbGoTop())

	// abre o arquivo de trabalho
	(_cAlTrb2)->(dbSelectArea(_cAlTrb2))
	(_cAlTrb2)->(dbGoTop())

	// abre o arquivo de trabalho
	(_cAlTrb3)->(dbSelectArea(_cAlTrb3))
	(_cAlTrb3)->(dbGoTop())

	// abre o arquivo de trabalho
	(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
	(_cAlTrbMov)->(dbGoTop())

	// controle se for rotina automatica
	If (_lRotAuto)

		// se for com reserva de endereco, executa funcao para calculo de reserva de enderecos (mapa expedicao)
		If ( _lResEndOri )

			// verifica se permite a geracao de mapa
			If (_lGeraMapa)

				// executa funcao para calculo de reserva de enderecos (mapa expedicao)
				Processa({ |lEnd| _lTudoOk := sfMapaApanhe( Nil, Nil, Nil, _cArmzPadrao),'Gerando o relatório...'})

				// ao final, gera ordem de servico
				If (_lTudoOk)
					// funcao para gerar ordem de servico
					sfConfMapa( Nil )
				Else
					// dispara email de aviso
					U_FtMail(_cLogMapa,;
					"TECADI - Erro na geração do mapa de apanhe (ONDA: " + _cNrOndSep + ")",;
					"accounts103@tecadi.com.br")
				EndIf

			EndIf

			// se nao precisa reservar endereco de origem, gera mapa soh das quantidades
		ElseIf ( ! _lResEndOri )

			// todos os itens da onda
			(_cAlTrbSC6)->(dbSelectArea(_cAlTrbSC6))
			(_cAlTrbSC6)->(dbSetOrder(1))
			(_cAlTrbSC6)->(dbGoTop())

			// varre todos os itens
			While (_cAlTrbSC6)->( ! Eof() )

				// estrutura _aMapaApanhe
				//  1-cod produto
				//  2-local/armazem
				//  3-end retirada
				//  4-quant
				//  5-end destino
				//  6-ID palete
				//  7-fraciona palete
				//  8-serie nota orig
				//  9-nota orig
				// 10-item nota orig
				// 11-sequencial
				// 12-numseq
				// 13-id volume
				// 14-Lote
				// 15-Tipo de Estoque
				// 16-Quantidade Seg Unid

				aAdd(_aMapaApanhe, {;
				(_cAlTrbSC6)->C6_PRODUTO,;
				""                      ,;
				""                      ,;
				(_cAlTrbSC6)->C6_QTDVEN ,;
				""                      ,;
				""                      ,;
				""                      ,;
				(_cAlTrbSC6)->C6_SERIORI,;
				(_cAlTrbSC6)->C6_NFORI  ,;
				(_cAlTrbSC6)->C6_ITEMORI,;
				""                      ,;
				(_cAlTrbSC6)->D1_NUMSEQ ,;
				""                      ,;
				(_cAlTrbSC6)->C6_LOTECTL,;
				(_cAlTrbSC6)->C6_ZTPESTO,;
				(_cAlTrbSC6)->C6_UNSVEN })

				// proximo item
				(_cAlTrbSC6)->( DbSkip() )

			EndDo

			// ao final, gera ordem de servico
			sfConfMapa( Nil )

		EndIf

	ElseIf ( ! _lRotAuto )
		// monta o dialogo
		_oWndWmsExp := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Gerar/consultar mapa de apanhe/expedição",,,.F.,,,,,,.T.,,,.T. )
		_oWndWmsExp:lMaximized := .T.

		// panel para os botoes de comando
		_oPnlBtnOpr := TPanel():New(000,000,Nil,_oWndWmsExp,,.F.,.F.,,,26,26,.T.,.F. )
		_oPnlBtnOpr:Align := CONTROL_ALIGN_TOP

		// -- botao confirmar
		_oBtnConfInt := TButton():New(005,005,"Confirmar",_oPnlBtnOpr,{|| Processa({ |lEnd| sfConfMapa(@_oWndWmsExp) },'Gerando Transferências...') } ,030,015,,,,.T.,,"",,,,.F. )
		_oBtnConfInt:bWhen := {|| ((_lTudoOk) .And. (_lGeraMapa)) }

		// -- botao pre-analise para buscar enderecos
		_oBtnGeraEnd := TButton():New(005,040,"Mapa Apanhe",_oPnlBtnOpr,{|| Processa({ |lEnd| _lTudoOk := sfMapaApanhe(@_oBrwDisp1, @_oBrwDisp2, @_oBrwDisp3, _cArmzPadrao),'Gerando o relatório...'}), _lImprMapa := _lTudoOk },040,015,,,,.T.,,"",,,,.F. )
		_oBtnGeraEnd:bWhen := {|| _lGeraMapa }

		// numero da carga / onda de separacao
		_oSayNrCarga := TSay():New(008,100,{|| IIf(_lPorCarga, "Nr. Carga: " + _cNumCarga, "Nr. Onda: " + _cNrOndSep) },_oPnlBtnOpr,,_oFnt01,.F.,.F.,.F.,.T.)

		// campo para informar o endereco de destino
		If !_lWmsNovo    //Apresenta o campo em tela somente quando não for o novo WMS (versão 2.0 - por onda de separação)
			_oSayEndDes := TSay():New(008,200,{||"End.Destino"},_oPnlBtnOpr,,_oFnt01,.F.,.F.,.F.,.T.)
			_oGetEndDes := TGet():New(005,250,{|u| If(PCount()>0,_cEndDest:=u,_cEndDest)},_oPnlBtnOpr,070,012,PesqPict("SBE","BE_LOCALIZ"),{|| Iif(_lWmsNovo,ExistCpo("SBE", _cArmzPadrao+_cEndDest),.T.) },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SBE","_cEndDest",,)
			_oGetEndDes:bWhen := {|| _lGeraMapa }
		EndIf

		// controle para liberar emissao de nota / movimenta mercadoria dos enderecos
		_oCkBxLibNf := TCheckBox():New(008,450,"Libera emissão NF ?",{|u| If(PCount()>0,_lLibNota:=u,_lLibNota)},_oPnlBtnOpr,80,10,,,_oFnt01,,,,,.T.,"",, )
		_oCkBxLibNf:bWhen := {|| .F. }

		// -- botao estorno
		_oBtnEstorno := TButton():New(005,((_aSizeDlg[5]/2)-106),"Estorno",_oPnlBtnOpr,{|| Processa({ |lEnd| sfEstorno(_cNumCarga, @_oWndWmsExp, _cNrOndSep) }, 'Estorno...') },030,015,,,,.T.,,"",,,,.F. )
		_oBtnEstorno:bWhen := {|| (_lTudoOk) .And. ( ! _lGeraMapa ) }

		// -- botao impressao
		_oBtnImpMapa := TButton():New(005,((_aSizeDlg[5]/2)-70),"Impressão",_oPnlBtnOpr,{|| U_WMSA019A(_cNumCarga, _aMapaApanhe, _cNrOndSep) },030,015,,,,.T.,,"",,,,.F. )
		_oBtnImpMapa:bWhen := {|| _lImprMapa }

		// -- botao fechar
		_oBtnFechar := TButton():New(005,((_aSizeDlg[5]/2)-35),"Fechar",_oPnlBtnOpr,{|| _oWndWmsExp:End() },030,015,,,,.T.,,"",,,,.F. )

		// panel para o browse dos itens do PV
		_oPnlBrwSC6 := TPanel():New(000,000,Nil,_oWndWmsExp,,.F.,.F.,,,120,120,.T.,.F. )
		_oPnlBrwSC6:Align := CONTROL_ALIGN_TOP

		// browse com a listagem dos itens do PV
		_oBrwSC6 := MsSelect():New((_cAlTrbSC6),,,_aHeadSC6,.F.,,{000,000,2000,2000},,,_oPnlBrwSC6,,_aCorSC6)
		_oBrwSC6:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
		_oBrwSC6:oBrowse:bChange := {|| sfFiltraEnd( (_cAlTrbSC6)->C6_SERIORI, (_cAlTrbSC6)->C6_NFORI, (_cAlTrbSC6)->C6_ITEMORI, (_cAlTrbSC6)->C6_PRODUTO, (_cAlTrbSC6)->C6_ZTPESTO, @_oBrwDisp1, @_oBrwDisp2, @_oBrwDisp3 ) }

		// panel para o browse dos enderecos disponiveis
		_oPnlBrwDisp := TPanel():New(000,000,Nil,_oWndWmsExp,,.F.,.F.,,,(_aSizeDlg[5]/4),(_aSizeDlg[5]/4),.T.,.F. )
		_oPnlBrwDisp:Align := CONTROL_ALIGN_LEFT

		// pastas com as opcoes de visualizacao
		_oFolder := TFolder():New(000,000,_aFolders,,_oPnlBrwDisp,,,,.T.,,200,200)
		_oFolder:Align:= CONTROL_ALIGN_ALLCLIENT

		// 1a PASTA - cria o panel e browse com enderecos disponiveis COM etiqueta
		_oBrwDisp1 := MsSelect():New((_cAlTrb1),,,_aHeadEnd1,,,{000,000,2000,2000},,,_oFolder:aDialogs[1],,_aCorEnd1)
		_oBrwDisp1:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
		_oBrwDisp1:oBrowse:BlDblClick := {|| sfDetProd((_cAlTrb1)->ET1_NUMSEQ) }

		// 2a PASTA - cria o panel e browse com enderecos disponiveis SEM etiqueta
		_oBrwDisp2 := MsSelect():New((_cAlTrb2),,,_aHeadEnd2,,,{000,000,2000,2000},,,_oFolder:aDialogs[2],,_aCorEnd2)
		_oBrwDisp2:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// 3a PASTA - cria o panel e browse com enderecos disponiveis AGRUPADORA
		_oBrwDisp3 := MsSelect():New((_cAlTrb3),,,_aHeadEnd3,,,{000,000,2000,2000},,,_oFolder:aDialogs[3],,_aCorEnd3)
		_oBrwDisp3:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// browse com a listagem dos enderecos selecionados
		_oBrwMovPlt := MsSelect():New((_cAlTrbMov),,,_aHeadMov,,,{000,000,2000,2000},,,_oWndWmsExp)
		_oBrwMovPlt:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
		_oBrwMovPlt:oBrowse:BlDblClick := { || Iif( ( _lTudoOk .And. _lGeraMapa .And. lAltMapa .AND. _lUsrGeren ),;
		fAltEnd(_cAlTrbMov,_cAlTrbSC6,_cAlTrb1,_cAlTrb2,_cArmzPadrao),;
		Alert("Este cliente não permite alterar o mapa ou você não tem a permissão necessária.")),;
		_oBrwMovPlt:oBrowse:Refresh(),_oBrwDisp3:oBrowse:Refresh(),_oBrwDisp2:oBrowse:Refresh(),_oBrwDisp1:oBrowse:Refresh()}

		// ativa a tela
		ACTIVATE MSDIALOG _oWndWmsExp CENTERED
	EndIf

	// fecha arquivo de trabalho
	If ValType(_cTrbSC6) == "O"
		_cTrbSC6:Delete()
	EndIf

	If ValType(_cTrbEnd1) == "O"
		_cTrbEnd1:Delete()
	EndIf

	If ValType(_cTrbEnd2) == "O"
		_cTrbEnd2:Delete()
	EndIf

	If ValType(_cTrbEnd3) == "O"
		_cTrbEnd3:Delete()
	EndIf

	If ValType(_cTrbMov) == "O"
		_cTrbMov:Delete()
	EndIf

	// funcao padrao da TOTVS que libera todos os registros com LOCK do SofLock
	LibLock(_aRegLock)

	// libera todos os registros
	MsUnLockAll()

Return

//** funcao para geracao da OS de Expedicao da carga
Static Function sfConfMapa(mvObjWnd)
	// controle do processamento
	local _lOk := .F.
	// variaveis da rotina automatica
	local _aTmpItem := {}
	local _aItemSD3 := {}

	// numero da OS
	local _cNumOS

	// documento SD3
	local _cDoctoSD3 := ""

	// variaveis obrigatorias para uso da rotina a260processa
	private cCusMed := GetMv("MV_CUSMED")
	private aRegSD3 := {}

	// quantidade de registros a processar
	(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
	ProcRegua( (_cAlTrbMov)->(RecCount()) )

	// início da transação
	Begin Transaction

		// chama a rotina padrao para geracao de OS
		_lOk := U_WMSA009B( Nil, "02", _cNumCarga, _cEndDest, _aMapaApanhe, ( ! _lLibNota ), "001", Nil, Nil, .F., Nil, Nil, _cNrOndSep) // gera OS sem mostrar o número nesse momento

		// se geracao de OS ok
		If (_lOk)

			// numero da OS
			_cNumOS := Z05->Z05_NUMOS

			// se libera emissao da nota, transfere toda a mercadoria para a doca
			If (_lLibNota)

				// chama o grupo de perguntas padrao da rotina MATA260
				pergunte("MTA260",.F.)

				// define o parametro "Considera Saldo poder de 3" como NAO
				mv_par03 := 2

				// zera variaveis
				_aItemSD3 := {}
				_aTmpItem := {}

				// itens e enderecos dos produtos a movimentar
				(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
				(_cAlTrbMov)->(DbGoTop())
				While (_cAlTrbMov)->(!Eof())

					// documento SD3
					_cDoctoSD3 := NextNumero("SD3",2,"D3_DOC",.T.)

					// controle de regua de processamento
					IncProc("Produto: " + AllTrim((_cAlTrbMov)->MOV_PROD))

					// posiciona no cadastro de produtos
					dbSelectArea("SB1")
					SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
					SB1->(dbSeek( xFilial("SB1")+(_cAlTrbMov)->MOV_PROD ))

					// zera variavel
					_aTmpItem := {}
					_aItemSD3 := {}

					// itens para movimentacao de transferencia
					aAdd(_aTmpItem, (_cAlTrbMov)->MOV_PROD  )
					aAdd(_aTmpItem, SB1->B1_DESC            )
					aAdd(_aTmpItem, SB1->B1_UM              )
					aAdd(_aTmpItem, (_cAlTrbMov)->MOV_LOCAL )
					aAdd(_aTmpItem, (_cAlTrbMov)->MOV_ENDORI)
					aAdd(_aTmpItem, (_cAlTrbMov)->MOV_PROD  )
					aAdd(_aTmpItem, SB1->B1_DESC            )
					aAdd(_aTmpItem, SB1->B1_UM              )
					aAdd(_aTmpItem, (_cAlTrbMov)->MOV_LOCAL )
					aAdd(_aTmpItem, (_cAlTrbMov)->MOV_ENDDES)
					aAdd(_aTmpItem, CriaVar("D3_NUMSERI")   )
					aAdd(_aTmpItem, (_cAlTrbMov)->MOV_LOTCTL)
					aAdd(_aTmpItem, CriaVar("D3_NUMLOTE")   )
					aAdd(_aTmpItem, CriaVar("D3_DTVALID")   )
					aAdd(_aTmpItem, CriaVar("D3_POTENCI")   )
					aAdd(_aTmpItem, (_cAlTrbMov)->MOV_QUANT )
					aAdd(_aTmpItem, CriaVar("D3_QTSEGUM")   )
					aAdd(_aTmpItem, CriaVar("D3_ESTORNO")   )
					aAdd(_aTmpItem, CriaVar("D3_NUMSEQ")    )
					aAdd(_aTmpItem, (_cAlTrbMov)->MOV_LOTCTL)
					aAdd(_aTmpItem, CriaVar("D3_DTVALID")   )
					aAdd(_aTmpItem, CriaVar("D3_SERVIC")    )
					aAdd(_aTmpItem, CriaVar("D3_ITEMGRD")   )
					If (SD3->(FieldPos("D3_IDDCF")) > 0)
						aAdd(_aTmpItem, CriaVar("D3_IDDCF"))
					EndIf
					If (SD3->(FieldPos("D3_OBSERVA")) > 0)
						aAdd(_aTmpItem, CriaVar("D3_OBSERVA"))
					EndIf
					aAdd(_aTmpItem, _cNumOS                 )
					aAdd(_aTmpItem, CriaVar("D3_ZSEQOS")    )
					aAdd(_aTmpItem, (_cAlTrbMov)->MOV_PALETE)
					aAdd(_aTmpItem, (_cAlTrbMov)->MOV_CARGA )
					aAdd(_aTmpItem, ""                      )
					aAdd(_aTmpItem, ""                      )

					// define primeira linha do cabecalho
					_aItemSD3 := {{_cDoctoSD3,dDataBase}}

					// adiciona o item
					aAdd(_aItemSD3, _aTmpItem)

					lMsHelpAuto := .T.
					lMsErroAuto := .F.

					// executa rotina automatica
					MsExecAuto({|x,y|MATA261(x,y)}, _aItemSD3, 3) // 3-transferencia

					// controle de erro na transferencia
					If (lMsErroAuto)
						_lOk := .F.
						DisarmTransaction()
						Break
					EndIf

					// proximo item
					(_cAlTrbMov)->(dbSkip())
				EndDo

				// apos movimentacao de mercadoria, altera a doca de retirada do pedido de venda e libera novamente os itens
				sfLibPedVen( .F. )

			EndIf

		EndIf

		// Gera logs das trocas do mapa de apanhe, caso existam
		For _nX := 1 to Len(_aTrocaMapa)
			U_FtGeraLog( xFilial("Z08"), "Z08", xFilial("Z08") + _cNumOS , _aTrocaMapa[_nX] , "WMS"  )
		Next _nX

		// finaliza transacao
	End Transaction

	If _lOk
		// funcao padrao da TOTVS que libera todos os registros com LOCK do SofLock
		LibLock(_aRegLock)

		// libera todos os registros
		MsUnLockAll()

		// mensagem de confirmacao
		If ( _lOk ) .And. ( ! _lRotAuto )
			// mensagem
			MsgInfo("Processamento Ok. Ordem de Serviço gerada: " + _cNumOS + ".", "Geração de Mapa")
		EndIf

		// fecha a janela
		If (mvObjWnd <> nil)
			mvObjWnd:End()
		EndIf
	EndIf

Return( _lOk )

//** funcao para realizar a busca dos enderecos de apanhe
Static Function sfMapaApanhe(mvBrwDisp1, mvBrwDisp2, mvBrwDisp3, mvArmzPadrao)
	// variavel de retorno
	local _lRet := .T.
	// retorno do mapa
	local _lRetMapa := .F.
	// controle da sequencia
	local _cCntrlSeq := "0001"

	// componentes para pesquisa de estrutura de agrupadora
	local _aProdPedido := {}
	local _cQryProdPed  := ""

	// valida endereco de destino
	//Incluido validação para considerar o endereço destino.
	If !_lWmsNovo
		If ( ! _lRotAuto ) .And. ( Empty(_cEndDest) )
			// mensagem
			Aviso("TWMSA019 -> sfMapaApanhe","É obrigatório informar o endereço de destino!",{"Fechar"})
			// retorno
			Return(.F.)
		EndIf
	EndIf
	// verifica se o endereco de destino é uma DOCA
	//Incluído validação para considerar se é o novo WMS.
	If !_lWmsNovo .And. ( ! _lRotAuto )

		// cadastro de enderecos
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
		SBE->(dbSeek( xFilial("SBE") + mvArmzPadrao + _cEndDest ))

		If (SBE->BE_ESTFIS != "000001")
			// mensagem
			Aviso("TWMSA019 -> sfMapaApanhe","Endereço "+_cEndDest+" inválido!",{"Fechar"})
			// retorno
			Return(.F.)
		EndIf

		// valida se o endereco de destino eh do cliente
		If (SBE->BE_ZCODCLI != _cCodCli)
			// mensagem
			Aviso("TWMSA019 -> sfMapaApanhe","Endereço "+_cEndDest+" não está configurado para este cliente!",{"Fechar"})
			// retorno
			Return(.F.)
		EndIf
	EndIf

	// quantidade de registros a processar
	(_cAlTrbSC6)->(dbSelectArea(_cAlTrbSC6))
	ProcRegua( (_cAlTrbSC6)->(RecCount()) )

	// atualiza saldo dos itens do pedido
	(_cAlTrbSC6)->(dbSelectArea(_cAlTrbSC6))
	(_cAlTrbSC6)->(DbGoTop())
	While (_cAlTrbSC6)->(!Eof())
		// seleciona TRB e atualiza saldo
		(_cAlTrbSC6)->(dbSelectArea(_cAlTrbSC6))
		(_cAlTrbSC6)->(RecLock(_cAlTrbSC6))
		(_cAlTrbSC6)->C6_SALDO := (_cAlTrbSC6)->C6_QTDVEN
		(_cAlTrbSC6)->(MsUnLock())

		// posiciona no cadastro do produto para reserva
		dbSelectArea("SB1")
		SB1->( dbSetOrder(1) ) // 1-FILIAL+COD
		SB1->( dbSeek( xFilial("SB1") + (_cAlTrbSC6)->C6_PRODUTO ) )

		// antes de iniciar o processo, verifica bloqueio do produto
		If ( ! SB1->( MsRLock()) )
			// mensagem
			Aviso("TWMSA019 -> sfMapaApanhe", "Produto " + AllTrim((_cAlTrbSC6)->C6_PRODUTO) + " bloqueado em outro mapa de expedição.",{"Fechar"})
			// funcao padrao da TOTVS que libera todos os registros com LOCK do SofLock
			LibLock(_aRegLock)
			// libera todos os registros
			MsUnLockAll()
			// retorno
			Return( .F. )
		EndIf

		// antes de iniciar o processo, bloqueia produto
		If ( ! SoftLock("SB1") )
			// mensagem
			Aviso("TWMSA019 -> sfMapaApanhe","Esta carga já está em processo de cálculo do mapa de apanhe/expedição!",{"Fechar"})
			// funcao padrao da TOTVS que libera todos os registros com LOCK do SofLock
			LibLock(_aRegLock)
			// libera todos os registros
			MsUnLockAll()
			// retorno
			Return( .F. )
		EndIf

		// adiciona RECNO para controle
		Aadd(_aRegLock, {"SB1", SB1->( RecNo() )} )

		// proximo item
		(_cAlTrbSC6)->(dbSkip())
	EndDo
	// primeiro registro
	(_cAlTrbSC6)->(DbGoTop())

	// limpa o arquivo de trabalho dos enderecos caso não seja rotina automática (schedule)
	// pois se não for, o usuário permanece com a tela aberta e as grids preenchidas. Já na rotina automática, ele só tenta uma única vez, com a tabela temporária vazia

	If !(_lRotAuto)
		(_cAlTrb1)->(dbSelectArea(_cAlTrb1))
		(_cAlTrb1)->(__DbZap())

		(_cAlTrb2)->(dbSelectArea(_cAlTrb2))
		(_cAlTrb2)->(__DbZap())

		(_cAlTrb3)->(dbSelectArea(_cAlTrb3))
		(_cAlTrb3)->(__DbZap())

		(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
		(_cAlTrbMov)->(__DbZap())
	EndIf

	// reinicia variavel
	_aMapaApanhe := {}
	_cLogMapa    := ""

	// antes de iniciar o processo, verifica bloqueio da carga
	If ( ! DAK->( MsRLock()) )
		// mensagem
		Aviso("TWMSA019 -> sfMapaApanhe","Esta carga já está em processo de cálculo do mapa de apanhe/expedição!",{"Fechar"})
		// funcao padrao da TOTVS que libera todos os registros com LOCK do SofLock
		LibLock(_aRegLock)
		// libera todos os registros
		MsUnLockAll()
		// retorno
		Return( .F. )
	EndIf

	// antes de iniciar o processo, bloqueia carga
	If ( ! SoftLock("DAK") )
		// mensagem
		Aviso("TWMSA019 -> sfMapaApanhe","Esta carga já está em processo de cálculo do mapa de apanhe/expedição!",{"Fechar"})
		// funcao padrao da TOTVS que libera todos os registros com LOCK do SofLock
		LibLock(_aRegLock)
		// libera todos os registros
		MsUnLockAll()
		// retorno
		Return( .F. )
	EndIf

	// adiciona RECNO para controle
	Aadd(_aRegLock, {"DAK", DAK->( RecNo() )} )

	// varre todos os itens dos pedidos da carga
	(_cAlTrbSC6)->(dbSelectArea(_cAlTrbSC6))
	(_cAlTrbSC6)->(DbGoTop())

	While (_cAlTrbSC6)->( ! Eof() )

		// controle de regua de processamento
		IncProc("Produto/NF Orig: " + AllTrim((_cAlTrbSC6)->C6_PRODUTO) + " / " + (_cAlTrbSC6)->C6_NFORI )

		// quando NAO controla por volume / Nao Expedir em Kit
		If ( ! _lExpEmKit )

			// pesquisa por enderecos relacionados na nota
			_lRetMapa := sfMontaMapa((_cAlTrbSC6)->C6_PRODUTO,;
			(_cAlTrbSC6)->C6_SERIORI,;
			(_cAlTrbSC6)->C6_NFORI  ,;
			(_cAlTrbSC6)->C6_ITEMORI,;
			(_cAlTrbSC6)->C6_SALDO  ,;
			@_cCntrlSeq             ,;
			(_cAlTrbSC6)->D1_NUMSEQ ,;
			(_cAlTrbSC6)->C6_ZTPESTO,;
			mvArmzPadrao            ,;
			(_cAlTrbSC6)->C6_LOTECTL )

			// atualiza variavel de retorno
			If ( ! _lRetMapa)
				_lRet := _lRetMapa
			EndIf

			// quando CONTROLA por volume
		ElseIf (_lExpEmKit)

			// string para SQL
			_cQryProdPed += (_cAlTrbSC6)->C6_PRODUTO + "!"

			// inclui produto
			aAdd(_aProdPedido,{(_cAlTrbSC6)->C6_PRODUTO ,;
			(_cAlTrbSC6)->C6_SALDO                 })

		EndIf

		// proximo item
		(_cAlTrbSC6)->(dbSkip())
	EndDo

	// no controle de volumes, pesquisa configuracao de agrupadores
	If (_lExpEmKit)

		// funcao que pesquisa as configuracoes de agrupadores disponiveis
		_lRetMapa := sfMapaAgrup(;
		@_aProdPedido ,;
		_cQryProdPed  ,;
		@_cCntrlSeq   ,;
		mvArmzPadrao   )

		// atualiza variavel de retorno
		If ( ! _lRetMapa)
			_lRet := _lRetMapa
		EndIf

	EndIf

	// posiciona no primeiro registro de cada browse
	(_cAlTrbSC6)->(dbSelectArea(_cAlTrbSC6))
	(_cAlTrbSC6)->(DbGoTop())

	(_cAlTrb1)->(dbSelectArea(_cAlTrb1))
	(_cAlTrb1)->(DbGoTop())

	(_cAlTrb2)->(dbSelectArea(_cAlTrb2))
	(_cAlTrb2)->(DbGoTop())

	// cria o indice da sequencia
	(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
	(_cAlTrbMov)->(DbGoTop())
	If (_cAlTrbMov)->(!EOF())
		(_cAlTrbMov)->(IndRegua((_cAlTrbMov),(_cTrbMov),"MOV_SEQ",,,"Selecionando Registros..."))
	EndIf
	(_cAlTrbMov)->(DbGoTop())

	If ( ! _lRet )
		Help( ,, 'TWMSA019.F01.006',, "Não foi possível gerar o mapa de apanhe." + CRLF+CRLF + _cLogMapa , 1, 0 )
		If ( ! _lRotAuto ) // se geração em tela, exibe os detalhes do problema
			HS_MsgInf("LOG:" + CRLF + _cLogMapa, "Log do Mapa de Expedição", "Inconsistência " + IIf(_lPorCarga, "Carga", "Onda") + ": " + IIf(_lPorCarga, _cNumCarga, _cNrOndSep) )
		EndIf
	EndIf

	// atualiza browse
	If ( ! _lRotAuto )

		// browse - disponiveis COM etiqueta
		mvBrwDisp1:oBrowse:Refresh()
		// browse - disponiveis SEM etiqueta
		mvBrwDisp2:oBrowse:Refresh()
		// browse - disponiveis de agrupadora
		mvBrwDisp3:oBrowse:Refresh()

	EndIf

Return( _lRet )

// ** funcao que pesquisa por enderecos relacionados na nota
Static Function sfMontaMapa(mvProduto, mvSerie, mvNota, mvItem, mvQuant, mvCntrlSeq, mvNumSeq, mvTipEsto, mvArmzPadrao, mvLote, lTroca)
	// variavel de retorno
	local _lRet := .F.
	// query para busca de dados
	local _cQuery
	local _cAlQry := GetNextAlias()
	// quantidade
	local _nQtdSelec := 0
	local _nQtdSegum := 0
	// saldo no endereco
	local _nSaldoEnd := 0
	local _nSldJaUti := 0
	// fracionar palete
	local _cFracPlt := "N"
	// saldo do palete atual
	local _nSldPltAtu := 0

	// saldo de apanhe
	local _nSaldoApanhe := mvQuant

	// posicao da reserva do endereco no vetor do mapa de apanhe
	local _nPosReserv := 0

	// endereco atual
	local _cEndAtual

	// armazem atual
	local _cArmzAtual

	// ID palete
	local _cIdPalete

	// saldo do palete
	local _aSaldoPlt := {}

	// variavel de controle de lote
	local _cLoteCTL := ""

	// estrutura fisicas para expedicao
	local _cEstFisExp := IIf(_lExpEmKit, _cEstPicking, _cEstFisMapa)

	// quantidade maxima de volumes/agrupadora por palete
	// estrutura do retorno
	// 1-Quantidade Total de Palete
	// 2-Quantidade de Paletes Cheios
	// 3-Quantidade de Paletes Fracionados
	// 4-Quantidade Maxima de SKU/Volumes por Palete
	// 5-Tipo do Calculo (Q-Quant Unitarios / P-Quant Palete Informado)
	Local _aRetPal := IIf(_lUsaSldPlt, {0,0,0,1,""}, U_FtWmsNorma(mvProduto, mvArmzPadrao, Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil))

	// atualiza variavel de controle de acordo com o calculo da funcao FtWmsNorma
	local _nVolMaxPlt := _aRetPal[4]

	// quantidade de paletes completos
	local _nPltComple := 0

	// quantidade de paletes fracionados
	local _nPltFracio := 0

	// modelo de pesquisa
	local _lPltComple := .F.
	local _lPltFracio := .F.

	// fracionar volume
	local _cFracVol := "N"

	// controle do Loop de tentativas de busca
	local _lNovaBusca := .T.

	// controle se o endereco atendeu a condicao
	local _lEndAtende := .T.

	// controle do tipo de busca
	// 1-Palete Completo
	// 2-Palete Fracionado
	// 3-Palete com Qualquer Quantidade
	local _cPadrBusca := IIf((_lUsaSldPlt) .Or. (_lVolJaDef), "3", "1")
	local _cTipoBusca := _cPadrBusca

	// controle para considerar a quantidade
	// 1-Palete com Quantidade Exata
	// 2-Palete com Quantidade Maior
	// 3-Palete com Quantidade Menor
	local _cTipoQuant := "1"

	// controle se deve mudar a busca, de palete completo para fracionado, quando sobrar saldo
	local _lMudaBusca := .F.

	//se for troca de Endereço Destino na tela de Mapa.
	DEFAULT lTroca := .F.  

	// quando nao usa palete completo, valida se encontrou lastro e camada
	If ( ! _lUsaSldPlt ) .And. (_nVolMaxPlt == 0)
		// define log
		If ( ! Empty(mvSerie))
			_cLogMapa += "Série/Nota/Item: "+mvSerie+"/"+mvNota+"/"+mvItem+CRLF
		EndIf
		_cLogMapa += "Produto: "+AllTrim(mvProduto)+"-"+AllTrim(Posicione("SB1",1,xFilial("SB1")+mvProduto,"B1_DESC"))+" -- "
		_cLogMapa += "Qtd Solic.: "+AllTrim(Str(mvQuant))+" / "
		_cLogMapa += "Sem Cadastro de Lastro x Camada"+CRLF
		// variavel de controle
		_lRet := .F.
		// retorno
		Return(_lRet)
	EndIf

	// cria o indice para pesquisa de enderecos do produto no mapa de movimentacao
	(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
	If (_cAlTrbMov)->(!EOF())
		(_cAlTrbMov)->(IndRegua((_cAlTrbMov),(_cTrbMov),"MOV_PROD+MOV_LOCAL+MOV_ENDORI+MOV_PALETE+MOV_LOTCTL",,,"Selecionando Registros..."))
	EndIf

	// posiciona no produto, para pegar os dados do grupo
	dbSelectArea("SB1")
	SB1-> ( dbSetOrder(1) ) // 1-FILIAL+COD
	If ( ! SB1-> ( dbSeek( xFilial("SB1")+mvProduto ) ) )
		// mensagem
		U_FtWmsMsg("TWMSA019 -> Produto "+mvProduto+" não encontrado!")
		// variavel de controle
		_lRet := .F.
		// retorno
		Return (_lRet)
	EndIf

	// calcula a quantidade de paletes completos
	_nPltComple := Int(_nSaldoApanhe / _nVolMaxPlt)

	// calcula a quantidade de paletes fracionados
	If (Mod(_nSaldoApanhe,_nVolMaxPlt) > 0)
		_nPltFracio := 1
	EndIf

	// modelo de pesquisa de palete completo/fracionado
	_lPltComple := (_nPltComple > 0)
	_lPltFracio := (_nPltFracio > 0)

	// controle do tipo de busca
	// 1-Palete Completo
	// 2-Palete Fracionado
	// 3-Palete com Qualquer Quantidade
	If (_lUsaSldPlt)
		_cTipoBusca := _cPadrBusca
	Else
		_cTipoBusca := IIf(_lPltComple, "1", "2")
	EndIf

	// controle para considerar a quantidade
	// 1-Palete com Quantidade Exata
	// 2-Palete com Quantidade Maior
	// 3-Palete com Quantidade Menor
	_cTipoQuant := "1"

	// controle de while para tratativas de novas buscas
	While (_nSaldoApanhe > 0) .And. (_lNovaBusca) .and. (!_lQbFIFO)

		// -- #1 - BUSCA ENDERECOS RELACIONADOS A NOTA FISCAL
		_cQuery := " SELECT Z16_ETQPAL, "
		_cQuery += "        Z16_LOCAL, "
		_cQuery += "        Z16_ENDATU, "
		_cQuery += "        Sum(Z16_SALDO)                              AS Z16_SALDO, "
		_cQuery += "        Z16_LOTCTL, "
		_cQuery += "        Count(DISTINCT Z16_ETQVOL)                  AS QTD_ETQVOL, "
		_cQuery += "        Count(DISTINCT Z16_ETQPRD) * Sum(Z16_SALDO) AS QTD_ETQPRD, "
		_cQuery += "        BF_ESTFIS "
		_cQuery += " FROM   (SELECT DISTINCT Z16_ETQPAL, "
		_cQuery += "                         Z16_LOCAL, "
		_cQuery += "                         Z16_ENDATU, "
		_cQuery += "                         Z16_SALDO, "
		_cQuery += "                         Z16_LOTCTL, "
		_cQuery += "                         Z16_ETQVOL, "
		_cQuery += "                         Z16_ETQPRD, "
		_cQuery += "                         (SELECT Count(DISTINCT ( CASE WHEN SBFKIT.BF_ESTFIS IN ( '000002', '000010' ) THEN SBFKIT.BF_PRODUTO ELSE '000000' END )) "
		_cQuery += "                          FROM   "+RetSqlName("SBF")+" SBFKIT (nolock)  "
		_cQuery += "                          WHERE  SBFKIT.BF_FILIAL = '"+xFilial("SBF")+"' "
		_cQuery += "                                 AND SBFKIT.D_E_L_E_T_ = ' ' "
		_cQuery += "                                 AND SBFKIT.BF_LOCAL = SBF.BF_LOCAL "
		_cQuery += "                                 AND SBFKIT.BF_LOCALIZ = SBF.BF_LOCALIZ) QTD_SKU, "
		_cQuery += "                         BF_ESTFIS "
		// composicao de palete
		_cQuery += "         FROM   " + RetSqlTab("Z16") + " (NOLOCK)"
		// saldo do produto no endereco
		_cQuery += "                INNER JOIN "+RetSqlTab("SBF") + " (NOLOCK)"
		_cQuery += "                        ON "+RetSqlCond("SBF")
		_cQuery += "                           AND BF_LOCAL = Z16_LOCAL "
		_cQuery += "                           AND BF_LOCALIZ = Z16_ENDATU "
		_cQuery += "                           AND BF_PRODUTO = Z16_CODPRO "
		_cQuery += "                           AND BF_ESTFIS IN "+FormatIn(_cEstFisExp,"/")+" "
		_cQuery += "                           AND BF_LOTECTL = Z16_LOTCTL "

		// filtra estrutura fisica
		If (_cTipoBusca == "1") // 1-Palete Completo
			_cQuery += " AND BF_ESTFIS IN ('000002', '000003', '000007') "
		ElseIf (_cTipoBusca == "2") // 2-Palete Fracionado
			_cQuery += " AND BF_ESTFIS IN ('000007', '000010') "
		EndIf

		// já que não há fracionamento de lote, não faz a validação pois vai buscar os endereços na Z45
		If ( ! _lLotAtivo )
			// controla saldo de enderecos que estao no plano de expedicao
			_cQuery += "                           AND BF_QUANT > (SELECT Isnull(Sum(Z08_QUANT), 0) "
			_cQuery += "                                           FROM   "+RetSqlTab("Z08") + " (NOLOCK)"
			_cQuery += "                                                  INNER JOIN "+RetSqlTab("Z06") + " (NOLOCK)"
			_cQuery += "                                                          ON "+RetSqlCond("Z06")
			_cQuery += "                                                             AND Z06_NUMOS = Z08_NUMOS "
			_cQuery += "                                                             AND Z06_SEQOS = Z08_SEQOS "
			_cQuery += "                                                             AND Z06_ATUEST = 'S' "
			_cQuery += "                                           WHERE  "+RetSqlCond("Z08")
			_cQuery += "                                                  AND Z08_STATUS IN ( 'P', 'M' ) "
			_cQuery += "                                                  AND Z08_LOCAL = BF_LOCAL "
			_cQuery += "                                                  AND Z08_ENDORI = BF_LOCALIZ "
			_cQuery += "                                                  AND Z08_PRODUT = BF_PRODUTO) "
		EndIf

		// quando os volumes ja foram definidos/selecionados no pedido de venda
		If ( _lVolJaDef )
			_cQuery += "                INNER JOIN " + RetSqlTab("Z45") + " (NOLOCK)"
			_cQuery += "                        ON " + RetSqlCond("Z45")
			_cQuery += "                           AND Z45_ETQPAL = Z16_ETQPAL "
			_cQuery += "                           AND Z45_CODPRO = Z16_CODPRO "
			_cQuery += "                           AND Z45_LOTCTL = Z16_LOTCTL "
			_cQuery += "                           AND Z16_ETQVOL = Z45_ETQVOL "
			_cQuery += "                           AND Z45_PEDIDO IN "+FormatIn(_cNumPed,"/")
		EndIf

		// filtro padrao
		_cQuery += "         WHERE  "+RetSqlCond("Z16")

		// etiquetas
		If ( ! _lExpEmKit )

			// etiqueta interna
			If (_lEtqIdInt)
				_cQuery += "                AND Z16_ETQPRD IN (SELECT Z11_CODETI "
				_cQuery += "                                   FROM   "+RetSqlTab("Z11") + " (NOLOCK)"
				_cQuery += "                                   WHERE  "+RetSqlCond("Z11")
				_cQuery += "                                          AND Z11_DOC = '"+mvNota+"' "
				_cQuery += "                                          AND Z11_SERIE = '"+mvSerie+"' "
				_cQuery += "                                          AND Z11_ITEMNF = '"+mvItem+"' "
				_cQuery += "                                          AND Z11_CODPRO = '"+mvProduto+"') "
			EndIf

			// etiqueta de volumes / ean
			If ((_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIDDun)) .And. (_lCtrVolume)
				_cQuery += "                AND ( Z16_ETQVOL IN (SELECT Z11_CODETI "
				_cQuery += "                                     FROM   " + RetSqlTab("Z11") + " (NOLOCK)"
				_cQuery += "                                     WHERE  " + RetSqlCond("Z11")
				_cQuery += "                                            AND Z11_DOC = '" + mvNota + "' "
				_cQuery += "                                            AND Z11_SERIE = '" + mvSerie + "' "
				_cQuery += "                                            AND Z11_ITEMNF = '" + mvItem + "' "
				_cQuery += "                                            AND Z11_CODPRO = '" + mvProduto + "') "
				_cQuery += "                       OR Z16_NUMSEQ = '" + mvNumSeq + "' ) "
			EndIf

		EndIf

		// somente com saldo
		_cQuery += "                AND Z16_SALDO > 0 "
		// produto
		_cQuery += "                AND Z16_CODPRO = '"+mvProduto+"' "
		// tipo do estoque
		_cQuery += "                AND Z16_TPESTO = '"+mvTipEsto+"' "
		// descarta armazem A3
		_cQuery += "                AND Z16_LOCAL NOT IN ( 'A3' ) "
		// armazem padrao do cliente
		_cQuery += "                AND Z16_LOCAL = '" +mvArmzPadrao+ "' "
		//filtro de endereços sob inventario
		_cQuery += " AND Z16_ENDATU NOT IN (SELECT Z21_LOCALI FROM " + RetSqlTab("Z21") + " (NOLOCK) WHERE " + RetSqlCond("Z21") + " AND Z21_PROD = BF_PRODUTO AND Z21_IDENT IN (SELECT Z06_NUMOS FROM " + RetSqlTab("Z06") + " (NOLOCK) WHERE Z06_FILIAL = Z21_FILIAL AND Z06_SERVIC = 'T02' AND Z06_NUMOS = Z21_IDENT AND D_E_L_E_T_ = '' AND Z06_STATUS NOT IN ('FI', 'CA'))) "
		//filtro de endereços cujos pallets ainda estão em OS de recebimento não finalizada (SERVIÇO 003 - RECEBIMENTO)
		_cQuery += " AND Z16_ETQPAL NOT IN (SELECT DISTINCT Z07_PALLET FROM " + RetSqlTab("Z07") + " (NOLOCK) WHERE " + RetSqlCond("Z07") + " AND Z07_PRODUT = BF_PRODUTO AND Z07_NUMOS IN (SELECT Z06_NUMOS FROM Z06010 (NOLOCK) WHERE Z06_FILIAL = Z07_FILIAL AND Z06_NUMOS = Z07_NUMOS AND D_E_L_E_T_ = '' AND Z06_SERVIC = '003' AND Z06_STATUS NOT IN ('FI','CA'))) "

		//filtra endereços origem e destino já reservados (exceto para expedição)
		_cQuery += " AND Z16_ENDATU NOT IN (
		_cQuery += " SELECT Z08_ENDDES AS 'END'   "
		_cQuery += " FROM  " + RetSqlTab("Z08") + " (NOLOCK)"
		_cQuery += " WHERE " + RetSqlCond("Z08")
		_cQuery += "  AND Z08_LOCAL = Z16_LOCAL"
		_cQuery += "  AND Z08_STATUS != 'R' "
		_cQuery += "  AND Z08_PRODUT = BF_PRODUTO "
		_cQuery += "  AND Z08_TPOPER != 'S' "
		_cQuery += " UNION ALL                    "
		_cQuery += " SELECT Z08_ENDORI AS 'END'   "
		_cQuery += " FROM  " + RetSqlTab("Z08") + " (NOLOCK)"
		_cQuery += " WHERE " + RetSqlCond("Z08")
		_cQuery += "  AND Z08_LOCAL = Z16_LOCAL  "
		_cQuery += "  AND Z08_PRODUT = BF_PRODUTO  "
		_cQuery += "  AND Z08_STATUS != 'R' "
		_cQuery += "  AND Z08_TPOPER != 'S') "

		// se controlar lote, ele vai pegar os endereços já estipulados no Z45 para o pedido informado
		If ( _lLotAtivo )
			If ( ! _lLotObrSai )
				_cQuery += "                AND Z16_ETQPAL IN (SELECT Z45_ETQPAL FROM "+RetSqlTab("Z45")+" (nolock)  WHERE "+RetSqlCond("Z45")+" AND Z45_PEDIDO IN "+FormatIn(_cNumPed,"/")+" ) "
			ElseIf ( _lLotObrSai ) .And. ( ! _lVolJaDef )
				_cQuery += "                AND Z16_LOTCTL = '" + mvLote + "' "
			EndIf
		Else
			// quando não controlar o lote, só busca pelos pallets que não possuem lote
			_cQuery += "                AND Z16_LOTCTL = '' "
		EndIf
		_cQuery += "                ) PALETES_DISPONIVEIS "

		// para cliente com controle de volumes, valida se expede em kit/agrupadora
		If (_lCtrVolume) .And. ( ! _lExpEmKit )
			_cQuery += " WHERE  QTD_SKU = 1 "
		EndIf

		// agrupa os dados
		_cQuery += " GROUP  BY Z16_ETQPAL, "
		_cQuery += "           Z16_LOCAL, "
		_cQuery += "           Z16_ENDATU, "
		_cQuery += "           Z16_LOTCTL, "
		_cQuery += "           BF_ESTFIS "

		// controle do tipo de busca
		// 1-Palete Completo
		// 2-Palete Fracionado
		// 3-Palete com Qualquer Quantidade
		If (_cTipoBusca == "1") // 1-Palete Completo
			If (_lEtqIdInt)
				_cQuery += " HAVING Sum(Z16_SALDO) = "+AllTrim(Str(_nVolMaxPlt))+" "
			ElseIf (_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIDDun)
				_cQuery += " HAVING Sum(Z16_SALDO) = "+AllTrim(Str(_nVolMaxPlt))+" "
			EndIf
		ElseIf (_cTipoBusca == "2") // 2-Palete Fracionado
			If (_lEtqIdInt)
				_cQuery += " HAVING Sum(Z16_SALDO) != "+AllTrim(Str(_nVolMaxPlt))+" "
			ElseIf (_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIDDun)
				_cQuery += " HAVING Sum(Z16_SALDO) != "+AllTrim(Str(_nVolMaxPlt))+" "
			EndIf
		EndIf

		// ordem do endereco de busca
		_cQuery += " ORDER  BY CASE "
		_cQuery += "             WHEN BF_ESTFIS = '000010' THEN 100 "
		_cQuery += "             ELSE 0 "
		_cQuery += "           END DESC,
		_cQuery += "           " + _cQryOrdPlt + ", "
		_cQuery += "           Substring(Z16_ENDATU, 1, 2), "
		_cQuery += "           Substring(Z16_ENDATU, 4, 2), "
		_cQuery += "           Substring(Z16_ENDATU, 3, 1), "
		_cQuery += "           Substring(Z16_ENDATU, 8, 5), "
		_cQuery += "           Substring(Z16_ENDATU, 6, 2) "

		memowrit("c:\query\twmsa019_sfMontaMapa_1_tpbusca_"+_cTipoBusca+"_saldo_nota.txt",_cQuery)

		// verifica se o alias esta em uso
		If (Select(_cAlQry) > 0)
			dbSelectArea(_cAlQry)
			dbCloseArea()
		EndIf

		// executa o select
		DbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),(_cAlQry),.F.,.T.)
		(_cAlQry)->(dbGoTop())

		// varre todos os enderecos
		While (_cAlQry)->( ! Eof() ) .And. (_lNovaBusca)

			// zera variavel
			_nQtdSelec    := 0
			_nQtdSegum    := 0
			_cFracPlt     := "N"
			_cArmzAtual   := (_cAlQry)->Z16_LOCAL
			_cEndAtual    := (_cAlQry)->Z16_ENDATU
			_cIdPalete    := (_cAlQry)->Z16_ETQPAL
			_cLoteCTL     := (_cAlQry)->Z16_LOTCTL
			_nSldPltAtu   := (_cAlQry)->Z16_SALDO

			// verifica se o endereco existe
			dbSelectArea("SBE")
			SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
			SBE->(dbSeek( xFilial("SBE")+_cArmzAtual+_cEndAtual ))

			// valida status do endereco
			If (SBE->BE_STATUS == "3")
				// proximo endereco
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// verifica o saldo do produto no endereco de origem
			_nSaldoEnd := SaldoSBF(;
			_cArmzAtual  ,;
			_cEndAtual   ,;
			mvProduto    ,;
			NIL          ,;
			_cLoteCTL    ,;
			NIL          ,;
			.F.          ,;
			SBE->BE_ESTFIS)

			// verifica o saldo no endereco
			If (_nSaldoEnd <= 0)
				// proximo endereco
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// para os casos de enderecos em bloco, define a quantidade do endereco de acordo com o saldo do palete
			// posiciono na DC8 pra validar qual o tipo de endereço
			dbSelectArea("DC8")
			DC8->(dbSetOrder(1)) // DC8_FILIAL, DC8_CODEST, R_E_C_N_O_, D_E_L_E_T_
			DC8->(dbSeek( xFilial("DC8")+SBE->BE_ESTFIS ))

			/*
			Retornos da DC8
			1 - PORTA PALETE A1 / ANALISE TECNICA
			2 - PICKING
			4 - MEZANINO A1 / NAO CONFORME / TRANSF FILIAIS / QUALIDADE / BLOCADO A1 - CTBA
			5 - DOCAS A1
			7 - RUA/CORREDOR
			*/

			If (DC8->DC8_TPESTR $ "4/5/7") .Or. (_lVolJaDef)
				_nSaldoEnd := _nSldPltAtu
			EndIf

			// verifica se o endereco ja foi utilizado em outro item

			// estrutura _aMapaApanhe
			//  1-cod produto
			//  2-local/armazem
			//  3-end retirada
			//  4-quant
			//  5-end destino
			//  6-ID palete
			//  7-fraciona palete
			//  8-serie nota orig
			//  9-nota orig
			// 10-item nota orig
			// 11-sequencial
			// 12-numseq
			// 13-id volume
			// 14-Lote
			// 15-Tipo de Estoque
			// 16-Quantidade Seg Unid

			// zera conteudo
			_nSldJaUti := 0
			// calcula saldo ja utilizado no endereco e palete
			aEval(_aMapaApanhe,{|x| _nSldJaUti += IIf((x[1] == mvProduto) .And. (x[2] == _cArmzAtual) .And. (x[3] == _cEndAtual) .And. (x[6] == _cIdPalete) .And. (x[14] == _cLoteCTL), x[4], 0) })

			// reduz o saldo do endereco ja utilizado
			If (_nSldJaUti != 0)
				_nSaldoEnd -= _nSldJaUti
			EndIf

			// verifica o saldo no endereco
			If (_nSaldoEnd <= 0)
				// proximo endereco
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// verifica o saldo no palete, desconsiderando o saldo ja reservado
			// dados para retorno
			// 1-Id Palete
			// 2-Local/Armazem
			// 3-Endereco Atual
			// 4-Etq Produto
			// 5-Etq Volume
			// 6-Cod Produto
			// 7-Saldo Atual (Z16)
			// 8-Saldo Reservado (Z08)
			// 9-Saldo Disponivel (Z16 - Z08)
			_aSaldoPlt := U_FtSldPlt(_cIdPalete,;
			Nil       ,;
			Nil       ,;
			mvProduto ,;
			.F.       ,;
			.F.       ,;
			_cLoteCTL  )

			// reduz o saldo do endereco ja utilizado em outro mapa
			If (Len(_aSaldoPlt) > 0) .And. ( ! _lVolJaDef )
				_nSaldoEnd -= _aSaldoPlt[1][8]
			EndIf

			// verifica o saldo no endereco
			If (_nSaldoEnd <= 0)
				// proximo endereco
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// controle do tipo de busca
			// 1-Palete Completo
			// 2-Palete Fracionado
			// 3-Palete com Qualquer Quantidade
			If (_cTipoBusca == "1") // 1-Palete Completo
				If (_nSaldoEnd != _nVolMaxPlt)
					// proximo endereco
					(_cAlQry)->(dbSkip())
					Loop
				EndIf
			ElseIf (_cTipoBusca == "2") // 2-Palete Fracionado
				If (_nSaldoEnd == _nVolMaxPlt)
					// proximo endereco
					(_cAlQry)->(dbSkip())
					Loop
				EndIf
			EndIf

			// distinção para controle de saldo
			If (_lUsaSldPlt) .Or. (_cTipoBusca == "1") // 1-Palete Completo
				_nQtdSelec := _nSaldoEnd
				_cFracPlt  := "N"
			ElseIf ( ! _lUsaSldPlt ) .And. (_cTipoBusca != "1") // 1-Palete Completo
				// controle de saldo
				If ( _nSaldoEnd <= _nSaldoApanhe)
					_nQtdSelec := _nSaldoEnd
					_cFracPlt  := "N"
				ElseIf ( _nSaldoEnd > _nSaldoApanhe)
					_nQtdSelec := _nSaldoApanhe
					_cFracPlt  := "S"
				EndIf
			EndIf

			// define a quantidade da segunda unidade de medida
			If (_lCtrVolume) .And. (SB1->B1_CONV == 0) .And. (_lVolJaDef)
				_nQtdSegum := (_cAlQry)->QTD_ETQVOL
			EndIf

			//posiciona na SBE para verificar se existe
			DBSelectArea("SBE")
			DBSetOrder(1)       //BE_FILIAL, BE_LOCAL, BE_LOCALIZ, R_E_C_N_O_, D_E_L_E_T_
			If !(SBE->( dbSeek( xFilial("SBE") + _cArmzAtual + _cEndAtual ) ) )
				(_cAlQry)->(dbSkip())
				Loop
			Endif

			//testa se ja esta bloqueado
			If ( ! SBE->( MsRLock()) )
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// tenta bloquear o endereço
			If ( ! SoftLock("SBE") )
				//proximo registro
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// adiciona RECNO para controle
			Aadd(_aRegLock, {"SBE", SBE->( RecNo() )} )

			// inclui o endereco
			(_cAlTrb1)->(dbSelectArea(_cAlTrb1))
			(_cAlTrb1)->(RecLock(_cAlTrb1,.T.))
			(_cAlTrb1)->ET1_COR    := "OK"
			(_cAlTrb1)->ET1_ORIG   := "Z16"
			(_cAlTrb1)->ET1_PROD   := mvProduto
			(_cAlTrb1)->ET1_ENDORI := _cEndAtual
			(_cAlTrb1)->ET1_SALDO  := _nSaldoEnd
			(_cAlTrb1)->ET1_QUANT  := _nQtdSelec
			(_cAlTrb1)->ET1_QTSEGU := ConvUM(mvProduto, _nQtdSelec, _nQtdSegum, 2)
			(_cAlTrb1)->ET1_SERORI := mvSerie
			(_cAlTrb1)->ET1_NFORI  := mvNota
			(_cAlTrb1)->ET1_ITEORI := mvItem
			(_cAlTrb1)->ET1_NUMSEQ := mvNumSeq
			(_cAlTrb1)->ET1_SEQ    := mvCntrlSeq
			(_cAlTrb1)->ET1_QRY    := "1"
			(_cAlTrb1)->ET1_TPBUSC := _cTipoBusca
			(_cAlTrb1)->ET1_LOTCTL := _cLoteCTL
			(_cAlTrb1)->ET1_TPESTO := mvTipEsto
			(_cAlTrb1)->ET1_ETQPAL := _cIdPalete
			(_cAlTrb1)->(MsUnLock())

			// atualiza o saldo do pedido
			(_cAlTrbSC6)->(dbSelectArea(_cAlTrbSC6))
			(_cAlTrbSC6)->(RecLock(_cAlTrbSC6))
			(_cAlTrbSC6)->C6_SALDO -= _nQtdSelec
			(_cAlTrbSC6)->(MsUnLock())

			// atualiza o saldo
			_nSaldoApanhe -= _nQtdSelec

			// inclui o endereco selecionado
			(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
			(_cAlTrbMov)->(dbSetOrder(1))
			If !lTroca .And. (_cAlTrbMov)->(dbSeek( mvProduto + _cArmzAtual + _cEndAtual + _cIdPalete + _cLoteCTL ))
				(_cAlTrbMov)->(RecLock(_cAlTrbMov))
				(_cAlTrbMov)->MOV_QUANT  += _nQtdSelec
				(_cAlTrbMov)->MOV_FRAPLT := IIf( (_cAlTrbMov)->MOV_QUANT < (_cAlTrbMov)->MOV_SLDEND , "S", "N")
				(_cAlTrbMov)->MOV_QTSEGU += ConvUM(mvProduto, _nQtdSelec, _nQtdSegum, 2)
				(_cAlTrbMov)->(MsUnLock())
			Else
				(_cAlTrbMov)->(RecLock(_cAlTrbMov,.T.))
				(_cAlTrbMov)->MOV_PROD   := mvProduto
				(_cAlTrbMov)->MOV_LOCAL  := _cArmzAtual
				(_cAlTrbMov)->MOV_ENDORI := _cEndAtual
				(_cAlTrbMov)->MOV_QUANT  := _nQtdSelec
				(_cAlTrbMov)->MOV_QTSEGU := ConvUM(mvProduto, _nQtdSelec, _nQtdSegum, 2)
				(_cAlTrbMov)->MOV_ENDDES := _cEndDest
				(_cAlTrbMov)->MOV_PALETE := _cIdPalete
				(_cAlTrbMov)->MOV_FRAPLT := _cFracPlt
				(_cAlTrbMov)->MOV_CARGA  := _cNumCarga
				(_cAlTrbMov)->MOV_SERORI := mvSerie
				(_cAlTrbMov)->MOV_NFORI  := mvNota
				(_cAlTrbMov)->MOV_ITEORI := mvItem
				(_cAlTrbMov)->MOV_NUMSEQ := mvNumSeq
				(_cAlTrbMov)->MOV_SEQ    := mvCntrlSeq
				(_cAlTrbMov)->MOV_VOLUME := ""
				(_cAlTrbMov)->MOV_LOTCTL := _cLoteCTL
				(_cAlTrbMov)->MOV_TPESTO := mvTipEsto
				(_cAlTrbMov)->(MsUnLock())

				// controle da sequencia
				mvCntrlSeq := Soma1(mvCntrlSeq)

			EndIf

			// estrutura _aMapaApanhe
			//  1-cod produto
			//  2-local/armazem
			//  3-end retirada
			//  4-quant
			//  5-end destino
			//  6-ID palete
			//  7-fraciona palete
			//  8-serie nota orig
			//  9-nota orig
			// 10-item nota orig
			// 11-sequencial
			// 12-numseq
			// 13-id volume
			// 14-Lote
			// 15-Tipo de Estoque
			// 16-Quantidade Seg Unid

			// verifica se o endereco ja foi utilizado em outro item, considerando o palete

			_nPosReserv := aScan(_aMapaApanhe,{|x| (x[1] == mvProduto) .And. (x[2] == _cArmzAtual) .And. (x[3] == _cEndAtual) .And. (x[6] == _cIdPalete) .And. (x[14] == _cLoteCTL) })

			// adiciona os detalhes no mapa de apanhe (utilizado na U_WMSA009B)
			If (_nPosReserv > 0)
				_aMapaApanhe[_nPosReserv][ 4] := (_cAlTrbMov)->MOV_QUANT
				_aMapaApanhe[_nPosReserv][ 7] := (_cAlTrbMov)->MOV_FRAPLT
				_aMapaApanhe[_nPosReserv][16] := (_cAlTrbMov)->MOV_QTSEGU
			Else
				aAdd(_aMapaApanhe,{(_cAlTrbMov)->MOV_PROD  , ;
				(_cAlTrbMov)->MOV_LOCAL , ;
				(_cAlTrbMov)->MOV_ENDORI, ;
				(_cAlTrbMov)->MOV_QUANT , ;
				(_cAlTrbMov)->MOV_ENDDES, ;
				(_cAlTrbMov)->MOV_PALETE, ;
				(_cAlTrbMov)->MOV_FRAPLT, ;
				(_cAlTrbMov)->MOV_SERORI, ;
				(_cAlTrbMov)->MOV_NFORI , ;
				(_cAlTrbMov)->MOV_ITEORI, ;
				(_cAlTrbMov)->MOV_SEQ   , ;
				(_cAlTrbMov)->MOV_NUMSEQ, ;
				(_cAlTrbMov)->MOV_VOLUME, ;
				(_cAlTrbMov)->MOV_LOTCTL, ;
				(_cAlTrbMov)->MOV_TPESTO ,;
				(_cAlTrbMov)->MOV_QTSEGU })
			EndIf

			// define nova busca
			_lNovaBusca := (_nSaldoApanhe > 0)

			// controle se deve mudar a busca, de palete completo para fracionado, quando sobrar saldo
			_lMudaBusca := .F.

			// verifica se deve mudar a busca
			If (_lNovaBusca) .And. (_cTipoBusca == "1") .And. (_nSaldoApanhe < _nVolMaxPlt)
				_lMudaBusca := .T.
			EndIf

			// verifica se deve mudar a logica de busca
			If (_lNovaBusca) .And. (_cTipoBusca == "1") .And. (_lMudaBusca)
				// sai do While de Enderecos
				Exit
			EndIf

			// proximo endereco
			(_cAlQry)->(dbSkip())
		EndDo

		// controle do tipo de busca
		// 1-Palete Completo
		// 2-Palete Fracionado
		// 3-Palete com Qualquer Quantidade
		_cTipoBusca := Soma1(_cTipoBusca)

		// encerra buscas
		If (_cTipoBusca == "4")
			_lNovaBusca := .F.
		EndIf

	EndDo

	// controle do Loop de tentativas de busca
	_lNovaBusca := (_nSaldoApanhe > 0)

	// se ainda tem saldo, recalcula quantidade de paletes completos e fracionados
	If (_lNovaBusca)
		// calcula a quantidade de paletes completos
		_nPltComple := Int(_nSaldoApanhe / _nVolMaxPlt)

		// calcula a quantidade de paletes fracionados
		If (Mod(_nSaldoApanhe,_nVolMaxPlt) > 0)
			_nPltFracio := 1
		EndIf

		// modelo de pesquisa de palete completo/fracionado
		_lPltComple := (_nPltComple > 0)
		_lPltFracio := (_nPltFracio > 0)
	EndIf

	// controle do tipo de busca
	// 1-Palete Completo
	// 2-Palete Fracionado
	// 3-Palete com Qualquer Quantidade
	If (_lUsaSldPlt)
		_cTipoBusca := _cPadrBusca
	Else
		_cTipoBusca := IIf(_lPltComple, "1", "2")
	EndIf

	// controle para considerar a quantidade
	// 1-Palete com Quantidade Exata
	// 2-Palete com Quantidade Maior
	// 3-Palete com Quantidade Menor
	_cTipoQuant := "1"

	// controle de while para tratativas de novas buscas, somente se estiver habilitado para completar o saldo faltante com outras notas fiscais (ignora o numseq)
	While (_nSaldoApanhe > 0) .And. (_lNovaBusca) .And. (_lCompCarga) .and. ( _lQbFIFO )

		// -- #2 - BUSCA TODOS OS ENDERECOS DO PRODUTO, MAS COM SALDO FISCAL ZERADO
		_cQuery := " SELECT BF_PRODUTO, "
		_cQuery += "        BF_LOCAL, "
		_cQuery += "        BF_LOCALIZ, "
		_cQuery += "        BF_QUANT, "
		_cQuery += "        Z16_ETQPAL, "
		_cQuery += "        Z16_LOTCTL, "
		_cQuery += "        Z16_SALDO, "
		_cQuery += "        QTD_SKU, "
		_cQuery += "        BF_ESTFIS "

		// sub-query
		_cQuery += " FROM   (SELECT BF_PRODUTO, "
		_cQuery += "   BF_LOCAL, "
		_cQuery += "   BF_LOCALIZ, "
		_cQuery += "   BF_QUANT, "
		_cQuery += "   Z16_ETQPAL, "
		_cQuery += "   Z16_LOTCTL, "
		_cQuery += "   Sum(Z16_SALDO) Z16_SALDO, "
		_cQuery += "                         (SELECT Count(DISTINCT ( CASE WHEN SBFKIT.BF_ESTFIS IN ( '000002', '000010' ) THEN SBFKIT.BF_PRODUTO ELSE '000000' END )) "
		_cQuery += "                          FROM   "+RetSqlName("SBF")+" SBFKIT (NOLOCK) "
		_cQuery += "                          WHERE  SBFKIT.BF_FILIAL = '"+xFilial("SBF")+"' "
		_cQuery += "                                 AND SBFKIT.D_E_L_E_T_ = ' ' "
		_cQuery += "                                 AND SBFKIT.BF_LOCAL = SBF.BF_LOCAL "
		_cQuery += "                                 AND SBFKIT.BF_LOCALIZ = SBF.BF_LOCALIZ) QTD_SKU, "
		_cQuery += "   BF_ESTFIS "

		// saldo por produto no endereco
		_cQuery += " FROM "+RetSqlTab("SBF") + " (NOLOCK) "

		// camposicao do palete
		_cQuery += " INNER JOIN "+RetSqlTab("Z16")+" (NOLOCK) ON "+RetSqlCond("Z16")+" AND Z16_CODPRO = BF_PRODUTO "
		// local e endereco
		_cQuery += " AND Z16_LOCAL = BF_LOCAL AND Z16_ENDATU = BF_LOCALIZ "
		// somente com saldo
		_cQuery += " AND Z16_SALDO > 0 "
		// tipo do estoque
		_cQuery += " AND Z16_TPESTO = '" + mvTipEsto + "' "
		// lote
		_cQuery += " AND Z16_LOTCTL = BF_LOTECTL "
		//filtro de endereços sob inventario
		_cQuery += " AND Z16_ENDATU NOT IN (SELECT Z21_LOCALI FROM " + RetSqlTab("Z21") + " (NOLOCK) WHERE " + RetSqlCond("Z21") + " AND Z21_PROD = BF_PRODUTO AND Z21_IDENT IN (SELECT Z06_NUMOS FROM " + RetSqlTab("Z06") + " (NOLOCK) WHERE Z06_FILIAL = Z21_FILIAL AND Z06_SERVIC = 'T02' AND Z06_NUMOS = Z21_IDENT AND D_E_L_E_T_ = '' AND Z06_STATUS NOT IN ('FI', 'CA'))) "
		//filtro de endereços cujos pallets ainda estão em OS de recebimento não finalizada (SERVIÇO 003 - RECEBIMENTO)
		_cQuery += " AND Z16_ETQPAL NOT IN (SELECT DISTINCT Z07_PALLET FROM " + RetSqlTab("Z07") + " (NOLOCK) WHERE " + RetSqlCond("Z07") + " AND Z07_PRODUT = BF_PRODUTO AND Z07_NUMOS IN (SELECT Z06_NUMOS FROM Z06010 (NOLOCK) WHERE Z06_FILIAL = Z07_FILIAL AND Z06_NUMOS = Z07_NUMOS AND D_E_L_E_T_ = '' AND Z06_SERVIC = '003' AND Z06_STATUS NOT IN ('FI','CA'))) "

		//filtra endereços origem e destino já reservados (exceto para expedição)
		_cQuery += " AND Z16_ENDATU NOT IN (
		_cQuery += " SELECT Z08_ENDDES AS 'END'   "
		_cQuery += " FROM  " + RetSqlTab("Z08") + " (NOLOCK)"
		_cQuery += " WHERE " + RetSqlCond("Z08")
		_cQuery += "  AND Z08_LOCAL = Z16_LOCAL"
		_cQuery += "  AND Z08_STATUS != 'R' "
		_cQuery += "  AND Z08_PRODUT = BF_PRODUTO "
		_cQuery += "  AND Z08_TPOPER != 'S' "
		_cQuery += " UNION ALL                    "
		_cQuery += " SELECT Z08_ENDORI AS 'END'   "
		_cQuery += " FROM  " + RetSqlTab("Z08") + " (NOLOCK)"
		_cQuery += " WHERE " + RetSqlCond("Z08")
		_cQuery += "  AND Z08_LOCAL = Z16_LOCAL  "
		_cQuery += "  AND Z08_PRODUT = BF_PRODUTO  "
		_cQuery += "  AND Z08_STATUS != 'R' "
		_cQuery += "  AND Z08_TPOPER != 'S') "
		// se controlar lote, ele vai pegar os endereços já estipulados no Z45 para o pedido informado
		If ( _lLotAtivo )
			If ( ! _lLotObrSai )
				_cQuery += "                AND Z16_ETQPAL IN (SELECT Z45_ETQPAL FROM "+RetSqlTab("Z45")+" (nolock)  WHERE "+RetSqlCond("Z45")+" AND Z45_PEDIDO IN "+FormatIn(_cNumPed,"/")+" ) "
			ElseIf ( _lLotObrSai ) .And. ( ! _lVolJaDef )
				_cQuery += "                AND Z16_LOTCTL = '" + mvLote + "' "
			EndIf
		Else
			// quando não controlar o lote, só busca pelos pallets que não possuem lote
			_cQuery += "                AND Z16_LOTCTL = '' "
		EndIf

		// saldo fiscal zerado
		_cQuery += "       INNER JOIN " + RetSqlTab("SB6") + " (NOLOCK) "
		_cQuery += "               ON " + RetSqlCond("SB6")
		_cQuery += "                  AND B6_IDENT = Z16_NUMSEQ "
		_cQuery += "                  AND B6_PODER3 = 'R' "
		_cQuery += "                  AND B6_SALDO = 0 "

		// quando os volumes ja foram definidos/selecionados no pedido de venda
		If ( _lVolJaDef )
			_cQuery += "                INNER JOIN " + RetSqlTab("Z45") + " (NOLOCK) "
			_cQuery += "                        ON " + RetSqlCond("Z45")
			_cQuery += "                           AND Z45_ETQPAL = Z16_ETQPAL "
			_cQuery += "                           AND Z45_CODPRO = Z16_CODPRO "
			_cQuery += "                           AND Z45_LOTCTL = Z16_LOTCTL "
			_cQuery += "                           AND Z16_ETQVOL = Z45_ETQVOL "
			_cQuery += "                           AND Z45_PEDIDO IN "+FormatIn(_cNumPed,"/")
		EndIf

		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("SBF")+" "
		// produto
		_cQuery += "AND BF_PRODUTO = '"+mvProduto+"' "
		// quanto nao expede em kit, pega de varias estruturas fisiscas
		If ( ! _lExpEmKit )
			_cQuery += "AND BF_ESTFIS IN "+FormatIn(_cEstFisMapa,"/")+" "
			// quando controla volume, so expede produto unitario quanto for Picking
		ElseIf (_lExpEmKit)
			_cQuery += "AND BF_ESTFIS IN "+FormatIn(_cEstPicking,"/")+" "
		EndIf

		// filtra estrutura fisica
		If (_cTipoBusca == "1") // 1-Palete Completo
			_cQuery += " AND BF_ESTFIS IN ('000002', '000003', '000007') "
		ElseIf (_cTipoBusca == "2") // 2-Palete Fracionado
			_cQuery += " AND BF_ESTFIS IN ('000007', '000010') "
		EndIf

		// controla saldo de enderecos que estao no plano de expedicao
		_cQuery += "AND BF_QUANT > (SELECT ISNULL(SUM(Z08_QUANT),0) FROM "+RetSqlName("Z08")+" Z08 (nolock)  "
		// somente OS que NAO movimentou estoque (Z06_ATUEST = 'S' - deve atualizar estoque na movimentacao fisica da carga)
		_cQuery += "INNER JOIN "+RetSqlName("Z06")+" Z06 (nolock)  ON "+RetSqlCond("Z06")+" AND Z06_NUMOS = Z08_NUMOS AND Z06_SEQOS = Z08_SEQOS "
		_cQuery += "AND Z06_ATUEST = 'S' "
		// filtro padrao do mapa
		_cQuery += "WHERE "+RetSqlCond("Z08")+" "
		_cQuery += "AND Z08_STATUS IN ('P','M') AND Z08_LOCAL = BF_LOCAL "
		_cQuery += "AND Z08_ENDORI = BF_LOCALIZ "
		_cQuery += "AND Z08_PRODUT = BF_PRODUTO) "

		// descarta armazem A3
		_cQuery += " AND BF_LOCAL NOT IN ('A3') "

		// armazem padrao do cliente
		_cQuery += " AND BF_LOCAL = '" +mvArmzPadrao+ "' "

		// controle do tipo de busca
		// 1-Palete Completo
		// 2-Palete Fracionado
		// 3-Palete com Qualquer Quantidade
		If (_cTipoBusca == "1") // 1-Palete Completo
			If (_lEtqIdInt)
				_cQuery += " AND Z16_SALDO = "+AllTrim(Str(_nVolMaxPlt))+" "
			ElseIf (_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIDDun)
				_cQuery += " AND Z16_SALDO = "+AllTrim(Str(_nVolMaxPlt))+" "
			EndIf
		ElseIf (_cTipoBusca == "2") // 2-Palete Fracionado
			If (_lEtqIdInt)
				_cQuery += " AND Z16_SALDO != "+AllTrim(Str(_nVolMaxPlt))+" "
			ElseIf (_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIDDun)
				_cQuery += " AND Z16_SALDO != "+AllTrim(Str(_nVolMaxPlt))+" "
			EndIf
		EndIf

		// agrupa os dados
		_cQuery += "GROUP  BY BF_PRODUTO, "
		_cQuery += "          BF_LOCAL, "
		_cQuery += "          BF_LOCALIZ, "
		_cQuery += "          BF_QUANT, "
		_cQuery += "          Z16_ETQPAL, "
		_cQuery += "          Z16_LOTCTL, "
		_cQuery += "          BF_ESTFIS "

		// fecha sub-query
		_cQuery += ") AS PALETES_DISPONIVEIS "

		// para cliente com controle de volumes, valida se expede em kit/agrupadora
		If (_lCtrVolume) .And. ( ! _lExpEmKit )
			_cQuery += " WHERE  QTD_SKU = 1 "
		EndIf

		// ordem do endereco de busca
		_cQuery += " ORDER  BY CASE "
		_cQuery += "             WHEN BF_ESTFIS = '000010' THEN 100 "
		_cQuery += "             ELSE 0 "
		_cQuery += "           END DESC, "
		_cQuery += "           " + _cQryOrdPlt + ", "
		_cQuery += "           Substring(BF_LOCALIZ, 1, 2), "
		_cQuery += "           Substring(BF_LOCALIZ, 4, 2), "
		_cQuery += "           Substring(BF_LOCALIZ, 3, 1), "
		_cQuery += "           Substring(BF_LOCALIZ, 8, 5), "
		_cQuery += "           Substring(BF_LOCALIZ, 6, 2) "

		memowrit("c:\query\twmsa019_sfMontaMapa_2_tpbusca_"+_cTipoBusca+"_todos_enderecos_sem_saldo_fiscal.txt",_cQuery)

		// verifica se o alias esta em uso
		If (Select(_cAlQry) > 0)
			dbSelectArea(_cAlQry)
			dbCloseArea()
		EndIf

		// executa o select
		DbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),(_cAlQry),.F.,.T.)
		(_cAlQry)->(dbGoTop())

		// varre todos os enderecos
		While (_cAlQry)->( ! Eof() ) .And. (_lNovaBusca)

			// zera variavel
			_nQtdSelec  := 0
			_nQtdSegum  := 0
			_cFracPlt   := "N"
			_cIdPalete  := (_cAlQry)->Z16_ETQPAL
			_cLoteCTL   := (_cAlQry)->Z16_LOTCTL
			_cArmzAtual := (_cAlQry)->BF_LOCAL
			_cEndAtual  := (_cAlQry)->BF_LOCALIZ
			_nSldPltAtu := (_cAlQry)->Z16_SALDO

			// verifica se o endereco existe
			dbSelectArea("SBE")
			SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
			SBE->(dbSeek( xFilial("SBE")+_cArmzAtual+_cEndAtual ))

			// valida status do endereco
			If (SBE->BE_STATUS == "3")
				// proximo endereco
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// verifica o saldo do produto no endereco de destino
			_nSaldoEnd := SaldoSBF(;
			_cArmzAtual   ,;
			_cEndAtual    ,;
			mvProduto     ,;
			NIL           ,;
			_cLoteCTL     ,;
			NIL           ,;
			.F.           ,;
			SBE->BE_ESTFIS )

			// verifica o saldo no endereco
			If (_nSaldoEnd <= 0)
				// proximo endereco
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// para os casos de enderecos em bloco, define a quantidade do endereco de acordo com o saldo do palete
			// posiciono na DC8 pra validar qual o tipo de endereço
			dbSelectArea("DC8")
			DC8->(dbSetOrder(1)) // DC8_FILIAL, DC8_CODEST, R_E_C_N_O_, D_E_L_E_T_
			DC8->(dbSeek( xFilial("DC8")+SBE->BE_ESTFIS ))

			/*
			Retornos da DC8
			1 - PORTA PALETE A1 / ANALISE TECNICA
			2 - PICKING
			4 - MEZANINO A1 / NAO CONFORME / TRANSF FILIAIS / QUALIDADE / BLOCADO A1 - CTBA
			5 - DOCAS A1
			7 - RUA/CORREDOR
			*/

			If (DC8->DC8_TPESTR $ "4/5/7") .Or. (_lVolJaDef)
				_nSaldoEnd := _nSldPltAtu
			EndIf

			// verifica se o endereco ja foi utilizado em outro item

			// estrutura _aMapaApanhe
			//  1-cod produto
			//  2-local/armazem
			//  3-end retirada
			//  4-quant
			//  5-end destino
			//  6-ID palete
			//  7-fraciona palete
			//  8-serie nota orig
			//  9-nota orig
			// 10-item nota orig
			// 11-sequencial
			// 12-numseq
			// 13-id volume
			// 14-Lote
			// 15-Tipo de Estoque
			// 16-Quantidade Seg Unid

			// zera conteudo
			_nSldJaUti := 0
			// calcula saldo ja utilizado no endereco e palete
			aEval(_aMapaApanhe,{|x| _nSldJaUti += IIf((x[1] == mvProduto) .And. (x[2] == _cArmzAtual) .And. (x[3] == _cEndAtual) .And. (x[6] == _cIdPalete) .And. (x[14] == _cLoteCTL), x[4], 0) })

			// reduz o saldo do endereco ja utilizado
			If (_nSldJaUti != 0)
				_nSaldoEnd -= _nSldJaUti
			EndIf

			// verifica o saldo no endereco
			If (_nSaldoEnd <= 0)
				// proximo endereco
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// verifica o saldo no palete, desconsiderando o saldo ja reservado
			// dados para retorno
			// 1-Id Palete
			// 2-Local/Armazem
			// 3-Endereco Atual
			// 4-Etq Produto
			// 5-Etq Volume
			// 6-Cod Produto
			// 7-Saldo Atual (Z16)
			// 8-Saldo Reservado (Z08)
			// 9-Saldo Disponivel (Z16 - Z08)
			_aSaldoPlt := U_FtSldPlt(_cIdPalete,;
			Nil       ,;
			Nil       ,;
			mvProduto ,;
			.F.       ,;
			.F.       ,;
			_cLoteCTL  )

			// reduz o saldo do endereco ja utilizado em outro mapa
			If (Len(_aSaldoPlt) > 0) .And. ( ! _lVolJaDef )
				_nSaldoEnd -= _aSaldoPlt[1][8]
			EndIf

			// verifica o saldo no endereco
			If (_nSaldoEnd <= 0)
				// proximo endereco
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// controle do tipo de busca
			// 1-Palete Completo
			// 2-Palete Fracionado
			// 3-Palete com Qualquer Quantidade
			If (_cTipoBusca == "1") // 1-Palete Completo
				If (_nSaldoEnd != _nVolMaxPlt)
					// proximo endereco
					(_cAlQry)->(dbSkip())
					Loop
				EndIf
			ElseIf (_cTipoBusca == "2") // 2-Palete Fracionado
				If (_nSaldoEnd == _nVolMaxPlt)
					// proximo endereco
					(_cAlQry)->(dbSkip())
					Loop
				EndIf
			EndIf

			// controle de saldo
			If (_lUsaSldPlt) .Or. (_cTipoBusca == "1") // 1-Palete Completo
				_nQtdSelec := _nSaldoEnd
				_cFracPlt  := "N"
			ElseIf ( ! _lUsaSldPlt) .And. (_cTipoBusca != "1") // 1-Palete Completo
				If (_nSaldoEnd <= _nSaldoApanhe)
					_nQtdSelec := _nSaldoEnd
					_cFracPlt  := "N"
				ElseIf (_nSaldoEnd > _nSaldoApanhe)
					_nQtdSelec := _nSaldoApanhe
					_cFracPlt  := "S"
				EndIf
			EndIf

			// define a quantidade da segunda unidade de medida
			If (_lCtrVolume) .And. (SB1->B1_CONV == 0) .And. (_lVolJaDef)
				_nQtdSegum := (_cAlQry)->QTD_ETQVOL
			EndIf

			//posiciona na SBE para verificar se existe
			DBSelectArea("SBE")
			DBSetOrder(1)       //BE_FILIAL, BE_LOCAL, BE_LOCALIZ, R_E_C_N_O_, D_E_L_E_T_
			If !(SBE->( dbSeek( xFilial("SBE") + _cArmzAtual + _cEndAtual ) ) )
				(_cAlQry)->(dbSkip())
				Loop
			Endif

			//testa se ja esta bloqueado
			If ( ! SBE->( MsRLock()) )
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// tenta bloquear o endereço
			If ( ! SoftLock("SBE") )
				//proximo registro
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// adiciona RECNO para controle
			Aadd(_aRegLock, {"SBE", SBE->( RecNo() )} )

			// inclui o endereco
			(_cAlTrb2)->(dbSelectArea(_cAlTrb2))
			(_cAlTrb2)->(RecLock(_cAlTrb2,.T.))
			(_cAlTrb2)->ET2_COR    := "OK"
			(_cAlTrb2)->ET2_ORIG   := "SBF"
			(_cAlTrb2)->ET2_PROD   := mvProduto
			(_cAlTrb2)->ET2_ENDORI := _cEndAtual
			(_cAlTrb2)->ET2_SALDO  := _nSaldoEnd
			(_cAlTrb2)->ET2_QUANT  := _nQtdSelec
			(_cAlTrb2)->ET2_QTSEGU := ConvUM(mvProduto, _nQtdSelec, _nQtdSegum, 2)
			(_cAlTrb2)->ET2_SERORI := mvSerie
			(_cAlTrb2)->ET2_NFORI  := mvNota
			(_cAlTrb2)->ET2_ITEORI := mvItem
			(_cAlTrb2)->ET2_SEQ    := mvCntrlSeq
			(_cAlTrb2)->ET2_NUMSEQ := mvNumSeq
			(_cAlTrb2)->ET2_QRY    := "2"
			(_cAlTrb2)->ET2_TPBUSC := _cTipoBusca
			(_cAlTrb2)->ET2_LOTCTL := _cLoteCTL
			(_cAlTrb2)->ET2_TPESTO := mvTipEsto
			(_cAlTrb2)->ET2_ETQPAL := _cIdPalete
			(_cAlTrb2)->(MsUnLock())

			// atualiza o saldo do pedido
			(_cAlTrbSC6)->(dbSelectArea(_cAlTrbSC6))
			(_cAlTrbSC6)->(RecLock(_cAlTrbSC6))
			(_cAlTrbSC6)->C6_SALDO -= _nQtdSelec
			(_cAlTrbSC6)->(MsUnLock())

			// atualiza o saldo
			_nSaldoApanhe -= _nQtdSelec

			// inclui o endereco selecionado
			(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
			(_cAlTrbMov)->(dbSetOrder(1))
			If (_cAlTrbMov)->(dbSeek( mvProduto + _cArmzAtual + _cEndAtual + _cIdPalete + _cLoteCTL ))
				(_cAlTrbMov)->(RecLock(_cAlTrbMov))
				(_cAlTrbMov)->MOV_QUANT  += _nQtdSelec
				(_cAlTrbMov)->MOV_FRAPLT := IIf( (_cAlTrbMov)->MOV_QUANT < (_cAlTrbMov)->MOV_SLDEND ,"S","N")
				(_cAlTrbMov)->MOV_QTSEGU += ConvUM(mvProduto, _nQtdSelec, _nQtdSegum, 2)
				(_cAlTrbMov)->(MsUnLock())
			Else
				(_cAlTrbMov)->(RecLock(_cAlTrbMov,.T.))
				(_cAlTrbMov)->MOV_PROD   := mvProduto
				(_cAlTrbMov)->MOV_LOCAL  := _cArmzAtual
				(_cAlTrbMov)->MOV_ENDORI := _cEndAtual
				(_cAlTrbMov)->MOV_QUANT  := _nQtdSelec
				(_cAlTrbMov)->MOV_QTSEGU := ConvUM(mvProduto, _nQtdSelec, _nQtdSegum, 2)
				(_cAlTrbMov)->MOV_ENDDES := _cEndDest
				(_cAlTrbMov)->MOV_PALETE := _cIdPalete
				(_cAlTrbMov)->MOV_FRAPLT := _cFracPlt
				(_cAlTrbMov)->MOV_CARGA  := _cNumCarga
				(_cAlTrbMov)->MOV_SERORI := mvSerie
				(_cAlTrbMov)->MOV_NFORI  := mvNota
				(_cAlTrbMov)->MOV_ITEORI := mvItem
				(_cAlTrbMov)->MOV_NUMSEQ := mvNumSeq
				(_cAlTrbMov)->MOV_SEQ    := mvCntrlSeq
				(_cAlTrbMov)->MOV_VOLUME := ""
				(_cAlTrbMov)->MOV_LOTCTL := _cLoteCTL
				(_cAlTrbMov)->MOV_TPESTO := mvTipEsto
				(_cAlTrbMov)->(MsUnLock())

				// controle da sequencia
				mvCntrlSeq := Soma1(mvCntrlSeq)

			EndIf

			// estrutura _aMapaApanhe
			//  1-cod produto
			//  2-local/armazem
			//  3-end retirada
			//  4-quant
			//  5-end destino
			//  6-ID palete
			//  7-fraciona palete
			//  8-serie nota orig
			//  9-nota orig
			// 10-item nota orig
			// 11-sequencial
			// 12-numseq
			// 13-id volume
			// 14-Lote
			// 15-Tipo de Estoque
			// 16-Quantidade Seg Unid

			// verifica se o endereco ja foi utilizado em outro item, considerando o palete

			_nPosReserv := aScan(_aMapaApanhe,{|x| (x[1] == mvProduto) .And. (x[2] == _cArmzAtual) .And. (x[3] == _cEndAtual) .And. (x[6] == _cIdPalete) .And. (x[14] == _cLoteCTL) })

			// adiciona os detalhes no mapa de apanhe (utilizado na U_WMSA009B)
			If (_nPosReserv > 0)
				_aMapaApanhe[_nPosReserv][ 4] := (_cAlTrbMov)->MOV_QUANT
				_aMapaApanhe[_nPosReserv][ 7] := (_cAlTrbMov)->MOV_FRAPLT
				_aMapaApanhe[_nPosReserv][16] := (_cAlTrbMov)->MOV_QTSEGU
			Else
				aAdd(_aMapaApanhe,{(_cAlTrbMov)->MOV_PROD  , ;
				(_cAlTrbMov)->MOV_LOCAL , ;
				(_cAlTrbMov)->MOV_ENDORI, ;
				(_cAlTrbMov)->MOV_QUANT , ;
				(_cAlTrbMov)->MOV_ENDDES, ;
				(_cAlTrbMov)->MOV_PALETE, ;
				(_cAlTrbMov)->MOV_FRAPLT, ;
				(_cAlTrbMov)->MOV_SERORI, ;
				(_cAlTrbMov)->MOV_NFORI , ;
				(_cAlTrbMov)->MOV_ITEORI, ;
				(_cAlTrbMov)->MOV_SEQ   , ;
				(_cAlTrbMov)->MOV_NUMSEQ, ;
				(_cAlTrbMov)->MOV_VOLUME, ;
				(_cAlTrbMov)->MOV_LOTCTL, ;
				(_cAlTrbMov)->MOV_TPESTO ,;
				(_cAlTrbMov)->MOV_QTSEGU })

			EndIf

			// define nova busca
			_lNovaBusca := (_nSaldoApanhe > 0)

			// controle se deve mudar a busca, de palete completo para fracionado, quando sobrar saldo
			_lMudaBusca := .F.

			// verifica se deve mudar a busca
			If (_lNovaBusca) .And. (_cTipoBusca == "1") .And. (_nSaldoApanhe < _nVolMaxPlt)
				_lMudaBusca := .T.
			EndIf

			// verifica se deve mudar a logica de busca
			If (_lNovaBusca) .And. (_cTipoBusca == "1") .And. (_lMudaBusca)
				// sai do While de Enderecos
				Exit
			EndIf

			// proximo endereco
			(_cAlQry)->(dbSkip())
		EndDo

		// controle do tipo de busca
		// 1-Palete Completo
		// 2-Palete Fracionado
		// 3-Palete com Qualquer Quantidade
		_cTipoBusca := Soma1(_cTipoBusca)

		// encerra buscas
		If (_cTipoBusca == "4")
			_lNovaBusca := .F.
		EndIf

	EndDo

	// controle do Loop de tentativas de busca
	_lNovaBusca := (_nSaldoApanhe > 0)

	// se ainda tem saldo, recalcula quantidade de paletes completos e fracionados
	If (_lNovaBusca)
		// calcula a quantidade de paletes completos
		_nPltComple := Int(_nSaldoApanhe / _nVolMaxPlt)

		// calcula a quantidade de paletes fracionados
		If (Mod(_nSaldoApanhe,_nVolMaxPlt) > 0)
			_nPltFracio := 1
		EndIf

		// modelo de pesquisa de palete completo/fracionado
		_lPltComple := (_nPltComple > 0)
		_lPltFracio := (_nPltFracio > 0)
	EndIf

	// controle do tipo de busca
	// 1-Palete Completo
	// 2-Palete Fracionado
	// 3-Palete com Qualquer Quantidade
	If (_lUsaSldPlt)
		_cTipoBusca := _cPadrBusca
	Else
		_cTipoBusca := IIf(_lPltComple, "1", "2")
	EndIf

	// controle para considerar a quantidade
	// 1-Palete com Quantidade Exata
	// 2-Palete com Quantidade Maior
	// 3-Palete com Quantidade Menor
	_cTipoQuant := "1"

	// controle de while para tratativas de novas buscas, somente se estiver habilitado para completar o saldo faltante com outras notas fiscais (ignora o numseq)
	While (_nSaldoApanhe > 0) .And. (_lNovaBusca) .And. (_lCompCarga) .AND. (_lQbFIFO)

		// -- #3 - BUSCA TODOS OS ENDERECOS DO PRODUTO
		_cQuery := "SELECT "
		_cQuery += "   BF_PRODUTO, "
		_cQuery += "   BF_LOCAL, "
		_cQuery += "   BF_LOCALIZ, "
		_cQuery += "   BF_QUANT, "
		_cQuery += "   Z16_ETQPAL, "
		_cQuery += "   Z16_LOTCTL, "
		_cQuery += "   Z16_SALDO, "
		_cQuery += "   Z16_QTSEGU, "
		_cQuery += "   QTD_SKU, "
		_cQuery += "   BF_ESTFIS, "
		_cQuery += "   (SELECT DC8_TPESTR FROM " + RetSqlName("DC8") + " DC8 (NOLOCK) WHERE DC8.DC8_FILIAL = '" + xFilial("DC8") + "' AND DC8.DC8_CODEST = PALETES_DISPONIVEIS.BF_ESTFIS AND DC8.D_E_L_E_T_ = '' ) DC8_TPESTR "
		// se controla número de série
		IF (_lSerieAtv)
			_cQuery += ", Z16_DTSERI, QTD_DATA"
		EndIf
		_cQuery += " FROM ( "

		_cQuery += "SELECT "
		_cQuery += "   BF_PRODUTO, "
		_cQuery += "   BF_LOCAL, "
		_cQuery += "   BF_LOCALIZ, "
		_cQuery += "   BF_QUANT, "
		_cQuery += "   Z16_ETQPAL, "
		_cQuery += "   Z16_LOTCTL, "
		_cQuery += "   Sum(Z16_SALDO) Z16_SALDO, "
		_cQuery += "   Sum(Z16_QTSEGU) Z16_QTSEGU, "
		_cQuery += "   (SELECT Count(DISTINCT ( CASE WHEN SBFKIT.BF_ESTFIS IN ( '000002', '000010' ) THEN SBFKIT.BF_PRODUTO ELSE '000000' END )) "
		_cQuery += "   FROM   " + RetSqlName("SBF") + " SBFKIT (nolock)  "
		_cQuery += "   WHERE  SBFKIT.BF_FILIAL = '"+xFilial("SBF")+"' "
		_cQuery += "   AND SBFKIT.D_E_L_E_T_ = ' ' "
		_cQuery += "   AND SBFKIT.BF_LOCAL = SBF.BF_LOCAL "
		_cQuery += "   AND SBFKIT.BF_LOCALIZ = SBF.BF_LOCALIZ) QTD_SKU, "
		_cQuery += "   BF_ESTFIS "
		// se controla número de série
		IF (_lSerieAtv)
			// verifica também quantas DATAS de número de série possuem no mesmo endereço / palete
			_cQuery += " ,Z16_DTSERI,"
			_cQuery += " (SELECT COUNT(DISTINCT Z16_DTSERI) "
			_cQuery += "  FROM " + RetSqlName("Z16") + " Z16DATA WITH (INDEX (Z160103) NOLOCK) "
			_cQuery += "  WHERE Z16DATA.Z16_FILIAL      = '" + xFilial("Z16") + "' "
			_cQuery += "         AND Z16DATA.Z16_CODPRO = SBF.BF_PRODUTO "
			_cQuery += "         AND Z16DATA.Z16_LOCAL  = SBF.BF_LOCAL "
			_cQuery += "         AND Z16DATA.Z16_ENDATU = SBF.BF_LOCALIZ "
			_cQuery += "         AND Z16DATA.Z16_SALDO  > 0 "
			_cQuery += "         AND Z16DATA.D_E_L_E_T_ = '' ) QTD_DATA "
			// retorna a diferentes entre a menor a maior data no mesmo palete
			_cQuery += " ,(SELECT Datediff(DAY, CONVERT(VARCHAR(10), Min(Z16_DTSERI), 103), CONVERT(VARCHAR(10), Max(Z16_DTSERI), 103)) "
			_cQuery += "  FROM " + RetSqlName("Z16") + " Z16DIFF WITH (INDEX(Z160103) NOLOCK) "
			_cQuery += "  WHERE  Z16DIFF.Z16_FILIAL = '" + xFilial("Z16") + "' "
			_cQuery += "         AND Z16DIFF.Z16_CODPRO = SBF.BF_PRODUTO "
			_cQuery += "         AND Z16DIFF.Z16_LOCAL = SBF.BF_LOCAL "
			_cQuery += "         AND Z16DIFF.Z16_ENDATU = SBF.BF_LOCALIZ "
			_cQuery += "         AND Z16DIFF.D_E_L_E_T_ = '' "
			_cQuery += "         AND Z16DIFF.Z16_ETQPAL = Z16.Z16_ETQPAL "
			_cQuery += "         AND Z16DIFF.Z16_SALDO > 0)              DIF_DATA "
		EndIf

		// saldo por produto no endereco
		_cQuery += " FROM " + RetSqlTab("SBF") + " (NOLOCK) "
		// camposicao do palete
		_cQuery += " INNER JOIN "+RetSqlTab("Z16")+" (NOLOCK) ON " + RetSqlCond("Z16") + " AND Z16_CODPRO = BF_PRODUTO "
		// local e endereco
		_cQuery += " AND Z16_LOCAL = BF_LOCAL AND Z16_ENDATU = BF_LOCALIZ "
		// somente com saldo
		_cQuery += " AND Z16_SALDO > 0 "
		// tipo do estoque
		_cQuery += " AND Z16_TPESTO = '" + mvTipEsto + "' "
		// lote
		_cQuery += " AND Z16_LOTCTL = BF_LOTECTL "
		//filtro de endereços sob inventario
		_cQuery += " AND Z16_ENDATU NOT IN (SELECT Z21_LOCALI FROM " + RetSqlTab("Z21") + " (NOLOCK) WHERE " + RetSqlCond("Z21") + " AND Z21_PROD = BF_PRODUTO AND Z21_IDENT IN (SELECT Z06_NUMOS FROM " + RetSqlTab("Z06") + " (NOLOCK) WHERE Z06_FILIAL = Z21_FILIAL AND Z06_SERVIC = 'T02' AND Z06_NUMOS = Z21_IDENT AND D_E_L_E_T_ = '' AND Z06_STATUS NOT IN ('FI', 'CA'))) "
		//filtro de endereços cujos pallets ainda estão em OS de recebimento não finalizada (SERVIÇO 003 - RECEBIMENTO)
		_cQuery += " AND Z16_ETQPAL NOT IN (SELECT DISTINCT Z07_PALLET FROM " + RetSqlTab("Z07") + " (NOLOCK) WHERE " + RetSqlCond("Z07") + " AND Z07_PRODUT = BF_PRODUTO AND Z07_NUMOS IN (SELECT Z06_NUMOS FROM Z06010 (NOLOCK) WHERE Z06_FILIAL = Z07_FILIAL AND Z06_NUMOS = Z07_NUMOS AND D_E_L_E_T_ = '' AND Z06_SERVIC = '003' AND Z06_STATUS NOT IN ('FI','CA'))) "

		//filtra endereços origem e destino já reservados (exceto para expedição)
		_cQuery += " AND Z16_ENDATU NOT IN (
		_cQuery += " SELECT Z08_ENDDES AS 'END'   "
		_cQuery += " FROM  " + RetSqlTab("Z08") + " (NOLOCK)"
		_cQuery += " WHERE " + RetSqlCond("Z08")
		_cQuery += "  AND Z08_LOCAL = Z16_LOCAL"
		_cQuery += "  AND Z08_STATUS != 'R' "
		_cQuery += "  AND Z08_PRODUT = BF_PRODUTO "
		_cQuery += "  AND Z08_TPOPER != 'S' "
		_cQuery += " UNION ALL                    "
		_cQuery += " SELECT Z08_ENDORI AS 'END'   "
		_cQuery += " FROM  " + RetSqlTab("Z08") + " (NOLOCK)"
		_cQuery += " WHERE " + RetSqlCond("Z08")
		_cQuery += "  AND Z08_LOCAL = Z16_LOCAL  "
		_cQuery += "  AND Z08_PRODUT = BF_PRODUTO  "
		_cQuery += "  AND Z08_STATUS != 'R' "
		_cQuery += "  AND Z08_TPOPER != 'S') "

		// se controlar lote, ele vai pegar os endereços já estipulados no Z45 para o pedido informado
		If ( _lLotAtivo )
			If ( ! _lLotObrSai )
				_cQuery += "                AND Z16_ETQPAL IN (SELECT Z45_ETQPAL FROM "+RetSqlTab("Z45")+" (NOLOCK) WHERE "+RetSqlCond("Z45")+" AND Z45_PEDIDO IN "+FormatIn(_cNumPed,"/")+" ) "
			ElseIf ( _lLotObrSai ) .And. ( ! _lVolJaDef )
				_cQuery += "                AND Z16_LOTCTL = '" + mvLote + "' "
			EndIf
		Else
			// quando não controlar o lote, só busca pelos pallets que não possuem lote
			_cQuery += "                AND Z16_LOTCTL = ' ' "
		EndIf

		// quando os volumes ja foram definidos/selecionados no pedido de venda
		If ( _lVolJaDef )
			_cQuery += "                INNER JOIN " + RetSqlTab("Z45") + " (NOLOCK) "
			_cQuery += "                        ON " + RetSqlCond("Z45")
			_cQuery += "                           AND Z45_ETQPAL = Z16_ETQPAL "
			_cQuery += "                           AND Z45_CODPRO = Z16_CODPRO "
			_cQuery += "                           AND Z45_LOTCTL = Z16_LOTCTL "
			_cQuery += "                           AND Z16_ETQVOL = Z45_ETQVOL "
			_cQuery += "                           AND Z45_PEDIDO IN "+FormatIn(_cNumPed,"/")
		EndIf

		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("SBF")
		// produto
		_cQuery += " AND BF_PRODUTO = '"+mvProduto+"' "
		// quanto nao expede em kit, pega de varias estruturas fisiscas
		If ( ! _lExpEmKit )
			_cQuery += " AND BF_ESTFIS IN "+FormatIn(_cEstFisMapa,"/")+" "
			// quando controla volume, so expede produto unitario quanto for Picking
		ElseIf (_lExpEmKit)
			_cQuery += " AND BF_ESTFIS IN "+FormatIn(_cEstPicking,"/")+" "
		EndIf

		// filtra estrutura fisica
		If (_cTipoBusca == "1") // 1-Palete Completo
			_cQuery += " AND BF_ESTFIS IN ('000002', '000003', '000007') "
		ElseIf (_cTipoBusca == "2") // 2-Palete Fracionado
			_cQuery += " AND BF_ESTFIS IN ('000007', '000010') "
		EndIf

		// controla saldo de enderecos que estao no plano de expedicao
		_cQuery += " AND BF_QUANT > (SELECT ISNULL(SUM(Z08_QUANT),0) FROM " + RetSqlTab("Z08") + " (NOLOCK) "
		// somente OS que NAO movimentou estoque (Z06_ATUEST = 'S' - deve atualizar estoque na movimentacao fisica da carga)
		_cQuery += " INNER JOIN "+RetSqlTab("Z06")+" (NOLOCK) ON "+RetSqlCond("Z06")+" AND Z06_NUMOS = Z08_NUMOS AND Z06_SEQOS = Z08_SEQOS "
		_cQuery += " AND Z06_ATUEST = 'S' "
		// filtro padrao do mapa
		_cQuery += " WHERE "+RetSqlCond("Z08")
		_cQuery += " AND Z08_STATUS IN ('P','M') AND Z08_LOCAL = BF_LOCAL "
		_cQuery += " AND Z08_ENDORI = BF_LOCALIZ "
		_cQuery += " AND Z08_PRODUT = BF_PRODUTO) "

		// descarta armazem A3
		_cQuery += " AND BF_LOCAL NOT IN ('A3') "

		// armazem padrao do cliente
		_cQuery += " AND BF_LOCAL = '" +mvArmzPadrao+ "' "

		// agrupa os dados
		_cQuery += "GROUP  BY BF_PRODUTO, "
		_cQuery += "          BF_LOCAL, "
		_cQuery += "          BF_LOCALIZ, "
		_cQuery += "          BF_QUANT, "
		_cQuery += "          Z16_ETQPAL, "
		_cQuery += "          Z16_LOTCTL, "
		_cQuery += "          BF_ESTFIS "
		// se controla número de série
		IF (_lSerieAtv)
			_cQuery += " ,Z16_DTSERI "
		EndIf
		// controle do tipo de busca
		// 1-Palete Completo
		// 2-Palete Fracionado
		// 3-Palete com Qualquer Quantidade
		If (_cTipoBusca == "1") // 1-Palete Completo
			If (_lEtqIdInt)
				_cQuery += " HAVING Sum(Z16_SALDO) = "+AllTrim(Str(_nVolMaxPlt))+" "
			ElseIf (_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIDDun)
				_cQuery += " HAVING Sum(Z16_SALDO) = "+AllTrim(Str(_nVolMaxPlt))+" "
			EndIf
		ElseIf (_cTipoBusca == "2") // 2-Palete Fracionado
			If (_lEtqIdInt)
				_cQuery += " HAVING Sum(Z16_SALDO) != "+AllTrim(Str(_nVolMaxPlt))+" "
			ElseIf (_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIDDun)
				_cQuery += " HAVING Sum(Z16_SALDO) != "+AllTrim(Str(_nVolMaxPlt))+" "
			EndIf
		EndIf

		// fecha sub-query
		_cQuery += ") AS PALETES_DISPONIVEIS "

		// apenas endereços não bloqueados
		_cQuery += " WHERE (SELECT BE_STATUS "
		_cQuery += "            FROM   " + RetSqlName("SBE") + " SBE (NOLOCK) "
		_cQuery += "            WHERE  SBE.BE_FILIAL = '" + xFilial("SBE") + "'"
		_cQuery += "                  AND SBE.D_E_L_E_T_ = '' "
		_cQuery += "                  AND SBE.BE_LOCAL = PALETES_DISPONIVEIS.BF_LOCAL "
		_cQuery += "                  AND SBE.BE_LOCALIZ = PALETES_DISPONIVEIS.BF_LOCALIZ) != 3 "

		// para cliente com controle de volumes, valida se expede em kit/agrupadora
		If (_lCtrVolume) .And. ( ! _lExpEmKit )
			_cQuery += " AND QTD_SKU = 1 "
		EndIf

		// se contola número de série pega a range de data de número de série conforme parâmetro TC_LIMISER
		If ( _lSerieAtv )
			_cQuery += " AND DIF_DATA <= " + cValToChar(_nRangeDt)
		Endif

		// ordem do endereco de busca
		_cQuery += " ORDER  BY CASE "
		_cQuery += "             WHEN BF_ESTFIS = '000010' THEN 100 "
		_cQuery += "             ELSE 0 "
		_cQuery += "           END DESC, "
		// se controla número de série
		IF (_lSerieAtv)
			_cQuery += " Z16_DTSERI " + sfOrdSer(_cNumPed) +" ,"
		EndIf
		_cQuery += "           " + _cQryOrdPlt + ", "
		_cQuery += "           Substring(BF_LOCALIZ, 1, 2), "
		_cQuery += "           Substring(BF_LOCALIZ, 4, 2), "
		_cQuery += "           Substring(BF_LOCALIZ, 3, 1), "
		_cQuery += "           Substring(BF_LOCALIZ, 8, 5), "
		_cQuery += "           Substring(BF_LOCALIZ, 6, 2) "

		memowrit("c:\query\twmsa019_sfMontaMapa_3_tpbusca_"+_cTipoBusca+"_todos_enderecos.txt",_cQuery)

		// verifica se o alias esta em uso
		If (Select(_cAlQry) > 0)
			dbSelectArea(_cAlQry)
			dbCloseArea()
		EndIf

		// executa o select
		DbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),(_cAlQry),.F.,.T.)
		(_cAlQry)->(dbGoTop())

		//abre tabelas necessárias
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ

		// varre todos os enderecos
		While (_cAlQry)->( ! Eof() ) .And. (_lNovaBusca)

			// zera variavel
			_nQtdSelec  := 0
			_nQtdSegum  := 0
			_cFracPlt   := "N"
			_cIdPalete  := (_cAlQry)->Z16_ETQPAL
			_cLoteCTL   := (_cAlQry)->Z16_LOTCTL
			_cArmzAtual := (_cAlQry)->BF_LOCAL
			_cEndAtual  := (_cAlQry)->BF_LOCALIZ
			_nSldPltAtu := (_cAlQry)->Z16_SALDO
			_nSaldoEnd  := (_cAlQry)->BF_QUANT

			// para os casos de enderecos em bloco, define a quantidade do endereco de acordo com o saldo do palete
			If ( (_cAlQry)->DC8_TPESTR  $ "4/5/7") .Or. (_lVolJaDef)
				_nSaldoEnd := _nSldPltAtu
			EndIf

			// verifica se o endereco ja foi utilizado em outro item

			// estrutura _aMapaApanhe
			//  1-cod produto
			//  2-local/armazem
			//  3-end retirada
			//  4-quant
			//  5-end destino
			//  6-ID palete
			//  7-fraciona palete
			//  8-serie nota orig
			//  9-nota orig
			// 10-item nota orig
			// 11-sequencial
			// 12-numseq
			// 13-id volume
			// 14-Lote
			// 15-Tipo de Estoque
			// 16-Quantidade Seg Unid

			// zera conteudo
			_nSldJaUti := 0
			// calcula saldo ja utilizado no endereco e palete
			aEval(_aMapaApanhe,{|x| _nSldJaUti += IIf((x[1] == mvProduto) .And. (x[2] == _cArmzAtual) .And. (x[3] == _cEndAtual) .And. (x[6] == _cIdPalete) .And. (x[14] == _cLoteCTL), x[4], 0) })

			// reduz o saldo do endereco ja utilizado
			If (_nSldJaUti != 0)
				_nSaldoEnd -= _nSldJaUti
			EndIf

			// verifica o saldo no endereco
			If (_nSaldoEnd <= 0)
				// proximo endereco
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// verifica o saldo no palete, desconsiderando o saldo ja reservado
			// dados para retorno
			// 1-Id Palete
			// 2-Local/Armazem
			// 3-Endereco Atual
			// 4-Etq Produto
			// 5-Etq Volume
			// 6-Cod Produto
			// 7-Saldo Atual (Z16)
			// 8-Saldo Reservado (Z08)
			// 9-Saldo Disponivel (Z16 - Z08)
			_aSaldoPlt := U_FtSldPlt(_cIdPalete,;
			Nil       ,;
			Nil       ,;
			mvProduto ,;
			.F.       ,;
			.F.       ,;
			_cLoteCTL  )

			// reduz o saldo do endereco ja utilizado em outro mapa
			If (Len(_aSaldoPlt) > 0) .And. ( ! _lVolJaDef )
				_nSaldoEnd -= _aSaldoPlt[1][8]
			EndIf

			// e então verifica se ainda existe saldo no endereco
			If (_nSaldoEnd <= 0)
				// proximo endereco
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// controle do tipo de busca
			// 1-Palete Completo
			// 2-Palete Fracionado
			// 3-Palete com Qualquer Quantidade
			If (_cTipoBusca == "1") // 1-Palete Completo
				If (_nSaldoEnd != _nVolMaxPlt)
					// proximo endereco
					(_cAlQry)->(dbSkip())
					Loop
				EndIf
			ElseIf (_cTipoBusca == "2") // 2-Palete Fracionado
				If (_nSaldoEnd == _nVolMaxPlt)
					// proximo endereco
					(_cAlQry)->(dbSkip())
					Loop
				EndIf
			EndIf

			// distinção para controle de saldo
			If (_lUsaSldPlt) .Or. (_cTipoBusca == "1") // 1-Palete Completo
				_nQtdSelec := _nSaldoEnd
				_cFracPlt  := "N"

			ElseIf ( ! _lUsaSldPlt ) .And. (_cTipoBusca != "1") // 1-Palete Completo
				// controle de saldo
				If (_nSaldoEnd <= _nSaldoApanhe)
					_nQtdSelec := _nSaldoEnd
					_cFracPlt  := "N"
				ElseIf (_nSaldoEnd > _nSaldoApanhe)
					_nQtdSelec := _nSaldoApanhe
					_cFracPlt  := "S"
				EndIf
			EndIf

			// define a quantidade da segunda unidade de medida
			If (_lCtrVolume) .And. (SB1->B1_CONV == 0) .And. (_lVolJaDef)
				_nQtdSegum := (_cAlQry)->Z16_QTSEGU
			EndIf

			// posiciona no endereço SBE para verificar se existe
			SBE->( dbSeek( xFilial("SBE") + _cArmzAtual + _cEndAtual ) )

			//testa se ja esta bloqueado
			If ( ! SBE->( MsRLock()) )
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// tenta bloquear o endereço
			If ( ! SoftLock("SBE") )
				//proximo registro
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// adiciona RECNO para controle
			Aadd(_aRegLock, {"SBE", SBE->( RecNo() )} )

			// inclui o endereco
			(_cAlTrb2)->(dbSelectArea(_cAlTrb2))
			(_cAlTrb2)->(RecLock(_cAlTrb2,.T.))
			(_cAlTrb2)->ET2_COR    := "OK"
			(_cAlTrb2)->ET2_ORIG   := "SBF"
			(_cAlTrb2)->ET2_PROD   := mvProduto
			(_cAlTrb2)->ET2_ENDORI := _cEndAtual
			(_cAlTrb2)->ET2_SALDO  := _nSaldoEnd
			(_cAlTrb2)->ET2_QUANT  := _nQtdSelec
			(_cAlTrb2)->ET2_QTSEGU += ConvUM(mvProduto, _nQtdSelec, _nQtdSegum, 2)
			(_cAlTrb2)->ET2_SERORI := mvSerie
			(_cAlTrb2)->ET2_NFORI  := mvNota
			(_cAlTrb2)->ET2_ITEORI := mvItem
			(_cAlTrb2)->ET2_SEQ    := mvCntrlSeq
			(_cAlTrb2)->ET2_NUMSEQ := mvNumSeq
			(_cAlTrb2)->ET2_QRY    := "3"
			(_cAlTrb2)->ET2_TPBUSC := _cTipoBusca
			(_cAlTrb2)->ET2_LOTCTL := _cLoteCTL
			(_cAlTrb2)->ET2_TPESTO := mvTipEsto
			(_cAlTrb2)->ET2_ETQPAL := _cIdPalete
			(_cAlTrb2)->(MsUnLock())

			// atualiza o saldo do pedido
			(_cAlTrbSC6)->(dbSelectArea(_cAlTrbSC6))
			(_cAlTrbSC6)->(RecLock(_cAlTrbSC6))
			(_cAlTrbSC6)->C6_SALDO -= _nQtdSelec
			(_cAlTrbSC6)->(MsUnLock())

			// atualiza o saldo
			_nSaldoApanhe -= _nQtdSelec

			// inclui o endereco selecionado
			(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
			(_cAlTrbMov)->(dbSetOrder(1))
			If (_cAlTrbMov)->(dbSeek( mvProduto + _cArmzAtual + _cEndAtual + _cIdPalete + _cLoteCTL ))
				(_cAlTrbMov)->(RecLock(_cAlTrbMov))
				(_cAlTrbMov)->MOV_QUANT  += _nQtdSelec
				(_cAlTrbMov)->MOV_FRAPLT := If( (_cAlTrbMov)->MOV_QUANT < (_cAlTrbMov)->MOV_SLDEND ,"S","N")
				(_cAlTrbMov)->MOV_QTSEGU += ConvUM(mvProduto, _nQtdSelec, _nQtdSegum, 2)
				(_cAlTrbMov)->(MsUnLock())
			Else
				(_cAlTrbMov)->(RecLock(_cAlTrbMov,.T.))
				(_cAlTrbMov)->MOV_PROD   := mvProduto
				(_cAlTrbMov)->MOV_LOCAL  := _cArmzAtual
				(_cAlTrbMov)->MOV_ENDORI := _cEndAtual
				(_cAlTrbMov)->MOV_QUANT  := _nQtdSelec
				(_cAlTrbMov)->MOV_QTSEGU := ConvUM(mvProduto, _nQtdSelec, _nQtdSegum, 2)
				(_cAlTrbMov)->MOV_ENDDES := _cEndDest
				(_cAlTrbMov)->MOV_PALETE := _cIdPalete
				(_cAlTrbMov)->MOV_FRAPLT := _cFracPlt
				(_cAlTrbMov)->MOV_CARGA  := _cNumCarga
				(_cAlTrbMov)->MOV_SERORI := mvSerie
				(_cAlTrbMov)->MOV_NFORI  := mvNota
				(_cAlTrbMov)->MOV_ITEORI := mvItem
				(_cAlTrbMov)->MOV_NUMSEQ := mvNumSeq
				(_cAlTrbMov)->MOV_SEQ    := mvCntrlSeq
				(_cAlTrbMov)->MOV_VOLUME := ""
				(_cAlTrbMov)->MOV_LOTCTL := _cLoteCTL
				(_cAlTrbMov)->MOV_TPESTO := mvTipEsto
				(_cAlTrbMov)->(MsUnLock())

				// controle da sequencia
				mvCntrlSeq := Soma1(mvCntrlSeq)

			EndIf

			// estrutura _aMapaApanhe
			//  1-cod produto
			//  2-local/armazem
			//  3-end retirada
			//  4-quant
			//  5-end destino
			//  6-ID palete
			//  7-fraciona palete
			//  8-serie nota orig
			//  9-nota orig
			// 10-item nota orig
			// 11-sequencial
			// 12-numseq
			// 13-id volume
			// 14-Lote
			// 15-Tipo de Estoque
			// 16-Quantidade Seg Unid

			// verifica se o endereco ja foi utilizado em outro item, considerando o palete

			_nPosReserv := aScan(_aMapaApanhe,{|x| (x[1] == mvProduto) .And. (x[2] == _cArmzAtual) .And. (x[3] == _cEndAtual) .And. (x[6] == _cIdPalete) .And. (x[14] == _cLoteCTL) })

			// adiciona os detalhes no mapa de apanhe (utilizado na U_WMSA009B)
			If (_nPosReserv > 0)
				_aMapaApanhe[_nPosReserv][ 4] := (_cAlTrbMov)->MOV_QUANT
				_aMapaApanhe[_nPosReserv][ 7] := (_cAlTrbMov)->MOV_FRAPLT
				_aMapaApanhe[_nPosReserv][16] := (_cAlTrbMov)->MOV_QTSEGU
			Else
				aAdd(_aMapaApanhe,{(_cAlTrbMov)->MOV_PROD  , ;
				(_cAlTrbMov)->MOV_LOCAL , ;
				(_cAlTrbMov)->MOV_ENDORI, ;
				(_cAlTrbMov)->MOV_QUANT , ;
				(_cAlTrbMov)->MOV_ENDDES, ;
				(_cAlTrbMov)->MOV_PALETE, ;
				(_cAlTrbMov)->MOV_FRAPLT, ;
				(_cAlTrbMov)->MOV_SERORI, ;
				(_cAlTrbMov)->MOV_NFORI , ;
				(_cAlTrbMov)->MOV_ITEORI, ;
				(_cAlTrbMov)->MOV_SEQ   , ;
				(_cAlTrbMov)->MOV_NUMSEQ, ;
				(_cAlTrbMov)->MOV_VOLUME, ;
				(_cAlTrbMov)->MOV_LOTCTL, ;
				(_cAlTrbMov)->MOV_TPESTO ,;
				(_cAlTrbMov)->MOV_QTSEGU })

			EndIf

			// define nova busca
			_lNovaBusca := (_nSaldoApanhe > 0)

			// controle se deve mudar a busca, de palete completo para fracionado, quando sobrar saldo
			_lMudaBusca := .F.

			// verifica se deve mudar a busca
			If (_lNovaBusca) .And. (_cTipoBusca == "1") .And. (_nSaldoApanhe < _nVolMaxPlt)
				_lMudaBusca := .T.
			EndIf

			// verifica se deve mudar a logica de busca
			If (_lNovaBusca) .And. (_cTipoBusca == "1") .And. (_lMudaBusca)
				// sai do While de Enderecos
				Exit
			EndIf

			// proximo endereco
			(_cAlQry)->(dbSkip())
		EndDo

		// controle do tipo de busca
		// 1-Palete Completo
		// 2-Palete Fracionado
		// 3-Palete com Qualquer Quantidade
		_cTipoBusca := Soma1(_cTipoBusca)

		// encerra buscas
		If (_cTipoBusca == "4")
			_lNovaBusca := .F.
		EndIf

	EndDo

	// atualiza varivel de retorno
	_lRet := (_nSaldoApanhe==0)

	// atualiza Log
	If ( ! _lRet )
		If ( ! Empty(mvSerie))
			_cLogMapa += "Série/Nota/Item: "+mvSerie+"/"+mvNota+"/"+mvItem+CRLF
		EndIf
		_cLogMapa += "Produto: "+AllTrim(mvProduto)+"-"+AllTrim(Posicione("SB1",1,xFilial("SB1")+mvProduto,"B1_DESC"))+" -- "
		_cLogMapa += "Qtd Solic.: "+AllTrim(Str(mvQuant))+" / "
		_cLogMapa += "Falta: "+AllTrim(Str(_nSaldoApanhe))+CRLF
	EndIf

Return(_lRet)

// ** funcao para filtrar os dados
Static Function sfFiltraEnd(mvSerie, mvNota, mvItem, mvCodProd, mvTpEstoq, mvBrwDisp1, mvBrwDisp2, mvBrwDisp3)

	// filtra enderecos COM etiquetas
	(_cAlTrb1)->(dbSelectArea(_cAlTrb1))
	(_cAlTrb1)->(DbGoTop())
	If (_cAlTrb1)->(!EOF())
		(_cAlTrb1)->(IndRegua((_cAlTrb1),(_cTrbEnd1),"ET1_PROD",,;
		(_cAlTrb1)+'->ET1_SERORI == "'+mvSerie+'" .And. '+;
		(_cAlTrb1)+'->ET1_NFORI  == "'+mvNota+'" .And. '+;
		(_cAlTrb1)+'->ET1_ITEORI == "'+mvItem+'" .And. '+;
		(_cAlTrb1)+'->ET1_PROD   == "'+mvCodProd+'" .And. '+;
		(_cAlTrb1)+'->ET1_TPESTO == "'+mvTpEstoq+'"',;
		"Selecionando Registros..."))
	EndIf

	// atualiza browse
	mvBrwDisp1:oBrowse:Refresh()

	// filtra enderecos SEM etiquetas
	(_cAlTrb2)->(dbSelectArea(_cAlTrb2))
	(_cAlTrb2)->(DbGoTop())
	If (_cAlTrb2)->(!EOF())
		(_cAlTrb2)->(IndRegua((_cAlTrb2),(_cTrbEnd2),"ET2_PROD",,;
		(_cAlTrb2)+'->ET2_SERORI == "'+mvSerie+'"   .And. '+;
		(_cAlTrb2)+'->ET2_NFORI  == "'+mvNota+'" .And. '+;
		(_cAlTrb2)+'->ET2_ITEORI == "'+mvItem+'" .And. '+;
		(_cAlTrb2)+'->ET2_PROD   == "'+mvCodProd+'" .And. '+;
		(_cAlTrb2)+'->ET2_TPESTO == "'+mvTpEstoq+'"',;
		"Selecionando Registros..."))
	EndIf

	// atualiza browse
	mvBrwDisp2:oBrowse:Refresh()

	// filtra enderecos AGRUPADORAS
	(_cAlTrb3)->(dbSelectArea(_cAlTrb3))
	(_cAlTrb3)->(DbGoTop())
	If (_cAlTrb3)->(!EOF())
		(_cAlTrb3)->(IndRegua((_cAlTrb3),(_cTrbEnd3),"ET3_PROD",,;
		(_cAlTrb3)+'->ET3_PROD   == "'+mvCodProd+'" .And. '+;
		(_cAlTrb3)+'->ET3_TPESTO == "'+mvTpEstoq+'"',;
		"Selecionando Registros..."))
	EndIf

	// atualiza browse
	mvBrwDisp3:oBrowse:Refresh()

Return

//** funcao para impressao do mapa de apanhe/expedicao
User Function WMSA019A(mvCarga, mvMapaApanhe, mvOndaSep)
	// variavel temporaria
	local _nResto
	local _nTmp
	local _nTmpTotal := 0
	local _nPosRes
	local _nPosRua
	// total de paletes fracionados
	local _nTotPltFra := 0

	// valores padroes
	Default mvCarga      := CriaVar("DAK_COD"   , .F.)
	Default mvMapaApanhe := {}
	Default mvOndaSep    := CriaVar("Z57_CODIGO", .F.)

	// fontes
	private _oFont01 := TFont():New("Arial Narrow",,13,,.F.,,,,,.F.)
	private _oFont02 := TFont():New("Arial Narrow",,13,,.T.,,,,,.F.)
	Private _oFont03 := TFont():New("Arial",,13,,.T.,,,,,.F.)

	Private oFnt22	:= TFont():New("Arial",,14,,.F.,,,,,.F.)
	Private oFnt16n	:= TFont():New("Arial",,16,,.T.,,,,,.F.)

	// parametros utilizados no relatorio
	Private _nQtdTotPag := 0  // Qdt de Paginas
	Private _nPagAtu    := 0  // Pagina Atual
	Private _nMaxItePag := 47 // Numero Maximos de Itens (Linhas) por Paginas
	Private _nLin       := 0  // controle de impressao da linha
	// posicao atual do vetor: mvMapaApanhe
	private _nPosAtuVet := 1
	// posicao atual do vetor: _aResumo
	private _nPosAtuRes := 1

	// objeto de impressao
	private _oPrnMapa

	// local/armazem
	private _cCodArzm

	// rua atual
	private _cRuaAtual := ""

	// predio atual
	private _cPreAtual := ""

	// lado atual
	private _cLadoAtual := ""

	// endereco de destino
	private _cEndDestino

	// totalizados e resumo
	// 1-Cod produto
	// 2-Quant do produto
	// 3-Quant de Palete
	private _aResumo := {}

	// total de palete por rua
	// 1-rua
	// 2-Quant de Palete
	private _aTotRua := {}

	// total geral
	private _nTotProdut := 0
	private _nTotPalete := 0

	// define origem dos dados
	private _lPorCarga := ((_cNumCarga != Nil) .And. ( ! Empty(_cNumCarga) ))
	private _lPorOnda  := ((_cNrOndSep != Nil) .And. ( ! Empty(_cNrOndSep) ))

	// valida a quantidade de itens
	If (Len(mvMapaApanhe)==0)
		MsgStop("Não há dados para impressão!")
		Return(.F.)
	EndIf

	// estrutura _aMapaApanhe
	//  1-cod produto
	//  2-local/armazem
	//  3-end retirada
	//  4-quant
	//  5-end destino
	//  6-ID palete
	//  7-fraciona palete
	//  8-serie nota orig
	//  9-nota orig
	// 10-item nota orig
	// 11-sequencial
	// 12-numseq
	// 13-id volume
	// 14-Lote
	// 15-Tipo de Estoque
	// 16-Quantidade Seg Unid

	// organiza os dados por (rua, predio, lado, posicao, andar)
	aSort(mvMapaApanhe,,,{|x,y| ( SubStr(x[3],1,2)+SubStr(x[3],4,2)+SubStr(x[3],3,1)+SubStr(x[3],8,5)+SubStr(x[3],6,2) ) < ( SubStr(y[3],1,2)+SubStr(y[3],4,2)+SubStr(y[3],3,1)+SubStr(y[3],8,5)+SubStr(y[3],6,2) )})

	// atualiza local/armazem
	_cCodArzm := mvMapaApanhe[1][2]

	// endereco de destino
	_cEndDestino := mvMapaApanhe[1][5]

	//Cria Objeto para impressao Grafica
	_oPrnMapa := TMSPrinter():New("Expedição de Mercadoria - " + IIf(_lPorCarga, "Nr. Carga: " + mvCarga, "Nr. Onda: " + mvOndaSep))

	// chama a rotina de Configuracao da impressao
	_oPrnMapa:Setup()
	_oPrnMapa:SetPortrait()

	// calcula a quantidade de quebras por rua e predio
	For _nTmp := 1 to Len(mvMapaApanhe)
		// quebra rua atual
		If (_cRuaAtual != SubStr(mvMapaApanhe[_nTmp][3],1,2))
			// atualiza controle de quebra
			_cRuaAtual := SubStr(mvMapaApanhe[_nTmp][3],1,2)
			_cPreAtual := ""
			// contador
			_nTmpTotal += 1
		EndIf

		// quebra predio atual
		If (_cPreAtual != SubStr(mvMapaApanhe[_nTmp][3],4,2))
			// atualiza controle de quebra
			_cPreAtual := SubStr(mvMapaApanhe[_nTmp][3],4,2)
			// contador
			_nTmpTotal += 1
		EndIf
		// contador
		_nTmpTotal += 1

		// totalizados e resumo
		// estrutura: _aResumo
		// 1-Cod produto
		// 2-Quant do produto
		// 3-Quant de Palete

		// verifica se o produto ja esta na relacao
		_nPosRes := aScan(_aResumo,{|x| x[1] == mvMapaApanhe[_nTmp][1] })

		// inclui novo registro
		If (_nPosRes == 0)
			aAdd(_aResumo,{mvMapaApanhe[_nTmp][1],;
			mvMapaApanhe[_nTmp][4],;
			1 })
			// atualiza total
		ElseIf (_nPosRes > 0)
			// total do produto
			_aResumo[_nPosRes][2] += mvMapaApanhe[_nTmp][4]
			// total de palete
			_aResumo[_nPosRes][3] += 1

		EndIf

		// total geral
		_nTotProdut += mvMapaApanhe[_nTmp][4]
		_nTotPalete += 1

		// total de paletes fracionados
		If (mvMapaApanhe[_nTmp][7] == "S")
			_nTotPltFra += 1
		EndIf

		// total de palete por rua
		// 1-rua
		// 2-Quant de Palete

		// verifica se a rua ja esta na relacao
		_nPosRua := aScan(_aTotRua,{|x| x[1] == _cRuaAtual })

		// inclui novo registro
		If (_nPosRua == 0)
			aAdd(_aTotRua,{_cRuaAtual,;
			1 })
			// atualiza total
		ElseIf (_nPosRua > 0)
			// total de palete por rua
			_aTotRua[_nPosRua][2] += 1

		EndIf

	Next _nTmp

	// incremente as linhas do total
	_nTmpTotal += 2
	_nTmpTotal += Len(_aResumo)
	// incrementa linha de total de paletes fracionados
	If (_nTotPltFra > 0)
		_nTmpTotal += 1
	EndIf

	// reinicia variaveis
	_cRuaAtual := ""
	_cPreAtual := ""

	// calcula a Quatidade de Paginas
	_nQtdTotPag	:= Int(_nTmpTotal/_nMaxItePag)
	_nResto     := Mod(_nTmpTotal,_nMaxItePag)
	// quebra de paginas
	If (_nResto > 0)
		_nQtdTotPag ++
	EndIf

	// impressao de todas as paginas
	For _nPagAtu := 1 to _nQtdTotPag

		// cria nova Pagina
		_oPrnMapa:StartPage()
		// impressao do Cabecalho
		sfImpCabec(mvCarga, mvOndaSep)
		// impressao do Itens (Detalhes)
		sfImpItens(mvMapaApanhe)
		// impressao do rodape
		If (_nPagAtu == _nQtdTotPag) .And. (_nPosAtuVet >= Len(mvMapaApanhe))
			sfImpRodape(_nTotPltFra)
		EndIf

		// finaliza a Pagina
		_oPrnMapa:EndPage()

	Next _nPagAtu

	// preview dos dados
	_oPrnMapa:Preview()

Return

//** funcao para impressao de Cabecalho
Static Function sfImpCabec(mvCarga, mvOndaSep)

	local _cNumOS := IIf(_lPorCarga, POSICIONE("Z05" , 4, xFilial("Z05") + mvCarga  , "Z05_NUMOS"), POSICIONE("Z05" , 5, xFilial("Z05") + mvOndaSep  , "Z05_NUMOS"))

	// primeiro quadro
	_oPrnMapa:Box(0060,0100,0180,2300)
	_oPrnMapa:Say(0100,0110,"Expedição de Mercadoria - " + IIf(_lPorCarga, "Nr. Carga: " + mvCarga, "Nr. Onda: " + mvOndaSep),oFnt22,100)
	_oPrnMapa:Say(0070,1300,"Início: " + DtoC(Date()) + " Hr: " + Time(),_oFont01,100,,,)
	_oPrnMapa:Say(0125,1300,"Finalizado: ____/____/____ -  Hr: ____:_____",_oFont01,100,,,0)
	_oPrnMapa:Say(0070,2280,"OS: " + _cNumOs ,_oFont01,100,,,1)
	_oPrnMapa:Say(0125,2280,"Pg: " + AllTrim(Str(_nPagAtu,3)) + " de " + AllTrim(Str(_nQtdTotPag,3)),_oFont01,100,,,1)

	// segundo quadro (dados da nota fiscal)
	_oPrnMapa:Box(0200,0100,0400,2300)

	// endereco de destino
	_oPrnMapa:Say(0320,0110,"DOCA DESTINO: " + _cEndDestino,oFnt16n,100)

	// dados do cliente
	//_oPrnMapa:Say(0270,0120,"Cliente: "+cCodCliFor+"/"+cLojCliFor+"-"+Posicione("SA1",1,xFilial("SA1")+cCodCliFor+cLojCliFor,"A1_NOME"),_oFont01,100)
	_oPrnMapa:Say(0320,2260,"ARMAZÉM: " + _cCodArzm,oFnt16n,100,,,1)

	// cabecalhos dos itens
	_oPrnMapa:Box(0420,0100,0480,2300)
	// endereco de origem
	_oPrnMapa:Say(0430,0200,"END. ORIGEM",_oFont02,100)
	// quantidade
	_oPrnMapa:Say(0430,0840,"QUANT.",_oFont02,100,,,1)
	// produto
	_oPrnMapa:Say(0430,0900,"PRODUTO",_oFont02,100)
	// fracionar
	_oPrnMapa:Say(0430,2000,"OBSERVAÇÃO",_oFont02,100)

Return

//Funcao Responsavel pela Impressao dos Itens
Static Function sfImpItens(mvMapaApanhe)
	// variaveis temporarias
	local _nPosRua

	// controle de linhas por pagina
	local _nLinAtu := 1

	// objeto utilizado para criar um retangulo
	local _oBrush1 := TBrush():New(,CLR_LIGHTGRAY)

	// decricao do produto
	local _cPrdDesc

	// reinicia posicao da linha
	_nLin := 500

	//While _QRYZ08->(!Eof()).And..And.(cCodArzm==_QRYZ08->Z08_LOCAL)
	While (_nPosAtuVet <= Len(mvMapaApanhe)) .And. (_nLinAtu <= _nMaxItePag)

		// estrutura _aMapaApanhe
		//  1-cod produto
		//  2-local/armazem
		//  3-end retirada
		//  4-quant
		//  5-end destino
		//  6-ID palete
		//  7-fraciona palete
		//  8-serie nota origs
		//  9-nota orig
		// 10-item nota orig
		// 11-sequencial
		// 12-numseq
		// 13-id volume
		// 14-Lote
		// 15-Tipo de Estoque
		// 16-Quantidade Seg Unid

		// quebra rua atual
		If (_cRuaAtual != SubStr(mvMapaApanhe[_nPosAtuVet][3],1,2))
			// atualiza controle de quebra
			_cRuaAtual  := SubStr(mvMapaApanhe[_nPosAtuVet][3],1,2)
			_cPreAtual  := ""
			_cLadoAtual := ""
			// cria um retangulo escuro no fundo da palavra
			_oPrnMapa:FillRect({_nLin+10, 0100,_nLin+60, 2300}, _oBrush1 )
			// imprime os dados da rua
			_oPrnMapa:Say(_nLin+10,0110,"RUA:  "+_cRuaAtual,_oFont02,100)//,CLR_WHITE)
			// total de palete por rua
			_nPosRua := aScan(_aTotRua,{|x| x[1] == _cRuaAtual })
			_oPrnMapa:Say(_nLin+10,0840,Transf(_aTotRua[_nPosRua][2],"@E 9999")+"  PALETES",_oFont02,100,,,1)
			// controle da linha
			_nLin += 50
			// controle da linha por pagina
			_nLinAtu ++
		EndIf

		// quebra predio atual
		If (_cPreAtual != SubStr(mvMapaApanhe[_nPosAtuVet][3],4,2))
			// atualiza controle de quebra
			_cPreAtual  := SubStr(mvMapaApanhe[_nPosAtuVet][3],4,2)
			_cLadoAtual := ""
			// imprime os dados da rua
			_oPrnMapa:Say(_nLin+10,0160,"PRÉDIO:  "+_cPreAtual,_oFont02,100)
			// controle da linha
			_nLin += 50
			// controle da linha por pagina
			_nLinAtu ++
		EndIf

		// controle do identificador do lado
		If (_cLadoAtual != SubStr(mvMapaApanhe[_nPosAtuVet][3],3,1))
			// atualiza controle de quebra
			_cLadoAtual := SubStr(mvMapaApanhe[_nPosAtuVet][3],3,1)
			// endereco de origem
			//_oPrnMapa:Say(_nLin+10,0110,"==>>",_oFont01,100)
		EndIf

		// endereco de origem
		_oPrnMapa:Say(_nLin+10,0200,Transf(mvMapaApanhe[_nPosAtuVet][3], PesqPict("SBF","BF_LOCALIZ") ),_oFont03,100)

		// descricao do produto
		_cPrdDesc := AllTrim(Posicione("SB1",1,xFilial("SB1")+mvMapaApanhe[_nPosAtuVet][1],"B1_DESC"))

		// quantidade
		_oPrnMapa:Say(_nLin+10,0840,Transf(mvMapaApanhe[_nPosAtuVet][4],PesqPict("SC6","C6_QTDVEN")),_oFont01,100,,,1)

		// codigo do produto
		_oPrnMapa:Say(_nLin+10,0900,AllTrim(mvMapaApanhe[_nPosAtuVet][1])+" - "+_cPrdDesc,_oFont01,100)

		// observacao
		If (mvMapaApanhe[_nPosAtuVet][7]=="S")
			_oPrnMapa:Say(_nLin+10,2000,"PLT PARCIAL",_oFont01,100)
		EndIf

		// controle da linha
		_nLin += 50

		// controle do item do vetor
		_nPosAtuVet += 1

		// controle da linha por pagina
		_nLinAtu ++

	EndDo

Return

//** funcao Responsavel pela Impressao do rodape com o resumo
Static Function sfImpRodape(mvTotPltFra)
	// controle de linhas por pagina
	Local _nLinAtu := 1

	// objeto utilizado para criar um retangulo
	local _oBrush1 := TBrush():New(,CLR_LIGHTGRAY)

	// decricao do produto
	local _cPrdDesc

	// controle da linha
	_nLin += 100

	// cria um retangulo escuro no fundo da palavra
	_oPrnMapa:FillRect({_nLin+10, 0100,_nLin+60, 2300}, _oBrush1 )
	// imprime os cabecalhos
	_oPrnMapa:Say(_nLin+10,0110,"PRODUTO",_oFont02,100)
	_oPrnMapa:Say(_nLin+10,1600,"QUANTIDADE",_oFont02,100,,,1)
	_oPrnMapa:Say(_nLin+10,1900,"QUANT. PLT",_oFont02,100,,,1)

	// controle da linha
	_nLin += 50
	// controle da linha por pagina
	_nLinAtu ++

	// varre todos os itens do resumo
	While (_nPosAtuRes <= Len(_aResumo)) .And. (_nLinAtu <= _nMaxItePag)

		// estrutura _aResumo
		// 1-Cod produto
		// 2-Quant do produto
		// 3-Quant de Palete

		// descricao do produto
		_cPrdDesc := AllTrim(Posicione("SB1",1,xFilial("SB1")+_aResumo[_nPosAtuRes][1],"B1_DESC"))

		// produto
		_oPrnMapa:Say(_nLin+10,0110,AllTrim(_aResumo[_nPosAtuRes][1])+" - "+_cPrdDesc,_oFont01,100)

		// quantidade de produto
		_oPrnMapa:Say(_nLin+10,1600,Transf(_aResumo[_nPosAtuRes][2],PesqPict("SC6","C6_QTDVEN")),_oFont01,100,,,1)

		// quantidade de paletes
		_oPrnMapa:Say(_nLin+10,1900,Transf(_aResumo[_nPosAtuRes][3],"@E 9999"),_oFont01,100,,,1)

		// controle da linha
		_nLin += 50

		// controle do item do vetor do resumo
		_nPosAtuRes += 1

		// controle da linha por pagina
		_nLinAtu ++

	EndDo

	// cria um retangulo escuro no fundo da palavra
	_oPrnMapa:FillRect({_nLin+10, 0100,_nLin+60, 2300}, _oBrush1 )
	// imprime os totais
	_oPrnMapa:Say(_nLin+10,1600,Transf(_nTotProdut,PesqPict("SC6","C6_QTDVEN")),_oFont02,100,,,1)
	_oPrnMapa:Say(_nLin+10,1900,Transf(_nTotPalete,"@E 9999"),_oFont02,100,,,1)
	// controle da linha por pagina
	_nLinAtu ++
	// controle da linha
	_nLin += 50

	// total de paletes fracionados
	If (mvTotPltFra > 0)
		_oPrnMapa:Say(_nLin + 10,0110,"PALETES PARCIAIS:  "+AllTrim(Str(mvTotPltFra)),_oFont01,100)
	EndIf
	_oPrnMapa:Say(_nLin + 100,0110,"ASSINATURA DO COLABORADOR: ___________________________________ ",_oFont01,100)

Return

//** funcao para estorno do mapa de apanhe
Static Function sfEstorno(mvNumCarga, mvObjWnd)
	// controle de seek
	local _cSeekZ06
	local _cSeekZ08
	local _cSeekZ18

	// query para busca dos dados no SD3
	local _cQrySD3
	local _cAlQry := GetNextAlias()

	// itens para estorno da transferencia de mercadoria
	local _aItemSD3 := {}

	// valida necessidade de estornar o pedido de venda
	local _lLibPedido := .T.

	// variavel de controle de transação
	local _lRet := .T.

	// ordens de serviço
	dbSelectArea("Z05")
	Z05->(dbOrderNickName("Z05_CARGA"))
	If ! Z05->(dbSeek( xFilial("Z05")+mvNumCarga ))
		// avisa o usuário que não encontrou a OS
		MsgStop("Ordem de Serviço não encontrada!")
		// variavel de controle
		_lRet := .F.
	EndIf

	// validação se o mapa já foi iniciado
	If ( _lRet )

		dbSelectArea("Z08")
		Z08->( dbSetOrder(1) ) // Z08_FILIAL, Z08_NUMOS, R_E_C_N_O_, D_E_L_E_T_
		Z08->( dbSeek ( _cSeekZ08 := xFilial("Z08") + Z05->Z05_NUMOS ) )

		// varre todos os itens da reserva de recursos
		While ( ! Z08->( Eof() ) ) .And. ( Z08->( Z08_FILIAL + Z08_NUMOS ) == _cSeekZ08)

			// valida se a operação já foi iniciada
			If ( ! Empty(Z08->Z08_DTINIC) )

				// avisa o usuário que não encontrou a OS
				MsgStop("As movimentações do Mapa de Apanhe já foram iniciadas. Estorno não permitido!")
				_lRet := .F.
			EndIf
			// próx registro
			Z08->( dbSkip() )
		EndDo
	EndIf

	If (_lRet)
		// mensagem de confirmacao
		_lRet := MsgYesNo("Confirma Estorno?", "Estorno")
	EndIf

	If ( _lRet )

		// monta a query para buscar os movimentos do SD3
		_cQrySD3 := "SELECT DISTINCT D3_DOC "
		// movimento interno
		_cQrySD3 += "FROM "+RetSqlName("SD3")+" SD3 (nolock)  "
		// filtro padrao
		_cQrySD3 += "WHERE "+RetSqlCond("SD3")+" "
		// numero da carga
		_cQrySD3 += "AND D3_ZCARGA  = '" + _cNumCarga + "' "
		// estorno
		_cQrySD3 += "AND D3_ESTORNO = ' ' "

		MemoWrit("c:\query\twmsa019_sfestorno.txt",_cQrySD3)

		// verifica se o alias esta em uso
		If (Select(_cAlQry) > 0)
			dbSelectArea(_cAlQry)
			dbCloseArea()
		EndIf

		// executa o select
		DbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQrySD3),(_cAlQry),.F.,.T.)
		(_cAlQry)->(dbGoTop())

		// quantidade de registros a processar
		ProcRegua( (_cAlQry)->( RecCount() ) )

		// chama o grupo de perguntas padrao da rotina MATA260
		pergunte("MTA260",.F.)

		// define o parametro "Considera Saldo poder de 3" como NAO
		mv_par03 := 2

		// inicia transacao
		BEGIN TRANSACTION

			// varre todos os enderecos
			While (_cAlQry)->(!Eof())

				// verifica se precisa liberar o pedido de venda
				If (_lLibPedido)

					// antes da movimentacao de estorno da mercadoria, altera a doca de retirada do pedido de venda e libera novamente os itens
					sfLibPedVen(.T.)

					// controle de liberacao do pedido de venda
					_lLibPedido := .F.

				EndIf

				// controle de regua de processamento
				IncProc("Seq.Documento: " + AllTrim( (_cAlQry)->D3_DOC ))

				// posiciona na movimentacao
				dbSelectArea("SD3")
				//SD3->(dbGoTo( (_cAlQry)->SD3ORIG ))
				SD3->(dbSetOrder(2)) //3-D3_FILIAL, D3_DOC, D3_COD
				SD3->(dbSeek( xFilial("SD3")+(_cAlQry)->D3_DOC ))

				lMsHelpAuto := .T.
				lMsErroAuto := .F.

				// executa rotina automatica
				MSExecAuto({|x,y| mata261(x,y)},_aItemSD3,6) // 6-estorno

				// controle de erro da rotina padrao
				If (lMsErroAuto)
					// rollback na transacao
					DisarmTransaction()
					// mostra erro
					MostraErro()
					// variavel de retorno
					_lRet := .F.
				EndIf

				// proximo endereco
				(_cAlQry)->(dbSkip())
			EndDo

			// itens da OS
			dbSelectArea("Z06")
			Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
			Z06->(dbSeek( _cSeekZ06 := xFilial("Z06") + Z05->Z05_NUMOS ))

			// varre todos os itens da OS
			While Z06->(!Eof()) .And. ((Z06->Z06_FILIAL + Z06->Z06_NUMOS) == _cSeekZ06)
				// apaga o item
				RecLock("Z06")
				Z06->(dbDelete())
				Z06->(MsUnLock())
				// proximo item
				Z06->(dbSkip())
			EndDo

			// mapa de armazenagem
			dbSelectArea("Z08")
			Z08->(dbSetOrder(1)) // 1-Z08_FILIAL, Z08_NUMOS
			Z08->(dbSeek( _cSeekZ08 := xFilial("Z08") + Z05->Z05_NUMOS ))

			// varre todos os itens do mapa de armazenagem
			While Z08->( ! Eof() ) .And. ((Z08->Z08_FILIAL + Z08->Z08_NUMOS) == _cSeekZ08)
				// apaga o item
				RecLock("Z08")
				Z08->(dbDelete())
				Z08->(MsUnLock())
				// proximo item
				Z08->(dbSkip())
			EndDo

			// reserva de recursos
			dbSelectArea("Z18")
			Z18->(dbSetOrder(1)) // 1-Z18_FILIAL, Z18_NUMOS, Z18_SEQOS
			Z18->(dbSeek( _cSeekZ18 := xFilial("Z18")+Z05->Z05_NUMOS ))

			// varre todos os itens da reserva de recursos
			While Z18->( ! Eof() ) .And. ((Z18->Z18_FILIAL + Z18->Z18_NUMOS) == _cSeekZ18)
				// apaga o item
				RecLock("Z18")
				Z18->(dbDelete())
				Z18->(MsUnLock())
				// proximo item
				Z18->(dbSkip())
			EndDo

			// apaga o cabecalho da OS
			dbSelectArea("Z05")
			RecLock("Z05")
			Z05->(dbDelete())
			Z05->(MsUnLock())

			// finaliza transacao
		END TRANSACTION
	EndIf

	If ( _lRet )
		// mensagem de confirmacao
		MsgInfo("Estorno realizado!", "Estorno")
		// fecha a janela
		mvObjWnd:End()
	EndIf

Return( _lRet )

//** funcao que demonstra os detalhes do endereco selecionado
Static Function sfDetProd(mvNumSeq)
	// objetos
	local _oWndConsEtq
	local _oBrwDetCons

	// variaveis do browse
	local _aHeadDet := {}
	local _aColsDet := {}

	// seek seb2
	local _cSeekSB2 := ""
	local _nSaldoSb2 := 0

	// define o header do browse
	aAdd(_aHeadDet,{"Cod.Prod"  ,"IT_PROD"  , ""                       , TamSx3("D1_COD")[1]    , 0                   ,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadDet,{"Saldo"     ,"IT_SALD"  , PesqPict("SB2","B2_QATU"), TamSx3("B2_QATU")[1]   , TamSx3("B2_QATU")[2],Nil,Nil,"N",Nil,"R" })
	aAdd(_aHeadDet,{"U.M."      ,"IT_UM"    , ""                       , TamSx3("D1_UM")[1]     , 0                   ,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadDet,{"NF Orig."  ,"IT_NOTA"  , ""                       , TamSx3("D1_DOC")[1]    , 0                   ,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadDet,{"Dt. Digit.","IT_DATA"  , ""                       , TamSx3("D1_EMISSAO")[1], 0                   ,Nil,Nil,"C",Nil,"R" })

	// busca os dados na SD1
	dbSelectArea("SD1")
	SD1->( dbSetOrder(4) ) // D1_FILIAL, D1_NUMSEQ, R_E_C_N_O_, D_E_L_E_T_
	If ( SD1->( dbSeek( xFilial("SD1") + mvNumSeq ) ) )

		dbSelectArea("SB2")
		SB2->( dbsetorder(1) ) // 1-B2_FILIAL, B2_COD, B2_LOCAL
		SB2->( dbseek( _cSeekSB2 := xFilial("SB2") + SD1->D1_COD ) )
		// varre todos os armazens do produto
		While SB2->( ! Eof() ) .And. ( (SB2->B2_FILIAL + SB2->B2_COD) == _cSeekSB2 )

			// verifica saldo disponivel no estoque.(SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QACLASS - SB2->B2_QEMP)
			_nSaldoSb2 += SaldoSb2()

			// proximo registro de saldo
			SB2->(dbSkip())
		EndDo

		// dados da nota de entrada
		aAdd(_aColsDet, { SD1->D1_COD, _nSaldoSb2, SD1->D1_UM, SD1->D1_DOC, SD1->D1_DTDIGIT, .F. } )
	EndIf

	// definicao da tela de consultas
	_oWndConsEtq := MSDialog():New(000,000,200,400,"Detalhes do Produto",,,.F.,,,,,,.T.,,,.T. )

	// browse com os detalhes da consulta
	_oBrwDetCons := MsNewGetDados():New(000,000,600,600,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDet),'AllwaysTrue()','','AllwaysTrue()',_oWndConsEtq,_aHeadDet,_aColsDet)
	_oBrwDetCons:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oWndConsEtq CENTERED

Return

//** funcao que busca o mapa gerado anteriormente
Static Function sfBuscaMapa(mvNumOs, mvStruMov, mvTudoOk)
	// query
	local _cQryZ08
	// valida se ja houve movimentacao
	local _lMovMerc := .F.

	// monta a query para buscar o mapa de expedicao
	_cQryZ08 := " SELECT "
	_cQryZ08 += " Z08_PRODUT MOV_PROD, "
	_cQryZ08 += " Z08_LOCAL  MOV_LOCAL, "
	_cQryZ08 += " Z08_ENDORI MOV_ENDORI, "
	_cQryZ08 += " Z08_QUANT  MOV_QUANT, "
	_cQryZ08 += " Z08_ENDDES MOV_ENDDES, "
	_cQryZ08 += " Z08_PALLET MOV_PALETE, "
	_cQryZ08 += " Z08_FRAPLT MOV_FRAPLT, "
	_cQryZ08 += " Z08_SEQUEN MOV_SEQ, "
	_cQryZ08 += " '' MOV_VOLUME, "
	_cQryZ08 += " Z08_STATUS MOV_STATUS, "
	_cQryZ08 += " Z08_QTSEGU MOV_QTSEGU "
	// mapa de expedicao
	_cQryZ08 += " FROM "+RetSqlTab("Z08")+" (nolock) "
	// filtro padrao
	_cQryZ08 += " WHERE "+RetSqlCond("Z08")
	// numero da OS
	_cQryZ08 += " AND Z08_NUMOS = '"+mvNumOs+"' "
	// ordem dos dados
	_cQryZ08 += " ORDER BY Z08_SEQUEN "

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQryZ08, mvStruMov, (_cAlTrbMov))

	(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
	(_cAlTrbMov)->(dbGoTop())

	// atualiza endereco de destino
	_cEndDest := (_cAlTrbMov)->MOV_ENDDES

	// atualiza a variavel _aMapaApanhe para usar no relatorio
	(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
	While (_cAlTrbMov)->(!Eof())

		// estrutura _aMapaApanhe
		//  1-cod produto
		//  2-local/armazem
		//  3-end retirada
		//  4-quant
		//  5-end destino
		//  6-ID palete
		//  7-fraciona palete
		//  8-serie nota orig
		//  9-nota orig
		// 10-item nota orig
		// 11-sequencial
		// 12-numseq
		// 13-id volume
		// 14-Lote
		// 15-Tipo de Estoque
		// 16-Quantidade Seg Unid

		// adiciona os detalhes no mapa de apanhe (utilizado na U_WMSA009B)
		aAdd(_aMapaApanhe,{(_cAlTrbMov)->MOV_PROD  , ;
		(_cAlTrbMov)->MOV_LOCAL , ;
		(_cAlTrbMov)->MOV_ENDORI, ;
		(_cAlTrbMov)->MOV_QUANT , ;
		(_cAlTrbMov)->MOV_ENDDES, ;
		(_cAlTrbMov)->MOV_PALETE, ;
		(_cAlTrbMov)->MOV_FRAPLT, ;
		(_cAlTrbMov)->MOV_SERORI, ;
		(_cAlTrbMov)->MOV_NFORI , ;
		(_cAlTrbMov)->MOV_ITEORI, ;
		(_cAlTrbMov)->MOV_SEQ   , ;
		(_cAlTrbMov)->MOV_NUMSEQ, ;
		(_cAlTrbMov)->MOV_VOLUME, ;
		(_cAlTrbMov)->MOV_LOTCTL ,;
		(_cAlTrbMov)->MOV_TPESTO ,;
		(_cAlTrbMov)->MOV_QTSEGU })

		// atualiza dados
		If ((_cAlTrbMov)->MOV_STATUS <> "P")
			_lMovMerc := .T.
		EndIf

		// proximo item
		(_cAlTrbMov)->(dbSkip())
	EndDo
	// primeiro registros
	(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
	(_cAlTrbMov)->(DbGoTop())

	// atualiza variavel para permitir estorno
	If ( ! _lMovMerc)
		mvTudoOk := .T.
	EndIf

	// verifica se houve movimentacao do estoque
	_cQryZ08 := "SELECT DISTINCT Z06_ATUEST "
	// mapa de expeicao
	_cQryZ08 += "FROM "+RetSqlName("Z08")+" Z08 (nolock)  "
	// sequencia da OS
	_cQryZ08 += "INNER JOIN "+RetSqlName("Z06")+" Z06 (nolock)  ON "+RetSqlCond("Z06")+" AND Z06_NUMOS = Z08_NUMOS AND Z06_SEQOS = Z08_SEQOS "
	// filtro padrao
	_cQryZ08 += "WHERE "+RetSqlCond("Z08")+" "
	// numero da OS
	_cQryZ08 += "AND Z08_NUMOS = '"+mvNumOs+"' "

	// atualiza variavel
	_lLibNota := (U_FtQuery(_cQryZ08) == "N")

Return

//** funcao para liberacao e analise de estorno do pedido de venda
Static Function sfLibPedVen(mvEstorno)
	// variavel de retorno
	local _lRet := .T.

	// query dos itens do pedido
	local _cQrySC6
	local _aRecnoLib := {}
	local _nRecnoLib := 0

	// pedidos liberados
	local _aPedLiber := {}

	// monta a query para buscar os itens dos pedidos de venda da carga
	_cQrySC6 := "SELECT SC6.R_E_C_N_O_ SC6RECNO, SC9.R_E_C_N_O_ SC9RECNO "
	// itens liberados
	_cQrySC6 += "FROM "+RetSqlName("SC9")+" SC9 (nolock)  "
	// itens liberados
	_cQrySC6 += "INNER JOIN "+RetSqlName("SC6")+" SC6 (nolock)  ON "+RetSqlCond("SC6")+" AND C6_NUM = C9_PEDIDO AND C6_ITEM = C9_ITEM AND C6_PRODUTO = C9_PRODUTO  "
	// filtro padrao
	_cQrySC6 += "WHERE "+RetSqlCond("SC9")+" "
	// carga
	_cQrySC6 += "AND C9_CARGA = '"+_cNumCarga+"' "
	// sem nota fiscal emitida E sem bloqueio de WMS
	_cQrySC6 += "AND C9_NFISCAL = ' ' AND C9_BLEST IN ('  ','02') AND C9_BLWMS = ' ' "
	// ordem dos dados
	_cQrySC6 += "ORDER BY C6_NUM, C6_ITEM "

	memowrit("c:\query\twmsa019_confmapa_libera_itens.txt",_cQrySC6)

	// alimenta o vetor com os RECNOs dos itens do pedido
	_aRecnoLib := U_SqlToVet(_cQrySC6)

	// varre todo os itens dos pedidos de venda
	For _nRecnoLib := 1 to len(_aRecnoLib)

		// posiciona no registro do item liberado
		dbSelectArea("SC9")
		SC9->(dbGoTo( _aRecnoLib[_nRecnoLib][2] ))

		// posiciona no registro do item
		dbSelectArea("SC6")
		SC6->(dbGoTo( _aRecnoLib[_nRecnoLib][1] ))

		// posiciona no cabecalho do pedido
		dbSelectArea("SC5")
		SC5->(dbSetOrder( 1 )) // 1-C5_FILIAL, C5_NUM
		SC5->(dbSeek( xFilial("SC5")+SC6->C6_NUM ))

		// pedidos liberados
		If ( aScan(_aPedLiber,{|x| x == SC5->C5_NUM }) == 0 )
			aAdd(_aPedLiber,SC5->C5_NUM)
		EndIf

		// atualiza a doca de retirada
		RecLock("SC6")
		SC6->C6_LOCALIZ := IIf(mvEstorno,SC6->C6_NUM,_cEndDest)
		SC6->(MsUnLock())

		// realiza o estorno da mercadoria empenhada no pedido de venda / necessario para realizar nova liberacao
		a460estorna()

		// liberacao do item do pedido de venda
		MaLibDoFat( SC6->(RecNo()) ,; // recno do SC6
		SC6->C6_QTDVEN             ,; // quantidade liberada da 1a UM
		Nil                        ,; // retorno de bloqueio de credito
		Nil                        ,; // retorno de bloqueio de estoque
		.T.                        ,; // reavalia credito?
		.T.                        ,; // reavalia estoque?
		.F.                        ,; // permite liberacao parcial de pedidos?
		.F.                         ) // transferencia de enderecos automaticamente?

	Next _nRecnoLib

	// atualiza o status do pedido de venda
	SC6->(MaLiberOk(_aPedLiber))

Return(_lRet)

// ** funcao que pesquisa as configuracoes de agrupadores disponiveis
Static Function sfMapaAgrup(mvProdPedido, mvQryProdPed, mvCntrlSeq, mvArmzPadrao)
	// variavel de retorno
	local _lRet := .T.
	// retorno do mapa
	local _lRetMapa := .F.

	// variaveis temporarias
	local _aTmpAgrup := {}
	local _nProd
	local _nOpcao

	// query
	local _cQuery

	// possibilidades
	local _aCfgPossiv := {}

	// monta query para buscar os agrupadores disponiveis
	_cQuery := " SELECT Z29_CODKIT, Z29_DSCKIT, COUNT(DISTINCT Z29_PRODUT) QTD_PROD "
	// cadastro de agrupadora
	_cQuery += " FROM "+RetSqlTab("Z29")+" (nolock) "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z29")
	// filtro por codigo de kit conforme seus produtos
	_cQuery += " AND Z29_CODKIT IN ("
	// busca os kits por codigo de produtos
	_cQuery += "     SELECT DISTINCT Z29_CODKIT FROM "+RetSqlTab("Z29")+" (nolock) "
	// filtro padrao
	_cQuery += "     WHERE "+RetSqlCond("Z29")
	// filtro de produtos
	_cQuery += "     AND Z29_PRODUT IN "+FormatIn(mvQryProdPed,"!")
	// kit bloqueado
	_cQuery += "    AND Z29_MSBLQL != '1' ) "
	// kit bloqueado
	_cQuery += " AND Z29_MSBLQL != '1' "
	// agrupa dados
	_cQuery += " GROUP BY Z29_CODKIT, Z29_DSCKIT "
	// ordem de dados
	_cQuery += " ORDER BY COUNT(DISTINCT Z29_PRODUT) DESC "

	memowrit("c:\query\twmsa019_sfMapaAgrup_consulta_kit.txt",_cQuery)

	// atualiza vetor temporario
	_aTmpAgrup := U_SqlToVet(_cQuery)

	// atualiza variavel principal
	For _nProd := 1 to Len(_aTmpAgrup)

		// inclui a configuracao do agrupador
		aAdd(_aCfgPossiv,{"AGR",_aTmpAgrup[_nProd][1]})

	Next _nProd

	// incrementa as opcoes por produto
	For _nProd := 1 to Len(mvProdPedido)

		// inclui a configuracao do agrupador
		aAdd(_aCfgPossiv,{"PRO",mvProdPedido[_nProd][1]})

	Next _nProd

	// cria o indice para pesquisa de enderecos do produto no mapa de movimentacao
	(_cAlTrb1)->(dbSelectArea(_cAlTrb1))
	If (_cAlTrb1)->(!EOF())
		(_cAlTrb1)->(IndRegua((_cAlTrb1),(_cTrbEnd1),"ET1_PROD+ET1_LOCAL+ET1_ENDORI",,,"Selecionando Registros..."))
	EndIf

	// cria o indice para pesquisa de enderecos do produto no mapa de movimentacao
	(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
	If (_cAlTrbMov)->(!EOF())
		(_cAlTrbMov)->(IndRegua((_cAlTrbMov),(_cTrbMov),"MOV_PROD+MOV_LOCAL+MOV_ENDORI+MOV_PALETE+MOV_LOTCTL",,,"Selecionando Registros..."))
	EndIf

	// inicia o processo de pesquisa por possibilidades de armazenagem
	For _nOpcao := 1 to Len(_aCfgPossiv)

		// se for agrupadora/kit
		If (_aCfgPossiv[_nOpcao][1] == "AGR")

			// funcao que pesquisa enderedos por agrupadora
			_lRetMapa := sfPesqAgrup(;
			_aCfgPossiv[_nOpcao][2] ,;
			@mvProdPedido           ,;
			@mvCntrlSeq             ,;
			mvArmzPadrao             )

			// atualiza variavel de retorno
			If ( ! _lRetMapa)
				_lRet := _lRetMapa
			EndIf

			// se for por produto
		ElseIf (_aCfgPossiv[_nOpcao][1] == "PRO")

			(_cAlTrbSC6)->(dbSelectArea(_cAlTrbSC6))
			(_cAlTrbSC6)->(dbSetOrder(1))
			(_cAlTrbSC6)->(dbSeek( _aCfgPossiv[_nOpcao][2] ))

			_lRetMapa := sfMontaMapa((_cAlTrbSC6)->C6_PRODUTO,;
			(_cAlTrbSC6)->C6_SERIORI,;
			(_cAlTrbSC6)->C6_NFORI  ,;
			(_cAlTrbSC6)->C6_ITEMORI,;
			(_cAlTrbSC6)->C6_SALDO  ,;
			@mvCntrlSeq             ,;
			(_cAlTrbSC6)->D1_NUMSEQ ,;
			(_cAlTrbSC6)->C6_ZTPESTO,;
			mvArmzPadrao            ,;
			(_cAlTrbSC6)->C6_LOTECTL )

			// atualiza variavel de retorno
			If ( ! _lRetMapa)
				_lRet := _lRetMapa
			EndIf

		EndIf

	Next _nOpcao

Return(_lRet)

// ** funcao para buscar endereco conforme componentes disponiveis
Static Function sfPesqAgrup(mvCodKit, mvProdPedido, mvCntrlSeq, mvArmzPadrao)
	// variaveis temporarias
	local _nComp
	local _nItNf

	// maior quantidade informada no componente
	local _nMaxQuant := 0
	// quantidade maxima do kit selecionado
	local _nQtdKit := 0
	local _nMaxMntKit := 0
	// quantidade disponivel
	local _nQtdDisp := 0

	// kit completo
	local _lKitOk := .T.

	// query para busca de dados
	local _cQuery
	local _cAlQry := GetNextAlias()

	// componentes da agrupadora
	local _aCompAgrup := {}
	local _cQryAgrup := ""

	// quantidade de componentes obrigatorios
	local _nQtdObrig := 0

	// saldo de apanhe
	local _nSaldoApanhe := 0

	// posicao da reserva do endereco no vetor do mapa de apanhe
	local _nPosReserv := 0

	// posicao do produto no vetor de itens do pedido
	local _nPosItPed := 0

	// endereco atual
	local _cEndAtual := ""

	// armazem atual
	local _cArmzAtual

	// ID palete
	local _cIdPalete

	// codigo do produto
	local _cCodProd   := ""
	local _nQtdNece   := 0
	local _nQtdEndAnt := 0

	// quantidade
	local _nQtdSelec := 0
	local _nQtdSegum := 0

	// saldo disponivel no endereco
	local _nSldDispEnd := 0

	// quantidade maxima de volumes/agrupadora por palete
	// estrutura do retorno
	// 1-Quantidade Total de Palete
	// 2-Quantidade de Paletes Cheios
	// 3-Quantidade de Paletes Fracionados
	// 4-Quantidade Maxima de SKU/Volumes por Palete
	// 5-Tipo do Calculo (Q-Quant Unitarios / P-Quant Palete Informado)
	Local _aRetPal := U_FtWmsNorma(mvCodKit, mvArmzPadrao, Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)

	// atualiza variavel de controle de acordo com o calculo da funcao FtWmsNorma
	local _nVolMaxPlt := _aRetPal[4]

	// quantidade de paletes completos
	local _nPltComple := 0

	// quantidade de paletes fracionados
	local _nPltFracio := 0

	// modelo de pesquisa
	local _lPltComple := .F.
	local _lPltFracio := .F.

	// fracionar palete
	local _cFracPlt := "N"

	// fracionar volume
	local _cFracVol := "N"

	// controle do Loop de tentativas de busca
	local _lNovaBusca := .T.

	// controle se o endereco atendeu a condicao
	local _lEndAtende := .T.

	// controle do tipo de busca
	// 1-Palete Completo
	// 2-Palete Fracionado
	// 3-Palete com Qualquer Quantidade
	local _cTipoBusca := "1"

	// controle para considerar a quantidade
	// 1-Palete com Quantidade Exata
	// 2-Palete com Quantidade Maior
	// 3-Palete com Quantidade Menor
	local _cTipoQuant := "1"

	// debugar mensagens
	local _lDebug := .F.

	// controle se deve mudar a busca, de palete completo para fracionado, quando sobrar saldo
	local _lMudaBusca := .F.

	// log do vetor de componentes
	local _cLogComp := ""

	Local _xxxxx := 0

	// valida quantidade maxima de volumes por palete (lastro x camada)
	If (_nVolMaxPlt == 0)
		Return(_lKitOk)
	EndIf

	// busca componentes do kit selecionado
	// 1-Cod Produto
	// 2-Qtd Basica do Componente
	// 3-Qtd Maxima do Componente
	// 4-Qtd Necessaria
	// 5-Saldo Total/Maximo para Apanhe
	// 6-Qtd Necessaria
	// 7-Qtd Necessaria
	// 8-Saldo Disponivel no Endereco
	_cQuery := "SELECT Z29_PRODUT, Z29_QUANT, 0 QTD_NECES, 0 QTD_SEPARADA, 0 QTD_SALDO, 0 QTD_NEC_END, 0 QTD_SEP_END, 0 QTD_DISP_END "
	// cad. de Kit
	_cQuery += "FROM "+RetSqlName("Z29")+" Z29 (nolock)  "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z29")
	// codigo do kit
	_cQuery += "AND Z29_CODKIT = '"+mvCodKit+"' "
	// ordem dos dados
	_cQuery += "ORDER BY Z29_PRODUT "

	// atualiza variavel
	_aCompAgrup := U_SqlToVet(_cQuery)

	// controle de componentes obrigatorios
	_nQtdObrig := Len(_aCompAgrup)

	// varre todos os componentes, para buscar a quantidade maxima por componente
	For _nComp := 1 to Len(_aCompAgrup)
		// calcula quantidade maxima
		If (_aCompAgrup[_nComp][2] > _nMaxQuant)
			_nMaxQuant := _aCompAgrup[_nComp][2]
		EndIf
		// inclui codigos dos produtos para usar o SQL
		_cQryAgrup += _aCompAgrup[_nComp][1] + "!"
	Next _nComp

	// varre todos os componentes novamente para buscar a quantidade por produto
	For _nComp := 1 to Len(_aCompAgrup)

		// se nao ha saldo, fecha a rotina
		If ( ! _lKitOk)
			Exit
		EndIf

		// zera variaveis
		_nQtdDisp := 0

		// varre todos os itens da nota para validar quantidade disponivel para montar o kit
		For _nItNf := 1 to Len(mvProdPedido)
			// verifica se o componente esta na lista
			If (mvProdPedido[_nItNf][1] == _aCompAgrup[_nComp][1])
				// calcula quantidade disponivel
				_nQtdDisp += mvProdPedido[_nItNf][2]
			EndIf
		Next _nItNf

		// calcula quantidade de KIT
		_nQtdKit := Int(_nQtdDisp / _nMaxQuant)

		// se nao tem quantidade disponivel, kit nao sera completo
		If (_nQtdKit <= 0)
			_nMaxMntKit := 0
			Exit
		EndIf

		// armazena a quantidade maxima de kit possiveis
		If (_nMaxMntKit == 0)
			_nMaxMntKit	:= _nQtdKit
		ElseIf (_nMaxMntKit > 0) .And. (_nQtdKit < _nMaxMntKit)
			_nMaxMntKit	:= _nQtdKit
		EndIf

	Next _nComp

	If (_lDebug)
		MsgSTop("_nMaxMntKit -> "+Str(_nMaxMntKit))
		MSgSTop("_nVolMaxPlt -> "+Str(_nVolMaxPlt))
	EndIf

	// se nao ha componente para montar o kit, finaliza
	If (_nMaxMntKit <= 0)
		Return(_lKitOk)
	EndIf

	// calcula a quantidade de paletes completos
	_nPltComple := Int(_nMaxMntKit / _nVolMaxPlt)

	// calcula a quantidade de paletes fracionados
	If (Mod(_nMaxMntKit,_nVolMaxPlt) > 0)
		_nPltFracio := 1
	EndIf

	// modelo de pesquisa de palete completo/fracionado
	_lPltComple := (_nPltComple > 0)
	_lPltFracio := (_nPltFracio > 0)

	If (_lDebug)
		MsgSTop("_nPltComple -> "+Str(_nPltComple))
		MsgSTop("_nPltFracio -> "+Str(_nPltFracio))
	EndIf

	// pesquisa agrupadores armazenados disponiveis

	// controle do tipo de busca
	// 1-Palete Completo
	// 2-Palete Fracionado
	// 3-Palete com Qualquer Quantidade
	_cTipoBusca := IIf(_lPltComple, "1", "2")

	// controle para considerar a quantidade
	// 1-Palete com Quantidade Exata
	// 2-Palete com Quantidade Maior
	// 3-Palete com Quantidade Menor
	_cTipoQuant := "1"

	// varre todos os componentes e calcula a coluna com a quantidade para apanhe (qtd comp x qtd kit)
	For _nComp := 1 to Len(_aCompAgrup)

		// atualiza quantidade necessaria e saldo
		_aCompAgrup[_nComp][3] := _aCompAgrup[_nComp][2] * _nMaxMntKit
		// saldo
		_aCompAgrup[_nComp][5] := _aCompAgrup[_nComp][3]

	Next _nComp

	// controle de saldo
	While (_lNovaBusca)

		If (_lDebug) .And. ( ! MsgYesNo("Continuar?", "Debug") )
			_lNovaBusca := .F.
			Loop
		EndIf

		If (_lDebug)
			MsgSTop("_cTipoBusca -> "+_cTipoBusca+" / _cTipoQuant -> "+_cTipoQuant)
		EndIf

		// -- 1o - BUSCA ENDERECOS RELACIONADOS A NOTA FISCAL
		_cQuery := "SELECT SBF.BF_LOCAL, "
		_cQuery += "       SBF.BF_LOCALIZ, "
		_cQuery += "       Z16_ETQPAL, "
		_cQuery += "       Count(DISTINCT Z16_ETQVOL) QTD_VOLUMES "

		// saldo do produto no endereco
		_cQuery += "FROM "+RetSqlName("SBF")+" SBF (nolock)  "

		// composicao de palete
		_cQuery += "INNER JOIN "+RetSqlName("Z16")+" Z16 (nolock)  ON "+RetSqlCond("Z16")+" AND Z16_LOCAL = SBF.BF_LOCAL AND Z16_ENDATU = SBF.BF_LOCALIZ "
		_cQuery += "AND Z16_CODPRO = SBF.BF_PRODUTO AND Z16_SALDO > 0 "
		// tipo do estoque 000001-NORMAL
		_cQuery += "AND Z16_TPESTO IN ('','000001') "
		//filtro de endereços sob inventario
		_cQuery += " AND NOT EXISTS (SELECT Z21_LOCALI FROM " + RetSqlTab("Z21") + " (nolock)  WHERE " + RetSqlCond("Z21") + " AND Z21_IDENT NOT IN (SELECT Z06_NUMOS FROM " + RetSqlTab("Z06") + " (nolock)  WHERE Z06_FILIAL = Z21_FILIAL AND Z06_NUMOS = Z21_IDENT AND D_E_L_E_T_ = '' AND Z06_STATUS NOT IN ('FI', 'CA'))) "
		//filtro de endereços cujos pallets ainda estão em OS de recebimento não finalizada (SERVIÇO 003 - RECEBIMENTO)
		_cQuery += " AND Z16_ETQPAL NOT IN (SELECT DISTINCT Z07_PALLET FROM " + RetSqlTab("Z07") + " (nolock)  WHERE " + RetSqlCond("Z07") + " AND Z07_NUMOS IN (SELECT Z06_NUMOS FROM Z06010 WHERE Z06_FILIAL = Z07_FILIAL AND Z06_NUMOS = Z07_NUMOS AND D_E_L_E_T_ = '' AND Z06_SERVIC = '003' AND Z06_STATUS NOT IN ('FI','CA'))) "

		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("SBF")+" "

		// somente enderecos que contem os produtos da agrupadora
		_cQuery += "AND SBF.BF_LOCALIZ IN (SELECT SBF1.BF_LOCALIZ "
		_cQuery += "                         FROM "+RetSqlName("SBF")+" SBF1 (nolock)  "
		_cQuery += "                        WHERE SBF1.BF_FILIAL = '"+xFilial("SBF")+"' AND SBF1.D_E_L_E_T_ = ' ' "
		_cQuery += "                          AND SBF1.BF_PRODUTO IN "+FormatIn(_cQryAgrup,"!")
		_cQuery += "                      ) "
		// estrutura fisica disponivel para o mapa
		_cQuery += "AND SBF.BF_ESTFIS IN "+FormatIn(_cEstFisMapa,"/")+" "
		// Tipo de Endereço DIFERENTE de Picking
		_cQuery += "AND SBF.BF_ESTFIS NOT IN "+FormatIn(_cEstPicking,"/")+" "

		// descarta armazem A3
		_cQuery += " AND BF_LOCAL NOT IN ('A3') "

		// armazem padrao do cliente
		_cQuery += " AND BF_LOCAL = '" +mvArmzPadrao+ "' "

		// agrupa dados
		_cQuery += "GROUP BY SBF.BF_LOCAL, "
		_cQuery += "         SBF.BF_LOCALIZ, "
		_cQuery += "         Z16_ETQPAL "

		// somente quando houver a quantidade de itens obrigatorios
		_cQuery += "HAVING Count(DISTINCT SBF.BF_PRODUTO) = "+AllTrim(Str(_nQtdObrig))+" "
		_cQuery += "   AND (SELECT Count(DISTINCT SBF3.BF_PRODUTO) "
		_cQuery += "          FROM "+RetSqlName("SBF")+" SBF3 (nolock)  "
		_cQuery += "         WHERE SBF3.BF_FILIAL  = '"+xFilial("SBF")+"' AND SBF3.D_E_L_E_T_ = ' ' "
		_cQuery += "           AND SBF3.BF_LOCAL = SBF.BF_LOCAL AND SBF3.BF_LOCALIZ = SBF.BF_LOCALIZ "
		_cQuery += "           AND SBF3.BF_PRODUTO IN "+FormatIn(_cQryAgrup,"!")+") = "+AllTrim(Str(_nQtdObrig))+" "

		// controle do tipo de busca
		// 1-Palete Completo
		// 2-Palete Fracionado
		// 3-Palete com Qualquer Quantidade
		If (_cTipoBusca == "1") // 1-Palete Completo
			_cQuery += " AND COUNT(DISTINCT Z16_ETQVOL) = "+AllTrim(Str(_nVolMaxPlt))+" "
		ElseIf (_cTipoBusca == "2") // 2-Palete Fracionado
			_cQuery += " AND COUNT(DISTINCT Z16_ETQVOL) <> "+AllTrim(Str(_nVolMaxPlt))+" "
		EndIf

		// ordem dos dados
		_cQuery += "ORDER  BY Z16_ETQPAL, "
		_cQuery += "          SBF.BF_LOCALIZ "

		memowrit("c:\query\twmsa019_sfMapaAgrup_sfCalcEstru_sql_"+_cTipoBusca+"_"+_cTipoQuant+".txt",_cQuery)

		If (_lDebug)
			MsgStop("Ver Query")
		EndIf

		// verifica se o alias esta em uso
		If (Select(_cAlQry) > 0)
			dbSelectArea(_cAlQry)
			dbCloseArea()
		EndIf

		// executa o select
		DbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),(_cAlQry),.F.,.T.)
		(_cAlQry)->(dbGoTop())

		// varre todos os enderecos
		While (_cAlQry)->( ! Eof() ) .And. (_lNovaBusca)

			// zera variaveis
			_nQtdSelec    := 0
			_nQtdSegum    := 0
			_cFracPlt     := "N"
			_cFracVol     := "N"
			_cArmzAtual   := (_cAlQry)->BF_LOCAL
			_cEndAtual    := (_cAlQry)->BF_LOCALIZ
			_cIdPalete    := (_cAlQry)->Z16_ETQPAL
			_nSldDispEnd  := 0

			// controle se o endereco atendeu a condicao
			_lEndAtende   := .T.

			// verifica se o endereco existe
			dbSelectArea("SBE")
			SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
			SBE->(dbSeek( xFilial("SBE")+_cArmzAtual+_cEndAtual ))

			If (_lDebug)
				MsgStop("_cEndAtual -> "+_cEndAtual)
			EndIF

			// valida status do endereco
			If (SBE->BE_STATUS == "3")
				// controle se o endereco atendeu a condicao
				_lEndAtende := .F.
				// proximo endereco
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// varre todos os componentes e calcula a coluna com a quantidade para apanhe (qtd comp x qtd kit)
			For _nComp := 1 to Len(_aCompAgrup)

				// 1-Palete Completo
				// 2-Palete Fracionado
				// 3-Palete com Qualquer Quantidade

				// atualiza a quantidade maxima do componente por endereco
				If (_cTipoBusca == "1") // 1-Palete Completo
					_aCompAgrup[_nComp][6] := _aCompAgrup[_nComp][2] * _nVolMaxPlt

					// controle de saldo
				ElseIf (_cTipoBusca == "2") // 2-Palete Fracionado
					_aCompAgrup[_nComp][6] := _aCompAgrup[_nComp][5]

				ElseIf (_cTipoBusca == "3") // 3-Palete com Qualquer Quantidade
					_aCompAgrup[_nComp][6] := _aCompAgrup[_nComp][5]

				EndIf

				If (_lDebug)
					MsgStop("prod -> "+_aCompAgrup[_nComp][1]+" / Quant -> "+Str(_aCompAgrup[_nComp][6]))
				EndIf

			Next _nComp

			// zera log do vetor de componentes
			_cLogComp := ""

			// zera quantidade para comparar
			_nQtdEndAnt := 0

			// verifica o saldo do produto no endereco de origem
			For _nComp := 1 to Len(_aCompAgrup)

				// codigo do produto
				_cCodProd := _aCompAgrup[_nComp][1]

				// quantidade necessaria
				_nQtdNece := _aCompAgrup[_nComp][6]

				// quantidade ja separada
				_aCompAgrup[_nComp][7] := 0

				// saldo atual do endereco
				_aCompAgrup[_nComp][8] := 0

				If (_lDebug)
					For _xxxxx := 1 to Len(_aCompAgrup[_nComp])
						If (_xxxxx == 1)
							_cLogComp += _aCompAgrup[_nComp][_xxxxx]
						Else
							_cLogComp += Str(_aCompAgrup[_nComp][_xxxxx])
						EndIf
					next _xxxxx
					_cLogComp += CRLF
				EndIf

				If (_lDebug)
					MsgSTop("_nQtdNece -> "+Str(_nQtdNece))
				EndIf

				// consulta saldo disponivel
				_nSaldoEnd := SaldoSBF(;
				_cArmzAtual  ,;
				_cEndAtual   ,;
				_cCodProd    ,;
				NIL          ,;
				NIL          ,;
				NIL          ,;
				.F.          ,;
				SBE->BE_ESTFIS)

				If (_lDebug)
					MsgSTop("_nSaldoEnd 1 -> "+Str(_nSaldoEnd))
				EndIf

				// verifica o saldo no endereco
				If (_nSaldoEnd <= 0)
					// controle se o endereco atendeu a condicao
					_lEndAtende := .F.
					// sai do loop do componente
					_nComp := Len(_aCompAgrup) ; Loop
				EndIf

				// verifica se o endereco ja foi utilizado em outro item

				// estrutura _aMapaApanhe
				//  1-cod produto
				//  2-local/armazem
				//  3-end retirada
				//  4-quant
				//  5-end destino
				//  6-ID palete
				//  7-fraciona palete
				//  8-serie nota orig
				//  9-nota orig
				// 10-item nota orig
				// 11-sequencial
				// 12-numseq
				// 13-id volume
				// 14-Lote
				// 15-Tipo de Estoque
				// 16-Quantidade Seg Unid

				_nPosReserv := aScan(_aMapaApanhe,{|x| (x[1] == _cCodProd) .And. (x[2] == _cArmzAtual) .And. (x[3] == _cEndAtual) .And. (x[6] == _cIdPalete) })

				// reduz o saldo do endereco ja utilizado
				If (_nPosReserv > 0)
					_nSaldoEnd -= _aMapaApanhe[_nPosReserv][4]
				EndIf

				If (_lDebug)
					MsgSTop("_nSaldoEnd 2 -> "+Str(_nSaldoEnd))
				EndIf

				// verifica o saldo no palete, desconsiderando o saldo ja reservado
				// dados para retorno
				// 1-Id Palete
				// 2-Local/Armazem
				// 3-Endereco Atual
				// 4-Etq Produto
				// 5-Etq Volume
				// 6-Cod Produto
				// 7-Saldo Atual (Z16)
				// 8-Saldo Reservado (Z08)
				// 9-Saldo Disponivel (Z16 - Z08)
				_aSaldoPlt := U_FtSldPlt(_cIdPalete,;
				Nil       ,;
				Nil       ,;
				_cCodProd ,;
				.F.       ,;
				.F.       ,;
				Nil        )

				// reduz o saldo do endereco ja utilizado em outro mapa
				If (Len(_aSaldoPlt) > 0) .And. ( ! _lVolJaDef )
					_nSaldoEnd -= _aSaldoPlt[1][8]
				EndIf

				If (_lDebug)
					MsgSTop("_nSaldoEnd 3 -> "+Str(_nSaldoEnd))
				EndIf

				// verifica o saldo no endereco
				If (_nSaldoEnd <= 0)
					// controle se o endereco atendeu a condicao
					_lEndAtende := .F.
					// sai do loop do componente
					_nComp := Len(_aCompAgrup) ; Loop
				EndIf

				// 1-Palete Completo
				// 2-Palete Fracionado
				// 3-Palete com Qualquer Quantidade

				// teste de palete completo, e se a quantidade esta de acordo com a necessidade
				If (_cTipoBusca == "1") .And. (_nSaldoEnd <> _nQtdNece) // 1-Palete Completo
					// controle se o endereco atendeu a condicao
					_lEndAtende := .F.
					// sai do loop do componente
					_nComp := Len(_aCompAgrup) ; Loop
				EndIf

				// controle de saldo
				If (_cTipoBusca == "1") .And. (_nSaldoEnd == _nQtdNece)
					_nQtdSelec   := _nSaldoEnd
					_nSldDispEnd := _nSaldoEnd
					_cFracPlt    := "N"
					_cFracVol    := "N"

					// controle de saldo
				ElseIf (_cTipoBusca $ "2|3") // 2-Palete Fracionado / 3-Palete com Qualquer Quantidade

					// validacao da quantidade
					// 1-Palete com Quantidade Exata
					// 2-Palete com Quantidade Maior
					// 3-Palete com Quantidade Menor
					/*
					If (_cTipoQuant == "1")
					// valida a quantidade
					If (_nSaldoEnd <> _nQtdNece)
					// controle se o endereco atendeu a condicao
					_lEndAtende := .F.
					// proximo endereco
					(_cAlQry)->(dbSkip())
					Loop
					EndIf
					EndIf
					*/

					If (_nSaldoEnd <= _nQtdNece)
						_nQtdSelec   := _nSaldoEnd
						_nSldDispEnd := _nSaldoEnd
						_cFracPlt    := "N"
						_cFracVol    := "N"
					ElseIf (_nSaldoEnd > _nQtdNece)
						_nQtdSelec   := _nQtdNece
						_nSldDispEnd := _nSaldoEnd
						_cFracPlt    := "S"
						_cFracVol    := "N"
					EndIf
				EndIf

				// atualiza quantidade para comparar
				If (_nQtdEndAnt > 0) .And. (_nQtdSelec <> _nQtdEndAnt)
					_lEndAtende := .F.
				EndIf

				// atualiza quantidade para comparar
				_nQtdEndAnt := _nQtdSelec

				// atualiza saldo do apanhe do endereco
				_aCompAgrup[_nComp][7] += _nQtdSelec

				// atualiza saldo disponivel no endereco
				_aCompAgrup[_nComp][8] := _nSldDispEnd

			Next _nComp

			// muda de endereco
			If ( ! _lEndAtende )
				// proximo endereco
				dbSelectArea(_cAlQry)
				(_cAlQry)->(dbSkip())
				Loop
			EndIf

			// calcula a quantidade separada por endereco
			_nSaldoApanhe := 0
			aEval(_aCompAgrup,{|x| (_nSaldoApanhe += Abs(x[6] - x[7])), _lEndAtende := IIf((!_lEndAtende), .F., (x[7] > 0)) })

			If (_lDebug)
				MsgStop("Fim -> "+Str(_nSaldoApanhe))
				MsgStop("_lEndAtende -> " + IIf(_lEndAtende,"Ok","Não"))
				memowrit("c:\query\twmsa019_kit_"+AllTrim(mvCodKit)+".txt",_cLogComp)
			EndIf

			// valida se a condicao atende
			If (_lEndAtende) .And. (((_cTipoBusca == "1") .And. (_nSaldoApanhe == 0)) .Or. (_cTipoBusca $ "2|3"))

				For _nComp := 1 to Len(_aCompAgrup)

					// codigo do produto
					_cCodProd  := _aCompAgrup[_nComp][1]

					// quantidade separada
					_nQtdSelec := _aCompAgrup[_nComp][7]

					// atualiza saldo disponivel no endereco
					_nSldDispEnd := _aCompAgrup[_nComp][8]

					// inclui o endereco
					(_cAlTrb3)->(dbSelectArea(_cAlTrb3))
					(_cAlTrb3)->(RecLock(_cAlTrb3,.T.))
					(_cAlTrb3)->ET3_COR    := "OK"
					(_cAlTrb3)->ET3_ORIG   := "AGR"
					(_cAlTrb3)->ET3_PROD   := _cCodProd
					(_cAlTrb3)->ET3_ENDORI := _cEndAtual
					(_cAlTrb3)->ET3_SALDO  := _nSldDispEnd
					(_cAlTrb3)->ET3_QUANT  := _nQtdSelec
					(_cAlTrb3)->ET3_SEQ    := mvCntrlSeq
					(_cAlTrb3)->ET3_QRY    := _cTipoBusca
					(_cAlTrb3)->ET3_TPBUSC := _cTipoBusca
					(_cAlTrb3)->ET3_CODKIT := mvCodKit
					(_cAlTrb3)->ET3_ETQPAL := _cIdPalete
					(_cAlTrb3)->(MsUnLock())

					// inclui o endereco selecionado
					(_cAlTrbMov)->(dbSelectArea(_cAlTrbMov))
					(_cAlTrbMov)->(dbSetOrder(1))
					If (_cAlTrbMov)->(dbSeek( _cCodProd + _cArmzAtual + _cEndAtual + _cIdPalete ))
						(_cAlTrbMov)->(RecLock(_cAlTrbMov))
						(_cAlTrbMov)->MOV_QUANT  += _nQtdSelec
						//(_cAlTrbMov)->MOV_FRAPLT := If( (_cAlTrbMov)->MOV_QUANT < (_cAlTrbMov)->MOV_SLDEND ,"S","N")
						(_cAlTrbMov)->(MsUnLock())
					Else
						(_cAlTrbMov)->(RecLock(_cAlTrbMov,.T.))
						(_cAlTrbMov)->MOV_PROD   := _cCodProd
						(_cAlTrbMov)->MOV_LOCAL  := _cArmzAtual
						(_cAlTrbMov)->MOV_ENDORI := _cEndAtual
						(_cAlTrbMov)->MOV_QUANT  := _nQtdSelec
						(_cAlTrbMov)->MOV_ENDDES := _cEndDest
						(_cAlTrbMov)->MOV_PALETE := _cIdPalete
						(_cAlTrbMov)->MOV_FRAPLT := _cFracPlt
						(_cAlTrbMov)->MOV_FRAVOL := _cFracVol
						(_cAlTrbMov)->MOV_CARGA  := _cNumCarga
						(_cAlTrbMov)->MOV_SEQ    := mvCntrlSeq
						(_cAlTrbMov)->MOV_VOLUME := ""
						(_cAlTrbMov)->MOV_CODKIT := mvCodKit
						(_cAlTrbMov)->(MsUnLock())
					EndIf

					// adiciona os detalhes no mapa de apanhe (utilizado na U_WMSA009B)
					If (_nPosReserv > 0)
						_aMapaApanhe[_nPosReserv][ 4] := (_cAlTrbMov)->MOV_QUANT
						_aMapaApanhe[_nPosReserv][ 7] := (_cAlTrbMov)->MOV_FRAPLT
						_aMapaApanhe[_nPosReserv][16] := (_cAlTrbMov)->MOV_QTSEGU
					Else
						aAdd(_aMapaApanhe,{(_cAlTrbMov)->MOV_PROD  , ;
						(_cAlTrbMov)->MOV_LOCAL , ;
						(_cAlTrbMov)->MOV_ENDORI, ;
						(_cAlTrbMov)->MOV_QUANT , ;
						(_cAlTrbMov)->MOV_ENDDES, ;
						(_cAlTrbMov)->MOV_PALETE, ;
						(_cAlTrbMov)->MOV_FRAPLT, ;
						(_cAlTrbMov)->MOV_SERORI, ;
						(_cAlTrbMov)->MOV_NFORI , ;
						(_cAlTrbMov)->MOV_ITEORI, ;
						(_cAlTrbMov)->MOV_SEQ   , ;
						(_cAlTrbMov)->MOV_NUMSEQ, ;
						(_cAlTrbMov)->MOV_VOLUME, ;
						(_cAlTrbMov)->MOV_LOTCTL, ;
						(_cAlTrbMov)->MOV_TPESTO ,;
						(_cAlTrbMov)->MOV_QTSEGU })
					EndIf

					// controle da sequencia
					mvCntrlSeq := Soma1(mvCntrlSeq)

					// atualiza saldo
					(_cAlTrbSC6)->(dbSelectArea(_cAlTrbSC6))
					(_cAlTrbSC6)->(dbSetOrder(1))
					(_cAlTrbSC6)->(dbSeek( _cCodProd ))
					(_cAlTrbSC6)->(RecLock(_cAlTrbSC6))
					(_cAlTrbSC6)->C6_SALDO -= _nQtdSelec
					(_cAlTrbSC6)->(MsUnLock())

					// pesquisa posicao do produto no vetor
					_nPosItPed := aScan(mvProdPedido,{|x| (x[1] == _cCodProd)})
					//atualiza saldo da variavel
					mvProdPedido[_nPosItPed][2] -= _nQtdSelec

					// reduz a quantidade necessaria por produto
					_aCompAgrup[_nComp][4] += _nQtdSelec
					_aCompAgrup[_nComp][5] -= _nQtdSelec

				Next _nComp

				// controle se deve mudar a busca, de palete completo para fracionado, quando sobrar saldo
				_lMudaBusca := .F.

				// calcula a quantidade total ja separada
				_nSaldoApanhe := 0
				// varre todos os componentes
				For _nComp := 1 to Len(_aCompAgrup)
					// acumulo do saldo total que falta coletar
					_nSaldoApanhe += _aCompAgrup[_nComp][5]
					// verifica necessidade de mudar a busca
					If (_cTipoBusca == "1") .And. (!_lMudaBusca) .And. (_aCompAgrup[_nComp][5] < _aCompAgrup[_nComp][6])
						_lMudaBusca := .T.
					EndIf
				Next _nComp

				If (_lDebug)
					MsgStop("_nSaldoApanhe final "+Str(_nSaldoApanhe))
				EndIf

				// define nova busca
				_lNovaBusca := (_nSaldoApanhe > 0)

				// verifica se deve mudar a logica de busca
				If (_lNovaBusca) .And. (_cTipoBusca == "1") .And. (_lMudaBusca)
					If (_lDebug)
						MsgSTop("_lNovaBusca")
					EndIf
					// sai do While de Enderecos
					Exit
				EndIf

			EndIf

			// proximo endereco
			(_cAlQry)->(dbSkip())
		EndDo

		If (_lDebug)
			MSgSTop("Altera tipo de Busca")
		EndIf

		// controle do tipo de busca
		// 1-Palete Completo
		// 2-Palete Fracionado
		// 3-Palete com Qualquer Quantidade
		_cTipoBusca := Soma1(_cTipoBusca)

		// encerra buscas
		If (_cTipoBusca == "4")
			_lNovaBusca := .F.
		EndIf

	EndDo

Return(_lKitOk)

// função para retornar a ordenação do número de série dos pedidos (cliente MIDEA) para ordenação do mapa de apanhe (SQL)
Static Function sfOrdSer(mvNumPed)

	local _cOrdem := ""
	local _cQryOrd := ""
	local _aPed := {}

	_cQryOrd := "SELECT C5_ZAGRUPA FROM " + RetSqlTab("SC5") + " WHERE " + RetSqlCond("SC5") + " AND C5_NUM IN  " + FormatIn(_cNumPed,"/") + " ORDER BY C5_ZAGRUPA"

	// obtem os pedidos
	_aPed := U_SqlToVet(_cQryOrd)

	// se o primeiro digito do primeiro pedido inicia com "4" (número da agrupadora), gera por LIFO (Cliente Midea)
	if ( SubStr( _aPed[1],1,1) == "4" )
		_cOrdem := "DESC"
	Else
		// se número da agrupadora inicia com "1", gera por FIFO (Cliente Midea)
		_cOrdem := "ASC"

	EndIf

Return (_cOrdem)

/*/{Protheus.doc} fBuscaEnd
Busca dados do endereços possíveis para alteração.
@author Luiz Fernando
@since 04/09/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
Static Function fBuscaEnd(mvTipEsto,mvArmzPadrao,mvProduto,aStruct,cTabela,cEndOri,cNotPallet)

	LOCAL _cQuery  := ""

	_cQuery := "SELECT "
	_cQuery += "   BF_PRODUTO, "
	_cQuery += "   BF_LOCAL, "
	_cQuery += "   BF_LOCALIZ, "
	_cQuery += "   BF_QUANT, "
	_cQuery += "   Z16_ETQPAL, "
	_cQuery += "   Z16_LOTCTL, "
	_cQuery += "   Z16_SALDO, "
	_cQuery += "   Z16_QTSEGU, "
	_cQuery += "   QTD_SKU, "
	_cQuery += "   BF_ESTFIS, "
	_cQuery += "   (SELECT DC8_TPESTR FROM " + RetSqlName("DC8") + " DC8 (NOLOCK) WHERE DC8.DC8_FILIAL = '" + xFilial("DC8") + "' AND DC8.DC8_CODEST = PALETES_DISPONIVEIS.BF_ESTFIS AND DC8.D_E_L_E_T_ = '' ) DC8_TPESTR "
	// se controla número de série
	IF (_lSerieAtv)
		_cQuery += ", Z16_DTSERI, QTD_DATA"
	EndIf
	_cQuery += " FROM ( "

	_cQuery += "SELECT "
	_cQuery += "   BF_PRODUTO, "
	_cQuery += "   BF_LOCAL, "
	_cQuery += "   BF_LOCALIZ, "
	_cQuery += "   BF_QUANT, "
	_cQuery += "   Z16_ETQPAL, "
	_cQuery += "   Z16_LOTCTL, "
	_cQuery += "   Sum(Z16_SALDO) Z16_SALDO, "
	_cQuery += "   Sum(Z16_QTSEGU) Z16_QTSEGU, "
	_cQuery += "   (SELECT Count(DISTINCT ( CASE WHEN SBFKIT.BF_ESTFIS IN ( '000002', '000010' ) THEN SBFKIT.BF_PRODUTO ELSE '000000' END )) "
	_cQuery += "   FROM   " + RetSqlName("SBF") + " SBFKIT (nolock)  "
	_cQuery += "   WHERE  SBFKIT.BF_FILIAL = '"+xFilial("SBF")+"' "
	_cQuery += "   AND SBFKIT.D_E_L_E_T_ = ' ' "
	_cQuery += "   AND SBFKIT.BF_LOCAL = SBF.BF_LOCAL "
	_cQuery += "   AND SBFKIT.BF_LOCALIZ = SBF.BF_LOCALIZ) QTD_SKU, "
	_cQuery += "   BF_ESTFIS "

	// se controla número de série
	IF (_lSerieAtv)
		// verifica também quantas DATAS de número de série possuem no mesmo endereço / palete
		_cQuery += " ,Z16_DTSERI,"
		_cQuery += " (SELECT COUNT(DISTINCT Z16_DTSERI) "
		_cQuery += "  FROM " + RetSqlName("Z16") + " Z16DATA WITH (INDEX (Z160103) NOLOCK) "
		_cQuery += "  WHERE Z16DATA.Z16_FILIAL      = '" + xFilial("Z16") + "' "
		_cQuery += "         AND Z16DATA.Z16_CODPRO = SBF.BF_PRODUTO "
		_cQuery += "         AND Z16DATA.Z16_LOCAL  = SBF.BF_LOCAL "
		_cQuery += "         AND Z16DATA.Z16_ENDATU = SBF.BF_LOCALIZ "
		_cQuery += "         AND Z16DATA.Z16_SALDO  > 0 "
		_cQuery += "         AND Z16DATA.D_E_L_E_T_ = '' ) QTD_DATA "
		// retorna a diferentes entre a menor a maior data no mesmo palete
		_cQuery += " ,(SELECT Datediff(DAY, CONVERT(VARCHAR(10), Min(Z16_DTSERI), 103), CONVERT(VARCHAR(10), Max(Z16_DTSERI), 103)) "
		_cQuery += "  FROM " + RetSqlName("Z16") + " Z16DIFF WITH (INDEX(Z160103) NOLOCK) "
		_cQuery += "  WHERE  Z16DIFF.Z16_FILIAL = '" + xFilial("Z16") + "' "
		_cQuery += "         AND Z16DIFF.Z16_CODPRO = SBF.BF_PRODUTO "
		_cQuery += "         AND Z16DIFF.Z16_LOCAL = SBF.BF_LOCAL "
		_cQuery += "         AND Z16DIFF.Z16_ENDATU = SBF.BF_LOCALIZ "
		_cQuery += "         AND Z16DIFF.D_E_L_E_T_ = '' "
		_cQuery += "         AND Z16DIFF.Z16_ETQPAL = Z16.Z16_ETQPAL "
		_cQuery += "         AND Z16DIFF.Z16_SALDO > 0)              DIF_DATA "
	EndIf

	// saldo por produto no endereco
	_cQuery += " FROM " + RetSqlTab("SBF") + " (NOLOCK) "
	// camposicao do palete
	_cQuery += " INNER JOIN "+RetSqlTab("Z16")+" (NOLOCK) ON " + RetSqlCond("Z16") + " AND Z16_CODPRO = BF_PRODUTO "
	// local e endereco
	_cQuery += " AND Z16_LOCAL = BF_LOCAL AND Z16_ENDATU = BF_LOCALIZ "
	// somente com saldo
	_cQuery += " AND Z16_SALDO > 0 "
	// tipo do estoque
	_cQuery += " AND Z16_TPESTO = '" + mvTipEsto + "' "
	// lote
	_cQuery += " AND Z16_LOTCTL = BF_LOTECTL "
	//filtro de endereços sob inventario
	_cQuery += " AND Z16_ENDATU NOT IN (SELECT Z21_LOCALI FROM " + RetSqlTab("Z21") + " (NOLOCK) WHERE " + RetSqlCond("Z21") + " AND Z21_PROD = BF_PRODUTO AND Z21_IDENT IN (SELECT Z06_NUMOS FROM " + RetSqlTab("Z06") + " (NOLOCK) WHERE Z06_FILIAL = Z21_FILIAL AND Z06_SERVIC = 'T02' AND Z06_NUMOS = Z21_IDENT AND D_E_L_E_T_ = '' AND Z06_STATUS NOT IN ('FI', 'CA'))) "
	//filtro de endereços cujos pallets ainda estão em OS de recebimento não finalizada (SERVIÇO 003 - RECEBIMENTO)
	_cQuery += " AND Z16_ETQPAL NOT IN (SELECT DISTINCT Z07_PALLET FROM " + RetSqlTab("Z07") + " (NOLOCK) WHERE " + RetSqlCond("Z07") + " AND Z07_PRODUT = BF_PRODUTO AND Z07_NUMOS IN (SELECT Z06_NUMOS FROM Z06010 (NOLOCK) WHERE Z06_FILIAL = Z07_FILIAL AND Z06_NUMOS = Z07_NUMOS AND D_E_L_E_T_ = '' AND Z06_SERVIC = '003' AND Z06_STATUS NOT IN ('FI','CA'))) "

	//Retira os Pallets
	_cQuery += " AND Z16_ETQPAL NOT IN "+FormatIN(cNotPallet,",")
	//filtra endereços origem e destino já reservados (exceto para expedição)
	_cQuery += " AND Z16_ENDATU NOT IN (
	_cQuery += " SELECT Z08_ENDDES AS 'END'   "
	_cQuery += " FROM  " + RetSqlTab("Z08") + " (NOLOCK)"
	_cQuery += " WHERE " + RetSqlCond("Z08")
	_cQuery += "  AND Z08_LOCAL = Z16_LOCAL"
	_cQuery += "  AND Z08_STATUS != 'R' "
	_cQuery += "  AND Z08_PRODUT = BF_PRODUTO "
	_cQuery += "  AND Z08_TPOPER != 'S' "
	_cQuery += " UNION ALL                    "
	_cQuery += " SELECT Z08_ENDORI AS 'END'   "
	_cQuery += " FROM  " + RetSqlTab("Z08") + " (NOLOCK)"
	_cQuery += " WHERE " + RetSqlCond("Z08")
	_cQuery += "  AND Z08_LOCAL = Z16_LOCAL  "
	_cQuery += "  AND Z08_PRODUT = BF_PRODUTO  "
	_cQuery += "  AND Z08_STATUS != 'R' "
	_cQuery += "  AND Z08_TPOPER != 'S') "

	// se controlar lote, ele vai pegar os endereços já estipulados no Z45 para o pedido informado
	If ( _lLotAtivo )
		If ( ! _lLotObrSai )
			_cQuery += "                AND Z16_ETQPAL IN (SELECT Z45_ETQPAL FROM "+RetSqlTab("Z45")+" (NOLOCK) WHERE "+RetSqlCond("Z45")+" AND Z45_PEDIDO IN "+FormatIn(_cNumPed,"/")+" ) "
		ElseIf ( _lLotObrSai ) .And. ( ! _lVolJaDef )
			_cQuery += "                AND Z16_LOTCTL = '" + mvLote + "' "
		EndIf
	Else
		// quando não controlar o lote, só busca pelos pallets que não possuem lote
		_cQuery += "                AND Z16_LOTCTL = ' ' "
	EndIf

	// quando os volumes ja foram definidos/selecionados no pedido de venda
	If ( _lVolJaDef )
		_cQuery += "                INNER JOIN " + RetSqlTab("Z45") + " (NOLOCK) "
		_cQuery += "                        ON " + RetSqlCond("Z45")
		_cQuery += "                           AND Z45_ETQPAL = Z16_ETQPAL "
		_cQuery += "                           AND Z45_CODPRO = Z16_CODPRO "
		_cQuery += "                           AND Z45_LOTCTL = Z16_LOTCTL "
		_cQuery += "                           AND Z16_ETQVOL = Z45_ETQVOL "
		_cQuery += "                           AND Z45_PEDIDO IN "+FormatIn(_cNumPed,"/")
	EndIf

	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("SBF")
	// produto
	_cQuery += " AND BF_PRODUTO = '"+mvProduto+"' "
	// quanto nao expede em kit, pega de varias estruturas fisiscas
	If ( ! _lExpEmKit )
		_cQuery += " AND BF_ESTFIS IN "+FormatIn(_cEstFisMapa,"/")+" "
		// quando controla volume, so expede produto unitario quanto for Picking
	ElseIf (_lExpEmKit)
		_cQuery += " AND BF_ESTFIS IN "+FormatIn(_cEstPicking,"/")+" "
	EndIf

	//Retira da consulta o endereço original
	_cQuery += " AND BF_LOCALIZ <> '"+cEndOri+"' "

	// controla saldo de enderecos que estao no plano de expedicao
	_cQuery += " AND BF_QUANT > (SELECT ISNULL(SUM(Z08_QUANT),0) FROM " + RetSqlTab("Z08") + " (NOLOCK) "
	// somente OS que NAO movimentou estoque (Z06_ATUEST = 'S' - deve atualizar estoque na movimentacao fisica da carga)
	_cQuery += " INNER JOIN "+RetSqlTab("Z06")+" (NOLOCK) ON "+RetSqlCond("Z06")+" AND Z06_NUMOS = Z08_NUMOS AND Z06_SEQOS = Z08_SEQOS "
	_cQuery += " AND Z06_ATUEST = 'S' "
	// filtro padrao do mapa
	_cQuery += " WHERE "+RetSqlCond("Z08")
	_cQuery += " AND Z08_STATUS IN ('P','M') AND Z08_LOCAL = BF_LOCAL "
	_cQuery += " AND Z08_ENDORI = BF_LOCALIZ "
	_cQuery += " AND Z08_PRODUT = BF_PRODUTO) "

	// descarta armazem A3
	_cQuery += " AND BF_LOCAL NOT IN ('A3') "

	// armazem padrao do cliente
	_cQuery += " AND BF_LOCAL = '" +mvArmzPadrao+ "' "

	// agrupa os dados
	_cQuery += "GROUP  BY BF_PRODUTO, "
	_cQuery += "          BF_LOCAL, "
	_cQuery += "          BF_LOCALIZ, "
	_cQuery += "          BF_QUANT, "
	_cQuery += "          Z16_ETQPAL, "
	_cQuery += "          Z16_LOTCTL, "
	_cQuery += "          BF_ESTFIS "
	// se controla número de série
	IF (_lSerieAtv)
		_cQuery += " ,Z16_DTSERI "
	EndIf

	_cQuery += ") AS PALETES_DISPONIVEIS "

	// apenas endereços não bloqueados
	_cQuery += " WHERE (SELECT BE_STATUS "
	_cQuery += "            FROM   " + RetSqlName("SBE") + " SBE (NOLOCK) "
	_cQuery += "            WHERE  SBE.BE_FILIAL = '" + xFilial("SBE") + "'"
	_cQuery += "                  AND SBE.D_E_L_E_T_ = '' "
	_cQuery += "                  AND SBE.BE_LOCAL = PALETES_DISPONIVEIS.BF_LOCAL "
	_cQuery += "                  AND SBE.BE_LOCALIZ = PALETES_DISPONIVEIS.BF_LOCALIZ) != 3 "

	// para cliente com controle de volumes, valida se expede em kit/agrupadora
	If (_lCtrVolume) .And. ( ! _lExpEmKit )
		_cQuery += " AND QTD_SKU = 1 "
	EndIf

	// se contola número de série pega a range de data de número de série conforme parâmetro TC_LIMISER
	If ( _lSerieAtv )
		_cQuery += " AND DIF_DATA <= " + cValToChar(_nRangeDt)
	Endif

	// ordem do endereco de busca
	_cQuery += " ORDER BY "
	_cQuery += " BF_LOCALIZ "

	memoWrit("C:\query\TWMSA019_fBuscaEnd_EndOri" + AllTrim(cEndOri) + "_" + FWTimeStamp(1,Date(),Time()) + ".txt",_cQuery)

	If Select("TRBEND")<> 0
		DBSelectArea("TRBEND")
		DBCloseArea()
	EndIf
	DBUseArea(.T.,"TOPCONN",TCGenQry(NIL,NIL,_cQuery),"TRBEND",.F.,.T.)

	Do While !TRBEND->(Eof())

		(cTabela)->(DBAppend(.F.))
		aEval(aStruct, {|aLinha|  (cTabela)->&(aLinha[1]):= IIf(aLinha[1]=="OK",Space(02), TRBEND->&(aLinha[1])) } )
		(cTabela)->(DBCommit())
		TRBEND->(DBSkip())
	EndDo
	(cTabela)->(DBGoTop())

Return

/*/{Protheus.doc} fAltEnd
Função para alteração do endereço do item selecionado.
@author Luiz Fernando Berti
@since 06/08/2019
@type function
@version 1.0
@param cTabela, characters, (nome Alias tabela de movimento.)
@param cTrbSC6, characters, (nome do Alias do cabeçalho)
@param cTrbET1, characters, (nome do Alias Enderecos Disponiveis COM Etiqueta)
@param cTrbET2, characters, (nome do alias Enderecos Disponiveis SEM Etiqueta)
@param mvArmzPadrao, characters, (armazém padrão)
@return ${return}, ${return nil}
/*/
Static Function fAltEnd(cTabela,cTrbSC6,cTrbET1,cTrbET2,mvArmzPadrao)

	LOCAL oWindow,oConfirm,oClose,oPanel1,oPanel2,oSelect,oSay, oSayQtd := nil
	LOCAL nFor    := 0
	LOCAL nOpc    := 0
	LOCAL oSize   := FwDefSize():New(.F.) //Sem enchoicebar
	LOCAL cTabTMP := GetNextAlias()
	LOCAL aStruct := {}
	LOCAL cMarca  := GetMark()
	LOCAL aHeader := {}
	LOCAL cTexto  := ""
	LOCAL cTitulo := "Alteração de endereço do Mapa de Apanhe."
	LOCAL oTabela := FWTemporaryTable():New(cTabTMP)
	LOCAL aStruct := {}
	LOCAL lTela   := .T.
	LOCAL cSeq    := "0001"
	LOCAL nRecSC6 := (cTrbSC6)->(Recno())
	LOCAL nRecMOV := (cTabela)->(Recno())
	LOCAL oFont   := TFont():New("Arial",,-12,.T.)
	LOCAL oFont1  := TFont():New('Arial',,-12,,.T.,,,,.T.,.F.,.F.)
	LOCAL oFont2  := TFont():New("Arial",,-22,.F.)
	LOCAL nQtdSel := 0 //Quantidade selecionada no mark.
	LOCAL aEnderecos := {}
	LOCAL cCdPallet := ""

	//Verifica se controla endereço no pedido de vendas, não permite alterar pela rotina rotina do mapa.
	If _lVolJaDef
		Aviso("Alteração de Endereço","Alteração de endereço não permitida, definido no Pedido de Vendas.",{"Fechar"})
		Return
	EndIf

	If Aviso("Alteração de Endereço","Deseja alterar o endereço do produto "+(cTabela)->MOV_PROD+"?",{"Sim","Não"}) == 2
		Return
	EndIf

	//Procura pela última sequencia, para gerar um novo item de remessa, quando o endereço por falterado.
	(cTabela)->(DBgoTop())
	cCdPallet := ""
	Do While !(cTabela)->(Eof())
		If cSeq < (cTabela)->MOV_SEQ
			cSeq :=  (cTabela)->MOV_SEQ
		EndIf

		//Inclui o número do pallet dos produtos para retirar da seleção dos registros.
		If Empty(cCdPallet)
			cCdPallet:= (cTabela)->MOV_PALETE
		Else
			cCdPallet+= ","+(+cTabela)->MOV_PALETE
		EndIf

		(cTabela)->(DBSkip())
	EndDo
	cSeq := Soma1(cSeq)

	(cTabela)->(DBGoTo(nRecMOV))

	//Localiza o pedido para gerar corretamente o movimento.
	(cTrbSC6)->(DBGoTop())
	Do While !(cTrbSC6)->(Eof())
		If (cTabela)->MOV_PROD == (cTrbSC6)->C6_PRODUTO
			Exit
		EndIf
		(cTrbSC6)->(DBSkip())
	EndDo

	//Campos para Header do grid
	aAdd(aHeader,{"OK"    ,"","  "        , ""     })
	aAdd(aHeader,{"BF_PRODUTO","",FWX3Titulo("BF_PRODUTO"),""})
	aAdd(aHeader,{"BF_LOCAL","",FWX3Titulo("BF_LOCAL"),""})
	aAdd(aHeader,{"BF_LOCALIZ","",FWX3Titulo("BF_LOCALIZ"),""})
	aAdd(aHeader,{"BF_QUANT","",FWX3Titulo("BF_QUANT"),""})
	aAdd(aHeader,{"Z16_ETQPAL","",FWX3Titulo("Z16_ETQPAL"),""})
	aAdd(aHeader,{"Z16_LOTCTL","",FWX3Titulo("Z16_LOTCTL"),""})
	aAdd(aHeader,{"Z16_SALDO","",FWX3Titulo("Z16_SALDO"),""})
	aAdd(aHeader,{"Z16_QTSEGU","",FWX3Titulo("Z16_QTSEGU"),""})
	aAdd(aHeader,{"QTD_SKU","","SKU",""})
	aAdd(aHeader,{"BF_ESTFIS","",FWX3Titulo("BF_ESTFIS"),""})
	aAdd(aHeader,{"DC8_TPESTR","",FWX3Titulo("DC8_TPESTR"),""})

	//Estruruta arquivo temporário.
	aAdd(aStruct,{"OK","C",2,0})
	aAdd(aStruct,{"BF_PRODUTO","C",TamSX3("BF_PRODUTO")[01],0})
	aAdd(aStruct,{"BF_LOCAL","C",TamSX3("BF_LOCAL")[01],0})
	aAdd(aStruct,{"BF_LOCALIZ","C",TamSX3("BF_LOCALIZ")[01],0})
	aAdd(aStruct,{"BF_QUANT","N",TamSX3("BF_QUANT")[01],TamSX3("BF_QUANT")[02]})
	aAdd(aStruct,{"Z16_ETQPAL","C",TamSX3("Z16_ETQPAL")[01],0})
	aAdd(aStruct,{"Z16_LOTCTL","C",TamSX3("Z16_LOTCTL")[01],0})
	aAdd(aStruct,{"Z16_SALDO","N",TamSX3("Z16_SALDO")[01],TamSX3("Z16_SALDO")[02]})
	aAdd(aStruct,{"Z16_QTSEGU","N",TamSX3("Z16_QTSEGU")[01],TamSX3("Z16_QTSEGU")[02]})
	aAdd(aStruct,{"QTD_SKU","N",TamSX3("Z16_QTSEGU")[01],TamSX3("Z16_QTSEGU")[02]})
	aAdd(aStruct,{"BF_ESTFIS","C",TamSX3("BF_ESTFIS")[01],0})
	aAdd(aStruct,{"DC8_TPESTR","C",TamSX3("DC8_TPESTR")[01],0})

	oTabela:SetFields(aStruct)
	oTabela:Create()

	//Busca por endereços aptos para alteração e popula no arquivo temporario.
	MsgRun("Localizando Endereços Aguarde...","Processando",{|| fBuscaEnd((cTrbSC6)->C6_ZTPESTO, mvArmzPadrao,(cTabela)->MOV_PROD,aStruct,cTabTMP,(cTabela)->MOV_ENDORI,cCdPallet) })

	nQtd := (cTabela)->MOV_QUANT

	//Monta a tela de seleção para os novos endereços.
	Do While lTela
		oWindow := MSDialog():New(oSize:aWindSize[1],oSize:aWindSize[2],oSize:aWindSize[3],oSize:aWindSize[4],cTitulo,,,.F.,,,,,,.T.,,,.T. )
		oWindow:lMaximized := .T.

		oPanel1 := TPanel():New(000,000,cTitulo,oWindow,,.F.,.F.,,,26,26,.T.,.F. )
		oPanel1:Align := CONTROL_ALIGN_TOP
		oConfirm := TButton():New(010,005,"Confirmar",oPanel1,{||nOpc := 1,oWindow:End()  },030,015,,,,.T.,,"",,,,.F. )
		oClose   := TButton():New(010,050,"Fechar",oPanel1,{|| nOpc:=0, lTela:= .F. ,oWindow:End() },030,015,,,,.T.,,"",,,,.F. )
		oSay     := TSay():New(012,100,{|| "Saldo:" },oPanel1,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,100,90)
		oSayQtd  := TSay():New(010,130,{|| nQtdSel },oPanel1,,oFont2,,,,.T.,CLR_RED,CLR_WHITE,100,90)

		oSayProd  := TSay():New(012,160,{|| "Produto Original: " },oPanel1,,oFont1,,,,.T.,CLR_BLACK,CLR_WHITE, 050, 100)
		oSayProd1 := TSay():New(012,210,{|| Alltrim((cTabela)->MOV_PROD)+" - Endereço: "+(cTabela)->MOV_ENDORI+" - Quantidade: "+cValToChar((cTabela)->MOV_QUANT) },oPanel1,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,280,100)

		oPanel2 := TPanel():New(000,000,cTitulo,oWindow,,.F.,.F.,,,120,250,.T.,.F. )
		oPanel2:Align := CONTROL_ALIGN_TOP

		oSelect := MsSelect():New((cTabTMP),"OK",,aHeader,,cMarca,{000,000,2000,2000},,,oPanel2,,{/*legenda*/})
		oSelect:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
		oSelect:bMark :=  {|| fMarcacao((cTabTMP),"OK",cMarca,@nQtdSel,nQtd),   oSayQtd:CtrlRefresh() }

		oWindow:lCentered := .T.
		oWindow:Activate()

		//Valida a quantidade
		If nOpc == 1 .And. (lTela := !fValSaldo(cTabTMP,nQtd))
			Aviso("Divergência de Quantidade.","A quantidade selecionada é menor que a quantidade do endereço original. Selecione um item com quantidade válida.",{"OK"})
		EndIf
	EndDo

	//Quanto confirmação.
	If nOpc == 1
		(cTabTMP)->(DBGoTop())
		//Inclui os registros marcados para ordenar.
		Do While !(cTabTMP)->(Eof())
			If (cTabTMP)->OK == cMarca
				aAdd(aEnderecos,{(cTabTMP)->Z16_ETQPAL,;//01
				(cTabTMP)->Z16_LOTCTL,;//02
				(cTabTMP)->BF_LOCAL,;//03
				(cTabTMP)->BF_LOCALIZ,;//04
				(cTabTMP)->Z16_SALDO,;//05
				(cTabTMP)->BF_QUANT,;//06
				(cTabTMP)->Z16_QTSEGU})//07
			EndIf
			(cTabTMP)->(DBSkip())
		EndDo
		(cTabTMP)->(DBGoTop())

		//Ordena os endereços pela quantidade do itens.
		aEnderecos:= AClone(ASort(aEnderecos,,,{|x,y| x[05] < y[05] }))

		//Inclui os novos endereços no arquivo temporário.
		For nFor := 1 To Len(aEnderecos)
			// adiciona log
			aAdd(_aTrocaMapa, "Produto " +  Alltrim((cTabela)->MOV_PROD) + " alterado no mapa de apanhe - " + AllTrim((cTabela)->MOV_ENDORI) + " para " + AllTrim(aEnderecos[nFor][4]) )

			If nQtd > 0
				_cFracPlt   := "N"
				_cIdPalete  := aEnderecos[nFor][01]//(cTabTMP)->Z16_ETQPAL
				_cLoteCTL   := aEnderecos[nFor][02]//(cTabTMP)->Z16_LOTCTL
				_cArmzAtual := aEnderecos[nFor][03]//(cTabTMP)->BF_LOCAL
				_cEndAtual  := aEnderecos[nFor][04]//(cTabTMP)->BF_LOCALIZ
				_nSldPltAtu := aEnderecos[nFor][05]//(cTabTMP)->Z16_SALDO
				_nSaldoEnd  := aEnderecos[nFor][06]//(cTabTMP)->BF_QUANT
				_nQtdSegum  := aEnderecos[nFor][07]//(cTabTMP)->Z16_QTSEGU
				nVlrItm     := 0

				//Valida os saldos do item com as novas seleções.
				If _nSldPltAtu > nQtd
					nQtdeItm  := nQtd
					_cFracPlt := "S"
				Else
					nQtdeItm := _nSldPltAtu
				EndIf
				nQtd-=nQtdeItm

				RecLock(cTabela,.T.)
				(cTabela)->MOV_PROD   := (cTrbSC6)->C6_PRODUTO
				(cTabela)->MOV_LOCAL  := _cArmzAtual
				(cTabela)->MOV_ENDORI := _cEndAtual
				(cTabela)->MOV_QUANT  := nQtdeItm
				(cTabela)->MOV_QTSEGU := ConvUM((cTrbSC6)->C6_PRODUTO, nQtdeItm, _nQtdSegum, 2)
				(cTabela)->MOV_ENDDES := _cEndDest
				(cTabela)->MOV_PALETE := _cIdPalete
				(cTabela)->MOV_FRAPLT := _cFracPlt
				(cTabela)->MOV_CARGA  := _cNumCarga
				(cTabela)->MOV_SERORI := (cTrbSC6)->C6_SERIORI
				(cTabela)->MOV_NFORI  := (cTrbSC6)->C6_NFORI
				(cTabela)->MOV_ITEORI := (cTrbSC6)->C6_ITEMORI
				(cTabela)->MOV_NUMSEQ := (cTrbSC6)->D1_NUMSEQ
				(cTabela)->MOV_SEQ    := cSeq
				(cTabela)->MOV_VOLUME := ""
				(cTabela)->MOV_LOTCTL := (cTrbSC6)->C6_LOTECTL
				(cTabela)->MOV_TPESTO := (cTrbSC6)->C6_ZTPESTO
				MsUnLock()
				cSeq := Soma1(cSeq)
			EndIf
		Next

		(cTabela)->(DBGoTo(nRecMOV))//Volta o ponteiro para o registro original.

		//Exclui o movimento anterior, quando houve alteração do endereço
		(cTrbET1)->(DBGoTop())
		Do While !(cTrbET1)->(Eof())
			If (cTrbET1)->ET1_SEQ == (cTabela)->MOV_SEQ
				RecLock(cTrbET1,.F.)
				(cTrbET1)->(DBDelete())
				MSUnLock()
			EndIf
			(cTrbET1)->(DBSkip())
		EndDo
		(cTrbET2)->(DBGoTop())
		
		Do While !(cTrbET2)->(Eof())
			If (cTrbET2)->ET2_SEQ == (cTabela)->MOV_SEQ
				RecLock(cTrbET2,.F.)
				(cTrbET2)->(DBDelete())
				MSUnLock()
			EndIf
			(cTrbET2)->(DBSkip())
		EndDo

		//Exclui o registro do movimento anterior, pois, na mudança de endereço de destino é cirado um ou maais.
		RecLock(cTabela,.F.)
		(cTabela)->(DBDelete())
		MSUnlock()
		(cTabela)->(DBGoTop())

		//Altera o conteúdo do array para ser usado na rotina WMSA009B, incluíndo os endereços substituídos.
		_aMapaApanhe := {}
		(cTabela)->(DBGoTop())
		Do While !(cTabela)->(Eof())
			aAdd(_aMapaApanhe,{(cTabela)->MOV_PROD  , ;
			(cTabela)->MOV_LOCAL , ;
			(cTabela)->MOV_ENDORI, ;
			(cTabela)->MOV_QUANT , ;
			(cTabela)->MOV_ENDDES, ;
			(cTabela)->MOV_PALETE, ;
			(cTabela)->MOV_FRAPLT, ;
			(cTabela)->MOV_SERORI, ;
			(cTabela)->MOV_NFORI , ;
			(cTabela)->MOV_ITEORI, ;
			(cTabela)->MOV_SEQ   , ;
			(cTabela)->MOV_NUMSEQ, ;
			(cTabela)->MOV_VOLUME, ;
			(cTabela)->MOV_LOTCTL, ;
			(cTabela)->MOV_TPESTO ,;
			(cTabela)->MOV_QTSEGU })

			(cTabela)->(DBSkip())
		EndDo
		(cTabela)->(DBGoTop())

		If nQtd >0
			Aviso("Saldo Faltante","Favor escolher um item que contemple o saldo total do item a ser substituido. Faltante: "+cValToChar(nQtd))
		EndIf
	EndIf

	oTabela:Delete()
	(cTrbSC6)->(DBGoTo(nRecSC6))
Return

/*/{Protheus.doc} fMarcacao
Função auxiliar para controlar a quantidade selecionada dos itens.
@author Luiz Fernando
@since 06/09/2019
@version 1.0
@param cTabela, characters, arquivo temporário
@param cCampo, characters, campo que armazena a marcação
@param cMarca, characters, conteúdo para o campo de marcação
@param nQtde, numeric, quantidade total da selação dos itens.
@param nQtdOri, numeric, quantidade do endereço original.
@type function
@return ${return}, ${nil}
/*/
Static Function fMarcacao(cTabela, cCampo, cMarca,nQtde,nQtdOri)

	//Valida se a quantidade selecionada atingiu a quantidade necess´paria original.
	If (cTabela)->(&cCampo) == cMarca .And.  nQtde >= nQtdOri
		RecLock(cTabela,.F.)
		(cTabela)->(&cCampo) := Space(02)
		MSUnlock()
		Aviso("Saldo","A seleção já contemplou o saldo do item.",{"Sair"})
		Return
	EndIf

	//Atualiza a variável de tela com os saldos dos itens.
	If (cTabela)->(&cCampo) == cMarca
		nQtde+= (cTabela)->Z16_SALDO
	Else
		nQtde-= (cTabela)->Z16_SALDO
	EndIf
Return

/*/{Protheus.doc} fValSaldo
Função para validar o saldo selecionado.
@author Luiz Fernando
@since 05/09/2019
@version 1.0
@param cTabela, characters, descricao
@param nQtde, numeric, descricao
@type function
@return ${return}, ${return_description}
/*/
Static Function fValSaldo(cTabela,nQtde)

	LOCAL nQtSld := 0
	(cTabela)->(DBGoTop())

	Do While !(cTabela)->(Eof())
		If !Empty((cTabela)->OK)
			nQtSld += (cTabela)->Z16_SALDO
		EndIf
		(cTabela)->(DBSkip())
	EndDo
	(cTabela)->(DBGoTop())

Return(nQtde<=nQtSld)