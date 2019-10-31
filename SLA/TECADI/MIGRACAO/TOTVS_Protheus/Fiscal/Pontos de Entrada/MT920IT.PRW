#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado no final da gravacao dos    !
!                  ! dados da tabela SD2, na rotina Notas Fiscais de Saida   !
!                  ! Manual (MATA920 - Livros Fiscais), antes de gerar o SF3 !
!                  ! 1. Gravacao de campos complementares nao suportado pela !
!                  !    rotina automatica                                    !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 06/2016 !
+------------------+--------------------------------------------------------*/

User Function MT920IT

	// controle de Cte cancelado
	local _lCteCanc := ((Type("_l920Cancel")=="L").and.(_l920Cancel))

	// grava dados complementares para CT-e da 03-Tecadi Transportes
	If (AllTrim(Upper(FunName())) $ "TTMSXSGT/TTMSXDAT/TMSXDATW/RPC").and.(cEmpAnt=="03").and.( ! _l920Cancel )
		// seleciona a tabela
		dbSelectArea("SD2")
		RecLock("SD2")
		SD2->D2_ORIGLAN := " "
		SD2->(MsUnLock())
	EndIf

Return