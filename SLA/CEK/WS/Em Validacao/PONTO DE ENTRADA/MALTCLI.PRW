#INCLUDE "TOTVS.CH"

USER FUNCTION MALTCLI()
	IF(SA1->(FIELDPOS('A1_WSDTALT'))>0)
		RECLOCK('SA1',.F.)
			SA1->A1_WSDTALT := DTOS(DATE())+SUBSTR(STRTRAN(TIME(),':',''),1,6) 
		SA1->(MSUNLOCK())
	ENDIF

RETURN .T.

USER FUNCTION OM010VIG()
Local lValido := .T.        
If TYPE("_cWSName") <> "U"
 	IF(_cWSName = 'WS206')
		lValido := .F. 	
		CONOUT("Passou pelo ponto de entrada - OM010VIG ")
	ENDIF
Endif

RETURN lValido