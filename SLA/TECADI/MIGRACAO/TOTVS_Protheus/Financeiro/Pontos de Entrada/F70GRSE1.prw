#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada na Baixa de Titulos a Receber          !
!                  ! 1. Integra com sistema Datamex, confirmando que fatura  !
!                  !    foi recebida/baixada                                 !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 07/2016 !
+------------------+--------------------------------------------------------*/

User Function F70GRSE1

	// detalhes do processamento
	local _cDetProc := ""

	// somente para transportes, e quando tem ID da Fatura
	If (cEmpAnt == "03").and.( ! Empty(SE1->E1_ZIDDTMX) )

		// chama funcao para baixar fatura no Datamex
		StaticCall(TTMSXDAT, sfFlagInt, "BAIXA_FAT", AllTrim(SE1->E1_ZIDDTMX), .t., @_cDetProc)

	EndIf

Return
