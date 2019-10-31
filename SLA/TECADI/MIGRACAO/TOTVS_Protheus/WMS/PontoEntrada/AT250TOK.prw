#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na confirmacao da tela de   !
!                  ! inclusao/alteracao/visualizacao do contratos, usado     !
!                  ! para validar consitencia de dados                       !
!                  ! 1. Exclusao de servicos/atividades de itens excluidos   !
!                  ! 2. Validar se a unidade de medida de cobranca do        !
!                  !    servico/atividade eh igual em todos os itens         !
+------------------+---------------------------------------------------------+
!Autor             ! TSC149-Percio Oliveira      ! Data de Criacao ! 01/2012 !
+------------------+--------------------------------------------------------*/

User Function AT250TOK
	// variavel de retorno
	local _lRet := .t.
	// query
	local _cQuery
	// variaveis temporarias
	local _aTmpSrvDup := {}
	local _cTmpSrvDup := ""
	local _nLinVld
	local _cQuery

	// novos metodos para controle de modelo de cadastro com MVC
	local _oModelPad  := FwModelActive()
	local _oModelGrid := _oModelPad:GetModel("MdGridIAAN")

	// variaveis para uso na funcao
	local _cItContrt

	// valida unidade de medida
	If (_lRet) .and. (Inclui .or. Altera)
		// prepara query
		_cQuery := " SELECT Z9_CODATIV, "
		_cQuery += "        ZT_DESCRIC, "
		_cQuery += "        Count(DISTINCT Z9_UNIDCOB) QTD_UM "
		_cQuery += " FROM   "+RetSqlTab("SZ9")
		_cQuery += "        INNER JOIN "+RetSqlTab("SZT")
		_cQuery += "                ON "+RetSqlCond("SZT")
		_cQuery += "                   AND ZT_CODIGO = Z9_CODATIV "
		_cQuery += " WHERE  "+RetSqlCond("SZ9")
		_cQuery += "        AND Z9_CONTRAT = '" + M->AAM_CONTRT + "' "
		_cQuery += " GROUP  BY Z9_CODATIV, "
		_cQuery += "           ZT_DESCRIC "
		_cQuery += " HAVING Count(DISTINCT Z9_UNIDCOB) > 1 "
		_cQuery += " ORDER  BY Z9_CODATIV "

		// atualiza vetor
		_aTmpSrvDup := U_SqlToVet(_cQuery)

		// caso tenha pedidos
		If (Len(_aTmpSrvDup) > 0)

			// variavel de retorno
			_lRet := .f.

			// solicita detalhamento
			If MsgYesNo("Há unidade(s) de cobrança dos serviços em duplicidade por item do contrato."+CRLF+"Deseja visualizar detalhes?","TECA250 -> AT250TOK - Validação")

				// atualiza relação de setores relacionados
				aEval(_aTmpSrvDup,{|_xDetSrv| _cTmpSrvDup += (_xDetSrv[1]+" - "+_xDetSrv[2] + CRLF) })

				// apresenta mensagen
				HS_MsgInf(_cTmpSrvDup ,;
				"Unidade de Medida em Duplicidade",;
				"Unidade de Medida em Duplicidade" )

			EndIf
		EndIf

	EndIf

	// exclui registros de servicos nao utilizados
	If (_lRet) .and. (Inclui .or. Altera)

		// varre todas as linhas do grid
		For _nLinVld := 1 to Len(_oModelGrid:aDataModel)

			// valida linha deletada
			If (_oModelGrid:IsDeleted(_nLinVld))

				// extrai o numero do item
				_cItContrt := _oModelGrid:GetValue('AAN_ITEM', _nLinVld)

				_cQuery := "DELETE FROM " + RetSqlName("SZ9") + " WHERE Z9_FILIAL = '" + XFILIAL("SZ9") + "' AND Z9_CONTRAT = '" + M->AAM_CONTRT + "' AND Z9_ITEM = '" + _cItContrt + "'"
				TCSQLEXEC(_cQuery)

				_cQuery := "DELETE FROM " + RetSqlName("SZU") + " WHERE ZU_FILIAL = '" + XFILIAL("SZU") + "' AND ZU_CONTRT = '" + M->AAM_CONTRT + "' AND ZU_ITCONTR = '" + _cItContrt + "'"
				TCSQLEXEC(_cQuery)
			EndIf
		Next _nLinVld
	EndIf

Return(_lRet)