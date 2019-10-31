#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada na atualizacao dos itens da pre-nota   !
!                  ! de entrada                                              !
!                  ! 1. Preencher a TES para documentos do tipo DI.          !
+------------------+---------------------------------------------------------+
!Retorno           ! Sem Retorno                                             !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 07/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function SD1140I
	// area inicial
	local _aAreaAtu := GetArea()

	// somente para BENEFICIAMENTO e DI
	If (SF1->F1_TIPO=="B").and.(AllTrim(SF1->F1_SERIE)=="DI")
		dbSelectArea("SD1")
		RecLock("SD1")
			SD1->D1_TESACLA := "49A"
		MsUnLock()
	EndIf

	// restaura area inicial
	RestArea(_aAreaAtu)
Return