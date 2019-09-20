#include "totvs.ch"
#include "TopConn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para conferencia de mercadoria no processo de    !
!                  ! expedicao/saida de produtos ("em stage")                !
!                  ! - Chamada a partir da rotina TWMSA009/TACDA002          !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 09/2012 !
+------------------+--------------------------------------------------------*/

User Function TWMSA012(mvQryUsr)

	local _lRet := .f.

	// pedido escolhido para aquela operação
	Private _cPedido := ""
	// total de pedidos
	Private _nTotPed := 0

	// valida se ha equipamento informado
	If ( ! Empty(_cCodEquip))
		U_FtWmsMsg("No processo de conferência não é necessário equipamento!","ATENCAO")
		Return(.f.)
	EndIf

	// inclui o codigo do servico de conferencia (saida) na query
	mvQryUsr += " AND Z06_SERVIC = '001' AND Z06_TAREFA = '003' "

	// chama funcao para visualizar o resumo da OS
	If ( _lRet := U_ACDA002C(mvQryUsr, "EX", .t., .F., .f., .T. ) )

		// pega o pedido que vai ser executado
		If ( ! sfTRetPed(Z05->Z05_CARGA))
			U_FtWmsMsg("É necessário selecionar algum pedido para continuar.","Atenção")
			Return (.f.)
		EndIf

		// se preencheu o pedido
		If ( ! Empty(_cPedido) )
			// rotina generica de conferencia
			U_WMSA012A(	Z06->Z06_SERVIC, Z06->Z06_TAREFA, "", Z06->Z06_STATUS, ;
			Z06->Z06_NUMOS, Z06->Z06_SEQOS, ;
			Z05->Z05_CLIENT, Z05->Z05_LOJA, ;
			Z06->Z06_PRIOR )
		EndIf

	EndIf

Return(_lRet)

// ** função da tela todos os pedidos daquela carga
Static Function sfTRetPed(mvCarga)

	// variavel de controle
	local _lRet      := .f.
	// objetos locais
	local _oWmsPedidos, _oPnlPedCab, _oBmpOk, _oBmpSair, _oBrwPedidos, _oBmpFim
	// arrays do browse
	local _aHeadPed  := {}
	// define o acols
	local _aColsPed := sfARetPed(mvCarga)

	// define a quantidade de pedidos
	_nTotPed := Len(_aColsPed)

	// monta o dialogo do monitor
	_oWmsPedidos := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Pedidos da Carga",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes de operacao
	_oPnlPedCab := TPanel():New(000,000,nil,_oWmsPedidos,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlPedCabs:Align:= CONTROL_ALIGN_TOP

	// botao que seleciona um pedido
	_oBmpOk := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| _cPedido := _oBrwPedidos:aCols[_oBrwPedidos:nAt][2], _lRet := .t., _oWmsPedidos:End() },_oPnlPedCab,"OK",,.T.)
	_oBmpOk:Align := CONTROL_ALIGN_LEFT

	// botao para encerrar a conferencia (se tudo já foi concluído)
	_oBmpFim := TBtnBmp2():New(000,000,060,022,"sdusetdel",,,,{|| IIf (_lRet := sfFimOS(mvCarga) , _oWmsPedidos:End(), Nil ) },_oPnlPedCab,"Finalizar conferência",,.T.)
	_oBmpFim:Align := CONTROL_ALIGN_LEFT

	// botao que sai
	_oBmpSair := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| _oWmsPedidos:End()},_oPnlPedCab,"Sair",,.T.)
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// define array do browse
	aAdd(_aHeadPed,{"Sts"         ,"IT_ZMNTVOL" ,"@!" ,2                      ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Pedido"      ,"C9_PEDIDO"  ,"@!" ,TamSx3("C9_PEDIDO")[1] ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Agrupador"   ,"C5_ZAGRUPA" ,"@!" ,TamSx3("C5_ZAGRUPA")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Ped.Cliente" ,"C5_ZPEDCLI" ,"@!" ,TamSx3("C5_ZPEDCLI")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })

	// browse
	_oBrwPedidos := MsNewGetDados():New(078,000,148,118,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsPed),'AllwaysTrue()','','AllwaysTrue()',_oWmsPedidos,_aHeadPed,_aColsPed)
	_oBrwPedidos:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativacao da tela
	ACTIVATE MSDIALOG _oWmsPedidos

Return (_lRet)

// ** função que retorna o array de pedidos
Static Function sfARetPed(mvCarga)
	// array que vai receber os dados
	local _aPedidos := {}
	// query para busca de pedidos
	local _cQuery   := ""

	// busco os pedidos baseado na carga
	_cQuery := " SELECT DISTINCT CASE WHEN C5_ZMNTVOL = 'S' THEN 'OK' ELSE '  ' END IT_ZMNTVOL, C9_PEDIDO, C5_ZAGRUPA, C5_ZPEDCLI, '.F.' IT_DEL"
	_cQuery += " FROM " + RetSqlTab("SC9") + " (nolock) "
	_cQuery += " INNER JOIN "+RetSqlTab("SC5") + " ON " + RetSqlCond("SC5") + " AND C5_NUM = C9_PEDIDO "
	_cQuery += " WHERE " + RetSqlCond("SC9")
	_cQuery += " AND C9_CARGA = '" + mvCarga + "' "
	_cQuery += " ORDER BY C9_PEDIDO "

	memowrit("C:\query\twmsa012_sfARetPed.txt",_cQuery)

	// jogo os dados pro array
	_aPedidos := U_SqlToVet(_cQuery)

	// retorno o array
Return (_aPedidos)

// ** funcao principal de conferencia de saida/carregamento (expedicao)
User Function WMSA012A(mvCodServ, mvCodTaref, mvCodFuncao, mvStatus, mvNumOS, mvSeqOS, mvCodCli, mvLojCli, mvPriori)

	// objetos locais
	local _oWmsConfExpe
	local _oPnlCfeCab
	local _oBmpCfeNvPalete, _oBmpCfeCons, _oBmpOpcoes
	local _oSayTitulo, _oSayNrPalete, _oSayCodProd

	// sub-menu
	local _oMnuOpcoes := nil
	local _oSbMnOpc1  := nil
	local _oSbMnOpc2  := nil
	local _oSbMnOpc3  := nil
	local _oSbMnOpc4  := nil
	local _oSbMnOpc5  := nil

	// controle de while
	local _lRet := .t.

	local _lOk := .f.

	// resumo da conferencia
	local _aResumoConf := {}

	// tipo da operacao da OS (E-Ent/S-Sai/I-Int)
	local _cTipoOper := ""
	local _cDscOpera := ""

	Local _aRetSC5 := {}
	Local _cQrySC5 := ""

	// variaveis recebidas de parametro
	Private cCodServ := mvCodServ
	Private cCodTaref := mvCodTaref
	Private cCodFuncao := mvCodFuncao
	Private _cCodStatus := mvStatus
	Private _cNumOrdSrv := mvNumOS
	Private _cSeqOrdSrv := mvSeqOS
	Private _cCodCliFor := mvCodCli
	Private _cLojCliFor := mvLojCli
	Private cPriori    := mvPriori

	// informacoes do produto
	Private _cEtiqProd := CriaVar("Z11_CODETI",.f.)
	Private nTamCodPrd := TamSx3("B1_COD")[1]
	Private _cCodProd := Space(nTamCodPrd)
	Private _cDscProd := ""
	Private _nQtdProd := 1
	Private _nQtdSegUM := 0

	// posicao dos campos no browse
	Private nPosNomOpe := 0
	Private _nPosIdPal := 0
	Private _nPosCdPrd := 0
	Private _nPosQuant := 0

	// controle de numero de contagens
	Private cNrContagem := ""

	// Id do palete
	Private _nTamIdPal := TamSx3("Z11_CODETI")[1]
	Private _cIdPalete := Space(_nTamIdPal)
	Private _cMskEtiq  := PesqPict("Z11","Z11_CODETI")
	Private _cCodUnit  := CriaVar("DC1_CODUNI",.f.)

	// endereco de devolucao de mercadorias para o cliente
	Private _cEndDevCli := PadR("DEVMERCCLI",TamSx3("BE_LOCALIZ")[1])

	// numero da movimentacao do veiculo
	Private _cNumCESV := ""

	// armazem
	Private _cArmzServ := ""

	// objetos Private
	Private _oGetNrPalete, _oGetCodProd
	// variaveis do browse
	Private _oBrwConfExpe
	Private _aHeadConf := {}
	Private _aColsConf := {}

	// doca do servico
	private _cDocaSrv := ""

	// Informações do Lote //Guilherme DataRoute
	private _nTamIdLot 	:= TamSx3("B8_LOTECTL")[1]
	private _cIdLote	:= Space(_nTamIdLot)
	Private _lCtrlLot   := .F.

	//Informações da Quantidade //Guilherme DataRoute
	private _nTamPlCli 	:= TamSx3("Z16_PLTCLI")[1]
	private _cPltClie	:= Space(_nTamPlCli)

	//Variável para verificar se preenche quantidade
	Private _lInfManual  := .F.
	//Numero do contrato.
	Private _cContrat := ""

	// mascara para campos quantidade
	private _cMaskQuant := PesqPict("SD1","D1_QUANT")

	// numero carga / agrupadora
	Private _cNrCarga := ""

	// posiciona na OS
	dbSelectArea("Z05")
	Z05->(dbSetOrder(1)) // 1-Z05_FILIAL, Z05_NUMOS
	Z05->(dbSeek( xFilial("Z05")+_cNumOrdSrv ))

	// numero carga / agrupadora
	_cNrCarga := Z05->Z05_CARGA

	// posiciona no pedido novamente
	dbSelectArea("SC5")
	SC5->(dbSetOrder(1)) // 1-C5_FILIAL, C5_NUM
	SC5->(dbSeek( xFilial("SC5")+_cPedido ))

	// valida se o pedido ja esta ok
	If (SC5->C5_ZMNTVOL == "S")
		U_FtWmsMsg("O pedido "+_cPedido+" já foi finalizado.","Atenção")
		Return (.f.)
	EndIf

	// atualiza CESV
	_cNumCESV  := Z05->Z05_CESV
	// define o tipo da operacao da OS (E-Ent/S-Sai/I-Int)
	_cTipoOper := Z05->Z05_TPOPER
	_cDscOpera := If(_cTipoOper=="E","Recebimento",If(_cTipoOper=="S","Expedicao","Interna"))

	// posiciona no item da OS
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	Z06->(dbSeek( xFilial("Z06")+_cNumOrdSrv+_cSeqOrdSrv ))

	// atualiza armazem
	_cArmzServ := Z06->Z06_LOCAL

	// doca do servico
	_cDocaSrv := Z06->Z06_ENDSRV

	// controle de numero de contagens
	cNrContagem := sfRetNrCont()

	// mascara para campos quantidade
	_cMaskQuant := U_FtVldCtr(_cCodCliFor, _cCodCliFor, "WMS_MASCARA_CAMPO_QUANTIDADE", 2, Z05->Z05_CARGA, "C")

	// mascara para campos quantidade
	If (Empty(_cMaskQuant)).or.(_cMaskQuant == Nil)
		_cMaskQuant := PesqPict("SD1","D1_QUANT")
	EndIf

	// atualiza os dados
	sfSelDados(.f.)

	// funcao que pesquisa se ficou algum palete pendente
	sfRetPltInt()

	// define novo pallet
	_lNovoPalete := (Empty(_cIdPalete))

	// monta o dialogo do monitor
	_oWmsConfExpe := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Conf. Mercadoria (Expedição)",,,.F.,,,,,,.T.,,,.T. )
	_oWmsConfExpe:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlCfeCab := TPanel():New(000,000,nil,_oWmsConfExpe,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlCfeCab:Align:= CONTROL_ALIGN_TOP

	// opcoes de operacoes

	// -- NOVO PALETE
	_oBmpCfeNvPalete := TBtnBmp2():New(000,000,060,022,"ARMIMG32",,,,{|| sfNovoPalete() },_oPnlCfeCab,"Novo Palete",,.T.)
	_oBmpCfeNvPalete:Align := CONTROL_ALIGN_LEFT

	// -- CONSULTA DETALHES
	_oBmpCfeCons := TBtnBmp2():New(000,000,060,022,"MDIHELP",,,,{|| sfDetConfer() },_oPnlCfeCab,"Informações",,.T.)
	_oBmpCfeCons:Align := CONTROL_ALIGN_LEFT

	// sub-itens do menus
	_oMnuOpcoes := TMenu():New(0,0,0,0,.T.)
	// adiciona itens no Menu
	// INTERROMPER
	_oSbMnOpc1 := TMenuItem():New(_oMnuOpcoes,"Interromper",,,,{|| sfInterromper(_oWmsConfExpe,@_lOk) },,"STOP"   ,,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc1)

	// -- FINALIZAR OS
	_oSbMnOpc2 := TMenuItem():New(_oMnuOpcoes,"Finalizar OS",,,,{|| sfFinalizaOS(_oWmsConfExpe,@_lOk) },,"CHECKED",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc2)

	// -- CONSULTAR DETALHES
	_oSbMnOpc3 := TMenuItem():New(_oMnuOpcoes,"Cons. Detalhe OS",,,,{|| U_ACDA002B(_cNumOrdSrv, _cSeqOrdSrv,.f.) },,"NOTE",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc3)

	// -- ESTORNO DE PALETE
	_oSbMnOpc4 := TMenuItem():New(_oMnuOpcoes,"Estorno de Palete Atual",,,,{|| If( sfEstornoPlt( _oBrwConfExpe:aCols[_oBrwConfExpe:nAt][1] ) , sfNovoPalete() , Nil) },,"ESTOMOVI",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc4)

	// -- SAIR SEM INTERROMPER
	If ((_lUsrGeren).or.(_lUsrAccou).or.(_lUsrSuper))
		_oSbMnOpc5 := TMenuItem():New(_oMnuOpcoes,"Sair",,,,{|| _lOk := .t. , _oWmsConfExpe:End()},,"FINAL",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOpc5)
	EndIf

	// -- BOTAO COM MAIS OPCOES
	_oBmpOpcoes := TBtnBmp2():New(000,000,060,022,"SDUAPPEND",,,,{|| Nil },_oPnlCfeCab,"",,.T.)
	_oBmpOpcoes:Align := CONTROL_ALIGN_RIGHT
	_oBmpOpcoes:SetPopupMenu(_oMnuOpcoes)

	// titulo
	_oSayTitulo := TSay():New(025,003,{||"Conferência de Mercadoria (Expedição)"},_oWmsConfExpe,,_oFnt02,.F.,.F.,.F.,.T.)

	// controle por palete
	_oSayNrPalete := TSay():New(037,003,{||"Id Palete"},_oWmsConfExpe,,,.F.,.F.,.F.,.T.)
	_oGetNrPalete := TGet():New(037,030,{|u| If(PCount()>0,_cIdPalete:=u,_cIdPalete)},_oWmsConfExpe,050,010,_cMskEtiq,{|| Vazio().or.sfVldPalete() },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIdPalete",,)
	_oGetNrPalete:bWhen := {|| .f. }

	// informacoes do produto lido
	_oSayCodProd := TSay():New(056,003,{||"Produto"},_oWmsConfExpe,,,.F.,.F.,.F.,.T.)
	_oGetCodProd := TGet():New(056,030,{|u| If(PCount()>0,_cEtiqProd:=u,_cEtiqProd)},_oWmsConfExpe,050,010,_cMskEtiq,{|| Vazio().or.sfVldProd(@_oWmsConfExpe, @_lOk) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtiqProd",,)

	// browse com a listagem dos produtos conferidos
	_oBrwConfExpe := MsNewGetDados():New(078,000,148,118,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsConf),'AllwaysTrue()','','AllwaysTrue()',_oWmsConfExpe,_aHeadConf,_aColsConf)

	// volta o foco para o ID Palete
	_oGetCodProd:SetFocus()

	// ativa a tela
	_oWmsConfExpe:Activate(,,,.F.,{|| _lOk },,)

Return()


// ** funcao para filtrar os itens já conferidos do servico/nota selecionado, conforme codigo do operador
Static Function sfSelDados(mvRefresh)
	// area inicial do SX3
	Local aAreaSX3 := SX3->(GetArea())
	// campos para o select
	Local cQuery := ""
	Local nX := 0
	// variaveis temporarias
	Local aTmpStruct := {}

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
	cQuery := "SELECT Z07_PALLET, SUM(Z07_QUANT) Z07_QUANT, Z07_PRODUT, B1_DESC, "
	// buscca o ultimo recno para ordenar
	cQuery += "(SELECT MAX(R_E_C_N_O_) FROM " + RetSqlName('Z07') + " (nolock) WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
	cQuery += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	cQuery += "AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
	cQuery += "AND Z07_NRCONT = '"+cNrContagem+"' "
	cQuery += "AND Z07_PRODUT = Z07.Z07_PRODUT) Z07RECNO "
	// tabela de itens conferidos
	cQuery += "FROM "+RetSqlName('Z07')+" Z07 (nolock) "
	// cadastro de produtos
	cQuery += "INNER JOIN "+RetSqlName('SB1')+" SB1 (nolock) ON "+RetSqlCond("SB1")+" AND B1_COD = Z07_PRODUT "
	// cadastro de usuarios
	cQuery += "INNER JOIN "+RetSqlName("DCD")+" DCD (nolock) ON "+RetSqlCond("DCD")+" AND DCD_CODFUN = Z07_USUARI "
	// filtros
	cQuery += "WHERE "+RetSqlCond("Z07")+" "
	cQuery += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	cQuery += "AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
	cQuery += "AND Z07_NRCONT = '"+cNrContagem+"' "
	// somente que nao C-EM CONFERENCIA
	cQuery += "AND Z07_STATUS = 'C' "
	// agrupamento de informacoes
	cQuery += "GROUP BY Z07_PALLET, Z07_PRODUT, B1_DESC "
	cQuery += "ORDER BY Z07RECNO DESC "

	memowrit("c:\query\twmsa012_sfSelDados.txt",cQuery)

	// executa a query
	dbUseArea(.T.,'TOPCONN',TCGENQRY(,,cQuery),"QRYCNF",.F.,.T.)

	// verifica a necessidade de criar o Header
	If (Len(_aHeadConf)==0)

		aAdd(_aHeadConf,{"Id Palete","Z07_PALLET" ,""         , TamSx3("Z07_PALLET")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Quant"    ,"Z07_QUANT"  ,_cMaskQuant, TamSx3("Z07_QUANT")[1],TamSx3("Z07_QUANT")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Produto"  ,"Z07_PRODUT" ,""         , TamSx3("Z07_PRODUT")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Descr."   ,"B1_DESC"    ,""         , TamSx3("B1_DESC")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })

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
	If (_oBrwConfExpe <> nil)
		_oBrwConfExpe:aCols := aClone(_aColsConf)
		_oBrwConfExpe:Refresh(.t.)
	EndIf

Return ( .T. )

// ** funcao para validacao do id do palete
Static Function sfVldPalete()
	// variavel de retorno
	local _lRet := .t.
	local _cQryPalete

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11")+_cIdPalete ))
			U_FtWmsMsg("Identificador do pallet inválido!","ATENCAO")
			_lRet := .f.
		EndIf
	EndIf

	// valida o tipo da etiqueta lida
	If (_lRet)
		If (Z11->Z11_TIPO != "03")
			U_FtWmsMsg("Tipo de etiqueta inválida!","ATENCAO")
			_lRet := .f.
		EndIf
	EndIf

	// valida se a etiqueta do palete ja foi conferido
	If (_lRet)

		_cQryPalete := "SELECT COUNT(*) IT_PALETE "
		_cQryPalete += "FROM " + RetSqlName("Z07") + " Z07 (nolock) "
		// filtros
		_cQryPalete += "WHERE "+RetSqlCond("Z07")+" "
		_cQryPalete += "AND Z07_NUMOS    = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		_cQryPalete += "AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
		_cQryPalete += "AND Z07_NRCONT = '"+cNrContagem+"' "
		_cQryPalete += "AND Z07_PALLET = '"+_cIdPalete+"' "

		If (U_FtQuery(_cQryPalete) > 0)
			U_FtWmsMsg("Palete já conferido!","ATENCAO")
			_lRet := .f.
		EndIf
	EndIf

	// define o codigo do unitizador
	If (_lRet)
		_cCodUnit := Z11->Z11_UNITIZ
		// atualiza a quantidade de leitura
		RecLock("Z11")
		Z11->Z11_QTDLEI += 1
		Z11->(MsUnLock())

		// atualiza novo palete
		_lNovoPalete := .f.
		// atualiza objetos
		_oGetNrPalete:lReadOnly := (!_lNovoPalete)
		_oGetCodProd:lReadOnly  := (_lNovoPalete)
		// foco no objeto ID do produto
		_oGetCodProd:SetFocus()
	EndIf

Return(_lRet)

// ** funcao para validacao do codigo do produto digitado (lido)
Static Function sfVldProd(mvDlg, mvOk)
	Local _cQuery := ""
	// controle de retorno
	local _lRet := .t.
	// num seq do documento de entrada
	local _cNumSeq := ""
	// quantidade maxima permitida por palete
	local _nQtdMaxPalete := 0

	// RECNO do Z07
	local _nRecnoZ07 := 0
	//RECNO Z16 - Utilizo para criar replica da Z16
	Local _nRecnoZ16	:= 0

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11") + _cEtiqProd ))
			U_FtWmsMsg("Etiqueta inválida!","ATENCAO")
			_lRet := .f.
		EndIf
	EndIf

	// pesquisa se a etiqueta é valida
	If (_lRet).and.(Z11->Z11_TIPO != "01") // 01 - etiqueta de produto
		U_FtWmsMsg("Etiqueta de produto inválida!","ATENCAO")
		_lRet := .f.
	EndIf

	// verifica se ja iniciou a leitura do palete
	If (_lRet) .and. (Empty(_cIdPalete))
		// pesquisa um palete
		_cIdPalete := sfRetNrPalete(_cEtiqProd)
		// valida se encontrou o palete
		_lRet := (!Empty(_cIdPalete))
		// se encontrou, reposiciona no palete
		If (_lRet)
			dbSelectArea("Z11")
			Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
			If ! Z11->(dbSeek( xFilial("Z11")+_cIdPalete ))
				U_FtWmsMsg("Identificador do palete inválido!","ATENCAO")
				_lRet := .f.
			EndIf
			// atualiza os dados do palete
			If (_lRet)
				_cCodUnit  := Z11->Z11_UNITIZ
			EndIf
		EndIf

	EndIf

	// verifica se foi informado a etiqueta do produto
	If (Empty(_cEtiqProd))
		U_FtWmsMsg("É necessário informar a etiqueta do produto!","ATENCAO")
		_lRet := .f.
	EndIf

	// realiza a pesquisa do produto, podendo ser feita pelo codigo de barras

	If (_lRet).and.( ! U_FtCodBar(@_cEtiqProd, @_cCodProd, @_lInfManual, @_cNumSeq, "INTERNA", _cCodCliFor))
		// variavel de retorno
		_lRet := .f.
	EndIf

	//Valida se Cliente usa controle por Lote  //Guilherme DataRoute
	_lCtrlLot := (SB1->B1_RASTRO == "L")

	// atualiza descricao do produto
	_cDscProd := SB1->B1_DESC

	// reinicia a variavel de quantidade
	If (_lInfManual)
		_nQtdProd := 0
	Else
		_nQtdProd := 1
	EndIf

	// valida se a etiqueta do produto ja foi conferida nesta OS
	If (_lRet)
		_cQuery := "SELECT ISNULL(SUM(Z07_QUANT),0) IT_PRODUTO "
		_cQuery += "FROM " + RetSqlName("Z07") + " Z07 (nolock) "
		_cQuery += "WHERE "+RetSqlCond("Z07")+" "
		_cQuery += "AND Z07_ETQPRD  = '"+_cEtiqProd+"' "
		_cQuery += "AND Z07_PALLET  = '"+_cIdPalete+"' "
		_cQuery += "AND Z07_NRCONT  = '"+cNrContagem+"' "
		_cQuery += "AND Z07_NUMOS   = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		// status
		_cQuery += "AND Z07_STATUS != 'C' "

		memowrit("c:\query\twmsa012_sfVldProd_1.txt", _cQuery)

		// se a quantidade nao eh informada, valida o palete
		If (U_FtQuery(_cQuery) > 0)
			U_FtWmsMsg("Identificador do produto já foi conferido!","ATENCAO")
			_lRet := .f.
		EndIf
	EndIf

	// valida se a etiqueta do produto esta em mais de um palete
	If (_lRet)
		_cQuery := "SELECT ISNULL(SUM(Z07_QUANT),0) IT_PRODUTO "
		_cQuery += "FROM " + RetSqlName("Z07") + " Z07 (nolock) "
		_cQuery += "WHERE "+RetSqlCond("Z07")+" "
		_cQuery += "AND Z07_ETQPRD  = '"+_cEtiqProd+"' "
		_cQuery += "AND Z07_PALLET != '"+_cIdPalete+"' "
		_cQuery += "AND Z07_NRCONT  = '"+cNrContagem+"' "
		_cQuery += "AND Z07_NUMOS   = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "

		memowrit("c:\query\twmsa012_sfVldProd_2.txt", _cQuery)

		// se a quantidade nao eh informada, valida o palete
		If (U_FtQuery(_cQuery) > 0)
			U_FtWmsMsg("Identificador do produto já está em uso em outro palete!","ATENCAO")
			_lRet := .f.
		EndIf
	EndIf

	// verifica se a etiqueta ja foi lida neste palete
	If (_lRet)
		_cQuery := "SELECT Z07.R_E_C_N_O_ Z07RECNO "
		_cQuery += "FROM " + RetSqlName("Z07") + " Z07 (nolock) "
		_cQuery += "WHERE "+RetSqlCond("Z07")
		_cQuery += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		_cQuery += "AND Z07_ETQPRD = '"+_cEtiqProd+"' "
		_cQuery += "AND Z07_PALLET = '"+_cIdPalete+"' "
		_cQuery += "AND Z07_NRCONT = '"+cNrContagem+"' "
		// status
		_cQuery += "AND Z07_STATUS = 'C' "

		memowrit("c:\query\twmsa012_sfVldProd_3.txt", _cQuery)

		// executa query
		_nRecnoZ07 := U_FtQuery(_cQuery)

		// se a quantidade nao eh informada, valida o palete
		If ( ! _lInfManual).and.(_nRecnoZ07 > 0)
			U_FtWmsMsg("Etiqueta já conferida!","ATENCAO")
			_lRet := .f.
		EndIf
	EndIf

	// valida se a etiqueta do produto ja esta disponivel para conferencia
	If (_lRet)

		// monta query para validar endereco atual do palete
		_cQuery := "SELECT COUNT(*) IT_PRODUTO "
		// composicao do palete
		_cQuery += "FROM " + RetSqlName("Z16") + " Z16 (nolock) "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("Z16")+" "
		// id do palete
		_cQuery += "AND Z16_ETQPAL = '"+_cIdPalete+"' "
		// etiqueta do produto
		_cQuery += "AND Z16_ETQPRD = '"+_cEtiqProd+"' "
		// endereco atual
		_cQuery += "AND Z16_ENDATU = '"+_cDocaSrv+"' "

		memowrit("c:\query\twmsa012_sfVldProd_4.txt", _cQuery)

		// executa query
		If (U_FtQuery(_cQuery) == 0)
			U_FtWmsMsg("Palete não disponível para conferência!","ATENCAO")
			_lRet := .f.
		EndIf
	EndIf

	// valida se ha algum palete em conferencia diferente do lido
	If (_lRet)
		// monta query
		_cQuery := "SELECT COUNT(*) IT_PRODUTO "
		// itens conferidos da OS
		_cQuery += "FROM " + RetSqlName("Z07") + " Z07 (nolock) "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("Z07")+" "
		// numero e sequencia da OS
		_cQuery += "AND Z07_NUMOS   = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		// id palete
		_cQuery += "AND Z07_PALLET != '"+_cIdPalete+"' "
		// nr de contagens
		_cQuery += "AND Z07_NRCONT  = '"+cNrContagem+"' "
		// status
		_cQuery += "AND Z07_STATUS  = 'C' "

		memowrit("c:\query\twmsa012_sfVldProd_5.txt", _cQuery)

		// se a quantidade nao eh informada, valida o palete
		If (U_FtQuery(_cQuery) > 0)
			U_FtWmsMsg("Já existe outro identificador de palete em conferência!","ATENCAO")
			_lRet := .f.
		EndIf
	EndIf

	// tela para informar a quantidade
	If (_lRet)
		sfInfQuant()
	Endif

	// valido se o pallet lido pertence aquela OS
	If (_lRet) .AND. (_nQtdProd > 0)

		// monta query para buscar a informacao do palete na OS
		_cQuery := " SELECT COUNT(*) TOTAL "
		// mapa de separacao
		_cQuery += " FROM " + RetSqlTab("Z08") + " (nolock) "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z08")
		// numero da os
		_cQuery += " AND Z08_NUMOS   = '" + _cNumOrdSrv + "' "
		// id palete
		_cQuery += " AND (CASE WHEN Z08_NEWPLT <> ' ' THEN Z08_NEWPLT ELSE Z08_PALLET END) = '"+_cIdPalete+"' "

		memowrit("c:\query\twmsa012_sfVldProd_6.txt", _cQuery)

		// se não encontrar nada
		If (U_FtQuery(_cQuery) == 0)

			// mensagem
			U_FtWmsMsg("Etiqueta do produto não pertence a essa OS.","ATENCAO")

			// controle de processo
			_lRet := .f.

		EndIf
	EndIf

	//valida os dados informados com o que existe cadastrado no sistema
	If (_lRet)

		// query de validação do uso do volume
		_cQuery := " SELECT Z16.R_E_C_N_O_ Z16RECNO "
		// composicao do palete
		_cQuery += " FROM " + RetSqlTab("Z16") + " (nolock) "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z16")
		// id do palete
		_cQuery += " AND Z16_ETQPAL = '" + _cIdPalete + "' "
		//etiqueta lida
		_cQuery += " AND Z16_ETQPRD = '" +_cEtiqProd + "' "
		//lote informado
		If _lCtrlLot
			_cQuery += " AND Z16_LOTCTL = '" + _cIdLote + "' "
		EndIf
		// somente com saldo
		_cQuery += " AND Z16_SALDO > 0 "

		memowrit("c:\query\twmsa012_sfVldProd_7.txt", _cQuery)

		// atualizo variavel com os dados do volume
		_aDadosVol := U_SqlToVet(_cQuery)

		// se não encontrou registro com os dados bipados e digitados, apresenta erro ao usuario
		If (Len(_aDadosVol) == 0)
			U_FtWmsMsg("A etiqueta de produto lida, com os dados informados, é invpalida. Verifique os dados informados de peso/quantidade e lote!","ATENCAO")
			// variavel de retorno
			_lRet := .F.
		EndIf

	EndIf

	//**********************   FIM DAS VALIDAÇÕES **********************

	// se validou todos os itens até aqui, grava o item conferido
	If (_lRet).and.(_nQtdProd > 0)

		// quando a quantidade é digitada, altera o registro
		If (_lInfManual).and.(_nRecnoZ07 > 0).and.(_nRecnoZ16 > 0)

			dbSelectArea("Z07")
			Z07->(dbGoTo(_nRecnoZ07))
			RecLock("Z07",.f.)
			Z07->Z07_QUANT	:= _nQtdProd
			Z07->(MsUnLock())
		Else
			// insere quantidade lida na relacao de itens
			dbSelectArea("Z07")
			RecLock("Z07",.t.)
			Z07->Z07_FILIAL	:= xFilial("Z07")
			Z07->Z07_NUMOS	:= _cNumOrdSrv
			Z07->Z07_SEQOS	:= _cSeqOrdSrv
			Z07->Z07_CLIENT	:= _cCodCliFor
			Z07->Z07_LOJA	:= _cLojCliFor
			Z07->Z07_ETQPRD	:= _cEtiqProd
			Z07->Z07_PRODUT	:= Z11->Z11_CODPRO
			Z07->Z07_NUMSEQ	:= _cNumSeq
			Z07->Z07_LOCAL	:= _cArmzServ
			Z07->Z07_QUANT	:= _nQtdProd
			Z07->Z07_NRCONT	:= cNrContagem
			Z07->Z07_USUARI	:= _cCodOper
			Z07->Z07_DATA	:= Date()
			Z07->Z07_HORA	:= Time()
			Z07->Z07_PALLET	:= _cIdPalete
			Z07->Z07_UNITIZ := _cCodUnit
			Z07->Z07_STATUS	:= "C" // C-EM CONFERENCIA / D-CONFERIDO/DISPONIVEL / M-EM MOVIMENTO / A-ARMAZENADO
			Z07->Z07_ENDATU	:= _cDocaSrv
			Z07->Z07_PLTCLI	:= _cPltClie
			Z07->Z07_LOTCTL	:= _cIdLote
			Z07->Z07_PEDIDO	:= _cPedido
			Z07->(MsUnLock())
		EndIf

		// atualiza a quantidade de leitura
		RecLock("Z11")
		Z11->Z11_QTDLEI += 1
		MsUnLock()

		// atualiza os dados do browse
		sfSelDados(.t.)

		// reinicia variaveis
		_cCodProd  := Space(nTamCodPrd)
		_cDscProd  := ""
		_cEtiqProd := Space(Len(_cEtiqProd))
		_cIdPalete := Space(_nTamIdPal)
		_cIdLote   := Space(_nTamIdLot)
		_cPltClie  := Space(_nTamPlCli)
		_aColsSum  := {}

	EndIf

	// foca no objeto cod produto
	_oGetCodProd:SetFocus()

Return( .T. )

// ** funcao para informar a quantidade manualmente (para produtos de pequeno porte)
Static Function sfInfQuant()
	// objetos
	local _oBtnFoco1
	// controle para nao fechar a tela
	Local _lRetOk := .f.

	// reinicia segunda unidade de medida
	_nQtdSegUM := 0

	// monta a tela para informa a quantidade
	_oWndInfQuant := MSDialog():New(020,020,220,200,"Informações Adicionais",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlInfQtdCab := TPanel():New(000,000,nil,_oWndInfQuant,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlInfQtdCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpInfQtdOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRetOk := (sfValIndAd("1").and.sfValIndAd("2")), _oWndInfQuant:End() },_oPnlInfQtdCab,"Ok",,.T.)
	_oBmpInfQtdOk:Align := CONTROL_ALIGN_LEFT

	// campos para preenchimento
	_oGetQuant   := TGet():New(033,005,{|u| If(PCount()>0,_nQtdProd:=u,_nQtdProd)},_oWndInfQuant,060,010,PesqPict("SD1","D1_QUANT")  ,{||sfValIndAd("1")}        ,,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nQtdProd",,,,,,,"Quantidade ("+SB1->B1_UM+"):",1)
	_oGetLotProd := TGet():New(055,005,{|u| If(PCount()>0,_cIdLote:=u,_cIdLote)}  ,_oWndInfQuant,060,010,PesqPict("Z07","Z07_LOTCTL"),{||sfValIndAd("2")}        ,,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIdLote",,,,,,,"Lote"                        ,1)
	_oGetPalCli  := TGet():New(075,005,{|u| If(PCount()>0,_cPltClie:=u,_cPltClie)},_oWndInfQuant,060,010,PesqPict("Z07","Z07_PLTCLI"),{||sfValIndAd("3")}        ,,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cPltClie",,,,,,,"Plt. Clie."                  ,1)

	If !(_lInfManual)
		_oGetQuant:Disable()
	EndIf

	If !(_lCtrlLot)
		_oGetLotProd:Disable()
	EndIf

	// ativacao da tela com validacao
	_oWndInfQuant:Activate(,,,.T.,{|| _lRetOk })

Return()


// ** funcao que calcula as unidade de medidas
Static Function sfVldQuant(mvUndRet)

	If (_nQtdProd>0).or.(_nQtdSegUM>0)
		If (!Empty(SB1->B1_SEGUM)).and.(SB1->B1_CONV>0)
			// retorna a 1a Unid Medida
			If (mvUndRet==1)
				// 2a Unid Medida
			ElseIf (mvUndRet==2)
				_nQtdSegUM := ConvUM(SB1->B1_COD,_nQtdProd,_nQtdSegUM,mvUndRet)
			EndIf
		EndIf
	EndIf

Return(.T.)

// ** função para validar Quantidade e Lote
Static Function sfValIndAd(mvCampoVal)

	Local _lRet        := .T.
	Default mvCampoVal := 0 //1=Quantidade | 2= Lote | 3= Palete Cliente


	If mvCampoVal == "1"

		If _lInfManual
			If _nQtdProd <= 0
				_lRet := .F.
				U_FtWmsMsg("Informar Quantidade Maior que 0 !","ATENCAO")
				_oGetQuant:SetFocus()
				Return(_lRet)
			EndIf
		EndIf

		sfVldQuant(2)

	ElseIf mvCampoVal == "2"
		If ( _lCtrlLot .AND. Empty(_cIdLote) )     //se controla lote, mas deixaram o campo em branco
			_lRet := .F.
			U_FtWmsMsg("Obrigatório informar Lote !","ATENCAO")
			_oGetLotProd:SetFocus()
			Return(_lRet)
		EndIf
	ElseIf mvCampoVal == "3"

	EndIf

Return(_lRet)

// ** funcao que retorna o numero de contagens
Static Function sfRetNrCont()
	local _cQuery := ""
	local _cRet := ""

	_cQuery := "SELECT MAX(Z06_NRCONT) Z06_NRCONT "
	_cQuery += "FROM " + RetSqlName("Z06") + " Z06 (nolock)  "
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

// ** funcao que apresenta os detalhes da conferencia
Static Function sfDetConfer()
	// objetos
	local _oWndConfDet
	local _oPnlConfDet
	local _oBmpConsDetSair
	local _oBrwConsDet

	local _aHeadDet := {}
	local _aColsDet := {}
	local _cQuery
	// quantidade total
	local _nQtdTot := 0
	// total de paletes
	local _nTotPalete := 0
	// botão de estorno
	local _oBmpEstorno

	// monta a query
	_cQuery := " SELECT CASE WHEN Z07_STATUS = 'C' THEN '  ' ELSE 'OK' END Z07_STATUS, Z07_PALLET, Z07_ETQPRD, SUM(Z07_QUANT) Z07_QUANT, B1_COD, B1_DESC, Z07_LOTCTL, '.F.' IT_DEL "
	_cQuery += " FROM " + RetSqlTab("Z07") + " (nolock) "
	_cQuery += " INNER JOIN " + RetSqlName("SB1") + " SB1 (nolock) ON " + RetSqlCond("SB1") + " AND B1_COD = Z07_PRODUT "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z07")+" "
	_cQuery += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	_cQuery += " AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
	_cQuery += " AND Z07_NRCONT = '"+cNrContagem+"' "
	_cQuery += " AND Z07_PEDIDO = '"+_cPedido+"' "
	// agrupamento dos dados
	_cQuery += " GROUP BY CASE WHEN Z07_STATUS = 'C' THEN '  ' ELSE 'OK' END, Z07_PALLET, Z07_ETQPRD, B1_COD, B1_DESC, Z07_LOTCTL "
	// ordem dos dados
	_cQuery += " ORDER BY Z07_PALLET, Z07_ETQPRD "

	memowrit("C:\query\TWSMA012_sfDetConfer.txt",_cQuery)

	// atualiza o vetor do browse
	_aColsDet := U_SqlToVet(_cQuery)

	// calcula a quantidade total
	aEval(_aColsDet,{|x| _nQtdTot += x[4] , _nTotPalete ++ })

	// adiciona a linha com o total
	aAdd(_aColsDet,{"","","TOTAL"    ,_nQtdTot      ,"","","",.f.})
	aAdd(_aColsDet,{"","","TOTAL PLT",_nTotPalete   ,"","","",.f.})

	// define o header
	aAdd(_aHeadDet,{"Sts"        , "Z07_STATUS", ""         , 2                      ,0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Id Palete"  , "Z07_PALLET", ""         , TamSx3("Z07_PALLET")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Etq Produto", "Z07_ETQPRD", ""         , TamSx3("Z07_ETQPRD")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Quant"      , "Z07_QUANT" , _cMaskQuant, TamSx3("Z07_QUANT")[1] ,TamSx3("Z07_QUANT")[2],Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Produto"    , "B1_COD"    , ""         , TamSx3("B1_COD")[1]    ,0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Desc Prod"  , "B1_DESC"   , ""         , TamSx3("B1_DESC")[1]   ,0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Lote"       , "Z07_LOTCTL", ""         , TamSx3("Z07_LOTCTL")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })

	// monta o dialogo do monitor
	_oWndConfDet := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Detalhes",,,.F.,,,,,,.T.,,,.T. )
	_oWndConfDet:lEscClose := .F.

	// cria o panel do cabecalho - botoes
	_oPnlConfDet := TPanel():New(000,000,nil,_oWndConfDet,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlConfDet:Align:= CONTROL_ALIGN_TOP

	// -- BOTAO DE ESTORNO
	_oBmpEstorno := TBtnBmp2():New(000,000,030,022,"ESTOMOVI",,,,{|| If( sfEstornoPlt(_oBrwConsDet:aCols[_oBrwConsDet:nAt][2]), _oWndConfDet:End(), Nil) },_oPnlConfDet,"Estornar conferência",,.T.)
	_oBmpEstorno:Align := CONTROL_ALIGN_LEFT
	// -- BOTAO DE SAIDA
	_oBmpConsDetSair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _oWndConfDet:End() },_oPnlConfDet,"Sair",,.T.)
	_oBmpConsDetSair:Align := CONTROL_ALIGN_RIGHT

	// monta o browse com os motivos de interrupcoes
	_oBrwConsDet := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDet),'AllwaysTrue()','','AllwaysTrue()',_oWndConfDet,_aHeadDet,_aColsDet)
	_oBrwConsDet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa o dialogo
	_oWndConfDet:Activate(,,,.F.,,,)

Return(.t.)

// ** funcao para realizar a finalizacao/encerramento total do servico de conferencia da OS
Static Function sfFinalizaOS(mvTela,mvOk)

	// objetos locais
	local _oWndConFinal
	local _oPnlCfeFinCab1, _oPnlCfeFinCab2
	local _oBmpCfeFinConf, _oBmpCfeFechar
	local _oSayStatus, _oSayTotPB, _oSayTotCB, _oSayTotVL, _oSayTotPL
	local _oBrwFinaliza

	// variaveis temporarias
	Local _cQryConf := ""
	Local cNewAlias := GetNextAlias()
	Local nX := 0
	Local nSaldoCtg := 0
	Local cTmpCodPro := ""

	// area atual
	Local aAreaAtu := GetArea()

	// estrutura do arquivo de trabalho e Browse
	Local aEstBrowse := {}
	Local aHeadBrowse := {}
	Local cMarca := Z07->(GetMark())

	// controle de divergencias
	Local _lDiverg := .f.

	// informacoes do resumo
	local _nTotPesoB  := 0
	local _nTotCubag  := 0
	local _nTotVolume := 0
	local _nTotPalete := 0

	// controle de confirmacao da tela
	local _lOk := .f.

	// cores da legenda
	local _aCorLeg := {}

	Private cArqTmp
	Private _TRBCNF := GetNextAlias()

	// adiciona as cores da legenda
	aAdd(_aCorLeg,{"Empty((_TRBCNF)->IT_COR)"   ,"DISABLE"})
	aAdd(_aCorLeg,{"!(Empty((_TRBCNF)->IT_COR))","ENABLE" })

	// confirmacao do processamento
	If ( ! U_FtYesNoMsg("Finalizar conferência?") )
		Return( .F. )
	EndIf

	// verifica se tem mais usuarios na mesma contagem em conferencia
	_cQryConf := " SELECT COUNT(*) QTD_ITENS FROM " + RetSqlTab("Z07") + " (nolock) "
	_cQryConf += " WHERE "+RetSqlCond("Z07")
	_cQryConf += " AND Z07_NUMOS   = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	_cQryConf += " AND Z07_NRCONT  = '"+cNrContagem+"' "
	// somente disponiveis
	_cQryConf += " AND Z07_STATUS  = 'C' "
	_cQryConf += " AND Z07_USUARI != '"+_cCodOper+"' "

	// executa a query de verificacao
	If (U_FtQuery(_cQryConf)>0)
		U_FtWmsMsg("Existem Operadores com conferência em aberto. Favor verificar antes de prosseguir.", "Finalizar")
		Return(.f.)
	EndIf

	// verifica se ha algum palete nao finalizado
	_cQryConf := " SELECT COUNT(*) QTD_ITENS FROM " + RetSqlTab("Z07") + " (nolock) "
	_cQryConf += " WHERE "+RetSqlCond("Z07")
	_cQryConf += " AND Z07_NUMOS   = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	_cQryConf += " AND Z07_NRCONT  = '"+cNrContagem+"' "
	// somente disponiveis
	_cQryConf += " AND Z07_STATUS  = 'C' "

	// executa a query de verificacao
	If (U_FtQuery(_cQryConf)>0)
		U_FtWmsMsg("Há paletes com conferência não finalizada!", "Finalizar")
		Return(.f.)
	EndIf

	// fecha o alias
	If (Select(cNewAlias)!=0)
		dbSelectArea(cNewAlias)
		dbCloseArea()
	EndIf

	// query para verificacao/analise da divergencia
	_cQryConf := " SELECT '  ' IT_OK, 'OK' IT_COR, "
	_cQryConf += " Z05_CARGA, "
	_cQryConf += " Z06_NRCONT, Z06_LOCAL, Z06_ENDSRV, C6_PRODUTO IT_PRODUTO, B1_DESC, B1_UM, "
	_cQryConf += " Sum(Isnull(Z45_QUANT, C6_QTDVEN)) C6_QTDVEN, "

	// quantidade conferida por produto
	_cQryConf += " ("
	_cQryConf += "  SELECT ISNULL(SUM(Z07_QUANT),0) FROM " + RetSqlName("Z07") + " Z07 (nolock)  "
	_cQryConf += "  WHERE "+RetSqlCond("Z07")+" "
	_cQryConf += "  AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	_cQryConf += "  AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
	_cQryConf += "  AND Z07_NRCONT = Z06_NRCONT "
	_cQryConf += "  AND Z07_PRODUT = C6_PRODUTO "
	_cQryConf += "  AND Z07_STATUS = 'D' "
	_cQryConf += "  AND Z07_LOTCTL = ISNULL(Z45_LOTCTL, C6_LOTECTL) "
	_cQryConf += " ) Z07_QUANT, "

	// peso bruto
	_cQryConf += " SUM(ISNULL(B1_PESBRU * C6_QTDVEN,0)) TOT_PESBRU, "

	// cubagem/m3
	_cQryConf += " SUM(ISNULL((B5_COMPRLC * B5_LARGLC * B5_ALTURLC) * C6_QTDVEN,0)) TOT_CUBAGE, "

	// quantidade de paletes da conferência
	_cQryConf += " ("
	_cQryConf += "  SELECT ISNULL(COUNT(DISTINCT Z07_PALLET),0) FROM " + RetSqlName("Z07") + " Z07 (nolock)  "
	_cQryConf += "  WHERE "+RetSqlCond("Z07")+" "
	_cQryConf += "  AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	_cQryConf += "  AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
	_cQryConf += "  AND Z07_NRCONT = Z06_NRCONT "
	_cQryConf += "  AND Z07_PRODUT = C6_PRODUTO "
	_cQryConf += "  AND Z07_STATUS = 'D' "
	_cQryConf += "  AND Z07_LOTCTL = ISNULL(Z45_LOTCTL, C6_LOTECTL) "
	_cQryConf += " ) QTD_PLTZ07, "

	// quantidade de paletes do apanhe
	_cQryConf += " (SELECT Isnull(Count(DISTINCT Z08_PALLET), 0) FROM " + RetSqlTab("Z08") + " (nolock) "
	_cQryConf += "         WHERE " + RetSqlCond("Z08")
	_cQryConf += "                AND Z08_NUMOS = '" + _cNumOrdSrv + "'"
	_cQryConf += "                AND Z08_PRODUT = C6_PRODUTO                                                "
	_cQryConf += "                AND Z08_STATUS = 'R'                                                       "
	_cQryConf += "                AND Z08_LOTCTL = Isnull(Z45_LOTCTL, C6_LOTECTL))            QTD_PLTZ08,"

	// saldo da contagem por produto
	_cQryConf += " 0 IT_SALDO, "

	// campos para controle de devolucoes/sobras
	_cQryConf += " 0 IT_QTDDEVO, 0 IT_QTDSOBR, "

	// lote
	_cQryConf += "        Isnull(Z45_LOTCTL, C6_LOTECTL) Z45_LOTCTL "

	// cabecalho da OS
	_cQryConf += " FROM " + RetSqlTab("Z05") + " (nolock) "

	// pedidos da carga
	_cQryConf += "        INNER JOIN " + RetSqlTab("DAI") + " (nolock) "
	_cQryConf += "                ON "+RetSqlCond("DAI")
	_cQryConf += "                   AND DAI_COD = Z05_CARGA "
	_cQryConf += "                   AND DAI_PEDIDO = '"+_cPedido+"' "

	// itens do pedido de venda
	_cQryConf += " INNER JOIN " + RetSqlTab("SC6") + " (nolock) ON " + RetSqlCond("SC6") + " AND C6_NUM = DAI_PEDIDO "

	// itens da OS
	_cQryConf += " INNER JOIN " + RetSqlTab("Z06") + " (nolock) ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z05_NUMOS "
	_cQryConf += " AND Z06_SERVIC = '"+cCodServ+"' AND Z06_TAREFA = '"+cCodTaref+"' "

	// reserva de lotes
	_cQryConf += "        LEFT JOIN " + RetSqlTab("Z45") + " (nolock) "
	_cQryConf += "               ON "+RetSqlCond("Z45")
	_cQryConf += "                  AND Z45_PEDIDO = C6_NUM "
	_cQryConf += "                  AND Z45_ITEM = C6_ITEM "
	_cQryConf += "                  AND Z45_CODPRO = C6_PRODUTO "

	// cad. de produtos
	_cQryConf += " INNER JOIN " + RetSqlTab("SB1") + " (nolock) ON " + RetSqlCond("SB1") + " AND B1_COD = C6_PRODUTO "

	// complemento de produtos
	_cQryConf += " LEFT  JOIN " + RetSqlTab("SB5") + " (nolock) ON " + RetSqlCond("SB5") + " AND B5_COD = C6_PRODUTO "

	// filtra o cabecalho da OS
	_cQryConf += " WHERE "+RetSqlCond("Z05")
	_cQryConf += " AND Z05_NUMOS  = '"+_cNumOrdSrv+"' "
	_cQryConf += " AND Z05_CLIENT = '"+_cCodCliFor+"' AND Z05_LOJA  = '"+_cLojCliFor+"' "

	// agrupa os dados
	_cQryConf += " GROUP  BY Z05_CARGA, "
	_cQryConf += "           C6_NUM, "
	_cQryConf += "           Z06_NRCONT, "
	_cQryConf += "           Z06_LOCAL, "
	_cQryConf += "           Z06_ENDSRV, "
	_cQryConf += "           C6_PRODUTO, "
	_cQryConf += "           B1_DESC, "
	_cQryConf += "           B1_UM, "
	_cQryConf += "           Z45_LOTCTL, "
	_cQryConf += "           C6_LOTECTL "

	memowrit("c:\QUERY\twmsa012_sfFinalizaOS.txt",_cQryConf)

	// executa query
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

	// erro nos dados
	If ((_TRBCNF)->(Eof()))
		U_FtWmsMsg("Nenhum palete conferido.","ATENCAO")
		Return( .F. )
	EndIf

	// verifica itens com divergencia
	(_TRBCNF)->(dbSelectArea(_TRBCNF))
	(_TRBCNF)->(dbGoTop())

	// TODO - tratar as divergências diretamente no SQL para melhorar performance

	// análise das divergências
	While (_TRBCNF)->(!Eof())

		// edita registro
		(_TRBCNF)->(RecLock(_TRBCNF, .F. ))
		// valida o saldo do item
		(_TRBCNF)->IT_SALDO	:= (_TRBCNF)->Z07_QUANT
		(_TRBCNF)->IT_OK		:= IIf(((_TRBCNF)->Z07_QUANT != (_TRBCNF)->C6_QTDVEN) .OR. ((_TRBCNF)->QTD_PLTZ07 != (_TRBCNF)->QTD_PLTZ08), cMarca, Space(2))
		(_TRBCNF)->IT_COR		:= IIf(((_TRBCNF)->Z07_QUANT != (_TRBCNF)->C6_QTDVEN) .OR. ((_TRBCNF)->QTD_PLTZ07 != (_TRBCNF)->QTD_PLTZ08), Space(2), cMarca)
		// calcula devolucoes
		(_TRBCNF)->IT_QTDDEVO	:= IIf((_TRBCNF)->Z07_QUANT < (_TRBCNF)->C6_QTDVEN, (_TRBCNF)->C6_QTDVEN - (_TRBCNF)->Z07_QUANT, 0)
		// calcula sobras
		(_TRBCNF)->IT_QTDSOBR	:= IIf((_TRBCNF)->Z07_QUANT > (_TRBCNF)->C6_QTDVEN, (_TRBCNF)->Z07_QUANT - (_TRBCNF)->C6_QTDVEN, 0)
		(_TRBCNF)->(MsUnLock())

		// verifica se tem divergencias
		If (!Empty((_TRBCNF)->IT_OK))
			_lDiverg := .T.
		EndIf

		// atualiza variaveis do resumo
		_nTotPesoB  += (_TRBCNF)->TOT_PESBRU
		_nTotCubag  += (_TRBCNF)->TOT_CUBAGE
		_nTotVolume += (_TRBCNF)->Z07_QUANT
		_nTotPalete += (_TRBCNF)->QTD_PLTZ07

		// proximo item
		(_TRBCNF)->(dbSkip())
	EndDo

	// abre o arquivo de trabalho
	(_TRBCNF)->(dbSelectArea(_TRBCNF))
	(_TRBCNF)->(dbGoTop())

	// inclui detalhes e titulos dos campos do browse
	aAdd(aHeadBrowse,{"IT_OK"       ,"@!"                        ,"  "              })
	aAdd(aHeadBrowse,{"Z05_CARGA"   ,"@!"                        ,"Carga"           })
	aAdd(aHeadBrowse,{"IT_PRODUTO"  ,"@!"                        ,"Cód. Produto"    })
	aAdd(aHeadBrowse,{"B1_DESC"     ,"@!"                        ,"Descrição"       })
	aAdd(aHeadBrowse,{"B1_UM"       ,"@!"                        ,"Und.Med."        })
	aAdd(aHeadBrowse,{"C6_QTDVEN"   ,PesqPict("SC6","C6_QTDVEN") ,"Qtd.PV"          })
	aAdd(aHeadBrowse,{"Z07_QUANT"   ,PesqPict("Z07","Z07_QUANT") ,"Qtd.Conferida"   })
	aAdd(aHeadBrowse,{"TOT_PESBRU"  ,PesqPict("SF1","F1_PBRUTO") ,"Peso Bruto Total"})
	aAdd(aHeadBrowse,{"TOT_CUBAGE"  ,PesqPict("SF1","F1_CUBAGEM"),"Cubagem Total"   })
	aAdd(aHeadBrowse,{"Z45_LOTCTL"  ,"@!"                        ,"Lote"            })
	aAdd(aHeadBrowse,{"QTD_PLTZ07"  ,"@!"                        ,"Qtd Plt Conf"    })
	aAdd(aHeadBrowse,{"QTD_PLTZ08"  ,"@!"                        ,"Qtd Plt Apanhe"  })

	// monta a tela com os detalhes da finalizacao total da OS
	_oWndConFinal := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Conf. Mercadoria (Expedição)",,,.F.,,,,,,.T.,,,.T. )
	_oWndConFinal:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlCfeFinCab1 := TPanel():New(000,000,nil,_oWndConFinal,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlCfeFinCab1:Align:= CONTROL_ALIGN_TOP

	// INICIO - define os botoes de operacao  =====

	// define o botao para finalizar a conferencia
	// botão só é aparente quando não há divergências
	If ( ! _lDiverg )
		_oBmpCfeFinConf := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| MsgRun("Aguarde. Selecionando Dados...",,{|| _lOk := sfFinServico(@_oWndConFinal) }) },_oPnlCfeFinCab,"Finaliza a Conferência",,.T. )
		_oBmpCfeFinConf:Align := CONTROL_ALIGN_LEFT
	EndIf
	// -- BOTAO PARA FECHAR A TELA
	_oBmpCfeFechar := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| _oWndConFinal:End() },_oPnlCfeFinCab,"Sair",,.T. )
	_oBmpCfeFechar:Align := CONTROL_ALIGN_RIGHT

	// resumo da operacao
	_oPnlCfeFinCab2 := TPanel():New(000,000,nil,_oWndConFinal,,.F.,.F.,,,048,048,.T.,.F.)
	_oPnlCfeFinCab2:Align:= CONTROL_ALIGN_TOP

	// status conferencia
	_oSayStatus := TSay():New(003,004,{||"Status: "+If(_lDiverg,"DIVERGÊNCIAS","OK") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.,If(_lDiverg,CLR_HRED,CLR_GREEN) )
	// total PESO BRUTO
	_oSayTotPB  := TSay():New(010,004,{||"PESO BRUTO: "+Transf(_nTotPesoB,"@E 999,999.999") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)
	// total CUBAGEM
	_oSayTotCB  := TSay():New(017,004,{||"CUBAGEM: "+Transf(_nTotCubag,"@E 999,999.999") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)
	// total VOLUMES
	_oSayTotVL  := TSay():New(024,004,{||"VOLUMES: "+Transf(_nTotVolume,"@E 999,999,999") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)
	// total PALETES
	_oSayTotPL  := TSay():New(031,004,{||"TOTAL PLT CONFERIDO:"+Transf(_nTotPalete,"@E 999,999,999") },_oPnlCfeFinCab2,,_oFnt02,.F.,.F.,.F.,.T.)

	// browse com a listagem dos produtos conferidos
	_oBrwFinaliza := MsSelect():New( _TRBCNF,"IT_OK",,aHeadBrowse,,cMarca,{15,1,183,373},,,,,_aCorLeg)
	_oBrwFinaliza:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oWndConFinal

	// atualiza variaveis da tela de conferencia
	If (_lOk)
		mvOk := .t.
		mvTela:End()
	EndIf

	// fecha arquivo de trabalho
	cArqTmp:Delete()

	// restaura area inicial
	RestArea(aAreaAtu)

Return(.t.)

// ** funcao que encerra o servico de conferencia
Static Function sfFinServico(mvWndConFinal)
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z05","Z06","SD1"})

	// variavel de retorno
	local _lRet := .t.

	Local _cQryArmaz
	local _cQryPallet

	// retorna o próximo serviço
	local _aPrxServico := {}

	// itens para devolucao (veio a menos)
	Local _aDevolucao := {}
	local _cItemDB, _nModOld, _cModOld
	local _aCabSDA, _aItemSDB

	Local aDadosSD1 := 0
	Local aItemDevol := {}

	// itens que sobraram (veio a mais)
	Local aSobras := {}

	// data e hora de emissao
	local _dDtEmissao := Date()
	local _cHrEmissao := Time()

	// variaveis do pedido de venda
	Local _aCabSC5 := {}
	Local _aItensSC6 := {}
	Local _aTmpItem := {}

	// variável que receberá o end serviço da seq anterior
	Local _cEndSrvAnt := ""
	// variável que receberá a query do endereço
	Local _cQryEndAnt := ""

	//Variavel controla finalizar OS sem documento Fiscal.
	Local _lLibeSNF := .F.

	// variavel de query para Z07
	local _cUpdZ07 := ""

	//Valida se Cliente pode finalizar a OS sem Documento Fiscal.
	_lLibeSNF := U_FtWmsParam("WMS_LIBERA_CARREGAMENTO_SEM_NF","L",.f.,.f.,"", _cCodCliFor, _cLojCliFor, nil, nil)

	// retorna o proximo servico, tarefa e atividades planejada da OS
	// 1-Num OS
	// 2-Seq OS
	// 3-Cod Servico
	// 4-Dsc Servico
	// 5-Cod Tarefa
	// 6-Dsc Tarefa
	// 7-Atualiza Estoque
	If (_lLibeSNF)
		_aPrxServico := U_FtPrxSrv(_cNumOrdSrv,_cSeqOrdSrv,_cCodCliFor,_cLojCliFor)
	EndIf

	// abre o arquivo de trabalho com o resultado da conferencia
	(_TRBCNF)->(dbSelectArea(_TRBCNF))
	(_TRBCNF)->(dbGoTop())

	// se todo o processo ocorreu corretamente
	If (_lRet)

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
		SC5->( dbSeek( xFilial("SC5")+_cPedido ))

		// atualiza status de conferencia/montagem de volumes
		RecLock("SC5")
		SC5->C5_ZMNTVOL := "S"
		SC5->(MsUnLock())

		//se o parametro WMS_LIBERA_CARREGAMENTO_SEM_NF for falso, então significa que devemos liberar
		//o pedido de venda para faturamento neste momento
		IF (!_lLibeSNF)
			// liberacao do pedido de venda
			StaticCall (TWMSA024, sfLibPedVen, .F., _cPedido, _cDocaSrv, _cArmzServ )
		EndIf

		// atualiza o status do servico para FI-FINALIZADO
		U_FtWmsSta(_cCodStatus, "FI", _cNumOrdSrv, _cSeqOrdSrv) 

		// libera novo serviço
		// pesquisa o proximo item da OS
		If (len(_aPrxServico) > 0)

			dbSelectArea("Z06")
			Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
			If ! Z06->(dbSeek( xFilial("Z06")+_cNumOrdSrv+_aPrxServico[1,2] ))
				U_FtWmsMsg("Erro na liberação da próxima atividade da OS!","ATENCAO")
				Return(.f.)
			EndIf

			// atualiza o proximo item da OS - libera sequencia
			If (Z06->Z06_STATUS=="PL")
				RecLock("Z06")
				Z06->Z06_ENDSRV := _cDocaSrv
				Z06->Z06_DTEMIS := date()
				Z06->Z06_HREMIS := time()
				Z06->Z06_STATUS := "AG"
				Z06->Z06_PRIOR  := "99"
				MsUnLock()
			EndIf

		EndIf

		// fecha a tela principal
		mvWndConFinal:End()
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni,.t.)
	RestArea(_aArea)

Return(_lRet)

// ** funcao para interromper o servico atual
Static Function sfInterromper(mvTela,mvTelaOk)
	If (!MsgYesNo("Interromper?","ATENÇÃO"))
		Return(.f.)
	EndIf
	// funcao generica para interromper atividade
	U_FtWmsMtInt(_cNumOrdSrv, _cSeqOrdSrv)
	mvTelaOk := .t.
	mvTela:End()
Return(.t.)

// ** funcao para gerar um novo palete
Static Function sfNovoPalete()
	// script para update
	local _cUpdZ07, _cUpdZ16
	local _nX
	// aCols temporaria
	local _aTmpCols := aClone(_oBrwConfExpe:aCols)
	// posicao do campo ID Palete
	local _nPosIdPlt  := aScan(_aHeadConf,{|x| (AllTrim(x[2]) == "Z07_PALLET" ) })
	// posicao do campo etiqueta produto
	local _nPosEtqPrd := aScan(_aHeadConf,{|x| (AllTrim(x[2]) == "Z07_PRODUT" ) })

	// mensagem de confirmacao
	If ( ! U_FTYesNoMsg("Confirma novo palete ?"))
		Return(.f.)
	EndIf

	// varre todos os itens do browse
	For _nX := 1 to Len(_aTmpCols)

		// finaliza os itens conferidos
		_cUpdZ07 := "UPDATE "+RetSqlName("Z07")+" "
		// status finalizado
		_cUpdZ07 += "SET Z07_STATUS = 'D' "
		// filtro padrao
		_cUpdZ07 += "WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
		// filtro da OS especifica
		_cUpdZ07 += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
		_cUpdZ07 += "AND Z07_NRCONT = '"+cNrContagem+"' "
		_cUpdZ07 += "AND Z07_USUARI = '"+_cCodOper+"' "
		// status C=EM CONFERENCIA
		_cUpdZ07 += "AND Z07_STATUS = 'C' "
		// id palete
		_cUpdZ07 += "AND Z07_PALLET = '"+_aTmpCols[_nX][_nPosIdPlt]+"' "
		// etiqueta produto
		_cUpdZ07 += "AND Z07_PRODUT = '"+_aTmpCols[_nX][_nPosEtqPrd]+"' "

		// executa o update
		TcSQLExec(_cUpdZ07)

		// atualiza pedido e carga dos itens do componente do palete atual
		_cUpdZ16 := " UPDATE "+RetSqlName("Z16")+" "
		// carga e pedido
		_cUpdZ16 += " SET Z16_CARGA = '" +_cNrCarga+ "', Z16_PEDIDO = '" +_cPedido+ "' "
		// filtro padrao
		_cUpdZ16 += " WHERE Z16_FILIAL = '"+xFilial("Z16")+"' AND D_E_L_E_T_ = ' ' "
		// id palete
		_cUpdZ16 += " AND Z16_ETQPAL = '"+_aTmpCols[_nX][_nPosIdPlt]+"' "
		// etiqueta produto
		_cUpdZ16 += " AND Z16_CODPRO = '"+_aTmpCols[_nX][_nPosEtqPrd]+"' "
		// com saldo
		_cUpdZ16 += " AND Z16_SALDO != 0 "
		// endereco atual
		_cUpdZ16 += " AND Z16_ENDATU = '"+_cDocaSrv+"' "

		// executa o update
		TcSQLExec(_cUpdZ16)

	Next _nX

	// atualiza variaveis
	_lNovoPalete := .t.
	_cEtiqProd   := Space(Len(_cEtiqProd))
	_cCodProd    := Space(nTamCodPrd)
	_nQtdProd    := 1
	_cIdPalete   := Space(_nTamIdPal)

	// atualiza os dados
	sfSelDados(.t.)

	// atualiza o objeto para receber o foco
	_oGetCodProd:SetFocus()

Return(.t.)

// ** funcao para estorno do palete
Static Function sfEstornoPlt(mvIdPltEst)
	// query
	local _cQryZ07, _cUpd
	// variaveis temporarias
	local _aTmpRecno := {}
	local _nX
	// variavel de retorno
	local _lRet := .f.

	// valida id do palete
	If (Empty(mvIdPltEst))
		// mensagem
		U_FtWmsMsg("Não há palete para estorno!","ATENCAO")
		Return(_lRet)
	EndIf

	If ( ! U_FtYesNoMsg("Estorna palete " + mvIdPltEst + " ?"))
		Return(_lRet)
	EndIf

	// monta SQL para estornar o palete
	_cQryZ07 := " SELECT Z07.R_E_C_N_O_ Z07RECNO "
	// itens em conferencia
	_cQryZ07 += " FROM " + RetSqlTab("Z07") + " (nolock) "
	// filtro padrao
	_cQryZ07 += " WHERE "+RetSqlCond("Z07")
	// filtro por OS
	_cQryZ07 += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	_cQryZ07 += " AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA = '"+_cLojCliFor+"' "
	_cQryZ07 += " AND Z07_NRCONT = '"+cNrContagem+"' "
	_cQryZ07 += " AND Z07_PALLET = '"+mvIdPltEst+"' "
	// status C=EM CONFERENCIA
	_cQryZ07 += " AND Z07_STATUS IN ('C','D') "
	// alimenta o vetor
	_aTmpRecno := U_SqlToVet(_cQryZ07)

	memowrit("C:\query\twmsa012_sfEstornoPlt.txt",_cQryZ07)

	BEGIN TRANSACTION

		// varre todos os recno
		For _nX := 1 to Len(_aTmpRecno)
			// posiciona no registro real
			dbSelectArea("Z07")
			Z07->(dbGoTo( _aTmpRecno[_nX] ))

			// apaga conferência
			RecLock("Z07")
			Z07->(dbDelete())
			Z07->(MsUnLock())

			// atualiza variavel de retorno
			_lRet := .t.
		Next _nX
	End Transaction

	If (_lRet)
		U_FtWmsMsg("Estorno realizado com sucesso!","ATENCAO")
		sfSelDados( .T. )
	EndIf

Return(_lRet)


// ** funcao que pesquisa o palete pela etiquetad do produto
Static Function sfRetNrPalete(mvIdEtqPrd)
	local _cRetIdPal := Space(Len(mvIdEtqPrd))
	local _cQryPlt

	_cQryPlt := "SELECT DISTINCT Z16_ETQPAL "
	// composicao de palete
	_cQryPlt += "FROM " + RetSqlName("Z16") + " Z16 (nolock)  "
	// filtro padrao
	_cQryPlt += "WHERE "+RetSqlCond("Z16")+" "
	_cQryPlt += "AND Z16_ETQPRD = '"+mvIdEtqPrd+"' "
	// executa a query
	_cRetIdPal := U_FtQuery(_cQryPlt)

	If (Empty(_cQryPlt))
		U_FtWmsMsg("Etiqueta não encontrada!","ATENCAO")
	EndIf

Return(_cRetIdPal)

// ** funcao que retorna o ID do palete quando interrompido
Static Function sfRetPltInt()
	local _cRetIdPlt := ""
	local _cQryZ07

	// monta query para buscar algum palete que nao foi finalizado
	_cQryZ07 := " SELECT DISTINCT Z07_PALLET "
	// itens de conferencia
	_cQryZ07 += " FROM " + RetSqlTab("Z07") + " (nolock) "
	// filtro padrao
	_cQryZ07 += " WHERE " + RetSqlCond("Z07")
	// filtro por OS
	_cQryZ07 += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	_cQryZ07 += " AND Z07_CLIENT = '"+_cCodCliFor+"'  AND Z07_LOJA  = '"+_cLojCliFor+"' "
	_cQryZ07 += " AND Z07_NRCONT = '"+cNrContagem+"' "
	_cQryZ07 += " AND Z07_USUARI = '"+_cCodOper+"' "
	// status / C=EM CONFERENCIA
	_cQryZ07 += " AND Z07_STATUS = 'C' "

	// executa a query
	_cRetIdPlt := U_FtQuery(_cQryZ07)

	// atualiza variavel ID do palete
	If ( ! Empty(_cRetIdPlt))
		_cIdPalete := _cRetIdPlt
	EndIf

Return


// ** função que permite encerrar a sequencia de conferência de carregamento, caso todos os pedidos estejam aptos
Static Function sfFimOS()

	local _nQtd     := 0
	local _cQuery   := ""
	local _lRet     := .F.

	//pede confirmação
	If ( ! MsgYesNo("Deseja encerrar a conferência de carregamento da carga " + Z05->Z05_CARGA + " ?"))
		Return( .F. )
	EndIf

	// finaliza OS somente quando todos os pedidos estiverem com os volumes montados
	_cQuery := "SELECT COUNT(*) QTD_PEND "
	// pedidos de venda
	_cQuery += "FROM " + RetSqlTab("SC5") + " (nolock) "
	// filtro padrao
	_cQuery += "WHERE " + RetSqlCond("SC5") + " "
	// cliente, loja e tipo de operacao
	_cQuery += "AND C5_CLIENTE = '" + Z05->Z05_CLIENT + "' AND C5_LOJACLI = '" + Z05->Z05_LOJA + "' AND C5_TIPOOPE = 'P' "
	// numero da carga/agrupadora
	_cQuery += "AND C5_ZCARGA = '" + Z05->Z05_CARGA + "' "
	// status da montagem de volume
	_cQuery += "AND C5_ZMNTVOL <> 'S' "

	memowrit("C:\query\twmsa012_sfFinaliza.txt",_cQuery)

	// joga os dados pro array
	_nQtd := U_FtQuery(_cQuery)

	//se permite finalizar (todos os pedidos foram montados)
	If (_nQtd == 0)
		// atualiza o status do servico para FI-FINALIZADO
		U_FtWmsSta(Z06->Z06_STATUS,;
		"FI"        ,;
		Z06->Z06_NUMOS ,;
		Z06->Z06_SEQOS  )

		//sai do loop principal
		_lContConf := .F.

		//retorna sucesso
		_lRet := .T.

	Else
		Alert("Existem " + AllTrim(Str(_nQtd)) + " pedidos ainda não conferidos para esta carga!")
	EndIf

Return (_lRet)

