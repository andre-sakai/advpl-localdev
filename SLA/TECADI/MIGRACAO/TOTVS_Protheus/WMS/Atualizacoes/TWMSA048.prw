#Include 'Protheus.ch'
#Include "TOPCONN.CH"

#DEFINE TAB CHR(09)

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
! Descricao        ! Rotinas para integração entre os sistemas GWS (Sumitomo)!
!                  ! e Totvs, conforme projeto de integração 2019 fase 1     !
!                  !                                                         !
+------------------+---------------------------------------------------------+
! Sub-descrição    ! EDI/Integracões de EXPORTAÇÃO                           !
+------------------+---------------------------------------------------------+
! Autor            ! Luiz Fernando Berti - SLA Consultoria                   !
! Data de criação  ! 06/2019                                                 !
+------------------+---------------------------------------------------------+
! Redmine          ! 414                     ! Chamado           !           !
+------------------+--------------------------------------------------------*/

/*/{Protheus.doc} TWMSA048
Exportação de arquivos Sumitomo.
@type function
@author Luiz Fernando
@since 22/05/2019
/*/
User Function TWMSA048()

	LOCAL cTipo   := PARAMIXB[1]//E-Sep Entrada; S-Sep. Saida
	LOCAL cNumOs  := PARAMIXB[2]
	LOCAL cSeqOS  := PARAMIXB[3]
	LOCAL cCodCli := PARAMIXB[4]
	LOCAL cLojCli := PARAMIXB[5]

	If cTipo == "E"
		fSepEnt(cNumOs,cSeqOS,cCodCli,cLojCli)//Exportação Sepração de Entrada.
	Else
		fSepSai(cNumOS,cSeqOS,cCodCli,cLojCli)//Exportação Separação de Saída.
	EndIf


Return

/*/{Protheus.doc} fSepEnt
Exportação Arquivo de separação de entrada.
@type function
@author Luiz Fernando Berti
@since 22/05/2019
/*/
Static Function fSepEnt(cNumOS,cSeqOS,cCodCli,cLojaCli )

	LOCAL nHdl   
	LOCAL cArquivo := ""
	LOCAL cLinha   := ""
	LOCAL nLinha   := 0 
	LOCAL cQuery   := ""
	LOCAL cCliTI   := GetNewPar("TC_SRBTI","00031601")//Cliente SRB Sta Catarina
	LOCAL cCliTP   := GetNewPar("TC_SRBTP","00031602")//Cliente SRB Parana cliente 000316  loja 02
	LOCAL cIFSeq   := ""//soma1(GetMV("TC_IFSEQSU"))
	LOCAL cBatch   := ""//soma1(GetMV("TC_BATCHSU"))
	LOCAL cDest    := ""
	LOCAL cExActCl := ""//Iif(cFilAnt=="103","TI","TP")
	LOCAL aDados   := {}
	LOCAL cMsg1    := "fSepEnt"

	cMsg1+= chr(13)+chr(10)
	cMsg1+= (" Usuario=["+cUsername+"] Computador=["+GetComputerName()+"]")
	cMsg1+= (" IP=["+Getclientip()+"]")
	cMsg1+= (" Thread=["+cValToChar(ThreadId())+"]")
	cMsg1+= chr(13)+chr(10)

	DBselectArea("Z05")
	Z05->(DBSetOrder(01))//Z05_FILIAL+Z05_NUMOS                                                                                                                                            

	Do Case 
		Case cFilAnt == "103" 
		cExActCl := "TIT"
		cCodCli  := Subs(cCliTI,1,TamSX3("A1_COD")[1])
		cLojaCli := Subs(cCliTI,(TamSX3("A1_COD")[1])+1)   
		cDest    := "FRG" 
		Case cFilAnt == "105" 
		cExActCl := "TCU"
		cCodCli  := Subs(cCliTP,1,TamSX3("A1_COD")[1])
		cLojaCli := Subs(cCliTP,(TamSX3("A1_COD")[1])+1)
		cDest    := "FRG"

		Case cFilAnt == "106" 
		cExActCl := "TSJ"
		cCodCli  := Subs(cCliTP,1,TamSX3("A1_COD")[1])
		cLojaCli := Subs(cCliTP,(TamSX3("A1_COD")[1])+1)		
		cDest    := "FRG"	

	EndCase


	If !ExistDir( "\sumitomo\exportacao\" )
		MakeDir( "\sumitomo\exportacao\" )
	EndIf

	cMsg:= "INICIO EXPORTAÇÃO SUMITOMO Separação de Entrada GERANDO ARQUIVO "+FWTimeStamp(1,Date(),Time())
	U_FtGeraLog(cFilAnt, "", "", cMsg, "002", "", "000000")	

	//Busca separacoes de entrada.
	cQuery:= "SELECT Z07_FILIAL, Z55_PEDCLI, Z05_NUMOS, Z56_TIPO ,SUM(Z56_QUANT) AS QUANTIDADE "
	cQuery+= " FROM   "+RetSQLName("Z07")+" Z07 "
	cQuery+= " 		INNER JOIN "+RetSQlName("Z05")+" Z05 "
	cQuery+= " 		ON Z05_FILIAL = Z07_FILIAL "
	cQuery+= " 		AND Z05_NUMOS = Z07_NUMOS "
	cQuery+= " 		AND Z05_TPOPER = 'E' "// -- Somente OS de entrada.
	cQuery+= " 		AND Z05.D_E_L_E_T_ != '*' "
	cQuery+= "		INNER JOIN "+RetSQLName("SB1")+" SB1 "
	cQuery+= " 		ON SB1.B1_FILIAL = '"+xFilial("SB1")+"' "
	cQuery+= " 		AND B1_COD = Z07.Z07_PRODUT  " 
	cQuery+= " 		AND SB1.D_E_L_E_T_ != '*' "
	cQuery+= "        INNER JOIN "+RetSqlName("Z56")+" Z56 "
	cQuery+= "                ON Z56.Z56_FILIAL = Z07.Z07_FILIAL "
	cQuery+= "                   AND Z56.Z56_CODETI = Z07.Z07_ETQPRD "
	cQuery+= "                   AND Z56.Z56_CODPRO = Z07.Z07_PRODUT "
	cQuery+= " 				  AND Z56.Z56_OK_ENT = 'S' "
	cQuery+= " 				  AND Z56.Z56_OK_SAI = 'N' "
	cQuery+= " 				  AND Z56.D_E_L_E_T_ != '*' "
	cQuery+= " 		INNER JOIN "+RetSqlName("Z55")+" Z55 "
	cQuery+= " 		ON "
	cQuery+= " 		Z55_FILIAL = Z56_FILIAL "
	cQuery+= " 		AND Z55_REMESS = Z56_REMESS " 
	cQuery+= "      AND Z55_CODCLI = '"+cCodCli+"' "
	cQuery+= "      AND Z55_LOJCLI = '"+cLojaCli+"' "
	cQuery+= "      AND Z55_PEDCLI <> '"+Space(TamSX3("Z55_PEDCLI")[01])+"' "
	cQuery+= " 		AND Z55.D_E_L_E_T_ != '*' "
	cQuery+= " WHERE  Z07_FILIAL = '"+xFilial("Z07")+"' "
	cQuery+= "        AND Z07_NUMOS = '"+cNumOS+"' "
	cQuery += "       AND Z07_SEQOS = '"+cSeqOS+"' "
	cQuery+= "        AND Z07.D_E_L_E_T_ = '' "
	cQuery+= " GROUP  BY Z07_FILIAL, Z55_PEDCLI, Z05_NUMOS,Z56_TIPO
	cQuery+= " ORDER BY Z07_FILIAL, Z55_PEDCLI, Z05_NUMOS "
	If Select("TRBOS") <> 0
		DBSelectArea("TRBOS")
		DBCloseArea()
	EndIf 
	TCQuery cQuery New Alias "TRBOS"
	cMsg1+= " cQuery=["+cQuery+"]"+chr(13)+chr(10)

	nLinha := 1
	Do While !TRBOS->(Eof())

		If nLinha == 1
			cIFSeq   := soma1(GetMV("TC_IFSEQSU"))
			cBatch   := soma1(GetMV("TC_BATCHSU"))

			//Grava a sequencia BatchNumber.
			PUTMV("TC_BATCHSU", cBatch)

			//Grava a sequencia de numeração.
			PUTMV("TC_IFSEQSU", cIFSeq)	
			SX6->(dbCommitAll())
		EndIf


		cLinha:= cIFSeq+TAB//IF_SEQ [1]
		cLinha+= cValToChar(nLinha)+TAB//BRANCH_NO [2]
		cLinha+= "03"+TAB//EX_ACTION_CLASS [3]
		cLinha+= cExActCl+TAB//SEND_FROM [4]
		cLinha+= cDest+TAB //SEND_DESTINATION [5]
		cLinha+= AllTrim(TRBOS->Z55_PEDCLI)+TAB//SHIPPING_INS_NO [6]
		cLinha+= TAB//ORG_SHIPPING_INS_NO [7]
		cLinha+= TAB//ACTION_CLASS [8]
		cLinha+= TAB//FACTORY_PART_NO6 [9]
		cLinha+= TAB//STOCK_KEY [10]
		cLinha+= IIf(Empty( AllTrim(TRBOS->Z56_TIPO)),"0",AllTrim(TRBOS->Z56_TIPO))+TAB//CONICITY [11]
		cLinha+= TAB//CONSIGNEE_CD [12]
		cLinha+= TAB//CONSIGNEE_Name [13]
		cLinha+= TAB//SHIPPING_PLAN_DATE [14]
		cLinha+= cValToChar(TRBOS->QUANTIDADE)+TAB//SHIPPING_INS_CNT [15]
		cLinha+= "0"+TAB//SITE [16]
		cLinha+= cExActCl+TAB//STOREHOUSE_CD [17]
		cLinha+= TAB//MARKET [18]
		cLinha+= TAB//PRODUCT_PROTO_CLASS [19]
		cLinha+= TAB//STUFFING_CLASS [20]
		cLinha+= TAB//KENPINKBN [21]
		cLinha+= ""//KENPINBARCD [22]
		cLinha+= CHR(13)+CHR(10)
		aAdd(aDados,cLinha)
		nLinha++

		TRBOS->(DBSkip())
	EndDo
	If Select("TRBOS") <> 0
		DBSelectArea("TRBOS")
		DBCloseArea()
	EndIf 
	cMsg1+= " Quantidade de Registros Localizados=["+cValToChar(Len(aDados))+"]"+chr(13)+chr(10)

	//Grava dados no arquivo.
	If Len(aDados)>0

		//Gera a nomenclatura do arquivo.
		cArquivo:= "\sumitomo\exportacao\"+cBatch+"_"+cExActCl+"_03_"+cIFSeq+".csv"

		nHdl  := fCreate(cArquivo)
		If nHdl == -1
			cMsg:= "ERRO - SEPARACAO ENTRADA - Action Class 03 - Arquivo não pôde ser Criado. Arquivo: "+cArquivo+" - TWMSA048 - (fSepEnt)"
			U_FtGeraLog(cFilAnt, "", "", cMsg, "002", "", "000000")	
			Return
		Endif
		For nFor:= 1 To Len(aDados)
			fWrite(nHdl,aDados[nFor])
		Next	
		FClose(nHdl)

		cMsg:= "SUCESSO - SEPARACAO ENTRADA - Arquivo gerado: "+cArquivo+" - TWMSA048 - (fSepEnt)"
		U_FtGeraLog(cFilAnt, "Z07", xFilial("Z07")+cNumOS+cSeqOS, cMsg, "002", "", "000000")

	Else
		cMsg:= "ERRO - SEPARACAO ENTRADA - Action Class 03 - Não trouxe dados OS: "+(xFilial("Z07")+cNumOS+cSeqOS)+" - TWMSA048 - (fSepEnt)"//+cQuery
		U_FtGeraLog(cFilAnt, "Z07", xFilial("Z07")+cNumOS+cSeqOS, cMsg, "002", "", "000000")	
	EndIf		
	cMsg1+= cMsg+chr(13)+chr(10)

	cMsg1+= " Arquivo=["+cArquivo+"]"+chr(13)+chr(10)
	cMsg1+= "[FIM]"
	If !ExistDir( "\loggen\" )
		MakeDir( "\loggen\" )
	EndIf
	memoWrit("\loggen\TWMSA048_fSepEnt_"+FWTimeStamp(1,Date(),Time())+".txt",cMsg1)


Return

/*/{Protheus.doc} fSepSai
Função auxiliar para exportar separações de saída.
O princípio do arquivo é enviar os produtos separados, conforme o pedido de vendas.
Portanto o campo SHIPPING_INS_NO, será o pedido do cliente, contido na SC5.
@type function
@author Luiz Fernando Berti
@since 23/05/2019
/*/
Static Function fSepSai(cNumOS,cSeqOS,cCodCli,cLojaCli)

	LOCAL nHdl   
	LOCAL cArquivo := ""
	LOCAL cLinha   := ""
	LOCAL nLinha   := 0 
	LOCAL cQuery   := ""
	LOCAL cCliTI   := GetNewPar("TC_SRBTI","00031601")//Cliente SRB Sta Catarina
	LOCAL cCliTP   := GetNewPar("TC_SRBTP","00031602")//Cliente SRB Parana cliente 000316  loja 02
	LOCAL cIFSeq   := ""//soma1(GetMV("TC_IFSEQSU"))
	LOCAL cBatch   := ""//soma1(GetMV("TC_BATCHSU"))
	LOCAL cExActCl := ""//Iif(cFilAnt=="103","TI","TP")
	LOCAL cDest    := ""
	LOCAL cActClass:= ""//"31"
	LOCAL aDados   := {}
	LOCAL cContai  := ""
	LOCAL cMsg1    := ""
	cMsg1+= chr(13)+chr(10)
	cMsg1+= "fSepSai"	
	cMsg1+= chr(13)+chr(10)
	cMsg1+= (" Usuario=["+cUsername+"] Computador=["+GetComputerName()+"]")
	cMsg1+= (" IP=["+Getclientip()+"]")
	cMsg1+= (" Thread=["+cValToChar(ThreadId())+"]")
	cMsg1+= chr(13)+chr(10)

	DBselectArea("Z05")
	DBSelectArea("SZ3")
	DBSelectArea("SZZ")
	DBSelectArea("Z06")
	SZ3->(DBSetOrder(03))//Z3_FILIAL+Z3_CONTAIN
	Z06->(DBSetOrder(01))//Z06_FILIAL+Z06_NUMOS+Z06_SEQOS
	SZZ->(DBSetOrder(01))//ZZ_FILIAL+ZZ_CESV
	Z05->(DBSetOrder(01))//Z05_FILIAL+Z05_NUMOS                                                                                                                                            

	If !ExistDir( "\sumitomo\exportacao\" )
		MakeDir( "\sumitomo\exportacao\" )
	EndIf

	Do Case 
		Case cFilAnt == "103" 
		cExActCl := "TIT"
		cDest    := "FRG" 
		Case cFilAnt == "105" 
		cExActCl := "TCU"
		cDest    := "FRG"
		Case cFilAnt == "106" 
		cExActCl := "TSJ"
		cDest    := "FRG"		
	EndCase

	cMsg:= "INICIO EXPORTAÇÃO SUMITOMO Separação de Saída GERANDO ARQUIVO "+FWTimeStamp(1,Date(),Time())
	U_FtGeraLog(cFilAnt, "", "", cMsg, "002", "", "000000")	

	//Busca separacoes de saida.
	cQuery:= "SELECT Z07_FILIAL, C5_ZPEDCLI, Z05_NUMOS, Z05_CESV, Z56_STORE, Z56_TICKET,Z56_CODPRO, Z56_FAC4,Z56_ETQCLI, C5_ZORIGEM, Z56_TIPO "
	cQuery+= " FROM   "+RetSQLName("Z07")+" Z07 "
	cQuery+= " 		INNER JOIN "+RetSQlName("Z05")+" Z05 "
	cQuery+= " 		ON Z05_FILIAL = Z07_FILIAL "
	cQuery+= " 		AND Z05_NUMOS = Z07_NUMOS "
	cQuery+= " 		AND Z05_TPOPER = 'S' "// -- Somente OS de saida.
	//cQuery+= " 		AND Z05_EXP03 <> '1' "
	cQuery+= " 		AND Z05.D_E_L_E_T_ != '*' "
	cQuery+= "		INNER JOIN "+RetSQLName("SB1")+" SB1 "
	cQuery+= " 		ON SB1.B1_FILIAL = '"+xFilial("SB1")+"' "
	cQuery+= " 		AND B1_COD = Z07.Z07_PRODUT  " 
	cQuery+= " 		AND SB1.D_E_L_E_T_ != '*' "
	cQuery+= "        INNER JOIN "+RetSqlName("Z56")+" Z56 "
	cQuery+= "                ON Z56.Z56_FILIAL = Z07.Z07_FILIAL "
	cQuery+= "                   AND Z56.Z56_CODETI = Z07.Z07_ETQPRD "
	cQuery+= "                   AND Z56.Z56_CODPRO = Z07.Z07_PRODUT "
	cQuery+= " 				     AND Z56.Z56_CODCLI = '"+cCodCli+"' "
	cQuery+= "                   AND Z56.Z56_LOJCLI = '"+cLojaCli+"' "	
	cQuery+= " 				     AND Z56.D_E_L_E_T_ != '*' "
	cQuery+= "      INNER JOIN "+RetSQLName("SC5")+" SC5 "
	cQuery+= "      ON "
	cQuery+= "      C5_FILIAL = Z07_FILIAL "
	cQuery+= "      AND C5_NUM = Z07_PEDIDO "
	cQuery+= "      AND SC5.D_E_L_E_T_ != '*' "
	cQuery+= " WHERE  Z07_FILIAL = '"+xFilial("Z07")+"' "
	cQuery+= "        AND Z07_NUMOS = '"+cNumOS+"' "
	cQuery+= "       AND Z07_SEQOS = '"+cSeqOS+"' "
	cQuery+= "        AND Z07.D_E_L_E_T_ = '' "
	cQuery+= " ORDER BY Z07_FILIAL, C5_ZPEDCLI, Z05_NUMOS "
	If Select("TRBOS") <> 0
		DBSelectArea("TRBOS")
		DBCloseArea()
	EndIf 
	TCQuery cQuery New Alias "TRBOS"

	cMsg1+= " cQuery=["+cQuery+"]"+chr(13)+chr(10)

	nLinha := 1
	Do While !TRBOS->(Eof())
		//Trata numeração somente se houver dados, evita utilizar a mesma numeração em arquivos diferentes.
		If nLinha == 1
			cIFSeq:= soma1(GetMV("TC_IFSEQSU"))
			cBatch:= soma1(GetMV("TC_BATCHSU"))	
			//Grava a sequencia BatchNumber.
			PUTMV("TC_BATCHSU", cBatch)

			//Grava a sequencia de numeração.
			PUTMV("TC_IFSEQSU", cIFSeq)
			SX6->(dbCommitAll())
		EndIf


		//Identifica se o pedido foi incluído pela integração (C5_ZORIGEM 02), envia action class 21 ao contrario envia 31.
		If Empty(cActClass)
			cActClass := IIf(TRBOS->C5_ZORIGEM == "02","31","21")
		EndIf
		cLinha:= cIFSeq+TAB//IF_SEQ [1]
		cLinha+= cValToChar(nLinha)+TAB//BRANCH_NO [2]
		cLinha+= cActClass+TAB//EX_ACTION_CLASS [3] //C5_ZORIGEM - Diferencia 02 Envia 31 e Branco ou 01 envia 21.
		cLinha+= cExActCl+TAB//SEND_FROM [4]
		cLinha+= cDest+TAB //SEND_DESTINATION [5]

		cLinha+= AllTrim(TRBOS->Z56_ETQCLI)+TAB//TIRE_BC [6]
		cLinha+= Iif(Empty(AllTrim(TRBOS->Z56_STORE)),"0",AllTrim(TRBOS->Z56_STORE))+TAB//STORE_YEAR_WEEK [7]
		cLinha+= cExActCl+TAB//STOREHOUSE_CD [8]
		cLinha+= Iif(Empty(AllTrim(TRBOS->Z56_TICKET)),"0",AllTrim(TRBOS->Z56_TICKET))+TAB//TICKET_NO [9]
		cLinha+= AllTrim(TRBOS->C5_ZPEDCLI)+TAB//SHIPPING_INS_NO [10]
		cLinha+= "1"+TAB//MARKET [11]
		cLinha+= "27"+TAB//STATUS [12]
		cLinha+= Iif(Empty(AllTrim(TRBOS->Z56_FAC4)),"0",AllTrim(TRBOS->Z56_FAC4))+TAB//FACTORY_PART_NO4 [13]
		cLinha+= StrTran(AllTrim(TRBOS->Z56_CODPRO),"SUMI","")+TAB//FACTORY_PART_NO6 [14]
		cLinha+= iif(Empty(AllTrim(TRBOS->Z56_TIPO)),"0",AllTrim(TRBOS->Z56_TIPO))+TAB//CONICITY [15]
		cLinha+= "0"+TAB//PRODUCT_PROTO_CLASS [16]
		cLinha+= "1"+TAB//CNT [17]
		cLinha+= TAB//PRODUCT_YEAR_WEEK [18]
		cLinha+= "*"+TAB//LOT_NO [19]
		cLinha+= "10"+TAB//BEFORE_STATUS [20] 
		cLinha+= TAB//LINE [21]
		cLinha+= "1"+TAB//TIRE_BC_FLG [22]
		cLinha+= "0"+TAB//WRAPPING_FLG [23]
		cLinha+= "0"+TAB//BUFF_FLG [24]

		//Pega o numero do container ou placa do caminhão
		cContai:= "AAA9999"
		cLacre := ""
		If SZZ->(MSSeek(xFilial("SZZ") + TRBOS->Z05_CESV))
			If Empty(SZZ->ZZ_CNTR01)
				cContai:= AllTrim(SZZ->ZZ_PLACA1)
			Else
				cContai:= AllTrim(SZZ->ZZ_CNTR01)
			EndIf

			//Busca pelo codigo do lacre (SEAL_NO1)
			cLacre := AllTrim(SZZ->ZZ_LACRE)	    
		EndIf
		cLinha+= IIf(Empty(cLacre),"undefined",cLacre)+TAB//SEAL_NO1 [25] 
		cLinha+= TAB//SEAL_NO2 [26]
		cLinha+= TAB//SEAL_NO3 [27]
		cLinha+= TAB//SEAL_NO4 [28]
		cLinha+= TAB//SEAL_NO5 [29]
		cLinha+= Iif(Empty(cContai),"",cContai)+TAB//CONTAINNER_NO //SZZ - ZZ_CNTR01 [30]

		cLoaDt := "1900/01/01 0:00:00"
		If Z06->(MSSeek(TRBOS->(Z07_FILIAL+Z05_NUMOS)+"002")) .And. !Empty(DTOS(Z06->Z06_DTFIM))
			cLoaDt:= DTOS(Z06->Z06_DTFIM)
			cLoaDt:= Subs(cLoaDt,1,4)+"/"+Subs(cLoaDt,5,2)+"/"+Subs(cLoaDt,7,2)
			cLoaDt+= Space(01)
			cLoaDt+= Z06->Z06_HRFIM+":00"
		EndIf
		cLinha+= cLoaDt//LOADING_FINISH_DATE [31] - 2018/12/25  0:00:00 Z06 Z06_SEQ == 000003(Z06_DTFIM+Z06_HRFIM) Z06_FILIAL+Z06_NUMOS+Z06_SEQOS

		cLinha+= CHR(13)+CHR(10)
		aAdd(aDados,cLinha)
		nLinha++

		TRBOS->(DBSkip())
	EndDo
	If Select("TRBOS") <> 0
		DBSelectArea("TRBOS")
		DBCloseArea()
	EndIf 

	cMsg1+= " Quantidade de Registros Localizados=["+cValToChar(Len(aDados))+"]"+chr(13)+chr(10)

	//Grava dados no arquivo.
	If Len(aDados)>0

		//Gera a nomenclatura do arquivo.
		cArquivo:= "\sumitomo\exportacao\"+cBatch+"_"+cExActCl+"_"+cActClass+"_"+cIFSeq+".csv"

		nHdl  := fCreate(cArquivo)
		If nHdl == -1
			cMsg:= "ERRO - SEPARACAO SAIDA - Action Class "+cActClass+" - Arquivo não pôde ser Criado "+cArquivo+" - TWMSA048 - (fSepSai)"
			U_FtGeraLog(cFilAnt, "Z07", xFilial("Z07")+cNumOS+cSeqOS, cMsg, "002", "", "000000")	
			Return
		Endif
		For nFor:= 1 To Len(aDados)
			fWrite(nHdl,aDados[nFor])
		Next	
		FClose(nHdl)

		cMsg:= "SUCESSO - SEPARACAO SAIDA - Arquivo gerado: "+cArquivo+" - TWMSA048 - (fSepSai)"
		U_FtGeraLog(cFilAnt, "Z07", xFilial("Z07")+cNumOS+cSeqOS, cMsg, "002", "", "000000")

	Else
		cMsg:= "ERRO - SEPARACAO SAIDA - Action Class "+cActClass+" - Não trouxe dados DADOS OS:"+(xFilial("Z07")+cNumOS+cSeqOS)+" - TWMSA048 - (fSepSai)"
		U_FtGeraLog(cFilAnt, "Z07", xFilial("Z07")+cNumOS+cSeqOS, cMsg, "002", "", "000000")	
	EndIf		
	cMsg1+= cMsg+chr(13)+chr(10)

	cMsg1+= " Arquivo=["+cArquivo+"]"+chr(13)+chr(10)
	cMsg1+= "[FIM]"
	If !ExistDir( "\loggen\" )
		MakeDir( "\loggen\" )
	EndIf
	memoWrit("\loggen\TWMSA048_fSepSai_"+FWTimeStamp(1,Date(),Time())+".txt",cMsg1)

Return

/*/{Protheus.doc} TWMA048M
Tela para testes de geração de arquivo.
@type function
@author Luiz Fernando
@since 24/07/2019
@version 1.0
@return ${return}, ${nil}
/*/
User Function TWMA048M()

	LOCAL aItems   := {"E-Entrada","S-Saída"}
	LOCAL cCombo   := aItems[1]
	LOCAL cNumOs   := Space(TamSX3("Z05_NUMOS")[01])
	LOCAL cSeqOS   := Space(TamSX3("Z07_SEQOS")[01])
	LOCAL cCliente := Space(TamSX3("A1_COD")[01])
	LOCAL cLoja    := Space(TamSX3("A1_LOJA")[01])
	LOCAL nOpc     := 0
	LOCAL oFont    := TFont():New("Arial",,-12,.T.)
	LOCAL nColSay  := 01
	LOCAL nColGet  := 40
	LOCAL nColSay2 := 120
	LOCAL nColGet2 := 160
	LOCAL nLinha   := 010

	oDlg := MSDialog():New(000,000,505,705, "Emissão de Remessa",,,,,,,,,.T.)
	oDlg:lEscClose := .T.
	oSay    := TSay():New(nLinha,nColSay,{||"Tipo: "},oDlg,,oFont,,,,.T.,,CLR_WHITE,100,90)
	oCombo1 := TComboBox():New(nLinha,nColGet,{|u| if(PCount()>0,cCombo:=u,cCombo)},aItems,70,20,oDlg,,{||},,,,.T.,,,,,,,,,'cCombo')

	nLinha+=15
	oSay    := TSay():New(nLinha,nColSay,{||"OS: "},oDlg,,oFont,,,,.T.,CLR_BLUE,CLR_WHITE,100,90)
	oGetOS  := TGet():New(nLinha,nColGet,{|u| if(PCount()>0,cNumOs:=u,cNumOs) }, oDlg,60,9,'@!',{ ||  },,,,,,.T.,,, {|| .T. } ,,,,(.F.),,"SC2","cNumOs")
	oSay    := TSay():New(nLinha,nColSay2,{||"Seq. OS: "},oDlg,,oFont,,,,.T.,CLR_BLUE,CLR_WHITE,100,90)
	oGetOSq  := TGet():New(nLinha,nColGet2,{|u| if(PCount()>0,cSeqOS:=u,cSeqOS) }, oDlg,60,9,'@!',{ ||  },,,,,,.T.,,, {|| .T. } ,,,,(.F.),,"","cSeqOS")
	nLinha+=15
	oSay    := TSay():New(nLinha,nColSay,{||"Cliente: "},oDlg,,oFont,,,,.T.,CLR_BLUE,CLR_WHITE,100,90)
	oGetCl  := TGet():New(nLinha,nColGet,{|u| if(PCount()>0,cCliente:=u,cCliente) }, oDlg,60,9,'@!',{ ||  },,,,,,.T.,,, {|| .T. } ,,,,(.F.),,"SA1","cCliente")
	oSay    := TSay():New(nLinha,nColSay2,{||"Loja: "},oDlg,,oFont,,,,.T.,CLR_BLUE,CLR_WHITE,100,90)
	oGetLj  := TGet():New(nLinha,nColGet2,{|u| if(PCount()>0,cLoja:=u,cLoja) }, oDlg,60,9,'@!',{ ||  },,,,,,.T.,,, {|| .T. } ,,,,(.F.),,"","cLoja")
	nLinha+=15
	oBtok     := TButton():New(nLinha, nColSay, "OK",oDlg,{||nOpc:=1, oDlg:End()},30,10,,,.F.,.T.,.F.,,.F.,,,.F.)
	oBtSair   := TButton():New(nLinha, nColSay+50, "Sair",oDlg,{||nOpc:=0, oDlg:End()},30,10,,,.F.,.T.,.F.,,.F.,,,.F.)

	oDlg:lCentered := .T.
	oDlg:Activate()

	If !Empty(nOpc)
		ExecBlock("TWMSA048",.F.,.F.,{Subs(cCombo,1,1),cNumOs,cSeqOS,cCliente,cLoja})	
	EndIf

Return