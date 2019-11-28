#include "rwmake.ch"
/*
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���rdmake	 � ART410   � Autor � Eduardo Marquetti     � Data � 19.09.11 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Rotina de impressao de etiquetas codigo de Barras		  ���
���          � do cadastro de produtos.                 		     	  ���
���          � Especifico para etiquetas de Expositores     			  ���
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/


User Function ART410()  

cPerg      := "ART410"  // Nome da Pergunte

//�������������������������������������������������������������������������Ŀ
//� Verifica as perguntas selecionadas                                      �
//���������������������������������������������������������������������������

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
			MSCBSAY   (10,28,cDesc,"N","9","2,2")  
			MSCBSAYBAR(20,07,Substring(cCodBar,1,13),"N","F",10,.F.,.T.,,,5,4,.F.) 
			MSCBEND()
			MSCBCLOSEPRINTER()
			nCopia := nCopia + 1		
		End	
	End
End

Return