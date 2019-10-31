#include "Totvs.ch"

/*/{Protheus.doc} EmpresaPortal
Classe utilizada para atribuir as informações referente a
loja do cliente da tabela AI4.
@type  Class
@author Matheus José da Cunha
@since 24/09/2019
/*/
Class EmpresaPortal
    Data    codigo      as character
    Data    loja        as character
    Data    nome        as character

    Method New() CONSTRUCTOR

EndClass 

Method New() Class EmpresaPortal
    self:codigo := ""
    self:loja   := ""
    self:nome   := ""
Return