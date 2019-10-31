#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Cadastro para regra de armazenagem.                     !
+------------------+---------------------------------------------------------+
!Retorno           !                                                         !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe José Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 26/03/2015                                              !
+------------------+--------------------------------------------------------*/

User Function TWMSC014()

	// tabela de regras de armazenagem do WMS
	Private cString := "Z38"
	dbSelectArea("Z38")
	dbSetOrder(1)

	// tela padrao de cadastro
	AxCadastro(cString,"Cadastro de Regras de Armazenagem","U_WMSC014A()")

Return

// ** funcao para validar se a regras de armazenagem poderá ser excluida
User Function WMSC014A
Return(.t.)