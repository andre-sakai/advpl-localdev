#INCLUDE "rwmake.ch"
#include "topconn.ch"

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±± Programa  ±ART327    ± Autor ± CLOVIS EMMENDORFER º Data ³  27/11/07   º±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±± Descricao ± RELATORIO GERENCIAL DE FATURAMENTO - CURVA ABC             º±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±± Uso       ± Especifico para Arteplas                                   º±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
/*/

User Function ART327()

LOCAL cDesc1       := "Este programa tem como objetivo imprimir relatorio "
LOCAL cDesc2       := "de acordo com os parametros informados pelo usuario."
LOCAL cDesc3       := "Relatorio gerencial de faturamento - Curva ABC."
LOCAL cPict        := ""
LOCAL titulo       := "Visão Gerencial do Faturamento - Curva ABC"
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
Private nomeprog   := "ART327"
Private nTipo      := 18
Private aReturn    := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey   := 0
Private cPerg      := "ART327"
Private cbtxt      := Space(10)
Private cbcont     := 00
Private CONTFL     := 01
Private m_pag      := 01
Private wnrel      := "ART327"

cPerg := "ART327"
aRegistros := {}
AADD(aRegistros,{cPerg,"01","Produto de  ?","","","mv_ch1","C",15,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SB1","","","","",""})
AADD(aRegistros,{cPerg,"02","Produto ate ?","","","mv_ch2","C",15,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SB1","","","","",""})
AADD(aRegistros,{cPerg,"03","Data de     ?","","","mv_ch3","D",08,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"04","Data ate    ?","","","mv_ch4","D",08,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"05","Estado de   ?","","","mv_ch5","C",02,0,0,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","12","","","","",""})
AADD(aRegistros,{cPerg,"06","Estado ate  ?","","","mv_ch6","C",02,0,0,"G","","mv_par06","","","","","","","","","","","","","","","","","","","","","","","","","12","","","","",""})
AADD(aRegistros,{cPerg,"07","Cliente de  ?","","","mv_ch7","C",06,0,0,"G","","mv_par07","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","","",""})
AADD(aRegistros,{cPerg,"08","Cliente ate ?","","","mv_ch8","C",06,0,0,"G","","mv_par08","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","","",""})
AADD(aRegistros,{cPerg,"09","Vendedor de ?","","","mv_ch9","C",06,0,0,"G","","mv_par09","","","","","","","","","","","","","","","","","","","","","","","","","SA3","","","","",""})
AADD(aRegistros,{cPerg,"10","Vendedor ate?","","","mv_chA","C",06,0,0,"G","","mv_par10","","","","","","","","","","","","","","","","","","","","","","","","","SA3","","","","",""})
AADD(aRegistros,{cPerg,"11","Visão por   ?","","","mv_chB","C",01,0,0,"G","","mv_par11","","","","","","","","","","","","","","","","","","","","","","","","","ART327","","","","",""})
//AADD(aRegistros,{cPerg,"11","Visão por   ?","","","mv_chB","N",01,0,0,"C","","mv_par11","1-Cliente","","","","","2-Produto","","","","","3-Vendedor","","","","","4-Estado","","","","","","5-Município","","","","",""})
AADD(aRegistros,{cPerg,"12","% Classe A  ?","","","mv_chC","N",03,0,0,"G","","mv_par12","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"13","% Classe B  ?","","","mv_chD","N",03,0,0,"G","","mv_par13","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"14","% Classe C  ?","","","mv_chE","N",03,0,0,"G","","mv_par14","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"15","Grupo de    ?","","","mv_chF","C",04,0,0,"G","","mv_par15","","","","","","","","","","","","","","","","","","","","","","","","","SBM","","","","",""})
AADD(aRegistros,{cPerg,"16","Grupo ate   ?","","","mv_chG","C",04,0,0,"G","","mv_par16","","","","","","","","","","","","","","","","","","","","","","","","","SBM","","","","",""})
AADD(aRegistros,{cPerg,"17","Municipio   ?","","","mv_chH","C",30,0,0,"G","","mv_par17","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})


AADD(aRegistros,{cPerg,"18","CNPJ de  ?","","","mv_chI","C",14,0,0,"G","","mv_par18","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","","",""})
AADD(aRegistros,{cPerg,"19","CNPJ ate ?","","","mv_chJ","C",14,0,0,"G","","mv_par19","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","","",""})


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

If (Select("TRA") <> 0)
	dbSelectArea("TRA")
	dbCloseArea()
Endif

aStru:={}

Aadd(aStru,{ "CLIENTE   ", "C", 6 , 0 } )
Aadd(aStru,{ "ESTADO    ", "C", 2 , 0 } )
Aadd(aStru,{ "NOMECLI   ", "C", 60, 0 } )
Aadd(aStru,{ "TOTAL     ", "N", 14, 2 } )
Aadd(aStru,{ "QUANT     ", "N", 11, 2 } )
Aadd(aStru,{ "QUANTUM   ", "N", 11, 2 } )
Aadd(aStru,{ "PRODUTO   ", "C", 15, 0 } )
Aadd(aStru,{ "DESC      ", "C", 35, 0 } )
Aadd(aStru,{ "UM        ", "C", 2 , 0 } )
Aadd(aStru,{ "VENDEDOR  ", "C", 6 , 0 } )
Aadd(aStru,{ "NOMEVEND  ", "C", 40, 0 } )
Aadd(aStru,{ "CIDADE    ", "C", 30, 0 } )
Aadd(aStru,{ "PAIS      ", "C", 3 , 0 } )
Aadd(aStru,{ "UFREP     ", "C", 2 , 0 } )
Aadd(aStru,{ "GRUPO     ", "C", 4 , 0 } )
Aadd(aStru,{ "GRDESC    ", "C", 30, 0 } )


cTemp := CriaTrab(aStru,.t.)
Use &cTemp. Alias TRA New
Index on TOTAL to &cTemp.

cQry := "SELECT D2_TOTAL,D2_QUANT,C5_TIPC,C5_TIPO,D2_QTSEGUM,D2_VALIPI, "
cQry += "D2_CLIENTE,A1_NOME,A1_EST,D2_COD,B1_DESC,B1_UM,B1_GRUPO,D2_QTDEDEV,D2_VALDEV,D2_IPI,B1_CONV, "
cQry += "D2_VEND1,A3_NOME,A3_EST,A1_MUN,A1_PAIS,D2_SEGUM,D2_UM,D2_PESO,D2_ICMSRET "
cQry += "FROM " + RETSQLNAME("SB1") + " SB1, "
cQry += " " + RETSQLNAME("SD2") + " SD2, "
cQry += " " + RETSQLNAME("SA1") + " SA1, "
cQry += " " + RETSQLNAME("SF4") + " SF4, "
cQry += " " + RETSQLNAME("SA3") + " SA3, "
cQry += " " + RETSQLNAME("SC5") + " SC5 "
cQry += "WHERE SB1.D_E_L_E_T_ <> '*' AND "
cQry += "SD2.D_E_L_E_T_ <> '*' AND "
cQry += "SA1.D_E_L_E_T_ <> '*' AND "
cQry += "SF4.D_E_L_E_T_ <> '*' AND "
cQry += "SA3.D_E_L_E_T_ <> '*' AND "
cQry += "SC5.D_E_L_E_T_ <> '*' AND "
cQry += "B1_FILIAL = '" + xFilial("SB1") + "' AND "
cQry += "D2_FILIAL = '" + xFilial("SD2") + "' AND "
cQry += "A1_FILIAL = '" + xFilial("SA1") + "' AND "
cQry += "F4_FILIAL = '" + xFilial("SF4") + "' AND "
cQry += "A3_FILIAL = '" + xFilial("SA3") + "' AND "
cQry += "C5_FILIAL = '" + xFilial("SC5") + "' AND "
cQry += "B1_COD BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' AND "
cQry += "B1_GRUPO BETWEEN '" + mv_par15 + "' AND '" + mv_par16 + "' AND "
cQry += "D2_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' AND "
cQry += "A1_EST BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' AND "
If !Empty(mv_par17)
	cQry += "A1_MUN = '" + mv_par17 + "' AND "
Endif
cQry += "D2_CLIENTE BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "' AND "
cQry += "D2_VEND1 BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "' AND "  
cQry += "A1_CGC BETWEEN '" + mv_par18 + "' AND '" + mv_par19 + "' AND "
cQry += "B1_COD = D2_COD AND A1_COD = D2_CLIENTE AND A1_LOJA = D2_LOJA AND F4_CODIGO = D2_TES AND A3_COD = D2_VEND1 AND "
cQry += "(F4_DUPLIC = 'S' OR D2_TES = '547' ) AND (D2_TIPO = 'N' OR D2_TIPO = 'C') AND D2_TES <> '604' AND C5_NUM = D2_PEDIDO "

If mv_par11 == "1" //CLIENTE
	cQry += "ORDER BY D2_CLIENTE "
Else
	If mv_par11 == "2" //PRODUTO
		cQry += "ORDER BY D2_COD "
	Else
		If mv_par11 == "3" //VENDEDOR
			cQry += "ORDER BY D2_VEND1 "
		Else
			If mv_par11 == "4" //ESTADO
				cQry += "ORDER BY A1_EST "
			Else
				If mv_par11 == "5" //MUNICIPIO
					cQry += "ORDER BY A1_MUN,A1_EST,A1_PAIS " //MUNICIPIO
				Else                      
					If mv_par11 == "6" //GRUPO
						cQry += "ORDER BY B1_GRUPO "
					EndIf
				EndIf
			Endif
		Endif
	Endif
Endif

If (Select("ART") <> 0)
	dbSelectArea("ART")
	dbCloseArea()
Endif

TCQUERY cQry NEW Alias "ART"

dbSelectArea("ART")
dbGoTop()

nRank     := 1
nOcorrenc := 0
nTotQuant := 0     
nTotUM    := 0     
nTotFat   := 0
nTotFatG  := 0
nTotQtG   := 0
nPartic   := 0
nTotPart  := 0
nPartAcum := 0
cCliente  := ART->D2_CLIENTE
cNomeCli  := ART->A1_NOME
cEstado   := ART->A1_EST
cProduto  := ART->D2_COD
cDesc     := ART->B1_DESC  
cUM       := ART->B1_UM
cVendedor := ART->D2_VEND1
cNomeVend := ART->A3_NOME
cCidade   := ART->A1_MUN
cPais     := ART->A1_PAIS
cUFRep	  := ART->A3_EST         
cGrupo	  := SUBSTR(ART->B1_GRUPO,1,1)

While !EOF()
	
	If ART->C5_TIPC == 'S'
		nTotFat  += ART->D2_TOTAL * 2
		nTotFatG += ART->D2_TOTAL * 2
	Else
		If ART->C5_TIPC == 'E'
			nTotFat  += ART->D2_TOTAL + (ART->D2_TOTAL * 80 / 20)
			nTotFatG += ART->D2_TOTAL + (ART->D2_TOTAL * 80 / 20)
		Else
			nTotFat  += ART->D2_TOTAL
			nTotFatG += ART->D2_TOTAL
		Endif
	Endif
	
	//Acrescenta valor do IPI e ICMS Retido
    If ART->C5_TIPO <> 'N' // Pedido que não é Normal (Devoluções, Complemento de ICMS/IPI)
		nTotFat  += ART->D2_VALIPI
		nTotFatG += ART->D2_VALIPI
	Else
		nTotFat  += ART->D2_VALIPI + ART->D2_ICMSRET
		nTotFatG += ART->D2_VALIPI + ART->D2_ICMSRET
	EndIf
	
	// Quantidade em Peso

	If ART->D2_UM == 'KG'
		nTotQuant += ART->D2_QUANT
		nTotQtG   += ART->D2_QUANT
	Else
		If ART->D2_SEGUM == 'KG'
			nTotQuant += ART->D2_QTSEGUM
			nTotQtG   += ART->D2_QTSEGUM
		Else
			If ART->D2_UM <> 'KG' .and. ART->D2_SEGUM <> 'KG'
				nTotQuant += ART->D2_QUANT * ART->D2_PESO
				nTotQtG   += ART->D2_QUANT * ART->D2_PESO
			Endif
		Endif
	Endif                         
	
	//Quantidade em UM
	
	nTotUM += ART->D2_QUANT
	
	dbSelectArea("ART")
	dbSkip()
	
	If mv_par11 == "1"
		
		If cCliente <> ART->D2_CLIENTE
			
			dbSelectArea("TRA")
			RecLock("TRA",.T.)
			TRA->CLIENTE  := cCliente
			TRA->ESTADO   := cEstado
			TRA->NOMECLI  := cNomeCli
			TRA->TOTAL    := nTotFat
			TRA->QUANT    := nTotQuant
			TRA->QUANTUM  := nTotUM
			
			msUnLock("TRA")
			
			cCliente  := ART->D2_CLIENTE
			cNomeCli  := ART->A1_NOME
			cEstado   := ART->A1_EST
			nTotFat   := 0
			nTotQuant := 0         
			nTotUM    := 0
			
			nOcorrenc++
			
		Endif
		
	Endif
	
	If mv_par11 == "2"
		
		If cProduto <> ART->D2_COD
			
			dbSelectArea("TRA")
			RecLock("TRA",.T.)
			TRA->TOTAL    := nTotFat
			TRA->QUANT    := nTotQuant
			TRA->QUANTUM  := nTotUM			
			TRA->PRODUTO  := cProduto
			TRA->DESC     := cDesc
			TRA->UM	      := cUM
			msUnLock("TRA")
			
			cProduto  := ART->D2_COD
			cDesc     := ART->B1_DESC
			cUM       := ART->B1_UM
			
			nTotFat   := 0
			nTotQuant := 0
			nTotUM    := 0			
			nOcorrenc++
			
		Endif
		
	Endif
	
	If mv_par11 == "3"
		
		If cVendedor <> ART->D2_VEND1
			
			dbSelectArea("TRA")
			RecLock("TRA",.T.)
			TRA->TOTAL    := nTotFat
			TRA->QUANT    := nTotQuant
			TRA->QUANTUM  := nTotUM			
			TRA->VENDEDOR := cVendedor
			TRA->NOMEVEND := cNomeVend
			TRA->UFREP    := cUFRep
			msUnLock("TRA")
			
			cVendedor := ART->D2_VEND1
			cNomeVend := ART->A3_NOME
			cUFREP    := ART->A3_EST
			nTotFat   := 0
			nTotQuant := 0          
			nTotUM    := 0			
			
			nOcorrenc++
			
		Endif
		
	Endif
	
	If mv_par11 == "4"
		
		If cEstado <> ART->A1_EST
			
			dbSelectArea("TRA")
			RecLock("TRA",.T.)
			TRA->ESTADO   := cEstado
			TRA->TOTAL    := nTotFat
			TRA->QUANT    := nTotQuant
			TRA->QUANTUM  := nTotUM			
			msUnLock("TRA")
			
			cEstado   := ART->A1_EST
			nTotFat   := 0
			nTotQuant := 0        
			nTotUM    := 0	
			nOcorrenc++
			
		Endif
		
	Endif
	
	If mv_par11 == "5" // MUNICIPIO
		
		If cEstado <> ART->A1_EST .or. cCidade <> ART->A1_MUN
			
			If cEstado <> "EX"
				cPais := "BRA"
			Endif
			
			dbSelectArea("TRA")
			RecLock("TRA",.T.)
			TRA->ESTADO   := cEstado
			TRA->TOTAL    := nTotFat
			TRA->QUANT    := nTotQuant
			TRA->QUANTUM  := nTotUM			
			TRA->CIDADE   := cCidade
			TRA->PAIS     := cPais
			msUnLock("TRA")
			
			cEstado   := ART->A1_EST
			cCidade   := ART->A1_MUN
			cPais     := ART->A1_PAIS
			nTotFat   := 0
			nTotQuant := 0  
			nTotUM    := 0
			nOcorrenc++
			
		Endif   
	EndIf
		
	If mv_par11 == "6" // GRUPO de Produto
		
		If cGrupo <> SUBSTR(ART->B1_GRUPO,1,1)
		
			dbSelectArea("TRA")
			RecLock("TRA",.T.)
			TRA->GRUPO    := cGrupo
			TRA->TOTAL    := nTotFat
			TRA->QUANT    := nTotQuant    
			TRA->QUANTUM  := nTotUM			
			TRA->GRDESC	  := Posicione("SBM",1,XFILIAL("SBM")+cGrupo,"BM_DESC")

			msUnLock("TRA")
			
			cGrupo   := SUBSTR(ART->B1_GRUPO,1,1)
			nTotFat   := 0
			nTotQuant := 0  
			nTotUM    := 0
			
			nOcorrenc++
			
		Endif
	Endif
	
dbSelectArea("ART")
	
Enddo

//ROTINA DE IMPRESSÃO

nClasseA  := Round(nTotFatG * (mv_par12 / 100),2)
nClasseB  := Round(nTotFatG * (mv_par13 / 100),2)
nClasseC  := Round(nTotFatG * (mv_par14 / 100),2)

nImpCabec := "S"

dbSelectArea("TRA")
dbGoBottom()

SetRegua(RecCount("TRA"))

For x:=1 to nOcorrenc
	
	If lAbortPrint
		@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
		Exit
	Endif
	
	//123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
	//         1         2         3         4         5         6         7         8         9         10        11
	//PRODUTO                                                    PESO LÍQUIDO    PESO BRUTO
	//999999999999999  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  1,00            99.99
	//
	
	If nLin > 75
		
		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
		
		nLin := 6
		
		If nImpCabec == "S"
			
			@nLin,01 pSay "Dados do Período entre " + Dtoc(MV_PAR03) +" e " + Dtoc(MV_PAR04)
            
			nLin++
			
			@nLin,01 pSay "CLASSE A ("
			@nLin,11 pSay mv_par12 Picture "@E 99.99"
			@nLin,16 pSay "%):"
			@nLin,20 pSay nClasseA Picture "@E 9,999,999.99"
			@nLin,35 pSay "CLASSE B ("
			@nLin,45 pSay mv_par13 Picture "@E 99.99"
			@nLin,50 pSay "%):"
			@nLin,54 pSay nClasseB Picture "@E 9,999,999.99"
			@nLin,68 pSay "CLASSE C ("
			@nLin,78 pSay mv_par14 Picture "@E 99.99"
			@nLin,83 pSay "%):"
			@nLin,87 pSay nClasseC Picture "@E 9,999,999.99"
			
			nLin++
			nLin++
			
			nImpCabec := "N"
			
		Endif
		
		If mv_par11 == "1"
			@nLin,01 pSay "CLIENTE  NOME                                      ESTADO QUANTIDADE  PESO    FATURAMENTO     % PARTIC.  % PART.ACM.  RANK.  CURVA ABC"
		Else
			If mv_par11 == "2"
				@nLin,01 pSay  " PRODUTO                             DESCRIÇÃO  UM      QUANT           PESO   FATURAMENTO   %PARTIC.   % PART.ACM.  RANK   ABC"
				//				"PRODUTO          DESCRIÇÃO                                QUANTIDADE  PESO    FATURAMENTO     % PARTIC.  % PART.ACM.  RANK.  CURVA ABC"
				             
			Else
				If mv_par11 == "3"
					@nLin,01 pSay "VENDEDOR  NOME                                       UF   QUANTIDADE  PESO    FATURAMENTO     % PARTIC.  % PART.ACM.  RANK.  CURVA ABC"
				Else
					If mv_par11 == "4"
						@nLin,01 pSay "ESTADO  NOME                                              QUANTIDADE  PESO    FATURAMENTO     % PARTIC.  % PART.ACM.  RANK.  CURVA ABC"
					Else              
						If mv_par11 == "5"
							@nLin,01 pSay "MUNICIPIO             ESTADO  PAÍS						QUANTIDADE  PESO    FATURAMENTO     % PARTIC.  % PART.ACM.  RANK.  CURVA ABC"
						EndIf
							If mv_par11 == "6"
								@nLin,01 pSay "GRUPO                                                   QUANTIDADE  PESO    FATURAMENTO     % PARTIC.  % PART.ACM.  RANK.  CURVA ABC"
							EndIf
						
						
					Endif
				Endif
			Endif
		Endif
		nLin++
		nLin++
	Endif
	
	If mv_par11 == "1"
		@nLin,01 pSay TRA->CLIENTE
		@nLin,10 pSay Substr(TRA->NOMECLI,1,40)
		@nLin,52 pSay TRA->ESTADO
	Else
		If mv_par11 == "2"
			@nLin,01 pSay TRA->PRODUTO
			@nLin,13 pSay TRA->DESC
			@nLin,50 pSay TRA->UM
		Else
			If mv_par11 == "3"
				@nLin,01 pSay TRA->VENDEDOR
				@nLin,11 pSay Alltrim(TRA->NOMEVEND)
				@nLin,54 pSay TRA->UFREP
			Else
				If mv_par11 == "4"
					@nLin,01 pSay TRA->ESTADO
					dbSelectArea("SX5")
					dbSeek(xFilial()+"12"+TRA->ESTADO)
					@nLin,09 PSay X5Descri()
				Else
					If mv_par11 == "5"
						@nLin,01 pSay TRA->CIDADE
						@nLin,26 pSay TRA->ESTADO
						@nLin,32 pSay Posicione("SZC",1,xFilial("SZC")+TRA->PAIS,"ZC_PAIS")
					Else
			            If mv_par11 == "6"
							@nLin,01 pSay TRA->GRUPO
							@nLin,05 pSay TRA->GRDESC
							
						Endif
					EndIf
				Endif
			Endif
		Endif
	EndIf

	
	nPartic   := Round(100 * TRA->TOTAL / nTotFatG,3)
	nPartAcum := nPartAcum + nPartic

// " PRODUTO                             DESCRICAO  UM      QUANT           PESO   FATURAMENTO   %PARTIC.   % PART.ACM.  RANK   ABC"
// XXXXXXXXX   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  XX   9,999,999  9,999,999.99  9,999,999.99   9999.999      9999.999  9999    X
//01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
//         10        20        30        40        50        60        70        80        90       100       110       120       130

	
	@nLin,055 pSay TRA->QUANTUM		PICTURE "@E 9,999,999"
	@nLin,066 pSay TRA->QUANT		PICTURE "@E 9,999,999.99"
	@nLin,080 pSay TRA->TOTAL		PICTURE "@E 999,999,999.99"
	@nLin,095 pSay nPartic     		PICTURE "@E 999.999"
	@nLin,106 pSay nPartAcum   		PICTURE "@E 999.999"
	@nLin,119 pSay nRank			PICTURE "@E 9999"

	
	
	If nClasseA > 0
		@nLin,127 pSay "A"
		nClasseA := nClasseA - TRA->TOTAL
	Else
		If nClasseB > 0
			@nLin,127 pSay "B"
			nClasseB := nClasseB - TRA->TOTAL
		Else
			@nLin,127 pSay "C"
		Endif
	Endif
	
	nLin++
	nRank++
	nTotPart := nTotPart + nPartic
	
	dbSelectArea("TRA")
	dbSkip(-1)
	
	IncRegua()
	
Next x

nLin++

@nLin,41 pSay "TOTAL ------->"
@nLin,65 pSay nTotQtG   	PICTURE "@E 9,999,999.99"
@nLin,79 pSay nTotFatG  	PICTURE "@E 999,999,999.99"
@nLin,95 pSay nTotPart		PICTURE "@E 999.99"


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