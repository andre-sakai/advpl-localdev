#include "Totvs.ch"

/*/{Protheus.doc} ProdutoRecebimentoPortal
Classe utilizada para atribuir informaçõe sobre
o produto que esteja no estoque em recebimento.
@author Matheus José da Cunha
@since 26/09/2019
/*/
Class ProdutoRecebimentoPortal
    Data    sequencia   as character
    Data    codigo      as character
    Data    descricao   as character
    Data    unidade     as character
    Data    saldo       as character
    Data    nf_origem   as character
    
    Method New() CONSTRUCTOR
EndClass

Method New() Class ProdutoRecebimentoPortal
    self:sequencia  := ""
    self:codigo     := ""
    self:descricao  := ""
    self:unidade    := ""
    self:saldo      := ""
    self:nf_origem  := ""      
Return