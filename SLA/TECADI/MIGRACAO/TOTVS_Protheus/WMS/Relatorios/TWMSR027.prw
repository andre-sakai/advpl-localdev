#Include 'Protheus.ch'
#Include "TopConn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSR027                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Relatório de entrada/saída de Containers e Free time    !
!                  !                                                         !
+------------------+---------------------------------------------------------+
!Autor             ! Luiz Poleza                                             !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 02/2017                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSR027()

	Local _aArea   := GetArea()
	
	// grupo de perguntas
	local _cPerg := PadR("TWMSR027",10)
	local _aPerg := {}
	
	// monta a lista de perguntas
	
	aAdd(_aPerg,{"Data inicial?"      ,"D",8,0,"G",,""})                        //mv_par01
	aAdd(_aPerg,{"Data final?"        ,"D",8,0,"G",,""})                        //mv_par02
	aAdd(_aPerg,{"Programação de:"    ,"C",TamSx3("Z3_PROGRAM")[1],0,"G",,""})  //mv_par03
	aAdd(_aPerg,{"Programação até:"   ,"C",TamSx3("Z3_PROGRAM")[1],0,"G",,""})  //mv_par04
	aAdd(_aPerg,{"Tipo de movimento:" ,"N",1,0,"C",{"1 - Ambos","2 - Entrada","3 - Saida"},""}) //mv_par05

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// chama rotina para geracao do relatorio
	oReport := ReportDef(_cPerg)
	oReport:PrintDialog()
	
	RestArea(_aArea)

Return

// ** funcao que gera o relatorio conforme parametros
Static Function ReportDef(mvPerg)

	Local oReport
	Local oSec01 := Nil

	//Montando o objeto oReport
	oReport := TReport():NEW("TWMSR027",;
	 			"Relatório de entrada/saída de Containers e Free time",;
	 			mvPerg,;
	 			{|oReport|PrintReport(oReport)},;
	 			"Este relatório gera uma listagem de todos os movimentos de containers e seu free-time correspondente. A coluna 'dias usados' é a diferença entre a data free time informada e a data de saída ")

	oReport:SetPortrait()
	
	//Declaração da Seção
	oSec01  := TRSection():New(oReport ,;
			   "Cabeçalho",;
			   {"QRY"})
	
	oSec01:SetHeaderPage()
	
	//Celulas
	TRCell():New(oSec01,"Z3_DTMOVIM" ,"QRY","Dt. Mov."	 ,/*Picture*/,10                     ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"Z3_DTSAIDA" ,"QRY","Dt. Saida"  ,/*Picture*/,10                     ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"Z3_TPMOVIM" ,"QRY","Tipo Mov"   ,/*Picture*/,TamSX3("Z3_TPMOVIM")[1],/*lPixel*/,/*{|| code-block de impressao }*/,"CENTER",,"CENTER")
	TRCell():New(oSec01,"Z3_PROGRAM" ,"QRY","Prog."      ,/*Picture*/,TamSX3("Z3_PROGRAM")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"A1_NOME"    ,"QRY","Cliente"    ,/*Picture*/,TamSX3("A1_NOME")[1]   ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"Z3_CONTAIN" ,"QRY","Container"  ,/*Picture*/,TamSX3("Z3_CONTAIN")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"Z3_CONTATU" ,"QRY","Conteúdo"   ,/*Picture*/,TamSX3("Z3_CONTATU")[1],/*lPixel*/,/*{|| code-block de impressao }*/,"CENTER")
	TRCell():New(oSec01,"Z3_TAMCONT" ,"QRY","Tamanho"    ,/*Picture*/,TamSX3("Z3_TAMCONT")[1],/*lPixel*/,/*{|| code-block de impressao }*/,"CENTER",,"CENTER")
	TRCell():New(oSec01,"Z3_TIPCONT" ,"QRY","Tipo"	     ,/*Picture*/,20                     ,/*lPixel*/,/*{|| code-block de impressao }*/,"CENTER",,"CENTER")
	TRCell():New(oSec01,"Z1_DTFREE"	 ,"QRY","Dt. free"   ,/*Picture*/,10                     ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSec01,"DIAS_USADOS","QRY","Dias usados",/*Picture*/,10                     ,/*lPixel*/,/*{|| code-block de impressao }*/)
		
Return(oReport)

Static Function PrintReport(_oReport)

	Local _cQuery := ""
	Local _nAtual :=0
	Local _nTotal :=0

	Local oSec01 := oReport:Section(1)

    //Montagem da Query
	_cQuery := "SELECT Z3_DTMOVIM                           ,              "
	_cQuery += "       Z3_DTSAIDA,                                         "
	_cQuery += "       CASE                                                "
	_cQuery += "         WHEN Z3_TPMOVIM = 'E' THEN 'ENTRADA'              "
	_cQuery += "         ELSE 'SAIDA'                                      "
	_cQuery += "       END                                  Z3_TPMOVIM,    "
	_cQuery += "       Z3_PROGRAM,                                         "
	_cQuery += "       A1_NOME,                                            "
	_cQuery += "       Z3_CONTAIN,                                         "
	_cQuery += "       CASE                                                "
	_cQuery += "         WHEN Z3_CONTATU = 'C' THEN 'CHEIO'                "
	_cQuery += "         ELSE 'VAZIO'                                      "
	_cQuery += "       END                                  Z3_CONTATU,    "
	_cQuery += "       Z3_TAMCONT,                                         "
	_cQuery += "       X5_DESCRI                            Z3_TIPCONT,    "
	_cQuery += "       Z1_DTFREE                            ,              "
	_cQuery += "       Datediff(day, z1_dtfree, z3_dtsaida) AS DIAS_USADOS "
	_cQuery += "FROM   " + RetSqlName("SZ3") + " SZ3                       "
	_cQuery += "       INNER JOIN " + RetSqlName("SZ1") + " SZ1            "
	_cQuery += "               ON " + RetSqlCond("SZ1")                    "
	_cQuery += "                  AND Z1_CODIGO = Z3_PROGRAM               "
	_cQuery += "       INNER JOIN SA1010 SA1                               "
	_cQuery += "               ON " + RetSqlCond("SA1")                    "
	_cQuery += "                  AND A1_COD = Z3_CLIENTE                  "
	_cQuery += "                  AND A1_LOJA = Z3_LOJA                    "
	_cQuery += "       LEFT JOIN SX5010 SX5                                "
	_cQuery += "               ON " + RetSqlCond("SX5")                    "
	_cQuery += "                 AND X5_TABELA = 'ZA'                      "
	_cQuery += "                 AND X5_CHAVE = Z3_TIPCONT                 "
	_cQuery += "WHERE " + RetSqlCond("SZ3")                               
	_cQuery += "       AND Z3_TAMCONT <> 'CS'                              "

	//parâmetros
	
	//data de/para
	_cQuery += "       AND Z3_DTMOVIM BETWEEN '" + DtoS(MV_PAR01) + "' AND  "
	_cQuery += " '" + DtoS(MV_PAR02) + "' "
	
	//programação de/para
	_cQuery += "       AND Z3_PROGRAM BETWEEN '" + MV_PAR03 + "' AND  "
	_cQuery += " '" + MV_PAR04 + "' "

	//filtro do tipo de movimento
	//obs: se for ambos (1) nao acrescenta nada na query, pois ela ja traz ambos por padrão
	If (MV_PAR05 == 2)  // somente entrada
		_cQuery += "AND Z3_TPMOVIM = 'E' "
	Elseif (MV_PAR05 == 3)
		_cQuery += "AND Z3_TPMOVIM = 'S' "
	Endif
		
	//ordenação
	_cQuery += "ORDER  BY Z3_PROGRAM,                                      "
	_cQuery += "          Z3_CONTAIN                                       "

	//padroniza query
	_cQuery := ChangeQuery(_cQuery)
	
	//arquivo para debug
	memowrit("C:\query\twmsr027.txt", _cQuery)

	//Executando consulta e setando o total da régua
	TCQuery _cQuery New Alias "QRY"
	Count to _nTotal
	_oReport:SetMeter(_nTotal)
	
	//Especifica os campos como data
	TCSetField("QRY", "Z3_DTMOVIM", "D")
	TCSetField("QRY", "Z3_DTSAIDA", "D")
	TCSetField("QRY", "Z1_DTFREE", "D")
	
	//inicializa seção
	oSec01:Init()
	QRY->(DbGoTop())
	
	//Enquanto houver dados
	While ! QRY->(Eof())
		//Incrementando a régua
		_nAtual++
		oReport:SetMsgPrint("Imprimindo registro " + cValToChar(_nAtual) + " de " + cValToChar(_nTotal) + "...")
		oReport:IncMeter()
		
		//Imprimindo a linha atual
		oSec01:PrintLine()
		
		QRY->(DbSkip())
	EndDo
	
	oSec01:Finish()
	
	//pula 2 linhas
	_oReport:SkipLine()
	_oReport:SkipLine()
	
	//imprime o total
	_oReport:Say(_oReport:Row(),_oReport:Col(), "Total de registros : " + Str(_nTotal))
	
	//fecha tabela temporaria
	QRY->(DbCloseArea())
	
Return oReport