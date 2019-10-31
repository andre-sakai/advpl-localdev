#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
! Descricao        ! Ponto de Entrada no Final da grava��o do documento      !
!                  ! de entrada, fora do controle transacional               !
!                  !                                                         !
+------------------+---------------------------------------------------------+
! Sub-descri��o    !                                                         !
+------------------+---------------------------------------------------------+
! Autor            ! Luiz Fernando Berti - SLA Consultoria                   !
! Data de cria��o  ! 07/2019                                                 !
+------------------+---------------------------------------------------------+
! Documenta��o                                                               !
! http://tdn.totvs.com/display/public/PROT/MT100AGR+-+Funcionalidades+em+    !
! notas+fiscais+de+entrada                                                   !
+------------------+---------------------------------------------------------+
! Redmine          !                      ! Chamado              !           !
+------------------+--------------------------------------------------------*/

User Function MT100AGR()
	LOCAL aArea := GetArea()

	// se processo de integra��o para barcode Sumitomo est� ativa
	Local lSumiBar := ""

	// apenas Tecadi AZ
	If (cEmpAnt == "01")
		// se processo de integra��o para barcode Sumitomo est� ativa
		lSumiBar := U_FtWmsParam("WMS_SUMITOMO_LEITURA_BARCODE", "L", .F., .F., Nil, SF1->F1_FORNECE, SF1->F1_LOJA, Nil, Nil)

		// TODO : remover data ap�s virada do projeto Sumitomo (23/07/19)
		If (INCLUI) .AND. ( Date() >= CtoD("23/07/19") )
			//Fun��o para relacionar Remessa (Z56) com NF Sumitomo
			If ( ExistBlock("TWMA047T") ) .And. (SF1->F1_TIPO == "B") .And. (SF1->F1_FORNECE == Subs(GetNewPar("TC_SRBTI","00031601"),1,TamSX3("A1_COD")[1])) .AND. (lSumiBar)
				Processa({|| U_TWMA047T() },"Processamento","...")
				RestArea(aArea)
			EndIf
		EndIf
	EndIf
Return

