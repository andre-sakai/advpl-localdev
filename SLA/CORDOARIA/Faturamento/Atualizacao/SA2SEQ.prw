#Include 'Protheus.ch'
#Include 'apwebsrv.ch'
#Include 'TbiConn.ch'

User Function SA2SEQ()

/*�����������������������������������������������������������������������������
�������������������������������������������������������������������������������
���������������������������������������������������������������������������Ŀ��
���Empresa     � Corda Brasil                                               ���
���������������������������������������������������������������������������Ĵ��
���Funcao      � GetCodCli  � Autor � Welinton Martins    � Data � 09/06/17 ���
���������������������������������������������������������������������������Ĵ��
���Descricao   � Pega o proximo numero e loja do cliente.                    ���
���            �                                                            ���
���������������������������������������������������������������������������Ĵ��
���Sintaxe     � GetCodCli(cCNPJ)                                           ���
���������������������������������������������������������������������������Ĵ��
���           ATUALIZACOES SOFRIDAS DESDE A CONSTRUCAO INICIAL              ���
���������������������������������������������������������������������������Ĵ��
���Programador � Data   � Motivo da alteracao                               ���
���������������������������������������������������������������������������Ĵ��
���            �  /  /  �                                                   ���
���            �        �                                                   ���
���������������������������������������������������������������������������Ĵ��
���Uso         � Especifico Corda Brasil                                    ���
����������������������������������������������������������������������������ٱ�
�������������������������������������������������������������������������������
������������������������������������������������������������������������������*/

//Static Function GetCodCli(cCNPJ)

Local aArea		:=	GetArea()
Local aAreaA1	:=	SA1->(GetArea())
Local cQuery 	:=	""
Local cLjPadrao	:=	"01"
Local aRet		:=	{}
Local cCNPJ	:=	""

cCNPJ := M->A1_CGC

cQuery := " SELECT ISNULL(A1_COD,'') AS RESULT "
cQuery += " FROM "+RetSqlName('SA1')
cQuery += " WHERE SubString(A1_CGC,1,8) = '"+SubStr(cCNPJ,1,8)+"' "
cQuery += " AND A1_CGC <> '"+cCNPJ+"' "
cQuery += " AND D_E_L_E_T_ = ' ' "
cQuery := ChangeQuery(cQuery)

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"RES",.F.,.T.)

If Empty(RES->RESULT)

	SA1->(dbSetOrder(3))
	If !SA1->(dbSeek(xFilial("SA1")+cCNPJ))
		
		//cQuery := " SELECT ISNULL(MAX(A1_COD),0) + 1 AS CODIGO "
		cQuery := " SELECT ISNULL(MAX(REPLICATE('0',(DATALENGTH(A1_COD)-LEN(A1_COD)))+RTRIM(LTRIM(A1_COD))),0) + 1 AS CODIGO "
		cQuery += " FROM "+RetSqlName('SA1')
		cQuery += " WHERE D_E_L_E_T_ = ' ' "
		cQuery := ChangeQuery(cQuery)
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMP",.F.,.T.)
		
		aAdd(aRet,TMP->CODIGO)			//-> CODIGO
		aAdd(aRet,cLjPadrao)			//-> LOJA
		
	Else

		aAdd(aRet,SA1->A1_COD)			//-> CODIGO
		aAdd(aRet,Soma1(SA1->A1_LOJA))	//-> LOJA
		
	EndIf

Else
	
	aAdd(aRet,RES->RESULT) 		//-> CODIGO
	aAdd(aRet,cLjPadrao)		//-> LOJA

	SA1->(dbSetOrder(1))
	If SA1->(dbSeek(xFilial("SA1")+aRet[1]+aRet[2]))
	
		cQuery := " SELECT ISNULL(MAX(A1_LOJA),'00') AS LOJA "
		cQuery += " FROM "+RetSqlName('SA1')
		cQuery += " WHERE A1_COD = '"+aRet[1]+"' "
		cQuery += " AND D_E_L_E_T_ = ' ' "
		cQuery := ChangeQuery(cQuery)
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMP2",.F.,.T.)
	    
		aRet[2] := Soma1(TMP2->LOJA)

	EndIf

EndIf

If Select("RES") > 0
	dbSelectArea("RES")
	dbCloseArea()
EndIf

If Select("TMP") > 0
	dbSelectArea("TMP")
	dbCloseArea()
EndIf

If Select("TMP2") > 0
	dbSelectArea("TMP2")
	dbCloseArea()
EndIf

RestArea(aAreaA1)
RestArea(aArea)

Return(aRet[1])
