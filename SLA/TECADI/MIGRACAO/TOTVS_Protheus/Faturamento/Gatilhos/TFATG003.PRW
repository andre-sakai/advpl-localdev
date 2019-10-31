#Include "RwMake.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Gatilho utilizado para atualizar o nome do cliente/forn !
!                  ! na tela de pedidos de venda OU notas de entrada         !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 05/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function TFATG003(mvAlias,mvTipo,mvChave)
	local _cRet := ""
	
	// SC5 - Pedido de Venda
	If (mvAlias=="SC5")
		If (mvTipo $ "B/D")
			_cRet := Posicione("SA2",1, xFilial("SA2")+mvChave ,"A2_NOME")
		Else
			_cRet := Posicione("SA1",1, xFilial("SA1")+mvChave ,"A1_NOME")
		EndIf
	// SF1 - Nota Fiscal de Entrada
	ElseIf (mvAlias=="SF1")
		If (mvTipo $ "B/D")
			_cRet := Posicione("SA1",1, xFilial("SA1")+mvChave ,"A1_NOME")
		Else
			_cRet := Posicione("SA2",1, xFilial("SA2")+mvChave ,"A2_NOME")
		EndIf
	EndIf
Return(_cRet)