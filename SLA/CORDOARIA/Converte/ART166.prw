#include "rwmake.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ART166    ºAutor  ³Marcelo J. Santos   º Data ³  29/06/05   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Programa chamado por Gatilho no SH6 (Apontamento de Producao±±
±±º          ³ buscar a primeira OP com saldo a partir do codigo do produ-º±±
±±º          ³ to digitado.                                               º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Especifico para Arteplas                                  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function ART166()

cProduto := M->H6_PRODUTO

DbSelectArea("SC2")
SC2->(DbSetOrder(2))

cRet:=" "
SC2->(DBSeek(xFilial("SC2")+cProduto))

While !SC2->(Eof()) .and. SC2->C2_PRODUTO == cProduto
	nQuant :=  SC2->C2_QUJE + SC2->C2_PERDA
	If SC2->C2_QUANT > nQuant .and. Empty(SC2->C2_DATRF)
		cRet := SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN
		Exit
	Endif
	SC2->(dbskip())
Enddo

DbSelectArea("SC2")
SC2->(DbSetOrder(1))

If cRet == " "
	_cMsg:= "Nao existe saldo para essa OP, favor criar nova OP !"
	MsgBox(_cMsg,"Atencao","ALERT")
Else
	Return(cRet)
EndIf
