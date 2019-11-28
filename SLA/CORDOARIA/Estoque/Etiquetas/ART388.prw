#INCLUDE "rwmake.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �ART388    � Autor � AP6 IDE            � Data �  02/08/10   ���
�������������������������������������������������������������������������͹��
���Descricao � Impressao de etiquetas famastil impressora ARGOX (fios)    ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � MP8 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function ART388

//���������������������������������������������������������������������Ŀ
//� Declaracao de Variaveis                                             �
//�����������������������������������������������������������������������

nEtiq     := 0
cProduto  := "               "
cDescAnt  := " "
cNomeAnt  := " "
cPedAnt   := " "   
cBitola   := " "
nTamanho  := 0   
nResisten := 0

Private oJanela

@ 10,015 TO 350,700 DIALOG oJanela TITLE "ARTEPL�S - ETIQUETAS FAMASTIL"

@ 020,020 SAY OemToAnsi("Produto")               Size 80,8
@ 030,020 GET cProduto F3 "SB1" Valid(Produto()) Size 50,8
@ 060,020 SAY OemToAnsi("Qtde Etiquetas")        Size 80,8
@ 070,020 GET nEtiq    Picture("@E 9,999.99")    Size 50,8

@ 100,150 BMPBUTTON TYPE 6 ACTION Etiqueta()
@ 100,180 BMPBUTTON TYPE 2 ACTION Close(oJanela)

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
cBitola    := Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_BITOLA")
nTamanho   := Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_METRAPR")
nResisten  := Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_RESISTE")

//cPorta := "COM2:9600,N,8,1"
cPorta := "LPT1"

If !Empty(cCodBarras)
	
	MSCBPRINTER("ARGOX",cPorta,,,.f.,,,,)
	MSCBCHKStatus(.f.)
	
	MSCBBEGIN(nEtiq,6)
	
	//DESENHA OS TEXTOS - Coluna,Linha
	MSCBSAY(10,12,Alltrim(cBitola) + " mm","N","2","1,2")
	MSCBSAY(20,12,Str(nTamanho) + " metros","N","2","1,2")
	
	//DESENHA OS C�DIGOS DE BARRAS
	MSCBSAYBAR(45,12,cCodBarras,"N","E",10,.F.,.T.,.T.,,,,.T.,.F.,,,)
	
	MSCBSAY(10,22,"Resistencia:","N","2","1,2")
	MSCBSAY(30,22,Str(nResisten) + " kg","N","2","1,2")
	
	MSCBSAY(10,27,Alltrim(cDesc),"N","2","1,2")
	MSCBSAY(10,32,Alltrim(cProduto),"N","2","1,2")
	
	MSCBEND()
	
Else
	
	MsgBox("Produto sem codigo de barras cadastrado!","Atencao","STOP")
	
EndIf

MSCBCLOSEPRINTER()

Return .t.