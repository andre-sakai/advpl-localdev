#include "Totvs.ch"

/*/{Protheus.doc} FotoPortal
Classe responsável por atribur os dados 
referente a foto do portal
@author Matheus José da Cunha
@since 02/10/2019
/*/
Class FotoPortal
    Data    pedido      as character
    Data    nota_fiscal as character
    Data    path        as character
    Data    quantidade  as numeric
    
    Method New() CONSTRUCTOR
EndClass

Method New() Class FotoPortal
    self:pedido     := ""
    self:nota_fiscal:= ""
    self:path       := ""
    self:quantidade := 0
Return