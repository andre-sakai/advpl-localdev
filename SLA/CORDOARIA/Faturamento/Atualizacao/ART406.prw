#include "rwmake.ch"        
#include "topconn.ch"        

/**********************************************************************************************************************************************************
Data...........: 22.12.2005
Descricao…: PROGRAMA PARA APONTAMENTO DE ORDEM DE PRODUCAO UTILIZANDO ROTINAS AUTOMATICAS MATA681
***********************************************************************************************************************************************************/

User Function ART406()     


Public cDocSD3

cDocSD3      := space(06)
nC2_QUANT := 0 // PARA ARMAZENAR C2_QUANT E COMPARAR COM H6_QTDPROD + nQtdProd
cOp 				:= space(11)
cProduto		:= space(15)  
cOperacao		:= space(02)
cRecurso		:= space(06)
cDataIni			:= dDatabase //CTOD("  /  /  ")
cHoraIni 		:= space(05)       
cDataFim		:= dDatabase //CTOD("  /  /  ")
cHoraFim 		:= space(05)
nQtdProd		:= 0.00        
cTempReal	:= space(06)
nQtdPerda		:= 0.00        
cSetIni			:= space(05)
cSetFim		:= space(05)            
cTempoSet   	:= space(05)     
cOperador		:= space(10)
cLote		   	:= space(06)
cSbLote	   	:= space(06)
dDataApont  	:= dDataBase
cPt			   	:= space(1)
cAp				:= space(1)

aItens 			:= {}
aadd(aItens,"P=Parcial")
aadd(aItens,"T=Total")    

aItens2		:= {}
aadd(aItens2,"N=Não")    
aadd(aItens2,"S=Sim")

   
@ 000,000 TO 270,320 DIALOG oDlgXX TITLE "Apontamento de Producao"

@ 005,001 SAY "OP"
@ 005,025 GET cOp Picture "@!" Size 55,10 F3 "SC2" Valid ExistCpo("SC2").AND.BuscaProduto()
@ 005,082 SAY "Produto"
@ 005,105 GET cProduto Picture "@!" Size 55,10

@ 017,001 SAY "Operacao"
@ 017,025 GET cOperacao Picture "@!" Size 55,10 Valid BuscaRecurso()
@ 017,082 SAY "Recurso"
@ 017,105 GET cRecurso Picture "@!" Size 55,10 F3 "SH1" Valid ExistCpo("SH1")

@ 029,001 SAY "DT. Ini"
@ 029,025 GET cDataIni Size 55,10          
@ 029,082 SAY "Hr. Ini"
@ 029,105 GET cHoraIni Picture "99:99" Size 55,10

@ 041,001 SAY "DT. Fim"
@ 041,025 GET cDataFim Size 55,10          
@ 041,082 SAY "Hr. Fim"
@ 041,105 GET cHoraFim Picture "99:99" Size 55,10 Valid CalcHoras()

@ 053,001 SAY "Qtd.Prod."
@ 053,025 GET nQtdProd Picture "99999999.999" Size 55,10 Valid Valida_PT()
@ 053,082 SAY "Temp.Re."
@ 053,105 GET cTempReal Picture "999:99" Size 55,10

@ 065,001 SAY "Qtd.Perda"
@ 065,025 GET nQtdPerda Picture "99999999.999" Size 55,10
@ 065,082 SAY "Set. Ini."
@ 065,105 GET cSetIni Picture "99:99" Size 55,10  Valid CalcSetup()

@ 077,001 SAY "Set. Fim"
@ 077,025 GET cSetFim Picture "99:99" Size 55,10 Valid CalcSetup()
@ 077,082 SAY "Temp.Set"
@ 077,105 GET cTempoSet Picture "99:99" Size 55,1

@ 089,001 SAY "Operador"
@ 089,025 GET cOperador Picture "@!" Size 55,10
@ 089,082 SAY "Lote"
@ 089,105 GET cLote Picture "@!" Size 55,10      

@ 101,001 SAY "Sb.Lote"
@ 101,025 GET cSbLote Picture "@!" Size 55,10

@ 101,082 SAY "Aproveit."
@ 101,105 COMBOBOX cAp ITEMS aItens2 SIZE 55,10      

@ 120,090 BMPBUTTON TYPE 1 ACTION Grava_Mata681()
@ 120,130 BMPBUTTON TYPE 2 ACTION Close(oDlgXX)

@ 113,001 SAY "Parc/Tot"
@ 113,025 COMBOBOX cPt ITEMS aItens SIZE 55,10

ACTIVATE DIALOG oDlgXX


Static Function Grava_Mata681()

Local aOrdem := {} 
Local nOpc := 3 // inclusao 
Private lMsHelpAuto := .t. // se .t. direciona as mensagens de help para o arq. de log
Private lMsErroAuto := .f. //necessario a criacao, pois sera //atualizado quando houver alguma incosistencia nos parametros


//SE FOR APROVEITAMENTO E ULTIMA FASE
if cAp == "S" .AND. UltimaFase()
	Aproveitamento()                                          
	CalculaAPRGERAL(cOp)
endif


//inicia a transacao da rotina automatica
Begin Transaction 
	aOrdem := {{"H6_OP" ,cOp ,Nil},;
	{"H6_PRODUTO" ,cProduto,Nil},;
	{"H6_OPERAC" ,cOperacao ,Nil},; 
	{"H6_RECURSO" ,cRecurso ,Nil},;
	{"H6_DATAINI" ,cDataIni,Nil},; 
	{"H6_HORAINI" ,cHoraIni,Nil},; 
	{"H6_DATAFIN" ,cDataFim,Nil},; 
	{"H6_HORAFIN" ,cHoraFim,Nil},; 
	{"H6_QTDPROD" ,nQtdProd,Nil},; 	 
	{"H6_TEMPO" ,cTempReal,Nil},;
	{"H6_QTDPERD" ,nQtdPerda,Nil},; 
	{"H6_HREINI" ,cSetIni,Nil},; 		
	{"H6_HREFIM" ,cSetFim,Nil},;
    {"H6_DIFREAL" ,cTempoSet,Nil},;
	{"H6_OPERADO" ,cOperador,Nil},;    
	{"H6_LOTE" ,cLote,Nil},;
	{"H6_NUMLOTE" ,cSbLote,Nil},;
	{"H6_PT" ,cPt,Nil},;	
	{"H6_DOCSD3" ,cDocSD3,Nil},;	
	{"H6_DTAPONT" ,dDatabase,Nil}}
	
	MSExecAuto({|x,y| mata681(x,y)},aOrdem,nOpc) 

	If lMsErroAuto
		DisarmTransaction()
		break
	EndIf

End Transaction 

If lMsErroAuto
	Mostraerro() 
	Return .f.
EndIf

//Inicializa as variaveis após a inclusão de um movimento de producao
Inicializa()

Return .t.

Static Function BuscaProduto()

	DbSelectArea("SC2")
	DbSetOrder(1)
	DbSeek(xFilial("SC2")+cOp)
	cProduto     	:= SC2->C2_PRODUTO
	nC2_QUANT	:= SC2->C2_QUANT
	ValidaEncerrada()	
Return .t.

Static Function BuscaRecurso()

	DbSelectArea("SG2")
	DbSetOrder(1)
	if DbSeek(xFilial("SG2")+cProduto+'01'+ cOperacao)
		 cRecurso    := SG2->G2_RECURSO
	  else
	      cRecurso   := space(06)
	endif
		                                    
	ValidaFase()
	
Return .t.     

Static Function CalcSetup()
    
	if cSetIni <> space(05)  .and. cSetFim <> space(05)
		if cSetIni >= cSetFim
			 //MsgBox("Set Up Inicio deve ser maior que o Set Up Fim. Verifique.","Apontamento de Producao","STOP")
			 return .f.
		   else
		     cTempoSet := Substr(ElapTime(cSetIni+":00",cSetFim+":00"),1,5)
		endif
	  else
	     cTempoSet := "  :  "	
	endif	

Return .t.

//***********************************************************************
Static Function Inicializa()	
	cProduto		:= space(15)  
	cOperacao		:= space(02)
	cRecurso		:= space(06)
	cDataIni			:= dDatabase
	cHoraIni 		:= space(05)       
	cDataFim		:= dDatabase
	cHoraFim 		:= space(05)
	nQtdProd		:= 0.00        
	cTempReal	:= space(06)
	nQtdPerda		:= 0.00        
	cSetIni			:= space(05)
	cSetFim		:= space(05)            
	cTempoSet   := space(05)     
	cOperador    := space(10)
	cLote		   := space(06)
	cSbLote	   := space(06)
	dDataApont  := dDataBase
	cPt			   	:= "P"
	cOp 				:= space(11)  
	cAp 				:= "N"
	cDocSD3      := space(06)
Return

/************************************************************/
Static Function CalcHoras()

	Local cTime	:= ""
	Local nTempoCen	:= 0
	Local cForHora	:= "N"
	Local nZeros	:= 5//At(":",PesoPict("SH6","H6_TEMPO"))-1

	If !Empty(cRecurso)
			SH1->(dbSetOrder(1))
			If SH1->(dbSeek(xFilial("SH1")+cRecurso))
				 nTempoCen := TimeCale(cDataIni,ConvHora(cHoraIni,cForHora),cDataFim,ConvHora(cHoraFim,cForHora),cRecurso)
	  		  Else
				 nTempoCen := 0
			End If
	End If

	cTime := StrZero(Int(nTempoCen),nZeros)+":"+StrZero(Mod(nTempoCen,1)*100,2)
	cTime := ConvHora(cTime,"C", cForHora)
	cTempReal := SubStr(cTime,3,6)
Return      

//***************************************************************************
Static Function TimeCale(dDataIni,cHoraIniT,dDataFim,cHoraFimT,cRecurso)
	Local nDuracao := 0
	Local dDataFor
	
	For dDataFor := dDataIni to dDataFim
			cCalend 	:= SHICalen(cRecurso,dDataFor,.T.)
			nDuracao  += PmHrs(dDataFor,If(dDataFor==dDataIni,cHoraIniT,"00:00"),dDataFor,If(dDataFor==dDataFim,cHoraFimT,"24:00"),cCalend,"",cRecurso,.T.)
	Next

Return(nDuracao)

/**********************************************************************************
Digitação da função PmsHrltvl*/
Static Function PmHrs(dDataIni, cHoraIniT, dDataFim, cHoraFimT,cCalend, cProjeto, cRecurso, lPcp)

	Local cAloc
	Local nTamanho
	Local nDuracao 			:= 0
	Local nMinBit				:= 60 / SuperGetMV("MV_PRECISA")
	Local aArea					:= GetArea()
	Local nx					:= 0

	/*DEFAULT*/ cProjeto		:= ""
	/*DEFAULT*/ cRecurso  		:= ""
	/*DEFAULT*/ IPcp		   		:= .F.

	If dDataIni <= dDataFim
		dbSelectArea("SH7")
		If MsSeek(xFilial("SH7")+cCalend)
			cAloc			:= Bin2Str(SH7->H7_ALOC)
			nTamanho		:= Len(cAloc)/7
		 Else
				cAloc		:= ""
				nTamanho := 0
		EndIf
		Do Case
			Case dDataini ==dDataFim
								nDuracao +=PmsHrUtil(dDataIni,"00"+cHoraIniT,"00"+cHoraFimT,cCalend,,cProjeto,cRecurso,IPcp,cAloc,nTamanho)
			Case dDataFim-dDataIni <14
								nDuracao +=PmsHrUtil(dDataIni,"00"+cHoraIniT,"0024:00",cCalend,,cProjeto,cRecurso,IPcp,cAloc,nTamanho)
								dDataIni++
								While dDataIni <= dDataFim
										if dDataIni == dDataFim
												nDuracao += PmsHrUtil(dDataIni,"0000:00","00"+cHoraFimT,cCalend,,cProjeto,cRecurso,lPcp,cAloc,nTamanho)
										   else
												nDuracao += PmsHrUtil(dDataIni,"0000:00","0024:00",cCalend,,cProjeto,cRecurso,lPcp,cAloc,nTamanho)										   		
										endif
										dDataIni++
								end
			OtherWise
								nDuracao += PmsHrUtil(dDataIni,"00"+cHoraIniT,"0024:00",cCalend,,cProjeto,cRecurso,lPcp,cAloc,nTamanho)
								dDataIni++
								For nx := 1 to ((dDataFim-dDataIni-1)/7)
									lSeek := .F.
									DbSelectArea("AFY")
									DbSetOrder(2)
									if MsSeek(xFilial("AFY")+Dtos(dDataIni),.T.)
											While !EOF() .and. (xFilial("AFY") == AFY->AFY_FILIAL) .and. (AFY->AFY_DATA <= dDataIni + 7)
													if 	(Empty(AFY->AFY_PROJET) .OR. (AFY->AFY_PROJET == cProjeto)) .and.;
														(Empty(AFY->AFT_RECURS) .OR. (AFY->AFY_RECURS == cRecurso))
															lSeek := .T.
															Exit
													endif       
													DbSkip()
											End
									Endif

									if lSeek
											dAuxData := dDataIni + 6
											While dDataIni < dAuxData
													nDuracao += PmsHrUtil(dDataIni,"0000:00","0024:00",cCalend,,cProjeto,cRecurso,lPcp,cAloc,nTamanho)		
													dDataIni ++
											End
									  Else
													nDuracao += ((Len(StrTran(Substr(cAloc,1,Len(cAloc))," ","")))*nMinBit)/60
													dDataIni += 7
									endif
								Next
								
								While dDataIni <= dDataFim
										if dDataIni == dDataFim
												nDuracao += PmsHrUtil(dDataIni,"0000:00","00"+cHoraFimT,cCalend,,cProjeto,cRecurso,lPcp,cAloc,nTamanho)
										   else
										   		nDuracao += PmsHrUtil(dDataIni,"0000:00","0024:00",cCalend,,cProjeto,cRecurso,lPcp,cAloc,nTamanho)
										endif                                                                               
										dDataIni++
								End
        EndCase
    Endif
    RestArea(aArea)
Return If(lPcp,nDuracao,NoRound(nDuracao,2))										


Static Function SHICalen(cRecurso,dData,lCalend,lRelease)
	
	Static aRecCalen := {}
	
	Local aSaveAre 		:= {}
	Local nSeek			:= 0
	Local dDatIni			:= Nil
	Local dDatFin		:= Nil
	Local nMvPrecisa 	:= SuperGetMV("MV_PRECISA",,4)
	Local cCalend		:= ""
	Local nPosCal		:= Nil
	
	/*Default*/ lRelease		:= .F.
	/*Default*/ lCalend	    := .F.
	
	if(nSeek := aScan(aRecCalen,{|z|z[1] == cRecurso .and. z[2] <= dData .and. dData <= z[3]})) == 0
			aSavAre := {SH1->(GetArea()),SH7->(GetArea())/*,SHI->(GetArea())*/,GetArea()}
			//dbSelectArea("SHI")
			//if !dbSeek(xFilial("SHI") +  cRecurso)
				SH1->(dbSeek(xFilial("SH1") + cRecurso))
				SH7->(dbSeek(xFilial("SH7") + SH1->H1_CALEND))
				dDatIni  := ctod("01/01/"+StrZero(Mod(Set(5),100),2))
				dDatFin := ctod("12/12/"+StrZero(Mod(Set(5)-1,100),2))	+19
				Aadd(aRecCalen,{cRecurso,dDatIni,dDatFin,SH1->H1_CALEND,{}})
			  /*else
		 		dbSetOrder(2)
		 		dbSeek(xFilial("SHI") + cRecurso + Dtos(dData),.T.)
		 		SH7->(dbSeek(xFilial("SH7") + SHI->HI_CALEND))
		 		Aadd(aRecCalen,{cRecurso,SHI->HIDTVGINI,SHI->DTVGFIM,SHI->HI_CALEND,{}})
		 	endif*/
		 	
		 	nSeek := Len(aRecCalen)
		 	cCalend := SH7->H7_ALOC
		 	
		 	if !lCalend
		 			NotBit(@cCalend,(24*7*nMvPrecisa)/8)
		 			nPerDia := (24 * nMvPrecisa) / 8
		 			aRecCalen[nSeek,5] 		:= Array(7)
		 			aRecCalen[nSeek,5,2]   	:= SubStr(cCalend,1,nPerDia)
		 			aRecCalen[nSeek,5,3]   	:= SubStr(cCalend,1 + (nPerdia * 1),nPerDia)
		 			aRecCalen[nSeek,5,4]   	:= SubStr(cCalend,1 + (nPerdia * 2),nPerDia)
		 			aRecCalen[nSeek,5,5]   	:= SubStr(cCalend,1 + (nPerdia * 3),nPerDia)
		 			aRecCalen[nSeek,5,6]   	:= SubStr(cCalend,1 + (nPerdia * 4),nPerDia)
		 			aRecCalen[nSeek,5,7]   	:= SubStr(cCalend,1 + (nPerdia * 5),nPerDia)		 					 					 					 			
		 			aRecCalen[nSeek,5,1]   	:= SubStr(cCalend,1 + (nPerdia * 6),nPerDia)		 					 					 					 					 			
		 			aEval(aSavAre,{|z| RestArea(z)})
		 	endif
		 			
	endif
		
Return(aRecCalen[nSeek,4])

Static Function ConvHora(cHora,cDe,cPara)                            

	Local nTime 		:= Val(StrTran(cHora,":","."))
	Local nHoras	    := Int(nTime)
	Local nMinutos	:= (nTime - nHoras)
	
	if Empty(StrTran(cHora,":",""))
		Return(cHora)
	endif
	
	cPara := If(cPara == Nil,"N",cPara)
	
	if nMinutos >= 6 .and. cDe == "N"
		nHoras 		+= 1
		nMinutos	-= if(cPara == "N",.6,1)
	endif
	
	if cDe == "N" .and. cPara == "C"
		nMinutos  := nMinutos / .6
	  elseif cDe == "C" .and. cPara == "N"	
	  	nMinutos := nMinutos * .6
	endif

Return(StrZero(nHoras,At(":",cHora)-1)+":"+StrZero(nMinutos*100,2))

Static Function PmsHrUtil(dData,cHoraIniT,cHoraFimT,cCalend,aForadeUso,cProjeto,cRecurso,lPcp,cAloc,nTamanho)
         Local nHoras		:= 0
         Local aArea			:= GetArea()
         Local nDayWeek	:= Dow(dData)
         Local nMinBit		:= 60 / SuperGetMV("MV_PRECISA")
         Local nBitIni			:= Round((Val(SubStr(cHoraIniT,3,2))*60+Val(SubStr(cHoraIniT,6,2)))/nMinBit,0)+1
         Local nBitFim		:= Round((Val(SubStr(cHoraFimT,3,2))*60+Val(SubStr(cHoraFimT,6,2)))/nMinBit,0)+1
         Local aExcrec		:= {}
         /*Default*/	lPcp			:= .F.
         
         nDayWeek := if(nDayWeek =1,7,nDayWeek-1)
         
         if cAloc == Nil
         	dbSelectArea("SH7")
         	if MsSeek(xFilial("SH7")+cCalend)
         			cAloc := Bin2Str(SH7->H7_ALOC)
         			nTamanho := Len(cAloc)/7
         		else
         			cAloc := ""
         			nTamanho := 0
         	endif
		endif
		
		cAloc := Substr(cAloc,(nTamanho*(nDayWeek-1))+1,nTamanho)
		if lPcp
			dbSelectArea("SH9")
			dbSetOrder(2)
			if MsSeek(xFilial("SH9") + "E" +Dtos(dData))
					While SH9->(!EOF() .and. (H9->FILIAL+H9_TIPO==xFilial("SH9")+"E") .and. (dData == H9_DTINI))
							if(SH9->H9_RECURSO == cRecurso) .and. !Empty(SH9->H9_CCUSTO)
									cAloc := Bin2Str(SH9->H9_ALOC)
									aExcRec := {}
									Exit
								elseif  (SH9->H9_RECURSO == cRecurso) .and. Empty(SH9->H9_CCUSTO)
									Aadd(aExcRec,{"1",SH9->H9_ALOC})
								elseif Empty(SH9->H9_RECURSO) .and. (!Empty(SH9->H9_CCUSTO))
									Aadd(aExcRec,"2",SH9->H9_ALOC)
								endif
								SH9->(dbSkip())
					End
					
					if !Empty(aExcRec)
							aExcRec  	:= aSort(aExcRec,,,{|x,y|x[1]<y[1]})
							cAloc		:= Bin2Str(aExcrec[1,2])
					endif
			endif
		  else
		  	dbSelectArea("AFY")
		  	dbSetOrder(2)
		  	if MsSeek(xFilial("AFY")+Dtos(dData))
		  			While !EOF() .and. (xFilial("AFY") == AFY->AFY_FILIAL) .and. (dData == AFY->AFY_DATA)
		  					if 	(Empty(AFY->AFY_PROJET) .OR. (AFY->AFY_PROJET == cProjet)) .and.;
		  						(Empty(AFY->AFY_RECURS) .OR. (AFY->AFY_RECURS == cRecurs))
		  						if FieldPos("AFY_MALOC") > 0
		  								cAloc := AFY->AFY_MALOC
		  					  		else
		  					  			cAloc := Bin2Str(AFY->AFY_ALOC)
		  					  	endif
		  					  	exit
		  					 endif
		  					 DbSkip()
		  			End
		  	Endif
		Endif
		
		nHoras := ((Len(StrTran(Substr(cAloc,nBitIni,nBitFim-nBitIni)," ","")))*nMinBit)/60 
		RestArea(aArea)				  					  					  					 	  					
							
Return (nHoras) //if(lPcp,nHoras,NoRound(nHoras,2))

//**** função para validar o campo H6_PT
Static Function Valida_PT()
	if nQtdProd > 0
		cQry := ""		  
		cQry += "SELECT SUM(H6_QTDPROD) AS QTD FROM SH6010 WHERE D_E_L_E_T_ <> '*' "
		cQry += "AND H6_OP = '" + cOp + "' AND H6_OPERAC = '" + cOperacao + "' "
		If Select("QRY") <> 0
			dbSelectArea("QRY")
			dbCloseArea("QRY")
		Endif	
		
		TCQUERY cQry NEW ALIAS "QRY"	
	
		nQtdTotal := nQtdProd + QRY->QTD
	
		if nQtdTotal >= nC2_QUANT
			cPt := "T"
	  	 else
	   		cPt := "P"	
		endif	              
	endif
Return

//**** funcao para validar se a OP e uma determinada fase já foram concluída em um último lançamento
Static Function ValidaFase()
	cQry := ""		  
	cQry += "SELECT COUNT(*) AS CONT FROM SH6010 WHERE D_E_L_E_T_ <> '*' "
	cQry += "AND H6_OP = '" + cOp + "' AND H6_OPERAC = '" + cOperacao + "'  AND H6_PT = 'T' "
	If Select("QRY") <> 0
		dbSelectArea("QRY")
		dbCloseArea("QRY")
	Endif	
	
	TCQUERY cQry NEW ALIAS "QRY"		                                                                                
	
	if QRY->CONT > 0 
		cMens  := "Capacidade desta OP para" + chr(13)
		cMens += "esta FASE já esta totalizada."
		MsgBox(cMens,"Veda","INFO")
		cOperacao := space(02)
	endif
Return

//*** funcao para validar se op ja foi encerrada
Static Function ValidaEncerrada()
		lRet := .t.
	DbSelectArea("SC2")
	DbSetOrder(1)
	DbSeek(xFilial("SC2")+cOp)
	if !Empty(SC2->C2_DATRF)
		MsgBox("OP já esta encerrada","Veda","INFO")
		lRet := .f.
	endif
Return(lRet)

//*** VERIFICA SE O APONTAMENTO É COM APROVEITAMENTO
//*** SE FOR EXCLUI O EMPENHO SD4
//*** E REGISTRA UM MOVIMENTO EM SD3 COM APR-GERAL
Static Function Aproveitamento()
	
		aEmp := {}
		
		cQry := ""
		cQry += "SELECT D4_COD FROM SD4010, SB1010 "
		cQry += "WHERE SD4010.D_E_L_E_T_ <> '*' AND SB1010.D_E_L_E_T_ <>'*'  "
		cQry += "AND B1_FILIAL = '" + xFilial("SB1") + "' AND D4_FILIAL = '" +  xFilial("SD4") + "'  "
		cQry += "AND B1_COD    = D4_COD  "
		cQry += "AND B1_TIPO   = 'MP' "
		cQry += "AND D4_OP = '" + cOp + "' "
		
		If Select("QRY") <> 0
			dbSelectArea("QRY")
			dbCloseArea("QRY")
		Endif	
		
		TCQUERY cQry NEW ALIAS "QRY"	
		
		DbSelectArea("QRY")
		DbGotop()
		
		//**** VERIFICA SE POSSUI EMPENHOS PARA ESTA OP COM MP AINDA NÃO EXCLUÍDAS
		//*** SE EXISTIR EXCLUI
		While !EOF()
		   
			Begin Transaction 
				aEmp := {	{"D4_FILIAL" ,xFilial("SD4") ,Nil},;
					     	{"D4_COD" ,QRY->D4_COD,Nil},;
							{"D4_OP" ,cOp,Nil}}
					   	
				MSExecAuto({|x,y| mata380(x,y)},aEmp,5) 

				If lMsErroAuto
					DisarmTransaction()
					break
				EndIf

			End Transaction 

			If lMsErroAuto
				Mostraerro() 
				Return .f.
			EndIf 		
		    
			DbSelectArea("QRY")
			DbSkip()
		End
		//***********************************************************************************************************************************
Return

//***** VERIFICA SE É ÚLTIMA FASE E RETORNA TRUE(.T.)
Static Function UltimaFase()
	lRet := .f.
	
	cQry := ""
	cQry += "SELECT TOP 1 G2_OPERAC FROM SG2010 "
	cQry += "WHERE D_E_L_E_T_ <> '*' AND G2_FILIAL = '" + xFilial("SG2") + "' AND G2_PRODUTO = '" + cProduto  + "' "
	cQry += "ORDER BY G2_OPERAC DESC "
		
	If Select("QRY") <> 0
		dbSelectArea("QRY")
		dbCloseArea("QRY")
	Endif	                           
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	DbSelectArea("QRY")
	DbGotop()	
	
	if Trim(QRY->G2_OPERAC) == Trim(cOperacao)
		lRet := .t.
	endif

Return(lRet)


//**** CALCULA A QUANTIDADE E O VALOR PARA O PRODUTO APR-GERAL UTILIZADO PARA
//**** APONTAMENTOS COM APROVEITAMENTO
Static Function CalculaAPRGERAL(OP)

	cQry :=  ""
	cQry += "SELECT G1_COD, G1_QUANT, G1_COMP, B1_CUSTD  FROM SG1010, SB1010 "
	cQry += "WHERE SG1010.D_E_L_E_T_ <> '*' AND SB1010.D_E_L_E_T_ <> '*' AND "
	cQry += "G1_COD = '" + cProduto + "' "
	cQry += "AND G1_FILIAL = '" + xFilial("SG1") + "' "
	cQry += "AND G1_COMP = B1_COD "
	cQry += "AND B1_TIPO = 'MP' "
	cQry += "AND G1_FILIAL = B1_FILIAL "
	
	If Select("QRY") <> 0
		dbSelectArea("QRY")
		dbCloseArea("QRY")
	Endif	                                                    
	
	TCQUERY cQry NEW ALIAS "QRY"	
	
	DbSelectArea("QRY")
	DbGotop()		
	
	While !EOF()
		GeraSD3(QRY->G1_COMP,QRY->G1_QUANT,QRY->B1_CUSTD,OP)		
	    DbSelectArea("QRY")
	    DbSkip()
	End
	
Return

//****************************************************************************************************************************
Static Function GeraSD3(COMP,QUANTCOMP,CUSTDCOMP,OP)
    
	Local nOpc := 3 // inclusao
    cOpSD3 	    	:= space(11)
	nCusto1	    	:= CUSTDCOMP * QUANTCOMP * nQtdProd  //OBTEM-SE O CUSTO STANDARD PARA A MP EM QUESTÃO
	cLocPadAPR		:= ""
	cGrupoAPR	    := ""
	
	DbSelectArea("SB1")
	DbSetOrder(1)
	if DbSeek(xFilial("SB1")+'APR-GERAL')
			nCusAPR 			:= SB1->B1_CUSTD	
			cLocPadAPR		:= SB1->B1_LOCPAD
			cGrupoAPR		:= SB1->B1_GRUPO
			cUMAPR			:= SB1->B1_UM
		else
			nCusAPR := 0			
	endif 
	
	if nCusAPR > 0
			nQuantAPR	:=  nCusto1 /  nCusAPR
		else
			nQuantAPR  := 1	
	endif                  
		

//***       E N T R A D A  *************************************
	//BUSCA O ULTIMO DOC  PARA INCREMENTAR 1	
	cQry   := ""
	cQry += "SELECT MAX(D3_DOC) AS DOC FROM SD3010 WHERE D_E_L_E_T_ <> '*' AND D3_DOC >= 'N' "
	If Select("QRY") <> 0
		dbSelectArea("QRY")
		dbCloseArea("QRY")
	Endif	
	TCQUERY cQry NEW ALIAS "QRY"
	cDoc 			:= SUBSTR(QRY->DOC,1,1) + STRZERO(VAL(SUBSTR(QRY->DOC,2,5))+1,5)		

	cCC				:= '1         '
	cEmissao		:= dDatabase 
 
	//Grava_Mata241(cDoc,'009',cCC,cEmissao,nQuantAPR,cOpSD3,cLocPadAPR,cUMAPR,cGrupoAPR,nCusto1)
	
	 
	//INCLUINDO EM SD3 ******* ENTRADA
	Private lMsHelpAuto := .t. // se .t. direciona as mensagens de help para o arq. de log
	Private lMsErroAuto := .f. //necessario a criacao, pois sera //atualizado quando houver alguma incosistencia nos parametros
	
	
	aInt			:= {} 
	aInternos	:= {} 
	aCabec		:= {}	
	aHeader	:= {}
	
	//inicia a transacao da rotina automatica	
	Begin Transaction                                

	aCabec := {{"D3_FILIAL" ,xFilial("SD3"),Nil},;  
					{"D3_DOC" ,cDoc,Nil},;
					{"D3_TM" ,'009',Nil},; //** AQUI
					{"D3_CC" ,cCC ,Nil},; 
					{"D3_EMISSAO" ,cEmissao,Nil}}

	aInt := {	{"D3_COD" ,'APR-GERAL',Nil},; 
			{"D3_QUANT" ,nQuantAPR,Nil},;
			{"D3_CUSTO1" ,nCusto1,Nil},;
			{"D3_OP" ,cOpSD3,Nil},;		
			{"D3_LOCAL" ,cLocPadAPR,Nil},;		
			{"D3_UM" ,cUMAPR,Nil},;				
			{"D3_GRUPO" ,cGrupoAPR,Nil}}
	
	aadd(aInternos,aInt)

	MSExecAuto({|x,y,z| mata241(x,y,z)},aCabec,aInternos,nOpc) 	
    
	If lMsErroAuto
		DisarmTransaction()
		break
	EndIf

	End Transaction 

	If lMsErroAuto
		Mostraerro() 
		Return .f.
	EndIf 	
	//FIM INCLUSAO SD3
//***************************** FIM ENTRADA ***************************


//***       S A Í D A   *************************************
	//BUSCA O ULTIMO DOC  PARA INCREMENTAR 1	
	cQry   := ""
	cQry += "SELECT MAX(D3_DOC) AS DOC FROM SD3010 WHERE D_E_L_E_T_ <> '*' AND D3_DOC >= 'N' "
	If Select("QRY") <> 0
		dbSelectArea("QRY")
		dbCloseArea("QRY")
	Endif	
	TCQUERY cQry NEW ALIAS "QRY"
	cDoc 			:= SUBSTR(QRY->DOC,1,1) + STRZERO(VAL(SUBSTR(QRY->DOC,2,5))+1,5)		
	

	cCC				:= '1         '
	cEmissao		:= dDatabase 
    cOpSD3		:= OP
	
	//INCLUINDO EM SD3 ******* SAIDA
	Private lMsHelpAuto := .t. // se .t. direciona as mensagens de help para o arq. de log
	Private lMsErroAuto := .f. //necessario a criacao, pois sera //atualizado quando houver alguma incosistencia nos parametros
	
	
	aInt			:= {} 
	aInternos	:= {} 
	aCabec		:= {}	
	aHeader	:= {}
	
	//inicia a transacao da rotina automatica	
	Begin Transaction                                

	aCabec := {{"D3_FILIAL" ,xFilial("SD3"),Nil},;  
					{"D3_DOC" ,cDoc,Nil},;
					{"D3_TM" ,'998',Nil},;  //** AQUI
					{"D3_CC" ,cCC ,Nil},; 
					{"D3_EMISSAO" ,cEmissao,Nil}}

	aInt := {	{"D3_COD" ,'APR-GERAL',Nil},; 
				{"D3_QUANT" ,nQuantAPR,Nil},;
				{"D3_CUSTO1" ,nCusto1,Nil},;
				{"D3_OP" ,cOpSD3,Nil},;		
				{"D3_LOCAL" ,cLocPadAPR,Nil},;		
				{"D3_UM" ,cUMAPR,Nil},;		 
				{"D3_GRUPO" ,cGrupoAPR,Nil}}
   
   aadd(aInternos,aInt)

	MSExecAuto({|x,y,z| mata241(x,y,z)},aCabec,aInternos,nOpc) 	
    
	If lMsErroAuto
		DisarmTransaction()
		break
	EndIf

	End Transaction 

	If lMsErroAuto
		Mostraerro() 
		Return .f.
	EndIf 	
	
	cDocSD3 := cDoc
	
	//FIM INCLUSAO SD3
//***************************** FIM S A Í D A ***************************
			
Return