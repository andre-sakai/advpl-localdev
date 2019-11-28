#Include "Protheus.ch"       
#Include "Rwmake.ch"
#Include "ParmType.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ ART429   ºAutor  ³Eduardo Marquetti  º Data ³  01/03/12   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Apontamento da producao via leitor Cod Barras/Balança      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP5                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function ART429()
	**********************
	
	DEFINE FONT oFnt  NAME "Arial" SIZE 17,17 //BOLD
	DEFINE FONT oFnt1 NAME "Arial" SIZE 17,17 BOLD
	DEFINE FONT oFnt2 NAME "Arial" SIZE 12,12 BOLD
	DEFINE FONT oFnt3 NAME "Arial" SIZE 19,19 BOLD
	
	CriaArqT()
	
	private cProduto := Space(15)
	private cAuxProd := Space(15)
	private nSaldo   := 0
	private cCodProduto := Space(15)
	
	private cProd     := Space(15)
	private cItem     := Space(2)
	private cSequen   := Space(3)      
	private cQuant    := SPACE(8)
	private cQuant2UM := SPACE(8)
	
	// TODO: William (04/05/2018)
	private cPeso		 	:= 0
	private nPesoBruto 	    := 0
	private nTara			:= 0
	private nPesoLiquido := 0
	// TODO: William (04/05/2018)
		
	private cItens    := SPACE(4)
	private cDescr    := SPACE(35)
	private cAuxQuant := Space(8)    
	private cAuxQuant2um := Space(8)
	private cUM		 := Space(2)    
	private cUmsegum := Space(2)
	// private cRecurso := Space(6)
	private cDescRec := Space(30)
	private cOperador:= Space(3)
	private cDescOp  := Space(40)
	private cTurno   := Space(1)
	private cNumOrdens := Space(30)
	
	private nAuxPeso		:= 0
	private nAuxQuant		:= 0
	private nQuant   		:= 0           
	private nAuxQuant2UM 	:= 0       
	private nQuant2UM  		:= 0
	
	private nseq     		:= 0
	
	private lReemb   := .F.
	private lGetQuant:= .F.
	
	Sele TRB
	DbGoTop()
	lOk:= .t.
	aBRW := {}
	AADD(aBRW,{"ITENS" 	 	,"Volumes"    })
	AADD(aBRW,{"PRODUTO"  	,"Produto"    })
	AADD(aBRW,{"DESCR"    	,"Descrição"  })
	AADD(aBRW,{"QUANTID"  	,"Quantidade" })
	AADD(aBRW,{"PESOBAL"  	,"Peso Balança" })
	AADD(aBRW,{"UM"			,"UM"		    })    
	AADD(aBRW,{"QUANTID2UM" ,"Quant 2a UM" })
	AADD(aBRW,{"UMSEGUM"    ,"2a UM"       })    
	AADD(aBRW,{"OPERADOR"	,"Operador"    })    
	AADD(aBRW,{"TURNO"      ,"Turno"      })    
	// AADD(aBRW,{"RECURSO"  ,"Recurso"    })    
	
	lAtivo	  :=.T.
	lFixaMain :=.F.
	lFixaRec  :=.F.
	lFixaTurno:=.F.
	
	// Verifica Turno
	***********************
	cDiaSemana  := cdow(ddatabase)
	cTurno		:= Space(1)
	cHora		:= time()

	// Regras para Turno:
	// Segunda até Sexta (Domingo Também entra nessa Regra)
	// 1 - 06:00 12:00
	// 1 - 14:00 16:00

	// 2 - 12:00 14:00
	// 2 - 16:00 22:00
	// 
	// Sábado
	// 1 - 06:00 12:00
	// 2 - 09:01 13:00


	If cDiaSemana <> 'Saturday' .and. cHora >= '06:00:00' .and. cHora <='12:00:00'
		cTurno := '1'                                                       
		EndIf
	If cDiaSemana <> 'Saturday' .and. cHora >= '14:00:00' .and. cHora <='16:00:00'
		cTurno := '1'                                                       
		EndIf
	If cDiaSemana <> 'Saturday' .and. cHora >= '12:00:00' .and. cHora <='14:00:00'
		cTurno := '2'                                          
	If cDiaSemana <> 'Saturday' .and. cHora >= '16:00:00' .and. cHora <='22:00:00'
		cTurno := '2'                                          
	EndIf
	EndIf             
	If cDiaSemana = 'Saturday' .and. cHora >= '05:00:00' .and. cHora <='09:00:00'
		cTurno := '1'
	EndIf
	If cDiaSemana = 'Saturday' .and. cHora >= '09:01:00' .and. cHora <='13:00:00'
		cTurno := '2'                                          
	EndIf
	// FIM - Verifica Turno
	***********************
	
	DEFINE MSDIALOG oDlgPrinc TITLE OemToAnsi("Apontamento da Produção - Cod. Barras / BALANCA") FROM 01,01 TO 510,900 PIXEL
	
	@ 04,030 MSGET oProduto var cProduto Valid ValProd() size 090,010 PIXEL
	@ 04,150 GET oQuant var nQuant Valid ValQtd() PICTURE "@e 999.99" size 030,010 PIXEL  When lGetQuant = .T.
	@ 05,380 SAY "Volumes: " SIZE 020,010 COLOR CLR_BLUE PIXEL
	@ 04,410 SAY nSeq        SIZE 030,020 COLOR CLR_RED FONT oFnt3 PIXEL
	@ 05,005 SAY oSayProd var "Leitura: " SIZE 020,010 COLOR CLR_BLUE PIXEL
	@ 20,005 SAY cDescr    SIZE 300,030 COLOR CLR_RED FONT oFnt1 PIXEL
	@ 20,300 SAY cAuxQuant SIZE 045,020 COLOR CLR_RED FONT oFnt1 PIXEL
	@ 20,350 SAY cUM       SIZE 030,020 COLOR CLR_RED FONT oFnt1 PIXEL
	@ 30,005 SAY cAuxProd  SIZE 200,030 COLOR CLR_BLUE FONT oFnt2 PIXEL
	@ 40,005 TO 230,450 BROWSE "TRB" OBJECT oBrw  fields aBRW
	
	obrw:oBrowse:bGotFocus := {|| oProduto:SetFocus()}
	
	@ 235,005 SAY cTurno    SIZE 030,020 COLOR CLR_RED FONT oFnt  PIXEL
	@ 245,005 SAY "Turno"   SIZE 020,010 COLOR CLR_BLUE PIXEL
	@ 245,030 SAY cDescRec  SIZE 100,30  COLOR CLR_BLUE PIXEL
	// @ 235,030 SAY cRecurso  SIZE 100,30  COLOR CLR_RED FONT oFnt PIXEL
	@ 245,030 SAY cDescOp   SIZE 120,30  COLOR CLR_BLUE PIXEL
	@ 235,030 SAY cOperador SIZE 120,30  COLOR CLR_RED FONT oFnt PIXEL
	
	oBtnTurno  :=tButton():New(240,210,"Turno",oDlgPrinc,{||SelTurno()},25,11,,,,.T.)
	// oBtnRecurs :=tButton():New(240,240,"Recurso",oDlgPrinc,{||SelRecurso()},25,11,,,,.T.)
	oBtnOperador :=tButton():New(240,240,"Operador",oDlgPrinc,{||SelOperador()},25,11,,,,.T.)
	
	@ 240,320 BMPBUTTON TYPE 3 ACTION Excluir()	 Object oBtnEx
	oBtnTirar:=tButton():New(240,350,"Desfaz",oDlgPrinc,{||Tirar()},25,11,,,,.T.)
	
	oBtnSair:=tButton():New(240,390,"Sair",oDlgPrinc,{||Sair()},25,11,,,,.T.)
	@ 240,420 BMPBUTTON TYPE 1 ACTION GrvApont() Object oBtnOk
	
	oProduto:Refresh()
	oProduto:SetFocus()
	
	If nSeq <= 0
		oBtnOk:disable()
		oBtnEx:disable()  
		oBtnTirar:disable()  
		oProduto:SetFocus()
	EndIf
	
	ACTIVATE MSDIALOG oDlgPrinc CENTERED valid lFixaMain
Return

/**
 * --------------------------------------------------------------------
 * DESCRIÇÃO	LER PESO BALANÇA URANO
 * AUTOR: 		WILLIAM REIS FERNANDES
 * EMPRESA: 	SLA CONSULTORIA 
 * DATA: 		04/05/2018
 *	FONTE:		SLA009.PRW
 * --------------------------------------------------------------------
 */
Static Function PESOBALM() 
	
	Local nPesoManual := 0
	Local oDlg1Frm := Nil
	Local oSay1Frm := Nil
	Local oGet1Frm := Nil
	Local oBtn1Frm := Nil
	Local oBtn2Frm := Nil
	
	//-> Construção da interface.
	oDlg1Frm := MSDialog():New( 091, 232, 225, 574, "Pessagem manual" ,,, .F.,,,,,, .T.,,, .T. )
	
	//-> Rótulo. 
	oSay1Frm := TSay():New( 008 ,008 ,{ || "Informe o peso manualmente:" } ,oDlg1Frm ,,,.F. ,.F. ,.F. ,.T. ,CLR_BLACK ,CLR_WHITE ,084 ,008 )
	
	//-> Campo.
	oGet1Frm := TGet():New( 020 ,008 ,{ | u | If( PCount() == 0 ,nPesoManual ,nPesoManual := u ) } ,oDlg1Frm ,150 ,008 ,"@e 99999.999" ,,CLR_BLACK ,CLR_WHITE ,,,,.T. ,"" ,,,.F. ,.F. ,,.F. ,.F. ,"" ,"nPesoManual" ,,)
	
	//-> Botões.	
	oBtn2Frm := TButton():New( 040 ,120 ,"Concluir"     ,oDlg1Frm ,{ || oDlg1Frm:End() } ,037 ,012 ,,,,.T. ,,"" ,,,,.F. )
	
	//-> Ativação da interface.
	oDlg1Frm:Activate( ,,,.T.)
	
Return nPesoManual
     
/**
 * --------------------------------------------------------------------
 * Função: 
 *				ARTPESAR
 *
 * Descrição:
 *
 *		Função faz tentativas de pessagem
 * --------------------------------------------------------------------
 */
Static Function ARTPESAR()   

	Local bAcao    	:= {|lFim| ARTPESARC(@lFim, @nPesoBruto, @nTara, @nPesoLiquido) } 	
	Local cTitulo  	:= 'Aguardando leitura da balança...'
	Local cMsg     	:= ''
	Public lAborta 	:= .T.
	
	Processa( bAcao, cTitulo, cMsg, lAborta )
	
Return nPesoLiquido

/**
 * --------------------------------------------------------------------
 * Função: 
 *				ARTPESARC
 *
 * Descrição:
 *
 *		Função faz tentativas de pessagem
 * --------------------------------------------------------------------
 */
Static Function ARTPESARC(lFim, nPesoBruto, nTara, nPesoLiquido)
	
	Local lEnd    		:= .F.
	Local nVezes  		:= 0
	Local cStringPeso 	:= ""	
	Local nTimeWaitB		:= 5
	Local nQtdVerif		:= 500
	Local nHdll  			:= 0
	Local cConfPort		:= "COM1:9600,n,8,2"
	Local cMens   		:= "Deseja repesar?"
	
	Begin Sequence 
	
		ProcRegua(nTimeWaitB)
		While !lEnd                      
		
			// ZERA VARIAVEIS A CADA LOOP
			nPesoBal		:= 0
			cStringPeso 	:= ""
			nVezes 		++
			
			// FAZ REFRESH NA TELA PARA EXIBIR
			Sysrefresh()
			If((lFim) .OR. (nVezes > nTimeWaitB))
				Break
			EndIf
	                                      
			// ABRIR PORTA DA BALANCA
			If MSOpenPort(nHdll,cConfPort)
			
				// 	SLEEP 
				sleep(nQtdVerif)				
			
				// AUTOMATICO COMANDO PARA PESAGEM
				MsWrite(nHdll,chr(4))		
			
				// ESPERAR BALANCA ENVIAR O PESO				
				sleep(nQtdVerif)                 
			
				// LER O PESO ENVIADO PELA BALANCA
				MsRead(nHdll,@cStringPeso)		
				
				// FECHAR PORTA DA BALANCA	
				msClosePort(nHdll)
			Else 
				MsgBox("Não foi possível conectar a porta especificada. Verifique se o cabo da balança está conectado.")
				If MsgYesNo(cMens,OemToAnsi('ATENCAO'))
		        	Loop
				Else
					PESOBALM()					
					Exit
				EndIf
			EndIf
			
			aPesBal		:= cStringPeso
			If !empty(aPesBal) .AND. Len(aPesBal) > 79

				nTara			:=	val(SUBSTR(cStringPeso, AT("T", cStringPeso) + 7, 6))
				nPesoLiquido	:=	val(SUBSTR(cStringPeso, AT("*", cStringPeso) + 10, 6))
				nPesoBruto		:=	val(SUBSTR(cStringPeso, AT("*", cStringPeso) + 10, 6))				
				
				If nPesoLiquido > 0
					Exit
				EndIf
				
			EndIf

			IncProc("Peso : " + cvaltochar(nPesoLiquido) +" Tentativas: "+cvaltochar(nVezes)+"/"+cvaltochar(nTimeWaitB))			

			If !lAborta
				Return(.F.)
			EndIf

		EndDo

/*		oBruto:Refresh()
   		oTara:Refresh()
		oLiq:Refresh() */
		
	End Sequence
	
Return(lEnd)

/* Static Function SelRecurso()
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

*/

Static Function SelOperador()
	****************************
	DEFINE MSDIALOG oDlgOpera TITLE OemToAnsi("Selecione Operador") FROM 01,01 TO 100,200 PIXEL
	@ 04,50 GET  cOperador F3 "SZH"  size 030,010
	@ 30,60 BMPBUTTON TYPE 1 ACTION ValOperador() Object oBtnOkOper
	
	ACTIVATE MSDIALOG oDlgOpera CENTERED valid lFixaOper
	
	lFixaOper:=.T.
	lEnd:=.F.
	nOps:=1                  
Return

Static Function ValOperador()
	*************************
	If !empty(cOperador) .and. Length(Alltrim(cOperador)) >= 2
		DbSelectArea("SZH")
		DbSetOrder(1)
		cAuxOperador := cOperador
	
		If !DbSeek(xFilial("SZH")+cOperador)
			MsgBox("Não existe Operador.")
			Return (.F.)                                                 
		Endif
	
		If cTurno <> SZH->ZH_TURNO
			If SZH->ZH_VTURNO <> '1'            
				MsgBox("Operador não pertence a este turno")
				Return(.F.)
			EndIf
		EndIf                     
	
	EndIf
	GrvOperador()
Return (.T.)               


Static Function GrvOperador()
****************************
	DbSelectArea("SZH")
	DbSetOrder(1)         
	If DbSeek(xFilial("SZH")+cOperador)
	   cDescOp := AllTrim(SZH->ZH_NOME) 
    Else
   		MsgBox("Operador Inexistente")   
   		Return .F.
   	End
	lFixaOper:=.T.
	Close(oDlgOpera)
	lEnd:=.F.
	nOps:=1
	oProduto:Refresh()
	oProduto:SetFocus()
Return

Static Function SelTurno()
****************************
	aTurno:= {"Turno 1","Turno 2","Turno 3"}
	cAuxTurno:= aTurno[3]
		
	DEFINE MSDIALOG oDlgTurno TITLE OemToAnsi("Selecione o Turno") FROM 01,01 TO 100,200 PIXEL
	oCombo:= tComboBox():New(04,50,{|u|if(PCount()>0,cAuxTurno:=u,cAuxTurno)},;
	aTurno,50,20,oDlgTurno,,{||},,,,.T.,,,,,,,,,"cAuxTurno")
	@ 30,60 BMPBUTTON TYPE 1 ACTION GrvTurno() Object oBtnOkTur
	ACTIVATE MSDIALOG oDlgTurno CENTERED valid lFixaTurno
	lFixaTurno:=.t.
	lEnd:=.f.
	nOps:=1                       
Return

Static Function GrvTurno()
****************************
   cTurno := Substring(cAuxTurno,7,1)
   
	lFixaTurno:=.t.
	Close(oDlgTurno)
	lEnd:=.f.
	nOps:=1
Return



Static Function ValProd()
	*************************
	
	If !empty(cProduto) .and. Length(Alltrim(cProduto)) = 13
		DbSelectArea("SB1")
		DbSetOrder(5)
		dbGoTop()
		dbSeek(xFilial("SB1")+cProduto,.T.)
		cAuxProd    := cProduto
		cCodProduto := SB1->B1_COD
	
/*		If cRecurso = SPACE(6) //RECURSO
		MsgBox("Selecione primeiramente o Recurso")
			cProduto = Space(15)		
			Return .F.
		End                                      
*/	
		
		If cOperador = SPACE(3)  			// OPERADOR
		MsgBox("Selecione o Operador")
			cProduto = Space(15)		
			Return .F.
		End
			    
	
		If !DbSeek(xFilial("SB1")+cProduto) // VERIFICA O CODIGO DE BARRAS
			MsgBox("Produto "+Alltrim(cCodProduto)+ " - " + AllTrim(cDescr) + "  nao tem codigo de barras ou nao Cadastrado: ")
			cAuxProd :=cCodProduto
			cProduto = Space(15)		
			oProduto:Refresh()
			oProduto:SetFocus()
			Return .F.   
		Endif
	
	
		DbSelectArea("SB2") // VERIFICA SE O PRODUTO TEM ESTOQUE NEGATIVO
		DbSetOrder(1)         
		DbSeek(xFilial("SB2")+cCodProduto)
		nSaldo := B2_QATU  
		
	    If nSaldo < 0
	    	MsgBox("Produto " +Alltrim(cCodProduto)+ " - " + AllTrim(cDescr) + "  tem SALDO NEGATIVO! Comunique o PCP")
	  //  	EnvMail()
	   		cAuxProd :=cProduto
			cProduto = Space(15)		
			oProduto:Refresh()
			oProduto:SetFocus()
			Return .F.       
	   	End
	
	   If SB1->B1_ATIVOAT = 'N' // VERIFICA SE O PRODUTO ESTA ATIVO
			MsgBox("Este Produto está INATIVO! Verifique")
			cAuxProd :=cProduto
			cProduto = Space(15)		
			oProduto:Refresh()
			oProduto:SetFocus()
			Return .F.
		Endif 
	  
		cDescr    	:= Alltrim(SB1->B1_DESC)  
		cUM		  	:= Alltrim(SB1->B1_UM)  
		cUMSEGUM	:= Alltrim(SB1->B1_SEGUM)  
		cAuxQuant 	:= Alltrim(Str(SB1->B1_PESOPAD))	
			
		cAuxQuant2um 	:= Alltrim(Str(SB1->B1_CONV))
		nAuxQuant 	 	:= val(cAuxQuant)      	 
		nAuxQuant2um 	:= val(cAuxQuant2UM)      	    
		nQuant 	  	:= nAuxQuant
		nQuant2UM    	:= nAuxQuant2UM   
		
		// William (04/05/2017) - Chamar função para pesagem     
		// Limpar o peso
		nPesoLiquido := 0  
		nPesoBruto	 := 0         
		nTara		 := 0    		
		// Executar função
		ARTPESAR()
		
		If SB1->B1_FORAPES = 'S'  // CORDA FORA DE PESO
			lGetQuant := .T.                  
			oQuant:SetFocus()
		Else     
			lGetQuant := .F.
			Valqtd()
			Return .T.
		EndIf
		
		lGetQuant := .F.
		Valqtd()
		
		Return .T.
		
	End                     
Return (.T.)

Static Function ValQtd()
	*************************
	If !empty(cProduto) .and. Length(Alltrim(cProduto)) = 13	 
		DbSelectArea("SB1")
		DbSetOrder(5)
		DbSeek(xFilial('SB1')+cProduto)
	   
		If nQuant = 0 .or. nQuant = 789.7   // Inicial do Código de Barras
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
	lReemb:=.T.
	nSeq++	
	    
		
		dbSelectarea("TRB")
	//	If DbSeek(cProduto+cRecurso+cOperador) 
		If DbSeek(cProduto+cOperador) 
			RecLock("TRB",.F.)
		else
			RecLock("TRB",.T.)
		Endif	                   
	
	  	TRB->Itens      := TRB->Itens + 1
		TRB->Produto    := cProduto
		TRB->Quantid    := (TRB->Quantid + nQuant) 
		TRB->Quantid2UM := (TRB->Quantid2UM + nQuant2UM) 
		TRB->Descr	    := SB1->B1_DESC
		TRB->Um		    := SB1->B1_UM
		TRB->UMSEGUM    := SB1->B1_SEGUM
	// 	TRB->Recurso    := cRecurso
		TRB->Operador   := cOperador	
		TRB->Turno      := cTurno
		
		// William (04/05/2018)
		If nPesoLiquido <= 0
			nPesoLiquido := PESOBALM()
		EndIf			
		TRB->PesoBal    := (TRB->PesoBal + nPesoLiquido)
		
		MsUnlock("TRB")
		
		Sele TRB
		DbGoTop()
		
		oBtnOk:Enable()
		oBtnOk:refresh()   
		oBtnEx:Enable()  
		oBtnTirar:Enable()  
	
	
	oBrw:oBrowse:Refresh()
	obrw:oBrowse:bGotFocus := {|| oProduto:SetFocus()}
	
	cProduto:= Space(15)
	cQuant	:= Space(8)
	nQuant  := 0
Return                                  


Static Function _MATA650()
	**************************

	Local aRot650 := {}
	Local nOpc     := 3 // inclusao
	Private lMsHelpAuto := .T.  // se .t. direciona as mensagens de help
	Private lMsErroAuto := .F. //necessario a criacao, pois sera
	//atualizado quando houver
	//alguma incosistencia nos parametros

	Sele TRB
	DbSetOrder(1)

	//	cProd:=GetSx8Num("")                              
	//	cProd:= GetSxENum("SC2")      
	
	cProd  := " "
	cAliasOld:=Alias()
	dbSelectArea("SC2")
	aAreaSC2:=GetArea()
	dbSetOrder(1)
	cProd := NextNumero("SC2",1,"C2_NUM",.T.)
	cProd := A261RetINV(cProd)	
	
	
	cItem:="01"
	cSequen:= "001"
	Sele SB1
	DbSetOrder(5)
	DbSeek(xFilial("SB1")+TRB->Produto)
	dFim := dDatabase // + 1
	Begin Transaction
	aRot650 := {{"C2_FILIAL"	,xFilial("SC2"),NIL},;
	{"C2_NUM"     ,cProd            ,NIL},;	
	{"C2_ITEM"    ,cItem           	,NIL},;
	{"C2_SEQUEN"  ,cSequen         	,NIL},;
	{"C2_PRODUTO" ,SB1->B1_COD  	,.F.},;
	{"C2_LOCAL"   ,SB1->B1_LOCPAD  	,NIL},;
	{"C2_CC"      ,"120300"		  	,NIL},;	
	{"C2_QUANT"   ,TRB->Quantid    	,NIL},;
	{"C2_UM"      ,SB1->B1_UM      	,NIL},;
	{"C2_DATPRI"  ,dDatabase       	,NIL},;
	{"C2_DATPRF"  ,dFim		       	,NIL},;
	{"C2_EMISSAO" ,dDatabase       	,NIL},;
	{"C2_PRIOR"  ,"500"		       	,NIL},;
	{"C2_STATUS" ,"N"		       	,NIL},;
	{"C2_TPOP"   ,"F"         		,NIL}} 

	MSExecAuto({|x,y| Mata650(x,y)},aRot650,nOpc)
	If lMsErroAuto
		DisarmTransaction()
		break
	EndIf
	ConfirmSx8()
	End Transaction

	If lMsErroAuto
		TONE(400,9)
		Mostraerro()
		Return .F.
	EndIf

Static Function _MATA250()
	**************************
	Local aRot250 := {}
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

   //cNumDoc:=GetSx8Num("SD3") // Pega Numeração Automatica	

    //  Outro Método para usar Numeração SD3 sem o GetSX8Num
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
	 	aRot250 := {{"D3_FILIAL" ,xFilial("SD3"),Nil},;
	 	{"D3_TM"		,"003"  				,Nil},;
		{"D3_COD"		,SB1->B1_COD  			,Nil},;
		{"D3_DESCR"		,TRB->DESCR    			,Nil},;
		{"D3_QUANT"		,TRB->QUANTID			,Nil},;
		{"D3_PESOBAL"	,TRB->PESOBAL			,Nil},;
		{"D3_UM"		,TRB->UM       			,Nil},;    
		{"D3_LOCAL"  	,SB1->B1_LOCPAD  		,NIL},;
		{"D3_OP"		,cProd+cItem+cSequen	,Nil},;			
		{"D3_DOC"		,cNumDoc				,Nil},;	 
		{"D3_PARCTOT"	,"T"					,Nil},;
		{"D3_EMISSAO"	,dDatabase				,Nil},;
		{"D3_OPERADOR"	,TRB->OPERADOR			,Nil},; 
		{"D3_TURNO"		,TRB->TURNO				,Nil},;
		{"D3_DTINC"		,MSDATE()		 		,Nil},;
		{"D3_HORAINC"	,TIME()					,Nil}} 
			
		// 	{"D3_RECURSO"	,TRB->RECURSO			,Nil},; 
		MSExecAuto({|x,y| mata250(x,y)},aRot250,3)
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
		MsgBox("Utilize o Botão Exluir para Zerar as Quantidades para Este Item.")
	Else
	    If nQuant >  TRB->Quantid 
			MsgBox("Quantidade Informada é maior que Registrada.")
	    Else
			If nQuant < TRB->Quantid 
				RecLock("TRB",.F.)             
				TRB->Quantid := (TRB->Quantid - nQuant) 
				TRB->Quantid2UM := (TRB->Quantid2UM - nQuant2UM)
				TRB->PesoBal    := (TRB->PesoBal - nPesoLiquido)
				TRB->Itens := TRB->Itens -1
				nSeq:= nseq -1
				MsUnlock("TRB")      
			End
		End
	End


	oBtnOk2:ENABLE()
	oBtnOk2:refresh()
	oBrw:oBrowse:Refresh()
	
	cProduto:= Space(15)
	cQuant	:= Space(8)
	nQuant  := 0
	
	lFixaMain2:=.t.
	Close(oDlg2)
	lEnd:=.f.
	nOps:=1
	
Return                                  


/*
Static Function EnvMail()
	**************************
	
	cServer     := GetMV("MV_RELSERV")      // Nome do servidor de e-mail
	cAccount	:= GetMV("MV_RELACNT")      // Nome da conta a ser usada no e-mail
	cPassword 	:= GetMV("MV_RELPSW")       // Senha              
	cFrom		:= "dti@cordoariabrasil.com.br"
	cEmail		:= "pcp01@cordoariabrasil.com.br;dti@cordoariabrasil.com.br"
	cAssunto	:= "Saldo Negativo para Apontamento"
	cMensagem	:= "Erro Tentativa de Apontamento de Producao para o Produto " +Alltrim(cCodProduto)+ " - " + AllTrim(cDescr) + "  Motivo: SALDO NEGATIVO!"
	cAttach		:= ""
	
	ACSendMail(cAccount,cPassword,cServer,cFrom,cEmail,cAssunto,cMensagem,cAttach)

Return 
*/


Static Function GrvApont()
	**************************
	Sele TRB
	DbGoTop()
	
	While !eof()
		_MATA650()
		_MATA250()
		Sele TRB
		DbSkip()
	End
	
	 // Primeiro Imprime           
	 Imprime()
	
	Sele TRB
	DbCloseArea("TRB")
	CriaArqT()
	
	// Limpa as Variáveis da Tela
	
	cProduto  := Space(15)
	cDescr    := SPACE(35)
	// cRecurso  := Space (6)
	cDescRec  := Space (35)
	cOperador := Space(3)
	cDescOp   := Space(40)  
	nSeq      := 0
	
	cAuxQuant := Space(1)
	cUM       := Space(1)
	cAuxProd  := Space(1)
	
	
	
	If nSeq <= 0
		oBtnOk:disable()
	//	oBtnEx:disable()
	EndIf
	
	oBtnOk:Refresh()
	//oBtnEx:Refresh()
	oBrw:oBrowse:Refresh()
	oProduto:SetFocus()
Return                 


Static Function Tirar()
	**********************
	Sele TRB
	If !EMPTY(TRB->PRODUTO)
		If MsgBox("Deseja retirar o ultimo registro ?","Escolha","YESNO")

			DbSelectArea("SB1")
			DbSetOrder(5) 
			DbSeek(xFilial("SB1")+TRB->Produto)
	  
			If SB1->B1_PESOPAD > 0 .AND. TRB->ITENS > 1 
				cAuxQuant := Alltrim(Str(SB1->B1_PESOPAD))
				nAuxQuant := val(cAuxQuant)      	    

				Sele TRB
				RecLock("TRB",.F.)   
				TRB->Quantid := TRB->Quantid - nAuxQuant
				TRB->Quantid2UM := (TRB->Quantid2UM - nQuant2UM)
				TRB->PesoBal    := (TRB->PesoBal - nPesoLiquido)
				TRB->ITENS := TRB->ITENS -1

				MsunLock("TRB")
				nSeq	   :=nSeq - 1                
			ElseIf  SB1->B1_PESOPAD > 0 .AND. TRB->ITENS = 1
			    MsgBox("So existe 1(UM) item para este Produto,  utilize o botao EXCLUIR!")
			ElseIf SB1->B1_PESOPAD = 0

				DEFINE MSDIALOG oDlg2 TITLE OemToAnsi("Desconta") FROM 01,01 TO 100,200 PIXEL
				@ 04,50 GET oQuant var nQuant  PICTURE "@e 999.99" size 030,010 PIXEL 
				@ 30,60 BMPBUTTON TYPE 1 ACTION GrvATirar() Object oBtnOk2
				ACTIVATE MSDIALOG oDlg2 CENTERED valid lFixaMain2
				lFixaMain2:=.t.
				lEnd:=.f.
				nOps:=1                  
			End
		EndIf
	EndIf
	
	
	IF nSeq <= 0
		oBtnOk:DISABLE()
	//	oBtnEx:Disable()
	else
		oBtnOk:ENABLE()
	//	oBtnEx:Enable()
	ENDIF
	
	oBtnOk:Refresh()
	
	Sele TRB
	DbGoTop()
	cProduto:=Space(15)
	cLeDados:=Space(12)
	
	oBrw:oBrowse:Refresh()
	oProduto:SetFocus()
return


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


Static Function Imprime()
	*************************
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de Variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	Local cDesc1         	:= "Este programa tem como objetivo imprimir relatorio "
	Local cDesc2         	:= "de acordo com os parametros informados pelo usuario."
	Local cDesc3         	:= "Relatorio de Apontamento de Produção"
	Local cPict          	:= ""
	Local titulo         	:= "Apontamentos de Produção - Cod. Barras"
	Local nLin         		:= 57
	Local Cabec1      		:= " "
	Local Cabec2       		:= " "
	Local imprime      		:= .T.
	Private lEnd         	:= .F.
	Private lAbortPrint  	:= .F.
	Private CbTxt        	:= " "
	Private limite       	:= 80
	Private tamanho      	:= "P"
	Private nomeprog     	:= "ART429" // Nome do programa para impressao no cabecalho
	Private nTipo        	:= 18
	Private aReturn      	:= { "Zebrado", 1, "Administracao", 1, 1, 2, "", 1}
	Private nLastKey     	:= 0
	Private cbtxt      		:= Space(10)
	Private cbcont     		:= 00
	Private CONTFL     		:= 01
	Private m_pag      		:= 01
	Private wnrel      		:= "ART429" // Nome do arquivo usado para impressao em disco
	Private cString   		:= "SD3"
	
	wnrel := SetPrint(cString,NomeProg,,@titulo,cDesc1,cDesc2,cDesc3,.T.,,.T.,Tamanho,,.T.)
	
	If nLastKey == 27
		Return
	Endif
	
	SetDefault(aReturn,cString)
	
	If nLastKey == 27
		Return
	Endif
	
	nTipo := 15
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Processamento. RPTSTATUS monta janela com a regua de processamento. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)
Return


Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ SETREGUA -> Indica quantos registros serao processados para a regua ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	SetRegua(RecCount())
	
		Cabec1  := "Vol.  Produto         Descrição                              Quant     UM"
	    //          9999  XXXXXXXXXXXXX   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX   999.99     XX 
		//          0123456789012345678901234567890123456789012345678901234567890123456789012"
		//                   10        20        30        40        50        60        70   
	
	nTOTQTD := 0
	nTOTVLR := 0
	nTOTVLR2:= 0
	nTOTGRUP:= 0
	cCodAux := ''
	nTotVol := 0
	
	
	Sele TRB
	DbGoTop()
	
	While !TRB->(Eof())
		_cCod := TRB->Produto
	
		While !TRB->(Eof()) .and. TRB->Produto == _cCod
	
			If nLin > 56
				Cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
				nLin := 8
			Endif
	
				@ nLin,000 PSay TRB->Itens
				@ nLin,006 PSay TRB->Produto
				@ nLin,022 PSay TRB->Descr
				@ nLin,060 PSay transform(TRB->Quantid,"@E 999.99")
				@ nLin,071 PSay TRB->Um
	//			@ nLin,078 PSay transform(TRB->Quantid2Um,"@E 999.99")
	//			@ nLin,088 PSay TRB->UmSegum
	//			@ nLin,095 PSay Alltrim(TRB->Recurso)
	//			@ nLin,110 PSay TRB->Operador
	// 			@ nLin,118 PSay TRB->Turno
	   			nTotVol := nTotVol + TRB->Itens
	   			DbSkip()
	   			nLin++
		End
	EndDo   
	
	@ nLin,000 PSay "--------------------"
	nLin++
	@ nLin,000 PSay "Volumes:"
	@ nLin,010 PSay transform(nTotVol,"@E 99.99")
	nTotvol:= 0
	nLin++
	nLin++
	
	//DbSelectArea("TRB")
	//DbCloseArea("TRB")
	
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Finaliza a execucao do relatorio...                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	SET DEVICE TO SCREEN
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Se impressao em disco, chama o gerenciador de impressao...          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	If aReturn[5]==1
		dbCommitAll()
		SET PRINTER TO
		OurSpool(wnrel)
	Endif
	
	MS_FLUSH()

Return
// Fim Relatorio
****************


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
//		oBtnRecurs:Enable()  
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
	Aadd(aStru,{ "UMSEGUM    ", "C", 02, 0 } )
	// Aadd(aStru,{ "RECURSO    ", "C", 06, 0 } )
	Aadd(aStru,{ "OPERADOR   ", "C", 03, 0 } )
	Aadd(aStru,{ "TURNO      ", "C", 01, 0 } )
	Aadd(aStru,{ "PESOBAL    ", "N", 12, 3 } )          
	
	
	If ( Select ( "TRB" ) <> 0 )
		dbSelectArea ( "TRB" )
		dbCloseArea()
	End
	
	cArq := CriaTrab(aStru,.T.)
	dbUseArea ( .T., "", cArq, "TRB", .F., .F. )
	// _cChave := "PRODUTO+RECURSO+OPERADOR"
	_cChave := "PRODUTO+OPERADOR"
	IndRegua("TRB", cArq, _cChave, "", "", "Selecionando registros...")

Return