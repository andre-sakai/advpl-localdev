#INCLUDE "rwmake.ch"
#include "topconn.ch"

/*/
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北 Programa  盇RT417    � Autor � EDUARDO MARQUETTI  � Data �  15/01/13   罕�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北 Descricao � VALIDAR EMAIL DO CADASTRO DE CLIENTES                      罕�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北 Uso       � Especifico para Arteplas                                   罕�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
/*/

User Function ART417()
Local lRet := .T. 
Local email := " "

cEmail := AllTrim(M->A1_EMAIL) 
XEmail := Isemail(cEmail) 

	If XEmail == .T. 
		Return cEmail
	Else 
		MsgAlert("E-MAIL Invalido!") 
		lRet := .F. 
		Return " "
	Endif       
	
