#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada para adicionar condições no filtro     !
!                  ! a ser aplicado na DAK para exibição no browse.          !
+------------------+---------------------------------------------------------+
!Retorno           ! Condicao Filtro ADVPL                                   !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe                      ! Data de Criacao ! 04/2015 !
+------------------+--------------------------------------------------------*/

User Function M461FILDAK()

	// parametros recebidos
	Local _cRetPE := PARAMIXB[1]

	// query
	Local _cQuery := ""

	// variaveis temporarias
	local _aTmpCargas := {}
	local _nX := 0
	// cargas que devem ser ADICIONADAS do resultado
	local _aCargasOk := {}

	// controle de filtros atendem condicoes
	local _lFiltroOk := .F.

	// grupo de perguntas
	local _cPerg := "M461FILDAK"
	local _aPerg := {}

	// salvar parametros atuais do grupo de perguntas
	local _aAtuParam := U_FtSavSx1(30)

	// carga De-Ate
	local _cCargaDe  := mv_par03
	local _cCargaAte := mv_par04

	// data carga De-Ate
	local _dDtCargDe := mv_par10
	local _dDtCargAt := mv_par11

	// condicao de filtro para não apresentar dados
	local _cFilNaoOk := " .And. (1 = 0) "

	// verifica se o WMS esta ativo
	local _lWmsAtivo := .F.

	// permite o carregamento sem a nota fiscal de venda do cliente
	local _lLibSemNF := .F.

	// monta grupo de perguntas
	aAdd(_aPerg,{"Cliente ?","C",TamSx3("A1_COD")[1] ,0,"G",,"SA1",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par01
	aAdd(_aPerg,{"Loja ?"   ,"C",TamSx3("A1_LOJA")[1],0,"G",,""   ,{{"X1_VALID","U_FtStrZero()"}}}) //mv_par02

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg, _aPerg)

	// abre os parametros
	If ( ! Pergunte(_cPerg, .T.) )
		// se pergunta foi cancelada, nao mostra nada
		_cRetPE += _cFilNaoOk
		// restaura grupo de perguntas
		U_FtResSx1(_aAtuParam)
		// retorno
		Return(_cRetPE)
	EndIf

	// verifica se o WMS esta ativo
	_lWmsAtivo := U_FtWmsParam("WMS_ATIVO_POR_CLIENTE", "L", .F., .F., Nil, mv_par01, mv_par02, Nil, Nil)

	// permite o carregamento sem a nota fiscal de venda do cliente
	_lLibSemNF := U_FtWmsParam("WMS_LIBERA_CARREGAMENTO_SEM_NF_VENDA", "L", .F., .F., Nil, mv_par01, mv_par02, Nil, Nil)

	// perpara query
	_cQuery := " SELECT DAK_COD, "
	_cQuery += "        DAK_SEQCAR, "
	_cQuery += "        Sum(( CASE "
	_cQuery += "                WHEN SC9.C9_BLEST != '  ' THEN 1 "
	_cQuery += "                ELSE 0 "
	_cQuery += "              END )) QTD_BLOQ, "
	_cQuery += "        Sum(( CASE "
	_cQuery += "                WHEN SC5.C5_ZDOCCLI = '  ' THEN 1 "
	_cQuery += "                ELSE 0 "
	_cQuery += "              END )) QTD_SEM_NF "
	_cQuery += " FROM   " + RetSqlTab("DAK")
	_cQuery += "        INNER JOIN " + RetSqlTab("SC9")
	_cQuery += "                ON " + RetSqlCond("SC9")
	_cQuery += "                   AND SC9.C9_CARGA = DAK_COD "
	_cQuery += "                   AND SC9.C9_SEQCAR = DAK_SEQCAR "
	_cQuery += "                   AND SC9.C9_CLIENTE = '" + mv_par01 + "' "
	_cQuery += "                   AND SC9.C9_LOJA = '" + mv_par02 + "' "
	_cQuery += "        INNER JOIN " + RetSqlTab("SC5")
	_cQuery += "                ON " + RetSqlCond("SC5")
	_cQuery += "                   AND SC5.C5_NUM = SC9.C9_PEDIDO "
	_cQuery += "                   AND SC5.C5_CLIENT = SC9.C9_CLIENTE "
	_cQuery += "                   AND SC5.C5_LOJACLI = SC9.C9_LOJA "
	_cQuery += "                   AND SC5.C5_TIPOOPE = 'P' "
	_cQuery += " WHERE  " + RetSqlCond("DAK")
	_cQuery += "        AND DAK.DAK_COD BETWEEN '" + _cCargaDe + "' AND '" + _cCargaAte + "' "
	_cQuery += "        AND DAK_FEZNF != '1' "
	_cQuery += "        AND DAK_BLWMS IN ( '05', '06', '07', '  ' ) "
	_cQuery += "        AND DAK_DATA BETWEEN '" + DtoS(_dDtCargDe) + "' AND '" + DtoS(_dDtCargAt) + "' "
	_cQuery += " GROUP  BY DAK_COD, "
	_cQuery += "           DAK_SEQCAR "
	_cQuery += " ORDER  BY DAK_COD  "

	MemoWrit("C:\QUERY\M461FILDAK_filtro1.txt",_cQuery)

	// carrega resultado do SQL na variavel.
	_aTmpCargas := U_SqlToVet(_cQuery)

	// se nao tem cargas, inclui filtro para nao apresentar nada
	If (Len(_aTmpCargas) == 0)
		// condicao de filtro para nao mostrar nada
		_cRetPE += _cFilNaoOk

		// varre as cargas obtidas e inclui aquelas que o cliente está configurado para não permitir faturar/retornar no filtro do P.E.
	ElseIf (Len(_aTmpCargas) != 0)
		// varre todas as cargas
		For _nX := 1 to Len(_aTmpCargas)
			// se cliente possui WMS ativo e nao tem pedido bloqueado
			// desativado temporariamente o controle de WMS Ativo, pois Portobello tem Ativacao de WMS por contrato
			If (_aTmpCargas[_nX][3] == 0)
				// verifica se pode faturar sem nota fiscal de venda do cliente
				If ( _lLibSemNF ) .Or. (( ! _lLibSemNF ) .And. (_aTmpCargas[_nX][4] == 0))
					// verifica se a carga ja esta na relacao
					If ( Ascan(_aCargasOk, _aTmpCargas[_nX][1]) == 0 )
						// adiciona carga na relacao
						aAdd(_aCargasOk, _aTmpCargas[_nX][1])
						// atualiza controle do filtr
						_lFiltroOk := .T.
					EndIf
				EndIf
			EndIf
		Next _nX
	EndIf

	// restaura grupo de perguntas
	U_FtResSx1(_aAtuParam)

	// se tem cargas para atender o filtro
	If (_lFiltroOk)
		// abre condição
		_cRetPE += " .AND. (DAK_COD $'"
		// adiciona as cargas a serem ADICIONADAS na seleção
		for _nX := 1 to Len(_aCargasOk)
			_cRetPE += _aCargasOk[_nX] + "|"
		next
		// fecha condição
		_cRetPE += "')"

		// se nao tem cargas, define filtro para nao mostrar nada
	ElseIf ( ! _lFiltroOk )
		// condicao de filtro para nao mostrar nada
		_cRetPE += _cFilNaoOk

	EndIf

	//log do filtro advpl montado
	memowrit("c:\query\M461FILDAK.txt", _cRetPE)

Return(_cRetPE)
