#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada na rotina documentos de entrada        !
!                  ! - filtrar dados por cliente                             !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 03/2017 !
+------------------+--------------------------------------------------------*/

User Function M103FILB
	// filtro de retorno
	local _cRetFiltro := ""
	// wms manual
	local _lWmsManual := .f.

	// filtros conforme operacao
	If (cEmpAnt == "01") .AND. (nModulo == 4).and.(cModulo == "EST")
		// verifica o menu utilizado
		_lWmsManual := ("SIGAEST_WMS" $ Upper(FWGetMnuFile()))

		// se for WMS manual, filtra codigo do cliente
		If (_lWmsManual)
			// define filtro
			_cRetFiltro := "F1_FORNECE = '000436' AND F1_TIPO = 'B'"
		EndIf

	EndIf

	// 17/09/2019 - Bruno Seára: Filtro para que seja apresentada apenas as NFs do tipo Beneficiamento quando o módulo for WMS
	// para enxergar as NFs de fornecedores, utilizar o módulo Compras
	If (cEmpAnt == "01") .AND. (nModulo == 42)
		_cRetFiltro := "F1_TIPO = 'B' AND F1_FILIAL = '" + xFilial("SF1") + "'"
	EndIf

Return(_cRetFiltro)