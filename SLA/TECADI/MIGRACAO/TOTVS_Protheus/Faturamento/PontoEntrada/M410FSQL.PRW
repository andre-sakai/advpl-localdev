/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela da      !
!                  ! rotina de Pedido de Vendas (MATA410)                    !
!                  ! 1. Utilizado para filtrar os pedidos de acordo com os   !
!                  !    acessos do usuario (Produtos/Servicos)               !
+------------------+---------------------------------------------------------+
!Retorno           ! Caracter: Expressao SQL para filtro                     !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Observação        !                                      				   	 !
!		           !                                                         !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 08/2011                                                 !
+------------------+---------------------------------------------------------+
!Data de Alteração ! 01/10/2019 - Luiz Poleza                                !
+------------------+--------------------------------------------------------*/

User Function M410FSQL
	// retorno da condicao SQL para filtro
	local _cFiltroSQL := ""
	// extrai as informacoes do usuario logado
	local _aUsrInfo := U_FtWmsFil()
	// se deve filtrar os pedidos por usuario
	local _lFiltrar := _aUsrInfo[1]

	// filtro dos pedidos
	If (_lFiltrar)
		_cFiltroSQL += "C5_FILIAL = '" + xFilial("SC5") + "' .AND. C5_TIPO == 'N' .AND. C5_TIPOOPE $ '" + _aUsrInfo[2] + "'"
	EndIf

Return(_cFiltroSQL)