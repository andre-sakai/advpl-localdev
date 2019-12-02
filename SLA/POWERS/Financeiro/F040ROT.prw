#INCLUDE "rwmake.ch"      
#INCLUDE "PROTHEUS.CH"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �NOVO2     � Autor � AP6 IDE            � Data �  20/10/14   ���
�������������������������������������������������������������������������͹��
���Descricao � Codigo gerado pelo AP6 IDE.                                ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
User Function FI040ROT()              

Local aRotina := ParamIxb

aAdd( aRotina, { "Proje��o/Powers", "U_MITA001", 0, 8,, .F. } )

Return aRotina                                        
                                                       
///////////////////////////////////////////////////////////////////////////
User Function MITA002()
///////////////////////////////////////////////////////////////////////////
// Variaveis Locais da Funcao
Local oEdit1
// Variaveis Private da Funcao
Private _oDlg				// Dialog Principal
// Variaveis que definem a Acao do Formulario
Private VISUAL := .F.                        
Private INCLUI := .F.                        
Private ALTERA := .F.                        
Private DELETA := .F.            
Private cEdit1 := 00
Private lSuccess := .F.                                               

DEFINE MSDIALOG _oDlg TITLE "Proje��o de T�tulos Powers" FROM C(178),C(181) TO C(341),C(465) PIXEL
	// Cria Componentes Padroes do Sistema
	@ C(014),C(025) Say "Digite o n�mero de meses para a Proje��o:" Size C(103),C(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ C(031),C(049) MsGet oEdit1 Var cEdit1 Size C(040),C(009) COLOR CLR_BLACK PIXEL OF _oDlg Picture "@E 99" Valid cEdit1 <= 36
	DEFINE SBUTTON FROM C(061),C(038) TYPE 1 ENABLE OF _oDlg ACTION (lSuccess := .T., _oDlg:End())
	DEFINE SBUTTON FROM C(061),C(080) TYPE 2 ENABLE OF _oDlg ACTION (lSuccess := .F., _oDlg:End())

ACTIVATE MSDIALOG _oDlg CENTERED        

If lSuccess       
	Processa( {|| UGRVCP() }, "Aguarde...", "Gerando t�tulos a pagar...",.F.)
EndIf

Return(.T.)


/*������������������������������������������������������������������������������
��������������������������������������������������������������������������������
����������������������������������������������������������������������������Ŀ��
���Programa   �   C()   � Autores � Norbert/Ernani/Mansano � Data �10/05/2005���
����������������������������������������������������������������������������Ĵ��
���Descricao  � Funcao responsavel por manter o Layout independente da       ���
���           � resolucao horizontal do Monitor do Usuario.                  ���
�����������������������������������������������������������������������������ٱ�
��������������������������������������������������������������������������������
������������������������������������������������������������������������������*/
Static Function UGrvCR()

Local nParc
                        
  BEGIN TRANSACTION
  RegToMemory("SE2",.F.,.F.)
  dVencto := M->E2_VENCTO+30   
  cParc   := SOMA1(M->E2_PARCELA)
  For nx := 1 to cEdit1
  	RecLock("SE2",.T.) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
     SE2->E2_FILIAL   := M->E2_FILIAL 
     SE2->E2_PREFIXO  := M->E2_PREFIXO
     SE2->E2_NUM      := M->E2_NUM
     SE2->E2_PARCELA  := cParc
     cParc := SOMA1(cParc)
     SE2->E2_TIPO     := M->E2_TIPO
	 SE2->E2_NATUREZ  := M->E2_NATUREZ
	 SE2->E2_FORNECE  := M->E2_FORNECE
	 SE2->E2_LOJA     := M->E2_LOJA
	 SE2->E2_NOMFOR   := M->E2_NOMFOR
	 SE2->E2_EMISSAO  := M->E2_EMISSAO
	 SE2->E2_VENCTO   := dVencto    
	 SE2->E2_VENCREA  := DataValida(dVencto)
	 SE2->E2_VENCORI  := DataValida(dVencto)
	 dVencto := dVencto+30 	 
	 SE2->E2_VALOR    := M->E2_VALOR
	 SE2->E2_ISS      := M->E2_ISS
	 SE2->E2_IRRF     := M->E2_IRRF
	 SE2->E2_HIST	  := M->E2_HIST
	 SE2->E2_SALDO    := M->E2_VALOR
	 SE2->E2_VALLIQ   := M->E2_VALLIQ
	 SE2->E2_VENCORI  := M->E2_VENCORI
	 SE2->E2_MOEDA    := M->E2_MOEDA
	 SE2->E2_FLUXO    := M->E2_FLUXO
	 SE2->E2_INSS     := M->E2_INSS
	 SE2->E2_TIPOFAT  := M->E2_TIPOFAT
	 SE2->E2_ORIGEM   := 'UGRVCP'
	MSUNLOCK("SE2")
  Next         
MsgInfo("Grava��o conclu�da!")  
END TRANSACTION          

Return   

/*������������������������������������������������������������������������������
��������������������������������������������������������������������������������
����������������������������������������������������������������������������Ŀ��
���Programa   �   C()   � Autores � Norbert/Ernani/Mansano � Data �10/05/2005���
����������������������������������������������������������������������������Ĵ��
���Descricao  � Funcao responsavel por manter o Layout independente da       ���
���           � resolucao horizontal do Monitor do Usuario.                  ���
�����������������������������������������������������������������������������ٱ�
��������������������������������������������������������������������������������
������������������������������������������������������������������������������*/
Static Function C(nTam)                                                         
Local nHRes	:=	oMainWnd:nClientWidth	// Resolucao horizontal do monitor     
	If nHRes == 640	// Resolucao 640x480 (soh o Ocean e o Classic aceitam 640)  
		nTam *= 0.8                                                                
	ElseIf (nHRes == 798).Or.(nHRes == 800)	// Resolucao 800x600                
		nTam *= 1                                                                  
	Else	// Resolucao 1024x768 e acima                                           
		nTam *= 1.28                                                               
	EndIf                                                                         
                                                                                
	//���������������������������Ŀ                                               
	//�Tratamento para tema "Flat"�                                               
	//�����������������������������                                               
	If "MP8" $ oApp:cVersion                                                      
		If (Alltrim(GetTheme()) == "FLAT") .Or. SetMdiChild()                      
			nTam *= 0.90                                                            
		EndIf                                                                      
	EndIf                                                                         
Return Int(nTam)                                                                

Return .T.