#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na rotina Contas a Pagar    !
!                  ! 1. Incluir botão para informar os processo envolvidos   !
!                  !    neste custo                                          !
+------------------+---------------------------------------------------------+
!Retorno           ! Array com opcoes do menu                                !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/2012                                                 !
+------------------+--------------------------------------------------------*/

User Function F050ROT
local _aNewRot := ParamIxb
// inclui opcao para relacionar processo ao titulo
aAdd(_aNewRot,{"Define Processo","U_TFINA002(SE2->E2_VALOR,.f.)",0,4,,.F.})
Return(_aNewRot)