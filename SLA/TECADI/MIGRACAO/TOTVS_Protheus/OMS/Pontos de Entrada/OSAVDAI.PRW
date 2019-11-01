#Include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado no final da rotina de inclu-!
!                  ! são dos itens da carga (DAI) - (OMSXFUN -> OsAvalDAI)   !
!                  ! 1. Utilizado para atualizar o conteudo dos campos custo-!
!                  !    mizados (C5_ZCARGA, C5_ZSEQCAR, C5_ZSEQENT)          !
+------------------+---------------------------------------------------------+
!Observacao        ! Ver PE OSAVDAI / OMSXEST / M440SC9I                     !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 03/2012                                                 !
+------------------+--------------------------------------------------------*/

User Function OSAVDAI
// variavel de retorno
local _lRet := .t.
// evento da funcao OsAvalDAI (1-Inclui no DAI)
local _nEvento := PARAMIXB[1]
// area inicial do pedido de venda
local _aAreaAtu := GetArea()
local _aAreaSC5 := SC5->(GetArea())

// verifica a condicao de processamento
If (cEmpAnt == "01").and.(_nEvento == 1)
	// posiciona no pedido de venda
	dbSelectArea("SC5")
	SC5->(dbSetOrder(1)) // 1-C5_FILIAL, C5_NUM
	If SC5->(dbSeek( xFilial("SC5")+SC9->C9_PEDIDO ))
		// verifica se eh pedido do tipo produto
		If (SC5->C5_TIPOOPE=="P")
			// atualiza numero da carga, sequencia e sequencia de entrega no pedido de venda
			dbSelectArea("SC5")
			RecLock("SC5")
			SC5->C5_ZCARGA  := DAI->DAI_COD
			SC5->C5_ZSEQCAR := DAI->DAI_SEQCAR
			SC5->C5_ZSEQENT := DAI->DAI_SEQUEN
			SC5->(MsUnLock())
		EndIf
	EndIf
EndIf

// restaura area inicial do pedido de venda
RestArea(_aAreaSC5)
RestArea(_aAreaAtu)

Return(_lRet)
