#INCLUDE "rwmake.ch"
#INCLUDE "TOPCONN.CH" 
#include "vkey.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ART426     º Autor ³ EDUARDO MARQUETTI   º±± Data 27/11/2017 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Relacionar Cte x Nota Fiscal de Venda                      º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Compras / Estoque                                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function ART426

cCadastro:="Relação Cte x NF Venda" 
aRotina := {}                      
aFixe   := {}
aCols   := {}
chave1  := " "
aHeader := {}
cFornece := '      '

@ 0,0 TO 100,540 DIALOG oDlg1 TITLE "Selecao de Notas Fiscais"
@ 10,010 SAY "Selecione o Fornecedor" SIZE 200,12
@ 30,010 SAY "Fornecedor: " SIZE 100,12
@ 30,040 GET cFornece F3 "SA2"  Size 35,10
@ 29,193 BMPBUTTON TYPE 1 ACTION Mostra()
@ 29,228 BMPBUTTON TYPE 2 ACTION Close(oDlg1)
ACTIVATE DIALOG oDlg1 CENTER
Return


Static Function Mostra

	AADD(aHeader,{ 'Serie'		,'D1_SERIE'		,'@!',3,,'',,'C','SD1'}) 
	AADD(aHeader,{ 'Nota'		,'D1_DOC'  		,'@!',9,,'',,'C','SD1'}) 
	AADD(aHeader,{ 'Item'		,'D1_ITEM'      ,'@!',2,,'',,'C','SD1'}) 
	AADD(aHeader,{ 'Produto'    ,'D1_COD'   	,'@!',15,,'',,'C','SD1'})  
	AADD(aHeader,{ 'Descricao'	,'B1_DESC'	    ,'@!',35,,'',,'C','SB1'})  
	AADD(aHeader,{ 'DOC Nfe'    ,'D1_DOCVEND'	,'@!',9,,'',,'C','SD1'})
	AADD(aHeader,{ 'Serie Nfe'  ,'D1_SERVEN'	,'@!',3,,'',,'C','SD1'})
	AADD(aHeader,{ 'RECNO' 	    ,'R_E_C_N_O_' 	,'@9999999999',10,,'',,'N','SD1'})

	nUsado:=0  
	chave:=(xfilial('SD1')+cFornece)
	
	dbSelectArea('SD1')
	dbSetOrder(10)
	dbseek(chave,.F.)

    cDescri := POSICIONE("SB1",1,XFILIAL("SB1")+D1_COD,"B1_DESC")             

	While !eof() .and. D1_FILIAL = XFILIAL("SD1") .AND. D1_FORNECE = cFornece

    	IF D1_COD = '217800080' .OR.  D1_COD = '217800218'
  	   		AADD(aCols,Array(11)) 
			aCols[Len(aCols),1]  := D1_SERIE
			aCols[Len(aCols),2]  := D1_DOC
			aCols[Len(aCols),3]  := D1_ITEM
			aCols[Len(aCols),4]  := D1_COD
			aCols[Len(aCols),5]  := cDescri := POSICIONE("SB1",1,XFILIAL("SB1")+D1_COD,"B1_DESC") 
			aCols[Len(aCols),6]  := D1_DOCVEND
			aCols[Len(aCols),7]  := D1_SERVEN
       		aCols[Len(aCols),8]  :=recno()
       		aCols[Len(aCols),9] :=.F. 
	 	ENDIF   
   		DBskip()
	End

 	If Len(Acols) > 0
 
		nLinGetD:=0
		cTitulo:="Relaciona Notas Fiscais"
		aC:={}
		aR:={}
		aCGD:={30,10,250,400}	
		aGetsGD:={'D1_DOCVEND','D1_SERVEN'}
		nOpcx:=6
		lRet:=Modelo2(cTitulo,aC,aR,aCGD,nOpcx,,'U_GRAVANF()',aGetsGD,,,,,.F.)
		Close(oDlg1)
   	return(.t.)
  	else
 		Msgbox('Não existem Notas Fiscais de Frete para Este Fornecedor',,,)
 		Close(oDlg1)
	end

User Function GRAVANF
FOR I:= 1 to len(Acols)
	Recno:=Acols[I,8]
	dbSelectArea('SD1') 
	dbSetOrder(10)
	Goto Recno

 	If !eof()
   		reclock('SD1',.F.)
   		SD1->D1_DOCVEND :=Acols[I,6]
		SD1->D1_SERVEN  :=Acols[I,7]
   		msunlock('SD1')                                 
 	endif                      
NEXT       

return(.t.)