#Include 'Protheus.ch'

//--------------------------------------------------------------------------//
// Programa: TWMSR033()  |   Autor: Gustavo Schumann    |   Data: 24/06/2019//
//--------------------------------------------------------------------------//
// Descrição: Relatório de Estoque com número de série.
//
// MV_PAR01 = Cliente ? C/6 SA1
// MV_PAR02 = Loja ? C/2
// MV_PAR03 = Produto DE ? C/30 SB1
// MV_PAR04 = Produto ATE ? C/30 SB1
// MV_PAR05 = Endereco DE ? C/15 SBE
// MV_PAR06 = Endereco ATE ? C/15 SBE
// MV_PAR07 = Nota Fiscal DE ? C/9 SF1
// MV_PAR08 = Nota Fiscal ATE ? C/9 SF1
//--------------------------------------------------------------------------//

User Function TWMSR033()
	local _cPerg := PadR("TWMSR033",10)
	private oReport, oSec01, oSec02

	//Montando o objeto oReport
	oReport := TReport():NEW("TWMSR033", "Relatório de Estoque com número de série", _cPerg, {|oReport|PrintReport(oReport)},;
	"Este relatório irá listar todo o estoque do cliente selecionado contendo número de série.")

	//Declaração da Secção
	oSec01  := TRSection():New(oReport ,"Estoque",{"SBF"})
	oSec02  := TRSection():New(oReport ,"Totais",{"SBF"})

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
	local _nZ      := 0
	local _nTotal  := 0
	local _nTGeral := 0
	local _aQry    :={}
	local _aItens  := {}

	//Seção de impressão
	Private oSec01 := oReport:Section(1)
	Private oSec02 := oReport:Section(2)

	If ( Empty( MV_PAR01 ) )
		MsgStop("Cliente não especificado nos parâmetros do relatório! Verifique!")
		Return ( .F. )
	EndIf

	// posiciona no Pedido
	dbSelectArea("SC5")
	SC5->(dbSetOrder(1))

	If !( SC5->(dbSeek( xFilial("SC5") + MV_PAR01 )) )
		MsgStop("Pedido não encontrado")
		Return ( .F. )
	EndIf

	// seleciona produtos do cliente com os filtros indicados
	_cQuery := " "
	_cQuery += " SELECT BF_PRODUTO,BF_QUANT,BF_LOCAL,BF_LOCALIZ "
	_cQuery += " FROM "+RetSQLName("SBF")+" "
	_cQuery += " where D_E_L_E_T_ = '' "
	_cQuery += " and BF_FILIAL = '"+xFilial("SBF")+"' "
	_cQuery += " and BF_LOCALIZ between '"+MV_PAR05+"' and '"+MV_PAR06+"' "
	_cQuery += " and BF_PRODUTO in ( "
	_cQuery += "     SELECT distinct B6_PRODUTO "
	_cQuery += "     FROM "+RetSQLName("SB6")+" "
	_cQuery += "     where D_E_L_E_T_ = '' "
	_cQuery += "     and B6_CLIFOR = '"+MV_PAR01+"' "
	_cQuery += "     and B6_LOJA = '"+MV_PAR02+"' "
	_cQuery += "     and B6_PRODUTO between '"+MV_PAR03+"' and '"+MV_PAR04+"' "
	_cQuery += "     and B6_DOC between '"+MV_PAR07+"' and '"+MV_PAR08+"') "
	_cQuery += " order by BF_PRODUTO "

	// arquivo para debug
	memowrit("C:\query\TWMSR033_01.txt", _cQuery)

	_aQry := U_SqlToVet(_cQuery)

	IF ( Len(_aQry) < 1 )
		Help(,, 'TWMSR033.F01.001',, "Não foram encontrados resultados.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"Revise os parâmetros utilizados para a geração do relatório."}) 
		Return( .F. )
	EndIf

	oReport:SetMeter(Len(_aQry))

	// cria células/campos
	TRCell():New(oSec01,"Z16_CODPRO"	,"","Produto"		,/*Picture*/,25   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"B1_DESC"		,"","Descricao"		,/*Picture*/,40   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"QUANT"			,"","Quantidade"	,"@N 999999",10   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"Z16_NUMSER"	,"","Numero Serie"	,/*Picture*/,25   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"Z16_DTSERI"	,"","Data Serie"	,/*Picture*/,15   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"Z16_LOCAL"		,"","Armazem"		,/*Picture*/,10   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"Z16_TPESTO"	,"","Tipo Estoque"	,/*Picture*/,25   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"Z16_ENDATU"	,"","Endereco"		,/*Picture*/,30   ,/*lPixel*/,/*{|| code-block de impressao }*/)

	TRCell():New(oSec02,"DESC"			,"",""		,/*Picture*/,60   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"TOTAL"			,"",""		,"@N 999999",10   ,/*lPixel*/,/*{|| code-block de impressao }*/)

	// itens
	oSec01:Init()
	oReport:StartPage()

	_nTotal := 0

	For _nX := 1 to Len(_aQry)

		// dados dos produtos filtrados
		_cQuery := " "
		_cQuery += " SELECT Z16_CODPRO,B1_DESC,Z16_NUMSER,Z16_DTSERI,Z16_LOCAL,Z16_TPESTO+'-'+LTRIM(RTRIM(Z34_DESCRI)) Z16_TPESTO,Z16_ENDATU "
		_cQuery += " FROM " + RetSQLName("Z16") + " Z16 "
		_cQuery += " 	Inner join " + RetSQLName("SB1") + " SB1 "
		_cQuery += " 	On SB1.D_E_L_E_T_ = '' "
		_cQuery += " 	And B1_COD = Z16_CODPRO "

		_cQuery += " 	Left Join "+RetSQLName("Z34")+" Z34 "
		_cQuery += " 	On Z34.D_E_L_E_T_ = '' "
		_cQuery += " 	And Z34_CODIGO = Z16_TPESTO "
		_cQuery += " where Z16.D_E_L_E_T_ = '' "
		_cQuery += " and Z16_CODPRO = '"+_aQry[_nX][1]+"' "
		_cQuery += " and Z16_ENDATU = '"+_aQry[_nX][4]+"' "
		_cQuery += " and Z16_LOCAL = '"+_aQry[_nX][3]+"' "

		memowrit("C:\query\TWMSR033_02.txt", _cQuery)

		_aItens := U_SqlToVet(_cQuery)

		For _nZ := 1 to Len(_aItens)
			// imprime todos os registros, por produto
			oSec01:Cell("Z16_CODPRO"):SetValue(_aItens[_nZ][1])
			oSec01:Cell("B1_DESC"   ):SetValue(_aItens[_nZ][2])
			oSec01:Cell("QUANT"     ):SetValue(1)
			oSec01:Cell("Z16_NUMSER"):SetValue(_aItens[_nZ][3])
			oSec01:Cell("Z16_DTSERI"):SetValue(STOD(AllTrim(_aItens[_nZ][4])))
			oSec01:Cell("Z16_LOCAL" ):SetValue(_aItens[_nZ][5])
			oSec01:Cell("Z16_TPESTO"):SetValue(_aItens[_nZ][6])
			oSec01:Cell("Z16_ENDATU"):SetValue(_aItens[_nZ][7])

			oSec01:PrintLine()

			_nTotal++
			_nTGeral++
		Next _nZ

		// imprime total de itens do produto
		oSec02:Init()
		oSec02:Cell("DESC"):SetValue("Total")
		oSec02:Cell("TOTAL"):SetValue(_nTotal)
		oSec02:PrintLine()
		oSec02:Finish()

		_nTotal := 0

		oReport:IncMeter() //Progresso da barra

	Next _nX

	// imprime a quantidade total de itens
	oSec02:Init()
	oSec02:Cell("DESC"):SetValue("Total Geral")
	oSec02:Cell("TOTAL"):SetValue(_nTGeral)
	oSec02:PrintLine()
	oSec02:Finish()

	oReport:SetTotalInLine(.F.)

	oSec01:Finish()

	oReport:EndPage()

	RestArea(_aArea)

Return oReport