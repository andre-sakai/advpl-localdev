#include "Totvs.ch"

/*/{Protheus.doc} PedidoVendaPortal
Classe responsável por atribuir os dados de 
cabeçalho do pedido de venda.
@author Matheus José da Cunha
@since 27/09/2019
/*/
Class PedidoVendaPortal
    Data    numero                  as character
    Data    dt_emissao              as date
    Data    nf_tecadi               as character
    Data    nf_cliente              as character
    Data    pedido_cliente          as character
    Data    volume                  as numeric
    Data    status_processamento    as character
    Data    status_pedido           as object
    Data    itens                   as array

    Method New() CONSTRUCTOR
    
EndClass

Method New() Class PedidoVendaPortal 
    self:numero                 := ""
    self:dt_emissao             := CtoD("  /  /  ")
    self:nf_tecadi              := ""
    self:nf_cliente             := ""
    self:pedido_cliente         := ""
    self:volume                 := 0
    self:status_processamento   := ""
    self:status_pedido          := nil
    self:itens                  := {}
Return