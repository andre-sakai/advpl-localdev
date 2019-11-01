#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Ponto de Entrada Cadastro de Produtos para manipulacao  !
!                  ! de opcoes no menu                                       !
+------------------+---------------------------------------------------------+
!Autor             ! David Branco                ! Data de Criacao ! 03/2015 !
+------------------+--------------------------------------------------------*/

User Function MTA010MNU()

	// somente 01-Armazem Geral
	If (cEmpAnt == "01")

		// adiciona um botão no cadastro de produtos
		aAdd(aRotina, { "CADASTRA SKU" ,"U_WMSC007A(SB1->B1_COD)", 0 , 4, 0, .F.} )
		// rotina para complemento de cadastro de produtos WMS
		aAdd(aRotina, { "COMPLEMENTO WMS" ,"U_TWMSC008(SB1->B1_COD)", 0 , 5, 0, .F.} )
		// importacao de cadastro de produtos
//		aAdd(aRotina, { "Importação de Cadastro" ,"U_FtImpPrd()", 0 , 3, 0, .F.} )

	EndIf
Return