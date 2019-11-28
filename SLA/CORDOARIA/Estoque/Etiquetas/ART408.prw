#include "rwmake.ch"
/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³rdmake	 ³ ART408   ³ Autor ³ Eduardo Marquetti     ³ Data ³ 05.09.11 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Rotina de impressao de etiquetas codigo de Barras		  ³±±
±±³          ³ do cadastro de produtos.                 		     	  ³±±
±±³          ³ Especifico para etiquetas de Produtos.          			  ³±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/


User Function ART408()  

cPerg      := "ART408"  // Nome da Pergunte

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica as perguntas selecionadas                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

IF !Pergunte(cPerg,.T.)               // Pergunta no SX1
	Return
End
      
cProduto := MV_PAR01
nCopias  := MV_PAR02

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
		nCopia	 := 1
		
		While nCopia <= nCopias
			IncProc("Imprimindo Etiquetas...")
			MSCBPRINTER("ALLEGRO",_cPorta,,)
			MSCBCHKSTATUS(.F.)       
			MSCBBEGIN()
			MSCBSAY   (05,50,"Codigo:","N","9","2,1") 
			
			MSCBSAY   (05,40,cProduto,"N","9","3,3")
			MSCBSAYBAR(50,37,cCodBar,"N","E",13,.F.,.T.,,,3,3,.T.)
			MSCBSAY   (05,32,"Produto:","N","9","2,1")
			MSCBSAY   (60,32,"Validade Indeterminada","N","9","1,1") 
			MSCBSAY   (05,25,cDesc,"N","9","2,3")  
			MSCBEND()
			MSCBCLOSEPRINTER()
	  		nCopia := nCopia + 1		
		End
	 End
End
Return