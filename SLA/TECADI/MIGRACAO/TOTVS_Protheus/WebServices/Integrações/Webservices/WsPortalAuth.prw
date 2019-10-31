#include "Totvs.ch"
#include "restful.ch"

/*/{Protheus.doc} WsPortalAuth
WebService responsável por efetuar a autenticação do Portal 
com o cadastro de usuário do Portal no sistema.
loja do cliente da tabela AI4.
@author Matheus José da Cunha
@since 24/09/2019
/*/
WSRESTFUL WsPortalAuth DESCRIPTION "Portal/App Cliente TECADI - Autenticação de Usuário" FORMAT APPLICATION_JSON
    WSDATA  pLogin  AS STRING 
    WSDATA  pPass   AS STRING

    WSMETHOD POST DESCRIPTION "Valida o login de acordo com o Cadastro do Portal." WSSYNTAX "/WsPortalAuth"

END WSRESTFUL

WSMETHOD POST WSSERVICE WsPortalAuth
    Local   cLogin      as character
    Local   cSenha      as character
    Local   cJson       as character
    Local   lRet        as logical
    Local   oResponse   as object

    //Seta o tipo de retorno JSON
    ::setContentType("application/json")

    RpcSetType(3)
    RpcSetEnv( "99","01", , , , , , , , ,  )
    
    //Inicializa as variáveis
    oResponse   := nil
    cLogin      := ::GetHeader("pLogin")
    cSenha      := ::GetHeader("pPass")

    lRet := lVldForm(cLogin,cSenha)

    //Caso as validações de formulário esteja de acordo, prossegue.
    If lRet
        dbSelectArea("AI3")
        AI3->(dbSetOrder(5)) //AI3_FILIAL+AI3_EMAIL
        If AI3->(dbSeek(xFilial("AI3")+Padr(cLogin,TamSX3("AI3_EMAIL")[1])))
            If ! Empty(AllTrim(AI3->AI3_PSW)) .and. AllTrim(AI3->AI3_PSW) == cSenha
                //Resgasta a array de JSON
                oResponse := aGetResp(AI3->AI3_CODUSU)

                If ValType(oResponse) == "O"
                    //Verifica se foi gerado o token
                    If ! Empty(AllTrim(oResponse:token))
                        //Resposta de sucesso
                        cJson := FWJsonSerialize(oResponse,.F.)
                        ::setResponse(EncodeUTF8(cJson))
                    Else   
                        setRestFault(400,EncodeUTF8("Não foi possível gerar o token de acesso."))
                        lRet := .F.
                    EndIf
                Else
                    setRestFault(400,EncodeUTF8("Usuário sem loja de acesso."))
                    lRet := .F.
                EndIf
            Else 
                setRestFault(400,EncodeUTF8("E-mail ou Senha estão inválidos."))
                lRet := .F.
            EndIf
        Else
            setRestFault(400,EncodeUTF8("Usuário não cadastrado."))
            lRet := .F.
        EndIf

        AI3->(dbCloseArea())
    EndIf
    
Return lRet

/*/{Protheus.doc} lVldForm
Efetua as pré validações do formulário de autenticação, 
antes de efetuar a autenticação no sistema.
@type  Static Function
@author Matheus José da Cunha
@since 23/09/2019
@param cLogin, characters, login informado
@param cSenha, characters, senha informada
@return lRet, logical, retorna se está OK as pré validações
/*/
Static Function lVldForm(cLogin,cSenha)
    Local   lRet    as logical

    //Inicializa as variáveis
    lRet := .T.

    Do Case
        //Campos obrigatórios
        Case ValType(cLogin) <> "C" .or. ValType(cSenha) <> "C"  
            setRestFault(400,EncodeUTF8("Campos obrigatórios não preenchidos."))
            lRet := .F.
        //USUÁRIO VAZIO
        Case Empty(AllTrim(cLogin)) 
            setRestFault(400,EncodeUTF8("O campo de E-mail não foi preenchido."))
            lRet := .F.
        //SENHA VAZIA
        Case Empty(AllTrim(cSenha))
            setRestFault(400,EncodeUTF8("O campo de Senha não foi preenchido."))
            lRet := .F.
    EndCase
        
Return lRet

/*/{Protheus.doc} aGetResp
Retorna uma array de resposta pré pararada para serializar
o json
@type  Static Function
@author Matheus José da Cunha
@since 24/09/2019
@param cCodUsu, characters, código de usuário do portal
@return oRet, object, objeto de estrtura JSON
/*/
Static Function aGetResp(cCodUsu)
    Local   aEmpresas   as array
    Local   cChave      as character 
    Local   oToken      as character
    Local   oCliente    as object
    Local   oUsuario    as object
    Local   oRet
    Default cCodUsu     := ""

    //Inicializa as variáveis
    aEmpresas   := {}
    oRet        := nil

    If ! Empty(cCodUsu)
        dbSelectArea("AI4")
        AI4->(dbSetOrder(1))
        cChave := xFilial("AI4")+cCodUsu

        If AI4->(dbSeek(cChave))
            //Resgata as lojas de acesso
            While AI4->( ! EoF() ) .and. AI4->AI4_FILIAL+AI4->AI4_CODUSU == cChave
                oCliente := EmpresaPortal():New()
                oCliente:codigo := AI4->AI4_CODCLI
                oCliente:loja   := AI4->AI4_LOJCLI
                oCliente:nome   := AllTrim(Posicione("SA1",1,xFilial("SA1")+AI4->AI4_CODCLI+AI4->AI4_LOJCLI,"A1_NOME"))

                aAdd(aEmpresas,oCliente)

                AI4->(dbSkip())
            EndDo

            AI4->(dbCloseArea())

            If Len(aEmpresas) > 0
                //Token de acesso
                oToken := TokenAuthPortal():New()
                oToken:gerarToken(cCodUsu)
                //Dados do usuário
                oUsuario := UsuarioPortal():New()
                oUsuario:nome := AllTrim(AI3->AI3_NOME)
                oUsuario:empresas_de_acesso := aEmpresas
                oRet := EstruturaJSONAuthPortal():New()
                oRet:token := oToken:getToken()
                oRet:usuario := oUsuario
            EndIf
        EndIf
    EndIf

Return oRet
