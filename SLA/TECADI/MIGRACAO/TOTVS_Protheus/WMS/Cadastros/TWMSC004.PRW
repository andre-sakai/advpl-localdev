#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Cadastro de M�quinas/Equipamentos                       !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 08/2014                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSC004
Private cString := "SZQ"
dbSelectArea("SZQ")
dbSetOrder(1)
AxCadastro(cString,"Cadastro de M�quinas/Equipamentos","U_WMSC004A()")
Return

// ** funcao para validar se o equipamento podera ser excluido
User Function WMSC004A
Return(.f.)
