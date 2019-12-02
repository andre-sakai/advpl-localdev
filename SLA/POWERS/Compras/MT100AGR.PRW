#INCLUDE "rwmake.ch"         
#include "protheus.ch" 
#INCLUDE "topconn.ch"
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³MT100GE2   º Autor ³ Jeyson Gurek/SMS  º Data ³  30/10/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ PE NFE na gravação dos títulos do cp.                      º±±
±±º          ³ Baixar o título projetado.                                 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP11 IDE                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function MT100AGR 

Local aArea   := GetArea()
Private cNumTit := SE2->E2_NUM

If INCLUI //.. inclusao
	//Seleciona SE2
	u_SelTitP()
EndIf 

If INCLUI == .F. //nOpc == 2 //.. exclusao
	u_VerDelE2()//verifica o título projetado/? recall
EndIf              
              
RestArea(aArea)

Return Nil

//------------------------------------------------
User function SelTitP()
//------------------------------------------------
Local stru:={}
Local aCpoBro := {}
Local oDlg
Local aCores := {}
Local lExec := .F.
Local lEnc  := .F.
Private lInverte := .F.
Private cMark   := GetMark()
Private oMark   
Private	_oCheckMark

Private	_lCheckMark	:= .T.

Private	lEnd		:= .F.

	//Cria um arquivo de Apoio
	AADD(stru,{"OK"       ,"C",2	,0	})
	AADD(stru,{"PREFIXO"  ,"C",3	,0	})
	AADD(stru,{"NUM"      ,"C",9	,0	})
	AADD(stru,{"PARCELA"  ,"C",2	,0	})
	AADD(stru,{"TIPO"     ,"C",3	,0	})
	AADD(stru,{"SALDO"    ,"N",18	,2	})
	AADD(stru,{"DTVENC"   ,"D",8	,0	})
	AADD(stru,{"FORNECE"  ,"C",6	,0	})
	AADD(stru,{"LOJA"     ,"C",2	,0	})
	cArq:=Criatrab(stru,.T.)
	If (Select("TRC") <> 0)
		dbSelectArea("TRC")
		dbCloseArea()
	Endif

	DBUSEAREA(.t.,,carq,"TRC")//Alimenta o arquivo de apoio com os registros 
	cFornece := SE2->E2_FORNECE
	cLoja    := SE2->E2_LOJA

	cArqTrb	:= CriaTrab( nil, .F. )
	cQuery := "SELECT * FROM "+ RetSQLName("SE2") + " SE2  "
	cQuery += "WHERE SE2.E2_FILIAL = '"+ xFilial("SE2") +"' AND "
	cQuery += "SE2.E2_FORNECE = '"+cFornece+"' AND "
	cQuery += "SE2.E2_LOJA = '"+cLoja+"' AND "
   //cQuery += "SE2.E2_VENCTO = '"+cRevisa+"' AND "
	cQuery += "SE2.E2_SALDO  > 0 AND " 
	cQuery += "SE2.E2_ORIGEM = 'FINA050' "
	cQuery += "AND SE2.D_E_L_E_T_ = ' '  "
	cQuery := ChangeQuery( cQuery )
	If (Select("SE2TMP") <> 0)
		dbSelectArea("SE2TMP")
		dbCloseArea()
	Endif
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"SE2TMP",.F.,.T.)
	dbSelectArea("SE2TMP")
	If Empty(SE2TMP->E2_NUM) 	
		Return
	EndIf	
	While !SE2TMP->(Eof())
		DbSelectArea("TRC")
		RecLock("TRC",.T.)
		TRC->OK 	  := ""//cMark
		TRC->PREFIXO  := SE2TMP->E2_PREFIXO
		TRC->NUM      := SE2TMP->E2_NUM
		TRC->PARCELA  := SE2TMP->E2_PARCELA
		TRC->TIPO     := SE2TMP->E2_TIPO
		TRC->SALDO    := SE2TMP->E2_SALDO 
		TRC->DTVENC   := STOD(SE2TMP->E2_VENCTO)
		TRC->FORNECE  := SE2TMP->E2_FORNECE
		TRC->LOJA     := SE2TMP->E2_LOJA
		MsunLock()
		SE2TMP->(DbSkip())
	EndDo	
		
	//Define quais colunas (campos da TRC) serao exibidas na MsSelect
	aCpoBro	:= {{ "OK"	,, "Mark"       ,"@!"},;
		{ "PREFIXO"	,, "Prefixo" ,"@!"},;
		{ "NUM"  	,, "Numero"  ,"@!"},;
		{ "PARCELA"	,, "Parcela" ,"@!"},;
		{ "TIPO"	,, "Tipo"    ,"@!"},;
		{ "SALDO"	,, "Valor"   ,"@E 999,999,999,999,999.99"},;
		{ "DTVENC"	,, "Data Vencimento" ,"@!"},;
		{ "FORNECE"	,, "Fornecedor"      ,"@!"},;
		{ "LOJA"	,, "Loja" ,"@!"} }
	//Cria uma Dialog
/*	DEFINE MSDIALOG oDlgM TITLE "Títulos Projetados Encontrados: Selecione para o Abatimento" From 9,0 To 315,800 PIXEL
	//Cria a MsSelect
	oMark := MsSelect():New("TRC","OK","",aCpoBro,@lInverte,@cMark,{17,1,150,400},,,,,aCores)
	oMark:bMark := {| | Disp()}
	ACTIVATE MSDIALOG oDlgM CENTERED ON INIT EnchoiceBar(oDlgM,{|| lExec := .T.,oDlgM:End()},{|| oDlgM:End()})
*/
	DEFINE MSDIALOG oDlg TITLE OemToAnsi("Títulos Projetados Encontrados: Selecione para o Abatimento") From 001,001 To 430,900 Of oMainWnd Pixel
	TRC->(DbGoTop())
 	oMark := MsSelect():New("TRC","OK","",aCpoBro,@lInverte,@cMark,{17,1,150,400},,,,,aCores)
	oMark:oBrowse:Refresh()
	@ 170, 005 To 195,200 Of oDlg Pixel
	@ 180, 015 CheckBox _oCheckMark Var _lCheckMark Prompt OemToAnsi('Inverter Seleção') On Click Processa({|| xInvertSel(.T.) }) Size 080,10 Of oDlg Pixel
	@ 180, 265 BUTTON OemToAnsi('&Abater Títulos') Size 40,12 Action (lExec:=.T.,oDlg:End()) When .t. Of oDlg Pixel
	@ 180, 310 BUTTON OemToAnsi('&Fechar') Size 35,12 Action (lExec:=.F.,oDlg:End()) When .t. Of oDlg Pixel
 	ACTIVATE MSDIALOG oDlg CENTERED

If lExec 
	DbSelectArea("TRC")                    
	TRC->(DbGoTop())
	While !TRC->(Eof())
	   If	Iif(lInverte,(TRC->OK <> cMark),(TRC->OK == cMark))
		DbSelectArea("SE2")
		DbSetOrder(1) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
		SE2->(DbGoTop())
		If SE2->(dbSeek(xFilial("SE2")+TRC->PREFIXO+TRC->NUM+TRC->PARCELA+TRC->TIPO+TRC->FORNECE+TRC->LOJA) )
			RecLock("SE2",.F.)  
				SE2->E2_TITADT := cNumTit
				SE2->(DbDelete())
			MsUnlock()
			MsgInfo("Título Projetado Deletado!")
			lEnc := .T.
    	EndIf
	   EndIf
   	TRC->(DbSkip())
	EndDo              
	If lEnc == .F.
		MsgAlert("Nenhum título foi selecionado!")
	EndIf
	Iif(File(cArq + GetDBExtension()),FErase(cArq  + GetDBExtension()) ,Nil)
EndIf
	
Return      


Static Function xInvertSel(_lUpdObj)

Local	_nQtdReg	:= 0
Default	_lUpdObj	:= .T.

DbSelectArea("TRC")
Count to _nQtdReg
ProcRegua(_nQtdReg)
TRC->(DbGoTop())

While	TRC->( ! Eof() )
		IncProc()
		If	RecLock("TRC",.F.)
			Replace TRC->OK With Iif(TRC->OK == cMark,Space(Len(TRC->OK)),cMark)
			TRC->(MsUnLock())
		Endif
	TRC->(DbSkip())
End

TRC->(DbGoTop())
If	_lUpdObj
	oMark:oBrowse:Refresh()
EndIf

Return()
              

//------------------------------------------------
//Funcao executada ao Marcar/Desmarcar um registro.
//------------------------------------------------
User Function VerDelE2()

Local cQuery := ""
      
	cQuery := "SELECT R_E_C_N_O_ "
	cQuery += "  FROM "+ RetSQLName("SE2") +" SE2 "
	cQuery += " WHERE SE2.E2_FILIAL  = '"+xFilial("SE2")+"'"
	cQuery += "   AND SE2.E2_TITADT = '"+cNumTit+"' "
	cQuery += "   AND SE2.D_E_L_E_T_ = '*' "
	cQuery := ChangeQuery(cQuery)  
	If (Select("SE2DEL") <> 0)
		dbSelectArea("SE2DEL")
		dbCloseArea()
	Endif
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"SE2DEL",.F.,.T.)
	If !SE2DEL->(Eof())
		dbSelectArea("SE2")
		SE2->(dbgoto(SE2DEL->R_E_C_N_O_))
		RecLock("SE2",.F.)
			SE2->(dbrecall())
		MsUnlock()
		MsgInfo("Título projetado recuperado!")
	EndIf
	SE2DEL->(dbCloseArea())

Return

//------------------------------------------------
//Funcao executada ao Marcar/Desmarcar um registro.
//------------------------------------------------
Static Function Disp()	                          

	RecLock("TRC",.F.)
	If Marked("OK")
		TRC->OK := cMark
		Else
		TRC->OK := ""
	Endif
	MSUNLOCK()      
	oMark:oBrowse:Refresh()
Return
