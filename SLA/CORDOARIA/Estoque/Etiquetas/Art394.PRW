#include "rwmake.ch"

/*
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���rdmake	 � Art396   � Autor � Eduardo Marquetti     � Data � 25.01.11 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Rotina de impressao de etiquetas codigo de Barras		  ���
���          � dos Produtos Injetados.LAYOUT NOVO. (BAUNGARTEN)            			  ���
���          � Impressora Zebra.                                          ���
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

User Function Art396()

cPerg      := "ART392"

//�������������������������������������������������������������������������Ŀ
//� Verifica as perguntas selecionadas                                      �
//���������������������������������������������������������������������������

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

//���������������������������������������������������������������������Ŀ
//� Finaliza a execucao do relatorio...                                 �
//�����������������������������������������������������������������������

SET DEVICE TO SCREEN

//���������������������������������������������������������������������Ŀ
//� Se impressao em disco, chama o gerenciador de impressao...          �
//�����������������������������������������������������������������������

SET PRINTER TO

MS_FLUSH()

Return (.t.)