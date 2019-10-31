#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada na Liquidacao de Contas a Receber      !
!                  ! 1. Não gerar NCC para liquidacoes parciais              !
+------------------+---------------------------------------------------------+
!Retorno           ! Lógico (.T. - Gera NCC / .F. - Não Gera NCC)            !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 07/2016 !
+------------------+--------------------------------------------------------*/

User Function F460GERNCC
Return(.f.)

