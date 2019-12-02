#Include 'Protheus.ch'
#Include 'Topconn.ch'

/*===================================================================*\
|	Data:		05/2019                                               |
|	Cliente:	C&K                                                   |
|	Autor :	    Júnior Conte                                          |
|	Módulo:		SIGACOM                                               |
|	Tipo:		Relatório                                             |
|	Resumo:		Importa intes do ped venda para o ped compra          |
|				                                         			  |
\*===================================================================*/


USER FUNCTION CEK027 

Local cPerg := PADR("CEK027", 10)

// Criação de parâmetros 
PutSx1(cPerg,"01",OemToAnsi("Fornece")    ,"","","mv_ch1","C",TamSx3("A2_COD")[1],0 ,0,"G","","SA2","","","mv_par01","","","","","","","","","","","","","","","","",{},{},{})
PutSx1(cPerg,"02",OemToAnsi("Loja")       ,"","","mv_ch2","C",TamSx3("A2_LOJA")[1],0,0,"G","","","",""   ,"mv_par02","","","","","","","","","","","","","","","","",{},{},{})
PutSx1(cPerg,"03",OemToAnsi("Ped Venda")  ,"","","mv_ch3","C",TamSx3("C5_NUM")[1],0 ,0,"G","","SC5","","","mv_par03","","","","","","","","","","","","","","","","",{},{},{})
PutSx1(cPerg,"04",OemToAnsi("Cod Pag")    ,"","","mv_ch4","C",TamSx3("C7_COND")[1],0,0,"G","","SE4","","","mv_par04","","","","","","","","","","","","","","","","",{},{},{})
//PutSx1(cPerg,"05",OemToAnsi("Tab Preco")  ,"","","mv_ch5","C",TamSx3("DA0_CODTAB")[1],0,0,"G","","DA0","","","mv_par05","","","","","","","","","","","","","","","","",{},{},{})

// Parâmetros para localizar a nota
If !Pergunte(cPerg,.T.)
	Return()
EndIF  

//Gravação pedido de compra
EfetivarPedido()


RETURN   

//chamada da rotina automatica
Static Function _MATA120(aTotItem, aCab)
	
	Private lMsHelpAuto := .T.
	Private lMsErroAuto := .F.
	
	
	//Mata120(1,aCab,aTotItem,3,.T.)    
	MSExecAuto({|v,x,y,z,w,a| MATA120(v,x,y,z,w,a)},1,aCab,aTotItem,3,.T.)
	
	//MSExecAuto({|v,x,y,z| MATA120(v,x,y,z)},1,aCab,aTotItem,3) 
	
   //	Alert("Pedido Gerado, número " +  SC7->C7_NUM)
	
	
	If lMsErroAuto
		MostraErro()
		DisarmTransaction()
	Endif
	
Return

//Monto aheadr e acols
Static Function EfetivarPedido
	
	Private dEntrega  		:= dDatabase
	
	aCab     := {}
	aTotItem := {}
	nItem    := ""
	aItem   := {}

	//Posiciono no cadastro de fornecedores.
	DbSelectArea("SA2")
	DbSetOrder(1)
	DbSeek(xFilial("SA2")+ MV_PAR01 + MV_PAR02 )
	
	//Posiciono na tabela de condição de pagamentos.
	DbSelectArea("SE4")
	DbSetOrder(1)
	DbSeek(xFilial("SE4")+ MV_PAR04  )
	
    //Posiciono no nos itens do pedido de venda.
	dbSelectArea("SC6")
	dbSetOrder(1)
	dbSeek(xFilial("SC6") +  MV_PAR03)   
	
	cDoc := ""
	
	WHILE SC6->(!EOF()) .AND.  XFILIAL("SC6") == SC6->C6_FILIAL .AND. SC6->C6_NUM == MV_PAR03
		
	
			aCab := {;
			{"C7_FILIAL"	,SM0->M0_CODFIL	,Nil},; // Numero do Pedido
			{"C7_NUM",           			,Nil},; // Numero do Pedido
			{"C7_EMISSAO" 	,dDataBase  	,Nil},; // Data de Emissao
			{"C7_FORNECE" 	,SA2->A2_COD 	,Nil},; // Fornecedor
			{"C7_LOJA"    	,SA2->A2_LOJA	,Nil},; // Loja do Fornecedor
			{"C7_COND"    	,SE4->E4_CODIGO ,Nil},; // Condicao de pagamento
			{"C7_TES"     	,Space(3)       ,Nil},; // TES
			{"C7_CONTATO" 	,SA2->A2_CONTATO,Nil},; // Contato
			{"C7_FILENT"  	,SM0->M0_CODFIL	,Nil}}  // Filial Entrega
			
			If Len(aItem) <> 0
				nItem := SomaIt(aItem[1][2])
			Else
				nItem := "0001"
			Endif 
			
			dbSelectArea("SB1")
			dbSetOrder(1)
			dbSeek(xFilial("SB1") + SC6->C6_PRODUTO )
			
			dbSelectArea("SB2")
			dbSetOrder(1)
			if ! dbSeek(xFilial("SB2") + SC6->C6_PRODUTO  + SB1->B1_LOCPAD)  			
			  //	alert("TESTE")						
		     	CRIASB2(SC6->C6_PRODUTO, SB1->B1_LOCPAD)  
		 	endif
		 	IF EMPTY(cDoc)
			 	dbSelectArea("SC7")
				dbSetOrder(1)
				MsSeek(xFilial("SC7")+"ZZZZZZ",.T.)
				dbSkip(-1)
				cDoc := SC7->C7_NUM 
				cDoc := Soma1(cDoc)
			ENDIF
			
			RecLock("SC7", .T.)
				SC7->C7_FILIAL 		:= SM0->M0_CODFIL
				SC7->C7_NUM    		:= cDoc          		
				SC7->C7_EMISSAO 	:= dDataBase  
				SC7->C7_FORNECE  	:= SA2->A2_COD 
				SC7->C7_LOJA     	:= SA2->A2_LOJA	
				SC7->C7_COND    	:= SE4->E4_CODIGO 		
				SC7->C7_CONTATO 	:= SA2->A2_CONTATO
				SC7->C7_FILENT   	:= SM0->M0_CODFIL					
				SC7->C7_ITEM  		:= Alltrim(nItem)		
			    SC7->C7_PRODUTO  	:= SC6->C6_PRODUTO
			    SC7->C7_DESCRI  	:= SB1->B1_DESC  
			    SC7->C7_UM  	    := SB1->B1_UM 
			    SC7->C7_QUANT  		:= SC6->C6_QTDVEN     
			    SC7->C7_PRECO  		:= SC6->C6_PRCVEN 
			    SC7->C7_TOTAL  		:= ( SC6->C6_QTDVEN *  SC6->C6_PRCVEN )	
			    //SC7->C7_TES    		:= MV_PAR06 
			    //SC7->C7_IPI    		:= MV_PAR06 
			    //SC7->C7_PICM  		:= MV_PAR06 
			    //SC7->C7_VALIPI      := MV_PAR06 
				//SC7->C7_VALICM      := MV_PAR06      		        	
	            SC7->C7_DATPRF  	:= dDatabase			
			    SC7->C7_FLUXO  		:= "S"				
			    SC7->C7_DATPRF  	:= dEntrega      			
			    SC7->C7_TIPO   		:= 1      			
			    SC7->C7_LOCAL  		:= SB1->B1_LOCPAD         													
			MsUnLock("SC7")	 
			
			dbSelectArea("SB2")
			dbSetOrder(1)
			if  dbSeek(xFilial("SB2") + SC6->C6_PRODUTO  + SB1->B1_LOCPAD)  			
			  RecLock("SB2" , .F. )
			       SB2->B2_SALPEDI :=   SB2->B2_SALPEDI + SC6->C6_QTDVEN 
			  MsUnLock("SB2")
		 	endif	 			 				
			
			aItem:={;
			{"C7_ITEM"		,Alltrim(nItem)			,Nil},; //Numero do Item		
			{"C7_PRODUTO"	,SC6->C6_PRODUTO    	,Nil},; //Codigo do Produto
			{"C7_QUANT"  	,SC6->C6_QTDVEN     	,Nil},; //Quantidade    
			{"C7_PRECO"	    ,SC6->C6_PRCVEN			,Nil},; // Codigo da tabela de precos 
			{"C7_TES"	    ,MV_PAR06		        	,Nil},; // Codigo da tabela de precos
			{"C7_DATPRF" 	,dDatabase				,Nil},; //Data De Entrega
			{"C7_FLUXO"  	,"S"					,Nil},; //Fluxo de Caixa (S/N)
			{"C7_DATPRF" 	,dEntrega      			,Nil},;
			{"C7_TIPO" 	    ,1      				,Nil},;
			{"C7_LOCAL"  	,SB1->B1_LOCPAD          ,Nil}}  //Localizacao			
			AADD(aTotItem,aItem)
		 
		SC6->(DBSKIP())
	ENDDO 
	
	//{"C7_LOCAL"  	,SC6->C6_LOCAL          ,Nil}}  //Localizacao 
	if !empty(cDoc)
		dbSelectArea("SC7")
		dbSetOrder(1)
		dbSeek(xFilial("SC7") +  cDoc  )  	
   		A120Pedido( 'SC7', SC7->( Recno() ), 4 )  
	endif
	
	If !Empty(aTotItem)
	   //	_MATA120(aTotItem, aCab)
	Else
		MsgInfo("Nao existem registros para o pedido!! Verifique os parametros.","Informacao")
	Endif
	
	
Return


