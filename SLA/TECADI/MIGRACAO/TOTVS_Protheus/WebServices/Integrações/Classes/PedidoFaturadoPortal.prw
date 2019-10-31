#include "Totvs.ch"

/*/{Protheus.doc} PedidoFaturadoPortal
Classe respons�vel por armazenar dados 
de pedido faturado.
@author Matheus Jos� da Cunha
@since 30/09/2019
/*/
Class PedidoFaturadoPortal
    Data    NF              as character
    Data    PO              as character
    Data    pedido_tecadi   as character
    Data    data_emissao    as date
    Data    data_vencreal   as date
    Data    valor           as numeric
    Data    status          as character

    Method New() CONSTRUCTOR

EndClass

Method New() Class PedidoFaturadoPortal
    self:nf             := ""
    self:po             := ""
    self:pedido_tecadi  := ""
    self:data_emissao   := CtoD("  /  /  ")
    self:data_vencreal  := CToD("  /  /  ")
    self:valor          := 0
    self:status         := ""
Return