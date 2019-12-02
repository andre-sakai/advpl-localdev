#INCLUDE "RWMAKE.CH"
//-------------------------------------------------------------------
/*/{Protheus.doc} BOLCEF
Impress„o Boleto Caixa EconÙmica

@author J˙nior Conte
@since 19/07/2017
@version 1.0
/*/
//-------------------------------------------------------------------


User Function BOLCEF()

LOCAL   nOpc := 0
PRIVATE Exec    := .F.


cPerg     :="BOLCEF"
ValidPerg()


If !Pergunte(cPerg,.T.)
	Return()
EndIf
//
CRIA_MV()
//
PRIVATE nCB1Linha	:= GETMV("PV_BOL_LI1") //14.5 >> 12.9
PRIVATE nCB2Linha	:= GETMV("PV_BOL_LI2") //26.1
Private nCBColuna	:= GETMV("PV_BOL_COL") //1.3
Private nCBLargura	:= GETMV("PV_BOL_LAR") //0.0280
Private nCBAltura	:= GETMV("PV_BOL_ALT") //1.4
Private _cNossoNum:=""
//


DbselectArea("SE1")
DbSetOrder(1)
//
Processa({|lEnd|MontaRel()})
//
Return Nil
/*/
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±⁄ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø±±
±±≥FunáÖo    ≥MontaRel()   ≥Descriá„o≥Montagem e Impressao de boleto Gra- ≥±±
±±≥          ≥             ≥         ≥fico do Banco CEF                   ≥±±
±±¿ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
/*/
Static Function MontaRel()
LOCAL   oPrint
LOCAL   n := 0
LOCAL aBitmap := "\SYSTEM\CEF.BMP"

LOCAL aDadosEmp    := {	AllTrim(SM0->M0_NOMECOM)                                                   ,; //[1]Nome da Empresa
Alltrim(SM0->M0_ENDCOB)                                                    ,; //[2]EndereÁo
AllTrim(SM0->M0_CIDCOB)+", "+Alltrim(SM0->M0_ESTCOB) ,; //[3]Complemento
"CEP: "+Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)             ,; //[4]CEP
"Fone: "+SM0->M0_TEL                                                    ,; //[5]Telefones
"CNPJ: "+Subs(SM0->M0_CGC,1,5)+          ; //[6]
Subs(SM0->M0_CGC,6,3)+"/"+Subs(SM0->M0_CGC,9,4)+"-"+                       ; //[6]
Subs(SM0->M0_CGC,13,2)                                                     ,; //[6]CGC
"I.E.: "+Subs(SM0->M0_INSC,1,3)+"."+Subs(SM0->M0_INSC,4,3)+"."+            ; //[7]
Subs(SM0->M0_INSC,7,3)+"."+Subs(SM0->M0_INSC,10,3)                         }  //[7]I.E

LOCAL aDadosTit
LOCAL aDadosBanco
LOCAL aDatSacado

LOCAL i            := 1
LOCAL CB_RN_NN     := {}
LOCAL nRec         := 0
LOCAL _nVlrAbat    := 0
LOCAL cParcela	   := ""  

Local nVlrAbat	  := 0

oPrint:= TMSPrinter():New( "Boleto Laser" )
oPrint:SetPortrait() // ou SetLandscape()
oPrint:StartPage()   // Inicia uma nova p·gina
//
aBltCEF:={}

DBSELECTAREA("SE1")
DBSETORDER(5) 

//DBSEEK(xFilial("SE1")+MV_PAR01+MV_PAR02,.T.)
DBSEEK(xFilial("SE1")+MV_PAR06,.T.)
//
While !EOF() .and. SE1->E1_NUM >= MV_PAR02 .and. SE1->E1_NUM <= MV_PAR03 .and. SE1->E1_PREFIXO == MV_PAR01 .and. SE1->E1_NUMBOR >= MV_PAR06 .and. SE1->E1_NUMBOR <= MV_PAR07
	
	If Alltrim(SE1->E1_TIPO) <> 'NF' .AND. Alltrim(SE1->E1_TIPO) <> 'FT'
		DBSelectArea("SE1")
		DBSKIP()
		LOOP
	ENDIF
	
	IF SE1->E1_SALDO <= 0
		DBSelectArea("SE1")
		DBSKIP()
		LOOP
	ENDIF
	/*
	If Val(SE1->E1_NUM) > Val(MV_PAR03) .or. SE1->E1_PREFIXO != MV_PAR01 .OR. SE1->E1_PARCELA > MV_PAR05  //.or. _cBanco <> "341"
		DBSelectArea("SE1")
		DBSkip()
		Loop
		
	EndIF
	// 
	
	
	If ALLTRIM(SE1->E1_PARCELA) < ALLTRIM(MV_PAR04) .OR. 	ALLTRIM(SE1->E1_PARCELA) > ALLTRIM(MV_PAR05)
		DBSelectArea("SE1")
		DBSKIP()
		LOOP
	ENDIF
	
	  */
	
	
  //	IF  MV_PAR06<>SE1->E1_CLIENTE .AND. MV_PAR07<>SE1->E1_CLIENTE
	  //	SE1->(dbskip())
	  //	Loop
 //	Else
		aBolText := {"ApÛs " + DTOC(SE1->E1_VENCTO) +  " cobrar R$" + transform(((SE1->E1_SALDO / 100) * 0.33),"@E 99999.99") + " de juros por dia de atraso.","Protestar apÛs 15 (sete) dias do vencimento."}
   //	EndIf
	
	//---------------------
	_nNumNF   := SE1->E1_NUM
	_cCliente := SE1->E1_CLIENTE
	_cLoja    := SE1->E1_LOJA
	_cParc    := SE1->E1_PARCELA
	
	//DbselectArea("SA1")
	
	/*
	SA1->(DbSetOrder(1))
	If SA1->(DBSeek(xFilial("SA1") + _cCliente + _cLoja))
		IF SA1->(A1_BCOBOLE) <>  '104' .AND. MV_PAR06<>SE1->E1_CLIENTE .AND. MV_PAR07<>SE1->E1_CLIENTE
			SE1->(dbskip())
			Loop
		ENDIF
	Else
		SE1->(dbskip())
		Loop
	EndIf
	*/
	
	//
	IF !EMPTY(SE1->E1_NUMBCO) .AND. SUBSTR(ALLTRIM(SE1->E1_NUMBCO),1,2) <> "14"
		//
		IF !MsgBox("O tÌtulo ("+SE1->E1_PREFIXO+"/"+SE1->E1_NUM+"-"+SE1->E1_PARCELA+") n„o gerou um Boleto da CEF previamente. Deseja Imprimir o Boleto Caixa?", "Impress„o de Boleto CEF", "YESNO")
			DBSelectArea("SE1")
			DBSKIP()
			LOOP
		ENDIF
		//
	ENDIF
	//
	/*
	DO CASE
		CASE ALLTRIM(SE1->E1_PARCELA) == "A"
			cParcela := "01"
		CASE ALLTRIM(SE1->E1_PARCELA) == "B"
			cParcela := "02"
		CASE ALLTRIM(SE1->E1_PARCELA) == "C"
			cParcela := "03"
		CASE ALLTRIM(SE1->E1_PARCELA) == "D"
			cParcela := "04"
		CASE ALLTRIM(SE1->E1_PARCELA) == "E"
			cParcela := "05"
		CASE ALLTRIM(SE1->E1_PARCELA) == "F"
			cParcela := "06"
		CASE ALLTRIM(SE1->E1_PARCELA) == "G"
			cParcela := "07"
		CASE ALLTRIM(SE1->E1_PARCELA) == "H"
			cParcela := "08"
		CASE ALLTRIM(SE1->E1_PARCELA) == "I"
			cParcela := "09"
		CASE ALLTRIM(SE1->E1_PARCELA) == "J"
			cParcela := "10"               
		CASE ALLTRIM(SE1->E1_PARCELA) == "K"
			cParcela := "11"
		CASE ALLTRIM(SE1->E1_PARCELA) == "L"
			cParcela := "12"
		CASE ALLTRIM(SE1->E1_PARCELA) == "M"
			cParcela := "13"
		CASE ALLTRIM(SE1->E1_PARCELA) == "N"
			cParcela := "14"
		CASE ALLTRIM(SE1->E1_PARCELA) == "O"
			cParcela := "15"
		CASE ALLTRIM(SE1->E1_PARCELA) == "P"
			cParcela := "16"
		CASE ALLTRIM(SE1->E1_PARCELA) == "Q"
			cParcela := "17"
		CASE ALLTRIM(SE1->E1_PARCELA) == "R"
			cParcela := "18"
		CASE ALLTRIM(SE1->E1_PARCELA) == "S"
			cParcela := "19"
		CASE ALLTRIM(SE1->E1_PARCELA) == "T"
			cParcela := "20"    
		CASE ALLTRIM(SE1->E1_PARCELA) == "U"
			cParcela := "21"
		CASE ALLTRIM(SE1->E1_PARCELA) == "V"
			cParcela := "22"
		CASE ALLTRIM(SE1->E1_PARCELA) == "W"
			cParcela := "23"
		CASE ALLTRIM(SE1->E1_PARCELA) == "Y"
			cParcela := "24"    
		CASE ALLTRIM(SE1->E1_PARCELA) == "Z"
			cParcela := "25"    
		OTHERWISE
			//cParcela := SUBSTRING(SE1->E1_PARCELA,3,1)
			cParcela := "99"
	ENDCASE
	*/   
	
	cParcela := strzero(val(SE1->E1_PARCELA), 3)
	
	_cNossoNum := "14"+IIF(!Empty(SE1->E1_FILORIG),SE1->E1_FILORIG,"99") +Substr((strzero(Val(Alltrim(SE1->E1_NUM)),11)),1,11) + cParcela
	
	//Posiciona o SA1 (Cliente)
	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial()+SE1->E1_CLIENTE+SE1->E1_LOJA,.T.)
	DbSelectArea("SE1")
	
	aDadosBanco  := {"104"           		,; // [1]Numero do Banco
	""      ,; // [2]Nome do Banco
	"3525"      	        ,; // [3]AgÍncia
	"00483",;
	"6" ,;
	"RG"                  }  // [6]Codigo da Carteira
	//
	
	If Empty(SA1->A1_ENDCOB) .or. Alltrim(SA1->A1_ENDCOB) == 'O MESMO'
		aDatSacado   := {AllTrim(SA1->A1_NOME)                            ,;     // [1]Raz„o Social
		AllTrim(SA1->A1_COD )+"-"+SA1->A1_LOJA           ,;     // [2]CÛdigo
		AllTrim(SA1->A1_END )+"-"+AllTrim(SA1->A1_BAIRRO),;     // [3]EndereÁo
		AllTrim(SA1->A1_MUN )                             ,;     // [4]Cidade
		SA1->A1_EST                                       ,;     // [5]Estado
		SA1->A1_CEP                                       ,;     // [6]CEP
		SA1->A1_CGC	 									  }      // [7]CGC
	Else
		aDatSacado   := {AllTrim(SA1->A1_NOME)                               ,;   // [1]Raz„o Social
		AllTrim(SA1->A1_COD )+"-"+SA1->A1_LOJA              ,;   // [2]CÛdigo
		AllTrim(SA1->A1_ENDCOB)+"-"+AllTrim(SA1->A1_BAIRROC),;   // [3]EndereÁo
		AllTrim(SA1->A1_MUNC)	                              ,;   // [4]Cidade
		SA1->A1_ESTC	                                      ,;   // [5]Estado
		SA1->A1_CEPC                                         ,;   // [6]CEP
		SA1->A1_CGC										   }    // [7]CGC
	Endif
	
	nVlrAbat   :=  SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",1,,SE1->E1_CLIENTE,SE1->E1_LOJA)
	CB_RN_NN    := Ret_cBarra(Subs(aDadosBanco[1],1,3)+"9",aDadosBanco[3],aDadosBanco[4],aDadosBanco[5],Alltrim(_cNossoNum),(E1_VALOR-nVlrAbat),E1_VENCTO) // "9" … O CODIGO DA MOEDA
	
	aDadosTit    := {AllTrim(E1_NUM)+AllTrim(E1_PARCELA)						,;  // [1] N˙mero do tÌtulo
	E1_EMISSAO                              					,;  // [2] Data da emiss„o do tÌtulo 
	Date()                                  					,;  // [3] Data da emiss„o do boleto
	E1_VENCTO                             					,;  // [4] Data do vencimento
	(E1_SALDO - nVlrAbat)			                    					,;  // [5] Valor do tÌtulo
	CB_RN_NN[3]                             					,;  // [6] Nosso n˙mero (Ver fÛrmula para calculo)
	E1_PREFIXO                               					,;  // [7] Prefixo da NF
	"DM"	                               						}  // [8] Tipo do Titulo
	//
	//for nVezes:= 1 to 2
	oPrint:StartPage()
	//Impress(oPrint,aBitmap,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,CB_RN_NN)
	Impress(oPrint,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,CB_RN_NN)
	
	oPrint:EndPage()  ////<<<<
	
	AADD(aBltCEF, {"\boletos\B_"+alltrim(SE1->E1_PREFIXO)+alltrim(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA),"","",SE1->E1_EMISSAO,ALLTRIM(SE1->E1_PREFIXO),aLLTRIM(SE1->E1_NUM),ALLTRIM(SE1->E1_PARCELA),SE1->E1_VENCTO,SE1->E1_SALDO})
	n := n + 1
	
	dbSelectArea("SE1")
	dbSkip()
	IncProc()
	i := i + 1
EndDo


If len(aBltCEF) > 0
	oPrint:EndPage()     // Finaliza a p·gina
	
	/*
	oprint:saveallasjpeg("\boletos\B_"+alltrim(SE1->E1_PREFIXO)+alltrim(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA),800,1200,120)
	
	For aaab:= 1 to len(aBltCEF)
		
		//AADD(aBltitau, {"\boletos\B_"+alltrim(SE1->E1_PREFIXO)+alltrim(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA),SA1->A1_BLEMAIL,SA1->A1_MAILFIN,SE1->E1_EMISSAO,ALLTRIM(SE1->E1_PREFIXO),aLLTRIM(SE1->E1_NUM),ALLTRIM(SE1->E1_PARCELA),SE1->E1_VENCTO,SE1->E1_SALDO})
		FRename( ("\boletos\B_"+alltrim(SE1->E1_PREFIXO)+alltrim(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA)+"_pag"+str(aaab,IIF(AAAB > 9,2,1),0)+".jpg"),(aBltCEF[aaab][1]+"_pag1.jpg"))
		cNomearqant:="\boletos\B_"+alltrim(SE1->E1_PREFIXO)+alltrim(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA)+"_pag"+str(aaab,IIF(AAAB > 9,2,1),0)+".jpg"
		cNovoNome:=(aBltCEF[aaab][1]+"_pag1.jpg")
		If MV_PAR08 == 1 .and. aBltCEF[aaab][2] == "1"  .AND. !EMPTY(aBltCEF[aaab][3])
			U_BI043(cNovoNome,ALLTRIM(aBltCEF[aaab][3]),aBltCEF[aaab][4],ALLTRIM(aBltCEF[aaab][5]),aLLTRIM(aBltCEF[aaab][6]),ALLTRIM(aBltCEF[aaab][7]),aBltCEF[aaab][8],aBltCEF[aaab][9],"C")
		Endif
	Next aaab
	
	*/
	oPrint:Preview()     // Visualiza antes de imprimir
Else
	MsgStop("Nao foi encontrado nenhum titulo com boleto para a faixa de paramentros informada. Favor revisar os parametros informados.")
Endif
Return nil
//
/*
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±⁄ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø±±
±±≥FunáÖo    ≥Impress      ≥Descriá„o≥Impressao de Boleto Grafico do Banco≥±±
±±≥          ≥             ≥         ≥Itau.                               ≥±±
±±¿ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
*/
*********************************************************************
Static Function  	Impress(oPrint,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,cLinhaDig)
//Static Function Impress(oPrint,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,cBarra,cLinhaDig)
*********************************************************************
Local oFont5
Local oFont8
Local oFont10
Local oFont15
Local oFont16
Local oFont14n
Local oFont24
Local i := 0
Local aCoords1 := {2000,1900,2100,2300}
Local aCoords2 := {2270,1900,2340,2300}
Local oBrush
aBitmap      := {"\SYSTEM\CEF.BMP",IIF(Substr(DtoS(dDataBase),5,2) == '09',"\SYSTEM\lgrl02.bmp","\SYSTEM\lgrl02.bmp")}  		//Logo da empresa
cAgencia :="3525"
//cCedente :="04184"   696227"  // digito 0
cCedente :="861807"  
xDig	 := "0"

oFont5  := TFont():New("Arial",5,8 ,.T.,.F.,5,.T.,5,.T.,.F.)
oFont8  := TFont():New("Arial",9,8 ,.T.,.F.,5,.T.,5,.T.,.F.)
oFont10 := TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)

oFont11 := TFont():New("Arial",4,6,.T.,.F.,5,.T.,5,.T.,.F.)

oFont15 := TFont():New("Arial",9,15,.T.,.T.,5,.T.,5,.T.,.F.)
oFont16 := TFont():New("Arial",9,16,.T.,.T.,5,.T.,5,.T.,.F.)
oFont14n:= TFont():New("Arial",9,14,.T.,.F.,5,.T.,5,.T.,.F.)
oFont24 := TFont():New("Arial",9,24,.T.,.T.,5,.T.,5,.T.,.F.)

oBrush := TBrush():New("",4)

oPrint:StartPage()   // Inicia uma nova p·gina

oPrint:Say  (000,100,aDadosEmp[1],oFont10)


oPrint:Box  (100,100,1210,2300)
oPrint:Line (200,100,200,2300 )
oPrint:Line (400,100,400,2300 )
oPrint:Line (100,400,200,400  )
oPrint:Line (100,800,200,800  )
oPrint:Line (100,1150,200,1150)
oPrint:Line (100,1500,200,1500)
oPrint:Line (100,1850,200,1850)

oPrint:SayBitMap (605,105,aBitMap[2],2090,490)   

oPrint:Say  (230,115 ,"Dados do Pagador"                  ,oFont8 )
oPrint:Say  (270,115 ,aDatSacado[1]                      ,oFont10)
oPrint:Say  (305,115 ,aDatSacado[3]                      ,oFont10)
oPrint:Say  (340,115 ,TRANSFORM(aDatSacado[6],"@R 99.999-999") +" - " + aDatSacado[4] + " - "+aDatSacado[5]                       ,oFont10)
//oPrint:Say  (340,2000,TRANSFORM(aDatSacado[6],"@R 99.999-999")+"   "+aDatSacado[5]  ,oFont10)

oPrint:Say  (115,115,"Vencimento"                   ,oFont8 )
oPrint:Say  (145,115,Substring(DTOS(aDadosTit[4]),7,2)+"/"+Substring(DTOS(aDadosTit[4]),5,2)+"/"+ Substring(DTOS(aDadosTit[4]),1,4),oFont10)

oPrint:Say  (115,415,"Valor R$"                     ,oFont8 )
oPrint:Say  (145,415,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10)

oPrint:Say  (115,815,"Data da OperaÁ„o"             ,oFont8 )
oPrint:Say  (145,815,Substring(DTOS(aDadosTit[3]),7,2)+"/"+Substring(DTOS(aDadosTit[3]),5,2)+"/"+ Substring(DTOS(aDadosTit[3]),1,4)             ,oFont10)


oPrint:Say  (115,1165,"Nro.do Documento"            ,oFont8 )
oPrint:Say  (145,1165,aDadosTit[1]                  ,oFont10)

oPrint:Say  (115,1515,"AgÍncia/CÛd Benefici·rio"      ,oFont8 )
oPrint:Say  (145,1515,cAgencia+"/"+cCedente+"-"+xDig,oFont10)


oPrint:Say  (115,1865,"Nosso N˙mero"                ,oFont8 )
//oPrint:Say  (145,1865,transform(_cNossoNum,"@R XX/XXXXXX-X"),oFont10)
oPrint:Say  (145,1865,Substr(aDadosTit[6],1,3)+Substr(aDadosTit[6],4),oFont10)

oPrint:Say  (1220,1605,"Destaque aqui, esta via n„o precisa ser levada ao banco",oFont8)


For i := 100 to 2300 step 50
	oPrint:Line( 1260, i, 1260, i+30)
Next i

oPrint:Line (1410,100,1410,2300)
//oPrint:Line (1410,550,1310,550)
//oPrint:Line (1410,800,1310,800)
oPrint:Line (1410,330,1310,330)
oPrint:Line (1410,600,1310,600)

//oPrint:SayBitMap (1300,0100,aBitMap[1],0115,0115) //  1234
oPrint:Say  (1344,100,aDadosBanco[2],oFont15)
//oPrint:Say  (1322,567,aDadosBanco[1]+"-0",oFont24)
oPrint:Say  (1322,340,aDadosBanco[1]+"-0",oFont24)
oPrint:Say  (1344,1890,"Via do Pagador",oFont16)


oPrint:Say  (1460,247 ,"Benefici·rio:"          ,oFont8)
oPrint:Say  (1520,156 ,"Nro.Documento:"    ,oFont8)
oPrint:Say  (1520,1500,"Nosso N˙mero:"     ,oFont8)
oPrint:Say  (1580,100 ,"Data do Documento:",oFont8)
oPrint:Say  (1580,1538,"Vencimento:"       ,oFont8)
oPrint:Say  (1640,241 ,"Valor R$:"         ,oFont8)

//oPrint:Say  (1458,400,aDadosEmp[1]+ " " +aDadosEmp[6]+ " " + aDadosEmp[2]+ " " + aDadosEmp[3] + " " +aDadosEmp[5],oFont10)
oPrint:Say  (1458,400,aDadosEmp[1],oFont10)
//oPrint:Say  (1468,1100," " +aDadosEmp[6]+ " " + aDadosEmp[2]+ " " + aDadosEmp[3] + " " +aDadosEmp[5],oFont11)


/*
oPrint:Say  (2235,100 ,aLLTRIM(aDadosEmp[1]),oFont10)
oPrint:Say  (2245,660 ,"  " + ALLTRIM(aDadosEmp[6]) + " End: " + aLLTRIM(aDadosEmp[2])+" CEP: " + ALLTRIM(aDadosEmp[3])                      ,oFont5)

*/


oPrint:Say  (1518,400,aDadosTit[1]                   ,oFont10)
//oPrint:Say  (1518,1725,_cNossoNum,oFont10)
oPrint:Say  (1518,1725,Substr(aDadosTit[6],1,3)+Substr(aDadosTit[6],4),oFont10)
oPrint:Say  (1578,400,Substring(DTOS(aDadosTit[3]),7,2)+"/"+Substring(DTOS(aDadosTit[3]),5,2)+"/"+ Substring(DTOS(aDadosTit[3]),1,4)             ,oFont10)
oPrint:Say  (1578,1725,Substring(DTOS(aDadosTit[4]),7,2)+"/"+Substring(DTOS(aDadosTit[4]),5,2)+"/"+ Substring(DTOS(aDadosTit[4]),1,4)            ,oFont10)


oPrint:Say  (1638,400,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10)

oPrint:Line (1710,100,1710,2300)
oPrint:Say  (1730,1000,"AutenticaÁ„o Mec‚nica",oFont8)

For i := 100 to 2300 step 50
	oPrint:Line( 1980, i, 1980, i+30)
Next i


oPrint:Line (2110,100,2110,2300)
//oPrint:Line (2110,550,2010,550 )
//oPrint:Line (2110,800,2010,800 )
oPrint:Line (2110,330,2010,330 )
oPrint:Line (2110,600,2010,600 )


oPrint:SayBitMap (1990,0100,aBitMap[1],0115,0115)
oPrint:Say  (2044,250,aDadosBanco[2],oFont10 )
//oPrint:Say  (2022,567,aDadosBanco[1]+"-0",oFont24 )   //?????????
oPrint:Say  (2022,340,aDadosBanco[1]+"-0",oFont24 )   //?????????

oPrint:Say  (2044,820,cLinhaDig[2],oFont14n)

oPrint:Line (2195,100,2195,2300 )
oPrint:Line (2290,100,2290,2300 )
oPrint:Line (2365,100,2365,2300 )
oPrint:Line (2435,100,2435,2300 )

oPrint:Line (2290,500,2435,500)
oPrint:Line (2365,750,2435,750)
oPrint:Line (2290,1000,2435,1000)
oPrint:Line (2290,1350,2365,1350)
oPrint:Line (2290,1550,2435,1550)

oPrint:Say  (2110,100 ,"Local de Pagamento"                                    ,oFont8)
oPrint:Say  (2150,100 ,"PREFERENCIALMENTE NAS CASAS LOT…RICAS AT… O VALOR LIMITE" ,oFont10)


oPrint:Say  (2110,1910,"Vencimento"                                     ,oFont8)
oPrint:Say  (2150,2010,Substring(DTOS(aDadosTit[4]),7,2)+"/"+Substring(DTOS(aDadosTit[4]),5,2)+"/"+ Substring(DTOS(aDadosTit[4]),1,4)                              ,oFont10)


oPrint:Say  (2195,100 ,"Benefici·rio"                                        ,oFont8)
//oPrint:Say  (2235,100 ,aDadosEmp[1]+ " " +aDadosEmp[6]+ " " + aDadosEmp[2]+ " " + aDadosEmp[3] + " " + aDadosEmp[4]             ,oFont10)
oPrint:Say  (2235,100 ,aLLTRIM(aDadosEmp[1]),oFont10)
oPrint:Say  (2245,850 ,"       " + ALLTRIM(aDadosEmp[6]) + " End: " + aLLTRIM(aDadosEmp[2]) + " " + ALLTRIM(aDadosEmp[3])+" " + aDadosEmp[4]  ,oFont11)

oPrint:Say  (2195,1910,"AgÍncia/CÛdigo Benefici·rio"                         ,oFont8)
oPrint:Say  (2235,2010,cAgencia+"/"+cCedente+"-"+xDig,oFont10)


oPrint:Say  (2295,100 ,"Data do Documento"                              ,oFont8)
oPrint:Say  (2325,100 ,Substring(DTOS(aDadosTit[3]),7,2)+"/"+Substring(DTOS(aDadosTit[3]),5,2)+"/"+ Substring(DTOS(aDadosTit[3]),1,4)                               ,oFont10)


oPrint:Say  (2295,505 ,"Nro.Documento"                                  ,oFont8)
oPrint:Say  (2325,605 ,aDadosTit[1]                                     ,oFont10)

oPrint:Say  (2295,1005,"EspÈcie Doc."                                   ,oFont8)
oPrint:Say  (2325,1105 ,"NF"                                             ,oFont10)

oPrint:Say  (2295,1355,"Aceite"                                         ,oFont8)
oPrint:Say  (2325,1455,"N"                                             ,oFont10)

oPrint:Say  (2295,1555,"Data do Processamento"                          ,oFont8)
oPrint:Say  (2325,1655,Substring(DTOS(aDadosTit[2]),7,2)+"/"+Substring(DTOS(aDadosTit[2]),5,2)+"/"+ Substring(DTOS(aDadosTit[2]),1,4) ,oFont10)


oPrint:Say  (2295,1910,"Nosso N˙mero"                                   ,oFont8)
oPrint:Say  (2325,1910,Substr(aDadosTit[6],1,3)+Substr(aDadosTit[6],4)                                       ,oFont10)


oPrint:Say  (2365,100 ,"Uso do Banco"                                   ,oFont8)

oPrint:Say  (2365,505 ,"Carteira"                                       ,oFont8)
oPrint:Say  (2395,550 ,"RG"                                            ,oFont10)

oPrint:Say  (2365,755 ,"Moeda"                                        ,oFont8)
oPrint:Say  (2395,805 ,"R$"                                             ,oFont10)

oPrint:Say  (2365,1005,"Qtde moeda"                                     ,oFont8)
oPrint:Say  (2365,1555,"xValor"                                          ,oFont8)

oPrint:Say  (2365,1910,"(=)Valor do Documento"                          ,oFont8)
oPrint:Say  (2395,2010,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10)

//oPrint:Say  (2435,100 ,"InstruÁıes (Todas informaÁıes deste bloqueto s„o de exclusiva responsabilidade do benefici·rio)",oFont8)
oPrint:Say  (2435,100 ,"InstruÁıes (Texto de Responsabilidade do Benefici·rio):",oFont10)
oPrint:Say  (2535,100 ,aBolText[2]                                      ,oFont10)
oPrint:Say  (2585,100 ,aBolText[1]                                      ,oFont10)
//oPrint:Say  (2635,100 ,aBolText[3]                                      ,oFont10)
//oPrint:Say  (2685,100 ,aBolText[4]                                      ,oFont10)

oPrint:Say  (2435,1910,"(-)Desconto/Abatimento"                         ,oFont8)
oPrint:Say  (2505,1910,"(-)Outras DeduÁıes"                             ,oFont8)
oPrint:Say  (2575,1910,"(+)Mora/Multa"                                  ,oFont8)
oPrint:Say  (2645,1910,"(+)Outros AcrÈscimos"                           ,oFont8)
oPrint:Say  (2715,1910,"(-)Valor Cobrado"                               ,oFont8)

oPrint:Say  (2795,100 ,"Pagador"                                         ,oFont8)
oPrint:Say  (2794,400 ,aDatSacado[1]+" ("+aDatSacado[2]+")"+"              CNPJ/CPF "+aDatSacado[7],oFont10)
oPrint:Say  (2836,400 ,aDatSacado[3]                                    ,oFont10)
oPrint:Say  (2878,400 ,aDatSacado[6] +  "  -  " + aDatSacado[4]+"     -     "+aDatSacado[5]               ,oFont10)
//oPrint:Say  (2920,400 ,aDatSacado[6]                                    ,oFont10)

oPrint:Say  (2920,100 ,"Pagador/Avalista                                                                                "     ,oFont8)
oPrint:Say  (2964,1865,"    Ficha de CompensaÁ„o"                           ,oFont10)
oPrint:Say  (2994,1865,"     AutenticaÁ„o Mec‚nica"                        ,oFont8)

oPrint:Line (2110,1900,2785,1900 )
oPrint:Line (2505,1900,2505,2300 )
oPrint:Line (2575,1900,2575,2300 )
oPrint:Line (2645,1900,2645,2300 )
oPrint:Line (2715,1900,2715,2300 )
oPrint:Line (2785,100 ,2785,2300 )
oPrint:Line (2956,100 ,2956,2300 )

//MSBAR2("INT25",25.5,2,cBarra,oPrint,.F.,,,,30,,,,.F.)
//MsBar("INT25"  ,25.5,2,cLinhaDig[1]  ,oPrint,.F.,,,nCBLargura,30,,,,.F.)

//MsBar("INT25"  ,25.5,2,cLinhaDig[1]  ,oPrint,.F.,,,nCBLargura,nCBAltura,,,,.F.)
MsBar("INT25"  ,25.9,2,cLinhaDig[1]  ,oPrint,.F.,,,nCBLargura,nCBAltura,,,,.F.)

DbSelectArea("SE1")
RecLock("SE1",.f.)

SE1->E1_NUMBCO :=	_cNossoNum

SE1->E1_PORTADO	:= 	"104"
SE1->E1_AGEDEP 	:=  "3525"
SE1->E1_CONTA	:=  "00483"


SE1->(MsUnlock())

Return Nil




/*/
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±⁄ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø±±
±±≥FunáÖo    ≥ Modulo10    ≥Descriá„o≥Faz a verificacao e geracao do digi-≥±±
±±≥          ≥             ≥         ≥to Verificador no Modulo 10.        ≥±±
±±¿ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
/*/
Static Function Modulo10(cData)
LOCAL L,D,P := 0
LOCAL B     := .F.
L := Len(cData)
B := .T.
D := 0
M := 2
While L > 0
	P := Val(SubStr(cData, L, 1))
		P := P * M
	    IF M = 2
	       M := 1
	    Else
	       M:= 2
	    Endif   
	    
		If P > 9           
		    P:= VAL(SUBSTR(STRZERO(P,2),1,1))+ VAL(SUBSTR(STRZERO(P,2),2,1))
			//P := P - 9
		End

	D := D + P
	L := L - 1
	
End
D := 10 - (Mod(D,10))
If D = 10
	D := 0
End
Return(D)
/*/
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±⁄ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø±±
±±≥FunáÖo    ≥ Modulo11    ≥Descriá„o≥Faz a verificacao e geracao do digi-≥±±
±±≥          ≥             ≥         ≥to Verificador no Modulo 11.        ≥±±
±±¿ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
/*/     klkk
Static Function Modulo11(cData)
LOCAL L, D, P := 0
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
//If (D == 0 .Or. D == 1 .Or. D == 10 .Or. D == 11)
If (D > 9 )
	D := 0
End
Return(D)
/*
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±⁄ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø±±
±±≥FunáÖo    ≥Ret_cBarra   ≥Descriá„o≥Gera a codificacao da Linha digitav.≥±±
±±≥          ≥             ≥         ≥gerando o codigo de barras.         ≥±±
±±¿ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
/*/
Static Function Ret_cBarra(cBanco,cAgencia,cConta,cDacCC,cNroDoc,nValor,dVencto)
//
LOCAL bldocnufinal := strzero(val(cNroDoc),8)
LOCAL blvalorfinal := strzero((nValor*100),10)
LOCAL dvnn         := 0
LOCAL dvcb         := 0
LOCAL dv           := 0
LOCAL NN           := ''
LOCAL RN           := ''
LOCAL CB           := ''
LOCAL s            := ''
LOCAL _cfator      := strzero(dVencto - ctod("07/10/97"),4)
//
//-------- Definicao do NOSSO NUMERO

/*
nossonumero       CONST1 CONST2 NNS1 NNS2 NNS3      BANCO MOEDA DIGITOCODBAR FATORVENC VALORDOC   CODBENEFICIARIO DIGITOBENEF DIGITOCLIVRE E2_CODBAR
----------------- ------ ------ ---- ---- --------- ----- ----- ------------ --------- ---------- --------------- ----------- ------------ ------------------------------------------------
71038002220090279 7      1      038  002  220090279 104   9     5            6765      0000006000 001550          4           2            10495676500000060000015504038700212200902792    
70308000000000188 7      0      308  000  000000188 104   9     7            6765      0000155000 003253          1           0            10497676500001550000032531308700000000001880    
70978000000000037 7      0      978  000  000000037 104   9     4            6775      0000636350 009441          8           3            10494677500006363500094418978700000000000373    
                                                                                                                                           10499677500006363500094412978700000000000377
10494677500006363500094418978700000000000373                                                                                                                                            
10499677500006363500094412978700000000000377  calc  
10499677500006363500094412978700000000000377?
70978000000000037 7      0      978  000  000000037 104   9     1            6787      0000469030 009441          8           8            10491678700004690300094418978700000000000378    
70978000000000038 7      0      978  000  000000038 104   9     1            6805      0000502850 009441          8           2            10491680500005028500094418978700000000000382    
70978000000000033 7      0      978  000  000000033 104   9     1            6653      0000838320 009441          8           1            10491665300008383200094418978700000000000331    
70978000000000036 7      0      978  000  000000036 104   9     8            6757      0000636350 009441          8           9            10498675700006363500094418978700000000000369    
70978000000000039 7      0      978  000  000000039 104   9     3            6836      0000436100 009441          8           2            10493683600004361000094418978700000000000392    
*/
//os 5 , pos 26, pos 44
//_cNossoNum:= "70978000000000037"
//_cNossoNum:= "14222333777777777"          
              
s:=_cNossoNum 
                                     

dvnn := modulo11(s) // digito verifacador Agencia + Conta + Carteira + Nosso Num
NN   := _cNossoNum + AllTrim(Str(dvnn))


/*////////////////
nCont:=0
cBarraImp3 	:= space(11)
cBarraImp3	:= _cNossoNum  // Subs(cBarra,19,11)
nCont	:= 0

nCont	:= nCont+(Val(Subs(cBarraImp3,17,1))*2)
nCont	:= nCont+(Val(Subs(cBarraImp3,16,1))*3)
nCont	:= nCont+(Val(Subs(cBarraImp3,15,1))*4)
nCont	:= nCont+(Val(Subs(cBarraImp3,14,1))*5)
nCont	:= nCont+(Val(Subs(cBarraImp3,13,1))*6)
nCont	:= nCont+(Val(Subs(cBarraImp3,12,1))*7)
nCont	:= nCont+(Val(Subs(cBarraImp3,11,1))*8)
nCont	:= nCont+(Val(Subs(cBarraImp3,10,1))*9)
nCont	:= nCont+(Val(Subs(cBarraImp3,09,1))*2)
nCont	:= nCont+(Val(Subs(cBarraImp3,08,1))*3)
nCont	:= nCont+(Val(Subs(cBarraImp3,07,1))*4)
nCont	:= nCont+(Val(Subs(cBarraImp3,06,1))*5)
nCont	:= nCont+(Val(Subs(cBarraImp3,05,1))*6)
nCont	:= nCont+(Val(Subs(cBarraImp3,04,1))*7)
nCont	:= nCont+(Val(Subs(cBarraImp3,03,1))*8)
nCont	:= nCont+(Val(Subs(cBarraImp3,02,1))*9)
nCont	:= nCont+(Val(Subs(cBarraImp3,01,1))*2)

nCont1  := int(nCont  / 11)
nCont2	:= ncont1 * 11
nResto  := ncont - ncont2
nResto  := 11 - nResto
if nResto > 9
	nResto := 0
	cBarraImp4 := cBarraImp3+"0"
	//Return("0")
else
	cBarraImp4 := cBarraImp3 + strzero(nResto,1)
	//Return(strzero(nResto,1))
EndIf

NN   := _cNossoNum + strzero(nResto,1)

////////////////*/

ccodbenef:="861807"  // digito 0   



 
dvCB:= str(modulo11(cCodBenef),1,0)
campolivre:= cCodBenef+dvCB+Substr(NN,3,3)+Substr(NN,1,1)+Substr(NN,6,3)+substr(NN,2,1)+substr(NN,9,9)
dvcl:=str(modulo11(campolivre),1,0)
//s    := cBanco +"9"+ _cfator + blvalorfinal + cCodBenef + dvCB + Substr(NN,3,3) + Substr(NN,1,1)+Substr(NN,6,3)+Substr(NN,2,1)+Substr(NN,9,9) +dvcl
s    := "104" +"9"+ _cfator + blvalorfinal + campolivre+dvcl

dvcba := modulo11(s)
If dvcba == 0
	dvcba:= 1
Endif                                                    
CB   := SubStr(s, 1, 4) + AllTrim(Str(dvcba)) + SubStr(s,5,39)

cCampo1:= Substr(CB,1,3) + Substr(CB,4,1) + Substr(CB,20,5)
cCampo1+=str(Modulo10(cCampo1),1,0)
cCampo2:= Substr(CB,25,10)
cCampo2+=str(Modulo10(cCampo2),1,0)
cCampo3:= Substr(CB,35,10)
cCampo3+=str(Modulo10(cCampo3),1,0)
cCampo4:= Substr(cb,5,1)
cCampo5:= Substr(CB,6,4)+ Substr(CB,10,10)

RN   := SUBSTR(cCampo1,1,5)+'.'+SUBSTR(cCampo1,6,5)+' ' + SUBSTR(cCampo2,1,5) +'.'+SUBSTR(cCampo2,6,6)+ ' ' + Substr(cCampo3,1,5)+'.'+substr(cCampo3,6,6)+' ' + cCampo4 + ' ' + cCampo5
Return({CB,RN,NN})
//
/*/
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±⁄ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø±±
±±≥FunáÖo    ≥ ValidPerg   ≥Descriá„o≥Verifica o Arquivo Sx1, criando as  ≥±±
±±≥          ≥             ≥         ≥Perguntas se necessario.            ≥±±
±±¿ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
/*/


Static Function ValidPerg()
Local _sAlias := Alias()
Local aRegs := {}
Local i,j
dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)
                                                    
AADD(aRegs, {cPerg,"01","Prefixo           ?","","","mv_ch1","C",03,0,0,"G","","mv_par01",""         ,""         ,"","","",""         ,""         ,"","","",""        ,""        ,"","","",""       ,""        ,"","","",""       ,""        ,"","","","","",""})
AADD(aRegs, {cPerg,"02","Titulo inicial    ?","","","mv_ch2","C",09,0,0,"G","","mv_par02",""         ,""         ,"","","",""         ,""         ,"","","",""        ,""        ,"","","",""       ,""        ,"","","",""       ,""        ,"","","","","",""})
AADD(aRegs, {cPerg,"03","Titulo final      ?","","","mv_ch3","C",09,0,0,"G","","mv_par03",""         ,""         ,"","","",""         ,""         ,"","","",""        ,""        ,"","","",""       ,""        ,"","","",""       ,""        ,"","","","","",""})
AADD(aRegs, {cPerg,"04","Da Parcela        ?","","","mv_ch4","C",02,0,0,"G","","mv_par04",""         ,""         ,"","","",""         ,""         ,"","","",""        ,""        ,"","","",""       ,""        ,"","","",""       ,""        ,"","","","","",""})
AADD(aRegs, {cPerg,"05","Ate Parcela       ?","","","mv_ch5","C",02,0,0,"G","","mv_par05",""         ,""         ,"","","",""         ,""         ,"","","",""        ,""        ,"","","",""       ,""        ,"","","",""       ,""        ,"","","","","",""})
AADD(aRegs, {cPerg,"06","Do Bordero        ?","","","mv_ch6","C",06,0,0,"G","","mv_par06",""         ,""         ,"","","",""         ,""         ,"","","",""        ,""        ,"","","",""       ,""        ,"","","",""       ,""        ,"","","","","",""})
AADD(aRegs, {cPerg,"07","Ate Bordero       ?","","","mv_ch7","C",06,0,0,"G","","mv_par07",""         ,""         ,"","","",""         ,""         ,"","","",""        ,""        ,"","","",""       ,""        ,"","","",""       ,""        ,"","","","","",""})



//AADD(aRegs, {cPerg,"06","Cliente Excessao 1 ","","","mv_ch6","C",06,0,0,"G","","mv_par06",""         ,""         ,"","","",""         ,""         ,"","","",""        ,""        ,"","","",""       ,""        ,"","","",""       ,""        ,"","","SA1","","",""})
//AADD(aRegs, {cPerg,"07","Cliente Excessao 2 ","","","mv_ch7","C",06,0,0,"G","","mv_par07",""         ,""         ,"","","",""         ,""         ,"","","",""        ,""        ,"","","",""       ,""        ,"","","",""       ,""        ,"","","SA1","","",""})
//AADD(aRegs, {cPerg,"08","Enviar por email?  ","","","mv_ch8","N",01,0,0,"C","","mv_par08","Sim"  ,"Sim"  ,"","","","Nao"   ,"Nao"   ,"","","",""          ,""          ,"","","",""        ,""        ,"","","",""       ,""        ,"","","   ","","",""})

dbGoTop()
For i:=1 to Len(aRegs)
	If !dbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j <= Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next
dbSelectArea(_sAlias)
Return




/*/


‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±⁄ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø±±
±±≥FunáÖo    ≥ CRIA_MV ≥DescriáÖo≥ Criacao dos Param.Necessarios no (SX6) ≥±±
±±¿ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
/*/
STATIC FUNCTION CRIA_MV()
//

dbSelectArea("SX6")
dbSetOrder(1)
//
If !dbSeek("  PV_BOL_LI1")
	RecLock("SX6",.T.)
	SX6->X6_FIL		:= "  "
	SX6->X6_VAR		:= "PV_BOL_LI1"
	SX6->X6_TIPO	:= "N"
	SX6->X6_DESCRIC	:= "NUMERO DA PRIMEIRA LINHA EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DSCSPA	:= "NUMERO DA PRIMEIRA LINHA EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DSCENG	:= "NUMERO DA PRIMEIRA LINHA EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DESC1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DSCSPA1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DSCENG1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DESC2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	SX6->X6_DSCSPA2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	SX6->X6_DSCENG2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	/*
	SX6->X6_CONTEUD	:= "6.8" //14.5
	SX6->X6_CONTSPA	:= "6.8"
	SX6->X6_CONTENG	:= "6.8"
	*/
	SX6->X6_CONTEUD	:= "12.9"
	SX6->X6_CONTSPA	:= "12.9"
	SX6->X6_CONTENG	:= "12.9"
	SX6->X6_PROPRI	:= "U"
	SX6->X6_PYME	:= ""
	MsUnLock()
Endif
//
If !dbSeek("  PV_BOL_LI2")
	RecLock("SX6",.T.)
	SX6->X6_FIL		:= "  "
	SX6->X6_VAR		:= "PV_BOL_LI2"
	SX6->X6_TIPO	:= "N"
	SX6->X6_DESCRIC	:= "NUMERO DA SEGUNDA LINHA EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DSCSPA	:= "NUMERO DA SEGUNDA LINHA EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DSCENG	:= "NUMERO DA SEGUNDA LINHA EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DESC1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DSCSPA1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DSCENG1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DESC2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	SX6->X6_DSCSPA2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	SX6->X6_DSCENG2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	/*	SX6->X6_CONTEUD	:= "12.0" //26.1
	SX6->X6_CONTSPA	:= "12.0"
	SX6->X6_CONTENG	:= "12.0"
	*/
	SX6->X6_CONTEUD	:= "26.1" //26.1
	SX6->X6_CONTSPA	:= "26.1"
	SX6->X6_CONTENG	:= "26.1"
	SX6->X6_PROPRI	:= "U"
	SX6->X6_PYME	:= ""
	MsUnLock()
Endif
//
If !dbSeek("  PV_BOL_COL")
	RecLock("SX6",.T.)
	SX6->X6_FIL		:= "  "
	SX6->X6_VAR		:= "PV_BOL_COL"
	SX6->X6_TIPO	:= "N"
	SX6->X6_DESCRIC	:= "NUMERO DA PRIMEIRA COLUNA EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DSCSPA	:= "NUMERO DA PRIMEIRA COLUNA EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DSCENG	:= "NUMERO DA PRIMEIRA COLUNA EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DESC1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DSCSPA1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DSCENG1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DESC2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	SX6->X6_DSCSPA2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	SX6->X6_DSCENG2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	SX6->X6_CONTEUD	:= "1.3" // 1.3
	SX6->X6_CONTSPA	:= "1.0"
	SX6->X6_CONTENG	:= "1.0"
	SX6->X6_PROPRI	:= "U"
	SX6->X6_PYME	:= ""
	MsUnLock()
Endif
//
If !dbSeek("  PV_BOL_LAR")
	RecLock("SX6",.T.)
	SX6->X6_FIL		:= "  "
	SX6->X6_VAR		:= "PV_BOL_LAR"
	SX6->X6_TIPO	:= "N"
	SX6->X6_DESCRIC	:= "TAMANHO DO CODIGO EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DSCSPA	:= "TAMANHO DO CODIGO EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DSCENG	:= "TAMANHO DO CODIGO EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DESC1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DSCSPA1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DSCENG1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DESC2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	SX6->X6_DSCSPA2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	SX6->X6_DSCENG2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	SX6->X6_CONTEUD	:= "0.0280" // 0.0280
	SX6->X6_CONTSPA	:= "0.0140"
	SX6->X6_CONTENG	:= "0.0140"
	SX6->X6_PROPRI	:= "U"
	SX6->X6_PYME	:= ""
	MsUnLock()
Endif
//
If !dbSeek("  PV_BOL_ALT")
	RecLock("SX6",.T.)
	SX6->X6_FIL		:= "  "
	SX6->X6_VAR		:= "PV_BOL_ALT"
	SX6->X6_TIPO	:= "N"
	SX6->X6_DESCRIC	:= "ALTURA DO CODIGO EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DSCSPA	:= "ALTURA DO CODIGO EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DSCENG	:= "ALTURA DO CODIGO EM (CM) PARA IMPRESSAO DO "
	SX6->X6_DESC1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DSCSPA1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DSCENG1	:= "CODIGO DE BARRAS (PODENDO VARIAR CONFORME DRIVER "
	SX6->X6_DESC2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	SX6->X6_DSCSPA2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	SX6->X6_DSCENG2	:= "DA IMPRESSORA) - A SER USADO NO BOLETO ITAU."
	SX6->X6_CONTEUD	:= "1.40"
	SX6->X6_CONTSPA	:= "0.50"
	SX6->X6_CONTENG	:= "0.50"
	SX6->X6_PROPRI	:= "U"
	SX6->X6_PYME	:= ""
	MsUnLock()
Endif
//
RETURN()
