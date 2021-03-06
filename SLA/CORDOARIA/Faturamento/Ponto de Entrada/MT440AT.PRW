#INCLUDE "rwmake.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  MT440AT    � Autor �  Eduardo Marquetti � Data �  11/04/10   ���
�������������������������������������������������������������������������͹��
���Descricao � Ponto de Entrada Antes de Liberar Pedido de Vendas         ���
�������������������������������������������������������������������������͹��
���Uso       � Especifico para Arteplas                                   ���
���          � Verifica se o Cliente tem Restri��o quanto ao SERASA  	  ���
���          � Campo A1_RESTRIC                                           ��� 
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
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


// � necess�rio verificar se o Pedido � uma Devolu��o

If cRestric = "1"
	MsgBox("Pedido N�O pode ser Liberado. O Cliente " + cNomcli + " tem restri��o SERASA. Verifique Resti��o do Cliente.") // Cliente com Restri��o de Cr�dito
    Return (.F.)
	Else
	If cRestric = "3"
		MsgAlert("Este Pedido pode ser Liberado. O Cliente " + cNomcli + " tem Restri��o com Permiss�o de Libera��o somente para este Pedido.")
	    RecLock("SA1",.F.)
		SA1->A1_RESTRIC := "1"
		MsUnlock("SA1")
    	Return (.T.)
	Else    
		If cTipo == 'N' .AND. cEmail = " "// Pedido Normal e Cliente n�o tem e-mail.
			MsgBox("Pedido N�O pode ser liberado. Cliente sem e-mail cadastrado.") 
		    Return (.F.)
        Else
	   		Return (.T.)
	  	EndIf
	EndIf
EndIf