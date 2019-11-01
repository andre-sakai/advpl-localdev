#Include "Totvs.ch"

/*-----------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                        !
+------------------------------------------------------------------------------+
!Descricao         ! Cadastro de Atividades                                    !
+------------------+-----------------------------------------------------------+
!Autor             ! TSC149-Percio A. de Oliveira                              !
+------------------+-----------------------------------------------------------+
!Data de Criacao   ! 12/2010                                                   !
+------------------+-----------------------------------------------------------+
!   ATUALIZACOES                                                               !
+-------------------------------------------+-----------+-----------+----------+
!   Descricao detalhada da atualizacao      !Nome do    ! Analista  !Data da   !
!                                           !Solicitante! Respons.  !Atualiz.  !
+-------------------------------------------+-----------+-----------+----------+
! Atualização da rotina para MVC            !           ! Luiz      ! 24/04/18 !
!                                           !           !    Poleza !          !
+-------------------------------------------+-----------+-----------+---------*/

User Function TWMSC002

	LOCAL _cAlias := "SZT"
	PRIVATE cCadastro := "Cadastro de Atividades WMS"
	PRIVATE aRotina     := MenuDef()


	dbSelectArea(_cAlias)
	dbSetOrder(1)

	mBrowse(, , , , _cAlias)

Return ( Nil )


// Define menu de acessos/rotinas
Static Function MenuDef()
	Local aRotina := { {"Pesquisar" ,"AxPesqui",0,1} ,;
	{"Visualizar"  ,"AxVisual",0,2} ,;
	{"Incluir"     ,"AxInclui",0,3} ,;
	{"Alterar"     ,"AxAltera",0,4} ,;
	{"Excluir"     ,"AxDeleta",0,5}}

Return aRotina
