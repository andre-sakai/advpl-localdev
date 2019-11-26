#INCLUDE "FINA380.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWCOMMAND.CH"
#INCLUDE "FWMVCDEF.CH"

Static lFWCodFil := .T.

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³ FinA380	³ Autor ³ Pilar S. Albaladejo   ³ Data ³ 24/10/94 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Reconciliacao Banc ria									  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FinA380()												  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ Generico 												  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/                           
User Function pinA380(nPosArotina)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿       
//³ Define Variaveis 									    	 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

LOCAL nSavRec		:= RecNO()
Local lPanelFin		:= IsPanelFin()

PRIVATE aRotina		:= MenuDef()
PRIVATE cBco380		:= CriaVar("E5_BANCO")
PRIVATE cAge380		:= CriaVar("E5_AGENCIA")
PRIVATE cCta380		:= CriaVar("E5_CONTA")
PRIVATE dIniDt380	:= dDataBase
PRIVATE dFimDt380	:= dDataBase
PRIVATE nQtdTitP	:= 0
PRIVATE nQtdTitR	:= 0
PRIVATE nValRec		:= 0
PRIVATE nValPag		:= 0

PRIVATE lFa380		:= ExistBlock("F380RECO",.F.,.F.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Define o cabecalho da tela de baixas								  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PRIVATE cCadastro := OemToAnsi(STR0003) // "Reconcilia‡„o Banc ria"

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Recupera o desenho padrao de atualizacoes						  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PRIVATE cFil380 // Variavel destinada a complementação do filtro atrves de ponto de entrada

dbSelectArea("SE5")
dbSetOrder(1)
dbSeek(xFilial("SE5"))

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Chamada da funcao pergunte                                   ³
//³ mv_par01 - Visibilidade                                      ³
//³          1 - Todos                                           ³
//³          2 - Nao Conciliados                                 ³
//³          3 - Conciliados                                     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
SetKey (VK_F12,{|a,b| AcessaPerg("FIN380",.T.)})
pergunte("FIN380",.F.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Endereca a Fun‡„o de BROWSE											  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

DEFAULT nPosArotina := 0
If nPosArotina > 0 // Sera executada uma opcao diretamento de aRotina, sem passar pela mBrowse
	dbSelectArea("SE5")
	bBlock := &( "{ |a,b,c,d,e| " + aRotina[ nPosArotina,2 ] + "(a,b,c,d,e) }" )
	Eval( bBlock, Alias(), (Alias())->(Recno()),nPosArotina)
Else
	mBrowse( 6, 1,22,75,"SE5",,,,,,F380Legenda())
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Recupera a Integridade dos dados									  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea("SE5")
dbSetOrder(1)
dbGoTo( nSavRec )

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³ fA380Rec ³ Autor ³ Pilar S. Albaladejo   ³ Data ³ 24/10/94 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Escolha dos itens para reconciliacao bancaria			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ Fa380Rec()												  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ Generico 												  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function A380Rec(cAlias,cCampo,nOpcE,lCtrlCheq)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Define Variaveis 														  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local lPanelFin		:= IsPanelFin()
LOCAL nSldIniRec	:= 0		/*nSaldoIni Saldo anterior (Reconciliados)*/
LOCAL nSldFinRec	:= 0		/*nSaldoAtu Saldo atual (Reconciliados)*/
LOCAL nSldIniBanc	:= 0		/*nSaldoGer Saldo anterior (Bancario)*/
LOCAL nSldFinBanc	:= 0		/*Saldo Atual (Bancario)*/
Local nOpca 		:= 0
LOCAL cIndex		:= ""
LOCAL aStruct		:= {}
LOCAL dDTLimRec		:= GetMV("MV_DATAREC")
Local lF380Grv		:= ExistBlock("F380GRV",.F.,.F.)
LOCAL aCampos		:= {}
LOCAL oDlg			:= NIL
LOCAL oQtdaP		:= NIL
LOCAL oQtdaR		:= NIL
LOCAL oValRec		:= NIL
LOCAL oValPag		:= NIL
LOCAL oValIni		:= NIL
Local oValAtu		:= NIL
Local oValRecT		:= NIL
Local oValGer		:= NIL
LOCAL oMark			:= 0
LOCAL lInverte		:= .f.
Local lAtuSaldo		:= .F.
Local lAtSalRec1	:= .F.
Local lAtSalRec2	:= .F.
Local nReconc		:= 0
Local cReconAnt		:= ""
Local aSize			:= {}
Local oPanel		:= NIL
Local cKeyCheque	:= ""  
Local lAltDt		:= .T.
Local aButtons		:= {}
Local lSaldoAtu		:= .F.
Local aArea			:= {}
Local nLinha		:= 0
Local nSize			:= 0
Local aColuna		:= {}
Local lF380VLD		:= ExistBlock("F380VLD",.F.,.F.) 
LOCAL lL380VLD		:= .F.
Local lF380AlDt 	:= ExistBlock("F380AlDt")
Local nPosVlr		:= 0
Local nValTit		:= 0
Local nTamFil		:= 0
Local nTamKey  	:= 0
Local nTamTipo   	:= 0
/*
Gestao - inicio */
Local cFilAtu		:= cFilAnt
Local lOK			:= .F.
/* GESTAO - fim
*/
Local oModelMov := NIL 		//FWLoadModel("FINM030")
Local oSubFK5	:= NIL
Local oSubFKA	:= NIL
Local cCamposE5 := ""
Local lRet		:= .T.
Local cIdProc	 := "" 
Local cGeraFK6  := 'C2|CM|CX|DC|J2|JR|M2|MT|VM'
Default lCtrlCheq:=.F.
PRIVATE cIndexSE5 := ""
PRIVATE cMarca	 := GetMark()

If !CtbValiDt(,dDataBase,,,,{"FIN001","FIN002"},)
	Return
EndIf
	
If cPaisLoc == "BRA"
   aCampos	 := { { "E5_OK"  		     ,, OemToAnsi(STR0004) },; //"Rec."      
					    { "E5_FILIAL"    ,, STR0080 },; 		 //"Filial"
						{ "E5_DTDISPO"   ,, STR0067},; 		 //"DT Disponivel"
						{ "E5_MOEDA"     ,, OemToAnsi(STR0006)},; //"Numer rio"
						{ "E5_VALOR"     ,, OemToAnsi(STR0007),PesqPict("SE5","E5_VALOR",19)},; //"Vlr. Movimen."
						{ "E5_NATUREZ"   ,, OemToAnsi(STR0008)},; //"Natureza"
						{ "E5_BANCO"     ,, OemToAnsi(STR0009)},; //"Banco"
						{ "E5_AGENCIA"   ,, OemToAnsi(STR0010)},; //"Agˆncia"
						{ "E5_CONTA"     ,, OemToAnsi(STR0011)},; //"Conta"
						{ "E5_NUMCHEQ"   ,, OemToAnsi(STR0012)},; //"Num. Cheque"
						{ "E5_DOCUMEN"   ,, OemToAnsi(STR0013)},; //"Documento"
						{ "E5_VENCTO"    ,, OemToAnsi(STR0014)},; //"Vencimeto"
						{ "E5_DATA"		  ,, OemToAnsi(STR0005)},; //"DT Movimento"
						{ "E5_RECPAG"    ,, OemToAnsi(STR0036)},; //"Rec/Pag"
						{ "E5_BENEF"     ,, OemToAnsi(STR0015)},; //"Benefici rio"
						{ "E5_HISTOR"    ,, OemToAnsi(STR0016)},; //"Hist¢rico"
						{ "E5_CREDITO"   ,, OemToAnsi(STR0017)},;  //"Cta Cr‚dito"
						{ "E5_PREFIXO"   ,, STR0058				},;  //"Prefixo"
						{ "E5_NUMERO"    ,, STR0059				},;  //"Número"
						{ "E5_PARCELA"   ,, STR0060				},;  //"Parcela"
						{ "E5_TIPO" 	  ,, STR0061	 				},;   //"Tipo"
						{ "E5_CLIFOR"	  ,, STR0062				},;  //"Cli/For"
						{ "E5_LOJA" 	  ,, STR0063	 				}}  						 //"Loja"

Else
   aCampos	 := { { "E5_OK"  		  ,, OemToAnsi(STR0004) },; //"Rec."
						{ "E5_NUMERO"   ,, OemToAnsi(STR0040)},; //"Numero"   
						{ "E5_DTDISPO"   ,, STR0067},;  //"DT Disponivel"
						{ "E5_MOEDA"     ,, OemToAnsi(STR0006)},; //"Numer rio"
						{ "E5_VALOR"     ,, OemToAnsi(STR0007),PesqPict("SE5","E5_VALOR",19)},; //"Vlr. Movimen."
						{ "E5_NATUREZ"   ,, OemToAnsi(STR0008)},; //"Natureza"
						{ "E5_BANCO"     ,, OemToAnsi(STR0009)},; //"Banco"
						{ "E5_AGENCIA"   ,, OemToAnsi(STR0010)},; //"Agˆncia"
						{ "E5_CONTA"     ,, OemToAnsi(STR0011)},; //"Conta"
						{ "E5_NUMCHEQ"   ,, OemToAnsi(STR0012)},; //"Num. Cheque"
						{ "E5_DOCUMEN"   ,, OemToAnsi(STR0013)},; //"Documento"
						{ "E5_VENCTO"    ,, OemToAnsi(STR0014)},; //"Vencimeto"
						{ "E5_DATA"		  ,, OemToAnsi(STR0005)},; //"DT Movimento"
						{ "E5_RECPAG"    ,, OemToAnsi(STR0036)},; //"Rec/Pag"
						{ "E5_BENEF"     ,, OemToAnsi(STR0015)},; //"Benefici rio"
						{ "E5_HISTOR"    ,, OemToAnsi(STR0016)},; //"Hist¢rico"
						{ "E5_CREDITO"   ,, OemToAnsi(STR0017)}}  //"Cta Cr‚dito"
EndIf

// Permite a altera‡Æo da ordem em que os campos serÆo apresentados.
If ExistBlock("F380CPOS")
	aCampos := ExecBlock("F380CPOS", .F., .F., { aCampos } )
Endif

If lPanelFin
	lOK := PergInPanel("FIN380",.T.)
Else
	lOK := pergunte("FIN380",.T.)
Endif

While lOK
	nSldIniRec	:= 0	/*Saldo anterior (Reconciliados)*/
	nSldFinRec	:= 0	/*Saldo atual (Reconciliados)*/
	nSldIniBanc	:= 0	/*Saldo anterior (Bancario)*/
	nSldFinBanc := 0	/*Saldo Atual (Bancario)*/
	nQtdTitP	:= 0
	nQtdTitR	:= 0
	nValRec		:= 0
	nValPag		:= 0
	nValRecT	:= 0
	nValPagT	:= 0
	nOpca		:= 3

	
	aSize := MSADVSIZE()
	If cPaisLoc $ "ARG|DOM|EQU" .AND. (FUNNAME()=="FINA095" .OR. FUNNAME()=="FINA096")
	   nOpca:=1
	Else
		If lPanelFin  //Chamado pelo Painel Financeiro					
			oPanelDados := FinWindow:GetVisPanel()
			oPanelDados:FreeChildren()
			aDim := DLGinPANEL(oPanelDados)
			DEFINE MSDIALOG oDlg OF oPanelDados:oWnd FROM 0,0 To 0,0 PIXEL STYLE nOR( WS_VISIBLE, WS_POPUP )							
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Observacao Importante quanto as coordenadas calculadas abaixo: ³ 
			//³ -------------------------------------------------------------- ³ 		
			//³ a funcao DlgWidthPanel() retorna o dobro do valor da area do	 ³
			//³ painel, sendo assim este deve ser dividido por 2 antes da sub- ³
			//³ tracao e redivisao por 2 para a centralizacao. 					 ³		
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ		
			nEspLarg :=	(((DlgWidthPanel(oPanelDados)/2) - 160) /2)
			nEspLin  := 0
					
		Else   
		   	nEspLarg := 0
		  	nEspLin  := 0
			DEFINE MSDIALOG oDlg FROM	91,83 TO 278,412 TITLE cCadastro PIXEL //"Reconcili‡„o Banc ria"
		Endif   

		oDlg:lMaximized := .F.
		oPanel := TPanel():New(0,0,'',oDlg,, .T., .T.,, ,20,20)
		oPanel:Align := CONTROL_ALIGN_ALLCLIENT    		
	   
		
		@ 000+nEspLin,003+nEspLarg TO 073+nEspLin,163+nEspLarg OF oPanel  PIXEL
		
		@ 011+nEspLin,010+nEspLarg SAY OemToAnsi(STR0020) SIZE 20, 7 OF oPanel PIXEL //"Banco:"
		@ 009+nEspLin,045+nEspLarg MSGET cBco380	F3 "SA6" Picture PesqPict("SE8","E8_BANCO")  ;
										Valid If(nOpca<>0,CarregaSA6(@cBco380,,,.T.),.T.) ;
										SIZE 17, 10 OF oPanel Hasbutton PIXEL
		@ 026+nEspLin,010+nEspLarg SAY OemToAnsi(STR0021) SIZE 24, 7 OF oPanel PIXEL //"Agˆncia:"
		@ 024+nEspLin,045+nEspLarg MSGET cAge380	Picture PesqPict("SE8","E8_AGENCIA")   ;
										Valid If(nOpca<>0,CarregaSA6(@cBco380,@cAge380,,.T.),.T.) ;
										SIZE 32, 10 OF oPanel PIXEL
		@ 42+nEspLin,010+nEspLarg SAY OemToAnsi(STR0022) SIZE 20, 7 OF oPanel PIXEL //"Conta:"
		If cPaisLoc == 'CHI'
			@ 040+nEspLin,045+nEspLarg MSGET cCta380	Picture PesqPict("SE8","E8_CONTA") ; 
											Valid If(nOpca<>0,CarregaSA6(@cBco380,@cAge380,@cCta380,.T.),.T.) ;
											SIZE 67, 10 OF oPanel PIXEL
		Else 
			@ 040+nEspLin,045+nEspLarg MSGET cCta380	Picture PesqPict("SE8","E8_CONTA") ; 
											Valid If(nOpca<>0,CarregaSA6(@cBco380,@cAge380,@cCta380,.T.),.T.) ;
											SIZE 47, 10 OF oPanel PIXEL
		EndIf										
		@ 057+nEspLin,010+nEspLarg SAY OemToAnsi(STR0027) SIZE 20, 7 OF oPanel PIXEL //"De"
		@ 056+nEspLin,045+nEspLarg MSGET dIniDt380 	Picture "99/99/99" ;
											VALID If( nOpca <> 0, Iif( !lF380VLD, (dIniDt380 > dDtLimRec), .T. ), .T. ) ;
											SIZE 50, 10 OF oPanel Hasbutton PIXEL
		@ 058+nEspLin,098+nEspLarg SAY OemToAnsi(STR0024) SIZE 20, 7 OF oPanel PIXEL //"At‚"	Sergio Fuzinaka - 03.07.02
		@ 056+nEspLin,114+nEspLarg MSGET dFimDt380	Picture "99/99/99";
											VALID If( nOpca <> 0, Iif( !lF380VLD, ((dFimDt380 > dDtLimRec) .and. (dFimDt380 >= dIniDt380)), .T. ), .T.) ;
											SIZE 50, 10 OF oPanel Hasbutton PIXEL
		
		If lPanelFin //Chamado pelo Painel Financeiro			
			oDlg:Move(aDim[1],aDim[2],aDim[4]-aDim[2], aDim[3]-aDim[1])			
			ACTIVATE MSDIALOG oDlg ON INIT FaMyBar(oDlg,;
			{||nOpca:=1,oDLg:End()},{||nOpca:=0,oDlg:End()})
			
			cAlias := FinWindow:cAliasFile     
			dbSelectArea(cAlias)					
			FinVisual(cAlias,FinWindow,(cAlias)->(Recno()),.T.)
	
		Else	   
			DEFINE SBUTTON FROM 76, 104 TYPE 1 ENABLE ACTION (nOpca:=1,oDLg:End()) OF oPanel
			DEFINE SBUTTON FROM 76, 132 TYPE 2 ENABLE ACTION oDlg:End() OF oPanel
	
			ACTIVATE MSDIALOG oDlg CENTERED
		Endif
	Endif

	If nOpca == 0 .Or. nOpca == 3
		Return
	Else
		If lF380VLD
			// Se retornar falso nao continua processamento
			lL380VLD := ExecBlock("F380VLD", .F., .F., { dDtLimRec, dIniDt380, dFimDt380 } )
			
			If ValType(lL380VLD) == "L" 
				If !lL380VLD
					Loop                                                                          
				EndIf
			EndIf	
		Else
			If dIniDt380 <= dDtLimRec .Or. dFimDt380 <= dDtLimRec
				// Período informado está abaixo da data limite de Reconciliacao Bancária.
				Aviso( STR0077, STR0079, {"Ok"} )
				Exit
			EndIf
		EndIf
	EndIf
	If cPaisLoc == "BRA" .AND. (SA6->A6_MOEDA > 1)
		nPosVlr := aScan(aCampos, {|x| x[1] == "E5_VALOR"})
	Endif
	
	dbSelectArea( "SE8" )
	dbSeek( xFilial("SE8")+cBco380+cAge380+cCta380+Dtos(dIniDt380),.T. )
	dbSkip( -1 )
	
	If xFilial("SE8") != E8_FILIAL .or.  E8_BANCO != cBco380 .or. E8_AGENCIA != cAge380 .or. E8_CONTA != cCta380 .or. BOF() .or. EOF()
		nSldIniRec	:= 0					/*Saldo anterior (Reconciliados)*/
		nSldIniBanc	:= 0					/*Saldo anterior (Bancario)*/
	Else
		nSldIniBanc	:= E8_SALATUA		/*Saldo anterior*/
		nSldIniRec	:= E8_SALRECO		/*Saldo anterior (Reconciliados)*/
	End

	dbSelectArea( "SE8" )
	dbSeek( xFilial("SE8")+cBco380+cAge380+cCta380+Dtos(dFimDt380),.T. )
	
	If xFilial ("SE8") != E8_FILIAL .or. E8_BANCO != cBco380 .or. E8_AGENCIA != cAge380 .or. E8_CONTA != cCta380 .or.;	
		Dtos(dFimDt380) != DTOS(E8_DTSALAT) .or. BOF() .or. EOF()
		dbSkip(-1)  
		lSaldoAtu := ! (E8_FILIAL+E8_BANCO+E8_AGENCIA+E8_CONTA != xFilial("SE8")+cBco380+cAge380+cCta380 .or. BOF() .or. EOF())  		
	Else
		lSaldoAtu := .T.
	Endif	 
	     
	// Atualiza o valor do saldo atual
	If !lSaldoAtu
		nSldFinRec	:= 0					/*Saldo atual (Reconciliados)*/
		nSldFinBanc	:= 0					/*Saldo atual (Bancario)*/
	Else
		nSldFinBanc	:= E8_SALATUA		/*Saldo atual (Reconciliados)*/
		nSldFinRec	:= E8_SALRECO		/*Saldo atual (Reconciliados)*/
	EndIf
	
	dbSelectArea("SE5")
	cNomeArq:= CriaTrab("",.F.)
	cIndex  := cNomeArq
	cChave  := If( ExistBlock("FA380CHV"),;
						ExecBlock("FA380CHV", .F., .F.),;
						"DTOS(E5_DTDISPO)+E5_BANCO+E5_AGENCIA+E5_CONTA")
	aStruct := dbStruct()
	AAdd( aStruct, {"E5_RECNO"		,"N", 09, 0} )
	
	nTamFilName := Len(FWFilialName(cEmpAnt,cFilAnt,1))+3
	nPosFil := aScan(aStruct,{|x|x[1]=="E5_FILIAL"})
	aStruct[nPosFil][3] += nTamFilName
	
	dbCreate( cNomeArq, aStruct )
 
	USE &cNomeArq	Alias Trb  NEW
	dbSelectArea("TRB")
	IndRegua("TRB",cIndex,cChave,,,OemToAnsi(STR0028))   //"Selecionando Registros..."
	dbSetIndex( cNomeArq +OrdBagExt())
	Fa380ChecF(lCtrlCheq)
	DbSelectArea("TRB")
	dbGoTop() 
	IF BOF() .and. EOF()
		Help(" ",1,"RECNO")
		Exit
	Endif
                                                     
	If ExistBlock("F380ATR")
		ExecBlock("F380ATR",.F.,.F.)
	EndIf

	nOpca := 0


	//Faz o calculo automatico de dimensoes de objetos
	oSize := FwDefSize():New(.T.)
	
	oSize:lLateral	:= .F.
	oSize:lProp		:= .T. // Proporcional
	
	oSize:AddObject( "1STROW" ,  100, 20, .T., .T. ) // Totalmente dimensionavel
	oSize:AddObject( "2NDROW" ,  100, 80, .T., .T. ) // Totalmente dimensionavel
		
	oSize:aMargins	:= { 3, 3, 3, 3 } // Espaco ao lado dos objetos 0, entre eles 3 

	oSize:Process() // Dispara os calculos		
	
	a1stRow := {	oSize:GetDimension("1STROW","LININI"),;
					oSize:GetDimension("1STROW","COLINI"),;
					oSize:GetDimension("1STROW","LINEND"),;
					oSize:GetDimension("1STROW","COLEND")}
					
	a2ndRow := {	oSize:GetDimension("2NDROW","LININI"),;
					oSize:GetDimension("2NDROW","COLINI"),;
					oSize:GetDimension("2NDROW","LINEND"),;
					oSize:GetDimension("2NDROW","COLEND")}
	
	DEFINE MSDIALOG oDlg TITLE STR0025 From oSize:aWindSize[1],oSize:aWindSize[2] to oSize:aWindSize[3],oSize:aWindSize[4] OF oMainWnd PIXEL  //"Reconcilia‡„o Banc ria"
	oDlg:lMaximized := .T.

	//------------------------------------------------------------------------------------------------------------------------
	//Painel 1 - Informações
	//------------------------------------------------------------------------------------------------------------------------
	nLinha	:= a1stRow[1] + 3
	nSize := 90
	aColuna:={a1stRow[2],,,}
	aColuna[2]:=aColuna[1]+nSize+5
	aColuna[3]:=aColuna[2]+70
	aColuna[4]:=aColuna[3]+nSize+5
	
	@nLinha,aColuna[1] Say STR0054 + " (" + "Bancario" + ")"SIZE nSize,10 PIXEL Of oDlg		// Saldo anterior (Bancario)
	@nLinha,aColuna[2] Say oValGer VAR nSldIniBanc Picture PesqPict("SE5","E5_VALOR",19) SIZE 50,10  PIXEL Of oDlg
	@nLinha,aColuna[3] Say STR0055 + " (" + "Bancario" + ")" SIZE nSize,10 PIXEL Of oDlg		// Saldo atual (Bancario)
	@nLinha,aColuna[4] Say oValAtu  VAR nSldFinBanc Picture PesqPict("SE5","E5_VALOR",19) SIZE 50,10  PIXEL Of oDlg 
	nLinha += 9

	@nLinha,aColuna[1] Say STR0054 + " (" + STR0002 + ")" SIZE nSize,10 PIXEL Of oDlg		// Saldo anterior (Reconciliados)
	@nLinha,aColuna[2] Say oValIni  VAR nSldIniRec Picture PesqPict("SE5","E5_VALOR",19) SIZE 50,10  PIXEL Of oDlg 
	@nLinha,aColuna[3] Say STR0055 + " (" + STR0002 + ")" SIZE nSize,10 PIXEL Of oDlg		// Saldo atual (Reconciliados)
	@nLinha,aColuna[4] Say oValAtu  VAR nSldFinRec Picture PesqPict("SE5","E5_VALOR",19) SIZE 50,10  PIXEL Of oDlg 
	nLinha += 9

	@nLinha,aColuna[1] Say STR0056  SIZE nSize,10 PIXEL Of oDlg 	//"Total Recebido "	 
	@nLinha,aColuna[2] Say oValRecT VAR nValRecT  Picture PesqPict("SE5","E5_VALOR",19) SIZE 50,10  PIXEL Of oDlg 
	@nLinha,aColuna[3] Say STR0057  SIZE nSize,10 PIXEL Of oDlg 			//"Total Pago     " 
	@nLinha,aColuna[4] Say oValPagT VAR nValPagT  Picture PesqPict("SE5","E5_VALOR",19) SIZE 50,10  PIXEL Of oDlg 
	nLinha += 9

	@nLinha,aColuna[1] Say STR0019  SIZE nSize,10 PIXEL Of oDlg   //"Docs.Reconc. Receber "
	@nLinha,aColuna[2] Say oQtdaR   VAR nQtdTitR Picture "@E 99999" SIZE 50,10  PIXEL Of oDlg 
	@nLinha,aColuna[3] Say STR0038  SIZE nSize,10 PIXEL Of oDlg  //"Valor Recebido "
	@nLinha,aColuna[4] Say oValRec  VAR nValRec Picture PesqPict("SE5","E5_VALOR",19) SIZE 50,10  PIXEL Of oDlg 
	nLinha += 9

	@nLinha,aColuna[1] Say STR0037  SIZE nSize,10 PIXEL Of oDlg   //"Docs.Reconc. Pagar "
	@nLinha,aColuna[2] Say oQtdaP   VAR nQtdTitP Picture "@E 99999" SIZE 50,10  PIXEL Of oDlg 
	@nLinha,aColuna[3] Say STR0039  SIZE nSize,10 PIXEL Of oDlg  //"Valor Pago "
	@nLinha,aColuna[4] Say oValPag  VAR nValPag Picture PesqPict("SE5","E5_VALOR",19) SIZE 50,10  PIXEL Of oDlg 
	nLinha += 9

	//------------------------------------------------------------------------------------------------------------------------
	//Painel 2 - MsSelect
	//------------------------------------------------------------------------------------------------------------------------
	oMark := MsSelect():New("TRB","E5_OK","",aCampos,@lInverte,@cMarca,{a2ndRow[1],a2ndRow[2],a2ndRow[3],a2ndRow[4]})
	oMark:oBrowse:lColDrag := .T.  
	oMark:bMark := {| | FA380Displ(cMarca,lInverte,oQtdaP,oQtdaR,oValRec,oValPag,oValRecT,oValPagT)}
	oMark:oBrowse:bAllMark := { || A380Inverte(cMarca,oQtdaP,oQtdaR,oValRec,oValPag,oValRecT,oValPagT)}
	If mv_par01 != 1  // Apenas para Conciliados e NÆo conciliados
		oMark:oBrowse:lhasMark = .t.
		oMark:oBrowse:lCanAllmark := .t.
	Endif
		
	If lPanelFin //Chamado pelo Painel Financeiro							
		aButtons := {}
		aButtons := aAdd({"S4WB008N",STR0048, {|| Calculadora()},,	 .T., CONTROL_ALIGN_LEFT})
		aButtons := aAdd({"S4WB009N",STR0049, {|| Agenda()}		,, 	 .T., CONTROL_ALIGN_LEFT}) 
		aButtons := aAdd({"S4WB010N",STR0050, {|| OurSpool()}	,,	 .T., CONTROL_ALIGN_LEFT}) 
		aButtons := aAdd({"S4WB016N",STR0051, {|| HelProg()}	,,	 .T., CONTROL_ALIGN_LEFT}) 
		aButtons := aAdd({"S4WB016N",STR0051, {|| HelProg()}	,,	 .T., CONTROL_ALIGN_LEFT})
		aButtons := aAdd({"NOTE"	,STR0069, {|| Fa380Edit()}	,,	 .T., CONTROL_ALIGN_LEFT}) 
		aButtons := aAdd({"NOTE"	,STR0069, {|| Fa380Edit()}	,,	 .T., CONTROL_ALIGN_LEFT})

	   If ExistBlock("F380BUT",.F.,.F.)
			aButtons := aAdd({"azul"	 ,STR0068,{|| ExecBlock("F380BUT",.F.,.F.)},,.T., CONTROL_ALIGN_LEFT})	
	   Endif				
		
		ACTIVATE MSDIALOG oDlg ON INIT FaMyBar(oDlg,{|| nOpca := 1,oDlg:End()},{|| nOpca := 2,oDlg:End()},aButtons)		
		
   Else	   	
		ACTIVATE MSDIALOG oDlg ON INIT (Fa380Bar(oDlg,{|| nOpca := 1,oDlg:End()},{|| nOpca := 2,oDlg:End()},,,@oMark),oMark:oBrowse:Refresh()) CENTERED
   Endif

	If ExistBlock("F380MTR")
		DbSelectArea("TRB")
		ExecBlock("F380MTR",.F.,.F.)
	EndIf	               
	
	If nOpca==1 
		
		nTamFil := TamSX3("E5_FILIAL")[1]
		nTamKey := TamSX3("E5_PREFIXO")[1]+TamSX3("E5_NUMERO")[1]+TamSX3("E5_PARCELA")[1] + 1
		nTamTipo := TamSX3("E5_TIPO")[1]
		
		dbSelectArea("TRB")
		dbGoTop()
		While !Eof()
			dbSelectArea("SE5")
			dbGoTo( TRB->E5_RECNO )
			
			cFilAnt := IIf(!Empty(SE5->E5_FILORIG),SE5->E5_FILORIG,cFilAnt)  

			//Carrega o Model de acordo com o tipo de registro da SE5

			If SE5->E5_TIPODOC $ "BA|VL|V2|ES|LJ|CP"
				If (!Empty(SE5->E5_LOTE) .And. SE5->E5_TABORI == "FK5") .Or.Alltrim(SE5->E5_TIPODOC) == "ES" .And. Empty(SE5->E5_MOTBX) .And. !Empty(SE5->E5_NUMCHEQ) .Or.;
				    Substr(SE5->E5_KEY,nTamKey,nTamTipo) $ MVPAGANT
					oModelMov := FWLoadModel("FINM030") //  estorno de cheque e Exclusão de PA
				Else
					If SE5->E5_TABORI == "FK1" .OR. (SE5->E5_RECPAG == "R" .and. SE5->E5_TIPODOC <> "ES" .and. !SE5->E5_TIPO $ MVPAGANT+"/"+MV_CPNEG) .Or. (SE5->E5_RECPAG == "P" .and. SE5->E5_TIPODOC == "ES" .and. !SE5->E5_TIPO $ MVPAGANT+"/"+MV_CPNEG);
						.OR. (SE5->E5_RECPAG == "P" .and. SE5->E5_TIPODOC <> "ES" .and. SE5->E5_TIPO $ MVRECANT+"/"+MV_CRNEG)  
							oModelMov := FWLoadModel("FINM010") //baixa a receber / RA
					Else
							oModelMov := FWLoadModel("FINM020")  //  Baixas a pagar / PA
					Endif
				EndIf	
			Else
				If ! SE5->E5_TIPODOC $ cGeraFK6
					oModelMov := FWLoadModel("FINM030")				
				Else
					oModelMov := Nil  //Valores acessórios migra ao migrar a baixa
				EndIf	
			EndIf
							
			If Empty(SE5->E5_IDORIG) // se não houve migração
				oModelMov := Nil
			EndIf


			//Verifico se nao estava reconciliado anteriormente
			If lCtrlCheq .and. cPaisLoc $ "ARG|DOM|EQU" .and. FUNNAME() $ "FINA095/FINA096"
				SEF->(DbSetOrder(6))                
				IF SEF->( DbSeek( xFilial("SEF")+SE5->E5_RECPAG+If(SE5->E5_RECPAG=="R",(SE5->E5_BCOCHQ+SE5->E5_AGECHQ+SE5->E5_CTACHQ+SUBSTR(SE5->E5_NUMERO,1,TAMSX3("EF_NUM")[1])),(SE5->E5_BANCO+SE5->E5_AGENCIA+SE5->E5_CONTA+SUBSTR(IIf(cPaisLoc == "ARG",SE5->E5_NUMERO,SE5->E5_NUMCHEQ),1,TAMSX3("EF_NUM")[1])))+SE5->E5_PREFIXO ))
					RecLock("SEF")                                            
					SEF->EF_RECONC := IIf(!Empty(TRB->E5_OK),"x"," ")
					SEF->(MSUnlock())
				Endif
			Endif
			cReconAnt := SE5->E5_RECONC
			If ValType(oModelMov) <> "U" 
				//Define os campos que não existem na FK5 e que serão gravados apenas na E5, para que a gravação da E5 continue igual
				cCamposE5 := "{"
				cCamposE5 += "{'E5_RECONC', '"  + IIf(!Empty(TRB->E5_OK),"x"," ") + "'}"													
				cCamposE5 += "}"
				
				oModelMov:SetOperation( MODEL_OPERATION_UPDATE ) //Alteração
				oModelMov:Activate()
				oModelMov:SetValue( "MASTER", "E5_GRV", .T. ) //habilita gravação de SE5 
				oModelMov:SetValue( "MASTER", "E5_CAMPOS", cCamposE5 ) //Informa os campos da SE5 que serão gravados indepentes de FK5
				
				//Posiciona a FKA com base no IDORIG da SE5 posicionada
				oSubFKA := oModelMov:GetModel( "FKADETAIL" )
				If SE5->E5_TABORI == "FK1" .OR. SE5->E5_TABORI == "FK2" 
					If oSubFKA:SeekLine( { {"FKA_TABORIG", SE5->E5_TABORI }, {"FKA_IDORIG", SE5->E5_IDORIG } } )
						cIdProc := oSubFKA:GetValue("FKA_IDPROC")
						oSubFKA:SeekLine( { {"FKA_TABORIG", "FK5" }, {"FKA_IDPROC", cIdProc } } )
					EndIf
					
				Else
					oSubFKA:SeekLine( { {"FKA_IDORIG", SE5->E5_IDORIG } } )
				EndIf
				
				//Dados do movimento
				oSubFK5 := oModelMov:GetModel( "FK5DETAIL" )					
				If !Empty(TRB->E5_OK)
					oSubFK5:SetValue( "FK5_DTCONC", dDataBase )
				Else
					oSubFK5:SetValue( "FK5_DTCONC", CTOD("") )
				Endif
		
				If SE5->E5_DTDISPO # TRB->E5_DTDISPO
					dOldDispo := SE5->E5_DTDISPO
					lAtuSaldo := .T.
					oSubFK5:SetValue( "FK5_DTDISP", TRB->E5_DTDISPO )
					AltDtFilho( TRB->E5_DTDISPO )
				Endif
				
				If oModelMov:VldData()
			       oModelMov:CommitData()
				Else
					lRet := .F.
					cLog := cValToChar(oModelMov:GetErrorMessage()[4]) + ' - '
					cLog += cValToChar(oModelMov:GetErrorMessage()[5]) + ' - '
					cLog += cValToChar(oModelMov:GetErrorMessage()[6])
					
					Help( ,,"MF380REC1",,cLog, 1, 0 )
				Endif
	
				oModelMov:DeActivate()
				oModelMov:Destroy()
				oModelMov:=NIL
			Else
				Reclock("SE5", .F.)
				SE5->E5_RECONC := IIf(!Empty(TRB->E5_OK),"x"," ")
				If SE5->E5_DTDISPO <> TRB->E5_DTDISPO
					SE5->E5_DTDISPO := TRB->E5_DTDISPO
				EndIf
				SE5->(MsUnlock())				
			EndIf
			//Acerto E5_DTDISPO dos titulos baixados com cheque para melhor apresentacao no
			//relatorio de fluxo de caixa realizado
			If lAtuSaldo .AND. !EMPTY(SE5->E5_NUMCHEQ)
				dbSelectArea("SE5")							
				dbSetOrder(11)
				If MsSeek(xFilial("SE5")+SE5->(E5_BANCO+E5_AGENCIA+E5_CONTA+E5_NUMCHEQ))
					cKeyCheque := SE5->(E5_FILIAL+E5_BANCO+E5_AGENCIA+E5_CONTA+E5_NUMCHEQ)
					While !Eof() .and. cKeyCheque == SE5->(E5_FILIAL+E5_BANCO+E5_AGENCIA+E5_CONTA+E5_NUMCHEQ)
						If lF380AlDt	
							lAltDt:=ExecBlock("F380AlDt",.F.,.F.)
						EndIf	
						If lAltDt
							If SE5->( Recno() ) == TRB->E5_RECNO .Or. lF380AlDt
								oModelMov := FWLoadModel("FINM030") //Recarrega o Model de movimentos para pegar o campo do relacionamento (SE5->E5_IDORIG)
								oModelMov:SetOperation( MODEL_OPERATION_UPDATE ) //Alteração
								oModelMov:Activate()
								oModelMov:SetValue( "MASTER", "E5_GRV", .T. ) //habilita gravação de SE5 
								
								//Posiciona a FKA com base no IDORIG da SE5 posicionada
								oSubFKA := oModelMov:GetModel( "FKADETAIL" )
								oSubFKA:SeekLine( { {"FKA_IDORIG", SE5->E5_IDORIG } } )	
								
								//Dados do movimento
								oSubFK5 := oModelMov:GetModel( "FK5DETAIL" )					
								oSubFK5:SetValue( "FK5_DTDISP", TRB->E5_DTDISPO )
								
								If oModelMov:VldData()
							       oModelMov:CommitData()
								Else
							       	lRet := .F.
								    cLog := cValToChar(oModelMov:GetErrorMessage()[4]) + ' - '
								    cLog += cValToChar(oModelMov:GetErrorMessage()[5]) + ' - '
								    cLog += cValToChar(oModelMov:GetErrorMessage()[6])        	
						        
							       	Help( ,,"MF380REC2",,cLog, 1, 0 )	
								Endif

								oModelMov:DeActivate()
								oModelMov:Destroy()
								oModelMov:=NIL

							EndIf
						EndIf	
						
						dbSkip()
					Enddo
				Endif
				dbGoTo( TRB->E5_RECNO )
			Endif
			
			If lF380Grv
				ExecBlock("F380GRV",.F.,.F.)
			EndIf	
	
			//Verifico atualizacao do saldo conciliado
			DO CASE
				CASE Empty(cReconAnt) .and. !Empty(SE5->E5_RECONC)
					nReconc := 1 	//Se foi reconciliado agora 			
				CASE !Empty(cReconAnt) .and. Empty(SE5->E5_RECONC)
					nReconc := 2 	//Se foi desconciliado agora
				CASE !Empty(cReconAnt) .and. !Empty(SE5->E5_RECONC)
	            nReconc := 3	//Nao foi alterada a situacao anterior, mas ja estava conciliado
			CASE Empty(cReconAnt) .and. Empty(SE5->E5_RECONC)		
	            nReconc := 3	//Nao foi alterada a situacao anterior, mas nao estava conciliado
			END CASE				
	
			If lAtuSaldo  // atualiza saldo bancario se alterou o E5_DTDISPO
				lAtuSaldo := .F.
	
				//Atualiza saldo conciliado na data antiga
				lAtSalRec1 := IIF( !Empty(SE5->E5_RECONC) .AND. (nReconc == 2 .or. nReconc == 3), .T., .F.)
				//Atualiza saldo conciliado na data nova
				lAtSalRec2 := IIF( !Empty(SE5->E5_RECONC) .AND. nReconc != 4, .T., .F.)
	
				If SE5->E5_RECPAG == "P"
					AtuSalBco(SE5->E5_BANCO,SE5->E5_AGENCIA,SE5->E5_CONTA,dOldDispo,SE5->E5_VALOR,"+",lAtSalRec1)
					AtuSalBco(SE5->E5_BANCO,SE5->E5_AGENCIA,SE5->E5_CONTA,SE5->E5_DTDISPO,SE5->E5_VALOR,"-",lAtSalRec2)
				Else
					AtuSalBco(SE5->E5_BANCO,SE5->E5_AGENCIA,SE5->E5_CONTA,dOldDispo,SE5->E5_VALOR,"-",lAtSalRec1)
					AtuSalBco(SE5->E5_BANCO,SE5->E5_AGENCIA,SE5->E5_CONTA,SE5->E5_DTDISPO,SE5->E5_VALOR,"+",lAtSalRec2)
				Endif
			Else
				//Atualiza apenas o saldo reconciliado
				If nReconc == 2	//Desconciliou
					If Alltrim(SE5->E5_TIPODOC) $ "TR;BD"
						nValTit := SE5->E5_VALOR
						aAreaSE5	:= SE5->( GetArea() )
						dbSelectArea("SE5")
						SE5->(dbsetorder(2))
						if SE5->(dbseek(SE5->E5_FILIAL+"I2"+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO+DTOS(E5_DATA)+ SE5->E5_CLIFOR+SE5->E5_LOJA+SE5->E5_SEQ))
							nValTit += SE5->E5_VALOR 
						EndIf
						RestArea( aAreaSE5 )
						AtuSalBco(SE5->E5_BANCO,SE5->E5_AGENCIA,SE5->E5_CONTA,SE5->E5_DTDISPO,nValTit,IIF(SE5->E5_RECPAG == "P","+","-"),.T.,.F.)
					Else
						AtuSalBco(SE5->E5_BANCO,SE5->E5_AGENCIA,SE5->E5_CONTA,SE5->E5_DTDISPO,SE5->E5_VALOR,IIF(SE5->E5_RECPAG == "P","+","-"),.T.,.F.)
					EndIf			
				Endif
				If nReconc == 1	//Conciliou
					If Alltrim(SE5->E5_TIPODOC) $ "TR;BD"
						nValTit := SE5->E5_VALOR
						aAreaSE5	:= SE5->( GetArea() )
						dbSelectArea("SE5")
						SE5->(dbsetorder(2))
						if SE5->(dbseek(SE5->E5_FILIAL+"I2"+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO+DTOS(E5_DATA)+ SE5->E5_CLIFOR+SE5->E5_LOJA+SE5->E5_SEQ))
							nValTit += SE5->E5_VALOR 
						EndIf
						RestArea( aAreaSE5 )
						AtuSalBco(SE5->E5_BANCO,SE5->E5_AGENCIA,SE5->E5_CONTA,SE5->E5_DTDISPO,nValTit,IIF(SE5->E5_RECPAG == "P","-","+"),.T.,.F.)
					Else
						AtuSalBco(SE5->E5_BANCO,SE5->E5_AGENCIA,SE5->E5_CONTA,SE5->E5_DTDISPO,SE5->E5_VALOR,IIF(SE5->E5_RECPAG == "P","-","+"),.T.,.F.)
					EndIf			
				Endif
			Endif
		
			dbSelectArea("TRB")
			dbSkip()
		EndDo
	Endif
	Exit
EndDo
If Select("TRB") > 0
	dbSelectArea("TRB")
	dbCloseArea()
	Ferase(cNomeArq+GetDBExtension())
	Ferase(cNomeArq+OrdBagExt())
EndIf
If Select("NEWSE5") > 0
	dbSelectArea( "NEWSE5" )
	Set Filter to
	dbCloseArea()
	#IFNDEF TOP
		IF !Empty(cIndexSE5)
			FErase (cIndexSE5+OrdBagExt())
		EndIF
	#ENDIF
Endif
/*
GESTAO - inicio */
cFilAnt := cFilAtu
/* GESTAO - fim
*/
dbSelectArea("SE5")
Return (.T.)

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³fa380ChecF³ Autor ³ Alessandro B.Freire   ³ Data ³ 08/01/97 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Grava no arq. de trabalho os registros que obedecerem as	  ³±±
±±³			 ³condicoes.																  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³fa380ChecF() 															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³FINA380																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function Fa380ChecF(lCtrlCheq)

LOCAL aStruSE5	:= {}
LOCAL aStruTRB	:= {}
Local nRegEmp	:= SM0->(Recno())
Local nRegAtu	:= SM0->(Recno())
Local cEmpAnt	:= SM0->M0_CODIGO
Local aFiliais	:= {xFilial("SE5")}
Local lTodasFil	:= .F.
Local cCond1	:= "!Eof()"				
Local nCond		:= 1
Local aAreaAtu	:= {}
Local lIndice12	:= .F.
Local lIsMySql	:= (TcGetDb() == 'MYSQL')
Local nPosCampo	:= 0
Local cCampo	:= ""
Local lTrue		:= .T.
Local nMoedBco	:= SA6->A6_MOEDA
/*
GESTAO - inicio */
Local lGestao	:= .F.
Local aSM0		:= {}

Local nI		:= 0
Local nX		:= 0

Default lCtrlCheq:=.F.
/* GESTAO - fim
*/

dbSelectArea("TRB")
aStruTRB := dbStruct()

dbSelectArea("SE5")
aStruSE5 := dbStruct()  

nTamFilName := Len(FWFilialName(cEmpAnt,cFilAnt,1))+3
nPosFil := aScan(aStruSE5,{|x|x[1]=="E5_FILIAL"})
aStruSE5[nPosFil][3] += nTamFilName

//Verifica existencia do indice 12 do SE5 - E5_FILIAL+DTOS(E5_DTDISPO)+E5_BANCO+E5_AGENCIA+E5_CONTA+E5_NUMCHEQ
aAreaAtu := GetArea()
dbSelectArea("SIX")
 
If MSSeek("SE5"+"C")
	If "E5_FILIAL" $ CHAVE .AND. "E5_BANCO" $ CHAVE .AND. "E5_AGENCIA" $ CHAVE .AND. "E5_CONTA" $ CHAVE .AND. ;
		"DTOS(E5_DTDISPO)" $ CHAVE .AND. "E5_NUMCHEQ" $ CHAVE    
		lIndice12:=	.T.
	EndIf
Else
	lIndice12:=	.F.
Endif
/*
GESTAO - inicio */
lGestao	:= ("E" $ FWSM0Layout() .Or. "U" $ FWSM0Layout())
If lGestao
	aSM0 := FWLoadSM0()
Endif
/* GESTAO - fim
*/	
RestArea(aAreaAtu)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Abre o SE5 com outro alias para ser filtrado                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

IF(If(lIsMySql,.T.,ChkFile("SE5",.F.,"NEWSE5")))

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Execblock a ser executado antes da Indregua                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	IF (ExistBlock("F380FIL"))
		cFil380 := ExecBlock("F380FIL",.f.,.f.)
	Else
		cFil380 := ""
	Endif

	//Formato antigo
	If !lIndice12

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Monta express„o do Filtro para sele‡„o                       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cIndexSE5	:= CriaTrab(nil,.f.)
		cChaveSE5	:= IndexKey()
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se devem ser consideradas todas as filiais          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If Empty(xFilial( "SA6")) .And. !Empty(xFilial("SE5"))
			If Left(LTrim(cChaveSE5),9) == "E5_FILIAL"
				// Tira a filial da chave.
				cChaveSE5 := lTrim(SubStr(cChaveSE5,AT("+",cChaveSE5)+1))
			EndIf
		EndIf
		nOldIndex	:= IndexOrd()
		#IFDEF TOP	
			If lIsMySql
				cFiltro := QryMySql(aStruSE5)
				dbUseArea(.T., "TOPCONN", TcGenQry(,,cFiltro), "NEWSE5", .F., .T. )
			Else
				IndRegua("NEWSE5",cIndexSE5,cChaveSE5,,FA380ChecA(),OemToAnsi(STR0028))  //"Selecionando Registros..."	
			Endif
		#ELSE
			IndRegua("NEWSE5",cIndexSE5,cChaveSE5,,FA380ChecA(),OemToAnsi(STR0028))  //"Selecionando Registros..." 
		#ENDIF
		dbSelectArea("NEWSE5")
		#IFNDEF TOP
			dbSetIndex(cIndexSE5+OrdBagExt())
		#ENDIF
		dbGoTop()
		If Bof() .And. Eof()
			Return
		EndIf

	Else  //indice novo existe
		/*
		GESTAO - inicio */
		If lGestao
			If FWModeAccess("SA6",3) == "C" .And. FWModeAccess("SE5",3) == "E"
				AdmSelecFil("",0,.F.,@aFiliais,"SE5",.T.,(FWModeAccess("SA6",2) == "E"))
				lTodasFil := .T.
			Else
				Aadd(aFiliais,cFilAnt)
				lTodasFil := .F.
			Endif
			/* Deixo na aSM0 somente as filiais selecionas para conciliacao. */
			nI := 0 
			For nX := Len(aSM0) To 1 Step -1
				If  Ascan(aFiliais,aSM0[nX,SM0_CODFIL]) == 0
					Adel(aSM0,nX)
					nI := nI + 1
				Endif
			Next
			If nI > 0
				Asize(aSM0,Len(aSM0) - nI)
			Endif
		Else
			If Empty(xFilial( "SA6")) .And. !Empty(xFilial("SE5"))
				lTodasFil := .T.
				dbSelectArea("SM0")
				nRegAtu := SM0->(RECNO())
				If dbSeek(cEmpAnt,.T.)
					aFiliais := {}
					While !Eof() .and. SM0->M0_CODIGO == cEmpAnt
						AADD(aFiliais,IIf( lFWCodFil, FWGETCODFILIAL, SM0->M0_CODFIL ))
						DbSkip()
					Enddo
				EndIf
				SM0->(dbGoto(nRegAtu))
			EndIf
		Endif
		/* GESTAO - fim 
		*/
		#IFDEF TOP	
			If lIsMySql
				cFiltro := QryMySql(aStruSE5)
				dbUseArea(.T., "TOPCONN", TcGenQry(,,cFiltro), "NEWSE5", .F., .T. )
			Else
		#ENDIF
				dbSelectArea("NEWSE5")
				dbSetOrder(12)  //E5_FILIAL+E5_BANCO+E5_AGENCIA+E5_CONTA+DTOS(E5_DATA)+E5_NUMCHEQ
				cCond1 := "!Eof() .and. "
				cCond1 += "E5_FILIAL == xFilial('SE5') .And."
				cCond1 += "E5_BANCO+E5_AGENCIA+E5_CONTA == '" + cBco380+cAge380+cCta380+"'.and."
				cCond1 += "DTOS(E5_DTDISPO)<= '" + DTOS(dFimDt380)+"'"
				If lTodasFil
					nCond := Len(aFiliais)
				Else
					nCond := 1
				Endif
		#IFDEF TOP		
			Endif
		#ENDIF			
	Endif

	//Tratamento de todas as filiais
	For nI := 1 to nCond

		//Se forem todas as filiais,utilizo o arrau aFiliais como referencia
		If nCond > 1	
			cFilAtu := aFiliais[nI]
			SM0->(MsSeek(SM0->M0_CODIGO+cFilAtu))
		Else
			cFilAtu := IIf( lFWCodFil, FWGETCODFILIAL, SM0->M0_CODFIL )
		Endif
		
		cEmpAnt := SM0->M0_CODIGO

		While !Eof() .and. SM0->M0_CODIGO == cEmpAnt .and. IIf( lFWCodFil, FWGETCODFILIAL, SM0->M0_CODFIL ) == cFilAtu

			cFilAnt := IIf( lFWCodFil, FWGETCODFILIAL, SM0->M0_CODFIL )
			dbSelectArea("NEWSE5")

			//Se possui novo indice posiciono no primeiro registro da filial
			If lIndice12 .and. !lIsMySql
				MsSeek(xFilial("SE5")+cBco380+cAge380+cCta380+DTOS(dIniDt380),.T.)
			Endif

			//Verifico quebra por filial ou por fim de arquivo
			While &cCond1
	
				If (NEWSE5->E5_MOEDA $ "C1/C2/C3/C4/C5/CH" .And. Empty(NEWSE5->E5_NUMCHEQ) .and. !(NEWSE5->E5_TIPODOC $ "TR#TE"))
					dbSkip()
					Loop
				EndIf	

				If !lIsMySql
					If cPaisLoc $ "ARG|DOM|EQU" .and. FUNNAME() $ "FINA095/FINA096"
						If lIndice12 
							lTrue:=&(FA380ChecA(,lCtrlCheq))
							If !lTrue
								dbSkip()
								Loop
							Endif	
						EndIf
					Else
						If lIndice12 .and. !&(FA380ChecA())
							dbSkip()
							Loop
						EndIf
					Endif	
				Endif
			             
				//Gravo arquivo de trabalho
				RecLock( "TRB", .T. )
				For nX := 1 to Len( aStruSE5 )
					cCampo    := aStruSE5[ nX, 1 ]
					xConteudo := NEWSE5->( FieldGet( FieldPos( cCampo ) ) )
					nPosCampo := TRB->( FieldPos( cCampo ) )
					If nPosCampo > 0
						If lIsMySql .And. Upper( aStruSE5[ nX, 2 ] ) == "D"
							xConteudo := StoD( xConteudo )
						EndIf
						TRB->( FieldPut( nPosCampo, xConteudo ) )
					EndIf
				Next nX
                
			  	TRB->E5_FILIAL := ALLTRIM(E5_FILIAL) + " - " + FWFilialName(cEmpAnt,cFilAnt,1)
				TRB->E5_RECNO := If(lIsMySql, NEWSE5->R_E_C_N_O_ , NEWSE5->(Recno()))
				TRB->E5_OK := IIf(NEWSE5->E5_RECONC == "x", cMarca,"  ")               
				
				msUnlock()
		
				dbSelectArea("NEWSE5")
		
				If ! Empty( TRB->E5_OK )
					If E5_RECPAG == "P"
						nQtdTitP++
						nValPag += IIF(nMoedBco > 1 .and. cPaisLoc == "BRA", E5_VLMOED2, E5_VALOR)
					Else
						nQtdTitR++
						nValRec += IIF(nMoedBco > 1 .and. cPaisLoc == "BRA", E5_VLMOED2, E5_VALOR)
					Endif
				Else
					If E5_RECPAG == "P"
						nValPagT += IIF(nMoedBco > 1 .and. cPaisLoc == "BRA", E5_VLMOED2, E5_VALOR)
					Else
						nValRecT += IIF(nMoedBco > 1 .and. cPaisLoc == "BRA", E5_VLMOED2, E5_VALOR)
					Endif
				EndIf
				dbSelectArea("NEWSE5")
				dbSkip()
			EndDo
			If Empty(xFilial("SE5"))
				Exit
			Endif
			dbSelectArea("SM0")
			dbSkip()
		Enddo	
	Next
EndIf
SM0->(dbGoTo(nRegEmp))
cFilAnt := IIf( lFWCodFil, FWGETCODFILIAL, SM0->M0_CODFIL )

Return .T.

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³fa380Displ³ Autor ³ Mauricio Pequim Jr.   ³ Data ³ 23/09/98 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Marca e Desmarca Titulos, invertendo a marca‡†o existente  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ fa380Displ()															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ 																			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA380																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function fa380Displ(cMarca,lInverte,oQtdaP,oQtdaR,oValRec,oValPag,oValRecT,oValPagT)
Local nMoedBco := SA6->A6_MOEDA
Local lBrasil  := cPaisLoc=="BRA"

If IsMark("E5_OK",cMarca,lInverte)
	If TRB->E5_RECPAG == "P"
		nValPag += IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
		nValPagT -= IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
		nQtdTitP++
	Else
		nValRec += IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
		nValRecT -= IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
		nQtdTitR++
	Endif
Else
	If TRB->E5_RECPAG == "P"
		nValPag -= IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
		nValPagT += IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
		nQtdTitP--
	Else
		nValRec -= IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
		nValRecT += IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
		nQtdTitR--				
	Endif
Endif
If lFa380
	ExecBlock("F380RECO",.F.,.F.)
EndIf	
oQtdaR:Refresh()
oQtdaP:Refresh()
oValRec:Refresh()
oValPag:Refresh()
oValRecT:Refresh()
oValPagT:Refresh()

Return

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³fa380Checa³ Autor ³ Mauricio Pequim Jr.   ³ Data ³ 23/09/98 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Filtro da Indiregua no SE5                  		 			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ fa380Checa()															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ 																			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA380																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function fa380Checa(cAlias,lCtrlCheq)

Local cFiltro := ""
Default lCtrlCheq	:=	.F.

If !(Empty(xFilial( "SA6")) .And. !Empty(xFilial("SE5")))
	cFiltro := 'E5_FILIAL=="'+xFilial("SE5")				+'".And.'
Endif	
cFiltro += 'DTOS(E5_DTDISPO)>="' + DTOS(dIniDt380)	+'".And.'
cFiltro += 'DTOS(E5_DTDISPO)<="' + DTOS(dFimDt380) + '".And.'
cFiltro += 'E5_BANCO=="' 			+ cBco380 			+ '".And.'
cFiltro += 'E5_AGENCIA=="' 		+ cAge380 			+ '".And.'
cFiltro += 'E5_CONTA=="' 			+ cCta380 			+ '".And.'
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Compatibilização da expressão contido ($) que causa problemas em MySql³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If cPaisLoc $ "ARG|DOM|EQU" .and. lCtrlCheq .and. FUNNAME() $ "FINA095/FINA096"
	If FunName()=="FINA096"
		cFiltro += ' (AllTrim(E5_TIPO)=="CH" .and. E5_TIPODOC$"VL") .and. E5_RECPAG=="R" .and. E5_SITUACA<>"C" '      
	Elseif FunName()=="FINA095"                                                                                      
		cFiltro += ' (AllTrim(E5_TIPO)$"CH/ORP" .and. E5_TIPODOC$"VL/CH") .and. E5_RECPAG=="P" .and. E5_SITUACA<>"C" '  
	Endif	                                                                                                            
 Else	                                                                                                               
	cFiltro += '!(E5_TIPODOC =="JR" .Or. E5_TIPODOC=="J2" .Or. E5_TIPODOC=="TL" .Or. E5_TIPODOC=="DC" '
	cFiltro += '.Or.  E5_TIPODOC=="D2" .Or. E5_TIPODOC=="MT" .Or. E5_TIPODOC=="M2" .Or. E5_TIPODOC=="CM" '   
	cFiltro += '.Or.  E5_TIPODOC=="C2" .Or. E5_TIPODOC=="CP" .Or. E5_TIPODOC=="BA" .Or. E5_TIPODOC=="V2" ) ' 
	cFiltro += '.And. E5_SITUACA!="C" '
Endif
IF mv_par01==2
	cFiltro += '.And. Empty(E5_RECONC)'
Elseif mv_par01==3
	cFiltro += '.And.!Empty(E5_RECONC)'
EndIf

If !(Empty(cFil380))
	cFiltro := '(' +cFiltro+ ').and.(' +cFil380+')'
Endif

Return( cFiltro )

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³Fa380BAR	³ Autor ³ Mauricio Pequim Jr	  ³ Data ³18.06.01  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Mostra a EnchoiceBar na tela - WINDOWS 						  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ Generico 																  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function Fa380Bar(oDlg,bOk,bCancel,oSelecP,oSelecR,oMark)

Local oBar, bSet15, bSet24, bSet18, lOk
Local lVolta :=.f.
Local lF380But := ExistBlock("F380BUT",.F.,.F.)
Local aButtons := {}

AADD(aButtons, {"S4WB005N"		, {|| NaoDisp()}, STR0045 } )  //"Recortar"
AADD(aButtons, {"S4WB006N"		, {|| NaoDisp()}, STR0046 } )  //"Copiar"
AADD(aButtons, {"S4WB007N"		, {|| NaoDisp()}, STR0047 } )  //"Colar"
AADD(aButtons, {"S4WB008N"		, {|| Calculadora()}, STR0048 } )  //"Calculadora..."
AADD(aButtons, {"S4WB009N"		, {|| Agenda()}, STR0049 } )  //"Agenda..."	
AADD(aButtons, {"S4WB010N"		, {|| OurSpool()}, STR0050 } )  //"Gerenciador de ImpressÆo..."
AADD(aButtons, {"S4WB016N"		, {|| HelProg()}, STR0051 } )  //"Help de Programa..."
AADD(aButtons, {"NOTE"		, {|| Fa380Edit(),oMark:oBrowse:Refresh() }, STR0052 } )  //"Editar"###"Edita Registro..(CTRL-E)"
SetKey(5, { || Fa380Edit()} )

If ExistBlock( "F380BUT" )
	AADD(aButtons, {"azul"		, {|| ExecBlock("F380BUT",.F.,.F.) }, STR0068 } )  //"Usuário"###"Botão do Usuário..(CTRL-R)"   
	SetKey(18, {|| ExecBlock("F380BUT",.F.,.F.)} )
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de entrada permite a inclusão de um botão customizado  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
IF (ExistBlock("F380BTCUST"))
	AADD(aButtons, {"azul"		, {|| ExecBlock("F380BTCUST",.F.,.F.,{3,@oDlg,@oMark}) }, STR0075 }  )		
Endif

EnchoiceBar( oDlg, {|| ( lLoop := lVolta, lOk := Eval( bOk ) ) }, {|| ( lLoop := .F., Eval( bCancel ), ButtonOff( bSet15, bSet24,bSet18,.T. ) ) },, aButtons,,,,, .F. )	

Return nil


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³ButtonOff ³ Autor ³ Mauricio Pequim Jr	  ³ Data ³18.06.01  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Desliga Botao da enchoice bar - WINDOWS						  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ Generico 																  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ButtonOff(bSet15,bSet24,bSet18,lOk)
DEFAULT lOk := .t.
IF lOk
	 SetKey(15,bSet15)
	 SetKey(24,bSet24)
	 SetKey(18,bSet18)	 
Endif

Return .T.


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³Fa380Edit ³ Autor ³ Mauricio Pequim Jr	  ³ Data ³18.06.01  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Mostra a EnchoiceBar na tela - WINDOWS 						  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ Generico 																  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function Fa380Edit()

Local oDlg1 
Local dNewDispo := E5_DTDISPO
Local nRecOri	 := TRB->(RECNO())
Local nRadio	 := 1
Local cCondicao := ""
Local nRecAtu 
Local nRecNxt
Local oRadio
Local cCond2	:= ""
Local lF380DTD := ExistBlock("F380DTD")
Local lF380DTC := ExistBLock("F380DTC")
Private lDtCrdAnt := .F.

//Permito conciliacao de movimentos com data de credito anterior a data de inclusao no sistema.
If lF380DTD
	lDtCrdAnt := ExecBlock("F380DTD",.F.,.F.)
Endif	

dDtDispo  := E5_DTDISPO

DEFINE MSDIALOG oDlg1 FROM  69,70 TO 220,331 TITLE OemToAnsi(STR0042) PIXEL  //'Reconciliacao - EXTRATO'
@ 0, 2 TO 58, 128 OF oDlg1 PIXEL
@ 8, 08 SAY OemToAnsi(STR0043) SIZE 80, 8 OF oDlg1 PIXEL	//"Data para Conciliacao"
@ 7, 75 MSGET dNewDispo SIZE 50,8 OF oDlg1 PIXEL VALID DtMovFin(dNewDispo)
If mv_par01 != 2
	@ 20,08 Radio oRadio VAR nRadio ;
		ITEMS STR0064, ; //"Apenas para este registro"
			STR0065, ; //"Apenas para registros de mesma data"
			STR0066 ; //"Para todos os registros"
	 3D SIZE 105,10 OF oDlg1 PIXEL
Else
	@ 20,08 Radio oRadio VAR nRadio ;
		ITEMS STR0064, ; //"Apenas para este registro"
			STR0065, ; //"Apenas para registros de mesma data"
			STR0066, ; //"Para todos os registros"
			STR0076 ; //"Apenas para registros marcados"
	 3D SIZE 105,10 OF oDlg1 PIXEL
Endif

DEFINE SBUTTON FROM 60, 100 TYPE 1 ENABLE ACTION IIF(lF380DTC,Iif(ExecBlock("F380DTC",.F.,.F.,dNewDispo),oDlg1:End(),Nil),oDlg1:End())   OF oDlg1
ACTIVATE MSDIALOG oDlg1 CENTERED

cCond2 := "((DTOS(E5_DTDISPO) != '"+ DTOS(dNewDispo) +"' .and. DTOS(E5_DATA) <= '" + DTOS(dNewDispo) + "') .or. lDtCrdAnt)"

If nRadio == 1		 	//Se gravar apenas para o registro corrente
	cCondicao	:= ".T."	                                        
ElseIf nRadio == 2 	//Se gravar apenas para os registros da mesma data
	TRB->(DbSeek(DTOS(dDtDispo)))	
	cCondicao := "DTOS(TRB->E5_DTDISPO) == '"+DTOS(E5_DTDISPO)+"'"
ElseIf nRadio == 3  //Se gravar a data para todos os movimentos
	TRB->(dbGoTop())
	cCondicao := "!(TRB->(EOF()))"
ElseIf nRadio == 4  //Se gravar a data apenas para os registros selecionados
	TRB->(dbGoTop())
	cCondicao := "!(TRB->(EOF()))"
	cCond2	+= " .and. TRB->E5_OK == '" + cMarca + "'"
Endif

While &cCondicao
	If nRadio > 1
		nRecAtu := TRB->(RECNO())
		dbSkip()
		nRecNxt := TRB->(RECNO())
		dbGoto(nRecAtu)                             
	Endif
	If &cCond2
		RecLock("TRB", .F.)
		TRB->E5_DTDISPO := dNewDispo
		TRB->(MsUnLock())
	Else
		If nRadio == 1 .And. TRB->E5_DTDISPO != dNewDispo		//apenas para registro corrente
			Aviso(STR0077, STR0078, {"Ok"})  //"Atencao"###"Data de disponibilidade nao pode ser anterior a data de inclusao do movimento."
		EndIf
	Endif	
	If nRadio == 1 // Se gravar a data apenas para o registro corrente
		Exit
	Else
		dbGoto(nRecNxt)
	Endif
Enddo
dbGoto(nRecOri)
Return

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³ A380Invert ³ Autor ³ Mauricio Pequim Jr    ³ Data ³ 29/08/01 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Marca / Desmarca titulos					  	         			 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ Fina380													                ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function A380Inverte(cMarca,oQtdaP,oQtdaR,oValRec,oValPag,oValRecT,oValPagT)
Local nMoedBco := SA6->A6_MOEDA
Local lBrasil  := cPaisLoc=="BRA"
Local nReg := TRB->(Recno())
DbSelectArea("TRB")                                                                                                                    
DbGoTop()

While !Eof()
	If TRB->E5_OK == cMarca
		If mv_par01 != 1  .or. Empty(TRB->E5_RECONC) // Apenas para Conciliados e NÆo conciliados
			If TRB->E5_RECPAG == "P"
				nValPag -= IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
				nValPagT += IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
				nQtdTitP--
			Else
				nValRec -= IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
				nValRecT += IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
				nQtdTitR--
			Endif
			RecLock("TRB")
			Replace TRB->E5_OK with "  "
			MsUnlock()
		EndIf
	Else
		If TRB->E5_RECPAG == "P"
			nValPag += IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
			nValPagT -= IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
			nQtdTitP++
		Else
			nValRec += IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
			nValRecT -= IIF(nMoedBco>1 .And. lBrasil,TRB->E5_VLMOED2,TRB->E5_VALOR)
			nQtdTitR++
		Endif
		RecLock("TRB")
		Replace TRB->E5_OK with cMarca
		MsUnlock()
	Endif
	dbskip()
EndDo
DbSelectArea("TRB")
DbGoTo(nReg)
oQtdaR:Refresh()
oQtdaP:Refresh()
oValRec:Refresh()
oValPag:Refresh()
oValRecT:Refresh()
oValPagT:Refresh()
Return(NIL)


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³QryMySql  ºAutor  ³Nilton Pereira      º Data ³  01/04/05   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Monta query especial para o MySql                           º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Fina380                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
#IFDEF TOP	
Static Function QryMySql(aStruSE5,nData)

Local cField  := ""
Local cFiltro := ""
Local x

DEFAULT nData := 1

For x:= 1 to len(aStruSE5)
	cField += aStruSE5[x][1] + ","
Next

cFiltro := "SELECT " + cField + "R_E_C_N_O_"
cFiltro += " FROM " + RetSQLname("SE5")
cFiltro += " WHERE D_E_L_E_T_ != '*' "
cFiltro += " AND E5_DTDISPO >= '" + DTOS(dIniDt380)	+ "'"
cFiltro += " AND E5_DTDISPO <= '" + DTOS(dFimDt380) + "'"
cFiltro += " AND E5_BANCO = '" + cBco380 + "'"
cFiltro += " AND E5_AGENCIA = '" + cAge380 +  "'"
cFiltro += " AND E5_CONTA = '" + cCta380 + "'"
cFiltro += " AND ( (INSTR('JR#J2#TL#DC#D2#MT#M2#CM#C2#CP#BA#V2', E5_TIPODOC ) = 0)  or (E5_TIPODOC = ' '))"
cFiltro += " AND E5_SITUACA <> 'C'"
IF mv_par01==2
	cFiltro += " AND E5_RECONC = ' '"
Elseif mv_par01==3
	cFiltro += " AND E5_RECONC <> ' '"
EndIf
If nData == 1
	cFiltro += " ORDER BY E5_DATA,E5_BANCO,E5_AGENCIA,E5_CONTA,E5_NUMCHEQ,R_E_C_N_O_ LIMIT 250"
Else
	cFiltro += " ORDER BY E5_DTDISPO,E5_BANCO,E5_AGENCIA,E5_CONTA,E5_NUMCHEQ,R_E_C_N_O_ LIMIT 250"	
Endif

memowrite("C:\Temp\testesql.txt",cFiltro )

Return cFiltro

#ENDIF

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³MenuDef   ³ Autor ³ Ana Paula N. Silva     ³ Data ³27/11/06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Utilizacao de menu Funcional                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Array com opcoes da rotina.                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Parametros do array a Rotina:                               ³±±
±±³          ³1. Nome a aparecer no cabecalho                             ³±±
±±³          ³2. Nome da Rotina associada                                 ³±±
±±³          ³3. Reservado                                                ³±±
±±³          ³4. Tipo de Transa‡„o a ser efetuada:                        ³±±
±±³          ³		1 - Pesquisa e Posiciona em um Banco de Dados     ³±±
±±³          ³    2 - Simplesmente Mostra os Campos                       ³±±
±±³          ³    3 - Inclui registros no Bancos de Dados                 ³±±
±±³          ³    4 - Altera o registro corrente                          ³±±
±±³          ³    5 - Remove o registro corrente do Banco de Dados        ³±±
±±³          ³5. Nivel de acesso                                          ³±±
±±³          ³6. Habilita Menu Funcional                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function MenuDef()
Local aRotina := { { STR0001, "AxPesqui", 0 , 1,,.F.},; // "Pesquisar"
							{ STR0002, "u_A380Rec", 0 , 3},; // "Reconciliacao"
							{ STR0084, "F380Legenda", 0 , 6, ,.F.} } //"Legenda"
Return(aRotina)/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³FinA380T   ³ Autor ³ Marcelo Celi Marques ³ Data ³ 04.04.08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Chamada semi-automatica utilizado pelo gestor financeiro   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ FINA380                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function FinA380T(aParam)
	ReCreateBrow("SE5",FinWindow)      	
	cRotinaExec := "FINA380"
	FinA380(aParam[1])
	ReCreateBrow("SE5",FinWindow)      	

	dbSelectArea("SE5")
	
	INCLUI := .F.
	ALTERA := .F.

Return .T.	

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³F380Legenda ³ Autor ³ Jose.Gavetti      . ³ Data ³ 13/11/14 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Cria uma janela contendo a legenda da mBrowse ou retorna a ³±±
±±³          ³ para o BROWSE                                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Fina380                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function F380Legenda(nReg)

Local aLegenda := { 	{"BR_VERDE", STR0085 },;		//"Movimento Bancario - Receber"
							{"BR_AZUL", STR0086 },;		//"Movimento Bancario - Pagar"
							{"BR_AMARELO", STR0087 },;		//"Movimento Bancario - Cancelado"
							{"BR_VERMELHO", STR0088 } }	//"Movimento Bancario - Excluido"
Local uRetorno := .T.

If nReg = Nil	// Chamada direta da funcao onde nao passa, via menu Recno eh passado
	uRetorno := {}
	Aadd(uRetorno, { 'E5_RECPAG = "R" .and. Empty(E5_SITUACA)', aLegenda[1][1] } )
	Aadd(uRetorno, { 'E5_RECPAG = "P" .and. Empty(E5_SITUACA)', aLegenda[2][1] } )
	Aadd(uRetorno, { 'E5_SITUACA $ "X/E"', aLegenda[3][1] } )
	Aadd(uRetorno, { 'E5_SITUACA = "C"', aLegenda[4][1] } )
Else
	BrwLegenda(cCadastro, STR0084, aLegenda) // "Legenda"
Endif

Return uRetorno

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³AltDtFilho ³ Autor ³ Daniel Mendes      . ³ Data ³ 06/08/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Atualiza a data E5_DTDISPO dos títulos filhos do principal ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Fina380                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function AltDtFilho( dDataConc )
Local cChaveSE5 := ""
Local cFilSE5   := ""
Local aTipos    := { "VL","CM","CX","DC","MT","JR","V2","C2","D2","M2","J2","BA","TL","LJ","RA" }
Local aArea     := {}
Local aAreaSE5  := {}
Local nFor      := 0

aArea     := GetArea()
aAreaSE5  := SE5->( GetArea() )
cFilSE5   := SE5->E5_FILIAL
IF !SE5->E5_TIPODOC == "CH"
	cChaveSE5 := SE5->( E5_PREFIXO + E5_NUMERO + E5_PARCELA + E5_TIPO + DtoS(E5_DATA) + E5_CLIFOR + E5_LOJA + E5_SEQ )
	
	SE5->( MsUnLock() )
	SE5->( dbSetOrder( 2 ) )//E5_FILIAL+E5_TIPODOC+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+DtoS(E5_DATA)+E5_CLIFOR+E5_LOJA+E5_SEQ
	
	For nFor := 1 To Len( aTipos ) 
		If SE5->( MsSeek( cFilSE5 + aTipos[ nFor ] + cChaveSE5 ) )
			RecLock( "SE5" , .F. )
			SE5->E5_DTDISPO := dDataConc
			SE5->( MsUnLock() )
		EndIf
	Next nFor
Else
	cChaveSE5 := SE5->( E5_FILIAL + E5_BANCO + E5_AGENCIA + E5_CONTA + E5_NUMCHEQ + DtoS(E5_DATA) )
	
	SE5->( MsUnLock() )
	SE5->( dbSetOrder( 11 ) ) 
	SE5->(dbSeek(cFilSE5 + SE5->E5_BANCO + SE5->E5_AGENCIA + SE5->E5_CONTA + SE5->E5_NUMCHEQ + DtoS(SE5->E5_DATA)))
	
	While !Eof() .and. cFilSE5 + SE5->( E5_BANCO + E5_AGENCIA + E5_CONTA + E5_NUMCHEQ + DtoS(E5_DATA) ) == cChaveSE5
		  If E5_TIPODOC $ "VL/CM/CX/DC/MT/JR/V2/C2/D2/M2/J2/BA/TL/LJ/RA"
				RecLock( "SE5" , .F. )
				SE5->E5_DTDISPO := dDataConc
				SE5->( MsUnLock() )
		  Endif	
		dbSkip()
	Enddo
Endif	

RestArea( aAreaSE5 )
RestArea( aArea    )
RecLock( "SE5" )//Devolvo no mesmo estado que a função foi chamada

Return Nil

