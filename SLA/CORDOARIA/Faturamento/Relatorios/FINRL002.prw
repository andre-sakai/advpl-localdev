#include "rwmake.ch"
#include "TOPCONN.CH"

/*/
ฑฑฺฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฟฑฑ
ฑฑณPROGRAMA  ณ FINRL002          Paulo Bindo              DATA ณ 26/06/03 ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณDESCRICAO ณ Emissใo de Etiquetas de clientes                           ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณALTERACAO ณ                                                            ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณCLIENTE   ณ CIS Eletronica Industria e Comercio Ltda                   ณฑฑ
ฑฑภฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤูฑฑ
/*/

User Function FINRL002()

SetPrvt("CSAVSCR1,CSAVCUR1,CSAVROW1,CSAVCOL1,CSAVCOR1,TITULO")
SetPrvt("CDESC1,CDESC2,CDESC3,CSTRING,ARETURN,CPERG")
SetPrvt("NLASTKEY,M_PAG,NLIN,LIMITE,CTAMANHO,CPROGRA")
SetPrvt("CBTXT,CBCONT,NSTQTDPREV,NSTQTDPEND,NSTQTDFAT,NSTTOTPREV")


//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Define Variaveis                                             ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Titulo     := "Emissใo de Etiquetas"
cDesc1     := "Este programa irแ emitir etiquetas de Clientes    "
cDesc2     := ""
cDesc3     := "Arteplas"
cString    := "SA1"
aReturn    := { "Zebrado", 1,"Administracao", 1, 1, 1, "",1 }
cPerg      := "FIRL02"
nLastKey   := 0
nLin       := 2
nEtiq      := 1
nUltima    := 0
nQtdEtiq   := 0
cTamanho   := "G"
cProgra    := "FINRL002"
cBtxt      := Space( 10 )
cBcont     := 0
aTrab      := {}
lFim       := .F.

Private _nPosHor := 0
Private _nLinha  := 0
Private _nEspLin := 0
Private _nPosVer := 0
Private _nTxtBox := 0
Private _CLIENTE
Private _NENDER
Private _BAIRRO
Private _CIDADE
Private _ESTADO
Private _CEP
Private _CONTATO

FiltImp    := ""
aInfo      := {}
nHeight    := 15
lBold      := .F.
lUnderLine := .F.
lPixel     := .T.
lPrint     := .F.

oFont11  := TFont():New( "Arial",,11,,.F.,,,,,.F. )
oFont11B := TFont():New( "Arial",,11,,.T.,,,,,.F. )
oFont12  := TFont():New( "Arial",,12,,.F.,,,,,.F. )
oFont12B := TFont():New( "Arial",,12,,.T.,,,,,.F. )
oFont13  := TFont():New( "Arial",,13,,.F.,,,,,.F. )
oFont13B := TFont():New( "Arial",,13,,.T.,,,,,.F. )
oFont14  := TFont():New( "Arial",,14,,.F.,,,,,.F. )
oFont14B := TFont():New( "Arial",,14,,.T.,,,,,.F. )
oFont15  := TFont():New( "Arial",,15,,.F.,,,,,.F. )
oFont15B := TFont():New( "Arial",,15,,.T.,,,,,.F. )
oFont16  := TFont():New( "Arial",,16,,.F.,,,,,.F. )
oFont16B := TFont():New( "Arial",,16,,.T.,,,,,.F. )
oprn     := TMSPrinter():New()
oprn:setup()

_nPosHor := 01
_nEspLin := 70
_nTxtBox := 05


//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Variaveis utilizadas para parametros        ณ
//ณ mv_par01            // Do Cliente           ณ
//ณ mv_par02            // Ate o Cliente        ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Envia controle para a funcao SETPRINT.                       ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

WnRel := cProgra
WnRel := SetPrint(cString,WnRel,cPerg,@Titulo,cDesc1,cDesc2,cDesc3,.T.)

If nLastKey == 27
	Set Filter To
	Return
Endif

SetDefault(aReturn,cString)
if nLastKey == 27
	Set Filter To
	Return
Endif

RptStatus({|| RptDetail() })

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณRptDetail บAutor  ณMicrosiga           บ Data ณ  12/17/03   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                        บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/


Static Function RptDetail()

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Cria a Estrutura do Arquivo de Trabalho                          ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
AADD(aTrab,{ "MARK"   ,"C", 02, 0 })
AADD(aTrab,{ "CLIENTE","C", 40, 0 })
AADD(aTrab,{ "ENDER"  ,"C", 40, 0 })
AADD(aTrab,{ "BAIRRO" ,"C", 15, 0 })
AADD(aTrab,{ "CIDADE" ,"C", 20, 0 })
AADD(aTrab,{ "ESTADO" ,"C", 02, 0 })
AADD(aTrab,{ "CEP"    ,"C", 08, 0 })
AADD(aTrab,{ "CONTATO","C", 15, 0 })

cArqDBF0 := CriaTrab( aTrab, .T. )
cArqNTX0 := CriaTrab( NIL, .F. )
Use &cArqDBF0 Alias "TRB" Exclusive New

cQuery := " SELECT * FROM SA1010 "
cQuery += " WHERE A1_VEND = '"+mv_par01+"' AND D_E_L_E_T_ <> '*'"

MemoWrit("FINRL002.sql",cQuery)
dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),"TRB1", .F., .T.)

COUNT TO nRecCount

//CASO NAO TENHA DADOS
If nRecCount == 0
	MsgStop("Nใo existem dados para este relat๓rio!")
	TRB->(dbCloseArea())
	TRB1->(dbCloseArea())	
Else
	SetRegua(nRecCount)
	dbSelectArea("TRB1")
	dbGoTop()
	While !EOF()
		IncRegua()
		
		_CLIENTE := Alltrim(TRB1->A1_NOME)
		_NENDER  := Alltrim(TRB1->A1_END)
		_BAIRRO  := Alltrim(TRB1->A1_BAIRRO)
		_CIDADE  := Alltrim(TRB1->A1_MUN)
		_ESTADO  := TRB1->A1_EST
		_CEP     := TRB1->A1_CEP
		
		IncRegua()
		
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Verifica se usuario teclou ALT+A para abandonar                  ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		
		Inkey( 0.01 )
		If LastKey() == 286
			@ nLin +  1, 000 PSAY "*** CANCELADO PELO USUARIO ***"
			Exit
		EndIf
		
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Grava arquivo temporario                                         ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		DbSelectarea("TRB")
		RECLOCK( "TRB", .T. )
		

		TRB->CLIENTE := _CLIENTE
		TRB->ENDER   := _NENDER
		TRB->BAIRRO  := _BAIRRO
		TRB->CIDADE  := _CIDADE
		TRB->ESTADO  := _ESTADO
		TRB->CEP     := _CEP
		
		MSUNLOCK()
		
		
		dbSelectArea("TRB1")
		dbSkip()
	EndDo
	
	dbselectarea("TRB")
	DbGoTop()
	
	aCampos := {}
	AADD(aCampos,{"MARK"      ,"BORDERO" })
	AADD(aCampos,{"CLIENTE"   ,"CLIENTE" })
	AADD(aCampos,{"ENDER"     ,"ENDERECO"})
	AADD(aCampos,{"BAIRRO"    ,"BAIRRO"  })
	AADD(aCampos,{"CIDADE"    ,"CIDADE"  })
	AADD(aCampos,{"ESTADO"    ,"ESTADO"  })
	AADD(aCampos,{"CEP"       ,"CEP"     })
	
	@ 100,1 TO 500,640 DIALOG oDlg2 TITLE "Selecao de Registros"
	@ 10,7 TO 170,320 BROWSE "TRB" FIELDS aCampos MARK "MARK"
	@ 180,80 BUTTON "_Ok"       SIZE 40,15 ACTION fcontinua()
	@ 180,160 BUTTON "_Cancela" SIZE 40,15 ACTION fSai()
	ACTIVATE DIALOG oDlg2 CENTERED
EndIf
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณfcontinua บAutor  ณMicrosiga           บ Data ณ  08/11/05   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                        บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function fcontinua()
bBloco := { |lEnd| OkProc() }
MsAguarde(bBloco,"Aguarde","Gerando Arquivo...",.f.)
Close(oDlg2)
Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณFSAI      บAutor  ณMicrosiga           บ Data ณ  08/11/05   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function fSai()
Close(oDlg2)
DBSELECTAREA("TRB")
USE
Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณOkProc    บAutor  ณMicrosiga           บ Data ณ  08/11/05   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function OkProc()

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Inicio da Impressao                                              ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
dbselectarea("TRB")
dbGotop()

SetRegua(LastRec())

oprn:StartPage()

Do While !eof()
	
	IncRegua()
	
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Verifica se usuario teclou ALT+A para abandonar                  ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	
	Inkey( 0.01 )
	If LastKey() == 286
		@ nLin +  1, 000 PSAY "*** CANCELADO PELO USUARIO ***"
		Exit
	EndIf
	
	IF MARKED("MARK")
		
		If nEtiq == 1
			cCliente1 := Alltrim(CLIENTE)
			cEnder1   := Alltrim(ENDER)
			cBairro1  := Alltrim(BAIRRO)
			cMunicip1 := Alltrim(CIDADE)
			cEstado1  := ESTADO
			cCep1     := CEP
			nEtiq     := 2
			nUltima   := 1
			dbSkip()
			Loop
		Else
			cCliente2 := Alltrim(CLIENTE)
			cEnder2   := Alltrim(ENDER)
			cBairro2  := Alltrim(BAIRRO)
			cMunicip2 := Alltrim(CIDADE)
			cEstado2  := ESTADO
			cCep2     := CEP
			nEtiq     := 1
			nUltima   := 0
		EndIf
		
		If nQtdEtiq > 12
			oprn:EndPage()
			oprn:StartPage()
			nLin     := 2
			nQtdEtiq := 0
		EndIf
		
		nLin := nLin + 1
		oprn:say(_nPosHor+((nLin)*_nEspLin),0005,cCliente1,ofont12B,100)
		oprn:say(_nPosHor+((nLin)*_nEspLin),1400,cCliente2,ofont12B,100)
		nLin := nLin + 1
		oprn:say(_nPosHor+((nLin)*_nEspLin),0005,cEnder1+" - "+cBairro1,ofont11,100)
		oprn:say(_nPosHor+((nLin)*_nEspLin),1400,cEnder2+" - "+cBairro2,ofont11,100)
		nLin := nLin + 1
		oprn:say(_nPosHor+((nLin)*_nEspLin),0005,cMunicip1+", "+cEstado1,ofont11,100)
		oprn:say(_nPosHor+((nLin)*_nEspLin),1400,cMunicip2+", "+cEstado2,ofont11,100)
		nLin := nLin + 1
		oprn:say(_nPosHor+((nLin)*_nEspLin),0005,"CEP: "+SUBST(cCep1,1,5)+"-"+SUBST(cCep1,6,3),ofont11,100)
		oprn:say(_nPosHor+((nLin)*_nEspLin),1400,"CEP: "+SUBST(cCep2,1,5)+"-"+SUBST(cCep2,6,3),ofont11,100)
		nLin := nLin + 1
		
		If nQtdEtiq == 0
			nLin := nLin + 2
		Else
			nLin := nLin + 1
		EndIf
		
		nQtdEtiq := nQtdEtiq + 2
		
	ENDIF
	dbSkip()
EndDo


oprn:EndPage()
oprn:Preview()


TRB1->(dbCloseArea())
TRB->(dbCloseArea())

/*
Set Device To Screen
If aReturn[5] == 1
	Set Printer To
	dbCommitAll()
	OurSpool(WnRel)
EndIf
  */
FT_PFLUSH()

Return NIL

Return
