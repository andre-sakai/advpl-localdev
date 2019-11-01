#include "Totvs.ch"

/*/{Protheus.doc} StatusPedidoPortal
Classe repons�vel por amarzenar
dados de status do pedido.
@author Matheus Jos� da Cunha
@since 27/09/2019
/*/
Class StatusPedidoPortal
    Data    descricao       as character
    Data    data_ocorrencia  as date

    Method New() CONSTRUCTOR
EndClass

Method New() Class StatusPedidoPortal 
    self:descricao      := ""
    self:data_ocorrencia:= CtoD("  /  /  ")
Return