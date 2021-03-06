#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada Solic.Compras que valida a permiss�o de inclus�o (Antes de abrir a tela de inclus�o)!
+------------------+---------------------------------------------------------+
!Autor             ! Odair                                                   !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 09/2013                                                 !
+------------------+--------------------------------------------------------*/

User Function MT110VLD
	// variavel de retorno
	local _lRet := .t.

	//Verifica se usuario pode efetuar uma solicitacao de compra
	_lRet	:=	U_FTCOM01A()
	
	// Nao permite incluir solicitacao de compra.
	If ( !_lRet )
		Aviso("Tecadi: MT110VLD","Usu�rio n�o autorizado a operar com solicita��es de compras. Consulte seu Gestor.",{"OK"})
	EndIf
	
Return(_lRet)
