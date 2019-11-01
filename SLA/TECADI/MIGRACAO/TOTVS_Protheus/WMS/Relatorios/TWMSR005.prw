#Include 'Protheus.ch'
#Include 'TopConn.ch'
#Include 'FWPrintSetup.ch'
#Include 'RPTDEF.CH'

//------------------------------------------------------------------------------//
// Programa: TWMRS005()  |   Autor: Gustavo Schumann / SLA TI | Data: 23/08/2018//
//------------------------------------------------------------------------------//
// Descrição: Lacre de Container.												//
//------------------------------------------------------------------------------//

User Function TWMSR005()
	Private cPerg := PADR("TWMRS005",10)

	ValidPerg()

	//=============================================================================================
	If Pergunte(cPerg,.T.,"Lacre de Container")
		If EMPTY(MV_PAR01) .Or. EMPTY(MV_PAR02) .Or. EMPTY(MV_PAR03) .Or. EMPTY(MV_PAR04) .Or. EMPTY(MV_PAR05)
			MsgAlert("Todos os campos devem ser preenchidos!","TWMRS005")
		Else
			U_WMSR005A(MV_PAR01,MV_PAR02,MV_PAR03,MV_PAR04,MV_PAR05)
		EndIf
	EndIf
	//=============================================================================================

Return
//-------------------------------------------------------------------------------------------------
Static Function ValidPerg()
	Local i	:= 0
	Local j	:= 0

	_sAlias := Alias()
	dbSelectArea("SX1")
	dbSetOrder(1)
	cPerg := PADR(cPerg,10)
	aRegs:={}

	AADD(aRegs,{cPerg,"01","NUMERO DA PROGRAMACAO ?	","","","mv_ch1","C",06,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SZ1","","","",""})
	AADD(aRegs,{cPerg,"02","CLIENTE ?				","","","mv_ch2","C",06,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","",""})
	AADD(aRegs,{cPerg,"03","LOJA ?					","","","mv_ch3","C",02,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPerg,"04","NUMERO DO CONTEINER ?	","","","mv_ch4","C",11,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","SZC","","","",""})
	AADD(aRegs,{cPerg,"05","NUMERO DO LACRE ?		","","","mv_ch5","C",15,0,0,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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
//-------------------------------------------------------------------------------------------------
User Function WMSR005A(MV_PAR01,MV_PAR02,MV_PAR03,MV_PAR04,MV_PAR05)
	Local cNumProg	:= AllTrim(MV_PAR01)
	Local cCliente	:= SubStr(Posicione("SA1",1,xFilial("SA1")+MV_PAR02+MV_PAR03,"A1_NOME"),1,22)
	Local cCont		:= AllTrim(MV_PAR04)
	Local cLacre	:= AllTrim(MV_PAR05)
	Local oFont		:= TFont():New("Arial",48,48,,.T.,,,,.T.,.F.)
	Local oPrn

	oPrn := FWMSPrinter():New('LCONT'+AllTrim(Str(Randomize(1,10000))),IMP_PDF,.F.,,.T.)
	oPrn:SetPortrait()
	oPrn:SetPaperSize(DMPAPER_A4)
	oPrn:SetMargin(10,10,10,10)
	oPrn:cPathPDF := "c:\temp\"
	oPrn:Setup()

	oPrn:StartPage()

	oPrn:say(0070, 0015, cNumProg			,oFont)
	oPrn:say(0150, 0015, cCliente			,oFont)
	oPrn:say(0250, 0015, "ID: " + cCont		,oFont)
	oPrn:say(0350, 0015, "LACRE: " + cLacre	,oFont)

	oPrn:say(0520, 0015, cNumProg			,oFont)
	oPrn:say(0600, 0015, cCliente			,oFont)
	oPrn:say(0700, 0015, "ID: " + cCont		,oFont)
	oPrn:say(0800, 0015, "LACRE: " + cLacre	,oFont)

	oPrn:EndPage()

	oPrn:Preview()
	FreeObj(oPrn)
	oPrn := Nil

Return