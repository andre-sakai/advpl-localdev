#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! M410PCDV                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! PE executado na opcao "Retornar" do pedido de venda a   !
!                  ! cada linha atualiza do aCols (itens do pedido SC6)      !
!                  ! 1. Utilizado para substrair o saldo ja resercados de    !
!                  !    outros estoques (nao conformidade, etc)              !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe Jose Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 19/03/15                                                !
+------------------+--------------------------------------------------------*/

User Function M410PCDV()

	// parametros recebidos
	Local _cExpA1 := PARAMIXB[1] //"alias" do arquivo de itens de notas de entrada.

	// Posiscao dos campos
	Local _nPosTES     := aScan(aHeader, {|x| AllTrim(x[2])=="C6_TES"})    // TES
	Local _nPosSerOri  := aScan(aHeader, {|x| AllTrim(x[2])=="C6_SERIORI"})// Serie nota original
	Local _nPosProduto := aScan(aHeader, {|x| AllTrim(x[2])=="C6_PRODUTO"})// Código Produto
	Local _nPosLocal   := aScan(aHeader, {|x| AllTrim(x[2])=="C6_LOCAL"})  // Armazem do Produto
	Local _nPosQtd     := aScan(aHeader, {|x| AllTrim(x[2])=="C6_QTDVEN"}) // Quantidade
	Local _nPosSB6     := aScan(aHeader, {|x| AllTrim(x[2])=="C6_IDENTB6"})// Identificador SB6
	Local _nPosDocOri  := aScan(aHeader, {|x| AllTrim(x[2])=="C6_NFORI"})  // Nota Original
	Local _nPosItemOri := aScan(aHeader, {|x| AllTrim(x[2])=="C6_ITEMORI"})// Item Original
	Local _nPosVlrUnit := aScan(aHeader, {|x| AllTrim(x[2])=="C6_PRCVEN"}) // Valor Unitario
	Local _nPosVlrTot  := aScan(aHeader, {|x| AllTrim(x[2])=="C6_VALOR"})  // Valor Total

	// Variavel para guardar saldo do Produto
	Local _nSaldo := 0
	Local _aSaldo := {}

	// Verifica saldo disponivel (Saldo SB6 - Saldo Reservado)
	// Estrutura do Retorno
	// 1 - Saldo Real (SB6 - Reservado)
	// 2 - Saldo SB6
	// 3 - Saldo Reservado
	_aSaldo := U_FtSldSb6(aCols[N,_nPosSB6],;
		(_cExpA1)->D1_FORNECE ,;
		(_cExpA1)->D1_LOJA    ,;
		aCols[N,_nPosDocOri]  ,;
		aCols[N,_nPosSerOri]  ,;
		aCols[N,_nPosItemOri] ,;
		aCols[N,_nPosProduto] ,;
		aCols[N,_nPosLocal]   ,;
		aCols[N,_nPosTES]      )

	// saldo apresentado no Grid menos a reserva (tipos de estoque)
	_nSaldo := aCols[N,_nPosQtd] - _aSaldo[3]

	// Atualiza valor disponivel para devolução na grid.
	aCols[N,_nPosQtd]    := _nSaldo
	// Atualiza valor Total do Produto na Grid.
	aCols[N,_nPosVlrTot] := a410Arred(aCols[N,_nPosQtd] * aCols[N,_nPosVlrUnit],"C6_VALOR")

Return