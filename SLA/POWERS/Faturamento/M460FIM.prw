#INCLUDE "topconn.ch"
#include "protheus.ch"
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³M460FIM    º Autor ³ Kellin / SMS º  Data ³12/11/14         º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Gatilho valor excedido faturamento                         º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP11 IDE                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function M460FIM()   

Local aArea   := GetArea()
Private cNumTit := SE1->E1_NUM

If !Empty(SC5->C5_EXCED)
	RecLock("SD2",.F.)
	SD2->D2_EXCED := SC5->C5_EXCED
	MsUnLock()
EndIf

//tratamento títulos projetados
u_SelTitCR() 


   
RestArea(aArea)

Return
///////////////////////////////////////////////////
User Function SelTitCR()
//////////////////////////////////////////////////
Local stru:={}
Local aCpoBro := {}
Local oDlgM
Local aCores := {}
Local lExec := .F.
Local lEnc  := .F.
Local _aArea := GetArea() 
Local _lExecut:= .F.

Private lInverte := .T.
Private cMark   := GetMark()
Private oMark1   
Private	_oCheckMark

Private	_lCheckMark	:= .T.

Private	lEnd		:= .F.   

If (Select("TRCC") <> 0)
	dbSelectArea("TRCC")
	dbCloseArea()
Endif

//Cria um arquivo de Apoio
AADD(stru,{"OK"       ,"C",2	,0	})
AADD(stru,{"PREFIXO"  ,"C",3	,0	})
AADD(stru,{"NUM"      ,"C",9	,0	})
AADD(stru,{"PARCELA"  ,"C",2	,0	})
AADD(stru,{"TIPO"     ,"C",3	,0	})
AADD(stru,{"SALDO"    ,"N",18	,2	})
AADD(stru,{"DTVENC"   ,"D",8	,0	})
AADD(stru,{"CLIENTE"  ,"C",6	,0	})
AADD(stru,{"LOJA"     ,"C",2	,0	})
cArq:=Criatrab(stru,.T.)
DBUSEAREA(.t.,,carq,"TRCC")//Alimenta o arquivo de apoio com os registros

cCliente := SE1->E1_CLIENTE
cLoja    := SE1->E1_LOJA

cArqTrb	:= CriaTrab( nil, .F. )
cQuery := "SELECT * FROM "+ RetSQLName("SE1") + " SE1  "
cQuery += "WHERE SE1.E1_FILIAL = '"+ xFilial("SE1") +"' AND "
cQuery += "SE1.E1_CLIENTE = '"+cCliente+"' AND "
cQuery += "SE1.E1_LOJA = '"+cLoja+"' AND "
cQuery += "SE1.E1_SALDO  > 0 AND "
cQuery += "SE1.E1_ORIGEM = 'FINA040' "
cQuery += "AND SE1.D_E_L_E_T_ = ' '  "
cQuery := ChangeQuery( cQuery )

If (Select("SE1TMP") <> 0)
	dbSelectArea("SE1TMP")
	dbCloseArea()
Endif

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"SE1TMP",.F.,.T.)
dbSelectArea("SE1TMP")

If Empty(SE1TMP->E1_NUM)
	Return
EndIf

While !SE1TMP->(Eof())
	DbSelectArea("TRCC")
	RecLock("TRCC",.T.)
	TRCC->OK 	   := ""
	TRCC->PREFIXO  := SE1TMP->E1_PREFIXO
	TRCC->NUM      := SE1TMP->E1_NUM
	TRCC->PARCELA  := SE1TMP->E1_PARCELA
	TRCC->TIPO     := SE1TMP->E1_TIPO
	TRCC->SALDO    := SE1TMP->E1_SALDO
	TRCC->DTVENC   := STOD(SE1TMP->E1_VENCTO)
	TRCC->CLIENTE  := SE1TMP->E1_CLIENTE
	TRCC->LOJA     := SE1TMP->E1_LOJA
	MsunLock()
	SE1TMP->(DbSkip())
EndDo

//Define quais colunas (campos da TRCC) serao exibidas na MsSelect
aCpoBro	:= {{ "OK"	,, "Mark"       ,"@!"},;
{ "PREFIXO"	,, "Prefixo" ,"@!"},;
{ "NUM"  	,, "Numero"  ,"@!"},;
{ "PARCELA"	,, "Parcela" ,"@!"},;
{ "TIPO"	,, "Tipo"    ,"@!"},;
{ "SALDO"	,, "Valor"   ,"@E 999,999,999,999,999.99"},;
{ "DTVENC"	,, "Data Vencimento" ,"@!"},;
{ "CLIENTE"	,, "Cliente"      ,"@!"},;
{ "LOJA"	,, "Loja" ,"@!"} }
//Cria uma Dialog

TRCC->(dbGoTop())

DEFINE MSDIALOG oDlg TITLE OemToAnsi("Títulos Projetados Encontrados: Selecione para o Abatimento") From 001,001 To 430,900 Of oMainWnd Pixel
oMark1 := MsSelect():New("TRCC","OK","",aCpoBro,@lInverte,@cMark,{17,1,150,400},,,,,aCores)
oMark1:oBrowse:Refresh()
@ 170, 005 To 195,200 Of oDlg Pixel
@ 180, 015 CheckBox _oCheckMark Var _lCheckMark Prompt OemToAnsi('Inverter Seleção') On Click Processa({|| xInvertSel(.T.) }) Size 080,10 Of oDlg Pixel
@ 180, 265 BUTTON OemToAnsi('&Abater Títulos') Size 40,12 Action (lExec:=.T.,oDlg:End()) When .t. Of oDlg Pixel
@ 180, 310 BUTTON OemToAnsi('&Fechar') Size 35,12 Action (lExec:=.F.,oDlg:End()) When .t. Of oDlg Pixel
ACTIVATE MSDIALOG oDlg CENTERED

If lExec
	DbSelectArea("TRCC")
	TRCC->(DbGoTop())
	While !TRCC->(Eof())
	   if  lInverte
	   		if (TRCC->OK <> cMark)
	   			_lExecut := .T.
	   		endif
	   else
	   		if (TRCC->OK == cMark)
	   			_lExecut := .T.
	   		endif	   		
	   endif
	   If _lExecut
			DbSelectArea("SE1")
			DbSetOrder(1) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO
			SE1->(DbGoTop())
			If SE1->(dbSeek(xFilial("SE1")+TRCC->PREFIXO+TRCC->NUM+TRCC->PARCELA+TRCC->TIPO) )
				RecLock("SE1",.F.)
				SE1->E1_IDMOV := cNumTit
				SE1->(DbDelete())
				MsUnlock()
				MsgInfo("Título Projetado Deletado!")
				lEnc := .T.
			EndIf
			_lExecut := .F.
		EndIf
	    
		TRCC->(DbSkip())
	EndDo
	If lEnc == .F.
		MsgAlert("Nenhum título foi selecionado!")
	EndIf

	Iif(File(cArq + GetDBExtension()),FErase(cArq  + GetDBExtension()) ,Nil)
EndIf

RestArea(_aArea)

Return() 
//----------------------------------------------------------------------------------------------------------------------------------------------------------

Static Function xInvertSel(_lUpdObj)

Local	_nQtdReg	:= 0
Default	_lUpdObj	:= .T.

DbSelectArea("TRCC")
Count to _nQtdReg
ProcRegua(_nQtdReg)
TRCC->(DbGoTop())

While	TRC->( ! Eof() )
		IncProc()
		If	RecLock("TRCC",.F.)
			Replace TRCC->OK With Iif(TRCC->OK == cMark,Space(Len(TRCC->OK)),cMark)
			TRCC->(MsUnLock())
		Endif
	TRCC->(DbSkip())
End

TRCC->(DbGoTop())
If	_lUpdObj
	oMark1:oBrowse:Refresh()
EndIf

Return()

