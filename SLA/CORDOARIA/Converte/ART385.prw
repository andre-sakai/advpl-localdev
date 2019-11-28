#INCLUDE "rwmake.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ART385    º Autor ³ AP6 IDE            º Data ³  09/06/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Impressao de etiquetas amarelas impressora ARGOX (fios)    º±±
±±º          ³ Meadas de exportação para mercado nacional                 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³  			                                              º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function ART385

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ              

nEtiq     := 0
cProduto  := "011240001      "
cDescAnt  := " "
cNomeAnt  := " "
cPedAnt   := " "   
nBitola   := 0
nTamanho  := 0   
nResisten := 0                                                                      


aItems:= {"LPT1","COM1"}
cCombo:= aItems[2]


Private oJanela

@ 10,015 TO 350,700 DIALOG oJanela TITLE "ARTEPLÁS - MEADAS DE EXPORTAÇÃO"

@ 020,020 SAY OemToAnsi("Produto")               Size 80,8
@ 030,020 GET cProduto F3 "SB1" Valid(Produto()) Size 50,8
@ 060,020 SAY OemToAnsi("Qtde Etiquetas")        Size 80,8
@ 070,020 GET nEtiq    Picture("@E 9,999.99")    Size 50,8
@ 100,020 SAY OemToAnsi("Porta")               Size 80,8
oCombo:= tComboBox():New(110,020,{|u|if(PCount()>0,cCombo:=u,cCombo)}, aItems,100,20,oJanela,,{||},,,,.T.,,,,,,,,,"cCombo")

@ 130,150 BMPBUTTON TYPE 6 ACTION Etiqueta()
@ 130,180 BMPBUTTON TYPE 2 ACTION Close(oJanela)

ACTIVATE DIALOG oJanela CENTERED

Return

Static Function Produto()

//VERIFICA SE EXISTE O PRODUTO
dbSelectArea("SB1")
dbSetOrder(1)
dbGoTop()
If !dbSeek(xFilial("SB1")+cProduto,.T.)
	MsgBox("Produto nao encontrado! Digite um codigo valido.","Atencao","STOP")
	Return(.F.)
Else
	@ 80,80 SAY cDescAnt     Size 180,8 Color 16777215
	oJanela:Refresh()
	@ 80,80 SAY SB1->B1_DESC Size 180,8 Color 16711680
	oJanela:Refresh()
	cDescAnt := SB1->B1_DESC
Endif

Return(.T.)

Static Function Etiqueta()

cCodBarras := Alltrim(Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_CODBAR"))
cDesc      := Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_DESC")
nBitola    := Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_BITOLA")
nTamanho   := Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_METRAPR")
nResisten  := Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_RESISTE")


If AllTrim(cCombo) = "LPT1" // LPT1
	cPorta := "LPT1"
Else
	cPorta := "COM1:9600,N,8,1"  // COM1
EndIf

If !Empty(cCodBarras)
	
	MSCBPRINTER("ARGOX",cPorta,,,.f.,,,,)
	MSCBCHKStatus(.f.)
	
	MSCBBEGIN(nEtiq,6)
	
	//DESENHA OS TEXTOS - Coluna,Linha
	MSCBSAY(05,08,STR(nBitola) + "mm","N","2","1,2")
	MSCBSAY(15,08,STR(nTamanho) + " metros","N","2","1,2")
	MSCBSAY(05,02,"Validade Indeterminada","N","2","1,1")
	
	
	//DESENHA O CÓDIGO DE BARRA
	MSCBSAYBAR(40,01,cCodBarras,"N","F",10,.F.,.T.,,,5,3,.F.) // EAN 13
	MSCBSAY(05,15,"Resistencia:","N","2","1,2")
	MSCBSAY(25,15,Str(nResisten) + " kg","N","2","1,2")
	MSCBSAY(05,20,Alltrim(cDesc),"N","2","1,2")
	MSCBSAY(05,25,Alltrim(cProduto),"N","2","1,2")

//	MSCBSAYBAR(40,01,cCodBarras,"N","F",10,.F.,.T.,,,5,3,.F.) // EAN 13
//	MSCBSAY(10,10,"Resistencia:","N","2","1,2")
//	MSCBSAY(30,10,Str(nResisten) + " kg","N","2","1,2")
//	MSCBSAY(10,15,Alltrim(cDesc),"N","2","1,2")
//	MSCBSAY(10,20,Alltrim(cProduto),"N","2","1,2")

	
	MSCBEND()
	
Else
	
	MsgBox("Produto sem codigo de barras cadastrado!","Atencao","STOP")
	
EndIf

MSCBCLOSEPRINTER()

Return .T.