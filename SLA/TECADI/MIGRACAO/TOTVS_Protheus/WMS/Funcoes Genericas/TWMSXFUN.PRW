#Include "Totvs.ch"
#Include "TopConn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Funcoes Genericas utilizadas no modulo WMS              !
!                  ! 1. Retorna o filtro por usuario (Produto/Servico)       !
!                  !    Retorno: 1-Fitrar dados? - Logico                    !
!                  !             2-Tipo Operacao - Caracter (P-Prod/S-Serv/  !
!                  !             T-Transf. Mercad/C-Consumo                  !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 09/2011                                                 !
+------------------+--------------------------------------------------------*/

// ** 1. Retorna o filtro por usuario (Produto/Servico/Consumo/Transf Mercadoria)
User Function FtWmsFil
	// se deve filtrar os pedidos por usuario
	local _lFiltrar := (__cUserId != "000000")
	// grupos do usuario
	local _aGrupos := {}
	// variavel temporaria
	local _nX
	// tipo da operacao
	local _cTipoOper := CriaVar("C5_TIPOOPE",.F.)
	// permite alterar as opcoes do tipo de operacao
	local _lAltOpc := (__cUserId == "000000")

	// verifica as condicoes para o filtro, quando nao for administrador
	If (_lFiltrar)
		// retorna os grupos do usuario logado
		_aGrupos := FWSFUsrGrps(__cUserId)
		// varre todos os grupos e retornar descrição do grupo
		For _nX := 1 to Len(_aGrupos)
			// filtro de servicos (000003-FINANCEIRO / 000012 - WMS FATURAMENTO)
			If (Upper(_aGrupos[_nX]) $ "000003/000012")
				_cTipoOper := "S"
				Exit
				
			ElseIf ("WMS" $ Upper(GrpRetName(_aGrupos[_nX]))) // filtro de produtos ("todos" os grupos com WMS no nome)
				// somente produtos
				_cTipoOper := "P"

				// usuarios com permissao de realizar transferencias
				If ( __cUserId $ AllTrim(SuperGetMV("TC_USRTRAN", .F., "")) )
					// incrementa T-Transferencia
					_cTipoOper += "/T"
					// permite alteracao da opcao
					_lAltOpc   := .T.
				EndIf

				// sai do Loop
				Exit

				// filtro de produtos (000006-WMS - FISCAL / 000009 - contabilidade interna )
			ElseIf (Upper(_aGrupos[_nX]) $ "000006/000009")
				_cTipoOper := "P/T/C"
				_lAltOpc   := .T.
				Exit

				// filtro de servicos (000004 - COMERCIAL)
			ElseIf (Upper(_aGrupos[_nX]) $ "000004")
				_cTipoOper := "S"
				Exit

				// sem filtro (grupo de administradores)
			ElseIf (Upper(_aGrupos[_nX]) $ "000000")
				_lFiltrar := .F.
				_lAltOpc   := .T.
				Exit
			EndIf
		Next _nX
	EndIf

Return({_lFiltrar, _cTipoOper, _lAltOpc})

// ** 2. funcao para validar se o usuario logado esta cadastrado como operador
User Function FtWmsOpe()
	// abre cadastro de recursos humanos
	dbSelectArea("DCD")
	DCD->(dbSetOrder(1)) //DCD_FILIAL+DCD_CODFUN
	If (!DCD->(dbSeek( xFilial("DCD")+__cUserId )))
		U_FtWmsMsg("Usuário não cadastrado como Recurso do WMS.","ATENCAO")
		Return({.F.,""})
	EndIf
Return({.T.,DCD->DCD_ZCATEG})

// ** 3. funcao que valida o usuario para execucao de um servico no WMS
User Function FtUsrWms()
	// variavel de retorno
	Local _lRetVldUsr := .F.
	// fontes
	Local oFntTit := TFont():New("Tahoma",,20,,.T.)
	// equipamento atual
	local _cEquipAtual := _cCodEquip
	local _cTpEquipAtu := _cTipEquip
	local _cDscEquip   := IIf(Empty(_cCodEquip), "NENHUM", AllTrim(Posicione("SZQ",1,xFilial("SZQ")+_cEquipAtual,"ZQ_DESCRIC")))
	local _cTmpFoco := " "

	// objetos da tela
	local _oWnd01VldUsr
	local _oPnl01Cab
	local _oBmp01Ok, _oBmp01Sair
	local _oGet01Foco
	local _oSay01CodUsr, _oSay01NomUsr

	// limpa código do equipamento e habilita tela para informar o operador
	_cCodEquip := Space(6)
	_cTipEquip := Space(3)

	// abertura de tabelas
	dbSelectArea("Z17")
	dbSelectArea("Z18")

	// valida o usuario
	_lRetVldUsr := sfVldUser(.F.)

	// se o usuario estiver apto a executar os servicos
	If (_lRetVldUsr)

		// verifica se tem algum alias aberto (se nao tiver gera erro na funcao Tabela)
		If (Empty(Alias()))
			dbSelectArea("SX5")
		EndIF

		// monta o dialogo de validacao do usuario
		_oWnd01VldUsr := MSDialog():New(020,018,160,220,"Validação do Usuário",,,.F.,,,,,,.T.,,,.T. )

		// -- painel com as opcoes disponiveis
		_oPnl01Cab := TPanel():New(000,000,nil,_oWnd01VldUsr,,.F.,.F.,,,20,20,.T.,.F. )
		_oPnl01Cab:Align:= CONTROL_ALIGN_TOP

		// -- confirmarcao
		_oBmp01Ok := TBtnBmp2():New(000,000,030,020,"OK",,,,{|| IIf(_lRetVldUsr := sfVldEquip(), _oWnd01VldUsr:End(), Nil) },_oPnl01Cab,"Ok",,.T.)
		_oBmp01Ok:Align := CONTROL_ALIGN_LEFT
		// -- botao Sair
		_oBmp01Sair := TBtnBmp2():New(000,000,030,020,"FINAL",,,,{|| _lRetVldUsr := .F. , _oWnd01VldUsr:End() },_oPnl01Cab,"Sair",,.T.)
		_oBmp01Sair:Align := CONTROL_ALIGN_RIGHT

		// informacoes do usuario
		_oSay01CodUsr := TSay():New(020,005,{||"Cod. Usuário"},_oWnd01VldUsr,,,.F.,.F.,.F.,.T.)
		oGetCodUsr := TGet():New(026,005,{|u| If(PCount()>0,_cCodOper:=u,_cCodOper)},_oWnd01VldUsr,030,008,'',{|| _lRetVldUsr := sfVldUser(.T.) },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cCodOper",,)
		oGetCodUsr:bWhen := {|| .F. }
		_oSay01NomUsr := TSay():New(028,040,{|| AllTrim(Upper(Posicione("DCD", 1, xFilial("DCD")+_cCodOper, "DCD_NOMFUN"))) },_oWnd01VldUsr,,,.F.,.F.,.F.,.T.)

		// codigo do equipamento
		oSayCodEquip := TSay():New(036,005,{||"Equipamento"},_oWnd01VldUsr,,,.F.,.F.,.F.,.T.)
		oGetCodEquip := TGet():New(042,005,{|u| If(PCount()>0,_cCodEquip:=u,_cCodEquip)},_oWnd01VldUsr,030,008,'@R 999999',{|| .T. },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cCodEquip",,)

		// equip. atual
		_oSayTitEqui := TSay():New(052,005,{||"Equipamento Atual"},_oWnd01VldUsr,,,.F.,.F.,.F.,.T.)
		_oSayEquiAtu := TSay():New(058,005,{|| _cEquipAtual+"-"+_cDscEquip },_oWnd01VldUsr,,,.F.,.F.,.F.,.T.)

		// cria um objeto fora da janela para receber o foco
		_oGet01Foco := TGet():New(1000,1000,{|u| If(PCount()>0,_cTmpFoco:=u,_cTmpFoco)},_oWnd01VldUsr,001,001,'@R 999999',{|| _oBmp01Ok:Click() },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cTmpFoco",,)

		// foco no objeto equipamento
		oGetCodEquip:SetFocus()

		// ativa a tela
		ACTIVATE MSDIALOG _oWnd01VldUsr// CENTERED

	EndIf

	// se a tela foi cancelada, volta a configuracao inicial
	If ( ! _lRetVldUsr )
		_cCodEquip := _cEquipAtual
		_cTipEquip := _cTpEquipAtu
		// chama funcao para atualizar a query
		sfVldEquip()
	EndIf

Return(_lRetVldUsr)

// ** funcao que valida o codigo do usuario
Static Function sfVldUser(mvVldFiltro)
	Local _cQuery := ""

	// verifica se o operador esta cadastrado e não é monitor
	dbSelectArea("DCD")
	DCD->(dbSetOrder(1)) //1-DCD_FILIAL, DCD_CODFUN
	If ( ! DCD->(dbSeek( xFilial("DCD") + _cCodOper )))
		Aviso("Permissão...","Operador não cadastrado!",{"Ok"})
		Return(.F.)
	EndIf

	// verifica a categoria do operador
	If (DCD->DCD_ZCATEG $ "M|C")
		Aviso("Permissão...","Operador Inválido!",{"Ok"})
		Return(.F.)
	EndIf

	// atualiza o nome do operador
	_cNomOper := AllTrim(Upper(DCD->DCD_NOMFUN))

	// valida a estrutura de permissoes do usuarios
	_cQuery := " SELECT COUNT(*) QTD_ITENS "
	// itens do servico
	_cQuery += " FROM " + RetSqlTab("Z06") + " (nolock) "
	// prepara condicao
	_cQuery += " WHERE "

	// monta filtro padrao
	cQryFilZ06 := RetSqlCond("Z06")+" "
	// insere filtros especificos do operador, que nao seja um Monitor
	cQryFilZ06 += U_FtWmsFlt(DCD->DCD_ZCATEG, _cCodOper)

	// cria condicao para filtrar OS que o operador esta relacionado como recusros
	cQryUsrZ18 := " EXISTS ("
	cQryUsrZ18 += "        SELECT Z18_OPERAD FROM "+RetSqlName("Z18")+" Z18 (nolock)  "
	cQryUsrZ18 += "        WHERE "+RetSqlCond("Z18")+" "
	cQryUsrZ18 += "        AND Z18_NUMOS = Z06_NUMOS AND Z18_SEQOS = Z06_SEQOS "
	cQryUsrZ18 += "        AND Z18_OPERAD = '"+_cCodOper+"' "
	cQryUsrZ18 += "        AND Z18_STATUS = 'R' "
	cQryUsrZ18 += "        ) "

	// insere o filtro padrao
	_cQuery += cQryFilZ06

	MemoWrit("c:\query\tmwsxfun_FtUsrWms.txt",_cQuery)

Return(.T.)

// ** 4. funcao responsavel pelo enderecamento
User Function FtEndereca(mvEndDest, mvEstruFis, mvLocal, mvProduto, mvQuant, mvFiltros, mvCesv, mvNumSeq, mvSeqKit, mvTpGera, mvCodCli, mvLote, mvTpEstoq, mvCompFrac, mvQtTotPrd, mvQtTotPlt)
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z05","Z06","Z07","Z08"})
	// variavel de retorno
	local _lRet := .T.
	// quantidade a enderecar
	local _nSaldo := mvQuant
	// saldo por enedereco
	local _nSaldoSBF := 0
	local _cQryEnder := ""
	// capacidade do endereco
	local _aCapacEnd := {}
	// total de uso do produto para armazenagem
	local _aDetArmPrd := {}

	// quantidade a enderecar
	local _nQtdEnder := 0

	// alias query enderecos
	Local _cAlQryEnd := ""

	// status do conteudo do palete
	local _cStsPalete := ""

	// Retorno Quantidade de Paletes
	Local _aRetPal := {}
	// Total de Paletes
	Local _nTotPlt := 0
	// quant palete cheio
	local _nQtdPltChe := 0
	// quant palete fracionado
	local _nQtdPltFra := 0
	// quantidade maxima de itens no palete
	local _nQtdMaxPalete := 0
	// Verifica tipo de conferencia do produto conforme tabela Z04 se é por Palete ou Quantidade.(P = Palete | Q = Quantidade)
	Local _cTipConf  :=""

	Local _aRetConf := {}
	Local _i := 0

	// valores padroes
	Default mvFiltros  := {}
	Default mvCodCli   := "" // cliente default para comparação
	Default mvLote     := CriaVar("B8_LOTECTL", .F.)
	Default mvTpEstoq  := CriaVar("Z16_TPESTO", .F.)
	Default mvCompFrac := .F.
	Default mvQtTotPrd := 0
	Default mvQtTotPlt := 0

	// tipo de estrutura fisica de destino
	If ("000002" $ mvEstruFis) .Or. ("000010" $ mvEstruFis) // 000002-PORTA PALETE / 000010-PICKING

		// prepara alias da query
		_cAlQryEnd := GetNextAlias()

		// pesquisa o lastro e camada do produto
		// estrutura do retorno
		// 1-Quantidade Total de Palete
		// 2-Quantidade de Paletes Cheios
		// 3-Quantidade de Paletes Fracionados
		// 4-Quantidade Maxima de SKU/Volumes por Palete
		// 5-Tipo do Calculo (Q-Quant Unitarios / P-Quant Palete Informado)
		_aRetPal := U_FtWmsNorma(mvProduto, mvLocal, Nil, Nil, Nil, mvCesv, mvNumSeq, mvSeqKit, mvQtTotPrd, IIf(mvCompFrac, 0, mvQtTotPlt) )

		// atualiza variavel de controle de acordo com o calculo da funcao FtWmsNorma
		_nTotPlt       := _aRetPal[1]
		_nQtdPltChe    := _aRetPal[2]
		_nQtdPltFra    := _aRetPal[3]
		_nQtdMaxPalete := _aRetPal[4]
		_cTipConf      := _aRetPal[5]

		If (_cTipConf == "Q")
			// valida a quantidade maxima por palete
			_lRet := (_nQtdMaxPalete > 0)
		Else
			//Valida Quantidade De Paletes
			_lRet   := (_nTotPlt > 0)
			_nSaldo := _nTotPlt
		Endif

		// executa enquanto tiver saldo
		While (_lRet) .And. (_nSaldo > 0)

			// status do conteudo do palete
			_cStsPalete := "T"

			If (_cTipConf == "Q")

				// calcula a quantidade a enderecar
				If (_nSaldo > _nQtdMaxPalete)
					_nQtdEnder := _nQtdMaxPalete
				ElseIf (_nSaldo <= _nQtdMaxPalete)
					_nQtdEnder := _nSaldo
				EndIf

				// palete fracionado
				If (_nSaldo < _nQtdMaxPalete)
					_cStsPalete := "T"
				EndIf

			Else

				_nQtdEnder := 1

			EndIf

			// calcula peso e cubagem total de armazenagem do produto
			// 1-Peso Total
			// 2-Volume Total
			_aDetArmPrd := U_FtCapPrd(mvProduto, _nQtdEnder)

			// busca os enderecos disponiveis
			_cQryEnder := " SELECT * FROM ( "
			// sub-select
			_cQryEnder += " SELECT BE_LOCAL, BE_LOCALIZ, BE_ESTFIS, "
			// quantidade de SKU por endereco
			_cQryEnder += "                (SELECT Count(DISTINCT ( CASE WHEN SBFKIT.BF_ESTFIS IN ( '000002', '000010' ) THEN SBFKIT.BF_PRODUTO ELSE '000000' END )) "
			_cQryEnder += "                 FROM   "+RetSqlName("SBF")+" SBFKIT (nolock)  "
			_cQryEnder += "                 WHERE  SBFKIT.BF_FILIAL = '"+xFilial("SBF")+"' "
			_cQryEnder += "                        AND SBFKIT.D_E_L_E_T_ = ' ' "
			_cQryEnder += "                        AND SBFKIT.BF_LOCAL = BE_LOCAL "
			_cQryEnder += "                        AND SBFKIT.BF_LOCALIZ = BE_LOCALIZ) QTD_SKU "
			// cadastro de enderecos
			_cQryEnder += " FROM "+RetSqlTab("SBE")
			// se for pra completar palete, somente do produto
			If (mvCompFrac)
				// saldo no endereco
				_cQryEnder += "        INNER JOIN " + RetSqlTab("SBF") + " (nolock) "
				_cQryEnder += "                ON " + RetSqlCond("SBF")
				_cQryEnder += "                   AND BF_LOCAL = BE_LOCAL "
				_cQryEnder += "                   AND BF_LOCALIZ = BE_LOCALIZ "
				_cQryEnder += "                   AND BF_PRODUTO = '" + mvProduto + "' "
				_cQryEnder += "                   AND BF_QUANT <= (" + Str(_nQtdMaxPalete) + " - " +Str(mvQtTotPrd)+ ")

				// composicao do palete
				_cQryEnder += "        INNER JOIN "+RetSqlTab("Z16")+" (nolock) "
				_cQryEnder += "                ON "+RetSqlCond("Z16")
				_cQryEnder += "                   AND Z16_CODPRO = BF_PRODUTO "
				_cQryEnder += "                   AND Z16_LOCAL = BF_LOCAL "
				_cQryEnder += "                   AND Z16_ENDATU = BF_LOCALIZ "
				_cQryEnder += "                   AND Z16_LOTCTL = BF_LOTECTL "
				_cQryEnder += "                   AND Z16_SALDO != 0 "
				_cQryEnder += "                   AND Z16_TPESTO = '" + mvTpEstoq + "' "
			EndIf

			// filtro padrao
			_cQryEnder += " WHERE "+RetSqlCond("SBE")
			// armazem
			_cQryEnder += " AND BE_LOCAL = '"+mvLocal+"' "
			// verifica filtros informado pelo usuario
			If (Len(mvFiltros) > 0)
				// RUA
				_cQryEnder += " AND SUBSTRING(BE_LOCALIZ,1,2) BETWEEN '"+mvFiltros[1][1]+"' AND '"+mvFiltros[1][2]+"' "
				// LADO
				If ( ! Empty(mvFiltros[2][1]))
					_cQryEnder += " AND SUBSTRING(BE_LOCALIZ,3,1) BETWEEN '"+mvFiltros[2][1]+"' AND '"+mvFiltros[2][2]+"' "
				EndIf
				// PREDIO
				_cQryEnder += " AND SUBSTRING(BE_LOCALIZ,4,2) BETWEEN '"+mvFiltros[3][1]+"' AND '"+mvFiltros[3][2]+"' "
				// ANDAR
				_cQryEnder += " AND SUBSTRING(BE_LOCALIZ,6,2) BETWEEN '"+mvFiltros[4][1]+"' AND '"+mvFiltros[4][2]+"' "
			EndIf
			// estrutura fisica
			_cQryEnder += " AND BE_ESTFIS IN "+FormatIn(mvEstruFis,"/")
			// descarta enderecos que estao no plano de enderecamento
			_cQryEnder += " AND BE_LOCALIZ NOT IN ("
			_cQryEnder += "   SELECT DISTINCT Z08_ENDDES FROM "+RetSqlTab("Z08")+" (nolock) "
			_cQryEnder += "   WHERE "+RetSqlCond("Z08")+" AND Z08_STATUS IN ('P','M') AND Z08_LOCAL = '"+mvLocal+"' "
			_cQryEnder += " ) "

			// descarta enderecos que estao no plano de expedicao
			_cQryEnder += "AND BE_LOCALIZ NOT IN ("
			_cQryEnder += "  SELECT DISTINCT Z08_ENDORI FROM "+RetSqlTab("Z08")+" (nolock) "
			_cQryEnder += "  WHERE "+RetSqlCond("Z08")+" AND Z08_STATUS IN ('P','M') AND Z08_LOCAL = '"+mvLocal+"' "
			_cQryEnder += ") "

			// descarta endereços que estão sob inventário não finalizado
			_cQryEnder += " AND BE_LOCALIZ NOT IN ( "
			_cQryEnder += "        SELECT DISTINCT Z21_LOCALI FROM " + RetSqlTab("Z21") + " (nolock) "
			_cQryEnder += "             INNER JOIN " + RetSqlTab("Z05") + " (nolock) "
			_cQryEnder += "               ON " + RetSqlCond("Z05")
			_cQryEnder += "                  AND Z05_NUMOS = Z21_IDENT  "
			_cQryEnder += "				     AND Z05_CLIENT = '" + mvCodCli + "'"
			_cQryEnder += "                  AND Z05_TPOPER = 'I'       "
			_cQryEnder += "             INNER JOIN " + RetSqlTab("Z06") + " (nolock) "
			_cQryEnder += "               ON " + RetSqlCond("Z06")
			_cQryEnder += "                  AND Z06_NUMOS = Z05_NUMOS  "
			_cQryEnder += "                  AND Z06_STATUS NOT IN ( 'FI' , 'CA' ) "
			_cQryEnder += "         WHERE " + RetSqlCond("Z21")
			_cQryEnder += "              AND Z21_LOCAL = '" + mvLocal + "'"
			_cQryEnder += " ) "

			// descarta bloqueados
			_cQryEnder += " AND BE_STATUS != '3' "

			// verifica status do endereco
			If (mvCompFrac) // completa palete fracionado
				_cQryEnder += " AND BE_STATUS = '2' "
			ElseIf ( ! mvCompFrac ) // somente desocupados
				_cQryEnder += " AND BE_STATUS = '1' "
			EndIf

			// somente enderecos do cliente
			_cQryEnder += " AND BE_ZCODCLI = '"+mvCodCli+"' "

			// somente endereços que tem o produto cadastrado ou nenhum produto cadastrado (evita endereçar em lugares vazios já reservados para outro produto)
			_cQryEnder += " AND (BE_CODPRO = '" + mvProduto + "' OR BE_CODPRO = '') "

			// agrupa os campos
			_cQryEnder += " GROUP  BY BE_LOCAL, "
			_cQryEnder += "           BE_LOCALIZ, "
			_cQryEnder += "           BE_ESTFIS ) AS ENDERECOS_DISPONIVEIS "

			// filtra enderecos com 1 sku
			If (mvCompFrac)
				_cQryEnder += " WHERE  QTD_SKU = 1 "
			EndIf

			// ordem dos dados
			_cQryEnder += " ORDER BY SUBSTRING(BE_LOCALIZ,1,2), SUBSTRING(BE_LOCALIZ,3,1) DESC, SUBSTRING(BE_LOCALIZ,4,2), SUBSTRING(BE_LOCALIZ,8,5), SUBSTRING(BE_LOCALIZ,6,2) "

			memowrit("c:\query\twmsxfun_ftendereca.txt", _cQryEnder)

			If (Select(_cAlQryEnd)<>0)
				dbSelectArea(_cAlQryEnd)
				dbCloseArea()
			EndIf

			// executa a query dos enderecos
			DbUseArea(.T.,'TOPCONN',TcGenQry(,,_cQryEnder),(_cAlQryEnd),.T.,.F.)
			dbSelectArea(_cAlQryEnd)

			// varre todos os enderecos
			If (_cAlQryEnd)->( Eof() )
				// se nao for logistica reversa
				If ( ! mvCompFrac )
					// mensagem
					U_FtWmsMsg("Não há endereço(s) disponívei(s) para recebimento do produto "+AllTrim(mvProduto)+" de acordo com os parâmetros informados.","ATENCAO")
					// variavel de controle
					_lRet := .F.
				ElseIf (mvCompFrac)
					// nova tentativa
					If ( U_FtYesNoMsg("Não há endereço(s) fracionado(s) disponível(veis) para o produto "+AllTrim(mvProduto)+". Deseja endereçar para endereços vazios?", "Log. Reversa") )
						// muda forma de pequisa
						mvCompFrac := .F.
						// loop
						Loop
					EndIf

					// variavel de controle
					_lRet := .F.

				EndIf
			EndIf

			// varre todos os enderecos
			While (_lRet) .And. (_cAlQryEnd)->( ! Eof() )

				// verifica o saldo do produto no endereco de destino
				_nSaldoSBF := QuantSBF(mvLocal,;
				(_cAlQryEnd)->BE_LOCALIZ)

				// calculo do saldo por endereco, considerando servicos a executar
				U_ConSldRF(mvLocal, (_cAlQryEnd)->BE_LOCALIZ, mvProduto, @_nSaldoSBF)

				// se o endereco ja possuir saldo, tenta outro endereco
				If ( ! mvCompFrac ) .And. (_nSaldoSBF > 0)
					// proximo endereco
					dbSelectArea(_cAlQryEnd)
					(_cAlQryEnd)->(dbSkip())
					loop
				ElseIf (mvCompFrac) .And. (_nSaldoSBF > (_nQtdMaxPalete - mvQtTotPrd))
					// proximo endereco
					dbSelectArea(_cAlQryEnd)
					(_cAlQryEnd)->(dbSkip())
					loop

				EndIf

				// calcula a capacidade do endereco
				// 1-Peso Total
				// 2-Volume Total
				_aCapacEnd := U_FtCapEnd(mvLocal,(_cAlQryEnd)->BE_LOCALIZ)

				// verifica se o endereco suporta o pallet - peso
				If (_aDetArmPrd[1] > _aCapacEnd[1])

				EndIf

				// verifica se o endereco suporta o pallet - cubagem
				If (_aDetArmPrd[2] > _aCapacEnd[2])

				EndIf

				// adiciona o endereco
				aAdd(mvEndDest,{mvLocal, (_cAlQryEnd)->BE_LOCALIZ, _nQtdEnder, _cStsPalete, _cTipConf, mvLote, mvCompFrac})

				//-- atualiza o saldo
				If _cTipConf == "Q"
					_nSaldo -= _nQtdEnder
				Else
					_nSaldo --
				EndIf

				// controle do saldo
				If (_nSaldo <= 0)
					Exit
				EndIf

				// proximo endereco
				(_cAlQryEnd)->(dbSkip())
			EndDo

			// se nao conseguir gerar o mapa completo (sobra de saldo)
			If (_nSaldo > 0) .And. (_lRet)
				// mensagem
				U_FtWmsMsg("Não há endereços disponíveis para recebimento do produto "+AllTrim(mvProduto)+" de acordo com os parâmetros informados.","ATENCAO")
				// variavel de controle
				_lRet := .F.
			EndIf

		EndDo

	ElseIf ("000007" $ mvEstruFis) // 000007-BLOCADO

		// status do conteudo do palete
		_cStsPalete := "T"

		// posiciona no cadastro do endereco
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
		If SBE->(dbSeek( xFilial("SBE") + mvLocal + mvFiltros[5][1] ))

			If SBE->BE_ESTFIS <> '000007'

				U_FtWmsMsg("Endereço digitado não se trata de um Blocado.","ATENCAO")
				_lRet := .F.

			ElseIf SBE->BE_STATUS == '3'

				U_FtWmsMsg("Blocado bloqueado para recebimento do produto "+AllTrim(mvProduto)+".","ATENCAO")
				_lRet := .F.

			EndIf

		Else
			U_FtWmsMsg("Blocado não Cadastrado para recebimento do produto "+AllTrim(mvProduto)+" de acordo com os parâmetros informados.","ATENCAO")
			_lRet := .F.
		EndIf

		If _lRet

			If (mvTpGera=="P")

				// pesquisa o lastro e camada do produto
				// estrutura do retorno
				// 1-Quantidade Total de Palete
				// 2-Quantidade de Paletes Cheios
				// 3-Quantidade de Paletes Fracionados
				// 4-Quantidade Maxima de SKU/Volumes por Palete
				// 5-Tipo do Calculo (Q-Quant Unitarios / P-Quant Palete Informado)
				_aRetPal := U_FtWmsNorma(mvProduto, mvLocal, Nil, Nil, Nil, mvCesv, mvNumSeq, mvSeqKit, Iif(mvTpGera=="P",mvQuant,Nil), Nil)

				// atualiza variavel de controle de acordo com o calculo da funcao FtWmsNorma
				_nTotPlt       := _aRetPal[1]
				_nQtdPltChe    := _aRetPal[2]
				_nQtdPltFra    := _aRetPal[3]
				_nQtdMaxPalete := _aRetPal[4]
				_cTipConf      := _aRetPal[5]

				If _cTipConf == "Q"

					// calcula a quantidade a enderecar
					If (_nSaldo > _nQtdMaxPalete)
						_nQtdEnder := _nQtdMaxPalete
					ElseIf (_nSaldo <= _nQtdMaxPalete)
						_nQtdEnder := _nSaldo
					EndIf

					// executa enquanto tiver saldo
					While (_lRet) .And. (_nSaldo > 0)
						// adiciona o endereco
						aAdd(mvEndDest,{mvLocal, mvFiltros[5][1], _nQtdEnder, _cStsPalete, _cTipConf, mvLote, mvCompFrac})
						_nSaldo -= _nQtdEnder
					EndDo
				Else

					_nQtdEnder := 1
					For _i := 1 To _nQtdPltChe
						// adiciona o endereco
						aAdd(mvEndDest,{mvLocal, mvFiltros[5][1], _nQtdEnder, _cStsPalete, _cTipConf, mvLote, mvCompFrac})
					Next _i

				EndIf

			ElseIf (mvTpGera=="R")

				// loop da quantidade de paletes para reserva de enderecos
				For _i := 1 To _nSaldo
					// adiciona o endereco
					aAdd(mvEndDest,{mvLocal, mvFiltros[5][1], 1, _cStsPalete, _cTipConf, mvLote, mvCompFrac})
				Next _i

			EndIf

		EndIf
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni)
	RestArea(_aArea)

Return(_lRet)

// ** funcao para calculo de capacidade produto - utilizacao
User Function FtCapPrd(mvProdut,mvQuant)
	// variavel de retorno
	// 1-Peso Total
	// 2-Volume Total
	local _aRet := {999999,999999}
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SB1","SB5","DC1"})

	// posiciona no cadastro do unitizador
	//dbSelectArea("DC1")
	//DC1->(dbSetOrder(1)) // 1-DC1_FILIAL, DC1_CODUNI
	//If ! DC1->(dbSeek( xFilial("SB1")+mvUnitiz ))
	//	MsgStop("não achou unitizador")
	//EndIf

	// posiciona no cadastro do produto
	dbSelectArea("SB1")
	SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
	If SB1->(dbSeek( xFilial("SB1")+mvProdut ))
		// calcula o peso total
		If (SB1->B1_PESBRU > 0)
			_aRet[1] := Round(SB1->B1_PESBRU * mvQuant,TamSx3("B1_PESBRU")[2])
			// acresce peso do unitizador
			//_aRet[1] += DC1->DC1_TARA
		EndIf
		// pesquisa o complemento do produto para pegar as medidas de armazenagem
		dbSelectArea('SB5')
		SB5->(dbSetOrder(1)) // 1-B5_FILIAL, B5_COD
		If SB5->(dbSeek( xFilial('SB5')+mvProdut ))
			If (SB5->B5_COMPRLC > 0) .And. (SB5->B5_LARGLC > 0) .And. (SB5->B5_ALTURLC > 0)
				// calcula a cubagem total
				_aRet[2] := SB5->(B5_COMPRLC * B5_LARGLC * B5_ALTURLC) * mvQuant
				// acresce a cubagem do unitizador
				//_aRet[2] += DC1->(DC1_ALTMAX * DC1_LRGMAX * DC1_CMPMAX)
			EndIf
		EndIf
	EndIF

	// restaura areas iniciais
	RestOrd(_aAreaIni)
	RestArea(_aArea)

Return(_aRet)

// ** funcao para calculo de capacidade endereco
User Function FtCapEnd(mvLocal,mvEnderec)
	// variavel de retorno
	// 1-Peso Total
	// 2-Volume Total
	local _aRet := {999999,999999}
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SBE"})

	// posiciona no cadastro do endereco
	dbSelectArea("SBE")
	SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
	If SBE->(dbSeek( xFilial("SBE")+mvLocal+mvEnderec ))
		// calcula o peso total
		If (SBE->BE_CAPACID > 0)
			_aRet[1] := SBE->BE_CAPACID
		EndIf
		// calcula a cubagem total
		If (SBE->BE_COMPRLC > 0) .And. (SBE->BE_LARGLC > 0) .And. (SBE->BE_ALTURLC > 0)
			_aRet[2] := Round(SBE->(BE_COMPRLC * BE_LARGLC * BE_ALTURLC),TamSx3("BE_COMPRLC")[2])
		EndIf
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni)
	RestArea(_aArea)

Return(_aRet)

// ** funcao que valida o codigo do equipamento
Static Function sfVldEquip()
	local _lRet := .T.

	// sem equipamento
	If (Empty(_cCodEquip))
		Return(_lRet)
	EndIf

	// pesquisa pelo equipamento
	If (_lRet)

		// cadastro de equipamento
		dbSelectArea("SZQ")
		SZQ->(dbSetOrder(1)) // 1-ZQ_FILIAL, ZQ_CODIGO
		If ( ! SZQ->(dbSeek( xFilial("SZQ")+_cCodEquip )))
			U_FtWmsMsg("Equipamento não cadastrado!","ATENCAO")
			_lRet := .F.
		EndIf

		// valida se esta disponivel para a filial corrente
		If (_lRet) .And. ( ! (cFilAnt $ SZQ->ZQ_DISPFIL) )
			U_FtWmsMsg("Equipamento não disponível para esta filial!","ATENCAO")
			_lRet := .F.
		EndIf

		// se ok, atualiza o tipo de equipamento
		If (_lRet)
			// tipo do equipamento
			_cTipEquip := SZQ->ZQ_TIPO

			// query - equipamento
			cQryFilZ06 += " AND EXISTS ("
			cQryFilZ06 += "        SELECT Z18_OPERAD FROM "+RetSqlName("Z18")+" Z18 (nolock)  "
			cQryFilZ06 += "        WHERE "+RetSqlCond("Z18")+" "
			cQryFilZ06 += "        AND Z18_NUMOS  = Z06_NUMOS AND Z18_SEQOS = Z06_SEQOS "
			cQryFilZ06 += "        AND Z18_TPEQUI = '"+_cTipEquip+"' "
			cQryFilZ06 += "        AND Z18_CATEG  = 'E' "
			cQryFilZ06 += "        AND Z18_STATUS = 'P' " // P=Planejado / R=Realizado / B=Bloqueado
			cQryFilZ06 += "        ) "

			// inclui o filtro de endereco por tipo de equipamento
			If(_cTipEquip == "XXX")
				_cQryEndEq := "( 1=1 )"
			ElseIf (_cTipEquip == "PE1") // paleteira eletrica
				_cQryEndEq := "( "
				_cQryEndEq += " (Z05_TPOPER = 'E' AND CMP_ENDSRV BETWEEN 'DOCA' AND 'DOCAZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'E' AND CMP_ENDSRV BETWEEN 'STAGE' AND 'STAGEZZZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'E' AND CMP_ENDSRV BETWEEN 'PORTAO' AND 'PORTAOZZZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_FILIAL != '105' AND Z05_TPOPER = 'S' AND SUBSTRING(CMP_ENDSRV,1,2) BETWEEN '01' AND '99' AND SUBSTRING(CMP_ENDSRV,3,1) = ' ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_FILIAL  = '105' AND Z05_TPOPER = 'S' AND SUBSTRING(CMP_ENDSRV,1,2) BETWEEN '01' AND '99' AND (Substring(CMP_ENDSRV, 3, 1) = ' ' OR Substring(CMP_ENDSRV, 6, 2) = '01') ) "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'S' AND CMP_ENDSRV BETWEEN 'BLOCO' AND 'BLOCOZZ' ) "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'S' AND CMP_ENDSRV BETWEEN 'QUADRA' AND 'QUADRAZZ' ) "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'S' AND CMP_ENDSRV BETWEEN 'STAGE' AND 'STAGEZZZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'S' AND CMP_ENDSRV BETWEEN 'DOCA' AND 'DOCAZZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'I' AND (SUBSTRING(CMP_ENDSRV,1,2) BETWEEN '01' AND '99' AND SUBSTRING(CMP_ENDSRV,3,1) = ' ') OR (SUBSTRING(CMP_ENDSRV,1,4) = 'DOCA')) "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'I' AND CMP_ENDSRV BETWEEN '01' AND '99' AND SUBSTRING(CMP_ENDSRV,3,1) = ' ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'I' AND CMP_ENDSRV BETWEEN 'RETRABALHO' AND 'RETRABALHOZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'I' AND CMP_ENDSRV BETWEEN 'BLOCO' AND 'BLOCOZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'I' AND CMP_ENDSRV BETWEEN 'QUADRA' AND 'QUADRAZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'I' AND CMP_ENDSRV BETWEEN 'NAOCONFORME' AND 'NAOCONFORMEZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'I' AND CMP_ENDSRV BETWEEN 'ANALISE' AND 'ANALISEZZ') "
				_cQryEndEq += ")  "

			ElseIf (_cTipEquip $ "ER1/EG1/EE1") // empilhadeira eletrica
				_cQryEndEq := "( "
				_cQryEndEq += " (CMP_ENDSRV BETWEEN 'DOCA' AND 'DOCAZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (CMP_ENDSRV BETWEEN '01A' AND '99ZZZZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (CMP_ENDSRV BETWEEN '01' AND '99' AND SUBSTRING(CMP_ENDSRV,3,1) = ' ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (CMP_ENDSRV BETWEEN 'RETRABALHO' AND 'RETRABALHOZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (CMP_ENDSRV BETWEEN 'STAGE' AND 'STAGEZZZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (CMP_ENDSRV BETWEEN 'PORTAO' AND 'PORTAOZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (CMP_ENDSRV BETWEEN 'BLOCO' AND 'BLOCOZZZ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (CMP_ENDSRV BETWEEN 'QUADRA' AND 'QUADRAZZZ') "
				_cQryEndEq += ") "

			ElseIf (_cTipEquip == "TE1") // trilateral eletrica
				_cQryEndEq := "( "
				_cQryEndEq += " (Z05_TPOPER = 'E' AND CMP_ENDSRV BETWEEN '01'  AND '99'   AND SUBSTRING(CMP_ENDSRV,3,1)  = ' ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'S' AND CMP_ENDSRV BETWEEN '01A' AND '99ZZ' AND SUBSTRING(CMP_ENDSRV,3,1) != ' ') "
				_cQryEndEq += " OR "
				_cQryEndEq += " (Z05_TPOPER = 'I' AND CMP_ENDSRV BETWEEN '01'  AND '99') "
				_cQryEndEq += ") "

			EndIf

		EndIf

	EndIf

Return(_lRet)

// ** funcao que retorna todos os servicos e tarefas configurados
User Function FtRetSrv(mvCodSrv, mvCodTrf, mvGeraOS, mvOperacao, mvCodCli, mvLojCli, mvNrContra)

	// query
	local _cQuery

	// 1-Cod Servico
	// 2-Dsc Servico
	// 3-Cod Tarefa
	// 4-Dsc Tarefa
	// 5-Funcao/Rotina
	local _aRet := {"","","","",""}

	// conteudo padrao
	Default mvCodSrv   := CriaVar("Z06_SERVIC", .F.)
	Default mvCodTrf   := CriaVar("Z06_TAREFA", .F.)
	Default mvGeraOS   := .F.
	Default mvOperacao := ""
	Default mvCodCli   := CriaVar("A1_COD"    , .F.)
	Default mvLojCli   := CriaVar("A1_LOJA"   , .F.)
	Default mvNrContra := CriaVar("AAM_CONTRT", .F.)

	// retorna codigo de servico, tarefa e atividades
	_cQuery := " SELECT TOP " + AllTrim(Str(If(mvGeraOS, 1, 100)))
	// cod servico e descricao
	_cQuery += " DC5_SERVIC, SX5SRV.X5_DESCRI DSC_SERVICO, "
	// cod tarefa e descricao
	_cQuery += " DC5_TAREFA, SX5TRF.X5_DESCRI DSC_TAREFA, "
	// funcao/rotina a ser executada
	_cQuery += " CASE WHEN Z37_ROTINA != ' ' THEN Z37_ROTINA ELSE DC5_FUNEXE END DC5_FUNEXE "
	// cad. servicos
	_cQuery += " FROM " + RetSqlTab("DC5") + " (nolock) "
	// desc. servico - tab L4
	_cQuery += " INNER JOIN " + RetSqlName("SX5") + " SX5SRV (nolock)  ON SX5SRV.X5_FILIAL = '" + xFilial("SX5") + "' AND SX5SRV.D_E_L_E_T_ = ' ' AND SX5SRV.X5_TABELA = 'L4' AND SX5SRV.X5_CHAVE = DC5_SERVIC "
	// desc. tarefa - tab L2
	_cQuery += " INNER JOIN " + RetSqlName("SX5") + " SX5TRF (nolock)  ON SX5TRF.X5_FILIAL = '" + xFilial("SX5") + "' AND SX5TRF.D_E_L_E_T_ = ' ' AND SX5TRF.X5_TABELA = 'L2' AND SX5TRF.X5_CHAVE = DC5_TAREFA "
	// atividades da tarefa
	_cQuery += " INNER JOIN " + RetSqlTab("DC6") + " (nolock)  ON " + RetSqlCond("DC6") + " AND DC6_TAREFA = DC5_TAREFA "
	// configuracao especifica do cliente
	_cQuery += " INNER JOIN " + RetSqlTab("Z37") + " (nolock)  ON " + RetSqlCond("Z37")
	_cQuery += " AND Z37_CODCLI = '" + mvCodCli + "' AND Z37_LOJCLI = '" + mvLojCli + "' "
	_cQuery += " AND Z37_CONTRT = '" + mvNrContra + "' "
	_cQuery += " AND Z37_SERVIC = DC5_SERVIC "
	_cQuery += " AND Z37_TAREFA = DC5_TAREFA "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("DC5")
	// filtra por codigo do servico
	If ( ! Empty(mvCodSrv) )
		_cQuery += " AND DC5_SERVIC = '" + mvCodSrv + "' "
		// filtra por codigo da tarefa
		If ( ! Empty(mvCodTrf) )
			_cQuery += " AND DC5_TAREFA = '" + mvCodTrf + "' "
		EndIf

		// filtra por tipo de servico
	ElseIf ( Empty(mvCodSrv) )
		// 1/E = Entrada
		If (mvOperacao == "E")
			_cQuery += " AND DC5_TIPO = '1' "
			// 2/S = Saida
		ElseIf (mvOperacao == "S")
			_cQuery += " AND DC5_TIPO = '2' "
			// 3/I = Interna
		ElseIf (mvOperacao == "I")
			_cQuery += " AND DC5_TIPO = '3' "
		EndIf
	EndIf
	// ordem dos dados
	_cQuery += " ORDER BY DC5_SERVIC, Z37_ORDEM, DC6_ORDEM"

	memowrit("c:\query\twmsxfun_FtRetSrv.txt",_cQuery)

	// alimenta o vetor com os dados da query
	_aRet := U_SqlToVet(_cQuery)

Return(_aRet)

// ** funcao que retorna a proxima atividade planejada da OS
User Function FtPrxSrv(mvNumOS, mvSeqOS, mvCodCli, mvLojCli, mvNrContra)

	// query
	local _cQuery

	// 1-Num OS
	// 2-Seq OS
	// 3-Cod Servico
	// 4-Dsc Servico
	// 5-Cod Tarefa
	// 6-Dsc Tarefa
	// 7-Funcao/Rotina
	local _aRet := {"","","","","","",""}

	// conteudo padrao
	Default mvCodCli   := CriaVar("A1_COD"    , .F.)
	Default mvLojCli   := CriaVar("A1_LOJA"   , .F.)
	Default mvNrContra := CriaVar("AAM_CONTRT", .F.)

	// retorna codigo de servico, tarefa e atividades
	_cQuery := "SELECT "
	// numero e sequencia da OS
	_cQuery += "Z06_NUMOS, Z06_SEQOS, "
	// cod servico e descricao
	_cQuery += "Z06_SERVIC, SX5SRV.X5_DESCRI DSC_SERVICO, "
	// cod tarefa e descricao
	_cQuery += "Z06_TAREFA, SX5TRF.X5_DESCRI DSC_TAREFA, "
	// funcao/rotina a ser executada
	_cQuery += "CASE WHEN Z37_ROTINA != ' ' THEN Z37_ROTINA ELSE DC5_FUNEXE END DC5_FUNEXE "
	// itens da ordem de servico
	_cQuery += "FROM "+RetSqlName("Z06")+" Z06 (nolock)  "
	// desc. servico - tab L4
	_cQuery += "INNER JOIN SX5010 SX5SRV (nolock)  ON SX5SRV.X5_FILIAL = '  ' AND SX5SRV.D_E_L_E_T_ = ' ' AND SX5SRV.X5_TABELA = 'L4' AND SX5SRV.X5_CHAVE = Z06_SERVIC "
	// desc. tarefa - tab L2
	_cQuery += "INNER JOIN SX5010 SX5TRF (nolock)  ON SX5TRF.X5_FILIAL = '  ' AND SX5TRF.D_E_L_E_T_ = ' ' AND SX5TRF.X5_TABELA = 'L2' AND SX5TRF.X5_CHAVE = Z06_TAREFA "
	// configuracao especifica do cliente
	_cQuery += "LEFT JOIN "+RetSqlName("Z37")+" Z37 (nolock)  ON "+RetSqlCond("Z37")
	_cQuery += "AND Z37_CODCLI = '"+mvCodCli+"' AND Z37_LOJCLI = '"+mvLojCli+"' "
	_cQuery += "AND Z37_CONTRT = '"+mvNrContra+"' "
	_cQuery += "AND Z37_SERVIC = Z06_SERVIC "
	_cQuery += "AND Z37_TAREFA = Z06_TAREFA "
	// cad. configuracao geral de servicos
	_cQuery += "LEFT  JOIN "+RetSqlName("DC5")+" DC5 (nolock)  ON "+RetSqlCond("DC5")+" AND DC5_SERVIC = Z06_SERVIC AND DC5_TAREFA = Z06_TAREFA "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z06")+" "
	// filtra numero da OS
	_cQuery += "AND Z06_NUMOS = '"+mvNumOS+"' "
	// proxima sequencia
	_cQuery += "AND Z06_SEQOS > '"+mvSeqOS+"' "
	// ordem dos dados
	_cQuery += "ORDER BY Z06_SEQOS"

	memowrit("c:\query\twmsxfun_FtPrxSrv.txt",_cQuery)

	// alimenta o vetor com os dados da query
	_aRet := U_SqlToVet(_cQuery)

Return(_aRet)

// ** funcao que retorna a norma de unitizacao do produto
User Function FtWmsNorma(mvProduto, mvLocal, mvLastro, mvCamada, mvAdicio, mvCesv, mvNumSeq, mvSeqKit, mvQtdTot, mvQtdPltInf)

	local _lRet := .F.
	Local _nRet := 0
	Local _aRet := {0, 0, 0, 0, ""}

	// seek
	local _cSeekZ04
	local _cSeekZ32

	// area inicial
	local _aAreaZ20  := Z20->(GetArea())
	local _aAreaZ04  := Z04->(GetArea())
	local _aAreaSB1  := SB1->(GetArea())
	local _aAreaZ32  := Z32->(GetArea())

	local _aAreaIni  := SaveOrd({"Z20","Z04","SB1", "Z32"})

	// total de paletes
	Local _nQtdPltChe := 0
	Local _nQtdPltFra := 0
	Local _nQtdMaxPal := 0

	// query
	local _cQuery

	// Retorno Quantidade de Paletes (chamada de FtWmsNorma, dentro dela mesma)
	Local _aRetPal := {}

	// zera variaveis
	Default mvLastro    := 0
	Default mvCamada    := 0
	Default mvAdicio    := 0
	Default mvCesv      := ""
	Default mvNumSeq    := ""
	Default mvSeqKit    := ""
	Default mvQtdTot    := 0
	Default mvQtdPltInf := 0

	// quando a quantidade de pallet for informada não calcula e nem busca do cadastro
	_lRet := (mvQtdPltInf > 0)

	// verifica a necessidade de buscar Lastro e Camada pelo CESV
	If ( ! _lRet ) .And. ( ! Empty(mvCesv) ) .And. ( ( ! Empty(mvNumSeq) ) .Or. ( ! Empty(mvSeqKit) ) ) .And. (mvQtdPltInf == 0)
		// itens da nota por veiculo
		dbSelectArea("Z04")
		Z04->(dbOrderNickName("Z04_CESV")) // Z04_FILIAL, Z04_CESV
		Z04->(dbSeek( _cSeekZ04 := xFilial("Z04")+mvCesv ))
		While Z04->( ! Eof() ) .And. ((Z04->Z04_FILIAL + Z04->Z04_CESV) == _cSeekZ04)

			// verifica o NumSeq
			If ( (Empty(mvSeqKit)) .And. (Empty(Z04->Z04_SEQKIT)) .And. (Z04->Z04_NUMSEQ $ mvNumSeq) ) .Or. ( ( ! Empty(mvSeqKit)) .And. ( ! Empty(Z04->Z04_SEQKIT)) .And. (Z04->Z04_SEQKIT == mvSeqKit) .And. (Empty(Z04->Z04_NUMSEQ)) )

				// atualiza variaveis de lastro e camada do cadastro do produto
				mvLastro    := Z04->Z04_LASTRO
				mvCamada    := Z04->Z04_CAMADA
				mvAdicio    := Z04->Z04_ADICIO
				mvQtdPltInf := Z04->Z04_QTDPAL

				// encontrou os registros para cálculo
				_lRet := .T.

				// sai do loop
				Exit
			EndIf

			// proximo item
			Z04->(dbSkip())
		EndDo

	EndIf

	// posiciona no cadastro de lastro e camada do produto
	If ( ! _lRet ) .And. (mvLastro == 0) .And. (mvQtdPltInf == 0)

		// cadastro de lastro e camada do produto
		dbSelectArea("Z20")
		Z20->(dbOrderNickName("Z20_CODPRO")) // Z20_FILIAL, Z20_CODPRO, Z20_LOCAL, Z20_UNITIZ
		If Z20->(dbSeek( xFilial("Z20") + mvProduto + mvLocal ))

			// atualiza variaveis de lastro e camada do cadastro do produto
			mvLastro    := Z20->Z20_LASTRO
			mvCamada    := Z20->Z20_CAMADA
			mvAdicio    := Z20->Z20_ADICIO
			mvQtdPltInf := 0

			// encontrou os registros para cálculo
			_lRet := (((mvLastro * mvCamada) + mvAdicio) != 0)
		EndIf

		// nao encontrou, então tenta localizar diretamente do cadastro do produto
		If ( ! _lRet )
			// cadastro produto
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1)) // 01 - B1_FILIAL, B1_COD, R_E_C_N_O_, D_E_L_E_T_
			If SB1->(dbSeek( xFilial("SB1") + mvProduto))

				// atualiza variaveis de lastro e camada do cadastro do produto
				mvLastro    := SB1->B1_ZLASTRO
				mvCamada    := SB1->B1_ZCAMADA
				mvAdicio    := SB1->B1_ZADICIO
				mvQtdPltInf := 0

				// encontrou os registros para cálculo
				_lRet := (((mvLastro * mvCamada) + mvAdicio) != 0)
			EndIf
		EndIf
	EndIf

	// prepara variavel de retorno de acordo com a quantidade de paletes informados - Tipo P
	If (_lRet) .And. (mvQtdPltInf > 0)
		// quando for palete informado, e nao nao tem quantidade maxima do produto por palete
		If (_nQtdMaxPal == 0) .And. ( ! IsInCallStack("U_FtWmsNorma") )
			// pesquisa o lastro e camada do produto
			// estrutura do retorno
			// 1-Quantidade Total de Palete
			// 2-Quantidade de Paletes Cheios
			// 3-Quantidade de Paletes Fracionados
			// 4-Quantidade Maxima de SKU/Volumes por Palete
			// 5-Tipo do Calculo (Q-Quant Unitarios / P-Quant Palete Informado)
			_aRetPal := U_FtWmsNorma(mvProduto, mvLocal, Nil, Nil, Nil, Nil, Nil, Nil, mvQtdTot, mvQtdPltInf)

			// atualiza variavel de controle de acordo com o calculo da funcao FtWmsNorma
			_nQtdMaxPal := _aRetPal[4]
		EndIf

		// prepara variavel de retorno
		_aRet := {mvQtdPltInf, mvQtdPltInf, 0, _nQtdMaxPal, "P"}

	EndIf

	// prepara variavel de retorno de acordo com a regra de Lastro x Camada + Adicional - Tipo Q
	If (_lRet) .And. (mvQtdPltInf == 0)

		// calcula a quantidade maxima por palete
		_nQtdMaxPal := (mvLastro * mvCamada) + mvAdicio

		// calcula a quantidade de palete
		_nQtdPltChe := Int(mvQtdTot / _nQtdMaxPal)

		// calcula quantidade de paletes fracionas
		If (Mod(mvQtdTot, _nQtdMaxPal) > 0)
			_nQtdPltFra ++
		EndIf

		// Quantidade De Paletes
		_aRet := {(_nQtdPltChe+_nQtdPltFra), _nQtdPltChe, _nQtdPltFra, _nQtdMaxPal, "Q"}

	EndIf

	// nao atendeu nenhuma das condicoes anteriores, então busca o maximo por palete no cadastro de Sku do item
	If ( ! _lRet ) .Or. ( ((mvQtdTot+mvQtdPltInf) > 0) .And. (_aRet[1] == 0) ) .Or. ( ((mvQtdTot+mvQtdPltInf) == 0) .And. (_aRet[4] == 0) )

		// cadastro de Sku por item
		dbSelectArea("Z32")
		Z32->(dbSetOrder(1)) // 1-Z32_FILIAL, Z32_CODPRO, Z32_ORDEM
		Z32->(dbSeek( _cSeekZ32 := xFilial("Z32") + mvProduto ))
		// varre todos os itens
		While Z32->( ! Eof() ) .And. (Z32->(Z32_FILIAL + Z32_CODPRO) == _cSeekZ32)

			// verifica o tipo = 9-Palete Completo
			If (Z32->Z32_TIPO == "9")

				// calcula a quantidade maxima por palete
				_nQtdMaxPal := Z32->Z32_QUANT

				// calcula a quantidade de palete
				_nQtdPltChe := Int(mvQtdTot / _nQtdMaxPal)

				// calcula quantidade de paletes fracionas
				If (Mod(mvQtdTot, _nQtdMaxPal) > 0)
					_nQtdPltFra ++
				EndIf

				// Quantidade De Paletes
				_aRet := {(_nQtdPltChe+_nQtdPltFra), _nQtdPltChe, _nQtdPltFra, _nQtdMaxPal, "Q"}

				// encontrou os registros para cálculo
				_lRet := .T.

				// sai do loop
				Exit
			EndIf

			// proximo item
			Z32->(dbSkip())
		EndDo

	EndIf

	// necessario informar lastro e camada do produto
	If ( ! _lRet ) .Or. ( ((mvQtdTot+mvQtdPltInf) > 0) .And. (_aRet[1] == 0) ) .Or. ( ((mvQtdTot+mvQtdPltInf) == 0) .And. (_aRet[4] == 0) )
		// mensagem
		U_FtWmsMsg("Lastro e Camada ou Quantidade de Palete(s) não está definido para o produto " + AllTrim(mvProduto),"ATENCAO")
		// retorno
		Return(_aRet)
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni)
	RestArea(_aAreaZ20)
	RestArea(_aAreaSB1)
	RestArea(_aAreaZ32)
	RestArea(_aAreaZ04)

Return(_aRet)

// ** 6. funcao que retorna complemento para o filtro dos servicos do usuario recebido como parametro
User Function FtWmsFlt(mvTpUser, mvCodUser)
	Local cCodFunc := ""
	Local cQryFiltro := ""
	Local aAreaAtu := GetArea()

	// nao executa para o gerente, supervisores, líderes
	If (mvTpUser == "G") .Or. (mvTpUser=="S") .OR. (mvTpUser == "L")
		Return(cQryFiltro)
	EndIf

	// caso for o monitor, usa o codigo do usuario para o operador
	If (mvTpUser == "M") .And. (Empty(mvCodUser))
		mvCodUser := __cUserId
	EndIf

	// monta filtro com as funcoes do usuario, somente para operadores
	If (mvTpUser $ "O")
		dbSelectArea("DCI")
		DCI->(dbSetOrder(1))//DCI_FILIAL, DCI_CODFUN, DCI_ORDFUN, DCI_FUNCAO
		If (!DCI->(dbSeek( xFilial("DCI")+mvCodUser )))
			//MsgStop("Funções do operador não cadastrado no Recurso do WMS.")
			DLAviso(nil,"Validação (FtWmsFlt)","Funções do operador não cadastrado no Recurso do WMS.")
			cCodFunc += "99999/"
		Else
			While (DCI->(!Eof())) .And. (DCI->DCI_FILIAL == xFilial("DCI")) .And. (DCI->DCI_CODFUN == mvCodUser)
				// inclui funcao do funcionario
				cCodFunc += DCI->DCI_FUNCAO+"/"
				// proxima funcao
				DCI->(dbSkip())
			EndDo
		EndIf
		// insere filtro das funcoes
		cCodFunc := Left(cCodFunc,Len(cCodFunc)-1)
		// inclui condicao de filtro
		cQryFiltro += " ( EXISTS "
		cQryFiltro += "     ( SELECT Z18_FUNCAO FROM " + RetSqlTab("Z18") + " (nolock) "
		cQryFiltro += "        WHERE " + RetSqlCond("Z18")
		cQryFiltro += "          AND Z18_NUMOS = Z06_NUMOS "
		cQryFiltro += "          AND Z18_FUNCAO IN " + FormatIn(cCodFunc, "/")
		cQryFiltro += "     ) "
		cQryFiltro += " ) "
	EndIf

	// regras de convocacao
	If Select("QRYDCQ") <> 0
		dbSelectArea("QRYDCQ")
		dbCloseArea()
	EndIf

	BeginSql Alias "QRYDCQ"
		SELECT *
		FROM %table:DCQ% DCQ  (nolock)
		WHERE DCQ_FILIAL = %xFilial:DCQ% AND DCQ.%NotDel%
		AND DCQ_CODFUN = %Exp:mvCodUser%
		AND DCQ_STATUS = %Exp:'1'%
	EndSql

	dbSelectArea("QRYDCQ")
	QRYDCQ->(dbGoTop())

	// caso nao tenha regra de convocacao, inclui condicao para nao trazer nada
	If (QRYDCQ->(Eof()))
		U_FtWmsMsg("Necessário verificar a regra de convocação!" + CRLF;
		+ "Verifique o cadastro do usuário na rotina de Recursos Humanos WMS";
		,"Função FtWmsFlt")
		cQryFiltro += IIf( Empty(cQryFiltro), "(" , " AND Z06_SERVIC = 'ZZZ' ")
	Else
		// inicia 1a condicao
		cQryFiltro += IIf( Empty(cQryFiltro), "(" , " AND ( ")

		// monta a regua de filtro
		While QRYDCQ->(!Eof())
			// Armazém
			If (QRYDCQ->DCQ_LOCAL == '**')  //(se "**" - qualquer armazem, então não filtra)
				cQryFiltro += "(1=1 "
			Else //filtra apenas o armazem onde pode atuar
				cQryFiltro += "(Z06_LOCAL = '" + QRYDCQ->DCQ_LOCAL + "' "
			Endif

			// servico
			If !Empty(QRYDCQ->DCQ_SERVIC)
				cQryFiltro += "AND Z06_SERVIC = '"+QRYDCQ->DCQ_SERVIC+"' "
			EndIf
			// tarefa
			If !Empty(QRYDCQ->DCQ_TAREFA)
				cQryFiltro += "AND Z06_TAREFA = '"+QRYDCQ->DCQ_TAREFA+"' "
			EndIf
			// endereco inicial e final
			If !Empty(QRYDCQ->DCQ_ENDFIM)
				cQryFiltro += "AND ( (Z06_ENDSRV BETWEEN '"+QRYDCQ->DCQ_ENDINI+"' AND '"+QRYDCQ->DCQ_ENDFIM+"') OR (Z06_ENDSRV = 'ZZZ') )"
			EndIf
			// fecha 2a condicao
			cQryFiltro += ") "
			// proxima regra
			QRYDCQ->(dbSkip())

			// complementa condicao
			If QRYDCQ->(!Eof())
				cQryFiltro += " OR "
			EndIf
		EndDo
		// fecha 1a condicao
		cQryFiltro += ") "
	EndIf
	// fecha o alias
	dbSelectArea("QRYDCQ")
	dbCloseArea()

	// restaura area incial
	RestArea(aAreaAtu)

	//gera log do filtro
	MemoWrit("c:\query\TWMSXFUN_FtWmsFlt_cQryFiltro " + Time() + ".txt", cQryFiltro)

Return(" AND "+cQryFiltro)

// ** 7. funcao para validacao do codigo de barras lido
// ** utilizado em campos que possibilite informar o codigo do produto ou codigo de barras
User Function FtCodBar(mvChvPesq, mvCodProd, mvInfQtd, mvNumSeq, mvTpIdEtiq, mvCodCli, mvQuant, mvNumSerie)
	// area inicial
	local _aAreaIni := SaveOrd({"SA1", "Z32"})

	// controle de pesquisa
	Local _lEncontrou := .T.
	local _lNovaPesq  := .T.

	// controle etiqueta intena
	local _lEtqCodInt := .F.
	local _lEtqIdInt  := .F.
	local _lEtqIdEAN  := .F.
	local _lEtqIdDUN  := .F.
	local _lEtqCod128 := .F.
	local _lEtqClient := .F.

	// sigla do cliente
	local _cSiglaCli := ""

	// seek
	local _cSeekZ56

	// valores padroes
	Default mvCodProd  := Space(Len(SB1->B1_COD))
	Default mvNumSeq   := ""
	Default mvTpIdEtiq := "INTERNA"
	Default mvCodCli   := CriaVar("A1_COD", .F.)
	Default mvQuant    := Nil
	Default mvNumSerie := Nil

	// controle etiqueta intena
	_lEtqCodInt := (AllTrim(mvTpIdEtiq) == "B1_COD")
	_lEtqIdInt  := (AllTrim(mvTpIdEtiq) == "INTERNA")
	_lEtqIdEAN  := (AllTrim(mvTpIdEtiq) == "EAN") .Or. (AllTrim(mvTpIdEtiq) == "EAN13")
	_lEtqIdDUN  := (AllTrim(mvTpIdEtiq) == "DUN14")
	_lEtqCod128 := (AllTrim(mvTpIdEtiq) == "CODE128")
	_lEtqClient := (AllTrim(mvTpIdEtiq) == "CLIENTE")

	// posiciona no cadastro de cliente
	If ( ! Empty(mvCodCli) )

		// posiciona no cadastro do cliente
		dbSelectArea("SA1")
		SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
		SA1->(dbSeek( xFilial("SA1") + mvCodCli ))

		// atualiza a sigla do cliente
		_cSiglaCli := SA1->A1_SIGLA

	EndIf

	// pesquisa se a etiqueta é valida
	If (_lEncontrou) .And. (_lNovaPesq) .And. (_lEtqIdInt)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11") + mvChvPesq ))
			// mensagem
			U_FtWmsMsg("Identificador do produto inválido!","ATENCAO")
			// variavel de retorno
			_lEncontrou := .F.
		EndIf
	EndIf

	// valida o tipo da etiqueta lida
	If (_lEncontrou) .And. (_lNovaPesq) .And. (_lEtqIdInt)
		If (Z11->Z11_TIPO != "01")
			// mensagem
			U_FtWmsMsg("Tipo de etiqueta inválida!","ATENCAO")
			// variavel de retorno
			_lEncontrou := .F.
		EndIf
	EndIf

	// pesquisa pelo num seq da nota de entrada
	If (_lEncontrou) .And. (_lNovaPesq) .And. (_lEtqIdInt)
		dbSelectArea("SD1")
		SD1->(dbSetOrder(4)) // 4-D1_FILIAL, D1_NUMSEQ
		If ! SD1->(dbSeek( xFilial("SD1") + Z11->Z11_NUMSEQ ))
			// mensagem
			U_FtWmsMsg("Erro ident num seq","ATENCAO")
			// variavel de retorno
			_lEncontrou := .F.
		EndIf
	EndIf

	// pesquisa o codigo do produto
	If (_lEncontrou) .And. (_lNovaPesq) .And. (_lEtqIdInt)
		// cad. de produto
		dbSelectArea("SB1")
		SB1->(dbSetOrder(1)) // B1_FILIAL, B1_COD
		If ! SB1->(dbSeek( xFilial("SB1") + Z11->Z11_CODPRO ))
			// mensagem
			U_FtWmsMsg("Erro na pesquisa pelo produto","ATENCAO")
			// variavel de retorno
			_lEncontrou := .F.
		Else
			// informa quantidade manual
			mvInfQtd   := (SB1->(FieldPos("B1_ZINFQTD"))>0) .And. (SB1->B1_ZINFQTD=="S")
			// informa número de série
			mvNumSerie := (SB1->(FieldPos("B1_ZNUMSER"))>0) .And. (SB1->B1_ZNUMSER=="S")
			// atualiza codigo do produto
			mvCodProd  := SB1->B1_COD
			// atualiza num seq de retorno
			mvNumSeq   := SD1->D1_NUMSEQ
			// nao pesquisa mais
			_lNovaPesq := .F.
		EndIf
	EndIf

	// pesquisa o codigo do produto pelo EAN / CODE128 / DUN14 na tabela de cadastro de códigos de barras adicionais (Z32)
	If (_lEncontrou) .And. (_lNovaPesq) .And. ((_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIdDUN) )
		// procura o codigo de barras no cadastro de SKU/item
		dbSelectArea("Z32")
		Z32->(dbSetOrder(2)) // 2-Z32_FILIAL, Z32_CODBAR, Z32_CODPRO
		Z32->(dbSeek( xFilial("Z32") + mvChvPesq ))
		// varre todos os registros com o mesmo codigo de barras, e valida cliente
		While Z32->( ! Eof() ) .And. (Z32->Z32_FILIAL == xFilial("Z32")) .And. (AllTrim(Z32->Z32_CODBAR) == AllTrim(mvChvPesq))

			// posiciona no cadastro do produto, para comparar a sigla do cliente
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
			SB1->(dbSeek( xFilial("SB1") + Z32->Z32_CODPRO ))

			// compara sigla com grupo
			If (SB1->B1_GRUPO == _cSiglaCli)
				// informa quantidade manual
				mvInfQtd   := (SB1->(FieldPos("B1_ZINFQTD"))>0) .And. (SB1->B1_ZINFQTD=="S")
				// informa número de série
				mvNumSerie := (SB1->(FieldPos("B1_ZNUMSER"))>0) .And. (SB1->B1_ZNUMSER=="S")
				// atualiza codigo do produto
				mvCodProd  := SB1->B1_COD
				// atualiza num seq de retorno
				mvNumSeq   := ""
				//atualiza quantidade conforme informado no cadastro do codigo de barras
				mvQuant    := Z32->Z32_QUANT
				// nao pesquisa mais
				_lNovaPesq := .F.
				// sai do Loop
				Exit
			EndIf

			// proximo item
			Z32->(dbSkip())
		EndDo
	EndIf

	// pesquisa o codigo do produto pelo EAN / CODE128 / DUN14 na tabela de produtos padrão (SB1)
	If (_lEncontrou) .And. (_lNovaPesq) .And. ((_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIdDUN) )
		// cad. de produto
		dbSelectArea("SB1")
		SB1->(dbSetOrder(5)) // 5-B1_FILIAL, B1_CODBAR
		If ! SB1->(dbSeek( xFilial("SB1") + mvChvPesq ))
			// mensagem
			U_FtWmsMsg("Código de barras não encontrado","ATENCAO")
			// variavel de retorno
			_lEncontrou := .F.
		Else
			// informa quantidade manual
			mvInfQtd   := (SB1->(FieldPos("B1_ZINFQTD"))>0) .And. (SB1->B1_ZINFQTD=="S")
			// informa número de série
			mvNumSerie := (SB1->(FieldPos("B1_ZNUMSER"))>0) .And. (SB1->B1_ZNUMSER=="S")
			// atualiza codigo do produto
			mvCodProd  := SB1->B1_COD
			// atualiza num seq de retorno
			mvNumSeq   := ""
			// nao pesquisa mais
			_lNovaPesq := .F.
		EndIf
	EndIf

	// pesquisa o codigo interno do produto (b1_cod)
	If (_lEncontrou) .And. (_lNovaPesq) .And. (_lEtqCodInt)
		// cad. de produto
		dbSelectArea("SB1")
		SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
		If ! SB1->(dbSeek( xFilial("SB1") + mvChvPesq ))
			// mensagem
			U_FtWmsMsg("Produto não encontrado","ATENCAO")
			// variavel de retorno
			_lEncontrou := .F.
		Else
			// informa quantidade manual
			mvInfQtd   := (SB1->(FieldPos("B1_ZINFQTD"))>0) .And. (SB1->B1_ZINFQTD=="S")
			// informa número de série
			mvNumSerie := (SB1->(FieldPos("B1_ZNUMSER"))>0) .And. (SB1->B1_ZNUMSER=="S")
			// atualiza codigo do produto
			mvCodProd  := SB1->B1_COD
			// atualiza num seq de retorno
			mvNumSeq   := ""
			// nao pesquisa mais
			_lNovaPesq := .F.
		EndIf
	EndIf

	// pesquisa o codigo da etiqueta do cliente
	If (_lEncontrou) .And. (_lNovaPesq) .And. (_lEtqClient)

		// padroniza o tamanho da chave da pesquisa
		mvChvPesq := PadR(mvChvPesq, Len(Z56->Z56_ETQCLI))

		// procura o codigo da etiqueta do cliente / importado anteriormente
		dbSelectArea("Z56")
		Z56->( DbSetOrder(2) ) // 2-Z56_FILIAL, Z56_ETQCLI, Z56_CODCLI, Z56_LOJCLI
		If ( ! Z56->( DbSeek( _cSeekZ56 := xFilial("Z56") + mvChvPesq + mvCodCli )) )
			// mensagem
			U_FtWmsMsg("Identificador do produto não localizado!", "ATENCAO")
			// variavel de retorno
			_lEncontrou := .F.
		EndIf

		// varre todos os registros com o mesmo codigo de barras, e valida cliente
		While Z56->( ! Eof() ) .And. (_lEncontrou) .And. ((Z56->Z56_FILIAL + Z56->Z56_ETQCLI + Z56->Z56_CODCLI) == _cSeekZ56)

			// posiciona no cadastro do produto, para comparar a sigla do cliente
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
			If ( ! SB1->(dbSeek( xFilial("SB1") + Z56->Z56_CODPRO )) )
				// mensagem
				U_FtWmsMsg("Identificador do produto não localizado!", "ATENCAO")
				// variavel de retorno
				_lEncontrou := .F.
			EndIf

			// compara sigla com grupo
			If (_lEncontrou) .And. (SB1->B1_GRUPO == _cSiglaCli)
				// informa quantidade manual
				mvInfQtd   := (SB1->(FieldPos("B1_ZINFQTD"))>0) .And. (SB1->B1_ZINFQTD=="S")
				// informa número de série
				mvNumSerie := (SB1->(FieldPos("B1_ZNUMSER"))>0) .And. (SB1->B1_ZNUMSER=="S")
				// atualiza codigo do produto
				mvCodProd  := SB1->B1_COD
				// atualiza num seq de retorno
				mvNumSeq   := ""
				// atualiza quantidade conforme informado na relacao de etiquetas
				mvQuant    := Z56->Z56_QUANT
				// nao pesquisa mais
				_lNovaPesq := .F.

				// posiciona no registro da etiqueta
				dbSelectArea("Z11")
				Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
				If ! Z11->(dbSeek( xFilial("Z11") + Z56->Z56_CODETI ))
					// mensagem
					U_FtWmsMsg("Identificador do produto não localizado!", "ATENCAO")
					// variavel de retorno
					_lEncontrou := .F.
				EndIf

				// sai do Loop
				Exit
			EndIf

			// proximo item
			Z32->(dbSkip())
		EndDo
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni)

Return(_lEncontrou)

// ** funcao para definir o motivo de interrupcao
User Function FtWmsMtInt(mvNumOS, mvSeqOS, mvMotInt)

	local _aHeadMotInt := {}
	local _aSizeCols := {}
	local _cQuery := ""
	local _aAreaZ06 := Z06->( GetArea() )

	local _lRet := .F.

	// fontes utilizadas
	Local oFntBrowse := TFont():New("Courier New",,14,,.F.)
	Private oFntProd := TFont():New("Tahoma",,20,,.T.)

	// browse
	private _aColsMotInt := {}

	// por padrão, o parâmetro é falso
	Default mvMotInt := ""

	// posiciona no item da OS
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	Z06->(dbSeek( xFilial("Z06") + mvNumOS + mvSeqOS ))

	// Se OS não estiver em execução (apta a interromper)
	If (Z06->Z06_STATUS != "EX")
		U_FtWmsMsg("A OS " + _cNumOrdSrv + " já foi interrompida ou finalizada por outro usuário. Fechando a tela!","ATENCAO")
		RestArea(_aAreaZ06)
		Return( .T. )   // retorna true pois, apesar de não ter efetuado a ação, a OS foi interrompida e o processo deve ser abortado
	EndIf

	// se for rotina automática (preenchendo o motivo da interrupção), chama direto a opção de gravação de motivo de interrupção
	If ( ! Empty(mvMotInt) )

		// chama opcao para confirma o motivo de interrupcao
		sfConfMotInt(@_lRet, mvNumOS, mvSeqOS, mvMotInt)

		// se deu algum problema, informa ao usuário
		If ( ! _lRet)
			// mensagem
			U_FtWmsMsg("Erro ao interromper OS. Avise o setor de TI")
			// retorno
			Return(.F.)
		Else
			// retorno
			Return(.T.)
		EndIf

	EndIf

	// abre/cria tabela de motivos de interrupcoes
	dbSelectArea("Z10")

	// monta a query
	_cQuery := "SELECT "
	// controle de recno e item deletado
	_cQuery += "Z10_CODIGO, Z10_DESCRI, Z10.R_E_C_N_O_ Z10RECNO, '.F.' IT_DEL "
	// cad. de enderecos
	_cQuery += "FROM "+RetSqlName("Z10")+" Z10 (nolock)  "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z10")+" "
	// ordem dos dados
	_cQuery += "ORDER BY Z10_DESCRI"

	// adiciona o conteudo da query para um array
	_aColsMotInt := U_SqlToVet(_cQuery)

	memowrit("c:\query\twmsa010_sfDefMotInt.txt",_cQuery)

	// define todos os campos do header
	aAdd(_aHeadMotInt,{"Código"    ,"Z10_CODIGO" ,"" ,TamSx3("Z10_CODIGO")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadMotInt,{"Descrição" ,"Z10_DESCRI" ,"" ,TamSx3("Z10_DESCRI")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadMotInt,{"Recno"     ,"Z10RECNO"   ,"" ,10                     ,0,Nil,Nil,"N",Nil,"R",,,".F." })

	// monta o dialogo do monitor
	_oWndDefMotInt := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Motivo Interrupção",,,.F.,,,,,,.T.,,,.T. )
	_oWndDefMotInt:lEscClose := .F.

	// cria o panel do cabecalho - botoes
	_oPnlMtIntCabec := TPanel():New(000,000,nil,_oWndDefMotInt,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlMtIntCabec:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpMotIntOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| sfConfMotInt(@_lRet, mvNumOS, mvSeqOS) },_oPnlMtIntCabec,"Ok",,.T.)
	_oBmpMotIntOk:Align := CONTROL_ALIGN_LEFT

	// monta o browse com os motivos de interrupcoes
	_oBrwDefMotInt := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsMotInt),'AllwaysTrue()','','AllwaysTrue()',_oWndDefMotInt,_aHeadMotInt,_aColsMotInt)
	_oBrwDefMotInt:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa o dialogo
	_oWndDefMotInt:Activate(,,,.F.,{|| _lRet },,)

Return

// ** funcao para confirmar a definicao da doca
Static Function sfConfMotInt(mvRet, mvNumOS, mvSeqOS, mvMotInt)
	// retorna o RECNO
	local _nRecnoZ10 := 0
	// area inicial
	local _aAreaZ06 := Z06->(GetArea())
	local _aAreaZ05 := Z05->(GetArea())

	// valor padrao
	Default mvRet := .T.

	// verifica se o motivo de interrupcao veio por parametro
	If ( ! Empty(mvMotInt))
		// posiciono no registro do recno do motivo da interrupção
		dbSelectArea("Z10")
		Z10->( dbSetOrder(1) ) //FILIAL+CODIGO
		If ( Z10->( dbSeek( xFilial("Z10")+mvMotInt) ) )
			_nRecnoZ10 := Recno()
		EndIf
	Else
		// recno da rotina padrão
		_nRecnoZ10 := _oBrwDefMotInt:aCols[_oBrwDefMotInt:nAt][Len(_oBrwDefMotInt:aHeader)]
	EndIf

	// se nao tem motivo de interrupcao selecionado
	If (_nRecnoZ10==0)
		// variavel de controle
		mvRet := .F.
		// retorno
		Return(mvRet)
	EndIf

	// posiciono no registro do motivo
	dbSelectArea("Z10")
	Z10->(dbGoTo(_nRecnoZ10))

	// posiciona na OS
	dbSelectArea("Z05")
	Z05->(dbSetOrder(1)) // 1-Z05_FILIAL, Z05_NUMOS
	Z05->(dbSeek( xFilial("Z05") + mvNumOS ))

	// posiciona nos itens da OS
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	Z06->(dbSeek( xFilial("Z06") + mvNumOS + mvSeqOS ))

	// atualiza o status do servico para EX-EM EXEUCAO / IN-INTERROMPIDO
	If ! U_FtWmsSta(Z06->Z06_STATUS, "IN", mvNumOS, mvSeqOS)
		// variavel de controle
		mvRet := .F.
		// retorno
		Return(mvRet)
	EndIf

	// inclui o motivo de interrupcao da OS
	dbSelectArea("Z09")
	RecLock("Z09",.T.)
	Z09->Z09_FILIAL	:= xFilial("Z09")
	Z09->Z09_CESV	:= Z05->Z05_CESV
	Z09->Z09_NUMOS	:= mvNumOS
	Z09->Z09_SEQOS	:= mvSeqOS
	Z09->Z09_DTINI	:= Date()
	Z09->Z09_HRINI	:= Time()
	Z09->Z09_MOTIVO	:= Z10->Z10_CODIGO
	Z09->Z09_USRINC	:= _cCodOper
	MsUnLock()

	// restaura area inicial
	RestArea(_aAreaZ05)
	RestArea(_aAreaZ06)

	// variavel de retorno
	mvRet := .T.

	// fecha tela
	If (Empty(mvMotInt))
		_oWndDefMotInt:End()
	EndIf

Return(mvRet)

// ** funcao para retomar a interrupcao de um servico
User Function FtRetSvInt(mvNumOS, mvSeqOS)
	local _lRet := .F.
	// controle do seek
	local _cSeekZ09

	// pesquisa o motivo de interrupcao da OS
	dbSelectArea("Z09")
	Z09->(dbSetOrder(2)) // 2-Z09_FILIAL, Z09_NUMOS, Z09_SEQOS
	Z09->(dbSeek( _cSeekZ09 := xFilial("Z09")+mvNumOS+mvSeqOS ))
	While Z09->(!Eof()) .And. (Z09->(Z09_FILIAL+Z09_NUMOS+Z09_SEQOS)==_cSeekZ09)
		// testa data de finalizacao
		If (Empty(Z09->Z09_DTFIM))
			RecLock("Z09")
			Z09->Z09_DTFIM := Date()
			Z09->Z09_HRFIM := Time()
			MsUnLock()
			// atualiza variavel de retorno
			_lRet := .T.
		EndIf
		// proximo item
		Z09->(dbSkip())
	EndDo

Return(_lRet)

// ** 8. funcao responsavel pela definicao dos servicos na nota de entrada
// ** verifica tambem o cadastro complementar do produtos (SB5)
User Function FtWmsSd1()
	Local aAreaSb1 := SB1->(GetArea())
	Local aAreaSb5 := SB5->(GetArea())
	// posicao dos campos
	Local nPosServ := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_SERVIC"}) // codigo do servico
	Local nPosEnder := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_ENDER"}) // endereco
	Local nPosTpEst := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_TPESTR"}) // tipo de estrutura
	Local nPosCodProd := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_COD"}) // codigo do produto
	Local nPosTes := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_TES"}) // codigo da TES
	// variavel de retorno (pode ser logico ou o codigo do servico)
	Local cRtCodServ := CriaVar("D1_SERVIC",.F.)
	// classificacao de pre-nota
	Local lRetCodServ := .F.
	// item do acols (pode ser N ou Len(aCols)
	Local nTmpIt := If(AllTrim(ReadVar())$"M->D1_TES/M->D1_COD", N, Len(aCols))
	// codigo do produto
	Local cCodProd := aCols[nTmpIt,nPosCodProd]
	// variavel temporaria
	Local nX := 1

	// verifica se esta sendo chamada pela Pre-Nota
	While .T.
		If Empty(ProcName(nX))
			Exit
		EndIf
		// se for execucacao de gatilhos
		If ("RUNTRIGGER"$Upper(ProcName(nX)))
			lRetCodServ := .T.
		EndIf

		If ("MATA140"$Upper(ProcName(nX)))
			Return(.T.)
		EndIF
		// contador
		nX++
	EndDo

	// posiciona no cadastro de produto
	If (AllTrim(cCodProd)<>AllTrim(SB1->B1_COD))
		dbSelectArea("SB1")
		SB1->(dbSetOrder(1))
		SB1->(dbSeek( xFilial("SB1")+cCodProd ))
	EndIf

	// verifica se tem a necessidade de gerar o servico de entrada
	If (GetMv("MV_INTDL")=="S") .And. (cTipo=="N") .And. (SB1->B1_LINHA<="501") .And. (Posicione("SF4",1,xFilial("SF4")+aCols[nTmpIt,nPosTes],"F4_ESTOQUE")=="S")
		// valida informacoes complementares do produto (PE apos a inclusao do Produto)
		U_MATA010(.T.)
		// codigo do servico
		cRtCodServ := Posicione("SB5",1, xFilial("SB5")+SB1->B1_COD ,"B5_SERVENT")
		// atualiza os dados dos servicos no item
		aCols[nTmpIt,nPosServ]	:= cRtCodServ
		aCols[nTmpIt,nPosEnder]	:= PadR("DOCA",Len(SD1->D1_ENDER))
		aCols[nTmpIt,nPosTpEst]	:= "000001"
	EndIf

	// restaura area inicial
	RestArea(aAreaSb5)
	RestArea(aAreaSb1)

Return(If(lRetCodServ,cRtCodServ,.T.))

// ** 9. Funcao que calcula o saldo previsto em servicos de Radio frequencia para o endereco
User Function ConSldRF(mvLocal, mvEndereco, mvProduto, mvSaldoSBF)
	// area inicial
	local _aArea := GetArea()
	// query
	local _cQrySaldo

	Default mvProduto := ""

	_cQrySaldo := "SELECT SUM(ISNULL(Z08_QUANT,0)) IT_SALDO "
	_cQrySaldo += "FROM "+RetSqlName("Z08")+" Z08 (nolock)  "
	_cQrySaldo += "WHERE "+RetSqlCond("Z08")+" "
	_cQrySaldo += "AND Z08_LOCAL   = '"+mvLocal+"' "
	_cQrySaldo += "AND Z08_ENDDES  = '"+mvEndereco+"' "
	_cQrySaldo += "AND Z08_STATUS != 'R' " // P-Planejado / R-Realizado / M-Movimento / E-Erro
	If (!Empty(mvProduto))
		_cQrySaldo += "AND Z08_PRODUT = '"+mvProduto+"' "
	EndIf
	// executa a query
	mvSaldoSBF += U_FtQuery(_cQrySaldo)

	// restaura area inicial
	RestArea(_aArea)

Return(mvSaldoSBF)

// ** funcao para gerar etiquetas
User Function FtGrvEtq(mvTipo, mvConteudo)
	// controle de numeracao de etiqueta
	local _cTmpCodEtq := GetSxENum("Z11","Z11_CODETI", xFilial("Z11") )

	If (mvTipo == "01") // 01 - PRODUTO
		dbSelectArea("Z11")
		RecLock('Z11',.T.)
		Z11->Z11_FILIAL := xFilial("Z11")
		Z11->Z11_FILORI := cFilAnt
		Z11->Z11_CODETI := _cTmpCodEtq
		Z11->Z11_DTNASC := Date()
		Z11->Z11_HRNASC := Time()
		Z11->Z11_USRINC	:= __cUserId
		Z11->Z11_TIPO   := mvTipo
		Z11->Z11_CLIENT	:= mvConteudo[ 1]
		Z11->Z11_LOJA	:= mvConteudo[ 2]
		Z11->Z11_TIPONF	:= mvConteudo[ 3]
		Z11->Z11_DOC	:= mvConteudo[ 4]
		Z11->Z11_SERIE	:= mvConteudo[ 5]
		Z11->Z11_ITEMNF	:= mvConteudo[ 6]
		Z11->Z11_CODPRO	:= mvConteudo[ 7]
		Z11->Z11_NUMSEQ	:= mvConteudo[ 8]
		Z11->Z11_PROCES	:= mvConteudo[ 9]
		Z11->Z11_CESV	:= mvConteudo[10]
		Z11->Z11_QTD1	:= mvConteudo[11]
		Z11->Z11_QTD2	:= mvConteudo[12]
		Z11->Z11_CARGA  := If(Len(mvConteudo)>=13,mvConteudo[13],"")
		Z11->(MsUnLock())

	ElseIf (mvTipo == "02") // 02 - ENDERECO/LOCALIZACAO
		dbSelectArea("Z11")
		RecLock('Z11',.T.)
		Z11->Z11_FILIAL := xFilial("Z11")
		Z11->Z11_FILORI := cFilAnt
		Z11->Z11_CODETI := _cTmpCodEtq
		Z11->Z11_DTNASC := Date()
		Z11->Z11_HRNASC := Time()
		Z11->Z11_USRINC	:= __cUserId
		Z11->Z11_TIPO   := mvTipo
		Z11->Z11_LOCAL	:= mvConteudo[1]
		Z11->Z11_ENDERE	:= mvConteudo[2]
		Z11->(MsUnLock())

	ElseIf (mvTipo == "03") // 03 - PALETE
		dbSelectArea("Z11")
		RecLock('Z11',.T.)
		Z11->Z11_FILIAL := xFilial("Z11")
		Z11->Z11_FILORI := cFilAnt
		Z11->Z11_CODETI := _cTmpCodEtq
		Z11->Z11_DTNASC := Date()
		Z11->Z11_HRNASC := Time()
		Z11->Z11_USRINC	:= __cUserId
		Z11->Z11_TIPO   := mvTipo
		Z11->Z11_UNITIZ	:= mvConteudo[1]
		Z11->Z11_CARGA  := If(Len(mvConteudo)>=2,mvConteudo[2],"")
		Z11->(MsUnLock())

	ElseIf (mvTipo == "04") // 04 - VOLUME
		dbSelectArea("Z11")
		RecLock('Z11',.T.)
		Z11->Z11_FILIAL := xFilial("Z11")
		Z11->Z11_FILORI := cFilAnt
		Z11->Z11_CODETI := _cTmpCodEtq
		Z11->Z11_DTNASC := Date()
		Z11->Z11_HRNASC := Time()
		Z11->Z11_USRINC	:= __cUserId
		Z11->Z11_TIPO   := mvTipo
		Z11->Z11_CLIENT	:= mvConteudo[ 1]
		Z11->Z11_LOJA	:= mvConteudo[ 2]
		Z11->Z11_PROCES	:= mvConteudo[ 3]
		Z11->Z11_CESV	:= mvConteudo[ 4]
		Z11->Z11_DOC    := mvConteudo[ 5]
		Z11->Z11_SERIE  := mvConteudo[ 6]
		Z11->Z11_TIPONF := mvConteudo[ 7]
		Z11->Z11_ITEMNF	:= mvConteudo[ 8]
		Z11->Z11_CODPRO	:= mvConteudo[ 9]
		Z11->Z11_NUMSEQ	:= mvConteudo[10]
		Z11->Z11_SEQKIT	:= mvConteudo[11]
		Z11->Z11_CODKIT	:= mvConteudo[12]
		Z11->Z11_QTD1	:= mvConteudo[13]
		Z11->Z11_QTD2	:= mvConteudo[14]
		Z11->(MsUnLock())

	ElseIf (mvTipo == "06") // 06 - TRANSPORTADORA
		dbSelectArea("Z11")
		RecLock('Z11',.T.)
		Z11->Z11_FILIAL := xFilial("Z11")
		Z11->Z11_FILORI := cFilAnt
		Z11->Z11_CODETI := _cTmpCodEtq
		Z11->Z11_DTNASC := Date()
		Z11->Z11_HRNASC := Time()
		Z11->Z11_USRINC	:= __cUserId
		Z11->Z11_TIPO   := mvTipo
		Z11->Z11_CESV	:= mvConteudo[1]
		Z11->Z11_TRANSP	:= mvConteudo[2]
		Z11->Z11_MOTORI	:= mvConteudo[3]
		Z11->Z11_PLACA1	:= mvConteudo[4]
		Z11->Z11_PLACA2	:= mvConteudo[5]
		Z11->(MsUnLock())

	ElseIf (mvTipo == "07") // 07 - ETIQUETA DO CLIENTE

		// estrutura do vetor mvConteudo
		//  1 - Cod Cliente
		//  2 - Loja Cliente
		//  3 - Nf - Tipo
		//  4 - Nf - Numero
		//  5 - Nf - Serie
		//  6 - Nf - Item/Sequencia
		//  7 - Nf - Cod Produto/Item
		//  8 - Nf - NumSeq
		//  9 - Nf - Quantidade
		// 10 - Nf - Lote
		// 11 - Nf - Processo
		// 12 - Numero da Etiqueta

		dbSelectArea("Z11")
		RecLock('Z11', .T.)
		Z11->Z11_FILIAL := xFilial("Z11")
		Z11->Z11_FILORI := cFilAnt
		Z11->Z11_CODETI := _cTmpCodEtq
		Z11->Z11_DTNASC := Date()
		Z11->Z11_HRNASC := Time()
		Z11->Z11_USRINC := __cUserId
		Z11->Z11_TIPO   := mvTipo
		Z11->Z11_CLIENT := mvConteudo[ 1]
		Z11->Z11_LOJA   := mvConteudo[ 2]
		Z11->Z11_TIPONF := mvConteudo[ 3]
		Z11->Z11_DOC    := mvConteudo[ 4]
		Z11->Z11_SERIE  := mvConteudo[ 5]
		Z11->Z11_ITEMNF := mvConteudo[ 6]
		Z11->Z11_CODPRO := mvConteudo[ 7]
		Z11->Z11_NUMSEQ := mvConteudo[ 8]
		Z11->Z11_QUANT  := mvConteudo[ 9]
		Z11->Z11_LOTCTL := mvConteudo[10]
		Z11->Z11_PROCES := mvConteudo[11]
		Z11->Z11_ETIQUE := mvConteudo[12]
		Z11->(MsUnLock())

	EndIf

	// confirma sequencial
	ConfirmSX8()

Return(Z11->Z11_CODETI)

// ** funcao para copiar o registro do alias
User Function FtCopReg(mvAlias,mvCmpAlt)
	Local _aDados := {}
	Local _nX
	Local _nPos
	Local _cCmpTmp

	dbSelectArea(mvAlias)
	For _nX := 1 to FCount()
		// verifica se o conteudo foi passado como parametro
		_nPos := aScan(mvCmpAlt,{|x|AllTrim(x[1]) == (mvAlias)->(FieldName(_nX))})
		If (_nPos>0)
			aAdd(_aDados,{ (mvAlias)->(FieldName(_nX)),mvCmpAlt[_nPos,2] })
		Else
			aAdd(_aDados,{ (mvAlias)->(FieldName(_nX)),(mvAlias)->(FieldGet(_nX)) })
		EndIf
	Next _nX

	dbSelectArea(mvAlias)
	RecLock(mvAlias,.T.)
	For _nX := 1 to Len(_aDados)
		_cCmpTmp := _aDados[_nX,1]
		(mvAlias)->(&_cCmpTmp) := _aDados[_nX,2]
	Next _nX
	MsUnLock()

Return

// ** funcao que retorna as impressoras disponiveis
User Function FtRetImp(mvTipo)
	// conteudo do parametro
	local _cImpZebra := AllTrim(SuperGetMV("TC_WMSIMP1", .F., ""))
	local _aRetZebra := Separa(_cImpZebra,";")

	// conteudo do parametro
	local _cImpLaser := AllTrim(SuperGetMV("TC_WMSIMP2", .F., ""))
	local _aRetLaser := Separa(_cImpLaser,";")

	// retorno
	local _aRet := {}

	Default mvTipo := 1

	if (mvTipo == 1)  // tipo 1 = impressora zebra
		_aRet := Aclone(_aRetZebra)
	Else  // tipo 2 = impressora laser
		_aRet := Aclone(_aRetLaser)
	EndIf

Return(_aRet)

// ** funcao que controla impressora zebra selecionada
User Function FtImpZbr(mvPrnString)
	// sessao do arquivo INI
	local _cSession := GetPrinterSession()
	// variavel de retorno
	local _cRetImpres := ""
	// chave tecadi_zebra
	local _cIdChave := "tecadi_zebra"
	// valor padrao
	Default mvPrnString := ""

	// busca configuracoes
	If (Empty(mvPrnString))
		// impressora zebra
		_cRetImpres := fwGetProfString(_cSession, _cIdChave, "", .T.)
	EndIf

	// grava configuracoes
	If ( ! Empty(mvPrnString) )
		fwWriteProfString(_cSession, _cIdChave, mvPrnString, .T.)
	EndIf

Return(_cRetImpres)

// ** funcao para atualizar o status da OS
User Function FtWmsSta(mvStsAtu, mvStsNew, mvNumOs, mvSeqOs)
	// area inicial
	local _aAreaZ05 := Z05->(GetArea())
	local _aAreaZ06 := Z06->(GetArea())
	local _aAreaSZZ := SZZ->(GetArea())
	// variavel de retorno
	local _lRet := .T.

	// posiciona na OS
	dbSelectArea("Z05")
	Z05->(dbSetOrder(1)) // 1-Z05_FILIAL, Z05_NUMOS
	Z05->(dbSeek( xFilial("Z05")+mvNumOs ))

	// posiciona no item da OS
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	Z06->(dbSeek( xFilial("Z06") + mvNumOs + mvSeqOs ))

	// valida status, verificando casos que a tela de usuarios esta aberta
	If (_lRet) .And. (mvStsAtu != Z06->Z06_STATUS)
		// mensagem
		U_FtWmsMsg("Falha na tentativa de alteração do Status da Ordem de Serviço: " + mvNumOs + " Seq: " + mvSeqOs + " (TabAtual/ParAtual " + Z06->Z06_STATUS + " -> " + mvStsAtu + ")", "ATENCAO")
		// variavel de controle
		_lRet := .F.
	EndIf

	// valida status, verificando casos que a tela de usuarios esta aberta
	If (_lRet) .And. (mvStsNew == Z06->Z06_STATUS)
		// mensagem
		U_FtWmsMsg("Falha na tentativa de alteração do Status da Ordem de Serviço: " + mvNumOs + " Seq: " + mvSeqOs + " (TabAtual/ParNovo " + Z06->Z06_STATUS + " -> " + mvStsAtu + ")", "ATENCAO")
		// variavel de controle
		_lRet := .F.
	EndIf

	// valida casos onde está senod feito a tarefa de montagem de volumes simultaneamente, e outro usuario já encerrou a sequencia
	If (_lRet) .And. (mvStsNew == "IN") .And. (mvStsAtu == 'FI')
		// mensagem
		U_FtWmsMsg("A OS " + mvNumOs + "/" + mvSeqOs + " já está finalizada! Verifique se outro usuário está realizando junto com você. Abortando!", "ATENCAO")
		// variavel de controle
		_lRet := .F.
	EndIf

	// se validacao ok, atualiza
	If (_lRet)

		// gera log da alteracao de status
		U_FtGeraLog(cFilAnt, "Z06", Z06->Z06_FILIAL + Z06->Z06_NUMOS + Z06->Z06_SEQOS, "Alteração de Status da Operação: De "+Z06->Z06_STATUS+" -> "+mvStsNew+" (mvStsAtu "+mvStsAtu+")", "WMS")

		// atualiza campos
		RecLock("Z06")
		If Z06->(FieldPos("Z06_STATAN")) <> 0
			Z06->Z06_STATAN := Z06->Z06_STATUS //Guarda o status anterior.
		EndIf
		Z06->Z06_STATUS	:= mvStsNew

		// iniciar OS - AG para EX
		If (mvStsAtu=="AG") .And. (mvStsNew=="EX")
			Z06->Z06_DTINIC	:= date()
			Z06->Z06_HRINIC	:= time()

			// inclui o recursos automaticamente
			U_FtRecuOS(mvNumOs, mvSeqOs, _cCodOper, _cCodOper)

			// se for o servico de chek-list, altera o status da entrada de veiculo
			If (Z06->Z06_SERVIC=="T01") .And. (Z06->Z06_TAREFA=="005")
				// posiciona sobre o CESV
				dbSelectArea("SZZ")
				SZZ->(dbSetOrder(1)) // 1-ZZ_FILIAL, ZZ_CESV
				SZZ->(dbSeek( xFilial("SZZ")+Z05->Z05_CESV ))
				RecLock("SZZ")
				SZZ->ZZ_STATUS := "04" // 04-EM INSPECAO
				SZZ->(MsUnLock())
			EndIf

			// iniciar OS - IN para EX
		ElseIf (mvStsAtu=="IN")  .And. (mvStsNew=="EX")
			// retoma OS interrompida
			U_FtRetSvInt(Z06->Z06_NUMOS, Z06->Z06_SEQOS)

			// iniciar OS - AG para EX
		ElseIf (mvStsAtu=="EX") .And. (mvStsNew=="FI")
			// data e hora da finalizacao
			Z06->Z06_DTFIM	:= date()
			Z06->Z06_HRFIM	:= time()
			Z06->Z06_USRFIM	:= _cCodOper

			// finaliza OS Bloqueada - BL para FI
		ElseIf (mvStsAtu=="BL") .And. (mvStsNew=="FI")
			// data e hora da finalizacao
			Z06->Z06_DTFIM	:= date()
			Z06->Z06_HRFIM	:= time()
			Z06->Z06_USRFIM	:= _cCodOper

			// reabrir OS - FI para EX
		ElseIf (mvStsAtu=="FI") .And. (mvStsNew=="EX")
			// limpa data, hora e usuario da finalizacao
			Z06->Z06_DTFIM  := CtoD("//") // sem data
			Z06->Z06_HRFIM  := ""         // sem hora
			Z06->Z06_USRFIM := ""         // sem usuário

			// opcao de cancelamento de servico
		ElseIf (mvStsAtu != "FI") .And. (mvStsNew == "CA")
			// data e hora de cancelamento
			Z06->Z06_DTFIM	:= date()
			Z06->Z06_HRFIM	:= time()
			Z06->Z06_USRFIM	:= _cCodOper
			// AN para FI, geralmente pre conferência de recebimento Midea
		ElseIf (mvStsAtu == "AN") .And. (mvStsNew == "FI")
			// data e hora de cancelamento
			Z06->Z06_DTFIM	:= date()
			Z06->Z06_HRFIM	:= time()
			Z06->Z06_USRFIM	:= __cUserId

		EndIf

		// confirma gravacao
		Z06->(MsUnLock())
	EndIf

	// restaura area inicial
	RestArea(_aAreaSZZ)
	RestArea(_aAreaZ06)
	RestArea(_aAreaZ05)

Return(_lRet)

// ** funcao generica que inclui o recurso na OS
User Function FtRecuOS(mvNumOs, mvSeqOs, mvUsuario, mvCodOper)
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z18"})
	// seek
	local _cSeekZ18
	// controla se deve incluir o recurso
	local _lIncRecurso := .T.

	dbSelectArea("Z18")
	Z18->(dbSetOrder(1)) // 1-Z18_FILIAL, Z18_NUMOS, Z18_SEQOS
	Z18->(dbSeek( _cSeekZ18 := xFilial("Z18")+mvNumOs+mvSeqOs ))
	While Z18->(!Eof()) .And. (Z18->(Z18_FILIAL+Z18_NUMOS+Z18_SEQOS) == _cSeekZ18)
		// verifica se o operador ja esta vinculado a OS
		If (Z18->Z18_OPERAD == mvCodOper)
			_lIncRecurso := .F.
			Exit
		EndIf
		// proximo item
		Z18->(dbSkip())
	EndDo

	If (_lIncRecurso)
		RecLock("Z18",.T.)
		Z18->Z18_FILIAL := xFilial("Z18")
		Z18->Z18_NUMOS  := mvNumOs
		Z18->Z18_SEQOS  := mvSeqOs
		Z18->Z18_USUARI := mvUsuario
		Z18->Z18_OPERAD := mvCodOper
		Z18->Z18_CATEG  := _aUsrInfo[2]
		Z18->Z18_STATUS := "R" // P=Planejado / R=Realizado / B=Bloqueado
		Z18->(MsUnLock())
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni)
	RestArea(_aArea)

Return

// ** funcao para apresentar mensagem emitindo beep
User Function FtWmsMsg(mvMensagem, mvTitulo, mvBeep, mvAtivTimer, mvTamFonte)
	// objetos da tela
	Local _oDlgMsg, _oTexto, _oBtnOk
	Local _oTimer
	// fonte
	local _oFnt01 := Nil
	// define tempo do timer (milisegundos)
	Local _nTimeOut := (20 * 1000)

	// valores padroes
	Default mvMensagem  := "** ERRO **"
	Default mvTitulo    := "ATENCAO"
	Default mvBeep      := .F.
	Default mvAtivTimer := .F.
	Default mvTamFonte  := 1

	// define a fonte
	_oFnt01 := TFont():New("Tahoma",,(13+mvTamFonte),,.T.)

	// monta dialogo
	DEFINE MSDIALOG _oDlgMsg FROM 020,020 TO 240,200 TITLE OemToAnsi(mvTitulo) PIXEL

	@ 003, 004 TO 027,087 LABEL "Help" OF _oDlgMsg PIXEL
	@ 010, 008 MSGET OemToAnsi(mvTitulo) WHEN .F. SIZE 076,010 OF _oDlgMsg PIXEL

	@ 030, 004 TO 090, 087 OF _oDlgMsg PIXEL
	_oTexto := tMultiget():New(035, 008, {|u|IIf(pCount()>0, mvMensagem := u, mvMensagem)}, _oDlgMsg, 076, 049, _oFnt01, , , , , .T.,,,,,,.T.)

	// cria uma timer para fechar a tela
	If (mvAtivTimer)
		// cria timer
		_oTimer:= TTimer():New(_nTimeOut, {|| _oDlgMsg:End() }, _oDlgMsg)
		// ativa timer
		_oTimer:Activate()
	EndIf

	_oBtnOk := tButton():New(094,058, "Ok", _oDlgMsg, {|| _oDlgMsg:End()},,,,,,.T.)
	_oTexto:SetFocus()

	ACTIVATE MSDIALOG _oDlgMsg

Return(Nil)

// ** funcao generica que organiza o endereco de acordo com a configuracao
User Function FtCfgEnd(mvEndereco,mvArmazem)
	Local aAreaAnt   := GetArea()
	Local aAreaSBE   := SBE->(GetArea())
	Local aAreaDC7   := DC7->(GetArea())
	Local aEndereco  := {}
	Local aNiveis    := {}
	Local nX         := 1
	Local nNivAtu    := 1
	Local nParNivIni := SuperGetMV('MV_ENDINRF', .F., 0)
	Local nParNivFim := SuperGetMV('MV_ENDFIRF', .F., 0)
	Local nLenDesc   := 0
	Local nLenEnd    := 0
	Local cSeekDC7   := ''
	Local lCfgEnd    := .F.
	local nNivIni := 0
	local nNivFim := 0

	// -- Considera o Parametro MV_ENDINRF
	nNivIni := If(nParNivIni>0, nParNivIni, nParNivIni)
	// -- Considera o Parametro MV_ENDINRF
	nNivFim := If(nParNivFim>0, nParNivFim, nNivFim)

	dbSelectArea('DC7')
	dbSetOrder(1)

	dbSelectArea('SBE')
	dbSetOrder(1)

	If	(lCfgEnd:=(MsSeek(xFilial('SBE') + mvArmazem + mvEndereco, .F.) .And. ! Empty(SBE->BE_CODCFG) .And. DC7->(MsSeek( cSeekDC7 := xFilial('DC7') + SBE->BE_CODCFG, .F.))))
		nX      := 1
		nNivAtu := 1
		dbSelectArea('DC7')
		Do While DC7->( ! Eof() ) .And. cSeekDC7 == DC7->DC7_FILIAL + DC7->DC7_CODCFG
			If ((nNivIni+nNivFim)==0) .Or. ((nNivIni>0.And.nNivFim>0) .And. (nNivAtu>=nNivIni.And.nNivAtu<=nNivFim))
				aAdd(aNiveis, {AllTrim(DC7->DC7_DESEND), AllTrim(SubStr(mvEndereco, nX, DC7->DC7_POSIC))})
			EndIf
			nX      += DC7_POSIC
			nNivAtu ++
			dbSkip()
		EndDo
		nLenDesc := 0
		nLenEnd  := 0
		For nX := 1 to Len(aNiveis)
			nLenEnd := If(Len(aNiveis[nX, 2])>nLenEnd, Len(aNiveis[nX, 2]), nLenEnd)
		Next nX
		nLenDesc := (27-nLenEnd)
		For nX := 1 to Len(aNiveis)
			aAdd(aEndereco,{PadR(aNiveis[nX, 1], nLenDesc) + ' ' + PadR(aNiveis[nX, 2], nLenEnd),.F.})
		Next nX
	Else
		aAdd(aEndereco, {AllTrim(mvEndereco),.F.})
	EndIf

	// restaura area inicial
	RestArea(aAreaDC7)
	RestArea(aAreaSBE)
	RestArea(aAreaAnt)

Return(aEndereco)

// ** funcao generica para consulta/alterar status do palete
User Function FtEndPlt(mvIdPalete, mvEndAtu, mvNewEnd, mvArmzAtu, mvCodProd, mvSaldo, mvArmzDest)
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SBE","SBF"})
	// variavel de retorno
	local _lRet := .T.
	local _cQryZ16
	// dados temporarios
	local _aTmpDados := {}
	// saldo do SBF
	Default mvSaldo := 0
	// armazem destino
	Default mvArmzDest := mvArmzAtu

	// se for consulta
	If (mvNewEnd == Nil)
		// monta query
		_cQryZ16 := "SELECT DISTINCT Z16_ENDATU, Z16_LOCAL, Z16_CODPRO, SUM(Z16_SALDO) Z16_SALDO "
		// composicao do palete
		_cQryZ16 += " FROM " + RetSqlTab("Z16") + " (nolock) "
		// filtro padrao
		_cQryZ16 += " WHERE " + RetSqlCond("Z16")
		// numero do palete
		_cQryZ16 += " AND Z16_ETQPAL = '" + mvIdPalete + "' "
		// com saldo
		_cQryZ16 += " AND Z16_SALDO > 0 "
		// agrupa por endereço e produto
		_cQryZ16 += " GROUP BY  Z16_ENDATU, Z16_LOCAL, Z16_CODPRO"

		// atualiza variavel temporaria
		_aTmpDados := U_SqlToVet(_cQryZ16)

		// atualiza variaveis de retorno
		If (Len(_aTmpDados) > 0)
			// endereco
			mvEndAtu  := _aTmpDados[1][1]
			// armazem
			mvArmzAtu := _aTmpDados[1][2]
			// produto
			mvCodProd := _aTmpDados[1][3]
			// saldo
			mvSaldo   := _aTmpDados[1][4]

			// posiciona no cadastro do endereco
			dbSelectArea("SBE")
			SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
			If ! SBE->(dbSeek( xFilial("SBE")+mvArmzAtu+mvEndAtu ))
				_lRet := .F.
			EndIf

			// posiciono na DC8 pra validar qual o tipo de endereço
			dbSelectArea("DC8")
			DC8->(dbSetOrder(1)) // DC8_FILIAL, DC8_CODEST, R_E_C_N_O_, D_E_L_E_T_
			If ! DC8->(dbSeek( xFilial("DC8")+SBE->BE_ESTFIS ))
				_lRet := .F.
			EndIf

			/* Retornos da DC8
			1	PORTA PALETE A1
			1	ANALISE TECNICA
			2	PICKING
			4	MEZANINO A1
			4	NAO CONFORME
			4	TRANSF FILIAIS
			4	QUALIDADE
			4	BLOCADO A1 - CTBA
			5	DOCAS A1
			7	RUA/CORREDOR
			*/

			// verifica saldo do produto no endereco
			/*
			If (_lRet)

			// verifica o saldo do produto no endereco atual
			mvSaldo := SaldoSBF(SBE->BE_LOCAL,;
			SBE->BE_LOCALIZ,;
			mvCodProd,;
			NIL,;
			NIL,;
			NIL,;
			.F.,;
			SBE->BE_ESTFIS)

			// caso encontrou saldo e o saldo está em bloco ou docas/stage, mostra o saldo da Z16
			// ou endereço atual é rua
			If ( (mvSaldo > 0) .And. (DC8->DC8_TPESTR $ "4/5/7") ) .Or. (DC8->DC8_TPESTR == "7")
			mvSaldo := _aTmpDados[1][4]
			EndIf

			// tratamento do retorno, conforme saldo
			If (mvSaldo <= 0)
			_lRet := .F.
			EndIf

			EndIf
			*/

		EndIf

		// atualiza o novo endereco
	ElseIf ( ValType(mvNewEnd) == "C" ) .And. ( ValType(mvArmzAtu) == "C" ) .And. ( ValType(mvArmzDest) == "C" )
		_cQryZ16 := "UPDATE "+RetSqlName("Z16")+" "
		_cQryZ16 += "SET Z16_ENDATU = '"+mvNewEnd+"', Z16_LOCAL = '"+mvArmzDest+"' "
		// filtro padrao
		_cQryZ16 += "WHERE Z16_FILIAL = '"+xFilial("Z16")+"' AND D_E_L_E_T_ = ' ' "
		// numero do palete
		_cQryZ16 += "AND Z16_ETQPAL = '"+mvIdPalete+"' "
		// somente quando tiver saldo
		_cQryZ16 += "AND Z16_SALDO > 0 "
		// endereco atual
		_cQryZ16 += "AND Z16_ENDATU = '"+mvEndAtu+"' "
		// local/armazem atual
		_cQryZ16 += "AND Z16_LOCAL = '"+mvArmzAtu+"' "
		// executa o update
		TcSQLExec(_cQryZ16)
	Else
		U_FtWmsMsg("Armazém ou Endereço não definido! Verifique!")
		Return(.F.)
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni)
	RestArea(_aArea)

Return(_lRet)

// ** Função para calcular quantidade disponivel do SB6 (Quantidade SB6 - Quantidade reservada)
User Function FtSldSb6(mvIdentSB6,mvFornece,mvLoja,mvDoc,mvSerie,mvItem,mvProd,mvArmazem,mvTes)

	// Variaveis de retorno
	Local _aRet    := {}
	Local _nRet    := 0

	// Variavel ira quardar saldo da SB6
	Local _aSaldo  := 0

	// Area inicial
	Local _aAreaAtu := GetArea()
	Local _aAreaSC0 := SC0->(GetArea())
	Local _aAreaSD1 := SD1->(GetArea())
	Local _aAreaSF4 := SF4->(GetArea())

	// Variavel ira quardar quantidade Reservada.
	Local _nReserv := 0

	// variaveis usadas na funcao A410SNfOri
	Local _lForn   := .T.
	Local _lPoder3 := .T.

	// posiciona no item de entrada
	dbSelectArea("SD1")
	SD1->(dbSetOrder(1)) // 1-D1_FILIAL, D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_COD, D1_ITEM
	SD1->(dbSeek( xFilial("SD1")+mvDoc+mvSerie+mvFornece+mvLoja+mvProd+mvItem ))

	// pesquisa as reservas do produto
	dbSelectArea("SC0")
	SC0->(DbOrderNickName("SC0001")) // C0_FILIAL+C0_ZIDENT

	// Verifica se tem alguma reserva da nota especifica.
	If(SC0->(dbSeek( _cSeekSC0 := xFilial("SC0") + mvIdentSB6)))
		While SC0->(!Eof()) .And. (SC0->(C0_FILIAL+C0_ZIDENT) == _cSeekSC0 )

			// Soma quantidade total reservada.
			_nReserv += SC0->C0_QUANT

			// proximo item da reserva
			SC0->(dbSkip())
		EndDo
	EndIf

	// Cadastro de TES
	dbSelectArea("SF4")
	SF4->(dbSetOrder(1)) // 1-F4_FILIAL+F4_CODIGO
	SF4->(dbSeek( xFilial("SF4") + SD1->D1_TES ))

	// verifica o poder de terceiros
	_lPoder3 := ( SF4->F4_PODER3 == "R" )

	// calcula o Saldo da Nota Original informada.Calcula o Saldo do poder de terceiros.
	_aSaldo := A410SNfOri(mvFornece,;
	mvLoja,;
	mvDoc,;
	mvSerie,;
	IIf(_lPoder3,"",mvItem),;
	mvProd,;
	IIf(_lPoder3,mvIdentSB6,),;
	IIf(_lPoder3,mvArmazem,),;
	"SD1",,;
	IIf(_lForn,.F.,.T.))

	// Verifica saldo Real (Saldo SB6 (B6_SALDO - B6_QULIB) + Qtd Pedido) - Saldo Reservado
	_nRet := (_aSaldo[1] + _aSaldo[5]) - _nReserv

	//Retorno da Função
	//1 - Saldo Real (SB6 - Reservado)
	//2 - Saldo SB6
	//3 - Saldo Reservado
	_aRet := {_nRet,_aSaldo[1],_nReserv}

	//Restaura area inicial
	RestArea(_aAreaSF4)
	RestArea(_aAreaSD1)
	RestArea(_aAreaSC0)
	RestArea(_aAreaAtu)

Return(_aRet)

// ** funcao que retorna a validacao de parametros para WMS
User Function FtWmsParam(mvCodParam, mvTipoPar, mvRetPadr, mvMsgErro, mvCodFil, mvCodCli, mvLojCli, mvNrContra, mvNumOs)

	// variavel de retorno
	local _xVarRet

	// controle de Loop
	local _lOk := .F.

	// string da chave
	local _cCmpChave := ""
	local _cStrChave := ""
	local _nPosChave := 0

	// nivel de pesquisa
	local _nNivPesq

	// controle se redefine as configuracoes de pesquisa
	local _lDefCfg := .T.

	// indice para pesquisa
	local _cIndPesq

	// controle de diminui tamanho da chave de pesquisa
	local _lRedChvPsq := .F.

	// define valores default
	Default mvCodParam := CriaVar("Z30_PARAM",.F.)
	Default mvRetPadr  := ""
	Default mvMsgErro  := .T.
	Default mvCodFil   := CriaVar("A1_FILIAL",.F.)
	Default mvCodCli   := CriaVar("A1_COD",.F.)
	Default mvLojCli   := CriaVar("A1_LOJA",.F.)
	Default mvNrContra := CriaVar("AAM_CONTRT",.F.)
	Default mvNumOs    := CriaVar("Z05_NUMOS",.F.)

	// padroniza tamanho das variaveis
	private _xCodParam := PadR(mvCodParam, TamSx3("Z30_PARAM")[1] )
	private _xCodFil   := PadR(mvCodFil  , TamSx3("A1_FILIAL")[1] )
	private _xCodCli   := PadR(mvCodCli  , TamSx3("A1_COD")[1]    )
	private _xLojCli   := PadR(mvLojCli  , TamSx3("A1_LOJA")[1]   )
	private _xNrContra := PadR(mvNrContra, TamSx3("AAM_CONTRT")[1])
	private _xNumOs    := PadR(mvNumOs   , TamSx3("Z05_NUMOS")[1] )

	// nivel 4 - nr OS
	If ( ! Empty(_xNumOs) )
		_nNivPesq := 4

		// nivel 3 - nr contrato
	ElseIf ( ! Empty(_xNrContra) )
		_nNivPesq := 3

		// nivel 2 - cliente + loja
	ElseIf ( Empty(_xNumOs+_xNrContra) )
		_nNivPesq := 2

	EndIf

	// Loop para encontrar o conteudo conforme chave
	While ( ! _lOk )

		// define forma de pesquisa
		// 4-Parametro + Filial + Cod Cliente + Loja Cliente + Num OS
		// 3-Parametro + Filial + Cod Cliente + Loja Cliente + Num Contrato
		// 2-Parametro + Filial + Cod Cliente + Loja Cliente
		// 1-Parametro + Filial + Cod Cliente

		// condicao para pesquisa por NUM OS
		If (_nNivPesq == 4) .And. (_lDefCfg) .And. ( ! Empty(_xNumOs) )
			// composicao dos campos da tabela
			_cCmpChave := "Z30_PARAM+Z30_CODFIL+Z30_CODCLI+Z30_LOJCLI+Z30_NUMOS"
			// composicao da chave de pesquisa
			_cStrChave := "_xCodParam+_xCodFil+_xCodCli+_xLojCli+_xNumOs"
			// nick name do indice
			_cIndPesq  := "Z30_NUMOS" // 2-Z30_FILIAL, Z30_PARAM, Z30_CODFIL, Z30_CODCLI, Z30_LOJCLI, Z30_NUMOS
			// controle de diminui tamanho da chave de pesquisa
			_lRedChvPsq := .F.
			// controle se redefine as configuracoes de pesquisa
			_lDefCfg    := .F.

			// condicao para pesquisa por NUM CONTRATO
		ElseIf (_nNivPesq == 3) .And. (_lDefCfg) .And. ( ! Empty(_xNrContra) )
			// composicao dos campos da tabela
			_cCmpChave := "Z30_PARAM+Z30_CODFIL+Z30_CODCLI+Z30_LOJCLI+Z30_CONTRT"
			// composicao da chave de pesquisa
			_cStrChave := "_xCodParam+_xCodFil+_xCodCli+_xLojCli+_xNrContra"
			// nick name do indice
			_cIndPesq  := "Z30_CONTRT" // 3-Z30_FILIAL, Z30_PARAM, Z30_CODFIL, Z30_CODCLI, Z30_LOJCLI, Z30_CONTRT
			// controle de diminui tamanho da chave de pesquisa
			_lRedChvPsq := .F.
			// controle se redefine as configuracoes de pesquisa
			_lDefCfg    := .F.

			// condicao para pesquisa por CLIENTE + LOJA
		ElseIf (_nNivPesq == 2) .And. (_lDefCfg)
			// composicao dos campos da tabela
			_cCmpChave := "Z30_PARAM+Z30_CODFIL+Z30_CODCLI+Z30_LOJCLI"
			// composicao da chave de pesquisa
			_cStrChave := "_xCodParam+_xCodFil+_xCodCli+_xLojCli"
			// nick name do indice
			_cIndPesq  := "Z30_CODCLI" // 1-Z30_FILIAL, Z30_PARAM, Z30_CODFIL, Z30_CODCLI, Z30_LOJCLI
			// controle de diminui tamanho da chave de pesquisa
			_lRedChvPsq := .F.
			// controle se redefine as configuracoes de pesquisa
			_lDefCfg    := .F.

			// condicao para pesquisa por CLIENTE
		ElseIf (_nNivPesq == 1) .And. (_lDefCfg)
			// composicao dos campos da tabela
			_cCmpChave := "Z30_PARAM+Z30_CODFIL+Z30_CODCLI"
			// composicao da chave de pesquisa
			_cStrChave := "_xCodParam+_xCodFil+_xCodCli"
			// nick name do indice
			_cIndPesq  := "Z30_CODCLI" // 1-Z30_FILIAL, Z30_PARAM, Z30_CODFIL, Z30_CODCLI, Z30_LOJCLI
			// controle de diminui tamanho da chave de pesquisa
			_lRedChvPsq := .T.
			// controle se redefine as configuracoes de pesquisa
			_lDefCfg    := .F.

		EndIf

		// abre tabela de parametros do WMS
		dbSelectArea("Z30")
		Z30->(dbOrderNickName(_cIndPesq))
		If Z30->(dbSeek( xFilial("Z30") + (&(_cStrChave)) ))

			// varre todos os registros da mesma condicao
			While Z30->( ! Eof() ) .And. (Z30_FILIAL == xFilial("Z30")) .And. ( Z30->(&(_cCmpChave)) == (&(_cStrChave)) )

				// valida se a chave esta de acordo com a pesquisa
				If ((_nNivPesq == 4) .And. ( Z30->Z30_NUMOS == _xNumOs ));
				.Or.((_nNivPesq == 3) .And. ( Z30->Z30_CONTRT == _xNrContra ));
				.Or.((_nNivPesq == 2) .And. (Empty(Z30->(Z30_CONTRT + Z30_NUMOS))) .And. ( ! Empty(Z30->(Z30_LOJCLI)) ));
				.Or.((_nNivPesq == 1) .And. (Empty(Z30->(Z30_CONTRT + Z30_NUMOS))) .And. ( Empty(Z30->(Z30_LOJCLI)) ))

					// atualiza variavel de retorno
					If (mvTipoPar == "L")
						_xVarRet := (Upper(AllTrim(Z30->Z30_CONTEU))==".T.")
					ElseIf (mvTipoPar == "D")
						_xVarRet := CtoD(AllTrim(Z30->Z30_CONTEU))
					ElseIf (mvTipoPar == "C")
						_xVarRet := AllTrim(Z30->Z30_CONTEU)
					ElseIf (mvTipoPar == "N")
						_xVarRet := Val(AllTrim(Z30->Z30_CONTEU))
					EndIf

					// controle de loop
					_lOk := .T.
					// sai do loop
					Exit

				EndIf

				// proximo item
				Z30->(dbSkip())

			EndDo
		EndIf

		// verifica se diminui a chave de pesquisa
		If (_lRedChvPsq)
			// CHAVE VARIAVEL - retorna a posicao do separador (+)
			_nPosChave := RAT("+",_cStrChave)

			// se nao tem mais quebra, finaliza
			If (_nPosChave == 0)
				// sai do loop
				Exit
			EndIf

			// atualiza nova chave
			_cStrChave := SubStr(_cStrChave,1,_nPosChave-1)

			// CHAVE CAMPO TABELA Z30 - retorna a posicao do separador (+)
			_nPosChave := RAT("+",_cCmpChave)

			// se nao tem mais quebra, finaliza
			If (_nPosChave == 0)
				// sai do loop
				Exit
			EndIf

			// atualiza nova chave
			_cCmpChave := SubStr(_cCmpChave,1,_nPosChave-1)

			// muda formato de pesquisa
		ElseIf ( ! _lRedChvPsq )
			// proxima opcao de pesquisa
			_nNivPesq --
			// controle se redefine as configuracoes de pesquisa
			_lDefCfg  := .T.

		EndIf

		// se nao tem mais quebra, finaliza
		If (_nNivPesq == 0)
			// sai do loop
			Exit
		EndIf

	EndDo

	// trata retorno
	If ( ! _lOk)
		// verifica se mostra mensagem
		If (mvMsgErro)
			U_FtWmsMsg("Conteúdo do parâmetro "+AllTrim(mvCodParam)+" não definido!","ATENCAO")
		EndIf
		// conteudo padrao
		_xVarRet := mvRetPadr
	EndIf

Return(_xVarRet)

// ** funcao para apresentar mensagem emitindo beep
User Function FtYesNoMsg(mvMensagem, mvTitulo)

	Local _oDlgMsg, _oTexto, _oBtnOk, _oBtnNOk
	// variavel de retorno
	Local _lRet := .F.

	Default mvMensagem := "** ERRO **"
	Default mvTitulo   := "ATENCAO"

	DEFINE MSDIALOG _oDlgMsg FROM 020,020 TO 240,200 TITLE OemToAnsi(mvTitulo) PIXEL

	@ 003, 004 TO 027,087 LABEL "Help" OF _oDlgMsg PIXEL
	@ 010, 008 MSGET OemToAnsi(mvTitulo) WHEN .F. SIZE 076,010 OF _oDlgMsg PIXEL

	@ 030, 004 TO 090, 087 OF _oDlgMsg PIXEL
	@ 036, 008 GET _oTexto VAR OemToAnsi(mvMensagem) MEMO READONLY /*NO VSCROLL*/ SIZE 076, 050 OF _oDlgMsg PIXEL

	_oBtnOk  := tButton():New(094,004, "Sim", _oDlgMsg, {|| _lRet := .T., _oDlgMsg:End()},,,,,,.T.)
	_oBtnNOk := tButton():New(094,052, "Não", _oDlgMsg, {|| _oDlgMsg:End()},,,,,,.T.)
	_oBtnOk:SetColor(CLR_WHITE,CLR_GREEN)
	_oBtnNOk:SetColor(CLR_WHITE,CLR_RED)

	_oTexto:SetFocus()

	ACTIVATE MSDIALOG _oDlgMsg //CENTERED

Return(_lRet)

// ** funcao generica calcular o saldo no palete
User Function FtSldPlt(mvIdPalete, mvEtqPrd, mvEtqVol, mvCodProd, mvAgrPrd, mvAgrVol, mvLoteCtl)

	// area inicial
	local _aArea := GetArea()

	// query
	local _cQryZ16

	// dados para retorno
	// 1-Id Palete
	// 2-Local/Armazem
	// 3-Endereco Atual
	// 4-Etq Produto
	// 5-Etq Volume
	// 6-Cod Produto
	// 7-Saldo Atual (Z16)
	// 8-Saldo Reservado (Z08)
	// 9-Saldo Disponivel (Z16 - Z08)
	local _aRetDados := {}

	// valores padroes
	Default mvEtqPrd  := ""
	Default mvEtqVol  := ""
	Default mvCodProd := ""
	Default mvAgrPrd  := .F.
	Default mvAgrVol  := .F.
	Default mvLoteCtl := ""

	// monta query
	_cQryZ16 := "SELECT "
	_cQryZ16 += "  Z16_ETQPAL, "
	_cQryZ16 += "  Z16_LOCAL, "
	_cQryZ16 += "  Z16_ENDATU, "
	_cQryZ16 += IIf(mvAgrPrd,"","''")+" Z16_ETQPRD, "
	_cQryZ16 += IIf(mvAgrVol,"","''")+" Z16_ETQVOL, "
	_cQryZ16 += "  Z16_CODPRO, "
	_cQryZ16 += "  SUM(Z16_SALDO) Z16_SALDO, "
	// saldo reservado
	If (mvAgrPrd) .Or. (mvAgrVol)
		_cQryZ16 += "0 Z08_QUANT, "
	Else
		_cQryZ16 += "(SELECT ISNULL(SUM(Z08_QUANT),0) FROM "+RetSqlName("Z08")+" Z08 (nolock)  "
		_cQryZ16 += "               INNER JOIN " + RetSqlTab("SBE") + " (nolock) "
		_cQryZ16 += "                       ON " + RetSqlCond("SBE")
		_cQryZ16 += "                          AND BE_LOCAL = Z08_LOCAL     "
		_cQryZ16 += "                          AND BE_LOCALIZ = Z08_ENDORI  "
		_cQryZ16 += "               LEFT JOIN " + RetSqlTab("DC8") + " (nolock) "
		_cQryZ16 += "                      ON " + RetSqlCond("DC8")
		_cQryZ16 += "                         AND DC8_CODEST = BE_ESTFIS    "
		// somente OS que NAO movimentou estoque (Z06_ATUEST = 'S' - deve atualizar estoque na movimentacao fisica da carga)
		_cQryZ16 += " INNER JOIN " + RetSqlTab("Z06") + " (nolock)  ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z08_NUMOS AND Z06_SEQOS = Z08_SEQOS "
		// tratamento para consulta de saldo por tipo de estrutura fisica do endereco
		_cQryZ16 += " AND ( ( Z06_ATUEST = 'S' ) OR ( Z06_ATUEST = 'N' AND DC8_TPESTR IN ( '4', '5', '7' ) ) ) "
		// filtro padrao do mapa
		_cQryZ16 += "WHERE "+RetSqlCond("Z08")+" "
		// status em movimento/planejado
		_cQryZ16 += "AND Z08_STATUS IN ('P','M') "
		// endereco
		_cQryZ16 += "AND Z08_LOCAL = Z16_LOCAL AND Z08_ENDORI = Z16_ENDATU "
		// produto
		_cQryZ16 += "AND Z08_PRODUT = Z16_CODPRO  "
		// palete
		_cQryZ16 += "AND Z08_PALLET = Z16_ETQPAL  "
		// lote
		_cQryZ16 += "AND Z08_LOTCTL = Z16_LOTCTL ) Z08_QUANT, "
	EndIf
	// saldo para retorno
	_cQryZ16 += "0 IT_SLDDISP, "
	// lote
	_cQryZ16 += "  Z16_LOTCTL "
	// composicao do palete
	_cQryZ16 += " FROM "+RetSqlTab("Z16")+" (nolock) "
	// filtro padrao
	_cQryZ16 += " WHERE "+RetSqlCond("Z16")
	// numero do palete
	_cQryZ16 += " AND Z16_ETQPAL = '"+mvIdPalete+"' "
	// somente quando tem saldo
	_cQryZ16 += " AND Z16_SALDO > 0 "
	// produto
	If ( ! Empty(mvCodProd) )
		_cQryZ16 += " AND Z16_CODPRO = '"+mvCodProd+"' "
	EndIf
	// lote
	If ( ! Empty(mvLoteCtl) )
		_cQryZ16 += " AND Z16_LOTCTL = '"+mvLoteCtl+"' "
	EndIf
	// agrupa dados
	_cQryZ16 += " GROUP BY "
	_cQryZ16 += "   Z16_ETQPAL, "
	_cQryZ16 += "   Z16_LOCAL, "
	_cQryZ16 += "   Z16_ENDATU, "
	If (mvAgrPrd)
		_cQryZ16 += "  Z16_ETQPRD, "
	EndIf
	If (mvAgrPrd)
		_cQryZ16 += "  Z16_ETQVOL, "
	EndIf
	_cQryZ16 += "  Z16_CODPRO, "
	_cQryZ16 += "  Z16_LOTCTL "

	MEMOWRIT("c:\query\twmsxfun_FtSldPlt.txt",_cQryZ16)

	// atualiza variavel de retorno
	_aRetDados := U_SqlToVet(_cQryZ16)

	// atualiza saldo da variavel de retorno
	aEval(_aRetDados,{|x| (x[9] := (x[7] - x[8])) })

	// restaura areas iniciais
	RestArea(_aArea)

Return(_aRetDados)

// ** Função para validar os parâmetros com base no contrato
User Function FtVldCtr(mvCodCli, mvLjCli, mvParam, mvVar, mvValor, mvTpRet, mvRetCont, mvContrat)
	// query
	local _cQuery := ""
	// variavel de retorno vai depender do VALTYPE do parâmetro
	local _xRet := Nil
	// variavel auxiliar para validação do retorno
	local _xAuxRet

	// variavel de loop
	local _nX

	// recebe variavel como parametros, para retorno conteudo. Chamar com @_aVariavel
	Default mvRetCont := .F.
	Default mvContrat := {}

	// caso o parâmetro passado seja diferente dos aceitáveis
	If (mvVar > 4)
		// para retornar erro, retorna NIL
		U_FtWmsMsg("TWMSXFUN -> FtVldCtr -> Tipo da chave de pesquisa não informado ou inválido!", "ATENCÃO")
		// retorno
		Return Nil
	EndIf

	// Valores permitidos para o parametro mvVar
	// 1 - PROGRAMAÇÃO
	// 2 - CARGA
	// 3 - PEDIDO
	// 4 - ONDA SEPARAÇÃO

	// Valores permitidos para o parametro mvTpRet
	// "L" - Lógico
	// "C" - Caraceter

	// uso a variável mvVar pra identificar qual é a origem da validação
	// pra saber onde buscar os contratos
	_cQuery := " SELECT DISTINCT Z1_CONTRT FROM "+RetSqlTab("SZ1")+" (nolock)  WHERE "+RetSqlCond("SZ1")
	// cliente e loja
	_cQuery += " AND Z1_CLIENTE = '"+mvCodCli+"' AND Z1_LOJA = '"+mvLjCli+"' "

	// filtro da programação baseado nas notas
	If (mvVar == 1) // PROGRAMAÇÃO
		// converte o conteudo em SQL IN
		mvValor := FormatIn(mvValor,";")
		// complementa a query
		_cQuery += " AND Z1_CODIGO IN "+mvValor+" "
	ElseIf (mvVar == 2) .Or. (mvVar == 3) .Or. (mvVar == 4) // 2-CARGA / 3-PEDIDO / 4-ONDA SEPARACAO
		// início da query de procura dos contratos
		_cQuery += " AND Z1_CODIGO IN ( "
		_cQuery += " SELECT F1_PROGRAM "
		// Cabeçalho - Pedido de Venda
		_cQuery += " FROM   "+RetSqlTab("SC5")+" (nolock) "
		// Itens - Pedido de Venda
		_cQuery += " INNER JOIN " + RetSqlTab("SC6") + " WITH(INDEX(" + RetSqlName("SC6") + "1)) "
		_cQuery += "   ON "+RetSqlCond("SC6")
		_cQuery += "      AND C6_NUM = C5_NUM "
		// Nota Fiscal de Entrada
		_cQuery += " INNER JOIN "+RetSqlTab("SF1")+" (nolock) "
		_cQuery += "   ON "+RetSqlCond("SF1")
		_cQuery += "      AND F1_DOC = C6_NFORI "
		_cQuery += "      AND F1_SERIE = C6_SERIORI "
		_cQuery += "      AND F1_FORNECE = C6_CLI "
		_cQuery += "      AND F1_LOJA = C6_LOJA "
		_cQuery += " WHERE  "+RetSqlCond("SC5")

		// validações do parâmetro mvVar
		If (mvVar == 2) // CARGA
			_cQuery += " AND C5_ZCARGA = '"+mvValor+"' ) "
		ElseIf (mvVar == 3) // PEDIDO
			_cQuery += " AND C5_NUM = '"+mvValor+"' ) "
		ElseIf (mvVar == 4) // ONDA SEPARACAO
			_cQuery += " AND C5_ZONDSEP = '" + mvValor + "' ) "
		EndIf

	EndIf

	memowrit("C:\query\twmsxfun_num_cont.txt",_cQuery)

	// jogo a informação para o array pra poder comparar
	mvContrat := U_SqlToVet(_cQuery)

	// se encontrou algum contrato, vai fazer a pesquisa
	If ( ! mvRetCont )
		For _nX := 1 to Len(mvContrat)

			// funcao que verifica o
			_xRet := U_FtWmsParam(mvParam, mvTpRet, .F., .F., "", mvCodCli, mvLjCli, mvContrat[_nX], Nil)

			// comparação para validar o retorno
			If (!Empty(_xAuxRet)) .And. (_xAuxRet != _xRet)
				// para retornar erro, retorna NIL
				U_FtWmsMsg("TWMSXFUN -> FtVldCtr -> Param: "+mvParam+" -> Existem tipos de contrato diferentes para o mesmo registro. Favor verificar!","ATENCÃO")
				// variavel de retorno
				_xRet := Nil
				// sai do Loop
				Exit

			EndIf

			// igualo os dois para comparação
			_xAuxRet := _xRet

		Next _nX

		// se nada foi encontrado, atualiza a variável pra falso
		If ( Empty (_xRet) )
			_xRet := .F.
		EndIf
	EndIf

Return (_xRet)

// ** funcao que apresenta pergunta com duas opções
User Function FtMultRet(mvOpc1, mvOpc2, mvRet1, mvRet2, mvTitulo, mvMessage)

	Local _oDlgMsg, _oTexto, _oBtnPA, _oBtnBL
	// variavel de retorno
	local _xRet

	Default mvMessage := "** ERRO **"
	Default mvTitulo  := "ATENCAO"
	Default mvOpc1    := ""
	Default mvOpc2    := ""
	Default mvRet1    := ""
	Default mvRet2    := ""

	DEFINE MSDIALOG _oDlgMsg FROM 020,020 TO 240,200 TITLE OemToAnsi(mvTitulo) PIXEL

	@ 003, 004 TO 027,087 LABEL "Help" OF _oDlgMsg PIXEL
	@ 010, 008 MSGET OemToAnsi(mvTitulo) WHEN .F. SIZE 076,010 OF _oDlgMsg PIXEL

	@ 030, 004 TO 090, 087 OF _oDlgMsg PIXEL
	@ 036, 008 GET _oTexto VAR OemToAnsi(mvMessage) MEMO READONLY /*NO VSCROLL*/ SIZE 076, 050 OF _oDlgMsg PIXEL

	_oBtnBL  := tButton():New(094,004, mvOpc1 , _oDlgMsg, {|| _xRet := mvRet1, _oDlgMsg:End() },40,15,,,,.T.)
	_oBtnPA  := tButton():New(094,048, mvOpc2 , _oDlgMsg, {|| _xRet := mvRet2, _oDlgMsg:End() },40,15,,,,.T.)
	_oBtnBL:SetColor(CLR_WHITE,CLR_BLUE)
	_oBtnPA:SetColor(CLR_WHITE,CLR_BLUE)

	_oTexto:SetFocus()

	ACTIVATE MSDIALOG _oDlgMsg

Return(_xRet)

// funcao que retorna se o WMS esta ativo por cliente/contrato
//** SEMPRE pesquisar pelo contrato do cliente
// chamado por StaticCall
// ex: StaticCall(TWMSXFUN, WmsMltCntr, "MATA410", "WMS_ATIVO_POR_CLIENTE", M->C5_CLIENTE, M->C5_LOJACLI)
Static Function WmsMltCntr(mvRotOrig, mvParam, mvCodCli, mvLojCli)
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SD1"})

	// variavel de retorno
	local _xVarRet := Nil

	// notas fiscais do cliente
	local _aNfRemes := {}

	// variaveis temporarias
	local _nX

	// posicao de campos
	local _nPosDocOri, _nPosSerOri, _nPosIteOri, _nPosIdSB6

	// variaveis com as programacoes do cliente
	local _cNumProg := ""

	// tipo da variavel
	local _cTipParam := Posicione("Z33",1, xFilial("Z33")+mvParam ,"Z33_TIPO") // 1-Z33_FILIAL, Z33_PARAM

	// chamada da rotina de pedido de venda
	If (AllTrim(Upper(mvRotOrig))=="MATA410")

		// posicao dos campos chaves no aCols
		_nPosDocOri := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_NFORI"  }) // nota fiscal original
		_nPosSerOri := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_SERIORI"}) // serie da nota original
		_nPosIteOri := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ITEMORI"}) // item da nota original
		_nPosIdSB6  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_IDENTB6"}) // Identificador SB6

		// varre todos os itens da tela do pedido de venda
		For _nX := 1 to Len(aCols)

			// verifica se a nota ja está na relacao
			If (aScan(_aNfRemes,{|x| (x[1] == aCols[_nX][_nPosDocOri]) .And. (x[2] == aCols[_nX][_nPosSerOri]) }) == 0 .And. aCols[_nX][len(aHeader)+1] == .F.)

				// adiciona a nota fiscal
				aAdd(_aNfRemes,{;
				aCols[_nX][_nPosDocOri] ,;
				aCols[_nX][_nPosSerOri] })

				// adiciona a programacao (separar por ;)
				_cNumProg += Posicione("SD1",4, xFilial("SD1")+aCols[N,_nPosIdSB6] ,"D1_PROGRAM") // 4-D1_FILIAL, D1_NUMSEQ
				_cNumProg += ";"

			EndIf

		Next _nX

		// limpa o último ; da string
		_cNumProg := Substr(AllTrim(_cNumProg), 1, len(AllTrim(_cNumProg))-1)
	EndIf

	// se encontrou a programação
	If ( ! Empty(_cNumProg) )
		// Valores permitidos para o parametro mvVar
		// 1 - PROGRAMAÇÃO
		// 2 - CARGA
		// 3 - PEDIDO

		// Valores permitidos para o parametro mvTpRet
		// "L" - Lógico
		// "C" - Caraceter

		// valida verifica a configuracao do parametro
		_xVarRet := U_FtVldCtr(mvCodCli, mvLojCli, mvParam, 1, _cNumProg, _cTipParam)

		// valido o tipo da variavel
		If (ValType(_xVarRet) != _cTipParam)
			// não deixa prosseguir e as mensagem são mostradas dentro da função
			U_FtWmsMsg("Erro ao consultar contrato para validar a configuração do parâmetro "+AllTrim(mvParam), "TWMSXFUN -> WmsMltCntr")
			// retorno
			Return(_xVarRet)
		EndIf
	Else
		// caso não tenha encontrado, retorna falso
		_xVarRet := .F.
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni)
	RestArea(_aArea)

Return(_xVarRet)

// exporta browse para excel
User Function FtExpExc( mvTitulo, mvHeader, mvDados )

	local _lProc := MsgYesNo("Deseja Exportar para Excel?" )

	// valida se processa ou não a solicitação
	If( _lProc )

		// função de exportação
		MsgRun("Exportando Registro(s)...", "Aguarde...", {|| CursorWait(), DlgtoExcel( { {"GETDADOS", mvTitulo, mvHeader, mvDados} } ), CursorArrow()})
	EndIf

Return

// função para validar se o cliente possui o código de serviço/tarefa configurado em suas permissões
User Function FTVldSrv (mvCodCli, mvLojCli, mvServico, mvTarefa)

	local _lRet    := .F.
	local _cQryZ37 := ""

	_cQryZ37 := "SELECT R_E_C_N_O_ Z37RECNO   "
	_cQryZ37 += " FROM " + RetSqlTab("Z37") + " (nolock) "
	_cQryZ37 += " WHERE  " + RetSqlCond("Z37")
	_cQryZ37 += "       AND Z37_CODCLI = '" + mvCodCli  + "'"
	_cQryZ37 += "       AND Z37_LOJCLI = '" + mvLojCli  + "'"
	_cQryZ37 += "       AND Z37_SERVIC = '" + mvServico + "'"
	_cQryZ37 += "       AND Z37_TAREFA = '" + mvTarefa  + "'"

	_lRet := !Empty( U_FTQuery(_cQryZ37) )

Return ( _lRet )

//--------------------------------------------------------------------------//
// Programa: FTPSend()  |   Autor: Gustavo Schumann    |   Data: 26/07/2018	//
//--------------------------------------------------------------------------//
// Descrição: Função genérica para efetuar upload via FTP.					//
//--------------------------------------------------------------------------//

User Function FTPSend(cEndereco, nPorta, cUsr, cPass, cPastaFTP, cArq, lAuto)
	Local lRet		:= .T.
	Local aNomeArq	:= {}
	Local cNomeArq	:= ""

	aNomeArq := StrTokArr(cArq,"\")
	cNomeArq := aNomeArq[Len(aNomeArq)]

	CpyT2S(cArq,GetSrvProfString("STARTPATH",""),.F.)

	// se for rotina automática
	If (lAuto)
		If !(FTPENV(cEndereco, nPorta, cUsr, cPass, cPastaFTP, cNomeArq))
			lRet := .F.
		EndIf
	Else
		// pede confirmação
		If MsgYesNo("Deseja enviar o arquivo para o FTP?")

			// tenta enviar o arquivo
			If !(FTPENV(cEndereco, nPorta, cUsr, cPass, cPastaFTP, cNomeArq))
				lRet := .F.
			EndIF
		EndIf
	EndIf

Return (lRet)

Static Function FTPENV(cEndereco, nPorta, cUsr, cPass, cPastaFTP, cArq)
	Local aArea		:= GetArea()
	Local cDirAbs	:= GetSrvProfString("STARTPATH","")
	Local lRet		:= .T.

	cDirAbs			+= cArq

	//Se conseguir conectar
	If FTPConnect(cEndereco ,nPorta ,cUsr , cPass )

		//Define o tipo de transferencia
		FtpSetType(0)

		//Se não conseguir dar o upload
		If !FTPUpload(cDirAbs, cPastaFTP+cArq)
			//Realiza mais uma tentativa
			If !FTPUpload(cDirAbs, cPastaFTP+cArq)
				lRet := .F.
			EndIf
		EndIf

		//Desconecta do FTP
		FTPDisconnect()
	EndIf

	RestArea(aArea)

Return (lRet)

// cria um arquivo e envia por FTP automaticamente, passando o conteudo do arquivo a ser criado via parametro
User Function FTPSend2(cConteudo, cNome, cPastaLoc, cEndereco, nPorta, cUsr, cPass, cPastaFTP, lAuto)
	Local _nHand
	local cFile

	Default cPastaLoc := "c:\temp\"

	cFile := cPastaLoc + cNome
	_nHand	:= FCREATE(cFile)

	// testa se o arquivo foi Criado Corretamente
	If (_nHand == -1)
		If !(lAuto)
			MsgAlert("O arquivo de nome " + cFile + " não pôde ser criado! Verifique os parâmetros da rotina ou as permissões de escrita da pasta destino.","Atencao!")
		EndIf
		Return( .F. )
	Endif

	// gera o arquivo
	FWrite(_nHand, cConteudo)

	//Fecha Arquivo
	FClose(_nHand)

	// se for rotina automática
	If (lAuto)
		If !( U_FTPSend(cEndereco, nPorta, cUsr, cPass, cPastaFTP, cFile, .T.) )
			Return ( .F. )
		EndIf
	Else
		// pede confirmação
		If MsgYesNo("Deseja enviar o arquivo para o FTP?")

			// tenta enviar o arquivo
			If !(U_FTPSend(cEndereco, nPorta, cUsr, cPass, cPastaFTP, cFile, .T.))
				Return ( .F. )
			EndIF
		EndIf
	EndIf

	// apaga o arquivo
	FErase(cFile)
Return ( .T. )

// função que retorna as funções WMS que o usuário pode executar
User Function FTWmsFun (mvCodUser)

	local _aRet := {}
	local _cRet := ""
	local _cQry := ""

	_cQry := "SELECT DCD_ZCATEG FROM " + RetSqlTab("DCD") + " (nolock)  WHERE " + RetSqlCond("DCD") + " AND DCD_CODFUN = '" + mvCodUser + "'"

	If (U_FTQuery(_cQry) $ "G|S|")  // se supervisor ou gerente
		// pega todas as funções WMS cadastradas no sistema
		_cQry := "SELECT RJ_FUNCAO FROM " + RetSqlTab("SRJ") + " (nolock)  WHERE " + RetSqlCond("SRJ") + " AND RJ_FUNCAO LIKE '%WMS%'"

		_aRet := U_SqlToVet(_cQry)
	Else
		// pega apenas as funções conforme cadastro na rotina de recursos WMS
		_cQry := "SELECT DCI_FUNCAO FROM " + RetSqlTab("DCI") + " (nolock)  WHERE " + RetSqlCond("DCI") + " AND DCI_CODFUN = '" + mvCodUser + "'"

		_aRet := U_SqlToVet(_cQry)
	EndIf

Return (_aRet)

// função que efetua a troca de um volume por outro, no ato da montagem de volumes ou conferência de carregamento
// OBS: não executa qualquer validação, presume que isso já foi tratado ao executar a rotina
User Function FTrocaVol(mvVolAntigo, mvVolNovo, mvNumOS, mvEndTroca)

	Local _cQry        := ""
	Local _aRetZ07A    := {}
	Local _aRetZ16A    := {}
	Local _aRetZ16N    := {}
	Local _nX
	Local _aAreaZ07    := Z07->(GetArea())
	Local _aAreaZ16    := Z16->(GetArea())
	Local _aAreaSB1    := SB1->(GetArea())
	Local _cEndConf    := ""
	Local _cNewPltN    := ""
	Local _cNewPltA    := ""
	Local _aItemSD3    := {}
	Local _aTmpItem    := {}

	Default mvEndTroca := "QUALIDADE"

	// Etapa 1 - Obtem registros do Volume antigo na conferência para excluir
	_cQry := "SELECT R_E_C_N_O_ FROM " + RetSqlTab("Z07") + " WHERE " + RetSqlCond("Z07")
	_cQry += " AND Z07_ETQVOL = '" + mvVolAntigo + "'"
	_cQry += " AND Z07_NUMOS  = '" + mvNumOS + "'"
	_cQry += " AND Z07_STATUS IN ('D', 'F') "

	If ( Len(_aRetZ07A := U_SqlToVet(_cQry)) < 1 )
		Return ( .F. )   // se não achou nenhum registro, aborta
	EndIf

	// Etapa 2 - Obtem endereço de serviço onde a conferência está sendo realizada
	If Empty( _cEndConf := GetAdvFval("Z06", "Z06_ENDSRV", xFilial("Z06")+mvNumOs,1 ) )        // 01 - Z06_FILIAL, Z06_NUMOS, Z06_SEQOS, R_E_C_N_O_, D_E_L_E_T_
		Return ( .F. )   // se não achou nenhum registro, aborta
	EndIf

	// Etapa 3 - Obtem registros da tabela Z16 da conferência do volume antigo
	_cQry := "SELECT R_E_C_N_O_ FROM " + RetSqlTab("Z16") + " WHERE " + RetSqlCond("Z16")
	_cQry += " AND Z16_ETQVOL = '" + mvVolAntigo + "'"
	_cQry += " AND Z16_SALDO > 0"
	_cQry += " AND Z16_ENDATU = '" + _cEndConf + "'"

	If ( Len(_aRetZ16A := U_SqlToVet(_cQry)) < 1 )
		Return ( .F. )   // se não achou nenhum registro, aborta
	EndIf

	// Etapa 4 - Obtem registros da tabela Z16 da conferência do volume novo
	_cQry := "SELECT R_E_C_N_O_, Z16_CODPRO, Z16_LOCAL, Z16_ENDATU, Z16_LOTCTL, Z16_VLDLOT, Z16_SALDO, Z16_ETQPAL FROM " + RetSqlTab("Z16") + " WHERE " + RetSqlCond("Z16")
	_cQry += " AND Z16_ETQVOL = '"+mvVolNovo+"'"
	_cQry += " AND Z16_SALDO > 0"

	If ( Len(_aRetZ16N := U_SqlToVet(_cQry, {"Z16_VLDLOT"}) ) < 1 )
		Return ( .F. )   // se não achou nenhum registro, aborta
	EndIf

	//------- Inicio processamento -------
	// insere quantidade lida na relacao de itens

	Begin Transaction

		// Pega os dados da Z07 e da etiqueta Origem para efetuar a cópia para a etiqueta destino
		If Select('tZ07') > 0
			DBSelectArea('tZ07')
			tZ07->(DBCloseArea())
		EndIf
		cQuery := " SELECT * "
		cQuery += " FROM  " + RetSqlTab("Z07") + " (NOLOCK) "
		cQuery += " WHERE " + RetSqlCond("Z07")
		cQuery += " AND Z07_NUMOS  = '" + mvNumOS     + "' "
		cQuery += " AND Z07_ETQVOL = '" + mvVolAntigo + "' "
		TCQuery cQuery NEW ALIAS 'tZ07'

		// Gera novo Pallet NOVO (Que será gravado na Z07)
		_cNewPltN := U_FtGrvEtq("03",{"000001",""})
		// Gera novo Pallet antigo (Que será ENVIADO PARA QUALIDADE)
		_cNewPltA := U_FtGrvEtq("03",{"000001",""})

		dbSelectArea("Z16")
		dbSelectArea("Z07")

		For _nX := 1 to Len(_aRetZ16N)
			// Atualiza endereço do novo volume para doca atual onde está sendo realizada a conferência
			Z16->(DbGoto(_aRetZ16N[_nX][1]))  // [1] = RECNO

			RecLock("Z16")
			Z16->Z16_ENDATU := _cEndConf
			Z16->Z16_PLTORI := tZ07->Z07_PALLET
			Z16->Z16_VOLORI := tZ07->Z07_ETQVOL
			Z16->Z16_ETQPAL := _cNewPltN
			Z16->Z16_PEDIDO := tZ07->Z07_PEDIDO
			Z16->Z16_ORIGEM := "VOL"
			Z16->Z16_PRDORI := mvVolAntigo
			MsUnLock("Z16")

			// Pega os dados da Z16 da etiqueta de destino para criar a Z07
			// Cria a Z07 de destino (já "efetua a conferência")

			RecLock("Z07", .T.)
			Z07->Z07_FILIAL	:= xFilial("Z07")
			Z07->Z07_NUMOS	:= mvNumOs
			Z07->Z07_SEQOS	:= tZ07->Z07_SEQOS
			Z07->Z07_CLIENT	:= tZ07->Z07_CLIENT
			Z07->Z07_LOJA	:= tZ07->Z07_LOJA
			Z07->Z07_PEDIDO	:= tZ07->Z07_PEDIDO
			Z07->Z07_ETQPRD	:= Z16->Z16_ETQPRD
			Z07->Z07_PRODUT	:= Z16->Z16_CODPRO
			Z07->Z07_NUMSEQ	:= Z16->Z16_NUMSEQ
			Z07->Z07_LOCAL	:= Z16->Z16_LOCAL
			Z07->Z07_QUANT	:= Z16->Z16_SALDO
			Z07->Z07_QTSEGU := Z16->Z16_QTSEGU
			Z07->Z07_NRCONT	:= tZ07->Z07_NRCONT
			Z07->Z07_USUARI := __cUserId
			Z07->Z07_DATA	:= Date()
			Z07->Z07_HORA	:= Time()
			Z07->Z07_PLTCLI := Z16->Z16_PLTCLI
			Z07->Z07_LOTCTL := Z16->Z16_LOTCTL
			Z07->Z07_VLDLOT := Z16->Z16_VLDLOT
			Z07->Z07_PALLET	:= _cNewPltN
			Z07->Z07_UNITIZ := Z16->Z16_UNITIZ
			Z07->Z07_STATUS	:= tZ07->Z07_STATUS
			Z07->Z07_ENDATU	:= tZ07->Z07_ENDATU
			Z07->Z07_CODBAR := Z16->Z16_CODBAR
			Z07->Z07_TPESTO := Z16->Z16_TPESTO
			Z07->Z07_CAMPLT := Z16->Z16_CAMPLT
			Z07->Z07_ETQVOL := Z16->Z16_ETQVOL
			Z07->Z07_EMBALA := Z16->Z16_EMBALA
			Z07->Z07_ETQCLI := Z16->Z16_ETQCLI
			Z07->Z07_NUMSER := Z16->Z16_NUMSER
			Z07->Z07_DTSERI := Z16->Z16_DTSERI
			Z07->Z07_PLTORI := tZ07->Z07_PALLET
			Z07->Z07_VOLORI := tZ07->Z07_ETQVOL

			// grava dados
			Z07->(MsUnLock())
		Next _nX

		// Apaga conferências da OS antiga
		For _nX := 1 to Len(_aRetZ07A)
			Z07->(DbGoto(_aRetZ07A[_nX]))
			RecLock("Z07")
			Z07->(DBDelete())
			MsUnLock("Z07")
		Next _nX

		// Atualiza endereço e tipo de estoque do volume antigo para área de inspeção de qualidade/troca informada nos parâmetros
		For _nX := 1 to Len(_aRetZ16A)
			Z16->(DbGoto(_aRetZ16A[_nX]))
			RecLock("Z16")
			Z16->Z16_ETQPAL := _cNewPltA
			Z16->Z16_ENDATU := mvEndTroca
			Z16->Z16_TPESTO := "000006"
			Z16->Z16_PLTORI := ""
			Z16->Z16_VOLORI := ""
			Z16->Z16_PEDIDO := ""
			Z16->Z16_PRDORI := ""
			Z16->Z16_ONDSEP := ""
			MsUnLock("Z16")
		Next _nX

		// Executa transferência do saldo fiscal para a área de inspeção de qualidade/troca
		// É feito levando o saldo do novo produto sendo trocado, pois o saldo do produto anterior (substituído) pode já estar empenhado em pedido de venda e o processo falharia
		For _nX := 1 to Len(_aRetZ16N)
			// zera variaveis
			_aItemSD3 := {}
			_aTmpItem := {}

			_aItemSD3 := {{NextNumero("SD3",2,"D3_DOC",.T.), Date() }}

			// posiciona no cadastro de produtos
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
			SB1->(dbSeek( xFilial("SB1") + _aRetZ16N[_nX][2] ))   // [2] - Z16_CODPRO - codigo do produto

			// itens para movimentacao de transferencia
			If !Empty(SB1->B1_TIPCONV)
				If SB1->B1_TIPCONV == "D"
					nSaldo2 := _aRetZ16N[_nX][7] / SB1->B1_CONV
				Else
					nSaldo2 := _aRetZ16N[_nX][7] * SB1->B1_CONV
				EndIf
			Else
				nSaldo2 := 0
			EndIf

			_aTmpItem := {	{"D3_COD"		, _aRetZ16N[_nX][2]	,Nil},;
			{"D3_DESCRI"	, SB1->B1_DESC		,Nil},;
			{"D3_UM"		, SB1->B1_UM		,Nil},;
			{"D3_LOCAL"		, _aRetZ16N[_nX][3]	,Nil},;
			{"D3_LOCALIZ"	, _aRetZ16N[_nX][4]	,Nil},;
			{"D3_COD"		, _aRetZ16N[_nX][2]	,Nil},;
			{"D3_DESCRI"	, SB1->B1_DESC		,Nil},;
			{"D3_UM"		, SB1->B1_UM		,Nil},;
			{"D3_LOCAL"		, _aRetZ16N[_nX][3]	,Nil},;
			{"D3_LOCALIZ"	, mvEndTroca		,Nil},;
			{"D3_NUMSERI"	, ""				,Nil},;
			{"D3_LOTECTL"	, _aRetZ16N[_nX][5]	,Nil},;
			{"D3_NUMLOTE"	, ""				,Nil},;
			{"D3_DTVALID"	, _aRetZ16N[_nX][6]	,Nil},;
			{"D3_POTENCI"	, 0.00				,Nil},;
			{"D3_QUANT"		, _aRetZ16N[_nX][7]	,Nil},;
			{"D3_QTSEGUM"	, nSaldo2			,Nil},;
			{"D3_ESTORNO"	, ""				,Nil},;
			{"D3_NUMSEQ"	, ""				,Nil},;
			{"D3_LOTECTL"	, _aRetZ16N[_nX][5]	,Nil},;
			{"D3_NUMLOTE"	, ""				,Nil},;
			{"D3_DTVALID"	, _aRetZ16N[_nX][6]	,Nil},;
			{"D3_ZNUMOS"	, mvNumOS			,Nil},;
			{"D3_ZSEQOS"	, ""				,Nil},;
			{"D3_ZETQPLT"	, _cNewPltN			,Nil},;
			{"D3_ZCARGA"	, ""				,Nil},;
			{"D3_ZPEDIDO"	, ""				,Nil},;
			{"D3_ZITPEDI"	, ""				,Nil}}

			// adiciona o item
			aAdd(_aItemSD3, _aTmpItem)

			// variaveis padroes da rotina automatica
			lMsHelpAuto := .T.
			lMsErroAuto := .F.

			// executa rotina automatica
			MsExecAuto({|x,y|MATA261(x,y)}, _aItemSD3, 3) // 3 - transferencia

			If (lMsErroAuto)   // se deu erro
				DisarmTransaction()
				RestArea(_aAreaZ07)
				RestArea(_aAreaZ16)
				RestArea(_aAreaSB1)
				Return ( .F. )
			EndIf

		Next _nX

	End Transaction

	//------- Fim processamento -------

	// restaura areas
	RestArea(_aAreaZ07)
	RestArea(_aAreaZ16)
	RestArea(_aAreaSB1)

Return ( .T. )

