#Include 'Protheus.ch'
#Include 'TopConn.ch'

//----------------------------------------------------------------------------------//
// Programa: TWMSR031	|	Autor: Gustavo Schumann / SLA TI	|	Data: 24/10/2018//
//----------------------------------------------------------------------------------//
//			Descrição: Relatório de etiquetas conferidas (etiqueta cliente).        //
//----------------------------------------------------------------------------------//

User Function TWMSR031()
	Private oReport	:= Nil
	Private cPerg 	:= PADR("TWMSR031", 10)
	Private oSec1

	ValidPerg()

	ReportDef()
	oReport	:PrintDialog()

Return Nil
//-------------------------------------------------------------------------------------------------
Static Function ValidPerg()
	Local i	:= 0
	Local j	:= 0

	dbSelectArea("SX1")
	dbSetOrder(1)
	cPerg := PADR(cPerg,10)
	aRegs:={}

	AADD(aRegs,{cPerg,"01","Numero da OS ?		","","","mv_ch1	","C",TamSx3("Z05_NUMOS")[1],0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","Z05","","","",""})

	For i:=1 to Len(aRegs)
		If !dbSeek(cPerg + aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next

Return
//-------------------------------------------------------------------------------------------------
Static Function ReportDef()

	oReport := TReport():New(cPerg,"Relatório de etiquetas de cliente conferidas.",cPerg,{|oReport| PrintReport(oReport)},"Relatório de etiquetas de cliente conferidas.")
	oReport:SetPortrait()

	oSec1 := TRSection():New( oReport , "", {"tZ07"} )

	TRCell():New(oSec1,"OS"					,"tZ07","OS"				,"@!",08,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec1,"Cliente"			,"tZ07","Cliente"			,"@!",10,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec1,"Etiqueta_Pallet"	,"tZ07","Etiqueta Pallet"	,"@!",15,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec1,"Etiqueta_Cliente"	,"tZ07","Etiqueta Cliente"	,"@!",15,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec1,"Data"				,"tZ07","Data"				,"@!",12,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec1,"Hora"				,"tZ07","Hora"				,"@!",10,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec1,"Produto"			,"tZ07","Produto"			,"@!",15,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec1,"Descricao"			,"tZ07","Descricao"			,"@!",40,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec1,"Quantidade"			,"tZ07","Quantidade"		,"@!",05,/*lPixel*/,/*{|| code-block de impressao }*/)

Return Nil
//-------------------------------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local cQuery := ""

	Pergunte(cPerg,.F.)

	If Select("tZ07") <> 0
		DBSelectArea("tZ07")
		tZ07->(DBCloseArea())
	EndIf

	cQuery := " "
	cQuery += " SELECT RTRIM(Z07_NUMOS) OS, RTRIM(Z07_CLIENT) Cliente,RTRIM(Z56_CODETI) Etiqueta_Pallet, RTRIM(Z56_ETQCLI) Etiqueta_Cliente, "
	cQuery += " CONVERT(VARCHAR(10), CONVERT(DATE, Z07_DATA), 103) Data, "
	cQuery += " Z07_HORA Hora, RTRIM(Z56_CODPRO) Produto,RTRIM(B1_DESC) Descricao,Z56_QUANT Quantidade "

	cQuery += " FROM " + RetSQLTab("Z07")

	cQuery += " inner join " + RetSQLTab("Z56")
	cQuery += " on " + RetSqlCond("Z56")
	cQuery += " and Z56_FILIAL = Z07_FILIAL "
	cQuery += " and Z56_CODCLI = Z07_CLIENT "
	cQuery += " and Z56_LOJCLI = Z07_LOJA "
	cQuery += " and Z56_CODETI = Z07_ETQPRD "

	cQuery += " inner join " + RetSQLTab("SB1")
	cQuery += " on "  + RetSqlCond("SB1")
	cQuery += " and B1_COD = Z56_CODPRO "

	cQuery += " where "  + RetSqlCond("Z07")
	cQuery += " and Z07_NUMOS = '" + MV_PAR01 + "' "
	cQuery += " order by Z56_CODETI,Z07_DATA,Z07_HORA "

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "tZ07"

	oSec1:BeginQuery()
	oSec1:EndQuery({{"tZ07"},cQuery})
	oSec1:Print()

	If Select("tZ07") <> 0
		DBSelectArea("tZ07")
		tZ07->(DBCloseArea())
	EndIf

Return Nil