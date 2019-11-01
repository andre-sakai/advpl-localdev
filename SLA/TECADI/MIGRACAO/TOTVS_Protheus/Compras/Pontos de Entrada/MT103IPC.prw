#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado no bota Selecionar Pedido   !
!                  ! de Compras, na rotina "Documento de Entrada"            !
!                  ! 1. Utilizado para atualizar campos customizados         !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function MT103IPC
	// item do Itens do aCols (Nota Fiscal)
	Local _nItemNf   := ParamIxb[1]
	// posicao do campo no browse
	Local _nPosDescr := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_DESCRIC"})
	// descricao do produto
	local _cDescProd := ""

	// tenta pegar do pedido
	If (Empty(_cDescProd))
		_cDescProd := SC7->C7_DESCRI
	EndIf

	// tenta pegar do pedido
	If (Empty(_cDescProd))
		_cDescProd := Posicione("SB1",1, xFilial("SB1")+SC7->C7_PRODUTO ,"B1_DESC")
	EndIf

	// atualiza campo no browse
	aCols[_nItemNf,_nPosDescr] := _cDescProd

Return