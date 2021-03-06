#include "rwmake.ch"

/*
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北谀哪哪哪哪穆哪哪哪哪哪履哪哪哪履哪哪哪哪哪哪哪哪哪哪哪履哪哪穆哪哪哪哪哪勘�
北硆dmake	 � Art396   � Autor � Eduardo Marquetti     � Data � 25.01.11 潮�
北媚哪哪哪哪呐哪哪哪哪哪聊哪哪哪聊哪哪哪哪哪哪哪哪哪哪哪聊哪哪牧哪哪哪哪哪幢�
北矰escri噮o � Rotina de impressao de etiquetas codigo de Barras		  潮�
北�          � dos Produtos Injetados.LAYOUT NOVO. (BAUNGARTEN)            			  潮�
北�          � Impressora Zebra.                                          潮�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌�
*/

User Function Art396()

cPerg      := "ART392"

//谀哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�
//� Verifica as perguntas selecionadas                                      �
//滥哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�

IF !Pergunte(cPerg,.T.)
	Return
Endif

Processa({|| Art396() })

Return

Static Function Art396()

DbSelectArea("SB1")
SB1->(DBSetOrder(1))
SB1->(DBGoTop())
SB1->(DBSeek(xFilial("SB1")+mv_par01,.F.))

_cDescricao := SB1->B1_DESC
_Lote      := SubStr(Dtos(dDataBase),5,2)+SubStr(Dtos(dDataBase),1,4)
_Titulo    := SB1->B1_TITULO
_cModelo   := SubStr("F8U9C",1,1)
_cPorta    := "LPT1"
_cCodBarra := AllTrim(SB1->B1_CODBAR)
cCodigoDP  := SB1->B1_TIPC
_ClaProEs := ''
_TpFioEs  := ''


If !Empty(_cCodBarra)
	
		MSCBPRINTER("S600",_cPorta,,,.f.)
		MSCBCHKSTATUS(.f.)
		MSCBLOADGRF("SMS22.GRF")
		MSCBBEGIN(mv_par02,6) 
		
		//Inicio da Imagem da Etiqueta
		//------------------
		MSCBSAY(35,04,"Desc.:","N","0","024,020")
		MSCBSAY(45,04,SB1->B1_DESC,"N","0","020,020")
		MSCBSAYBAR(45,10,_cCodBarra,"N","E",10,.f.,.t.,,,3,3,.f.)
		MSCBSAY(45,26,"MP: PP","N","0","020,020")
		MSCBSAY(69,26,"Lote: "+_Lote,"N","0","020,020")
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

Return (.t.)
