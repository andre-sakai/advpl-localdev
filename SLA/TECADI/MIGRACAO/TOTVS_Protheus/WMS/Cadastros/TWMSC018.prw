#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Cadastro de Servicos x Fotos para App                   !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 09/2017 !
+------------------+--------------------------------------------------------*/

User Function TWMSC018
	Private cString := "Z24"
	dbSelectArea("Z24")
	dbSetOrder(1)
	AxCadastro(cString,"Cadastro de Servicos x Fotos para App","U_WMSC018A()")
Return

//** funcao para validar se a fotos podera ser excluida
User Function WMSC018A
Return(.t.)