#INCLUDE "rwmake.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �NOVO3     � Autor � AP5 IDE            � Data �  14/11/02   ���
�������������������������������������������������������������������������͹��
���Descricao � Codigo gerado pelo AP5 IDE.                                ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP5 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/


User Function ART107()

	//���������������������������������������������������������������������Ŀ
	//� Declaracao de Variaveis                                             �
	//�����������������������������������������������������������������������

	Private cString
	cVldAlt := "U__IncluiSC4()" // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
	cVldExc := "U__ExcluiSC4()" // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.

	Private cString := "SC4"

	dbSelectArea("SC4")
	dbSetOrder(1)

	AxCadastro(cString,"Previsao de Vendas",cVldExc,cVldAlt)

Return


User Function _IncluiSC4()
	
	If .not.Inclui 
		U__ExcluiSC4()
	EndIf
	
	SB2->(DBGoTop())
	SB2->(DBSetOrder(1))
	If SB2->(DBSeek(xFilial("SB2")+M->C4_PRODUTO+M->C4_LOCAL,.F.))
		SB2->(RecLock("SB2",.F.))
		SB2->B2_QEMP := SB2->B2_QEMP + M->C4_QUANT
		SB2->(MSUnLock())
	EndIf

Return(.T.)


User Function _ExcluiSC4()

	SB2->(DBGoTop())
	SB2->(DBSetOrder(1))
	If SB2->(DBSeek(xFilial("SB2")+SC4->C4_PRODUTO+SC4->C4_LOCAL,.F.))
		SB2->(RecLock("SB2",.F.))
		SB2->B2_QEMP := SB2->B2_QEMP - (SC4->C4_QUANT - SC4->C4_QUJE)
		SB2->(MSUnLock())
	EndIf

Return(.T.)