/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  ART399  � Autor � Eduardo Marquetti   � Data �  30/06/11   ���
�������������������������������������������������������������������������͹��
���Descricao � Gatilho para Alertar de T�tulos em Aberto na Incus�o do    ��� 
���            pedido de Vendas.                                           ���
���                             										  ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/ 


#INCLUDE "rwmake.ch"

User Function ART399(cOri)

//���������������������������������������������������������������������Ŀ
//� Declaracao de Variaveis                                             �
//�����������������������������������������������������������������������

Local cMsgV   := ""
Local cMsgD   := ""

Local lVerif := .F.
cCliente	 := M->C5_CLIENTE
cRetorno	 := M->C5_CLIENTE
cTipo		 := M->C5_TIPO

If !M->C5_TIPO $ "B#D"
	lVerif	:= .T.
EndIf

//���������������������������������������������������������������������Ŀ
//� Verifica titulos em atraso                                          �
//�����������������������������������������������������������������������

If lVerif 
	dbSelectArea("SE1")
	dbSetOrder(2)
	dbGoTop()
	dbSeek(xFilial("SE1")+cCliente,.T.)
	While !Eof() .And. SE1->E1_CLIENTE == cCliente
		                                                  
		
		 If DTOS(SE1->E1_VENCREA) < DTOS(dDataBase) .And. SE1->E1_STATUS == "A" .And. SE1->E1_SALDO > 0
		 	cDias := Alltrim(Str(dDataBase - SE1->E1_VENCREA))  
		 	nDias := dDataBase - SE1->E1_VENCREA
		    If nDias > 10
		   		cMsgV += Alltrim(SE1->E1_NUM) + " / " + Alltrim(SE1->E1_PARCELA) +" vencido em " + DTOC(SE1->E1_VENCREA) + ", atraso de "+cDias+" dias, valor:" + Transform(SE1->E1_SALDO,"@E 999,999,999.99") + Chr(13)
			EndIf
		Endif
		
		dbSelectArea("SE1")
		dbSkip()
	End
	If !Empty(cMsgV).and. FunName() =="MATA410"
		MsgBox(cMsgV,"Titulos vencidos a mais de 10 dias.","ALERTA")
//		cRetorno:= " "     
		cRetorno:= cCliente                                                         
   	 	Else 	
		cRetorno:= cCliente
	EndIf
Endif
                  
Return (cRetorno)