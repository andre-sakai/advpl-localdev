#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSR028                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Relatório de volumes (produtos) conferidos  durante     !
!                  ! a sequência de recebimento                              !
+------------------+---------------------------------------------------------+
!Autor             ! Luiz Poleza                                             !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 06/2018                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSR028()

	// grupo de perguntas
	local _cPerg := PadR("TWMSR028",10)
	local _aPerg := {}

	// monta a lista de perguntas
	aAdd(_aPerg,{"Num OS:" , "C",TamSx3("Z05_NUMOS")[1] ,0,"G",,""}) //mv_par01

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// chama rotina para geracao do relatorio
	oReport := ReportDef(_cPerg)
	oReport:PrintDialog()

Return

// ** funcao que gera o relatorio conforme parametros
Static Function ReportDef(mvPerg)

	Private oReport

	//Montando o objeto oReport
	oReport := TReport():NEW("TWMSR028", "Relatório da etapa de Conferencia de recebimento", mvPerg, {|oReport|PrintReport(oReport)},;
	"Este relatório irá listar todos os itens conferidos durante a etapa de recebimento de determinada ordem de serviço")

	//Declaração da Secção
	oSec01  := TRSection():New(oReport ,"Cabeçalho",{"Z05"})
	oSec02  := TRSection():New(oReport ,"Itens",{"Z07"})
	oSec01:SetTotalInLine(.F.)
	oSec02:SetTotalInLine(.F.)

	TRCell():New(oSec01,"CODCLI"  ,"","Cód. Cliente"  ,/*Picture*/,TamSX3("A1_COD")[1]     ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"LOJCLI"  ,"","Loja"          ,/*Picture*/,TamSX3("A1_LOJA")[1]    ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"CLIENT"  ,"","Cliente" 	  ,/*Picture*/,TamSX3("A1_NOME")[1]    ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"NUMOS"	  ,"","Nº OS"		  ,/*Picture*/,TamSX3("Z05_NUMOS")[1]  ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"CESV"	  ,"","Nº CESV"	      ,/*Picture*/,TamSX3("Z05_CESV")[1]   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"PROGRAM" ,"","Programação"   ,/*Picture*/,TamSX3("Z05_PROCES")[1] ,/*lPixel*/,/*{|| code-block de impressao }*/)

	TRCell():New(oSec02,"PROD"	 ,"","Cód. Produto"	  ,/*Picture*/                         ,TamSX3("B1_COD")[1]     ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"DESC"	 ,"","Descrição"	  ,/*Picture*/                         ,30                      ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"QTD"    ,"","Quant"          ,PesqPict("SD1","D1_QUANT")          ,TamSX3("Z07_QUANT")[1]  ,,,       ,,"RIGHT"         )
	TRCell():New(oSec02,"LOTE"   ,"","Lote"           ,/*Picture*/                         ,TamSX3("Z07_LOTCTL")[1] ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"ETQCLI" ,"","Etq. Cliente"   ,/*Picture*/                         ,TamSX3("Z07_ETQCLI")[1] ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"PLTCLI" ,"","Etq. Pallet"    ,/*Picture*/                         ,TamSX3("Z07_PLTCLI")[1] ,/*lPixel*/,/*{|| code-block de impressao }*/)

	oSec01:SetHeaderPage()
	oReport:lParamPage := .F.

Return(oReport)

// lógica do relatório
Static Function PrintReport(oReport)

	Local oBreak01

	// query
	Local _cQuery:= ""

	Local _aArea := GetArea()

	// variaveis temporarias
	local _nX      := 0
	local _aQry    :={}

	//Seção de impressão
	Private oSec01 := oReport:Section(1)
	Private oSec02 := oReport:Section(2)

	If ( Empty( MV_PAR01 ) )
		MsgStop("Número da OS não especificado nos parâmetros do relatório! Verifique!")
		Return ( .F. )
	EndIf

	// posiciona na OS
	dbSelectArea("Z05")
	Z05->(dbSetOrder(1)) // 1-Z05_FILIAL, Z05_NUMOS

	If !( Z05->(dbSeek( xFilial("Z05") + MV_PAR01 )) )
		MsgStop("OS não encontrada")
		Return ( .F. )
	EndIf

	If ( Z05->Z05_TPOPER != "E" )
		MsgStop("Relatório disponível apenas para OS do tipo Recebimento")
		Return ( .F. )
	EndIf

	// posiciona nos serviços da OS
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1 - Z06_FILIAL, Z06_NUMOS, Z06_SEQOS, R_E_C_N_O_, D_E_L_E_T_
	Z06->(dbSeek( xFilial("Z05") + MV_PAR01 + "001"))

	IF ( Z06->Z06_STATUS != "FI")
		MsgStop("Relatório disponível apenas para recebimentos já concluídos.")
		Return ( .F. )
	EndIf

	//	oBreak01 := TRBreak():New(oSec01,oSec01:Cell("NCERV"),"Total",.F.)

	//	TRFunction():New(oSec02:Cell('QTDD'	),NIL,"SUM",oBreak01,/*Titulo*/,/*cPicture*/,/*uFormula*/,.F.,.F.)
	//	TRFunction():New(oSec02:Cell('QTDC'	),NIL,"SUM",oBreak01,/*Titulo*/,/*cPicture*/,/*uFormula*/,.F.,.F.)

	// dados da query
	_cQuery := " SELECT Z05_NUMOS,                          "
	_cQuery += "        Z05_CLIENT,                         "
	_cQuery += "        Z05_LOJA,                           "
	_cQuery += "        A1_NOME,                            "
	_cQuery += "        Z05_CESV,                           "
	_cQuery += "        Z05_PROCES,                         "
	_cQuery += "        Z07_PRODUT,                         "
	_cQuery += "        B1_DESC,                            "
	_cQuery += "        Z07_QUANT,                          "
	_cQuery += "        Z07_LOTCTL,                         "
	_cQuery += "        Z07_ETQVOL,                         "
	_cQuery += "        Z07_ETQCLI,                         "
	_cQuery += "        Z07_PLTCLI                          "
	_cQuery += " FROM " + RetSqlTab("Z05")
	_cQuery += "        INNER JOIN " + RetSqlTab("SA1")
	_cQuery += "                ON " + RetSqlCond("SA1")
	_cQuery += "                   AND A1_COD = Z05_CLIENT  "
	_cQuery += "                   AND A1_LOJA = Z05_LOJA   "
	_cQuery += "        INNER JOIN " + RetSqlTab("Z07")
	_cQuery += "                ON " + RetSqlCond("Z07")
	_cQuery += "                   AND Z07_NUMOS = Z05_NUMOS"
	_cQuery += "                   AND Z07_SEQOS = '001'    "
	_cQuery += "        INNER JOIN " + RetSqlTab("SB1")
	_cQuery += "                ON " + RetSqlCond("SB1")
	_cQuery += "                   AND B1_COD = Z07_PRODUT  "
	_cQuery += " WHERE  " + RetSqlCond("Z05")
	_cQuery += "        AND Z05_NUMOS = '" + MV_PAR01 + "'"
	_cQuery += " ORDER BY Z07_PRODUT, Z07_LOTCTL "

	// arquivo para debug
	memowrit("C:\query\twmsr028.txt", _cQuery)

	_aQry := U_SqlToVet(_cQuery)

	oReport:SetMeter(Len(_aQry))

	// cabeçalho
	oSec01:Init()
	oSec01:Cell("NUMOS"	  ):SetValue(_aQry[1][1])
	oSec01:Cell("CODCLI"  ):SetValue(_aQry[1][2])
	oSec01:Cell("LOJCLI"  ):SetValue(_aQry[1][3])
	oSec01:Cell("CLIENT"  ):SetValue(_aQry[1][4])
	oSec01:Cell("CESV"	  ):SetValue(_aQry[1][5])
	oSec01:Cell("PROGRAM" ):SetValue(_aQry[1][6])
	oSec01:PrintLine()


	// itens

	oSec02:Init()

	For _ny := 1 to Len(_aQry)

		oSec02:Cell("PROD"	 ):SetValue(_aQry[_ny][7])
		oSec02:Cell("DESC"	 ):SetValue(_aQry[_ny][8])
		oSec02:Cell("QTD"    ):SetValue(_aQry[_ny][9])
		oSec02:Cell("LOTE"   ):SetValue(_aQry[_ny][10])
		oSec02:Cell("ETQCLI" ):SetValue(_aQry[_ny][12])
		oSec02:Cell("PLTCLI" ):SetValue(_aQry[_ny][13])
		oSec02:PrintLine()

		oReport:IncMeter() //Progresso da barra

	Next _ny

	oSec01:Finish()
	oSec02:Finish()

	RestArea(_aArea)

Return oReport