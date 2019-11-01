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

User Function DL200TRB()
	// array com os campos padroes
	local _aCpoTrb := PARAMIXB

	// adiciona campo customizado
	aAdd(_aCpoTrb,{"PED_ZAGRUP", "C", TamSx3("C5_ZAGRUPA")[1], TamSx3("C5_ZAGRUPA")[2]})
	aAdd(_aCpoTrb,{"PED_ZDOCCL", "C", TamSx3("C5_ZDOCCLI")[1], TamSx3("C5_ZDOCCLI")[2]})

Return(_aCpoTrb)