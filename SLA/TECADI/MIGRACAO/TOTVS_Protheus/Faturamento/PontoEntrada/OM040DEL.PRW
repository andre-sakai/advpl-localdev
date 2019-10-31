
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada executado na validacao da exclusao     !
!                  ! do cadastro de motoristas                               !
!                  ! 1. Utilizado para validar se o motorista possui movimen-!
!                  !    tacoes de cargas                                     !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 09/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function OM040DEL
	// variavel de retorno
	local _lRet := .t.
	
	// verifica se ocorreu alguma movimentacao
	dbSelectArea("SZ3")
    SZ3->(dbOrderNickName("Z3_MOTORIS")) //6-Z3_FILIAL, Z3_MOTORIS
    If SZ3->(dbSeek( xFilial("SZ3")+DA4->DA4_COD ))
		Aviso("Tecadi: OM040DEL","Não é possível realizar a exclusão, pois este motorista já possui movimentações de cargas.",{"Fechar"})
		_lRet := .f.
    EndIf

Return(_lRet)