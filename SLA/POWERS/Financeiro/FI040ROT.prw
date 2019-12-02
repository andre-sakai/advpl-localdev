#INCLUDE "rwmake.ch"      
#INCLUDE "PROTHEUS.CH"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³FI040ROT     º Autor ³ Jeyson /SMS     º Data ³  20/10/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Adiciona botão rotina projeção contas a receber.           º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Projeto Powers/Financeiro                                  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function FI040ROT              

Local aRotina := ParamIxb

aAdd( aRotina, { "Projeção/Powers", "U_MITA002", 0, 8,, .F. } )

Return aRotina     

/////////////////////////////////////////////////////////////////////////////
User Function FA740BRW

Local aBotao := {}     

aAdd(aBotao, {"Projeção/Powers", "U_MITA002",   0 , 3    })

Return(aBotao)
                               
                                                       
///////////////////////////////////////////////////////////////////////////
User Function MITA002()
///////////////////////////////////////////////////////////////////////////
// Variaveis Locais da Funcao
Local oEdit1
Local oEdit2 
// Variaveis Private da Funcao
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

If Alltrim(SE1->E1_TIPO) == 'PR'
   MsgAlert("Atenção título é provisório, não se aplica!")
   Return
EndIf                                   

DEFINE MSDIALOG _oDlg TITLE "Projeção de Títulos a receber Powers" FROM C(178),C(181) TO C(341),C(465) PIXEL
	// Cria Componentes Padroes do Sistema      
	@ C(013),C(040) Say "Prefixo:"  Size C(103),C(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ C(019),C(040) MsGet oEdit2 Var cEdit2 Size C(015),C(009) COLOR CLR_BLACK PIXEL OF _oDlg Picture "@!" valid (Len(cEdit2) == 3)        
	@ C(013),C(060) Say "Data Vencimento:"  Size C(103),C(008) COLOR CLR_BLACK PIXEL OF _oDlg     
	@ C(019),C(060) MsGet oDtVcto Var dDtVcto Size C(040),C(008) COLOR CLR_BLACK PIXEL OF _oDlg 
	@ C(033),C(040) Say "Número de meses:" Size C(080),C(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ C(040),C(040) MsGet oEdit1 Var cEdit1 Size C(040),C(009) COLOR CLR_BLACK PIXEL OF _oDlg Picture "@E 99" Valid cEdit1 <= 60
	DEFINE SBUTTON FROM C(061),C(038) TYPE 1 ENABLE OF _oDlg ACTION (lSuccess := .T., _oDlg:End())
	DEFINE SBUTTON FROM C(061),C(080) TYPE 2 ENABLE OF _oDlg ACTION (lSuccess := .F., _oDlg:End())

ACTIVATE MSDIALOG _oDlg CENTERED        

If lSuccess       
	Processa( {|| UGRVCR(dDtVcto) }, "Aguarde...", "Gerando títulos a receber...",.F.)
EndIf

Return(.T.)


/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa   ³   C()   ³ Autores ³ Norbert/Ernani/Mansano ³ Data ³10/05/2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao  ³ Funcao responsavel por manter o Layout independente da       ³±±
±±³           ³ resolucao horizontal do Monitor do Usuario.                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function UGrvCR(dDtVcto)

Local nParc
Local dVencto :=CTOD("") 
                        
  BEGIN TRANSACTION
  RegToMemory("SE1",.F.,.F.)
  dVencto := dDtVcto+30   
  cParc   := SOMA1(M->E1_PARCELA)
  For nx := 1 to cEdit1
  	RecLock("SE1",.T.) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_FORNECE+E1_LOJA
     SE1->E1_FILIAL   := M->E1_FILIAL 
     SE1->E1_PREFIXO  := M->E1_PREFIXO
     If !Empty(cEdit2)
     		SE1->E1_NUM := cEdit2+Alltrim(Strzero(Month(dVencto),2))+Alltrim(Str(Year(dVencto)))   
		Else
			SE1->E1_NUM := M->E1_NUM
	 EndIf	     
     SE1->E1_PARCELA  := cParc
     cParc := SOMA1(cParc)
     SE1->E1_TIPO     := M->E1_TIPO
	 SE1->E1_NATUREZ  := M->E1_NATUREZ
	 SE1->E1_PORTADO  := M->E1_PORTADO
	 SE1->E1_AGEDEP   := M->E1_AGEDEP
	 SE1->E1_CLIENTE  := M->E1_CLIENTE
  	 SE1->E1_LOJA	  := M->E1_LOJA
  	 SE1->E1_NOMCLI   := M->E1_NOMCLI
	 SE1->E1_EMISSAO  := M->E1_EMISSAO
	 dVencto := dVencto+30
	 SE1->E1_VENCTO   := dVencto    
	 SE1->E1_VENCREA  := DataValida(dVencto)
	 SE1->E1_VENCORI  := DataValida(dVencto) 
	 SE1->E1_VALOR    := M->E1_VALOR       
	 SE1->E1_BASEIRF  := M->E1_BASEIRF
	 SE1->E1_NUMBCO   := M->E1_NUMBCO
	 SE1->E1_TIPODES  := M->E1_TIPODES //
	 SE1->E1_MULTNAT  := M->E1_MULTNAT //
	 SE1->E1_PROJPMS   := M->E1_PROJPMS //
	 SE1->E1_DESDOBR  := M->E1_DESDOBR //
     SE1->E1_MODSPB	  := M->E1_MODSPB 
     SE1->E1_SCORGP	  := M->E1_SCORGP 
     SE1->E1_RELATO	  := M->E1_RELATO
     SE1->E1_APLVLMN  := M->E1_APLVLMN
     SE1->E1_VLMINIS  := M->E1_VLMINIS
     SE1->E1_TPDESC   := M->E1_TPDESC
     SE1->E1_RATFIN   := M->E1_RATFIN
	 SE1->E1_ISS      := M->E1_ISS
	 SE1->E1_IRRF     := M->E1_IRRF
	 SE1->E1_HIST	  := M->E1_HIST
	 SE1->E1_SALDO    := M->E1_VALOR
	 SE1->E1_VALLIQ   := M->E1_VALLIQ     
	 SE1->E1_VLCRUZ   := M->E1_VLCRUZ
	 SE1->E1_VENCORI  := M->E1_VENCORI
	 SE1->E1_MOEDA    := M->E1_MOEDA
	 SE1->E1_FLUXO    := M->E1_FLUXO
	 SE1->E1_INSS     := M->E1_INSS
	 SE1->E1_SITUACA  := M->E1_SITUACA
	 SE1->E1_ORIGEM   := 'FINA040'
	MSUNLOCK("SE1")
  Next         
MsgInfo("Gravação concluída!")  
END TRANSACTION          

Return   

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa   ³   C()   ³ Autores ³ Norbert/Ernani/Mansano ³ Data ³10/05/2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao  ³ Funcao responsavel por manter o Layout independente da       ³±±
±±³           ³ resolucao horizontal do Monitor do Usuario.                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function C(nTam)                                                         
Local nHRes	:=	oMainWnd:nClientWidth	// Resolucao horizontal do monitor     
	If nHRes == 640	// Resolucao 640x480 (soh o Ocean e o Classic aceitam 640)  
		nTam *= 0.8                                                                
	ElseIf (nHRes == 798).Or.(nHRes == 800)	// Resolucao 800x600                
		nTam *= 1                                                                  
	Else	// Resolucao 1024x768 e acima                                           
		nTam *= 1.28                                                               
	EndIf                                                                         
                                                                                
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿                                               
	//³Tratamento para tema "Flat"³                                               
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ                                               
	If "MP8" $ oApp:cVersion                                                      
		If (Alltrim(GetTheme()) == "FLAT") .Or. SetMdiChild()                      
			nTam *= 0.90                                                            
		EndIf                                                                      
	EndIf                                                                         
Return Int(nTam)                                                                

Return .T.