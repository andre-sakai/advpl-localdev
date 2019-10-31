#include "Totvs.ch"
#include "restful.ch"

WSRESTFUL WsPortalConsultaPedidos DESCRIPTION "Portal/App Cliente TECADI - Consulta de Pedidos" FORMAT APPLICATION_JSON
    WSDATA  pToken      AS STRING
    WSDATA  pEmpresa    AS STRING

    WSMETHOD GET DESCRIPTION "Retorna uma consulta de pedidos dos últimos 30 dias." WSSYNTAX "/WsPortalConsultaPedidos"

END WSRESTFUL

WSMETHOD GET WSRECEIVE pToken, pEmpresa WSSERVICE WsPortalConsultaPedidos
    Local   aToken      as array
    Local   cCodCli     as character
    Local   cCodLoj     as character
    Local   lRet        as logical
    Local   oResponse   as object
    Local   oCliente    as object
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
            setRestFault(400,EncodeUTF8("Não há resultados de Pedidos de Venda."))
            lRet := .F.
        EndIf
    Else
        setRestFault(aToken[2],EncodeUTF8(aToken[3]))
        lRet := .F.
    EndIf
Return lRet 

/*/{Protheus.doc} oGetResp
Retorna uma array ajustada para JSON referente aos
pedidos de venda do cliente.
@type  Static Function
@author Matheus José da Cunha
@since 27/09/2019
@param cCodCli, characters, código do cliente
@return oRet, object, objeto de estrtura JSON
/*/
Static Function oGetResp(cCodCli,cCodLoj)
    Local   aParams     as array
    Local   aPedidos    as array
    Local   aDadosEmp   as array
    Local   cQuery      as character
    Local   cAliasQry   as character
    Local   oStm        as object
    Local   oPedido     as object 
    Local   oRet        as object
    Default cCodCli     := ""
    Default cCodLoj     := ""

    //Inicializa as variáveis
    oRet        := nil
    aParams     := {}
    aPedidos    := {}   
    aDadosEmp   := {} 
    cAliasQry   := getNextAlias()

    //Prepara os parâmetros da query
    aAdd(aParams,MsDate()-30)
    aAdd(aParams,MsDate())
    aAdd(aParams,cCodCli)
    aAdd(aParams,cCodLoj)

    /*
    Para o status, deve-se comparar Data/HORA da emissão do pedido com a finalização da OS de apanhe e montagem.
    A descrição deve obedecer as regras abaixo:

    Atendido no prazo: pedidos prontos para carregar (separação e montagem/conferência concluído) , finalizados dentro de 24 horas
    Atendido fora do prazo:pedidos prontos para carregar (separação e montagem/conferência concluído) , não finalizados dentro do prazo de 24 horas
    Em processamento: pedidos com OS gerada e iniciada, que não está 100% finalizada montagem/conferência, indiferente do prazo
    Backlog (pedidos em atraso): pedidos que estão em atraso (com OS não INICIADA ou sem OS, com mais de 24 horas da emissão do pedido)
    Aguardando: pedidos com OS gerada ou não, sem estar iniciada, com menos de 24 horas da emissão do pedido (pois se passar de 24 horas, já é atrasado/backlog
    Erro: outro status não previsto
    Importante: não considerar sábado e domingo como limite (se C5_EMISSAO for sábado/domingo, por exemplo, deve considerar segunda-feira 00:01 para o "início")
    */

    cQuery := " SELECT PED_TECADI, REPLACE(CONVERT(varchar,EMISSAO_PED),'-','') EMISSAO, "
    cQuery += " NF_TECADI,NF_CLIENTE, PED_CLIENTE, VOLUME,"
    cQuery += " 	(CASE "
    cQuery += " 		WHEN (DT_FINALIZADO = EMISSAO_PED OR (DATEDIFF(DAY,EMISSAO_PED,DT_FINALIZADO) = 1 AND HR_FINALIZADO <= HORA_PED)) AND STATUS_OS = 'FI'"
    cQuery += " 			THEN 'Atendimento no prazo'"
    cQuery += " 		WHEN EMISSAO_ORIGINAL = DT_FINALIZADO AND STATUS_OS = 'FI'"
    cQuery += " 			THEN 'Atendimento no prazo'"
    cQuery += " 		WHEN (DATEDIFF(DAY,EMISSAO_PED,DT_FINALIZADO) > 1 OR (DATEDIFF(DAY,EMISSAO_PED,DT_FINALIZADO) = 1 AND HR_FINALIZADO > HORA_PED)) AND STATUS_OS = 'FI'"
    cQuery += " 			THEN 'Atendimento fora do prazo'"
    cQuery += " 		WHEN (NUM_OS <> ' ' AND STATUS_OS = 'EX') OR (NUM_OS <> ' ' AND STATUS_OS IS NULL)"
    cQuery += " 			THEN 'Em processamento'"
    cQuery += " 		WHEN (NUM_OS = ' ' OR STATUS_OS = 'AG' OR STATUS_OS = 'PL') AND (DATA_ATUAL = EMISSAO_PED OR (DATEDIFF(DAY,EMISSAO_PED,DATA_ATUAL) = 1 AND HORA_PED <= HORA_ATUAL))"
    cQuery += " 			THEN 'Aguardando'"
    cQuery += " 		WHEN (NUM_OS = ' ' OR STATUS_OS = 'AG' OR STATUS_OS = 'PL') AND ((DATEDIFF(DAY,EMISSAO_PED,DATA_ATUAL) = 1 AND HORA_PED > HORA_ATUAL) OR DATEDIFF(DAY,EMISSAO_PED,DATA_ATUAL) > 1)" 
    cQuery += " 			THEN 'Backlog'"
    cQuery += " 		ELSE 'Erro'"
    cQuery += " 	END) STATUS_PROCESSO"
    cQuery += " FROM "
    cQuery += " 	(SELECT SC5.C5_NUM PED_TECADI ,SC5.C5_NOTA NF_TECADI, "
    cQuery += " 	SC5.C5_ZDOCCLI NF_CLIENTE ,SC5.C5_ZPEDCLI PED_CLIENTE, SC5.C5_VOLUME1 VOLUME,"
    cQuery += " 	CONVERT(DATE,Z06.Z06_DTFIM,106) DT_FINALIZADO, CONVERT(TIME,Z06.Z06_HRFIM,108) HR_FINALIZADO,"
    cQuery += " 	CONVERT(TIME,SC5.C5_ZHRINCL,108) HORA_PED, SC5.C5_ZNOSSEP NUM_OS, Z06.Z06_STATUS STATUS_OS, "
    cQuery += " 	CONVERT(DATE,GETDATE(),106) DATA_ATUAL, CONVERT(TIME,GETDATE(),106) HORA_ATUAL,"
    //Verifica se a data de emissão precisa ser ajustada
    cQuery += " 	CONVERT(DATE,SC5.C5_EMISSAO,106) EMISSAO_ORIGINAL,"
    cQuery += " 	(CASE"
    //Domingo
    cQuery += " 		WHEN DATEPART(weekday,CONVERT(DATE,SC5.C5_EMISSAO,106)) = 1"
    cQuery += " 			THEN DATEADD(day,1,CONVERT(DATE,SC5.C5_EMISSAO,106))"
    //Sábado
    cQuery += " 		WHEN DATEPART(weekday,CONVERT(DATE,SC5.C5_EMISSAO,106)) = 7"
    cQuery += " 			THEN DATEADD(day,2,CONVERT(DATE,SC5.C5_EMISSAO,106))"
    //Dia de semana
    cQuery += " 		ELSE CONVERT(DATE,SC5.C5_EMISSAO,106)"
    cQuery += " 	END) EMISSAO_PED"
    cQuery += " 	FROM " + RetSqlName("SC5") + " SC5 (nolock)"
    cQuery += " 	LEFT JOIN " + RetSqlName("Z06") + " Z06 (nolock) ON (Z06.Z06_FILIAL = SC5.C5_FILIAL"
    cQuery += " 									  AND Z06.Z06_NUMOS = SC5.C5_ZNOSSEP "
    cQuery += " 									  AND Z06.Z06_SEQOS = '002'"
    cQuery += " 									  AND Z06.D_E_L_E_T_ = ' ')"
    cQuery += " 	WHERE SC5.C5_EMISSAO BETWEEN ? AND ?"
    cQuery += " 	AND SC5.C5_CLIENTE = ?"
    cQuery += " 	AND SC5.C5_LOJACLI = ?"
    cQuery += " 	AND SC5.D_E_L_E_T_ = ' '"
    cQuery += " 	GROUP BY SC5.C5_NUM, SC5.C5_NOTA, SC5.C5_ZDOCCLI, SC5.C5_EMISSAO,"
    cQuery += " 	SC5.C5_ZPEDCLI,SC5.C5_VOLUME1, Z06.Z06_DTFIM, Z06.Z06_HRFIM,"
    cQuery += " 	SC5.C5_ZHRINCL, SC5.C5_ZNOSSEP, Z06.Z06_STATUS) AS SUB"
    oStm := FWPreparedStatement():New(cQuery)
    oStm:setParams(aParams)
    cQuery := oStm:getFixQuery()
    oStm:destroy()
    MPSysOpenQuery(cQuery,cAliasQry)
    (cAliasQry)->(dbGoTop())

    While (cAliasQry)->( ! EoF() )
        oPedido := PedidoVendaPortal():New()
        oPedido:numero              := AllTrim((cAliasQry)->PED_TECADI)
        oPedido:dt_emissao          := CtoD(DtoC(StoD(AllTrim((cAliasQry)->EMISSAO))))
        oPedido:nf_tecadi           := AllTrim((cAliasQry)->NF_TECADI)
        oPedido:nf_cliente          := AllTrim((cAliasQry)->NF_CLIENTE)
        oPedido:pedido_cliente      := AllTrim((cAliasQry)->PED_CLIENTE)
        oPedido:volume              := (cAliasQry)->VOLUME
        oPedido:status_processamento:= AllTrim((cAliasQry)->STATUS_PROCESSO)

        aAdd(aPedidos,oPedido)

        (cAliasQry)->(dbSkip())
    EndDo 

    If Len(aPedidos) > 0
        //Dados da empresa
        oCliente := EmpresaPortal():New()
        oCliente:codigo := cCodCli
        oCliente:loja   := cCodLoj
        oCliente:nome   := AllTrim(Posicione("SA1",1,xFilial("SA1")+cCodCli+cCodLoj,"A1_NOME"))
        aAdd(aDadosEmp,oCliente)
        oRet := EstruturaJSONConsPedidosPortal():New()
        oRet:token := oToken:getToken()
        oRet:empresa_atual := aDadosEmp
        oRet:pedidos := aPedidos
    EndIf

    (cAliasQry)->(dbCloseArea())
    
Return oRet