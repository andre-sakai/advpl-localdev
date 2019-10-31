#include "Totvs.ch"
#include "restful.ch"

WSRESTFUL WsPortalFaturados DESCRIPTION "Portal/App Cliente TECADI - Consulta Financeiro de Faturados" FORMAT APPLICATION_JSON
    WSDATA  pToken      AS STRING
    WSDATA  pEmpresa    AS STRING

    WSMETHOD GET DESCRIPTION "Retorna um consulta do financeiro de pedidos que foram faturados." WSSYNTAX "/WsPortalFaturados"

END WSRESTFUL

WSMETHOD GET WSRECEIVE pToken, pEmpresa WSSERVICE WsPortalFaturados
    Local   aToken      as array
    Local   cCodCli     as character
    Local   cCodLoj     as character
    Local   lRet        as logical
    Local   oResponse   as object
    Private oToken      as object 

    //Seta o tipo de retorno JSON
    ::setContentType("application/json")

    If ValType(self:pToken) <> "C" .or.;
    ValType(self:pEmpresa) <> "C"
        setRestFault(400,EncodeUTF8("Parâmetros obrigatórios não informados ou inválidos."))
        Return lRet
    EndIf 

    RpcSetType(3)
    RpcSetEnv('99','01', , , , , , , , ,  )

    //Inicializa as variáveis
    oResponse   := nil
    lRet        := .T.
    cToken      := self:pToken
    cCodCli     := SubStr(self:pEmpresa,1,6)
    cCodLoj     := SubStr(self:pEmpresa,7,2)
    oToken      := TokenAuthPortal():New()
    aToken      := oToken:validarToken(cToken,cCodCli,cCodLoj)

    //Valida se o token é válido
    If aToken[1]
        oResponse := oGetResp(cCodCli,cCodLoj)

        If ValType(oResponse) == "O"
            cJson := FWJsonSerialize(oResponse,.F.,.T.)
            ::setResponse(EncodeUTF8(cJson))
        Else
            setRestFault(400,EncodeUTF8("Não há resultados de Pedidos Faturados."))
            lRet := .F.
        EndIf
    Else
        setRestFault(aToken[2],EncodeUTF8(aToken[3]))
        lRet := .F.
    EndIf

Return  lRet

/*/{Protheus.doc} oGetResp
Retorna uma array ajustada para JSON referente aos
pedidos de venda do cliente que estejam faturados.
@type  Static Function
@author Matheus José da Cunha
@since 30/09/2019
@param cCodCli, characters, código do cliente
#param cCodLoj, characters, código da loja do cliente
@return oRet, object, objeto de estrtura JSON
/*/
Static Function oGetResp(cCodCli,cCodLoj)
    Local   aParams     as array
    Local   aFaturados  as array
    Local   aDadosEmp   as array
    Local   cQuery      as character
    Local   cAliasQry   as character
    Local   oStm        as object
    Local   oFaturado   as object
    Local   oRet        as object
    Local   oCliente    as object
    Default cCodCli := ""
    Default cCodLoj := ""

    //Inicializa as variáveis
    oRet        := nil
    aParams     := {}
    aFaturados  := {}
    aDadosEmp   := {}
    cAliasQry   := getNextAlias()

    //Prepara os parâmetros da query
    aAdd(aParams,cCodCli)
    aAdd(aParams,cCodLoj)

    //Consulta SQL
    cQuery := " SELECT SC5.C5_NOTA+'/'+SC5.C5_SERIE NOTA, SC5.C5_ZPEDCLI, SC5.C5_NUM,"
    cQuery += " SE1.E1_EMISSAO,SE1.E1_VENCREA, SE1.E1_SALDO,"
    cQuery += " 	(CASE"
    cQuery += " 		WHEN CONVERT(DATE,SE1.E1_VENCREA) < CONVERT(DATE,getDate())"
    cQuery += " 			THEN 'Vencido'"
    cQuery += " 		ELSE 'A vencer'"
    cQuery += " 	END) STATUS_TITULO"
    cQuery += " FROM " + RetSqlName("SE1") + " SE1 (nolock)"
    cQuery += " INNER JOIN " + RetSqlName("SC5") + " SC5 (nolock) ON (SC5.C5_FILIAL = SE1.E1_FILIAL"
    cQuery += " 								   AND SC5.C5_NUM = SE1.E1_PEDIDO"
    cQuery += " 								   AND SC5.C5_NOTA = SE1.E1_NUM" 
    cQuery += " 								   AND SC5.C5_SERIE = SE1.E1_PREFIXO"
    cQuery += " 								   AND SC5.C5_CLIENTE = SE1.E1_CLIENTE"
    cQuery += " 								   AND SC5.C5_LOJACLI = SE1.E1_LOJA"
    cQuery += " 								   AND SC5.C5_TIPOOPE = 'S'"
    cQuery += " 								   AND SC5.D_E_L_E_T_ = ' ')"
    cQuery += " WHERE SE1.E1_CLIENTE = ?"
    cQuery += " AND SE1.E1_LOJA = ?"
    cQuery += " AND SE1.E1_PREFIXO = 'SE1'"
    cQuery += " AND SE1.E1_TIPO = 'NF'"
    cQuery += " AND SE1.E1_SALDO > 0 "
    cQuery += " AND SE1.D_E_L_E_T_ = ' '"
    cQuery += " GROUP BY SE1.E1_EMISSAO,SE1.E1_VENCREA, SE1.E1_VALOR,SE1.E1_CLIENTE,"
    cQuery += " SE1.E1_LOJA,SE1.E1_SALDO, SC5.C5_NOTA, SC5.C5_SERIE,"
    cQuery += " SC5.C5_ZPEDCLI, SE1.E1_NUM, SC5.C5_NUM"
    cQuery += " ORDER BY SE1.E1_NUM"
    oStm := FWPreparedStatement():New(cQuery)
    oStm:setParams(aParams)
    cQuery := oStm:getFixQuery()
    oStm:destroy()
    MPSysOpenQuery(cQuery,cAliasQry)
    TCSetField((cAliasQry),"E1_EMISSAO","D")
    TCSetField((cAliasQry),"E1_VENCREA","D")

    (cAliasQry)->(dbGoTop())

    While (cAliasQry)->( ! EoF() )
        oFaturado := PedidoFaturadoPortal():New()
        oFaturado:NF            := AllTrim((cAliasQry)->NOTA)
        oFaturado:PO            := AllTrim((cAliasQry)->C5_ZPEDCLI)
        oFaturado:pedido_tecadi := AllTrim((cAliasQry)->C5_NUM)
        oFaturado:data_emissao  := (cAliasQry)->E1_EMISSAO
        oFaturado:data_vencreal := (cAliasQry)->E1_VENCREA
        oFaturado:valor         := (cAliasQry)->E1_SALDO
        oFaturado:status        := (cAliasQry)->STATUS_TITULO

        aAdd(aFaturados,oFaturado)

        (cAliasQry)->(dbSkip())
    EndDo

    If Len(aFaturados) > 0
        //Dados da empresa
        oCliente := EmpresaPortal():New()
        oCliente:codigo := cCodCli
        oCliente:loja   := cCodLoj
        oCliente:nome   := AllTrim(Posicione("SA1",1,xFilial("SA1")+cCodCli+cCodLoj,"A1_NOME"))
        aAdd(aDadosEmp,oCliente)
        oRet := EstruturaJSONFaturadosPortal():New()
        oRet:token := oToken:getToken()
        oRet:empresa_atual := aDadosEmp
        oRet:faturados := aFaturados
    EndIf

    (cAliasQry)->(dbCloseArea())
Return oRet
