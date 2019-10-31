#include "Totvs.ch"

/*/{Protheus.doc} EstruturaJSONAuthPortal
Classe respons�vel pela Estrutura JSON de Autentica��o.
@author Matheus Jos� da Cunha
@since 30/09/2019
@version version
/*/
Class EstruturaJSONAuthPortal
    Data    token           as character
    Data    usuario         as object

    Method New() CONSTRUCTOR

EndClass

Method New() Class EstruturaJSONAuthPortal
    self:token      := ""
    self:usuario    := nil
Return