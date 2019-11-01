#include "Totvs.ch"

/*/{Protheus.doc} EstruturaJSONConsPedidosPortal
Classe responsável pela Estrutura JSON de Consulta Pedidos.
@author Matheus José da Cunha
@since 30/09/2019
@version version
/*/
Class EstruturaJSONConsPedidosPortal
    Data    token           as character
    Data    empresa_atual   as array
    Data    pedidos         as array

    Method New() CONSTRUCTOR

EndClass

Method New() Class EstruturaJSONConsPedidosPortal
    self:token          := ""
    self:empresa_atual  := {}
    self:pedidos        := {}
Return