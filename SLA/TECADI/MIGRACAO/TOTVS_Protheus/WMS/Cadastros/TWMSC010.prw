#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Cadastro de Avarias de Mercadorias                      !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSC010
	// Cadastro de Avarias de Mercadorias
	Private cString := "Z35"
	dbSelectArea("Z35")
	dbSetOrder(1)
	// tela padrao de cadastro
	AxCadastro(cString,"Cadastro de Avarias de Mercadorias","U_WMSC010A()")
Return

// ** funcao para validar se a avaria podera ser excluida
User Function WMSC010A
Return(.t.)