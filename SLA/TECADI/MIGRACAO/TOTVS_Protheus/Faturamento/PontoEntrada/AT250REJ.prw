#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada na rotina de reajuste de contratos     !
!                  ! - reajustar tabelas customizadas                        !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 05/2017 !
+------------------+--------------------------------------------------------*/

User Function AT250REJ()
	// area inicial
	local _aAreaAtu := GetArea()
	Local _aAreaSB1 := SB1->(GetArea())
	// valor reajuste (arredondado)
	local _nVlrReaj := 0
	local _nTotReaj := 0

	// posiciona no produto do item do contrato
	dbSelectArea("SB1")
	SB1->(dbSetOrder(1))
	SB1->(dbSeek( xFilial("SB1") + AAN->AAN_CODPRO ))

	// FRETES
	If (SB1->B1_TIPOSRV=='4')
		sfReaFrete(mv_par11)
	EndIf

	// OUTROS SERVICOS
	If (SB1->B1_TIPOSRV=='7')
		sfReaOutrosServicos(mv_par11)
	EndIf

	// extra valor reajustado, para posterior arredondamento (chamado #13481)
	_nVlrReaj := AAN->AAN_VLRUNI
	_nTotReaj := AAN->AAN_VALOR

	// para este servicos, sempre valor 1
	If (SB1->B1_TIPOSRV $ '4|7')
		_nVlrReaj := 1
		_nTotReaj := 1
	EndIf

	// atualiza valor (arredondado)
	RecLock("AAN",.F.)
	AAN->AAN_VLRUNI := Round(_nVlrReaj, TamSx3("AAN_VALOR")[2])
	AAN->AAN_VALOR  := Round(_nTotReaj, TamSx3("AAN_VALOR")[2])
	MsUnLock()

	// grava log do processamento
	U_FtGeraLog(xFilial("AAN"), "AAN", xFilial("AAN") + AAN->AAN_CONTRT + AAN->AAN_ITEM + AAN->AAN_CODPRO, "Reajuste aplicado com sucesso. Item: "+AAN->AAN_ITEM+" Serviço: "+AllTrim(AAN->AAN_CODPRO)+" Percentual: "+AllTrim(Str(mv_par11)), "FAT", "")

	// restaura area inicial
	RestArea(_aAreaSB1)
	RestArea(_aAreaAtu)

Return

// ** funcao que reajusta a tabela de fretes
Static Function sfReaFrete(mvFator)
	// seek
	local _cSeekSZ5

	// pesquisa tabela de frete
	dbSelectArea("SZ4")
	SZ4->(dbSetOrder(1)) // 1-Z4_FILIAL, Z4_CODIGO
	If SZ4->(dbSeek( xFilial("SZ4")+AAN->AAN_TABELA ))
		// pesquisa itens da tabela de frete
		dbSelectArea("SZ5")
		SZ5->(dbSetOrder(1)) // 1-Z5_FILIAL, Z5_CODIGO, Z5_ITEM
		SZ5->(dbSeek( _cSeekSZ5 := xFilial("SZ5")+SZ4->Z4_CODIGO ))
		// varre todos os itens da tabela
		While SZ5->( ! Eof() ).and.(SZ5->(Z5_FILIAL+Z5_CODIGO) == _cSeekSZ5)
			// incremente com o fator
			RecLock("SZ5")
			SZ5->Z5_VALOR := Round(SZ5->Z5_VALOR * mvFator, TamSx3("AAN_VALOR")[2])
			SZ5->(MsUnLock())
			// proximo item
			SZ5->(dbSkip())
		EndDo
	EndIf

Return

// ** funcao que reajusta a tabela de servicos diversos
Static Function sfReaOutrosServicos(mvFator)
	// seek
	local _cSeekSZ9

	// pesquisa servicos diversos
	dbSelectArea("SZ9")
	SZ9->(dbSetOrder(1)) // 1-Z9_FILIAL, Z9_CONTRAT, Z9_ITEM, Z9_CODATIV
	SZ9->(dbSeek( _cSeekSZ9 := xFilial("SZ9") + AAN->AAN_CONTRT + AAN->AAN_ITEM ))
	// varre todos os itens da tabela
	While SZ9->( ! Eof() ).and.(SZ9->(Z9_FILIAL+Z9_CONTRAT+Z9_ITEM) == _cSeekSZ9)
		// incremente com o fator
		RecLock("SZ9")
		SZ9->Z9_VALOR := Round(SZ9->Z9_VALOR * mvFator, TamSx3("AAN_VALOR")[2])
		SZ9->(MsUnLock())
		// proximo item
		SZ9->(dbSkip())
	EndDo

Return