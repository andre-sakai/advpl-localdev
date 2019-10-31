#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Cadastro de Servicos x Fotos x Clientes para App        !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 09/2017 !
+------------------+--------------------------------------------------------*/

User Function TWMSC019
	Private cString := "Z25"
	dbSelectArea("Z25")
	dbSetOrder(1)
	AxCadastro(cString,"Cadastro de Servicos x Fotos x Clientes para App","U_WMSC019A()")
Return

//** funcao para validar se a fotos podera ser excluida
User Function WMSC019A
Return(.t.)