#Include 'Protheus.ch'
#Include 'rwmake.ch'
#Include 'TopConn.ch'
#Include 'Fileio.ch'

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ PREST001 บAutor  ณ JOAO LOPES        บ Data ณ  18/03/2018  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Relatorio de Analise de Saldos Iniciais   	              บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ MP11- Powers Solutions                                     บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function PREST001()

Private cPerg		:= "PREST001"
Private nomeprog	:= "PREST001"

ValidPerg()
Pergunte(cPerg,.F.)

@ 200,30 TO 500,530 DIALOG oDlg TITLE "Relatorio de analises Saldos Iniciais"
@ 10,010 SAY " Gera as informa็๕es para comparar saldos iniciais com resultado Kardex"
@ 20,010 SAY " - antes da virada de saldos"
@ 30,010 SAY "                                                      "
@ 40,010 SAY "                                                      "
@ 50,010 SAY " Uso Exclusivo Ceramarte.                             "
@ 100,050 BMPBUTTON TYPE 05 ACTION Pergunte(cPerg,.T.)
@ 100,100 BMPBUTTON TYPE 01 ACTION MsgRun("Por Favor Aguarde... Processando...", "Processando",{|| Start()})
@ 100,150 BMPBUTTON TYPE 02 ACTION Close(oDlg)
ACTIVATE DIALOG oDlg CENTERED

Return

//----------------------------------------------------------------------------------------------------------------------
Static Function ValidPerg()

Local i	:= 0
Local j	:= 0

_sAlias := Alias()
dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)
aRegs:={}

AADD(aRegs,{cPerg,"01","Data Fechamento  ?","","","mv_ch1","D",08,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"02","Tipo de          ?","","","mv_ch2","C",02,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"03","Tipo at้         ?","","","mv_ch3","C",02,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"04","Armazem de       ?","","","mv_ch4","C",02,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"05","Armazem at้      ?","","","mv_ch5","C",02,0,0,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

For i:=1 to Len(aRegs)
	If !dbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j <= Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next

dbSelectArea(_sAlias)

Return

//----------------------------------------------------------------------------------------------------------------------
Static Function Start()

Private cLogoCabec := CurDir()+"lg"+cEmpAnt+".bmp"   // Logo
Private nAltLin   	:= 50                            // Altura da linha
Private nTotLin   	:= 65                            // Total de Linhas por pแgina
Private nTotPag   	:= 0                             // Total de linhas
Private nLin      	:= 7                             // Linha corrente
Private nResto    	:= 0                             // Var. usado para calculo de total de paginas
Private nPag     	:= 1                             // Pagina corrente
Private cTab      	:= ""                            // Tabela de trabalho
Private nTotal		:= 0							 // Valor 		Total dos Itens Exibidos
Private nQtd		:= 0	    			    	 // Quantidade  Total dos Itens Exibidos
Private nTotalGr	:= 0		    				 // Valor 		Total dos Itens Exibidos
Private nQtdGr		:= 0							 // Quantidade  Total dos Itens Exibidos

//Variaveis Excel
Private aCabec :={}
Private aDados :={}

Private dDtFech  	:= mv_par01
Private cTpPrdI     := mv_par02
Private cTpPrdF     := mv_par03
Private cLcPrdI     := mv_par04
Private cLcPrdF     := mv_par05
Private cProdB2     := ""
Private	cArmzB2     := ""
Private	nSLDKar     := 0
Private	nVLRKar     := 0 
Private _nCM1       := 0

//Monta Cabe็alho do Excel
AADD(aCabec,	{"FILIAL"   		,"C",	04,0} ) //01
AADD(aCabec,	{"NCM"		     	,"C",	12,0} ) //02
AADD(aCabec, 	{"PRODUTO"      	,"C",	15,0} ) //03
AADD(aCabec,	{"DESCRICAO"		,"C",	50,0} ) //04
AADD(aCabec,	{"TIPO"			    ,"C",	02,0} ) //05
AADD(aCabec,	{"ARMZ"		        ,"C",	02,0} ) //06   
AADD(aCabec,	{"QTD_FIM"			,"N",	20,0} ) //07
AADD(aCabec,	{"VLR_FIM"			,"N",	20,0} ) //08
AADD(aCabec,	{"QTD_KARDEX"	    ,"N",	20,0} ) //09
AADD(aCabec,	{"VLR_KARDEX"    	,"N",	20,0} ) //10
AADD(aCabec,    {"C.MEDIO"          ,"N",   20,0} ) //11
AADD(aCabec,	{"QTD_INI"       	,"N",	20,0} ) //12
AADD(aCabec,	{"VLR_INI"    	    ,"N",	20,0} ) //13

AADD(aDados, { "","","","","","","","","","","","",""} )
// - gambiarra para a ๚ltima coluna, pois o correto nใo estava gravando nada...
AADD(aDados[LEN(aDados)],"")

// Monta dados
Montadados()

IF Len(aDados)<=1
	MsgStop("Dados Nใo Encontrados Nestes Parโmetros.","Dados Nใo Encontrados")
	RETURN
ENDIF

//Exporta para Excel
//Abre o excel
//If ! ApOleClient( 'MsExcel' )
//	MsgStop('MsExcel nao instalado')
//Else

cTitExcel	:= "Relat๓rio para anแlise fechamento Saldos Finais x Kardex - "+DTOC(DATE())+" | "+SUBSTR(TIME(),1,5)
cTitExcel += " - Fechamento "+DTOC(dDtFech)
/*MsgRun("Por Favor Aguarde... Exportando Registros para o Excel...", "Exportando os Registros para o Excel",;
{||	DlgToExcel({ {"GETDADOS", cTitExcel, aCabec, aDados}})})//"ARRAY" ou "GETDADOS"*/

U_TOEXCELA(cTitExcel, aCabec, aDados)
//Endif
//FIM

RETURN

/////////////////////////
Static Function Montadados()

Local _nMeses	:= 0

If Select("QRYPRD") <> 0
	dbSelectArea("QRYPRD")
	dbCloseArea()
Endif

BEGINSQL ALIAS "QRYPRD"
	SELECT B2_FILIAL,
	B1_POSIPI,
	B2_COD,
	B1_DESC,
	B1_TIPO,
	B2_LOCAL,
	B1_LOCPAD AMZPD,
	SUM(B2_QFIM)  QFIM,
	SUM(B2_VFIM1) VFIM,
	SUM(B9_QINI)  QINI,
	SUM(B9_VINI1) VINI
	FROM %table:SB2% SB2
	INNER JOIN %table:SB1% SB1 ON
	SB1.%notdel%
	AND B1_MSBLQL<>'1'
	AND B1_COD = B2_COD
	INNER JOIN %table:SB9% SB9 ON B2_FILIAL = B9_FILIAL
	AND B2_COD = B9_COD
	AND B2_LOCAL = B9_LOCAL
	AND B2_LOCAL = B9_LOCAL
	AND B9_DATA=%exp:DTOS(dDtFech)%
	AND SB9.%notdel% 
	AND (B9_QINI <> 0
	OR B9_VINI1 <> 0)
	WHERE B2_FILIAL=%xfilial:SB2%
	AND SB2.%notdel%
	AND B1_TIPO  BETWEEN %exp:cTpPrdI% AND %exp:cTpPrdF%
	AND B2_LOCAL BETWEEN %exp:cLcPrdI% AND %exp:cLcPrdF%
	//AND B2_LOCAL <> '11'
	//AND B2_LOCAL='06'
	GROUP BY B2_FILIAL,
	B2_COD,
	B1_DESC,
	B1_TIPO,
	B1_POSIPI,
	B2_LOCAL,
	B1_LOCPAD
	ORDER BY B1_POSIPI,
	B2_COD
ENDSQL

dbSelectArea("QRYPRD")
dbGoTop()
WHILE !EOF()
	
	cProdB2 := QRYPRD->B2_COD
	cArmzB2 := QRYPRD->B2_LOCAL
	
	nSLDKar := (CalcEst(cProdB2,cArmzB2,dDtFech+1,NIL)[1])
	nVLRKar := (CalcEst(cProdB2,cArmzB2,dDtFech+1,NIL)[2])
	
	If (nSLDKar<>0 .and. nVLRKar<>0)
		_nCM1 := ROUND(nVLRKar/nSLDKar,4)
	Else
		_nCM1 := 0
	EndIf
	
	AADD(aDados, { "|"+QRYPRD->B2_FILIAL,"|"+QRYPRD->B1_POSIPI,"|"+QRYPRD->B2_COD,QRYPRD->B1_DESC,QRYPRD->B1_TIPO,"|"+QRYPRD->B2_LOCAL,;
	QRYPRD->QFIM,QRYPRD->VFIM,nSLDKar,nVLRKar,_nCM1,QRYPRD->QINI,QRYPRD->VINI})
	
	dbSkip()
ENDDO
If Select("QRYPRD") <> 0
	dbSelectArea("QRYPRD")
	dbCloseArea()
Endif

Return
