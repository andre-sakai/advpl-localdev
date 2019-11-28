//ART110 GATILHO DE sd3->D3_cod => D3_OP,c,13
User Function ART162()
dbselectArea("SB1")
SB1->(dbsetorder(1))
SB1->(DBSeek(xFilial("SB1")+M->D3_COD))
_nQtde2 := 0.0
if M->D3_SEGUM <> "  "
   if SB1->B1_TIPCONV == "M"
      _nQtde2 := M->D3_QUANT * SB1->B1_CONV
   endif   
   if SB1->B1_TIPCONV == "D"
      _nQtde2 := M->D3_QUANT / SB1->B1_CONV
   endif   
endif   
   
RETURN(_nQtde2)