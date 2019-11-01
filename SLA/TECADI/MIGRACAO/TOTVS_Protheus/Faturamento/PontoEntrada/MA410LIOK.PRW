#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na validacao da linha no    !
!                  ! Pedido de Venda                                         !
!                  ! 1. Utilizado para validar a serie da nota de devolucao  !
!                  ! 2. Validar saldo do produto conforme reservas           !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 10/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function M410LIOK()
	// Area inicial
	local _aAreaSB1 := SB1->(GetArea())
	local _aAreaSB2 := SB2->(GetArea())

	// Variavel de retorno
	Local _lRet := .T.

	// Posiscao dos campos
	Local _nPosTES     := aScan(aHeader, {|x| AllTrim(x[2])=="C6_TES"})     // TES
	Local _nPosSerOri  := aScan(aHeader, {|x| AllTrim(x[2])=="C6_SERIORI"}) // Serie nota original
	Local _nPosProduto := aScan(aHeader, {|x| AllTrim(x[2])=="C6_PRODUTO"}) // Código Produto
	Local _nPosItem    := aScan(aHeader, {|x| AllTrim(x[2])=="C6_ITEM"})    // Item

	// variavel de controle
	local _nL_Ite := 1
	local _nPos   := 0

	// se for INCLUSAO ou ALTERACAO / tipo do pedido for PRODUTO
	If (M->C5_TIPO=="N") .AND. ( (Inclui) .OR. (Altera) ) .AND. (M->C5_TIPOOPE == "P") .AND. (cEmpAnt == "01")

		// se estiver excluindo a linha, produto controlar lote e tiver selecionado lote com F10 (gravado na Z45), então irá excluir do array
		If (aCols[N,Len(aHeader)+1]) .AND. ( Rastro(aCols[N,_nPosProduto],"L") )
			If ( TYPE("_aLotesPV") == "A" )
				// pesquisa o item na variavel publica
				_nPos := aScan(_aLotesPV,{|x| x[_nL_Ite] == aCols[N,_nPosItem] })

				// exclui o item do vetor/variavel publica
				while (_nPos > 0)
					Adel(_aLotesPV, _nPos)
					ASize(_aLotesPV,Len(_aLotesPV)-1)
					_nPos := aScan(_aLotesPV,{|x| x[_nL_Ite] == aCols[N,_nPosItem] })
				enddo
			Endif
		EndIf

		// valida se está utilizando a TES correta (99A) caso esteja utilizando nota fiscal série DI (sem controle fiscal SPED/SEFAZ)
		If (AllTrim(aCols[N,_nPosSerOri]) == "DI")
			// verifica se a TES esta correta
			If (AllTrim(aCols[N,_nPosTES]) <> "99A")
				Aviso("Tecadi: M410LIOK","A TES informada para este processo está incorreta. Favor entrar em contato com o setor fiscal para maiores instruções.",{"OK"})
				//Muda a variavel de retorno
				_lRet := .F.
				Return(_lRet)
			EndIf
		EndIf


	EndIf

	//Restaura area inicial
	RestArea(_aAreaSB1)
	RestArea(_aAreaSB2)

Return(_lRet)