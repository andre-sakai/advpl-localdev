#INCLUDE "RWMAKE.CH"        
#INCLUDE "TOPCONN.CH"
#INCLUDE "Protheus.ch"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "RPTDEF.CH"
/*/
苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
北谀哪哪哪哪穆哪哪哪哪哪履哪哪哪履哪哪哪哪哪哪哪哪哪哪哪履哪哪穆哪哪哪哪哪目北
北砅rograma  ?BOLETO   ?Autor ?ACTVS                 ?Data ?21/12/12  潮?
北媚哪哪哪哪呐哪哪哪哪哪聊哪哪哪聊哪哪哪哪哪哪哪哪哪哪哪聊哪哪牧哪哪哪哪哪拇北
北矰escri噮o ?IMPRESSAO DE BOLETOS                                        潮?
北媚哪哪哪哪呐哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪拇北
北砋so       ?Especifico para Clientes                                    潮?
北滥哪哪哪哪牧哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪馁北
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌
/*/
User Function BOLETOACTVS(aBoletos)

	Local   nOpc 		:= 1
	Local	nX			:= 0
	Local	nJ			:= 0
	Local	aCabec		:= {}
	Local   aMarked 	:= {}
	Local   cDesc 		:= "Este programa imprime os boletos de"+chr(13)+"cobranca bancaria de acordo com"+chr(13)+"os parametros informados"
	Local 	cQuery		:= ""
	Local	_lInverte	:= .F.
	Local	_cMarca		:= GetMark()  
	Local 	_oDlg       
	Local	oMark          
	Local	oBrowse    
	Local	oImgMark
	Local	oImgDMark
	Local 	aSize		:= MsAdvSize()		//Tamanhos da tela
	Private aRegLoop	:= {}
    
	//Variaveis que indicam qual banco o boleto est?usando
	Private BB			:= .F.
	Private BRADESCO	:= .F.
	Private SAFRA    	:= .F.
	Private ITAU		:= .F.
	Private SANTANDER	:= .F.
	Private CAIXAEF		:= .F.
	Private BANRISUL    := .F.
	Private HSBC	    := .F.
	
	//Variaveis do programa
	Private	aTitulos	:= {}   
	Private cLocPagto	:= ""
	Private Exec    	:= .F.  
	Private lMarcar		:= .T.
	Private cIndexName 	:= ''
	Private cIndexKey  	:= ''
	Private cFilter    	:= ''
	Private cPerg		:= "ACTBOL1"
	Private cAliasSE1 
	Private lAutoExec   
	
	Private _MV_PAR01
	Private _MV_PAR02
	Private _MV_PAR03
	Private _MV_PAR04
	Private _MV_PAR05
	Private _MV_PAR06
	Private _MV_PAR07
	Private _MV_PAR08
	Private _MV_PAR09
	Private _MV_PAR10
	Private _MV_PAR11
	Private _MV_PAR12
	Private _MV_PAR13
	Private _MV_PAR14
	Private _MV_PAR15
	Private _MV_PAR16
	Private _MV_PAR17
	Private _MV_PAR18
	Private _MV_PAR19
	Private _MV_PAR20
	Private _MV_PAR21
	Private _MV_PAR22
	Private _MV_PAR23
	Private _MV_PAR24
	Private _MV_PAR25
	Private _MV_PAR26
	Private _MV_PAR27
	
	aBoletos := IIF(aBoletos==Nil,{},aBoletos)
	
	lAutoExec := Len(aBoletos) > 0     
			
	dbSelectArea("SE1")
	
	If !lAutoExec
	
		ValidPerg()
			
		If !Pergunte (cPerg,.T.)
			Return
		EndIf
		
		//Configura os parametros
		_MV_PAR01 := MV_PAR01 //Do Prefixo:
		_MV_PAR02 := MV_PAR02 //Ate o Prefixo:
		_MV_PAR03 := MV_PAR03 //Do Titulo:
		_MV_PAR04 := MV_PAR04 //Ate o Titulo:
		_MV_PAR05 := MV_PAR05 //Da Parcela:
		_MV_PAR06 := MV_PAR06 //Ate a Parcela:
		_MV_PAR07 := MV_PAR07 //Do Banco:
		_MV_PAR08 := MV_PAR08 //Agencia:
		_MV_PAR09 := MV_PAR09 //Conta:
		_MV_PAR10 := MV_PAR10 //SubConta:
		_MV_PAR11 := MV_PAR11 //Do Cliente:
		_MV_PAR12 := MV_PAR12 //Ate o Cliente:
		_MV_PAR13 := MV_PAR13 //Da Loja:
		_MV_PAR14 := MV_PAR14 //Ate a Loja:
		_MV_PAR15 := MV_PAR15 //Da Data de Vencimento:
		_MV_PAR16 := MV_PAR16 //Ate a Data de Vencimento:
		_MV_PAR17 := MV_PAR17 //Da Data Emiss鉶:
		_MV_PAR18 := MV_PAR18 //Ate a Data de Emiss鉶:
		_MV_PAR19 := MV_PAR19 //Do bordero:
		_MV_PAR20 := MV_PAR20 //Ate o Bordero:
		_MV_PAR21 := MV_PAR21 //Selecionar T韙ulos:
		_MV_PAR22 := MV_PAR22 //Gerar Bordero
		_MV_PAR23 := MV_PAR23 //Enviar por email

		If Empty(MV_PAR04) .Or. Empty(MV_PAR06) .Or. Empty(MV_PAR12) .Or. Empty(MV_PAR18) .Or. Empty(MV_PAR16) .Or. Empty(MV_PAR14) .Or. Empty(MV_PAR20)
			VerParam("Voc?deve selecionar um intervalo de valores em todos os par鈓etros!")
			Return
		EndIf

		nOpc := Aviso("Impressao do Boleto Laser",cDesc,{"Ok","Cancelar"})
	Else
		//COnfigura os parametros
		_MV_PAR21 := 1
		_MV_PAR22 := 1 //Gerar Bordero
		_MV_PAR23 := 1 //Gerar boleto em tela
		//Dados do Banco		
		_MV_PAR07 := MV_PAR01
		_MV_PAR08 := MV_PAR02
		_MV_PAR09 := MV_PAR03
		_MV_PAR10 := MV_PAR04
		
	EndIf

	If nOpc == 1
	 
		dbSelectArea("SE1")
		aStruTRB := dbStruct()
		
		If !lAutoExec
		
			cQuery := "SELECT  "
				
			For nI:=1 To Len(aStruTRB)
				cQuery += aStruTRB[nI][1]+","
			Next nI
			
			cQuery += " SE1.R_E_C_N_O_  AS NREG "
			cQuery += " FROM "+	RetSqlName("SE1") + " SE1 "
			cQuery += " WHERE E1_NUM   >= '" 	+ _MV_PAR03 		+ "' And E1_NUM     <= '" 	+ _MV_PAR04 + "'  " 
			cQuery += " AND E1_PARCELA >= '" 	+ _MV_PAR05 		+ "' And E1_PARCELA <= '"	+ _MV_PAR06 + "'  " 
			cQuery += " AND E1_PREFIXO >= '" 	+ _MV_PAR01 		+ "' And E1_PREFIXO <= '"	+ _MV_PAR02 + "'  " 
			cQuery += " AND E1_CLIENTE >= '" 	+ _MV_PAR11 		+ "' And E1_CLIENTE <= '"	+ _MV_PAR12 + "' " 
			cQuery += " AND E1_EMISSAO >= '" 	+ DTOS(_MV_PAR17)	+ "' And E1_EMISSAO <= '"	+ DTOS(_MV_PAR18) + "' " 
			cQuery += " AND E1_VENCTO  >= '" 	+ DTOS(_MV_PAR15)	+ "' And E1_VENCTO  <= '" 	+ DTOS(_MV_PAR16) + "' "
			cQuery += " AND E1_LOJA    >= '"	+ _MV_PAR13			+ "' And E1_LOJA    <= '"	+ _MV_PAR14 + "' "
			If _MV_PAR22 == 2 //Nao gera bordero
				cQuery += " AND E1_NUMBOR  >= '"	+ _MV_PAR19			+ "' And E1_NUMBOR  <= '"	+ _MV_PAR20 + "' "
				If !Empty(_MV_PAR07)
					cQuery += " AND E1_PORTADO = '" + _MV_PAR07 + "' "
				Endif
			Else
				cQuery += " AND E1_NUMBCO = '' AND E1_NUMBOR = '' " //Se gera bordero, somente selecionara os titulos sem boleto
			Endif
			cQuery += " AND E1_FILIAL = '"		+ xFilial("SE1")	+ "' And E1_SALDO > 0  " 
			cQuery += " AND SUBSTRING(E1_TIPO,3,1) != '-' "  
			cQuery += " AND D_E_L_E_T_ = ' ' "
		    cQuery += " ORDER BY E1_NOMCLI,E1_PORTADO, E1_CLIENTE, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_EMISSAO "
	   EndIf
	
		If Select("TRB1") <> 0
			dbSelectArea("TRB1")
			dbCloseArea()
		EndIf
		
		cAliasSE1 := "TRB1"
		cNomeArq:=CriaTrab( aStruTRB, .T. )
		dbUseArea(.T.,__LocalDriver,cNomeArq,cAliasSE1,.T.,.F.)
		
		If !lAutoExec                                        
			MsAguarde({|| SqlToTrb(cQuery, aStruTRB, cAliasSE1 )},OemToAnsi("Executando Query..."))
		Else                         
			//Criado no ponto de entrada M460NOTA
			For nX:=1 To Len(aBoletos)
				RecLock(cAliasSE1, .T.)
					For nJ:=1 To Len(aBoletos[nX])
						aDados := aBoletos[nX][nJ]
						&(cAliasSE1+"->"+aDados[1]) := aDados[2]        
				   	Next
				MsUnlock()             
			Next
		EndIf
		
		DbSelectArea(cAliasSE1)
		DbGoTOp()
	
		If _mv_par21 == 1
			    
		    dbSelectArea(cAliasSe1)
		    dbGoTop()       
		    
		    While !EoF()
		   		/* SIDINEI - RETIRADO EM 14/07/17 POIS TODOS DEVER肙 APARECER P/ IMPRESSAO
				DbSelectarea("SD2")
				DbSetOrder(3)
				If DbSeek(xfilial("SD2")+ Padr((cAliasSe1)->E1_NUM,Len(SF2->F2_DOC)) + Padr((cAliasSe1)->E1_PREFIXO,Len(SF2->F2_SERIE)) + (cAliasSe1)->E1_CLIENTE + (cAliasSe1)->E1_LOJA )
					DbSelectArea("SC5")
					DbSetOrder(1)
					If DbSeek(xFilial("SC5")+SD2->D2_PEDIDO)
						If SC5->C5_BLEMAIL <> "1"
							aAdd( aRegLoop , (cAliasSe1)->(Recno()) )
							dbSelectArea(cAliasSe1)
							dbSkip()
							Loop
						Endif
					EndIF
				Endif
		        */
		        aTemp := {}
		        AADD(aTemp, !lMarcar)    
		        AADD(aTemp, (cAliasSe1)->E1_NOMCLI)
		        AADD(aTemp, (cAliasSe1)->E1_PREFIXO)
		        AADD(aTemp, (cAliasSe1)->E1_NUM)      
		        AADD(aTemp, (cAliasSe1)->E1_PARCELA)  
		        AADD(aTemp, (cAliasSe1)->E1_TIPO)    
		        AADD(aTemp, (cAliasSe1)->E1_EMISSAO)  
		        AADD(aTemp, (cAliasSe1)->E1_VENCTO)    
		        AADD(aTemp, Transform((cAliasSe1)->E1_SALDO,x3Picture("E1_SALDO")))    
		        	
		        //Caso seja execucao automatica, deve verificar a condicao de pagamento
				If lAutoExec
			        AADD(aTitulos, aTemp)                                
		        Else                                             
		        	//Nao deve verificar porque no financeiro tem o esquema de agrupamento de NF
		        	AADD(aTitulos, aTemp)
		        EndIf
		        
		        dbSelectArea(cAliasSe1)
		        (cAliasSe1)->(DbSkip())
		    EndDo     
		    
		    If Len(aTitulos) == 0
		    	Alert("N鉶 foram encontrados t韙ulos com os parametros informados!") 
		    	DbSelectArea("SE1") 
				RetIndex("SE1")
				FErase(cIndexName+OrdBagExt())        
				Return
		    EndIf  
		    			
			AADD(aCabec, "")
			AADD(aCabec, "Cliente")
			AADD(aCabec, "Prefixo")
			AADD(aCabec, "Documento")
			AADD(aCabec, "Parcela")
			AADD(aCabec, "Tipo")
			AADD(aCabec, "Emissao")
			AADD(aCabec, "Vencimento")
			AADD(aCabec, "Valor")
		
			DEFINE MSDIALOG _oDlg TITLE "Sele玢o de t韙ulos para gera玢o de boletos" From aSize[7],0 To aSize[6],aSize[5] OF oMainWnd PIXEL  
			
			oImgMark 	:= LoadBitmap(GetResources(),'LBTIK')
			oImgDMark	:= LoadBitmap(GetResources(),'LBNO')  
			
			oBrowse:= TCBROWSE():New(001,001,350,170,,aCabec,{},_oDlg,,,,,{||},,_oDlg:oFont,,,,,.F.,,.T.,,.F.,,,)
			
			oBrowse:SetArray(aTitulos)
			oBrowse:lAdjustColSize 	:= .T.
			oBrowse:bLDblClick		:= {|nRow, nCol| aTitulos[oBrowse:nAt,01] := !aTitulos[oBrowse:nAt,01]}
			oBrowse:bChange			:= {||SetFocus(oBrowse:hWnd)} 
			oBrowse:bHeaderClick	:= {|nRow, nCol| If(nCol == 1,(lMarcacao(),oBrowse:Refresh()),Nil) }
			oBrowse:nAt				:= 1
			oBrowse:Align			:= CONTROL_ALIGN_ALLCLIENT //Tela inteira
			oBrowse:bLine 			:= {||{ If(	aTitulos[oBrowse:nAt,01],oImgMark,oImgDMark),;
												PadR(aTitulos[oBrowse:nAt,02],50),;
												aTitulos[oBrowse:nAt,03],;
												aTitulos[oBrowse:nAT,04],;
												aTitulos[oBrowse:nAT,05],;
												aTitulos[oBrowse:nAT,06],;
												aTitulos[oBrowse:nAT,07],;
												aTitulos[oBrowse:nAT,08],;
												aTitulos[oBrowse:nAT,09]}}
		    
	    
			ACTIVATE DIALOG _oDlg CENTERED ON INIT EnchoiceBar(_oDlg,{|| Exec := .T.,Close(_oDlg)},{|| Exec := .F.,Close(_oDlg)})
		EndIf
	EndIf
	
	//Execucao automatica
	If _mv_par21 == 2
		Exec := .T.
	EndIf
	
	For nX:=1 To Len(aTitulos)
		AADD(aMarked,IIF(_mv_par21 == 2,.T.,aTitulos[nX][1]))
	Next
	
	If Exec
		Processa({|lEnd| MontaRel(aMarked)}) 
	Endif
	
	DbSelectArea("SE1") 
	RetIndex("SE1")
	FErase(cIndexName+OrdBagExt())
	
Return Nil                   

//------------------------------------------------------------------------------------
// Inverte marcacao
//------------------------------------------------------------------------------------
Static Function lMarcacao()
	For nX:= 1 To Len(aTitulos)
		aTitulos[nX][1] := lMarcar
	Next
	lMarcar := !lMarcar
Return

//------------------------------------------------------------------------------------
// Impressao dos boletos
//------------------------------------------------------------------------------------

Static Function MontaRel(aMarked)

	Local aDatSacado     
	Local aBolText  
	Local lMark		:= .F.          
	Local CB_RN_NN  	:= {} 
	Local i        	:= 1 
	Local n 			:= 0
	Local nRec      := 0
	Local _nVlrAbat 	:= 0
	Local aBitmap   	:= {"" ,"\Bitmaps\Logo_Siga.bmp"}  //Logo da empresa                 
	Local aBMP		:= aBitMap                  
	Private aDadosEmp	:= {SM0->M0_NOMECOM                                                      	,; //Nome da Empresa
	                       AllTrim(SM0->M0_ENDCOB)                                          		,; //Endere鏾
	                       AllTrim(SM0->M0_BAIRCOB)+", "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB 	,; //Complemento
	                       "CEP: "+Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)             ,; //CEP
	                       "PABX/FAX: "+SM0->M0_TEL                                              ,; //Telefones
	                       "CNPJ: "+Subs(SM0->M0_CGC,1,2)+"."+Subs(SM0->M0_CGC,3,3)+"."+           	;
	                       Subs(SM0->M0_CGC,6,3)+"/"+Subs(SM0->M0_CGC,9,4)+"-"+                    	;
	                       Subs(SM0->M0_CGC,13,2)                                             	,; //CGC
	                       "I.E.: "+Subs(SM0->M0_INSC,1,3)+"."+Subs(SM0->M0_INSC,4,3)+"."+      		;
	                       Subs(SM0->M0_INSC,7,3)+"."+Subs(SM0->M0_INSC,10,3)                      	}  //I.E
	
	Private cCodCeden //Somente BANRISUL
   	Private aDadosTit                       
	Private aDadosBanco     
    Private oPrint                  
    Private nFatorH := 1
    Private nFatorV := 1
    Private nAddSay := 0
    Private nAddLin := 0
    Private nAddBco := 0
    Private lBB_dgnn := .F. //Indica se a impressao do Nosso Numero no BB ?com (T) ou sem (F) digito verificador 
    
	DbSelectArea(cAliasSE1)
	dbGoTop()
	For nX:=1 To Len(aMarked)
		If !lMark
			lMark := aMarked[nX]
		EndIf
	Next
	If !lMark
		Alert("Voc?deve marcar ao menos um boleto para impress鉶!")
  		Return 		
	EndIf
	
   If _MV_PAR23 == 1 //Se for gera玢o em tela
		oPrint:= TMSPrinter():New( "Boleto Laser" )
		oPrint:setPortrait()
		oPrint:setPaperSize(DMPAPER_A4)
		oPrint:Setup()
		oPrint:SetPortrait() 	// ou SetLandscape()
		oPrint:SetPaperSize(DMPAPER_A4)	// tamanho A4
		oPrint:StartPage()   	// Inicia uma nova p醙ina
   Endif
               
   ProcRegua(nRec)
   
   Do While !EOF()
   
   	  //Caso o pedido foi indicado para pagamento por deposito e nao boleto
   	  If aScan(aRegLoop,{|x| x == (cAliasSe1)->(Recno()) }) > 0
		dbSkip()
		Loop
   	  Endif

	  If !aMarked[i]
		i++
		dbSkip()
		Loop
	  Endif

      //Posiciona o SA6 (Bancos)
      DbSelectArea("SA6")
      DbSetOrder(1)
      If !Empty((caliasSE1)->E1_AGEDEP) .And. _MV_PAR22 == 2
         DbSeek(xFilial("SA6")+(caliasSE1)->E1_PORTADO+(caliasSE1)->E1_AGEDEP+(caliasSE1)->E1_CONTA)  
      Else 
         DbSeek(xFilial("SA6")+_MV_PAR07+_MV_PAR08+_MV_PAR09)  
      Endif
      
      If Eof()
         MsgBox("Banco/Ag阯cia n鉶 Encontrado")
         Return()
      Endif
      
      SEA->(DbSetOrder(1))
      SEA->(DbSeek(xFilial("SEA")+(caliasSE1)->E1_NUMBOR+(caliasSE1)->E1_PREFIXO+(caliasSE1)->E1_NUM+(caliasSE1)->E1_PARCELA+(caliasSE1)->E1_TIPO))      
      //Posiciona o SEE (Parametros banco)
      DbSelectArea("SEE")
      DbSetOrder(1)
      If !Empty((caliasSE1)->E1_AGEDEP) .And. _MV_PAR22 == 2
         DbSeek(xFilial("SEE")+(caliasSE1)->(E1_PORTADO+E1_AGEDEP+E1_CONTA)+SEA->EA_SUBCTA)
      Else
         DbSeek(xFilial("SEE")+_MV_PAR07+_MV_PAR08+_MV_PAR09+_MV_PAR10)  
      Endif
      
      If Eof()
         MsgBox("Parametros Bancos N鉶 Encontrado")
         Return()
      EndIf
      
      cA6_COD := SA6->A6_COD
      cA6_AGE := SA6->A6_AGENCIA
      cA6_CON := SA6->A6_NUMCON
      cA6_NOM := SA6->A6_NREDUZ
      cA6_DIG := SA6->A6_DVCTA
      cA6_DAG := SA6->A6_DVAGE
      
      If SEE->(FieldPos("EE_BANCORR")) > 0 .and. SEE->(FieldPos("EE_AGECORR")) > 0 .and. SEE->(FieldPos("EE_CONCORR")) > 0 .and.;
      		!Empty(SEE->EE_BANCORR) .and. !Empty(SEE->EE_AGECORR) .and. !Empty(SEE->EE_CONCORR) 

	      aOldSA6 := SA6->(GetArea())
	      DbSelectArea("SA6")
	      DbSetOrder(1)
	      If DbSeek(xFilial("SA6")+SEE->EE_BANCORR+SEE->EE_AGECORR+SEE->EE_CONCORR)
		      cA6_COD := SEE->EE_BANCORR
		      cA6_AGE := SEE->EE_AGECORR
		      cA6_CON := SEE->EE_CONCORR
		      cA6_NOM := SA6->A6_NREDUZ
		      cA6_DIG := SA6->A6_DVCTA
		      cA6_DAG := SA6->A6_DVAGE
		  Endif
	      RestArea(aOldSA6)
	   Endif

      cCodCeden := SEE->EE_CODEMP //Somente BANRISUL
	  //Posiciona o SA1 (Cliente)
      DbSelectArea("SA1")
      DbSetOrder(1)
      DbSeek(xFilial("SA1")+(caliasSE1)->(E1_CLIENTE+E1_LOJA))
      
      
      If Len(Alltrim(SA1->A1_CGC))== 14
         cCpfCnpj:="CNPJ "+Transform(SA1->A1_CGC,"@R 99.999.999/9999-99")
      Else 
         cCpfCnpj:="CPF "+Transform(SA1->A1_CGC,"@R 999.999.999-99")
      Endif   
      
      DbSelectArea("SE1")
       
      aDadosBanco  := {cA6_COD                                       ,;               //Numero do Banco
                       cA6_NOM                                       ,;               //Nome do Banco
                       Iif(cA6_COD=="479",StrZero(Val(AllTrim(cA6_AGE)),7),SubStr(StrZero(Val(AllTrim(cA6_AGE)),4),1,4)+If(Empty(cA6_DAG),"","-"+cA6_DAG)),;   //Ag阯cia
                       Iif(cA6_COD=="479",AllTrim(SEE->EE_CODEMP),AllTrim(cA6_CON)),;   //Conta Corrente
                       Iif(cA6_COD=="479","",If(Empty(cA6_DIG),"",cA6_DIG))  ,;               //D韌ito da conta corrente
                       AllTrim(SEE->EE_CARTEIR)+Iif(!Empty(AllTrim(SEE->EE_VARIACA)),"-"+SEE->EE_VARIACA,"") }                //Carteira

      aDatSacado   := {AllTrim(SA1->A1_NOME)+" - "+cCpfCnpj             ,;      //Raz鉶 Social 
                       AllTrim(SA1->A1_COD )                            ,;      //C骴igo
                       If(!Empty(SA1->A1_ENDCOB),AllTrim(SA1->A1_ENDCOB)+" - "+SA1->A1_BAIRROC,AllTrim(SA1->A1_END)+"-"+SA1->A1_BAIRRO) ,;      //Endere鏾
                       If(!Empty(SA1->A1_MUNC), AllTrim(SA1->A1_MUNC ), AllTrim(SA1->A1_MUN )) ,;      //Cidade
                       If(!Empty(SA1->A1_ESTC), SA1->A1_ESTC, SA1->A1_EST) ,;      //Estado
                       If(!Empty(SA1->A1_CEPC), SA1->A1_CEPC, SA1->A1_CEP)  }       //CEP     
      
	  _nSaldo := 0
	  _nSaldo := (caliasSE1)->E1_SALDO+(caliasSE1)->E1_SDACRES-(caliasSE1)->E1_SDDECRE 
      _nSaldo -= SomaAbat((caliasSE1)->E1_PREFIXO,(caliasSE1)->E1_NUM,(caliasSE1)->E1_PARCELA,"R",1,,(caliasSE1)->E1_CLIENTE,(caliasSE1)->E1_LOJA)
      
      //Monta o Border?
      If lAutoExec .Or. _MV_PAR22 == 1
			
		cAliasTmp 	:= Alias()
		cRecTmp		:= Recno()
		cBordero 	:= If(!Empty((caliasSE1)->E1_NUMBOR),(caliasSE1)->E1_NUMBOR,BuscaBorde())
			
		If Empty(cBordero)
			cBordero := GetMv("MV_NUMBORR",.F.)
			If Empty(cBordero)
				cBordero := "000001"
			Endif
			PutMv("MV_NUMBORR",Soma1(cBordero))
		Endif
        
		If Empty( (caliasSE1)->E1_NUMBOR ) 
			RecLock("SEA",.T.)
			SEA->EA_FILIAL		:= (caliasSE1)->E1_FILIAL	 
			SEA->EA_PREFIXO 	:= (caliasSE1)->E1_PREFIXO	 
			SEA->EA_NUM 		:= (caliasSE1)->E1_NUM		 
			SEA->EA_PARCELA 	:= (caliasSE1)->E1_PARCELA	 
			SEA->EA_PORTADO 	:= SA6->A6_COD	 
			SEA->EA_AGEDEP 		:= SA6->A6_AGENCIA	 
			SEA->EA_SUBCTA 		:= _MV_PAR10
			SEA->EA_DATABOR 	:= (dDataBase)				 
			SEA->EA_TIPO 		:= (caliasSE1)->E1_TIPO	 
			SEA->EA_LOJA 		:= (caliasSE1)->E1_LOJA	 
			SEA->EA_NUMCON 		:= SA6->A6_NUMCON	 
			SEA->EA_SALDO 		:= (caliasSE1)->E1_SALDO	 
			SEA->EA_FILORIG 	:= (caliasSE1)->E1_FILORIG	 
			SEA->EA_CART 		:= "R"	
			SEA->EA_NUMBOR 		:= cBordero
			SEA->EA_SITUACA		:= "1"
			SEA->EA_SITUANT     := "0"		
			SEA->(MsUnlock())

			DbSelectArea("SE1")
			DbSetOrder(1) //incluido pelo sadiomar em 22/04/2013
			DbSeek(xFilial("SE1")+(cAliasSE1)->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO))
			
			RecLock("SE1",.F.)
			SE1->E1_NUMBOR	:= cBordero			 
			SE1->E1_MOVIMEN	:= dDataBase				 
			SE1->E1_DATABOR	:= dDataBase
			SE1->E1_SITUACA	:= "1"
			SE1->E1_PORTADO := SA6->A6_COD
			SE1->E1_AGEDEP  := SA6->A6_AGENCIA
			SE1->E1_CONTA   := SA6->A6_NUMCON
			SE1->(MsUnlock())
		Endif
					
		DbSelectArea("SE1")
		DbSetOrder(1)
		DbSeek(xFilial("SE1")+(cAliasSE1)->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO))

		DbCloseArea()
		
		DbSelectArea(cAliasTmp)
		DbGoTo(cRecTmp)
					
	  EndIf
      
      //Tamanho do NOSSO NUMERO
      nTam_NN := If( SEE->EE_TAM_NN == 0 , 11 , SEE->EE_TAM_NN )

      //Define NOSSO NUMERO: Se o titulo j?foi impresso, reaproveita, senao, busca do proximo numero gravada na tabela de parametros banco
      cNosso_Num := StrZero( Val( IIf( Empty((caliasSE1)->E1_NUMBCO) , Substr(SEE->EE_FAXATU,1,nTam_NN) , Substr((caliasSE1)->E1_NUMBCO,1,nTam_NN) ) ) , nTam_NN )
      
      If Val(cNosso_Num) == 0
      	cNosso_Num := StrZero( 1, nTam_NN )
      Endif

      If Empty( (caliasSE1)->E1_NUMBCO) //Titulo ainda nao impresso, calcula o proximo numero para o proximo boleto que ser?impresso futuramente
			DbSelectArea("SEE")
			RecLock("SEE",.f.)
			SEE->EE_FAXATU := StrZero( Val(cNosso_Num) + 1, nTam_NN )
	     	SEE->(MsUnlock())
	  Endif
	
      //montando codigo de barras 
      //Caso o titulo ja tenha sido impresso sera pego o nosso numero do campo E1_NUMBCO
      CB_RN_NN    := Ret_cBarra(	Substr(aDadosBanco[1],1,3)+"9",;
      								Subs(aDadosBanco[3],1,4),;
      								aDadosBanco[4],;
      								aDadosBanco[5],;
      								SubStr(aDadosBanco[6],1,2),;
      								AllTrim((caliasSE1)->E1_NUM)+AllTrim((caliasSE1)->E1_PARCELA),;
      								_nSaldo,;
      								(caliasSE1)->E1_VENCTO,;
      								SEE->EE_CODEMP,;
      								cNosso_Num,;
      								SEE->EE_CARTEIR)

      //aDadosTit    :=  {AllTrim((caliasSE1)->E1_NUM)+AllTrim((caliasSE1)->E1_PARCELA)  ,;             //N鷐ero do t韙ulo
      aDadosTit    :=  {AllTrim((caliasSE1)->E1_NUM)  ,;             //N鷐ero do t韙ulo
                       (caliasSE1)->E1_EMISSAO      ,;             //Data da emiss鉶 do t韙ulo
                       MsDate()    ,;             //Data da emiss鉶 do boleto
                       (caliasSE1)->E1_VENCTO  ,;             //Data do vencimento
                       _nSaldo,;             //Valor do t韙ulo
                       IIF( cA6_COD=="041", CB_RN_NN[3], SubStr(CB_RN_NN[3],1,Len(CB_RN_NN[3])-1)+"-"+SubStr(CB_RN_NN[3],Len(CB_RN_NN[3]),1)) ,; //Nosso n鷐ero (Ver f髍mula para calculo)
                       AllTrim((caliasSE1)->E1_TIPO)  ,;//TIPO DO TITULO
                       AllTrim((caliasSE1)->E1_PARCELA),; //PARCELA DO TITULO
                       SEE->EE_CODEMP } //Cod Empresa

      //Mensagens boleto
      aBolText  := 	{}
      //Mensagem de desconto
      If (caliasSE1)->E1_DESCFIN > 0
	      nValDesc := ((caliasSE1)->E1_DESCFIN * (caliasSE1)->E1_SALDO) / 100
	      cDesconto := "DESCONTO DE R$ "+Alltrim(TransForm(nValDesc,"@E 9999,999,999.99"))+" P/ PAGTO AT?O VENCIMENTO"
	      aAdd( aBolText , cDesconto )
      Endif
      //Mensagem de juros
      If (caliasSE1)->E1_VALJUR > 0
	      cJuros := "JUROS DE MORA POR DIA - R$ "+Alltrim(TransForm((caliasSE1)->E1_VALJUR,"@E 9999,999,999.99"))
	      aAdd( aBolText , cJuros )
	  ElseIf (caliasSE1)->E1_PORCJUR > 0
	  	  nValJuros := ((caliasSE1)->E1_PORCJUR * (caliasSE1)->E1_SALDO) / 100
	      cJuros    := "JUROS DE MORA POR DIA - R$ "+Alltrim(TransForm(nValJuros,"@E 9999,999,999.99"))
	      aAdd( aBolText , cJuros )
	  Endif
	  //Mensagem para protesto
	  If Alltrim(SEE->EE_DIASPRO) <> "00" .And. !Empty(SEE->EE_DIASPRO)
		  cProstesto := "T韙ulo sujeito a Protesto ap髎 "+SEE->EE_DIASPRO+" dias de vencimento."
		  aAdd( aBolText , cProstesto )
	  EndIf
      //Outras Mensagens de instrucao
      aAdd( aBolText , SEE->EE_MSG1 ) //Instrucao 1
      aAdd( aBolText , SEE->EE_MSG2 ) //Instrucao 2
      aAdd( aBolText , SEE->EE_MSG3 ) //Instrucao 3                        
	  
      cLocPagto := SEE->EE_LOCPAG //Local para pagamento
      cEspecieD := SEE->EE_ESPDOC //Especie Doc
      cAceite   := SEE->EE_ACEITE //Aceite
      
      //Indica o banco deste boleto
      BB		:= Substr(aDadosBanco[1],1,3) == "001"
      BRADESCO	:= Substr(aDadosBanco[1],1,3) == "237"
      ITAU 		:= Substr(aDadosBanco[1],1,3) $ "341/655"
      SAFRA    	:= Substr(aDadosBanco[1],1,3) == "422"
      SANTANDER := Substr(aDadosBanco[1],1,3) == "033"
      CAIXAEF   := Substr(aDadosBanco[1],1,3) == "104"
      BANRISUL  := Substr(aDadosBanco[1],1,3) == "041"
      HSBC      := Substr(aDadosBanco[1],1,3) == "399"

      cValCIP   := SEE->EE_VALCIP
      If Empty(AllTrim((caliasSE1)->E1_NUMBCO)) //AINDA N肙 FOI IMPRESSO O TITULO   
	     	SE1->(dbSetOrder(1))
			If SE1->(dbSeek(xFilial("SE1")+(cAliasSE1)->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)))
				RecLock("SE1",.F.)
				SE1->E1_OCORREN	:= "01" //Registro de Titulos  
				SE1->E1_INSTR1	:= "00" //05-Protestar no 5o. Dia 趖il (1o. Intrs cod.)
				SE1->E1_INSTR2 	:= "00" //00-Ausencia de Instru珲es (2a. Intr. cod.)
				If BANRISUL
					SE1->E1_NUMBCO 	:= CB_RN_NN[3]+CB_RN_NN[4]
				Else
					SE1->E1_NUMBCO 	:= CB_RN_NN[3] //Nosso numero com ou sem digito verificador (depende da configuracao do banco)
				Endif
				SE1->E1_PORTADO	:= SA6->A6_COD
				SE1->(MsUnlock())
			EndIf
      Endif
      
      If _MV_PAR23 <> 1 //Se for gerar PDF
    	 nFatorH := 0.9
    	 nFatorV := 0.8
    	 nAddSay := 70
    	 nAddLin := 50
    	 nAddBco := 40
         //Define o nome do arquivo a ser gerado em PDF
		 cFatura := AllTrim((cAliasSE1)->E1_TIPO)+Alltrim(cEmpAnt)+AllTrim((cAliasSE1)->E1_NUM)+"P"+AllTrim((cAliasSE1)->E1_PARCELA)
		 
		 //*********************************************
		 //ADICIONADO FUNCAO PARA TIRAR AS / (BARRAS) DO NUMERO DA PARCELA, POIS GERA ERRO NA GRAVACAO EM PDF E ENVIO POR E-mail
		 //TSC117 - Jaylson - 10/07/2017
         
		 cFatura := StrTran(cFatura,"/","")  
		 
		 // FIM DA ALTERACAO
		 //*********************************************
	  
	  
      	 //Verifica se o boleto j?est?no diretorio e exclui
	     cDirTmpFat := Alltrim(GetTempPath())+"totvsprinter\" //Alltrim(Mv_par24)+if(Right(Alltrim(Mv_par24),1)=="\","","\")
	     MontaDir(cDirTmpFat)
		 If File(cDirTmpFat+cFatura+".PDF")
	    	FErase(cDirTmpFat+cFatura+".PDF")
	     Endif
    	
    	 nResol := 72
	     Private oPrint:=FWMSPrinter():New(cFatura,IMP_PDF,.T.,cDirTmpFat,.T.,,@oPrint,,.T.,,,.F.)
		 oPrint:SetResolution(nResol)
		 oPrint:SetPortrait()
		 oPrint:SetPaperSize(DMPAPER_A4)
		 oPrint:SetMargin(60,60,60,60)
      Endif
      
      If aMarked[i]
         Impress(aBMP,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,CB_RN_NN,cLocPagto,cValCIP,cEspecieD,cAceite)
         n := n + 1
      EndIf 

      If _MV_PAR23 <> 1 //Se for gerar PDF
		  oPrint:Print()   //Gerar em PDF
		  
		  //Salva o PDF no diretorio local e do servidor
		  MontaDir(cDirTmpFat)
		  If File("\Boletos\"+cFatura+".PDF")
		      FErase("\Boletos\"+cFatura+".PDF")
		  Endif
		  
		  CpyT2S( cDirTmpFat+cFatura+".PDF", "\Boletos" )
		  
		  If File(Alltrim(Mv_par24)+cFatura+".PDF")
		      FErase(Alltrim(Mv_par24)+cFatura+".PDF")
		  Endif
		  CpyS2T( "\Boletos\"+cFatura+".PDF", Alltrim(Mv_par24) )
		  
		  dbSelectArea("SA1")
		  SA1->(dbsetorder(1))
		  
		  
		  //Enviar PDF por email
		  If _MV_PAR23 == 3
		
			
			 	
			 		EnvEmail(cFatura)
		    	
		  Endif
      Endif

      DbSelectArea(cAliasSE1)  
      dbSkip()          
      IncProc()
      i++
   EndDo   
   
   If _MV_PAR23 == 1 //Se for gera玢o em tela
	   oPrint:EndPage() //Finaliza a p醙ina
	   oPrint:Preview() //Visualiza antes de imprimir
   Endif
Return nil

//------------------------------------------------------------------------------------
// Imprime pagina
//------------------------------------------------------------------------------------
Static Function Impress(aBitmap,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,CB_RN_NN,cLocPagto,cValCIP,cEspecieD,cAceite)

	Local i := 0,nBol
	Local aCoords1 := {150,1900,250,2300}   // FICHA DO SACADO
	Local aCoords2 := {420,1900,490,2300}   // FICHA DO SACADO
	Local aCoords3 := {1270,1900,1370,2300} // FICHA DO CAIXA
	Local aCoords4 := {1540,1900,1610,2300} // FICHA DO CAIXA
	Local aCoords5 := {2390,1900,2490,2300} // FICHA DE COMPENSACAO
	Local aCoords6 := {2660,1900,2730,2300} // FICHA DE COMPENSACAO
	Local oBrush

	//Par鈓etros de TFont.New()
	//1.Nome da Fonte (Windows)
	//3.Tamanho em Pixels
	//5.Bold (T/F)
	oFont8  	:= TFont():New("Arial",9,8 ,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont09 	:= TFont():New("Arial",9,9,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont10 	:= TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont10n 	:= TFont():New("Arial",9,10,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont14		:= TFont():New("Arial",9,14,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont14n	:= TFont():New("Arial",9,13,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont16 	:= TFont():New("Arial",9,16,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont16n	:= TFont():New("Arial",9,16,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont20		:= TFont():New("Arial",9,20,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont24 	:= TFont():New("Arial",9,24,.T.,.T.,5,.T.,5,.T.,.F.)
	
	oBrush := TBrush():New("",4)
	
	oPrint:StartPage()   // Inicia uma nova p醙ina
	
	//Variaveis para Label
	cLabAgCed := If(ITAU .or. BANRISUL .or. HSBC,"Ag阯cia/C骴igo do Benefici醨io","Ag阯cia/C骴igo do Benefici醨io")
	cLabCeden := If(ITAU .or. BANRISUL .or. HSBC,"Benefici醨io","Benefici醨io")
	cLabSaca  := If(ITAU .or. BANRISUL .or. HSBC,"Pagador","Pagador")
	
	//cLabAgCed := If(ITAU .or. BANRISUL .or. HSBC,"Ag阯cia/C骴igo do Benefici醨io","Ag阯cia/C骴igo Benefici醨io")
	//cLabCeden := If(ITAU .or. BANRISUL .or. HSBC,"Benefici醨io","Benefici醨io e Pagador")
	//cLabSaca  := If(ITAU .or. BANRISUL .or. HSBC,"Pagador","Benefici醨io e Pagador")
	
	
	nAjLin := 0
	
	//谀哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪?
	//?Ficha do Caixa                                                     ?
	//滥哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪?
	o_Line (150,100,150,2300)   
	If File(Alltrim(aDadosBanco[1])+".bmp") //Verifica se existe imagem com o logo do banco -> A6_COD + ".bmp"
		If _MV_PAR23 == 1 //Se for em tela
			oPrint:SayBitMap(84-30,100,Alltrim(aDadosBanco[1])+".bmp",332,82 )  //imagem
		Else
			o_SayBitMap(84-30,100,Alltrim(aDadosBanco[1])+".bmp",332,82 )  //imagem
		Endif
	Else
		o_Say  (84,100,aDadosBanco[2],oFont16 )  //Nome Banco
	Endif
	o_Say  (84,1850,"Comprovante de Entrega"                              ,oFont10)

	o_Line (250,100,250,1300 )
	o_Line (350,100,350,1300 )
	o_Line (420,100,420,2300 )
	o_Line (490,100,490,2300 )

	o_Line (350,400,420,400)
	o_Line (420,500,490,500)
	o_Line (350,725,420,725)
	o_Line (350,850,420,850)

	o_Line (150,1300,490,1300 )
	o_Line (150,2300,490,2300 )
	o_Say  (150,1310 ,"MOTIVOS DE N肙 ENTREGA (para uso do entregador)"                             ,oFont8) 
	o_Say  (200,1310 ,"|   | Mudou-se"                             ,oFont8) 
	o_Say  (270,1310 ,"|   | Recusado"                             ,oFont8) 
	o_Say  (340,1310 ,"|   | Desconhecido"                             ,oFont8) 

	o_Say  (200,1580 ,"|   | Ausente"                             ,oFont8) 
	o_Say  (270,1580 ,"|   | N鉶 Procurado"                             ,oFont8) 
	o_Say  (340,1580 ,"|   | Endere鏾 insuficiente"                             ,oFont8) 

	o_Say  (200,1930 ,"|   | N鉶 existe o N鷐ero"                             ,oFont8) 
	o_Say  (270,1930 ,"|   | Falecido"                             ,oFont8) 
	o_Say  (340,1930 ,"|   | Outros(anotar no verso)"                             ,oFont8) 

	o_Say  (420,1310 ,"Recebi(emos) o bloqueto"                             ,oFont8) 
	o_Say  (450,1310 ,"com os dados ao lado."                             ,oFont8) 
	o_Line (420,1700,490,1700)
	o_Say  (420,1705 ,"Data"                             ,oFont8) 
	o_Line (420,1900,490,1900)
	o_Say  (420,1905 ,"Assinatura"                             ,oFont8) 

	o_Say  (150,100 ,cLabCeden            	,oFont8) //Cedente
	o_Say  (150,300 ,aDadosEmp[6]         	,oFont10n) 
	o_Say  (185,100 ,AllTrim(aDadosEmp[1])	,oFont10)
	o_Say  (220,100 ,aDadosEmp[2]+", "+aDadosEmp[3] ,oFont8)
	
	cIndTmp := At("-",aDatSacado[1])
	cCGCTmp := SubStr(aDatSacado[1], At("-", aDatSacado[1])+2, Len(aDatSacado[1]))
	cSacado := SubStr(aDatSacado[1],1, At("-", aDatSacado[1])-2)

	o_Say  (250,100 ,cLabSaca   	,oFont8) //Sacado ou Pagador
	o_Say  (250,300 ,cCGCTmp		,oFont10n)
	o_Say  (290,100 ,cSacado    	,oFont10)

	o_Say  (350,100 ,"Data do Vencimento"                              ,oFont8)  
	o_Say  (380,100 ,Substr(DTOS(aDadosTit[4]),7,2)+"/"+Substr(DTOS(aDadosTit[4]),5,2)+"/"+Substr(DTOS(aDadosTit[4]),1,4),oFont10) 

	o_Say  (350,405 ,"Nro.Documento"                                  ,oFont8) 
	o_Say  (380,435 ,aDadosTit[1]+aDadosTit[8]                         ,oFont10)

	o_Say  (350,730,"Moeda"                                   ,oFont8)
	o_Say  (380,755,GetMv("MV_SIMB1")                         ,oFont10)

	o_Say  (350,855,"Valor/Quantidade"                               ,oFont8) 
	o_Say  (380,865,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10)

	o_Say  (420,100 ,cLabAgCed                           ,oFont8) //"Ag阯cia/C骴igo do Cedente"

	If BANRISUL
		o_Say  (450,100,aDadosBanco[3]+".38/"+ Substr(cCodCeden,1,6)+"."+Substr(cCodCeden,7,1)+"."+Substr(cCodCeden,8,2)  ,oFont10)
	ElseIf HSBC
		o_Say  (450,100,aDadosBanco[3]+aDadosBanco[4]+aDadosBanco[5],oFont10)
	Else
		o_Say  (450,100,aDadosBanco[3]+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""),oFont10)
	EndIf

	o_Say  (420,505,"Nosso N鷐ero"                                   ,oFont8)   	
	If BRADESCO
		o_Say  (450,520,aDadosBanco[6]+"/"+SubStr(aDadosTit[6], Len(aDadosTit[6])-12, 13)        ,oFont10)
	ElseIf BB
		If lBB_dgnn
			o_Say  (450,520,Alltrim(Substr(aDadosTit[9],1,7))+StrTran(aDadosTit[6],"-",""),oFont10)
		Else
			o_Say  (450,520,Alltrim(Substr(aDadosTit[9],1,7))+SubStr(CB_RN_NN[3],1,Len(CB_RN_NN[3])-1),oFont10)
		Endif
	ElseIf ITAU
		o_Say  (450,520,aDadosBanco[6]+"/"+substr(aDadosTit[6],1,len(aDadosTit[6]))        ,oFont10)
	ElseIf BANRISUL
		o_Say  (450,520,CB_RN_NN[3]+CB_RN_NN[4],oFont10)  
	Else
		o_Say  (450,520,aDadosTit[6],oFont10)
	EndIf

	For i := 100 to 2300 step 50
	   o_Line( 520, i, 520, i+30)
	Next i

	For i := 100 to 2300 step 50
	   o_Line( 1080, i, 1080, i+30)
	Next i

	//谀哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪?
	//?Ficha do Sacado                                                     ?
	//滥哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪?
	
	o_Line (1270,100,1270,2300)   
	o_Line (1270,650,1170,650 )
	o_Line (1270,900,1170,900 ) 
	If File(Alltrim(aDadosBanco[1])+".bmp") //Verifica se existe imagem com o logo do banco -> A6_COD + ".bmp"
		If _MV_PAR23 == 1 //Se for em tela
			oPrint:SayBitMap(1204-30,100,Alltrim(aDadosBanco[1])+".bmp",332,82 )  //imagem
		Else
			o_SayBitMap(1204-30,100,Alltrim(aDadosBanco[1])+".bmp",332,82 )  //imagem
		Endif
	Else
		o_Say  (1204,100,aDadosBanco[2],oFont16 ) //Nome Banco (ou imagem)
	Endif
	If BRADESCO
		o_Say  (1182+nAddBco,680,aDadosBanco[1]+"-2",oFont20 ) 
	ElseIf SAFRA
		o_Say  (1182+nAddBco,680,aDadosBanco[1]+"-7",oFont20 ) 
	ElseIf BANRISUL
		o_Say  (1182+nAddBco,680,aDadosBanco[1]+"-8",oFont20 )
	Else
		o_Say  (1182+nAddBco,680,aDadosBanco[1]+"-"+Modulo11(aDadosBanco[1],aDadosBanco[1]),oFont20 ) 
	EndIf
	
	o_Line (1370,100,1370,2300 )
	o_Line (1470,100,1470,2300 )
	o_Line (1540,100,1540,2300 )
	o_Line (1610,100,1610,2300 )
	
	o_Line (1470,500,1610,500)
	o_Line (1540,750,1610,750) 
	o_Line (1470,1000,1610,1000)
	o_Line (1470,1350,1540,1350)
	o_Line (1470,1550,1610,1550)
	
	o_Say  (1270,100 ,"Local de Pagamento"                             ,oFont8) 
	o_Say  (1310,100 ,cLocPagto        ,oFont10)
	
	o_Say  (1270,1910,"Vencimento"                                     ,oFont8)
	o_Say  (1310,2200,Substr(DTOS(aDadosTit[4]),7,2)+"/"+Substr(DTOS(aDadosTit[4]),5,2)+"/"+Substr(DTOS(aDadosTit[4]),1,4),oFont10,,,,1 )
	 
	o_Say  (1370,100 ,cLabCeden                                   ,oFont8) //Cedente
	o_Say  (1405,100 ,AllTrim(aDadosEmp[1])+" - "+aDadosEmp[6]                                     ,oFont10)
	o_Say  (1440,100 ,aDadosEmp[2]+", "+aDadosEmp[3] ,oFont8)
	
	o_Say  (1370,1910,cLabAgCed                         ,oFont8) //Ag阯cia/C骴igo Cedente
	If SAFRA
		o_Say  (1410,2200,PadL(aDadosBanco[3],5,"0")+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""),oFont10,,,,1 )
	ElseIf BANRISUL
		o_Say  (1410,2200,PadL(aDadosBanco[3],4,"0")+".38/"+Substr(cCodCeden,1,6)+"."+Substr(cCodCeden,7,1)+"."+Substr(cCodCeden,8,2)  ,oFont10,,,,1 )
	ElseIf HSBC
		o_Say  (1410,2200,aDadosBanco[3]+aDadosBanco[4]+aDadosBanco[5],oFont10,,,,1 )
	Else
		o_Say  (1410,2200,aDadosBanco[3]+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""),oFont10,,,,1 )
	Endif
	
	o_Say  (1470,100 ,"Data do Documento"                              ,oFont8)  
	o_Say  (1500,100 ,Substr(DTOS(aDadosTit[2]),7,2)+"/"+Substr(DTOS(aDadosTit[2]),5,2)+"/"+Substr(DTOS(aDadosTit[2]),1,4),oFont10) 
	
	o_Say  (1470,505 ,"Nro.Documento"                                  ,oFont8) 
	o_Say  (1500,535 ,aDadosTit[1]+aDadosTit[8]                  ,oFont10)
	
	o_Say  (1470,1005,"Esp閏ie Doc."                                   ,oFont8)
	o_Say  (1500,1105,cEspecieD                                       ,oFont10)
	
	o_Say  (1470,1355,"Aceite"                                         ,oFont8) 
	o_Say  (1500,1455,cAceite                                          ,oFont10)
	
	o_Say  (1470,1555,"Data do Processamento"                          ,oFont8) 
	o_Say  (1500,1655,Substr(DTOS(aDadosTit[2]),7,2)+"/"+Substr(DTOS(aDadosTit[2]),5,2)+"/"+Substr(DTOS(aDadosTit[2]),1,4)                               ,oFont10)

	o_Say  (1470,1910,"Nosso N鷐ero"                                   ,oFont8)  	
	If BRADESCO
		o_Say  (1500,2200,aDadosBanco[6]+"/"+SubStr(aDadosTit[6], Len(aDadosTit[6])-12, 13)       ,oFont10,,,,1 )
	ElseIf BB
		If lBB_dgnn
			o_Say  (1500,2200,Alltrim(Substr(aDadosTit[9],1,7))+StrTran(aDadosTit[6],"-",""),oFont10,,,,1 )
		Else
			o_Say  (1500,2200,Alltrim(Substr(aDadosTit[9],1,7))+SubStr(CB_RN_NN[3],1,Len(CB_RN_NN[3])-1),oFont10,,,,1 )
		Endif		
	ElseIf ITAU
		o_Say  (1500,2200,aDadosBanco[6]+"/"+substr(aDadosTit[6],1,len(aDadosTit[6]))        ,oFont10,,,,1 )
	ElseIf BANRISUL
		o_Say  (1500,2200,CB_RN_NN[3]+CB_RN_NN[4],oFont10,,,,1 )
	Else
		o_Say  (1500,2200,aDadosTit[6],oFont10,,,,1 )
	EndIf
	
	o_Say  (1540,100 ,"Uso do Banco"                                   ,oFont8)
	
	If !Empty(cValCIP)
		o_Line(1540,405,1610,405)
		o_Say(1540,410,"CIP")
		o_Say(1570,435,cValCIP,oFont10)
	EndIf        
	
	o_Say  (1540,505 ,"Carteira"                                       ,oFont8)     
	o_Say  (1570,555 ,aDadosBanco[6]                                   ,oFont10)     
	
	o_Say  (1540,755 ,"Esp閏ie"                                        ,oFont8)   
	o_Say  (1570,805 ,GetMv("MV_SIMB1")                                ,oFont10)  
	
	o_Say  (1540,1005,"Quantidade"                                     ,oFont8) 
	o_Say  (1540,1555,"Valor"                                          ,oFont8)            
	
	o_Say  (1540,1910,"(=)Valor do Documento"                          ,oFont8) 
	o_Say  (1570,2200,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10,,,,1 )
	
	If BANRISUL
		o_Say  (1610,100 ,"Instru珲es (Todas as informa珲es deste boleto s鉶 de responsabilidade do benefici醨io)",oFont8)
	ElseIf HSBC
		o_Say  (1610,100 ,"Instru珲es/Texto de responsabilidade do benefici醨io",oFont8)
	ElseIf ITAU
		o_Say  (1610,100 ,"Instru珲es (Instru珲es de responsabilidade do benefici醨io. Qualquer d鷙ida sobre este boleto, contate o benefici醨io)",oFont8)
	Else
		o_Say  (1610,100 ,"Instru珲es/Texto de responsabilidade do cedente",oFont8)
	EndIf
	For nBol := 1 To 6
		If Len(aBolText) >= nBol
			o_Say  (1630+(40*nBol),100 ,aBolText[nBol],oFont09)
		Endif
	Next nBol
	
	o_Say  (1610,1910,"(-)Desconto/Abatimento"                         ,oFont8) 
	o_Say  (1680,1910,"(-)Outras Dedu珲es"                             ,oFont8)
	o_Say  (1750,1910,"(+)Mora/Multa"                                  ,oFont8)
	o_Say  (1820,1910,"(+)Outros Acr閟cimos"                           ,oFont8)
	o_Say  (1890,1910,"(=)Valor Cobrado"                               ,oFont8)
	o_Say  (1960 ,100 ,cLabSaca+":"                                         ,oFont8)//Do Sacado ou Pagador
	o_Say  (1988 ,210 ,aDatSacado[1]+" ("+aDatSacado[2]+")"             ,oFont8)
	o_Say  (2030 ,210 ,aDatSacado[3]                                    ,oFont8)
	o_Say  (2070 ,210 ,aDatSacado[6]+"  "+aDatSacado[4]+" - "+aDatSacado[5] ,oFont8)
	
	o_Say  (1925,100 ,"Sacador/Avalista"                               ,oFont8)   
	o_Say  (2110,1500,"Autentica玢o Mec鈔ica "                        ,oFont8)  
	o_Say  (1204,1850,"Recibo do "+cLabSaca+":"                              ,oFont10) //Do Sacado ou Pagador
	
	o_Line (1270,1900,1960,1900 )
	o_Line (1680,1900,1680,2300 )
	o_Line (1750,1900,1750,2300 )
	o_Line (1820,1900,1820,2300 )
	o_Line (1890,1900,1890,2300 )  
	o_Line (1960,100 ,1960,2300 )
	
	o_Line (2105,100,2105,2300  )     
	
	For i := 100 to 2300 step 50
	   o_Line( 2270, i, 2270, i+30)
	Next i                                                                   
	
	//谀哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪?
	//?Ficha de Compensacao                                                ?
	//滥哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪?
	
	o_Line (2390,100,2390,2300)   
	o_Line (2390,650,2290,650 )
	o_Line (2390,900,2290,900 )

	If File(Alltrim(aDadosBanco[1])+".bmp") //Verifica se existe imagem com o logo do banco -> A6_COD + ".bmp"
		If _MV_PAR23 == 1 //Se for em tela
			oPrint:SayBitMap(2324-30,100,Alltrim(aDadosBanco[1])+".bmp",332,82 )  //imagem
		Else
			o_SayBitMap(2324-30,100,Alltrim(aDadosBanco[1])+".bmp",332,82 )  //imagem
		Endif
	Else	 
		o_Say  (2324,100,aDadosBanco[2],oFont16 )  //Nome do Banco
	Endif
	
	If BRADESCO
		o_Say  (2302+nAddBco,680,aDadosBanco[1]+"-2",oFont20 ) 
	ElseIf SAFRA
		o_Say  (2302+nAddBco,680,aDadosBanco[1]+"-7",oFont20 ) 
	ElseIf BANRISUL
		o_Say  (2302+nAddBco,680,aDadosBanco[1]+"-8",oFont20 )
	Else
		o_Say  (2302+nAddBco,680,aDadosBanco[1]+"-"+Modulo11(aDadosBanco[1],aDadosBanco[1]),oFont20 ) 
	EndIf
	o_Say  (2324,920,CB_RN_NN[2],oFont14n) //linha digitavel
	
	o_Line (2490,100,2490,2300 )
	o_Line (2590,100,2590,2300 )
	o_Line (2660,100,2660,2300 )
	o_Line (2730,100,2730,2300 )
	
	o_Line (2590,500,2730,500)
	o_Line (2660,750,2730,750)
	o_Line (2590,1000,2730,1000)
	o_Line (2590,1350,2660,1350)
	o_Line (2590,1550,2730,1550)
	
	o_Say  (2390,100 ,"Local de Pagamento"                             ,oFont8) 
	o_Say  (2430,100 ,cLocPagto        ,oFont10)
	
	o_Say  (2390,1910,"Vencimento"                                     ,oFont8)
	o_Say  (2430,2200,Substr(DTOS(aDadosTit[4]),7,2)+"/"+Substr(DTOS(aDadosTit[4]),5,2)+"/"+Substr(DTOS(aDadosTit[4]),1,4),oFont10,,,,1 )
	 
	o_Say  (2490,100 ,cLabCeden                                   ,oFont8) //Cedente
	o_Say  (2525,100 ,AllTrim(aDadosEmp[1])+" - "+aDadosEmp[6]                                     ,oFont10)
	o_Say  (2560,100 ,aDadosEmp[2]+", "+aDadosEmp[3] ,oFont8)
	
	o_Say  (2490,1910,cLabAgCed                         ,oFont8) //Ag阯cia/C骴igo Cedente
	If SAFRA
		o_Say  (2530,2200,PadL(aDadosBanco[3],5,"0")+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""),oFont10,,,,1 )
	ElseIf BANRISUL
		o_Say  (2530,2200,PadL(aDadosBanco[3],4,"0")+".38/"+ Substr(cCodCeden,1,6)+"."+Substr(cCodCeden,7,1)+"."+Substr(cCodCeden,8,2)  ,oFont10,,,,1 )
	ElseIf HSBC
		o_Say  (2530,2200,aDadosBanco[3]+aDadosBanco[4]+aDadosBanco[5],oFont10,,,,1 )
	Else
		o_Say  (2530,2200,aDadosBanco[3]+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""),oFont10,,,,1 )
	Endif
	
	o_Say  (2590,100 ,"Data do Documento"                              ,oFont8)  
	o_Say  (2620,100 ,Substr(DTOS(aDadosTit[2]),7,2)+"/"+Substr(DTOS(aDadosTit[2]),5,2)+"/"+Substr(DTOS(aDadosTit[2]),1,4),oFont10) 
	
	o_Say  (2590,505 ,"Nro.Documento"                                  ,oFont8) 
	o_Say  (2620,535 ,aDadosTit[1]+aDadosTit[8]                  ,oFont10)
	
	o_Say  (2590,1005,"Esp閏ie Doc."                                   ,oFont8)
	o_Say  (2620,1105,cEspecieD                                        ,oFont10)
	
	o_Say  (2590,1355,"Aceite"                                         ,oFont8) 
	o_Say  (2620,1455,cAceite                                          ,oFont10)
	
	o_Say  (2590,1555,"Data do Processamento"                          ,oFont8) 
	o_Say  (2620,1655,Substr(DTOS(aDadosTit[2]),7,2)+"/"+Substr(DTOS(aDadosTit[2]),5,2)+"/"+Substr(DTOS(aDadosTit[2]),1,4)                               ,oFont10)

	o_Say  (2590,1910,"Nosso N鷐ero"                                   ,oFont8)   	
	If BRADESCO
		o_Say  (2620,2200,aDadosBanco[6]+"/"+SubStr(aDadosTit[6], Len(aDadosTit[6])-12, 13)        ,oFont10,,,,1 )
	ElseIf BB
		If lBB_dgnn
			o_Say  (2620,2200,Alltrim(Substr(aDadosTit[9],1,7))+StrTran(aDadosTit[6],"-",""),oFont10,,,,1 )
		Else
			o_Say  (2620,2200,Alltrim(Substr(aDadosTit[9],1,7))+SubStr(CB_RN_NN[3],1,Len(CB_RN_NN[3])-1),oFont10,,,,1 )
		Endif
	ElseIf ITAU
		o_Say  (2620,2200,aDadosBanco[6]+"/"+substr(aDadosTit[6],1,len(aDadosTit[6]))        ,oFont10,,,,1 )
	ElseIf BANRISUL
		o_Say  (2620,2200,CB_RN_NN[3]+CB_RN_NN[4],oFont10,,,,1 )
	Else
		o_Say  (2620,2200,aDadosTit[6],oFont10,,,,1 )
	EndIf
	
	o_Say  (2660,100 ,"Uso do Banco"                                   ,oFont8)
	
	If !Empty(cValCIP)
		o_Line(2660,405,2730,405)
		o_Say(2660,410,"CIP")
		o_Say(2690,435,cValCIP,oFont10)
	EndIf        
	
	o_Say  (2660,505 ,"Carteira"                                       ,oFont8)     
	o_Say  (2690,555 ,aDadosBanco[6]                                   ,oFont10)     
	
	o_Say  (2660,755 ,"Esp閏ie"                                        ,oFont8)   
	o_Say  (2690,805 ,GetMv("MV_SIMB1")                                ,oFont10)  
	
	o_Say  (2660,1005,"Quantidade"                                     ,oFont8) 
	o_Say  (2660,1555,"Valor"                                          ,oFont8)            
	
	o_Say  (2660,1910,"(=)Valor do Documento"                          ,oFont8) 
	o_Say  (2690,2200,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10,,,,1 )
	
	If BANRISUL
		o_Say  (2730,100 ,"Instru珲es(Todas as informa珲es deste boleto s鉶 de responsabilidade do benefici醨io)",oFont8)
	ElseIf HSBC
		o_Say  (2730,100 ,"Instru珲es/Texto de responsabilidade do benefici醨io",oFont8)
	ElseIf ITAU
		o_Say  (2730,100 ,"Instru珲es (Instru珲es de responsabilidade do benefici醨io. Qualquer d鷙ida sobre este boleto, contate o benefici醨io)",oFont8)
	Else
		o_Say  (2730,100 ,"Instru珲es/Texto de responsabilidade do cedente",oFont8)
	EndIf
	For nBol := 1 To 6
		If Len(aBolText) >= nBol
			o_Say  (2750+(40*nBol),100 ,aBolText[nBol],oFont09)
		Endif
	Next nBol

	o_Say  (2730,1910,"(-)Desconto/Abatimento"                         	,oFont8) 
	o_Say  (2800,1910,"(-)Outras Dedu珲es"                             	,oFont8)
	o_Say  (2870,1910,"(+)Mora/Multa"                                 	,oFont8)
	o_Say  (2940,1910,"(+)Outros Acr閟cimos"                           	,oFont8)
	o_Say  (3010,1910,"(=)Valor Cobrado"                               	,oFont8)
	
	o_Say  (3080,100 ,cLabSaca                                        	,oFont8) //Sacado ou Pagador
	o_Say  (3108,210 ,aDatSacado[1]+" ("+aDatSacado[2]+")"             	,oFont8)
	o_Say  (3148,210 ,aDatSacado[3]                                   	,oFont8)
	o_Say  (3188,210 ,aDatSacado[6]+"  "+aDatSacado[4]+" - "+aDatSacado[5]	,oFont8)
	
	o_Say  (3228,100 ,"Sacador/Avalista"                               	,oFont8)   
	o_Say  (3270,1500,"Autentica玢o Mec鈔ica -"                        	,oFont8)  
	o_Say  (3270,1850,"Ficha de Compensa玢o"                           	,oFont10)
	
	o_Line(2390,1900,3080,1900)
	o_Line(2800,1900,2800,2300)
	o_Line(2870,1900,2870,2300)
	o_Line(2940,1900,2940,2300)
	o_Line(3010,1900,3010,2300)  
	o_Line(3080,100 ,3080,2300)
	
	o_Line (3265,100,3265,2300)
	
	If _MV_PAR23 == 1 //Se for imprimir em tela
   		MSBAR("INT25"  ,27.9,1.3,CB_RN_NN[1],oPrint,.F.,,,0.025,1.3,,,,.F.)
	Else
		nPosicao := 3285/1.2 //788
		nColBar  := 150 //30
		nWidth   := 0.80
		nHeigth  := 36
		oPrint:Int25(nPosicao,nColBar,CB_RN_NN[1],nWidth,nHeigth,.F.,.F.)
	Endif
	
	/*
	北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?
	北谀哪哪哪哪穆哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪勘?
	北砅arametros?01 cTypeBar String com o tipo do codigo de barras          潮?
	北?         ?            "EAN13","EAN8","UPCA" ,"SUP5"   ,"CODE128"     潮?
	北?         ?            "INT25","MAT25,"IND25","CODABAR" ,"CODE3_9"    潮?
	北?         ?02 nRow     Numero da Linha em centimentros                潮?
	北?         ?03 nCol     Numero da coluna em centimentros               潮?
	北?         ?04 cCode    String com o conteudo do codigo                潮?
	北?         ?05 oPr      Objeto Printer                                 潮?
	北?         ?06 lcheck   Se calcula o digito de controle                潮?
	北?         ?07 Cor      Numero  da Cor, utilize a "common.ch"          潮?
	北?         ?08 lHort    Se imprime na Horizontal                       潮?
	北?         ?09 nWidth   Numero do Tamanho da barra em centimetros      潮?
	北?         ?10 nHeigth  Numero da Altura da barra em milimetros        潮?
	北?         ?11 lBanner  Se imprime o linha em baixo do codigo          潮?
	北?         ?12 cFont    String com o tipo de fonte                     潮?
	北?         ?13 cMode    String com o modo do codigo de barras CODE128  潮?
	北滥哪哪哪哪牧哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪俦?
	北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?
	哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌?
	*/
	      
	oPrint:EndPage() // Finaliza a pagina
		
Return Nil

//------------------------------------------------------------------------------------
// Calcula modulo 10 
//------------------------------------------------------------------------------------
Static Function Modulo10(cData)
	
	Local L,D,P	:= 0
	Local B    	:= .F.
	
   L := Len(cData)
   B := .T.
   D := 0
   
   While L > 0 
      P := Val(SubStr(cData, L, 1))
      If (B) 
         P := P * 2
         If P > 9 
            P := P - 9
         End
      End
      D := D + P
      L := L - 1
      B := !B
   End
   
   D := 10 - (Mod(D,10))
   
   If D = 10
      D := 0
   End
   
Return(D)

//------------------------------------------------------------------------------------
// Calcula modulo 11 
//------------------------------------------------------------------------------------
Static Function Modulo11(cData,cBanc,cCarteira,xNC)
	
	Local L, D, P := 0
	  
	If cBanc == "001" //Banco do Brasil
	   L := Len(cdata)
	   D  := 0
	   DS := 0
	   P := 6
	   X := 0
       for X=1 to L
	      P := P + 1
	      if P = 10
	         P := 2
	      end 

	      DS := DS + (Val(SubStr(cData, X, 1)) * P)
	      //L := L - 1
	   next
	   
	   D := int( (DS / 11) )
	   D := DS - (D * 11)
	   
	   If D == 10
	      D := "X"
	   Else
	      D := AllTrim(Str(D))
	   End        
	  
	ElseIf cBanc == "237" //Bradesco
		
	    nSoma1 := val(subs(cCarteira,01,1))*2
	    nSoma2 := val(subs(cCarteira,02,1))*7
	    nSoma3 := val(subs(cData,01,1))   *6
	    nSoma4 := val(subs(cData,02,1))   *5
	    nSoma5 := val(subs(cData,03,1))   *4
	    nSoma6 := val(subs(cData,04,1))   *3
	    nSoma7 := val(subs(cData,05,1))   *2
	    nSoma8 := val(subs(cData,06,1))   *7
	    nSoma9 := val(subs(cData,07,1))   *6
	    nSomaA := val(subs(cData,08,1))   *5
	    nSomaB := val(subs(cData,09,1))   *4
	    nSomaC := val(subs(cData,10,1))   *3
	    nSomaD := val(subs(cData,11,1))   *2
	        
	    cDigito := mod(nSoma1+nSoma2+nSoma3+nSoma4+nSoma5+nSoma6+nSoma7+nSoma8+nSoma9+nSomaA+nSomaB+nSomaC+nSomaD,11)
	    
	    D := iif(cDigito == 1, "P", iif(cDigito == 0 , "0", strzero(11-cDigito,1)))
    
   ElseIf cBanc $ "422/104" //SAFRA ou CAIXA (CEF)
   
		nCnt	:= 0
		cDigito:= 0
		nSoma	:= 0
		nBase	:= 0
		aPeso	:= {9,8,7,6,5,4,3,2}; 
		
		nBase := Len(aPeso)+1
		
		FOR nCnt := Len(cData) TO 1 STEP -1
			nBase := IF(--nBase = 0,Len(aPeso),nBase)
			nSoma += Val(SUBS(cData,nCnt,01)) * aPeso[nBase]
		NEXT
		
		nResto	:= (nSoma % 11)  
		
		cDigito := 11 - nResto

		DO CASE
			CASE cBanc == "104" //CAIXA
				cDigito := If(cDigito > 9 .or. cDigito < 0 , "0" , STR( cDigito, 1, 0 ) )			
			CASE nResto = 1
				cDigito := "0"
			CASE nResto = 0 
				cDigito := "1"
			CASE cDigito > 9
				cDigito := "1"
			OTHERWISE
				cDigito := STR( cDigito, 1, 0 )
		ENDCASE
        
		D := cDigito   
    
   ElseIf cBanc $ "341/655" //ITAU ou VOTORANTIM
   
		nCnt	:= 0
		cDigito:= 0
		nSoma	:= 0
		nBase	:= 0
		aPeso	:= {9,8,7,6,5,4,3,2}; 
		
		nBase := Len(aPeso)+1
		
		FOR nCnt := Len(cData) TO 1 STEP -1
			nBase := IF(--nBase = 0,Len(aPeso),nBase)
			nSoma += Val(SUBS(cData,nCnt,01)) * aPeso[nBase]
		NEXT
		
		cDigito := 11 - (nSoma % 11)  

		DO CASE
			CASE cDigito = 0
				cDigito := "1"
			CASE cDigito > 9
				cDigito := "1"
			OTHERWISE
				cDigito := STR( cDigito, 1, 0 )
		ENDCASE
        
		D := cDigito
      
	ElseIf cBanc == "479"
	   L := Len(cdata)
	   D := 0
	   P := 1
	   While L > 0 
	      P := P + 1
	      D := D + (Val(SubStr(cData, L, 1)) * P)
	      If P = 9 
	         P := 1
	      End
	      L := L - 1
	   End
	   D := Mod(D*10,11)
	   If D == 10
	      D := 0
	   End
	   D := AllTrim(Str(D))
	   
	ElseIf cBanc == "033"
		L := Len(cdata)
		D := 0
		P := 1
		While L > 0
			P := P + 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
			If P = 9
				P := 1
			End
			L := L - 1
		End
		R := (mod(D,11))	
		Do Case
			Case R == 10
				D := 1
			Case R == 0
				D := 0
			Case R == 1
				D := 0
			OtherWise
				D := (11 - R )
		EndCase
		D := AllTrim(Str(D))
	
	ElseIf cBanc == "041" .or. cBanc == "399"

		L := Len(cdata)
		D := 0
		P := 1
		R   := 0
		While L > 0
			P := P + 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
			If P = 7
				P := 1
			End
			L := L - 1
		End
		R := (mod(D,11))
		Do Case
			Case R == 0
				D := 0
			Case R == 1
				If cBanc == "399"
					D := 0
				ElseIf Valtype(xNC) <> "C"
					D := 1
				Else
					D := (11 - R )
				Endif
			OtherWise
				D := (11 - R )
		EndCase
		
		If D == 10 //Quando o RESTO for igual a 1, o Digito automaticamente ser?10 (invalido). Sendo assim, o primeiro NC ser?incrementado e o modulo11 refeito.
			Return "ERRO"			
		Endif
		D := AllTrim(Str(D))
	Else
	   L := Len(cdata)
	   D := 0
	   P := 1
	   While L > 0 
	      P := P + 1
	      D := D + (Val(SubStr(cData, L, 1)) * P)
	      If P = 9 
	         P := 1
	      End
	      L := L - 1
	   End
	   D := 11 - (mod(D,11))
	   If cBanc $ "SANTANDER/CAIXA" .OR. cA6_COD == '041'
	   		IF (D == 0 .Or. D == 1 .Or. D == 10 .Or. D == 11)
	   		  D := 1
		   End
	   Else
		   If (D == 10 .Or. D == 11)
		      D := 1
		   End
	   Endif
	   D := AllTrim(Str(D))
	Endif
	   
Return(D)   

//------------------------------------------------------------------------------------
//Retorna os strings para inpress鉶 do Boleto
//CB = String para o c骴.barras, RN = String com o n鷐ero digit醰el
//Cobran鏰 n鉶 identificada, n鷐ero do boleto = T韙ulo + Parcela
//------------------------------------------------------------------------------------
Static Function Ret_cBarra(cBanco,cAgencia,cConta,cDacCC,cCarteira,cNroDoc,nValor,dvencimento,cConvenio,cSequencial,cCarBank)
	
	Local cCodEmp 		:= StrZero(Val(SubStr(cConvenio,1,7)),7)
	Local cNumSeq 		:= Strzero(val(cSequencial),nTam_NN)
	Local bldocnufinal 	:= Strzero(val(cNroDoc),9)
	Local blvalorfinal 	:= Strzero(Round(nValor,2)*100,10) //strzero(int(nValor*100),10)
	Local cNNumSDig 	:= cCpoLivre := cCBSemDig := cCodBarra := cNNum := cFatVenc := ''
	Local cDvn          := " "
	Local cDvnNN        := "  "
	
	//Tamanho do NN nos bancos:
	//	Banrisul = 8
	//	BB = 
	//	CEF = 
	//	Itau = 
	//	Bradesco = 
	//	Santander = 
	//	HSBC = 
	//	Safra = 
	//	Votorantim = 

	//Fator Vencimento - POSICAO DE 06 A 09	
	cFatVenc := STRZERO(dvencimento - CtoD("07/10/1997"),4)
	
	//Prefixo Nosso Numero
	//Nosso Numero
	cNNum := cNumSeq

	//Campo Livre (Definir campo livre com cada banco)
	If Substr(cBanco,1,3) == "001" //BB
		cCpoLivre := StrZero(0,6) + cCodEmp + cNumSeq + PadR(cCarBank,2) //cCarBank -> Carteira
		//cDvn := cValToChar(Modulo10(AllTrim(cAgencia)+AllTrim(cConta)+cCarBank+cNumSeq))
	  cDvn := cValToChar(Modulo11((AllTrim(cConvenio)+cNumSeq),SubStr(cBanco,1,3),cCarteira) )
		//6 + 7 + 10 + 2 = 25
	ElseIf Substr(cBanco,1,3) == "237" //BRADESCO
		cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3),cCarteira)
		cCpoLivre := StrZero(Val(cAgencia),4) + cCarteira + cNumSeq + StrZero(Val(cConta),7) + "0"
		//4 + 2 + 11 + 8 = 25
	ElseIf SubStr(cBanco,1,3) $ "341/655" //ITAU ou VOTORANTIM
		cDvn := cValToChar(Modulo10(AllTrim(cAgencia)+AllTrim(cConta)+cCarBank+cNumSeq))
		cDvC := cValToChar(Modulo10(AllTrim(cAgencia)+AllTrim(cConta)))
		cCpoLivre := Alltrim(cCarBank) + cNumSeq + cDvn + strzero(val(cAgencia),4)+AllTrim(cConta)+cDvC+"000"
		//2 + 8 + 1 + 4 + 10 = 25
	ElseIf SubStr(cBanco,1,3) == "422" //SAFRA
		cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3))
		cCpoLivre := "7" + PadL( Strzero(Val(cAgencia),5)+ PadL(AllTrim(cConta)+cDacCC,9,"0") , 14 ) + cNumSeq + cDvn + "2"
		cCpoLivre := StrTran(cCpoLivre," ","0")
		//1 + 14 + 8 + 2 = 25
	ElseIf SubStr(cBanco,1,3) == "033" //SANTANDER
		cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3))
		cCpoLivre := "9" + cCodEmp + ALLTRIM(STRTRAN(cNumSeq,"-","")) + cDvn + "0" + cCarBank
		//1 + 7 + 12 + 1 + 1 + 3 = 25
	ElseIf SubStr(cBanco,1,3) == "104" //CAIXA E.F.
		/*
		10 - Nosso Numero sem digito verificador (nosso n鷐ero deve come鏰r sempre com 9 no cad. parametro do banco)
		04 - Agencia
		04 - Operacao
		07 - Codigo Cedente
		Total 25
		*/
		cCpoLivre := cNumSeq + Strzero(Val(cAgencia),4) + "8700" + cCodEmp
		//MsgInfo(cCpoLivre)
		cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3))
	ElseIf SubStr(cBanco,1,3) == "399" //HSBC
		cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3))
		cCpoLivre := cNumSeq + cDvn + Strzero(Val(cAgencia),4)+ StrZero(Val(Alltrim(cConta)+Alltrim(cDacCC)),7) + "00" + "1"
		//10 + 1 + 4 + 7 + 2 + 1 = 25
	ElseIf SubStr(cBanco,1,3) == "041" //BANRISUL
		/*
		Posi玢o 20 a 20 Produto:
		"1" Cobran鏰 Normal, Fich醨io emitido pelo BANRISUL
		"2" Cobran鏰 Direta, Fich醨io emitido pelo CLIENTE.
		Posi玢o 21 a 21 Constante "1"
		Posi玢o 22 a 25 Ag阯cia com quatro d韌itos, sem o N鷐ero de Controle
		Posi玢o 26 a 32	C骴igo do Cedente sem N鷐ero de Controle.
		Posi玢o 33 a 40	Nosso N鷐ero sem N鷐ero de Controle.
		Posi玢o 41 a 42	Constante "40".
		Posi玢o 43 a 44	Duplo D韌ito referente 鄐 posi珲es 20 a 42 (m骴ulos 10 e 11).
		*/
		
		cCL := "2"+"1"+StrZero(Val(cAgencia),4)+SUBSTR(cConvenio,1,7)+cNumSeq+"40"
		nNc1 := cValToChar(Modulo10(Alltrim(cCL)))
		nNc2 := Modulo11(cCL+AllTrim(nNc1),"041",,"NC")
		While .T.
			If nNc2 == "ERRO" //Quando o RESTO for igual a 1, o Digito automaticamente ser?10 (invalido). Sendo assim, o primeiro NC ser?incrementado e o modulo11 refeito.
				If Val(nNc1) >= 9
					nNc1 := "0"
				Else
					nNc1 := StrZero(Val(nNc1)+1,1)
				Endif
				nNc2 := Modulo11(cCL+AllTrim(nNc1),"041",,"NC")
			Else
				Exit
			Endif
		End
		cCpoLivre := cCL+AllTrim(nNc1)+AllTrim(nNc2)
		
		//Complemento do Nosso Numero
		nNcNN1 := cValToChar(Modulo10(Alltrim(cNumSeq)))
		nNcNN2 := Modulo11(cNumSeq+AllTrim(nNcNN1),"041",,"NC")
		While .T.
			If nNcNN2 == "ERRO" //Quando o RESTO for igual a 1, o Digito automaticamente ser?10 (invalido). Sendo assim, o primeiro NC ser?incrementado e o modulo11 refeito.
				If Val(nNcNN1) >= 9
					nNcNN1 := "0"
				Else
					nNcNN1 := StrZero(Val(nNcNN1)+1,1)
				Endif
				nNcNN2 := Modulo11(cNumSeq+AllTrim(nNcNN1),"041",,"NC")
			Else
				Exit
			Endif
		End
		cDvnNN := AllTrim(nNcNN1) + AllTrim(nNcNN2)
	Else
		cCpoLivre := ""
	Endif
	
	//Dados para Calcular o Dig Verificador Geral
	cCBSemDig := cBanco + cFatVenc + blvalorfinal + cCpoLivre
	
	//Codigo de Barras Completo
	cCodBarra := cBanco +  Modulo11(cCBSemDig, If(SANTANDER .OR. CAIXAEF,"SANTANDER/CAIXA","SEM_BANCO")) + cFatVenc + blvalorfinal + cCpoLivre
	//4 + 1 + 4 + 10 + 6 + 7 + 10 + 2
	//MsgInfo(cCodBarra)
	//Digito Verificador do Primeiro Campo                  
	cPrCpo := cBanco + SubStr(cCodBarra,20,5)
	cDvPrCpo := AllTrim(Str(Modulo10(cPrCpo)))
	
	//Digito Verificador do Segundo Campo
	cSgCpo := SubStr(cCodBarra,25,10)
	cDvSgCpo := AllTrim(Str(Modulo10(cSgCpo)))
	
	//Digito Verificador do Terceiro Campo
	cTrCpo := SubStr(cCodBarra,35,10)
	cDvTrCpo := AllTrim(Str(Modulo10(cTrCpo)))
	
	//Digito Verificador Geral
	cDvGeral := SubStr(cCodBarra,5,1)
	
	//Linha Digitavel
	cLindig := SubStr(cPrCpo,1,5) + "." + SubStr(cPrCpo,6,4) + cDvPrCpo + " "   //primeiro campo
	cLinDig += SubStr(cSgCpo,1,5) + "." + SubStr(cSgCpo,6,5) + cDvSgCpo + " "   //segundo campo
	cLinDig += SubStr(cTrCpo,1,5) + "." + SubStr(cTrCpo,6,5) + cDvTrCpo + " "   //terceiro campo
	cLinDig += " " + cDvGeral              //dig verificador geral
	cLinDig += "  " + SubStr(cCodBarra,6,4)+SubStr(cCodBarra,10,10)  // fator de vencimento e valor nominal do titulo

	If SubStr(cBanco,1,3) == "041" 
		Return({cCodBarra,cLinDig,cSequencial,cDvnNN})
	Endif

Return({cCodBarra,cLinDig,cNNum+PadR(cDvn,1),"  " })
                                        
/*/
苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘?
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?
北赏屯屯屯屯脱屯屯屯屯屯送屯屯屯淹屯屯屯屯屯屯屯屯屯退屯屯屯淹屯屯屯屯屯屯槐?
北篎un噭o    砎ALIDPERG ?Autor ?AP5 IDE            ?Data ? 07/04/03   罕?
北掏屯屯屯屯拓屯屯屯屯屯释屯屯屯贤屯屯屯屯屯屯屯屯屯褪屯屯屯贤屯屯屯屯屯屯贡?
北篋escri噭o ?Verifica a existencia das perguntas criando-as caso seja   罕?
北?         ?necessario (caso nao existam).                             罕?
北掏屯屯屯屯拓屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯贡?
北篣so       ?Programa principal                                         罕?
北韧屯屯屯屯拖屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯急?
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?
哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌?
/*/

Static Function ValidPerg()
	
	PutSx1(cPerg,"01","Do Prefixo:"				,"","","mv_ch1" ,"C",03,0,0,"G","",""		,"","","mv_par01",""  				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"02","Ate o Prefixo:"			,"","","mv_ch2" ,"C",03,0,0,"G","",""		,"","","mv_par02",""  				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"03","Do Titulo:"				,"","","mv_ch3" ,"C",09,0,0,"G","",""		,"","","mv_par03",""				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"04","Ate o Titulo:"			,"","","mv_ch4" ,"C",09,0,0,"G","",""		,"","","mv_par04",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"05","Da Parcela:"				,"","","mv_ch5" ,"C",02,0,0,"G","",""		,"","","mv_par05",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"06","Ate a Parcela:"			,"","","mv_ch6" ,"C",02,0,0,"G","",""		,"","","mv_par06",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"07","Do Banco:"				,"","","mv_ch7" ,"C",03,0,0,"G","","SA6"	,"","","mv_par07",""   				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"08","Agencia:"				,"","","mv_ch8" ,"C",05,0,0,"G","",""		,"","","mv_par08",""   				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"09","Conta:"					,"","","mv_ch9" ,"C",10,0,0,"G","",""		,"","","mv_par09",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"10","SubConta:" 				,"","","mv_ch10","C",03,0,0,"G","",""		,"","","mv_par10",""  				,"","","","" 			,"","","","","","","","","","","")
	PutSx1(cPerg,"11","Do Cliente:"				,"","","mv_ch11","C",06,0,0,"G","","SA1"	,"","","mv_par11",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"12","Ate o Cliente:"			,"","","mv_ch12","C",06,0,0,"G","","SA1"	,"","","mv_par12",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"13","Da Loja:"				,"","","mv_ch13","C",02,0,0,"G","",""		,"","","mv_par13",""   				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"14","Ate a Loja:"				,"","","mv_ch14","C",02,0,0,"G","",""		,"","","mv_par14",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"15","Da Dt. Venc.:"			,"","","mv_ch15","D",08,0,0,"G","",""		,"","","mv_par15",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"16","Ate a Dt. Venc:"			,"","","mv_ch16","D",08,0,0,"G","",""		,"","","mv_par16",""  				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"17","Da Dt. Emissao:"			,"","","mv_ch17","D",08,0,0,"G","",""		,"","","mv_par17",""   				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"18","Ate a Dt. Emis:"			,"","","mv_ch18","D",08,0,0,"G","",""		,"","","mv_par18",""   				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"19","Do bordero:"				,"","","mv_ch19","C",06,0,0,"G","",""		,"","","mv_par19",""				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"20","Ate o Bordero:"			,"","","mv_ch20","C",06,0,0,"G","",""		,"","","mv_par20",""				,"","","",""			,"","","","","","","","","","","")
	PutSx1(cPerg,"21","Selecionar titulos:"		,"","","mv_ch21","N",01,0,0,"C","",""		,"","","mv_par21","Sim"				,"","","","N鉶"			,"","","","","","","","","","","")
	PutSx1(cPerg,"22","Gerar Bordero:"			,"","","mv_ch22","N",01,0,0,"C","",""		,"","","mv_par22","Sim"				,"","","","N鉶"			,"","","","","","","","","","","")
	PutSx1(cPerg,"23","Forma de Impress鉶:"		,"","","mv_ch23","N",01,0,0,"C","",""		,"","","mv_par23","Tela"			,"","","","Arquivo PDF"	,"","","Enviar E-mail","","","","","","","","")
	PutSx1(cPerg,"24","Diret髍io Local p/ PDF:" ,"","","mv_ch24","C",30,0,0,"G","",""		,"","","mv_par24",""				,"","","c:\temp\boletos_totvs\",""			,"","","","","","","","","","","")
Return

Static Function VerParam(mensagem)
	Alert(mensagem)
	U_BOLETOACTVS()
Return
                
//Busca um bordero com a data atual que n鉶 tenha sido transferido
Static Function BuscaBorde()  

	Local cRet	:= ""
	Local cQuery:= ""
	Local Temp
	Local cIniBord := "A00001"
	
	cQuery += "Select EA_NUMBOR From "	+ RetSqlName("SEA")	+ " As SEA "
	cQuery += "Where SEA.EA_AGEDEP = '"	+ _MV_PAR08 		+ "' " 
	cQuery += "And SEA.EA_NUMCON = '" 	+ _MV_PAR09 		+ "' " 
	cQuery += "And SEA.EA_PORTADO = '" 	+ _MV_PAR07 		+ "' "
	cQuery += "And SEA.EA_SUBCTA = '" 	+ _MV_PAR10 		+ "' "
	cQuery += "And SEA.EA_FILIAL = '" 	+ xFilial("SEA") 	+ "' "
	cQuery += "And SEA.EA_DATABOR = '" 	+ dToS(dDataBase) 	+ "' "
	cQuery += "And SEA.EA_TRANSF = '' "
	cQuery += "And SEA.EA_CART = 'R' "
	cQuery += "And SEA.EA_NUMBOR <> '' "
	cQuery += "And SEA.D_E_L_E_T_ = '' " 

	TCQUERY cQuery NEW ALIAS (Temp:=GetNextAlias())
	
	While (Temp)->(!EoF())
		cRet := (Temp)->EA_NUMBOR
		(Temp)->(DbSkip())
	EndDo
	
	(Temp)->(DbCloseArea())
	
Return cRet



Static Function o_Say(xPar1,xPar2,xPar3,xPar4,xPar5,xPar6, xPar7, xPar8, xPar9)
Local nWidht
If ValType(xPar8) <> "N"
	//Imprimir alinhado a esquerda
	oPrint:Say( nAddSay+(xPar1*nFatorV) , xPar2*nFatorH , xPar3, xPar4, xPar5 )
Else
	//Imprimir alinhado a direita
	nWidht := oPrint:GetTextWidth(xPar3,xPar4)
	oPrint:Say( nAddSay+(xPar1*nFatorV) , (xPar2-nWidht+60)*nFatorH , xPar3, xPar4, xPar5 )
Endif
Return

Static Function o_Line(xPar1,xPar2,xPar3,xPar4)
oPrint:Line( nAddLin+(xPar1*nFatorV) , xPar2*nFatorH , nAddLin+(xPar3*nFatorV) , xPar4*nFatorH )
Return

Static Function o_SayBitMap(xPar1,xPar2,xPar3,xPar4,xPar5)
oPrint:SayBitMap( 40+(xPar1*nFatorV) , xPar2*nFatorH , xPar3 , xPar4 , xPar5 )
Return

/*/
苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘?
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?
北赏屯屯屯屯脱屯屯屯屯屯送屯屯屯淹屯屯屯屯屯屯屯屯屯退屯屯屯淹屯屯屯屯屯屯槐?
北篎un噭o    ?EnvEmail ?Autor ?Rubem Cerqueira    ?Data ? 07/07/17   罕?
北掏屯屯屯屯拓屯屯屯屯屯释屯屯屯贤屯屯屯屯屯屯屯屯屯褪屯屯屯贤屯屯屯屯屯屯贡?
北篋escri噭o ?Envio de boleto em PDF por email.                          罕?
北掏屯屯屯屯拓屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯贡?
北篣so       ?Programa principal                                         罕?
北韧屯屯屯屯拖屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯急?
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?
哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌?
/*/




Static Function EnvEmail(cFatura)
	
	
	local oServer  := Nil
	local oMessage := Nil
	local nErr     := 0
	local cPopAddr  := "pop.example.com"      // Endereco do servidor POP3
	local cSMTPAddr := "smtp.zoho.com"     // Endereco do servidor SMTP
	local cPOPPort  := 110                    // Porta do servidor POP
	local cSMTPPort := 465                    // Porta do servidor SMTP
	local cUser     := "financeiro2@cekacessorios.com.br"     // Usuario que ira realizar a autenticacao
	local cPass     := "CeK#finan02"             // Senha do usuario
	local nSMTPTime := 60                     // Timeout SMTP
	Local cMsg := ""
	Local xRet
	
	Local cLocal := "\Boletos\"+cFatura+".PDF"

	// Instancia um novo TMailManager
	oServer := tMailManager():New()
	
	// Usa SSL na conexao
	oServer:setUseSSL(.T.)
	
	// Inicializa
	oServer:init(cPopAddr, cSMTPAddr, cUser, cPass, cPOPPort, cSMTPPort)
	
	// Define o Timeout SMTP
	if oServer:SetSMTPTimeout(nSMTPTime) != 0
		conout("[ERROR]Falha ao definir timeout")
		return .F.
	endif
	
	// Conecta ao servidor
	nErr := oServer:smtpConnect()
	if nErr <> 0
		conOut("[ERROR]Falha ao conectar: " + oServer:getErrorString(nErr))
		oServer:smtpDisconnect()
		return .F.
	endif
	
	// Realiza autenticacao no servidor
	nErr := oServer:smtpAuth(cUser, cPass)
	if nErr <> 0
		conOut("[ERROR]Falha ao autenticar: " + oServer:getErrorString(nErr))
		oServer:smtpDisconnect()
		return .F.
	endif
	
	// Cria uma nova mensagem (TMailMessage)
	oMessage := tMailMessage():new()
	oMessage:clear()
	oMessage:cFrom    	:= "financeiro2@cekacessorios.com.br"
	oMessage:cTo      	:= SA1->A1_E_FIN
	//oMessage:cTo      	:= "rubem.cerqueira@totvs.com.br"
	oMessage:cSubject  	 :=  "Informe de emissao de boleto: "+(cAliasSE1)->E1_NUM

	//oMessage:cSubject := "SOLICITA敲O DE CERTIFICADO DE CONTE贒O LOCAL Ped. Cliente .: " + AllTrim(SC6->C6_PEDCLI) + " - NFe .: " + AllTrim(SC6->C6_NOTA)
	oMessage:cBody    := fHTML()
	xRet := oMessage:AttachFile(cLocal)
	oMessage:SetConfirmRead( .T. )
	
	if xRet < 0
		cMsg := "Could not attach file " + cLocal
		conout( cMsg )
		return
	endif
	
	
	// Envia a mensagem
	nErr := oMessage:send(oServer)
	if nErr <> 0
		conout("[ERROR]Falha ao enviar: " + oServer:getErrorString(nErr))
		oServer:smtpDisconnect()
		return .F.
	endif
	
	// Disconecta do Servidor
	oServer:smtpDisconnect()
		
		
	//Apagar
	if(File("\Boletos\"+cFatura+".PDF"))
		
		fErase("\Boletos\"+cFatura+".PDF")
		
	Endif
		
	
Return .T.

Static Function fHTML()

	Local cHTML := ""
	cHTML := "Prezado Cliente, <br><br>"
	cHTML += "Segue em anexo boleto de documento emitido por " + Alltrim(SM0->M0_NOMECOM)+". <br>"
	cHTML += "Em caso de d鷙idas, entrar em contato com a nossa cobran鏰 atrav閟 do n鷐ero (47) 3466-1384 ou via email financeiro2@cekacessorios.com.br <br><br><br>"
	

Return cHTML

