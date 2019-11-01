#include "Totvs.ch"
#include "restful.ch"

WSRESTFUL WsPortalEstoque DESCRIPTION "Portal/App Cliente TECADI - Estoques Disponíveis do Cliente" FORMAT APPLICATION_JSON
    WSDATA  pToken      AS STRING 
    WSDATA  pEmpresa    AS STRING
    WSDATA  pTpRet      AS INTEGER

    WSMETHOD GET DESCRIPTION "Retorna dados de estoque de acordo com o tipo. 1 = Disponível / 2 = Bloqueado / 3 = Em Recebimento" WSSYNTAX "/WsPortalEstoque"
END WSRESTFUL

WSMETHOD GET WSRECEIVE pToken, pEmpresa ,pTpRet WSSERVICE WsPortalEstoque
    Local   aToken      as array
    Local   cCodCli     as character
    Local   cCodLoj     as character
    Local   cMsgError   as character
    Local   lRet        as logical
    Local   oResponse   as object
    Private oToken      as object

    //Seta o tipo de retorno JSON
    ::setContentType("application/json")

    If ValType(self:pToken) <> "C" .or.;
    ValType(self:pEmpresa) <> "C" .or.;
    ValType(self:pTpRet) <> "N"
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

        Do Case
            //Estoque Disponível
            Case self:pTpRet == 1
                oResponse := oGetDesp(cCodCli,cCodLoj)
                cMsgError := "Não há produtos com estoques disponíveis"
            //Em Recebimento
            Case self:pTpRet == 3
                oResponse := aGetReceb(cCodCli,cCodLoj)
                cMsgError := "Não há produtos no estoque em recebimento."
            Otherwise
                setRestFault(400,EncodeUTF8("Tipo de retorno não implementado."))
                Return lRet := .F.
        EndCase 

        If ValType(oResponse) == "O" 
            cJson := FWJsonSerialize(oResponse,.F.)
            ::setResponse(EncodeUTF8(cJson))
        Else
            setRestFault(400,EncodeUTF8(cMsgError))
            lRet := .F.
        EndIf
    Else
        setRestFault(aToken[2],EncodeUTF8(aToken[3]))
        lRet := .F.
    EndIf

Return lRet

/*/{Protheus.doc} oGetDesp
Retorna uma array ajustada para JSON referente aos
estoques disponíveis do cliente.
@type  Static Function
@author Matheus José da Cunha
@since 25/09/2019
@param cCodCli, characters, código do cliente
@param cCodLoj, characters, código da loja do cliente
@return oRet, object, objeto de estrtura JSON
/*/
Static Function oGetDesp(cCodCli,cCodLoj)
    Local   aParams     as array
    Local   aProdutos   as array
    Local   aDadosEmp   as array
    Local   cSeq        as character
    Local   cAliasQry   as character
    Local   cQuery      as character
    Local   oProduto    as object
    Local   oStm        as object
    Local   oCliente    as object
    Local   oRet        as object
    Default cCodCli     := ""
    Default cCodLoj     := ""

    //Inicializa as variáveis
    oRet        := nil
    aParams     := {}
    aDadosEmp   := {}
    aProdutos   := {}
    cAliasQry   := getNextAlias()
    cSeq        := "0001"
    
    aAdd(aParams,xFilial("SB1"))
    aAdd(aParams,cCodCli)
    aAdd(aParams,cCodLoj)

    cQuery := " SELECT * FROM"
    cQuery += "     (SELECT SB1.B1_COD CODIGO, SB1.B1_DESC, SB1.B1_UM, SB1.B1_RASTRO RASTRO, SB8.B8_LOTECTL,
    cQuery += "     (CASE 
    cQuery += "     	WHEN SB8.B8_LOTECTL IS NOT NULL THEN SB8.B8_SALDO-(SB8.B8_QACLASS+SB8.B8_EMPENHO)
    cQuery += "     	ELSE SB2.B2_QATU-(SB2.B2_QPEDVEN+SB2.B2_RESERVA+SB2.B2_QACLASS) "
    cQuery += "     END) SALDO"
    cQuery += "     	FROM " + RetSqlName("SB2") + " SB2 (nolock)"
    cQuery += "     	INNER JOIN " + RetSqlName("SB1") + " SB1 (nolock) ON (SB1.B1_FILIAL = ?"
    cQuery += "     							  AND SB1.B1_COD = SB2.B2_COD"
    cQuery += "     							  AND SB1.B1_MSBLQL <> '1'"
    cQuery += "     							  AND SB1.D_E_L_E_T_ = ' ')"
    cQuery += "     	INNER JOIN " + RetSqlName("SB6") + " SB6 (nolock) ON (SB6.B6_FILIAL = SB2.B2_FILIAL"
    cQuery += "     									   AND SB6.B6_PRODUTO = SB2.B2_COD"
    cQuery += "     									   AND SB6.B6_CLIFOR = ?"
    cQuery += "     									   AND SB6.B6_LOJA = ?"
    cQuery += "     									   AND SB6.D_E_L_E_T_ = ' ')"
    cQuery += "     	LEFT JOIN " + RetSqlName("SB8") + " SB8  (nolock) ON (SB8.B8_FILIAL = SB2.B2_FILIAL"
    cQuery += "     							 AND SB8.B8_PRODUTO = SB2.B2_COD"
    cQuery += "     							 AND SB8.B8_LOCAL = SB2.B2_LOCAL"
    cQuery += "     							 AND SB8.B8_SALDO > 0"
    cQuery += "     							 AND SB1.B1_RASTRO = 'L'"
    cQuery += "     							 AND SB8.D_E_L_E_T_ = ' ')"
    cQuery += "     	WHERE SB2.B2_FILIAL IN ('01','101','102','103','104','105','106')"
    cQuery += "     	AND SB2.B2_QATU > 0"
    cQuery += "     	AND SB2.D_E_L_E_T_ = ' '"
	cQuery += "     GROUP BY SB1.B1_COD, SB1.B1_DESC, SB1.B1_UM, SB1.B1_RASTRO,"
	cQuery += "     SB2.B2_QATU, SB2.B2_QPEDVEN, SB2.B2_RESERVA, SB2.B2_QACLASS, SB8.B8_QACLASS,"
	cQuery += "     SB8.B8_EMPENHO,SB8.B8_SALDO, SB8.B8_LOTECTL) AS SUB"
    cQuery += " WHERE SUB.SALDO > 0"
    cQuery += " ORDER BY SUB.RASTRO, SUB.CODIGO"
    oStm := FWPreparedStatement():New(cQuery)
    oStm:setParams(aParams)
    cQuery := oStm:getFixQuery()
    oStm:destroy()
    cQuery := ChangeQuery(cQuery)
    MPSysOpenQuery(cQuery,cAliasQry)

    (cAliasQry)->(dbGoTop())

    While (cAliasQry)->( ! EoF() )
        oProduto := ProdutoDisponivelPortal():New()
        oProduto:sequencia  := cSeq
        oProduto:codigo     := AllTrim((cAliasQry)->CODIGO)
        oProduto:descricao  := AllTrim((cAliasQry)->B1_DESC)
        oProduto:unidade    := (cAliasQry)->B1_UM
        oProduto:saldo      := (cAliasQry)->SALDO
        oProduto:lote       := AllTrim((cAliasQry)->B8_LOTECTL)

        aAdd(aProdutos,oProduto)

        cSeq := Soma1(cSeq)
        (cAliasQry)->(dbSkip())
    EndDo 

    If Len(aProdutos) > 0 
        //Dados da empresa
        oCliente := EmpresaPortal():New()
        oCliente:codigo := cCodCli
        oCliente:loja   := cCodLoj
        oCliente:nome   := AllTrim(Posicione("SA1",1,xFilial("SA1")+cCodCli+cCodLoj,"A1_NOME"))
        aAdd(aDadosEmp,oCliente)
        oRet := EstruturaJSONEstoquePortal():New()
        oRet:token := oToken:getToken()
        oRet:empresa_atual := aDadosEmp
        oRet:produtos := aProdutos
    EndIf

    (cAliasQry)->(dbCloseArea())
    
Return oRet

/*/{Protheus.doc} aGetReceb
Retorna uma array ajustada para JSON referente aos
estoques que estão em recebimento.
@type  Static Function
@author Matheus José da Cunha
@since 26/09/2019
@param cCodCli, characters, código do cliente
@param cCodLoj, characters, código da loja do cliente
@return oRet, object, objeto de estrtura JSON
/*/
Static Function aGetReceb(cCodCli,cCodLoj)
    Local   aParams     as array
    Local   aProdutos   as array
    Local   aDadosEmp   as array
    Local   cAliasQry   as character
    Local   cQuery      as character
    Local   cSeq        as character
    Local   oProduto    as object
    Local   oStm        as object
    Local   oRet        as object
    Default cCodCli     := ""
    Default cCodLoj     := ""

    //Inicializa as variáveis
    oRet        := nil
    aParams     := {}
    aProdutos   := {}
    aDadosEmp   := {}
    cAliasQry   := getNextAlias()
    cSeq        := "0001"

    aAdd(aParams,xFilial("SB1"))
    aAdd(aParams,cCodCli)
    aAdd(aParams,cCodLoj)

    cQuery := " SELECT SDA.DA_PRODUTO, SB1.B1_DESC, SB1.B1_UM,  SUM(SDA.DA_SALDO) SALDO,"
    cQuery += " SDA.DA_LOTECTL, SDA.DA_DOC,SDA.DA_SERIE"
    cQuery += " FROM " + RetSqlName("SDA") + " SDA (nolock)"
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " SB1 (nolock) ON (SB1.B1_FILIAL = ?"
    cQuery += "                                    AND SB1.B1_COD = SDA.DA_PRODUTO"
    cQuery += "                                    AND SB1.B1_MSBLQL <> '1'"
    cQuery += "                                    AND SB1.D_E_L_E_T_ = ' ')"
    cQuery += " WHERE SDA.DA_SALDO > 0"
    cQuery += " AND SDA.DA_CLIFOR = ?"
    cQuery += " AND SDA.DA_LOJA = ?"
    cQuery += " AND SDA.D_E_L_E_T_ = ' '"
    cQuery += " GROUP BY SDA.DA_PRODUTO, SDA.DA_LOTECTL, SDA.DA_DOC,"
    cQuery += " SDA.DA_SERIE,SB1.B1_DESC,SB1.B1_UM"
    cQuery += " ORDER BY SDA.DA_PRODUTO"
    oStm := FWPreparedStatement():New(cQuery)
    oStm:setParams(aParams)
    cQuery := oStm:getFixQuery()
    oStm:destroy()
    cQuery := ChangeQuery(cQuery)
    MPSysOpenQuery(cQuery,cAliasQry)

    (cAliasQry)->(dbGoTop())

    While (cAliasQry)->( ! EoF() )
        oProduto := ProdutoRecebimentoPortal():New()
        oProduto:sequencia  := cSeq
        oProduto:codigo     := AllTrim((cAliasQry)->DA_PRODUTO)
        oProduto:descricao  := AllTrim((cAliasQry)->B1_DESC)
        oProduto:unidade    := (cAliasQry)->B1_UM
        oProduto:saldo      := (cAliasQry)->SALDO
        oProduto:nf_origem  := AllTrim((cAliasQry)->DA_DOC+"/"+(cAliasQry)->DA_SERIE)
        
        aAdd(aProdutos,oProduto)

        cSeq := Soma1(cSeq)

        (cAliasQry)->(dbSkip())
    EndDo

    If Len(aProdutos) > 0
        //Dados da empresa
        oCliente := EmpresaPortal():New()
        oCliente:codigo := cCodCli
        oCliente:loja   := cCodLoj
        oCliente:nome   := AllTrim(Posicione("SA1",1,xFilial("SA1")+cCodCli+cCodLoj,"A1_NOME"))
        aAdd(aDadosEmp,oCliente)
        oRet := EstruturaJSONEstoquePortal():New()
        oRet:token := oToken:getToken()
        oRet:empresa_atual := aDadosEmp
        oRet:produtos := aProdutos
        oRet := oRet
    EndIf

    (cAliasQry)->(dbCloseArea())

Return oRet