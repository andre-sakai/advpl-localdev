#Include 'Protheus.ch'
#include "TOTVS.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSR017                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Impressão de TFAA                                       !
!                  !                                                         !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe Jose Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSR017()

	// grupo de perguntas
	local _cPerg   := PadR("TWMSR017",10)
	local _aPerg   := {}
	Local _aRetSQL := {}
	Local _cQuery  := ""
	Local _cDescUM := ""
	Local _cCodiUM := ""
	Local _lAvaria := .f.

	//Controle de Posicionamento de colunas
	Private lin  := 50      // Distancia da linha vertical da margem esquerda
	Private lin1 := 330     // Distancia da linha vertical da margem superior
	Private lin2 := 1950    // Tamanho verttical da linha

	Private oFont10  := TFont():New("Calibri",10,10,,.F.,,,,.T.,.F.)
	Private oFont10n := TFont():New("Calibri",10,10,,.T.,,,,.T.,.F.)
	Private oFont11  := TFont():New("Calibri",11,11,,.F.,,,,.T.,.F.)
	Private oFont12  := TFont():New("Calibri",13,13,,.F.,,,,.T.,.F.)
	Private oFont13  := TFont():New("Calibri",13,13,,.F.,,,,.T.,.F.)
	Private oFont20n := TFont():New("Calibri",20,20,,.T.,,,,.T.,.F.)
	Private oFont28n := TFont():New("Calibri",28,28,,.T.,,,,.T.,.F.)//Fonte28 Negrito

	// monta a lista de perguntas
	aAdd(_aPerg,{"Nº OS:"            ,"C",TamSx3("Z41_NUMOS")[1] ,0,"G",,""}) //mv_par01

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// chama a tela de parametros
	Pergunte(_cPerg,.T.)

	// busca Pedidos.
	_cQuery := "SELECT Z05_CLIENT,Z05_LOJA,Z05_PROCES,Z04_NF,F1_DTDIGIT,Z2_DOCUMEN,ZZ_CNTR01,ZZ_PLACA1,Z42_PROD,B1_DESC,(Z42_QTDORI - Z42_QTDCON),Z42_QTDORI, Z42_QTDCON,Z35_DESCRI,Z41_CODIGO "

	//WMS - ORDEM DE SERVICO
	_cQuery += " FROM "+RetSqlName("Z05")+" Z05 "

	//WMS - TFAA (CABECALHO)
	_cQuery += " INNER JOIN "+RetSqlName("Z41")+" Z41 ON "+RetSqlCond("Z41")+" AND Z41.Z41_CODIGO  = Z05.Z05_TFAA  "

	//WMS - TFAA (ITENS)
	_cQuery += " INNER JOIN "+RetSqlName("Z42")+" Z42 ON "+RetSqlCond("Z42")+" AND Z41.Z41_CODIGO = Z42.Z42_CODIGO AND Z42_QTDCON != Z42_QTDORI "

	// Produtos
	_cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND B1_COD = Z42_PROD "

	//WMS - CADASTRO DE AVARIAS
	_cQuery += " LEFT JOIN "+RetSqlName("Z35")+" Z35 ON "+RetSqlCond("Z35")+" AND Z35.Z35_CODIGO = Z42.Z42_CODAVA "

	//WMS - CESV (ENT/SAI VEIC)
	_cQuery += " INNER JOIN "+RetSqlName("SZZ")+" SZZ ON "+RetSqlCond("SZZ")+" AND SZZ.ZZ_CESV  = Z05.Z05_CESV  "

	//WMS - MERCADORIAS DA CARGA
	_cQuery += " INNER JOIN "+RetSqlName("Z04")+" Z04 ON "+RetSqlCond("Z04")+" AND Z04.Z04_CESV  = Z05.Z05_CESV AND Z04_PROD = Z42_PROD AND Z04.Z04_NUMSEQ = Z42.Z42_NUMSEQ "
	
	//COMPARA OS ITENS DA NF COM OS ITENS PLANEJADOS NA OS
	_cQuery += " INNER JOIN "+RetSqlName("SD1")+" SD1 ON "+RetSqlCond("SD1")+" AND SD1.D1_NUMSEQ = Z04.Z04_NUMSEQ "

	//PROGRAMACOES - ITENS
	_cQuery += " INNER JOIN "+RetSqlName("SZ2")+" SZ2 ON "+RetSqlCond("SZ2")+" AND SZ2.Z2_CODIGO = Z04.Z04_PROCES AND SZ2.Z2_ITEM = SD1.D1_ITEPROG "

	//CABECALHO DAS NF DE ENTRADA
	_cQuery += " INNER JOIN "+RetSqlName("SF1")+" SF1 ON "+RetSqlCond("SF1")+" AND Z04_CLIENT = F1_FORNECE AND Z04_LOJA  = F1_LOJA AND Z04_TIPONF = F1_TIPO AND Z04_NF = F1_DOC AND Z04_SERIE = F1_SERIE "

	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond('Z05')+" "

	//Filtro OS
	_cQuery += " AND Z05.Z05_NUMOS = '"+mv_par01+"'"

	//Filtro Item com divergencias de conferencia
	//_cQuery += " AND Z42_QTDORI <> Z42_QTDCON "

	memowrite("C:\query\twmsr017.txt",_cQuery)

	// carrega resultado do SQL na variavel.
	_aRetSQL := U_SqlToVet(_cQuery)

	If Len(_aRetSQL) <= 0
		MsgStop("Sem informações para Imprimir")
		Return(.F.)
	EndIf

	oPrint:= TMSPrinter():New("TFAA - Termo de Faltas, Acréscimos e Avarias") // Monta objeto para impressão
	oPrint:SetPortrait()
	oPrint:Setup()
	oPrint:StartPage()

	oBrush1 := TBrush():New( , CLR_HGRAY )
	oBrush2 := TBrush():New( , CLR_WHITE )

	oPrint:SayBitmap(-0100,0001,"logo_tecadi_group.png",1100,0700 )// Logo
	oPrint:Say(0150,1500,"TFAA",oFont28n)
	oPrint:Say(0280,1290,"Termo de Faltas, Acréscimos e Avarias",oFont13)
	oPrint:Say(0330,1480,"NR: " + Alltrim(cFilant) + "/" + Alltrim(_aRetSQL[1][15]),oFont12)

	_nLinBox1 := 500
	_nLinBox2 := 500

	oPrint:fillRect( { _nLinBox1, 050, _nLinBox1 + 50, 2300}, oBrush1 )
	_nLinBox1 := _nLinBox1 + 5
	_nLinBox2 := _nLinBox2 + 5
	//505
	oPrint:Say(_nLinBox1  ,0100 ,"Dados Armazem",oFont10)
	oPrint:Say(_nLinBox1  ,1600 ,"Dados Cliente",oFont10)

	_nLinBox1 := _nLinBox1 + 45
	_nLinBox2 := _nLinBox2 + 45
	//550
	//Conteudo da empresa Compradora
	oPrint:Say(_nLinBox1,0100,SM0->M0_NOMECOM ,oFont11)
	_nLinBox1 := _nLinBox1 + 70
	_nLinBox2 := _nLinBox2 + 70
	oPrint:Say(_nLinBox1,0100,Alltrim(SM0->M0_ENDCOB) + " " + Alltrim(SM0->M0_CIDCOB)+" - "+ Alltrim(SM0->M0_ESTCOB),oFont11)
	_nLinBox1 := _nLinBox1 + 70
	_nLinBox2 := _nLinBox2 + 70
	oPrint:Say(_nLinBox1,0100,"CNPJ..: " + TransForm(SM0->M0_CGC,"@R 99.999.999/9999-99") ,oFont11)

	// pesquisa o cliente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1))
	SA1->(dbSeek(xFilial("SA1") + _aRetSQL[1][1] + _aRetSQL[1][2] ))

	_nLinBox1 := 550
	_nLinBox2 := 550
	// Conteudo do Cliente
	oPrint:Say(_nLinBox1,1600,SA1->A1_NOME                     ,oFont11)
	_nLinBox1 := _nLinBox1 + 70
	_nLinBox2 := _nLinBox2 + 70
	oPrint:Say(_nLinBox1,1600,SA1->A1_END                      ,oFont11)
	_nLinBox1 := _nLinBox1 + 70
	_nLinBox2 := _nLinBox2 + 70
	oPrint:Say(_nLinBox1,1600,"CNPJ..: "+ TransForm(SA1->A1_CGC,"@R 99.999.999/9999-99") ,oFont11)
	_nLinBox1 := _nLinBox1 + 70
	_nLinBox2 := _nLinBox2 + 70
	//760
	oPrint:fillRect( { _nLinBox2, 050, _nLinBox2 + 50, 2300}, oBrush1 )
	_nLinBox1 := _nLinBox1 + 5
	_nLinBox2 := _nLinBox2 + 5
	//765
	oPrint:Say(_nLinBox1,0100 ,"Dados da programação / Processo" ,oFont10)
	_nLinBox1 := _nLinBox1 + 40
	_nLinBox2 := _nLinBox2 + 40
	//805
	oPrint:Say(_nLinBox1,0800 ,"Processo: "                       ,oFont10 , , , ,1)
	oPrint:Say(_nLinBox1,0830 ,Alltrim(_aRetSQL[1][3])            ,oFont10n, , , ,0)
	oPrint:Say(_nLinBox1,1700 ,"Data Recebimento: "               ,oFont10 , , , ,1)
	oPrint:Say(_nLinBox1,1730 ,Alltrim(dtoc(Stod(_aRetSQL[1][5]))),oFont10n, , , ,0)

	_nLinBox1 := _nLinBox1 + 50
	_nLinBox2 := _nLinBox2 + 50
	oPrint:Say(_nLinBox1,0800 ,"NF de remessa: "       ,oFont10 , , , ,1)
	oPrint:Say(_nLinBox1,0830 ,Alltrim(_aRetSQL[1][4]) ,oFont10n, , , ,0)
	oPrint:Say(_nLinBox1,1700 ,"Nº DI: "               ,oFont10 , , , ,1)
	oPrint:Say(_nLinBox1,1730 ,Alltrim(_aRetSQL[1][6]) ,oFont10n, , , ,0)

	_nLinBox1 := _nLinBox1 + 50
	_nLinBox2 := _nLinBox2 + 50
	oPrint:Say(_nLinBox1,0800 ,"Containeres / Veículos: "             ,oFont10  , , , ,1)
	oPrint:Say(_nLinBox1,0830 ,_aRetSQL[1][7] + "/" +  _aRetSQL[1][8] ,oFont10n , , , ,0)
	oPrint:Say(_nLinBox1,1700 ,"Lacres:"                              ,oFont10  , , , ,1)
	oPrint:Say(_nLinBox1,1730 ,""                                     ,oFont10n , , , ,0)
	_nLinBox1 := _nLinBox1 + 050
	_nLinBox2 := _nLinBox2 + 050

	For _nBox:= 1 To Len(_aRetSQL)
		If (_aRetSQL[_nBox][12] <> _aRetSQL[_nBox][13])
			_lAvaria := .t.
		EndIf
	Next _nBox
	/*
	_zVeiculo := _aRetSQL[1][7] + "/" +  _aRetSQL[1][8]

	For _nBox:= 1 To 12
		oPrint:Box( _nLinBox1,400,_nLinBox2 + 50,1200 )
		oPrint:Box( _nLinBox1,400,_nLinBox2 + 50,2000 )

		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50
	Next _nBox
	_nLinBox1 := 1015
	_nLinBox2 := 1015

	For _nBox:= 1 To Len(_aRetSQL)
		If (_zVeiculo <> _aRetSQL[_nBox][7] + "/" +  _aRetSQL[_nBox][8]) .Or. (_nBox == 1)

			oPrint:Say(_nLinBox1 + 5 ,0450 ,_aRetSQL[_nBox][7] + "/" +  _aRetSQL[_nBox][8],oFont10n)//Containeres / Veículos
			oPrint:Say(_nLinBox1 + 5 ,1250 ,""                           ,oFont10n)//Lacres

			_zVeiculo := _aRetSQL[1][7] + "/" +  _aRetSQL[1][8]
			_nLinBox1 := _nLinBox1 + 50
			_nLinBox2 := _nLinBox2 + 50
		EndIf
	Next _nBox

	_nLinBox1 := 1655
	_nLinBox2 := 1655
	*/
	oPrint:Box( _nLinBox1,050,_nLinBox2 + 70 ,150 )
	oPrint:fillRect( { _nLinBox1, 155, _nLinBox2 + 70, 2300}, oBrush1 )

	If _lAvaria
		oPrint:Say(_nLinBox1 + 5,0155,"Houve falta, acréscimo ou avaria no recebimento da mercadoria, conforme detalhado abaixo." ,oFont10n, , , , 0)
		oPrint:Say(_nLinBox1 - 5,0067,"X" ,oFont20n, , , , 0)

		oPrint:Say(_nLinBox1 + 100,0055,"Informamos que os itens constantes no processo em referência, armazenados em " + Alltrim(dtoc(Stod(_aRetSQL[1][5]))) + " , sofreram avarias constatadas abaixo:" ,oFont10, , , , 0)
		//oPrint:Say(_nLinBox1 + 100,1260, Alltrim(dtoc(Stod(_aRetSQL[1][5]))) ,oFont10n, , , , 0)

		_nLinBox1 := _nLinBox1 + 200
		_nLinBox2 := _nLinBox2 + 200

		oPrint:fillRect( { _nLinBox1, 050, _nLinBox2 + 50, 2300}, oBrush1 )
		oPrint:Say(_nLinBox1 + 5 ,0060 ,"CÓDIGO"                     ,oFont10n)
		oPrint:Say(_nLinBox1 + 5 ,0380 ,"DESCRIÇÃO MERCADORIA / LOTE",oFont10n)
		oPrint:Say(_nLinBox1 + 5 ,1260 ,"QTD"                        ,oFont10n)
		oPrint:Say(_nLinBox1 + 5 ,1450 ,"DESCRIÇÃO OCORRÊNCIA"       ,oFont10n)

		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50

		For _nBox:= 1 To 30
			oPrint:Box( _nLinBox1,050,_nLinBox2 + 50,0370 )
			oPrint:Box( _nLinBox1,050,_nLinBox2 + 50,1250 )
			oPrint:Box( _nLinBox1,050,_nLinBox2 + 50,1440 )
			oPrint:Box( _nLinBox1,050,_nLinBox2 + 50,2300 )
			_nLinBox1 := _nLinBox1 + 50
			_nLinBox2 := _nLinBox2 + 50
		Next _nBox

		_nLinBox1 := 1205
		_nLinBox2 := 1205

		For _nBox:= 1 To Len(_aRetSQL)
			If (_aRetSQL[_nBox][12] <> _aRetSQL[_nBox][13])
				oPrint:Say(_nLinBox1 + 5 ,0060 ,_aRetSQL[_nBox][09]               ,oFont11)
				oPrint:Say(_nLinBox1 + 5 ,0380 ,_aRetSQL[_nBox][10]               ,oFont11)
				oPrint:Say(_nLinBox1 + 5 ,1335 ,TransForm(Abs(_aRetSQL[_nBox][11]),"@E 99,999,999.9999"),oFont11, , , ,2)

				_cCodiUM := Posicione("SB1",1, xFilial("SB1")+ _aRetSQL[_nBox][09] ,"B1_UM")
				_cDescUM := Posicione("SAH",1, xFilial("SAH")+ _cCodiUM            ,"AH_UMRES")

				If _aRetSQL[_nBox][11] > 0
					oPrint:Say(_nLinBox1 + 5 ,1450 ,"Constatamos a falta de " + Alltrim(TransForm(Abs(_aRetSQL[_nBox][11]),"@E 99,999,999.9999")) + " " + Alltrim(_cDescUM) + ".",oFont11)
				Else
					oPrint:Say(_nLinBox1 + 5 ,1450 ,"Constatamos o ascrecimo de " + Alltrim(TransForm(Abs(_aRetSQL[_nBox][11]),"@E 99,999,999.9999")) + " " + Alltrim(_cDescUM) + ".",oFont11)
				EndIf
				_nLinBox1 := _nLinBox1 + 50
				_nLinBox2 := _nLinBox2 + 50
			EndIf
		Next _nBox
		_nLinBox1 := 3005
		_nLinBox2 := 3005
	Else
		oPrint:Say(_nLinBox1 + 5,0155,"Não houve falta, acréscimo ou avaria no recebimento da mercadoria." ,oFont10n, , , , 0)
		oPrint:Say(_nLinBox1 - 5,0067,"X" ,oFont20n, , , , 0)
		_nLinBox1 := _nLinBox1 + 500
		_nLinBox2 := _nLinBox2 + 500
	EndIf


	_nLinBox1 := _nLinBox1 + 200

	oPrint:Say(_nLinBox1      ,1200 ,"_______________________________________",oFont10n, , , , 2)
	oPrint:Say(_nLinBox1 + 50 ,1120 ,"CONFERENTE",oFont10n, , , , 0)

	

	oPrint:Say(_nLinBox1      ,0060 ,"_______________________________________",oFont10n, , , , 0)
	oPrint:Say(_nLinBox1 + 50 ,0280 ,"GERENTE",oFont10n, , , , 0)

	oPrint:Say(_nLinBox1      ,2300 ,"_______________________________________",oFont10n, , , , 1)
	oPrint:Say(_nLinBox1 + 50 ,1950 ,"ASSIS. LOGISTICA",oFont10n, , , , 0)

	// Visualiza a impressão
	oPrint:EndPage()
	oPrint:Preview()

Return