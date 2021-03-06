#include "rwmake.ch"

/*
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北谀哪哪哪哪穆哪哪哪哪哪履哪哪哪履哪哪哪哪哪哪哪哪哪哪哪履哪哪穆哪哪哪哪哪勘�
北硆dmake	 � Art397   � Autor � Eduardo Marquetti     � Data � 10.06.11 潮�
北媚哪哪哪哪呐哪哪哪哪哪聊哪哪哪聊哪哪哪哪哪哪哪哪哪哪哪聊哪哪牧哪哪哪哪哪幢�
北矰escri噮o � Rotina de impressao de etiquetas Mostru醨io (Peteca)    	  潮�
北�          �                                                            潮�
北�          � Impressora Zebra.                                          潮�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌�
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

	// verifica se produto est� bloqueado
	If SB1->B1_MSBLQL = '1'  
		MsgAlert ("Imposivel Imprimir, o produto est� bloqueado.")
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