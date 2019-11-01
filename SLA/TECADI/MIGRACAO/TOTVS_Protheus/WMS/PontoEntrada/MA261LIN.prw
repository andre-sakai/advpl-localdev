#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                         FICHA TECNICA DO PROGRAMA                          !
+------------------+---------------------------------------------------------+
!Descricao         ! PE na validacao da linha da rotina de transferencia     !
!                  ! interna (mod.2) de produtos (MATA161)                   !
!                  ! 1. Valida campo "End.Destino"                           !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 04/2017 !
+------------------+--------------------------------------------------------*/

User Function MA261LIN()
	// variavel de retorno
	local _lRet := .t.

	// valida campo de endereco de destino
	If (Empty(aCols[N,10]))
		// mensagem
		MsgAlert("Favor informar o endereço de destino.","Atencao (MA261LIN)")
		// variavel de controle e retorno
		_lRet := .f.
	EndIf

Return(_lRet)