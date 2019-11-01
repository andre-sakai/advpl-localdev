#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
! Descricao        ! Ponto de entrada na validação da exclusão da Pré-Nota   !
!                  !                                                         !
!                  !                                                         !
+------------------+---------------------------------------------------------+
! Sub-descrição    !                                                         !
+------------------+---------------------------------------------------------+
! Autor            ! Luiz Fernando Berti - SLA Consultoria                   !
! Data de criação  ! 07/2019                                                 !
+------------------+---------------------------------------------------------+
! Documentação                                                               !
! http://tdn.totvs.com/pages/releaseview.action?pageId=6085271               !
+------------------+---------------------------------------------------------+
! Redmine          !  414                 ! Chamado              !           !
+------------------+--------------------------------------------------------*/

User Function A140EXC()
	LOCAL aArea := GetArea()
	LOCAL lRet  := .T.
	LOCAL cMsg,cUpd  := ""

	// Apenas Tecadi Armazéns
	If (cEmpAnt == "01")
	
		//Tratamento para exclusão do vínculo das notas fiscais na tabela de etiquetas (específico Sumitomo)
		If (lRet) .And. ( SF1->F1_TIPO = "B" ) .And. ( SF1->F1_FORNECE == Subs(GetNewPar("TC_SRBTI","00031601"),1,TamSX3("A1_COD")[1]) )
			cUpd:= "UPDATE "+RetSQLName("Z56")
			cUpd+= " SET Z56_NOTA = '', Z56_SERIE = '', Z56_ITEMNF = '' "
			cUpd+= " WHERE  Z56_FILIAL = '"+SF1->F1_FILIAL+"' "
			cUpd+= " AND Z56_NOTA   = '"+SF1->F1_DOC+"' "
			cUpd+= " AND Z56_SERIE  = '"+SF1->F1_SERIE+"' "
			cUpd+= " AND Z56_CODCLI = '"+SF1->F1_FORNECE+"' "
			cUpd+= " AND Z56_LOJCLI = '"+SF1->F1_LOJA+"'   "
			cUpd+= " AND D_E_L_E_T_ = '' "

			If ( TcSQLExec(cUpd) < 0)
				cMsg:= " Erro SQL ao desvincular as etiquetas da nota fiscal "+ TCSQLError()	
				U_FtGeraLog(SF1->F1_FILIAL,"SF1",SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA),cMsg,"001", "","000000")
				Aviso("Erro",cMsg,{"Fechar"},3)
				lRet := .F. 	
			EndIf
		EndIf
	EndIf

	RestArea(aArea)

Return lRet

