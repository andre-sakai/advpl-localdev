#INCLUDE "RWMAKE.CH" 

User Function WsUsrField()

Local cAlias := PARAMIXB[1]
Local aReturn := {}

Do Case 

	Case cAlias == "SC5"
		aAdd( aReturn,"C5_OBS") 
		aAdd( aReturn,"C5_TIPOENT") 

End Case

Return aReturn