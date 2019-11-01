
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada na alteracao do pedido de venda,       !
!                  ! utilizado para validar se eh permitido a alteracao de   !
!                  ! pedidos com bloqueio no WMS                             !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 09/2012 !
+------------------+--------------------------------------------------------*/

User Function M410ALOK
	// variavel de retorno
	local _lRet := .t.
	local _cQuery

	// valida se o WMS esta ativo por cliente
	local _lWmsAtivo := .f.

	// somente na 01-ARMAZENS
	If (cEmpAnt=="01").and.(SC5->C5_TIPOOPE=="P").and.(Type("_lWmsIsACD") == "U")

		// valida se o WMS esta ativo por cliente
		_lWmsAtivo := StaticCall(TWMSXFUN, WmsMltCntr, "MATA410", "WMS_ATIVO_POR_CLIENTE", SC5->C5_CLIENTE, SC5->C5_LOJACLI)

		// se o WMS ativo
		If (_lWmsAtivo)

			_cQuery := " SELECT COUNT(*) QTD FROM "+RetSqlTab("SC9")
			_cQuery += " WHERE "+RetSqlCond("SC9")
			_cQuery += " AND C9_PEDIDO = '"+SC5->C5_NUM+"' "
			_cQuery += " AND C9_BLWMS != ' ' "

			// executa validacao
			_lRet := (U_FtQuery(_cQuery) == 0)
		EndIf

	EndIf

	If (!_lRet)
		Aviso("Pedido de Venda -> M410ALOK","Pedido de venda não pode ser alterado pois está em processo no WMS.",{"Fechar"})
	EndIf

Return(_lRet)
