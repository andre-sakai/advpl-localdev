#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada utilizado para adicionar bot�es ao     !
!                  ! Menu Principal da Pr�-Nota de Entrada                   !
+------------------+---------------------------------------------------------+
!Retorno           !                                                         !
+------------------+---------------------------------------------------------+
!Autor             ! David Branco                                            !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 01/2016                                                 !
+------------------+--------------------------------------------------------*/

User Function MTA140MNU()

	// inclui botao para importa��o do xml da Nfe
	aAdd(aRotina,{ 'Importa Nfe (Xml)', 'U_TWMSA006',0,3,0,nil })

Return(aRotina)