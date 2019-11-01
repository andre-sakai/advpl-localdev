#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'TopConn.ch'

//----------------------------------------------------------------------------------//
// Programa: TFISR001	|	Autor: Gustavo Schumann / SLA TI	|	Data: 23/08/2018//
//----------------------------------------------------------------------------------//
//			Descrição: Relatório Planilha para PIS/COFINS.							//
//----------------------------------------------------------------------------------//

User Function TCTBR001()
	Private oReport	:= Nil
	Private oSecCab	:= Nil
	Private cPerg 	:= PADR("TCTBR001", 10)

	ValidPerg()

	ReportDef()
	oReport	:PrintDialog()

Return Nil
//-------------------------------------------------------------------------------------------------
Static Function ValidPerg()
	Local i	:= 0
	Local j	:= 0

	_sAlias := Alias()
	dbSelectArea("SX1")
	dbSetOrder(1)
	cPerg := PADR(cPerg,10)
	aRegs:={}

	AADD(aRegs,{cPerg,"01","Filial ?		","","","mv_ch1	","C",03,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SM0","","","",""})
	AADD(aRegs,{cPerg,"02","Origem ?		","","","mv_ch2	","C",01,0,0,"C","","mv_par02","1=NFs Entrada","","","","","2=NFs Saida","","","","","3-NF Ent/Saida","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPerg,"03","Cliente DE ?	","","","mv_ch3	","C",06,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","",""})
	AADD(aRegs,{cPerg,"04","Loja DE ?		","","","mv_ch4	","C",02,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPerg,"05","Cliente ATE ?	","","","mv_ch5	","C",06,0,0,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","",""})
	AADD(aRegs,{cPerg,"06","Loja ATE ?		","","","mv_ch6	","C",02,0,0,"G","","mv_par06","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPerg,"07","Fornecedor DE ?	","","","mv_ch7	","C",06,0,0,"G","","mv_par07","","","","","","","","","","","","","","","","","","","","","","","","","SA2","","","",""})
	AADD(aRegs,{cPerg,"08","Fornecedor ATE ?","","","mv_ch8	","C",06,0,0,"G","","mv_par08","","","","","","","","","","","","","","","","","","","","","","","","","SA2","","","",""})
	AADD(aRegs,{cPerg,"09","Data DE ?		","","","mv_ch9	","D",08,0,0,"G","","mv_par09","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPerg,"10","Data ATE ?		","","","mv_ch10","D",08,0,0,"G","","mv_par10","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPerg,"11","Nota DE ?		","","","mv_ch11","C",09,0,0,"G","","mv_par11","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPerg,"12","Nota ATE ?		","","","mv_ch12","C",09,0,0,"G","","mv_par12","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPerg,"13","Conta Cont ? (Branco p/ todos)	","","","mv_ch13","C",20,0,0,"G","","mv_par13","","","","","","","","","","","","","","","","","","","","","","","","","CT1","","","",""})
	AADD(aRegs,{cPerg,"14","Imprime notas com PIS ou COFINS?:	","","","mv_ch14","C",01,0,0,"C","","mv_par14","1=Sim","","","","","2=Não","","","","","","","","","","","","","","","","","","","","","","",""})

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

	dbSelectArea(_sAlias)

Return
//-------------------------------------------------------------------------------------------------
Static Function ReportDef()
	oReport := TReport():New(cPerg,"Planilha de auditoria PIS/COFINS",cPerg,{|oReport| PrintReport(oReport)},"Este relatório irá listar todas as notas fiscais, dentro dos parâmetros informados, que contém ou não impostos de PIS ou COFINS.")
	oReport:SetPortrait()

	oSecCab := TRSection():New( oReport , "Saldo", {"tSFT"} )

	TRCell():New( oSecCab, "Origem"				, "tSFT")
	TRCell():New( oSecCab, "Filial"				, "tSFT")
	TRCell():New( oSecCab, "Nota"				, "tSFT")
	TRCell():New( oSecCab, "Serie"				, "tSFT")
	TRCell():New( oSecCab, "CliFor"				, "tSFT")
	TRCell():New( oSecCab, "Loja"				, "tSFT")
	TRCell():New( oSecCab, "Nome"				, "tSFT")
	TRCell():New( oSecCab, "CNPJ"				, "tSFT")
	TRCell():New( oSecCab, "Ano"				, "tSFT")
	TRCell():New( oSecCab, "Mes"				, "tSFT")
	TRCell():New( oSecCab, "UF"					, "tSFT")
	TRCell():New( oSecCab, "CFOP"				, "tSFT")
	TRCell():New( oSecCab, "Cod_Produto"		, "tSFT")
	TRCell():New( oSecCab, "Descricao"			, "tSFT")
	TRCell():New( oSecCab, "Qtde"				, "tSFT")
	TRCell():New( oSecCab, "Valor_Unit"			, "tSFT")
	TRCell():New( oSecCab, "Valor_Total"		, "tSFT")
	TRCell():New( oSecCab, "Aliq_IR"			, "tSFT")
	TRCell():New( oSecCab, "Valor_IR"			, "tSFT")
	TRCell():New( oSecCab, "Conta"				, "tSFT")
	TRCell():New( oSecCab, "Desc_Conta"			, "tSFT")
	TRCell():New( oSecCab, "Cod_Centro_Custo"	, "tSFT")
	TRCell():New( oSecCab, "Desc_Centro_Custo"	, "tSFT")

Return Nil
//-------------------------------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local cQuery := ""
	Local cPar02 := AllTrim(Str(MV_PAR02))
	Local cPar14 := AllTrim(Str(MV_PAR14))

	Pergunte(cPerg,.F.)

	If Select("tSFT") <> 0
		DBSelectArea("tSFT")
		tSFT->(DBCloseArea())
	EndIf

	cQuery := " "
	cQuery += " SELECT 'Entrada' as Origem, D1_FILIAL as Filial,D1_DOC as Nota,D1_SERIE as Serie,D1_FORNECE as CliFor,D1_LOJA as Loja,A2_NOME as Nome, "
	cQuery += " A2_CGC as CNPJ,Substring(D1_EMISSAO,1,4) as Ano,Substring(D1_EMISSAO,5,2)+'/'+Substring(D1_EMISSAO,1,4) as Mes,A2_EST as UF, "
	cQuery += " D1_CF as CFOP, D1_COD as Cod_Produto,B1_DESC Descricao,D1_QUANT Qtde,D1_VUNIT Valor_Unit, D1_TOTAL Valor_Total, "
	cQuery += " D1_BASEIRR as Aliq_IR, D1_VALIRR as Valor_IR, FT_CONTA Conta,CT1_DESC01 as Desc_Conta,D1_CC as Cod_Centro_Custo, IsNull(CTT_DESC01,'') as Desc_Centro_Custo "	
	cQuery += " FROM  " + RetSQLTab("SD1")
	cQuery += " inner join " + RetSQLTab("SFT") 
	cQuery += " on " + RetSqlCond("SFT")
	cQuery += " and FT_FILIAL = D1_FILIAL "
	cQuery += " and FT_NFISCAL = D1_DOC "
	cQuery += " and FT_SERIE = D1_SERIE "
	cQuery += " and FT_CLIEFOR = D1_FORNECE "
	cQuery += " and FT_LOJA = D1_LOJA "
	cQuery += " and FT_ALIQIRR = D1_BASEIRR "
	cQuery += " and FT_VALIRR = D1_VALIRR "
	If (cPar14 == "1") // apenas com PIS ou COFINS
		cQuery += " AND (FT_VALPIS != 0 OR FT_VALCOF != 0) "
	Else // apenas sem PIS ou COFINS
		cQuery += " AND (FT_VALPIS = 0) "
		cQuery += " AND (FT_VALCOF = 0) "
	EndIf
	If !EMPTY(MV_PAR13)
		cQuery += " and FT_CONTA = '" + MV_PAR13 + "' "
	EndIf


	cQuery += " inner join " + RetSQLTab("CT1")
	cQuery += " on " + RetSqlCond("CT1")
	cQuery += " and CT1_CONTA = FT_CONTA "

	cQuery += " inner join " + RetSQLTab("SA2")
	cQuery += " on " + RetSqlCond("SA2")
	cQuery += " and A2_COD = D1_FORNECE "
	cQuery += " and A2_LOJA = D1_LOJA "

	cQuery += " inner join " + RetSQLTab("SB1") 
	cQuery += " on " + RetSqlCond("SB1")
	cQuery += " and B1_COD = D1_COD "

	cQuery += " left join " + RetSQLTab("CTT")
	cQuery += " on " + RetSqlCond("CTT")
	cQuery += " and CTT_CUSTO = D1_CC "

	cQuery += " where " + RetSqlCond("SD1")
	cQuery += " and D1_FILIAL = '" + MV_PAR01 + "'"
	cQuery += " and ('1' = '" + cPar02 + "' or '3' = '" + cPar02 + "') "
	cQuery += " and D1_FORNECE between '"+MV_PAR07+"' and '"+MV_PAR08+"' "
	cQuery += " and D1_EMISSAO between '"+DTOS(MV_PAR09)+"' and '"+DTOS(MV_PAR10)+"' "
	cQuery += " and D1_DOC between '"+MV_PAR11+"' and '"+MV_PAR12+"' "

	cQuery += " UNION ALL "

	cQuery += " SELECT 'Saida' as Origem, D2_FILIAL as Filial,D2_DOC as Nota,D2_SERIE as Serie,D2_CLIENTE as CliFor,D2_LOJA as Loja,A1_NOME as Nome, "
	cQuery += " A1_CGC as CNPJ,Substring(D2_EMISSAO,1,4) as Ano,Substring(D2_EMISSAO,5,2)+'/'+Substring(D2_EMISSAO,1,4) as Mes,A1_EST as UF, "
	cQuery += " D2_CF as CFOP, D2_COD as Cod_Produto,B1_DESC Descricao,D2_QUANT Qtde,D2_PRCVEN Valor_Unit, D2_TOTAL Valor_Total, "
	cQuery += " D2_ALQIRRF as Aliq_IR, D2_VALIRRF as Valor_IR, FT_CONTA Conta,IsNull(CT1_DESC01,'') as Desc_Conta,D2_CCUSTO as Cod_Centro_Custo, IsNull(CTT_DESC01,'') as Desc_Centro_Custo "

	cQuery += " FROM " + RetSQLTab("SD2")

	cQuery += " inner join " + RetSQLTab("SFT")
	cQuery += " on " + RetSqlCond("SFT")
	cQuery += " and FT_FILIAL = D2_FILIAL "
	cQuery += " and FT_NFISCAL = D2_DOC "
	cQuery += " and FT_SERIE = D2_SERIE "
	cQuery += " and FT_CLIEFOR = D2_CLIENTE "
	cQuery += " and FT_LOJA = D2_LOJA "
	cQuery += " and FT_ALIQIRR = D2_ALQIRRF "
	cQuery += " and FT_VALIRR = D2_VALIRRF "
	If (cPar14 == "1") // apenas com PIS ou COFINS
		cQuery += " AND (FT_VALPIS != 0 OR FT_VALCOF != 0) "
	Else // apenas sem PIS ou COFINS
		cQuery += " AND (FT_VALPIS = 0) "
		cQuery += " AND (FT_VALCOF = 0) "
	EndIf
	If !EMPTY(MV_PAR13)
		cQuery += " and FT_CONTA = '"+MV_PAR13+"' "
	EndIf

	cQuery += " left join " + RetSQLTab("CT1") 
	cQuery += " on " + RetSqlCond("CT1")
	cQuery += " and CT1_CONTA = FT_CONTA "

	cQuery += " inner join "+RetSQLTab("SA1")
	cQuery += " on " + RetSqlCond("SA1")
	cQuery += " and A1_COD = D2_CLIENTE "
	cQuery += " and A1_LOJA = D2_LOJA "

	cQuery += " inner join " + RetSQLTab("SB1")
	cQuery += " on " + RetSqlCond("SB1")
	cQuery += " and B1_COD = D2_COD "

	cQuery += " left join " + RetSQLTab("CTT")
	cQuery += " on " + RetSqlCond("CTT")
	cQuery += " and CTT_CUSTO = D2_CCUSTO "

	cQuery += " where " + RetSqlCond("SD2")
	cQuery += " and D2_FILIAL = '" + MV_PAR01 + "'"
	cQuery += " and ('2' = '" + cPar02 + "' or '3' = '" + cPar02 + "') "
	cQuery += " and D2_CLIENTE between '" + MV_PAR03 + "' and '" + MV_PAR05 + "' "
	cQuery += " and D2_LOJA between '" + MV_PAR04 + "' and '" + MV_PAR06 + "' "
	cQuery += " and D2_EMISSAO between '" + DtoS(MV_PAR09) + "' and '" + DtoS(MV_PAR10) +"'"
	cQuery += " and D2_DOC between '" + MV_PAR11 + "' and '" + MV_PAR12 + "' "

	MemoWrit("c:\query\TCTBR001.txt", cQuery)
	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "tSFT"

	oSecCab:BeginQuery()
	oSecCab:EndQuery({{"tSFT"},cQuery})
	oSecCab:Print()

Return Nil