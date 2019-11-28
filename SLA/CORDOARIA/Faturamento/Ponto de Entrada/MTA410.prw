#INCLUDE "rwmake.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³MTA410    º Autor ³ Clóvis Emmendorfer º Data ³  11/09/08   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Ponto de Entrada Apos a Confirmacao do Pedido de Vendas    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Especifico para Arteplas                                   º±±
±±º          ³ Cálculo do preço médio do pedido e comissão				  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

//Cálcula o peso Bruto e Líquido do pedido
//Cálcula o preço médio e a comissão
//Verifica se o representante esta desativado

User Function MTA410()

aHPMedio := {}

aadd(aHPMedio,{"Grupo 	  	   ", "C6_ITEMORI"  , "@!"					,  4, 0, "", "ÇÇÇÇÇÇÇÇÇÇÇÇÇÇá", "C", "SC6" })
aadd(aHPMedio,{"Quantidade     ", "C6_QTDVEN"   , "9999999999"			, 10, 0, "", "ÇÇÇÇÇÇÇÇÇÇÇÇÇÇá", "C", "SC6" })
aadd(aHPMedio,{"Valor Total    ", "C6_VALOR"    , "@E 99,999,999.99"  	, 15, 0, "", "ÇÇÇÇÇÇÇÇÇÇÇÇÇÇá", "C", "SC6" })
aadd(aHPMedio,{"Preço Medio    ", "C6_PRCVEN"   , "@E 99,999,999.9999"	, 15, 0, "", "ÇÇÇÇÇÇÇÇÇÇÇÇÇÇá", "C", "SC6" })
aadd(aHPMedio,{"PM Calculado   ", "C6_PRMEDIO"  , "@E 99,999,999.9999"	, 15, 0, "", "ÇÇÇÇÇÇÇÇÇÇÇÇÇÇá", "C", "SC6" })
aPMedio := {}
nCnt  	:= 0

_iPosPro := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_PRODUTO" })
_iQtdPro := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_QTDLIB"  })
_iPosVal := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_VALOR"   })
_iPosPre := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_PRCVEN"  })
_iPosQtd := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_QTDVEN"  })
_iPosIte := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_ITEM"    })
_iPosBlq := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_BLOQUEI" })
_iPosPmc := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_PMCALCU" })
_iPosDel := Len(aHeader) + 1
_nPeso	 := M->C5_PESOL

iPosPro := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_PRODUTO" })
iPosQtd := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_QTDVEN"  })
iPosVal := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_VALOR"   })
iPosQum := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_UNSVEN"  })
iPosUM  := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_UM"      })
iPosSUM := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_SEGUM"   })
iPosPrc := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_PRUNIT"  })
iPosCom := Ascan(aHeader,{|X| AllTrim(X[2]) == "C6_COMIS1"  })
iPosDel := Len(aHeader) + 1

nPeso  := Posicione("SB1",1,xFilial("SB1") + aCols[n,iPosPro],"B1_PESO")

If M->C5_TIPO == 'A' .or. M->C5_TIPO == '1' .or. M->C5_TIPO == '0' .or. M->C5_TIPO == 'N'
	M->C5_TIPO := "N"
Endif

If M->C5_CALCOM == "S" .AND. M->C5_COMIS1 > 0 .AND. ALLTRIM(M->C5_VEND1) <> '9000' //Verifica se é pra calcular a comissão pela tabela de comissões ou não.
	Comissao()
Endif                            

For n := 1 to Len(aCols)
	If !aCols[n,_iPosDel]
		_cCodPro  := aCols[n,_iPosPro]
		_cGrupo   := Substr(aCols[n,_iPosPro],1,4)
		_nQuant   := aCols[n,_iPosQtd]
		_nValor   := aCols[n,_iPosVal]
		_nQtdPro  := aCols[n,_iQtdPro]

		dbSelectArea("SG1")
		SG1->(DbSetOrder(1))
		SG1->(DbSeek(xFilial("SG1")+_cCodPro,.F.))
		If !SG1->(Eof())
			While !SG1->(Eof()) .and. SG1->G1_COD == _cCodPro
				If Posicione("SB1",1,xFilial("SB1")+SG1->G1_COMP,"B1_TIPO") == "EM"  // Somente se for Embalagens
					_nQuantItem := ExplEstr(_nQtdPro)
					_nPeso		:= _nPeso + (_nQuantItem * Posicione("SB1",1,xFilial("SB1")+SG1->G1_COMP,"B1_PESO"))
				Endif
				SG1->(DbSkip())
			Enddo
		Endif
		
		nPos := Ascan(aPMedio,{|x| x[1]==_cGrupo}) //Verifica se o grupo ja existe na array
		
		If nPos == 0
			_nPMCalc := (_nValor/_nQuant)
			aadd(aPMedio, {})
			nCnt++
			aadd(aPMedio[nCnt],_cGrupo)
			aadd(aPMedio[nCnt],_nQuant)
			aadd(aPMedio[nCnt],_nValor)
			aadd(aPMedio[nCnt],0)
			aadd(aPMedio[nCnt],_nPMCalc)
			aadd(aPMedio[nCnt],.f.)
		Else
			_nTotQuant := (aPMedio[nPos,2] + _nQuant)
			_nTotValor := (aPMedio[nPos,3] + _nValor)
			_nPMCalc   := (_nTotValor/_nTotQuant)
			aPMedio[nPos,2] := _nTotQuant
			aPMedio[nPos,3] := _nTotValor
			aPMedio[nPos,4] := 0
			aPMedio[nPos,5] := _nPMCalc
		EndIf
		
	Endif
	
Next

M->C5_PBRUTO := _nPeso

Return(.T.)

//ROTINA PARA CÁLCULO DO PREÇO MÉDIO E COMISSÃO POR PRODUTO - CLÓVIS (30/03/10)
//Alteração em 03/08/10 p/ contemplar nova forma de cálculo da comissão

Static Function Comissao()

nQuant := 0
nValor := 0
nComis := 0
nPrc1  := 0
nPrc2  := 0
nPrc3  := 0
nPreco := 0

//cCalcula := "S"

cVendedor := Alltrim(Posicione("SA3",1,xFilial("SA3") + M->C5_VEND1,"A3_NREDUZ"))

If cVendedor <> 'DESATIVADO'
	
	For n := 1 to Len(aCols)
		
		If !aCols[n,iPosDel]
			
			cGrupo := Posicione("SB1",1,xFilial("SB1") + aCols[n,iPosPro],"B1_GRUPO")
			
			If (Substr(cGrupo,1,1) >= 'A' .and. Substr(cGrupo,1,1) <= 'I') .or. Alltrim(cGrupo) == 'PV'
				
				If aCols[n,iPosUM] == 'KG'
					nQuant += aCols[n,iPosQtd]
				Else
					If aCols[n,iPosSUM] == 'KG'
						nQuant += aCols[n,iPosQum]
					Else
						nQuant += aCols[n,iPosQtd] * nPeso
					Endif
				Endif
				
				nValor += aCols[n,iPosVal]
				
				// cCalcula := "S"
				
				// Representantes Rio Verde e Coravale comissão por representante
				// A partir de 14/09/10 será calculada como os demais representantes, a pedido da Valéria.
				// If Alltrim(M->C5_VEND1) == '9066' .or. Alltrim(M->C5_VEND1) == '9002'
				// 		aCols[n,iPosCom] := 0
				//		cCalcula := "N"
				// Endif
				
				// If cCalcula == "S"
				
				nPreco := aCols[n,iPosPrc]
				
				If M->C5_TIPC=="S"
					nPreco := nPreco * 2
				Endif
				
				If M->C5_TIPC=="E"
					nPreco := nPreco + (nPreco * 80 / 20)
				Endif
				
				dbSelectArea("SZG") //CÁLCULO DA COMISSÃO NO PRODUTO BASEADO NA TABELA DE COMISSÕES
				dbSetOrder(2)
				
				If dbSeek(xFilial("SZG") + aCols[n,iPosPro])
					
					While !EOF() .and. aCols[n,iPosPro] == SZG->ZG_PRODUTO
						
						If nPreco >= SZG->ZG_PRCME1 .and. nPreco <= SZG->ZG_PRCME2
							nComis := SZG->ZG_COMISSA
						Endif
						
						dbSelectArea("SZG")
						dbSkip()
						
					Enddo
					
					If M->C5_TIPC=="S"
						nComis := nComis * 2
					Endif
					
					If M->C5_TIPC=="E"
						nComis := nComis + (nComis * 80 / 20)
					Endif
					
					If nComis == 0
						MsgBox("ATENÇÃO! PRODUTO " + ALLTRIM(aCols[n,iPosPro]) + " SEM FAIXA DE COMISSÃO PARA ESSE PREÇO.","Atencao","STOP")
					Else
						aCols[n,iPosCom] := nComis
						nComis := 0
					Endif
					
				Else
					
					aCols[n,iPosCom] := 0
					MsgBox("ATENÇÃO! PRODUTO " + ALLTRIM(aCols[n,iPosPro]) + " SEM TABELA DE COMISSÕES. NÃO SERÁ CALCULADA A COMISSÃO.","Atencao","STOP")
					
				Endif
				
				//Endif
				
			Endif
			
		Endif
		
	Next
	
	If M->C5_TIPC=="S"
		nValor := nValor * 2
	Endif
	
	If M->C5_TIPC=="E"
		nValor := nValor + (nValor * 80 / 20)
	Endif
	
	M->C5_PRCMED := nValor / nQuant
	
Else
	
	M->C5_COMIS1 := 0
	M->C5_PRCMED := 0
	MsgBox("ATENÇÃO! REPRESENTANTE DESATIVADO","Atencao","STOP")
	
Endif

//FIM DA ROTINA DE COMISSÕES

Return