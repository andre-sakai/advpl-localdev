//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"

//Constantes
#Define STR_PULA		Chr(13)+Chr(10)

/*/{Protheus.doc} BFFATR16
Relatório - Faturamento Mensal            
@author zReport
@since 10/01/2018
@version 1.0
@example
u_BFFATR16()
@obs Função gerada pelo zReport()
/*/

User Function BFFATR16()
	Local aArea   := GetArea()
	Local oReport
	Local lEmail  := .F.
	Local cPara   := ""
	Private cPerg := "" 
	
	Private cAlias := GetNextAlias()

	//Definições da pergunta
	DbSelectArea("SX1")
	cPerg := Padr("BFFATR16  ",Len(SX1->X1_GRUPO))
	
	sfValPerg()
	
	//Se a pergunta não existir, zera a variável
	DbSelectArea("SX1")
	SX1->(DbSetOrder(1)) //X1_GRUPO + X1_ORDEM
	If ! SX1->(DbSeek(cPerg))
		cPerg := Nil
	EndIf

	//Cria as definições do relatório
	oReport := fReportDef()


	oReport:PrintDialog()
	

	RestArea(aArea)
Return

/*-------------------------------------------------------------------------------*
| Func:  fReportDef                                                             |
| Desc:  Função que monta a definição do relatório                              |
*-------------------------------------------------------------------------------*/

Static Function fReportDef()
	Local oReport
	Local oSectDad := Nil
	Local oBreak := Nil     
	
	Private QRY_AUX := GetNextAlias()

	//Criação do componente de impressão
	oReport := TReport():New(	"BFFATR16",;		//Nome do Relatório
	"Faturamento Mensal",;		//Título
	cPerg,;		//Pergunte ... Se eu defino a pergunta aqui, será impresso uma página com os parâmetros, conforme privilégio 101
	{|oReport| fRepPrint(oReport)},;		//Bloco de código que será executado na confirmação da impressão
	)		//Descrição
	oReport:SetTotalInLine(.F.)
	oReport:lParamPage := .F.
	oReport:oPage:SetPaperSize(9) //Folha A4
	oReport:SetPortrait()

	//Criando a seção de dados
	oSectDad := TRSection():New(	oReport,;		//Objeto TReport que a seção pertence
	"Dados",;		//Descrição da seção
	{"QRY_AUX"})		//Tabelas utilizadas, a primeira será considerada como principal da seção
	oSectDad:SetTotalInLine(.T.)  //Define se os totalizadores serão impressos em linha ou coluna. .F.=Coluna; .T.=Linha

	//Colunas do relatório
	TRCell():New(oSectDad, "VENDEDOR", "QRY_AUX", "Vendedor", /*Picture*/, 70, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CLIENTE", "QRY_AUX", "Cliente", /*Picture*/, 10, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "A1_NOME", "QRY_AUX", "Nome Cliente", /*Picture*/, 70, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "A1_EST", "QRY_AUX", "Estado", /*Picture*/, 70, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "A1_MUN", "QRY_AUX", "Municipio", /*Picture*/, 70, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "NOTA", "QRY_AUX", "Nota", /*Picture*/, 9, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "TABELA", "QRY_AUX", "TABELA", /*Picture*/, 9, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "EMISSAO", "QRY_AUX", "EMISSAO", /*Picture*/, 9, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "VALMERC", "QRY_AUX", "VALMERC", /*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	

	
	//oBreakVend  := TRBreak():New(oSectDad, {|| (QRY_AUX)->VENDEDOR } , {|| "SUBTOTAL --> " })
	
	
Return oReport

/*-------------------------------------------------------------------------------*
| Func:  fRepPrint                                                              |
| Desc:  Função que imprime o relatório                                         |
*-------------------------------------------------------------------------------*/

Static Function fRepPrint(oReport)
	Local aArea    := GetArea()
	Local cQryAux  := ""
	Local oSectDad := Nil
	Local nAtual   := 0
	Local nTotal   := 0

	//Pegando as seções do relatório
	oSectDad := oReport:Section(1)

	//Montando consulta de dados   
	

	
	cQryAux := ""
	cQryAux := " SELECT  " 
	cQryAux += " SF2.F2_DOC  NOTA, "  
	cQryAux += " SF2.F2_SERIE, "
	cQryAux += " SA3.A3_NOME VENDEDOR, "
	cQryAux += " SF2.F2_CLIENTE CLIENTE, " 
	cQryAux += " SF2.F2_LOJA LOJA, "
	cQryAux += " SA1.A1_NOME, "
	cQryAux += " SA1.A1_EST, "
	cQryAux += " SA1.A1_MUN, "
	cQryAux += " SC5.C5_VEND1 ,  "
	cQryAux += " SC5.C5_NUM, "	
	cQryAux += " SC5.C5_TABELA TABELA, "
	cQryAux += " SF2.F2_EMISSAO EMISSAO, "	
	cQryAux += " ( SF2.F2_VALMERC  - SF2.F2_VALICM  ) VALMERC "
	cQryAux += " FROM " + RetSqlName("SF2") + " SF2 "
	cQryAux += " 	INNER JOIN " + RetSqlName("SC5") + " SC5 ON SC5.C5_FILIAL = SF2.F2_FILIAL AND "
	cQryAux += " 		SC5.C5_NOTA = SF2.F2_DOC  "	
	cQryAux += " 	INNER JOIN " + RetSqlName("SA3") + " SA3 ON  "
	cQryAux += " 		SA3.A3_COD = SC5.C5_VEND1  " 
	cQryAux += " 	INNER JOIN " + RetSqlName("SA1") + " SA1 ON  "
	cQryAux += " 		SA1.A1_COD = SF2.F2_CLIENTE  "  
	cQryAux += " WHERE SF2.D_E_L_E_T_ = ' ' AND SC5.D_E_L_E_T_ = ' '    AND    SA3.D_E_L_E_T_ = ' ' AND    SA1.D_E_L_E_T_ = ' ' AND  "	
	cQryAux += " SF2.F2_TIPO = 'N' AND SF2.F2_DUPL <> ' ' AND  SC5.C5_VEND1 BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' AND "	
	cQryAux += " SF2.F2_EMISSAO  BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "'  "	
	cQryAux += " ORDER BY SC5.C5_FILIAL, SA3.A3_NOME, SF2.F2_EMISSAO, SF2.F2_CLIENTE "  
	cQryAux := ChangeQuery(cQryAux)

	//Executando consulta e setando o total da régua
	TCQuery cQryAux New Alias "QRY_AUX"
	Count to nTotal
	oReport:SetMeter(nTotal)

	//Enquanto houver dados
	oSectDad:Init()
	QRY_AUX->(DbGoTop())
	While ! QRY_AUX->(Eof())
		//Incrementando a régua
		nAtual++
		oReport:SetMsgPrint("Imprimindo registro "+cValToChar(nAtual)+" de "+cValToChar(nTotal)+"...")
		oReport:IncMeter()

		//Imprimindo a linha atual
		oSectDad:PrintLine()

		QRY_AUX->(DbSkip())
	EndDo
	oSectDad:Finish()
	QRY_AUX->(DbCloseArea())

	RestArea(aArea)
Return


// Exemplo de uso

Static Function sfValPerg()

	Local	aSx1Cab		:= {"X1_GRUPO",;	//1
							"X1_ORDEM",;	//2
							"X1_PERGUNT",;	//3	
							"X1_VARIAVL",;	//4
							"X1_TIPO",;		//5
							"X1_TAMANHO",;	//6
							"X1_DECIMAL",;	//7
							"X1_PRESEL",;	//8
							"X1_GSC",;		//9
							"X1_VAR01",;	//10	
							"X1_F3"}		//11
							
	Local	aSX1Resp	:= {}
	
							
	Aadd(aSX1Resp,{	cPerg,;					//1
					'01',;					//2
					'Data de?',;			//3
					'mv_ch1',;				//4
					'D',;					//5
					8,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par01',;			//10
					''})					//11
	
	Aadd(aSX1Resp,{	cPerg,;					//1
					'02',;					//2
					'Data Ate?'	,;			//3
					'mv_ch2',;				//4
					'D',;					//5
					8,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par02',;			//10
					''})					//11
					
	Aadd(aSX1Resp,{	cPerg,;					//1
					'03',;					//2
					'Vendedor De?',;		//3
					'mv_ch3',;				//4
					'C',;					//5
					6,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par03',;			//10
					'SA3'})					//11
	
	Aadd(aSX1Resp,{	cPerg,;					//1
					'04',;					//2
					'Vendedor Até?',;		//3
					'mv_ch4',;				//4
					'C',;					//5
					6,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par04',;			//10
					'SA3'})					//11					
	// Grava Perguntas				
    U_XPUTSX1(aSx1Cab,aSX1Resp,.F./*lForceAtuSx1*/)
    
	
Return



User Function XPUTSX1(aInX1Cabec,aInX1Perg,lForceAtuSx1)
	// aInX1Cabec virá com os campos que serão populados
	// {"X1_GRUPO","X1_ORDEM","X1_PERGUNT","X1_VARIAVL","X1_TIPO""X1_TAMANHO","X1_DECIMAL","X1_PRESEL"}
	// aInX1Perg  deverá ter as respostas dos campos   
	Local 	aHelpPor 		:= {}
	Local	aCabSX1			:= {}
	Local	nA,nB
	Local	lInclui			:= .F. 
	Local	nPosGrp			:= 0
	Local	nPosOrd			:= 0
	Local	nPosAux			:= 0
	Default	lForceAtuSx1	:= .F. 
	
	Aadd(aCabSX1,{"X1_GRUPO"	,"C"	,""})
	Aadd(aCabSX1,{"X1_ORDEM"	,"C"	,""})
	Aadd(aCabSX1,{"X1_PERGUNT"	,"C"	,""})
	Aadd(aCabSX1,{"X1_PERSPA"	,"C"	,"SX1->X1_PERGUNT"	})
	Aadd(aCabSX1,{"X1_PERENG"	,"C"	,"SX1->X1_PERGUNT"})
	Aadd(aCabSX1,{"X1_VARIAVL"	,"C"	,""})
	Aadd(aCabSX1,{"X1_TIPO"		,"C"	,""})
	Aadd(aCabSX1,{"X1_TAMANHO"	,"N"	,0})
	Aadd(aCabSX1,{"X1_DECIMAL"	,"N"	,0})
	Aadd(aCabSX1,{"X1_PRESEL"	,"N"	,0})
	Aadd(aCabSX1,{"X1_GSC"		,"C"	,""})	//G=1-Edit S=2-Text C=3-Combo R=4-Range F=5-File ( X1_DEF01=56 ) E=6-Expression K=7-Check
	Aadd(aCabSX1,{"X1_VALID"	,"C"	,""})
	Aadd(aCabSX1,{"X1_VAR01"	,"C"	,""})
	Aadd(aCabSX1,{"X1_DEF01"	,"C"	,""})
	Aadd(aCabSX1,{"X1_DEFSPA1"	,"C"	,"SX1->X1_DEF01"})
	Aadd(aCabSX1,{"X1_DEFENG1"	,"C"	,"SX1->X1_DEF01"})
	Aadd(aCabSX1,{"X1_CNT01"	,"C"	,""})
	Aadd(aCabSX1,{"X1_VAR02"	,"C"	,""})
	Aadd(aCabSX1,{"X1_DEF02"	,"C"	,""})
	Aadd(aCabSX1,{"X1_DEFSPA2"	,"C"	,"SX1->X1_DEF02"})
	Aadd(aCabSX1,{"X1_DEFENG2"	,"C"	,"SX1->X1_DEF02"})
	Aadd(aCabSX1,{"X1_CNT02"	,"C"	,""})
	Aadd(aCabSX1,{"X1_VAR03"	,"C"	,""})
	Aadd(aCabSX1,{"X1_DEF03"	,"C"	,""})
	Aadd(aCabSX1,{"X1_DEFSPA3"	,"C"	,"SX1->X1_DEF03"})
	Aadd(aCabSX1,{"X1_DEFENG3"	,"C"	,"SX1->X1_DEF03"})
	Aadd(aCabSX1,{"X1_CNT03"	,"C"	,""})
	Aadd(aCabSX1,{"X1_VAR04"	,"C"	,""})
	Aadd(aCabSX1,{"X1_DEF04"	,"C"	,"SX1->X1_DEF04"})
	Aadd(aCabSX1,{"X1_DEFSPA4"	,"C"	,"SX1->X1_DEF04"})
	Aadd(aCabSX1,{"X1_DEFENG4"	,"C"	,""})
	Aadd(aCabSX1,{"X1_CNT04"	,"C"	,""})
	Aadd(aCabSX1,{"X1_VAR05"	,"C"	,""})
	Aadd(aCabSX1,{"X1_DEF05"	,"C"	,""})
	Aadd(aCabSX1,{"X1_DEFSPA5"	,"C"	,"SX1->X1_DEF05"})
	Aadd(aCabSX1,{"X1_DEFENG5"	,"C"	,"SX1->X1_DEF05"})
	Aadd(aCabSX1,{"X1_CNT05"	,"C"	,""})
	Aadd(aCabSX1,{"X1_F3"		,"C"	,""})
	Aadd(aCabSX1,{"X1_PYME"		,"C"	,""})
	Aadd(aCabSX1,{"X1_GRPSXG"	,"C"	,""})
	Aadd(aCabSX1,{"X1_HELP"		,"C"	,""})
	Aadd(aCabSX1,{"X1_PICTURE"	,"C"	,""})
	Aadd(aCabSX1,{"X1_IDFIL"	,"C"	,""})	
	
	DbSelectArea('SX1')
	SX1->(DbSetOrder(1))
	For nA:=1 to Len(aInX1Perg)
		nPosGrp		:= aScan(aInX1Cabec,{|x| x== "X1_GRUPO"}) 
		nPosOrd		:= aScan(aInX1Cabec,{|x| x== "X1_ORDEM"}) 
		
		lInclui:= !SX1->(DbSeek(Padr(aInX1Perg[nA,nPosGrp],Len(SX1->X1_GRUPO))+aInX1Perg[nA,nPosOrd]))
		// Se não for Inclusão e não deva atualizar a SX1
		If !lInclui .And. !lForceAtuSx1
			// Não faz nada
		// Efetua gravação	
		ElseIf	RecLock('SX1',lInclui)
			// Efetua Loop pelas colunas 
			For nB := 1 To Len(aInX1Cabec)
				&("SX1->"+aInX1Cabec[nB]) 	:= aInX1Perg[nA,nB]
			Next nB
			
			// Popula os registros com valor Default
			For nB := 1 To Len(aCabSX1)
				nPosAux		:= aScan(aInX1Cabec,{|x| x== aCabSX1[nB][1]})
				If nPosAux == 0 .And. !Empty(aCabSX1[nB,3])
					&("SX1->"+aCabSX1[nB,1]) 	:= &(aCabSX1[nB,3])
				Endif 
			Next nB 
			SX1->(MsUnLock())
		Endif
	Next nA 
Return 