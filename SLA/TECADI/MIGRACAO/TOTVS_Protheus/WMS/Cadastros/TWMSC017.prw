#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Cadastro de Fotos para App                              !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 08/2017 !
+------------------+--------------------------------------------------------*/

User Function TWMSC017
	Private cString := "Z23"
	dbSelectArea("Z23")
	dbSetOrder(1)
	AxCadastro(cString,"Cadastro de Fotos para App","U_WMSC017A()")
Return

//** funcao para validar se a fotos podera ser excluida
User Function WMSC017A
Return(.t.)