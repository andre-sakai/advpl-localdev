#include "Totvs.ch"
#include "restful.ch"

WSRESTFUL WsPortalConfig DESCRIPTION "Portal/App Cliente TECADI - Configuração de Usuário" FORMAT APPLICATION_JSON
    WSDATA  pToken          AS STRING
    WSDATA  pEmpresa        AS STRING
    WSDATA  pOldPass        AS STRING
    WSDATA  pNewPass        AS STRING
    WSDATA  pConfirmPass    AS STRING

    WSMETHOD PUT DESCRIPTION "Atualiza a senha do usuário" WSSYNTAX "/WsPortalConfig"
END WSRESTFUL

WSMETHOD PUT WSRECEIVE pToken, pEmpresa, pOldPass, pNewPass, pConfirmPass WSSERVICE WsPortalConfig
    Local   aToken      as array
    Local   cCodCli     as character
    Local   cCodLoj     as character
    Local   cOldPass    as character
    Local   cNewPass    as character
    Local   cConfPass   as character
    Local   lRet        as logical
    Local   oResponse   as object   
    Local   oCliente    as object
    Private oToken      as object

    ::setContentType("application/json")

    RpcSetType(3)
    RpcSetEnv('99','01', , , , , , , , ,  )

    //Valida os parâmetros
    If ValType(self:pToken) <> "C" .or.;
    ValType(self:pEmpresa) <> "C" .or.;
    ValType(self:pOldPass) <> "C" .or.;
    ValType(self:pNewPass) <> "C" .or.;
    ValType(self:pConfirmPass) <> "C"
        setRestFault(400,EncodeUTF8("Parâmetros obrigatórios não informados ou inválidos."))
        Return lRet
    EndIf 

    lRet        := .T.
    oResponse   := nil
    oToken      := TokenAuthPortal():New()
    cCodCli     := SubStr(self:pEmpresa,1,6)
    cCodLoj     := SubStr(self:pEmpresa,7,2)
    cOldPass    := self:pOldPass
    cNewPass    := self:pNewPass
    cConfPass   := self:pConfirmPass
    aToken      := oToken:validarToken(self:pToken,cCodCli,cCodLoj)

    If aToken[1]
        dbSelectArea("AI3")
        AI3->(dbSetOrder(1))
        Do Case
            //Valida a senha antiga e já posiciona no código de usuário na AI3
            Case ! lVldOldPass(cOldPass)
                lRet := .F.
            Case cNewPass <> cConfPass
                lRet := .F.
                setRestFault(400,EncodeUTF8("A nova senha não confere com sua confirmação."))
            Case cNewPass == cOldPass
                lRet := .F.
                setRestFault(400,EncodeUTF8("A nova senha não pode ser a mesma que a senha atual."))
        EndCase 

        If lRet
            Begin Transaction
                If RecLock("AI3",.F.)
                    Replace AI3->AI3_PSW    With    AllTrim(cNewPass)
                    AI3->(msUnlock())
                    oCliente := EmpresaPortal():New()
                    oCliente:codigo := cCodCli
                    oCliente:loja   := cCodLoj
                    oCliente:nome   := AllTrim(Posicione("SA1",1,xFilial("SA1")+cCodCli+cCodLoj,"A1_NOME"))

                    oResponse := EstruturaJSONConfigPortal():New()
                    oResponse:token := oToken:getToken()
                    aAdd(oResponse:empresa_atual,oCliente)
                    oResponse:mensagem := "Senha alterada com sucesso."
                    ::setResponse(FWJsonSerialize(oResponse,.F.))
                Else 
                    DisarmTransaction()
                    lRet := .F.
                    setRestFault(400,"Erro inesperado ao atualizar a senha.")
                EndIf
            End Transaction
        EndIf

        AI3->(dbCloseArea())
    Else
        setRestFault(aToken[2],EncodeUTF8(aToken[3]))
        lRet := .F.
    EndIf

Return lRet 

/*/{Protheus.doc} lVldOldPass
Valida se senha atual (antiga) está correta
@type  Static Function
@author Matheus José da Cunha
@since 01/10/2019
@param cOldPass, characters, senha antiga do usuário (atual)
@return lRet, logical, indica se a senha está correta
/*/
Static Function lVldOldPass(cOldPass)
    Local   cQuery      as character
    Local   cAliasQry   as character
    Local   lRet        as logical
    Default cOldPass    := ""

    //Inicializa as variáveis
    lRet        := .F.
    cAliasQry   := getNextAlias()

    cQuery := " SELECT SESSION_LOGIN"
    cQuery += " FROM PORTAL_SESSION"
    cQuery += " WHERE SESSION_ID = '" + oToken:getToken() + "'"
    MPSysOpenQuery(cQuery,cAliasQry) 

    (cAliasQry)->(dbGoTop())
    If (cAliasQry)->( ! EoF() )
        If AI3->(dbSeek(xFilial("AI3")+Padr(AllTrim((cAliasQry)->SESSION_LOGIN),TamSX3("AI4_CODUSU")[1])))
            If AllTrim(AI3->AI3_PSW) == cOldPass
                lRet := .T.
            Else
                setRestFault(400,EncodeUTF8("A senha atual está incorreta."))
            EndIf
        Else
            setRestFault(400,EncodeUTF8("Usuário não encontrado."))
        EndIf
    Else
        setRestFault(400,EncodeUTF8("Usuário não autenticado."))
    EndIf

    (cAliasQry)->(dbCloseArea())

Return lRet