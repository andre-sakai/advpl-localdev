/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  ART402  � Autor � Eduardo Marquetti   � Data �  04/07/11     ���
�������������������������������������������������������������������������͹��
���Descricao � Gatilho para Alertar quanto a inatividade do Cliente caso  ��� 
���            seja maior que 180 dias.                                   ���
���                             										  ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/ 


#INCLUDE "rwmake.ch"

User Function ART402()

//���������������������������������������������������������������������Ŀ
//� Declaracao de Variaveis                                             �
//�����������������������������������������������������������������������

Local cMsgD   := ""

Local lVerif := .F.
cCliente	 := M->C5_CLIENTE  
cRetorno	 := " "
cTipo		 := M->C5_TIPO

If !M->C5_TIPO $ "B#D"
	lVerif	:= .T.
EndIf

//���������������������������������������������������������������������Ŀ
//� Verifica se Cliente n�o compra a mais de 180 dias                   �
//�����������������������������������������������������������������������


If lVerif
	dbSelectArea("SA1")
	dbSetOrder(1)
	dbGoTop()
	dbSeek(xFilial("SA1")+cCliente,.T.)

	While !Eof() .And. SA1->A1_COD == cCliente
		cNome := Substr(Alltrim(SA1->A1_NOME),1,15)
		
		If dDatabase - SA1->A1_ULTCOM  >= 180
	 		cMsgD += "O Cliente "+ cCliente +" - " +cNome +", n�o compra a mais de 6 meses." + Chr(13) 
		Endif
		
		dbSelectArea("SA1")
		dbSkip()
	End
   	If !Empty(cMsgD)
   		MsgBox(cMsgD,"Revisar Cadastro","ALERTA")
		cRetorno := "Cliente n�o compra a mais de 6 meses - REVISAR CADASTRO"
	Endif
Endif   
                        
Return (cRetorno)