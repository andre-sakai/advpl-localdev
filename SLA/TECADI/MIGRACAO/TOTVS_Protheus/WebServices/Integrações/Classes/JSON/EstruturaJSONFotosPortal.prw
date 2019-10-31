#include "Totvs.ch"

/*/{Protheus.doc} EstruturaJSONFotosPortal
Classe responsável pela estrutua JSON do 
WS de Fotos.
@author Matheus José da Cunha
@since 02/10/2019
/*/
Class EstruturaJSONFotosPortal
    Data    token           as character
    Data    empresa_atual   as array
    Data    fotos           as array

    Method New() CONSTRUCTOR
EndClass

Method New() Class EstruturaJSONFotosPortal
    self:token          := ""
    self:empresa_atual  := {}
    self:fotos          := {}
Return