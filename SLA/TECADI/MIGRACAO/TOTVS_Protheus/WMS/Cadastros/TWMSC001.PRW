#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Manutencao do Cadastro de Avarias de Containers         !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2010                                                !
+------------------+---------------------------------------------------------+
!   ATUALIZACOES                                                             !
+-------------------------------------------+-----------+-----------+--------+
!   Descricao detalhada da atualizacao      !Nome do    ! Analista  !Data da !
!                                           !Solicitante! Respons.  !Atualiz.!
+-------------------------------------------+-----------+-----------+--------+
!                                           !           !           !        !
!                                           !           !           !        !
+-------------------------------------------+-----------+-----------+-------*/

User Function TWMSC001

// campos a serem apresentados no browse
Local _aCampos := {	{"Código","X5_CHAVE" ,"",00,00,"@!"} ,;
					{"Avaria","X5_DESCRI","",00,00,"@!"} }

Private cTab		:= "ZB"
Private cCadastro	:= "Cadastro de Avarias de Containers"
Private aRotina		:= {{OemToAnsi("Pesquisar")	, "axPesqui"   , 0, 1}, ;
						{OemToAnsi("Visualizar"), 'U_WMSC001A(2)', 0, 2}, ;
						{OemToAnsi("Incluir")	, 'U_WMSC001A(3)', 0, 3}, ;
						{OemToAnsi("Alterar")	, 'U_WMSC001A(4)', 0, 4, 2}, ;
						{OemToAnsi("Excluir")	, 'U_WMSC001A(5)', 0, 5, 1}}

dbSelectArea("SX5")
dbSetOrder(1)
mBrowse(06, 01, 22, 75, "SX5",_aCampos,,,,,,,,,,,,, "X5_TABELA = '"+cTab+"'")

Return

//** funcao padarao do sistema para manutencao de tabela do SX5
User Function WMSC001A(_nOpc)

cSayCpo1 := "Codigo"
cSayCpo2 := "Avaria"

HS_TelSx5(,,_nOpc,2)

Return