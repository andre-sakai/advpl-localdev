#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela de      !
!                  ! alteracao/visualizacao do contratos, usado para         !
!                  ! adicionar botoes na EnchoiceBar                         !
!                  ! 1. Botao para visualizar os detalhes de cada servico    !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 01/2012                                                 !
+------------------+--------------------------------------------------------*/

User Function AT250BUT
	// variavel de retorno
	local _aRetBtn := {}

	// opcao para visualizar os detalhes do servico
	aAdd(_aRetBtn,{"LJPRECO",{|| U_TWMSG002() } ,"Detalhes do Serviço"})

Return(_aRetBtn)