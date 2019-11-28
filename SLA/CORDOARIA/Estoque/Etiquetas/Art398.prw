#include "rwmake.ch"


//�����������������������������������������������������������������������������
//�������������������������������������������������������������������������Ŀ��
//�rdmake	 � Art396   � Autor � Eduardo Marquetti     � Data � 25.01.11 ���
//�������������������������������������������������������������������������Ĵ��
//���Descri��o � Rotina de impressao de etiquetas codigo de Barras		  ���
//���          � dos Produtos Injetados.LAYOUT NOVO. (BAUNGARTEN)           ���
//���          � Impressora Zebra.                                          ���
//�����������������������������������������������������������������������������
//�����������������������������������������������������������������������������


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

//���������������������������������������������������������������������Ŀ
//� Finaliza a execucao do relatorio...                                 �
//�����������������������������������������������������������������������

SET DEVICE TO SCREEN

//���������������������������������������������������������������������Ŀ
//� Se impressao em disco, chama o gerenciador de impressao...          �
//�����������������������������������������������������������������������

SET PRINTER TO
MS_FLUSH()

Return (.T.)
