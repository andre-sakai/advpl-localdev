#Include "Protheus.ch"       
#Include "Rwmake.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ ART428   บAutor  ณEduardo Marquetti  บ Data ณ  23/04/18   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Consumo Materia Prima Codigo de Barras                     บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP5                                                        บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function ART428()
**********************

DEFINE FONT oFnt  NAME "Arial" SIZE 16,16 //BOLD
DEFINE FONT oFnt1 NAME "Arial" SIZE 14,14 BOLD
DEFINE FONT oFnt2 NAME "Arial" SIZE 12,12 BOLD
DEFINE FONT oFnt3 NAME "Arial" SIZE 16,16 BOLD
DEFINE FONT oFnt4 NAME "Arial" SIZE 26,26 BOLD

CriaArqT()

private cCodBar     := Space(35)
private cProtudo    := Space(09)
private cAuxProd    := Space(13)
private	nSaldo      := 0
private cCodProduto := Space(09)

private cProd      := Space(09)
private cItem      := Space(2)
private cSequen    := Space(3)      
private cQuant     := SPACE(20)
private cItens     := SPACE(4)
private cDescr     := SPACE(35)
private cAuxQuant  := Space(20)    
private cUM		   := Space(2)    
private cTipoProd  := Space(2)
private cNumOrdens := Space(30)
private nAuxQuant  := 0 
private nQuant     := 0 
private nseq       := 0
private nPosProduto := 0
private nPosQuant  := 0
private cRecurso := Space(6)
private lReemb     := .F.
private lGetQuant  := .F.

Sele TRB
DbGoTop()
lOk:= .t.
aBRW := {}
AADD(aBRW,{"ITENS" 	  ,"Etiquetas"  })
AADD(aBRW,{"PRODUTO"  ,"Produto"    })
AADD(aBRW,{"DESCR"    ,"Descri็ใo"  })
AADD(aBRW,{"QUANTID"  ,"Quantidade" })
AADD(aBRW,{"UM"       ,"UM"		    })    
AADD(aBRW,{"CODBAR"   ,"CODBAR"	    })    
AADD(aBRW,{"RECURSO"  ,"Recurso"    })    

lAtivo	  :=.T.
lFixaMain :=.F.
lFixaRec  :=.F.
lFixaTurno:=.F.

***********************

DEFINE MSDIALOG oDlgPrinc TITLE OemToAnsi("CONSUMO MP e PI - por Etiquetas") FROM 01,01 TO 510,900 PIXEL

@ 04,030 MSGET oProduto var cCodBar Valid ValProd() size 090,010 PIXEL
// @ 04,150 GET oQuant var nQuant Valid ValQtd() PICTURE "@e 999,999.99" size 050,010 PIXEL  When lGetQuant = .T.
@ 05,380 SAY "Lidas: " SIZE 020,010 COLOR CLR_BLUE PIXEL
@ 04,410 SAY nSeq          SIZE 030,020 COLOR CLR_BLACK FONT oFnt4 PIXEL
@ 05,005 SAY oSayProd var "Leitura: " SIZE 020,010 COLOR CLR_BLUE PIXEL
@ 30,005 SAY cDescr    SIZE 380,030 COLOR CLR_BLACK FONT     oFnt4 PIXEL
@ 45,250 SAY TRANSFORM(nAuxQuant,"@E 99,999.99") SIZE 120,050 COLOR CLR_GREEN FONT     oFnt4 PIXEL
@ 47,420 SAY cUM       SIZE 030,020 COLOR CLR_BLACK FONT     oFnt3 PIXEL
@ 55,005 SAY cAuxProd  SIZE 200,030 COLOR CLR_BLUE FONT      oFnt2 PIXEL
@ 65,005 TO 230,450 BROWSE "TRB" OBJECT oBrw  fields aBRW
 obrw:oBrowse:bGotFocus := {|| oProduto:SetFocus()}
@ 235,030 SAY cRecurso  SIZE 100,30  COLOR CLR_RED FONT oFnt PIXEL
@ 240,320 BMPBUTTON TYPE 3 ACTION Excluir()	 Object oBtnEx
oBtnRecurs :=tButton():New(240,240,"Recurso",oDlgPrinc,{||SelRecurso()},25,11,,,,.T.)
oBtnSair:=tButton():New(240,390,"Sair",oDlgPrinc,{||Sair()},25,11,,,,.T.)
@ 240,420 BMPBUTTON TYPE 1 ACTION GrvApont() Object oBtnOk

oProduto:Refresh()
oProduto:SetFocus()

If nSeq <= 0
	oBtnOk:disable()
	oBtnEx:disable()  
	oProduto:SetFocus()
EndIf

ACTIVATE MSDIALOG oDlgPrinc CENTERED valid lFixaMain
Return

 Static Function SelRecurso()
****************************
	DEFINE MSDIALOG oDlgRecurso TITLE OemToAnsi("Selecione Recurso") FROM 01,01 TO 100,200 PIXEL
	@ 04,50 GET  cRecurso F3 "SH1_CB"   size 030,010
	@ 30,60 BMPBUTTON TYPE 1 ACTION GrvRecurso() Object oBtnOkRec
	ACTIVATE MSDIALOG oDlgRecurso CENTERED valid lFixaRec
	lFixaRec:=.t.
	lEnd:=.f.
	nOps:=1                  
Return

Static Function GrvRecurso()
****************************
	DbSelectArea("SH1")
	DbSetOrder(1)         
	If DbSeek(xFilial("SH1")+cRecurso)
	   cDescRec := SH1->H1_DESCRI
    Else
   		MsgBox("Recurso Inexistente")
   		Return .F.
   	End
	lFixaRec:=.t.
	Close(oDlgRecurso)
	lEnd:=.f.
	nOps:=1
Return


Static Function ValProd()
*************************

If !empty(cCodBar) .and. Length(Alltrim(cCodBar)) >= 9
	DbSelectArea("SB1")
	DbSetOrder(1)
	dbGoTop()  
	nPosProduto := AT("P",cCodbar) +1
	nPosquant   := AT("Q",cCodbar) +1
	cProduto := Alltrim(Substring(cCodbar,nPosProduto,9))
	nQuant   := Val(STRTRAN(Alltrim(Substring(cCodbar,nPosQuant,9)), ',', '.'))

	
	dbSeek(xFilial("SB1")+cProduto,.T.)
	cAuxProd    := cProduto
	cCodProduto := SB1->B1_COD     
	cTipoProd   := SB1->B1_TIPO
	cDescr   	:= AllTrim(SB1->B1_DESC)

	If cTipoProd = "PI" .and. cRecurso = ' ' // ษ PI, Tem de Selecionar RECURSO
	MsgBox("Este item ้ (PI). Selecione primeiramente o Recurso.")
	cProduto = Space(15)		
	Return .F.
	End                                      


	If !DbSeek(xFilial("SB1")+cProduto) // VERIFICA SE ESTA CADASTRADO
		MsgBox("Produto " +Alltrim(cProduto)+ " nao Cadastrado: ")
		cAuxProd :=cCodProduto
		cProduto = Space(15)		
		oProduto:Refresh()
		oProduto:SetFocus()
		Return .F.   
	Endif
   
/*
	If cTipoProd  <> "MP"  // Verifica se ้ Materia Prima (MP) ou Produto Intermediario (PI).
    	MsgBox("Produto " +Alltrim(cCodProduto)+ " - " + AllTrim(cDescr) + "  Nao e MP/PI - Materia Prima")
   		cAuxProd :=cCodProduto
		cProduto := Space(09)		
		oProduto:Refresh()
		oProduto:SetFocus()
		Return .F.       
   	End
*/    



	DbSelectArea("SB2") // VERIFICA SE O PRODUTO TEM ESTOQUE NEGATIVO
	DbSetOrder(1)         
	DbSeek(xFilial("SB2")+cCodProduto)
	nSaldo := B2_QATU  
	
    If nSaldo < 0
    	MsgBox("Produto " +Alltrim(cCodProduto)+ " - " + AllTrim(cDescr) + "  tem SALDO NEGATIVO! Comunique o PCP")
   		cAuxProd :=cCodProduto
		cProduto = Space(09)		
		oProduto:Refresh()
		oProduto:SetFocus()
		Return .F.       
   	End

    
    If SB1->B1_ATIVOAT = 'N' // VERIFICA SE O PRODUTO ESTA ATIVO
		MsgBox("Este Produto estแ INATIVO! Verifique")
		cAuxProd :=cProduto
		cProduto = Space(15)		
		oProduto:Refresh()
		oProduto:SetFocus()
		Return .F.
	Endif 

    cDescr    	 := Alltrim(SB1->B1_DESC)  
    cUM		  	 := Alltrim(SB1->B1_UM)  
	cAuxQuant 	 := Alltrim(Substring(cCodbar,nPosQuant,9))
	nAuxQuant 	 := val(cAuxQuant)      	 
	
	lGetQuant := .F.
// 	Valqtd()
	
	Process()
End
Return .T.


Static Function ValQtd()
*************************
If !empty(cCodProduto) .and. Length(Alltrim(cCodProduto)) = 9	 
	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial('SB1')+cCodProduto)
	
	cAuxProd    := cProduto
	cCodProduto := SB1->B1_COD
   
    If nQuant = 0   // Inicial do C๓digo de Barras
		MsgBox("FORA DE PESO - Digite a quantidade")
		oQuant:SetFocus()
		Return .F.
    Else
		cAuxQuant := nQuant
    	lGetQuant := .F.
    	Process()
    End
End    
Return
	

Static Function Process()
*************************

// **** Verifica se a Etiqueta jแ foi apontada no Arquivo TRB.  

	Sele TRB  
	DbGoTop()
	While !eof()
		If TRB->CODBAR	= cCodbar
			MsgBox("ESTA ETIQUETA JA FOI APONTADA ANTERIORMENTE")
			oBtnOk:Enable()
			oBtnOk:refresh()   
			oBtnEx:Enable()  
			oBrw:oBrowse:Refresh()
			obrw:oBrowse:bGotFocus := {|| oProduto:SetFocus()}
			cProduto 	:= Space(09)         
			cCodbar  	:= Space(35)           
		    cRecurso    := Space(6)           
			cAuxCodBar  := Space(35)
			nQuant  	:= 0    
		Sele TRB
		Return    
		Endif 
    	DbSkip()  
	End
               
// **** Verifica se Etiqueta estแ contida no Arquivo SD3.

	DbSelectArea("SD3")
	dbOrderNickname("D3ETIQ") // Indice Exclusivo para a Rotina.
	dbGoTop()  
	dbSeek(xFilial("SD3")+cCodbar,.T.)

	If DbSeek(xFilial("SD3")+cCodbar) 
		MsgBox("ETIQUETA " +Alltrim(cCodbar)+ " JA FOI APONTADA! ")
			oBtnOk:Enable()
			oBtnOk:refresh()   
			oBtnEx:Enable()  
			oBrw:oBrowse:Refresh()
			obrw:oBrowse:bGotFocus := {|| oProduto:SetFocus()}
			cProduto 	:= Space(09)         
			cCodbar  	:= Space(35)           
			cAuxCodBar  := Space(35)
			nQuant  	:= 0    
			Return .F.   
	Endif

	lReemb:=.T.
	nSeq++	
	
	Sele TRB
	DbGoTop()

	dbSelectarea("TRB")
	If DbSeek(cProduto+cCodProduto+cRecurso)                     
//	If DbSeek(cProduto+cRecurso) 
		RecLock("TRB",.F.)
	else
		RecLock("TRB",.T.)
	Endif	                   

  	TRB->Itens      := TRB->Itens + 1
	TRB->Produto    := cCodProduto
	TRB->Quantid    := (TRB->Quantid + nQuant) 	
	TRB->Descr	    := SB1->B1_DESC
	TRB->Um		    := SB1->B1_UM
	TRB->UMSEGUM    := SB1->B1_SEGUM
	TRB->CODBAR		:= cCodbar    
 	TRB->Recurso    := cRecurso
	MsUnlock("TRB")
	
	Sele TRB
	DbGoTop()
	
	oBtnOk:Enable()
	oBtnOk:refresh()   
	oBtnEx:Enable()  

oBrw:oBrowse:Refresh()
obrw:oBrowse:bGotFocus := {|| oProduto:SetFocus()}

cProduto 	:= Space(09)         
cCodbar  	:= Space(35)           
cAuxCodBar  := Space(35)
nQuant   := 0    

Return                                  


Static Function _MATA240()
**************************
Local aRot240 := {}
Local nOpc     := 3 // inclusao
Private lMsHelpAuto := .T. 
Private lMsErroAuto := .F. 

Sele TRB
DbSetOrder(1)

nQtApont  := 0
nQtApont1 := 0
nQtApont2 := 0
nConta 	  := 0
nTempo    := 0                
cTpApont := "T"

// cNumDoc:=GetSx8Num("SD3") // Numera็ใo Automatica

// Outro M้todo para usar Numera็ใo SD3 sem o GetSX8Num
cNumDoc := " "
cAliasOld:=Alias()
dbSelectArea("SD3")
dbSetOrder(2)
cNumDoc := NextNumero("SD3",2,"D3_DOC",.T.)
cNumDoc := A261RetINV(cNumDoc)
// Fim



nConta++

	Sele SB1
	DbSetOrder(5)
	DbSeek(xFilial("SB1")+TRB->Produto)
	Begin Transaction     
	
 	aRot240 := {{"D3_FILIAL" ,xFilial("SD3"),Nil},;
 	{"D3_TM"		,"501"  				,Nil},;
	{"D3_COD"		,TRB->Produto 			,Nil},;
	{"D3_DESCR"		,TRB->DESCR    			,Nil},;
	{"D3_QUANT"		,TRB->QUANTID			,Nil},;
	{"D3_UM"		,TRB->UM       			,Nil},;    
	{"D3_LOCAL"  	,SB1->B1_LOCPAD  		,NIL},;
	{"D3_DOC"		,cNumDoc				,Nil},;	 
	{"D3_PARCTOT"	,"T"					,Nil},;
	{"D3_CONTA"  	,"41202001"				,Nil},;
	{"D3_ETIQ"  	,TRB->CODBAR			,Nil},;
 	{"D3_RECURSO"	,TRB->RECURSO			,Nil},; 
	{"D3_EMISSAO"	,dDatabase				,Nil}}

	MSExecAuto({|x,y| mata240(x,y)},aRot240,3)
	If lMsErroAuto
		DisarmTransaction()
		break
	EndIf
	ConfirmSX8()
	End Transaction
	If lMsErroAuto
		Mostraerro()
		Return .F.
	EndIf
Return .T.


Static Function GrvATirar()
**************************

	DbSelectArea("SB1")
	DbSetOrder(5) 
	DbSeek(xFilial("SB1")+TRB->Produto)
                        
	dbSelectarea("TRB")

	If  nQuant - TRB->Quantid = 0
		MsgBox("Utilize o Botใo Exluir para Zerar as Quantidades para Este Item.")
	Else
	    If nQuant >  TRB->Quantid 
			MsgBox("Quantidade Informada ้ maior que Registrada.")
	    Else
			If nQuant < TRB->Quantid 
				RecLock("TRB",.F.)             
				TRB->Quantid := (TRB->Quantid - nQuant) 
				TRB->Itens := TRB->Itens -1
				nSeq:= nseq -1
				MsUnlock("TRB")      
			End
		End
	End


	oBtnOk2:ENABLE()
	oBtnOk2:refresh()
	oBrw:oBrowse:Refresh()
	
	cProduto:= Space(20)
    cCodBar := Space(35)
	cQuant	:= Space(8)
	nQuant  := 0
	
	lFixaMain2:=.t.
	Close(oDlg2)
	lEnd:=.f.
	nOps:=1
	
Return                                  

Static Function GrvApont()
**************************
Sele TRB
DbGoTop()
While !eof()
	_MATA240()
	Sele TRB
	DbSkip()
End


Sele TRB
DbCloseArea("TRB")
CriaArqT()

// Limpa as Variแveis da Tela

cProduto  := Space(09)
cDescr    := SPACE(35)
cRecurso  := Space (6)
cDescRec  := Space (35)
cOperador := Space(3)
cDescOp   := Space(40)  
nSeq      := 0

cAuxQuant := Space(1)
cUM       := Space(1)
cAuxProd  := Space(1)
nQuant	  := 0



If nSeq <= 0
	oBtnOk:disable()
//	oBtnEx:disable()
EndIf
oBtnOk:Refresh()
//oBtnEx:Refresh()
oBrw:oBrowse:Refresh()
oProduto:SetFocus()

Return                 



Static Function Sair()
**********************

If MsgBox("Confirma Saida ? ","Escolha","YESNO")

	lFixaMain:=.t.
	Close(oDlgPrinc)
	lEnd:=.f.
	nOps:=1
else
	lEnd:=.f.
	nOps:= 2
	oProduto:SetFocus()    
endif
Return

Static Function Excluir()
*************************

Sele TRB
if !EMPTY(TRB->PRODUTO)
	If MsgBox("Confirma exclusao deste registro ?","Escolha","YESNO")
		Sele TRB
		nQuant := nQuant - TRB->Quantid
		RecLock("TRB",.f.)
		DbDelete()
		MsunLock("TRB")
		nSeq:=nSeq - Itens
	endif
endif

IF nSeq <= 0
	oBtnOk:Disable()  
	oBtnRecurs:Enable()  
else
	oBtnOk:ENABLE()
ENDIF

oBtnOk:Refresh()



Sele TRB
DbGoTop()
cProduto:=Space(15)
cLeDados:=Space(12)

oBrw:oBrowse:Refresh()
oProduto:SetFocus()
return

Static Function CriaArqT()
**************************

aStru:={}
Aadd(aStru,{ "OK         ", "C", 02, 0 } )
Aadd(aStru,{ "ITENS      ", "N", 4, 0  } )
Aadd(aStru,{ "PRODUTO    ", "C", 15, 0 } )
Aadd(aStru,{ "DESCR      ", "C", 35, 0 } )
Aadd(aStru,{ "QUANTID    ", "N", 12, 2 } )
Aadd(aStru,{ "UM         ", "C", 02, 0 } )
Aadd(aStru,{ "QUANTID2UM ", "N", 12, 2 } )
Aadd(aStru,{ "RECURSO    ", "C", 06, 0 } )
Aadd(aStru,{ "UMSEGUM    ", "C", 02, 0 } )
Aadd(aStru,{ "CODBAR     ", "C", 35, 0 } )

If ( Select ( "TRB" ) <> 0 )
	dbSelectArea ( "TRB" )
	dbCloseArea()
End

cArq := CriaTrab(aStru,.T.)
dbUseArea ( .T.,, cArq, "TRB",.F.,.F. )
_cChave := "PRODUTO+RECURSO"
//_cChave := "PRODUTO+PRODUTO"
IndRegua("TRB", cArq,_cChave,,,"Selecionando registros...")

Return