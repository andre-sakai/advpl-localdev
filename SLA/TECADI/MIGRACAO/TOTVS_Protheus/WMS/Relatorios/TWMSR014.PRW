#INCLUDE "Totvs.ch"

User Function TWMSR014()

Local oReport
Local oSection1
Local oSection2
Local oSection3
Local oCell
Local aOrdem := {}
Local cTamVal:= TamSX3('B6_CUSTO1' )[1]
Local cTamQtd:= TamSX3('B6_QUANT' )[1]

LOCAL wnrel, nOrdem
LOCAL Tamanho := "G"
LOCAL cDesc1  := "Este programa ira emitir o Relatorio de Materiais"
LOCAL cDesc2  := "de Terceiros em nosso poder e/ou nosso Material em"
LOCAL cDesc3  := "poder de Terceiros."
LOCAL cString := "SB6"
LOCAL aOrd    := {OemToAnsi(" Produto/Local "),OemToAnsi(" Cliente/Fornecedor ")}

// grupo de perguntas
Local _aPerg := {}
Local _cPerg := PadR("TWMSR014",10)

PRIVATE cCondCli
PRIVATE aReturn := {OemToAnsi("Zebrado"), 1,OemToAnsi("Administracao"), 1, 2, 1, "",1 }
PRIVATE nomeprog:= "TWMSR014"
PRIVATE aLinha  := { },nLastKey := 0
PRIVATE Titulo  := OemToAnsi("Relacao de materiais de Terceiros e em Terceiros")
PRIVATE cabec1, cabec2, nTipo, CbTxt, CbCont
PRIVATE lListCustM := .T.
PRIVATE lCusFIFO   := GetMV('MV_CUSFIFO')

// criacao das Perguntas
aAdd(_aPerg,{"Programação De?" ,"C",TamSx3("Z1_CODIGO")[1],0,"G",,"SZ1"}) //mv_par01
aAdd(_aPerg,{"Programação Até?" ,"C",TamSx3("Z1_CODIGO")[1],0,"G",,"SZ1"}) //mv_par02
aAdd(_aPerg,{"Cliente De?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par03
aAdd(_aPerg,{"Cliente Até?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par04
aAdd(_aPerg,{"Loja De?" ,"C",TamSx3("A1_LOJA")[1],0,"G",,""}) //mv_par05
aAdd(_aPerg,{"Loja Até?" ,"C",TamSx3("A1_LOJA")[1],0,"G",,""}) //mv_par06
aAdd(_aPerg,{"Produto De?" ,"C",TamSx3("B1_COD")[1],0,"G",,"SB1"}) //mv_par07
aAdd(_aPerg,{"Produto Até?" ,"C",TamSx3("B1_COD")[1],0,"G",,"SB1"}) //mv_par08
aAdd(_aPerg,{"Dt. Entrada De?" ,"D",8,0,"G",,""}) //mv_par09
aAdd(_aPerg,{"Dt. Entrada Até?" ,"D",8,0,"G",,""}) //mv_par10
aAdd(_aPerg,{"Dt. Devolução De?" ,"D",8,0,"G",,""}) //mv_par11
aAdd(_aPerg,{"Dt. Devolução Até?" ,"D",8,0,"G",,""}) //mv_par12

// cria grupo de perguntas
U_FtCriaSX1( _cPerg,_aPerg )

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis utilizadas para Impressao do Cabecalho e Rodape    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
CbTxt := SPACE(10)
CbCont:= 00
li	  := 80
m_pag := 01


// Verifica as perguntas selecionadas
pergunte(_cPerg,.F.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis utilizadas para parametros                                  ³
//³ mv_par01   		// Cliente Inicial                		              ³
//³ mv_par02        // Cliente Final                       	              ³
//³ mv_par03        // Fornecedor Inicial                     	          ³
//³ mv_par04        // Fornecedor Final                          	      ³
//³ mv_par05        // Produto Inicial                              	  ³
//³ mv_par06        // Produto Final                         		      ³
//³ mv_par07        // Data Inicial                              	      ³
//³ mv_par08        // Data Final                                   	  ³
//³ mv_par09        // Situacao   (Todos / Em aberto)                     ³
//³ mv_par10        // Tipo   (De Terceiros / Em Terceiros / Ambos)		  ³
//³ mv_par11        // Custo em Qual Moeda  (1/2/3/4/5)             	  ³
//³ mv_par12        // Lista NF Devolucao  (Sim) (Nao)              	  ³
//³ mv_par13        // Devolucao data de                            	  ³
//³ mv_par14        // Devolucao data ate                           	  ³
//³ mv_par15        // QTDE. na 2a. U.M.? Sim / Nao                       ³
//³ mv_par16        // Lista Custo? Medio / Fifo                          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Define variaveis p/ filtrar arquivo.                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cCondCli := "B6_CLIFOR   <= mv_par04 .And. B6_CLIFOR  >= mv_par03 .And."+;
" B6_PRODUTO <= mv_par08 .And. B6_PRODUTO >= mv_par07 .And."+;
" B6_DTDIGIT <= mv_par10 .And. B6_DTDIGIT >= mv_par09 .And."+;
" B6_QUANT   <> 0 "


// Envia controle para a funcao SetPrint
wnrel := SetPrint(cString,"TWMSR014",_cPerg,@titulo,cDesc1,cDesc2,cDesc3,.F.,aOrd,.T.,Tamanho)

If nLastKey == 27
	Return .T.
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
	Return .T.
Endif

RptStatus({|lEnd| R480Imp(@lEnd,wnRel,cString,Tamanho)},titulo)

Return NIL

// ** funcao para Chamada do Relatorio
Static Function R480Imp(lEnd,WnRel,cString,Tamanho)

nTipo:=IIF(aReturn[4]==1,15,18)

nOrdem := aReturn[8]

lListCustM := .t.

dbSelectArea("SB6")

If nOrdem == 1
	R480Prod(lEnd,Tamanho)
ElseIf nOrdem == 2
	R480CliFor(lEnd,Tamanho)
EndIf

dbSelectArea("SB6")
Set Filter To
dbSetOrder(1)

If aReturn[5] == 1
	Set Printer To
	dbCommitAll()
	ourspool(wnrel)
Endif

MS_FLUSH()

Return .t.

// funcao que Imprime Por Ordem de Produto / LOCAL
Static Function R480Prod(lEnd,Tamanho)
LOCAL cCliFor   := ""
LOCAL cProdLOCAL:= ""
LOCAL cQuebra   := ""
LOCAL cSeek     := ""
LOCAL cQuery    := ""
LOCAL cAliasSB6 := "SB6"
LOCAL aSaldo    := {}
LOCAL aStrucSB6 := {}
LOCAL aAreaSB6  := {}
LOCAL nCusTot   := nQuant := nQuJe := nTotal := nTotDev := nTotQuant := nTotQuJe := nTotSaldo := 0
LOCAL nGerTot   := nGerTotDev:=nGerCusTot:=0
LOCAL nIncCol   := If(cPaisLoc == "MEX",7,0)
LOCAL cTamB6Qt  := PesqPict("SB6","B6_QUANT",17)
LOCAL cTamB6Q2  := PesqPict("SB6", "B6_QTSEGUM",12)
LOCAL nRegs     := SB6->(LastRec())
LOCAL nSaldo    := 0
LOCAL nCusto    := 0
LOCAL nPrUnit   := 0
LOCAL nX        := 0
LOCAL lQuery    := .T.
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta o Cabecalho de acordo com o tipo de emissao            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
titulo := "RELACAO DE MATERIAIS DE TERCEIROS EM NOSSO PODER - PRODUTO / LOCAL"

cabec1 := "            Cliente /        Loja  -  Documento  - Data de  Unid.de ---------------------- Quantidade ------------------- --------------- Valores -----------   Custo Prod. TM  Segunda    Quantidade      Data    Dt Ult.
cabec2 := "            Fornecedor              Numero  Serie  Emissao   Medida          Original      Ja' entregue             Saldo Total Nota Fiscal   Total Devolvido    na Moeda X     Un.Med.       Seg. UM    Lancto    Entrega

dbSelectArea("SB6")
dbSetOrder(1)

cAliasSB6 := GetNextAlias()
aStrucSB6 := SB6->(dbStruct())
cQuery	  := " SELECT SB6.* "
cQuery	  +=   " FROM " + RetSqlName("SB6") + " SB6"
cQuery    +=  " WHERE SB6.B6_FILIAL = '"   + xFilial("SB6") + "' "
cQuery    +=    " AND SB6.B6_CLIFOR BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' "
cQuery    +=    " AND SB6.B6_LOJA BETWEEN '"+mv_par05+"' AND '"+mv_par06+"' "
cQuery    +=    " AND SB6.B6_DTDIGIT BETWEEN '"+DtoS(mv_par09)+"' AND '"+DtoS(mv_par10)+"' "
cQuery    +=    " AND SB6.B6_PRODUTO >= '" + mv_par07 + "' "
cQuery    +=    " AND SB6.B6_PRODUTO <= '" + mv_par08 + "' "
cQuery    +=    " AND SB6.B6_PODER3 = 'R'
// programacao
cQuery    +=    " AND SB6.B6_IDENT IN ( "
cQuery    +=    "                      SELECT D1_IDENTB6 
cQuery    +=    "                      FROM "+RetSqlName("SD1")+" SD1 WHERE "+RetSqlCond("SD1")+" "
cQuery    +=    "                      AND D1_DTDIGIT BETWEEN '"+DtoS(mv_par09)+"' AND '"+DtoS(mv_par10)+"' "
cQuery    +=    "                      AND D1_FORNECE BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' "
cQuery    +=    "                      AND D1_LOJA BETWEEN '"+mv_par05+"' AND '"+mv_par06+"' "
cQuery    +=    "                      AND D1_TIPO IN ('B','D') "
cQuery    +=    "                      AND D1_PROGRAM BETWEEN '"+mv_par01+"' AND '"+mv_par02+"') "
// deletados
cQuery    +=    " AND SB6.D_E_L_E_T_ = ' ' "
// ordem dos dados
cQuery    +=    " ORDER BY B6_FILIAL, B6_PRODUTO, B6_LOCAL "
cQuery:=ChangeQuery(cQuery)
MsAguarde({|| dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cAliasSB6,.F.,.T.)},"Processando ...")
dbSelectArea(cAliasSB6)
For nX := 1 To Len(aStrucSB6)
	If ( aStrucSB6[nX][2] <> "C" .And. FieldPos(aStrucSB6[nX][1])<>0 )
		TcSetField(cAliasSB6,aStrucSB6[nX][1],aStrucSB6[nX][2],aStrucSB6[nX][3],aStrucSB6[nX][4])
	EndIf
Next

SetRegua(nRegs)

While !Eof() .And. B6_FILIAL == xFilial("SB6")
	
	IncRegua()
	
	If lEnd
		@Prow()+1,001 PSay "CANCELADO PELO OPERADOR"
		Exit
	Endif
	
	If !Empty(aReturn[7])
		If !&(aReturn[7])
			dbSkip()
			Loop
		EndIf
	EndIf
	
	dbSelectArea("SF4")
	MsSeek(xFilial("SF4")+(cAliasSB6)->B6_TES)
	If SF4->F4_PODER3 == "D"
		dbselectArea(cAliasSB6)
		dbSkip()
		Loop
	EndIf
	
	dbSelectArea(cAliasSB6)
	
	IF ( &cCondCli )
		aSaldo:=CalcTerc((cAliasSB6)->B6_PRODUTO,(cAliasSB6)->B6_CLIFOR,(cAliasSB6)->B6_LOJA,(cAliasSB6)->B6_IDENT,(cAliasSB6)->B6_TES,,mv_par09,mv_par10)
		dbSelectArea(cAliasSB6)
		nSaldo  := aSaldo[1]
		nPrUnit := IIF(aSaldo[3]==0,(cAliasSB6)->B6_PRUNIT,aSaldo[3])
	Else
		dbSkip()
		Loop
	Endif
	
	nCusTot:=0
	nQuant :=0
	nQuJe  :=0
	nTotal :=0
	nTotDev:=0
	nSaldo :=0
	aSaldo :={}
	nCusto :=0
	cQuebra:= (cAliasSB6)->B6_PRODUTO+(cAliasSB6)->B6_LOCAL
	
	While !Eof() .And. xFilial("SB6") == (cAliasSB6)->B6_FILIAL .And. cQuebra == (cAliasSB6)->B6_PRODUTO+(cAliasSB6)->B6_LOCAL
		
		IncRegua()
		
		If li > 55
			Cabec(titulo,cabec1,cabec2,nomeprog,Tamanho,nTipo)
		EndIf
		
		If !Empty(aReturn[7])
			If !&(aReturn[7])
				dbSkip()
				Loop
			EndIf
		EndIf
		
		dbSelectArea("SF4")
		MsSeek(xFilial("SF4")+(cAliasSB6)->B6_TES)
		If SF4->F4_PODER3 == "D"
			dbselectArea(cAliasSB6)
			dbSkip()
			loop
		Endif
		
		dbSelectArea(cAliasSB6)
		
		IF	( &cCondCli )
			aSaldo:=CalcTerc((cAliasSB6)->B6_PRODUTO,(cAliasSB6)->B6_CLIFOR,(cAliasSB6)->B6_LOJA,(cAliasSB6)->B6_IDENT,(cAliasSB6)->B6_TES,,mv_par09,mv_par10)
			dbSelectArea(cAliasSB6)
			nSaldo  := aSaldo[1]
			nPrUnit := IIF(aSaldo[3]==0,(cAliasSB6)->B6_PRUNIT,aSaldo[3])
			
			If cProdLOCAL != (cAliasSB6)->B6_PRODUTO+(cAliasSB6)->B6_LOCAL
				dbSelectArea("SB1")
				If MsSeek(xFilial("SB1")+(cAliasSB6)->B6_PRODUTO)
					If !Empty(cProdLOCAL)
						li += 2
					EndIf
					If li > 55
						Cabec(titulo,cabec1,cabec2,nomeprog,Tamanho,nTipo)
					EndIf
					@ li,000 PSay "PRODUTO / LOCAL: "+B1_COD+" - "+Trim(Substr(B1_DESC,1,30))+" / "+(cAliasSB6)->B6_LOCAL
					cProdLOCAL := (cAliasSB6)->B6_PRODUTO+(cAliasSB6)->B6_LOCAL
				Else
					Help(" ",1,"R480PRODUT")
					// Fecha a query
					If lQuery .And. Select(cAliasSB6) > 0
						(cAliasSB6)->(dbCloseArea())
					EndIf
					dbSelectArea("SB6")
					dbSetOrder(1)
					Return .F.
				EndIf
			EndIf
			dbSelectArea(cAliasSB6)
			
			If li > 55
				Cabec(titulo,cabec1,cabec2,nomeprog,Tamanho,nTipo)
			EndIf
			
			If !Empty(cProdLocal)
				
				li++
				@ li,000 PSay IIf((cAliasSB6)->B6_TPCF == "C","Clie:","Forn:")
				@ li,008 PSay (Substr((cAliasSB6)->B6_CLIFOR,1,15))
				@ li,025 PSay (cAliasSB6)->B6_LOJA
				@ li,030 PSay (cAliasSB6)->B6_DOC
				@ li,045+nIncCol PSay (cAliasSB6)->B6_SERIE
				@ li,050+nIncCol PSay Dtoc((cAliasSB6)->B6_EMISSAO)
				@ li,062+nIncCol PSay (cAliasSB6)->B6_UM
				
				// Quantidade Original
				@ li,068+nIncCol PSay (cAliasSB6)->B6_QUANT Picture cTamB6Qt
				nQuant += (cAliasSB6)->B6_QUANT
				
				// Quantidade Ja Entregue
				@ li,086+nIncCol PSay ((cAliasSB6)->B6_QUANT - nSaldo) Picture cTamB6Qt
				nQuJe += ((cAliasSB6)->B6_QUANT - nSaldo)
				
				// Saldo
				@ li,104+nIncCol PSay nSaldo Picture cTamB6Qt
				
				// Total Nota Fiscal
				@ li,122+nIncCol PSay Transform((cAliasSB6)->B6_QUANT * nPrUnit,'@E 99,999,999,999.99')
				nTotal += (cAliasSB6)->B6_QUANT * nPrUnit
				nGerTot+= (cAliasSB6)->B6_QUANT * nPrUnit
				
				// Total Nota Fiscal Devolvido
				@ li,140+nIncCol PSay Transform(((cAliasSB6)->B6_QUANT - nSaldo) * nPrUnit,'@E 99,999,999,999.99')
				nTotDev    += ((cAliasSB6)->B6_QUANT - nSaldo) * nPrUnit
				nGerTotDev += ((cAliasSB6)->B6_QUANT - nSaldo) * nPrUnit
				
				// Custo na Moeda
				nCusto := (&(If(lListCustM.Or.(!lListCustM.And.!lCusFIFO), 'B6_CUSTO', 'B6_CUSFF')+Str(1,1,0)) / (cAliasSB6)->B6_QUANT) * nSaldo
				nCusTot += nCusto
				nGerCusTot +=nCusto
				
				@ li,158+nIncCol PSay Transform(nCusto,'@E 999,999,999.99')
				@ li,173+nIncCol PSay (cAliasSB6)->B6_TIPO
				@ li,177+nIncCol PSay (cAliasSB6)->B6_SEGUM
				@ li,184 PSay (cAliasSB6)->B6_QTSEGUM Picture cTamB6Q2
				@ li,199 PSay Dtoc((cAliasSB6)->B6_DTDIGIT)
				@ li,210 PSay Dtoc((cAliasSB6)->B6_UENT)
				
				// Lista as devolucoes da remessa
				If (.t.) .And. (((cAliasSB6)->B6_QUANT - nSaldo) > 0)
					aAreaSB6 := (cAliasSB6)->(GetArea())
					SB6->(dbSetOrder(3))
					cSeek:=xFilial("SB6")+(cAliasSB6)->B6_IDENT+(cAliasSB6)->B6_PRODUTO+"D"
					If SB6->(dbSeek(cSeek))
						li++
						@ li,000 PSay "Notas Fiscais de Retorno"
						Do While !SB6->(Eof()) .And. SB6->B6_FILIAL+SB6->B6_IDENT+SB6->B6_PRODUTO+SB6->B6_PODER3 == cSeek
							If SB6->B6_DTDIGIT < mv_par11 .Or. SB6->B6_DTDIGIT > mv_par12
								DbSelectArea("SB6")
								DbSkip()
								Loop
							Endif
							If li > 55
								Cabec(titulo,cabec1,cabec2,nomeprog,Tamanho,nTipo)
							EndIf
							li++
							@ li,000 PSay IIf(SB6->B6_TPCF == "C","Clie:","Forn:")
							@ li,008 PSay (Substr(SB6->B6_CLIFOR,1,15))
							@ li,025 PSay SB6->B6_LOJA
							@ li,030 PSay SB6->B6_DOC
							@ li,045+nIncCol PSay SB6->B6_SERIE
							@ li,050+nIncCol PSay Dtoc(SB6->B6_EMISSAO)
							@ li,062+nIncCol PSay SB6->B6_UM
							// Quantidade Original
							@ li,068+nIncCol PSay SB6->B6_QUANT Picture cTamB6Qt
							
							// Total Nota Fiscal
							@ li,122+nIncCol PSay Transform(SB6->B6_QUANT * nPrUnit,'@E 99,999,999,999.99')
							@ li,173+nIncCol PSay SB6->B6_TIPO
							@ li,177+nIncCol PSay SB6->B6_SEGUM
							@ li,184 PSay SB6->B6_QTSEGUM Picture cTamB6Q2
							@ li,199 PSay Dtoc(SB6->B6_DTDIGIT)
							@ li,210 PSay Dtoc(SB6->B6_UENT)
							SB6->(dbSkip())
						EndDo
						li++
					EndIf
					RestArea(aAreaSB6)
					dbSelectArea(cAliasSB6)
				EndIf
			EndIf
		EndIf
		dbSkip()
	EndDo
	If nQuant > 0
		li++
		@ li,000 PSay "TOTAL DESTE PRODUTO / LOCAL ------ >"
		@ li,068+nIncCol PSay nQuant        		Picture PesqPict("SB6", "B6_QUANT",17)
		@ li,086+nIncCol PSay nQuje             	Picture PesqPict("SB6", "B6_QUANT",17)
		@ li,104+nIncCol PSay (nQuant - nQuJe)  	Picture PesqPict("SB6", "B6_QUANT",17)
		@ li,122+nIncCol PSay Transform(nTotal, '@E 99,999,999,999.99')
		@ li,140+nIncCol PSay Transform(nTotDev,'@E 99,999,999,999.99')
		@ li,158+nIncCol PSay Transform(nCusTot,'@E 999,999,999.99')
		nTotQuant += nQuant
		nTotQuje  += nQuje
		nTotSaldo += (nQuant - nQuJe)
	Endif
End

If nQuant > 0 .Or. nTotal > 0
	li++;li++
	@ li,000 PSay "T O T A L    G E R A L  ---------- >"
	@ li,068+nIncCol PSay nTotQuant Picture PesqPict("SB6","B6_QUANT",17)
	@ li,086+nIncCol PSay nTotQuJe  Picture PesqPict("SB6","B6_QUANT",17)
	@ li,104+nIncCol PSay nTotSaldo Picture PesqPict("SB6","B6_QUANT",17)
	@ li,122+nIncCol PSay Transform(nGerTot	  ,'@E 99,999,999,999.99')
	@ li,140+nIncCol PSay Transform(nGerTotDev,'@E 99,999,999,999.99')
	@ li,158+nIncCol PSay Transform(nGerCusTot,'@E 999,999,999.99')
	Roda(CbCont,CbTxt,Tamanho)
EndIf

// Fecha a query
If lQuery .And. Select(cAliasSB6) > 0
	(cAliasSB6)->(dbCloseArea())
EndIf
dbSelectArea("SB6")
Return .T.

// ** funcao que Imprime Por Ordem de Cliente / Fornecedor.
Static Function R480CliFor(lEnd,Tamanho)
LOCAL cCliFor     := ""
LOCAL cCliForAnt  := ""
LOCAL cQuebra     := ""
LOCAL cIndex      := ""
LOCAL cKey        := ""
LOCAL cNomeCliFor := ""
LOCAL cDescCliFor := ""
LOCAL cAliasSB6   := "SB6"
LOCAL nIncCol     := If(cPaisLoc == "MEX",7,0)
LOCAL nRegs       := SB6->(LastRec())
LOCAL lQuery      := .t.
LOCAL nGerTot     := 0
LOCAL nGerTotDev  := 0
LOCAL nGerCusTot  := 0
LOCAL nCusTot     := 0
LOCAL nQuant      := 0
LOCAL nQuJe       := 0
LOCAL nTotal      := 0
LOCAL nTotDev     := 0
LOCAL nTotQuant   := 0
LOCAL nTotQuJe    := 0
LOCAL nTotSaldo   := 0
LOCAL nIndex      := 0
LOCAL nSaldo      := 0
LOCAL nCusto      := 0
LOCAL nPrUnit     := 0
LOCAL nX          := 0
LOCAL aAreaSB6    := {}
LOCAL aStrucSB6   := {}
LOCAL aSaldo      := {}
LOCAL cVar,cFilter


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Montagem da Query para Performance do relatorio              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea("SB6")
dbSetOrder(1)

cAliasSB6 := GetNextAlias()
aStrucSB6 := SB6->(dbStruct())
cQuery	  := " SELECT SB6.* "
cQuery	  +=   " FROM " + RetSqlName("SB6") + " SB6"
cQuery    +=  " WHERE SB6.B6_FILIAL = '"   + xFilial("SB6") + "' "
cQuery    +=    " AND SB6.B6_CLIFOR BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' "
cQuery    +=    " AND SB6.B6_LOJA BETWEEN '"+mv_par05+"' AND '"+mv_par06+"' "
cQuery    +=    " AND SB6.B6_DTDIGIT BETWEEN '"+DtoS(mv_par09)+"' AND '"+DtoS(mv_par10)+"' "
cQuery    +=    " AND SB6.B6_PRODUTO >= '" + mv_par07 + "' "
cQuery    +=    " AND SB6.B6_PRODUTO <= '" + mv_par08 + "' "
cQuery    +=    " AND SB6.B6_PODER3 = 'R'
// programacao
cQuery    +=    " AND SB6.B6_IDENT IN ( "
cQuery    +=    "                      SELECT D1_IDENTB6 
cQuery    +=    "                      FROM "+RetSqlName("SD1")+" SD1 WHERE "+RetSqlCond("SD1")+" "
cQuery    +=    "                      AND D1_DTDIGIT BETWEEN '"+DtoS(mv_par09)+"' AND '"+DtoS(mv_par10)+"' "
cQuery    +=    "                      AND D1_FORNECE BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' "
cQuery    +=    "                      AND D1_LOJA BETWEEN '"+mv_par05+"' AND '"+mv_par06+"' "
cQuery    +=    "                      AND D1_TIPO IN ('B','D') "
cQuery    +=    "                      AND D1_PROGRAM BETWEEN '"+mv_par01+"' AND '"+mv_par02+"') "
// deletados
cQuery    +=    " AND SB6.D_E_L_E_T_ = ' ' "
// ordem dos dados
cQuery    +=  " ORDER BY B6_FILIAL,B6_TPCF,B6_CLIFOR,B6_LOJA,B6_PRODUTO "
cQuery:=ChangeQuery(cQuery)
MsAguarde({|| dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cAliasSB6,.F.,.T.)},"Processando ...")

dbSelectArea(cAliasSB6)
For nX := 1 To Len(aStrucSB6)
	If ( aStrucSB6[nX][2] <> "C" .And. FieldPos(aStrucSB6[nX][1])<>0 )
		TcSetField(cAliasSB6,aStrucSB6[nX][1],aStrucSB6[nX][2],aStrucSB6[nX][3],aStrucSB6[nX][4])
	EndIf
Next

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta o Cabecalho de acordo com o tipo de emissao            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
titulo := "RELACAO DE MATERIAIS DE TERCEIROS EM NOSSO PODER - CLIENTE / FORNECEDOR"

cabec1 := "                 -    Documento    -  Data de         Unid. de ---------------------- Quantidade ---------------------  ------------ Valores --------------  Custo do Prod. TM  Segunda   Quantidade     Data   Data da Ult.
cabec2 := "Produto          Numero        Serie  Emissao  Almox.  Medida        Original        Ja' entregue           Saldo       Total Nota Fiscal   Total Devolvido    na Moeda X       Unid. Med.   Seg. UM  Lancamento  Entrega

SetRegua(nRegs)

While !(cAliasSB6)->(Eof())
	
	IncRegua()
	
	If lEnd
		@Prow()+1,001 PSay "CANCELADO PELO OPERADOR"
		Exit
	EndIf
	
	If !Empty(aReturn[7])
		If !&(aReturn[7])
			dbSkip()
			Loop
		EndIf
	EndIf
	
	dbSelectArea("SF4")
	dbSeek(xFilial("SF4")+(cAliasSB6)->B6_TES)
	If SF4->F4_PODER3 == "D"
		dbselectArea(cAliasSB6)
		dbSkip()
		Loop
	EndIf
	
	dbSelectArea(cAliasSB6)
	
	IF ( &cCondCli )
		aSaldo:=CalcTerc((cAliasSB6)->B6_PRODUTO,(cAliasSB6)->B6_CLIFOR,(cAliasSB6)->B6_LOJA,(cAliasSB6)->B6_IDENT,(cAliasSB6)->B6_TES,,mv_par09,mv_par10)
		dbSelectArea(cAliasSB6)
		nSaldo:= aSaldo[1]
		nPrUnit := IIF(aSaldo[3]==0,(cAliasSB6)->B6_PRUNIT,aSaldo[3])
	Else
		dbSkip()
		Loop
	EndIf
	
	cQuebra  := (cAliasSB6)->B6_CLIFOR+(cAliasSB6)->B6_LOJA+(cAliasSB6)->B6_PRODUTO+(cAliasSB6)->B6_TPCF
	nCusTot  := 0
	nQuant	 := 0
	nQuJe	 := 0
	nTotal	 := 0
	nTotDev	 := 0
	
	Do While (cAliasSB6)->B6_CLIFOR+(cAliasSB6)->B6_LOJA+(cAliasSB6)->B6_PRODUTO+(cAliasSB6)->B6_TPCF == cQuebra
		
		IncRegua()
		
		If	! ( &cCondCli )
			dbSkip()
			Loop
		EndIf
		
		If !Empty(aReturn[7])
			If !&(aReturn[7])
				dbSkip()
				Loop
			EndIf
		EndIf
		
		dbSelectArea("SF4")
		dbSeek(xFilial("SF4")+(cAliasSB6)->B6_TES)
		If SF4->F4_PODER3 == "D"
			dbSelectArea(cAliasSB6)
			dbSkip()
			Loop
		Endif
		
		dbSelectArea(cAliasSB6)
		aSaldo:=CalcTerc((cAliasSB6)->B6_PRODUTO,(cAliasSB6)->B6_CLIFOR,(cAliasSB6)->B6_LOJA,(cAliasSB6)->B6_IDENT,(cAliasSB6)->B6_TES,,mv_par09,mv_par10)
		dbSelectArea(cAliasSB6)
		nSaldo:= aSaldo[1]
		
		
		If Li > 55
			Cabec(titulo,cabec1,cabec2,nomeprog,Tamanho,nTipo)
		EndIf
		
		If cCliForAnt != (cAliasSB6)->B6_TPCF .Or. cNomeCliFor != (cAliasSB6)->B6_CLIFOR+(cAliasSB6)->B6_LOJA
			dbSelectArea(IIf((cAliasSB6)->B6_TPCF == "C" , "SA1" , "SA2" ) )
			dbSeek(xFilial(IIf((cAliasSB6)->B6_TPCF == "C" , "SA1" , "SA2" ))+(cAliasSB6)->B6_CLIFOR+(cAliasSB6)->B6_LOJA)
			If Found()
				If !Empty(cDescCliFor)
					li++
				EndIf
				cDescCliFor	:= IIf((cAliasSB6)->B6_TPCF == "C" , "CLIENTE / LOJA: " , "FORNECEDOR / LOJA: ")
				@ li,000 PSay cDescCliFor+Trim( IIf((cAliasSB6)->B6_TPCF == "C" ,A1_COD+" - "+A1_NOME , A2_COD+" - "+A2_NOME )  )+" / "+IIf((cAliasSB6)->B6_TPCF == "C" , A1_LOJA , A2_LOJA )
				cNomeCliFor := (cAliasSB6)->B6_CLIFOR+(cAliasSB6)->B6_LOJA
				cCliForAnt 	:= (cAliasSB6)->B6_TPCF
			Else
				Help(" ",1,"R480CLIFOR")
				If lQuery
					If Select(cAliasSB6) > 0
						(cAliasSB6)->(dbCloseArea())
					EndIf
					dbSelectArea("SB6")
				Else
					RetIndex("SB6")
					dbSelectArea("SB6")
					dbSetOrder(1)
					cIndex += OrdBagExt()
					Ferase(cIndex)
				EndIf
				Return .F.
			EndIf
			dbSelectArea(cAliasSB6)
		EndIf
		
		If Li > 55
			Cabec(titulo,cabec1,cabec2,nomeprog,Tamanho,nTipo)
		EndIf
		
		If Len(cNomeCliFor) != 0
			li++
			@ li,000 PSay (cAliasSB6)->B6_PRODUTO
			@ li,017 PSay (cAliasSB6)->B6_DOC
			@ li,033+nIncCol PSay (cAliasSB6)->B6_SERIE
			@ li,038+nIncCol PSay Dtoc((cAliasSB6)->B6_EMISSAO)
			@ li,049+nIncCol PSay (cAliasSB6)->B6_LOCAL
			@ li,057+nIncCol PSay (cAliasSB6)->B6_UM
			
			// Quantidade Original
			@ li,063+nIncCol PSay (cAliasSB6)->B6_QUANT Picture PesqPict("SB6", "B6_QUANT",17)
			nQuant     += (cAliasSB6)->B6_QUANT
			
			// localiza Saldo
			aSaldo:=CalcTerc((cAliasSB6)->B6_PRODUTO,(cAliasSB6)->B6_CLIFOR,(cAliasSB6)->B6_LOJA,(cAliasSB6)->B6_IDENT,(cAliasSB6)->B6_TES,,mv_par09,mv_par10)
			dbSelectArea(cAliasSB6)
			nSaldo  := aSaldo[1]
			nPrUnit := IIF(aSaldo[3]==0,(cAliasSB6)->B6_PRUNIT,aSaldo[3])
			
			// Quantidade Ja Entregue
			@ li,082+nIncCol PSay ((cAliasSB6)->B6_QUANT - nSaldo) Picture PesqPict("SB6", "B6_QUANT",17)
			nQuJe     +=  ((cAliasSB6)->B6_QUANT - nSaldo)
			
			// Saldo
			@ li,101+nIncCol PSay nSaldo Picture PesqPict("SB6", "B6_QUANT",17)
			
			// Total da Nota Fiscal
			@ li,120+nIncCol PSay Transform((cAliasSB6)->B6_QUANT * nPrUnit,'@E 99,999,999,999.99')
			nTotal	+= (cAliasSB6)->B6_QUANT * nPrUnit
			nGerTot	+= (cAliasSB6)->B6_QUANT * nPrUnit
			
			// Total da Nota Fiscal Devolvido
			@ li,138+nIncCol PSay Transform(((cAliasSB6)->B6_QUANT - nSaldo) * nPrUnit,'@E 99,999,999,999.99')
			nTotDev		+= ((cAliasSB6)->B6_QUANT - nSaldo) * nPrUnit
			nGerTotDev	+= ((cAliasSB6)->B6_QUANT - nSaldo) * nPrUnit
			nCusto 		:= (&(If(lListCustM.Or.(!lListCustM.And.!lCusFIFO), 'B6_CUSTO', 'B6_CUSFF')+Str(1,1,0)) / (cAliasSB6)->B6_QUANT) * nSaldo
			nCusTot 	+= nCusto
			nGerCusTot 	+= nCusto
			
			@ li,156+nIncCol PSay Transform(nCusto,'@E 999,999,999.99')
			@ li,172+nIncCol PSay (cAliasSB6)->B6_TIPO
			@ li,176+nIncCol PSay (cAliasSB6)->B6_SEGUM
			@ li,184 PSay (cAliasSB6)->B6_QTSEGUM Picture PesqPict("SB6", "B6_QTSEGUM",12)
			@ li,199 PSay Dtoc((cAliasSB6)->B6_DTDIGIT)
			@ li,210 PSay Dtoc((cAliasSB6)->B6_UENT)
		EndIf
		
		// Lista as devolucoes da remessa
		If (.t.) .And. (((cAliasSB6)->B6_QUANT - nSaldo) > 0)
			aAreaSB6 := (cAliasSB6)->(GetArea())
			SB6->(dbSetOrder(3))
			cSeek:=xFilial("SB6")+(cAliasSB6)->B6_IDENT+(cAliasSB6)->B6_PRODUTO+"D"
			If SB6->(dbSeek(cSeek))
				li++
				@ li,000 PSay "Notas Fiscais de Retorno"
				Do While !SB6->(Eof()) .And. SB6->B6_FILIAL+SB6->B6_IDENT+SB6->B6_PRODUTO+SB6->B6_PODER3 == cSeek
					If SB6->B6_DTDIGIT < mv_par11 .Or. SB6->B6_DTDIGIT > mv_par12
						DbSelectArea("SB6")
						DbSkip()
						Loop
					EndIf
					If li > 55
						Cabec(titulo,cabec1,cabec2,nomeprog,Tamanho,nTipo)
					EndIf
					li++
					@ li,017 PSay SB6->B6_DOC
					@ li,033+nIncCol PSay SB6->B6_SERIE
					@ li,038+nIncCol PSay Dtoc(SB6->B6_EMISSAO)
					@ li,049+nIncCol PSay SB6->B6_LOCAL
					@ li,057+nIncCol PSay SB6->B6_UM
					// Quantidade Original
					@ li,063+nIncCol PSay SB6->B6_QUANT Picture PesqPict("SB6", "B6_QUANT",17)
					// Total da Nota Fiscal
					@ li,120+nIncCol PSay Transform(SB6->B6_QUANT * nPrUnit,'@E 99,999,999,999.99')
					// Total da Nota Fiscal Devolvido
					@ li,172+nIncCol PSay SB6->B6_TIPO
					@ li,176+nIncCol PSay SB6->B6_SEGUM
					@ li,184 PSay SB6->B6_QTSEGUM Picture PesqPict("SB6", "B6_QTSEGUM",12)
					@ li,199 PSay Dtoc(SB6->B6_DTDIGIT)
					@ li,210 PSay Dtoc(SB6->B6_UENT)
					SB6->(dbSkip())
				EndDo
				li++
			EndIf
			RestArea(aAreaSB6)
			If lQuery
				dbSelectArea(cAliasSB6)
			Else
				dbSetOrder(nIndex+1)
			EndIf
		EndIf
		dbSkip()
	EndDo
	If nQuant > 0
		li++
		If !lQuery
			dbSkip(-1)
		EndIf
		cVar:=IIF(B6_TPCF == "C" ,"CLIENTE ---->","FORNECEDOR --->")
		If !lQuery
			dbSkip()
		EndIf
		IncRegua()
		If li > 55
			Cabec(titulo,cabec1,cabec2,nomeprog,Tamanho,nTipo)
		EndIf
		@ li,000 PSay "TOTAL DO PRODUTO NO " +cVar
		@ li,063+nIncCol PSay nQuant			Picture PesqPict("SB6", "B6_QUANT",17)
		@ li,082+nIncCol PSay nQuje				Picture PesqPict("SB6", "B6_QUANT",17)
		@ li,101+nIncCol PSay (nQuant - nQuJe)	Picture PesqPict("SB6", "B6_QUANT",17)
		@ li,119+nIncCol PSay Transform(nTotal ,'@E 999,999,999,999.99')
		@ li,137+nIncCol PSay Transform(nTotDev,'@E 999,999,999,999.99')
		@ li,156+nIncCol PSay Transform(nCusTot,'@E 999,999,999.99')
		li++
		nTotQuant += nQuant
		nTotQuJe  += nQuje
		nTotSaldo += (nQuant - nQuJe)
	Endif
End
If Len(cNomeCliFor) != 0
	li++
	@ li,000 PSay "T O T A L    G E R A L  ---------- >"
	@ li,063+nIncCol PSay nTotQuant Picture PesqPict("SB6", "B6_QUANT",17)
	@ li,082+nIncCol PSay nTotQuJe  Picture PesqPict("SB6", "B6_QUANT",17)
	@ li,101+nIncCol PSay nTotSaldo Picture PesqPict("SB6", "B6_QUANT",17)
	@ li,119+nIncCol PSay Transform(nGerTot	 ,'@E 999,999,999,999.99')
	@ li,137+nIncCol PSay Transform(nGerTotDev,'@E 999,999,999,999.99')
	@ li,156+nIncCol PSay Transform(nGerCusTot,'@E 999,999,999.99')
	Roda(CbCont,CbTxt,Tamanho)
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Devolve condicao original ao SB6 e apaga arquivo de trabalho.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lQuery
	If Select(cAliasSB6) > 0
		(cAliasSB6)->(dbCloseArea())
	EndIf
	dbSelectArea("SB6")
Else
	RetIndex("SB6")
	dbSelectArea("SB6")
	dbSetOrder(1)
	cIndex += OrdBagExt()
	Ferase(cIndex)
EndIf
Return .T.