#INCLUDE "rwmake.ch"

/*/
Programa.: ART421    
Autor....: Eduardo Marquetti
Data.....: 30/01/17
Descricao: Etiquetas Collins AMARELA
/*/

User Function ART421

// Declaracao de Variaveis                                             

nQtde    := 0
nEtiq    := 0
cLote    := SubStr(Dtos(dDataBase),5,2)+SubStr(Dtos(dDataBase),3,2)
cProduto := Space(15)
cCliente := Space(6)
cLoja    := Space(2)

cDescAnt := ' '
cNomeAnt := ' '
cUmProd  := " "

Private oJanela

aItems:= {"Argox","Datamax"}
cCombo:= aItems[2]

@ 10,015 TO 230,600 DIALOG oJanela TITLE "ETIQUETAS COLLINS"
@ 010,020 SAY OemToAnsi("Cliente")               Size 80,8
@ 020,020 GET cCliente F3 "SA1" Valid(Cliente()) Size 50,8
@ 030,020 SAY OemToAnsi("Produto")               Size 80,9
@ 040,020 GET cProduto F3 "SB1" Valid(Produto()) Size 50,9
@ 050,020 SAY OemToAnsi("Qtde Etiquetas")        Size 80,9
@ 060,020 GET nEtiq Picture("@E 9999")           Size 50,9
@ 080,020 SAY OemToAnsi("Lote")                  Size 80,9
@ 060,220 SAY OemToAnsi("Impressora")            Size 40,8
oCombo:= tComboBox():New(70,220,{|u|if(PCount()>0,cCombo:=u,cCombo)},;
   aItems,60,20,oJanela,,{||},;
   ,,,.T.,,,,,,,,,"cCombo")
@ 090,020 GET cLote                              Size 50,9
@ 090,220 BMPBUTTON TYPE 2 ACTION Close(oJanela)
@ 090,250 BMPBUTTON TYPE 6 ACTION Etiqueta()
ACTIVATE DIALOG oJanela CENTERED

Return

Static Function Produto()
*************************
	//VERIFICA SE EXISTE O PRODUTO
	dbSelectArea("SB1")
	dbSetOrder(1)
	dbGoTop()
	
	If !dbSeek(xFilial("SB1")+cProduto,.T.)
		MsgBox("Produto nao encontrado! Digite um codigo valido.","Atencao","STOP")
		Return(.F.)
	Else
		@ 40,80 SAY cDescAnt     Size 180,9 Color 16777215
		oJanela:Refresh()
		@ 40,80 SAY SB1->B1_DESC Size 180,9 Color 16711680
		oJanela:Refresh()
		cDescAnt := SB1->B1_DESC         
		cUmProd := Alltrim(SB1->B1_UM)
	Endif                    
        
	If SB1->B1_CODBAR = ' '
		MsgBox("Produto sem codigo de barras cadastrado!","Atencao","STOP")
		Return(.F.)	
	End

Return(.T.)                           


Static Function Cliente()

	//VERIFICA SE EXISTE O CLIENTE
	dbSelectArea("SA1")
	dbSetOrder(1)
	dbGoTop()
	If !Empty(cCliente)
		If !dbSeek(xFilial("SA1")+cCliente,.T.)
			MsgBox("Cliente nao encontrado! Digite um codigo valido.","Atencao","STOP")
			Return(.F.)
		Else
			@ 20,80 SAY cNomeAnt     Size 180,8 Color 16777215
			oJanela:Refresh()
			@ 20,80 SAY Alltrim(SA1->A1_NOME) Size 180,8 Color 16711680
			oJanela:Refresh()
			cNomeAnt := SA1->A1_NOME
			cLoja := SA1->A1_LOJA
		Endif             
	Endif
Return(.T.)
    

Static Function Etiqueta()
**************************
	cCodBarras := Alltrim(Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_CODBAR"))
	cDesc      := Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_DESC")
	cPorta     := "COM1:9600,N,8,1"
	
	cBitola    := Alltrim(Str(Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_BITOLA")))
	nTamanho   := Alltrim(Str(Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_METRAPR")))
	cCor 	   := Alltrim(Posicione("SZ2",1,xFilial("SZ2")+SB1->B1_COR,"Z2_DESC"))

	

	If AllTrim(cCombo) = "Datamax" // DATAMAX

		MSCBPRINTER("ALLEGRO",cPorta,,,.f.)
		MSCBCHKStatus(.f.)
		MSCBBEGIN(nEtiq,6)
	
//		dbSelectArea("SA7")
//		dbSetOrder(2)
//		dbGoTop()
//		dbSeek(xFilial("SA7")+cProduto+cCliente+cLoja,.t.)  
					             
		 cCodcli  := Alltrim(Posicione("SA7",2,xFilial("SA7")+cProduto+cCliente+cLoja,"A7_CODCLI")) 
 		 cDesccli := Alltrim(Posicione("SA7",2,xFilial("SA7")+cProduto+cCliente+cLoja,"A7_DESCCLI"))

		 If Alltrim(cUMProd) = "CR"	 // Descrição Produto Collins	 
		   cDesccli := Alltrim(Substr(SA7->A7_DESCCLI,1,18))
		 else                                                   
	       cDesccli := Alltrim(Substr(SA7->A7_DESCCLI,1,24))    
	     Endif
	 
	  	MSCBSAYBAR(28,08,cCodBarras,"N","F",10,.F.,.T.,,,5,4,.F.) // EAN 13
		MSCBSAY(02,02,'Validade Indeterminada '  ,"N","2","1,1,1")
        MSCBSAY(02,05,'Lote: '+cLote             ,"N","2","1,1,1")
		MSCBSAY(02,08,'Metragem: '+nTamanho +' m',"N","2","1,1,1") 
		MSCBSAY(02,11,'Cor: '+cCor               ,"N","2","1,1,1") 
		MSCBSAY(02,14,'Diametro: '+cBitola +' mm',"N","2","1,1,1") 
		MSCBSAY(28,25, cDesccli                  ,"N","3","1,1,1")
		MSCBSAY(02,20, cCodcli                   ,"N","3","1,1,1")
		MSCBSAY(02,25,'Codigo:'                  ,"N","2","1,1,1")
// 		MSCBSAY(02,25,'Codigo: '+cCodcli         ,"N","2","1,1,1")
		MSCBEND()
		MSCBCLOSEPRINTER()          
	Else
		***************************
		MSCBPRINTER("ARGOX","LPT1",,,.f.,,,,) //ARGOX
		MSCBCHKStatus(.f.)
		MSCBBEGIN(nEtiq,6)
		MSCBSAY(08,25,"ARTEPLAS ARTEFATOS DE PLASTICOS S/A","N","3","1,2")	
		MSCBSAY(08,20,Alltrim(cProduto)+" - "+Alltrim(cDesc),"N","2","1,2")

		If !Empty(cCliente)
			dbSelectArea("SA7")
			dbSetOrder(2)
			dbGoTop()
			dbSeek(xFilial("SA7")+cProduto+cCliente,.t.)
			MSCBSAY(08,15,Alltrim(SA7->A7_CODCLI),"N","2","1,2")
			MSCBSAY(26,15,Alltrim(SA7->A7_DESCCLI),"N","1","1,2")
		Endif

		MSCBSAY(42,06,'Lote...: '+cLote,"N","2","1,2")
		MSCBSAY(42,01,'Qtde Kg:'+Transform(nQtde,"@E 9,999.99"),"N","2","1,2")
		MSCBSAY(75,11,"Turno","B","1","1,2")
		MSCBSAY(76,11,"1[ ]","N","2","1,2")
		MSCBSAY(76,06,"2[ ]","N","2","1,2")
		MSCBSAY(76,01,"3[ ]","N","2","1,2")                       
		//DESENHA OS CÃ“DIGOS DE BARRAS
		MSCBSAYBAR(08,01,cCodBarras,"N","F",10,.F.,.F.,.T.,,,,.T.,.F.,,,)
		MSCBEND()
		MSCBCLOSEPRINTER()          
	End 
Return .T.