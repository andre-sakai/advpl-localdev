#INCLUDE "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Cadastro de NCM / Pos IPI                               !
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

User Function TFATC007

	// tabela padrao SYD - Nomeclatura Comum do Mercosul
	dbSelectArea("SYD")
	
	Private cCadastro := "Nomeclatura Comum do Mercosul"

	Private aRotina := {{"Pesquisar","AxPesqui",0,1} ,;
						{"Visualizar","AxVisual",0,2} ,;
						{"Incluir","AxInclui",0,3} ,;
						{"Alterar","AxAltera",0,4} ,;
						{"Excluir","AxDeleta",0,5} }

	DbSelectArea("SYD")
	SYD->(DbSetOrder(1))
	mBrowse(6,1,22,75,"SYD")
   
Return