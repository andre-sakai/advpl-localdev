#Include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado no final da rotina de estor-!
!                  ! no dos itens da carga (DAI) - (OMSXFUN -> OsAvalDAI)   !
!                  ! 1. Utilizado para atualizar o conteudo dos campos custo-!
!                  !    mizados (C5_ZCARGA, C5_ZSEQCAR, C5_ZSEQENT)          !
+------------------+---------------------------------------------------------+
!Observacao        ! Ver PE OSAVDAI / OMSXEST / M440SC9I                     !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 03/2012                                                 !
+------------------+--------------------------------------------------------*/

User Function OMSXEST
// variaveis recebidas como parametro da funcao OsAvalDAI
local _cAlias  := PARAMIXB[1]
// area inicial do pedido de venda
local _aAreaAtu := GetArea()
local _aAreaSC5 := SC5->(GetArea())
// variaveis temporarias
local _nContFunc := 1
// deve estornar a carga
local _lEstCarga := .f.

// verifica o nome da rotina em processamento
While ( ! Empty(ProcName(_nContFunc)))
	// verifica a rotina quer permite o estorno da carga
	If (Upper(Alltrim(ProcName(_nContFunc))) $ "OMSA200/MATA460A")
		_lEstCarga := .t.
		Exit
	EndIf
	_nContFunc++
Enddo

// verifica a condicao de processamento
If (cEmpAnt == "01").and.(_cAlias == "DAI").and.(_lEstCarga)
	// posiciona no pedido de venda
	dbSelectArea("SC5")
	SC5->(dbSetOrder(1)) // 1-C5_FILIAL, C5_NUM
	If SC5->(dbSeek( xFilial("SC5")+SC9->C9_PEDIDO ))
		// verifica se eh pedido do tipo produto
		If (SC5->C5_TIPOOPE=="P")
			// atualiza numero da carga, sequencia e sequencia de entrega no pedido de venda
			dbSelectArea("SC5")
			RecLock("SC5")
			SC5->C5_ZCARGA  := Space(Len(SC5->C5_ZCARGA))
			SC5->C5_ZSEQCAR := Space(Len(SC5->C5_ZSEQCAR))
			SC5->C5_ZSEQENT := Space(Len(SC5->C5_ZSEQENT))
			SC5->(MsUnLock())
		EndIf
	EndIf
EndIf

// restaura area inicial do pedido de venda
RestArea(_aAreaSC5)
RestArea(_aAreaAtu)

Return
