#Include "Protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "TOPCONN.CH"

/*======================================================================*\
|| #################################################################### ||
|| # Fun��o:   M460MARK                                               # ||
|| # Desc:     N�o permitido faturar com pre�o abaixo da tabela       # ||
|| # Autor:    J�nior Conte                                           # ||
|| # Data:     14/03/2013                                             # ||
|| #################################################################### ||
\*======================================================================*/

User Function M460mark()

If ( If(!ThisInv(), SC9->C9_OK==ThisMark(), SC9->C9_OK!=ThisMark() ) )

 
	
	dbSelectArea("SC5")
	dbSetOrder(1)
	if dbseek(SC9->C9_FILIAL + SC9->C9_PEDIDO )   
	
      if alltrim(SC5->C5_BLPRECO)  == 'X'   
      
      	Alert("Pedido com pre�o abaixo da tabela, favor solicitar libera��o. ")
      
		Return .F.  
		
	  endif   
	  
	EndIf

EndIf

Return ( .T. )