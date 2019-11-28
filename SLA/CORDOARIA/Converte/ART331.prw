#INCLUDE "rwmake.ch"
#include "topconn.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณART331    บ Autor ณ CLOVIS EMMENDORFER บ Data ณ  12/03/08   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ RELATORIO COMPARATIVO FATURAMENTO X PRODUวรO               บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ ESPECIFICO PARA ARTEPLมS                                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

User Function ART331()

LOCAL cDesc1       := "Este programa tem como objetivo imprimir relatorio "
LOCAL cDesc2       := "de acordo com os parametros informados pelo usuario."
LOCAL cDesc3       := "Relatorio comparativo entre faturamento e produ็ใo."
LOCAL cPict        := ""
LOCAL titulo       := "Relatorio Faturamento x Produ็ใo"
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
Private nomeprog   := "ART331"
Private nTipo      := 18
Private aReturn    := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey   := 0
Private cPerg      := "ART331"
Private cbtxt      := Space(10)
Private cbcont     := 00
Private CONTFL     := 01
Private m_pag      := 01
Private wnrel      := "ART331"

cPerg := "ART331"
aRegistros := {}
AADD(aRegistros,{cPerg,"01","Grupo de  ?","","","mv_ch1","C",04,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SBM","","","",""})
AADD(aRegistros,{cPerg,"02","Grupo ate ?","","","mv_ch2","C",04,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SBM","","","",""})
AADD(aRegistros,{cPerg,"03","Data de   ?","","","mv_ch3","D",08,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"04","Data ate  ?","","","mv_ch4","D",08,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Declaracao de Variaveis                                             ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

pergunte(cPerg,.F.)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Monta a interface padrao com o usuario...                           ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

wnrel := SetPrint(cString,NomeProg,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)

If nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
	Return
Endif

nTipo := If(aReturn[4]==1,15,18)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Processamento. RPTSTATUS monta janela com a regua de processamento. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบFuno    ณRUNREPORT บ Autor ณ AP6 IDE            บ Data ณ  29/11/06   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescrio ณ Funcao auxiliar chamada pela RPTSTATUS. A funcao RPTSTATUS บฑฑ
ฑฑบ          ณ monta a janela com a regua de processamento.               บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Programa principal                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)

nFatCordas := 0 //Notas fiscais de saํda de cordas

//TOTAIS POR GRUPO
nFat    := 0
nProd   := 0
nBoni   := 0
nZ3     := 0
nTotFat := 0
nTotPro := 0
nTotBon := 0
nTotZ3  := 0

//TOTAIS POR FAMอLIA
nTFCO := 0 //Total Faturamento de Cordas
nTFFI := 0 //Total Faturamento de Fios
nTFFB := 0 //Total Faturamento de Fibras
nTFGR := 0 //Total Faturamento de Grใos

nTPCO := 0 //Total Produ็ใo de Cordas
nTPFI := 0 //Total Produ็ใo de Fios
nTPFB := 0 //Total Produ็ใo de Fibras
nTPGR := 0 //Total Produ็ใo de Grใos

nTBCO := 0 //Total Bonifica็ใo de Cordas
nTBFI := 0 //Total Bonifica็ใo de Fios
nTBFB := 0 //Total Bonifica็ใo de Fibras
nTBGR := 0 //Total Bonifica็ใo de Grใos

nTZCO := 0 //Total Z3 Cordas
nTZFI := 0 //Total Z3 Fios
nTZFB := 0 //Total Z3 Fibras
nTZGR := 0 //Total Z3 Grใos

//TOTAIS POR RESUMO
nTFTRA   := 0 //Total faturado cordas tran็adas
nTFTOR   := 0 //Total faturado cordas torcidas
nTFTRR   := 0 //Total faturado cordas torcidas e retorcidas
nTFMULTI := 0 //Total faturamento multifilamento
nTFMONO  := 0 //Total faturamento monofilamento
nTFPE    := 0 //Total faturamento cordas PE
nTFPET   := 0 //Total faturamento cordas PET
nTFPP    := 0 //Total faturamento cordas PP
nTFFIB   := 0 //Total faturado fibras
nTFFIO   := 0 //Total faturado fios
nTFGRA   := 0 //Total faturado grใos
nTPTRA   := 0 //Total produ็ใo cordas tran็adas
nTPTOR   := 0 //Total produ็ใo cordas torcidas
nTPTRR   := 0 //Total produ็ใo cordas torcidas e retorcidas
nTPMULTI := 0 //Total produ็ใo multifilamento
nTPMONO  := 0 //Total produ็ใo monofilamento
nTPPE    := 0 //Total produ็ใo cordas PE
nTPPET   := 0 //Total produ็ใo cordas PET
nTPPP    := 0 //Total produ็ใo cordas PP
nTPFIB   := 0 //Total produ็ใo fibras
nTPFIO   := 0 //Total produ็ใo fios
nTPGRA   := 0 //Total produ็ใo grใos
nTBTRA   := 0 //Total bonifica็ใo cordas tran็adas
nTBTOR   := 0 //Total bonifica็ใo cordas torcidas
nTBTRR   := 0 //Total bonifica็ใo cordas torcidas e retorcidas
nTBMULTI := 0 //Total bonifica็ใo multifilamento
nTBMONO  := 0 //Total bonifica็ใo monofilamento
nTBPE    := 0 //Total bonifica็ใo cordas PE
nTBPET   := 0 //Total bonifica็ใo cordas PET
nTBPP    := 0 //Total bonifica็ใo cordas PP
nTBFIB   := 0 //Total bonifica็ใo fibras
nTBFIO   := 0 //Total bonifica็ใo fios
nTBGRA   := 0 //Total bonifica็ใo grใos
nTZTRA   := 0 //Total Z3 cordas tran็adas
nTZTOR   := 0 //Total Z3 cordas torcidas
nTZTRR   := 0 //Total Z3 cordas torcidas e retorcidas
nTZFIB   := 0 //Total Z3 fibras
nTZFIO   := 0 //Total Z3 fios
nTZGRA   := 0 //Total Z3 grใos
nTZMULTI := 0 //Total Z3 multifilamento
nTZMONO  := 0 //Total Z3 monofilamento
nTZPE    := 0 //Total Z3 cordas PE
nTZPET   := 0 //Total Z3 cordas PET
nTZPP    := 0 //Total Z3 cordas PP

nTFD     := 0 //Total faturamento diversos
nTPD     := 0 //Total produ็ใo diversos
nTBD     := 0 //Total bonifica็ใo diversos
nTZ3D    := 0 //Total Z3 diversos

nDiferenca := 0
nAux       := 0

//BUSCA TOTAL FATURADO CORDAS
cQry := "SELECT D2_QUANT,D2_QTSEGUM,D2_SEGUM,D2_UM,D2_PESO "
cQry += "FROM " + RETSQLNAME("SD2") + " SD2, "
cQry += " " + RETSQLNAME("SF4") + " SF4 "
cQry += "WHERE SD2.D_E_L_E_T_ <> '*' AND "
cQry += "SF4.D_E_L_E_T_ <> '*' AND "
cQry += "D2_FILIAL = '" + xFilial("SD2") + "' AND "
cQry += "F4_FILIAL = '" + xFilial("SF4") + "' AND "
cQry += "D2_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' AND "
cQry += "D2_GRUPO BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' AND "
cQry += "F4_CODIGO = D2_TES AND F4_ESTOQUE = 'S' AND D2_TIPO = 'N' AND D2_GRUPO >= 'A' AND D2_GRUPO <= 'FZZZ' "

If (Select("ART") <> 0)
	dbSelectArea("ART")
	dbCloseArea()
Endif

TCQUERY cQry NEW Alias "ART"

dbSelectArea("ART")
dbGoTop()

While !EOF()
	
	If ART->D2_UM == 'KG'
		nFatCordas += ART->D2_QUANT
	Else
		If ART->D2_SEGUM == 'KG'
			nFatCordas += ART->D2_QTSEGUM
		Else
			If ART->D2_UM == 'PC'
				nFatCordas += ART->D2_QUANT * ART->D2_PESO
			Endif
		Endif
	Endif
	
	dbSkip()
	
Enddo

dbSelectArea("SBM")
dbSetOrder(1)
dbGoTop()

dbSeek(xFilial("SBM")+"A",.F.)

SetRegua(RecCount("SBM"))

While !EOF() .and. SBM->BM_GRUPO <= 'IZZZ'
	
	If SBM->BM_GRUPO < mv_par01 .or. SBM->BM_GRUPO > mv_par02
		dbSkip()
		Loop
	Endif
	
	//BUSCA INFORMAวีES DE FATURAMENTO
	cQry := "SELECT D2_QUANT,D2_QTSEGUM,D2_SEGUM,D2_UM,D2_PESO,B1_TIPOCOR,B1_TIPOFIO,B1_GRUPO,B1_MP "
	cQry += "FROM " + RETSQLNAME("SD2") + " SD2, "
	cQry += " " + RETSQLNAME("SF4") + " SF4, "
	cQry += " " + RETSQLNAME("SB1") + " SB1 "
	cQry += "WHERE SD2.D_E_L_E_T_ <> '*' AND "
	cQry += "SF4.D_E_L_E_T_ <> '*' AND "
	cQry += "SB1.D_E_L_E_T_ <> '*' AND "
	cQry += "D2_FILIAL = '" + xFilial("SD2") + "' AND D2_COD = B1_COD AND "
	cQry += "F4_FILIAL = '" + xFilial("SF4") + "' AND "
	cQry += "B1_FILIAL = '" + xFilial("SB1") + "' AND "
	cQry += "D2_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' AND "
	cQry += "D2_GRUPO = '" + SBM->BM_GRUPO + "' AND "
	cQry += "F4_CODIGO = D2_TES AND F4_DUPLIC = 'S' AND D2_TIPO = 'N' AND D2_TES <> '604' "
	
	If (Select("ART") <> 0)
		dbSelectArea("ART")
		dbCloseArea()
	Endif
	
	TCQUERY cQry NEW Alias "ART"
	
	dbSelectArea("ART")
	dbGoTop()
	
	While !EOF()
		
		If ART->D2_UM == 'KG'
			nFat += ART->D2_QUANT
			nAux := ART->D2_QUANT
		Else
			If ART->D2_SEGUM == 'KG'
				nFat += ART->D2_QTSEGUM
				nAux := ART->D2_QTSEGUM
			Else
				If ART->D2_UM == 'PC'
					nFat += ART->D2_QUANT * ART->D2_PESO
					nAux := ART->D2_QUANT * ART->D2_PESO
				Endif
			Endif
		Endif
		
		If ART->B1_GRUPO >= 'A' .and. ART->B1_GRUPO <= 'FZZZ' //CORDAS
			
			nTFCO += nAux
			
			If ART->B1_TIPOFIO == 'MULTI'
				nTFMULTI += nAux
			Else
				nTFMONO += nAux
			Endif
			
			If Alltrim(ART->B1_MP) == 'PET'
				nTFPET += nAux
			Else
				If Alltrim(ART->B1_MP) == 'PE'
					nTFPE += nAux
				Else
					nTFPP += nAux
				Endif
			Endif
			
			If ART->B1_TIPOCOR == 'TRA'
				nTFTRA += nAux
			Else
				If ART->B1_TIPOCOR == 'TOR'
					nTFTOR += nAux
				Else
					If ART->B1_TIPOCOR == 'TRR'
						nTFTRR += nAux
					Endif
				Endif
			Endif
			
		Endif
		
		If SBM->BM_GRUPO >= 'G' .and. SBM->BM_GRUPO <= 'GZZZ' //GRรOS
			nTFGRA += nAux
		Else
			If SBM->BM_GRUPO >= 'H' .and. SBM->BM_GRUPO <= 'HZZZ' //FIBRAS
				nTFFIB += nAux
			Else
				If SBM->BM_GRUPO >= 'I' .and. SBM->BM_GRUPO <= 'IZZZ' //FIOS
					nTFFIO += nAux
				Endif
			Endif
		Endif
		
		dbSkip()
		
	Enddo
	
	nTotFat += nFat
	
	//BUSCA INFORMAวีES DE PRODUวรO
	cQuery := "SELECT D3_COD, D3_UM, D3_QUANT, D3_QTSEGUM, B1_GRUPO,B1_TIPOCOR,B1_TIPOFIO,B1_MP "
	cQuery += "FROM " + RetSqlName("SD3") + " SD3, "
	cQuery += " " + RetSqlName("SB1") + " SB1 "
	cQuery += "WHERE SD3.D_E_L_E_T_ <> '*' AND D3_TM = '003' AND D3_ESTORNO <> 'S' "
	cQuery += "AND SB1.D_E_L_E_T_ <> '*' AND B1_COD = D3_COD "
	cQuery += "AND D3_FILIAL = '" + xFilial("SD3") + "' "
	cQuery += "AND B1_FILIAL = '" + xFilial("SB1") + "' "
	cQuery += "AND B1_GRUPO = '" + SBM->BM_GRUPO + "' "
	cQuery += "AND D3_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	cQuery += "ORDER BY B1_GRUPO,D3_COD "
	
	If (Select("ART") <> 0)
		dbSelectArea("ART")
		dbCloseArea()
	Endif
	
	TCQUERY cQuery NEW Alias "ART"
	
	dbSelectArea("ART")
	dbGoTop()
	
	While !EOF()
		
		If ART->D3_UM == "KG"
			
			nProd += ART->D3_QUANT
			nAux  := ART->D3_QUANT
			
		Else
			
			nProd += ART->D3_QTSEGUM
			nAux  := ART->D3_QTSEGUM
			
		Endif
		
		If ART->B1_GRUPO >= 'A' .and. ART->B1_GRUPO <= 'FZZZ' //CORDAS
			
			nTPCO += nAux
			
			If ART->B1_TIPOFIO == 'MULTI'
				nTPMULTI += nAux
			Else
				nTPMONO += nAux
			Endif
			
			If Alltrim(ART->B1_MP) == 'PET'
				nTPPET += nAux
			Else
				If Alltrim(ART->B1_MP) == 'PE'
					nTPPE += nAux
				Else
					nTPPP += nAux
				Endif
			Endif
			
			If ART->B1_TIPOCOR == 'TRA'
				nTPTRA += nAux
			Else
				If ART->B1_TIPOCOR == 'TOR'
					nTPTOR += nAux
				Else
					If ART->B1_TIPOCOR == 'TRR'
						nTPTRR += nAux
					Endif
				Endif
			Endif
			
		Endif
		
		If SBM->BM_GRUPO >= 'G' .and. SBM->BM_GRUPO <= 'GZZZ' //GRรOS
			nTPGRA += nAux
		Else
			If SBM->BM_GRUPO >= 'H' .and. SBM->BM_GRUPO <= 'HZZZ' //FIBRAS
				nTPFIB += nAux
			Else
				If SBM->BM_GRUPO >= 'I' .and. SBM->BM_GRUPO <= 'IZZZ' //FIOS
					nTPFIO += nAux
				Endif
			Endif
		Endif
		
		dbSkip()
		
	Enddo
	
	nTotPro += nProd
	
	//BUSCA INFORMAวีES DE BONIFICAวรO
	cQry := "SELECT D2_QUANT,D2_QTSEGUM,D2_SEGUM,D2_UM,D2_PESO,B1_TIPOCOR,B1_TIPOFIO,B1_GRUPO,B1_MP "
	cQry += "FROM " + RETSQLNAME("SD2") + " SD2, "
	cQry += " " + RETSQLNAME("SB1") + " SB1 "
	cQry += "WHERE SD2.D_E_L_E_T_ <> '*' AND "
	cQry += "SB1.D_E_L_E_T_ <> '*' AND B1_COD = D2_COD AND "
	cQry += "D2_FILIAL = '" + xFilial("SD2") + "' AND "
	cQry += "B1_FILIAL = '" + xFilial("SB1") + "' AND "
	cQry += "D2_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' AND "
	cQry += "D2_GRUPO = '" + SBM->BM_GRUPO + "' AND "
	cQry += "D2_TIPO = 'N' AND SUBSTRING(D2_CF,2,3) = '910' "
	
	If (Select("ART") <> 0)
		dbSelectArea("ART")
		dbCloseArea()
	Endif
	
	TCQUERY cQry NEW Alias "ART"
	
	dbSelectArea("ART")
	dbGoTop()
	
	While !EOF()
		
		If ART->D2_UM == 'KG'
			nBoni += ART->D2_QUANT
			nAux  := ART->D2_QUANT
		Else
			If ART->D2_SEGUM == 'KG'
				nBoni += ART->D2_QTSEGUM
				nAux  := ART->D2_QTSEGUM
			Else
				If ART->D2_UM == 'PC'
					nBoni += ART->D2_QUANT * ART->D2_PESO
					nAux  := ART->D2_QUANT * ART->D2_PESO
				Endif
			Endif
		Endif
		
		If ART->B1_GRUPO >= 'A' .and. ART->B1_GRUPO <= 'FZZZ' //CORDAS
			
			nTBCO += nAux
			
			If ART->B1_TIPOFIO == 'MULTI'
				nTBMULTI += nAux
			Else
				nTBMONO += nAux
			Endif
			
			If Alltrim(ART->B1_MP) == 'PET'
				nTBPET += nAux
			Else
				If Alltrim(ART->B1_MP) == 'PE'
					nTBPE += nAux
				Else
					nTBPP += nAux
				Endif
			Endif
			
			If ART->B1_TIPOCOR == 'TRA'
				nTBTRA += nAux
			Else
				If ART->B1_TIPOCOR == 'TOR'
					nTBTOR += nAux
				Else
					If ART->B1_TIPOCOR == 'TRR'
						nTBTRR += nAux
					Endif
				Endif
			Endif
			
		Endif
		
		If SBM->BM_GRUPO >= 'G' .and. SBM->BM_GRUPO <= 'GZZZ' //GRรOS
			nTBGRA += nAux
		Else
			If SBM->BM_GRUPO >= 'H' .and. SBM->BM_GRUPO <= 'HZZZ' //FIBRAS
				nTBFIB += nAux
			Else
				If SBM->BM_GRUPO >= 'I' .and. SBM->BM_GRUPO <= 'IZZZ' //FIOS
					nTBFIO += nAux
				Endif
			Endif
		Endif
		
		dbSkip()
		
	Enddo
	
	nTotBon += nBoni
	
	//BUSCA INFORMAวีES Z3
	cQry := "SELECT D2_QUANT,D2_QTSEGUM,D2_SEGUM,D2_UM,D2_PESO,B1_TIPOCOR,B1_TIPOFIO,B1_GRUPO,B1_MP "
	cQry += "FROM " + RETSQLNAME("SD2") + " SD2, "
	cQry += " " + RETSQLNAME("SF4") + " SF4, "
	cQry += " " + RETSQLNAME("SB1") + " SB1 "
	cQry += "WHERE SD2.D_E_L_E_T_ <> '*' AND "
	cQry += "SF4.D_E_L_E_T_ <> '*' AND "
	cQry += "SB1.D_E_L_E_T_ <> '*' AND "
	cQry += "D2_FILIAL = '" + xFilial("SD2") + "' AND "
	cQry += "B1_FILIAL = '" + xFilial("SB1") + "' AND "
	cQry += "F4_FILIAL = '" + xFilial("SF4") + "' AND B1_COD = D2_COD AND "
	cQry += "D2_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' AND "
	cQry += "D2_GRUPO = '" + SBM->BM_GRUPO + "' AND "
	cQry += "F4_CODIGO = D2_TES AND F4_DUPLIC = 'S' AND D2_TIPO = 'N' AND D2_TES = '604' "
	
	If (Select("ART") <> 0)
		dbSelectArea("ART")
		dbCloseArea()
	Endif
	
	TCQUERY cQry NEW Alias "ART"
	
	dbSelectArea("ART")
	dbGoTop()
	
	While !EOF()
		
		If ART->D2_UM == 'KG'
			nZ3 += ART->D2_QUANT
			nAux := ART->D2_QUANT
		Else
			If ART->D2_SEGUM == 'KG'
				nZ3 += ART->D2_QTSEGUM
				nAux := ART->D2_QTSEGUM
			Else
				If ART->D2_UM == 'PC'
					nZ3 += ART->D2_QUANT * ART->D2_PESO
					nAux := ART->D2_QUANT * ART->D2_PESO
				Endif
			Endif
		Endif
		
		If ART->B1_GRUPO >= 'A' .and. ART->B1_GRUPO <= 'FZZZ' //CORDAS
			
			nTZCO += nAux
			
			If ART->B1_TIPOFIO == 'MULTI'
				nTZMULTI += nAux
			Else
				nTZMONO += nAux
			Endif
			
			If Alltrim(ART->B1_MP) == 'PET'
				nTZPET += nAux
			Else
				If Alltrim(ART->B1_MP) == 'PE'
					nTZPE += nAux
				Else
					nTZPP += nAux
				Endif
			Endif
			
			If ART->B1_TIPOCOR == 'TRA'
				nTZTRA += nAux
			Else
				If ART->B1_TIPOCOR == 'TOR'
					nTZTOR += nAux
				Else
					If ART->B1_TIPOCOR == 'TRR'
						nTZTRR += nAux
					Endif
				Endif
			Endif
			
		Endif
		
		If SBM->BM_GRUPO >= 'G' .and. SBM->BM_GRUPO <= 'GZZZ' //GRรOS
			nTZGRA += nAux
		Else
			If SBM->BM_GRUPO >= 'H' .and. SBM->BM_GRUPO <= 'HZZZ' //FIBRAS
				nTZFIB += nAux
			Else
				If SBM->BM_GRUPO >= 'I' .and. SBM->BM_GRUPO <= 'IZZZ' //FIOS
					nTZFIO += nAux
				Endif
			Endif
		Endif
		
		nTotZ3 += nAux
		
		dbSkip()
		
	Enddo
	
	cQry := "SELECT ZF_QUANT,ZF_QTSEGUM,ZF_SEGUM,ZF_UM,B1_PESO,B1_TIPOCOR,B1_TIPOFIO,B1_GRUPO,B1_MP "
	cQry += "FROM " + RETSQLNAME("SZF") + " SZF, "
	cQry += " " + RETSQLNAME("SB1") + " SB1 "
	cQry += "WHERE SZF.D_E_L_E_T_ <> '*' AND "
	cQry += "SB1.D_E_L_E_T_ <> '*' AND "
	cQry += "ZF_FILIAL = '" + xFilial("SZF") + "' AND "
	cQry += "B1_FILIAL = '" + xFilial("SB1") + "' AND "
	cQry += "B1_COD = ZF_COD AND "
	cQry += "ZF_DTMETA BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' AND "
	cQry += "B1_GRUPO = '" + SBM->BM_GRUPO + "' "
	
	If (Select("ART") <> 0)
		dbSelectArea("ART")
		dbCloseArea()
	Endif
	
	TCQUERY cQry NEW Alias "ART"
	
	dbSelectArea("ART")
	dbGoTop()
	
	While !EOF()
		
		If ART->ZF_UM == 'KG'
			nZ3 += ART->ZF_QUANT
			nAux := ART->ZF_QUANT
		Else
			If ART->ZF_SEGUM == 'KG'
				nZ3 += ART->ZF_QTSEGUM
				nAux := ART->ZF_QTSEGUM
			Else
				If ART->ZF_UM == 'PC'
					nZ3 += ART->ZF_QUANT * ART->B1_PESO
					nAux := ART->ZF_QUANT * ART->B1_PESO
				Endif
			Endif
		Endif
		
		If ART->B1_GRUPO >= 'A' .and. ART->B1_GRUPO <= 'FZZZ' //CORDAS
			
			nTZCO += nAux
			
			If ART->B1_TIPOFIO == 'MULTI'
				nTZMULTI += nAux
			Else
				nTZMONO += nAux
			Endif
			
			If Alltrim(ART->B1_MP) == 'PET'
				nTZPET += nAux
			Else
				If Alltrim(ART->B1_MP) == 'PE'
					nTZPE += nAux
				Else
					nTZPP += nAux
				Endif
			Endif
			
			If ART->B1_TIPOCOR == 'TRA'
				nTZTRA += nAux
			Else
				If ART->B1_TIPOCOR == 'TOR'
					nTZTOR += nAux
				Else
					If ART->B1_TIPOCOR == 'TRR'
						nTZTRR += nAux
					Endif
				Endif
			Endif
			
		Endif
		
		If SBM->BM_GRUPO >= 'G' .and. SBM->BM_GRUPO <= 'GZZZ' //GRรOS
			nTZGRA += nAux
		Else
			If SBM->BM_GRUPO >= 'H' .and. SBM->BM_GRUPO <= 'HZZZ' //FIBRAS
				nTZFIB += nAux
			Else
				If SBM->BM_GRUPO >= 'I' .and. SBM->BM_GRUPO <= 'IZZZ' //FIOS
					nTZFIO += nAux
				Endif
			Endif
		Endif
		
		nTotZ3 += nAux
		
		dbSkip()
		
	Enddo
	
	//ROTINA DE IMPRESSรO
	
	SetRegua(RecCount())
	
	If lAbortPrint
		@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
		Exit
	Endif
	
	//123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
	//         1         2         3         4         5         6         7         8         9         10        11        12        13
	//GRUPO                                 PRODUวรO        FATURAMENTO     VENDAS Z3       BONIFICAวรO     DIFERENวA       % VENDA
	//9999  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  999.999.999,99  999.999.999,99  999.999.999,99  999.999.999,99  999.999.999,99  999.99
	
	If nLin > 55
		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
		nLin := 6
		@nLin,48 pSay "Perํodo de " + dtoc(mv_par03) + " a " + dtoc(mv_par04)
		nLin++
		nLin++
		@nLin,01 pSay "GRUPO                                 PRODUวรO        FATURAMENTO            Z3       BONIFICAวรO     DIFERENวA       % VENDA"
		nLin++
		@nLin,01 pSay Replicate("-",132)
		nLin++
		nLin++
	Endif
	
	If nProd > 0 .or. nFat > 0 .or. nZ3 > 0 .or. nBoni > 0
		
		@nLin,001 pSay SBM->BM_GRUPO
		@nLin,007 pSay Substr(SBM->BM_DESC,1,30)
		@nLin,039 pSay nProd                         PICTURE "@E 999,999,999.99"
		@nLin,055 pSay nFat                          PICTURE "@E 999,999,999.99"
		@nLin,071 pSay nZ3                           PICTURE "@E 999,999,999.99"
		@nLin,087 pSay nBoni                         PICTURE "@E 999,999,999.99"
		@nLin,103 pSay nProd - nBoni - nFat - nZ3    PICTURE "@E 999,999,999.99"
		
		If Substr(SBM->BM_GRUPO,1,1) >= 'A' .and. Substr(SBM->BM_GRUPO,1,1) <= 'F'
			@nLin,119 pSay ((nBoni + nFat + nZ3) / nFatCordas) * 100   PICTURE "@E 999.99"
		Endif
		
		nFat  := 0
		nProd := 0
		nBoni := 0
		nZ3   := 0
		nLin++
		
	Endif
	
	dbSelectArea("SBM")
	dbSkip()
	
	IncRegua()
	
EndDo

nLin++

@nLin,007 pSay "TOTAL CORDAS           =>"
@nLin,039 pSay nTPCO       PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFCO       PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZCO       PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBCO       PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPCO - nTFCO - nTZCO - nTBCO   PICTURE "@E 999,999,999.99"
@nLin,119 pSay (nTBCO + nTFCO + nTZCO) / (nTotFat + nTotZ3 + nTotBon) * 100   PICTURE "@E 999.99"

nLin++

@nLin,007 pSay "TOTAL FIOS             =>"
@nLin,039 pSay nTPFIO       PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFFIO       PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZFIO       PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBFIO       PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPFIO - nTFFIO - nTZFIO - nTBFIO   PICTURE "@E 999,999,999.99"
@nLin,119 pSay (nTBFIO + nTFFIO + nTZFIO) / (nTotFat + nTotZ3 + nTotBon) * 100   PICTURE "@E 999.99"

nLin++

@nLin,007 pSay "TOTAL FIBRAS           =>"
@nLin,039 pSay nTPFIB       PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFFIB       PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZFIB       PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBFIB       PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPFIB - nTFFIB - nTZFIB - nTBFIB   PICTURE "@E 999,999,999.99"
@nLin,119 pSay (nTBFIB + nTFFIB + nTZFIB) / (nTotFat + nTotZ3 + nTotBon) * 100   PICTURE "@E 999.99"

nLin++

@nLin,007 pSay "TOTAL GRรOS            =>"
@nLin,039 pSay nTPGRA       PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFGRA       PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZGRA       PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBGRA       PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPGRA - nTFGRA - nTZGRA - nTBGRA   PICTURE "@E 999,999,999.99"
@nLin,119 pSay (nTBGRA + nTFGRA + nTZGRA) / (nTotFat + nTotZ3 + nTotBon) * 100   PICTURE "@E 999.99"

nLin++
nLin++

@nLin,007 pSay "TOTAL GERAL            =>"
@nLin,039 pSay nTotPro        PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTotFat        PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTotZ3         PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTotBon        PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTotPro - nTotFat - nTotZ3 - nTotBon   PICTURE "@E 999,999,999.99"

Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
nLin := 6
@nLin,01 pSay "RESUMO                                PRODUวรO        FATURAMENTO            Z3       BONIFICAวรO     DIFERENวA       % VENDA"
nLin++
@nLin,01 pSay Replicate("-",132)
nLin++
nLin++

@nLin,007 pSay "Cordas Multifilamento  =>"
@nLin,039 pSay nTPMULTI        PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFMULTI        PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZMULTI        PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBMULTI        PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPMULTI - nTFMULTI - nTZMULTI - nTBMULTI   PICTURE "@E 999,999,999.99"
@nLin,119 pSay (nTFMULTI + nTZMULTI + nTBMULTI) / (nTFMONO + nTFMULTI + nTZMONO + nTZMULTI + nTBMONO + nTBMULTI) * 100   PICTURE "@E 999.99"

nLin++

@nLin,007 pSay "Cordas Monofilamento   =>"
@nLin,039 pSay nTPMONO        PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFMONO        PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZMONO        PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBMONO        PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPMONO - nTFMONO - nTZMONO - nTBMONO   PICTURE "@E 999,999,999.99"
@nLin,119 pSay (nTFMONO + nTZMONO + nTBMONO) / (nTFMONO + nTFMULTI + nTZMONO + nTZMULTI + nTBMONO + nTBMULTI) * 100   PICTURE "@E 999.99"

nLin++
nLin++

@nLin,007 pSay "Cordas PE              =>"
@nLin,039 pSay nTPPE        PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFPE        PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZPE        PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBPE        PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPPE - nTFPE - nTZPE - nTBPE   PICTURE "@E 999,999,999.99"
@nLin,119 pSay (nTFPE + nTZPE + nTBPE) / (nTFPE + nTZPE + nTBPE + nTFPET + nTZPET + nTBPET + nTFPP + nTZPP + nTBPP) * 100   PICTURE "@E 999.99"

nLin++

@nLin,007 pSay "Cordas PET             =>"
@nLin,039 pSay nTPPET        PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFPET        PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZPET        PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBPET        PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPPET - nTFPET - nTZPET - nTBPET   PICTURE "@E 999,999,999.99"
@nLin,119 pSay (nTFPET + nTZPET + nTBPET) / (nTFPE + nTZPE + nTBPE + nTFPET + nTZPET + nTBPET + nTFPP + nTZPP + nTBPP) * 100   PICTURE "@E 999.99"

nLin++

@nLin,007 pSay "Cordas PP              =>"
@nLin,039 pSay nTPPP        PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFPP        PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZPP        PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBPP        PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPPP - nTFPP - nTZPP - nTBPP   PICTURE "@E 999,999,999.99"
@nLin,119 pSay (nTFPP + nTZPP + nTBPP) / (nTFPE + nTZPE + nTBPE + nTFPET + nTZPET + nTBPET + nTFPP + nTZPP + nTBPP) * 100   PICTURE "@E 999.99"

nLin++
nLin++

@nLin,007 pSay "Cordas Tran็adas       =>"
@nLin,039 pSay nTPTRA        PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFTRA        PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZTRA        PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBTRA        PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPTRA - nTFTRA - nTZTRA - nTBTRA   PICTURE "@E 999,999,999.99"
@nLin,119 pSay (nTFTRA + nTZTRA + nTBTRA) / (nTFTRA + nTZTRA + nTBTRA + nTFTOR + nTZTOR + nTBTOR + nTFTRR + nTZTRR + nTBTRR) * 100   PICTURE "@E 999.99"

nLin++

@nLin,007 pSay "Cordas Torcidas        =>"
@nLin,039 pSay nTPTOR        PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFTOR        PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZTOR        PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBTOR        PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPTOR - nTFTOR - nTZTOR - nTBTOR  PICTURE "@E 999,999,999.99"
@nLin,119 pSay (nTFTOR + nTZTOR + nTBTOR) / (nTFTRA + nTZTRA + nTBTRA + nTFTOR + nTZTOR + nTBTOR + nTFTRR + nTZTRR + nTBTRR) * 100   PICTURE "@E 999.99"

nLin++

@nLin,007 pSay "Cordas Torc. e Retorc. =>"
@nLin,039 pSay nTPTRR        PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFTRR        PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZTRR        PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBTRR        PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPTRR - nTFTRR - nTZTRR - nTBTRR   PICTURE "@E 999,999,999.99"
@nLin,119 pSay (nTFTRR + nTZTRR + nTBTRR) / (nTFTRA + nTZTRA + nTBTRA + nTFTOR + nTZTOR + nTBTOR + nTFTRR + nTZTRR + nTBTRR) * 100   PICTURE "@E 999.99"

nLin++
nLin++

@nLin,007 pSay "Fibras                 =>"
@nLin,039 pSay nTPFIB        PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFFIB        PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZFIB        PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBFIB        PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPFIB - nTFFIB - nTZFIB - nTBFIB   PICTURE "@E 999,999,999.99"

nLin++

@nLin,007 pSay "Fios                   =>"
@nLin,039 pSay nTPFIO        PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFFIO        PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZFIO        PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBFIO        PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPFIO - nTFFIO - nTZFIO - nTBFIO   PICTURE "@E 999,999,999.99"

nLin++

@nLin,007 pSay "Grใos                  =>"
@nLin,039 pSay nTPGRA        PICTURE "@E 999,999,999.99"
@nLin,055 pSay nTFGRA        PICTURE "@E 999,999,999.99"
@nLin,071 pSay nTZGRA        PICTURE "@E 999,999,999.99"
@nLin,087 pSay nTBGRA        PICTURE "@E 999,999,999.99"
@nLin,103 pSay nTPGRA - nTFGRA - nTZGRA - nTBGRA   PICTURE "@E 999,999,999.99"

dbCloseArea("ART")

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Finaliza a execucao do relatorio...                                 ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

SET DEVICE TO SCREEN

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Se impressao em disco, chama o gerenciador de impressao...          ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

If aReturn[5]==1
	dbCommitAll()
	SET PRINTER TO
	OurSpool(wnrel)
Endif

MS_FLUSH()

Return