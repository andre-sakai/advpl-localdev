User Function PWS01M01()

local nSeq
local cCod
local aArea := SB1->(getArea())
    
DbSelectArea("SB1")
SB1->(DbSetOrder(4))

//SB1->(SetFilter("B1_GRUPO=='"+M->B1_GRUPO+"'"))
SB1->(DBSETFILTER( {|| SB1->B1_GRUPO==M->B1_GRUPO }, 'SB1->B1_GRUPO==M->B1_GRUPO' ))


SB1->(DbGoBottom())
   
if Empty(SB1->B1_COD)
	nSeq := 0
else
	nSeq := val(alltrim(substr(SB1->B1_COD,5,4)))
EndIf	
             
nSeq++   
       
cCod := M->B1_GRUPO + strzero(nSeq,4)

SB1->(DBCLOSEAREA())

//SB1->(DBSETFILTER( {|| }, '' ))
                  
//alert(cCod)

SB1->(RestArea(aArea))  



Return cCod