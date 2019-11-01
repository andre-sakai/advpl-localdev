¿#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Cadastro de Grupos de Estoque                           !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 03/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSC012

	// tabela de grupos de estoque
	Private cString := "Z36"
	dbSelectArea("Z36")
	dbSetOrder(1)

	// tela padrao de cadastro
	AxCadastro(cString,"Cadastro de Grupos de Estoque","U_WMSC012A()")

Return

// ** funcao para validar se o grupo de estoque podera ser excluido
User Function WMSC012A
Return(.t.)