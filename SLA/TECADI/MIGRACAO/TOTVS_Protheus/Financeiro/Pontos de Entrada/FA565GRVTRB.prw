#Include "TOTVS.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela da      !
!                  ! rotina de Liquidacao a Pagar, utilizado para incluir ou !
!                  ! a ordem de apresentacao dos campos                      !
!                  ! 1. Inclusao do campo Nome do Fornecedor                 !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 01/2016 !
+------------------+---------------------------------------------------------+
!Observacoes       ! USAR EM CONJUNTO COM : FA565GRVTRB / FA565ADDCPO        !
+------------------+--------------------------------------------------------*/

User Function FA565GRVTRB()
	dbSelectArea("TRB")
	Replace NOMFOR With SE2->E2_NOMFOR
Return
