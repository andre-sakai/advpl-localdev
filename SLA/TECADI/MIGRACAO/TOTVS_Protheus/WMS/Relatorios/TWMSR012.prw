#INCLUDE "rwmake.ch"
#INCLUDE "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Relatório de valores utilizados para encaminhamento para!
!                  ! seguradora. Opção de exportação para Excel.             !
+------------------+---------------------------------------------------------+
!Autor             ! Rafael de Souza           ! Data de Criacao   ! 03/2013 !
+------------------+---------------------------------------------------------+
!Observacoes       !                                                         !
+------------------+--------------------------------------------------------*/

User Function TWMSR012

	// Declaracao de Variaveis
	Local _aPerg  := {}
	Local _cPerg  := PadR("TWMSR012",10)
	Local cDesc1  := "Este programa tem como objetivo imprimir relatorio "
	Local cDesc2  := "de acordo com os parametros informados pelo usuario."
	Local cDesc3  := "Valores Seguradora"
	Local cPict   := ""
	Local titulo  := "Valores Seguradora"
	Local nLin    := 100
	Local Cabec1  := "Filial  Progr      NF    Serie   Dt Entr NF     Total NF          DI             Cliente  "
	Local Cabec2  := "    Cntr	        Placa    DtMov.Cntr        Prc Origem                             Prc Destino                         Vlr por Cntr"
	Local imprime := .T.
	Local aOrd    := {}
	Private lEnd        := .F.
	Private lAbortPrint := .F.
	Private CbTxt       := ""
	Private limite      := 132
	Private tamanho     := "M"
	Private nomeprog    := "TWMSR012" // Coloque aqui o nome do programa para impressao no cabecalho
	Private nTipo       := 18
	Private aReturn     := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
	Private nLastKey    := 0
	Private cbtxt       := Space(10)
	Private cbcont      := 00
	Private CONTFL      := 01
	Private m_pag       := 01
	Private wnrel       := "TWMSR012" // Coloque aqui o nome do arquivo usado para impressao em disco

	// monta a lista de perguntas
	aAdd(_aPerg,{"Filial De ?"      ,"C",3,0,"G",,""}) //mv_par01
	aAdd(_aPerg,{"Filial Até ?"     ,"C",3,0,"G",,""}) //mv_par02
	aAdd(_aPerg,{"Dt Emissão De ?"  ,"D",8,0,"G",,""}) //mv_par03
	aAdd(_aPerg,{"Dt Emissão Até ?" ,"D",8,0,"G",,""}) //mv_par04
	aAdd(_aPerg,{"Exportar Excel ?" ,"N",1,0,"C",{"Sim","Nao"},""}) //mv_par05

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	If ! Pergunte(_cPerg,.t.)
		Return
	EndIf

	//Monta a interface padrao com o usuario...
	wnrel := SetPrint("",NomeProg,"TWMSR012",@titulo,cDesc1,cDesc2,cDesc3,.F.,aOrd,.F.,Tamanho,,.F.)

	If nLastKey == 27
		Return
	Endif

	SetDefault(aReturn,"")

	If nLastKey == 27
		Return
	Endif

	nTipo := If(aReturn[4]==1,15,18)

	//Processamento. RPTSTATUS monta janela com a regua de processamento.
	RptStatus({|| sfImpressao(Cabec1,Cabec2,Titulo,nLin) },Titulo)

Return

// ** Função responsável por selecionar os dados de acordo com os parametros e gerar impressão.
Static Function sfImpressao(Cabec1,Cabec2,Titulo,nLin)
	local _nCont := 0
	Local nOrdem
	local _cQuery
	// controle de quebra de OS
	local _cQbr := ""
	local _cQbrPrg := ""
	local _cFilNota := ""
	local _cNrProgr := ""
	Local _nVlrNota := 0
	Local _nDataDig := ""

	Local _aCabec := {}
	Local _aDados := {}

	Local _cTipoMov
	Local _cStatus
	Local _cPrcOrig := ""
	Local _cPrcDest := ""

	Local _cDoc:= ""
	Local _cDtaMovEnt := ""
	Local _cPlaca := ""
	Local _cCntr := ""
	Local _cDataDigNF := ""
	Local _cSerie := ""
	Local _cDocumen:= ""
	Local _cNomeCli:= ""
	Local _cValor

	//----------------------------------------------------------   SQL   ----------------------------------------------------------------------------//
	_cQuery := " SELECT DISTINCT F1_FILIAL, "
	_cQuery += "                 F1_PROGRAM, "
	_cQuery += "                 F1_DOC, "
	_cQuery += "                 F1_SERIE, "
	_cQuery += "                 F1_VALMERC, "
	_cQuery += "                 (SELECT TOP 1 Z2_DOCUMEN "
	_cQuery += "                  FROM   "+RetSqlTab("SZ2")
	_cQuery += "                  WHERE  Z2_FILIAL = F1_FILIAL "
	_cQuery += "                         AND SZ2.D_E_L_E_T_ = ' ' "
	_cQuery += "                         AND Z2_CODIGO = F1_PROGRAM) AS Z2_DOCUMEN, "
	_cQuery += "                 A1_NOME, "
	_cQuery += "                 F1_DTDIGIT "
	_cQuery += " FROM   "+RetSqlTab("SF1")
	_cQuery += "        LEFT JOIN "+RetSqlTab("SA1")
	_cQuery += "               ON "+RetSqlCond("SA1")
	_cQuery += "                  AND A1_COD = F1_FORNECE "
	_cQuery += "                  AND A1_LOJA = F1_LOJA "
	_cQuery += " WHERE  F1_FILIAL BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' "
	_cQuery += "        AND SF1.D_E_L_E_T_ = ' ' "
	_cQuery += "        AND F1_DTDIGIT BETWEEN '"+DtoS(mv_par03)+"' AND '"+DtoS(mv_par04)+"' "
	_cQuery += "        AND F1_TIPO = 'B' "
	_cQuery += "        AND EXISTS (SELECT Z3_CONTAIN "
	_cQuery += "                    FROM   "+RetSqlTab("SZ3")
	_cQuery += "                    WHERE  Z3_FILIAL = F1_FILIAL "
	_cQuery += "                           AND SZ3.D_E_L_E_T_ = ' ' "
	_cQuery += "                           AND Z3_PROGRAM = F1_PROGRAM "
	_cQuery += "                           AND Z3_TRANSP = '000023' "
	_cQuery += "                           AND Z3_TPMOVIM = 'E' "
	_cQuery += "                           AND Z3_TIPCONT <> '99' "
	_cQuery += "                           AND ( ( Z3_CONTEUD = 'C' ) "
	_cQuery += "                                  OR (( Z3_CONTEUD = 'V' "
	_cQuery += "                                        AND Z3_CONTATU = 'C' )) )) "
	_cQuery += " ORDER  BY F1_FILIAL, "
	_cQuery += "           F1_PROGRAM "
	//----------------------------------------------------------   SQL   ----------------------------------------------------------------------------//

	memowrit("c:\query\TWMSR012_sfImpressao.txt",_cQuery)


	//!=0 para poder entrar mais de uma vez no relatorio.
	If select("_QRY")!= 0
		dbSelectArea("_QRY")
		dbCloseArea()
	EndIf

	// executa a query e joga pro alias
	dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),"_QRY",.F.,.T.)

	dbSelectArea("_QRY")
	_QRY->(dbGoTop())

	//indica que estao sendo processado os regsitros
	SetRegua(100)

	// se for final do arquivo
	While _QRY->(!EOF())

		IncRegua()

		//Verifica o cancelamento pelo usuario...
		If lAbortPrint
			@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
			Exit
		Endif

		//Impressao do cabecalho do relatorio. . .
		If nLin > 55 // Salto de Página. Neste caso o formulario tem 55 linhas...
			Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
			nLin := 9
		Endif

		if (_cQbrPrg != (_QRY->(F1_FILIAL+F1_PROGRAM)))

			// cada vez que entra, ele ZERA o valor da nota
			_nVlrNota := 0
			//imprime a linha de quebra de OS
			@nLin,000 pSay __PrtThinLine()
			//controle de linhas
			nLin ++

			//atualiza filial, programação de novo.
			@ nLin,01 pSay (_QRY->F1_FILIAL)
			@ nLin,06 pSay (_QRY->F1_PROGRAM)

		EndIf

		//verifica se a opção exporta para excel esta como não.
		if mv_par05 == 2

			//Cabec1 - Filial  Progr   NF    Serie    Dt Entrada NF  TOTAL NF     DI    CLIENTE
			@ nLin,15 pSay (_QRY->F1_DOC)
			@ nLin,26 pSay (_QRY->F1_SERIE)
			@ nLin,35 pSay DtoC(StoD(_QRY->F1_DTDIGIT))
			@ nLin,46 pSay Transf(_QRY->F1_VALMERC,PesqPict("SF1","F1_VALMERC"))
			@ nLin,62 pSay (_QRY->Z2_DOCUMEN)
			@ nLin,80 pSay (_QRY->A1_NOME)

			// controle de linha
			nLin ++

		Elseif mv_par05 == 1

			//atribuindo a nota a uma variavel
			_cDoc := _QRY->F1_DOC

			//atribuindo a serie a uma variavel
			_cSerie := _QRY->F1_SERIE

			//atribuindo o documento a uma variavel
			_cDocumen := _QRY->Z2_DOCUMEN

			//atribuindo o nome do cliente a uma variavel
			_cNomeCli := _QRY->A1_NOME

			//data de digitação da nota fiscal
			_cDataDigNF := DtoC(StoD(_QRY->F1_DTDIGIT))

		EndIf

		// controle de quebra
		_cQbrPrg := _QRY->(F1_FILIAL+F1_PROGRAM)

		//salva nas variaveis, para poder utilizar na comparação
		_cFilNota := _QRY->F1_FILIAL
		_cNrProgr := _QRY->F1_PROGRAM

		//Valor total das NFs
		_nVlrNota += _QRY->F1_VALMERC

		//Avanca o ponteiro do registro no arquivo
		_QRY->(dbSkip())


		//Se a programação e filial for != da atual entra nesta condição
		If (_cQbrPrg != (_QRY->(F1_FILIAL+F1_PROGRAM)))

			//----------------------------------------------------------   SQL   ----------------------------------------------------------------------------//

			_cQuery := " SELECT Z3_DTMOVIM, "
			_cQuery += "        Z3_CONTAIN, "
			_cQuery += "        Z3_PLACA1, "
			_cQuery += "        Z3_PRCORIG, "
			_cQuery += "        Z3_PRCDEST, "
			_cQuery += "        (SELECT Count(*) "
			_cQuery += "         FROM   "+RetSqlTab("SZ3")
			_cQuery += "         WHERE  Z3_FILIAL = '"+_cFilNota+"' "
			_cQuery += "                AND SZ3.D_E_L_E_T_ = ' ' "
			_cQuery += "                AND Z3_PROGRAM = '"+_cNrProgr+"' "
			_cQuery += "                AND Z3_TRANSP = '000023' "
			_cQuery += "                AND Z3_TPMOVIM = 'E' "
			_cQuery += "                AND Z3_TIPCONT <> '99' "
			_cQuery += "                AND ( ( Z3_CONTEUD = 'C' ) "
			_cQuery += "                       OR ( Z3_CONTEUD = 'V' "
			_cQuery += "                            AND Z3_CONTATU = 'C' ) )) AS QTD_CNTR "
			_cQuery += " FROM   "+RetSqlTab("SZ3")
			_cQuery += " WHERE  Z3_FILIAL = '"+_cFilNota+"' "
			_cQuery += "        AND SZ3.D_E_L_E_T_ = ' ' "
			_cQuery += "        AND Z3_PROGRAM = '"+_cNrProgr+"' "
			_cQuery += "        AND Z3_TRANSP = '000023' "
			_cQuery += "        AND Z3_TPMOVIM = 'E' "
			_cQuery += "        AND Z3_TIPCONT <> '99' "
			_cQuery += "        AND ( ( Z3_CONTEUD = 'C' ) "
			_cQuery += "               OR ( Z3_CONTEUD = 'V' "
			_cQuery += "                    AND Z3_CONTATU = 'C' ) ) "
			//----------------------------------------------------------   SQL   ----------------------------------------------------------------------------//

			memowrit("c:\query\TWMSR012_sfImpressaoCON.txt",_cQuery)

			//!=0 para poder entrar mais de uma vez no relatorio.
			If select("_QRYCON")!= 0
				dbSelectArea("_QRYCON")
				dbCloseArea()
			EndIf

			// executa a query e joga para o alias
			dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),"_QRYCON",.F.,.T.)

			dbSelectArea("_QRYCON")
			_QRYCON->(dbGoTop())

			SetRegua(100)

			While _QRYCON->(!EOF())

				IncRegua()

				//Verifica o cancelamento pelo usuario...
				If lAbortPrint
					@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
					Exit
				Endif

				// Impressao do cabecalho do relatorio. . .
				If nLin > 55 // Salto de Página. Neste caso o formulario tem 55 linhas...
					Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
					nLin := 9
				Endif

				//faz a verificação se não exporta para excel
				if mv_par05 == 2

					// Cabec2  CNTR 	DtMov.CNTR   PLACA   PRC ORIGEM   PRC DESTINO   VLR CONTAINER
					@ nLin,02 pSay Transform(_QRYCON->Z3_CONTAIN,PesqPict("SZ3","Z3_CONTAIN"))
					@ nLin,18 pSay Transform(_QRYCON->Z3_PLACA1,PesqPict("SZ3","Z3_PLACA1"))
					@ nLin,28 pSay DtoC(StoD(_QRYCON->Z3_DTMOVIM))
					@ nLin,43 pSay AllTrim(_QRYCON->Z3_PRCORIG) +"-"+ Posicione("SZB",1,xFilial("SZB")+_QRYCON->Z3_PRCORIG,"ZB_DESCRI")
					@ nLin,80 pSay AllTrim(_QRYCON->Z3_PRCDEST) +"-"+ Posicione("SZB",1,xFilial("SZB")+_QRYCON->Z3_PRCDEST,"ZB_DESCRI")
					@ nLin,120 pSay Transf(_nVlrNota / _QRYCON->QTD_CNTR,PesqPict("SF1","F1_VALMERC"))
					nLin++

					//faz a verificação se exporta para excel
				ElseIf mv_par05 == 1

					//data do movimento de entrada do CNTR
					_cDtaMovEnt := DtoC(StoD(_QRYCON->Z3_DTMOVIM))

					//cod + descrição do produto a variavel _cPrcOrig
					_cPrcOrig := AllTrim(_QRYCON->Z3_PRCORIG) +"-"+ Posicione("SZB",1,xFilial("SZB")+_QRYCON->Z3_PRCORIG,"ZB_DESCRI")
					_cPrcDest := AllTrim(_QRYCON->Z3_PRCDEST) +"-"+ Posicione("SZB",1,xFilial("SZB")+_QRYCON->Z3_PRCDEST,"ZB_DESCRI")

					//utilizando a mascara para impressão do Container e Placa
					_cPlaca := Transf(_QRYCON->Z3_PLACA1,PesqPict("SZ3","Z3_PLACA1"))
					_cCntr := Transf(_QRYCON->Z3_CONTAIN,PesqPict("SZ3","Z3_CONTAIN"))

					//atribuindo o valor por container, ja ratiado
					_cValor := _nVlrNota / _QRYCON->QTD_CNTR

					//adicionando todas as informações ao vetor, desta forma ficará com os dados das variáveis.
					aAdd(_aDados,{_cFilNota,;
						_cNrProgr,;
						_cDoc,;
						_cSerie,;
						_cDataDigNF,;
						_nVlrNota,;
						_cValor,;
						_cCntr,;
						_cDtaMovEnt,;
						_cPlaca,;
						_cDocumen,;
						_cNomeCli,;
						_cPrcOrig,;
						_cPrcDest})

				EndIf

				//Avanca o ponteiro do registro no arquivo
				_QRYCON->(dbSkip())


			EndDo

			nLin++

		EndIf

	EndDo

	nLin++

	//chamada para exportar para excel
	If mv_par05 == 1
		SfExpExcel(Titulo,_aDados)
		return
	EndIf

	//chamada para imprimir o relatorio na tela
	If mv_par05 == 2

		//Finaliza a execucao do relatorio..
		SET DEVICE TO SCREEN

		//³ Se impressao em disco, chama o gerenciador de impressao...          ³
		If aReturn[5]==1
			dbCommitAll()
			SET PRINTER TO
			OurSpool(wnrel)
		Endif

		MS_FLUSH()

	EndIf

Return

//** Função utilizada para exportação excel
Static Function SfExpExcel(mvTitulo,mvDados)

	//Variaveis utilizadas na exportação para Excel na função DlgToExcel
	Local _aCabec := {}
	Local _aDados := mvDados


	//montagem do cabeçalho
	_aCabec := {"FILIAL",; //1
	"PROGRAMAÇÃO",;   //2
	"NOTA FISCAL",;   //3
	"SERIE",;  		  //4
	"DT ENTRADA NF",; //5
	"VLR TOTAL NF",;      //6
	"VLR POR CONTAINER",; //7
	"CONTAINER",;     //8
	"DT MOV CNTR",;	  //9
	"PLACA",;         //10
	"DI",;  		  //11
	"CLIENTE",;  	  //12
	"PRACA DE ORIGEM",;	  //13
	"PRACA DE DESTINO"}	  //14

	//verifica se exporta para excel = sim.
	If mv_par05 == 1

		DlgToExcel({ {"ARRAY",mvTitulo,_aCabec,_aDados}})

	EndIf

Return
