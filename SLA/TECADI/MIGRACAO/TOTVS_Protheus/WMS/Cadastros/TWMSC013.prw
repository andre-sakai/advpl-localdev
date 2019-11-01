#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Cadastro de Parametros WMS                              !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 03/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSC013

	// tabela de paramentros do WMS
	Private cString := "Z33"
	dbSelectArea("Z33")
	dbSetOrder(1)

	// tela padrao de cadastro
	AxCadastro(cString,"Cadastro de Parametros WMS","U_WMSC013A()")

Return

// ** funcao para validar se o parametro WMS podera ser excluido
User Function WMSC013A
Return(.t.)