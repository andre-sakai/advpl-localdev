#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"         
#INCLUDE "font.ch"
#INCLUDE "colors.ch"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³  IMPNFLOCA  º Autor ³JEYSON GUREK     º Data ³  20/06/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³  IMPRESSÃO DA NOTA FISCAL DE LOCAÇÃO             		  º±±
±±º          ³														      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³  Power Solutions                                           º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function ImpNFloca()
        
Local   nLin     := 1050
local 	nLin2	 := 1050
Local	cQuery	 := ""
Local 	cAlias   := getNextAlias()	
Private cPerg    := "XIMPNFLOCA"

Private lEnd     := .f.
Private oBrush   := TBrush():New(" ",255*100*100)
Private aAnexos  := {}

Private aCposFolder := {}  // Array contendo os campos amarrados com seus respectivos folders
Private nPos               // Utilizado para identificar a posição de um item dentro de um array
Private aCposNaoImp := {}  // Campos que não devem ser impressos pelo método automático
Private oPrn               // Variável objeto a ser utilizado para impressão
Private x
Private aArray
Private cConteudo
//Private cImagem := "calderaro.bmp"

AjustaSX1(cPerg)
Pergunte(cPerg,.T.)

DbSelectArea("SF2")
DbSetOrder(1) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO  
SF2->(DbGoTop())                                                                                                

If !SF2->(DbSeek(xFilial("SF2")+MV_PAR01+MV_PAR02,.T.))
	MsgAlert("Nota fiscal não encontrada") 	

else

	DbSelectArea("SD2")
	DbSetOrder(3) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM 
	SD2->(DbGoTop())                                                                                                    
	
	If !SD2->(DbSeek(xFilial("SD2")+MV_PAR01+MV_PAR02,.T.))
		MsgAlert("Nota fiscal não encontrada") 	
	else
			           
		DbSelectArea("SA1")
		DbSetOrder(1) //A1_FILIAL+A1_COD+A1_LOJA                                                                                                                                        
		SA1->(DbGoTop())                                                                                                    
		
		if !SA1->(DbSeek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA))			    
			MsgAlert("Cliente não encontrado")		    
		else	
		
			// Carreando impressão gráfica
			oPrn := TMSPrinter():New()
			oPrn:Setup()
			oPrn:EndPage()
			oPrn:StartPage()
			// Definindo os campos que não devem ser impressos automaticamente (por ter que ser impresso em área específica)
			
			ProcRegua(230)
			IncProc(OemToAnsi("Imprimindo..."))                                          
			
			// IMPRESSAO
			if MV_PAR03 == 1
				oPrn:Say(0257, 1450,"Nota: " + ALLTRIM(MV_PAR01) + " - Série: " + ALLTRIM(MV_PAR02), TFont():New("Arial",,11,,.T.), 100)
			endif
			
			oPrn:Say(0435, 1450,ALLTRIM(STR(DAY(SF2->F2_EMISSAO)))+"/"+ALLTRIM(STRZERO(MONTH(SF2->F2_EMISSAO),2))+"/"+ALLTRIM(STR(YEAR(SF2->F2_EMISSAO))), TFont():New("Arial",,11,,.F.), 100)
			oPrn:Say(0592, 0295, TRIM(SA1->A1_NOME)								,TFont():New("Arial",,11,,.F.), 100)
			oPrn:Say(0648, 0365, TRIM(SA1->A1_END)								,TFont():New("Arial",,11,,.F.), 100)
			oPrn:Say(0648, 1795, TRIM(SA1->A1_CEP)								,TFont():New("Arial",,11,,.F.), 100)
			oPrn:Say(0705, 0358, TRIM(SA1->A1_MUN)								,TFont():New("Arial",,11,,.F.), 100)
			oPrn:Say(0705, 1700, TRIM(SA1->A1_EST)								,TFont():New("Arial",,11,,.F.), 100)
			oPrn:Say(0762, 0360, Transform(SA1->A1_CGC,"@R 99.999.999/9999-99")	,TFont():New("Arial",,11,,.F.), 100)
			oPrn:Say(0762, 1200, TRIM(SA1->A1_INSCR)							,TFont():New("Arial",,11,,.F.), 100) 	
			
			// Imprimindo Imagem
			//oPrn:SayBitmap(1400, 1560, cImagem, 500, 500)
//			#ifdef ORACLE  
				cQuery := "SELECT "
				cQuery += " Trim( UTL_RAW.CAST_TO_VARCHAR2( DBMS_LOB.SUBSTR( SC5.C5_ZDESCRI,2000 ) ) ) As XMLSIGA "
//			#ELSE - TESTE COM SQL
//				cQuery := "SELECT "
//				cQuery += " ISNULL(CONVERT(VARCHAR(1024),CONVERT(VARBINARY(1024),SC5.C5_ZDESCRI)),'') AS XMLSIGA "
//			#ENDIF
				cQuery += " FROM " + retSqlName("SC5") + " SC5"
				cQuery += " where C5_NOTA = '" + MV_PAR01 +"'"
				cQuery += " and C5_SERIE = '" + MV_PAR02 +"'" 
				cQuery += " and C5_CLIENTE = '" + SA1->A1_COD +"'"
				cQuery += " and C5_LOJACLI = '" + SA1->A1_LOJA +"'"

			cQuery := changeQuery(cQuery)
			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlias,.T.,.T.)
			
			cDescri := alltrim((cAlias)->XMLSIGA)

			dbSelectArea(cAlias)
			dbCloseArea()
			//cDescri := STRTRAN(cDescri,CHR(13)+CHR(10)," ")
			//cDescri := QaDivFra(cDescri,100) 
			if !empty(cDescri)
				aDescri := JustificaTxt(cDescri,80,.T.,.F.)
			
				For nI:=1 to Len(aDescri)
					if !empty(aDescri[nI])			
						oPrn:Say(nLin2, 0175, aDescri[nI] ,TFont():New("Arial",,11,,.F.), 100)
						nLin2 := nLin2 + 50
					endif
				Next nI
            else
           			oPrn:Say(nLin, 0175, Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_DESC"),TFont():New("Arial",,11,,.F.), 100)		   
            endif
//			oPrn:Say(nLin, 0175, Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_DESC"),TFont():New("Arial",,11,,.F.), 100)		   
			oPrn:Say(nLin, 1800, 'R$ '+ALLTRIM(Transform(SD2->D2_TOTAL,"@E 999,999,999.99")),TFont():New("Arial",,11,,.F.), 100)		   
			nLin += 25
			
			oPrn:Say(2800, 1800, 'R$ '+ALLTRIM(Transform(SF2->F2_VALBRUT,"@E 999,999,999.99")), TFont():New("Arial",,11,,.F.), 100)     
			// Finalizando impressão
			oPrn:EndPage()
			// Finalizando impressão
			oPrn:Preview()
		endif			
	endif
EndIf                                                  

Return()

//----------------------------------------------------------------------------------------------------------------------------------------------------------
Static Function AjustaSX1( cPerg )                                                                                         

Local i,j
Local aAreaAtu	:= GetArea()
Local aAreaSX1	:= SX1->( GetArea() )
Local aTamSX3	:= {}
Local aRegs     := {}

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Grava as perguntas no arquivo SX1                                                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aTamSX3	:= TAMSX3( "F2_DOC" )
AADD(aRegs,{cPerg,	"01","Da Nota ?"               	,"¿Da Nota  ?"                 	,"From Number ?"        ,"mv_ch1", aTamSX3[3],aTamSx3[1],	aTamSX3[2],         0,"G" ,"","mv_par01"  ,                "",               "",            "",""         ,"",              "",                "",              "","","",         "",          "",            "","","",         "",          "",            "","","",         "",          "",            "","",   "","S",    "",          "","","" })

aTamSX3	:= TAMSX3( "F2_SERIE" )
AADD(aRegs,{cPerg,	"02","Da Serie ?"              	,"¿Da Serie ?"                	,"From Prefix ?"        ,"mv_ch2", aTamSX3[3],aTamSx3[1],	aTamSX3[2],         0,"G" ,"","mv_par02"  ,                "",               "",            "",""         ,"",              "",                "",              "","","",         "",          "",            "","","",         "",          "",            "","","",         "",          "",            "","",   "","S",    "",          "","","" })
AADD(aRegs,{cPerg,	"03","Reimpressão ?"     		,"¿Reimpressão ?"        		,"Reimpressão ?"   		,"mv_ch3",        "N",         1,         	 0,         0,"C" ,"","mv_par03"  ,"Sim"             ,"Si"             ,"Yes"         ,""         ,"","Nao"           ,"No"              ,"No"            ,"","",         "",          "",            "","","",         "",          "",            "","","",         "",          "",            "","",   "","S",    "",          "","","" }) 

DbSelectArea("SX1")                                                                                                           
SX1->(DbSetOrder(1))                                                                                                                                                                                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                                                                                                                                           
For I := 1 To Len(aRegs)
	If 	!dbSeek(cPerg+aRegs[i,2])                                                                                                                                                                  
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			IF j <= Len(aRegs[i])           
				FieldPut(j,aRegs[i,j])
			EndIf                                          
		Next
	                                                                                                                       
		MsUnLock()
	EndIf
Next

RestArea( aAreaSX1 )
RestArea( aAreaAtu )

Return()
