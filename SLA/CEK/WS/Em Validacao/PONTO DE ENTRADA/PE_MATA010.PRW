#Include "TOTVS.ch"
#Include "FWMVCDEF.ch"

//PONTO DE ENTRADA MVC - ALTERAÇÃO DE PRODUTO

User Function ITEM()
 Local aParam := PARAMIXB
 Local xRet := .T.
 Local oObj := ""
 Local cIdPonto := ""
 Local cIdModel := ""
// Local cMsg := ""
 Local nOpc
 Local lIsGrid := .f.

//ApMsgInfo('Chamada MATA010')

//EECVIEW(VARINFO('aParam',aParam),'MATA010')

If (aParam <> NIL)
	oObj := aParam[1]
	cIdPonto := aParam[2]
	cIdModel := aParam[3]
	

	//ApMsgInfo('Chamada mvc.' + CRLF + 'ID ' + cIdModel)

	nOpc := oObj:GetOperation() // PEGA A OPERAÇÃO

	If (cIdPonto == "MODELPOS")
		//cMsg := "Chamada na validação total do modelo." + CRLF
		//cMsg += "ID " + cIdModel + CRLF]
		IF nOpc == 3
			//Alert('inclusão')
		ElseIF nOpc == 4
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
		//MsgInfo("Chamada após a gravação da tabela do formulário. nop:"+cvaltochar(nOpc))

		IF(nOpc=3 .or. nOpc=4 .or. nOpc=5)
			RECLOCK('SB1',.F.)					
			If (SB1->(FIELDPOS('B1_WSDTALT'))>0)
				SB1->B1_WSDTALT :=DTOS(DATE())+STRTRAN(TIME(),':','')
			EndIf
			
			If(nOpc=3)
				//MsgInfo("APAGA O CODBAR2","MATA010")
				SB1->B1_CODBAR2 := ' '
			EndIf
			
			SB1->(MSUNLOCK())
			
			
			//GERA CODIGO DE BARRAS PRODUTO
			If(nOpc=3 .or. nOpc=4)
				u_CEKA001(SB1->B1_COD)
			EndIf
			
		EndIf
	ElseIf (cIdPonto =="MODELCANCEL")
		//cMsg := "Deseja realmente sair?"
		//xRet := MsgYesNo(cMsg)
	ElseIf (cIdPonto =="BUTTONBAR")
		//xRet := {{"Botão", "BOTÃO", {|| MsgInfo("Buttonbar")}}}
	EndIf
	
EndIf

Return (xRet)
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