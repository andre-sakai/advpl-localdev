#include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+                                                                              
!Descricao         ! Ponto de Entrada na tela de consulta dos documentos que !
!                  ! controla poder de terceiros (COMXFUN -> F4PODER3)       !
+------------------+---------------------------------------------------------+
!Uso               ! 1. Utilizado para incluir opcoes de pesquisa/ordem      !
+------------------+---------------------------------------------------------+
!Retorno           ! Array 1 posicao                                         !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 03/2013                                                 !
+------------------+--------------------------------------------------------*/

User Function MTF4PD3I
// variavel de retorno
local _aRetIndx := {}

// inclui indices da data de digitacao
aAdd(_aRetIndx,"B6_DTDIGIT")

Return(_aRetIndx)
