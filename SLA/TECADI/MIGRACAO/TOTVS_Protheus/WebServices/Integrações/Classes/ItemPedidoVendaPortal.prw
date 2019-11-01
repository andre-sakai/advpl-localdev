#include "Totvs.ch"

/*/{Protheus.doc} ItemPedidoVendaPortal
Classe responsável por armazenar as informações do 
item do pedido de venda.
@author Matheus José da Cunha
@since 27/09/2019
/*/
Class ItemPedidoVendaPortal
    Data    sequencia   as character
    Data    produto     as character
    Data    descricao   as character
    Data    unidade     as character
    Data    quantidade  as numeric
    Data    lote        as character

    Method New() CONSTRUCTOR
    
EndClass

Method New() Class ItemPedidoVendaPortal
    self:sequencia      := ""
    self:produto        := ""
    self:descricao      := ""
    self:unidade        := ""
    self:quantidade     := 0
    self:lote           := ""
Return