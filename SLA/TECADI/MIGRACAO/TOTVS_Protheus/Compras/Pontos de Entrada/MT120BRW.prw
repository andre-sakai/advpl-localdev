#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela de      !
!                  ! pedidos de compras                                      !
!                  ! 1. Botao para consultar Log da Analise de Alcadas       !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 03/2016                                                 !
+------------------+--------------------------------------------------------*/

User Function MT120BRW

	// consulta de LOG
	aAdd(aRotina,{"Consulta Log" ,"U_FtConsLog(xFilial('SC7'), 'SC7', xFilial('SC7')+SC7->(C7_NUM+C7_ITEM) )",0,4,0,NIL})

Return