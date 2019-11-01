#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada antes da geração da carga,             !
!                  ! permitindo o usuário interfirir na geração ou não       !
!                  ! da carga.                                               !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe                      ! Data de Criacao ! 03/2015 !
+------------------+--------------------------------------------------------*/

User Function OM200OK()

	// Area inicial
	local _aArea    := GetArea()
	local _aAreaSC5 := SC5->(GetArea())

	// parametros recebidos
	Local _aPedVenda := PARAMIXB[1]//Vetor de pedidos de vendas da carga (somente os selecionados)
	Local _aExpA2    := PARAMIXB[2]//Vetor de cargas
	Local _nExpA3    := PARAMIXB[3]//nPosCarga - carga disponivel aberta

	// posicao dos campos
	local _nPosNrPed  := 5
	local _nPosCodCli := 6
	local _nPosLojCli := 7

	// Variavel de retorno
	Local _lRet := .T.

	//Variavel para pegar o 1º Pedido Selecionado
	Local _cPedido := _aPedVenda[1][_nPosNrPed]

	//Código Cliente
	Local _cCodCli := _aPedVenda[1][_nPosCodCli]

	//Loja Cliente
	Local _cLojaCli := _aPedVenda[1][_nPosLojCli]

	// Agrupadora do primento pedido selecionado
	Local _cAgrupa := Posicione("SC5", 1, xFilial("SC5") + _cPedido, "C5_ZAGRUPA")

	// Quantidade de pedidos com a mesma agrupadora
	Local _nQtdAgrup := 0

	// query
	local _cQuery  := ""

	// variaveis temporaris
	Local _nPed := 0

	local _lTotAgrupa := .F.

	// Veridica se todos os pedidos marcados são do mesmo cliente.
	For _nPed := 1  To Len(_aPedVenda)
		// compara codigo do cliente e loja
		If ((_aPedVenda[_nPed][_nPosCodCli] + _aPedVenda[_nPed][_nPosLojCli]) <> (_cCodCli + _cLojaCli))
			// mensagem para usuario
			Aviso("Tecadi: OM200OK","Tem pedidos selecionados com Clientes diferentes. Favor verificar.",{"OK"})
			//Restaura area inicial
			RestArea(_aAreaSC5)
			RestArea(_aArea)
			// variavel de retorno
			_lRet := .F.
			// retorno
			Return(_lRet)
		EndIf
	Next _nPed

	// Veridica se todos os pedidos marcados são da mesma agrupadora.
	If (_cCodCli != "000603")
		For _nPed := 1  To Len(_aPedVenda)
			//Pedido de Venda
			dbSelectArea("SC5")
			SC5->(dbSetOrder(1))//C5_FILIAL+C5_NUM
			If SC5->(dbSeek( xFilial("SC5") + _aPedVenda[_nPed][_nPosNrPed]))
				// compara agrupadora
				If (SC5->C5_ZAGRUPA <> _cAgrupa)
					// mensagem para usuario
					Aviso("Tecadi: OM200OK","Tem pedidos selecionados com agrupadoras diferentes. Favor verificar.",{"OK"})
					//Restaura area inicial
					RestArea(_aAreaSC5)
					RestArea(_aArea)
					// variavel de retorno
					_lRet := .F.
					// retorno
					Return(_lRet)
				EndIf
			EndIf
		Next _nPed
	EndIf
	
	// verifica se é pra validar pelo total da agrupadora
	_lTotAgrupa := U_FtWmsParam("WMS_CARGA_TOTAL_AGRUPADOR", "L", .F., .F., "", _cCodCli, _cLojaCli, "", "")

	// quando o cliente agrupa varios pedidos, verifica se ficou algum pedido da mesma agrupadora fora da selecao
	If ( _lTotAgrupa ) .And. ( ! Empty(_cAgrupa) )

		// fazer um Select para saber quantos pedidos tem com esta Agrupadora.
		_cQuery := " SELECT COUNT(C5_NUM) QTD_PEDIDO "
		// pedido de venda
		_cQuery += " FROM " + RetSqlTab("SC5")
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("SC5")
		// codigo e loja do cliente
		_cQuery += " AND C5_CLIENTE = '" + _cCodCli + "' AND C5_LOJACLI = '" + _cLojaCli + "' "
		// chave agrupadora
		_cQuery += " AND C5_ZAGRUPA = '" + _cAgrupa + "'

		// atualiza o total de pedidos na mesma agrupadora
		_nQtdAgrup := U_FtQuery(_cQuery)

		// valida a quantidade de pedidos selecionados com a quantidade total de pedidos da agrupadora
		If (Len(_aPedVenda) <> _nQtdAgrup)
			// mensagem para usuario
			Aviso("Tecadi: OM200OK","Total de pedidos selecionados não bate com a quantidade total da agrupadora: " + _cAgrupa + ".",{"OK"})
			//Restaura area inicial
			RestArea(_aAreaSC5)
			RestArea(_aArea)
			// variavel de retorno
			_lRet := .F.
			// retorno
			Return(_lRet)
		EndIf

	EndIf

	//Restaura area inicial
	RestArea(_aAreaSC5)
	RestArea(_aArea)

Return(_lRet)