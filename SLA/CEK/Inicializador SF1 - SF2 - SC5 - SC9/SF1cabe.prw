#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³SF1cabe   º Autor ³ Alexandre Kuhnen   º Data ³  04/01/13   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³Programa para trazer o nome do fornecedor ou cliente        º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP6 IDE                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
  
User Function SF1cabe(cCliente,cPedido,cFilSF1)

Local cNome := "", cTipo := "", cCod := "", cTabela := ""
Local cSql := ""
Local cFilPes2 := If( Empty(xFilial("SA2")) , xFilial("SA2") , cFilSF1 )
Local cFilPes1 := If( Empty(xFilial("SA1")) , xFilial("SA1") , cFilSF1 )

cSql := " SELECT F1_TIPO FROM " + RetSqlName("SF1") + " F1 "
cSql += " WHERE F1.D_E_L_E_T_ = '' AND  F1_FILIAL = '" + xFilial("SF1",cFilSF1) + "'"
cSql += " AND F1_DOC = '" + cPedido + "'"
cSql += " AND F1_FORNECE = '" + cCliente + "'"
TCQuery cSql New Alias "__F1"
cTipo := __F1->F1_TIPO		                     
__F1->(dbCloseArea())
cNome := IIf((cTipo == "N" .or. cTipo == "C" ), Posicione("SA2",1,cFilPes2+cCliente,"A2_NOME") , Posicione("SA1",1,cFilPes1+cCliente,"A1_NOME") )

Return(cNome)      

