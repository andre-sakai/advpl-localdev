#include "rwmake.ch"
/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³rdmake	 ³ ART409   ³ Autor ³ Eduardo Marquetti     ³ Data ³ 14.09.11 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Rotina de impressao de etiquetas codigo de Barras		  ³±±
±±³          ³ do cadastro de produtos.                 		     	  ³±±
±±³          ³ Especifico para etiquetas de Cordas Martins     			  ³±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/


User Function ART409()  

cPerg      := "ART409"  // Nome da Pergunte

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica as perguntas selecionadas                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

IF !Pergunte(cPerg,.T.)               // Pergunta no SX1
	Return
End
      
cProduto := MV_PAR01
nCopias  := MV_PAR02
cUMEmb	 := MV_PAR03
nQtdEmb	 := Alltrim(Str(MV_PAR04))
cUMProd  := MV_PAR05


Processa({|| _Eti() })

Static Function _Eti()
**********************

_cPorta  := 'LPT1'
_cModelo := "F"


If !empty(cProduto)
	DbSelectArea("SB1")
	DbSetOrder(1)
	If DbSeek(xFilial("SB1")+cProduto)
		cProduto := Alltrim(B1_COD)
		cDesc	 := Alltrim(B1_DESC)
		cCodbar  := Alltrim(B1_CODBAR) 


		DbSelectArea("SB5") // 
		DbSetOrder(1)
		DbSeek(xFilial("SB5")+cProduto)
		cEmbal := Alltrim(B5_EMB1)
		cEmbCod  := Substring(cEmbal,1,1)+" "+Substring(cEmbal,2,2)+" "+Substring(cEmbal,4,5)+" "+Substring(cEmbal,9,5)+" "+Substring(cEmbal,14,1)
				
		DbSelectArea("SAH") // Unidade de medida
		DbSetOrder(1)
		DbSeek(xFilial("SAH")+cUMProd)
		cUMPodX := Alltrim(AH_DESCPO)
		DbCloseArea("SAH")
	
		nCopia	 := 1 
		
		While nCopia <= nCopias
			IncProc("Imprimindo Etiquetas...")
			MSCBPRINTER("ALLEGRO",_cPorta,,)
			MSCBCHKSTATUS(.F.)       
			MSCBBEGIN()
			MSCBSAY   (20,28,cDesc,"N","2","1,2")  
			MSCBSAY   (20,22,cUMEmb +" c/ "+nQtdEmb+" "+cUMPodX,"N","2","1,2")                                        
			MSCBSAYBAR(20,07,Substring(cEmbal,1,13),"N","L",12,.F.,.F.,,,9,4,.F.) // L - Interleaved 2 of 5 Modulo 10
			MSCBSAY   (21,02,cEmbCod,"N","2","2,2")  
			MSCBEND()
			MSCBCLOSEPRINTER()
			nCopia := nCopia + 1		
		End	
	End
End

Return