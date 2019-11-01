#INCLUDE "rwmake.ch"
#INCLUDE "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Consulta de Relação de Ordem de Serviço Analitico e     !
!                  ! Sintetico.                                              !
+------------------+---------------------------------------------------------+
!Autor             ! Rafael de Souza                                         !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 10/2012                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSR011


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de Variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Local _aPerg := {}


	local _cPerg := PadR("TWMSR011",10)

	Local cDesc1         := "Este programa tem como objetivo imprimir relatorio "
	Local cDesc2         := "de acordo com os parametros informados pelo usuario."
	Local cDesc3         := "Relação de Ordens de Serviço"
	Local cPict          := ""
	Local titulo       := "Relação de Ordens de Serviço"
	Local nLin         := 100
	//Posição   		  //0       9             23              39           54          66       75         86       95      103                                        150
	Local Cabec1       := "Tp Mov.  Número OS     Contêiner       Dt Emissao   Dt Inic     Hr Ini   Dt Fim     Hr Fim   Progr   Cód. Cliente                               Conferente     "
	Local Cabec2       := "  Cod.  Serviço                                                           Situação"
	Local imprime      := .T.
	Local aOrd := {}
	Private _CCODCLI := ""
	Private lEnd         := .F.
	Private lAbortPrint  := .F.
	Private CbTxt        := ""
	Private limite           := 132
	Private tamanho          := "M"
	Private nomeprog         := "TWMSR011" // Coloque aqui o nome do programa para impressao no cabecalho
	Private nTipo            := 18
	Private aReturn          := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
	Private nLastKey        := 0
	Private cbtxt      := Space(10)
	Private cbcont     := 00
	Private CONTFL     := 01
	Private m_pag      := 01
	Private wnrel      := "TWMSR011" // Coloque aqui o nome do arquivo usado para impressao em disco

	/*Private cString := "SZ6"
	dbSelectArea("SZ6")
	dbSetOrder(1)*/

	// monta a lista de perguntas
	aAdd(_aPerg,{"Programação De ?" ,"C",TamSx3("Z1_CODIGO")[1],0,"G",,"SZ1"}) //mv_par01
	aAdd(_aPerg,{"Programação Até ?" ,"C",TamSx3("Z1_CODIGO")[1],0,"G",,"SZ1"}) //mv_par02
	aAdd(_aPerg,{"Tipo Layout ?" ,"N",1,0,"C",{"Analitico","Sintetico"},""}) //mv_par03
	aAdd(_aPerg,{"Cliente De ?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par04
	aAdd(_aPerg,{"Cliente Até ?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par05
	aAdd(_aPerg,{"Dt Emissão De ?" ,"D",8,0,"G",,""}) //mv_par06
	aAdd(_aPerg,{"Dt Emissão Até ?" ,"D",8,0,"G",,""}) //mv_par07
	aAdd(_aPerg,{"Cod. Serviços" ,"C",30,0,"G",,""}) //mv_par08
	aAdd(_aPerg,{"Tp da OS" ,"C",5,0,"G",,""}) //mv_par09
	aAdd(_aPerg,{"Numero OS de?" ,"C",TamSx3("Z6_NUMOS")[1],0,"G",,"SZ6"}) //mv_par10
	aAdd(_aPerg,{"Numero OS  Até ?" ,"C",TamSx3("Z6_NUMOS")[1],0,"G",,"SZ6"}) //mv_par11
	aAdd(_aPerg,{"Pedido de Venda de?" ,"C",TamSx3("C5_NUM")[1],0,"G",,""}) //mv_par12
	aAdd(_aPerg,{"Pedido de Venda  Até ?" ,"C",TamSx3("C5_NUM")[1],0,"G",,""}) //mv_par13
	aAdd(_aPerg,{"Status Faturamento ?" ,"N",1,0,"C",{"Sim","Nao","Ambos"},""}) //mv_par14
	aAdd(_aPerg,{"Exportar Excel ?" ,"N",1,0,"C",{"Sim","Nao"},""}) //mv_par15


	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	If ! Pergunte(_cPerg,.t.)
		Return
	EndIf

	wnrel := SetPrint("",NomeProg,"TWMSR011",@titulo,cDesc1,cDesc2,cDesc3,.F.,aOrd,.F.,Tamanho,,.F.)

	If nLastKey == 27
		Return
	Endif

	SetDefault(aReturn,"")

	If nLastKey == 27
		Return
	Endif


	nTipo := If(aReturn[4]==1,15,18)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Processamento. RPTSTATUS monta janela com a regua de processamento. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	RptStatus({|| sfImpressao(Cabec1,Cabec2,Titulo,nLin) },Titulo)

Return

Static Function sfImpressao(Cabec1,Cabec2,Titulo,nLin)
	local _nCont := 0
	Local nOrdem
	local _cQuery

	// controle de coluna de impressao
	local _nCol := 0

	// controle de quebra de OS
	local _cQbrOS := ""

	//----------------------------------------------------------   SQL   ----------------------------------------------------------------------------
	_cQuery := "SELECT Z6_NUMOS, Z6_CODIGO, Z6_CONTAIN, Z6_EMISSAO, Z6_STATUS, Z6_CLIENTE, Z6_LOJA, Z6_DATAINI, Z6_HORAINI, Z6_DATAFIM, Z6_HORAFIM, Z6_TIPOMOV, Z6_PEDIDO, A1_NOME, "
	_cQuery += "(SELECT TOP 1 DCD_NOMFUN "
	_cQuery += "FROM " + RetSqlName("SZ8") + " SZ8 "
	_cQuery += "INNER JOIN " + RetSqlName("DCD") + " DCD ON " + RetSqlCond("DCD") + "AND DCD_CODFUN = Z8_RECHUM "
	_cQuery += "WHERE  Z8_FILIAL = Z6_FILIAL "
	_cQuery += "AND Z8_NUMOS = Z6_NUMOS "
	_cQuery += "AND Z8_FUNCAO = 'WMS02') NOME_CONF "
	// opcao 1 = analitico
	If mv_par03 == 1
		_cQuery += ",Z7_CODATIV, Z7_QUANT, Z7_DTFATAT, "
		_cQuery += "CONVERT(VarChar(8000), CONVERT(VarBinary(8000), Z6_OBSERVA)) AS Z6_OBSERVA "
	Endif

	_cQuery += "FROM "+RetSqlName("SZ6")+" AS SZ6 "

	// opcao 1 = analitico
	If mv_par03 == 1
		_cQuery += "INNER JOIN "+RetSqlName("SZ7")+" SZ7 ON "+RetSqlCond("SZ7")+" AND Z7_NUMOS = Z6_NUMOS "
		If (!Empty(mv_par08))
			_cQuery += "AND Z7_CODATIV IN "+FormatIn(AllTrim(mv_par08),";")+" "
		Endif
		If mv_par14 == 1
			_cQuery += "AND Z7_DTFATAT != ' ' "
		ElseIf mv_par14 == 2
			_cQuery += "AND Z7_DTFATAT = ' ' "
		EndIf
	Endif

	_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 ON "+RetSqlCond("SA1")+" AND Z6_CLIENTE = A1_COD AND Z6_LOJA = A1_LOJA "

	// filtro do cabecalho da OS
	_cQuery += "WHERE "+RetSqlCond("SZ6")+" "
	_cQuery += "AND Z6_CODIGO  BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' "
	_cQuery += "AND Z6_CLIENTE BETWEEN '"+mv_par04+"' AND '"+mv_par05+"' "
	_cQuery += "AND Z6_EMISSAO BETWEEN '"+DtoS(mv_par06)+"' AND '"+DtoS(mv_par07)+"' "

	//validação do campo do tipo de OS, entrada,interna, saída
	if (!Empty(mv_par09))
		_cQuery += "AND Z6_TIPOMOV IN "+FormatIn(AllTrim(mv_par09),";")+" "
	endif

	_cQuery += "AND Z6_NUMOS BETWEEN '"+mv_par10+"' AND '"+mv_par11+"' "
	_cQuery += "AND Z6_PEDIDO BETWEEN '"+mv_par12+"' AND '"+mv_par13+"' "

	If mv_par14 == 1
		_cQuery += "AND Z6_STATUS = 'P' "
	ElseIf mv_par14 == 2
		_cQuery += "AND Z6_STATUS IN ('F','P') "
	EndIf
	_cQuery += "ORDER BY Z6_CODIGO, Z6_NUMOS"

	//----------------------------------------------------------   SQL   ----------------------------------------------------------------------------

	memowrit("c:\query\TWMSR011_sfImpressao.txt",_cQuery)

	// !=0 para poder entrar mais de uma vez no relatorio.
	If select("_QRYOS")!= 0
		dbSelectArea("_QRYOS")
		dbCloseArea()
	EndIf

	// executa a query e joga pro alias
	dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),"_QRYOS",.F.,.T.)

	dbSelectArea("_QRYOS")
	_QRYOS->(dbGoTop())

	//condição para exportar para Excel
	if mv_par15 == 1
		SfExpExcel(Titulo)
		return
	EndIf

	/*dbSelectArea(cString)
	dbSetOrder(1) // 1- Z06_FILIAL + Z06_NUMOS
	dbSeek( xFilial("Z06") )*/

	SetRegua(100)

	While _QRYOS->(!EOF()) // .and. SZ6->Z6_FILIAL == xFilial("Z06")


		IncRegua()

		//Verifica o cancelamento pelo usuario...
		If lAbortPrint
			@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
			Exit
		Endif


		//Impressao do cabecalho do relatorio. . .     
		If nLin > 58 // Salto de Página. Neste caso o formulario tem 55 linhas...
			Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
			nLin := 9
		Endif

		/*Coloque aqui a logica da impressao do seu programa...
		Utilize PSAY para saida na impressora. Por exemplo:
		@nLin,00 PSAY SA1->A1_COD
		If SZ6->Z6_CODIGO >= mv_par01 .and. SZ6->Z6_CODIGO <= mv_par02 */

		// controle de quebra de OS
		If (_cQbrOS != _QRYOS->Z6_NUMOS)

			// reinicio controle
			_nCol := 0

			@nLin,_nCol pSay __PrtThinLine()
			//controle de linhas
			nLin ++
			//imprime no relatorio o tipo da movimentação.
			If _QRYOS->Z6_TIPOMOV == "E"
				@ nLin,_nCol pSay "ENTRADA"
			EndIf

			If _QRYOS->Z6_TIPOMOV == "I"
				@ nLin,_nCol pSay "INTERNA"
			EndIf

			If _QRYOS->Z6_TIPOMOV == "S"
				@ nLin,_nCol pSay "SAIDA"
			EndIf

			// controle de colunas
			_nCol += 9

			//SEQUENCIA QUE EXIBE NO RELATORIO, TP MOVIMENTAÇÃO, N° OS, CNTR, DTA EMISSÃO, HR INICIO, HR FIM, COD CLIENTE, DESC. CLIENTE, PROGRAMAÇÃO
			@ nLin,_nCol pSay Transform(_QRYOS->Z6_NUMOS,PesqPict("SZ6","Z6_NUMOS"))
			_nCol += 14
			@ nLin,_nCol pSay Transform(_QRYOS->Z6_CONTAIN,PesqPict("SZC","ZC_CODIGO"))
			_nCol += 16
			@ nLin,_nCol pSay DtoC(StoD(_QRYOS->Z6_EMISSAO))
			_nCol += 13
			@ nLin,_nCol pSay DtoC(StoD(_QRYOS->Z6_DATAINI))
			_nCol += 12
			@ nLin,_nCol pSay (_QRYOS->Z6_HORAINI)
			_nCol += 9
			@ nLin,_nCol pSay DtoC(StoD(_QRYOS->Z6_DATAFIM))
			_nCol += 11
			@ nLin,_nCol pSay (_QRYOS->Z6_HORAFIM)
			_nCol += 9
			@ nLin,_nCol pSay (_QRYOS->Z6_CODIGO)
			_nCol += 8
			@ nLin,_nCol pSay (_QRYOS->Z6_CLIENTE)+"/"+ _QRYOS->Z6_LOJA+"-"+ _QRYOS->A1_NOME
			_nCol += 43
			@ nLin,_nCol pSay (_QRYOS->NOME_CONF)

			// controle de linha
			nLin ++
			_nCol := 0
			_cQbrOS := _QRYOS->Z6_NUMOS

			// opcao 1 = analitico? se TRUE, imprime a OBSERVAÇÃO
			If mv_par03 == 1
				@ nLin,002 pSay AllTrim("Obs: "+StrTran(_QRYOS->Z6_OBSERVA,CRLF,", "))
				nLin++
			EndIf

		EndIf

		// opcao 1 = analitico
		If mv_par03 == 1

			@ nLin,02 pSay AllTrim(_QRYOS->Z7_CODATIV) +"-"+ Posicione("SZT",1,xFilial("SZT")+_QRYOS->Z7_CODATIV,"ZT_DESCRIC")
			@ nLin,53 pSay "QTD: "+Transf(_QRYOS->Z7_QUANT,PesqPict("SZ7","Z7_QUANT"))


			If (_QRYOS->Z6_STATUS == "P")
				If (Empty(_QRYOS->Z7_DTFATAT))
					@ nLin,75 pSay "FINALIZADA"
				Else
					@ nLin,75 pSay "FATURADO"
				EndIf
			ElseIf (_QRYOS->Z6_STATUS == "A")
				@ nLin,75 pSay "ABERTO"
			ElseIf (_QRYOS->Z6_STATUS == "F")
				@ nLin,75 pSay "FINALIZADA"
			EndIf

			// controle de linha
			nLin ++

		EndIf

		/* S - 20121011
		C - 11/10/2012 + 30
		D - 11/10/2012 + 30
		quantidade de registros*/
		_nCont ++

		_QRYOS->(dbSkip()) // Avanca o ponteiro do registro no arquivo

	EndDo

	//controle de linha
	nLin++
	@ nLin,10 pSay "Total: "+AllTrim(Str(_nCont))+" registros"


	//³ Finaliza a execucao do relatorio...


	SET DEVICE TO SCREEN


	//³ Se impressao em disco, chama o gerenciador de impressao... 

	If aReturn[5]==1
		dbCommitAll()
		SET PRINTER TO
		OurSpool(wnrel)
	Endif

	MS_FLUSH()

Return

Static Function SfExpExcel(mvTitulo)

	Local _aCabec := {}

	Local _aDados := {}
	Local _cTipoMov
	Local _cStatus
	Local _cDescr
	Local _cDta
	Local _cDtaIni
	Local _cDtaFim

	If mv_par03 == 1
		_aCabec := {"TIPO MOV",; //1
		"NÚMERO OS",;    //2
		"DATA EMISSAO",; //3
		"DATA INICIO",;  //4
		"HORA INICIO",;  //5
		"DATA FIM",;     //6
		"HORA FIM",;     //7
		"SERVIÇO",;      //8
		"QTD",;			 //9
		"SITUAÇÃO",;     //10
		"CONTAINER",;	 //11
		"PROGRAMAÇÃO",;  //12
		"COD CLIENTE",;  //13
		"LOJA",;		 //14
		"DESCRIÇÃO",;    //15
		"OBSERVAÇÃO",;   //16
		"CONFERENTE" }	 //17
	ElseIf mv_par03 == 2
		_aCabec := {"TIPO MOV",; //1
		"NÚMERO OS",;    //2
		"DATA EMISSAO",; //3
		"DATA INICIO",;  //4
		"HORA INICIO",;  //5
		"DATA FIM",;     //6
		"HORA FIM",;     //7
		"CONTAINER",;	 //8
		"PROGRAMAÇÃO",;  //9
		"COD CLIENTE",;  //10
		"LOJA",;		 //11
		"DESCRIÇÃO",;	 //12
		"CONFERENTE" }	 //13
	EndIf

	While _QRYOS->(!EOF()) // .and. SZ6->Z6_FILIAL == xFilial("Z06")

		//identifica as entradas, jogando para variavel _cTipoMov, passando para o array
		If _QRYOS->Z6_TIPOMOV == "E"
			_cTipoMov:= "ENTRADA"
		EndIf

		If _QRYOS->Z6_TIPOMOV == "I"
			_cTipoMov:= "INTERNA"
		EndIf

		If _QRYOS->Z6_TIPOMOV == "S"
			_cTipoMov:= "SAIDA"
		EndIf

		//converte a data para dd/mm/aaaa
		_cDta    := DtoC(StoD(_QRYOS->Z6_EMISSAO))
		_cDtaIni := DtoC(StoD(_QRYOS->Z6_DATAINI))
		_cDtaFim := DtoC(StoD(_QRYOS->Z6_DATAFIM))

		//verifica se a opção é analitico
		If mv_par03 == 1
			//verifica o status da OS, joagando para variavel _cStatus, passando para o array
			If (_QRYOS->Z6_STATUS == "P")
				If (Empty(_QRYOS->Z7_DTFATAT))
					_cStatus:= "FINALIZADA"
				Else
					_cStatus:= "FATURADO"
				EndIf
			ElseIf (_QRYOS->Z6_STATUS == "A")
				_cStatus:= "ABERTO"
			ElseIf (_QRYOS->Z6_STATUS == "F")
				_cStatus:= "FINALIZADA"
			EndIf

			// atribui ao cod + descrição do produto a variavel _cDescr
			_cDescr := AllTrim(_QRYOS->Z7_CODATIV) +"-"+ Posicione("SZT",1,xFilial("SZT")+_QRYOS->Z7_CODATIV,"ZT_DESCRIC")


			//linha do array 01
			aAdd(_aDados,{_cTipoMov,; // Tipo de movimento
			_QRYOS->Z6_NUMOS,; 		  // Numero OS
			_cDta,; 	  		  	  // Emissao
			_cDtaIni,;      		  // Data inicio
			_QRYOS->Z6_HORAINI,; 	  // Hora inicio
			_cDtaFim,;                // Data fim			
			_QRYOS->Z6_HORAFIM,;	  // Hora fim
			_cDescr,;	 			  // Descrição do serviço
			_QRYOS->Z7_QUANT,;		  // Qtd
			_cStatus,;                // Situação no faturamento
			_QRYOS->Z6_CONTAIN,; 	  // Numero do container
			_QRYOS->Z6_CODIGO,; 	  // Programação
			_QRYOS->Z6_CLIENTE,; 	  // Cod do cliente
			_QRYOS->Z6_LOJA,;		  // Loja
			_QRYOS->A1_NOME,;		  // Nome
			_QRYOS->Z6_OBSERVA,;      // Observação
			_QRYOS->NOME_CONF})		  // Conferente

		Else

			aAdd(_aDados,{_cTipoMov,; // Tipo de movimento
			_QRYOS->Z6_NUMOS,; 		  // Num os
			_cDta,; 	  		  	  // Emissao
			_cDtaIni,;      		  // Data inicio
			_QRYOS->Z6_HORAINI,; 	  // Hora inicio
			_cDtaFim,;                // Data fim			
			_QRYOS->Z6_HORAFIM,;	  // Hora fim
			_QRYOS->Z6_CONTAIN,; 	  // Numero do container
			_QRYOS->Z6_CODIGO,; 	  // Programação
			_QRYOS->Z6_CLIENTE,; 	  // Cod do cliente
			_QRYOS->Z6_LOJA,;		  // Loja
			_QRYOS->A1_NOME,;		  // Nome
			_QRYOS->NOME_CONF})		  // Conferente

		EndIf

		_QRYOS->(dbSkip())

	End

	DlgToExcel({ {"ARRAY",mvTitulo,_aCabec,_aDados}})

Return

