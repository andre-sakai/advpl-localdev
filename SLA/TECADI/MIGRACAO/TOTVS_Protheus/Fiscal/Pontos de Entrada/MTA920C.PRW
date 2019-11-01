#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado no final da gravacao dos    !
!                  ! dados da tabela SF2, na rotina Notas Fiscais de Saida   !
!                  ! Manual (MATA920 - Livros Fiscais), antes de gerar o SF3 !
!                  ! 1. Gravacao de campos complementares nao suportado pela !
!                  !    rotina automatica                                    !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 11/2012 !
+------------------+--------------------------------------------------------*/

User Function MTA920C

	// variaveis temporarias
	local _nX
	local _cTmpCampo

	// grava dados complementares para CT-e da 03-Tecadi Transportes
	If (AllTrim(Upper(FunName())) $ "TTMSXSGT/TTMSXDAT/TMSXDATW/RPC").and.(cEmpAnt=="03")
		// verifica se a variavel existe
		If (Type("_a920Dados")=="A")
			// varre todos os campos
			For _nX := 1 to Len(_a920Dados)
				// armazena o nome do campo
				_cTmpCampo := _a920Dados[_nX][1]
				// seleciona a tabela
				dbSelectArea("SF2")
				RecLock("SF2")
				SF2->(&_cTmpCampo) := _a920Dados[_nX][2]
				SF2->(MsUnLock())
			Next _nX
		EndIf
	EndIf

Return