#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSR025                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Relatório de Conferencia de recebimento de Cargas       !
!                  !                                                         !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe Jose Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/2015                                                !
+------------------+--------------------------------------------------------*/

User Function TWMSR025()

	// grupo de perguntas
	local _cPerg := PadR("TWMSR025",10)
	local _aPerg := {}

	// monta a lista de perguntas
	aAdd(_aPerg,{"Nr. CESV:" ,"C",TamSx3("Z04_CESV")[1] ,0,"G",,""}) //mv_par01
	aAdd(_aPerg,{"Nr OS:"    ,"C",TamSx3("Z07_NUMOS")[1],0,"G",,""}) //mv_par02

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	//Se a rotina não for chamada do ponto de entrada MTA145MNU apresenta tela de Parametros.
	If Funname()  <> "MATA145"
		// chama a tela de parametros
		If ! Pergunte(_cPerg,.T.)
			Return
		EndIf
		If Empty(mv_par01) .And. Empty(mv_par02)
			MsgStop("Favor informar pelo menos 1 parâmetro.","TWMSR025 - Conferencia de recebimento de Cargas")
			Return()
		End
	EndIF

	// chama rotina para geracao do relatorio
	oReport := ReportDef(_cPerg)
	oReport:PrintDialog()

Return

// ** funcao que gera o relatorio conforme parametros
Static Function ReportDef(mvPerg)

	Private oReport

	//Montando o objeto oReport
	oReport := TReport():NEW("TWMSR025", "Relatório de Conferencia de recebimento de Cargas", mvPerg, {|oReport|PrintReport(oReport)}, "Relatório de Conferencia de recebimento de Cargas")

	//Declaração da Secção
	oSec01  := TRSection():New(oReport ,"Cabeçalho",{"SZZ"})
	oSec02  := TRSection():New(oReport ,"Itens",{"SZZ"})
	oSec01:SetTotalInLine(.F.)
	oSec02:SetTotalInLine(.F.)

	TRCell():New(oSec01,"NCERV"	 ,"","Nº Cerv"	           ,/*Picture*/,TamSX3("Z05_CESV")[1] ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"NOS"	 ,"","Nº OS"		       ,/*Picture*/,TamSX3("Z05_NUMOS")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"CLIENT" ,"","Cliente" 		       ,/*Picture*/,TamSX3("A1_NOME")[1]  ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"MOTORI" ,"","Motorista"           ,/*Picture*/,TamSX3("DA4_NOME")[1] ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"TRANSP" ,"","Transportadora"      ,/*Picture*/,TamSX3("A4_NOME")[1]  ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"PLACA"	 ,"","Placa"               ,/*Picture*/,TamSX3("ZZ_PLACA1")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"DATA"	 ,"","Data"+CRLF+"Entrada" ,/*Picture*/,10                    ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"HORA"	 ,"","Hora"+CRLF+"Entrada" ,/*Picture*/,TamSX3("ZZ_HRCHEG")[1],/*lPixel*/,/*{|| code-block de impressao }*/)

	TRCell():New(oSec02,"PROD"	 ,"","Cód. Produto"	         ,/*Picture*/                 ,TamSX3("DB3_CODPRO")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"DESC"	 ,"","Descrição"	         ,/*Picture*/                 ,If (TamSX3("B1_COD")[1] > 15,TamSX3("B1_DESC")[1],21)   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"QTDD"   ,"","Quant"+CRLF+"Digitada" ,PesqPict("SD1","D1_QUANT") ,TamSX3("DB3_QUANT")[1] +3 ,,,       ,,"RIGHT"         )
	TRCell():New(oSec02,"QTDC"   ,"","Quant"+CRLF+"Conferida",PesqPict("SD1","D1_QUANT") ,TamSX3("DB3_QUANT")[1] +3 ,,,       ,,"RIGHT"         )

	oSec01:SetHeaderPage()
	oReport:lParamPage := .F.
Return(oReport)


Static Function PrintReport(oReport)

	Local oBreak01

	// query
	Local _cQuery:= ""

	// variaveis temporarias
	local _nX      := 0
	local _aPosCab :={}

	//Seção de impreção
	Private oSec01 := oReport:Section(1)
	Private oSec02 := oReport:Section(2)

	oBreak01 := TRBreak():New(oSec01,oSec01:Cell("NCERV"),"Total",.F.)

	TRFunction():New(oSec02:Cell('QTDD'	),NIL,"SUM",oBreak01,/*Titulo*/,/*cPicture*/,/*uFormula*/,.F.,.F.)
	TRFunction():New(oSec02:Cell('QTDC'	),NIL,"SUM",oBreak01,/*Titulo*/,/*cPicture*/,/*uFormula*/,.F.,.F.)

	// dados da query
	_cQuery := " SELECT Z05_CESV,"
    _cQuery += " Z05_NUMOS, "
    _cQuery += " A1_NOME, "
    _cQuery += " DA4_NOME, "
    _cQuery += " A4_NOME, "
    _cQuery += " ZZ_PLACA1, "
    _cQuery += " ZZ_DTCHEG, "
    _cQuery += " ZZ_HRCHEG, "
    _cQuery += " Z04_PROD, "
    _cQuery += " B1_DESC, "
    _cQuery += " Z04_QUANT, "
    _cQuery += " ISNULL(( SELECT SUM(Z07_QUANT) FROM "+RetSqlName("Z07")+" Z07 "
    _cQuery += " WHERE "+RetSqlCond("Z07")
    _cQuery += " AND  Z07.Z07_NUMOS = Z05_NUMOS "
    _cQuery += " AND Z07.Z07_PRODUT = Z04_PROD "
    _cQuery += " AND Z07_SEQKIT = Z04_SEQKIT),0) Z07_QUANT "
    // query baseada na Z04 visto que a antiga era baseada na DB3
    _cQuery += " FROM   "+RetSqlName("Z04")+" Z04 "
    _cQuery += " INNER JOIN  "+RetSqlName("Z05")+" Z05 "
    // vinculo da OS e da CARGA
    _cQuery += " ON "+RetSqlCond("Z05") 
    _cQuery += "  AND Z05_CESV = Z04_CESV "
    // registro de entrada do veículo
    _cQuery += " INNER JOIN  "+RetSqlName("SZZ")+" SZZ "
    _cQuery += " ON "+RetSqlCond("SZZ")
    _cQuery += " AND SZZ.ZZ_CESV = Z05.Z05_CESV "
    // dados do produto
    _cQuery += " INNER JOIN  "+RetSqlName("SB1")+" SB1 "
    _cQuery += " ON "+RetSqlCond("SB1")
    _cQuery += " AND SB1.B1_COD = Z04_PROD "
    // dados do cliente
    _cQuery += " INNER JOIN  "+RetSqlName("SA1")+" SA1 "
    _cQuery += " ON "+RetSqlCond("SA1")
    _cQuery += " AND SA1.A1_COD = SZZ.ZZ_CLIENTE "
    _cQuery += " AND SA1.A1_LOJA = SZZ.ZZ_LOJA "
    // dados do motorista
    _cQuery += " LEFT JOIN  "+RetSqlName("DA4")+" DA4 "
    _cQuery += " ON "+RetSqlCond("DA4")
    _cQuery += " AND DA4.DA4_COD = SZZ.ZZ_MOTORIS "
    // dados da transportadora
    _cQuery += " LEFT JOIN  "+RetSqlName("SA4")+" SA4 "
    _cQuery += " ON "+RetSqlCond("SA4")
    _cQuery += " AND SA4.A4_COD = SZZ.ZZ_TRANSP "
    // filtro padrão
    _cQuery += " WHERE  Z04_FILIAL = '103' "
    _cQuery += " AND Z04.D_E_L_E_T_ = '' "

	// se for chamado do do ponto de entrada MTA145MNU.
	If Funname()  == "MATA145"
		_cQuery += " AND Z04_PROCES = '" + DB1->DB1_ZPROGR + "'"
		// senão filtra pelos parametros digitados.
	Else
		If ! Empty(mv_par01)
			_cQuery += " AND Z05.Z05_CESV = '" + mv_par01 + "'"
		EndIf
		If ! Empty(mv_par02)
			_cQuery += " AND Z05.Z05_NUMOS = '" + mv_par02 + "'"
		EndIf
	EndIf
	
	// ordenação pela sequencia do kit para diferenciar dos produtos duplicados
	_cQuery += " ORDER BY Z04_SEQKIT, Z04_PROD "

	// arquivo para debug
	memowrit("C:\query\twmsr025.txt", _cQuery)

	_aPosCab := U_SqlToVet(_cQuery)

	oReport:SetMeter(Len(_aPosCab))

	If Len(_aPosCab) > 0
		_ContServ := _aPosCab[1][1]
		oSec01:Init()
		oSec01:Cell("NCERV"  ):SetValue(_aPosCab[1][1])
		oSec01:Cell("NOS"    ):SetValue(_aPosCab[1][2])
		oSec01:Cell("CLIENT" ):SetValue(_aPosCab[1][3] )
		oSec01:Cell("MOTORI" ):SetValue(_aPosCab[1][4])
		oSec01:Cell("TRANSP" ):SetValue(_aPosCab[1][5])
		oSec01:Cell("PLACA"  ):SetValue(_aPosCab[1][6])
		oSec01:Cell("DATA"   ):SetValue(Stod(Alltrim(_aPosCab[1][7])))
		oSec01:Cell("HORA"   ):SetValue(_aPosCab[1][8])
		oSec01:PrintLine()
	EndIf
	oSec02:Init()
	For _ny := 1 to Len(_aPosCab)

		oSec02:Cell("PROD"   ):SetValue(_aPosCab[_ny][9])
		oSec02:Cell("DESC"   ):SetValue(_aPosCab[_ny][10])
		oSec02:Cell("QTDD"   ):SetValue(_aPosCab[_ny][11])
		oSec02:Cell("QTDC"   ):SetValue(_aPosCab[_ny][12])
		oSec02:PrintLine()
		oReport:IncMeter() //Progresso da barra

	Next _ny
	oSec01:Finish()
	oSec02:Finish()
Return oReport