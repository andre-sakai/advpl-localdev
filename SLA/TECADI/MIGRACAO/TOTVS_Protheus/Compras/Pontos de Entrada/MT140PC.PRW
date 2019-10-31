#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada na validacao da linha, na rotina de    !
!                  ! Pre-Nota de Entrada                                     !
!                  ! 1. Ignora validacao de pedido de compra (MV_PCNFE)      !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 08/2014                                                 !
+------------------+--------------------------------------------------------*/

User Function MT140PC
// sempre ignora a validacao, pois ainda nao tem TES definida
Return(.f.)