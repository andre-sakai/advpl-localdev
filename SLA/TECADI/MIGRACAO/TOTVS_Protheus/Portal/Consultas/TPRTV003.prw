#include "protheus.ch"
#include "parmtype.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Portal Cliente - Consulta Monitor de Servicos           !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 02/2017 !
+------------------+--------------------------------------------------------*/

User Function TPRTV003()

	// lista de pergunta (parametros)
	Local _vPerg := {}
	local _cPerg := PadR("TPRTV003",10)

	// cores da legenda
	local _aCoresLeg := {}

	// objetos da tela
	local _oMnuPrin1
	local _oMnu1OrdSrv, _oMnu1Tools

	// variaveis temporarias
	local _nSigla
	local _nCodCli

	// filtro por sigla
	local _cFilSigla := ""

	// dimensoes da tela
	private _aSizeWnd := MsAdvSize()

	// variaveis para filtro
	Private mvDataDe   := (Date()-7) //mv_par01
	Private mvDataAte  := Date()     //mv_par02
	Private mvQbraVis  := 1          //mv_par03

	// fontes utilizadas
	Private _oFntBrowse := TFont():New("Verdana",,14,.f.,.f.)
	Private _oFntMenu   := TFont():New("Verdana",,14,.t.,.f.)
	Private _oFntCabec  := TFont():New("Verdana",,25,.t.,.f.)

	// campos do browse das ordens de servico
	private _aHdOrdServ := {}
	private _aStOrdServ := {}
	private _oBrwOrdServ
	private _cAlTrOrdServ := GetNextAlias()

	// filtro por codigo do cliente
	private _cFilCodCli := ""

	// titulo da tela principal
	Private cCadastro := "Monitor de Ordem de Serviços"
	
	private _oAlTrb

	// valida do login do usuario
	If ( ! U_FtPrtVld(__cUserId) )
		Return(.f.)
	EndIf

	// define filtro por sigla
	For _nSigla := 1 to Len(___aPrtSigla)
		_cFilSigla += ___aPrtSigla[_nSigla] + "|"
	Next _nSigla

	// define filtro por codigo de cliente
	For _nCodCli := 1 to Len(___aPrtDepos)
		_cFilCodCli += ___aPrtDepos[_nCodCli][1] + "|"
	Next _nCodCli

	// lista de perguntas (parametros)
	aAdd(_vPerg,{"Data De?"       , "D", 8, 0, "G",                        ,"",}) //mv_par01
	aAdd(_vPerg,{"Data Até?"      , "D", 8, 0, "G",                        ,"",}) //mv_par02
	aAdd(_vPerg,{"Visualizar Por?", "N", 1, 0, "C",{"Pedido", "Nota Venda"},"",}) //mv_par03

	// cria grupo de perguntas
	U_FtCriaSX1( _cPerg, _vPerg )

	// apresenta perguntas na tela
	If ( ! Pergunte(_cPerg, .T.) )
		Return
	EndIf

	// atualiza as variaveis
	mvDataDe   := mv_par01
	mvDataAte  := mv_par02
	mvQbraVis  := mv_par03

	// define as cores da legenda
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'AG'", "BR_VERMELHO"}) // Aguardando
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'EX'", "BR_AZUL"    }) // Em Execução
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'IN'", "BR_AMARELO" }) // Interrompida
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'AN'", "BR_CINZA"   }) // Em Análise
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'BL'", "BR_PRETO"   }) // Bloqueada
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'FI'", "BR_VERDE"   }) // Finalizada
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'PL'", "BR_MARROM"  }) // Planejada

	// busca dados
	sfRfrDados( .T. )

	// monta o dialogo do monitor
	_oDlgMntOrdServ := MSDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"Monitor de Serviços",,,.F.,,,,,,.T.,,,.T. )
	_oDlgMntOrdServ:lMaximized := .T.

	// cria o panel do cabecalho (opcoes da pesquisa)
	_oPnlCabec := TPanel():New(000,000,'Monitor de Serviços',_oDlgMntOrdServ,_oFntCabec,.T.,.F.,,,000,025,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// monta um Menu Suspenso
	_oMnuPrin1 := TMenuBar():New(_oDlgMntOrdServ)
	_oMnuPrin1:SetCss("QMenuBar{background-color:#424242;color:#ffffff}")
	_oMnuPrin1:Align     := CONTROL_ALIGN_TOP
	_oMnuPrin1:bRClicked := {||}
	_oMnuPrin1:oFont := _oFntMenu

	// sub-opcao
	_oMnu1OrdSrv := TMenu():New(0,0,0,0,.T.,,_oDlgMntOrdServ)
	_oMnu1Tools  := TMenu():New(0,0,0,0,.T.,,_oDlgMntOrdServ)

	// adciona opcao principal do menu
	_oMnuPrin1:AddItem('&Ordens de Serviço', _oMnu1OrdSrv, .T.)
	_oMnuPrin1:AddItem('&Ferramentas'      , _oMnu1Tools, .T.)

	// sub-opcoes - ordens de servico
	_oMnu1OrdSrv:Add(TMenuItem():New(_oDlgMntOrdServ,'Atualização/Refresh de Dados'                           ,,,,{|| sfRfrDados( .F. )     },,'RELOAD'      ,,,,,,,.T.))
	_oMnu1OrdSrv:Add(TMenuItem():New(_oDlgMntOrdServ,'Sair'                                                   ,,,,{|| _oDlgMntOrdServ:End() },,'FINAL'       ,,,,,,,.T.))

	// sub-opcoes - ferramentas
	_oMnu1Tools:Add(TMenuItem():New(_oDlgMntOrdServ, 'Definir novos parâmetros de consulta'                   ,,,,{|| sfDefParam(_cPerg)    },,'PARAMETROS'  ,,,,,,,.T.))
	_oMnu1Tools:Add(TMenuItem():New(_oDlgMntOrdServ, 'Legenda'                                                ,,,,{|| sfLegenda()           },,'COLOR'       ,,,,,,,.T.))

	// browse com a listagem dos servicos
	_oBrwOrdServ := MsSelect():New((_cAlTrOrdServ),,,_aHdOrdServ,,,{000,000,400,1000},,,_oDlgMntOrdServ,,_aCoresLeg)
	_oBrwOrdServ:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwOrdServ:oBrowse:oFont := _oFntBrowse

	// inclui teclas de atalho
	SetKey(VK_F5 , {|| sfRfrDados( .F. ) } )

	// ativa a tela
	ACTIVATE MSDIALOG _oDlgMntOrdServ CENTERED

	// limpa teclas de atalho
	SetKey(VK_F5 , {|| Nil})
	
	// exclui informacoes temporarias
	If ( ! Empty(_cAlTrOrdServ) )
		fErase(_cAlTrOrdServ + GetDBExtension())
		fErase(_cAlTrOrdServ + OrdBagExt())
		(_cAlTrOrdServ)->(DbCloseArea())
		_oAlTrb:Delete()
	Endif

Return()

// ** funcao usada para atualizar os dados
Static Function sfRfrDados(mvFirst)
	Local _lRet := .f.
	MsgRun("Atualizando a Tela do Monitor de Serviços...", "Aguarde...", {|| CursorWait(), _lRet := sfSelDados(mvFirst, Nil), CursorArrow()})
Return _lRet

// ** funcao para filtrar servicos de acordo com os parametros e configuracao do operador
Static Function sfSelDados(mvFirst, mvNumOs)
	local _cQuery     := ""
	local _aRetSQL    := {}
	// area inicial do TRB
	local _aAreaTRB  := IIf(mvFirst,Nil,(_cAlTrOrdServ)->(GetArea()))

	// variaveis temporias
	local _nTrf

	// tabela de classificao do status da OS
	local _cTabClas := SuperGetMV('TC_CLASOS',.F.,"BL=1;AN=2;IN=3;PL=4;AG=5;EX=6;FI=7")
	local _aTabClas := Separa(_cTabClas,";")
	local _nTabClas
	local _aTmpStsCla

	// valor padrao para nr de OS
	Default mvNumOs  := ""

	// abre o alias
	dbSelectArea("Z05")
	dbSelectArea("Z06")
	dbSelectArea("Z18")

	// busca as movimentacoes com as tarefas para poder criar as colunas dinamicamente.
	_cQuery := " SELECT DISTINCT Z06_TAREFA, LTRIM(RTRIM(SX5TRF.X5_DESCRI)) DSC_TAREFA"
	// cabecalho da OS
	_cQuery += " FROM " + RetSqlTab("Z05")
	// itens da ordem de servicos
	_cQuery += " INNER JOIN " + RetSqlTab("Z06") + " ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z05_NUMOS "
	// filtra os inventários, para que não apareçam na lista
	_cQuery += " AND Z06_TAREFA <> 'T02' "
	// cad. de tarefas
	_cQuery += " INNER JOIN "+RetSqlName("SX5")+" SX5TRF ON SX5TRF.X5_FILIAL = '" + xFilial("SX5") + "' AND SX5TRF.D_E_L_E_T_ = ' ' AND SX5TRF.X5_TABELA = 'L2' AND SX5TRF.X5_CHAVE = Z06_TAREFA "
	// cad. de servicos por cliente
	_cQuery += "        LEFT  JOIN " + RetSqlTab("Z37") + " (NOLOCK) "
	_cQuery += "                ON " + RetSqlCond("Z37")
	_cQuery += "                   AND Z37_CODCLI = Z05_CLIENT "
	_cQuery += "                   AND Z37_LOJCLI = Z05_LOJA "
	_cQuery += "                   AND Z37_OPERAC = Z05_TPOPER "
	_cQuery += "                   AND Z37_SERVIC = Z06_SERVIC "
	_cQuery += "                   AND Z37_TAREFA = Z06_TAREFA "
	// filtro da movimentacoes
	_cQuery += " WHERE " + RetSqlCond("Z05")
	// filtro por cliente
	_cQuery += " AND Z05_CLIENT IN " + FormatIn(_cFilCodCli,"|")
	// filtro por data
	_cQuery += " AND Z05_DTEMIS BETWEEN '" + DtoS(mvDataDe) + "' AND '" + DtoS(mvDataAte)+ "' "
	// somente expedicao
	_cQuery += " AND Z05_TPOPER = 'S' "

//	memowrit("c:\query\tprtv003_sfSelDados_cod_srv.txt",_cQuery )
//	memowrit("\query\" + __cUserId + "_tprtv003_sfSelDados_cod_srv.txt",_cQuery )

	// atualiza variavel
	_aRetSQL := U_SqlToVet(_cQuery)

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStOrdServ,{"Z06_STATUS"  ,"C", TamSx3("Z06_STATUS")[1]   ,0})
		aAdd(_aStOrdServ,{"Z05_NUMOS"   ,"C", TamSx3("Z05_NUMOS")[1]    ,0}) ; aAdd(_aHdOrdServ,{"Z05_NUMOS" ,"","Número O.S." , ""})
		aAdd(_aStOrdServ,{"Z05_DTEMIS"  ,"D", TamSx3("Z05_DTEMIS")[1]   ,0}) ; aAdd(_aHdOrdServ,{"Z05_DTEMIS","","Data Emissão", ""})

		// criando as colunas conforme retorno da consulta SQL
		For _nTrf := 1 To Len(_aRetSQL)
			// inclui campo da estrutura do TRB / campo do browse
			aAdd(_aStOrdServ,{"TRF" + Alltrim(_aRetSQL[_nTrf][1]), "N", 6, 2 }) ; aAdd(_aHdOrdServ,{"TRF" + Alltrim(_aRetSQL[_nTrf][1]), "" , Alltrim(_aRetSQL[_nTrf][2]), "@E 999.99 %"})
		Next _nTrf

		// quantidade de pedido
		aAdd(_aStOrdServ,{"QTD_PEDIDO"  ,"N",  6,0}) ; aAdd(_aHdOrdServ,{"QTD_PEDIDO", "", "Quant." + IIf(mv_par03 == 1, "Pedidos", "Nota Venda"), ""})
		// relacao de pedido de pedido
		aAdd(_aStOrdServ,{"REL_PEDIDO"  ,"C",150,0}) ; aAdd(_aHdOrdServ,{"REL_PEDIDO", "", IIf(mv_par03 == 1, "Pedidos", "Notas de Venda")       , ""})

		// relacao de pedido de pedido
		aAdd(_aStOrdServ,{"QTD_VOL"     ,"N", 9,0}) ; aAdd(_aHdOrdServ,{"QTD_VOL", "", "Qtd. Volumes" , ""})

		// fecha alias do TRB
		If (Select(_cAlTrOrdServ) <> 0)
			(_cAlTrOrdServ)->(dbSelectArea(_cAlTrOrdServ))
			(_cAlTrOrdServ)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho		
		_oAlTrb := FWTemporaryTable():New(_cAlTrOrdServ)
		_oAlTrb:SetFields(_aStOrdServ)
		_oAlTrb:Create()

		
		// criacao de indice por OS
		IndRegua(_cAlTrOrdServ,_oAlTrb:cIndexName,"Z05_NUMOS",,, "Indexando Arquivo de Trabalho")

		//-- Abre o indice do Arquivo de Trabalho.
		(_cAlTrOrdServ)->(dbSetOrder(1))

	EndIf

	// limpa o conteudo do TRB
	If ( ! mvFirst )
		(_cAlTrOrdServ)->(dbSelectArea(_cAlTrOrdServ))
		(_cAlTrOrdServ)->(__DbZap())
	EndIf

	// busca as movimentacoes para criação do TRB.
	_cQuery := "SELECT "
	// status da ordem de servico
	_cQuery += "(SELECT TOP 1 Z06_STATUS "
	// itens da ordem de servico
	_cQuery += "        FROM   "+RetSqlTab("Z06")
	// filtro padrao
	_cQuery += "        WHERE  "+RetSqlCond("Z06")
	// numero da OS
	_cQuery += "               AND Z06_NUMOS = Z05_NUMOS "
	// ordem conforme tabela de classificacao
	_cQuery += "        ORDER  BY "

	// inicio da condicao de ordem de dados
	_cQuery += "CASE WHEN Z06_STATUS = 'ZZ' THEN 100 "
	// varre a tabela de classificacao
	For _nTabClas := 1 to Len(_aTabClas)

		// separa os dados
		_aTmpStsCla := Separa(_aTabClas[_nTabClas], "=", .f.)

		// complementa a query
		_cQuery += " WHEN Z06_STATUS = '"+_aTmpStsCla[1]+"' THEN "+_aTmpStsCla[2]

	Next _nTabClas
	// final da condicao de ordem de dados
	_cQuery += " ELSE 0 "
	_cQuery += " END) Z06_STATUS, "

	// nr da os
	_cQuery += " Z05_NUMOS, "
	// data de emissao
	_cQuery += " Z05_DTEMIS, "
	// descricao da operacao
	_cQuery += " CASE "
	_cQuery += "   WHEN Z05_TPOPER = 'E' THEN 'RECEBIMENTO' "
	_cQuery += "   WHEN Z05_TPOPER = 'S' THEN 'EXPEDICAO' "
	_cQuery += "   WHEN Z05_TPOPER = 'I' THEN 'INTERNA' "
	_cQuery += " END DSC_OPER, "
	// cliente
	_cQuery += " Z05_CLIENT, Z05_LOJA, A1_NOME, "
	// programacao ou carga
	_cQuery += " CASE "
	_cQuery += "   WHEN Z05_TPOPER = 'E' THEN 'PG: ' + Z05_PROCES "
	_cQuery += "   WHEN Z05_TPOPER = 'S' THEN 'CG: ' + Z05_CARGA "
	_cQuery += "   ELSE '' "
	_cQuery += " END IT_CODREF, "
	// total/percentual por tarefa
	_cQuery += " COALESCE([002], 0) TRF002, "
	_cQuery += " COALESCE([003], 0) TRF003, "
	_cQuery += " COALESCE([004], 0) TRF004, "
	_cQuery += " COALESCE([007], 0) TRF007, "
	_cQuery += " COALESCE([009], 0) TRF009, "
	_cQuery += " COALESCE([013], 0) TRF013, "
	_cQuery += " COALESCE([T05], 0) TRFT05, "
	_cQuery += " COALESCE([T06], 0) TRFT06, "
	_cQuery += " COALESCE([T07], 0) TRFT07, "
	_cQuery += " COALESCE([T08], 0) TRFT08, "

	// quantidade de pedidos
	_cQuery += " QTD_PEDIDO, "

	// relacao de pedidos por ordem de servico
	_cQuery += " REL_PEDIDO, "

	// QUANTIDADE DE VOLUMES MONTADOS
	_cQuery += " QTD_VOL "

	// sub-select com os filtros necessarios
	_cQuery += "FROM ( "
	_cQuery += "SELECT Z06_FILIAL, "
	_cQuery += "       Z06_NUMOS, "
	_cQuery += "       Z06_TAREFA, "
	_cQuery += "       CASE "

	// 002-Mov.Merc/Apanhe / 009-Enderecamento / 013-Transferencia
	_cQuery += "         WHEN Z06_TAREFA IN ( '002', '009', '013', 'T08' ) THEN (SELECT SUM(CASE "
	_cQuery += "                                                                              WHEN Z08_STATUS = 'R' THEN 1 "
	_cQuery += "                                                                              ELSE 0 "
	_cQuery += "                                                                            END) * 100 / CASE "
	_cQuery += "                                                                                           WHEN Count(*) = 0 THEN 1 "
	_cQuery += "                                                                                           ELSE Count(*) "
	_cQuery += "                                                                                         END "
	_cQuery += "                                                                 FROM   "+RetSqlName("Z08")+" Z08 WITH (NOLOCK, INDEX("+RetSqlName("Z08")+"1)) "
	_cQuery += "                                                                 WHERE  "+RetSqlCond("Z08")
	_cQuery += "                                                                        AND Z08_NUMOS = Z06_NUMOS "
	_cQuery += "                                                                        AND Z08_SEQOS = Z06_SEQOS) "

	// 003-Conferencia de Entrada
	_cQuery += "           WHEN Z06_SERVIC = '003' "
	_cQuery += "                AND Z06_TAREFA IN ( '003' ) THEN (SELECT ( Isnull((SELECT Sum(Z07_QUANT) FROM "+RetSqlTab("Z07")+" WITH (NOLOCK, INDEX("+RetSqlName("Z07")+"1)) WHERE "+RetSqlCond("Z07")+" AND Z07_NUMOS = Z06_NUMOS AND Z07_SEQOS = Z06_SEQOS), 0) "
	_cQuery += "                                                           + Isnull((SELECT Sum(Z42_QTDORI - Z42_QTDCON) FROM "+RetSqlTab("Z42")+" WHERE "+RetSqlCond("Z42")+" AND Z42_CODIGO = Z05_TFAA), 0) ) * 100 / Sum(Z04_QUANT) "
	_cQuery += "                                                  FROM   "+RetSqlTab("Z04")+" WITH (NOLOCK, INDEX("+RetSqlName("Z04")+"1)) "
	_cQuery += "                                                  WHERE  "+RetSqlCond("Z04")
	_cQuery += "                                                         AND Z04_CESV = Z05_CESV "
	_cQuery += "                                                         AND ( ( Z04_SEQKIT = ' ' ) "
	_cQuery += "                                                                OR ( Z04_SEQKIT != ' ' "
	_cQuery += "                                                                     AND Z04_NUMSEQ != ' ' ) )) "

	// 001-Conferencia de Saída
	_cQuery += "         WHEN Z06_SERVIC IN ( '001' ) AND Z06_TAREFA IN ( '003','T07' ) THEN ( CASE WHEN Z06_TAREFA = 'T07' THEN ( CASE WHEN Z06_STATUS = 'FI' THEN 100 ELSE 0 END )
	_cQuery += "         															ELSE ((SELECT Isnull((SELECT Sum(Z07_QUANT) "
	_cQuery += "                                                                       FROM   "+RetSqlTab("Z07")+" WITH (NOLOCK) "
	_cQuery += "                                                                       WHERE  "+RetSqlCond("Z07")+" "
	_cQuery += "                                                                              AND Z07_NUMOS = Z06_NUMOS "
	_cQuery += "                                                                              AND Z07_SEQOS = Z06_SEQOS), 0)) * 100 / (SELECT Sum(Z08_QUANT) "
	_cQuery += "                                                                                                                       FROM   "+RetSqlTab("Z08")+" WITH (NOLOCK, INDEX("+RetSqlName("Z08")+"1)) "
	_cQuery += "                                                                                                                       WHERE  "+RetSqlCond("Z08")+" "
	_cQuery += "                                                                                                                         AND Z08_NUMOS = Z06_NUMOS)) END ) "

	// 004-Carregamento
	_cQuery += "         WHEN Z06_TAREFA = '004' THEN (SELECT (SELECT Isnull(Sum(Z07_QUANT), 0) "
	_cQuery += "                                                           FROM   " + RetSqlTab("Z07") + " WITH (NOLOCK) "
	_cQuery += "                                                           WHERE  " + RetSqlCond("Z07")
	_cQuery += "                                                                  AND Z07_SEQOS = Z06_SEQOS "
	_cQuery += "                                                                  AND Z07_NUMOS = Z06_NUMOS) * 100 / Sum(C6_QTDVEN) "
	_cQuery += "                                                   FROM   " + RetSqlTab("SC6")
	_cQuery += "                                                   WHERE  " + RetSqlCond("SC6")
	_cQuery += "                                                       AND C6_NUM IN (SELECT Z43_PEDIDO "
	_cQuery += "                                                                      FROM   " + RetSqlTab("Z43")
	_cQuery += "                                                                      WHERE  " + RetSqlCond("Z43")
	_cQuery += "                                                                             AND Z43_STATUS = 'R' "
	_cQuery += "                                                                             AND Z43_NUMOS = Z06_NUMOS)) "

	// 007-Montagem de Palete/Volumes
	_cQuery += "         WHEN Z06_TAREFA = '007' THEN (SELECT (SELECT Isnull(Sum(Z07_QUANT), 0) "
	_cQuery += "                                                           FROM   " + RetSqlTab("Z07") + " WITH (NOLOCK) "
	_cQuery += "                                                           WHERE  " + RetSqlCond("Z07")
	_cQuery += "                                                                  AND Z07_SEQOS = Z06_SEQOS "
	_cQuery += "                                                                  AND Z07_NUMOS = Z06_NUMOS) * 100 / Sum(Z08_QUANT) "
	_cQuery += "                                                   FROM   "+RetSqlName("Z08")+" Z08 WITH (INDEX("+RetSqlName("Z08")+"1)) "
	_cQuery += "                                                   WHERE  "+RetSqlCond("Z08")
	_cQuery += "                                                          AND Z08_NUMOS = Z06_NUMOS) "


	// T06-Estufagem
	_cQuery += "    	WHEN Z06_SERVIC IN ( 'T06' ) "
	_cQuery += "    	 AND Z06_TAREFA IN ( 'T06' ) THEN ( CASE "
	_cQuery += "    	                                   WHEN Z06_STATUS = 'FI' THEN 100 "
	_cQuery += "    	                                   ELSE ((SELECT Isnull(Sum(Z47_QUANT), 0) * 100 / (SELECT Isnull(Sum(C0_QUANT), 0)"
	_cQuery += "    	                                                                                     FROM   "+RetSqlTab("SC0")+" WITH (NOLOCK, INDEX("+RetSqlName("SC0")+"1)) "
	_cQuery += "    	                                                                                    WHERE  C0_NUM = Z47_IDRES
	_cQuery += "    	                                                                                       AND "+RetSqlCond("SC0")+")
	_cQuery += "    	                                          FROM   "+RetSqlTab("Z47")+" WITH (NOLOCK, INDEX("+RetSqlName("Z47")+"1)) "
	_cQuery += "    	                                          WHERE  "+RetSqlCond("Z47")
	_cQuery += "    	                                                 AND Z47_NUMOS = Z06_NUMOS
	_cQuery += "    	                                          GROUP  BY Z47_IDRES))
	_cQuery += "    	                                 END )"

	// demais não especificados
	_cQuery += "         ELSE 0 "
	_cQuery += "       END QTD_TOTAL, "

	// quantidade total de pedidos
	_cQuery += " CASE WHEN Z05_CARGA != '' AND Z05_ONDSEP = '' THEN"
	_cQuery += " (SELECT Count(DISTINCT " + IIf(mvQbraVis == 1, "C5_ZPEDCLI", "C5_ZDOCCLI") + ") "
	_cQuery += "                 FROM   " + RetSqlTab("SC5")
	_cQuery += "                 WHERE  " + RetSqlCond("SC5")
	_cQuery += "                        AND C5_TIPOOPE = 'P' "
	_cQuery += "                        AND C5_CLIENTE = Z05_CLIENT "
	_cQuery += "                        AND C5_LOJACLI = Z05_LOJA "
	_cQuery += "                        AND " + IIf(mvQbraVis == 1, "C5_ZPEDCLI", "C5_ZDOCCLI") + " != '' "
	_cQuery += "                        AND C5_ZCARGA = Z05_CARGA AND Z05_CARGA != '')"                     
	_cQuery += " WHEN Z05_CARGA = '' AND Z05_ONDSEP != '' THEN"
	_cQuery += " (SELECT Count(DISTINCT " + IIf(mvQbraVis == 1, "C5_ZPEDCLI", "C5_ZDOCCLI") + ") "
	_cQuery += "                 FROM   " + RetSqlTab("SC5")
	_cQuery += "                 WHERE  " + RetSqlCond("SC5")
	_cQuery += "                        AND C5_TIPOOPE = 'P' "
	_cQuery += "                        AND C5_CLIENTE = Z05_CLIENT "
	_cQuery += "                        AND C5_LOJACLI = Z05_LOJA "
	_cQuery += "                        AND " + IIf(mvQbraVis == 1, "C5_ZPEDCLI", "C5_ZDOCCLI") + " != '' "
	_cQuery += "                        AND C5_ZONDSEP = Z05_ONDSEP AND Z05_ONDSEP != '')"                     
	_cQuery += " END QTD_PEDIDO, "

	// relacao de pedidos por ordem de servico
	_cQuery += " CASE WHEN Z05_CARGA != '' AND Z05_ONDSEP = '' THEN"
	_cQuery += "                (SELECT Rtrim(" + IIf(mvQbraVis == 1, "C5_ZPEDCLI", "C5_ZDOCCLI") + ") + '; ' "
	_cQuery += "                 FROM   " + RetSqlTab("SC5")
	_cQuery += "                 WHERE  " + RetSqlCond("SC5")
	_cQuery += "                        AND C5_TIPOOPE = 'P' "
	_cQuery += "                        AND C5_CLIENTE = Z05_CLIENT "
	_cQuery += "                        AND C5_LOJACLI = Z05_LOJA "
	_cQuery += "                        AND C5_ZCARGA = Z05_CARGA AND Z05_CARGA != ''"
	_cQuery += "                        AND " + IIf(mvQbraVis == 1, "C5_ZPEDCLI", "C5_ZDOCCLI") + " != '' "
	_cQuery += "                 FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(400)')" 
	_cQuery += " WHEN Z05_CARGA = '' AND Z05_ONDSEP != '' THEN"
	_cQuery += "                (SELECT Rtrim(" + IIf(mvQbraVis == 1, "C5_ZPEDCLI", "C5_ZDOCCLI") + ") + '; ' "
	_cQuery += "                 FROM   " + RetSqlTab("SC5")
	_cQuery += "                 WHERE  " + RetSqlCond("SC5")
	_cQuery += "                        AND C5_TIPOOPE = 'P' "
	_cQuery += "                        AND C5_CLIENTE = Z05_CLIENT "
	_cQuery += "                        AND C5_LOJACLI = Z05_LOJA "
	_cQuery += "                        AND C5_ZONDSEP = Z05_ONDSEP AND Z05_ONDSEP != ''"
	_cQuery += "                        AND " + IIf(mvQbraVis == 1, "C5_ZPEDCLI", "C5_ZDOCCLI") + " != '' "
	_cQuery += "                 FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(400)')" 
	_cQuery += " END REL_PEDIDO, "

	// quantidade de volumes montados na OS
	_cQuery += " CASE WHEN Z05_ONDSEP != '' OR Z05_CARGA != '' THEN"
	_cQuery += " (SELECT Count(DISTINCT Z07_ETQVOL)                "
	_cQuery += "                FROM " + RetSqlTab("Z07")
	_cQuery += "                WHERE " + RetSqlCond("Z07")
	_cQuery += "                       AND Z07_NUMOS = Z05_NUMOS   "
	_cQuery += "                       AND Z07_STATUS = 'F')       "
	_cQuery += " ELSE ''"
	_cQuery += " END QTD_VOL "

	// itens da ordem de servico
	_cQuery += "FROM   " + RetSqlTab("Z06")+" (NOLOCK) "

	// cab. ordem de servico
	_cQuery += "       INNER JOIN " + RetSqlTab("Z05") + " (NOLOCK) "
	_cQuery += "               ON " + RetSqlCond("Z05")
	_cQuery += "                  AND Z05_NUMOS = Z06_NUMOS "
	// somente expedicao
	_cQuery += "                  AND Z05_TPOPER = 'S' "

	// filtro por cliente
	_cQuery += "                  AND Z05_CLIENT IN " + FormatIn(_cFilCodCli,"|")
	// filtro por data
	_cQuery += "                  AND Z05_DTEMIS BETWEEN '" + DtoS(mvDataDe) + "' AND '" + DtoS(mvDataAte) + "' "
	// filtro padrao
	_cQuery += "WHERE " + RetSqlCond("Z06")
	// para não mostrar as OS de Inventário
	_cQuery += "AND Z06_TAREFA <> 'T02') REL_ORD_SRV "

	// tabela de PIVO / RESUMO
	_cQuery += "       PIVOT ( Sum(QTD_TOTAL) "
	_cQuery += "             FOR Z06_TAREFA IN ([002], "
	_cQuery += "                                [003], "
	_cQuery += "                                [004], "
	_cQuery += "                                [007], "
	_cQuery += "                                [009], "
	_cQuery += "                                [013], "
	_cQuery += "                                [T05], "
	_cQuery += "                                [T06], "
	_cQuery += "                                [T07], "
	_cQuery += "                                [T08]) ) TAB_PIV "
	// cab. ordem de servico
	_cQuery += "       INNER JOIN " + RetSqlTab("Z05") + " (NOLOCK) "
	_cQuery += "               ON " + RetSqlCond("Z05")
	_cQuery += "                  AND Z05_NUMOS = Z06_NUMOS "
	// cad. cliente
	_cQuery += "       LEFT JOIN " + RetSqlTab("SA1") + " ON " + RetSqlCond("SA1") + " AND A1_COD = Z05_CLIENT AND A1_LOJA = Z05_LOJA "

	// ordem das informacoes
	_cQuery += "ORDER BY Z05_NUMOS"

//	memowrit("\tprtv003_sfSelDados_relacao_ord_srv.txt", _cQuery)
//	memowrit("c:\query\tprtv003_sfSelDados_relacao_ord_srv.txt", _cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery, _aStOrdServ, (_cAlTrOrdServ))
	// abre o arquivo de trabalho
	(_cAlTrOrdServ)->(dbSelectArea(_cAlTrOrdServ))

	// varre todos o TRB para atualizar o status
	(_cAlTrOrdServ)->(dbSelectArea(_cAlTrOrdServ))
	(_cAlTrOrdServ)->(dbSetOrder(1))
	(_cAlTrOrdServ)->(dbGoTop())

	// reposiciona cursor no browse
	If (mvFirst)
		(_cAlTrOrdServ)->(dbSelectArea(_cAlTrOrdServ))
		(_cAlTrOrdServ)->(dbGoTop())
	ElseIf (!mvFirst)
		// area inicial do TRB
		RestArea(_aAreaTRB)
	EndIf

	// refresh do browse
	If (_oBrwOrdServ <> nil)
		_oBrwOrdServ:oBrowse:Refresh()
	EndIf

Return .t.

// ** funcao que apresenta a legenda
Static Function sfLegenda()

	Local _aCores := {}

	// inclui opcoes e cores do status
	aAdd(_aCores,{"BR_VERMELHO", "Aguardando"  })
	aAdd(_aCores,{"BR_AZUL"    , "Em Execução" })
	aAdd(_aCores,{"BR_AMARELO" , "Interrompida"})
	aAdd(_aCores,{"BR_CINZA"   , "Em Análise"  })
	aAdd(_aCores,{"BR_PRETO"   , "Bloqueada"   })
	aAdd(_aCores,{"BR_VERDE"   , "Finalizada"  })
	aAdd(_aCores,{"BR_MARROM"  , "Planejada"   })

	// funcao padrao para apresentar as legendas
	BrwLegenda(cCadastro,"Legenda",_aCores)

Return NIL

// ** funcao para definicao de novos parametros
Static Function sfDefParam(mvPerg)

	// apresenta perguntas na tela
	If ( ! Pergunte(mvPerg, .T.) )
		Return
	EndIf

	// atualiza as variaveis
	mvDataDe   := mv_par01
	mvDataAte  := mv_par02

	// atualiza os dados
	sfRfrDados( .F. )

Return