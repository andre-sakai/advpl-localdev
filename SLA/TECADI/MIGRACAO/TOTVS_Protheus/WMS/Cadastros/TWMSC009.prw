#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Configurações WMS por Contrato                          !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 03/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSC009

	// variaveis para o MarkBrowse
	Private cCadastro := "Configuração do WMS - Por Contrato"
	/*
	// sub-menu de consultas
	private _aBtnCons	:= {{ "Cons. Detalhada"		,"U_FATA002V('1')", 0 , 2},;
		{ "Consulta de Log"		,"U_FATA002V('2')", 0 , 2},;
		{ "Consulta Contrato"	,"U_FATA002V('3')", 0 , 2},;
		{ "Id. Processo"		,"U_FATA002V('4')", 0 , 2} }

	// sub-menu de impressão
	private _aBtnImpre	:= {{ "Det. Faturamento"	,"U_FATA002O('1')", 0 , 2},;
		{ "Histór. Faturamento"	,"U_FATA002O('2')", 0 , 2},;
		{ "Mapa Movimentação"	,"U_FATA002O('3')", 0 , 2} }

	// sub-menu do pedido de vendas
	private _aBtnPedVen	:= {{ "Gera Pedido Venda"	,"U_FATA002G('F')"  , 0 , 2},;
		{ "Visualizar Pedido"	,"U_FATA002N()"     , 0 , 2},;
		{ "Análise de Crédito"	,"U_FATA002U('CR')" , 0 , 2},;
		{ "Estornar"			,"U_FATA002Y()"     , 0 , 2},;
		{ "Gera Nota Fiscal"	,"U_FATA002U('NF')" , 0 , 2} }

	// sub-menu do pedido de vendas
	private _aBtnNtFis	:= { }
	*/

	//		{ "Pedido de Venda"		,_aBtnPedVen      , 0 , 2},;
		//{ "Consultas"			,_aBtnCons        , 0 , 2},;
		//{ "Relatórios"			,_aBtnImpre       , 0 , 2},;

	// opcoes do menus
	Private aRotina := { { "Configurar WMS" ,"U_WMSC009A()", 0 , 2} }

	// seleciona o alias do contrato
	dbSelectArea("AAM")
	AAM->(dbGotop())

	// mark browse com os contratos
	MarkBrow("AAM",Nil,Nil,Nil,,Nil,Nil)

Return(.t.)

// ** funcao para atualizar os dados do contrato
User Function WMSC009A
	// objetos da tela
	local _oDlgParam
	local _oPnlCabec
	local _oBrwParam
	local _oSayContrt, _oSayDescri, _oSayCliente

	// variaveis do browse
	local _cAlParam := GetNextAlias()
	local _cTrParam := ""
	Local _aStParam := {}
	Local _aHdParam := {}


	// controle de confirmacao da tela
	local _lOk := .f.

	// dimensoes da tela
	local _aSizeDlg := MsAdvSize()

	// administrador
	local _aGrupos   := FWSFUsrGrps(__cUserId)
	local _lWmsAdmin := ((__cUserId $ "000000/000051") .or. (aScan(_aGrupos,"000000") > 0))

	// cria tabelas
	dbSelectArea("Z33") // cad. parametros
	dbSelectArea("Z30") // configuracoes

	// verifica se tem permissao
	If ( ! _lWmsAdmin )
		Aviso("TWMSC009","Usuário sem permissão para utilizar esta rotina.",{"Fechar"})
		Return(.f.)
	EndIf

	// -- estrutura do TRB - Parametros
	aAdd(_aStParam,{"Z33_PARAM" , "C", TamSx3("Z33_PARAM")[1] ,0})
	aAdd(_aStParam,{"Z33_DESCRI", "C", TamSx3("Z33_DESCRI")[1],0})
	aAdd(_aStParam,{"Z33_TIPO"  , "C", TamSx3("Z33_TIPO")[1]  ,0})
	aAdd(_aStParam,{"Z30_CONTEU", "C", TamSx3("Z30_CONTEU")[1],0})

	// criar um arquivo de trabalho
	_cTrParam := CriaTrab(_aStParam,.T.)
	dbUseArea(.T.,,(_cTrParam),(_cAlParam),.F.,.F.)

	// campos do browse
	aAdd(_aHdParam,{"Z33_PARAM" , "", "Parametro", PesqPict("Z33","Z33_PARAM")  })
	aAdd(_aHdParam,{"Z33_DESCRI", "", "Descrição", PesqPict("Z33","Z33_DESCRI") })
	aAdd(_aHdParam,{"Z33_TIPO"  , "", "Tipo"     , PesqPict("Z33","Z33_TIPO")   })
	aAdd(_aHdParam,{"Z30_CONTEU", "", "Conteúdo" , PesqPict("Z33","Z30_CONTEU") })

	// funcao que atualiza os dados conforme cadastro
	If ( ! sfDefParam(_cAlParam, _aStParam) )
		Return(.f.)
	EndIf

	// seleciona o TRB e coloca no inicio
	dbSelectArea(_cAlParam)
	(_cAlParam)->(dbGoTop())

	// monta a tela para alterar o valor
	_oDlgParam := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Configurações WMS por Contrato",,,.F.,,,,,,.T.,,,.T. )
	_oDlgParam:lMaximized := .T.

	// cria o panel do cabecalho
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgParam,,.F.,.F.,,,000,040,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// informacoes do contrato e cliente
	_oSayContrt  := TSay():New(010,010,{|| "Contrato: "+AAM->AAM_CONTRT },_oPnlCabec,,,.F.,.F.,.F.,.T.,,,300,010)
	_oSayDescri  := TSay():New(020,010,{|| "Título: "+AAM->AAM_TITULO },_oPnlCabec,,,.F.,.F.,.F.,.T.,,,300,010)
	_oSayCliente := TSay():New(030,010,{|| "Cliente: "+AAM->AAM_CODCLI + "/" + AAM->AAM_LOJA + "-" + Posicione("SA1",1, xFilial("SA1")+AAM->(AAM_CODCLI+AAM_LOJA) ,"A1_NOME") },_oPnlCabec,,,.F.,.F.,.F.,.T.,,,300,008)

	// browse com os detalhes dos parametros
	_oBrwParam := MsSelect():New((_cAlParam),,,_aHdParam,,,{15,1,183,373},,,_oDlgParam,,;
		{{ "Empty("+_cAlParam+"->Z30_CONTEU)","DISABLE"},{ "!(Empty("+_cAlParam+"->Z30_CONTEU))","ENABLE"}})
	_oBrwParam:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwParam:oBrowse:blDblClick := {|| sfAltParam(_cAlParam) }

	// ativacao da tela com validacao
	ACTIVATE MSDIALOG _oDlgParam CENTERED ON INIT EnchoiceBar(_oDlgParam,{|| _lOk := .t., _oDlgParam:End() } , {|| _oDlgParam:End() })

	// se a tela foi confirmada
	If (_lOk)
		// funcao para gravar as atualizacoes dos parametros
		sfGrvParam(_cAlParam)
	EndIf

Return(_lOk)

// ** funcao que atualiza os dados conforme cadastro
Static Function sfDefParam(mvAlParam, mvStParam)
	// variavel para montagem da query
	local _cQuery

	// filtra somente parametros padroes
	_cQuery := "SELECT Z33_PARAM, Z33_DESCRI, Z33_TIPO, ISNULL(Z30CLIE.Z30_CONTEU,'"+CriaVar("Z30_CONTEU")+"') Z30_CONTEU "
	// cad. de parametrs
	_cQuery += "FROM "+RetSqlName("Z33")+" Z33 "
	// conteudo padrao
	_cQuery += "LEFT JOIN "+RetSqlName("Z30")+" Z30PADR ON Z30PADR.Z30_FILIAL = Z33_FILIAL AND Z30PADR.D_E_L_E_T_ = ' ' AND Z30PADR.Z30_PARAM = Z33_PARAM "
	_cQuery += "AND Z30PADR.Z30_CODCLI = ' ' "
	// conteudo por cliente
	_cQuery += "LEFT JOIN "+RetSqlName("Z30")+" Z30CLIE ON Z30CLIE.Z30_FILIAL = Z33_FILIAL AND Z30CLIE.D_E_L_E_T_ = ' ' AND Z30CLIE.Z30_PARAM = Z33_PARAM "
	_cQuery += "AND Z30CLIE.Z30_CODCLI = '"+AAM->AAM_CODCLI+"' AND Z30CLIE.Z30_LOJCLI = '"+AAM->AAM_LOJA+"' "
	//_cQuery += "AND Z30CLIE.Z30_CONTRT = '"+AAM->AAM_CONTRT+"' "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z33")
	// ordem dos dados
	_cQuery += "ORDER BY Z33_PARAM"

	// dados para o vetor
	U_SqlToTrb(_cQuery, mvStParam, mvAlParam)

Return(.t.)

// ** funcao para informar o conteúdo do parametros
Static Function sfAltParam(mvAlParam)
	// objetos
	local _oWnd01Param
	local _oSay01Param, _oSay01Descr, _oSay01Conte, _oSay01Expli
	local _oGet01Param, _oGet01Descr, _oGet01Conte, _oGet01Expli
	// controle para nao fechar a tela
	Local _lOk := .f.
	// conteudo o do parametro
	private _cGetParam := (mvAlParam)->Z30_CONTEU

	// posiciona no cadatro do parametro
	dbSelectArea("Z33")
	Z33->(dbSetOrder(1)) // 1-Z33_FILIAL, Z33_PARAM
	Z33->(dbSeek( xFilial("Z33")+(mvAlParam)->Z33_PARAM ))

	// monta a tela para informa a quantidade
	_oWnd01Param := MSDialog():New(000,000,400,650,"Definição do Parâmetro",,,.F.,,,,,,.T.,,,.T.)

	// parametro
	_oSay01Param := TSay():New(010,010,{||"Parâmetro"},_oWnd01Param,,,.F.,.F.,.F.,.T.)
	_oGet01Param := TGet():New(018,010,{|| Z33->Z33_PARAM },_oWnd01Param,300,010,PesqPict("Z33","Z33_PARAM"),Nil,,,,,,.T.,"",,{||.F.},.F.,.F.,,.F.,.F.,"",Nil,,)

	// descricao do parametro
	_oSay01Descr := TSay():New(030,010,{||"Descrição do Parâmetro"},_oWnd01Param,,,.F.,.F.,.F.,.T.)
	_oGet01Descr := TGet():New(038,010,{|| Z33->Z33_DESCRI },_oWnd01Param,300,010,PesqPict("Z33","Z33_DESCRI"),Nil,,,,,,.T.,"",,{||.F.},.F.,.F.,,.F.,.F.,"",Nil,,)

	// conteudo do parametro
	_oSay01Conte := TSay():New(050,010,{||"Definição do Parâmetro"},_oWnd01Param,,,.F.,.F.,.F.,.T.)
	_oGet01Conte := TGet():New(058,010,{|u| If(PCount()>0,_cGetParam:=u,_cGetParam)},_oWnd01Param,300,010,PesqPict("Z33","Z30_CONTEU"),Nil,,,,,,.T.,"",,{||.T.},.F.,.F.,,.F.,.F.,Nil,"_cGetParam",,)

	// explicacao detalhada
	_oSay01Expli := TSay():New(070,010,{||"Descrição Completa"},_oWnd01Param,,,.F.,.F.,.F.,.T.)
	_oGet01Expli := tMultiget():New(078,010, {|| Z33->Z33_DSCCOM }, _oWnd01Param,300,100,,,,,,.T.,,,,,,.T.)

	// ativacao da tela com validacao
	ACTIVATE MSDIALOG _oWnd01Param CENTERED ON INIT EnchoiceBar(_oWnd01Param,{|| _lOk := .t., _oWnd01Param:End() } , {|| _oWnd01Param:End() })

	// se foi confirmado, grava o novo conteudo
	If (_lOk)
		dbSelectArea(mvAlParam)
		RecLock(mvAlParam)
		(mvAlParam)->Z30_CONTEU := _cGetParam
		(mvAlParam)->(MsUnLock())
	EndIf
Return

// ** funcao para gravar as atualizacoes dos parametros
Static Function sfGrvParam(mvAlParam)
	// quais contratos
	local _aContrt := {}
	// quais cliente
	local _aCliente := {{AAM->AAM_CODCLI, AAM->AAM_LOJA}}
	// variaveis temporias
	local _nItem
	local _nCliente
	local _nContrt
	// codigo do parametro
	local _cCodParam
	// conteudo do parametro
	local _cConteudo

	// varre todos os parametros por cliente/loja
	For _nCliente := 1 to Len(_aCliente)

		// varre todos os parametros
		dbSelectArea(mvAlParam)
		(mvAlParam)->(DbGoTop())

		While (mvAlParam)->(!Eof())

			// atualiza codigo do parametro
			_cCodParam := (mvAlParam)->Z33_PARAM
			// extrai o parametro
			_cConteudo := (mvAlParam)->Z30_CONTEU

			// ignora conteudo vazio
			If (Empty(_cConteudo))
				dbSelectArea(mvAlParam)
				(mvAlParam)->(dbSkip())
				Loop
			EndIf

			// abre tabela dos parametros
			dbSelectArea("Z30")
			Z30->(dbSetOrder(1)) // 1-Z30_FILIAL, Z30_PARAM, Z30_CODFIL, Z30_CODCLI, Z30_LOJCLI, Z30_CONTRT, Z30_NUMOS

			If Z30->(dbSeek( xFilial("Z30") + _cCodParam + xFilial("AAM") + _aCliente[_nCliente][1] + _aCliente[_nCliente][2] ))
				// atualiza os dados
				dbSelectArea("Z30")
				RecLock("Z30",.f.)
				Z30->Z30_CONTEU := _cConteudo
				Z30->(MsUnLock())
			Else
				// inclui novo registro
				dbSelectArea("Z30")
				RecLock("Z30",.t.)
				Z30->Z30_FILIAL := xFilial("Z30")
				Z30->Z30_PARAM  := _cCodParam
				Z30->Z30_CODFIL := xFilial("AAM")
				Z30->Z30_CODCLI := _aCliente[_nCliente][1]
				Z30->Z30_LOJCLI := _aCliente[_nCliente][2]
				Z30->Z30_CONTRT := ""
				Z30->Z30_CONTEU := _cConteudo
				Z30->(MsUnLock())
			EndIf

			// proximo parametro
			dbSelectArea(mvAlParam)
			(mvAlParam)->(dbSkip())
		EndDo

		// proximo cliente/loja
	Next _nCliente

Return