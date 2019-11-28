#INCLUDE "rwmake.ch"
#include "TopConn.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³MT010INC  º Autor ³ Marcelo J. Santos  º Data ³  04/10/06   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Ponto de Entrada na Inclusao de Produtos                   º±±
±±º          ³ Utilizado para Gerar e Gravar o Codigo de Barras (EAN-13)  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Especifico para Arteplas                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function MT010INC()

If SB1->B1_TIPO == "PA" 

	If MsgBox("Deseja GERAR Código de Barras para este Produto?","Confirme","YESNO")
	
		_Query:= "SELECT MAX(Substring(B1_CODBAR,1,12)) AS CODBAR  "
		_Query+= "FROM   " + RetSQLName("SB1") + " SB1 "
		_Query+= "WHERE SB1.D_E_L_E_T_ <> '*' "
		_Query+= "AND SB1.B1_CODBAR LIKE '78970%' "
		
		TCQUERY _Query NEW ALIAS "QRY"
		
		DBSelectArea("QRY")
		QRY->(dbGoTop())
		_nProxCodBar := Str(Val(QRY->CODBAR) + 1)
		DBSelectArea("QRY")
		DBCloseArea("QRY")
		
		_cDig := EanDigito(PADL(AllTrim(_nProxCodBar),12,"0"))
		
		MsgBox("O proximo Codigo de Barras e: "+AllTrim(_nProxCodBar)+AllTrim(_cDig),"Informacao","INFO")
		RecLock("SB1",.F.)
		SB1->B1_CODBAR := AllTrim(_nProxCodBar)+AllTrim(_cDig)
		MsUnlock("SB1")
		
	Else
	
		MsgBox("NAO foi gerado nenhum codigo de barras para o produto","Informacao","INFO")
		
	Endif
	
Endif

Return