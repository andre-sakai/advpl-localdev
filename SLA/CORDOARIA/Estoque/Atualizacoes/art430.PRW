#include "rwmake.ch"
#INCLUDE "topconn.ch"     
#INCLUDE "PROTHEUS.CH"  				
#include "TbiConn.ch"


/*                                                                                                                      
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ ART430   บ Eduardo Marquetti           บ Data ณ  13/06/18  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Imprime Etiquetas para os Bags de Materia Prima            บฑฑ
ฑฑบ          ณ     														  บฑฑ
ฑฑบ          ณ                       									  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ                                            บฑฑ
ฑฑฬออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบCampos    ณ                                                            บฑฑ
ฑฑฬออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบAltera็๕es:                      บฑฑ
ฑฑบAltera็๕es:                                      บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
  */  
  
                                                  
User Function ART430()


// DEFINE PERGUNTAS DO SX1

cPerg   :="ART430"   
aRegistros:={}


// cria vetor de perguntas
AADD(aRegistros,{cPerg,"01","Etiqueta de     ?","","","mv_ch1","C",09,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"02","Etiqueta ate    ?","","","mv_ch2","C",09,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
// verifica exist๊ncia de perguntas

dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)
For i:=1 to Len(aRegistros)
    If !dbSeek(cPerg+aRegistros[i,2])
        RecLock("SX1",.T.)
        For j:=1 to FCount()
            If j <= Len(aRegistros[i])
                FieldPut(j,aRegistros[i,j])
            Endif
        Next
        MsUnlock()
    Endif
Next
                  

cBarraImp := Space(50)           
lPrint:=.F.
nPosBar	:=  10        
cBitMap := "CBrasil.bmp"
nAjust1	:= -2100	
Npula   := 0

oFont8  := TFont():New( "Arial" ,,08,,.t.,,,,,.f. )
oFont10 := TFont():New( "Arial" ,,10,,.t.,,,,,.f. )
oFont12 := TFont():New( "Arial" ,,12,,.t.,,,,,.f. )
oFont14 := TFont():New( "Arial" ,,14,,.t.,,,,,.f. )
oFont16 := TFont():New( "Arial" ,,16,,.t.,,,,,.f. )
oFont18 := TFont():New( "Arial" ,,18,,.t.,,,,,.f. )
oFont20 := TFont():New( "Arial" ,,20,,.t.,,,,,.f. )
oFont26 := TFont():New( "Arial" ,,26,,.t.,,,,,.f. )
oFont72 := TFont():New( "Arial" ,,72,,.t.,,,,,.f. )

If Pergunte(cPerg,.T.)
	Runreport()
Endif

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบFuno    ณRUNREPORT บ Autor ณ AP6 IDE            บ Data ณ  08/06/18   บฑฑ
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

// 
cQuery := "SELECT ZJ_ID,ZJ_CARTAO,B1_DESC,ZJ_CODPRO,ZJ_QUANT,A2_NOME,ZJ_DATA,ZJ_DOC,D1_QUANT,D1_VUNIT,ZJ_CODBAR,ZJ_OBS "
cQuery += "FROM " + RETSQLNAME("SZJ") + " SZJ, " + RETSQLNAME("SB1") + " SB1, " + RETSQLNAME("SD1") + " SD1, "+ RETSQLNAME("SA2") + " SA2 "
cQuery += "WHERE "
cQuery += "ZJ_FILIAL = '" + xFilial("SZJ") + "'" + "AND B1_FILIAL = '" + xFilial("SB1") + "'" + "AND D1_FILIAL = '" + xFilial("SD1") + "'" + "AND A2_FILIAL = '" + xFilial("SA2") + "'"
cQuery += "AND SZJ.D_E_L_E_T_ = ' '  AND SB1.D_E_L_E_T_ = ' ' AND SD1.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' ' "
cQuery += "AND ZJ_CODPRO = B1_COD "
cQuery += "AND ZJ_DOC = D1_DOC  AND ZJ_SERIE = D1_SERIE AND ZJ_FORNECE = D1_FORNECE AND ZJ_LOJA = D1_LOJA AND ZJ_CODPRO = D1_COD "
cQuery += "AND A2_COD = D1_FORNECE AND A2_LOJA = D1_LOJA "                     
cQuery += "AND ZJ_DOC <> ' ' "
cQuery += "AND ZJ_ID BETWEEN '" + (mv_par01) + "' AND '" + (mv_par02) + "' "
cQuery += "UNION "
cQuery += "SELECT ZJ_ID,ZJ_CARTAO,B1_DESC,ZJ_CODPRO,ZJ_QUANT,' ' AS A2_NOME,ZJ_DATA,ZJ_DOC,' ' AS D1_QUANT,' ' AS D1_VUNIT,ZJ_CODBAR,ZJ_OBS "
cQuery += "FROM " + RETSQLNAME("SZJ") + " SZJ, " + RETSQLNAME("SB1") + " SB1 "
cQuery += "WHERE "
cQuery += "ZJ_FILIAL = '" + xFilial("SZJ") + "'" + "AND B1_FILIAL = '" + xFilial("SB1") + "'"
cQuery += "AND SZJ.D_E_L_E_T_ = ' '  AND SB1.D_E_L_E_T_ = ' ' "
cQuery += "AND ZJ_CODPRO = B1_COD "
cQuery += "AND ZJ_DOC = ' ' "
cQuery += "AND ZJ_ID BETWEEN '" + (mv_par01) + "' AND '" + (mv_par02) + "' "



If (Select("ART") <> 0)
	dbSelectArea("ART")
	dbCloseArea()
Endif
	
TCQUERY cQuery NEW Alias "ART"                  
	
dbSelectArea("ART")
dbGoTop()

oPrn 	:= TMSPrinter():New()    
nReg	:= 1

While !EOF()

	cID   	 := ART->ZJ_ID	       
	cCartao  := ART->ZJ_CARTAO
	cDesc	 := Trim(ART->B1_DESC)
	cCodpro	 := Trim(ART->ZJ_CODPRO)
	cQuant   := ART->ZJ_QUANT
	cQuantNF := ART->D1_QUANT
	cFornece := Substr(ART->A2_NOME,1,35)
	cDoc	 := Trim(ART->ZJ_DOC)      
	cVUnit   := ART->D1_VUNIT
	cEntrada := Substr(ART->ZJ_DATA,7,2)+"/"+Substr(ART->ZJ_DATA,5,2)+"/"+Substr(ART->ZJ_DATA,1,4)
	cCodBar	 := Trim(ART->ZJ_CODBAR)      
	Cobs     := Trim(ART->ZJ_OBS)
        
	//******************************************
	//  INICIALIZA IMPRESSAO
	//******************************************

	oPrn:StartPage()
	
	// Monta linhas horizontais
	// oPrn:Line(2220+nAjust1, 0050, 2220+nAjust1, 2300)

	// Insere retโngulo
    
	oPrn:Box(2220+nAjust1, 0050, 2450+nAjust1, 1750)
	oPrn:Box(2220+nAjust1, 1750, 2450+nAjust1, 2300)

	oPrn:Box(2450+nAjust1, 0050, 2700+nAjust1, 2300)
	oPrn:Box(2700+nAjust1, 0050, 3200+nAjust1, 2300)
	oPrn:Box(3200+nAjust1, 0050, 3600+nAjust1, 1200)
	oPrn:Box(3200+nAjust1, 1200, 3600+nAjust1, 2300)
	oPrn:Box(3600+nAjust1, 0050, 3750+nAjust1, 2300)

	//Pontilhado separador      
	If Npula = 0                 
		For nI := 100 to 2300 step 50
			oPrn:Line(3810+nAjust1, nI,3810+nAjust1, nI+30)
		Next nI
	EndIf
	
	// IMPRIME TEXTO

	oPrn:Say(2300+nAjust1, 0090, "ID ETIQUETA",oFont14,100)
	oPrn:SayBitmap(2150+nAjust1,2000,cBitMap,350,120)
	oPrn:Say( 2350+nAjust1, 0090, cID      ,oFont26,100)

	oPrn:Say( 2350+nAjust1, 1800, "Cartao :",oFont14,100)  
	oPrn:Say( 2350+nAjust1 ,2100 ,TRANSFORM(cCartao,"@E 999"),oFont20,100)

	oPrn:Say( 2500+nAjust1, 0090, cDesc    ,oFont26,100)
	oPrn:Say( 2600+nAjust1, 0090, cCodPro  ,oFont16,100)
	oPrn:Say( 2800+nAjust1 ,0550 ,TRANSFORM(cQuant,"@E 99,999.99"),oFont72,100)
	oPrn:Say( 3300+nAjust1, 1250, "Entrada :",oFont10,100)
	oPrn:Say( 3300+nAjust1, 1500, cEntrada ,oFont10,100)    
	oPrn:Say( 3350+nAjust1, 1250, "Fornecedor :",oFont10,100)
	oPrn:Say( 3350+nAjust1, 1500, cFornece ,oFont10,100)    
	oPrn:Say( 3400+nAjust1, 1250, "NF :",oFont10,100)       
	oPrn:Say( 3400+nAjust1, 1500, cDoc ,oFont10,100)        
	oPrn:Say( 3450+nAjust1, 1250, "Qtde NF :",oFont10,100)                        
	oPrn:Say( 3450+nAjust1 ,1500 ,TRANSFORM(cQuantNF,"@E 99,999.99"),oFont10,100)

	oPrn:Say( 3620+nAjust1, 0090, "OBS : ",oFont10,100)
	oPrn:Say( 3620+nAjust1, 0300, Substr(COBS,001,090) ,oFont10,100)    
	oPrn:Say( 3660+nAjust1, 0300, Substr(COBS,091,090) ,oFont10,100)    
	oPrn:Say( 3700+nAjust1, 0300, Substr(COBS,181,090) ,oFont10,100)    

	MSBAR3("CODE128" ,nPosBar , 0.8, cCodBar,oPrn,.F.,NIL,.T.,0.028,1.5,.T.,NIL,NIL,LPRINT)       
	
    
    Npula := Mod(nReg,2) // Registro par ou impar ?
    
	IF npula = 0 	// Par. Inicio da Folha.
		nAjust1	:= -2100	
		nPosBar	:=  10           
		oPrn:EndPage() //Finaliza Pagina
	 //	nReg 	:= 1
	Endif		

	IF npula > 0      // Impar. Imprime na parte de baixo da Folha.
		nAjust1	:= nAjust1 + 1700
		nPosBar	:= nPosBar + 14  		
	EndIf
					
    nReg := nReg + 1
	
	ART->(dbSkip()) 
EndDo

ART->(dbCloseArea())
oPrn:Preview()
SetPgEject(.F.)
MS_Flush()

RETURN()