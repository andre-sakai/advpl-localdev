#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Funcoes Genericas utilizadas no modulo WMS              !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/2015                                                 !
+------------------+--------------------------------------------------------*/

// ** funcao que monta uma tela com a relacao da programacao de recebimentos do cliente
User Function FtLstPrg(mvCodCli, mvLojCli)

	Local _cQuery
	// controle de confirmacao
	Local _lRet := .f.
	// estrutura do arquivo de trabalho
	Local _aEstruTrb := {}
	// campo do browse
	Local _aCmpBrw := {}
	// codigo e item da Programacao
	Local _cCodProga := CriaVar("D1_PROGRAM",.f.)
	Local _cIteProga := CriaVar("D1_ITEPROG",.f.)

	// objetos da tela
	local oBtnProgDet, oBtnProgSair, _oBmpRefresh

	// arquivo TMP
	private _cArqTrb
	private _TRBPROG := GetNextAlias()

	// campos do arquivo de trabalho
	aAdd(_aEstruTrb,{"Z1_CODIGO","C",TamSx3("Z1_CODIGO")[1],0})
	aAdd(_aEstruTrb,{"Z2_ITEM","C",TamSx3("Z2_ITEM")[1],0})
	aAdd(_aEstruTrb,{"Z2_DOCUMEN","C",TamSx3("Z2_DOCUMEN")[1],0})
	aAdd(_aEstruTrb,{"Z2_TAMCONT","C",TamSx3("Z2_TAMCONT")[1],0})
	aAdd(_aEstruTrb,{"Z2_TIPCONT","C",20,0})
	aAdd(_aEstruTrb,{"Z2_CONTEUD","C",5,0})
	aAdd(_aEstruTrb,{"Z2_QUANT","N",TamSx3("Z2_QUANT")[1],TamSx3("Z2_QUANT")[2]})
	aAdd(_aEstruTrb,{"Z2_QTDREC","N",TamSx3("Z2_QTDREC")[1],TamSx3("Z2_QTDREC")[2]})

	// verifica se o TRB existe
	If Select(_TRBPROG)<>0
		dbSelectArea(_TRBPROG)
		dbCloseArea()
	EndIf
	// criar um arquivo de trabalho
	_cArqTrb := FWTemporaryTable():New( _TRBPROG )
	_cArqTrb:SetFields( _aEstruTrb )
	_cArqTrb:Create()

	// monta a query para filtro dos dados
	_cQuery := "SELECT Z1_CODIGO, Z2_ITEM, Z2_DOCUMEN, Z2_TAMCONT, "
	// tipo do container
	_cQuery += "X5_DESCRI Z2_TIPCONT, "
	// conteudo
	_cQuery += "CASE WHEN Z2_CONTEUD = 'C' THEN 'CHEIO' ELSE 'VAZIO' END Z2_CONTEUD, "
	_cQuery += "Z2_QUANT, Z2_QTDREC "
	// programacao de recebimento
	_cQuery += "FROM "+RetSqlName("SZ1")+" SZ1 (nolock)  "
	// itens da programacao
	_cQuery += "INNER JOIN "+RetSqlName("SZ2")+" SZ2 (nolock)  ON "+RetSqlCond("SZ2")+" "
	_cQuery += "      AND Z2_CODIGO = Z1_CODIGO "
	// tipo do container
	_cQuery += "INNER JOIN "+RetSqlName("SX5")+" SX5 (nolock)  ON "+RetSqlCond("SX5")+" "
	_cQuery += "      AND X5_TABELA = 'ZA' AND X5_CHAVE = Z2_TIPCONT "
	// filtro da programacao
	_cQuery += "WHERE "+RetSqlCond("SZ1")+" "
	_cQuery += "  AND Z1_CLIENTE = '"+mvCodCli+"' AND Z1_LOJA = '"+mvLojCli+"' "
	// nao esteja encerrada
	_cQuery += "  AND Z1_DTFINFA = ' ' "
	// ordem dos dados
	_cQuery += "ORDER BY Z2_CODIGO, Z2_ITEM"
	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQuery,_aEstruTrb,_TRBPROG)

	// verifica os dados
	(_TRBPROG)->(dbSelectArea(_TRBPROG))
	(_TRBPROG)->(dbGoTop())

	// verifica se há programacoes para visualizar
	If ((_TRBPROG)->(RecCount())==0)
		MsgStop("Não há programações de recebimentos!")
		// fecha arquivo de trabalho
		(_TRBPROG)->(dbSelectArea(_TRBPROG))
		(_TRBPROG)->(__dbZap())

		_lRet := .f.
		Return({_lRet,_cCodProga,_cIteProga})
	EndIf

	// alimenta o header
	aAdd(_aCmpBrw,{"Z1_CODIGO", PesqPict("SZ1","Z1_CODIGO") , "Código"})
	aAdd(_aCmpBrw,{"Z2_ITEM",   PesqPict("SZ2","Z2_ITEM")   , "Item"})
	aAdd(_aCmpBrw,{"Z2_DOCUMEN",PesqPict("SZ2","Z2_DOCUMEN"), "Documento"})
	aAdd(_aCmpBrw,{"Z2_TAMCONT",PesqPict("SZ2","Z2_TAMCONT"), "Tam.Container"})
	aAdd(_aCmpBrw,{"Z2_TIPCONT",PesqPict("SZ2","Z2_TIPCONT"), "Tipo Container"})
	aAdd(_aCmpBrw,{"Z2_CONTEUD",PesqPict("SZ2","Z2_CONTEUD"), "Conteúdo?"})
	aAdd(_aCmpBrw,{"Z2_QUANT",  PesqPict("SZ2","Z2_QUANT")  , "Quantidade"})
	aAdd(_aCmpBrw,{"Z2_QTDREC", PesqPict("SZ2","Z2_QTDREC") , "Qtd.Recebida"})

	// monta o dialogo
	oDlgProgRec := MSDialog():New(000,000,400,800,"Programação de Recebimentos",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho
	oPnlCabec := TPanel():New(000,000,nil,oDlgProgRec,,.F.,.F.,,,000,020,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// botao para detahes do dia
	oBtnProgDet := TButton():New(005,005,"Confirmar",oPnlCabec,{|| _lRet:=.t.,oDlgProgRec:End() },060,010,,,,.T.,,"",,,,.F. )
	// botao pra fechar
	oBtnProgSair := TButton():New(005,070,"Fechar",oPnlCabec,{||oDlgProgRec:End()},060,010,,,,.T.,,"",,,,.F. )

	// botao para atualizar o grid (caso o usuario reabra uma programação com a tela aberta)
	_oBmpRefresh := TBtnBmp2():New(003,760,040,040,"RELOAD",,,,;
	{|| (_TRBPROG)->( __DBZap() ),;
	SqlToTrb(_cQuery,_aEstruTrb,_TRBPROG),;
	oBrwProgRec:oBrowse:Refresh(.F.),;
	oBrwProgRec:oBrowse:GoTop()},;
	oPnlCabec,"Atualizar dados",,.T. )

	// browse com a listagem das programações
	oBrwProgRec := MsSelect():New(_TRBPROG,,,_aCmpBrw,,,{15,1,183,373})
	oBrwProgRec:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG oDlgProgRec CENTERED

	If (_lRet)
		_cCodProga := (_TRBPROG)->Z1_CODIGO
		_cIteProga := (_TRBPROG)->Z2_ITEM
		// fecha o arquivo TRB
		If ValType(_cArqTrb) == "O"
			_cArqTrb:Delete()
		EndIf
	EndIf

Return({_lRet,_cCodProga,_cIteProga})

// ** 2. funcao para validar se o pedido de venda ja tem mapa de expedicao
User Function FtMapExp(mvNrPedido)
	// variavel de retorno
	local _lRet := .f.
	// query
	local _cQuery

	// prepara query
	_cQuery := " SELECT Sum(QTD_PLANEJADA) QTD_PLANEJADA "
	// verifica por carga
	_cQuery += " FROM   (SELECT Count(DISTINCT DAI_COD) QTD_PLANEJADA "
	// itens da carga
	_cQuery += "         FROM   " + RetSqlTab("DAI") + " (nolock) "
	_cQuery += "                INNER JOIN " + RetSqlTab("Z05") + " (nolock) "
	_cQuery += "                        ON " + RetSqlCond("Z05")
	_cQuery += "                           AND Z05_CARGA = DAI_COD "
	_cQuery += "                INNER JOIN " + RetSqlTab("Z08") + " (nolock) "
	_cQuery += "                        ON " + RetSqlCond("Z08")
	_cQuery += "                           AND Z08_NUMOS = Z05_NUMOS "
	_cQuery += "         WHERE  " + RetSqlCond("DAI")
	_cQuery += "                AND DAI_PEDIDO = '" + mvNrPedido + "'
	// agrupa query
	_cQuery += "         UNION ALL "
	// verifica por onda de separacao
	_cQuery += "         SELECT Count(DISTINCT Z58_CODIGO) QTD_PLANEJADA "
	_cQuery += "         FROM   " + RetSqlTab("Z58") + " (nolock) "
	_cQuery += "                INNER JOIN " + RetSqlTab("Z05") + " (nolock) "
	_cQuery += "                        ON " + RetSqlCond("Z05")
	_cQuery += "                           AND Z05_ONDSEP = Z58_CODIGO "
	_cQuery += "                INNER JOIN " + RetSqlTab("Z08") + " (nolock) "
	_cQuery += "                        ON " + RetSqlCond("Z08")
	_cQuery += "                           AND Z08_NUMOS = Z05_NUMOS "
	_cQuery += "         WHERE  " + RetSqlCond("Z58")
	_cQuery += "                AND Z58_PEDIDO = '" + mvNrPedido + "') VALIDA_MAPA_GERADO "

	// atualiza variavel de retorno
	_lRet := (U_FtQuery(_cQuery) > 0)

Return(_lRet)

// ** funcao que troca mensagem do monitor/dbaccess
User Function FtMsgMon(mvRotAtual)
	// mensagem para monitor
	local _cMsgMonit := "** Rot Sem Cadastro ** - "
	// valor padrao
	Default mvRotAtual := AllTrim(ProcName(1))

	// define texto
	Do Case
		Case ("TACDA002" $ mvRotAtual)
		_cMsgMonit := "TACDA002 - Main Window"
		Case ("ACDA002A" $ mvRotAtual)
		_cMsgMonit := "ACDA002A - Ordens de Serviço"
		Case ("WMSA010A" $ mvRotAtual)
		_cMsgMonit := "WMSA010A - Conferencia de Entrada"
		Case ("TWMSA011" $ mvRotAtual)
		_cMsgMonit := "TWMSA011 - Movimentação de Mercadorias"
		Case ("WMSA014A" $ mvRotAtual)
		_cMsgMonit := "WMSA014A - Inventário"
		Case ("WMSA029A" $ mvRotAtual)
		_cMsgMonit := "WMSA029A - Divisão de Estoque/Palete"
		Case ("TWMSA043" $ mvRotAtual)
		_cMsgMonit := "TWMSA043 - Apanhe Livre"
		OtherWise
		_cMsgMonit += mvRotAtual
	EndCase

	// define mensagem
	PtInternal(1, "Emp: " + AllTrim(cEmpAnt) + "/" + AllTrim(cFilAnt) + " | Usuario:[" + __CUSERID + "]  " + " | WMS Tecadi | " + _cMsgMonit + " | ThreadId(" + AllTrim(Str(ThreadID())) + ")" )
	TcInternal(1, "Emp: " + AllTrim(cEmpAnt) + "/" + AllTrim(cFilAnt) + " | Usuario:[" + __CUSERID + "]  " + " | WMS Tecadi | " + _cMsgMonit + " | ThreadId(" + AllTrim(Str(ThreadID())) + ")" )

Return

// ** funcao que monta uma tela com a relacao de ordens de serviço em aberto com pré-conferência finalizada
User Function LstPConf(mvCodCli, mvLojCli, mvProgram, mvItProg)

	Local _cQuery
	// controle de confirmacao
	Local _lRet := .f.
	// estrutura do arquivo de trabalho
	Local _aEstruTrb := {}
	// campo do browse
	Local _aCmpBrw := {}

	local _cNumos := CriaVar("Z05_NUMOS", .T. )

	// objetos da tela
	local oBtnOK, oBtnSair, _oBmpRefresh, oDlgNumos, oPnlCabec, oBrwNumos

	// arquivo TMP
	local _cArqTrb
	local _TRBNUMOS := GetNextAlias()

	// campos do arquivo de trabalho
	aAdd(_aEstruTrb,{"Z06_NUMOS"  ,"C",TamSx3("Z06_NUMOS")[1],0})
	aAdd(_aEstruTrb,{"Z06_SEQOS"  ,"C",TamSx3("Z06_SEQOS")[1],0})
	aAdd(_aEstruTrb,{"Z05_CLIENT" ,"C",TamSx3("Z05_CLIENT")[1],0})
	aAdd(_aEstruTrb,{"Z05_LOJA"   ,"C",TamSx3("Z05_LOJA")[1],0})
	aAdd(_aEstruTrb,{"Z05_PROCES" ,"C",TamSx3("Z05_PROCES")[1],0})
	aAdd(_aEstruTrb,{"Z05_ITPROC" ,"C",TamSx3("Z05_ITPROC")[1],0})
	aAdd(_aEstruTrb,{"Z06_DTINIC" ,"D",8,0})
	aAdd(_aEstruTrb,{"Z06_DTFIM"  ,"D",8,0})

	// verifica se o TRB existe
	If Select(_TRBNUMOS)<>0
		dbSelectArea(_TRBNUMOS)
		dbCloseArea()
	EndIf
	// criar um arquivo de trabalho
	_cArqTrb := FWTemporaryTable():New( _TRBNUMOS )
	_cArqTrb:SetFields( _aEstruTrb )
	_cArqTrb:Create()

	// monta a query para filtro dos dados
	_cQuery := " SELECT Z06_NUMOS,                            "
	_cQuery += "        Z06_SEQOS,                            "
	_cQuery += "        Z05_CLIENT,                           "
	_cQuery += "        Z05_LOJA,                             "
	_cQuery += "        Z05_PROCES,                           "
	_cQuery += " 	    Z05_ITPROC,                           "
	_cQuery += "        Z06_DTINIC,                           "
	_cQuery += "        Z06_DTFIM                             "
	_cQuery += " FROM " + RetSqlTab("Z06")
	_cQuery += "        INNER JOIN " + RetSqlTab("Z05")
	_cQuery += "                ON " + RetSqlCond("Z05") 
	_cQuery += "                   AND Z05_NUMOS = Z06_NUMOS  "
	_cQuery += "                   AND Z05_TPOPER = 'E'       "
	_cQuery += "                   AND Z05_CLIENT = '" + mvCodCli + "'  "
	_cQuery += "                   AND Z05_LOJA =   '" + mvLojCli + "'  "
	_cQuery += " WHERE " + RetSqlCond("Z06") 
	_cQuery += "        AND Z06_SERVIC = '015'                "
	_cQuery += "        AND Z06_TAREFA = '014'                "
	_cQuery += "        AND Z06_STATUS = 'AN'                 "
	// apenas OS sem vínculo fiscal (numseq em branco)
	_cQuery += "       AND (SELECT Count(Z07_NUMSEQ) "
	_cQuery += "            FROM " + RetSqlTab("Z07")
	_cQuery += "            WHERE " + RetSqlCond("Z07")
	_cQuery += "            AND Z07_NUMOS = Z06_NUMOS "
	_cQuery += "            AND Z07_SEQOS = Z06_SEQOS "
	_cQuery += "            AND Z07_CLIENT = Z05_CLIENT "
	_cQuery += "            AND Z07_LOJA   = Z05_LOJA "
	_cQuery += "            AND Z07_NUMSEQ = '') > 0 "
	_cQuery += " ORDER BY Z06_NUMOS                           "

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQuery,_aEstruTrb,_TRBNUMOS)

	// verifica os dados
	(_TRBNUMOS)->(dbSelectArea(_TRBNUMOS))
	(_TRBNUMOS)->(dbGoTop())

	// verifica se há programacoes para visualizar
	If ((_TRBNUMOS)->(RecCount())==0)
		// avisa usuario
		Help( Nil, Nil, 'TWMSXFU1.LstPconf.001', Nil, "Não foram localizadas ordens de serviço de pré-conferência válidas.", 1, 0, Nil, Nil, Nil, Nil, Nil, {"Verifique se a pré-conferência já foi realizada e está finalizada, e se a programação está correta."})      

		// fecha arquivo de trabalho
		(_TRBNUMOS)->(dbSelectArea(_TRBNUMOS))
		(_TRBNUMOS)->(__dbZap())

		// retorna sem número da OS
		Return()
	EndIf

	// alimenta o header
	aAdd(_aCmpBrw,{"Z06_NUMOS" , PesqPict("Z06","Z06_NUMOS") , "OS"})
	aAdd(_aCmpBrw,{"Z06_SEQOS" , PesqPict("Z06","Z06_SEQOS") , "Seq. OS"})
	aAdd(_aCmpBrw,{"Z05_CLIENT", PesqPict("Z05","Z05_CLIENT"), "Cod.Cliente"})
	aAdd(_aCmpBrw,{"Z05_LOJA"  , PesqPict("Z05","Z05_LOJA")  , "Loja"})
	aAdd(_aCmpBrw,{"Z05_PROCES", PesqPict("Z05","Z05_PROCES"), "Program."})
	aAdd(_aCmpBrw,{"Z05_ITPROC", PesqPict("Z05","Z05_ITPROC"), "Item Prog."})
	aAdd(_aCmpBrw,{"Z06_DTINIC", PesqPict("Z06","Z06_DTINIC"), "Data inicio"})
	aAdd(_aCmpBrw,{"Z06_DTFIM" , PesqPict("Z06","Z06_DTINIC"), "Data finaliz."})

	// monta o dialogo
	oDlgNumos := MSDialog():New(000,000,400,800,"Ordens de serviço de pré-conferência (vincular com esta nota fiscal)",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho
	oPnlCabec := TPanel():New(000,000,nil,oDlgNumos,,.F.,.F.,,,000,020,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// botao para confirmar
	oBtnOK := TButton():New(005,005,"Confirmar",oPnlCabec,{|| _lRet:= .T. ,oDlgNumos:End() },060,010,,,,.T.,,"",,,,.F. )
	// botao pra fechar
	oBtnSair := TButton():New(005,070,"Fechar",oPnlCabec,{||oDlgNumos:End()},060,010,,,,.T.,,"",,,,.F. )
	// botao para atualizar o grid
	_oBmpRefresh := TBtnBmp2():New(003,760,040,040,"RELOAD",,,,	{|| (_TRBNUMOS)->( __DBZap() ),	SqlToTrb(_cQuery,_aEstruTrb,_TRBNUMOS),	oBrwNumos:oBrowse:Refresh(.F.), 	oBrwNumos:oBrowse:GoTop()}, 	oPnlCabec,"Atualizar dados",,.T. )

	// browse com a listagem ordens de serviço
	oBrwNumos := MsSelect():New(_TRBNUMOS,,,_aCmpBrw,,,{15,1,183,373})
	oBrwNumos:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG oDlgNumos CENTERED

	If (_lRet)
		_cNumos := (_TRBNUMOS)->Z06_NUMOS
	EndIf

	// fecha o arquivo TRB
	If ValType(_cArqTrb) == "O"
		_cArqTrb:Delete()
	EndIf

Return( _cNumos )