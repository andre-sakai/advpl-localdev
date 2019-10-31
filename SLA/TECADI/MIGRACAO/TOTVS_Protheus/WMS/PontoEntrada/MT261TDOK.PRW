
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada apos gravacao das transferecias de     !
!                  ! mercadoria                                              !
!                  ! - utilizado para gravar codigo do palete quando for ACD !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 10/2012 !
+------------------+---------------------------------------------------------+
!Observacoes       !                                                         !
+------------------+--------------------------------------------------------*/

User Function MT261TDOK
// area inicial
local _aArea := GetArea()
local _aAreaIni := SaveOrd({"SD3","Z08"})
// variaveis temporarias
local _nRegSD3

// quando for atraves do ACD/Coletor
If (IsTelnet())
	For _nRegSD3 := 1 to Len(aRegSD3)
		// posiciona no registro da tabela
		dbSelectArea("SD3")
		SD3->(dbGoTo(aRegSD3[_nRegSD3]))
		RecLock("SD3")
		SD3->D3_ZPALETE := Z08->Z08_PALLET
		SD3->(MsUnLock())
	Next _nRegSD3
EndIf

// restaura areas iniciais
RestArea(_aArea)
RestOrd(_aAreaIni)

Return