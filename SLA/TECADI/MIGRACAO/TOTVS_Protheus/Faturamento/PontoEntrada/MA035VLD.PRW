
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na função Ma035Valid, (vali-!
!                  ! dação inclusao ou alteracao do Grupo de Produtos)       !
!                  ! 1. Utilizado para obrigar o preenchimento do campo base !
!                  !    do CNPJ do cliente                                   !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 08/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function MA035VLD
// variavel de retorno
local _lRet := .t.
// opcao selecionada
local _nOpc := ParamIxb[1]

// verifica se a base do CNPJ foi preenchida
If (_lRet).and.(_nOpc==3).and.(M->BM_TIPGRU=="99").and.(Empty(M->BM_ZCGC))
	Aviso("Tecadi: MA035VLD","Para grupos do tipo SIGLA DE CLIENTE, é obrigatório informar a base do CNPJ do cliente",{"Voltar"})
	_lRet := .f.
EndIf

// verifica o subgrupo para materiais de consumo
If (_lRet).and.(_nOpc==3).and.( ! M->BM_TIPGRU $ "99/90").and.(Empty(M->BM_ZSUBGRU))
	Aviso("Tecadi: MA035VLD","Para materiais de consumo, favor informar o sub-grupo.",{"Voltar"})
	_lRet := .f.
EndIf

Return(_lRet)