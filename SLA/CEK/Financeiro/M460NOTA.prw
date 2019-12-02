#Include 'Protheus.ch'
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPonto Entrada ณPOL06A30  บAutor  ณACTVS           บ Data ณ  09/27/12   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบ Ponto de entrada 'M460NOTA', executado ao final do processamento de   บฑฑ
ฑฑบ todas as notas fiscais selecionadas na markbrowse                     บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/       
User Function M460NOTA()

	Local aBoletos	:= {}
	Local aDBF2		:= {}   
	Local aSE1		:= {}
	Local nI 		:= 0
	Local nX 		:= 0   
	
	Public _aS_F_2_      
	
	If SuperGetMV("MV_XBOLNF",.F.,"N") <> "S"
		Return NIL
	Endif
	
	If ValType(_aS_F_2_) == "U"
		_aS_F_2_ := {}
	EndIf
                                 	
	DbSelectArea("SE1")
	aDBF2 := dbStruct()
	
	For nX := 1 To Len(_aS_F_2_)

		DbSelectArea("SE1")
		DbSetOrder(1)	
		
		If DbSeek(xFilial("SE1")+_aS_F_2_[nX][1]+_aS_F_2_[nX][2])
			While !EoF() .And. SE1->E1_NUM == _aS_F_2_[nX][2] .And. SE1->E1_PREFIXO == _aS_F_2_[nX][1];
			 .And. SE1->E1_FILIAL == xFilial("SE1")                                                

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
	
	Next
	
	If Len(aBoletos) > 0 .And. MsgYesNo("Deseja gerar boleto?")
		//Filtro Tela de Faturamento
		cPerg2	:= "BOLFSW2"
		PutSx1(cPerg2,"01","Do Banco:"				,"","","mv_ch1" ,"C",03,0,0,"G","","SEEBOL","","","mv_par01",""   				,"","","",""  			,"","","","","","","","","","","")
		PutSx1(cPerg2,"02","Agencia:"				,"","","mv_ch2" ,"C",05,0,0,"G","",""		 ,"","","mv_par02",""   				,"","","",""  			,"","","","","","","","","","","")
		PutSx1(cPerg2,"03","Conta:"					,"","","mv_ch3" ,"C",10,0,0,"G","",""		 ,"","","mv_par03",""  				,"","","",""  			,"","","","","","","","","","","")
		PutSx1(cPerg2,"04","SubConta:" 				,"","","mv_ch4" ,"C",03,0,0,"G","","SEESUB","","","mv_par04",""  				,"","","","" 			,"","","","","","","","","","","")
		If Pergunte(cPerg2,.T.,"Boleto")
			U_BOLETOACTVS(aBoletos)
		EndIf

	EndIf
	
	_aS_F_2_ := {}
Return