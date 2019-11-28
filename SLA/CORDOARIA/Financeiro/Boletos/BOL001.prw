#include "rwmake.ch"
#INCLUDE "topconn.ch"     
#INCLUDE "PROTHEUS.CH"  				
#include "TbiConn.ch"


/*                                                                                                                      
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±…ÕÕÕÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕª±±
±±∫Programa  ≥ BOL001   ∫ Autor ≥ SADIOMAR WARMLING  ∫ Data ≥  10/11/06   ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Descricao ≥   Rotina para impress„   o de boleto banc·rio com cÛdigo de∫±±
±±∫          ≥   barras e atualizaÁ„o dos campos do tÌtulo (portador,     ∫±±
±±∫          ≥   borderÙ, nosso n˙mero, juros, etc.)                      ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Uso       ≥ CLIENTES TOTVS                                             ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Campos    ≥                                                            ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫AlteraÁıes: Alterar E1_NUMBCO para tamanho 17                          ∫±±
±±∫AlteraÁıes: Criar indice SEA_A                                         ∫±±
±±»ÕÕÕÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
  */  
  
  
                                                        
User Function BOL001()

    

// DEFINE PERGUNTAS DO SX1
aRegistros:={}
cPerg   :="BOL001"
// cria vetor de perguntas
AADD(aRegistros,{cPerg,"01","Banco               ?"," "," ","mv_ch1","C",03,0,0,"G"," ","mv_par01"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," ","SA6"," "," "," "})
AADD(aRegistros,{cPerg,"02","Agencia             ?"," "," ","mv_ch2","C",05,0,0,"G"," ","mv_par02"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "})
AADD(aRegistros,{cPerg,"03","Conta-Corrente      ?"," "," ","mv_ch3","C",10,0,0,"G"," ","mv_par03"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "})
AADD(aRegistros,{cPerg,"04","Subconta            ?"," "," ","mv_ch4","C",03,0,0,"G"," ","mv_par04"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "})
AADD(aRegistros,{cPerg,"05","Prefixo             ?"," "," ","mv_ch5","C",03,0,0,"G"," ","mv_par05"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "})
AADD(aRegistros,{cPerg,"06","Do titulo           ?"," "," ","mv_ch6","C",06,0,0,"G"," ","mv_par06"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "})
AADD(aRegistros,{cPerg,"07","Ate titulo          ?"," "," ","mv_ch7","C",06,0,0,"G"," ","mv_par07"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "})
AADD(aRegistros,{cPerg,"08","N∫ Bordero          ?"," "," ","mv_ch8","C",06,0,0,"G"," ","mv_par08"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "})
AADD(aRegistros,{cPerg,"09","Filtra por          ?"," "," ","mv_ch9","N",01,0,0,"C"," ","mv_par08","Numero"," "," "," "," ","Bordero"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "})
AADD(aRegistros,{cPerg,"10","% de Juros ao MÍs   ?"," "," ","mv_chA","N",14,2,0,"G"," ","mv_par09"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "})
AADD(aRegistros,{cPerg,"11","% de Multa          ?"," "," ","mv_chB","N",14,2,0,"G"," ","mv_par10"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "})
AADD(aRegistros,{cPerg,"12","Terceira Mensagem   ?"," "," ","mv_chC","C",50,0,0,"G"," ","mv_par11"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "})
AADD(aRegistros,{cPerg,"13","Parcela             ?"," "," ","mv_chD","C",01,0,0,"G"," ","mv_par12","S"," "," "," "," ","N"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "})
AADD(aRegistros,{cPerg,"14","Imprime Sld/Orig    ?"," "," ","mv_chE","C",01,0,0,"G"," ","mv_par13","Saldo"," "," "," "," ","Original"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "})


// verifica existÍncia de perguntas

dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)
For i:=1 to Len(aRegistros)
    If !dbSeek(cPerg+aRegistros[i,2])
        RecLock("SX1",.T.)
        For j:=1 to FCount()
            If j <= Len(aRegistros[i])
                FieldPut(j,aRegistros[i,j])
            Endif
        Next
        MsUnlock()
    Endif
Next


If Pergunte(cPerg,.T.)  


    // testa se titulo informado possui Portador
	dbSelectArea("SE1")
	dbSetOrder(1)   // prefixo+numero
	dbGoTop()
	IF EMPTY(MV_PAR13)
		dbSeek(xFilial("SE1")+MV_PAR05+MV_PAR06)
	ELSE
		dbSeek(xFilial("SE1")+MV_PAR05+MV_PAR06+MV_PAR13)
	ENDIF
	lFound := .F.      
	While !lFound .And. !Eof() .And. E1_FILIAL == xFilial("SE1") .And. E1_PREFIXO == MV_PAR05 .And. (E1_NUM >= MV_PAR06 .and. E1_NUM <= MV_PAR07)
	    If !Empty(MV_PAR13) .And. !(E1_PARCELA == MV_PAR13)
	        dbSkip()
	        Loop
	    Endif   
	    If E1_TIPO == "NCC" .Or. E1_TIPO="AB-" 
	        dbSkip()
	        Loop
	    Endif                                                                                                                 
	    If E1_SALDO <= 0
	        dbSkip()
	        Loop
	    Endif    
	    lFound := .T. 
	Enddo
	
	If !lFound
	    MsgBox("Titulo informado n„o foi encontrado!!!","ATEN«√O!!!")
        Return
    Endif     

    If SE1->E1_SALDO <= 0 
	    MsgBox("Titulo informado est· com Saldo zerado!!!","ATEN«√O!!!")
        Return
    Endif     
    
//    If MV_PAR01 == '237' .And. MV_PAR02 == '26565' .And. MV_PAR03 == '0076000519' .And. !(MV_PAR04 == '19 ')
//	    MsgBox("Carteira deve ser 09 para Banco/Agencia/Conta informado!!!","ATEN«√O!!!")
//        Return
//    Endif
    
    If Empty(SE1->E1_PORTADO)
        
        _cPortad := GetMV("MV_BCOCNAB")  
   		_cPortad += Space(18-Len(_cPortad)) 
		If !Empty(_cPortad)
		    _cBcoTit := Left(_cPortad,3)
			_cAgeTit := Substr(_cPortad,4,5)
			_cCtaTit := Substr(_cPortad,9,10)		
		  ELSE                                   
		    _cBcoTit := Space(3)            
			_cAgeTit := Space(5)
			_cCtaTit := Space(10)
		Endif      
		
		//BANCO BRADESCO
		IF _cBcoTit == "237"  
           IF _cAgeTit == "72524" .AND. ALLTRIM(_cCtaTit) == "00751731"
		       MV_PAR01 := "237"
		       MV_PAR02 := "72524"
		       MV_PAR03 := "00751731"
		       MV_PAR04 := '09 '
		   ElseIf _cAgeTit == "26565" .AND. ALLTRIM(_cCtaTit) == "0076001302"
		       MV_PAR01 := '237'
		       MV_PAR02 := '26565'
		       MV_PAR03 := '0076001302'
		       MV_PAR04 := '02 '
		   Else	
		       MsgBox("Portador configurado em <MV_BCOCNAB> È inv·lido!", "WM002 Bradesco "+AllTrim(_cPortad))
	           Return
		   ENDIF
		ENDIF 
        //FIM BANCO BRADESCO
        
        //BANCO PARANA		
		IF _cBcoTit == "254"     
		   IF _cAgeTit == "00010" .AND. ALLTRIM(_cCtaTit) == "0014955812"
	           MV_PAR01 := '254'
	    	   MV_PAR02 := '00010'
	       	   MV_PAR03 := '0014955812'
	       	   MV_PAR04 := '112' 
           ELSE
		   	   MsgBox("Portador configurado em <MV_BCOCNAB> È inv·lido!", "WM002 Parana "+AllTrim(_cPortad))
               Return
           ENDIF
		ENDIF  
		//FIM BANCO PARANA
        
        //BANCO SAFRA		
		IF _cBcoTit == "422"     
		   IF _cAgeTit == "08800" .AND. ALLTRIM(_cCtaTit) == "0201172302"
	           MV_PAR01 := '422'
	    	   MV_PAR02 := '08800'
	       	   MV_PAR03 := '0201172302'
	       	   MV_PAR04 := '02 '                                      
           ELSE
		   	   MsgBox("Portador configurado em <MV_BCOCNAB> È inv·lido!", "WM002 Safra "+AllTrim(_cPortad))
               Return
           ENDIF
		ENDIF  
		//FIM BANCO SAFRA
		
		//BANCO SANTANDER		
		IF _cBcoTit == "033"     
		   IF _cAgeTit == "01473" .AND. ALLTRIM(_cCtaTit) == "0130063764"
	           MV_PAR01 := '033'
	    	   MV_PAR02 := '01473'
	       	   MV_PAR03 := '0130063764'
	       	   MV_PAR04 := '22 ' 
           ELSE
		   	   MsgBox("Portador configurado em <MV_BCOCNAB> È inv·lido!", "WM002 Santander "+AllTrim(_cPortad))
               Return
           ENDIF
		ENDIF  
		//FIM BANCO SANTANDER
		 
		IF _cBcoTit == "001"     // BANCO DO BRASIL
	       //IF _cAgeTit == "18368"
			IF _cAgeTit == "18368" .AND. ALLTRIM(_cCtaTit) == "0030953201" 
	       		MV_PAR01 := '001'
	       		MV_PAR02 := '18368'
	       		MV_PAR03 := '0030953201'
	       		MV_PAR04 := '001' 
	       	elseIF _cAgeTit == "29823" .AND. ALLTRIM(_cCtaTit) == "309532" 
	       		MV_PAR01 := '001'
	       		MV_PAR02 := '29823'
	       		MV_PAR03 := '309532'
	       		MV_PAR04 := '001' 
	    		ELSE		       
			   MsgBox("Portador configurado em <MV_BCOCNAB> È inv·lido!", "WM002 BB "+AllTrim(_cPortad))
	           Return 
	        ENDIF   
        ENDIF
               
		IF _cBcoTit == "341"     // BANCO ITAU     
        	//IF AllTrim(_cCtaTit) == "122808" 
        		IF _cAgeTit == "07365" .AND. ALLTRIM(_cCtaTit) == "0012280809"
		       MV_PAR01 := '341'
		       MV_PAR02 := '07365'
		       MV_PAR03 := '0012280809'
		       MV_PAR04 := '109'     
            //ELSEIF AllTrim(_cCtaTit) == "123533"
            ELSEIF _cAgeTit == "07365" .AND. ALLTRIM(_cCtaTit) == "0012353309"
		       MV_PAR01 := '341'
		       MV_PAR02 := '07365'
		       MV_PAR03 := '0012353309'
		       MV_PAR04 := '109'    
		    //ELSEIF ALLTRIM(_cCtaTit) == "027078"  //BANCO VOTORANTIM
		    ELSEIF _cAgeTit == "01248" .AND. ALLTRIM(_cCtaTit) == "0002707809" 
    	       MV_PAR01 := '341'
	       	   MV_PAR02 := '01248'
	       	   MV_PAR03 := '0002707809'
	       	   MV_PAR04 := '109'     
	        ELSEIF _cAgeTit == "07365" .AND. ALLTRIM(_cCtaTit) == "0015046009" 
    	       MV_PAR01 := '341'
	       	   MV_PAR02 := '07365'
	       	   MV_PAR03 := '0015046009'
	       	   MV_PAR04 := '109'     
            ELSEIF alltrim(_cAgeTit) == "7365" .AND. ALLTRIM(_cCtaTit) == "122808"
		       MV_PAR01 := '341'
		       MV_PAR02 := '7365' + space(01)
		       MV_PAR03 := '122808' + space(04)
		       MV_PAR04 := '109'    
	        ELSE
	           MsgBox("Portador configurado em <MV_BCOCNAB> È inv·lido!", "WM002 Itau/Votorantim "+AllTrim(_cPortad)) 
	           Return
		    ENDIF 
		    
		ENDIF   

	    IF _cBcoTit == "104"     // CAIXA ECONOMICA FEDERAL
	       IF AllTrim(_cCtaTit) == "0002163312"
		       MV_PAR01 := '104'
	    	   MV_PAR02 := '18686'
	       	   MV_PAR03 := '0002163312'
	       	   MV_PAR04 := '12'  
           ELSE
		   	   MsgBox("Portador configurado em <MV_BCOCNAB> È inv·lido!", "WM002 CEF "+AllTrim(_cPortad))
               Return
           ENDIF
		ENDIF  
		
		IF _cBcoTit == "745"     // CITIBANK
		   //IF AllTrim(_cCtaTit) == "3499590014"
		   IF _cAgeTit == "00125" .AND. ALLTRIM(_cCtaTit) == "3499590014"
	           MV_PAR01 := '745'
	    	   MV_PAR02 := '00125'
	       	   MV_PAR03 := '3499590014'
	       	   MV_PAR04 := '314' 
	       ELSEIF _cAgeTit == "00125" .AND. ALLTRIM(_cCtaTit) == "3499590012"
	           MV_PAR01 := '745'
	    	   MV_PAR02 := '00125'
	       	   MV_PAR03 := '3499590012'
	       	   MV_PAR04 := '112'
           ELSE
		   	   MsgBox("Portador configurado em <MV_BCOCNAB> È inv·lido!", "WM002 CITIBANK "+AllTrim(_cPortad))
               Return
           ENDIF
		ENDIF   

    ENDIF
    //Msgbox('Banco: '+MV_PAR01+"-"+MV_PAR02+"-"+MV_PAR03+"-"+MV_PAR04)  
	//u_WM002A(MV_PAR01,MV_PAR02,MV_PAR03,MV_PAR04,MV_PAR05,MV_PAR06,MV_PAR07,MV_PAR08,MV_PAR09,MV_PAR10,MV_PAR11,MV_PAR12,MV_PAR13)
	u_WM002A(MV_PAR01,MV_PAR02,MV_PAR03,MV_PAR04,MV_PAR05,MV_PAR06,MV_PAR07,MV_PAR08,MV_PAR09,MV_PAR10,MV_PAR11,MV_PAR12,MV_PAR13,MV_PAR14)
ENDIF

Return()


***********************************************************************************************************************
User Function WM002A(sPAR01,sPAR02,sPAR03,sPAR04,sPAR05,sPAR06,sPAR07,sPAR08,sPAR09,nPAR10,nPAR11,sPAR12,sPAR13,sPAR14)
*********************************************************************************************************************** 

Local _cEMAIL := "emarquetti@cordoariabrasil.com.br"

Private sPAR01,sPAR02,sPAR03,sPAR04,sPAR05,sPAR06,sPAR07,sPAR08,sPAR09,nPAR10,nPAR11,sPAR12,sPAR13,sPAR14
Private cBanco 	:= ""
Private cAgencia 	:= ""
Private cConta 		:= ""
Private cSubConta 	:= ""
Private cDigitao	:= ""
Private nLastKey    := 0
Private cPerguntas  := .T.
Private cPerg
Private oFont, cCode
Private cBarraFim
Private aBancos		:= {}
Private nPOS		:= 0
// RCO (16/03/2010)
Private lProtesto	:= .T. 
Private lTitAnt, dNewVen, nVlrCob 
Private cAmbiente   := GetEnvServer() 
Private NOSSONUM	:= ""
cBarraImp := Space(50)
nHeight:=15
lBold:= .F.
lUnderLine:= .F.
lPixel:= .T.
lPrint:=.F.
nSedex := 1
MsgInstr01	:= " "
MsgInstr02	:= " "
MsgInstr03	:= " "

AADD(aBancos, { "237","BRADESCO"		,"BRADESCO.BMP"	,"237-2","19"  	,"" ,"" ,"" ,"" ,5  })
AADD(aBancos, { "237","BRADESCO"		,"BRADESCO.BMP"	,"237-2","02"  	,"" ,"" ,"" ,"" ,5  })
AADD(aBancos, { "104","CEF"		       	,"CAIXA.BMP"	,"104-0","CR" 	,"1868870000009410" ,"" ,"" ,"" ,5 })  																		  
AADD(aBancos, { "341","ITAU"			,"ITAU.BMP"	    ,"341-7","109" 	,"" ,"" ,"" ,"" ,5 })
AADD(aBancos, { "001","BANCO DO BRASIL"	,"BBRASIL.BMP"	,"001-9","001" 	,"1126576" ,"" ,"" ,"" ,5 })  
AADD(aBancos, { "745","CITIBANK"        ,"CITIBANK.BMP"	,"745-0","314" 	,"" ,"" ,"" ,"" ,5 }) 
AADD(aBancos, { "745","CITIBANK"        ,"CITIBANK.BMP"	,"745-0","112" 	,"" ,"" ,"" ,"" ,5 })
AADD(aBancos, { "422","SAFRA"           ,"SAFRA.BMP"	,"422-7","2  " 	,"" ,"" ,"" ,"" ,5 })
AADD(aBancos, { "033","SANTANDER"       ,"SANTANDER.JPG","033-7","101" 	,"" ,"" ,"" ,"" ,5 })
AADD(aBancos, { "254","PARANA"          ,"BRADESCO.BMP" ,"237-2","19" 	,"" ,"" ,"" ,"" ,5 })


oFont1 := TFont():New( "Times New Roman",,08,,.t.,,,,,.f. )
oFont2 := TFont():New( "Times New Roman",,10,,.t.,,,,,.f. )
oFont3 := TFont():New( "Times New Roman",,12,,.t.,,,,,.f. )
oFont4 := TFont():New( "Times New Roman",,14,,.t.,,,,,.f. )
oFont5 := TFont():New( "Times New Roman",,16,,.t.,,,,,.f. )

oFont6 := TFont():New( "HAETTENSCHWEILLER",,10,,.t.,,,,,.f. )

oFont8 := TFont():New( "Free 3 of 9" ,,44,,.t.,,,,,.f. )
oFont10:= TFont():New( "Free 3 of 9" ,,38,,.t.,,,,,.f. )

oFont11:= TFont():New( "Courier New" ,,10,,.t.,,,,,.f. )
oFont12:= TFont():New( "Courier New" ,,11,,.t.,,,,,.f. )
oFont13:= TFont():New( "Arial"       ,,06,,.f.,,,,,.f. )
oFont14:= TFont():New( "Courier New"   ,,09,,.T.,,,,,.f. )
oFont15:= TFont():New( "Arial"         ,,10,,.t.,,,,,.f. )
oFont16:= TFont():New( "Arial"         ,,10,,.f.,,,,,.f. )
oFont17:= TFont():New( "Arial"         ,,07,,.T.,,,,,.f. )
oFont18:= TFont():New( "Arial"         ,,09,,.T.,,,,,.f. )
oFont19:= TFont():New( "Arial"         ,,22,,.t.,,,,,.f. )
oFont20:= TFont():New( "Arial Black"   ,,12,,.f.,,,,,.f. )
oFont21:= TFont():New( "Arial"         ,,14,,.f.,,,,,.f. )
oFont22:= TFont():New( "Arial"         ,,11,,.t.,,,,,.f. )
oFont23:= TFont():New( "Arial Black"   ,,15.7,,.t.,,,,,.f. )
oFont24 := TFont():New( "Times New Roman",,14,,.t.,,,,,.f. )

oPrn := TMSPrinter():New()
//oPrn:Setup()
//oPrn:EndPage()
//oPrn:StartPage()  

IF !sPAR01$"104|237|001|341|745|422|033|254"
	APMSGALERT("Rotina habilitada apenas para os bancos Bradesco (237), CEF (104), BB (001), ITAU (341), CITIBANK (745) e SAFRA (422)")
	Return()
//ELSEIF sPAR01=="237" .AND. !(ALLTRIM(sPAR04)$"19/02")
//	APMSGALERT("Para o banco Bradesco (237) obrigatoriamente a subconta deve ser 19 ou 02.")
//	Return()
ELSEIF sPAR01=="001" .AND. ALLTRIM(sPAR04)<>"001"
	APMSGALERT("Para o banco Banco do Brasil (001) obrigatoriamente a subconta deve ser 001.")
	Return()
ELSEIF sPAR01=="341" .AND. ALLTRIM(sPAR04)<>"109"
	APMSGALERT("Para o banco Itau ou Votorantim(341) obrigatoriamente a subconta deve ser 109.")
	Return()
ELSEIF sPAR01=="104" .AND. !(ALLTRIM(sPAR04)$"12/CR")
	APMSGALERT("Para o banco C.E.F. (104) obrigatoriamente a subconta deve ser 12.")
	Return()  
ELSEIF sPAR01=="745" .AND. !(ALLTRIM(sPAR04)$"314/112")
	APMSGALERT("Para o banco CITIBANK. (745) obrigatoriamente a subconta deve ser 314 ou 112.")
	Return()
ELSEIF sPAR01=="422" .AND. !(ALLTRIM(sPAR04)$"02")
	APMSGALERT("Para o banco SAFRA. (745) obrigatoriamente a subconta deve ser 02.")
	Return()	
ELSEIF sPAR01=="033" .AND. !(ALLTRIM(sPAR04)$"22")
	APMSGALERT("Para o banco SAFRA. (033) obrigatoriamente a subconta deve ser 22.")
	Return()
ELSEIF sPAR01=="254" .AND. !(ALLTRIM(sPAR04)$"112")
	APMSGALERT("Para o banco PARANA. (112) obrigatoriamente a subconta deve ser 112.")
	Return()
ENDIF 

//inclui digito conta bradesco portonave
//if sPAR01=="237" .and. sPAR02=="2656 "
//	cAgeImp:=Alltrim(sPAR02)+"5"
//elseif sPAR01=="237" .and. sPAR02=="04130"
//  cAgeImp:="41300" 
//else
  cAgeImp:=sPAR02
//endif

// PESQUISA POR N⁄MERO DE TITULO
If sPAR09==1
	dbSelectArea("SE1")
	SE1->(dbSetOrder(1))   // prefixo+numero
	SE1->(dbgotop())
	IF EMPTY(sPAR13)
    	SE1->(dbSeek(xFilial("SE1")+sPAR05+sPAR06,.T.))
  		cCondicao := "SE1->E1_FILIAL=='"+xFilial("SE1")+"' .AND. SE1->E1_PREFIXO=='"+sPAR05+"' .AND. SE1->E1_NUM >='"+sPAR06+"' .AND. SE1->E1_NUM <='"+sPAR07+"'"  
	ELSE
		SE1->(dbSeek(xFilial("SE1")+sPAR05+sPAR06+sPAR13,.T.))
		cCondicao := "SE1->E1_FILIAL=='"+xFilial("SE1")+"' .AND. SE1->E1_PREFIXO=='"+sPAR05+"' .AND. SE1->E1_NUM <='"+sPAR07+"' .AND. SE1->E1_PARCELA=='"+sPAR13+"' "
	ENDIF  
	Else
	IF  !empty(sPAR08)
		SE1->(dbSetOrder(5))   // bordero
		SE1->(dbgotop())
		SE1->(dbSeek(xFilial("SE1")+alltrim(sPAR08),.T.))
		cCondicao := "SE1->E1_FILIAL=='"+xFilial("SE1")+"' .AND. SE1->E1_NUMBOR=='"+alltrim(sPAR08)+"'"
	else
		MSGBOX("Nao foi preenchido o Numero do Bordero","Aviso","STOP")
		Return
	endif
EndIf
cAbatimento := MVABATIM +"|"+MVFUABT+"|"+MV_CRNEG+"|"+MVRECANT
cAbatimento := strtran(cAbatimento,"|","','")

If Select("WM002") > 0 
	dbSelectArea("WM002")
   dbCloseArea()
EndIf

// query para seleÁ„o de tÌtulos
cquery := " select " 
cQuery += " E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO "                   
cquery += " from " + retSqlName("SE1") + " SE1 "
cquery += " where SE1.D_E_L_E_T_ <> '*' "
cquery += " and E1_PREFIXO = '" + sPar05 + "' "	
cquery += " and E1_NUM between '" + sPar06 + "' and '" + sPar07 + "' "
cquery += " and E1_TIPO not in ('" + cAbatimento + "') "

if !empty(sPAR08)
	cquery += " and E1_NUMBOR = '" + sPar08 + "' "
endif	

cQuery += " order by E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO "

TCQuery cQuery NEW ALIAS "WM002"

// PROCESSA INTERVALO DE TÕTULOS CONFORME PAR¬METRO
While WM002->(!Eof()) 
	
	dbSelectArea("SE1")
	dbsetorder(1)
	dbseek(WM002->E1_FILIAL + WM002->E1_PREFIXO + WM002->E1_NUM + WM002->E1_PARCELA + WM002->E1_TIPO)
	
	If SUBSTR(SE1->E1_TIPO,3,1) == "-"
		SE1->(dbSkip())
		Loop
	Endif

	// VERIFICA PORTADOR
	// - caso n„o tenha portador definido pega do cadastro do cliente
	// RCO (29/05/11)
	//IF EMPTY(SE1->E1_PORTADO)
	IF EMPTY(SE1->E1_PORTADO) .AND. SE1->E1_SALDO > 0
//		if(cBanco <> "001" .and. cConta <> "309532")
//			cBanco	 	:= sPAR01
//			cAgencia 		:= sPAR02
//			cConta	 	:= sPAR03
//			cSubConta		:= sPAR04
//		else   	    
	   	    cBanco 		:= padr(alltrim(sPAR01)	,tamSx3("EE_CODIGO")[01])
	   	    cAgencia 	:= padr(alltrim(sPAR02)	,tamSx3("EE_AGENCIA")[01])
	   	    cConta		:= padr(alltrim(sPAR03)	,tamSx3("EE_CONTA")[01])
	   	    cSubconta	:= padr(alltrim(sPAR04)	,tamSx3("EE_SUBCTA")[01])
//		endif
		dbSelectArea("SEE")
		dbSetOrder(1)
		IF dbSeek(XFILIAL("SEE")+cBanco+cAgencia+cConta+cSubConta)   		
			RecLock("SE1",.F.)
				Replace SE1->E1_PORTADO	with SEE->EE_CODIGO
				Replace SE1->E1_AGEDEP	with SEE->EE_AGENCIA
				Replace SE1->E1_CONTA	with SEE->EE_CONTA
				Replace SE1->E1_NUMBCO	with space(TamSx3("E1_NUMBCO")[1])
			MsUnLock()
		ELSE
			APMSGALERT("N„o foi localizada registro na tabela 'Parametros Banco' para o banco+agencia+conta+subconta informados","DADOS INVALIDOS")
			Return .F.
		ENDIF
	ELSEIF SE1->E1_PORTADO == sPAR01
		cBanco 		:= SE1->E1_PORTADO
		cAgencia	:= SE1->E1_AGEDEP
		cConta		:= SE1->E1_CONTA
//		cSubConta   := Posicione("SA6",1,xFilial("SA6")+cBanco+cAgencia+cConta,"A6_SUBCONT")
		dbSelectArea("SEE")
		dbSetOrder(1)
		dbSeek(XFILIAL("SEE")+SE1->E1_PORTADO+SE1->E1_AGEDEP+SE1->E1_CONTA) //+cSubConta)
	ELSE
		APMSGALERT("O boleto para o titulo "+SE1->E1_PREFIXO+"/"+SE1->E1_NUM+"-"+SE1->E1_PARCELA+" n„o ser· impresso pois o portador gravado nele ("+SE1->E1_PORTADO+") È diferente do informado ("+sPAR01+")")
		WM002->(dbSkip())
		Loop
	ENDIF  
	
	// VERIFICA A SITUA«√O DO TÕTULO
	// - se estiver em carteira ("0") muda para cobranÁa simples ("1")
	// - caso o usu·rio deseja outro tipo de cobranÁa dever· fazer manutenÁ„o do tÌtulo posteriormente
	// - altera tambÈm a ocorrÍncia para "01" (registro)
	// RCO (29/05/11)

	IF SE1->E1_SALDO > 0
		RecLock("SE1",.F.)
			IF SE1->E1_SITUACA=="0"
				Replace SE1->E1_SITUACA with "1"
			ENDIF
			IF EMPTY(SE1->E1_OCORREN)
				Replace SE1->E1_OCORREN	with "01"
			ENDIF
			IF SE1->E1_PORTADO=="237" .And. SE1->E1_AGEDEP=="26565" .And. SE1->E1_CONTA=="0076001302" 
				Replace SE1->E1_SITUACA with "4"            // cobranca vinculada
			ENDIF
			IF SE1->E1_PORTADO=="341" .And. SE1->E1_AGEDEP=="07365" .And. SE1->E1_CONTA=="0012353309" 
				Replace SE1->E1_SITUACA with "4"            // cobranca vinculada
			ENDIF
			IF SE1->E1_PORTADO=="745" .And. SE1->E1_AGEDEP=="00125" .And. SE1->E1_CONTA=="3499590014" 
				Replace SE1->E1_SITUACA with "3"            // cobranca caucionada
			ENDIF
			IF SE1->E1_PORTADO=="422" .And. SE1->E1_AGEDEP=="08800" .And. SE1->E1_CONTA=="0201172302" 
				Replace SE1->E1_SITUACA with "4"            // cobranca vinculada
			ENDIF
		MsUnLock()
	ENDIF
	
	// IDENTIFICA O BANCO PARA OBTEN«√O DOS PAR¬METROS
	// - se n„o for nenhum dos bancos prÈ-determinados n„o imprime o boleto  
	
    If sPAR01     == "237" .And. sPAR03 == "00751731"   
       nPOS := 1
    ElseIf sPAR01 == "237" .And. sPAR03 == "0076001302"   
       nPOS := 2
    ElseIf sPAR01 == "745" .And. sPAR03 == "3499590014"
       nPOS := 6  
    ElseIf sPAR01 == "745" .And. sPAR03 == "3499590012"
       nPOS := 7  
    ElseIf sPAR01 == "001" .And. sPAR03 == "0030953201" // RIBAS
       nPOS := 5   
    ElseIf sPAR01 == "001" .And. sPAR03 == "309532" 
       nPOS := 5   
    Else
	   nPOS := ASCAN(aBancos,{|x| x[1]==cBanco})
	Endif
	   
	IF nPOS==0
		dbSelectArea("SE1")
		dbSkip()
		Loop
	ENDIF
	// OBT…M C”DIGO DE CEDENTE DO PAR¬METRO DE BANCO J¡ POSICIONADO
	IF cBanco=="237"        // bradesco
		cCodced			:= 	transform(STRZERO(VAL(Alltrim(STRTRAN(SEE->EE_CODEMP,"-",""))),8),"@R 9999999-9")
		cContaSEE		:=  Left(cConta,8)
	ELSEIF cBanco=="422"        // Safra
		cCodced			:= 	"08800"
		cContaSEE		:=  "002011723"
	ELSEIF cBanco=="104" .AND. cAgencia=="18686"   // cef
		cCodced			:= "18688" //	Substr(cAgencia,4)+"-"+Substr(cAgencia,5,1) //"0921870000013101"	//"0092000030030769"
		cContaSEE		:= "0021633" //   SUBSTR(cConta,1,4)+"-"+Substr(cConta,8,1)   //"000013101"	//"030030769"
	ELSEIF cBanco=="341" .AND. cAgencia=="01248"      //  VOTORANTIM
		cCodced			:= 	"1248"
		cContaSEE		:=  "027078"
    ELSEIF cBanco=="341" .AND. cAgencia=="07365"	  //ITAU
		cCodced			:= 	SUBSTR(cAgencia,2,4)
		cContaSEE		:=  SUBSTR(cConta,3,5)+"-"+Substr(cConta,8,1)   
    ELSEIF cBanco=="341" .AND. alltrim(cAgencia)=="7365"	  //ITAU // tadeu - 20161019
		cCodced			:= 	SUBSTR(cAgencia,1,4)
		cContaSEE		:=  SUBSTR(cConta,1,5) + "-" + Substr(cConta,6,1)   

	ELSEIF cBanco=="745" //CITIBANK
		cCodced			:= 	Substr(cAgencia,2,4)
		cContaSEE		:=  "0093545028"  
	    //Left(cConta,5)+"-"+Substr(cConta,6,1)   
	ELSEIF cBanco=="001"    // banco do brasil
		cCodced			:= 	"18368"	//"0092000030030769"      // RIBAS
		cContaSEE		:=  "0030953201"	//"030030769"
	ELSEIF cBanco == "001"    // banco do brasil
		cCodced		:= 	"29823"
		cContaSEE		:=  "309532"
	ELSEIF cBanco=="033"    // BANCO SANTANDER
		cCodced			:= 	"01473"	//"0092000030030769"
		cContaSEE		:=  "0130063764"	//"030030769"
	ELSEIF cBanco=="254"    // BANCO PARANA
		cCodced			:= 	"00010"	//"0092000030030769"
		cContaSEE		:=  "149558"	//"030030769"
	ENDIF    
                               
    IF cBanco == "254"
    	aBancos[nPOS,5] :=  "19" 
    ELSEIF cBanco == "237" .AND. cCOnta=="0076000519" 
    	aBancos[nPOS,5] :=  "19"                      
    ELSEIF cBanco == "237" .AND. cCOnta=="0076001302" 
    	aBancos[nPOS,5] :=  "02"  
    ELSEIF cBanco == "001" .And. cCOnta == "0030953201"   // RIBAS
    	aBancos[nPOS,5] :=  "00"
    ELSEIF cBanco == "001" .And. cCOnta == "309532"
    	aBancos[nPOS,5] :=  "00"
    ELSE
    	aBancos[nPOS,5] :=  ALLTRIM(SEE->EE_SUBCTA)    
    ENDIF
    	
	aBancos[nPOS,6] :=  cCodCed
                    
	//  GRAVACAO DO FLAG DE IMPRESS√O
	// OBT…M NOSSO N⁄MERO

	IF !EMPTY(SE1->E1_NUMBCO)  
		nossonum := Alltrim(SE1->E1_NUMBCO)  
	ELSE
		// OBT…M NOSSO N⁄MERO DOS PAR¬METROS DE BANCO J¡ POSICIONADO
		//dbSelectArea("SEE")
		//dbSetOrder(1)
		//dbSeek(XFILIAL("SEE")+cBanco+cAgencia+cConta+cSubConta)       

		IF (cBanco=="237" .AND. cCOnta=="00751731  ") .OR. (cBanco=="237" .AND. cCOnta=="0076001302") 
			If Empty(Alltrim(cCodCed))
				MsgBox("O CÛdigo do Benefici·rio n„o foi informado. ImpossÌvel continuar","CÛdigo Benefici·rio ","STOP")
				Return()
			EndIf
			nossonum  := StrZero(1 + Val(subs(SEE->EE_FAXATU,1,11)),11)   
			If Alltrim(nossonum) > Alltrim(SUBSTR(SEE->EE_FAXFIM,1,11))
				Alert("O nosso numero esta acima da faixa permitida, SERA ABORTADO, favor rever a faixa")
				Exit
			Endif 
		ELSEIF cBanco=="422"
			If Empty(Alltrim(cCodCed))
				MsgBox("O CÛdigo do Benefici·rio n„o foi informado. ImpossÌvel continuar","CÛdigo Benefici·rio","STOP")
				Return()
			EndIf
			nossonum  := StrZero(1 + Val(subs(SEE->EE_FAXATU,1,8)),8)
			If Alltrim(nossonum) > Alltrim(SUBSTR(SEE->EE_FAXFIM,1,8))
				Alert("O nosso numero esta acima da faixa permitida, SERA ABORTADO, favor rever a faixa")
				Exit
			Endif          
		ELSEIF cBanco=="254" .AND. cCodCed="00010"
			If Empty(Alltrim(cCodCed))
				MsgBox("O CÛdigo do Benefici·rio n„o foi informado. ImpossÌvel continuar","CÛdigo Benefici·rio","STOP")
				Return()
			EndIf
			nossonum  := StrZero(1 + Val(subs(SEE->EE_FAXATU,1,11)),11)
			If Alltrim(nossonum) > Alltrim(SUBSTR(SEE->EE_FAXFIM,1,11))
				Alert("O nosso numero esta acima da faixa permitida, SERA ABORTADO, favor rever a faixa")
				Exit
		Endif          
		ELSEIF cBanco=="033"
			If Empty(Alltrim(cCodCed))
				MsgBox("O CÛdigo do Benefici·rio n„o foi informado. ImpossÌvel continuar","CÛdigo Benefici·rio","STOP")
				Return()
			EndIf
			nossonum  := StrZero(1 + Val(subs(SEE->EE_FAXATU,1,7)),7)
			If Alltrim(nossonum) > Alltrim(SUBSTR(SEE->EE_FAXFIM,1,7))
				Alert("O nosso numero esta acima da faixa permitida, SERA ABORTADO, favor rever a faixa")
				Exit
			Endif          
		ELSEIF cBanco=="104"
			If Empty(Alltrim(cCodCed))
				APMsgALERT("O CÛdigo do Benefici·rio n„o foi informado. ImpossÌvel continuar","CÛdigo Benefici·rio")
				Return()
			EndIf
			nossonum  := StrZero(1 + Val(subs(SEE->EE_FAXATU,1,11)),11)
			If Alltrim(nossonum) > Alltrim(SUBSTR(SEE->EE_FAXFIM,1,11))
				APMSGAlert("O nosso numero esta acima da faixa permitida, SERA ABORTADO, favor rever a faixa")
				Return
			Endif
		ELSEIF cBanco=="341" .and. alltrim(cCodCed) = "7365"
			If Empty(Alltrim(cCodCed))
				APMsgALERT("O CÛdigo do Benefici·rio n„o foi informado. ImpossÌvel continuar","CÛdigo Benefici·rio")
				Return()
			EndIf
			nossonum  := StrZero(1 + Val(substr(SEE->EE_FAXATU,1,8)),8)
			If Alltrim(nossonum) > Alltrim(SUBSTR(SEE->EE_FAXFIM,1,8)) 
				APMSGAlert("O nosso numero esta acima da faixa permitida, SERA ABORTADO, favor rever a faixa")
				Return
			Endif 
		ELSEIF cBanco=="341" .and. cCodCed="1248"
			If Empty(Alltrim(cCodCed))
				APMsgALERT("O CÛdigo do Benefici·rio n„o foi informado. ImpossÌvel continuar","CÛdigo Benefici·rio")
				Return()
			EndIf
			nossonum  := StrZero(1 + Val(subs(SEE->EE_FAXATU,1,8)),8)
			If Alltrim(nossonum) > Alltrim(SUBSTR(SEE->EE_FAXFIM,1,8)) 
				APMSGAlert("O nosso numero esta acima da faixa permitida, SERA ABORTADO, favor rever a faixa")
				Return
			Endif
		ELSEIF cBanco=="745" //.and. cCodCed=="0093545028"
			If Empty(Alltrim(cCodCed))
				APMsgALERT("O CÛdigo do Benefici·rio n„o foi informado. ImpossÌvel continuar","CÛdigo Benefici·rio")
				Return()
			EndIf
			nossonum  := StrZero(1 + Val(subs(SEE->EE_FAXATU,1,11)),11)
			If Alltrim(nossonum) > Alltrim(SUBSTR(SEE->EE_FAXFIM,1,11)) 
				APMSGAlert("O nosso numero esta acima da faixa permitida, SERA ABORTADO, favor rever a faixa")
				Return
			Endif 
		ELSEIF cBanco=="001"       // ajustar
				nossonum  := "1126576" + StrZero(1 + Val(left(SEE->EE_FAXATU,10)),10)
			If Alltrim(nossonum) >  "1126576" + Alltrim(SUBSTR(SEE->EE_FAXFIM,1,10))
				APMSGAlert("O nosso numero esta acima da faixa permitida, SERA ABORTADO, favor rever a faixa")
				Return
			Endif
		ENDIF
	Endif            
	
	// GRAVA BORDER‘ NO TÕTULO E TABELA SEA
	// Verifica n˙mero do borderÙ
	//If sPAR09==1
	// RCO (29/05/11)
	//IF EMPTY(SE1->E1_NUMBOR)
	IF EMPTY(SE1->E1_NUMBOR) .AND. SE1->E1_SALDO > 0
		//verificar o numero do bordero que ser· utilizado
		//pesquisa na tabela de titulos transferidos, e se houver algum titulo j· transferido e ainda n√o gerado o arquivo
		//utiliza o mesmo numero do bordero
		//do contr·rio cria outro bordero.
		
		cNumBor	:= ""
		
		// RCO (23/02/2010)
		/*
		DbSelectAreA("SEA")
//		DBOrderNickName("SEA_A")
		DbSetOrdeR(3) //indice personalizado - EA_FILIAL+EA_PORTADO+EA_AGEDEP+EA_NUMCON+EA_CART+EA_DATABOR+EA_PREFIXO
		DbSeek(xFilial("SEA")+cBanco+cAgencia+cConta+"R"+dtos(ddatabase)+SE1->E1_PREFIXO)
		While !Eof() .and. SEA->EA_FILIAL==xFilial("SEA");
			.and. SEA->EA_PORTADO==cBanco;
			.and. SEA->EA_AGEDEP==cAgencia;
			.and. SEA->EA_NUMCON==cConta;
			.and. SEA->EA_CART=="R";
			.and. SEA->EA_DATABOR==dDatabase;
			.and. SEA->EA_PREFIXO==SE1->E1_PREFIXO;
			.and. Empty(cNumBor)
			If SEA->EA_TRANSF<>"S"
				cNumBor	:= SEA->EA_NUMBOR
			EndIf
			DbSelectArea("SEA")
			DbSkip()
		EndDo
		If Empty(cNumBor)
			cNumBor := Soma1(GetMV("MV_NUMBORR"),6)
			cNumBor := Replicate("0",6-Len(Alltrim(cNumBor)))+Alltrim(cNumBor)
    		SETMV("MV_NUMBORR",cNumBor)
		EndIf
		*/
		If (Select("QRY") <> 0)
			dbSelectArea("QRY")
			dbCloseArea("QRY")
		Endif     
		cFilBor := xFilial("SE1")
		BEGINSQL ALIAS "QRY"
			SELECT EA.EA_NUMBOR,COUNT(*) AS TOTNENV FROM %Table:SEA% EA
				INNER JOIN %Table:SE1% E1
				ON E1.D_E_L_E_T_<>'*'
				AND E1.E1_FILIAL=%exp:cFilBor%
				AND E1.E1_PREFIXO=EA.EA_PREFIXO
				AND E1.E1_NUM=EA.EA_NUM
				AND E1.E1_PARCELA=EA.EA_PARCELA
				AND E1.E1_TIPO=EA.EA_TIPO
				AND E1.E1_NUMBCO>' '
			WHERE EA.D_E_L_E_T_<>'*'
			AND EA.EA_FILIAL=%exp:cFilBor%
			AND EA.EA_PORTADO=%exp:cBanco%
			AND EA.EA_AGEDEP=%exp:cAgencia%
			AND EA.EA_NUMCON=%exp:cConta%
			AND EA.EA_CART='R'
			AND EA.EA_TRANSF<>'S'
			AND EA.EA_DATABOR=%exp:dtos(ddatabase)%
			AND EA.EA_NUMBOR>' '
			GROUP BY EA.EA_NUMBOR
			ORDER BY EA.EA_NUMBOR
		ENDSQL
		//	AND EA.EA_PREFIXO=%exp:SE1->E1_PREFIXO%
		dbSelectArea("QRY")
		dbGoTop()
		If !EOF() .AND. QRY->TOTNENV > 0
			cNumBor	:= QRY->EA_NUMBOR
		ELSE
			cNumBor := Soma1(GetMV("MV_NUMBORR"),6)
			cNumBor := Replicate("0",6-Len(Alltrim(cNumBor)))+Alltrim(cNumBor)
    		SETMV("MV_NUMBORR",cNumBor)
    		APMSGALERT("Foi gerado o borderÙ " + cNumBor + ".")
    		//U_WFGERAL(_cEmail,"Gerado novo borderÙ "+cNumBor+" - "+DTOC(DDATABASE),"Acaba de ser gerado novo borderÙ de cobranÁa "+cNumBor+" na filial "+SM0->M0_CODFIL+", para o banco "+cBanco)
    		_cEmailTeste := "emarquetti@cordoariabrasil.com.br"
    		cTitulo := "Gerado novo borderÙ " + cNumBor + " - " + DTOC(DDATABASE)
		    cBody   := "Acaba de ser gerado novo borderÙ de cobranÁa " + cNumBor + " na filial " + SM0->M0_CODFIL + ", para o banco: " + cBanco + " / Agencia: " + cAgencia + " /Conta: " + cConta
// emarquetti    U_EmailPDA(cTitulo, cBody, _cEmail,SM0->M0_CODFIL)
		EndIf

	    If (Select("QRY") <> 0)
			dbSelectArea("QRY")
			dbCloseArea("QRY")
		Endif
		
		//fim
		//		cNumBor	:= subs(dtos(ddatabase),3,2)+subs(dtos(ddatabase),5,2)+subs(dtos(ddatabase),7,2)
		
		// Atualiza tÌtulo no Contas a Receber
		
		RecLock("SE1",.F.)
			Replace SE1->E1_NUMBOR		with cNumBor
			Replace SE1->E1_DATABOR	with ddatabase
		MsUnLock()
		
		// Inclui registro na tabela SEA (Titulos enviados a bancos)
		dbSelectArea("SEA")
		dbSetOrder(1) // EA_FILIAL+EA_NUMBOR+EA_PREFIXO+EA_NUM+EA_PARCELA+EA_TIPO+EA_FORNECE+EA_LOJA
		dbSeek(XFILIAL("SEA")+cNumBor+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO)
		IF !FOUND()
			RecLock("SEA",.T.)
			Replace SEA->EA_FILIAL		with XFILIAL("SEA")
			Replace SEA->EA_PREFIXO	with SE1->E1_PREFIXO
			Replace SEA->EA_NUM		with SE1->E1_NUM
			Replace SEA->EA_PARCELA	with SE1->E1_PARCELA
			Replace SEA->EA_PORTADO	with cBanco
			Replace SEA->EA_AGEDEP		with SEE->EE_AGENCIA
			Replace SEA->EA_NUMBOR		with cNumBor
			Replace SEA->EA_DATABOR	with dDataBase
			Replace SEA->EA_TIPO		with SE1->E1_TIPO
			Replace SEA->EA_CART		with "R"
			Replace SEA->EA_NUMCON		with SEE->EE_CONTA
			Replace SEA->EA_SUBCTA		with SEE->EE_SUBCTA
			Replace SEA->EA_SITUACA	with "1"
			Replace SEA->EA_SITUANT	with "0"
			Replace SEA->EA_FILORIG 	with XFILIAL("SEA") //SUBSTR(SE1->E1_PREFIXO,2,2)
			MsUnLock()
		ENDIF
	Else
		cNumBor	:= SE1->E1_NUMBOR
	EndIf
	
	// atualiza campos nas faturas
	xRECNO    := SE1->(RECNO())
	PREFANT   := SE1->E1_PREFIXO
	NUMANT    := SE1->E1_NUM
	TIPOANT   := SE1->E1_TIPO
	CLIANT    := SE1->E1_CLIENTE
	LOJANT    := SE1->E1_LOJA
	
	MsgInstr01	:= SE1->E1_INSTR1
	MsgInstr02	:= SE1->E1_INSTR2
	MsgInstr03	:= sPAR12
	
	SA1->(dbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,.f.))
	cNome := SA1->A1_NOME
	cCGC  := If(SA1->A1_PESSOA=="F",TRansform(SA1->A1_CGC, "@R 999.999.999-99"),TRansform(SA1->A1_CGC, "@R 99.999.999/9999-99"))
	
	// RCO (26/05/11)
	// VERIFICA ABATIMENTOS DO TÕTULOS (RHO - 03/11/05)

/*	nAbatim	:= 0
	dbSelectArea("SE1")
	aAreaE1 := GetArea()
	cChave := SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA
	dbSelectArea("SE1")
	dbSeek(XFILIAL("SE1")+cChave)
	WHILE !EOF() .AND. (SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA)==cChave
		// Verifica se o tÌtulo È de abatimento
		IF SUBS(SE1->E1_TIPO,3,1)=="-"
			// RCO (26/05/11)
			//nAbatim += SE1->E1_SALDO
			IF sPAR14==1
				nAbatim += SE1->E1_SALDO
			ELSE
				nAbatim += SE1->E1_VALOR
			ENDIF
		ENDIF
		dbSelectArea("SE1")
		dbSkip()
	ENDDO
	RestArea(aAreaE1)
	*/
	nAbatim	:= SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",SE1->E1_MOEDA,dDataBase,SE1->E1_CLIENTE,SE1->E1_LOJA)
	
	// GRAVA«√O DOS JUROS
	// RCO (29/05/11)
	//IF SE1->E1_VALJUR==0.0 .AND. nPAR10>0.0
	IF SE1->E1_VALJUR == 0.0 .AND. nPAR10 > 0.0 .AND. SE1->E1_SALDO > 0
		RecLock("SE1",.F.)
		Replace SE1->E1_VALJUR 	with Round(SE1->E1_VALOR * (nPAR10/30/100),2)
		Replace SE1->E1_PORCJUR 	with ROUND(nPAR10/30,2)
		MsUnlock()
	ENDIF
	
	njuros := 0
	IF SE1->E1_VALJUR == 0.0 .AND. SE1->E1_PORCJUR == 0
		njuros 	:= (nPAR10/30)/100
		// RCO (26/05/11)
		//njuros 	:= Round(SE1->E1_SALDO * njuros,2)
		IF sPAR14=='S'
			njuros 	:= Round(SE1->E1_SALDO * njuros,2)
		ELSE
			njuros 	:= Round(SE1->E1_VALOR * njuros,2)
		ENDIF
	ELSEIF SE1->E1_VALJUR > 0
		njuros	:= SE1->E1_VALJUR
	ELSE 
	    nJuros	:= Round(SE1->E1_VALOR * (SE1->E1_PORCJUR/100),2)
	ENDIF
	njrs01 := njuros
	njuros := ALLTRIM(transf(njuros,"@E 999,999.99"))
	
	nmulta	:= 0
	IF nPAR11 > 0
		nmulta	:= (nPAR11/100) 
		IF cBanco == "033"
			nmulta	:= NoRound(SE1->E1_VALOR * nmulta,2)
		ELSE
			nmulta	:= Round(SE1->E1_VALOR * nmulta,2)
		ENDIF
	ENDIF
    nmul01 := nmulta
	nmulta := ALLTRIM(transf(nmulta,"@E 999,999.99"))
	
	lTitAnt := .F.
	     
	// se titulo j· est· vencido
	If SE1->E1_VENCTO < Date() .AND. SE1->E1_SALDO > 0
		                          
		dDatEmi := SE1->E1_EMISSAO
		dDatVen := SE1->E1_VENCTO  
		nVlrSdo := SE1->E1_SALDO
		nTaxJur := mv_par10
		nTaxMul := mv_par11		
		dNewVen := Date()+7 
		cAtuVlr := "N"           
		cDadTit := SE1->E1_PREFIXO + "  " + SE1->E1_NUM + "  " + SE1->E1_PARCELA + "  " + SE1->E1_TIPO
		cDadCli := SE1->E1_CLIENTE + "  " + SE1->E1_LOJA + "  " + SE1->E1_NOMCLI
		If SE1->E1_SITUACA == "0"
		   cSitTit := "0  CARTEIRA"
		Elseif SE1->E1_SITUACA == "1"
		   cSitTit := "1  COBR. SIMPLES"
		Elseif SE1->E1_SITUACA == "2"
		   cSitTit := "2  COBR. DESCONT."
		Elseif SE1->E1_SITUACA == "4"
		   cSitTit := "4  COBR. VINCULAD"
		Else
		   cSitTit := Left(SE1->E1_SITUACA,1,1)
		Endif
	
		@ 150,1 TO 430,490 DIALOG oDlg1 TITLE "ATEN«√O!!! TÕTULO VENCIDO."
   
		@ 006,005  To 115,240 Title ""

		@ 013,013 Say "Reemiss„o de boleto com dados atualizados (DT VENCTO E VALOR)." 
		@ 028,013 Say "Titulo: "
		@ 042,013 Say "Cliente: "		
		@ 056,013 Say "Dt. Emiss„o: "
		@ 056,123 Say "Dt. Vencto Orig: "

		@ 070,013 Say "Vlr TÌtulo:"
		@ 070,123 Say "SituaÁ„o:"
		@ 084,013 Say "%Taxa Juros:"
		@ 084,123 Say "%Taxa Multa:"

		@ 098,013 Say "Atualiza Valor? "
		@ 098,123 Say "Nova Dt. Vencto: "
		
		@ 027,055 Get cDadTit Size 080,060 When .F.
		@ 041,055 Get cDadCli Size 120,060 When .F.
		@ 055,055 Get dDatEmi Size 045,060 When .F.
		@ 055,170 Get dDatVen Size 045,060 When .F.
		
		@ 069,055 Get nVlrSdo Size 055,060 When .F. Picture "@E 9,999,999.99"
		@ 069,170 Get cSitTit Size 060,060 When .F. 
		@ 083,055 Get nTaxJur Size 030,060 When .F. Picture "@E 99.99"
		@ 083,170 Get nTaxMul Size 030,060 Picture "@E 99.99"		
		
		@ 097,055 Get cAtuVlr Size 020,060 Picture "@!" Valid cAtuVlr $ "SN"
		@ 097,170 Get dNewVen Size 045,060 Valid dNewVen >= dDatVen
		
		@ 121,105 BUTTON "_OK"          SIZE 035,015  ACTION Close(oDlg1)

		ACTIVATE DIALOG oDlg1 CENTERED     
		/*  VALOR DO BOLETO DE COBRAN«A (VALOR DA CONTA EM ATRASO)=R$100,00
			Vencimento: 20/09/2012
			Data de Pagamento: 25/09/2012

			MULTA de 2% = R$100,00*2%= R$2,00

			JUROS DE MORA OU MORAT”RIO = 1% AO M S. Se È ao mÍs, considere que o mÍs comercial possua 30 dias, logo o valor ser· = 1/30 multiplicado pela quantidade de dias em atraso. Nesse caso 5 dias. Ent„o o valor ser· igual a:
			R$100,00*1%= R$1,00
			R$1,00/30= R$0,03.
			R$0,03*5(quantidade de dias em atraso)=R$0,15.		
		*/		
	         
		If cAtuVlr == "S"
		   lTitAnt := .T.   
		   nValorMulta := (SE1->E1_SALDO*nTaxJur/100) 
		   nValorMulta := (nValorMulta/30)*(dNewVen-dDatVen)
		   //nVlrCob := SE1->E1_SALDO + nmul01 + (nTaxJur*(dNewVen-dDatVen))  
		   nVlrCob := SE1->E1_SALDO + nmul01 + nValorMulta
		   
		   
		   //MsgBox("SE1->E1_SALDO "+Str(SE1->E1_SALDO))
		   //MsgBox("nMulta "+Str(nmul01))
		   //MsgBox("nJuros "+Str(njrs01))
		   //MsgBox("Qtde Dias "+Str(dNewVen-dDatVen))
		   //MsgBox("(njrs01*(dNewVen-dDatVen)) "+Str((njrs01*(dNewVen-dDatVen)) ))
 		   //MsgBox("nVlrCob "+Str(nVlrCob))
		   
		Endif   
	
	Endif
	
	// CALCULA PAR¬METROS PARA CADA BANCO (Linha Digit·vel, CÛdigo de Barras, Nosso N˙mero)
	// - RHO - 03/11/05 - mudanÁa na rotina para considerar DecrÈscimo e Abatimentos
	CALCVALBOL(cBanco,aBancos,sPar01,sPar02,sPar03,sPar14)
	
	// GRAVA«√O DO NOSSO N⁄MERO
	// RCO (29/05/11)
	//IF EMPTY(SE1->E1_NUMBCO)
	IF EMPTY(SE1->E1_NUMBCO) .AND. SE1->E1_SALDO > 0   
		
		If cBanco=="341"
		    RecLock("SE1",.F.)
			Replace SE1->E1_NUMBCO with Substr(NossoNum,1,9)
			MsUnlock() 
        Else
			RecLock("SE1",.F.)
			Replace SE1->E1_NUMBCO with NossoNum
			MsUnlock() 
        Endif 
        
		IF cBanco=="237" .OR. cBanco=="104" .OR. cBanco=="422" .OR. cBanco='033' .OR. cBanco='254'		
			RecLock("SEE",.F.)
			Replace SEE->EE_FAXATU with NossoNum
			MsUnLock()
		ElseIf cBanco=="001"	
			RecLock("SEE",.F.)
			Replace SEE->EE_FAXATU with Substr(NossoNum,8,10)
			MsUnLock()
		ElseIf cBanco=="341"
			RecLock("SEE",.F.)
			Replace SEE->EE_FAXATU with Substr(NossoNum,1,9)
			MsUnLock()  
		ELSEIF cBanco=="745"
			RecLock("SEE",.F.)
			Replace SEE->EE_FAXATU with Substr(NossoNum,1,11)
			MsUnLock()
		Endif
		
	ENDIF
	
	dbSelectArea("SEE")
	dbSetOrder(1)
	dbSeek(XFILIAL("SEE") + cBanco + cAgencia + cConta + cSubConta)
	                    
	If lTitAnt
	   cData := DTOC(dNewVen)
	Else   
	   cData := DTOC(SE1->E1_VENCTO)
	Endif   
	cData := IIF(LEN(cData) == 8,SUBS(cData,1,6)+"20"+SUBS(cData,7,2),cData)
	cData2 := DTOC(SE1->E1_EMISSAO)
	cData2 := IIF(LEN(cData2) == 8,SUBS(cData2,1,6)+"20"+SUBS(cData2,7,2),cData2)
	cData3 := DTOC(DDATABASE)
	cData3 := IIF(LEN(cData3) == 8,SUBS(cData3,1,6)+"20"+SUBS(cData3,7,2),cData3)


	//******************************************
	//  PESQUISA NOTAS FISCAIS 
	//******************************************
	dbSelectArea("SE1")
	sNotFat := '' 
	sDocCit := ''
	nRecn := Recno()
	nInd  := dbSetOrder()
	sReg  := SE1->E1_FILIAL + SE1->E1_CLIENTE + SE1->E1_LOJA + SE1->E1_NUM  
	dbSetOrder(10)
//	dbOrderNickName("SE1A")
	DbSeek(sReg,.T.)
    While !Eof() .And. Alltrim(sReg)  == Alltrim(SE1->E1_FILIAL + SE1->E1_CLIENTE + SE1->E1_LOJA + SE1->E1_FATPREF + SE1->E1_FATURA)
                                                                                            
	      iF !SE1->E1_NUM $ sNotFat
		      sNotFat += IIF(Empty(sNotFat),'', ' / ') + SE1->E1_NUM
		      sDocCit += Substr(SE1->E1_NUM,5,5)
	      EndIf
	      DbSkip()
	EndDo         
	dbSelectArea("SE1")
	dbSetOrder(nInd)
	DbGoto(	nRecn )
	nRecn := Recno()  
	
	cEndBeneficiario := "AV. ADOLFO KONDER, 1444 SAO VICENTE, ITAJAI, SC - CEP: 88308-002"



	//******************************************
	//  INICIALIZA IMPRESSAO DO BOLETO   
	//******************************************
	oPrn:StartPage()
	nAjust1	:= -2100	// Recibo Entrega
	nAjust2	:= -1595+70	// Recibo Sacado
	nAjust3 := -600+70		// Ficha de Compensacao
	
	//******************************************
	//  MONTA RECIBO DE ENTREGA    -2110
	//******************************************
	
	// Monta linhas horizontais
	oPrn:Line(2220+nAjust1, 0050, 2220+nAjust1, 2380)
	
	oPrn:Line(2290+nAjust1, 0050, 2290+nAjust1, 2380)
	oPrn:Line(2360+nAjust1, 0050, 2360+nAjust1, 2380)
	oPrn:Line(2430+nAjust1, 0050, 2430+nAjust1, 2380)
	oPrn:Line(2500+nAjust1, 0050, 2500+nAjust1, 2380)
	oPrn:Line(2570+nAjust1, 0050, 2570+nAjust1, 2380)
	
	
	oPrn:Line(2500+nAjust1+80+70, 0050, 2500+nAjust1+80+70, 2380) //
		
	// Monta linha verticais
	oPrn:Line(2135+nAjust1, 0620, 2215+nAjust1, 0620)
	oPrn:Line(2135+nAjust1, 0830, 2215+nAjust1, 0830)
	
	oPrn:Line(2150+nAjust1+70, 1720, 2500+nAjust1+70, 1720)
	oPrn:Line(2220+nAjust1+70, 1720, 2500+nAjust1+70, 1720)
	
	oPrn:Line(2360+nAjust1+70, 0500, 2500+nAjust1+70, 0500)
	oPrn:Line(2360+nAjust1+70, 0900, 2500+nAjust1+70, 0900)
	oPrn:Line(2360+nAjust1+70, 1100, 2430+nAjust1+70, 1100)
	oPrn:Line(2360+nAjust1+70, 1400, 2500+nAjust1+70, 1400)
	
	IF FILE(aBancos[nPOS,3])     // LOGOTIPO BANCO
		IF cBanco=="237"  
			oPrn:SayBitmap( 2150+nAjust1-25, 0050,aBancos[nPOS,3],210,80 )
			//oPrn:Say( 2150+nAjust1      , 0210, aBancos[nPOS,2]		,oFont24,100)
			//oPrn:SayBitmap( 2150+nAjust1-20, 0050,aBancos[nPOS,3],320,75 )
			//oPrn:Say( 2150+nAjust1      , 0210, aBancos[nPOS,2]		,oFont24,100)
		ELSEIF cBanco=="104" 
			oPrn:SayBitmap( 2150+nAjust1-25, 0100,aBancos[nPOS,3],200,80 )
		ELSEIF cBanco=="254" 
			oPrn:SayBitmap( 2150+nAjust1-25, 0100,aBancos[nPOS,3],200,80 )
		ELSEIF cBanco=="341"
			oPrn:Say( 2180+nAjust1-25, 0100,"Banco Ita˙ SA", oFont20,100 )
		ELSEIF cBanco=="001"
			oPrn:SayBitmap( 2150+nAjust1-22, 0050,aBancos[nPOS,3],400,85 )
		ELSEIF cBanco=="745" 
			oPrn:SayBitmap( 2150+nAjust1-25, 0100,aBancos[nPOS,3],200,80 )
		ELSEIF cBanco=="422" 
			oPrn:SayBitmap( 2150+nAjust1-25, 0100,aBancos[nPOS,3],200,80 )
		ELSEIF cBanco=="033" 
			oPrn:SayBitmap( 2150+nAjust1-25, 0100,aBancos[nPOS,3],200,80 )
		EndIf
	ELSE
		oPrn:Say( 2150+nAjust1, 0100, aBancos[nPOS,2]		,oFont24,100)
	ENDIF
	
	oPrn:Say( 2150+nAjust1, 0640, aBancos[nPOS,4]			,oFont20,100)
	oPrn:Say( 2155+nAjust1, 1440, "COMPROVANTE  DE  ENTREGA"  ,oFont4,100)
	
	oPrn:Say( 2225+nAjust1, 0070, "Benefici·rio "               ,oFont13,100  )
	oPrn:Say( 2225+nAjust1, 1730, "Vencimento "        ,oFont13,100  )
	oPrn:Say( 2250+nAjust1, 2040, cData     				,oFont15,100  )
	
	IF cBanco=="104" .OR. cBanco == "341"
		oPrn:Say( 2245+nAjust1, 0090, ALLTRIM(SUBS(SM0->M0_NOMECOM,1,35))+" - CNPJ: "+ ALLTRIM(TRANSFORM(SM0->M0_CGC, "@R 99.999.999/9999-99"))			,oFont12,100  )
	ELSEIF cBanco=="745"
		oPrn:Say( 2245+nAjust1, 0090, RTRIM(SUBS(SM0->M0_NOMECOM,1,35))+"  ("+SE1->E1_PREFIXO+"-"+AllTrim(SE1->E1_NUM)+"-"+SE1->E1_PARCELA+")",oFont12,100  )
	ELSEIF cBanco=="254"
		oPrn:Say( 2245+nAjust1, 0090, "PARAN¡ BANCO S/A",oFont12,100  )
	ELSEIF cBanco == "001"
		oPrn:Say( 2245+nAjust1, 0090, ALLTRIM(SUBS(SM0->M0_NOMECOM,1,35))+" - CNPJ: "+ ALLTRIM(TRANSFORM(SM0->M0_CGC, "@R 99.999.999/9999-99"))			,oFont12,100  )
	ELSE
		oPrn:Say( 2245+nAjust1, 0090, SUBS(SM0->M0_NOMECOM,1,35)			,oFont12,100  )
	ENDIF
	
	oPrn:Say( 2295+nAjust1, 0070, "EndereÁo "               ,oFont13,100  )
	oPrn:Say( 2320+nAjust1, 0090, cEndBeneficiario, oFont12,100  )   
	
	oPrn:Say( 2295+nAjust1, 1730, "AgÍncia/CÛdigo Benefici·rio "        ,oFont13,100  ) 
	
	IF cBanco=="237"
	   oPrn:Say( 2320+nAjust1, 1880, transform(strzero(val(StrTran(cAgencia,"-","")),5),"@R 9999-9")+"/"+transform(Left(cConta,8),"@R 9999999-9"),oFont12,100  )
	ELSEIF cBanco=="422"  
	   oPrn:Say( 2320+nAjust1, 1880, cCodCed+" /"+TRANSFORM(cContaSEE,"@R 99999999-9"),oFont12,100)
	ELSEIF cBanco=="254"  
	   oPrn:Say( 2320+nAjust1, 1880, "049 / 0222400-3",oFont12,100)
	ELSEIF cBanco=="033"  //648701-7
	   oPrn:Say( 2320+nAjust1, 1880, transform(SUBSTR(cCodCed,1,4),"@R 9999")+" / 648701-7",oFont12,100  )
	ELSEIF cBanco=="104"                                        //87000000941-0                   //0021633
	   oPrn:Say( 2320+nAjust1, 1880, transform(cCodCed,"@R 9999-9")+" / "+transform(cContaSEE,"@R 999999-9"),oFont12,100  )
	ELSEIF cBanco=="001" .and. alltrim(cConta) == "309532"
	   oPrn:Say( 2320+nAjust1, 1880, transform(strzero(val(StrTran(cAgencia,"-","")),5),"@R 9999-9") + "/" + transform(Substr(alltrim(cContaSEE),1,8),"@R 9999999-9"),oFont12,100  )
	ELSEIF cBanco=="001"
	   oPrn:Say( 2320+nAjust1, 1880, transform(strzero(val(StrTran(cAgencia,"-","")),5),"@R 9999-9")+"/"+transform(Substr(cConta,3,8),"@R 9999999-9"),oFont12,100  )
	ELSEIF cBanco=="341" .and. alltrim(cConta) <> "122808"
	   oPrn:Say( 2320+nAjust1, 1930, transform(strzero(val(StrTran(cAgencia,"-","")),4),"@R 9999")+"/"+transform(Substr(cConta,3,6),"@R 99999-9"),oFont12,100)
	ELSEIF cBanco=="341" .and. alltrim(cConta) == "122808"
	   oPrn:Say( 2320+nAjust1, 1930, transform(strzero(val(StrTran(cAgencia,"-","")),4),"@R 9999")+"/"+transform(Substr(cConta,1,6),"@R 99999-9"),oFont12,100)
	ELSEIF cBanco=="745"
	   oPrn:Say( 2320+nAjust1, 1880, cCodCed+"/"+cContaSEE,oFont12,100  )
	/*	ELSEIf cBanco=="399"
		oPrn:Say( 2250+nAjust1, 1880, substr(StrTran(sPAR02,"-",""),1,4)+"-"+substr(StrTran(sPAR02,"-",""),1,4)+Right(Alltrim(StrTran(sPAR03,"-","")),7),oFont12,100  )
	*/    
	ELSEIF cBanco=="104"
	   oPrn:Say( 2320+nAjust1, 1880, SUBSTR(aBancos[nPOS,6],1,4)+"."+SUBSTR(aBancos[nPOS,6],5,3)+"."+SUBSTR(aBancos[nPOS,6],8,8)+"-"+SUBSTR(aBancos[nPOS,6],16,1),oFont12,100  )
	EndIf
	
                                                          
   IF cBanco == "341"                                                                   
   	oPrn:Say( 2390+nAjust1, 2075, ALLTRIM(SE1->E1_CLIENTE) ,oFont12,100  )
   ELSE
   	oPrn:Say( 2390+nAjust1, 1880, ALLTRIM(SE1->E1_CLIENTE) ,oFont12,100  )
   ENDIF  
   
                                                                  
    
    oPrn:Say( 2365+nAjust1, 0070, "Pagador: "       ,oFont13,100  )  
    oPrn:Say( 2365+nAjust1, 1730, "Codigo Pagador "        ,oFont13,100  )
    
    oPrn:Say( 2390+nAjust1, 0090, ALLTRIM(cNome)           ,oFont12,100  )   
    
	
	oPrn:Say( 2435+nAjust1, 0070, "Data Documento"       ,oFont13,100  )
	oPrn:Say( 2435+nAjust1, 0510, "N∫. Documento "         ,oFont13,100  )
	oPrn:Say( 2435+nAjust1, 0910, "Especie Doc. "          ,oFont13,100  )
	oPrn:Say( 2435+nAjust1, 1110, "Aceite "                ,oFont13,100  )
	oPrn:Say( 2435+nAjust1, 1410, "(=) Valor do Documento" ,oFont13,100  )
	
	IF cBanco != "237"
		oPrn:Say( 2435+nAjust1, 1730, "Nosso Numero "          ,oFont13,100  )
	ELSE
		oPrn:Say( 2435+nAjust1, 1730, "Carteira/Nosso Numero "          ,oFont13,100  )
	ENDIF
	   
	oPrn:Say( 2460+nAjust1, 0090, cData2     				, oFont12,100  )
	oPrn:Say( 2460+nAjust1, 0520, SE1->E1_PREFIXO+"/"+SE1->E1_NUM+"-"+SE1->E1_PARCELA , oFont12,100  )
	oPrn:Say( 2460+nAjust1, 0970, IIF(cBanco=="399","PD",IIF(cBanco$"745","DMI","DM")), oFont12,100  )
	oPrn:Say( 2460+nAjust1, 1230, IIF(cBanco$"745","N","N„o")      , oFont12,100  ) //ACEITE

    IF lTitAnt
		oPrn:Say( 2460+nAjust1, 1440, TRANSF(nVlrCob,"@E 999,999.99"), oFont12,100  )
    ELSE
		IF sPAR14=='S'      // imprime saldo do tÌtulo
			oPrn:Say( 2460+nAjust1, 1440, TRANSF(SE1->E1_SALDO-SE1->E1_DECRESC-nAbatim+SE1->E1_ACRESC,"@E 999,999.99"), oFont12,100  )
		ELSE
			oPrn:Say( 2460+nAjust1, 1440, TRANSF(SE1->E1_VALOR-SE1->E1_DECRESC-nAbatim+SE1->E1_ACRESC,"@E 999,999.99"), oFont12,100  )
		ENDIF
	ENDIF
	             
	oPrn:Say( 2460+nAjust1, 1880, aBancos[nPOS,8]         	, oFont12,100  )
	
	oPrn:Say( 2500+nAjust1, 0070, "Recebi(emos) o Boleto"   ,oFont18,100  )
	oPrn:Say( 2530+nAjust1, 0070, "de caracterÌstica acima" ,oFont18,100  )
	oPrn:Say( 2500+nAjust1, 0510, "Data "			   		,oFont13,100  )
	oPrn:Say( 2500+nAjust1, 0910, "Assinatura "           	,oFont13,100  )
	oPrn:Say( 2500+nAjust1, 1410, "Data "                 	,oFont13,100  )
	oPrn:Say( 2500+nAjust1, 1730, "Entregador "    		   	,oFont13,100  )
	
	//******************************************
	//  MONTA RECIBO DO SACADO +nAjust2
	//******************************************
	
	// Monta linhas horizontais
	oPrn:Line(2220+nAjust2, 0050, 2220+nAjust2, 2380)
	
	oPrn:Line(2290+nAjust2, 0050, 2290+nAjust2, 2380)
	oPrn:Line(2360+nAjust2, 0050, 2360+nAjust2, 2380)
	oPrn:Line(2430+nAjust2, 0050, 2430+nAjust2, 2380)
	oPrn:Line(2500+nAjust2, 0050, 2500+nAjust2, 2380)
	oPrn:Line(2570+nAjust2, 0050, 2570+nAjust2, 2380)
	
	oPrn:Line(2915+nAjust2, 0050, 2915+nAjust2, 2380)
			
	oPrn:Line(3120+nAjust2, 0050, 3120+nAjust2, 2380)
		
	oPrn:Line(2570+nAjust2, 1720, 2570+nAjust2, 2380)
	oPrn:Line(2640+nAjust2, 1720, 2640+nAjust2, 2380)
	oPrn:Line(2710+nAjust2, 1720, 2710+nAjust2, 2380)
	oPrn:Line(2780+nAjust2, 1720, 2780+nAjust2, 2380) 
	
	// Monta linha verticais
	oPrn:Line(2135+nAjust2, 0620, 2215+nAjust2, 0620)
	oPrn:Line(2135+nAjust2, 0830, 2215+nAjust2, 0830)
	
	oPrn:Line(2150+nAjust2+70, 1720, 2845+nAjust2+70, 1720)
	
	IF cBanco="033"
		oPrn:Line(2360+nAjust2+70, 0500, 2430+nAjust2+70, 0500)
	ELSE
		oPrn:Line(2360+nAjust2+70, 0500, 2500+nAjust2+70, 0500)
	ENDIF
	oPrn:Line(2360+nAjust2+70, 0900, 2500+nAjust2+70, 0900)
	oPrn:Line(2360+nAjust2+70, 1100, 2430+nAjust2+70, 1100)
	oPrn:Line(2360+nAjust2+70, 1400, 2500+nAjust2+70, 1400)
	oPrn:Line(2430+nAjust2+70, 0700, 2500+nAjust2+70, 0700)
	
	IF FILE(aBancos[nPOS,3])
		IF cBanco=="237"  
			oPrn:SayBitmap( 2150+nAjust2-25, 0050,aBancos[nPOS,3],210,80)
			oPrn:Say( 2150+nAjust2      , 0330, aBancos[nPOS,2]		,oFont24,100)
		ELSEIF cBanco=="422"  
			oPrn:SayBitmap( 2150+nAjust2-25, 0100,aBancos[nPOS,3],200,80 )
		ELSEIF cBanco=="033"  
			oPrn:SayBitmap( 2150+nAjust2-25, 0100,aBancos[nPOS,3],200,80 )
		ELSEIF cBanco=="104"  .OR. cBanco=="254"
			oPrn:SayBitmap( 2150+nAjust2-25, 0100,aBancos[nPOS,3],200,80 )
		ELSEIF cBanco=="341"  
			oPrn:Say( 2180+nAjust2-25, 0100,"Banco Ita˙ SA", oFont20,100 )
		ELSEIF cBanco=="001"  
			oPrn:SayBitmap( 2150+nAjust2-20, 0050,aBancos[nPOS,3],400,90 )
		ELSEIF cBanco=="745"  
			oPrn:SayBitmap( 2150+nAjust2-25, 0100,aBancos[nPOS,3],200,80 )
		EndIf
	ELSE
		oPrn:Say( 2150+nAjust2, 0100, aBancos[nPOS,2]		,oFont24,100)
	ENDIF
	
	oPrn:Say( 2150+nAjust2, 0640, aBancos[nPOS,4]			,oFont20,100)
	oPrn:Say( 2155+nAjust2, 0870, aBancos[nPOS,7]          ,oFont4,100)
	
	oPrn:Say( 2225+nAjust2, 0070, "Local de Pagamento "    ,oFont13,100  )
	oPrn:Say( 2225+nAjust2, 1730, "Vencimento "            ,oFont13,100  )
	
	IF cBanco=="237"
		oPrn:Say( 2245+nAjust2, 0090, "PAG¡VEL PREFERENCIALMENTE NAS AG NCIAS DO BRADESCO",oFont22,100  )
	ELSEIF cBanco=="341"
		oPrn:Say( 2245+nAjust2, 0090, "AtÈ o vencimento, preferencialmente no Ita˙. ApÛs o vencimento, somente no Ita˙",oFont15,100  )
	ELSEIF cBanco=="104"
		oPrn:Say( 2245+nAjust2, 0090, "Pagto em qualquer agÍncia banc·ria ou lotÈricas atÈ o vencimento. ApÛs, somente na CAIXA.",oFont15,100  )
	ELSE
		oPrn:Say( 2245+nAjust2, 0090, "PAG¡VEL EM QUALQUER BANCO AT… O VENCIMENTO",oFont22,100  )
	ENDIF
	
	IF cBanco == "341"
		oPrn:Say( 2250+nAjust2, 2040, cData     				,oFont15,100  )
	ELSE
		oPrn:Say( 2250+nAjust2, 1900, cData     				,oFont15,100  )
	ENDIF  
	
	oPrn:Say( 2295+nAjust2, 0070, "Benefici·rio  "               ,oFont13,100  )
	oPrn:Say( 2295+nAjust2, 1730, "AgÍncia/Codigo Benefici·rio "        ,oFont13,100  )
	
	oPrn:Say( 2365+nAjust2, 0070, "EndereÁo "               ,oFont13,100  )
	oPrn:Say( 2390+nAjust2, 0090, cEndBeneficiario, oFont12,100  )   	
	
	// RCO (02/03/2010
	IF cBanco=="104" .OR. cBanco == "341"
		oPrn:Say( 2320+nAjust2, 0090, ALLTRIM(SUBS(SM0->M0_NOMECOM,1,35))+" - CNPJ: "+ ALLTRIM(TRANSFORM(SM0->M0_CGC, "@R 99.999.999/9999-99"))			,oFont12,100  )
	ELSEIf cBanco == "254"                                                                                                                             
		oPrn:Say( 2320+nAjust2, 0090, "PARAN¡ BANCO S/A",oFont12,100  )
	ELSEIF cBanco == "001"
		oPrn:Say( 2320+nAjust2, 0090, ALLTRIM(SUBS(SM0->M0_NOMECOM,1,35))+" - CNPJ: "+ ALLTRIM(TRANSFORM(SM0->M0_CGC, "@R 99.999.999/9999-99"))			,oFont12,100  )
	ELSE
		oPrn:Say( 2320+nAjust2, 0090, SUBS(SM0->M0_NOMECOM,1,35)	,oFont12,100  )
    ENDIF
    
	IF cBanco=="237"
	   oPrn:Say( 2320+nAjust2, 1880, transform(strzero(val(StrTran(cAgeImp,"-","")),5),"@R 9999-9")+"/"+transform(Left(sPAR03,8),"@R 9999999-9"),oFont12,100  )
	ELSEIF cBanco=="422"  
	   oPrn:Say( 2320+nAjust2, 1880, cCodCed+"/"+TRANSFORM(cContaSEE,"@R 99999999-9"),oFont12,100)   
   	ELSEIF cBanco=="254"  
	   oPrn:Say( 2320+nAjust2, 1880, "049 / 0222400-3",oFont12,100)
	ELSEIF cBanco=="033"       //6487017
	   oPrn:Say( 2320+nAjust2, 1880, transform(SUBSTR(cCodCed,1,4),"@R 9999")+" / 648701-7",oFont12,100  )	   
	ELSEIF cBanco=="104"
	   oPrn:Say( 2320+nAjust2, 1880, transform(cCodCed,"@R 9999-9")+" / "+transform(cContaSEE,"@R 999999-9"),oFont12,100)
	ELSEIF cBanco=="341" .and. alltrim(cConta) <> "122808"
	   oPrn:Say( 2320+nAjust2, 1930, transform(strzero(val(StrTran(cAgeImp,"-","")),4),"@R 9999")+"/"+transform(Substr(sPAR03,3,6),"@R 99999-9"),oFont12,100  )
	ELSEIF cBanco=="341" .and. alltrim(cConta) == "122808"
	   oPrn:Say( 2320+nAjust2, 1930, transform(strzero(val(StrTran(cAgencia,"-","")),4),"@R 9999")+"/"+transform(Substr(cConta,1,6),"@R 99999-9"),oFont12,100)
	ELSEIF cBanco=="001" .and. alltrim(cConta) == "309532"
	   oPrn:Say( 2320+nAjust2, 1880, transform(strzero(val(StrTran(cAgencia,"-","")),5),"@R 9999-9") + "/" + transform(Substr(alltrim(cContaSEE),1,8),"@R 9999999-9"),oFont12,100  )
   	ELSEIF cBanco=="001"
	   oPrn:Say( 2320+nAjust2, 1880, transform(strzero(val(StrTran(cAgeImp,"-","")),5),"@R 9999-9")+"/"+transform(Substr(sPAR03,3,8),"@R 9999999-9"),oFont12,100  )
	ELSEIF cBanco=="745"
	   oPrn:Say( 2320+nAjust2, 1880, cCodCed+"/"+cContaSEE,oFont12,100  )
	EndIf
		
	oPrn:Say( 2435+nAjust2, 0070, "Data Documento "        ,oFont13,100  )
	oPrn:Say( 2435+nAjust2, 0510, "N∫. Documento "         ,oFont13,100  )
	oPrn:Say( 2435+nAjust2, 0910, "Especie Doc. "          ,oFont13,100  )
	oPrn:Say( 2435+nAjust2, 1110, "Aceite "                ,oFont13,100  )
	oPrn:Say( 2435+nAjust2, 1410, "Data do Processamento " ,oFont13,100  )
	IF cBanco!="237"
		oPrn:Say( 2365+nAjust2, 1730, "Nosso Numero "          ,oFont13,100  )    
	else
		oPrn:Say( 2365+nAjust2, 1730, "Carteira/Nosso Numero "          ,oFont13,100  )
	endif
	oPrn:Say( 2460+nAjust2, 0090, cData2       				, oFont12,100  )
	oPrn:Say( 2460+nAjust2, 0520, SE1->E1_PREFIXO+"/"+SE1->E1_NUM+"-"+SE1->E1_PARCELA , oFont12,100  )
	//oPrn:Say( 2390+nAjust2, 0530, IIF(cBanco$"745",sDocCit,SE1->E1_PREFIXO+"/"+AllTrim(SE1->E1_NUM)+"-"+SE1->E1_PARCELA) , oFont12,100  )
	oPrn:Say( 2460+nAjust2, 0970, IIF(cBanco=="399","PD",IIF(cBanco$"745","DMI","DM")) , oFont12,100  )
	oPrn:Say( 2460+nAjust2, 1230, IIF(cBanco$"745","N","N„o")  , oFont12,100  )
	oPrn:Say( 2460+nAjust2, 1440, cData3          			, oFont12,100  )
	oPrn:Say( 2390+nAjust2, 1880, aBancos[nPOS,8]         	, oFont12,100  )
	
	IF cBanco=="033"
		oPrn:Say( 2505+nAjust2, 0070, "Carteira "          ,oFont13,100  )
	ELSE
		oPrn:Say( 2505+nAjust2, 0070, "Uso do Banco "          ,oFont13,100  )
	ENDIF

	IF cBanco<>"033"
		oPrn:Say( 2505+nAjust2, 0510, "Carteira "			   ,oFont13,100  )
	ENDIF
	oPrn:Say( 2505+nAjust2, 0710, "Especie "               ,oFont13,100  )
	oPrn:Say( 2505+nAjust2, 0910, "Quantidade "            ,oFont13,100  )
	oPrn:Say( 2505+nAjust2, 1410, "Valor "                 ,oFont13,100  )
	oPrn:Say( 2435+nAjust2, 1730, "(=) Valor do Documento "    ,oFont13,100  )
	                                           
	If cBanco == "001"	
		oPrn:Say( 2530+nAjust2, 0540, "17"            			, oFont12,100  )
	ELSEIF cBanco == "104"
		oPrn:Say( 2530+nAjust2, 0540, "CR"		   			    , oFont12,100  )
	ELSEIF cBanco == "033"
		oPrn:Say( 2530+nAjust2, 0090, "COBRANCA SIMPLES - ECR"		   			    , oFont12,100  )
	Else	
		oPrn:Say( 2530+nAjust2, 0540, aBancos[nPOS,5]			, oFont12,100  )
	Endif	
		
	oPrn:Say(2530+nAjust2, 0745-30, if(cBanco=="399","9 - REAL","R$")           , oFont12,100  )


// Eduardo Marquetti -> 
/*	IF lTitAnt
		oPrn:Say(2530+nAjust2, 1440, TRANSF(nVlrCob,"@E 999,999.99"), oFont12,100  )
    ELSE
		IF sPAR14=='S'      // imprime saldo do tÌtulo
			oPrn:Say(2530+nAjust2, 1440, TRANSF(SE1->E1_SALDO-SE1->E1_DECRESC-nAbatim+SE1->E1_ACRESC,"@E 999,999.99"), oFont12,100  )
		ELSE
			oPrn:Say(2530+nAjust2, 1440, TRANSF(SE1->E1_VALOR-SE1->E1_DECRESC-nAbatim+SE1->E1_ACRESC,"@E 999,999.99"), oFont12,100  )
		ENDIF
	ENDIF		

*/

    IF lTitAnt
		oPrn:Say( 2460+nAjust2, 1975, TRANSF(nVlrCob,"@E 999,999.99"), oFont12,100  )
    ELSE
		IF sPAR14=='S'
			oPrn:Say( 2460+nAjust2, 1975, TRANSF(SE1->E1_SALDO,"@E 999,999.99") , oFont12,100  )
		ELSE
			oPrn:Say( 2460+nAjust2, 1975, TRANSF(SE1->E1_VALOR,"@E 999,999.99") , oFont12,100  )
		ENDIF
	ENDIF	


	IF cBanco=="422"
		oPrn:Say( 2575+nAjust2, 0070, "InstruÁıes: As informaÁ„oes contidas neste boleto, s„o de exclusiva responsabilidade do benefici·rio .",oFont13,100  ) 
	    oPrn:Say( 2595+nAjust2, 0070, "Este boleto representa duplicata cedida fiduciariamente ao Banco Safra S/A, ficando vedado o pagamento de qualquer outra forma que n„o atravÈs do presente boleto.", oFont13, 100)
	ELSEIF cBanco=="341"
		oPrn:Say( 2575+nAjust2, 0070, "InstruÁıes de resposabilidade do benefici·rio, Qualquer d˙vida sobre esse boleto, contate o benefici·rio. ",oFont13,100  ) 
  	ELSE
		oPrn:Say( 2575+nAjust2, 0070, "InstruÁıes: ",oFont13,100  )
	ENDIF
	
	IF cBanco=="104"
		oPrn:Say( 2600+nAjust2, 0090, "Texto de Responsabilidade do Benefici·rio  " ,oFont17,100  )
	ENDIF
	oPrn:Say( 2505+nAjust2, 1730, "(-) Desconto/Abatimento",oFont13,100  )
	
	IF nAbatim>0
		oPrn:Say( 2530+nAjust2, 1975, TRANSF(nAbatim,"@E 999,999.99") , oFont12,100  )
	ENDIF                                                                                                
	
	oPrn:Say( 2650+nAjust2, 0090, "Apos o vencimento cobrar juros de 0,2% ao dia de atraso;" ,oFont14,100  ) 
	oPrn:Say( 2710+nAjust2, 0090, "Apos 10 dias de atraso sera enviado automaticamente para o cartorio." ,oFont14,100  )

	If nmulta<>"0,00"
		oPrn:Say( 2740+nAjust2, 0090, "COBRAR MULTA DE 2% AP”S O VENCIMENTO." ,oFont14,100  )
	EndIf    
	IF cBanco=="745"
		oPrn:Say( 2800+nAjust2, 0090, "PRF/TIT/PARC: "+SE1->E1_PREFIXO+"-"+AllTrim(SE1->E1_NUM)+"-"+SE1->E1_PARCELA ,oFont14,100  )
	ENDIF
	IF nmulta<>"0,00" .AND. cBanco=="341" .AND. cAgencia=='01248'                                  
		oPrn:Say( 2800+nAjust2, 0090, "TITULO CAUCIONADO EM FAVOR DO BANCO VOTORANTIM S/A" ,oFont14,100  )
	ENDIF
	/*
	dbSelectArea("SE1")
	sNotFat := ''
	nRecn := Recno()
	nInd  := dbSetOrder()
	sReg  := SE1->E1_FILIAL+SE1->E1_CLIENTE+SE1->E1_LOJA+SE1->E1_NUM
	dbSetOrder(24)
	DbSeek(sReg,.T.)
	While !Eof() .And. Alltrim(sReg)  == Alltrim(SE1->E1_FILIAL+SE1->E1_CLIENTE+SE1->E1_LOJA+SE1->E1_FATURA)
	      iF !SE1->E1_NUM $ sNotFat
		      sNotFat += IIF(Empty(sNotFat),'', ' / ') + SE1->E1_NUM
	      EndIf
	      DbSkip()
	EndDo         
	dbSelectArea("SE1")
	dbSetOrder(nInd)
	DbGoto(	nRecn )
	nRecn := Recno()
	*/
    If !Empty(sNotFat)
        IF cBanco == "341" .AND. cAgencia=='01248'
		    oPrn:Say( 2830+nAjust2, 0090, "FATURA REF. NF : " + sNotFat ,oFont14,100  )
        ELSEIF cBanco == "341"
		    oPrn:Say( 2830+nAjust2, 0090, "FATURA REF. NF : " + sNotFat ,oFont14,100  )
        ELSEIF cBanco=="745" 
	        oPrn:Say( 2830+nAjust2, 0090, "FATURA REF. NF : " + sNotFat ,oFont14,100  )
	    ELSE
	        oPrn:Say( 2800+nAjust2, 0090, "FATURA REF. NF : " + sNotFat ,oFont14,100  )
	    ENDIF
	EndIf
	
	//oPrn:Say( 2760+nAjust2, 0090, MsgInstr03               ,oFont18,100  )
	// RCO (02/03/2010) 
	
	If !Empty(SE1->E1_HIST)
        IF cBanco=="341" .AND. cAgencia=='01248'
		    oPrn:Say( 2860+nAjust2, 0090, SE1->E1_HIST             ,oFont18,100  )	
        ELSEIF cBanco=="341"
		    oPrn:Say( 2860+nAjust2, 0090, SE1->E1_HIST             ,oFont18,100  )	
        ELSEIF cBanco=="745" 
	        oPrn:Say( 2860+nAjust2, 0090, SE1->E1_HIST             ,oFont18,100  )	
	    ELSE
	        oPrn:Say( 2830+nAjust2, 0090, SE1->E1_HIST             ,oFont18,100  )	
	    ENDIF
	Else 
	    If nAbatim > 0 
	    
			dbSelectArea("SE1")
			_HistAbatim := ''
			nRecn := Recno()
			nInd  := dbSetOrder()
			sReg  := xFilial("SE1")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+"AB-"
			dbSetOrder(1)
			DbSeek(sReg)
			If Found()
	      		_HistAbatim := SE1->E1_HIST
			Endif         
			dbSelectArea("SE1")
			dbSetOrder(nInd)
			DbGoto(	nRecn )
	         
	        If !Empty(_HistAbatim)	    
			    oPrn:Say( 2770+nAjust2, 0090, "* VLR ABATIM: "+AllTrim(_HistAbatim)+" *"       ,oFont18,100  )	 
			Endif    
	    Endif
	Endif	
	
	//oPrn:Say( 2760+nAjust2, 0090, SE1->E1_HIST             ,oFont18,100  )
	//oPrn:Say( 2800+nAjust2, 0090, ALLTRIM(SE1->E1_HIST)+" (IDCNAB="+SE1->E1_IDCNAB+")"  ,oFont18,100  )
	
	oPrn:Say( 2575+nAjust2, 1730, "(-) Outras deduÁıes "   ,oFont13,100  )
	
	IF SE1->E1_DECRESC>0
		oPrn:Say( 2600+nAjust2, 1975, TRANSF(SE1->E1_DECRESC,"@E 999,999.99") , oFont12,100  )
	ENDIF
	
	oPrn:Say( 2645+nAjust2, 1730, "(+) Mora/Multa/Juros "  ,oFont13,100  )
	oPrn:Say( 2715+nAjust2, 1730, "(+) Outros Acrecimos "  ,oFont13,100  )
	
	IF SE1->E1_ACRESC>0
		oPrn:Say( 2740+nAjust2, 1975, TRANSF(SE1->E1_ACRESC,"@E 999,999.99") , oFont12,100  )
	ENDIF
	
	oPrn:Say( 2785+nAjust2, 1730, "(=) Valor Cobrado "     ,oFont13,100  )
	
	IF (SE1->E1_DECRESC+nAbatim+SE1->E1_ACRESC)>0
		// RCO (26/05/11)
		//oPrn:Say( 2810+nAjust2, 1975, TRANSF(SE1->E1_SALDO-SE1->E1_DECRESC-nAbatim+SE1->E1_ACRESC,"@E 999,999.99") , oFont12,100  )
		IF sPAR14=='S'
			oPrn:Say( 2800+nAjust2, 1975, TRANSF(SE1->E1_SALDO-SE1->E1_DECRESC-nAbatim+SE1->E1_ACRESC,"@E 999,999.99") , oFont12,100  )
		ELSE
			oPrn:Say( 2800+nAjust2, 1975, TRANSF(SE1->E1_VALOR-SE1->E1_DECRESC-nAbatim+SE1->E1_ACRESC,"@E 999,999.99") , oFont12,100  )
		ENDIF
	ENDIF

	oPrn:Say( 2920+nAjust2, 0070, "Pagador "                 ,oFont13,100  )
	oPrn:Say( 2955+nAjust2, 0090, ALLTRIM(SE1->E1_CLIENTE) + " - " + ALLTRIM(cNome) + " - " +cCgc, oFont12,100)
	
	IF  Empty(SA1->A1_ENDCOB)
		oPrn:Say( 2995+nAjust2, 0090, ALLTRIM(SA1->A1_END), oFont12,100)
		oPrn:Say( 3035+nAjust2, 0090, TRANSFORM(SA1->A1_CEP,"@R 99999-999")+" - "+ALLTRIM(SA1->A1_BAIRRO)+" - "+ALLTRIM(SA1->A1_MUN)+" - "+SA1->A1_EST, oFont12,100  )
	ELSE
		oPrn:Say( 2995+nAjust2, 0090, ALLTRIM(SA1->A1_ENDCOB), oFont12,100)
		oPrn:Say( 3035+nAjust2, 0090, TRANSFORM(SA1->A1_CEPC,"@R 99999-999")+" - "+ALLTRIM(SA1->A1_BAIRROC)+" - "+ALLTRIM(SA1->A1_MUNC)+" - "+SA1->A1_ESTC, oFont12,100  )
	ENDIF
	
	IF cBanco=="001"
		cCNPJFilial = '05097311000134'
		oPrn:Say( 3080+nAjust2, 0070, "Benefici·rio "                 ,oFont13,100  )
		oPrn:Say( 3070+nAjust2, 0190, ALLTRIM(SM0->M0_NOMECOM)+" - "+TRANSFORM(ALLTRIM(cCNPJFilial), "@R 99.999.999/9999-99"), oFont12,100  ) //oPrn:Say( 3000+nAjust2, 0190, SM0->M0_NOMECOM		, oFont12,100  ) //Alterado 14/12/2011 - BRUNO
	ELSE 
		IF cBanco == "254"
			oPrn:Say( 3080+nAjust2  , 0070, "Pagador Avalista: "                 ,oFont13,100  )
			oPrn:Say( 3070+nAjust2+5, 0250, ALLTRIM(SM0->M0_NOMECOM)+" - "+TRANSFORM(ALLTRIM(SM0->M0_CGC), "@R 99.999.999/9999-99"), oFont12,100  )
		ELSE
			oPrn:Say( 3080+nAjust2, 0070, "Benefici·rio "                 ,oFont13,100  )
			oPrn:Say( 3070+nAjust2, 0190, Substr(SM0->M0_NOMECOM,1,30)+" - "+TRANSFORM(ALLTRIM(SM0->M0_CGC), "@R 99.999.999/9999-99"), oFont12,100  )
		ENDIF
	ENDIF
	
	//IF cBanco == "341"                                                           
		oPrn:Say( 3060+nAjust2, 1450, "AutenticaÁ„o Mec‚nica"   ,oFont3,100  )  
	//ELSE
		//oPrn:Say( 2920+nAjust2, 1750, "AutenticaÁ„o Mec‚nica"   ,oFont18,100  )  
	//ENDIF

	IF cBanco == "422"
		oPrn:Say( 2090+nAjust2, 1950, "Recibo do Pagador"    	,oFont3,100  )
	ELSEIF cBanco == "341"
		oPrn:Say( 3060+nAjust2, 1950, "Recibo do Pagador"    	,oFont3,100  )
	ELSE
		oPrn:Say( 3060+nAjust2, 1950, "Recibo do Pagador"    	,oFont3,100  )
	ENDIF
	
	//******************************************
	//  MONTA FICHA COMPENSA«√O    +nAjust3
	//******************************************
	
	// Monta linhas horizontais
	oPrn:Line(2220+nAjust3+70, 0050, 2220+nAjust3+70, 2380)
	oPrn:Line(2290+nAjust3+70, 0050, 2290+nAjust3+70, 2380)
	oPrn:Line(2360+nAjust3+70, 0050, 2360+nAjust3+70, 2380)
	oPrn:Line(2430+nAjust3+70, 0050, 2430+nAjust3+70, 2380)
	oPrn:Line(2500+nAjust3+70, 0050, 2500+nAjust3+70, 2380)
	oPrn:Line(2570+nAjust3+70, 0050, 2570+nAjust3+70, 2380) 
	
	oPrn:Line(2845+nAjust3+140, 0050, 2845+nAjust3+140, 2380)
	oPrn:Line(3050+nAjust3+140, 0050, 3050+nAjust3+140, 2380)
	
	oPrn:Line(2570+nAjust3+140, 1720, 2570+nAjust3+140, 2380)
	oPrn:Line(2640+nAjust3+140, 1720, 2640+nAjust3+140, 2380)
	oPrn:Line(2710+nAjust3+140, 1720, 2710+nAjust3+140, 2380)
	//oPrn:Line(2780+nAjust3+140, 1720, 2780+nAjust3+140, 2380)
	
	// Monta linha verticais
	oPrn:Line(2135+nAjust3+70, 0620, 2215+nAjust3+70, 0620)
	oPrn:Line(2135+nAjust3+70, 0830, 2215+nAjust3+70, 0830)
	
	oPrn:Line(2220+nAjust3+70, 1720, 2915+nAjust3+70, 1720)
	
	IF cBanco=="033"
		oPrn:Line(2360+nAjust3+140, 0500, 2430+nAjust3+140, 0500)
	ELSE
		oPrn:Line(2360+nAjust3+140, 0500, 2500+nAjust3+140, 0500)
	ENDIF
	oPrn:Line(2360+nAjust3+140, 0900, 2500+nAjust3+140, 0900)
	oPrn:Line(2360+nAjust3+140, 1100, 2430+nAjust3+140, 1100)
	oPrn:Line(2360+nAjust3+140, 1400, 2500+nAjust3+140, 1400)
	oPrn:Line(2430+nAjust3+140, 0700, 2500+nAjust3+140, 0700)
	
	IF FILE(aBancos[nPOS,3])
		IF cBanco=="237"  
			oPrn:SayBitmap( 2150+nAjust3-12+70, 0050,aBancos[nPOS,3],210,80 )
			oPrn:Say( 2150+nAjust3+70          ,0330,aBancos[nPOS,2],oFont24,100) 
		ELSEIF cBanco=="422"  
			oPrn:SayBitmap( 2150+nAjust3-12+70, 0100,aBancos[nPOS,3],200,80 )
		ELSEIF cBanco=="033"  
			oPrn:SayBitmap( 2150+nAjust3-12+70, 0100,aBancos[nPOS,3],200,80 )
		ELSEIF cBanco=="001"  
			oPrn:SayBitmap( 2150+nAjust3-15+70, 0050,aBancos[nPOS,3],400,90 )
		ELSEIF cBanco=="341"     
			oPrn:Say( 2180+nAjust3-25+70, 0100,"Banco Ita˙ SA", oFont20,100 )
	    ELSEIF cBanco=="104" .OR. cBanco=="254"
			oPrn:SayBitmap( 2150+nAjust3-12+70, 0100,aBancos[nPOS,3],200,80 )
	    ELSEIF cBanco=="745"  
			oPrn:SayBitmap( 2150+nAjust3-12+70, 0100,aBancos[nPOS,3],200,80 )
		EndIf
	ELSE
		oPrn:Say( 2150+nAjust3+70, 50, aBancos[nPOS,2]		,oFont20,100)
	ENDIF
	
	oPrn:Say( 2150+nAjust3+70, 0640, aBancos[nPOS,4]			,oFont20,100)
	oPrn:Say( 2155+nAjust3+70, 0870, aBancos[nPOS,7]         ,oFont4,100)
	
	oPrn:Say( 2225+nAjust3+70, 0070, "Local de Pagamento "    ,oFont13,100  )
	oPrn:Say( 2225+nAjust3+70, 1730, "Vencimento "            ,oFont13,100  )
	IF cBanco=="237"                                                                          
		oPrn:Say( 2245+nAjust3+70, 0090, "PAG¡VEL PREFERENCIALMENTE NAS AG NCIAS DO BRADESCO",oFont22,100  ) 
	ELSEIF cBanco=="341"	
		oPrn:Say( 2245+nAjust3+70, 0090, "AtÈ o vencimento, preferencialmente no Ita˙. ApÛs o vencimento, somente no Ita˙",oFont15,100  )
	ELSEIF cBanco=="104"
		oPrn:Say( 2245+nAjust3+70, 0090, "Pagto em qualquer agÍncia banc·ria ou lotÈricas atÈ o vencimento. ApÛs, somente na CAIXA.",oFont15,100  )
	ELSE
		oPrn:Say( 2245+nAjust3+70, 0090, "PAG¡VEL EM QUALQUER BANCO AT… O VENCIMENTO",oFont22,100  )
	ENDIF                                      
	
	IF cBanco == "341"                                         
		oPrn:Say( 2250+nAjust3+70, 2040, cData     ,oFont15,100  )
	ELSE
		oPrn:Say( 2250+nAjust3+70, 1900, cData     ,oFont15,100  )
	ENDIF
	
	oPrn:Say( 2295+nAjust3+70, 0070, "Benefici·rio "               ,oFont13,100  )
	oPrn:Say( 2295+nAjust3+70, 1730, "AgÍncia/Codigo Benefici·rio "        ,oFont13,100  ) 
	
	oPrn:Say( 2365+nAjust3+70, 0070, "EndereÁo "               ,oFont13,100  )
	oPrn:Say( 2390+nAjust3+70, 0090, cEndBeneficiario, oFont12,100  )   	
	
	// RCO (02/03/2010)
	IF cBanco=="104" .OR. cBanco == "341"
		oPrn:Say( 2320+nAjust3+70, 0090, ALLTRIM(SUBS(SM0->M0_NOMECOM,1,35))+" - CNPJ: "+ALLTRIM(TRANSFORM(SM0->M0_CGC, "@R 99.999.999/9999-99"))		,oFont12,100  )
	ELSEIF cBanco == "254"                                                             
		oPrn:Say( 2320+nAjust3+70, 0090, "PARAN¡ BANCO S/A",oFont12,100  )
	ELSEIF cBanco == "001"	
		oPrn:Say( 2320+nAjust3+70, 0090, ALLTRIM(SUBS(SM0->M0_NOMECOM,1,35))+" - CNPJ: "+ALLTRIM(TRANSFORM(SM0->M0_CGC, "@R 99.999.999/9999-99"))		,oFont12,100  )
	ELSE
		oPrn:Say( 2320+nAjust3+70, 0090, SUBS(SM0->M0_NOMECOM,1,35)		,oFont12,100  )
	ENDIF
	
	IF cBanco=="237"
	   oPrn:Say( 2320+nAjust3+70, 1880, transform(strzero(val(StrTran(cAgeImp,"-","")),5),"@R 9999-9")+"/"+transform(Left(sPAR03,8),"@R 9999999-9"),oFont12,100  )
	ELSEIF cBanco=="422"  
	   oPrn:Say( 2320+nAjust3+70, 1880, cCodCed+"/"+TRANSFORM(cContaSEE,"@R 99999999-9"),oFont12,100) 
   	ELSEIF cBanco=="254"  
	   oPrn:Say( 2320+nAjust3+70, 1880, "049 / 0222400-3",oFont12,100)
	ELSEIF cBanco=="033" ///648701-7
	   //oPrn:Say( 2320+nAjust3+70, 1880, transform(SUBSTR(cCodCed,1,4),"@R 9999")+"/"+transform(SUBSTR(cContaSEE,1,10),"@R 999999999-9"),oFont12,100  )
	   oPrn:Say( 2320+nAjust3+70, 1880, transform(SUBSTR(cCodCed,1,4),"@R 9999")+" / 648701-7",oFont12,100  )	   
	ELSEIF cBanco=="104"  
	   oPrn:Say( 2320+nAjust3+70, 1880, transform(cCodCed,"@R 9999-9")+" / "+transform(cContaSEE,"@R 999999-9"),oFont12,100)
	ELSEIF cBanco=="001" .and. alltrim(cConta) == "309532"
	   oPrn:Say( 2320+nAjust3+70, 1880, transform(strzero(val(StrTran(cAgencia,"-","")),5),"@R 9999-9") + "/" + transform(Substr(alltrim(cContaSEE),1,8),"@R 9999999-9"),oFont12,100  )
	ELSEIF cBanco=="001"
	   oPrn:Say( 2320+nAjust3+70, 1880, transform(strzero(val(StrTran(cAgeImp,"-","")),5),"@R 9999-9")+"/"+transform(cCodced,"@R 999999-9"),oFont12,100  )
	ELSEIF cBanco=="341" .and. alltrim(cConta) <> "122808"
	   oPrn:Say( 2320+nAjust3+70, 1930, transform(strzero(val(StrTran(cAgeImp,"-","")),4),"@R 9999")+"/"+transform(Substr(sPAR03,3,6),"@R 99999-9"),oFont12,100  )
	ELSEIF cBanco=="341" .and. alltrim(cConta) == "122808"
	   oPrn:Say( 2320+nAjust3 + 70, 1930, transform(strzero(val(StrTran(cAgencia,"-","")),4),"@R 9999")+"/"+transform(Substr(cConta,1,6),"@R 99999-9"),oFont12,100)
	/*
	ELSEIf cBanco=="399"
		oPrn:Say( 2320+nAjust3+70, 1880, substr(StrTran(sPAR02,"-",""),1,4)+"-"+substr(StrTran(sPAR02,"-",""),1,4)+Right(Alltrim(StrTran(sPAR03,"-","")),7),oFont12,100  )
	elseif cBanco=="422"
	   oPrn:Say( 2320+nAjust3+70, 1880, substr(sPAR02,1,5)+"."+substr(sPAR03,2,8)+"-"+substr(sPAR03,10,1),oFont12,100  )	      
	*/
	ELSEIF cBanco=="104"
	   oPrn:Say( 2320+nAjust3+70, 1880, SUBSTR(aBancos[nPOS,6],1,4)+"."+SUBSTR(aBancos[nPOS,6],5,3)+"."+SUBSTR(aBancos[nPOS,6],8,8)+"-"+SUBSTR(aBancos[nPOS,6],16,1),oFont12,100  )
	ELSEIF cBanco=="745"
	   oPrn:Say( 2320+nAjust3+70, 1880, cCodCed+"/"+cContaSEE,oFont12,100  )
	EndIf
	oPrn:Say( 2365+nAjust3+140, 0070, "Data Documento "        ,oFont13,100  )
	oPrn:Say( 2365+nAjust3+140, 0510, "N∫. Documento "         ,oFont13,100  )
	oPrn:Say( 2365+nAjust3+140, 0910, "Especie Doc. "          ,oFont13,100  )
	oPrn:Say( 2365+nAjust3+140, 1110, "Aceite "                ,oFont13,100  )
	oPrn:Say( 2365+nAjust3+140, 1410, "Data do Processamento " ,oFont13,100  )
    if cBanco<>"237"
		oPrn:Say( 2365+nAjust3+70, 1730, "Nosso Numero"          ,oFont13,100  )
	else
		oPrn:Say( 2365+nAjust3+70, 1730, "Carteira/Nosso Numero"          ,oFont13,100  )
	endif
	
	oPrn:Say( 2390+nAjust3+140, 0090, cData2       				, oFont12,100  )
	oPrn:Say( 2390+nAjust3+140, 0520, SE1->E1_PREFIXO+"/"+SE1->E1_NUM+"-"+SE1->E1_PARCELA , oFont12,100  )
	//oPrn:Say( 2390+nAjust3+70, 0530, IIF(cBanco$"745",sDocCit,SE1->E1_PREFIXO+"/"+AllTrim(SE1->E1_NUM)+"-"+SE1->E1_PARCELA), oFont12,100  )
    oPrn:Say( 2390+nAjust3+140, 0970, IIF(cBanco=="399","PD",IIF(cBanco$"745","DMI","DM")) , oFont12,100  )
	oPrn:Say( 2390+nAjust3+140, 1230, IIF(cBanco$"745","N","N„o")     , oFont12,100  )
	oPrn:Say( 2390+nAjust3+140, 1440, cData3          			, oFont12,100  )
	oPrn:Say( 2390+nAjust3+70, 1880, aBancos[nPOS,8]         	, oFont12,100  )
	
	
	IF cBanco=="033"
		oPrn:Say( 2435+nAjust3+140, 0070, "Carteira"          ,oFont13,100  )
	ELSE
		oPrn:Say( 2435+nAjust3+140, 0070, "Uso do Banco "          ,oFont13,100  )
	ENDIF 
	
	IF cBanco<>"033"
		oPrn:Say( 2435+nAjust3+140, 0510, "Carteira "			   ,oFont13,100  )
	ENDIF
	
	oPrn:Say( 2435+nAjust3+140, 0710, "Especie "               ,oFont13,100  )
	oPrn:Say( 2435+nAjust3+140, 0910, "Quantidade "            ,oFont13,100  )
	oPrn:Say( 2435+nAjust3+140, 1410, "Valor "                 ,oFont13,100  )
	oPrn:Say( 2435+nAjust3+70, 1730, "(=) Valor do Documento "    ,oFont13,100  )
	
	If cBanco == "001"	
		oPrn:Say( 2460+nAjust3+140, 0540, "17"            			, oFont12,100  ) 
	ELSEIF cBanco == "104"
		oPrn:Say( 2460+nAjust3+140, 0540, "CR"		   			    , oFont12,100  )
	ELSEIF cBanco == "033"
		oPrn:Say( 2460+nAjust3+140, 0090, "COBRANCA SIMPLES - ECR"		   			    , oFont12,100  )		
	Else	
		oPrn:Say( 2460+nAjust3+140, 0540, aBancos[nPOS,5]			, oFont12,100  )
    Endif
	oPrn:Say( 2460+nAjust3+140, 0745-30, if(cBanco=="399","9 - REAL","R$")                , oFont12,100  )
/*	
	IF lTitAnt
		oPrn:Say(2460+nAjust3+140, 1440, TRANSF(nVlrCob,"@E 999,999.99"), oFont12,100  )
    ELSE
		IF sPAR14=='S'      // imprime saldo do tÌtulo
			oPrn:Say(2460+nAjust3+140, 1440, TRANSF(SE1->E1_SALDO-SE1->E1_DECRESC-nAbatim+SE1->E1_ACRESC,"@E 999,999.99"), oFont12,100  )
		ELSE
			oPrn:Say(2460+nAjust3+140, 1440, TRANSF(SE1->E1_VALOR-SE1->E1_DECRESC-nAbatim+SE1->E1_ACRESC,"@E 999,999.99"), oFont12,100  )
		ENDIF
	ENDIF		
*/	
    IF lTitAnt
		oPrn:Say( 2460+nAjust3+70, 1975, TRANSF(nVlrCob,"@E 999,999.99"), oFont12,100  )
    ELSE
		IF sPAR14=='S'
			oPrn:Say( 2460+nAjust3+70, 1975, TRANSF(SE1->E1_SALDO,"@E 999,999.99") , oFont12,100  )
		ELSE
			oPrn:Say( 2460+nAjust3+70, 1975, TRANSF(SE1->E1_VALOR,"@E 999,999.99") , oFont12,100  )
		ENDIF
	ENDIF	
	
	
	IF cBanco=="422"
		oPrn:Say( 2505+nAjust3+140, 0070, "InstruÁıes: As informaÁ„oes contidas neste boleto, s„o de exclusiva responsabilidade do benefici·rio .",oFont13,100  )
	ELSEIF cBanco=="341"
		oPrn:Say( 2505+nAjust3+140, 0070, "InstruÁıes de resposabilidade do benefici·rio, Qualquer d˙vida sobre esse boleto, contate o benefici·rio. ",oFont13,100  ) 
  	ELSE                                                                     
		oPrn:Say( 2505+nAjust3+140, 0070, "InstruÁıes "            ,oFont13,100  )
	ENDIF
	
	IF cBanco=="104"
		oPrn:Say( 2530+nAjust3+140, 0090, "Texto de Responsabilidade do Benefici·rio " ,oFont17,100  )
	ENDIF
	oPrn:Say( 2505+nAjust3+70, 1730, "(-) Desconto/Abatimento "          ,oFont13,100  )
	
	IF nAbatim>0
		oPrn:Say( 2530+nAjust3+70, 1975, TRANSF(nAbatim,"@E 999,999.99") , oFont12,100  )
	ENDIF
	
	oPrn:Say( 2580+nAjust3+140, 0090, "Apos o vencimento cobrar juros de 0,2% ao dia de atraso;" ,oFont14,100  ) 

	IF lProtesto
		oPrn:Say( 2610+nAjust3+140, 0090, "Apos 10 dias de atraso sera enviado automaticamente para o cartorio." ,oFont14,100  )
		//oPrn:Say( 2640+nAjust3+70, 0090, "COM INCLUS√O DE SERASA." ,oFont14,100  ) 
	ENDIF 
	//oPrn:Say( 2670+nAjust3+70, 0090, "VALORES A MENOR N√O SER¡ QUITADO." ,oFont14,100  ) 
    //oPrn:Say( 2640+nAjust3+140, 0090, "COBRAR JUROS DE MORA 6% AO M S" ,oFont14,100  )
	If nmulta<>"0,00"
		oPrn:Say( 2670+nAjust3+140, 0090, "COBRAR MULTA DE 2% AP”S O VENCIMENTO." ,oFont14,100  )
	EndIf   
	IF cBanco=="745"
		oPrn:Say( 2730+nAjust3+140, 0090, "PRF/TIT/PARC: "+SE1->E1_PREFIXO+"-"+AllTrim(SE1->E1_NUM)+"-"+SE1->E1_PARCELA ,oFont14,100  )
	ENDIF

	IF !Empty(sNotFat)
	  		IF cBanco=="341" .AND. cAgencia=='01248'
			    oPrn:Say( 2760+nAjust3+140, 0090, "FATURA REF. NF : " + sNotFat ,oFont14,100  )
	        ELSEIF cBanco=="745" 
		        oPrn:Say( 2760+nAjust3+140, 0090, "FATURA REF. NF : " + sNotFat ,oFont14,100  )
		    ELSE
		        oPrn:Say( 2730+nAjust3+140, 0090, "FATURA REF. NF : " + sNotFat ,oFont14,100  )
		    ENDIF        
	ENDIF
	IF nmulta<>"0,00" .AND. cBanco=="341" .AND. cAgencia=='01248'                                   
		oPrn:Say( 2730+nAjust3+140, 0090, "TITULO CAUCIONADO EM FAVOR DO BANCO VOTORANTIM S/A" ,oFont14,100  )
	ENDIF
	IF nmulta=="0,00" .AND. cBanco=="341" .AND. cAgencia=='01248'                                    
	   	oPrn:Say( 2700+nAjust3+140, 0090, "TITULO CAUCIONADO EM FAVOR DO BANCO VOTORANTIM S/A" ,oFont14,100  )
	ENDIF

	If !Empty(SE1->E1_HIST)
        IF cBanco=="341" .AND. cAgencia=='01248'
		    oPrn:Say( 2860+nAjust3+70, 0090, SE1->E1_HIST             ,oFont18,100  )	
        ELSEIF cBanco=="745" 
	        oPrn:Say( 2860+nAjust3+70, 0090, SE1->E1_HIST             ,oFont18,100  )	
	    ELSE
	        oPrn:Say( 2830+nAjust3+70, 0090, SE1->E1_HIST             ,oFont18,100  )	
	    ENDIF
	Else 
	    If nAbatim > 0 
	    
			dbSelectArea("SE1")
			_HistAbatim := ''
			nRecn := Recno()
			nInd  := dbSetOrder()
			sReg  := xFilial("SE1")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+"AB-"
			dbSetOrder(1)
			DbSeek(sReg)
			If Found()
	      		_HistAbatim := SE1->E1_HIST
			Endif         
			dbSelectArea("SE1")
			dbSetOrder(nInd)
			DbGoto(	nRecn )
	         
	        If !Empty(_HistAbatim)	    
			    oPrn:Say( 2770+nAjust3+70, 0090, "* VLR ABATIM: "+AllTrim(_HistAbatim)+" *"       ,oFont18,100  )	 
			Endif    
	    Endif
	Endif	
		
	//oPrn:Say( 2730+nAjust3+70, 0090, MsgInstr03               ,oFont18,100  )
	// RCO (02/02/2010)
    
	//oPrn:Say( 2760+nAjust3+70, 0090, SE1->E1_HIST             ,oFont18,100  )
	//oPrn:Say( 2800+nAjust3+70, 0090, ALLTRIM(SE1->E1_HIST)+" (IDCNAB="+SE1->E1_IDCNAB+")"  ,oFont18,100  )
	
	oPrn:Say( 2575+nAjust3+70, 1730, "(-) Outras deduÁıes "   ,oFont13,100  )
	
	IF SE1->E1_DECRESC>0
		oPrn:Say( 2600+nAjust3+70, 1975, TRANSF(SE1->E1_DECRESC,"@E 999,999.99") , oFont12,100  )
	ENDIF
	
	oPrn:Say( 2645+nAjust3+70, 1730, "(+) Mora/Multa/Juros "  ,oFont13,100  )
	oPrn:Say( 2715+nAjust3+70, 1730, "(+) Outros Acrecimos "  ,oFont13,100  )
	
	IF SE1->E1_ACRESC>0
		oPrn:Say( 2730+nAjust3+70, 1975, TRANSF(SE1->E1_ACRESC,"@E 999,999.99") , oFont12,100  )
	ENDIF
	
	oPrn:Say( 2785+nAjust3+70, 1730, "(=) Valor Cobrado "     ,oFont13,100  )
	
	IF (SE1->E1_DECRESC+nAbatim+SE1->E1_ACRESC)>0
		// RCO (26/05/11)
		//oPrn:Say( 2805+nAjust3+70, 1975, TRANSF(SE1->E1_SALDO-SE1->E1_DECRESC-nAbatim+SE1->E1_ACRESC,"@E 999,999.99") , oFont12,100  )
		IF sPAR14=='S'
			oPrn:Say( 2805+nAjust3+70, 1975, TRANSF(SE1->E1_SALDO-SE1->E1_DECRESC-nAbatim+SE1->E1_ACRESC,"@E 999,999.99") , oFont12,100  )
		ELSE
			oPrn:Say( 2805+nAjust3+70, 1975, TRANSF(SE1->E1_VALOR-SE1->E1_DECRESC-nAbatim+SE1->E1_ACRESC,"@E 999,999.99") , oFont12,100  )
		ENDIF
	ENDIF

	oPrn:Say( 2850+nAjust3+140, 0070, "Pagador "                 ,oFont13,100  )
	oPrn:Say( 2885+nAjust3+140, 0090, ALLTRIM(SE1->E1_CLIENTE) + " - " + ALLTRIM(cNome)+" - " +cCgc, oFont12,100  )
	
	IF  Empty(SA1->A1_ENDCOB) 
		oPrn:Say( 2925+nAjust3+140, 0090, ALLTRIM(SA1->A1_END), oFont12,100)
		oPrn:Say( 2965+nAjust3+140, 0090, TRANSFORM(SA1->A1_CEP,"@R 99999-999")+" - "+ALLTRIM(SA1->A1_BAIRRO)+" - "+ALLTRIM(SA1->A1_MUN)+" - "+SA1->A1_EST, oFont12,100  )
	ELSE
		oPrn:Say( 2925+nAjust3+140, 0090, ALLTRIM(SA1->A1_ENDCOB), oFont12,100)
		oPrn:Say( 2965+nAjust3+140, 0090, TRANSFORM(SA1->A1_CEPC,"@R 99999-999")+" - "+ALLTRIM(SA1->A1_BAIRROC)+" - "+ALLTRIM(SA1->A1_MUNC)+" - "+SA1->A1_ESTC, oFont12,100  )
	ENDIF
	
	IF cBanco == "254"
		oPrn:Say( 3000+nAjust3+140+5, 0250, ALLTRIM(SM0->M0_NOMECOM)+" - "+TRANSFORM(ALLTRIM(SM0->M0_CGC), "@R 99.999.999/9999-99"), oFont12,100  )
	ENDIF

	oPrn:Say( 3010+nAjust3+140, 0070, "Pagador Avalista: "                 ,oFont13,100  )
	
	//IF cBanco=="341"
		oPrn:Say( 3220+nAjust3+120, 1450, "AutenticaÁ„o Mec‚nica"   ,oFont3,100  )  
	//ELSE
	  //	oPrn:Say( 3070+nAjust3+120, 1750, "AutenticaÁ„o Mec‚nica"   ,oFont18,100  )  
	//ENDIF
			
	IF cBanco=="341"
	    oPrn:Say( 3220+nAjust3+120, 1950, "Ficha de CompensaÁ„o"    ,oFont3,100  )  		
	ELSE
		oPrn:Say( 3220+nAjust3+120, 1950, "Ficha de CompensaÁ„o"    ,oFont3,100  ) 
	ENDIF 

	/*
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	±±⁄ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒø±±
	±±≥FunáÖo    ≥MSBAR       ≥ Autor ≥ ALEX SANDRO VALARIO ≥ Data ≥  06/99   ≥±±
	±±√ƒƒƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒ¥±±
	±±≥DescriáÖo ≥ Imprime codigo de barras                                   ≥±±
	±±√ƒƒƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¥±±
	±±≥Parametros≥ 01 cTypeBar String com o tipo do codigo de barras          ≥±±
	±±≥          ≥ 				"EAN13","EAN8","UPCA" ,"SUP5"   ,"CODE128"    ≥±±
	±±≥          ≥ 				"INT25","MAT25,"IND25","CODABAR","CODE3_9"    ≥±±
	±±≥          ≥ 02 nRow		Numero da Linha em centimentros               ≥±±
	±±≥          ≥ 03 nCol		Numero da coluna em centimentros	      	    ≥±±
	±±≥          ≥ 04 cCode		String com o conteudo do codigo               ≥±±
	±±≥          ≥ 05 oPr		Obejcto Printer                               ≥±±
	±±≥          ≥ 06 lcheck	Se calcula o digito de controle               ≥±±
	±±≥          ≥ 07 Cor 		Numero  da Cor, utilize a "common.ch"         ≥±±
	±±≥          ≥ 08 lHort		Se imprime na Horizontal                      ≥±±
	±±≥          ≥ 09 nWidth	Numero do Tamanho da barra em centimetros     ≥±±
	±±≥          ≥ 10 nHeigth	Numero da Altura da barra em milimetros       ≥±±
	±±≥          ≥ 11 lBanner	Se imprime o linha em baixo do codigo         ≥±±
	±±≥          ≥ 12 cFont		String com o tipo de fonte                    ≥±±
	±±≥          ≥ 13 cMode		String com o modo do codigo de barras CODE128 ≥±±
	±±√ƒƒƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¥±±
	±±≥ Uso      ≥ Impress∆o de etiquetas c¢digo de Barras para HP e Laser    ≥±±
	±±¿ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
	*/
	nPosBar	:= 23.1        

	// RCO (02/03/2010) - retirada linha abaixo do codigo de barras
	//MSBAR("INT25" ,nPosBar , 1.0 ,cbarraFim,oPrn,.F.,NIL,.T.,0.0295,1.3,.T.,NIL,NIL,LPRINT)
	MSBAR("INT25" ,nPosBar , 1.0 ,cbarraFim,oPrn,.F.,NIL,.T.,0.025,1.3,.F.,NIL,NIL,LPRINT)

	oPrn:Line(2520+200-30+170, 0050, 2520+200-30+170, 2380)
	oPrn:Say( 2525+200-30+170, 1950, "Cortar Aqui"    ,oFont13,100  ) //nAjuste3
	oPrn:Say( 1600,1950, "Cortar Aqui"    ,oFont13,100  ) //nAjuste2   
	IF cBanco<>'422'
		oPrn:Say( 560,1950, "Cortar Aqui"    ,oFont13,100  ) //nAjuste1
	ENDIF
	
	oPrn:EndPage()
	
	WM002->(dbSkip())
EndDo
WM002->(dbCloseArea())

oPrn:Preview()
SetPgEject(.F.)
MS_Flush()

RETURN(.t.)


/*/
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±…ÕÕÕÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕª±±
±±≥FunáÖo    ≥ CALCVALBOL≥ Autor ≥ RAFAEL OGEDA         ≥ Data ≥ 23/04/05 ≥±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±≥DescriáÖo ≥ Faz o Calculo dos Par‚metros de cada banco                 ≥±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Uso       ≥ DALQUIM                                                    ∫±±
±±»ÕÕÕÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
/*/
Static FUNCTION CALCVALBOL(cBanco,aBancos,sPar01,sPar02,sPar03,sPar14)
                              
Local _DtVenc   
   
If lTitAnt
   _DtVenc := dNewVen
Else
   _DtVenc := SE1->E1_VENCTO
Endif

cFatorVen	:= strzero(_DtVenc-CTOD("07/10/1997"),4)
cLinha		:= ""
// RCO (06/06/11)

// IDENTIFICA O BANCO PARA OBTEN«√O DOS PAR¬METROS
// - se n„o for nenhum dos bancos prÈ-determinados n„o imprime o boleto   
If sPAR01 == "237" .And. sPAR03 == "0076000519" 
   nPOS := 1  
ElseIf sPAR01 == "237" .And. sPAR03 == "0076001302"   
   nPOS := 2
ElseIf sPAR01 == "745" .And. sPAR03 == "3499590014"
   nPOS := 6
ElseIf sPAR01 == "745" .And. sPAR03 == "3499590012"
   nPOS := 7
Else
   nPOS := ASCAN(aBancos,{|x| x[1]==cBanco})  
Endif

// RHO - 03/11/05 - Recalcula o saldo do tÌtulo em funÁ„o dos decrÈscimos e dos abatimentos
// RHO - 29/11/05 - INCLUS√O DE ACR…SCIMO
// RCO (26/05/11)
//nSaldo := SE1->E1_SALDO-SE1->E1_DECRESC-nAbatim+SE1->E1_ACRESC

IF lTitAnt
	nSaldo := nVlrCob
ELSE
	IF sPAR14=='S'
		nSaldo := SE1->E1_SALDO - SE1->E1_DECRESC - nAbatim + SE1->E1_ACRESC
	ELSE
		nSaldo := SE1->E1_VALOR
	ENDIF
ENDIF	

IF cBanco=="399"
	
	cValor  := StrZero(100*nSaldo,10)
	cCartei	:= SUBS(aBancos[nPOS,5],1,2)
	
	// Calculo do digito verificador do Nosso Numero
	strmult := "5432765432"
	BaseDiv := 0
	_cCarNum := alltrim(cCartei)+subs(nossonum,1,11)
	For xx := 1 To 10
		BaseDiv := BaseDiv+Val(Subs(NossoNum,xx,1))*VAL(Subs(strmult,xx,1))
	Next xx
	resto  	:= BaseDiv % 11
	resto  	:= 11 - resto
	resto  	:= STR(IIF(resto>9 .or. resto==0 ,0,resto),1,0)
	
	Nossonum	:= nossonum+resto
	
	// Calculo do codigo de barras + digito
	// --------------------------------------------------------
	// 	01-03  03  BANCO ("237")
	// 	04-04  01  MOEDA ("9"=real,"0"=outras)
	// 	05-05  01  DIGITO VERIFICADOR (DAC)
	// 	06-09  04  FATORVEN
	// 	10-17  08  SALDO
	// 	18-19  02  SALDO (centavos)
	//    20-44  25  LIVRE (sistema BDL)
	// 	20-23  04  AGENCIA SEM DIGITO VERIFICADOR
	//	   24-25 02  CARTEIRA
	// 	26-36 11  NOSSONUM SEM N⁄MERO DE CONTROLE
	// 	37-43 07  CONTA SEM DIGITO VERIFICADOR
	//   44-44 01  "0"
	
	cLinha	:= ""
	strmult := "4329876543298765432987654329876543298765432"
	
	/*
	CAMPO LIVRE
	20 a 23 4 AgÍncia Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	24 a 25 2 Carteira
	26 a 36 11 N˙mero do Nosso N˙mero(Sem o digito verificador)
	37 a 43 7 Conta do Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	44 a 44 1 Zero
	*/
	livre   := substr((nossonum),1,11)+strzero(val(substr(StrTran(sPAR02,"-",""),1,4)),4)+Right(Alltrim(strtran(sPAR03,"-","")),7)+"00"+"1"
	sBarra  := alltrim(cBanco)+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+cFatorVen+cValor+livre
	BaseDiv := 0
	For xx := 1 To 43
		BaseDiv := BaseDiv+Val(Subs(sBarra,xx,1))*Val(Subs(strmult,xx,1))
	Next xx
	resto  	:= BaseDiv % 11
	resto  	:= 11 - resto
	resto  	:= STR(IIF(resto>9 .or. resto==0,1,resto),1,0)
	sBarra	:= cBanco+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+resto+cFatorVen+cValor+livre
	cBarraFim  	:= Alltrim(sBarra)
	
	// Calculo da linha digit†
	sDigi1 := cBanco+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+Subs(livre,1,5)  	// 23712.1510	+X
	sDigi2 := Subs (livre, 6,10)								// 90051.05001	+X
	sDigi3 := Subs (livre,16,10)								// 13008.00040	+X
	sDigi1 := cDigi(sDigi1)
	sDigi2 := cDigi(sDigi2)
	sDigi3 := cDigi(sDigi3)
	sDigi1 := Subs(sDigi1,1,5)+"."+Subs(sDigi1,6,5)+" "
	sDigi2 := Subs(sDigi2,1,5)+"."+Subs(sDigi2,6,6)+" "
	sDigi3 := Subs(sDigi3,1,5)+"."+Subs(sDigi3,6,6)+" "
	sDigit := sDigi1+sDigi2+sDigi3+resto+" "+cFatorVen+cValor
	
	// Linha Digit·vel
	aBancos[nPOS,7] := sDigit
	// Nosso N˙mero
	aBancos[nPOS,8] := SUBS(nossonum,1,11)
	// CÛdigo de Barras
	aBancos[nPOS,9] := cBarraFim 
	
ELSEIF cBanco=="237"

	cValor  := StrZero(100*nSaldo,10)
	cCartei	:= SUBS(aBancos[nPOS,5],1,2)
	
	// Calculo do digito verificador do Nosso Numero 
	dig237  := ""
    resto	:= 0
    strmult := "2765432765432"		
	BaseDiv := 0 
	
	IF LEN(ALLTRIM(NOSSONUM)) <= 11
	    _cCarNum := alltrim(cCartei)+subs(nossonum,1,11)
		For xx := 1 To 13
			BaseDiv := BaseDiv+Val(Subs(_cCarNum,xx,1))*VAL(Subs(strmult,xx,1))
		Next xx
		resto	 := BaseDiv % 11
		resto 	 := 11 - resto
		dig237   := IIF(resto==10,"P",IIF(resto==11,"0",ALLTRIM(STR(resto))))
		Nossonum := nossonum+dig237  
	ENDIF
			
	// Calculo do codigo de barras + digito
	// --------------------------------------------------------
	// 	01-03  03  BANCO ("237") 	
	// 	04-04  01  MOEDA ("9"=real,"0"=outras)
	// 	05-05  01  DIGITO VERIFICADOR (DAC)
	// 	06-09  04  FATORVEN
	// 	10-17  08  SALDO
	// 	18-19  02  SALDO (centavos)
	//    20-44  25  LIVRE (sistema BDL)
	// 	20-23  04  AGENCIA SEM DIGITO VERIFICADOR
	//	   24-25 02  CARTEIRA
	// 	26-36 11  NOSSONUM SEM N⁄MERO DE CONTROLE
	// 	37-43 07  CONTA SEM DIGITO VERIFICADOR
	//   44-44 01  "0"

	cLinha	:= ""	
	strmult := "4329876543298765432987654329876543298765432"
//	livre   := subs(SEE->EE_FAXINI,1,4)+SUBS(alltrim(cCartei),1,2)+subs((nossonum),1,11)+SUBS(cContaSEE,1,7)+"0"
	/*
	CAMPO LIVRE
	20 a 23 4 AgÍncia Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	24 a 25 2 Carteira
	26 a 36 11 N˙mero do Nosso N˙mero(Sem o digito verificador)
	37 a 43 7 Conta do Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	44 a 44 1 Zero
	*/
	livre   := strzero(val(substr(sPAR02,1,4)),4)+SUBS(alltrim(cCartei),1,2)+substr((nossonum),1,11)+SUBS(cContaSEE,1,7)+"0"
	sBarra  := alltrim(cBanco)+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+cFatorVen+cValor+livre
	BaseDiv := 0
	For xx := 1 To 43
		BaseDiv := BaseDiv+Val(Subs(sBarra,xx,1))*Val(Subs(strmult,xx,1))
	Next xx
	resto  	  := BaseDiv % 11
	resto  	  := 11 - resto
	resto  	  := STR(IIF(resto>9 .or. resto==0,1,resto),1,0)
	sBarra	  := cBanco+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+resto+cFatorVen+cValor+livre
	cBarraFim := Alltrim(sBarra)

	// Calculo da linha digit†
	sDigi1 := cBanco+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+Subs(livre,1,5)  	// 23712.1510	+X
	sDigi2 := Subs (livre, 6,10)								// 90051.05001	+X
	sDigi3 := Subs (livre,16,10)								// 13008.00040	+X
	sDigi1 := cDigi(sDigi1)
	sDigi2 := cDigi(sDigi2)
	sDigi3 := cDigi(sDigi3)
	sDigi1 := Subs(sDigi1,1,5)+"."+Subs(sDigi1,6,5)+" "
	sDigi2 := Subs(sDigi2,1,5)+"."+Subs(sDigi2,6,6)+" "
	sDigi3 := Subs(sDigi3,1,5)+"."+Subs(sDigi3,6,6)+" "
	sDigit := sDigi1+sDigi2+sDigi3+resto+" "+cFatorVen+cValor		

	// Linha Digit·vel
	aBancos[nPOS,7] := sDigit
	// Nosso N˙mero  
	aBancos[nPOS,8] := cCartei+" / "+SUBS(nossonum,1,11)+"-"+SUBS(nossonum,12,1)
	// CÛdigo de Barras
	aBancos[nPOS,9] := cBarraFim

ELSEIF cBanco=="254"

	cValor  := StrZero(100*nSaldo,10)
	cCartei	:= "19"
	
	// Calculo do digito verificador do Nosso Numero
    dig237  := ""
    resto	:= 0
    strmult := "2765432765432"		
	BaseDiv := 0 
	IF LEN(ALLTRIM(NOSSONUM)) <= 11
	    _cCarNum := alltrim(cCartei)+subs(nossonum,1,11)
		For xx := 1 To 13
			BaseDiv := BaseDiv+Val(Subs(_cCarNum,xx,1))*VAL(Subs(strmult,xx,1))
		Next xx
		resto	:= BaseDiv % 11
		resto 	:= 11 - resto
		dig237  := IIF(resto==10,"P",IIF(resto==11,"0",ALLTRIM(STR(resto)))) //BRADESCO
		Nossonum	:= nossonum+dig237   
	ENDIF
			
	// Calculo do codigo de barras + digito
	// --------------------------------------------------------
	// 	01-03  03  BANCO ("237") 	
	// 	04-04  01  MOEDA ("9"=real,"0"=outras)
	// 	05-05  01  DIGITO VERIFICADOR (DAC)
	// 	06-09  04  FATORVEN
	// 	10-17  08  SALDO
	// 	18-19  02  SALDO (centavos)
	//    20-44  25  LIVRE (sistema BDL)
	// 	20-23  04  AGENCIA SEM DIGITO VERIFICADOR
	//	   24-25 02  CARTEIRA
	// 	26-36 11  NOSSONUM SEM N⁄MERO DE CONTROLE
	// 	37-43 07  CONTA SEM DIGITO VERIFICADOR
	//   44-44 01  "0"

	cLinha	:= ""	
	strmult := "4329876543298765432987654329876543298765432"
//	livre   := subs(SEE->EE_FAXINI,1,4)+SUBS(alltrim(cCartei),1,2)+subs((nossonum),1,11)+SUBS(cContaSEE,1,7)+"0"
	/*
	CAMPO LIVRE
	20 a 23 4 AgÍncia Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	24 a 25 2 Carteira
	26 a 36 11 N˙mero do Nosso N˙mero(Sem o digito verificador)
	37 a 43 7 Conta do Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	44 a 44 1 Zero
	*/
	livre   := "0049"+"19"+substr((nossonum),1,11)+"0222400"+"0"
	sBarra  := "237"+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+cFatorVen+cValor+livre
	BaseDiv := 0
	For xx := 1 To 43
		BaseDiv := BaseDiv+Val(Subs(sBarra,xx,1))*Val(Subs(strmult,xx,1))
	Next xx
	resto  	:= BaseDiv % 11
	resto  	:= 11 - resto
	resto  	:= STR(IIF(resto>9 .or. resto==0 .or. resto==1,1,resto),1,0)
	sBarra	:= "237"+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+resto+cFatorVen+cValor+livre
	cBarraFim  	:= Alltrim(sBarra)

	// Calculo da linha digit†
	sDigi1 := "237"+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+Subs(livre,1,5)  	// 23712.1510	+X
	sDigi2 := Subs (livre, 6,10)								// 90051.05001	+X
	sDigi3 := Subs (livre,16,10)								// 13008.00040	+X
	sDigi1 := cDigi(sDigi1)
	sDigi2 := cDigi(sDigi2)
	sDigi3 := cDigi(sDigi3)
	sDigi1 := Subs(sDigi1,1,5)+"."+Subs(sDigi1,6,5)+" "
	sDigi2 := Subs(sDigi2,1,5)+"."+Subs(sDigi2,6,6)+" "
	sDigi3 := Subs(sDigi3,1,5)+"."+Subs(sDigi3,6,6)+" "
	sDigit := sDigi1+sDigi2+sDigi3+resto+" "+cFatorVen+cValor		

	// Linha Digit·vel
	aBancos[nPOS,7] := sDigit
	// Nosso N˙mero  
	aBancos[nPOS,8] := cCartei+" / "+SUBS(nossonum,1,11)+"-"+SUBS(nossonum,12,1)
	// CÛdigo de Barras
	aBancos[nPOS,9] := cBarraFim

ELSEIF cBanco=="422"

	cValor  := StrZero(100*nSaldo,10)
	cCartei	:= SUBS(aBancos[nPOS,5],1,2)
	
	// Calculo do digito verificador do Nosso Numero
    dig422  := 0
    strmult := "98765432"		
	BaseDiv := 0
    _cCarNum := subs(nossonum,1,8)
	For xx := 1 To 8
		BaseDiv := BaseDiv+Val(Subs(_cCarNum,xx,1))*VAL(Subs(strmult,xx,1))
	Next xx
	dig422  := BaseDiv % 11
	if dig422==0
		nossonum :=nossonum+"1"		    
	elseif dig422==1                    
		nossonum :=nossonum+"0"		    	
	else
		dig422	 := 11-dig422
		nossonum := nossonum +alltrim(str(dig422))		    
	Endif		 			
			
	// Calculo do codigo de barras + digito
	// --------------------------------------------------------
	// 	01-03  03  BANCO ("237")
	// 	04-04  01  MOEDA ("9"=real,"0"=outras)
	// 	05-05  01  DIGITO VERIFICADOR (DAC)
	// 	06-09  04  FATORVEN
	// 	10-17  08  SALDO
	// 	18-19  02  SALDO (centavos)
	//   20-44  25  LIVRE (sistema BDL)
	// 	20-23  04  AGENCIA SEM DIGITO VERIFICADOR
	//	24-25 02  CARTEIRA
	// 	26-36 11  NOSSONUM SEM N⁄MERO DE CONTROLE
	// 	37-43 07  CONTA SEM DIGITO VERIFICADOR
	//  44-44 01  "0"

	cLinha	:= ""	
	strmult := "4329876543298765432987654329876543298765432"
//	livre   := subs(SEE->EE_FAXINI,1,4)+SUBS(alltrim(cCartei),1,2)+subs((nossonum),1,11)+SUBS(cContaSEE,1,7)+"0"
	/*
	CAMPO LIVRE
	20 a 23 4 AgÍncia Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	24 a 25 2 Carteira
	26 a 36 11 N˙mero do Nosso N˙mero(Sem o digito verificador)
	37 a 43 7 Conta do Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	44 a 44 1 Zero
	*/
	livre   := "7"+strzero(val(substr(sPAR02,1,5)),5)+strzero(val(substr(sPAR03,1,8)),9)+substr((nossonum),1,9)+"2"
	sBarra  := alltrim(cBanco)+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+cFatorVen+cValor+livre
	BaseDiv := 0
	For xx := 1 To 43
		BaseDiv := BaseDiv+Val(Subs(sBarra,xx,1))*Val(Subs(strmult,xx,1))
	Next xx
   
		resto  	  := BaseDiv % 11
	resto  	  := 11 - resto
	resto  	  := STR(IIF(resto>9 .or. resto==0,1,resto),1,0)
	sBarra 	  := cBanco+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+resto+cFatorVen+cValor+livre
	cBarraFim := Alltrim(sBarra)     
	
	// Calculo da linha digit†
	sDigi1 := cBanco+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+Subs(livre,1,5)  	// 23712.1510	+X
	sDigi2 := Subs (livre, 6,10)								                // 90051.05001	+X
	sDigi3 := Subs (livre,16,10)								                // 13008.00040	+X
	sDigi1 := cDigi(sDigi1)
	sDigi2 := cDigi(sDigi2)
	sDigi3 := cDigi(sDigi3)
	sDigi1 := Subs(sDigi1,1,5)+"."+Subs(sDigi1,6,5)+" "
	sDigi2 := Subs(sDigi2,1,5)+"."+Subs(sDigi2,6,6)+" "
	sDigi3 := Subs(sDigi3,1,5)+"."+Subs(sDigi3,6,6)+" "
	sDigit := sDigi1+sDigi2+sDigi3+resto+" "+cFatorVen+cValor		

	// Linha Digit·vel
	aBancos[nPOS,7] := sDigit
	// Nosso N˙mero
	aBancos[nPOS,8] := SUBS(nossonum,1,8)+"-"+SUBS(nossonum,9,1)
	// CÛdigo de Barras
	aBancos[nPOS,9] := cBarraFim

ELSEIF cBanco=="033"

	cValor  := StrZero(100*nSaldo,10)
	cCartei	:= "101"
	
	// Calculo do digito verificador do Nosso Numero
    dig422  := 0
    strmult := "8765432"		
	BaseDiv := 0 
	
	IF LEN(ALLTRIM(NOSSONUM)) <= 7
	    _cCarNum := subs(nossonum,1,7)
		For xx := 7 To 1 Step -1
			BaseDiv := BaseDiv+Val(Subs(_cCarNum,xx,1))*VAL(Subs(strmult,xx,1))
		Next xx
		dig422  := BaseDiv % 11
		
		if dig422==10		
			nossonum :=nossonum+"1"		    
		elseif dig422==0 .OR. dig422==1                    
			nossonum :=nossonum+"0"		    	
		else
			dig422	 := 11-dig422 
			nossonum := nossonum +alltrim(str(dig422))		    
		Endif		 		 
	ENDIF	

			
	// Calculo do codigo de barras + digito
	// --------------------------------------------------------
	// 	01-03  03  BANCO ("237")
	// 	04-04  01  MOEDA ("9"=real,"0"=outras)
	// 	05-05  01  DIGITO VERIFICADOR (DAC)
	// 	06-09  04  FATORVEN
	// 	10-17  08  SALDO
	// 	18-19  02  SALDO (centavos)
	//  20-44  25  LIVRE (sistema BDL)
	// 	20-23  04  AGENCIA SEM DIGITO VERIFICADOR
	//	24-25 02   CARTEIRA
	// 	26-36 11   NOSSONUM SEM N⁄MERO DE CONTROLE
	// 	37-43 07   CONTA SEM DIGITO VERIFICADOR
	//  44-44 01  "0"

	cLinha	:= ""	
	strmult := "4329876543298765432987654329876543298765432"
	strmult2:= "212121212121212121212"
	//strmult := "2345678923456789234567892345678923456789234"	
//	livre   := subs(SEE->EE_FAXINI,1,4)+SUBS(alltrim(cCartei),1,2)+subs((nossonum),1,11)+SUBS(cContaSEE,1,7)+"0"
	/*
	CAMPO LIVRE
	20 a 23 4 AgÍncia Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	24 a 25 2 Carteira
	26 a 36 11 N˙mero do Nosso N˙mero(Sem o digito verificador)
	37 a 43 7 Conta do Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	44 a 44 1 Zero
	*/
       
	//LINHA DIGITAVEL
	livre   := "033"+"9"+"9"+"6487"+"017"+strzero(val(nossonum),13)+"0"+"101"+cFatorVen+cValor
	//CODDIGO DE BARRAS
	sBarra  := ALLTRIM(cBanco)+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+cFatorVen+cValor+"9"+"6487017"+"00000"+strzero(val(nossonum),8)+"0"+"101"
	BaseDiv := 0 
	cTamsBarra := LEN(sBarra)
	For xx := 1 To 43 
		BaseDiv := BaseDiv+Val(Subs(sBarra,xx,1))*Val(Subs(strmult,xx,1))
	Next xx
    
    BaseDiv := BaseDiv * 10                                                  
  	restoCodBar	  := BaseDiv % 11
	//IF RESTO == 10 = 1 / RESTO == 0 OU 1 = 0 / SENAO RESTO
	If restoCodBar == 10 .OR. restoCodBar == 0 .OR. restoCodBar == 1
		restoCodBar := "1"	
	ELSE
		restoCodBar := ALLTRIM(STR(restoCodBar))
	ENDIF
	//resto   := STR(IIF(resto>9 .or. resto==0,1,resto),1,0)
	sBarra 	  := cBanco+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+restoCodBar+cFatorVen+cValor+"9"+"6487017"+"00000"+strzero(val(nossonum),8)+"0"+"101"
	cBarraFim := Alltrim(sBarra)
    

	// Calculo da linha digit†                                                                
	//livre   := "0339964870170000000000223010159720000000776"
	sDigi1 := cBanco+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+"9"+Subs(livre,6,4)  	// 03399.6487
	sDigi2 := Subs (livre,10,10)								                    //
	sDigi3 := Subs (livre,20,10)								                // 13008.00040	+X
	sDigi1 := cDigi(sDigi1)
	sDigi2 := cDigi(sDigi2)
	sDigi3 := cDigi(sDigi3)
	sDigi1 := Subs(sDigi1,1,5)+"."+Subs(sDigi1,6,5)+" "
	sDigi2 := Subs(sDigi2,1,5)+"."+Subs(sDigi2,6,6)+" "
	sDigi3 := Subs(sDigi3,1,5)+"."+Subs(sDigi3,6,6)+" "
	sDigit := sDigi1+sDigi2+sDigi3+restoCodBar+" "+cFatorVen+cValor		

	// Linha Digit·vel
	aBancos[nPOS,7] := sDigit
	// Nosso N˙mero
	aBancos[nPOS,8] := SUBS(nossonum,1,7)+"-"+SUBS(nossonum,8,1)
	// CÛdigo de Barras
	aBancos[nPOS,9] := cBarraFim

ELSEIF cBanco=="104"

	cValor  := StrZero(100*nSaldo,10)
	cCartei	:= SUBS(aBancos[nPOS,5],1,2) 
	cCodBen := "4762274"
	cBarraFim := ""
	
	
    dig104  := ""
    dig422  := ""
    dig244  := ""
    resto	:= 0
    strmult := "29876543298765432"		
	BaseDiv := 0
    _cCarNum := "14"+"0000"+subs(nossonum,1,11)   
    
    // Calculo do digito verificador do Nosso Numero
	IF LEN(ALLTRIM(NOSSONUM)) <= 11
		For xx := 17 To 1 Step -1
			BaseDiv := BaseDiv+Val(Subs(_cCarNum,xx,1))*VAL(Subs(strmult,xx,1))
		Next xx
		resto	 := BaseDiv % 11
		dig422 	 := 11 - resto
		dig422   := IIF(dig422>9,"0",ALLTRIM(STR(dig422)))
		nossonum := nossonum+dig422
	ENDIF
			
	// Calculo do codigo de barras + digito
	// --------------------------------------------------------
	// 	01-03  03  BANCO ("104")
	// 	04-04  01  MOEDA ("9"=real,"0"=outras)
	// 	05-05  01  DIGITO VERIFICADOR (DAC)
	// 	06-09  04  FATORVEN
	// 	10-17  08  SALDO
	// 	18-19  02  SALDO (centavos)
	//  20-44  25  LIVRE (sistema BDL)
	// 	20-29  10  NOSSONUM SEM N⁄MERO DE CONTROLE
	//	30-44  15  CODIGO CEDENTE SEM DIGITO VERIFICADOR

	cLinha	:= ""	
	strmult := "4329876543298765432987654329876543298765432" 
	strmult2:= "987654329876543298765432" 

	/*
	CAMPO LIVRE
	20 a 23 4 AgÍncia Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	24 a 25 2 Carteira
	26 a 36 11 N˙mero do Nosso N˙mero(Sem o digito verificador)
	37 a 43 7 Conta do Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	44 a 44 1 Zero
	*/
	                            
	livre   := SUBS(cCodBen,1,6)+SUBS(cCodBen,7,1)+"000"+"1"+"0"+SUBS(NOSSONUM,1,2)+"4"+SUBS(NOSSONUM,3,10) 
	sBarra  :=ALLTRIM(cBanco)+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+ALLTRIM(cFatorVen)+ALLTRIM(cValor)
	BaseDiv := 0                                                        
	
	For xx := 25 To 1 Step -1 
		BaseDiv := BaseDiv+Val(Subs(livre,xx,1))*Val(Subs(strmult2,xx,1))
	Next xx
	resto  := BaseDiv % 11
	dig244 := 11 - resto
	dig244 := IIF(dig244>9,"0",ALLTRIM(STR(dig244))) 
	livre  := livre+dig244
		
	BaseDiv := 0
	For xx := 43 To 1 Step -1 
		BaseDiv := BaseDiv+Val(Subs(sBarra,xx,1))*Val(Subs(strmult,xx,1))
	Next xx
	resto  		:= BaseDiv % 11
	dig104   	:= 11 - resto
	dig104  	:= IIF(dig104>9 .OR. dig104==0,"1",ALLTRIM(STR(dig104)))
	sBarra		:= cBanco+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+dig104+cFatorVen+cValor+livre
	cBarraFim  	:= Alltrim(sBarra)

	// Calculo da linha digit†
	sDigi1 := cBanco+IIF(STR(SE1->E1_MOEDA,1,0)=="1","9","0")+Subs(livre,1,5)  	// 10412.1510	+X
	sDigi2 := Subs (livre, 6,10)								// 90051.05001	+X
	sDigi3 := Subs (livre,16,10)								// 13008.00040	+X
	sDigi1 := cDigi(sDigi1)
	sDigi2 := cDigi(sDigi2)
	sDigi3 := cDigi(sDigi3)
	sDigi1 := Subs(sDigi1,1,5)+"."+Subs(sDigi1,6,5)+" "
	sDigi2 := Subs(sDigi2,1,5)+"."+Subs(sDigi2,6,6)+" "
	sDigi3 := Subs(sDigi3,1,5)+"."+Subs(sDigi3,6,6)+" "
	sDigit := sDigi1+sDigi2+sDigi3+dig104+" "+cFatorVen+cValor		

	// Linha Digit·vel
	aBancos[nPOS,7] := sDigit
	// Nosso N˙mero
	aBancos[nPOS,8] := "14"+"0000"+SUBS(nossonum,1,11)+"-"+SUBS(nossonum,12,1)
	// CÛdigo de Barras
	aBancos[nPOS,9] := cBarraFim 
	

ELSEIF cBanco=="341" .AND. ALLTRIM(cAgencia)=="01248" .AND. ALLTRIM(cConta)=="0002707809"       // banco itau votorantim
	cValor  := StrZero(100*nSaldo,10)
	cCartei	:= "109"
	
	// Calculo do digito verificador do Nosso Numero
    dig341  := ""
    resto	:= 0
    strmult := "12121212121212121212"		
	BaseDiv := 0
	_cCarNum := "12483027078109"+nossonum
    // _cCarNum := "736512280109"+nossonum (8 digitos) 
	For xx := 1 To 20
	    BaseDig := Val(Subs(_cCarNum,xx,1))*VAL(Subs(strmult,xx,1))
	    BaseLen := AllTrim(Str(BaseDig))
	    If Len(BaseLen) == 2
	       BaseLen := Str(Val(Subs(BaseLen,1,1))+VAL(Subs(BaseLen,2,1)),1)
	    Endif
		BaseDiv := BaseDiv+Val(BaseLen)
	Next xx
	
	//MsgBox("E1_NUM+E1_PARCELA "+SE1->E1_NUM+"/"+SE1->E1_PARCELA)
	//MsgBox("strmult "+strmult+" _cCarNum "+_cCarNum)
	//MsgBox("BaseDiv "+Str(BaseDiv))   
	resto	:= BaseDiv % 10
   	dig341 	:= 10 - resto    
	dig341  := IIF(dig341==10,0,dig341)
	nossonum := nossonum+Str(dig341,1)  
	
    //MsgBox("resto "+str(resto)+ " dig341 "+str(dig341))
	//MsgBox("nossonum "+nossonum)
			
	// Calculo do codigo de barras + digito
	// --------------------------------------------------------
	// 	01-03  03  BANCO ("104")
	// 	04-04  01  MOEDA ("9"=real,"0"=outras)
	// 	05-05  01  DIGITO VERIFICADOR (DAC)
	// 	06-09  04  FATORVEN
	// 	10-17  08  SALDO
	// 	18-19  02  SALDO (centavos)
	//  20-44  25  LIVRE (sistema BDL)
	// 	 20-29  10  NOSSONUM SEM N⁄MERO DE CONTROLE
	//	 30-44  15  CODIGO CEDENTE SEM DIGITO VERIFICADOR

	cLinha	:= ""	
	strmult := "4329876543298765432987654329876543298765432"
//	livre   := subs(SEE->EE_FAXINI,1,4)+SUBS(alltrim(cCartei),1,2)+subs((nossonum),1,11)+SUBS(cContaSEE,1,7)+"0"
	/*
	CAMPO LIVRE
	20 a 23 4 AgÍncia Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	24 a 25 2 Carteira
	26 a 36 11 N˙mero do Nosso N˙mero(Sem o digito verificador)
	37 a 43 7 Conta do Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	44 a 44 1 Zero
	*/
	livre   := "109"+nossonum+Substr(cAgencia,2,4)+Substr(cConta,3,6)+"000"    //25
	
	sBarra  := "341"+"9"+cFatorVen+cValor+livre    // 18+25
	                             
	BaseDiv := 0
	For xx := 1 To 43
		BaseDiv := BaseDiv+Val(Subs(sBarra,xx,1))*Val(Subs(strmult,xx,1))
	Next xx
	resto  	:= BaseDiv % 11
	dig104  := 11 - resto
	dig104  := STR(IIF(dig104>9 .or. dig104==0,1,dig104),1,0)
	sBarra	:= cBanco+"9"+dig104+cFatorVen+cValor+livre
	cBarraFim  	:= Alltrim(sBarra)
             
 	//MsgBox("dig104 "+dig104)
 	//MsgBox("cBarraFim "+cBarraFim)
 	
	// Calculo da linha digit†
	sDigi1 := cBanco+"9"+Subs(livre,1,5)  						// 10412.1510	+X
	sDigi2 := Substr(livre, 6,10)								// 90051.05001	+X
	sDigi3 := Substr(livre,16,10)								// 13008.00040	+X
	sDigi1 := cDigi(sDigi1)
	sDigi2 := cDigi(sDigi2)
	sDigi3 := cDigi(sDigi3)
	sDigi1 := Substr(sDigi1,1,5)+"."+Substr(sDigi1,6,5)+" "
	sDigi2 := Substr(sDigi2,1,5)+"."+Substr(sDigi2,6,6)+" "
	sDigi3 := Substr(sDigi3,1,5)+"."+Substr(sDigi3,6,6)+" "
	sDigit := sDigi1+sDigi2+sDigi3+dig104+" "+cFatorVen+cValor		
       
 	//MsgBox("sDigit "+sDigit)

	// Linha Digit·vel
	aBancos[nPOS,7] := sDigit
	// Nosso N˙mero
	aBancos[nPOS,8] := "109/"+SUBS(nossonum,1,8)+"-"+SUBS(nossonum,9,1)
	// CÛdigo de Barras
	aBancos[nPOS,9] := cBarraFim     

ELSEIF cBanco=="341" .AND. ALLTRIM(cAgencia)=="07365" .AND. ALLTRIM(cConta)=="0012353309"      // banco itau
     
	cValor  := StrZero(100*nSaldo,10)
	cCartei	:= "109"
	
	// Calculo do digito verificador do Nosso Numero
    dig341  := ""
    resto	:= 0
    strmult := "12121212121212121212"		
	BaseDiv := 0  
	_cCarNum := "7365123533109"+nossonum
    //_cCarNum := "1248027078109"+nossonum             // _cCarNum := "736512280109"+nossonum (8 digitos) 
	For xx := 1 To 20
	    BaseDig := Val(Subs(_cCarNum,xx,1))*VAL(Subs(strmult,xx,1))
	    BaseLen := AllTrim(Str(BaseDig))
	    If Len(BaseLen) == 2
	       BaseLen := Str(Val(Subs(BaseLen,1,1))+VAL(Subs(BaseLen,2,1)),1)
	    Endif
		BaseDiv := BaseDiv+Val(BaseLen)
	Next xx
	
	//MsgBox("E1_NUM+E1_PARCELA "+SE1->E1_NUM+"/"+SE1->E1_PARCELA)
	//MsgBox("strmult "+strmult+" _cCarNum "+_cCarNum)
	//MsgBox("BaseDiv "+Str(BaseDiv))
	
	resto	:= BaseDiv % 10
	dig341 	:= 10 - resto    
	dig341  := IIF(dig341==10,0,dig341)
	nossonum := nossonum+Str(dig341,1)
	
	//MsgBox("resto "+str(resto)+ " dig341 "+str(dig341))
	//MsgBox("nossonum "+nossonum)
			
	// Calculo do codigo de barras + digito
	// --------------------------------------------------------
	// 	01-03  03  BANCO ("104")
	// 	04-04  01  MOEDA ("9"=real,"0"=outras)
	// 	05-05  01  DIGITO VERIFICADOR (DAC)
	// 	06-09  04  FATORVEN
	// 	10-17  08  SALDO
	// 	18-19  02  SALDO (centavos)
	//  20-44  25  LIVRE (sistema BDL)
	// 	 20-29  10  NOSSONUM SEM N⁄MERO DE CONTROLE
	//	 30-44  15  CODIGO CEDENTE SEM DIGITO VERIFICADOR

	cLinha	:= ""	
	strmult := "4329876543298765432987654329876543298765432"
//	livre   := subs(SEE->EE_FAXINI,1,4)+SUBS(alltrim(cCartei),1,2)+subs((nossonum),1,11)+SUBS(cContaSEE,1,7)+"0"
	/*
	CAMPO LIVRE
	20 a 23 4 AgÍncia Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	24 a 25 2 Carteira
	26 a 36 11 N˙mero do Nosso N˙mero(Sem o digito verificador)
	37 a 43 7 Conta do Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	44 a 44 1 Zero
	*/
	livre   := "109"+nossonum+Substr(cAgencia,2,4)+Substr(cConta,3,6)+"000"    //25
	
	sBarra  := "341"+"9"+cFatorVen+cValor+livre    // 18+25
	                             
	BaseDiv := 0
	For xx := 1 To 43
		BaseDiv := BaseDiv+Val(Subs(sBarra,xx,1))*Val(Subs(strmult,xx,1))
	Next xx
	resto  	:= BaseDiv % 11
	dig104  := 11 - resto
	dig104  := STR(IIF(dig104>9 .or. dig104==0,1,dig104),1,0)
	sBarra	:= cBanco+"9"+dig104+cFatorVen+cValor+livre
	cBarraFim  	:= Alltrim(sBarra)
             
 	//MsgBox("dig104 "+dig104)
 	//MsgBox("cBarraFim "+cBarraFim)
 	
	// Calculo da linha digit†
	sDigi1 := cBanco+"9"+Subs(livre,1,5)  						// 10412.1510	+X
	sDigi2 := Substr(livre, 6,10)								// 90051.05001	+X
	sDigi3 := Substr(livre,16,10)								// 13008.00040	+X
	sDigi1 := cDigi(sDigi1)
	sDigi2 := cDigi(sDigi2)
	sDigi3 := cDigi(sDigi3)
	sDigi1 := Substr(sDigi1,1,5)+"."+Substr(sDigi1,6,5)+" "
	sDigi2 := Substr(sDigi2,1,5)+"."+Substr(sDigi2,6,6)+" "
	sDigi3 := Substr(sDigi3,1,5)+"."+Substr(sDigi3,6,6)+" "
	sDigit := sDigi1+sDigi2+sDigi3+dig104+" "+cFatorVen+cValor		
       
 	//MsgBox("sDigit "+sDigit)

	// Linha Digit·vel
	aBancos[nPOS,7] := sDigit
	// Nosso N˙mero
	aBancos[nPOS,8] := "109/"+SUBS(nossonum,1,8)+"-"+SUBS(nossonum,9,1)
	// CÛdigo de Barras
	aBancos[nPOS,9] := cBarraFim	

ELSEIF cBanco=="341" .AND. ALLTRIM(cAgencia)=="07365" .AND. ALLTRIM(cConta)=="0012280809"      // banco itau
     
	cValor  := StrZero(100*nSaldo,10)
	cCartei	:= "109"
	
	// Calculo do digito verificador do Nosso Numero
    dig341  := ""
    resto	:= 0
    strmult := "12121212121212121212"		
	BaseDiv := 0  
    _cCarNum := "7365122808109"+nossonum

	For xx := 1 To 20
	    BaseDig := Val(Subs(_cCarNum,xx,1))*VAL(Subs(strmult,xx,1))
	    BaseLen := AllTrim(Str(BaseDig))
	    If Len(BaseLen) == 2
	       BaseLen := Str(Val(Subs(BaseLen,1,1))+VAL(Subs(BaseLen,2,1)),1)
	    Endif
		BaseDiv := BaseDiv+Val(BaseLen)
	Next xx
	
	//MsgBox("E1_NUM+E1_PARCELA "+SE1->E1_NUM+"/"+SE1->E1_PARCELA)
	//MsgBox("strmult "+strmult+" _cCarNum "+_cCarNum)
	//MsgBox("BaseDiv "+Str(BaseDiv))
	
	resto	:= BaseDiv % 10
	dig341 	:= 10 - resto    
	dig341  := IIF(dig341==10,0,dig341)
	nossonum := nossonum+Str(dig341,1)
	
	//MsgBox("resto "+str(resto)+ " dig341 "+str(dig341))
	//MsgBox("nossonum "+nossonum)
			
	// Calculo do codigo de barras + digito
	// --------------------------------------------------------
	// 	01-03  03  BANCO ("104")
	// 	04-04  01  MOEDA ("9"=real,"0"=outras)
	// 	05-05  01  DIGITO VERIFICADOR (DAC)
	// 	06-09  04  FATORVEN
	// 	10-17  08  SALDO
	// 	18-19  02  SALDO (centavos)
	//  20-44  25  LIVRE (sistema BDL)
	// 	 20-29  10  NOSSONUM SEM N⁄MERO DE CONTROLE
	//	 30-44  15  CODIGO CEDENTE SEM DIGITO VERIFICADOR

	cLinha	:= ""	
	strmult := "4329876543298765432987654329876543298765432"
//	livre   := subs(SEE->EE_FAXINI,1,4)+SUBS(alltrim(cCartei),1,2)+subs((nossonum),1,11)+SUBS(cContaSEE,1,7)+"0"
	/*
	CAMPO LIVRE
	20 a 23 4 AgÍncia Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	24 a 25 2 Carteira
	26 a 36 11 N˙mero do Nosso N˙mero(Sem o digito verificador)
	37 a 43 7 Conta do Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	44 a 44 1 Zero
	*/
	livre   := "109"+nossonum+Substr(cAgencia,2,4)+Substr(cConta,3,6)+"000"    //25
	
	sBarra  := "341"+"9"+cFatorVen+cValor+livre    // 18+25
	                             
	BaseDiv := 0
	For xx := 1 To 43
		BaseDiv := BaseDiv+Val(Subs(sBarra,xx,1))*Val(Subs(strmult,xx,1))
	Next xx
	resto  	:= BaseDiv % 11
	dig104  := 11 - resto
	dig104  := STR(IIF(dig104>9 .or. dig104==0,1,dig104),1,0)
	sBarra	:= cBanco+"9"+dig104+cFatorVen+cValor+livre
	cBarraFim  	:= Alltrim(sBarra)
             
 	//MsgBox("dig104 "+dig104)
 	//MsgBox("cBarraFim "+cBarraFim)
 	
	// Calculo da linha digit†
	sDigi1 := cBanco+"9"+Subs(livre,1,5)  						// 10412.1510	+ X
	sDigi2 := Substr(livre, 6,10)								// 90051.05001	+X
	sDigi3 := Substr(livre,16,10)								// 13008.00040	+X
	sDigi1 := cDigi(sDigi1)
	sDigi2 := cDigi(sDigi2)
	sDigi3 := cDigi(sDigi3)
	sDigi1 := Substr(sDigi1,1,5)+"."+Substr(sDigi1,6,5)+" "
	sDigi2 := Substr(sDigi2,1,5)+"."+Substr(sDigi2,6,6)+" "
	sDigi3 := Substr(sDigi3,1,5)+"."+Substr(sDigi3,6,6)+" "
	sDigit := sDigi1+sDigi2+sDigi3+dig104+" "+cFatorVen+cValor		
       
 	//MsgBox("sDigit "+sDigit)

	// Linha Digit·vel
	aBancos[nPOS,7] := sDigit
	// Nosso N˙mero
	aBancos[nPOS,8] := "109/"+SUBS(nossonum,1,8)+"-"+SUBS(nossonum,9,1)
	// CÛdigo de Barras
	aBancos[nPOS,9] := cBarraFim	

ELSEIF cBanco=="341" .AND. ALLTRIM(cAgencia)=="7365" .AND. ALLTRIM(cConta)=="122808"      // banco itau
     
	cValor  := StrZero(100 * nSaldo,10)
	cCartei	:= "109"
	
	// Calculo do digito verificador do Nosso Numero
    dig341  := ""
    resto	 := 0
    strmult := "12121212121212121212"		
	BaseDiv := 0  
    _cCarNum := ALLTRIM(cAgencia) + ALLTRIM(substr(cConta,1,5)) + cCartei + nossonum
	//_cCarNum := "00571234511012345678"
	For xx := 1 To 20
	    BaseDig := Val(Substr(_cCarNum,xx,1)) * VAL(Substr(strmult,xx,1))
	    BaseLen := AllTrim(Str(BaseDig))
	    If Len(BaseLen) == 2
	       BaseLen := Str(Val(Subs(BaseLen,1,1)) + VAL(Subs(BaseLen,2,1)),1)
	    Endif
		BaseDiv := BaseDiv + Val(BaseLen)
	Next xx
	
	resto	:= BaseDiv % 10
	dig341 	:= 10 - resto    
	dig341  := IIF(dig341 == 10 , 0 , dig341)
	//nossonum := nossonum + Str(dig341,1)
	_cResto :=  + Str(dig341,1)
	
	if len(nossonum) < 9
		nossoNum := nossoNum + _cResto
	endif
	
	//MsgBox("resto "+str(resto)+ " dig341 "+str(dig341))
	//MsgBox("nossonum "+nossonum)
			
	// Calculo do codigo de barras + digito
	// --------------------------------------------------------
	// 	01-03  03  BANCO ("104")
	// 	04-04  01  MOEDA ("9"=real,"0"=outras)
	// 	05-05  01  DIGITO VERIFICADOR (DAC)
	// 	06-09  04  FATORVEN
	// 	10-17  08  SALDO
	// 	18-19  02  SALDO (centavos)
	//  20-44  25  LIVRE (sistema BDL)
	// 	 20-29  10  NOSSONUM SEM N⁄MERO DE CONTROLE
	//	 30-44  15  CODIGO CEDENTE SEM DIGITO VERIFICADOR

	cLinha	:= ""	
	strmult := "4329876543298765432987654329876543298765432"
//	livre   := subs(SEE->EE_FAXINI,1,4)+SUBS(alltrim(cCartei),1,2)+subs((nossonum),1,11)+SUBS(cContaSEE,1,7)+"0"
	/*
	CAMPO LIVRE
	20 a 22 03 9(03) Carteira
	23 a 30 08 9(08) Nosso N˙mero
	31 a 31 01 9(01) DAC [AgÍncia /Conta/Carteira/Nosso N˙mero] (Anexo 4)
	32 a 35 04 9(04) N.∫ da AgÍncia BENEFICI¡RIO
	36 a 40 05 9(05) N.∫ da Conta Corrente
	41 a 41 01 9(01) DAC [AgÍncia/Conta Corrente] (Anexo 3)
	42 a 44 03 9(03) Zeros
	*/
	livre   := "109" + nossonum  + Substr(alltrim(cAgencia),1,4) + Substr(alltrim(cConta),1,6) + "000"    //25
	
	sBarra  := "341"+"9" + cFatorVen + cValor + livre    // 18+25
	                             
	BaseDiv := 0
	For xx := 1 To 43
		BaseDiv := BaseDiv+Val(Subs(sBarra,xx,1))*Val(Subs(strmult,xx,1))
	Next xx
	resto  	:= BaseDiv % 11
	dig104  := 11 - resto
	dig104  := STR(IIF(dig104 > 9 .or. dig104 == 0 .or. dig104 == 1, 1, dig104),1,0)
	sBarra	:= cBanco + "9" + dig104 + cFatorVen + cValor + livre
	cBarraFim  	:= Alltrim(sBarra)
     
     //MsgBox("dig104 "+dig104)
 	//MsgBox("cBarraFim "+cBarraFim)
 	
	// Calculo da linha digit†
	sDigi1 := cBanco+"9"+Subs(livre,1,5)  						// 10412.1510	+X
	sDigi2 := Substr(livre, 6,10)								// 90051.05001	+X
	sDigi3 := Substr(livre,16,10)								// 13008.00040	+X
	sDigi1 := cDigi(sDigi1)
	sDigi2 := cDigi(sDigi2)
	sDigi3 := cDigi(sDigi3)
	sDigi1 := Substr(sDigi1,1,5)+"."+Substr(sDigi1,6,5)+" "
	sDigi2 := Substr(sDigi2,1,5)+"."+Substr(sDigi2,6,6)+" "
	sDigi3 := Substr(sDigi3,1,5)+"."+Substr(sDigi3,6,6)+" "
	sDigit := sDigi1+sDigi2+sDigi3+dig104+" "+cFatorVen+cValor		
       
 	//MsgBox("sDigit "+sDigit)

	// Linha Digit·vel
	aBancos[nPOS,7] := sDigit
	// Nosso N˙mero
	aBancos[nPOS,8] := "109/"+SUBS(nossonum,1,8)+"-"+SUBS(nossonum,9,1)
	// CÛdigo de Barras
	aBancos[nPOS,9] := cBarraFim	

//######## FIM  BANCO ITAU (341) AG.: 7355 / CC.: 15046-0 ########//	
ELSEIF cBanco=="341" .AND. ALLTRIM(cAgencia)=="07365"  .AND. ALLTRIM(cConta)=="0015046009"     
     
	cValor  := StrZero(100*nSaldo,10)
	cCartei	:= "109"
	
	// Calculo do digito verificador do Nosso Numero
    dig341  := ""
    resto	:= 0
    strmult := "12121212121212121212"		
	BaseDiv := 0  
    _cCarNum := "736515046109"+nossonum //(8 digitos) 

	IF LEN(ALLTRIM(NOSSONUM)) <= 8
	   For xx := 1 To 20
		    BaseDig := Val(Subs(_cCarNum,xx,1))*VAL(Subs(strmult,xx,1))
		    BaseLen := AllTrim(Str(BaseDig))
		    If Len(BaseLen) == 2
		       BaseLen := Str(Val(Subs(BaseLen,1,1))+VAL(Subs(BaseLen,2,1)),1)
	    	Endif
	    	BaseDiv := BaseDiv+Val(BaseLen)
		Next xx		
	ENDIF
	
	resto	:= BaseDiv % 10
	dig341 	:= 10 - resto    
	dig341  := IIF(dig341==10,0,dig341)
	nossonum := nossonum+Str(dig341,1)
			
	// Calculo do codigo de barras + digito
	// --------------------------------------------------------
	// 	01-03  03  BANCO ("341")
	// 	04-04  01  MOEDA ("9"=real,"0"=outras)
	// 	05-05  01  DIGITO VERIFICADOR (DAC) DO COD. DE BARRAS
	// 	06-09  04  FATORVEN
	// 	10-19  08  SALDO
   
	//CAMPO LIVRE
	//  20-22  03  CARTEIRA
	//  23-30  08  NOSSO NUMERO (SEM DAC)
	//  31-31  01  DAC [AGENCIA/CONTA/CARTEIRA/NOSSO NUMERO
	//  32-35  04  N∫ AGENCIA CEDENTE
	//  36-40  05  N∫ CONTA CORRENTE
	//  41-41  01  DAC [AGENCIA/CONTA CORRENTE]
	//	42-44  03  ZEROS

	cLinha	:= ""	
	strmult := "4329876543298765432987654329876543298765432"

	livre   := "109"+SUBSTR(NOSSONUM,1,9)+SUBSTR(cAgencia,2,4)+SUBSTR(cConta,3,6)+"000"    //25
	
	sBarra  := "341"+"9"+cFatorVen+cValor+livre    // 18+25
	                             
	BaseDiv := 0
	For xx := 1 To 43
		BaseDiv := BaseDiv+Val(Subs(sBarra,xx,1))*Val(Subs(strmult,xx,1))
	Next xx
	resto  	:= BaseDiv % 11
	dig104  := 11 - resto
	dig104  := STR(IIF(dig104>9 .or. dig104==0,1,dig104),1,0)
	sBarra	:= cBanco+"9"+dig104+cFatorVen+cValor+livre
	cBarraFim  	:= Alltrim(sBarra)
             
 	//MsgBox("dig104 "+dig104)
 	//MsgBox("cBarraFim "+cBarraFim)
 	
	// Calculo da linha digit†
	sDigi1 := cBanco+"9"+Subs(livre,1,5)  						// 10412.1510	+X
	sDigi2 := Substr(livre, 6,10)								// 90051.05001	+X
	sDigi3 := Substr(livre,16,10)								// 13008.00040	+X
	sDigi1 := cDigi(sDigi1)
	sDigi2 := cDigi(sDigi2)
	sDigi3 := cDigi(sDigi3)
	sDigi1 := Substr(sDigi1,1,5)+"."+Substr(sDigi1,6,5)+" "
	sDigi2 := Substr(sDigi2,1,5)+"."+Substr(sDigi2,6,6)+" "
	sDigi3 := Substr(sDigi3,1,5)+"."+Substr(sDigi3,6,6)+" "
	sDigit := sDigi1+sDigi2+sDigi3+dig104+" "+cFatorVen+cValor		
       
 	//MsgBox("sDigit "+sDigit)

	// Linha Digit·vel
	aBancos[nPOS,7] := sDigit
	// Nosso N˙mero
	aBancos[nPOS,8] := "109/"+SUBS(nossonum,1,8)+"-"+SUBS(nossonum,9,1)
	// CÛdigo de Barras
	aBancos[nPOS,9] := cBarraFim		
//######## FIM  BANCO ITAU (341) AG.: 7355 / CC.: 15046-0 ########//	

//############# COME«O CITIBANK #############// 	
ELSEIF cBanco=="745" .AND. ALLTRIM(cAgencia)=="00125" .AND. ALLTRIM(cConta)=="3499590014"       // BANCO CITIBANK
     
	cValor  := StrZero(100*nSaldo,10)
	cCartei	:= "314"
	                        	
	// Calculo do digito verificador do Nosso Numero
    dig341  := ""
    resto	:= 0
    strmult := "43298765432" //"12121212121212121212"		
	BaseDiv := 0 
	_cCarNum := nossonum    // (11 digitos)
	For xx := 1 To 11
	    BaseDig := Val(Subs(_cCarNum,xx,1))*VAL(Subs(strmult,xx,1))
		BaseDiv := BaseDiv+BaseDig
	Next xx
	
	//MsgBox("E1_NUM+E1_PARCELA "+SE1->E1_NUM+"/"+SE1->E1_PARCELA)
	//MsgBox("strmult "+strmult+" _cCarNum "+_cCarNum)
	//MsgBox("BaseDiv "+Str(BaseDiv))
	
	resto	:= BaseDiv % 11
    If resto == 0 .Or. resto == 1
		dig341 	:= 0    
    Else
		dig341 	:= 11 - resto    
	Endif	
	nossonum := nossonum+Str(dig341,1)
	
	// Calculo do codigo de barras + digito
	// --------------------------------------------------------
	// 	01-03  03  BANCO ("745")
	// 	04-04  01  MOEDA ("9"=real,"0"=outras)
	// 	05-05  01  DIGITO VERIFICADOR (DAC)
	// 	06-09  04  FATORVEN
	// 	10-17  08  SALDO
	// 	18-19  02  SALDO (centavos)
	//  20-44  25  LIVRE (sistema BDL)
	// 	 20-29  10  NOSSONUM SEM N⁄MERO DE CONTROLE
	//	 30-44  15  CODIGO CEDENTE SEM DIGITO VERIFICADOR

	cLinha	:= ""	
	strmult := "4329876543298765432987654329876543298765432"
//	livre   := subs(SEE->EE_FAXINI,1,4)+SUBS(alltrim(cCartei),1,2)+subs((nossonum),1,11)+SUBS(cContaSEE,1,7)+"0"
	/*
	CAMPO LIVRE
	20 a 23 4 AgÍncia Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	24 a 25 2 Carteira
	26 a 36 11 N˙mero do Nosso N˙mero(Sem o digito verificador)
	37 a 43 7 Conta do Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	44 a 44 1 Zero
	*/
	livre   := "3314" + "093545028" + substr(nossonum,1,12)    //25
	
	sBarra  := "745"+"9"+cFatorVen+cValor+livre    // 18+25
	                             
	BaseDiv := 0
	For xx := 1 To 43
		BaseDiv := BaseDiv+Val(Subs(sBarra,xx,1))*Val(Subs(strmult,xx,1))
	Next xx
	resto  	:= BaseDiv % 11
	dig104  := 11 - resto
	dig104  := STR(IIF(dig104>9 .or. dig104==0,1,dig104),1,0)
	sBarra	:= "745"+"9"+dig104+cFatorVen+cValor+livre
	cBarraFim  	:= Alltrim(sBarra)
             
 	//MsgBox("dig104 "+dig104)
 	//MsgBox("cBarraFim "+cBarraFim)
 	
	// Calculo da linha digit†
	sDigi1 := cBanco+"9"+Subs(livre,1,5)  						// 10412.1510	+X
	sDigi2 := Substr(livre, 6,10)								// 90051.05001	+X
	sDigi3 := Substr(livre,16,10)								// 13008.00040	+X
	sDigi1 := cDigi(sDigi1)
	sDigi2 := cDigi(sDigi2)
	sDigi3 := cDigi(sDigi3)
	sDigi1 := Substr(sDigi1,1,5)+"."+Substr(sDigi1,6,5)+" "
	sDigi2 := Substr(sDigi2,1,5)+"."+Substr(sDigi2,6,6)+" "
	sDigi3 := Substr(sDigi3,1,5)+"."+Substr(sDigi3,6,6)+" "
	sDigit := sDigi1+sDigi2+sDigi3+dig104+" "+cFatorVen+cValor		
       
 	//MsgBox("sDigit "+sDigit)

	// Linha Digit·vel
	aBancos[nPOS,7] := sDigit
	// Nosso N˙mero
	aBancos[nPOS,8] := SUBS(nossonum,1,11)+"-"+SUBS(nossonum,12,1)    //"314/"+SUBS(nossonum,1,8)+"-"+SUBS(nossonum,9,1)
	// CÛdigo de Barras
	aBancos[nPOS,9] := cBarraFim  
	
ELSEIF cBanco=="745" .AND. ALLTRIM(cAgencia)=="00125" .AND. ALLTRIM(cConta)=="3499590012"       // BANCO CITIBANK
     
	cValor  := StrZero(100*nSaldo,10)
	cCartei	:= "112"
	                        	
	// Calculo do digito verificador do Nosso Numero
    dig341  := ""
    resto	:= 0
    strmult := "43298765432" //"12121212121212121212"		
	BaseDiv := 0 
	_cCarNum := nossonum    // (11 digitos)
	For xx := 1 To 11
	    BaseDig := Val(Subs(_cCarNum,xx,1))*VAL(Subs(strmult,xx,1))
		BaseDiv := BaseDiv+BaseDig
	Next xx
	
	//MsgBox("E1_NUM+E1_PARCELA "+SE1->E1_NUM+"/"+SE1->E1_PARCELA)
	//MsgBox("strmult "+strmult+" _cCarNum "+_cCarNum)
	//MsgBox("BaseDiv "+Str(BaseDiv))
	
	resto	:= BaseDiv % 11
    If resto == 0 .Or. resto == 1
		dig341 	:= 0    
    Else
		dig341 	:= 11 - resto    
	Endif	
	nossonum := nossonum+Str(dig341,1)
	
	// Calculo do codigo de barras + digito
	// --------------------------------------------------------
	// 	01-03  03  BANCO ("745")
	// 	04-04  01  MOEDA ("9"=real,"0"=outras)
	// 	05-05  01  DIGITO VERIFICADOR (DAC)
	// 	06-09  04  FATORVEN
	// 	10-17  08  SALDO
	// 	18-19  02  SALDO (centavos)
	//  20-44  25  LIVRE (sistema BDL)
	// 	 20-29  10  NOSSONUM SEM N⁄MERO DE CONTROLE
	//	 30-44  15  CODIGO CEDENTE SEM DIGITO VERIFICADOR

	cLinha	:= ""	
	strmult := "4329876543298765432987654329876543298765432"
//	livre   := subs(SEE->EE_FAXINI,1,4)+SUBS(alltrim(cCartei),1,2)+subs((nossonum),1,11)+SUBS(cContaSEE,1,7)+"0"
	/*
	CAMPO LIVRE
	20 a 23 4 AgÍncia Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	24 a 25 2 Carteira
	26 a 36 11 N˙mero do Nosso N˙mero(Sem o digito verificador)
	37 a 43 7 Conta do Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	44 a 44 1 Zero
	*/
	livre   := "3112" + "093545028" + substr(nossonum,1,12)    //25
	
	sBarra  := "745"+"9"+cFatorVen+cValor+livre    // 18+25
	                             
	BaseDiv := 0
	For xx := 1 To 43
		BaseDiv := BaseDiv+Val(Subs(sBarra,xx,1))*Val(Subs(strmult,xx,1))
	Next xx
	resto  	:= BaseDiv % 11
	dig104  := 11 - resto
	dig104  := STR(IIF(dig104>9 .or. dig104==0,1,dig104),1,0)
	sBarra	:= "745"+"9"+dig104+cFatorVen+cValor+livre
	cBarraFim  	:= Alltrim(sBarra)
             
 	//MsgBox("dig104 "+dig104)
 	//MsgBox("cBarraFim "+cBarraFim)
 	
	// Calculo da linha digit†
	sDigi1 := cBanco+"9"+Subs(livre,1,5)  						// 10412.1510	+X
	sDigi2 := Substr(livre, 6,10)								// 90051.05001	+X
	sDigi3 := Substr(livre,16,10)								// 13008.00040	+X
	sDigi1 := cDigi(sDigi1)
	sDigi2 := cDigi(sDigi2)
	sDigi3 := cDigi(sDigi3)
	sDigi1 := Substr(sDigi1,1,5)+"."+Substr(sDigi1,6,5)+" "
	sDigi2 := Substr(sDigi2,1,5)+"."+Substr(sDigi2,6,6)+" "
	sDigi3 := Substr(sDigi3,1,5)+"."+Substr(sDigi3,6,6)+" "
	sDigit := sDigi1+sDigi2+sDigi3+dig104+" "+cFatorVen+cValor		
       
 	//MsgBox("sDigit "+sDigit)

	// Linha Digit·vel
	aBancos[nPOS,7] := sDigit
	// Nosso N˙mero
	aBancos[nPOS,8] := SUBS(nossonum,1,11)+"-"+SUBS(nossonum,12,1)    //"314/"+SUBS(nossonum,1,8)+"-"+SUBS(nossonum,9,1)
	// CÛdigo de Barras
	aBancos[nPOS,9] := cBarraFim	
			 
//############# FIM CITIBANK #############// 	

ELSEIF cBanco=="001"

	cValor  := StrZero(100*nSaldo,10)
	cCartei	:= "17"
	
	// Calculo do digito verificador do Nosso Numero
    // n„o È necess·rio para Banco do Brasil
    // utiliza apenas a vari·vel "nossonum"
			
	// Calculo do codigo de barras + digito
	// --------------------------------------------------------
	// 	01-03  03  BANCO ("104")
	// 	04-04  01  MOEDA ("9"=real,"0"=outras)
	// 	05-05  01  DIGITO VERIFICADOR (DAC)
	// 	06-09  04  FATORVEN
	// 	10-17  08  SALDO
	// 	18-19  02  SALDO (centavos)
	//  20-44  25  LIVRE (sistema BDL)
	// 	 20-29  10  NOSSONUM SEM N⁄MERO DE CONTROLE
	//	 30-44  15  CODIGO CEDENTE SEM DIGITO VERIFICADOR

	cLinha	:= ""	
	strmult := "4329876543298765432987654329876543298765432"
//	livre   := subs(SEE->EE_FAXINI,1,4)+SUBS(alltrim(cCartei),1,2)+subs((nossonum),1,11)+SUBS(cContaSEE,1,7)+"0"
	/*
	CAMPO LIVRE
	20 a 23 4 AgÍncia Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	24 a 25 2 Carteira
	26 a 36 11 N˙mero do Nosso N˙mero(Sem o digito verificador)
	37 a 43 7 Conta do Cedente (Sem o digito verificador, completar com zeros a esquerda quando necess·rio)
	44 a 44 1 Zero
	*/
	livre   := SUBSTR(nossonum,1,10)+SUBSTR(cCodCed,1,15)
	sBarra  := "001"+"9"+cFatorVen+cValor+"000000"+nossonum+"17"
	BaseDiv := 0
	For xx := 1 To 43
		BaseDiv := BaseDiv+Val(Subs(sBarra,xx,1))*Val(Subs(strmult,xx,1))
	Next xx
	resto  	:= BaseDiv % 11
	dig001  := 11 - resto
	dig001  := STR(IIF(dig001>9 .or. dig001==0,1,dig001),1,0)
	sBarra	:= "001"+"9"+dig001+cFatorVen+cValor+"000000"+nossonum+"17"
	cBarraFim := Alltrim(sBarra)    
	
	//         "0019353230000695870 000000 000000487644 17
	
	// Calculo da linha digit†
	sDigi1 := "001"+"9"+Subs(cBarraFim,20,5)  	// 10412.1510	+X
	sDigi2 := Subs (cBarraFim,25,10)								// 90051.05001	+X
	sDigi3 := Subs (cBarraFim,35,10)								// 13008.00040	+X
	sDigi1 := cDigi(sDigi1)
	sDigi2 := cDigi(sDigi2)
	sDigi3 := cDigi(sDigi3)
	sDigi1 := Subs(sDigi1,1,5)+"."+Subs(sDigi1,6,5)+" "
	sDigi2 := Subs(sDigi2,1,5)+"."+Subs(sDigi2,6,6)+" "
	sDigi3 := Subs(sDigi3,1,5)+"."+Subs(sDigi3,6,6)+" "
	sDigit := sDigi1+sDigi2+sDigi3+dig001+" "+cFatorVen+cValor		   // "X" = dig104

	// Linha Digit·vel
	aBancos[nPOS,7] := sDigit
	// Nosso N˙mero
	aBancos[nPOS,8] := nossonum
	// CÛdigo de Barras
	aBancos[nPOS,9] := cBarraFim

ENDIF
	      


Return



/*/
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±…ÕÕÕÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕª±±
±±∫FunáÑo    ≥cDigi     ∫ Autor ≥ RAFAEL OGEDA       ∫ Data ≥  08/05/03   ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫DescriáÑo ≥                                                            ∫±±
±±∫          ≥                                                            ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Uso       ≥ Programa principal                                         ∫±±
±±»ÕÕÕÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
/*/
Static Function cDigi(cVal)

lBase  := Len(cVal)
umdois := 2
sumdig := 0
auxi   := 0
iDig := lBase
Do While iDig >= 1
	auxi   := VAL(Subs(cVal,idig,1))*umdois
	sumdig := SumDig+IIF(auxi<10,auxi,INT(auxi/10)+auxi%10)
	umdois := 3-umdois
	iDig   := iDig-1
Enddo
auxi   := STR(Round(sumdig/10+0.49,0)*10-sumdig,1,0)

Return (cVal+auxi)       

                         
*----------------------
User Function DocCiti()
*----------------------
	sAlias  := Alias()	
	dbSelectArea("SE1")
	sNotFat := '' 
	sDocCit := ''
	nRecn := Recno()
	nInd  := dbSetOrder()
	sReg  := SE1->E1_FILIAL+SE1->E1_CLIENTE+SE1->E1_LOJA+SE1->E1_NUM
	dbSetOrder(24)
	DbSeek(sReg,.T.)
	While !Eof() .And. Alltrim(sReg)  == Alltrim(SE1->E1_FILIAL+SE1->E1_CLIENTE+SE1->E1_LOJA+SE1->E1_FATURA)
	      iF !SE1->E1_NUM $ sNotFat
		      sNotFat += IIF(Empty(sNotFat),'', ' / ') + SE1->E1_NUM
		      sDocCit += Substr(SE1->E1_NUM,5,5)
	      EndIf
	      DbSkip()
	EndDo         
	dbSelectArea("SE1")
	dbSetOrder(nInd)
	DbGoto(	nRecn )
	nRecn := Recno()  
	dbSelectArea(sAlias)   
Return (sDocCit)

