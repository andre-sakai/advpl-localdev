#include "rwmake.ch"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³M030Inc   ºAutor  ³Marcelo J. Santos   º Data ³  21/02/06   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Ponto de Entrada na Funcao de Inclusao de Cliente          º±±
±±º          ³ Aqui Utilizado para Incluir a Conta Contabil no Plano de   º±±
±±º          ³ Contas do Cliente que estah sendo incluido                 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Especifico para Arteplas                                  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function M030Inc()

_Mens01 := "Cria Conta Contabil?"

If SA1->A1_EST == "EX"  // Se for Cliente Exportacao nao cria conta, mantem a conta 11201010
	RecLock("SA1",.F.)
	SA1->A1_CONTA :=  "11201010"                                                               		
	MsUnlock("SA1")
Else
    if alltrim(funname()) == "RPC"
		CT1->(DbSetOrder(1))
		CT1->(DbSeek(xFilial("CT1")+"11201"+SA1->A1_COD+SA1->A1_LOJA,.F.))
		If CT1->(Found())
			_Mens02 := "Ja existe essa Conta no Plano de Contas"+Chr(13)+Chr(13);
				      +"Conta     : "+Trans(CT1->CT1_CONTA,"@9.9.9.99.999999")+Chr(13);
				      +"Descricao : "+Alltrim(CT1->CT1_DESC01)
			MSGBOX(_Mens02,"Erro","STOP")
		Else
			RecLock("CT1",.T.)
			CT1->CT1_FILIAL		:= xFilial("CT1")
			CT1->CT1_CONTA		:= "11201"+SA1->A1_COD+SA1->A1_LOJA
			CT1->CT1_DESC01		:= SA1->A1_NOME
			CT1->CT1_CLASSE		:= "2"
			CT1->CT1_NORMAL		:= "1"
			CT1->CT1_BLOQ 		:= "2"
			CT1->CT1_CVD02		:= "1"
			CT1->CT1_CVD03		:= "1"		
			CT1->CT1_CVD04		:= "1"
			CT1->CT1_CVD05		:= "1"				
			CT1->CT1_CVC02		:= "1"
			CT1->CT1_CVC03		:= "1"		
			CT1->CT1_CVC04		:= "1"
			CT1->CT1_CVC05		:= "1"				
			CT1->CT1_CTASUP		:= "11201"
			CT1->CT1_ACITEM		:= "1"
			CT1->CT1_ACCUST		:= "1"		
			CT1->CT1_ACCLVL		:= "1"
			CT1->CT1_DTEXIS		:= CtoD("01/01/80")
			CT1->CT1_AGLSLD		:= "2"						
			CT1->CT1_CCOBRG		:= "2"		
			CT1->CT1_ITOBRG		:= "2"		
			CT1->CT1_CLOBRG		:= "2"			 
			CT1->CT1_NATCTA		:= "01"
			CT1->CT1_NTSPED		:= "01"
			CT1->CT1_INDNAT		:= "1"
			MsUnlock("CT1")
			RecLock("SA1",.F.)
			SA1->A1_CONTA := "11201"+SA1->A1_COD+SA1->A1_LOJA
			MsUnlock("SA1")
			MSGBOX("A Conta Contabil foi Criada com Sucesso!","Informacao","INFO")
		Endif
	else
		If MSGBOX(_Mens01,"Confirme","YESNO")
			CT1->(DbSetOrder(1))
			CT1->(DbSeek(xFilial("CT1")+"11201"+SA1->A1_COD+SA1->A1_LOJA,.F.))
			If CT1->(Found())
				_Mens02 := "Ja existe essa Conta no Plano de Contas"+Chr(13)+Chr(13);
					      +"Conta     : "+Trans(CT1->CT1_CONTA,"@9.9.9.99.999999")+Chr(13);
					      +"Descricao : "+Alltrim(CT1->CT1_DESC01)
				MSGBOX(_Mens02,"Erro","STOP")
			Else
				RecLock("CT1",.T.)
				CT1->CT1_FILIAL		:= xFilial("CT1")
				CT1->CT1_CONTA		:= "11201"+SA1->A1_COD+SA1->A1_LOJA
				CT1->CT1_DESC01		:= SA1->A1_NOME
				CT1->CT1_CLASSE		:= "2"
				CT1->CT1_NORMAL		:= "1"
				CT1->CT1_BLOQ 		:= "2"
				CT1->CT1_CVD02		:= "1"
				CT1->CT1_CVD03		:= "1"		
				CT1->CT1_CVD04		:= "1"
				CT1->CT1_CVD05		:= "1"				
				CT1->CT1_CVC02		:= "1"
				CT1->CT1_CVC03		:= "1"		
				CT1->CT1_CVC04		:= "1"
				CT1->CT1_CVC05		:= "1"				
				CT1->CT1_CTASUP		:= "11201"
				CT1->CT1_ACITEM		:= "1"
				CT1->CT1_ACCUST		:= "1"		
				CT1->CT1_ACCLVL		:= "1"
				CT1->CT1_DTEXIS		:= CtoD("01/01/80")
				CT1->CT1_AGLSLD		:= "2"						
				CT1->CT1_CCOBRG		:= "2"		
				CT1->CT1_ITOBRG		:= "2"		
				CT1->CT1_CLOBRG		:= "2"	   
				CT1->CT1_NATCTA		:= "01"
				CT1->CT1_NTSPED		:= "01"
				CT1->CT1_INDNAT		:= "1"
				MsUnlock("CT1")
				RecLock("SA1",.F.)
				SA1->A1_CONTA := "11201"+SA1->A1_COD
				MsUnlock("SA1")
				MSGBOX("A Conta Contabil foi Criada com Sucesso!","Informacao","INFO")
			Endif
		endif
	Endif
Endif
Return