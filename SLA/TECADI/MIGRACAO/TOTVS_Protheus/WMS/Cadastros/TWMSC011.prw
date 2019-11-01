#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Cadastro de Tipos de Estoque                            !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 03/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSC011
	// tabela de tipos de estoque
	Private cString := "Z34"
	dbSelectArea("Z34")
	dbSetOrder(1)
	// tela padrao de cadastro
	AxCadastro(cString,"Cadastro de Tipos de Estoque","U_WMSC011A()")
Return

// ** funcao para validar se o tipo de estoque podera ser excluido
User Function WMSC011A
Return(.t.)