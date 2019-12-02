// ###########################################################################################
// Projeto: PowerSolution
// Modulo : Estoques
// Fonte  : MT103FIM
// ---------+-------------------------+-------------------------------------------------------
// Data     | Autor: Rafael Fernandes | Ponto de entrada na gravação do documento de entrada
// ---------+-------------------------+-------------------------------------------------------
// 02/04/13 | TOTVS Developer Studio  | 
// ---------+-------------------------+-------------------------------------------------------

#Include 'Protheus.ch'
#Include 'Rwmake.ch'

User Function MT103FIM()

	Local nOpcao := PARAMIXB[1]
	Local nConfirma := PARAMIXB[2]
	
	If nOpcao == 3 .And. nConfirma == 1
	
		If msgYesNo('Deseja imprimir etiquetas?','[MT103FIM] Impressão de etiquetas')
	
			sfTela()
			
		Endif
	
	Endif

Return

Static Function sfTela()

	Local aBrw := sfEstrut()
	Local aTrb := sfEstTRB()
	
	Local cArq := ''
	
	Private lInverte := .F.
	
	Private cMarca := GetMark()
	
	SetPrvt('oDlg','oBrw','oBtn1','oBtn2','oPanel','oSay')
	
	If Select('TRB') <> 0
		TRB->(dbCloseArea())
	Endif
	
	cArq := criaTrab(aTrb,.T.)
	
	dbUseArea(.T.,,cArq,'TRB',.T.)
	
	sfFilTRB()
	
	TRB->(dbGoTop())
	
	oFont  := TFont():New('Arial',0,-11,,.T.,0,,700,.F.,.F.,,,,,, )
	oFont2 := TFont():New('Arial',0,-18,,.T.,0,,700,.F.,.F.,,,,,, ) 
	
	oDlg := MSDialog():New(141,046,585,918,'[MT103FIM] Itens da Nota Fiscal de Entrada',,,.F.,,,,,,.T.,,,.T. )
	oBrw := MsSelect():New('TRB','OK','',aBrw,@lInverte,@cMarca,{025,004,200,435},,, oDlg )
	
	oBrw:oBrowse:lHasMark    := .T.
	oBrw:oBrowse:lCanAllMark := .T.
	oBrw:bAval := {|| sfFuncMarca() } 
	oBrw:OBROWSE:BLDBLCLICK := {|| telaAlt() }
	
	oBrw:oBrowse:bAllMark := {|| marcaTudo()}
	
	oBtn1 := TButton():New(207,320,'Imprimir',oDlg,{||sfPrint(),oDlg:End()},052,012,,,,.T.,,"",,,,.F. )
	oBtn2 := TButton():New(207,380,'Sair',oDlg,{||oDlg:End()},052,012,,,,.T.,,"",,,,.F. )
	
	oSay  := TSay():New(006,163,{||'| Impressão de etiquetas |'},,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,180,020)

	oDlg:Activate(,,,.T.)
	
Return

Static Function sfEstrut()

	Local aRet := {}
	
	aAdd(aRet,{'OK'     ,,'[X]',})
	aAdd(aRet,{'ITEM'   ,,RetTitle('D1_ITEM'),X3Picture('D1_ITEM')})
	aAdd(aRet,{'CODPRD' ,,RetTitle('D1_COD') ,X3Picture('D1_COD')})
	aAdd(aRet,{'DESCPRD',,RetTitle('B1_DESC'),X3Picture('B1_DESC')})
	aAdd(aRet,{'UM'     ,,RetTitle('D1_UM')  ,X3Picture('D1_UM')})
	aAdd(aRet,{'QUANTS' ,,'Qtd. NF Entrada'  ,X3Picture('D1_TOTAL')})
	aAdd(aRet,{'QUANTI' ,,'Qtd. impressão'   ,X3Picture('D1_TOTAL')})

Return aRet

Static Function sfEstTRB()

	Local aRet := {}
	
	aAdd(aRet,{'OK'     ,'C'						,2                    ,0})
	aAdd(aRet,{'ITEM'   ,TamSX3('D1_ITEM')[3]	,TamSX3('D1_ITEM')[1] ,TamSX3('D1_ITEM')[2]})
	aAdd(aRet,{'CODPRD' ,TamSX3('D1_COD')[3]  ,TamSX3('D1_COD')[1]  ,TamSX3('D1_COD')[2]})
	aAdd(aRet,{'DESCPRD',TamSX3('B1_DESC')[3]	,TamSX3('B1_DESC')[1] ,TamSX3('B1_DESC')[2]})
	aAdd(aRet,{'UM'     ,TamSX3('D1_UM')[3]	,TamSX3('D1_UM')[1]   ,TamSX3('D1_UM')[2]})
	aAdd(aRet,{'QUANTI' ,TamSX3('D1_TOTAL')[3],TamSX3('D1_TOTAL')[1],TamSX3('D1_TOTAL')[2]})
	aAdd(aRet,{'QUANTS' ,TamSX3('D1_TOTAL')[3],TamSX3('D1_TOTAL')[1],TamSX3('D1_TOTAL')[2]}) 

Return aRet

Static Function sfFilTRB()
	
	For i := 1 to Len(aCols)
	
		RecLock('TRB',.T.)
			TRB->ITEM    := aCols[i][1]
			TRB->CODPRD  := aCols[i][2]
			TRB->DESCPRD := Posicione('SB1',1,xFilial('SB1') + TRB->CODPRD,'B1_DESC')
			TRB->UM      := aCols[i][3]
			TRB->QUANTI  := aCols[i][5]
			TRB->QUANTS  := aCols[i][5]
		MsUnlock('TRB')
		
	Next i
	
	TRB->(dbGoTop())

Return

Static Function telaAlt()

	Local nQtd			:= TRB->QUANTI
	Local nOpc			:= 0

	SetPrvt('oDlg1','oSay1','oGet1','oBtn1','oBtn2')
	
	oDlg1 := MSDialog():New(282,398,396,607,'Informe a quantidade',,,.F.,,,,,,.T.,,,.T.)
	oSay1 := TSay():New(008,004,{||'Quantidade:'},oDlg1,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,044,008)
	oGet1 := TGet():New(020,004,{|u| If(PCount()>0,nQtd:=u,nQtd)},oDlg1,060,008,'@E 9,999,999.99',,CLR_BLACK,CLR_WHITE,,,,.T.,'',,,.F.,.F.,,.F.,.F.,'','',,)
	oBtn1 := TButton():New(040,025,'Ok',oDlg1,{||sfMarca(nQtd),oDlg1:End()},037,012,,,,.T.,,'',,,,.F. )
	oBtn2 := TButton():New(040,065,'Cancelar',oDlg1,{||sfCancela(),oDlg1:End()},037,012,,,,.T.,,'',,,,.F. )
	
	oDlg1:Activate(,,,.T.)

Return

Static Function sfMarca(nQuant)

	RecLock('TRB',.F.)
		TRB->OK     := cMarca
		TRB->QUANTI := nQuant
	MsUnlock('TRB')

Return

Static Function sfCancela()

	RecLock('TRB',.F.)
		TRB->OK    := ''
		TRB->QUANTI := 0
	MsUnlock('TRB')

Return

Static Function sfFuncMarca()

	Local nReg := TRB->(RECNO())
	Local cMar := .F.
	
	RecLock("TRB",.F.)	
		If TRB->OK == cMarca
			TRB->OK := "  "
		Else
			TRB->OK := cMarca
			cMar    := .T.
		EndIf
	MsUnlock("TRB")
	
	TRB->(DbGoTo(nReg))
	oBrw:oBrowse:Refresh()
	
Return

Static Function MarcaTudo()

	Local nReg := TRB->(RECNO())
	Local cMar := .F.
	
	TRB->(dbGoTop())
	
	While TRB->(!Eof())
	
		RecLock('TRB',.F.)
			If TRB->OK == cMarca
				TRB->OK := '  '
			Else
				TRB->OK := cMarca
				cMar    := .T.
			EndIf
		MsUnlock('TRB')
		
		TRB->(dbSkip())
		
	EndDo
	
	TRB->(DbGoTo(nReg))
	oBrw:oBrowse:Refresh()
	
Return

Static Function sfPrint()

	oReport := ReportDef()
	oReport:PrintDialog()
	
Return

Static Function ReportDef()

	Private oReport

	oReport := TReport():New('MT103FIM','Impressão de Etiquetas',,{|oReport|PrintReport(oReport)} ,'Esta rotina irá imprimir as etiquetas.')
	
	oReport:lParamPage     := .F. 
	oReport:lHeaderVisible := .F. 
	oReport:lFooterVisible := .F.
	 
	oReport:SetLandscape(.T.)
	
Return oReport

Static Function PrintReport(oReport)

	Local nCont := 0

	Local oFont12N := TFont():New('ARIAL',12,12,,.T.,,,,.T.,.F.)
	Local oFont12  := TFont():New('ARIAL',12,12,,.F.,,,,.T.,.F.)

	TRB->(dbGoTop())
	
	While TRB->(!Eof())
	
		For i := 1 to TRB->QUANTI
	
			oReport:Box(0000,0000,0280,950)
		
			oReport:Saybitmap(0005,0005,'powers.bmp',0450,0072)
		
			oReport:Say(0076,0010,Substr(TRB->DESCPRD,01,50),oFont12N)
		
			nCodBar := Posicione('SB1',1,xFilial('SB1') + TRB->CODPRD,'B1_CODBAR')

			oReport:Say(0235,0450,TRB->CODPRD,oFont12N)

			MSBAR3('INT25',1.05,0.45,nCodBar,@oReport:oPrint,.F.,Nil,Nil,0.025,0.8,Nil,Nil,'A',.F.)
			
			nCont ++
		
			oReport:EndPage()
			If TRB->QUANTI <> nCont
				oReport:StartPage()
			EndIf
			
		Next i
		
		nCont := 0
	
		TRB->(dbSkip())
		
	EndDo
	
Return