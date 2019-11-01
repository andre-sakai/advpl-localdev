#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado após geração do registro de !
!                  ! movimentacao de mercadoria de terceiros (SB6)           !
!                  ! 1. Gravar campos customizados de controle: peso bruto,  !
!                  !    liquido e cubagem total                              !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 06/2014                                                 !
+------------------+--------------------------------------------------------*/

User Function SB6GRAVA
// variaveis temporarias
local _nCntProc := 0
// nota fiscal de saida
// precisa buscar os dados do SC6, pois os campos customizados não estao preenchidos - serao preenchidos no PE MSD2460
local _lBuscaSC6 := .f.

// somente na 01-Armazem
If (cEmpAnt == "01")
	// Remessa - Nota de Entrada
	If (SB6->B6_PODER3 == "R").and.(SD1->D1_TIPO == "B")
		SB6->B6_ZCUBAGE := SD1->D1_ZCUBAGE
		SB6->B6_ZPESOB  := SD1->D1_ZPESOB
		SB6->B6_ZPESOL  := SD1->D1_ZPESOL
		
		// Devolucao - Nota de Saida
	ElseIf (SB6->B6_PODER3 == "D")
		// verifica se eh na rotina de emissao de nota de saida
		While ( ! Empty(ProcName(_nCntProc)))
			// verifica o nome da rotina
			If (Upper(Alltrim(ProcName(_nCntProc))) $ "MATA460/MATA461/MAPVL2SD2")
				// busca dados do SC6
				_lBuscaSC6 := .t.
				Exit
			EndIf
			// controle da seq das funcoes
			_nCntProc++
		Enddo
		
		// atualiza dados
		SB6->B6_ZCUBAGE := IIf(_lBuscaSC6, SC6->C6_ZCUBAGE, SD2->D2_ZCUBAGE)
		SB6->B6_ZPESOB  := IIf(_lBuscaSC6, SC6->C6_ZPESOB , SD2->D2_ZPESOB )
		SB6->B6_ZPESOL  := IIf(_lBuscaSC6, SC6->C6_ZPESOL , SD2->D2_ZPESOL )
		
	EndIf
EndIf

Return
