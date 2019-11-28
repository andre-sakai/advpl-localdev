#include "rwmake.ch"


//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
//³rdmake	 ³ Art396   ³ Autor ³ Eduardo Marquetti     ³ Data ³ 25.01.11 ³±±
//±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
//±±³Descri‡…o ³ Rotina de impressao de etiquetas codigo de Barras		  ³±±
//±±³          ³ dos Produtos Injetados.LAYOUT NOVO. (BAUNGARTEN)           ³±±
//±±³          ³ Impressora Zebra.                                          ³±±
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß


User Function ART398()

cPerg      := "ART392"

IF !Pergunte(cPerg,.T.)
	Return
Endif

Processa({|| Art398() })

Return

Static Function Art398()

DbSelectArea("SB1")
SB1->(DBSetOrder(1))
SB1->(DBGoTop())
SB1->(DBSeek(xFilial("SB1")+mv_par01,.F.))

_cModelo   := SubStr("F8U9C",1,1)
_cPorta    := "LPT1"

cDescri    := SB1->B1_DESC
cCodBarra  := AllTrim(SB1->B1_CODBAR)
cExtend	   := Alltrim(B1->B1_CONV) + Alltrim(SB1->B1_UM) +' - '+ Alltrim(SB1_B1_METAPR)+ 'M' 


If SB1->B1_MSBLQL = '1'  
	MsgAlert ("Imposivel Imprimir, o produto está bloqueado.")
	return(.F.)
Else


If !Empty(_cCodBarra)
	
		MSCBPRINTER("S600",_cPorta,,,.f.)
		MSCBCHKSTATUS(.f.)
		MSCBLOADGRF("SMS22.GRF")
		MSCBBEGIN(mv_par02,6) 
		
		//Inicio da Imagem da Etiqueta
		//------------------
		MSCBSAY(10,05,cDescri,"N","0","020,020")
		MSCBSAY(10,10,cExtend,"N","0","020,020")
		MSCBSAYBAR(10,15,cCodBarra,"N","A",10,.f.,.t.,,,3,3,.f.)
		
		//------------------
		MSCBEND() //Fim da Imagem da Etiqueta

	MSCBCLOSEPRINTER()
	
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Finaliza a execucao do relatorio...                                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

SET DEVICE TO SCREEN

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Se impressao em disco, chama o gerenciador de impressao...          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

SET PRINTER TO
MS_FLUSH()

Return (.T.)
