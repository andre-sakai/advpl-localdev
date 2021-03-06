#include "rwmake.ch"
/*
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北谀哪哪哪哪穆哪哪哪哪哪履哪哪哪履哪哪哪哪哪哪哪哪哪哪哪履哪哪穆哪哪哪哪哪勘�
北硆dmake	 � ART409   � Autor � Eduardo Marquetti     � Data � 14.09.11 潮�
北媚哪哪哪哪呐哪哪哪哪哪聊哪哪哪聊哪哪哪哪哪哪哪哪哪哪哪聊哪哪牧哪哪哪哪哪幢�
北矰escri噮o � Rotina de impressao de etiquetas codigo de Barras		  潮�
北�          � do cadastro de produtos.                 		     	  潮�
北�          � Especifico para etiquetas de Cordas Martins     			  潮�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌�
*/


User Function ART409()  

cPerg      := "ART409"  // Nome da Pergunte

//谀哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�
//� Verifica as perguntas selecionadas                                      �
//滥哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�

IF !Pergunte(cPerg,.T.)               // Pergunta no SX1
	Return
End
      
cProduto := MV_PAR01
nCopias  := MV_PAR02
cUMEmb	 := MV_PAR03
nQtdEmb	 := Alltrim(Str(MV_PAR04))
cUMProd  := MV_PAR05


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


		DbSelectArea("SB5") // 
		DbSetOrder(1)
		DbSeek(xFilial("SB5")+cProduto)
		cEmbal := Alltrim(B5_EMB1)
		cEmbCod  := Substring(cEmbal,1,1)+" "+Substring(cEmbal,2,2)+" "+Substring(cEmbal,4,5)+" "+Substring(cEmbal,9,5)+" "+Substring(cEmbal,14,1)
				
		DbSelectArea("SAH") // Unidade de medida
		DbSetOrder(1)
		DbSeek(xFilial("SAH")+cUMProd)
		cUMPodX := Alltrim(AH_DESCPO)
		DbCloseArea("SAH")
	
		nCopia	 := 1 
		
		While nCopia <= nCopias
			IncProc("Imprimindo Etiquetas...")
			MSCBPRINTER("ALLEGRO",_cPorta,,)
			MSCBCHKSTATUS(.F.)       
			MSCBBEGIN()
			MSCBSAY   (20,28,cDesc,"N","2","1,2")  
			MSCBSAY   (20,22,cUMEmb +" c/ "+nQtdEmb+" "+cUMPodX,"N","2","1,2")                                        
			MSCBSAYBAR(20,07,Substring(cEmbal,1,13),"N","L",12,.F.,.F.,,,9,4,.F.) // L - Interleaved 2 of 5 Modulo 10
			MSCBSAY   (21,02,cEmbCod,"N","2","2,2")  
			MSCBEND()
			MSCBCLOSEPRINTER()
			nCopia := nCopia + 1		
		End	
	End
End

Return