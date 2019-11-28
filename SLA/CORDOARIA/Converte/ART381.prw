#INCLUDE "rwmake.ch"
#include "topconn.ch"

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±± Programa  ±ART381    ± Autor ± CLOVIS EMMENDORFER º Data ³  12/05/10   º±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±± Descricao ± RELATORIO GERENCIAL DE FATURAMENTO                         º±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±± Uso       ± Especifico para Arteplas                                   º±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
/*/

User Function ART381()

LOCAL cDesc1       := "Este programa tem como objetivo imprimir relatorio "
LOCAL cDesc2       := "de acordo com os parametros informados pelo usuario."
LOCAL cDesc3       := "Relatorio gerencial de faturamento."
LOCAL cPict        := ""
LOCAL titulo       := "Visão Gerencial do Faturamento"
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
Private tamanho    := "M"
Private nomeprog   := "ART381"
Private nTipo      := 18
Private aReturn    := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey   := 0
Private cPerg      := "ART381"
Private cbtxt      := Space(10)
Private cbcont     := 00
Private CONTFL     := 01
Private m_pag      := 01
Private wnrel      := "ART381"

cPerg := "ART381"
aRegistros := {}
AADD(aRegistros,{cPerg,"01","Produto de  ?","","","mv_ch1","C",15,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SB1","","","","",""})
AADD(aRegistros,{cPerg,"02","Produto ate ?","","","mv_ch2","C",15,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SB1","","","","",""})
AADD(aRegistros,{cPerg,"03","Data de     ?","","","mv_ch3","D",08,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"04","Data ate    ?","","","mv_ch4","D",08,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"05","Cliente de  ?","","","mv_ch5","C",06,0,0,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","","",""})
AADD(aRegistros,{cPerg,"06","Cliente ate ?","","","mv_ch6","C",06,0,0,"G","","mv_par06","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","","",""})

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

aStru := {}
bStru := {}

//FATURAMENTO
Aadd(aStru,{ "GRUPO     ", "C", 4 , 0 } ) //Grupos Analíticos
Aadd(aStru,{ "DESC      ", "C", 50, 0 } )
Aadd(aStru,{ "TOTAL     ", "N", 14, 2 } )
Aadd(aStru,{ "QUANT     ", "N", 11, 2 } ) //Quantidade em quilos

cTemp := CriaTrab(aStru,.t.)
Use &cTemp. Alias TRA New
Index on GRUPO to &cTemp.

// ALTERAR O  CÓDIGO PARA CONSIDERAR O B1_GRUPO E ALTERAR A QUERY RETIRANDO O AS D2_GRUPO

cQry := "SELECT D2_COD,D2_GRUPO,D2_TOTAL,D2_QUANT,C5_TIPC,C5_TIPO,D2_QTSEGUM,D2_VALIPI,D2_TES,D2_SEGUM,D2_UM,D2_PESO,D2_ICMSRET,D2_EST,
cQry += "D2_SEGURO,D2_VALFRE "
cQry += "FROM " + RETSQLNAME("SD2") + " SD2, "
cQry += " " + RETSQLNAME("SF4") + " SF4, "
cQry += " " + RETSQLNAME("SC5") + " SC5, "
cQry += " " + RETSQLNAME("SB1") + " SB1 "
cQry += "WHERE SD2.D_E_L_E_T_ <> '*' AND "
cQry += "SF4.D_E_L_E_T_ <> '*' AND "
cQry += "SC5.D_E_L_E_T_ <> '*' AND "
cQry += "D2_FILIAL = '" + xFilial("SD2") + "' AND "
cQry += "F4_FILIAL = '" + xFilial("SF4") + "' AND "
cQry += "C5_FILIAL = '" + xFilial("SC5") + "' AND "
cQry += "D2_COD BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' AND "
cQry += "D2_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' AND "
cQry += "D2_CLIENTE BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' AND "
cQry += "F4_CODIGO = D2_TES AND "
cQry += "F4_DUPLIC = 'S' AND (D2_TIPO = 'N' OR D2_TIPO = 'C') AND C5_NUM = D2_PEDIDO AND "
cQry += "B1_COD = D2_COD "
cQry += "ORDER BY D2_GRUPO "

If (Select("ART") <> 0)
	dbSelectArea("ART")
	dbCloseArea()
Endif

TCQUERY cQry NEW Alias "ART"

dbSelectArea("ART")
dbGoTop()

nFatAux := 0
nFatGru := 0
nQtAux  := 0
nQtGru  := 0
nValPE  := 0
nQtdPE  := 0
nValGra := 0
nQtdGra := 0
nValTel := 0
nQtdTel := 0
nValCat := 0
nQtdCat := 0
nValRes := 0
nQtdRes := 0
nValExp := 0
nQtdExp := 0
nValGer := 0
nQtdGer := 0
cGrupo  := ART->D2_GRUPO
cOK     := 'N'

//CORDAS PET
CORINTFAT := 0 //VENDAS INTERNAS
CORINTQTD := 0 //QTDE VENDAS INTERNAS
COREXPFAT := 0 //VENDAS EXPORTAÇÃO
COREXPQTD := 0 //QTDE EXPORTAÇÃO
CORTRFFAT := 0 //Z3 TRF
CORTRFQTD := 0 //Z3 QTDE
//FIBRAS PET
FIBINTFAT := 0
FIBINTQTD := 0
FIBEXPFAT := 0
FIBEXPQTD := 0
FIBTRFFAT := 0
FIBTRFQTD := 0
//FIOS PET
FIOINTFAT := 0
FIOINTQTD := 0
FIOEXPFAT := 0
FIOEXPQTD := 0
FIOTRFFAT := 0
FIOTRFQTD := 0
//CORDAS PE
CPEINTFAT := 0
CPEINTQTD := 0
CPEEXPFAT := 0
CPEEXPQTD := 0
CPETRFFAT := 0
CPETRFQTD := 0
//CORDAS PP
CPPINTFAT := 0
CPPINTQTD := 0
CPPEXPFAT := 0
CPPEXPQTD := 0
CPPTRFFAT := 0
CPPTRFQTD := 0
//GRÃOS PP/PE
GREINTFAT := 0
GREINTQTD := 0
GREEXPFAT := 0
GREEXPQTD := 0
GRETRFFAT := 0
GRETRFQTD := 0
//GRÃOS PP/RF
GRFINTFAT := 0
GRFINTQTD := 0
GRFEXPFAT := 0
GRFEXPQTD := 0
GRFTRFFAT := 0
GRFTRFQTD := 0
//TELHAS
TELINTFAT := 0
TELINTQTD := 0
TELEXPFAT := 0
TELEXPQTD := 0
TELTRFFAT := 0
TELTRFQTD := 0
//CATRACAS
CATINTFAT := 0
CATINTQTD := 0
CATEXPFAT := 0
CATEXPQTD := 0
CATTRFFAT := 0
CATTRFQTD := 0
//RESIDUOS
RESINTFAT := 0
RESINTQTD := 0
//EXPOSITORES
EXPINTFAT := 0
EXPINTQTD := 0
//INJETADOS
INJINTFAT := 0 //VENDAS INTERNAS
INJINTQTD := 0 //QTDE VENDAS INTERNAS
INJEXPFAT := 0 //VENDAS EXPORTAÇÃO
INJEXPQTD := 0 //QTDE EXPORTAÇÃO
INJTRFFAT := 0 //Z3 TRF
INJTRFQTD := 0 //Z3 QTDE
//OUTRAS VENDAS
OUTINTFAT := 0
OUTINTQTD := 0

While !EOF()
	
	If ART->C5_TIPC == 'S'
		nFatAux := ART->D2_TOTAL * 2
	Else
		If ART->C5_TIPC == 'E'
			nFatAux := ART->D2_TOTAL + (ART->D2_TOTAL * 80 / 20)
		Else
			nFatAux := ART->D2_TOTAL
		Endif
	Endif
	
	If ART->D2_UM == 'KG'
		nQtAux := ART->D2_QUANT
	Else
		If ART->D2_SEGUM == 'KG'
			nQtAux := ART->D2_QTSEGUM
		Else
			If ART->D2_UM <> 'KG' .and. ART->D2_SEGUM <> 'KG'
				nQtAux := ART->D2_QUANT * ART->D2_PESO
			Endif
		Endif
	Endif
	
	If ART->C5_TIPO = 'N'
		nFatGru += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET
		Else                                                     
		nFatGru += nFatAux + ART->D2_VALIPI
	EndIf
	nQtGru  += nQtAux           
	
	If ART->D2_GRUPO >= 'A' .AND. ART->D2_GRUPO <= 'BZZZ' //Cordas PET
	
		If ART->D2_EST <> 'EX' .AND. ART->D2_TES <> '604' //Vendas Internas
			If ART->C5_TIPO = 'N' // Pedido Normal
				CORINTFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET
			Else                                                   
				CORINTFAT += nFatAux + ART->D2_VALIPI
			EndIf
			CORINTQTD += nQtAux
		Endif
	
		If ART->D2_TES = '604' //Z3
			CORTRFFAT += nFatAux
			CORTRFQTD += nQtAux
		Endif
	
		If ART->D2_EST = 'EX' //Exportações
			COREXPFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET + ART->D2_SEGURO + ART->D2_VALFRE
			COREXPQTD += nQtAux
		Endif 
		
		cOK := 'S'

	Endif
	
	If ART->D2_GRUPO >= 'H' .AND. ART->D2_GRUPO <= 'HZZZ' //Fibras PET
	
		If ART->D2_EST <> 'EX' .AND. ART->D2_TES <> '604' //Vendas Internas
			If ART->C5_TIPO = 'N' // Pedido Normal                 
				FIBINTFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET
			Else
				FIBINTFAT += nFatAux + ART->D2_VALIPI
			EndIf
			FIBINTQTD += nQtAux
		Endif
	
		If ART->D2_TES = '604' //Z3
			FIBTRFFAT += nFatAux
			FIBTRFQTD += nQtAux
		Endif
	
		If ART->D2_EST = 'EX' //Exportações
			FIBEXPFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET + ART->D2_SEGURO + ART->D2_VALFRE
			FIBEXPQTD += nQtAux
		Endif
		
		cOK := 'S'

	Endif
	
	If (ART->D2_GRUPO >= 'I' .AND. ART->D2_GRUPO <= 'IZZZ') .OR. (ALLTRIM(ART->D2_GRUPO) >= '03' .AND. ART->D2_GRUPO <= '0399') .OR. ALLTRIM(ART->D2_GRUPO) == '52'//Fios PET
	
		If ART->D2_EST <> 'EX' .AND. ART->D2_TES <> '604' //Vendas Internas
			If ART->C5_TIPO = 'N' // Pedido Normal                 
				FIOINTFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET
			Else
				FIOINTFAT += nFatAux + ART->D2_VALIPI 
			EndIf
			FIOINTQTD += nQtAux
		Endif
	
		If ART->D2_TES = '604' //Z3
			FIOTRFFAT += nFatAux
			FIOTRFQTD += nQtAux
		Endif
	
		If ART->D2_EST = 'EX' //Exportações
			FIOEXPFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET + ART->D2_SEGURO + ART->D2_VALFRE
			FIOEXPQTD += nQtAux
		Endif
		
		cOK := 'S'

	Endif
	
	If Substr(ART->D2_GRUPO,1,1) == 'C' //Cordas PE
	
		If ART->D2_EST <> 'EX' .AND. ART->D2_TES <> '604' //Vendas Internas
			If ART->C5_TIPO = 'N' // Pedido Normal                 
				CPEINTFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET
			Else
				CPEINTFAT += nFatAux + ART->D2_VALIPI 
			EndIf
			CPEINTQTD += nQtAux
		Endif
	
		If ART->D2_TES = '604' //Z3
			CPETRFFAT += nFatAux
			CPETRFQTD += nQtAux
		Endif
	
		If ART->D2_EST = 'EX' //Exportações
			CPEEXPFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET + ART->D2_SEGURO + ART->D2_VALFRE
			CPEEXPQTD += nQtAux
		Endif
		
		cOK := 'S'

	Endif
	
	If Substr(ART->D2_GRUPO,1,1) == 'D' //Cordas PP
	
		If ART->D2_EST <> 'EX' .AND. ART->D2_TES <> '604' //Vendas Internas
			If ART->C5_TIPO = 'N' // Pedido Normal
				CPPINTFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET
			Else                                                   
				CPPINTFAT += nFatAux + ART->D2_VALIPI
			EndIf
			CPPINTQTD += nQtAux
		Endif
	
		If ART->D2_TES = '604' //Z3
			CPPTRFFAT += nFatAux
			CPPTRFQTD += nQtAux
		Endif
	
		If ART->D2_EST = 'EX' //Exportações
			CPPEXPFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET + ART->D2_SEGURO + ART->D2_VALFRE
			CPPEXPQTD += nQtAux
		Endif
		
		cOK := 'S'

	Endif
	
	If ART->D2_GRUPO >= 'G1' .AND. ART->D2_GRUPO <= 'G1ZZ' //Grãos PP/PE
	
		If ART->D2_EST <> 'EX' .AND. ART->D2_TES <> '604' //Vendas Internas
			If ART->C5_TIPO = 'N' // Pedido Normal                 
				GREINTFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET
			Else                                                   
				GREINTFAT += nFatAux + ART->D2_VALIPI
			EndIf
			GREINTQTD += nQtAux
		Endif
	
		If ART->D2_TES = '604' //Z3
			GRETRFFAT += nFatAux
			GRETRFQTD += nQtAux
		Endif
	
		If ART->D2_EST = 'EX' //Exportações
			GREEXPFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET + ART->D2_SEGURO + ART->D2_VALFRE
			GREEXPQTD += nQtAux
		Endif
		
		cOK := 'S'

	Endif     
	
	If ART->D2_GRUPO >= 'G2' .AND. ART->D2_GRUPO <= 'G2ZZ' //Grãos PP/RAFIA
	
		If ART->D2_EST <> 'EX' .AND. ART->D2_TES <> '604' //Vendas Internas
			If ART->C5_TIPO = 'N' // Pedido Normal
				GRFINTFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET
			Else                                                       
				GRFINTFAT += nFatAux + ART->D2_VALIPI
			EndIf
	
			GRFINTQTD += nQtAux
		Endif
	
		If ART->D2_TES = '604' //Z3
			GRFTRFFAT += nFatAux
			GRFTRFQTD += nQtAux
		Endif
	
		If ART->D2_EST = 'EX' //Exportações
			GRFEXPFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET + ART->D2_SEGURO + ART->D2_VALFRE
			GRFEXPQTD += nQtAux
		Endif
		
		cOK := 'S'

	Endif     
	
	If ART->D2_GRUPO >= 'J' .AND. ART->D2_GRUPO <= 'JZZZ' //Telhas
	
		If ART->D2_EST <> 'EX' .AND. ART->D2_TES <> '604' //Vendas Internas
			If ART->C5_TIPO = 'N' // Pedido Normal
				TELINTFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET
			Else                                                       
				TELINTFAT += nFatAux + ART->D2_VALIPI 
			EndIf
			TELINTQTD += nQtAux
		Endif
	
		If ART->D2_TES = '604' //Z3
			TELTRFFAT += nFatAux
			TELTRFQTD += nQtAux
		Endif
	
		If ART->D2_EST = 'EX' //Exportações
			TELEXPFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET + ART->D2_SEGURO + ART->D2_VALFRE
			TELEXPQTD += nQtAux
		Endif
		
		cOK := 'S'

	Endif     
	
	If ART->D2_GRUPO >= 'K' .AND. ART->D2_GRUPO <= 'KZZZ' // INJETADOS
	
		If ART->D2_EST <> 'EX' .AND. ART->D2_TES <> '604' //Vendas Internas
			If ART->C5_TIPO = 'N' // Pedido Normal
				INJINTFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET
			Else
				INJINTFAT += nFatAux + ART->D2_VALIPI
			EndIf
			INJINTQTD += nQtAux
		Endif
	
		If ART->D2_TES = '604' //Z3
			INJTRFFAT += nFatAux
			INJTRFQTD += nQtAux
		Endif
	
		If ART->D2_EST = 'EX' //Exportações
			INJEXPFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET + ART->D2_SEGURO + ART->D2_VALFRE
			INJEXPQTD += nQtAux
		Endif
		
		cOK := 'S'

	Endif     
	
	
	If Alltrim(ART->D2_COD) == '115900455' .or. Alltrim(ART->D2_COD) == '580100902'       //Catracas
	
		If ART->D2_EST <> 'EX' .AND. ART->D2_TES <> '604' //Vendas Internas
			If ART->C5_TIPO = 'N' // Pedido Normal
				CATINTFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET
			Else
				CATINTFAT += nFatAux + ART->D2_VALIPI 
			EndIf
			CATINTQTD += nQtAux
		Endif
	
		If ART->D2_TES = '604' //Z3
			CATTRFFAT += nFatAux
			CATTRFQTD += nQtAux
		Endif
	
		If ART->D2_EST = 'EX' //Exportações
			CATEXPFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET + ART->D2_SEGURO + ART->D2_VALFRE
			CATEXPQTD += nQtAux
		Endif
		
		cOK := 'S'

	Endif     
	
	If Alltrim(ART->D2_GRUPO) == '06' //Expositores
	
		If ART->C5_TIPO = 'N' // Pedido Normal
		EXPINTFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET
		Else                                                   
		EXPINTFAT += nFatAux + ART->D2_VALIPI
		EndIf
		EXPINTQTD += nQtAux
		
		cOK := 'S'

	Endif     
	
	If Alltrim(ART->D2_COD) == '207600040' //Resíduos
		If ART->C5_TIPO = 'N' // Pedido Normal
			RESINTFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET
		Else
			RESINTFAT += nFatAux + ART->D2_VALIPI
		EndIf
		RESINTQTD += nQtAux
	Endif     

	If cOK == 'N' .AND. Alltrim(ART->D2_COD) <> '207600040' //Caso não se enquadre em nenhuma condição acima e não seja resíduo,
															//é tratado como outras vendas.
		OUTINTFAT += nFatAux + ART->D2_VALIPI + ART->D2_ICMSRET + ART->D2_SEGURO + ART->D2_VALFRE
		OUTINTQTD += nQtAux
	Endif

	
	
	dbSelectArea("ART")
	dbSkip()
	
	If cGrupo <> ART->D2_GRUPO
		
		dbSelectArea("TRA")
		RecLock("TRA",.T.)
		TRA->GRUPO    := cGrupo
		TRA->DESC     := Posicione("SBM",1,XFILIAL("SBM")+cGrupo,"BM_DESC")
		TRA->TOTAL    := nFatGru
		TRA->QUANT    := nQtGru
		msUnLock("TRA")
		
		cGrupo  := ART->D2_GRUPO
		nFatGru := 0
		nQtGru  := 0
		
	Endif
	
	dbSelectArea("ART")
	
	cOK := 'N'
	
Enddo

//BUSCA INFORMAÇÕES DE METAS Z3 (RESIDUOS)
cQry := "SELECT ZF_TOTAL,ZF_QUANT,ZF_QTSEGUM,ZF_SEGUM,ZF_UM,B1_PESO,B1_GRUPO,ZF_COD "
cQry += "FROM " + RETSQLNAME("SZF") + " SZF, "
cQry += " " + RETSQLNAME("SB1") + " SB1 "
cQry += "WHERE SZF.D_E_L_E_T_ <> '*' AND "
cQry += "SB1.D_E_L_E_T_ <> '*' AND "
cQry += "ZF_FILIAL = '" + xFilial("SZF") + "' AND "
cQry += "B1_FILIAL = '" + xFilial("SB1") + "' AND "
cQry += "ZF_COD BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' AND "
cQry += "ZF_DTMETA BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' AND "
cQry += "ZF_CLIENTE BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' AND "
cQry += "ZF_COD = B1_COD "

If (Select("QZ3") <> 0)
	dbSelectArea("QZ3")
	dbCloseArea()
Endif

TCQUERY cQry NEW Alias "QZ3"

dbSelectArea("QZ3")
dbGoTop()

While !EOF()

	If Alltrim(QZ3->ZF_COD) == '207600040' //Resíduos
	
		RESINTFAT += QZ3->ZF_TOTAL
		RESINTQTD += QZ3->ZF_QUANT
		
	Endif     
	
/*
	nValAuxZ3 := QZ3->ZF_TOTAL
	
	If QZ3->ZF_UM == 'KG'
		nQtdAuxZ3 := QZ3->ZF_QUANT
	Else
		If QZ3->ZF_SEGUM == 'KG'
			nQtdAuxZ3 := QZ3->ZF_QTSEGUM
		Else
			If QZ3->ZF_UM <> 'KG' .and. QZ3->ZF_SEGUM <> 'KG'
				nQtdAuxZ3 := QZ3->ZF_QUANT * QZ3->B1_PESO
			Endif
		Endif
	Endif
	
	If QZ3->B1_GRUPO >= 'A' .AND. QZ3->B1_GRUPO < 'G'
		nValZ3Cor  += nValAuxZ3
		nQtdZ3Cor  += nQtdAuxZ3
	Else
		If QZ3->B1_GRUPO >= 'H' .AND. QZ3->B1_GRUPO < 'I'
			nValZ3Fib  += nValAuxZ3
			nQtdZ3Fib  += nQtdAuxZ3
		Else
			If QZ3->B1_GRUPO >= 'I' .AND. QZ3->B1_GRUPO < 'J'
				nValZ3Fio  += nValAuxZ3
				nQtdZ3Fio  += nQtdAuxZ3
			Else
				nValZ3  += nValAuxZ3
				nQtdZ3  += nQtdAuxZ3
			Endif
		Endif
	Endif
	
	*/
	
	dbSkip()
	
Enddo


//BUSCA DEVOLUÇÕES
cQuery := "SELECT DISTINCT B1_GRUPO,C5_TIPC,D1_TOTAL,D1_QUANT,D1_QTSEGUM,D1_VALIPI,D1_UM,D1_SEGUM,B1_PESO,D1_DOC,D1_NFORI,D1_COD,D1_ICMSRET "
cQuery += "FROM " + RETSQLNAME("SD1") + " SD1, " + RETSQLNAME("SB1") + " SB1, " + RETSQLNAME("SD2") + " SD2, "
cQuery += " " + RETSQLNAME("SC5") + " SC5 "
cQuery += "WHERE SD1.D_E_L_E_T_ <> '*' AND SD2.D_E_L_E_T_ <> '*' AND SB1.D_E_L_E_T_ <> '*' AND SC5.D_E_L_E_T_ <> '*' "
cQuery += "AND D1_FILIAL = '" + xFilial("SD1") + "' "
cQuery += "AND D2_FILIAL = '" + xFilial("SD2") + "' "
cQuery += "AND B1_FILIAL = '" + xFilial("SB1") + "' "
cQuery += "AND C5_FILIAL = '" + xFilial("SC5") + "' "
cQuery += "AND D1_NFORI = D2_DOC "
cQuery += "AND C5_NUM = D2_PEDIDO "
cQuery += "AND D1_SERIORI = D2_SERIE AND SUBSTRING(D1_CF,2,1) <> '9' "
cQuery += "AND D1_COD = B1_COD "
cQuery += "AND D1_FORNECE BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
cQuery += "AND D1_DTDIGIT BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
cQuery += "AND D1_COD BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' AND D1_TIPO = 'D' "
cQuery += "ORDER BY B1_GRUPO "

If (Select("DEV") <> 0)
	dbSelectArea("DEV")
	dbCloseArea()
Endif

TCQUERY cQuery NEW Alias "DEV"

dbSelectArea("DEV")  
dbGoTop()

nAuxDevVlr  := 0
nAuxDevQtde := 0
nValCorDev  := 0
nQtdCorDev  := 0
nValGraDev  := 0
nQtdGraDev  := 0
nValFioDev  := 0
nQtdFioDev  := 0
nValFibDev  := 0
nQtdFibDev  := 0
nValTelDev	:= 0 
nQtdTelDev  := 0
nValCatDev  := 0
nQtdCatDev  := 0
nValInjDev  := 0
nQtdInjDev  := 0
nValExpDev  := 0
nQtdExpDev  := 0
nValOutDev  := 0
nQtdOutDev  := 0

While !EOF()
	
	If DEV->C5_TIPC == 'S'
		nAuxDevVlr := DEV->D1_TOTAL * 2                                      
	Else                                                                     
		If DEV->C5_TIPC == 'E'
			nAuxDevVlr := DEV->D1_TOTAL + (DEV->D1_TOTAL * 80 / 20)
		Else
			nAuxDevVlr := DEV->D1_TOTAL
		Endif
	Endif
	
	nAuxDevVlr += DEV->D1_VALIPI + DEV->D1_ICMSRET
	
	Do Case
		Case DEV->D1_UM = "KG"
			nAuxDevQtde := DEV->D1_QUANT
		Case DEV->D1_SEGUM = "KG"
			nAuxDevQtde := DEV->D1_QTSEGUM
		Case DEV->D1_UM <> "KG" .AND. DEV->D1_SEGUM <> "KG"
			nAuxDevQtde := (DEV->D1_QUANT * DEV->B1_PESO)
	EndCase
	
	If DEV->B1_GRUPO >= 'A' .AND. DEV->B1_GRUPO <= 'FZZZ' //  CORDAS - A,B,C,D 
		nValCorDev += nAuxDevVlr
		nQtdCorDev += nAuxDevQtde
	Else
		If Substr(DEV->B1_GRUPO,1,1) == 'G' // GRAOS
			nValGraDev += nAuxDevVlr
			nQtdGraDev += nAuxDevQtd
		Else
			If Substr(DEV->B1_GRUPO,1,1) == 'H' // FIBRAS
				nValFibDev += nAuxDevVlr
				nQtdFibDev += nAuxDevQtd
			Else
				If ALLTRIM(DEV->B1_GRUPO) == 'PV' //CATRACAS
					nValCatDev += nAuxDevVlr
					nQtdCatDev += nAuxDevQtd
				Else
					If Substr(DEV->B1_GRUPO,1,1) == 'I' // FIOS
						nValFioDev += nAuxDevVlr
						nQtdFioDev += nAuxDevQtd
					Else
		   				If Substr(DEV->B1_GRUPO,1,1) == 'J' // TELHAS
							nValTelDev += nAuxDevVlr
							nQtdTelDev += nAuxDevQtd
						Else
							If Substr(DEV->B1_GRUPO,1,1) == 'K' //INJETADOS
								nValInjDev += nAuxDevVlr
								nQtdInjDev += nAuxDevQtd
							Else
								If Alltrim(DEV->B1_GRUPO) == '06' //EXPOSITORES
									nValExpDev += nAuxDevVlr
									nQtdExpDev += nAuxDevQtd
								Else
  			  					nValOutDev += nAuxDevVlr
								nQtdOutDev += nAuxDevQtd          
								EndIf
							EndIf
						Endif
					Endif
				Endif
			Endif
		Endif
	EndIF
		
	dbSelectArea("DEV")
	dbSkip()
	
Enddo

//ROTINA DE IMPRESSÃO

dbSelectArea("TRA")
dbGoTop()

SetRegua(RecCount("TRA"))

While !EOF()
	
	If lAbortPrint
		@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
		Exit
	Endif
	
	/*
	123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
	         1         2         3         4         5         6         7         8         9         10        11
	                   PET CORDAS
	                             INTERNAS                     999,999,999.99   9,999,999.99   9,999,999.99
	                             EXPORTAÇÕES                  999,999,999.99   9,999,999.99   9,999,999.99
	                             Z3                           999,999,999.99   9,999,999.99   9,999,999.99
	                             
	*/
	
	
	If nLin > 55
		
		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
		nLin := 6
		@nLin,01 pSay "GRUPO                                                     FATURAMENTO      QTDE(KG)       PREÇO MEDIO"
		nLin++
		nLin++
		
	Endif
	
	@nLin,001 pSay TRA->GRUPO
	@nLin,006 pSay TRA->DESC
	@nLin,059 pSay TRA->TOTAL		       PICTURE "@E 999,999,999.99""
	@nLin,076 pSay TRA->QUANT		       PICTURE "@E 9,999,999.99"
	@nLin,091 pSay TRA->TOTAL/TRA->QUANT   PICTURE "@E 9,999,999.99"
	
	nLin++
	
	dbSelectArea("TRA")
	dbSkip()
	
	IncRegua()
	
Enddo

Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
nLin := 6
@nLin,01 pSay "RESUMO DE VENDAS                                          FATURAMENTO      QTDE(KG)       PREÇO MEDIO"
nLin++
nLin++

@nLin,030 pSay "VENDAS INTERNAS"
@nLin,059 pSay CORINTFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay CORINTQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay CORINTFAT/CORINTQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "EXPORTAÇÕES"
@nLin,059 pSay COREXPFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay COREXPQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay COREXPFAT/COREXPQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "Z3"
@nLin,059 pSay CORTRFFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay CORTRFQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay CORTRFFAT/CORTRFQTD  PICTURE "@E 9,999,999.99"
nLin++     
@nLin,059 pSay "--------------""
@nLin,076 pSay "------------"
@nLin,091 pSay "------------"
nLin++     
@nLin,030 pSay "CORDAS PET"
@nLin,059 pSay CORINTFAT+COREXPFAT+CORTRFFAT                                    PICTURE "@E 999,999,999.99"
@nLin,076 pSay CORINTQTD+COREXPQTD+CORTRFQTD                                    PICTURE "@E 9,999,999.99"
@nLin,091 pSay (CORINTFAT+COREXPFAT+CORTRFFAT)/(CORINTQTD+COREXPQTD+CORTRFQTD)  PICTURE "@E 9,999,999.99"
nLin++     
nLin++     

nValGer += CORINTFAT + COREXPFAT + CORTRFFAT
nQtdGer += CORINTQTD + COREXPQTD + CORTRFQTD

@nLin,030 pSay "VENDAS INTERNAS"
@nLin,059 pSay FIBINTFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay FIBINTQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay FIBINTFAT/FIBINTQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "EXPORTAÇÕES"
@nLin,059 pSay FIBEXPFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay FIBEXPQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay FIBEXPFAT/FIBEXPQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "Z3"
@nLin,059 pSay FIBTRFFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay FIBTRFQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay FIBTRFFAT/FIBTRFQTD  PICTURE "@E 9,999,999.99"
nLin++     
@nLin,059 pSay "--------------"
@nLin,076 pSay "------------"
@nLin,091 pSay "------------"
nLin++     
@nLin,030 pSay "FIBRAS PET"
@nLin,059 pSay FIBINTFAT+FIBEXPFAT+FIBTRFFAT                                    PICTURE "@E 999,999,999.99"
@nLin,076 pSay FIBINTQTD+FIBEXPQTD+FIBTRFQTD                                    PICTURE "@E 9,999,999.99"
@nLin,091 pSay (FIBINTFAT+FIBEXPFAT+FIBTRFFAT)/(FIBINTQTD+FIBEXPQTD+FIBTRFQTD)  PICTURE "@E 9,999,999.99"
nLin++     
nLin++     

nValGer += FIBINTFAT + FIBEXPFAT + FIBTRFFAT
nQtdGer += FIBINTQTD + FIBEXPQTD + FIBTRFQTD

@nLin,030 pSay "VENDAS INTERNAS"
@nLin,059 pSay FIOINTFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay FIOINTQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay FIOINTFAT/FIOINTQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "EXPORTAÇÕES"
@nLin,059 pSay FIOEXPFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay FIOEXPQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay FIOEXPFAT/FIOEXPQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "Z3"
@nLin,059 pSay FIOTRFFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay FIOTRFQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay FIOTRFFAT/FIOTRFQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,059 pSay "--------------"
@nLin,076 pSay "------------"
@nLin,091 pSay "------------"
nLin++     
@nLin,030 pSay "FIOS PET"
@nLin,059 pSay FIOINTFAT+FIOEXPFAT+FIOTRFFAT                                    PICTURE "@E 999,999,999.99"
@nLin,076 pSay FIOINTQTD+FIOEXPQTD+FIOTRFQTD                                    PICTURE "@E 9,999,999.99"
@nLin,091 pSay (FIOINTFAT+FIOEXPFAT+FIOTRFFAT)/(FIOINTQTD+FIOEXPQTD+FIOTRFQTD)  PICTURE "@E 9,999,999.99"
nLin++     
nLin++     

nValGer += FIOINTFAT + FIOEXPFAT + FIOTRFFAT
nQtdGer += FIOINTQTD + FIOEXPQTD + FIOTRFQTD

@nLin,030 pSay "VENDAS INTERNAS"
@nLin,059 pSay CPEINTFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay CPEINTQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay CPEINTFAT/CPEINTQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "EXPORTAÇÕES"
@nLin,059 pSay CPEEXPFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay CPEEXPQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay CPEEXPFAT/CPEEXPQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "Z3"
@nLin,059 pSay CPETRFFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay CPETRFQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay CPETRFFAT/CPETRFQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,059 pSay "--------------"
@nLin,076 pSay "------------"
@nLin,091 pSay "------------"
nLin++     
@nLin,030 pSay "CORDAS PE"
@nLin,059 pSay CPEINTFAT+CPEEXPFAT+CPETRFFAT                                    PICTURE "@E 999,999,999.99"
@nLin,076 pSay CPEINTQTD+CPEEXPQTD+CPETRFQTD                                    PICTURE "@E 9,999,999.99"
@nLin,091 pSay (CPEINTFAT+CPEEXPFAT+CPETRFFAT)/(CPEINTQTD+CPEEXPQTD+CPETRFQTD)  PICTURE "@E 9,999,999.99"
nLin++     
nLin++     

nValGer += CPEINTFAT + CPEEXPFAT + CPETRFFAT
nQtdGer += CPEINTQTD + CPEEXPQTD + CPETRFQTD

@nLin,030 pSay "VENDAS INTERNAS"
@nLin,059 pSay CPPINTFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay CPPINTQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay CPPINTFAT/CPEINTQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "EXPORTAÇÕES"
@nLin,059 pSay CPPEXPFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay CPPEXPQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay CPPEXPFAT/CPEEXPQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "Z3"
@nLin,059 pSay CPPTRFFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay CPPTRFQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay CPPTRFFAT/CPETRFQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,059 pSay "--------------"
@nLin,076 pSay "------------"
@nLin,091 pSay "------------"
nLin++     
@nLin,030 pSay "CORDAS PP"
@nLin,059 pSay CPPINTFAT+CPPEXPFAT+CPPTRFFAT                                    PICTURE "@E 999,999,999.99""
@nLin,076 pSay CPPINTQTD+CPPEXPQTD+CPPTRFQTD                                    PICTURE "@E 9,999,999.99"
@nLin,091 pSay (CPPINTFAT+CPPEXPFAT+CPPTRFFAT)/(CPPINTQTD+CPPEXPQTD+CPPTRFQTD)  PICTURE "@E 9,999,999.99"
nLin++     
nLin++     

nValGer += CPPINTFAT + CPPEXPFAT + CPPTRFFAT
nQtdGer += CPPINTQTD + CPPEXPQTD + CPPTRFQTD

@nLin,030 pSay "VENDAS INTERNAS"
@nLin,059 pSay GREINTFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay GREINTQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay GREINTFAT/GREINTQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "EXPORTAÇÕES"
@nLin,059 pSay GREEXPFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay GREEXPQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay GREEXPFAT/GREEXPQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "Z3"
@nLin,059 pSay GRETRFFAT            PICTURE "@E 999,999,999.99"
@nLin,076 pSay GRETRFQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay GRETRFFAT/GRETRFQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,059 pSay "--------------"
@nLin,076 pSay "------------"
@nLin,091 pSay "------------"
nLin++     
@nLin,030 pSay "GRÃOS PP/PE"
@nLin,059 pSay GREINTFAT+GREEXPFAT+GRETRFFAT                                    PICTURE "@E 999,999,999.99"
@nLin,076 pSay GREINTQTD+GREEXPQTD+GRETRFQTD                                    PICTURE "@E 9,999,999.99"
@nLin,091 pSay (GREINTFAT+GREEXPFAT+GRETRFFAT)/(GREINTQTD+GREEXPQTD+GRETRFQTD)  PICTURE "@E 9,999,999.99"
nLin++     
nLin++     

nValGer += GREINTFAT + GREEXPFAT + GRETRFFAT
nQtdGer += GREINTQTD + GREEXPQTD + GRETRFQTD                                       
                                                                                   
@nLin,030 pSay "VENDAS INTERNAS"                                          
@nLin,059 pSay GRFINTFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay GRFINTQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay GRFINTFAT/GRFINTQTD  PICTURE "@E 9,999,999.99"             
nLin++
@nLin,030 pSay "EXPORTAÇÕES"
@nLin,059 pSay GRFEXPFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay GRFEXPQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay GRFEXPFAT/GRFEXPQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "Z3"
@nLin,059 pSay GRFTRFFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay GRFTRFQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay GRFTRFFAT/GRFTRFQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,059 pSay "--------------""
@nLin,076 pSay "------------"
@nLin,091 pSay "------------"
nLin++     
@nLin,030 pSay "GRÃOS PP/RF"
@nLin,059 pSay GRFINTFAT+GRFEXPFAT+GRFTRFFAT                                    PICTURE "@E 999,999,999.99""
@nLin,076 pSay GRFINTQTD+GRFEXPQTD+GRFTRFQTD                                    PICTURE "@E 9,999,999.99"
@nLin,091 pSay (GRFINTFAT+GRFEXPFAT+GRFTRFFAT)/(GRFINTQTD+GRFEXPQTD+GRFTRFQTD)  PICTURE "@E 9,999,999.99"
nLin++     
nLin++     
nValGer += GRFINTFAT + GRFEXPFAT + GRFTRFFAT
nQtdGer += GRFINTQTD + GRFEXPQTD + GRFTRFQTD

// TELHAS
      
@nLin,030 pSay "VENDAS INTERNAS"
@nLin,059 pSay TELINTFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay TELINTQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay TELINTFAT/TELINTQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "EXPORTAÇÕES"
@nLin,059 pSay TELEXPFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay TELEXPQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay TELEXPFAT/TELEXPQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "Z3"
@nLin,059 pSay TELTRFFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay TELTRFQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay TELTRFFAT/TELTRFQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,059 pSay "--------------""
@nLin,076 pSay "------------"
@nLin,091 pSay "------------"
nLin++     

@nLin,030 pSay "TELHAS"
@nLin,059 pSay TELINTFAT+TELEXPFAT+TELTRFFAT                                    PICTURE "@E 999,999,999.99""
@nLin,076 pSay TELINTQTD+TELEXPQTD+TELTRFQTD                                    PICTURE "@E 9,999,999.99"
@nLin,091 pSay (TELINTFAT+TELEXPFAT+TELTRFFAT)/(TELINTQTD+TELEXPQTD+TELTRFQTD)  PICTURE "@E 9,999,999.99"
nLin++     
nLin++     

nValGer += TELINTFAT + TELEXPFAT + TELTRFFAT
nQtdGer += TELINTQTD + TELEXPQTD + TELTRFQTD

// CATRACAS

@nLin,030 pSay "VENDAS INTERNAS"
@nLin,059 pSay CATINTFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay CATINTQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay CATINTFAT/CATINTQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "EXPORTAÇÕES"
@nLin,059 pSay CATEXPFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay CATEXPQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay CATEXPFAT/CATEXPQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "Z3"
@nLin,059 pSay CATTRFFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay CATTRFQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay CATTRFFAT/CATTRFQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,059 pSay "--------------""
@nLin,076 pSay "------------"
@nLin,091 pSay "------------"
nLin++     

@nLin,030 pSay "CATRACAS"
@nLin,059 pSay CATINTFAT+CATEXPFAT+CATTRFFAT                                    PICTURE "@E 999,999,999.99""
@nLin,076 pSay CATINTQTD+CATEXPQTD+CATTRFQTD                                    PICTURE "@E 9,999,999.99"
@nLin,091 pSay (CATINTFAT+CATEXPFAT+CATTRFFAT)/(CATINTQTD+CATEXPQTD+CATTRFQTD)  PICTURE "@E 9,999,999.99"
nLin++     
nLin++     
nValGer += CATINTFAT + CATEXPFAT + CATTRFFAT
nQtdGer += CATINTQTD + CATEXPQTD + CATTRFQTD

// INJETADOS

@nLin,030 pSay "VENDAS INTERNAS"
@nLin,059 pSay INJINTFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay INJINTQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay INJINTFAT/INJINTQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "Z3"
@nLin,059 pSay INJTRFFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay INJTRFQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay INJTRFFAT/INJTRFQTD  PICTURE "@E 9,999,999.99"
nLin++
@nLin,059 pSay "--------------""
@nLin,076 pSay "------------"
@nLin,091 pSay "------------"
nLin++     

@nLin,030 pSay "INJETADOS"
@nLin,059 pSay INJINTFAT+INJEXPFAT+INJTRFFAT                                    PICTURE "@E 999,999,999.99""
@nLin,076 pSay INJINTQTD+INJEXPQTD+INJTRFQTD                                    PICTURE "@E 9,999,999.99"
@nLin,091 pSay (INJINTFAT+INJEXPFAT+INJTRFFAT)/(INJINTQTD+INJEXPQTD+INJTRFQTD)  PICTURE "@E 9,999,999.99"
nLin++     
nLin++     

nValGer += INJINTFAT + INJEXPFAT + INJTRFFAT
nQtdGer += INJINTQTD + INJEXPQTD + INJTRFQTD

// RESIDUOS

@nLin,030 pSay "RESÍDUOS"
@nLin,059 pSay RESINTFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay RESINTQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay RESINTFAT/RESINTQTD  PICTURE "@E 9,999,999.99"
nLin++        
nLin++        

nValGer += RESINTFAT
nQtdGer += RESINTQTD

@nLin,030 pSay "EXPOSITORES"
@nLin,059 pSay EXPINTFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay EXPINTQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay EXPINTFAT/EXPINTQTD  PICTURE "@E 9,999,999.99"
nLin++        

nValGer += EXPINTFAT
nQtdGer += EXPINTQTD

nLin++

@nLin,030 pSay "OUTRAS VENDAS"
@nLin,059 pSay OUTINTFAT            PICTURE "@E 999,999,999.99""
@nLin,076 pSay OUTINTQTD            PICTURE "@E 9,999,999.99"
@nLin,091 pSay OUTINTFAT/OUTINTQTD  PICTURE "@E 9,999,999.99"
nLin++        

nValGer += OUTINTFAT
nQtdGer += OUTINTQTD

nLin++

@nLin,030 pSay "TOTAL"
@nLin,059 pSay nValGer   	    PICTURE "@E 999,999,999.99""
@nLin,076 pSay nQtdGer   	    PICTURE "@E 9,999,999.99"
@nLin,091 pSay nValGer/nQtdGer  PICTURE "@E 9,999,999.99"         

Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
nLin := 6

@nLin,001 pSay "(-) DEVOLUÇÕES                                            FATURAMENTO      QTDE(KG)"
nLin++          
nLin++          

@nLin,030 pSay "CORDAS"
@nLin,059 pSay nValCorDev 	    PICTURE "@E 999,999,999.99""
@nLin,076 pSay nQtdCorDev  	    PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "GRÃOS "
@nLin,059 pSay nValGraDev 	    PICTURE "@E 999,999,999.99""
@nLin,076 pSay nQtdGraDev  	    PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "FIOS  "
@nLin,059 pSay nValFioDev 	    PICTURE "@E 999,999,999.99""
@nLin,076 pSay nQtdFioDev  	    PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "FIBRAS"
@nLin,059 pSay nValFibDev 	    PICTURE "@E 999,999,999.99""
@nLin,076 pSay nQtdFibDev  	    PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "TELHAS"
@nLin,059 pSay nValTelDev 	    PICTURE "@E 999,999,999.99""
@nLin,076 pSay nQtdTelDev  	    PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "CATRACAS"
@nLin,059 pSay nValCatDev 	    PICTURE "@E 999,999,999.99""
@nLin,076 pSay nQtdCatDev  	    PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "INJETADOS"
@nLin,059 pSay nValInjDev 	    PICTURE "@E 999,999,999.99""
@nLin,076 pSay nQtdInjDev  	    PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "EXPOSITORES"
@nLin,059 pSay nValExpDev 	    PICTURE "@E 999,999,999.99""
@nLin,076 pSay nQtdExpDev  	    PICTURE "@E 9,999,999.99"
nLin++
@nLin,030 pSay "OUTROS"
@nLin,059 pSay nValOutDev 	    PICTURE "@E 999,999,999.99""
@nLin,076 pSay nQtdOutDev  	    PICTURE "@E 9,999,999.99"
nLin++
nLin++
@nLin,030 pSay "TOTAL   "
@nLin,059 pSay nValCatDev+nValFioDev+nValGraDev+nValCorDev+nValFibDev+nValTelDev+nValInjDev+nValExpDev+nValOutDev 	    PICTURE "@E 999,999,999.99""
@nLin,076 pSay nQtdCatDev+nQtdFioDev+nQtdGraDev+nQtdCorDev+nQtdFibDev+nQtdTelDev+nQtdInjDev+nQtdExpDev+nQtdOutDev	    PICTURE "@E 9,999,999.99"
nLin++
nLin++
@nLin,030 pSay "TOTAL GERAL"
@nLin,059 pSay nValGer-(nValCatDev+nValFioDev+nValGraDev+nValCorDev+nValFibDev+nValTelDev+nValInjDev+nValExpDev+nValOutDev)    PICTURE "@E 999,999,999.99""
@nLin,076 pSay nQtdGer-(nQtdCatDev+nQtdFioDev+nQtdGraDev+nQtdCorDev+nQtdFibDev+nQtdTelDev+nQtdInjDev+nQtdExpDev+nQtdOutDev)    PICTURE "@E 9,999,999.99"


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