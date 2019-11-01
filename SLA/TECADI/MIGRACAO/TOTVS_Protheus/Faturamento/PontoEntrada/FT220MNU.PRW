#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela do      !
!                  ! cadastro de usuarios do portal                          !
!                  ! 1. Botao para definicao de menu por usuario             !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 05/2014                                                 !
+------------------+--------------------------------------------------------*/

User Function FT220MNU
	
	// definicao do menu do usuario
	aAdd(aRotina,{"Define Menu"  ,"U_TPRTA001",0,4,0,NIL})
	// definicao da primeira senha
	aAdd(aRotina,{"Gera 1a Senha","U_TPRTA002",0,4,0,NIL})
	// consulta de LOG
	aAdd(aRotina,{"Consulta Log" ,"U_FtConsLog(xFilial('AI3'), 'AI3', xFilial('AI3')+AI3->AI3_CODUSU )",0,4,0,NIL})
	
Return
