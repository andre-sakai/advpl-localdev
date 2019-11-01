#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! PE no final da gravacao do Pedido de Venda              !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 08/2017 !
+------------------+--------------------------------------------------------*/

User Function MTA410T()

	// variavel de controle de processamento
	local _lRet := .T.

	// valida se o WMS esta ativo por cliente
	local _lWmsAtivo := .F.
	// verifica se o controle de lote esta
	local _lLotAtivo := .F.

	// variaveis para controle da gravacao dos dados
	local _nX        := 0
	local _nPos      := 0
	local _aRecnoZ45 := {}
	local _nRecnoZ45 := 0

	// posicao dos campos no browse
	local _nP_Ite    := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ITEM"   })
	local _nP_Prd    := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_PRODUTO"})

	// query
	local _cQry := ""

	// posicoes do _aLotesPV (variavel publica criada pelo P.E. A410CONS)
	local _nL_Ite    := 1
	local _nL_Cod    := 2
	local _nL_Amz    := 3
	local _nL_Lot    := 4
	local _nL_End    := 5
	local _nL_Pal    := 6
	local _nL_Qtd    := 7
	local _nL_Seq    := 8
	local _nL_EtqVol := 9

	// controle se deve gerar onda de separacao e ordem de servico
	local _lAutoPlanej := .F.

	// opcao de rotina automatica para geracao de mapa
	local _nOpcAuto := IIf(INCLUI, 3, 4)

	// se for INCLUSAO ou ALTERACAO e o tipo do pedido for PRODUTO
	If (_lRet) .And. (M->C5_TIPO == "N") .And. ((Inclui) .Or. (Altera)) .And. (M->C5_TIPOOPE == "P") .And. (cEmpAnt == "01")

		// verifica se o WMS esta ativo
		_lWmsAtivo := StaticCall(TWMSXFUN, WmsMltCntr, "MATA410", "WMS_ATIVO_POR_CLIENTE", M->C5_CLIENTE, M->C5_LOJACLI)

		// verifica se o controle de lote esta
		_lLotAtivo := StaticCall(TWMSXFUN, WmsMltCntr, "MATA410", "WMS_CONTROLE_POR_LOTE", M->C5_CLIENTE, M->C5_LOJACLI)

		// controle se deve gerar onda de separacao e ordem de servico
		_lAutoPlanej := StaticCall(TWMSXFUN, WmsMltCntr, "MATA410", "WMS_EXPEDICAO_GERA_ONDA_SEPARACAO_AUTOMATICA", M->C5_CLIENTE, M->C5_LOJACLI)

		// verifica se deve gravar os dados do lote selecionado
		If (_lWmsAtivo) .and. (_lLotAtivo)

			// exclui lotes pois podem ter sido excluidos os produtos
			_cQry := " SELECT Z45.R_E_C_N_O_ Z45RECNO "
			// itens relacionados no pedido de venda
			_cQry += " FROM "+RetSqlTab("Z45")
			// filtro padrao
			_cQry += " WHERE "+RetSqlCond("Z45")
			// numero do pedido
			_cQry += " AND Z45_PEDIDO = '" + M->C5_NUM + "' "

			// atualiza vetor
			_aRecnoZ45 := U_SqlToVet(_cQry)

			// varre todos os RECNOs para exclusao
			For _nRecnoZ45 := 1 to Len(_aRecnoZ45)

				// posiciona no registro
				dbSelectArea("Z45")
				Z45->(dbGoto( _aRecnoZ45[_nRecnoZ45] ))

				RecLock("Z45", .F.)
				Z45->(dbDelete())
				Z45->(MsUnlock())

			Next _nRecnoZ45

			// grava lotes por item
			If ( Type("_aLotesPV") == "A" ) .and. (Len(_aLotesPV) > 0)

				// varre todos os itens selecionados
				For _nX := 1 to Len(_aLotesPV)

					// verifica o item
					_nPos := aScan(aCols,{|x| x[_nP_Ite] == _aLotesPV[_nX,_nL_Ite] })

					// valia se o item nao esta deletado
					If ( ! aCols[_nPos][Len(aHeader)+1] )

						// verifica do cadastro de produto
						dbSelectArea("SB1")
						SB1->(dbSetOrder(1))
						SB1->(dbSeek( xFilial("SB1")+aCols[_nPos,_nP_Prd] ))

						// verifica se controla LOTE
						If (Rastro(aCols[_nPos,_nP_Prd],"L"))
							recLock("Z45", .T.)
							Z45->Z45_FILIAL	:= xFilial("Z45")
							Z45->Z45_PEDIDO	:= M->C5_NUM
							Z45->Z45_ITEM	:= _aLotesPV[_nX,_nL_Ite   ]
							Z45->Z45_CODPRO	:= _aLotesPV[_nX,_nL_Cod   ]
							Z45->Z45_LOTCTL	:= _aLotesPV[_nX,_nL_Lot   ]
							Z45->Z45_ETQPAL	:= _aLotesPV[_nX,_nL_Pal   ]
							Z45->Z45_ENDATU	:= _aLotesPV[_nX,_nL_End   ]
							Z45->Z45_LOCAL	:= _aLotesPV[_nX,_nL_Amz   ]
							Z45->Z45_QUANT	:= _aLotesPV[_nX,_nL_Qtd   ]
							Z45->Z45_NUMSEQ	:= _aLotesPV[_nX,_nL_Seq   ]
							Z45->Z45_ETQVOL	:= _aLotesPV[_nX,_nL_EtqVol]
							msUnlock()
						EndIf

					EndIf

				Next _nX

			EndIf

		EndIf

		// verifica se deve gerar onda de separacao e ordem de servico automaticamente
		// se WMS ativo, e geração automática ativa e não estiver sendo chamado da rotina de conferência de recebimento do coletor (o que indica um TFAA)
		If (_lWmsAtivo) .And. (_lAutoPlanej) .AND. !( IsInCallStack("U_WMSA010A") )

			// se for alteracao de pedido, mas nao tem mapa, chama funcao como incusao
			If (_nOpcAuto == 4) .And. ( Empty(SC5->C5_ZONDSEP) )
				// altera para 3-Inclusao
				_nOpcAuto := 3
			EndIf

			// rotina padrao de geracao de onda de separacao
			If U_WMSA042C("02", _nOpcAuto) // 02 - Liberado para Planejamento

				// posiciona na onda selecionada
				dbSelectArea("Z57")
				Z57->(dbSetOrder(1)) // 1 - Z57_FILIAL, Z57_CODIGO
				Z57->(dbSeek( xFilial("Z57") + SC5->C5_ZONDSEP ))

				// se o status da onda for 02-Liberado para Planejamento
				If (Z57->Z57_STATUS == "02")

					// chama funcao para geracao de mapa de expedicao
					U_WMSA042D(_nOpcAuto)

				EndIf

			EndIf

		EndIf

	EndIf

Return