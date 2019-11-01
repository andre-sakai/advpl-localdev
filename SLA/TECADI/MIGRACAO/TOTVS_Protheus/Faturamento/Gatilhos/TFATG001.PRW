#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Gatilho utilizado para atualizar o preco unitario       !
!                  ! no item do pedido de venda de acordo com a nota fiscal  !
!                  ! de entrada                                              !
+------------------+---------------------------------------------------------+
!Campos            ! C6_QTDVEN / Cnt Dom: C6_VALOR / Regra: U_TFATG001()     !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2010                                                 !
+------------------+---------------------------------------------------------+
!   ATUALIZACOES                                                             !
+-------------------------------------------+-----------+-----------+--------+
!   Descricao detalhada da atualizacao      !Nome do    ! Analista  !Data da !
!                                           !Solicitante! Respons.  !Atualiz.!
+-------------------------------------------+-----------+-----------+--------+
!                                           !           !           !        !
!                                           !           !           !        !
+-------------------------------------------+-----------+-----------+-------*/

User Function TFATG001
	Local _aArea     := GetArea()
	Local _aAreaSD1  := SD1->(GetArea())
	Local _aAreaSF4  := SF4->(GetArea())

	Local _nPPrcVen  := aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRCVEN"})
	Local _nPValor   := aScan(aHeader,{|x| AllTrim(x[2])=="C6_VALOR"})
	Local _nPVlDesc  := aScan(aHeader,{|x| AllTrim(x[2])=="C6_VALDESC"})
	Local _nPProduto := aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})
	Local _nPNfOrig  := aScan(aHeader,{|x| AllTrim(x[2])=="C6_NFORI"})
	Local _nPSerOrig := aScan(aHeader,{|x| AllTrim(x[2])=="C6_SERIORI"})
	Local _nPItOrig  := aScan(aHeader,{|x| AllTrim(x[2])=="C6_ITEMORI"})
	Local _nPosTes   := aScan(aHeader,{|x| AllTrim(x[2])=="C6_TES"})
	Local _nTotal    := aCols[N,_nPValor]
	
	// verifica se a TES controla Porder de 3
	dbSelectArea("SF4")
	SF4->(dbSetORder(1)) //1-F4_FILIAL, F4_CODIGO
	If (SF4->(dbSeek(xFilial("SF4")+aCols[N,_nPosTes])).and.(SF4->F4_PODER3=="D"))
		// pesquisa o item da nota original
		dbSelectArea("SD1")
		SD1->(dbSetOrder(1))//1-D1_FILIAL, D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_COD, D1_ITEM
		If SD1->(dbSeek( xFilial("SD1")+aCols[N,_nPNfOrig]+aCols[N,_nPSerOrig]+M->C5_CLIENTE+M->C5_LOJACLI+aCols[N,_nPProduto]+aCols[N,_nPItOrig]))
			// atualiza total
			_nTotal := SD1->D1_TOTAL
			// atualiza preco unitario
			aCols[N,_nPPrcVen] := SD1->D1_VUNIT
			// zera o desconto
			aCols[N,_nPVlDesc] := 0
		EndIf
	EndIf
		
	// restaura area inicial
	RestArea(_aAreaSF4)
	RestArea(_aAreaSD1)
	RestArea(_aArea)

Return(_nTotal)