#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Cadastro de Containers                                  !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 10/2010                                                 !
+------------------+---------------------------------------------------------+
!   ATUALIZACOES                                                             !
+-------------------------------------------+-----------+-----------+--------+
!   Descricao detalhada da atualizacao      !Nome do    ! Analista  !Data da !
!                                           !Solicitante! Respons.  !Atualiz.!
+-------------------------------------------+-----------+-----------+--------+
!                                           !           !           !        !
!                                           !           !           !        !
+-------------------------------------------+-----------+-----------+-------*/

User Function TFATC004
	Private cString := "SZC"
	dbSelectArea("SZC")
	dbSetOrder(1)
	AxCadastro(cString,"Cadastro de Containers","U_FATC004A()")
Return

//** funcao para validar se o armador podera ser excluido
User Function FATC004A
Return(.t.)