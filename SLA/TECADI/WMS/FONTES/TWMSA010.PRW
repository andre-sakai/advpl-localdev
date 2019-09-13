#Include "Totvs.ch"
#Include "Protheus.ch"
#Include "TopConn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para conferencia de mercadoria no processo de    !
!                  ! entrada de produtos                                     !
!                  ! - Chamada a partir da rotina TWMSA009/TACDA002          !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 07/2012 !
+------------------+--------------------------------------------------------*/

User Function TWMSA010(mvQryUsr, mvGeraMapa)
	// variavel de retorno
	local _lRet := .F.
	// status para filtrar OS
	local _cStsFiltro := "EX"

	// controle para novo WMS
	local _lWmsNovo := .F.

	// areas de armazenagem
	Private _cAreaArm := ""

	// valor padrao para nao gerar mapa
	Default mvGeraMapa := .F.

	// valida se ha equipamento informado
	If ( ! Empty(_cCodEquip) )
		U_FtWmsMsg("No processo de conferência não é necessário equipamento!","ATENCAO")
		Return(.F.)
	EndIf

	// inclui o codigo do servico de conferencia (entrada) na query
	mvQryUsr += " AND Z06_SERVIC IN ('003','T03','T04','015') AND Z06_TAREFA IN ('003', '014') "

	// se eh chamada para gerar o mapa apos finalizar a OS
	If (mvGeraMapa)
		// status de finalizada - mostra todas as OS finalizadas para geração do mapa
		_cStsFiltro := "FI"
		// só mostra OS que já tiveram conferencia
		mvQryUsr += "  AND Z06_NUMOS IN (SELECT DISTINCT Z07CONF.Z07_NUMOS FROM "+RetSqlName("Z07")+" Z07CONF (nolock)  WHERE Z07CONF.Z07_FILIAL = Z06_FILIAL AND Z07CONF.Z07_NUMOS = Z06_NUMOS AND Z07CONF.D_E_L_E_T_ = '' )
		// só mostra Os que não possuem mapa gerado
		mvQryUsr += "  AND Z06_NUMOS NOT IN (SELECT DISTINCT Z08MAPA.Z08_NUMOS FROM "+RetSqlName("Z08")+" Z08MAPA (nolock)  WHERE Z08MAPA.Z08_FILIAL = Z06_FILIAL AND Z08MAPA.Z08_NUMOS = Z06_NUMOS AND Z08MAPA.D_E_L_E_T_ = '' )
	EndIf

	// chama funcao para visualizar o resumo da OS (o condicional com o mvGeraMapa é apenas para não alterar o status da OS)
	If ( _lRet := U_ACDA002C(mvQryUsr,_cStsFiltro,.T.,IIF(mvGeraMapa, .F.,.T.),.F.,.T.) )

		// verifica a configuracao do WMS novo
		//		_lWmsNovo := (U_FtWmsParam("WMS_VERSAO", "N", 1, .F., "", Z05->Z05_CLIENT, Z05->Z05_LOJA, Nil, Nil) == 2)

		//		If ( ! _lWmsNovo )
		// rotina generica de conferencia
		U_WMSA010A(	Z06->Z06_SERVIC, Z06->Z06_TAREFA, Z06->Z06_STATUS, ;
		Z06->Z06_NUMOS , Z06->Z06_SEQOS, ;
		Z05->Z05_CLIENT, Z05->Z05_LOJA,  ;
		Z06->Z06_PRIOR , mvGeraMapa      )

		/*		ElseIf (_lWmsNovo)
		// nova versao de conferencia
		U_WMSA041A( ;
		Z06->Z06_SERVIC, Z06->Z06_TAREFA,;
		Z06->Z06_STATUS, ;
		Z06->Z06_NUMOS , Z06->Z06_SEQOS, ;
		Z05->Z05_CLIENT, Z05->Z05_LOJA,  ;
		Z06->Z06_PRIOR , mvGeraMapa      )

		EndIf
		*/
	EndIf

Return(_lRet)

// ** funcao principal de conferencia de mercadoria (recebimento)
User Function WMSA010A(mvCodServ, mvCodTaref, mvStatus, mvNumOS, mvSeqOS, mvCodCli, mvLojCli, mvPriori, mvGeraMapa)

	// variavel de retorno
	local _lRet := .T.

	local _lOk := .F.

	// resumo da conferencia
	local _aResumoConf := {}

	// sub-menu
	local _oMnuOpcoes := nil
	local _oSbMnOp01 := nil
	local _oSbMnOp02 := nil
	local _oSbMnOp03 := nil
	local _oSbMnOp04 := nil
	local _oSbMnOp05 := nil
	local _oSbMnOp06 := nil
	local _oSbMnOp07 := nil
	local _oSbMnOp08 := nil
	local _oSbMnOp09 := nil
	local _oSbMnOp10 := nil
	local _oSbMnOp11 := nil
	local _oSbMnOp12 := nil

	// valida identificacao do produto
	local _cTpIdEtiq := U_FtWmsParam("WMS_PRODUTO_ETIQ_IDENT", "C", "INTERNA", .F., "", mvCodCli, mvLojCli, "", mvNumOS)

	// pastas do FOLDER
	local _aFolders := {'Conferência'}

	// query pra análise de conferência não finaliada
	local _cQryZ07 := ""


	// variaveis recebidas de parametro
	Private _cCodServ   := mvCodServ
	Private _cCodTaref  := mvCodTaref
	Private _cCodStatus := mvStatus
	private _cNumOrdSrv := mvNumOS
	private _cSeqOrdSrv := mvSeqOS
	Private _cCodCliFor := mvCodCli
	Private _cLojCliFor := mvLojCli
	Private _cOSOrig    := Z05->Z05_OSORIG

	// informacoes do produto
	private _cEtiqProd  := CriaVar("Z11_CODETI",.F.)
	private _cEtqLote   := CriaVar("B8_LOTECTL",.F.)
	private _cPltClie   := CriaVar("Z07_PLTCLI",.F.)
	private _cNumSerie  := CriaVar("Z07_NUMSER",.F.)
	private _dDtSeri    := CriaVar("Z07_DTSERI",.F.)
	private _dVldLote   := CtoD("31/12/2049")
	Private _nTamCodPrd := TamSx3("B1_COD")[1]
	Private _nQtdProd   := 0
	Private _cCodProd   := Space(_nTamCodPrd)
	Private _cDscProd   := ""
	Private _nQtdSegUM  := 0
	private _cEtqCodBar := ""
	private _nPltCamada := CriaVar("Z07_CAMPLT", .F.)

	// controle de numero de contagens
	Private _cNrContagem := ""

	// variável para informar se é uma OS do tipo "pré-conferencia" (sem documento/nota fiscal)
	Private _lPreConf := (_cCodServ == "015")

	// Id do palete
	private _nTamIdPal := TamSx3("Z11_CODETI")[1]
	private _cIdPalete := Space(_nTamIdPal)
	private _cMskEtiq  := PesqPict("Z11","Z11_CODETI")
	private _cCodUnit  := CriaVar("DC1_CODUNI",.F.)

	// gera id palete automatico (sem a necessidade de leitura da etiqueta)
	private _lIdPltAuto := .T.
	private _cIdPltAuto := PadR("AUT_" + _cCodOper,_nTamIdPal)

	// status do conteudo do palete
	private _cStatusPlt := "V"

	// status do conteudo do volume
	private _cStatusVlm := "V"

	// endereco de devolucao de mercadorias para o cliente
	Private _cEndDevCli := PadR("DEVMERCCLI", TamSx3("BE_LOCALIZ")[1])

	// codigo da programacao/processo
	Private _cCodProg := Z05->Z05_PROCES

	// numero do contrato
	Private _cContrat := ""

	// validação se pode finalizar a conferência sem mapa gerado
	Private _lFinSemMapa := U_FtWmsParam("WMS_FINALIZA_CONF_SEM_MAPA", "L", .F., .F., "", mvCodCli, mvLojCli, "", mvNumOS)

	// parâmetro para não necessitar confirmar "novo volume" na conferência
	Private _lAutoVol := U_FtWmsParam("WMS_RECEBIMENTO_VOLUME_AUTOMATICO", "L", .F. , .F., "", mvCodCli, mvLojCli, "", mvNumOS)

	// se processo de integração para barcode Sumitomo está ativa
	Private lSumiBar := U_FtWmsParam("WMS_SUMITOMO_LEITURA_BARCODE", "L", .F., .F., Nil, _cCodCliFor, _cLojCliFor, Nil, Nil)

	// verifica se o controle de lote esta ativo
	Private _lLotAtivo := .F.

	// numero da movimentacao do veiculo
	private _cNumCESV := ""

	// armazem
	private _cArmzServ := ""

	// doca do servico
	private _cDocaSrv := ""

	// variaveis do browse
	private _oBrwConferencia
	private _aHeadConf := {}
	private _aColsConf := {}

	// tipo de identificacao
	private _lEtqIdInt  := (AllTrim(_cTpIdEtiq) == "INTERNA")
	private _lEtqIdEAN  := (AllTrim(_cTpIdEtiq) == "EAN") .Or. (AllTrim(_cTpIdEtiq) == "EAN13")
	private _lEtqIdDUN  := (AllTrim(_cTpIdEtiq) == "DUN14")
	private _lEtqCod128 := (AllTrim(_cTpIdEtiq) == "CODE128")
	private _lEtqClient := (AllTrim(_cTpIdEtiq) == "CLIENTE")

	// permite conferencia/recebimento por volumes
	private _lCtrVolume := .F.
	private _lCtrVld    := .F.
	private _lRptLot    := .F.

	// variável para verificar se controla número de série
	private _lNumSerie := .F.   // flag de controle de numero de serie no produto
	private _lSerieAtv := .F.   // flag de controle de número de serie global por cliente (parâmetro tabela Z30)

	// Id etiqueta do volume
	private _cEtqVolume := Space(_nTamIdPal)

	// controle de apontamento de palete
	private _lNovoPalete := .T.

	// controle de apontamento de volume
	private _lNovoVolume := .T.

	// codigo do unitizador padrao
	private _cUnitPdr := SuperGetMV('TC_PLTPADR',.F.,"000001")

	// variaveis do browse
	private _oBrwCompKit
	private _aHdCompKit := {}
	private _aItCompKit := {}

	// opcoes de kit
	private _aKitDispon   := {}
	private _aOpcoesKit   := {}
	private _cSeqKitSelec := ""

	// tipo de estoque
	private _aOpcoesEst     := {}
	private _cTpEstoque     := U_FtWmsParam("WMS_RECEBIMENTO_TIPO_ESTOQUE_PADRAO", "C", "000001" , .F., "", mvCodCli, mvLojCli, "", "")  // tipo de estoque padrão
	// tipo de estoque apresentado na tela
	private _cDescTpEstoque := ""
	private _oSayCodEst // objeto do estoque

	//quantidade conferida no pallet atual
	private _oSayQtdPal
	private _nQtdConfPlt := 0

	// numero da OS
	private _cNumos := mvNumOS

	// valida se a conferencia é devolucao de mercadoria sem nota fiscal
	private _lDevMerc := .F.

	// RECNO do Z07
	private _nRecnoZ07 := 0

	// controla se informa a quantidade manual
	private _lInfManual := .F.

	// num seq do documento de entrada
	private _cNumSeq := ""

	// quantidade etiqueta de identificacao por palete
	private _lEtqUnqPlt := U_FtWmsParam("WMS_ETIQ_IDENT_UNICA_PALETE", "L", .F., .F., "", mvCodCli, mvLojCli, "", mvNumOS)

	// aceita recebimento em palete misto
	private _lPltMisto := .T.

	// mascara para campos quantidade
	private _cMaskQuant := U_FtWmsParam("WMS_MASCARA_CAMPO_QUANTIDADE", "C", PesqPict("SD1","D1_QUANT"), .F., "", mvCodCli, mvLojCli, "", mvNumOS)

	// mascara para codigo de barras
	private _cMskCodBar := PesqPict("SB1","B1_CODBAR")

	// verifica se o lote eh obrigatorio na entrada da nota
	private _lLotObrEnt := .F.

	// permite impressao de etiquetas no recebimento
	private _lImpEtiq := .F.

	// valida o controle de uso de segunda unidade de medida
	private _lUsoSegUM := .F.

	// valida uso de logistica reversa
	private _lUsoLogRev := .F.

	// valida o controle de uso de segunda unidade de medida, se podera ser fracionada
	private _lSegUMFrac := .F.

	// enderecos utilizados para geracao do mapa de armazenagem
	// estrutura
	// 1- Armazem/Local
	// 2- Endereco
	// 3- Quantidade
	// 4- Status do Palete
	// 5- Tipo da Conferencia
	// 6- Lote
	// 7- Completa Palete Fracionado
	private _aRetEnder := {}

	// controle se deve validar a capacidade do palete baseado no cadastro de lastro x camada
	private _lVldCapacPlt := U_FtWmsParam("WMS_VALIDA_CAPACIDADE_PALETE", "L", .T., .F., "", mvCodCli, mvLojCli, "", mvNumOS)

	// define quantidade de caracteres da etiqueta do cliente
	private _nTamEtqCli := U_FtWmsParam("WMS_QUANT_CARACTERES_ETIQUETA_CLIENTE", "N", TamSx3("Z56_ETQCLI")[1], .F., "", mvCodCli, mvLojCli, "", Nil)

	// define mensagem no monitor
	U_FtMsgMon()

	// atualiza variavel de controle de geracao de mapa de armazenagem
	mvGeraMapa := Iif( ((_lRet) .And. (mvGeraMapa)) .Or. ( (!_lFinSemMapa) .And. ((_lUsrGeren) .Or. (_lUsrAccou) .Or. (_lUsrSuper) .Or. ( _lUsrLider ) ) .And. (!_lDevMerc)) , .T., .F.)

	// valida se a programacao esta encerrada
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	If (SZ1->(dbSeek( xFilial("SZ1")+ _cCodProg )))
		If ( ! Empty(SZ1->Z1_DTFINFA))
			U_FtWmsMsg("A programação " + _cCodProg + " encontra-se encerrada." + CRLF + "Contate o setor de Faturamento.","ATENCAO")
			Return(.F.)
		EndIf
	Else
		U_FtWmsMsg("Programação " + _cCodProg + " não encontrada." + CRLF + "Contate o setor de Faturamento.","ATENCAO")
		Return(.F.)
	EndIf

	// atualiza numero do contrato
	_cContrat := SZ1->Z1_CONTRT

	// valida status do contrato
	dbSelectArea("SZ1")
	AAN->(DbSetOrder(1))
	If (AAN->( DbSeek( xFilial("AAN") + _cContrat ) ) )
		If AAN->AAN_ZATIVO <> "S"
			U_FtWmsMsg("Contrato " + _cContrat + " não esta ativo." + CRLF +  "Contate o setor de Faturamento.","ATENCAO")
			Return(.F.)
		EndIf
	Else
		U_FtWmsMsg("Contrato " + _cContrat + " não encontrado." + CRLF +  "Contate o setor de Faturamento.","ATENCAO")
		Return(.F.)
	EndIf

	// permite conferencia/recebimento por volumes
	_lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.F.,.F.,"", mvCodCli, mvLojCli, _cContrat, Nil)

	// permite conferencia/recebimento por volumes
	_lSerieAtv := U_FtWmsParam("WMS_CONTROLE_POR_NUMERO_SERIE","L",.F.,.F.,"", mvCodCli, mvLojCli, _cContrat, Nil)

	// controla data de validade do lote
	_lCtrVld    := U_FtWmsParam("WMS_CONTROLE_DATA_VALIDADE","L",.F.,.F.,"", mvCodCli, mvLojCli, _cContrat, Nil)

	// controle para repetir o lote na conferencia
	_lRptLot    := U_FtWmsParam("WMS_REPETE_LOTE_NA_CONFERENCIA","L",.F.,.F.,"", mvCodCli, mvLojCli, _cContrat, Nil)

	// atualiza variavel de controle de lote
	_lLotAtivo  := U_FtWmsParam("WMS_CONTROLE_POR_LOTE","L",.F.,.F.,Nil, mvCodCli, mvLojCli, _cContrat, Nil)

	// verifica se o lote eh obrigatorio na entrada da nota
	_lLotObrEnt := U_FtWmsParam("WMS_LOTE_OBRIGATORIO_ENTRADA", "L", .F., .F., Nil, mvCodCli, mvLojCli, _cContrat, Nil)

	// validação da área de armazenagem do cliente
	_cAreaArm := U_FtWmsParam("WMS_AREA_ARMAZENAGEM_POR_CLIENTE", "C", "", .F., "", mvCodCli, mvLojCli, _cContrat, Nil)

	// permite impressao de etiquetas no recebimento
	_lImpEtiq := U_FtWmsParam("WMS_PERMITE_IMP_ETQ_RECEBIMENTO", "L", "", .T., "", mvCodCli, mvLojCli, _cContrat, Nil)

	// valida o controle de uso de segunda unidade de medida
	_lUsoSegUM := U_FtWmsParam("WMS_PRODUTO_USA_SEGUNDA_UNIDADE_MEDIDA", "L", .F. , .F., Nil, mvCodCli, mvLojCli, _cContrat, Nil)

	// aceita recebimento em palete misto
	_lPltMisto := U_FtWmsParam("WMS_ARMAZENA_PALETE_MISTO", "L", .F., .T., "", mvCodCli, mvLojCli, _cContrat, Nil)

	// valida uso de logistica reversa
	_lUsoLogRev := U_FtWmsParam("WMS_LOGISTICA_REVERSA", "L", .F. , .F., "", mvCodCli, mvLojCli, _cContrat, Nil)

	// valida o controle de uso de segunda unidade de medida, se podera ser fracionada
	_lSegUMFrac := U_FtWmsParam("WMS_PRODUTO_FRACIONA_SEGUNDA_UNIDADE_MEDIDA", "L", .F. , .F., Nil, mvCodCli, mvLojCli, _cContrat, Nil)

	// prepara tamanho do codigo de barras
	If (_lEtqIdEAN)
		_cEtqCodBar := Space(13)
		_cMskCodBar := "@R " + Replicate("9", Len(_cEtqCodBar))
	ElseIf (_lEtqCod128)
		_cEtqCodBar := CriaVar("B1_CODBAR", .F.)
		_cMskCodBar := "@!"
	ElseIf (_lEtqIdDUN)
		_cEtqCodBar := Space(14)
		_cMskCodBar := "@R " + Replicate("9", Len(_cEtqCodBar))
	ElseIf (_lEtqClient)
		_cEtqCodBar := Space(_nTamEtqCli)
		_cMskCodBar := "@!"
	EndIf

	// define campos do browse dos componentes do kit
	aAdd(_aHdCompKit,{"Conf"    ,"Z07_QUANT"  ,"@R 999" ,TamSx3("Z07_QUANT")[1],TamSx3("Z07_QUANT")[2],Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHdCompKit,{"Prog"    ,"Z07_QUANT"  ,"@R 999" ,TamSx3("Z07_QUANT")[1],TamSx3("Z07_QUANT")[2],Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHdCompKit,{"Produto" ,"Z07_PRODUT" ,""       ,TamSx3("Z07_PRODUT")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHdCompKit,{"Descr."  ,"B1_DESC"    ,""       ,TamSx3("B1_DESC")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })

	// posiciona na OS
	dbSelectArea("Z05")
	Z05->(dbSetOrder(1)) // 1-Z05_FILIAL, Z05_NUMOS
	Z05->(dbSeek( xFilial("Z05")+_cNumOrdSrv ))

	// atualiza CESV
	_cNumCESV := Z05->Z05_CESV

	// posiciona no item da OS
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	Z06->(dbSeek( xFilial("Z06")+_cNumOrdSrv+_cSeqOrdSrv ))

	// atualiza armazem
	_cArmzServ := Z06->Z06_LOCAL

	// doca do servico
	_cDocaSrv := Z06->Z06_ENDSRV

	// valida se a conferencia é devolucao de mercadoria sem nota fiscal
	_lDevMerc := sfDevMerc()

	// controle de numero de contagens
	_cNrContagem := sfRetNrCont()

	// verifica a necessidade de criar o Header
	If (Len(_aHeadConf)==0)

		aAdd(_aHeadConf,{"Quant"     , "Z07_QUANT" , _cMaskQuant, TamSx3("Z07_QUANT")[1] , TamSx3("Z07_QUANT")[2] , Nil, Nil, "N", Nil, "R",,,".F." })
		aAdd(_aHeadConf,{"Produto"   , "Z07_PRODUT", ""         , TamSx3("Z07_PRODUT")[1], 0                      , Nil, Nil, "C", Nil, "R",,,".F." })
		aAdd(_aHeadConf,{"Descr."    , "B1_DESC"   , ""         , TamSx3("B1_DESC")[1]   , 0                      , Nil, Nil, "C", Nil, "R",,,".F." })
		aAdd(_aHeadConf,{"Num.Serie" , "Z07_NUMSER", ""         , TamSx3("Z07_NUMSER")[1], 0                      , Nil, Nil, "C", Nil, "R",,,".F." })
		aAdd(_aHeadConf,{"Id Palete" , "Z07_PALLET", ""         , TamSx3("Z07_PALLET")[1], 0                      , Nil, Nil, "C", Nil, "R",,,".F." })
		aAdd(_aHeadConf,{"Id Volume" , "Z07_ETQVOL", ""         , TamSx3("Z07_ETQVOL")[1], 0                      , Nil, Nil, "C", Nil, "R",,,".F." })
		aAdd(_aHeadConf,{"Qtd Seg UM", "Z07_QTSEGU", _cMaskQuant, TamSx3("Z07_QTSEGU")[1], TamSx3("Z07_QTSEGU")[2], Nil, Nil, "N", Nil, "R",,,".F." })

	EndIf

	// atualiza os itens do browse
	If (_oBrwConferencia <> nil)
		_oBrwConferencia:aCols := aClone(_aColsConf)
		_oBrwConferencia:Refresh(.T.)
	EndIf

	// atualiza o status do conteudo do palete
	_cStatusPlt := sfRetStsPlt()

	// define novo palete
	_lNovoPalete := (_cStatusPlt == "V")

	// seleciona kits disponiveis para a conferencia
	If (_lCtrVolume)
		_aOpcoesKit := sfKitDispo()
	EndIf

	// cria nova aba para controle de volumes
	If (_lCtrVolume) .And. (Len(_aOpcoesKit) != 0)
		aAdd(_aFolders,'Dados')
	EndIf

	// seleciona os tipos de estoque disponíveis para conferência
	_aOpcoesEst := sfRetTpEstoque()
	// busca a descrição do tipo de estoque padrão
	_cDescTpEstoque := _aOpcoesEst[ AScan(_aOpcoesEst, _cTpEstoque) ]

	// valida se ha doca informada
	If ((Empty(_cArmzServ)) .Or. (Empty(_cDocaSrv)))
		// mensagem
		U_FtWmsMsg("Não há endereço de serviço informado.","ATENCAO")
		// variavel de controle
		_lRet := .F.
		// retorno
		Return(_lRet)
	EndIf

	// se a chamada for pela rotina de geração de mapa
	If (_lRet) .And. (mvGeraMapa) .And. ((_lUsrGeren) .Or. (_lUsrAccou) .Or. (_lUsrSuper) .Or. ( _lUsrLider ))
		// mensagem de confirmacao para geracao do mapa
		If ( U_FtYesNoMsg("Deseja gerar Mapa de Armazenagem?") )
			// mensagem
			MsgRun("Aguarde. Gerando mapa...",,{|| U_sfGeraMapa(.F.) })
			// retorno
			Return()
		Else
			//Se a Atividade estiver finalizada abre a opção para geração do Mapa
			If (Z06->Z06_STATUS == "FI")
				// retorno
				Return()
			EndIf
		EndIf
	EndIf

	// executa rotina para atualizar os dados de palete em conferencia
	sfSelDados("AUTO")

	// monta o dialogo do monitor
	_oWmsConfEntr := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Conf. Mercadoria (Entrada)",,,.F.,,,,,,.T.,,,.T. )
	_oWmsConfEntr:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlCfeCab := TPanel():New(000,000,nil,_oWmsConfEntr,,.F.,.F.,,CLR_HGRAY,20,20,.T.,.F.)
	_oPnlCfeCab:Align:= CONTROL_ALIGN_TOP

	// opcoes de operacoes

	// -- NOVO PALETE
	_oBt01NvPlt := TBtnBmp2():New(000,000,060,022,"ARMIMG32",,,,{|| sfNovoPalete(.T.) },_oPnlCfeCab,"Novo Palete (F7)",,.T.)
	_oBt01NvPlt:Align := CONTROL_ALIGN_LEFT
	// define teclas de atalho
	SetKey(VK_F7,{|| _oBt01NvPlt:Click() } )

	// -- NOVO VOLUME
	If (_lCtrVolume)
		_oBt01NvVlm := TBtnBmp2():New(000,000,060,022,"AVGARMAZEM",,,,{|| sfNovoVolume(.T.) },_oPnlCfeCab,"Novo Volume (F8)",,.T.)
		_oBt01NvVlm:Align := CONTROL_ALIGN_LEFT
		// define teclas de atalho
		SetKey(VK_F8,{|| _oBt01NvVlm:Click() } )
	EndIf

	// -- CONSULTA DETALHES
	_oBmpCfeCons := TBtnBmp2():New(000,000,060,022,"MDIHELP",,,,{|| sfDetConfer() },_oPnlCfeCab,"Informações",,.T.)
	_oBmpCfeCons:Align := CONTROL_ALIGN_LEFT

	// sub-itens do menus
	_oMnuOpcoes := TMenu():New(0,0,0,0,.T.)
	// adiciona itens no Menu
	// INTERROMPER
	_oSbMnOp01 := TMenuItem():New(_oMnuOpcoes,"Interromper",,,,{|| sfInterromper(_oWmsConfEntr, @_lOk) },,"STOP"   ,,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOp01)
	// -- FINALIZAR OS
	_oSbMnOp02 := TMenuItem():New(_oMnuOpcoes,"Finalizar OS",,,,{|| sfFinalizaOS(_oWmsConfEntr, @_lOk) },,"CHECKED",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOp02)
	// -- CONSULTAR DETALHES
	_oSbMnOp03 := TMenuItem():New(_oMnuOpcoes,"Cons. Detalhe OS",,,,{|| U_ACDA002B(_cNumOrdSrv, _cSeqOrdSrv, .F.) },,"NOTE",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOp03)
	// -- CONSULTAR LASTRO E CAMADA
	_oSbMnOp04 := TMenuItem():New(_oMnuOpcoes,"Lastro x Camada",,,,{|| sfLastroCamada() },,"ESTIMG32",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOp04)
	// -- CONSULTAR ENDERECOS
	_oSbMnOp05 := TMenuItem():New(_oMnuOpcoes,"Endereços",,,,{|| sfEndReserv() },,"PMSIMG32",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOp05)
	// -- IMPRESSAO DE ETIQUETAS
	If (_lImpEtiq)
		_oSbMnOp06 := TMenuItem():New(_oMnuOpcoes,"Etiquetas",,,,{|| U_WMSA009C( _cNumOrdSrv ) },,"ACDIMG32",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOp06)
	EndIf
	// -- LIBERA SAIDA DO VEICULO
	_oSbMnOp07 := TMenuItem():New(_oMnuOpcoes,"Lib.Saída.Veículo",,,,{|| U_WMSA008C( _cNumCESV ) },,"TMSIMG32",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOp07)
	// -- ESTORNO DE PALETE
	_oSbMnOp08 := TMenuItem():New(_oMnuOpcoes,"Estorno de Palete Atual",,,,{|| IIf( sfEstorno( _oBrwConferencia:aCols[_oBrwConferencia:nAt][5], /* mvIdVol */  ,_oBrwConferencia:aCols[_oBrwConferencia:nAt][2] ) , sfNovoPalete(.F.) , Nil) },,"ESTOMOVI",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOp08)
	// -- CONSULTA DE KIT
	If (_lCtrVolume) .And. (Len(_aOpcoesKit) != 0)
		_oSbMnOp09 := TMenuItem():New(_oMnuOpcoes,"Consulta Agrupadora",,,,{|| sfEstrutKit() },,"ESTIMG32",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOp09)
	EndIf

	// - ALTERA TIPO DE ESTOQUE
	_oSbMnOp12 := TMenuItem():New(_oMnuOpcoes,"Def. Tipo Estoque",,,,{|| sfAltTpEst() },,"FRTIMG32",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOp12)

	// -- SAIR SEM INTERROMPER
	If ((_lUsrGeren) .Or. (_lUsrAccou) .Or. (_lUsrSuper) .Or. ( _lUsrLider ) )
		_oSbMnOp10 := TMenuItem():New(_oMnuOpcoes,"Sair",,,,{|| _lOk := .T. , _oWmsConfEntr:End()},,"FINAL",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOp10)
	EndIf

	// -- BOTAO COM MAIS OPCOES
	_oBmpOpcoes := TBtnBmp2():New(000,000,060,022,"SDUAPPEND",,,,{|| Nil },_oPnlCfeCab,"",,.T.)
	_oBmpOpcoes:Align := CONTROL_ALIGN_RIGHT
	_oBmpOpcoes:SetPopupMenu(_oMnuOpcoes)

	// pastas com as opcoes de visualizacao
	_oFldConfEnt := TFolder():New(000,000,_aFolders,,_oWmsConfEntr,,,,.T.,,200,200)
	_oFldConfEnt:Align:= CONTROL_ALIGN_ALLCLIENT

	// -- PRIMEIRA PASTA --

	// controle por palete
	_oSayNrPalete := TSay():New(005,003,{||"Id Palete"},_oFldConfEnt:aDialogs[1],,,.F.,.F.,.F.,.T.)
	_oGetNrPalete := TGet():New(003,034,{|u| If(PCount()>0,_cIdPalete:=u,_cIdPalete)},_oFldConfEnt:aDialogs[1],048,008,_cMskEtiq,{|| (Vazio()) .Or. (sfVldPalete()) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIdPalete",,)
	_oGetNrPalete:bWhen := {|| ( ! _lIdPltAuto ) }
	_oGetNrPalete:lReadOnly := ( ! _lNovoPalete )

	// quantidade conferida
	_oSayQtdPal := TSay():New(005,085	,{ || "/ Qt conf: " + Str(_nQtdConfPlt,3)},_oFldConfEnt:aDialogs[1],,,.F.,.F.,.F.,.T.)

	// informacoes do id de volume
	_oSayEtqVolume := TSay():New(017,003,{||"Id Volume"},_oFldConfEnt:aDialogs[1],,,.F.,.F.,.F.,.T.)
	_oGetEtqVolume := TGet():New(015,034,{|u| If(PCount()>0,_cEtqVolume:=u,_cEtqVolume)},_oFldConfEnt:aDialogs[1],048,008,_cMskEtiq,{|| (Vazio()) .Or. (sfVldVolume(@_oGetEtqVolume)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtqVolume",,)
	_oGetEtqVolume:bWhen := {|| (_lCtrVolume) .And. ( ! _lEtqClient ) }
	_oGetEtqVolume:lReadOnly := ( ! _lNovoVolume )

	// conteudo/status do palete -  Removido David 09/04 para inclusão de um combobox
	_oCmbContPlt := TComboBox():New(027,034,{|u| If(PCount()>0,_cStatusPlt:=u,_cStatusPlt)},{"V=Vazio","T=Total","P=Parcial"},048,008,_oFldConfEnt:aDialogs[1],,,,,,.T.,,"",,,,,,,_cStatusPlt)
	_oCmbContPlt:bWhen := {|| .F. }
	_oCmbContPlt:Hide()

	// opcoes de estoque a opção para alterar está no submenu
	_oSayCodEst := TSay():New(029,003,{ || "Tp.Estoque: " + _cDescTpEstoque},_oFldConfEnt:aDialogs[1],,,.F.,.F.,.F.,.T.)

	// se controle por agrupadora/volume
	If (_lCtrVolume) .And. (Len(_aOpcoesKit) != 0)
		// opcoes de Kit
		_oSayCodKit := TSay():New(041,003,{||"Agrupadora"},_oFldConfEnt:aDialogs[1],,,.F.,.F.,.F.,.T.)
		_oCmbCodKit := TComboBox():New(039,034,{|u| If(PCount()>0,_cSeqKitSelec:=u,_cSeqKitSelec)},_aOpcoesKit,080,008,_oFldConfEnt:aDialogs[1],,,,,,.T.,,"",,,,,,,_cSeqKitSelec)
		_oCmbCodKit:bWhen := {|| _lCtrVolume }
		_oCmbCodKit:bChange := {|| sfDadosAgrup() }

		// browse com a listagem dos produtos/componentes do kit selecionado
		_oBrwCompKit := MsNewGetDados():New(053,003,102,114,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aItCompKit),'AllwaysTrue()','','AllwaysTrue()',_oFldConfEnt:aDialogs[1],_aHdCompKit,_aItCompKit)

	ElseIf ( ! _lCtrVolume ) .Or. ((_lCtrVolume) .And. (Len(_aOpcoesKit) == 0))
		// browse com a listagem dos produtos conferidos
		_oBrwConferencia := MsNewGetDados():New(041,003,102,114,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsConf),'AllwaysTrue()','','AllwaysTrue()',_oFldConfEnt:aDialogs[1],_aHeadConf,_aColsConf)

	EndIf

	// informacoes do produto lido
	_oSayCodProd := TSay():New(106,003,{||"Produto"},_oFldConfEnt:aDialogs[1],,,.F.,.F.,.F.,.T.)

	If (_lEtqIdInt) // etiqueta interna
		_oGetCodProd := TGet():New(104,034,{|u| If(PCount()>0,_cEtiqProd:=u,_cEtiqProd)},_oFldConfEnt:aDialogs[1],050,008,_cMskEtiq,{|| (Vazio()) .Or. (sfVldProd(_cTpIdEtiq)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtiqProd",,)

	ElseIf (_lEtqIdEAN) .Or. (_lEtqCod128) .Or.  (_lEtqIdDUN) .Or. (_lEtqClient)  // ean 13 / code 128 / DUN14 / CLIENTE
		_oGetCodProd := TGet():New(104,034,{|u| If(PCount()>0,_cEtqCodBar:=u,_cEtqCodBar)},_oFldConfEnt:aDialogs[1],080,008, _cMskCodBar, {|| (Vazio()) .Or. (sfVldProd(_cTpIdEtiq)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtqCodBar",,)

	EndIf


	// -- SEGUNDA PASTA (QUANDO HOUVER)--

	If (_lCtrVolume) .And. (Len(_aOpcoesKit) != 0)
		// browse com a listagem dos produtos conferidos
		_oBrwConferencia := MsNewGetDados():New(000,000,600,600,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsConf),'AllwaysTrue()','','AllwaysTrue()',_oFldConfEnt:aDialogs[2],_aHeadConf,_aColsConf)
		_oBrwConferencia:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	EndIf

	// volta o foco para o ID Palete
	If (_lIdPltAuto)
		If (_lCtrVolume)
			If (_lEtqIdEAN) .Or. (_lEtqCod128) .Or.  (_lEtqIdDUN) // ean 13 / code 128 / DUN14
				_oGetEtqVolume:SetFocus()
			ElseIf (_lEtqClient) // CLIENTE
				_oGetCodProd:SetFocus()
			EndIf
		Else
			_oGetCodProd:SetFocus()
		EndIf
	ElseIf ( ! _lIdPltAuto )
		_oGetNrPalete:SetFocus()
	EndIf

	// ativa a tela
	_oWmsConfEntr:Activate(,,,.F.,{|| _lOk },,)

	// zera teclas de atalho
	SetKey(VK_F7,{|| Nil})
	SetKey(VK_F8,{|| Nil})

Return


// ** funcao para filtrar os itens já conferidos do servico/nota selecionado, conforme codigo do operador
Static Function sfSelDados(mvPltauto)
	// area inicial do SX3
	Local aAreaSX3 := SX3->(GetArea())
	// campos para o select
	Local _cQuery := ""
	Local nX := 0

	Default mvPltauto := ""

	// reinicia variaveis dos itens
	_aColsConf := {}

	// abre tebela de conferencia
	dbSelectArea("Z07")

	// monta a query para buscar os itens já conferidos
	_cQuery := " SELECT SUM(Z07_QUANT) Z07_QUANT, Z07_PRODUT, B1_DESC, Z07_NUMSER, Z07_PALLET, Z07_ETQVOL, "
	// segunda unidade de medida
	_cQuery += " SUM(Z07_QTSEGU) Z07_QTSEGU, "
	// controle de deletado
	_cQuery += " '.F.' AS IT_DEL "
	// tabela de itens conferidos
	_cQuery += " FROM "+RetSqlTab('Z07')+" (nolock) "
	// cadastro de produtos
	_cQuery += " LEFT JOIN "+RetSqlTab('SB1')+" (nolock)  ON "+RetSqlCond("SB1")+" AND B1_COD = Z07_PRODUT "
	// filtros
	_cQuery += " WHERE "+RetSqlCond("Z07")
	_cQuery += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	_cQuery += " AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
	_cQuery += " AND Z07_NRCONT = '"+_cNrContagem+"' "
	// somente que nao C-EM CONFERENCIA
	_cQuery += " AND Z07_STATUS IN ('C','D') "
	If (mvPltauto == "AUTO")
		_cQuery += " AND Z07_PALLET = '" + _cIdPltAuto + "' "
	EndIf
	// agrupamento de informacoes
	_cQuery += " GROUP BY Z07_PRODUT, B1_DESC, Z07_PALLET, Z07_ETQVOL, Z07_NUMSER "
	// ordem dos dados
	_cQuery += " ORDER BY Z07_PALLET, Z07_ETQVOL, Z07_PRODUT "

	MemoWrit("c:\query\twmsa010_sfSelDados.txt", _cQuery)

	// atualiza os dados do vetor
	_aColsConf := U_SqlToVet(_cQuery)

	// atualiza os itens do browse
	If (_oBrwConferencia <> nil)
		_oBrwConferencia:aCols := aClone(_aColsConf)
		_oBrwConferencia:Refresh(.T.)
	EndIf

	// atualiza dados do kit
	If (_lCtrVolume)
		sfDadosAgrup()
	EndIf

	// restaura posicao inicial
	RestArea(aAreaSX3)

Return(.T.)

// ** funcao para validacao do id do palete
Static Function sfVldPalete()
	// variavel de retorno
	local _lRet := .T.
	local _cQryPalete

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11")+_cIdPalete ))
			U_FtWmsMsg("Identificador do palete inválido!","ATENCAO")
			// limpa o codigo do produto
			//_cCodProd := Space(_nTamCodPrd)
			_lRet := .F.
		EndIf
	EndIf

	// valida o tipo da etiqueta lida
	If (_lRet)
		If (Z11->Z11_TIPO != "03")
			U_FtWmsMsg("Tipo de etiqueta inválida!","ATENCAO")
			// limpa o codigo do produto
			//_cCodProd := Space(_nTamCodPrd)
			_lRet := .F.
		EndIf
	EndIf

	// verifica se o palete esta em uso
	If (_lRet)

		_lRet := (U_FtQuery("SELECT COUNT(*) QTD FROM "+RetSqlName("SDB")+" SDB (nolock)  WHERE "+RetSqlCond("SDB")+" AND DB_ESTORNO = '' AND DB_ZPALLET = '"+_cIdPalete+"' ") == 0)

		If (!_lRet)
			U_FtWmsMsg("Palete já está em uso.","ATENCAO")
		EndIf

	EndIf

	// valida se a etiqueta do palete ja foi conferido
	If (_lRet)

		_cQryPalete := "SELECT COUNT(*) IT_PALETE "
		_cQryPalete += "FROM "+RetSqlName("Z07")+" Z07 (nolock)  "
		// filtros
		_cQryPalete += "WHERE "+RetSqlCond("Z07")+" "
		_cQryPalete += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		_cQryPalete += "AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
		_cQryPalete += "AND Z07_NRCONT = '"+_cNrContagem+"' "
		_cQryPalete += "AND Z07_PALLET = '"+_cIdPalete+"' "
		//_cQryPalete += "AND Z07_STATUS = 'F' "

		If (U_FtQuery(_cQryPalete) > 0)
			U_FtWmsMsg("Palete já endereçado!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	If (_lRet)
		// define o codigo do unitizador
		_cCodUnit := Z11->Z11_UNITIZ
		// atualiza a quantidade de leitura
		RecLock("Z11")
		Z11->Z11_QTDLEI += 1
		Z11->(MsUnLock())
		// atualiza novo palete
		_lNovoPalete := .F.
		// atualiza objetos
		_oGetNrPalete:lReadOnly := (!_lNovoPalete)
		//_oGetCodProd:lReadOnly  := (_lNovoPalete)
		// foco no objeto ID do produto
		_oGetCodProd:SetFocus()
	EndIf

Return(_lRet)

// ** funcao para validacao do codigo do produto digitado (lido)
Static Function sfVldProd(mvTpIdEtiq)
	Local _cQuery := ""

	// controle de retorno
	local _lRet := .T.
	// num seq do documento de entrada
	local _cNumSeq := ""
	// num seq temporarios (para validacao)
	local _cTmpNumSeq := ""
	local _aTmpNumSeq := {}
	local _nTmpNumSeq := 0

	// RECNO do Z07
	local _nRecnoZ07 := 0

	// update do status do conteudo do palete
	local _cQryZ07

	// chave de pesquisa
	local _cChvPesq := ""

	// quantidade maxima de unidades/caixas por palete
	local _nMaxVlmPlt := 0

	// quantidade maxima de unidades por caixas/volume
	local _nQtdMaxVolume := 0

	// Retorno Quantidade de Paletes
	Local _aRetPal := {}

	// Total de Paletes
	Local _nTotPlt := 0

	// quant palete cheio
	local _nQtdPltChe := 0

	// quant palete fracionado
	local _nQtdPltFra := 0

	// verifica tipo de conferencia do produto conforme tabela Z04 se é por Palete ou Quantidade.(P = Palete | Q = Quantidade)
	Local _cTipConf := ""

	// id palete temporario
	local _cTmpIdPlt := ""

	// multiplo NumSeq
	local _lMultNumSeq := .F.

	// controle por busca e saldo de numseq
	local _nTipoBusca := 0

	// Quantidade padrão do item a ser conferido
	local _nQuant := 0

	// Arrays auxiliares produtos Sumitomo
	local aProdSum	:= {}
	local aTmpSum	:= {}
	local v
	local _cUpd

	// Array produtos Sumitomo
	private _aColsSum	:= {}


	// id palete temporario
	If (_lIdPltAuto)
		_cTmpIdPlt := IIf(Empty(_cIdPalete), _cIdPltAuto, _cIdPalete)
	ElseIf ( ! _lIdPltAuto)
		_cTmpIdPlt := _cIdPalete
	EndIf

	If (_lEtqIdInt) // ident interna
		_cChvPesq := _cEtiqProd
	ElseIf (_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIdDUN) .Or. (_lEtqClient) // ean 13 / code128 / DUN14 / CLIENTE
		_cChvPesq := _cEtqCodBar
	EndIf

	// valida conteudo da etiqueta
	If (_lRet) .And. (((_lEtqIdInt) .And. Empty(_cEtiqProd)) .Or. (((_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIdDUN) .Or. (_lEtqClient)) .And. Empty(_cEtqCodBar)))
		U_FtWmsMsg("É necessário informar a etiqueta do produto!","ATENCAO")
		_lRet := .F.
	EndIf

	// controle por volume
	If (_lRet) .And. ( ! _lEtqClient ) .And. ((_lCtrVolume) .And. (Empty(_cEtqVolume)))
		U_FtWmsMsg("É necessário informar a etiqueta do volume!","ATENCAO")
		_lRet := .F.
	EndIf

	// valida o tipo de estoque
	If (_lRet) .And. (Empty(_cTpEstoque))
		U_FtWmsMsg("É necessário informar o tipo de estoque!","ATENCAO")
		_lRet := .F.
	EndIf

	// realiza a pesquisa do produto
	If (_lRet) .And. ( ! U_FtCodBar(_cChvPesq, @_cCodProd, @_lInfManual, @_cNumSeq, mvTpIdEtiq, _cCodCliFor, @_nQuant, @_lNumSerie) )
		// variavel de retorno
		_lRet := .F.
	EndIf

	// quando for Etiqueta EAN / CODE128 / DUN14 e não for OS do tipo pré-conferencia (sem documento/nota fiscal), pesquisa o numseq para relacionar
	If (_lRet) .And. ((_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIdDUN) .Or. (_lEtqClient) ) .And. (Empty(_cNumSeq)) .AND. !(_lPreConf)

		// monta a query
		_cQuery := " SELECT Z04_NUMSEQ "
		// itens/mercadorias relacionadas a carga
		_cQuery += " FROM " + RetSqlTab("Z04") + " (nolock) "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z04")
		// nr do CESV
		_cQuery += " AND Z04_CESV   = '" + _cNumCESV + "' "
		// se for kit, valida a sequencia do kit selecionado
		If ( ! Empty(_cSeqKitSelec) )
			_cQuery += " AND Z04_SEQKIT = '" + _cSeqKitSelec + "' "
		EndIf
		// codigo do produto
		_cQuery += " AND Z04_PROD   = '" + _cCodProd + "' "

		memowrit("c:\query\twmsa010_sfVldProd_1.txt", _cQuery)

		// atualiza variavel temporaria
		_aTmpNumSeq := U_SqlToVet(_cQuery)

		// verifica se o mesmo produto esta repetido na nota fiscal (multiplos numseq)
		_lMultNumSeq := (Len(_aTmpNumSeq) > 1)

		// atualiza numseq temporario
		If (Len(_aTmpNumSeq) != 0)
			_cTmpNumSeq := _aTmpNumSeq[1]
		EndIf

		// valida NumSeq - obs: quando for aviso de recebimento de cargas, o NUMSEQ é em branco
		If ( ! _lDevMerc ) .And. (Empty(_cTmpNumSeq))
			// mensagem
			U_FtWmsMsg("Identificador do produto não pertence ao Processo ou Kit!","ATENCAO")
			// variavel de controle
			_lRet := .F.
		Else
			// atualiza numseq
			_cNumSeq := _cTmpNumSeq
		EndIf
	EndIf

	// verifica se a etiqueta/numseq faz parte da nota fiscal em conferencia
	If (_lRet) .AND. !(_lPreConf)
		// monta query
		_cQuery := " SELECT COUNT(*) QTD_ITEM "
		// itens/mercadorias relacionadas a carga
		_cQuery += " FROM "+RetSqlTab("Z04")+" (nolock) "
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("Z04")
		// nr do CESV
		_cQuery += " AND Z04_CESV   = '"+_cNumCESV+"' "
		// valida o NumSeq
		_cQuery += " AND Z04_NUMSEQ = '"+_cNumSeq+"' "
		// se for kit, valida a sequencia do kit selecionado
		If ( ! Empty(_cSeqKitSelec))
			_cQuery += "AND Z04_SEQKIT = '"+_cSeqKitSelec+"' "
		EndIf
		// codigo do produto
		_cQuery += "AND Z04_PROD   = '" + _cCodProd + "' "

		memowrit("c:\query\twmsa010_sfVldProd_2.txt", _cQuery)

		// se nao houver registros, a etiqueta eh de outro processo
		If (U_FtQuery(_cQuery) == 0)
			// mensagem
			U_FtWmsMsg("Identificador do produto não pertence ao processo!","ATENCAO")
			// variavel de controle
			_lRet := .F.
		EndIf

	EndIf

	// atualiza descricao do produto
	_cDscProd := SB1->B1_DESC

	// valido novamente se o produto controla lote
	If ( _lRet ) .And. ( _lLotAtivo ) .And. ( ! Rastro( _cCodProd ) )
		// mensagem
		U_FtWmsMsg( "Controle de Lote desabilitado para o produto: " + _cCodProd + ". Favor verificar.","Atenção")
		// variavel de controle
		_lRet := .F.
	EndIf

	// valido se o cliente controla número de serie mas no produto está desabilitado
	If ( _lRet ) .And. (_lSerieAtv) .AND. !( _lNumSerie )
		// mensagem
		U_FtWmsMsg( "Controle de número de série desabilitado para o produto: " + _cCodProd + ". Favor verificar.","Atenção")
		// variavel de controle
		_lRet := .F.
	EndIf

	// reinicia a variavel de quantidade
	If (!_lInfManual)
		If (_lEtqIdDUN) .Or. (_lEtqClient) // é codigo de barras multiplicador DUN14 / ou Etiqueta Cliente
			_nQtdSegUM  := IIf(_lUsoSegUM, 1, 0)
			_nQtdProd   := _nQuant
		Else                     //não é codigo de barras multiplicador
			_nQtdProd  := 1
			_nQtdSegUM := 0
		EndIf
	Else                       //informa manual, mantem zerado para forçar usuario a digitar
		_nQtdProd  := 0
		_nQtdSegUM := 0
	EndIf

	// valida se a etiqueta do produto esta em mais de um palete
	If (_lRet) .And. (_lEtqIdInt)
		_cQuery := " SELECT ISNULL(SUM(Z07_QUANT),0) IT_PRODUTO "
		_cQuery += " FROM " + RetSqlTab("Z07") + " (nolock) "
		_cQuery += " WHERE " + RetSqlCond("Z07")
		_cQuery += " AND Z07_ETQPRD  = '"+_cEtiqProd+"' "
		_cQuery += " AND Z07_PALLET != '"+_cTmpIdPlt+"' "
		_cQuery += " AND Z07_NRCONT  = '"+_cNrContagem+"' "

		memowrit("c:\query\twmsa010_sfVldProd_4.txt", _cQuery)

		// se a quantidade nao eh informada, valida o palete
		If (U_FtQuery(_cQuery) > 0)
			// mensagem
			U_FtWmsMsg("Identificador do produto já está em uso em outro palete!","ATENCAO")
			// variavel de controle
			_lRet := .F.
		EndIf
	EndIf

	// verifica se a etiqueta ja foi lida neste palete
	If (_lRet) .And. (_lEtqIdInt)
		_cQuery := " SELECT Z07.R_E_C_N_O_ Z07RECNO "
		_cQuery += " FROM "+RetSqlTab("Z07") + " (nolock) "
		_cQuery += " WHERE "+RetSqlCond("Z07")
		_cQuery += " AND Z07_ETQPRD = '"+_cEtiqProd+"' "
		_cQuery += " AND Z07_PALLET = '"+_cTmpIdPlt+"' "
		_cQuery += " AND Z07_NRCONT = '"+_cNrContagem+"' "

		memowrit("c:\query\twmsa010_sfVldProd_5.txt", _cQuery)

		// se a quantidade nao eh informada, valida o palete
		If ( ! _lInfManual )
			If ((_nRecnoZ07 := U_FtQuery(_cQuery)) > 0)
				// mensagem
				U_FtWmsMsg("Etiqueta já conferida!","ATENCAO")
				// variavel de controle
				_lRet := .F.
			EndIf
		ElseIf (_lInfManual)
			//_nQtdProd := U_FtQuery(_cQuery)
		EndIf
	EndIf

	// verifica quantidade de etiquetas por palete
	If (_lRet) .And. (_lEtqIdInt) .And. (_lEtqUnqPlt)

		// monta query
		_cQuery := " SELECT COUNT(DISTINCT Z07_ETQPRD) QTD_ETQ "
		// conferencia do palete
		_cQuery += " FROM "+RetSqlTab("Z07") + " (nolock) "
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("Z07")
		// palete atual
		_cQuery += " AND Z07_PALLET = '"+_cTmpIdPlt+"' "
		// nr de contagens
		_cQuery += " AND Z07_NRCONT = '"+_cNrContagem+"' "

		memowrit("c:\query\twmsa010_sfVldProd_6.txt", _cQuery)

		// se ja tem etiqueta no palete, bloqueia processo
		If (U_FtQuery(_cQuery) > 0)
			// mensagem
			U_FtWmsMsg("Não é permitido múltiplas etiquetas por palete/bobina!","ATENCAO")
			// variavel de controle
			_lRet := .F.
		EndIf

	EndIf

	// verifica produtos distintos no mesmo palete
	If (_lRet) .And. ( ! _lPltMisto )

		// monta query
		_cQuery := " SELECT COUNT(DISTINCT Z07_PRODUT) Z07_PRODUT "
		// conferencia do palete
		_cQuery += " FROM " + RetSqlTab("Z07") + " (nolock) "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z07")
		// palete atual
		_cQuery += " AND Z07_PALLET = '"+_cTmpIdPlt+"' "
		// nr de contagens
		_cQuery += " AND Z07_NRCONT = '"+_cNrContagem+"' "
		// codigo do produto
		_cQuery += " AND Z07_PRODUT != '" +_cCodProd+ "' "

		memowrit("c:\query\twmsa010_sfVldProd_7.txt", _cQuery)

		// se ja tem etiqueta no palete, bloqueia processo
		If (U_FtQuery(_cQuery) > 0)
			// mensagem
			U_FtWmsMsg("Não é permitido múltiplos produtos por palete/bobina!","ATENCAO")
			// variavel de controle
			_lRet := .F.
		EndIf

	EndIf

	// valida se a etiqueta do cliente esta em mais de um palete
	If (_lRet) .And. (_lEtqClient)

		// prepara query
		_cQuery := " SELECT ISNULL(SUM(Z07_QUANT),0) IT_PRODUTO "
		_cQuery += " FROM " + RetSqlTab("Z07") + " (nolock) "
		_cQuery += " WHERE " + RetSqlCond("Z07")
		_cQuery += " AND Z07_ETQCLI  = '" + _cEtqCodBar + "' "

		// se a quantidade nao eh informada, valida o palete
		If (U_FtQuery(_cQuery) > 0)
			// mensagem
			U_FtWmsMsg("Etiqueta informada já conferida anteriormente.","ATENCAO")
			// variavel de controle
			_lRet := .F.
		EndIf

	EndIf

	// verifica tipos de estoques distintos no mesmo palete
	If (_lRet)

		// monta query
		_cQuery := " SELECT COUNT(DISTINCT Z07_TPESTO) Z07_TPESTO "
		// conferencia do palete
		_cQuery += " FROM " + RetSqlTab("Z07") + " (nolock) "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z07")
		// palete atual
		_cQuery += " AND Z07_PALLET = '"+_cTmpIdPlt+"' "
		// nr de contagens
		_cQuery += " AND Z07_NRCONT = '"+_cNrContagem+"' "
		// codigo do produto
		_cQuery += " AND Z07_TPESTO != '" + _cTpEstoque + "' "

		memowrit("c:\query\twmsa010_sfVldProd_8.txt", _cQuery)

		// se ja tem etiqueta no palete, bloqueia processo
		If (U_FtQuery(_cQuery) > 0)
			// mensagem
			U_FtWmsMsg("Não é permitido múltiplos Tipos de Estoque por palete/bobina!","ATENCAO")
			// variavel de controle
			_lRet := .F.
		EndIf

	EndIf

	// controle para integração entre sistema GWS Sumitomo x Totvs (projeto 2019)
	// para verificar se o produto exige leitura de barcode
	// Redmine #414
	// Se for cliente Sumitomo e o produto estiver com leitura de barcode ativa
	If (_lRet) .And. (_cCodCliFor == "000316") .AND. (lSumibar) .And. (Posicione("SB1",1,xFilial("SB1") + AllTrim(_cCodProd),"B1_ZNUMSER") == "S")
		_lRet := EtqSumi()
	ElseIf (_lRet) .And. ((_lInfManual) .Or. (_lLotAtivo) .OR. (_lSerieAtv) )  // caso configurado no produto para informar quantidade manual, lote ou numero de serie
		// tela para informar informações Adicionais
		sfInfAdici()
		_aColsSum	:= {}
	EndIf

	// em caso de multiplos numseq na mesma nota, apos informar dados adicionais, valida o NumSeq correto
	If (_lRet) .And. (_lMultNumSeq) .And. ((_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIdDUN) .Or. (_lEtqClient)) .AND. !(_lPreConf)

		// zera variaveis
		_cNumSeq    := ""
		_cTmpNumSeq := ""

		// executa duas vezes, uma para procurar informacao exata, outra para controle de saldo do numseq
		For _nTipoBusca := 1 to 2

			// se encontrou numseq correto, sai do loop
			If ( ! Empty(_cNumSeq) )
				Exit
			EndIf

			// monta a query
			_cQuery := " SELECT Z04_NUMSEQ, "
			_cQuery += "        Z04_LOTCTL, "
			_cQuery += "        Z04_QUANT, "
			_cQuery += "       (SELECT Isnull(Sum(Z07_QUANT), 0) "
			_cQuery += "        FROM   "+RetSqlTab("Z07")+" (nolock) "
			_cQuery += "        WHERE  "+RetSqlCond("Z07")
			_cQuery += "               AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
			_cQuery += "               AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
			_cQuery += "               AND Z07_NRCONT = '"+_cNrContagem+"' "
			_cQuery += "               AND Z07_NUMSEQ = Z04_NUMSEQ) Z07_QUANT "
			// itens/mercadorias relacionadas a carga
			_cQuery += " FROM   "+RetSqlTab("Z04")+" (nolock) "
			// filtro padrao
			_cQuery += " WHERE  "+RetSqlCond("Z04")
			// nr do CESV
			_cQuery += "        AND Z04_CESV = '"+_cNumCESV+"' "
			// codigo do produto
			_cQuery += "        AND Z04_PROD = '"+_cCodProd+"' "
			// se for kit, valida a sequencia do kit selecionado
			If ( ! Empty(_cSeqKitSelec) )
				_cQuery += "        AND Z04_SEQKIT = '"+_cSeqKitSelec+"' "
			EndIf
			// compara lote
			If (_nTipoBusca==1) .And. (_lLotAtivo) .And. (_lLotObrEnt)
				_cQuery += "        AND Z04_LOTCTL = '" +_cEtqLote+ "' "
			EndIf

			memowrit("c:\query\twmsa010_sfVldProd_9_"+AllTrim(Str(_nTipoBusca))+"_multnumseq.txt", _cQuery)

			// atualiza variavel temporaria
			_aTmpNumSeq := U_SqlToVet(_cQuery)

			// varre as opcoes de numseq para uso conforme saldo
			For _nTmpNumSeq := 1 to Len(_aTmpNumSeq)

				// compara saldo utilizado, com saldo esperado
				If (_aTmpNumSeq[_nTmpNumSeq][4] < _aTmpNumSeq[_nTmpNumSeq][3])
					// atualiza numseq temporario
					_cTmpNumSeq := _aTmpNumSeq[_nTmpNumSeq][1]
					_cNumSeq    := _cTmpNumSeq
					// sai do Loop
					Exit
				EndIf

				// proximo numseq
			Next _nTmpNumSeq

			// proximo tipo de buscao
		Next _nTipoBusca

		// valida NumSeq - obs: quando for aviso de recebimento de cargas, o NUMSEQ é em branco
		If ( ! _lDevMerc ) .And. (Empty(_cTmpNumSeq))
			// mensagem
			U_FtWmsMsg("Identificador do produto não pertence ao Processo ou Kit!","ATENCAO")
			// variavel de controle
			_lRet := .F.
		EndIf

	EndIf

	// quantidade maxima de volumes para unitizar
	If (_lRet) .And. (_lVldCapacPlt)

		// pesquisa o lastro e camada do produto
		// estrutura do retorno
		// 1-Quantidade Total de Palete
		// 2-Quantidade de Paletes Cheios
		// 3-Quantidade de Paletes Fracionados
		// 4-Quantidade Maxima de SKU/Volumes por Palete
		// 5-Tipo do Calculo (Q-Quant Unitarios / P-Quant Palete Informado)
		_aRetPal := U_FtWmsNorma(_cCodProd, _cArmzServ, Nil, Nil, Nil, _cNumCESV, _cNumSeq, _cSeqKitSelec, Nil, Nil)

		// atualiza variavel de controle de acordo com o calculo da funcao FtWmsNorma
		_nTotPlt       := _aRetPal[1]
		_nQtdPltChe    := _aRetPal[2]
		_nQtdPltFra    := _aRetPal[3]
		_nMaxVlmPlt    := _aRetPal[4]
		_cTipConf      := _aRetPal[5]

	EndIf

	//Validar quantidade maxima de produto no palete.
	If (_lRet) .And. (_lVldCapacPlt) .And. (_cTipConf == "Q")
		// verifica a quantidade maximo de produto no palete
		If (_lRet) .And. ( ! sfCapacPlt(_nMaxVlmPlt, _lCtrVolume,_cTipConf ) )
			// variavel de retorno
			_lRet := .F.
		EndIf
	Else
		_cStatusPlt := "T"
	EndIf

	// se validou e a quantidade foi informada
	If (_lRet) .And. (_nQtdProd > 0)
		// quando a quantidade é digitada, altera o registro
		If (_lInfManual) .And. (_nRecnoZ07 > 0)
			dbSelectArea("Z07")
			RecLock("Z07")
			Z07->Z07_QUANT  := _nQtdProd
			Z07->Z07_QTSEGU := _nQtdSegUM
			Z07->(MsUnLock())
		Else
			// insere quantidade lida na relacao de itens
			dbSelectArea("Z07")
			RecLock("Z07",.T.)
			Z07->Z07_FILIAL	:= xFilial("Z07")
			Z07->Z07_NUMOS	:= _cNumOrdSrv
			Z07->Z07_SEQOS	:= _cSeqOrdSrv
			Z07->Z07_CLIENT	:= _cCodCliFor
			Z07->Z07_LOJA	:= _cLojCliFor
			Z07->Z07_ETQPRD	:= _cEtiqProd
			Z07->Z07_PRODUT	:= _cCodProd
			Z07->Z07_NUMSEQ	:= _cNumSeq
			Z07->Z07_LOCAL	:= _cArmzServ
			Z07->Z07_QUANT	:= _nQtdProd
			Z07->Z07_QTSEGU := _nQtdSegUM
			Z07->Z07_NRCONT	:= _cNrContagem
			Z07->Z07_USUARI := _cCodOper
			Z07->Z07_DATA	:= Date()
			Z07->Z07_HORA	:= Time()
			Z07->Z07_PLTCLI := _cPltClie
			Z07->Z07_LOTCTL := _cEtqLote
			Z07->Z07_VLDLOT := _dVldLote
			Z07->Z07_PALLET	:= _cTmpIdPlt
			Z07->Z07_UNITIZ := _cCodUnit
			Z07->Z07_STATUS	:= "C" // C-EM CONFERENCIA / D-CONFERIDO/DISPONIVEL / M-EM MOVIMENTO / A-ARMAZENADO
			Z07->Z07_ENDATU	:= _cDocaSrv
			Z07->Z07_CODBAR := _cEtqCodBar
			Z07->Z07_TPESTO := _cTpEstoque
			Z07->Z07_CAMPLT := _nPltCamada
			Z07->Z07_ETQVOL := _cEtqVolume
			Z07->Z07_NUMSER := _cNumSerie
			Z07->Z07_DTSERI := _dDtSeri

			// dados complementares quando uso de Agrupadora
			If ( ! Empty(_cEtqVolume)) .And. ( ! Empty(_cSeqKitSelec)) .And. (Len(_aKitDispon) > 0)
				Z07->Z07_EMBALA := sfRetTpEmbala(_cSeqKitSelec) // retorna a embalagem por kit
				Z07->Z07_SEQKIT := _cSeqKitSelec
				Z07->Z07_CODKIT := _aKitDispon[aScan(_aKitDispon,{|x| x[1] == _cSeqKitSelec })][2]
			EndIf

			// grava dados da etiqueta do cliente
			If ( _lEtqClient )
				Z07->Z07_ETQCLI := _cEtqCodBar
			EndIf

			// grava dados
			Z07->(MsUnLock())
		EndIf

		// atualiza a quantidade de leitura
		If ( ! _lEtqClient )
			RecLock("Z11")
			Z11->Z11_QTDLEI += 1
			MsUnLock()
		EndIf

		// atualiza o status do conteudo do palete
		If (_lVldCapacPlt)

			// monta SQL para atualizar o status do conteudo do palete
			_cQryZ07 := " UPDATE " + RetSqlName("Z07")
			// ID do palete
			_cQryZ07 += " SET Z07_CONTEU = '"+_cStatusPlt+"' " // V=Vazio / T=Total / P=Parcial
			// filtro padrao
			_cQryZ07 += " WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
			// filtro por OS
			_cQryZ07 += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
			// cliente e loja
			_cQryZ07 += " AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
			// nr de contagem
			_cQryZ07 += " AND Z07_NRCONT = '"+_cNrContagem+"' "
			// ID palete
			_cQryZ07 += " AND Z07_PALLET = '"+_cTmpIdPlt+"' "
			// status
			_cQryZ07 += " AND Z07_STATUS = 'C' "

			// executa o update
			TcSQLExec(_cQryZ07)

		EndIf

		// atualiza os dados do browse
		sfSelDados("AUTO")

	EndIf

	// se houver atualizações de etiqueta para fazer na tabela Z56 (etiquetas cliente) - Sumitomo Barcode
	If (_lRet) .AND. ( !Empty(_aColsSum) )
		For v := 1 To Len(_aColsSum)
			//			_cUpd := " update Z56 set Z56_CODETI = '"+_cEtiqProd+"' "
			_cUpd := " update " + RetSQLName("Z56")
			_cUpd += " set Z56_CODETI = '" + _cEtiqProd + "' , Z56_OK_ENT = 'S'" 
			_cUpd += " where D_E_L_E_T_ = '' and Z56_FILIAL = '" + xFilial("Z56") + "'"
			_cUpd += " and Z56_CODCLI = '" + _cCodCliFor     + "' "
			_cUpd += " and Z56_ETQCLI = '" + _aColsSum[v][1] + "' "

			Memowrit("c:\query\TWMSA010_update_Z56.txt", _cUpd)

			If (TCSQLExec(_cUpd) < 0)
				Memowrit("c:\query\TWMSA010_update_Z56_" + _cEtiqProd + ".txt", _cUpd)
				U_FtGeraLog(cFilAnt, "Z56", xFilial("Z56") + _cEtiqProd, "Erro ao atualizar etiquetas do cliente da OS: " + _cNumOrdSrv, "WMS", "")
				U_FtWmsMsg("Erro ao atualizar etiquetas do cliente! Informe IMEDIATAMENTE o supervisor" ,"Erro TWMSA010 - Update Z56")
			EndIf
		Next v
	EndIf

	// reinicia variaveis
	_cCodProd   := Space(_nTamCodPrd)
	_cEtqCodBar := Space(Len(_cEtqCodBar))
	_cDscProd   := ""
	_cEtiqProd  := Space(Len(_cEtiqProd))
	_cNumSerie  := Space(Len(_cNumSerie))
	_dDtSeri    := CtoD("//")
	_nPltCamada := 0

	//aumenta quantidade de pallets conferidos
	IIf (_lRet , _nQtdConfPlt++, Nil)

	// foca no objeto cod produto
	_oGetCodProd:SetFocus()

	// define se limpa os campos ou não com base no parâmetro
	If ( ! _lRptLot )

		_cEtqLote := Space(Len(_cEtqLote))
		_dVldLote := CtoD("//")

	EndIf

	// se não controlar validade, já trás o campo preenchido
	If ( ! _lCtrVld )

		// define a data como data atual
		_dVldLote := CtoD("31/12/2049")

	EndIf

	// se parametro de volume automatico ativo, já dispara "novo volume"
	If (_lAutoVol)
		_oBt01NvVlm:Click()
	EndIf

Return(.T.)


// ** funcao para informar a informações adicionais(Quantidade,Palete Cliente,Lote)
Static Function sfInfAdici()
	// objetos
	local _oBtnFoco1
	local _oScrInfAdi
	// controle para nao fechar a tela
	Local _lRetOk := .F.

	// controles para desenhar o componente get
	local _nLinha  := 5    // linha inicial 
	local _nSaltol := 20   // incremento de linha

	// primeiro campo criado, para posicionar o foco
	local _cCampo := ""

	// reinicia segunda unidade de medida
	If (_lCtrVolume) .And. (_lUsoSegUM) .And. (SB1->B1_CONV == 0)
		_nQtdSegUM := 1
	Else
		_nQtdSegUM := 0
	EndIf

	// monta a tela para informa a quantidade
	_oWndInfQuant := MSDialog():New(020,020,270,220,"Informações Adicionais",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlInfQtdCab := TPanel():New(000,000,nil,_oWndInfQuant,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlInfQtdCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpInfQtdOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRetOk := sfValIndAd(), _oWndInfQuant:End() },_oPnlInfQtdCab,"Ok",,.T.)
	_oBmpInfQtdOk:Align := CONTROL_ALIGN_LEFT

	// scroll principal com todos as campos disponiveis
	_oScrInfAdi := TScrollBox():New(_oWndInfQuant,000,000,_aSizeDlg[2],_aSizeDlg[1],.T.,.T.,.T.)
	_oScrInfAdi:Align := CONTROL_ALIGN_ALLCLIENT

	// campos disponiveis
	If (_lInfManual)  // se informa quantidade manual, mostra campos de quantidade
		_cCampo := "_oGetQuant"
		_oGetQuant   := TGet():New(_nLinha, 005, {|u| If(PCount()>0,_nQtdProd   :=u,_nQtdProd   )}, _oScrInfAdi, 060, 010, _cMaskQuant, {|| sfVldQuant(2) },,,_oFnt02,,,.T.,"",,                               ,.F.,.F.,,.F.,.F.,"","_nQtdProd" ,,,,,,,"Quantidade ("+SB1->B1_UM+"):"   ,1) ; _nLinha += _nSaltoL
		_oGetQtdSeg  := TGet():New(_nLinha, 005, {|u| If(PCount()>0,_nQtdSegUM  :=u,_nQtdSegUM  )}, _oScrInfAdi, 060, 010, _cMaskQuant, {|| sfVldQuant(1) },,,_oFnt02,,,.T.,"",,{|| ! Empty(SB1->B1_SEGUM)    },.F.,.F.,,.F.,.F.,"","_nQtdSegUM",,,,,,,"Qtd Seg UM ("+SB1->B1_SEGUM+"):",1) ; _nLinha += _nSaltoL
	EndIf
	If (_lLotAtivo) // se controla lote, mostra campos de lote
		IIf (Empty(_cCampo), _cCampo := "_oGetLotProd", "")
		_oGetLotProd := TGet():New(_nLinha, 005, {|u| If(PCount()>0,_cEtqLote   :=u,_cEtqLote   )}, _oScrInfAdi, 060, 010, "@!"       , {||               },,,_oFnt02,,,.T.,"",,{|| _lLotAtivo                },.F.,.F.,,.F.,.F.,"","_cEtqLote" ,,,,,,,"Lote"                           ,1) ; _nLinha += _nSaltoL
		_oGetVldLote := TGet():New(_nLinha, 005, {|u| If(PCount()>0,_dVldLote   :=u,_dVldLote   )}, _oScrInfAdi, 060, 010, ""         , {||               },,,_oFnt02,,,.T.,"",,{|| _lLotAtivo .And. _lCtrVld },.F.,.F.,,.F.,.F.,"","_dVldLote" ,,,,,,,"Dt. Validade Lote"              ,1) ; _nLinha += _nSaltoL
	EndIf
	If (_lSerieAtv) // se controla numero de serie, mostra campo
		IIf (Empty(_cCampo), _cCampo := "_oGetSerie", "")
		//		_oGetSerie   := TGet():New(_nLinha, 005, {|u| If(PCount()>0,_cNumSerie   :=u,_cNumSerie   )}, _oScrInfAdi, 060, 010, "@!"       , {|| sfVldSer()              },,,_oFnt02,,,.T.,"",,{|| _lSerieAtv                },.F.,.F.,,.F.,.F.,"","_cNumSerie" ,,,,,,,"Número Serie"    ,1) ; _nLinha += _nSaltoL
		_oGetSerie   := TGet():New(_nLinha, 005, {|u| If(PCount()>0,_cNumSerie   :=u,_cNumSerie   )}, _oScrInfAdi, 060, 010, "@!"       , {||              },,,_oFnt02,,,.T.,"",,{|| _lSerieAtv                },.F.,.F.,,.F.,.F.,"","_cNumSerie" ,,,,,,,"Número Serie"    ,1) ; _nLinha += _nSaltoL
	EndIf

	_oGetPalCli  := TGet():New(_nLinha, 005, {|u| If(PCount()>0,_cPltClie   :=u,_cPltClie   )}, _oScrInfAdi, 060, 010, "@!"       , {||               },,,_oFnt02,,,.T.,"",,                               ,.F.,.F.,,.F.,.F.,"","_cPltClie" ,,,,,,,"Plt. Clie."                     ,1) ; _nLinha += _nSaltoL
	//	_oGetPalCam  := TGet():New(_nLinha, 005, {|u| If(PCount()>0,_nPltCamada :=u,_nPltCamada )}, _oScrInfAdi, 060, 010, "@R 999"   , {||               },,,_oFnt02,,,.T.,"",,                               ,.F.,.F.,,.F.,.F.,"","_nPltCamada" ,,,,,,,"Camada no Palete"             ,1) ; _nLinha += _nSaltoL

	// seta o foco na quantidade
	&(_cCampo):SetFocus()

	// ativacao da tela com validacao
	_oWndInfQuant:Activate(,,,.T.,{|| _lRetOk })

Return

// ** função pra validar os números de série ** //
Static Function sfVldSer()
	Local _lRet := .F.

	// TODO melhorar validação do número de série
	If (Len(AllTrim( _cNumSerie)) != 11)
		_oGetSerie:SetColor(CLR_WHITE,CLR_RED)
		_oGetSerie:SetFocus()
	Else
		_lRet := .T.
		_oGetSerie:SetColor(CLR_BLACK,CLR_WHITE)
		If Empty(_cPltClie)
			_oGetPalCli:SetFocus()
		Else
			_oBmpInfQtdOk:Click()
		EndIf
	EndIf


Return(_lRet)

// ** função pra validar as informações adicinoais ** //
Static Function sfValIndAd()

	// variavel de retorno
	Local _lRet        := .T.
	Local _cQuery  := ""
	Local _cRetSql := ""

	// controle de quantidade informada
	If (_lInfManual)
		If (_nQtdProd <= 0)
			_lRet := .F.
			U_FtWmsMsg("Informar Quantidade Maior que 0!","ATENCAO")
			_oGetQuant:SetFocus()
			Return(_lRet)
		EndIf

		// validação da quantidade
		sfVldQuant(2)
	EndIf

	// se controle de lote está ativo
	If (_lLotAtivo)
		// valida se o lote foi informado
		If (Empty(_cEtqLote))
			_lRet := .F.
			// informa o usuário e retorna
			U_FtWmsMsg("Obrigatório informar Lote!","ATENCAO")
			_oGetLotProd:SetFocus()
			Return(_lRet)
		EndIf
		// valida a data do lote
		If (_lCtrVld) .And. (Empty(_dVldLote))
			_lRet := .F.
			// informa o usuário e retorna
			U_FtWmsMsg("Obrigatório informar Validade do Lote!","ATENCAO")
			_oGetVldLote:SetFocus()
			Return(_lRet)
		EndIf
	EndIf

	// se controle de número de serie está ativo
	If (_lSerieAtv)
		// valida se o número de serie foi informado
		If (Empty(_cNumSerie))
			_lRet := .F.
			// informa o usuário e retorna
			U_FtWmsMsg("Obrigatório informar número série!","ATENCAO")
			_oGetSerie:SetFocus()
			Return(_lRet)
		EndIf

		// se for cancelamento de pedido, só permite número de série conforme OS original
		IF (_cCodServ == "T03") 
			// valida se o número de série pertence a OS original
			// ao fazer a busca, já obtenho a data do SN para gravar ao confirmar o volume
			_cQuery := " SELECT Z07_DTSERI "
			_cQuery += " FROM " + RetSqlTab("Z07") + " (nolock) "
			_cQuery += " WHERE " + RetSqlCond("Z07")
			_cQuery += " AND Z07_NUMOS  = '" + _cOSOrig    +"' "
			_cQuery += " AND Z07_NUMSER = '" + _cNumSerie  +"' "

			memowrit("c:\query\twmsa010_sfValIndAd_numserie1.txt", _cQuery)
			_dDtSeri := StoD( U_FtQuery(_cQuery) )

			// se não obteve data da serie, então o serial também não esite
			If (Empty(_dDtSeri))
				// mensagem
				U_FtWmsMsg("Número de série lido não consta na OS cancelada ("+_cOSOrig+")! Verifique o número de série!","ATENÇÃO")
				_oGetSerie:SetFocus()
				Return( .F. )
			EndIf
		EndIf

		// verifica se o número de série já possui saldo em estoque (assim, caso tenha sido recebido e expedido, pode ler denovo em caso de logística reversa)
		_cQuery := " SELECT COUNT(R_E_C_N_O_) QTD          "
		_cQuery += " FROM " + RetSqlTab("Z16")
		_cQuery += " WHERE  " + RetSqlCond("Z16")
		_cQuery += "        AND Z16_NUMSER = '" + _cNumSerie  +"' "
		_cQuery += " 	    AND Z16_SALDO != 0              " // somente etiquetas que ainda não foram expedidas

		memowrit("c:\query\twmsa010_sfValIndAd_numserie2.txt", _cQuery)

		// se já existe
		If ( !Empty(U_FtQuery(_cQuery) ) )
			// mensagem
			U_FtWmsMsg("Número de série já conferido anteriormente e ainda possui saldo em estoque! Verifique e estorne se necessário","ATENÇÃO")
			_oGetSerie:SetFocus()
			_lRet := .F.
			Return(_lRet)
		EndIf

		// valida se número de série já foi lido em outra OS de conferência não finalizada (incluindo esta)
		_cQuery := " SELECT TOP 1 Z07_NUMOS                    "
		_cQuery += " FROM " + RetSqlTab("Z07")
		_cQuery += "        INNER JOIN " + RetSqlTab("Z06")
		_cQuery += "                ON " + RetSqlCond("Z06")
		_cQuery += "                   AND Z06_NUMOS = Z07_NUMOS "
		_cQuery += "                   AND Z06_STATUS NOT IN ( 'FI', 'CA')    "
		_cQuery += " WHERE " + RetSqlCond("Z07")
		_cQuery += "        AND Z07_NUMSER = '" + _cNumSerie  +"' "

		_cRetSql := AllTrim(U_FtQuery(_cQuery))
		
		// se já existe
		If ( !Empty(_cRetSql) )
			// mensagem
			U_FtWmsMsg("Número de série já conferido anteriormente na OS " + _cRetSql + CRLF + "Verifique e estorne se necessário","TWMSA010 - sfValIndAd")
			_oGetSerie:SetFocus()
			_lRet := .F.
			Return(_lRet)
		EndIf


	EndIf

	// valida fracao da segunda unidade de medida
	If (_lUsoSegUM) .And. ( ! Empty(SB1->B1_SEGUM) ) .And. (_nQtdSegUM <= 0)
		// variavel de controle
		_lRet := .F.
		// informa o usuário e retorna
		U_FtWmsMsg("Favor informar quantidade para segunda unidade de medida.","ATENCAO")
		// foco em objeto
		_oGetQuant:SetFocus()
		// retorno
		Return(_lRet)
	EndIf

	// valida fracao da segunda unidade de medida
	If (_lUsoSegUM) .And. ( ! Empty(SB1->B1_SEGUM) ) .And. (SB1->B1_CONV != 0) .And. ( Mod(_nQtdProd, SB1->B1_CONV) != 0 ) .And. ( ! _lSegUMFrac )
		// variavel de controle
		_lRet := .F.
		// informa o usuário e retorna
		U_FtWmsMsg("Favor verificar a fração entre as unidades de medidas.","ATENCAO")
		// foco em objeto
		_oGetQuant:SetFocus()
		// retorno
		Return(_lRet)
	EndIf

Return(_lRet)

// ** funcao para alterar o tipo de estoque para a conferência
Static Function sfAltTpEst()

	// objetos
	local _oBtnFoco1, _oGetTpEst, _oSayTpEst
	// controle para nao fechar a tela
	Local _lRetOk  := .F.
	// query de validação
	Local _cQryZ07 := ""
	// Variavel Temp. For
	Local _nX := 0

	// query que valida as conferências que não foram finalizadas para aquela OS
	_cQryZ07 := " SELECT COUNT(*) TOTPLT FROM "+RetSqlTab("Z07")+" (nolock) "
	_cQryZ07 += " WHERE "+RetSqlCond("Z07")
	_cQryZ07 += " AND Z07_NUMOS = '"+_cNumOrdSrv+"' "
	_cQryZ07 += " AND Z07_SEQOS = '"+_cSeqOrdSrv+"'"
	_cQryZ07 += " AND Z07_STATUS = 'C' "

	// gero txt para debug
	MemoWrit("C:\query\twmsa010_alttpest.txt", _cQryZ07)

	// valido se existe algum registro não finalizado
	If ( U_FtQuery(_cQryZ07) > 0 )
		// mensagem
		U_FtWmsMsg("Ainda há pallets em conferência para a OS selecionada! Finalize o pallet primeiro antes de mudar o tipo de estoque.","ATENCAO")
		// variavel de controle
		_lRetOk := .F.
		// retorno
		Return(_lRetOk)
	EndIf

	// monta a tela para informa a quantidade
	_oWndAltTpEst := MSDialog():New(020,020,120,200,"Tipo de Estoque",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlInfTpEstCab := TPanel():New(000,000,nil,_oWndAltTpEst,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlInfTpEstCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpInfTpEstOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRetOk := .T.,_oWndAltTpEst:End() },_oPnlInfTpEstCab,"Ok",,.T.)
	_oBmpInfTpEstOk:Align := CONTROL_ALIGN_LEFT

	// titulo
	_oSayTpEst := TSay():New(025,005,{||"Tp.Estoque:"},_oWndAltTpEst,,_oFnt02,.F.,.F.,.F.,.T.)
	// combo de opções de tipos de estoque carregados anteriormente
	_oCmbCodEst := TComboBox():New(035,005,{|u| If(PCount()>0, _cTpEstoque:=u,_cTpEstoque) },_aOpcoesEst,080,008,_oWndAltTpEst,,,,,,.T.,,"",,,,,,,_cTpEstoque)

	// ativacao da tela com validacao
	_oWndAltTpEst:Activate(,,,.T.,{|| _lRetOk })

	// caso o campo tenha sido preenchido, busca no array o correspondente e atualiza a label
	If (! Empty(_cTpEstoque))
		For _nX := 1 to Len(_aOpcoesEst)
			If (_cTpEstoque $ _aOpcoesEst[_nX])
				_cDescTpEstoque := _aOpcoesEst[_nX]
				_oSayCodEst:Refresh()
			EndIf
		Next
	EndIf

Return (.T.)

// ** funcao que calcula as unidade de medidas
Static Function sfVldQuant(mvUndRet)

	If (_nQtdProd > 0) .Or. (_nQtdSegUM > 0)
		If ( ! Empty(SB1->B1_SEGUM) ) .And. (SB1->B1_CONV>0)
			// retorna a 1a Unid Medida
			If (mvUndRet==1)
				_nQtdProd := ConvUM(SB1->B1_COD, _nQtdProd, _nQtdSegUM, mvUndRet)
				// 2a Unid Medida
			ElseIf (mvUndRet==2)
				_nQtdSegUM := ConvUM(SB1->B1_COD, _nQtdProd, _nQtdSegUM, mvUndRet)
			EndIf
		EndIf
	EndIf

Return(.T.)

// ** funcao que retorna o numero de contagens
Static Function sfRetNrCont()
	Local _cQuery := ""
	Local _cRet := ""

	_cQuery := "SELECT MAX(Z06_NRCONT) Z06_NRCONT "
	_cQuery += "FROM "+RetSqlName("Z06")+" Z06 (nolock)  "
	_cQuery += "WHERE "+RetSqlCond("Z06")+" "
	_cQuery += "AND Z06_NUMOS  = '"+_cNumOrdSrv+"' AND Z06_SEQOS = '"+_cSeqOrdSrv+"' "
	// calculo pra proxima contagem
	_cRet := U_FtQuery(_cQuery)

	// se for a primeira contagem, atualiza todos os itens da ordem de servico
	If (Val(_cRet)==0)
		// calcula a primeira contagem
		_cRet := StrZero(Val(_cRet)+1,3)

		_cQuery := "UPDATE "+RetSqlName("Z06")+" "
		_cQuery += "SET Z06_NRCONT = '"+_cRet+"' "
		_cQuery += "WHERE Z06_FILIAL = '"+xFilial("Z06")+"' AND D_E_L_E_T_ = ' ' "
		_cQuery += "AND Z06_NUMOS  = '"+_cNumOrdSrv+"' AND Z06_SEQOS = '"+_cSeqOrdSrv+"' "
		// executa o update
		TcSQLExec(_cQuery)
	EndIf

Return(_cRet)

// ** funcao para gerar um novo palete
Static Function sfNovoPalete(mvGeraNovo)
	// query
	local _cQryZ07
	// id palete temporario
	local _cTmpIdPlt

	// mensagem de palete parcial
	If (mvGeraNovo) .And. (_cStatusPlt == "P")
		U_FtWmsMsg("ATENÇÃO: Palete Parcial!","ATENCAO")
	EndIf

	If (mvGeraNovo) .And. ( ! U_FtYesNoMsg("Confirma novo palete ?"))
		Return(.F.)
	EndIf

	// gera ID palete automatico?
	If (mvGeraNovo) .And. (_lIdPltAuto)
		// ID palete automatico
		If (Empty(_cIdPalete))

			// funcao generica para geracao do Id Palete
			_cIdPalete := U_FtGrvEtq("03",{_cUnitPdr,""})
			// define o codigo do unitizador
			_cCodUnit := Z11->Z11_UNITIZ

			// ID atual do palete
			_cTmpIdPlt := _cIdPltAuto

			// usado quando for completar um palete
		ElseIf ( ! Empty(_cIdPalete))

			// pesquisa o palete
			dbSelectArea("Z11")
			Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
			Z11->(dbSeek( xFilial("Z11")+_cIdPalete ))
			// define o codigo do unitizador
			_cCodUnit := Z11->Z11_UNITIZ

			// ID atual do palete
			_cTmpIdPlt := _cIdPalete

		EndIf

		// monta SQL para atualizar o novo numero do palete
		_cQryZ07 := "UPDATE "+RetSqlName("Z07")+" "
		// ID do palete
		_cQryZ07 += "SET Z07_PALLET = '"+_cIdPalete+"', "
		// unitizador
		_cQryZ07 += "Z07_UNITIZ = '"+_cCodUnit+"' "
		// filtro padrao
		_cQryZ07 += "WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
		// filtro por OS
		_cQryZ07 += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		// cliente e lojga
		_cQryZ07 += "AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
		// nr contagem
		_cQryZ07 += "AND Z07_NRCONT = '"+_cNrContagem+"' "
		// id palete
		_cQryZ07 += "AND Z07_PALLET = '"+_cTmpIdPlt+"' "
		// em conferencia
		_cQryZ07 += "AND Z07_STATUS = 'C' "

		// executa o update
		TcSQLExec(_cQryZ07)

	EndIf

	// se permitir enderecar antes de finalizar a conferencia, gera proximo servico da OS
	If (mvGeraNovo) .And. (_lFinSemMapa)
		If ( ! sfLibArmParcial() )
			Return(.F.)
		EndIf
	EndIf

	// atualiza variaveis
	_lNovoPalete := .T.
	_lNovoVolume := .T.
	_cEtiqProd   := Space(Len(_cEtiqProd))
	_cEtqCodBar  := Space(Len(_cEtqCodBar))
	_cCodProd    := Space(_nTamCodPrd)
	_nQtdProd    := 1
	_nQtdSegUM   := 0
	_cIdPalete   := Space(_nTamIdPal)
	_cStatusPlt  := "V"
	_cStatusVlm  := "V"
	_cEtqVolume  := Space(Len(_cEtqVolume))
	_cPltClie    := Space(Len(_cPltClie))
	_nPltCamada  := 0
	_nQtdConfPlt := 0

	// define se limpa os campos ou não com base no parâmetro
	If ( ! _lRptLot )

		_cEtqLote := Space(Len(_cEtqLote))
		_dVldLote := CtoD("//")

	EndIf

	// se não controlar validade, já trás o campo preenchido
	If ( ! _lCtrVld )

		// define a data como data atual
		_dVldLote := CtoD("31/12/2049")

	EndIf

	// atualiza os itens do browse
	If (_oBrwConferencia <> nil)
		_aColsConf := {}
		aadd(_aColsConf,{0,"","","","",0,.F.})
		_oBrwConferencia:SetArray( _aColsConf )
		_oBrwConferencia:Refresh(.T.)

	EndIf

	// atualiza o objeto para receber o foco
	_oGetNrPalete:lReadOnly := (!_lNovoPalete)
	// atualizo objeto etiqueta volume
	_oGetEtqVolume:lReadOnly := ( ! _lNovoVolume )
	// atualiza o conteudo do palete
	_oCmbContPlt:Refresh()

	// foco no objeto
	If ( ! _lIdPltAuto)
		_oGetNrPalete:SetFocus()
	ElseIf (_lIdPltAuto)
		If (_lCtrVolume)
			If (_lEtqIdEAN) .Or. (_lEtqCod128) .Or.  (_lEtqIdDUN) // ean 13 / code 128 / DUN14
				_oGetEtqVolume:SetFocus()
			ElseIf (_lEtqClient) // CLIENTE
				_oGetCodProd:SetFocus()
			EndIf
		Else
			_oGetCodProd:SetFocus()
		EndIf
	EndIf

Return(.T.)

// ** funcao que valida a quantidade maxima de volumes/produto por palete
Static Function sfCapacPlt(mvQtdMxPlt, mvCtrVolume)

	local _nQtdJaLida := 0
	local _lRet := .T.
	local _cQryTot
	// detalhes do palete
	local _aDetPlt := {}

	// query para validar quantidade por palete
	_cQryTot := "SELECT Z07_PALLET, COUNT(DISTINCT Z07_ETQVOL) QTD_VLM,  SUM(Z07_QUANT) QTD_PROD "
	// itens conferidos
	_cQryTot += "FROM "+RetSqlName("Z07")+" Z07 (nolock)  "
	// filtro padrao
	_cQryTot += "WHERE "+RetSqlCond("Z07")+" "
	// numero e sequencia da OS
	_cQryTot += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	// cliente e loja
	_cQryTot += "AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
	// nr de contagem
	_cQryTot += "AND Z07_NRCONT = '"+_cNrContagem+"' "
	// ID palete
	If (_lIdPltAuto)
		_cQryTot += "AND Z07_PALLET = '"+IIf(Empty(_cIdPalete), _cIdPltAuto, _cIdPalete)+"' "
	ElseIf ( ! _lIdPltAuto)
		_cQryTot += "AND Z07_PALLET = '"+_cIdPalete+"' "
	EndIF
	// status
	_cQryTot += "AND Z07_STATUS = 'C' "
	// agrupa dados
	_cQryTot += "GROUP BY Z07_PALLET "

	// atualiza variavel
	_aDetPlt := U_SqlToVet(_cQryTot)

	// atualiza a quantidade ja lida
	If (Len(_aDetPlt)>0)
		If (mvCtrVolume)
			_nQtdJaLida := _aDetPlt[1][2]
		ElseIf ( ! mvCtrVolume)
			_nQtdJaLida := _aDetPlt[1][3]
		EndIf
	EndIf

	// calcula a quantidade - por volume
	If ((mvCtrVolume) .And. (_nQtdJaLida > mvQtdMxPlt))
		U_FtWmsMsg("Quantidade máxima por palete já atingida.","ATENCAO")
		_lRet := .F.
		// calcula a quantidade - por produto
	ElseIf ( ! mvCtrVolume) .And. ((_nQtdJaLida+_nQtdProd) > mvQtdMxPlt)
		U_FtWmsMsg("Quantidade máxima por palete já atingida.","ATENCAO")
		_lRet := .F.
	endIf

	// atualiza o status/conteudo do palete
	If (_lRet)
		If (mvCtrVolume)
			If (_nQtdJaLida == mvQtdMxPlt)
				_cStatusPlt := "T"
			ElseIf (_nQtdJaLida < mvQtdMxPlt)
				_cStatusPlt := "P"
			EndIf
		ElseIf ( ! mvCtrVolume)
			If ((_nQtdJaLida+_nQtdProd) == mvQtdMxPlt)
				_cStatusPlt := "T"
			ElseIf ((_nQtdJaLida+_nQtdProd) < mvQtdMxPlt)
				_cStatusPlt := "P"
			EndIf
		EndIf
	EndIf

Return(_lRet)

// ** funcao que apresenta os detalhes da conferencia
Static Function sfDetConfer()

	// obejtos da tela
	local _oWndConfDet
	local _oBmpEstorno, _oBmpConsDetSair, _oBmpCmpPlt, _oGetBusca
	local _oBrwConsDet
	local _oPnlConfDet, _oPnlConfRod
	local _oSayTotal, _oSayTotalPlt, _oSayTotalVlm

	// variaveis do browse
	local _aHeadDet := {}
	local _aColsDet := {}
	local _cQuery

	// quantidade total
	local _nQtdTot := 0
	// total de paletes
	local _nTotPalete := 0
	// total de volumes
	local _nTotVolume := 0
	//Total de Lotes
	local _nTotLotes  := 0
	// campo para busca
	local _cBusca := Space(30)

	// variaveis temporarias
	local _cTmpPlt := ""
	local _cTmpLot := ""
	local _cTmpVlm := ""

	Local _lTpAgrup := .T.

	If !(SFAgrupMsg("Agrupar informações Por ?", "Informações"))
		_lTpAgrup := .F.
	EndIf

	// define teclas de atalho para busca
	SetKey(VK_F2, {|| sfBuscaConf(_cBusca, _aColsDet , _oGetBusca, _oBrwConsDet ) } )

	// monta a query
	_cQuery := " SELECT CASE WHEN Z07_STATUS = 'C' THEN '  ' ELSE 'OK' END Z07_STATUS,  "
	// define o campo usado para identificacao do produto
	If _lTpAgrup
		If (_lEtqIdInt) // interna
			_cQuery += " Z07_PALLET, Z07_ETQVOL, Z07_ETQPRD ETQ_PROD, "
		ElseIf (_lEtqIdEAN) .OR. (_lEtqCod128) .OR. (_lEtqIdDUN) // cod EAN / CODE128
			_cQuery += " Z07_PALLET, Z07_ETQVOL, Z07_CODBAR ETQ_PROD, "
		EndIf
	Else
		_cQuery += " Z07_LOTCTL LOTE, "
	EndIf
	// quantidade
	_cQuery += "SUM(Z07_QUANT) Z07_QUANT, B1_COD, B1_DESC, Z07_NUMSER, SUM(Z07_QTSEGU) Z07_QTSEGU, '.F.' IT_DEL "
	// itens conferidos
	_cQuery += " FROM "+RetSqlTab("Z07")+" (nolock) "
	// cad. de produtos
	_cQuery += " INNER JOIN "+RetSqlTab("SB1")+" (nolock)  ON "+RetSqlCond("SB1")+" AND B1_COD = Z07_PRODUT "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z07")
	_cQuery += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	_cQuery += " AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
	_cQuery += " AND Z07_NRCONT = '"+_cNrContagem+"' "
	// agrupamento dos dados
	_cQuery += " GROUP BY CASE WHEN Z07_STATUS = 'C' THEN '  ' ELSE 'OK' END, Z07_NUMSER,  "
	// define o campo usado para identificacao do produto
	If _lTpAgrup
		If (_lEtqIdInt) // interna
			_cQuery += "Z07_PALLET,Z07_ETQVOL, Z07_ETQPRD, "
		ElseIf (_lEtqIdEAN) .OR. (_lEtqCod128) .OR. (_lEtqIdDUN) // cod EAN / CODE128
			_cQuery += "Z07_PALLET,Z07_ETQVOL, Z07_CODBAR, "
		EndIf
	Else
		_cQuery += " Z07_LOTCTL , "
	EndIf
	_cQuery += " B1_COD, B1_DESC "

	// ordem dos dados
	If _lTpAgrup
		_cQuery += " ORDER BY Z07_PALLET, Z07_ETQVOL, ETQ_PROD "
	Else
		_cQuery += " ORDER BY Z07_LOTCTL "
	EndIf

	MemoWrit("c:\query\twmsa010_sfDetConfer.txt",_cQuery)

	// atualiza o vetor do browse
	_aColsDet := U_SqlToVet(_cQuery)

	If (_lTpAgrup)
		// calcula a quantidade total de palete
		aEval(_aColsDet,{|x| _nQtdTot += x[5] , IIf(_cTmpPlt <> x[2], _nTotPalete ++, Nil), _cTmpPlt := x[2] })

		// calcula a quantidade total de volume
		aEval(_aColsDet,{|x| IIf(_cTmpVlm <> x[3], _nTotVolume ++, Nil), _cTmpVlm := x[3] })
	Else

		// calcula a quantidade total de Lotes
		aEval(_aColsDet,{|x| _nQtdTot += x[3] , IIf(_cTmpLot <> x[2], _nTotLotes ++, Nil), _cTmpLot := x[2] })

	EndIf

	// define o header
	aAdd(_aHeadDet,{"Sts"        ,"Z07_STATUS"  ,""                           ,2                      ,0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	If _lTpAgrup
		aAdd(_aHeadDet,{"Id Palete"  ,"Z07_PALLET"  ,PesqPict("Z07","Z07_PALLET") ,TamSx3("Z07_PALLET")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadDet,{"Id Volume"  ,"Z07_ETQVOL"  ,PesqPict("Z07","Z07_ETQVOL") ,TamSx3("Z07_ETQVOL")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	EndIf
	If _lTpAgrup
		If (_lEtqIdInt) // interna
			aAdd(_aHeadDet,{"Etq Produto", "ETQ_PROD", PesqPict("Z07","Z07_ETQPRD") ,TamSx3("Z07_ETQPRD")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
		ElseIf (_lEtqIdEAN) .OR. (_lEtqCod128) .OR. (_lEtqIdDUN)        // cod EAN / CODE128 / DUN14
			aAdd(_aHeadDet,{"Etq Produto", "ETQ_PROD", PesqPict("Z07","Z07_CODBAR") ,TamSx3("Z07_CODBAR")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
		EndIf
	Else
		aAdd(_aHeadDet,{"Lote"  ,"Z07_LOTCTL"  ,PesqPict("Z07","Z07_LOTCTL") ,TamSx3("Z07_LOTCTL")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	EndIf
	aAdd(_aHeadDet,{"Quant"      ,"Z07_QUANT"   ,_cMaskQuant                  ,TamSx3("Z07_QUANT")[1] , TamSx3("Z07_QUANT")[2] ,Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Produto"    ,"B1_COD"      ,PesqPict("SB1","B1_COD")     ,TamSx3("B1_COD")[1]    , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Desc Prod"  ,"B1_DESC"     ,PesqPict("SB1","B1_DESC")    ,TamSx3("B1_DESC")[1]   , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Num.Serie"  ,"Z07_NUMSER"  ,PesqPict("Z07","Z07_NUMSER") ,TamSx3("Z07_NUMSER")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Qtd Seg UM" ,"Z07_QTSEGU"  ,_cMaskQuant                  ,TamSx3("Z07_QTSEGU")[1], TamSx3("Z07_QTSEGU")[2],Nil,Nil,"N",Nil,"R",,,".F." })

	// monta o dialogo do monitor
	_oWndConfDet := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Detalhes",,,.F.,,,,,,.T.,,,.T. )
	_oWndConfDet:lEscClose := .F.

	// cria o panel do cabecalho - botoes
	_oPnlConfDet := TPanel():New(000,000,nil,_oWndConfDet,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlConfDet:Align:= CONTROL_ALIGN_TOP

	// -- BOTAO DE ESTORNO

	If (_lTpAgrup)
		_oBmpEstorno := TBtnBmp2():New(000,000,040,040,"ESTOMOVI",,,,{|| If( sfEstorno(_oBrwConsDet:aCols[_oBrwConsDet:nAt][2], _oBrwConsDet:aCols[_oBrwConsDet:nAt][3], _oBrwConsDet:aCols[_oBrwConsDet:nAt][6], Nil), _oWndConfDet:End(), Nil) },_oPnlConfDet,"Estornar conferência",,.T.)
		_oBmpEstorno:Align := CONTROL_ALIGN_LEFT
	Else
		_oBmpEstorno := TBtnBmp2():New(000,000,040,040,"ESTOMOVI",,,,{|| If( sfEstorno(Nil,Nil,Nil, _oBrwConsDet:aCols[_oBrwConsDet:nAt][2], _oBrwConsDet:aCols[_oBrwConsDet:nAt][4]), _oWndConfDet:End(), Nil) },_oPnlConfDet,"Estornar conferência",,.T.)
		_oBmpEstorno:Align := CONTROL_ALIGN_LEFT
	EndIf
	// -- BOTAO COMPLETA PALETE
	If (_lCtrVolume)
		_oBmpCmpPlt := TBtnBmp2():New(000,000,040,040,"BMPCPO",,,,{|| If( sfComplPlt(_oBrwConsDet:aCols[_oBrwConsDet:nAt][2]), _oWndConfDet:End(), Nil) },_oPnlConfDet,"Completa Palete",,.T.)
		_oBmpCmpPlt:Align := CONTROL_ALIGN_LEFT
	EndIf

	// campo para busca no browse
	_oGetBusca := TGet():New(000,050,{|u| If(PCount()>0,_cBusca:=u,_cBusca)}, _oWndConfDet ,048,008, "@!", {||  },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cBusca",,,,,,, "Localizar (tecla F2)",1)

	// -- FECHAR TELA
	_oBmpConsDetSair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _oWndConfDet:End() },_oPnlConfDet,"Sair",,.T.)
	_oBmpConsDetSair:Align := CONTROL_ALIGN_RIGHT

	// monta o browse com os motivos de interrupcoes
	_oBrwConsDet := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDet),'AllwaysTrue()','','AllwaysTrue()',_oWndConfDet,_aHeadDet,_aColsDet)
	_oBrwConsDet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// cria o panel do rodape - botoes
	_oPnlConfRod := TPanel():New(000,000,nil,_oWndConfDet,,.F.,.F.,,,020,020,.T.,.F. )
	_oPnlConfRod:Align:= CONTROL_ALIGN_BOTTOM

	// adiciona a linha com o total
	If _lTpAgrup
		_oSayTotal    := TSay():New(005,003,{|| "TOTAL: "         + AllTrim(Transf(_nQtdTot, _cMaskQuant)) },_oPnlConfRod,,,.F.,.F.,.F.,.T.)
		_oSayTotalVlm := TSay():New(005,050,{|| "TOTAL VOLUMES: " + AllTrim(Str(_nTotVolume)) },_oPnlConfRod,,,.F.,.F.,.F.,.T.)
		_oSayTotalPlt := TSay():New(012,003,{|| "TOTAL PALETES: " + AllTrim(Str(_nTotPalete)) },_oPnlConfRod,,,.F.,.F.,.F.,.T.)
	Else
		_oSayTotal    := TSay():New(005,003,{|| "TOTAL: "       + AllTrim(Transf(_nQtdTot, _cMaskQuant)) },_oPnlConfRod,,,.F.,.F.,.F.,.T.)
		_oSayTotalVlm := TSay():New(005,050,{|| "TOTAL LOTES: " + AllTrim(Str(_nTotLotes)) },_oPnlConfRod,,,.F.,.F.,.F.,.T.)
	EndIf

	// ativa o dialogo
	_oWndConfDet:Activate(,,,.F.,,,)

	// limpa tecla de atalho
	SetKey(VK_F2, {|| Nil } )

Return(.T.)

Static Function sfBuscaConf(mvBusca, mvAcols, mvGet, mvBrow)

	local _nPos := 0

	// reseta cor
	mvGet:SetColor(CLR_BLACK,CLR_WHITE)
	mvBrow:oBrowse:SetBlkBackColor({ ||  })
	mvBrow:Refresh()

	If !Empty(mvBusca)
		// tenta localizar por etiqueta volume (posição 3)
		_nPos := AScan(mvAcols, {|x| AllTrim((x[3])) == AllTrim(mvBusca) })

		if (_nPos > 0)
			mvBrow:Goto(_nPos)
			mvBrow:oBrowse:SetBlkBackColor({|| IIF(mvBrow:nAt == _nPos, CLR_YELLOW, CLR_WHITE) })
			mvBrow:Refresh()
		else
			// tenta localizar por serial (posição 8)
			_nPos := AScan(mvAcols, {|x| AllTrim((x[8])) == AllTrim(mvBusca) })

			if (_nPos > 0)
				mvBrow:Goto(_nPos)
				mvBrow:oBrowse:SetBlkBackColor({|| IIF(mvBrow:nAt == _nPos, CLR_YELLOW, CLR_WHITE) })
				mvBrow:Refresh()
			Else
				// pinta de vermelho porque não localizou
				mvGet:SetColor(CLR_WHITE,CLR_RED)
			EndIf
		EndIf
	EndIf

Return ( Nil )

// ** funcao para gerar o pre-mapa de armazenagem (reserva de enderecos)
User Function sfGeraMapa(lComple,aComple)

	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z06","Z08"})

	local _cQryMapa := ""
	local _lRetEnder := .F.
	local _nRetEnder := 0
	// endereco de servico
	local _cEndServ := ""
	// endereco de origem
	local _cEndOrig := ""
	// endereco de transicao
	local _cEndTran := ""
	// endereco de destino
	local _cEndDest := ""

	// controle de saldo a enderecar
	local _nSldEnder := 0

	// data e hora de emissao
	local _dDtEmissao := Date()
	local _cHrEmissao := Time()

	// controle de enderecamento completo
	local _lEndComp := .T.

	// variavel de controle da geração do Mapa (P = Planejado-Z04 / R = Realizado-Z07)
	Local _cTpGerMap := ""

	// variavel de controle do tipo de estrutura de destino
	Local _cEstFisDes := CriaVar("DC8_CODEST", .F.)

	//Unidade de medida do Produto
	Local _cCodiUM := CriaVar("B1_UM", .F.)

	// retorna o proximo servico, tarefa e atividades planejada da OS
	// 1-Num OS
	// 2-Seq OS
	// 3-Cod Servico
	// 4-Dsc Servico
	// 5-Cod Tarefa
	// 6-Dsc Tarefa
	// 7-Funcao/Rotina
	local _aPrxServico := {}

	// parametros para filtro de enderecos
	local _aFiltroEnd := {}

	// controle da sequencia
	local _cCntrlSeq := StrZero(1, TamSx3("Z08_SEQUEN")[1])

	Local _cTipConf := ""

	// quantidade para uso no calculo de reserva
	local _nQtdMsg := 0
	// unidade de medida
	local _cUnMedMapa := ""

	// lote
	local _cLoteMap := ""

	// eh logistica reversa
	local _lLogRev := .F.

	// completa paletes fracionados
	local _lComPltFra := .F.

	// se a rotina for chamado por outro fonte, carrega as variáveis usadas enviadas por parâmetros
	If ValType(aComple) == "A"
		_cNumOrdSrv	:= aComple[1]
		_cSeqOrdSrv	:= aComple[2]
		_cCodCliFor	:= aComple[3]
		_cLojCliFor	:= aComple[4]
		_cNumCESV	:= aComple[5]
		_lLotObrEnt	:= aComple[6]
		_cMaskQuant	:= aComple[7]
		_cAreaArm	:= aComple[8]
		_lUsoLogRev	:= aComple[9]
		_cArmzServ	:= Z06->Z06_LOCAL
		_lPreConf   := (GetAdvFVal("Z06", "Z06_SERVIC", xFilial("Z06") + _cNumOrdSrv + _cSeqOrdSrv,1) == "015")

		_lVldCapacPlt := U_FtWmsParam("WMS_VALIDA_CAPACIDADE_PALETE", "L", .T., .F., "", _cCodCliFor, _cLojCliFor, "", _cNumOrdSrv)
	EndIf

	// retorna o proximo servico, tarefa e atividades planejada da OS
	// 1-Num OS
	// 2-Seq OS
	// 3-Cod Servico
	// 4-Dsc Servico
	// 5-Cod Tarefa
	// 6-Dsc Tarefa
	// 7-Funcao/Rotina
	_aPrxServico := U_FtPrxSrv(_cNumOrdSrv, _cSeqOrdSrv, _cCodCliFor, _cLojCliFor, Nil)

	_cPrxServ := IIF(lComple,_cSeqOrdSrv,_aPrxServico[1,2])

	// se estiver finalizada, não deixa fazer pela conferencia
	_cTpGerMap := IIF(lComple,"R",IIf(Z06->Z06_STATUS == "FI", "R", "P"))

	// pesquisa o proximo item da OS
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	Z06->(dbSeek( xFilial("Z06")+_cNumOrdSrv+_cPrxServ ))

	// se não for de forma
	If !lComple
		// verifica se o mapa ja foi gerado
		dbSelectArea("Z08")
		Z08->(dbSetOrder(1)) // 1-Z08_FILIAL, Z08_NUMOS, Z08_SEQOS
		If Z08->(dbSeek( xFilial("Z08")+_cNumOrdSrv+_cPrxServ ))
			// restaura areas iniciais
			RestOrd(_aAreaIni,.T.)
			RestArea(_aArea)
			// mensagem
			U_FtWmsMsg("OS ja tem mapa de separação gerado!","ATENCAO")
			// retorno
			Return (.F.)
		EndIf
	EndIf

	// valida se tabela de conferência já tem nota fiscal vinculada (NUMSEQ != branco)
	If (_lPreConf)
		_cQryMapa := "SELECT COUNT(R_E_C_N_O_) QTD FROM " + RetSqlTab("Z07")
		_cQryMapa += " WHERE " + RetSqlCond("Z07")
		_cQryMapa += " AND Z07_NUMOS  = '" + _cNumOrdSrv + "'"
		_cQryMapa += " AND Z07_SEQOS  = '" + _cSeqOrdSrv + "'"
		_cQryMapa += " AND Z07_NUMSEQ = '' "

		If (U_FTQuery(_cQryMapa) != 0)
			// restaura areas iniciais
			RestOrd(_aAreaIni,.T.)
			RestArea(_aArea)
			// mensagem
			U_FtWmsMsg("OS ainda sem nota fiscal vinculada! Consulte account! ","ATENCAO")
			// retorno
			Return (.F.)
		EndIf
	EndIf


	// conforme planejamento
	If (_cTpGerMap == "P")
		// monta query para buscar os dados
		_cQryMapa := "SELECT "
		_cQryMapa += "  ZZ_CESV   MAP_CESV, "
		_cQryMapa += "  Z04_PROD  MAP_CODPRD, "
		// descricao do produto
		_cQryMapa += "  CASE "
		_cQryMapa += "    WHEN ( ( Z04_SEQKIT = '' ) OR  ( Z04_SEQKIT != '' AND Z04_NUMSEQ != '' ) ) THEN (SELECT D1_DESCRIC FROM "+RetSqlName("SD1")+" SD1  (nolock) WHERE "+RetSqlCond("SD1")+" AND D1_NUMSEQ = Z04_NUMSEQ) "
		_cQryMapa += "    WHEN ( (Z04_SEQKIT != '' AND Z04_NUMSEQ = '') ) THEN (SELECT DISTINCT Z29_DSCKIT FROM "+RetSqlName("Z29")+" Z29 (nolock)  WHERE "+RetSqlCond("Z29")+" AND Z29_CODKIT = Z04_CODKIT) "
		_cQryMapa += "  END       MAP_DSCPRD, "

		_cQryMapa += "  Z04_QUANT MAP_QUANT, "
		_cQryMapa += "  ZZ_LOCAL  MAP_LOCAL, "

		// busca numseq / varios numseq para kit
		_cQryMapa += "  COALESCE("
		_cQryMapa += "  	(SELECT Z04COMPKIT.Z04_NUMSEQ + ';' "
		_cQryMapa += "  	 FROM "+RetSqlName("Z04")+" AS Z04COMPKIT (nolock)  "
		_cQryMapa += "  	 WHERE Z04COMPKIT.Z04_FILIAL  = '"+xFilial("Z04")+"' AND Z04COMPKIT.D_E_L_E_T_ = ' ' "
		_cQryMapa += "  	   AND Z04COMPKIT.Z04_CESV    = ZZ_CESV "
		_cQryMapa += "  	   AND Z04COMPKIT.Z04_CODKIT != '' "
		_cQryMapa += "  	   AND Z04COMPKIT.Z04_CODKIT  = Z04.Z04_CODKIT "
		_cQryMapa += "  	   AND Z04COMPKIT.Z04_SEQKIT  = Z04.Z04_SEQKIT "
		_cQryMapa += "  	   AND Z04COMPKIT.Z04_NF     != '' "
		_cQryMapa += "  	 FOR XML PATH(''), TYPE).value('.[1]','VARCHAR(400)') "
		_cQryMapa += "  , Z04_NUMSEQ) MAP_NUMSEQ, "

		_cQryMapa += " Z04_SEQKIT MAP_SEQKIT,
		_cQryMapa += " ZZ_DOCA    MAP_DOCA, "
		_cQryMapa += " Z04_QTDPAL MAP_QTDPALETES, "
		_cQryMapa += " Z04_LOTCTL MAP_LOTE, "
		_cQryMapa += " ''         MAP_TPESTO "

		// movimentacao do veiculo
		_cQryMapa += " FROM "+RetSqlTab("SZZ")+" (nolock) "

		// itens da nota relacionado a mov de veiculo
		_cQryMapa += " INNER JOIN "+RetSqlTab("Z04")+" (nolock)  ON "+RetSqlCond("Z04")+" AND Z04_CESV = ZZ_CESV "
		_cQryMapa += " AND ( "
		_cQryMapa += "       (Z04_NF != '' AND Z04_SEQKIT = '' AND Z04_CODKIT = '') "
		_cQryMapa += "       OR "
		_cQryMapa += "       (Z04_NF =  '' AND Z04_SEQKIT != '' AND Z04_CODKIT != '') "
		_cQryMapa += "     ) "

		// fitro padrao
		_cQryMapa += "WHERE "+RetSqlCond("SZZ")
		// nr CESV
		_cQryMapa += "AND ZZ_CESV = '"+_cNumCESV+"' "

	ElseIf (_cTpGerMap == "R")

		// monta query para buscar os dados
		_cQryMapa := "SELECT "
		_cQryMapa += "  DISTINCT(CASE WHEN Z07_CODKIT != '' THEN Z07_CODKIT ELSE Z07_PRODUT END) MAP_CODPRD, "
		_cQryMapa += "  ZZ_CESV   MAP_CESV, "
		// descricao do produto
		_cQryMapa += "  CASE "
		_cQryMapa += "    WHEN Z07_CODKIT = '' THEN (SELECT D1_DESCRIC FROM "+RetSqlTab("SD1")+" (nolock)  WHERE "+RetSqlCond("SD1")+" AND D1_NUMSEQ = Z07_NUMSEQ) "
		_cQryMapa += "    ELSE (SELECT DISTINCT Z29_DSCKIT FROM "+RetSqlTab("Z29")+" (nolock)  WHERE "+RetSqlCond("Z29")+" AND Z29_CODKIT = Z07_CODKIT) "
		_cQryMapa += "  END       MAP_DSCPRD, "

		_cQryMapa += "  SUM(Z07_QUANT)  MAP_QUANT, "
		_cQryMapa += "  Z07_LOCAL       MAP_LOCAL, "

		// busca numseq / varios numseq para kit
		_cQryMapa += "  COALESCE("
		_cQryMapa += "  	(SELECT DISTINCT(Z07COMPKIT.Z07_NUMSEQ) + ';' "
		_cQryMapa += "       FROM "+RetSqlName("SZZ")+" SZZCOMPKIT (nolock)  "
		_cQryMapa += "       INNER JOIN "+RetSqlName("Z05")+" Z05COMPKIT (nolock)  ON Z05COMPKIT.Z05_FILIAL  = '"+xFilial("Z05")+"' AND Z05COMPKIT.D_E_L_E_T_ = ' ' AND Z05COMPKIT.Z05_CESV  = SZZCOMPKIT.ZZ_CESV "
		_cQryMapa += "       INNER JOIN "+RetSqlName("Z07")+" Z07COMPKIT (nolock)  ON Z07COMPKIT.Z07_FILIAL  = '"+xFilial("Z07")+"' AND Z07COMPKIT.D_E_L_E_T_ = ' ' AND Z07COMPKIT.Z07_NUMOS = Z05COMPKIT.Z05_NUMOS "
		_cQryMapa += "  	 WHERE SZZCOMPKIT.ZZ_FILIAL  = '"+xFilial("SZZ")+"' AND SZZCOMPKIT.D_E_L_E_T_ = ' ' "
		_cQryMapa += "  	   AND SZZCOMPKIT.ZZ_CESV    = SZZ.ZZ_CESV "
		_cQryMapa += "  	   AND Z07COMPKIT.Z07_CODKIT != '' "
		_cQryMapa += "  	   AND Z07COMPKIT.Z07_CODKIT  = Z07.Z07_CODKIT "
		_cQryMapa += "  	   AND Z07COMPKIT.Z07_SEQKIT  = Z07.Z07_SEQKIT "
		_cQryMapa += "  	 FOR XML PATH(''), TYPE).value('.[1]','VARCHAR(400)') "
		_cQryMapa += "  , Z07_NUMSEQ) MAP_NUMSEQ, "

		_cQryMapa += " Z07_SEQKIT                 MAP_SEQKIT, "
		_cQryMapa += " ZZ_DOCA                    MAP_DOCA, "

		// se for complemento desconta os endereços já ocupados
		If lComple
			_cQryMapa += " COUNT(DISTINCT Z07_PALLET) - (SELECT COUNT(DISTINCT(Z08_ENDDES)) QTD "
			_cQryMapa += " 								FROM "+RetSqlName("Z08")+" (NOLOCK) "
			_cQryMapa += " 								WHERE D_E_L_E_T_ = '' "
			_cQryMapa += " 								AND Z08_FILIAL = '"+xFilial("Z08")+"' "
			_cQryMapa += " 								AND Z08_NUMOS = '"+_cNumOrdSrv+"' "
			_cQryMapa += " 								AND Z08_SEQOS = '002'
			_cQryMapa += " 								AND Z08_PRODUT = Z07_PRODUT
			_cQryMapa += " 								AND Z08_NUMSEQ = Z07_NUMSEQ) MAP_QTDPALETES, "
		Else
			_cQryMapa += " COUNT(DISTINCT Z07_PALLET) MAP_QTDPALETES, "
		EndIf
		_cQryMapa += " Z07_LOTCTL                 MAP_LOTE, "
		_cQryMapa += " Z07_TPESTO                 MAP_TPESTO "

		// movimentacao do veiculo
		_cQryMapa += " FROM "+RetSqlTab("SZZ")+" (nolock) "
		// cab ordem servico
		_cQryMapa += " INNER JOIN "+RetSqlTab("Z05")+" (nolock)  ON "+RetSqlCond("Z05")+" AND Z05_CESV = ZZ_CESV "
		// itens Conferidos
		_cQryMapa += " INNER JOIN "+RetSqlTab("Z07")+" (nolock)  ON "+RetSqlCond("Z07")+" AND Z05_NUMOS = Z07_NUMOS "

		// fitro padrao
		_cQryMapa += " WHERE "+RetSqlCond("SZZ")
		// nr CESV
		_cQryMapa += " AND ZZ_CESV = '"+_cNumCESV+"' "
		// agrupa dados
		_cQryMapa += " GROUP  BY ZZ_CESV, "
		_cQryMapa += "           Z07_PRODUT, "
		_cQryMapa += "           Z07_NUMSEQ, "
		_cQryMapa += "           Z07_SEQKIT, "
		_cQryMapa += "           Z07_CODKIT, "
		_cQryMapa += "           Z07_LOCAL, "
		_cQryMapa += "           ZZ_DOCA, "
		_cQryMapa += "           Z07_LOTCTL, "
		_cQryMapa += "           Z07_TPESTO "

	EndIF

	memowrit("c:\query\twmsa010_sfGeraMapa.txt",_cQryMapa)

	// verifica se o alias esta em uso
	If Select("_QRYMAPA") <> 0
		dbSelectArea("_QRYMAPA")
		dbCloseArea()
	EndIf

	// executa a query
	dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQryMapa),"_QRYMAPA",.F.,.T.)
	dbSelectArea("_QRYMAPA")

	// valida se a doca foi informada
	If ( Empty(_QRYMAPA->MAP_DOCA))
		// mensagem
		U_FtWmsMsg("Doca/Stage não definida para esta operação.","ATENCAO")
		// fecha query
		dbSelectArea("_QRYMAPA")
		dbCloseArea()
		// restaura areas iniciais
		RestOrd(_aAreaIni,.T.)
		RestArea(_aArea)
		// retorno
		Return(.F.)
	EndIf

	// inicia transacao
	BEGIN TRANSACTION

		// varre todos os itens
		While ( _QRYMAPA->( !Eof() ) )

			// reinicia variaveis
			_lLogRev    := .F.
			_lComPltFra := .F.

			IF ( _cTpGerMap == "R" ) .AND. ( _QRYMAPA->MAP_QTDPALETES == 0 )
				// próximo item a gerar o mapa
				_QRYMAPA->( dbSkip() )
				// pula esta geração em branco
				Loop
			EndIf

			// unidade de medida
			_cCodiUM := Posicione("SB1",1, xFilial("SB1")+ _QRYMAPA->MAP_CODPRD ,"B1_UM")

			// lote do mapa
			_cLoteMap := IIf(_lLotObrEnt, _QRYMAPA->MAP_LOTE, "")

			// definição da mascara do campo
			If ( _cTpGerMap == "P" )
				// se tem paletes informados
				If (_QRYMAPA->MAP_QTDPALETES != 0)
					// controla o saldo total enderecado
					_nSldEnder := _QRYMAPA->MAP_QTDPALETES
					// define quantidade
					_nQtdMsg    := Transf(_nSldEnder, "@E 999")
					// define unidade de medida
					_cUnMedMapa := "Palete(s)"
				Else
					// controla o saldo total enderecado
					_nSldEnder := _QRYMAPA->MAP_QUANT
					// define quantidade
					_nQtdMsg := Transf(_nSldEnder, _cMaskQuant)
					// define unidade de medida
					_cUnMedMapa := _cCodiUM

				EndIf
			Else
				// controla o saldo total enderecado
				_nSldEnder := _QRYMAPA->MAP_QTDPALETES
				// define quantidade
				_nQtdMsg := Transf(_nSldEnder, "@E 999")
				// define unidade de medida
				_cUnMedMapa := "Palete(s)"

			EndIf

			// se for complemento de estoque, chama a função e exibe o alerta 
			If lComple
				// seleciona os tipos de estoque disponíveis para conferência
				_aOpcoesEst := sfRetTpEstoque()
			EndIf

			// mensagem de confirmacao
			U_FtWmsMsg("Produto: " + AllTrim(_QRYMAPA->MAP_CODPRD) + "-" + ;
			AllTrim(_QRYMAPA->MAP_DSCPRD) +;
			CRLF +;
			"Quant: " + AllTrim(_nQtdMsg) + " " +_cUnMedMapa + ;
			IIf(Empty(_cLoteMap), "", CRLF + "Lote: " + AllTrim(_cLoteMap)) + ;
			CRLF +;
			IIf( _cTpGerMap == "R" , "Estoque: " + AllTrim(_aOpcoesEst[ AScan(_aOpcoesEst, _QRYMAPA->MAP_TPESTO ) ]) , "") ,"ATENCAO")

			// se a area de armazenagem do cliente foi definida
			_cEstFisDes := _cAreaArm

			// se não encontrou, trás a tela padrão
			If ( Empty(_cEstFisDes) ) .OR. ( ("000002" $ _cEstFisDes) .AND. ("000007" $ _cEstFisDes) )

				// definicao da estrutura fisica de destino
				_cEstFisDes := sfTpEndMsg("Escolha Onde a Mercadoria será Endereçada", "GERAR MAPA")

			EndIf

			// valida selecao da estrutura fisca de destino
			If ( Empty(_cEstFisDes) )
				// rollback na transacao
				DisarmTransaction()
				// mensagem
				U_FtWmsMsg("É obrigatório informar uma estrutura física de destino!","ATENCAO")
				// restaura areas iniciais
				RestOrd(_aAreaIni,.T.)
				RestArea(_aArea)
				// retorno
				_lEndComp := .F.
				Break
			EndIf

			// define parametros para uso de logistica reversa
			If (_lUsoLogRev) .And. (_cTpGerMap == "R")
				// define se item eh logistica reversa
				_lLogRev    := sfEhLogRev(_QRYMAPA->MAP_NUMSEQ) .OR. (Z06->Z06_SERVIC == "T03")
				_lComPltFra := _lLogRev
			EndIf

			// solicita parametros para geracao do mapa por produto
			If ( ! sfParamMapa( @_aFiltroEnd, _QRYMAPA->MAP_CODPRD, _QRYMAPA->MAP_DSCPRD, _QRYMAPA->MAP_QUANT, _QRYMAPA->MAP_QTDPALETES, _cTpGerMap, _cEstFisDes, _lLogRev, @_lComPltFra ) )
				// rollback na transacao
				DisarmTransaction()
				// fecha query
				dbSelectArea("_QRYMAPA")
				dbCloseArea()
				// restaura areas iniciais
				RestOrd(_aAreaIni,.T.)
				RestArea(_aArea)
				// retorno
				_lEndComp := .F.
				Break
			EndIf

			// zera os enderecos de destino
			_aRetEnder := {}

			// executa a funcao para enderecamento do produto
			_lRetEnder := U_FtEndereca(	@_aRetEnder                            ,; // retorno dos enderecos selecionados
			_cEstFisDes                                                        ,; // cod. estr. fisica
			_QRYMAPA->MAP_LOCAL                                                ,; // cod. do armazem / local
			_QRYMAPA->MAP_CODPRD                                               ,; // cod. do produto / kit
			_nSldEnder                                                         ,; // quantidade a enderecar
			_aFiltroEnd                                                        ,; // filtros
			_QRYMAPA->MAP_CESV                                                 ,; // cesv
			_QRYMAPA->MAP_NUMSEQ                                               ,; // num seq
			_QRYMAPA->MAP_SEQKIT                                               ,; // sequencia do kit
			_cTpGerMap                                                         ,; // Gerar Mapa Planejado
			_cCodCliFor                                                        ,; // cliente da operacao
			_cLoteMap                                                          ,; // lote
			_QRYMAPA->MAP_TPESTO                                               ,; // tipo de estoque
			_lComPltFra                                                        ,; // se deve completar paletes fracionados
			_QRYMAPA->MAP_QUANT                                                ,; // quantidade total da mercadoria
			_QRYMAPA->MAP_QTDPALETES )                                            // quantidade de paletes (planejado ou realizado)

			// se encontrou endereco, gera plano de armazenagem
			If (_lRetEnder)

				// varre todos os enderecos, gerando o mapa de armazenagem na tabela Z08
				For _nRetEnder := 1 to Len(_aRetEnder)

					// define endereco de servico
					_cEndServ := _QRYMAPA->MAP_DOCA
					// define endereco de origem
					_cEndOrig := _QRYMAPA->MAP_DOCA
					// define endereco de transicao
					_cEndTran := IIf(("000002" $ _cEstFisDes) .Or. ("000010" $ _cEstFisDes), SubStr(_aRetEnder[_nRetEnder][2],1,2), "")
					// define endereco de destino
					_cEndDest := _aRetEnder[_nRetEnder][2]
					// tipo do planejamento (Q-Quant Sku/Volume / P-Quant Palete Informado)
					_cTipConf := _aRetEnder[_nRetEnder][5]

					// inclui o item da OS
					dbSelectArea("Z08")
					RecLock("Z08",.T.)
					Z08->Z08_FILIAL := xFilial("Z08")
					Z08->Z08_NUMOS  := _cNumOrdSrv
					Z08->Z08_SEQOS	:= Z06->Z06_SEQOS
					Z08->Z08_LOCAL  := _aRetEnder[_nRetEnder][1]
					Z08->Z08_SERVIC := Z06->Z06_SERVIC
					Z08->Z08_TAREFA := Z06->Z06_TAREFA
					Z08->Z08_ENDSRV := _cEndServ
					Z08->Z08_ENDORI := _cEndOrig
					Z08->Z08_ENDTRA := _cEndTran
					Z08->Z08_ENDDES := _cEndDest
					Z08->Z08_DTEMIS := _dDtEmissao
					Z08->Z08_HREMIS := _cHrEmissao
					Z08->Z08_STATUS := "P" // P-Planejado / R-Realizado / M-Movimento / E-Erro
					Z08->Z08_PRODUT := _QRYMAPA->MAP_CODPRD
					Z08->Z08_QUANT  := _aRetEnder[_nRetEnder][3]
					Z08->Z08_PRIOR  := "99"
					Z08->Z08_FRAPLT	:= IIf(_aRetEnder[_nRetEnder][4]=="T", "N", "S")
					Z08->Z08_NUMSEQ	:= _QRYMAPA->MAP_NUMSEQ
					Z08->Z08_TPOPER := Z05->Z05_TPOPER
					Z08->Z08_SEQUEN := _cCntrlSeq
					Z08->Z08_SEQKIT := _QRYMAPA->MAP_SEQKIT
					Z08->Z08_LOCDES := _aRetEnder[_nRetEnder][1] // local de destino igual a origem, pois, recebimento só pode rodar no mesmo armazém
					Z08->Z08_LOTCTL := _aRetEnder[_nRetEnder][6] // lote
					Z08->Z08_LOGREV := IIf(_lLogRev, "S", "N")
					Z08->Z08_COMFRA := IIf(_aRetEnder[_nRetEnder][7], "S", "N")
					Z08->Z08_TPESTO := _QRYMAPA->MAP_TPESTO
					Z08->(MsUnLock())

					// diminui o saldo a enderecar
					_nSldEnder -= _aRetEnder[_nRetEnder][3]
					// controle da sequencia
					_cCntrlSeq := Soma1(_cCntrlSeq)

				Next _nRetEnder

				If _cTipConf == "Q"
					// se sobrou saldo, deu erro
					If (_nSldEnder > 0)
						// atualiza variavel de retorno
						_lEndComp := .F.
						// sai do Loop
						Exit
					EndIf
				EndIf
				// caso nao tenha encontrado, detalha Log
			ElseIf ( ! _lRetEnder )
				// atualiza variavel de retorno
				_lEndComp := .F.
				// sai do Loop
				Exit
			EndIf

			// proximo item
			_QRYMAPA->(dbSkip())
		EndDo

		// fecha alias
		dbSelectArea("_QRYMAPA")
		dbCloseArea()

		// restaura areas iniciais
		RestOrd(_aAreaIni,.T.)
		RestArea(_aArea)

		// se NAO encontrou endereco, cancela transacao
		If ( ! _lEndComp )
			// rollback na transacao
			DisarmTransaction()
			// mensagem
			U_FtWmsMsg("Não foi possível gerar o Mapa de Armazenagem! Favor verificar os parâmetros.","ATENCAO")
			// retorno
			_lEndComp := .F.
			Break
		EndIf

		// finaliza transacao
	END TRANSACTION

	// quando ok, e fora da transcao, mensagem
	If (_lEndComp)
		//gera log do mapa
		U_FtGeraLog(cFilAnt, "Z08", xFilial("Z08") + _cNumOrdSrv, "Mapa de armazenagem gerado com sucesso: " + _cNumOrdSrv, "WMS", "")

		U_FtWmsMsg("Mapa de Armazenagem Gerado!","ATENCAO")
	EndIf

Return(_lEndComp)

// ** funcao para liberar armazenagem parcial / mapa gerado anteriormente
Static Function sfLibArmParcial()
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z05","Z06","Z07","Z08"})

	// query
	local _cQryPalete
	local _cQryArmz
	local _cUpdZ07

	// data e hora de emissao
	local _dDtEmissao := Date()
	local _cHrEmissao := Time()

	// mapa de enderecos reservados para armazenagem
	local _aMapaEnd := {}
	local _nMapaEnd := 0

	// controle de enderecamento completo
	local _lEndComp := .T.

	// endereco de servico da atividade de conferencia
	local _cTmpEndSrv := Z06->Z06_ENDSRV
	// retorna o proximo servico, tarefa e atividades planejada da OS
	// 1-Num OS
	// 2-Seq OS
	// 3-Cod Servico
	// 4-Dsc Servico
	// 5-Cod Tarefa
	// 6-Dsc Tarefa
	// 7-Funcao/Rotina
	local _aPrxServico := U_FtPrxSrv(_cNumOrdSrv, _cSeqOrdSrv, _cCodCliFor, _cLojCliFor, Nil)

	// status do palete (V=Vazio / T=Total / P=Parcial)
	local _cStsPalete := ""

	// data e hora da criação da Z16
	local _cDtTran := Date()
	local _cHrTran := Time()

	// pesquisa o proximo item da OS
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	If ! Z06->(dbSeek( xFilial("Z06")+_cNumOrdSrv+_aPrxServico[1,2] ))
		U_FtWmsMsg("Erro na geração da próxima atividade da OS!","ATENCAO")
		// restaura areas iniciais
		RestOrd(_aAreaIni,.T.)
		RestArea(_aArea)
		Return(_lEndComp)
	EndIf


	// inicia transacao
	BEGIN TRANSACTION


		// atualiza o proximo item da OS
		If (Z06->Z06_STATUS=="PL")
			RecLock("Z06")
			Z06->Z06_ENDSRV	:= _cTmpEndSrv
			Z06->Z06_DTEMIS := _dDtEmissao
			Z06->Z06_HREMIS := _cHrEmissao
			Z06->Z06_STATUS := "AG"
			Z06->Z06_PRIOR  := "99"
			Z06->(MsUnLock())
		EndIf

		// busca os dados dos paletes conferidos
		_cQryPalete := " SELECT Z07_LOCAL, Z07_PALLET, Z07_PRODUT, Z07_UNITIZ, Z07_LOTCTL, Z07_VLDLOT, SUM(Z07_QUANT) Z07_QUANT "
		_cQryPalete += " FROM "+RetSqlTab("Z07")+" (nolock) "
		_cQryPalete += " WHERE "+RetSqlCond("Z07")
		_cQryPalete += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		_cQryPalete += " AND Z07_NRCONT = '"+_cNrContagem+"' "
		_cQryPalete += " AND Z07_STATUS = 'C' "
		_cQryPalete += " AND Z07_PALLET = '" + _cIdPalete + "'"
		_cQryPalete += " GROUP BY Z07_LOCAL, Z07_PALLET, Z07_PRODUT, Z07_UNITIZ,Z07_LOTCTL,Z07_VLDLOT "
		//TODO
		memowrit("c:\query\twmsa010_sfLibArmParcial_1.txt", _cQryPalete)

		// verifica se a query esta aberta
		If (Select("_QRYALLPLT")<>0)
			dbSelectArea("_QRYALLPLT")
			dbCloseArea()
		EndIf

		// executa a query
		dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQryPalete),"_QRYALLPLT",.F.,.T.)
		dbSelectArea("_QRYALLPLT")

		// varre todos os itens da query para enderecar
		While _QRYALLPLT->(!Eof())

			// realiza a formacao da composicao do palete selecionado
			_cQryPalete := " SELECT Z07_LOCAL, Z07_PALLET, Z07_ETQPRD, Z07_PRODUT, Z07_NUMSEQ, Z07_UNITIZ, SUM(Z07_QUANT) Z07_QUANT, SUM(Z07_QTSEGU) Z07_QTSEGU, Z07_EMBALA, Z07_TPESTO, Z07_CODBAR, Z07_ETQVOL, Z07_SEQKIT, Z07_CODKIT,Z07_LOTCTL,Z07_PLTCLI,Z07_VLDLOT, Z07_CAMPLT, Z07_NUMSER "
			_cQryPalete += " FROM "+RetSqlTab("Z07")+" (nolock) "
			_cQryPalete += " WHERE "+RetSqlCond("Z07")
			_cQryPalete += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
			_cQryPalete += " AND Z07_NRCONT = '"+_cNrContagem+"' "
			_cQryPalete += " AND Z07_PALLET = '"+_QRYALLPLT->Z07_PALLET+"' "
			_cQryPalete += " AND Z07_STATUS = 'C' "
			_cQryPalete += " GROUP BY Z07_LOCAL, Z07_PALLET, Z07_ETQPRD, Z07_PRODUT, Z07_NUMSEQ, Z07_UNITIZ, Z07_EMBALA, Z07_TPESTO, Z07_CODBAR, Z07_ETQVOL, Z07_SEQKIT, Z07_CODKIT,Z07_LOTCTL,Z07_PLTCLI, Z07_VLDLOT, Z07_CAMPLT, Z07_NUMSER "

			memowrit("c:\query\twmsa010_sfLibArmParcial_2.txt", _cQryPalete)

			// verifica se a query esta aberta
			If (Select("_QRYIDPLT")<>0)
				dbSelectArea("_QRYIDPLT")
				dbCloseArea()
			EndIf

			// executa a query
			dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQryPalete),"_QRYIDPLT",.F.,.T.)
			dbSelectArea("_QRYIDPLT")

			While _QRYIDPLT->(!Eof())

				// grava os dados
				dbSelectArea("Z16")
				RecLock("Z16",.T.)
				Z16->Z16_FILIAL	:= xFilial("Z16")
				Z16->Z16_ETQPAL	:= _QRYIDPLT->Z07_PALLET
				Z16->Z16_UNITIZ	:= _QRYIDPLT->Z07_UNITIZ
				Z16->Z16_ETQPRD	:= _QRYIDPLT->Z07_ETQPRD
				Z16->Z16_CODPRO	:= _QRYIDPLT->Z07_PRODUT
				Z16->Z16_QUANT	:= _QRYIDPLT->Z07_QUANT
				Z16->Z16_QTSEGU := _QRYIDPLT->Z07_QTSEGU
				Z16->Z16_SALDO  := _QRYIDPLT->Z07_QUANT
				Z16->Z16_NUMSEQ	:= _QRYIDPLT->Z07_NUMSEQ
				Z16->Z16_STATUS	:= _cStatusPlt // V=Vazio / T=Total / P=Parcial
				Z16->Z16_QTDVOL	:= _QRYIDPLT->Z07_QUANT
				Z16->Z16_ENDATU := _cTmpEndSrv
				Z16->Z16_ORIGEM := "Z07"
				Z16->Z16_LOCAL  := _QRYIDPLT->Z07_LOCAL
				Z16->Z16_TPESTO := _QRYIDPLT->Z07_TPESTO
				Z16->Z16_CODBAR := _QRYIDPLT->Z07_CODBAR
				Z16->Z16_PLTCLI := _QRYIDPLT->Z07_PLTCLI
				Z16->Z16_LOTCTL := _QRYIDPLT->Z07_LOTCTL
				Z16->Z16_VLDLOT := Stod(_QRYIDPLT->Z07_VLDLOT)
				// informacoes de volume/agrupadora
				If ( ! Empty(_QRYIDPLT->Z07_ETQVOL))
					Z16->Z16_EMBALA := _QRYIDPLT->Z07_EMBALA
					Z16->Z16_ETQVOL := _QRYIDPLT->Z07_ETQVOL
					Z16->Z16_SEQKIT := _QRYIDPLT->Z07_SEQKIT
					Z16->Z16_CODKIT := _QRYIDPLT->Z07_CODKIT
				EndIf
				// data e hora da criação da Z16
				Z16->Z16_DATA   := _cDtTran
				Z16->Z16_HORA   := _cHrTran
				Z16->Z16_CAMPLT := _QRYIDPLT->Z07_CAMPLT
				Z16->Z16_NUMSER := _QRYIDPLT->Z07_NUMSER
				Z16->(MsUnLock())

				// proximo item
				_QRYIDPLT->(dbSkip())
			EndDo


			// finaliza os itens conferidos
			_cUpdZ07 := "UPDATE "+RetSqlName("Z07")+" "
			// status finalizado
			_cUpdZ07 += "SET Z07_STATUS = 'D' "
			// filtro padrao
			_cUpdZ07 += "WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
			// filtro da OS especifica
			_cUpdZ07 += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
			_cUpdZ07 += "AND Z07_NRCONT = '"+_cNrContagem+"' "
			// status iniciado
			_cUpdZ07 += "AND Z07_STATUS = 'C' "
			_cUpdZ07 += "AND Z07_PALLET = '"+_QRYALLPLT->Z07_PALLET+"' "

			memowrit("c:\query\twmsa010_sfLibArmParcial_3.txt", _cUpdZ07)

			// executa o update
			TcSQLExec(_cUpdZ07)

			// proximo item
			_QRYALLPLT->(dbSkip())
		EndDo

		// se NAO encontrou endereco, cancela transacao
		If ( ! _lEndComp)

			// rollback na transacao
			DisarmTransaction()

			U_FtWmsMsg("Erro ao gerar plano de armazenagem parcial!","ATENCAO")

			// restaura areas iniciais
			RestOrd(_aAreaIni,.T.)
			RestArea(_aArea)

			_lEndComp := .F.
			Break
		EndIf

		// finaliza transacao
	END TRANSACTION

	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aArea)

Return(_lEndComp)


// ** funcao para realizar a finalizacao/encerramento total do servico de conferencia da OS
Static Function sfFinalizaOS(mvTela, mvTelaOk)
	// variavel de retorno
	local _lRet := .F.

	// variaveis temporarias
	Local _cQryConf := ""
	Local cNewAlias := GetNextAlias()
	Local nX := 0
	Local nSaldoCtg := 0
	Local cTmpCodPro := ""
	local _cQryMapa
	// area atual
	Local aAreaAtu := GetArea()

	// estrutura do arquivo de trabalho e Browse
	Local aEstBrowse := {}
	Local aHeadBrowse := {}
	Local cArqTmp
	Local cMarca := Z07->(GetMark())
	local _aCorDiverg := {}

	// controle de divergencias
	Local _lDiverg   := .F.  // divergências graves/produto/lote
	Local _lDivTpEst := .F.  // divergência do tipo de estoque
	
	// controle se permite finalizar a OS
	local _lFinalOk := .T.
	// controle de sobras
	local _lSobras := .F.

	// informacoes do resumo
	local _nTotPesoB  := 0
	local _nTotCubag  := 0
	local _nTotVolume := 0
	local _nTotPalete := 0

	private _TRBCNF := GetNextAlias()

	// adiciona as cores para divergencia no browse
	aAdd(_aCorDiverg, {"Empty((_TRBCNF)->IT_COR)"   ,"DISABLE"})
	aAdd(_aCorDiverg, {"!(Empty((_TRBCNF)->IT_COR))","ENABLE" })

	// valida se pode finalizar sem o mapa gerado
	If ( ! _lFinSemMapa )
		// verifica se ha mapa de armazenagem gerado
		_cQryMapa := " SELECT COUNT(*) QTD_MAPA "
		// mapa de armazenagem
		_cQryMapa += " FROM "+RetSqlTab("Z08")+" (nolock) "
		// filtro padrao
		_cQryMapa += " WHERE "+RetSqlCond("Z08")
		// numero da OS
		_cQryMapa += " AND Z08_NUMOS = '"+_cNumOrdSrv+"' "

		If (U_FtQuery(_cQryMapa) == 0)
			U_FtWmsMsg("Não há mapa de armazenagem definido. Favor verificar pendência com o supervisor.", "ATENÇÃO")
			Return(.F.)
		EndIf
	EndIf

	// solicita confirmacao
	If ( ! U_FtYesNoMsg("Finalizar Conferência?") )
		Return(.F.)
	EndIf



	// verifica se tem mais usuarios na mesma contagem sem ter finalizado
	_cQryConf := " SELECT COUNT(*) QTD_ITENS FROM "+RetSqlTab("Z07")+" (nolock) "
	_cQryConf += " WHERE "+RetSqlCond("Z07")
	_cQryConf += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	_cQryConf += " AND Z07_NRCONT = '"+_cNrContagem+"' "
	// C-EM CONFERENCIA
	_cQryConf += " AND Z07_STATUS = 'C' "

	// executa a query de verificacao
	If (U_FtQuery(_cQryConf)>0)
		U_FtWmsMsg("Existem Operadores com conferência em aberto. Favor verificar antes de prosseguir.", "Finalizar")
		Return(.F.)
	EndIf

	// verifica as mercadorias con divergencias no tipo de estoque
	_cQryConf := " SELECT COUNT(DISTINCT Z07_TPESTO) QTD_TPEST "
	// itens conferidos
	_cQryConf += " FROM "+RetSqlTab("Z07")+" (nolock) "
	// filtro padrao
	_cQryConf += " WHERE "+RetSqlCond("Z07")
	// nr de OS
	_cQryConf += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	// nr de contagem
	_cQryConf += " AND Z07_NRCONT = '"+_cNrContagem+"' "

	// executa a query de verificacao
	If (U_FtQuery(_cQryConf) > 1)
		// mensagens
		U_FtWmsMsg("Ordem de Serviço contém divergências no tipo de estoque. Favor solicitar autorização ao seu Supervisor.", "Finalizar")
		// seta como divergencia
		_lDivTpEst := .T.
	EndIf

	// fecha o alias
	If (Select(cNewAlias)!=0)
		dbSelectArea(cNewAlias)
		dbCloseArea()
	EndIf

	If !(_lPreConf)

		// query para verificacao/analise da divergencia
		_cQryConf := "SELECT '  ' IT_OK, 'OK' IT_COR, "
		_cQryConf += "Z06_NRCONT, Z06_LOCAL, Z06_ENDSRV, Z04_ITEMNF, Z04_PROD, Z04_NUMSEQ, B1_DESC, B1_UM, "
		_cQryConf += "SUM(Z04_QUANT) Z04_QUANT, "

		// quantidade conferida por produto
		_cQryConf += "("
		_cQryConf += " SELECT ISNULL(SUM(Z07_QUANT),0) FROM "+RetSqlName("Z07")+" Z07 (nolock)  "
		_cQryConf += " WHERE "+RetSqlCond("Z07")+" "
		_cQryConf += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		_cQryConf += " AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
		_cQryConf += " AND Z07_NRCONT = Z06_NRCONT "
		_cQryConf += " AND Z07_PRODUT = Z04_PROD "
		_cQryConf += " AND Z07_NUMSEQ = Z04_NUMSEQ "
		_cQryConf += ") Z07_QUANT, "
		// peso bruto
		_cQryConf += "B1_PESBRU, "
		_cQryConf += "0 TOT_PESBRU, "
		// cubagem/m3
		_cQryConf += "ISNULL(B5_COMPRLC,0) B5_COMPRLC, "
		_cQryConf += "ISNULL(B5_LARGLC ,0) B5_LARGLC,  "
		_cQryConf += "ISNULL(B5_ALTURLC,0) B5_ALTURLC, "
		_cQryConf += "0 TOT_CUBAGE, "
		// quantidade de paletes
		_cQryConf += "("
		_cQryConf += " SELECT ISNULL(COUNT(DISTINCT Z07_PALLET),0) FROM "+RetSqlTab("Z07")+" (nolock) "
		_cQryConf += " WHERE "+RetSqlCond("Z07")
		_cQryConf += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		_cQryConf += " AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
		_cQryConf += " AND Z07_NRCONT = Z06_NRCONT "
		_cQryConf += ") QTD_PALETE, "
		// quantidade de volumes
		If (_lCtrVolume)
			_cQryConf += "("
			_cQryConf += " SELECT ISNULL(COUNT(DISTINCT Z07_ETQVOL),0) FROM "+RetSqlTab("Z07")+" (nolock) "
			_cQryConf += " WHERE "+RetSqlCond("Z07")
			_cQryConf += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
			_cQryConf += " AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
			_cQryConf += " AND Z07_NRCONT = Z06_NRCONT "
			_cQryConf += ") QTD_VOLUME, "
		EndIf
		// saldo da contagem por produto
		_cQryConf += "0 IT_SALDO, "
		// campos para controle de devolucoes/sobras
		_cQryConf += "0 IT_QTDDEVO, 0 IT_QTDSOBR, "

		// valida quantidade do lote conferido
		_cQryConf += "        (SELECT Isnull(Sum(Z07_QUANT), 0)
		_cQryConf += "         FROM   "+RetSqlTab("Z07")+" (nolock) "
		_cQryConf += "         WHERE  "+RetSqlCond("Z07")
		_cQryConf += "                AND Z07_NUMOS  = '"+_cNumOrdSrv+"' "
		_cQryConf += "                AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		_cQryConf += "                AND Z07_CLIENT = '"+_cCodCliFor+"' "
		_cQryConf += "                AND Z07_LOJA  = '"+_cLojCliFor+"' "
		_cQryConf += "                AND Z07_NRCONT = Z06_NRCONT "
		_cQryConf += "                AND Z07_PRODUT = Z04_PROD "
		_cQryConf += "                AND Z07_NUMSEQ = Z04_NUMSEQ "
		_cQryConf += "                AND Z07_LOTCTL = Z04_LOTCTL) QTD_LOTE, "
		// campo para status do lote
		_cQryConf += " CASE																		 "
		_cQryConf += "   WHEN (SELECT Isnull(Sum(Z07_QUANT), 0)									 "
		_cQryConf += "         FROM   " + RetSqlTab("Z07") + " (NOLOCK)							 "
		_cQryConf += "         WHERE  " + RetSqlCond("Z07")										 
		_cQryConf += "                AND Z07_NUMOS  = '" + _cNumOrdSrv + "'						 "
		_cQryConf += "                AND Z07_SEQOS  = '" + _cSeqOrdSrv + "'						 "
		_cQryConf += "                AND Z07_CLIENT = '" + _cCodCliFor + "'						 "
		_cQryConf += "                AND Z07_LOJA   = '" + _cLojCliFor + "'						 "
		_cQryConf += "                AND Z07_NRCONT = Z06_NRCONT								 "
		_cQryConf += "                AND Z07_PRODUT = Z04_PROD									 "
		_cQryConf += "                AND Z07_NUMSEQ = Z04_NUMSEQ								 "
		_cQryConf += "                AND Z07_LOTCTL = Z04_LOTCTL) > 0 THEN 'CONFERENCIA LOTE OK' "
		_cQryConf += "   ELSE 'LOTE DIVERGENTE'													 "
		_cQryConf += " END                                  AS 'STS_LOTE'                         "

		// cabecalho da OS
		_cQryConf += "FROM "+RetSqlName("Z05")+" Z05 (nolock)  "
		// itens da nota fiscal amarrada ao CESC
		_cQryConf += "INNER JOIN "+RetSqlTab("Z04")+" (nolock)  ON "+RetSqlCond("Z04")+" AND Z04_CESV = Z05_CESV "
		// itens da OS
		_cQryConf += "INNER JOIN "+RetSqlTab("Z06")+" (nolock)  ON "+RetSqlCond("Z06")+" AND Z06_NUMOS = Z05_NUMOS "
		_cQryConf += "AND Z06_SERVIC = '"+_cCodServ+"' AND Z06_TAREFA = '"+_cCodTaref+"' "
		// cad. de produtos
		_cQryConf += "INNER JOIN "+RetSqlTab("SB1")+" (nolock)  ON "+RetSqlCond("SB1")+" AND B1_COD = Z04_PROD "
		// complemento de produtos
		_cQryConf += "LEFT  JOIN "+RetSqlTab("SB5")+" (nolock)  ON "+RetSqlCond("SB5")+" AND B5_COD = Z04_PROD "

		// filtra o cabecalho da OS
		_cQryConf += " WHERE "+RetSqlCond("Z05")
		_cQryConf += " AND Z05_NUMOS  = '"+_cNumOrdSrv+"' "
		_cQryConf += " AND Z05_CLIENT = '"+_cCodCliFor+"' AND Z05_LOJA  = '"+_cLojCliFor+"' "
		// agrupa os dados
		_cQryConf += " GROUP BY Z06_NRCONT, Z06_LOCAL, Z06_ENDSRV, Z04_ITEMNF, Z04_PROD, Z04_NUMSEQ, B1_DESC, B1_UM, B1_PESBRU, B5_COMPRLC, B5_LARGLC, B5_ALTURLC, Z04_LOTCTL "
		// ordem por codigo
		_cQryConf += " ORDER BY Z04_PROD "

		MemoWrit("c:\QUERY\twmsa010_sfFinalizaOS.txt",_cQryConf)

	Else // se for pre-conferencia
		_cQryConf := "SELECT '  '                                  IT_OK,      "
		_cQryConf += "        'OK'                                 IT_COR,     "
		_cQryConf += "        Z07_PRODUT,                                      "
		_cQryConf += "        B1_DESC,                                         "
		_cQryConf += "        B1_UM,                                           "
		_cQryConf += "        Sum(Z07_QUANT)                       Z07_QUANT,  "
		_cQryConf += "        B1_PESBRU,                                       "
		_cQryConf += "        0                                    TOT_PESBRU, "
		_cQryConf += "        Isnull(B5_COMPRLC, 0)                B5_COMPRLC, "
		_cQryConf += "        Isnull(B5_LARGLC, 0)                 B5_LARGLC,  "
		_cQryConf += "        Isnull(B5_ALTURLC, 0)                B5_ALTURLC, "
		_cQryConf += "        0                                    TOT_CUBAGE, "

		_cQryConf += "        (SELECT Isnull(Count(DISTINCT Z07_PALLET), 0)    "
		_cQryConf += "         FROM   " + RetSqlTab("Z07") + " (NOLOCK)        "
		_cQryConf += "         WHERE  " + RetSqlCond("Z07")
		_cQryConf += "         AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		_cQryConf += "         AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
		_cQryConf += "         AND Z07_NRCONT = Z06_NRCONT) QTD_PALETE, "

		_cQryConf += "        (SELECT Isnull(Count(DISTINCT Z07_ETQVOL), 0)    "
		_cQryConf += "         FROM   " + RetSqlTab("Z07") + " (NOLOCK)        "
		_cQryConf += "         WHERE  " + RetSqlCond("Z07")
		_cQryConf += "         AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		_cQryConf += "         AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
		_cQryConf += "         AND Z07_NRCONT = Z06_NRCONT) QTD_VOLUME, "

		_cQryConf += "        (SELECT Isnull(Sum(Z07_QUANT), 0)                "
		_cQryConf += "         FROM   " + RetSqlTab("Z07") + " (NOLOCK)        "
		_cQryConf += "         WHERE  " + RetSqlCond("Z07")
		_cQryConf += "         AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		_cQryConf += "         AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
		_cQryConf += "         AND Z07_NRCONT = Z06_NRCONT) QTD_LOTE    "


		_cQryConf += " FROM   " + RetSqlTab("Z05") + " (nolock)                "
		_cQryConf += "        INNER JOIN " + RetSqlTab("Z06") + " (nolock)     "
		_cQryConf += "                ON " + RetSqlCond("Z06")
		_cQryConf += "                   AND Z06_NUMOS = Z05_NUMOS             "
		_cQryConf += "                   AND Z06_SERVIC = '015'                "
		_cQryConf += "                   AND Z06_TAREFA = '014'                "
		_cQryConf += "        INNER JOIN " + RetSqlTab("Z07") + " (nolock)     "
		_cQryConf += "                ON " + RetSqlCond("Z07")
		_cQryConf += "                   AND Z07_NUMOS = Z05_NUMOS             "
		_cQryConf += "                   AND Z07_NRCONT = Z06_NRCONT           "
		_cQryConf += "        INNER JOIN " + RetSqlTab("SB1") + " (nolock)     "
		_cQryConf += "                ON " + RetSqlCond("SB1")
		_cQryConf += "                   AND B1_COD = Z07_PRODUT               "
		_cQryConf += "        LEFT JOIN " + RetSqlTab("SB5") + " (nolock)      "
		_cQryConf += "               ON " + RetSqlCond("SB5")
		_cQryConf += "                  AND B5_COD = Z07_PRODUT                "
		_cQryConf += " WHERE  " + RetSqlCond("Z05")
		_cQryConf += "        AND Z05_NUMOS  = '" + _cNumOrdSrv + "'           "
		_cQryConf += "        AND Z05_CLIENT = '" + _cCodCliFor + "'           "
		_cQryConf += "        AND Z05_LOJA   = '" + _cLojCliFor + "'           "
		_cQryConf += " GROUP  BY Z06_NRCONT,                                   "
		_cQryConf += "           Z06_LOCAL,                                    "
		_cQryConf += "           Z06_ENDSRV,                                   "
		_cQryConf += "           Z07_PRODUT,                                   "
		_cQryConf += "           B1_DESC,                                      "
		_cQryConf += "           B1_UM,                                        "
		_cQryConf += "           B1_PESBRU,                                    "
		_cQryConf += "           B5_COMPRLC,                                   "
		_cQryConf += "           B5_LARGLC,                                    "
		_cQryConf += "           B5_ALTURLC,                                   "
		_cQryConf += "           Z07_LOTCTL                                    "
		_cQryConf += " ORDER  BY Z07_PRODUT                                    "

	EndIf

	//_cQryConf := ChangeQuery(_cQryConf)
	dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQryConf),cNewAlias,.F.,.T.)

	// pega a estrutura do select
	aEstBrowse := (cNewAlias)->(dbStruct())

	If (Select(_TRBCNF)<>0)
		dbSelectArea(_TRBCNF)
		dbCloseArea()
	EndIf

	// criar um arquivo de trabalho
	cArqTmp := FWTemporaryTable():New( _TRBCNF )
	cArqTmp:SetFields( aEstBrowse )
	cArqTmp:Create()

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQryConf,aEstBrowse,_TRBCNF)

	// fecha a query
	dbSelectArea(cNewAlias)
	dbCloseArea()

	// verifica itens com divergencia
	(_TRBCNF)->(dbSelectArea(_TRBCNF))
	(_TRBCNF)->(dbGoTop())
	While (_TRBCNF)->(!Eof())

		// edita registro
		RecLock(_TRBCNF,.F.)
		If !(_lPreConf)
			// atualiza o saldo do item
			(_TRBCNF)->IT_SALDO	:= (_TRBCNF)->Z07_QUANT
			(_TRBCNF)->IT_OK		:= IIf(((_TRBCNF)->Z07_QUANT != (_TRBCNF)->Z04_QUANT) .Or. ((_lLotAtivo) .And. (_lLotObrEnt) .And. ((_TRBCNF)->QTD_LOTE != (_TRBCNF)->Z04_QUANT)), cMarca, Space(2))
			(_TRBCNF)->IT_COR		:= IIf(((_TRBCNF)->Z07_QUANT != (_TRBCNF)->Z04_QUANT) .Or. ((_lLotAtivo) .And. (_lLotObrEnt) .And. ((_TRBCNF)->QTD_LOTE != (_TRBCNF)->Z04_QUANT)), Space(2), cMarca)
			// calcula devolucoes
			(_TRBCNF)->IT_QTDDEVO	:= IIf((_TRBCNF)->Z07_QUANT < (_TRBCNF)->Z04_QUANT, (_TRBCNF)->Z04_QUANT - (_TRBCNF)->Z07_QUANT, 0)
			// calcula sobras
			(_TRBCNF)->IT_QTDSOBR	:= IIf((_TRBCNF)->Z07_QUANT > (_TRBCNF)->Z04_QUANT, (_TRBCNF)->Z07_QUANT - (_TRBCNF)->Z04_QUANT, 0)
		Endif
		// peso bruto
		(_TRBCNF)->TOT_PESBRU := (_TRBCNF)->B1_PESBRU * (_TRBCNF)->Z07_QUANT
		// cubagem
		(_TRBCNF)->TOT_CUBAGE := (_TRBCNF)->( B5_COMPRLC * B5_LARGLC * B5_ALTURLC ) * (_TRBCNF)->Z07_QUANT

		If ((_lLotAtivo) .And. (_lLotObrEnt) .And. ((_TRBCNF)->QTD_LOTE != (_TRBCNF)->Z04_QUANT)) .AND. !(_lPreConf)
			// status da divergecia de lote
			(_TRBCNF)->STS_LOTE := "DIVERGÊNCIA"
			// informa que há divergências
			_lDiverg := .T.
		EndIf

		// confirma os dados
		(_TRBCNF)->(MsUnLock())

		// verifica se tem divergencias
		If !(_lPreConf)

			If ( ! Empty((_TRBCNF)->IT_OK))
				_lDiverg := .T.
			EndIf

			// verifica se tem falta fiscal, e nao permite finalizar
			If ((_TRBCNF)->IT_QTDSOBR != 0)
				_lFinalOk := .F.
				_lSobras  := .T.
			EndIf
		EndIf

		// atualiza variaveis do resumo
		_nTotPesoB  += (_TRBCNF)->TOT_PESBRU
		_nTotCubag  += (_TRBCNF)->TOT_CUBAGE
		// volume e totald e palete
		_nTotVolume := IIf(_lCtrVolume, (_TRBCNF)->QTD_VOLUME, _nTotVolume += (_TRBCNF)->Z07_QUANT)
		_nTotPalete := (_TRBCNF)->QTD_PALETE

		// proximo item
		(_TRBCNF)->(dbSkip())
	EndDo
	(_TRBCNF)->(dbGoTop())

	// abre o arquivo de trabalho
	(_TRBCNF)->(dbSelectArea(_TRBCNF))
	(_TRBCNF)->(dbGoTop())

	// inclui detalhes e titulos dos campos do browse
	If !(_lPreConf)
		aAdd(aHeadBrowse,{"IT_OK"       ,,"  "              , Nil                         })
		aAdd(aHeadBrowse,{"Z04_ITEMNF"  ,,"Item NF"         , Nil                         })
		aAdd(aHeadBrowse,{"Z04_PROD"    ,,"Cód. Produto"    , Nil                         })
		aAdd(aHeadBrowse,{"B1_DESC"     ,,"Descrição"       , Nil                         })
		aAdd(aHeadBrowse,{"B1_UM"       ,,"Und.Med."        , Nil                         })
		aAdd(aHeadBrowse,{"Z04_QUANT"   ,,"Qtd.NF"          , _cMaskQuant                 })
		aAdd(aHeadBrowse,{"Z07_QUANT"   ,,"Qtd.Conferida"   , _cMaskQuant                 })
		aAdd(aHeadBrowse,{"TOT_PESBRU"  ,,"Peso Bruto Total", PesqPict("SF1","F1_PBRUTO") })
		aAdd(aHeadBrowse,{"TOT_CUBAGE"  ,,"Cubagem Total"   , PesqPict("SF1","F1_CUBAGEM")})
		aAdd(aHeadBrowse,{"Z06_LOCAL"   ,,"Local"           , Nil                         })
		aAdd(aHeadBrowse,{"Z06_ENDSRV"  ,,"End. Srv."       , Nil                         })
		aAdd(aHeadBrowse,{"IT_QTDDEVO"  ,,"Devolver"        , _cMaskQuant                 })
		aAdd(aHeadBrowse,{"IT_QTDSOBR"  ,,"Sobra"           , _cMaskQuant                 })
		aAdd(aHeadBrowse,{"STS_LOTE"    ,,"Status Lote"     , "@!"                        })
	Else
		aAdd(aHeadBrowse,{"IT_OK"       ,,"  "              , Nil                         })
		aAdd(aHeadBrowse,{"Z07_PRODUT"    ,,"Cód. Produto"    , Nil                         })
		aAdd(aHeadBrowse,{"B1_DESC"     ,,"Descrição"       , Nil                         })
		aAdd(aHeadBrowse,{"B1_UM"       ,,"Und.Med."        , Nil                         })
		aAdd(aHeadBrowse,{"Z07_QUANT"   ,,"Qtd.Conferida"   , _cMaskQuant                 })
		aAdd(aHeadBrowse,{"TOT_PESBRU"  ,,"Peso Bruto Total", PesqPict("SF1","F1_PBRUTO") })
		aAdd(aHeadBrowse,{"TOT_CUBAGE"  ,,"Cubagem Total"   , PesqPict("SF1","F1_CUBAGEM")})
	EndIf
	// abre o arquivo de trabalho
	(_TRBCNF)->(dbSelectArea(_TRBCNF))
	(_TRBCNF)->(dbGoTop())

	// apresenta mensagem em caso de sobra de mercadoria
	If (_lSobras)
		U_FtWmsMsg("Ocorreu SOBRA de mercadoria na conferência e não será permitido finalizar a Ordem de Serviço. Favor solicitar Documento Complementar.","ATENCAO")
	EndIf

	// monta a tela com os detalhes da finalizacao total da OS
	_oWndConFinal := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Conf. Mercadoria (Entrada)",,,.F.,,,,,,.T.,,,.T. )
	_oWndConFinal:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlCfeFinCab1 := TPanel():New(000,000,nil,_oWndConFinal,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlCfeFinCab1:Align:= CONTROL_ALIGN_TOP

	// INICIO - define os botoes de operacao  =====

	// define o botao para finalizar a conferencia
	If !(_lDiverg .AND. _lDivTpEst) .And. (_lFinalOk)         //sem divergências
		_oBmpCfeFinConf := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| MsgRun("Aguarde. Selecionando Dados...",,{|| _lRet := sfFinServico(_lDiverg, _lDivTpEst) }) },_oPnlCfeFinCab,"Finaliza a Conferência",,.T. )
		_oBmpCfeFinConf:Align := CONTROL_ALIGN_LEFT
	ElseIf (_lDiverg .OR. _lDivTpEst) .And. (_lFinalOk) .And. ( (_lUsrGeren) .Or. (_lUsrSuper) .Or. ( _lUsrLider ) )    //com alguma divergencia, somente supervisor
		_oBmpCfeFinConf := TBtnBmp2():New(000,000,060,022,"COMIMG32",,,,{|| MsgRun("Aguarde. Selecionando Dados...",,{|| _lRet := sfFinServico(_lDiverg, _lDivTpEst) }) },_oPnlCfeFinCab,"Finaliza a Conferência",,.T. )
		_oBmpCfeFinConf:Align := CONTROL_ALIGN_LEFT
	EndIf

	// -- BOTAO PARA FECHAR A TELA
	_oBmpCfeFechar := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| _oWndConFinal:End() },_oPnlCfeFinCab,"Sair",,.T. )
	_oBmpCfeFechar:Align := CONTROL_ALIGN_RIGHT

	// resumo da operacao
	_oPnlCfeFinCab2 := TPanel():New(000,000,nil,_oWndConFinal,,.F.,.F.,,,040,040,.T.,.F.)
	_oPnlCfeFinCab2:Align:= CONTROL_ALIGN_TOP

	// status conferencia
	_oSayStatus := TSay():New(003,004,{||"Status: "+IIf( (_lDiverg .OR. _lDivTpEst) ,"DIVERGÊNCIAS","OK") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.,IIf( (_lDiverg .OR. _lDivTpEst),CLR_HRED,CLR_GREEN) )
	// total PESO BRUTO
	_oSayTotPB  := TSay():New(010,004,{||"PESO BRUTO: " + AllTrim(Transf(_nTotPesoB, PesqPict("SF1","F1_PBRUTO"))) },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)
	// total CUBAGEM
	_oSayTotCB  := TSay():New(017,004,{||"CUBAGEM: "+Transf(_nTotCubag,"@E 999,999.999") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)
	// total VOLUMES
	_oSayTotVL  := TSay():New(024,004,{||"QUANTIDADE: "+Transf(_nTotVolume, _cMaskQuant) },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)
	// total PALETES
	_oSayTotPL  := TSay():New(031,004,{||"PALETES: "+Transf(_nTotPalete,"@E 999,999,999") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)

	// browse com a listagem dos produtos conferidos
	_oBrwFinaliza := MsSelect():New( _TRBCNF,"IT_OK",,aHeadBrowse,,cMarca,{15,1,183,373},,,,,_aCorDiverg)
	_oBrwFinaliza:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oWndConFinal

	// atualiza variaveis da tela de conferencia
	If (_lRet)
		mvTelaOk := _lRet
		mvTela:End()
	EndIf

	// fecha arquivo de trabalho
	(_TRBCNF)->(dbSelectArea(_TRBCNF))
	dbCloseArea()
	cArqTmp:Delete()

	// restaura area inicial
	RestArea(aAreaAtu)

Return(_lRet)

// ** funcao que encerra o servico de conferencia
Static Function sfFinServico(mvDiverg, mvDivTpEst)
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z05","Z06","SD1","SZZ"})

	// variavel de retorno
	local _lRet := .T.

	Local _cQryArmaz
	local _cQryPalete

	// itens para devolucao (veio a menos)
	Local _aDevolucao := {}
	local _cItemDB, _nModOld, _cModOld
	local _aCabSDA, _aItemSDB

	Local aDadosSD1 := 0
	Local aItemDevol := {}

	// data e hora de emissao
	local _dDtEmissao := Date()
	local _cHrEmissao := Time()

	// dados para gerar o TFAA
	local _cNrPvTFAA  := ""
	local _cNumTFAA   := ""
	local _aDadosTFAA := {}

	// anexos de email
	local _aAnexos := {}

	// validação para caso seja cancelamento de carregamento (T03) e tem divergencia
	If (_cCodServ == 'T03') .And. (mvDiverg)
		MsgStop("Não é permitido encerrar ordem de serviço do tipo 'cancelamento de carregamento' com divergências de produtos!")
		_lRet := .F.

		Return(_lRet)
	EndIf

	//pergunta se tem certeza para finalizar
	IIF ( (mvDiverg .OR. mvDivTpEst),;
	_lRet := U_FtYesNoMsg("Tem certeza que deseja finalizar a ordem de serviço com divergências?","Atenção supervisor!") ,;
	_lRet := U_FtYesNoMsg("Tem certeza que deseja finalizar a ordem de serviço?","Atenção!") )

	// valida senha do supervisor quando tem divergencia
	If (_lRet) .And. (mvDiverg .OR. mvDivTpEst)

		// solicita senha de confirmacao do Gerente ou Supervisor ou Lider
		_lRet := sfVldUser("G|S|L")

	EndIf

	// caso tenha retorno negativo
	If ( ! _lRet)
		Return(_lRet)
	EndIf


	// inicia transacao
	BEGIN TRANSACTION

		If !(_lPreConf) // serviço de pré-conferência não gera TFAA, pois não tem com o que comparar

			// abre o arquivo de trabalho com o resultado da conferencia
			(_TRBCNF)->(dbSelectArea(_TRBCNF))
			(_TRBCNF)->(dbGoTop())

			// varre todos os itens
			While ( !(_TRBCNF)->(Eof()) )

				// posiciona no item da nota de entrada
				dbSelectArea("SD1")
				SD1->(dbSetOrder(4)) // 4-D1_FILIAL, D1_NUMSEQ
				SD1->(dbSeek( xFilial("SD1")+(_TRBCNF)->Z04_NUMSEQ ))

				// dados para o TFAA
				aAdd(_aDadosTFAA,{_cNumOrdSrv,;
				_cNumCESV           ,;
				SD1->D1_TIPO        ,;
				SD1->D1_DOC         ,;
				SD1->D1_SERIE       ,;
				SD1->D1_ITEM        ,;
				SD1->D1_COD         ,;
				(_TRBCNF)->Z04_QUANT  ,;
				(_TRBCNF)->Z07_QUANT  ,;
				(_TRBCNF)->IT_QTDSOBR ,;
				(_TRBCNF)->IT_QTDDEVO ,;
				(_TRBCNF)->Z04_NUMSEQ })

				// se tiver quantidades conferidas a menos, gera DEVOLUCOES para o cliente
				If ((_TRBCNF)->IT_QTDDEVO > 0)

					// inclui item para gerar pedido de devolucao
					// 1. Item da NF Orig 	- D1_ITEM
					// 2. Cod Produto		- D1_COD
					// 3. Quant Devolvida	- Saldo Negativo da Conf.
					// 4. Valor Unitario	- D1_VUNIT
					// 5. Numero Nota Orig	- D1_DOC
					// 6. Serie Nota Orig	- D1_SERIE
					// 7. TES Doc Orig		- D1_TES
					// 8. Ident SB6			- D1_IDENTB6
					// 9. Lote		     	- D1_LOTECTL
					// 10 Data validade     - D1_DTVALID
					aAdd(_aDevolucao,{SD1->D1_ITEM, SD1->D1_COD, (_TRBCNF)->IT_QTDDEVO, SD1->D1_VUNIT, SD1->D1_DOC, SD1->D1_SERIE, SD1->D1_TES, SD1->D1_IDENTB6, SD1->D1_LOTECTL, "31/12/2049" })

					// realiza o enderecamento da diferenca, para um endereco de devolucoes

					// posiciona nos itens a enderecar
					dbSelectArea("SDA")
					SDA->(dbSetORdeR(1)) // 1-DA_FILIAL, DA_PRODUTO, DA_LOCAL, DA_NUMSEQ, DA_DOC, DA_SERIE, DA_CLIFOR, DA_LOJA, R_E_C_N_O_, D_E_L_E_T_
					SDA->(dbSeek( xFilial("SDA")+SD1->D1_COD+SD1->D1_LOCAL+SD1->D1_NUMSEQ ))

					// pesquisa a ultimo item utilizado
					_cItemDB := A265UltIt('C')
					// proximo item valido
					_cItemDB := Soma1(_cItemDB)

					// armazena modulo atual
					_nModOld := nModulo
					_cModOld := cModulo

					// muda o modlulo para WMS
					nModulo := 42
					cModulo := "WMS"

					// zera variaveis
					_aCabSDA  := {}
					_aItemSDB := {}

					// cabecalho de movimentacao da mercadoria
					_aCabSDA := {{"DA_FILIAL"	,SDA->DA_FILIAL ,NIL},;
					{"DA_PRODUTO"	,SDA->DA_PRODUTO,NIL},;
					{"DA_QTDORI"	,SDA->DA_QTDORI	,NIL},;
					{"DA_SALDO"		,SDA->DA_SALDO	,NIL},;
					{"DA_DATA"  	,dDataBase		,NIL},;
					{"DA_LOTECTL"	,SDA->DA_LOTECTL,NIL},;
					{"DA_DOC"		,SDA->DA_DOC	,NIL},;
					{"DA_SERIE"		,SDA->DA_SERIE	,NIL},;
					{"DA_CLIFOR"	,SDA->DA_CLIFOR	,NIL},;
					{"DA_LOJA"		,SDA->DA_LOJA	,NIL},;
					{"DA_TIPONF"	,SDA->DA_TIPONF	,NIL},;
					{"DA_NUMSEQ"	,SDA->DA_NUMSEQ	,NIL},;
					{"DA_LOCAL"		,SDA->DA_LOCAL	,NIL},;
					{"DA_ORIGEM"	,SDA->DA_ORIGEM	,NIL}}

					// item da movimentacao da mercadoria
					Aadd(_aItemSDB,  {{"DB_FILIAL"	,xFilial("SDB")	,NIL},;
					{"DB_ITEM"		,_cItemDB            ,NIL},;
					{"DB_LOCAL"		,SDA->DA_LOCAL       ,NIL},;
					{"DB_ESTORNO" 	," "                 ,Nil},;
					{"DB_LOCALIZ"	,_cEndDevCli         ,NIL},;
					{"DB_PRODUTO"	,SDA->DA_PRODUTO     ,NIL},;
					{"DB_DOC"		,SDA->DA_DOC         ,NIL},;
					{"DB_SERIE"		,SDA->DA_SERIE       ,NIL},;
					{"DB_NUMSEQ"	,SDA->DA_NUMSEQ      ,NIL},;
					{"DB_DATA"		,dDataBase           ,NIL},;
					{"DB_QUANT"		,(_TRBCNF)->IT_QTDDEVO ,NIL},;
					{"DB_ZNUMOS"	,_cNumOrdSrv         ,NIL},;
					{"DB_ZSEQOS"	,_cSeqOrdSrv         ,NIL},;
					{"DB_ZLOTECT"	,SDA->DA_LOTECTL     ,NIL}})

					// executa funcao padrao de distribuicao da mercadoria
					lMsErroAuto := .F.
					MSExecAuto({|x,y,z| mata265(x,y,z)},_aCabSDA,_aItemSDB,3) //Distribui

					// retorna o modulo padrao
					nModulo := _nModOld
					cModulo := _cModOld

					// se ocorreu erro na rotina automatica
					If (lMsErroAuto)
						DisarmTransaction()
						U_FtWmsMsg(sfAchaErro(),"ATENCAO")
						_lRet := .F.
						Exit
					Endif
				EndIf

				// proximo item
				(_TRBCNF)->(dbSkip())
			EndDo

			// se ocorreu normalmente, grava o pedido de venda de devolucao de mercadoria
			If (_lRet) .And. (mvDiverg) .And. (Len(_aDevolucao)>0)
				// rotina para gravar pedido de venda com as devolucoes
				If ( ! sfGrvDevol(@_cNrPvTFAA, _aDevolucao))
					// variavel de retorno
					_lRet := .F.
				EndIf
			EndIf

			// se ocorreu normalmente, grava o TFAA
			If (_lRet) .And. (mvDiverg) .And. (Len(_aDadosTFAA)>0)

				// rotina para gerar o TFAA
				If ( ! sfGrvTFAA(@_cNumTFAA, _aDadosTFAA, _cNrPvTFAA))

					// rollback na transacao
					DisarmTransaction()
					// variavel de retorno
					_lRet := .F.

				EndIf

				// grava o numero do TFAA na OS
				If (_lRet)
					dbSelectArea("Z05")
					RecLock("Z05")
					Z05->Z05_TFAA   := _cNumTFAA
					Z05->Z05_PVTFAA := _cNrPvTFAA
					Z05->(MsUnLock())
				EndIf

			EndIf
		EndIf

		// se tudo ok
		If (_lRet)

			// atualiza o status do servico para FI-FINALIZADO se tudo ok ou  "AN-EM ANALISE" se tiver TFAA e depende do gerente liberar
			U_FtWmsSta(_cCodStatus,;
			IIf( (mvDiverg .OR. _lPreconf) , "AN", "FI") ,;
			_cNumOrdSrv ,;
			_cSeqOrdSrv )

			// se cliente Sumitomo, gera arquivo EDI para integração contendo as etiquetas do cliente (barcodes) lidos/conferidos
			If (_cCodCliFor == "000316") .AND. (lSumiBar)
				ExecBlock("TWMSA048",.F.,.F.,{"E",_cNumOrdSrv, _cSeqOrdSrv, _cCodCliFor, _cLojCliFor})
			EndIf

			// se cliente MIDEA, envia email com as etiquetas do cliente (barcodes) lidos/conferidos
			If (_cCodCliFor == "000603") 
				Aadd(_aAnexos, U_TECMID05(_cNumOrdSrv, .T.))  // gera o arquivo e pega o nome do arquivo bgerado

				//envia o email
				U_FtMail( "Este é um email automatizado, disparado pelo sistema WMS Tecadi após a finalização da conferência de recebimento da OS " + _cNumOrdSrv + ". Aguardamos o envio do arquivo de importação no SFTP, juntamente com a nota fiscal de armazenagem.",;
				"Resultado da conferência da OS Midea - " + _cNumOrdSrv,;
				"accounts103@tecadi.com.br",;
				_aAnexos)
			EndIf

			// registro do CESV
			dbSelectArea("SZZ")
			SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
			SZZ->(dbSeek( xFilial("SZZ")+_cNumCESV ))

			// valida o status o CESV
			If ( ! (SZZ->ZZ_STATUS $ "09|10"))

				// insere o log
				U_FtGeraLog(cFilAnt, "SZZ", xFilial("SZZ")+SZZ->ZZ_CESV, "Saída do veículo liberada (Status "+SZZ->ZZ_STATUS+" -> 09)", "WMS")

				// atualiza as informacoes das tabelas
				dbSelectArea("SZZ")
				RecLock("SZZ")
				SZZ->ZZ_STATUS := "09" // 09-SAIDA LIBERADA
				SZZ->ZZ_OPWMS  := "S"  // operado pelo WMS
				SZZ->(MsUnLock())

			EndIf

		EndIf

		// finaliza transacao
	END TRANSACTION

	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aArea)

	// fecha tela do resumo
	If (_lRet)
		_oWndConFinal:End()
	EndIf

Return(_lRet)

// ** funcao que inclui pedido de venda de devolucao
Static Function sfGrvDevol(mvNrPvTFAA, mvDevolucao)
	// variaveis para a rotina Mata410
	Local _aCabSC5 := {}
	Local _aItensSC6 := {}
	Local _cItem := StrZero(1,TamSx3("C6_ITEM")[1])

	// variavel de retorno
	local _lRet := .F.

	// variaveis temporarias
	Local _nIt := 0
	Local _aTmpItem := {}

	// Codigo da TES de Devolucao
	Local _cTESDevol := ""

	// prepara numero do pedido de venda
	mvNrPvTFAA := GetSXENum("SC5","C5_NUM")

	// posiciona no cadastro do cliente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
	SA1->(dbSeek( xFilial("SA1")+_cCodCliFor+_cLojCliFor ))

	// inclui informacoes no cabecalho do pedido de venda
	_aCabSC5	:= {;
	{"C5_NUM"     , mvNrPvTFAA , nil} ,; // numero do pedido de venda
	{"C5_TIPO"    ,"N"         , nil} ,; // tipo do pedido
	{"C5_CLIENTE" ,SA1->A1_COD , nil} ,; // Cod. Cliente
	{"C5_LOJAENT" ,SA1->A1_LOJA, nil} ,; // loja do cliente
	{"C5_LOJACLI" ,SA1->A1_LOJA, nil} ,; // Loja
	{"C5_TIPOCLI" ,SA1->A1_TIPO, nil} ,; // Tipo do Cliente
	{"C5_CONDPAG" ,"001"       , nil} ,; // Condicao de Pagamento
	{"C5_TIPOOPE" ,"P"         , nil} ,; // tipo da operacao (P-Produto)
	{"C5_VOLUME1" ,1           , nil} ,; // volumes
	{"C5_ESPECI1" ,"62"        , nil} ,; // especie / 62-volumes (tab CC SX5)
	{"C5_EMISSAO" ,dDataBase   , nil} }  // data de emissao

	// varre todos os itens para devolucao
	For _nIt := 1 to Len(mvDevolucao)
		// Estrutura do Array mvDevolucao
		// 1. Item da NF Orig 	- D1_ITEM
		// 2. Cod Produto		- D1_COD
		// 3. Quant Devolvida	- Saldo Negativo da Conf.
		// 4. Valor Unitario	- D1_VUNIT
		// 5. Numero Nota Orig	- D1_DOC
		// 6. Serie Nota Orig	- D1_SERIE
		// 7. TES Doc Orig		- D1_TES
		// 8. Ident SB6			- D1_IDENTB6

		// busca a TES de devolucao do item
		_cTESDevol := Posicione("SF4",1, xFilial("SF4")+mvDevolucao[_nIt,7] ,"F4_TESDV")

		// prepara item
		_aTmpItem := {;
		{"C6_ITEM"    , _cItem              , nil} ,; //Item do Pedido
		{"C6_PRODUTO" , mvDevolucao[_nIt,2] , nil} ,; // Codigo do Produto
		{"C6_QTDVEN"  , mvDevolucao[_nIt,3] , nil} ,; // Quantidade Devolvida
		{"C6_PRUNIT"  , mvDevolucao[_nIt,4] , nil} ,; //Preco Unitario
		{"C6_TES"     , _cTESDevol, nil}           ,; // TES
		{"C6_QTDLIB"  , mvDevolucao[_nIt,3] , nil} ,; // quantidade liberada
		{"C6_SERIORI" , mvDevolucao[_nIt,6] , nil} ,; // serie da nota original
		{"C6_NFORI"   , mvDevolucao[_nIt,5] , nil} ,; // numero nota original
		{"C6_ITEMORI" , mvDevolucao[_nIt,1] , nil} ,; // item da nota original
		{"C6_IDENTB6" , mvDevolucao[_nIt,8] , nil} ,; // ident SB6
		{"C6_LOCALIZ" , _cEndDevCli, nil}          ,; // endereco para retirada
		{"C6_LOTECTL" , mvDevolucao[_nIt,9] , nil} ,; // lote conforme nota fiscal de entrada
		{"C6_DTVALID" , mvDevolucao[_nIt,10], nil} ,; // data validade conforme nota fiscal de entrada
		{"AUTDELETA"	, "N", Nil}                } //Incluir sempre no último elemento do array de cada item
		
		
		// adiciona a Linha no Vetor de todos os Itens
		aAdd( _aItensSC6 , aClone(_aTmpItem) )
		// incrementa proximo item
		_cItem := SomaIt(_cItem)

	Next _nIt

	// inclui o Pedido
	If Len(_aItensSC6) > 0
		If(msgyesno('Ordena vetor de itens?','Mata410 dev'))
			fwvetbydic(_aItensSC6,'SC6',.t.)
		EndIf
		// prepara variaveis para chamada da rotina Mata410
		
		
		return({_aCabSC5, _aItensSC6})
		
		
		lMsErroAuto := .F.
		MsExecAuto({|x,y,z| Mata410(x,y,z)}, _aCabSC5, _aItensSC6, 3)

		// em caso de erro na rotina automatica
		If (lMsErroAuto)
			// rollback da operacao
			DisarmTransaction()
			RollBackSX8()

			// variavel de retorno
			_lRet := .F.

			// mensagem
			U_FtWmsMsg(sfAchaErro(),"ATENCAO")

			Return(_lRet)
		EndIf
		// confirma numeracao do pedido
		ConfirmSx8()
		// variavel de retorno
		_lRet := .T.

	Endif

Return(_lRet)

// ** funcao que Retorna o erro da Rotina Automatica
Static Function sfAchaErro()
	Local cStartPath:= GetSrvProfString("Startpath","")
	Local cFileLog	:= Alltrim(cStartPath) + Alltrim(NomeAutoLog())

	Local cRet		:= ""

	//Variavel Temp. For
	Local nPos := 0
	//Pega o Conteudo do Arquivo Texto do LOG
	Local cConteudo	:= MemoRead( cFileLog )

	MemoWrit("C:\Query\TWMSA010_MsErroAuto.txt", cConteudo)

	If "HELP: OBRIGAT" $ cConteudo
		cRet := StrTran(cConteudo,chr(13)+chr(10)," ")
	Else

		aConteudo := Separa(cConteudo,chr(13)+chr(10))

		For nPos := 1 to Len(aConteudo)
			If nPos == 1 .Or. nPos == 2
				cRet += aConteudo[nPos] +" "
			ElseIf "< -- Invalido" $ aConteudo[nPos]
				cRet += aConteudo[nPos] +" "
			EndIf

		Next nPos

	EndIf

	fErase(cFileLog)

Return cRet


// ** funcao para interromper o servico atual
Static Function sfInterromper(mvTela,mvTelaOk)

	If ( ! U_FtYesNoMsg("Interromper?","ATENÇÃO"))
		Return(.F.)
	EndIf

	// funcao generica para interromper atividade
	U_FtWmsMtInt(_cNumOrdSrv, _cSeqOrdSrv)
	mvTelaOk := .T.
	mvTela:End()

Return(.T.)

// ** funcao que solicita parametros para geracao do mapa
Static Function sfParamMapa(mvFiltros, mvCodProd, mvDscProd, mvQuant, mvQuantPal, mvTpGera, mvEstFisDes, mvLogRev, mvComPltFra)

	// configuracoes da estrutura
	local _aDetArmz
	// variavel de retorno
	local _lRet
	// parametros
	local mvRuaDe
	local mvRuaAte
	local _aLados
	local mvLado
	local mvPreDe
	local mvPreAte
	local mvAndDe
	local mvAndAte
	local mvBloco := CriaVar("BE_LOCALIZ", .F.)

	// objetos da tela
	local _oWndParamMapa
	local _oCbPltFra

	// descricao da estrutura fisica do destino
	local _cDscEstFis := AllTrim(Posicione("DC8", 1, xFilial("DC8")+mvEstFisDes, "DC8_DESEST"))

	// valores padroes
	Default mvLogRev    := .F.
	Default mvComPltFra := .F.

	// monta a tela para informar os filtros para geracao do mapa de armazenagem
	_oWndParamMapa := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Mapa Armazenagem",,,.F.,,,,,,.T.,,,.T. )
	_oWndParamMapa:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlParamCab := TPanel():New(000,000,nil,_oWndParamMapa,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlParamCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpParamOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRet := .T., _oWndParamMapa:End() },_oPnlParamCab,"Confirmar",,.T.)
	_oBmpParamOk:Align := CONTROL_ALIGN_LEFT

	// Titulo
	_oSayTitulo := TSay():New(000,030,{|| _cDscEstFis },_oWndParamMapa,,_oFnt02,.F.,.F.,.F.,.T.)

	// -- SAIR
	_oBmpParamSair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _lRet := .F., _oWndParamMapa:End() },_oPnlParamCab,"Sair",,.T.)
	_oBmpParamSair:Align := CONTROL_ALIGN_RIGHT

	// Sub - titulo
	_oSayTitulo := TSay():New(025,005,{||"Parâmetros / Mapa - Arm: " + _cArmzServ},_oWndParamMapa,,_oFnt02,.F.,.F.,.F.,.T.)

	// tipo de endereçamento Igual PORTA PALLET / PICKING
	If ( "000002" $ mvEstFisDes) .Or. ( "000010" $ mvEstFisDes)

		_aDetArmz := U_SqlToVet("SELECT MIN(SUBSTRING(BE_LOCALIZ,1,2)) RUA_INI, "+;
		"MAX(SUBSTRING(BE_LOCALIZ,1,2)) RUA_FIM, "+;
		"MIN(SUBSTRING(BE_LOCALIZ,4,2)) PRE_INI, "+;
		"MAX(SUBSTRING(BE_LOCALIZ,4,2)) PRE_FIM, "+;
		"MIN(SUBSTRING(BE_LOCALIZ,6,2)) AND_INI, "+;
		"MAX(SUBSTRING(BE_LOCALIZ,6,2)) AND_FIM  "+;
		"FROM "+RetSqlTab("SBE")+" (nolock)  WHERE "+RetSqlCond("SBE")+" AND BE_LOCAL = '"+_cArmzServ+"' AND BE_ZCODCLI = '"+_cCodCliFor+"' AND BE_ESTFIS IN ('000002','000010')")
		mvRuaDe  := _aDetArmz[1][1]
		mvRuaAte := _aDetArmz[1][2]
		_aLados  := {" ","A","B"}
		mvLado   := Space(1)
		mvPreDe  := _aDetArmz[1][3]
		mvPreAte := _aDetArmz[1][4]
		mvAndDe  := _aDetArmz[1][5]
		mvAndAte := _aDetArmz[1][6]

		// PARAMETROS - INI
		// -- RUA DE->ATE
		_oSayRuaDe  := TSay():New(040,005,{||"Rua De:"},_oWndParamMapa,,,.F.,.F.,.F.,.T.)
		_oGetRuaDe  := TGet():New(038,036,{|u| If(PCount()>0,mvRuaDe :=u,mvRuaDe )},_oWndParamMapa,020,010,"@R 99",{|| Nil },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","mvRuaDe",,)
		_oSayRuaAte := TSay():New(040,060,{||"Rua Até:"},_oWndParamMapa,,,.F.,.F.,.F.,.T.)
		_oGetRuaAte := TGet():New(038,090,{|u| If(PCount()>0,mvRuaAte:=u,mvRuaAte)},_oWndParamMapa,020,010,"@R 99",{|| Nil },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","mvRuaAte",,)

		// -- LADO
		_oSayLado  := TSay():New(055,005,{||"Lado:"},_oWndParamMapa,,,.F.,.F.,.F.,.T.)
		_oCbLado   := TComboBox():New(053,036,{|u| If(PCount()>0,mvLado:=u,mvLado)},_aLados,020,010,_oWndParamMapa,,,,,,.T.,,"",,,,,,,mvLado)

		// -- PREDIO DE->ATE
		_oSayPreDe  := TSay():New(070,005,{||"Prédio De:"},_oWndParamMapa,,,.F.,.F.,.F.,.T.)
		_oGetPreDe  := TGet():New(068,036,{|u| If(PCount()>0,mvPreDe :=u,mvPreDe )},_oWndParamMapa,020,010,"@R",{|| Nil },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","mvPreDe",,)
		_oSayPreAte := TSay():New(070,060,{||"Prédio Até:"},_oWndParamMapa,,,.F.,.F.,.F.,.T.)
		_oGetPreAte := TGet():New(068,090,{|u| If(PCount()>0,mvPreAte:=u,mvPreAte)},_oWndParamMapa,020,010,"@R",{|| Nil },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","mvPreAte",,)

		// -- ANDAR DE->ATE
		_oSayAndDe  := TSay():New(085,005,{||"Andar De:"},_oWndParamMapa,,,.F.,.F.,.F.,.T.)
		_oGetAndDe  := TGet():New(083,036,{|u| If(PCount()>0,mvAndDe :=u,mvAndDe )},_oWndParamMapa,020,010,"@R 99",{|| Nil },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","mvAndDe",,)
		_oSayAndAte := TSay():New(085,060,{||"Andar Até:"},_oWndParamMapa,,,.F.,.F.,.F.,.T.)
		_oGetAndAte := TGet():New(083,090,{|u| If(PCount()>0,mvAndAte:=u,mvAndAte)},_oWndParamMapa,020,010,"@R 99",{|| Nil },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","mvAndAte",,)

		// -- ABASTE PALETE FRACIONADO (logistica reversa)
		If (mvLogRev)
			_oCbPltFra := TCheckBox():New(100,005,"Prioriza Abastecer Palete Fracionado", {|u| If(PCount()>0,mvComPltFra:=u,mvComPltFra)},_oWndParamMapa,100,,,,,,,,,.T.,,,)
		EndIf

		// ativa a tela
		_oWndParamMapa:Activate(,,,.F.,,,)

		If (_lRet)
			// atualiza os filtros
			mvFiltros := {}
			// RUA DE->ATE
			aAdd(mvFiltros,{mvRuaDe,mvRuaAte})
			// LADO
			aAdd(mvFiltros,{mvLado ,mvLado  })
			// PREDIO DE->ATE
			aAdd(mvFiltros,{mvPreDe,mvPreAte})
			// ANDAR DE->ATE
			aAdd(mvFiltros,{mvAndDe,mvAndAte})
			// Bloco
			aAdd(mvFiltros,{"",""})

			//gera log com os parametros utilizados para este produto
			U_FtGeraLog(cFilAnt, "Z08", xFilial("Z08") + Z06->Z06_NUMOS, "Tentativa de geração de mapa de armazenagem (PP): " ;
			+ " Produto: " + mvCodProd ;
			+ " Ruas de/ate: " + mvRuaDe + "/" + mvRuaAte ;
			+ " Lado: " + mvLado;
			+ " Predios de/ate: " + mvPreDe + "/" + mvPreAte ;
			+ " Andar de/ate: " + mvAndDe + "/" + mvAndAte ;
			,"", "WMS")
		EndIf

		//Tipo de endereçamento Igual BLOCADO
	ElseIf ( "000007" $ mvEstFisDes)

		// -- BLOCO
		_oSayBloco  := TSay():New(070,005,{||"Bloco:"},_oWndParamMapa,,,.F.,.F.,.F.,.T.)
		_oGetBloco  := TGet():New(068,036,{|u| If(PCount()>0,mvBloco :=u,mvBloco )},_oWndParamMapa,080,010,"@!",{|| sfVldEndBloco(mvBloco) },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","mvBloco",,)

		// ativa a tela
		_oWndParamMapa:Activate(,,,.F.,,,)

		If (_lRet)
			// atualiza os filtros
			mvFiltros := {}
			// RUA DE->ATE
			aAdd(mvFiltros,{"",""})
			// LADO
			aAdd(mvFiltros,{"" ,""  })
			// PREDIO DE->ATE
			aAdd(mvFiltros,{"",""})
			// ANDAR DE->ATE
			aAdd(mvFiltros,{"",""})
			// Bloco
			aAdd(mvFiltros,{mvBloco,""})

			//gera log com os parametros utilizados para este produto
			U_FtGeraLog(cFilAnt, "Z08", xFilial("Z08") + Z06->Z06_NUMOS, "Tentativa de geração de mapa de armazenagem (Bloco): " ;
			+ " Produto: " + mvCodProd ;
			+ " Bloco: " + mvBloco ;
			,"", "WMS")
		EndIf

	EndIf

Return(_lRet)

// ** funcao que consulta o lastro e camada de armazenagem
Static Function sfLastroCamada()
	// objetos
	local _oWndDetLasCam, _oPnlLasCamCab, _oBmpLasCamSair, _oBrwLasCamDet
	// posicao inicial das tabelas
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SZZ","Z04"})
	// seek
	local _cSeekZ04
	// lastro, camada e adicional
	local _nLastro := 0
	local _nCamada := 0
	local _nAdicio := 0
	// total por palete
	local _nTotPlt := 0
	// quant palete cheio
	local _nQtdPltChe := 0
	// quant palete fracionado
	local _nQtdPltFra := 0

	// browse com os detalhes do lastro e camada
	local _aColsLasCam := {}
	local _aHeadLasCam := {}

	//Quantidade de Pelates.
	local _aRetPal := {}

	// define o header do browse
	aAdd(_aHeadLasCam,{"Titulo"   ,"IT_TITULO", "",  11,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadLasCam,{"Descrição","IT_DESCRI", "", 100,0,Nil,Nil,"C",Nil,"R" })

	// posiciona no movimentacao de entrada/saida do veiculo
	dbSelectArea("SZZ")
	SZZ->(dbSetOrder(1)) // 1-ZZ_FILIAL, ZZ_CESV
	SZZ->(dbSeek( xFilial("SZZ")+_cNumCESV ))

	// posiciona nos itens da nota desta OS
	dbSelectArea("Z04")
	Z04->(dbSetOrder(1)) // 1-Z04_FILIAL, Z04_CESV
	Z04->(dbSeek( _cSeekZ04 := xFilial("Z04")+_cNumCESV ))

	// varre todos os itens
	While Z04->(!Eof()) .And. (Z04->(Z04_FILIAL+Z04_CESV) == _cSeekZ04)

		// valida produto ou kit
		If (Z04->Z04_PRDPAI <> "S")
			// proximo item
			Z04->(dbSkip())
			Loop
		EndIf

		// zera variaveis
		_nQtdPltChe := 0
		_nQtdPltFra := 0
		_nLastro := 0
		_nCamada := 0
		_nAdicio := 0

		// pesquisa o lastro e camada do produto
		// estrutura do retorno
		// 1-Quantidade Total de Palete
		// 2-Quantidade de Paletes Cheios
		// 3-Quantidade de Paletes Fracionados
		// 4-Quantidade Maxima de SKU/Volumes por Palete
		// 5-Tipo do Calculo (Q-Quant Unitarios / P-Quant Palete Informado)
		_aRetPal := U_FtWmsNorma(Z04->Z04_PROD, Z04->Z04_LOCAL, @_nLastro, @_nCamada, @_nAdicio, _cNumCESV, Z04->Z04_NUMSEQ, Z04->Z04_SEQKIT, Z04->Z04_QUANT, Z04->Z04_QTDPAL)

		// atualiza variavel de controle de acordo com o calculo da funcao FtWmsNorma
		_nTotPlt    := _aRetPal[1]
		_nQtdPltChe := _aRetPal[2]
		_nQtdPltFra := _aRetPal[3]

		// inclui os detalhes do item da nota
		aAdd(_aColsLasCam,{"Item NF"     ,Z04->Z04_ITEMNF,.F.})
		aAdd(_aColsLasCam,{"Produto"     ,AllTrim(Z04->Z04_PROD)+"-"+AllTrim(Posicione("SB1",1,xFilial("SB1")+Z04->Z04_PROD,"B1_DESC")),.F.})
		If (_nLastro > 0) .And. (_nCamada > 0)
			aAdd(_aColsLasCam,{"Last x Cam"  ,AllTrim(Str(_nLastro))+" X "+AllTrim(Str(_nCamada)),.F.})
			aAdd(_aColsLasCam,{"Adicional"   ,AllTrim(Str(_nAdicio)),.F.})
		EndIf
		aAdd(_aColsLasCam,{"Qtd por PLT" ,AllTrim(Str(_nTotPlt)),.F.})
		aAdd(_aColsLasCam,{"Total PLT"   ,"Cheio "+AllTrim(Str(_nQtdPltChe))+If(_nQtdPltFra==0,""," / Fracionado: "+AllTrim(Str(_nQtdPltFra))),.F.})
		aAdd(_aColsLasCam,{"===========" ,"",.F.})

		// proximo item
		Z04->(dbSkip())
	EndDo

	// monta o dialogo
	_oWndDetLasCam := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Lastro e Camada",,,.F.,,,,,,.T.,,,.T. )

	// -- painel com as opcoes disponiveis
	_oPnlLasCamCab := TPanel():New(000,000,nil,_oWndDetLasCam,,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlLasCamCab:Align:= CONTROL_ALIGN_TOP

	// -- botao Sair
	_oBmpLasCamSair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _oWndDetLasCam:End() },_oPnlLasCamCab,"Sair",,.T.)
	_oBmpLasCamSair:Align := CONTROL_ALIGN_RIGHT

	// browse com a listagem dos servicos
	_oBrwLasCamDet := MsNewGetDados():New(000,000,600,600,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsLasCam),'AllwaysTrue()','','AllwaysTrue()',_oWndDetLasCam,_aHeadLasCam,_aColsLasCam)
	_oBrwLasCamDet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwLasCamDet:oBrowse:oFont := _oFnt02

	// ativa a tela
	ACTIVATE MSDIALOG _oWndDetLasCam

	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aArea)

Return(.T.)

// ** funcao que consulta os enderecos reservador
Static Function sfEndReserv()
	// objetos
	local _oWndEndReserv
	local _oPnlEndResCab
	local _oBmpEndResSair, _oBmpEndResEst
	local _oBrwEndReserv
	// posicao inicial das tabelas
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z08"})

	// browse com os detalhes do lastro e camada
	local _aColsEndRes := {}
	local _aHeadEndRes := {}

	// query dos enderecos
	local _cQryZ08

	// permite estornar mapa
	local _lEstMapa := .T.

	// define o header do browse
	aAdd(_aHeadEndRes,{"Sts"        ,"IT_STATUS" , ""                   , 3                      ,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadEndRes,{"End.Destino","IT_ENDDEST", "@R 99.A.99.99.99999", TamSx3("BE_LOCALIZ")[1],0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadEndRes,{"End.Atual"  ,"IT_ENDATUA", "@R 99.A.99.99.99999", TamSx3("BE_LOCALIZ")[1],0,Nil,Nil,"C",Nil,"R" })

	// monta a query para buscar os enderecos reservados
	_cQryZ08 := "SELECT "
	// status
	_cQryZ08 += "CASE "
	_cQryZ08 += "  WHEN (Z08_ENDDES  = Z16_ENDATU) OR (Z08_STATUS = 'R') THEN 'ARM' "
	_cQryZ08 += "  WHEN (Z08_ENDDES != Z16_ENDATU) OR (Z08_STATUS = 'M') THEN 'MOV' "
	_cQryZ08 += "  WHEN Z16_ENDATU IS NULL THEN 'RES' "
	_cQryZ08 += "END IT_STATUS, "
	// enderecos
	_cQryZ08 += "Z08_ENDDES, ISNULL(Z16_ENDATU,'') Z16_ENDATU, '.F.' IT_DEL "

	// end. reservados
	_cQryZ08 += "FROM "+RetSqlName("Z08")+" Z08 (nolock)  "

	// composicao do palete
	_cQryZ08 += "LEFT JOIN "+RetSqlName("Z16")+" Z16 (nolock)  ON "+RetSqlCond("Z16")+" AND Z16_ETQPAL = Z08_PALLET "

	// filtro padrao
	_cQryZ08 += "WHERE "+RetSqlCond("Z08")
	// filtro pelo nr da OS
	_cQryZ08 += "AND Z08_NUMOS = '"+_cNumOrdSrv+"' "
	// agrupa itens
	_cQryZ08 += "GROUP BY Z08_ENDDES, Z16_ENDATU, Z08_STATUS "
	// ordem dos dados
	_cQryZ08 += "ORDER BY SUBSTRING(Z08_ENDDES,1,5), SUBSTRING(Z08_ENDDES,8,5) "

	// atualiza o aCols com os dados da query
	_aColsEndRes := U_SqlToVet(_cQryZ08)

	If (Len(_aColsEndRes) == 0) .AND. ( (_lUsrSuper) .OR. ( _lUsrLider ) .OR. (_lUsrGeren) ) .AND. !(_lPreConf)
		// mensagem de confirmacao
		If ( U_FtYesNoMsg("Deseja gerar Mapa de Armazenagem?") )
			MsgRun("Aguarde. Gerando mapa...",,{|| U_sfGeraMapa(.F.) })
			Return(.T.)
		EndIf
	EndIf

	// valida se permite o estorno do mapa
	aEval(_aColsEndRes,{|x| _lEstMapa := IIf(_lEstMapa, x[1] == "RES", .F.) })

	// monta o dialogo
	_oWndEndReserv := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"End. Reservados",,,.F.,,,,,,.T.,,,.T. )

	// -- painel com as opcoes disponiveis
	_oPnlEndResCab := TPanel():New(000,000,nil,_oWndEndReserv,,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlEndResCab:Align:= CONTROL_ALIGN_TOP

	// -- botao estornar mapa
	If ( (_lUsrGeren) .Or. (_lUsrAccou) .Or. (_lUsrSuper) .Or. ( _lUsrLider ) ) .And. (_lEstMapa)
		_oBmpEndResEst := TBtnBmp2():New(000,000,040,040,"ESTOMOVI",,,,{|| IIf(sfEstMapa(), _oWndEndReserv:End(), Nil) },_oPnlEndResCab,"Estornar Mapa",,.T.)
		_oBmpEndResEst:Align := CONTROL_ALIGN_LEFT
	EndIf

	// -- botao Sair
	_oBmpEndResSair := TBtnBmp2():New(000,000,040,040,"FINAL",,,,{|| _oWndEndReserv:End() },_oPnlEndResCab,"Sair",,.T.)
	_oBmpEndResSair:Align := CONTROL_ALIGN_RIGHT

	// browse com a listagem dos servicos
	_oBrwEndReserv := MsNewGetDados():New(000,000,600,600,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsEndRes),'AllwaysTrue()','','AllwaysTrue()',_oWndEndReserv,_aHeadEndRes,_aColsEndRes)
	_oBrwEndReserv:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwEndReserv:oBrowse:oFont := _oFnt02

	// ativa a tela
	ACTIVATE MSDIALOG _oWndEndReserv

	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aArea)

Return(.T.)

// ** funcao que retorna o status do ultimo palete iniciado
Static Function sfRetStsPlt()
	local _cRet := ""
	local _cQryZ07

	// monta query para buscar algum palete que nao foi finalizado
	_cQryZ07 := "SELECT DISTINCT Z07_CONTEU "
	// itens de conferencia
	_cQryZ07 += "FROM "+RetSqlName("Z07")+" (nolock)  "
	// filtro padrao
	_cQryZ07 += "WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
	// filtro por OS
	_cQryZ07 += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	// codigo e loja do cliente
	_cQryZ07 += "AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
	// nr de contagens
	_cQryZ07 += "AND Z07_NRCONT = '"+_cNrContagem+"' "
	// ID do palete
	If (_lIdPltAuto)
		_cQryZ07 += "AND Z07_PALLET = '"+IIf(Empty(_cIdPalete), _cIdPltAuto, _cIdPalete)+"' "
	ElseIf ( ! _lIdPltAuto)
		_cQryZ07 += "AND Z07_PALLET = '"+_cIdPalete+"' "
	EndIf
	// controle de volume/kit
	If (_lCtrVolume)
		_cQryZ07 += "AND Z07_ETQVOL  = '"+_cEtqVolume+"' "
	EndIf
	// status - somente que nao C-EM CONFERENCIA
	_cQryZ07 += "AND Z07_STATUS = 'C' "

	// executa a query
	_cRet := U_FtQuery(_cQryZ07)

	// se nao tem palete, define como VAZIO
	If (Empty(_cRet))
		_cRet := "V"
	EndIf

Return(_cRet)

// ** funcao para estorno do palete
Static Function sfEstorno(mvIdPlt, mvIdVol, mvCodProd, mvLote)
	// query
	local _cQryZ07
	// variaveis temporarias
	local _aTmpRecno := {}
	local _nX
	// variavel de retorno
	local _lRet := .F.
	// opção escolhida
	local _cOpcEst := ""

	// update etiquetas do cliente
	local _cUpdZ56

	// valores padroes
	Default mvIdPlt   := CriaVar("Z11_CODETI", .T.)
	Default mvIdVol   := CriaVar("Z11_CODETI", .T.)
	Default mvCodProd := Space(_nTamCodPrd)
	Default mvLote    := CriaVar("Z07_LOTCTL", .T.)

	// valida id do palete
	If (Empty(mvIdPlt)) .And. (Empty(mvLote))
		// mensagem
		U_FtWmsMsg("Não há palete para estorno!","ATENCAO")
		// retorno
		Return(_lRet)
	EndIf

	If ( ! Empty(mvIdPlt) )

		// chama a tela de opções para estorno
		_cOpcEst := sfRetOpcEst(mvIdPlt, mvIdVol, mvCodProd)

		// caso tenha cancelado o estorno
		If (Empty(_cOpcEst))
			// retorno
			Return(_lRet)
		EndIf

	Else
		If !( U_FtYesNoMsg("Estorna Linha(s) do Lote Selecionado?") )
			Return(.F.)
		EndIf
	EndIf

	// monta SQL para estornar o palete
	_cQryZ07 := " SELECT Z07.R_E_C_N_O_ Z07RECNO, ISNULL(Z16.R_E_C_N_O_,0) Z16RECNO "
	// itens em conferencia
	_cQryZ07 += " FROM " + RetSqlTab("Z07") + " (NOLOCK) "
	// composicao do palete
	_cQryZ07 += " LEFT JOIN " + RetSqlTab("Z16") + " (NOLOCK)  ON "+RetSqlCond("Z16")+" AND Z16_ETQPAL = Z07_PALLET "
	_cQryZ07 += "      AND Z16_ETQVOL = Z07_ETQVOL AND Z16_ETQPRD = Z07_ETQPRD AND Z16_CODBAR = Z07_CODBAR "
	_cQryZ07 += "      AND Z16_CODPRO = Z07_PRODUT AND Z16_ENDATU = Z07_ENDATU "
	// filtro padrao
	_cQryZ07 += " WHERE " + RetSqlCond("Z07")+" "
	// filtro por OS
	_cQryZ07 += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	// cliente e loja
	_cQryZ07 += " AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
	// nr contagem
	_cQryZ07 += " AND Z07_NRCONT = '"+_cNrContagem+"' "

	If (Empty(mvLote))

		// palete
		_cQryZ07 += " AND Z07_PALLET = '"+mvIdPlt+"' "

		// validação do estorno do volume
		If (_cOpcEst == "VOL" ) .Or. (_cOpcEst == "LIN" )
			_cQryZ07 += " AND Z07_ETQVOL = '"+mvIdVol+"' "
		EndIf

		// validação do estorno do produto
		If (_cOpcEst == "LIN" )
			_cQryZ07 += " AND Z07_PRODUT = '"+mvCodProd+"' "
		EndIf

	Else

		// Lote
		_cQryZ07 += " AND Z07_LOTCTL = '"+mvLote+"' "

	EndIf

	// status
	_cQryZ07 += " AND Z07_STATUS IN ('C','D') "

	// filtra somente quando for operador
	If (( ! _lUsrGeren ) .And. ( ! _lUsrAccou ) .And. ( ! _lUsrSuper ) .And. ( !_lUsrLider ) )
		_cQryZ07 += " AND Z07_USUARI = '"+_cCodOper+"' "
	EndIf

	// somente quanto estiver na doca
	_cQryZ07 += " AND Z07_ENDATU = '"+_cDocaSrv+"' "

	MemoWrit("C:\query\twmsa010_sfEstorno.txt",_cQryZ07)
	// alimenta o vetor
	_aTmpRecno := U_SqlToVet(_cQryZ07)

	// valida quantidade de registros
	If (Len(_aTmpRecno) == 0)
		// mensagem
		U_FtWmsMsg("Não há dados para estornar!","ATENCAO")
		// retorno
		Return(_lRet)
	EndIf

	// inicio de transacao
	BEGIN TRANSACTION

		// varre todos os recno
		For _nX := 1 to Len(_aTmpRecno)

			// posiciona no registro real - conferencia
			dbSelectArea("Z07")
			Z07->(dbGoTo( _aTmpRecno[_nX][1] ))

			// exclui o registro
			RecLock("Z07")
			Z07->(dbDelete())
			Z07->(MsUnLock())

			// posiciona no registro real - estrutura do palete
			If (_aTmpRecno[_nX][2] > 0)
				dbSelectArea("Z16")
				Z16->(dbGoTo( _aTmpRecno[_nX][2] ))

				// exclui o registro
				RecLock("Z16")
				Z16->(dbDelete())
				Z16->(MsUnLock())
			EndIf

			// atualiza variavel de retorno
			_lRet := .T.

		Next _nX

		// limpa/estorna etiquetas na tabela z56 (etiquetas de cliente) se for Sumitomo e processo de integração com GWS ativo para o produto
		If  ( _cCodCliFor == "000316") .And. (lSumibar) .AND. ( Posicione("SB1",1,xFilial("SB1") + AllTrim(mvCodProd),"B1_ZNUMSER") == "S" )
			_cUpdZ56 := " UPDATE " + RetSQLName("Z56") 
			_cUpdZ56 += " SET Z56_CODETI = '', Z56_OK_ENT = 'N' "
			_cUpdZ56 += " WHERE D_E_L_E_T_ = '' "
			_cUpdZ56 += " AND Z56_FILIAL = '"+xFilial("Z56")+"' "
			_cUpdZ56 += " AND Z56_CODCLI = '"+_cCodCliFor+"' "
			_cUpdZ56 += " AND Z56_LOJCLI = '"+_cLojCliFor+"' "
			// verifica na Z16 com base no palete gerado SE o operador clicou em NOVO PALETE, 
			// pois nesse momento há um número de palete (mvIdPlt)
			_cUpdZ56 += " AND Z56_CODETI = Isnull((SELECT DISTINCT Z16_ETQPRD " 
			_cUpdZ56 += "						   FROM " + RetSQLName("Z16") + " (NOLOCK) "
			_cUpdZ56 += "						   WHERE Z16_FILIAL = '" + xFilial("Z56")   + "' "
			_cUpdZ56 += "						   		 AND Z16_ETQPAL = '"   + AllTrim(mvIdPlt) + "' "
			_cUpdZ56 += "						   		 AND Z16_ETQPRD != '' AND Z16_CODPRO = '" + AllTrim(mvCodProd) + "'), "
			// Se o operador não clicou em NOVO PALETE e estornou pelo botão "Estono de palete atual", 
			// verifica na Z07, pois ainda não tem núemro de palete
			_cUpdZ56 += "                         (SELECT TOP 1 Z07_ETQPRD "
			_cUpdZ56 += "						   FROM " + RetSQLName("Z07") + " (NOLOCK) "
			_cUpdZ56 += "                          WHERE  Z07_FILIAL = '" + xFilial("Z07") + "' "
			// pego somente o que já foi deletado no FOR acima
			_cUpdZ56 += "                                 AND D_E_L_E_T_ = '*' "
			_cUpdZ56 += "                                 AND Z07_PALLET = '"   + AllTrim(mvIdPlt) + "' "
			_cUpdZ56 += "                                 AND Z07_ETQPRD != '' "
			_cUpdZ56 += "                                 AND Z07_PRODUT = '" + AllTrim(mvCodProd) + "' "
			// utilizo order by desc em conjunto com o TOP 1, pois pode haver mais de um estorno, 
			// pois o palete temporário utiliza a regra "AUT_CODIGO OPERADOR como regra de nomenclatura"
			_cUpdZ56 += "                          ORDER  BY R_E_C_N_O_ DESC)) " 

			MemoWrit("C:\query\twmsa010_sfEstorno_updZ56.txt",_cUpdZ56)

			If (TCSQLExec(_cUpdZ56) < 0)
				DisarmTransaction()
				U_FtWmsMsg("Não foi possível estornar etiquetas do cliente!" ,"Erro TWMSA010 - SfEstorno")
			EndIf
		EndIf

		// fim de transacao
	END TRANSACTION

	// atualiza os dados
	If (_lRet)
		sfSelDados()
	EndIf

	If (_lRet)
		U_FtWmsMsg("Estorno realizado com sucesso!","ATENCAO")
	Else
		U_FtWmsMsg("Estorno não permitido! Pallet já armazenado.","ATENCAO")
	EndIf

Return(_lRet)

// ** funcao para validacao do codigo do ID de volume
Static Function sfVldVolume(mvGetEtqVolume)
	Local _cQuery := ""
	// controle de retorno
	local _lRet := .T.

	// RECNO do Z07
	local _nRecnoZ07 := 0

	// update do status do conteudo do palete
	local _cQryZ07

	// valida conteudo da etiqueta
	If (Empty(_cEtqVolume))
		// mensagem
		U_FtWmsMsg("É necessário informar a etiqueta do volume!","ATENCAO")
		// varivel de controle
		_lRet := .F.
	EndIf

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11")+_cEtqVolume ))
			// mensagem
			U_FtWmsMsg("Identificador de volume inválido!","ATENCAO")
			// retorno
			_lRet := .F.
		EndIf
	EndIf

	// valida o tipo da etiqueta lida
	If (_lRet)
		If (Z11->Z11_TIPO != "04")
			// mensagem
			U_FtWmsMsg("Tipo de etiqueta de volume inválida!","ATENCAO")
			// retorno
			_lRet := .F.
		EndIf
	EndIf

	// valida se a etiqueta de volume já foi utilizada (z07)
	If (_lRet)
		_cQuery := " SELECT ISNULL(SUM(Z07_QUANT),0) QTD "
		_cQuery += " FROM " + RetSqlTab("Z07") + " (NOLOCK) "
		_cQuery += " WHERE " + RetSqlCond("Z07")
		_cQuery += " AND Z07_ETQVOL  = '" + _cEtqVolume + "' "

		If (U_FtQuery(_cQuery) > 0)
			// mensagem
			U_FtWmsMsg("Etiqueta de volume já foi utilizada (Z07)!" + CRLF + CRLF + "Utilize uma etiqueta de volume nova/sem vínculo.","TWMSA010 - sfVldVolume Z16")
			// variavel de controle
			_lRet := .F.
		EndIf
	EndIf

	// valida se a etiqueta de volume já foi utilizada (z16)
	If (_lRet)	
		_cQuery := " SELECT COUNT(*) QTD "
		_cQuery += " FROM " + RetSqlTab("Z16") + " (NOLOCK) "
		_cQuery += " WHERE " + RetSqlCond("Z16")
		_cQuery += " AND Z16_ETQVOL = '" + _cEtqVolume + "' "

		If (U_FtQuery(_cQuery) > 0)
			// mensagem
			U_FtWmsMsg("Etiqueta de volume já foi utilizada (Z16)!" + CRLF + CRLF + "Utilize uma etiqueta de volume nova/sem vínculo.","TWMSA010 - sfVldVolume Z16")
			// variavel de controle
			_lRet := .F.
		EndIf

	EndIf

	If ( ! _lRet)
		// reinicia variaveis
		_cEtqVolume := Space(Len(_cEtqVolume))
		// foco na etiqueta de volume
		_oGetEtqVolume:SetFocus()
	EndIf

	// atualiza objetos da tela
	If (_lRet)
		// atualiza a quantidade de leitura
		RecLock("Z11")
		Z11->Z11_QTDLEI += 1
		Z11->(MsUnLock())
		// atualiza variaveis de controle
		_lNovoVolume := .F.
		// atualiza objetos
		mvGetEtqVolume:lReadOnly := (!_lNovoVolume)
		// foco no objeto ID do produto
		_oGetCodProd:SetFocus()
	EndIf

Return(_lRet)

// ** funcao que consulta os kit disponiveis para a OS
Static Function sfEstrutKit()
	// objetos
	local _oWndDetKit, _oPnlKitCab, _oBmpKitSair, _oBrwKitDet
	// posicao inicial das tabelas
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SZZ","Z04","Z29","SB1"})
	// seek
	local _cSeekZ04
	local _cSeekZ29
	// lastro, camada e adicional
	local _nLastro := 0
	local _nCamada := 0
	local _nAdicio := 0
	// total por palete
	local _nTotPlt := 0
	// quant palete cheio
	local _nQtdPltChe := 0
	// quant palete fracionado
	local _nQtdPltFra := 0

	//Quantidade de Pelates.
	local _aRetPal := {}

	// browse com os detalhes do lastro e camada
	local _aColsKit := {}
	local _aHeadKit := {}

	// controle de Kit
	local _cSeqKit := ""

	// define o header do browse
	aAdd(_aHeadKit,{"Titulo"   ,"IT_TITULO", "",  11,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadKit,{"Descrição","IT_DESCRI", "", 100,0,Nil,Nil,"C",Nil,"R" })

	// posiciona no movimentacao de entrada/saida do veiculo
	dbSelectArea("SZZ")
	SZZ->(dbSetOrder(1)) // 1-ZZ_FILIAL, ZZ_CESV
	SZZ->(dbSeek( xFilial("SZZ")+_cNumCESV ))

	// posiciona nos itens da nota desta OS
	dbSelectArea("Z04")
	Z04->(dbSetOrder(1)) // 1-Z04_FILIAL, Z04_CESV
	Z04->(dbSeek( _cSeekZ04 := xFilial("Z04")+_cNumCESV ))

	// varre todos os itens
	While Z04->(!Eof()) .And. (Z04->(Z04_FILIAL+Z04_CESV) == _cSeekZ04)

		// valida produto ou kit
		If (Empty(Z04->Z04_SEQKIT)) .Or. (Z04->Z04_PRDPAI == "N")
			// proximo item
			Z04->(dbSkip())
			Loop
		EndIf

		// zera variaveis
		If (_cSeqKit != Z04->Z04_SEQKIT)

			// zera variaveis
			_nQtdPltChe := 0
			_nQtdPltFra := 0

			// produto pai
			If (Z04->Z04_PRDPAI == "S")

				// estrutura do retorno
				// 1-Quantidade Total de Palete
				// 2-Quantidade de Paletes Cheios
				// 3-Quantidade de Paletes Fracionados
				// 4-Quantidade Maxima de SKU/Volumes por Palete
				// 5-Tipo do Calculo (Q-Quant Unitarios / P-Quant Palete Informado)
				_aRetPal := U_FtWmsNorma(Z04->Z04_PROD, Z04->Z04_LOCAL, @_nLastro, @_nCamada, @_nAdicio, _cNumCESV, Z04->Z04_NUMSEQ, Z04->Z04_SEQKIT, Z04->Z04_QUANT, Z04->Z04_QTDPAL)

				// atualiza variavel de controle de acordo com o calculo da funcao FtWmsNorma
				_nTotPlt    := _aRetPal[1]
				_nQtdPltChe := _aRetPal[2]
				_nQtdPltFra := _aRetPal[3]

				// adiciona os detalhes do kit
				aAdd(_aColsKit,{"Kit"            ,AllTrim(Z04->Z04_PROD)+"-"+AllTrim(Posicione("Z29",1,xFilial("Z29")+Z04->Z04_PROD,"Z29_DSCKIT")),.F.})
				If (_nLastro > 0) .And. (_nCamada > 0)
					aAdd(_aColsKit,{"Last x Cam"     ,AllTrim(Str(_nLastro))+" X "+AllTrim(Str(_nCamada)),.F.})
					aAdd(_aColsKit,{"Adicional"      ,AllTrim(Str(_nAdicio)),.F.})
				EndIf
				aAdd(_aColsKit,{"Qtd por PLT"    ,AllTrim(Str(_nTotPlt)),.F.})
				aAdd(_aColsKit,{"Total PLT"      ,"Cheio "+AllTrim(Str(_nQtdPltChe))+If(_nQtdPltFra==0,""," / Fracionado: "+AllTrim(Str(_nQtdPltFra))),.F.})
				aAdd(_aColsKit,{""               ,"== Componentes",.F.})

				// componentes do Kit
				dbSelectArea("Z29")
				Z29->(dbSetOrder(1)) // 1- Z29_FILIAL, Z29_CODKIT, Z29_PRODUT
				Z29->(dbSeek( _cSeekZ29 := xFilial("Z29")+Z04->Z04_PROD ))
				// varre todos os itens do Kit
				While Z29->(!Eof()) .And. (Z29->(Z29_FILIAL+Z29_CODKIT) == _cSeekZ29)
					// inclui o detalhe
					aAdd(_aColsKit,{"|..Produto","Qtd: "+AllTrim(Str(Z29->Z29_QUANT))+" - "+AllTrim(Posicione("SB1",1,xFilial("SB1")+Z29->Z29_PRODUT,"B1_DESC"))+" (Cód: "+AllTrim(Z29->Z29_PRODUT)+")",.F.})
					// proximo item
					Z29->(dbSkip())
				EndDo

			EndIf

			// sequencia de kit
			//Felipe Limas
			/*_cSeqKit != Z04->Z04_SEQKIT*/
			_cSeqKit := Z04->Z04_SEQKIT

		EndIf

		// proximo item
		Z04->(dbSkip())
	EndDo

	// monta o dialogo
	_oWndDetKit := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Detalhes de Agrupadora",,,.F.,,,,,,.T.,,,.T. )

	// -- painel com as opcoes disponiveis
	_oPnlKitCab := TPanel():New(000,000,nil,_oWndDetKit,,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlKitCab:Align:= CONTROL_ALIGN_TOP

	// -- botao Sair
	_oBmpKitSair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _oWndDetKit:End() },_oPnlKitCab,"Sair",,.T.)
	_oBmpKitSair:Align := CONTROL_ALIGN_RIGHT

	// browse com a listagem dos kit
	_oBrwKitDet := MsNewGetDados():New(000,000,600,600,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsKit),'AllwaysTrue()','','AllwaysTrue()',_oWndDetKit,_aHeadKit,_aColsKit)
	_oBrwKitDet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwKitDet:oBrowse:oFont := _oFnt02

	// ativa a tela
	ACTIVATE MSDIALOG _oWndDetKit

	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aArea)

Return(.T.)

// ** funcao que retorna os kit disponiveis para conferencia
Static Function sfKitDispo()
	// variavel de retorno
	local _aRetKit := {}

	// posicao inicial das tabelas
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SZZ","Z04","Z29","SB1"})

	// seek
	local _cSeekZ04

	// controle de Kit
	local _cSeqKit := ""

	// posiciona no movimentacao de entrada/saida do veiculo
	dbSelectArea("SZZ")
	SZZ->(dbSetOrder(1)) // 1-ZZ_FILIAL, ZZ_CESV
	SZZ->(dbSeek( xFilial("SZZ")+_cNumCESV ))

	// posiciona nos itens da nota desta OS
	dbSelectArea("Z04")
	Z04->(dbSetOrder(1)) // 1-Z04_FILIAL, Z04_CESV
	Z04->(dbSeek( _cSeekZ04 := xFilial("Z04")+_cNumCESV ))

	// varre todos os itens
	While Z04->(!Eof()) .And. (Z04->(Z04_FILIAL+Z04_CESV) == _cSeekZ04)

		// valida produto ou kit
		If (Empty(Z04->Z04_SEQKIT)) .Or. (Z04->Z04_PRDPAI == "N")
			// proximo item
			Z04->(dbSkip())
			Loop
		EndIf

		// zera variaveis
		If (_cSeqKit != Z04->Z04_SEQKIT)

			// inclui um elemento em branco
			If (Len(_aRetKit) == 0)
				_aRetKit := {""}
			EndIf

			// adiciona a opcao de kit
			aAdd(_aRetKit,Z04->Z04_SEQKIT+"="+AllTrim(Posicione("Z29",1,xFilial("Z29")+Z04->Z04_PROD,"Z29_DSCKIT")) )

			// adiciona detalhes com o codigo do kit
			aAdd(_aKitDispon,{Z04->Z04_SEQKIT, Z04->Z04_PROD})

			// sequencia de kit
			_cSeqKit := Z04->Z04_SEQKIT

		EndIf

		// proximo item
		Z04->(dbSkip())
	EndDo

	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aArea)

Return(_aRetKit)

// ** funcao para gerar um novo volume no mesmo palete
Static Function sfNovoVolume(mvGeraNovo, mvAuto)

	Default mvAuto := .F.

	//se volume automatico
	If (_lAutoVol)
		mvAuto := .T.
	EndIf

	// mensagem de volume parcial
	If (mvGeraNovo) .And. (_cStatusVlm == "P") .And. ( ! mvAuto )
		U_FtWmsMsg("ATENÇÃO: Volume Parcial!","ATENCAO")
	EndIf

	If ( ! mvAuto )    //se não for rotina automatica
		If (mvGeraNovo) .And. ( ! U_FtYesNoMsg("Confirma novo Volume ?"))
			Return(.F.)
		EndIf
	EndIf

	// atualiza variaveis
	_cEtiqProd   := Space(Len(_cEtiqProd))
	_cEtqCodBar  := Space(Len(_cEtqCodBar))
	_cCodProd    := Space(_nTamCodPrd)
	_nQtdProd    := 1
	_nQtdSegUM   := 0
	_cStatusVlm  := "V"
	_cEtqVolume  := Space(Len(_cEtqVolume))
	_lNovoVolume := .T.
	_cNumSerie   := Space(Len(_cNumSerie))
	_dDtSeri     := CtoD("//")

	// atualiza os dados
	sfSelDados("AUTO")

	// atualiza o objeto para receber o foco
	_oGetNrPalete:lReadOnly := ( ! _lNovoPalete )
	// atualiza objeto para pemitir novas leituras
	_oGetEtqVolume:lReadOnly := ( ! _lCtrVolume ) .And. ( ! _lNovoVolume )
	// atualiza o conteudo do palete
	_oCmbContPlt:Refresh()

	// foco na etiqueta de volume
	If (_lCtrVolume)
		If (_lEtqIdEAN) .Or. (_lEtqCod128) .Or.  (_lEtqIdDUN) // ean 13 / code 128 / DUN14
			_oGetEtqVolume:SetFocus()
		ElseIf (_lEtqClient) // CLIENTE
			_oGetCodProd:SetFocus()
		EndIf
	EndIf

Return( .T. )

// ** funcao para selecionar os dados do kit/agrupadora para montagem
Static Function sfDadosAgrup()
	// componentes do kit
	local _aCompKit := {}
	local _nCompKit

	// total programado
	local _nTotProg := 0
	// total conferido
	local _nTotConf := 0

	// zera variavel
	_aItCompKit := {}

	// busca os componentes do kit
	// retorno (vetor)
	// 1-cod produto
	// 2-desc produto
	// 3-quantidade
	_aCompKit := sfCompKit(_cSeqKitSelec)

	// status atual por volume
	_cStatusVlm := "T"

	// atualiza varivel de retorno
	For _nCompKit := 1 to Len(_aCompKit)

		// inclui componente
		aAdd(_aItCompKit,{_aCompKit[_nCompKit][1], _aCompKit[_nCompKit][2], _aCompKit[_nCompKit][3], _aCompKit[_nCompKit][4], .F.})

		// total programado
		_nTotProg += _aCompKit[_nCompKit][2]
		// total conferido
		_nTotConf += _aCompKit[_nCompKit][1]

	Next _aCompKit

	// status do volume
	If (_nTotConf == 0)
		_cStatusVlm := "V"
	ElseIf ((_nTotConf > 0) .And. (_nTotConf < _nTotProg))
		_cStatusVlm := "P"
	ElseIf ((_nTotConf > 0) .And. (_nTotConf == _nTotProg))
		_cStatusVlm := "T"
	EndIf

	// atualiza browse
	If (_oBrwCompKit <> nil)
		_oBrwCompKit:aCols := aClone(_aItCompKit)
		_oBrwCompKit:Refresh()
	EndIf

Return

// ** funcao que retorna os componentes do kit selecionado
Static Function sfCompKit(mvSeqKit)
	// variavel de retorno
	local _aRetCompKit := {}
	// query que trará os dados
	local _cQryKit := ""

	// optei por fazer num único select para poder atualizar constantemente
	_cQryKit := " SELECT Sum(Isnull(Z07_QUANT, 0)) Z07_QUANT, "
	_cQryKit += "	       Z29_QUANT, "
	_cQryKit += "	       Z29_PRODUT, "
	_cQryKit += "	       B1_DESC "
	_cQryKit += "	FROM   (SELECT DISTINCT Z29_QUANT, "
	_cQryKit += "	                        Z29_PRODUT, "
	_cQryKit += "	                        B1_DESC, "
	_cQryKit += "	                        Z04_CESV, "
	_cQryKit += "	                        Z04_FILIAL "
	_cQryKit += "	        FROM   "+RetSqlName("Z04")+" Z04 (nolock)  "
	_cQryKit += "	               LEFT JOIN "+RetSqlName("Z29")+" Z29 (nolock)  "
	_cQryKit += "	                      ON Z29_CODKIT = Z04_CODKIT "
	_cQryKit += "	                         AND Z29.D_E_L_E_T_ = '' "
	_cQryKit += "	               LEFT JOIN "+RetSqlName("SB1")+" SB1 (nolock)  "
	_cQryKit += "	                      ON B1_COD = Z29_PRODUT "
	_cQryKit += "	                         AND SB1.D_E_L_E_T_ = '' "
	_cQryKit += "	        WHERE  Z04_CESV = '"+_cNumCESV+"' "
	_cQryKit += "	               AND "+RetSqlCond("Z04")
	_cQryKit += "	               AND Z04_SEQKIT = '"+mvSeqKit+"' "
	_cQryKit += "	               AND Z04_PRDPAI = 'S') KIT "
	_cQryKit += "	       LEFT JOIN "+RetSqlName("Z05")+" Z05 (nolock)   "
	_cQryKit += "	              ON Z05_CESV = Z04_CESV "
	_cQryKit += "	                 AND "+RetSqlCond("Z05")
	_cQryKit += "	       LEFT JOIN "+RetSqlName("Z07")+" Z07 (nolock)  "
	_cQryKit += "	              ON Z07_NUMOS = Z05_NUMOS "
	_cQryKit += "	                 AND "+RetSqlCond("Z07")
	_cQryKit += "	                 AND Z07_PRODUT = Z29_PRODUT "
	_cQryKit += "	                 AND Z07_NUMOS = '"+_cNumos+"' "
	If (_lIdPltAuto)
		_cQryKit += "	                 AND Z07_PALLET = '"+IIf(Empty(_cIdPalete), _cIdPltAuto, _cIdPalete)+"' "
	ElseIf ( ! _lIdPltAuto)
		_cQryKit += "	                 AND Z07_PALLET = '"+_cIdPalete+"' "
	EndIF
	_cQryKit += "	                 AND Z07_ETQVOL = '"+_cEtqVolume+"' "
	_cQryKit += "	GROUP  BY Z29_QUANT, "
	_cQryKit += "	          Z29_PRODUT, "
	_cQryKit += "	          B1_DESC "

	MemoWrit("C:\query\twmsa010_query_kit.txt",_cQryKit)

	// jogo os dados pro array
	_aRetCompKit := U_SqlToVet(_cQryKit)

Return(_aRetCompKit)

// ** função que retorna array que contem tipos de estoque
Static Function sfRetTpEstoque()

	// query para consulta
	local _cQuery := ""
	// array pra retorno
	local _aTpEstoque := {}

	// consulto os tipos de estoque disponíveis na tabela
	_cQuery := " SELECT Z34_CODIGO+'='+Z34_DESCRI TPESTOQUE from "+RetSqlName("Z34")+" Z34  (nolock)  WHERE "+RetSqlCond("Z34")+" ORDER BY Z34_CODIGO"

	// jogo os dados pro array
	_aTpEstoque := U_SqlToVet(_cQuery)

Return (_aTpEstoque)

// ** função para retornar o tipo de embalagem
Static Function sfRetTpEmbala(mvSeqKit)

	// query para consulta
	local _cQuery := ""
	// variavel pra retorno
	local _cTpEmbala := ""

	// faço a pesquisa pra me retornar a embalagem
	_cQuery := " SELECT DISTINCT Z29_EMBALA FROM "+RetSqlName("Z29")+" Z29 (nolock)  "
	_cQuery += "	WHERE Z29_CODKIT IN ( "
	_cQuery += "	SELECT Z04_CODKIT FROM "+RetSqlName("Z04")+" Z04 (nolock)  "
	_cQuery += "	WHERE Z04_SEQKIT = '"+mvSeqKit+"' "
	_cQuery += "	AND Z04_CESV = '"+_cNumCESV+"' "
	_cQuery += "	AND "+RetSqlCond("Z04")+" ) "
	_cQuery += "    AND "+RetSqlCond("Z29")

	MemoWrit("C:\query\sfRetTpEmbala_twmsa010.txt",_cQuery)

	// jogo o resultado pra variável
	_cTpEmbala := U_FtQuery(_cQuery)

Return (_cTpEmbala)

// ** rotina com opções para estorno
Static Function sfRetOpcEst(mvIdPlt, mvIdVol, mvCodProd)

	// objetos
	local _oWmsOpcEst, _oPnlOpcCab, _oPnlOpcMei, _oBmpConvSair, _oBmpPlt, _oBmpVol, _oBmpLinha
	// retorno
	local _cRetOpc := ""
	// controle de transação
	local _lRet := .F.
	// array do retorno de totais
	local _aTotais := sfRetTotalPorTipo(mvIdPlt, mvIdVol, mvCodProd)

	// monta o dialogo do monitor
	_oWmsOpcEst := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Opções de Estorno",,,.F.,,,,,,.T.,,,.T. )
	_oWmsOpcEst:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlOpcCab := TPanel():New(000,000,nil,_oWmsOpcEst,,.F.,.F.,,CLR_WHITE,20,20,.T.,.F.)
	_oPnlOpcCab:Align:= CONTROL_ALIGN_TOP

	// -- botao Sair
	_oBmpConvSair := TBtnBmp2():New(000,000,040,040,"FINAL",,,,{|| If(U_FtYesNoMsg("Cancelar Estorno?","ATENÇÃO"),_oWmsOpcEst:End(),Nil) },_oPnlOpcCab,"Sair",,.T. )
	_oBmpConvSair:Align := CONTROL_ALIGN_RIGHT

	// cria o panel do rodape
	_oPnlOpcMei := TPanel():New(000,000,nil,_oWmsOpcEst,,.F.,.F.,,CLR_WHITE,,,.T.,.F.)
	_oPnlOpcMei:Align:= CONTROL_ALIGN_ALLCLIENT

	// -- botao Pallet
	_oBmpPlt := TButton():New( 002, 010, "Estorna Pallet? " + CRLF + _aTotais[1],_oPnlOpcMei,{|| _cRetOpc := "PLT",_oWmsOpcEst:End()  }, 100,30,,,.F.,.T.,.F.,,.F.,,,.F. )
	_oBmpPlt:Align := CONTROL_ALIGN_CENTER
	// O CSS abaixo remove a cor degrade do fundo
	_oBmpPlt:SetCss(sfPadrCSS())

	// -- botao Volume
	_oBmpVol := TButton():New( 040, 010, "Estorna Volume? " + CRLF + _aTotais[2],_oPnlOpcMei,{|| _cRetOpc := "VOL",_oWmsOpcEst:End() },100,30,,,.F.,.T.,.F.,,.F.,,,.F. )
	_oBmpVol:Align := CONTROL_ALIGN_CENTER
	// O CSS abaixo remove a cor degrade do fundo
	_oBmpVol:SetCss(sfPadrCSS())

	// -- botao Linha
	_oBmpLinha := TButton():New( 078, 010, "Estorna Linha Selecionada? " + CRLF + _aTotais[3],_oPnlOpcMei,{|| _cRetOpc := "LIN",_oWmsOpcEst:End()  }, 100,30,,,.F.,.T.,.F.,,.F.,,,.F. )
	_oBmpLinha:Align := CONTROL_ALIGN_CENTER
	// O CSS abaixo remove a cor degrade do fundo
	_oBmpLinha:SetCss(sfPadrCSS())

	// ativa a tela
	_oWmsOpcEst:Activate(,,,.F.,{|| .T. },,)

Return (_cRetOpc)

// ** retorna quantidade de registros por tipo
Static Function sfRetTotalPorTipo(mvIdPlt, mvChvEtiq, mvCodProd)

	// variavel de retorno
	local _aTotal := {}
	// query pra consulta
	local _cQuery := ""

	// consulto os dados pra trazer o retorno
	_cQuery := " SELECT CAST(COUNT(*) AS VARCHAR)+' REGISTRO(S)' FROM " + RetSqlTab("Z07") + " (nolock) "
	_cQuery += "	WHERE "+RetSqlCond("Z07")
	_cQuery += "	AND Z07_PALLET = '"+mvIdPlt+"'
	_cQuery += "	AND Z07_NUMOS = '"+_cNumos+"'
	_cQuery += "	UNION ALL
	_cQuery += "	SELECT CAST(COUNT(*) AS VARCHAR)+' REGISTRO(S)' FROM " + RetSqlTab("Z07") + " (nolock) "
	_cQuery += "	WHERE "+RetSqlCond("Z07")
	_cQuery += "	AND Z07_PALLET = '"+mvIdPlt+"'
	_cQuery += "	AND Z07_ETQVOL = '"+mvChvEtiq+"'
	_cQuery += "	AND Z07_NUMOS = '"+_cNumos+"'
	_cQuery += "	UNION ALL
	_cQuery += "	SELECT CAST(COUNT(*) AS VARCHAR)+' REGISTRO(S)' FROM " + RetSqlTab("Z07") + " (nolock) "
	_cQuery += "	WHERE "+RetSqlCond("Z07")
	_cQuery += "	AND Z07_PALLET = '"+mvIdPlt+"'
	_cQuery += "	AND Z07_ETQVOL = '"+mvChvEtiq+"'
	_cQuery += "	AND Z07_PRODUT = '"+mvCodProd+"'
	_cQuery += "	AND Z07_NUMOS  = '"+_cNumos+"'

	// total dos registros
	_aTotal := U_SqlToVet(_cQuery)

Return (_aTotal)

// ** funcao que valida se a conferencia é devolucao de mercadoria sem nota fiscal
Static Function sfDevMerc()

	// variavel de retorno
	local _lRet := .F.
	// query
	local _cQuery

	// inicio da query
	_cQuery := "SELECT COUNT(*) QTD_REG "
	// itens da nota relacionado ao CESV
	_cQuery += "FROM "+RetSqlName("Z04")+" Z04 (nolock)  "
	// documento digitado no aviso de recebimento de carga
	_cQuery += "INNER JOIN "+RetSqlName("DB2")+" DB2 (nolock)  ON "+RetSqlCond("DB2")+" AND DB2_DOC = Z04_NF AND DB2_SERIE = Z04_SERIE AND DB2_CLIFOR = Z04_CLIENT AND DB2_LOJA = Z04_LOJA "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z04")+" "
	// numero do CESV
	_cQuery += "AND Z04_CESV = '"+_cNumCESV+"' "
	// NUMSEQ em branco
	_cQuery += "AND Z04_NUMSEQ = ' ' "

	// executa a query
	_lRet := (U_FtQuery(_cQuery) > 0)

Return(_lRet)

// ** funcao que define o CSS padrao para botoes
Static Function sfPadrCSS()

	// varivel de retorno
	local _cRet := ""

	// define o CSS
	_cRet := "QPushButton{ background-repeat: none; margin: 2px;"+;
	" background-position: center top; "+;
	" background-color: #CCCCCC; "+;
	" text-align: justify; }"

Return(_cRet)

// ** funcao para completar um palete
Static Function sfComplPlt(mvIdPalete)

	// query
	local _cQryPalete
	// variavel de retorno
	local _lRet := .T.

	// valida se ja tem ID de palete
	If (_lRet) .And. (Empty(mvIdPalete)) .Or. (mvIdPalete == _cIdPltAuto)
		U_FtWmsMsg("Palete não disponível para esta operação.","ATENCAO")
		_lRet := .F.
	EndIf

	// valida se o palete esta disponivel para alteracao
	If (_lRet)
		// monta query
		_cQryPalete := "SELECT COUNT(*) IT_PALETE "
		// itens conferidos
		_cQryPalete += "FROM "+RetSqlName("Z07")+" Z07 (nolock)  "
		// filtro padrao
		_cQryPalete += "WHERE "+RetSqlCond("Z07")+" "
		// numero e sequencia da OS
		_cQryPalete += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		// cliente e loja
		_cQryPalete += "AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
		// contagem
		_cQryPalete += "AND Z07_NRCONT = '"+_cNrContagem+"' "
		// id palete
		_cQryPalete += "AND Z07_PALLET = '"+mvIdPalete+"' "
		// status (C-EM CONFERENCIA / D-CONFERIDO/DISPONIVEL / M-EM MOVIMENTO / A-ARMAZENADO)
		_cQryPalete += "AND Z07_STATUS != 'D' "

		// valida quantidade
		If (U_FtQuery(_cQryPalete) > 0)
			U_FtWmsMsg("Palete não disponível para esta operação.","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// atualiza variaveis
	If (_lRet)
		_lNovoPalete := .F.
		_lNovoVolume := .T.
		_cEtiqProd   := Space(Len(_cEtiqProd))
		_cEtqCodBar  := Space(Len(_cEtqCodBar))
		_cCodProd    := Space(_nTamCodPrd)
		_nQtdProd    := 1
		_nQtdSegUM   := 0
		_cIdPalete   := mvIdPalete
		_cStatusPlt  := "P"
		_cStatusVlm  := "V"
		_cEtqVolume  := Space(Len(_cEtqVolume))

		// atualiza o objeto para receber o foco
		_oGetNrPalete:lReadOnly := (!_lNovoPalete)
		// atualiza objeto para pemitir novas leituras
		_oGetEtqVolume:lReadOnly := (!_lCtrVolume) .And. (!_lNovoVolume)
		// foco na etiqueta de volume
		If (_lEtqIdEAN) .Or. (_lEtqCod128) .Or.  (_lEtqIdDUN) // ean 13 / code 128 / DUN14
			_oGetEtqVolume:SetFocus()
		ElseIf (_lEtqClient) // CLIENTE
			_oGetCodProd:SetFocus()
		EndIf

	EndIf

Return(_lRet)

// ** funcao para estorno do mapa de armazenagem
Static Function sfEstMapa()

	// variavel de retorno
	local _lRet := .F.

	// seek
	local _cSeekZ08

	// mensagem de confirmacao
	If ( ! U_FtYesNoMsg("Confirma o estorno do mapa ?"))
		Return(_lRet)
	EndIf

	// INICIO DE TRANSACAO
	BEGIN TRANSACTION

		// mapa de armazenagem
		dbSelectArea("Z08")
		Z08->(dbSetOrder(1)) // 1-Z08_FILIAL, Z08_NUMOS
		Z08->(dbSeek( _cSeekZ08 := xFilial("Z08")+_cNumOrdSrv ))

		// varre todos os itens do mapa
		While Z08->( ! Eof() ) .And. (Z08->(Z08_FILIAL+Z08_NUMOS) == _cSeekZ08)

			// valida se permite a exclusao
			If (Z08->Z08_STATUS != "P") .Or. ( ! Empty(Z08->Z08_PALLET) ) .Or. (Z08->Z08_ENDSRV != _cDocaSrv)
				// rollback
				DisarmTransaction()
				// mensagem
				U_FtWmsMsg("Já ocorreram movimentações de mercadoria no Mapa de Armazenagem!","ATENCAO")
				// variavel de retorno
				_lRet := .F.
				Break
			EndIf

			// exclui o registro
			RecLock("Z08")
			Z08->(dbDelete())
			Z08->(MsUnLock())

			// variavel de retorno
			_lRet := .T.

			// proximo item
			Z08->(dbSkip())
		EndDo

		// FIM DE TRANSACAO
	END TRANSACTION

	// mensagem
	If (_lRet)
		U_FtWmsMsg("Estorno realizado com sucesso!","ATENCAO")
	EndIf

Return(_lRet)

// ** funcao para validar senha de usuario
Static Function sfVldUser(mvCateg)

	// objetos da tela
	local _oWnd02VldUser
	local _oPnl02Cab
	local _oBt02Sair
	local _oSay02CodUsr, _oSay02Passw
	local _oGet02CodUsr, _oGet02Passw

	// codigo de usuario e senha
	Local _cUsuario := Space(6)
	Local _cPassw   := Space(20)

	// variavel de retorno
	local _lRet := .F.

	// monta o dialogo de validacao do usuario
	_oWnd02VldUser := MSDialog():New(020,018,160,220,"Validação do Usuário",,,.F.,,,,,,.T.,,,.T. )

	// -- painel com as opcoes disponiveis
	_oPnl02Cab := TPanel():New(000,000,nil,_oWnd02VldUser,,.F.,.F.,,,20,20,.T.,.F. )
	_oPnl02Cab:Align:= CONTROL_ALIGN_TOP

	// -- botao Sair
	_oBt02Sair := TBtnBmp2():New(000,000,030,020,"FINAL",,,,{|| _oWnd02VldUser:End() },_oPnl02Cab,"Sair",,.T.)
	_oBt02Sair:Align := CONTROL_ALIGN_RIGHT

	// informacoes do usuario
	_oSay02CodUsr := TSay():New(020,005,{||"Cod. Usuário"},_oWnd02VldUser,,,.F.,.F.,.F.,.T.)
	_oGet02CodUsr := TGet():New(026,005,{|u| If(PCount()>0,_cUsuario:=u,_cUsuario)},_oWnd02VldUser,030,008,'@R 999999',{|| .T. },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cUsuario",,)

	// senha
	_oSay02Passw := TSay():New(036,005,{||"Senha"},_oWnd02VldUser,,,.F.,.F.,.F.,.T.)
	_oGet02Passw := TGet():New(042,005,{|u| If(PCount()>0,_cPassw:=u,_cPassw)},_oWnd02VldUser,050,008,'',{|| IIf(_lRet := sfVldSenha(mvCateg, _cUsuario, _cPassw), _oWnd02VldUser:End(), Nil) },,,,,,.T.,"",,,.F.,.F.,,.F.,.T.,"","_cPassw",,)

	// ativa a tela
	ACTIVATE MSDIALOG _oWnd02VldUser

Return(_lRet)

// ** funcao que valida o codigo do usuario
Static Function sfVldSenha(mvCateg, mvCodUsr, mvPassw)

	// variavel de retorno
	local _lRet := .F.
	local _nRet := 0

	// gerenciamento de senhas padrao
	Local _oUser := MPUserAccount():New()

	// verifica se o usuario esta cadastrado e não é monitor
	dbSelectArea("DCD")
	DCD->(dbSetOrder(1)) //1-DCD_FILIAL, DCD_CODFUN
	If ( ! DCD->(dbSeek( xFilial("DCD")+mvCodUsr )))
		U_FtWmsMsg("Usuário não cadastrado!","ATENCAO")
		Return(_lRet)
	EndIf

	// verifica a categoria do operador
	If ( ! DCD->DCD_ZCATEG $ mvCateg)
		U_FtWmsMsg("Usuário sem permissão!","ATENCAO")
		Return(_lRet)
	EndIf

	// Inicializa a classe de autenticação de usuário
	_oUser:Activate()

	// valida usuario e senha
	_nRet := _oUser:Authentication(mvCodUsr, mvPassw)

	// atualiza variavel
	_lRet := (_nRet > 0)

	// usuário nao autenticado
	If ( ! _lRet)
		U_FtWmsMsg("Usuário não autorizado!","ATENCAO")
	EndIf

Return(_lRet)

// ** funcao que inclui um novo TFAA
Static Function sfGrvTFAA(mvNumTFAA, mvDadosTFAA, mvPVTFAA)

	// variavel de retorno
	local _lRet := .F.

	// grava cabecalho
	local _lGrvCabec := .T.

	// variaveis temporarias
	Local _nIt := 0

	// varre todo os itens do TFAA
	For _nIt := 1 to Len(mvDadosTFAA)

		// verifica necessidade de gravacao do cabecalho
		If (_lGrvCabec)
			// inclui o cabecalho
			dbSelectArea("Z41")
			RecLock("Z41",.T.)
			Z41->Z41_FILIAL := xFilial("Z41")
			Z41->Z41_CODIGO := GetSXENum("Z41","Z41_CODIGO")
			Z41->Z41_DTEMIS := Date()
			Z41->Z41_HREMIS := Time()
			Z41->Z41_NUMOS  := mvDadosTFAA[_nIt][1]
			Z41->Z41_CESV   := mvDadosTFAA[_nIt][2]
			Z41->(MsUnLock())
			// controle de gravacao
			_lGrvCabec := .F.
		EndIf

		// grava os itens
		dbSelectArea("Z42")
		RecLock("Z42",.T.)
		Z42->Z42_FILIAL := xFilial("Z42")
		Z42->Z42_CODIGO := Z41->Z41_CODIGO
		Z42->Z42_ITEM   := StrZero(_nIt,Len(Z42->Z42_ITEM))
		Z42->Z42_TIPONF := mvDadosTFAA[_nIt][ 3]
		Z42->Z42_NF     := mvDadosTFAA[_nIt][ 4]
		Z42->Z42_SERIE  := mvDadosTFAA[_nIt][ 5]
		Z42->Z42_ITEMNF := mvDadosTFAA[_nIt][ 6]
		Z42->Z42_PROD   := mvDadosTFAA[_nIt][ 7]
		Z42->Z42_QTDORI := mvDadosTFAA[_nIt][ 8]
		Z42->Z42_QTDCON := mvDadosTFAA[_nIt][ 9]
		Z42->Z42_NUMSEQ := mvDadosTFAA[_nIt][12]
		If FieldPos("Z42_LOTE") > 0 
			Z42->Z42_LOTE   := mvDadosTFAA[_nIt][13]
		EndIf
		Z42->(MsUnLock())

	Next _nIt

	// confirma numeracao do pedido
	ConfirmSx8()
	// variavel de retorno
	_lRet := .T.

	// atualiza o numero do TFAA
	mvNumTFAA := Z41->Z41_CODIGO

	// insere o log
	U_FtGeraLog(cFilAnt, "Z41", xFilial("Z41") + Z41->Z41_CODIGO, "TFAA " + Z41->Z41_CODIGO + " gerado para a OS " + Z41->Z41_NUMOS + " . Pedido de devolução relacionado: " + mvPVTFAA, "WMS")


Return(_lRet)

// ** funcao que apresenta pergunta para o tipo de endereçamento ao usuario.
Static Function sfTpEndMsg(mvMensagem, mvTitulo)

	Local _oDlgMsg, _oTexto, _oBtnPA, _oBtnBL
	// variavel de retorno
	Local _cRet := CriaVar("DC8_CODEST", .F.)

	// retorno para estutura fisica blocado
	local _cRetBloc := U_FtWmsParam("WMS_RECEBIMENTO_MAPA_ARMAZ_ESTFIS_BLOCADO","C","",.F.,"", _cCodCliFor, _cLojCliFor, Nil, _cNumOrdSrv)

	// retorno para estutura fisica porta palete
	local _cRetPorPal := U_FtWmsParam("WMS_RECEBIMENTO_MAPA_ARMAZ_ESTFIS_PORTA_PALETE","C","",.F.,"", _cCodCliFor, _cLojCliFor, Nil, _cNumOrdSrv)


	Default mvMensagem := "** ERRO **"
	Default mvTitulo   := "ATENCAO"

	DEFINE MSDIALOG _oDlgMsg FROM 020,020 TO 240,200 TITLE OemToAnsi(mvTitulo) PIXEL

	@ 003, 004 TO 027,087 LABEL "Help" OF _oDlgMsg PIXEL
	@ 010, 008 MSGET OemToAnsi(mvTitulo) WHEN .F. SIZE 076,010 OF _oDlgMsg PIXEL

	@ 030, 004 TO 090, 087 OF _oDlgMsg PIXEL
	@ 036, 008 GET _oTexto VAR OemToAnsi(mvMensagem) MEMO READONLY /*NO VSCROLL*/ SIZE 076, 050 OF _oDlgMsg PIXEL

	_oBtnBL  := tButton():New(094,004, "BLOCO"        , _oDlgMsg, {|| _cRet := _cRetBloc  , _oDlgMsg:End() },40,15,,,,.T.)
	_oBtnPA  := tButton():New(094,048, "PORTA PALETE" , _oDlgMsg, {|| _cRet := _cRetPorPal, _oDlgMsg:End() },40,15,,,,.T.)
	_oTexto:SetFocus()

	ACTIVATE MSDIALOG _oDlgMsg

Return(_cRet)

// ** funcao que apresenta pergunta para o tipo de agrupamento da consulta (LOTE X PRODUTO).
Static Function SFAgrupMsg(mvMensagem, mvTitulo)

	Local _oDlgMsg, _oTexto, _oBtnPA, _oBtnBL
	// variavel de retorno
	Local _lRet := .T.

	Default mvMensagem := "** ERRO **"
	Default mvTitulo   := "ATENCAO"

	DEFINE MSDIALOG _oDlgMsg FROM 020,020 TO 240,200 TITLE OemToAnsi(mvTitulo) PIXEL

	@ 003, 004 TO 027,087 LABEL "Help" OF _oDlgMsg PIXEL
	@ 010, 008 MSGET OemToAnsi(mvTitulo) WHEN .F. SIZE 076,010 OF _oDlgMsg PIXEL

	@ 030, 004 TO 090, 087 OF _oDlgMsg PIXEL
	@ 036, 008 GET _oTexto VAR OemToAnsi(mvMensagem) MEMO READONLY /*NO VSCROLL*/ SIZE 076, 050 OF _oDlgMsg PIXEL

	_oBtnBL  := tButton():New(094,004, "PRODUTO" , _oDlgMsg, {|| _lRet := .T., _oDlgMsg:End()},40,15,,,,.T.)
	_oBtnPA  := tButton():New(094,048, "LOTE"    , _oDlgMsg, {|| _lRet := .F., _oDlgMsg:End()},40,15,,,,.T.)
	_oTexto:SetFocus()

	ACTIVATE MSDIALOG _oDlgMsg //CENTERED

Return(_lRet)

// ** funcao para validar o endereco informado na geracao do mapa
Static Function sfVldEndBloco(mvBloco)
	// variavel de retorno
	local _lRet := .T.

	// valida se o endereco existe
	If (_lRet)
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
		If ! SBE->(dbSeek( xFilial("SBE")+_cArmzServ+mvBloco ))
			// mensagem
			U_FtWmsMsg("O endereço informado é inválido ou não está cadastrado")
			// controle
			_lRet := .F.
		EndIf
	EndIf

	// valida se o endereco nao esta bloqueado
	If (_lRet)
		If (SBE->BE_STATUS == "3")
			// mensagem
			U_FtWmsMsg("O endereço informado está bloqueado.")
			// controle
			_lRet := .F.
		EndIf
	EndIf

	// valida se o endereco pertence ao cliente
	If (_lRet)
		If (SBE->BE_ZCODCLI != _cCodCliFor)
			// mensagem
			U_FtWmsMsg("O endereço informado não está liberado para este cliente.")
			// controle
			_lRet := .F.
		EndIf
	EndIf

	// valida se o endereco eh blocado
	If (_lRet)
		If (SBE->BE_ESTFIS != "000007")
			// mensagem
			U_FtWmsMsg("O endereço informado não é do tipo BLOCADO.")
			// controle
			_lRet := .F.
		EndIf
	EndIf

Return(_lRet)

// ** funcao que verifica se o item eh de nota fiscal de logistica reversa
Static Function sfEhLogRev(mvNumSeq)
	// variavel de retorno
	local _lRet := .F.
	// query
	local _cQuery

	// prepara query
	_cQuery := " SELECT TOP 1 D1_ZLOGREV "
	_cQuery += " FROM   " + RetSqlTab("SD1") + " (nolock) "
	_cQuery += " WHERE  " + RetSqlCond("SD1")
	_cQuery += "        AND D1_NUMSEQ IN " + FormatIn(mvNumSeq, ";")
	_cQuery += "        AND D1_IDENTB6 != ' ' "
	_cQuery += " ORDER  BY CASE "
	_cQuery += "             WHEN D1_ZLOGREV = 'S' THEN 0 "
	_cQuery += "             ELSE 1 "
	_cQuery += "           END "

	// executa query
	_lRet := (U_FtQuery(_cQuery) == "S")

Return(_lRet)

Static Function EtqSumi()
	// obejtos da tela
	local _oBmpEstorno, _oBmpConsDetSair

	local _oPnlConfDet, _oPnlConfRod

	local cRetorno := .T.

	// variaveis do browse
	local _aHeadSum := {}

	Local _lTpAgrup := .T.

	Local oFont18:= TFont():New('Arial',,-18,,.F.)
	Local oFont14n:= TFont():New('Arial',,-14,,.T.)

	Private nQtdSum	    := 0
	Private _cProdBp	:= SPACE(8)
	private _oBrwSum
	Private _oGetSum
	Private _oSayTS
	Private oDlgEtqS

	// define o header
	aAdd(_aHeadSum,{"Etq Cliente" ,"Z11_CODETI"  ,"@!"                         ,8                      ,0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadSum,{"Quant"       ,"Z11_QTD1"    ,_cMaskQuant                  ,1                      , 0                    ,Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHeadSum,{"Produto"     ,"B1_COD"      ,PesqPict("SB1","B1_COD")     ,TamSx3("B1_COD")[1]    , 0                    ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadSum,{"Desc Prod"   ,"B1_DESC"     ,PesqPict("SB1","B1_DESC")    ,TamSx3("B1_DESC")[1]   , 0                    ,Nil,Nil,"C",Nil,"R",,,".F." })

	_aColsSum := {}
	//	AADD(_aColsSum,{"",0,"","",.F.})

	// monta o dialogo 
	oDlgEtqS := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Receb. Sumitomo",,,.F.,,,,,,.T.,,,.T. )
	oDlgEtqS:lEscClose := .F.

	// cria o panel do cabecalho - botoes
	_oPnlConfDet := TPanel():New(000,000,nil,oDlgEtqS,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlConfDet:Align:= CONTROL_ALIGN_TOP

	// Total de produtos bipados
	_oSayTS       := TSay():New(005,005,{|| "Quant. lida: " + AllTrim(Str(nQtdSum)) },_oPnlConfDet,,oFont14n,.F.,.F.,.F.,.T.)
	_oSayTS:Align := CONTROL_ALIGN_CENTER

	// -- botão de CONFIRMACAO
	_oBtnSrvConf := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| ConfSum() },_oPnlConfDet,"Ok",,.T.)
	_oBtnSrvConf:Align := CONTROL_ALIGN_RIGHT

	// monta o browse com os códigos de barras lidos
	_oBrwSum := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsSum),'AllwaysTrue()','','AllwaysTrue()',oDlgEtqS,_aHeadSum,_aColsSum)
	_oBrwSum:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// cria o panel do rodape
	_oPnlConfRod := TPanel():New(000,000,nil,oDlgEtqS,,.F.,.F.,,,020,020,.T.,.F. )
	_oPnlConfRod:Align:= CONTROL_ALIGN_BOTTOM

	// Campo para bipar os códigos de barra
	_oGetSum := TGet():New(005,005,{|u| If(PCount()>0,_cProdBp:=u,_cProdBp)},_oPnlConfRod,060,008,,{|| (Vazio()) .Or. AddBrwS(_cProdBp),_cProdBp := Space(8) },,,oFont18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cProdBp",,)
	_oGetSum:Align := CONTROL_ALIGN_LEFT
	_oGetSum:SetFocus()

	// -- BOTAO DE ESTORNO de leitura
	_oBmpEstorno := TBtnBmp2():New(000,000,040,040,"ESTOMOVI",,,,{|| EstrSum(_oBrwSum:aCols[_oBrwSum:nAt][1],_oBrwSum:nAt) },_oPnlConfRod,"Estornar conferência",,.T.)
	_oBmpEstorno:Align := CONTROL_ALIGN_RIGHT

	// ativa o dialogo
	oDlgEtqS:Activate(,,,.F.,,,)

	if (Len(_aColsSum) == 0)
		cRetorno := .F.
	Else
		_nQtdProd := Len(_aColsSum)
	EndIf


Return (cRetorno)
//-------------------------------------------------------------------------------------------------
Static Function ConfSum()

	If U_FtYesNoMsg("Confirma fim da conferência deste pallet?")
		oDlgEtqS:End()
	EndIf

Return
//-------------------------------------------------------------------------------------------------
Static Function EstrSum(cEtiqCli,nPos)

	If (Empty(cEtiqCli))
		Return
	Else

		If U_FtYesNoMsg("Estornar etiqueta " + AllTrim(cEtiqCli) + " ?")
			ADEL(_aColsSum,nPos)
			ASIZE(_aColsSum,Len(_aColsSum)-1)
			nQtdSum := Len(_aColsSum)
			_oBrwSum:aCols := aClone(_aColsSum)
			_oBrwSum:Refresh(.T.)
			_cProdBp := Space(8)
			_oGetSum:Refresh(.T.)
			_oGetSum:SetFocus()
		EndIf

		_oSayTS:Refresh(.T.)
	EndIf

Return
//-------------------------------------------------------------------------------------------------
Static Function AddBrwS(_cProdBp)
	Local lRet := .T.

	// consultas SQL
	local cQuery    := ""
	local aRetZ56   := {}
	local cRetZ56   := ""
	local cRetZ11   := ""

	// Valida se o código de barras bipado já foi lido (em memória)
	If (lRet)
		If ( Ascan(_aColsSum, { |x| x[1] == _cProdBp }) > 0 )
			U_FtWmsMsg("O código de barras " + AllTrim(_cProdBp) + " já foi lido!")
			lRet := .F.
			_cProdBp := Space(8)
			_oGetSum:Refresh(.T.)
			_oGetSum:SetFocus()
		EndIf
	EndIf

	// Valida se a etiqueta do cliente existe
	If (lRet)
		cQuery := " SELECT Z56_NOTA "   // já adquire a nota fiscal de entrada ao qual este barcode está vinculado, para nova validação posterior 
		cQuery += " FROM "  + RetSQLTab("Z56") + " (nolock) "
		cQuery += " WHERE " + RetSQLCond("Z56")
		cQuery += " AND Z56_CODCLI = '" + _cCodCliFor + "' "
		cQuery += " AND Z56_LOJCLI = '" + _cLojCliFor + "' "
		cQuery += " AND Z56_ETQCLI = '" + _cProdBp    + "' "

		Memowrit("c:\query\TWMSA010_addbrws_etqexiste.txt", cQuery)

		cRetZ56 := U_FTQuery(cQuery)

		// não encontrou etiqueta na base de dados
		If Empty(cRetZ56)
			U_FtWmsMsg("Etiqueta do cliente (barcode) não foi encontrada na base de dados do Tecadi!", "TWMSA010 - AddBrwS - 1")
			_cProdBp := Space(8)
			_oGetSum:Refresh(.T.)
			_oGetSum:SetFocus()
			lRet := .F.
		EndIf
	EndIf

	// valida se barcode pertence a nota fiscal que está sendo conferida nesta OS
	If (lRet)
		// 01 - Z04_FILIAL, Z04_CESV, R_E_C_N_O_, D_E_L_E_T_
		If ( cRetZ56 != GetAdvFVal("Z04", "Z04_NF", xFilial("Z04") + _cNumCESV, 1) )
			U_FtWmsMsg("Etiqueta do cliente (barcode) não pertence a nota fiscal deste recebimento!", "TWMSA010 - AddBrwS - 2")
			_cProdBp := Space(8)
			_oGetSum:Refresh(.T.)
			_oGetSum:SetFocus()
			lRet := .F.
		EndIf
	EndIf

	// Valida se o produto já tem etiqueta de Pallet vinculado
	// consulto o código do produto para já comparar na próxima validação, pois, se retornar qualquer coisa
	// significa que já foi lido anteriormente de qualquer forma...
	If (lRet)
		cQuery := " SELECT Z56_CODPRO, Z56_CODETI "
		cQuery += " FROM "  + RetSQLTab("Z56") + " (nolock) "
		cQuery += " WHERE " + RetSQLCond("Z56")
		cQuery += " AND Z56_CODCLI = '" + _cCodCliFor + "' "
		cQuery += " AND Z56_LOJCLI = '" + _cLojCliFor + "' "
		cQuery += " AND Z56_ETQCLI = '" + _cProdBp    + "' "

		Memowrit("c:\query\TWMSA010_addbrws_cqueryZ56.txt", cQuery)

		aRetZ56 := U_SqlToVet(cQuery)

		If (Len(aRetZ56) < 1)
			U_FtWmsMsg("Etiqueta do cliente (barcode) não foi encontrada na base de dados do Tecadi!", "TWMSA010 - AddBrwS")
			_cProdBp := Space(8)
			_oGetSum:Refresh(.T.)
			_oGetSum:SetFocus()
			lRet := .F.
		EndIf

		If ( !Empty(aRetZ56[1][2]) ) .AND. (lRet)
			U_FtWmsMsg("Este código de barras já está vinculado à etiqueta Tecadi: " + aRetZ56[1][2], "TWMSA010 - AddBrwS")
			lRet := .F.
			_cProdBp := Space(8)
			_oGetSum:Refresh(.T.)
			_oGetSum:SetFocus()
		EndIf
	EndIf

	// Valida se o produto lido na etiqueta Tecadi (que será vinculada) pertence ao código de barras do cliente
	If (lRet)

		cQuery := " SELECT Z11_CODPRO "
		cQuery += " FROM " + RetSqlTab("Z11") + " (nolock) "
		cQuery += " WHERE " + RetSqlCond("Z11")
		cQuery += " AND Z11_CLIENT = '" + _cCodCliFor + "' "
		cQuery += " AND Z11_LOJA   = '" + _cLojCliFor + "' "
		cQuery += " AND Z11_CESV   = '" + _cNumCESV   + "' "
		cQuery += " AND Z11_CODETI = '" + _cEtiqProd  + "' "  // etiqueta TECADI bipada no inicio da conferencia

		Memowrit("c:\query\TWMSA010_addbrws_cqueryZ11.txt", cQuery)

		cRetZ11 := U_FTQuery(cQuery)

		// compara o produto vinculado à etiqueta TECADI com o produto informado pelo cliente na importação de etiquetas
		If (cRetZ11 != aRetZ56[1][1])
			U_FtWmsMsg("O produto " + AllTrim(aRetZ56[1][1]) + " não pertence à etiqueta Tecadi " + AllTrim(_cEtiqProd) + "!")
			lRet := .F.
			_cProdBp := Space(8)
			_oGetSum:Refresh(.T.)
			_oGetSum:SetFocus()
		EndIf
	EndIf

	// Adiciona no Browser e atualiza
	If (lRet)

		AADD(_aColsSum,;
		{ AllTrim(_cProdBp),;                  // código de barras do cliente lido
		1,;                                    // quantidade
		AllTrim(aRetZ56[1][1]),;               // código do produto
		Posicione("SB1",1, xFilial("SB1") + aRetZ56[1][1] ,"B1_DESC"),;   // descrição do produto
		.F. })

		nQtdSum := Len(_aColsSum)

		// atualiza os itens do browse
		_oSayTS:Refresh(.T.)
		_oBrwSum:aCols := aClone(_aColsSum)
		_oBrwSum:Refresh(.T.)
		_cProdBp := Space(8)
		_oGetSum:Refresh(.T.)
		_oGetSum:SetFocus()
	EndIf


Return (lRet)