#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada Pedido de compras APÓS gravaçao
+------------------+---------------------------------------------------------+
!Autor             ! Odair                                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 09/2013                                                 !
+------------------+--------------------------------------------------------*/

User Function MT120GOK

	// verifica limite para a alçada da Área, liberando o pedido de compra ou enviando-o para a alçada correspondente para aprovação.
	if ( cEmpAnt == "01" )
		U_FTCOM02C(SC7->C7_NUM)
	EndIf

Return