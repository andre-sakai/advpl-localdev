#include "Totvs.ch"

Class EstruturaJSONNFOrigemProd
    Data    token           as character
    Data    empresa_atual   as array
    Data    notas_fiscais   as array
    
    Method New() CONSTRUCTOR
EndClass

Method New() Class EstruturaJSONNFOrigemProd
    self:token          := ""
    self:empresa_atual  := {}
    self:notas_fiscais  := {} 
Return
