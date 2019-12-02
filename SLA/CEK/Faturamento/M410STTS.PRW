#INCLUDE "rwmake.ch"

/*/
=============================================================
Programa     : M410STTS()
Data         : 18/07/2017
Alterado por : 
Data         : 
-------------------------------------------------------------
Descricao    :  Ao concluir a manutenção em pedidos de venda                                    
Módulo (Uso) : SIGAFAT 
=============================================================
/*/

User Function M410STTS()

Local	aArea	:= GetArea()

	if inclui .or. altera
   		U_CEK097(SC5->C5_NUM)  
   
   		sftabela() 
    endif

RestArea(aArea)

Return    


//Verifica se pedido entrrou com preço menor que tabela de preços. 
Static Function sftabela()

nVlrMin2 	:= 0

dbSelectArea("SC5")

DbSelectArea("SA1")
DbSetOrder(1)
DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)

dbSelectArea("SC6")
dbSetorder(1)
dbSeek(SC5->C5_FILIAL+SC5->C5_NUM)

nPrcVen := 0
nPrcMin := 0

aprod := {}


While !EOF()  .AND. SC6->C6_NUM == SC5->C5_NUM   
	
  //	IF EMPTY(SC6->C6_NOTA)  
						
		nVlrMin2:=  U_CEKTAB(SC6->C6_PRODUTO,SC5->C5_TABELA)
	
		nPrcVen := SC6->C6_PRCVEN
	    nPrcMin := nVlrMin2 
	  
	    
	    If nPrcVen < (nPrcMin)
			aadd(aprod, {SC6->C6_FILIAL, SC6->C6_PRODUTO, SC6->C6_NUM,nPrcVen, nPrcMin })			
		endif
	   
   //	Endif
	Dbselectarea("SC6")
	Dbskip()
Enddo


if len(aprod)>0  

		dbSelectArea("SC5")
		RecLock("SC5", .F.) 		
			SC5->C5_BLPRECO := 'X'		
		MsUnLock("SC5")

		cProcess := OemToAnsi("001010")
		cStatus  := OemToAnsi("001011")
		oProcess := TWFProcess():New(cProcess,OemToAnsi("Inclusão pedido de venda com preço menor que a tabela de preço."))   
		
		oProcess:NewTask(cStatus,"\WORKFLOW\wfped.HTML")
		oProcess:cSubject := "Filial: " + SC5->C5_FILIAL + " - Inclusão alteração de pedidos de venda com preço menor que a tabela. "
		oProcess:bReturn  := ""
		oHTML    := oProcess:oHTML 
		dbSelectArea("SC5")
		
		//HttpGet->filial+HttpGet->num+HttpGet->forn+HttpGet->loja+HttpGet->usrcod+HttpGet->usrname
	   //	cdados:=SC5->C5_FILIAL + SC5->C5_NUM + SC5->C5_CLIENTE + SC5->C5_LOJACLI + cUserName 
				
	//	cValHash := MD5(cdados,2) 
		
		for n := 1 to len(aprod) 
		
					oHtml:ValByName("emissao",SC5->C5_EMISSAO)
					oHtml:ValByName("cliente",SC5->C5_CLIENTE) 
					oHtml:ValByName("nomecli",posicione("SA1",1, xFilial("SA1")+ SC5->C5_CLIENTE + SC5->C5_LOJACLI, "A1_NOME"))
					oHtml:ValByName("pedido",SC5->C5_NUM)
					oHtml:ValByName("produto",aprod[n][2])
					oHtml:ValByName("preco",transform(aprod[n][4], "@E 999,999,999.99" ) )  				
				   	oHtml:ValByName("prtabela",transform(aprod[n][5] , "@E 999,999,999.99" ))
		
		next
		
		oProcess:cTo := 'financeiro@cekacessorios.com.br'
		oHtml:ValByName("data",DTOC(Date()))
		oHtml:ValByName("hora",Time())          
		                
		oProcess:Start()
		oProcess:Finish()  

else
  		dbSelectArea("SC5")
		RecLock("SC5", .F.) 		
			SC5->C5_BLPRECO := ' '		
		MsUnLock("SC5")
endif

Return


// Busca valor da tabela de preços
User Function CEKTAB(cCodProd,cTABELA)

Local nVlrDA1 := 0
Local aArea   := GetArea()



DbSelectArea("DA0")
DA0->(DbSetOrder(1)) // FILIAL + COD TABELA
If DA0->(DbSeek(xfilial("DA0")+TRIM(cTABELA))) 


    DbSelectArea("DA1")
    DA1->(DbSetOrder(1)) // FILIAL + COD TABELA + PRODUTO + FAIXA + ITEM
    If DA1->(DbSeek(xfilial("DA1")+TRIM(cTABELA)+TRIM(cCodProd))) .AND. (DA0->DA0_ATIVO == "1")
      
        While DA1->(!Eof()) .and. (DA1->(DA1_FILIAL+DA1_CODTAB+DA1_CODPRO) = xFilial("DA1")+TRIM(cTABELA)+TRIM(cCodProd))  
        
        
            nVlrDA1 := DA1->DA1_PRCVEN //DA1->DA1_PRCMIN
            DA1->(DbSkip())
        EndDo
     
    EndIf
EndIf

RestArea(aArea)

Return nVlrDA1
