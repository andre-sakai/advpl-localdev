#include "Totvs.ch"

/*/{Protheus.doc} ProdutoDisponivelPortal
Classe responsável por armazenar informações 
do produto referente ao seu estoque.
@author Matheus José da Cunha
@since 25/09/2019
/*/
Class ProdutoDisponivelPortal
    Data    sequencia   as character
    Data    codigo      as character
    Data    descricao   as character
    Data    unidade     as character
    Data    saldo       as numeric
    Data    lote        as character

    Method New() CONSTRUCTOR
    
EndClass

Method New() Class ProdutoDisponivelPortal
    self:sequencia  := ""
    self:codigo     := ""
    self:descricao  := ""
    self:unidade    := ""
    self:saldo      := 0
    self:lote       := ""
Return