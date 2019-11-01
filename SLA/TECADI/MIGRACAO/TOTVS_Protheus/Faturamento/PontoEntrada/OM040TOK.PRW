
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na função Os040TudOk, (vali-!
!                  ! dação inclusao ou alteracao do cadastro de motoristas)  !
!                  ! 1. Utilizado para obrigar o preenchimento dos campos    !
!                  !    CPF ou Doc. Estrangeiro, de acordo com o pais        !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 08/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function OM040TOK
	// variavel de retorno
	local _lRet := .t.
	
	// verifica se os documentos foram informados corretamente
	// BRASIL	
	If (INCLUI).AND.(M->DA4_ZPAIS=="105").and.(Empty(M->DA4_CPF))
		Aviso("Tecadi: OM040TOK","Quando o país for Brasil, é obrigatório informar o CPF.",{"Fechar"})
		_lRet := .f.
	// ESTRANGEIRO
	ElseIf (INCLUI).AND.(M->DA4_ZPAIS<>"105").and.(Empty(M->DA4_ZDOCES))
		Aviso("Tecadi: OM040TOK","É obrigatório informar o Documento de Estrangeiro.",{"Fechar"})
		_lRet := .f.
	EndIf

Return(_lRet)