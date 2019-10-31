#include "Totvs.ch"

/*/{Protheus.doc} EstruturaJSONConfigPortal
Classe respons�ve pela estrutura de retorno 
JSON da aba configura��es
@author Matheus Jos� da Cunha
@since 03/10/2019
/*/
Class EstruturaJSONConfigPortal
    Data    token           as character
    Data    empresa_atual   as array
    Data    mensagem        as character

    Method New() CONSTRUCTOR
EndClass

Method New() Class EstruturaJSONConfigPortal
    self:token          := ""
    self:empresa_atual  := {}
    self:mensagem       := ""
Return