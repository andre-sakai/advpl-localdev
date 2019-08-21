#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para Montagem de Volumes                         !
!                  ! - Chamada a partir da rotina TWMSA009/TACDA002          !
+------------------+---------------------------------------------------------+
!Autor             ! David                       ! Data de Criacao ! 03/2015 !
+------------------+--------------------------------------------------------*/

User Function TWMSA024(mvQryUsr)

	// controle de confirmacao
	local _lRet := .F.

	// permite conferencia/recebimento por volumes
	private _lCtrVolume := .F.

	// pedido escolhido para aquela operação
	Private _cPedido := ""

	// pedido do cliente
	private _cPedCliente := ""

	// numero carga / agrupadora
	Private _cNrCarga := ""

	// mascara para campos quantidade
	private _cMaskQuant := U_FtWmsParam("WMS_MASCARA_CAMPO_QUANTIDADE", "C", PesqPict("SD1","D1_QUANT"), .F., "", Nil, Nil, Nil, Nil)

	// variavel de controle do loop de conferencias
	private _lContConf := .T.

	// numero onda de separacao
	Private _cNrOndSep := ""

	// valida se ha equipamento informado
	If ( ! Empty(_cCodEquip) )
		// mensagem
		U_FtWmsMsg("No processo de montagem de volumes não é necessário equipamento!","ATENCAO")
		// retorno
		Return(.F.)
	EndIf

	// inclui o codigo do servico de conferencia (montagem) na query
	mvQryUsr += " AND Z06_SERVIC = '001' AND Z06_TAREFA = '007' "

	memowrit("C:\query\twmsa024_query.txt", mvQryUsr)

	// chama funcao para visualizar o resumo da OS
	If ( _lRet := U_ACDA002C(mvQryUsr, "EX", .T., .F., .F., .T.) )

		// permite conferencia/recebimento por volumes
		_lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.F.,.F.,"", Z05->Z05_CLIENT, Z05->Z05_LOJA, "", Z05->Z05_NUMOS)

		// mascara para campos quantidade
		_cMaskQuant := U_FtWmsParam("WMS_MASCARA_CAMPO_QUANTIDADE", "C", PesqPict("SD1","D1_QUANT"), .F., "", Z05->Z05_CLIENT, Z05->Z05_LOJA, "", Z05->Z05_NUMOS)

		// se nao controla por volume, nao permite o uso da funcao
		If ( ! _lCtrVolume )
			U_FtWmsMsg("Rotina disponível somente para contratos com controle de expedição por volume.","Atenção")
			Return (.F.)
		EndIf

		// loop de conferencia de pedidos
		While ( _lContConf )

			// pega o pedido que vai ser executado
			If ( ! sfTRetPed(Z05->Z05_CLIENT, Z05->Z05_LOJA, Z05->Z05_CARGA, Z05->Z05_ONDSEP,Z05->Z05_NUMOS) )
				Loop
			EndIf

			// verifica se foi selecionado pedido
			If ( Empty(_cPedido) )
				// mensagem
				U_FtWmsMsg("É necessário selecionar algum pedido para continuar.","Atenção")
				// retorna para nova tentativa
				Loop
			EndIf

			// se preencheu o pedido
			If ( ! Empty(_cPedido) )
				// rotina específica para montagem de volumes
				U_WMSA024A(;
				Z06->Z06_SERVIC ,;
				Z06->Z06_TAREFA ,;
				Z06->Z06_STATUS ,;
				Z06->Z06_NUMOS  ,;
				Z06->Z06_SEQOS  ,;
				Z05->Z05_CLIENT ,;
				Z05->Z05_LOJA   ,;
				Z06->Z06_PRIOR   )
			EndIf

		EndDo

	EndIf

Return(_lRet)

// ** função da tela todos os pedidos daquela carga
Static Function sfTRetPed(mvCodCli, mvLojCli, mvCarga, mvOndSep, mvNumOS)

	// variavel de controle
	local _lRet := .F.
	// objetos locais
	local _oWmsPedidos, _oBmpOk, _oBmpSair, _oBrwPedidos, _oBmpFim, _oBmpTrc
	local _oPnlPedCab, _oPnlPedRod
	local _oGetChvNfv

	// arrays do browse
	local _aHeadPed  := {}
	// define o acols
	local _aColsPed := sfARetPed(mvCodCli, mvLojCli, mvCarga, mvOndSep)

	// controle se a chave da nota foi encontrada
	local _lChaveOk := .F.

	// parâmetro se o cliente está configurado para permitir troca de volumes
	local _lPodeTroca := U_FtWmsParam("WMS_EXPEDICAO_PERMITE_TROCA_VOLUME","L",.F.,.F.,cFilAnt, mvCodCli, mvLojCli, Nil, Nil)   

	// chave da nota fiscal de venda
	private _cChvNfVen := CriaVar("C5_ZCHVNFV", .F.)

	// monta o dialogo do monitor
	_oWmsPedidos := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Pedidos da Carga",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes de operacao
	_oPnlPedCab := TPanel():New(000,000,nil,_oWmsPedidos,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlPedCab:Align:= CONTROL_ALIGN_TOP

	// botao que seleciona um pedido
	_oBmpOk := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| _cPedido := _oBrwPedidos:aCols[_oBrwPedidos:nAt][2], _lRet := .T., _oWmsPedidos:End() },_oPnlPedCab,"OK",,.T.)
	_oBmpOk:Align := CONTROL_ALIGN_LEFT

	// botao para encerrar a montagem (se tudo já foi concluído)
	_oBmpFim := TBtnBmp2():New(000,000,060,022,"sdusetdel",,,,{|| IIf (_lRet := sfFimOS(mvCodCli, mvLojCli, mvCarga, mvOndSep) , _oWmsPedidos:End(), Nil ) },_oPnlPedCab,"Finalizar montagem",,.T.)
	_oBmpFim:Align := CONTROL_ALIGN_LEFT

	// -- Troca de volume
	if (_lPodeTroca)
		_oBmpTrc := TBtnBmp2():New(000,000,060,022,"DESTINOS",,,,{|| sfAltVol(mvNumOS, mvCodCli, mvLojCli, _oBrwPedidos:aCols[_oBrwPedidos:nAt][2]) },_oPnlPedCab,"Troca de Volume",,.T.)
		_oBmpTrc:Align := CONTROL_ALIGN_LEFT
	EndIf

	// botao que sai
	_oBmpSair := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| _lContConf := .F., _oWmsPedidos:End()},_oPnlPedCab,"Sair",,.T.)
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// define array do browse
	aAdd(_aHeadPed,{"Sts"           , "IT_ZMNTVOL" ,"@!" ,2                      ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Pedido"        , "C9_PEDIDO"  ,"@!" ,TamSx3("C9_PEDIDO")[1] ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Agrupador"     , "C5_ZAGRUPA" ,"@!" ,TamSx3("C5_ZAGRUPA")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Ped.Cliente"   , "C5_ZPEDCLI" ,"@!" ,TamSx3("C5_ZPEDCLI")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Chave Nf Venda", "C5_ZCHVNFV" ,"@!" ,TamSx3("C5_ZCHVNFV")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })

	// cria o panel para o campo de confirmacao do endereco
	_oPnlPedRod := TPanel():New(000,000,nil,_oWmsPedidos,,.F.,.F.,,CLR_LIGHTGRAY,22,22,.T.,.F.)
	_oPnlPedRod:Align:= CONTROL_ALIGN_TOP

	// leitura do codigo da chave da nota fiscal
	_oGetChvNfv := TGet():New(001,002,{|u| If(PCount()>0,_cChvNfVen:=u ,_cChvNfVen )}, _oPnlPedRod, 113, 008,'@!',{|| (Vazio()) .Or. (sfVldChvNfv(_cChvNfVen, @_oBrwPedidos, _aHeadPed, @_lChaveOk )), IIf(_lChaveOk, _oBmpOk:Click(), Nil) },,,,,,.T.,"",, Nil,.F.,.F.,,.F.,.F.,""  ,"_cChvNfVen"  ,,,,,, .T. ,"Chave Nota Venda", 1)

	// browse
	_oBrwPedidos := MsNewGetDados():New(078,000,148,118,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsPed),'AllwaysTrue()','','AllwaysTrue()',_oWmsPedidos,_aHeadPed,_aColsPed)
	_oBrwPedidos:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwPedidos:oBrowse:blDblClick := {|| _oBmpOk:Click() }

	// ativacao da tela
	ACTIVATE MSDIALOG _oWmsPedidos

Return (_lRet)

// ** função que retorna o array de pedidos
Static Function sfARetPed(mvCodCli, mvLojCli, mvCarga, mvOndSep)
	// array que vai receber os dados
	local _aPedidos := {}
	// query para busca de pedidos
	local _cQuery := ""

	// busco os pedidos baseado na carga
	_cQuery += " SELECT DISTINCT CASE "
	_cQuery += "                   WHEN C5_ZMNTVOL = 'S' THEN 'OK' "
	_cQuery += "                   ELSE '  ' "
	_cQuery += "                 END   IT_ZMNTVOL, "
	_cQuery += "                 C9_PEDIDO, "
	_cQuery += "                 C5_ZAGRUPA, "
	_cQuery += "                 C5_ZPEDCLI, "
	_cQuery += "                 C5_ZCHVNFV, "
	_cQuery += "                 '.F.' IT_DEL "
	// itens linerados do pedido
	_cQuery += " FROM   " + RetSqlTab("SC9") + " (nolock) "
	// cab. pedido de venda
	_cQuery += "        INNER JOIN " + RetSqlTab("SC5") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("SC5")
	_cQuery += "                   AND C5_TIPOOPE = 'P' "
	_cQuery += "                   AND C5_NUM = C9_PEDIDO "
	// filtro por onda de separacao
	If ( ! Empty(mvOndSep) )
		_cQuery += "                   AND C5_ZONDSEP = '" + mvOndSep + "' "
	EndIf
	// filtro padrao
	_cQuery += " WHERE  " + RetSqlCond("SC9")
	// cliente e loja
	_cQuery += "        AND C9_CLIENTE = '" + mvCodCli + "' "
	_cQuery += "        AND C9_LOJA = '" + mvLojCli + "' "
	// filtro por carga
	If ( ! Empty(mvCarga) )
		_cQuery += "        AND C9_CARGA = '" + mvCarga + "' "
	EndIf
	// ordem dos dados
	_cQuery += " ORDER  BY C9_PEDIDO "

	memowrit("C:\query\twmsa024_sfARetPed.txt",_cQuery)

	// jogo os dados pro array
	_aPedidos := U_SqlToVet(_cQuery)

	// retorno o array
Return (_aPedidos)

// ** rotina principal pra montagem de volumes
User Function WMSA024A(mvCodServ, mvCodTaref, mvStatus, mvNumOS, mvSeqOS, mvCodCli, mvLojCli, mvPriori)

	// NOTA: Z07_ETQVOL refere-se a etiqueta AGRUPADORA

	// objetos locais
	local _oWmsConfMont
	local _oPnlCfeCab
	local _oBmpCfeNvPalete, _oBmpCfeCons, _oBmpOpcoes
	local _oSayNewAgrupa, _oSayCodProd, _oSayCodEmb
	local _oCmbCodEmb

	// sub-menu
	local _oMnuOpcoes := nil
	local _oSbMnOpc1  := nil
	local _oSbMnOpc2  := nil
	local _oSbMnOpc3  := nil
	local _oSbMnOpc4  := nil
	local _oSbMnOpc5  := nil

	// valida identificacao do produto
	local _cTpIdEtiq := U_FtWmsParam("WMS_PRODUTO_ETIQ_IDENT","C","INTERNA",.F.,"", mvCodCli, mvLojCli, "", mvNumOS)

	// controle de while
	local _lRet := .T.

	local _lOk := .F.

	// tipo da operacao da OS (E-Ent/S-Sai/I-Int)
	local _cTipoOper := ""
	local _cDscOpera := ""

	// permite sair
	local _lSair := (mvStatus == "FI")

	// descrição do campo de busca do produto
	Local _cDescGet := "Etiq. Volume Tecadi:"

	// variaveis recebidas de parametro
	Private _cCodServ    := mvCodServ
	Private _cCodTaref   := mvCodTaref
	Private _cCodStatus  := mvStatus
	private _cNumOrdSrv  := mvNumOS
	private _cSeqOrdSrv  := mvSeqOS
	Private _cCodCliFor  := mvCodCli
	Private _cLojCliFor  := mvLojCli

	// informacoes do produto
	Private _nTamEtqInt := TamSx3("Z11_CODETI")[1]
	private _cEtiqProd  := CriaVar("Z11_CODETI",.F.)
	private _cEtqCodBar := ""
	Private _nTamCodPrd := TamSx3("B1_COD")[1]
	Private _cCodProd   := Space(_nTamCodPrd)
	Private _cNewAgrup  := Space(_nTamEtqInt)
	Private _cOldAgrup  := Space(_nTamEtqInt)
	Private _cDscProd   := ""
	Private _nQtdProd   := 1
	Private _nQtdSegUM  := 0
	Private _cPltCli    := Space(30)

	// controle de numero de contagens
	Private _cNrContagem := ""

	// Id do palete
	private _nTamIdPal  := TamSx3("Z11_CODETI")[1]
	private _cIdPalete  := Space(_nTamIdPal)
	private _cPltOrig   := Space(_nTamIdPal)
	private _cMskEtiq   := PesqPict("Z11","Z11_CODETI")
	private _cMskCodBar := PesqPict("SB1","B1_CODBAR")
	private _cCodUnit   := CriaVar("DC1_CODUNI",.F.)

	// numero da movimentacao do veiculo
	private _cNumCESV := ""

	// armazem
	private _cArmzServ := ""

	// objetos private
	private _oGetNewAgrupa, _oGetOldAgrupa, _oGetCodProd
	Private _oBtnNvVol  // botão de novo volume

	// variaveis do browse
	private _oBrwConfMont
	private _aHeadConf := {}
	private _aColsConf := {}

	// tipo de identificacao
	private _lEtqIdInt  := (AllTrim(_cTpIdEtiq) == "INTERNA")
	private _lEtqIdEAN  := (AllTrim(_cTpIdEtiq) == "EAN") .Or. (AllTrim(_cTpIdEtiq) == "EAN13")
	private _lEtqIdDUN  := (AllTrim(_cTpIdEtiq) == "DUN14")
	private _lEtqCod128 := (AllTrim(_cTpIdEtiq) == "CODE128")
	private _lEtqClient := (AllTrim(_cTpIdEtiq) == "CLIENTE")

	// doca do servico
	private _cDocaSrv := ""

	// controle de apontamento de palete
	private _lNovoPalete := .T.

	// controle de apontamento de volume
	private _lNovoVolume := .T.

	// variáveis de controle de número de série
	private _lNumSerie := .F.   // flag de controle de numero de serie no produto
	private _lSerieAtv := U_FtWmsParam("WMS_CONTROLE_POR_NUMERO_SERIE","L",.F.,.F.,"", mvCodCli, mvLojCli, Nil, Nil)   // flag se o cliente controla número de série (parâmetro tabela Z30)

	// controla se informa a quantidade manual
	Private _lInfManual := .F.

	// tipos de estoque
	private _cTpEmbala := ""
	private _aOpcoesEmb := sfRetTpEmbala(mvCodCli) // retorna todas as embalagens disponíveis

	// codigo do unitizador padrao
	private _cUnitPdr := SuperGetMV('TC_PLTPADR',.F.,"000001")

	// define quantidade de caracteres da etiqueta do cliente
	private _nTamEtqCli := U_FtWmsParam("WMS_QUANT_CARACTERES_ETIQUETA_CLIENTE", "N", TamSx3("Z56_ETQCLI")[1], .F., "", mvCodCli, mvLojCli, Nil, Nil)

	// parâmetro para não necessitar confirmar "novo volume" na conferência
	Private _lAutoVol := U_FtWmsParam("WMS_EXPEDICAO_VOLUME_AUTOMATICO", "L", .F. , .F., "", mvCodCli, mvLojCli, "", mvNumOS)

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
	ElseIf (_lSerieAtv)
		_cEtqCodBar := Space(_nTamEtqInt)
		_cMskCodBar := PesqPict("Z11","Z11_CODETI")
	EndIf

	// posiciona na OS
	dbSelectArea("Z05")
	Z05->(dbSetOrder(1)) // 1-Z05_FILIAL, Z05_NUMOS
	Z05->(dbSeek( xFilial("Z05") + _cNumOrdSrv ))

	// atualiza CESV
	_cNumCESV  := Z05->Z05_CESV
	// define o tipo da operacao da OS (Sempre será do tipo S)
	_cTipoOper := Z05->Z05_TPOPER
	_cDscOpera := "Expedição"

	// numero da carga
	_cNrCarga := Z05->Z05_CARGA

	// numero da onda de separacao
	_cNrOndSep := Z05->Z05_ONDSEP

	// posiciona no item da OS
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	Z06->(dbSeek( xFilial("Z06") + _cNumOrdSrv + _cSeqOrdSrv ))

	// atualiza armazem
	_cArmzServ := Z06->Z06_LOCAL

	// doca do servico
	_cDocaSrv  := Z06->Z06_ENDSRV

	//verifica se a OS está em um estado válido (execução) pois pode ter sido alterada por outro conferente ou rotina, ainda que dentro do laço
	If (Z06->Z06_STATUS != 'EX')
		// mensagem
		U_FtWmsMsg("O status da ordem de serviço " + Z06->Z06_NUMOS + " é inválido (" + Z06->Z06_STATUS + "). Verifique com o supervisor. A tela será fechada.","Erro")
		// retorno
		Return(.F.)
	Endif

	// posiciona no pedido
	dbSelectArea("SC5")
	SC5->(dbSetOrder(1)) // 1-C5_FILIAL, C5_NUM
	SC5->(dbSeek( xFilial("SC5") + _cPedido ))

	// atualiza pedido do cliente
	_cPedCliente := SC5->C5_ZPEDCLI

	// valida se o pedido ja esta ok
	If (SC5->C5_ZMNTVOL == "S")
		U_FtWmsMsg("O pedido "+_cPedido+" já está finalizado.","Atenção")
		Return (.F.)
	EndIf

	// atualiza os dados
	sfSelDados(.F.)

	// define novo pallet
	_lNovoPalete := (Empty(_cIdPalete))

	// monta o dialogo do monitor
	_oWmsConfMont := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Mont.Vol/Pedido: "+_cPedido,,,.F.,,,,,,.T.,,,.T. )
	_oWmsConfMont:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlCfeCab := TPanel():New(000,000,nil,_oWmsConfMont,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlCfeCab:Align:= CONTROL_ALIGN_TOP

	// opcoes de operacoes

	// -- NOVO PALLET
	_oBmpCfeNvPalete := TBtnBmp2():New(000,000,060,022,"ARMIMG32",,,,{|| sfNovoPalete() },_oPnlCfeCab,"Novo Palete",,.T.)
	_oBmpCfeNvPalete:Align := CONTROL_ALIGN_LEFT

	// -- NOVO VOLUME
	_oBtnNvVol := TBtnBmp2():New(000,000,060,022,"AVGARMAZEM",,,,{|| sfNovoVolume() },_oPnlCfeCab,"Novo Volume",,.T.)
	_oBtnNvVol:Align := CONTROL_ALIGN_LEFT

	// -- CONSULTA DETALHES
	_oBmpCfeCons := TBtnBmp2():New(000,000,060,022,"MDIHELP",,,,{|| sfDetConfer() } ,_oPnlCfeCab,"Informações",,.T.)
	_oBmpCfeCons:Align := CONTROL_ALIGN_LEFT

	// sub-itens do menus
	_oMnuOpcoes := TMenu():New(0,0,0,0,.T.)

	// adiciona itens no Menu
	// INTERROMPER
	If ( ! _lSair )
		_oSbMnOpc1 := TMenuItem():New(_oMnuOpcoes,"Interromper",,,,{|| sfInterromper(_oWmsConfMont, @_lOk) },,"STOP"   ,,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOpc1)
	EndIf
	// -- FINALIZAR OS
	_oSbMnOpc2 := TMenuItem():New(_oMnuOpcoes,"Finalizar Pedido/OS",,,,{|| sfFinalizaOS(_oWmsConfMont, @_lOk) },,"CHECKED",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc2)
	// -- CONSULTAR DETALHES
	_oSbMnOpc3 := TMenuItem():New(_oMnuOpcoes,"Cons. Detalhe OS",,,,{|| U_ACDA002B(_cNumOrdSrv, _cSeqOrdSrv,.F.) },,"NOTE",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc3)
	// -- CONSULTAR DETALHES DO PEDIDO SELECIONADO
	_oSbMnOpc4 := TMenuItem():New(_oMnuOpcoes,"Cons. Detalhe Pedido",,,,{|| sfDetPedido() },,"NOTE",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc4)
	// -- SAIR SEM INTERROMPER
	If ((_lUsrGeren) .Or. (_lUsrAccou) .Or. (_lUsrSuper) .Or. (_lSair))
		_oSbMnOpc5 := TMenuItem():New(_oMnuOpcoes,"Sair",,,,{|| _lOk := .T. , _oWmsConfMont:End()},,"FINAL",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOpc5)
	EndIf

	// -- BOTAO COM MAIS OPCOES
	_oBmpOpcoes := TBtnBmp2():New(000,000,060,022,"SDUAPPEND",,,,{|| Nil },_oPnlCfeCab,"",,.T.)
	_oBmpOpcoes:Align := CONTROL_ALIGN_RIGHT
	_oBmpOpcoes:SetPopupMenu(_oMnuOpcoes)

	// tipos de embalagem
	_oSayCodEmb := TSay():New(025,003,{||"Embalagem"},_oWmsConfMont,,,.F.,.F.,.F.,.T.)
	_oCmbCodEmb := TComboBox():New(023,035,{|u| If(PCount()>0,_cTpEmbala:=u,_cTpEmbala)},_aOpcoesEmb,085,008,_oWmsConfMont,,,,,,.T.,,"",,,,,,,_cTpEmbala)
	_oCmbCodEmb:bWhen := {|| Len(_aOpcoesEmb) != 0 }

	// código de barras para localização/busca do produto (EAN/DUN/ETQ INTERNA/CLIENTE/ETC)
	if !(_lSerieAtv) // se não controlar por número de série (o que significa que o volume é 1 para 1), exibe os campos para montagem de volume
		_cDescGet := "Cód. barras "
		// nova etiqueta agrupadora (Destino)
		_oSayNewAgrupa := TSay():New(038,003,{||"Nova Agrupadora"},_oWmsConfMont,,,.F.,.F.,.F.,.T.)
		_oGetNewAgrupa := TGet():New(036,050,{|u| If(PCount()>0,_cNewAgrup:=u,_cNewAgrup)},_oWmsConfMont,050,010,_cMskEtiq,{|| (Vazio()) .Or. (sfVldAgrupa(@_lOk, _cNewAgrup, .T.)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNewAgrup",,)
		_oGetNewAgrupa:bWhen := {|| (_lCtrVolume) }
		_oGetNewAgrupa:lReadOnly := ( ! _lNovoVolume )

		// etiqueta agrupadora antiga (origem)
		_oSayOldAgrupa := TSay():New(051,003,{||"Agrup. Origem"},_oWmsConfMont,,,.F.,.F.,.F.,.T.)
		_oGetOldAgrupa := TGet():New(049,050,{|u| If(PCount()>0,_cOldAgrup:=u,_cOldAgrup)},_oWmsConfMont,050,010,_cMskEtiq,{|| (Vazio()) .Or. (sfVldAgrupa(@_lOk, _cOldAgrup, .F.)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cOldAgrup",,)
		_oGetOldAgrupa:bWhen := {|| (_lCtrVolume)  }
	Endif
	_oSayCodProd := TSay():New(064,003,{|| _cDescGet },_oWmsConfMont,,,.F.,.F.,.F.,.T.)
	_oGetCodProd := TGet():New(062,055,{|u| If(PCount()>0,_cEtqCodBar:=u,_cEtqCodBar)},_oWmsConfMont,050,010, _cMskCodBar, {|| (Vazio()) .Or. ( sfVldProd( _cTpIdEtiq) ) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtqCodBar",,)

	// browse com a listagem dos produtos conferidos
	_oBrwConfMont := MsNewGetDados():New(075,003,154,118,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsConf),'AllwaysTrue()','','AllwaysTrue()',_oWmsConfMont,_aHeadConf,_aColsConf)

	// foco no campo correto para bipar
	If (_lSerieAtv)
		_oGetCodProd:SetFocus()
	Else
		_oGetNewAgrupa:SetFocus()
	EndIf

	// ativa a tela
	_oWmsConfMont:Activate(,,,.F.,{|| _lOk },,)

Return ()

// ** função que valida a etiqueta agrupadora
Static Function sfVldAgrupa(mvOk, mvCodAgrup, mvNovaEtiq)
	// variavel de retorno
	local _lRet := .T.
	// query
	local _cQuery
	// variavel de controle de utilização do volume
	local _cConVol := ""

	// dados do palete original
	local _aPltOrig := {}

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11")+mvCodAgrup ))
			U_FtWmsMsg("Identificador da agrupadora não encontrado no sistema!","ATENCAO")
			_lRet := .F.
		ElseIf (Z11->Z11_TIPO != '04')
			U_FtWmsMsg("Identificador da agrupadora inválido!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// valida se a nota etiqueta esta em uso
	If (_lRet) .And. (mvNovaEtiq)

		// prepara query
		_cQuery := " SELECT COUNT(*) QTD_REG "
		_cQuery += " FROM   "+RetSqlTab("Z16")
		_cQuery += " WHERE  "+RetSqlCond("Z16")
		_cQuery += "       AND Z16_ETQVOL = '" + mvCodAgrup + "' "
		_cQuery += "       AND Z16_SALDO != 0 "
		_cQuery += "       AND Z16_PEDIDO != '" + _cPedido + "' "
		_cQuery += "       AND Z16_PEDIDO != ' ' "
		_cQuery += "       AND Z16_ORIGEM = 'VOL' "

		// executa query e validacao
		If (U_FtQuery(_cQuery) != 0)
			// mensagem
			U_FtWmsMsg("Essa etiqueta de volume já foi utilizada. Favor verificar e utilizar uma nova etiqueta de volume!","ATENCAO")
			// variavel de retorno
			_lRet := .F.
		EndIf

	EndIf

	// se o volume já foi usado uma vez na mesma montagem
	If (_lRet) .And. (mvNovaEtiq)

		// query de validação do uso do volume
		_cQuery := " SELECT Z07_PEDIDO "
		// filtro na table de conferência
		_cQuery += " FROM " + RetSqlTab("Z07") + " (nolock) "
		// join pra validar somente as que são do tipo de S-SAÍDA
		_cQuery += " INNER JOIN " + RetSqlTab("Z05") + " (nolock)  ON Z05_NUMOS = Z07_NUMOS AND Z05_TPOPER = 'S' AND " + RetSqlCond("Z05")
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z07")
		// codigo da etiqueta agrupadora
		_cQuery += " AND Z07_ETQVOL = '" + mvCodAgrup + "' "

		// jogo o resultado da query para a variavel para validar
		_cConVol := U_FtQuery(_cQuery)

		// se encontrou algum registro, vai informar ao usuário
		If ( ! Empty(_cConVol))
			// mensagem
			U_FtWmsMsg("Essa etiqueta de volume já foi usada no pedido "+_cConVol+". Favor verificar!","ATENCAO")
			// variavel de retorno
			_lRet := .F.
		EndIf

	EndIf

	// valida se a etiqueta antiga esta disponivel
	If (_lRet) .And. ( ! mvNovaEtiq )

		// funcao que retorna a composicao do palete, conforme etiqueta agrupadora
		//  estrutura:
		//  1- Id Palete
		//  2- Cod. Produto
		//  3- Etq Produto
		//  4- Etq Volume
		//  5. Saldo
		//  6. End. Atual
		//  7. Saldo Atual
		//  8. Tipo de Estoque
		//  9. Lote
		// 10. Validade Lote
		// 11. Número série
		// 12. Data Número série
		// 13. NUMSEQ
		_aPltOrig := sfRetCompos(mvCodAgrup, Nil)

		// valida se encontrou dados
		If (Len(_aPltOrig) == 0)
			// mensagem
			U_FtWmsMsg("Etiqueta de volume não encontrada!","ATENCAO")
			// variavel de retorno
			_lRet := .F.
		EndIf

		// atualiza variaveis
		If (_lRet) .And. (Len(_aPltOrig) > 0)
			_cPltOrig := _aPltOrig[1][1]
		EndIf

	EndIf

	// pra retornar o parâmetro da rotina
	mvOk := _lRet

	// atualiza objetos
	If (_lRet)
		// quando for leitura de nova etiqueta
		If (mvNovaEtiq) .AND. !(_lSerieAtv)
			// atualiza variaveis de controle
			_lNovoVolume := .F.
			// atualiza objetos
			_oGetNewAgrupa:lReadOnly := ( ! _lNovoVolume)
		EndIf
	EndIf

	// retorno a variavel
Return (_lRet)

// ** funcao para filtrar os itens já conferidos/montados do pedido selecionado, conforme codigo do operador
Static Function sfSelDados(mvRefesh)
	// campos para o select
	Local _cQuery := ""
	Local nX := 0

	// reinicia variaveis dos itens
	_aColsConf := {}

	// fecha alias
	If (Select("QRYCNF")!=0)
		dbSelectArea("QRYCNF")
		dbCloseArea()
	EndIf

	// abre tebela de conferencia
	dbSelectArea("Z07")

	// monta a query para buscar os itens já conferidos
	_cQuery := " SELECT Z07_ETQVOL, Z07_PRODUT, B1_DESC, SUM(Z07_QUANT) Z07_QUANT, SUM(Z07_QTSEGU) Z07_QTSEGU "
	// tabela de itens conferidos
	_cQuery += " FROM "+RetSqlTab('Z07')+" (nolock) "
	// cadastro de produtos
	_cQuery += " INNER JOIN "+RetSqlTab('SB1')+" (nolock)  ON "+RetSqlCond("SB1")+" AND B1_COD = Z07_PRODUT "
	// filtros
	_cQuery += " WHERE "+RetSqlCond("Z07")+" "
	_cQuery += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	_cQuery += " AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
	_cQuery += " AND Z07_NRCONT = '"+_cNrContagem+"' "
	_cQuery += " AND Z07_PEDIDO = '"+_cPedido+"' " // somente do pedido selecionado anteriormente
	// somente que nao C-EM CONFERENCIA
	_cQuery += " AND Z07_STATUS = 'C' "
	// agrupamento de informacoes
	_cQuery += " GROUP BY Z07_ETQVOL, Z07_PRODUT, B1_DESC "
	// ordem dos dados
	_cQuery += " ORDER BY Z07_ETQVOL, Z07_PRODUT "

	memowrit("c:\query\twmsa024_sfSelDados.txt",_cQuery)

	// executa a query
	dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),"QRYCNF",.F.,.T.)

	// verifica a necessidade de criar o Header
	If (Len(_aHeadConf)==0)
		// browse de acompanhamento
		aAdd(_aHeadConf,{"Etq.Vol"    ,"Z07_ETQVOL" ,_cMskEtiq                    ,TamSx3("Z07_ETQVOL")[1], TamSx3("Z07_ETQVOL")[2], Nil, Nil, "C", Nil, "R",,, ".F."})
		aAdd(_aHeadConf,{"Produto"    ,"Z07_PRODUT" ,PesqPict("Z07","Z07_PRODUT") ,TamSx3("Z07_PRODUT")[1], 0                      , Nil, Nil, "C", Nil, "R",,, ".F."})
		aAdd(_aHeadConf,{"Descr."     ,"B1_DESC"    ,PesqPict("SB1","B1_DESC")    ,TamSx3("B1_DESC")[1]   , 0                      , Nil, Nil, "C", Nil, "R",,, ".F."})
		aAdd(_aHeadConf,{"Quant"      ,"Z07_QUANT"  ,_cMaskQuant                  ,TamSx3("Z07_QUANT")[1] , TamSx3("Z07_QUANT")[2] , Nil, Nil, "N", Nil, "R",,, ".F."})
		aAdd(_aHeadConf,{"Qtd Seg UM" ,"Z07_QTSEGU" ,_cMaskQuant                  ,TamSx3("Z07_QTSEGU")[1], TamSx3("Z07_QTSEGU")[2], Nil, Nil, "N", Nil, "R",,, ".F."})
	EndIf

	// seleciona o novo alias
	dbSelectArea("QRYCNF")
	QRYCNF->(dbGoTop())

	// caso nao tenha itens
	If QRYCNF->(Eof())
		// cria a linha de acordo com os campos do Header
		aAdd(_aColsConf,Array(Len(_aHeadConf)+1))
		// atualiza campos do Browse
		For nX := 1 To Len(_aHeadConf)
			_aColsConf[1][nX] := CriaVar(_aHeadConf[nX][2])
		Next nX
		// campo de controle do deletado
		_aColsConf[1][Len(_aHeadConf)+1] := .F.
	Else
		While QRYCNF->(!Eof())
			// cria a linha de acordo com os campos do Header
			aAdd(_aColsConf,Array(Len(_aHeadConf)+1))
			// adiciona a demao
			For nX := 1 to Len(_aHeadConf)
				// atualiza informacao do campo
				_aColsConf[Len(_aColsConf),nX] := FieldGet(FieldPos(_aHeadConf[nX,2]))
			Next nX
			// campo de controle do deletado
			_aColsConf[Len(_aColsConf),Len(_aHeadConf)+1] := .F.

			// proximo item
			QRYCNF->(dbSkip())
		EndDo
	EndIf

	// atualiza os itens do browse
	If (_oBrwConfMont <> nil)
		_oBrwConfMont:aCols := aClone(_aColsConf)
		_oBrwConfMont:Refresh(.T.)
	EndIf

Return (.T.)

// ** funcao para gerar um novo palete
Static Function sfNovoPalete()
	// query
	local _cUpdZ07, _cUpdZ16, _cQryPalete
	local _lRet := .T.

	// mensagem de confirmacao
	If ( ! U_FtYesNoMsg("Confirma novo palete ?"))
		Return(.F.)
	EndIf

	// inicia transacao
	BEGIN TRANSACTION

		// funcao generica para geracao do Id Palete
		_cIdPalete := U_FtGrvEtq("03",{_cUnitPdr,""})
		// define o codigo do unitizador
		_cCodUnit := Z11->Z11_UNITIZ

		// finaliza os itens conferidos
		_cUpdZ07 := "UPDATE "+RetSqlName("Z07")+" "
		// status finalizado
		_cUpdZ07 += "SET Z07_STATUS = 'D', Z07_PALLET = '"+_cIdPalete+"', Z07_UNITIZ = '"+_cCodUnit+"' "
		// filtro padrao
		_cUpdZ07 += "WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
		// filtro da OS especifica
		_cUpdZ07 += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		// nr contagem
		_cUpdZ07 += "AND Z07_NRCONT = '"+_cNrContagem+"' "
		// status C=Em Conferência
		_cUpdZ07 += "AND Z07_STATUS = 'C' "
		// somente do pedido selecionado anteriormente
		_cUpdZ07 += "AND Z07_PEDIDO = '"+_cPedido+"' "

		// executa o update
		If (TcSQLExec(_cUpdZ07) < 0)
			// rollback na transacao
			U_FtWmsMsg("*** ERRO NA ATUALIZACAO DO SALDO POR PALETE (sfNovoPalete.1) ***"+CRLF+CRLF+TCSQLError(),"ATENCAO")
			_lRet := .F.
			DisarmTransaction()
			Break
		EndIf

		// realiza a formacao da composicao do palete selecionado
		_cQryPalete := " SELECT Z07_LOCAL, Z07_PALLET, Z07_PLTORI, Z07_ETQPRD, Z07_PRODUT, Z07_NUMSEQ, Z07_UNITIZ, SUM(Z07_QUANT) QTD_ENDERE, Z07_EMBALA, Z07_TPESTO, Z07_CODBAR, Z07_ETQVOL, Z07_VOLORI, Z07_ENDATU, Z07_LOTCTL, Z07_VLDLOT, SUM(Z07_QTSEGU) Z07_QTSEGU, Z07_PLTCLI, Z07_DTSERI, Z07_NUMSER "
		// itens conferidos da OS
		_cQryPalete += " FROM "+RetSqlTab("Z07")+" (nolock) "
		// filtro padrao
		_cQryPalete += " WHERE " + RetSqlCond("Z07")
		// filtro da OS especifica
		_cQryPalete += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		// nr contagem
		_cQryPalete += " AND Z07_NRCONT = '"+_cNrContagem+"' "
		// status C=Em Conferência
		_cQryPalete += " AND Z07_STATUS = 'D' "
		// somente do pedido selecionado anteriormente
		_cQryPalete += " AND Z07_PEDIDO = '"+_cPedido+"' "
		// ID Palete
		_cQryPalete += " AND Z07_PALLET = '"+_cIdPalete+"' "
		// agrupa dados
		_cQryPalete += " GROUP BY Z07_LOCAL, Z07_PALLET, Z07_PLTORI, Z07_ETQPRD, Z07_PRODUT, Z07_NUMSEQ, Z07_UNITIZ, Z07_EMBALA, Z07_TPESTO, Z07_CODBAR, Z07_ETQVOL, Z07_VOLORI, Z07_ENDATU, Z07_LOTCTL, Z07_VLDLOT,Z07_PLTCLI, Z07_DTSERI, Z07_NUMSER "

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
			Z16->Z16_PLTORI := _QRYIDPLT->Z07_PLTORI
			Z16->Z16_UNITIZ	:= _QRYIDPLT->Z07_UNITIZ
			Z16->Z16_ETQPRD	:= _QRYIDPLT->Z07_ETQPRD
			Z16->Z16_CODPRO	:= _QRYIDPLT->Z07_PRODUT
			Z16->Z16_QUANT	:= _QRYIDPLT->QTD_ENDERE
			Z16->Z16_QTSEGU := _QRYIDPLT->Z07_QTSEGU
			Z16->Z16_SALDO  := _QRYIDPLT->QTD_ENDERE
			Z16->Z16_NUMSEQ	:= _QRYIDPLT->Z07_NUMSEQ
			Z16->Z16_STATUS	:= "T" // V=Vazio / T=Total / P=Parcial
			Z16->Z16_QTDVOL	:= _QRYIDPLT->QTD_ENDERE
			Z16->Z16_ENDATU := _QRYIDPLT->Z07_ENDATU
			Z16->Z16_ORIGEM := "VOL"
			Z16->Z16_LOCAL  := _QRYIDPLT->Z07_LOCAL
			Z16->Z16_TPESTO := _QRYIDPLT->Z07_TPESTO
			Z16->Z16_CODBAR := _QRYIDPLT->Z07_CODBAR
			Z16->Z16_EMBALA := _QRYIDPLT->Z07_EMBALA
			Z16->Z16_ETQVOL := _QRYIDPLT->Z07_ETQVOL
			Z16->Z16_VOLORI := _QRYIDPLT->Z07_VOLORI
			Z16->Z16_PLTCLI := _QRYIDPLT->Z07_PLTCLI
			Z16->Z16_CARGA  := _cNrCarga
			Z16->Z16_ONDSEP := _cNrOndSep
			Z16->Z16_PEDIDO := _cPedido
			Z16->Z16_DATA   := Date()
			Z16->Z16_HORA   := Time()
			Z16->Z16_LOTCTL := _QRYIDPLT->Z07_LOTCTL
			Z16->Z16_VLDLOT := StoD(_QRYIDPLT->Z07_VLDLOT)
			Z16->Z16_NUMSER := _QRYIDPLT->Z07_NUMSER
			Z16->Z16_DTSERI := StoD(_QRYIDPLT->Z07_DTSERI)
			Z16->(MsUnLock())

			// atualiza o saldo do palete de origem
			_cUpdZ16 := "UPDATE "+RetSqlName("Z16")+" SET Z16_SALDO = Z16_SALDO - "+AllTrim(Str(_QRYIDPLT->QTD_ENDERE))+" "
			// filtro padrao
			_cUpdZ16 += "WHERE Z16_FILIAL = '"+xFilial("Z16")+"' AND D_E_L_E_T_ = ' ' "
			// id do palete ORIGEM
			_cUpdZ16 += "AND Z16_ETQPAL = '"+_QRYIDPLT->Z07_PLTORI+"' "
			// etiqueta produto
			_cUpdZ16 += "AND Z16_ETQPRD = '"+_QRYIDPLT->Z07_ETQPRD+"' "
			// codigo do produto
			_cUpdZ16 += "AND Z16_CODPRO = '"+_QRYIDPLT->Z07_PRODUT+"' "
			// etiqueta de volume ORIGEM
			_cUpdZ16 += "AND Z16_ETQVOL = '"+_QRYIDPLT->Z07_VOLORI+"' "

			// executa o update
			If (TcSQLExec(_cUpdZ16) < 0)
				// rollback na transacao
				U_FtWmsMsg("*** ERRO NA ATUALIZACAO DO SALDO POR PALETE (sfNovoPalete.2) ***"+CRLF+CRLF+TCSQLError(),"ATENCAO")
				_lRet := .F.
				DisarmTransaction()
				Break
			EndIf

			// proximo item
			_QRYIDPLT->(dbSkip())
		EndDo

		// finaliza transacao
	END TRANSACTION

	If _lRet
		// atualiza variaveis
		_lNovoPalete := .T.
		_lNovoVolume := .T.
		_cEtiqProd   := Space(Len(_cEtiqProd))
		_cCodProd    := Space(_nTamCodPrd)
		_nQtdProd    := 1
		_nQtdSegUM   := 0
		_cPltCli     := Space(30)
		_cIdPalete   := Space(_nTamIdPal)
		_cPltOrig    := Space(_nTamIdPal)
		_cNewAgrup   := Space(_nTamEtqInt)
		_cOldAgrup   := Space(_nTamEtqInt)

		// atualiza os dados
		sfSelDados(.T.)

		// foco no campo
		If (_lSerieAtv)
			_oGetCodProd:SetFocus()
		Else
			_oGetNewAgrupa:SetFocus()
		EndIf
	Endif

Return( _lRet )

// ** funcao para gerar novo volume
Static Function sfNovoVolume()
	// variavel de retorno
	local _lRet := .T.

	// solicita confirmacao se não for automático
	If (_lRet) .And. !(_lAutoVol) 
		If !( U_FtYesNoMsg("Confirma novo volume?") )
			_lRet := .F.
			Return(_lRet)
		EndIf
	EndIf

	// dados ok
	If (_lRet)
		// reinicia variaveis
		_cCodProd    := Space(Len(_cCodProd))
		_cEtiqProd   := Space(Len(_cEtiqProd))
		_nQtdProd    := 1
		_nQtdSegUM   := 0
		_cPltCli     := Space(30)
		_cNewAgrup   := Space(_nTamEtqInt)
		_cOldAgrup   := Space(_nTamEtqInt)
		_lNovoVolume := .T.

		// atualiza os dados
		sfSelDados()

		// foco no campo correto para continuar
		If (_lSerieAtv)
			_oGetCodProd:SetFocus()
		Else
			// atualiza objeto para pemitir novas leituras
			_oGetNewAgrupa:lReadOnly := (!_lCtrVolume) .And. (!_lNovoVolume)

			// foco de objetos
			_oGetNewAgrupa:SetFocus()
		Endif
	EndIf

Return(_lRet)

// ** funcao para interromper o servico atual
Static Function sfInterromper(mvTela, mvTelaOk)
	If ( ! U_FtYesNoMsg("Interromper?","ATENÇÃO"))
		Return( .F. )
	EndIf

	// funcao generica para interromper atividade
	U_FtWmsMtInt(_cNumOrdSrv, _cSeqOrdSrv)

	//se interrompido a OS, não deve selecionar outro pedido na window de pedido, então seta a variavel de controle para fechar a tela
	_lContConf := .F.

	// controle de fechamento do dialogo
	mvTelaOk := .T.

	// fecha tela anterior
	mvTela:End()
Return( .T. )

// ** funcao para validacao e busca do do produto digitado (lido)
Static Function sfVldProd(mvTpIdEtiq)
	// query
	Local _cQuery := ""

	// controle de retorno
	local _lRet := .T.
	// num seq do documento de entrada
	local _cNumSeq := ""
	// controle de for
	local _nX := 0

	// dados do palete original
	local _aPltOrig := {}
	local _nPltOrig

	local _cRetQuery := ""

	// Quantidade padrão do item a ser conferido
	local _nQuant := 0

	// controla se torna obrigatório a digitação de dados adicionais para o produto
	Private _lVldInfAd  := .F.

	// cliente não controla por número de série, então a busca é padrão (EAN/DUN/etc...)
	If !( _lSerieAtv )
		// verifica se foi informado a etiqueta do produto
		If ( Empty(_cEtqCodBar) )
			// mensagem
			U_FtWmsMsg("É necessário informar a etiqueta do produto!","ATENCAO")
			// variavel de controle
			_lRet := .F.
		EndIf

		// verifica se foi informado a etiqueta do novo volumes
		If ( Empty(_cNewAgrup) )
			// mensagem
			U_FtWmsMsg("É necessário informar a etiqueta de DESTINO!","ATENCAO")
			// variavel de controle
			_lRet := .F.
		EndIf

		// realiza a pesquisa do produto, podendo ser feita pelo codigo de barras
		If (_lRet) .And. ( ! U_FtCodBar(@_cEtqCodBar, @_cCodProd, @_lInfManual, @_cNumSeq, mvTpIdEtiq, _cCodCliFor, @_nQuant, @_lNumSerie))
			// mensagem
			U_FtWmsMsg("Dados do produto não encontrados.","ATENCAO")
			// variavel de retorno
			_lRet := .F.
		EndIf

		// valida se o produtos compoe a agrupadora
		If (_lRet)

			// funcao que retorna a composicao do palete, conforme etiqueta agrupadora
			//  estrutura:
			//  1- Id Palete
			//  2- Cod. Produto
			//  3- Etq Produto
			//  4- Etq Volume
			//  5. Saldo
			//  6. End. Atual
			//  7. Saldo Atual
			//  8. Tipo de Estoque
			//  9. Lote
			// 10. Validade Lote
			// 11. Número série
			// 12. Data Número série
			// 13. NUMSEQ
			_aPltOrig := sfRetCompos(_cOldAgrup, _cCodProd)

			// valida se encontrou dados
			If (Len(_aPltOrig) == 0)
				// mensagem
				U_FtWmsMsg("Produto não pertence a essa etiqueta de volume!", "ATENCAO")
				// variavel de retorno
				_lRet := .F.
			EndIf

		EndIf

	Else   // controla por número de série, então localiza pela etiqueta Tecadi (número de série já atrelado na entrada)

		// valida se a etiqueta de volume já foi utilizada
		sfVldAgrupa(@_lRet, _cEtqCodBar, .F.)

		if (_lRet)
			sfVldAgrupa(@_lRet, _cEtqCodBar, .T.)
		EndIf

		// preenche a composição do pallet
		// funcao que retorna a composicao do palete, conforme etiqueta agrupadora
		//  estrutura:
		//  1- Id Palete
		//  2- Cod. Produto
		//  3- Etq Produto
		//  4- Etq Volume
		//  5. Saldo
		//  6. End. Atual
		//  7. Saldo Atual
		//  8. Tipo de Estoque
		//  9. Lote
		// 10. Validade Lote
		// 11. Número série
		// 12. Data Número série
		// 13. NUMSEQ
		If (_lRet)
			_aPltOrig := sfRetCompos(_cEtqCodBar, Nil)

			// valida se encontrou dados
			If (Len(_aPltOrig) == 0)
				// mensagem
				U_FtWmsMsg("Etiqueta de volume Tecadi não localizada!", "TWMSA024 - sfVldProd")
				// limpa o campo serial
				_cEtqCodBar    := Space(Len(_cEtqCodBar))
				// variavel de retorno
				Return ( .F. )
			Else
				// o tratamento do array sempre será a posição 1, pois número de série é individual e único
				_cCodProd   := _aPltOrig[1][2]
				_cNewAgrup  := _aPltOrig[1][4]
				_cOldAgrup  := _aPltOrig[1][4]
				_lNumSerie  := GetAdvFVal("SB1", "B1_ZNUMSER", xFilial("SB1") + _cCodProd,1) == "S"  
				_cNumSeq    := _aPltOrig[1][13]
				_cEtqCodBar := GetAdvFVal("Z16", "Z16_CODBAR", xFilial("Z16") + _aPltOrig[1][1], 1)  
				_cPltOrig   := _aPltOrig[1][1]
			EndIf
		EndIf

		// valido se o cliente controla número de serie mas no produto está desabilitado
		If ( _lRet ) .And. (_lSerieAtv) .AND. !( _lNumSerie )
			// mensagem
			U_FtWmsMsg( "Controle de número de série desabilitado para o produto: " + _cCodProd + ". Favor verificar.","Atenção")
			// variavel de controle
			_lRet := .F.
		EndIf
	EndIf

	// valida se o produto lido faz parte do pedido
	If (_lRet)
		// filtra dados do pedido de venda
		_cQuery := " SELECT COUNT(*) QTD_PEDIDO "
		// itens do pedido de venda
		_cQuery += " FROM " + RetSqlTab("SC6") + " (nolock) "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("SC6")
		// numero do pedido
		_cQuery += " AND C6_NUM = '" + _cPedido + "' "
		// codigo do produto
		_cQuery += " AND C6_PRODUTO = '" + _cCodProd + "' "

		// valida quantidade do item conferido
		If (U_FtQuery(_cQuery) == 0)
			// mensagem
			U_FtWmsMsg("Produto não pertence ao pedido " + _cPedido, "ATENCAO")
			// variavel de retorno
			_lRet := .F.
		EndIf
	EndIf

	// atualiza descricao do produto
	_cDscProd := SB1->B1_DESC

	// reinicia a variavel de quantidade
	_nQtdProd  := 1
	_nQtdSegUM := 0
	_cPltCli   := Space(30)
	_lVldInfAd := (SB1->B1_ZINFADC == "S")

	// verifica se o produto pode informar quantidades
	If (_lRet) .And. (_lInfManual)  
		// tela para informar informações Adicionais
		sfInfQuant()
	EndIf

	// validação do produto a sua respectiva quantidade
	If (_lRet)
		// para cada registro na composição do pallet, consulta o registro e quantidade
		For _nX := 1 to Len(_aPltOrig)
			// com a comparação do produto
			If( _cCodProd == _aPltOrig[_nX][2])
				// valido se a quantidade solicitada é maior do que a quantidade disponível
				If (_nQtdProd > _aPltOrig[_nX][7])
					// mensagem
					U_FtWmsMsg("A quantidade informada é maior do que o saldo do produto!","ATENCAO")
					// variavel de retorno
					_lRet := .F.
				EndIf
			EndIf
		Next _nX
	EndIf

	// se validou todos os itens, grava item conferido
	If (_lRet) .And. (_nQtdProd > 0)

		// insere quantidade lida na relacao de itens
		For _nPltOrig := 1 to Len(_aPltOrig)
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
			Z07->Z07_PLTCLI := _cPltCli
			Z07->Z07_NRCONT	:= _cNrContagem
			Z07->Z07_USUARI := _cCodOper
			Z07->Z07_DATA	:= Date()
			Z07->Z07_HORA	:= Time()
			Z07->Z07_PALLET	:= _cIdPalete
			Z07->Z07_PLTORI := _cPltOrig
			Z07->Z07_UNITIZ := _cCodUnit
			Z07->Z07_STATUS	:= "C" // C-EM CONFERENCIA / D-CONFERIDO/DISPONIVEL / M-EM MOVIMENTO / A-ARMAZENADO
			Z07->Z07_ENDATU	:= _cDocaSrv
			Z07->Z07_PEDIDO := _cPedido
			Z07->Z07_ETQVOL := _cNewAgrup
			Z07->Z07_VOLORI := _cOldAgrup
			Z07->Z07_CODBAR := _cEtqCodBar
			Z07->Z07_EMBALA := _cTpEmbala
			Z07->Z07_TPESTO := _aPltOrig[_nPltOrig][ 8] // tipo de estoque do pallet de origem
			Z07->Z07_LOTCTL := _aPltOrig[_nPltOrig][ 9] // lote
			Z07->Z07_VLDLOT := _aPltOrig[_nPltOrig][10] // validade lote
			Z07->Z07_NUMSER := _aPltOrig[_nPltOrig][11] // número de série
			Z07->Z07_DTSERI := _aPltOrig[_nPltOrig][12] // data número serie
			Z07->(MsUnLock())
		Next _nPltOrig

		// atualiza os dados do browse
		sfSelDados(.T.)

	EndIf

	// reinicia variaveis
	_cCodProd   := Space(_nTamCodPrd)
	_cDscProd   := ""
	_cEtiqProd  := Space(Len(_cEtiqProd))
	_cEtqCodBar := Space(Len(_cEtqCodBar))
	_cPltCli    := Space(Len(_cPltCli))

	// foca no objeto cod produto
	_oGetCodProd:SetFocus()

	// se parametro de volume automatico ativo, já dispara "novo volume"
	If (_lAutoVol) .AND. (_lRet)
		_oBtnNvVol:Click()
	EndIf


Return( .T. )

// ** funcao para realizar a finalizacao/encerramento total do servico de conferencia da OS
Static Function sfFinalizaOS(mvTela, mvOk)

	// objetos locais
	local _oWndConFinal
	local _oPnlCfeFinCab1, _oPnlCfeFinCab2
	local _oBmpCfeFinConf, _oBmpCfeFechar
	local _oSayStatus, _oSayTotPB, _oSayTotCB, _oSayTotVL, _oSayNrPed
	local _oBrwFinaliza

	// variaveis temporarias
	Local _cQryConf  := ""
	Local _cQryPed   := ""
	Local cNewAlias  := GetNextAlias()
	Local nX         := 0
	Local _aConf     := {}

	// area atual
	Local aAreaAtu := GetArea()

	// estrutura do arquivo de trabalho e Browse
	Local aEstBrowse := {}
	Local aHeadBrowse := {}
	Local cMarca  := Z07->(GetMark())

	// controle de divergencias
	Local _lDiverg := .F.

	// informacoes do resumo
	local _nTotPesoB  := 0
	local _nTotCubag  := 0
	local _nTotVolume := 0
	local _nTotPalete := 0

	// controle de confirmacao da tela
	local _lOk := .F.

	// cores do browse
	local _aCorBrowse := {}

	private cArqTmp
	private _TRBPED := GetNextAlias()

	// confirmacao do processamento
	If ( ! U_FtYesNoMsg("Finalizar Montagem do pedido " + _cPedido + " ?" ))
		Return( .F. )
	EndIf

	// define cores do browse
	aAdd(_aCorBrowse, {"  Empty((_TRBPED)->IT_COR)","DISABLE"})
	aAdd(_aCorBrowse, {"! Empty((_TRBPED)->IT_COR)","ENABLE" })


	//---INICIO VALIDAÇÕES INICIAS ---

	// verifica se a OS está em um estado válido para finalização
	_cQryConf := "SELECT Z06_STATUS "
	_cQryConf += " FROM " + RetSqlTab("Z06") + " (nolock) "
	_cQryConf += " WHERE " + RetSqlCond("Z06")
	_cQryConf += "       AND Z06_NUMOS  = '" + _cNumOrdSrv + "'  "
	_cQryConf += "       AND Z06_SEQOS  = '" + _cSeqOrdSrv + "'  "

	If (U_FtQuery(_cQryConf) != 'EX')
		U_FtWmsMsg("O status da ordem de serviço " + Z06->Z06_NUMOS + " é inválido (" + Z06->Z06_STATUS + "). Verifique com o supervisor. A tela será fechada.","Erro")

		//se OS com status inválido, não deve selecionar outro pedido na window de pedido, então seta a variavel de controle
		//para fechar a tela no laço principal (1ª tela de seleção de pedidos)
		_lContConf := .F.

		//tela anterior de conferência  (2ª tela - conferência/montagem, já com pedido selecionado)
		//variável retorna TRUE pois é o que mantem a tela aberta
		mvOk := .T.

		//fecha a tela
		mvTela:End()

		Return( .F. )
	EndIf

	// verifica se tem mais usuarios na mesma contagem em conferencia
	_cQryConf := " SELECT COUNT(*) QTD_ITENS FROM " + RetSqlTab("Z07") + " (nolock) "
	// itens conferidos
	_cQryConf += " WHERE "+RetSqlCond("Z07")
	// numero da OS
	_cQryConf += " AND Z07_NUMOS   = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '" + _cSeqOrdSrv + "' "
	// nr contagem
	_cQryConf += " AND Z07_NRCONT  = '"+_cNrContagem+"' "
	// somente disponiveis
	_cQryConf += " AND Z07_STATUS = 'C' "
	// somente do pedido selecionado anteriormente
	_cQryConf += " AND Z07_PEDIDO = '"+_cPedido+"' "

	// executa a query de verificacao
	If (U_FtQuery(_cQryConf) > 0)
		// mensagem
		U_FtWmsMsg("Existem Operadores com conferência/montagem em aberto. Favor verificar antes de prosseguir.", "Finalizar")
		// retorno
		Return(.F.)
	EndIf

	// verifica se ha algum palete nao finalizado
	_cQryConf := " SELECT COUNT(*) QTD_ITENS FROM "+RetSqlTab("Z07")+" (nolock) "
	_cQryConf += " WHERE "+RetSqlCond("Z07")
	_cQryConf += " AND Z07_NUMOS   = '" + _cNumOrdSrv + "' AND Z07_SEQOS = '" + _cSeqOrdSrv + "' "
	_cQryConf += " AND Z07_NRCONT  = '" + _cNrContagem + "' "
	_cQryConf += " AND Z07_STATUS  = 'C' "                 // somente disponiveis
	_cQryConf += " AND Z07_PEDIDO = '" + _cPedido + "' "   // somente do pedido selecionado anteriormente

	If (U_FtQuery(_cQryConf) > 0)
		U_FtWmsMsg("Há paletes com conferência não finalizada!", "Finalizar")
		Return( .F. )
	EndIf

	// verifica se houve alguma conferência para o pedido/os
	_cQryConf := "SELECT COUNT(Z07_ETQVOL) "
	_cQryConf += " FROM " + RetSqlTab("Z07") + " (nolock) "
	_cQryConf += " WHERE " + RetSqlCond("Z07")
	_cQryConf += "       AND Z07_NUMOS  = '" + _cNumOrdSrv + "'  "
	_cQryConf += "       AND Z07_SEQOS  = '" + _cSeqOrdSrv + "'  "
	_cQryConf += "       AND Z07_PEDIDO = '" + _cPedido +    "'  "
	_cQryConf += "	     AND Z07_STATUS = 'D'         "

	If (U_FtQuery(_cQryConf) == 0)
		U_FtWmsMsg("Nenhum palete montado/conferido para o pedido " + _cPedido + ".","ATENCAO")
		Return( .F. )
	EndIf


	//---FIM VALIDAÇÕES INICIAS ---

	// fecha o alias
	If ( Select(cNewAlias) != 0 )
		dbSelectArea(cNewAlias)
		dbCloseArea()
	EndIf

	//pega as informações do pedido de venda
	_cQryPed := "SELECT 'DI'          IT_OK,      "
	_cQryPed += "       '  '          IT_COR,     "
	_cQryPed += "       C6_NUM,                   "
	_cQryPed += "	    C6_PRODUTO,               "
	_cQryPed += "	    SB1.B1_DESC,              "
	_cQryPed += "	    SB1.B1_UM,                "
	_cQryPed += "       Sum(C6_QTDVEN) QTD,       "
	_cQryPed += "       C6_LOTECTL,               "
	_cQryPed += "       0 QTD_PALETE,             "
	_cQryPed += "	    0 QTD_VOLUME,             "
	_cQryPed += "	    0 Z07_CONF                "
	_cQryPed += " FROM " + RetSqlTab("SC6") + " (nolock) "
	_cQryPed += " LEFT JOIN " + RetSqlTab("SB1") + " (nolock) "
	_cQryPed += "     ON SB1.B1_COD = SC6.C6_PRODUTO
	_cQryPed += "        AND " + RetSqlCond("SB1")
	_cQryPed += " WHERE " + RetSqlCond("SC6")
	_cQryPed += "     AND C6_NUM = '" + _cPedido + "'  "
	_cQryPed += " GROUP  BY C6_PRODUTO,           "
	_cQryPed += "           C6_LOTECTL,           "
	_cQryPed += "           C6_NUM,               "
	_cQryPed += "           B1_DESC,              "
	_cQryPed += "           B1_UM                 "

	memowrit("c:\QUERY\twmsa024_sfFinalizaOS_Pedido.txt",_cQryPed)

	cNewAlias := GetNextAlias()
	dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQryPed),cNewAlias,.F.,.T.)

	// pega a estrutura do select dos pedidos para compor a TRB
	aEstBrowse := (cNewAlias)->(dbStruct())

	// fecha o trb
	If ( Select(_TRBPED) <> 0 )
		dbSelectArea(_TRBPED)
		dbCloseArea()
	EndIf

	// criar um arquivo de trabalho
	cArqTmp := FWTemporaryTable():New( _TRBPED )
	cArqTmp:SetFields( aEstBrowse )
	cArqTmp:AddIndex("01", {"C6_PRODUTO", "C6_LOTECTL"} )
	cArqTmp:Create()

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQryPed, aEstBrowse, _TRBPED)

	// fecha a query
	dbSelectArea(cNewAlias)
	dbCloseArea()

	//consulta tudo que foi conferido para esta OS e pedido
	_cQryConf := "SELECT Z07_NUMOS,                                                "
	_cQryConf += "       Z07_SEQOS,                                                "
	_cQryConf += "       Z07_PRODUT,                                               "
	_cQryConf += "       Z07_LOTCTL,                                               "
	_cQryConf += "       Sum(Z07_QUANT)                           AS Z07_QUANT,    "
	_cQryConf += "       (SELECT Isnull(Count(DISTINCT Z07_ETQVOL), 0)             "
	_cQryConf += "        FROM   " + RetSqlTab("Z07") + " (nolock) "
	_cQryConf += "        WHERE  " + RetSqlCond("Z07")
	_cQryConf += "               AND Z07_NUMOS = CONF.Z07_NUMOS                    "
	_cQryConf += "               AND Z07_SEQOS = CONF.Z07_SEQOS                    "
	_cQryConf += "               AND Z07_PEDIDO = CONF.Z07_PEDIDO) AS 'QTD_VOLUME',"
	_cQryConf += "       (SELECT Isnull(Count(DISTINCT Z07_PALLET), 0)             "
	_cQryConf += "        FROM   " + RetSqlTab("Z07") + " (nolock) "
	_cQryConf += "        WHERE  " + RetSqlCond("Z07")
	_cQryConf += "               AND Z07_NUMOS = CONF.Z07_NUMOS                    "
	_cQryConf += "               AND Z07_SEQOS = CONF.Z07_SEQOS                    "
	_cQryConf += "               AND Z07_PEDIDO = CONF.Z07_PEDIDO) AS 'QTD_PALETE' "
	_cQryConf += "FROM  " + RetSqlName("Z07") + " CONF (nolock)  "
	_cQryConf += "WHERE  CONF.D_E_L_E_T_ = ''                                      "
	_cQryConf += "       AND CONF.Z07_FILIAL = '" + xFilial("Z07") + " '           "
	_cQryConf += "       AND CONF.Z07_NUMOS = '" + _cNumOrdSrv + "'                "
	_cQryConf += "       AND CONF.Z07_SEQOS = '" + _cSeqOrdSrv + "'                "
	_cQryConf += "       AND CONF.Z07_PEDIDO = '" + _cPedido + "'                  "
	_cQryConf += "       AND CONF.Z07_STATUS = 'D'                                 "
	_cQryConf += "GROUP  BY Z07_NUMOS,                                             "
	_cQryConf += "          Z07_SEQOS,                                             "
	_cQryConf += "          Z07_PRODUT,                                            "
	_cQryConf += "          Z07_LOTCTL,                                            "
	_cQryConf += "          Z07_PEDIDO                                             "

	memowrit("c:\QUERY\twmsa024_sfFinalizaOS_Conf.txt",_cQryConf)

	//joga a consulta de tudo que foi conferido em array
	_aConf := U_SqlToVet(_cQryConf)

	/*
	Composição do array _aConf

	[1] - Z07_NUMOS
	[2] - Z07_SEQ0S
	[3] - Z07_PRODUT
	[4] - Z07_LOTCTL
	[5] - Z07_QUANT (SOMADO)
	[6] - QTD_VOLUME
	[7] - QTD_PALETE

	*/

	(_TRBPED)->(dbSelectArea(_TRBPED))
	(_TRBPED)->(dbGoTop())

	//percorre o array comparando o que foi conferido com o previsto no pedido de venda
	For nX := 1 To Len(_aConf)
		If ( (_TRBPED)->( DbSeek(_aConf[nX][3] + _aConf[nX][4])) )   		//se achou produto e lote
			// atualiza o TRB com os dados do produto encontrado
			(_TRBPED)->(RecLock(_TRBPED, .F. ))

			(_TRBPED)->Z07_CONF    := _aConf[nx][5]
			(_TRBPED)->QTD_VOLUME  := _aConf[nx][6]
			(_TRBPED)->QTD_PALETE  := _aConf[nx][7]

			(_TRBPED)->IT_OK  := IIf( ((_TRBPED)->Z07_CONF != (_TRBPED)->QTD), cMarca, Space(2) )
			(_TRBPED)->IT_COR := IIf( ((_TRBPED)->Z07_CONF != (_TRBPED)->QTD), Space(2), cMarca )

			(_TRBPED)->(MsUnLock())
		Else 		//produto ou lote não esperado, vou inserir no TRB para mostrar
			(_TRBPED)->(RecLock(_TRBPED, .T. ))

			//preenche TRB com uma nova linha do produto não esperado
			(_TRBPED)->IT_OK       := cMarca
			(_TRBPED)->IT_COR      := Space(2)         //em branco, bola vermelha "disable" na legenda
			(_TRBPED)->C6_NUM      := "ERRADO"
			(_TRBPED)->C6_PRODUTO  := _aConf[nx][3]
			(_TRBPED)->B1_DESC     := AllTrim( Posicione( "SB1", 1, xFilial("SB1") + _aConf[nx][3], "B1_DESC" ) )
			(_TRBPED)->QTD         := 0                //qtd no pedido de venda. No caso, o produto não é esperado, então é 0
			(_TRBPED)->C6_LOTECTL  := _aConf[nx][4]
			(_TRBPED)->QTD_PALETE  := _aConf[nx][7]
			(_TRBPED)->QTD_VOLUME  := _aConf[nx][6]
			(_TRBPED)->Z07_CONF    := _aConf[nx][5]

			_lDiverg := .T.       //produto não esperado para o pedido, sempre marca a finalização como divergente

			(_TRBPED)->(MsUnLock())
		EndIf

		// atualiza variaveis do resumo
		_nTotVolume := IIf(_lCtrVolume, (_TRBPED)->QTD_VOLUME, _nTotVolume += (_TRBPED)->Z07_QUANT)
		_nTotPalete += (_TRBPED)->QTD_PALETE

	Next nX

	//verifica divergências
	(_TRBPED)->(dbGoTop())
	(_TRBPED)->(DbEval ({|| IIf( (!Empty((_TRBPED)->IT_OK) ), _lDiverg := .T. , Nil )  }))

	//volta para o primeiro para exibir a grid corretamente
	(_TRBPED)->(dbGoTop())

	// atualiza variaveis do resumo
	_nTotCubag := sfRetCubEmb()

	// inclui detalhes e titulos dos campos do browse
	aAdd(aHeadBrowse,{"IT_OK"       ,, "  "          , "@!"        })
	aAdd(aHeadBrowse,{"C6_PRODUTO"  ,, "Cód. Produto", "@!"        })
	aAdd(aHeadBrowse,{"B1_DESC"     ,, "Descrição"   , "@!"        })
	aAdd(aHeadBrowse,{"B1_UM"       ,, "Und.Med."    , "@!"        })
	aAdd(aHeadBrowse,{"QTD"         ,, "Qtd.PV"      , _cMaskQuant })
	aAdd(aHeadBrowse,{"Z07_CONF"    ,, "Qtd.Conf."   , _cMaskQuant })
	aAdd(aHeadBrowse,{"QTD_VOLUME"  ,, "Qtd.Volume"  , _cMaskQuant })
	aAdd(aHeadBrowse,{"QTD_PALETE"  ,, "Qtd.Palete"  , _cMaskQuant })

	// monta a tela com os detalhes da finalizacao total da OS
	_oWndConFinal := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Mont.Vol/Pedido: "+_cPedido,,,.F.,,,,,,.T.,,,.T. )
	_oWndConFinal:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlCfeFinCab1 := TPanel():New(000,000,nil,_oWndConFinal,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlCfeFinCab1:Align:= CONTROL_ALIGN_TOP

	If ( ! _lDiverg)
		_oBmpCfeFinConf := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| MsgRun("Aguarde. Selecionando Dados...",,{|| _lOk := sfFinServico(@_oWndConFinal, _nTotVolume) }) },_oPnlCfeFinCab,"Finaliza a Conferência",,.T. )
		_oBmpCfeFinConf:Align := CONTROL_ALIGN_LEFT
	EndIf
	// -- BOTAO PARA FECHAR A TELA
	_oBmpCfeFechar := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| _oWndConFinal:End() },_oPnlCfeFinCab,"Sair",,.T. )
	_oBmpCfeFechar:Align := CONTROL_ALIGN_RIGHT

	// resumo da operacao
	_oPnlCfeFinCab2 := TPanel():New(000,000,nil,_oWndConFinal,,.F.,.F.,,,048,048,.T.,.F.)
	_oPnlCfeFinCab2:Align:= CONTROL_ALIGN_TOP

	// status conferencia
	_oSayStatus := TSay():New(003,004,{||"STATUS: " + IIf(_lDiverg, "DIVERGÊNCIAS", "OK") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T., IIf(_lDiverg, CLR_HRED, CLR_GREEN) )
	// total PESO BRUTO
	_oSayTotPB  := TSay():New(010,004,{||"PESO BRUTO: "+Transf(_nTotPesoB,"@E 999,999.999") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)
	// total CUBAGEM
	_oSayTotCB  := TSay():New(017,004,{||"CUBAGEM: "+Transf(_nTotCubag,"@E 999,999.999") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)
	// total VOLUMES
	_oSayTotVL  := TSay():New(024,004,{||"VOLUMES: "+Transf(_nTotVolume,"@E 999,999,999") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)
	// Nr Pedido
	_oSayNrPed  := TSay():New(038,004,{||"PEDIDO: "+_cPedido+"/"+_cPedCliente },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)

	// browse com a listagem dos produtos conferidos
	_oBrwFinaliza := MsSelect():New( _TRBPED,"IT_OK",,aHeadBrowse,,cMarca,{15,1,183,373},,,,,_aCorBrowse)
	_oBrwFinaliza:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oWndConFinal

	// atualiza variaveis da tela de conferencia
	If (_lOk)
		//para fechar a tela no laço principal (1ª tela de seleção de pedidos)
		_lContConf := .F.

		//se cliente Danuri, envia EDI por FTP automaticamente
		If (_cCodCliFor == "000547")
			U_TWMSA026( .T. , .T.)
		EndIf

		//fecha telas abertas e volta para menu principal do coletor
		mvOk := .T.
		mvTela:End()
	EndIf

	// fecha arquivo de trabalho
	cArqTmp:Delete()

	// restaura area inicial
	RestArea(aAreaAtu)

Return(.T.)

// ** funcao para estorno do palete
Static Function sfEstornoVol(mvIdVolume)
	// query
	local _cQryZ07, _cUpdZ16
	// variaveis temporarias
	local _aTmpRecno := {}
	local _nX
	// variavel de retorno
	local _lRet := .F.

	// valida id do palete
	If ( Empty(mvIdVolume) )
		// mensagem
		U_FtWmsMsg("Não há palete para estorno!","ATENCAO")
		// retorno
		Return(_lRet)
	EndIf

	// mensagem para confirmar processo
	If ( ! U_FtYesNoMsg("Confirmar estorno da etiqueta "+Transf(mvIdVolume,_cMskEtiq)+"?"))
		Return(_lRet)
	EndIf

	// monta SQL para estornar o palete
	_cQryZ07 := " SELECT Z07.R_E_C_N_O_ Z07RECNO, ISNULL(Z16.R_E_C_N_O_,0) Z16RECNO "
	// itens em conferencia
	_cQryZ07 += " FROM " + RetSqlTab("Z07") + " (nolock) "
	// composicao do palete
	_cQryZ07 += " LEFT JOIN " + RetSqlTab("Z16") + " (nolock)  ON " + RetSqlCond("Z16") + " AND Z16_ETQPAL = Z07_PALLET "
	_cQryZ07 += "      AND Z16_ETQVOL = Z07_ETQVOL AND Z16_ETQPRD = Z07_ETQPRD AND Z16_CODBAR = Z07_CODBAR "
	_cQryZ07 += "      AND Z16_CODPRO = Z07_PRODUT AND Z16_ENDATU = Z07_ENDATU "
	_cQryZ07 += "      AND Z16_LOTCTL = Z07_LOTCTL "

	// filtro padrao
	_cQryZ07 += " WHERE " + RetSqlCond("Z07")
	// filtro por OS
	_cQryZ07 += " AND Z07_NUMOS  = '" + _cNumOrdSrv + "' AND Z07_SEQOS = '" + _cSeqOrdSrv + "' "
	// cliente e loja
	_cQryZ07 += " AND Z07_CLIENT = '" + _cCodCliFor + "'  AND Z07_LOJA  = '" + _cLojCliFor + "' "
	// id do volume
	_cQryZ07 += " AND Z07_ETQVOL = '" + mvIdVolume + "' "
	// status C=EM CONFERENCIA e D=DISPONIVEL
	_cQryZ07 += " AND Z07_STATUS IN ('C','D') "
	// somente do pedido selecionado anteriormente
	_cQryZ07 += " AND Z07_PEDIDO = '" + _cPedido + "' "

	// alimenta o vetor
	_aTmpRecno := U_SqlToVet(_cQryZ07)

	memowrit("C:\query\twmsa024_sfEstornoVol.txt",_cQryZ07)

	// inicia transacao
	BEGIN TRANSACTION

		// varre todos os recno
		For _nX := 1 to Len(_aTmpRecno)

			// posiciona no registro real
			dbSelectArea("Z07")
			Z07->(dbGoTo( _aTmpRecno[_nX][1] ))

			// atualiza o saldo do palete de origem
			If (Z07->Z07_STATUS == "D") // D-Disponivel (palete montado e saldo atualizado)

				// atualiza o saldo do palete de origem
				_cUpdZ16 := " UPDATE " + RetSqlName("Z16") + " SET Z16_SALDO = Z16_SALDO + " + AllTrim(Str(Z07->Z07_QUANT))
				// filtro padrao
				_cUpdZ16 += " WHERE Z16_FILIAL = '" + xFilial("Z16") + "' AND D_E_L_E_T_ = ' ' "
				// id do palete ORIGEM
				_cUpdZ16 += " AND Z16_ETQPAL = '" + Z07->Z07_PLTORI + "' "
				// etiqueta produto
				_cUpdZ16 += " AND Z16_ETQPRD = '" + Z07->Z07_ETQPRD + "' "
				// codigo do produto
				_cUpdZ16 += " AND Z16_CODPRO = '" + Z07->Z07_PRODUT + "' "
				// etiqueta de volume ORIGEM
				_cUpdZ16 += " AND Z16_ETQVOL = '" + Z07->Z07_VOLORI + "' "
				// lote
				_cUpdZ16 += " AND Z16_LOTCTL = '" + Z07->Z07_LOTCTL + "' "

				// executa o update
				If (TcSQLExec(_cUpdZ16) < 0)
					// rollback na transacao
					U_FtWmsMsg("*** ERRO NA ATUALIZACAO DO SALDO POR PALETE (sfEstornoVol) ***"+CRLF+CRLF+TCSQLError(),"ATENCAO")
					_lRet := .F.
					DisarmTransaction()
					Break
				EndIf

			EndIf

			// exclui o registro da conferencia
			RecLock("Z07")
			Z07->(dbDelete())
			Z07->(MsUnLock())

			// posiciona no registro real - estrutura do palete
			If (_aTmpRecno[_nX][2] > 0)

				// tabela de composicao do palete
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

		// finaliza transacao
	END TRANSACTION

	If (_lRet)
		// mensagem
		U_FtWmsMsg("Estorno realizado com sucesso!","ATENCAO")
		// atualiza os dados do browse
		sfSelDados(.T.)

	EndIf

Return(_lRet)

// ** funcao que apresenta os detalhes da montagem
Static Function sfDetConfer()
	// objetos
	local _oWndMontDet
	local _oPnlConfDet
	local _oBrwConsDet
	local _aHeadDet := {}
	local _aColsDet := {}
	local _cQuery
	// quantidade total
	local _nQtdTot   := 0
	local _nQtdSegum := 0
	// total de paletes
	local _nTotPalete := 0
	// botão de estorno
	local _oBmpEstorno
	// botão de sair
	local _oBmpConsDetSair

	// monta a query
	_cQuery := " SELECT CASE WHEN Z07_STATUS = 'C' THEN '  ' ELSE 'OK' END Z07_STATUS, B1_COD, B1_DESC, Z07_ETQVOL, SUM(Z07_QUANT) Z07_QUANT, SUM(Z07_QTSEGU) Z07_QTSEGU, Z07_LOTCTL, '.F.' IT_DEL "
	// itens conferidos
	_cQuery += " FROM "+RetSqlTab("Z07")+" (nolock) "
	// cad. produtos
	_cQuery += " INNER JOIN "+RetSqlTab("SB1")+" (nolock)  ON "+RetSqlCond("SB1")+" AND B1_COD = Z07_PRODUT "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z07")
	// ordem de servico
	_cQuery += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	// cliente
	_cQuery += " AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
	// pedido
	_cQuery += " AND Z07_PEDIDO = '"+_cPedido+"' "
	// agrupamento dos dados
	_cQuery += " GROUP BY Z07_STATUS, Z07_ETQVOL, B1_COD, B1_DESC, Z07_LOTCTL "
	// ordem dos dados
	_cQuery += " ORDER BY Z07_ETQVOL "

	memowrit("C:\query\TWSMA024_sfDetConfer.txt",_cQuery)

	// atualiza o vetor do browse
	_aColsDet := U_SqlToVet(_cQuery)

	// calcula a quantidade total
	aEval(_aColsDet,{|x| _nQtdTot += x[5], _nQtdSegum += x[6], _nTotPalete ++ })

	// adiciona a linha com o total
	aAdd(_aColsDet,{"", "", "TOTAL"    , "",_nQtdTot   , _nQtdSegum, "", .F.})
	aAdd(_aColsDet,{"", "", "TOTAL PLT", "",_nTotPalete, 0         , "", .F.})

	// define o header
	aAdd(_aHeadDet,{"Sts"           , "Z07_STATUS", ""                          , 2                      , 0                      , Nil, Nil, "C", Nil, "R",,, ".F."})
	aAdd(_aHeadDet,{"Produto"       , "B1_COD"    , PesqPict("SB1","B1_COD")    , TamSx3("B1_COD")[1]    , 0                      , Nil, Nil, "C", Nil, "R",,, ".F."})
	aAdd(_aHeadDet,{"Desc Prod"     , "B1_DESC"   , PesqPict("SB1","B1_DESC")   , TamSx3("B1_DESC")[1]   , 0                      , Nil, Nil, "C", Nil, "R",,, ".F."})
	aAdd(_aHeadDet,{"Etq.Agrupadora", "Z07_ETQVOL", _cMskEtiq                   , TamSx3("Z07_ETQVOL")[1], 0                      , Nil, Nil, "C", Nil, "R",,, ".F."})
	aAdd(_aHeadDet,{"Quant"         , "Z07_QUANT" , _cMaskQuant                 , TamSx3("Z07_QUANT")[1] , TamSx3("Z07_QUANT")[2] , Nil, Nil, "N", Nil, "R",,, ".F."})
	aAdd(_aHeadDet,{"Qtd Seg UM"    , "Z07_QTSEGU", _cMaskQuant                 , TamSx3("Z07_QTSEGU")[1], TamSx3("Z07_QTSEGU")[2], Nil, Nil, "N", Nil, "R",,, ".F."})
	aAdd(_aHeadDet,{"Lote"          , "Z07_LOTCTL", PesqPict("Z07","Z07_LOTCTL"), TamSx3("Z07_LOTCTL")[1], 0                      , Nil, Nil, "C", Nil, "R",,, ".F."})

	// monta o dialogo do monitor
	_oWndMontDet := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Detalhes",,,.F.,,,,,,.T.,,,.T. )
	_oWndMontDet:lEscClose := .F.

	// cria o panel do cabecalho - botoes
	_oPnlConfDet := TPanel():New(000,000,nil,_oWndMontDet,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlConfDet:Align:= CONTROL_ALIGN_TOP

	// -- BOTAO DE ESTORNO
	_oBmpEstorno := TBtnBmp2():New(000,000,030,022,"ESTOMOVI",,,,{|| IIf( sfEstornoVol(_oBrwConsDet:aCols[_oBrwConsDet:nAt][4]), _oWndMontDet:End(), Nil) },_oPnlConfDet,"Estornar conferência",,.T.)
	_oBmpEstorno:Align := CONTROL_ALIGN_LEFT
	// -- BOTAO DE SAIDA
	_oBmpConsDetSair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _oWndMontDet:End() },_oPnlConfDet,"Sair",,.T.)
	_oBmpConsDetSair:Align := CONTROL_ALIGN_RIGHT

	// monta o browse com os motivos de interrupcoes
	_oBrwConsDet := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDet),'AllwaysTrue()','','AllwaysTrue()',_oWndMontDet,_aHeadDet,_aColsDet)
	_oBrwConsDet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa o dialogo
	_oWndMontDet:Activate(,,,.F.,,,)

Return(.T.)

// ** função que retorna array que contem tipos de estoque
Static Function sfRetTpEmbala(mvCodCli)

	// query para consulta
	local _cQuery := ""
	// array pra retorno
	local _aTpEmbala := {}

	// consulto os tipos de estoque disponíveis na tabela
	_cQuery := " SELECT Z31_CODIGO +'-'+Z31_DESCRI TPEMBALA FROM "+RetSqlTab("Z31")+" (nolock) "
	_cQuery += " WHERE "+RetSqlCond("Z31")
	_cQuery += " AND Z31_SIGLA IN (SELECT DISTINCT A1_SIGLA FROM "+RetSqlTab("SA1")+" (nolock)  WHERE "+RetSqlCond("SA1")+" AND A1_COD = '"+mvCodCli+"') "

	// jogo os dados pro array
	_aTpEmbala := U_SqlToVet(_cQuery)

Return (_aTpEmbala)

// ** funcao que apresenta os detalhes dos itens do pedido
Static Function sfDetPedido()
	// objetos
	local _oWndDetPed
	local _oPnlDetPed
	local _oBmpSair
	local _oBrwDetPed
	local _aHeadDet := {}
	local _aColsDet := {}
	local _cQuery
	// quantidade total
	local _nQtdTot := 0
	// total de paletes
	local _nTotPalete := 0

	// monta a query
	_cQuery := "SELECT "
	_cQuery += "C6_PRODUTO, "
	_cQuery += "B1_DESC, "
	_cQuery += "B1_UM, "
	// quantidade solicitada
	_cQuery += "SUM(C6_QTDVEN) C6_QTDVEN, "
	//lote
	_cQuery += "C6_LOTECTL, "
	// controle de item deletado
	_cQuery += "'.F.' IT_DEL "

	// itens do pedido venda
	_cQuery += "FROM "+RetSqlName("SC6")+" SC6 (nolock)  "

	// cad. produtos
	_cQuery += "LEFT JOIN "+RetSqlName("SB1")+" SB1 (nolock)  ON "+RetSqlCond("SB1")+" AND B1_COD = C6_PRODUTO "

	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SC6")+" "

	// filtra numero do pedido
	_cQuery += "AND C6_NUM = '"+_cPedido+"' "

	// agrupa dados
	_cQuery += "GROUP BY C6_PRODUTO, "
	_cQuery += "B1_DESC, "
	_cQuery += "B1_UM, "
	_cQuery += "C6_LOTECTL "

	// ordem dos dados
	_cQuery += "ORDER BY C6_PRODUTO "

	memowrit("C:\query\TWSMA024_sfDetPedido.txt",_cQuery)

	// atualiza o vetor do browse
	_aColsDet := U_SqlToVet(_cQuery)

	// calcula a quantidade total
	aEval(_aColsDet,{|x| _nQtdTot += x[4] , _nTotPalete ++ })

	// adiciona a linha com o total
	aAdd(_aColsDet,{"", "TOTAL", "", _nQtdTot, "", .F.})

	// define o header
	aAdd(_aHeadDet,{"Produto"  , "C6_PRODUTO", ""                          , TamSx3("C6_PRODUTO")[1], 0                     , Nil, Nil, "C", Nil, "R",,, ".F." })
	aAdd(_aHeadDet,{"Desc Prod", "B1_DESC"   , ""                          , TamSx3("B1_DESC")[1]   , 0                     , Nil, Nil, "C", Nil, "R",,, ".F." })
	aAdd(_aHeadDet,{"UM"       , "B1_UM"     , ""                          , TamSx3("B1_UM")[1]     , 0                     , Nil, Nil, "C", Nil, "R",,, ".F." })
	aAdd(_aHeadDet,{"Quant"    , "C6_QTDVEN" , _cMaskQuant                 , TamSx3("C6_QTDVEN")[1] , TamSx3("C6_QTDVEN")[2], Nil, Nil, "N", Nil, "R",,, ".F." })
	aAdd(_aHeadDet,{"Lote"     , "C6_LOTECTL", PesqPict("SC6","C6_LOTECTL"), TamSx3("C6_LOTECTL")[1], 0                     , Nil, Nil, "C", Nil, "R",,, ".F." })

	// monta o dialogo dos detalhes do pedido
	_oWndDetPed := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Detalhes do Pedido",,,.F.,,,,,,.T.,,,.T. )
	_oWndDetPed:lEscClose := .F.

	// cria o panel do cabecalho - botoes
	_oPnlDetPed := TPanel():New(000,000,nil,_oWndDetPed,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlDetPed:Align:= CONTROL_ALIGN_TOP

	// -- BOTAO DE SAIDA
	_oBmpSair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _oWndDetPed:End() },_oPnlDetPed,"Sair",,.T.)
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// monta o browse com os detalhes do pedido de venda
	_oBrwDetPed := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDet),'AllwaysTrue()','','AllwaysTrue()',_oWndDetPed,_aHeadDet,_aColsDet)
	_oBrwDetPed:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa o dialogo
	_oWndDetPed:Activate(,,,.F.,,,)

Return(.T.)

// ** funcao que encerra o servico de montagem de volumes
Static Function sfFinServico(mvWndConFinal, mvTotVolume)
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z05","Z06","SC5"})

	// variavel de retorno
	local _lRet := .T.

	// finaliza OS somente quando todos os pedidos estiverem com os volumes montados
	local _lFinalOS := .F.

	// query
	local _cQuery
	local _cUpdZ07

	// etiquetas de volume
	local _aEtqVolume := {}
	local _nEtqVolume

	// imprime etiqueta de packing logo apos finalizar a montagem de volumes
	local _lImpEtqPacking := U_FtWmsParam("WMS_EXPEDICAO_ETIQUETA_PACKING_IMPRESSAO_COLETOR", "L", .F., .F. , "", _cCodCliFor, _cLojCliFor, Nil, Nil)

	// envia e-mail para o cliente avisando que a montagem foi finalizada
	local _lEmailFim := U_FtWmsParam("WMS_EXPEDICAO_EMAIL_FIM_MONTAGEM_VOLUMES", "L", .F., .F. , "", _cCodCliFor, _cLojCliFor, Nil, Nil)

	// inicia transacao
	BEGIN TRANSACTION

		// finaliza os itens conferidos
		_cUpdZ07 := "UPDATE "+RetSqlName("Z07")+" "
		// status F=Finalizado
		_cUpdZ07 += "SET Z07_STATUS = 'F' "
		// filtro padrao
		_cUpdZ07 += "WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
		// filtro da OS especifica
		_cUpdZ07 += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		// status D=Em Conferência
		_cUpdZ07 += "AND Z07_STATUS = 'D' "
		// somente do pedido selecionado anteriormente
		_cUpdZ07 += "AND Z07_PEDIDO = '"+_cPedido+"' "

		// executa o update
		TcSQLExec(_cUpdZ07)

		// posiciona no pedido
		dbSelectArea("SC5")
		SC5->(dbSetOrder(1)) // 1-C5_FILIAL, C5_NUM
		SC5->(dbSeek( xFilial("SC5")+_cPedido ))

		// atualiza status de conferencia/montagem de volumes
		RecLock("SC5")
		SC5->C5_ZMNTVOL := "S"
		SC5->C5_VOLUME1 := mvTotVolume
		SC5->(MsUnLock())

		// liberacao do pedido de venda
		sfLibPedVen(.F., SC5->C5_NUM, _cDocaSrv, _cArmzServ)

		// atualiza informacoes Volume De->Ate no cadastro de Etiquetadas (usado para impressao)
		_cQuery := "SELECT DISTINCT Z07_ETQVOL "
		// tabela de itens conferidos
		_cQuery += "FROM "+RetSqlName('Z07')+" Z07 (nolock)  "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("Z07")+" "
		// numero e seq da OS
		_cQuery += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		// cliente e loja
		_cQuery += "AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
		// nr do pedido
		_cQuery += "AND Z07_PEDIDO = '"+_cPedido+"' "
		// somente que nao F-Finalizado
		_cQuery += "AND Z07_STATUS = 'F' "
		// ordem dos dados
		_cQuery += "ORDER BY Z07_ETQVOL "

		// atualiza vetor com o codigo das etiquetas
		_aEtqVolume := U_SqlToVet(_cQuery)

		// varre todas as etiquetas para atualizar os dados
		For _nEtqVolume := 1 to Len(_aEtqVolume)

			// pesquisa etiqueta no cadastro
			dbSelectARea("Z11")
			Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
			If Z11->(dbSeek( xFilial("Z11")+_aEtqVolume[_nEtqVolume] ))
				RecLock("Z11")
				Z11->Z11_QTD1 := _nEtqVolume
				Z11->Z11_QTD2 := Len(_aEtqVolume)
				Z11->(MsUnLock())
			EndIf

		Next _nEtqVolume

		// finaliza OS somente quando todos os pedidos estiverem com os volumes montados
		_cQuery := " SELECT COUNT(*) QTD_PEND "
		// pedidos de venda
		_cQuery += " FROM " + RetSqlTab("SC5") + " (nolock) "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("SC5")
		// cliente, loja e tipo de operacao
		_cQuery += " AND C5_CLIENTE = '" + _cCodCliFor + "' AND C5_LOJACLI = '" + _cLojCliFor + "' AND C5_TIPOOPE = 'P' "
		// numero da carga/agrupadora
		If ( ! Empty(_cNrCarga) )
			_cQuery += " AND C5_ZCARGA = '" + _cNrCarga + "' "
		EndIf
		// filtro por onda de separacao
		If ( ! Empty(_cNrOndSep) )
			_cQuery += " AND C5_ZONDSEP = '" + _cNrOndSep + "' "
		EndIf
		// status da montagem de volume
		_cQuery += " AND C5_ZMNTVOL <> 'S' "

		MEMOWRIT("c:\query\twmsa024_sfFinServico_ped_pend.txt",_cQuery)

		// executa a query
		_lFinalOS := (U_FtQuery(_cQuery) == 0)

		// se tudo ok
		If (_lFinalOS)

			// atualiza o status do servico para FI-FINALIZADO
			U_FtWmsSta(_cCodStatus,;
			"FI"        ,;
			_cNumOrdSrv ,;
			_cSeqOrdSrv  )

			// envia mensagem de e-mail
			If ( _lEmailFim )
				sfMailRes()
			EndiF

		EndIf

		// finaliza transacao
	END TRANSACTION

	// imprimir etiquetas de packing
	If (_lImpEtqPacking) .And. (U_FtYesNoMsg("Confirmar impressão de etiqueta de packing?"))
		// funcao para impressao de etiquetas de packing
		U_WMSR016A( Nil, "  ", "ZZZ", _cPedido, _cNrCarga, "  ", "  ", "  ", _cCodCliFor, _cNrOndSep, Nil)
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aArea)

	// fecha tela do resumo
	If (_lRet)
		mvWndConFinal:End()
	EndIf

Return(_lRet)

// ** funcao que calcula a cubagem por embalagem
Static Function sfRetCubEmb()
	// variavel de retorno
	local _nRet := 0
	// query
	local _cQuery
	// dados temporarios
	local _aDadosCub := {}

	// monta a query para buscar os volumes por pedido
	_cQuery := "SELECT Z07_ETQVOL, Z31_CUBAGE "

	// itens conferidos/volumes montados
	_cQuery += "FROM "+RetSqlName("Z07")+" Z07 (nolock)  "

	// cad. clientes
	_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 (nolock)  ON "+RetSqlCond("SA1")+" AND A1_COD = Z07_CLIENT AND A1_LOJA = Z07_LOJA "

	// cad. embalagens
	_cQuery += " INNER JOIN "+RetSqlName("Z31")+" Z31 (nolock)  ON "+RetSqlCond("Z31")+" AND Z31_CODIGO = Z07_EMBALA AND Z31_SIGLA = A1_SIGLA "

	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z07")+" "
	// numero e seq da OS
	_cQuery += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	// cliente e loja
	_cQuery += "AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
	// nr do pedido
	_cQuery += "AND Z07_PEDIDO = '"+_cPedido+"' "

	// agrupa dados
	_cQuery += " GROUP BY Z07_ETQVOL, Z31_CUBAGE "

	memowrit("c:\query\twmsa024_sfRetCubEmb.txt", _cQuery)

	// atualiza vetor
	_aDadosCub := U_SqlToVet(_cQuery)

	// calcula a quantidade total de palete
	aEval(_aDadosCub,{|x| _nRet += x[2] })

Return(_nRet)

// ** funcao para liberacao e analise de estorno do pedido de venda
Static Function sfLibPedVen(mvEstorno, mvPedido, mvEndDest, mvArmDest)

	// variavel de retorno
	local _lRet := .T.

	// query dos itens do pedido
	local _cQrySC6
	local _aRecnoLib := {}
	local _nRecnoLib := 0

	// pedidos liberados
	local _aPedLiber := {}

	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaSC5 := SC5->(GetArea())
	local _aAreaSC6 := SC6->(GetArea())
	local _aAreaSC9 := SC9->(GetArea())

	// monta a query para buscar os itens dos pedidos de venda da carga
	_cQrySC6 := "SELECT SC6.R_E_C_N_O_ SC6RECNO, SC9.R_E_C_N_O_ SC9RECNO "
	// itens liberados
	_cQrySC6 += "FROM "+RetSqlName("SC9")+" SC9 (nolock)  "
	// itens liberados
	_cQrySC6 += "INNER JOIN "+RetSqlName("SC6")+" SC6 (nolock)  ON "+RetSqlCond("SC6")+" AND C6_NUM = C9_PEDIDO AND C6_ITEM = C9_ITEM AND C6_PRODUTO = C9_PRODUTO "
	// filtro padrao
	_cQrySC6 += "WHERE "+RetSqlCond("SC9")+" "
	// nr do pedido
	_cQrySC6 += "AND C9_PEDIDO = '"+mvPedido+"' "
	// sem nota fiscal emitida E sem bloqueio de WMS
	_cQrySC6 += "AND C9_NFISCAL = ' ' AND C9_BLEST IN ('  ','02') AND C9_BLWMS = ' ' "
	// ordem dos dados
	_cQrySC6 += "ORDER BY C6_NUM, C6_ITEM "

	memowrit("c:\query\twmsa022_sfLibPedVen.txt",_cQrySC6)

	// alimenta o vetor com os RECNOs dos itens do pedido
	_aRecnoLib := U_SqlToVet(_cQrySC6)

	// varre todo os itens dos pedidos de venda
	For _nRecnoLib := 1 to len(_aRecnoLib)

		// posiciona no registro do item liberado
		dbSelectArea("SC9")
		SC9->(dbGoTo( _aRecnoLib[_nRecnoLib][2] ))

		// posiciona no registro do item
		dbSelectArea("SC6")
		SC6->(dbGoTo( _aRecnoLib[_nRecnoLib][1] ))

		// posiciona no cabecalho do pedido
		dbSelectArea("SC5")
		SC5->(dbSetOrder( 1 )) // 1-C5_FILIAL, C5_NUM
		SC5->(dbSeek( xFilial("SC5")+SC6->C6_NUM ))

		// pedidos liberados
		If ( aScan(_aPedLiber,{|x| x == SC5->C5_NUM }) == 0 )
			aAdd(_aPedLiber,SC5->C5_NUM)
		EndIf

		// atualiza a doca de retirada
		RecLock("SC6")
		SC6->C6_LOCALIZ := IIf(mvEstorno, SC6->C6_NUM  , mvEndDest)
		SC6->C6_LOCAL   := IIf(mvEstorno, SC6->C6_LOCAL, mvArmDest)
		SC6->(MsUnLock())

		// realiza o estorno da mercadoria empenhada no pedido de venda / necessario para realizar nova liberacao
		a460estorna()

		// liberacao do item do pedido de venda
		MaLibDoFat( SC6->(RecNo()) ,; // recno do SC6
		SC6->C6_QTDVEN             ,; // quantidade liberada da 1a UM
		Nil                        ,; // retorno de bloqueio de credito
		Nil                        ,; // retorno de bloqueio de estoque
		.T.                        ,; // reavalia credito?
		.T.                        ,; // reavalia estoque?
		.F.                        ,; // permite liberacao parcial de pedidos?
		.F.                         ) // transferencia de enderecos automaticamente?

	Next _nRecnoLib

	// atualiza o status do pedido de venda
	SC6->(MaLiberOk(_aPedLiber))

	// restaura area atual
	RestArea(_aAreaSC9)
	RestArea(_aAreaSC6)
	RestArea(_aAreaSC5)
	RestArea(_aAreaAtu)

Return(_lRet)

// ** funcao que retorna os dados da camposicao do palete, comforme etiqueta agrupadora
Static Function sfRetCompos(mvEtqAgrup, mvCodProd)
	// variavel de retorno
	local _aRet := {}
	// query
	local _cQuery

	// valores padroes
	Default mvEtqAgrup := Space(_nTamEtqInt)
	Default mvCodProd  := Space(_nTamCodPrd)

	// query de validação do uso do volume
	_cQuery := " SELECT Z16_ETQPAL, Z16_CODPRO, Z16_ETQPRD, Z16_ETQVOL, SUM(Z16_SALDO) Z16_SALDO, Z16_ENDATU, "
	// consulta de saldo para que os registros não fiquem  negativos na Z16
	_cQuery += " Isnull(Sum(Z16_SALDO) - "
	_cQuery += " (SELECT Isnull(Sum(Z07_QUANT),0) FROM "+RetSqlTab("Z07")+" (nolock) "
	_cQuery += "  WHERE "+RetSqlCond("Z07")
	_cQuery += "   AND ( Z07_ETQVOL = Z16_ETQVOL "
	_cQuery += "      OR Z07_VOLORI = Z16_ETQVOL ) "
	_cQuery += "   AND Z07_PLTORI = Z16_ETQPAL "
	_cQuery += "   AND Z07_PRODUT = Z16_CODPRO "
	_cQuery += "   AND Z07_ENDATU = Z16_ENDATU "
	_cQuery += "   AND Z07_STATUS = 'C'), 0) SALDOPLT, " // usar somente status C pois o status D já teve o saldo baixado
	// tipo de estoque
	_cQuery += " Z16_TPESTO, "
	// lote ctl
	_cQuery += " Z16_LOTCTL, Z16_VLDLOT, Z16_NUMSER, Z16_DTSERI, Z16_NUMSEQ "
	// mapa de separacao
	_cQuery += " FROM "+RetSqlTab("Z08")+" (nolock) "
	// composicao de paletes
	_cQuery += " INNER JOIN "+RetSqlTab("Z16")+" (nolock)  ON "+RetSqlCond("Z16")
	// codigo id do palete
	_cQuery += " AND Z16_ETQPAL = (CASE WHEN Z08_NEWPLT <> ' ' THEN Z08_NEWPLT ELSE Z08_PALLET END) "
	// cod. produto
	_cQuery += " AND Z16_CODPRO = Z08_PRODUT "
	// etiqueta do volume
	_cQuery += " AND Z16_ETQVOL = '"+mvEtqAgrup+"' "
	// somente com saldo
	_cQuery += " AND Z16_SALDO > 0 "
	// cadastro produto
	If ( ! Empty(mvCodProd))
		// cad. produto
		_cQuery += " INNER JOIN "+RetSqlTab("SB1")+" (nolock)  ON "+RetSqlCond("SB1")+" AND B1_COD = '"+mvCodProd+"' AND B1_COD = Z16_CODPRO "
		// grupo/sigla
		_cQuery += " AND B1_GRUPO IN (SELECT A1_SIGLA FROM "+RetSqlTab("SA1")+" (nolock)  WHERE "+RetSqlCond("SA1")+" AND A1_COD = '"+_cCodCliFor+"' AND A1_LOJA = '"+_cLojCliFor+"') "
	EndIf
	// filtro do mapa
	_cQuery += " WHERE "+RetSqlCond("Z08")
	// nr da OS
	_cQuery += " AND Z08_NUMOS = '"+_cNumOrdSrv+"' "
	// statuso R=Realizado
	_cQuery += " AND Z08_STATUS = 'R' "
	// agrupa dados
	_cQuery += " GROUP BY Z16_ETQPAL, Z16_CODPRO, Z16_ETQPRD, Z16_ETQVOL, Z16_ENDATU, Z16_TPESTO, Z16_LOTCTL, Z16_VLDLOT, Z16_NUMSER, Z16_DTSERI, Z16_NUMSEQ "
	// ordem dos dados
	_cQuery += " ORDER BY Z16_ETQPAL"

	MemoWrit("c:\query\twmsa024_sfVldAgrupa_sfRetCompos.txt",_cQuery)

	// dados do palete original
	//  estrutura:
	//  1- Id Palete
	//  2- Cod. Produto
	//  3- Etq Produto
	//  4- Etq Volume
	//  5. Saldo
	//  6. End. Atual
	//  7. Saldo Atual
	//  8. Tipo de Estoque
	//  9. Lote
	// 10. Validade Lote
	// 11. Número série
	// 12. Data Número série
	// 13. NUMSEQ
	_aRet := U_SqlToVet(_cQuery,{"Z16_VLDLOT", "Z16_DTSERI"})

Return(_aRet)

// ** funcao para informar dados adicionais
Static Function sfInfQuant()
	// controle para nao fechar a tela
	Local _lRetOk := .F.

	// controles para desenhar o componente get
	local _nLinha  := 20    // linha inicial 
	local _nSaltol := 20   // incremento de linha

	// primeiro campo criado, para posicionar o foco
	local _cCampo := ""

	// reinicia segunda unidade de medida
	_nQtdSegUM := 0

	// monta a tela para informa a quantidade
	_oWndInfQuant := MSDialog():New(020,020,270,220,"Informações adicionais",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlInfQtdCab := TPanel():New(000,000,nil,_oWndInfQuant,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlInfQtdCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpInfQtdOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRetOk := .T.,_oWndInfQuant:End() },_oPnlInfQtdCab,"Ok",,.T.)
	_oBmpInfQtdOk:Align := CONTROL_ALIGN_LEFT

	// campos disponiveis
	If (_lInfManual)  // se informa quantidade manual, mostra campos de quantidade
		_cCampo := "_oGetQuant"
		_oGetQuant   := TGet():New(_nLinha, 005, {|u| If(PCount()>0,_nQtdProd :=u,_nQtdProd )}, _oWndInfQuant, 060, 010, _cMaskQuant                 , {|| (Positivo()) .And. (sfVldQuant(2)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nQtdProd" ,,,,,,,"Quantidade ("+SB1->B1_UM+"):"   ,1) ; _nLinha += _nSaltoL
		_oGetQtdSeg  := TGet():New(_nLinha, 005, {|u| If(PCount()>0,_nQtdSegUM:=u,_nQtdSegUM)}, _oWndInfQuant, 060, 010, _cMaskQuant                 , {|| (Positivo()) .And. (sfVldQuant(1)) },,,_oFnt02,,,.T.,"",,{|| ! Empty(SB1->B1_SEGUM) },.F.,.F.,,.F.,.F.,"","_nQtdSegUM",,,,,,,"Qtd Seg UM ("+SB1->B1_SEGUM+"):",1) ; _nLinha += _nSaltoL
	EndIf
	_oGetPlt     := TGet():New(_nLinha, 005, {|u| If(PCount()>0,_cPltCli  :=u,_cPltCli  )}, _oWndInfQuant, 060, 010, PesqPict("Z07","Z07_PLTCLI"), {|| (sfVldInfAd() )}                                   ,,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cPltCli",,,,,,,"Plt. Clie."                  ,1) ; _nLinha += _nSaltoL

	// seta o foco no primeiro get
	&(_cCampo):SetFocus()

	// ativacao da tela com validacao
	_oWndInfQuant:Activate(,,,.T.,{|| _lRetOk })

Return

// ** funcao que calcula as unidade de medidas
Static Function sfVldQuant(mvUndRet)

	If (_nQtdProd > 0) .Or. (_nQtdSegUM > 0)
		If (!Empty(SB1->B1_SEGUM)) .And. (SB1->B1_CONV>0)
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

// ** funcao auxiliar para validar se o campo de dados adicionais é obrigatório 
Static Function sfVldInfAd()
	local _lRet := .T.

	If (_lVldInfAd) .and. ( Empty(_cPltCli) )
		U_FtWmsMsg("Este produto exige a digitação/bipagem de dados adicionais do pallet.", "TWSMA024 - sfVldInfAd")
		_lRet := .F.
	EndIf

Return (_lRet)

// ** funcao que valida a chave da nota fiscal de venda
Static Function sfVldChvNfv(mvChvNfVen, mvBrwPedidos, mvHeadPed, _lChaveOk)
	// variavel de retorno
	local _lRet := .T.
	// vetor com os pedidos
	local _aPedidos := mvBrwPedidos:aCols
	// posicao do campo chave nota fiscal
	local _nPosChave := aScan(mvHeadPed,{|x| AllTrim(x[2])=="C5_ZCHVNFV"})
	// variaveis temporarias
	local _nX

	// reinicia variavel
	_lChaveOk := .F.

	// varre todos os pedidos disponiveis
	For _nX := 1 to Len(_aPedidos)

		// compara os campos
		If (mvChvNfVen == _aPedidos[_nX][_nPosChave])
			// posiciona na linha do browse
			mvBrwPedidos:nAt := _nX
			// variavel de controle
			_lChaveOk := .T.
		EndIf

	Next _nX

Return(_lRet)

// ** função que permite encerrar a sequencia de montagem de volumes, caso todos os pedidos estejam aptos
Static Function sfFimOS(mvCodCli, mvLojCli, mvCarga, mvOndSep)

	local _nQtd   := 0
	local _cQuery := ""
	local _lRet   := .F.
	local _cTpAgr := IIf(Empty(mvCarga), "Onda de Separação", "Carga")

	// envia e-mail para o cliente avisando que a montagem foi finalizada
	local _lEmailFim := U_FtWmsParam("WMS_EXPEDICAO_EMAIL_FIM_MONTAGEM_VOLUMES", "L", .F., .F. , "", mvCodCli, mvLojCli, Nil, Nil)

	//pede confirmação
	If ( ! U_FtYesNoMsg("Deseja encerrar a etapa de montagem de volumes da " + _cTpAgr + " " + IIf(Empty(mvCarga), mvOndSep, mvCarga) + " ?"))
		Return( .F. )
	EndIf

	// finaliza OS somente quando todos os pedidos estiverem com os volumes montados
	_cQuery := " SELECT COUNT(*) QTD_PEND "
	// pedidos de venda
	_cQuery += " FROM " + RetSqlTab("SC5") + " (nolock) "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("SC5")
	// cliente, loja e tipo de operacao
	_cQuery += " AND C5_CLIENTE = '" + mvCodCli + "' AND C5_LOJACLI = '" + mvLojCli + "' AND C5_TIPOOPE = 'P' "
	// numero da carga/agrupadora
	If ( ! Empty(mvCarga) )
		_cQuery += " AND C5_ZCARGA = '" + mvCarga + "' "
	EndIf
	// filtro por onda de separacao
	If ( ! Empty(mvOndSep) )
		_cQuery += " AND C5_ZONDSEP = '" + mvOndSep + "' "
	EndIf
	// status da montagem de volume
	_cQuery += " AND C5_ZMNTVOL <> 'S' "

	memowrit("C:\query\twmsa024_sfFinaliza.txt",_cQuery)

	// joga os dados pro array
	_nQtd := U_FtQuery(_cQuery)

	//se este é o unico pedido pendente, então permite finalizar pois todos os OUTROS pedidos foram montados
	If (_nQtd == 0)
		// atualiza o status do servico para FI-FINALIZADO
		U_FtWmsSta(;
		Z06->Z06_STATUS,;
		"FI"           ,;
		Z06->Z06_NUMOS ,;
		Z06->Z06_SEQOS  )

		//sai do loop principal
		_lContConf := .F.

		//retorna sucesso
		_lRet := .T.

		// envia mensagem de e-mail
		If (_lEmailFim)
			sfMailRes()
		EndIf

	Else
		U_FtWmsMsg("Erro: ainda existem " + AllTrim(Str(_nQtd)) + " pedidos pendentes/não montados para esta " + _cTpAgr + ". Verifique!", "TWSMA024 - sfFimOS")
	EndIf

Return (_lRet)

// ** funcao que envia email com o resumo da ordem de servico
Static Function sfMailRes()

	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"Z05", "Z06", "SC5", "SA1"})

	// query
	local _cQuery

	// dados do pedido
	local _aTmpDados := {}
	local _nItPed

	// html da mensagem de email
	local _cHtml := ""

	// destinatarios
	local _cDestin := ""

	// prepara query
	_cQuery := " SELECT Z07_PEDIDO, "
	_cQuery += "        C5_ZPEDCLI, "
	_cQuery += "        C5_ZDOCCLI, "
	_cQuery += "        Sum(Z07_QUANT)             QTD_TOTAL, "
	_cQuery += "        Count(DISTINCT Z07_PRODUT) QTD_SKU, "
	_cQuery += "        Count(DISTINCT Z07_ETQVOL) QTD_VOL, "
	_cQuery += "        ISNULL(A4_NOME, 'EM BRANCO/NÃO INFORMADA') A4_NOME "
	_cQuery += " FROM   " + RetSqlTab("Z05") + " (nolock) "
	_cQuery += "        INNER JOIN " + RetSqlTab("Z06") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("Z06")
	_cQuery += "                   AND Z06_NUMOS = Z05_NUMOS "
	_cQuery += "                   AND Z06_SEQOS = '" + Z06->Z06_SEQOS + "' "
	_cQuery += "                   AND Z06_SERVIC = '001' "
	_cQuery += "                   AND Z06_TAREFA = '007' "
	_cQuery += "                   AND Z06_STATUS = 'FI' "
	_cQuery += "        INNER JOIN " + RetSqlTab("Z07") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("Z07")
	_cQuery += "                   AND Z07_NUMOS = Z06_NUMOS "
	_cQuery += "                   AND Z07_SEQOS = Z06_SEQOS "
	_cQuery += "        INNER JOIN " + RetSqlTab("SC5") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("SC5")
	_cQuery += "                   AND C5_NUM = Z07_PEDIDO "
	_cQuery += "        LEFT JOIN "  + RetSqlTab("SA4") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("SA4")
	_cQuery += "                   AND SA4.A4_COD = C5_TRANSP
	_cQuery += " WHERE  " + RetSqlCond("Z05")
	_cQuery += "        AND Z05_NUMOS = '" + Z06->Z06_NUMOS + "' "
	_cQuery += " GROUP  BY Z07_PEDIDO, "
	_cQuery += "           C5_ZPEDCLI, "
	_cQuery += "           C5_ZDOCCLI, "
	_cQuery += "           A4_NOME     "

	// atualiza variavel com dados do pedido
	// estrutura do _aTmpDados
	// 1 - Z07_PEDIDO
	// 2 - C5_ZPEDCLI
	// 3 - C5_ZDOCCLI
	// 4 - Sum(Z07_QUANT)             QTD_TOTAL
	// 5 - Count(DISTINCT Z07_PRODUT) QTD_SKU
	// 6 - Count(DISTINCT Z07_ETQVOL) QTD_VOL
	// 7 - ISNULL(A4_NOME, 'EM BRANCO/NÃO INFORMADA') A4_NOME / nome transportadora
	_aTmpDados := U_SqlToVet(_cQuery)

	// posiciona no cadastro do cliente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
	SA1->(dbSeek( xFilial("SA1") + Z05->Z05_CLIENT + Z05->Z05_LOJA ))

	// inicio da mensagem de email
	_cHtml += '<table width="780px" align="center">'
	_cHtml += '   <tr>'
	_cHtml += '      <td>'
	_cHtml += '         <table style="border-collapse: collapse;font-family: Tahoma; font-size: 12px;" border="1" width="100%" cellpadding="2" cellspacing="0" align="center" >'
	_cHtml += '            <tr>'
	_cHtml += '               <td height="30" colspan="2" style="background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Status de Separação e Preparação de Pedidos</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Filial</td>'
	_cHtml += '               <td width="80%" >' + AllTrim(SM0->M0_CODFIL) + "-" + AllTrim(SM0->M0_FILIAL) + '</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Data/Hora</td>'
	_cHtml += '               <td width="80%" >' + DtoC(Z06->Z06_DTFIM) + ' as ' + Z06->Z06_HRFIM + ' h</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Depositante</td>'
	_cHtml += '               <td width="80%" >' + SA1->A1_COD + ' / ' + SA1->A1_LOJA + ' - ' + AllTrim(SA1->A1_NOME) + '</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Ordem de Serviço</td>'
	_cHtml += '               <td width="80%" >' + Z06->Z06_NUMOS + ' / ' + Z06->Z06_SEQOS + '</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Status</td>'
	_cHtml += '               <td width="80%" ><span style="background-color: #80d22d">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>&nbsp;Pedido separado. Aguardando NF de Venda para carregamento.</td>'
	_cHtml += '            </tr>'
	_cHtml += '         </table>'
	_cHtml += '         <br>'
	_cHtml += '         <table style="border-collapse: collapse;font-family: Tahoma; font-size: 12px;" border="1" width="100%" cellpadding="2" cellspacing="0" align="center" >'
	_cHtml += '            <tr>'
	_cHtml += '               <td height="20" colspan="5" style="background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Composição do Mapa de Separação</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr style="background-color: #87CEEB;">'
	_cHtml += '               <td width="20%" >Pedido do Cliente</td>'
	_cHtml += '               <td width="20%" >Nota Fiscal de Venda</td>'
	_cHtml += '               <td width="40%" >Transportadora</td>'
	_cHtml += '               <td width="10%" >Quantidade de Volumes</td>'
	_cHtml += '               <td width="10%" >Quantidade de SKU</td>'
	_cHtml += '            </tr>'

	// varre todos os itens dos detalhes
	For _nItPed := 1 to Len(_aTmpDados)

		// estrutura do _aTmpDados
		// 1 - Z07_PEDIDO
		// 2 - C5_ZPEDCLI
		// 3 - C5_ZDOCCLI
		// 4 - Sum(Z07_QUANT)             QTD_TOTAL
		// 5 - Count(DISTINCT Z07_PRODUT) QTD_SKU
		// 6 - Count(DISTINCT Z07_ETQVOL) QTD_VOL
		// 7 - ISNULL(A4_NOME, 'EM BRANCO/NÃO INFORMADA') A4_NOME / nome transportadora

		// insere linha na mensagem
		_cHtml += '            <tr>'
		_cHtml += '               <td width="20%" >' + AllTrim(_aTmpDados[_nItPed][2]) + '</td>'
		_cHtml += '               <td width="20%" >' + AllTrim(_aTmpDados[_nItPed][3]) + '</td>'
		_cHtml += '               <td width="20%" >' + AllTrim(_aTmpDados[_nItPed][7]) + '</td>'
		_cHtml += '               <td width="10%" align="center" >' + AllTrim(Str(_aTmpDados[_nItPed][6])) + '</td>'
		_cHtml += '               <td width="10%" align="center">' + AllTrim(Str(_aTmpDados[_nItPed][5])) + '</td>'
		_cHtml += '            </tr>'

	Next _nItPed

	_cHtml += '         </table>'
	_cHtml += '         <br>'
	_cHtml += '      </td>'
	_cHtml += '   </tr>'
	_cHtml += '</table>'

	// prepara relacao de destinatarios
	_cDestin := AllTrim(SA1->A1_USRCONT)

	// envio de email
	U_FtMail(_cHtml, "TECADI - Log de Preparação de Pedido - " + DtoC(Date()), _cDestin)

	// restaura areas iniciais
	RestOrd(_aAreaIni, .T.)
	RestArea(_aAreaAtu)

Return( .T. )

// Tela de alteração de numero de serie
Static Function sfAltVol(mvNumOS, mvCodCli, mvLojCli, mvPedido)
	// controle de confirmacao da tela
	local _lFechaWnd := .F.

	// objetos locais
	local _oPnInMvCb, _oPnInMvCen
	local _oSayNrOrdSrv, _oSayPedido
	local _oSayDscOri, _oSayTexto
	Local _oBmpSair, _oBtnFoco

	// array para guardar as informações da etiqueta origem
	Private _aVolOri := {}
	Private _cEndereco := CriaVar("BE_LOCALIZ",.F.)

	// janela e objetos
	private _oWndInicMov
	Private _oGetVolOri, _oGetNewVol

	// tamanho dos campos de etiquetas
	private _nTamIdEtq := TamSx3("Z07_ETQVOL")[1]
	private _cVolOri   := Space(_nTamIdEtq)
	private _cNewVol   := Space(_nTamIdEtq)

	// guarda Recnos bloqueados durante o movimento
	Private _aRegLk1 := {}
	
	// não continua caso pedido não esteja com a montagem finalizada
	If GetAdvFVal("SC5", "C5_ZMNTVOL", xFilial("SC5") + mvPedido) != "S"
		U_FtWmsMsg("Montagem do "+mvPedido+" não está encerrada! Faça a conferência pela rotina padrão.","TWMSA024 - sfVldEtq")
		Return()
	EndIf
	
	// monta o dialogo do monitor
	_oWndInicMov := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"TWMSA024 - Troca de volume",,,.F.,,,,,,.T.,,,.T. )
	_oWndInicMov:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnInMvCb := TPanel():New(000,000,nil,_oWndInicMov,,.F.,.F.,,CLR_HGRAY,20,20,.T.,.F.)
	_oPnInMvCb:Align:= CONTROL_ALIGN_TOP

	// titulo com a ordem de servico
	_oSayNrOrdSrv := TSay():New(002,005,{||"Ord.Serv: " + mvNumOS },_oPnInMvCb,,_oFnt05,.F.,.F.,.F.,.T.)
	_oSayPedido   := TSay():New(010,005,{||"Pedido:   " + mvPedido },_oPnInMvCb,,_oFnt05,.F.,.F.,.F.,.T.)

	// -- SAIR
	_oBmpSair := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| LibLock(_aRegLk1), _lFechaWnd := .T. , _oWndInicMov:End() },_oPnInMvCb,"Sair",,.T.)
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// cria o panel para os campos
	_oPnInMvCen := TPanel():New(000,000,nil,_oWndInicMov,,.F.,.F.,,,140,140,.T.,.F.)
	_oPnInMvCen:Align:= CONTROL_ALIGN_TOP

	// etiqueta volume produto origem (a ser substituido)
	_oGetVolOri := TGet():New(010,003,{|u| If(PCount()>0,_cVolOri:=u,_cVolOri)},_oPnInMvCen,100,015,"@!",;
	{|| (Vazio()) .Or. (sfVldEtq(@_lFechaWnd, _cVolOri, .F.,mvCodCli, mvLojCli, mvNumOS, mvPedido)) },,,_oFnt03,;
	,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cVolOri",,,,,, .T. ,"Volume antigo (que será substituído)", 1)

	// sugestão de endereço
	_oSayDscOri := TSay():New(038,010,{||"Endereço para apanhe:  " +CRLF + _cEndereco },_oPnInMvCen,,_oFnt05,.F.,.F.,.F.,.T.)

	// etiqueta - novo volume (que irá substituir)
	_oGetNewVol := TGet():New(060,003,{|u| If(PCount()>0,_cNewVol:=u,_cNewVol)},_oPnInMvCen,100,015,"@!",;
	{|| (Vazio()) .Or. (sfVldEtq(@_lFechaWnd, _cNewVol, .T. ,mvCodCli, mvLojCli, mvNumOS, mvPedido)) },,,_oFnt03,,;
	,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNewVol",,,,,, .T. ,"Novo volume (a substituir)", 1)
	_oGetNewVol:Disable()  // começa desativado, só ativa após bipar o volume antigo

	_oSayTexto  := TSay():New(090,005,{||"A troca respeitará a regra de FIFO/LIFO "+CRLF+"do cliente.O apanhe deve ser feito "+CRLF+"no local indicado." },_oPnInMvCen,,_oFnt02,.F.,.F.,.F.,.T.)

	// cria um botao, que nao executa nada, serve apenas para receber o foco e possibilitar tirar o cursor do campo
	_oBtnFoco := TButton():New(000,000,"",_oPnInMvCen,{|| Nil },000,000,,,,.T.,,"",,,,.F. )

	// seta o ofoco
	_oGetVolOri:SetFocus()

	// ativa a tela
	_oWndInicMov:Activate(,,,.F.,{|| _lFechaWnd },,)

Return()

// Função responsável por validar a etiqueta de volume lida
Static Function sfVldEtq(mvFechaWnd, _cEtiqueta, _lNewVol, mvCodCli, mvLojCli, mvNumOS, mvPedido)
	Local _cQuery := ""
	Local _lRet   := .T.

	// declara variáveis necessárias na static call sfVldEtiqueta (TWMSA033)
	Private _cTipoTf	:= "02" // tipo de transferência (01 - Pallet inteiro / 02 - Volume unitário)
	Private _cCliSigla	:= GetAdvFVal("SA1", "A1_SIGLA", xFilial("SA1") + mvCodCli + mvLojCli)

	// Verifica se a etiqueta de origem bipada faz realmente parte da OS
	If (_lRet) .And. !(_lNewVol)
		_cQuery := " SELECT Z07_ENDATU "
		_cQuery += " FROM " + RetSqlTab("Z07") + " (nolock)  "
		_cQuery += " where " + RetSqlCond("Z07")
		_cQuery += " and Z07_NUMOS  = '"+mvNumOS+"' "
		_cQuery += " and Z07_CLIENT = '"+mvCodCli+"' "
		_cQuery += " and Z07_LOJA   = '"+mvLojCli+"' "
		_cQuery += " and Z07_ETQVOL = '"+_cEtiqueta+"' "
		_cQuery += " and Z07_PEDIDO = '"+mvPedido+"' "

		If Empty(U_FTQuery(_cQuery))
			U_FtWmsMsg("Esta etiqueta não pertence a OS "+mvNumOS+"! Favor verificar!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// Chama função que efetua a validação da etiqueta
	If (_lRet)
		//		_lRet := U_sfVldEtiqueta(_cTpEtiq, _cEtiqueta, Nil, Nil, @_lFixaWnd, "ORI", Nil)
		//		_lRet := StaticCall(TWMSA033, sfVldEtiqueta, "04", _cEtiqueta, Nil, Nil, @_lFixaWnd, "ORI", Nil)  
		_lRet := StaticCall(TWMSA033, sfVldEtiqueta, "04", _cEtiqueta, Nil, Nil, Nil, "ORI", Nil)  

		//sfVldEtiqueta(mvTpEtiq, mvIdEtiqueta, mvContProc, mvWndOrig, mvFechaTela, mvTipoEnd, mvCompPlt)
	EndIf

	// se não for a etiqueta nova, então guarda as informações da etiqueta antiga no array para validações posteriores
	If (_lRet) .AND. !(_lNewVol) 
		_cQuery := " SELECT R_E_C_N_O_, Z16_CODPRO, Z16_LOCAL, Z16_ENDATU, Z16_DTSERI, Z16_TPESTO "
		_cQuery += " FROM " + RetSqlTab("Z16") + " (NOLOCK)  "
		_cQuery += " WHERE " + RetSqlCond("Z16")
		_cQuery += " AND Z16_SALDO > 0  "
		_cQuery += " AND Z16_ETQVOL = '"+_cEtiqueta+"'"

		_aVolOri := U_SqlToVet(_cQuery)

		// valida se não encontrou
		If Len(_aVolOri) == 0
			U_FtWmsMsg("Etiqueta não encontrada!","TWMSA024 - sfVldEtq")
			_lRet := .F.
		Elseif Len(_aVolOri) > 1  // valida se trouxe mais de uma linha (sem suporte na versão 1 - 01/08/19)
			U_FtWmsMsg("Etiqueta de agrupadora (mais de um produto na mesma etiqueta) não suportada nesta versão da rotina!","TWMSA024 - sfVldEtq")
			_lRet := .F.
		EndIf

	EndIf

	// Atualiza o campo Sugestão de apanhe de endereço
	If (_lRet) .And. !(_lNewVol)
		// ### ->> PRECISA ANALISAR E VALIDAR ESTA QUERY ABAIXO
		_cQuery := " SELECT TOP 1 Z16_ENDATU "
		_cQuery += " FROM   " + RetSqlTab("Z16") + " (NOLOCK) "
		_cQuery += " WHERE  " + RetSqlCond("Z16")
		_cQuery += "        AND Z16_CODPRO = '"+_aVolOri[1][2]+"' "
		_cQuery += "        AND Z16_LOCAL  = '"+_aVolOri[1][3]+"' "
		_cQuery += "        AND Z16_TPESTO = '000001' " 
		// filtra pallets que estejam no mapa de apanhe
		_cQuery += "        AND NOT EXISTS (SELECT Z08_ENDORI, Z08_ENDDES, Z08_PALLET
		_cQuery += "                      FROM   " + RetSqlTab("Z08") + " (NOLOCK) "
		_cQuery += "                      WHERE  " + RetSqlCond("Z08")
		_cQuery += "                      AND Z08_LOCAL = Z16_LOCAL "
		_cQuery += "                      AND Z08_STATUS != 'R' "
		_cQuery += "                      AND Z08_PRODUT = Z16_CODPRO"
		_cQuery += "                      AND (Z08_ENDORI = Z16_ENDATU OR Z08_ENDDES = Z16_ENDATU ))"		
		// filtra endereços que estejam com saldo divergente
		_cQuery += "        AND Z16_SALDO <= (SELECT Sum(BF_QUANT) "
		_cQuery += "                          FROM   " + RetSqlTab("SBF") + " (NOLOCK) "
		_cQuery += "                          WHERE " + RetSqlCond("SBF")
		_cQuery += "                                 AND BF_LOCAL = Z16_LOCAL "
		_cQuery += "                                 AND BF_PRODUTO = Z16_CODPRO "
		_cQuery += "                                 AND BF_LOCALIZ = Z16_ENDATU "
		_cQuery += "                                 AND BF_ESTFIS IN ( '000007', '000002', '000010' )) "
		_cQuery += " ORDER BY Z16_DTSERI, Z16_SALDO "

		memowrit("c:\query\twmsa024_sfVldEtq_1.txt", _cQuery)

		// grava endereço sugestão
		_cEndereco := U_FTQuery(_cQuery)
	EndIf

	// Se for validação da etiqueta de Destino efetua demais validações e processos
	If (_lRet) .And. (_lNewVol)
		// Não pode ser etiquetas iguais
		If AllTrim(_cNewVol) == AllTrim(_cVolOri)
			U_FtWmsMsg("As etiquetas não podem ser iguais!","TWMSA024 - sfVldEtq")
			_lRet := .F.
		EndIf

		// Valida se bipou volume do endereço sugerido (sugerido meu ovo)
		If (GetAdvFVal("Z16", "Z16_ENDATU", xFilial("Z16") + _cEtiqueta, 4) != _cEndereco)  // 04- Z16_FILIAL, Z16_ETQVOL, R_E_C_N_O_, D_E_L_E_T_
			U_FtWmsMsg("Volume a substituir não é do endereço informado!","TWMSA024 - sfVldEtq")
			_lRet := .F.
		EndIf		
	EndIf

	// tudo certo
	If (_lRet) .And. (_lNewVol)
		// solicita confirmaçãp
		If U_FtYesNoMsg("Confirma a troca dos volumes ?")
			// tenta efetuar a troca
			If U_FTrocaVol(_cVolOri, _cNewVol, mvNumOS, "QUALIDADE")
				U_FtWmsMsg("Troca de volume efetuada com sucesso!","TWMSA024 - sfVldEtq")
				mvFechaWnd := .T.
			Else
				U_FtWmsMsg("Ocorreu algum erro durante a troca de volumes!","TWMSA024 - sfVldEtq")
				_lRet := .F.
			EndIf
		Else   // ficou com medo e não confirmou
			_lRet := .F.
		EndIf
	EndIf

	// desabilita botão do volume antigo e seta o foco no novo
	If (_lRet) .AND. !(_lNewVol)
		_oGetVolOri:Disable()
		_oGetNewVol:Enable()
		_oGetVolOri:SetFocus()

		// Bloqueia volume antigo
		Aadd(_aRegLk1, {"Z16", _aVolOri[1][1]} )  // _aVolOri[1][1] = RECNO Z16
	EndIf

	// Se o processo deu todo certo, fecha a janela de troca de serie
	If (_lRet) .And. (_lNewVol) .And. (mvFechaWnd)
		LibLock(_aRegLk1)
		_oWndInicMov:End()
	EndIf

Return()
