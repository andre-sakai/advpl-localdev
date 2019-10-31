#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                         FICHA TECNICA DO PROGRAMA                          !
+------------------+---------------------------------------------------------+
!Descricao         ! PE antes da montagem da tela da rotina de desmontagem de!
!                  ! produtos (MATA242), para incluir campos no browse       !
!                  ! OBS: UTILIZAR EM CONJUNTO COM O PE MTA242I              !
!                  ! 1. Apresentar campos customizados                       !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 03/2016 !
+------------------+--------------------------------------------------------*/

User Function MT242CPO
	// variavel de retorno com os campos adicionais para o browse
	local _aRetCpo := {"D3_ZNUMOS", "D3_ZSEQOS", "D3_ZETQPLT", "D3_ZORIGNS", "D3_ZSERIE"}
Return(_aRetCpo)