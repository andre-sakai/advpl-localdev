#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada na Liquidacao de Contas a Receber      !
!                  ! 1. N�o gerar NCC para liquidacoes parciais              !
+------------------+---------------------------------------------------------+
!Retorno           ! L�gico (.T. - Gera NCC / .F. - N�o Gera NCC)            !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 07/2016 !
+------------------+--------------------------------------------------------*/

User Function F460GERNCC
Return(.f.)

