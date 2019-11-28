#INCLUDE "rwmake.ch"
#INCLUDE "TOPCONN.CH" 
#include "vkey.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ART427     º Autor ³ EDUARDO MARQUETTI   º±± Data 05/02/2018 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Data de Programação de Pedidos de Venda e Obs              º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Faturamento                                                º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function ART427

cCadastro:="Pedidos com Previsao de Faturamento" 
aRotina := {}                      
aFixe   := {}
aCols   := {}
chave1  := " "
aHeader := {}

@ 0,0 TO 100,540 DIALOG oDlg1 TITLE "Selecionando Pedidos"
@ 29,193 BMPBUTTON TYPE 1 ACTION Mostra()
@ 29,228 BMPBUTTON TYPE 2 ACTION Close(oDlg1)
ACTIVATE DIALOG oDlg1 CENTER
Return

Static Function Mostra

	AADD(aHeader,{ 'Pedido'		,'C5_NUM'		,'@!',6,,'',,'C','SC5'}) 
	AADD(aHeader,{ 'Emissao'	,'C5_EMISSAO'	,'@D',8,,'',,'D','SC5'}) 
	AADD(aHeader,{ 'Entrega'	,'C5_SAIDA  '   ,'@D',8,,'',,'D','SC5'})      
	AADD(aHeader,{ 'Obs'        ,'C5_OBSFAT'   	,'@!',50,,'',,'C','SC5'})             
    AADD(aHeader,{ 'RECNO' 	    ,'R_E_C_N_O_' 	,'@9999999999',10,,'',,'N','SC5'})

	nUsado:=0  
	chave:=(xfilial('SC5'))
	
	dbSelectArea('SC5')
	dbSetOrder(1)
	dbseek(chave,.F.)

//     cDescri := POSICIONE("SB1",1,XFILIAL("SB1")+D1_COD,"B1_DESC")             

	While !eof() .and. C5_FILIAL = XFILIAL("SC5") // .AND. D1_FORNECE = cFornece

    	IF C5_SAIDA >= CTOD("01/01/2018")
  	   		AADD(aCols,Array(11)) 
			aCols[Len(aCols),1]  := C5_NUM
			aCols[Len(aCols),2]  := C5_EMISSAO
			aCols[Len(aCols),3]  := C5_SAIDA
			aCols[Len(aCols),4]  := C5_OBSFAT
       		aCols[Len(aCols),5]  :=recno()
       		aCols[Len(aCols),6] :=.F.
	 	endif   
   		DBskip()
	End

// 			aCols[Len(aCols),5]  := cDescri := POSICIONE("SB1",1,XFILIAL("SB1")+D1_COD,"B1_DESC") 

 	If Len(Acols) > 0
 
		nLinGetD:=0
		cTitulo:="Relaciona Pedidos"
		aC:={}
		aR:={}
		aCGD:={30,10,250,400}	
		aGetsGD:={'C5_SAIDA','C5_OBSFAT'}
		nOpcx:=6
		lRet:=Modelo2(cTitulo,aC,aR,aCGD,nOpcx,,'U_GRAVAPEDIDO()',aGetsGD,,,,,.F.)
		Close(oDlg1)
   	return(.t.)
  	else
 		Msgbox('Não existem Pedidos para esta Programacao',,,)
 		Close(oDlg1)
	end

User Function GRAVAPEDIDO
FOR I:= 1 to len(Acols)
	Recno:=Acols[I,6]
	dbSelectArea('SC5') 
	dbSetOrder(1)
	Goto Recno

 	If !eof()
   		reclock('SC5',.F.)
   		SC5->C5_SAIDA   :=Acols[I,3]
		SC5->C5_OBSFAT  :=Acols[I,4]
   		msunlock('SC5')                                 
 	endif                      
NEXT       

return(.t.)