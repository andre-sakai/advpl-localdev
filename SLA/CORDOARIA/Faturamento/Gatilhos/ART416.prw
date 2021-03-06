#INCLUDE "PROTHEUS.CH"
/*
臼浜様様様様用様様様様様様様僕様様冤様様様様様様様様曜様様様冤様様様様様様� 臼
臼�Programa � ART416      �Autor�Eduardo Marquetti     � Data � 02/01/2013 艮�
臼麺様様様様謡様様様様様様様瞥様様詫様様様様様様様様擁様様様詫様様様様様様� 臼
臼�Desc.     �Dados de Redespacho                                          艮�
臼麺様様様様謡様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様� 臼
*/                                                                      
User Function ART416()

Local cMensagem      :=" "
Local cCNPJ          :=" "
Local cCodRedesp     := M->C5_REDESP
Local cLog           := " "
Local _cUser         := Alltrim(Substr(cUsuario,7,21))
Local _cData         := DtoC(Date())
Local _cHora         := Time()
Local _cPedido       := M->C5_NUM

DBSELECTAREA("SA4")
DBSETORDER(1)
DBSEEK(xFILIAL("SA4")+cCodRedesp,.T.)

cMensagem := " ## REDESPACHO (FOB): "+Alltrim(SA4->A4_NOME)+" "+"CNPJ/CPF: "+Transform(SA4->A4_CGC,IIF(Len(Alltrim(SA4->A4_CGC))<>14,"@r 999.999.999-99","@r 99.999.999/9999-99"))+" "
cMensagem += "I.E.: "+Alltrim(SA4->A4_INSEST)+" "
cMensagem += "End.: "+Alltrim(SA4->A4_END)+" "+"Bairro: "+Alltrim(A4_BAIRRO)+" "
cMensagem += "CEP: "+Transform(SA4->A4_CEP,"@R 99.999-999")+" "+Alltrim(SA4->A4_MUN)+"/"+Alltrim(SA4->A4_EST) +" ## "

M->C5_MENNOTA:= Alltrim(M->C5_MENNOTA)+' '+cMensagem


RETURN (M->C5_MENNOTA)