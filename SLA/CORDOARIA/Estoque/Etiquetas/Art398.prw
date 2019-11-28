#include "rwmake.ch"


//北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
//北谀哪哪哪哪穆哪哪哪哪哪履哪哪哪履哪哪哪哪哪哪哪哪哪哪哪履哪哪穆哪哪哪哪哪勘�
//硆dmake	 � Art396   � Autor � Eduardo Marquetti     � Data � 25.01.11 潮�
//北媚哪哪哪哪呐哪哪哪哪哪聊哪哪哪聊哪哪哪哪哪哪哪哪哪哪哪聊哪哪牧哪哪哪哪哪幢�
//北矰escri噮o � Rotina de impressao de etiquetas codigo de Barras		  潮�
//北�          � dos Produtos Injetados.LAYOUT NOVO. (BAUNGARTEN)           潮�
//北�          � Impressora Zebra.                                          潮�
//北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
//哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌�


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
	MsgAlert ("Imposivel Imprimir, o produto est� bloqueado.")
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

//谀哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�
//� Finaliza a execucao do relatorio...                                 �
//滥哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�

SET DEVICE TO SCREEN

//谀哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�
//� Se impressao em disco, chama o gerenciador de impressao...          �
//滥哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�

SET PRINTER TO
MS_FLUSH()

Return (.T.)
