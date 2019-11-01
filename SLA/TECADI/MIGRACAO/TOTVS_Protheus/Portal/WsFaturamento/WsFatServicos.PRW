#Include "APWEBSRV.CH"
#Include "PROTHEUS.CH"

// criacao do Web Service
WSSERVICE WsFatServicos DESCRIPTION "Web Service Faturamento de Serviços"
	
	// variaveis de envio
	WSDATA RecUsrPortal        AS String
	WSDATA RecIdSessionPortal  AS String
	WSDATA RecCodFilial        AS String
	WSDATA RecCodCli           AS String
	WSDATA RecLojCli           AS String
	WSDATA RecDataEmissaoDe    AS Date
	WSDATA RecDataEmissaoAte   AS Date
	WSDATA RecTipoPeriodo      AS String
	
	// variaveis de retorno
	WSDATA RetFatSrvFatServicosDet AS ARRAY OF StFatSrvFatServicosDet
	WSDATA RetFatSrvNotasFiscais   AS ARRAY OF StFatSrvNotasFiscais
	
	// declaracao dos metodos
	WSMETHOD FatSrvListaFaturamentoServicos     DESCRIPTION "Listar os detalhes do faturamento de servicos"
	WSMETHOD FatSrvListaNotasFiscais            DESCRIPTION "Listar notas fiscais/recibos de serviços"
	
ENDWSSERVICE

// criacao do metodo
WSMETHOD FatSrvListaFaturamentoServicos WSRECEIVE RecUsrPortal, RecIdSessionPortal, RecCodFilial, RecCodCli, RecLojCli, RecDataEmissaoDe, RecDataEmissaoAte, RecTipoPeriodo WSSEND RetFatSrvFatServicosDet WSSERVICE WsFatServicos
	
	Local _cQuery, _cQryGroup
	local _aDados
	local _nDados
	local _nItem
	// periodos
	local _aPeriodos := {}
	local _nPeriodos
	
	// objeto pra validar login
	local _oWsLogin := WSWSCFGLOGIN():New()

	// valores padroes	
	Default ::RecDataEmissaoDe  := FirstDay(Date())
	Default ::RecDataEmissaoAte := Date()

	// validacao de tipo de variavel
	If ValType(::RecUsrPortal) != 'C'      ; setSoapFault("FATURAMENTO POR SERVICOS","Formato do parâmetro RecUsrPortal inválido (expected C)")      ; Return .F.; EndIf
	If ValType(::RecIdSessionPortal) != 'C'; setSoapFault("FATURAMENTO POR SERVICOS","Formato do parâmetro RecIdSessionPortal inválido (expected C)"); Return .F.; EndIf
	If ValType(::RecCodFilial) != 'C'      ; setSoapFault("FATURAMENTO POR SERVICOS","Formato do parâmetro RecCodFilial inválido (expected C)")      ; Return .F.; EndIf
	If ValType(::RecCodCli) != 'C'         ; setSoapFault("FATURAMENTO POR SERVICOS","Formato do parâmetro RecCodCli inválido (expected C)")         ; Return .F.; EndIf
	If ValType(::RecLojCli) != 'C'         ; setSoapFault("FATURAMENTO POR SERVICOS","Formato do parâmetro RecLojCli inválido (expected C)")         ; Return .F.; EndIf
	If ValType(::RecDataEmissaoDe) != 'D'  ; setSoapFault("FATURAMENTO POR SERVICOS","Formato do parâmetro RecDataEmissaoDe inválido (expected D)")  ; Return .F.; EndIf
	If ValType(::RecDataEmissaoAte) != 'D' ; setSoapFault("FATURAMENTO POR SERVICOS","Formato do parâmetro RecDataEmissaoAte inválido (expected D)") ; Return .F.; EndIf
	If ValType(::RecTipoPeriodo) != 'C'    ; setSoapFault("FATURAMENTO POR SERVICOS","Formato do parâmetro RecTipoPeriodo inválido (expected C)")    ; Return .F.; EndIf

	// valores padroes		
	::RecDataEmissaoDe  := IIf(Empty(::RecDataEmissaoDe) , FirstDay(Date()), ::RecDataEmissaoDe )
	::RecDataEmissaoAte := IIf(Empty(::RecDataEmissaoAte), Date()          , ::RecDataEmissaoAte)

	// valida session
	If ! _oWsLogin:CFGVALIDSESSION(::RecUsrPortal, ::RecIdSessionPortal)
		setSoapFault("FATURAMENTO POR SERVICOS","Sessão inválida ou Sessão Expirou!")
		Return(.f.)
	EndIf
	
	// obrigatorio informar o codigo da filial
	If Empty(::RecCodFilial)
		setSoapFault("FATURAMENTO POR SERVICOS","Campo filial é obrigatório.")
		Return(.f.)
	EndIf
	
	// obrigatorio informar o codigo do cliente
	If (Empty(::RecCodCli)).or.(Empty(::RecLojCli))
		setSoapFault("FATURAMENTO POR SERVICOS","Campos código e loja do cliente são obrigatórios.")
		Return(.f.)
	EndIf
	
	// obrigatorio informar tipo do periodo
	If (Empty(::RecTipoPeriodo))
		setSoapFault("FATURAMENTO POR SERVICOS","Campo tipo do período é obrigatório.")
		Return(.f.)
	EndIf
	
	// valida se os dados estao corretos para o login
	If ( ! U_FtPrtLgn(::RecUsrPortal, ::RecCodCli, ::RecLojCli, ::RecTipoPeriodo, Nil))
		setSoapFault("FATURAMENTO POR SERVICOS","Dados não permitidos para o login informado.")
		Return(.f.)
	EndIf
	
	// funcao para gerar os periodos
	_aPeriodos := U_FtPrtPeri(::RecDataEmissaoDe, ::RecDataEmissaoAte, ::RecTipoPeriodo)
	
	// executa a consulta de todos os periodos
	For _nPeriodos := 1 to Len(_aPeriodos)
		
		_cQuery := "SELECT "
		
		If (::RecTipoPeriodo == "DIA")
			_cQuery    += "D2_EMISSAO "
			_cQryGroup := "D2_EMISSAO "
		Else
			//_cQuery    += "'"+HS_DtoC(_aPeriodos[_nPeriodos][1],2)+" a "+HS_DtoC(_aPeriodos[_nPeriodos][2],2)+"' "
			_cQuery    += "'"+_aPeriodos[_nPeriodos][3]+"' "
			_cQryGroup := ""
		EndIf
		
		// nome da coluna
		_cQuery += "DT_EMISSAO, "
		
		// descricao do produto
		_cQuery    += "B1_DESC, "
		_cQryGroup += IIf(Empty(_cQryGroup),"",",") + "B1_DESC "
		
		// total
		_cQuery += "SUM(D2_TOTAL) D2_TOTAL "
		
		// view com os dados de faturamento
		_cQuery += "  FROM V_FATURAMENTO_SERVICOS_01 "
		// filtro por filial
		_cQuery += " WHERE D2_FILIAL  = '"+::RecCodFilial+"' "
		// cliente
		_cQuery += "   AND D2_CLIENTE = '"+::RecCodCli+"' AND D2_LOJA = '"+::RecLojCli+"' "
		// periodo
		_cQuery += "   AND D2_EMISSAO BETWEEN '"+DtoS(_aPeriodos[_nPeriodos][1])+"' AND '"+DtoS(_aPeriodos[_nPeriodos][2])+"' "
		
		// agrupa por dados
		If ( ! Empty(_cQryGroup))
			_cQuery += "GROUP BY "+_cQryGroup
		EndIf
		
		// ordem dos dados
		_cQuery += "ORDER BY DT_EMISSAO, B1_DESC"
		
		// dadps no vetor
		_aDados := U_SqlToVet(_cQuery)
		
		For _nDados := 1 to Len(_aDados)
			
			aAdd(::RetFatSrvFatServicosDet,WSClassNew("StFatSrvFatServicosDet"))
			_nItem := Len(::RetFatSrvFatServicosDet)
			
			::RetFatSrvFatServicosDet[_nItem]:dDataEmissao := IIf( ::RecTipoPeriodo == "DIA", HS_DtoC(StoD(_aDados[_nDados][1]),2), _aDados[_nDados][1] )
			::RetFatSrvFatServicosDet[_nItem]:cDescServico := _aDados[_nDados][2]
			::RetFatSrvFatServicosDet[_nItem]:nValorTotal  := _aDados[_nDados][3]
			
		Next _nDados
		
	Next _nPeriodos
	
	// valida conteudo de retorno
	If (Len(::RetFatSrvFatServicosDet) == 0)
		setSoapFault("FATURAMENTO POR SERVICOS","Não há dados com esses parâmetros")
		Return(.f.)
	EndIf
	
	// retorno TRUE deu certo / FALSE deu errado
Return(.t.)

// estrutura retorno do faturamento de servicos
WSSTRUCT StFatSrvFatServicosDet
	WSDATA dDataEmissao As String
	WSDATA cDescServico As String
	WSDATA nValorTotal  As float
ENDWSSTRUCT

// criacao do metodo
WSMETHOD FatSrvListaNotasFiscais WSRECEIVE RecUsrPortal, RecIdSessionPortal, RecCodFilial, RecCodCli, RecLojCli, RecDataEmissaoDe, RecDataEmissaoAte WSSEND RetFatSrvNotasFiscais WSSERVICE WsFatServicos
	
	Local _cQuery
	// dados da nota
	local _aDados
	local _nDados
	local _nItem
	// dados dos itens da nota
	local _aItmDados
	local _nItmDados
	local _nPosItNfse
	
	// mensagem adicional
	local _cMsgAdic := ""
	// mensagem fiscal
	local _cMsgFiscal := ""
	// pedido do cliente
	local _cNrPedCli := ""

	// objeto para validar login
	local _oWsLogin := WSWSCFGLOGIN():New()

	// valores padroes
	Default ::RecDataEmissaoDe  := FirstDay(Date())
	Default ::RecDataEmissaoAte := Date()

	If ValType(::RecUsrPortal) != 'C'      ; setSoapFault("LISTA NOTAS FISCAIS","Formato do parâmetro RecUsrPortal inválido (expected C)")      ; Return .F.; EndIf
	If ValType(::RecIdSessionPortal) != 'C'; setSoapFault("LISTA NOTAS FISCAIS","Formato do parâmetro RecIdSessionPortal inválido (expected C)"); Return .F.; EndIf
	If ValType(::RecCodFilial) != 'C'      ; setSoapFault("LISTA NOTAS FISCAIS","Formato do parâmetro RecCodFilial inválido (expected C)")      ; Return .F.; EndIf
	If ValType(::RecCodCli) != 'C'         ; setSoapFault("LISTA NOTAS FISCAIS","Formato do parâmetro RecCodCli inválido (expected C)")         ; Return .F.; EndIf
	If ValType(::RecLojCli) != 'C'         ; setSoapFault("LISTA NOTAS FISCAIS","Formato do parâmetro RecLojCli inválido (expected C)")         ; Return .F.; EndIf
	If ValType(::RecDataEmissaoDe) != 'D'  ; setSoapFault("LISTA NOTAS FISCAIS","Formato do parâmetro RecDataEmissaoDe inválido (expected D)")  ; Return .F.; EndIf
	If ValType(::RecDataEmissaoAte) != 'D' ; setSoapFault("LISTA NOTAS FISCAIS","Formato do parâmetro RecDataEmissaoAte inválido (expected D)") ; Return .F.; EndIf

	::RecDataEmissaoDe  := IIf(Empty(::RecDataEmissaoDe) , FirstDay(Date()), ::RecDataEmissaoDe )
	::RecDataEmissaoAte := IIf(Empty(::RecDataEmissaoAte), Date()          , ::RecDataEmissaoAte)
	
	// valida session
	If ! _oWsLogin:CFGVALIDSESSION(::RecUsrPortal, ::RecIdSessionPortal)
		setSoapFault("LISTA NOTAS FISCAIS","Sessão inválida ou Sessão Expirou!")
		Return(.f.)
	EndIf

	// obrigatorio informar o codigo da filial
	If Empty(::RecCodFilial)
		setSoapFault("LISTA NOTAS FISCAIS","Campo filial é obrigatório.")
		Return(.f.)
	EndIf
	
	// obrigatorio informar o codigo do cliente
	If (Empty(::RecCodCli)).or.(Empty(::RecLojCli))
		setSoapFault("LISTA NOTAS FISCAIS","Campos código e loja do cliente são obrigatórios.")
		Return(.f.)
	EndIf
	
	// valida se os dados estao corretos para o login
	If ( ! U_FtPrtLgn(::RecUsrPortal, ::RecCodCli, ::RecLojCli, Nil, Nil))
		setSoapFault("FATURAMENTO POR SERVICOS","Dados não permitidos para o login informado.")
		Return(.f.)
	EndIf

	// seta ambiente, conforme filial
	If (cFilAnt != ::RecCodFilial)

		RPCClearEnv()
		RPCSetType(3)
		RPCSetEnv("01",::RecCodFilial)

	EndIf

	// monta a query para filtra as notas fiscais do cliente
	_cQuery := "SELECT SF2.R_E_C_N_O_ SF2RECNO, F2_FILIAL, F2_SERIE, F2_DOC, F2_NFELETR, F2_VALBRUT, F2_EMISSAO "
	// cab. nota fiscal saida
	_cQuery += "FROM "+RetSqlName("SF2")+" SF2 "
	_cQuery += "WHERE "
	_cQuery += "SF2.F2_FILIAL   = '"+::RecCodFilial+"' AND "
	_cQuery += "SF2.F2_CLIENTE  = '"+::RecCodCli+"' AND "
	_cQuery += "SF2.F2_LOJA     = '"+::RecLojCli+"' AND "
	_cQuery += "SF2.F2_EMISSAO >= '"+DtoS(::RecDataEmissaoDe)+"' AND SF2.F2_EMISSAO <= '"+DtoS(::RecDataEmissaoAte)+"' AND "
	_cQuery += "SF2.F2_ESPECIE  IN ('RPS','NFS') AND "
	_cQuery += "SF2.D_E_L_E_T_  = ' ' "
	// ordem dos dados
	_cQuery += "ORDER BY F2_FILIAL, F2_EMISSAO, F2_DOC "
	
	// atualiza os dados no vetor
	_aDados := U_SqlToVet(_cQuery)
	
	If (Len(_aDados) == 0)
		setSoapFault("LISTA NOTAS FISCAIS","Não há dados com esses parâmetros")
		Return(.f.)
	EndIf

	// prepara a estrutura com o retorno dos dados
	For _nDados := 1 to Len(_aDados)
		
		// reinicia variaveis
		_cMsgAdic   := ""
		_cMsgFiscal := ""
		_cNrPedCli  := ""
		
		// posiciona na nota fiscal
		dbSelectArea("SF2")
		SF2->(dbGoTo(_aDados[_nDados][1]))

		// retorna os itens da nota e mensagens complementares
		_aItmDados := sfRetItNfse(SF2->F2_SERIE, SF2->F2_DOC, SF2->F2_CLIENTE, SF2->F2_LOJA, @_cMsgAdic, @_cMsgFiscal, @_cNrPedCli)

		// adiciona o item
		aAdd(::RetFatSrvNotasFiscais,WSClassNew("StFatSrvNotasFiscais"))
		_nItem := Len(::RetFatSrvNotasFiscais)
		
		::RetFatSrvNotasFiscais[_nItem]:cNfsFilial        := SF2->F2_FILIAL
		::RetFatSrvNotasFiscais[_nItem]:cNfsSerie         := SF2->F2_SERIE
		::RetFatSrvNotasFiscais[_nItem]:cNfsNumRps        := SF2->F2_DOC
		::RetFatSrvNotasFiscais[_nItem]:cNfsNumNfse       := SF2->F2_NFELETR
		::RetFatSrvNotasFiscais[_nItem]:cNfsChvNfse       := AllTrim(If( ! Empty(SF2->F2_ZCODVER),SF2->F2_ZCODVER,SF2->F2_CODNFE) )
		::RetFatSrvNotasFiscais[_nItem]:nNfsValor         := SF2->F2_VALBRUT
		::RetFatSrvNotasFiscais[_nItem]:dNfsEmissao       := SF2->F2_EMISSAO
		// mensagens adicionais
		::RetFatSrvNotasFiscais[_nItem]:cNfsMensAdicional := _cMsgAdic
		// mensagens fiscais
		::RetFatSrvNotasFiscais[_nItem]:cNfsMensFiscal    := _cMsgFiscal
		// pedidos do cliente
		::RetFatSrvNotasFiscais[_nItem]:cNfsPedidoCliente := _cNrPedCli

		// municipio de Itajai-SC
		If (SM0->M0_CODMUN == "4208203")
			::RetFatSrvNotasFiscais[_nItem]:cNfsLinkVld := "http://nfse.itajai.sc.gov.br:8080/nfse/jsp/nfs/nfp/externo/consulta.jsp?numero="+AllTrim(SF2->F2_NFELETR)+"&serie=A1&cnpj_cpf="+SM0->M0_CGC+"&chave_validacao="+AllTrim(If( ! Empty(SF2->F2_ZCODVER),SF2->F2_ZCODVER,SF2->F2_CODNFE) )
			// Curitiba-PR
		ElseIf (SM0->M0_CODMUN == "4106902")
			::RetFatSrvNotasFiscais[_nItem]:cNfsLinkVld := "http://isscuritiba.curitiba.pr.gov.br/portalnfse/Default.aspx?doc="+SM0->M0_CGC+"&num="+AllTrim(SF2->F2_NFELETR)+"&cod="+AllTrim(SF2->F2_CODNFE)
		EndIf
		
		// itens da nota
		::RetFatSrvNotasFiscais[_nItem]:xNfsItens := {}
		
		// ex: estrutura _aItmDados
		// 1-Cod.Produto
		// 2-Dsc.Produto
		// 3-Quantidade
		// 4-Vlr.Unitario
		// 5-Vlr.Total
		
		// varre todos os itens da nota e prepara o retorno
		For _nItmDados := 1 to Len(_aItmDados)
			
			// adiciona linha do item da nota
			aAdd(::RetFatSrvNotasFiscais[_nItem]:xNfsItens,WSClassNew("StFatSrvItensNotasFiscais"))
			_nPosItNfse := Len(::RetFatSrvNotasFiscais[_nItem]:xNfsItens)
			
			::RetFatSrvNotasFiscais[_nItem]:xNfsItens[_nPosItNfse]:cItNfsCodProd  := _aItmDados[_nItmDados][1]
			::RetFatSrvNotasFiscais[_nItem]:xNfsItens[_nPosItNfse]:cItNfsDescric  := _aItmDados[_nItmDados][2]
			::RetFatSrvNotasFiscais[_nItem]:xNfsItens[_nPosItNfse]:nItNfsQuantid  := _aItmDados[_nItmDados][3]
			::RetFatSrvNotasFiscais[_nItem]:xNfsItens[_nPosItNfse]:nItNfsVlrUnit  := _aItmDados[_nItmDados][4]
			::RetFatSrvNotasFiscais[_nItem]:xNfsItens[_nPosItNfse]:nItNfsVlrTotal := _aItmDados[_nItmDados][5]
			
		Next _nItmDados
		
		
	Next _nDados

	// retorno TRUE deu certo / FALSE deu errado
Return(.t.)

// estrutura retorno das notas fiscais
WSSTRUCT StFatSrvNotasFiscais
	WSDATA cNfsFilial        As String
	WSDATA cNfsSerie         As String
	WSDATA cNfsNumRps        As String
	WSDATA cNfsNumNfse       As String
	WSDATA cNfsChvNfse       As String
	WSDATA nNfsValor         As float
	WSDATA dNfsEmissao       As Date
	WSDATA cNfsLinkVld       As String
	WSDATA cNfsMensAdicional As String
	WSDATA cNfsMensFiscal    As String
	WSDATA cNfsPedidoCliente As String
	WSDATA xNfsItens         As Array Of StFatSrvItensNotasFiscais
ENDWSSTRUCT

// estrutura retorno dos itens das notas fiscais
WSSTRUCT StFatSrvItensNotasFiscais
	WSDATA cItNfsCodProd       As String
	WSDATA cItNfsDescric       As String
	WSDATA nItNfsQuantid       As float
	WSDATA nItNfsVlrUnit       As float
	WSDATA nItNfsVlrTotal      As float
ENDWSSTRUCT

// ** funcao que retorna os itens da nota fiscal
Static Function sfRetItNfse(mvSerie, mvDoc, mvCodCli, mvLojCli, mvMsgAdic, mvMsgFiscal, mvNrPedCli)
	// ex: estrutura
	// 1-Cod.Produto
	// 2-Dsc.Produto
	// 3-Quantidade
	// 4-Vlr.Unitario
	// 5-Vlr.Total
	local _aDscServico := {}
	local _nPosServico := 0
	local _nTmpQuant   := 0
	local _lSomaQuant  := .f.
	local _lSomaPrUni  := .f.
	// query
	local _cQrySD2
	local _cQrySC5
	// dados
	local _aItensNfse := {}
	local _nItensNfse
	
	// variaveis temporarias
	local _cItCodProd  := ""
	local _cItDscProd  := ""
	local _nItQuant    := 0
	local _nItPrcUnit  := 0
	local _nItVlrTotal := 0
	local _nItVlrDesc  := 0
	
	// numeros dos pedidos de vendas envolvidos
	local _aNrPedVenda := {}
	local _nNrPedVenda
	
	// quantidade de mensagens
	local _nQtdMsgAdi := 0
	local _nQtdMsgFis := 0
	
	// pedidos do cliente
	local _aRefPedCli := {}
	
	// monta a query para busca os itens da nota fiscal
	_cQrySD2 := "SELECT "
	_cQrySD2 += " D2_SERIE, D2_DOC, D2_CLIENTE, D2_LOJA, D2_COD, C6_DESCRI, "
	_cQrySD2 += " CASE WHEN D2_COD = '9000005' THEN 1 ELSE D2_QUANT END D2_QUANT, "
	_cQrySD2 += " SUM(D2_PRUNIT) D2_PRUNIT, "
	_cQrySD2 += " SUM(D2_TOTAL) D2_TOTAL, "
	_cQrySD2 += " SUM(D2_DESCON) D2_DESCON "
	
	// itens da nota fiscal
	_cQrySD2 += "FROM "+RetSqlName("SD2")+" SD2 "
	
	// itens do pedido de venda
	_cQrySD2 += "INNER JOIN "+RetSqlName("SC6")+" SC6 ON "+RetSqlCond("SC6")
	_cQrySD2 += "  AND C6_NUM     = D2_PEDIDO "
	_cQrySD2 += "  AND C6_ITEM    = D2_ITEMPV "
	_cQrySD2 += "  AND C6_PRODUTO = D2_COD "
	
	// filtro padrao
	_cQrySD2 += "WHERE "+RetSqlCond("SD2")
	// serie
	_cQrySD2 += "  AND D2_SERIE   = '"+mvSerie+"' "
	// nota
	_cQrySD2 += "  AND D2_DOC     = '"+mvDoc+"' "
	// cliente e loja
	_cQrySD2 += "  AND D2_CLIENTE = '"+mvCodCli+"' "
	_cQrySD2 += "  AND D2_LOJA    = '"+mvLojCli+"' "
	
	// agrupa dados
	_cQrySD2 += "GROUP BY D2_SERIE,D2_DOC,D2_CLIENTE,D2_LOJA,D2_COD,C6_DESCRI,CASE WHEN D2_COD = '9000005' THEN 1 ELSE D2_QUANT END "
	
	// ordem dos dados
	_cQrySD2 += "ORDER BY D2_DOC,D2_SERIE,D2_CLIENTE,D2_LOJA "
	
	// atualiza os dados no vetor
	_aItensNfse := U_SqlToVet(_cQrySD2)
	
	// varre todos os itens e organiza o vetor de retorno
	For _nItensNfse := 1 to Len(_aItensNfse)
		
		// ex: estrutura _aDscServico
		// 1-Cod.Produto
		// 2-Dsc.Produto
		// 3-Quantidade
		// 4-Vlr.Unitario
		// 5-Vlr.Total
		
		// reinicia variaveis
		_lSomaQuant := .f.
		_lSomaPrUni := .f.
		
		// variaveis temporarias
		_cItCodProd  := _aItensNfse[_nItensNfse][ 5]
		_cItDscProd  := _aItensNfse[_nItensNfse][ 6]
		_nItQuant    := _aItensNfse[_nItensNfse][ 7]
		_nItPrcUnit  := _aItensNfse[_nItensNfse][ 8]
		_nItVlrTotal := _aItensNfse[_nItensNfse][ 9]
		_nItVlrDesc  := _aItensNfse[_nItensNfse][10]
		
		// armazena a quantidade
		If (AllTrim(_cItCodProd)=="9000005")
			_nTmpQuant  := 1
			_lSomaQuant := .f.
			_lSomaPrUni := .t.
		Else
			_nTmpQuant  := _nItQuant
			_lSomaQuant := (_nTmpQuant > 1)
			_lSomaPrUni := .t.
		EndIf
		
		// para pacotes logisticos, separa cobranca por preco unitario
		If (AllTrim(_cItCodProd) $ "9000006/9000010/9000011")
			_nPosServico := aScan(_aDscServico,{|x| (x[1] == _cItCodProd).and.(x[2] == _cItDscProd).and.(x[4] == _nItPrcUnit) })
			_lSomaQuant  := .t.
			_lSomaPrUni  := .f.
		Else
			_nPosServico := aScan(_aDscServico,{|x| (x[1] == _cItCodProd).and.(x[2] == _cItDscProd) })
		EndIf
		
		// inclui novo servico
		If (_nPosServico == 0)
			
			// atualiza os dados
			aAdd(_aDscServico,{ _cItCodProd ,;
				_cItDscProd                     ,;
				_nTmpQuant                      ,;
				_nItPrcUnit                     ,;
				(_nItVlrTotal + _nItVlrDesc)    })
			
			// atualiza dados do servico
		ElseIf (_nPosServico > 0)
			
			// quantidade (só incrementa quanto a quantidade for maior que 1)
			_aDscServico[_nPosServico][3] += IIf(_lSomaQuant,_nTmpQuant,0)
			// valor unitario
			_aDscServico[_nPosServico][4] += IIf(_lSomaPrUni,_nItPrcUnit,0)
			// valor total
			_aDscServico[_nPosServico][5] += (_nItVlrTotal + _nItVlrDesc)
			
		EndIf
		
	Next _nItensNfse
	
	// verifica se deve incluir mensagens do pedido de venda
	_cQrySC5 := "SELECT DISTINCT TOP 2 C5_MENNOTA, C5_MENPAD, C5_ZPEDCLI "
	// cab. pedido de venda
	_cQrySC5 += "FROM "+RetSqlName("SC5")+" SC5 "
	// filtro padrao
	_cQrySC5 += "WHERE "+RetSqlCond("SC5")
	// cod e loja do cliente
	_cQrySC5 += "  AND C5_CLIENTE = '"+mvCodCli+"' AND C5_LOJACLI = '"+mvLojCli+"' "
	// numero da nota e serie
	_cQrySC5 += "  AND C5_NOTA = '"+mvDoc+"' AND C5_SERIE = '"+mvSerie+"' "
	
	// atualiza vetor
	_aNrPedVenda := U_SqlToVet(_cQrySC5)
	
	// atualiza os dados de retorno
	For _nNrPedVenda := 1 to Len(_aNrPedVenda)
		// mensagem adicional da nota
		If (_nQtdMsgAdi <= 1).and.( ! AllTrim(_aNrPedVenda[_nNrPedVenda][1]) $ mvMsgAdic)
			// atualiza mensagem
			mvMsgAdic += AllTrim(_aNrPedVenda[_nNrPedVenda][1])
			// atualiza contador
			_nQtdMsgAdi ++
			// aceita somente uma mensagem de processo
			If (_nQtdMsgAdi > 1)
				mvMsgAdic := ""
			EndIf
		EndIf
		
		// mensagem fiscal da nota
		If (_nQtdMsgFis <= 1).and.( ! Empty(_aNrPedVenda[_nNrPedVenda][2]) .And. !AllTrim(FORMULA(_aNrPedVenda[_nNrPedVenda][2])) $ mvMsgFiscal)
			// atualiza mensagem
			mvMsgFiscal += AllTrim(FORMULA(_aNrPedVenda[_nNrPedVenda][2]))
			// atualiza contador
			_nQtdMsgFis ++
			// aceita somente uma mensagem de processo
			If (_nQtdMsgFis > 1)
				mvMsgFiscal := ""
			EndIf
		EndIf
		
		
		// armazena numeros dos pedidos do cliente
		If (SC5->(FieldPos("C5_ZPEDCLI")) > 0).And.(!Empty(_aNrPedVenda[_nNrPedVenda][3]))
			// verifica se o pedido ja esta na relacao
			If ( aScan(_aRefPedCli,{|xVetor| (xVetor == _aNrPedVenda[_nNrPedVenda][3]) }) == 0)
				// adiciona pedido
				aAdd(_aRefPedCli,_aNrPedVenda[_nNrPedVenda][3])
			EndIf
		EndIf
		
	Next _nNrPedVenda
	
	// mensagem do pedido do cliente
	If (Len(_aRefPedCli) > 0)
		// atualiza variavel com todos os pedidos, separando por virgula
		aEval(_aRefPedCli,{|mvVetor| (mvNrPedCli += If(Empty(mvNrPedCli),"",", ")+AllTrim(mvVetor)) })
	EndIf
	
Return(_aDscServico)