#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada MTSLDLOT permite consultar os dados do !
!                  ! produto com saldo por lote ou saldo por endereço        !
!                  ! 1. O ponto de entrada pode ser executado em dois        !
!                  !    momentos: Ao avaliar se o produto possui:            !
!                  !      a) saldo por lote (SB8),                           !
!                  !      b) ou saldo por endereçamento (SBF)                !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 06/2018 !
+------------------+--------------------------------------------------------*/

User Function MTSLDLOT()
	// variavel de retorno
	local _lRet := .T.
	// query
	local _cQuery := ""
	// local
	local mvLoteCtl := ParamIxb[3]
	// endereco
	local mvLocaliz := ParamIxb[5]

	// variaveis temporarias
	local _aTmpLotes := {}

	// se for INCLUSAO ou ALTERACAO e o tipo do pedido for PRODUTO
	If (_lRet) .And. (cEmpAnt=="01") .And. ( IsInCallStack("MALIBDOFAT") ) .And. (SC5->C5_TIPO == "N") .And. (SC5->C5_TIPOOPE == "P") .And. ( Empty(SC6->C6_LOTECTL) ) .And. ( Empty(mvLocaliz) ) .And. ( ! Empty(SC6->C6_LOCALIZ) )

		// verifica os lotes de cada item do pedido de venda
		_cQuery += " SELECT DISTINCT Z45_LOTCTL "
		_cQuery += " FROM   " + RetSqlTab("Z45")
		_cQuery += " WHERE  " + RetSqlCond("Z45")
		_cQuery += "        AND Z45_PEDIDO = '" + SC5->C5_NUM + "' "
		_cQuery += "        AND Z45_ITEM = '" + SC6->C6_ITEM + "' "

		// atualiza variavel de controle
		_aTmpLotes := U_SqlToVet(_cQuery)

		// atualiza variavel de retorno conforme valida de lote
		_lRet := (aScan(_aTmpLotes, mvLoteCtl) != 0)

	EndIf

Return( _lRet )