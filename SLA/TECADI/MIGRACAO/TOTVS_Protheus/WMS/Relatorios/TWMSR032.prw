#Include 'Protheus.ch'

//--------------------------------------------------------------------------//
// Programa: TWMSR032()  |   Autor: Gustavo Schumann    |   Data: 29/05/2019//
//--------------------------------------------------------------------------//
// Descrição: Relatório Espelho de pedido de venda  .						//
//--------------------------------------------------------------------------//

User Function TWMSR032()
	local _cPerg := PadR("TWMSR032",10)
	private oReport, oSec01, oSec02

	//Montando o objeto oReport
	oReport := TReport():NEW("TWMSR032", "Relatório - Espelho de pedido de venda", _cPerg, {|oReport|PrintReport(oReport)},;
	"Este relatório irá listar todos os itens do pedido de venda e suas quantidades e lote (espelho do pedido)")

	//Declaração da Secção
	oSec01  := TRSection():New(oReport ,"Cabeçalho pedido",{"SC5"})
	oSec02  := TRSection():New(oReport ,"Itens",{"SC6"})

	// desabilita totalizadores
	oSec01:SetTotalInLine( .F. )
	oSec02:SetTotalInLine( .F. )

	oSec01:SetHeaderPage()

	// desabilita personalizar relatório
	oReport:SetEdit( .F. )

	//desabilita impressão da página de parâmetros
	oReport:lParamPage := .F.
	// chama rotina para geracao do relatorio
	oReport:PrintDialog()

Return

// lógica do relatório
Static Function PrintReport(oReport)
	// query
	Local _cQuery  := ""

	Local _aArea := GetArea()

	// variaveis temporarias
	local _nX      := 0
	local _aQry    :={}
	local _cNumped := ""

	local _nQtdPlt := 0
	local _nQtdVol := 0
	local _nQuant   := 0

	//Seção de impressão
	Private oSec01 := oReport:Section(1)
	Private oSec02 := oReport:Section(2)

	If ( Empty( MV_PAR01 ) )
		MsgStop("Número do Pedido não especificado nos parâmetros do relatório! Verifique!")
		Return ( .F. )
	EndIf

	// posiciona no Pedido
	dbSelectArea("SC5")
	SC5->(dbSetOrder(1))

	If !( SC5->(dbSeek( xFilial("SC5") + MV_PAR01 )) )
		MsgStop("Pedido não encontrado")
		Return ( .F. )
	EndIf

	// dados da query
	_cQuery := " SELECT C5_FILIAL, "
	_cQuery += "        C5_NUM, "
	_cQuery += "        CONVERT(VARCHAR(10), CONVERT(DATE, C5_EMISSAO), 103) C5_EMISSAO, "
	_cQuery += "        IsNull(C5_ZDOCCLI,'') C5_ZDOCCLI, "
	_cQuery += "        IsNull(C5_ZCARGA,'') C5_ZCARGA, "
	_cQuery += "        IsNull(C5_ZNOSSEP,'') C5_ZNOSSEP, "
	_cQuery += "        Substring(C6_PRODUTO, 5, 25) C6_PRODUTO, "
	_cQuery += "        C6_DESCRI, "
	_cQuery += "        C6_NFORI, "
	_cQuery += "        C6_SERIORI, "
	_cQuery += "        Z45_LOTCTL, "
	_cQuery += "        IsNull(Z45_QUANT, C6_QTDVEN) QTD, "
	_cQuery += "        Z45_ETQPAL, "
	_cQuery += "        Z45_ETQVOL "
	_cQuery += " FROM   " + RetSQLTab("SC5")
	_cQuery += "        INNER JOIN " + RetSQLTab("SC6")
	_cQuery += "                ON " + RetSqlCond("SC6")
	_cQuery += "                   AND C5_NUM = C6_NUM "
	_cQuery += "        LEFT JOIN " + RetSQLTab("Z45")
	_cQuery += "                ON " + RetSqlCond("Z45")
	_cQuery += "                   AND Z45_PEDIDO = C6_NUM "
	_cQuery += "                   AND Z45_CODPRO = C6_PRODUTO "
	_cQuery += "                   AND Z45_LOTCTL = C6_LOTECTL "
	_cQuery += "                   AND Z45_LOCAL = C6_LOCAL "
	_cQuery += " WHERE " + RetSqlCond("SC5")
	_cQuery += "        AND C5_NUM = '" + MV_PAR01 + "' "
	_cQuery += "        AND C5_TIPOOPE = 'P' "

	// arquivo para debug
	memowrit("C:\query\twmsr032.txt", _cQuery)

	_aQry := U_SqlToVet(_cQuery)

	IF ( Len(_aQry) < 1 )
		Help(,, 'TWMSR032.F01.001',, "Não foram encontrados resultados.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"Revise os parâmetros utilizados para a geração do relatório."}) 
		Return( .F. )
	EndIf

	_cQuery := " SELECT count(distinct Z45_ETQPAL) Z45_ETQPAL "
	_cQuery += " FROM   " + RetSQLTab("SC5")
	_cQuery += "        INNER JOIN " + RetSQLTab("SC6")
	_cQuery += "                ON " + RetSqlCond("SC6")
	_cQuery += "                   AND C5_NUM = C6_NUM "
	_cQuery += "        INNER JOIN " + RetSQLTab("Z45")
	_cQuery += "                ON " + RetSqlCond("Z45")
	_cQuery += "                   AND Z45_PEDIDO = C6_NUM "
	_cQuery += "                   AND Z45_CODPRO = C6_PRODUTO "
	_cQuery += "                   AND Z45_LOTCTL = C6_LOTECTL "
	_cQuery += "                   AND Z45_LOCAL  = C6_LOCAL "
	_cQuery += " WHERE " + RetSqlCond("SC5")
	_cQuery += "        AND C5_NUM = '" + MV_PAR01 + "' "
	_cQuery += "        AND C5_TIPOOPE = 'P' "
	
	// arquivo para debug
	memowrit("C:\query\twmsr032_1.txt", _cQuery)

	_nQtdPlt := U_FTQuery(_cQuery)

	_cQuery := " SELECT count(distinct Z45_ETQVOL) Z45_ETQVOL "
	_cQuery += " FROM  " + RetSQLTab("SC5")
	_cQuery += "        INNER JOIN " + RetSQLTab("SC6")
	_cQuery += "                ON " + RetSqlCond("SC6")
	_cQuery += "                   AND C5_NUM = C6_NUM "
	_cQuery += "        INNER JOIN " + RetSQLTab("Z45")
	_cQuery += "                ON "  + RetSqlCond("Z45")
	_cQuery += "                   AND Z45_PEDIDO = C6_NUM "
	_cQuery += "                   AND Z45_CODPRO = C6_PRODUTO "
	_cQuery += "                   AND Z45_LOTCTL = C6_LOTECTL "
	_cQuery += "                   AND Z45_LOCAL = C6_LOCAL "
	_cQuery += " WHERE " + RetSqlCond("SC5")
	_cQuery += "        AND C5_NUM = '" + MV_PAR01 + "' "
	_cQuery += "        AND C5_TIPOOPE = 'P' "

	// arquivo para debug
	memowrit("C:\query\twmsr032_2.txt", _cQuery)

	_nQtdVol := U_FTQuery(_cQuery)

	For i:=1 To Len(_aQry)
		_nQuant += _aQry[i][12]
	Next i

	oReport:SetMeter(Len(_aQry))

	// cria células/campos
	TRCell():New(oSec01,"C5_FILIAL"    ,"","Filial"			,/*Picture*/,TamSX3("C5_FILIAL")[1]     ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"C5_NUM"       ,"","Pedido"			,/*Picture*/,TamSX3("C5_NUM")[1]    ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"C5_EMISSAO"   ,"","Emissao"		,/*Picture*/,10    ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"C5_ZDOCCLI"   ,"","Doc Cliente"	,/*Picture*/,TamSX3("C5_ZDOCCLI")[1]  ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"C5_ZCARGA"	   ,"","Nr. Carga"		,/*Picture*/,TamSX3("C5_ZCARGA")[1]  ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"C5_ZNOSSEP"   ,"","OS Separacao"	,/*Picture*/,TamSX3("C5_ZNOSSEP")[1]  ,/*lPixel*/,/*{|| code-block de impressao }*/)

	TRCell():New(oSec01,"QUANT"   ,"","Quantidade"	,/*Picture*/,TamSX3("Z45_QUANT")[1]  ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"ETQPAL"   ,"","Qtd Etq Pallet"	,/*Picture*/,TamSX3("Z45_ETQPAL")[1]  ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"ETQVOL"   ,"","Qtd Etq Volume"	,/*Picture*/,TamSX3("Z45_ETQVOL")[1]  ,/*lPixel*/,/*{|| code-block de impressao }*/)

	TRCell():New(oSec02,"C6_PRODUTO"   ,"","Produto"		,/*Picture*/,25   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"C6_DESCRI"    ,"","Descricao"		,/*Picture*/,30   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"C6_NFORI"     ,"","Nota"			,/*Picture*/,20   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"C6_SERIORI"   ,"","Serie"			,/*Picture*/,5   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"Z45_LOTCTL"   ,"","Lote"			,/*Picture*/,20   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"Z45_QUANT"    ,"","Quantidade"		,PesqPict("Z45","Z45_QUANT"),30   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"Z45_ETQPAL"   ,"","Etq Pallet"		,/*Picture*/,30   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"Z45_ETQVOL"   ,"","Etq Volume"		,/*Picture*/,30   ,/*lPixel*/,/*{|| code-block de impressao }*/)

	// cabeçalho principal
	oSec01:Init()
	oSec01:Cell("C5_FILIAL" ):SetValue(_aQry[1][1])
	oSec01:Cell("C5_NUM"    ):SetValue(_aQry[1][2])
	oSec01:Cell("C5_EMISSAO"):SetValue(_aQry[1][3])
	oSec01:Cell("C5_ZDOCCLI"):SetValue(_aQry[1][4])
	oSec01:Cell("C5_ZCARGA" ):SetValue(_aQry[1][5])
	oSec01:Cell("C5_ZNOSSEP"):SetValue(_aQry[1][6])
	oSec01:Cell("QUANT"):SetValue(_nQuant)
	oSec01:Cell("ETQPAL" ):SetValue(_nQtdPlt)
	oSec01:Cell("ETQVOL"):SetValue(_nQtdVol)
	oSec01:PrintLine()
	oSec01:Finish()

	// itens
	oSec02:Init()

	oReport:StartPage()

	For _nX := 1 to Len(_aQry)
		oSec02:Cell("C6_PRODUTO" ):SetValue(_aQry[_nX][7])
		oSec02:Cell("C6_DESCRI"  ):SetValue(_aQry[_nX][8])
		oSec02:Cell("C6_NFORI"   ):SetValue(_aQry[_nX][9])
		oSec02:Cell("C6_SERIORI" ):SetValue(_aQry[_nX][10])
		oSec02:Cell("Z45_LOTCTL" ):SetValue(_aQry[_nX][11])
		oSec02:Cell("Z45_QUANT"  ):SetValue(_aQry[_nX][12])
		oSec02:Cell("Z45_ETQPAL" ):SetValue(_aQry[_nX][13])
		oSec02:Cell("Z45_ETQVOL" ):SetValue(_aQry[_nX][14])

		oSec02:PrintLine()

		oReport:IncMeter() //Progresso da barra
	Next _nX

	oReport:SetTotalInLine(.F.)

	oSec02:Finish()

	oReport:EndPage()

	RestArea(_aArea)

Return oReport