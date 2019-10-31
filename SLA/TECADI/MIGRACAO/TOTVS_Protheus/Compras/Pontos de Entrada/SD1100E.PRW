#include "Totvs.ch"
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado no processo de Exclusao da  !
!                  ! Nota Fiscal de Entrada e Estorno de Classif. de Pre-Nota!
!                  ! chamado a cada exclusao de item da nota                 !
!                  ! 1. Utilizado para reabrir a programacao de recebimentos !
!                  ! 2. Utilizado para reabrir fechamento de fretes de notas !
!                  !    de transportes                                       !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 01/2010 !
+------------------+--------------------------------------------------------*/

User Function SD1100E
	// area atual
	Local _aAreaAtu := GetArea()
	// seek do SZF
	local _cSeekSZF

	// reabre programacao
	If (SF1->F1_TIPO=="B").and.( ! Empty(SD1->D1_PROGRAM) )
		// atualiza data de inicio
		dbSelectArea("SZ1")
		SZ1->(dbSetOrder(1))//1-Z1_FILIAL, Z1_CODIGO
		If SZ1->(dbSeek( xFilial("SZ1")+SD1->D1_PROGRAM ))
			RecLock("SZ1")
			SZ1->Z1_DTDOC := CtoD("//")
			MsUnLock()
		EndIf
	EndIf

	// reabre fechamentos de fretes
	If (SF1->F1_TIPO=="N").and.(AllTrim(SF1->F1_ESPECIE)=="NFPS")
		// atualiza dados da nota fiscal no fechamento
		dbSelectArea("SZF")
		SZF->(dbOrderNickName("ZF_NFDOC")) // 4-ZF_FILIAL+ZF_NFFIL+ZF_NFDOC+ZF_NFSERIE+ZF_NFFORNE+ZF_NFLOJA
		If SZF->(dbSeek( _cSeekSZF := xFilial("SZF")+SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) ))
			While SZF->(!Eof()).and.(SZF->(ZF_FILIAL+ZF_NFFIL+ZF_NFDOC+ZF_NFSERIE+ZF_NFFORNE+ZF_NFLOJA)==_cSeekSZF)
				// atualiza campos
				RecLock("SZF")
				SZF->ZF_NFFIL	:= ""
				SZF->ZF_NFDOC	:= ""
				SZF->ZF_NFSERIE	:= ""
				SZF->ZF_NFFORNE	:= ""
				SZF->ZF_NFLOJA	:= ""
				MsUnLock()
				// proximo item
				SZF->(dbSkip())
			EndDo
		EndIf
	EndIf

	// Geração de log com observações do usuário ao excluir um documento de entrada.
	U_FtGeraLog(cFilAnt, "SF1", SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA), "Nota Fiscal Excluída", "COM", "")

	// restaura area inicial
	RestArea(_aAreaAtu)

Return