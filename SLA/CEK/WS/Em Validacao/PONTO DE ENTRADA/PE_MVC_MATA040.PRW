#Include "TOTVS.ch"
#Include "FWMVCDEF.ch"

//Ponto de Entrada mvc não está funcionando
/*
User Function MATA040()
 Local aParam := PARAMIXB
 Local xRet := .T.
 Local oObj := ""
 Local cIdPonto := ""
 Local cIdModel := ""
 Local cMsg := ""
 Local nOp



If (aParam <> NIL)
	oObj := aParam[1]
	cIdPonto := aParam[2]
	cIdModel := aParam[3]
	

	ApMsgInfo('Chamada mvc.' + CRLF + 'ID ' + cIdModel)

	nOpc := oObj:GetOperation() // PEGA A OPERAÇÃO

	If (cIdPonto == "MODELPOS")
		//cMsg := "Chamada na validação total do modelo." + CRLF
		//cMsg += "ID " + cIdModel + CRLF]
		IF nOp == 3
			//Alert('inclusão')
		ElseIF nOp == 4
			//Alert('alteração')
		ENDIF

		//xRet := MsgYesNo(cMsg + "Continua?")
	ElseIf (cIdPonto == "MODELVLDACTIVE")
		//cMsg := "Chamada na ativação do modelo de dados."
		//xRet := MsgYesNo(cMsg + "Continua?")
	ElseIf (cIdPonto == "FORMPOS")
		//cMsg := "Chamada na validação total do formulário." + CRLF
		//cMsg += "ID " + cIdModel + CRLF

		If (lIsGrid == .T.)
			//cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
			//cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
		Else
			//cMsg += "É um FORMFIELD" + CRLF
		EndIf
		//xRet := MsgYesNo(cMsg + "Continua?")
	ElseIf (cIdPonto =="FORMLINEPRE")
		If aParam[5] =="DELETE"
			//cMsg := "Chamada na pré validação da linha do formulário." + CRLF
			//cMsg += "Onde esta se tentando deletar a linha" + CRLF
			//cMsg += "ID " + cIdModel + CRLF
			
			//cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
			
			//cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
			
			//xRet := MsgYesNo(cMsg + " Continua?")
			
		EndIf
	ElseIf (cIdPonto =="FORMLINEPOS")
		//cMsg := "Chamada na validação da linha do formulário." + CRLF
		//cMsg += "ID " + cIdModel + CRLF
		//cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
		//cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
		
		//xRet := MsgYesNo(cMsg + " Continua?")
		
	ElseIf (cIdPonto =="MODELCOMMITTTS")
		//MsgInfo("Chamada após a gravação total do modelo e dentro da transação.")
	ElseIf (cIdPonto =="MODELCOMMITNTTS")
		//MsgInfo("Chamada após a gravação total do modelo e fora da transação.")
	ElseIf (cIdPonto =="FORMCOMMITTTSPRE")
		//MsgInfo("Chamada após a gravação da tabela do formulário.")
	ElseIf (cIdPonto =="FORMCOMMITTTSPOS")
		MsgInfo("Chamada após a gravação da tabela do formulário.")
		IF (SA3->(FIELDPOS('A3_WSDTALT')>0))
			RECLOCK('SA3',.F.)
				SA3->A3_WSDTALT :=DTOS(DATE())+STRTRAN(TIME(),':','')
			SA3->(MSUNLOCK())
		ENDIF
	ElseIf (cIdPonto =="MODELCANCEL")
		//cMsg := "Deseja realmente sair?"
		//xRet := MsgYesNo(cMsg)
	ElseIf (cIdPonto =="BUTTONBAR")
		//xRet := {{"Botão", "BOTÃO", {|| MsgInfo("Buttonbar")}}}
	EndIf
	
EndIf

Return (xRet)

RETURN _lRet
*/

//Condição de pagamento
User Function MATA360()
 Local aParam := PARAMIXB
 Local xRet := .T.
 Local oObj := ""
 Local cIdPonto := ""
 Local cIdModel := ""
 //Local cMsg := ""
 Local nOp
 Local lIsGrid := .f.



If (aParam <> NIL)
	oObj := aParam[1]
	cIdPonto := aParam[2]
	cIdModel := aParam[3]
	

//	ApMsgInfo('Chamada mvc.' + CRLF + 'ID ' + cIdModel)

	nOpc := oObj:GetOperation() // PEGA A OPERAÇÃO

	If (cIdPonto == "MODELPOS")
		//cMsg := "Chamada na validação total do modelo." + CRLF
		//cMsg += "ID " + cIdModel + CRLF]
		IF nOp == 3
			//Alert('inclusão')
		ElseIF nOp == 4
			//Alert('alteração')
		ENDIF

		//xRet := MsgYesNo(cMsg + "Continua?")
	ElseIf (cIdPonto == "MODELVLDACTIVE")
		//cMsg := "Chamada na ativação do modelo de dados."
		//xRet := MsgYesNo(cMsg + "Continua?")
	ElseIf (cIdPonto == "FORMPOS")
		//cMsg := "Chamada na validação total do formulário." + CRLF
		//cMsg += "ID " + cIdModel + CRLF

		If (lIsGrid == .T.)
			//cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
			//cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
		Else
			//cMsg += "É um FORMFIELD" + CRLF
		EndIf
		//xRet := MsgYesNo(cMsg + "Continua?")
	ElseIf (cIdPonto =="FORMLINEPRE")
		If aParam[5] =="DELETE"
			//cMsg := "Chamada na pré validação da linha do formulário." + CRLF
			//cMsg += "Onde esta se tentando deletar a linha" + CRLF
			//cMsg += "ID " + cIdModel + CRLF
			
			//cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
			
			//cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
			
			//xRet := MsgYesNo(cMsg + " Continua?")
			
		EndIf
	ElseIf (cIdPonto =="FORMLINEPOS")
		//cMsg := "Chamada na validação da linha do formulário." + CRLF
		//cMsg += "ID " + cIdModel + CRLF
		//cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
		//cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
		
		//xRet := MsgYesNo(cMsg + " Continua?")
		
	ElseIf (cIdPonto =="MODELCOMMITTTS")
		//MsgInfo("Chamada após a gravação total do modelo e dentro da transação.")
	ElseIf (cIdPonto =="MODELCOMMITNTTS")
		//MsgInfo("Chamada após a gravação total do modelo e fora da transação.")
	ElseIf (cIdPonto =="FORMCOMMITTTSPRE")
		//MsgInfo("Chamada após a gravação da tabela do formulário.")
	ElseIf (cIdPonto =="FORMCOMMITTTSPOS")
		//MsgInfo("Chamada após a gravação da tabela do formulário.")
		IF (SE4->(FIELDPOS('E4_WSDTALT')>0))
			RECLOCK('SE4',.F.)
				SE4->E4_WSDTALT :=DTOS(DATE())+STRTRAN(TIME(),':','')
			SE4->(MSUNLOCK())
		ENDIF
	ElseIf (cIdPonto =="MODELCANCEL")
		//cMsg := "Deseja realmente sair?"
		//xRet := MsgYesNo(cMsg)
	ElseIf (cIdPonto =="BUTTONBAR")
		//xRet := {{"Botão", "BOTÃO", {|| MsgInfo("Buttonbar")}}}
	EndIf
	
EndIf

Return (xRet)

//Tabela de Preço
User Function OMSA010()
 Local aParam := PARAMIXB
 Local xRet := .T.
 Local oObj := ""
 Local cIdPonto := ""
 Local cIdModel := ""
// Local cMsg := ""
 Local nOp, nQtdLinhas, nLinha
 Local  lIsGrid := .f.



If (aParam <> NIL)
	oObj := aParam[1]
	cIdPonto := aParam[2]
	cIdModel := aParam[3]

	lIsGrid := ( Len( aParam ) > 3 )

	If lIsGrid
		//nQtdLinhas := oObj:GetQtdLine()
		//nLinha := oObj:nLine
	EndIf 	

	//ApMsgInfo('Chamada mvc.' + CRLF + 'ID ' + cIdModel)

	nOpc := oObj:GetOperation() // PEGA A OPERAÇÃO

	If (cIdPonto == "MODELPOS")
		//cMsg := "Chamada na validação total do modelo." + CRLF
		//cMsg += "ID " + cIdModel + CRLF]
		IF nOp == 3
			//Alert('inclusão')
		ElseIF nOp == 4
			//Alert('alteração')
		ENDIF

		//xRet := MsgYesNo(cMsg + "Continua?")
	ElseIf (cIdPonto == "MODELVLDACTIVE")
		//cMsg := "Chamada na ativação do modelo de dados."
		//xRet := MsgYesNo(cMsg + "Continua?")
	ElseIf (cIdPonto == "FORMPOS")
		//cMsg := "Chamada na validação total do formulário." + CRLF
		//cMsg += "ID " + cIdModel + CRLF

		If (lIsGrid == .T.)
			//cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
			//cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
		Else
			//cMsg += "É um FORMFIELD" + CRLF
		EndIf
		//xRet := MsgYesNo(cMsg + "Continua?")
	ElseIf (cIdPonto =="FORMLINEPRE")
		If aParam[5] =="DELETE"
			//cMsg := "Chamada na pré validação da linha do formulário." + CRLF
			//cMsg += "Onde esta se tentando deletar a linha" + CRLF
			//cMsg += "ID " + cIdModel + CRLF
			
			//cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
			
			//cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
			
			//xRet := MsgYesNo(cMsg + " Continua?")
			
		EndIf
	ElseIf (cIdPonto =="FORMLINEPOS")
		//cMsg := "Chamada na validação da linha do formulário." + CRLF
		//cMsg += "ID " + cIdModel + CRLF
		//cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
		//cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
		
		oModelx := FWModelActive()
		oModelxDet := oModelx:GetModel('DA1DETAIL')
		oModelxDet:SetValue('DA1_WSDTAL',DTOS(DATE())+STRTRAN(TIME(),':',''))
		
		//xRet := MsgYesNo(cMsg + " Continua?")
		
	ElseIf (cIdPonto =="MODELCOMMITTTS")
		//MsgInfo("Chamada após a gravação total do modelo e dentro da transação.")
	ElseIf (cIdPonto =="MODELCOMMITNTTS")
		//MsgInfo("Chamada após a gravação total do modelo e fora da transação.")
	ElseIf (cIdPonto =="FORMCOMMITTTSPRE")
		//MsgInfo("Chamada após a gravação da tabela do formulário.")
	ElseIf (cIdPonto =="FORMCOMMITTTSPOS")
		//MsgInfo("Chamada após a gravação da tabela do formulário.")
		IF (DA0->(FIELDPOS('DA0_WSDTAL')>0))
			RECLOCK('DA0',.F.)
				DA0->DA0_WSDTAL :=DTOS(DATE())+STRTRAN(TIME(),':','')
			DA0->(MSUNLOCK())
		ENDIF
		
	ElseIf (cIdPonto =="MODELCANCEL")
		//cMsg := "Deseja realmente sair?"
		//xRet := MsgYesNo(cMsg)
	ElseIf (cIdPonto =="BUTTONBAR")
		//xRet := {{"Botão", "BOTÃO", {|| MsgInfo("Buttonbar")}}}
	EndIf
	
EndIf

Return (xRet)

//alteração de vendedores
user Function MA040VLD()
 
Local _nOpc := PARAMIXB     //3- Inclusão, 4- Alteração e 5- Exclusão
Local _lRet := .T.
//Local _cUsuario := RetCodUsr()

//msgalert("MA040VLD - NOPC"+CVALTOCHAR(_nOpc),"ponto de entrada")

If _nOpc == 3 .OR. _nOpc == 4 .OR. _nOpc == 5
	U_VLDWSALT("A3_WSDTALT")
EndIf
 
Return _lRet
*/
USER FUNCTION VLDWSALT(_cCampo)

	IF(!EMPTY(_cCampo))
		M->(&(_cCampo )):= DTOS(DATE())+STRTRAN(TIME(),':','')
		MSGALERT(&(_cCampo),_cCampo)
	ENDIF
	

RETURN .T.


//alteração de produtos
/*
User Function MT010ALT()
    Local aArea := GetArea()
     msginfo('MT010ALT')
    //Grava o usuário que alterou
		RECLOCK('SB1',.F.)		
			IF (SB1->(FIELDPOS('B1_WSDTALT')>0))
					SB1->B1_WSDTALT :=DTOS(DATE())+STRTRAN(TIME(),':','')
			ENDIF
			IF(lINCLUI)
				SB1->B1_CODBAR2 :=' '
			ENDIF
		SB1->(MSUNLOCK())
     
    RestArea(aArea)
Return .T.
*/

//alteração de Fornecedores
User Function CUSTOMERVENDOR()
 Local aParam := PARAMIXB
 Local xRet := .T.
 Local oObj := ""
 Local cIdPonto := ""
 Local cIdModel := ""
// Local cMsg := ""
 Local nOp
 Local lIsGrid := .f.

//ApMsgInfo('Chamada MATA010')

If (aParam <> NIL)
	oObj := aParam[1]
	cIdPonto := aParam[2]
	cIdModel := aParam[3]
	

	//ApMsgInfo('Chamada mvc.' + CRLF + 'ID ' + cIdModel)

	nOpc := oObj:GetOperation() // PEGA A OPERAÇÃO

	If (cIdPonto == "MODELPOS")
		//cMsg := "Chamada na validação total do modelo." + CRLF
		//cMsg += "ID " + cIdModel + CRLF]
		IF nOp == 3
			//Alert('inclusão')
		ElseIF nOp == 4
			//Alert('alteração')
		ENDIF

		//xRet := MsgYesNo(cMsg + "Continua?")
	ElseIf (cIdPonto == "MODELVLDACTIVE")
		//cMsg := "Chamada na ativação do modelo de dados."
		//xRet := MsgYesNo(cMsg + "Continua?")
	ElseIf (cIdPonto == "FORMPOS")
		//cMsg := "Chamada na validação total do formulário." + CRLF
		//cMsg += "ID " + cIdModel + CRLF

		If (lIsGrid == .T.)
			//cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
			//cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
		Else
			//cMsg += "É um FORMFIELD" + CRLF
		EndIf
		//xRet := MsgYesNo(cMsg + "Continua?")
	ElseIf (cIdPonto =="FORMLINEPRE")
		If aParam[5] =="DELETE"
			//cMsg := "Chamada na pré validação da linha do formulário." + CRLF
			//cMsg += "Onde esta se tentando deletar a linha" + CRLF
			//cMsg += "ID " + cIdModel + CRLF
			
			//cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
			
			//cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
			
			//xRet := MsgYesNo(cMsg + " Continua?")
			
		EndIf
	ElseIf (cIdPonto =="FORMLINEPOS")
		//cMsg := "Chamada na validação da linha do formulário." + CRLF
		//cMsg += "ID " + cIdModel + CRLF
		//cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
		//cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
		
		//xRet := MsgYesNo(cMsg + " Continua?")
		
	ElseIf (cIdPonto =="MODELCOMMITTTS")
		//MsgInfo("Chamada após a gravação total do modelo e dentro da transação.")
	ElseIf (cIdPonto =="MODELCOMMITNTTS")
		//MsgInfo("Chamada após a gravação total do modelo e fora da transação.")
	ElseIf (cIdPonto =="FORMCOMMITTTSPRE")
		//MsgInfo("Chamada após a gravação da tabela do formulário.")
	ElseIf (cIdPonto =="FORMCOMMITTTSPOS")
		//MsgInfo("Chamada após a gravação da tabela do formulário.")
		RECLOCK('SA2',.F.)		
		IF(nOp=3 .or. nOp=4 .or. nOp=5)
			IF (SA2->(FIELDPOS('A2_WSDTALT')>0))
				SA2->A2_WSDTALT :=DTOS(DATE())+STRTRAN(TIME(),':','')
			EndIf
		EndIf
		SA3->(MSUNLOCK())
	ElseIf (cIdPonto =="MODELCANCEL")
		//cMsg := "Deseja realmente sair?"
		//xRet := MsgYesNo(cMsg)
	ElseIf (cIdPonto =="BUTTONBAR")
		//xRet := {{"Botão", "BOTÃO", {|| MsgInfo("Buttonbar")}}}
	EndIf
	
EndIf

Return (xRet)

//gravação do campo de data de alteração do titulo 

USER FUNCTION FA040ALT()

	M->E1_WSDTALT := DTOS(DATE())+STRTRAN(TIME(),':','')

RETURN .T.

//gravação de data de eleiminação de residuo de pedido
USER FUNCTION M410VRES()

	RECLOCK("SC5",.F.)
		SC5->C5_WSDTALT := DTOS(DATE())+STRTRAN(TIME(),':','')
	SC5->(MSUNLOCK())
	
RETURN .T.

//
/*
USER FUNCTION MA040TOK()

IF(ALTERA .OR. INCLUI)
	MSGALERT("MA040TOK ALTERA:"+CVALTOCHAR(ALTERA)+" - INCLUI:"+CVALTOCHAR(INCLUI)+" - A3_WSDTALT("+CVALTOCHAR(M->A3_WSDTALT)+")!","")
	M->A3_WSDTALT :=  DTOS(DATE())+STRTRAN(TIME(),':','')
ENDIF 

RETURN .T.
*/



