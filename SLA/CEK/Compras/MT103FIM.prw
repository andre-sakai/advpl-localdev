#include "protheus.ch"
#include "rwmake.ch"
#include "tbiconn.ch"
#INCLUDE "TOPCONN.CH"

//+-----------------------------------------------------------------------------------//
//|Empresa...: Komeco
//|Programa..: MT103FIM()
//|Autor.....: Júnior Conte 
//|Data......: 09 de maio de 2018
//|Uso.......: SIGACOM 
//|Versao....: Protheus 12   
//|Descricao.: Ponto de entrada utilizado no final da inclusão do documento fiscal para 
//|            realizar apontamento de produdução quando vinculado numero de op junto
//|            ao documento fiscal
//|Observação:
//+-----------------------------------------------------------------------------------//

User Function MT103FIM()
Local _aArea    := GetArea()
Local nOpcao    := PARAMIXB[1]
Local nConfirma := PARAMIXB[2]
Local _nX := 1
Local _nY := 1   

Local oButton1
Local oButton2
Local oFont1 := TFont():New("Verdana",,022,,.T.,,,,,.F.,.F.)
Local oFont2 := TFont():New("Verdana",,018,,.T.,,,,,.F.,.F.)
Local oMultiGe1
Local cMultiGe1 := " "
Local oSay1
Local oSay2
Local oSay3
Local oSay4
Local oSay5

Private _nQuant := 0
Private cGet1   := space(10)

Private oDlg



dbSelectArea("SD1")
SD1->(DBSETORDER(1))
SD1->(DBSEEK(xFILIAL("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))
While !SD1->(EOF()) .AND. SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA == XFILIAL("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA
    
	_cOp := SD1->D1_OP

	If !Empty(SD1->D1_OP) .AND. SUBSTR(SD1->D1_CF,2,4) == "124 "
		
		DEFINE MSDIALOG oDlg TITLE "Apontamento de OP  - CeK" FROM 000, 000  TO 340, 450 COLORS 0, 16777215 PIXEL
		
		@ 032, 028 GET oMultiGe1 VAR cMultiGe1 OF oDlg MULTILINE SIZE 001, 000 COLORS 0, 16777215 HSCROLL PIXEL
		@ 010, 030 SAY oSay1 PROMPT "APONTAMENTO DE OP - CeK" SIZE 166, 018 OF oDlg FONT oFont1 COLORS 0, 16777215 PIXEL
		@ 052, 007 SAY oSay2 PROMPT "Ordem de Produção: " SIZE 103, 011 OF oDlg FONT oFont2 COLORS 16711680, 16777215 PIXEL
		@ 050, 118 SAY oSay3 PROMPT _cOp SIZE 101, 019 OF oDlg FONT oFont1 COLORS 0, 16777215 PIXEL
		@ 080, 007 SAY oSay4 PROMPT "Quantidade Saldo:" SIZE 076, 020 OF oDlg FONT oFont2 COLORS 16711680, 16777215 PIXEL
		_nQuant := (Posicione("SC2",1,xFilial("SC2")+SD1->D1_OP,"C2_QUANT")) - (Posicione("SC2",1,xFilial("SC2")+SD1->D1_OP,"C2_QUJE"))
		@ 078, 117 SAY oSay5 PROMPT _nQuant SIZE 101, 019 OF oDlg FONT oFont1 COLORS 0, 16777215 PIXEL
		
		@ 115, 007 SAY oSay4 PROMPT "Quantidade Digitada:" SIZE 103, 011 OF oDlg FONT oFont2 COLORS 16711680, 16777215 PIXEL
		@ 115, 117 MSGET oGet1 VAR cGet1 SIZE 067, 010 OF oDlg COLORS 0, 16777215 PIXEL
		
		@ 150, 039 BUTTON oButton1 PROMPT "Efetuar Apontamento" SIZE 067, 018 OF oDlg ACTION apont() PIXEL
		@ 150, 121 BUTTON oButton2 PROMPT "Cancelar/Novo Apontamento" SIZE 080, 018 Action(oDlg:END()) OF oDlg PIXEL
		
		
		ACTIVATE MSDIALOG oDlg CENTERED
		
	EndIf
    
    //Dbselectarea("SD1")
    SD1->(Dbskip())
Enddo 


Static Function apont

Local _aVetor := {}
Local _nOpc   := 3

lMsErroAuto := .F.
dData:=dDataBase

If Val(cGet1) > 0
	
	_aVetor := {;
	{"D3_OP"		,SD1->D1_OP ,NIL},;
	{"D3_TM"		,"010"				,NIL},;
	{"D3_QUANT"		,Val(cGet1)				,NIL}}
	
Else
	
	_aVetor := {;
	{"D3_OP"		,SD1->D1_OP ,NIL},;
	{"D3_TM"		,"010"				,NIL}}
	
EndIf

MSExecAuto({|x, y| mata250(x, y)},_aVetor, _nOpc )

If lMsErroAuto
	Mostraerro()
Endif

cGet1 := space(10)
_cOp := "       "
_nQuant := 0
Return


