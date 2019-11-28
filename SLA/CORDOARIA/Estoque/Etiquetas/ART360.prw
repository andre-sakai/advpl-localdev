#INCLUDE "rwmake.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ART360    º Autor ³ AP6 IDE            º Data ³  01/04/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Impressao de etiquetas para as caixas de cordas exportação.º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ MP8 IDE                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function ART360

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

nQtde    := 0
cCliente := Space(60)
cPedido  := Space(6)
cProduto := "01124          "
cHora    := "00:00:00"
cDescAnt := " "
cPedAnt  := " "
cData    := date()
cLote    := " "

Private oJanela

@ 10,015 TO 350,700 DIALOG oJanela TITLE "ARTEPLÁS - EMBALAGEM DE CORDAS/MEADAS PARA EXPORTAÇÃO"

@ 010,020 SAY OemToAnsi("Pedido")      Size 80,8
@ 020,020 GET cPedido  F3 "SC5" Valid(Pedido())     Size 50,8
@ 040,020 SAY OemToAnsi("Produto")     Size 80,8
@ 050,020 GET cProduto F3 "SB1" Valid(Produto())    Size 50,8
@ 070,020 SAY OemToAnsi("Quantidade")  Size 80,8
@ 080,020 GET nQtde    Picture("@E 9,999.99")       Size 50,8

@ 140,150 BMPBUTTON TYPE 6 ACTION Etiqueta()
@ 140,180 BMPBUTTON TYPE 2 ACTION Close(oJanela)

ACTIVATE DIALOG oJanela CENTERED

Return

Static Function Pedido()

//VERIFICA SE EXISTE O PEDIDO DE VENDA
dbSelectArea("SC5")
dbSetOrder(1)
dbGoTop()

If dbSeek(xFilial("SC5")+cPedido,.T.)
	@ 20,80 SAY cCliente Size 180,8 Color 16777215
	oJanela:Refresh()
	cCliente := Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME")
	@ 20,80 SAY cCliente Size 180,8 Color 16711680
	oJanela:Refresh()
Endif

Return(.T.)

Static Function Produto()

//VERIFICA SE EXISTE O PRODUTO E SE ELE FAZ PARTE DO PEDIDO
dbSelectArea("SB1")
dbSetOrder(1)
dbGoTop()
If !dbSeek(xFilial("SB1")+cProduto,.T.)
	MsgBox("Produto nao encontrado! Digite um codigo valido.","Atencao","STOP")
	Return(.F.)
Else
	dbSelectArea("SC6")
	dbSetOrder(2)
	dbGoTop()
	If !dbSeek(xFilial("SC6")+cProduto+cPedido,.T.)
		MsgBox("Produto nao faz parte desse pedido!","Atencao","STOP")
		Return(.F.)
	Else
		@ 50,80 SAY cDescAnt Size 180,8 Color 16777215
		oJanela:Refresh()
		@ 50,80 SAY SB1->B1_DESC Size 180,8 Color 16711680
		oJanela:Refresh()
		cDescAnt := SB1->B1_DESC
	Endif
Endif

Return(.T.)

Static Function Etiqueta()

If !Empty(cPedido)
	cCodCli := Posicione("SC5",1,xFilial("SC5")+cPedido,"C5_CLIENTE")
	cPedCli := Posicione("SC6",2,xFilial("SC6")+cProduto+cPedido,"C6_PEDCLI")
	cCodPro := Posicione("SA7",2,xFilial("SA7")+cProduto+cCodCli,"A7_CODCLI")
	cDesPro := Posicione("SA7",2,xFilial("SA7")+cProduto+cCodCli,"A7_DESCCLI")
Else
	cCodCli := ""
	cPedCli := ""
	cCodPro := ""
	cDesPro := ""
Endif            

cCodBarras := Alltrim(Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_CODBAR"))
cDesc      := Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_DESC")
cOperador  := Substr(cUsuario,7,13)

cHora  := Time()
cPorta := "LPT1"

If !Empty(cCodBarras)
	
	MSCBPRINTER("ARGOX",cPorta,,,.f.,,,,)
	MSCBCHKStatus(.f.)
	
	MSCBBEGIN(1,6)
	
	//DESENHA AS MOLDURAS - Coluna,Linha,Coluna,Linha,Espessura
	MSCBBOX(10,05,101,115,2)
	MSCBBOX(23,10,41,110,2)
	MSCBBOX(41,10,59,110,2)
	MSCBBOX(59,10,77,110,2)
	MSCBBOX(80,10,95,60,2)
	
	//DESENHA OS TEXTOS - Coluna,Linha
	MSCBSAY(15,07,"Order","B","1","1,2")
	MSCBSAY(22,14,cPedCli,"B","3","2,2")
	MSCBSAY(15,64,"Customer","B","1","1,2")
	MSCBSAY(21,75,Alltrim(cCliente),"B","3","1,2")
	
	MSCBSAY(32,52,Alltrim(cDesc),"B","2","1,2")
	MSCBSAY(40,52,Alltrim(cProduto),"B","2","1,2")
	
	MSCBSAY(49,15,cCodPro,"B","2","1,2")
	MSCBSAY(57,15,Alltrim(cDesPro),"B","2","1,2")
	
	MSCBSAY(67,12,'Units:',"B","2","1,2")
	MSCBSAY(75,30,Transform(nQtde,"@E 9,999.99"),"B","5","2,2")   
	MSCBSAY(67,62,'Pedido:',"B","2","1,2")
	MSCBSAY(75,77,cPedido,"B","5","2,2")
	
	MSCBSAY(87,12,'Lote:',"B","1","1,3")
	MSCBSAY(87,18,DTOS(dDatabase),"B","1","1,3")
	MSCBSAY(87,33,cHora,"B","1","1,3")
	
	MSCBSAY(92,12,'Operator:',"B","1","1,3")
	MSCBSAY(92,22,cOperador,"B","1","1,3")
	
	//DESENHA OS CÓDIGOS DE BARRAS
	MSCBSAYBAR(37,13,cCodBarras,"B","E",10,.F.,.F.,.T.,,,,.T.,.F.,,,)
	//MSCBSAYBAR(92,65,cBarraPeso,"B","MB07",10,.f.,.f.,.f.,,,,.t.,.f.,,,)
	//cBarraPeso = Cod. Produto + Peso Liquido = xxxxxxxxx99999
	//cBarraPeso = Cod. Produto + Peso Liquido = xxxxxxxxx99999
	
	MSCBEND()
	
Else
	
	MsgBox("Produto sem codigo de barras cadastrado!","Atencao","STOP")
	
EndIf

MSCBCLOSEPRINTER()

Return .t.
