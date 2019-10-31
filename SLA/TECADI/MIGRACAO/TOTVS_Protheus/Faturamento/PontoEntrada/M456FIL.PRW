#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela de      !
!                  ! análise de crédito do pedido de venda                   !
!                  ! 1. Se for chamada pela rotina de faturamento de         !
!                  !    contratos (TFATA002), filtra os dados pelo numero    !
!                  !    do pedido de venda                                   !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 02/2012                                                 !
+------------------+--------------------------------------------------------*/

User Function M456FIL
	// variavel de retorno
	local _cRetFil := If(AllTrim(FunName()) == "TFATA002","C9_PEDIDO = '" + (_TRBGERAL)->IT_NUMPED + "'","")
Return(_cRetFil)