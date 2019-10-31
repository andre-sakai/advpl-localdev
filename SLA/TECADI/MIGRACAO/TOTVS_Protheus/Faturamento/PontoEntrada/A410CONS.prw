#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na entrada da rotina de     !
!                  ! Pedido de Venda, para inclusão de botões na enchoice    !
!                  ! 1. Incluir botão para selecionar Lotes                  !
+------------------+---------------------------------------------------------+
!Retorno           ! Array                                                   !
+------------------+---------------------------------------------------------+
!Autor             ! Eliane (Dataroute)          ! Data de Criacao ! 09/2014 !
+------------------+--------------------------------------------------------*/

User Function A410CONS

	// variavel de retorno
	local _aButtons := {}

	// define se eh manutencao de pedido
	local _lMntPedido := ((Inclui).or.(Altera))

	// variavel publica para ser utilizada nos pontos de entrada da rotina MATA410
	// e na rotina para selecionar lotes
	// pos. 1 = item
	// pos. 2 = produto
	// pos. 3 = armazem
	// pos. 4 = lote
	// pos. 5 = localizacao
	// pos. 6 = pallet
	// pos. 7 = quantidade
	// pos. 8 = numseq (identb6)
	// pos. 9 = etiqueta volume
	public _aLotesPV := {}

	// somente 01-Armazem Geral
	If (cEmpAnt=="01")

		// inclui botao para selecao de lotes
		aadd(_aButtons,{"AVGBOX1",{|| U_TFATC009(_lMntPedido) },"Cadastro de Lotes por Item","Selecionar Lotes  <F11>"})

		// inclui tecla de atalho
		SetKey(VK_F11,{|| U_TFATC009(_lMntPedido) } )

		// atualiza variavel _aLotesPV
		sfPesqLote(M->C5_NUM, @_aLotesPV)

	EndIf

Return(_aButtons)

//** funcao para buscar lotes e preencher a variavel publica
Static Function sfPesqLote(mvNumPed, _aLotesPV)
	// area atual
	local _aAreaAtu := GetArea()
	// query
	local _cQry := ""

	// zera variavel
	_aLotesPV := {}

	// prepara query
	_cQry := " SELECT Z45_ITEM, Z45_CODPRO, Z45_LOCAL, Z45_LOTCTL, Z45_ENDATU, Z45_ETQPAL, Z45_QUANT, Z45_NUMSEQ, Z45_ETQVOL "
	// lotes do pedido
	_cQry += " FROM "+RetSqlTab("Z45")
	// filtro padrao
	_cQry += " WHERE "+RetSqlCond("Z45")
	// filtro por pedido
	_cQry += " AND Z45_PEDIDO = '"+mvNumPed+"' "
	// ordem dos dados
	_cQry += " ORDER BY Z45_ITEM "

	// atualiza variavel
	_aLotesPV := U_SqlToVet(_cQry)

	// restaura area atual
	RestArea(_aAreaAtu)

Return
