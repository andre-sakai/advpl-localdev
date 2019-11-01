#INCLUDE "FONT.CH"
#INCLUDE "protheus.ch"
#INCLUDE "rwmake.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Contratos WMS											 !
+------------------+---------------------------------------------------------+
!Autor             ! TSC149-Percio Alexandre de Oliveira                     !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2010                                                 !
+------------------+---------------------------------------------------------+
!   ATUALIZACOES                                                             !
+-------------------------------------------+-----------+-----------+--------+
!   Descricao detalhada da atualizacao      !Nome do    ! Analista  !Data da !
!                                           !Solicitante! Respons.  !Atualiz.!
+-------------------------------------------+-----------+-----------+--------+
!                                           !           !           !        !
!                                           !           !           !        !
+-------------------------------------------+-----------+-----------+-------*/

User Function TWMSA005()

Private aRotina     := {} 
Private cCadastro	:= OemToAnsi("Contrato de Prestacao de Servicos")    

aRotina	:= {	{ OemToAnsi("Pes&quisar"),"AxPesqui"  ,0,1},;	//"Pesquisar"
				{ OemToAnsi("&Visualizar"),"At250Manut",0,2},;	//"Visualizar"
				{ OemToAnsi("&Incluir"),"At250Manut",0,3},;	//"Incluir"
				{ OemToAnsi("&Alterar"),"At250Manut",0,4},;	//"Alterar"
				{ OemToAnsi("&Excluir"),"At250Manut",0,5},;	//"Excluir"
				{ OemToAnsi("Gera &P.V."),"U_TWMSA004()",0,7},;	//"Gera P.V"
				{ OemToAnsi("&Conhecimento"),"MsDocument",0,4} }	//"Conhecimento"

mBrowse( 6,1,22,75,"AAM")

RetIndex("AAM")
Return NIL
