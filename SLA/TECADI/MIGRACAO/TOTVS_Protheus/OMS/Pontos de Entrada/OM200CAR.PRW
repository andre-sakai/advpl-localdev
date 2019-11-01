#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na gravacao dos itens da    !
!                  ! cargas do OMS                                           !
!                  ! OBS: UTILIZAR EM CONJUNTO COM O PE OM200QRY             !
!                  ! 1. Alterar condicao da QUERY para filtrar pedidos com   !
!                  !    bloqueio de estoque (controle Tecadi do WMS)         !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 02/2013                                                 !
+------------------+--------------------------------------------------------*/

User Function OM200CAR
	// recebe a query padrao
	local _cQuery := ParamIxb[1]

	// utiliza o ChangeQuery para padronizar o Script
	_cQuery := ChangeQuery(_cQuery)

	// atualiza filtro por bloqueio de Estoque
	_cQuery := StrTran(_cQuery,"AND C9_BLEST = '  '","AND C9_BLEST IN ('  ','02') AND C9_BLWMS = '  '")

	// a partir da versão 12.1.23 lobo-guará, agora tem a tabela na consulta
	_cQuery := StrTran(_cQuery,"AND SC9.C9_BLEST = '  '","AND SC9.C9_BLEST IN ('  ','02') AND SC9.C9_BLWMS = '  '")

Return(_cQuery)