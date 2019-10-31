#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"  

User Function AT250CAN  

If inclui .OR. altera  
	// Cancelamento dos produtos do Pacote Logistico                            
	cQuery:="DELETE FROM "+RetSqlName("SZU")+" WHERE ZU_FILIAL = '"+XFILIAL("SZU")+"' AND ZU_CONTRT = '"+M->AAM_CONTRT+"' "
	cQuery+="AND "+RetSqlName("SZU")+".D_E_L_E_T_ = '' AND NOT EXISTS (SELECT * FROM "+RetSqlName("AAN")+"  AAN "
	cQuery+="WHERE AAN_FILIAL = '"+xfilial("AAN")+"' "
	cQuery+="AND AAN_CONTRT = ZU_CONTRT "
	cQuery+="AND AAN_ITEM = ZU_ITCONTR "
	cQuery+="AND AAN.D_E_L_E_T_ = '') "
	TCSQLEXEC(cQuery)     
	// Cancelamento das atividades                            
	cQuery:="DELETE FROM "+RetSqlName("SZ9")+" WHERE Z9_FILIAL = '"+XFILIAL("SZ9")+"' AND Z9_CONTRAT = '"+M->AAM_CONTRT+"' "
	cQuery+="AND "+RetSqlName("SZ9")+".D_E_L_E_T_ = '' AND NOT EXISTS (SELECT * FROM "+RetSqlName("AAN")+"  AAN "
	cQuery+="WHERE AAN_FILIAL = '"+xfilial("AAN")+"' "
	cQuery+="AND AAN_CONTRT = Z9_CONTRAT "
	cQuery+="AND AAN_ITEM = Z9_ITEM "
	cQuery+="AND AAN.D_E_L_E_T_ = '') "
	TCSQLEXEC(cQuery)   		
endif

Return(.t.)