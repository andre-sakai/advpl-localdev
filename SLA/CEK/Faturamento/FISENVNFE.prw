#include "rwmake.ch" 
#include "topconn.ch" 

//---------------------------------------------------------------------------------------
// Analista   : Júnior Conte - 22/08/18
// Nome função: FISENVNFE
// Parametros :
// Objetivo   : Envia boleto automatico para cliente na validação da nfe.
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------     

User Function FISENVNFE()
Local aIdNfe 	:= PARAMIXB
Local cIdsNfe	:= ""
Local nX		:= 0  
Local aBoletos	:= {}
Local aDBF2		:= {}
Local aSE1		:= {}




If Len(aIdNfe) > 0 
    //parâmetro para habilitar e desabilitar  o enviou automático de boleto.
	If SuperGetMV("MV_XBOLNFE",.F.,"N") <> "S"
		Return NIL
	Endif 
	
	//cria estrutura de campos para gerar informações na impressão dos boletos.	
	DbSelectArea("SE1")
	aDBF2 := dbStruct()                                
	
	//nfe's selecionadas para transmissão na rotina spednfe
	For nX := 1 To Len(aIdNfe)		                       
	
		cIdsNfe	:= Alltrim(aIdNfe[Nx])
		
		DbSelectArea("SE1")
		DbSetOrder(1)  
		
		cPrefixo := substr(cIdsNfe, 1, tamsx3("F2_SERIE")[1] ) 
		cDoc     := substr(cIdsNfe, tamsx3("F2_SERIE")[1] + 1, tamsx3("F2_DOC")[1] )    
		
		dbSelectArea("SF2")
		dbSetOrder(1)
		dbSeek(xFilial("SF2") +  cDoc + cPrefixo)    
		
		IF !EMPTY(SF2->F2_CHVNFE)								
			If DbSeek(xFilial("SE1")+ cPrefixo + cDoc )
				While !EoF() .And. SE1->E1_NUM == cDoc .And. SE1->E1_PREFIXO == cPrefixo;
						.And. SE1->E1_FILIAL == xFilial("SE1")   
						
					//validação do tipo para não enviar titulos de impostos
					If Substr(SE1->E1_TIPO,3,1) != '-'
						aSE1 := {}
						For nI := 1 To Len(aDBF2)
							AADD(aSe1, {aDBF2[nI][1], &("SE1->"+(aDBF2[nI][1]))})
						Next
						AADD(aBoletos, aSE1)
					Endif
					
					DbSelectArea("SE1")
					DbSkip()
				EndDo
			EndIf  
		ENDIF		

	Next nX	
	
	If Len(aBoletos) > 0 .And. MsgYesNo("Deseja gerar boleto?")
		//Filtro Tela de Faturamento
		cPerg2	:= "BOLFSW3"
	
		u_zPutSX1(cPerg2, "01", "Do Banco:",		    "MV_PAR01", "MV_CH0", "C", 03, 0, "G", "","SEEBOL", 			"", "",  "",        "",        "",    "", "Informe o Banco")
		u_zPutSX1(cPerg2, "02", "Agencia:",		    "MV_PAR02", "MV_CH1", "C", 05, 0, "G", "","", "",        	"",  "",  "",        "",    "", "Informe agenciia")
		u_zPutSX1(cPerg2, "03", "Conta:",				 "MV_PAR03", "MV_CH2", "C", 10, 0, "G", "","", "",        	"",  "",   "",        "",    "", "Informe a conta")
		u_zPutSX1(cPerg2, "04", "Subconta:",			 "MV_PAR04", "MV_CH3", "C", 03, 0, "G", "","SEESUB", 			"",  "",  "",        "",        "",    "", "Informe a Sub-Conta")
		u_zPutSX1(cPerg2, "05",  "Envia E-mail:",	    "MV_PAR05", "MV_CH4", "N", 01, 0, "C",      "",   "",        "", "SIM","NAO", "", "", "Enviar E-mail 1- Sim 2=Não")
						
		
		
		If Pergunte(cPerg2,.T.,"Boleto")
			If mv_par05 == 1 
				U_zBolA02(aBoletos)
			Else 
				U_zBoletoA01(aBoletos)
			EndIf
		EndIf

		
	EndIf

EndIF	
Return Nil