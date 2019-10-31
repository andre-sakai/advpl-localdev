#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada utilizado para adicionar botões ao     !
!                  ! Menu Principal do aviso de recebimento.                 !
+------------------+---------------------------------------------------------+
!Retorno           !                                                         !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe José Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function MTA145MNU()

	// inclui botao para atualizar o numero da nota fiscal
	aAdd(aRotina,{ 'Atualizar NF'         , 'U_TWMSA025',0,4,0,nil })
	// inclui botao para impressao da conferencia de cargas
	aAdd(aRotina,{ 'Conferencia de Cargas', 'U_TWMSR025',0,4,0,nil })

Return(aRotina)