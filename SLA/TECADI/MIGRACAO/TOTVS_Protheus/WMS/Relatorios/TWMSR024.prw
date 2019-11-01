#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSR024                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Relatório de Posição de Estoque por Categoria           !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe Jose Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSR024()

	// grupo de perguntas
	local _cPerg := PadR("TWMSR024",10)
	local _aPerg := {}
	local _lDadosOk := .t.

	// monta a lista de perguntas
	aAdd(_aPerg,{"Armazém De:"     ,"C",TamSx3("BE_LOCAL")[1],0,"G",             ,"Z12"}) //mv_par01
	aAdd(_aPerg,{"Armazém Até:"    ,"C",TamSx3("BE_LOCAL")[1],0,"G",             ,"Z12"}) //mv_par02
	aAdd(_aPerg,{"Produto De:"     ,"C",TamSx3("B1_COD")[1]  ,0,"G",             ,"SB1"}) //mv_par03
	aAdd(_aPerg,{"Produto Até:"    ,"C",TamSx3("B1_COD")[1]  ,0,"G",             ,"SB1"}) //mv_par04
	aAdd(_aPerg,{"Grupo De:"       ,"C",TamSx3("B1_GRUPO")[1],0,"G",             ,"SBM"}) //mv_par05
	aAdd(_aPerg,{"Grupo Até:"      ,"C",TamSx3("B1_GRUPO")[1],0,"G",             ,"SBM"}) //mv_par06
	aAdd(_aPerg,{"Cliente De:"     ,"C",TamSx3("A1_COD")[1]  ,0,"G",             ,"SA1"}) //mv_par07
	aAdd(_aPerg,{"Loja De:"        ,"C",TamSx3("A1_LOJA")[1] ,0,"G",             ,""   }) //mv_par08
	aAdd(_aPerg,{"Cliente Até:"    ,"C",TamSx3("A1_COD")[1]  ,0,"G",             ,"SA1"}) //mv_par09
	aAdd(_aPerg,{"Loja Até:"       ,"C",TamSx3("A1_LOJA")[1] ,0,"G",             ,""   }) //mv_par10
	aAdd(_aPerg,{"Imp. Endereços?" ,"N",1                    ,0,"C",{"Sim","Não"},""   }) //mv_par11

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// chama a tela de parametros
	If ! Pergunte(_cPerg,.T.)
		Return
	EndIf

	//Tipo de Estoque
	Private _aTipEst  := {}

	// chama rotina para geracao do relatorio
	oReport := ReportDef(_cPerg, @_lDadosOk)

	// se ha dados para impressao
	If (_lDadosOk)
		oReport:PrintDialog()
	EndIf

Return

// ** funcao que gera o relatorio conforme parametros
Static Function ReportDef(mvPerg, mvDadosOk)

	// query
	Local _cQuery   := ""
	//Descição Tipo de Estoque
	Local _cDescTip := ""
	// variaveis temporarias
	local _nX       := 0

	Private oReport
	Private oSec01

	//Montando o objeto oReport
	oReport := TReport():NEW("TWMSR024", "Relatório de Posição de Estoque por Tipo de Estoque", mvPerg, {|oReport|PrintReport(oReport)}, "Este relatório irá imprimir relatórios de Posição de Estoque por Tipo de Estoque.")

	If TamSX3("B1_COD")[1] > 15
		oReport:SetLandscape()
	EndIf

	//Declaração da Secção
	oSec01  := TRSection():New(oReport ,"Saldos em Estoque",{"SB2","SB1","SB2"})
	oSec01:SetTotalInLine(.F.)

	// definicoes das colunas para sesssao 01
	TRCell():New(oSec01,"TIPREG"	,"","Tipo"                      ,/*Picture*/,3,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"CODIGO"	,"","Código"+CRLF+"Endereço"    ,/*Picture*/,TamSX3("B1_COD")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"DESCRI"	,"","Descrição"+CRLF+"Lote"     ,/*Picture*/,TamSX3("B1_DESC")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"PLTCLI"	,"","Pallet"+CRLF+"Cliente"     ,/*Picture*/,TamSX3("Z16_PLTCLI")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"ARMAZEM"	,"","Arm." 			            ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"QTDTOT"    ,"","Quant"+CRLF+"FISCAL"       ,PesqPict("SB2","B2_QATU")    ,TamSX3("B2_QATU")[1]     ,,,       ,,"RIGHT"         )
	TRCell():New(oSec01,"QTDDIS"    ,"","Quant"+CRLF+"DISPONIVEL"   ,PesqPict("SB2","B2_QATU")    ,TamSX3("B2_QATU")[1]     ,,,       ,,"RIGHT"         )
	TRCell():New(oSec01,"QUANTE"	,"","Quant"+CRLF+"RECEBIMENTO"  ,PesqPict("SB2","B2_QACLASS") ,TamSX3("B2_QACLASS")[1]  ,,,       ,,"RIGHT"         )
	TRCell():New(oSec01,"QUANTR"	,"","Quant"+CRLF+"RESERVA"      ,PesqPict("SB2","B2_RESERVA") ,TamSX3("B2_RESERVA")[1]  ,,,       ,,"RIGHT"         )
	TRCell():New(oSec01,"QTDPED"	,"","Quant"+CRLF+"PED.VENDA"    ,PesqPict("SB2","B2_QPEDVEN") ,TamSX3("B2_QPEDVEN")[1]  ,,,       ,,"RIGHT"         )

	//Limpando variavel responsavel pelas colunas dinamicas.
	_aTipEst := {}

	// montando SQL para Colunas dinamicas conforme tipo de estoques na tabela Z16
	_cQuery := " SELECT Z16_TPESTO "
	// cad. produtos
	_cQuery += " FROM   "+RetSqlTab("SB1")+" (NOLOCK) "
	// saldo por produto
	_cQuery += "        INNER JOIN "+RetSqlTab("SB2")+" (NOLOCK) "
	_cQuery += "                ON "+RetSqlCond("SB2")
	_cQuery += "                   AND B2_LOCAL BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' "
	_cQuery += "                   AND B2_COD = B1_COD "
	_cQuery += "                   AND B2_QATU <> 0 "
	// saldo por palete
	_cQuery += "        LEFT JOIN "+RetSqlTab("Z16")+" (NOLOCK) "
	_cQuery += "               ON "+RetSqlCond("Z16")
	_cQuery += "                  AND Z16_CODPRO = B2_COD "
	_cQuery += "                  AND Z16_SALDO > 0 "
	// filtro padrao
	_cQuery += " WHERE  "+RetSqlCond("SB1")
	_cQuery += "        AND B1_COD BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' "
	_cQuery += "        AND B1_GRUPO BETWEEN '"+mv_par05+"' AND '"+mv_par06+"' "
	_cQuery += "        AND Z16_TPESTO IS NOT NULL "
	// cad. siga do cliente
	_cQuery += "        AND B1_GRUPO IN (SELECT DISTINCT A1_SIGLA "
	_cQuery += "                         FROM   "+RetSqlTab("SA1")+" (NOLOCK) "
	_cQuery += "                         WHERE  "+RetSqlCond("SA1")
	_cQuery += "                                AND A1_COD BETWEEN '"+mv_par07+"' AND '"+mv_par09+"' "
	_cQuery += "                                AND A1_LOJA BETWEEN '"+mv_par08+"' AND '"+mv_par10+"') "
	// agrupa informacoes
	_cQuery += " GROUP  BY Z16_TPESTO "
	// ordem dos dadso
	_cQuery += " ORDER  BY Z16_TPESTO "

	memowrit("c:\query\twmsr024_aTipEst.txt", _cQuery)

	// carrega resultado do SQL na variavel.
	_aTipEst := U_SqlToVet(_cQuery)

	// valida tipo de estoque
	If (Len(_aTipEst) == 0)
		// mensagem
		MsgInfo("Não há dados para impressão com estes parâmetros.")
		// variavel de controle
		mvDadosOk := .f.
		// retorno
		Return(oReport)
	EndIf

	// Adiciona colunas conforme retorno do SQL.
	For _nX := 1 to Len(_aTipEst)

		// descricao do tipo de estoque
		_cDescTip := Upper(Alltrim(Posicione("Z34",1, xFilial("Z34")+_aTipEst[_nx] ,"Z34_DESCRI")))

		// inclui coluna para sessao 01
		TRCell():New(oSec01,"D" + Alltrim(_aTipEst[_nx]),"","Quant"+CRLF+_cDescTip,PesqPict("SB2","B2_RESERVA"),TamSX3("B2_RESERVA")[1],,,,,"RIGHT")

	Next _nX

	// seta cabecalho
	oSec01:SetHeaderPage()
	oReport:lParamPage := .F.

Return(oReport)

// ** funcao que gera o relatorio
Static Function PrintReport(oReport)

	Local oBreak01

	// query
	Local _cQuery:= ""

	// variaveis temporarias
	local _nTpEst  := 0
	local _ny      := 0
	Local _aPosEstoque := {}

	// posicao ultimo campo fixo
	local _nPosUltCmp := 11

	//Seção de impreção
	Private oSec01 := oReport:Section(1)

	// totalizador
	oBreak01 := TRBreak():New(oSec01,oSec01:Cell("ARMAZEM"),"Total Geral",.F.)

	TRFunction():New(oSec01:Cell('QTDTOT'	),NIL,"SUM",oBreak01,/*Titulo*/,/*cPicture*/,/*uFormula*/,.F.,.F.,,,{ || (oSec01:Cell("TIPREG"):GetValue() == "SLD") } )
	TRFunction():New(oSec01:Cell('QTDDIS'	),NIL,"SUM",oBreak01,/*Titulo*/,/*cPicture*/,/*uFormula*/,.F.,.F.,,,{ || (oSec01:Cell("TIPREG"):GetValue() == "SLD") } )
	TRFunction():New(oSec01:Cell('QUANTE'	),NIL,"SUM",oBreak01,/*Titulo*/,/*cPicture*/,/*uFormula*/,.F.,.F.,,,{ || (oSec01:Cell("TIPREG"):GetValue() == "SLD") } )
	TRFunction():New(oSec01:Cell('QUANTR'	),NIL,"SUM",oBreak01,/*Titulo*/,/*cPicture*/,/*uFormula*/,.F.,.F.,,,{ || (oSec01:Cell("TIPREG"):GetValue() == "SLD") } )
	TRFunction():New(oSec01:Cell('QTDPED'	),NIL,"SUM",oBreak01,/*Titulo*/,/*cPicture*/,/*uFormula*/,.F.,.F.,,,{ || (oSec01:Cell("TIPREG"):GetValue() == "SLD") } )

	//Seleciona os tipos de estoque.
	For _nTpEst := 1 to Len(_aTipEst)
		TRFunction():New(oSec01:Cell("D" + Alltrim(_aTipEst[_nTpEst])),NIL,"SUM",oBreak01,/*Titulo*/,/*cPicture*/,/*uFormula*/,.F.,.F.)
	Next _nTpEst

	//SQL inicio
	_cQuery := " SELECT 'SLD'                 TMP_TIPO, "
	_cQuery += "        BF_LOCALIZ, "
	_cQuery += "        B1_COD, "
	_cQuery += "        B1_DESC, "
	_cQuery += "        '' PLT_CLI, "
	_cQuery += "        B2_LOCAL              TMP_ARMAZ, "
	_cQuery += "        B2_QATU, "
	_cQuery += "        B2_QACLASS, "
	_cQuery += "        B2_RESERVA, "
	_cQuery += "        B2_QPEDVEN, "
//	_cQuery += "        B2_QATU - B2_QACLASS - B2_QPEDVEN - B2_RESERVA - B2_QEMP, "
	_cQuery += "        (B2_QATU - B2_QACLASS - B2_QPEDVEN - B2_RESERVA - B2_QEMP) AS 'SLD_DISP', "
	For _nTpEst := 1 to Len(_aTipEst)
		_cQuery += "        COALESCE(["+_aTipEst[_nTpEst]+"], 0) TE"+_aTipEst[_nTpEst] + IIF(_nTpEst < Len(_aTipEst),", ","")
	Next _nTpEst
	_cQuery += " FROM   (SELECT ''             BF_LOCALIZ, "
	_cQuery += "                B1_COD, "
	_cQuery += "                B1_DESC, "
	_cQuery += "                B2_LOCAL, "
	_cQuery += "                B2_QATU, "
	_cQuery += "                B2_QACLASS, "
	_cQuery += "                B2_RESERVA, "
	_cQuery += "                B2_QEMP, "
	_cQuery += "                B2_QPEDVEN, "
	_cQuery += "                Z16_TPESTO, "
	_cQuery += "                Sum(Z16_SALDO) Z16_SALDO "
	// cadastro de produtos
	_cQuery += "         FROM   "+RetSqlTab("SB1")+" (NOLOCK) "
	// saldo por armazem
	_cQuery += "                INNER JOIN "+RetSqlTab("SB2")+" (NOLOCK) "
	_cQuery += "                        ON "+RetSqlCond("SB2")
	_cQuery += "                           AND B2_LOCAL BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' "
	_cQuery += "                           AND B2_COD = B1_COD "
	_cQuery += "                           AND B2_QATU <> 0 "
	// composicao do palete
	_cQuery += "                LEFT JOIN "+RetSqlTab("Z16")+" (NOLOCK) "
	_cQuery += "                       ON "+RetSqlCond("Z16")
	_cQuery += "                          AND Z16_LOCAL = B2_LOCAL "
	_cQuery += "                          AND Z16_CODPRO = B2_COD "
	_cQuery += "                          AND Z16_SALDO > 0 "
	_cQuery += "                          AND Z16_PEDIDO = '' "
	// filtro padrao
	_cQuery += "         WHERE  "+RetSqlCond("SB1")
	// cad. sigla do cliente
	_cQuery += "                AND B1_GRUPO IN (SELECT DISTINCT A1_SIGLA "
	_cQuery += "                                 FROM   "+RetSqlTab("SA1")+" (NOLOCK) "
	_cQuery += "                                 WHERE  "+RetSqlCond("SA1")
	_cQuery += "                                        AND A1_COD BETWEEN '"+mv_par07+"' AND '"+mv_par09+"' "
	_cQuery += "                                        AND A1_LOJA BETWEEN '"+mv_par08+"' AND '"+mv_par10+"') "
	// codigo de produto
	_cQuery += "                AND B1_COD BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' "
	// grupos
	_cQuery += "                AND B1_GRUPO BETWEEN '"+mv_par05+"' AND '"+mv_par06+"' "
	// ordem dos dados
	_cQuery += "         GROUP  BY B1_COD, "
	_cQuery += "                   B1_DESC, "
	_cQuery += "                   B2_LOCAL, "
	_cQuery += "                   B2_QATU, "
	_cQuery += "                   B2_QACLASS, "
	_cQuery += "                   B2_RESERVA, "
	_cQuery += "                   B2_QPEDVEN, "
	_cQuery += "                   B2_QEMP, "
	_cQuery += "                   Z16_TPESTO) REL_TIPO_ESTOQUE "
	_cQuery += "        PIVOT ( Sum(Z16_SALDO) "
	_cQuery += "              FOR Z16_TPESTO IN ("
	For _nTpEst := 1 to Len(_aTipEst)
		_cQuery += "                                 ["+_aTipEst[_nTpEst]+"]" + IIF(_nTpEst < Len(_aTipEst),", ","")
	Next _nTpEst
	_cQuery += "                                ) ) TAB_SALDO_PRODUTO "

	// verifica se imprime enderecos
	If (mv_par11 == 1)
		_cQuery += " UNION ALL "
		_cQuery += " SELECT 'END'                 TMP_TIPO, "
		_cQuery += "        BF_LOCALIZ, "
		_cQuery += "        B1_COD, "
		_cQuery += "        B1_DESC, "
		_cQuery += "        Z16_PLTCLI PLT_CLI, "
		_cQuery += "        BF_LOCAL              TMP_ARMAZ, "
		_cQuery += "        0, "
		_cQuery += "        0, "
		_cQuery += "        0, "
		_cQuery += "        0, "
		For _nTpEst := 1 to Len(_aTipEst)
			_cQuery += "        COALESCE(["+_aTipEst[_nTpEst]+"], 0) " + IIF(_nTpEst < Len(_aTipEst)," + "," AS 'SLD_DISP', ")
		Next _nTpEst
		For _nTpEst := 1 to Len(_aTipEst)
			_cQuery += "        COALESCE(["+_aTipEst[_nTpEst]+"], 0) TE"+_aTipEst[_nTpEst] + IIF(_nTpEst < Len(_aTipEst),", ","")
		Next _nTpEst
		_cQuery += " FROM   (SELECT BF_LOCALIZ, "
		_cQuery += "                B1_COD, "
		_cQuery += "                BF_LOTECTL     B1_DESC, "
		_cQuery += "                BF_LOCAL, "
		_cQuery += "                BF_QUANT, "
		_cQuery += "                Z16_PLTCLI, "
		_cQuery += "                0              B2_QACLASS, "
		_cQuery += "                0              B2_RESERVA, "
		_cQuery += "                0              B2_QPEDVEN, "
		_cQuery += "                Z16_TPESTO, "
		_cQuery += "                Sum(Z16_SALDO) Z16_SALDO "
		_cQuery += "         FROM   "+RetSqlTab("SB1")+" (NOLOCK) "
		_cQuery += "                INNER JOIN "+RetSqlTab("SBF")+" (NOLOCK) "
		_cQuery += "                        ON "+RetSqlCond("SBF")
		_cQuery += "                           AND BF_LOCAL BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' "
		_cQuery += "                           AND BF_PRODUTO = B1_COD "
		_cQuery += "                LEFT JOIN "+RetSqlTab("Z16")+" (NOLOCK) "
		_cQuery += "                       ON "+RetSqlCond("Z16")
		_cQuery += "                          AND Z16_LOCAL = BF_LOCAL "
		_cQuery += "                          AND Z16_ENDATU = BF_LOCALIZ "
		_cQuery += "                          AND Z16_CODPRO = BF_PRODUTO "
		_cQuery += "                          AND Z16_LOTCTL = BF_LOTECTL "
		_cQuery += "                          AND Z16_SALDO > 0 "
		_cQuery += "         WHERE  "+RetSqlCond("SB1")
		_cQuery += "                AND B1_COD BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' "
		_cQuery += "                AND B1_GRUPO BETWEEN '"+mv_par05+"' AND '"+mv_par06+"' "
		// cad. sigla do cliente
		_cQuery += "                AND B1_GRUPO IN (SELECT DISTINCT A1_SIGLA "
		_cQuery += "                                 FROM   "+RetSqlTab("SA1")+" (NOLOCK) "
		_cQuery += "                                 WHERE  "+RetSqlCond("SA1")
		_cQuery += "                                        AND A1_COD BETWEEN '"+mv_par07+"' AND '"+mv_par09+"' "
		_cQuery += "                                        AND A1_LOJA BETWEEN '"+mv_par08+"' AND '"+mv_par10+"') "
		// ordem dos dados
		_cQuery += "         GROUP  BY B1_COD, "
		_cQuery += "                   BF_LOCALIZ, "
		_cQuery += "                   BF_LOTECTL, "
		_cQuery += "                   BF_LOCAL, "
		_cQuery += "                   BF_QUANT, "
		_cQuery += "                   Z16_PLTCLI, "
		_cQuery += "                   Z16_TPESTO) REL_TIPO_ESTOQUE "
		_cQuery += "        PIVOT ( Sum(Z16_SALDO) "
		_cQuery += "              FOR Z16_TPESTO IN ("
		For _nTpEst := 1 to Len(_aTipEst)
			_cQuery += "                                 ["+_aTipEst[_nTpEst]+"]" + IIF(_nTpEst < Len(_aTipEst),", ","")
		Next _nTpEst
		_cQuery += "                                ) ) TAB_SALDO_ENDERECO "
	EndIf

	// ordem dos dados
	_cQuery += " ORDER BY B1_COD, BF_LOCALIZ, PLT_CLI "

	MemoWrit("c:\query\twmsr024_PrintReport.txt", _cQuery)

	_aPosEstoque := U_SqlToVet(_cQuery)

	// define regua de processamento
	oReport:SetMeter(Len(_aPosEstoque))

	// inicia impressao
	oSec01:Init()

	// varre todos os registros por produto
	For _ny := 1 to Len(_aPosEstoque)

		// imprime dados do registro principal do saldo
		oSec01:Cell("TIPREG" ):SetValue(_aPosEstoque[_ny][1])

		// imprime codigo do produto
		If (_aPosEstoque[_ny][1] == "SLD")
			oSec01:Cell("CODIGO" ):SetValue(Alltrim(_aPosEstoque[_ny][3]))
			// endereco do produto
		ElseIf (_aPosEstoque[_ny][1] == "END")
			oSec01:Cell("CODIGO" ):SetValue(Alltrim(_aPosEstoque[_ny][2]))
		EndIf

		// imprime descricao do produto
		oSec01:Cell("DESCRI" ):SetValue(Alltrim(_aPosEstoque[_ny][4]))
		// imprime pallet do cliente
		oSec01:Cell("PLTCLI" ):SetValue(Alltrim(_aPosEstoque[_ny][5]))
		// armazem
		oSec01:Cell("ARMAZEM"):SetValue(Alltrim(_aPosEstoque[_ny][6]))
		// quantidade total
		oSec01:Cell("QTDTOT" ):SetValue(_aPosEstoque[_ny][7])
		// quantidade a classificar
		oSec01:Cell("QUANTE" ):SetValue(_aPosEstoque[_ny][8])
		// quantidade reserva
		oSec01:Cell("QUANTR" ):SetValue(_aPosEstoque[_ny][9])
		// quantidade em pedidos de venda
		oSec01:Cell("QTDPED" ):SetValue(_aPosEstoque[_ny][10])
		// quantidade disponível para solicitar
		oSec01:Cell("QTDDIS" ):SetValue(_aPosEstoque[_ny][11])

		// varre todos os tipos de estoque. Deve ser dessa forma para preencher 0 quando nao tem saldo, senao o relatorio duplicado os valores
		For _nTpEst := 1 to Len(_aTipEst)

			// imprime total por tipo de estoque
			oSec01:Cell("D" + Alltrim(_aTipEst[_nTpEst])):SetValue( _aPosEstoque[_ny][ _nPosUltCmp + _nTpEst] )

		Next _nTpEst

		// imprime linha do saldo
		oSec01:PrintLine()

		//Progresso da barra
		oReport:IncMeter()

	Next _ny

	// finaliza impressao
	oSec01:Finish()

Return oReport