#include "totvs.ch"

/*/{Protheus.doc} NotaFiscalPortal  
Classe respons�vel pelas informa��es
de uma nota fiscal.
@author Matheus Jos� da Cunha
@since 04/10/2019
/*/
Class NotaFiscalPortal  
    Data    numero  as character
    Data    emissao as date
    Data    saldo   as numeric    

    Method New() CONSTRUCTOR
EndClass

Method New() Class NotaFiscalPortal
    self:numero := ""
    self:emissao:= CtoD("  /  /  ")
    self:saldo  := 0  
Return