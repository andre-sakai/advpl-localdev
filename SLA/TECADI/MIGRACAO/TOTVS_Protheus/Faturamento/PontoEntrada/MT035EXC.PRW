
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na função Mata035Ex, (vali- !
!                  ! dação de exclusão do Grupo de Produtos)                 !
!                  ! 1. Utilizado para validar se o codigo esta em uso no    !
!                  !    cadastro de cliente                                  !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 01/2011                                                 !
+------------------+---------------------------------------------------------+
!   ATUALIZACOES                                                             !
+-------------------------------------------+-----------+-----------+--------+
!   Descricao detalhada da atualizacao      !Nome do    ! Analista  !Data da !
!                                           !Solicitante! Respons.  !Atualiz.!
+-------------------------------------------+-----------+-----------+--------+
!                                           !           !           !        !
!                                           !           !           !        !
+-------------------------------------------+-----------+-----------+-------*/

User Function MT035EXC
	// armazena area inicial
	Local _aAreaSA1 := SA1->(GetArea())
	// variavel de retorno
	Local _lRet := .t.

	// pesquisa se existe cliente
	dbSelectArea("SA1")
	SA1->(dbOrderNickName("A1_SIGLA")) // A1_FILIAL, A1_SIGLA
	If SA1->(dbSeek( xFilial("SA1")+SBM->BM_GRUPO ))
		Aviso("Atenção!","Este Sigla esta sendo utilizada em algum produto ou cliente e não poderá ser excluído.",{"Voltar"},2)
		_lRet := .f.
	EndIf

	// restaura area inicial
	RestArea(_aAreaSA1)
Return(_lRet)