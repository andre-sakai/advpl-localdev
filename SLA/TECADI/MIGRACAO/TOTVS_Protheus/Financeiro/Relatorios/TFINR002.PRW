#INCLUDE "rwmake.ch"                 
#INCLUDE "topconn.ch"


/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Impressao de Faturas                                    !
+------------------+---------------------------------------------------------+
!Autor             ! DIANA P.KISTNER                                         !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2010                                                 !
+------------------+--------------------------------------------------------*/

User Function TFINR002() 

	Local _aPerg := {}
	Local _cPerg := PadR("TFINR002",Len(SX1->X1_GRUPO))

	// imagem da logo
	private _cImagem := "\"+AllTrim(CurDir())+"\logo_tecadi.jpg"

	// define o grupo de perguntas
	aAdd(_aPerg,{"Prefixo" ,"C",TamSx3("E1_PREFIXO")[1],0,"G",,""}) //mv_par01
	aAdd(_aPerg,{"Número" ,"C",TamSx3("E1_NUM")[1],0,"G",,""}) //mv_par02
	aAdd(_aPerg,{"Tipo" ,"C",TamSx3("E1_TIPO")[1],0,"G",,"05"}) //mv_par03

	// cria grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)
	
	If ! Pergunte(_cPerg,.T.)
		Return ()
	EndIf 


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Variaveis a serem utilizadas para impressao das dupliacatas	 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	
	oFont6 := TFont():New( "Arial" ,,6,,.t.,,,,,.f. )
	oFont7 := TFont():New( "Arial" ,,7,,.t.,,,,,.f. )
	oFont88 := TFont():New( "Arial" ,,8,,.t.,,,,,.f. )
	oFont8 := TFont():New( "Arial Black" ,,9,,.t.,,,,,.f. )
	oFont9 := TFont():New( "Arial" ,,9,,.t.,,,,,.f. )
	oFont10 := TFont():New( "Arial" ,,10,,.t.,,,,,.f. )
	oFont12 := TFont():New( "Arial" ,,12,,.t.,,,,,.f. )
	oFont14 := TFont():New( "Arial" ,,14,,.t.,,,,,.f. )      
	oFont20 := TFont():New( "Arial" ,,20,,.t.,,,,,.F. )     
	oFont48 := TFont():New( "Arial" ,,48,,.t.,,,,,.F. )
		
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicializa a regua de processamento                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	Processa({|| RunCont() },"Processando Impressao...")  
	
Return


Static Function RunCont()
	local _cQuery
	local _nReg
	local _aRecnoSE1

	oPrn := tAvPrinter():New()     


	dbSelectArea("SE1")                            

	// monta a query para filtrar os titulos
	_cQuery := "SELECT SE1.R_E_C_N_O_ SE1RECNO "
	// titulos a receber
	_cQuery += "FROM "+RetSqlName("SE1")+" SE1 "
	_cQuery += "WHERE "+RetSqlCond("SE1")+" "
	_cQuery += "AND E1_PREFIXO = '"+mv_par01+"' "
	_cQuery += "AND E1_NUM     = '"+mv_par02+"' "
	_cQuery += "AND E1_TIPO    = '"+mv_par03+"' "
	_cQuery += "AND E1_SALDO   > 0 "
	_cQuery += "AND E1_TIPO NOT IN "+FormatIN(MVRECANT+MVPROVIS+MV_CRNEG+StrTran(MVABATIM,"|",""),,3)+" "
	// ordem de impressao dos dados
	_cQuery += "ORDER BY E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA "
	// converte os dados da query para vetor
	_aRecnoSE1 := U_SqlToVet(_cQuery)
	
	For _nReg := 1 to Len(_aRecnoSE1)

		IncProc()
		

		// posiciona no registro da tabela SE1
		dbSelectArea("SE1")
		SE1->(dbGoTo(_aRecnoSE1[_nReg]))


		//Linhas do cabecalho               
		oPrn:Line(050, 1300, 400, 1300) 
		oPrn:Box(050, 050, 400, 2350)	
		oPrn:Line(050, 1300, 400, 1300) 

		//Cabecalho            
		oPrn:SayBitmap(080,260,_cImagem,744.8,239.4)
		oPrn:Say(070, 1400,AllTrim(SM0->M0_NOMECOM),oFont14,100)   
		oPrn:Say(160, 1400,AllTrim(SM0->M0_ENDCOB)+" - "+AllTrim(SM0->M0_BAIRCOB),oFont10,100)   
		oPrn:Say(220, 1400,AllTrim(SM0->M0_CIDCOB)+"-"+AllTrim(SM0->M0_ESTCOB)+"  / FONE: "+AllTrim(SM0->M0_TEL)+" FAX: "+AllTrim(SM0->M0_FAX),oFont10,100)   
		oPrn:Say(280, 1400,"CNPJ: "+Transform(SM0->M0_CGC,"@r 99.999.999/9999-99")+"  I.E.: "+AllTrim(SM0->M0_INSC),oFont10,100)   

	                            
    	// DATA 		
    	oPrn:Say(340, 1400,"DATA DE EMISSAO: "+HS_DtoC(SE1->E1_EMISSAO,2),oFont10,100)  

		
		//Linhas da fatura
		oPrn:Box(420, 050, 650, 2050)
		oPrn:Box(420, 2060, 750, 2350)		
		oPrn:Line(490, 500, 650, 500)
		oPrn:Line(420, 950, 650, 950)
		oPrn:Line(490, 1350, 650, 1350)
		oPrn:Say(440, 450,"NOTA FISCAL N.",oFont10 ,100) 
		oPrn:Say(440, 1150,"DUPLICATA",oFont10 ,100) 
		oPrn:Line(490, 050, 490, 1800)        
		oPrn:Line(420, 1800, 650, 1800)
		oPrn:Say(510, 200,"NUMERO",oFont10 ,100) 
		oPrn:Say(510, 650,"VALOR",oFont10 ,100) 
		oPrn:Say(510, 1050,"NUMERO",oFont10 ,100) 
		oPrn:Say(510, 1450,"VALOR",oFont10 ,100) 
		oPrn:Say(440, 1810,"VENCIMENTO",oFont10 ,100) 
		oPrn:Line(560, 050, 560, 2050)    
		oPrn:Say(440, 2100,"PARA USO DA",oFont7 ,100) 
		oPrn:Say(490, 2100,"INST. FINANCEIRA",oFont7 ,100)   
		
		//Linhas do corpo   
		x:=1600
		oPrn:Box(670, 050, x, 400)
		oPrn:Box(770, 410, x, 2350) 
		oPrn:Line(1160, 450, 1160, 2350)     
		oPrn:Line(1320, 450, 1320, 2350)    
		oPrn:Line(1160, 730, 1320, 730)          
//		oPrn:Line(720,340,1650,350)  
		
		//EMITENTE          
		N:=80
		oPrn:Say(730+N, 060,"A",oFont10,100)    
		oPrn:Say(760+N, 060,"S",oFont10,100)   
		oPrn:Say(790+N, 060,"S",oFont10,100)   
		oPrn:Say(820+N, 060,"I",oFont10,100)   
		oPrn:Say(850+N, 060,"N",oFont10,100)   
		oPrn:Say(880+N, 060,"A",oFont10,100)   
		oPrn:Say(910+N, 060,"T",oFont10,100)   
		oPrn:Say(940+N, 060,"U",oFont10,100)   
		oPrn:Say(970+N, 060,"R",oFont10,100)   
		oPrn:Say(1000+N, 060,"A",oFont10,100)    
		
		oPrn:Say(1060+N, 060,"D",oFont10,100)   
		oPrn:Say(1090+N, 060,"O",oFont10,100)   
		
		oPrn:Say(1150+N, 060,"E",oFont10,100)   
		oPrn:Say(1180+N, 060,"M",oFont10,100)   
		oPrn:Say(1210+N, 060,"I",oFont10,100)   
		oPrn:Say(1240+N, 060,"T",oFont10,100)   
		oPrn:Say(1270+N, 060,"E",oFont10,100)   
		oPrn:Say(1300+N, 060,"N",oFont10,100)   
		oPrn:Say(1330+N, 060,"T",oFont10,100)   
		oPrn:Say(1360+N, 060,"E",oFont10,100)   
		
		
		//Desconto
		oPrn:Say(680, 470,"DESCONTO DE:",oFont10,100)      
		oPrn:Say(680, 1700,"ATE:",oFont10,100)         
		oPrn:Say(730, 470,"CONDICOES ESPECIAIS:",oFont10,100) 		
	    		    
		// INFORMACOES DO TITULO
		oPrn:Say(580, 180,AllTrim(SE1->E1_NUM),oFont12,100) 

		// posiciona na nota fiscal
		dbSelectArea("SF2")                            
		SF2->(dbSetOrder(1)) //1-F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_FORMUL, F2_TIPO
   		SF2->(dbSeek( XFILIAL("SF2")+SE1->(E1_NUM+E1_SERIE+E1_CLIENTE+E1_LOJA) ))

	   	oPrn:Say(580, 630,AllTrim(TRANSFORM(SF2->F2_VALBRUT,"@E 999,999.99")),oFont12,100) 
		oPrn:Say(580, 1000,AllTrim(SE1->E1_NUM)+"/"+AllTrim(SE1->E1_PARCELA),oFont12,100) 
		oPrn:Say(580, 1450,AllTrim(TRANSFORM(SE1->E1_VALOR,"@E 999,999.99")),oFont12,100) 
	   	oPrn:Say(580, 1808,DTOC(SE1->E1_VENCREA),oFont12,100) 
	   	
	   	//INFORMACOES DO CLIENTE 
	   	dbSelectArea("SA1")
	   	dbSetOrder(1)
	   	dbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA)   
	   	oPrn:Say(810, 470,"NOME DO SACADO:",oFont10,100)   
	   	oPrn:Say(805, 900,AllTrim(SA1->A1_NOME),oFont12,100)     
	   	oPrn:Say(880, 470,"ENDERECO:",oFont10,100) 
	   	oPrn:Say(875, 900,AllTrim(SA1->A1_END),oFont12,100) 
	   	oPrn:Say(880, 1900,"FONE:",oFont10,100) 
	   	oPrn:Say(875, 2020,SA1->A1_DDD+" "+SA1->A1_TEL,oFont12,100)      
	   	oPrn:Say(950, 470,"MUNICIPIO:",oFont10,100) 
	   	oPrn:Say(945, 900,AllTrim(SA1->A1_MUN),oFont12,100)     
	   	oPrn:Say(950, 1500,"CEP:",oFont10,100) 
	   	oPrn:Say(945, 1600,AllTrim(SA1->A1_CEP),oFont12,100)    
	   	oPrn:Say(950, 2000,"UF:",oFont10,100) 
	   	oPrn:Say(945, 2100,AllTrim(SA1->A1_EST),oFont12,100)    
	   	oPrn:Say(1020, 470,"PRACA PAGTO:",oFont10,100) 
	   	oPrn:Say(1015, 900,"ITAJAÍ/SC",oFont12,100)    
	   	oPrn:Say(1020, 1500,"BAIRRO:",oFont10,100) 
	   	oPrn:Say(1015, 1660,AllTrim(SA1->A1_BAIRRO),oFont12,100)  
	   	oPrn:Say(1090, 470,"INSCR. CNPJ:",oFont10,100) 
	   	oPrn:Say(1085, 900,Transform(SA1->A1_CGC,"@r 99.999.999/9999-99"),oFont12,100)    
	   	oPrn:Say(1090, 1600,"INSCR. EST.:",oFont10,100) 
	   	oPrn:Say(1085, 1900,AllTrim(SA1->A1_INSCR),oFont12,100) 
	   	
	   	// VALOR POR EXTENSO
	   	oPrn:Say(1220, 750,AllTrim(Extenso(SE1->E1_VALOR)),oFont10,100)   
	   	oPrn:Say(1170, 520,"VALOR",oFont10,100)  
	   	oPrn:Say(1220, 540,"POR",oFont10,100) 
	   	oPrn:Say(1270, 500,"EXTENSO",oFont10,100)  
	   	
	   	//RODAPE TEXTO
	   	oPrn:Say(1340, 470,"RECONHEÇO(EMOS) A EXATIDAO DESTA DUPLICATA DE PRESTAÇÃO DE SERVIÇOS, NA IMPORTANCIA ACIMA QUE",oFont9,100)  
	   	oPrn:Say(1380, 470,"PAGAREI(EMOS) A TECADI ARMAZENS GERAIS, OU A SUA ORDEM NA PRAÇA E VENCIMENTO ACIMA INDICADOS.",oFont9,100)  
	   	oPrn:Say(1555, 570,"1. Via",oFont88,100)  
	   	oPrn:Say(1555, 1470,"DATA DO ACEITE",oFont88,100)  
	   	oPrn:Say(1555, 2090,"ASSINATURA",oFont88,100)  
	   	oPrn:Line(1540,1450,1540,1750)
	   	oPrn:Line(1540,1800,1540,2330)
	
//2 via

		//Linhas do cabecalho               
		oPrn:Line(050+x, 1300, 400+x, 1300) 
		oPrn:Box(050+x, 050, 400+x, 2350)	
		oPrn:Line(050+x, 1300, 400+x, 1300) 

		//Cabecalho            
		oPrn:SayBitmap(080+x,260,_cImagem,744.8,239.4)
		oPrn:Say(070+x, 1400,AllTrim(SM0->M0_NOMECOM),oFont14,100)   
		oPrn:Say(160+x, 1400,AllTrim(SM0->M0_ENDCOB)+" - "+AllTrim(SM0->M0_BAIRCOB),oFont10,100)   
		oPrn:Say(220+x, 1400,AllTrim(SM0->M0_CIDCOB)+"-"+AllTrim(SM0->M0_ESTCOB)+"  / FONE: "+AllTrim(SM0->M0_TEL)+" FAX: "+AllTrim(SM0->M0_FAX),oFont10,100)   
		oPrn:Say(280+x, 1400,"CNPJ: "+Transform(SM0->M0_CGC,"@r 99.999.999/9999-99")+"  I.E.: "+AllTrim(SM0->M0_INSC),oFont10,100)   

	                            
    	// DATA 		
    	oPrn:Say(340+x, 1400,"DATA DE EMISSAO: "+HS_DtoC(SE1->E1_EMISSAO,2),oFont10,100)  

		
		//Linhas da fatura
		oPrn:Box(420+x, 050, 650+x, 2050)
		oPrn:Box(420+x, 2060, 750+x, 2350)		
		oPrn:Line(490+x, 500, 650+x, 500)
		oPrn:Line(420+x, 950, 650+x, 950)
		oPrn:Line(490+x, 1350, 650+x, 1350)
		oPrn:Say(440+x, 450,"NOTA FISCAL N.",oFont10 ,100) 
		oPrn:Say(440+x, 1150,"DUPLICATA",oFont10 ,100) 
		oPrn:Line(490+x, 050, 490+x, 1800)        
		oPrn:Line(420+x, 1800, 650+x, 1800)
		oPrn:Say(510+x, 200,"NUMERO",oFont10 ,100) 
		oPrn:Say(510+x, 650,"VALOR",oFont10 ,100) 
		oPrn:Say(510+x, 1050,"NUMERO",oFont10 ,100) 
		oPrn:Say(510+x, 1450,"VALOR",oFont10 ,100) 
		oPrn:Say(440+x, 1810,"VENCIMENTO",oFont10 ,100) 
		oPrn:Line(560+x, 050, 560+x, 2050)    
		oPrn:Say(440+x, 2100,"PARA USO DA",oFont7 ,100) 
		oPrn:Say(490+x, 2100,"INST. FINANCEIRA",oFont7 ,100)   
		
		//Linhas do corpo   
		oPrn:Box(670+x, 050, 2 * x, 400)
		oPrn:Box(770+x, 410, 2 * x, 2350) 
		oPrn:Line(1160+x, 450, 1160+x, 2350)     
		oPrn:Line(1320+x, 450, 1320+x, 2350)    
		oPrn:Line(1160+x, 730, 1320+x, 730)          
//		oPrn:Line(720,340,1650,350)  
		
		//EMITENTE          
		oPrn:Say(730+N+x, 060,"A",oFont10,100)    
		oPrn:Say(760+N+x, 060,"S",oFont10,100)   
		oPrn:Say(790+N+x, 060,"S",oFont10,100)   
		oPrn:Say(820+N+x, 060,"I",oFont10,100)   
		oPrn:Say(850+N+x, 060,"N",oFont10,100)   
		oPrn:Say(880+N+x, 060,"A",oFont10,100)   
		oPrn:Say(910+N+x, 060,"T",oFont10,100)   
		oPrn:Say(940+N+x, 060,"U",oFont10,100)   
		oPrn:Say(970+N+x, 060,"R",oFont10,100)   
		oPrn:Say(1000+N+x, 060,"A",oFont10,100)    
		
		oPrn:Say(1060+N+x, 060,"D",oFont10,100)   
		oPrn:Say(1090+N+x, 060,"O",oFont10,100)   
		
		oPrn:Say(1150+N+x, 060,"E",oFont10,100)   
		oPrn:Say(1180+N+x, 060,"M",oFont10,100)   
		oPrn:Say(1210+N+x, 060,"I",oFont10,100)   
		oPrn:Say(1240+N+x, 060,"T",oFont10,100)   
		oPrn:Say(1270+N+x, 060,"E",oFont10,100)   
		oPrn:Say(1300+N+x, 060,"N",oFont10,100)   
		oPrn:Say(1330+N+x, 060,"T",oFont10,100)   
		oPrn:Say(1360+N+x, 060,"E",oFont10,100)   
		
		
		//Desconto
		oPrn:Say(680+x, 470,"DESCONTO DE:",oFont10,100)      
		oPrn:Say(680+x, 1700,"ATE:",oFont10,100)         
		oPrn:Say(730+x, 470,"CONDICOES ESPECIAIS:",oFont10,100) 		
	    		    
		// INFORMACOES DO TITULO
		oPrn:Say(580+x, 180,AllTrim(SE1->E1_NUM),oFont12,100) 

	   	oPrn:Say(580+x, 630,AllTrim(TRANSFORM(SF2->F2_VALBRUT,"@E 999,999.99")),oFont12,100) 
		oPrn:Say(580+x, 1000,AllTrim(SE1->E1_NUM)+"/"+AllTrim(SE1->E1_PARCELA),oFont12,100) 
		oPrn:Say(580+x, 1450,AllTrim(TRANSFORM(SE1->E1_VALOR,"@E 999,999.99")),oFont12,100) 
	   	oPrn:Say(580+x, 1808,DTOC(SE1->E1_VENCREA),oFont12,100) 
	   	
	   	//INFORMACOES DO CLIENTE 
	   	dbSelectArea("SA1")
	   	dbSetOrder(1)
	   	dbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA)   
	   	oPrn:Say(810+x, 470,"NOME DO SACADO:",oFont10,100)   
	   	oPrn:Say(805+x, 900,AllTrim(SA1->A1_NOME),oFont12,100)     
	   	oPrn:Say(880+x, 470,"ENDERECO:",oFont10,100) 
	   	oPrn:Say(875+x, 900,AllTrim(SA1->A1_END),oFont12,100) 
	   	oPrn:Say(880+x, 1900,"FONE:",oFont10,100) 
	   	oPrn:Say(875+x, 2020,SA1->A1_DDD+" "+SA1->A1_TEL,oFont12,100)      
	   	oPrn:Say(950+x, 470,"MUNICIPIO:",oFont10,100) 
	   	oPrn:Say(945+x, 900,AllTrim(SA1->A1_MUN),oFont12,100)     
	   	oPrn:Say(950+x, 1500,"CEP:",oFont10,100) 
	   	oPrn:Say(945+x, 1600,AllTrim(SA1->A1_CEP),oFont12,100)    
	   	oPrn:Say(950+x, 2000,"UF:",oFont10,100) 
	   	oPrn:Say(945+x, 2100,AllTrim(SA1->A1_EST),oFont12,100)    
	   	oPrn:Say(1020+x, 470,"PRACA PAGTO:",oFont10,100) 
	   	oPrn:Say(1015+x, 900,"ITAJAÍ/SC",oFont12,100)    
	   	oPrn:Say(1020+x, 1500,"BAIRRO:",oFont10,100) 
	   	oPrn:Say(1015+x, 1660,AllTrim(SA1->A1_BAIRRO),oFont12,100)  
	   	oPrn:Say(1090+x, 470,"INSCR. CNPJ:",oFont10,100) 
	   	oPrn:Say(1085+x, 900,Transform(SA1->A1_CGC,"@r 99.999.999/9999-99"),oFont12,100)    
	   	oPrn:Say(1090+x, 1600,"INSCR. EST.:",oFont10,100) 
	   	oPrn:Say(1085+x, 1900,AllTrim(SA1->A1_INSCR),oFont12,100) 
	   	
	   	// VALOR POR EXTENSO
	   	oPrn:Say(1220+x, 750,AllTrim(Extenso(SE1->E1_VALOR)),oFont10,100)   
	   	oPrn:Say(1170+x, 520,"VALOR",oFont10,100)  
	   	oPrn:Say(1220+x, 540,"POR",oFont10,100) 
	   	oPrn:Say(1270+x, 500,"EXTENSO",oFont10,100)  
	   	
	   	//RODAPE TEXTO
	   	oPrn:Say(1340+x, 470,"RECONHEÇO(EMOS) A EXATIDAO DESTA DUPLICATA DE PRESTAÇÃO DE SERVIÇOS, NA IMPORTANCIA ACIMA QUE",oFont9,100)  
	   	oPrn:Say(1380+x, 470,"PAGAREI(EMOS) A TECADI ARMAZENS GERAIS, OU A SUA ORDEM NA PRAÇA E VENCIMENTO ACIMA INDICADOS.",oFont9,100)  
	   	oPrn:Say(1555+x, 570,"2. Via",oFont88,100)  
	   	oPrn:Say(1555+x, 1470,"DATA DO ACEITE",oFont88,100)  
	   	oPrn:Say(1555+x, 2090,"ASSINATURA",oFont88,100)  
	   	oPrn:Line(1540+x,1450,1540+x,1750)
	   	oPrn:Line(1540+x,1800,1540+x,2330)

		oPrn:EndPage()	   	
	    
	Next _nReg	

	oPrn:Preview()	
	oPrn:End()

	MS_FLUSH()   	
	
Return