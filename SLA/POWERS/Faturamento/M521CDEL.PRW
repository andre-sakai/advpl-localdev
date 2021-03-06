#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  M521CDEL   � Autor � Jeyson Gurek / SMS �  Data �19/09/14    ���
�������������������������������������������������������������������������͹��
���Descricao � Inclus�o de uma condi��o adicional na consulta SQL (Query),���
���          � de sele��o dos t�tulos a receber.                          ���
�������������������������������������������������������������������������͹��
���Uso       � AP11 IDE                                                   ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function M521CDEL()    

Local aArea   := GetArea()
Local lRet := .T.
Local cQuery := ""   
Local cNumTit := SF2->F2_DOC
      
	cQuery := "SELECT R_E_C_N_O_ "
	cQuery += "  FROM "+ RetSQLName("SE1") +" SE1 "
	cQuery += " WHERE SE1.E1_FILIAL  = '"+xFilial("SE1")+"'"
	cQuery += "   AND SE1.E1_IDMOV = '"+cNumTit+"' "
	cQuery += "   AND SE1.D_E_L_E_T_ = '*' "
	cQuery := ChangeQuery(cQuery)  
	If (Select("SE1DEL") <> 0)
		dbSelectArea("SE1DEL")
		dbCloseArea()
	Endif
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"SE1DEL",.F.,.T.)
	If !SE1DEL->(Eof())
		dbSelectArea("SE1")
		SE1->(dbgoto(SE1DEL->R_E_C_N_O_))
		RecLock("SE1",.F.)
			SE1->(dbrecall())
		MsUnlock()
		MsgInfo("T�tulo projetado recuperado!")
	EndIf
	SE1DEL->(dbCloseArea())

RestArea(aArea)

Return(lRet) 
	