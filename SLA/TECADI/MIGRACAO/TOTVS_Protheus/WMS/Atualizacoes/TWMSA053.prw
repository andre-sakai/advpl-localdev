#include 'protheus.ch'
#Include "TopConn.ch"

User function TWMSA053()

	LOCAL aSays    := {}
	LOCAL aButtons := {}
	LOCAL cPerg    := {}
	LOCAL cCab     := "Troca de estoque fiscal com reaproveitamento de endereçamento WMS"
	Local oProcess := MsNewProcess():New({|| fProcessa(oProcess)}, "Processando...", "Aguarde...", .T.)
	Private _cCodCli := ""
	Private _cLojCli := ""
	Private _cDoc    := ""
	Private _cSerie  := ""

	// corpo da janela
	aadd(aSays,"Esta rotina fará a troca fiscal dos produtos em estoque,")
	aadd(aSays,"Permitindo a troca de código do produto e aproveitando o endereçamento")
	aadd(aSays,"WMS existente.")

	// botões de ação
	aadd(aButtons, { 5,.T.,{||  Pergunte("TWMSA053", .T. ) } } )
	aadd(aButtons, { 1,.T.,{||  sfValida(oProcess), FechaBatch() }} )
	aadd(aButtons, { 2,.T.,{||  FechaBatch() }} )

	// abre janela
	FormBatch( cCab, aSays, aButtons)

Return


// função auxiliar para validações antes do processamento
Static Function sfValida(oProcObj)

	local _lContinua := .T.
	Local cQuery := ""
	Local _cSeekSD1 := ""
	Local cCodAntigo := ""
	Local nRetQry := 0

	DBSelectArea("SF1")
	DBSelectArea("SD1")
	DBSelectArea("SDA")
	DBSelectArea("Z16")
	SF1->(DBSetOrder(01))//F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
	SD1->(DBSetOrder(01))//D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
	SDA->(DBSetOrder(01))//DA_FILIAL+DA_PRODUTO+DA_LOCAL+DA_NUMSEQ+DA_DOC+DA_SERIE+DA_CLIFOR+DA_LOJA

	// Estrutura pergunte TWMSA053
	_cCodCli := MV_PAR01 // MV_PAR01 - codigo cliente
	_cLojCli := MV_PAR02 // MV_PAR02 - loja cliente
	_cDoc    := MV_PAR03 // MV_PAR03 - nota fiscal
	_cSerie  := MV_PAR04 // MV_PAR04 - série nota fiscal


	// TODO - validar se tem pedido de venda em aberto


	// posiciona na nota fiscal
	If SD1->(MSSeek(_cSeekSD1 := xFilial("SD1") + _cDoc + _cSerie + _cCodCli + _cLojCli))
		// percorre itens da nota fiscal e vai validando
		Do While !SD1->( EOF() ) .AND. ( SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == _cSeekSD1)

			// posiciona no registro da SDA
			If SDA->(MSSeek(xFilial("SDA") + SD1->(D1_COD+D1_LOCAL+D1_NUMSEQ)))

				// valida se possui saldo a endereçar
				If (SDA->DA_SALDO <= 0)
					MsgAlert("Falha no processamento da nota fiscal " + SDA->DA_DOC + CRLF + " Nota Fiscal ou produto não possui saldo a endereçar." + CRLF + "Verifique se a nota foi classificada ou já foi distribuída." + CRLF + "Produto: " + SDA->DA_PRODUTO, "Distribuição de saldos TECADI")
					_lContinua := .F.
					Exit  // sai do While
				EndIf

				// pesquisa se houve troca de código (SKU)
				cQuery := "SELECT IsNull(CODIGO_ANTIGO,'') FROM TWMSA053 (NOLOCK) WHERE CODCLI = '"+_cCodCli+"' AND LOJACLI = '"+_cLojCli+"' AND CODIGO_NOVO = '"+AllTrim(SDA->DA_PRODUTO)+"'"

				// guarda o codigo antigo na variável, para usar no update
				cCodAntigo := U_FTQuery(cQuery)

				// se em branco/nulo, então não teve troca de código... guarda o mesmo código do produto na variável (ficando ANTIGO = NOVO na lógica)
				If Empty(cCodAntigo)
					cCodAntigo := SDA->DA_PRODUTO
				EndIf


				/******* VALIDAÇÃO ******************************************
				/ saldo de etiquetas Z16, será utilizado para comparação com a NF de entrada
				/ se saldo de etiquetas maior que quantidade recebida na NF, aborta o processo e verifica as pendencias (carregamento / pedidos)
				*************************************************************/

				cQuery := " SELECT IsNull(Sum(Z16.Z16_SALDO),0) AS Z16_SALDO "
				cQuery += " FROM " + RetSqlTab("Z16")
				cQuery += " 	   INNER JOIN " + RetSqlTab("SBE") + " (NOLOCK) "
				cQuery += " 	   		   ON " + RetSqlCond("SBE")
				cQuery += "                   AND SBE.BE_LOCALIZ = Z16.Z16_ENDATU "
				cQuery += "                   AND SBE.BE_FILIAL = Z16.Z16_FILIAL "
				cQuery += "                   AND SBE.BE_LOCAL = Z16.Z16_LOCAL "
				cQuery += "                   AND SBE.BE_ESTFIS IN ( '000002','000010','000007','000015' ) " // 2 - PP, 10 - PICKING, 7 - BLOCO, 15 - CONTAINER
				cQuery += " WHERE " + RetSqlCond("Z16")
				cQuery += "        AND Z16.Z16_SALDO > 0
				cQuery += "        AND Z16.Z16_CODPRO = '" + cCodAntigo + "' "

				MemoWrit("C:\query\twmsa053_qtd_z16.txt", cQuery )

				nRetQry := U_FTQuery(cQuery)

				//se a quantidade obtida dos pallets for MAIOR do que o enviado na nota fiscal, então aborta o processo e dá rollback em tudo
				If (nRetQry > SDA->DA_SALDO)
					MsgAlert("Falha no processamento da nota fiscal " + SDA->DA_DOC + CRLF + " O saldo em etiquetas é maior que o saldo a distribuir." + CRLF + "Verifique possíveis pendências de carregamento." + CRLF + "Produto: " + SDA->DA_PRODUTO, "Distribuição de saldos TECADI")
					_lContinua := .F.
					Exit // sai do While
				EndIf

				/******* VALIDAÇÃO ******************************************
				/ saldo de etiquetas Z16 que estão em estruturas físicas diferentes de PP, picking ou BLOCO, será utilizado para comparação com a NF de entrada
				/ se saldo de etiquetas maior que quantidade recebida na NF, aborta o processo e verifica as pendencias (carregamento / pedidos)
				*************************************************************/

				cQuery := " SELECT IsNull(Sum(Z16.Z16_SALDO),0) AS Z16_SALDO "
				cQuery += " FROM " + RetSqlTab("Z16") + " (NOLOCK) "
				cQuery += " 	   INNER JOIN " + RetSqlTab("SBE") + " (NOLOCK) "
				cQuery += " 	   		   ON " + RetSqlCond("SBE")
				cQuery += "                   AND SBE.BE_LOCALIZ = Z16.Z16_ENDATU "
				cQuery += "                   AND SBE.BE_FILIAL = Z16.Z16_FILIAL "
				cQuery += "                   AND SBE.BE_LOCAL = Z16.Z16_LOCAL "
				cQuery += "                   AND SBE.BE_ESTFIS NOT IN ( '000002','000010','000007','000015' ) " // 2 - PP, 10 - PICKING, 7 - BLOCO, 15 - CONTAINER
				cQuery += " WHERE " + RetSqlCond("Z16")
				cQuery += "        AND Z16.Z16_SALDO > 0
				cQuery += "        AND Z16.Z16_CODPRO = '" + cCodAntigo + "' "

				MemoWrit("C:\query\twmsa053_qtd_z16_pend.txt", cQuery )

				nRetQry := U_FTQuery(cQuery)

				//se a quantidade obtida dos pallets for MAIOR do que o enviado na nota fiscal, então aborta o processo e dá rollback em tudo
				If (nRetQry > 0)
					MsgAlert("Falha no processamento da nota fiscal " + SDA->DA_DOC + CRLF + " A quantidade de etiquetas é maior que o saldo a distribuir." + CRLF + "Verifique possíveis pendências de carregamento." + CRLF + "Produto: " + SDA->DA_COD, "Distribuição de saldos TECADI")
					_lContinua := .F.
					Exit // sai do While
				EndIf
			Else
				MsgAlert("Saldo a endereçar não encontrado")
				_lContinua := .F.
				Exit // sai do While
			EndIf

			// próximo item da nota fiscal
			SD1->(DBSkip())
		EndDo
	Else
		MsgAlert("Nota fiscal não encontrada")
		_lContinua := .F.
	EndIf

	// se passou nas validações então inicia o processamento
	If (_lContinua)
		If ( MsgYesNO("Validações OK. Continuar?") )
			oProcObj:Activate()
		EndIF
	EndIf
Return 

Static Function fProcessa(oProcObj)

	LOCAL cQuery := ""
	LOCAL nQtde  := 0
	LOCAL aDados := {}
	Local _aRecnoSD1 := {}
	Local nTotalZ16 := 0
	Local nAtualZ16 := 0
	Local nTotalSD1 := 0
	Local nAtualSD1 := 0
	Local nQtdZ16    := 0
	Local nQtdPendZ16 := 0
	Local _lAzDif   := .F. // flag para identificar se o armazém do produto é diferente do armazem onde foi lançada a nota fiscal
	Local cCodAntigo  := ""   // código antigo do SKU
	Local _aItemSD3, _aTmpItem := {}
	Local cItemDB := ""
	Local _cLog := ""

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	Private aCabSDA, aItemSDB := {}

	SF1->(DBSetOrder(01))//F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
	SDA->(DBSetOrder(01))//DA_FILIAL+DA_PRODUTO+DA_LOCAL+DA_NUMSEQ+DA_DOC+DA_SERIE+DA_CLIFOR+DA_LOJA

	//seta regua1 com a quantidade de produtos da NF
	cQuery := "SELECT COUNT(*) FROM " + RetSqlTab("SD1") + "  WHERE " + RetSqlCond("SD1")
	cQuery += " AND D1_FORNECE = '" + _cCodCli + "'"
	cQuery += " AND D1_LOJA    = '" + _cLojCli + "'"
	cQuery += " AND D1_DOC     = '" + _cDoc + "'"
	cQuery += " AND D1_SERIE   = '" + _cSerie + "'"
	cQuery += " AND D1_TIPO    = 'B'"

	MemoWrit("C:\Query\TWMSA053_query_SD1.txt", cQuery)

	nTotalSD1 := U_FTQuery(cQuery)

	// seta quantidade total de produtos da nota
	oProcObj:SetRegua1( nTotalSD1 )

	// abre transação
	Begin Transaction
		_cLog := Time() + " - Inicio processo/transacao" + CRLF

		// posiciona na nota fiscal
		If SF1->(MSSeek(xFilial("SF1") + _cDoc + _cSerie + _cCodCli + _cLojCli + "B"))
			// posiciona no primeiro item da nota fiscal
			SD1->(dbGoTop())

			// pega todos os RECNO da nota fiscal. Necessário pois as rotinas padrão estão desposicionando a nota fiscal (Luiz Poleza 29/08/19)
			cQuery := "SELECT R_E_C_N_O_ RECNO FROM " + RetSqlTab("SD1")
			cQuery += " WHERE " + RetSqlCond("SD1")
			cQuery += " AND D1_FORNECE = '" + _cCodCli + "'"
			cQuery += " AND D1_LOJA    = '" + _cLojCli + "'"
			cQuery += " AND D1_DOC     = '" + _cDoc + "'"
			cQuery += " AND D1_SERIE   = '" + _cSerie + "'"
			cQuery += " AND D1_TIPO    = '" + SF1->F1_TIPO + "'"
			cQuery += " ORDER BY 1"

			_aRecnoSD1 := U_SqlToVet(cQuery)

			// percorre itens da nota fiscal
			For _nX := 1 to Len(_aRecnoSD1)
				SD1->( DbGoto(_aRecnoSD1[_nX]) )
				
				// Aumenta produto atual
				nAtualSD1++
				oProcObj:IncRegua1("Processando produto - " + cValToChar(nAtualSD1) + " de " + cValToChar(nTotalSD1) + " / " + AllTrim(SD1->D1_COD))

				// limpa variável do código do produto antigo
				cCodAntigo := ""

				_cLog += Time() + " ---- Inicio processamento : " + AllTrim(SD1->D1_COD) + CRLF

				// posiciona no registro da SDA
				If SDA->(MSSeek(xFilial("SDA") + SD1->(D1_COD+D1_LOCAL+D1_NUMSEQ)))   //DA_FILIAL+DA_PRODUTO+DA_LOCAL+DA_NUMSEQ+DA_DOC+DA_SERIE+DA_CLIFOR+DA_LOJA
					// pesquisa se houve troca de código (SKU)
					cQuery := "SELECT IsNull(CODIGO_ANTIGO,'') FROM TWMSA053 (NOLOCK) WHERE CODCLI = '"+_cCodCli+"' AND LOJACLI = '"+_cLojCli+"' AND CODIGO_NOVO = '"+AllTrim(SDA->DA_PRODUTO)+"'"

					// guarda o codigo antigo na variável, para usar no update
					cCodAntigo := U_FTQuery(cQuery)

					// se em branco/nulo, então não teve troca de código... guarda o mesmo código do produto na variável (ficando ANTIGO = NOVO na lógica)
					If Empty(cCodAntigo)
						_cLog += Time() + " - Produto : " + AllTrim(SD1->D1_COD) + " não teve o codigo trocado."+ CRLF
						cCodAntigo := SDA->DA_PRODUTO
					Else
						_cLog += Time() + " - Produto : " + AllTrim(cCodAntigo) + " trocou codigo para: " + AllTrim(SD1->D1_COD) + CRLF
					EndIf

					cQuery := " SELECT Z16.Z16_CODPRO, "
					cQuery += "        Z16.Z16_ENDATU, "
					cQuery += "        Z16.Z16_LOCAL,  "
					cQuery += "        Sum(Z16.Z16_SALDO) AS SALDO "
					cQuery += " FROM " + RetSqlTab("Z16") + " (NOLOCK) "
					cQuery += " 	   INNER JOIN " + RetSqlTab("SBE") + " (NOLOCK) "
					cQuery += " 	   		   ON " + RetSqlCond("SBE")
					cQuery += "                   AND SBE.BE_LOCALIZ = Z16.Z16_ENDATU "
					cQuery += "                   AND SBE.BE_FILIAL = Z16.Z16_FILIAL "
					cQuery += "                   AND SBE.BE_LOCAL = Z16.Z16_LOCAL  "
					cQuery += "                   AND SBE.BE_ESTFIS IN ( '000002', '000007', '000010', '000015' ) "
					cQuery += " WHERE " + RetSqlCond("Z16")
					cQuery += "        AND Z16.Z16_SALDO > 0  "
					cQuery += " 	   AND Z16_CODPRO = '" + cCodAntigo + "' "
					cQuery += " GROUP  BY Z16_CODPRO, "
					cQuery += "           Z16_ENDATU, "
					cQuery += "           Z16_LOCAL  "

					MemoWrit("C:\query\twmsa053_" + Alltrim(SD1->D1_DOC) + AllTrim(SD1->D1_COD) + ".txt", cQuery )

					// cria arquivo temporário
					If Select("TRBZ16") <> 0
						DBSelectArea("TRBZ16")
						DBCloseArea()
					EndIf
					//					DBUseArea(.T., "TOPCONN", TCGenQry(NIL,NIL,cQuery),"TRBZ16",.F.,.T.)

					TcQuery cQuery New Alias "TRBZ16"
					DbSelectArea("TRBZ16")

					// seta regua primária
					Count to nTotalZ16
					oProcObj:SetRegua2(nTotalZ16)

					_cLog += Time() + " - Produto : " + AllTrim(SD1->D1_COD) + " tem " + AllTrim( Str(nTotalZ16) ) + " registros Z16 para atualizar e transferir." + CRLF
					_cLog += Time() + " - Produto : " + AllTrim(SD1->D1_COD) + " tem " + AllTrim( Str(SDA->DA_SALDO) ) + " para endereçar." + CRLF

					If (nTotalZ16 == 0)
						TRBZ16->( DBCloseArea() )
						DisarmTransaction()
						_cLog += Time() + " - Nenhuma etiqueta ou endereço encontrado para o produto : " + AllTrim(SD1->D1_COD) + CRLF
						MsgAlert("FALHA: Nenhuma etiqueta ou endereço encontrado para o produto: " + SDA->DA_PRODUTO, "FALHA")
						Break
					EndIf

					/**************************************************************************************************************
					//TODO - **AQUI** Antes de começar a endereçar, verificar se todos os endereços que vão ser "alimentados" estão desocupados, 
					//pois dependendo do período de demora para novo processamento, pode ter sido ocupado por outro produto.
					**************************************************************************************************************/

					// zera quantidade já utilizada/distribuída
					nQtde := 0
					nAtualZ16 := 0

					// posiciona no primeiro registro
					TRBZ16->( DbGoTop() )

					_cLog += Time() + " - Iniciando transferências do produto : " + AllTrim(SD1->D1_COD) + CRLF

					// percorre todos os pallets até o final
					Do While !TRBZ16->( Eof() )
						// atualiza quantidade já utilizada/distribuída
						nQtde  += TRBZ16->SALDO

						// zera variaveis
						aCabSDA  := {}
						aItemSDB := {}
						_lAzDif  := .F.

						// cabecalho de movimentacao da mercadoria
						aCabSDA := {{"DA_FILIAL",SDA->DA_FILIAL ,NIL},;
						{"DA_PRODUTO"	,SDA->DA_PRODUTO	,NIL},;
						{"DA_QTDORI"	,SDA->DA_QTDORI	    ,NIL},;
						{"DA_SALDO"		,SDA->DA_SALDO		,NIL},;
						{"DA_DATA"		,Date() 			,NIL},;
						{"DA_LOTECTL"	,SDA->DA_LOTECTL	,NIL},;
						{"DA_DOC"		,SDA->DA_DOC		,NIL},;
						{"DA_SERIE"		,SDA->DA_SERIE		,NIL},;
						{"DA_CLIFOR"	,SDA->DA_CLIFOR	    ,NIL},;
						{"DA_LOJA"		,SDA->DA_LOJA		,NIL},;
						{"DA_TIPONF"	,SDA->DA_TIPONF	    ,NIL},;
						{"DA_NUMSEQ"	,SDA->DA_NUMSEQ	    ,NIL},;
						{"DA_LOCAL"		,SDA->DA_LOCAL		,NIL},;
						{"DA_ORIGEM"	,SDA->DA_ORIGEM	    ,NIL}}

						// Aumenta régua
						nAtualZ16++
						oProcObj:IncRegua2("Gerando transf. (Z16) - " + cValToChar(nAtualZ16) + " de " + cValToChar(nTotalZ16) + "...")

						// pesquisa a ultimo item utilizado
						cItemDB := Soma1(A265UltIt('C'))

						// flag se o pallet está em armazém diferente do que foi lançado a nota. neste caso, primeiro tem que endereçar e depois transferir para o armazém final
						IF (SDA->DA_LOCAL != Z16->Z16_LOCAL)
							_lAzDif := .T.
						EndIf

						// item a distribuir
						Aadd(aItemSDB,{{"DB_FILIAL",xFilial("SDB"),NIL},;
						{"DB_ITEM"		,cItemDB			,NIL},;
						{"DB_LOCAL"		,SDA->DA_LOCAL		,NIL},; // obrigatório mesmo armazém
						{"DB_ESTORNO"	," "				,Nil},;
						{"DB_LOCALIZ"	,IIf(_lAzDif, "TRANSITORIO", TRBZ16->Z16_ENDATU)	,NIL},; // endereço
						{"DB_PRODUTO"	,SDA->DA_PRODUTO	,NIL},;
						{"DB_DOC"		,SDA->DA_DOC		,NIL},;
						{"DB_SERIE"		,SDA->DA_SERIE		,NIL},;
						{"DB_NUMSEQ"	,SDA->DA_NUMSEQ		,NIL},;
						{"DB_DATA"		,Date() 			,NIL},;
						{"DB_QUANT"		,TRBZ16->SALDO		,NIL},;
						{"DB_ZNUMOS"	,""					,NIL},;
						{"DB_ZSEQOS"	,""					,NIL},;
						{"DB_ZLOTECT"	,SDA->DA_LOTECTL	,NIL},;
						{"DB_ZPALLET"	,""              	,NIL}})

						// Atualiza arquivo de saldos em estoque
						dbSelectArea("SB2")
						SB2->(DbSetOrder(1)) // 1-B2_FILIAL, B2_COD, B2_LOCAL
						If ! SB2->(dbSeek( xFilial("SB2") + SDA->DA_PRODUTO + TRBZ16->Z16_LOCAL ))
							// cria registro do produto no armazem de destino
							CriaSB2(SDA->DA_PRODUTO, TRBZ16->Z16_LOCAL)
						EndIf

						// executa rotina automática
						MSExecAuto({|x,y,z| mata265(x,y,z)}, aCabSDA, aItemSDB, 3) // 3 - Distribui

						// se ocorreu erro na rotina automatica
						If (lMsErroAuto)
							DisarmTransaction()
							MostraErro()
							Break
						EndIf

						// se armazém diferente, ainda falta transferir o saldo fiscal para o endereço final
						If (_lAzDif)

							// chama o grupo de perguntas padrao da rotina MATA260
							pergunte("MTA260",.F.)

							// define o parametro "Considera Saldo poder de 3" como NAO
							mv_par03 := 2

							// zera variaveis
							_aItemSD3 := {}
							_aTmpItem := {}

							_aItemSD3 := {{NextNumero("SD3",2,"D3_DOC",.T.), Date() }}

							// posiciona no cadastro de produtos
							dbSelectArea("SB1")
							SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
							SB1->(dbSeek( xFilial("SB1") + SDA->DA_PRODUTO ))

							// calcula 2ª UM correta
							If !Empty(SB1->B1_TIPCONV)
								If (SB1->B1_TIPCONV == "D")  // se divide
									nSaldo2 := TRBZ16->SALDO / SB1->B1_CONV
								Else  // se multiplica
									nSaldo2 := TRBZ16->SALDO * SB1->B1_CONV
								EndIf
							Else
								nSaldo2 := 0
							EndIf

							_aTmpItem := { {"D3_COD"		, SDA->DA_PRODUTO	,Nil},;
							{"D3_DESCRI"	, SB1->B1_DESC		,Nil},;
							{"D3_UM"		, SB1->B1_UM		,Nil},;
							{"D3_LOCAL"		, SDA->DA_LOCAL 	,Nil},;  // armazem transitorio (lançamento nf)
							{"D3_LOCALIZ"	, "TRANSITORIO"  	,Nil},;  // endereço transitorio
							{"D3_COD"		, SDA->DA_PRODUTO	,Nil},;
							{"D3_DESCRI"	, SB1->B1_DESC		,Nil},;
							{"D3_UM"		, SB1->B1_UM		,Nil},;
							{"D3_LOCAL"		, TRBZ16->Z16_LOCAL	,Nil},;  // armazem final
							{"D3_LOCALIZ"	, TRBZ16->Z16_ENDATU,Nil},;  // endereço final
							{"D3_NUMSERI"	, ""				,Nil},;
							{"D3_LOTECTL"	, SDA->DA_LOTECTL	,Nil},;
							{"D3_NUMLOTE"	, ""				,Nil},;
							{"D3_DTVALID"	, ""	            ,Nil},;
							{"D3_POTENCI"	, 0  				,Nil},;
							{"D3_QUANT"		, TRBZ16->SALDO  	,Nil},;
							{"D3_QTSEGUM"	, nSaldo2			,Nil},;
							{"D3_ESTORNO"	, ""				,Nil},;
							{"D3_NUMSEQ"	, ""				,Nil},;
							{"D3_LOTECTL"	, SDA->DA_LOTECTL	,Nil},;
							{"D3_NUMLOTE"	, ""				,Nil},;
							{"D3_DTVALID"	, ""            	,Nil},;
							{"D3_ZNUMOS"	, ""     			,Nil},;
							{"D3_ZSEQOS"	, ""				,Nil},;
							{"D3_ZETQPLT"	, ""                ,Nil},;
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
								MostraErro()
								Alert("Erro Execauto transferencia entre armazens - " + Alltrim(SDA->DA_PRODUTO) )
								Break
							EndIf
						EndIf

						// próximo pallet
						TRBZ16->(DBSkip())
					EndDo


					_cLog += Time() + " - Produto : " + AllTrim(SD1->D1_COD) + " endereçou " + AllTrim( Str(nQtde) )  + CRLF

					// se a quantidade obtida dos pallets, ao final da operação, for menor do que o enviado na nota fiscal, então endereça a sobra para LOST
					If ( SDA->DA_SALDO > 0)

						// zera variaveis
						aCabSDA  := {}
						aItemSDB := {}

						// cabecalho de movimentacao da mercadoria
						aCabSDA := {{"DA_FILIAL",SDA->DA_FILIAL ,NIL},;
						{"DA_PRODUTO"	,SDA->DA_PRODUTO	,NIL},;
						{"DA_QTDORI"	,SDA->DA_QTDORI	    ,NIL},;
						{"DA_SALDO"		,SDA->DA_SALDO		,NIL},;
						{"DA_DATA"		,dDataBase			,NIL},;
						{"DA_LOTECTL"	,SDA->DA_LOTECTL	,NIL},;
						{"DA_DOC"		,SDA->DA_DOC		,NIL},;
						{"DA_SERIE"		,SDA->DA_SERIE		,NIL},;
						{"DA_CLIFOR"	,SDA->DA_CLIFOR	    ,NIL},;
						{"DA_LOJA"		,SDA->DA_LOJA		,NIL},;
						{"DA_TIPONF"	,SDA->DA_TIPONF	    ,NIL},;
						{"DA_NUMSEQ"	,SDA->DA_NUMSEQ	    ,NIL},;
						{"DA_LOCAL"		,SDA->DA_LOCAL		,NIL},;
						{"DA_ORIGEM"	,SDA->DA_ORIGEM	    ,NIL}}

						// pesquisa a ultimo item utilizado
						cItemDB := Soma1(A265UltIt('C'))

						Aadd(aItemSDB,{{"DB_FILIAL",xFilial("SDB"),NIL},;
						{"DB_ITEM"		,cItemDB			,NIL},;
						{"DB_LOCAL"		,SDA->DA_LOCAL   	,NIL},;
						{"DB_ESTORNO"	," "			    ,Nil},;
						{"DB_LOCALIZ"	,"LOST"	            ,NIL},; //LOCAL
						{"DB_PRODUTO"	,SDA->DA_PRODUTO	,NIL},;
						{"DB_DOC"		,SDA->DA_DOC		,NIL},;
						{"DB_SERIE"		,SDA->DA_SERIE		,NIL},;
						{"DB_NUMSEQ"	,SDA->DA_NUMSEQ		,NIL},;
						{"DB_DATA"		,Date()			    ,NIL},;
						{"DB_QUANT"		,(SDA->DA_SALDO)	,NIL},;
						{"DB_ZNUMOS"	,""					,NIL},;
						{"DB_ZSEQOS"	,""					,NIL},;
						{"DB_ZLOTECT"	,SDA->DA_LOTECTL	,NIL},;
						{"DB_ZPALLET"	,""	,NIL}})

						_cLog += Time() + " - Iniciando endereçamento para LOST do produto : " + AllTrim(SDA->DA_PRODUTO) + " / Quant.: " + AllTrim(Str(SDA->DA_SALDO)) + CRLF

						// executa rotina automática
						MSExecAuto({|x,y,z| mata265(x,y,z)}, aCabSDA, aItemSDB, 3) // 3 - Distribui

						// se ocorreu erro na rotina automatica
						If (lMsErroAuto)
							DisarmTransaction()
							MostraErro()
							Break
						EndIf
					EndIf

					_cLog += Time() + " - Será executado UPDATE Z16 do produto : " + AllTrim(SDA->DA_PRODUTO) + CRLF

					// atualiza nota fiscal, codigo do produto em todos os pallets deste produto
					cQuery := " UPDATE " + RetSQLName("Z16") + " SET Z16_CODPRO ='" + SDA->DA_PRODUTO + "', Z16_NUMSEQ = '" + SDA->DA_NUMSEQ + "', Z16_ORIGEM = 'INV'  "
					cQuery += " WHERE Z16_FILIAL = '" + SDA->DA_FILIAL + "' AND D_E_L_E_T_ = '' "
					cQuery += " AND Z16_SALDO > 0 "
					cQuery += " AND Z16_FILIAL = '"+SDA->DA_FILIAL+"' "
					cQuery += " AND Z16_CODPRO = '"+cCodAntigo+"' "

					// verifica se deu erro no comando update					
					If TCSQLExec(cQuery) < 0
						DisarmTransaction()						
						Alert("Erro de execução na atualização das etiquetas")
						Break				  	       
					EndIf

					_cLog += Time() + " - Executado UPDATE Z16 do produto : " + AllTrim(SDA->DA_PRODUTO) + CRLF

					_cLog += Time() + " ---- Fim do processamento total do produto : " + AllTrim(SDA->DA_PRODUTO) + CRLF

					// próximo item da nota fiscal
					_cLog += Time() + " - Próximo produto SD1 " + CRLF

				Else
					DisarmTransaction()				
					Alert("Não encontrei SDA - " + SD1->D1_NUMSEQ)
					Break
				EndIF
			Next _nX // proximo registro
		EndIF // se achou nota fiscal

		If !MsgYesNo("Ultima chance! Confirma?")
			DisarmTransaction()
			Break		
		EndIf

	End Transaction

	//salva log
	MemoWrit("C:\query\TWMSA053_log_" + SDA->DA_DOC + ".txt", _cLog)

	//	MsgInfo("Nota fiscal " + SDA->DA_DOC + " / " + SDA->DA_SERIE + " distribuída com sucesso.")
Return
