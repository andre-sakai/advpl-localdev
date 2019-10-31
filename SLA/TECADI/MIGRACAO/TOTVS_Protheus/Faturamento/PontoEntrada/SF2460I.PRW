#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! PE Após a Gravação dos Dados da NF de Saída             !
!                  ! 1. Utilizado para ratear as naturezas do titulo         !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 08/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function SF2460I()
	// area inicial
	local _aAreaAtu := GetArea()

	// rateio de naturezas (somente para notas com Gera Financ = SIM)
	If (SF2->F2_VALFAT > 0)
		// executa o rateio de naturezas
		sfRatNatur()
	EndIf		

	// restaura area inicial
	RestArea(_aAreaAtu)
Return

//** funcao que pesquisa o rateio das naturezas
Static Function sfRatNatur()
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSD2 := SD2->(GetArea())
	local _aAreaSB1 := SB1->(GetArea())
	local _aAreaSE1 := SE1->(GetArea())
	// Seek no SD2
	local _cSeekSD2
	// natureza do produto
	local _cNatProd
	// controle do total de rateio
	local _nRateio := 0
	local _nTotRat := 0
	// qtd casas decimais rateio
	local _nDecPerc := TamSx3("EV_PERC")[2]
	// posicao da natureza
	local _nPosNat
	// rateio de naturezas
	local _aRatNatur := {}

	// Seek do SE1
	local _cSeekSE1
	// variavel temporaria
	local _nX := 0
	// controle do valor total rateado
	local _nVlrRateio := 0
	local _nVlrTotRat := 0
	// qtd casas decimais rateio
	local _nDecVlr  := TamSx3("EV_VALOR")[2]

	// pesquisa os itens da nota
	dbSelectArea("SD2")
	SD2->(dbSetOrder(3)) //3-D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, D2_COD, D2_ITEM
	If SD2->(dbSeek( _cSeekSD2 := xFilial("SD2")+SF2->(F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA) ))
		While SD2->(!Eof()).and.(SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA)==_cSeekSD2)
			// pesquisa a natureza do produto
			_cNatProd := Posicione("SB1",1, xFilial("SB1")+SD2->D2_COD ,"B1_ZCODNAT")
			// caso nao tenha natureza no produto
			If (Empty(_cNatProd))
				Aviso("Tecadi: SF2460I","Produto "+AllTrim(SD2->D2_COD)+" sem natureza financeira informada! O rateio financeiro ficará incorreto!",{"OK"})
				Return(.f.)
			EndIf
			// calcula o rateio, de acordo com o total da nota
			_nRateio := Round( ((SD2->D2_TOTAL*100)/SF2->F2_VALFAT) , _nDecPerc )
			// pesquisa a natureza
			_nPosNat := aScan(_aRatNatur,{|x|x[1]==_cNatProd})
			// armazena rateio
			If (_nPosNat > 0)
				_aRatNatur[_nPosNat,2] += _nRateio
			Else
				aAdd(_aRatNatur,{ _cNatProd , _nRateio })
			EndIf
			// total de rateio
			_nTotRat += _nRateio
			// proximo item
			SD2->(dbSkip())
		EndDo
		// no ultimo item, verifica o rateio total
		If (_nTotRat <> 100)
			// pesquisa a natureza
			_nPosNat := aScan(_aRatNatur,{|x|x[1]==_cNatProd})
			// valor maior (diminui)
			If (_nTotRat > 100)
				_aRatNatur[_nPosNat,2] -= (_nTotRat - 100)
			// valor menor (acrescenta)
			ElseIf (_nTotRat < 100)
				_aRatNatur[_nPosNat,2] += (_nTotRat - 100)
			EndIf
		EndIf
	EndIf

	// executa o rateio dos titulos
	If (Len(_aRatNatur)>0)
		// pesquisa os titulos
		dbSelectArea("SE1")
		SE1->(dbSetOrder(2)) //2-E1_FILIAL, E1_CLIENTE, E1_LOJA, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO
		SE1->(dbSeek( _cSeekSE1 := xFilial("SE1")+SF2->(F2_CLIENTE+F2_LOJA+F2_PREFIXO+F2_DUPL) ))
		While SE1->(!Eof()).and.(SE1->(E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM)==_cSeekSE1)
			// somente os titulos da nota
			If (AllTrim(SE1->E1_TIPO)<>"NF")
				SE1->(dbSkip())
				Loop
			EndIf
			
			// zera valores por parcela
			_nVlrRateio := 0
			_nVlrTotRat := 0
		
			// se for apenas 1 natureza, nao rateia
			If (Len(_aRatNatur)==1)
				dbSelectArea("SE1")
				RecLock("SE1")
				SE1->E1_NATUREZ := _aRatNatur[1,1]
				SE1->(MsUnLock())
			Else
				// marca o titulo com multiplas naturezas
				dbSelectArea("SE1")
				RecLock("SE1")
				SE1->E1_MULTNAT := "1"
				SE1->E1_NATUREZ := "01010101"
				SE1->(MsUnLock())
	
				// alimenta o rateio
				For _nX := 1 to Len(_aRatNatur)

					// calcula o valor do rateio
					If (Len(_aRatNatur)==_nX)
						_nVlrRateio := Round( SE1->E1_VALOR - _nVlrTotRat ,_nDecVlr)
					Else
						_nVlrRateio := Round( ((SE1->E1_VALOR * _aRatNatur[_nX,2])/100) ,_nDecVlr)
						_nVlrTotRat += _nVlrRateio
					EndIf
		
					// inclui registro de rateio de naturezas
					dbSelectArea("SEV")
					RecLock("SEV",.t.)
					SEV->EV_FILIAL	:= xFilial("SEV")
					SEV->EV_PREFIXO	:= SE1->E1_PREFIXO
					SEV->EV_NUM		:= SE1->E1_NUM
					SEV->EV_PARCELA	:= SE1->E1_PARCELA
					SEV->EV_CLIFOR	:= SE1->E1_CLIENTE
					SEV->EV_LOJA	:= SE1->E1_LOJA
					SEV->EV_TIPO	:= SE1->E1_TIPO
					SEV->EV_VALOR	:= _nVlrRateio
					SEV->EV_NATUREZ	:= _aRatNatur[_nX,1]
					SEV->EV_RECPAG	:= "R"
					SEV->EV_PERC	:= (_aRatNatur[_nX,2] / 100)
					SEV->EV_RATEICC	:= '2'
					SEV->EV_IDENT	:= '1'
					SEV->(MsUnLock())
				Next _nX
			EndIf
			// proximo titulo
			dbSelectArea("SE1")
			SE1->(dbSkip())
		EndDo
	EndIf
	
	// restaura area inicial
	RestArea(_aAreaSE1)
	RestArea(_aAreaSB1)
	RestArea(_aAreaSD2)
	RestArea(_aAreaAtu)

Return(.t.)