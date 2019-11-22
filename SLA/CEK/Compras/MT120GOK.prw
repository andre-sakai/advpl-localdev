#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"


//+-----------------------------------------------------------------------------------//
//|Empresa...: C&K
//|Programa..: MT120GOK()
//|Autor.....: Júnior Conte 
//|Data......: 04 de maio de 2018
//|Uso.......: SIGACOM 
//|Versao....: Protheus 12    
//|Descricao.: Ponto de entrada
//|			   Dispara workflow informando que o preço negociado é menor maior que a tabela de preço.
//|Observação:
//+-----------------------------------------------------------------------------------//


User Function MT120GOK()

Local cPedido    :=  PARAMIXB[1] // Numero do Pedido
Local lInclui    :=  PARAMIXB[2] // Inclusão
Local lAltera    :=  PARAMIXB[3] // Alteração
Local lExclusao  :=  PARAMIXB[4] // Exclusão

//Codigo do Usuario para tratamento do Pedido de compras antes da Contabilização.

If lInclui .or. lAltera
	u_Mtaprova(cPedido)
EndIf 

Return               

User Function MTaprova(cPedido)
    Local _cEmail	:= {}      
    
    Private aPrcUlt := {}    
    
    Private  nPrcUC := 0	
	Private  dDtDigit := stod("")
	Private  cDoc	:= "" 
	
	Private  cForne1	:= "" 
	
	Private  nPrcUC2 := 0	
	Private  dDtDigi2 := stod("")
	Private  cDoc2	:= ""
	
	Private  cForne2	:= "" 
	
	Private  nPrcUC3 := 0	
	Private  dDtDigi3 := stod("")
	Private  cDoc3	:= ""
	
	Private  cForne3	:= "" 
	
	
	Private lFlag := .f.
    
    dbSelectArea("SC7")
    dbSetorder(1)
    dbSeek(xFilial("SC7")+Subs(cPedido,1,tamsx3("C7_NUM")[1]))
    
	cQuery1 := ''
	cQuery1 += "SELECT C7_FORNECE, C7_LOJA, C7_PRODUTO, C7_PRECO, C7_EMISSAO, C7_NUM "
	cQuery1 += "FROM "+RetSqlName("SC7")+" "
	cQuery1 += "WHERE D_E_L_E_T_ = ' ' "                                      
	cQuery1 += "AND C7_FILIAL = '"+xFilial("SC7")+"' "
	cQuery1 += "AND C7_NUM = '"+alltrim(cPedido)+"' "


	cQuery1 := ChangeQuery(cQuery1)
	If Select("TRB2") > 0
	     dbSelectARea("TRB2")
	     dbCloseArea()
	Endif
	TCQUERY cQuery1 NEW ALIAS "TRB2" //&cAlias

	dbSelectArea("TRB2")
	dbGoTop()            
	While TRB2->(!eof())
		// Cria um novo processo...    
		
	
		//primeiro ultimo preço
		If Select("QUCOM") <> 0
				dbSelectArea("QUCOM")
				QUCOM->(dbCloseArea())
		EndIf				
		cQuery := " SELECT  D1_FILIAL, D1_COD,D1_SERIE, D1_DOC, D1_VUNIT, D1_DTDIGIT, D1_FORNECE, D1_LOJA, A2_COD, A2_LOJA, A2_NOME, SD1.R_E_C_N_O_ "                
		cQuery += "               FROM "+RetSqlName("SD1")+" SD1 " 
		cQuery += "               Inner Join "+RetSqlName("SF4")+" SF4 on SF4.F4_CODIGO = SD1.D1_TES "
		cQuery += "               Inner Join "+RetSqlName("SB1")+" SB1 on SB1.B1_COD    = SD1.D1_COD " 
		cQuery += "               Inner Join "+RetSqlName("SA2")+" SA2 on SA2.A2_COD    = SD1.D1_FORNECE "
		cQuery += "               WHERE  SD1.D1_FILIAL = '"+xFilial("SD1")+"' AND  SD1.D_E_L_E_T_ = ' ' and SF4.D_E_L_E_T_ = ' '  and SA2.D_E_L_E_T_ = ' ' and SB1.D_E_L_E_T_ = ' '  and SD1.D1_TIPO = 'N'  and SF4.F4_DUPLIC = 'S' and D1_COD = '"+TRB2->C7_PRODUTO+"' "
		cQuery += " ORDER BY SD1.R_E_C_N_O_ DESC  "
		
		TCQuery cQuery NEW ALIAS "QUCOM"   				
		dbSelectArea("QUCOM") 
		if !empty(QUCOM->d1_doc)						
			nPrcUC		:= QUCOM->d1_vunit
			dDtDigit	:= stod(QUCOM->d1_dtdigit)
			cDoc		:= QUCOM->d1_doc  
			
			cForne1		:= QUCOM->A2_COD  + "  " + QUCOM->A2_LOJA + "  "  + QUCOM->A2_NOME  		
		endif  
		
		
		//segundo ultimo preço
		If Select("QUCOM") <> 0
				dbSelectArea("QUCOM")
				QUCOM->(dbCloseArea())
		EndIf				
		cQuery := " SELECT  D1_FILIAL, D1_COD,D1_SERIE, D1_DOC, D1_VUNIT, D1_DTDIGIT, D1_FORNECE, D1_LOJA,  A2_COD, A2_LOJA, A2_NOME, SD1.R_E_C_N_O_ "                
		cQuery += "               FROM "+RetSqlName("SD1")+" SD1 " 
		cQuery += "               Inner Join "+RetSqlName("SF4")+" SF4 on SF4.F4_CODIGO = SD1.D1_TES "
		cQuery += "               Inner Join "+RetSqlName("SB1")+" SB1 on SB1.B1_COD    = SD1.D1_COD " 
		cQuery += "               Inner Join "+RetSqlName("SA2")+" SA2 on SA2.A2_COD    = SD1.D1_FORNECE "
		cQuery += "               WHERE  SD1.D1_FILIAL = '"+xFilial("SD1")+"' AND SD1.D_E_L_E_T_ = ' '   and SA2.D_E_L_E_T_ = ' ' and SD1.D1_DTDIGIT < '" + DTOS(dDtDigit) + "' and SF4.D_E_L_E_T_ = ' ' and SB1.D_E_L_E_T_ = ' '  and SD1.D1_TIPO = 'N'  and SF4.F4_DUPLIC = 'S' and D1_COD = '"+TRB2->C7_PRODUTO+"' "
		cQuery += " ORDER BY SD1.R_E_C_N_O_ DESC  "		
		TCQuery cQuery NEW ALIAS "QUCOM"   				
		dbSelectArea("QUCOM") 
		if !empty(QUCOM->d1_doc)						
			nPrcUC2		:= QUCOM->d1_vunit
			dDtDigi2	:= stod(QUCOM->d1_dtdigit)
			cDoc2		:= QUCOM->d1_doc  	
			
			cForne2		:=  QUCOM->A2_COD  + "  " + QUCOM->A2_LOJA + "  "  + QUCOM->A2_NOME  	
				
		endif  
		
		
		
		//terceiro ultimo preço
		If Select("QUCOM") <> 0
				dbSelectArea("QUCOM")
				QUCOM->(dbCloseArea())
		EndIf				
		cQuery := " SELECT  D1_FILIAL, D1_COD,D1_SERIE, D1_DOC, D1_VUNIT, D1_DTDIGIT, D1_FORNECE, D1_LOJA, A2_COD, A2_LOJA,  A2_NOME,  SD1.R_E_C_N_O_ "                
		cQuery += "               FROM "+RetSqlName("SD1")+" SD1 " 
		cQuery += "               Inner Join "+RetSqlName("SF4")+" SF4 on SF4.F4_CODIGO = SD1.D1_TES "
		cQuery += "               Inner Join "+RetSqlName("SB1")+" SB1 on SB1.B1_COD    = SD1.D1_COD " 
		cQuery += "               Inner Join "+RetSqlName("SA2")+" SA2 on SA2.A2_COD    = SD1.D1_FORNECE "
		cQuery += "               WHERE  SD1.D1_FILIAL = '"+xFilial("SD1")+"' AND SD1.D_E_L_E_T_ = ' '   and SA2.D_E_L_E_T_ = ' ' and SD1.D1_DTDIGIT < '" + DTOS(dDtDigi2) + "' and SF4.D_E_L_E_T_ = ' ' and SB1.D_E_L_E_T_ = ' '  and SD1.D1_TIPO = 'N'  and SF4.F4_DUPLIC = 'S' and D1_COD = '"+TRB2->C7_PRODUTO+"' "
		cQuery += " ORDER BY SD1.R_E_C_N_O_ DESC  "		
		TCQuery cQuery NEW ALIAS "QUCOM"   				
		dbSelectArea("QUCOM") 
		if !empty(QUCOM->d1_doc)						
			nPrcUC3		:= QUCOM->d1_vunit
			dDtDigi3	:= stod(QUCOM->d1_dtdigit)
			cDoc3		:= QUCOM->d1_doc 
			
			cForne3		:=  QUCOM->A2_COD  + "  " + QUCOM->A2_LOJA + "  "  + QUCOM->A2_NOME  	
			
			 	
		endif
		
							
	   	if nPrcUC  > 0 .and.  TRB2->C7_PRECO > nPrcUC
	   	   	if !lFlag
				cProcess := OemToAnsi("001010")
				cStatus  := OemToAnsi("001011")
				oProcess := TWFProcess():New(cProcess,OemToAnsi("Inclusão pedido de compra com preço maior que a ultima compra."))   
			
				oProcess:NewTask(cStatus,"\WORKFLOW\wfAprova.HTML")
				oProcess:cSubject := " Inclusão alteração de pedidos de compra, preço acima do preço praticado."
				oProcess:bReturn  := ""
				oHTML    := oProcess:oHTML 
				
				lFlag := .T. 
				
			endif
			dbSelectArea("SC7")		            
			oHtml:ValByName("emissao",STOD(TRB2->C7_EMISSAO))
			oHtml:ValByName("fornecedor",TRB2->C7_FORNECE) 
			oHtml:ValByName("nomeforn",posicione("SA2",1, xFilial("SA2")+ TRB2->C7_FORNECE + TRB2->C7_LOJA, "A2_NOME"))
			oHtml:ValByName("pedido",TRB2->C7_NUM)
			oHtml:ValByName("produto",TRB2->C7_PRODUTO)
			oHtml:ValByName("preco",transform(TRB2->C7_PRECO, "@E 999,999,999.9999"))  			
	
		   	oHtml:ValByName("UltCompra",transform(nPrcUC, "@E 999,999,999.9999"))   
		  	oHtml:ValByName("DtDigit"  ,dDtDigit) 
			oHtml:ValByName("DocUltComp"  ,cDoc) 
			
			oHtml:ValByName("forne1"  ,cForne1)
			
			if nPrcUC2 > 0
				oHtml:ValByName("UltCompra2",transform(nPrcUC2, "@E 999,999,999.9999") )   
			  	oHtml:ValByName("DtDigit2"  ,dDtDigi2) 
				oHtml:ValByName("DocUltComp2"  ,cDoc2)
				
				oHtml:ValByName("forne2"  ,cForne2)
				
				
			endif
			
			if nPrcUC3 > 0
				oHtml:ValByName("UltCompra3",transform(nPrcUC3, "@E 999,999,999.9999") )   
			  	oHtml:ValByName("DtDigit3"  ,dDtDigi3) 
				oHtml:ValByName("DocUltComp3"  ,cDoc3)
				
				oHtml:ValByName("forne3"  ,cForne3)
				
				
			endif
	
		
	    endif

		TRB2->(dbSkip())
	EndDo 
	
	
	IF 	lFlag
	
		
			oProcess:cTo := 'financeiro@cekacessorios.com.br'
			oHtml:ValByName("data",DTOC(Date()))
			oHtml:ValByName("hora",Time())          
			                
			oProcess:Start()
			oProcess:Finish()    
			
	ENDIF
	
	
	     

Return    


