#INCLUDE "rwmake.ch"
#include "topconn.ch"

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±± Programa  ±ART374    ± Autor ± CLOVIS EMMENDORFER º Data ³  22/01/10   º±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±± Descricao ± RELATORIO DE FATURAMENTO POR CLIENTE                       º±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±± Uso       ± Especifico para Arteplas                                   º±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
/*/

User Function ART374()

LOCAL cDesc1       := "Este programa tem como objetivo imprimir relatorio "
LOCAL cDesc2       := "de acordo com os parametros informados pelo usuario."
LOCAL cDesc3       := "Relatorio gerencial de faturamento - Cliente."
LOCAL cPict        := ""
LOCAL titulo       := "Ultimas Vendas por Cliente"
LOCAL nLin         := 80
LOCAL cString      := ""
LOCAL Cabec1       := ""
LOCAL Cabec2       := ""
LOCAL imprime      := .T.
LOCAL aOrd         := {}
Private lEnd       := .F.
Private lAbortPrint:= .F.
Private CbTxt      := ""
Private limite     := 132
Private tamanho    := "G"
Private nomeprog   := "ART374"
Private nTipo      := 18
Private aReturn    := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey   := 0
Private cPerg      := "ART374"
Private cbtxt      := Space(10)
Private cbcont     := 00
Private CONTFL     := 01
Private m_pag      := 01
Private wnrel      := "ART374"

cPerg := "ART374"
aRegistros := {}
AADD(aRegistros,{cPerg,"01","Produto de  ?","","","mv_ch1","C",15,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SB1","","","",""})
AADD(aRegistros,{cPerg,"02","Produto ate ?","","","mv_ch2","C",15,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SB1","","","",""})
AADD(aRegistros,{cPerg,"03","Cliente de  ?","","","mv_ch3","C",06,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","",""})
AADD(aRegistros,{cPerg,"04","Cliente ate ?","","","mv_ch4","C",06,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","",""})
AADD(aRegistros,{cPerg,"05","Vendedor de ?","","","mv_ch5","C",06,0,0,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","SA3","","","",""})
AADD(aRegistros,{cPerg,"06","Vendedor ate?","","","mv_ch6","C",06,0,0,"G","","mv_par06","","","","","","","","","","","","","","","","","","","","","","","","","SA3","","","",""})
AADD(aRegistros,{cPerg,"07","Data de     ?","","","mv_ch7","D",08,0,0,"G","","mv_par07","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"08","Data ate    ?","","","mv_ch8","D",08,0,0,"G","","mv_par08","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

dbSelectArea("SX1")
dbSeek(cPerg)
If !Found()
	dbSeek(cPerg)
	While SX1->X1_GRUPO==cPerg.and.!Eof()
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock("SX1")
		dbSkip()
	End
	For i:=1 to Len(aRegistros)
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			FieldPut(j,aRegistros[i,j])
		Next
		MsUnlock("SX1")
	Next
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

pergunte(cPerg,.F.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta a interface padrao com o usuario...                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

wnrel := SetPrint(cString,NomeProg,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)

If nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
	Return
Endif

nTipo := If(aReturn[4]==1,15,18)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Processamento. RPTSTATUS monta janela com a regua de processamento. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFun‡„o    ³RUNREPORT º Autor ³ AP6 IDE            º Data ³  29/11/06   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescri‡„o ³ Funcao auxiliar chamada pela RPTSTATUS. A funcao RPTSTATUS º±±
±±º          ³ monta a janela com a regua de processamento.               º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Programa principal                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)

cQry := "SELECT A1_COD,A1_LOJA,A1_NREDUZ,A1_CGC,A1_END,A1_BAIRRO,A1_CEP,A1_MUN,A1_EST,A1_TEL,A1_PRICOM,A1_ULTCOM,A1_NROCOM "
cQry += "FROM " + RETSQLNAME("SA1") + " SA1 "
cQry += "WHERE SA1.D_E_L_E_T_ <> '*' AND "
cQry += "A1_FILIAL = '" + xFilial("SA1") + "' AND A1_PRICOM <> '' AND A1_ULTCOM <> '' AND "
cQry += "A1_COD BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "' AND "
cQry += "A1_VEND BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' AND "
cQry += "A1_ULTCOM BETWEEN '" + DTOS(mv_par07) + "' AND '" + DTOS(mv_par08) + "' "
cQry += "ORDER BY A1_COD "

If (Select("ART") <> 0)
	dbSelectArea("ART")
	dbCloseArea()
Endif

TCQUERY cQry NEW Alias "ART"

dbSelectArea("ART")
dbGoTop()

cCliente := ''

While !EOF()
	
	cDoc := ''
	
	cQry := " SELECT DISTINCT D2_DOC "
	cQry += "FROM " + RETSQLNAME("SD2") + " SD2, "
	cQry += " " + RETSQLNAME("SF4") + " SF4 "
	cQry += "WHERE SD2.D_E_L_E_T_ <> '*' AND SF4.D_E_L_E_T_ <> '*' AND "
	cQry += "F4_FILIAL = '" + xFilial("SF4") + "' AND "
	cQry += "D2_FILIAL = '" + xFilial("SD2") + "' AND "
	cQry += "D2_COD BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' AND "
	cQry += "D2_CLIENTE = '" + ART->A1_COD + "' AND "
	cQry += "D2_EMISSAO BETWEEN '" + DTOS(mv_par07) + "' AND '" + DTOS(mv_par08) + "' "
	cQry += "AND F4_CODIGO = D2_TES AND F4_DUPLIC = 'S' AND (D2_TIPO = 'N' OR D2_TIPO = 'C') AND D2_TES <> '604' "
	cQry += "ORDER BY D2_DOC "
	
	If (Select("CLE") <> 0)
		dbSelectArea("CLE")
		dbCloseArea()
	Endif
	
	TCQUERY cQry NEW Alias "CLE"
	
	While !EOF()
		
		cDoc := CLE->D2_DOC
		
		dbSkip()
		
	Enddo
	
	cRedesp   := ''
	nTotFat   := 0
	nTotFatG  := 0
	nTotQuant := 0
	nTotQG    := 0
	
	cQry := "SELECT D2_DOC,D2_TOTAL,D2_QUANT,D2_COD,B1_DESC,D2_UM,D2_PRCVEN,C5_REDESP, "
	cQry += "E4_DESCRI,A4_NREDUZ,C5_TIPC,D2_VALIPI,D2_QTSEGUM,D2_SEGUM,D2_PESO "
	cQry += "FROM " + RETSQLNAME("SB1") + " SB1, "
	cQry += " " + RETSQLNAME("SD2") + " SD2, "
	cQry += " " + RETSQLNAME("SE4") + " SE4, "
	cQry += " " + RETSQLNAME("SA4") + " SA4, "
	cQry += " " + RETSQLNAME("SF2") + " SF2, "
	cQry += " " + RETSQLNAME("SC5") + " SC5, "
	cQry += " " + RETSQLNAME("SF4") + " SF4 "
	cQry += "WHERE SB1.D_E_L_E_T_ <> '*' AND "
	cQry += "SD2.D_E_L_E_T_ <> '*' AND "
	cQry += "SE4.D_E_L_E_T_ <> '*' AND "
	cQry += "SA4.D_E_L_E_T_ <> '*' AND "
	cQry += "SF2.D_E_L_E_T_ <> '*' AND "
	cQry += "SF4.D_E_L_E_T_ <> '*' AND "
	cQry += "SC5.D_E_L_E_T_ <> '*' AND "
	cQry += "B1_FILIAL = '" + xFilial("SB1") + "' AND "
	cQry += "D2_FILIAL = '" + xFilial("SD2") + "' AND "
	cQry += "D2_DOC = '" + cDoc + "' AND "
	cQry += "E4_FILIAL = '" + xFilial("SE4") + "' AND "
	cQry += "A4_FILIAL = '" + xFilial("SA4") + "' AND "
	cQry += "F2_FILIAL = '" + xFilial("SF2") + "' AND "
	cQry += "F4_FILIAL = '" + xFilial("SF4") + "' AND "
	cQry += "C5_FILIAL = '" + xFilial("SC5") + "' AND "
	cQry += "D2_EMISSAO BETWEEN '" + DTOS(mv_par07) + "' AND '" + DTOS(mv_par08) + "' AND "
	cQry += "B1_COD BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' AND "
	cQry += "D2_CLIENTE = '" + ART->A1_COD + "' AND "
	cQry += "B1_COD = D2_COD AND F4_CODIGO = D2_TES AND E4_CODIGO = F2_COND AND "
	cQry += "(F4_DUPLIC = 'S' OR D2_TES = '547') AND (D2_TIPO = 'N' OR D2_TIPO = 'C') AND D2_TES <> '604' AND C5_NUM = D2_PEDIDO AND "
	cQry += "F2_DOC = D2_DOC AND A4_COD = F2_TRANSP "
	cQry += "ORDER BY D2_DOC,D2_COD "
	
	If (Select("TRA") <> 0)
		dbSelectArea("TRA")
		dbCloseArea()
	Endif
	
	TCQUERY cQry NEW Alias "TRA"
	
	dbSelectArea("TRA")
	dbGoTop()
	
	If !Empty(TRA->D2_DOC)
		
		cRedesp := Posicione("SA4",1,xFilial("SA4")+TRA->C5_REDESP,"A4_NREDUZ")
		
		While !EOF()
			
			If TRA->C5_TIPC == 'S'
				nTotFat  := TRA->D2_TOTAL * 2
				nTotFatG += TRA->D2_TOTAL * 2
			Else
				If TRA->C5_TIPC == 'E'
					nTotFat  := TRA->D2_TOTAL + (TRA->D2_TOTAL * 80 / 20)
					nTotFatG += TRA->D2_TOTAL + (TRA->D2_TOTAL * 80 / 20)
				Else
					nTotFat  := TRA->D2_TOTAL
					nTotFatG += TRA->D2_TOTAL
				Endif
			Endif
			
			//Acrescenta valor do IPI
			nTotFat  += TRA->D2_VALIPI
			nTotFatG += TRA->D2_VALIPI
			
			If TRA->D2_UM == 'KG'
				nTotQuant := TRA->D2_QUANT
			Else
				If TRA->D2_SEGUM == 'KG'
					nTotQuant := TRA->D2_QTSEGUM
				Else
					If TRA->D2_UM == 'PC'
						nTotQuant := TRA->D2_QUANT * TRA->D2_PESO
					Endif
				Endif
			Endif
			
			nTotQG += nTotQuant
			
			SetRegua(RecCount("TRA"))
			
			If lAbortPrint
				@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
				Exit
			Endif
			
			//123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
			//         1         2         3         4         5         6         7         8         9         10        11        12        13        14        15
			//CLIENTE : 999999 XXXXXXXXXXXXXXXXXXXX  CNPJ: 99.999.999/9999-99  NRO COMPRAS: 9.999  PRIM. COMPRA: 99/99/9999  ULT. COMPRA: 99/99/9999
			//ENDEREÇO: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX               TELEFONE: 999999999999999
			//BAIRRO  : XXXXXXXXXXXXXXXXXXXX         MUN.: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX          EST.: XX                  CEP: 99999-999
			//
			//PRODUTO                                              QTDE          PRC VENDA     TOTAL           COND. PAGTO           TRANSP           REDESPACHO
			//999999999999999 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  9.999.999,99  999.999,9999  999.999.999,99  XXXXXXXXXXXXXXXXXXXX  XXXXXXXXXXXXXXX  XXXXXXXXXXXXXXX
			
			If nLin > 55
				
				Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
				
				nLin := 6
				
			Endif
			
			If cCliente <> ART->A1_COD
				
				nLin++
				nLin++
				
				@nLin,001 pSay "CLIENTE :"
				@nLin,011 pSay ART->A1_COD
				@nLin,018 pSay ART->A1_NREDUZ
				@nLin,040 pSay "CNPJ:"
				@nLin,046 pSay ART->A1_CGC Picture "@R 99.999.999/9999-99"
				@nLin,066 pSay "NRO COMPRAS:"
				@nLin,079 pSay ART->A1_NROCOM Picture "@E 9,999"
				@nLin,086 pSay "PRIM. COMPRA:"
				@nLin,100 pSay DTOC(STOD(ART->A1_PRICOM))
				@nLin,112 pSay "ULT. COMPRA:"
				@nLin,125 pSay DTOC(STOD(ART->A1_ULTCOM))
				
				nLin++
				
				@nLin,001 pSay "ENDEREÇO: " + ART->A1_END
				@nLin,086 pSay "TELEFONE: " + ART->A1_TEL
				
				nLin++
				
				@nLin,001 pSay "BAIRRO  : " + ART->A1_BAIRRO
				@nLin,040 pSay "MUN.: " + ART->A1_MUN
				@nLin,086 pSay "EST.: " + ART->A1_EST
				@nLin,112 pSay "CEP: "
				@nLin,117 pSay ART->A1_CEP Picture "@R 99999-999"
				
				nLin++
				nLin++
				
				@nLin,001 pSay "PRODUTO                                              QTDE          PRC VENDA     TOTAL           COND. PAGTO           TRANSP           REDESPACHO"
				
				nLin++
				
				cCliente := ART->A1_COD
				
			Endif
			
			@nLin,001 pSay TRA->D2_COD
			@nLin,017 pSay TRA->B1_DESC
			@nLin,054 pSay nTotQuant    	PICTURE "@E 9,999,999.99"
			@nLin,068 pSay TRA->D2_PRCVEN	PICTURE "@E 999,999.9999"
			@nLin,082 pSay nTotFat      	PICTURE "@E 999,999,999.99"
			@nLin,098 pSay TRA->E4_DESCRI
			@nLin,120 pSay TRA->A4_NREDUZ
			@nLin,137 pSay cRedesp
			
			nLin++
			nTotFat   := 0
			nTotQuant := 0
			
			dbSelectArea("TRA")
			dbSkip()
			
		Enddo
		
		nLin++
		@nLin,035 pSay "TOTAL --->"
		@nLin,054 pSay nTotQG        	PICTURE "@E 9,999,999.99"
		@nLin,082 pSay nTotFatG      	PICTURE "@E 999,999,999.99"
		
	Endif
	
	dbSelectArea("ART")
	dbSkip()
	
Enddo

DbCloseArea("ART")
DbCloseArea("TRA")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Finaliza a execucao do relatorio...                                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

SET DEVICE TO SCREEN

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Se impressao em disco, chama o gerenciador de impressao...          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If aReturn[5]==1
	dbCommitAll()
	SET PRINTER TO
	OurSpool(wnrel)
Endif

MS_FLUSH()

Return
