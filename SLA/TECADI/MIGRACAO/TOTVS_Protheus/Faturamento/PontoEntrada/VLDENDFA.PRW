/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada na validacao do campo C6_LOCALIZ,      !
!                  ! funcao TOTVS VldLocaliz                                 !
!                  ! - Utilizado para validar o endereco igual ao numero do  !
!                  !   pedido de venda na geracao de OS para WMS             !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 11/2012 !
+------------------+--------------------------------------------------------*/

User Function VLDENDFA
	// parametros recebidos
	local _lRet  := ParamIxb[1]
	local _cProg := ParamIxb[2]

	// valida se o WMS esta ativo por cliente
	local _lWmsAtivo := .f.

	// valida rotina principal
	If (AllTrim(FunName()) <> "MATA430")

		// somente na ARMAZENS GERAIS, e se o WMS estiver ativo
		If (cEmpAnt=="01").and.(_cProg=="A440").and.(M->C5_TIPOOPE=="P")

			// verifica se o WMS esta ativo por cliente
			_lWmsAtivo := StaticCall(TWMSXFUN, WmsMltCntr, "MATA410", "WMS_ATIVO_POR_CLIENTE", M->C5_CLIENTE, M->C5_LOJACLI)

			If (_lWmsAtivo)
				_lRet := .t.
			EndIf

		EndIf

	EndIf

Return(_lRet)
