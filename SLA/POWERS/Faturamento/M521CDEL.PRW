#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  M521CDEL   º Autor ³ Jeyson Gurek / SMS º  Data ³19/09/14    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Inclusão de uma condição adicional na consulta SQL (Query),º±±
±±º          ³ de seleção dos títulos a receber.                          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP11 IDE                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
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
		MsgInfo("Título projetado recuperado!")
	EndIf
	SE1DEL->(dbCloseArea())

RestArea(aArea)

Return(lRet) 
	