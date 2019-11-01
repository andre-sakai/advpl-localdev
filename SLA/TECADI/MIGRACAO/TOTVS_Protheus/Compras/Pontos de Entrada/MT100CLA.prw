#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
! Descricao        ! Ponto de Entrada na classificação do documento          !
!                  ! de entrada, fora do controle transacional               !
!                  !                                                         !
+------------------+---------------------------------------------------------+
! Sub-descrição    !                                                         !
+------------------+---------------------------------------------------------+
! Autor            ! Luiz Fernando Berti - SLA Consultoria                   !
! Data de criação  ! 07/2019                                                 !
+------------------+---------------------------------------------------------+
! Documentação                                                               !
! http://tdn.totvs.com/pages/releaseview.action?pageId=6085391               !
+------------------+---------------------------------------------------------+
! Redmine          !                      ! Chamado              !           !
+------------------+--------------------------------------------------------*/

User Function MT100CLA()
	LOCAL aArea := GetArea()

	// se processo de integração para barcode Sumitomo está ativa
	Local lSumiBar := ""

	// apenas Tecadi AZ
	If (cEmpAnt == "01")

		// se processo de integração para barcode Sumitomo está ativa
		lSumiBar := U_FtWmsParam("WMS_SUMITOMO_LEITURA_BARCODE", "L", .F., .F., Nil, SF1->F1_FORNECE, SF1->F1_LOJA, Nil, Nil)

		// TODO: remover data após virada do projeto Sumitomo em 23/07/19
		//Função para relacionar Remessa de etiquetas (tabela Z56) com NF Sumitomo
		If (ExistBlock("TWMA047T")) .And. (SF1->F1_TIPO == "B") .And. ( SF1->F1_FORNECE == Subs(GetNewPar("TC_SRBTI","00031601"),1,TamSX3("A1_COD")[1]) ) .And. (lSumiBar) .AND. ( Date() >= CtoD("23/07/19") )
			Processa({|| U_TWMA047T() },"Processamento","...")
			RestArea(aArea)
		EndIf
	EndIf
	
	RestArea(aArea)

Return

