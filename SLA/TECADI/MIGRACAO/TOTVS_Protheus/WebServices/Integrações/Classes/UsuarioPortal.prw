#include "Totvs.ch"

/*/{Protheus.doc} UsuarioPortal
Classe utilizada para atribuir as informações referente a
as informações do usuário da tabela AI3.
@type  Class
@author Matheus José da Cunha
@since 24/09/2019
/*/
Class UsuarioPortal
    Data    nome                as character
    Data    empresas_de_acesso  as array

    Method New() Constructor

EndClass

Method New() Class UsuarioPortal
    self:nome                   := ""
    self:empresas_de_acesso     := {}
Return  