#Include "Totvs.ch"
#Include "protheus.ch"
#Include "rwmake.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado no botao Confirmar do       !
!                  ! Pedido de Venda                                         !
!                  ! 1. Sempre libera todos os itens do pedido de venda      !
!                  ! 2. Utilizado para validar o peso bruto, liquido e       !
!                  !    cubagem total, rateando o peso de devolucao entre os !
!                  !    itens                                                !
!                  ! 3. Verifica se tem informacoes de volumes               !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 09/2010 !
+------------------+--------------------------------------------------------*/

User Function MT410TOK()
	// variavel de retorno
	local _lRet := .t.
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSD1 := SD1->(GetArea())
	local _aAreaSF4 := SF4->(GetArea())
	local _aAreaCC2 := CC2->(GetArea())
	local _aAreaSB1 := SB1->(GetArea())
	local _aAreaSC5 := SC5->(GetArea())

	// posicao de campos no browse
	local _nX        := 0
	local _nP_Ite    := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ITEM"    })
	local _nP_Prd    := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_PRODUTO" })
	local _nP_LotCtl := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_LOTECTL" }) // lote do produto
	local _nP_Quant  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_QTDVEN"  }) // quantidade
	local _nP_NFOri  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_NFORI"   }) // nota fiscal origem
	local _nP_SerOri := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_SERIORI" }) // serie nf origem

	// variavel para controle de mapa de expedição gerado
	local _lTemMapa := .f.

	// valida se o WMS esta ativo por cliente
	local _lWmsAtivo := .f.

	// verifica se o controle de lote esta
	local _lLotAtivo := .f.

	// verifica se o lote eh obrigatorio na saida da nota
	local _lLotObrSai := .f.

	// wms manual
	local _lWmsManual := ("SIGAEST_WMS" $ Upper(FWGetMnuFile()))

	// valida o controle de uso de segunda unidade de medida
	local _lUsoSegUM := .f.

	// valida o controle de uso de segunda unidade de medida, se podera ser fracionada
	local _lSegUMFrac := .f.

	// chave da nota fiscal de venda
	local _cChaveNFV

	// variavel que confirma utilizacao de DI com outras series.
	Private _lPedVMist := .f.

	// valida necessidade de validar a quantidade conforme cadastro de SKU
	Private _lVldSkuProd := .f.

	// Valida se cliente deve preencher campo C5_ZCHVNFV
	Private _lVldChvNfv := .F.

	// posicoes do _aLotesPV (variavel publica criada pelo P.E. A410CONS)
	private _nL_Ite    := 1
	private _nL_Cod    := 2
	private _nL_Amz    := 3
	private _nL_Lot    := 4
	private _nL_End    := 5
	private _nL_Pal    := 6
	private _nL_Qtd    := 7
	private _nL_Seq    := 8
	private _nL_EtqVol := 9

	// volumes (caixas) ja selecionados no pedido de venda
	private _lVolJaDef := .f.

	// zera conteudo de campos do municipio prestador de servicos
	M->C5_ESTPRES := CriaVar("C5_ESTPRES",.f.)
	M->C5_MUNPRES := CriaVar("C5_MUNPRES",.f.)
	M->C5_DESCMUN := CriaVar("C5_DESCMUN",.f.)

	// preenchimento do campo C5_FECENT (Dt Entrega), pois é usado no filtro de montagem de cargas
	If (Empty(M->C5_FECENT))
		M->C5_FECENT := Date()
	EndIf

	// gravacao da hora de inclusao do pedido
	If (SC5->(FieldPos("C5_ZHRINCL")) > 0) .and. (Empty(M->C5_ZHRINCL))
		M->C5_ZHRINCL := Time()
	EndIf

	// se for INCLUSAO ou ALTERACAO
	If (_lRet).and. ((Inclui) .or. (Altera))
		// funcao que SEMPRE libera todos os itens
		_lRet := sfLibItens()
	EndIf

	// se for INCLUSAO ou ALTERACAO e o tipo do pedido for PRODUTO
	If (_lRet) .and. (M->C5_TIPO=="N") .and. ((Inclui) .or. (Altera)) .and. (M->C5_TIPOOPE=="P") .and. (cEmpAnt=="01")

		// para pedidos do tipo PRODUTO, nao usar vendedores
		M->C5_VEND1  := CriaVar("C5_VEND1" , .f.)
		M->C5_COMIS1 := CriaVar("C5_COMIS1", .f.)
		M->C5_VEND2  := CriaVar("C5_VEND2" , .f.)
		M->C5_COMIS2 := CriaVar("C5_COMIS2", .f.)
		M->C5_VEND3  := CriaVar("C5_VEND3" , .f.)
		M->C5_COMIS3 := CriaVar("C5_COMIS3", .f.)
		M->C5_VEND4  := CriaVar("C5_VEND4" , .f.)
		M->C5_COMIS4 := CriaVar("C5_COMIS4", .f.)
		M->C5_VEND5  := CriaVar("C5_VEND5" , .f.)
		M->C5_COMIS5 := CriaVar("C5_COMIS5", .f.)

		// valida necessidade de validar a quantidade conforme cadastro de SKU
		_lVldSkuProd := U_FtWmsParam("WMS_VALIDA_QUANTIDADE_SKU","L",.f.,.f.,Nil, M->C5_CLIENTE, M->C5_LOJACLI, Nil, Nil)

		// verifica se o WMS esta ativo
		_lWmsAtivo := StaticCall(TWMSXFUN, WmsMltCntr, "MATA410", "WMS_ATIVO_POR_CLIENTE", M->C5_CLIENTE, M->C5_LOJACLI)

		//Valida se cliente deve obrigatoriamente preencher o campo C5_ZCHVNFV.
		_lVldChvNfv := U_FtWmsParam("WMS_PEDIDO_CHAVE_NFE_VENDA","L",.F.,.F.,"",  M->C5_CLIENTE, M->C5_LOJACLI, Nil, Nil)

		// verifica se o controle de lote esta
		_lLotAtivo := StaticCall(TWMSXFUN, WmsMltCntr, "MATA410", "WMS_CONTROLE_POR_LOTE", M->C5_CLIENTE, M->C5_LOJACLI)

		// verifica se o lote eh obrigatorio na saida da nota
		_lLotObrSai := U_FtWmsParam("WMS_LOTE_OBRIGATORIO_SAIDA","L",.F.,.F.,Nil, M->C5_CLIENTE, M->C5_LOJACLI, Nil, Nil)

		// volumes (caixas) ja selecionados no pedido de venda
		_lVolJaDef := U_FtWmsParam("WMS_EXPEDICAO_ESCOLHE_VOLUMES", "L", .f., .f., Nil, M->C5_CLIENTE, M->C5_LOJACLI, Nil, Nil)

		// valida o controle de uso de segunda unidade de medida
		_lUsoSegUM := StaticCall(TWMSXFUN, WmsMltCntr, "MATA410", "WMS_PRODUTO_USA_SEGUNDA_UNIDADE_MEDIDA", M->C5_CLIENTE, M->C5_LOJACLI)

		// valida o controle de uso de segunda unidade de medida
		_lSegUMFrac := StaticCall(TWMSXFUN, WmsMltCntr, "MATA410", "WMS_PRODUTO_FRACIONA_SEGUNDA_UNIDADE_MEDIDA", M->C5_CLIENTE, M->C5_LOJACLI)

		// executa a funcao de rateio do peso
		_lRet := sfRatPeso()

		//Caso conteudo verdadeiro, apresenta mensagem ao usuario que pedido de venda esta MISTO.
		if	( _lPedVMist ) //OGA - 26/07/13
			Aviso("Tecadi: MT410TOK","Para pedidos de venda do tipo PRODUTO, não vincular DI com nota.",{"OK"})
			_lRet := .F.
		EndIf

		// valida, se a Chave da NFe de Venda foi informada
		If (_lRet) .and. (FunName() == "MATA410") .and. (_lVldChvNfv) .And. (Empty(M->C5_ZCHVNFV))
			Aviso("Tecadi: MT410TOK","Obrigatório preencher o campo Chave Nota Fiscal de Venda do Cliente.",{"OK"})
			_lRet := .F.
		EndIf

		// verifica se tem informacoes de volumes
		If (_lRet) .and. ((M->C5_VOLUME1 <= 0) .or. (Empty(M->C5_ESPECI1)))
			Aviso("Tecadi: MT410TOK","Para pedidos de venda do tipo PRODUTO é necessário informar Volume e Espécie.",{"OK"})
			_lRet := .F.
		EndIf

		// só valido se existe a variavel caso o WMS esteja ativo
		If (_lRet) .and. (_lWmsAtivo) .and. (_lLotAtivo)
			If ( TYPE("_aLotesPV") != "A" )
				_aLotesPV := {}
				GetGlbVars("_aGlbLot",@_aLotesPV)
			EndIf
		EndIf

		// valida se os produtos com lote tem estoque para atender o pedido (Eliane - Dataroute)
		If (_lRet) .and. (_lWmsAtivo) .and. (_lLotAtivo)
			_lRet := sfValQtdLot()
		EndIf

		// quando a validade de quantidade de SKU estiver ativo
		If (_lRet) .and. (_lVldSkuProd)
			_lRet := sfValQtdSKU()
		EndIf

		// Verifica se o WMS esta ativo e define o endereco WMS para separacao da mercadoria
		If (_lRet) .and. (cEmpAnt=="01") .and. (_lWmsAtivo)
			// funcao que define endereco de retirada da mercadoria
			sfWmsDefEnd(_lWmsManual)
			// define que utiliza carga (1-Utiliza / 2-Nao Utiliza)
			M->C5_TPCARGA := "1"
		EndIf

		// Verifica se o WMS esta ativo e define o endereco WMS para separacao da mercadoria
		If (_lRet) .and. (cEmpAnt=="01") .and. (_lWmsAtivo)
			// variavel para controle de mapa de expedição gerado
			_lTemMapa := U_FtMapExp(M->C5_NUM)
		EndIf

	EndIf

	// validação específica para alterações quando já há mapa gerado
	If (_lRet) .and. (M->C5_TIPO=="N") .and. (Altera) .and. (M->C5_TIPOOPE=="P") .and. (_lWmsAtivo) .and. (_lTemMapa)
		_lRet := sfVldAltMap()
	EndIf

	// validação específica para controle de lote a wms ativo
	If (_lRet) .and. (M->C5_TIPO=="N") .and. ((Inclui) .or. (Altera)) .and. (M->C5_TIPOOPE=="P") .and. (_lWmsAtivo) .and. (_lLotAtivo)

		// valida o total do lote informado
		_lRet := sfValLote()

	EndIf

	// validações para cada NF origem
	If (_lRet) .and. (M->C5_TIPO=="N") .and. ((Inclui) .or. (Altera)) .and. (M->C5_TIPOOPE=="P") .AND. (!IsInCallStack("U_TWMSA010") )   
		// varre todos os itens do pedido de venda
		For _nX := 1 to Len(aCols)
			
			// validação específica para verificar se a nota fiscal que está sendo devolvida possui saldo a endereçar
			// isto impede que se devolva NF ainda não recebida 
			/////////////// 
			///  25/07/2019 - BRUNO SEÁRA: CHAMADO 19407 ADICIONADA EXCEÇÃO ATÉ 31/12/2019 PARA CLIENTE SUMITOMO LOJA 01 SOLICITADO POR FLAVIO E AUTORIZADO DANIEL
			//////////////
			If ( ! aCols[_nX][Len(aHeader)+1] ) .AND. (_lRet) .AND. !(M->C5_CLIENTE == "000316" .AND. M->C5_LOJACLI == "01") 
				If (!sfNFSDA(M->C5_CLIENTE, M->C5_LOJACLI, aCols[_nX][_nP_NFOri], aCols[_nX][_nP_SerOri] ))
					_lRet := .F.
				EndIf
			EndIf
			
			// validação específica para verificar se a nota fiscal que está sendo devolvida possui TFAA em aberto
			// isto impede que se devolva NF ainda em processamento
			If ( ! aCols[_nX][Len(aHeader)+1] ) .AND. (_lRet)
				If (!sfNFTFAA(M->C5_CLIENTE, M->C5_LOJACLI, aCols[_nX][_nP_NFOri], aCols[_nX][_nP_SerOri] ))
					_lRet := .F.
				EndIf
			EndIf
		Next _nX
	EndIf

	// validação específica para controle de lote
	If (_lRet) .and. (M->C5_TIPO=="N") .and. ((Inclui) .or. (Altera)) .and. (M->C5_TIPOOPE=="P") .and. (_lWmsAtivo) .and. (_lLotAtivo)

		// varre todos os itens do pedido de venda
		For _nX := 1 to Len(aCols)

			// posiciona no cadastro do produto
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+aCols[_nX,_nP_Prd]))

			// se a linha nao estiver deletada / e se o lote do produto foi informado
			If ( ! aCols[_nX][Len(aHeader)+1] ) .and. (Rastro(aCols[_nX,_nP_Prd],"L"))

				// valida se o lote eh obrigatorio
				If (_lLotObrSai) .and. (Empty(aCols[_nX,_nP_LotCtl]))
					// mensagem
					Aviso("Tecadi: MT410TOK","É obrigatório informar o lote do produto.",{"OK"})
					// controle da validacoes/retorno
					_lRet := .f.

				ElseIf ( ! _lLotObrSai )
					// se controla rastro, e o lote nah eh obrigatorio, limpa o campo lote pois está na tabela Z45
					aCols[_nX][_nP_LotCtl] := Space(TamSx3("C6_LOTECTL")[1])

				EndIf
			EndIf

		Next _nX

	EndIf

	// validação específica para controle e uso da segunda unidade de medida, sem fracao
	If (_lRet) .and. (M->C5_TIPO=="N") .and. ((Inclui) .or. (Altera)) .and. (M->C5_TIPOOPE=="P") .and. (_lUsoSegUM) .and. ( ! _lSegUMFrac )

		// varre todos os itens do pedido de venda
		For _nX := 1 to Len(aCols)

			// posiciona no cadastro do produto
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+aCols[_nX, _nP_Prd]))

			// se a linha nao estiver deletada / e se o lote do produto foi informado
			If ( ! aCols[_nX][Len(aHeader)+1] ) .and. ( ! Empty(SB1->B1_SEGUM) ) .and. (SB1->B1_CONV != 0) .and. ( Mod(aCols[_nX][_nP_Quant], SB1->B1_CONV) != 0 )
				// mensagem
				Aviso("Tecadi: MT410TOK","Favor verificar a fração entre as unidades de medidas. Item: " + aCols[_nX][_nP_Ite] + "-" + aCols[_nX][_nP_Prd],{"OK"})
				// controle da validacoes/retorno
				_lRet := .f.
			EndIf

		Next _nX

	EndIf

	// se for INCLUSAO ou ALTERACAO e o tipo do pedido for SERVICO
	If (_lRet) .and. (M->C5_TIPO=="N") .and. ((Inclui) .or. (Altera)) .and. (M->C5_TIPOOPE=="S")

		// funcao que valida o codigo do servico ISS
		If (_lRet)
			_lRet := sfVldCodISS()                               
		EndIf

		// funcao que atualiza preco de lista igual ao preco de venda (somente para servicos)
		If (_lRet)
			_lRet := sfAtuPrcLista()
		EndIf

		// atualiza municipio de prestacao de servico (conforme cadastro da empresa)
		If (_lRet)
			M->C5_ESTPRES := SM0->M0_ESTCOB
			M->C5_MUNPRES := SubS(SM0->M0_CODMUN,3)
			M->C5_DESCMUN := Upper(SM0->M0_CIDCOB)
		EndIf

		// define vendedores, conforme cadastro de cliente
		If (_lRet)
			_lRet := sfDefVend()
		EndIf

	EndIf

	// validação específica para controle da chave da nota fiscal de venda
	If (_lRet) .and. (M->C5_TIPO=="N") .and. ((Inclui) .or. (Altera)) .and. (M->C5_TIPOOPE=="P") .and. (_lVldChvNfv) .And. ( ! Empty(M->C5_ZCHVNFV) )

		// padroniza tamanho do campo
		_cChaveNFV := PadR(M->C5_ZCHVNFV, TamSx3("C5_ZCHVNFV")[1])

		_cQuery := " SELECT COUNT(*) QTD FROM " + RetSqlTab("SC5") + " (NOLOCK) "
		_cQuery += " WHERE " + RetSqlCond("SC5")
		_cQuery += " AND C5_ZCHVNFV = '" + _cChaveNFV + "' AND C5_CLIENTE = '" + M->C5_CLIENTE + "' AND C5_LOJACLI = '" + M->C5_LOJACLI + "'"
		_cQuery += " AND C5_NUM != '" + M->C5_NUM + "'"

		// Verifica se já existe algum pedido com esta chave de nota fiscal
		If (U_FTQuery(_cQuery) > 0) 
			// variavel de retorno
			_lRet := .f.
			// mensagem de aviso
			Help(Nil, Nil, "Tecadi: MT410TOK",,"Chave da Nota Fiscal de Venda " + AllTrim(_cChaveNFV) + " já registrada no pedido: " + SC5->C5_NUM, 1, 0)
		EndIf

	EndIf

	// restaura area inicial
	RestArea(_aAreaSC5)
	RestArea(_aAreaSB1)
	RestArea(_aAreaCC2)
	RestArea(_aAreaSF4)
	RestArea(_aAreaSD1)
	RestArea(_aAreaAtu)

Return(_lRet)

// ** funcao para rateio do peso bruto, liquido e cubagem entre os itens
Static Function sfRatPeso()
	// variavel temporaria
	local _nX
	local _aSaldo
	// percentual de rateio do item
	local _nPercRat := 0
	// posicao dos campos PESO no header
	local _nP_PesLiq := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ZPESOL"}) // peso liquido
	local _nP_PesBru := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ZPESOB"}) // peso bruto
	// posicao do campo QUANTIDADE
	local _nP_Quant := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_QTDVEN"}) // quantidade
	// posicao do campo CUBAGEM no header
	local _nP_Cubag := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ZCUBAGE"}) // cubagem
	// posicao dos campos NOTA, SERIE e ITEM ORIGINAIS
	local _nP_Doc := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_NFORI"}) // nota fiscal original
	local _nP_Serie := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_SERIORI"}) // serie da nota original
	local _nP_ItemOr := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ITEMORI"}) // item da nota original
	local _nP_CodProd := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_PRODUTO"}) // produto
	local _nP_Item := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ITEM"}) // item do pedido de venda
	// posicao da TES
	local _nP_Tes := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_TES"}) // Codigo da TES
	// posicao da Descrição do produto.
	local _nP_Descri := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_DESCRI"}) // Codigo da Descrição do produto.

	// variavel Estatica
	local _cTpSeriPd := Space(3)
	// variavel de retorno
	local _lRet := .t.

	// query
	local _cQuery

	// dados da nota
	local _aSaldoNf  := {}
	local _nTmpQuant := 0

	// quantidade
	local _nQtdEntra := 0
	local _nSaidaSb6 := 0
	local _nSaidaSd2 := 0
	local _nSaidaSc6 := 0

	// controle de devolucao total do item
	local _lDevTotal := .f.

	// zera o peso bruto, liquido e cubagem
	M->C5_PESOL   := 0
	M->C5_PBRUTO  := 0
	M->C5_CUBAGEM := 0

	// varre todos os itens do pedido de venda, rateando o peso bruto e liquido de acordo com a nota fiscal de entrada
	For _nX := 1 to Len(aCols)

		// se a linha nao estiver deletada / e se a TES movimenta estoque
		If ( ! aCols[_nX][Len(aHeader)+1] ) .and. (Posicione("SF4",1, xFilial("SF4")+aCols[_nX][_nP_Tes] ,"F4_ESTOQUE")=="S")

			// pesquisa o item na nota original
			dbSelectArea("SD1")
			SD1->(dbSetOrder(1)) //1-D1_FILIAL, D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_COD, D1_ITEM
			If ! SD1->(dbSeek( xFilial("SD1")+aCols[_nX][_nP_Doc]+aCols[_nX][_nP_Serie]+M->C5_CLIENTE+M->C5_LOJACLI+aCols[_nX][_nP_CodProd]+aCols[_nX][_nP_ItemOr] ))
				// mensagem
				Aviso("Tecadi: MT410TOK","Item "+aCols[_nX][_nP_ItemOr]+" "+aCols[_nX][_nP_CodProd]+" não encontrado na nota fiscal informada.",{"OK"})
				// variavel de controle
				_lRet := .f.
			Else
				//Deixar a descrição do produto igual a nota de entrada.
				// Luiz poleza 13/09/18 - exceção temporária para cliente MINELAB pois precisa informar o número de serie
				If !(M->C5_CLIENTE == "000579")
					aCols[_nX][_nP_Descri] := SD1->D1_DESCRIC
				EndIf
			EndIf

			// valida se a programacao esta encerrada
			If (_lRet)
				dbSelectArea("SZ1")
				SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
				If (SZ1->(dbSeek( xFilial("SZ1")+SD1->D1_PROGRAM )))
					If ( ! Empty(SZ1->Z1_DTFINFA))
						// mensagem
						Aviso("Tecadi: MT410TOK","A programação "+SD1->D1_PROGRAM+" encontra-se encerrada."+CRLF+;
						"Item "+aCols[_nX][_nP_ItemOr]+" Produto: "+AllTrim(aCols[_nX][_nP_CodProd])+CRLF+;
						"Contate o setor de Faturamento.",{"OK"})
						// variavel de controle
						_lRet := .f.

					EndIf
				Else
					// mensagem
					Aviso("Tecadi: MT410TOK","Programação "+SD1->D1_PROGRAM+" não encontrada."+CRLF+;
					"Item "+aCols[_nX][_nP_ItemOr]+" Produto: "+AllTrim(aCols[_nX][_nP_CodProd])+CRLF+;
					"Contate o setor de Faturamento.",{"OK"})
					// variavel de controle
					_lRet := .f.

				EndIf
			EndIf

			// valida quantidade total de entrada com quantidade de saidas, evitando saida maior que entrada (erro padrao no totvs)
			If (_lRet)

				// atualiza variavel
				_nTmpQuant := aCols[_nX][_nP_Quant]

				// busca qtd entrada e qtd de saida
				_cQuery := "SELECT "
				_cQuery += " B6_IDENT, "
				_cQuery += " SUM(CASE WHEN B6_PODER3 = 'R' THEN B6_QUANT ELSE 0 END) QTD_ENT, "
				_cQuery += " SUM(CASE WHEN B6_PODER3 = 'D' THEN B6_QUANT ELSE 0 END) QTD_SAI, "
				// quantidade ja expedida em nota fiscal de saida
				_cQuery += " (SELECT SUM(D2_QUANT) "
				// itens da nota fiscal de saida
				_cQuery += "    FROM "+RetSqlName("SD2")+" SD2 "
				// TES que Movimenta Estoque
				_cQuery += "INNER JOIN "+RetSqlName("SF4")+" SF4 ON "+RetSqlCond("SF4")+" AND F4_CODIGO = D2_TES AND F4_ESTOQUE = 'S' AND F4_PODER3 = 'D' "
				// filtro padrao
				_cQuery += "   WHERE "+RetSqlCond("SD2")
				// cliente e loja
				_cQuery += "     AND D2_CLIENTE = '"+SD1->D1_FORNECE+"' AND D2_LOJA = '"+SD1->D1_LOJA+"' "
				// nota, serie e item
				_cQuery += "     AND D2_NFORI = '"+SD1->D1_DOC+"' AND D2_SERIORI = '"+SD1->D1_SERIE+"' AND D2_ITEMORI = '"+SD1->D1_ITEM+"' "
				// identb6 / numseq
				_cQuery += "     AND D2_IDENTB6 = B6_IDENT ) QTD_SAI_NF, "
				// quantidade em pedidos de venda
				_cQuery += " (SELECT SUM(C6_QTDVEN) "
				// itens do pedido de venda
				_cQuery += "    FROM "+RetSqlName("SC6")+" SC6 "
				// TES que Movimenta Estoque
				_cQuery += "INNER JOIN "+RetSqlName("SF4")+" SF4 ON "+RetSqlCond("SF4")+" AND F4_CODIGO = C6_TES AND F4_ESTOQUE = 'S' AND F4_PODER3 = 'D' "
				// filtro padrao
				_cQuery += "   WHERE "+RetSqlCond("SC6")
				// cliente e loja
				_cQuery += "     AND C6_CLI = '"+SD1->D1_FORNECE+"' AND C6_LOJA = '"+SD1->D1_LOJA+"' "
				// nota, serie e item
				_cQuery += "     AND C6_NFORI = '"+SD1->D1_DOC+"' AND C6_SERIORI = '"+SD1->D1_SERIE+"' AND C6_ITEMORI = '"+SD1->D1_ITEM+"' "
				// identb6 / numseq
				_cQuery += "     AND C6_IDENTB6 = B6_IDENT "
				// de outros pedidos
				_cQuery += "     AND C6_NUM <> '" + M->C5_NUM + "') QTD_PED_VEN "
				// saldo de mercadoria de terceiros em nosso poder
				_cQuery += " FROM "+RetSqlName("SB6")+" SB6 "
				// filtro padrao
				_cQuery += "WHERE "+RetSqlCond("SB6")
				// identb6
				_cQuery += "  AND B6_IDENT = '"+SD1->D1_IDENTB6+"' "
				// produto
				_cQuery += "  AND B6_PRODUTO = '"+SD1->D1_COD+"' "
				// agrupa dados
				_cQuery += "GROUP BY B6_IDENT "

				MemoWrit("c:\query\mt410tok_sfRatPeso_1.txt",_cQuery)

				// atualiza dados
				_aSaldoNf := U_SqlToVet(_cQuery)

				// atualiza varaiveis de quantidade
				_nQtdEntra := _aSaldoNf[1][2]
				_nSaidaSb6 := _aSaldoNf[1][3]
				_nSaidaSd2 := _aSaldoNf[1][4]
				_nSaidaSc6 := _aSaldoNf[1][5]

				// valida quantidades
				If ( (_nQtdEntra < (_nSaidaSb6 + _nTmpQuant)) .or. (_nQtdEntra < (_nSaidaSd2 + _nTmpQuant)) .or. (_nSaidaSb6 <> _nSaidaSd2) .or. (_nQtdEntra < (_nSaidaSc6 + _nTmpQuant)) )

					if (Type("__NRSOLC") == "U") .OR. (Type("__NRSOLC") == "C" .AND. IsInCallStack("U_TWMSA037")) // só exibe o erro se rodando via tela, e não por job
						HS_MsgInf("ATENÇÃO: PE MT410TOK" +CRLF+CRLF+;
						"Erro no cálculo de reserva de saldo em estoque" +CRLF+;
						"Nota: "+alltrim(SD1->D1_DOC) +CRLF+;
						"Produto: "+alltrim(SD1->D1_COD) +CRLF+;
						"Item: "+aCols[_nX][_nP_Item] +CRLF+;
						"Entradas: "+Str(_nQtdEntra) +CRLF+;
						"Saídas: "+Str(_nSaidaSd2) +CRLF+;
						"Solicitado: "+Str(_nTmpQuant) ,;
						"Reserva de Saldo em Estoque" ,;
						"Reserva de Saldo em Estoque" )
					EndIf
					// variavel de retorno
					_lRet := .f.

				EndIf

			EndIf

			// Caso variavel ja foi preechida.
			If (_lRet) .and. ( ! Empty(_ctpSeriPd) )
				Do Case //compara conteudo atribuido a variavel _cTPSERIPD com o conteudo da Acols posicionada.
					Case ( Subs(_cTpSeriPd,1,2) <> "DI" .and. Subs(aCols[_nX][_nP_Serie],1,2) == "DI" )
					_lPedVMist := .t. //Confirma pedido de venda misto
					_lRet := .f.

					Case ( Subs(_cTpSeriPd,1,2) == "DI" .and. Subs(aCols[_nX][_nP_Serie],1,2) <> "DI" )
					_lPedVMist := .t. //Confirma pedido de venda misto
					_lRet := .f.

				EndCase
			Else
				//se variavel estava vazia.
				_cTpSeriPd := aCols[_nX][_nP_Serie]

			EndIf

			// para calculo do rateio de peso e cubagem
			If (_lRet)

				// calcula o percentual de rateio do item
				_nPercRat := ((aCols[_nX][_nP_Quant] * 100) / SD1->D1_QUANT) / 100

				// reinicia variavel de controle de devolucao total do item
				_lDevTotal := .f.

				// 1-Quantidade
				// 2-Peso Bruto
				// 3-Peso Liquido
				// 4-Cubagem
				_aSaldo := sfRetSaldo(SD1->D1_QUANT,;
				SD1->D1_ZPESOB ,;
				SD1->D1_ZPESOL ,;
				SD1->D1_ZCUBAGE,;
				aCols[_nX][_nP_Item])

				// define se eh devolucao total do item
				_lDevTotal := (_aSaldo[1] == aCols[_nX,_nP_Quant])

				// verifica se o peso esta informado no produto
				dbSelectArea("SB1")
				SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
				SB1->(dbSeek( xFilial("SB1")+aCols[_nX][_nP_CodProd] ))

				If (SB1->B1_PESO > 0) .and. (SB1->B1_PESBRU > 0)
					// atualiza o peso liquido
					aCols[_nX,_nP_PesLiq] := NoRound((aCols[_nX,_nP_Quant] * SB1->B1_PESO),TamSx3("D1_ZPESOL")[2])
					// atualiza o peso bruto
					aCols[_nX,_nP_PesBru] := NoRound((aCols[_nX,_nP_Quant] * SB1->B1_PESBRU),TamSx3("D1_ZPESOB")[2])
				Else
					// devolucao total do item
					If ( _lDevTotal )
						// atualiza o peso liquido
						aCols[_nX,_nP_PesLiq] := NoRound(_aSaldo[3], TamSx3("D1_ZPESOL")[2])
						// atualiza o peso bruto
						aCols[_nX,_nP_PesBru] := NoRound(_aSaldo[2], TamSx3("D1_ZPESOB")[2])
						// devolucao parcial, calcula rateio
					ElseIf ( ! _lDevTotal )
						// atualiza o peso liquido
						aCols[_nX,_nP_PesLiq] := NoRound((SD1->D1_ZPESOL * _nPercRat), TamSx3("D1_ZPESOL")[2])
						// atualiza o peso bruto
						aCols[_nX,_nP_PesBru] := NoRound((SD1->D1_ZPESOB * _nPercRat), TamSx3("D1_ZPESOB")[2])

					EndIf

				EndIf

				// devolucao total do item
				If ( _lDevTotal )
					// atualiza a cubagem
					aCols[_nX,_nP_Cubag] := NoRound(_aSaldo[4], TamSx3("D1_ZCUBAGE")[2])
					// devolucao parcial, calcula rateio
				ElseIf ( ! _lDevTotal )
					// atualiza a cubagem
					aCols[_nX,_nP_Cubag] := NoRound((SD1->D1_ZCUBAGE * _nPercRat), TamSx3("D1_ZCUBAGE")[2])
				EndIf

				// Verifica se foi possivel calcular o peso bruto, liquido e cubagem de todos os itens
				If (aCols[_nX,_nP_PesBru] <= 0) .or. (aCols[_nX,_nP_PesLiq] <= 0) .or. (aCols[_nX,_nP_Cubag] <= 0)

					// apresenta mensagem 
					if (Type("__NRSOLC") == "U") .OR. (Type("__NRSOLC") == "C" .AND. IsInCallStack("U_TWMSA037")) // só exibe o erro se rodando via tela, e não por job
						HS_MsgInf("ATENÇÃO: PE MT410TOK"+CRLF+CRLF+;
						"Não foi possível calcular o peso bruto, líquido ou cubagem corretamente. "+CRLF+;
						"Nota: "+alltrim(SD1->D1_DOC)+CRLF+;
						"Produto: "+alltrim(SB1->B1_COD)+CRLF+;
						"Item: "+aCols[_nX][_nP_Item]+CRLF+;
						"Cubagem: "+AllTrim( Transf(aCols[_nX,_nP_Cubag],PesqPict("SD1","D1_ZCUBAGE")))+CRLF+;
						"Peso Liq: "+AllTrim( Transf(aCols[_nX,_nP_PesLiq],PesqPict("SD1","D1_ZPESOL")))+CRLF+;
						"Peso Bru: "+AllTrim( Transf(aCols[_nX,_nP_PesBru],PesqPict("SD1","D1_ZPESOB")))+CRLF+;
						"Saldo: "+AllTrim( Transf(_aSaldo[1],PesqPict("SB6","B6_SALDO")) )+CRLF+;
						"Perc.Rateio: "+AllTrim( StrZero(_nPercRat,9,6) ) ,;
						"Cálculo do Peso Bruto/Líquido/Cubagem",;
						"Cálculo do Peso Bruto/Líquido/Cubagem" )
					EndIf
					// Zera os dados no cabecalho
					M->C5_PESOL   := 0
					M->C5_PBRUTO  := 0
					M->C5_CUBAGEM := 0

					// variaval de controle
					_lRet := .f.
				EndIf

				// atualiza o total do peso bruto, liquido e cubagem no cabecalho
				M->C5_PESOL   += aCols[_nX,_nP_PesLiq]
				M->C5_PBRUTO  += aCols[_nX,_nP_PesBru]
				M->C5_CUBAGEM += aCols[_nX,_nP_Cubag]

			EndIf

		EndIf
	Next _nX

Return(_lRet)

// ** funcao que SEMPRE libera todos os itens do pedido
Static Function sfLibItens()

	// posicao dos campos QTD VENDIDA e QTD LIBERADA
	local _nP_QtdLib := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_QTDLIB" }) // quantidade liberada 1a und medida
	local _nP_QtdVen := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_QTDVEN" }) // quantidade vendida 1a und medida
	local _nP_QtdSeg := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_UNSVEN" }) // quantidade vendida segunda unidade medida
	local _nP_LibSeg := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_QTDLIB2"}) // quantidade liberada segunda unidade medida

	// variavel temporaria
	local _nX

	// varre todos os itens do pedido de venda, informando a quantidade liberada IGUAL a quantidade vendida,
	For _nX := 1 to Len(aCols)

		// se a linha nao estiver deletada
		If ( ! aCols[_nX][Len(aHeader)+1] )

			// atualiza quantidade liberada = quantidade vendida
			aCols[_nX][_nP_QtdLib] := aCols[_nX][_nP_QtdVen]
			aCols[_nX][_nP_LibSeg] := aCols[_nX][_nP_QtdSeg]

		EndIf

	Next _nX

Return(.t.)

// ** funcao para informar o endereco WMS para separacao do pedido
Static Function sfWmsDefEnd(mvWmsManual)
	// posicao dos campos no browse
	local _nP_WmsEnd  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_LOCALIZ"}) // localizaao
	local _nP_CodProd := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_PRODUTO"}) // codigo produto
	Local _nP_Local   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_LOCAL"  }) // Armazem do Produto

	// variavel temporaria
	local _nX

	// varre todos os itens do pedido de venda, informando a quantidade liberada IGUAL a quantidade vendida
	For _nX := 1 to Len(aCols)
		// se a linha nao estiver deletada
		If (!aCols[_nX][Len(aHeader)+1]) .and. ( (Empty(aCols[_nX][_nP_WmsEnd])) .or. (mvWmsManual) )
			// forca o endereco com o numero do pedido de venda
			If (mvWmsManual)
				aCols[_nX][_nP_WmsEnd] := sfRetEndPicking(aCols[_nX][_nP_CodProd], aCols[_nX][_nP_Local])
			ElseIf ( ! mvWmsManual )
				aCols[_nX][_nP_WmsEnd] := M->C5_NUM
			EndIf
		EndIf
	Next _nX

Return(.t.)

// ** funcao que atualiza preco de lista igual ao preco de venda (somente para servicos)
Static Function sfAtuPrcLista()
	// posicao dos campos PRC VENDA e PRC LISTA
	local _nP_PrcVen := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_PRCVEN"}) // preco/valor de venda
	local _nP_PrcLst := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_PRUNIT"}) // preco/valor de lista
	// variavel temporaria
	local _nX
	// variavel de retorno
	local _lRet := .t.

	// varre todos os itens do pedido de venda, e atualiza o preco de lista com o preco de venda
	For _nX := 1 to Len(aCols)
		// se a linha nao estiver deletada
		If ( ! aCols[_nX][Len(aHeader)+1])
			// atualiza preco de lista
			aCols[_nX][_nP_PrcLst] := aCols[_nX][_nP_PrcVen]
		EndIf
	Next _nX

Return(_lRet)

// ** funcao que define os vendedores, conforme cadastro de cliente
Static Function sfDefVend()
	// variavel de retorno
	local _lRet := .t.
	// relacao de campos
	local _aCmpVend := {}
	local _nCmpVend
	// campos
	local _cCmpVenC5
	local _cCmpVenA1
	local _cCmpComC5
	local _cCmpComA1

	// cria a lista de campos
	aAdd(_aCmpVend,{{"C5_VEND1","A1_VEND"  },{"C5_COMIS1","A1_COMIS"  }})
	aAdd(_aCmpVend,{{"C5_VEND2","A1_ZVEND2"},{"C5_COMIS2","A1_ZCOMIS2"}})
	aAdd(_aCmpVend,{{"C5_VEND3","A1_ZVEND3"},{"C5_COMIS3","A1_ZCOMIS3"}})
	aAdd(_aCmpVend,{{"C5_VEND4","A1_ZVEND4"},{"C5_COMIS4","A1_ZCOMIS4"}})
	aAdd(_aCmpVend,{{"C5_VEND5","A1_ZVEND5"},{"C5_COMIS5","A1_ZCOMIS5"}})

	// varre todos os campos
	For _nCmpVend := 1 to Len(_aCmpVend)

		// define nome de campos
		_cCmpVenC5 := _aCmpVend[_nCmpVend][1][1]
		_cCmpVenA1 := _aCmpVend[_nCmpVend][1][2]
		_cCmpComC5 := _aCmpVend[_nCmpVend][2][1]
		_cCmpComA1 := _aCmpVend[_nCmpVend][2][2]

		// verifica a existencia dos campos customizados
		If (SA1->(FieldPos(_cCmpVenA1)) > 0) .and. (SA1->(FieldPos(_cCmpComA1)) > 0)
			// atualiza os campos da memoria conforme cadastro do cliente
			M->(&(_cCmpVenC5)) := SA1->(&(_cCmpVenA1))
			M->(&(_cCmpComC5)) := SA1->(&(_cCmpComA1))
		EndIf

	Next _nCmpVend

Return(_lRet)

// ** funcao para validar somente um código de servico no mesmo pedido (somente para servicos)
Static Function sfVldCodISS()
	// posicao do campo CODIGO DO SERVICO ISS
	local _nP_CodIss := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_CODISS"}) // codigo do servico
	// variavel temporaria
	local _nX
	local _cCodIss := CriaVar("C6_CODISS",.f.)
	local _lPegaCod := .t.
	// variavel de retorno
	local _lRet := .t.

	// varre todos os itens do pedido de venda, e compara o codigo do servico iss
	For _nX := 1 to Len(aCols)
		// se a linha nao estiver deletada
		If ( ! aCols[_nX][Len(aHeader)+1])

			// atualiza o primeiro codigo do ISS
			If (_lPegaCod)
				_cCodIss  := aCols[_nX][_nP_CodIss]
				_lPegaCod := .f.
			EndIf

			// compara codigos
			If (_cCodIss != aCols[_nX][_nP_CodIss])
				Aviso("Tecadi: MT410TOK","É permitido apenas um Código de Serviço para pedidos de venda do tipo SERVICO.",{"OK"})
				_lRet := .f.
			EndIf

		EndIf
	Next _nX

Return(_lRet)

// ** funcao para validar a quantidade de SKU do Produto.
Static Function sfValQtdSKU()

	// posicao dos campos
	Local _nPosProduto := aScan(aHeader, {|x| AllTrim(x[2])=="C6_PRODUTO"}) // Código Produto
	Local _nPosQtd     := aScan(aHeader, {|x| AllTrim(x[2])=="C6_QTDVEN"})  // Quantidade

	// variavel de retorno
	local _lRetSKU := .t.

	// variaveis de controle
	Local _aPrdSKU := {}
	local _nPos := 0

	// Variaveis para calculo de Qauntidade SKU
	Local _aQtdSKU  := {}
	// Seek Z32
	Local _cSeekZ32 := ""

	// variaveis temporarias
	Local _nX, _nY
	Local _nRest := 0

	// varre todos os itens do pedido de venda
	For _nX := 1 to Len(aCols)

		// se a linha nao estiver deletada
		If ( ! aCols[_nX][Len(aHeader)+1])

			// verifica se o produto ja esta na lista
			_nPos := aScan(_aPrdSKU,{|x| (x[1] == aCols[_nX,_nPosProduto]) })

			// atualiza lista de produtos com totais
			If (_nPos == 0)
				Aadd(_aPrdSKU,{aCols[_nX,_nPosProduto],;
				aCols[_nX,_nPosQtd] })
			Else
				_aPrdSKU[_nPos][2] += aCols[_nX,_nPosQtd]
			EndIf

		EndIf
	Next _nX

	// varre todos os produtos e calcula a quantidade de SKU
	For _nX := 1 To Len(_aPrdSKU)

		// zera variaveis
		_aQtdSKU := {}

		// Tabela De SKU por Produto
		dbSelectArea("Z32")
		Z32->(dbSetOrder(1)) // 1-Z32_FILIAL+Z32_CODPRO+Z32_ORDEM
		Z32->(dbSeek( _cSeekZ32 := xFilial("Z32") + _aPrdSKU[_nX][1] ))

		// varre todos os itens do cadastro do produto
		While Z32->(!Eof()) .and. (Z32->(Z32_FILIAL+Z32_CODPRO) == _cSeekZ32 )
			// adiciona os valores disponiveis para separação.
			aadd(_aQtdSKU,Z32->Z32_QUANT)
			// proximo registro da Tabela
			Z32->(dbSkip())
		EndDo

		// Calculo para verificar se o valor escolhido bate com o controle de SKU.
		For _nY := 1 To Len(_aQtdSKU)

			// calcula o multiplo por SKU
			_nRest := Mod(_aPrdSKU[_nX][2],_aQtdSKU[_nY])

			// se for multiplo do SKU
			If (_nRest == 0)
				Exit
			Else
				_nQtdVen := _nRest
			EndIf

		Next _nY

		// Se houve quantidade que nao atende por SKU
		If (_nRest <> 0)
			Aviso("Tecadi: M410LIOK","Produto " + Alltrim(_aPrdSKU[_nX][1]) + "." + CRLF + "A Quantidade solicitada não está de acordo com o Lote Mínimo.",{"OK"})
			// atualiza variavel de retorno
			_lRetSKU := .f.
			// retorno
			Return(_lRetSKU)
		EndIf
	Next _nX

Return(_lRetSKU)

// ** funcao para validar se o produto tem quantidade disponivel no estoque.
// alterado por Eliane (Dataroute) em 23/09/15 para validar somente produtos sem rastro
Static Function sfValQtdSal()
	// posicao dos campos
	Local _nPosProduto := aScan(aHeader, {|x| AllTrim(x[2])=="C6_PRODUTO"}) // Código Produto
	Local _nPosQtd     := aScan(aHeader, {|x| AllTrim(x[2])=="C6_QTDVEN"})  // Quantidade
	Local _nPosLocal   := aScan(aHeader, {|x| AllTrim(x[2])=="C6_LOCAL"})   // Armazem do Produto

	// variavel de retorno
	local _lRetSal := .T.
	// variaveis de controle
	Local _aPrdSAL := {}
	local _nPos := 0

	// variaveis temporarias
	Local _nX := 0
	Local _nSaldo

	// varre todos os itens do pedido de venda
	For _nX := 1 to Len(aCols)

		// se a linha nao estiver deletada
		If ( ! aCols[_nX][Len(aHeader)+1])
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+aCols[_nX,_nPosProduto]))

			if !Rastro(aCols[_nX,_nPosProduto],"L")
				// verifica se o produto ja esta na lista
				_nPos := aScan(_aPrdSAL,{|x| (x[1] == aCols[_nX,_nPosProduto]) })

				// atualiza lista de produtos com totais
				If (_nPos == 0)
					Aadd(_aPrdSAL,{aCols[_nX,_nPosProduto],aCols[_nX,_nPosQtd], aCols[_nX,_nPosLocal]})
				Else
					_aPrdSAL[_nPos][2] += aCols[_nX,_nPosQtd]
				EndIf
			EndIf
		EndIf
	Next _nX

	//Vare os Itens e verifica se tem saldo para atender o PV.
	For _nX := 1 to Len(_aPrdSAL)

		// cadastro do produto
		dbSelectArea("SB1")
		SB1->(dbsetorder(1))
		If SB1->(dbseek(xFilial("SB1") + _aPrdSAL[_nX,1]))

			// saldo por produto x armazem
			dbSelectArea("SB2")
			SB2->(dbsetorder(1))
			If SB2->(dbseek(xFilial("SB2")+_aPrdSAL[_nX,1]+_aPrdSAL[_nX,3]))

				// Verifica saldo disponivel no estoque.(SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QACLASS - SB2->B2_QEMP)
				// obs: SaldoSB2 precisa estar posicionada no SB1 e SB2
				_nSaldo := SaldoSb2()

				// Compara saldo para veririfca se a quantidade informada é maior que a disponivel.
				If (_aPrdSAL[_nX,2] > _nSaldo)
					Aviso("Tecadi: M410LIOK","Produto " + Alltrim(_aPrdSAL[_nX,1]) + " não tem saldo em estoque para atender o pedido.",{"OK"})
					// Muda a variavel de retorno
					_lRetSal := .F.
					Return(_lRetSal)
				EndIf
			EndIf
		EndIf

	Next _nX

Return(_lRetSal)

// ** funcao para validar se foram informados lotes para o produto com rastro
// incluido por Eliane (Dataroute) em 23/09/2015
Static Function sfValLote()
	// posicao dos campos
	Local _nP_Cod    := aScan(aHeader, {|x| AllTrim(x[2])=="C6_PRODUTO"})
	local _nP_Ite    := aScan(aHeader, {|x| AllTrim(Upper(x[2]))=="C6_ITEM"})
	local _nP_Qtd    := aScan(aHeader, {|x| AllTrim(Upper(x[2]))=="C6_QTDVEN"})
	local _nP_LotCtl := aScan(aHeader, {|x| AllTrim(Upper(x[2]))=="C6_LOTECTL"})
	local _nP_Endere := aScan(aHeader, {|x| AllTrim(Upper(x[2]))=="C6_LOCALIZ"})

	// variavel de retorno
	local _lRetLot := .T.

	local _nPos := 0
	// variaveis temporarias
	Local _nX := 0
	local _nY := 0
	local _nQtd := 0

	// varre todos os itens do pedido de venda
	For _nX := 1 to Len(aCols)
		// se a linha nao estiver deletada
		If ( ! aCols[_nX][Len(aHeader)+1])

			dbSelectArea("SB1")
			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+aCols[_nX,_nP_Cod]))

			if Rastro(aCols[_nX,_nP_Cod],"L")

				// verifica se o lote está preenchido e foram selecionados volumes (se necessario via parâmetro)
				If ( Empty( aCols[_nX,_nP_LotCtl]) ) .OR. (_lVolJaDef .AND. AllTrim(aCols[_nX,_nP_Endere]) != 'DEVMERCCLI' )
					if aScan(_aLotesPV,{|x| x[_nL_Ite]==aCols[_nX][_nP_Ite]})==0
						Aviso( "Tecadi: MT410TOK","Nao foram informados lotes/volumes para o produto: "+aCols[_nX,_nP_Cod]+chr(10)+"Item: "+aCols[_nX][_nP_Ite],{"Aviso"})
						_lRetLot := .F.
						exit
					else
						_nQtd := 0
						for _nY:=1 to len(_aLotesPV)
							if 	_aLotesPV[_nY,_nL_Ite]==aCols[_nX][_nP_Ite]
								_nQtd += _aLotesPV[_nY,_nL_Qtd]
							EndIf
						next _nY
						if _nQtd <> aCols[_nX][_nP_Qtd]
							Aviso("Tecadi: MT410TOK","Item: "+aCols[_nX,_nP_Ite]+"--->Qtd informada nos lotes= "+str(_nQtd)+chr(10)+"diferente da quantidade do pedido= "+str(aCols[_nX][_nP_Qtd]),{"Aviso"})
							_lRetLot := .F.
							exit
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	next

return(_lRetLot)

// Validar saldos por lote
// variavel _aLotesPV
// pos. 1 = item
// pos. 2 = produto
// pos. 3 = lote
// pos. 4 = pallet
// pos. 5 = localizacao
// pos. 6 = local
// pos. 7 = quantidade
// pos. 8 = numseq
// pos. 9 = etiqueta de volume

Static Function sfValQtdLot()
	// posicao dos campos
	Local _nP_Cod := aScan(aHeader, {|x| AllTrim(x[2])=="C6_PRODUTO"}) // Código Produto
	local _nP_Ite := aScan(aHeader,{|x| AllTrim(x[2])=="C6_ITEM"})

	// variavel de retorno
	local _lRetSal := .T.

	// variaveis temporarias
	Local _nX := 0
	local _nY	:= 0
	local _nPos := 0

	local _aSaldos		:= {}
	Local _aPrdLote := {}
	Local _nSaldo		:= 0
	local _nEstorno := 0
	local _nUsado		:= 0

	// posicoes do array
	// pos.1=produto
	// pos.2=qtd
	// pos.3=local
	// pos.4=lote
	// pos.5=ID Palete

	// varre todos os itens do pedido de venda e acumula por lote
	For _nX := 1 to Len(aCols)

		If ( ! aCols[_nX][Len(aHeader)+1])

			dbSelectArea("SB1")
			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+aCols[_nX,_nP_Cod]))

			if Rastro(aCols[_nX,_nP_Cod],"L")

				for _nY := 1 to Len(_aLotesPV)

					if (_aLotesPV[_nY,_nL_Ite] == aCols[_nX][_nP_Ite])

						// verifica se o produto ja esta na lista
						_nPos := aScan(_aPrdLote,{|x| (x[1]==aCols[_nX,_nP_Cod]) .and. (x[3]==_aLotesPV[_nY,_nL_Amz]) .and. (x[4]==_aLotesPV[_nY,_nL_Lot]) })

						// atualiza lista de produtos com totais
						If (_nPos == 0)
							Aadd(_aPrdLote,{aCols[_nX,_nP_Cod],_aLotesPV[_nY,_nL_Qtd], _aLotesPV[_nY,_nL_Amz], _aLotesPV[_nY,_nL_Lot]})
						Else
							_aPrdLote[_nPos][2] += _aLotesPV[_nY,_nL_Qtd]
						EndIf

					EndIf

				next _nY

			EndIf
		EndIf
	Next _nX

	//Varre os Itens e verifica se tem saldo para atender o PV.
	For _nX := 1 to Len(_aPrdLote)

		// cadastro do produto
		dbSelectArea("SB1")
		SB1->(dbsetorder(1))
		If SB1->(dbseek(xFilial("SB1") + _aPrdLote[_nX,1]))

			// retorna o saldo do lote (B8_SALDO - B8_EMPENHO)
			_nSaldo := U_ftPesqLo(_aPrdLote[_nX,1],_aPrdLote[_nX,4],_aPrdLote[_nX,3])

			// total utilizado no pedido
			_nUsado := _aPrdLote[_nX,2]

			// se estiver alterando o pedido desconsidera as liberacoes da SC9 para este produto, item,lote e armazem
			// pois ja foram subtraidas do saldo da SB8 e serao excluidas
			_nEstorno := 0

			if ALTERA
				_nEstorno := U_ftSomaLib(M->C5_NUM,_aPrdLote[_nX,1],_aPrdLote[_nX,4],_aPrdLote[_nX,3])
			EndIf

			// Compara saldo para verificar se a quantidade informada é maior que a disponivel.
			If (_nUsado > _nSaldo + _nEstorno)
				Aviso("Tecadi: MT410TOK","Lote: "+Alltrim(_aPrdLote[_nX,4])+" do produto " + Alltrim(_aPrdLote[_nX,1]) + " não tem saldo em estoque para atender o pedido.",{"OK"})
				// Muda a variavel de retorno
				_lRetSal := .F.
				Return(_lRetSal)
			EndIf
		EndIf

	Next _nX

Return(_lRetSal)

// ** funcao que valida se houve alteracao de campos chaves nos itens do pedido de venda
Static Function sfVldAltMap

	// variavel temporaria
	local _nX
	local _nCampo
	local _nPosCampo
	local _cTmpCampo

	// vetor com campos a serem validados
	local _aCmpVld := {"C6_PRODUTO", "C6_QTDVEN", "C6_PRCVEN", "C6_VALOR", "C6_LOCAL", "C6_NFORI", "C6_SERIORI", "C6_ITEMORI"}

	// posicao do campo item do pedido
	local _nP_Item := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ITEM"}) // Item do PV

	// variavel de retorno
	local _lRet := .t.

	// varre todos os itens do pedido de venda, validando alterações em campos chaves dos itens do PV
	For _nX := 1 to Len(aCols)

		// posiciona no item do pedido de venda
		dbSelectArea("SC6")
		SC6->(dbSetOrder(1)) //1-C6_FILIAL, C6_NUM, C6_ITEM
		SC6->( dbSeek( xFilial("SC6")+M->C5_NUM+aCols[_nX][_nP_Item] ))

		// se o item foi excluído
		If ( aCols[_nX][Len(aHeader)+1] ) .and. (SC6->(Found()))
			Aviso("Tecadi: MT410TOK","O Item "+aCols[_nX][_nP_Item]+" não pode ser deletado pois já tem mapa gerado.",{"OK"})
			_lRet := .f.
		ElseIf  ( ! aCols[_nX][Len(aHeader)+1] ) .and. ( ! SC6->(Found()))
			Aviso("Tecadi: MT410TOK","O Item "+aCols[_nX][_nP_Item]+" não pode ser incluído pois já tem mapa gerado.",{"OK"})
			_lRet := .f.
		ElseIf  ( ! aCols[_nX][Len(aHeader)+1] ) .and. (SC6->(Found()))
			For _nCampo := 1 to len(_aCmpVld)
				_cTmpCampo := _aCmpVld[_nCampo]
				_nPosCampo := aScan(aHeader,{|x| AllTrim(Upper(x[2]))==_cTmpCampo})

				// valido se houve alterações nos campos
				If (aCols[_nX][_nPosCampo] != SC6->(&(_cTmpCampo)))
					Aviso("Tecadi: MT410TOK","O Item "+aCols[_nX][_nP_Item]+" não pode ser alterado pois já tem mapa gerado.",{"OK"})
					_lRet := .f.
				EndIf
			Next _nCampo
		EndIf
	Next _nX
Return _lRet

// ** funcao que retorna o saldo disponivel, considerando pedidos anteriores e itens do pedido atual
Static Function sfRetSaldo(mvEntQtd, mvEntPeB, mvEntPeL, mvEntCub, mvItAtual)
	// variavel temporaria
	local _nLin
	local _aTmpSaldo
	// query
	local _cQuery
	// variavel de retorno
	// 1-Quantidade
	// 2-Peso Bruto
	// 3-Peso Liquido
	// 4-Cubagem
	local _aSaldo := {mvEntQtd, mvEntPeB, mvEntPeL, mvEntCub}

	// posicao dos campos
	local _nP_Item    := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ITEM"   }) // item do pedido de venda
	local _nP_IdentB6 := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_IDENTB6"}) // id do controle de poder de terceiros
	local _nP_Quant   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_QTDVEN" }) // quantidade
	local _nP_PesoB   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ZPESOB" }) // peso bruto
	local _nP_PesoL   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ZPESOL" }) // peso liquido
	local _nP_Cubag   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ZCUBAGE"}) // cubagem

	// monta query para calcular o saldo disponivel
	_cQuery := "SELECT ISNULL(SUM(C6_QTDVEN), 0)  C6_QTDVEN,
	_cQuery += "       ISNULL(SUM(C6_ZPESOB), 0)  C6_ZPESOB,
	_cQuery += "       ISNULL(SUM(C6_ZPESOL), 0)  C6_ZPESOL,
	_cQuery += "       ISNULL(SUM(C6_ZCUBAGE), 0) C6_ZCUBAGE "
	// itens de outros pedidos
	_cQuery += "FROM "+RetSqlTab("SC6")
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SC6")+" "
	// cliente
	_cQuery += "AND C6_CLI     = '"+SD1->D1_FORNECE+"' AND C6_LOJA = '"+SD1->D1_LOJA+"' "
	// produto
	_cQuery += "AND C6_PRODUTO = '"+SD1->D1_COD+"' "
	// nota fiscal, serie e item
	_cQuery += "AND C6_NFORI   = '"+SD1->D1_DOC+"' AND C6_SERIORI = '"+SD1->D1_SERIE+"' AND C6_ITEMORI = '"+SD1->D1_ITEM+"' "
	// id de controle de saldo de poder de terceiros
	_cQuery += "AND C6_IDENTB6 = '"+SD1->D1_IDENTB6+"' "
	// outros pedidos
	_cQuery += "AND C6_NUM    <> '"+M->C5_NUM+"' "
	// bloqueio de residuo
	_cQuery += "AND C6_BLQ <> 'R' "

	memowrit("c:\query\mt410tok_sfRetSaldo.txt",_cQuery)

	// saldo temporarios de outros pedidos de venda
	_aTmpSaldo := U_SqlToVet(_cQuery)

	// reduz o saldo disponivel de outros pedidos de venda
	_aSaldo[1] -= _aTmpSaldo[1][1] // quantidade
	_aSaldo[2] -= _aTmpSaldo[1][2] // peso bruto
	_aSaldo[3] -= _aTmpSaldo[1][3] // peso liquido
	_aSaldo[4] -= _aTmpSaldo[1][4] // cubagem

	// varre todos os itens do pedido atual, para calcula consumo atual
	For _nLin := 1 to Len(aCols)

		// valida somente itens anteriores
		If (aCols[_nLin][_nP_Item] >= mvItAtual)
			Exit
		EndIf

		// valida o id do controle de poder de terceiros
		If (aCols[_nLin][_nP_IdentB6] == SD1->D1_IDENTB6) .and. (aCols[_nLin][_nP_Item] < mvItAtual)

			// reduz o saldo disponivel dos itens do pedido atual
			_aSaldo[1] -= aCols[_nLin][_nP_Quant] // quantidade
			_aSaldo[2] -= aCols[_nLin][_nP_PesoB] // peso bruto
			_aSaldo[3] -= aCols[_nLin][_nP_PesoL] // peso liquido
			_aSaldo[4] -= aCols[_nLin][_nP_Cubag] // cubagem

		EndIf

	Next _nLin


Return(_aSaldo)

// ** funcao que retorna o endereco de picking padrao, para WMS manual
Static Function sfRetEndPicking(mvCodProduto, mvCodArmaz)
	// variavel de retorno
	local _cEndRet := ""
	// estruturas fisicas disponiveis para geracao de mapa de separacao
	local _cEstFisMapa := U_FtWmsParam("WMS_EXPEDICAO_MAPA_APANHE_ESTRUTURA_FISICA", "C", "000002/000003/000007", .f., "", M->C5_CLIENTE, M->C5_LOJACLI, Nil, Nil)
	// query
	local _cQuery

	// prepara query que busca o endereco de picking manual
	_cQuery := " SELECT BE_LOCALIZ "
	_cQuery += " FROM   " + RetSqlTab("SBE") + " (NOLOCK) "
	_cQuery += " WHERE  " + RetSqlCond("SBE")
	_cQuery += "        AND BE_CODPRO = '" +mvCodProduto+ "' "
	_cQuery += "        AND BE_LOCAL = '" +mvCodArmaz+ "' "
	_cQuery += "        AND BE_ESTFIS IN "+FormatIn(_cEstFisMapa,"/")
	_cQuery += "        AND SUBSTRING(BE_LOCALIZ,1,2) = '01' "

	// executa query e atualiza variavel
	_cEndRet := U_FtQuery(_cQuery)

	// se nao tem dados, preenche com o codigo do pedido
	If (Empty(_cEndRet))
		_cEndRet := M->C5_NUM
	EndIf

	// padroniza tamanho da variavel
	_cEndRet := PadR(_cEndRet, TamSx3("C6_LOCALIZ")[1])

Return(_cEndRet)

// função auxiliar para pesquisar se existe saldo a endereçar na nota fiscal
Static Function sfNFSDA (mvCodcli, mvLojCli, mvNF, mvSerie)
	local _lRet := .T.
	local _cQry := ""

	// verifica se a nota fiscal possui saldo a endeçar
	_cQry := "SELECT IsNull(Count(*),0) QTD "
	_cQry += " FROM " + RetSqlTab("SDA") + " (NOLOCK) "
	_cQry += " WHERE " + RetSqlCond("SDA")
	_cQry += "       AND DA_SALDO > 0                  "
	_cQry += "       AND DA_CLIFOR  = '" + mvCodCli + "'"
	_cQry += "       AND DA_LOJA    = '" + mvLojCli + "'"
	_cQry += "       AND DA_DOC     = '" + mvNF     + "'"
	_cQry += "       AND DA_SERIE   = '" + mvSerie	+ "'"

	If ( U_FTQuery(_cQry) != 0)
		// retorno
		_lRet := .F.

		// avisa usuario
		Help( Nil, Nil, "MT410TOK.F01.001", Nil, "Nota fiscal " + mvNF + " / " + mvSerie + " possui saldo a endereçar.",;
		1,;
		0,;
		Nil, Nil, Nil, Nil, Nil,;
		{"Verifique se há ordem de serviço de recebimento ainda a realizar ou em execução."})  
	EndIf


Return (_lRet)


// função auxiliar para verificar se existe TFAA ainda não resolvido (devolvido) para a NF origem sendo usada
// no pedido de venda
Static Function sfNFTFAA (mvCodcli, mvLojCli, mvNF, mvSerie)
	local _lRet := .T.
	local _cQry := ""
	local _aRet := {}

	// verifica se a nota fiscal origem possui TFAA em aberto
	_cQry := " SELECT C6_NUM "
	_cQry += " FROM   " + RetSqlTab("SC6") + " (NOLOCK) "
	_cQry += " WHERE " + RetSqlCond("SC6")
	_cQry += "        AND C6_LOCALIZ = 'DEVMERCCLI' "
	_cQry += "        AND C6_NOTA = ''              "
	_cQry += " 	      AND C6_NFORI   = '" + mvNF     + "'"
	_cQry += " 	      AND C6_SERIORI = '" + mvSerie  + "'"
	_cQry += " 	      AND C6_CLI     = '" + mvCodcli + "'"
	_cQry += " 	      AND C6_LOJA    = '" + mvLojCli + "'"

	_aRet := U_SqlToVet(_cQry)
	
	// se achou pedido
	If ( Len(_aRet) > 0)
		// retorno
		_lRet := .F.

		// avisa usuario
		Help( Nil, Nil, "MT410TOK.F01.002", Nil, "Nota fiscal " + mvNF + " / " + mvSerie + " possui TFAA em aberto ainda não resolvido.",;
		1,;
		0,;
		Nil, Nil, Nil, Nil, Nil,;
		{"Efetue o processo de TFAA referente esta nota fiscal no pedido " + _aRet[1] + " em sua TOTALIDADE antes de utilizar a NF origem em outro pedido. Devolva/fature o pedido TFAA ou entre em contato com a coordenação."})  
	EndIf


Return (_lRet)