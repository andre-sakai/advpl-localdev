#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela de      !
!                  ! montagem de bordero de pagamentos para validar se o     !
!                  ! titulo pode ser selecionado                             !
!                  ! 1. Preencher campos especificos                         !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 11/2016 !
+------------------+--------------------------------------------------------*/

User Function F240TIT()
	// posicao inicial
	local _aAreaSA2 := SA2->(GetArea())

	// atualiza portador, conforme cadastro
	If ( Empty( (cAliasSE2)->E2_CODBAR ) )

		// posiciona no cadastro do fornecedor
		dbSelectArea("SA2")
		SA2->(dbSetOrder(1)) // 1-A2_FILIAL, A2_COD, A2_LOJA
		SA2->(dbSeek( xFilial("SA2")+(cAliasSE2)->E2_FORNECE+(cAliasSE2)->E2_LOJA ))

		// atualiza campo
		RecLock(cAliasSE2)
		(cAliasSE2)->E2_PORTADO := SA2->A2_BANCO
		(cAliasSE2)->(MsUnLock())

	EndIf

	// restaura posicao inicial do SX3
	RestArea(_aAreaSA2)

Return(.t.)