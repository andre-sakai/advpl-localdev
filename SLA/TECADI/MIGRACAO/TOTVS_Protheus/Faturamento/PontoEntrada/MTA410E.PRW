#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada na Exclusao do item do Pedido de Venda !
+------------------+---------------------------------------------------------+
!Uso               ! 1. Utilizado para estornar os detalhes dos servicos do  !
!                  !    faturamento de contratos                             !
+------------------+---------------------------------------------------------+
!Retorno           ! Sem Retorno                                             !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function MTA410E(mvFatCont, mvPedido, mvItem, mvCodServico)
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSB1 := SB1->(GetArea())
	// tipo do servico
	local _cTpServ := ""
	// seek do SRZ
	local _cSeekSZR
	// valores padroes dos parametros
	Default mvFatCont	 := .f.
	Default mvPedido	 := SC5->C5_NUM
	Default mvItem		 := SC6->C6_ITEM
	Default mvCodServico := SC6->C6_PRODUTO

	// somente (pedido NORMAL), (tipo SERVICO) e (NAO for ALTERACAO)
	If (mvFatCont).or.((cEmpAnt $ "01/02").and.(SC5->C5_TIPO=="N").and.(SC5->C5_TIPOOPE=="S").and.(!ALTERA))
		// retorna o tipo do servico
		_cTpServ := Posicione("SB1",1,xFilial("SB1")+ mvCodServico ,"B1_TIPOSRV")

		// ** 1-ARMAZENAGEM DE CONTAINER
		If (_cTpServ == "1")
			// rotina para estorno de armazenagem de container
			sfEstArmCnt(mvPedido, mvItem, mvCodServico)

			// ** 2-ARMAZENAGEM DE PRODUTOS
		ElseIf (_cTpServ == "2")
			// rotina para estorno de armazenagem de produtos
			sfEstArmPrd(mvPedido, mvItem, mvCodServico)

			// ** 3-PACOTE LOGISTICO
		ElseIf (_cTpServ $ "3/A/B")
			// rotina para estorno de pacote logistico
			sfEstPcteLog(mvPedido, mvItem, mvCodServico)

			// ** 4-TRANSF INTERNAS / FRETES
		ElseIf (_cTpServ == "4")
			// rotina para estorno de fretes
			sfEstFrete(mvPedido, mvItem, mvCodServico)

			// ** 5-SEGUROS
		ElseIf (_cTpServ == "5")
			// rotina para estorno de seguros
			sfEstSeguros(mvPedido, mvItem, mvCodServico)

			// ** 7-SERVICOS DIVERSOS
		ElseIf (_cTpServ == "7")
			// rotina para estorno de servicos diversos
			sfEstServico(mvPedido, mvItem, mvCodServico)

			// ** 8-VALORES FIXOS / ALUGUEIS
		ElseIf (_cTpServ == "8")
			// rotina para estorno de servicos diversos
			sfEstFixo(mvPedido, mvItem, mvCodServico)

		EndIf

		// estorna o resumo do faturamento
		dbSelectArea("SZR")
		SZR->(dbSetOrder(2)) // 2-ZR_FILIAL, ZR_PEDIDO, ZR_ITEPEDI
		SZR->(dbSeek( _cSeekSZR := xFilial("SZR")+mvPedido+mvItem ))
		While SZR->(!Eof()).and.(SZR->(ZR_FILIAL+ZR_PEDIDO+ZR_ITEPEDI)==_cSeekSZR)
			// verifica se eh o mesmo produto/servico
			If (AllTrim(SZR->ZR_CODSRV) == AllTrim(mvCodServico))
				// exclui o resumo
				RecLock("SZR")
				SZR->(dbDelete())
				MsUnLock()
			EndIf
			// proximo item
			SZR->(dbSkip())
		EndDo

	EndIf

	// restaura area inicial
	RestArea(_aAreaSB1)
	RestArea(_aAreaAtu)

Return

// ** funcao responsavel pelo estorno de armazenagem de container
// ** 1-ARMAZENAGEM DE CONTAINER
Static Function sfEstArmCnt(mvPedido, mvItem, mvProduto)
	// variaveis temporarias
	local _cQrySZG
	local _nItem
	// detalhes do servico
	local _aItens := {}
	// RIC de saida
	local _cRICSaida

	// monta a query para retornar os detalhes dos servicos
	_cQrySZG := "SELECT SZG.R_E_C_N_O_ SZGRECNO "
	_cQrySZG += "FROM "+RetSqlName("SZG")+" SZG "
	_cQrySZG += "WHERE "+RetSqlCond("SZG")+" "
	_cQrySZG += "AND ZG_STATUS  IN ('C','F') "
	_cQrySZG += "AND ZG_PEDIDO  = '"+mvPedido+"' "
	_cQrySZG += "AND ZG_ITEMPED = '"+mvItem+"' "
	_cQrySZG += "AND ZG_PRODUTO = '"+mvProduto+"' "

	// converte os itens em verot
	_aItens := U_SqlToVet(_cQrySZG)

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)
		// posiciona no registro real da tabela
		dbSelectArea("SZG")
		SZG->(dbGoTo(_aItens[_nItem]))

		// atualiza os dados da movimentacao da unidade
		dbSelectArea("SZ3")
		SZ3->(dbOrderNickName("Z3_RIC")) // 4-Z3_FILIAL, Z3_RIC
		If SZ3->(dbSeek( xFilial("SZ3")+SZG->ZG_RIC ))

			// marca a data anterior do faturamento
			RecLock("SZ3")
			SZ3->Z3_DTFATAR := SZG->ZG_DTANTER
			MsUnlock()

			// quando o container ja saiu, marca o movimento de saida como faturado
			If (!Empty(SZ3->Z3_DTSAIDA))
				// funcao para pesquisar a RIC de saida
				_cRICSaida := U_FtRetRIC(SZG->ZG_RIC)

				// atualiza os dados da movimentacao da unidade
				dbSelectArea("SZ3")
				SZ3->(dbOrderNickName("Z3_RIC")) // 4-Z3_FILIAL, Z3_RIC
				If SZ3->(dbSeek( xFilial("SZ3")+_cRICSaida ))
					// marca a data anterior do faturamento
					RecLock("SZ3")
					SZ3->Z3_DTFATAR := SZG->ZG_DTANTER
					MsUnlock()
				EndIf
			EndIF
		EndIf

		// excluo o item
		RecLock("SZG")
		SZG->(dbDelete())
		MsUnLock()

	Next _nItem

Return(.t.)

// ** funcao responsavel pelo estorno de armazenagem de produtos
// ** 2-ARMAZENAGEM DE PRODUTOS
Static Function sfEstArmPrd(mvPedido, mvItem, mvProduto)
	// variaveis temporarias
	local _cQrySZH, _cQryZ48
	local _nItem
	// detalhes do servico
	local _aItens := {}

	// monta a query para retornar os detalhes dos servicos
	_cQrySZH := "SELECT SZH.R_E_C_N_O_ SZHRECNO "
	_cQrySZH += "FROM "+RetSqlName("SZH")+" SZH "
	_cQrySZH += "WHERE "+RetSqlCond("SZH")+" "
	_cQrySZH += "AND ZH_STATUS  IN ('C','F') "
	_cQrySZH += "AND ZH_PEDIDO  = '"+mvPedido+"' "
	_cQrySZH += "AND ZH_ITEMPED = '"+mvItem+"' "
	_cQrySZH += "AND ZH_PRODUTO = '"+mvProduto+"' "

	// converte os itens em verot
	_aItens := U_SqlToVet(_cQrySZH)

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)
		// posiciona no registro real da tabela
		dbSelectArea("SZH")
		SZH->(dbGoTo(_aItens[_nItem]))

		// atualiza os dados da nota fiscal
		dbSelectArea("SF1")
		SF1->(dbSetOrder(1)) //1-F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO
		If SF1->(dbSeek(xFilial("SF1")+SZH->(ZH_DOC+ZH_SERIE+ZH_CLIENTE+ZH_LOJA)+"B"))
			// atualiza a ultima data de faturamento (ultimo dia mais 1)
			RecLock("SF1",.F.)
			SF1->F1_DTFATPR	:= SZH->ZH_DTANTER
			MsUnlock()
		EndIf

		// excluo o item
		RecLock("SZH")
		SZH->(dbDelete())
		MsUnLock()

	Next _nItem

	// estorno os detalhes do saldo por item da nota
	_cQryZ48 := " SELECT Z48.R_E_C_N_O_ Z48RECNO "
	_cQryZ48 += " FROM "+RetSqlTab("Z48")
	_cQryZ48 += " WHERE "+RetSqlCond("Z48")
	_cQryZ48 += " AND Z48_STATUS IN ('C','F') "
	_cQryZ48 += " AND Z48_PEDIDO = '"+mvPedido+"' "
	_cQryZ48 += " AND Z48_ITEMPV = '"+mvItem+"' "
	_cQryZ48 += " AND Z48_SERVIC = '"+mvProduto+"' "

	// converte os itens em vetor
	_aItens := U_SqlToVet(_cQryZ48)

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)

		// posiciona no registro real da tabela
		dbSelectArea("Z48")
		Z48->(dbGoTo(_aItens[_nItem]))

		// excluo o item
		RecLock("Z48")
		Z48->(dbDelete())
		MsUnLock()

	Next _nItem

Return(.t.)

// ** funcao responsavel pelo estorno de pacote logistico
// ** 3-PACOTE LOGISTICO
Static Function sfEstPcteLog(mvPedido, mvItem, mvServPacte)
	// variaveis temporarias
	local _cQrySZJ
	local _nItem
	// detalhes do servico
	local _aItens := {}
	// RECNO para exclusao do pacote
	local _aRecnoSZJ := {}

	// monta a query para retornar os detalhes dos servicos
	_cQrySZJ := "SELECT SZJ.R_E_C_N_O_ SZJRECNO, SZO.R_E_C_N_O_ SZORECNO, B1_TIPOSRV "
	// pacote logistico
	_cQrySZJ += "FROM "+RetSqlName("SZJ")+" SZJ "
	// itens do pacote logistico
	_cQrySZJ += "INNER JOIN "+RetSqlName("SZO")+" SZO ON "+RetSqlCond("SZO")+" AND ZO_PACOTE = ZJ_PACOTE AND ZO_SEQPACO = ZJ_SEQPACO "
	// cad. de produto
	_cQrySZJ += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND B1_COD = ZO_PRODUTO "
	// filtro do pacote
	_cQrySZJ += "WHERE "+RetSqlCond("SZJ")+" "
	_cQrySZJ += "AND ZJ_STATUS  IN ('C','F') "
	_cQrySZJ += "AND ZJ_PEDIDO  = '"+mvPedido+"' "
	_cQrySZJ += "AND ZJ_ITEMPED = '"+mvItem+"' "
	_cQrySZJ += "AND ZJ_PRODUTO = '"+mvServPacte+"' "

	// converte os itens em verot
	_aItens := U_SqlToVet(_cQrySZJ)

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)

		// posiciona no registro real da tabela
		dbSelectArea("SZJ")
		SZJ->(dbGoTo(_aItens[_nItem][1]))

		// armanena o recno do pacote
		If (aScan( _aRecnoSZJ, _aItens[_nItem][1] ) == 0)
			aAdd( _aRecnoSZJ, _aItens[_nItem][1] )
		EndIf

		// posiciona no registro real da tabela
		dbSelectArea("SZO")
		SZO->(dbGoTo(_aItens[_nItem][2]))

		// 4-TRANSF INTERNAS / FRETES / B-PACOTE DE SERVICOS
		If (_aItens[_nItem][3] $ "4/B")
			// rotina para estorno de fretes
			sfEstFrete(mvPedido, mvItem, SZO->ZO_PRODUTO)

			// ** 7-SERVICOS DIVERSOS
		ElseIf (_aItens[_nItem][3] == "7")
			// rotina para estorno de servicos diversos
			sfEstServico(mvPedido, mvItem, SZO->ZO_PRODUTO)

		EndIf

		// excluo o item
		RecLock("SZO")
		SZO->(dbDelete())
		MsUnLock()

	Next _nItem

	// ao final, exclui registros do pacote
	For _nItem := 1 to Len( _aRecnoSZJ )

		// posiciona no registro real da tabela
		dbSelectArea("SZJ")
		SZJ->(dbGoTo( _aRecnoSZJ[_nItem]) )

		// excluo o item
		If (SZJ->( ! Eof() ))
			RecLock("SZJ")
			SZJ->(dbDelete())
			MsUnLock()
		EndIf

	Next _nItem

Return(.t.)

// ** funcao responsavel pelo estorno de fretes
// ** 4-TRANSF INTERNAS / FRETES
Static Function sfEstFrete(mvPedido, mvItem, mvProduto)
	// variaveis temporarias
	local _cQrySZK
	local _nItem
	// detalhes do servico
	local _aItens := {}

	// monta a query para retornar os detalhes dos servicos
	_cQrySZK := "SELECT SZK.R_E_C_N_O_ SZKRECNO "
	_cQrySZK += "FROM "+RetSqlName("SZK")+" SZK "
	_cQrySZK += "WHERE "+RetSqlCond("SZK")+" "
	_cQrySZK += "AND ZK_STATUS  IN ('C','F') "
	_cQrySZK += "AND ZK_PEDIDO  = '"+mvPedido+"' "
	_cQrySZK += "AND ZK_ITEMPED = '"+mvItem+"' "
	_cQrySZK += "AND ZK_PRODUTO = '"+mvProduto+"' "

	// converte os itens em verot
	_aItens := U_SqlToVet(_cQrySZK)

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)
		// posiciona no registro real da tabela
		dbSelectArea("SZK")
		SZK->(dbGoTo(_aItens[_nItem]))

		// atualiza os dados da movimentacao da unidade
		dbSelectArea("SZ3")
		SZ3->(dbOrderNickName("Z3_RIC")) // 4-Z3_FILIAL, Z3_RIC
		If SZ3->(dbSeek( xFilial("SZ3")+SZK->ZK_RIC ))
			// marca a data de faturamento
			RecLock("SZ3",.F.)
			// se for pacote logistico
			If (!Empty(SZK->ZK_PACOTE))
				SZ3->Z3_DTFATPA := CtoD("//")
			EndIf
			// data de frete
			SZ3->Z3_DTFATFR := CtoD("//")
			MsUnlock()
		EndIf

		// excluo o item
		RecLock("SZK")
		SZK->(dbDelete())
		MsUnLock()

	Next _nItem

Return(.t.)

// ** funcao responsavel pelo estorno de seguros
// ** 5-SEGUROS
Static Function sfEstSeguros(mvPedido, mvItem, mvProduto)
	// variaveis temporarias
	local _cQrySZI, _cQryZ48
	local _nItem
	// detalhes do servico
	local _aItens := {}

	// monta a query para retornar os detalhes dos servicos
	_cQrySZI := "SELECT SZI.R_E_C_N_O_ SZIRECNO "
	_cQrySZI += "FROM "+RetSqlName("SZI")+" SZI "
	_cQrySZI += "WHERE "+RetSqlCond("SZI")+" "
	_cQrySZI += "AND ZI_STATUS  IN ('C','F') "
	_cQrySZI += "AND ZI_PEDIDO  = '"+mvPedido+"' "
	_cQrySZI += "AND ZI_ITEMPED = '"+mvItem+"' "
	_cQrySZI += "AND ZI_PRODUTO = '"+mvProduto+"' "

	// converte os itens em verot
	_aItens := U_SqlToVet(_cQrySZI)

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)
		// posiciona no registro real da tabela
		dbSelectArea("SZI")
		SZI->(dbGoTo(_aItens[_nItem]))

		// atualiza os dados da nota fiscal
		dbSelectArea("SF1")
		SF1->(dbSetOrder(1)) //1-F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO
		If SF1->(dbSeek(xFilial("SF1")+SZI->(ZI_DOC+ZI_SERIE+ZI_CLIENTE+ZI_LOJA)+"B"))
			// atualiza a ultima data de faturamento (ultimo dia mais 1)
			RecLock("SF1",.F.)
			SF1->F1_DTFATSE	:= SZI->ZI_DTANTER
			MsUnlock()
		EndIf

		// excluo o item
		RecLock("SZI")
		SZI->(dbDelete())
		MsUnLock()

	Next _nItem

	// estorno os detalhes do saldo por item da nota
	_cQryZ48 := " SELECT Z48.R_E_C_N_O_ Z48RECNO "
	_cQryZ48 += " FROM "+RetSqlTab("Z48")
	_cQryZ48 += " WHERE "+RetSqlCond("Z48")
	_cQryZ48 += " AND Z48_STATUS IN ('C','F') "
	_cQryZ48 += " AND Z48_PEDIDO = '"+mvPedido+"' "
	_cQryZ48 += " AND Z48_ITEMPV = '"+mvItem+"' "
	_cQryZ48 += " AND Z48_SERVIC = '"+mvProduto+"' "

	// converte os itens em vetor
	_aItens := U_SqlToVet(_cQryZ48)

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)

		// posiciona no registro real da tabela
		dbSelectArea("Z48")
		Z48->(dbGoTo(_aItens[_nItem]))

		// excluo o item
		RecLock("Z48")
		Z48->(dbDelete())
		MsUnLock()

	Next _nItem

Return(.t.)

// ** funcao responsavel pelo estorno de servicos diversos
// ** 7-SERVICOS DIVERSOS
Static Function sfEstServico(mvPedido, mvItem, mvProduto)
	// variaveis temporarias
	local _cQrySZL
	local _nItem
	// detalhes do servico
	local _aItens := {}

	// monta a query para retornar os detalhes dos servicos
	_cQrySZL := "SELECT SZL.R_E_C_N_O_ SZLRECNO "
	_cQrySZL += "FROM "+RetSqlName("SZL")+" SZL "
	_cQrySZL += "WHERE "+RetSqlCond("SZL")+" "
	_cQrySZL += "AND ZL_STATUS  IN ('C','F') "
	_cQrySZL += "AND ZL_PEDIDO  = '"+mvPedido+"' "
	_cQrySZL += "AND ZL_ITEMPED = '"+mvItem+"' "
	_cQrySZL += "AND ZL_PRODUTO = '"+mvProduto+"' "

	// converte os itens em verot
	_aItens := U_SqlToVet(_cQrySZL)

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)

		// posiciona no registro real da tabela
		dbSelectArea("SZL")
		SZL->(dbGoTo(_aItens[_nItem]))

		// atualiza os dados da OS - Itens
		dbSelectArea("SZ7")
		SZ7->(dbSetOrder(1)) //1-Z7_FILIAL, Z7_NUMOS, Z7_CODATIV
		If SZ7->(dbSeek( xFilial("SZ7")+SZL->(ZL_NUMOS+ZL_CODATIV) ))
			RecLock("SZ7")
			SZ7->Z7_DTFATAT	:= CtoD("//")
			SZ7->Z7_SALDO	+= SZL->ZL_QUANT
			MsUnlock()
		EndIf

		// atualiza os dados da OS - Cabec
		dbSelectArea("SZ6")
		SZ6->(dbSetOrder(1)) //1-Z6_FILIAL, Z6_NUMOS, Z6_CLIENTE, Z6_LOJA
		If SZ6->(dbSeek( xFilial("SZ6")+SZL->ZL_NUMOS ))
			RecLock("SZ6")
			SZ6->Z6_STATUS := sfRetStatus(SZL->ZL_NUMOS)
			MsUnlock()
		EndIf

		// excluo o item
		RecLock("SZL")
		SZL->(dbDelete())
		MsUnLock()

	Next _nItem

Return(.t.)

// ** funcao que retorna o status da OS (conforme faturamento dos itens)
Static Function sfRetStatus(mvNumOS)
	// area inicial
	local _aAreaSZ7 := SZ7->(GetArea())
	// status da OS
	local _cRetStatus := "F" //F-Finalizada
	// seek do SZ7
	local _cSeekSZ7

	// varre todos os itens da OS para verificar se ainda possui item faturado
	dbSelectArea("SZ7")
	SZ7->(dbSetOrder(1)) //1-Z7_FILIAL, Z7_NUMOS, Z7_CODATIV
	SZ7->(dbSeek( _cSeekSZ7 := xFilial("SZ7")+mvNumOS ))
	While SZ7->(!EOF()).and.(SZ7->(Z7_FILIAL+Z7_NUMOS)==_cSeekSZ7)
		// verifica a data de faturamento do servico
		If (!Empty(SZ7->Z7_DTFATAT))
			// muda o status
			_cRetStatus := "P" //P-Pedido de Venda
			Exit
		EndIf
		// proximo item da OS
		SZ7->(dbSkip())
	EndDo

	// restaura area inicial
	RestArea(_aAreaSZ7)

Return(_cRetStatus)

// ** funcao responsavel pelo estorno de valores fixos / alugueis
// ** 8-VALORES FIXOS / ALUGUEIS
Static Function sfEstFixo(mvPedido, mvItem, mvProduto)
	// variaveis temporarias
	local _cQrySZM
	local _nItem
	// detalhes do servico
	local _aItens := {}

	// monta a query para retornar os detalhes dos servicos
	_cQrySZM := "SELECT SZM.R_E_C_N_O_ SZMRECNO "
	_cQrySZM += "FROM "+RetSqlName("SZM")+" SZM "
	_cQrySZM += "WHERE "+RetSqlCond("SZM")+" "
	_cQrySZM += "AND ZM_STATUS  IN ('C','F') "
	_cQrySZM += "AND ZM_PEDIDO  = '"+mvPedido+"' "
	_cQrySZM += "AND ZM_ITEMPED = '"+mvItem+"' "
	_cQrySZM += "AND ZM_PRODUTO = '"+mvProduto+"' "

	// converte os itens em verot
	_aItens := U_SqlToVet(_cQrySZM)

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)

		// posiciona no registro real da tabela
		dbSelectArea("SZM")
		SZM->(dbGoTo(_aItens[_nItem]))

		// excluo o item
		RecLock("SZM")
		SZM->(dbDelete())
		MsUnLock()

	Next _nItem

Return(.t.)