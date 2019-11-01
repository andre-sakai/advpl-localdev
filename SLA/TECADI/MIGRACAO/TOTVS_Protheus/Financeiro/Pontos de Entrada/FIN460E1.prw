#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada no Cancelamento de Liquidacao (CR)     !
!                  ! 1. Integra com sistema Datamex, cancelando que fatura   !
!                  !    foi integrada                                        !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 09/2016 !
+------------------+--------------------------------------------------------*/

User Function FIN460E1

	// detalhes do processamento
	local _cDetProc := ""

	// somente para transportes, e quando tem ID da Fatura
	If (cEmpAnt == "03").and.( ! Empty(SE1->E1_ZIDDTMX) )

		// chama funcao para baixar fatura no Datamex
		StaticCall(TTMSXDAT, sfFlagInt, "FAT", AllTrim(SE1->E1_ZIDDTMX), .f., @_cDetProc)

	EndIf

Return