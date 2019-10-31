#include "Totvs.ch"
#include "restful.ch"

WSRESTFUL WsPortalNFOrigemProduto DESCRIPTION "Portal/App Cliente TECADI - Consulta de Notas Fiscais de Origem do produto de Estoque Disponível"
    WSDATA  pToken      AS STRING   
    WSDATA  pEmpresa    AS STRING
    WSDATA  pProduto    AS STRING
    WSDATA  pLote       AS STRING OPTIONAL 

    WSMETHOD GET DESCRIPTION "Retorna as notas fiscais de origem do produto disponível." WSSYNTAX "/WsPortalNFOrigemProduto" 

END WSRESTFUL

WSMETHOD GET WSRECEIVE pToken, pEmpresa, pProduto, pLote WSSERVICE WsPortalNFOrigemProduto
    Local   aToken      as array
    Local   cCodCli     as character
    Local   cCodLoj     as character
    Local   cToken      as character
    Local   cProd       as character
    Local   cLote       as character
    Local   lRet        as logical
    Local   oResponse   as object
    Private oToken      as object

    //Seta o tipo de retorno JSON
    ::setContentType("application/json")

    If ValType(self:pToken) <> "C" .or.;
    ValType(self:pEmpresa) <> "C" .or.;
    ValType(self:pProduto) <> "C" 
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
    cProd       := self:pProduto
    cLote       := IIf(ValType(self:pLote) == "O",self:pLote,"")
    oToken      := TokenAuthPortal():New()
    aToken      := oToken:validarToken(cToken,cCodCli,cCodLoj)

    //Valida se o token é válido
    If aToken[1]
        oResponse := oGetNfs(cCodCli,cCodLoj,cProd,cLote)

        If ValType(oResponse) == "O"
            ::setResponse(EncodeUTF8(FWJsonSerialize(oResponse,.F.,.T.)))
        Else
            setRestFault(400,EncodeUTF8("Não há resultados de Notas Fiscais de origem."))
            lRet := .F.
        EndIf

    Else
        setRestFault(aToken[2],EncodeUTF8(aToken[3]))
        lRet := .F.
    EndIf
    
Return lRet

/*/{Protheus.doc} oGetNfs
Retorna uma estrutura JSON com as notas fiscais
origem do produto especificado.
@type  Static Function
@author Matheus José da Cunha
@since 04/10/2019
@param cCodCli, characters, código do cliente
@param cCodLoj, characters, código da loja de cliente
@return oRet, object, estrutura json em objeto
/*/
Static Function oGetNfs(cCodCli,cCodLoj,cProd,cLote)
    Local   aParams         as array
    Local   aNfs            as array
    Local   aDadosEmp       as array
    Local   cAliasQry       as character
    Local   cQuery          as character
    Local   oNotaFiscal     as object
    Local   oRet            as object
    Local   oCliente        as object
    Default cCodCli         := ""
    Default cCodLoj         := ""
    Default cProd           := ""
    Default cLote           := ""

    //Inicializa as variáveis
    oRet        := nil
    aParams     := {}
    aNfs        := {}   
    aDadosEmp   := {} 
    cAliasQry   := getNextAlias()

    aAdd(aParams,cCodCli)
    aAdd(aParams,cCodLoj)
    aAdd(aParams,cLote)
    aAdd(aParams,cProd)

    cQuery := " SELECT DOCUMENTO, SERIE, EMISSAO, SUM(SALDO) SALDO"
    cQuery += " FROM "
    cQuery += " 	(SELECT SB6.B6_DOC DOCUMENTO, SB6.B6_SERIE SERIE, SB6.B6_EMISSAO EMISSAO,"
    cQuery += " 	SB6.B6_SALDO SALDO,"
    cQuery += " 	 (Case "
    cQuery += " 		WHEN SB1.B1_RASTRO <> 'L' OR SD1.D1_LOTECTL IS NOT NULL THEN 1"
    cQuery += " 		ELSE 0"
    cQuery += " 	END) ADICIONA"
    cQuery += " 	FROM " + RetSqlName("SB2") + " SB2 (nolock)"
    cQuery += " 	INNER JOIN " + RetSqlName("SB1") + " SB1 (nolock) ON (SB1.B1_FILIAL = ' '"
    cQuery += " 							  AND SB1.B1_COD = SB2.B2_COD"
    cQuery += " 							  AND SB1.B1_MSBLQL <> '1'"
    cQuery += " 							  AND SB1.D_E_L_E_T_ = ' ')"
    cQuery += " 	INNER JOIN " + RetSqlName("SB6") + " SB6 (nolock) ON (SB6.B6_FILIAL = SB2.B2_FILIAL"
    cQuery += " 									   AND SB6.B6_PRODUTO = SB2.B2_COD"
    cQuery += " 									   AND SB6.B6_CLIFOR = ?"
    cQuery += " 									   AND SB6.B6_LOJA = ?"
    cQuery += " 									   AND SB6.B6_SALDO > 0"
    cQuery += " 									   AND SB6.D_E_L_E_T_ = ' ')"
    cQuery += " 	LEFT JOIN " + RetSqlName("SB8") + " SB8  (nolock) ON (SB8.B8_FILIAL = SB2.B2_FILIAL"
    cQuery += " 							 AND SB8.B8_PRODUTO = SB2.B2_COD
    cQuery += " 							 AND SB8.B8_LOTECTL = ?"
    cQuery += " 							 AND SB8.B8_LOCAL = SB2.B2_LOCAL"
    cQuery += " 							 AND SB8.B8_SALDO > 0"
    cQuery += " 							 AND SB1.B1_RASTRO = 'L'"
    cQuery += " 							 AND SB8.D_E_L_E_T_ = ' ')"
    cQuery += " 	LEFT JOIN " + RetSqlName("SD1") + " SD1 (nolock) ON (SD1.D1_FILIAL = SB8.B8_FILIAL"
    cQuery += " 								 AND SD1.D1_COD = SB2.B2_COD"
    cQuery += " 								 AND SD1.D1_LOCAL = SB2.B2_LOCAL"
    cQuery += " 								 AND SD1.D1_LOTECTL = SB8.B8_LOTECTL)"
    cQuery += " 	WHERE SB2.B2_COD = ?"
    cQuery += " 	AND SB2.B2_QATU > 0"
    cQuery += " 	AND SB2.D_E_L_E_T_ = ' '"
    cQuery += " 	GROUP BY SB6.B6_DOC,SB6.B6_SERIE,SB6.B6_EMISSAO, SB6.B6_SALDO,"
    cQuery += " 	SD1.D1_LOTECTL, SB1.B1_RASTRO) AS SUB"
    cQuery += " WHERE ADICIONA = 1"
    cQuery += " GROUP BY DOCUMENTO, SERIE, EMISSAO"
    oStm := FWPreparedStatement():New(cQuery)
    oStm:setParams(aParams)
    cQuery := oStm:getFixQuery()
    oStm:destroy()
    MPSysOpenQuery(cQuery,cAliasQry)
    (cAliasQry)->(dbGoTop())

    While (cAliasQry)->( ! EoF() )
        oNotaFiscal := NotaFiscalPortal():New()
        oNotaFiscal:numero  := AllTrim((cAliasQry)->DOCUMENTO)+"/"+AllTrim((cAliasQry)->SERIE)
        oNotaFiscal:emissao := (cAliasQry)->EMISSAO
        oNotaFiscal:saldo   := (cAliasQry)->SALDO

        aAdd(aNfs,oNotaFiscal)
    
        (cAliasQry)->(dbSkip())
    EndDo 

    If Len(aNfs) > 0
        //Dados da empresa
        oCliente := EmpresaPortal():New()
        oCliente:codigo := cCodCli
        oCliente:loja   := cCodLoj
        oCliente:nome   := AllTrim(Posicione("SA1",1,xFilial("SA1")+cCodCli+cCodLoj,"A1_NOME"))
        aAdd(aDadosEmp,oCliente)
        oRet := EstruturaJSONNFOrigemProd():New()
        oRet:token := oToken:getToken()
        oRet:empresa_atual := aDadosEmp
        oRet:notas_fiscais := aNfs
    EndIf 

    (cAliasQry)->(dbCloseArea())

Return oRet