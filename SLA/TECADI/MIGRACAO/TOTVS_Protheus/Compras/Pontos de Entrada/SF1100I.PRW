
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado no final da gravacao da     !
!                  ! Nota Fiscal de Entrada                                  !
!                  ! 1. Utilizado para atualizar a data de digitacao da nota !
!                  !    fiscal da progr. de recebimentos                     !
!                  ! 2. Atualizar a programacao no cabecalho da nota         !
!                  ! 3. Atualizar a cubagem total no cabecalho da nota       !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 09/2010 !
+------------------+--------------------------------------------------------*/

User Function SF1100I
	// area inicial
	local _aAreaAtu := GetArea()

	// atualiza quantidade recebida da programacao de carga
	If (SF1->F1_TIPO=="B") .and. ( ! Empty(SD1->D1_PROGRAM) )
		// atualiza data de inicio
		dbSelectArea("SZ1")
		SZ1->(dbSetOrder(1))//1-Z1_FILIAL, Z1_CODIGO
		If SZ1->(dbSeek( xFilial("SZ1")+SD1->D1_PROGRAM ))
			If Empty(SZ1->Z1_DTDOC)
				RecLock("SZ1")
					SZ1->Z1_DTDOC := Date()
				MsUnLock()
			EndIf
		EndIf

		// atualiza o numero da programacao
		RecLock("SF1")
			SF1->F1_PROGRAM := SD1->D1_PROGRAM
			SF1->F1_CUBAGEM := sfRetCubag()
			SF1->F1_ZLOGREV := SD1->D1_ZLOGREV
		MsUnlock()

	EndIf

	// notas fiscais de transportes
	If (SF1->F1_TIPO=="N").and.(AllTrim(SF1->F1_ESPECIE)=="NFPS")
		// funcao para escolher os fechamentos de frete
		sfSelFechFre()
	EndIf

	// restaura area inicial
	RestArea(_aAreaAtu)

Return

//** funcao que retorna a cubagem (soma da cubagem de cada item)
Static Function sfRetCubag()
	local _aAreaSD1 := SD1->(GetArea())
	local _nRet := 0
	// seek do SD1
	local _cSeekSD1

	// pesquisa os itens da nota
	dbSelectArea("SD1")
	SD1->(dbSetOrder(1)) //1-D1_FILIAL, D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_COD, D1_ITEM
	SD1->(dbSeek( _cSeekSD1 := xFilial("SD1")+SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) ))
	While SD1->(!Eof()).and.(SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA)==_cSeekSD1)
		// soma total de cubagem
		_nRet += SD1->D1_ZCUBAGE
		// proximo item
		SD1->(dbSkip())
	EndDo

	// restaura area inicial
	RestArea(_aAreaSD1)
Return(_nRet)