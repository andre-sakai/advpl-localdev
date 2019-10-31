#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSR029                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Relatório de volumes (produtos) conferidos  durante     !
!                  ! a sequência de conferência de carregamento              !
+------------------+---------------------------------------------------------+
!Autor             ! Luiz Poleza                                             !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 07/2018                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSR029()

	// grupo de perguntas
	local _cPerg := PadR("TWMSR029",10)
	local _aPerg := {}

	private oReport, oSec01, oSec02, oSec03

	// monta a lista de perguntas
	aAdd(_aPerg,{"Num OS:" , "C",TamSx3("Z05_NUMOS")[1] ,0,"G",,""}) //mv_par01

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	//Montando o objeto oReport
	oReport := TReport():NEW("TWMSR029", "Relatório da etapa de Conferencia de carregamento", _cPerg, {|oReport|PrintReport(oReport)},;
	"Este relatório irá listar todos os itens conferidos durante a etapa de conferência de carregamento de determinada ordem de serviço")

	//Declaração da Secção
	oSec01  := TRSection():New(oReport ,"Cabeçalho",{"Z05"})
	oSec02  := TRSection():New(oReport ,"Cabeçalho pedido",{"SC5"})
	oSec03  := TRSection():New(oReport ,"Itens",{"Z07"})

	// desabilita totalizadores
	oSec01:SetTotalInLine( .F. )
	oSec02:SetTotalInLine( .F. )
	oSec03:SetTotalInLine( .F. )

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
	Local _cQryZ16 := ""

	Local _aArea := GetArea()

	// variaveis temporarias
	local _nX      := 0
	local _aQry    :={}
	local _cNumped := ""

	//Seção de impressão
	Private oSec01 := oReport:Section(1)
	Private oSec02 := oReport:Section(2)
	Private oSec03 := oReport:Section(3)

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

	If ( Z05->Z05_TPOPER != "S" )
		MsgStop("Relatório disponível apenas para OS do tipo expedição")
		Return ( .F. )
	EndIf

	// dados da query
	_cQuery := " SELECT Z43_NUMOS,                                                              "
	_cQuery += "        Z43_CLIENT,                                                             "
	_cQuery += "        Z43_LOJA,                                                               "
	_cQuery += "        A1_NOME,                                                                "
	_cQuery += "        C5_ZDOCCLI,                                                             "
	_cQuery += "        C5_ZPEDCLI,                                                             "
	_cQuery += "        C5_ZCLIENT,                                                             "
	_cQuery += "        Rtrim(Ltrim(C5_ZENDENT)) + ' - '                                        "
	_cQuery += "        + Rtrim(Ltrim(C5_ZCIDENT)) + ' - '                                      "
	_cQuery += "        + Rtrim(Ltrim(C5_ZUFENTR))        ENDCLI,                               "
	_cQuery += "        Z07_PEDIDO,                                                             "
	_cQuery += "        Z07_PRODUT,                                                             "
	_cQuery += "        B1_DESC,                                                                "
	_cQuery += "        Cast(Z07_QUANT AS DECIMAL(10, 4)) AS Z07_QUANT,                         "
	_cQuery += "        Z07_LOTCTL,                                                             "
	_cQuery += "        Z07_ETQVOL,                                                             "
	_cQuery += "        Z07_ETQCLI,                                                             "
	_cQuery += "        Z07_PLTCLI                                                              "
	_cQuery += " FROM " + RetSqlTab("Z43")
	_cQuery += "        INNER JOIN " + RetSqlTab("SA1")
	_cQuery += "                ON SA1.D_E_L_E_T_ = ''                                          "
	_cQuery += "                   AND A1_COD = Z43_CLIENT                                      "
	_cQuery += "                   AND A1_LOJA = Z43_LOJA                                       "
	_cQuery += "        INNER JOIN " + RetSqlTab("SC5")
	_cQuery += "                ON " + RetSqlCond("SC5")
	_cQuery += "                   AND C5_NUM = Z43_PEDIDO                                      "
	_cQuery += "                   AND C5_FILIAL = Z43_FILIAL                                   "
	_cQuery += "        INNER JOIN " + RetSqlTab("Z07")
	_cQuery += "                ON " + RetSqlCond("Z07")
	_cQuery += "                   AND Z07_NUMOS = SC5.C5_ZNOSMNT                               "
	_cQuery += "                   AND Z07_SEQOS = (SELECT Max(Z07_SEQOS)                       "
	_cQuery += "                                    FROM   Z07010 Z07SUB                        "
	_cQuery += "                                    WHERE  Z07SUB.Z07_FILIAL = Z07.Z07_FILIAL   "
	_cQuery += "                                           AND Z07SUB.D_E_L_E_T_ = ''           "
	_cQuery += "                                           AND Z07SUB.Z07_NUMOS = Z07.Z07_NUMOS)"
	_cQuery += "        INNER JOIN " + RetSqlTab("SB1")
	_cQuery += "                ON " + RetSqlCond("SB1")
	_cQuery += "                   AND B1_COD = Z07_PRODUT                                      "
	_cQuery += " WHERE " + RetSqlCond("Z43")
	_cQuery += "        AND Z43_NUMOS = '" + MV_PAR01 + "'"
	_cQuery += " ORDER  BY Z07_PEDIDO,"
	_cQuery += "           Z07_PRODUT,"
	_cQuery += "           Z07_LOTCTL "

	// arquivo para debug
	memowrit("C:\query\twmsr029.txt", _cQuery)

	_aQry := U_SqlToVet(_cQuery)

	IF ( Len(_aQry) < 1 )
		Help(,, 'TWMSR029.F01.001',, "Não foram encontrados resultados.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"Revise os parâmetros utilizados para a geração do relatório."}) 
		Return( .F. )
	EndIf

	oReport:SetMeter(Len(_aQry))

	// cria células/campos
	TRCell():New(oSec01,"CODCLI"  ,"","Cód. Cliente"  ,/*Picture*/,TamSX3("A1_COD")[1]     ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"LOJCLI"  ,"","Loja"          ,/*Picture*/,TamSX3("A1_LOJA")[1]    ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"CLIENT"  ,"","Cliente" 	  ,/*Picture*/,TamSX3("A1_NOME")[1]    ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"NUMOS"	  ,"","Nº OS"		  ,/*Picture*/,TamSX3("Z05_NUMOS")[1]  ,/*lPixel*/,/*{|| code-block de impressao }*/)

	TRCell():New(oSec02,"PEDIDO"   ,"","Pedido Tecadi"	    ,/*Picture*/,TamSX3("Z07_PEDIDO")[1]   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"DOCCLI"   ,"","NF Cliente"	        ,/*Picture*/,TamSX3("C5_ZDOCCLI")[1]   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"PEDCLI"   ,"","Ped Cliente"	    ,/*Picture*/,TamSX3("C5_ZPEDCLI")[1]   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"CLIFINAL" ,"","Nome cliente final"	,/*Picture*/,40   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec02,"ENDCLI"   ,"","Endereço cliente"	,/*Picture*/,100   ,/*lPixel*/,/*{|| code-block de impressao }*/)

	// para cliente Ritrama, a ordem de apresentação e nome dos campos são diferentes
	If (_aQry[1][2] == '000573')
		TRCell():New(oSec03,"LOTE"   ,"","Etq. Pallet"    ,/*Picture*/                         ,TamSX3("Z07_LOTCTL")[1] ,/*lPixel*/,/*{|| code-block de impressao }*/)
		TRCell():New(oSec03,"PROD"	 ,"","Cód. Produto"	  ,/*Picture*/                         ,TamSX3("B1_COD")[1]     ,/*lPixel*/,/*{|| code-block de impressao }*/)
		TRCell():New(oSec03,"DESC"	 ,"","Descrição"	  ,/*Picture*/                         ,30                      ,/*lPixel*/,/*{|| code-block de impressao }*/)
		TRCell():New(oSec03,"QTD"    ,"","Quant"          ,PesqPict("SD1","D1_QUANT")          ,30  ,,,       ,,         )
		TRCell():New(oSec03,"PLTCLI" ,"","Lote"  		  ,/*Picture*/                         ,TamSX3("Z07_PLTCLI")[1] ,/*lPixel*/,/*{|| code-block de impressao }*/)
		TRCell():New(oSec03,"ETQCLI" ,"","Etq. Cliente"   ,/*Picture*/                         ,TamSX3("Z07_ETQCLI")[1] ,/*lPixel*/,/*{|| code-block de impressao }*/)
	else
		TRCell():New(oSec03,"PROD"	 ,"","Cód. Produto"	  ,/*Picture*/                         ,TamSX3("B1_COD")[1]     ,/*lPixel*/,/*{|| code-block de impressao }*/)
		TRCell():New(oSec03,"DESC"	 ,"","Descrição"	  ,/*Picture*/                         ,30                      ,/*lPixel*/,/*{|| code-block de impressao }*/)
		TRCell():New(oSec03,"QTD"    ,"","Quant"          ,PesqPict("SD1","D1_QUANT")          ,30  ,,,       ,,         )
		TRCell():New(oSec03,"LOTE"   ,"","Lote"           ,/*Picture*/                         ,TamSX3("Z07_LOTCTL")[1] ,/*lPixel*/,/*{|| code-block de impressao }*/)
		TRCell():New(oSec03,"ETQCLI" ,"","Etq. Cliente"   ,/*Picture*/                         ,TamSX3("Z07_ETQCLI")[1] ,/*lPixel*/,/*{|| code-block de impressao }*/)
		TRCell():New(oSec03,"PLTCLI" ,"","Etq. Pallet"    ,/*Picture*/                         ,TamSX3("Z07_PLTCLI")[1] ,/*lPixel*/,/*{|| code-block de impressao }*/)
	EndIf

	// para cliente Ritrama, cria totalizador que soma a quantidade (por pallet)
	If (_aQry[1][2] == '000573')
		oBreak01 := TRBreak():New(oSec03,oSec03:Cell("LOTE"),"Total do pallet",.F.)
		oSum01   := TRFunction():New(oSec03:Cell("QTD"),NIL,"SUM",oBreak01,/*Titulo*/, "@E 999,999.9999",/*uFormula*/,.F.,.T.)
	EndIf

	// cabeçalho principal
	oSec01:Init()
	oSec01:Cell("NUMOS"	  ):SetValue(_aQry[1][1])
	oSec01:Cell("CODCLI"  ):SetValue(_aQry[1][2])
	oSec01:Cell("LOJCLI"  ):SetValue(_aQry[1][3])
	oSec01:Cell("CLIENT"  ):SetValue(_aQry[1][4])
	oSec01:PrintLine()

	oSec02:Init()
	oSec02:Cell("PEDIDO"  ):SetValue(_aQry[1][9])
	oSec02:Cell("DOCCLI"  ):SetValue(_aQry[1][5])
	oSec02:Cell("PEDCLI"  ):SetValue(_aQry[1][6])
	oSec02:Cell("CLIFINAL"):SetValue(_aQry[1][7])
	oSec02:Cell("ENDCLI"  ):SetValue(_aQry[1][8])
	oSec02:PrintLine()

	// armazena pedido atual
	_cNumped := _aQry[1][9]

	// itens
	oSec03:Init()

	For _nX := 1 to Len(_aQry)

		// se mudou o pedido, imprime o cabeçalho denovo
		If ( _aQry[_nX][9] != _cNumPed )

			_cNumped := _aQry[_nX][9]

			// finaliza página atual e gera uma nova
			oSec01:Finish()
			oSec02:Finish()
			oSec03:Finish()
			oReport:EndPage()
			oReport:StartPage()

			// imprime cabeçalho principal
			oSec01:Init()
			oSec01:PrintLine()

			// imprime dados do pedido
			oSec02:Init()
			oSec02:Cell("PEDIDO"  ):SetValue(_aQry[_nX][9])
			oSec02:Cell("DOCCLI"  ):SetValue(_aQry[_nX][5])
			oSec02:Cell("PEDCLI"  ):SetValue(_aQry[_nX][6])
			oSec02:Cell("CLIFINAL"):SetValue(_aQry[_nX][7])
			oSec02:Cell("ENDCLI"  ):SetValue(_aQry[_nX][8])
			oSec02:PrintLine()

			oSec03:Init()

		EndIf

		oSec03:Cell("PROD"	 ):SetValue(_aQry[_nX][10])
		oSec03:Cell("DESC"	 ):SetValue(_aQry[_nX][11])
		oSec03:Cell("QTD"    ):SetValue(_aQry[_nX][12])
		oSec03:Cell("LOTE"   ):SetValue(_aQry[_nX][13])
		oSec03:Cell("ETQCLI" ):SetValue(_aQry[_nX][15])
		// para cliente Ritrama, pega a informação da numeração do pallet ("número de série") informado na entrada
		// quando foi feita a conferência desta etiqueta, para simplificar e não exigir que bipem denovo na montagem
		If (_aQry[1][2] == '000573')
			// busca informação do palle da conferência
			_cQryZ16 := "SELECT Z16_PLTCLI FROM " + RetSqlTab("Z16") + " WHERE " + RetSqlCond("Z16") + " AND Z16_ORIGEM = 'Z07' AND Z16_ETQVOL = '" + _aQry[_nX][14] + "'" 
			_cQryZ16 := U_FTQuery(_cQryZ16)
			oSec03:Cell("PLTCLI" ):SetValue( _cQryZ16 )
		Else
			oSec03:Cell("PLTCLI" ):SetValue(_aQry[_nX][16])
		EndIf
		oSec03:PrintLine()

		oReport:IncMeter() //Progresso da barra

	Next _nX

	oSec03:Finish()

	RestArea(_aArea)

Return oReport