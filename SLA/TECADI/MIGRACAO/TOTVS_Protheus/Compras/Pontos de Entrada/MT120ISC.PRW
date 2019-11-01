#include "totvs.ch"
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada na tela de liberacao/aprovacao de      !
!                  ! documentos de entrada e pedidos de compras              !
!                  ! 1. Utilizado para atualizar o conteudo de campos custo- !
!                  !    mizados                                              !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2012                                                 !
+------------------+--------------------------------------------------------*/

User Function MT120ISC
	// posicao dos campos no browse
	local _nPosInfAd  := aScan(aHeader,{|x| AllTrim(Upper(x[2])) == "C7_ZINFADI" }) // informacao adicional do produto
	local _nPosNumSC  := aScan(aHeader,{|x| AllTrim(Upper(x[2])) == "C7_NUMSC"   }) // numero da solicitacao de compras
	local _nPosUsrSol := aScan(aHeader,{|x| AllTrim(Upper(x[2])) == "C7_ZUSRSC"  }) // usuario da solicitacao de compras
	local _nPosPrior  := aScan(aHeader,{|x| AllTrim(Upper(x[2])) == "C7_ZPRIORI" }) // Prioridade da solicitacao de compras
	local _nPosIdAlca := aScan(aHeader,{|x| AllTrim(Upper(x[2])) == "C7_ZIDALCA" }) // ID do setor (cadastro de alcada)
	local _nPosNivAlc := aScan(aHeader,{|x| AllTrim(Upper(x[2])) == "C7_ZNIVALC" }) // Nivel do setor (cadastro de alcada)
	local _nPosPreco  := aScan(aHeader,{|x| AllTrim(Upper(x[2])) == "C7_PRECO"   }) // valor unitario / preco
	local _nPosVlTot  := aScan(aHeader,{|x| AllTrim(Upper(x[2])) == "C7_TOTAL"   }) // valor total

	// somente pedido de compras
	If (nTipoPed == 1)
		// verifica se tem Solic. de Comptas
		If ( ! Empty(aCols[n][_nPosNumSC]) )
			// verifica se o campo Inf.Adic.Produto existe
			If (_nPosInfAd > 0)
				aCols[n][_nPosInfAd] := SC1->C1_ZINFADI
			EndIf
			// verifica se o campo Usr.Solic.Compras existe
			If (_nPosUsrSol > 0)
				aCols[n][_nPosUsrSol] := SC1->C1_USER
			EndIf
			// verifica se o campo Prioridade existe
			If (_nPosPrior > 0)
				aCols[n][_nPosPrior] := SC1->C1_ZPRIORI
			EndIf
			// verifica se o campo ID do Setor (Cad. Alcada) existe
			If (_nPosIdAlca > 0)
				aCols[n][_nPosIdAlca] := SC1->C1_ZIDALCA
			EndIf
			// verifica se o campo ID do Setor (Cad. Alcada) existe
			If (_nPosNivAlc > 0)
				aCols[n][_nPosNivAlc] := SC1->C1_ZNIVALC
			EndIf
			// atualiza campo preco / valor unitario
			If (_nPosPreco > 0)
				aCols[n][_nPosPreco] := SC1->C1_ZPRECO
			EndIf
			// atualiza campo valor total
			If (_nPosVlTot > 0)
				aCols[n][_nPosVlTot] := SC1->C1_QUANT * SC1->C1_ZPRECO
			EndIf

		EndIf
	EndIf

Return