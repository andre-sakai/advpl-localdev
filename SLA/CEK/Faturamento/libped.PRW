#include 'totvs.ch'
#include "rwmake.ch"
#INCLUDE "TOPCONN.CH"   

user function libped()
Local	aArea	:= GetArea() 

	 If (UPPER(SUBSTR(cusername,1,13)) == "ADMINISTRADOR")
	    if msgyesno("Deseja desbloquear este pedido?","Sim ou Nao")        
	         DbSelectArea("SC5")
	         DbSetOrder(1)
	         if dbSeek( SC5->C5_FILIAL + SC5->C5_NUM )
	              RecLock("SC5", .F. )
	              		SC5->C5_BLPRECO := ' '              
	              MsUnlock("SC5")
	         
	         endif
	    endif  
	endif

RestArea(aArea)

return


