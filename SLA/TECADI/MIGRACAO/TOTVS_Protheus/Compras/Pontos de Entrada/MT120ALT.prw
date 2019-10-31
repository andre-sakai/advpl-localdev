#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela de      !
!                  ! pedidos de compras                                      !
!                  ! 1. Validar permissao para alterar registros             !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/2016                                                 !
+------------------+--------------------------------------------------------*/

User Function MT120ALT()
	// opcao selecionada
	local _nOpcSelec := ParamIxb[1]
	// variavel de retorono
	local _lRetOk := .t.
	// query
	local _cQuery

	// somente na 01-Armazem Geral
	If ( cEmpAnt == "01" ).and.((_nOpcSelec == 4).or.(_nOpcSelec == 5))

		// query para verificar se ha itens eliminados por residuo
		_cQuery := " SELECT COUNT(*) QTD_ITENS "
		// ped. compras
		_cQuery += " FROM "+RetSqlTab("SC7")
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("SC7")
		// numero do pedido
		_cQuery += " AND C7_NUM = '"+SC7->C7_NUM+"' "
		// eliminado por residuo
		_cQuery += " AND C7_RESIDUO = 'S' "

		// executa validacao
		_lRetOk := (U_FtQuery(_cQuery) == 0)

		// mensagem
		If ( ! _lRetOk )
			MsgAlert("Operação não permitida, pois o Pedido "+SC7->C7_NUM+" possui itens eliminados por resíduo.")
		EndIf

	EndIf

Return(_lRetOk)