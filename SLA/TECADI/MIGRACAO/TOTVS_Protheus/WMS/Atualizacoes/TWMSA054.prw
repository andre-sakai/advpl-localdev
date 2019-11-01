#include 'protheus.ch'
#Include "TopConn.ch"

/*/{Protheus.doc} TWMSA054
Função destinada a transferir saldo de um ou *TODOS* os produtos de um determinado cliente para um endereço de expedição.
O objetivo é facilitar a emissão do pedido de venda/nota fiscal de retorno de armazenagem, para questões de finalização de contrato, troca de inventário ou algo do tipo.

Requisitos: WMS Inativo 
			Saldo fiscal e no endereço em conformidade 
			Não existir pedido em aberto
			Não existir pendencia de endereçamento
			Não existir pendencia de recebimento
@type function
@author Bruno Seára
@since 18/08/2019
/*/

User function TWMSA054()

	LOCAL aSays    := {}
	LOCAL aButtons := {}
	LOCAL cPerg    := {}
	LOCAL cCab     := "Transferência de saldo fiscal total para um único endereço"

	private oProcess := MsNewProcess():New({|| fProcessa(oProcess)}, "Processando...", "Aguarde...", .T.)

	// corpo da janela
	aadd(aSays,"Esta rotina fará a transferência do SALDO TOTAL dos produtos")
	aadd(aSays,"do cliente para endereço de preparação para expedição sem WMS")
	aadd(aSays,"ATENÇÃO: Caso parâmetro PRODUTO em branco, fará o processamento de TODOS os produtos.")

	// botões de ação
	aadd(aButtons, { 5,.T.,{||  Pergunte("TWMSA054", .T. ) } } )
	aadd(aButtons, { 1,.T.,{||  oProcess:Activate() }} )
	aadd(aButtons, { 2,.T.,{||  FechaBatch() }} )

	// Estrutura pergunte TWMSA054
	// MV_PAR01 - CLIENTE
	// MV_PAR02 - LOJA
	// MV_PAR03 - PRODUTO *** SE FOR EM BRANCO, FAZ TODOS OS PRODUTOS ****

	// abre janela
	FormBatch( cCab, aSays, aButtons)

Return

Static Function fProcessa(oProcObj)

	Local _cQuery 		:= ""
	Local _lWmsAtivo 	:= .F.
	Local _cProduto 	:= ""
	Local _cCliente 	:= ""
	Local _cLojaCli		:= ""
	Local _cSiglaCli 	:= ""
	Local _cNomeCli		:= ""
	Local _nRetQry 		:= 0
	Local _nTotalSBF	:= 0
	Local _nAtualSBF	:= 0
	Local _aCliente 	:= {}
	Local _cEndDesti	:= "EXPEDICAO"
	Local _cArmDesti	:= "01"
	Local _aItemSD3, _aTmpItem := {}

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	_cCliente := MV_PAR01
	_cLojaCli := MV_PAR02
	_cProduto := MV_PAR03

	_cQuery := ""
	_cQuery := " SELECT A1_COD, "
	_cQuery += "        A1_LOJA, "
	_cQuery += "        A1_SIGLA, "
	_cQuery += "        A1_NOME "
	_cQuery += " FROM " + RetSqlTab("SA1") + " (NOLOCK) "
	_cQuery += " WHERE " + RetSqlCond("SA1")
	_cQuery += " 		AND A1_COD = '" + AllTrim(_cCliente) + "' "
	_cQuery += "        AND A1_MSBLQL = 2 "

	MemoWrit("C:\Query\TWMSA054_query_cliente.txt", _cQuery)

	_aCliente := U_SqlToVet(_cQuery)

	If (Len(_aCliente) == 0)
		Alert("Processo abortado" + CRLF + "Cliente informado não encontrado.")
		Return
	Endif

	_cCliente  := _aCliente[1][1]
	_cLojaCli  := _aCliente[1][2]
	_cSiglaCli := _aCliente[1][3]
	_cNomeCli  := _aCliente[1][4]

	// verifica se o WMS esta ativo
	_lWmsAtivo := U_FtWmsParam("WMS_ATIVO_POR_CLIENTE", "L", .F. , .F., Nil, _cCliente, _cLojaCli, Nil, Nil)

	// Query para verificar se existe saldo em endereços diferentes de 2 - PP, 10 - Picking, 15 - Container, 7 - BLOCO
	_cQuery := " SELECT Count(*) "
	_cQuery += " FROM "  + RetSqlTab("SBF") + " (NOLOCK) "
	_cQuery += " WHERE " + RetSqlCond("SBF")
	If !(Empty(_cProduto)) // Se o produto foi informado nos parâmetros
		_cQuery += " AND BF_PRODUTO = '" + AllTrim(_cProduto) + "' "
	Else
		// Se não foi informado o produto, pega TODOS os produtos com base na sigla do cliente
		_cQuery += " AND Substring(BF_PRODUTO, 1, 4) = '" + AllTrim(_cSiglaCli) + "' "
	Endif
	_cQuery += " AND BF_ESTFIS NOT IN ( '000002', '000010', '000015', '000007' ) "

	MemoWrit("C:\Query\TWMSA054_query_SBF_EndTran.txt", _cQuery)

	_nRetQry := U_FTQuery(_cQuery)

	//se retornar maior que zero, aborta, pois as pendencias devem ser resolvidas
	If (_nRetQry > 0)
		MsgAlert("Falha no processamento, existe saldo em DOCA, RUA ou outro endereço de transição." + CRLF + "Verifique possíveis pendências de carregamento.", "TWMSA054 - Processo abortado.")
		Return
	EndIf

	_cQuery := ""
	_cQuery := " SELECT Count(*) "
	_cQuery += " FROM "  + RetSqlTab("SDA") + " (NOLOCK) "
	_cQuery += " WHERE " + RetSqlCond("SDA")
	_cQuery += " 		AND DA_CLIFOR = '" + _cCliente + "' "
	_cQuery += "        AND DA_SALDO > 0 "
	If !(Empty(_cProduto))
		_cQuery += "        AND DA_PRODUTO = '" + AllTrim(_cProduto) + "' "
	Else
		_cQuery += "        AND Substring(DA_PRODUTO, 1, 4) = '" + AllTrim(_cSiglaCli) + "' "
	Endif

	MemoWrit("C:\Query\TWMSA054_query_SDA_saldo.txt", _cQuery)

	_nRetQry := U_FTQuery(_cQuery)

	//se retornar maior que zero, aborta, pois as pendencias devem ser resolvidas
	If (_nRetQry > 0)
		MsgAlert("Falha no processamento, existe saldo a endereçar." + CRLF + "Verifique possíveis pendências de endereçamento ou exclua a NF.", "TWMSA054 - Processo abortado.")
		Return
	EndIf

	_cQuery := " SELECT SB6.B6_PRODUTO 					 B6_PRODUTO, "
	_cQuery += "        Sum(SB6.B6_SALDO)                B6_SALDO, "
	_cQuery += "        (SELECT DISTINCT( SBF.BF_PRODUTO ) "
	_cQuery += "         FROM " + RetSqlTab("SBF") + " WITH (INDEX (SBF0102) NOLOCK) "
	_cQuery += "         WHERE  BF_FILIAL = SB6.B6_FILIAL "
	_cQuery += "                AND SBF.BF_PRODUTO = SB6.B6_PRODUTO "
	_cQuery += "                AND SBF.D_E_L_E_T_ = '') BF_PRODUTO, "
	_cQuery += "        (SELECT DISTINCT( Sum(BF_QUANT) ) "
	_cQuery += "         FROM " + RetSqlTab("SBF") + " WITH (INDEX (SBF0102) NOLOCK) "
	_cQuery += "         WHERE  BF_FILIAL = SB6.B6_FILIAL "
	_cQuery += "                AND SBF.BF_PRODUTO = SB6.B6_PRODUTO "
	_cQuery += "                AND SBF.D_E_L_E_T_ = '') BF_QUANT "
	_cQuery += " FROM  " + RetSqlTab("SB6") + " (NOLOCK) "
	_cQuery += " WHERE  " + RetSqlCond("SB6")
	If !(Empty(_cProduto))
		_cQuery += " 	AND SB6.B6_PRODUTO = '" + AllTrim(_cProduto) + "' "
	Else
		_cQuery += " 	AND SUBSTRING(SB6.B6_PRODUTO,1,4) = '" + AllTrim(_cSiglaCli) + "' "
	Endif
	_cQuery += "        AND SB6.B6_CLIFOR = '" + _cCliente + "' "
	_cQuery += "        AND SB6.B6_LOJA = '" + _cLojaCli + "' "
	_cQuery += "        AND SB6.B6_PODER3 = 'R' "
	_cQuery += "        AND B6_SALDO > 0 "
	_cQuery += " GROUP  BY SB6.B6_FILIAL, "
	_cQuery += "           SB6.B6_PRODUTO "

	MemoWrit("C:\Query\TWMSA054_query_SBF_SB6_saldo.txt", _cQuery)

	// cria arquivo temporário
	If Select("TRBSB6") <> 0
		DBSelectArea("TRBSB6")
		DBCloseArea()
	EndIf

	TcQuery _cQuery New Alias "TRBSB6"
	DbSelectArea("TRBSB6")

	If Select("TRBSB6") == 0
		DBCloseArea()
		MsgAlert("FALHA: Nenhum endereço / saldo fiscal encontrado para o produto selecionado.", "FALHA")
		Return
	EndIf
	
	// posiciona no primeiro registro
	TRBSB6->( dbGotop() )

	// percorre todos os pallets até o final
	Do While !TRBSB6->( Eof() )
		If !(TRBSB6->B6_PRODUTO == TRBSB6->BF_PRODUTO)
			MsgAlert("Falha no processamento." + CRLF + "O saldo fiscal do produto " + TRBSB6->B6_PRODUTO + " diverge do produto endereçado." + CRLF + "Produto endereçado: " + TRBSB6->BF_PRODUTO, "TWMSA054 - Processo abortado.")
			Return
		Elseif !(TRBSB6->B6_SALDO == TRBSB6->BF_QUANT)
			MsgAlert("Falha no processamento." + CRLF + "O saldo fiscal do produto " + TRBSB6->B6_PRODUTO + " diverge do saldo endereçado." + CRLF + "Saldo Fiscal: " + cValToChar(TRBSB6->B6_SALDO) + CRLF + "Saldo endereçado: " + cValToChar(TRBSB6->BF_QUANT), "TWMSA054 - Processo abortado.")
			Return
		Endif
		TRBSB6->(DBSkip())
	Enddo

	_cQuery := ""
	_cQuery := " SELECT BF_PRODUTO, "
	_cQuery += "        BF_LOCAL, "
	_cQuery += "        BF_LOCALIZ, "
	_cQuery += "        BF_QUANT,
	_cQuery += "        BF_QTSEGUM, "
	_cQuery += "        BF_LOTECTL, "
	_cQuery += "        BF_ESTFIS "
	_cQuery += " FROM " + RetSqlTab("SBF") + " WITH (INDEX(SBF0102) NOLOCK) "
	_cQuery += " WHERE " + RetSqlCond("SBF")
	If !(Empty(_cProduto))
		_cQuery += "       AND BF_PRODUTO = '" + AllTrim(_cProduto) + "' "
	Else
		_cQuery += " 	   AND SUBSTRING(BF_PRODUTO,1,4) = '" + AllTrim(_cSiglaCli) + "' "
	Endif
	_cQuery += " 	   AND BF_QUANT > 0 "
	_cQuery += " 	   AND BF_ESTFIS IN ( '000002', '000010', '000015', '000007' ) "

	MemoWrit("C:\Query\TWMSA054_query_SBF_saldo.txt", _cQuery)

	// cria arquivo temporário
	If Select("TRBSBF") <> 0
		DBSelectArea("TRBSBF")
		DBCloseArea()
	EndIf

	TcQuery _cQuery New Alias "TRBSBF"
	DbSelectArea("TRBSBF")

	If Select("TRBSBF") == 0
		DBCloseArea()
		MsgAlert("FALHA: Nenhum endereço encontrado para o produto selecionado.", "FALHA")
		Return
	EndIf

	// seta regua primária
	Count to _nTotalSBF
	oProcObj:SetRegua2(_nTotalSBF)

	// posiciona no primeiro registro
	TRBSBF->( DbGoTop() )

	// abre transação
	Begin Transaction

		// Se estiver com WMS ativo, aborta.
		If (_lWmsAtivo)
			If !(MsgYesNo("Não é possível continuar, pois o cliente possui WMS ativo. Deseja inativar e continuar?", "WMS Ativo"))
				DisarmTransaction()
				Return
			Else
				_cQuery := " UPDATE Z30010 "
				_cQuery += " SET    Z30_CONTEU = '.F.' "
				_cQuery += " WHERE  Z30_CODCLI = '" + _cCliente + "' "
				_cQuery += "        AND Z30_LOJCLI = '" + _cLojaCli + "' "
				_cQuery += "        AND Z30_PARAM = 'WMS_ATIVO_POR_CLIENTE' "
				_cQuery += "        AND D_E_L_E_T_ = '' "

				// verifica se deu erro no comando update
				If TCSQLExec(_cQuery) < 0
					DisarmTransaction()
					Alert("Falha ao desabilitar o WMS do cliente " + _cCliente + " / " + _cLojaCli )
					Break
				EndIf
			Endif
		Endif

		// percorre todos os pallets até o final
		Do While !TRBSBF->( Eof() )

			// Atualiza arquivo de saldos em estoque
			dbSelectArea("SB2")
			SB2->(DbSetOrder(1)) // 1-B2_FILIAL, B2_COD, B2_LOCAL
			If ! SB2->(dbSeek( xFilial("SB2") + TRBSBF->BF_PRODUTO + TRBSBF->BF_LOCAL ))
				// cria registro do produto no armazem de destino
				CriaSB2(TRBSBF->BF_PRODUTO, TRBSBF->BF_LOCAL)
			EndIf

			// chama o grupo de perguntas padrao da rotina MATA260
			pergunte("MTA260",.F.)

			// zera variaveis
			_aItemSD3 := {}
			_aTmpItem := {}

			_aItemSD3 := {{NextNumero("SD3",2,"D3_DOC",.T.), Date() }}

			// posiciona no cadastro de produtos
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
			SB1->(dbSeek( xFilial("SB1") + TRBSBF->BF_PRODUTO ))

			// calcula 2ª UM correta
			If !Empty(SB1->B1_TIPCONV)
				If (SB1->B1_TIPCONV == "D")  // se divide
					nSaldo2 := TRBSBF->BF_QUANT / SB1->B1_CONV
				Else  // se multiplica
					nSaldo2 := TRBSBF->BF_QUANT * SB1->B1_CONV
				EndIf
			Else
				nSaldo2 := 0
			EndIf

			_aTmpItem := { {"D3_COD"		, TRBSBF->BF_PRODUTO	,Nil},;
			{"D3_DESCRI"	, SB1->B1_DESC		,Nil},;
			{"D3_UM"		, SB1->B1_UM		,Nil},;
			{"D3_LOCAL"		, TRBSBF->BF_LOCAL 	,Nil},;  // armazem transitorio (lançamento nf)
			{"D3_LOCALIZ"	, TRBSBF->BF_LOCALIZ,Nil},;  // endereço transitorio
			{"D3_COD"		, TRBSBF->BF_PRODUTO,Nil},;
			{"D3_DESCRI"	, SB1->B1_DESC		,Nil},;
			{"D3_UM"		, SB1->B1_UM		,Nil},;
			{"D3_LOCAL"		, _cArmDesti		,Nil},;  // armazem final
			{"D3_LOCALIZ"	, _cEndDesti		,Nil},;  // endereço final
			{"D3_NUMSERI"	, ""				,Nil},;
			{"D3_LOTECTL"	, TRBSBF->BF_LOTECTL,Nil},;
			{"D3_NUMLOTE"	, ""				,Nil},;
			{"D3_DTVALID"	, ""	            ,Nil},;
			{"D3_POTENCI"	, 0  				,Nil},;
			{"D3_QUANT"		, TRBSBF->BF_QUANT 	,Nil},;
			{"D3_QTSEGUM"	, TRBSBF->BF_QTSEGUM,Nil},;
			{"D3_ESTORNO"	, ""				,Nil},;
			{"D3_NUMSEQ"	, ""				,Nil},;
			{"D3_LOTECTL"	, TRBSBF->BF_LOTECTL,Nil},;
			{"D3_NUMLOTE"	, ""				,Nil},;
			{"D3_DTVALID"	, ""            	,Nil},;
			{"D3_ZNUMOS"	, ""     			,Nil},;
			{"D3_ZSEQOS"	, ""				,Nil},;
			{"D3_ZETQPLT"	, "" 				,Nil},;
			{"D3_ZCARGA"	, ""				,Nil},;
			{"D3_ZPEDIDO"	, ""				,Nil},;
			{"D3_ZITPEDI"	, ""				,Nil}}

			// adiciona o item
			aAdd(_aItemSD3, _aTmpItem)

			// variaveis padroes da rotina automatica
			lMsHelpAuto := .T.
			lMsErroAuto := .F.

			// executa rotina automatica
			MsExecAuto({|x,y|MATA261(x,y)}, _aItemSD3, 3) // 3 - transferencia

			// se deu erro
			If (lMsErroAuto)
				DisarmTransaction()
				Alert("Erro Execauto transferencia para EXPEDICAO" )
				Break
			Endif

			_nAtualSBF++
			oProcObj:IncRegua2("Gerando transf. (SBF) - " + cValToChar(_nAtualSBF) + " de " + cValToChar(_nTotalSBF) + "...")

			TRBSBF->(DBSkip())
		Enddo
	End Transaction

	/***********************************
	* TODO - ao finalizar o processo, gerar o pedido de venda e liberar
	***********************************/

	MsgInfo(Iif(_cProduto == "","Produtos","Produto " + AllTrim(_cProduto)) + " transferidos com sucesso." + CRLF + "Cliente " + _cCliente + " - " + AllTrim(_cNomeCli) )

Return