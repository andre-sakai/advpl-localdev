#include "Totvs.ch"

/*/{Protheus.doc} EstruturaJSONEstoquePortal
Classe respons�vel pela Estrutura JSON de Estoques.
@author Matheus Jos� da Cunha
@since 30/09/2019
@version version
/*/
Class EstruturaJSONEstoquePortal
    Data    token           as character
    Data    empresa_atual   as array
    Data    produtos        as array

    Method New() CONSTRUCTOR

EndClass

Method New() Class EstruturaJSONEstoquePortal
    self:token          := ""
    self:empresa_atual  := {}
    self:produtos       := {}
Return