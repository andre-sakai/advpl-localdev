
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado no final da gravacao da     !
!                  ! Pre Nota Fiscal de Entrada                              !
!                  ! 1. Utilizado para atualizar a hora de digitacao da nota !
!                  !    fiscal                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 07/2016 !
+------------------+--------------------------------------------------------*/

User Function SF1140I

	// atualiza campos customizados
	If (SF1->(FieldPos("F1_ZHRDIG")) > 0)
		// atualiza hora de digitacao
		RecLock("SF1")
		SF1->F1_ZHRDIG := Time()
		SF1->(MsUnLock())
	EndIf

Return