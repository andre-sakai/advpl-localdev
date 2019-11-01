#include 'totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Consulta quadro de programacoes/agendamento             !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 07/2012 !
+------------------+--------------------------------------------------------*/

// ** nova funcao de agendamento
User Function TWMSV005()

	// objeto browse
	Local _oBrwAgenda := Nil

	// cabecalho
	dbSelectArea("SZY")

	// titulo
	Private cCadastro := "Controle de Agendamentos"

	// controle de opcoes do menu
	Private aRotina := MenuDef()

	// cria objeto do browse
	_oBrwAgenda := FWMBrowse():New()
	_oBrwAgenda:SetAlias('SZY')
	_oBrwAgenda:SetDescription(cCadastro)

	// define cores do browse
	_oBrwAgenda:AddLegend("ZY_STATUS == 'A'", "BR_AZUL" )
	_oBrwAgenda:AddLegend("ZY_STATUS == 'R'", "BR_VERDE")
	_oBrwAgenda:AddLegend("ZY_STATUS == 'C'", "BR_PRETO")

	// cria um filtro fixo para todos
	_oBrwAgenda:AddFilter("Agendado" , "ZY_STATUS == 'A'", .f., .t., "SZY", .f., {}, "ID_AGENDADO" )
	_oBrwAgenda:AddFilter("Realizado", "ZY_STATUS == 'R'", .f., .f., "SZY", .f., {}, "ID_REALIZADO")
	_oBrwAgenda:AddFilter("Cancelado", "ZY_STATUS == 'C'", .f., .f., "SZY", .f., {}, "ID_CANCELADO")

	// ativa objeto browse
	_oBrwAgenda:Activate()

Return

// ** funcao para definir o menu
Static Function MenuDef()
	// variavel de retorno
	local _aRetMenu := 	{;
	{ "Pesquisar"            , "AxPesqui"    , 0 , 1 },;
	{ "Visualizar"           , "AxVisual"    , 0 , 2 },;
	{ "Incluir"              , "U_WMSV005D()", 0 , 3 },;
	{ "Alterar"              , "U_WMSV005F()", 0 , 4 },;
	{ "Cancelar"             , "U_WMSV005H()", 0 , 4 },;
	{ "Planejar Carregamento", "U_WMSV005I()", 0 , 4 },;
	{ "Consultar Log"        , "U_FtConsLog(cFilAnt, 'SZY', SZY->ZY_FILIAL + SZY->ZY_SEQUENC )", 0 , 5 },;
	{ "Legenda"              , "U_WMSV005C()", 0 , 1 } }

	//{ "Excluir"      , "U_WMSV005G()", 0 , 5 },; -- desativado a pedido do Flavio e Daniel em 08/12

Return(_aRetMenu)

// ** funcao que Monta a Legenda
User Function WMSV005C()

	BrwLegenda(cCadastro, "Status "+cCadastro,{;
	{"BR_AZUL" , "Agendado"  },;
	{"BR_VERDE", "Realizado" },;
	{"BR_PRETO", "Cancelado" }})

Return .T.

// ** funcao para inclusao de agendamentos
User Function WMSV005D()
	// variavel de controle
	local _lRet := .t.
	// opcao da confirmacao da tela
	local _nOpcSel := 0

	local _aRet := {}

	// chama rotina padrao de alteracao de dados
	If (_lRet)
		// tela padrao de alteracao de dados
		_nOpcSel := AxInclui("SZY", Nil, 3, Nil, Nil, Nil, "U_WMSV005E(.f.)")
	EndIf

	// esta esta ok, e foi confirmado, atualiza dados
	If (_lRet) .and. (_nOpcSel == 1)
		RecLock("SZY")
		// define o tempo do agendamento em relacao ao inicio da operacao
		SZY->ZY_TPAGEND := sfRetTpAge(SZY->ZY_DTINIC, SZY->ZY_HRINIC)
		MsUnLock()

	EndIf

Return(_lRet)

// ** funcao que realiza as validacoes da tela
User Function WMSV005E(mvCanc)
	// variavel de controle
	local _lRet := .t.

	// variável para guardar retorno de programação e item
	local _aRet := {}

	// duracao da operacao
	local _nTempoDur := 0

	// valor padrao
	Default mvCanc    := .f.

	// valida data e hora
	If (_lRet) .and. ( ! mvCanc ) .and. (M->ZY_DTINIC < Date())
		// mensagem
		Aviso("TWMV005 -> WMSV005E","A data do início da operação não pode ser inferior a data atual.",{"Fechar"})
		// variavel de controle
		_lRet := .f.
	EndIf

	// valida data e hora
	If (_lRet) .and. ( ! mvCanc ) .and. ((M->ZY_DTFINAL < M->ZY_DTINIC) .or. ((M->ZY_DTFINAL == M->ZY_DTINIC) .and. (M->ZY_HRFINAL <= M->ZY_HRINIC))  )
		// mensagem
		Aviso("TWMV005 -> WMSV005E","A data ou hora final do agendamento não pode ser inferior a data ou hora inicial.",{"Fechar"})
		// variavel de controle
		_lRet := .f.
	EndIf

	// valida tempo de duracao da operacao
	If (_lRet) .and. ( ! mvCanc )
		// calculo duracao
		_nTempoDur := fConvHr(A680Tempo(M->ZY_DTINIC, M->ZY_HRINIC, M->ZY_DTFINAL, M->ZY_HRFINAL), "H")
	EndIf

	// valida tempo minimo de 30 min
	If (_lRet) .and. ( ! mvCanc ) .and. (_nTempoDur < 0.30)
		// mensagem
		Aviso("TWMV005 -> WMSV005E","Favor verificar o tempo total da operação, que não pode ser inferior a 30 min.",{"Fechar"})
		// variavel de controle
		_lRet := .f.
	EndIf

	// valida tempo maximo de 30 min
	If (_lRet) .and. ( ! mvCanc ) .and. (_nTempoDur > 10)
		// mensagem
		Aviso("TWMV005 -> WMSV005E","Favor verificar o tempo total da operação, que não pode ser superior a 10 horas.",{"Fechar"})
		// variavel de controle
		_lRet := .f.
	EndIf

	// valida se foi preenchida programação e item da programação
	If (_lRet) .and. ( ! mvCanc )
		// caso seja expedição, não deve mais utilizar/pedir programação, pois a programação de carregamento
		// não se usa para nada (Daniel Kenig 31/08/2018)
		IF !(M->ZY_OPERACA == "02")
			// se estiver vazio, obriga a preencher a programação
			if ( Empty(M->ZY_PROCES) .OR. Empty(M->ZY_ITPROC) )
				_aRet := U_FtLstPrg(M->ZY_CLIENTE, M->ZY_LOJA)

				_lRet := _aRet[1]
				// programação e item da programação
				M->ZY_PROCES := _aRet[2]
				M->ZY_ITPROC := _aRet[3]
			Else
				If MsgYesNo("Deseja trocar a programação?")
					_aRet := U_FtLstPrg(M->ZY_CLIENTE, M->ZY_LOJA)

					_lRet := _aRet[1]
					// programação e item da programação
					M->ZY_PROCES := _aRet[2]
					M->ZY_ITPROC := _aRet[3]
				EndIf
			EndIf
		EndIf

	EndIf

	// solicita o motivo do cancelamento
	If (_lRet) .and. (mvCanc)

		// chama funcao padrao para informar o motivo de cancelamento
		_cMotCanc := FWInputBox("Informe o motivo do cancelamento", _cMotCanc)

		// valida conteudo digitado
		If (Len(AllTrim(_cMotCanc)) < 15)
			// mensagem
			Aviso("TWMV005 -> WMSV005E","Favor informar um motivo de cancelamento com mais de 15 caracteres.",{"Fechar"})
			// variavel de controle
			_lRet := .f.
		EndIf
	EndIf

Return(_lRet)

// ** funcao para alteracao de agendamentos
User Function WMSV005F()
	// variavel de controle
	local _lRet := .t.
	// opcao da confirmacao da tela
	local _nOpcSel := 0
	// recno para atualizacao
	local _nRegAtu := SZY->( Recno() )
	// campos que serao alterados na tela
	local _aCposAlt := {"ZY_DTINIC", "ZY_HRINIC", "ZY_DTFINAL", "ZY_HRFINAL", "ZY_TRANSP", "ZY_PLACA", "ZY_MOTORIS", "ZY_OBSERV"}
	// status atual
	local _cStsAtual := IIf(SZY->ZY_STATUS=="R", "Realizado", "Cancelado")
	// data e hora atual
	local _dDtInic := SZY->ZY_DTINIC
	local _cHrInic := SZY->ZY_HRINIC

	// verifica o status do registro atual
	If (_lRet) .and. (SZY->ZY_STATUS != "A")
		// mensagem
		Aviso("TWMV005 -> WMSV005F","Este agendamento não permite alteração pois seu status é " + _cStsAtual + ".",{"Fechar"})
		// variavel de controle
		_lRet := .f.
	EndIf

	// chama rotina padrao de alteracao de dados
	If (_lRet)
		// tela padrao de alteracao de dados
		_nOpcSel := AxAltera("SZY", _nRegAtu, 4, Nil, _aCposAlt, Nil, Nil, "U_WMSV005E(.f.)")
	EndIf

	// esta esta ok, e foi confirmado, atualiza dados
	If (_lRet) .and. (_nOpcSel == 1)
		// define o tempo do agendamento em relacao ao inicio da operacao
		If (_dDtInic != SZY->ZY_DTINIC) .or. (_cHrInic != SZY->ZY_HRINIC)
			RecLock("SZY")
			SZY->ZY_TPAGEND := sfRetTpAge(SZY->ZY_DTINIC, SZY->ZY_HRINIC)
			MsUnLock()
		EndIf
		// insere o log da transação para registro
		U_FtGeraLog( cFilAnt, "SZY", xFilial("SZY") + SZY->ZY_SEQUENC, "Alteração de Agendamento", "WMS" )
	EndIf

Return(_lRet)

// ** funcao para exclusao de agendamentos
User Function WMSV005G()
	// variavel de controle
	local _lRet := .t.
	// opcao da confirmacao da tela
	local _nOpcSel := 0
	// recno para atualizacao
	local _nRegAtu := SZY->( Recno() )
	// status atual
	local _cStsAtual := IIf(SZY->ZY_STATUS=="R", "Realizado", "Cancelado")

	// verifica o status do registro atual
	If (_lRet) .and. (SZY->ZY_STATUS != "A")
		// mensagem
		Aviso("TWMV005 -> WMSV005G","Este agendamento não permite exclusão pois seu status é " + _cStsAtual + ".",{"Fechar"})
		// variavel de controle
		_lRet := .f.
	EndIf

	// chama rotina padrao de exclusao de dados
	If (_lRet)
		// tela padrao de exclusao de dados
		_nOpcSel := AxDeleta("SZY", _nRegAtu, 6)
	EndIf

	// esta esta ok, e foi confirmado, gera log
	If (_lRet) .and. (_nOpcSel == 2)
		// insere o log da transação para registro
		U_FtGeraLog( cFilAnt, "SZY", xFilial("SZY") + SZY->ZY_SEQUENC, "Exclusão de Agendamento", "WMS" )
	EndIf

Return(_lRet)

// ** funcao para cancelar de agendamentos
User Function WMSV005H()
	// variavel de controle
	local _lRet := .t.
	// opcao da confirmacao da tela
	local _nOpcSel := 0
	// recno para atualizacao
	local _nRegAtu := SZY->( Recno() )
	// campos que serao alterados na tela
	local _aCposAlt := {}
	// status atual
	local _cStsAtual := IIf(SZY->ZY_STATUS=="R", "Realizado", "Cancelado")
	// query
	local _cQuery := ""

	// seek
	local _cSeekZ43

	// motivo do cancelamento
	private _cMotCanc := Space(100)

	// verifica o status do registro atual
	If (_lRet) .And. (SZY->ZY_STATUS != "A")
		// mensagem
		Aviso("TWMV005 -> WMSV005H","Este agendamento não permite cancelamento pois seu status é " + _cStsAtual + ".",{"Fechar"})
		// variavel de controle
		_lRet := .f.
	EndIf

	// verifica se já gerou OS de expedição para o agendamento (significa que já iniciou)
	If (_lRet)
		_cQuery := "SELECT Z43_NUMOS "
		_cQuery += " FROM " + RetSqlTab("Z43") + " (nolock) "
		_cQuery += " WHERE " + RetSqlCond("Z43")
		_cQuery += "        AND Z43_SEQAGE = '" + SZY->ZY_SEQUENC + "'"
		_cQuery += "        AND Z43_NUMOS != ''"

		// jogo o resultado da query para a variavel pra analisar se está correto
		_cQuery := U_FtQuery(_cQuery)

		If !(Empty(_cQuery))
			Aviso("TWMV005 -> WMSV005H","Este agendamento não permite cancelamento pois já foi gerada e iniciada a OS de expedição " + _cQuery + " para ele!",{"Fechar"})

			// variavel de controle
			_lRet := .f.
		EndIf

	EndIf

	// chama rotina padrao de alteracao de dados
	If (_lRet)
		// tela padrao de alteracao de dados
		_nOpcSel := AxAltera("SZY", _nRegAtu, 4, Nil, _aCposAlt, Nil, Nil, "U_WMSV005E(.t.)", "RecLock('SZY',.f.), SZY->ZY_STATUS := 'C', MsUnLock()")
	EndIf

	// esta esta ok, e foi confirmado, atualiza dados
	If (_lRet) .and. (_nOpcSel == 1)

		// atualiza status do planejamento do carregamento
		If (SZY->ZY_OPERACA == "02")

			// planejamento do carregamento
			dbSelectArea("Z43")
			Z43->( dbSetOrder(5) ) // 5 - Z43_FILIAL, Z43_SEQAGE
			If Z43->( dbSeek( _cSeekZ43 := xFilial("Z43") + SZY->ZY_SEQUENC ) )

				// varre todos os itens do planejamento
				While Z43->( ! Eof() ) .And. ((Z43->Z43_FILIAL + Z43->Z43_SEQAGE) == _cSeekZ43)

					// atualiza campo de controle
					RecLock("Z43")
					Z43->(DbDelete())
					Z43->(MsUnLock())

					// proximo item
					Z43->( dbSkip() )
				EndDo

			EndIf
		EndIf

		// insere o log da transação para registro
		U_FtGeraLog( cFilAnt, "SZY", xFilial("SZY") + SZY->ZY_SEQUENC, "Cancelamento de Agendamento. Motivo: " + _cMotCanc , "WMS" )

	EndIf

Return(_lRet)

//** funcao que define o tipo de agendamento
Static Function sfRetTpAge(mvDtInic, mvHrInic)
	// tipos de agenda
	//1-AGEND. PONTUAL
	//2-AGEND. ATRASADO
	//3-ENCAIXE
	local _cRet := "1"
	// tempo entre agendamento
	local _nTempo := fConvHr(A680Tempo(Date(), Left(Time(),5), mvDtInic, mvHrInic),"H")

	// acima de 48 horas - 1-Agend. Pontual
	If (_nTempo > 48)
		_cRet := "1"
		// entre 2 e 48 horas - 2-Agend. Atrasado
	ElseIf (_nTempo > 2).and.(_nTempo <= 48)
		_cRet := "2"
		// até 2 horas - 3-Encaixe
	ElseIf (_nTempo <= 2)
		_cRet := "3"
	EndIf

Return(_cRet)

// ** funcao para planejamento em massa de carregamento de pedidos
User Function WMSV005I

	// grupo de perguntas
	local _cPerg := PadR("WMSV005I", 10)
	local _aPerg := {}

	local _aPedSelect := {}
	local _lIncPlanej := .T.
	local _nX := 0

	// verifica versão do WMS do cliente
	local  _lWmsNovo := (U_FtWmsParam("WMS_VERSAO", "N", 1, .F., "", SZY->ZY_CLIENTE, SZY->ZY_LOJA, Nil, Nil) == 2)

	// armazena opcoes do menu
	Local _aRotBack := aClone( aRotina )

	// alias do arquivo temporario
	private _cNewAlias := GetNextAlias()
	private _cArqTmp

	// valida tipo de operacao para planejar carregamento
	If (SZY->ZY_OPERACA != "02")
		// avisa usuario
		Help( Nil, Nil, 'TWMSV005.F01.001', Nil, "Opção não disponível para este tipo de operação.", 1, 0, Nil, Nil, Nil, Nil, Nil, {"Utilizar somente para processos de expedição."})
		// retorno
		Return( .F. )
	EndIf

	// valida status de operacao para planejar carregamento
	If (SZY->ZY_STATUS != "A")
		// avisa usuario
		Help( Nil, Nil, 'TWMSV005.F01.002', Nil, "Opção não disponível. Operação já realizada ou cancelada.", 1, 0, Nil, Nil, Nil, Nil, Nil, {"Utilizar somente para processos com status Agendado."})
		// retorno
		Return( .F. )
	EndIf

	// versão 1.0 - OS criada já no momento inicial
	if !(_lWmsNovo)

		// funcao que busca planejamento de carga do agendamento
		_aPedSelect := sfCargaAge(SZY->ZY_SEQUENC)

		// se ainda não teve pedidos selecionados
		If (Len(_aPedSelect) == 0)
			// solicita selecionar os pedido com OS já existente para amarrar ao agendamento
			If ( ! sfDefDadAdic(SZY->ZY_OPERACA, SZY->ZY_PROCES, SZY->ZY_ITPROC, SZY->ZY_CLIENTE, SZY->ZY_LOJA, @_aPedSelect, .F.))
				Return( .F. )
			EndIf
		Else
			Alert("Pedidos/OS já selecionados para este CESV.")
		EndIf
		// cria tabela Z43 com os pedidos selecionados no array

		/* Composição do vetor _aPedSelect
		1-Z05_NUMOS
		2-C9_CARGA
		3-C9_PEDIDO
		4-C5_ZPEDCLI
		5-C5_ZAGRUPA
		6-C5_CLIENTE
		7-C5_LOJACLI
		*/

		// varro o array e salvo os dados
		For _nX := 1 to Len(_aPedSelect)

			// reinicia variavel
			_lIncPlanej := .T.

			// verifica se pedido já existe, para saber se vai incluir ou alterar
			dbselectArea("Z43")
			Z43->(dbSetOrder( 5 )) // 5 - Z43_FILIAL, Z43_SEQAGE, Z43_PEDIDO
			If ( Z43->(dbSeek( xFilial("Z43") + SZY->ZY_SEQUENC + _aPedSelect[_nX, 3] )) )
				_lIncPlanej := .F.
			EndIf

			// atualizacao de dados
			Reclock("Z43", _lIncPlanej)
			// campos para inclusao
			If (_lIncPlanej)
				Z43->Z43_FILIAL := xFilial("Z43")
				Z43->Z43_NUMOS  := _aPedSelect[_nX, 1]
				Z43->Z43_CARGA  := _aPedSelect[_nX, 2]
				Z43->Z43_PEDIDO := _aPedSelect[_nX, 3]
				Z43->Z43_CLIENT := _aPedSelect[_nX, 6]
				Z43->Z43_LOJA   := _aPedSelect[_nX, 7]
				Z43->Z43_PEDCLI := _aPedSelect[_nX, 4]
				Z43->Z43_STATUS := "P" // P-PLANEJADO | C-CANCELADO | R-REALIZADO
				Z43->Z43_AGRUPA := _aPedSelect[_nX, 5]
				Z43->Z43_DATA   := Date()
				Z43->Z43_HORA   := Time(0)
				Z43->Z43_SEQAGE := SZY->ZY_SEQUENC
			EndIf

			// confirma gravacao de dados
			Z43->(MsUnlock())
		Next _nX
	else
		// versão 2.0 - por onda

		// define grupo de perguntas/parametros
		aAdd(_aPerg,{"Pedido TECADI De"  , "C", TamSx3("C5_NUM")[1]    , 0, "G", Nil, ""   , {{"X1_VALID","U_FtStrZero()"}} }) //mv_par01
		aAdd(_aPerg,{"Pedido TECADI Até" , "C", TamSx3("C5_NUM")[1]    , 0, "G", Nil, ""   , {{"X1_VALID","U_FtStrZero()"}} }) //mv_par02
		aAdd(_aPerg,{"Pedido CLIENTE De" , "C", TamSx3("C5_ZPEDCLI")[1], 0, "G", Nil, ""   , Nil                            }) //mv_par03
		aAdd(_aPerg,{"Pedido CLIENTE Até", "C", TamSx3("C5_ZPEDCLI")[1], 0, "G", Nil, ""   , Nil                            }) //mv_par04
		aAdd(_aPerg,{"Nota Venda De"     , "C", TamSx3("F2_DOC")[1]    , 0, "G", Nil, ""   , Nil                            }) //mv_par05
		aAdd(_aPerg,{"Nota Venda Até"    , "C", TamSx3("F2_DOC")[1]    , 0, "G", Nil, ""   , Nil                            }) //mv_par06
		aAdd(_aPerg,{"Data Emissão Até"  , "D", TamSx3("C5_EMISSAO")[1], 0, "G", Nil, ""   , Nil                            }) //mv_par07
		aAdd(_aPerg,{"Data Emissão Até"  , "D", TamSx3("C5_EMISSAO")[1], 0, "G", Nil, ""   , Nil                            }) //mv_par08
		aAdd(_aPerg,{"Data Entrega De"   , "D", TamSx3("C5_EMISSAO")[1], 0, "G", Nil, ""   , Nil                            }) //mv_par09
		aAdd(_aPerg,{"Data Entrega Até"  , "D", TamSx3("C5_EMISSAO")[1], 0, "G", Nil, ""   , Nil                            }) //mv_par10
		aAdd(_aPerg,{"Prioridade De"     , "C", TamSx3("Z50_PRIORI")[1], 0, "G", Nil, ""   , Nil                            }) //mv_par11
		aAdd(_aPerg,{"Prioridade Até"    , "C", TamSx3("Z50_PRIORI")[1], 0, "G", Nil, ""   , Nil                            }) //mv_par12
		aAdd(_aPerg,{"Transportadora De" , "C", TamSx3("A4_COD")[1]    , 0, "G", Nil, "SA4", {{"X1_VALID","U_FtStrZero()"}} }) //mv_par13
		aAdd(_aPerg,{"Transportadora Até", "C", TamSx3("A4_COD")[1]    , 0, "G", Nil, "SA4", {{"X1_VALID","U_FtStrZero()"}} }) //mv_par14

		// cria o grupo de perguntas
		U_FtCriaSX1(_cPerg, _aPerg)

		// chama a tela de parametros
		If ( ! Pergunte(_cPerg, .T.) )
			Return( .F. )
		EndIf

		// funcao que atualiza os dados
		sfSelDados()

		// abre a tela com os dados
		sfTelaGeral()

	EndIf

	// ao retornar, atualiza aRotina (menus)
	aRotina := aClone( _aRotBack )

	If ValType(_cArqTmp) == "O"
		_cArqTmp:Delete()
	EndIf

Return( Nil )

// ** funcao que carrega os dados dos pedidos
Static Function sfSelDados()

	// estrutura do arquivo de trabalho
	local _aStrTrbCarga := {}

	// query para filtro de dados
	local _cQuery

	// cria o arquivo de trabalho
	If (Select(_cNewAlias) == 0)

		// cria o arquivo de trabalho para o MarkBrowse
		aAdd(_aStrTrbCarga,{"IT_OK"    , "C", TamSx3("C5_OK")[1]     , 0})
		aAdd(_aStrTrbCarga,{"IT_CARGA" , "C", TamSx3("C9_CARGA")[1]  , 0})
		aAdd(_aStrTrbCarga,{"IT_PEDIDO", "C", TamSx3("C5_NUM")[1]    , 0})
		aAdd(_aStrTrbCarga,{"IT_PEDCLI", "C", TamSx3("C5_ZPEDCLI")[1], 0})
		aAdd(_aStrTrbCarga,{"IT_AGRUPA", "C", TamSx3("C5_ZAGRUPA")[1], 0})
		aAdd(_aStrTrbCarga,{"IT_DOCCLI", "C", TamSx3("C5_ZDOCCLI")[1], 0})
		aAdd(_aStrTrbCarga,{"IT_PRIORI", "C", TamSx3("Z50_PRIORI")[1], 0})
		aAdd(_aStrTrbCarga,{"IT_CODCLI", "C", TamSx3("C5_CLIENTE")[1], 0})
		aAdd(_aStrTrbCarga,{"IT_LOJCLI", "C", TamSx3("C5_LOJACLI")[1], 0})

		// criar um arquivo de trabalho
		_cArqTmp := FWTemporaryTable():New( _cNewAlias )
		_cArqTmp:SetFields( _aStrTrbCarga )
		_cArqTmp:Create()

		// caso o arquivo exista, limpa os dados
	ElseIf (Select(_cNewAlias) <> 0)
		// limpa o conteudo do TRB
		(_cNewAlias)->(dbSelectArea(_cNewAlias))
		(_cNewAlias)->(__DbZap())

	EndIf

	// prepara query para filtro de dados
	_cQuery := " SELECT DISTINCT '  '       AS IT_OK, "
	//	_cQuery := " SELECT DISTINCT (Case When (SELECT top 1 Z43_PEDIDO "
	//	_cQuery += "	FROM "+RetSQLName("Z43")+" Z43 "
	//	_cQuery += "	WHERE   Z43_FILIAL = '103' AND Z43.D_E_L_E_T_ = ' ' AND Z43_PEDIDO = C5_NUM AND Z43_STATUS IN ( 'P', 'R' )) = C5_NUM then 'XX' Else '  ' end ) AS IT_OK, "
	_cQuery += "                 C9_CARGA   AS IT_CARGA, "
	_cQuery += "                 C9_PEDIDO  AS IT_PEDIDO, "
	_cQuery += "                 C5_ZPEDCLI AS IT_PEDCLI, "
	_cQuery += "                 C5_ZAGRUPA AS IT_AGRUPA, "
	_cQuery += "                 C5_ZDOCCLI AS IT_DOCCLI, "
	_cQuery += "                 C5_CLIENTE AS IT_CODCLI, "
	_cQuery += "                 C5_LOJACLI AS IT_LOJCLI "
	// pedido de venda
	_cQuery += " FROM   " + RetSqlTab("SC5") + " (nolock) "
	// liberacao dos itens do pedido de venda
	_cQuery += "        INNER JOIN " + RetSqlTab("SC9") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("SC9")
	_cQuery += "                   AND C9_PEDIDO = C5_NUM "
	_cQuery += "                   AND C9_CARGA != ' ' "
	If (!_lCESVSemNf)
		// não permite planejar o CESV sem nota
		_cQuery += "                   AND C9_NFISCAL != ' ' "
	Endif
	// filtro padrao
	_cQuery += " WHERE  " + RetSqlCond("SC5")
	// cliente e loja
	_cQuery += "        AND C5_CLIENTE = '" + SZY->ZY_CLIENTE + "' AND C5_LOJACLI = '" + SZY->ZY_LOJA + "' "
	// filtra pedidos que ainda não tiveram a OS finalizada (sequencia 02 conferencia/montagem)
	_cQuery += "        AND (SELECT Z06_STATUS FROM " + RetSqlTab("Z06") + " (NOLOCK) WHERE " + RetSqlCond("Z06") + " AND Z06_SEQOS = '002' AND Z06_NUMOS = C5_ZNOSMNT) = 'FI'"
	// tipo de operacao
	_cQuery += "        AND C5_TIPOOPE = 'P' "
	// data de emissao
	_cQuery += "        AND C5_EMISSAO BETWEEN '" + DtoS(mv_par07) + "' AND '" + DtoS(mv_par08) + "' "
	// pedido TECADI
	_cQuery += "        AND C5_NUM BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' "
	// pedido CLIENTE
	_cQuery += "        AND C5_ZPEDCLI BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "' "
	// que nao foi carregado
	_cQuery += "        AND C5_ZCARREG != 'S' "
	If (!_lCESVSemNf)
		// montagem de volumes
		_cQuery += "        AND C5_ZMNTVOL = 'S' "
		// emissao de nota de retorno
		_cQuery += "        AND C5_NOTA != ' ' "
	Endif
	// nota fiscal do cliente
	_cQuery += "        AND C5_ZDOCCLI BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
	// transportadora
	_cQuery += "        AND C5_TRANSP BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "' "
	// que nao esteja em outro planejamento -> Comentado pois deve trazer os registros no browser
	_cQuery += "        AND NOT EXISTS (SELECT * "
	_cQuery += "                        FROM   " + RetSqlTab("Z43") + " (nolock) "
	_cQuery += "                        WHERE  " + RetSqlCond("Z43")
	_cQuery += "                               AND Z43_PEDIDO = C5_NUM "
	_cQuery += "                               AND Z43_STATUS IN ( 'P', 'R' )) "

	// traz os pedidos já inseridos neste agendamento anteriormente
	_cQuery += " UNION ALL                                         "
	_cQuery += " SELECT DISTINCT 'XX'       AS IT_OK,              "
	_cQuery += "                 Z43_CARGA   AS IT_CARGA,          "
	_cQuery += "                 Z43_PEDIDO  AS IT_PEDIDO,         "
	_cQuery += "                 Z43_PEDCLI AS IT_PEDCLI,          "
	_cQuery += "                 Z43_AGRUPA AS IT_AGRUPA,          "
	_cQuery += "                 C5_ZDOCCLI AS IT_DOCCLI,          "
	_cQuery += "                 Z43_CLIENT AS IT_CODCLI,          "
	_cQuery += "                 Z43_LOJA AS IT_LOJCLI             "
	_cQuery += " FROM   " + RetSqlTab("Z43") + " (nolock) "
	_cQuery += "        INNER JOIN " + RetSqlTab("SC5") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("SC5")
	_cQuery += "                   AND Z43_PEDIDO = SC5.C5_NUM     "
	_cQuery += "                   AND Z43_CLIENT = SC5.C5_CLIENT  "
	_cQuery += " 				   AND Z43_LOJA   = SC5.C5_LOJACLI "
	_cQuery += " WHERE " + RetSqlCond("Z43")
	_cQuery += "        AND Z43_CLIENT = '" + SZY->ZY_CLIENTE + "' "
	_cQuery += "        AND Z43_LOJA   = '" + SZY->ZY_LOJA    + "' "
	_cQuery += "        AND Z43_SEQAGE = '" + SZY->ZY_SEQUENC + "' "

	// ordem dos dados
	_cQuery += " ORDER  BY IT_OK DESC, C5_ZDOCCLI "

	MemoWrit("c:\query\TWMSV005_sfSelDados.txt", _cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery, _aStrTrbCarga, _cNewAlias)

Return

// ** funcao que monta tela (browse) com a relacao de pedidos
Static Function sfTelaGeral()

	// campos do browse
	local _aHeadBrw := {}
	// legenda
	local _aCorLegenda := {}

	// variaveis para o MarkBrowse
	//Private _cTrbFlag := GetMark()
	Private _cTrbFlag := "XX" // Alterado para uma marcação fixa no browser, assim facilita o tratamento dos registros por query

	// opcoes do menus
	Private aRotina := {;
	{ "Gravar Planejamento", "U_WMSV005J(), CloseBrowse()", 0 , 3} }

	// inclui detalhes e titulos dos campos do browse
	aAdd(_aHeadBrw,{"IT_OK"    , Nil,"  "                  , ""})
	aAdd(_aHeadBrw,{"IT_DOCCLI", Nil,"Nr.Nota Fiscal Venda", ""})
	aAdd(_aHeadBrw,{"IT_PEDCLI", Nil,"Nr.Pedido Cliente"   , ""})
	aAdd(_aHeadBrw,{"IT_PEDIDO", Nil,"Nr.Pedido TECADI"    , ""})

	// adiciona as cores da legenda
	//aAdd(_aCorLegenda,{"((_cNewAlias)->IT_PRIORI == '001')", "BR_AZUL"   })
	//aAdd(_aCorLegenda,{"((_cNewAlias)->IT_PRIORI == '002')", "BR_AMARELO"})
	//aAdd(_aCorLegenda,{"((_cNewAlias)->IT_PRIORI == '003')", "ENABLE"    })
	//aAdd(_aCorLegenda,{"((_cNewAlias)->IT_PRIORI == '004')", "DISABLE"   })

	// seleciona o arquivo de trabalho
	(_cNewAlias)->(dbSelectArea(_cNewAlias))
	(_cNewAlias)->(dbGotop())

	// mark browse com os itens a faturar
	(_cNewAlias)->(MarkBrow(_cNewAlias, "IT_OK", Nil, _aHeadBrw, Nil, _cTrbFlag, "StaticCall(TWMSV005, sfMarkAll)", Nil, Nil, Nil, Nil, Nil, Nil, Nil )) //, _aCorLegenda)

	// seleciona o arquivo de trabalho
	(_cNewAlias)->(dbSelectArea(_cNewAlias))
	(_cNewAlias)->(dbCloseArea())

Return( .T. )

// ** funcao que marca todos os itens quando clicar no header da coluna
Static Function sfMarkAll()

	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaTrb := (_cNewAlias)->(GetArea())

	// seleciona alias do aruivo de trabalho
	(_cNewAlias)->(DbSelectArea(_cNewAlias))
	(_cNewAlias)->(dbGoTop())

	// varre todos os itens do arquivo de trabalho
	While (_cNewAlias)->( ! Eof() )
		// attualiza campo de controle
		(_cNewAlias)->(RecLock(_cNewAlias, .F.))
		(_cNewAlias)->IT_OK := IIf((_cNewAlias)->IT_OK == _cTrbFlag, "", _cTrbFlag )
		(_cNewAlias)->(MsUnLock())
		// proximo item
		(_cNewAlias)->(DbSkip())
	EndDo

	// refresj no browse
	MarkBRefresh()

	// restaura area inicial
	RestArea(_aAreaTrb)
	RestArea(_aAreaAtu)

Return( .T. )

// ** funcao geral responsavel por atualizar os pedidos por agendamento
User Function WMSV005J

	// dados atualizados
	local _lDadosOk := .F.

	// seleciona alias do aruivo de trabalho
	(_cNewAlias)->(DbSelectArea(_cNewAlias))
	(_cNewAlias)->(dbGoTop())

	// varre todos os itens do arquivo de trabalho
	While (_cNewAlias)->( ! Eof() )
		// verifica se o item esta selecionado
		If ((_cNewAlias)->IT_OK == _cTrbFlag)

			// Grava na Z43 se não existir
			DbSelectArea("Z43")
			Z43->(dbSetOrder( 5 )) // 5 - Z43_FILIAL, Z43_SEQAGE, Z43_PEDIDO
			If !( Z43->(dbSeek( xFilial("Z43") + SZY->ZY_SEQUENC + (_cNewAlias)->IT_PEDIDO )))

				// varro o array e salvo os dados
				dbselectArea("Z43")
				Reclock("Z43", .T.)
				Z43->Z43_FILIAL := xFilial("Z43")
				Z43->Z43_CARGA  := (_cNewAlias)->IT_CARGA
				Z43->Z43_PEDIDO := (_cNewAlias)->IT_PEDIDO
				Z43->Z43_CLIENT := (_cNewAlias)->IT_CODCLI
				Z43->Z43_LOJA   := (_cNewAlias)->IT_LOJCLI
				Z43->Z43_PEDCLI := (_cNewAlias)->IT_PEDCLI
				Z43->Z43_STATUS := "P" // P-PLANEJADO | C-CANCELADO | R-REALIZADO
				Z43->Z43_AGRUPA := (_cNewAlias)->IT_AGRUPA
				Z43->Z43_DATA   := Date()
				Z43->Z43_HORA   := Time()
				Z43->Z43_SEQAGE := SZY->ZY_SEQUENC
				Z43->(MsUnlock())

				// atualizacao de dados
				_lDadosOk := .T.
			EndIf
		Else
			// Exclui o registro caso o pedido for desmarcado no browser
			DbSelectArea("Z43")
			Z43->(dbSetOrder( 5 )) // 5 - Z43_FILIAL, Z43_SEQAGE, Z43_PEDIDO
			If ( Z43->(dbSeek( xFilial("Z43") + SZY->ZY_SEQUENC + (_cNewAlias)->IT_PEDIDO )))
				RecLock("Z43")
				Z43->(dbDelete())
				Z43->(MsUnLock())
			EndIf
		EndIf

		// proximo item
		(_cNewAlias)->(DbSkip())
	EndDo

	// apresenta mensagem
	If ( _lDadosOk )
		MsgInfo("Planejamento realizado com sucesso!")
	EndIf

Return( _lDadosOk )

//** função para escolher os pedidos e OS para clientes no formato WMS 1.0
Static Function sfDefDadAdic(mvCodOpe, mvNrProc, mvItProc, mvCodCli, mvLojCli, mvPedSelect, mvSemAgenda)

	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"SZZ","SZY","SC5"})
	// controle de confirmacao
	Local _lRet := .f.
	Local _cQuery
	// estrutura do arquivo de trabalho
	Local _aEstruTrb := {}
	// campo do browse
	Local _aCmpBrw := {}
	// objeto TMP
	Local _cArqTrb
	// arquivo TMP
	Local _TRBDADADIC := GetNextAlias()
	// select do browse
	local _cMarcaBrw := GetMark()

	// validação para controle de volume
	Private _lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME", "L", .f., .f., Nil, mvCodCli, mvLojCli, Nil, Nil)
	// validação para entrada de caminhão sem NF emitida
	Private _lCESVSemNf := U_FtWmsParam("WMS_LIBERA_CARREGAMENTO_SEM_NF", "L", .f., .f., Nil, mvCodCli, mvLojCli, Nil, Nil)
	// permite o carregamento sem a nota fiscal de venda do cliente
	private _lSemNfVend := U_FtWmsParam("WMS_LIBERA_CARREGAMENTO_SEM_NF_VENDA", "L", .f., .f., "", mvCodCli, mvLojCli, Nil, Nil)

	// default do valor
	default mvSemAgenda := .f.

	// campos do arquivo de trabalho

	// seleciona
	aAdd(_aEstruTrb,{"IT_OK"      ,"C",2,0})
	// numos
	aAdd(_aEstruTrb,{"Z05_NUMOS"  ,"C",TamSx3("Z05_NUMOS")[1],0})
	// carga
	aAdd(_aEstruTrb,{"C9_CARGA"   ,"C",TamSx3("C9_CARGA")[1],0})
	// pedido
	aAdd(_aEstruTrb,{"C9_PEDIDO"  ,"C",TamSx3("C9_PEDIDO")[1],0})
	// pedido do cliente
	aAdd(_aEstruTrb,{"C5_ZPEDCLI" ,"C",TamSx3("C5_ZPEDCLI")[1],0})
	// agrupadora do cliente
	aAdd(_aEstruTrb,{"C5_ZAGRUPA" ,"C",TamSx3("C5_ZAGRUPA")[1],0})
	// documento/nota do cliente
	aAdd(_aEstruTrb,{"C5_ZDOCCLI" ,"C",TamSx3("C5_ZDOCCLI")[1],0})
	// codigo cliente
	aAdd(_aEstruTrb,{"C5_CLIENTE" ,"C",TamSx3("C5_CLIENTE")[1],0})
	// loja cliente
	aAdd(_aEstruTrb,{"C5_LOJACLI" ,"C",TamSx3("C5_LOJACLI")[1],0})

	// verifica se o TRB existe
	If Select(_TRBDADADIC)<>0
		dbSelectArea(_TRBDADADIC)
		dbCloseArea()
	EndIf

	// criar um arquivo de trabalho
	_cArqTrb := FWTemporaryTable():New( _TRBDADADIC )
	_cArqTrb:SetFields( _aEstruTrb )
	_cArqTrb:Create()

	// monta a query para filtro dos dados

	_cQuery := " SELECT DISTINCT '  ' IT_OK, Z05_NUMOS, C9_CARGA, C9_PEDIDO, C5_ZPEDCLI, C5_ZAGRUPA, C5_ZDOCCLI, C5_CLIENTE, C5_LOJACLI "
	// pedidos de venda
	_cQuery += " FROM " + RetSqlTab("SC5") + " (NOLOCK) "
	// itens liberados do pedido
	_cQuery += " INNER JOIN " + RetSqlTab("SC9") + " (NOLOCK) ON " + RetSqlCond("SC9") + " AND C9_PEDIDO = C5_NUM "
	// OS por carga
	_cQuery += " INNER JOIN " + RetSqlTab("Z05") + " (NOLOCK) ON "+RetSqlCond("Z05")+" AND Z05_CARGA = C5_ZCARGA "
	// filtro do pedido de venda
	_cQuery += " WHERE " + RetSqlCond("SC5")

	// se for sem agenda, trás os pedidos disponíveis para o usuário selecionar
	If ( ! mvSemAgenda )
		_cQuery += " AND C5_CLIENTE = '" + mvCodCli + "' AND C5_LOJACLI = '" + mvLojCli + "' "
	EndIf

	// filtra pedidos que ainda não tiveram a OS finalizada (sequencia 02 conferencia/montagem)
	_cQuery += " AND (SELECT Z06_STATUS FROM " + RetSqlTab("Z06") + " (NOLOCK) WHERE " + RetSqlCond("Z06") + " AND Z06_SEQOS = '002' AND Z06_NUMOS = C5_ZNOSMNT) = 'FI'"

	// tipo do pedido
	_cQuery += " AND C5_TIPOOPE = 'P' "

	// carga não pode estar em branco
	_cQuery += " AND C5_ZCARGA != '' "

	// data de corte para nova rotina
	_cQuery += " AND C5_EMISSAO >= '20150715' "

	// não pode ter sido carregado ainda
	_cQuery += "  AND C5_ZCARREG != 'S' "

	// parâmetros específicos para controle de volume
	If (_lCtrVolume)
		// com volumes já montados
		_cQuery += " AND C5_ZMNTVOL = 'S' "
	EndIf

	// documento/nf do cliente ja informado
	If ( ! _lSemNfVend )
		_cQuery += " AND C5_ZDOCCLI != ' ' "
	EndIf

	// se já teve nota gerada
	If ( ! _lCESVSemNf )
		_cQuery += "  AND C5_NOTA != '' "
	EndIf

	// não pode ter status Planejado nem Realizado na Z43
	_cQuery += "  AND NOT EXISTS ( "
	_cQuery += "  SELECT * FROM " + RetSqlTab("Z43")
	_cQuery += "  WHERE " + RetSqlCond("Z43")
	_cQuery += "  AND Z43_PEDIDO = C5_NUM "
	_cQuery += "  AND Z43_STATUS IN ( 'P','R' ) "
	_cQuery += " ) "
	// ordem dos dados
	_cQuery += " ORDER BY C9_CARGA "

	// gravo query para consulta ou debug
	memowrit("C:\query\TWMSV005_sfdefda.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQuery,_aEstruTrb,_TRBDADADIC)

	// verifica os dados
	(_TRBDADADIC)->(dbSelectArea(_TRBDADADIC))
	(_TRBDADADIC)->(dbGoTop())

	// verifica se há programacoes para visualizar
	If ((_TRBDADADIC)->(RecCount())==0)
		// mensagem para usuario
		U_FtWmsMsg("Não há programações/cargas disponíveis!","ATENCAO")
		// fecha arquivo de trabalho
		If (Select(_TRBDADADIC)<>0)
			(_TRBDADADIC)->(dbSelectArea(_TRBDADADIC))
			(_TRBDADADIC)->(dbCloseArea())
		EndIf
		// restaura area inicial
		RestOrd(_aAreaIni)
		RestArea(_aAreaAtu)
		Return(.f.)
	EndIf

	// alimenta o header

	// seleciona
	aAdd(_aCmpBrw,{"IT_OK"      ,"@!", " "})
	// Número da OS
	aAdd(_aCmpBrw,{"Z05_NUMOS"  ,PesqPict("Z05","Z05_NUMOS"), "Num.OS"})
	// Carga
	aAdd(_aCmpBrw,{"C9_CARGA"   ,PesqPict("SC9","C9_CARGA"),  "Carga"})
	// Pedido
	aAdd(_aCmpBrw,{"C9_PEDIDO"  ,PesqPict("SC9","C9_PEDIDO"), "Pedido"})
	// Pedido do Cliente
	aAdd(_aCmpBrw,{"C5_ZPEDCLI" ,PesqPict("SC5","C5_ZPEDCLI"), "Ped.Cli"})
	// Agrupadora do Cliente
	aAdd(_aCmpBrw,{"C5_ZAGRUPA" ,PesqPict("SC5","C5_ZAGRUPA"), "Agrupadora"})
	// documento/nota fiscal do cliente
	aAdd(_aCmpBrw,{"C5_ZDOCCLI" ,PesqPict("SC5","C5_ZDOCCLI"), "Doc. Cliente"})

	// monta o dialogo
	oDlgProgRec := MSDialog():New(000,000,400,800,"Programação de Recebimentos/Cargas",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho
	oPnlCabec := TPanel():New(000,000,nil,oDlgProgRec,,.F.,.F.,,,000,020,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// botao para detahes do dia
	oBtnProgDet := TButton():New(005,005,"Confirmar",oPnlCabec,{|| _lRet := (mvCodOpe != "01") .Or. (MsgYesNo("Confirma utilização do processo " + (_TRBDADADIC)->Z1_CODIGO + "/" + (_TRBDADADIC)->Z2_ITEM + " ?", "Confirmação")) , oDlgProgRec:End() },060,010,,,,.T.,,"",,,,.F. )
	// botao pra fechar
	oBtnProgSair := TButton():New(005,070,"Fechar",oPnlCabec,{||oDlgProgRec:End()},060,010,,,,.T.,,"",,,,.F. )

	// browse com a listagem das programacoes/cargas disponiveis
	oBrwProgRec := MsSelect():New(_TRBDADADIC, IIF(mvCodOpe=="02","IT_OK",Nil),, _aCmpBrw,, _cMarcaBrw, {15,1,183,373})
	// tela cheia
	oBrwProgRec:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG oDlgProgRec CENTERED

	If (_lRet)
		// preencho a variável que levará todos os dados selecionados pra fora da função
		(_TRBDADADIC)->( dbGotop() )

		While (_TRBDADADIC)->( ! EOF() )
			// caso o registro esteja selecionado, inclui no array
			If ( (_TRBDADADIC)->IT_OK == _cMarcaBrw )

				// registros sendo adicionados no array
				aAdd( mvPedSelect, { (_TRBDADADIC)->Z05_NUMOS, (_TRBDADADIC)->C9_CARGA, (_TRBDADADIC)->C9_PEDIDO, (_TRBDADADIC)->C5_ZPEDCLI, (_TRBDADADIC)->C5_ZAGRUPA, (_TRBDADADIC)->C5_CLIENTE, (_TRBDADADIC)->C5_LOJACLI } )

				// para quando não houver agenda, atualiza os dados do cliente e loja
				If ( mvSemAgenda )
					mvCodCli := (_TRBDADADIC)->C5_CLIENTE
					mvLojCli := (_TRBDADADIC)->C5_LOJACLI
				EndIf

			EndIf
			// proximo item
			(_TRBDADADIC)->( dbSkip() )
		EndDo

		// valido se algum campo for selecionado
		If ( Len(mvPedSelect) == 0 )
			// avisa o usuário
			MsgAlert( "É preciso selecionar pelo menos um registro.", "Info" )
			// variavel de retorno
			_lRet := .F.
		EndIf
	EndIf

	// restaura area inicial
	RestOrd(_aAreaIni)
	RestArea(_aAreaAtu)

	If ValType(_cArqTrb) == "O"
		_cArqTrb:Delete()
	EndIf

Return(_lRet)

// ** funcao que busca pedidos já existentes para agendamento
Static Function sfCargaAge(mvSeqAgend)
	// variavel de retorno
	local _aRetPedSel := {}
	// query
	local _cQuery := ""

	// prepara query
	_cQuery += " SELECT Z43_NUMOS, "
	_cQuery += "        Z43_CARGA, "
	_cQuery += "        Z43_PEDIDO, "
	_cQuery += "        Z43_PEDCLI, "
	_cQuery += "        Z43_AGRUPA, "
	_cQuery += "        Z43_CLIENT, "
	_cQuery += "        Z43_LOJA "
	_cQuery += " FROM   " + RetSqlTab("Z43") + " (nolock) "
	_cQuery += " WHERE  " + RetSqlCond("Z43")
	_cQuery += "        AND Z43_SEQAGE = '" + mvSeqAgend + "' "
	_cQuery += "        AND Z43_STATUS = 'P' "

	// retorna dados
	_aRetPedSel := U_SqlToVet(_cQuery)

Return( _aRetPedSel )