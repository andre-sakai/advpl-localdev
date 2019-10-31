#Include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura do browse da    !
!                  ! solicitacao de compras, utilizado para filtrar as SC    !
!                  ! de acordo com o usuario logado                          !
+------------------+---------------------------------------------------------+
!Autor             ! Odair Garcia Arouca                                     !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2013                                                 !
+------------------+--------------------------------------------------------*/

User Function MT110QRY()
	Local _cFiltro := ''
	Local _lRet := .t.

	// se for Administrador não Filtra as Solicitacoes
	If (__cUserID == "000000")
		Return (_cFiltro)
	EndIf

	// Se for Aprovador não filtra Nada
	dbSelectArea("SAK")
	SAK->(dbSetOrder(2))
	If SAK->(dbSeek( xFilial("SAK")+__cUserID ))
		Return (_cFiltro)
	EndIf

	// se for Comprador não filtra Nada
	dbSelectArea("SY1")
	SY1->(dbSetOrder(3))
	If SY1->(dbSeek( xFilial("SY1")+__cUserID ))
		Return (_cFiltro)
	EndIf

	//Em qualquer outra Condicao, filtra as solicitacoes do Usuário

	//Verifica se usuario pode efetuar uma solicitacao de compra, baseando-se na tabela Z26
	_lRet := U_FTCOM01A(1)

	// Caso falso, insere um filtro para nao apresentar registros
	If ( !_lRet )
		_cFiltro := " C1_FILIAL = 'ZZZ' "
	Else
		_cFiltro := " C1_USER = '" +__cUserID+ "' "
	EndIf

Return (_cFiltro)
