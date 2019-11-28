#INCLUDE "rwmake.ch"
#INCLUDE "TOPCONN.CH" 
#include "vkey.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ART400     º Autor ³ EDUARDO MARQUETTI   º±± Data 16/05/2011 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Gerenciar os Faturamentos antecipados                      º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Faturamento                                                º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function ART400

cCadastro:="Faturamento pendente de entrega" 
aRotina := {}                      
aFixe   := {}
aCols   := {}
chave1  := " "
aHeader := {}
cCliente := '      '

@ 0,0 TO 100,540 DIALOG oDlg1 TITLE "Selecao de Notas Fiscais"
@ 10,010 SAY "Selecione o Cliente" SIZE 200,12
@ 30,010 SAY "Cliente: " SIZE 100,12
@ 30,040 GET cCliente F3 "SA1"  Size 35,10
@ 29,193 BMPBUTTON TYPE 1 ACTION Mostra()
@ 29,228 BMPBUTTON TYPE 2 ACTION Close(oDlg1)
ACTIVATE DIALOG oDlg1 CENTER
Return


Static Function Mostra

	AADD(aHeader,{ 'Serie'		,'D2_SERIE'		,'@!',3,,'',,'C','SD2'}) 
	AADD(aHeader,{ 'Nota'		,'D2_DOC'  		,'@!',9,,'',,'C','SD2'}) 
	AADD(aHeader,{ 'Item'		,'D2_ITEM'      ,'@!',2,,'',,'C','SD2'}) 
	AADD(aHeader,{ 'Produto'    ,'D2_COD'   	,'@!',15,,'',,'C','SD2'})  
	AADD(aHeader,{ 'Descricao'	,'B1_DESC'	    ,'@!',35,,'',,'C','SB1'})  
	AADD(aHeader,{ 'Quantidade'	,'D2_QUANT'	    ,'@E 99,999.99',9,2,'',,'N','SD2'})  
	AADD(aHeader,{ 'Q Entregue'	,'D2_QTDSAI'  	,'@E 99,999.99',9,2,'',,'N','SD2'})  
	AADD(aHeader,{ 'Saldo'	    ,'D2_QUANT'   	,'@E 99,999.99',9,2,'',,'N','SD2'})   //???
	AADD(aHeader,{ 'Dt.Saida'   ,'D2_SAIDA'	   	,'@D',8,,'',,'D','SD2'})
	AADD(aHeader,{ 'RECNO' 	    ,'R_E_C_N_O_' 	,'@9999999999',10,,'',,'N','SD2'})

	nUsado:=0  
	chave:=(xfilial('SD2')+cCliente)
	
	dbSelectArea('SD2')
	dbSetOrder(9)
	dbseek(chave,.F.)

    cDescri := POSICIONE("SB1",1,XFILIAL("SB1")+D2_COD,"B1_DESC")             

	While !eof() .and. D2_FILIAL = XFILIAL("SD2") .AND. D2_CLIENTE = cCliente
    	IF D2_QUANT > D2_QTDSAI .AND. D2_SERIE = '001'
  	   		AADD(aCols,Array(11)) 
                                          
			Nsaldo := D2_QUANT - D2_QTDSAI // SALDO A ENTREGAR
			
			aCols[Len(aCols),1]  := D2_SERIE
			aCols[Len(aCols),2]  := D2_DOC
			aCols[Len(aCols),3]  := D2_ITEM
			aCols[Len(aCols),4]  := D2_COD
			aCols[Len(aCols),5]  := cDescri := POSICIONE("SB1",1,XFILIAL("SB1")+D2_COD,"B1_DESC") 
			aCols[Len(aCols),6]  := D2_QUANT
			aCols[Len(aCols),7]  := D2_QTDSAI // NAO PODE SER MAIOR QUE D2_QUANT                
			aCols[Len(aCols),8]  := nSaldo
			aCols[Len(aCols),9]  := D2_SAIDA
       		aCols[Len(aCols),10] :=recno()
       		aCols[Len(aCols),11] :=.F.
	 	endif   
   		DBskip()
	End

 	If Len(Acols) > 0
 
		nLinGetD:=0
		cTitulo:="Altera quantidade Entregue"
		aC:={}
		aR:={}
		aCGD:={30,10,120,350}	
		aGetsGD:={'D2_QTDSAI','D2_SAIDA'}
		nOpcx:=6
		lRet:=Modelo2(cTitulo,aC,aR,aCGD,nOpcx,,'U_GRAVA()',aGetsGD,,,,,.F.)
		Close(oDlg1)
   	return(.t.)
  	else
 		Msgbox('Não existem Notas Fiscais com quantidades pendentes para este Cliente',,,)
 		Close(oDlg1)
	end

User Function GRAVA
FOR I:= 1 to len(Acols)
	Recno:=Acols[I,10]
	dbSelectArea('SD2') 
	dbSetOrder(3)
	Goto Recno

 	If !eof()
   		reclock('SD2',.F.)
   		
		If Acols[I,7] > Acols[I,6]
			ApMsgStop("Quantidade Entreque não pode ser maior do que a Quantidade Vendida. Verifique!")	
			Return .F.
		EndIf
		If Acols[I,7] <> 0 .AND. Acols[I,7] <= Acols[I,6] .AND. Acols[I,9] = ctod(" ")	
			ApMsgStop("Verifique as Datas de Entrega.")	
			Return .F.
		EndIf             

   		SD2->D2_QTDSAI :=Acols[I,7]
		SD2->D2_SAIDA  :=Acols[I,9]
   		msunlock('SD2')                                 
 	endif                      
NEXT       

return(.t.)