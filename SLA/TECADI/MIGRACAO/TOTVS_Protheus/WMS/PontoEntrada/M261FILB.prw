#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada na rotina de transferencia modelo 2    !
!                  ! - filtrar dados por cliente                             !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 03/2017 !
+------------------+--------------------------------------------------------*/

User Function M261FILB
	// filtro de retorno
	local _cRetFiltro := ""
	// wms manual
	local _lWmsManual := .f.

	// filtros conforme operacao
	If (cEmpAnt == "01").and.(nModulo == 4).and.(cModulo == "EST")
		// verifica o menu utilizado
		_lWmsManual := ("SIGAEST_WMS" $ Upper(FWGetMnuFile()))

		// se for WMS manual, filtra codigo do cliente
		If (_lWmsManual)
			// define filtro
			IF ("SIGAEST_WMS_KLAB" $ Upper(FWGetMnuFile()))
				_cRetFiltro := "D3_GRUPO = 'KLAB' AND D3_ZNUMOS = ''"
			Else
				_cRetFiltro := "D3_GRUPO = 'DELO' AND D3_ZNUMOS = ''"
			EndIf
		EndIf

	EndIf

Return(_cRetFiltro)