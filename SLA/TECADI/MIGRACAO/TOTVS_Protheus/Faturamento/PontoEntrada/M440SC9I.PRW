#Include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado no final da rotina de libe- !
!                  ! ração do item do Pedido de Venda (FATXFUN -> MaGravaSC9)!
!                  ! 1. Utilizado para recriar a carga, baseado nos campos   !
!                  !    customizados (C5_ZCARGA, C5_ZSEQCAR, C5_ZSEQENT)     !
+------------------+---------------------------------------------------------+
!Observacao        ! Ver PE OSAVDAI / OMSXEST / M440SC9I                     !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 03/2012                                                 !
+------------------+--------------------------------------------------------*/

User Function M440SC9I
	// vetor utilizado na geracao da carga (MaAvalSC9)
	local _aRotas := {}

	// gravacao do numero do contrato
	dbSelectArea("SC9")
	Reclock("SC9")
	SC9->C9_ZCONTRT := SC5->C5_ZCONTRT
	SC9->(MsUnlock())

	// verifica a condicao de processamento
	If (cEmpAnt == "01").and.(SC5->C5_TIPOOPE=="P").and.( ! Empty(SC5->C5_ZCARGA))

		// atualiza os dados da carga no item liberado
		dbSelectArea("SC9")
		Reclock("SC9")
		SC9->C9_CARGA  := SC5->C5_ZCARGA
		SC9->C9_SEQCAR := SC5->C5_ZSEQCAR
		SC9->C9_SEQENT := SC5->C5_ZSEQENT
		SC9->C9_ENDPAD := Space(Len(SC9->C9_ENDPAD))
		SC9->(MsUnlock())

		//-- Array com os dados da roteirizacao
		//   [01] Codigo da Rota
		//   [02] Codigo da Zona
		//   [03] Codigo do Setor
		//   [04] Motorista
		//   [05] Caminhao
		//   [06] Ajudante 1
		//   [07] Ajudante 2
		//   [08] Ajudante 3
		//   [09] Hora chegada
		//   [10] Time Service
		//   [11] Data chegada
		//   [12] Data saida
		//   [13] Hora de inicio de entrega
		//   [14] Valor do Frete (DAI_VALFRE)*
		//   [15] Frete Autonomo (DAI_FREAUT)*

		aAdd(_aRotas, "999999" )
		aAdd(_aRotas, "999999" )
		aAdd(_aRotas, "999999" )
		aAdd(_aRotas, ""       )
		aAdd(_aRotas, ""       )
		aAdd(_aRotas, ""       )
		aAdd(_aRotas, ""       )
		aAdd(_aRotas, ""       )
		aAdd(_aRotas, ""       )
		aAdd(_aRotas, ""       )
		aAdd(_aRotas, CriaVar("DAI_DTCHEG",.f.)	)
		aAdd(_aRotas, CriaVar("DAI_DTSAID",.f.)	)
		aAdd(_aRotas, ""       )
		aAdd(_aRotas, CriaVar("DAI_VALFRE",.f.) )
		aAdd(_aRotas, CriaVar("DAI_FREAUT",.f.) )

		//-- Avalia o SC9 para inclusao do DAI
		// [7] Montagem de Carga do SC9
		MaAvalSC9("SC9",7,,,,,,_aRotas)

	EndIf

Return
