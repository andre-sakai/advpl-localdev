#include "Totvs.ch"
#include "restful.ch"

WSRESTFUL WsPortalFotos DESCRIPTION "Portal/App Cliente TECADI - Fotos Operacionais" FORMAT APPLICATION_JSON
    DATA    pToken      AS STRING
    DATA    pEmpresa    AS STRING

    WSMETHOD GET DESCRIPTION "Retorna as fotos operacionais do cliente de seus pedidos." WSSYNTAX "/WsPortalFotos"

END WSRESTFUL

WSMETHOD GET WSRECEIVE pToken, pEmpresa WSSERVICE WsPortalFotos
    Local   aToken      as array
    Local   cCodCli     as character
    Local   cCodLoj     as character
    Local   lRet        as logical 
    Local   oResponse   as object
    Private oToken      as object

    //Seta o tipo de retorno JSON
    ::setContentType("application/json")

    //Valida os parâmetros
    If ValType(self:pToken) <> "C" .or.;
    ValType(self:pEmpresa) <> "C"
        setRestFault(400,EncodeUTF8("Parâmetros obrigatórios não informados ou inválidos."))
        Return lRet
    EndIf 

    RpcSetType(3)
    RpcSetEnv( "99","01", , , , , , , , ,  )

    lRet        := .T.
    oResponse   := nil
    oToken      := TokenAuthPortal():New()
    cCodCli     := SubStr(self:pEmpresa,1,6)
    cCodLoj     := SubStr(self:pEmpresa,7,2)
    aToken      := oToken:validarToken(self:pToken,cCodCli,cCodLoj)

    If aToken[1]
        oResponse := oGetFotos(cCodCli,cCodLoj)

        If ValType(oResponse) == "O"
            ::setResponse(EncodeUTF8(FWJsonSerialize(oResponse,.F.,.T.)))
        Else
            lRet := .F.
            setRestFault(400,EncodeUTF8("Não há resultados de fotos."))
        EndIf
    Else
        setRestFault(aToken[2],EncodeUTF8(aToken[3]))
        lRet := .F.
    EndIf
Return lRet

/*/{Protheus.doc} oGetFotos
Retorna as fotos do cliente em formato de objeto 
de estrutura JSON.
@type  Static Function
@author Matheus José da Cunha
@since 02/10/2019
@param cCodCli, characters, código de cliente
@param cCodLoj, characters, código da loja do cliente
@return oRet, object, retorna um objeto de estrutura JSON
 /*/
Static Function oGetFotos(cCodCli,cCodLoj)
    Local   aFotos      as array
    Local   aDadosEmp   as array
    Local   aParams     as array
    Local   cQuery      as character
    Local   cAliasQry   as character 
    Local   oStm        as object
    Local   oRet        as object
    Local   oFoto       as object
    Local   oCliente    as object
    Default cCodCli     := ""
    Default cCodLoj     := ""

    //Inicializa as variáveis
    aParams     := {}
    aFotos      := {}
    aDadosEmp   := {} 
    cAliasQry   := getNextAlias()
    oRet        := nil

    aAdd(aParams,cCodCli)
    aAdd(aParams,cCodLoj)

    cQuery := " SELECT SZ6.Z6_EMISSAO, SZ6.Z6_PEDIDO, SC5.C5_NOTA,"
    cQuery += " SZ6.Z6_LINKFOT, SZ6.Z6_QTDFOTO"
    cQuery += " FROM " + RetSqlName("SZ6") + " SZ6 (nolock)"
    cQuery += " LEFT JOIN " + RetSqlName("SC5") + " SC5 (nolock) ON (SC5.C5_FILIAL = SZ6.Z6_FILIAL"
    cQuery += " 								  					 AND SZ6.Z6_PEDIDO = SC5.C5_NUM "
    cQuery += " 								  					 AND SZ6.D_E_L_E_T_ = ' ')"
    cQuery += " WHERE SZ6.Z6_TIPOMOV = 'S' "
    cQuery += " AND SZ6.Z6_CLIENTE = ?"
    cQuery += " AND SZ6.Z6_LOJA = ?"
    cQuery += " AND SZ6.Z6_FOTO = 'R'"
    cQuery += " AND SZ6.Z6_QTDFOTO > 0"
    cQuery += " AND SZ6.Z6_LINKFOT <> ' '" 
    cQuery += " AND SZ6.D_E_L_E_T_ = ' '"
    cQuery += " GROUP BY SZ6.Z6_EMISSAO, SZ6.Z6_PEDIDO, SC5.C5_NOTA,"
    cQuery += " SZ6.Z6_LINKFOT, SZ6.Z6_QTDFOTO"
    cQuery += " ORDER BY SZ6.Z6_EMISSAO DESC, SZ6.Z6_PEDIDO DESC"
    oStm := FWPreparedStatement():New(cQuery)
    oStm:setParams(aParams)
    cQuery := oStm:getFixQuery()
    oStm:destroy()
    MPSysOpenQuery(cQuery,cAliasQry)
    (cAliasQry)->(dbGoTop())

    While (cAliasQry)->( ! EoF() )
        oFoto := FotoPortal():New()
        oFoto:pedido        := AllTrim((cAliasQry)->Z6_PEDIDO)
        oFoto:nota_fiscal   := AllTrim((cAliasQry)->C5_NOTA)
        oFoto:path          := AllTrim((cAliasQry)->Z6_LINKFOT)
        oFoto:quantidade    := (cAliasQry)->Z6_QTDFOTO

        aAdd(aFotos,oFoto)
        (cAliasQry)->(dbSkip())
    EndD
    
    If Len(aFotos) > 0
        //Dados da empresa
        oCliente := EmpresaPortal():New()
        oCliente:codigo := cCodCli
        oCliente:loja   := cCodLoj
        oCliente:nome   := AllTrim(Posicione("SA1",1,xFilial("SA1")+cCodCli+cCodLoj,"A1_NOME"))
        aAdd(aDadosEmp,oCliente)
        oRet := EstruturaJSONFotosPortal():New()
        oRet:token := oToken:getToken()
        oRet:empresa_atual := aDadosEmp
        oRet:fotos := aFotos
    EndIf

    (cAliasQry)->(dbCloseArea())
    
Return oRet