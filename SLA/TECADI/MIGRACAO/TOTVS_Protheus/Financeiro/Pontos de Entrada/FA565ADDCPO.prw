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
!Observacoes       ! USAR EM CONJUNTO COM : FA565ADDCPO / FA565GRVTRB        !
+------------------+--------------------------------------------------------*/

User Function FA565ADDCPO()
	// campos do TRB
	aAdd(aCampos,{"NOMFOR","C", TamSx3("E2_NOMFOR")[1],0})
	// campos do browse
	aAdd(aCpoBro,{"NOMFOR",,"Nome do Fornecedor",""})
Return