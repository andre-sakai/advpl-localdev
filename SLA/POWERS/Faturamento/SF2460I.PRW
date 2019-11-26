#INCLUDE "rwmake.ch"   
#include "protheus.ch"      
#INCLUDE "topconn.ch"
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³SF2460I    º Autor ³ Jeyson Gurek / SMS  º Data ³  18/09/14 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Atualizar dados do Título a Receber (SE1) após a geração   º±±
±±º          ³ do faturamento.                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP11 IDE                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function SF2460I()
    
Local _aArea := GetArea()
 
SE1->(RecLock('SE1',.F.))
	//Atualize campos do SE1 - Titulos a Receber conforme regra especifica
	SE1->E1_DEPOSIT := SC5->C5_DEPOSIT
SE1->(MsUnLock())  



If Select("QRYSD2") <> 0
	dbSelectArea("QRYSD2")
	QRYSD2->(dbCloseArea())
EndIf  


cQuery := " SELECT D2_COD "
cQuery += " FROM "+RetSqlName("SD2")+ " SD2 "
cQuery += " WHERE  D2_DOC = '"+SF2->F2_DOC+"' AND  D2_SERIE = '"+SF2->F2_SERIE+"'   AND  D2_CLIENTE = '"+SF2->F2_CLIENTE+"' "  
cQuery += " AND  D2_LOJA = '"+SF2->F2_LOJA+"'  AND D_E_L_E_T_ = ' ' "   



cQuery := ChangeQuery(cQuery)

TcQuery cQuery New Alias "QRYSD2"  
	
dbSelectArea("QRYSD2")
QRYSD2->(dbGoTop())   


	
While QRYSD2 -> (!Eof())
        
	
	dbSelectArea("SB1")
	dbSetOrder(1)
	If dbSeek(xFilial("SB1") + QRYSD2->D2_COD )	
		/*
		if !EMPTY(ALLTRIM(SB1->B1_CODISS))   
		
			cQueryUPD := " UPDATE "+RetSqlName('SF3')+" SET F3_CODISS = '"+SB1->B1_CODISS+"' "
			cQueryUPD += " WHERE D_E_L_E_T_ = ' ' AND F3_NFISCAL = '" + SF2->F2_DOC + "'   AND F3_SERIE = '" + SF2->F2_SERIE + "'   AND F3_CLIFOR = '" + SF2->F2_CLIENTE + "' "
			cQueryUPD += " AND F3_LOJA = '" + SF2->F2_LOJA + "'   AND F3_FILIAL = '" + SF2->F2_FILIAL + "'  " 
			TCSQLEXEC(cQueryUPD)
		 
		endif
		*/
		Dbselectarea("SF3")
		DBSETORDER(4)
		DBSEEK( XFILIAL("SF3") + SF2->F2_CLIENTE + SF2->F2_LOJA + SF2->F2_DOC + SF2->F2_SERIE )				
		While !SF3->(EoF()) .AND.  SF3->F3_FILIAL == SF2->F2_FILIAL .AND.  SF3->F3_CLIEFOR == SF2->F2_CLIENTE .AND. SF3->F3_LOJA == SF2->F2_LOJA  .AND. SF3->F3_NFISCAL == SF2->F2_DOC  .AND. SF3->F3_SERIE == SF2->F2_SERIE		
			
			reclock("SF3", .F.)	
				SF3->F3_CODISS = SB1->B1_CODISS
			msunlock("SF3")
			SF3->(dbSkip())
			
		enddo
	
	endif
		

	QRYSD2->(Dbskip())
Enddo

                              
RestArea(_aArea)

Return

