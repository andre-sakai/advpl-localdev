#include "Totvs.ch"
#include "restful.ch"

WSRESTFUL WsPortalConsultaDetalhesPedido DESCRIPTION "Portal/App Cliente TECADI - Consulta de detalhes de um Pedido de Venda específico" FORMAT APPLICATION_JSON
    WSDATA  pToken      AS STRING
    WSDATA  pEmpresa    AS STRING
    WSDATA  pPedTecadi  AS STRING
    WSDATA  pPedCli     AS STRING OPTIONAL

    WSMETHOD GET DESCRIPTION "Retorna os itens vinculados a um pedido de venda." WSSYNTAX "/WsPortalConsultaDetalhesPedido"

END WSRESTFUL

WSMETHOD GET WSRECEIVE pToken, pEmpresa, pPedTecadi, pPedCli WSSERVICE WsPortalConsultaDetalhesPedido 
    Local   aToken      as array
    Local   cCodCli     as character
    Local   cCodLoj     as character
    Local   cPedTecadi  as character
    Local   cPedCli     as character
    Local   lRet        as logical
    Local   oResponse   as object
    Private oToken      as object

    //Seta o tipo de retorno JSON
    ::setContentType("application/json")

    If ValType(self:pToken) <> "C" .or.;
    ValType(self:pEmpresa) <> "C" .or.;
    ValType(self:pPedTecadi) <> "C"
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
    cPedTecadi  := self:pPedTecadi
    cPedCli     := self:pPedCli
    oToken      := TokenAuthPortal():New()
    aToken      := oToken:validarToken(cToken,cCodCli,cCodLoj)

    //Valida se o token é válido
    If aToken[1]
        oResponse := oGetResp(cPedTecadi,cCodCli,cCodLoj,cPedCLi)

        If ValType(oResponse) == "O" 
            cJson := FWJsonSerialize(oResponse,.F.,.T.)
            ::setResponse(EncodeUTF8(cJson))
        Else
            setRestFault(400,EncodeUTF8("Não foi localizado o pedido especificado"))
            lRet := .F.
        EndIf

    Else
        setRestFault(aToken[2],EncodeUTF8(aToken[3]))
        lRet := .F.
    EndIf

Return lRet

/*/{Protheus.doc} oGetResp
Retorna uma array ajustada para JSON referente aos
detalhes do pedido
@type  Static Function
@author Matheus José da Cunha
@since 27/09/2019
@param cPedTecadi, characters, número do pedido de venda da TECADI
@param cCodCli, characters, código do cliente
@param cCodLoj, characters, código da loja
@param cPedCli, characters, número do pedido de venda do cliente
@return oRet, object, objeto de estrtura JSON
/*/
Static Function oGetResp(cPedTecadi,cCodCli,cCodLoj,cPedCli)
    Local   aParams         as array
    Local   cAliasQry       as character
    Local   cQuery          as character
    Local   cSeq            as character
    Local   lAddDetalhe     as logical
    Local   oStm            as object
    Local   oStatus         as object
    Local   oProduto        as object
    Local   oPedido         as object
    Local   oCliente        as object
    Local   oRet            as object
    Default cPedTecadi      := ""
    Default cCodCli         := ""
    Default cCodLoj         := ""
    Default cPedCli         := ""

    //Inicializa as variáveis
    oRet            := nil
    aParams         := {}
    cAliasQry       := getNextAlias()
    cSeq            := "0001"
    lAddDetalhe     := .T.

    aAdd(aParams,cPedTecadi)
    aAdd(aParams,cCodCli)
    aAdd(aParams,cCodLoj)

    cQuery := " SELECT PED_TECADI, REPLACE(CONVERT(varchar,EMISSAO_PED),'-','') EMISSAO, "
    cQuery += " NF_TECADI,NF_CLIENTE, PED_CLIENTE, VOLUME, PRODUTO, UNIDADE, DESCRICAO,"
    cQuery += " LOTE, QUANTIDADE,"
    cQuery += " 	(CASE "
    cQuery += " 		WHEN (DT_FINALIZADO = EMISSAO_PED OR (DATEDIFF(DAY,EMISSAO_PED,DT_FINALIZADO) = 1 AND HR_FINALIZADO <= HORA_PED)) AND STATUS_OS = 'FI'"
    cQuery += " 			THEN 'Atendimento no prazo'"
    cQuery += " 		WHEN EMISSAO_ORIGINAL = DT_FINALIZADO AND STATUS_OS = 'FI'"
    cQuery += " 			THEN 'Atendimento no prazo'"
    cQuery += " 		WHEN (DATEDIFF(DAY,EMISSAO_PED,DT_FINALIZADO) > 1 OR (DATEDIFF(DAY,EMISSAO_PED,DT_FINALIZADO) = 1 AND HR_FINALIZADO > HORA_PED)) AND STATUS_OS = 'FI'"
    cQuery += " 			THEN 'Atendimento fora do prazo'"
    cQuery += " 		WHEN (NUM_OS <> ' ' AND STATUS_OS = 'EX') OR (NUM_OS <> ' ' AND STATUS_OS IS NULL)"
    cQuery += " 			THEN 'Em processamento'"
    cQuery += " 		WHEN (NUM_OS = ' ' OR STATUS_OS = 'AG' OR STATUS_OS = 'PL') AND (DATA_ATUAL = EMISSAO_PED OR (DATEDIFF(DAY,EMISSAO_PED,DATA_ATUAL) = 1 AND HORA_PED < HORA_ATUAL))"
    cQuery += " 			THEN 'Aguardando'"
    cQuery += " 		WHEN (NUM_OS = ' ' OR STATUS_OS = 'AG' OR STATUS_OS = 'PL') AND ((DATEDIFF(DAY,EMISSAO_PED,DATA_ATUAL) = 1 AND HORA_PED > HORA_ATUAL) OR DATEDIFF(DAY,EMISSAO_PED,DATA_ATUAL) > 1) "
    cQuery += " 			THEN 'Backlog'"
    cQuery += " 		ELSE 'Erro'"
    cQuery += " 	END) STATUS_PROCESSO"
    cQuery += " FROM "
    cQuery += " 	(SELECT SC5.C5_NUM PED_TECADI ,SC9.C9_NFISCAL NF_TECADI, "
    cQuery += " 	SC5.C5_ZDOCCLI NF_CLIENTE ,SC5.C5_ZPEDCLI PED_CLIENTE, SC5.C5_VOLUME1 VOLUME,"
    cQuery += " 	CONVERT(DATE,Z06.Z06_DTFIM,106) DT_FINALIZADO, CONVERT(TIME,Z06.Z06_HRFIM,108) HR_FINALIZADO,"
    cQuery += " 	CONVERT(TIME,SC5.C5_ZHRINCL,108) HORA_PED, SC5.C5_ZNOSSEP NUM_OS, Z06.Z06_STATUS STATUS_OS, "
    cQuery += " 	CONVERT(DATE,GETDATE(),106) DATA_ATUAL, CONVERT(TIME,GETDATE(),106) HORA_ATUAL, SC6.C6_PRODUTO PRODUTO,"
    cQuery += " 	CONVERT(DATE,SC5.C5_EMISSAO,106) EMISSAO_ORIGINAL, SB1.B1_UM UNIDADE, SB1.B1_DESC DESCRICAO, "
    cQuery += " 	SC9.C9_LOTECTL LOTE, SC6.C6_ITEM ITEM, SC6.C6_QTDVEN QUANTIDADE,"
    cQuery += " 	(CASE"
    cQuery += " 		WHEN DATEPART(weekday,CONVERT(DATE,SC5.C5_EMISSAO,106)) = 1"
    cQuery += " 			THEN DATEADD(day,1,CONVERT(DATE,SC5.C5_EMISSAO,106))"
    cQuery += " 		WHEN DATEPART(weekday,CONVERT(DATE,SC5.C5_EMISSAO,106)) = 7"
    cQuery += " 			THEN DATEADD(day,2,CONVERT(DATE,SC5.C5_EMISSAO,106))"
    cQuery += " 		ELSE CONVERT(DATE,SC5.C5_EMISSAO,106)"
    cQuery += " 	END) EMISSAO_PED"
    cQuery += " 	FROM " + RetSqlName("SC5") + " SC5 (nolock)"
    cQuery += " 	INNER JOIN " + RetSqlName("SC6") + " SC6 (nolock) ON (SC6.C6_FILIAL = SC5.C5_FILIAL"
    cQuery += " 									   AND SC6.C6_NUM = SC5.C5_NUM"
    cQuery += " 									   AND SC6.D_E_L_E_T_ = ' ')"
    cQuery += " 	LEFT JOIN " + RetSqlName("SC9") + " SC9 (nolock) ON (SC9.C9_FILIAL = SC6.C6_FILIAL"
    cQuery += " 									  AND SC9.C9_CLIENTE = SC6.C6_CLI"
    cQuery += " 									  AND SC9.C9_LOJA = SC6.C6_LOJA"
    cQuery += " 									  AND SC9.C9_PEDIDO = SC6.C6_NUM"
    cQuery += " 									  AND SC9.C9_ITEM = SC6.C6_ITEM"
    cQuery += " 									  AND SC9.D_E_L_E_T_ = ' ')"
    cQuery += " 	INNER JOIN " + RetSqlName("SB1") + " SB1 (nolock) ON (SB1.B1_FILIAL = ' '"
    cQuery += " 									   AND SB1.B1_COD = SC6.C6_PRODUTO"
    cQuery += " 									   AND SB1.D_E_L_E_T_ = ' ')"
    cQuery += " 	LEFT JOIN " + RetSqlName("Z06") + " Z06 (nolock) ON (Z06.Z06_FILIAL = SC5.C5_FILIAL"
    cQuery += " 									  AND Z06.Z06_NUMOS = SC5.C5_ZNOSSEP "
    cQuery += " 									  AND Z06.Z06_SEQOS = '002'"
    cQuery += " 									  AND Z06.D_E_L_E_T_ = ' ')"
    cQuery += " 	WHERE SC5.C5_NUM = ?"
    cQuery += " 	AND SC5.C5_CLIENTE = ?"
    cQuery += " 	AND SC5.C5_LOJACLI = ?"
    If ! Empty(AllTrim(cPedCli))
        aAdd(aParams,cPedCli)
        cQuery += " 	AND SC5.C5_ZPEDCLI = ?"
    EndIf
    cQuery += " 	AND SC5.D_E_L_E_T_ = ' '"
    cQuery += " 	GROUP BY SC5.C5_NUM, SC9.C9_NFISCAL, SC5.C5_ZDOCCLI, SC5.C5_EMISSAO,"
    cQuery += " 	SC5.C5_ZPEDCLI,SC5.C5_VOLUME1, Z06.Z06_DTFIM, Z06.Z06_HRFIM,"
    cQuery += " 	SC5.C5_ZHRINCL, SC5.C5_ZNOSSEP, Z06.Z06_STATUS, SC6.C6_PRODUTO,"
    cQuery += " 	SB1.B1_UM, SB1.B1_DESC, SC9.C9_LOTECTL, SC6.C6_ITEM,SC6.C6_QTDVEN"
    cQuery += " 	) AS SUB"
    cQuery += " ORDER BY PED_TECADI"
    oStm := FWPreparedStatement():New(cQuery)
    oStm:setParams(aParams)
    cQuery := oStm:getFixQuery()
    oStm:destroy()
    MPSysOpenQuery(cQuery,cAliasQry)
    (cAliasQry)->(dbGoTop())

    If (cAliasQry)->( ! EoF() )
        While (cAliasQry)->( ! EoF() )
            
            //Adiciona Detalhes do pedido
            If lAddDetalhe
                //Status do pedido
                oStatus := StatusPedidoPortal():New()
                oStatus:descricao       := "Teste" //AllTrim((cAliasQry)->STATUS_OCORRENCIA)
                oStatus:data_ocorrencia := CtoD("10/10/2019") //AllTrim((cAliasQry)->DATA_OCORRENCIA)

                //Informações do pedido
                oPedido := PedidoVendaPortal():New()
                oPedido:numero              := AllTrim((cAliasQry)->PED_TECADI)
                oPedido:dt_emissao          := CtoD(DtoC(StoD(AllTrim((cAliasQry)->EMISSAO))))
                oPedido:nf_tecadi           := AllTrim((cAliasQry)->NF_TECADI)
                oPedido:nf_cliente          := AllTrim((cAliasQry)->NF_CLIENTE)
                oPedido:pedido_cliente      := AllTrim((cAliasQry)->PED_CLIENTE)
                oPedido:volume              := (cAliasQry)->VOLUME
                oPedido:status_processamento:= AllTrim((cAliasQry)->STATUS_PROCESSO)
                oPedido:status_pedido       := oStatus
                lAddDetalhe := .F. 
            EndIf

            //Itens
            oProduto := ItemPedidoVendaPortal():New()
            oProduto:sequencia  := cSeq
            oProduto:produto    := AllTrim((cAliasQry)->PRODUTO)
            oProduto:descricao  := AllTrim((cAliasQry)->DESCRICAO)
            oProduto:unidade    := AllTrim((cAliasQry)->UNIDADE)
            oProduto:quantidade := (cAliasQry)->QUANTIDADE
            oProduto:lote       := AllTrim((cAliasQry)->LOTE)

            aAdd(oPedido:itens,oProduto)

            cSeq := Soma1(cSeq)

            (cAliasQry)->(dbSkip())
        EndDo 

        oCliente := EmpresaPortal():New()
        oCliente:codigo := cCodCli
        oCliente:loja   := cCodLoj
        oCliente:nome   := AllTrim(Posicione("SA1",1,xFilial("SA1")+cCodCli+cCodLoj,"A1_NOME"))
        oRet := EstruturaJSONConsPedidosPortal():New()
        oRet:token := oToken:getToken()
        aAdd(oRet:empresa_atual,oCliente)
        aAdd(oRet:pedidos,oPedido)
    EndIf

    (cAliasQry)->(dbCloseArea())
    
Return oRet