#INCLUDE "rwmake.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  MT440AT    º Autor ³  Eduardo Marquetti º Data ³  11/04/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Ponto de Entrada Antes de Liberar Pedido de Vendas         º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Especifico para Arteplas                                   º±±
±±º          ³ Verifica se o Cliente tem Restrição quanto ao SERASA  	  º±±
±±º          ³ Campo A1_RESTRIC                                           º±± 
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function MT440AT()

cCliente := C5_CLIENTE
cLoja    := C5_LOJACLI   
cTipo	 := C5_TIPO
cRestic := " "
                               
dbSelectArea("SA1")                
DbSetOrder(1)
dbSeek(xFilial("SA1")+cCliente+cLoja,.t.)  
cNomcli  := Alltrim(SA1->A1_NOME)
cRestric := SA1->A1_RESTRIC        
cEmail   := SA1->A1_EMAIL


// É necessário verificar se o Pedido é uma Devolução

If cRestric = "1"
	MsgBox("Pedido NÃO pode ser Liberado. O Cliente " + cNomcli + " tem restrição SERASA. Verifique Restição do Cliente.") // Cliente com Restrição de Crédito
    Return (.F.)
	Else
	If cRestric = "3"
		MsgAlert("Este Pedido pode ser Liberado. O Cliente " + cNomcli + " tem Restrição com Permissão de Liberação somente para este Pedido.")
	    RecLock("SA1",.F.)
		SA1->A1_RESTRIC := "1"
		MsUnlock("SA1")
    	Return (.T.)
	Else    
		If cTipo == 'N' .AND. cEmail = " "// Pedido Normal e Cliente não tem e-mail.
			MsgBox("Pedido NÃO pode ser liberado. Cliente sem e-mail cadastrado.") 
		    Return (.F.)
        Else
	   		Return (.T.)
	  	EndIf
	EndIf
EndIf