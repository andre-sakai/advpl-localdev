
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado no botao RETORNAR do Pedido !
!                  ! Venda                                                   !
!                  ! 1. Utilizado para filtrar somente notas fiscais de bene-!
!                  !    ficiamento com saldo                                 !
+------------------+---------------------------------------------------------+
!Retorno           ! Query/ADVPL com filtro                                  !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 09/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function A410RNF
	// parametros recebidos
	local _dDataDe	:= ParamIxb[1] // Data inicial digitada na tela de pesquisa para exibição das notas a retornar.
	local _dDataAte	:= ParamIxb[2] // Data final digitada na tela de pesquisa para exibição das notas a retornar.
	local _lFornece	:= ParamIxb[3] // Opção selecionada .T. Fornecedor ou .F. Cliente.
	local _lPorClie := ParamIxb[4] // Opção selecionada .T. Cliente ou .F. Documento
	// filtro de retorno
	local _cRetFiltro := ""
	// variaveis temporarias
	local _cQuery
	local _cCmpQry := ""
	// devolucao de mercadoria de cliente sem controle de saldo de poder de terceiros
	local _lPoderTerc := ( SuperGetMV('TC_DEVPVP3',.F.,"S") == "S" )
	local nX
	
	// define os campos
	If (_lPorClie)
		// busca campos do cabecalho da nota
		aX3SF1 := FWSX3Util():GetAllFields( "SF1" )
		For nX := 1 to Len(aX3SF1)
			// retorna campos da SX3
			cX3Browse := GetSX3Cache(aX3SF1[nX],"X3_BROWSE")
			cX3Contex := GetSX3Cache(aX3SF1[nX],"X3_CONTEXT")
			cX3Campo  := GetSX3Cache(aX3SF1[nX],"X3_CAMPO")
			// valida utilização do campo
			If cX3Browse == 'S' .and. cX3Contex <> 'V'
				// adiciona campo
				_cCmpQry += IIf(Empty(_cCmpQry),"",", ") + cX3Campo
			EndIf
			
		Next nX

	EndIf

	// monta a query
	_cQuery := " SELECT DISTINCT " + IIf(_lPorClie, _cCmpQry, "F1_DOC+F1_SERIE")+" "
	// notas fiscais
	_cQuery += " FROM "+RetSqlTab("SF1")
  	// se NAO for fornecedor, busca o saldo em Poder de Terceiros
  	If (!_lFornece)
	  	_cQuery += IIf(_lPoderTerc," INNER"," LEFT")+" JOIN "+RetSqlTab("SB6")+" ON "+RetSqlCond("SB6")
		_cQuery += " AND B6_DOC = F1_DOC AND B6_SERIE = F1_SERIE AND B6_CLIFOR = F1_FORNECE AND B6_LOJA = F1_LOJA "
		_cQuery += " AND B6_TPCF = 'C' AND B6_PODER3 = 'R' "
		// somente notas com saldo
		_cQuery += " AND (B6_SALDO - B6_QULIB - ISNULL((SELECT SUM(C0_QUANT) FROM " +RetSqlTab("SC0")+ " WHERE SB6.B6_IDENT = C0_ZIDENT AND SB6.B6_DOC = C0_ZNOTA AND SB6.B6_SERIE = C0_ZSERIE AND "+RetSqlCond("SC0")+"),0)) > 0 "
	EndIf
	// filtra cabecalho da nota
  	_cQuery += " WHERE "+RetSqlCond("SF1")
  	_cQuery += " AND F1_FORNECE = '"+cFornece+"' AND F1_LOJA = '"+cLoja+"' "
  	_cQuery += " AND F1_DTDIGIT BETWEEN '"+DtoS(_dDataDe)+"' AND '"+DtoS(_dDataAte)+"' "
	// status da nota
  	_cQuery += " AND F1_STATUS <> '"+Space(Len(SF1->F1_STATUS))+"' "
  	// tipo da nota
  	_cQuery += " AND F1_TIPO "+If(_lFornece,"NOT","")+" IN ('D','B') "
  	
  	_cQuery += " ORDER BY 1 "

	// quando for por DOCUMENTO usa filtro ADVPL
	If ( ! _lPorClie )

		// monta o filtro ADVPL
		_cRetFiltro := " SF1->F1_FILIAL == '" + xFilial("SF1") + "' "
	  	_cRetFiltro += " .And. SF1->F1_FORNECE == '" + cFornece + "' "
	  	_cRetFiltro += " .And. SF1->F1_LOJA    == '" + cLoja    + "' "
	  	_cRetFiltro += " .And. DtoS(SF1->F1_EMISSAO) >= '" + DtoS(_dDataDe)  + "'"
		_cRetFiltro += " .And. DtoS(SF1->F1_EMISSAO) <= '" + DtoS(_dDataAte) + "' "
	  	_cRetFiltro += " .And. "+If(_lFornece,"!","")+ "(SF1->F1_TIPO $ 'DB') "
		_cRetFiltro += " .And. SF1->(F1_DOC+F1_SERIE) $ '"+sfFormatIn(_cQuery)+"' "

	// por CLIENTE retorna a query
	ElseIf (_lPorClie)
		_cRetFiltro := _cQuery
	EndIf

Return(_cRetFiltro)

//** funcao que formata a query
Static Function sfFormatIn(mvQuery)
	local _aTmpNotas := U_SqlToVet(mvQuery)
	local _cRet := ""
	// atualiza a variavel de retorno
	aEval(_aTmpNotas,{|_aTmpNotas| _cRet += _aTmpNotas + "|" })
Return(_cRet)