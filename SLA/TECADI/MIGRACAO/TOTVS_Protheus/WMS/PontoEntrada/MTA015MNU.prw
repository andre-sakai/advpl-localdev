#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela do      !
!                  ! cadastro de enderecos, usado para adicionais botoes     !
!                  ! 1. Botao para cadastro de enderecos em massa            !
!                  ! 2. Botao para alterar enderecos em massa                !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 03/2017 !
+------------------+--------------------------------------------------------*/

User Function MTA015MNU()
	// opcao para gerar enderecos em massa
	aAdd(aRotina,{ "Cadastrar Endereços em Massa", "U_FtGeraEnd",0,3,0,nil })
	aAdd(aRotina,{ "Gera endereços Bloco em massa", "U_FtGeraBloc",0,3,0,nil })
	// opcao para alterar enderecos em massa
	aAdd(aRotina,{ "Alterar Endereços em Massa", "U_TWMSA034",0,3,0,nil })
	// opcao para alterar informacoes de produtos e quantidades
	aAdd(aRotina,{ "Alterar dados de picking", "U_TWMSC020",0,3,0,nil })
Return