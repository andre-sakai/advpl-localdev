#include "rwmake.ch"
/*
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北谀哪哪哪哪穆哪哪哪哪哪履哪哪哪履哪哪哪哪哪哪哪哪哪哪哪履哪哪穆哪哪哪哪哪勘�
北硆dmake	 � ART410   � Autor � Eduardo Marquetti     � Data � 19.09.11 潮�
北媚哪哪哪哪呐哪哪哪哪哪聊哪哪哪聊哪哪哪哪哪哪哪哪哪哪哪聊哪哪牧哪哪哪哪哪幢�
北矰escri噮o � Rotina de impressao de etiquetas codigo de Barras		  潮�
北�          � do cadastro de produtos.                 		     	  潮�
北�          � Especifico para etiquetas de Expositores     			  潮�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌�
*/


User Function ART410()  

cPerg      := "ART410"  // Nome da Pergunte

//谀哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�
//� Verifica as perguntas selecionadas                                      �
//滥哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�

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