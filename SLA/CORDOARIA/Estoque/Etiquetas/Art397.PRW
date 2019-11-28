#include "rwmake.ch"

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³rdmake	 ³ Art397   ³ Autor ³ Eduardo Marquetti     ³ Data ³ 10.06.11 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Rotina de impressao de etiquetas Mostruário (Peteca)    	  ³±±
±±³          ³                                                            ³±±
±±³          ³ Impressora Zebra.                                          ³±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function Art397()

	cPerg      := "ART392"

	IF !Pergunte(cPerg,.T.)
		Return
	Endif

	Processa({|| Art397() })
Return

Static Function Art397()

	DbSelectArea("SB1")
	SB1->(DBSetOrder(1))
	SB1->(DBGoTop())
	SB1->(DBSeek(xFilial("SB1")+mv_par01,.F.))

	cCodigo	:= SB1->B1_COD
	cDescricao := Alltrim(SB1->B1_DESC)
	cModelo   	:= SubStr("F8U9C",1,1)
	cPorta := "COM1:9600,N,8,1"
//	cPorta    	:= "LPT1"
	ClaProEs 	:= ''
	TpFioEs  	:= ''

	// verifica se produto está bloqueado
	If SB1->B1_MSBLQL = '1'  
		MsgAlert ("Imposivel Imprimir, o produto está bloqueado.")
		return(.F.)
	Else
		MSCBPRINTER("ALLEGRO",cPorta,,)
	//	MSCBPRINTER("S600",cPorta,,,.F.) // PARA ZEBRA
		MSCBCHKSTATUS(.F.)
		MSCBLOADGRF("SMS22.GRF")
		MSCBBEGIN(mv_par02,6) 
		//Inicio da Imagem da Etiqueta
		//------------------


		MSCBSAY(04,20,Substr(cDescricao,1,28),"N","2","35,35")
		MSCBSAY(58,20,Substr(cDescricao,1,28),"N","2","35,35")

		MSCBSAY(04,15,Substr(cDescricao,29,40),"N","2","35,35")
		MSCBSAY(58,15,Substr(cDescricao,29,40),"N","2","35,35")
		

		MSCBSAY(04,10,"Codigo: "+ cCodigo,"N","2","20,20")
		MSCBSAY(58,10,"Codigo: "+ cCodigo,"N","2","20,20")

		MSCBSAY(04,02,"www.arteplas.com.br","N","2","30,30")    	
		MSCBSAY(58,02,"www.arteplas.com.br","N","2","30,30")    	

		//------------------
		MSCBEND() //Fim da Imagem da Etiqueta
		MSCBCLOSEPRINTER()
	EndIf

	SET DEVICE TO SCREEN
	SET PRINTER TO
	MS_FLUSH()

Return (.T.)