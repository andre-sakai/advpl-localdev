#include "Totvs.ch"

/*/{Protheus.doc} EstruturaJSONFaturadosPortal
Classe responsável pela Estrutura JSON de Faturados.
@author Matheus José da Cunha
@since 30/09/2019
@version version
/*/
Class EstruturaJSONFaturadosPortal
    Data    token           as character
    Data    empresa_atual   as array
    Data    faturados       as array

    Method New() CONSTRUCTOR

EndClass

Method New() Class EstruturaJSONFaturadosPortal
    self:token          := ""
    self:empresa_atual  := {}
    self:faturados      := {}
Return