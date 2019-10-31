#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada na entrada da tela do cadastro de      !
!                  ! clientes                                                !
+------------------+---------------------------------------------------------+
!Uso               ! 1. Utilizado para filtrar os dados de acordo com o      !
!                  !    perfil do cliente                                    !
+------------------+---------------------------------------------------------+
!Retorno           ! Condição ADVPL                                          !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 04/2016 !
+------------------+--------------------------------------------------------*/

User Function MA030BRW()
	// area atual
	Local _aAreaAtu := SA1->(GetArea())
	// filtro de retorno
	Local _cRetFiltro := ""
	// retorna os grupos do usuario logado
	local _aGrupos := FWSFUsrGrps(__cUserId)
	// variaveis temporaias
	local _nX

	// somente para 01-Armazem
	If (cEmpAnt <> "01")
		Return(_cRetFiltro)
	EndIf

	// varre todos os grupos e retornar descrição do grupo
	For _nX := 1 to Len(_aGrupos)
		// filtro de servicos (000001 - GATE)
		If (Upper(_aGrupos[_nX]) $ "000001")
			_cRetFiltro := "SA1->A1_COD == '000449' .OR. SA1->A1_TIPO == 'X'"
			Exit
		EndIf
	Next _nX

	// restura area atual
	RestArea(_aAreaAtu)

Return(_cRetFiltro)