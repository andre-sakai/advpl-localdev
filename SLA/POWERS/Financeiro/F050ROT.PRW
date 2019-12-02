#INCLUDE "rwmake.ch"     
#INCLUDE "PROTHEUS.CH"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณF050ROT     บ Autor ณ Jeyson /SMS      บ Data ณ  20/10/14   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Ponto de entrada habilita botใo proje็ใo powers CP.        บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Projeto Powers / Financeiro                                บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/
User Function F050ROT              

Local aRotina := ParamIxb

aAdd( aRotina, { "Proje็ใo/Powers", "U_MITA001", 0, 8,, .F. } )

Return aRotina                                        
///////////////////////////////////////////////////////////////////////////
User Function FA750BRW()              
                                       
Local aBotao := {}     

aAdd(aBotao, {"Proje็ใo/Powers", "U_MITA001",   0 , 3    })

Return(aBotao)
///////////////////////////////////////////////////////////////////////////
User Function MITA001()

Local oEdit1
Local oEdit2 
Private _oDlg				// Dialog Principal
// Variaveis que definem a Acao do Formulario
Private VISUAL := .F.                        
Private INCLUI := .F.                        
Private ALTERA := .F.                        
Private DELETA := .F.            
Private cEdit1 := 00
Private cEdit2 := Space(3)
Private lSuccess := .F.    
Private dDtVcto := CTOD("")
                                      

DEFINE MSDIALOG _oDlg TITLE "Proje็ใo de Tํtulos a Pagar Powers" FROM C(178),C(181) TO C(341),C(465) PIXEL
	// Cria Componentes Padroes do Sistema
	@ C(013),C(040) Say "Prefixo:"  Size C(103),C(008) COLOR CLR_BLACK PIXEL OF _oDlg     
	@ C(019),C(040) MsGet oEdit2 Var cEdit2 Size C(015),C(009) COLOR CLR_BLACK PIXEL OF _oDlg Picture "@!" valid (Len(cEdit2) == 3) 
	@ C(013),C(060) Say "Data Vencimento:"  Size C(103),C(008) COLOR CLR_BLACK PIXEL OF _oDlg     
	@ C(019),C(060) MsGet oDtVcto Var dDtVcto Size C(040),C(009) COLOR CLR_BLACK PIXEL OF _oDlg 
	@ C(033),C(040) Say "N๚mero de meses:" Size C(080),C(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ C(040),C(040) MsGet oEdit1 Var cEdit1 Size C(040),C(009) COLOR CLR_BLACK PIXEL OF _oDlg Picture "@E 99" Valid cEdit1 <= 60
	DEFINE SBUTTON FROM C(061),C(038) TYPE 1 ENABLE OF _oDlg ACTION (lSuccess := .T., _oDlg:End())
	DEFINE SBUTTON FROM C(061),C(080) TYPE 2 ENABLE OF _oDlg ACTION (lSuccess := .F., _oDlg:End())

ACTIVATE MSDIALOG _oDlg CENTERED        

If lSuccess       
	Processa( {|| UGRVCP() }, "Aguarde...", "Gerando tํtulos a pagar...",.F.)
EndIf

Return(.T.)

///////////////////////////////////////////////////////////////////////////
Static Function UGrvCP()

Local nParc		:= 0
Local _cNum 	:= ""
Local _lAchei	:= .F.
Local nX 		:= 0
Local dVencto 	:= dDtVcto+30   
Local cParc 	:= ""

RegToMemory("SE2",.F.,.F.)

cParc := SOMA1(M->E2_PARCELA)        

If !Empty(cEdit2)
	_cNum := cEdit2+Alltrim(Strzero(Month(dVencto),2))+Alltrim(Str(Year(dVencto)))
Else
	_cNum := M->E2_NUM 
EndIf

// valido a exist๊ncia do tํtulo e das parcelas antes de gravar
if cEdit1 = 0
	cEdit1 := 1
endif
For nx := 1 to cEdit1
	if dbseek(xFilial("SE2")+cEdit2+_cNum+cParc+E2_TIPO+E2_FORNECE+E2_LOJA)                     
		_lAchei := .T.
	endIf
	cParc := SOMA1(M->E2_PARCELA)        
next nX

if _lAchei
	msgStop("Aten็ใo! Tํtulo jแ existente. Favor selecionar outro prefixo.","Tํtulo Existente")
else
	cParc := SOMA1(M->E2_PARCELA)
	BEGIN TRANSACTION
	For nx := 1 to cEdit1
	 	
		RecLock("SE2",.T.) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
	     SE2->E2_FILIAL   	:= M->E2_FILIAL 
	     //SE2->E2_PREFIXO  := Alltrim(M->E2_PREFIXO)                                                  
	     SE2->E2_PREFIXO  	:= Alltrim(cEdit2)                                                  
		 SE2->E2_NUM 		:= _cNum 
	     SE2->E2_PARCELA  	:= cParc
	     cParc := SOMA1(cParc)
	     SE2->E2_TIPO     := M->E2_TIPO
		 SE2->E2_NATUREZ  := M->E2_NATUREZ
		 SE2->E2_FORNECE  := M->E2_FORNECE
		 SE2->E2_LOJA     := M->E2_LOJA
		 SE2->E2_NOMFOR   := M->E2_NOMFOR
		 SE2->E2_EMISSAO  := M->E2_EMISSAO
		 dVencto := dVencto+30
		 SE2->E2_VENCTO   := dVencto    
		 SE2->E2_VENCREA  := DataValida(dVencto)
		 SE2->E2_VENCORI  := DataValida(dVencto)		  	 
		 SE2->E2_VALOR    := M->E2_VALOR
		 SE2->E2_VLCRUZ   := M->E2_VLCRUZ
		 SE2->E2_ISS      := M->E2_ISS
		 SE2->E2_IRRF     := M->E2_IRRF
		 SE2->E2_HIST	  := M->E2_HIST
		 SE2->E2_SALDO    := M->E2_VALOR
		 SE2->E2_VALLIQ   := M->E2_VALLIQ
		 SE2->E2_VENCORI  := M->E2_VENCORI
		 SE2->E2_MOEDA    := M->E2_MOEDA
		 SE2->E2_FLUXO    := 'S'
		 SE2->E2_INSS     := M->E2_INSS
		 SE2->E2_TIPOFAT  := M->E2_TIPOFAT  
		 SE2->E2_FILORIG  := M->E2_FILORIG
		 SE2->E2_ORIGEM   := 'FINA050' 
		 SE2->E2_DESDOBR  := M->E2_DESDOBR //"N"	              
		 SE2->E2_MULTNAT  := M->E2_MULTNAT //"2"
		 SE2->E2_PROJPMS  := M->E2_PROJPMS // "2"
		 SE2->E2_DIRF	  := M->E2_DIRF //"2"
		 SE2->E2_MODSPB   := M->E2_MODSPB //"1"  
		 SE2->E2_FRETISS  := M->E2_FRETISS //"1"
		 SE2->E2_APLVLMN  := M->E2_APLVLMN //"1"
		 SE2->E2_DATAAGE  := SE2->E2_VENCREA
		MSUNLOCK("SE2")
	  Next         
	MsgInfo("Grava็ใo concluํda!")  
	END TRANSACTION          

endif	
Return   

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑฺฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฟฑฑ
ฑฑณPrograma   ณ   C()   ณ Autores ณ Norbert/Ernani/Mansano ณ Data ณ10/05/2005ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณDescricao  ณ Funcao responsavel por manter o Layout independente da       ณฑฑ
ฑฑณ           ณ resolucao horizontal do Monitor do Usuario.                  ณฑฑ
ฑฑภฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤูฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿*/
Static Function C(nTam)                                                         
Local nHRes	:=	oMainWnd:nClientWidth	// Resolucao horizontal do monitor     
	If nHRes == 640	// Resolucao 640x480 (soh o Ocean e o Classic aceitam 640)  
		nTam *= 0.8                                                                
	ElseIf (nHRes == 798).Or.(nHRes == 800)	// Resolucao 800x600                
		nTam *= 1                                                                  
	Else	// Resolucao 1024x768 e acima                                           
		nTam *= 1.28                                                               
	EndIf                                                                         
                                                                                
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ                                               
	//ณTratamento para tema "Flat"ณ                                               
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู                                               
	If "MP8" $ oApp:cVersion                                                      
		If (Alltrim(GetTheme()) == "FLAT") .Or. SetMdiChild()                      
			nTam *= 0.90                                                            
		EndIf                                                                      
	EndIf                                                                         
Return Int(nTam)                                                                

Return .T.