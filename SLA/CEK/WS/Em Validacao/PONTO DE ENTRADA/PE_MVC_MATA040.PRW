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
*/

user function Ma040VLD()

Local _nOpc := PARAMIXB     //3- Inclusão, 4- Alteração e 5- Exclusão
Local _lRet := .T.
Local _cUsuario := RetCodUsr()


IF(_nOpc == 3 .OR. _nOpc == 4 .OR. _nOpc == 5)
	IF (M->(FIELDPOS('A3_WSDTALT')>0))
		msginfo('verificar se data foi alterada')
		M->A3_WSDTALT :=DTOS(DATE())+STRTRAN(TIME(),':','')
	Else
		msginfo(' campo ws data não encontrado')
	ENDIF
ENDIF

RETURN _lRet

