#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada Pedido de compras AP�S grava�ao
+------------------+---------------------------------------------------------+
!Autor             ! Odair                                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 09/2013                                                 !
+------------------+--------------------------------------------------------*/

User Function MT120GOK

	// verifica limite para a al�ada da �rea, liberando o pedido de compra ou enviando-o para a al�ada correspondente para aprova��o.
	if ( cEmpAnt == "01" )
		U_FTCOM02C(SC7->C7_NUM)
	EndIf

Return