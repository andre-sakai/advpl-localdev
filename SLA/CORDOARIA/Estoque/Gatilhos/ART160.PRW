#include "rwmake.ch"
//ART110 GATILHO DE sd3->D3_cod => D3_OP,c,13
User Function ART160()
cProduto:= M->D3_COD
  dbSelectArea("SC2")
  SC2->(dbSetOrder(2)) 
  cRet:=" "
  SC2->(DBSeek(xFilial("SC2")+cProduto))
  while !SC2->(eof()) .and. SC2->C2_PRODUTO == cProduto
     nQuant :=  SC2->C2_QUJE + SC2->C2_PERDA
     if SC2->C2_QUANT > nQuant .and. empty(SC2->C2_DATRF)
        cRet := SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN
        EXIT
     endif  
	  SC2->(dbskip())
  enddo              
dbSelectArea("SC2")
SC2->(dbSetOrder(1)) 
If cRet == " " 
  _cMsg:= "Nao existe saldo para essa OP, favor criar nova OP !"
  MsgBox(_cMsg,"Atencao","ALERT")
Else
  RETURN(cRet)
EndIf  
Return