#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada Pedido de compras para validar se      !
!                  ! continua a gravaçao (TudoOk)                            !
+------------------+---------------------------------------------------------+
!Autor             ! Emerson Eap TECNOLOGIA                                  !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 11/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function MT120OK()

	// variavel de retorno
	Local _lRet := .t.
	// numero do pedido atual
	Local _cPcScNum := ca120num

	// somente para 01-Armazem Geral
	If ( cEmpAnt != "01" )
		Return(_lRet)
	EndIf

	// chama funcao padrao para analise das aprovacoes/limites
	_lRet := U_FtAvaAlc(_cPcScNum, Nil, .f.)

Return(_lRet)