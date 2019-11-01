#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada na rotina de montagem de Cargas        !
!                  ! USAR EM CONJUNTO COM : DL200BRW / DL200TRB / OM200GRV   !
!                  ! 1. Incluir campos customizados no Browse dos Pedidos    !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 06/2017 !
+------------------+--------------------------------------------------------*/

User Function OM200GRV()
	RecLock("TRBPED",.F.)
	TRBPED->PED_ZAGRUP := SC5->C5_ZAGRUPA
	TRBPED->PED_ZDOCCL := SC5->C5_ZDOCCLI
	MsUnlock()
Return