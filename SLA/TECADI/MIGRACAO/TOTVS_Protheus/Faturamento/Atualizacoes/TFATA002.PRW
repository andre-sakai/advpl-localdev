#Include "Totvs.ch"
#Include "Colors.ch"
#Include "topconn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Faturamento dos Contratos WMS                           !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 10/2011                                                 !
+------------------+--------------------------------------------------------*/

#Define _cTranspPro "000023"

User Function TFATA002()
	// grupo de perguntas
	local _aPerg := {}
	private _cPerg := PadR("TFATA002",10)
	Private _oGerTmp

	// monta a lista de perguntas
	aAdd(_aPerg,{"Processo de ?" ,"C",TamSx3("Z1_CODIGO")[1],0,"G",,"SZ1",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par01
	aAdd(_aPerg,{"Processo Até ?" ,"C",TamSx3("Z1_CODIGO")[1],0,"G",,"SZ1",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par02
	aAdd(_aPerg,{"Cliente de ?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par03
	aAdd(_aPerg,{"Cliente Até ?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par04
	aAdd(_aPerg,{"Contrato de ?" ,"C",TamSx3("AAM_CONTRT")[1],0,"G",,"AAM",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par05
	aAdd(_aPerg,{"Contrato Até ?" ,"C",TamSx3("AAM_CONTRT")[1],0,"G",,"AAM",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par06
	aAdd(_aPerg,{"Mostra Faturados ?" ,"N",1,0,"C",{"Sim","Não"},""}) //mv_par07
	aAdd(_aPerg,{"Tipo de Serviço ?" ,"C",2,0,"G",,"T0"}) //mv_par08
	aAdd(_aPerg,{"Status do Processo ?" ,"N",1,0,"C",{"Aberto","Encerrado","Ambos"},""}) //mv_par09
	aAdd(_aPerg,{"Status do Contrato ?" ,"N",1,0,"C",{"Ativo","Suspenso","Encerrado","Cancelado","Todos"},""}) //mv_par10

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// abre os parametros
	if !Pergunte(_cPerg,.T.)
		Return
	endif

	// chama a rotina principal de faturamento de contratos
	U_FATA002A(.t., .f.)
	
	If Valtype(_oGerTmp) == "O"
		_oGerTmp:Delete()
	Endif

Return NIL

// ** funcao que executa o processo de faturamento e apresenta tela principal
User Function FATA002A(mvBtnParam, mvWorkFlow)
	// controle do processamento
	local _lProcOk := .f.

	// valor default
	Default mvBtnParam := .t.
	Default mvWorkFlow := .f.

	// se eh processamento por workflow
	private _lWorkFlow := ((Select("SX2")==0).or.(mvWorkFlow))

	// fontes utilizadas
	private _oFnt01 := TFont():New("Verdana",,15,,.t.)
	// campos do browse
	private _aStrTrbFat := {}

	// gera um ID de processo (por usuario)
	private _cIdProc := If(_lWorkFlow,"",CriaTrab(nil,.f.))
	// inicio da vigencia do contrato
	Private _dIniVigen := CtoD("//")
	// data base de processamento
	private _dDataBase
	// permite utilizar o botao de parametros (desabilitado qdo executado pela consulta de programacoes TWMSV004)
	private _lBtnParam := mvBtnParam

	// parametros
	private mvContDe
	private mvContAte
	private mvClieDe
	private mvClieAte
	private mvProcDe
	private mvProcAte
	private mvMostraFat
	private mvTpServ
	private mvStsProc
	private mvStsContr

	// permite gerar pedido de venda
	private _lGeraPed := .t.

	// ignorar mensagens de ordens de servicos pendentes
	private _lMsgOsPend := .t.
	
	//FWTemporaryTable
	private _TRBGERAL := GetNextAlias()
	
	//FWMarkBrowser
	Private   aColumns := {}
	
	// se for workflow, muda os parametros
	If (_lWorkFlow)

		MsgStop(_cIdProc)

		mvProcDe	:= "  "
		mvProcAte	:= "ZZ"
		mvClieDe	:= "000083"
		mvClieAte	:= "000084"
		mvContDe	:= "  "
		mvContAte	:= "ZZ"
		mvMostraFat := .f.
		mvTpServ	:= "99" // 99-Todos
		mvStsProc	:= 1 // status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
		mvStsContr  := 1 // status do contrato (1-Ativo, 2-Suspenso,3-Encerrado, 4-Cancelado, 5-Todos)

		// variavel da data base
		_dDataBase := dDataBase

		// altera a sigla inicial do ID de processo
		_cIdProc	:= "WF"+GravaData(_dDataBase,.f.,4)

		MsgStop(_cIdProc)

		// chama a rotina de processamento
		_lProcOk := sfProcContrato(.t.)

	Else

		// parametros
		mvProcDe	:= mv_par01
		mvProcAte	:= mv_par02
		mvClieDe	:= mv_par03
		mvClieAte	:= mv_par04
		mvContDe	:= mv_par05
		mvContAte	:= mv_par06
		mvMostraFat := (mv_par07==1) // mostra faturados anteriormente
		mvTpServ	:= mv_par08
		mvStsProc	:= mv_par09 // status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
		mvStsContr	:= mv_par10 // status do contrato (1-Ativo, 2-Suspenso,3-Encerrado, 4-Cancelado, 5-Todos)

		// variavel da data base
		_dDataBase := dDataBase

		// chama funcao que processa todos os contratos de acordo com parametros iniciais
		Processa({ || _lProcOk := sfProcContrato(.t.) },"Faturamento de Contratos...",,.T.)

		// apresenta tela com todos os detalhes
		If (_lProcOk)
			sfTelaGeral()
		EndIf
	EndIf

Return(_lProcOk)

// ** funcao que processa todos os contratos
Static Function sfProcContrato(mvProcAnt)
	// variaveis temporarias
	local _cQryAAM
	// quantidade de registros a processar
	local _nQtdReg
	// controle do codigo de contrato
	local _cContrato := ""
	// controle do cliente
	local _cCodCli := ""
	// controle de servicos ja faturados
	local _lArmPrd := _lArmCnt := _lFrete := _lSegMerc := _lSegTransp := _lOutSrv := .f.
	// itens para NAO faturar
	local _cNaoFatur  := ""
	local _lOkIgnorar := .f.
	
	// reinicia variaveis
	_lMsgOsPend := .t.

	// monta a query com os contratos
	_cQryAAM := " SELECT DISTINCT "
	_cQryAAM += " aam_codcli, "
    _cQryAAM += " aam_loja, "
	_cQryAAM += " aam_contrt, "
	_cQryAAM += " aam_znaofa, "
	_cQryAAM += " convert(varchar(10), cast(aam_inivig AS date),103) as aam_inivig, "
	_cQryAAM += " convert(varchar(10), cast(aam_fimvig AS date),103) as aam_fimvig, "
	_cQryAAM += " aam_status, "
	_cQryAAM += " aam_zmsgis, "
	_cQryAAM += " AAM.r_e_c_n_o_ AS AAMRECNO, " 
	// campos dos itens
	_cQryAAM += " aan_item, "
	_cQryAAM += " aan_tabela, "
	_cQryAAM += " aan_codpro, "
	_cQryAAM += " aan_zdescr, "
	_cQryAAM += " aan_quant, "
	_cQryAAM += " aan_diafat, "
	_cQryAAM += " aan_praca, "
	_cQryAAM += " aan_tipoca, "
	_cQryAAM += " aan_vlruni, "
	_cQryAAM += " aan_tamcon, "
	_cQryAAM += " aan_dayfre, "
	_cQryAAM += " aan_tipoar, "
	_cQryAAM += " aan_zgrpes, "
	_cQryAAM += " AAN.r_e_c_n_o_ AS AANRECNO, " 
	// define a ordem dos dados (prioriza 0-Pacote logistico / 9000006, 1-Pacote logistico Exportacao / 9000010, 2-Pacote de Servicos / 9000011)
	_cQryAAM += " CASE "
	_cQryAAM += " WHEN aan_codpro = '9000006' THEN '0' " 
	_cQryAAM += " WHEN aan_codpro = '9000010' THEN '1' "
	_cQryAAM += " WHEN aan_codpro = '9000011' THEN '2' "
	_cQryAAM += " ELSE aan_codpro "
	_cQryAAM += " END AS IT_ORDEM "
	// contrato
	_cQryAAM += " FROM "+RetSqlTab("AAM")
	// itens do contrato
	_cQryAAM += " INNER JOIN "+RetSqlTab("AAN")+" ON "+RetSqlCond("AAN")+" AND AAN_CONTRT = AAM_CONTRT AND AAN_ZATIVO != 'N' "
	// se informar o processo nos parametros, filtra os constratos especificos
	If (!Empty(mvProcDe)).and.(!Empty(mvProcAte))
		_cQryAAM += " INNER JOIN "+RetSqlTab("SZ1")+" ON "+RetSqlCond("SZ1")+" AND Z1_CONTRT = AAM_CONTRT AND Z1_CODIGO BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' "
		// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
		If (mvStsProc==1) // aberto
			_cQryAAM += " AND Z1_DTFINFA  = ' ' "
		ElseIf (mvStsProc==2) // encerrado
			_cQryAAM += " AND Z1_DTFINFA != ' ' "
		EndIf
	EndIf
	// filtro de contratos
	_cQryAAM += " WHERE "+RetSqlCond("AAM")
	_cQryAAM += " AND AAM_CONTRT BETWEEN '"+mvContDe+"' AND '"+mvContAte+"' "
	_cQryAAM += " AND AAM_CODCLI BETWEEN '"+mvClieDe+"' AND '"+mvClieAte+"' "
	// status do contrato
	If (mvStsContr != 5)
		_cQryAAM += " AND AAM_STATUS = '" +Str(mvStsContr,1)+ "' "
	EndIf

	// ordem dos dados
	_cQryAAM += " ORDER BY AAM_CODCLI, AAM_CONTRT, IT_ORDEM "

	memoWrit("c:\query\TFATA002_sfProcContrato.txt",_cQryAAM)

	// verifica se o alias da query existe
	If (Select("_QRYAAM")<>0)
		dbSelectArea("_QRYAAM")
		dbCloseArea()
	EndIf
	// executa a query
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQryAAM),"_QRYAAM",.F.,.T.)
	dbSelectArea("_QRYAAM")
	
	// quantidade de registros da query
	Count to _nQtdReg

	dbSelectArea("_QRYAAM")
	_QRYAAM->(dbGoTop())

	// acrescenta a limpeza de dados historicos
	_nQtdReg += 1
	// acrescenta a selecao de dados
	_nQtdReg += 1

	// define a quantidade de processos principais
	If (!_lWorkFlow)
		ProcRegua(_nQtdReg)
	EndIf

	// realiza a limpeza de informacoes temporarias
	sfLimpezaTmp(mvProcAnt)

	// reinicia variavel permite gerar pedido de venda
	_lGeraPed := .t.

	// processa todos os itens dos contratos
	While _QRYAAM->(!Eof())

		// controle da regua de processamento
		If (!_lWorkFlow)
			IncProc("Processando Contrato "+_QRYAAM->AAM_CONTRT+" Item "+_QRYAAM->AAN_ITEM)
		EndIf

		// controle do cogido do cliente
		If (_QRYAAM->AAM_CODCLI <> _cCodCli)
			// armazena o codigo do cliente
			_cCodCli := _QRYAAM->AAM_CODCLI
		EndIf

		// reinicia variaveis a cada contrato
		If (_QRYAAM->AAM_CONTRT <> _cContrato)
			// posiciona no contrato
			dbSelectArea("AAM")
			AAM->(dbGoTo(_QRYAAM->AAMRECNO))

			// atualiza numero do contrato
			_cContrato := _QRYAAM->AAM_CONTRT
			// atualiza data de inicio da vigencia do contrato
			_dIniVigen := AAM->AAM_INIVIG

			// itens para NAO faturar do contrato
			_cNaoFatur := If((AAM->(FieldPos("AAM_ZNAOFA"))>0),AAM->AAM_ZNAOFA,"")

			// reinicia as variaveis
			_lArmPrd := _lArmCnt := _lFrete := _lSegMerc := _lSegTransp := _lOutSrv := .f.

			// verifica apenas contratos dentro da faixa de vigencia da database
			If (!_lWorkFlow).and.((_dDataBase < AAM->AAM_INIVIG).or.(_dDataBase > AAM->AAM_FIMVIG).or.(AAM->AAM_STATUS != "1"))
				// atualiza variavel de controle de geracao de pedido de venda
				_lGeraPed := .f.
				// apresenta mensagem
				If (Aviso("TFATA002 -> sfProcContrato",	"O Contrato nr "+_cContrato+" está fora do prazo da vigência em processamento."+CRLF+;
				"Vigência: "+DtoC(AAM->AAM_INIVIG)+" a "+DtoC(AAM->AAM_FIMVIG)+CRLF+;
				"Situação: "+IIf(AAM->AAM_STATUS=="3","Encerrado",IIf(AAM->AAM_STATUS=="2","Suspenso","Ativo")),{"Fechar","Continuar"}) == 1)
					// cancela processamento
					Return(.f.)
				EndIf
			EndIf

		EndIf

		// posiciona no item do contrato
		dbSelectArea("AAN")
		AAN->(dbGoTo(_QRYAAM->AANRECNO))


		// posiciona no produto do item do contrato
		dbSelectArea("SB1")
		SB1->(dbSetOrder(1))
		SB1->(dbSeek( xFilial("SB1")+AAN->AAN_CODPRO ))


		// ** faturamento por tipo de item do contrato


		// ARMAZENAGEM DE CONTAINER
		If (SB1->B1_TIPOSRV=='1').and.(mvTpServ $ "01|99")
			sfArmzContainer(.t.)
			_lArmCnt := .T.
		EndIf

		// ARMAZENAGEM DE PRODUTO
		If (SB1->B1_TIPOSRV=='2').and.(mvTpServ $ "02|99")
			sfArmzProduto(.t., .f.)
			_lArmPrd := .T.
		EndIf

		// PACOTE LOGISTICO
		If (SB1->B1_TIPOSRV=='3').and.(mvTpServ $ "03|99")
			sfPacoteLog(.t.)
		EndIf

		// FRETES
		If (SB1->B1_TIPOSRV=='4').and.(mvTpServ $ "04|99")
			sfFrete(.t.,.f.,"",.f.)
			_lFrete := .T.
		EndIf

		// SEGUROS MERCADORIA
		If (SB1->B1_TIPOSRV=='5').and.(mvTpServ $ "05|99")
			sfSeguro(.t., .f., .f.)
			_lSegMerc := .T.
		EndIf
		/*
		// SEGUROS DE TRANSPORTE
		If (SB1->B1_TIPOSRV=='6').and.(mvTpServ $ "06|09")
		sfSeguro(.t.,.t.)
		_lSegTransp := .T.
		EndIf
		*/

		// OUTROS SERVICOS
		If (SB1->B1_TIPOSRV=='7').and.(mvTpServ $ "07|99")
			sfOutrosServicos(.t.,.f.,"")
			_lOutSrv := .T.
		EndIf

		// VALOR FIXO
		If (SB1->B1_TIPOSRV=='8').and.(mvTpServ $ "08|99")
			sfFixo(.t.)
		EndIf

		// PACOTE LOGISTICO DE EXPORTACAO
		If (SB1->B1_TIPOSRV=='A').and.(mvTpServ $ "10|99")
			sfPctLogExp(.t.)
		EndIf

		// PACOTE DE SERVICOS
		If (SB1->B1_TIPOSRV=='B').and.(mvTpServ $ "11|99")
			sfPctServicos(.t.)
		EndIf


		// proximo item do contrato
		_QRYAAM->(dbSkip())

		// reinicia variaveis
		_lOkIgnorar := .f.


		// somente na armazem, pesquisa valores que nao estao em contrato
		If (cEmpAnt=="01")
			// se for outro contrato, pesquisa valores que nao estao em contrato
			If (_cContrato <> _QRYAAM->AAM_CONTRT)
				// 1-ARMAZENAGEM DE CONTAINER
				If ( ! _lArmCnt ).and.(mvTpServ $ "01|99")
					// se nao deve faturar, limpa registros
					If ("1" $ _cNaoFatur)
						// mensagem de confirmacao
						If (Aviso("TFATA002 -> Ignorar Cobrança","Contrato configurado para ignorar cobrança de ARMAZENAGEM DE CONTAINER. Confirma ignorar cobrança de todas as movimentações em aberto?",{"Não","Sim"}) == 2)
							// executa rotina, com parametro para nao faturar armazenagem de container
							_lOkIgnorar := sfArmzContainer(.f., .t.)

						EndIf
					EndIf

					// se nao ignorou, gera dados sem item vinculado
					If ( ! _lOkIgnorar )
						sfArmzContainer(.f., .f.)
					EndIf
				EndIf

				// 2-ARMAZENAGEM DE PRODUTO
				If ( ! _lArmPrd ).and.(mvTpServ $ "02|99")
					// se nao deve faturar, limpa registros
					If ("2" $ _cNaoFatur)
						// mensagem de confirmacao
						If (Aviso("TFATA002 -> Ignorar Cobrança","Contrato configurado para ignorar cobrança de ARMAZENAGEM DE PRODUTOS. Confirma ignorar cobrança de todas os documentos em aberto?",{"Não","Sim"}) == 2)
							// executa rotina, com parametro para nao faturar armazenagem de produtos
							_lOkIgnorar := sfArmzProduto(.f., .t.)

						EndIf
					EndIf

					// se nao ignorou, gera dados sem item vinculado
					If ( ! _lOkIgnorar )
						sfArmzProduto(.f., .f.)
					EndIf
				EndIf

				// PACOTE LOGISTICO
				// ### gustavo - ver a necessidade
				//If (SB1->B1_TIPOSRV=='3').and.(mvTpServ $ "03|09")
				//	sfPacoteLog(.t.)
				//EndIf

				// 4-FRETES
				If (!_lFrete).and.(mvTpServ $ "04|99").and.(!("4" $ _cNaoFatur))
					sfFrete(.f.,.f.,"",.f.)
				EndIf

				// 5-SEGUROS MERCADORIAS
				If ( ! _lSegMerc ).and.(mvTpServ $ "05|99")
					// se nao deve faturar, limpa registros
					If ("5" $ _cNaoFatur)
						// mensagem de confirmacao
						If (Aviso("TFATA002 -> Ignorar Cobrança","Contrato configurado para ignorar cobrança de SEGURO. Confirma ignorar cobrança de todas os documentos em aberto?",{"Não","Sim"}) == 2)
							// executa rotina, com parametro para nao faturar seguro
							_lOkIgnorar := sfSeguro(.f., .f., .t.)

						EndIf
					EndIf

					// se nao ignorou, gera dados sem item vinculado
					If ( ! _lOkIgnorar )
						sfSeguro(.f., .f., .f.)
					EndIf
				EndIf
				/*
				// 5-SEGUROS DE TRANSPORTE
				If (!_lSegTransp).and.(mvTpServ $ "06|99").and.(!("6" $ _cNaoFatur))
				sfSeguro(.f., .t., .f.)
				EndIf
				*/
				// OUTROS SERVICOS
				If (!_lOutSrv).and.(mvTpServ $ "07|99").and.(!("7" $ _cNaoFatur))
					sfOutrosServicos(.f.,.f.,"")
				EndIf
			EndIf
		EndIf
	EndDo

	If (!_lWorkFlow)
		// executa a selecao da dados
		sfSelDados()

		// posiciona no primeiro registro do TRB
		(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
		(_TRBGERAL)->(dbGoTop())
	EndIf

Return(.t.)

// ** funcao para faturamento de pacote logistico
Static Function sfPacoteLog(mvTemContr)
	// area inicial
	local _aAreaAtu := GetArea()
	local _cQrySZ3, _cQrySzu

	// praca do contrato
	local _cPrcContr := If( !mvTemContr , "", AllTrim(AAN->AAN_PRACA))
	// tipo da carga
	local _cTpCarga := If( !mvTemContr , "", AAN->AAN_TIPOCA)
	// tarifa do pacote
	local _nTarifa := If( !mvTemContr , 0, AAN->AAN_VLRUNI)

	// servicos que compoe o pacote logistico
	local _aSrvPacote := {}
	local _nSrvPacote

	// numero do pacote logistico
	local _cNumPacote
	local _cSeqPacote

	// quebra de processo / item
	local _cQuebraPac := ""

	// MOVIMENTACOES DE ENTRADA
	_cQrySZ3 := "SELECT Z3_DTMOVIM, Z3_CONTAIN, Z3_PROGRAM, Z3_ITEPROG, Z3_RIC, Z3_TPMOVIM, Z3_PRCORIG, Z3_PRCDEST, Z3_CONTEUD, Z3_TAMCONT, Z3_TRANSP "
	_cQrySZ3 += "FROM "+RetSqlName("SZ3")+" Z3, "+RetSqlName("SZ1")+" Z1 "
	_cQrySZ3 += "WHERE Z3_FILIAL = '"+xfilial("SZ3")+"' AND Z3_FILIAL = Z1_FILIAL AND Z3_PROGRAM = Z1_CODIGO AND Z3_TPMOVIM = 'E' "
	_cQrySZ3 += "AND Z3_PRCORIG IN "+FormatIn(_cPrcContr,";")+" "
	// nao foi cobrado pacote nem frete
	_cQrySZ3 += "AND Z3_DTFATPA = ' ' AND Z3_DTFATFR = ' ' "
	// filtro de datas
	_cQrySZ3 += "AND Z3_DTMOVIM BETWEEN '"+DtoS(_dIniVigen)+"' AND '"+DtoS(_dDataBase)+"' "
	_cQrySZ3 += "AND Z3_CLIENTE = '"+AAM->AAM_CODCLI+"' "
	_cQrySZ3 += "AND Z3_LOJA = '"+AAM->AAM_LOJA+"' "
	// somente container cheio (conf Juliana 11.04.12)
	_cQrySZ3 += "AND Z3_CONTEUD = 'C' "
	// contrato
	_cQrySZ3 += "AND Z1_CONTRT = '"+AAM->AAM_CONTRT+"' "

	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	If (mvStsProc==1) // aberto
		_cQrySZ3 +="AND Z1_DTFINFA = ' ' "
	ElseIf (mvStsProc==2) // encerrado
		_cQrySZ3 +="AND Z1_DTFINFA != ' ' "
	EndIf

	// filtra numero do processo
	_cQrySZ3 += "AND Z3_PROGRAM BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' "

	// filtra pelo tipo da carga
	If (!Empty(_cTpCarga))
		_cQrySZ3 +="AND Z1_TIPOCAR = '"+_cTpCarga+"' "
	EndIf

	// 26.08 - cnfe orientacao do Toni, soh pode ser transportadora tecadi
	_cQrySZ3 +="AND Z3_TRANSP = '"+_cTranspPro+"' "
	// deletados
	_cQrySZ3 +="AND Z3.D_E_L_E_T_ = ' ' AND Z1.D_E_L_E_T_ = ' ' "

	// descarta pacote logistico ja faturado
	_cQrySZ3 += "AND NOT EXISTS ("
	_cQrySZ3 += "SELECT SZJ.R_E_C_N_O_ FROM "+RetSqlName("SZJ")+" SZJ "
	_cQrySZ3 += "WHERE "+RetSqlCond("SZJ")+" "
	_cQrySZ3 += "AND ZJ_PROCES  = Z3_PROGRAM AND ZJ_ITPROC = Z3_ITEPROG "
	_cQrySZ3 += "AND ZJ_CONTRT  = Z1_CONTRT "
	_cQrySZ3 += "AND ZJ_CONTAIN = Z3_CONTAIN "
	_cQrySZ3 += "AND ZJ_DTMOVIM = Z3_DTMOVIM "
	_cQrySZ3 += "AND ZJ_TPMOVIM = Z3_TPMOVIM "
	_cQrySZ3 += "AND ZJ_DTPROCE = '"+DtoS(Date())+"' "
	_cQrySZ3 += "AND ZJ_USRPROC = '"+__cUserId+"' "
	_cQrySZ3 += "AND ZJ_IDPROCE = '"+_cIdProc+"' "
	_cQrySZ3 += "AND ZJ_STATUS  = ' ' ) "

	// ordem dos dados
	_cQrySZ3 +="ORDER BY Z3_PROGRAM, Z3_ITEPROG "

	memowrit("c:\query\sfPacoteLog.txt",_cQrySZ3)

	If (Select("_QRYPCTLOG") != 0)
		dbSelectArea("_QRYPCTLOG")
		dbCloseArea()
	Endif
	// executa a query
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQrySZ3),"_QRYPCTLOG",.F.,.T.)
	DbSelectArea("_QRYPCTLOG")

	// varre todos os registro selecionados
	While _QRYPCTLOG->(!EOF())

		// se for outro processo / item, cria novo numero do pacote
		If (_cQuebraPac <> _QRYPCTLOG->(Z3_PROGRAM+Z3_ITEPROG))
			// controla quebra de numeracao
			_cQuebraPac := _QRYPCTLOG->(Z3_PROGRAM+Z3_ITEPROG)
			// criar novo numero do pacote
			_cNumPacote	:= GetSxeNum("SZJ","ZJ_PACOTE")
			_cSeqPacote	:= "001"
			// confirma a sequencia do numero do pacote
			ConfirmSx8()
			// verifica se quantidade programada do item esta completa
			dbSelectArea("SZ2")
			SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM
			SZ2->(dbSeek( xFilial("SZ2")+_QRYPCTLOG->(Z3_PROGRAM+Z3_ITEPROG) ))
			If (SZ2->Z2_QTDREC < SZ2->Z2_QUANT)
				Aviso("TFATA002 -> sfPacoteLog","ATENÇÃO: O processo "+SZ2->Z2_CODIGO+" item "+SZ2->Z2_ITEM+" possui saldo em aberto."+CRLF+;
				"Programado: "+Str(SZ2->Z2_QUANT,3)+CRLF+;
				"Recebido: "+Str(SZ2->Z2_QTDREC,3)+CRLF+;
				"Saldo: "+Str(SZ2->(Z2_QUANT - Z2_QTDREC),3),;
				{"Continuar..."})
			EndIf
		EndIf

		// gera os dados do pacote logistico
		dbSelectArea("SZJ")
		RecLock("SZJ",.t.)
		SZJ->ZJ_FILIAL	:= xFilial("SZJ")
		SZJ->ZJ_PROCES	:= _QRYPCTLOG->Z3_PROGRAM
		SZJ->ZJ_ITPROC	:= _QRYPCTLOG->Z3_ITEPROG
		SZJ->ZJ_CONTRT	:= AAM->AAM_CONTRT
		SZJ->ZJ_ITCONTR	:= If(mvTemContr,AAN->AAN_ITEM,"Z1")
		SZJ->ZJ_PRODUTO	:= If(mvTemContr,AAN->AAN_CODPRO,"")
		SZJ->ZJ_CLIENTE	:= AAM->AAM_CODCLI
		SZJ->ZJ_LOJA	:= AAM->AAM_LOJA
		SZJ->ZJ_PACOTE	:= _cNumPacote
		SZJ->ZJ_SEQPACO	:= _cSeqPacote
		SZJ->ZJ_VALOR	:= Round(_nTarifa,TamSx3("ZJ_VALOR")[2])
		SZJ->ZJ_CONTAIN	:= _QRYPCTLOG->Z3_CONTAIN
		SZJ->ZJ_DTMOVIM	:= StoD(_QRYPCTLOG->Z3_DTMOVIM)
		SZJ->ZJ_TPMOVIM	:= _QRYPCTLOG->Z3_TPMOVIM
		SZJ->ZJ_RIC		:= _QRYPCTLOG->Z3_RIC
		SZJ->ZJ_TAMCONT	:= _QRYPCTLOG->Z3_TAMCONT
		SZJ->ZJ_CONTEUD	:= _QRYPCTLOG->Z3_CONTEUD
		SZJ->ZJ_TRANSP	:= _QRYPCTLOG->Z3_TRANSP
		SZJ->ZJ_PRCORIG	:= _QRYPCTLOG->Z3_PRCORIG
		SZJ->ZJ_PRCDEST	:= _QRYPCTLOG->Z3_PRCDEST
		SZJ->ZJ_FATURAR	:= "S"
		SZJ->ZJ_STATUS	:= " "
		SZJ->ZJ_IDPROCE	:= _cIdProc
		SZJ->ZJ_DTPROCE	:= _dDataBase
		SZJ->ZJ_USRPROC	:= __cUserId
		SZJ->ZJ_DATABAS	:= Date()
		MsUnLock()

		// proxima sequencia do pacote
		_cSeqPacote := Soma1(_cSeqPacote)

		// relaciona todos os itens/servicos que compoe o pacote logistico
		_cQrySzu := "SELECT ZU_PRODUTO, B1_TIPOSRV "
		// servicos do pacote
		_cQrySzu += "FROM "+RetSqlName("SZU")+" SZU "
		// cad. de produto
		_cQrySzu += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND ZU_PRODUTO = B1_COD "
		// filtro dos servicos do contrato e item
		_cQrySzu += "WHERE "+RetSqlCond("SZU")+" "
		_cQrySzu += "AND ZU_CONTRT = '"+AAM->AAM_CONTRT+"' AND ZU_ITCONTR = '"+AAN->AAN_ITEM+"' "
		// ordem dos dados
		_cQrySzu += "ORDER BY ZU_PRODUTO
		// alimenta o vetor com o resultado do SQL
		_aSrvPacote := U_SqlToVet(_cQrySzu)

		For _nSrvPacote := 1 to Len(_aSrvPacote)

			// FRETES
			If (_aSrvPacote[_nSrvPacote][2]=='4')
				sfFrete(.t.,.t.,_aSrvPacote[_nSrvPacote][1],.f.)

				// OUTROS SERVICOS / SERVICOS DIVERSOS
			ElseIf (_aSrvPacote[_nSrvPacote][2]=='7')
				sfOutrosServicos(.t.,.t.,_aSrvPacote[_nSrvPacote][1])

			EndIf

		Next _nSrvPacote

		// proximo registro
		_QRYPCTLOG->(DBSKIP())
	EndDo

Return(.t.)


// ** funcao para calculo de fretes
Static Function sfFrete(mvTemContr,mvPacteLog,mvPactePrd,mvPcteSrv)
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSB1 := SB1->(GetArea())
	local _aAreaAAM := AAM->(GetArea())
	local _aAreaAAN := AAN->(GetArea())
	local _cQrySZ3

	// valor do frete
	local _nVlrFrete := 0

	// define padrao
	Default mvPacteLog := .f.

	// MOVIMENTACOES DE FRETE
	_cQrySZ3 := " SELECT Z3_DTMOVIM, Z3_CONTAIN, Z3_PROGRAM, Z3_ITEPROG, Z3_RIC, Z3_TPMOVIM, Z3_PRCORIG, Z3_PRCDEST, Z3_CONTEUD, Z3_TAMCONT, Z3_TRANSP "
	// movimentacoes de veiculos e cab de programacao
	_cQrySZ3 += " FROM "+RetSqlTab("SZ3")+", "+RetSqlTab("SZ1")
	// filtro padrao
	_cQrySZ3 += " WHERE "+RetSqlCond("SZ3") + " AND " + RetSqlCond("SZ1")
	// codigo programacao
	_cQrySZ3 += " AND Z3_PROGRAM = Z1_CODIGO "
	// quando NAO for pacote de servicos, FILTAR transportadora propria
	If ( ! mvPcteSrv)
		_cQrySZ3 += " AND ((Z3_TPMOVIM = 'E' AND Z3_TRACONT = '"+_cTranspPro+"') OR (Z3_TPMOVIM = 'S' AND Z3_TRANSP = '"+_cTranspPro+"')) "
	EndIf
	// considera data de faturamento do frete
	_cQrySZ3 += " AND Z3_DTFATFR = ' ' "
	// emissao menor q database
	_cQrySZ3 += " AND Z3_DTMOVIM <= '"+DtoS(_dDataBase)+"' "
	// codigo e loja do cliente
	_cQrySZ3 += " AND Z3_CLIENTE = '"+AAM->AAM_CODCLI+"' AND Z3_LOJA = '"+AAM->AAM_LOJA+"' "
	// contrato
	_cQrySZ3 += " AND Z1_CONTRT  = '"+AAM->AAM_CONTRT+"' "
	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	If (mvStsProc==1) // aberto
		_cQrySZ3 += " AND Z1_DTFINFA = ' ' "
	ElseIf (mvStsProc==2) // encerrado
		_cQrySZ3 += " AND Z1_DTFINFA != ' ' "
	EndIf

	// se for pacote logistico, filtra o procecesso
	If (mvPacteLog)
		_cQrySZ3 += " AND Z3_PROGRAM = '"+SZJ->ZJ_PROCES+"' "
		_cQrySZ3 += " AND Z3_ITEPROG = '"+SZJ->ZJ_ITPROC+"' "
		_cQrySZ3 += " AND Z3_CONTAIN = '"+SZJ->ZJ_CONTAIN+"' "
	Else
		_cQrySZ3 += " AND Z3_PROGRAM BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' "
	EndIf

	//NAO FATURAR FRETES DE SAIDA QUANDO O FRETE DE ENTRADA DO CONTAINER JA FOI FATURADO PELO PACOTE LOGISTICO - DANIEL 15/03
	//O OBJETIVO DESTE FILTRO E ELIMINAR OS FRETES DE SAIDA ONDE A ENTRADA DO MESMO JA TENHO SIDO FATURADO ANTES DA DATA DE SAIDA
	_cQrySZ3 += " AND CASE WHEN Z3_TPMOVIM = 'S' THEN (SELECT COUNT(*) FROM "+RetSqlName("SZ3")+" Z3T WHERE Z3T.Z3_FILIAL = SZ3.Z3_FILIAL AND Z3T.Z3_PROGRAM = SZ3.Z3_PROGRAM AND Z3T.Z3_ITEPROG = SZ3.Z3_ITEPROG AND Z3T.Z3_CONTAIN = SZ3.Z3_CONTAIN AND Z3T.Z3_TPMOVIM = 'E' AND Z3T.D_E_L_E_T_ = '' AND Z3T.Z3_DTFATPA = '') ELSE 1 END > 0 "

	// descarta fretes que ja estao no pacote logistico
	_cQrySZ3 += " AND NOT EXISTS ("
	_cQrySZ3 += " SELECT SZK.R_E_C_N_O_ FROM "+RetSqlTab("SZK")
	_cQrySZ3 += " WHERE "+RetSqlCond("SZK")
	_cQrySZ3 += " AND ZK_PROCES  = Z3_PROGRAM AND ZK_ITPROC = Z3_ITEPROG "
	_cQrySZ3 += " AND ZK_CONTRT  = Z1_CONTRT "
	_cQrySZ3 += " AND ZK_CONTAIN = Z3_CONTAIN "
	_cQrySZ3 += " AND ZK_DTPROCE = '"+DtoS(_dDataBase)+"' "
	_cQrySZ3 += " AND ZK_DATABAS = '"+DtoS(Date())+"' "
	_cQrySZ3 += " AND ZK_USRPROC = '"+__cUserId+"' "
	_cQrySZ3 += " AND ZK_IDPROCE = '"+_cIdProc+"' "
	_cQrySZ3 += " AND ZK_STATUS = ' ' "
	_cQrySZ3 += " AND ZK_PACOTE <> ' ' "
	_cQrySZ3 += " ) "

	// ordem dos dados
	_cQrySZ3 += "ORDER BY Z3_PROGRAM, Z3_ITEPROG, Z3_RIC "

	memowrit("c:\query\tfata002_sffrete.txt",_cQrySZ3)

	// verifica se o alias da query existe
	If (Select("_QRYFRETE") != 0)
		dbSelectArea("_QRYFRETE")
		dbCloseArea()
	Endif
	// executa a query
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQrySZ3),"_QRYFRETE",.F.,.T.)
	DbSelectArea("_QRYFRETE")

	// varre todos os registro selecionados
	While _QRYFRETE->(!EOF())

		cCt  := AAM->AAM_CONTRT
		cIt  := AAN->AAN_ITEM //cItem
		cPrd := Space(30)

		// se for pacote logistico, deixa valor 0 (zero)
		If (mvPacteLog)
			_nVlrFrete := 0
		Else
			//_nVlrFrete := sfTarifaFrete(@cCt, @cIt, @cPrd, _QRYFRETE->Z3_RIC, 'S')
			_nVlrFrete := sfTarifaFrete(AAM->AAM_CONTRT, AAN->AAN_ITEM, _QRYFRETE->Z3_RIC)
		EndIf

		// gera os dados do frete
		dbSelectArea("SZK")
		RecLock("SZK",.t.)
		SZK->ZK_FILIAL	:= xFilial("SZK")
		SZK->ZK_PROCES	:= _QRYFRETE->Z3_PROGRAM
		SZK->ZK_ITPROC	:= _QRYFRETE->Z3_ITEPROG
		SZK->ZK_CONTRT	:= AAM->AAM_CONTRT
		SZK->ZK_ITCONTR	:= If(mvTemContr,AAN->AAN_ITEM,"Z1")
		SZK->ZK_PRODUTO	:= If(mvTemContr,If(mvPacteLog,mvPactePrd,AAN->AAN_CODPRO),"")
		SZK->ZK_CLIENTE	:= AAM->AAM_CODCLI
		SZK->ZK_LOJA	:= AAM->AAM_LOJA
		SZK->ZK_VALOR	:= _nVlrFrete
		SZK->ZK_CONTAIN	:= _QRYFRETE->Z3_CONTAIN
		SZK->ZK_DTMOVIM	:= StoD(_QRYFRETE->Z3_DTMOVIM)
		SZK->ZK_TPMOVIM	:= _QRYFRETE->Z3_TPMOVIM
		SZK->ZK_RIC		:= _QRYFRETE->Z3_RIC
		SZK->ZK_TAMCONT	:= _QRYFRETE->Z3_TAMCONT
		SZK->ZK_CONTEUD	:= _QRYFRETE->Z3_CONTEUD
		SZK->ZK_TRANSP	:= _QRYFRETE->Z3_TRANSP
		SZK->ZK_PRCORIG	:= _QRYFRETE->Z3_PRCORIG
		SZK->ZK_PRCDEST	:= _QRYFRETE->Z3_PRCDEST
		SZK->ZK_FATURAR	:= "S"
		SZK->ZK_STATUS	:= " "
		SZK->ZK_IDPROCE	:= _cIdProc
		SZK->ZK_DTPROCE	:= _dDataBase
		SZK->ZK_USRPROC	:= __cUserId
		SZK->ZK_DATABAS	:= Date()
		// dados do pacote logistico
		If (mvPacteLog)
			SZK->ZK_PACOTE	:= SZJ->ZJ_PACOTE
			SZK->ZK_SEQPACO	:= SZJ->ZJ_SEQPACO
		EndIf
		MsUnLock()

		// proximo registro
		_QRYFRETE->(DBSKIP())
	EndDo

	// fecha alias do frete
	dbSelectArea("_QRYFRETE")
	dbCloseArea()

	// restaura area inicial
	RestArea(_aAreaAAN)
	RestArea(_aAreaAAM)
	RestArea(_aAreaSB1)
	RestArea(_aAreaAtu)

Return(.t.)

// ** funcao para calculo de servicos diversos
Static Function sfOutrosServicos(mvTemContr,mvPacteLog,mvPactePrd)
	// area inicial
	local _aAreaAtu := GetArea()
	local _cQrySZ6

	// quantidade de servicos
	local _nQtdServ := 0
	local _nSaldoSrv := 0
	// valor do servico
	local _nVlrServ := 0
	// valor total do servico
	local _nVlrTotal := 0
	// unidade cobranca
	local _cUnidCobr := ""
	// cubagem
	local _nCubagem := 0
	// peso bruto
	local _nPesoBru := 0

	// contrato, item e produto
	local _cSrvContrat := ""
	local _cSrvItContr := ""
	local _cSrvPrdCont := ""
	local _cSrvPacote  := ""
	local _cSrvSeqPac  := ""

	// OSs em aberto
	local _aOrdAbert := {}
	local _cMsgOS := ""

	// controle de atividade ok
	local _lAtivOk := .f.

	// varivel de retorno
	local _lRet := .f.

	// define padrao
	Default mvPacteLog := .f.

	// valida se o processo possui ordens de servico em abero
	If (_lMsgOsPend)
		// monta query
		_cQrySZ6 := "SELECT Z6_CODIGO, Z6_NUMOS, Z6_EMISSAO "
		// ordens de servico
		_cQrySZ6 += "FROM "+RetSqlName("SZ6")+" SZ6 "
		// cad. do processo
		_cQrySZ6 += "INNER JOIN "+RetSqlName("SZ1")+" SZ1 ON "+RetSqlCond("SZ1")+" AND Z1_CODIGO = Z6_CODIGO AND Z1_CONTRT = '"+AAM->AAM_CONTRT+"' "
		// filtro de ordens de servico em aberto
		_cQrySZ6 += "WHERE "+RetSqlCond("SZ6")+" "
		// sem data de finalizacao
		_cQrySZ6 += "AND Z6_DTFINAL = ' ' "
		// status de OS Aberta
		_cQrySZ6 += "AND Z6_STATUS  = 'A' "
		// filtra o cliente
		_cQrySZ6 += "AND Z6_CLIENTE = '"+AAM->AAM_CODCLI+"' AND Z6_LOJA = '"+AAM->AAM_LOJA+"' "
		// filtra o processo
		_cQrySZ6 += "AND Z6_CODIGO BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' "
		// ordem dos dados
		_cQrySZ6 += "ORDER BY Z6_CODIGO, Z6_NUMOS "
		// executa a query
		_aOrdAbert := U_SqlToVet(_cQrySZ6,{"Z6_EMISSAO"})

		memowrit("c:\query\sfOutrosServicos_emaberto.txt",_cQrySZ6)

		// apresenta mensagem caso tiver OS em aberto
		If ( ! _lWorkFlow).and.( Len(_aOrdAbert) > 0 )
			// zera mensagem
			_cMsgOS := "Contrato: "+AAM->AAM_CONTRT+" Item: "+If(mvTemContr,AAN->AAN_ITEM,"Z1")+CRLF+CRLF
			// atualiza todas as OS na mensagem
			aEval(_aOrdAbert,{|_aOrdAbert| _cMsgOS += "Processo: "+_aOrdAbert[1]+"    Nr OS: "+_aOrdAbert[2]+"   Data Abertura: "+DtoC(_aOrdAbert[3])+CRLF })
			// mensagem
			If (Aviso(	"TFATA002 -> sfOutrosServicos",;
			"ATENÇÃO: Processo possui ordens de serviço em aberta!"+CRLF+;
			_cMsgOS,;
			{"Ignorar","Continuar"},3)==1)

				// ignorar mensagens de ordens de servicos pendentes
				_lMsgOsPend := .f.

			EndIf

		EndIf

	EndIf

	// MOVIMENTACOES DE ORDEM DE SERVICO
	_cQrySZ6 := "SELECT Z6_EMISSAO, Z6_DTFINAL, Z6_CONTAIN, Z6_CODIGO, Z6_ITEM, Z7_NUMOS, Z6_TIPOMOV, Z7_CODATIV, Z7_QUANT, Z7_SALDO, Z7_FATURAR, Z7_TIPOPER, "
	_cQrySZ6 += "CONVERT(VarChar(8000), CONVERT(VarBinary(8000), Z6_OBSERVA)) AS Z6_OBSERVA, "
	_cQrySZ6 += "CONVERT(VarChar(8000), CONVERT(VarBinary(8000), Z7_OBSERVA)) AS Z7_OBSERVA, Z6_RIC, Z6_PEDIDO, Z6_DOCSERI, "
	// RECNO do SZ6
	_cQrySZ6 += "Z6.R_E_C_N_O_ SZ6RECNO, "
	// apresenta coluna com a quantidade ja apontada
	_cQrySZ6 += "(SELECT ISNULL(SUM(ZL_QUANT),0) FROM "+RetSqlName("SZL")+" SZL "
	_cQrySZ6 += "WHERE "+RetSqlCond("SZL")+" "
	_cQrySZ6 += "AND ZL_PROCES  = Z6_CODIGO AND ZL_ITPROC = Z6_ITEM "
	_cQrySZ6 += "AND ZL_CONTRT  = Z1_CONTRT "
	_cQrySZ6 += "AND ZL_CONTAIN = Z6_CONTAIN "
	_cQrySZ6 += "AND ZL_NUMOS   = Z6_NUMOS "
	_cQrySZ6 += "AND ZL_CODATIV = Z7_CODATIV "
	_cQrySZ6 += "AND ZL_DATABAS = '"+DtoS(Date())+"' "
	_cQrySZ6 += "AND ZL_DTPROCE = '"+DtoS(_dDataBase)+"' "
	_cQrySZ6 += "AND ZL_USRPROC = '"+__cUserId+"' "
	_cQrySZ6 += "AND ZL_IDPROCE = '"+_cIdProc+"' "
	_cQrySZ6 += "AND ZL_STATUS  = ' ' ) QTD_APONT "
	// tabela de ordem de servicos, itens e processo
	_cQrySZ6 += "FROM "+RetSqlName("SZ6")+" Z6, "+RetSqlName("SZ7")+" Z7, "+RetSqlName("SZ1")+" Z1 "
	// filtro padrao
	_cQrySZ6 += "WHERE Z6_FILIAL = '"+xfilial("SZ6")+"' AND Z6_FILIAL = Z7_FILIAL AND Z1_FILIAL = Z6_FILIAL AND Z6_NUMOS = Z7_NUMOS AND Z6_CODIGO = Z1_CODIGO "
	// data de finalizacao da OS
	_cQrySZ6 += "AND Z6_DTFINAL <= '"+DtoS(_dDataBase)+"' AND Z6_STATUS IN ('F','P') "
	_cQrySZ6 += "AND (Z7_DTFATAT = ' ' OR Z7_SALDO > 0) "
	_cQrySZ6 += "AND Z6_CLIENTE  = '"+AAM->AAM_CODCLI+"' AND Z6_LOJA   = '"+AAM->AAM_LOJA+"'  "
	_cQrySZ6 += "AND Z1_CONTRT   = '"+AAM->AAM_CONTRT+"' "
	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	If (mvStsProc==1) // aberto
		_cQrySZ6 += "AND Z1_DTFINFA = ' ' "
	ElseIf (mvStsProc==2) // encerrado
		_cQrySZ6 += "AND Z1_DTFINFA != ' ' "
	EndIf

	// se for pacote logistico, filtra o procecesso
	If (mvPacteLog)
		_cQrySZ6 += "AND  Z6_CODIGO  = '"+SZJ->ZJ_PROCES+"' "
		_cQrySZ6 += "AND  Z6_ITEM    = '"+SZJ->ZJ_ITPROC+"' "
		_cQrySZ6 += "AND (Z6_CONTAIN = '"+SZJ->ZJ_CONTAIN+"' OR Z6_CONTAIN = ' ') "

	Else
		_cQrySZ6 += "AND Z6_CODIGO BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' "
	EndIf
	_cQrySZ6 += "AND Z6.D_E_L_E_T_ = ' ' AND Z7.D_E_L_E_T_ = ' ' AND Z1.D_E_L_E_T_ = ' ' "
	_cQrySZ6 += "ORDER BY Z6_CODIGO, Z6_ITEM "

	memowrit("c:\query\sfservicos.txt",_cQrySZ6)

	// verifica se o alias da query existe
	If (Select("_QRYOUTSRV") != 0)
		dbSelectArea("_QRYOUTSRV")
		dbCloseArea()
	Endif
	// executa a query
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQrySZ6),"_QRYOUTSRV",.F.,.T.)
	DbSelectArea("_QRYOUTSRV")

	// varre todos os registro selecionados
	While _QRYOUTSRV->(!EOF())

		// quantidade de servicos
		_nQtdServ	:= _QRYOUTSRV->(Z7_SALDO - QTD_APONT)
		_nSaldoSrv	:= _QRYOUTSRV->(Z7_SALDO - QTD_APONT)

		// enquanto tiver saldo da quantidade do servico
		While (_nSaldoSrv > 0)

			// valores padroes do contrato, item e produto
			_cSrvContrat := AAM->AAM_CONTRT
			_cSrvItContr := If(mvTemContr,AAN->AAN_ITEM,"Z1")
			_cSrvPrdCont := If(mvTemContr,If(mvPacteLog,mvPactePrd,AAN->AAN_CODPRO),"")
			_cSrvPacote  := If(mvPacteLog,SZJ->ZJ_PACOTE,"")
			_cSrvSeqPac  := If(mvPacteLog,SZJ->ZJ_SEQPACO,"")
			_lAtivOk     := .f.

			// zera variaveis
			_cUnidCobr	:= ""
			_nCubagem	:= 0
			_nPesoBru	:= 0

			// busca o valor do servico
			_nVlrServ := sfTarifaAtv( mvPacteLog,;
			@_nQtdServ,;
			_QRYOUTSRV->Z7_CODATIV,;
			@_cUnidCobr,;
			_cSrvContrat,;
			@_cSrvItContr,;
			@_cSrvPrdCont,;
			_QRYOUTSRV->Z6_CODIGO,;
			_QRYOUTSRV->Z6_ITEM,;
			_QRYOUTSRV->Z6_CONTAIN,;
			@_cSrvPacote,;
			@_cSrvSeqPac,;
			@_nVlrTotal,;
			@_lAtivOk,;
			_QRYOUTSRV->SZ6RECNO,;
			@_nCubagem,;
			@_nPesoBru )

			// se nao foi possivel alocar a atividade, passa para outro servico
			If (!_lAtivOk)
				Exit
			EndIf

			// gera os dados dos servicos diversos
			dbSelectArea("SZL")
			RecLock("SZL",.t.)
			SZL->ZL_FILIAL	:= xFilial("SZL")
			SZL->ZL_PROCES	:= _QRYOUTSRV->Z6_CODIGO
			SZL->ZL_ITPROC	:= _QRYOUTSRV->Z6_ITEM
			SZL->ZL_CONTRT	:= _cSrvContrat
			SZL->ZL_ITCONTR	:= _cSrvItContr
			SZL->ZL_PRODUTO	:= _cSrvPrdCont
			SZL->ZL_CLIENTE	:= AAM->AAM_CODCLI
			SZL->ZL_LOJA	:= AAM->AAM_LOJA
			SZL->ZL_QUANT	:= _nQtdServ
			SZL->ZL_VLRUNIT	:= _nVlrServ
			SZL->ZL_TOTAL	:= _nVlrTotal
			SZL->ZL_CUBAGEM	:= _nCubagem
			SZL->ZL_PESOBRU	:= _nPesoBru
			SZL->ZL_CONTAIN	:= _QRYOUTSRV->Z6_CONTAIN
			SZL->ZL_PVCARRE	:= _QRYOUTSRV->Z6_PEDIDO
			SZL->ZL_NFCARRE	:= SubStr(_QRYOUTSRV->Z6_DOCSERI, 1,9)
			SZL->ZL_SERCARR	:= SubStr(_QRYOUTSRV->Z6_DOCSERI,10,3)
			SZL->ZL_DTINIOS	:= StoD(_QRYOUTSRV->Z6_EMISSAO) // ### VERIFICAR DATA DE INICIO E FIM DA OS
			SZL->ZL_DTFIMOS	:= StoD(_QRYOUTSRV->Z6_DTFINAL)
			//SZL->ZL_DTMOVIM	:= StoD(_QRYOUTSRV->Z6_EMISSAO)
			SZL->ZL_NUMOS	:= _QRYOUTSRV->Z7_NUMOS
			SZL->ZL_CODATIV	:= _QRYOUTSRV->Z7_CODATIV
			SZL->ZL_UNIDCOB	:= _cUnidCobr
			SZL->ZL_TIPOMOV	:= _QRYOUTSRV->Z6_TIPOMOV
			SZL->ZL_TPOPER	:= _QRYOUTSRV->Z7_TIPOPER
			SZL->ZL_OBS		:= _QRYOUTSRV->Z6_OBSERVA
			SZL->ZL_OBSITEM	:= _QRYOUTSRV->Z7_OBSERVA
			SZL->ZL_FATURAR	:= _QRYOUTSRV->Z7_FATURAR
			SZL->ZL_STATUS	:= " "
			SZL->ZL_IDPROCE	:= _cIdProc
			SZL->ZL_DTPROCE	:= _dDataBase
			SZL->ZL_USRPROC	:= __cUserId
			SZL->ZL_DATABAS	:= Date()
			// dados do pacote logistico
			If (mvPacteLog).and.(!Empty(_cSrvPacote))
				SZL->ZL_PACOTE	:= _cSrvPacote
				SZL->ZL_SEQPACO	:= _cSrvSeqPac
			EndIf
			MsUnLock()

			// diminui o saldo de apontamento
			_nSaldoSrv -= _nQtdServ

			// atualiza varivel de retorno
			_lRet := .t.

		EndDo

		// proximo registro
		_QRYOUTSRV->(DBSKIP())
	EndDo

	// fecha o alias
	If (Select("_QRYOUTSRV") != 0)
		dbSelectArea("_QRYOUTSRV")
		dbCloseArea()
	Endif

Return(_lRet)


// ** funcao que retorna o valor do frete conforme tabela de preco e pracas de origem e destino
Static Function sfTarifaFrete(mvContrt,mvItContr,mvRIC)
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSZ3 := SZ3->(GetArea())
	local _aAreaAAN := SZ3->(GetArea())
	// retorno do valor
	local _nRetPreco := 0
	// query
	local _cQrySZ5

	// posiciona no registro da movimentacao
	dbSelectArea("SZ3")
	SZ3->(dbOrderNickName("Z3_RIC"))
	SZ3->(dbSeek( xFilial("SZ3")+mvRIC ))

	// posiciona no item do contrato
	dbSelectArea("AAN")
	AAN->(dbSetOrder(1)) //1-AAN_FILIAL, AAN_CONTRT, AAN_ITEM
	AAN->(dbSeek( xFilial("AAN")+mvContrt+mvItContr ))

	// monta a query para pesquisar o valor do frete na tabela de precos
	_cQrySZ5 := "SELECT Z5_VALOR FROM "+RetSqlName("SZ5")+" SZ5 "
	_cQrySZ5 += "WHERE "+RetSqlCond("SZ5")+" "
	// codigo da tabela
	_cQrySZ5 += "AND Z5_CODIGO  = '"+AAN->AAN_TABELA+"' "
	// conteudo da carga
	_cQrySZ5 += "AND Z5_CONTEUD = '"+SZ3->Z3_CONTEUD+"' "
	// praca de origem / destino
	_cQrySZ5 += "AND ( ((Z5_PRCORIG + Z5_PRCDEST) LIKE '%"+SZ3->Z3_PRCORIG+"%') AND ((Z5_PRCORIG + Z5_PRCDEST) LIKE '%"+SZ3->Z3_PRCDEST+"%') )
	// executa a query
	_nRetPreco := U_FtQuery(_cQrySZ5)

	// restaura area inicial
	RestArea(_aAreaAAN)
	RestArea(_aAreaSZ3)
	RestArea(_aAreaAtu)

Return(_nRetPreco)

// ** funcao que valida se o servico faz parte de pacote logistico, calcula quantidade maximo do servico e retorna o valor do servico
Static Function sfTarifaAtv(mvPacote, mvQuant, mvCodAtiv, mvUnidCob, mvContrt, mvItCont, mvCodProd, mvNumProg, mvIteProg, mvContain, mvNumPaco, mvSeqPaco, mvVlrTotal, mvAtivOk, mvRecnoSZ6, mvCubagem, mvPesoBru)
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSZ9 := SZ9->(GetArea())
	local _aAreaSZT := SZT->(GetArea())
	local _aAreaSZ6 := SZ6->(GetArea())
	// variaveis temporarias
	local _cQuery
	// item do contrato para os servicos diversos
	local _aItemCont := {}
	// valor de retorno
	local _nRetValor := 0
	// quantidade ja utilizada no pacote
	local _nQtdUtil := 0
	// saldo a utilizar
	local _nSaldo := 0
	// valor minimo
	local _nVlrMin := 0.01
	// valor maximo
	local _nVlrMax := 99999999.99
	// verifica se utilizou o preco padrao
	local _lVlrPadr := .f.

	// pesquisa a atividade no item do contrato
	dbSelectArea("SZ9")
	SZ9->(dbSetOrder(1)) //1-Z9_FILIAL, Z9_CONTRAT, Z9_ITEM, Z9_CODATIV
	If SZ9->(dbSeek( xFilial("SZ9")+mvContrt+mvItCont+mvCodAtiv ))
		// verifica a quantidade maxima da atividade no contrato, quando for pacote logistico
		If (mvPacote)
			_cQuery := "SELECT ISNULL(SUM(ZL_QUANT),0) ZL_QUANT "
			_cQuery += "FROM "+RetSqlName("SZL")+" SZL "
			_cQuery += "WHERE "+RetSqlCond("SZL")+" "
			_cQuery += "AND ZL_PROCES  = '"+mvNumProg+"' AND ZL_ITPROC  = '"+mvIteProg+"' "
			_cQuery += "AND ZL_CONTRT  = '"+mvContrt+"'  AND ZL_ITCONTR = '"+mvItCont+"' "
			_cQuery += "AND ZL_DTPROCE = '"+DtoS(Date())+"' "
			_cQuery += "AND ZL_USRPROC = '"+__cUserId+"' "
			_cQuery += "AND ZL_IDPROCE = '"+_cIdProc+"' "
			_cQuery += "AND ZL_STATUS  = ' ' "
			_cQuery += "AND ZL_CONTAIN = '"+mvContain+"' "
			_cQuery += "AND ZL_CODATIV = '"+mvCodAtiv+"' "
			_cQuery += "AND ZL_PACOTE  = '"+mvNumPaco+"' AND ZL_SEQPACO = '"+mvSeqPaco+"' "
			// retorna o resultado da query
			_nQtdUtil := U_FtQuery(_cQuery)

			// calcula o saldo disponivel
			_nSaldo := (SZ9->Z9_MAXPACO - _nQtdUtil)
		Else
			_nSaldo := mvQuant
		EndIf

		// caso a quantidade esta dentro do permitido
		If (_nSaldo > 0).and.(mvQuant <= _nSaldo)
			// controle do retorno
			mvAtivOk := .t.
			// valor
			_nRetValor := SZ9->Z9_VALOR

			// quantidade maior que o saldo
		ElseIf (_nSaldo > 0).and.(mvQuant > _nSaldo)
			// atualiza a quantidade de acordo com o saldo
			mvQuant := _nSaldo
			// controle do retorno
			mvAtivOk := .t.
			// valor
			_nRetValor := SZ9->Z9_VALOR

			// se for dentro do pacote e nao tem mais saldo, encerra o processo para posterior alocacao em servicos diversos
		ElseIf (_nSaldo == 0)
			Return(_nRetValor)

		EndIf

		// define valor minimo e valor maximo do servico
		_nVlrMin := SZ9->Z9_VLRMIN
		_nVlrMax := SZ9->Z9_VLRMAX
		// unidade de medida de cobranca
		mvUnidCob := SZ9->Z9_UNIDCOB

	EndIf

	// quando for pacote logistico e nao encontrou o servico no pacote, pesquisa o valor da atividade no item dos 7-SERVICOS DIVERSOS do contrato
	If (!mvAtivOk).and.(mvPacote)
		// query para buscar o item de 7-SERVICOS DIVERSOS do contrato
		_cQuery := "SELECT AAN_ITEM, AAN_CODPRO FROM "+RetSqlName("AAN")+" AAN "
		// cad. de produtos
		_cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND B1_COD = AAN_CODPRO AND B1_TIPOSRV IN ('7') "
		// filtro padrao do item do contrato
		_cQuery += "WHERE "+RetSqlCond("AAN")+" "
		// numero do contrato
		_cQuery += "AND AAN_CONTRT = '"+mvContrt+"' "
		// alimenta o array
		_aItemCont := U_SqlToVet(_cQuery)

		// se encontrou 1 item, pesquisa o valor da atividade
		If (Len(_aItemCont)==1)
			// pesquisa a atividade no item de 7-servicos diverso
			dbSelectArea("SZ9")
			SZ9->(dbSetOrder(1)) //1-Z9_FILIAL, Z9_CONTRAT, Z9_ITEM, Z9_CODATIV
			If SZ9->(dbSeek( xFilial("SZ9")+mvContrt+_aItemCont[1][1]+mvCodAtiv ))
				// controle do retorno
				mvAtivOk := .t.
				// atualiza o valor
				_nRetValor	:= SZ9->Z9_VALOR
				// define valor minimo e valor maximo do servico
				_nVlrMin := SZ9->Z9_VLRMIN
				_nVlrMax := SZ9->Z9_VLRMAX
				// unidade de medida de cobranca
				mvUnidCob := SZ9->Z9_UNIDCOB
				// atualiza o item do contrato
				mvItCont	:= _aItemCont[1][1]
				// atualiza o produto do contrato
				mvCodProd	:= _aItemCont[1][2]
				// zera as informacoes do pacote
				mvNumPaco	:= ""
				// marca que nao eh mais pacote, para calcular valor minimo e valor maximo
				mvPacote := .f.
			EndIf

			// se encontrou mais de 1 item, apresenta mensagem de erro
		ElseIf (Len(_aItemCont) > 1)
			MsgStop("errrrrrrro")
			Return(0)
		EndIf
	EndIf

	// caso nao tenha encontrado o valor em nenhum do itens acima, demonstra o valor padrao
	If (!mvAtivOk)
		dbSelectArea("SZT")
		SZT->(dbSetOrder(1)) //1-ZT_FILIAL, ZT_CODIGO
		SZT->(dbSeek( xFilial("SZT")+mvCodAtiv ))
		// atualiza o valor
		_nRetValor	:= SZT->ZT_VALOR
		// unidade de medida de cobranca
		mvUnidCob := SZT->ZT_UM
		// atualiza o item do contrato
		mvItCont	:= "Z7"
		// atualiza o produto do contrato
		mvCodProd	:= ""
		// zera as informacoes do pacote
		mvNumPaco	:= ""
		// marca que nao eh mais pacote, para calcular valor minimo e valor maximo
		mvPacote    := .f.
		// controle do retorno
		mvAtivOk := .t.
		// define que utilizou o preco padrao
		_lVlrPadr := .t.
	EndIf

	// posiciona no registro real do cabecalho da OS
	dbSelectArea("SZ6")
	SZ6->(dbGoTo(mvRecnoSZ6))

	// para ordem de servico de SAIDA e unidade de medida M3, procurar a cubagem no pedido de venda
	If (SZ6->Z6_TIPOMOV == "S").and.(AllTrim(mvUnidCob)=="M3")
		// busca a cubagem do pedido de venda
		mvCubagem := sfRetInfPed(mvNumProg,SZ6->Z6_PEDIDO,"1")
		// calcula o valor total com base na cubagem
		mvVlrTotal := Round(mvCubagem * _nRetValor,2)

		// para ordem de servico de SAIDA unidade de medida TO, procurar o peso bruto no pedido de venda
	ElseIf (SZ6->Z6_TIPOMOV=="S").and.(AllTrim(mvUnidCob)=="TO")
		// busca a peso bruto do pedido de venda
		mvPesoBru := sfRetInfPed(mvNumProg,SZ6->Z6_PEDIDO,"2")
		// calcula o valor total com base no peso bruto
		mvVlrTotal := Round(mvPesoBru * _nRetValor,2)

		// para ordem de servico de ENTRADA unidade de medida M3, procurar a cubagem nas notas de entrada
	ElseIf (SZ6->Z6_TIPOMOV=="E").and.(AllTrim(mvUnidCob)=="M3")
		// busca a cubagem da nota de entrada
		mvCubagem := sfRetInfNfe(mvNumProg,mvIteProg,"1")
		// calcula o valor total com base na cubagem
		mvVlrTotal := Round(mvCubagem * _nRetValor,2)

		// para ordem de servico de ENTRADA unidade de medida TO, procurar o peso bruto nas notas de entrada
	ElseIf (SZ6->Z6_TIPOMOV=="E").and.(AllTrim(mvUnidCob)=="TO")
		// busca o peso bruto da nota de entrada
		mvPesoBru := sfRetInfNfe(mvNumProg,mvIteProg,"2")
		// calcula o valor total com base na cubagem
		mvVlrTotal := Round(mvPesoBru * _nRetValor,2)

		// outras situacoes
	Else
		// calcula o valor total
		mvVlrTotal := Round(mvQuant * _nRetValor,2)
	EndIf

	// define valor minimo e valor maximo do servico
	If (mvAtivOk).and.(!mvPacote).and.(!_lVlrPadr)
		// valor minimo
		If (mvVlrTotal < _nVlrMin)
			mvVlrTotal := _nVlrMin
			// valor maximo
		ElseIf (mvVlrTotal > _nVlrMax)
			mvVlrTotal := _nVlrMax
		EndIf
	EndIf

	// restaura area inicial
	RestArea(_aAreaSZ6)
	RestArea(_aAreaSZT)
	RestArea(_aAreaSZ9)
	RestArea(_aAreaAtu)

Return(_nRetValor)

// ** funcao para cobranca de valores fixos
Static Function sfFixo(mvTemContr)
	// area inicial
	local _aAreaAtu := GetArea()
	local _cQrySZM
	// valores do contrato
	local _nValor := If( !mvTemContr , 0, AAN->AAN_VLRUNI )
	// descricao do servico no contrato
	local _cDscProd := If( !mvTemContr , "", AllTrim(AAN->AAN_ZDESCR) )
	// data de referencia inicial
	local _dDtInic := CtoD("//")
	local _dDtFinal := CtoD("//")

	// busca a ultima data de faturamento do item do contrato
	_cQrySZM := "SELECT ISNULL(MAX(ZM_DTFIM),'') IT_DTBASE "
	// valore fixos
	_cQrySZM += "FROM "+RetSqlName("SZM")+" SZM "
	// filtro padrao
	_cQrySZM += "WHERE "+RetSqlCond("SZM")+" "
	_cQrySZM += "AND ZM_CLIENTE = '"+AAM->AAM_CODCLI+"' AND ZM_LOJA    = '"+AAM->AAM_LOJA+"' "
	_cQrySZM += "AND ZM_CONTRT  = '"+AAM->AAM_CONTRT+"' AND ZM_ITCONTR = '"+AAN->AAN_ITEM+"' "
	_cQrySZM += "AND ZM_IDPROCE = ' ' AND ZM_STATUS IN ('C','F') "
	// retorna a data
	_dDtInic := StoD(U_FtQuery(_cQrySZM))

	// se nao encontrou a data, utiliza a data inicial do contrato
	If Empty(_dDtInic)
		_dDtInic := _dIniVigen
	Else
		_dDtInic += 1
	EndIf

	// calcula a data final
	_dDtFinal := LastDay(_dDtInic)

	// gera valores de acordo com o periodo
	While (_dDtInic <= _dDataBase).and.(Day(_dDataBase) >= AAN->AAN_DIAFAT)

		// inclui o item
		dbSelectArea("SZM")
		RecLock("SZM",.t.)
		SZM->ZM_FILIAL	:= xFilial("SZM")
		SZM->ZM_CONTRT	:= AAM->AAM_CONTRT
		SZM->ZM_ITCONTR	:= If(mvTemContr,AAN->AAN_ITEM,"Z8")
		SZM->ZM_PRODUTO	:= If(mvTemContr,AAN->AAN_CODPRO,"")
		SZM->ZM_DSCPROD	:= _cDscProd + " (REF. "+Upper(MesExtenso(_dDtInic))+"/"+Str(Year(_dDtInic),4)+")"
		SZM->ZM_CLIENTE	:= AAM->AAM_CODCLI
		SZM->ZM_LOJA	:= AAM->AAM_LOJA
		SZM->ZM_VALOR	:= Round(_nValor,TamSx3("ZM_VALOR")[2])
		SZM->ZM_DTINI	:= _dDtInic
		SZM->ZM_DTFIM	:= _dDtFinal
		SZM->ZM_FATURAR	:= "S"
		SZM->ZM_STATUS	:= " "
		SZM->ZM_IDPROCE	:= _cIdProc
		SZM->ZM_DTPROCE	:= _dDataBase
		SZM->ZM_USRPROC	:= __cUserId
		SZM->ZM_DATABAS	:= Date()
		MsUnLock()

		// atualiza as datas
		_dDtInic  := _dDtFinal + 1
		_dDtFinal := LastDay(_dDtInic)

	EndDo

Return(.t.)

// ** funcao para calculo da armazenagem de container
Static Function sfArmzContainer(mvTemContr, mvNaoFatur)
	// area inicial
	local _aAreaAtu := GetArea()
	local _cQrySZ3
	// dias free do contrato
	local _nDayFree := 0
	// valor da tarifa por periodo
	local _nTarifa := If( !mvTemContr , 0, AAN->AAN_VLRUNI)
	// quantidade de periodos
	local _nQtdPeriodo := 1
	// qtd dias do periodo
	local _nQtdDiaPer := If( !mvTemContr , 1, AAN->AAN_QUANT)

	// quantidade de registros
	local _nQtdReg := 0

	// numero da RIC de saida
	local _cRICSaida

	// valores padroes
	Default mvNaoFatur := .f.


	// busca movimentacoes de container com devolucao (ja saiu)
	_cQrySZ3 := " SELECT "
	// configura a data inicial
	_cQrySZ3 += " CASE WHEN Z3_DTFATAR = ' ' THEN Z3_DTMOVIM ELSE Z3_DTFATAR END DTINICIO, "
	// configura a data final
	_cQrySZ3 += " CASE WHEN (Z3_DTSAIDA = ' ' OR Z3_DTSAIDA >= '"+DtoS(_dDataBase)+"') THEN '"+DtoS(_dDataBase)+"' ELSE Z3_DTSAIDA END DTFIM, "
	// demais campos
	_cQrySZ3 += " Z3_CONTAIN, Z3_PROGRAM, Z3_ITEPROG, Z3_RIC, Z3_TAMCONT, Z3_DTFATAR, Z3_DTMOVIM, Z3_DTSAIDA, SZ3.R_E_C_N_O_ SZ3RECNO "
	// movimentacao de carga
	_cQrySZ3 += " FROM "+RetSqlTab("SZ3")
	// dados do processo
	_cQrySZ3 += "INNER JOIN "+RetSqlTab("SZ1")+" ON "+RetSqlCond("SZ1")+" AND Z1_CODIGO = Z3_PROGRAM AND Z1_CONTRT = '"+AAM->AAM_CONTRT+"' "
	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	If (mvStsProc==1) // aberto
		_cQrySZ3 += " AND Z1_DTFINFA = ' ' "
	ElseIf (mvStsProc==2) // encerrado
		_cQrySZ3 += " AND Z1_DTFINFA != ' ' "
	EndIf
	// filtro das movimentacoes
	_cQrySZ3 += " WHERE "+RetSqlCond("SZ3")
	_cQrySZ3 += " AND Z3_PROGRAM BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' "
	_cQrySZ3 += " AND Z3_CLIENTE = '"+AAM->AAM_CODCLI+"' AND Z3_LOJA = '"+AAM->AAM_LOJA+"' "
	_cQrySZ3 += " AND Z3_TPMOVIM = 'E' "
	_cQrySZ3 += " AND "
	_cQrySZ3 += " ( "
	// filtro de container que já saiu
	_cQrySZ3 += "   ( Z3_DTSAIDA != ' ' AND Z3_DTSAIDA >= Z3_DTFATAR ) "
	_cQrySZ3 += "   OR "
	// container ainda no patio
	_cQrySZ3 += "   ( Z3_DTSAIDA  = ' ' AND Z3_DTMOVIM <= '"+DtoS(_dDataBase)+"' ) "
	_cQrySZ3 += " ) "
	// somente container
	_cQrySZ3 += " AND Z3_TIPCONT <> '99' "
	// filtra por tamanho do container (quando tem no contrato)
	If (mvTemContr).and.( ! Empty(AAN->AAN_TAMCON ))
		_cQrySZ3 += " AND Z3_TAMCONT = '"+AAN->AAN_TAMCON+"' "
	EndIf
	// somente movimentos que nao foram ignorados
	_cQrySZ3 += " AND Z3_DTFATAR < '" + DtoS(CtoD("31/12/2049")) + "' "

	memowrit("c:\query\sfArmzContainer.txt",_cQrySZ3)

	// verifica se o alias da query existe
	If (Select("_QRYARMCNT") != 0)
		dbSelectArea("_QRYARMCNT")
		dbCloseArea()
	Endif
	// executa a query
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQrySZ3),"_QRYARMCNT",.F.,.T.)
	DbSelectArea("_QRYARMCNT")

	// quantidade de registros da query
	Count to _nQtdReg

	// posiciona primeiro registro
	DbSelectArea("_QRYARMCNT")
	_QRYARMCNT->(dbGoTop())

	// se nao tem notas para ignorar
	If (mvNaoFatur).and.(_nQtdReg == 0)
		// mensagem
		MsgInfo("Não há movimentações para ignorar cobrança de ARMAZENAGEM DE CONTAINER.", "sfArmzContainer")
		// retorno
		Return(.t.)
	EndIf

	// aviso de quantidade de movimentacoes que nao vai faturar
	If (mvNaoFatur) .and. (Aviso("TFATA002 -> sfArmzContainer","Ignorar cobrança de "+AllTrim(Str(_nQtdReg))+" movimentos de veículos ?",{"Não","Sim"}) == 1)
		Return(.f.)
	EndIf

	// varre todos os registro selecionados
	While _QRYARMCNT->( ! EOF() )

		// posiciona no registro da nota fiscal
		dbSelectArea("SZ3")
		SZ3->(dbGoTo( _QRYARMCNT->SZ3RECNO ))

		// se for para ignorar, atualiza a data e gera log
		If (mvNaoFatur)

			// atualiza a ultima data de faturamento
			RecLock("SZ3",.F.)
			SZ3->Z3_DTFATAR	:= CtoD("31/12/2049")
			MsUnlock()

			// gera log
			U_FtGeraLog(cFilAnt, "SZ3", SZ3->(Z3_FILIAL + Z3_RIC), "Cobrança ignorada: Contrato configurado para não faturar ARMAZENAGEM DE CONTAINER", "FAT", SZ3->Z3_PROGRAM)

			// quando o container ja saiu, marca o movimento de saida como faturado
			If ( ! Empty(SZ3->Z3_DTSAIDA) )

				// funcao para pesquisar a RIC de saida
				_cRICSaida := U_FtRetRIC(SZ3->Z3_RIC)

				// atualiza os dados da movimentacao da unidade
				dbSelectArea("SZ3")
				SZ3->(dbOrderNickName("Z3_RIC")) // 4-Z3_FILIAL, Z3_RIC
				If SZ3->(dbSeek( xFilial("SZ3")+_cRICSaida ))
					// marca a data para o proximo faturamento
					RecLock("SZ3",.F.)
					SZ3->Z3_DTFATAR := CtoD("31/12/2049")
					MsUnlock()
				EndIf
			EndIF

			// proxima nota
			_QRYARMCNT->( dbSkip() )
			// loop
			Loop

		EndIf

		// calcula a quantidade de dias free da armazenagem
		If ( ! mvTemContr ).or.( ! Empty(_QRYARMCNT->Z3_DTFATAR) )
			_nDayFree := 0
		Else
			_nDayFree := AAN->AAN_DAYFRE
		EndIf

		// calcula a quantidade de periodos
		_nQtdPeriodo := sfPeriodo( StoD(_QRYARMCNT->DTFIM),; // data final
		StoD(_QRYARMCNT->DTINICIO)+_nDayFree,; // data incial
		_nQtdDiaPer)

		// se tem periodo pra cobranca, grava dados
		If (_nQtdPeriodo > 0)
			// gera os dados na tabela de detalhes
			dbSelectArea("SZG")
			RecLock("SZG",.t.)
			SZG->ZG_FILIAL	:= xFilial("SZG")
			SZG->ZG_PROCES	:= _QRYARMCNT->Z3_PROGRAM
			SZG->ZG_ITPROC	:= _QRYARMCNT->Z3_ITEPROG
			SZG->ZG_CONTRT	:= AAM->AAM_CONTRT
			SZG->ZG_ITCONTR	:= If(mvTemContr,AAN->AAN_ITEM,"Z1")
			SZG->ZG_PRODUTO	:= If(mvTemContr,AAN->AAN_CODPRO,"")
			SZG->ZG_CLIENTE	:= AAM->AAM_CODCLI
			SZG->ZG_LOJA	:= AAM->AAM_LOJA
			SZG->ZG_QUANT	:= _nQtdPeriodo
			SZG->ZG_VLRUNIT	:= Round(_nTarifa,TamSx3("ZG_VLRUNIT")[2])
			SZG->ZG_TOTAL	:= _nQtdPeriodo * _nTarifa
			SZG->ZG_DTINI	:= StoD(_QRYARMCNT->DTINICIO)+_nDayFree
			SZG->ZG_DTFIM	:= StoD(_QRYARMCNT->DTFIM)
			SZG->ZG_DIASPER	:= _nQtdDiaPer
			SZG->ZG_DAYFREE	:= _nDayFree
			SZG->ZG_CONTAIN	:= _QRYARMCNT->Z3_CONTAIN
			SZG->ZG_TAMCONT	:= _QRYARMCNT->Z3_TAMCONT
			SZG->ZG_RIC		:= _QRYARMCNT->Z3_RIC
			SZG->ZG_DTENTRA	:= StoD(_QRYARMCNT->Z3_DTMOVIM)
			SZG->ZG_DTSAIDA	:= StoD(_QRYARMCNT->Z3_DTSAIDA)
			SZG->ZG_FATURAR	:= "S"
			SZG->ZG_STATUS	:= " "
			SZG->ZG_IDPROCE	:= _cIdProc
			SZG->ZG_DTPROCE	:= _dDataBase
			SZG->ZG_USRPROC	:= __cUserId
			SZG->ZG_DATABAS	:= Date()
			SZG->ZG_DTANTER	:= StoD(_QRYARMCNT->Z3_DTFATAR)
			MsUnLock()
		EndIf

		// proximo container
		_QRYARMCNT->(dbSkip())
	EndDo

	// fecha o alias da query
	dbSelectArea("_QRYARMCNT")
	dbCloseArea()

	// restaura area inicial
	RestArea(_aAreaAtu)

Return(.t.)


// ** funcao para calculo da armazenagem de produtos
Static Function sfArmzProduto(mvTemContr, mvNaoFatur)
	// area inicial
	local _aAreaAtu := GetArea()
	// controle de validacao
	local _lRet := .t.
	// variaveis temporarias
	local _cQrySF1
	// data inicial de cobranca
	local _dDtInicial := CtoD("//")
	// data final do periodo de cobranca
	local _dDtFinal := CtoD("//")
	// quantidade de periodos para cobranca
	local _nPerAtu := 0
	local _aDetPeriodo := {}
	// quantidade de dias do periodo do cliente
	local _nQtdDiaPer := If( !mvTemContr , 120, AAN->AAN_QUANT)
	// tarifa por periodo
	local _nTarifa := If( !mvTemContr , 0, AAN->AAN_VLRUNI)
	// dias frees
	local _nDayFree := If( !mvTemContr , 0, AAN->AAN_DAYFRE)
	// tipo de armazenagem (se nao tem no contrato, usa por quantidade)
	local _cTipoArm := If( !mvTemContr , "4", AAN->AAN_TIPOAR )
	// grupo de estoque
	local _cGrpEsto := AAN->AAN_ZGRPES

	// tipo servico
	local _cTpServCntr := SB1->B1_TIPOSRV

	// saldo do periodo
	local _nSaldo := 0

	// data limite para o filtro
	local _dDtLimite := _dDataBase //If(_dDataBase >= Date(),_dDataBase-1,_dDataBase)

	// controle se é a primeira cobranca da nota fiscal
	local _lPrimCobr := .f.

	// quantidade de registros
	local _nQtdReg := 0

	// saldo dos itens da nota fiscal
	local _aSldItens := {}
	local _nSldItens

	// valor total por item (corrigir arredondamento)
	local _nVlrTotIt := 0

	// soma total do valor por item (corrigir arredondamento)
	local _nVlrTotal := 0

	// valores padroes
	Default mvNaoFatur := .f.

	// prepara a query
	_cQrySF1 := " SELECT DISTINCT F1_DTDIGIT, F1_EMISSAO, D1_DOC, D1_SERIE, D1_TIPO, D1_PROGRAM, D1_ITEPROG, F1_DTFATPR, F1_CUBAGEM, F1_PBRUTO, "
	// busca a referencia da entrada de container cheio
	_cQrySF1 += " (SELECT MIN(Z3_DTMOVIM) FROM "+RetSqlName("SZ3")+" WHERE Z3_FILIAL = D1_FILIAL AND Z3_PROGRAM = D1_PROGRAM AND Z3_ITEPROG = D1_ITEPROG "
	_cQrySF1 += " AND Z3_TPMOVIM = 'E' AND D_E_L_E_T_ = ' ' "
	// 08.09.11 - Toni - Somente Container Cheio
	_cQrySF1 += " AND Z3_CONTEUD = 'C') AS DT_CONTAIN, "
	// numero do contrato do cliente
	_cQrySF1 += " Z1_CONTRT, "
	// recno da nota de entrada
	_cQrySF1 += " SF1.R_E_C_N_O_ SF1RECNO "

	// nota fiscal de entrada
	_cQrySF1 += " FROM "+RetSqlTab("SF1")
	// itens da nota fiscal de entrada
	_cQrySF1 += " INNER JOIN "+RetSqlTab("SD1")+" ON "+RetSqlCond("SD1")+" AND D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE AND D1_FORNECE = F1_FORNECE AND D1_LOJA = F1_LOJA "
	_cQrySF1 += " AND D1_TIPO = F1_TIPO "
	// processo
	_cQrySF1 += " INNER JOIN "+RetSqlTab("SZ1")+" ON "+RetSqlCond("SZ1")+" AND Z1_CODIGO = F1_PROGRAM "
	// contrato do processo
	_cQrySF1 += " AND Z1_CONTRT = '"+AAM->AAM_CONTRT+"' "
	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	If (mvStsProc==1) // aberto
		_cQrySF1+=" AND Z1_DTFINFA = ' ' "
	ElseIf (mvStsProc==2) // encerrado
		_cQrySF1+=" AND Z1_DTFINFA != ' ' "
	EndIf

	// filtro das nota do cliente no processo
	_cQrySF1 += " WHERE "+RetSqlCond("SF1")
	// numero do processi
	_cQrySF1 += " AND F1_PROGRAM BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' "
	_cQrySF1 += " AND F1_PROGRAM <> ' ' AND F1_TIPO = 'B' "
	// data de digitacao da nota
	_cQrySF1 += " AND F1_DTDIGIT BETWEEN '"+DtoS(_dIniVigen)+"' AND '"+DtoS(_dDtLimite)+"' "
	// somente documentos que nao foram ignorados
	_cQrySF1 += " AND F1_DTFATPR < '" + DtoS(CtoD("31/12/2049")) + "' "

	// cliente
	_cQrySF1 += " AND F1_FORNECE = '"+AAM->AAM_CODCLI+"' AND F1_LOJA = '"+AAM->AAM_LOJA+"' "

	memowrit("c:\query\sfArmzProduto.txt",_cQrySF1)

	// verifica se o alias da query existe
	If (Select("_QRYARMPRD") != 0)
		dbSelectArea("_QRYARMPRD")
		dbCloseArea()
	Endif
	// executa a query
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQrySF1),"_QRYARMPRD",.F.,.T.)
	DbSelectArea("_QRYARMPRD")

	// quantidade de registros da query
	Count to _nQtdReg

	// posiciona primeiro registro
	DbSelectArea("_QRYARMPRD")
	_QRYARMPRD->(dbGoTop())

	// se nao tem notas para ignorar
	If (mvNaoFatur) .and. (_nQtdReg == 0)
		// mensagem
		MsgInfo("Não há documentos para ignorar cobrança de ARMAZENAGEM DE PRODUTOS.", "sfArmzProduto")
		// retorno
		Return(.t.)
	EndIf

	// aviso de quantidade de notas que nao vai faturar
	If (mvNaoFatur).and.(Aviso("TFATA002 -> sfArmzProduto","Ignorar cobrança de "+AllTrim(Str(_nQtdReg))+" documentos/notas fiscais ?",{"Não","Sim"}) == 1)
		Return(.f.)
	EndIf

	// varre todos os registro selecionados
	While _QRYARMPRD->( ! EOF() )

		// posiciona no registro da nota fiscal
		dbSelectArea("SF1")
		SF1->(dbGoTo( _QRYARMPRD->SF1RECNO ))

		// se for para ignorar, atualiza a data e gera log
		If (mvNaoFatur)

			// atualiza a ultima data de faturamento
			RecLock("SF1",.F.)
			SF1->F1_DTFATPR	:= CtoD("31/12/2049")
			MsUnlock()

			// gera log
			U_FtGeraLog(cFilAnt, "SF1", SF1->(F1_FILIAL + F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA + F1_TIPO), "Cobrança ignorada: Contrato configurado para não faturar ARMAZENAGEM DE PRODUTO", "FAT", SF1->F1_PROGRAM)

			// proxima nota
			_QRYARMPRD->( dbSkip() )
			// loop
			Loop

		EndIf

		// zera variaveis
		_dDtInicial := CtoD("//")
		_dDtFinal   := CtoD("//")
		// dias frees
		_nDayFree := If( !mvTemContr , 0, AAN->AAN_DAYFRE)
		// quantidade de dias do periodo do cliente
		_nQtdDiaPer := If( !mvTemContr , 120, AAN->AAN_QUANT)
		// tarifa por periodo
		_nTarifa := If( !mvTemContr , 0, AAN->AAN_VLRUNI)
		// controle se é a primeira cobranca da nota fiscal
		_lPrimCobr := .t.

		// define a data inicial de cobranca (data de digitacao da nota (F1_DTDIGIT) ou data de entrada no gate (SZ3))
		If (Empty(_QRYARMPRD->DT_CONTAIN))
			_dDtInicial := StoD(_QRYARMPRD->F1_DTDIGIT)
		ElseIf ( ! Empty(_QRYARMPRD->DT_CONTAIN))
			_dDtInicial := StoD(_QRYARMPRD->DT_CONTAIN)
		EndIf

		// se nao teve faturamento de armazenagem, adiciona Days Free
		If (Empty(_QRYARMPRD->F1_DTFATPR))
			// incrementa day free
			_dDtInicial += _nDayFree
			// primeira cobranca da nota fiscal
			_lPrimCobr := .t.

			// verifica a ultima data de faturamento de armazenagem
		ElseIf ( ! Empty(_QRYARMPRD->F1_DTFATPR))
			// define data inicial
			_dDtInicial := StoD(_QRYARMPRD->F1_DTFATPR)
			// se ja teve faturamento, zera os dias free
			_nDayFree := 0
			// ja houve cobranca anterior
			_lPrimCobr := .f.

		EndIf

		// calcula a quantidade de periodos para cobranca
		// estrutura: _aDetPeriodo
		// 1-Data Inicial
		// 2-Data Final
		// 3-Dias do Periodo
		// 4-Tarifa
		_aDetPeriodo := sfDetPeriodo( _dDtInicial,;	// data inicial
		_dDtLimite      ,; // data final (limite)
		_nQtdDiaPer     ,; // quant dias do periodo
		_cTpServCntr    ,; // tipo do servico do contato (2-armazenagem)
		_cTipoArm       ,; // tipo de armazenagem
		_nTarifa        ,; // tarifa de armazenagem
		AAM->AAM_CODCLI ,; // codigo do cliente
		AAM->AAM_LOJA   ,; // loja do cliente
		_lPrimCobr       ) // controle se eh primeira cobranca da nota fiscal

		// varre todos os periodos, calculando o saldo
		For _nPerAtu := 1 to Len(_aDetPeriodo)

			// atualiza a data inicial e final do periodo
			_dDtInicial := _aDetPeriodo[_nPerAtu][1]
			_dDtFinal   := _aDetPeriodo[_nPerAtu][2]

			// quantidade de dias do periodo
			_nQtdDiaPer := _aDetPeriodo[_nPerAtu][3]

			// atualiza tarifa
			_nTarifa    := _aDetPeriodo[_nPerAtu][4]

			// saldo dos itens da nota fiscal
			_aSldItens := {}

			// busca o saldo do produto (para saldo de quant, peso ou cubagem sempre passar mvFisrt como .f.)
			_nSaldo := sfSaldoNota(	_dDtInicial,;
			_dDtFinal            ,;
			AAM->AAM_CODCLI      ,;
			AAM->AAM_LOJA        ,;
			_QRYARMPRD->D1_DOC   ,;
			_QRYARMPRD->D1_SERIE ,;
			_cTipoArm            ,;
			.f.                  ,;
			@_lRet               ,;
			_cGrpEsto            ,;
			@_aSldItens           )

			// se cancelou, encerra
			If ( ! _lRet )
				Exit
			EndIf

			// se nao tiver mais saldo, encerra o calculo dos proximo periodos
			If (_nSaldo <= 0)
				Exit
			EndIf

			// se tem periodo pra cobranca, grava dados
			If (_nSaldo > 0)

				// soma total do valor por item (corrigir arredondamento)
				_nVlrTotal := 0

				// guarda o saldo por item da nota
				For _nSldItens := 1 to Len(_aSldItens)

					// valor total por item (corrigir arredondamento)
					_nVlrTotIt := Round( (_aSldItens[_nSldItens][4] * _nTarifa) ,2)

					// gera os dados na tabela de detalhes
					dbSelectArea("Z48")
					RecLock("Z48",.t.)
					Z48->Z48_FILIAL  := xFilial("Z48")
					Z48->Z48_PROCES  := _QRYARMPRD->D1_PROGRAM
					Z48->Z48_ITPROC  := _QRYARMPRD->D1_ITEPROG
					Z48->Z48_CONTRT  := AAM->AAM_CONTRT
					Z48->Z48_ITCONT  := IIf(mvTemContr, AAN->AAN_ITEM  , "Z2")
					Z48->Z48_SERVIC  := IIf(mvTemContr, AAN->AAN_CODPRO, ""  )
					Z48->Z48_CLIENT  := AAM->AAM_CODCLI
					Z48->Z48_LOJA    := AAM->AAM_LOJA
					Z48->Z48_DOC     := _QRYARMPRD->D1_DOC
					Z48->Z48_SERIE   := _QRYARMPRD->D1_SERIE
					Z48->Z48_TIPONF  := _QRYARMPRD->D1_TIPO
					Z48->Z48_ITEMNF  := _aSldItens[_nSldItens][1]
					Z48->Z48_PRODUT  := _aSldItens[_nSldItens][2]
					Z48->Z48_SALDO   := _aSldItens[_nSldItens][4]
					Z48->Z48_VLRUNI  := Round(_nTarifa, TamSx3("Z48_VLRUNI")[2])
					Z48->Z48_TOTAL   := _nVlrTotIt
					Z48->Z48_DTINI   := _dDtInicial
					Z48->Z48_DTFIM   := _dDtFinal
					Z48->Z48_DIASPE  := _nQtdDiaPer
					Z48->Z48_DAYFRE  := IIf(_nPerAtu > 1, 0, _nDayFree)
					Z48->Z48_TPARMA  := _cTipoArm
					Z48->Z48_FATURA  := "S"
					Z48->Z48_STATUS  := " "
					Z48->Z48_IDPROC  := _cIdProc
					Z48->Z48_DTPROC  := _dDataBase
					Z48->Z48_USRPRO  := __cUserId
					Z48->Z48_PERIOD  := _nPerAtu
					Z48->Z48_DTANTE  := StoD(_QRYARMPRD->F1_DTFATPR)
					Z48->Z48_DATABA  := Date()
					Z48->Z48_GRPEST  := _aSldItens[_nSldItens][3]
					MsUnLock()

					// soma total do valor por item (corrigir arredondamento)
					_nVlrTotal += _nVlrTotIt

				Next _nSldItens

				// gera os dados na tabela de detalhes
				dbSelectArea("SZH")
				RecLock("SZH",.t.)
				SZH->ZH_FILIAL   := xFilial("SZH")
				SZH->ZH_PROCES   := _QRYARMPRD->D1_PROGRAM
				SZH->ZH_ITPROC   := _QRYARMPRD->D1_ITEPROG
				SZH->ZH_CONTRT   := AAM->AAM_CONTRT
				SZH->ZH_ITCONTR  := If(mvTemContr,AAN->AAN_ITEM,"Z2")
				SZH->ZH_PRODUTO  := If(mvTemContr,AAN->AAN_CODPRO,"")
				SZH->ZH_CLIENTE  := AAM->AAM_CODCLI
				SZH->ZH_LOJA     := AAM->AAM_LOJA
				SZH->ZH_PERIODO  := _nPerAtu
				SZH->ZH_SALDO    := _nSaldo
				SZH->ZH_VLRUNIT  := Round(_nTarifa  ,TamSx3("ZH_VLRUNIT")[2])
				SZH->ZH_TOTAL    := Round(_nVlrTotal,TamSx3("ZH_TOTAL")[2]  )
				SZH->ZH_DTINI    := _dDtInicial
				SZH->ZH_DTFIM    := _dDtFinal
				SZH->ZH_DIASPER  := _nQtdDiaPer
				SZH->ZH_DAYFREE  := If(_nPerAtu > 1,0,_nDayFree)
				SZH->ZH_TPARMAZ  := _cTipoArm
				SZH->ZH_DOC      := _QRYARMPRD->D1_DOC
				SZH->ZH_SERIE    := _QRYARMPRD->D1_SERIE
				SZH->ZH_FATURAR  := "S"
				SZH->ZH_STATUS   := " "
				SZH->ZH_IDPROCE  := _cIdProc
				SZH->ZH_DTPROCE  := _dDataBase
				SZH->ZH_USRPROC  := __cUserId
				SZH->ZH_DATABAS  := Date()
				SZH->ZH_DTANTER  := StoD(_QRYARMPRD->F1_DTFATPR)
				SZH->ZH_GRPEST   := _cGrpEsto
				MsUnLock()

			EndIf

		Next _nPerAtu

		// proximo item
		_QRYARMPRD->(DBSKIP())

	ENDDO

	// fecha alias da query
	dbSelectArea("_QRYARMPRD")
	dbCloseArea()

	// restaura area inicial
	RestArea(_aAreaAtu)

Return(_lRet)

// ** funcao responsavel pelo calculo do seguro de mercadoria e transporte
Static Function sfSeguro(mvTemContr, mvSegTransp, mvNaoFatur)
	// area inicial
	local _aAreaAtu := GetArea()
	local _cQrySF1
	// dias free do contrato
	local _nDayFree := 0
	// quantidade de periodos
	local _nQtdPeriodo := 1
	// qtd dias do periodo
	local _nQtdDiaPer := If( !mvTemContr , 120, AAN->AAN_QUANT)
	// controle do loop de periodos
	local _nPerAtu := 0
	// valor da tarifa
	local _nTarifa := If( !mvTemContr , 0, AAN->AAN_VLRUNI)
	// saldo do periodo
	local _nSaldo := 0
	// data inicial de cobranca
	local _dDtInicial := CtoD("//")
	// data final do periodo de cobranca
	local _dDtFinal := CtoD("//")

	// variavel para controle do primeiro faturamento de seguro
	local _lFirst := .f.

	// controle se é a primeira cobranca da nota fiscal
	local _lPrimCobr := .f.

	// quantidade de registros
	local _nQtdReg := 0

	// saldo dos itens da nota fiscal
	local _aSldItens := {}
	local _nSldItens

	// valor total por item (corrigir arredondamento)
	local _nVlrTotIt := 0

	// soma total do valor por item (corrigir arredondamento)
	local _nVlrTotal := 0

	// valores padroes
	Default mvNaoFatur := .f.


	//  monta query para buscar as notas fiscais do processo
	_cQrySF1 := "SELECT DISTINCT F1_DTDIGIT, F1_EMISSAO, D1_DOC, D1_SERIE, D1_PROGRAM, D1_ITEPROG, F1_DTFATSE, D1_TIPO, "
	// busca a referencia da entrada de container
	_cQrySF1 += "(SELECT MIN(Z3_DTMOVIM) FROM "+RetSqlName("SZ3")+" WHERE Z3_FILIAL = D1_FILIAL AND Z3_PROGRAM = D1_PROGRAM AND Z3_ITEPROG = D1_ITEPROG "
	_cQrySF1 += " AND Z3_TPMOVIM = 'E' AND D_E_L_E_T_ = ' ') AS DT_CONTAIN, "
	// recno da nota de entrada
	_cQrySF1 += " SF1.R_E_C_N_O_ SF1RECNO "
	// itens da nota fiscal
	_cQrySF1 += " FROM "+RetSqlTab("SD1")
	// cabecalho da nota
	_cQrySF1 += " INNER JOIN "+RetSqlTab("SF1")+" ON "+RetSqlCond("SF1")+" AND F1_DOC = D1_DOC AND F1_SERIE = D1_SERIE AND F1_FORNECE = D1_FORNECE AND F1_LOJA = D1_LOJA AND F1_TIPO = D1_TIPO "
	_cQrySF1 += " AND F1_DTDIGIT BETWEEN '"+DtoS(_dIniVigen)+"' AND '"+DtoS(_dDataBase)+"' "
	// somente documentos que nao foram ignorados
	_cQrySF1 += " AND F1_DTFATSE < '" + DtoS(CtoD("31/12/2049")) + "' "
	// cad. programacao
	_cQrySF1 += " INNER JOIN "+RetSqlTab("SZ1")+" ON "+RetSqlCond("SZ1")+" AND Z1_CODIGO = D1_PROGRAM "
	_cQrySF1 += " AND Z1_CONTRT = '"+AAM->AAM_CONTRT+"' "
	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	If (mvStsProc==1) // aberto
		_cQrySF1 += " AND Z1_DTFINFA = ' ' "
	ElseIf (mvStsProc==2) // encerrado
		_cQrySF1 += " AND Z1_DTFINFA != ' ' "
	EndIf
	// filtro padrao
	_cQrySF1 += " WHERE "+RetSqlCond("SD1")
	// fornecedor/cliente e loja
	_cQrySF1 += " AND D1_FORNECE = '"+AAM->AAM_CODCLI+"' "
	_cQrySF1 += " AND D1_LOJA = '"+AAM->AAM_LOJA+"' "
	// programacao
	_cQrySF1 += " AND D1_PROGRAM BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' AND D1_PROGRAM <> ' ' "
	// tipo da nota
	_cQrySF1 += " AND D1_TIPO = 'B'

	memowrit("c:\query\sfseguro.txt",_cQrySF1)

	// verifica se o alias da query existe
	If (Select("_QRYSEGUR") != 0)
		dbSelectArea("_QRYSEGUR")
		dbCloseArea()
	Endif

	// executa a query
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQrySF1),"_QRYSEGUR",.F.,.T.)
	DbSelectArea("_QRYSEGUR")

	// quantidade de registros da query
	Count to _nQtdReg

	// posiciona primeiro registro
	DbSelectArea("_QRYSEGUR")
	_QRYSEGUR->(dbGoTop())

	// se nao tem notas para ignorar
	If (mvNaoFatur) .and. (_nQtdReg == 0)
		// mensagem
		MsgInfo("Não há documentos para ignorar cobrança de SEGURO", "sfSeguro")
		// retorno
		Return(.t.)
	EndIf

	// aviso de quantidade de notas que nao vai faturar
	If (mvNaoFatur) .and. (Aviso("TFATA002 -> sfSeguro","Ignorar cobrança de "+AllTrim(Str(_nQtdReg))+" documentos/notas fiscais ?",{"Não","Sim"}) == 1)
		Return(.f.)
	EndIf

	// varre todas as notas fiscais
	While _QRYSEGUR->( ! EOF() )

		// posiciona no registro da nota fiscal
		dbSelectArea("SF1")
		SF1->(dbGoTo( _QRYSEGUR->SF1RECNO ))

		// se for para ignorar, atualiza a data e gera log
		If (mvNaoFatur)

			// atualiza a ultima data de faturamento (ultimo dia mais 1)
			RecLock("SF1",.F.)
			SF1->F1_DTFATSE	:= CtoD("31/12/2049")
			MsUnlock()

			// gera log
			U_FtGeraLog(cFilAnt, "SF1", SF1->(F1_FILIAL + F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA + F1_TIPO), "Cobrança ignorada: Contrato configurado para não faturar SEGURO", "FAT", SF1->F1_PROGRAM)

			// proxima nota
			_QRYSEGUR->( dbSkip() )
			// loop
			Loop

		EndIf

		// zera variaveis
		_dDtInicial := CtoD("//")
		_dDtFinal := CtoD("//")

		// define a data inicial de cobranca (data de digitacao da nota (F1_DTDIGIT) ou data de entrada no gate (SZ3))
		If (Empty(_QRYSEGUR->DT_CONTAIN))
			_dDtInicial := StoD(_QRYSEGUR->F1_DTDIGIT)
		ElseIf ( ! Empty(_QRYSEGUR->DT_CONTAIN))
			_dDtInicial := StoD(_QRYSEGUR->DT_CONTAIN)
		EndIf

		// se nao teve faturamento de seguros, adiciona Days Free
		If (Empty(_QRYSEGUR->F1_DTFATSE))
			// incrementa day free
			_dDtInicial += _nDayFree
			// primeira cobranca da nota fiscal
			_lPrimCobr := .t.

			// verifica a ultima data de faturamento de seguros
		ElseIf ( ! Empty(_QRYSEGUR->F1_DTFATSE))
			// define data inicial
			_dDtInicial := StoD(_QRYSEGUR->F1_DTFATSE)
			// se ja teve faturamento, zera os dias free
			_nDayFree := 0
			// ja houve cobranca anterior
			_lPrimCobr := .f.

		EndIf


		// calcula a quantidade de periodos
		_nQtdPeriodo := sfPeriodo( _dDataBase ,; // data final
		_dDtInicial ,; // data incial
		_nQtdDiaPer)


		// varre todos os periodos, calculando o saldo
		For _nPerAtu := 1 To _nQtdPeriodo

			// verifica se eh o primeiro faturamento do seguro
			_lFirst := (Empty(_QRYSEGUR->F1_DTFATSE)).and.(_nPerAtu==1)

			// atualiza a data inicial do periodo
			If ( ! Empty(_dDtFinal))
				_dDtInicial += _nQtdDiaPer
			EndIf

			// atualiza a data final do periodo
			// obs: -1 pra considerar periodo contando o primeiro dia da data inicial
			_dDtFinal := (_dDtInicial + _nQtdDiaPer) - 1

			// saldo dos itens da nota fiscal
			_aSldItens := {}

			// calcula o saldo em aberto
			_nSaldo := sfSaldoNota(	_dDtInicial, ;
			_dDtFinal          ,;
			AAM->AAM_CODCLI    ,;
			AAM->AAM_LOJA      ,;
			_QRYSEGUR->D1_DOC  ,;
			_QRYSEGUR->D1_SERIE,;
			'V'                ,;
			_lFirst            ,;
			Nil                ,;
			Nil                ,;
			@_aSldItens         )

			// se nao tiver mais saldo, encerra o calculo dos proximo periodos
			If (_nSaldo <= 0.30)
				Exit
			EndIf

			// se tem saldo a faturar
			If (_nSaldo > 0)

				// soma total do valor por item (corrigir arredondamento)
				_nVlrTotal := 0

				// guarda o saldo por item da nota
				For _nSldItens := 1 to Len(_aSldItens)

					// valor total por item (corrigir arredondamento)
					_nVlrTotIt := Round( (_aSldItens[_nSldItens][4] * _nTarifa) / 100 ,2)

					// gera os dados na tabela de detalhes
					dbSelectArea("Z48")
					RecLock("Z48",.t.)
					Z48->Z48_FILIAL  := xFilial("Z48")
					Z48->Z48_PROCES  := _QRYSEGUR->D1_PROGRAM
					Z48->Z48_ITPROC  := _QRYSEGUR->D1_ITEPROG
					Z48->Z48_CONTRT  := AAM->AAM_CONTRT
					Z48->Z48_ITCONT  := IIf(mvTemContr, AAN->AAN_ITEM  , "Z2")
					Z48->Z48_SERVIC  := IIf(mvTemContr, AAN->AAN_CODPRO, ""  )
					Z48->Z48_CLIENT  := AAM->AAM_CODCLI
					Z48->Z48_LOJA    := AAM->AAM_LOJA
					Z48->Z48_DOC     := _QRYSEGUR->D1_DOC
					Z48->Z48_SERIE   := _QRYSEGUR->D1_SERIE
					Z48->Z48_TIPONF  := _QRYSEGUR->D1_TIPO
					Z48->Z48_ITEMNF  := _aSldItens[_nSldItens][1]
					Z48->Z48_PRODUT  := _aSldItens[_nSldItens][2]
					Z48->Z48_SALDO   := _aSldItens[_nSldItens][4]
					Z48->Z48_VLRUNI  := Round(_nTarifa, TamSx3("Z48_VLRUNI")[2])
					Z48->Z48_TOTAL   := _nVlrTotIt
					Z48->Z48_DTINI   := _dDtInicial
					Z48->Z48_DTFIM   := _dDtFinal
					Z48->Z48_DIASPE  := _nQtdDiaPer
					Z48->Z48_DAYFRE  := _nDayFree
					Z48->Z48_TPARMA  := "V"
					Z48->Z48_FATURA  := "S"
					Z48->Z48_STATUS  := " "
					Z48->Z48_IDPROC  := _cIdProc
					Z48->Z48_DTPROC  := _dDataBase
					Z48->Z48_USRPRO  := __cUserId
					Z48->Z48_PERIOD  := _nPerAtu
					Z48->Z48_DTANTE  := StoD(_QRYSEGUR->F1_DTFATSE)
					Z48->Z48_DATABA  := Date()
					MsUnLock()

					// soma total do valor por item (corrigir arredondamento)
					_nVlrTotal += _nVlrTotIt

				Next _nSldItens


				// gera os dados na tabela de detalhes
				dbSelectArea("SZI")
				RecLock("SZI",.t.)
				SZI->ZI_FILIAL	:= xFilial("SZI")
				SZI->ZI_PROCES	:= _QRYSEGUR->D1_PROGRAM
				SZI->ZI_ITPROC	:= _QRYSEGUR->D1_ITEPROG
				SZI->ZI_CONTRT	:= AAM->AAM_CONTRT
				SZI->ZI_ITCONTR	:= IIf(mvTemContr, AAN->AAN_ITEM  , "Z2")
				SZI->ZI_PRODUTO	:= IIf(mvTemContr, AAN->AAN_CODPRO, "")
				SZI->ZI_CLIENTE	:= AAM->AAM_CODCLI
				SZI->ZI_LOJA	:= AAM->AAM_LOJA
				SZI->ZI_PERIODO	:= _nPerAtu
				SZI->ZI_VLRUNIT	:= Round(_nTarifa  ,TamSx3("ZI_VLRUNIT")[2])
				SZI->ZI_TOTAL	:= Round(_nVlrTotal,TamSx3("ZI_TOTAL")[2]  )
				SZI->ZI_SALDO	:= _nSaldo
				SZI->ZI_DTINI	:= _dDtInicial
				SZI->ZI_DTFIM	:= _dDtFinal
				SZI->ZI_DIASPER	:= _nQtdDiaPer
				SZI->ZI_DAYFREE	:= _nDayFree
				SZI->ZI_DOC		:= _QRYSEGUR->D1_DOC
				SZI->ZI_SERIE	:= _QRYSEGUR->D1_SERIE
				SZI->ZI_DTDOC	:= StoD(_QRYSEGUR->F1_DTDIGIT)
				SZI->ZI_FATURAR	:= "S"
				SZI->ZI_STATUS	:= " "
				SZI->ZI_IDPROCE	:= _cIdProc
				SZI->ZI_DTPROCE	:= _dDataBase
				SZI->ZI_USRPROC	:= __cUserId
				SZI->ZI_DATABAS	:= Date()
				SZI->ZI_DTANTER	:= StoD(_QRYSEGUR->F1_DTFATSE)
				SZI->(MsUnLock())

			EndIf

			// proximo periodo
		Next _nPerAtu

		// proxima nota
		_QRYSEGUR->(DBSKIP())

	ENDDO

Return(.t.)

// ** funcao que calcula o saldo total da nota
Static Function sfSaldoNota(mvDtIni, mvDtFim, cCliente, cLoja, cnota, cserie, mvTipo, mvFirst, mvRet, mvGrpEsto, mvSldItens)
	// area inicial
	local _aAreaAtu := GetArea()
	// variavel de retorno
	local _nRetValor := 0
	// variavel temporaria
	local _cQuery
	// campo chave para total entrada
	local _cExpEntra
	// campo chave para total saida
	local _cExpSaida
	// saldo do item
	local _nSldItem := 0

	// controle de uso de grupo de estoque ativo
	local _lUsoGrpEst := U_FtWmsParam("WMS_USA_GRUPO_ESTOQUE","L",.f.,.f.,Nil, cCliente, cLoja, AAM->AAM_CONTRT, Nil)

	// validacao se ha grupo de estoque no cadastro do produto
	If (_lUsoGrpEst).and.(mvTipo <> "V").and.(Empty(mvGrpEsto))
		// quando for workflow, encerra a pesquisa
		If (_lWorkFlow)
			// zera variaveis
			_nRetValor := 0
			mvRet := .f.
			Return(mvRet)

			// mensagem de falta de informacao
		ElseIf (!_lWorkFlow)
			Aviso(	"TFATA002 -> sfSaldoNota",;
			"ATENÇÃO: Não há Grupo de Estoque informado neste item do contrato" +CRLF+;
			"Item do Contrato: "+AAN->AAN_ITEM ,;
			{"Fechar"},3)
			// zera variaveis
			_nRetValor := 0
			mvRet := .f.
			Return(mvRet)
		EndIf
	EndIf

	// Daniel 20/04 solicitou via email para considerar saldo do produto sempre do dia anterior
	// considerar o ultimo saldo valido antes de iniciar o periodo (saldo da meia-noite)
	// conforme chamado 5734, o saldo de cobraca devera ser igual para todas as formas de cobranca, inclusive seguro
	mvDtIni -= 1

	// monta a expressao de calculo do retorno
	Do Case
		Case (mvTipo == "V") // V-Valor
		_cExpEntra := "ROUND((B6_QUANT * B6_PRUNIT),2)"
		_cExpSaida := "ROUND((D2_QUANT * D2_PRCVEN),2)"

		Case (mvTipo == "1") // 1-Cubagem
		_cExpEntra := "D1_ZCUBAGE"
		_cExpSaida := "D2_ZCUBAGE"

		Case (mvTipo == "2") // 2-Peso Bruto (por TON)
		_cExpEntra := "D1_ZPESOB / 1000"
		_cExpSaida := "D2_ZPESOB / 1000"

		Case (mvTipo == "3") // 3- Posicao Pallet
		_cExpEntra := "B6_QUANT"
		_cExpSaida := "D2_QUANT"

		Case (mvTipo == "4") // 4- Quantidade
		_cExpEntra := "B6_QUANT"
		_cExpSaida := "D2_QUANT"

		Case (mvTipo == "5") // 5-Peso Liquido (por TON)
		_cExpEntra := "D1_ZPESOL / 1000"
		_cExpSaida := "D2_ZPESOL / 1000"

	EndCase

	// monta a query
	_cQuery := "SELECT "
	// quantidade de entrada
	_cQuery += " "+_cExpEntra+" IT_ENTRADA "
	// quantidade de saida
	_cQuery += " ,	ISNULL( ( "
	_cQuery += " 		SELECT SUM("+_cExpSaida+")  "
	_cQuery += " 		FROM "+RetSqlName("SD2")+" SD2 "
	_cQuery += " 		WHERE SD2.D2_FILIAL   = SB6ENT.B6_FILIAL AND SD2.D_E_L_E_T_ = ' ' "
	_cQuery += "          AND ((SD2.D2_CLIENTE  = SB6ENT.B6_CLIFOR AND SD2.D2_LOJA = SB6ENT.B6_LOJA) OR (SD2.D2_CLIENTE = '000140')) "
	_cQuery += "          AND SD2.D2_NFORI    = SB6ENT.B6_DOC AND SD2.D2_SERIORI = SB6ENT.B6_SERIE "
	_cQuery += "          AND SD2.D2_COD      = SB6ENT.B6_PRODUTO "
	_cQuery += "          AND SD2.D2_IDENTB6  = SB6ENT.B6_IDENT "
	_cQuery += " 		  AND SD2.D2_EMISSAO <= '"+DtoS(mvDtIni)+"' "
	_cQuery += " 		) ,0 ) IT_SAIDA, "
	// informacoes da nota pra mensagem
	_cQuery += "D1_DOC, D1_SERIE, D1_ITEM, D1_COD, D1_PROGRAM, "
	// grupo de estoque do produto
	_cQuery += "B1_ZGRPEST, "
	// procura produtos sem grupo de estoque
	_cQuery += "(SELECT COUNT(*) FROM "+RetSqlName("AAN")+" AAN "
	_cQuery += "WHERE "+RetSqlCond("AAN")+" AND AAN_CONTRT = '"+AAM->AAM_CONTRT+"' "
	_cQuery += "AND B1_ZGRPEST LIKE ('%'+RTRIM(LTRIM(AAN_ZGRPES))+'%') AND AAN_CODPRO = '"+AAN->AAN_CODPRO+"' ) QTD_GRPEST "

	// para PESO ou CUBAGEM, procura itens com PESO ou CUBAGEM zerados (somente diferente de valores)
	If (mvTipo $ "1|2|5") // quando for 1-CUBAGEM ou 2-PESO BRUTO ou 5-PESO LIQUIDO
		// se nao for o primeiro faturamento, pesquisa itens de saida com valoers zerados
		If (!mvFirst)
			_cQuery  += ", (SELECT COUNT(*) "
			_cQuery  += "FROM "+RetSqlName("SB6")+" B6SAIDA "
			_cQuery	+= "INNER JOIN "+RetSqlName("SD2")+" SD2 ON SD2.D2_FILIAL = B6SAIDA.B6_FILIAL AND SD2.D_E_L_E_T_ = ' ' "
			_cQuery	+= "      AND SD2.D2_IDENTB6 = B6SAIDA.B6_IDENT "
			_cQuery	+= "      AND SD2.D2_DOC = B6SAIDA.B6_DOC AND SD2.D2_SERIE = B6SAIDA.B6_SERIE "
			_cQuery	+= "      AND ((SD2.D2_CLIENTE = B6SAIDA.B6_CLIFOR AND SD2.D2_LOJA = B6SAIDA.B6_LOJA) OR (SD2.D2_CLIENTE = '000140')) "
			_cQuery	+= "      AND SD2.D2_COD = B6SAIDA.B6_PRODUTO "
			_cQuery	+= "      AND "+If(mvTipo=="1","SD2.D2_ZCUBAGE",If(mvTipo=="2","SD2.D2_ZPESOB","SD2.D2_ZPESOL"))+" <= 0 "
			_cQuery	+= "WHERE B6SAIDA.B6_FILIAL = SB6ENT.B6_FILIAL AND B6SAIDA.D_E_L_E_T_ = ' ' "
			_cQuery	+= "      AND B6SAIDA.B6_IDENT = SB6ENT.B6_IDENT "
			_cQuery	+= "      AND B6SAIDA.B6_PODER3 = 'D' "
			_cQuery	+= "      AND B6SAIDA.B6_TPCF = 'C' "
			_cQuery	+= "      AND B6SAIDA.B6_EMISSAO <= '"+DtoS(mvDtIni)+"') QTD_ZERO "
		EndIf
	EndIf

	// saldo poder de terceiros
	_cQuery += "FROM "+RetSqlName("SB6")+" SB6ENT "

	// cad. de produto
	_cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND B1_COD = SB6ENT.B6_PRODUTO "

	// nota fiscal de entrada
	_cQuery += "INNER JOIN "+RetSqlName("SD1")+" SD1 ON "+RetSqlCond("SD1")+" AND D1_IDENTB6 = B6_IDENT "

	// filtro da nota de entrada
	_cQuery += "WHERE SB6ENT.B6_FILIAL = '"+xFilial("SB6")+"' AND SB6ENT.D_E_L_E_T_ = ' ' "
	_cQuery += "AND SB6ENT.B6_DOC    = '"+cNota+"'    AND SB6ENT.B6_SERIE = '"+cSerie+"' "
	_cQuery += "AND SB6ENT.B6_CLIFOR = '"+cCliente+"' AND SB6ENT.B6_LOJA  = '"+cLoja+"' "
	_cQuery += "AND SB6ENT.B6_TPCF   = 'C' "
	_cQuery += "AND SB6ENT.B6_PODER3 = 'R' "

	memowrit("c:\query\tfata002_sfSaldoNota.txt",_cQuery)

	If Select("_QRYSLDVLR") <> 0
		dbSelectarea("_QRYSLDVLR")
		dbCloseArea()
	EndIf

	//TCQuery Abre uma workarea com o resultado da query
	TCQUERY _cQuery ALIAS _QRYSLDVLR NEW

	dbSelectarea("_QRYSLDVLR")
	While _QRYSLDVLR->(!Eof())

		// validacao se ha grupo de estoque no cadastro do produto
		If (_lUsoGrpEst).and.(mvTipo <> "V").and.(Empty(_QRYSLDVLR->B1_ZGRPEST))
			// quando for workflow, encerra a pesquisa
			If (_lWorkFlow)
				// zera variaveis
				_nRetValor := 0
				mvRet := .f.
				Exit

				// mensagem de falta de informacao
			ElseIf (!_lWorkFlow)
				Aviso(	"TFATA002 -> sfSaldoNota",;
				"ATENÇÃO: Não há Grupo de Estoque para o produto "+_QRYSLDVLR->D1_COD +CRLF+;
				"Processo: "+_QRYSLDVLR->D1_PROGRAM +CRLF+;
				"Nota Entrada: "+_QRYSLDVLR->D1_DOC+" / "+_QRYSLDVLR->D1_SERIE +CRLF+;
				"Item: "+_QRYSLDVLR->D1_ITEM ,;
				{"Fechar"},3)
				// zera variaveis
				_nRetValor := 0
				mvRet := .f.
				Exit
			EndIf
		EndIf

		// validacao se todos os grupos de estoque dos produtos estoa no contrato
		If (_lUsoGrpEst).and.(mvTipo <> "V").and.(_QRYSLDVLR->QTD_GRPEST == 0)
			// quando for workflow, encerra a pesquisa
			If (_lWorkFlow)
				// zera variaveis
				_nRetValor := 0
				mvRet := .f.
				Exit

				// mensagem de falta de informacao
			ElseIf (!_lWorkFlow)
				Aviso(	"TFATA002 -> sfSaldoNota",;
				"ATENÇÃO: O Grupo de Estoque do produto "+_QRYSLDVLR->D1_COD+" não está relacionado neste contrato" +CRLF+;
				"Processo: "+_QRYSLDVLR->D1_PROGRAM +CRLF+;
				"Nota Entrada: "+_QRYSLDVLR->D1_DOC+" / "+_QRYSLDVLR->D1_SERIE +CRLF+;
				"Item: "+_QRYSLDVLR->D1_ITEM ,;
				{"Fechar"},3)
				// zera variaveis
				_nRetValor := 0
				mvRet := .f.
				Exit
			EndIf
		EndIf

		// calcula o saldo do grupo de estoque de cada produto
		If ( ! _lUsoGrpEst ).or.(mvTipo == "V").or.((_lUsoGrpEst).and.(mvTipo <> "V").and.(_QRYSLDVLR->B1_ZGRPEST $ mvGrpEsto))

			// saldo do item
			_nSldItem := (_QRYSLDVLR->IT_ENTRADA - ( IIf(!mvFirst,_QRYSLDVLR->IT_SAIDA,0)) )

			// soma o valor do retorno
			_nRetValor += _nSldItem

			// mensagem informando falta de informacao de peso e cubagem
			If (mvTipo $ "1|2|5")
				// verifica a quantidade de entrada
				If (_QRYSLDVLR->IT_ENTRADA <= 0).or.((!mvFirst).and.(_QRYSLDVLR->QTD_ZERO > 0))
					// quando for workflow, encerra a pesquisa
					If (_lWorkFlow)
						// zera variaveis
						_nRetValor := 0
						mvRet := .f.
						Exit

						// mensagem de falta de informacao
					ElseIf (!_lWorkFlow)
						If (Aviso(	"TFATA002 -> sfSaldoNota",;
						"ATENÇÃO: Não há "+If(mvTipo=="1","CUBAGEM",If(mvTipo=="2","PESO BRUTO","PESO LIQUIDO"))+" informado nesta nota. Favor solicitar o recálculo de peso desta programação."+CRLF+;
						"Processo: "+_QRYSLDVLR->D1_PROGRAM +CRLF+;
						"Nota Entrada: "+_QRYSLDVLR->D1_DOC+" / "+_QRYSLDVLR->D1_SERIE +CRLF+;
						"Item: "+_QRYSLDVLR->D1_ITEM +CRLF+;
						"Produto: "+_QRYSLDVLR->D1_COD +CRLF+;
						"Data Ref.: "+DtoC(mvDtIni) ,;
						{"Fechar","Continuar"},3)==1)
							// zera variaveis
							_nRetValor := 0
							mvRet := .f.
							Exit
						EndIf
					EndIf
				EndIf
			EndIf

			// inclui o saldo do item
			If (_nSldItem > 0)
				aAdd(mvSldItens, {;
				_QRYSLDVLR->D1_ITEM    ,; // item nota
				_QRYSLDVLR->D1_COD     ,; // codigo do produto
				_QRYSLDVLR->B1_ZGRPEST ,; // grupo de estoque
				_nSldItem              }) // saldo do item
			EndIf

		EndIf

		// proximo valor
		_QRYSLDVLR->(DbSkip())
	EndDo

	// fecha alias da query
	dbSelectarea("_QRYSLDVLR")
	dbCloseArea()

	// restaura area inicial
	RestArea(_aAreaAtu)

Return(_nRetValor)

// ** funcao para calcula o periodo
Static Function sfPeriodo(mvDtFim, mvDtIni, mvDiasPer)
	// variavel de retorno
	local _nQtdPer := 0
	// quantidade de dias entre periodos
	local _nDiasPer := 0
	// fracao de periodo
	local _nFracPer := 0

	// se data final for menor que data inicial, retorno 0 periodos
	If (mvDtFim < mvDtIni)
		Return (_nQtdPer)
	EndIf

	// calcula quantidade de dias entre o periodos
	_nDiasPer := (mvDtFim - mvDtIni) + 1

	// calcula quantidade de periodos
	_nQtdPer  := Int(_nDiasPer / mvDiasPer)

	// calcula fracao do periodo
	_nFracPer := Mod(_nDiasPer, mvDiasPer)

	// quando ha fracao, inclui novo periodo
	If (_nFracPer > 0)
		_nQtdPer ++
	EndIf

Return(_nQtdPer)

// ** funcao para calcular os detalhes do periodo
Static Function sfDetPeriodo(mvDtIni, mvDtFim, mvDiasPer, mvTpServ, mvTpArmz, mvTarifa, mvCodCli, mvLojCli, mvPrimCobr)
	// variavel de retorno - estrutura

	// 1-Data Inicial
	// 2-Data Final
	// 3-Dias do Periodo
	// 4-Tarifa
	local _aDetPeriodo := {}

	// data inicial e final do period
	local _dDtIni := mvDtIni
	local _dDtFim := CtoD("//")

	// controle se eh tarifa do segundo periodo
	local _lTrfSegPer := .f.

	// se data final for menor que data inicial, retorno 0 periodos
	If (mvDtFim < mvDtIni)
		Return (_aDetPeriodo)
	EndIf

	// loop para calculo do periodo
	While (_dDtIni <= mvDtFim)

		// se ja houve cobranca de periodo anterior
		If ( ! mvPrimCobr ) .and. ( ! _lTrfSegPer )
			// para sumitomo, para todas unidades de cobranca - primeiro periodo cheio (30 dias), após cobrar diário (chamado #14479)
			If (mvCodCli == "000316") .and. (mvDiasPer == 30)
				// periodo diario
				mvDiasPer := 15
				// divide a tarifa por 30 dias
				mvTarifa := (mvTarifa / 2)
			EndIf

			// atualiza o controle se a tarifa ja foi reduzida para o segundo periodo
			_lTrfSegPer := .t.

		EndIf

		// define data final
		// obs: -1 pra considerar periodo contando o primeiro dia da data inicial
		_dDtFim := (_dDtIni + mvDiasPer) - 1

		// adiciona os detalhes do period
		aAdd(_aDetPeriodo, {;
		_dDtIni   ,; // data inicial
		_dDtFim   ,; // data final
		mvDiasPer ,; // quantidade dias no periodo
		mvTarifa  }) // tarifa do periodo

		// define nova data inicial
		_dDtIni := (_dDtFim + 1)

		// altera parametro de controle da primeira cobranca
		If (mvPrimCobr)
			mvPrimCobr := .f.
		EndIf

	EndDo

Return(_aDetPeriodo)

// ** funcao que apresenta o total por servico na tela do browse
User Function FATA002S()
	// area inicial do TRB
	local _aAreaTrb := (_TRBGERAL)->(GetArea())
	local _cMsgTotal := ""
	local _aTotal := {}
	local _nTotal := 0
	// variaveis temporaria
	local _cTmpProd
	local _nTmpPos
	local _nX

	(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
	(_TRBGERAL)->(dbGoTop())

	// varre todos os itens do arquivo de trabalho
	While (_TRBGERAL)->(!Eof())
		If Empty((_TRBGERAL)->IT_NUMPED)
			// codigo do produto
			_cTmpProd := (_TRBGERAL)->IT_CODPROD
			// pesquisa se o produto ja tem valor
			_nTmpPos := aScan(_aTotal,{|x| x[1] ==_cTmpProd})
			// atualiza o total por produto
			If (_nTmpPos > 0)
				_aTotal[_nTmpPos,2] += (_TRBGERAL)->AAN_VALOR
			Else
				Aadd(_aTotal,{_cTmpProd,(_TRBGERAL)->AAN_VALOR})
			EndIf
		EndIf
		// proximo registro
		(_TRBGERAL)->(DbSkip())
	EndDo

	// varre todo o total para montar a mensagem
	For _nX := 1 To Len(_aTotal)
		// atualiza a mensagem
		_cMsgTotal += IIf(Empty(_aTotal[_nX,1]),"SEM CONTRATO",AllTrim(Posicione("SB1",1,xFilial("SB1")+_aTotal[_nX,1],"B1_DESC")))
		_cMsgTotal += " = R$ "
		_cMsgTotal += AllTrim(Transform(_aTotal[_nX,2],"@E 9,999,999.99")) +CRLF
		// total geral
		_nTotal += _aTotal[_nX,2]
	Next _nX
	// total geral
	_cMsgTotal += CRLF+"TOTAL GERAL = R$ "+AllTrim(Transform(_nTotal,"@E 9,999,999.99"))

	// apresenta a mensagem na tela
	Aviso(	"TFATA002 -> FATA002S",;
	"== Resumo Geral =="+CRLF+;
	_cMsgTotal,;
	{"Fechar"},3)

	// restaura area inicial
	RestArea(_aAreaTrb)

Return(.t.)

// ** funcao que marca todos os itens quando clicar no header da coluna
User Function FATA002L()
	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaTrb := (_TRBGERAL)->(GetArea())

	(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
	(_TRBGERAL)->(dbGoTop())

	While (_TRBGERAL)->(!Eof())
		// verifica se nao tem pedido de venda e se tem valor
		If Empty((_TRBGERAL)->IT_NUMPED) .and. ((_TRBGERAL)->AAN_VALOR > 0)
			(_TRBGERAL)->(RecLock(_TRBGERAL,.F.))
			(_TRBGERAL)->IT_OK := If((_TRBGERAL)->IT_OK == _cMarca,"",_cMarca )
			(_TRBGERAL)->(MsUnLock())
		EndIf
		// proximo item
		(_TRBGERAL)->(DbSkip())
	EndDo

	// restaura area inicial
	RestArea(_aAreaTrb)
	RestArea(_aAreaAtu)

	// refresh no browse
	oMark:Refresh()

Return(.t.)


// ** funcao para validar a marcacao do item
User Function FATA002M()
	// variavel de retorno
	local _lRet := .f.

	// validacao se permite a marcacao do item
	_lRet := Empty((_TRBGERAL)->IT_NUMPED) .and. (!Empty((_TRBGERAL)->IT_CODPROD)).and.((_TRBGERAL)->AAN_VALOR > 0)

	// inverte selecao
	_lRet := !( _lRet )

Return( _lRet )


// ** funcao que grava as alteracoes
Static Function sfGrvAlteracoes()
	// header do Browse
	local _aHeadBrw := aClone(_oBrwDetalhes:aHeader)
	// posicao dos campos no browse
	local _nPosRecno := aScan(_aHeadBrw,{|x| AllTrim(SubS(x[2],4))=="RECNO"})
	local _nPosFat := aScan(_aHeadBrw,{|x| AllTrim(SubS(x[2],4))=="FATURAR"})
	local _nPosTot := aScan(_aHeadBrw,{|x| AllTrim(SubS(x[2],4))=="VALOR"})
	local _nPosObsFat := aScan(_aHeadBrw,{|x| AllTrim(SubS(x[2],4))=="OBSFAT"})
	// variaveis temporarias
	local _nLin

	// se nao for visualizacao, grava as alteracoes
	If (!_lVisDetalhe)

		// 4-FRETES
		If (_cTpSrv == "4")
			// varre todos os itens dos detalhes
			For _nLin := 1 To Len(_oBrwDetalhes:aCols)
				// posiciona no registro da tabela
				dbSelectArea("SZK")
				SZK->(dbGoTo( _oBrwDetalhes:aCols[_nLin][_nPosRecno] ))
				RecLock("SZK")
				SZK->ZK_FATURAR	:= _oBrwDetalhes:aCols[_nLin][_nPosFat]
				//SZK->ZK_VALOR	:= _oBrwDetalhes:aCols[_nLin][_nPosTot]
				SZK->ZK_OBSFAT	:= _oBrwDetalhes:aCols[_nLin][_nPosObsFat]
				MsUnLock()
			Next _nLin

			// funcao que atualiza o valor total
			sfAtuValor()

			// 7-OUTROS SERVICOS
		ElseIf (_cTpSrv == "7")
			// varre todos os itens dos detalhes
			For _nLin := 1 To Len(_oBrwDetalhes:aCols)
				// posiciona no registro da tabela
				dbSelectArea("SZL")
				SZL->(dbGoTo( _oBrwDetalhes:aCols[_nLin][_nPosRecno] ))
				RecLock("SZL")
				SZL->ZL_FATURAR	:= _oBrwDetalhes:aCols[_nLin][_nPosFat]
				//SZL->ZL_VALOR	:= _oBrwDetalhes:aCols[_nLin][_nPosTot]
				SZL->ZL_OBSFAT	:= _oBrwDetalhes:aCols[_nLin][_nPosObsFat]
				MsUnLock()
			Next _nLin

			// funcao que atualiza o valor total
			sfAtuValor()

			// 8-VALORES FIXOS / ALUGUEIS
		ElseIf (_cTpSrv == "8")
			// varre todos os itens dos detalhes
			For _nLin := 1 To Len(_oBrwDetalhes:aCols)
				// posiciona no registro da tabela
				dbSelectArea("SZM")
				SZM->(dbGoTo( _oBrwDetalhes:aCols[_nLin][_nPosRecno] ))
				RecLock("SZM")
				SZM->ZM_FATURAR	:= _oBrwDetalhes:aCols[_nLin][_nPosFat]
				SZM->ZM_OBSFAT	:= _oBrwDetalhes:aCols[_nLin][_nPosObsFat]
				MsUnLock()
			Next _nLin

			// funcao que atualiza o valor total
			sfAtuValor()

		EndIf

		// atualiza a descricao do item
		(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
		(_TRBGERAL)->(RecLock(_TRBGERAL))
		(_TRBGERAL)->IT_DESPROD := _cDscProduto
		(_TRBGERAL)->(MsUnlock())

	EndIf

Return(.t.)

// ** funcao para validar toda a tela de detalhes (browse TudoOk)
User Function FATA002Z()
	// header do Browse
	local _aHeadBrw := aClone(_oBrwDetalhes:aHeader)
	// posicao dos campos no browse
	local _nPosFat := aScan(_aHeadBrw,{|x| AllTrim(SubS(x[2],4))=="FATURAR"})
	local _nPosObs := aScan(_aHeadBrw,{|x| AllTrim(SubS(x[2],4))=="OBSFAT"})
	// variaveis temporarias
	local _nLin
	// conteudo do campo
	local _cFaturar := ""
	local _cObsFat := ""

	MsgStop("FATA002Z - TUDO")

	// quando for 4-Frete / 7-Servicos / 8-Valores Fixos
	If (_cTpSrv $ "4|7|8")
		// varre todos os itens dos detalhes
		For _nLin := 1 To Len(_oBrwDetalhes:aCols)
			// conteudo do campo
			_cFaturar := _oBrwDetalhes:aCols[_nLin][_nPosFat]
			_cObsFat  := _oBrwDetalhes:aCols[_nLin][_nPosObs]
			// se estiver como FATURAR = NAO, obriga informar uma observacao
			If (_cFaturar=="N").and.(Empty(_cObsFat))
				Aviso("TFATA002 -> FATA002Z (TudoOk)","É obrigatório informar no campo >Obs Faturam.< um motivo para não faturar o item "+AllTrim(Str(_nLin)),{"Fechar"})
				Return(.f.)
			EndIf
		Next _nLin
	EndIf

Return(.t.)

// ** funcao responsavel pela validacao da linha, no browse dos detalhes dos servicos
User Function FATA002K()
	// header do Browse
	local _aHeadBrw := aClone(_oBrwDetalhes:aHeader)
	// posicao dos campos no browse
	local _nPosFat := aScan(_aHeadBrw,{|x| AllTrim(SubS(x[2],4))=="FATURAR"})
	local _nPosObs := aScan(_aHeadBrw,{|x| AllTrim(SubS(x[2],4))=="OBSFAT"})

	// conteudo do campo
	local _cFaturar := _oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nPosFat]
	local _cObsFat := _oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nPosObs]

	MsgStop("FATA002K - LINHA")

	// quando for 4-Frete / 7-Servicos / 8-Valores Fixos
	If (_cTpSrv $ "4|7|8")
		// se estiver como FATURAR = NAO, obriga informar uma observacao
		If (_cFaturar=="N").and.(Empty(_cObsFat))
			Aviso("TFATA002 -> FATA002K (LinhaOk)","É obrigatório informar no campo >Obs Faturam.< um motivo para não faturar este item !!",{"Fechar"})
			Return(.f.)
		EndIf
		// grava a observacao
		//sfGravaOBS()
	EndIf

Return(.t.)

// ** funcao executada na validacao do campo ZK_FATURAR (somente nos detalhes do frete)
User Function FATA0024()
	// header do Browse
	local _aHeadBrw := aClone(_oBrwDetalhes:aHeader)
	// posicao dos campos no browse
	local _nPosVlr := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="ZK_VLRUNIT"})
	local _nPosQtd := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="ZK_QUANT"})
	local _nPosTot := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="ZK_VALOR"})
	local _nPosRIC := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="ZK_RIC"})

	//MsgStop("FATA0024")

	// Atualiza Browse dos movimentos
	//_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nPosVlr] := sfTarifaFrete((_TRBGERAL)->IT_CONTRAT, (_TRBGERAL)->IT_ITCONTR, '', _oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nPosRIC], M->ZK_FATURAR)
	//_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nPosVlr] := sfTarifaFrete((_TRBGERAL)->IT_CONTRAT, (_TRBGERAL)->IT_ITCONTR, _oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nPosRIC])
	//_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nPosTot] := _oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nPosQtd] * _oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nPosVlr]

	// Atualiza Browse dos servicos
	//sfAtuValor()

	/*
	// Atualiza array dos movimentos caso usuario click novamente
	nPos:=aScan(aMovContr,{|x| x[1]+x[2]+x[3]+x[4]+x[25] ==(_TRBGERAL)->Z2_CODIGO+(_TRBGERAL)->Z2_ITEM+(_TRBGERAL)->IT_CONTRAT+(_TRBGERAL)->IT_ITCONTR+_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nPosRIC]})

	If nPos > 0
	aMovContr[nPos,09]:=_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nPosVlr]
	aMovContr[nPos,10]:=_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_PosTot]
	aMovContr[nPos,20]:=M->Z7_FATURAR
	EndIf
	*/

Return (.t.)

User Function FATA0027()

	nVlr:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_TARIFA"})
	nQtd:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_QTDE"})
	nTot:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_TOTAL"})
	nAtv:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZT_CODIGO"})
	nOS:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="Z6_NUMOS"})

	// Atualiza Browse dos movimentos
	_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,nVlr] := sfTarifaAtv(_TRBMOV->IT_CONTRAT, _TRBMOV->IT_ITCONTR, '', _oBrwDetalhes:aCols[_oBrwDetalhes:nAt,nAtv], M->Z7_FATURAR, '' ,'', '')
	_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,nTot] := _oBrwDetalhes:aCols[_oBrwDetalhes:nAt,nQtd]*_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,nVlr]

	// Atualiza Browse dos servicos
	sfAtuValor()

	// Atualiza array dos movimentos caso usuario click novamente
	nPos:=aScan(aMovContr,{|x| x[1]+x[2]+x[3]+x[4]+x[18]+x[19]==_TRBMOV->Z2_CODIGO+_TRBMOV->Z2_ITEM+_TRBMOV->IT_CONTRAT+_TRBMOV->IT_ITCONTR+_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,nOS]+_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,nAtv]})
	If nPos > 0
		aMovContr[nPos,09]:=_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,nVlr]
		aMovContr[nPos,10]:=_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,nTot]
		aMovContr[nPos,20]:=M->Z7_FATURAR
	EndIf

Return (.t.)

// atualiza o valor total (no browse principal) do servico posicionado
Static Function sfAtuValor()
	// header do Browse
	local _aHeadBrw := aClone(_oBrwDetalhes:aHeader)
	// posicao dos campos no browse
	local _nPosTot  := aScan(_aHeadBrw,{|x| AllTrim(SubS(x[2],4)) $ "VALOR|TOTAL"})
	local _nPosFat  := aScan(_aHeadBrw,{|x| AllTrim(SubS(x[2],4))=="FATURAR"})
	// valor total dos servicos
	local _nVlrTotal := 0
	// variaveis temporarias
	local _nLin := 0

	//MsgStop("sfAtuValor()")

	// varre todos os itens dos detalhes do servico
	For _nLin := 1 To Len(_oBrwDetalhes:aCols)
		// verifica se o item esta definido como FATURAR = SIM
		If (_oBrwDetalhes:aCols[_nLin,_nPosFat]=="S")
			// armazena o total
			_nVlrTotal += _oBrwDetalhes:aCols[_nLin,_nPosTot]
		EndIf
	Next _nLin

	// atualiza o valor total o browse (arq de trabalho)
	(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
	(_TRBGERAL)->(RecLock(_TRBGERAL))
	(_TRBGERAL)->AAN_VALOR	:= _nVlrTotal
	(_TRBGERAL)->AAN_VLRUNI	:= _nVlrTotal
	(_TRBGERAL)->(MsUnlock())

Return(.t.)

Static Function sfGravaOBS()

	// Atualiza array dos movimentos caso usuario click novamente
	nOBS:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_OBSERVA"})
	If _cTpSrv == "4"
		nRIC:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="Z3_RIC"})
		nPos:=aScan(aMovContr,{|x| x[1]+x[2]+x[3]+x[4]+x[25] ==_TRBMOV->Z2_CODIGO+_TRBMOV->Z2_ITEM+_TRBMOV->AAN_CONTRT+_TRBMOV->IT_ITCONTR+_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,nRIC]})
	EndIf
	If _cTpSrv == "7"
		nAtv:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZT_CODIGO"})
		nOS:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="Z6_NUMOS"})
		nPos:=aScan(aMovContr,{|x| x[1]+x[2]+x[3]+x[4]+x[18]+x[19]==_TRBMOV->Z2_CODIGO+_TRBMOV->Z2_ITEM+_TRBMOV->AAN_CONTRT+_TRBMOV->AAN_ITEM+_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,nOS]+_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,nAtv]})
	EndIf
	If nPos > 0
		aMovContr[nPos,32]:=_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,nOBS]
	EndIf

Return(.t.)

// ** funcao responsavel pela geracao do pedido de vendas
User Function FATA002G(mvTpFatur)
	// variavel de retorno
	local _lRet := .t.
	// usuarios com permissao para cancelamento de servicos
	local _cUsrCanc := AllTrim(GetMV('TC_USRCANF',.F.,"000000"))

	// cancelar faturamento
	If (mvTpFatur=="C")

		// para cancelamento, zera variavel
		_lRet := .f.

		// verifica se o usuario tem permissao
		If (__cUserId $ _cUsrCanc).and.((_TRBGERAL)->IT_TIPOSRV $ "1|2|4|5|7|B|")
			_lRet := .t.
		EndIf
	EndIf

	// controle de permissao
	If (!_lRet)
		Alert("Usuário sem permissão de cancelar faturamento ou item não permitido.")
		Return(_lRet)
	EndIf

	// verifica se permite gerar o pedido de venda
	If (mvTpFatur=="F") .and. ( ! _lGeraPed )
		Aviso("Pedido de Venda","O pedido de venda não poderá ser gerado pois há divergências no contrato.",{"Fechar"})
		Return(_lRet)
	EndIf

	// geracao do pedido de venda
	If (mvTpFatur=="F").and.(Aviso("Pedido de Venda","Confirma a geração do Pedido de Venda ?",{"Sim","Não"})==1)
		// chama funcao para gerar o pedido de venda
		Processa({ || _lRet := sfGeraPedVenda(mvTpFatur) },"Gerando o pedido de venda...",,.T.)

		// cancelamento da cobranca
	ElseIf (mvTpFatur=="C").and.(Aviso("Cancelamento","Confirma o cancelamento do faturamento ?",{"Sim","Não"})==1)
		// chama funcao para cancelar a cobranca
		Processa({ || _lRet := sfCancCobranca() },"Cancelando a cobrança do item...",,.T.)

	EndIf

Return(_lRet)

// ** funcao para gerar os pedidos de venda
Static Function sfGeraPedVenda(mvTpFatur)

	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaTrb := (_TRBGERAL)->(GetArea())
	// array para agrupar informacoes do mesmo processo do cliente
	// 1-Nr Processo
	// 2-Item Processo
	// 3-Cliente
	// 4-Loja
	local _aGrupo := {}
	local _nGrupo
	local _cProcesso
	local _cItProces
	local _cCodCli
	local _cLojCli
	// variaveis temporarias
	local _cTmpMsg
	// itens do pedido de venda
	local _aPedCabec := {}
	local _aPedItens := {}
	local _cItem
	local _nQuant := 0
	local _nVlrUnit := 0
	local _nTotal := 0
	local _cCondPag
	local _aDadosCFO
	local _cCFOP
	local _aTmpLinha
	local _cMsgNota := ""
	// numero do pedido do cliente
	local _cNumPedCli := CriaVar("C5_ZPEDCLI",.f.)
	// valor do ISS para repasse ao cliente
	local _nVlrISS
	// controla se deve apresentar a linha de repasse do ISS
	local _lItemISS := .f.
	// controla se deve repassar ISS ao cliente
	local _lRepasISS := .t.
	// mensagem padrao de ISS
	local _cMsgISS := ""
	// informacoes do pedido gerado para marcar os detalhes como faturado
	local _aContPed := {}

	// numero do contrato do cliente
	local _cNrContrt := ""
	
	local lMarcaOK := .F.

	//#### VER PARA GERAR MAIS DE UMA LINHA NO PEDIDO DE VENDA QUANDO FOR ALUGUEL, CONFOREME PERIORO
	//### VER MENSAGENS PADROES
	//## VER MENSAGEM FISCAL DE ISS DO ALUGUEL (ISENCAO)

	// define a quantidade de processos principais
	ProcRegua((_TRBGERAL)->(RecCount()))

	// valida valores e TES / agrupa faturamento
	(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
	(_TRBGERAL)->(dbGotop())

	// varre todos os itens do arquivo de trabalho
	While (_TRBGERAL)->(!EOF())

		// controle da regua de processamento
		IncProc("Processo "+(_TRBGERAL)->IT_PROCESS)

		// verifica se o item esta selecionado e se nao tem pedido de venda gerado
		If ((_TRBGERAL)->IT_OK==_cMarca) .and. Empty((_TRBGERAL)->IT_NUMPED)
			lMarcaOK := .T.
			// se for selecionado FATURAR, verifica se o item possui valor
			If (mvTpFatur == "F")
				// verifica se o produto do servico possui TES de Saida cadastrada
				If (Empty(Posicione("SB1",1, xFilial("SB1")+(_TRBGERAL)->IT_CODPROD ,"B1_TS")))
					// mensagem de erro
					_cTmpMsg := "Programação: "+(_TRBGERAL)->IT_PROCESS+" Item: "+(_TRBGERAL)->IT_ITPROCE +CRLF
					_cTmpMsg += "Serviço: "+AllTrim((_TRBGERAL)->IT_DESPROD) +CRLF
					_cTmpMsg += "Verificar pois este item não possui uma TES de Saída Cadastrada no Produto !! "
					Alert(_cTmpMsg)
					Return(.f.)
				EndIf
			EndIf

			// agrupa por processo + item + cliente + loja
			If (aScan(_aGrupo, {|x| x[1]+x[2]+x[3]+x[4] == (_TRBGERAL)->(IT_PROCESS+IT_ITPROCE+IT_CODCLIE+IT_LOJCLIE) })==0)
				// adiciona as informacoes no vetor
				aAdd(_aGrupo,{(_TRBGERAL)->IT_PROCESS,(_TRBGERAL)->IT_ITPROCE, (_TRBGERAL)->IT_CODCLIE, (_TRBGERAL)->IT_LOJCLIE})

				// verifica se o cliente possui vendedor
				dbSelectArea("SA1")
				SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
				If SA1->(dbSeek( xFilial("SA1")+(_TRBGERAL)->(IT_CODCLIE+IT_LOJCLIE) ))
					// verifica o codigo do vendedor
					If (Empty(SA1->A1_VEND))
						Aviso(	"TFATA002 -> sfGeraPedVenda",;
						"O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+AllTrim(SA1->A1_NOME)+" não possui vendedor."+CRLF+;
						"O processo de geração de pedido de venda será cancelado",;
						{"Fechar"} )
						Return(.f.)
					EndIf
				EndIf
			EndIf

		EndIf
		// proximo item
		(_TRBGERAL)->(dbSkip())
	EndDo
	
	If !lMarcaOK
		Aviso("TFATA002 -> sfGeraPedVenda","Não foi marcado nenhum pedido de venda. Marque para gerar.",{"Fechar"})
	EndIf
	
	// chama o grupo de perguntas da rotina de pedido de venda
	//pergunte("MTA410",.f.)

	// conforme o agrupamento, gera o pedido de venda
	For _nGrupo := 1 To Len(_aGrupo)

		// variaveis de controle de quebra de grupos
		_cProcesso	:= _aGrupo[_nGrupo,1]	// processo
		_cItProces	:= _aGrupo[_nGrupo,2]	// item do processo
		_cCodCli	:= _aGrupo[_nGrupo,3]	// cod cliente
		_cLojCli	:= _aGrupo[_nGrupo,4]	// loj cliente

		// zera as variaveis
		_aPedItens	:= {}
		_cItem		:= "00"
		_nVlrISS	:= 0
		_aContPed	:= {}
		_lItemISS	:= .f.
		_lRepasISS  := .t.
		_cNumPedCli := ""


		// varre o TRB buscando as informacoes do agrupamento atual
		(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
		(_TRBGERAL)->(dbGotop())
		
		nAliqISS := GETMV("MV_ALIQISS")

		While (_TRBGERAL)->(!EOF())
			// verifica se o item esta selecionado e nao tem pedido de venda
			If ((_TRBGERAL)->IT_OK == _cMarca) .and. Empty((_TRBGERAL)->IT_NUMPED).and.(_cProcesso + _cItProces + _cCodCli + _cLojCli == (_TRBGERAL)->(IT_PROCESS+IT_ITPROCE+IT_CODCLIE+IT_LOJCLIE))

				// Posiciona no cliente
				dbSelectArea("SA1")
				SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
				SA1->(dbSeek( xFilial("SA1")+ _cCodCli+_cLojCli ))

				// posiciona no contrato
				dbSelectArea("AAM")
				AAM->(dbSetOrder(1)) //1-AAM_FILIAL, AAM_CONTRT
				AAM->(dbSeek( xFilial("AAM")+(_TRBGERAL)->IT_CONTRAT ))

				// verifica no contrato se deve gerar o item de ISS
				_lItemISS  := (AAM->AAM_ZISS <> "N")
				// mensagem padrao do ISS
				_cMsgISS   := AAM->AAM_ZMSGIS
				// verifica no contrato se deve repassar ISS para o cliente
				_lRepasISS := (AAM->AAM_ZREISS <> "N")

				// valida e inclui mensagem especifica do cliente, conforme contrato
				If ( ! Empty(AAM->AAM_ZMSGPV)).and.( ! AllTrim(AAM->AAM_ZMSGPV) $ _cNumPedCli)
					_cNumPedCli += AllTrim(AAM->AAM_ZMSGPV)
				EndIf

				// posiciona no produto
				dbSelectArea("SB1")
				SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
				SB1->(dbSeek( xFilial("SB1")+(_TRBGERAL)->IT_CODPROD ))

				// posiciona na TES
				dbSelectArea("SF4")
				SF4->(dbSetOrder(1)) //1-F4_FILIAL, F4_CODIGO
				SF4->(dbSeek( xFilial("SF4")+SB1->B1_TS ))

				// verifica se eh pacote logistico
				If ((_TRBGERAL)->IT_TIPOSRV == "3")
					_nQuant   := (_TRBGERAL)->AAN_QUANT
					_nVlrUnit := Round((_TRBGERAL)->AAN_VLRUNI, TamSx3("C6_PRCVEN")[2])
				Else
					_nQuant   := 1
					_nVlrUnit := Round((_TRBGERAL)->AAN_VALOR , TamSx3("C6_PRCVEN")[2])
				EndIf

				// valor total
				_nTotal := (_TRBGERAL)->AAN_VALOR

				// repasse do ISS do cliente
				If (SF4->F4_ISS == "S" ) .AND. (_lRepasISS)
					// se deve gerar o item do ISS
					If (_lItemISS)
						_nVlrISS += Iif( SB1->B1_ALIQISS > 0,  Round(_nTotal * (SB1->B1_ALIQISS /100),2) ,   Round(_nTotal * (nAliqISS/100),2) )
						// se NAO deve gerar, dilui o valor no item
					ElseIf (!_lItemISS)
						// atualiza o valor unitario
						_nVlrUnit	+= Iif( SB1->B1_ALIQISS > 0, Round(_nVlrUnit * (SB1->B1_ALIQISS /100),2) , Round(_nVlrUnit * (nAliqISS/100),2) )
						// atualiza o valor total
						_nTotal		+= Iif( SB1->B1_ALIQISS > 0, Round(_nTotal * (SB1->B1_ALIQISS /100),2) , Round(_nTotal * (nAliqISS/100),2) )
					EndIf
				EndIf

				// condicao de pagamento (busca do contrato)
				_cCondPag	:= Posicione("AAM",1, xFilial("AAM")+(_TRBGERAL)->IT_CONTRAT ,"AAM_CPAGPV")

				// define o CFOP
				_aDadosCFO := {}
				Aadd(_aDadosCFO,{"OPERNF"	,"S"})
				Aadd(_aDadosCFO,{"TPCLIFOR"	,SA1->A1_TIPO})
				Aadd(_aDadosCFO,{"UFDEST"  	,SA1->A1_EST})
				Aadd(_aDadosCFO,{"INSCR"   	,SA1->A1_INSCR})
				// retorna a CFOP correta
				_cCFOP := MaFisCfo(,SF4->F4_CF,_aDadosCFO)

				// controle do item do pedido
				_cItem := SomaIt(_cItem)

				// alimenta a linha do pedido de venda
				_aTmpLinha := {}
				aadd(_aTmpLinha,{"C6_ITEM"      ,_cItem                 ,Nil})
				aadd(_aTmpLinha,{"C6_PRODUTO"   ,(_TRBGERAL)->IT_CODPROD  ,Nil})
				aadd(_aTmpLinha,{"C6_QTDVEN"    ,_nQuant                ,Nil})
				aadd(_aTmpLinha,{"C6_QTDLIB"    ,_nQuant                ,Nil}) // QTD LIBERADA
				aadd(_aTmpLinha,{"C6_PRUNIT"    ,_nVlrUnit              ,Nil})
				aadd(_aTmpLinha,{"C6_PRCVEN"    ,_nVlrUnit              ,Nil})
				aadd(_aTmpLinha,{"C6_VALOR"     ,_nTotal                ,Nil})
				aadd(_aTmpLinha,{"C6_UM"        ,SB1->B1_UM             ,Nil})
				aadd(_aTmpLinha,{"C6_TES"       ,SB1->B1_TS             ,Nil})
				aadd(_aTmpLinha,{"C6_CF"        ,_cCFOP                 ,Nil})
				aadd(_aTmpLinha,{"C6_LOCAL"     ,SB1->B1_LOCPAD         ,Nil})
				aadd(_aTmpLinha,{"C6_CLI"       ,_cCodCli               ,Nil})
				aadd(_aTmpLinha,{"C6_LOJA"      ,_cLojCli               ,Nil})
				aadd(_aTmpLinha,{"C6_DESCRI"    ,(_TRBGERAL)->IT_DESPROD  ,Nil})
				aadd(_aTmpLinha,{"C6_CONTRT"    ,(_TRBGERAL)->IT_CONTRAT  ,Nil})
				aadd(_aTmpLinha,{"C6_ITCONTR"   ,(_TRBGERAL)->IT_ITCONTR  ,Nil})
				aadd(_aTmpLinha,{"C6_TPCONTR"   ,"1"                    ,Nil})
				aadd(_aTmpLinha,{"C6_CODISS"    ,SB1->B1_CODISS         ,Nil})
				aadd(_aTmpLinha,{"C6_ENTREG"    ,_dDataBase             ,Nil})
				aadd(_aTmpLinha,{"C6_ZPROCES"   ,_cProcesso             ,Nil})
				aadd(_aTmpLinha,{"C6_ZITPROC"   ,_cItProces             ,Nil})

				// atualiza numero do contato do cliente
				_cNrContrt := (_TRBGERAL)->IT_CONTRAT

				// atribui a linha aos itens do pedido de venda
				aadd(_aPedItens,_aTmpLinha)

				// armazena os itens que geraram PV
				AAdd(_aContPed, { (_TRBGERAL)->(RecNo()), NIL, _cItem } )

			EndIf

			// proximo item
			(_TRBGERAL)->(dbSkip())
		EndDo

		// se tiver itens, gera o pedido de venda
		If (Len(_aPedItens) > 0)

			// mensagem pra nota
			If (!Empty(_cProcesso))
				// mensagem do processo
				_cMsgNota := "REF. PROCESSO: "+_cProcesso
				// inclui mensagem do documento do processo
				_cMsgNota += " "+AllTrim(Posicione("SZ1",1,xFilial("SZ1")+_cProcesso,"Z1_REFEREN"))
				// inclui mensagem do ITEM do processo
				_cMsgNota += " "+AllTrim(Posicione("SZ2",1,xFilial("SZ2")+_cProcesso+_cItProces,"Z2_DOCUMEN"))
				// mensagem da referencia da nota
				_cMsgNota += " "+sfRetRefNf(_cProcesso)
			EndIf

			// prepara o cabecalho do pedido de venda
			_aPedCabec := {}
			aadd(_aPedCabec, {"C5_TIPO"     , "N"          ,Nil})
			aadd(_aPedCabec, {"C5_TIPOOPE"  , "S"          ,Nil})
			aadd(_aPedCabec, {"C5_CLIENTE"  , _cCodCli     ,Nil})
			aadd(_aPedCabec, {"C5_CLIENT"   , _cCodCli     ,Nil})
			aadd(_aPedCabec, {"C5_LOJAENT"  , _cLojCli     ,Nil})
			aadd(_aPedCabec, {"C5_LOJACLI"  , _cLojCli     ,Nil})
			aadd(_aPedCabec, {"C5_TIPOCLI"  , SA1->A1_TIPO ,Nil})
			aadd(_aPedCabec, {"C5_CONDPAG"  , _cCondPag    ,Nil})
			aadd(_aPedCabec, {"C5_MENNOTA"  , _cMsgNota    ,Nil})
			aadd(_aPedCabec, {"C5_ZPROCES"  , _cProcesso   ,Nil})
			aadd(_aPedCabec, {"C5_MENPAD"   , _cMsgISS     ,Nil})
			aadd(_aPedCabec, {"C5_ZPEDCLI"  , _cNumPedCli  ,Nil})
			aadd(_aPedCabec, {"C5_ZCONTRT"  , _cNrContrt   ,Nil})

			// Cobra ISS caso seja necessario
			If (_nVlrISS > 0) .AND. (_lItemISS) .AND. (_lRepasISS)

				// Define qual código de produto deve utilizar para gerar o ISS (de acordo com o código de serviço ISS)
				
				If ( AllTrim(SB1->B1_CODISS) == "1601")   // serviços de transportes de natureza municipal
					// posiciona no produto de ISS 9000015
					dbSelectArea("SB1")
					SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
					SB1->(dbSeek( xFilial("SB1")+"9000015" ))
				Else
					// posiciona no produto de ISS 9000009
					dbSelectArea("SB1")
					SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
					SB1->(dbSeek( xFilial("SB1")+"9000009" ))
				EndIf

				// posiciona na TES
				dbSelectArea("SF4")
				SF4->(dbSetOrder(1)) //1-F4_FILIAL, F4_CODIGO
				SF4->(dbSeek( xFilial("SF4") + SB1->B1_TS ))

				// retorna a CFOP correta
				_cCFOP := MaFisCfo(,SF4->F4_CF,_aDadosCFO)

				// controle do item do pedido
				_cItem := SomaIt(_cItem)

				// alimenta a linha do pedido de venda
				_aTmpLinha:={}
				aadd(_aTmpLinha, {"C6_ITEM"      , _cItem         ,Nil})
				aadd(_aTmpLinha, {"C6_PRODUTO"   , SB1->B1_COD    ,Nil})
				aadd(_aTmpLinha, {"C6_QTDVEN"    , 1              ,Nil})
				aadd(_aTmpLinha, {"C6_QTDLIB"    , 1              ,Nil}) // QTD LIBERADA
				aadd(_aTmpLinha, {"C6_PRUNIT"    , _nVlrISS       ,Nil})
				aadd(_aTmpLinha, {"C6_PRCVEN"    , _nVlrISS       ,Nil})
				aadd(_aTmpLinha, {"C6_VALOR"     , _nVlrISS       ,Nil})
				aadd(_aTmpLinha, {"C6_UM"        , SB1->B1_UM     ,Nil})
				aadd(_aTmpLinha, {"C6_TES"       , SB1->B1_TS     ,Nil})
				aadd(_aTmpLinha, {"C6_CF"        , _cCFOP         ,Nil})
				aadd(_aTmpLinha, {"C6_LOCAL"     , SB1->B1_LOCPAD ,Nil})
				aadd(_aTmpLinha, {"C6_CLI"       , _cCodCli       ,Nil})
				aadd(_aTmpLinha, {"C6_LOJA"      , _cLojCli       ,Nil})
				aadd(_aTmpLinha, {"C6_DESCRI"    , SB1->B1_DESC   ,Nil})
				aadd(_aTmpLinha, {"C6_CONTRT"    , _cNrContrt     ,Nil})
				aadd(_aTmpLinha, {"C6_ENTREG"    , _dDataBase     ,Nil})
				aadd(_aTmpLinha, {"C6_ZPROCES"   , _cProcesso     ,Nil})

				// atribui a linha aos itens do pedido de venda
				aadd(_aPedItens,_aTmpLinha)

			EndIf

			// variaveis internas da rotina padrao MATA410
			lMSHelpAuto := .T.
			lMsErroAuto := .F.
			
			// inicio da transacao
			BEGIN Transaction
			
				// se for faturamento, gera o pedido de venda
				If (mvTpFatur == "F")
					// funcao Padrao de gravacao de pedido
					MSExecAuto({|x,y,z|Mata410(x,y,z)},_aPedCabec,_aPedItens,3)
				EndIf
	
				// se deu erro, apresenta a mensagem e derruba a transacao
				If lMsErroAuto
					// rollback na transacao
					DisarmTransaction()
				Else
					For nLoop := 1 To Len( _aContPed )
						//Caso for cancelamento o numero do pedido sera CNNNNN
						If (mvTpFatur == "F")
							_aContPed[ nLoop, 2 ] := SC5->C5_NUM
						Else
							// busca o ultimo numero para pedidos cancelados
							_aContPed[ nLoop, 2 ] := sfNextPedCan()
	
						EndIf
					Next nLoop
				EndIf
			
			// final da transacao
			END Transaction
			
			If lMsErroAuto
			Alert("Erro Na Geracao de Pedido")
					// mostra o erro
					MostraErro()
					// encerra a rotina
					Return(.f.)
			EndIf

		EndIf
		
		// inicio da transacao
		BEGIN Transaction
		
			// Grava dados do pedido
			For nLoop := 1 to Len( _aContPed )
	
				(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
				(_TRBGERAL)->(dbGoTo(_aContPed[nLoop,1]))
	
				If (mvTpFatur == "F")
	
					dbSelectArea("SC6")
					dbSetOrder(1)
					dbSeek(xFilial("SC6")+_aContPed[nLoop,2]+_aContPed[nLoop,3])
	
					(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
					(_TRBGERAL)->(RecLock(_TRBGERAL,.F.))
					(_TRBGERAL)->IT_NUMPED	:= SC6->C6_NUM
					(_TRBGERAL)->IT_ITEMPED	:= SC6->C6_ITEM
					(_TRBGERAL)->(MsUnlock())
	
				Else
	
					(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
					(_TRBGERAL)->(RecLock(_TRBGERAL,.F.))
					(_TRBGERAL)->IT_NUMPED	:= _aContPed[nLoop,2]
					(_TRBGERAL)->IT_ITEMPED	:= _aContPed[nLoop,3]
					(_TRBGERAL)->(MsUnlock())
	
				EndIf
	
				//sfGravaRel()
	
				// se nao mostra faturados, exclui o registro do TRB
				If (!mvMostraFat)
					(_TRBGERAL)->(RecLock(_TRBGERAL,.F.))
					(_TRBGERAL)->(dbDelete())
					(_TRBGERAL)->(MsUnlock())
				EndIf
	
				// se for armazenagem de container
				If ((_TRBGERAL)->IT_TIPOSRV == '1')
					sfBaixaContain(mvTpFatur)
				EndIf
	
				// se for armazenagem de produtos
				If ((_TRBGERAL)->IT_TIPOSRV == '2')
					sfBaixaProduto(mvTpFatur)
				EndIf
	
				// se for pacote logistico
				If ((_TRBGERAL)->IT_TIPOSRV $ '3/A/B')
					sfBaixaPacote(mvTpFatur, (_TRBGERAL)->IT_TIPOSRV)
				EndIf
	
				// se for fretes
				If ((_TRBGERAL)->IT_TIPOSRV == '4')
					sfBaixaFrete(mvTpFatur,.f.)
				EndIf
	
				// se for seguro
				If ((_TRBGERAL)->IT_TIPOSRV == '5')
					sfBaixaSeg(mvTpFatur)
				EndIf
	
				// se for servicos diversos
				If ((_TRBGERAL)->IT_TIPOSRV == '7')
					sfBaixaOS(mvTpFatur,.f.)
				EndIf
	
				// se for valores fixos / alugueis
				If ((_TRBGERAL)->IT_TIPOSRV == '8')
					sfBaixaFixo(mvTpFatur,.f.)
				EndIf
				
				// gera a linha de resumo
				dbSelectArea("SZR")
				RecLock("SZR",.t.)
				SZR->ZR_FILIAL   := xFilial("SZR")
				SZR->ZR_PROGRAM  := (_TRBGERAL)->IT_PROCESS
				SZR->ZR_ITEPROG  := (_TRBGERAL)->IT_ITPROCE
				SZR->ZR_CONTRT   := (_TRBGERAL)->IT_CONTRAT
				SZR->ZR_ITEM     := (_TRBGERAL)->IT_ITCONTR
				SZR->ZR_CODSRV   := (_TRBGERAL)->IT_CODPROD
				SZR->ZR_DESCRI   := (_TRBGERAL)->IT_DESPROD
				SZR->ZR_CODCLI   := (_TRBGERAL)->IT_CODCLIE
				SZR->ZR_LOJCLI   := (_TRBGERAL)->IT_LOJCLIE
				SZR->ZR_PEDIDO   := (_TRBGERAL)->IT_NUMPED
				SZR->ZR_ITEPEDI  := (_TRBGERAL)->IT_ITEMPED
				SZR->ZR_DATA     := _dDataBase
				SZR->ZR_QUANT    := (_TRBGERAL)->AAN_QUANT
				SZR->ZR_VLRUNI   := (_TRBGERAL)->AAN_VLRUNI
				SZR->ZR_VALOR    := (_TRBGERAL)->AAN_VALOR
				SZR->ZR_PACOTE   := (_TRBGERAL)->IT_PACOTE
				MsUnlock()
	
			Next nLoop
		
		// final da transacao
		END Transaction

	Next _nGrupo

	// restaura area inicial
	RestArea(_aAreaTrb)
	RestArea(_aAreaAtu)

Return(.t.)

// ** funcao responsavel por marcar os detalhes do servico como faturado
// ** 4-TRANSF INTERNAS / FRETES
Static Function sfBaixaFrete(mvTpFatur, mvPacLog)
	// area inicial
	local _aAreaSZ3 := SZ3->(GetArea())
	// detalhes do servico
	local _aItens := sfDetFrete(.f.,nil,mvPacLog,.t.)
	// posicao do campo RECNO
	local _nPosRecno := If((Len(_aItens) > 0),(Len(_aItens[1]) - 1),0)
	// variaveis temporarias
	local _nItem

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)

		// posiciona no registro real da tabela
		dbSelectArea("SZK")
		SZK->(dbGoTo(_aItens[_nItem][_nPosRecno]))

		// verifica se deve baixar o frete
		If (!mvPacLog).and.(mvTpFatur=="F").and.(SZK->ZK_FATURAR <> "S")
			Loop
		EndIf

		// atualiza os campos
		RecLock("SZK")
		SZK->ZK_STATUS	:= mvTpFatur
		SZK->ZK_IDPROCE	:= ""
		SZK->ZK_PEDIDO	:= (_TRBGERAL)->IT_NUMPED
		SZK->ZK_ITEMPED	:= (_TRBGERAL)->IT_ITEMPED
		SZK->ZK_OBSFAT	:= If(mvTpFatur=="F","",AllTrim(UsrRetName(__cUserID))+": "+_cMotCanc)
		SZK->ZK_PRODUTO	:= If( ! Empty(SZK->ZK_PRODUTO), SZK->ZK_PRODUTO, sfRetCdSrv((_TRBGERAL)->IT_TIPOSRV))
		MsUnLock()

		// cria o item no pacote logistico
		If (mvPacLog)
			dbSelectArea("SZO")
			SZO->(dbOrderNickName("ZO_PACOTE")) // 1-ZO_FILIAL, ZO_PACOTE, ZO_SEQPACO, ZO_PRODUTO
			If ! SZO->(dbSeek( xFilial("SZO")+SZK->(ZK_PACOTE+ZK_SEQPACO+ZK_PRODUTO) ))
				RecLock("SZO",.t.)
				SZO->ZO_FILIAL	:= xFilial("SZO")
				SZO->ZO_PACOTE	:= SZK->ZK_PACOTE
				SZO->ZO_SEQPACO	:= SZK->ZK_SEQPACO
				SZO->ZO_PRODUTO	:= SZK->ZK_PRODUTO
				MsUnLock()
			EndIf
		EndIf

		// atualiza os dados da movimentacao da unidade
		dbSelectArea("SZ3")
		SZ3->(dbOrderNickName("Z3_RIC")) // 4-Z3_FILIAL, Z3_RIC
		If SZ3->(dbSeek( xFilial("SZ3")+SZK->ZK_RIC ))
			// marca a data de faturamento
			RecLock("SZ3",.F.)
			SZ3->Z3_DTFATFR := SZK->ZK_DTPROCE
			MsUnlock()
		EndIf

	Next _nItem

	// restaura area inicial
	RestArea(_aAreaSZ3)

Return(.t.)

// ** funcao responsavel por marcar os detalhes do servico como faturado
// ** 5-SEGUROS
Static Function sfBaixaSeg(mvTpFatur)
	// area inicial
	local _aAreaSF1 := SF1->(GetArea())
	// detalhes do servico
	local _aItens := sfDetSeguro(.f., nil, nil, .t.)
	// detalhes de saldo por item
	local _aSaldoItm := sfDetItmNf(.f., Nil, .t.)
	// posicao do campo RECNO
	local _nPosRecno
	// variaveis temporarias
	local _nItem

	// posicao do campo RECNO
	_nPosRecno := IIf((Len(_aItens) > 0),(Len(_aItens[1]) - 1),0)

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)

		// posiciona no registro real da tabela
		dbSelectArea("SZI")
		SZI->(dbGoTo(_aItens[_nItem][_nPosRecno]))

		// atualiza os campos
		RecLock("SZI")
		SZI->ZI_STATUS	:= mvTpFatur
		SZI->ZI_IDPROCE	:= ""
		SZI->ZI_PEDIDO	:= (_TRBGERAL)->IT_NUMPED
		SZI->ZI_ITEMPED	:= (_TRBGERAL)->IT_ITEMPED
		SZI->ZI_OBSFAT	:= If(mvTpFatur=="F","",AllTrim(UsrRetName(__cUserID))+": "+_cMotCanc)
		SZI->ZI_PRODUTO	:= If(!Empty(SZI->ZI_PRODUTO).and.(mvTpFatur=="F"),SZI->ZI_PRODUTO,sfRetCdSrv((_TRBGERAL)->IT_TIPOSRV))
		SZI->ZI_OBSFAT	:= If(mvTpFatur=="F","",AllTrim(UsrRetName(__cUserID))+": "+_cMotCanc)
		SZI->(MsUnLock())

		// atualiza os dados da nota fiscal
		dbSelectArea("SF1")
		SF1->(dbSetOrder(1)) //1-F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO
		If SF1->(dbSeek(xFilial("SF1")+SZI->(ZI_DOC+ZI_SERIE+ZI_CLIENTE+ZI_LOJA)+"B"))
			// atualiza a ultima data de faturamento (ultimo dia mais 1)
			RecLock("SF1",.F.)
			SF1->F1_DTFATSE	:= SZI->ZI_DTFIM + 1
			MsUnlock()
		EndIf

	Next _nItem

	// posicao do campo RECNO
	_nPosRecno := IIf((Len(_aSaldoItm) > 0),(Len(_aSaldoItm[1]) - 1),0)

	// varre todos os detalhes do saldo por item da nota
	For _nItem := 1 to Len(_aSaldoItm)

		// posiciona no registro real da tabela
		dbSelectArea("Z48")
		Z48->(dbGoTo(_aSaldoItm[_nItem][_nPosRecno]))

		// atualiza os campos
		RecLock("Z48")
		Z48->Z48_STATUS	:= mvTpFatur
		Z48->Z48_IDPROC	:= ""
		Z48->Z48_PEDIDO	:= (_TRBGERAL)->IT_NUMPED
		Z48->Z48_ITEMPV	:= (_TRBGERAL)->IT_ITEMPED
		Z48->Z48_SERVIC	:= IIf( ! Empty(SZI->ZI_PRODUTO).and.(mvTpFatur=="F"), SZI->ZI_PRODUTO, sfRetCdSrv((_TRBGERAL)->IT_TIPOSRV))
		Z48->(MsUnLock())

	Next _nItem

	// restaura area inicial
	RestArea(_aAreaSF1)

Return(.t.)

// ** funcao responsavel por marcar os detalhes do servico como faturado
// ** 2-ARMAZENAGEM DE PRODUTOS
Static Function sfBaixaProduto(mvTpFatur)
	// area inicial
	local _aAreaSF1 := SF1->(GetArea())
	// detalhes do servico
	local _aItens := sfDetArmPrd(.f., nil, nil, .t.)
	// detalhes de saldo por item
	local _aSaldoItm := sfDetItmNf(.f., Nil, .t.)
	// posicao do campo RECNO
	local _nPosRecno
	// variaveis temporarias
	local _nItem

	// posicao do campo RECNO
	_nPosRecno := IIf((Len(_aItens) > 0),(Len(_aItens[1]) - 1),0)

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)
		// posiciona no registro real da tabela
		dbSelectArea("SZH")
		SZH->(dbGoTo(_aItens[_nItem][_nPosRecno]))

		// atualiza os campos
		RecLock("SZH")
		SZH->ZH_STATUS	:= mvTpFatur
		SZH->ZH_IDPROCE	:= ""
		SZH->ZH_PEDIDO	:= (_TRBGERAL)->IT_NUMPED
		SZH->ZH_PRODUTO	:= If(!Empty(SZH->ZH_PRODUTO).and.(mvTpFatur=="F"),SZH->ZH_PRODUTO,sfRetCdSrv((_TRBGERAL)->IT_TIPOSRV))
		SZH->ZH_ITEMPED	:= (_TRBGERAL)->IT_ITEMPED
		SZH->ZH_OBSFAT	:= If(mvTpFatur=="F","",AllTrim(UsrRetName(__cUserID))+": "+_cMotCanc)
		MsUnLock()

		// atualiza os dados da nota fiscal
		dbSelectArea("SF1")
		SF1->(dbSetOrder(1)) //1-F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO
		If SF1->(dbSeek(xFilial("SF1")+SZH->(ZH_DOC+ZH_SERIE+ZH_CLIENTE+ZH_LOJA)+"B"))
			// atualiza a ultima data de faturamento (ultimo dia mais 1)
			RecLock("SF1",.F.)
			SF1->F1_DTFATPR	:= SZH->ZH_DTFIM + 1
			MsUnlock()
		EndIf

	Next _nItem

	// posicao do campo RECNO
	_nPosRecno := IIf((Len(_aSaldoItm) > 0),(Len(_aSaldoItm[1]) - 1),0)

	// varre todos os detalhes do saldo por item da nota
	For _nItem := 1 to Len(_aSaldoItm)

		// posiciona no registro real da tabela
		dbSelectArea("Z48")
		Z48->(dbGoTo(_aSaldoItm[_nItem][_nPosRecno]))

		// atualiza os campos
		RecLock("Z48")
		Z48->Z48_STATUS	:= mvTpFatur
		Z48->Z48_IDPROC	:= ""
		Z48->Z48_PEDIDO	:= (_TRBGERAL)->IT_NUMPED
		Z48->Z48_ITEMPV	:= (_TRBGERAL)->IT_ITEMPED
		Z48->Z48_SERVIC	:= IIf( ! Empty(SZH->ZH_PRODUTO).and.(mvTpFatur=="F"), SZH->ZH_PRODUTO, sfRetCdSrv((_TRBGERAL)->IT_TIPOSRV))
		Z48->(MsUnLock())

	Next _nItem

	// restaura area inicial
	RestArea(_aAreaSF1)

Return(.t.)


// ** funcao responsavel por marcar os detalhes do servico como faturado
// ** 1-ARMAZENAGEM DE CONTAINER
Static Function sfBaixaContain(mvTpFatur)
	// area inicial
	local _aAreaSZ3 := SZ3->(GetArea())
	// detalhes do servico
	local _aItens := sfDetArmCnt(.f.,nil,nil,.t.)
	// posicao do campo RECNO
	local _nPosRecno := If((Len(_aItens) > 0),(Len(_aItens[1]) - 1),0)
	// variaveis temporarias
	local _nItem
	// RIC de saida
	local _cRICSaida

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)
		// posiciona no registro real da tabela
		dbSelectArea("SZG")
		SZG->(dbGoTo(_aItens[_nItem][_nPosRecno]))

		// atualiza os campos
		RecLock("SZG")
		SZG->ZG_STATUS	:= mvTpFatur
		SZG->ZG_IDPROCE	:= ""
		SZG->ZG_PEDIDO	:= (_TRBGERAL)->IT_NUMPED
		SZG->ZG_ITEMPED	:= (_TRBGERAL)->IT_ITEMPED
		SZG->ZG_PRODUTO	:= If(!Empty(SZG->ZG_PRODUTO).and.(mvTpFatur=="F"),SZG->ZG_PRODUTO,sfRetCdSrv((_TRBGERAL)->IT_TIPOSRV))
		SZG->ZG_OBSFAT	:= If(mvTpFatur=="F","",AllTrim(UsrRetName(__cUserID))+": "+_cMotCanc)
		MsUnLock()

		// atualiza os dados da movimentacao da unidade
		dbSelectArea("SZ3")
		SZ3->(dbOrderNickName("Z3_RIC")) // 4-Z3_FILIAL, Z3_RIC
		If SZ3->(dbSeek( xFilial("SZ3")+SZG->ZG_RIC ))
			// marca a data para o proximo faturamento
			RecLock("SZ3",.F.)
			SZ3->Z3_DTFATAR := SZG->ZG_DTFIM + 1
			MsUnlock()

			// quando o container ja saiu, marca o movimento de saida como faturado
			If (!Empty(SZ3->Z3_DTSAIDA))
				// funcao para pesquisar a RIC de saida
				_cRICSaida := U_FtRetRIC(SZG->ZG_RIC)

				// atualiza os dados da movimentacao da unidade
				dbSelectArea("SZ3")
				SZ3->(dbOrderNickName("Z3_RIC")) // 4-Z3_FILIAL, Z3_RIC
				If SZ3->(dbSeek( xFilial("SZ3")+_cRICSaida ))
					// marca a data para o proximo faturamento
					RecLock("SZ3",.F.)
					SZ3->Z3_DTFATAR := SZG->ZG_DTFIM + 1
					MsUnlock()
				EndIf
			EndIF
		EndIf

	Next _nItem

	// restaura area inicial
	RestArea(_aAreaSZ3)

Return(.t.)

// ** funcao responsavel por marcar os detalhes do pacote logistico
// ** 3-PACOTE LOGISTICO / A-PACOTE LOGISTICO EXPORTACAO / B-PACOTE DE SERVICOS
Static Function sfBaixaPacote(mvTpFatur, mvTpServPcte)
	// area inicial
	local _aAreaSZ3 := SZ3->(GetArea())
	// detalhes do servico
	local _aItens := sfDetPacote(.f., nil, nil, .t., mvTpServPcte)
	// posicao do campo RECNO
	local _nPosRecno := If((Len(_aItens) > 0),(Len(_aItens[1]) - 1),0)
	// variaveis temporarias
	local _nItem
	// RIC de saida
	local _cRICSaida

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)

		// posiciona no registro real da tabela
		dbSelectArea("SZJ")
		SZJ->(dbGoTo(_aItens[_nItem][_nPosRecno]))

		// atualiza os campos
		RecLock("SZJ")
		SZJ->ZJ_STATUS	:= mvTpFatur
		SZJ->ZJ_IDPROCE	:= ""
		SZJ->ZJ_PEDIDO	:= (_TRBGERAL)->IT_NUMPED
		SZJ->ZJ_ITEMPED	:= (_TRBGERAL)->IT_ITEMPED
		MsUnLock()

		// cria o item do pacote logistico
		RecLock("SZO",.t.)
		SZO->ZO_FILIAL	:= xFilial("SZO")
		SZO->ZO_PACOTE	:= SZJ->ZJ_PACOTE
		SZO->ZO_SEQPACO	:= SZJ->ZJ_SEQPACO
		SZO->ZO_PRODUTO	:= SZJ->ZJ_PRODUTO
		MsUnLock()

		// atualiza os dados da movimentacao da unidade
		dbSelectArea("SZ3")
		SZ3->(dbOrderNickName("Z3_RIC")) // 4-Z3_FILIAL, Z3_RIC
		If SZ3->(dbSeek( xFilial("SZ3")+SZJ->ZJ_RIC ))
			// marca a data para o proximo faturamento
			RecLock("SZ3",.F.)
			SZ3->Z3_DTFATPA := SZJ->ZJ_DTPROCE
			MsUnlock()

			// quando o container ja saiu, marca o movimento de saida como faturado
			If (!Empty(SZ3->Z3_DTSAIDA))
				// funcao para pesquisar a RIC de saida
				_cRICSaida := U_FtRetRIC(SZJ->ZJ_RIC)

				// atualiza os dados da movimentacao da unidade
				dbSelectArea("SZ3")
				SZ3->(dbOrderNickName("Z3_RIC")) // 4-Z3_FILIAL, Z3_RIC
				If SZ3->(dbSeek( xFilial("SZ3")+_cRICSaida ))
					// marca a data para o proximo faturamento
					RecLock("SZ3",.F.)
					SZ3->Z3_DTFATPA := SZJ->ZJ_DTPROCE
					MsUnlock()
				EndIf
			EndIF
		EndIf

		// baixa ordens de servico do pacote
		sfBaixaOS(mvTpFatur,.t.)

		// baixa fretes do pacote
		sfBaixaFrete(mvTpFatur,.t.)

	Next _nItem

Return(.t.)

// ** funcao responsavel por marcar os detalhes do servico como faturado
// ** 7-SERVICOS DIVERSOS
Static Function sfBaixaOS(mvTpFatur,mvPacLog)
	// area inicial
	local _aAreaSZ6 := SZ6->(GetArea())
	local _aAreaSZ7 := SZ7->(GetArea())
	// detalhes do servico
	local _aItens := sfDetServico(.f.,nil,mvPacLog,.t.)
	// posicao do campo RECNO
	local _nPosRecno := If((Len(_aItens) > 0),(Len(_aItens[1]) - 1),0)
	// variaveis temporarias
	local _nItem
	// RIC de saida
	local _cRICSaida

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)

		// posiciona no registro real da tabela
		dbSelectArea("SZL")
		SZL->(dbGoTo(_aItens[_nItem][_nPosRecno]))

		// verifica se deve baixar a OS
		If (!mvPacLog).and.(mvTpFatur=="F").and.(SZL->ZL_FATURAR <> "S")
			Loop
		EndIf

		// quando for cancelamento, verifica se deve baixar a OS
		If (!mvPacLog).and.(mvTpFatur=="C").and.(SZL->ZL_FATURAR <> "I")
			Loop
		EndIf


		// atualiza os campos
		RecLock("SZL")
		SZL->ZL_STATUS	:= mvTpFatur
		SZL->ZL_IDPROCE	:= ""
		SZL->ZL_PEDIDO	:= (_TRBGERAL)->IT_NUMPED
		SZL->ZL_ITEMPED	:= (_TRBGERAL)->IT_ITEMPED
		SZL->ZL_OBSFAT	:= If(mvTpFatur=="F","",AllTrim(UsrRetName(__cUserID))+": "+_cMotCanc)
		SZL->ZL_PRODUTO	:= If(!Empty(SZL->ZL_PRODUTO),SZL->ZL_PRODUTO,sfRetCdSrv((_TRBGERAL)->IT_TIPOSRV))
		MsUnLock()

		// cria o item no pacote logistico
		If (mvPacLog)
			dbSelectArea("SZO")
			SZO->(dbOrderNickName("ZO_PACOTE")) // 1-ZO_FILIAL, ZO_PACOTE, ZO_SEQPACO, ZO_PRODUTO
			If ! SZO->(dbSeek( xFilial("SZO")+SZL->(ZL_PACOTE+ZL_SEQPACO+ZL_PRODUTO) ))
				RecLock("SZO",.t.)
				SZO->ZO_FILIAL	:= xFilial("SZO")
				SZO->ZO_PACOTE	:= SZL->ZL_PACOTE
				SZO->ZO_SEQPACO	:= SZL->ZL_SEQPACO
				SZO->ZO_PRODUTO	:= SZL->ZL_PRODUTO
				MsUnLock()
			EndIf
		EndIf

		// atualiza os dados da OS - Cabec
		dbSelectArea("SZ6")
		SZ6->(dbSetOrder(1)) //1-Z6_FILIAL, Z6_NUMOS, Z6_CLIENTE, Z6_LOJA
		If SZ6->(dbSeek( xFilial("SZ6")+SZL->ZL_NUMOS ))
			RecLock("SZ6")
			SZ6->Z6_STATUS := "P"
			MsUnlock()
		EndIf

		// atualiza os dados da OS - Itens
		dbSelectArea("SZ7")
		SZ7->(dbSetOrder(1)) //1-Z7_FILIAL, Z7_NUMOS, Z7_CODATIV
		If SZ7->(dbSeek( xFilial("SZ7")+SZL->(ZL_NUMOS+ZL_CODATIV) ))
			RecLock("SZ7")
			SZ7->Z7_SALDO	-= SZL->ZL_QUANT
			SZ7->Z7_DTFATAT := SZL->ZL_DTPROCE
			MsUnlock()
		EndIf

	Next _nItem

	// restaura area inicial
	RestArea(_aAreaSZ7)
	RestArea(_aAreaSZ6)

Return(.t.)

// ** funcao responsavel por marcar os detalhes do servico como faturado
// ** 8-VALORES FIXOS / ALUGUEIS
Static Function sfBaixaFixo(mvTpFatur)
	// detalhes do servico
	local _aItens := sfDetFixo(.f.,nil,nil,.t.)
	// posicao do campo RECNO
	local _nPosRecno := If((Len(_aItens) > 0),(Len(_aItens[1]) - 1),0)
	// variaveis temporarias
	local _nItem

	// varre todos os detalhes
	For _nItem := 1 to Len(_aItens)

		// posiciona no registro real da tabela
		dbSelectArea("SZM")
		SZM->(dbGoTo(_aItens[_nItem][_nPosRecno]))

		// atualiza os campos
		RecLock("SZM")
		SZM->ZM_STATUS	:= mvTpFatur
		SZM->ZM_IDPROCE	:= ""
		SZM->ZM_PEDIDO	:= (_TRBGERAL)->IT_NUMPED
		SZM->ZM_ITEMPED	:= (_TRBGERAL)->IT_ITEMPED
		MsUnLock()

	Next _nItem

Return(.t.)

// ** funcao pra visualizar a nota fiscal de entrada (remessa)
Static Function sfVisualNFE(mvHeader)
	local _nPosDoc := aScan(mvHeader,{|x| AllTrim(SubS(x[2],4))=="DOC"})
	local _nPosSerie := aScan(mvHeader,{|x| AllTrim(SubS(x[2],4))=="SERIE"})

	// cria variaveis internas do sistema
	private aParamAuto := {}

	// posciona na nota fiscal de entrada
	dbSelectArea("SF1")
	SF1->(dbSetOrder(1)) //1-F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO
	If MsSeek( xFilial("SF1")+_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nPosDoc]+_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nPosSerie]+(_TRBGERAL)->(IT_CODCLIE+IT_LOJCLIE)+"B" )
		A103NFiscal("SF1",SF1->(RecNo()),1)
	EndIf

Return(.t.)

// ** funcao para visualizar o pedido de venda
User Function FATA002N()

	// valida se tem pedido de venda para visualizar
	If (Left((_TRBGERAL)->IT_NUMPED,1)!="C") .and. Empty((_TRBGERAL)->IT_NUMPED)
		Aviso("TFATA002 -> FATA002N","Não há pedido de venda para visualizar.",{"Fechar"})
		Return(.f.)
	EndIf

	// posiciona no pedido de venda
	dbSelectArea("SC5")
	SC5->(dbSetOrder(1)) //1-C5_FILIAL, C5_NUM
	If dbSeek(xFilial("SC5")+(_TRBGERAL)->IT_NUMPED)
		A410Visual("SC5",SC5->(RecNo()),2)
	EndIf

Return(.t.)


// ** funcao para estornar um faturamento
User Function FATA002Y()
	// Seek do SC5
	local _cSeekSC5

	// valida se tem pedido de venda
	If Empty((_TRBGERAL)->IT_NUMPED)
		Aviso("TFATA002 -> FATA002N","Não há pedido de venda para estornar.",{"Fechar"})
		Return(.f.)
	EndIf

	// mensagem de confirmacao
	If (Aviso("Estorno","Confirma o estorno do faturamento ?",{"Sim","Não"})==1)
		// se for item cancelado, executa ponto de entrada padrao do pedido de venda
		If (Left((_TRBGERAL)->IT_NUMPED,1)=="C")
			// ponto de entrada da exclusao do pedido de venda
			// parametros
			// 1. Se eh chamada pelo rotina de faturamento de contratos (.T./.F.)
			// 2. Numero do Pedido
			// 3. Item do Pedido
			// 4. Codigo do Produto
			U_MTA410E(.t.,(_TRBGERAL)->IT_NUMPED,(_TRBGERAL)->IT_ITEMPED,(_TRBGERAL)->IT_CODPROD)

			// se for pedido de venda
		Else
			// posiciona no pedido de venda
			dbSelectArea("SC5")
			SC5->(dbSetOrder(1)) //1-C5_FILIAL, C5_NUM
			If dbSeek(xFilial("SC5")+(_TRBGERAL)->IT_NUMPED)
				// executa funcao para estornar os itens liberados
				dbSelectArea("SC9")
				SC9->(dbSetOrder(1)) // 1-C9_FILIAL, C9_PEDIDO, C9_ITEM, C9_SEQUEN, C9_PRODUTO
				SC9->(dbSeek( _cSeekSC5 := xFilial("SC9")+SC5->C5_NUM ))
				While SC9->( ! Eof() ) .and. ((SC9->C9_FILIAL + SC9->C9_PEDIDO) == _cSeekSC5)

					// descarta itens faturados
					If (SC9->C9_BLEST=="10").and.(SC9->C9_BLCRED=="10")
						// apresenta mensagem
						Aviso("TFATA002 -> FATA002Y","Não é possível estornar o pedido pois o mesmo encontra-se faturado.",{"Fechar"})
						Return(.f.)
					EndIf

					// rotina padrao para estorno da liberacao
					a460Estorna()

					// proximo item
					SC9->(dbSkip())
				Enddo
							// variaveis internas da rotina padrao MATA410
				lMSHelpAuto := .T.
				lMsErroAuto := .F.
				
				MSExecAuto({|x,y,z|Mata410(x,y,z)},{{"C5_NUM",(_TRBGERAL)->IT_NUMPED,Nil}},{},5)
				
				If lMsErroAuto
					Alert("Erro no estorno do Pedido")
					// rollback na transacao
					DisarmTransaction()
					// mostra o erro
					MostraErro()
					// encerra a rotina
					Return(.f.)
				Else
					(_TRBGERAL)->(RecLock(_TRBGERAL,.F.))
					(_TRBGERAL)->IT_NUMPED	:= " "
					(_TRBGERAL)->(MsUnlock())
				EndIf
				
				/*// rotina padrao de exclusao de pedido
				If (A410Deleta("SC5",SC5->(RecNo()),5) <> 2)// 5-Excluir
					Return(.f.)
				EndIf*/

			EndIf

		EndIf
		
	EndIf

Return(.t.)

// ** funcao que retorna a descricao de campo combobox
Static Function sfCBoxDescr(mvCampo,mvConteudo,mvPesq,mvRet)
	Local _aAreaSX3 := SX3->(GetArea())
	// retorno em array
	// 1 -> S=Sim
	// 2 -> S
	// 3 -> Sim
	Local _aCbox := RetSx3Box(Posicione('SX3',2,mvCampo,'X3CBox()'),,,TamSx3(mvCampo)[1])
	Local _nPos  := aScan( _aCbox , {|x| AllTrim(x[mvPesq]) == AllTrim(mvConteudo) } )
	Local _cRet  := If(_nPos>0,_aCbox[_nPos,mvRet],"")
	// restaura area inicial
	RestArea(_aAreaSX3)
Return(_cRet)

// ** funcao responsavel pela Legenda
User Function FATA002H
	BrwLegenda(cCadastro, "Status",{{"ENABLE"	,"Apto a Faturar"},;
	{"BR_AZUL"	,"Ocorrência Sem Item no Contrato"},;
	{"BR_AMARELO","Cancelado"},;
	{"DISABLE"	,"Pedido de Venda Gerado"} })
Return

// ** funcao para selecao dos itens a nao processar
User Function FATA002P(mvValida)

	Local _cVar      := Upper( Alltrim( ReadVar() ) )
	local _cValor    := ""
	Local _lRet      := .T.
	local _cValorSX3 := ""
	local _nPosIni, _nPosFim

	// valor padrao do parametro
	Default mvValida := .f.

	Static __cWhenLastVar__

	DEFAULT __cWhenLastVar__ := "__cWhenLastVar__"

	// quando chamada em forma de validacao
	If (mvValida)

		// extrai valores validos
		_cValorSX3 := AllTrim(GetSx3Cache("B1_TIPOSRV", "X3_VLDUSER"))
		// busca funcao "pertence"
		_nPosIni := At("PERTENCE", Upper(_cValorSX3))
		// organiza os dados, removendo a funcao
		_cValorSX3 := SubS(_cValorSX3, (_nPosIni + 10))
		// busca a posicao final
		_nPosFim := At('"', Upper(_cValorSX3))
		// organiza os dados, removendo o restante da validacao
		_cValorSX3 := SubS(_cValorSX3, 1, (_nPosFim - 1))

		// extrai o valor do campo
		_cValor := AllTrim(&_cVar)
		// remove os asterisco
		_cValor := StrTran(_cValor, "*", "")

		// percorre os valores, para validar conteudo
		For _nPosIni := 1 to Len(_cValor)
			// verifica o conteud
			If (At(SubStr(_cValor, _nPosIni, 1), _cValorSX3) == 0)
				_lRet := .f.
			EndIf
		Next _nPosIni

		// retorno da validacao
		Return(_lRet)

		// quando chamada em forma de F3
	Else
		If ! ( __cWhenLastVar__ == _cVar )
			CposInitWhen()
		EndIf

		IF ( CposInitWhen( NIL , .T. ) )
			// chama rotina padrao de opcoes
			f_Opcoes(;
			@M->AAM_ZNAOFA           ,; // variavel de retorno
			"Opcoes para NAO faturar",; // titulo da janela
			nil                      ,; // opcoes de escolha
			nil                      ,; // opcoes para retorno
			nil                      ,; // nao utilizado
			nil                      ,; // nao utilizado
			.f.                      ,; // seleciona apenas 1 item
			nil                      ,; // tamanho da chave
			nil                      ,; // maximo de elementos de retorno
			.t.                      ,; // botao para selecionar todos os itens
			.t.                      ,; // se as opcoes vem de campo ComboBox (x3_cbox)
			"B1_TIPOSRV"              ) // nome do campo

			CposInitWhen( .F. )
		EndIf

		// atualiza variavel de retorno da consulta padrao
		VAR_IXB := &_cVar

		__cWhenLastVar__ := _cVar
	EndIf

Return( _lRet )

// ** funcao para reprocessar os contratos dentro da tela principal
User Function FATA002X()
	// desabilitado
	If (!_lBtnParam)
		Aviso("TFATA002 -> FATA002X","Opção desabilitada para este processo.",{"Fechar"})
		Return(.t.)
	EndIf

	// chama os parametros de processo
	If (Pergunte(_cPerg,.T.))

		// atualiza as variaveis
		mvProcDe	:= mv_par01
		mvProcAte	:= mv_par02
		mvClieDe	:= mv_par03
		mvClieAte	:= mv_par04
		mvContDe	:= mv_par05
		mvContAte	:= mv_par06
		mvMostraFat := (mv_par07==1) // mostra faturados anteriormente
		mvTpServ	:= mv_par08
		mvStsProc	:= mv_par09 // status do processo (1-Aberto, 2-Encerrado, 3-Ambos)

		// chama funcao que processa todos os contratos de acordo com parametros iniciais
		Processa({ || sfProcContrato(.f.) },"Faturamento de Contratos...",,.T.)

	EndIf

Return(.t.)

// ** funcao que realiza a limpeza de informacoes temporarias
Static Function sfLimpezaTmp(mvProcAnt)
	// variaveis temporarias
	local _cDelete

	// controle da regua de processamento
	IncProc("Limpeza de informações temporárias...")

	// limpa dados de armazenagem de container
	dbSelectArea("SZG")
	// script
	_cDelete := "DELETE FROM "+RetSqlName("SZG")+" "
	_cDelete += "WHERE ZG_FILIAL = '"+xFilial("SZG")+"' "
	_cDelete += "AND ZG_STATUS = ' ' "
	_cDelete += "AND ZG_USRPROC = '"+__cUserId+"' "
	// limpa dados de processo anteriores
	If (!_lWorkFlow)
		If (mvProcAnt)
			_cDelete += "AND ZG_DTPROCE <> '"+DtoS(_dDataBase)+"' "
		ElseIf (!mvProcAnt)
			_cDelete += "AND ZG_DTPROCE = '"+DtoS(_dDataBase)+"' "
			_cDelete += "AND ZG_IDPROCE = '"+_cIdProc+"' "
		EndIf
	EndIf
	// executa o DELETE
	TcSQLExec(_cDelete)


	// limpa dados de armazenagem de produtos
	_cDelete := "DELETE FROM "+RetSqlName("SZH")+" "
	_cDelete += "WHERE ZH_FILIAL = '"+xFilial("SZH")+"' "
	_cDelete += "AND ZH_STATUS = ' ' "
	_cDelete += "AND ZH_USRPROC = '"+__cUserId+"' "
	// limpa dados de processo anteriores
	If (!_lWorkFlow)
		If (mvProcAnt)
			_cDelete += "AND ZH_DTPROCE <> '"+DtoS(_dDataBase)+"' "
		ElseIf (!mvProcAnt)
			_cDelete += "AND ZH_DTPROCE = '"+DtoS(_dDataBase)+"' "
			_cDelete += "AND ZH_IDPROCE = '"+_cIdProc+"' "
		EndIf
	EndIf
	// executa o DELETE
	TcSQLExec(_cDelete)


	// limpa dados de SEGUROS
	_cDelete := "DELETE FROM "+RetSqlName("SZI")+" "
	_cDelete += "WHERE ZI_FILIAL = '"+xFilial("SZI")+"' "
	_cDelete += "AND ZI_STATUS = ' ' "
	_cDelete += "AND ZI_USRPROC = '"+__cUserId+"' "
	// limpa dados de processo anteriores
	If (!_lWorkFlow)
		If (mvProcAnt)
			_cDelete += "AND ZI_DTPROCE <> '"+DtoS(_dDataBase)+"' "
		ElseIf (!mvProcAnt)
			_cDelete += "AND ZI_DTPROCE = '"+DtoS(_dDataBase)+"' "
			_cDelete += "AND ZI_IDPROCE = '"+_cIdProc+"' "
		EndIf
	EndIf
	// executa o DELETE
	TcSQLExec(_cDelete)


	// limpa dados de PACOTE LOGISTICO
	_cDelete := "DELETE FROM "+RetSqlName("SZJ")+" "
	_cDelete += "WHERE ZJ_FILIAL = '"+xFilial("SZJ")+"' "
	_cDelete += "AND ZJ_STATUS = ' ' "
	_cDelete += "AND ZJ_USRPROC = '"+__cUserId+"' "
	// limpa dados de processo anteriores
	If (!_lWorkFlow)
		If (mvProcAnt)
			_cDelete += "AND ZJ_DTPROCE <> '"+DtoS(_dDataBase)+"' "
		ElseIf (!mvProcAnt)
			_cDelete += "AND ZJ_DTPROCE = '"+DtoS(_dDataBase)+"' "
			_cDelete += "AND ZJ_IDPROCE = '"+_cIdProc+"' "
		EndIf
	EndIf
	// executa o DELETE
	TcSQLExec(_cDelete)


	// limpa dados de 7-FRETES
	_cDelete := "DELETE FROM "+RetSqlName("SZK")+" "
	_cDelete += "WHERE ZK_FILIAL = '"+xFilial("SZK")+"' "
	_cDelete += "AND ZK_STATUS = ' ' "
	_cDelete += "AND ZK_USRPROC = '"+__cUserId+"' "
	// limpa dados de processo anteriores
	If (!_lWorkFlow)
		If (mvProcAnt)
			_cDelete += "AND ZK_DTPROCE <> '"+DtoS(_dDataBase)+"' "
		ElseIf (!mvProcAnt)
			_cDelete += "AND ZK_DTPROCE = '"+DtoS(_dDataBase)+"' "
			_cDelete += "AND ZK_IDPROCE = '"+_cIdProc+"' "
		EndIf
	EndIf
	// executa o DELETE
	TcSQLExec(_cDelete)


	// limpa dados de ORDEM DE SERVICOS
	_cDelete := "DELETE FROM "+RetSqlName("SZL")+" "
	_cDelete += "WHERE ZL_FILIAL = '"+xFilial("SZL")+"' "
	_cDelete += "AND ZL_STATUS = ' ' "
	_cDelete += "AND ZL_USRPROC = '"+__cUserId+"' "
	// limpa dados de processo anteriores
	If (!_lWorkFlow)
		If (mvProcAnt)
			_cDelete += "AND ZL_DTPROCE <> '"+DtoS(_dDataBase)+"' "
		ElseIf (!mvProcAnt)
			_cDelete += "AND ZL_DTPROCE = '"+DtoS(_dDataBase)+"' "
			_cDelete += "AND ZL_IDPROCE = '"+_cIdProc+"' "
		EndIf
	EndIf
	// executa o DELETE
	TcSQLExec(_cDelete)


	// limpa dados de VALORES FIXOS / ALUGUEIS
	_cDelete := "DELETE FROM "+RetSqlName("SZM")+" "
	_cDelete += "WHERE ZM_FILIAL = '"+xFilial("SZM")+"' "
	_cDelete += "AND ZM_STATUS = ' ' "
	_cDelete += "AND ZM_USRPROC = '"+__cUserId+"' "
	// limpa dados de processo anteriores
	If (!_lWorkFlow)
		If (mvProcAnt)
			_cDelete += "AND ZM_DTPROCE <> '"+DtoS(_dDataBase)+"' "
		ElseIf (!mvProcAnt)
			_cDelete += "AND ZM_DTPROCE = '"+DtoS(_dDataBase)+"' "
			_cDelete += "AND ZM_IDPROCE = '"+_cIdProc+"' "
		EndIf
	EndIf
	// executa o DELETE
	TcSQLExec(_cDelete)


	// limpa dados de SALDO POR ITEM DA NOTA
	dbSelectArea("Z48")
	// script
	_cDelete := "DELETE FROM "+RetSqlName("Z48")+" "
	_cDelete += "WHERE Z48_FILIAL = '"+xFilial("Z48")+"' "
	_cDelete += "AND Z48_STATUS = ' ' "
	_cDelete += "AND Z48_USRPRO = '"+__cUserId+"' "
	// limpa dados de processo anteriores
	If (!_lWorkFlow)
		If (mvProcAnt)
			_cDelete += "AND Z48_DTPROC <> '"+DtoS(_dDataBase)+"' "
		ElseIf (!mvProcAnt)
			_cDelete += "AND Z48_DTPROC = '"+DtoS(_dDataBase)+"' "
			_cDelete += "AND Z48_IDPROC = '"+_cIdProc+"' "
		EndIf
	EndIf
	
	// executa o DELETE
	TcSQLExec(_cDelete)
	
	memowrit("c:\query\sfLimpezaTmp.txt",_cDelete)

Return(.t.)


// ** funcao que monta a tela com todas as informacoes necessarias
Static Function sfTelaGeral()
	// campos do browse
	local _aHeadBrw 	:= {}
	// legenda
	local _aCorLegenda 	:= {}
	
	local lMarcar 		:= .F.

	// variaveis para o MarkBrowse
	Private _cMarca		:= GetMark()
	Private cCadastro	:= "Faturamento de Contrato"
	// sub-menu de consultas
	private _aBtnCons	:= {;
	{ "Cons. Detalhada"		,"U_FATA002V('1')"	,0	,2},;
	{ "Consulta de Log"		,"U_FATA002V('2')"	,0	,2},;
	{ "Consulta Contrato"	,"U_FATA002V('3')"	,0	,2},;
	{ "Id. Processo"		,"U_FATA002V('4')"	,0	,2} }

	// sub-menu de impressão
	private _aBtnImpre	:= {;
	{ "Det. Faturamento"	,"U_FATA002O('1')"	,0	,2},;
	{ "Histór. Faturamento"	,"U_FATA002O('2')"	,0	,2},;
	{ "Mapa Movimentação"	,"U_FATA002O('3')"	,0	,2} }

	// sub-menu do pedido de vendas
	private _aBtnPedVen	:= {;
	{ "Gera Pedido Venda"	,"U_FATA002G('F')"	,0	,2},;
	{ "Visualizar Pedido"	,"U_FATA002N()"		,0	,2},;
	{ "Análise de Crédito"	,"U_FATA002U('CR')"	,0	,2},;
	{ "Estornar"			,"U_FATA002Y()"		,0	,2},;
	{ "Gera Nota Fiscal"	,"U_FATA002U('NF')"	,0	,2} }

	// opcoes do menus
	Private aRotina		:= {;
	{ "Parametros"			,"U_FATA002X()"		,0	,2},;
	{ "Detalhes"			,"U_FATA002T()"		,0	,2},;
	{ "Pedido de Venda"		,_aBtnPedVen		,0	,2},;
	{ "Consultas"			,_aBtnCons			,0	,2},;
	{ "Relatórios"			,_aBtnImpre			,0	,2},;
	{ "Totais"				,"U_FATA002S()"		,0	,2},;
	{ "Encerrar Processo"	,"U_FATA002I(.f.)"	,0	,2},;
	{ "Encerrar Massa"		,"U_FATA002J()"		,0	,2},;
	{ "Ignorar Cobrança"	,"U_FATA002G('C')"	,0	,2},;
	{ "Inserir Comentário"	,"U_FATA002Q()"		,0	,2},;
	{ "Legenda"				,"U_FATA002H()"		,0	,2} }

	// inclui detalhes e titulos dos campos do browse

	AAdd(aColumns,FWBrwColumn():New())				
	aColumns[ Len(aColumns) ]:SetData( &("{||IT_PROCESS}"))
	aColumns[ Len(aColumns) ]:SetType("C")
	aColumns[ Len(aColumns) ]:SetTitle("Processo")
	aColumns[ Len(aColumns) ]:SetSize(TamSx3("Z2_CODIGO")[1])
	aColumns[ Len(aColumns) ]:SetPicture("")
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_LEFT)
	
	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||IT_NOMCLIE}"))
	aColumns[ Len(aColumns) ]:SetType("C")
	//aColumns[ Len(aColumns) ]:SetTitle(PadR("Nome",20))
	aColumns[ Len(aColumns) ]:SetTitle("Nome")
	aColumns[ Len(aColumns) ]:SetSize(TamSx3("A1_NREDUZ")[1])
	aColumns[ Len(aColumns) ]:SetPicture("")
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_LEFT)
	
	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||IT_DESPROD}"))
	aColumns[ Len(aColumns) ]:SetType("C")
	aColumns[ Len(aColumns) ]:SetTitle(PadR("Descrição",30))
	aColumns[ Len(aColumns) ]:SetSize(30)
	aColumns[ Len(aColumns) ]:SetPicture("")
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_LEFT)

	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||AAN_QUANT}"))
	aColumns[ Len(aColumns) ]:SetType("N")
	aColumns[ Len(aColumns) ]:SetTitle("Quant")
	aColumns[ Len(aColumns) ]:SetSize(TamSx3("AAN_QUANT")[1])
	aColumns[ Len(aColumns) ]:SetDecimal(TamSx3("AAN_QUANT")[2])
	aColumns[ Len(aColumns) ]:SetPicture(PesqPict("AAN","AAN_QUANT"))
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_RIGHT)

	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||AAN_VLRUNI}"))
	aColumns[ Len(aColumns) ]:SetType("N")
	aColumns[ Len(aColumns) ]:SetTitle("Vlr Unitario")
	aColumns[ Len(aColumns) ]:SetSize(TamSx3("AAN_VLRUNI")[1])
	aColumns[ Len(aColumns) ]:SetDecimal(TamSx3("AAN_VLRUNI")[2])
	aColumns[ Len(aColumns) ]:SetPicture(PesqPict("AAN","AAN_VLRUNI"))
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_RIGHT)

	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||AAN_VALOR}"))
	aColumns[ Len(aColumns) ]:SetType("N")
	aColumns[ Len(aColumns) ]:SetTitle("Vlr Total")
	aColumns[ Len(aColumns) ]:SetSize(TamSx3("AAN_VALOR")[1])
	aColumns[ Len(aColumns) ]:SetDecimal(TamSx3("AAN_VALOR")[2])
	aColumns[ Len(aColumns) ]:SetPicture(PesqPict("AAN","AAN_VALOR"))
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_RIGHT)

	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||IT_NUMPED}"))
	aColumns[ Len(aColumns) ]:SetType("C")
	aColumns[ Len(aColumns) ]:SetTitle("Pedido")
	aColumns[ Len(aColumns) ]:SetSize(TamSx3("C6_NUM")[1])
	aColumns[ Len(aColumns) ]:SetPicture("")
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_LEFT)
	
	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||IT_ITEMPED}"))
	aColumns[ Len(aColumns) ]:SetType("C")
	aColumns[ Len(aColumns) ]:SetTitle("It.Pedido")
	aColumns[ Len(aColumns) ]:SetSize(TamSx3("C6_ITEM")[1])
	aColumns[ Len(aColumns) ]:SetPicture("")
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_LEFT)

	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||IT_CONTRAT}"))
	aColumns[ Len(aColumns) ]:SetType("C")
	aColumns[ Len(aColumns) ]:SetTitle(PadR("Contrato",15))
	aColumns[ Len(aColumns) ]:SetSize(TamSx3("AAN_CONTRT")[1])
	aColumns[ Len(aColumns) ]:SetPicture("")
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_LEFT)

	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||IT_ITCONTR}"))
	aColumns[ Len(aColumns) ]:SetType("C")
	aColumns[ Len(aColumns) ]:SetTitle(PadR("It.Contr.",15))
	aColumns[ Len(aColumns) ]:SetSize(TamSx3("AAN_ITEM")[1])
	aColumns[ Len(aColumns) ]:SetPicture("")
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_LEFT)

	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||IT_ULTDATA}"))
	aColumns[ Len(aColumns) ]:SetType("D")
	aColumns[ Len(aColumns) ]:SetTitle(PadR("Dt.Ult.Fat.",15))
	aColumns[ Len(aColumns) ]:SetSize(TamSx3("AAN_DATA")[1])
	aColumns[ Len(aColumns) ]:SetPicture("")
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_CENTER)

	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||IT_ITPROCE}"))
	aColumns[ Len(aColumns) ]:SetType("C")
	aColumns[ Len(aColumns) ]:SetTitle(PadR("It.Proc.",15))
	aColumns[ Len(aColumns) ]:SetSize(TamSx3("Z2_ITEM")[1])
	aColumns[ Len(aColumns) ]:SetPicture("")
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_LEFT)
	
	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||IT_CODCLIE}"))
	aColumns[ Len(aColumns) ]:SetType("C")
	aColumns[ Len(aColumns) ]:SetTitle("Cod.Cliente")
	aColumns[ Len(aColumns) ]:SetSize(TamSx3("A1_COD")[1])
	aColumns[ Len(aColumns) ]:SetPicture("")
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_LEFT)

	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||IT_LOJCLIE}"))
	aColumns[ Len(aColumns) ]:SetType("C")
	aColumns[ Len(aColumns) ]:SetTitle("Loja")
	aColumns[ Len(aColumns) ]:SetSize(TamSx3("A1_LOJA")[1])
	aColumns[ Len(aColumns) ]:SetPicture("")
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_LEFT)

	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||IT_CODPROD}"))
	aColumns[ Len(aColumns) ]:SetType("C")
	aColumns[ Len(aColumns) ]:SetTitle(PadR("Cod.Serviço",11))
	aColumns[ Len(aColumns) ]:SetSize(TamSx3("AAN_CODPRO")[1])
	aColumns[ Len(aColumns) ]:SetPicture("")
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_CENTER)
	
	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||IT_CHVCNTR}"))
	aColumns[ Len(aColumns) ]:SetType("C")
	aColumns[ Len(aColumns) ]:SetTitle("Chave Contrato")
	aColumns[ Len(aColumns) ]:SetSize(32)
	aColumns[ Len(aColumns) ]:SetPicture("")
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_LEFT)	
	
	AAdd(aColumns,FWBrwColumn():New())
	aColumns[ Len(aColumns) ]:SetData( &("{||IT_ORDEM}"))
	aColumns[ Len(aColumns) ]:SetType("C")
	aColumns[ Len(aColumns) ]:SetTitle("Ordem dos Dados")
	aColumns[ Len(aColumns) ]:SetSize(4)
	aColumns[ Len(aColumns) ]:SetPicture("")	
	aColumns[ Len(aColumns) ]:SetAlign(CONTROL_ALIGN_RIGHT)
	
	// seleciona o arquivo de trabalho
	(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
	dbGotop()
	
	//Criando o MarkBrow
	oMark := FWMarkBrowse():New()
	oMark:SetAlias(_TRBGERAL)
	oMark:SetFieldMark("IT_OK")
	oMark:cMark := _cMarca
	oMark:SetDescription("Faturamento de Contrato")
	
	//Setando semáforo, descrição e campo de mark
	//oMark:SetSemaphore(.T.) //desabilitado pois não funciona com o AllMark
	
	//Setando o filtro da marcação
	oMark:SetCustomMarkRec({|| StaticCall(TFATA002,sfVldMrkGeral) })
	
	//Comportamento do botão do Header
    //oMark:SetAllMark( { || oMark:AllMark(), oMark:Refresh( .T. ) } )
	oMark:SetAllMark( { || sfMrkAll() } )
	
	//Setando Legenda
	oMark:AddLegend( "Empty((_TRBGERAL)->IT_CODPROD)"			,"BR_AZUL"		,"Sem código de produto" )
	oMark:AddLegend( "SubStr((_TRBGERAL)->IT_NUMPED,1,1)=='C'"	,"BR_AMARELO"	,"Pedido começa com C")
	oMark:AddLegend( "Empty((_TRBGERAL)->IT_NUMPED)"			,"ENABLE"		,"Sem Pedido de Venda")
	oMark:AddLegend( "!Empty((_TRBGERAL)->IT_NUMPED)"			,"DISABLE"		,"Tem Pedido de Venda")
	
	//Incluindo demais Colunas
	oMark:SetColumns( aColumns )

	//Opções
    oMark:SetTemporary() //Indica que o Browse utiliza tabela temporária
    	
	//Ativando a janela
	oMark:Activate()
	
	// seleciona o arquivo de trabalho
	(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
	(_TRBGERAL)->(dbCloseArea(_TRBGERAL))

Return(.t.)

// ** funcao para inverter selecao do mark brow
Static Function sfInvert(cMarca,lMarcar)
    
    Local cAliasMark := 'TRB'

    dbSelectArea(cAliasMark)
    (cAliasMark)->( dbGoTop() )
    While !(cAliasMark)->( Eof() )
        RecLock( (cAliasMark), .F. )
        (cAliasMark)->( IT_OK ) := IIf( lMarcar, cMarca, '  ' )
        MsUnlock()
        (cAliasMark)->( dbSkip() )
    EndDo
    
Return .T.

// ** funcao que carrega os dados da programacao
Static Function sfSelDados()

	// controle da regua de processamento
	IncProc("Organizando informações...")

	// cria o arquivo de trabalho
	If (Select(_TRBGERAL)==0)
		// cria o arquivo de trabalho para o MarkBrowse
		aAdd(_aStrTrbFat,{"IT_OK"       ,"C", 2,0})
		aAdd(_aStrTrbFat,{"IT_PROCESS"  ,"C", TamSx3("Z2_CODIGO")[1] ,0})
		aAdd(_aStrTrbFat,{"IT_ITPROCE"  ,"C", TamSx3("Z2_ITEM")[1]   ,0})
		aAdd(_aStrTrbFat,{"IT_CODCLIE"  ,"C", TamSx3("A1_COD")[1]    ,0})
		aAdd(_aStrTrbFat,{"IT_LOJCLIE"  ,"C", TamSx3("A1_LOJA")[1]   ,0})
		aAdd(_aStrTrbFat,{"IT_NOMCLIE"  ,"C", TamSx3("A1_NREDUZ")[1] ,0})
		aAdd(_aStrTrbFat,{"IT_CODPROD"  ,"C", TamSx3("AAN_CODPRO")[1],0})
		aAdd(_aStrTrbFat,{"IT_DESPROD"  ,"C", 30                     ,0})
		aAdd(_aStrTrbFat,{"AAN_QUANT"   ,"N", 10                     ,3})
		aAdd(_aStrTrbFat,{"AAN_VLRUNI"  ,"N", TamSx3("AAN_VLRUNI")[1],TamSx3("AAN_VLRUNI")[2]})
		aAdd(_aStrTrbFat,{"AAN_VALOR"   ,"N", TamSx3("AAN_VALOR")[1] ,TamSx3("AAN_VALOR")[2]})
		aAdd(_aStrTrbFat,{"IT_NUMPED"   ,"C", TamSx3("C6_NUM")[1]    ,0})
		aAdd(_aStrTrbFat,{"IT_ITEMPED"  ,"C", TamSx3("C6_ITEM")[1]   ,0})
		aAdd(_aStrTrbFat,{"IT_CONTRAT"  ,"C", TamSx3("AAN_CONTRT")[1],0})
		aAdd(_aStrTrbFat,{"IT_ITCONTR"  ,"C", TamSx3("AAN_ITEM")[1]  ,0})
		aAdd(_aStrTrbFat,{"IT_TIPOSRV"  ,"C", TamSx3("B1_TIPOSRV")[1],0})
		aAdd(_aStrTrbFat,{"IT_PACOTE"   ,"C", TamSx3("ZJ_PACOTE")[1] ,0})
		aAdd(_aStrTrbFat,{"IT_ULTDATA"  ,"D", TamSx3("AAN_DATA")[1]  ,0})
		aAdd(_aStrTrbFat,{"IT_CHVCNTR"  ,"C", 32                     ,0})
		aAdd(_aStrTrbFat,{"ZH_DIASPER"  ,"N", TamSx3("ZH_DIASPER")[1],TamSx3("ZH_DIASPER")[2]})
		aAdd(_aStrTrbFat,{"IT_ORDEM"    ,"C", 3						 ,0})

		// cria o TRB
		_oGerTmp := FWTemporaryTable():New(_TRBGERAL)
		_oGerTmp:SetFields(_aStrTrbFat)
		_oGerTmp:Create()
		
		IndRegua(_TRBGERAL,_oGerTmp:cIndexName,"IT_CODCLIE+IT_LOJCLIE+IT_PROCESS+IT_ITPROCE+IT_CODPROD+IT_CONTRAT+IT_ITCONTR+DtoS(IT_ULTDATA)+IT_NUMPED+IT_ITEMPED+IT_ORDEM",,,"Selecionando registros...") // limite do tamanho do indice deve ser 140

		// caso o arquivo exista, limpa os dados
	ElseIf (Select(_TRBGERAL) <> 0)
		// limpa o conteudo do TRB
		(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
		(_TRBGERAL)->(__DbZap())
	EndIf

	// chama as opcoes para buscar os detalhes
	// 1-Arm Container
	If (mvTpServ $ "01|99")
		sfDetArmCnt(.t.,nil,nil,.f.)
	EndIf
	// 2-Arm Produto
	If (mvTpServ $ "02|99")
		sfDetArmPrd(.t., nil, nil, .f.)
	EndIf
	// 3-Pacote Logistico
	If (mvTpServ $ "03|99")
		sfDetPacote(.t., nil, nil, .f., "3")
	EndIf
	// 4-Fretes
	If (mvTpServ $ "04|99")
		sfDetFrete(.t.,nil,nil,.f.)
	EndIf
	// 5-Seguros
	If (mvTpServ $ "05|99")
		sfDetSeguro(.t.,nil,nil,.f.)
	EndIf
	// 7-Servicos Diversos
	If (mvTpServ $ "07|99")
		sfDetServico(.t.,nil,nil,.f.)
	EndIf
	// 8-Valores Fixos (alugueis)
	If (mvTpServ $ "08|99").and.((cEmpAnt=="02").or.(Empty(mvProcDe).and.Empty(mvProcAte)))
		sfDetFixo(.t.,nil,nil,.f.)
	EndIf
	// A-Pacote Logistico Exportacao
	If (mvTpServ $ "10|99")
		sfDetPacote(.t., nil, nil, .f., "A")
	EndIf
	// B-Pacote de Servicos
	If (mvTpServ $ "11|99")
		sfDetPacote(.t., nil, nil, .f., "B")
	EndIf

Return

// ** busca todos os dados detalhados de armazenagem de container
Static Function sfDetArmCnt(mvResumo, mvHeader, mvPacteLog, mvFatura)
	// variaveis temporarias
	local _cQuery
	// variavel de retorno para informacoes detalhadas
	local _aRet := {}

	// valores padroes dos parametros
	Default mvFatura := .f.

	// busca as movimentacoes
	_cQuery := "SELECT "

	// informacoes resumidas para o browse principal]
	If (mvResumo)
		_cQuery += "' ' IT_OK, ZG_PROCES IT_PROCESS, ZG_ITPROC IT_ITPROCE, ZG_CLIENTE IT_CODCLIE, ZG_LOJA IT_LOJCLIE, A1_NOME IT_NOMCLIE, "
		_cQuery += "ZG_PRODUTO IT_CODPROD, ISNULL(ZR_DESCRI,ISNULL(AAN_ZDESCR,'<< ARMAZENAGEM DE CONTAINER >>')) IT_DESPROD, SUM(ZG_QUANT) AAN_QUANT, ZG_VLRUNIT AAN_VLRUNI, SUM(ZG_TOTAL) AAN_VALOR, "
		_cQuery += "ZG_PEDIDO IT_NUMPED, ZG_ITEMPED IT_ITEMPED, ZG_CONTRT IT_CONTRAT, ZG_ITCONTR IT_ITCONTR, ISNULL(B1_TIPOSRV,'1') IT_TIPOSRV, ZG_TAMCONT, "
		// busca a ultima data de faturamento
		_cQuery += "CASE WHEN ZG_PEDIDO = ' ' THEN "
		_cQuery += "    (SELECT ISNULL(MAX(ZG_DTPROCE),'') FROM "+RetSqlName("SZG")+" ULTDT WHERE ULTDT.ZG_FILIAL = '"+xFilial("SZG")+"' AND ULTDT.D_E_L_E_T_ = ' ' "
		_cQuery += "     AND ULTDT.ZG_PROCES  = SZG.ZG_PROCES AND ULTDT.ZG_ITPROC  = SZG.ZG_ITPROC "
		_cQuery += "     AND ULTDT.ZG_CONTRT  = SZG.ZG_CONTRT AND ULTDT.ZG_ITCONTR = SZG.ZG_ITCONTR "
		_cQuery += "     AND ULTDT.ZG_PRODUTO = SZG.ZG_PRODUTO "
		_cQuery += "     AND ULTDT.ZG_IDPROCE = ' ' AND ULTDT.ZG_STATUS IN ('C','F')) "
		_cQuery += "ELSE ' ' END IT_ULTDATA "
		// informacoes detalhadas
	ElseIf (!mvResumo)
		_cQuery += "ZG_CONTAIN, ZG_TAMCONT, ZG_DTENTRA, ZG_DTSAIDA, ZG_DAYFREE, ZG_DTINI, ZG_DTFIM, ZG_QUANT, ZG_VLRUNIT, ZG_TOTAL, ZG_RIC, "
		_cQuery += "CONVERT(VarChar(8000), CONVERT(VarBinary(8000), ZG_OBSFAT)) ZG_OBSFAT, "
		_cQuery += "SZG.R_E_C_N_O_ SZGRECNO, '.F.' IT_DEL "
	EndIf

	// armazenagem de container
	_cQuery += "FROM "+RetSqlName("SZG")+" SZG "

	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	If (mvStsProc != 3) // 3-ambos
		// cad. processo
		_cQuery += "INNER JOIN "+RetSqlName("SZ1")+" SZ1 ON "+RetSqlCond("SZ1")+" AND Z1_CODIGO = ZG_PROCES "
		// filtro do status
		If (mvStsProc==1) // aberto
			_cQuery += "AND Z1_DTFINFA  = ' ' "
		ElseIf (mvStsProc==2) // encerrado
			_cQuery += "AND Z1_DTFINFA != ' ' "
		EndIf
	EndIf

	If (mvResumo)
		// cad. clientes
		_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 ON "+RetSqlCond("SA1")+" AND A1_COD = ZG_CLIENTE AND A1_LOJA = ZG_LOJA "
		// cad. produtos
		_cQuery += "LEFT  JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND B1_COD = ZG_PRODUTO "
		// itens do contrato
		_cQuery += "LEFT  JOIN "+RetSqlName("AAN")+" AAN ON "+RetSqlCond("AAN")+" AND AAN_CONTRT = ZG_CONTRT AND AAN_ITEM = ZG_ITCONTR "
		// resumo do faturamento
		_cQuery += "LEFT  JOIN "+RetSqlName("SZR")+" SZR ON "+RetSqlCond("SZR")+" AND ZR_PROGRAM = ZG_PROCES AND ZR_ITEPROG = ZG_ITPROC "
		_cQuery += "      AND ZR_CONTRT  = ZG_CONTRT  AND ZR_ITEM    = ZG_ITCONTR "
		_cQuery += "      AND ZR_CODCLI  = ZG_CLIENTE AND ZR_LOJCLI  = ZG_LOJA "
		_cQuery += "      AND ZR_PEDIDO  = ZG_PEDIDO  AND ZR_ITEPEDI = ZG_ITEMPED "
		_cQuery += "      AND ZR_CODSRV  = ZG_PRODUTO "
	EndIf

	// filtro dos dados
	_cQuery += "WHERE "+RetSqlCond("SZG")+" "
	// filtro padrao
	_cQuery += "AND ZG_PROCES  BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' "
	_cQuery += "AND ZG_CONTRT  BETWEEN '"+mvContDe+"' AND '"+mvContAte+"' "
	_cQuery += "AND ZG_CLIENTE BETWEEN '"+mvClieDe+"' AND '"+mvClieAte+"' "
	// filtro por ID de processo
	_cQuery += "AND ("
	// filtro de processo atual
	_cQuery += "     (ZG_DTPROCE = '"+DtoS(_dDataBase)+"' "
	_cQuery += "      AND ZG_USRPROC = '"+__cUserId+"' "
	_cQuery += "      AND ZG_IDPROCE = '"+_cIdProc+"' "
	_cQuery += "      AND ZG_STATUS = ' ') "
	// filtro para mostrar faturados/cancelados anteriormente
	If (mvMostraFat)
		_cQuery += " OR (ZG_IDPROCE = ' ' AND ZG_STATUS IN ('C','F')) "
	EndIf
	_cQuery += "    ) "

	// filtro especifico das informacoes detalhadas
	If (!mvResumo)
		_cQuery += "AND ZG_PROCES  = '"+(_TRBGERAL)->IT_PROCESS+"' "
		_cQuery += "AND ZG_ITPROC  = '"+(_TRBGERAL)->IT_ITPROCE+"' "
		_cQuery += "AND ZG_CONTRT  = '"+(_TRBGERAL)->IT_CONTRAT+"' "
		_cQuery += "AND ZG_ITCONTR = '"+(_TRBGERAL)->IT_ITCONTR+"' "
		// se for faturamento filtra pelo pedido de venda em branco
		If (mvFatura)
			_cQuery += "AND ZG_PEDIDO  = ' ' "
		ElseIf (!mvFatura)
			_cQuery += "AND ZG_PEDIDO  = '"+(_TRBGERAL)->IT_NUMPED+"' "
			_cQuery += "AND ZG_ITEMPED = '"+(_TRBGERAL)->IT_ITEMPED+"' "
		EndIf
	EndIf

	// informacoes resumidas
	If (mvResumo)
		// agrupamento de dados
		_cQuery += "GROUP BY ZG_PROCES, ZG_ITPROC, ZG_CLIENTE, ZG_LOJA, A1_NOME, ZG_PRODUTO, ISNULL(ZR_DESCRI,ISNULL(AAN_ZDESCR,'<< ARMAZENAGEM DE CONTAINER >>')), ZG_VLRUNIT, ZG_PEDIDO, ZG_ITEMPED, ZG_CONTRT, ZG_ITCONTR, B1_TIPOSRV, ZG_TAMCONT "
		// adiciona o conteudo da query para o arquivo de trabalho
		U_SqlToTrb(_cQuery,_aStrTrbFat,_TRBGERAL)
		// informacoes detalhadas
	ElseIf (!mvResumo)
		// adiciona o conteudo da query para um array
		_aRet := U_SqlToVet(_cQuery,{"ZG_DTINI","ZG_DTFIM","ZG_DTENTRA","ZG_DTSAIDA"})
	EndIf

	memoWrit("c:\query\sfDetArmCnt.txt",_cQuery)

	// se for dados detalhados, atualiza o header recebido como parametro
	If (!mvResumo).and.(!mvFatura)
		// zera o header
		mvHeader := {}

		// define todos os campos do header
		aAdd(mvHeader,{"Container"    ,"ZG_CONTAIN" ,PesqPict("SZG","ZG_CONTAIN") , TamSx3("ZG_CONTAIN")[1], 0,Nil,Nil,"C",Nil,"R" })
		aAdd(mvHeader,{"Tamanho"      ,"ZG_TAMCONT" ,PesqPict("SZG","ZG_TAMCONT") , TamSx3("ZG_TAMCONT")[1], 0,Nil,Nil,"C",Nil,"R" })
		aAdd(mvHeader,{"Dt Entrada"   ,"ZG_DTENTRA" ,""                           , TamSx3("ZG_DTENTRA")[1], 0,Nil,Nil,"D",Nil,"R" })
		aAdd(mvHeader,{"Dt Saida"     ,"ZG_DTSAIDA" ,""                           , TamSx3("ZG_DTSAIDA")[1], 0,Nil,Nil,"D",Nil,"R" })
		aAdd(mvHeader,{"Days Free"    ,"ZG_DAYFREE" ,PesqPict("SZG","ZG_DAYFREE") , TamSx3("ZG_DAYFREE")[1], TamSx3("ZG_DAYFREE")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"Dt Inicial"   ,"ZG_DTINI"   ,""                           , TamSx3("ZG_DTINI")[1]  , 0,Nil,Nil,"D",Nil,"R" })
		aAdd(mvHeader,{"Dt Final"     ,"ZG_DTFIM"   ,""                           , TamSx3("ZG_DTFIM")[1]  , 0,Nil,Nil,"D",Nil,"R" })
		aAdd(mvHeader,{"Periodos"     ,"ZG_QUANT"   ,PesqPict("SZG","ZG_QUANT")   , TamSx3("ZG_QUANT")[1]  , TamSx3("ZG_QUANT")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"Vlr. Unit."   ,"ZG_VLRUNIT" ,PesqPict("SZG","ZG_VLRUNIT") , TamSx3("ZG_VLRUNIT")[1], TamSx3("ZG_VLRUNIT")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"Total"        ,"ZG_TOTAL"   ,PesqPict("SZG","ZG_TOTAL")   , TamSx3("ZG_TOTAL")[1]  , TamSx3("ZG_TOTAL")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"RIC"          ,"ZG_RIC"     ,PesqPict("SZG","ZG_RIC")     , TamSx3("ZG_RIC")[1]    , 0,Nil,Nil,"C",Nil,"R" })
		aAdd(mvHeader,{"Obs Faturam." ,"ZG_OBSFAT"  ,""                           , TamSx3("ZG_OBSFAT")[1] , 0,Nil,Nil,"M",Nil,"R",,,IIf(_lEdita,".T.",".F.")  })
		aAdd(mvHeader,{"Recno"        ,"SZGRECNO"   ,"", 10 , 0,Nil,Nil,"N",Nil,"R",,,".F." })

		// re-ordena os dados pela 1-Container
		aSort(_aRet,,,{|x,y| x[1] < y[1] })

	EndIf

Return(If(mvResumo,.t.,_aRet))


// ** busca todos os dados detalhados de armazenagem de produtos
Static Function sfDetArmPrd(mvResumo, mvHeader, mvPacteLog, mvFatura)
	// variaveis temporarias
	local _cQuery
	// variavel de retorno para informacoes detalhadas
	local _aRet := {}

	// valores padroes dos parametros
	Default mvFatura := .f.

	// busca as movimentacoes
	_cQuery := "SELECT "

	// informacoes resumidas para o browse principal]
	If (mvResumo)
		_cQuery += "' ' IT_OK, ZH_PROCES IT_PROCESS, ZH_ITPROC IT_ITPROCE, ZH_CLIENTE IT_CODCLIE, ZH_LOJA IT_LOJCLIE, A1_NOME IT_NOMCLIE, "
		_cQuery += "ZH_PRODUTO IT_CODPROD, ISNULL(ZR_DESCRI,ISNULL(AAN_ZDESCR,'<< ARMAZENAGEM DE PRODUTO >>')) IT_DESPROD, 1 AAN_QUANT, ZH_VLRUNIT AAN_VLRUNI, SUM(ZH_TOTAL) AAN_VALOR, "
		_cQuery += "ZH_PEDIDO IT_NUMPED, ZH_ITEMPED IT_ITEMPED, ZH_CONTRT IT_CONTRAT, ZH_ITCONTR IT_ITCONTR, ISNULL(B1_TIPOSRV,'2') IT_TIPOSRV, "
		// busca a ultima data de faturamento
		_cQuery += "CASE WHEN ZH_PEDIDO = ' ' THEN "
		_cQuery += "    (SELECT ISNULL(MAX(ZH_DTPROCE),'') FROM "+RetSqlName("SZH")+" ULTDT WHERE ULTDT.ZH_FILIAL = '"+xFilial("SZH")+"' AND ULTDT.D_E_L_E_T_ = ' ' "
		_cQuery += "     AND ULTDT.ZH_PROCES  = SZH.ZH_PROCES AND ULTDT.ZH_ITPROC  = SZH.ZH_ITPROC "
		_cQuery += "     AND ULTDT.ZH_CONTRT  = SZH.ZH_CONTRT AND ULTDT.ZH_ITCONTR = SZH.ZH_ITCONTR "
		_cQuery += "     AND ULTDT.ZH_PRODUTO = SZH.ZH_PRODUTO "
		_cQuery += "     AND ULTDT.ZH_IDPROCE = ' ' AND ULTDT.ZH_STATUS IN ('C','F')) "
		_cQuery += "ELSE ' ' END IT_ULTDATA, "
		// chave do contrato
		_cQuery += "ltrim(ZH_PRODUTO+ISNULL(B1_TIPOSRV,'2')+ZH_TPARMAZ) IT_CHVCNTR, "
		// quantidade de dias no periodo
		_cQuery += "ZH_DIASPER, "
		// ordem dos dados (menor periodo por tarifa)
		_cQuery += "LTRIM(RTRIM(CAST(MIN(ZH_PERIODO) AS VARCHAR))) IT_ORDEM "

		// informacoes detalhadas
	ElseIf (!mvResumo)
		_cQuery += "ZH_PERIODO, ZH_DOC, ZH_SERIE, ZH_DAYFREE, ZH_VLRUNIT, ZH_SALDO, ZH_TOTAL, ZH_DTINI, ZH_DTFIM, ZH_TPARMAZ, ZH_DIASPER, "
		_cQuery += "CONVERT(VarChar(8000), CONVERT(VarBinary(8000), ZH_OBSFAT)) ZH_OBSFAT, ZH_GRPEST, "
		_cQuery += "SZH.R_E_C_N_O_ SZHRECNO, '.F.' IT_DEL "
	EndIf

	// armazenagem de produtos
	_cQuery += "FROM "+RetSqlName("SZH")+" SZH "

	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	If (mvStsProc != 3) // 3-ambos
		// cad. processo
		_cQuery += "INNER JOIN "+RetSqlName("SZ1")+" SZ1 ON "+RetSqlCond("SZ1")+" AND Z1_CODIGO = ZH_PROCES "
		// filtro do status
		If (mvStsProc==1) // aberto
			_cQuery += "AND Z1_DTFINFA  = ' ' "
		ElseIf (mvStsProc==2) // encerrado
			_cQuery += "AND Z1_DTFINFA != ' ' "
		EndIf
	EndIf

	If (mvResumo)
		// cad. clientes
		_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 ON "+RetSqlCond("SA1")+" AND A1_COD = ZH_CLIENTE AND A1_LOJA = ZH_LOJA "
		// cad. produtos
		_cQuery += "LEFT  JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND B1_COD = ZH_PRODUTO "
		// itens do contrato
		_cQuery += "LEFT  JOIN "+RetSqlName("AAN")+" AAN ON "+RetSqlCond("AAN")+" AND AAN_CONTRT = ZH_CONTRT AND AAN_ITEM = ZH_ITCONTR "
		// resumo do faturamento
		_cQuery += "LEFT  JOIN "+RetSqlName("SZR")+" SZR ON "+RetSqlCond("SZR")+" AND ZR_PROGRAM = ZH_PROCES AND ZR_ITEPROG = ZH_ITPROC "
		_cQuery += "      AND ZR_CONTRT  = ZH_CONTRT  AND ZR_ITEM   = ZH_ITCONTR "
		_cQuery += "      AND ZR_CODCLI  = ZH_CLIENTE AND ZR_LOJCLI = ZH_LOJA "
		_cQuery += "      AND ZR_PEDIDO  = ZH_PEDIDO AND ZR_ITEPEDI = ZH_ITEMPED "
		_cQuery += "      AND ZR_CODSRV  = ZH_PRODUTO "
	EndIf

	// filtro dos dados
	_cQuery += "WHERE "+RetSqlCond("SZH")+" "
	// filtro padrao
	_cQuery += "AND ZH_PROCES  BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' "
	_cQuery += "AND ZH_CONTRT  BETWEEN '"+mvContDe+"' AND '"+mvContAte+"' "
	_cQuery += "AND ZH_CLIENTE BETWEEN '"+mvClieDe+"' AND '"+mvClieAte+"' "
	// filtro por ID de processo
	_cQuery += "AND ("
	// filtro de processo atual
	_cQuery += "     (ZH_DTPROCE = '"+DtoS(_dDataBase)+"' "
	_cQuery += "      AND ZH_USRPROC = '"+__cUserId+"' "
	_cQuery += "      AND ZH_IDPROCE = '"+_cIdProc+"' "
	_cQuery += "      AND ZH_STATUS = ' ') "
	// filtro para mostrar faturados/cancelados anteriormente
	If (mvMostraFat)
		_cQuery += " OR (ZH_IDPROCE = ' ' AND ZH_STATUS IN ('C','F')) "
	EndIf
	_cQuery += "    ) "

	// filtro especifico das informacoes detalhadas
	If ( ! mvResumo )
		_cQuery += "AND ZH_PROCES  = '"+(_TRBGERAL)->IT_PROCESS+"' "
		_cQuery += "AND ZH_ITPROC  = '"+(_TRBGERAL)->IT_ITPROCE+"' "
		_cQuery += "AND ZH_CONTRT  = '"+(_TRBGERAL)->IT_CONTRAT+"' "
		_cQuery += "AND ZH_ITCONTR = '"+(_TRBGERAL)->IT_ITCONTR+"' "
		_cQuery += "AND ZH_DIASPER = "+AllTrim(Str((_TRBGERAL)->ZH_DIASPER))+" "
		// se for faturamento filtra pelo pedido de venda em branco
		If (mvFatura)
			_cQuery += "AND ZH_PEDIDO  = ' ' "
		ElseIf (!mvFatura)
			_cQuery += "AND ZH_PEDIDO  = '"+(_TRBGERAL)->IT_NUMPED+"' "
			_cQuery += "AND ZH_ITEMPED = '"+(_TRBGERAL)->IT_ITEMPED+"' "
		EndIf
	EndIf

	// informacoes resumidas
	If (mvResumo)
		// agrupamento de dados
		_cQuery += "GROUP BY ZH_PROCES, ZH_ITPROC, ZH_CLIENTE, ZH_LOJA, A1_NOME, ZH_PRODUTO, ISNULL(ZR_DESCRI,ISNULL(AAN_ZDESCR,'<< ARMAZENAGEM DE PRODUTO >>')), ZH_VLRUNIT, ZH_CONTRT, ZH_PEDIDO, ZH_ITEMPED, ZH_ITCONTR, B1_TIPOSRV, ZH_TPARMAZ, ZH_DIASPER "
		// adiciona o conteudo da query para o arquivo de trabalho
		U_SqlToTrb(_cQuery, _aStrTrbFat, _TRBGERAL)

		// informacoes detalhadas
	ElseIf (!mvResumo)
		// adiciona o conteudo da query para um array
		_aRet := U_SqlToVet(_cQuery,{"ZH_DTINI","ZH_DTFIM"})
	EndIf

	memoWrit("c:\query\tfata002_sfDetArmPrd.txt",_cQuery)

	// se for dados detalhados, atualiza o header recebido como parametro
	If (!mvResumo).and.(!mvFatura)
		// zera o header
		mvHeader := {}

		// define todos os campos do header
		aAdd(mvHeader,{"Periodo"      , "ZH_PERIODO", PesqPict("SZH","ZH_PERIODO"), TamSx3("ZH_PERIODO")[1], TamSx3("ZH_PERIODO")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"NF.Remessa"   , "ZH_DOC"    , PesqPict("SZH","ZH_DOC")    , TamSx3("ZH_DOC")[1]    , 0,Nil,Nil,"C",Nil,"R" })
		aAdd(mvHeader,{"Série"        , "ZH_SERIE"  , PesqPict("SZH","ZH_SERIE")  , TamSx3("ZH_SERIE")[1]  , 0,Nil,Nil,"C",Nil,"R" })
		aAdd(mvHeader,{"Days Free"    , "ZH_DAYFREE", PesqPict("SZH","ZH_DAYFREE"), TamSx3("ZH_DAYFREE")[1], TamSx3("ZH_DAYFREE")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"Tarifa"       , "ZH_VLRUNIT", PesqPict("SZH","ZH_VLRUNIT"), TamSx3("ZH_VLRUNIT")[1], TamSx3("ZH_VLRUNIT")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"Saldo NF"     , "ZH_SALDO"  , PesqPict("SZH","ZH_SALDO")  , TamSx3("ZH_SALDO")[1]  , TamSx3("ZH_SALDO")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"Valor"        , "ZH_TOTAL"  , PesqPict("SZH","ZH_TOTAL")  , TamSx3("ZH_TOTAL")[1]  , TamSx3("ZH_TOTAL")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"Dt Inicial"   , "ZH_DTINI"  , ""                          , TamSx3("ZH_DTINI")[1]  , 0,Nil,Nil,"D",Nil,"R" })
		aAdd(mvHeader,{"Dt Final"     , "ZH_DTFIM"  , ""                          , TamSx3("ZH_DTFIM")[1]  , 0,Nil,Nil,"D",Nil,"R" })
		aAdd(mvHeader,{"Tipo Armaz"   , "ZH_TPARMAZ", PesqPict("SZH","ZH_TPARMAZ"), TamSx3("ZH_TPARMAZ")[1], 0,Nil,Nil,"C",Nil,"R" })
		aAdd(mvHeader,{"Periodicidade", "ZH_DIASPER", PesqPict("SZH","ZH_DIASPER"), TamSx3("ZH_DIASPER")[1], TamSx3("ZH_DIASPER")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"Obs Faturam." , "ZH_OBSFAT" , ""                          , TamSx3("ZH_OBSFAT")[1] , 0,Nil,Nil,"M",Nil,"R",,,IIf(_lEdita,".T.",".F.")  })
		aAdd(mvHeader,{"Grupo Estoque", "ZH_GRPEST" , ""                          , TamSx3("ZH_GRPEST")[1] , 0,Nil,Nil,"C",Nil,"R" })
		aAdd(mvHeader,{"Recno"        , "SZHRECNO"  , ""                          , 10                     , 0,Nil,Nil,"N",Nil,"R",,,".F." })

		// re-ordena os dados pela 8-data INICIAL
		aSort(_aRet,,,{|x,y| x[8] < y[8] })
	EndIf

Return(If(mvResumo,.t.,_aRet))

// ** busca todos os dados detalhados de seguros
Static Function sfDetSeguro(mvResumo, mvHeader, mvPacteLog, mvFatura)
	// variaveis temporarias
	local _cQuery
	// variavel de retorno para informacoes detalhadas
	local _aRet := {}

	// valores padroes dos parametros
	Default mvFatura := .f.

	// busca as movimentacoes
	_cQuery := "SELECT "

	// informacoes resumidas para o browse principal
	If (mvResumo)
		_cQuery += "' ' IT_OK, ZI_PROCES IT_PROCESS, ZI_ITPROC IT_ITPROCE, ZI_CLIENTE IT_CODCLIE, ZI_LOJA IT_LOJCLIE, A1_NOME IT_NOMCLIE, "
		_cQuery += "ZI_PRODUTO IT_CODPROD, ISNULL(AAN_ZDESCR,'<< SEGUROS >>') IT_DESPROD, 1 AAN_QUANT, ZI_VLRUNIT AAN_VLRUNI, SUM(ZI_TOTAL) AAN_VALOR, "
		_cQuery += "ZI_PEDIDO IT_NUMPED, ZI_ITEMPED IT_ITEMPED, ZI_CONTRT IT_CONTRAT, ZI_ITCONTR IT_ITCONTR, ISNULL(B1_TIPOSRV,'5') IT_TIPOSRV, "
		// busca a ultima data de faturamento
		_cQuery += "CASE WHEN ZI_PEDIDO = ' ' THEN "
		_cQuery += "    (SELECT ISNULL(MAX(ZI_DTPROCE),'') FROM "+RetSqlName("SZI")+" ULTDT WHERE ULTDT.ZI_FILIAL = '"+xFilial("SZI")+"' AND ULTDT.D_E_L_E_T_ = ' ' "
		_cQuery += "     AND ULTDT.ZI_PROCES  = SZI.ZI_PROCES AND ULTDT.ZI_ITPROC  = SZI.ZI_ITPROC "
		_cQuery += "     AND ULTDT.ZI_CONTRT  = SZI.ZI_CONTRT AND ULTDT.ZI_ITCONTR = SZI.ZI_ITCONTR "
		_cQuery += "     AND ULTDT.ZI_PRODUTO = SZI.ZI_PRODUTO "
		_cQuery += "     AND ULTDT.ZI_IDPROCE = ' ' AND ULTDT.ZI_STATUS IN ('C','F')) "
		_cQuery += "ELSE ' ' END IT_ULTDATA "
		// informacoes detalhadas
	ElseIf ( ! mvResumo )
		_cQuery += "ZI_PERIODO, ZI_DOC, ZI_SERIE, ZI_VLRUNIT, ZI_SALDO, ZI_TOTAL, ZI_DIASPER, ZI_DTINI, ZI_DTFIM, "
		_cQuery += "CONVERT(VarChar(8000), CONVERT(VarBinary(8000), ZI_OBSFAT)) ZI_OBSFAT, "
		_cQuery += "SZI.R_E_C_N_O_ SZIRECNO, '.F.' IT_DEL "
	EndIf

	// seguros
	_cQuery += "FROM "+RetSqlTab("SZI")+" "

	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	If (mvStsProc != 3) // 3-ambos
		// cad. processo
		_cQuery += "INNER JOIN "+RetSqlTab("SZ1")+" ON "+RetSqlCond("SZ1")+" AND Z1_CODIGO = ZI_PROCES "
		// filtro do status
		If (mvStsProc==1) // aberto
			_cQuery += "AND Z1_DTFINFA  = ' ' "
		ElseIf (mvStsProc==2) // encerrado
			_cQuery += "AND Z1_DTFINFA != ' ' "
		EndIf
	EndIf

	If (mvResumo)
		// cad. clientes
		_cQuery += "INNER JOIN "+RetSqlTab("SA1")+" ON "+RetSqlCond("SA1")+" AND A1_COD = ZI_CLIENTE AND A1_LOJA = ZI_LOJA "
		// cad. produtos
		_cQuery += "LEFT  JOIN "+RetSqlTab("SB1")+" ON "+RetSqlCond("SB1")+" AND B1_COD = ZI_PRODUTO "
		// itens do contrato
		_cQuery += "LEFT  JOIN "+RetSqlTab("AAN")+" ON "+RetSqlCond("AAN")+" AND AAN_CONTRT = ZI_CONTRT AND AAN_ITEM = ZI_ITCONTR "
	EndIf

	// filtro dos dados
	_cQuery += "WHERE "+RetSqlCond("SZI")+" "
	// filtro padrao
	_cQuery += "AND ZI_PROCES  BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' "
	_cQuery += "AND ZI_CONTRT  BETWEEN '"+mvContDe+"' AND '"+mvContAte+"' "
	_cQuery += "AND ZI_CLIENTE BETWEEN '"+mvClieDe+"' AND '"+mvClieAte+"' "
	// filtro por ID de processo
	_cQuery += "AND ("
	// filtro de processo atual
	_cQuery += "     (ZI_DTPROCE = '"+DtoS(_dDataBase)+"' "
	_cQuery += "      AND ZI_USRPROC = '"+__cUserId+"' "
	_cQuery += "      AND ZI_IDPROCE = '"+_cIdProc+"' "
	_cQuery += "      AND ZI_STATUS = ' ') "
	// filtro para mostrar faturados/cancelados anteriormente
	If (mvMostraFat)
		_cQuery += " OR (ZI_IDPROCE = ' ' AND ZI_STATUS IN ('C','F')) "
	EndIf
	_cQuery += "    ) "

	// filtro especifico das informacoes detalhadas
	If ( ! mvResumo )
		_cQuery += "AND ZI_PROCES  = '"+(_TRBGERAL)->IT_PROCESS+"' "
		_cQuery += "AND ZI_ITPROC  = '"+(_TRBGERAL)->IT_ITPROCE+"' "
		_cQuery += "AND ZI_CONTRT  = '"+(_TRBGERAL)->IT_CONTRAT+"' "
		_cQuery += "AND ZI_ITCONTR = '"+(_TRBGERAL)->IT_ITCONTR+"' "
		// se for faturamento filtra pelo pedido de venda em branco
		If (mvFatura)
			_cQuery += "AND ZI_PEDIDO  = ' ' "
		ElseIf (!mvFatura)
			_cQuery += "AND ZI_PEDIDO  = '"+(_TRBGERAL)->IT_NUMPED+"' "
			_cQuery += "AND ZI_ITEMPED = '"+(_TRBGERAL)->IT_ITEMPED+"' "
		EndIf
	EndIf

	// informacoes resumidas
	If (mvResumo)
		// agrupamento de dados
		_cQuery += "GROUP BY ZI_PROCES, ZI_ITPROC, ZI_CLIENTE, ZI_LOJA, A1_NOME, ZI_PRODUTO, AAN_ZDESCR, ZI_VLRUNIT, ZI_PEDIDO, ZI_ITEMPED, ZI_CONTRT, ZI_ITCONTR, B1_TIPOSRV "
		// adiciona o conteudo da query para o arquivo de trabalho
		U_SqlToTrb(_cQuery, _aStrTrbFat, _TRBGERAL)
		// informacoes detalhadas
	ElseIf ( ! mvResumo )
		// adiciona o conteudo da query para um array
		_aRet := U_SqlToVet(_cQuery,{"ZI_DTINI","ZI_DTFIM"})
	EndIf

	memowrit("c:\query\tfata002_sfDetSeguro.txt",_cQuery)

	// se for dados detalhados, atualiza o header recebido como parametro
	If ( ! mvResumo ).and.( ! mvFatura )
		// zera o header
		mvHeader := {}

		// define todos os campos do header
		aAdd(mvHeader,{"Periodo"      ,"ZI_PERIODO", PesqPict("SZI","ZI_PERIODO") , TamSx3("ZI_PERIODO")[1] , TamSx3("ZI_PERIODO")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"NF.Remessa"   ,"ZI_DOC"    , PesqPict("SZI","ZI_DOC")     , TamSx3("ZI_DOC")[1]     , 0,Nil,Nil,"C",Nil,"R" })
		aAdd(mvHeader,{"Série"        ,"ZI_SERIE"  , PesqPict("SZI","ZI_SERIE")   , TamSx3("ZI_SERIE")[1]   , 0,Nil,Nil,"C",Nil,"R" })
		aAdd(mvHeader,{"Tarifa"       ,"ZI_VLRUNIT", PesqPict("SZI","ZI_VLRUNIT") , TamSx3("ZI_VLRUNIT")[1] , TamSx3("ZI_VLRUNIT")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"Saldo NF"     ,"ZI_SALDO"  , PesqPict("SZI","ZI_SALDO")   , TamSx3("ZI_SALDO")[1]   , TamSx3("ZI_SALDO")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"Valor Seguro" ,"ZI_TOTAL"  , PesqPict("SZI","ZI_TOTAL")   , TamSx3("ZI_TOTAL")[1]   , TamSx3("ZI_TOTAL")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"Periodicidade","ZI_DIASPER", PesqPict("SZI","ZI_DIASPER") , TamSx3("ZI_DIASPER")[1] , 0,Nil,Nil,"N",Nil,"R" })
		aAdd(mvHeader,{"Data Inicial" ,"ZI_DTINI"  , ""                           , TamSx3("ZI_DTINI")[1]   , 0,Nil,Nil,"D",Nil,"R" })
		aAdd(mvHeader,{"Data Final"   ,"ZI_DTFIM"  , ""                           , TamSx3("ZI_DTFIM")[1]   , 0,Nil,Nil,"D",Nil,"R" })
		aAdd(mvHeader,{"Obs Faturam." ,"ZI_OBSFAT" , ""                           , TamSx3("ZI_OBSFAT")[1]  , 0,Nil,Nil,"M",Nil,"R",,,IIf(_lEdita,".T.",".F.")  })
		aAdd(mvHeader,{"Recno"        ,"SZIRECNO"  , "", 10 , 0,Nil,Nil,"N",Nil,"R",,,".F." })

		// re-ordena os dados pela 8-data inicial
		aSort(_aRet,,,{|x,y| x[8] < y[8] })

	EndIf

Return( IIf(mvResumo, .t., _aRet) )

// ** busca todos os dados detalhados do pacote logistico
Static Function sfDetPacote(mvResumo, mvHeader, mvPacteLog, mvFatura, mvTpServPcte)
	// variaveis temporarias
	local _cQuery
	// variavel de retorno para informacoes detalhadas
	local _aRet := {}

	// valores padroes dos parametros
	Default mvFatura := .f.

	// busca as movimentacoes
	_cQuery := "SELECT "

	// informacoes resumidas para o browse principal]
	If (mvResumo)
		_cQuery += "' ' IT_OK, ZJ_PROCES IT_PROCESS, ZJ_ITPROC IT_ITPROCE, ZJ_CLIENTE IT_CODCLIE, ZJ_LOJA IT_LOJCLIE, A1_NOME IT_NOMCLIE, "
		_cQuery += "ZJ_PRODUTO IT_CODPROD, ISNULL(AAN_ZDESCR,'<< PACOTE LOGISTICO >>') IT_DESPROD, COUNT(*) AAN_QUANT, ZJ_VALOR AAN_VLRUNI, SUM(ZJ_VALOR) AAN_VALOR, "
		_cQuery += "ZJ_PEDIDO IT_NUMPED, ZJ_ITEMPED IT_ITEMPED, ZJ_CONTRT IT_CONTRAT, ZJ_ITCONTR IT_ITCONTR, ISNULL(B1_TIPOSRV,'"+mvTpServPcte+"') IT_TIPOSRV, ' ' IT_ULTDATA, ZJ_PACOTE IT_PACOTE "
		// informacoes detalhadas
	ElseIf (!mvResumo)
		_cQuery += "ZJ_VALOR, ZJ_DTMOVIM, ZJ_TPMOVIM, ZJ_RIC, ZJ_CONTAIN, ZJ_TAMCONT, ZJ_CONTEUD, "
		_cQuery += "SZBORIG.ZB_DESCRI IT_PRCORIG, SZBDEST.ZB_DESCRI IT_PRCDEST, "
		_cQuery += "A4_NREDUZ, SZJ.R_E_C_N_O_ SZJRECNO,  '.F.' IT_DEL "
	EndIf

	// pacote logistico
	_cQuery += "FROM "+RetSqlName("SZJ")+" SZJ "

	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	If (mvStsProc != 3) // 3-ambos
		// cad. processo
		_cQuery += "INNER JOIN "+RetSqlName("SZ1")+" SZ1 ON "+RetSqlCond("SZ1")+" AND Z1_CODIGO = ZJ_PROCES "
		// filtro do status
		If (mvStsProc==1) // aberto
			_cQuery += "AND Z1_DTFINFA  = ' ' "
		ElseIf (mvStsProc==2) // encerrado
			_cQuery += "AND Z1_DTFINFA != ' ' "
		EndIf
	EndIf

	// informacoes para o resumo
	If (mvResumo)
		// cad. clientes
		_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 ON "+RetSqlCond("SA1")+" AND A1_COD = ZJ_CLIENTE AND A1_LOJA = ZJ_LOJA "
		// cad. produtos
		_cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND B1_COD = ZJ_PRODUTO AND B1_TIPOSRV = '"+mvTpServPcte+"' "
		// itens do contrato
		_cQuery += "LEFT  JOIN "+RetSqlName("AAN")+" AAN ON "+RetSqlCond("AAN")+" AND AAN_CONTRT = ZJ_CONTRT AND AAN_ITEM = ZJ_ITCONTR "
	ElseIf (!mvResumo)
		// cad. de pracas
		_cQuery += "LEFT JOIN "+RetSqlName("SZB")+" SZBORIG ON SZBORIG.ZB_FILIAL = '"+xFilial("SZB")+"' AND SZBORIG.D_E_L_E_T_ = ' ' AND SZBORIG.ZB_CODIGO = ZJ_PRCORIG "
		_cQuery += "LEFT JOIN "+RetSqlName("SZB")+" SZBDEST ON SZBDEST.ZB_FILIAL = '"+xFilial("SZB")+"' AND SZBDEST.D_E_L_E_T_ = ' ' AND SZBDEST.ZB_CODIGO = ZJ_PRCDEST "
		// cad. transportadora
		_cQuery += "LEFT JOIN "+RetSqlName("SA4")+" SA4 ON "+RetSqlCond("SA4")+" AND A4_COD = ZJ_TRANSP "
	EndIf

	// filtro dos dados
	_cQuery += "WHERE "+RetSqlCond("SZJ")+" "
	// filtro padrao
	_cQuery += "AND ZJ_PROCES  BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' "
	_cQuery += "AND ZJ_CONTRT  BETWEEN '"+mvContDe+"' AND '"+mvContAte+"' "
	_cQuery += "AND ZJ_CLIENTE BETWEEN '"+mvClieDe+"' AND '"+mvClieAte+"' "
	// filtro por ID de processo
	_cQuery += "AND ("
	// filtro de processo atual
	//_cQuery += "     (ZI_DTPROCE = '"+DtoS(Date())+"' "
	_cQuery += "     (ZJ_DTPROCE = '"+DtoS(_dDataBase)+"' "
	_cQuery += "      AND ZJ_USRPROC = '"+__cUserId+"' "
	_cQuery += "      AND ZJ_IDPROCE = '"+_cIdProc+"' "
	_cQuery += "      AND ZJ_STATUS = ' ') "
	// filtro para mostrar faturados/cancelados anteriormente
	If (mvMostraFat)
		_cQuery += " OR (ZJ_IDPROCE = ' ' AND ZJ_STATUS IN ('C','F')) "
	EndIf
	_cQuery += "    ) "

	//_cQuery += "AND ZJ_FATURAR = 'S' "

	// filtro especifico das informacoes detalhadas
	If (!mvResumo)
		_cQuery += "AND ZJ_PROCES  = '"+(_TRBGERAL)->IT_PROCESS+"' "
		_cQuery += "AND ZJ_ITPROC  = '"+(_TRBGERAL)->IT_ITPROCE+"' "
		_cQuery += "AND ZJ_CONTRT  = '"+(_TRBGERAL)->IT_CONTRAT+"' "
		_cQuery += "AND ZJ_ITCONTR = '"+(_TRBGERAL)->IT_ITCONTR+"' "
		// se for faturamento filtra pelo pedido de venda em branco
		If (mvFatura)
			_cQuery += "AND ZJ_PEDIDO  = ' ' "
		ElseIf (!mvFatura)
			_cQuery += "AND ZJ_PEDIDO  = '"+(_TRBGERAL)->IT_NUMPED+"' "
			_cQuery += "AND ZJ_ITEMPED = '"+(_TRBGERAL)->IT_ITEMPED+"' "
		EndIf
	EndIf

	// informacoes resumidas
	If (mvResumo)
		// agrupamento de dados
		_cQuery += "GROUP BY ZJ_PROCES, ZJ_ITPROC, ZJ_CLIENTE, ZJ_LOJA, A1_NOME, ZJ_PRODUTO, AAN_ZDESCR, ZJ_VALOR, ZJ_PEDIDO, ZJ_ITEMPED, ZJ_CONTRT, ZJ_ITCONTR, B1_TIPOSRV, ZJ_PACOTE "
		// adiciona o conteudo da query para o arquivo de trabalho
		U_SqlToTrb(_cQuery,_aStrTrbFat,_TRBGERAL)
		// informacoes detalhadas
	ElseIf (!mvResumo)
		// adiciona o conteudo da query para um array
		_aRet := U_SqlToVet(_cQuery,{"ZJ_DTMOVIM"})
	EndIf

	memowrit("c:\query\TFATA002_sfDetPacote_"+mvTpServPcte+".txt",_cQuery)

	// se for dados detalhados, atualiza o header recebido como parametro
	If (!mvResumo).and.(!mvFatura)
		// zera o header
		mvHeader := {}

		// define todos os campos do header
		//aAdd(mvHeader,{"Qtde"           ,"ZJ_QUANT"   ,PesqPict("SZJ","ZJ_QUANT")   ,TamSx3("ZJ_QUANT")[1]  , TamSx3("ZJ_QUANT")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		//aAdd(mvHeader,{"Tarifa"         ,"ZJ_VLRUNIT" ,PesqPict("SZJ","ZJ_VLRUNIT") ,TamSx3("ZJ_VLRUNIT")[1], TamSx3("ZJ_VLRUNIT")[2],Nil,Nil,"N",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Valor"          ,"ZJ_VALOR"   ,PesqPict("SZJ","ZJ_VALOR")   ,TamSx3("ZJ_VALOR")[1]  , TamSx3("ZJ_VALOR")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Data"           ,"ZJ_DTMOVIM" ,""                           ,TamSx3("ZJ_DTMOVIM")[1], 0,Nil,Nil,"D",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Tipo"           ,"ZJ_TPMOVIM" ,PesqPict("SZJ","ZJ_TPMOVIM") ,TamSx3("ZJ_TPMOVIM")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"RIC"            ,"ZJ_RIC"     ,PesqPict("SZJ","ZJ_RIC")     ,TamSx3("ZJ_RIC")[1]    , 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Container"      ,"ZJ_CONTAIN" ,PesqPict("SZJ","ZJ_CONTAIN") ,TamSx3("ZJ_CONTAIN")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Tamanho"        ,"ZJ_TAMCONT" ,PesqPict("SZJ","ZJ_TAMCONT") ,TamSx3("ZJ_TAMCONT")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Conteudo"       ,"ZJ_CONTEUD" ,PesqPict("SZJ","ZJ_CONTEUD") ,TamSx3("ZJ_CONTEUD")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Praça Orig."    ,"ZB_DESCRI"  ,PesqPict("SZB","ZB_DESCRI")  , 20, 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Praça Dest."    ,"ZB_DESCRI"  ,PesqPict("SZB","ZB_DESCRI")  , 20, 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Transportadora" ,"A4_NREDUZ"  ,PesqPict("SA4","A4_NREDUZ")  , TamSx3("A4_NREDUZ")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Recno"          ,"SZJRECNO"   , "", 10 , 0,Nil,Nil,"N",Nil,"R",,,".F." })

		// ordem dos dados de retorno (posicao 5-Container)
		aSort(_aRet,,,{|x,y| x[5] < y[5] })
	EndIf

Return(If(mvResumo,.t.,_aRet))

// ** funcao para detalhar todos os servicos do pacote logistico
Static Function sfDetPacLog()
	// browse dos servicos do pacote
	local _aHeadPac := {}
	local _aColsPac := {}
	// browse dos detlhaes dos servicos do pacote
	local _aHeadSrv := {}
	local _aColsSrv := {}

	// variaveis da query
	local _cQryDet
	// dimensoes da tela
	local _aSizeDlg := MsAdvSize()

	// item ja faturado
	local _lItemFat := !Empty((_TRBGERAL)->IT_NUMPED)

	// cria o objeto do browse
	private _oBrwDetSrvPcte := nil

	// monta o header dos servicos do pacote logistico
	aAdd(_aHeadPac,{"Produto"  ,"ZO_PRODUTO",PesqPict("SZO","ZO_PRODUTO"), TamSx3("ZO_PRODUTO")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
	aAdd(_aHeadPac,{"Descricao","ZO_DESCRI" ,PesqPict("SZO","ZO_DESCRI") , TamSx3("ZO_DESCRI")[1] , 0,Nil,Nil,"C",Nil,"R",,,".F."  })

	// se o item ja estiver faturado, busca os itens do pacote logistico - SZO
	If (_lItemFat)
		_cQryDet := "SELECT DISTINCT ZO_PRODUTO, B1_DESC, '.F.' IT_DEL "
		// servicos do pacote
		_cQryDet += "FROM "+RetSqlName("SZO")+" SZO "
		// cad. de produto
		_cQryDet += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND ZO_PRODUTO = B1_COD "
		// filtro dos servicos do contrato e item
		_cQryDet += "WHERE "+RetSqlCond("SZO")+" "
		// filtra numero do pacote
		_cQryDet += "AND ZO_PACOTE = '"+(_TRBGERAL)->IT_PACOTE+"' "
		// nao apresenta o produto PACOTE LOGISTICO, pois vai incluir automatico logo abaixo
		_cQryDet += "AND ZO_PRODUTO != '"+(_TRBGERAL)->IT_CODPROD+"' "
		// ordem dos dados
		_cQryDet += "ORDER BY ZO_PRODUTO"
		// se o item nao estiver faturadom busca os itens do pacote logistico do contrato - SZU
	ElseIf (!_lItemFat)
		_cQryDet := "SELECT ZU_PRODUTO, B1_DESC, '.F.' IT_DEL "
		// servicos do pacote
		_cQryDet += "FROM "+RetSqlName("SZU")+" SZU "
		// cad. de produto
		_cQryDet += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND ZU_PRODUTO = B1_COD "
		// filtro dos servicos do contrato e item
		_cQryDet += "WHERE "+RetSqlCond("SZU")+" "
		_cQryDet += "AND ZU_CONTRT = '"+(_TRBGERAL)->IT_CONTRAT+"' AND ZU_ITCONTR = '"+(_TRBGERAL)->IT_ITCONTR+"' "
		// ordem dos dados
		_cQryDet += "ORDER BY ZU_PRODUTO"
	EndIf

	// alimenta o acols com o resultado do SQL
	_aColsPac := U_SqlToVet(_cQryDet)

	// inclui o servico principal do pacote
	aAdd(_aColsPac,{(_TRBGERAL)->IT_CODPROD,(_TRBGERAL)->IT_DESPROD,.F.})


	// monta a tela com os dados de todos os servicos do pacote logitico
	_oDlgPacLog := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Detalhes do Pacote Logístico",,,.F.,,,,,,.T.,,,.T. )
	_oDlgPacLog:lMaximized := .T.
	// cria o panel com os botoes
	_oPnlPacLogBtn := TPanel():New(000,000,nil,_oDlgPacLog,,.F.,.F.,,,030,030,.T.,.F. )
	_oPnlPacLogBtn:Align:= CONTROL_ALIGN_TOP
	// botao para confirmar
	_oBtnPacLogFechar := TButton():New(005,005,"Fechar",_oPnlPacLogBtn,{||_oDlgPacLog:End()},045,012,,_oFnt01,,.T.,,"",,,,.F. )

	// cria o panel para o browse 1
	_oPnlPacLogServ := TPanel():New(000,000,nil,_oDlgPacLog,,.F.,.F.,,,080,080,.T.,.F. )
	_oPnlPacLogServ:Align:= CONTROL_ALIGN_TOP
	// browse com os dados do servicos que compoe o pacote logistico
	_oBrwPacLogSrv := MsNewGetDados():New(000,000,1000,1000,Nil,'AllwaysTrue()','AllwaysTrue()','',,,99,'AllwaysTrue()','','AllwaysTrue()',_oPnlPacLogServ,_aHeadPac,_aColsPac,{|| sfDetSrvPcte( _oBrwPacLogSrv:aCols[_oBrwPacLogSrv:nAt,1] ,@_aHeadSrv,@_aColsSrv ) })
	_oBrwPacLogSrv:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// cria o panel para o browse 2
	_oPnlPacLogSubTit := TPanel():New(000,000,nil,_oDlgPacLog,,.F.,.F.,,,020,020,.T.,.F. )
	_oPnlPacLogSubTit:Align:= CONTROL_ALIGN_TOP
	// sub-titulo
	_oSayPacLogTit1  := TSay():New(009,012,{||"Detalhes do Serviço ..."},_oPnlPacLogSubTit,,_oFnt01,.F.,.F.,.F.,.T.,CLR_GREEN)

	// apresenta botao para visualizar OS
	_oBtnVisOS := TButton():New(005,150,"Visualiza O.S.",_oPnlPacLogSubTit,{|| sfVisualOS(_aHeadSrv,_oBrwDetSrvPcte) },055,012,,,,.T.,,"",,,,.F. )
	// apresenta botao para visualizar Mov Carga
	_oBtnVisMovCarga := TButton():New(005,210,"Visualiza Mov. Carga",_oPnlPacLogSubTit,{|| sfVisMovCarga(_aHeadSrv,_oBrwDetSrvPcte) },055,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela
	_oDlgPacLog:Activate(,,,.T.,)

Return(.t.)


// ** busca todos os dados detalhados dos servicos diversos
Static Function sfDetServico(mvResumo,mvHeader,mvPacteLog,mvFatura)
	// variaveis temporarias
	local _cQuery
	// variavel de retorno para informacoes detalhadas
	local _aRet := {}

	// valores padroes dos parametros
	Default mvHeader := {}
	Default mvPacteLog := .f.
	Default mvFatura := .f.


	// busca as movimentacoes
	_cQuery := "SELECT "

	// informacoes resumidas para o browse principal
	If (mvResumo)
		_cQuery += "' ' IT_OK, ZL_PROCES IT_PROCESS, ZL_ITPROC IT_ITPROCE, ZL_CLIENTE IT_CODCLIE, ZL_LOJA IT_LOJCLIE, A1_NOME IT_NOMCLIE, "
		_cQuery += "ZL_PRODUTO IT_CODPROD, ISNULL(ZR_DESCRI,ISNULL(AAN_ZDESCR,'<< SERVICOS DIVERSOS >>')) IT_DESPROD, "
		_cQuery += "1 AAN_QUANT, "
		_cQuery += "SUM( CASE WHEN ZL_FATURAR = 'S' THEN ZL_TOTAL ELSE 0 END ) AAN_VLRUNI, "
		_cQuery += "SUM( CASE WHEN ZL_FATURAR = 'S' THEN ZL_TOTAL ELSE 0 END ) AAN_VALOR, "
		_cQuery += "ZL_PEDIDO IT_NUMPED, ZL_ITEMPED IT_ITEMPED, ZL_CONTRT IT_CONTRAT, ZL_ITCONTR IT_ITCONTR, ISNULL(B1_TIPOSRV,'7') IT_TIPOSRV, ' ' IT_ULTDATA "
		// informacoes detalhadas
	ElseIf (!mvResumo)
		_cQuery += "ZL_FATURAR, ZL_CODATIV, ZT_DESCRIC, ZL_UNIDCOB, ZL_QUANT, ZL_VLRUNIT, ZL_TOTAL, ZL_CONTAIN, ZL_DTINIOS, ZL_TIPOMOV, ZL_TPOPER, "
		_cQuery += "ZL_NUMOS, "
		_cQuery += "CONVERT(VarChar(8000), CONVERT(VarBinary(8000), ZL_OBS)) ZL_OBS, "
		_cQuery += "CONVERT(VarChar(8000), CONVERT(VarBinary(8000), ZL_OBSITEM)) ZL_OBSITEM, "
		_cQuery += "CONVERT(VarChar(8000), CONVERT(VarBinary(8000), ZL_OBSFAT)) ZL_OBSFAT, "
		_cQuery += "ZL_CUBAGEM, "
		_cQuery += "ZL_PESOBRU, "
		_cQuery += "SZL.R_E_C_N_O_ SZLRECNO, '.F.' IT_DEL "
	EndIf

	// ordens de servico
	_cQuery += "FROM "+RetSqlName("SZL")+" SZL "

	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	If (mvStsProc != 3) // 3-ambos
		// cad. processo
		_cQuery += "INNER JOIN "+RetSqlName("SZ1")+" SZ1 ON "+RetSqlCond("SZ1")+" AND Z1_CODIGO = ZL_PROCES "
		// filtro do status
		If (mvStsProc==1) // aberto
			_cQuery += "AND Z1_DTFINFA  = ' ' "
		ElseIf (mvStsProc==2) // encerrado
			_cQuery += "AND Z1_DTFINFA != ' ' "
		EndIf
	EndIf

	// informacoes para o resumo
	If (mvResumo)
		// cad. clientes
		_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 ON "+RetSqlCond("SA1")+" AND A1_COD = ZL_CLIENTE AND A1_LOJA = ZL_LOJA "
		// cad. produtos
		_cQuery += "LEFT  JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND B1_COD = ZL_PRODUTO "
		// itens do contrato
		_cQuery += "LEFT  JOIN "+RetSqlName("AAN")+" AAN ON "+RetSqlCond("AAN")+" AND AAN_CONTRT = ZL_CONTRT AND AAN_ITEM = ZL_ITCONTR "
		// resumo do faturamento
		_cQuery += "LEFT  JOIN "+RetSqlName("SZR")+" SZR ON "+RetSqlCond("SZR")+" AND ZR_PROGRAM = ZL_PROCES AND ZR_ITEPROG = ZL_ITPROC "
		_cQuery += "      AND ZR_CONTRT  = ZL_CONTRT  AND ZR_ITEM   = ZL_ITCONTR "
		_cQuery += "      AND ZR_CODCLI  = ZL_CLIENTE AND ZR_LOJCLI = ZL_LOJA "
		_cQuery += "      AND ZR_PEDIDO  = ZL_PEDIDO AND ZR_ITEPEDI = ZL_ITEMPED "
		_cQuery += "      AND ZR_CODSRV  = ZL_PRODUTO "
	ElseIf (!mvResumo)
		// cad. de atividades
		_cQuery += "INNER JOIN "+RetSqlName("SZT")+" SZT ON "+RetSqlCond("SZT")+" AND ZT_CODIGO = ZL_CODATIV "
	EndIf

	// filtro dos dados
	_cQuery += "WHERE "+RetSqlCond("SZL")+" "
	// filtro padrao
	_cQuery += "AND ZL_PROCES  BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' "
	_cQuery += "AND ZL_CONTRT  BETWEEN '"+mvContDe+"' AND '"+mvContAte+"' "
	_cQuery += "AND ZL_CLIENTE BETWEEN '"+mvClieDe+"' AND '"+mvClieAte+"' "
	// filtro por ID de processo
	_cQuery += "AND ("
	// filtro de processo atual
	_cQuery += "     (ZL_DTPROCE = '"+DtoS(_dDataBase)+"' "
	_cQuery += "      AND ZL_USRPROC = '"+__cUserId+"' "
	_cQuery += "      AND ZL_IDPROCE = '"+_cIdProc+"' "
	_cQuery += "      AND ZL_STATUS = ' ') "
	// filtro para mostrar faturados/cancelados anteriormente
	If (mvMostraFat)
		_cQuery += " OR (ZL_IDPROCE = ' ' AND ZL_STATUS IN ('C','F')) "
	EndIf
	_cQuery += "    ) "

	//_cQuery += "AND ZL_FATURAR = 'S' "

	// filtro especifico das informacoes detalhadas
	If (!mvResumo)
		_cQuery += "AND ZL_PROCES  = '"+(_TRBGERAL)->IT_PROCESS+"' "
		_cQuery += "AND ZL_ITPROC  = '"+(_TRBGERAL)->IT_ITPROCE+"' "
		_cQuery += "AND ZL_CONTRT  = '"+(_TRBGERAL)->IT_CONTRAT+"' "
		_cQuery += "AND ZL_ITCONTR = '"+(_TRBGERAL)->IT_ITCONTR+"' "
		// se for faturamento filtra pelo pedido de venda em branco
		If (mvFatura)
			_cQuery += "AND ZL_PEDIDO  = ' ' "
		ElseIf (!mvFatura)
			_cQuery += "AND ZL_PEDIDO  = '"+(_TRBGERAL)->IT_NUMPED+"' "
			_cQuery += "AND ZL_ITEMPED = '"+(_TRBGERAL)->IT_ITEMPED+"' "
		EndIf
	EndIf

	// controle de pacote logistico
	If (mvPacteLog)
		_cQuery += "AND ZL_PACOTE = '"+(_TRBGERAL)->IT_PACOTE+"' "
		// no faturamento, quando baixa de OS, filtrar pela sequencia do pacote
		If (mvFatura)
			_cQuery += "AND ZL_SEQPACO = '"+SZJ->ZJ_SEQPACO+"' "
		EndIf
	Else
		_cQuery += "AND ZL_PACOTE = ' ' "
	EndIf

	// informacoes resumidas
	If (mvResumo)
		// agrupamento de dados
		_cQuery += "GROUP BY ZL_PROCES, ZL_ITPROC, ZL_CLIENTE, ZL_LOJA, A1_NOME, ZL_PRODUTO, ISNULL(ZR_DESCRI,ISNULL(AAN_ZDESCR,'<< SERVICOS DIVERSOS >>')), ZL_PEDIDO, ZL_ITEMPED, ZL_CONTRT, ZL_ITCONTR, B1_TIPOSRV "
		// adiciona o conteudo da query para o arquivo de trabalho
		U_SqlToTrb(_cQuery,_aStrTrbFat,_TRBGERAL)
		// informacoes detalhadas
	ElseIf (!mvResumo)
		// adiciona o conteudo da query para um array
		_aRet := U_SqlToVet(_cQuery,{"ZL_DTINIOS"})
	EndIf

	memowrit("c:\query\sfDetServico.txt",_cQuery)

	// se for dados detalhados, atualiza o header recebido como parametro
	If (!mvResumo).and.(!mvFatura)
		// zera o header
		mvHeader := {}

		// define todos os campos do header
		//aAdd(mvHeader,{"Faturar"      , "ZL_FATURAR", PesqPict("SZL","ZL_FATURAR"), TamSx3("ZL_FATURAR")[1], 0,IIf(_lEdita,"U_FATA0027()",""),Nil,"C",Nil,"R",,,IIf(_lEdita,".T.",".F.") })
		aAdd(mvHeader,{"Faturar"      , "ZL_FATURAR", PesqPict("SZL","ZL_FATURAR"), TamSx3("ZL_FATURAR")[1], 0,IIf(_lEdita,"U_FATA0024()",""),Nil,"C",Nil,"R",,,IIf(_lEdita,".T.",".F.") })
		aAdd(mvHeader,{"Cod.Atv."     , "ZL_CODATIV", PesqPict("SZL","ZL_CODATIV"), TamSx3("ZL_CODATIV")[1], 0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Desc.Atv."    , "ZT_DESCRIC", PesqPict("SZT","ZT_DESCRIC"), 20, 0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Unid Cobrança", "ZL_UNIDCOB", PesqPict("SZL","ZL_UNIDCOB"), TamSx3("ZL_UNIDCOB")[1], 0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Qtde"         , "ZL_QUANT"  , PesqPict("SZL","ZL_QUANT")  , TamSx3("ZL_QUANT")[1], TamSx3("ZL_QUANT")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Tarifa"       , "ZL_VLRUNIT", PesqPict("SZL","ZL_VLRUNIT"), TamSx3("ZL_VLRUNIT")[1], TamSx3("ZL_VLRUNIT")[2],Nil,Nil,"N",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Total"        , "ZL_TOTAL"  , PesqPict("SZL","ZL_TOTAL")  , TamSx3("ZL_TOTAL")[1], TamSx3("ZL_TOTAL")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Container"    , "ZL_CONTAIN", PesqPict("SZL","ZL_CONTAIN"), TamSx3("ZL_CONTAIN")[1], 0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Data"         , "ZL_DTINIOS", PesqPict("SZL","ZL_DTINIOS"), TamSx3("ZL_DTINIOS")[1], 0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Movimento"    , "ZL_TIPOMOV", PesqPict("SZL","ZL_TIPOMOV"), TamSx3("ZL_TIPOMOV")[1], 0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Operação"     , "ZL_TPOPER" , PesqPict("SZL","ZL_TPOPER") , TamSx3("ZL_TPOPER")[1], 0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(mvHeader,{"O.S."         , "ZL_NUMOS"  , PesqPict("SZL","ZL_NUMOS")  , TamSx3("ZL_NUMOS")[1], 0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Obs da OS"    , "ZL_OBS"    , ""                          , TamSx3("ZL_OBS")[1], 0,Nil,Nil,"M",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Obs Item OS"  , "ZL_OBSITEM", ""                          , TamSx3("ZL_OBSITEM")[1], 0,Nil,Nil,"M",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Obs Faturam." , "ZL_OBSFAT" , ""                          , TamSx3("ZL_OBSFAT")[1] , 0,Nil,Nil,"M",Nil,"R",,,IIf(_lEdita,".T.",".F.")  })
		aAdd(mvHeader,{"Cubagem"      , "ZL_CUBAGEM", PesqPict("SZL","ZL_CUBAGEM"), TamSx3("ZL_CUBAGEM")[1] , 0,Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Peso Bruto"   , "ZL_PESOBRU", PesqPict("SZL","ZL_PESOBRU"), TamSx3("ZL_PESOBRU")[1] , 0,Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Recno"        , "SZLRECNO"  , ""                          , 10 , 0,Nil,Nil,"N",Nil,"R",,,".F." })

		// ordem dos dados de retorno (posicao 2-Cod Atividade)
		aSort(_aRet,,,{|x,y| x[2] < y[2] })
	EndIf

Return(If(mvResumo,.t.,_aRet))


// ** busca todos os dados detalhados dos fretes (transferencia interna)
Static Function sfDetFrete(mvResumo,mvHeader,mvPacteLog,mvFatura)
	// variaveis temporarias
	local _cQuery
	// variavel de retorno para informacoes detalhadas
	local _aRet := {}

	// valores padroes dos parametros
	Default mvHeader := {}
	Default mvPacteLog := .f.
	Default mvFatura := .f.

	// busca as movimentacoes
	_cQuery := "SELECT "

	// informacoes resumidas para o browse principal
	If (mvResumo)
		_cQuery += "' ' IT_OK, ZK_PROCES IT_PROCESS, ZK_ITPROC IT_ITPROCE, ZK_CLIENTE IT_CODCLIE, ZK_LOJA IT_LOJCLIE, A1_NOME IT_NOMCLIE, "
		_cQuery += "ZK_PRODUTO IT_CODPROD, ISNULL(ZR_DESCRI,ISNULL(AAN_ZDESCR,'<< FRETES >>')) IT_DESPROD, 1 AAN_QUANT, SUM(ZK_VALOR) AAN_VLRUNI, SUM(ZK_VALOR) AAN_VALOR, "
		_cQuery += "ZK_PEDIDO IT_NUMPED, ZK_ITEMPED IT_ITEMPED, ZK_CONTRT IT_CONTRAT, ZK_ITCONTR IT_ITCONTR, ISNULL(B1_TIPOSRV,'4') IT_TIPOSRV, ' ' IT_ULTDATA "
		// informacoes detalhadas
	ElseIf (!mvResumo)
		_cQuery += "ZK_FATURAR, 1 ZK_QUANT, ZK_VALOR AAN_VLRUNI, ZK_VALOR, ZK_DTMOVIM, ZK_TPMOVIM, ZK_RIC, ZK_CONTAIN, ZK_TAMCONT, ZK_CONTEUD, "
		_cQuery += "SZBORIG.ZB_DESCRI IT_PRCORIG, SZBDEST.ZB_DESCRI IT_PRCDEST, "
		_cQuery += "A4_NREDUZ, CONVERT(VarChar(8000), CONVERT(VarBinary(8000), ZK_OBSFAT)) ZK_OBSFAT, SZK.R_E_C_N_O_ SZKRECNO, '.F.' IT_DEL "
	EndIf

	// ordens de servico
	_cQuery += "FROM "+RetSqlName("SZK")+" SZK "

	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	If (mvStsProc != 3) // 3-ambos
		// cad. processo
		_cQuery += "INNER JOIN "+RetSqlName("SZ1")+" SZ1 ON "+RetSqlCond("SZ1")+" AND Z1_CODIGO = ZK_PROCES "
		// filtro do status
		If (mvStsProc==1) // aberto
			_cQuery += "AND Z1_DTFINFA  = ' ' "
		ElseIf (mvStsProc==2) // encerrado
			_cQuery += "AND Z1_DTFINFA != ' ' "
		EndIf
	EndIf

	// informacoes para o resumo
	If (mvResumo)
		// cad. clientes
		_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 ON "+RetSqlCond("SA1")+" AND A1_COD = ZK_CLIENTE AND A1_LOJA = ZK_LOJA "
		// cad. produtos
		_cQuery += "LEFT  JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND B1_COD = ZK_PRODUTO "
		// itens do contrato
		_cQuery += "LEFT  JOIN "+RetSqlName("AAN")+" AAN ON "+RetSqlCond("AAN")+" AND AAN_CONTRT = ZK_CONTRT AND AAN_ITEM = ZK_ITCONTR "
		// resumo do faturamento
		_cQuery += "LEFT  JOIN "+RetSqlName("SZR")+" SZR ON "+RetSqlCond("SZR")+" AND ZR_PROGRAM = ZK_PROCES AND ZR_ITEPROG = ZK_ITPROC "
		_cQuery += "      AND ZR_CONTRT  = ZK_CONTRT  AND ZR_ITEM    = ZK_ITCONTR "
		_cQuery += "      AND ZR_CODCLI  = ZK_CLIENTE AND ZR_LOJCLI  = ZK_LOJA "
		_cQuery += "      AND ZR_PEDIDO  = ZK_PEDIDO  AND ZR_ITEPEDI = ZK_ITEMPED "
		_cQuery += "      AND ZR_CODSRV  = ZK_PRODUTO "
	ElseIf (!mvResumo)
		// cad. de pracas
		_cQuery += "LEFT JOIN "+RetSqlName("SZB")+" SZBORIG ON SZBORIG.ZB_FILIAL = '"+xFilial("SZB")+"' AND SZBORIG.D_E_L_E_T_ = ' ' AND SZBORIG.ZB_CODIGO = ZK_PRCORIG "
		_cQuery += "LEFT JOIN "+RetSqlName("SZB")+" SZBDEST ON SZBDEST.ZB_FILIAL = '"+xFilial("SZB")+"' AND SZBDEST.D_E_L_E_T_ = ' ' AND SZBDEST.ZB_CODIGO = ZK_PRCDEST "
		// cad. transportadora
		_cQuery += "LEFT JOIN "+RetSqlName("SA4")+" SA4 ON "+RetSqlCond("SA4")+" AND A4_COD = ZK_TRANSP "
	EndIf

	// filtro dos dados
	_cQuery += "WHERE "+RetSqlCond("SZK")+" "

	// filtro padrao
	_cQuery += "AND ZK_PROCES  BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' "
	_cQuery += "AND ZK_CONTRT  BETWEEN '"+mvContDe+"' AND '"+mvContAte+"' "
	_cQuery += "AND ZK_CLIENTE BETWEEN '"+mvClieDe+"' AND '"+mvClieAte+"' "
	// filtro por ID de processo
	_cQuery += "AND ("
	// filtro de processo atual
	_cQuery += "     (ZK_DTPROCE = '"+DtoS(_dDataBase)+"' "
	_cQuery += "      AND ZK_USRPROC = '"+__cUserId+"' "
	_cQuery += "      AND ZK_IDPROCE = '"+_cIdProc+"' "
	_cQuery += "      AND ZK_STATUS = ' ') "
	// filtro para mostrar faturados/cancelados anteriormente
	If (mvMostraFat)
		_cQuery += " OR (ZK_IDPROCE = ' ' AND ZK_STATUS IN ('C','F')) "
	EndIf
	_cQuery += "    ) "

	//_cQuery += "AND ZK_FATURAR = 'S' "

	// filtro especifico das informacoes detalhadas
	If (!mvResumo)
		_cQuery += "AND ZK_PROCES  = '"+(_TRBGERAL)->IT_PROCESS+"' "
		_cQuery += "AND ZK_ITPROC  = '"+(_TRBGERAL)->IT_ITPROCE+"' "
		_cQuery += "AND ZK_CONTRT  = '"+(_TRBGERAL)->IT_CONTRAT+"' "
		_cQuery += "AND ZK_ITCONTR = '"+(_TRBGERAL)->IT_ITCONTR+"' "
		// se for faturamento filtra pelo pedido de venda em branco
		If (mvFatura)
			_cQuery += "AND ZK_PEDIDO  = ' ' "
		ElseIf (!mvFatura)
			_cQuery += "AND ZK_PEDIDO  = '"+(_TRBGERAL)->IT_NUMPED+"' "
			_cQuery += "AND ZK_ITEMPED = '"+(_TRBGERAL)->IT_ITEMPED+"' "
		EndIf
	EndIf

	// controle de pacote logistico
	If (mvPacteLog)
		_cQuery += "AND ZK_PACOTE = '"+(_TRBGERAL)->IT_PACOTE+"' "
		// no faturamento, quando baixa de frete, filtrar pela sequencia do pacote
		If (mvFatura)
			_cQuery += "AND ZK_SEQPACO = '"+SZJ->ZJ_SEQPACO+"' "
		EndIf
	Else
		_cQuery += "AND ZK_PACOTE = ' ' "
	EndIf

	// informacoes resumidas
	If (mvResumo)
		// agrupamento de dados
		_cQuery += "GROUP BY ZK_PROCES, ZK_ITPROC, ZK_CLIENTE, ZK_LOJA, A1_NOME, ZK_PRODUTO, ISNULL(ZR_DESCRI,ISNULL(AAN_ZDESCR,'<< FRETES >>')), ZK_PEDIDO, ZK_ITEMPED, ZK_CONTRT, ZK_ITCONTR, B1_TIPOSRV "
		// adiciona o conteudo da query para o arquivo de trabalho
		U_SqlToTrb(_cQuery,_aStrTrbFat,_TRBGERAL)
		// informacoes detalhadas
	ElseIf (!mvResumo)
		// adiciona o conteudo da query para um array
		_aRet := U_SqlToVet(_cQuery,{"ZK_DTMOVIM"})
	EndIf

	memowrit("c:\query\sfDetFrete.txt",_cQuery)

	// se for dados detalhados, atualiza o header recebido como parametro
	If (!mvResumo).and.(!mvFatura)
		// zera o header
		mvHeader := {}

		// define todos os campos do header
		aAdd(mvHeader,{"Faturar"       , "ZK_FATURAR", PesqPict("SZK","ZK_FATURAR"), TamSx3("ZK_FATURAR")[1], 0,IIf(_lEdita,"U_FATA0024()",""),Nil,"C",Nil,"R",,,IIf(_lEdita,".T.",".F.") })
		aAdd(mvHeader,{"Qtde"          , "ZK_QUANT"  , PesqPict("SZL","ZL_QUANT")  , TamSx3("ZL_QUANT")[1]  , TamSx3("ZL_QUANT")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Tarifa"        , "ZK_VLRUNIT", PesqPict("SZK","ZK_VALOR")  , TamSx3("ZK_VALOR")[1]  , TamSx3("ZK_VALOR")[2],Nil,Nil,"N",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Total"         , "ZK_VALOR"  , PesqPict("SZK","ZK_VALOR")  , TamSx3("ZK_VALOR")[1]  , TamSx3("ZK_VALOR")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Data"          , "ZK_DTMOVIM", ""                          , TamSx3("ZK_DTMOVIM")[1], 0,Nil,Nil,"D",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Tipo"          , "ZK_TPMOVIM", ""                          , TamSx3("ZK_TPMOVIM")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"RIC"           , "ZK_RIC"    , PesqPict("SZK","ZK_RIC")    , TamSx3("ZK_RIC")[1]    , 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Container"     , "ZK_CONTAIN", PesqPict("SZK","ZK_CONTAIN"), TamSx3("ZK_CONTAIN")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Tamanho"       , "ZK_TAMCONT", PesqPict("SZK","ZK_TAMCONT"), TamSx3("ZK_TAMCONT")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Conteudo"      , "ZK_CONTEUD", PesqPict("SZK","ZK_CONTEUD"), TamSx3("ZK_CONTEUD")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Praça Orig."   , "ZB_DESCRI" , PesqPict("SZB","ZB_DESCRI") , TamSx3("ZB_DESCRI")[1] , 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Praça Dest."   , "ZB_DESCRI" , PesqPict("SZB","ZB_DESCRI") , TamSx3("ZB_DESCRI")[1] , 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Transportadora", "A4_NREDUZ" , PesqPict("SA4","A4_NREDUZ") , TamSx3("A4_NREDUZ")[1] , 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Obs Faturam."  , "ZK_OBSFAT" , ""                          , TamSx3("ZK_OBSFAT")[1] , 0,Nil,Nil,"M",Nil,"R",,,IIf(_lEdita,".T.",".F.")  })
		aAdd(mvHeader,{"Recno"         , "SZKRECNO"  , ""                          , 10 , 0,Nil,Nil,"N",Nil,"R",,,".F." })

		// ordem dos dados de retorno (posicao 8-container e 6-Tipo Movimento)
		aSort(_aRet,,,{|x,y| x[8]+x[6] < y[8]+y[6] })
	EndIf

Return(If(mvResumo,.t.,_aRet))


// ** busca todos os dados detalhados dos valores fixos (alugueis)
Static Function sfDetFixo(mvResumo,mvHeader,mvPacteLog,mvFatura)
	// variaveis temporarias
	local _cQuery
	// variavel de retorno para informacoes detalhadas
	local _aRet := {}

	// valores padroes dos parametros
	Default mvHeader := {}
	Default mvPacteLog := .f.
	Default mvFatura := .f.

	// busca as movimentacoes
	_cQuery := "SELECT "

	// informacoes resumidas para o browse principal
	If (mvResumo)
		_cQuery += "' ' IT_OK, ' ' IT_PROCESS, ' ' IT_ITPROCE, ZM_CLIENTE IT_CODCLIE, ZM_LOJA IT_LOJCLIE, A1_NOME IT_NOMCLIE, "
		_cQuery += "ZM_PRODUTO IT_CODPROD, ISNULL(AAN_ZDESCR,'<< VALORES FIXOS / ALUGUEIS >>') IT_DESPROD, 1 AAN_QUANT, SUM(ZM_VALOR) AAN_VLRUNI, SUM(ZM_VALOR) AAN_VALOR, "
		_cQuery += "ZM_PEDIDO IT_NUMPED, ZM_ITEMPED IT_ITEMPED, ZM_CONTRT IT_CONTRAT, ZM_ITCONTR IT_ITCONTR, ISNULL(B1_TIPOSRV,'4') IT_TIPOSRV, "
		// busca a ultima data de faturamento
		_cQuery += "' ' IT_ULTDATA "
		// informacoes detalhadas
	ElseIf (!mvResumo)
		_cQuery += "ZM_FATURAR, ZM_VALOR, ZM_DSCPROD, ZM_DTINI, ZM_DTFIM, "
		_cQuery += "CONVERT(VarChar(8000), CONVERT(VarBinary(8000), ZM_OBSFAT)) ZM_OBSFAT, "
		_cQuery += "SZM.R_E_C_N_O_ SZMRECNO, '.F.' IT_DEL "
	EndIf

	// valores fixos / alugueis
	_cQuery += "FROM "+RetSqlName("SZM")+" SZM "

	// informacoes para o resumo
	If (mvResumo)
		// cad. clientes
		_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 ON "+RetSqlCond("SA1")+" AND A1_COD = ZM_CLIENTE AND A1_LOJA = ZM_LOJA "
		// cad. produtos
		_cQuery += "LEFT  JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND B1_COD = ZM_PRODUTO "
		// itens do contrato
		_cQuery += "LEFT  JOIN "+RetSqlName("AAN")+" AAN ON "+RetSqlCond("AAN")+" AND AAN_CONTRT = ZM_CONTRT AND AAN_ITEM = ZM_ITCONTR "
	EndIf

	// filtro dos dados
	_cQuery += "WHERE "+RetSqlCond("SZM")+" "

	// filtro padrao
	_cQuery += "AND ZM_CONTRT  BETWEEN '"+mvContDe+"' AND '"+mvContAte+"' "
	_cQuery += "AND ZM_CLIENTE BETWEEN '"+mvClieDe+"' AND '"+mvClieAte+"' "
	// filtro por ID de processo
	_cQuery += "AND ("
	// filtro de processo atual
	_cQuery += "     (ZM_DTPROCE = '"+DtoS(_dDataBase)+"' "
	_cQuery += "      AND ZM_USRPROC = '"+__cUserId+"' "
	_cQuery += "      AND ZM_IDPROCE = '"+_cIdProc+"' "
	_cQuery += "      AND ZM_STATUS = ' ') "
	// filtro para mostrar faturados/cancelados anteriormente
	If (mvMostraFat)
		_cQuery += " OR (ZM_IDPROCE = ' ' AND ZM_STATUS IN ('C','F')) "
	EndIf
	_cQuery += "    ) "

	// filtro especifico das informacoes detalhadas
	If (!mvResumo)
		_cQuery += "AND ZM_CONTRT  = '"+(_TRBGERAL)->IT_CONTRAT+"' "
		_cQuery += "AND ZM_ITCONTR = '"+(_TRBGERAL)->IT_ITCONTR+"' "
		// se for faturamento filtra pelo pedido de venda em branco
		If (mvFatura)
			_cQuery += "AND ZM_PEDIDO  = ' ' "
		ElseIf (!mvFatura)
			_cQuery += "AND ZM_PEDIDO  = '"+(_TRBGERAL)->IT_NUMPED+"' "
			_cQuery += "AND ZM_ITEMPED = '"+(_TRBGERAL)->IT_ITEMPED+"' "
		EndIf
	EndIf

	// informacoes resumidas
	If (mvResumo)
		// agrupamento de dados
		_cQuery += "GROUP BY ZM_CLIENTE, ZM_LOJA, A1_NOME, ZM_PRODUTO, AAN_ZDESCR, ZM_PEDIDO, ZM_ITEMPED, ZM_CONTRT, ZM_ITCONTR, B1_TIPOSRV "
		// adiciona o conteudo da query para o arquivo de trabalho
		U_SqlToTrb(_cQuery,_aStrTrbFat,_TRBGERAL)
		// informacoes detalhadas
	ElseIf (!mvResumo)
		// adiciona o conteudo da query para um array
		_aRet := U_SqlToVet(_cQuery,{"ZM_DTINI","ZM_DTFIM"})
	EndIf

	memowrit("c:\query\sfDetFixo.txt",_cQuery)

	// se for dados detalhados, atualiza o header recebido como parametro
	If (!mvResumo).and.(!mvFatura)
		// zera o header
		mvHeader := {}

		// define todos os campos do header
		aAdd(mvHeader,{"Faturar"       , "ZM_FATURAR", PesqPict("SZM","ZM_FATURAR"), TamSx3("ZM_FATURAR")[1], 0,IIf(_lEdita,"U_FATA0024()",""),Nil,"C",Nil,"R",,,IIf(_lEdita,".T.",".F.") })
		aAdd(mvHeader,{"Total"         , "ZM_VALOR"  , PesqPict("SZM","ZM_VALOR")  , TamSx3("ZM_VALOR")[1]  , TamSx3("ZM_VALOR")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(mvHeader,{"Descrição"     , "ZM_DSCPROD", PesqPict("SZM","ZM_DSCPROD"), TamSx3("ZM_DSCPROD")[1], 0,Nil,Nil,"C",Nil,"R",,,IIf(_lEdita,".T.",".F.") })
		aAdd(mvHeader,{"Data Inicial"  , "ZM_DTINI"  , ""                          , TamSx3("ZM_DTINI")[1]  , 0,Nil,Nil,"D",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Data Final"    , "ZM_DTFIM"  , ""                          , TamSx3("ZM_DTFIM")[1]  , 0,Nil,Nil,"D",Nil,"R",,,".F."  })
		aAdd(mvHeader,{"Obs Faturam."  , "ZM_OBSFAT" , ""                          , TamSx3("ZM_OBSFAT")[1] , 0,Nil,Nil,"M",Nil,"R",,,IIf(_lEdita,".T.",".F.")  })
		aAdd(mvHeader,{"Recno"         , "SZMRECNO"  , ""                          , 10 , 0,Nil,Nil,"N",Nil,"R",,,".F." })

		// ordem dos dados de retorno (posicao 4-Data Inicial)
		aSort(_aRet,,,{|x,y| x[4] < y[4] })
	EndIf

Return(If(mvResumo,.t.,_aRet))

// ** funcao que detalha o item selecionado
User Function FATA002T()
	// dimensoes da tela
	local _aSizeDlg := MsAdvSize()

	// campos utilizados
	local _aHeadDet 	:= {}
	local _aColsDet 	:= {}

	// objetos da tela
	local _oBtnVisNFE, _oBtnDetItm
	local _oGetDscProd
	local _oSayDscProd

	// controle das informacoes do browse
	private _cTpSrv	:= (_TRBGERAL)->IT_TIPOSRV
	private _lEdita	:= Empty((_TRBGERAL)->IT_NUMPED).and.(_cTpSrv <> "3")// pacote logistico
	// controle para gravar os dados
	private _lDadosOk := .f.

	// somente visualizacao (historico)
	private _lVisDetalhe := !Empty((_TRBGERAL)->IT_NUMPED)

	// descricao do item pro pedido de venda
	private _cDscProduto := (_TRBGERAL)->IT_DESPROD

	Private cTpArmaz := ""
	Private nPeriod  := 0

	Private _aHeadPrd := {}
	Private _aColsPrd := {}
	Private _oFntRoda := TFont():New("Tahoma",,16,,.t.)

	// atualiza o vetor com os detalhes de cada servico
	Do Case
		// ARMAZENAGEM DE CONTAINER
		Case (_cTpSrv == "1")
		// chama funcao para detalhes
		_aColsDet := sfDetArmCnt(.f., @_aHeadDet, .f., .f.)

		// ARMAZENAGEM DE PRODUTOS
		Case (_cTpSrv == "2")
		// chama funcao para detalhes
		_aColsDet := sfDetArmPrd(.f., @_aHeadDet, .f., .f.)

		// 3-PACOTE LOGISTICO, A-PACOTE LOGISTICO EXPORTACAO, B-PACOTE DE SERVICOS
		Case (_cTpSrv $ "3/A/B")
		// chama funcao para detalhes do pacote logistico
		sfDetPacLog()
		Return(.t.)

		// FRETES
		Case (_cTpSrv == "4")
		// chama funcao para detalhes
		_aColsDet := sfDetFrete(.f.,@_aHeadDet,.f.,.f.)

		// SEGUROS
		Case (_cTpSrv == "5")
		// chama funcao para detalhes
		_aColsDet := sfDetSeguro(.f.,@_aHeadDet,.f.,.f.)

		// SERVICOS DIVERSOS
		Case (_cTpSrv == "7")
		// chama funcao para detalhes
		_aColsDet := sfDetServico(.f.,@_aHeadDet,.f.,.f.)

		// VALORES FIXOS / ALUGUEIS
		Case (_cTpSrv == "8")
		// chama funcao para detalhes
		_aColsDet := sfDetFixo(.f.,@_aHeadDet,.f.,.f.)

	EndCase

	// verifica se existem movimentos para este servico
	If (Len(_aColsDet) == 0)
		Alert("Não existem movimentos para este serviço !!")
		Return (.t.)
	EndIf

	// definicao da tela
	_oDlgDetalhes := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Movimentos - "+AllTrim((_TRBGERAL)->IT_DESPROD),,,.F.,,,,,,.T.,,,.T. )
	_oDlgDetalhes:lMaximized := .T.

	// cria o panel do cabecalho - botoes
	_oPnlCabec1 := TPanel():New(000,000,nil,_oDlgDetalhes,,.F.,.F.,,,000,030,.T.,.F. )
	_oPnlCabec1:Align:= CONTROL_ALIGN_TOP

	// se for 2-ARM PRODUTOS / 5-SEGUROS inclui opcao para visualizar a nota
	If (_cTpSrv $ "2|5")
		_oBtnVisNFE := TButton():New(010,015,"Visualiza NF"  ,_oPnlCabec1,{|| sfVisualNFE(_aHeadDet) },045,012,,,,.T.,,"",,,,.F. )
		_oBtnDetItm := TButton():New(010,065,"Saldo por Item",_oPnlCabec1,{|| sfDetItmNf(.f., _aHeadDet, .f.) },045,012,,,,.T.,,"",,,,.F. )
	EndIf

	// se for 7-SERVICOS DIVERSOS inclui opcao para visualizar a OS
	If (_cTpSrv $ "7")
		_oBtnVisOS := TButton():New(010,015,"Visualiza O.S.",_oPnlCabec1,{|| sfVisualOS(_aHeadDet,_oBrwDetalhes) },045,012,,,,.T.,,"",,,,.F. )
	EndIf

	// se for 1-ARMAZENAGEM DE CONTAINERS / 4-FRETES inclui opcao para visualizar a movimentacao da carga
	If (_cTpSrv $ "1|4")
		_oBtnVisMovCarga := TButton():New(010,015,"Visualiza Mov. Carga",_oPnlCabec1,{|| sfVisMovCarga(_aHeadDet,_oBrwDetalhes) },055,012,,,,.T.,,"",,,,.F. )
	EndIf

	// somente para 4-FRETES / 7-SERVICOS DIVERSOS, define o botao agrupar o servico ao pacote logistico
	If (!_lVisDetalhe).and.((_TRBGERAL)->IT_TIPOSRV $ "7")
		// botao para adicionar o servico no pacote logistico
		_oBtnAgrPacote  := TButton():New(010,((_aSizeDlg[5]/2)-200),"Agrega ao Pacote",_oPnlCabec1,{|| sfAgrOrdSrv(_aHeadDet,_oBrwDetalhes,@_oDlgDetalhes) },045,012,,,,.T.,,"",,,,.F. )
	EndIf

	// somente para 4-FRETES / 7-SERVICOS DIVERSOS, define o botao para ignorar todos
	If (!_lVisDetalhe).and.(_lEdita).and.((_TRBGERAL)->IT_TIPOSRV $ "4|7")
		_oBtnIgnorar    := TButton():New(010,((_aSizeDlg[5]/2)-150),"Status >Faturar<",_oPnlCabec1,{|| sfMudaStatus() },045,012,,,,.T.,,"",,,,.F. )
	EndIf


	// se nao for visualizacao, define o botao Confirmar
	If (!_lVisDetalhe)
		_oBtnConfirma := TButton():New(010,((_aSizeDlg[5]/2)-100),"Confirmar",_oPnlCabec1,{|| If(_lDadosOk := _oBrwDetalhes:TudoOK(),_oDlgDetalhes:End(),nil) },045,012,,,,.T.,,"",,,,.F. )
	EndIf

	// botao cancelar
	_oBtnCancela  := TButton():New(010,((_aSizeDlg[5]/2)- 50),"Cancelar" ,_oPnlCabec1,{|| _oDlgDetalhes:End() },045,012,,,,.T.,,"",,,,.F. )

	// cria o panel do cabecalho - descricao do item
	_oPnlCabec2 := TPanel():New(000,000,nil,_oDlgDetalhes,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlCabec2:Align:= CONTROL_ALIGN_TOP

	// data de movimentacao
	_oSayDscProd := TSay():New(008,015,{||"Descrição"},_oPnlCabec2,,,.F.,.F.,.F.,.T.)
	_oGetDscProd := TGet():New(006,050,{|u| If(PCount()>0,_cDscProduto:=u,_cDscProduto)},_oPnlCabec2,200,010,"@!",,,,_oFnt01,,,.T.,"",,{|| (!_lVisDetalhe) },.F.,.F.,,.F.,.F.,"","_cDscProduto",,)

	// browse com os detalhes dos servicos
	_oBrwDetalhes := MsNewGetDados():New(000,000,_aSizeDlg[6],_aSizeDlg[5],IIf(_cTpSrv$"4|7|8".And._lEdita,GD_UPDATE,Nil),'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDet),'AllwaysTrue()','','AllwaysTrue()',_oDlgDetalhes,_aHeadDet,_aColsDet)
	_oBrwDetalhes:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa o dialogo
	_oDlgDetalhes:Activate(,,,.T.,,, )

	// se a tela for confirmada
	If (_lDadosOk)
		// grava as alteracoes
		sfGrvAlteracoes()
	EndIf

Return(.t.)

// ** funcao que monta a EnchoiceBar da tela de detalhes de servicos
Static Function sfMntEncBar(mvOk)
	local _oBar		:= TBar():New(_oDlgDetalhes, 025, 025, .T.)
	local _oBtnImpr
	local _oBtnEdit
	
	// se nao for visualizacao, define o botao Ok
	If (!_lVisDetalhe)
		_oBtnImpr	:= TBtnBmp():NewBar("OK"	,,,,,{|| (mvOk:=.t.,_oDlgDetalhes:End()) },.F.,_oBar,.F.,,"OK",.F.,,,,"")
		SetKey(15,_oBtnImpr:bAction) //K_CTRL_O
	EndIf
	
	// define o botao Sair
	_oBtnEdit	:= TBtnBmp():NewBar("FINAL"	,,,,,{|| _oDlgDetalhes:End() },.F.,_oBar,.F.,,"Fechar" ,.F.,,,,"")
	// cancela
	SetKey(24,_oBtnEdit:bAction) //K_CTRL_X
	
	_oBar:bRClicked := {|| AlwaysTrue()}

	// somente para 4-FRETES, define o botao para Ignorar todos
	//If ((_TRBGERAL)->IT_TIPOSRV $ "4").and.(!_lVisDetalhe)
	//	DEFINE BUTTON _oBtnIgnorar RESOURCE "BONUS" OF _oBarEnchoice GROUP ACTION sfIgnorarTodos() PROMPT "Ignorar Todos" TOOLTIP "Ignorar Todos"
	//EndIf

Return Nil

// ** funcao que detalha as informacoes do servico do pacote logistico
Static Function sfDetSrvPcte(mvProduto,mvHeadSrv,mvColsSrv)
	// atualiza o tipo do servico
	local _cTpSrv := Posicione("SB1",1,xFilial("SB1")+mvProduto,"B1_TIPOSRV")

	mvHeadSrv := {}
	mvColsSrv := {}

	//mvColsSrv := sfDetServico(.f.,@mvHeadSrv,.t.,mvProduto)

	_oBrwDetSrvPcte := nil

	// PACOTE LOGISTICO
	If (_cTpSrv $ "3/A/B")
		// chama funcao para detalhes
		mvColsSrv := sfDetPacote(.f., @mvHeadSrv, .t., .f., _cTpSrv)

		// FRETES - TRANSF INTERNAS
	ElseIf (_cTpSrv == "4")
		// chama funcao para detalhes
		mvColsSrv := sfDetFrete(.f.,@mvHeadSrv,.t.,.f.)

		// SERVICOS DIVERSOS
	ElseIf (_cTpSrv == "7")
		// chama funcao para detalhes
		mvColsSrv := sfDetServico(.f.,@mvHeadSrv,.t.,.f.)

	EndIf

	// browse com os detalhes do pacote
	_oBrwDetSrvPcte := MsNewGetDados():New(000,000,1000,1000,Nil,'AllwaysTrue()','AllwaysTrue()','',,,,'AllwaysTrue()','','AllwaysTrue()',_oDlgPacLog,mvHeadSrv,mvColsSrv)
	_oBrwDetSrvPcte:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwDetSrvPcte:Refresh(.t.)

Return(.t.)

// ** funcao que chama a rotinas de consulta detalhada do processo
User Function FATA002V(mvConsulta)
	// area inicial
	local _aAreaAtu := GetArea()

	// chama a rotina de consulta detalhada do processo
	If (mvConsulta=="1")
		// desabilitado
		If (!_lBtnParam)
			Aviso("TFATA002 -> FATA002V","Opção desabilitada para este processo.",{"Fechar"})
			Return(.t.)
		EndIf

		If (Empty((_TRBGERAL)->IT_PROCESS))
			Aviso("TFATA002 -> FATA002V","Não há processo para visualizar.",{"Fechar"})
			Return(.f.)
		EndIf

		// chama rotina de consulta detalhada do processo
		U_TWMSV004((_TRBGERAL)->IT_PROCESS)

		// chama a rotina de consulta de LOG
	ElseIf (mvConsulta=="2")
		// valida se tem numero de processo
		If (Empty((_TRBGERAL)->IT_PROCESS))
			Aviso("TFATA002 -> FATA002V","Não há processo para consultar LOG!",{"Fechar"})
			Return(.f.)
		EndIf

		// verifica o tipo de pesquisa de LOG
		If (Aviso("Consulta de LOG","Qual a forma de pesquisa do Log ... ",{"Processo","Item Proc."})==1)
			// consulta Log por processo
			U_FtConsLog(cFilAnt, "SZ1", xFilial("SZ1")+(_TRBGERAL)->IT_PROCESS )
		Else
			// consulta Log por item do processo
			U_FtConsLog(cFilAnt, "SZ2", xFilial("SZ2")+(_TRBGERAL)->(IT_PROCESS+IT_ITPROCE) )
		EndIf

		// chama a rotina de visualizacao do contrato
	ElseIf (mvConsulta=="3")

		dbSelectArea("AAM")
		AAM->(dbSetOrder(1)) //1-AAM_FILIAL, AAM_CONTRT
		If AAM->(dbSeek( xFilial("AAM")+(_TRBGERAL)->IT_CONTRAT ))
			// rotina padrao para visualizacao do contrato
			At250Manut("AAM",AAM->(RecNo()),2)
		EndIf

		// mostra o ID do Processo
	ElseIf (mvConsulta=="4")

		Aviso("ID do Processo","ID: "+_cIdProc,{"Fechar"})

	EndIf

	// restaura area inicial
	RestArea(_aAreaAtu)

Return(.t.)

// ** funcao que busca o ultimo numero de pedidos cancelados
Static Function sfNextPedCan()
	// variavel de retorno
	local _cRetNum := AllTrim(GetMV('TC_PEDCANC',.F.,""))
	local _cTmpNum, _cQrySZR
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSX6 := SX6->(GetArea())

	// se _cRetNum estiver em branco exibe uma mensagem para o usuário
	If (Empty(_cRetNum))
		// mensagem para usuario
		Help( Nil, Nil, 'TFATA002 - Parâmetro TC_PEDCANC não existe',;
		Nil,;
		"Parâmetro TC_PEDCANC não existe. Favor criar o parâmetro e preencher com o número do último pedido cancelado na tabela SZR (ZR_PEDIDO)";
		, 1, 0 )		
	EndIf

	// gera o proximo numero
	_cRetNum := Soma1(_cRetNum)

	// atualiza o parametro
	PutMv('TC_PEDCANC',_cRetNum)

	// restaura area inicial
	RestArea(_aAreaSX6)
	RestArea(_aAreaAtu)

Return(_cRetNum)

// ** funcao para Ignorar o faturamento de todos os itens do detalhe do servico
Static Function sfMudaStatus()
	// header do Browse
	local _aHeadBrw := aClone(_oBrwDetalhes:aHeader)
	// posicao dos campos no browse
	local _nPosFat := aScan(_aHeadBrw,{|x| AllTrim(SubS(x[2],4))=="FATURAR"})
	// variaveis temporarias
	local _nLin
	// conteudo do campo FATURAR
	local _nOpcSelec := Aviso("Status Faturamento","Selecione a opção para mudar o status do campo FATURAR:",{"Ignorar","Status=Não","Fechar"})

	If (_nOpcSelec == 1).or.(_nOpcSelec == 2)
		// varre todos os itens dos detalhes
		For _nLin := 1 To Len(_oBrwDetalhes:aCols)
			// atualiza o campo de FATURAR como N=NAO
			_oBrwDetalhes:aCols[_nLin][_nPosFat] := IIf(_nOpcSelec==1,"I","N")
		Next _nLin
	EndIf

Return(.t.)

// ** funcao que chama rotinas de impressao
User Function FATA002O(mvTpImpressao)
	// Variavel para situação financeira
	local _nMosSitFin := 0

	// chama rotina de impressao dos detalhes do faturamento
	If (mvTpImpressao == "1")

		// valida se tem pedido de venda para visualizar
		If (Left((_TRBGERAL)->IT_NUMPED,1)!="C") .and. Empty((_TRBGERAL)->IT_NUMPED)
			Aviso("TFATA002 -> FATA002O","Não há pedido de venda para impressão!",{"Fechar"})
			Return(.f.)
		EndIf

		// chama a rotina que posiciona o pedido de venda para impressão
		Processa({ || U_WMSR004A((_TRBGERAL)->IT_NUMPED,(_TRBGERAL)->IT_NUMPED,nil,nil,nil,nil,nil,nil) },"Gerando relatório...",,.T.)

		// chama rotina de impressao dos detalhes do historico completo do faturamento
	ElseIf (mvTpImpressao == "2")

		// valida se tem pedido de venda para visualizar
		If (Left((_TRBGERAL)->IT_NUMPED,1)!="C").and.Empty((_TRBGERAL)->IT_NUMPED)
			Aviso("TFATA002 -> FATA002O","Não há pedido de venda para impressão!",{"Fechar"})
			Return(.f.)
		EndIf

		If ApMsgYesNo("Mostrar Situação Financeira?")
			_nMosSitFin := 1
		Else
			_nMosSitFin := 2
		EndIf

		// chama a rotina de impressao do historico completo do faturamento
		Processa({ || U_FATR003A((_TRBGERAL)->IT_PROCESS,_nMosSitFin) },"Gerando relatório...",,.T.)

		// chama rotina de impressao do mapa de movimentacao de produtos
	ElseIf (mvTpImpressao == "3")

		// cria os parametros de acordo com o grupo de perguntas
		Pergunte("TWMSR006",.f.)
		// estrutura
		// mv_par01 - Programação?
		// mv_par02 - Data de Referencia?
		// mv_par03 - Layout? (1-Sintético/2-Analítico")

		// define os parametros
		mv_par01 := (_TRBGERAL)->IT_PROCESS
		mv_par02 := dDataBase
		mv_par03 := Aviso("TFATA002 -> FATA002O -> Mapa de Moviment.","Opção do Layout do relatório...",{"Sintético","Analítico","Cancelar"})

		// se escolheu cancelar
		If (mv_par03==3)
			Return(.f.)
		EndIf

		// chama a rotina de impressao
		Processa({ || U_TWMSR006(.t.) },"Gerando relatório...",,.T.)

	EndIf

Return(.t.)

// ** funcao para ser utilizada no worwflow
User Function FATA002W

	// prepara o Ambiente para o Processamento
	RpcSetEnv("01","101","","","SIGAFAT","",{"AAN"})

	// cria os parametros do grupo de perguntas
	Pergunte("TFATA002",.f.)

	// executa rotina para gerar os dados
	U_FATA002A(.f.,.t.)

Return

// ** funcao para encerrar o processo
User Function FATA002I(mvEmMassa, mvProcesso)
	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaSA1 := SA1->(GetArea())
	local _aAreaSZ1 := SZ1->(GetArea())

	// controle de validacao
	local _lOk := .t.

	// opcao selecionada
	local _nOpc := 0

	// query
	local _cQuery
	local _cSeekSZ2

	// log de validacao
	local _cErroLog := ""

	// OS em aberto
	local _aOrdAbert := {}
	// movimentacao de veiculos
	local _aMovVeicu := {}
	// saldo de mercadoria
	local _nSaldo := 0

	// controle de mensagem do cabecalho
	local _lCabOk := .f.

	// nota fiscais de entrada na programacao
	local _aDocEntrada := {}
	local _nDocEntrada

	// grupo de estoque do cliente
	local _aGrpEstCli := {}
	local _cGrpEstCli := ""

	// saldo dos itens da nota fiscal
	local _aSldItens := {}

	// valor padrao
	Default mvEmMassa  := .f.
	Default mvProcesso := CriaVar("Z1_CODIGO", .f.)

	// verifica se o usuario tem permissao
	If ( ! __cUserId $ AllTrim(SuperGetMv("TC_ENCFATU",.f.,"")) )
		// mensagem
		Alert("Usuário sem permissão de encerrar o processo.")
		// retorno
		Return(.f.)
	EndIf

	// verifica se o processo foi informado
	If ( IsInCallStack("U_TFATA002") ) .and. ( Empty(mvProcesso) )
		mvProcesso := (_TRBGERAL)->IT_PROCESS
	EndIf

	// valida se o processo foi informado
	If ( Empty(mvProcesso) )
		// mensagem
		Alert("Número do processo não informado!")
		// retorno
		Return(.f.)
	EndIf

	// valida se o processo ja esta encerrado
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	If SZ1->(dbSeek( xFilial("SZ1") + mvProcesso ))
		If ( ! Empty(SZ1->Z1_DTFINFA) )
			Alert("Processo já encontra-se encerrado!")
			Return(.f.)
		EndIf
	EndIf

	// posiciona no cadastro do cliente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
	SA1->(dbSeek( xFilial("SA1") + SZ1->Z1_CLIENTE + SZ1->Z1_LOJA ))

	// mensagem de confirmacao
	If ( ! mvEmMassa )
		_nOpc := Aviso("TFATA002 -> FATA002I","Confirma o encerramento geral do processo?",{"Não","Sim"})
	EndIf

	// se a mensagem for confirmada
	If (_nOpc==2) .or. (mvEmMassa)

		// atualiza o grupo de estoque do cliente
		_aGrpEstCli := U_SqlToVet("SELECT Z36_CODIGO FROM "+RetSqlTab("Z36")+" WHERE "+RetSqlCond("Z36")+" AND Z36_SIGLA = '" + SA1->A1_SIGLA + "'")
		// converte array em string
		aEval(_aGrpEstCli,{|_aGrpEstCli| _cGrpEstCli += _aGrpEstCli+";" })

		// 1. Valida se o processo possui ordens de servico em aberto
		_cQuery := "SELECT Z6_NUMOS, Z6_EMISSAO "
		// ordens de servico
		_cQuery += "FROM "+RetSqlName("SZ6")+" SZ6 "
		// filtro de ordens de servico em aberto
		_cQuery += "WHERE "+RetSqlCond("SZ6")+" "
		// sem data de finalizacao
		_cQuery += "AND Z6_DTFINAL = ' ' "
		// status de OS Aberta
		_cQuery += "AND Z6_STATUS  = 'A' "
		// filtra o cliente
		_cQuery += "AND Z6_CLIENTE = '" + SZ1->Z1_CLIENTE + "' AND Z6_LOJA = '" + SZ1->Z1_LOJA + "' "
		// filtra o processo
		_cQuery += "AND Z6_CODIGO  = '" + SZ1->Z1_CODIGO + "' "
		// ordem dos dados
		_cQuery += "ORDER BY Z6_NUMOS "
		// executa a query
		_aOrdAbert := U_SqlToVet(_cQuery,{"Z6_EMISSAO"})

		memowrit("c:\query\tfata002_fata002i_os_em_aberto.txt",_cQuery)

		// apresenta mensagem caso tiver OS em aberto
		If (Len(_aOrdAbert) > 0)
			// incrementa LOG
			_cErroLog += If(_lCabOk,"","[001-ORDENS DE SERVICOS EM ABERTO]"+CRLF)
			// atualiza todas as OS na mensagem
			aEval(_aOrdAbert,{|_aOrdAbert| _cErroLog += " Nr OS: "+_aOrdAbert[1]+"  Data Abertura: "+DtoC(_aOrdAbert[2])+CRLF })
			// variavel de retorno
			_lOk := .f.
			// cabecalho ok
			_lCabOk := .t.
		EndIf

		// reinicia variavel
		_lCabOk := .f.

		// 2. Valida se tem OS com saldo a faturar
		_cQuery := "SELECT Z6_NUMOS, Z6_EMISSAO "
		// cabecalho da OS
		_cQuery += "FROM "+RetSqlName("SZ6")+" SZ6 "
		// itens da OS
		_cQuery += "INNER JOIN "+RetSqlName("SZ7")+" SZ7 ON "+RetSqlCond("SZ7")+" AND Z7_NUMOS = Z6_NUMOS AND (Z7_DTFATAT = ' ' OR Z7_SALDO > 0) "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("SZ6")+" "
		_cQuery += "AND Z6_CLIENTE = '" + SZ1->Z1_CLIENTE + "' AND Z6_LOJA = '" + SZ1->Z1_LOJA + "' "
		_cQuery += "AND Z6_CODIGO  = '" + SZ1->Z1_CODIGO + "' "
		// ordem dos dados
		_cQuery += "ORDER BY Z6_NUMOS "
		// executa a query
		_aOrdAbert := U_SqlToVet(_cQuery,{"Z6_EMISSAO"})

		memowrit("c:\query\tfata002_fata002i_os_com_saldo_faturar.txt",_cQuery)

		// apresenta mensagem caso tiver OS em aberto
		If (Len(_aOrdAbert) > 0)
			// incrementa LOG
			_cErroLog += If(_lCabOk,"","[002-ORDENS DE SERVICOS COM SALDO A FATURAR]"+CRLF)
			// atualiza todas as OS na mensagem
			aEval(_aOrdAbert,{|_aOrdAbert| _cErroLog += " Nr OS: "+_aOrdAbert[1]+"  Data Abertura: "+DtoC(_aOrdAbert[2])+CRLF })
			// variavel de retorno
			_lOk := .f.
			// cabecalho ok
			_lCabOk := .t.
		EndIf

		// reinicia variavel
		_lCabOk := .f.

		// 3. valida se a quantidade programada foi atendida
		dbSelectArea("SZ2")
		SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM
		SZ2->(dbSeek( _cSeekSZ2 := xFilial("SZ2") + SZ1->Z1_CODIGO ))
		While SZ2->( ! Eof() ) .and. ((SZ2->Z2_FILIAL + SZ2->Z2_CODIGO) == _cSeekSZ2)
			// verifica a quantidade
			If (SZ2->Z2_QTDREC < SZ2->Z2_QUANT)
				// incrementa LOG
				_cErroLog += If(_lCabOk,"","[003-SALDO DE VEICULOS EM ABERTO]"+CRLF)
				// detalhe do item
				_cErroLog += " Item "+SZ2->Z2_ITEM+" Programado: "+Str(SZ2->Z2_QUANT,2)+" -> Recebido: "+Str(SZ2->Z2_QTDREC,2)+CRLF
				// variavel de retorno
				_lOk := .f.
				// cabecalho ok
				_lCabOk := .t.
			EndIf
			// proximo item
			SZ2->(dbSkip())
		EndDo

		// reinicia variavel
		_lCabOk := .f.


		// 4. valida se ha movimentacao de veiculos para faturar
		_cQuery := "SELECT Z3_DTMOVIM, CASE WHEN Z3_TPMOVIM = 'E' THEN 'ENTRADA' ELSE 'SAIDA' END Z3_TPMOVIM, Z3_CONTAIN "
		// movimentacao de veiculos
		_cQuery += "FROM "+RetSqlName("SZ3")+" SZ3 "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("SZ3")+" "
		// quando NAO for pacote de servicos, FILTAR transportadora propria
		_cQuery += "AND ((Z3_TPMOVIM = 'E' AND Z3_TRACONT = '"+_cTranspPro+"') OR (Z3_TPMOVIM = 'S' AND Z3_TRANSP = '"+_cTranspPro+"')) "
		// cobranca de frete
		_cQuery += "AND Z3_DTFATFR = ' ' "
		// codigo e loja do cliente
		_cQuery += "AND Z3_CLIENTE = '" + SZ1->Z1_CLIENTE + "' AND Z3_LOJA = '" + SZ1->Z1_LOJA + "' "
		// programacao
		_cQuery += "AND Z3_PROGRAM = '" + SZ1->Z1_CODIGO + "' "
		// ordem dos dados
		_cQuery += "ORDER BY Z3_DTMOVIM, Z3_CONTAIN "
		// executa a query
		_aMovVeicu := U_SqlToVet(_cQuery,{"Z3_DTMOVIM"})

		memowrit("c:\query\tfata002_fata002i_mov_veiculos.txt",_cQuery)

		// apresenta mensagem caso tiver movimentacao de veiculos em aberto
		If (Len(_aMovVeicu) > 0)
			// incrementa LOG
			_cErroLog += If(_lCabOk,"","[004-MOVIMENTACAO DE VEICULOS - COBRANÇA DE FRETE]"+CRLF)
			// atualiza todas as movimentacoes na mensagem
			aEval(_aMovVeicu,{|_aMovVeicu| _cErroLog += " Data: "+DtoC(_aMovVeicu[1])+"  "+_aMovVeicu[2]+"  Unidade: "+Transf(_aMovVeicu[3],PesqPict("SZ3","Z3_CONTAIN"))+CRLF })
			// variavel de retorno
			_lOk := .f.
			// cabecalho ok
			_lCabOk := .t.
		EndIf

		// reinicia variavel
		_lCabOk := .f.

		// 5. valida se ha movimentacao de veiculos ainda no patio
		_cQuery := "SELECT Z3_DTMOVIM, CASE WHEN Z3_TPMOVIM = 'E' THEN 'ENTRADA' ELSE 'SAIDA' END Z3_TPMOVIM, Z3_CONTAIN "
		// movimentacao de veiculos
		_cQuery += "FROM "+RetSqlName("SZ3")+" SZ3 "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("SZ3")+" "
		// ainda no patio
		_cQuery += "AND Z3_DTSAIDA = ' ' "
		// codigo e loja do cliente
		_cQuery += "AND Z3_CLIENTE = '" + SZ1->Z1_CLIENTE + "' AND Z3_LOJA = '" + SZ1->Z1_LOJA + "' "
		// programacao
		_cQuery += "AND Z3_PROGRAM = '" + SZ1->Z1_CODIGO + "' "
		// ordem dos dados
		_cQuery += "ORDER BY Z3_DTMOVIM, Z3_CONTAIN "
		// executa a query
		_aMovVeicu := U_SqlToVet(_cQuery,{"Z3_DTMOVIM"})

		memowrit("c:\query\tfata002_fata002i_mov_veiculos_patio.txt",_cQuery)

		// apresenta mensagem caso tiver movimentacao de veiculos no patio
		If (Len(_aMovVeicu) > 0)
			// incrementa LOG
			_cErroLog += If(_lCabOk,"","[005-VEICULOS/CONTAINER NO PATIO]"+CRLF)
			// atualiza todas as movimentacoes na mensagem
			aEval(_aMovVeicu,{|_aMovVeicu| _cErroLog += " Data: "+DtoC(_aMovVeicu[1])+"  "+_aMovVeicu[2]+"  Unidade: "+Transf(_aMovVeicu[3],PesqPict("SZ3","Z3_CONTAIN"))+CRLF })
			// variavel de retorno
			_lOk := .f.
			// cabecalho ok
			_lCabOk := .t.
		EndIf

		// reinicia variavel
		_lCabOk := .f.

		// 6. valida se ha saldo de produtos para faturar
		_cQuery := "SELECT F1_DOC, F1_SERIE "
		// notas fiscais
		_cQuery += "FROM "+RetSqlName("SF1")+" SF1 "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("SF1")+" "
		// codigo e loja do cliente
		_cQuery += "AND F1_FORNECE = '" + SZ1->Z1_CLIENTE + "' AND F1_LOJA = '" + SZ1->Z1_LOJA + "' "
		// programacao
		_cQuery += "AND F1_PROGRAM = '" + SZ1->Z1_CODIGO + "' "
		// tipo da nota
		_cQuery += "AND F1_TIPO    = 'B' "
		// ordem dos dados
		_cQuery += "ORDER BY F1_DTDIGIT, F1_DOC "
		// executa a query
		_aDocEntrada := U_SqlToVet(_cQuery)

		memowrit("c:\query\tfata002_fata002i_saldo_notas.txt",_cQuery)

		// apresenta mensagem caso tiver saldo de produtos a faturar
		For _nDocEntrada := 1 to Len(_aDocEntrada)

			// saldo dos itens da nota fiscal
			_aSldItens := {}

			// calculo o saldo da nota
			_nSaldo := sfSaldoNota(	Date()+30,;
			Nil                          ,;
			SZ1->Z1_CLIENTE              ,;
			SZ1->Z1_LOJA                 ,;
			_aDocEntrada[_nDocEntrada,1] ,;
			_aDocEntrada[_nDocEntrada,2] ,;
			"4"                          ,;
			.f.                          ,;
			Nil                          ,;
			_cGrpEstCli                  ,;
			@_aSldItens                   )

			// incrementa LOG
			If (_nSaldo > 0)
				_cErroLog += If(_lCabOk,"","[006-SALDO DE MERCADORIA]"+CRLF)
				// atualiza todas as movimentacoes na mensagem
				_cErroLog += " Nota Fiscal: "+_aDocEntrada[_nDocEntrada,1]+"/"+_aDocEntrada[_nDocEntrada,2]+" Saldo: "+Transf(_nSaldo,PesqPict("SD1","D1_QUANT"))+CRLF
				// variavel de retorno
				_lOk := .f.
				// cabecalho ok
				_lCabOk := .t.
			EndIf

		Next _nDocEntrada

		// reinicia variavel
		_lCabOk := .f.

		// 7. valida se ha saldo de produtos a enderecar
		_cQuery := " SELECT DA_DOC, DA_SERIE, Sum(DA_SALDO) DA_SALDO "
		// notas fiscais
		_cQuery += " FROM " + RetSqlTab("SD1")
		// saldo a enderecar do WMS
		_cQuery += "        INNER JOIN " + RetSqlTab("SDA")
		_cQuery += "                ON " + RetSqlCond("SDA")
		_cQuery += "                   AND DA_PRODUTO = D1_COD "
		_cQuery += "                   AND DA_NUMSEQ = D1_NUMSEQ "
		_cQuery += "                   AND DA_SALDO != 0 "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("SD1")
		// codigo e loja do cliente
		_cQuery += " AND D1_FORNECE = '" + SZ1->Z1_CLIENTE + "' AND D1_LOJA = '" + SZ1->Z1_LOJA + "' "
		// programacao
		_cQuery += " AND D1_PROGRAM = '" + SZ1->Z1_CODIGO + "' "
		// tipo da nota
		_cQuery += " AND D1_TIPO    = 'B' "
		// agrupa dados
		_cQuery += " GROUP BY DA_DOC, DA_SERIE "

		// executa a query
		_aDocEntrada := U_SqlToVet(_cQuery)

		memowrit("c:\query\tfata002_fata002i_saldo_notas_wms.txt",_cQuery)

		// apresenta mensagem caso tiver saldo de produtos a faturar
		For _nDocEntrada := 1 to Len(_aDocEntrada)

			// saldo da nota
			_nSaldo := _aDocEntrada[_nDocEntrada, 3]

			// incrementa LOG
			If (_nSaldo > 0)
				// define cabecalho
				_cErroLog += IIf(_lCabOk, "", "[007-SALDO DE MERCADORIA WMS (FALTA ENDEREÇAMENTO)]" + CRLF)
				// atualiza todas as movimentacoes na mensagem
				_cErroLog += " Nota Fiscal: "+_aDocEntrada[_nDocEntrada,1] + "/" + _aDocEntrada[_nDocEntrada,2] + " Saldo: " + Transf(_nSaldo, PesqPict("SD1","D1_QUANT")) + CRLF
				// variavel de retorno
				_lOk := .f.
				// cabecalho ok
				_lCabOk := .t.
			EndIf

		Next _nDocEntrada

		// reinicia variavel
		_lCabOk := .f.
	
		// 8. valida se exite armazenagem calculada pendente de faturamento
		_cQuery := " SELECT 1 as ARMZ_ABERTA"
		_cQuery += " FROM " + RetSqlTab("SZH")
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("SZH")
		// cálculo de armazenagem em aberto
		_cQuery += " AND (ZH_PRODUTO = '' OR ZH_PEDIDO = '' ) "
		// programacao
		_cQuery += " AND ZH_PROCES = '" + SZ1->Z1_CODIGO + "' "
	
		// executa a query
		_aProg := U_SqlToVet(_cQuery)
	
		memowrit("c:\query\EncProg_armz_pendente.txt",_cQuery)
	
		// apresenta mensagem caso tiver armazenagem calculada sem faturamento
		If Len(_aProg) > 0
			_cErroLog += "[008-SERVICO DE ARMAZENAGEM CALCULADO SEM FATURAMENTO] Prog: "+ SZ1->Z1_CODIGO +" Contrato: "+ SZ1->Z1_CONTRT +CRLF
			_lOk := .f.
		Endif
		
		// reinicia variavel
		_lCabOk := .f.
	
		// 9. valida se exite seguro calculada pendente de faturamento
		_cQuery := " SELECT 1 as SEGUR_ABERTA"
		_cQuery += " FROM " + RetSqlTab("SZI")
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("SZI")
		// cálculo de armazenagem em aberto
		_cQuery += " AND (ZI_PRODUTO = '' OR ZI_PEDIDO = '' ) "
		// programacao
		_cQuery += " AND ZI_PROCES = '" + SZ1->Z1_CODIGO + "' "
	
		// executa a query
		_aProg := U_SqlToVet(_cQuery)
	
		memowrit("c:\query\EncProg_segur_pendente.txt",_cQuery)
	
		// apresenta mensagem caso tiver armazenagem calculada sem faturamento
		If Len(_aProg) > 0
			_cErroLog += "[009-SERVICO DE SEGURO CALCULADO SEM FATURAMENTO] Prog: "+ SZ1->Z1_CODIGO +" Contrato: "+ SZ1->Z1_CONTRT +CRLF
			_lOk := .f.
		Endif


		// se ocorreu algum erro, apresenta mensagem
		If ( ! _lOk )
			// mensagem de log
			HS_MsgInf("ATENÇÃO: Não é possível finalizar o processo!" +CRLF+CRLF+ _cErroLog ,;
			"Log de Encerramento",;
			"Log de Encerramento" )

			// se estiver tudo Ok
		ElseIf (_lOk)
			// atualiza da data de encerramento do processo
			dbSelectArea("SZ1")
			SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
			SZ1->(dbSeek( xFilial("SZ1") + mvProcesso ))
			RecLock("SZ1")
			SZ1->Z1_DTFINFA	:= Date()
			SZ1->Z1_USFINFA	:= __cUserId
			SZ1->(MsUnLock())

			// gera o LOG de finalizacao do processo
			U_FtGeraLog(cFilAnt, "SZ1", SZ1->(Z1_FILIAL+Z1_CODIGO), "ENCERRAMENTO GERAL DO PROCESSO", "FAT", "Z1_CODIGO")

			// mensagem
			If ( ! mvEmMassa )
				MsgInfo("Encerramento realizado com sucesso!", "Encerramento Geral")
			EndIf

		EndIf

	EndIf

Return(.t.)

// ** funcao responsavel pela geracao da nota fiscal
User Function FATA002U(mvTpOper)
	// variavel de retorno
	local _lRet := .t.
	
	// valida se o pedido de venda pode gerar nota fiscal
	If (Left((_TRBGERAL)->IT_NUMPED,1)=="C") .or. Empty((_TRBGERAL)->IT_NUMPED)
		Aviso("TFATA002 -> FATA002U","Este item não está disponível para faturamento.",{"Fechar"})
		Return(.f.)
	EndIf

	// analise de credito do pedido
	If (mvTpOper=="CR").and.(Aviso("Análise de Crédito","Executar a análise de crédito do pedido de venda ?",{"Sim","Não"})==1)
		// posiciona no registro do cabecalho do pedido de venda
		dbSelectArea("SC5")
		SC5->(dbSetOrder(1)) //1-C5_FILIAL, C5_NUM
		If dbSeek(xFilial("SC5")+(_TRBGERAL)->IT_NUMPED)
			// chama funcao de análise de crédito
			_lRet := Mata456()
		EndIf

		// geração da nota fiscal
	ElseIf (mvTpOper=="NF").and.(Aviso("Nota Fiscal","Confirma a geração da Nota Fiscal ?",{"Sim","Não"})==1)
		// posiciona no registro do cabecalho do pedido de venda
		dbSelectArea("SC5")
		SC5->(dbSetOrder(1)) //1-C5_FILIAL, C5_NUM
		If dbSeek(xFilial("SC5")+(_TRBGERAL)->IT_NUMPED)
			// chama funcao para gerar a nota fiscal
			Processa({ || _lRet := Ma410PvNfs() },"Gerando nota fiscal...",,.T.)
		EndIf

	EndIf
	
Return(_lRet)

// ** funcao pra visualizar a ordem de servico
Static Function sfVisualOS(mvHeader,mvBrwDet)
	local _nPosOS := aScan(mvHeader,{|x| AllTrim(SubS(x[2],4))=="NUMOS"})

	// fontes utilizadas na rotina WMSA002F
	Private oFntVerd15 := TFont():New("Verdana",,15,,.T.)
	Private oFntCour18 := TFont():New("Courier New",,18,,.T.)

	// se nao encontrou o campo NUMOS
	If (_nPosOS==0)
		Aviso("TFATA002 -> sfVisualOS","Erro na visualização da Ordem de Serviço. Favor verificar o tipo de serviço selecionado.",{"Fechar"})
		Return(.f.)
	EndIf

	// posciona no cabecalho da ordem de servico
	dbSelectArea("SZ6")
	SZ6->(dbSetOrder(1)) //1-Z6_FILIAL, Z6_NUMOS, Z6_CLIENTE, Z6_LOJA
	If MsSeek( xFilial("SZ6")+mvBrwDet:aCols[mvBrwDet:nAt,_nPosOS] )
		// chama rotina para visualizar a OS
		U_WMSA002F(.f., .f.)
	EndIf

Return(.t.)

// ** funcao pra visualizar a movimentacao da carga
Static Function sfVisMovCarga(mvHeader,mvBrwDet)
	local _nPosRIC := aScan(mvHeader,{|x| AllTrim(SubS(x[2],4))=="RIC"})

	// se nao encontrou o campo RIC
	If (_nPosRIC==0)
		Aviso("TFATA002 -> sfVisMovCarga","Erro na visualização da Movimentação da Carga. Favor verificar o tipo de serviço selecionado.",{"Fechar"})
		Return(.f.)
	EndIf

	// chama rotina para visualizar a mov da carga
	U_WMSV002B(xFilial("SZ3"),mvBrwDet:aCols[mvBrwDet:nAt,_nPosRIC])

Return(.t.)

// ** funcao para realizar o cancelamento da cobranca
Static Function sfCancCobranca()

	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaTrb := (_TRBGERAL)->(GetArea())

	// numero do pedido para cancelamento
	local _cNumCanc := ""

	// controle da confirmacao do processo
	Local _lOk := .F.

	// motivo do cancelamento
	private _cMotCanc := ""

	// monta a tela para informar o motivo do cancelamento
	_oDlgInfMotivo := MSDialog():New(000,000,200,400,"Informe o motivo do cancelamento",,,.F.,,,,,,.T.,,,.T. )
	_oSayMotCanc := TSay():New(007,004,{||"Informe o motivo do cancelamento:"},_oDlgInfMotivo,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGetMotCanc := TMultiGet():New(017,004,{|u| If(PCount()>0,_cMotCanc:=u,_cMotCanc)},_oDlgInfMotivo,194,060,_oFnt01,,,,,.T.,"",,,.F.,.F.,.f.,,,.F.,,)
	// botao para confirmar a tela
	_oBtnConfCanc := TButton():New(080,089,"Confirmar",_oDlgInfMotivo,{|| _lOk := sfVldMotCanc(),IF(_lOk,_oDlgInfMotivo:End(),NIL)},050,012,,,,.T.,,"",,,,.F. )
	// botao para fechar a tela
	_oBtnFechaCanc := TButton():New(080,144,"Fechar",_oDlgInfMotivo,{||_oDlgInfMotivo:End()},050,012,,,,.T.,,"",,,,.F. )
	// ativacao da tela com validacao
	_oDlgInfMotivo:Activate(,,,.T.,)

	// se cancelou, fecha a tela de nao processa
	If (!_lOk)
		Return(.f.)
	EndIf

	// busca o proximo numero do pedido para cancelamento
	_cNumCanc := sfNextPedCan()

	// atualiza o numero do pedido no arquivo de trabalho
	(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
	(_TRBGERAL)->(RecLock(_TRBGERAL,.F.))
	(_TRBGERAL)->IT_NUMPED	:= _cNumCanc
	(_TRBGERAL)->IT_ITEMPED	:= "00"
	(_TRBGERAL)->IT_CODPROD	:= If(!Empty((_TRBGERAL)->IT_CODPROD),(_TRBGERAL)->IT_CODPROD,sfRetCdSrv((_TRBGERAL)->IT_TIPOSRV))
	(_TRBGERAL)->IT_DESPROD	:= StrTran(StrTran((_TRBGERAL)->IT_DESPROD,"<<","**"),">>","")
	(_TRBGERAL)->(MsUnlock())


	// inicio da transacao
	BEGIN Transaction

		// se for armazenagem de container
		If ((_TRBGERAL)->IT_TIPOSRV == '1')
			sfBaixaContain("C")
		EndIf

		// se for armazenagem de produtos
		If ((_TRBGERAL)->IT_TIPOSRV == '2')
			sfBaixaProduto("C")
		EndIf

		// se for 3-pacote logistico / A-Pacote Logistico de Exportacao / B-Pacote de Servicos
		If ((_TRBGERAL)->IT_TIPOSRV $ '3/A/B')
			sfBaixaPacote("C", (_TRBGERAL)->IT_TIPOSRV)
		EndIf

		// se for fretes
		If ((_TRBGERAL)->IT_TIPOSRV == '4')
			sfBaixaFrete("C",.f.)
		EndIf

		// se for seguro
		If ((_TRBGERAL)->IT_TIPOSRV == '5')
			sfBaixaSeg("C")
		EndIf

		// se for servicos diversos
		If ((_TRBGERAL)->IT_TIPOSRV == '7')
			sfBaixaOS("C",.f.)
		EndIf

		// se for valores fixos / alugueis
		If ((_TRBGERAL)->IT_TIPOSRV == '8')
			sfBaixaFixo("C",.f.)
		EndIf

		// gera a linha de resumo
		dbSelectArea("SZR")
		RecLock("SZR",.t.)
		SZR->ZR_FILIAL	:= xFilial("SZR")
		SZR->ZR_PROGRAM	:= (_TRBGERAL)->IT_PROCESS
		SZR->ZR_ITEPROG	:= (_TRBGERAL)->IT_ITPROCE
		SZR->ZR_CONTRT	:= (_TRBGERAL)->IT_CONTRAT
		SZR->ZR_ITEM	:= (_TRBGERAL)->IT_ITCONTR
		SZR->ZR_CODSRV	:= If(!Empty((_TRBGERAL)->IT_CODPROD),(_TRBGERAL)->IT_CODPROD,sfRetCdSrv((_TRBGERAL)->IT_TIPOSRV))
		SZR->ZR_DESCRI	:= StrTran(StrTran((_TRBGERAL)->IT_DESPROD,"<<","**"),">>","")
		SZR->ZR_CODCLI	:= (_TRBGERAL)->IT_CODCLIE
		SZR->ZR_LOJCLI	:= (_TRBGERAL)->IT_LOJCLIE
		SZR->ZR_PEDIDO	:= (_TRBGERAL)->IT_NUMPED
		SZR->ZR_ITEPEDI	:= (_TRBGERAL)->IT_ITEMPED
		SZR->ZR_DATA	:= _dDataBase
		SZR->ZR_QUANT	:= (_TRBGERAL)->AAN_QUANT
		SZR->ZR_VLRUNI	:= (_TRBGERAL)->AAN_VLRUNI
		SZR->ZR_VALOR	:= (_TRBGERAL)->AAN_VALOR
		SZR->ZR_PACOTE	:= (_TRBGERAL)->IT_PACOTE
		MsUnlock()

		// final da transacao
	END Transaction

	// se nao mostra faturados, exclui o registro do TRB
	If (!mvMostraFat)
		(_TRBGERAL)->(RecLock(_TRBGERAL,.F.))
		(_TRBGERAL)->(dbDelete())
		(_TRBGERAL)->(MsUnlock())
	EndIf

	// restaura area inicial
	RestArea(_aAreaTrb)
	RestArea(_aAreaAtu)

Return(.t.)

// ** funcao que valida se o motivo de cancelamento foi informado
Static Function sfVldMotCanc()
	// valida o conteudo digital
	If (Empty(_cMotCanc)).or.(Len(AllTrim(_cMotCanc))<=10)
		Aviso("FATA002G -> sfVldMotCanc","É obrigatório informar o campo > Motivo de Cancelamento < !!",{"Fechar"})
		Return(.f.)
	EndIf
Return(.t.)

// ** funcao que retornar a mensage da referencia da nota
Static Function sfRetRefNf(mvProcesso)
	local _cRet := ""
	local _cQuery
	local _aTmpNotas := {}

	// monta a query pra buscar as notas fiscais do processo
	_cQuery := "SELECT F1_DOC FROM "+RetSqlName("SF1")+" SF1 "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SF1")+" "
	// filtro por processo
	_cQuery += "AND F1_PROGRAM = '"+mvProcesso+"' "
	// alimenta o vetor
	_aTmpNotas := U_SqlToVet(_cQuery)

	// se encontrou notas
	If (Len(_aTmpNotas) > 0)
		// inicio da mensagem
		_cRet := "REF "+If(Len(_aTmpNotas)==1,"SUA NF ","SUAS NFS ")
		// inclui a relacao de notas
		aEval(_aTmpNotas,{|_aTmpNotas| _cRet += _aTmpNotas+", " })
		// remove a ultima virgula
		_cRet := Left(_cRet,Len(_cRet)-2)
	EndIf

Return(_cRet)

// ** funcao para agrupar a OS no pacote logistico
Static Function sfAgrOrdSrv(mvHeader,mvBrwDet,mvDlgDetalhes)
	// variaveis temporarias
	local _cQuery
	// posicao dos campos no browse
	local _nPosRecno := aScan(mvHeader,{|x| AllTrim(SubS(x[2],4))=="RECNO"})
	local _nPosQuant := aScan(mvHeader,{|x| AllTrim(SubS(x[2],4))=="QUANT"})
	// controle da confirmacao na tela
	local _lOk := .f.
	// variaveis do browse
	local _aHeadPacote := {}
	local _aColsPacote := {}
	// saldo a utilizar
	local _nSaldo := 0
	// produto SERVICOS DIVERSOS do pacote logistico
	local _cProdSrvDiv := ""
	// quantidade para apontamento
	local _nQtdApont := 0
	// recno do pacote logistico
	local _nRecnoSZJ := 0


	// posiciona no item real do servico
	dbSelectArea("SZL")
	SZL->(dbGoTo( mvBrwDet:aCols[mvBrwDet:nAt,_nPosRecno] ))


	// verifica se existe pacote logistico
	_cQuery := "SELECT SZJ.R_E_C_N_O_ SZJRECNO "
	// pacote logistico
	_cQuery += "FROM "+RetSqlName("SZJ")+" SZJ "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SZJ")+" "
	_cQuery += "AND ZJ_PROCES  = '"+(_TRBGERAL)->IT_PROCESS+"'  AND ZJ_ITPROC = '"+(_TRBGERAL)->IT_ITPROCE+"' "
	_cQuery += "AND ZJ_CLIENTE = '"+(_TRBGERAL)->IT_CODCLIE+"' AND ZJ_LOJA    = '"+(_TRBGERAL)->IT_LOJCLIE+"' "
	_cQuery += "AND ZJ_CONTRT  = '"+(_TRBGERAL)->IT_CONTRAT+"' "
	_cQuery += "AND ZJ_STATUS  = 'F' "
	_cQuery += "AND ZJ_IDPROCE = ' ' "
	_cQuery += "AND ZJ_PEDIDO != ' ' "
	// atualiza o RECNO
	_nRecnoSZJ := U_FtQuery(_cQuery)

	// verifica se tem pacote
	If (_nRecnoSZJ == 0)
		MsgStop("Não há pacote logístico disponível.")
		Return(.f.)
	EndIf

	// posiciona no item do pacote logistico
	dbSelectArea("SZJ")
	SZJ->(dbGoTo( _nRecnoSZJ ))

	// verifica se o servico esta no contrato do pacote logistico
	_cQuery := "SELECT COUNT(*) QTD FROM "+RetSqlName("SZ9")+" SZ9 "
	_cQuery += "WHERE "+RetSqlCond("SZ9")+" "
	_cQuery += "AND Z9_CONTRAT = '"+SZJ->ZJ_CONTRT+"' AND Z9_ITEM = '"+SZJ->ZJ_ITCONTR+"' "
	_cQuery += "AND Z9_CODATIV = '"+SZL->ZL_CODATIV+"' "

	If ( U_FtQuery(_cQuery) == 0 )
		MsgStop("Serviço "+SZL->ZL_CODATIV+" não está no contrato do pacote logístico. Nr: "+SZJ->ZJ_CONTRT+" / "+SZJ->ZJ_ITCONTR)
		Return(.f.)
	EndIf


	// verifica se ja existe algum pacote logistico faturado
	_cQuery := "SELECT ZJ_PACOTE, ZJ_SEQPACO, ZJ_CONTAIN, SZJ.R_E_C_N_O_ SZJRECNO, SZ9.R_E_C_N_O_ SZ9RECNO, Z9_MAXPACO, ISNULL(SUM(ZL_QUANT),0) QTD_APONT, '.F.' IT_DEL "

	// pacote logistico
	_cQuery += "FROM "+RetSqlName("SZJ")+" SZJ "

	// atividades que compoe o item do pacote
	_cQuery += "INNER JOIN "+RetSqlName("SZ9")+" SZ9 ON "+RetSqlCond("SZ9")+" AND Z9_CONTRAT = ZJ_CONTRT AND Z9_ITEM = ZJ_ITCONTR "
	_cQuery += "AND Z9_CODATIV = '"+SZL->ZL_CODATIV+"' "

	// calcula saldo ja apontado desta atividade no pacote
	_cQuery += "LEFT  JOIN "+RetSqlName("SZL")+" SZL ON "+RetSqlCond("SZL")+" AND ZL_PROCES = ZJ_PROCES AND ZL_ITPROC = ZJ_ITPROC "
	_cQuery += "AND ZL_CONTRT  = ZJ_CONTRT AND ZL_ITCONTR = ZJ_ITCONTR AND ZL_STATUS IN ('C','F') "
	_cQuery += "AND ((ZL_CONTAIN = ZJ_CONTAIN) OR ZL_CONTAIN = ' ') "
	_cQuery += "AND ZL_PACOTE  = ZJ_PACOTE AND ZL_SEQPACO = ZJ_SEQPACO "
	_cQuery += "AND ZL_CODATIV = Z9_CODATIV "
	//_cQuery += "AND ZL_NUMOS = '"+SZL->ZL_NUMOS+"' "

	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SZJ")+" "
	_cQuery += "AND ZJ_PROCES  = '"+(_TRBGERAL)->IT_PROCESS+"'  AND ZJ_ITPROC = '"+(_TRBGERAL)->IT_ITPROCE+"' "
	_cQuery += "AND ZJ_CLIENTE = '"+(_TRBGERAL)->IT_CODCLIE+"' AND ZJ_LOJA    = '"+(_TRBGERAL)->IT_LOJCLIE+"' "
	_cQuery += "AND ZJ_CONTRT  = '"+(_TRBGERAL)->IT_CONTRAT+"' "
	_cQuery += "AND ZJ_STATUS  = 'F' "
	_cQuery += "AND ZJ_IDPROCE = ' ' "
	_cQuery += "AND ZJ_PEDIDO != ' ' "

	// agrupa os dados
	_cQuery += "GROUP BY ZJ_PACOTE, ZJ_SEQPACO, ZJ_CONTAIN, SZJ.R_E_C_N_O_, SZ9.R_E_C_N_O_, Z9_MAXPACO "

	// alimenta o vetor
	_aColsPacote := U_SqlToVet(_cQuery)

	// se encontrou informacoes, verifica o saldo
	If (Len(_aColsPacote) > 0)

		// estrutura do vetor
		// 1-ZJ_PACOTE
		// 2-ZJ_SEQPACO
		// 3-ZJ_CONTAIN
		// 4-SZJ.R_E_C_N_O_ SZJRECNO
		// 5-SZ9.R_E_C_N_O_ SZ9RECNO
		// 6-Z9_MAXPACO
		// 7-ISNULL(SUM(ZL_QUANT),0) QTD_APONT

		// define o Header
		aAdd(_aHeadPacote,{"Pacote"    ,"IT_PACOTE" , "@!", TamSx3("ZJ_PACOTE")[1] , 0,Nil,Nil,"C",Nil,"R",,,".F."})
		aAdd(_aHeadPacote,{"Sequencia" ,"IT_SEQPACO", "@!", TamSx3("ZJ_SEQPACO")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."})
		aAdd(_aHeadPacote,{"Container" ,"IT_CONTAIN", PesqPict("SZC","ZC_CODIGO"), TamSx3("ZC_CODIGO")[1] , 0,Nil,Nil,"C",Nil,"R",,,".F."})
		aAdd(_aHeadPacote,{"SZJ Recno" ,"SZJRECNO"  , "@E 999999999", 10 , 0,Nil,Nil,"N",Nil,"R",,,".F."})
		aAdd(_aHeadPacote,{"SZ9 Recno" ,"SZ9RECNO"  , "@E 999999999", 10 , 0,Nil,Nil,"N",Nil,"R",,,".F."})
		aAdd(_aHeadPacote,{"Max Pacote","Z9_MAXPACO", PesqPict("SZ9","Z9_MAXPACO"), TamSx3("Z9_MAXPACO")[1] , TamSx3("Z9_MAXPACO")[2],Nil,Nil,"N",Nil,"R",,,".F."})
		aAdd(_aHeadPacote,{"Qtd Apont" ,"QTD_APONT" , PesqPict("SZ9","Z9_MAXPACO"), TamSx3("Z9_MAXPACO")[1] , TamSx3("Z9_MAXPACO")[2],Nil,Nil,"N",Nil,"R",,,".F."})

		// monta a tela para escolha do pacote logistico
		_oDlgSelPacote := MSDialog():New(000,000,250,620,"Informar servico",,,.F.,,,,,,.T.,,,.T. )
		// cria o panel do cabecalho
		oPnlCabec := TPanel():New(000,000,nil,_oDlgSelPacote,,.F.,.F.,,,000,020,.T.,.F. )
		oPnlCabec:Align:= CONTROL_ALIGN_TOP

		// botao para confirmar
		_oBtnFechar := TButton():New(005,050,"Cancelar",oPnlCabec,{|| _oDlgSelPacote:End()},050,012,,,,.T.,,"",,,,.F. )
		_oBtnConfirmar := TButton():New(005,130,"Confirmar",oPnlCabec,{|| _lOk := .t.,_oDlgSelPacote:End()},050,012,,,,.T.,,"",,,,.F. )

		// monta o browse dos pacote disponiveis
		_oBrwPacDisp := MsNewGetDados():New(000,000,300,300,Nil,'AllwaysTrue()','AllwaysTrue()','',,,99,'AllwaysTrue()','','AllwaysTrue()',_oDlgSelPacote,_aHeadPacote,_aColsPacote)
		_oBrwPacDisp:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// ativacao da tela com validacao
		_oDlgSelPacote:Activate(,,,.T.,)

		// se a tela foi confirmada
		If (_lOk)

			// calcula o saldo disponivel (maximo menos ja utilizado)
			_nSaldo := (_oBrwPacDisp:aCols[_oBrwPacDisp:nAt,6] - _oBrwPacDisp:aCols[_oBrwPacDisp:nAt,7])

			// calcula a quantidade de apontamento de acordo com o saldo disponivel
			_nQtdApont := mvBrwDet:aCols[mvBrwDet:nAt,_nPosQuant]

			// se a quantidade for maior que o saldo disponivel
			If (_nQtdApont > _nSaldo)
				_nQtdApont := _nSaldo
			EndIf

			// se na tiver saldo, fecha a rotina
			If (_nSaldo <= 0)
				MsgStop("Sem saldo no pacote logistico")
				Return(.f.)

				// se tiver saldo permitido, relaciona o servico da OS no pacote
			ElseIf (_nSaldo > 0)

				// posiciona no item do pacote logistico
				dbSelectArea("SZJ")
				SZJ->(dbGoTo( _oBrwPacDisp:aCols[_oBrwPacDisp:nAt,4] ))

				// posiciona na atividade no item do pacote logistico
				dbSelectArea("SZ9")
				SZ9->(dbGoTo( _oBrwPacDisp:aCols[_oBrwPacDisp:nAt,5] ))

				// pesquisa o produto SERVICOS DIVERSOS dentro do pacote logistico
				_cQuery := "SELECT DISTINCT ZU_PRODUTO FROM "+RetSqlName("SZU")+" SZU "
				// cad. de produtos
				_cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND B1_COD = ZU_PRODUTO AND B1_TIPOSRV IN ('7') "
				// filtro padrao
				_cQuery += "WHERE "+RetSqlCond("SZU")+" "
				_cQuery += "AND ZU_CONTRT = '"+SZJ->ZJ_CONTRT+"' AND ZU_ITCONTR = '"+SZJ->ZJ_ITCONTR+"' "
				// executa a query
				_cProdSrvDiv := U_FtQuery(_cQuery)


				// cria o item do pacote logistico
				dbSelectArea("SZO")
				SZO->(dbOrderNickName("ZO_PACOTE")) // 1-ZO_FILIAL, ZO_PACOTE, ZO_SEQPACO, ZO_PRODUTO
				If ! SZO->(dbSeek( xFilial("SZO")+SZJ->(ZJ_PACOTE+ZJ_SEQPACO)+_cProdSrvDiv ))
					RecLock("SZO",.t.)
					SZO->ZO_FILIAL	:= xFilial("SZO")
					SZO->ZO_PACOTE	:= SZJ->ZJ_PACOTE
					SZO->ZO_SEQPACO	:= SZJ->ZJ_SEQPACO
					SZO->ZO_PRODUTO	:= _cProdSrvDiv
					MsUnLock()
				EndIf

				// posiciona no item real do servico
				dbSelectArea("SZL")
				SZL->(dbGoTo( mvBrwDet:aCols[mvBrwDet:nAt,_nPosRecno] ))

				// atualiza os dados
				dbSelectArea("SZL")
				RecLock("SZL")
				SZL->ZL_ITCONTR	:= SZJ->ZJ_ITCONTR // muda o item do contrato
				SZL->ZL_PRODUTO	:= _cProdSrvDiv
				SZL->ZL_QUANT	:= _nQtdApont
				SZL->ZL_VLRUNIT	:= SZ9->Z9_VALOR
				SZL->ZL_TOTAL	:= (_nQtdApont * SZ9->Z9_VALOR)
				SZL->ZL_FATURAR	:= "S"
				SZL->ZL_STATUS	:= SZJ->ZJ_STATUS
				SZL->ZL_DTPROCE	:= SZJ->ZJ_DTPROCE
				SZL->ZL_IDPROCE	:= " "
				SZL->ZL_USRPROC	:= __cUserId
				SZL->ZL_DATABAS	:= SZJ->ZJ_DATABAS
				SZL->ZL_PACOTE	:= SZJ->ZJ_PACOTE
				SZL->ZL_SEQPACO	:= SZJ->ZJ_SEQPACO
				SZL->ZL_PEDIDO	:= SZJ->ZJ_PEDIDO
				SZL->ZL_ITEMPED	:= SZJ->ZJ_ITEMPED
				MsUnLock()

				// diminui o saldo da atividade
				dbSelectArea("SZ7")
				SZ7->(dbSetOrder(1)) //1-Z7_FILIAL, Z7_NUMOS, Z7_CODATIV
				If SZ7->(dbSeek( xFilial("SZ7")+SZL->(ZL_NUMOS+ZL_CODATIV) ))
					RecLock("SZ7")
					SZ7->Z7_SALDO	-= _nQtdApont
					SZ7->Z7_DTFATAT	:= SZJ->ZJ_DTPROCE
					MsUnLock()
				EndIf

				// atualiza os dados da OS - Cabec
				dbSelectArea("SZ6")
				SZ6->(dbSetOrder(1)) //1-Z6_FILIAL, Z6_NUMOS, Z6_CLIENTE, Z6_LOJA
				If SZ6->(dbSeek( xFilial("SZ6")+SZL->ZL_NUMOS ))
					RecLock("SZ6")
					SZ6->Z6_STATUS := "P" // P-Pedido
					MsUnlock()
				EndIf

				// fecha a tela principal
				mvDlgDetalhes:End()

				// reabre a tela
				U_FATA002T()

			EndIf
		EndIf
	EndIf

Return(.t.)

// ** funcao que retorna informacoes (peso, cubagem) do pedido de venda / nota de retorno
Static Function sfRetInfPed(mvNumProg,mvPedido,mvTipo)
	local _cQuery
	local _nQtdRet := 0
	local _cTmpCampo := ""

	// cubagem
	If (mvTipo=="1")
		_cTmpCampo := "C6_ZCUBAGE"
		// peso bruto
	ElseIf (mvTipo=="2")
		_cTmpCampo := "C6_ZPESOB / 1000"
	EndIf

	// busca as movimentacoes
	_cQuery := " SELECT SUM("+_cTmpCampo+") VLR_RETORNO "
	// notas de saida
	_cQuery += " FROM "+RetSqlTab("SC6")
	// filtro da filial e cliente
	_cQuery += " WHERE "+RetSqlCond("SC6")
	_cQuery += " AND C6_CLI = '"+AAM->AAM_CODCLI+"' AND C6_LOJA = '"+AAM->AAM_LOJA+"' "
	// notas originais
	_cQuery += " AND C6_NFORI + C6_SERIORI IN ("
	_cQuery += "     SELECT F1_DOC + F1_SERIE FROM "+RetSqlTab("SF1")
	_cQuery += "     WHERE "+RetSqlCond("SF1")
	_cQuery += "     AND F1_PROGRAM = '"+mvNumProg+"' "
	_cQuery += "     AND F1_TIPO IN ('B','D') ) "
	// pedido de venda
	_cQuery += " AND C6_NUM = '"+mvPedido+"' "

	memowrit("c:\query\tfata002_sfRetInfPed.txt", _cQuery)

	// executa a query
	_nQtdRet := U_FtQuery(_cQuery)

Return(_nQtdRet)

// ** funcao que retorna informacoes (peso, cubagem) da nota fiscal de entrada
Static Function sfRetInfNfe(mvNumProg,mvIteProg,mvTipo)
	local _cQuery
	local _nQtdRet := 0
	local _cTmpCampo := ""

	// cubagem
	If (mvTipo=="1")
		_cTmpCampo := "D1_ZCUBAGE"
		// peso bruto
	ElseIf (mvTipo=="2")
		_cTmpCampo := "D1_ZPESOB / 1000"
	EndIf

	// busca as movimentacoes
	_cQuery := "SELECT SUM("+_cTmpCampo+") VLR_RETORNO "
	// notas de saida
	_cQuery += "FROM "+RetSqlName("SD1")+" SD1 "
	// filtro da filial e cliente
	_cQuery += "WHERE "+RetSqlCond("SD1")+" "
	_cQuery += "AND D1_FORNECE = '"+AAM->AAM_CODCLI+"' AND D1_LOJA = '"+AAM->AAM_LOJA+"' "
	// notas originais
	_cQuery += "AND D1_PROGRAM = '"+mvNumProg+"' AND D1_ITEPROG = '"+mvIteProg+"' "
	_cQuery += "AND D1_TIPO IN ('B','D') "

	// executa a query
	_nQtdRet := U_FtQuery(_cQuery)

Return(_nQtdRet)

// ** funcao para incluir um comentario (log) no processo
User Function FATA002Q
	local _lOk := .f.
	local _cComent := Space(100)

	// monta a tela
	_oDlgInfLog := MSDialog():New(000,000,100,400,"Inserir comentário",,,.F.,,,,,,.T.,,,.T. )

	// comentario
	_oSayComent := TSay():New(010,010,{||"Comentário"},_oDlgInfLog,,,.F.,.F.,.F.,.T.)
	_oGetComent := TGet():New(008,040,{|u| If(PCount()>0,_cComent:=u,_cComent)},_oDlgInfLog,150,010,"@!",,,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cComent",,)

	// botoes para confirmar/fechar
	_oBtnConfirmar := TButton():New(025,100,"Confirmar",_oDlgInfLog,{|| _lOk := .t.,_oDlgInfLog:End()},040,012,,,,.T.,,"",,,,.F. )
	_oBtnFechar := TButton():New(025,150,"Fechar",_oDlgInfLog,{|| _oDlgInfLog:End()},040,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgInfLog:Activate(,,,.T.,)

	// se foi confirmado
	If (_lOk).and.(!Empty(_cComent))
		// insere o comentario no log
		U_FtGeraLog(cFilAnt, "SZ1", xFilial("SZ1")+(_TRBGERAL)->IT_PROCESS, "Comentário: "+_cComent, "FAT", "Z1_CODIGO")
	EndIf

Return

// ** funcao para retornar o codigo do servicos
Static Function sfRetCdSrv(mvTpServ)
	local _cRetCod := U_FtQuery("SELECT B1_COD FROM "+RetSqlName("SB1")+" SB1 WHERE "+RetSqlCond("SB1")+" AND B1_GRUPO = '9000' AND B1_TIPOSRV = '"+mvTpServ+"'")
Return(_cRetCod)

// ** funcao para faturamento de pacote logistico de exportacao
Static Function sfPctLogExp(mvTemContr)
	// area inicial
	local _aAreaAtu := GetArea()
	local _cQrySZ3, _cQrySzu

	// praca do contrato
	local _cPrcContr := If( !mvTemContr , "", AllTrim(AAN->AAN_PRACA))
	// tipo da carga
	local _cTpCarga := If( !mvTemContr , "", AAN->AAN_TIPOCA)
	// tarifa do pacote
	local _nTarifa := If( !mvTemContr , 0, AAN->AAN_VLRUNI)

	// servicos que compoe o pacote logistico
	local _aSrvPctExp := {}
	local _nSrvPctExp

	// numero do pacote logistico
	local _cNumPacote
	local _cSeqPacote

	// quebra de processo / item
	local _cQuebraPac := ""


	// MOVIMENTACOES DE ENTRADA
	_cQrySZ3 := " SELECT Z3_DTMOVIM, Z3_CONTAIN, Z3_PROGRAM, Z3_ITEPROG, Z3_RIC, Z3_TPMOVIM, Z3_PRCORIG, Z3_PRCDEST, Z3_CONTEUD, Z3_TAMCONT, Z3_TRANSP "
	_cQrySZ3 += " FROM " + RetSqlTab("SZ3")+", " + RetSqlTab("SZ1")
	// filtro padrao
	_cQrySZ3 += " WHERE "+RetSqlCond("SZ3")+" AND "+RetSqlCond("SZ1")
	// programacao
	_cQrySZ3 += " AND Z3_PROGRAM = Z1_CODIGO "
	// somente saida
	_cQrySZ3 += " AND Z3_TPMOVIM = 'S' "
	// praca de destino
	_cQrySZ3 += " AND Z3_PRCDEST IN "+FormatIn(_cPrcContr,";")+" "
	// nao foi cobrado pacote nem frete
	_cQrySZ3 += " AND Z3_DTFATPA = ' ' AND Z3_DTFATFR = ' ' "
	// filtro de datas
	_cQrySZ3 += " AND Z3_DTMOVIM BETWEEN '"+DtoS(_dIniVigen)+"' AND '"+DtoS(_dDataBase)+"' "
	_cQrySZ3 += " AND Z3_CLIENTE = '"+AAM->AAM_CODCLI+"' "
	_cQrySZ3 += " AND Z3_LOJA = '"+AAM->AAM_LOJA+"' "
	// somente container cheio
	_cQrySZ3 += " AND Z3_CONTEUD = 'C' "
	// contrato
	_cQrySZ3 += " AND Z1_CONTRT = '"+AAM->AAM_CONTRT+"' "

	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	If (mvStsProc==1) // aberto
		_cQrySZ3 += " AND Z1_DTFINFA = ' ' "
	ElseIf (mvStsProc==2) // encerrado
		_cQrySZ3 += " AND Z1_DTFINFA != ' ' "
	EndIf

	// filtra numero do processo
	_cQrySZ3 += " AND Z3_PROGRAM BETWEEN '" + mvProcDe + "' AND '" + mvProcAte + "' "

	// filtra pelo tipo da carga
	If ( ! Empty(_cTpCarga) )
		_cQrySZ3 += " AND Z1_TIPOCAR = '" + _cTpCarga + "' "
	EndIf

	// transportadora TECADI
	_cQrySZ3 += " AND Z3_TRANSP = '"+_cTranspPro+"' "

	// descarta pacote logistico ja faturado
	_cQrySZ3 += " AND NOT EXISTS ("
	_cQrySZ3 += " SELECT SZJ.R_E_C_N_O_ FROM "+RetSqlTab("SZJ")
	_cQrySZ3 += " WHERE "+RetSqlCond("SZJ")
	_cQrySZ3 += " AND ZJ_PROCES  = Z3_PROGRAM AND ZJ_ITPROC = Z3_ITEPROG "
	_cQrySZ3 += " AND ZJ_CONTRT  = Z1_CONTRT "
	_cQrySZ3 += " AND ZJ_CONTAIN = Z3_CONTAIN "
	_cQrySZ3 += " AND ZJ_DTMOVIM = Z3_DTMOVIM "
	_cQrySZ3 += " AND ZJ_TPMOVIM = Z3_TPMOVIM "
	_cQrySZ3 += " AND ZJ_DTPROCE = '"+DtoS(Date())+"' "
	_cQrySZ3 += " AND ZJ_USRPROC = '"+__cUserId+"' "
	_cQrySZ3 += " AND ZJ_IDPROCE = '"+_cIdProc+"' "
	_cQrySZ3 += " AND ZJ_STATUS  = ' ' ) "

	// apresenta somente movimentacoes de SAIDA com conteudo CHEIO, quanto a ENTRADA foi VAZIO (chamado #13197)
	_cQrySZ3 += "        AND (SELECT Count(*)
	_cQrySZ3 += "             FROM   " + RetSqlName("SZ3") + " Z3T "
	_cQrySZ3 += "             WHERE  Z3T.Z3_FILIAL = SZ3.Z3_FILIAL "
	_cQrySZ3 += "                    AND Z3T.D_E_L_E_T_ = ' ' "
	_cQrySZ3 += "                    AND Z3T.Z3_PROGRAM = SZ3.Z3_PROGRAM "
	_cQrySZ3 += "                    AND Z3T.Z3_ITEPROG = SZ3.Z3_ITEPROG "
	_cQrySZ3 += "                    AND Z3T.Z3_CONTAIN = SZ3.Z3_CONTAIN "
	_cQrySZ3 += "                    AND Z3T.Z3_DTSAIDA = SZ3.Z3_DTSAIDA "
	_cQrySZ3 += "                    AND Z3T.Z3_HRSAIDA = SZ3.Z3_HRSAIDA "
	_cQrySZ3 += "                    AND Z3T.Z3_TPMOVIM = 'E' "
	_cQrySZ3 += "                    AND Z3T.Z3_CONTEUD = 'V') != 0 "

	// ordem dos dados
	_cQrySZ3 += " ORDER BY Z3_PROGRAM, Z3_ITEPROG "

	memowrit("c:\query\tfata002_sfPctLogExp.txt",_cQrySZ3)

	If (Select("_QRYPCTEXP") != 0)
		dbSelectArea("_QRYPCTEXP")
		dbCloseArea()
	Endif
	// executa a query
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQrySZ3),"_QRYPCTEXP",.F.,.T.)
	DbSelectArea("_QRYPCTEXP")

	// varre todos os registro selecionados
	While _QRYPCTEXP->(!EOF())

		// se for outro processo / item, cria novo numero do pacote
		If (_cQuebraPac <> _QRYPCTEXP->(Z3_PROGRAM+Z3_ITEPROG))
			// controla quebra de numeracao
			_cQuebraPac := _QRYPCTEXP->(Z3_PROGRAM+Z3_ITEPROG)
			// criar novo numero do pacote
			_cNumPacote	:= GetSxeNum("SZJ","ZJ_PACOTE")
			_cSeqPacote	:= "001"
			// confirma a sequencia do numero do pacote
			ConfirmSx8()
			// verifica se quantidade programada do item esta completa
			dbSelectArea("SZ2")
			SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM
			SZ2->(dbSeek( xFilial("SZ2")+_QRYPCTEXP->(Z3_PROGRAM+Z3_ITEPROG) ))
			If (SZ2->Z2_QTDREC < SZ2->Z2_QUANT)
				Aviso("TFATA002 -> sfPctLogExp","ATENÇÃO: O processo "+SZ2->Z2_CODIGO+" item "+SZ2->Z2_ITEM+" possui saldo em aberto."+CRLF+;
				"Programado: "+Str(SZ2->Z2_QUANT,3)+CRLF+;
				"Recebido: "+Str(SZ2->Z2_QTDREC,3)+CRLF+;
				"Saldo: "+Str(SZ2->(Z2_QUANT - Z2_QTDREC),3),;
				{"Continuar..."})
			EndIf
		EndIf

		// gera os dados do pacote logistico
		dbSelectArea("SZJ")
		RecLock("SZJ",.t.)
		SZJ->ZJ_FILIAL	:= xFilial("SZJ")
		SZJ->ZJ_PROCES	:= _QRYPCTEXP->Z3_PROGRAM
		SZJ->ZJ_ITPROC	:= _QRYPCTEXP->Z3_ITEPROG
		SZJ->ZJ_CONTRT	:= AAM->AAM_CONTRT
		SZJ->ZJ_ITCONTR	:= If(mvTemContr,AAN->AAN_ITEM,"Z1")
		SZJ->ZJ_PRODUTO	:= If(mvTemContr,AAN->AAN_CODPRO,"")
		SZJ->ZJ_CLIENTE	:= AAM->AAM_CODCLI
		SZJ->ZJ_LOJA	:= AAM->AAM_LOJA
		SZJ->ZJ_PACOTE	:= _cNumPacote
		SZJ->ZJ_SEQPACO	:= _cSeqPacote
		SZJ->ZJ_VALOR	:= _nTarifa
		SZJ->ZJ_CONTAIN	:= _QRYPCTEXP->Z3_CONTAIN
		SZJ->ZJ_DTMOVIM	:= StoD(_QRYPCTEXP->Z3_DTMOVIM)
		SZJ->ZJ_TPMOVIM	:= _QRYPCTEXP->Z3_TPMOVIM
		SZJ->ZJ_RIC		:= _QRYPCTEXP->Z3_RIC
		SZJ->ZJ_TAMCONT	:= _QRYPCTEXP->Z3_TAMCONT
		SZJ->ZJ_CONTEUD	:= _QRYPCTEXP->Z3_CONTEUD
		SZJ->ZJ_TRANSP	:= _QRYPCTEXP->Z3_TRANSP
		SZJ->ZJ_PRCORIG	:= _QRYPCTEXP->Z3_PRCORIG
		SZJ->ZJ_PRCDEST	:= _QRYPCTEXP->Z3_PRCDEST
		SZJ->ZJ_FATURAR	:= "S"
		SZJ->ZJ_STATUS	:= " "
		SZJ->ZJ_IDPROCE	:= _cIdProc
		SZJ->ZJ_DTPROCE	:= _dDataBase
		SZJ->ZJ_USRPROC	:= __cUserId
		SZJ->ZJ_DATABAS	:= Date()
		MsUnLock()

		// proxima sequencia do pacote
		_cSeqPacote := Soma1(_cSeqPacote)

		// relaciona todos os itens/servicos que compoe o pacote logistico de exportacao
		_cQrySzu := "SELECT ZU_PRODUTO, B1_TIPOSRV "
		// servicos do pacote
		_cQrySzu += "FROM "+RetSqlName("SZU")+" SZU "
		// cad. de produto
		_cQrySzu += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND ZU_PRODUTO = B1_COD "
		// filtro dos servicos do contrato e item
		_cQrySzu += "WHERE "+RetSqlCond("SZU")+" "
		/// numero do contrato
		_cQrySzu += "AND ZU_CONTRT = '"+AAM->AAM_CONTRT+"' AND ZU_ITCONTR = '"+AAN->AAN_ITEM+"' "
		// ordem dos dados
		_cQrySzu += "ORDER BY ZU_PRODUTO
		// alimenta o vetor com o resultado do SQL
		_aSrvPctExp := U_SqlToVet(_cQrySzu)

		For _nSrvPctExp := 1 to Len(_aSrvPctExp)

			// FRETES
			If (_aSrvPctExp[_nSrvPctExp][2]=='4')
				sfFrete(.t.,.t.,_aSrvPctExp[_nSrvPctExp][1],.f.)

				// OUTROS SERVICOS / SERVICOS DIVERSOS
			ElseIf (_aSrvPctExp[_nSrvPctExp][2]=='7')
				sfOutrosServicos(.t.,.t.,_aSrvPctExp[_nSrvPctExp][1])

			EndIf

		Next _nSrvPctExp

		// proximo registro
		_QRYPCTEXP->(DBSKIP())
	EndDo

Return(.t.)

// ** funcao para faturamento de pacote de servicos diversos
Static Function sfPctServicos(mvTemContr)
	// area inicial
	local _aAreaAtu := GetArea()
	local _cQrySZ3, _cQrySzu, _cQryDelSZK

	// praca do contrato
	local _cPrcContr := If( !mvTemContr , "", AllTrim(AAN->AAN_PRACA))
	// tipo da carga
	local _cTpCarga := If( !mvTemContr , "", AAN->AAN_TIPOCA)
	// tarifa do pacote
	local _nTarifa := If( !mvTemContr , 0, AAN->AAN_VLRUNI)

	// servicos que compoe o pacote logistico
	local _aSrvPctExp := {}
	local _nSrvPctExp

	// numero do pacote logistico
	local _cNumPacote
	local _cSeqPacote

	// quebra de processo / item
	local _cQuebraPac := ""

	// validacao de pacote com servicos
	local _lPcteOk := .f.

	// MOVIMENTACOES DE ENTRADA
	_cQrySZ3 := "SELECT Z3_DTMOVIM, Z3_CONTAIN, Z3_PROGRAM, Z3_ITEPROG, Z3_RIC, Z3_TPMOVIM, Z3_PRCORIG, Z3_PRCDEST, Z3_CONTEUD, Z3_TAMCONT, Z3_TRANSP "
	_cQrySZ3 += "FROM "+RetSqlName("SZ3")+" SZ3, "+RetSqlName("SZ1")+" SZ1 "
	// filtro padrao
	_cQrySZ3 += "WHERE "+RetSqlCond("SZ3")+" AND "+RetSqlCond("SZ1")+" "
	// programacao
	_cQrySZ3 += "AND Z3_PROGRAM = Z1_CODIGO "
	// somente saida
	_cQrySZ3 += "AND Z3_TPMOVIM = 'E' "
	// nao foi cobrado pacote nem frete
	_cQrySZ3 += "AND Z3_DTFATPA = ' ' AND Z3_DTFATFR = ' ' "
	// filtro de datas
	_cQrySZ3 += "AND Z3_DTMOVIM BETWEEN '"+DtoS(_dIniVigen)+"' AND '"+DtoS(_dDataBase)+"' "
	// codigo do cliente
	_cQrySZ3 += "AND Z3_CLIENTE = '"+AAM->AAM_CODCLI+"' AND Z3_LOJA = '"+AAM->AAM_LOJA+"' "
	// contrato
	_cQrySZ3 += "AND Z1_CONTRT = '"+AAM->AAM_CONTRT+"' "

	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	If (mvStsProc==1) // aberto
		_cQrySZ3 +="AND Z1_DTFINFA = ' ' "
	ElseIf (mvStsProc==2) // encerrado
		_cQrySZ3 +="AND Z1_DTFINFA != ' ' "
	EndIf

	// filtra numero do processo
	_cQrySZ3 += "AND Z3_PROGRAM BETWEEN '"+mvProcDe+"' AND '"+mvProcAte+"' "

	// filtra pelo tipo da carga
	If (!Empty(_cTpCarga))
		_cQrySZ3 +="AND Z1_TIPOCAR = '"+_cTpCarga+"' "
	EndIf

	// descarta pacote logistico ja faturado
	_cQrySZ3 += "AND NOT EXISTS ("
	_cQrySZ3 += "SELECT SZJ.R_E_C_N_O_ FROM "+RetSqlName("SZJ")+" SZJ "
	_cQrySZ3 += "WHERE "+RetSqlCond("SZJ")+" "
	_cQrySZ3 += "AND ZJ_PROCES  = Z3_PROGRAM AND ZJ_ITPROC = Z3_ITEPROG "
	_cQrySZ3 += "AND ZJ_CONTRT  = Z1_CONTRT "
	_cQrySZ3 += "AND ZJ_CONTAIN = Z3_CONTAIN "
	_cQrySZ3 += "AND ZJ_DTMOVIM = Z3_DTMOVIM "
	_cQrySZ3 += "AND ZJ_TPMOVIM = Z3_TPMOVIM "
	_cQrySZ3 += "AND ZJ_DTPROCE = '"+DtoS(Date())+"' "
	_cQrySZ3 += "AND ZJ_USRPROC = '"+__cUserId+"' "
	_cQrySZ3 += "AND ZJ_IDPROCE = '"+_cIdProc+"' "
	_cQrySZ3 += "AND ZJ_STATUS  = ' ' ) "

	// ordem dos dados
	_cQrySZ3 +="ORDER BY Z3_PROGRAM, Z3_ITEPROG "

	memowrit("c:\query\tfata002_sfPctServicos.txt",_cQrySZ3)

	If (Select("_QRYPCTEXP") != 0)
		dbSelectArea("_QRYPCTEXP")
		dbCloseArea()
	Endif
	// executa a query
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQrySZ3),"_QRYPCTEXP",.F.,.T.)
	DbSelectArea("_QRYPCTEXP")

	// varre todos os registro selecionados
	While _QRYPCTEXP->(!EOF())

		// se for outro processo / item, cria novo numero do pacote
		If (_cQuebraPac <> _QRYPCTEXP->(Z3_PROGRAM+Z3_ITEPROG))

			// controla quebra de numeracao
			_cQuebraPac := _QRYPCTEXP->(Z3_PROGRAM+Z3_ITEPROG)
			// criar novo numero do pacote
			_cNumPacote	:= GetSxeNum("SZJ","ZJ_PACOTE")
			_cSeqPacote	:= "001"
			// confirma a sequencia do numero do pacote
			ConfirmSx8()

			// validacao de pacote com servicos
			_lPcteOk := .f.

			// verifica se quantidade programada do item esta completa
			dbSelectArea("SZ2")
			SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM
			SZ2->(dbSeek( xFilial("SZ2")+_QRYPCTEXP->(Z3_PROGRAM+Z3_ITEPROG) ))
			If (SZ2->Z2_QTDREC < SZ2->Z2_QUANT)
				Aviso("TFATA002 -> sfPctServicos","ATENÇÃO: O processo "+SZ2->Z2_CODIGO+" item "+SZ2->Z2_ITEM+" possui saldo em aberto."+CRLF+;
				"Programado: "+Str(SZ2->Z2_QUANT,3)+CRLF+;
				"Recebido: "+Str(SZ2->Z2_QTDREC,3)+CRLF+;
				"Saldo: "+Str(SZ2->(Z2_QUANT - Z2_QTDREC),3),;
				{"Continuar..."})
			EndIf
		EndIf

		// gera os dados do pacote logistico
		dbSelectArea("SZJ")
		RecLock("SZJ",.t.)
		SZJ->ZJ_FILIAL	:= xFilial("SZJ")
		SZJ->ZJ_PROCES	:= _QRYPCTEXP->Z3_PROGRAM
		SZJ->ZJ_ITPROC	:= _QRYPCTEXP->Z3_ITEPROG
		SZJ->ZJ_CONTRT	:= AAM->AAM_CONTRT
		SZJ->ZJ_ITCONTR	:= If(mvTemContr,AAN->AAN_ITEM,"Z1")
		SZJ->ZJ_PRODUTO	:= If(mvTemContr,AAN->AAN_CODPRO,"")
		SZJ->ZJ_CLIENTE	:= AAM->AAM_CODCLI
		SZJ->ZJ_LOJA	:= AAM->AAM_LOJA
		SZJ->ZJ_PACOTE	:= _cNumPacote
		SZJ->ZJ_SEQPACO	:= _cSeqPacote
		SZJ->ZJ_VALOR	:= _nTarifa
		SZJ->ZJ_CONTAIN	:= _QRYPCTEXP->Z3_CONTAIN
		SZJ->ZJ_DTMOVIM	:= StoD(_QRYPCTEXP->Z3_DTMOVIM)
		SZJ->ZJ_TPMOVIM	:= _QRYPCTEXP->Z3_TPMOVIM
		SZJ->ZJ_RIC		:= _QRYPCTEXP->Z3_RIC
		SZJ->ZJ_TAMCONT	:= _QRYPCTEXP->Z3_TAMCONT
		SZJ->ZJ_CONTEUD	:= _QRYPCTEXP->Z3_CONTEUD
		SZJ->ZJ_TRANSP	:= _QRYPCTEXP->Z3_TRANSP
		SZJ->ZJ_PRCORIG	:= _QRYPCTEXP->Z3_PRCORIG
		SZJ->ZJ_PRCDEST	:= _QRYPCTEXP->Z3_PRCDEST
		SZJ->ZJ_FATURAR	:= "S"
		SZJ->ZJ_STATUS	:= " "
		SZJ->ZJ_IDPROCE	:= _cIdProc
		SZJ->ZJ_DTPROCE	:= _dDataBase
		SZJ->ZJ_USRPROC	:= __cUserId
		SZJ->ZJ_DATABAS	:= Date()
		MsUnLock()

		// proxima sequencia do pacote
		_cSeqPacote := Soma1(_cSeqPacote)

		// relaciona todos os itens/servicos que compoe o pacote logistico de exportacao
		_cQrySzu := "SELECT ZU_PRODUTO, B1_TIPOSRV "
		// servicos do pacote
		_cQrySzu += "FROM "+RetSqlName("SZU")+" SZU "
		// cad. de produto
		_cQrySzu += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND ZU_PRODUTO = B1_COD "
		// filtro dos servicos do contrato e item
		_cQrySzu += "WHERE "+RetSqlCond("SZU")+" "
		/// numero do contrato
		_cQrySzu += "AND ZU_CONTRT = '"+AAM->AAM_CONTRT+"' AND ZU_ITCONTR = '"+AAN->AAN_ITEM+"' "
		// ordem dos dados
		_cQrySzu += "ORDER BY ZU_PRODUTO
		// alimenta o vetor com o resultado do SQL
		_aSrvPctExp := U_SqlToVet(_cQrySzu)

		For _nSrvPctExp := 1 to Len(_aSrvPctExp)

			// FRETES
			If (_aSrvPctExp[_nSrvPctExp][2]=='4')
				sfFrete(.t.,.t.,_aSrvPctExp[_nSrvPctExp][1],.t.)

				// OUTROS SERVICOS / SERVICOS DIVERSOS
			ElseIf (_aSrvPctExp[_nSrvPctExp][2]=='7')
				If sfOutrosServicos(.t.,.t.,_aSrvPctExp[_nSrvPctExp][1])
					_lPcteOk := .t.
				EndIf

			EndIf

		Next _nSrvPctExp

		// se NAO for pacote completo, apaga registro gerado
		If ( ! _lPcteOk)

			// apaga frete
			_cQryDelSZK := "DELETE FROM "+RetSqlName("SZK")+" "
			_cQryDelSZK += "WHERE ZK_FILIAL  = '"+xFilial("SZK")+"' "
			// processo
			_cQryDelSZK += "  AND ZK_PROCES  = '"+SZJ->ZJ_PROCES+"' "
			_cQryDelSZK += "  AND ZK_ITPROC  = '"+SZJ->ZJ_ITPROC+"' "
			// contrato
			_cQryDelSZK += "  AND ZK_CONTRT  = '"+SZJ->ZJ_CONTRT+"' "
			_cQryDelSZK += "  AND ZK_ITCONTR = '"+SZJ->ZJ_ITCONTR+"' "
			// status
			_cQryDelSZK += "  AND ZK_STATUS  = ' ' "
			_cQryDelSZK += "  AND ZK_USRPROC = '"+__cUserId+"' "
			_cQryDelSZK += "  AND ZK_DTPROCE = '"+DtoS(_dDataBase)+"' "
			_cQryDelSZK += "  AND ZK_IDPROCE = '"+_cIdProc+"' "
			// pacote
			_cQryDelSZK += "  AND ZK_PACOTE  = '"+SZJ->ZJ_PACOTE+"' "
			_cQryDelSZK += "  AND ZK_SEQPACO = '"+SZJ->ZJ_SEQPACO+"' "

			// executa o DELETE
			TcSQLExec(_cQryDelSZK)

			// apaga pacote
			dbSelectArea("SZJ")
			RecLock("SZJ",.f.)
			SZJ->(dbDelete())
			SZJ->(MsUnLock())

		EndIf

		// proximo registro
		_QRYPCTEXP->(DBSKIP())
	EndDo

Return(.t.)

// ** funcao que valida a marcacao dos itens no browse principal
Static Function sfVldMrkGeral()
	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaTrb := (_TRBGERAL)->(GetArea())
	// chave do processo
	local _cSeekProg := (_TRBGERAL)->(IT_PROCESS+IT_ITPROCE)
	// armaneza marcacao do item
	local _cAtuMarca := (_TRBGERAL)->IT_OK
	// nova marcacao
	local _cNewMarca := IIf(Empty(_cAtuMarca), _cMarca, Space(Len(_cAtuMarca)))
	// produto atual
	local _cAtuProd := (_TRBGERAL)->IT_CODPROD
	// tipo de servico atual
	local _cAtuTpServ := (_TRBGERAL)->IT_TIPOSRV
	// chave do contrato
	local _cChvContr := (_TRBGERAL)->IT_CHVCNTR

	// valida tipo do servico
	If ! ("2" $ _cAtuTpServ)
		// atualiza o item conforme selecao
		(_TRBGERAL)->(RecLock(_TRBGERAL,.F.))
		(_TRBGERAL)->IT_OK := _cNewMarca
		(_TRBGERAL)->(MsUnLock())
		
		// refresh no browse
		oMark:Refresh()
		
		Return(.t.)
		
	EndIf

	// posiciona no primeiro item
	(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
	(_TRBGERAL)->(dbGoTop())

	// varre todos os itens do TRB
	While (_TRBGERAL)->( ! Eof() )

		// valida a chave da programacao, se nao tem pedido de venda e se tem valor
		If (_cSeekProg == (_TRBGERAL)->(IT_PROCESS+IT_ITPROCE)).and.(Empty((_TRBGERAL)->IT_NUMPED)).and.((_TRBGERAL)->AAN_VALOR > 0).and.(_cChvContr == (_TRBGERAL)->IT_CHVCNTR)
			// atualiza o item conforme selecao
			(_TRBGERAL)->(RecLock(_TRBGERAL,.F.))
			(_TRBGERAL)->IT_OK := _cNewMarca
			(_TRBGERAL)->(MsUnlock())
		EndIf
		// proximo item
		(_TRBGERAL)->(DbSkip())
	EndDo
	
	// restaura area atual
	RestArea(_aAreaTrb)
	RestArea(_aAreaAtu)
	
	// refresh no browse
	oMark:Refresh()

Return(.t.)

// ** funcao que marca todos
Static Function sfMrkAll()
	// armaneza marcacao do item
	local _cAtuMarca	:= ""
	// nova marcacao
	local _cNewMarca 	:= ""
	// produto atual
	local _cAtuProd		:= ""
	// tipo de servico atual
	local _cAtuTpServ	:= ""
	// chave do contrato
	local _cChvContr	:= ""

	(_TRBGERAL)->(dbGoTop())
	
	While (_TRBGERAL)->( ! Eof() )
		
		_cAtuMarca := (_TRBGERAL)->IT_OK
		_cNewMarca := IIf(Empty(_cAtuMarca), _cMarca, Space(Len(_cAtuMarca)))
		_cAtuProd := (_TRBGERAL)->IT_CODPROD
		_cAtuTpServ := (_TRBGERAL)->IT_TIPOSRV
		_cChvContr := (_TRBGERAL)->IT_CHVCNTR
		
		// valida tipo do servico
		If ! ("2" $ _cAtuTpServ)
			// atualiza o item conforme selecao
			(_TRBGERAL)->(RecLock(_TRBGERAL,.F.))
			(_TRBGERAL)->IT_OK := _cNewMarca
			(_TRBGERAL)->(MsUnLock())
			
		EndIf
	
		// valida a chave da programacao, se nao tem pedido de venda e se tem valor
		If ("2" $ _cAtuTpServ) .and. (Empty((_TRBGERAL)->IT_NUMPED)) .and. ((_TRBGERAL)->AAN_VALOR > 0) .and. (_cChvContr == (_TRBGERAL)->IT_CHVCNTR)
			// atualiza o item conforme selecao
			(_TRBGERAL)->(RecLock(_TRBGERAL,.F.))
			(_TRBGERAL)->IT_OK := _cNewMarca
			(_TRBGERAL)->(MsUnlock())
		EndIf
		// proximo item
		(_TRBGERAL)->(DbSkip())
	
	EndDo
	
	// refresh no browse
	oMark:Refresh()
	oMark:GoTop( .T. )

Return(.t.)


// ** funcao pra visualizar o saldo por item da nota fiscal
Static Function sfDetItmNf(mvResumo, mvHeader, mvFatura)

	// dimensoes da tela
	local _aSizeDlg := MsAdvSize()

	// posicao dos campos
	local _nP_Period := aScan(mvHeader,{|x| "PERIOD" $ AllTrim(x[2]) })
	local _nP_Doc    := aScan(mvHeader,{|x| AllTrim(SubS(x[2],4))=="DOC"})
	local _nP_Serie  := aScan(mvHeader,{|x| AllTrim(SubS(x[2],4))=="SERIE"})
	local _nP_TpArm  := aScan(mvHeader,{|x| "TPARMA" $ AllTrim(x[2]) })

	// objetos para browse
	local _aHdSldItm := {}
	local _aCoSldItm := {}

	// query
	local _cQuery := " SELECT "

	// objetos da tela
	local _oDlg01SldItm
	local _oPnl01Cab
	local _oBtn01Fechar
	local _oBrw01SldItm

	// define todos os campos do header
	_cQuery += "Z48_PERIOD, "; aAdd(_aHdSldItm,{"Periodo"      ,"Z48_PERIOD", PesqPict("Z48","Z48_PERIOD") , TamSx3("Z48_PERIOD")[1] , TamSx3("Z48_PERIOD")[2],Nil,Nil,"N",Nil,"R" })
	_cQuery += "Z48_DOC, "   ; aAdd(_aHdSldItm,{"NF.Remessa"   ,"Z48_DOC"   , PesqPict("Z48","Z48_DOC")    , TamSx3("Z48_DOC")[1]    , 0,Nil,Nil,"C",Nil,"R" })
	_cQuery += "Z48_SERIE, " ; aAdd(_aHdSldItm,{"Série"        ,"Z48_SERIE" , PesqPict("Z48","Z48_SERIE")  , TamSx3("Z48_SERIE")[1]  , 0,Nil,Nil,"C",Nil,"R" })
	_cQuery += "Z48_ITEMNF, "; aAdd(_aHdSldItm,{"Item NF"      ,"Z48_ITEMNF", PesqPict("Z48","Z48_ITEMNF") , TamSx3("Z48_ITEMNF")[1] , 0,Nil,Nil,"C",Nil,"R" })
	_cQuery += "Z48_PRODUT, "; aAdd(_aHdSldItm,{"Produto NF"   ,"Z48_PRODUT", PesqPict("Z48","Z48_PRODUT") , TamSx3("Z48_PRODUT")[1] , 0,Nil,Nil,"C",Nil,"R" })
	_cQuery += "Z48_SALDO, " ; aAdd(_aHdSldItm,{"Saldo NF"     ,"Z48_SALDO" , PesqPict("Z48","Z48_SALDO")  , TamSx3("Z48_SALDO")[1]  , TamSx3("Z48_SALDO")[2] ,Nil,Nil,"N",Nil,"R" })
	_cQuery += "Z48_VLRUNI, "; aAdd(_aHdSldItm,{"Tarifa"       ,"Z48_VLRUNI", PesqPict("Z48","Z48_VLRUNI") , TamSx3("Z48_VLRUNI")[1] , TamSx3("Z48_VLRUNI")[2],Nil,Nil,"N",Nil,"R" })
	_cQuery += "Z48_TOTAL, " ; aAdd(_aHdSldItm,{"Valor Total"  ,"Z48_TOTAL" , PesqPict("Z48","Z48_TOTAL")  , TamSx3("Z48_TOTAL")[1]  , TamSx3("Z48_TOTAL")[2] ,Nil,Nil,"N",Nil,"R" })
	_cQuery += "Z48_DIASPE, "; aAdd(_aHdSldItm,{"Periodicidade","Z48_DIASPE", PesqPict("Z48","Z48_DIASPE") , TamSx3("Z48_DIASPE")[1] , 0,Nil,Nil,"N",Nil,"R" })
	_cQuery += "Z48_TPARMA, "; aAdd(_aHdSldItm,{"Tipo Cobrança","Z48_TPARMA", PesqPict("Z48","Z48_TPARMA") , TamSx3("Z48_TPARMA")[1] , 0,Nil,Nil,"C",Nil,"R" })
	_cQuery += "Z48_DTINI, " ; aAdd(_aHdSldItm,{"Data Inicial" ,"Z48_DTINI" , ""                           , TamSx3("Z48_DTINI")[1]  , 0,Nil,Nil,"D",Nil,"R" })
	_cQuery += "Z48_DTFIM, " ; aAdd(_aHdSldItm,{"Data Final"   ,"Z48_DTFIM" , ""                           , TamSx3("Z48_DTFIM")[1]  , 0,Nil,Nil,"D",Nil,"R" })

	// recno e delete
	_cQuery += "Z48.R_E_C_N_O_ Z48RECNO, '.F.' IT_DEL " ; aAdd(_aHdSldItm,{"Recno", "Z48RECNO", "", 10 , 0,Nil,Nil,"N",Nil,"R",,,".F." })

	// continuacao da query
	_cQuery += " FROM "+RetSqlTab("Z48")
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z48")

	// filtro por ID de processo
	_cQuery += " AND ("
	// filtro de processo atual
	_cQuery += "     (Z48_DTPROC = '"+DtoS(_dDataBase)+"' "
	_cQuery += "      AND Z48_USRPRO = '"+__cUserId+"' "
	_cQuery += "      AND Z48_IDPROC = '"+_cIdProc+"' "
	_cQuery += "      AND Z48_STATUS = ' ') "
	// filtro para mostrar faturados/cancelados anteriormente
	If (mvMostraFat)
		_cQuery += " OR (Z48_IDPROC = ' ' AND Z48_STATUS IN ('C','F')) "
	EndIf
	_cQuery += "    ) "

	// filtro especifico das informacoes detalhadas
	If ( ! mvResumo )
		_cQuery += " AND Z48_PROCES = '"+(_TRBGERAL)->IT_PROCESS+"' "
		_cQuery += " AND Z48_ITPROC = '"+(_TRBGERAL)->IT_ITPROCE+"' "
		_cQuery += " AND Z48_CONTRT = '"+(_TRBGERAL)->IT_CONTRAT+"' "
		_cQuery += " AND Z48_ITCONT = '"+(_TRBGERAL)->IT_ITCONTR+"' "
		// se for faturamento filtra pelo pedido de venda em branco
		If (mvFatura)
			_cQuery += " AND Z48_PEDIDO = ' ' "
		ElseIf ( ! mvFatura )
			_cQuery += " AND Z48_PEDIDO = '"+(_TRBGERAL)->IT_NUMPED+"' "
			_cQuery += " AND Z48_ITEMPV = '"+(_TRBGERAL)->IT_ITEMPED+"' "
		EndIf
	EndIf

	If ( ! mvResumo ).and.( ! mvFatura )
		// filtro por nota fiscal
		_cQuery += " AND Z48_DOC   = '" +_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nP_Doc  ]+ "' "
		_cQuery += " AND Z48_SERIE = '" +_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nP_Serie]+ "' "
		// periodo
		_cQuery += " AND Z48_PERIOD = " +AllTrim(Str(_oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nP_Period]))
		// tipo de armazenagem / cobranca
		_cQuery += " AND Z48_TPARMA = '" + IIf(_nP_TpArm > 0, _oBrwDetalhes:aCols[_oBrwDetalhes:nAt,_nP_TpArm], "V")+ "' "
	EndIf

	// ordem dos dados
	_cQuery += " ORDER BY Z48_DTINI "

	MemoWrit("c:\query\tfata002_sfDetItmNf.txt", _cQuery)

	// atualiza itens do browse
	_aCoSldItm := U_SqlToVet(_cQuery, {"Z48_DTINI","Z48_DTFIM"})

	If ( ! mvResumo ).and.( ! mvFatura )
		// definicao da tela
		_oDlg01SldItm := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Saldo por Item - "+AllTrim((_TRBGERAL)->IT_DESPROD),,,.F.,,,,,,.T.,,,.T. )
		_oDlg01SldItm:lMaximized := .T.

		// cria o panel do cabecalho - botoes
		_oPnl01Cab := TPanel():New(000,000,nil,_oDlg01SldItm,,.F.,.F.,,,000,025,.T.,.F. )
		_oPnl01Cab:Align:= CONTROL_ALIGN_TOP

		// botao fechar
		_oBtn01Fechar := TButton():New(007,((_aSizeDlg[5]/2)- 50),"Fechar" ,_oPnl01Cab,{|| _oDlg01SldItm:End() },045,012,,,,.T.,,"",,,,.F. )

		// browse com os detalhes dos servicos
		_oBrw01SldItm := MsNewGetDados():New(000,000,_aSizeDlg[6],_aSizeDlg[5],Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aCoSldItm),'AllwaysTrue()','','AllwaysTrue()',_oDlg01SldItm,_aHdSldItm,_aCoSldItm)
		_oBrw01SldItm:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// ativa o dialogo
		_oDlg01SldItm:Activate(,,,.T.,,, )
	EndIf

Return( IIf(mvResumo, .t., _aCoSldItm) )

// encerrar processos em massa
User Function FATA002J
	// mensagem de confirmacao
	local _nOpc := Aviso("TFATA002 -> FATA002J","Confirma o encerramento geral de TODOS os processos apresentados na tela ?",{"Não","Sim"})
	// codigo do processo
	local _cTmpProc := ""

	// se foi confirmado
	If (_nOpc == 2)

		// primeiro registro
		(_TRBGERAL)->(dbSelectArea(_TRBGERAL))
		(_TRBGERAL)->(dbGoTop())

		While (_TRBGERAL)->( ! Eof() )

			// controle de processo ja executado
			If (_cTmpProc != (_TRBGERAL)->IT_PROCESS)

				// chama funcao de encerramento de processo
				If ( ! U_FATA002I(.t.) )
					Return(.f.)
				EndIf

				// controle de processamento
				_cTmpProc := (_TRBGERAL)->IT_PROCESS

			EndIf

			// proximo processo
			(_TRBGERAL)->( dbSkip() )
		EndDo

	EndIf

Return
