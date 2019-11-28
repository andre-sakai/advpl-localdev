#include "rwmake.ch"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³M020Inc   ºAutor  ³Marcelo J. Santos   º Data ³  21/02/06   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Ponto de Entrada na Funcao de Incusao de Fornecedores      º±±
±±º          ³ Aqui Utilizado para Incluir a Conta Contabil no Plano de   º±±
±±º          ³ Contas do Fornecedor que estah sendo incluido              º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Especifico para Arteplas                                  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function M020Inc()

_Mens01 := "Cria Conta Contabil?"

If MSGBOX(_Mens01,"Confirme","YESNO")
	CT1->(DbSetOrder(1))
	CT1->(DbSeek(xFilial("CT1")+"21101"+SA2->A2_COD,.F.))
	If CT1->(Found())
		_Mens02 := "Ja existe essa Conta no Plano de Contas"+Chr(13)+Chr(13);
		+"Conta     : "+Trans(CT1->CT1_CONTA,"@9.9.9.99.999999")+Chr(13);
		+"Descricao : "+Alltrim(CT1->CT1_DESC01)
		MSGBOX(_Mens02,"Erro","STOP")
		RecLock("SA2",.F.)
		SA2->A2_CONTA := CT1->CT1_CONTA
		MsUnlock("SA2")
	Else
		CT1->(DbSeek(xFilial("CT1")+"21102"+SA2->A2_COD,.F.))
		If CT1->(Found())
			_Mens02 := "Ja existe essa Conta no Plano de Contas"+Chr(13)+Chr(13);
			+"Conta     : "+Trans(CT1->CT1_CONTA,"@9.9.9.99.999999")+Chr(13);
			+"Descricao : "+Alltrim(CT1->CT1_DESC01)
			MSGBOX(_Mens02,"Erro","STOP")
			RecLock("SA2",.F.)
			SA2->A2_CONTA := CT1->CT1_CONTA
			MsUnlock("SA2")
		Else
			CT1->(DbSeek(xFilial("CT1")+"21103"+SA2->A2_COD,.F.))
			If CT1->(Found())
				_Mens02 := "Ja existe essa Conta no Plano de Contas"+Chr(13)+Chr(13);
				+"Conta     : "+Trans(CT1->CT1_CONTA,"@9.9.9.99.999999")+Chr(13);
				+"Descricao : "+Alltrim(CT1->CT1_DESC01)
				MSGBOX(_Mens02,"Erro","STOP")
				RecLock("SA2",.F.)
				SA2->A2_CONTA := CT1->CT1_CONTA
				MsUnlock("SA2")
			Else
				RecLock("CT1",.T.)
				CT1->CT1_FILIAL		:= xFilial("CT1")
				CT1->CT1_CONTA		:= "21103"+SA2->A2_COD
				CT1->CT1_DESC01		:= SA2->A2_NOME
				CT1->CT1_CLASSE		:= "2"
				CT1->CT1_NORMAL		:= "2"
				CT1->CT1_BLOQ 		:= "2"
				CT1->CT1_CVD02		:= "1"
				CT1->CT1_CVD03		:= "1"
				CT1->CT1_CVD04		:= "1"
				CT1->CT1_CVD05		:= "1"
				CT1->CT1_CVC02		:= "1"
				CT1->CT1_CVC03		:= "1"
				CT1->CT1_CVC04		:= "1"
				CT1->CT1_CVC05		:= "1"
				CT1->CT1_CTASUP		:= "211"
				CT1->CT1_ACITEM		:= "1"
				CT1->CT1_ACCUST		:= "1"
				CT1->CT1_ACCLVL		:= "1"
				CT1->CT1_DTEXIS		:= CtoD("01/01/80")
				CT1->CT1_AGLSLD		:= "2"
				CT1->CT1_CCOBRG		:= "2"
				CT1->CT1_ITOBRG		:= "2"
				CT1->CT1_CLOBRG		:= "2"
				MsUnlock("CT1")
				RecLock("SA2",.F.)
				SA2->A2_CONTA := "21103"+SA2->A2_COD
				MsUnlock("SA2")
				MSGBOX("A Conta Contabil foi Criada com Sucesso!","Informacao","INFO")
			Endif
		Endif
	Endif
Endif
Return
