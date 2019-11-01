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

User Function DL200BRW()
	// array com os campos padroes
	local _aCpoBrw := PARAMIXB

	// adiciona campo customizado
	aAdd(_aCpoBrw,{"PED_ZAGRUP",,"Agrupadora"    })
	aAdd(_aCpoBrw,{"PED_ZDOCCL",,"Doc/Nf Cliente"})

Return(_aCpoBrw)
