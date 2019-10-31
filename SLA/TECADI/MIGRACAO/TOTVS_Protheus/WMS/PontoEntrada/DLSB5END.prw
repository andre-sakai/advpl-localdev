/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na funcao WmsEndereca       !
!                  ! 1. Utilizado para definir Codigo Padrao da Zona de      !
!                  !    Armazenagem para Operacoes de CrossDocking           !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 11/2017 !
+------------------+--------------------------------------------------------*/

User Function DLSB5END()
	// recebimento de parametros
	Local _cCodProd := PARAMIXB[1]
	// variavel de retorno
	Local _aZonaRet := {"000001", .t.}

	// define zona de cross-docking
	If (cEmpAnt == "01")
		_aZonaRet[1] := "000002"
		_aZonaRet[2] := .t.
	EndIf

Return(_aZonaRet)
