#include "Totvs.ch"

/*/{Protheus.doc} UsuarioPortal
Classe utilizada para atribuir as informa��es referente a
as informa��es do usu�rio da tabela AI3.
@type  Class
@author Matheus Jos� da Cunha
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