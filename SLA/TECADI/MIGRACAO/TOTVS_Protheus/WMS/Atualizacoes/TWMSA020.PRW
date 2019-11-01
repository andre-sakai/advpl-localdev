#include "totvs.ch"
#include "Protheus.ch"
#include "TopConn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para conferencia de mercadoria no processo de    !
!                  ! carregamento (na "porta do caminhão")                   !
!                  ! - Chamada a partir da rotina TACDA002                   !
+------------------+---------------------------------------------------------+
!Autor             ! David                       ! Data de Criacao ! 07/2013 !
+------------------+--------------------------------------------------------*/

User Function TWMSA020(mvQryUsr)

	// controle de confirmacao de tela
	local _lRet := .F.

	// conteudo o parametro do controle de tipo de carregamento
	local _cTipoCarreg := ""

	// quantidade de OS
	local _aOrdSrvPend := {}

	// query
	local _cQuery

	// planejamento de carregamento
	local _aRecnoZ43 := {}
	local _nRecZ43   := 0

	local _cTmpOS    := ""   // variável temporária para guardar o resultado da consulta se existe uma OS de carregamento anterior
	local _lGeraOS   := .T.  // informa se deve gerar uma nova OS de carregamento

	// controle por volume
	private _lCtrVolume := .F.

	// tipo de etiqueta
	private _cTpIdEtiq := ""

	// habilita carregamento sem NF emitida
	private _lCESVSemNf := .F.

	// container da operação
	private _cContainer := CriaVar("ZZ_CNTR01", .F.)

	// numeros dos pedidos
	private _cAllPedidos := ""
	private _cPedUnico   := ""

	// numero carga / agrupadora
	Private _cAllCargas := ""
	private _cCargaUnic := ""

	// numero da movimentacao do veiculo
	private _cNumCESV := CriaVar("ZZ_CESV", .F.)

	//Variável para verificar se preenche quantidade
	Private _lInfManual  := .F.

	// controle por tipo de carregamento
	private _lPorCarga  := .F.
	private _lPorPedido := .F.

	// codigo do cliente
	Private _cCodServ    := "001/002"
	Private _cCodTaref   := "004"
	private _cNumOrdSrv  := ""
	private _cNrOSUnica  := ""
	Private _cCodCliFor  := ""
	Private _cLojCliFor  := ""

	// mascara para campos quantidade
	private _cMaskQuant := U_FtWmsParam("WMS_MASCARA_CAMPO_QUANTIDADE", "C", PesqPict("SD1","D1_QUANT"), .F., "", Nil, Nil, Nil, Nil)

	// permite o carregamento sem a nota fiscal de venda do cliente
	private _lSemNfVend := .F.

	// tipo de identificacao
	private _lEtqIdInt  := .F.
	private _lEtqIdEAN  := .F.
	private _lEtqIdDUN  := .F.
	private _lEtqCod128 := .F.
	private _lEtqClient := .F.

	// define quantidade de caracteres da etiqueta do cliente
	private _nTamEtqCli := 0

	// codigo de barras para leitura
	private _cEtqCodBar := ""

	// mascara para codigo de barras
	private _cMskCodBar := PesqPict("SB1","B1_CODBAR")

	// controle de unica ordem de servico para carregamento (nova versao)
	private _lNrOSUnica := .F.

	// codigos do servico em sintaxe SQL
	Private _cSqlCodSrv := FormatIn(_cCodServ, "/")

	// versao do processo de carregamento (1-Planeja Carregamento com Mapa de Separacao | 2-Ordem de Servico de Carregamento Independente das demais)
	private _nVersCarreg := 0

	// se processo de integração de sistema Sumitomo (barcode) está ativa
	Private lSumiBar := ""

	// array de controle etiquetas Sumitomo
	private _aColsSum	:= {}

	// valida se ha equipamento informado
	If ( ! Empty(_cCodEquip) )
		// mensagem
		U_FtWmsMsg("No processo de conferência não é necessário equipamento!","ATENCAO")
		// retorno
		Return(.F.)
	EndIf

	// inclui o codigo do servico de conferencia (saida) na query (código 004 (Carregar Veículos) adicionado para diferenciar da conferência de expedição)
	mvQryUsr += " AND Z06_SERVIC IN " + _cSqlCodSrv + " AND Z06_TAREFA = '" + _cCodTaref + "' "

	// descarta ordens de servico FI-Finalizadas e/ou CA-Canceldas
	mvQryUsr += " AND Z06_STATUS NOT IN ( 'FI', 'CA' ) "

	MemoWrit("c:\query\twmsa020_1.txt", mvQryUsr)

	// atualiza vetor com as ordens de servico pendentes para o usuario
	_aOrdSrvPend := U_SqlToVet(mvQryUsr)

	// valida se ha ordens de servico pendentes para o usuario/ o usuario tem permissao de acesso
	If ( Len(_aOrdSrvPend) == 0 )
		// mensagem
		U_FtWmsMsg("Não há carregamentos/pedidos disponíveis para este usuário.")
		// variavel de controle do retorno
		_lRet := .F.
		// retorno
		Return( .F. )
	EndIf

	// chama a rotina padrao para consultar veiculos disponiveis para operacao
	_lRet := U_WMSA016B("02", .T.)

	// se foi confirmado, atualiza CESV, codigo e loja do cliente
	If (_lRet)
		_cNumCESV    := SZZ->ZZ_CESV
		_cCodCliFor  := SZZ->ZZ_CLIENTE
		_cLojCliFor  := SZZ->ZZ_LOJA
		// versao do processo de carregamento (1-Planeja Carregamento com Mapa de Separacao | 2-Ordem de Servico de Carregamento Independente das demais)
		_nVersCarreg := sfRetVersao( @_lRet )
	EndIf

	// complementa a query com a CESV selecionada
	If (_lRet)

		// codigo e loja do cliente
		mvQryUsr += " AND Z05_CLIENT = '" + _cCodCliFor + "' "
		mvQryUsr += " AND Z05_LOJA = '" + _cLojCliFor + "' "

		// ordens de servico ja programadas
		mvQryUsr += " AND Z06_NUMOS IN ( "
		mvQryUsr += "                   SELECT DISTINCT Z43_NUMOS "
		mvQryUsr += "                     FROM " + RetSqlTab("Z43")
		mvQryUsr += "                    WHERE " + RetSqlCond("Z43")
		mvQryUsr += "                      AND Z43_STATUS IN ('P', 'R') "
		mvQryUsr += "                      AND Z43_CESV = '" + _cNumCESV + "' "
		mvQryUsr += "                  ) "
	EndIF

	MemoWrit("c:\query\twmsa020_2.txt", mvQryUsr)

	// validação para entrada de caminhão sem NF emitida
	_lCESVSemNf := U_FtWmsParam("WMS_LIBERA_CARREGAMENTO_SEM_NF","L",.F.,.F.,"", _cCodCliFor, _cLojCliFor, Nil, Nil)

	// se foi confirmado, verifica necessidade de geracao de ordem de servico de carregamento
	If ( _lRet )

		// prepara query para buscar planejamento de carregamento, sem ordem de servico gerada
		_cQuery := " SELECT Z43.R_E_C_N_O_ Z43RECNO "
		// agendamento/programacao de carregamento
		_cQuery += " FROM   " + RetSqlTab("Z43")
		// pedido de venda
		_cQuery += "        INNER JOIN " + RetSqlTab("SC5") 
		_cQuery += "                ON " + RetSqlCond("SC5")
		_cQuery += "                   AND C5_NUM = Z43_PEDIDO "
		_cQuery += "                   AND C5_TIPOOPE = 'P' "
		// valida se precisa de NF para carregamento
		If ( ! _lCESVSemNf )
			_cQuery += "                   AND C5_NOTA != ' ' "
		EndIf
		// filtro padrao
		_cQuery += " WHERE  " + RetSqlCond("Z43")
		_cQuery += "        AND Z43_STATUS = 'P'
		_cQuery += "        AND Z43_CLIENT = '" + _cCodCliFor + "' "
		_cQuery += "        AND Z43_LOJA = '" + _cLojCliFor + "' "
		_cQuery += "        AND Z43_NUMOS = '' "
		_cQuery += "        AND Z43_CESV = '" + _cNumCESV + "' "

		MemoWrit("c:\query\twmsa020_3.txt", _cQuery)

		// atualiza vetor com pendencias
		_aRecnoZ43 := U_SqlToVet(_cQuery)

		// se tem pendencias, solicita ao usuario confirmacao de geracao de ordem de servico
		If (Len(_aRecnoZ43) != 0)
			// verifico se este CESV já tem ordem de serviço gerada, pois pode ter ocorrido um carregamento parcial
			// devido a emissão de nota fiscal de um dos pedidos POSTERIOR ao inicio do carregamento

			_cQuery := " SELECT Z43_NUMOS "
			_cQuery += " FROM " + RetSqlTab("Z43")
			_cQuery += " WHERE " + RetSqlCond("Z43")
			_cQuery += "        AND Z43_CLIENT = '" + _cCodCliFor + "'"
			_cQuery += "        AND Z43_LOJA = '"   + _cLojCliFor + "'"
			_cQuery += "        AND Z43_CESV = '"   + _cNumCESV   + "'"

			_cTmpOS := U_FTQuery(_cQuery)

			If ( !Empty(_cTmpOS) )   // CESV já gerou OS
				// posiciono na Z05 com a OS gerada
				dbSelectArea("Z05")
				Z05->(DbSetOrder(1)) // 1-FILIAL+NUMOS
				Z05->(DbSeek( xFilial("Z05") + _cTmpOS ))
				_lGeraOS := .F.
			Else
				// não encontrou OS gerada, pergunta se quer gerar agora
				if (! U_FtYesNoMsg("Confirma Geração de Ordem de Serviço para Carregamento para CESV " + _cNumCESV + " ?")) 
					// variavel de controle
					_lRet := .F.
				EndIf
			EndIf

			// se foi confirmado a geracao, gera nova ordem de servico
			If ( _lRet ) .and. ( _lGeraOS )
				Begin Transaction

					// funcao padrao para geracao de ordem de servico (Srv: 002-Carregamento | Trf: 004-Carregar Veiculos)
					If ( ! U_WMSA009B(_cNumCESV, "02", Nil, Nil, Nil, .T., "002", _cCodCliFor, _cLojCliFor, .F. , Nil, Nil, Nil, "004" ) )
						// variavel de controle
						DisarmTransaction()
						_lRet := .F.
					EndIf

					// varre itens pendente/planejados
					For _nRecZ43 := 1 to Len(_aRecnoZ43)

						// posiciona no registro real
						dbSelectArea("Z43")
						Z43->( DbGoTo( _aRecnoZ43[_nRecZ43] ) )

						// atualiza numero da ordem de servico
						RecLock("Z43", .F.)
						Z43->Z43_NUMOS := Z05->Z05_NUMOS
						Z43->(MsUnLock())

					Next _nRecZ43

				End Transaction
			EndIf

		EndIf

	EndIf

	// chama funcao para selecionar os clientes
	If (_lRet)

		_lRet := sfSelCliente(_cNumCESV)

	EndIf

	// se foi selecionado o cliente, define os parametros
	If (_lRet)

		// permite validação por volumes
		_lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.F.,.F.,Nil, _cCodCliFor, _cLojCliFor, Nil, Nil)

		// tipo da etiqueta a ser usada
		_cTpIdEtiq := U_FtWmsParam("WMS_PRODUTO_ETIQ_IDENT","C","INTERNA",.F.,"", _cCodCliFor, _cLojCliFor, Nil, Nil)

		// se processo de integração de sistema Sumitomo (barcode) está ativa
		lSumiBar := U_FtWmsParam("WMS_SUMITOMO_LEITURA_BARCODE", "L", .F., .F., Nil, _cCodCliFor, _cLojCliFor, Nil, Nil)

		// tipo de identificacao
		_lEtqIdInt  := (AllTrim(_cTpIdEtiq) == "INTERNA")
		_lEtqIdEAN  := (AllTrim(_cTpIdEtiq) == "EAN") .Or. (AllTrim(_cTpIdEtiq) == "EAN13")
		_lEtqIdDUN  := (AllTrim(_cTpIdEtiq) == "DUN14")
		_lEtqCod128 := (AllTrim(_cTpIdEtiq) == "CODE128")
		_lEtqClient := (AllTrim(_cTpIdEtiq) == "CLIENTE")

		// conteudo o parametro do controle de tipo de carregamento
		_cTipoCarreg := U_FtWmsParam("WMS_EXPEDICAO_TIPO_CONFERENCIA_CARREGAMENTO", "C", "PEDIDO", .F., Nil, _cCodCliFor, _cLojCliFor, Nil, Nil)
		_lPorPedido  := (AllTrim(_cTipoCarreg) == "PEDIDO")
		_lPorCarga   := (AllTrim(_cTipoCarreg) == "CARGA")

		// mascara para campos quantidade
		_cMaskQuant := U_FtWmsParam("WMS_MASCARA_CAMPO_QUANTIDADE", "C", PesqPict("SD1","D1_QUANT"), .F., "", _cCodCliFor, _cLojCliFor, Nil, Nil)

		// permite o carregamento sem a nota fiscal de venda do cliente
		_lSemNfVend := U_FtWmsParam("WMS_LIBERA_CARREGAMENTO_SEM_NF_VENDA", "L", .F., .F., "", _cCodCliFor, _cLojCliFor, Nil, Nil)

		// define quantidade de caracteres da etiqueta do cliente
		_nTamEtqCli := U_FtWmsParam("WMS_QUANT_CARACTERES_ETIQUETA_CLIENTE", "N", TamSx3("Z56_ETQCLI")[1], .F., "", _cCodCliFor, _cLojCliFor, Nil, Nil)

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

	EndIf

	// loop para manter o processo de cargas aberto
	While (_lRet)

		// pega o pedido que vai ser executado (total de pedidos daquele CESV)
		If (_lRet) .And. ( ! sfRetPedidos(_cNumCESV, mvQryUsr) )
			// atualiza variavel de controle
			_lRet := .F.
			// retorno
			Exit
		EndIf

		If (_lRet) .And. (_lPorPedido)

			// posiciono no pedido para validação
			dbSelectArea("SC5")
			SC5->( dbSetOrder(1) ) // C5_FILIAL, C5_NUM, R_E_C_N_O_, D_E_L_E_T_
			If ! SC5->( dbSeek( xFilial("SC5") + _cPedUnico) )
				// mensagem
				U_FtWmsMsg("Pedido não encontrado. Verifique o status da Ord.Serviço e permissões do usuário.")
				// retorna tela de pedidos
				Loop
			EndIf

			// valida se o pedido ja esta ok
			If (SC5->C5_ZCARREG == "S")
				// mensagem
				U_FtWmsMsg("O pedido " + _cPedUnico + " já está carregado. Tente selecionar outro pedido da lista ou Finalize o Carregamento.","Atenção")
				// retorna tela de pedidos
				Loop
			EndIf

		EndIf

		// valida o status do CESV
		If (_lRet)
			// valida a doca
			If ( Empty(SZZ->ZZ_DOCA) )
				// mensagem
				U_FtWmsMsg("Veículo sem DOCA de expedição definida. Obrigatório escolher agora.","ATENCAO")

				_lRet := U_WMSA008B( SZZ->ZZ_CESV )
			EndIf
		EndIf

		// se encontrou o registro, altera o status
		If (_lRet)
			// atualiza STATUS
			If (SZZ->ZZ_STATUS <> "07")
				dbSelectArea("SZZ")
				RecLock("SZZ",.F.)
				SZZ->ZZ_STATUS := "07" // 07-LIBERADO PARA OPERACAO
				SZZ->(MsUnLock())
			EndIf

			// rotina de conferência para carregamento
			U_WMSA020A()

		EndIf

		// fim do while
	EndDo

Return(_lRet)

// ** função da tela todos os pedidos daquela carga
Static Function sfRetPedidos(mvCesv, mvQryUsr)
	// variavel de controle
	local _lRet := .F.
	// objetos locais
	local _oWmsPedidos, _oPnlPedCab, _oBmpOk, _oBmpSair, _oBrwPedidos, _oBmpOpcoes
	// arrays do browse
	local _aHeadPed  := {}
	local _aColsPed  := {}
	// variaveis para seek
	local _cSeekZ05 := "", _cSeekZ06 := "", _cSeekZ43 := ""
	// sub-menu
	local _oMnuOpcoes := nil
	local _oSbMnOpc1  := nil
	local _oSbMnOpc2  := nil
	// variaveis temporarias
	local _nLinCol
	local _nX
	local _aTmpOrdSrv  := {}
	local _cTmpOrdSrv  := ""
	local _aTmpPedidos := {}
	local _cTmpNrPedid := ""
	local _aTmpCargas  := {}
	local _cTmpNrCarga := ""

	// define o acols
	_aColsPed := sfQryPedidos(mvCesv)

	// quando nao ha pedidos liberados
	If (Len(_aColsPed) == 0)
		// mensagem
		U_FtWmsMsg("Todos os pedidos já foram carregados ou não há pedidos liberados para carregamento.")
		// retorno
		Return(_lRet)
	EndIf

	// monta o dialogo do monitor
	_oWmsPedidos := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Pedidos para Carregamento",,,.F.,,,,,,.T.,,,.T. )

	// sub-itens do menus
	_oMnuOpcoes := TMenu():New(0,0,0,0,.T.)

	// -- FINALIZAR CARREGAMENTO
	_oSbMnOpc1 := TMenuItem():New(_oMnuOpcoes,"Finalizar Carregamento",,,,{|| IIf( sfFinalCar(_cNumCesv), _oWmsPedidos:END(), Nil ) },,"CHECKED",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc1)

	// -- SAIR
	_oSbMnOpc2 := TMenuItem():New(_oMnuOpcoes,"Sair",,,,{|| IIF( U_FtYesNoMsg("O carregamento não foi finalizado, deseja sair mesmo assim?"), _oWmsPedidos:END(), Nil ) },,"FINAL",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc2)

	// cria o panel do cabecalho - botoes de operacao
	_oPnlPedCab := TPanel():New(000,000,nil,_oWmsPedidos,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlPedCabs:Align:= CONTROL_ALIGN_TOP

	// botao que seleciona um pedido
	_oBmpOk := TBtnBmp2():New(000,000,060,022,"WMS_CAR_VEI",,,,{|| _lRet := .T., _oWmsPedidos:End() },_oPnlPedCab,"OK",,.T.)
	_oBmpOk:Align := CONTROL_ALIGN_LEFT

	// -- BOTAO COM MAIS OPCOES
	_oBmpOpcoes := TBtnBmp2():New(000,000,060,022,"SDUAPPEND",,,,{|| Nil },_oPnlPedCab,"",,.T.)
	_oBmpOpcoes:Align := CONTROL_ALIGN_RIGHT
	_oBmpOpcoes:SetPopupMenu(_oMnuOpcoes)

	// define array do browse
	aAdd(_aHeadPed,{"Sts"         ,"IT_ZCARREG" ,"@!",4                       ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Ped.Cliente" ,"C5_ZPEDCLI" ,""  ,TamSx3("C5_ZPEDCLI")[1] ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Agrupador"   ,"C5_ZAGRUPA" ,""  ,TamSx3("C5_ZAGRUPA")[1] ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Pedido"      ,"C5_NUM"     ,""  ,TamSx3("C5_NUM")[1]     ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Carga"       ,"C9_CARGA"   ,""  ,TamSx3("C9_CARGA")[1]   ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Num.OS"      ,"Z43_NUMOS"  ,""  ,TamSx3("Z43_NUMOS")[1]  ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPed,{"Doc.Cliente" ,"C5_ZDOCCLI" ,""  ,TamSx3("C5_ZDOCCLI")[1] ,0,Nil,Nil,"C",Nil,"R",,,".F." })

	// browse
	_oBrwPedidos := MsNewGetDados():New(078,000,148,118,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsPed),'AllwaysTrue()','','AllwaysTrue()',_oWmsPedidos,_aHeadPed,_aColsPed)
	_oBrwPedidos:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwPedidos:oBrowse:bLdblClick := {|| sfCanCar(_oBrwPedidos:aCols[_oBrwPedidos:nAt][6], _oBrwPedidos:aCols[_oBrwPedidos:nAt][5], _oBrwPedidos:aCols[_oBrwPedidos:nAt][4], _oBrwPedidos, _oWmsPedidos) }

	// ativacao da tela
	ACTIVATE MSDIALOG _oWmsPedidos

	// posiciona nos registros das tabelas envolvidas
	If (_lRet)

		// zera variaveis
		_aTmpOrdSrv := {}
		_cTmpOrdSrv := ""

		// controle de conferencia
		If (_lPorPedido)

			// numero da ordem atual
			_cTmpOrdSrv  := _oBrwPedidos:aCols[_oBrwPedidos:nAt][6]
			_cTmpNrPedid := _oBrwPedidos:aCols[_oBrwPedidos:nAt][4]
			_cTmpNrCarga := _oBrwPedidos:aCols[_oBrwPedidos:nAt][5]

			// ordem de servico
			If ( Ascan(_aTmpOrdSrv, _cTmpOrdSrv) == 0 )
				aAdd(_aTmpOrdSrv, _cTmpOrdSrv)
			EndIf

			// pedido
			If ( Ascan(_aTmpPedidos, _cTmpNrPedid) == 0 )
				aAdd(_aTmpPedidos, _cTmpNrPedid)
			EndIf

			// carga
			If ( Ascan(_aTmpCargas, _cTmpNrCarga) == 0 )
				aAdd(_aTmpCargas, _cTmpNrCarga)
			EndIf

		ElseIf (_lPorCarga)
			// varre todas as linhas do aCols de Pedidos
			For _nLinCol := 1 to Len(_oBrwPedidos:aCols)

				// numero da ordem atual
				_cTmpOrdSrv  := _oBrwPedidos:aCols[_nLinCol][6]
				_cTmpNrPedid := _oBrwPedidos:aCols[_nLinCol][4]
				_cTmpNrCarga := _oBrwPedidos:aCols[_nLinCol][5]

				// ordem de servico
				If ( Ascan(_aTmpOrdSrv, _cTmpOrdSrv) == 0 )
					aAdd(_aTmpOrdSrv, _cTmpOrdSrv)
				EndIf

				// pedido
				If ( Ascan(_aTmpPedidos, _cTmpNrPedid) == 0 )
					aAdd(_aTmpPedidos, _cTmpNrPedid)
				EndIf

				// carga
				If ( Ascan(_aTmpCargas, _cTmpNrCarga) == 0 )
					aAdd(_aTmpCargas, _cTmpNrCarga)
				EndIf

			Next _nLinCol
		EndIf

		// zera variaveis
		_cNumOrdSrv  := ""
		_cNrOSUnica  := ""
		_cAllPedidos := ""
		_cPedUnico   := ""
		_cAllCargas  := ""
		_cCargaUnic  := ""

		// Ord Servico - concatena todas na mesma string
		For _nX := 1 to Len(_aTmpOrdSrv)
			_cNumOrdSrv += IIf(Empty(_cNumOrdSrv),"","|") + _aTmpOrdSrv[_nX]
			_cNrOSUnica := _aTmpOrdSrv[_nX]
		Next _nX

		// formata a variavel do numero da OS para SQL IN
		_cNumOrdSrv := FormatIn(_cNumOrdSrv, "|")

		// Pedidos - concatena todos na mesma string
		For _nX := 1 to Len(_aTmpPedidos)
			_cAllPedidos += IIf(Empty(_cAllPedidos),"","|") + _aTmpPedidos[_nX]
			_cPedUnico   := _aTmpPedidos[_nX]
		Next _nX

		// formata a variavel do numero do pedido para SQL IN
		_cAllPedidos := FormatIn(_cAllPedidos, "|")

		// Cargas - concatena todos na mesma string
		For _nX := 1 to Len(_aTmpCargas)
			_cAllCargas += IIf(Empty(_cAllCargas),"","|") + _aTmpCargas[_nX]
			_cCargaUnic := _aTmpCargas[_nX]
		Next _nX

		// formata a variavel do numero da carga para SQL IN
		_cAllCargas := FormatIn(_cAllCargas, "|")

		// controle de unica ordem de servico para carregamento (nova versao)
		_lNrOSUnica := (Len(_aTmpOrdSrv) == 1)

	EndIf

Return (_lRet)

// ** função pra cancelar carregamento
Static Function sfCanCar(mvNumOS, mvCarga, mvPedido, mvBrw, mvTela)
	// variável de controle
	local _lRet := .T.
	// acols do browse
	local _aColsNew := {}

	If (_lRet)
		// pesquisa o CESV da OS selecionada
		dbSelectArea("Z43")
		Z43->(DbSetOrder(3)) // 3-Z43_FILIAL, Z43_NUMOS, Z43_CARGA, Z43_PEDIDO, Z43_CESV
		If ( Z43->(DbSeek( _cSeekZ43 := xFilial("Z43") + mvNumOS + mvCarga + mvPedido + _cNumCESV )))
			// valida status de REALIZADO
			If (Z43->Z43_STATUS == "R")
				// mensagem
				U_FtWmsMsg("O pedido já foi carregado!")
				// variavel de controle
				_lRet := .F.
			ElseIf (Z43->Z43_STATUS == "C")
				// pergunta ao usuário
				_lRet := U_FtYesNoMsg("Deseja recuperar o pedido " + Z43->Z43_PEDCLI + " (Interno: " + mvPedido + ")?")

				If (_lRet)
					// liberar o pedido
					dbSelectArea("Z43")
					Reclock("Z43")
					Z43->Z43_STATUS := "P"
					Z43->(MsUnlock())
				EndIf
			Else
				// pergunta ao usuário
				_lRet := U_FtYesNoMsg("Deseja cancelar o carregamento o pedido do cliente " + Z43->Z43_PEDCLI + " (Interno: " + mvPedido + ")?")

				If (_lRet)
					// cancelar o pedido
					dbSelectArea("Z43")
					Reclock("Z43")
					Z43->Z43_STATUS := "C"
					Z43->(MsUnlock())
				EndIf
			EndIf
		Else
			U_FtWmsMsg("Pedido não encontrado")
			_lRet := .F.
		EndIf

		// conteudo da variavel do acols
		_aColsNew := sfQryPedidos(_cNumCESV)

		If (Len(_aColsNew) > 0)
			// atualizo o browse
			mvBrw:aCols := _aColsNew
			mvBrw:Refresh(.t.)
		EndIf
	EndIf
Return (_lRet)

// ** função que retorna o array de pedidos
Static Function sfQryPedidos(mvCesv)
	// array que vai receber os dados
	local _aPedidos := {}
	// query para busca de pedidos
	local _cQuery   := ""

	// busco os pedidos baseado no vinculo de pedidos ao CESV
	_cQuery := " SELECT DISTINCT CASE WHEN C5_ZCARREG = 'S' AND Z43_STATUS = 'R' THEN 'OK' "
	_cQuery += "                      WHEN Z43_STATUS = 'C' THEN 'CAN' "
	_cQuery += "					  ELSE '' END IT_ZCARREG, "
	_cQuery += "                 C5_ZPEDCLI, "
	_cQuery += "                 C5_ZAGRUPA, "
	_cQuery += "                 C5_NUM, "
	_cQuery += "                 C9_CARGA, "
	_cQuery += "                 Z43_NUMOS, "
	_cQuery += "                 C5_ZDOCCLI, "
	_cQuery += "                 '.F.' IT_DEL "

	// pedido de venda
	_cQuery += " FROM " + RetSqlTab("SC5") + " (nolock) "

	// itens liberados do pedido
	_cQuery += " INNER JOIN " + RetSqlTab("SC9") + " (nolock) "
	// filtro padrao
	_cQuery += "         ON " + RetSqlCond("SC9")
	// pedido
	_cQuery += "            AND C9_PEDIDO = C5_NUM "

	// valida se precisa de NF para carregamento
	If ( ! _lCESVSemNf )
		_cQuery += "            AND C9_NFISCAL <> ' ' "
	EndIf

	// pedidos relacionados ao CESV
	_cQuery += " INNER JOIN " + RetSqlTab("Z43")
	// filtro padrao
	_cQuery += "         ON " + RetSqlCond("Z43")
	// carga
	_cQuery += "            AND Z43_CARGA = C5_ZCARGA "
	// pedido
	_cQuery += "            AND Z43_PEDIDO = C5_NUM "
	// status
	_cQuery += "            AND Z43_STATUS IN ('P', 'R', 'C') "
	// numero OS
	_cQuery += "            AND Z43_CESV = '" + mvCesv + "' "

	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("SC5")

	If ( _lCtrVolume )
		// pedido que ja foi montado volumes
		_cQuery += " AND C5_ZMNTVOL = 'S' "
	EndIf

	// documento/nf do cliente ja informado
	If ( ! _lSemNfVend )
		_cQuery += " AND C5_ZDOCCLI <> ' ' "
	EndIf

	// ordem dos dados
	_cQuery += " ORDER BY C5_ZPEDCLI "

	memowrit("C:\query\twmsa020_sfQryPedidos.txt",_cQuery)

	// jogo os dados pro array
	_aPedidos := U_SqlToVet(_cQuery)

	// retorno o array
Return (_aPedidos)

// ** funcao principal de conferencia de saida/carregamento (expedicao)
User Function WMSA020A()

	// objetos locais
	local _oWmsConfExpe
	local _oPnlCfeCab
	local _oBmpCfeNvPalete, _oBmpCfeCons, _oBmpOpcoes, _oBt01NvVlm
	local _oSayTitulo, _oSayNrPalete, _oSayCodProd, _oSaySomaVol

	// sub-menu
	local _oMnuOpcoes := nil
	local _oSbMnOpc2  := nil
	local _oSbMnOpc5  := nil

	// controle de while
	local _lRet := .t.

	local _lOk := .F.

	// Seek Z43
	local _cSeekZ43

	// informacoes do produto
	private _cEtiqProd  := CriaVar("Z11_CODETI",.F.)
	Private _nTamCodPrd := TamSx3("B1_COD")[1]
	Private _cCodProd   := Space(_nTamCodPrd)
	Private _cDscProd   := ""
	Private _nQtdProd   := 1
	Private _nQtdSegUM  := 0
	Private _cIdAgrupa  := CriaVar("Z11_CODETI",.F.)

	// Id do palete
	private _nTamIdPal := TamSx3("Z11_CODETI")[1]
	private _cIdPalete := Space(_nTamIdPal)
	private _cMskEtiq  := PesqPict("Z11","Z11_CODETI")
	private _cCodUnit  := CriaVar("DC1_CODUNI",.F.)

	// armazem
	private _cArmzServ := ""

	// objetos private
	private _oGetNrPalete, _oGetCodProd, _oGetEtqAgrupa

	// variaveis do browse
	private _oBrwConfExpe
	private _aHeadConf := {}
	private _aColsConf := {}

	// Informações Adicionais
	private _nTamIdLot := TamSx3("B8_LOTECTL")[1]
	private _cIdLote   := Space(_nTamIdLot)
	private _nTamPlCli := TamSx3("Z16_PLTCLI")[1]
	private _cPltClie  := Space(_nTamPlCli)
	private _nSomaVol  := 0

	//Verifica se Cliente controla Lote
	private _lCtrLote := .F.

	// atualiza os dados
	sfSelDados( .F. )

	// funcao que pesquisa se ficou algum palete pendente
	sfRetPltInt()

	// define novo pallet
	_lNovoPalete := (Empty(_cIdPalete))

	// monta o dialogo do monitor
	_oWmsConfExpe := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Carregamento por " + IIf(_lPorPedido, "Pedido", "Carga"),,,.F.,,,,,,.T.,,,.T. )
	_oWmsConfExpe:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlCfeCab := TPanel():New(000,000,nil,_oWmsConfExpe,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlCfeCab:Align:= CONTROL_ALIGN_TOP

	// -- NOVO VOLUME
	If (_lCtrVolume)
		_oBt01NvVlm := TBtnBmp2():New(000,000,060,022,"AVGARMAZEM",,,,{|| sfNovoVolume() },_oPnlCfeCab,"Novo Volume",,.T.)
		_oBt01NvVlm:Align := CONTROL_ALIGN_LEFT
		// -- NOVO PALETE
	Else
		_oBmpCfeNvPalete := TBtnBmp2():New(000,000,060,022,"ARMIMG32",,,,{|| sfNovoPalete() },_oPnlCfeCab,"Novo Palete",,.T.)
		_oBmpCfeNvPalete:Align := CONTROL_ALIGN_LEFT
	EndIf

	// -- CONSULTA DETALHES
	_oBmpCfeCons := TBtnBmp2():New(000,000,060,022,"MDIHELP",,,,{|| sfDetConfer() },_oPnlCfeCab,"Informações",,.T.)
	_oBmpCfeCons:Align := CONTROL_ALIGN_LEFT

	// sub-itens do menus
	_oMnuOpcoes := TMenu():New(0,0,0,0,.T.)
	// adiciona itens no Menu
	// -- FINALIZAR OS
	_oSbMnOpc2 := TMenuItem():New(_oMnuOpcoes,"Finalizar Carregamento",,,,{|| sfFinalizaOS(_oWmsConfExpe, @_lOk) },,"CHECKED",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc2)
	// -- SAIR SEM INTERROMPER
	_oSbMnOpc5 := TMenuItem():New(_oMnuOpcoes,"Sair",,,,{|| _lOk := .t. , _oWmsConfExpe:End()},,"FINAL",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc5)

	// -- BOTAO COM MAIS OPCOES
	_oBmpOpcoes := TBtnBmp2():New(000,000,060,022,"SDUAPPEND",,,,{|| Nil },_oPnlCfeCab,"",,.T.)
	_oBmpOpcoes:Align := CONTROL_ALIGN_RIGHT
	_oBmpOpcoes:SetPopupMenu(_oMnuOpcoes)

	// titulo
	If (_lPorPedido)
		_oSayTitulo := TSay():New(025,003,{|| "Carregamento (Pedido: " + _cPedUnico + ")"},_oWmsConfExpe,,_oFnt02,.F.,.F.,.F.,.T.)
	EndIf

	// valida se vai trabalhar com volume
	If ( ! _lCtrVolume ) .And. (_lEtqIdInt)
		// controle por palete
		_oSayNrPalete := TSay():New(039,003,{||"Id Palete"},_oWmsConfExpe,,,.F.,.F.,.F.,.T.)
		_oGetNrPalete := TGet():New(037,036,{|u| If(PCount()>0,_cIdPalete:=u,_cIdPalete)},_oWmsConfExpe,050,010,_cMskEtiq,{|| (Vazio()) .Or. (sfVldPalete()) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIdPalete",,)
		_oGetNrPalete:bWhen := {|| .F. }

		// informacoes do produto lido
		_oSayCodProd := TSay():New(058,003,{||"Etiq.Produto"},_oWmsConfExpe,,,.F.,.F.,.F.,.T.)
		_oGetCodProd := TGet():New(056,036,{|u| If(PCount()>0,_cEtiqProd:=u,_cEtiqProd)},_oWmsConfExpe,050,010,_cMskEtiq,{|| (Vazio()) .Or. (sfVldProd(@_oWmsConfExpe, @_lOk)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtiqProd",,)
	ElseIf (_lCtrVolume) .And. ((_lEtqIdEAN) .Or. (_lEtqIdDUN) .Or. (_lEtqCod128))
		// controle volume
		_oGetEtqAgrupa := TGet():New(035,003,{|u| If(PCount()>0,_cIdAgrupa:=u,_cIdAgrupa)},_oWmsConfExpe,050,010,_cMskEtiq,{|| (Vazio()) .Or. (sfVldAgrupa(@_lOk)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIdAgrupa",,,,,,,"Etq.Tecadi  ",2)
		_oGetEtqAgrupa:SetFocus()
		_oSaySomaVol := TSay():New(055,003,{ || "Tot.Vol.Conf.: " + Iif(Empty(_nSomaVol),"-",Str(_nSomaVol,4))},_oWmsConfExpe,,,.F.,.F.,.F.,.T.)
	ElseIf (_lCtrVolume) .And. (_lEtqClient)
		// controle volume
		_oGetEtqAgrupa := TGet():New(048,003,{|u| If(PCount()>0,_cEtqCodBar:=u,_cEtqCodBar)},_oWmsConfExpe,050,010,_cMskCodBar,{|| (Vazio()) .Or. (sfVldEtqCli(@_lOk)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtqCodBar",,,,,,,"Etq.Identificação",2)
		_oGetEtqAgrupa:SetFocus()
	EndIf

	// browse com a listagem dos produtos conferidos
	_oBrwConfExpe := MsNewGetDados():New(078,000,148,118,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsConf),'AllwaysTrue()','','AllwaysTrue()',_oWmsConfExpe,_aHeadConf,_aColsConf)

	// ativa a tela
	_oWmsConfExpe:Activate(,,,.F.,{|| _lOk },,)

Return(_lOk)

// ** funcao para filtrar os itens já conferidos do servico/nota selecionado, conforme codigo do operador
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
	_cQuery := " SELECT Z07_PALLET, SUM(Z07_QUANT) Z07_QUANT, SUM(Z07_QTSEGU) Z07_QTSEGU, Z07_PRODUT, B1_DESC, Z07_ETQVOL, Z07_LOTCTL, Z07_ETQCLI, Z07_NUMSER,"

	// buscca o ultimo recno para ordenar
	_cQuery += " (SELECT MAX(R_E_C_N_O_) FROM " + RetSqlTab('Z07') + " (nolock)  WHERE " + RetSqlCond("Z07")
	_cQuery += " AND Z07_NUMOS  IN " + _cNumOrdSrv
	_cQuery += " AND Z07_CLIENT = '" + _cCodCliFor + "' AND Z07_LOJA  = '" + _cLojCliFor + "' "
	_cQuery += " AND Z07_PRODUT = Z07.Z07_PRODUT) Z07RECNO "

	// tabela de itens conferidos
	_cQuery += " FROM " + RetSqlTab('Z07') + " (nolock) "

	// itens da ordem de servico
	_cQuery += " INNER JOIN " + RetSqlTab("Z06") + " (nolock)  ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z07_NUMOS AND Z06_SEQOS = Z07_SEQOS "
	_cQuery += " AND Z06_SERVIC IN " + _cSqlCodSrv + " AND Z06_TAREFA = '" + _cCodTaref + "' "

	// cadastro de produtos
	_cQuery += " INNER JOIN " + RetSqlTab('SB1') + " (nolock)  ON " + RetSqlCond("SB1") + " AND B1_COD = Z07_PRODUT "

	// filtros
	_cQuery += " WHERE " + RetSqlCond("Z07")
	// nr de OS
	_cQuery += " AND Z07_NUMOS  IN " + _cNumOrdSrv
	// cliente e loja
	_cQuery += " AND Z07_CLIENT = '" + _cCodCliFor + "' AND Z07_LOJA  = '" + _cLojCliFor + "' "
	// todos os pedidos
	_cQuery += " AND Z07_PEDIDO IN " + _cAllPedidos
	// conferencia por pedido
	If (_lPorPedido)
		_cQuery += " AND Z07_PEDIDO = '" + _cPedUnico + "' "
	EndIf
	// somente que nao C-EM CONFERENCIA
	_cQuery += " AND Z07_STATUS = 'C' "
	// agrupamento de informacoes
	_cQuery += " GROUP BY Z07_PALLET, Z07_PRODUT, B1_DESC, Z07_ETQVOL, Z07_LOTCTL,Z07_ETQCLI, Z07_NUMSER "
	// ordem dos dados
	_cQuery += " ORDER BY Z07RECNO DESC "

	memowrit("c:\query\twmsa020_sfSelDados.txt",_cQuery)

	// executa a query
	dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),"QRYCNF",.F.,.T.)

	// verifica a necessidade de criar o Header
	If (Len(_aHeadConf) == 0)
		aAdd(_aHeadConf,{"Id Palete"  , "Z07_PALLET", PesqPict("Z07","Z07_PALLET"), TamSx3("Z07_PALLET")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Quant"      , "Z07_QUANT" , _cMaskQuant                 , TamSx3("Z07_QUANT")[1] , TamSx3("Z07_QUANT")[2] ,Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Qtd Seg UM" , "Z07_QTSEGU", _cMaskQuant                 , TamSx3("Z07_QTSEGU")[1], TamSx3("Z07_QTSEGU")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Produto"    , "Z07_PRODUT", PesqPict("Z07","Z07_PRODUT"), TamSx3("Z07_PRODUT")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Descr."     , "B1_DESC"   , PesqPict("SB1","B1_DESC")   , TamSx3("B1_DESC")[1]   , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Etq.Volume" , "Z07_ETQVOL", PesqPict("Z07","Z07_ETQVOL"), TamSx3("Z07_ETQVOL")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Lote"       , "Z07_LOTCTL", PesqPict("Z07","Z07_LOTCTL"), TamSx3("Z07_LOTCTL")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Etq.Cliente", "Z07_ETQCLI", PesqPict("Z07","Z07_ETQCLI"), TamSx3("Z07_ETQCLI")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Num.Serie"  , "Z07_NUMSER", PesqPict("Z07","Z07_NUMSER"), TamSx3("Z07_NUMSER")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
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
		// soma qtd. volumes
		_nSomaVol := Iif(mvRefesh,_nSomaVol,_nSomaVol + _aColsConf[1][2])
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
			// soma qtd. volumes
			_nSomaVol := Iif(mvRefesh,_nSomaVol,_nSomaVol + _aColsConf[Len(_aColsConf),2])
			// campo de controle do deletado
			_aColsConf[Len(_aColsConf),Len(_aHeadConf)+1] := .F.

			// proximo item
			QRYCNF->(dbSkip())
		EndDo
	EndIf

	// atualiza os itens do browse
	If (_oBrwConfExpe <> nil)
		_oBrwConfExpe:aCols := aClone(_aColsConf)
		_oBrwConfExpe:Refresh( .T. )
	EndIf

Return .t.

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
			_lRet := .F.
		EndIf
	EndIf

	// valida o tipo da etiqueta lida
	If (_lRet)
		If (Z11->Z11_TIPO != "03")
			U_FtWmsMsg("Tipo de etiqueta inválida!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// valida se a etiqueta do palete ja foi conferido
	If (_lRet)

		_cQryPalete := " SELECT COUNT(*) IT_PALETE "
		_cQryPalete += " FROM " + RetSqlTab("Z07")
		// filtros
		_cQryPalete += " WHERE " + RetSqlCond("Z07")
		_cQryPalete += " AND Z07_NUMOS IN " + _cNumOrdSrv
		_cQryPalete += " AND Z07_CLIENT = '" + _cCodCliFor + "' AND Z07_LOJA  = '" + _cLojCliFor + "' "
		_cQryPalete += " AND Z07_PALLET = '" + _cIdPalete + "' "

		If (U_FtQuery(_cQryPalete) > 0)
			U_FtWmsMsg("Palete já conferido!","ATENCAO")
			_lRet := .F.
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
		_lNovoPalete := .F.
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
	// RECNO do Z07
	local _nRecnoZ07 := 0
	// doca de serviço
	local _cDocaSrv := ""

	// dados do produto
	local _aDadosVol := {}
	local _nDadosVol

	// numero da OS
	local _cNumOS     := CriaVar("Z06_NUMOS", .F.)
	local _cSeqSrvVol := CriaVar("Z06_SEQOS", .F.)
	local _cSeqSrvCar := CriaVar("Z06_SEQOS", .F.)

	// carga
	local _cNrCarga := ""
	// pedido
	local _cNrPedido := ""

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11")+ IIf( ! _lCtrVolume, _cEtiqProd, _cIdAgrupa )))
			U_FtWmsMsg("Etiqueta inválida!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// pesquisa se a etiqueta é valida
	If (_lRet) .And. (Z11->Z11_TIPO != "01") .And. (Z11->Z11_TIPO != "04")// 01 - etiqueta de produto
		U_FtWmsMsg("Etiqueta de produto inválida!","ATENCAO")
		_lRet := .F.
	EndIf

	// verifica se ja iniciou a leitura do palete
	If (_lRet) .And. (Empty(_cIdPalete)) .And. ( ! _lCtrVolume )
		// pesquisa um palete
		_cIdPalete := sfRetNrPalete(_cEtiqProd)
		// valida se encontrou o palete
		_lRet := ( ! Empty(_cIdPalete) )
		// se encontrou, reposiciona no palete
		If (_lRet)
			dbSelectArea("Z11")
			Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
			If ! Z11->(dbSeek( xFilial("Z11")+_cIdPalete ))
				U_FtWmsMsg("Identificador do palete inválido!","ATENCAO")
				_lRet := .F.
			EndIf
			// atualiza os dados do palete
			If (_lRet)
				_cCodUnit := Z11->Z11_UNITIZ
			EndIf
		Else
			U_FtWmsMsg("Etiqueta de produto inválida!","ATENCAO")
			_lRet := .F.
		EndIf

	EndIf

	// verifica se foi informado a etiqueta do produto
	If (Empty(_cEtiqProd))
		U_FtWmsMsg("É necessário informar a etiqueta do produto!","ATENCAO")
		_lRet := .F.
	EndIf

	// realiza a pesquisa do produto, podendo ser feita pelo codigo de barras
	If (_lRet) .And. ( ! U_FtCodBar(@_cEtiqProd, @_cCodProd, @_lInfManual, @_cNumSeq, _cTpIdEtiq, _cCodCliFor))
		// variavel de retorno
		_lRet := .F.
	EndIf

	// valido o controle de lote
	_lCtrLote := (SB1->B1_RASTRO == "L")

	// atualiza descricao do produto
	_cDscProd := SB1->B1_DESC

	// reinicia a variavel de quantidade
	_nQtdProd := 1

	// valida se a etiqueta do produto ja foi conferida nesta OS
	If (_lRet) .And. ( ! _lCtrVolume )
		_cQuery := " SELECT ISNULL(SUM(Z07_QUANT),0) IT_PRODUTO "
		// itens conferidos
		_cQuery += " FROM " + RetSqlTab("Z07")
		// itens da ordem de servico
		_cQuery += " INNER JOIN " + RetSqlTab("Z06") + " (nolock)  ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z07_NUMOS AND Z06_SEQOS = Z07_SEQOS "
		_cQuery += " AND Z06_SERVIC IN " + _cSqlCodSrv + " AND Z06_TAREFA = '" + _cCodTaref + "' "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z07")
		_cQuery += " AND Z07_ETQPRD  = '" + _cEtiqProd + "' "
		_cQuery += " AND Z07_PALLET  = '" + _cIdPalete + "' "
		_cQuery += " AND Z07_NUMOS  IN " + _cNumOrdSrv
		// status
		_cQuery += " AND Z07_STATUS != 'C' "

		memowrit("c:\query\twmsa020_sfVldProd_1.txt", _cQuery)

		// se a quantidade nao eh informada, valida o palete
		If (U_FtQuery(_cQuery) > 0)
			U_FtWmsMsg("Identificador do produto já foi conferido!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// valida se a etiqueta do produto esta em mais de um palete
	If (_lRet) .And. ( ! _lCtrVolume )
		_cQuery := " SELECT ISNULL(SUM(Z07_QUANT),0) IT_PRODUTO "
		// itens conferidos
		_cQuery += " FROM " + RetSqlTab("Z07")
		// itens da ordem de servico
		_cQuery += " INNER JOIN " + RetSqlTab("Z06") + " (nolock)  ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z07_NUMOS AND Z06_SEQOS = Z07_SEQOS "
		_cQuery += " AND Z06_SERVIC IN " + _cSqlCodSrv + " AND Z06_TAREFA = '" + _cCodTaref + "' "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z07")
		_cQuery += " AND Z07_ETQPRD  = '" + _cEtiqProd + "' "
		_cQuery += " AND Z07_PALLET != '" + _cIdPalete + "' "
		_cQuery += " AND Z07_NUMOS  IN " + _cNumOrdSrv

		memowrit("c:\query\twmsa020_sfVldProd_2.txt", _cQuery)

		// se a quantidade nao eh informada, valida o palete
		If (U_FtQuery(_cQuery) > 0)
			U_FtWmsMsg("Identificador do produto já está em uso em outro palete!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// verifica se a etiqueta ja foi lida neste palete
	If (_lRet) .And. ( ! _lCtrVolume )
		_cQuery := " SELECT Z07.R_E_C_N_O_ Z07RECNO "
		// itens conferidos
		_cQuery += " FROM " + RetSqlTab("Z07")
		// itens da ordem de servico
		_cQuery += " INNER JOIN " + RetSqlTab("Z06") + " (nolock)  ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z07_NUMOS AND Z06_SEQOS = Z07_SEQOS "
		_cQuery += " AND Z06_SERVIC IN " + _cSqlCodSrv + " AND Z06_TAREFA = '" + _cCodTaref + "' "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z07")
		_cQuery += " AND Z07_NUMOS  IN " + _cNumOrdSrv
		_cQuery += " AND Z07_ETQPRD  = '" + _cEtiqProd + "' "
		_cQuery += " AND Z07_PALLET  = '" + _cIdPalete + "' "
		// status
		_cQuery += " AND Z07_STATUS = 'C' "

		memowrit("c:\query\twmsa020_sfVldProd_3.txt", _cQuery)

		// executa query
		_nRecnoZ07 := U_FtQuery(_cQuery)

		// se a quantidade nao eh informada, valida o palete
		If (_nRecnoZ07 > 0)
			// mensagem
			U_FtWmsMsg("Etiqueta já conferida.","ATENCAO")
			// retorno
			_lRet := .F.
		EndIf

	EndIf


	// valida se a etiqueta do produto ja esta disponivel para conferencia
	If (_lRet) .And. ( ! _lCtrVolume )

		// query de validação do uso do volume
		_cQuery := " SELECT Z16_ETQPAL, Z16_CODPRO, Z16_NUMSEQ, Z16_ETQPRD, Z16_ETQVOL, SUM(Z16_SALDO) Z16_SALDO, Z16_ENDATU, Z16_LOCAL, Z16_EMBALA, Z07_NUMOS, Z07_SEQOS, Z07_PEDIDO, Z16_CARGA, Z16_NUMSER, Z16_DTSERI "

		// composicao do palete
		_cQuery += " FROM " + RetSqlTab("Z16") + " (nolock) "

		// conferencia na montagem de volumes
		_cQuery += "        INNER JOIN " + RetSqlTab("Z07") + " (nolock) "
		_cQuery += "                ON " + RetSqlCond("Z07")
		_cQuery += "                   AND Z07_NUMOS IN " + _cNumOrdSrv
		_cQuery += "                   AND Z07_ETQVOL = Z16_ETQVOL "
		_cQuery += "                   AND Z07_LOTCTL = Z16_LOTCTL "
		_cQuery += "                   AND Z07_ETQPRD = Z16_ETQPRD "
		_cQuery += "                   AND Z07_STATUS = 'F' "

		// itens da ordem de servico
		_cQuery += "        INNER JOIN " + RetSqlTab("Z06") + " (nolock) "
		_cQuery += "                ON " + RetSqlCond("Z06")
		_cQuery += "                   AND Z06_NUMOS = Z07_NUMOS "
		_cQuery += "                   AND Z06_SEQOS = Z07_SEQOS "
		_cQuery += "                   AND Z06_SERVIC IN " + _cSqlCodSrv

		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z16")
		// id do palete
		_cQuery += " AND Z16_ETQPAL = '" + _cIdPalete + "' "
		// adequação para controle por volume
		If (_lCtrVolume)
			_cQuery += " AND Z16_ETQVOL  = '" + _cEtiqProd + "' "
		Else
			_cQuery += " AND Z16_ETQPRD  = '" + _cEtiqProd + "' "
		EndIf
		// somente com saldo
		_cQuery += " AND Z16_SALDO > 0 "
		// pedido
		_cQuery += " AND Z16_PEDIDO IN " + _cAllPedidos
		// carga
		_cQuery += " AND Z16_CARGA  IN " + _cAllCargas
		// agrupa dados
		_cQuery += " GROUP BY Z16_ETQPAL, Z16_CODPRO, Z16_NUMSEQ, Z16_ETQPRD, Z16_ETQVOL, Z16_ENDATU, Z16_LOCAL, Z16_EMBALA, Z07_NUMOS, Z07_SEQOS, Z07_PEDIDO, Z16_CARGA, Z16_NUMSER, Z16_DTSERI  "
		// ordem dos dados
		_cQuery += " ORDER BY Z16_ETQPAL, Z16_ETQVOL"

		memowrit("c:\query\twmsa020_sfVldProd_4.txt", _cQuery)

		// atualizo variavel com os dados do volume
		_aDadosVol := U_SqlToVet(_cQuery,{"Z16_DTSERI"})

		// se encontrou algum registro, vai informar ao usuário
		If (Len(_aDadosVol) == 0)
			U_FtWmsMsg("Essa etiqueta de produto não foi encontrada!","ATENCAO")
			// variavel de retorno
			_lRet := .F.
		EndIf

	EndIf

	// valido se o pallet lido pertence aquela OS
	If (_lRet) .And. ( ! Empty(_cIdPalete) )

		// monta query para buscar a informacao do palete na OS
		_cQuery := " SELECT COUNT(*) TOTAL "
		// mapa de separacao
		_cQuery += " FROM " + RetSqlTab("Z08") + " (nolock) "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z08")
		// numero da os
		_cQuery += " AND Z08_NUMOS IN " + _cNumOrdSrv
		// id palete
		_cQuery += " AND ( (Z08_NEWPLT = '' AND Z08_PALLET = '" + _cIdPalete + "') OR (Z08_NEWPLT != '' AND Z08_NEWPLT = '" + _cIdPalete + "') )"
		// status (R-Realizado)
		_cQuery += " AND Z08_STATUS = 'R' "

		memowrit("c:\query\twmsa020_sfVldProd_5.txt", _cQuery)

		// se não encontrar nada
		If (U_FtQuery(_cQuery) == 0)
			// mensagem
			U_FtWmsMsg("Identificador do produto não pertence a essa OS.","ATENCAO")
			// controle de validacao
			_lRet := .F.
		EndIf
	EndIf

	// se encontrou dados, valida dados da OS correspondente
	If (_lRet) .And. (Len(_aDadosVol) > 0)

		// varre todos os itens do volume para gravar o carregamento
		For _nDadosVol := 1 to Len(_aDadosVol)

			// dados da ordem de servico
			_cNumOS     := _aDadosVol[_nDadosVol][10]
			_cSeqSrvVol := _aDadosVol[_nDadosVol][11]
			_cSeqSrvCar := Space(Len(_cSeqSrvCar))
			// dados do pedido
			_cNrPedido  := _aDadosVol[_nDadosVol][12]
			// dados da carga
			_cNrCarga   := _aDadosVol[_nDadosVol][13]

			// pesquisa o CESV da OS selecionada
			dbSelectArea("Z43")
			Z43->(DbSetOrder(3)) // 3-Z43_FILIAL, Z43_NUMOS, Z43_CARGA, Z43_PEDIDO, Z43_CESV
			If ! Z43->(DbSeek( _cSeekZ43 := xFilial("Z43") + _cNumOS + _cNrCarga + _cNrPedido ))
				// mensagem
				U_FtWmsMsg("A OS " + _cNumOS + ", Carga " + _cNrCarga + " ou Pedido " + _cNrPedido + " ainda não foram liberados para carregamento.")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit
			EndIf

			// valida o status do carregamento
			If (Z43->Z43_STATUS == "R")
				// mensagem
				U_FtWmsMsg("A OS " + _cNumOS + ", Carga " + _cNrCarga + " ou Pedido " + _cNrPedido + " já carregado na CESV: " + Z43->Z43_CESV)
				// retorno
				_lRet := .F.
				// sai do loop
				Exit
			EndIf

			// posiciono na Z05
			dbSelectArea("Z05")
			Z05->(DbSetOrder(1)) // 1-FILIAL+NUMOS
			If ! Z05->(DbSeek( _cSeekZ05 := xFilial("Z05") + _cNumOS ))
				// mensagem
				U_FtWmsMsg("OS " + _cNumOS + " não encontrada!")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit
			EndIf

			// posiciono na Z06
			dbSelectArea("Z06")
			Z06->(DbSetOrder(1)) // 1-FILIAL+NUMOS+SEQOS
			If ! Z06->(DbSeek( _cSeekZ06 := xFilial("Z06") + _cNumOS + _cSeqSrvVol ))
				// mensagem
				U_FtWmsMsg("Sequencia " +_cSeqSrvVol+ " da OS " + _cNumOS+" não encontrada!")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit
			EndIf

			// armazena doca de servico da montagem de volumes
			If (_lRet)
				_cDocaSrv  := Z06->Z06_ENDSRV
				_cArmzServ := Z06->Z06_LOCAL
			EndIf

			// valida se a montagem de volumes ja foi encerrada
			If (_lRet) .And. (Z06->Z06_STATUS != "FI")
				// mensagem
				U_FtWmsMsg("A OS "+Z06->Z06_NUMOS+" ainda não foi liberada para carregamento.")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit
			EndIf

			// retorna o proximo servico, tarefa e atividades planejada da OS
			// 1-Num OS
			// 2-Seq OS
			// 3-Cod Servico
			// 4-Dsc Servico
			// 5-Cod Tarefa
			// 6-Dsc Tarefa
			// 7-Funcao/Rotina
			_aPrxServico := U_FtPrxSrv(_cNumOS, _cSeqSrvVol, _cCodCliFor, _cLojCliFor)

			// atualiza sequencia do proximo servico
			_cSeqSrvCar := _aPrxServico[1][2]

			// posiciono na Z06
			dbSelectArea("Z06")
			Z06->(DbSetOrder(1)) // 1-FILIAL+NUMOS+SEQOS
			If ! Z06->(DbSeek( _cSeekZ06 := xFilial("Z06") + _cNumOS + _cSeqSrvCar ))
				// mensagem
				U_FtWmsMsg("Sequencia " +_cSeqSrvCar+ " da OS " + _cNumOS+" não encontrada!")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit
			EndIf

			// starto a OS selecionada
			If (Z06->Z06_STATUS $ "AG/IN")
				// atualiza o status do servico para EX-EM EXECUCAO
				U_FtWmsSta(;
				Z06->Z06_STATUS,;
				"EX"           ,;
				Z06->Z06_NUMOS ,;
				Z06->Z06_SEQOS  )

			ElseIf (Z06->Z06_STATUS == "PL")
				dbSelectArea("Z06")
				Reclock("Z06")
				Z06->Z06_STATUS := "EX"
				Z06->Z06_DTEMIS := Date()
				Z06->Z06_HREMIS := Time()
				Z06->Z06_DTINIC := Date()
				Z06->Z06_HRINIC := Time()
				Z06->Z06_ENDSRV := _cDocaSrv
				Z06->(MsUnlock())

			ElseIf (Z06->Z06_STATUS == "FI")
				// caso a OS ja tenha sido finalizada
				U_FtWmsMsg("A OS "+Z06->Z06_NUMOS+" já foi finalizada! Aguarde saída do veículo!")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit

			EndIf

			// verifica se o produto pode informar quantidades
			// Se for cliente Sumitomo e o produto estiver configurado para efetuar a integração de barcode (código de barras)
			If (_lRet) .And. (_cCodCliFor == "000316") .And. ( SB1->B1_ZNUMSER == "S" ) .AND. (lSumiBar)
				// Valida se a etiqueta bipada já foi utilizada
				If Select("tZ07") > 0
					DBSelectArea("tZ07")
					tZ07->(DBCloseArea())
				EndIf

				_cQuery := "SELECT Z07_ETQPRD                            "
				_cQuery += "FROM " + RetSqlTab("Z07")
				_cQuery += "WHERE " + RetSqlCond("Z07")
				_cQuery += "       AND Z07_ETQPRD = '"+_cEtiqProd+"'         "
				_cQuery += "	   AND Z07_SEQOS != '001'                "
				_cQuery += "	   AND ( ( Z07_NUMOS != '"+_cNumOS+"' )       "
				_cQuery += "              OR ( Z07_NUMOS = '"+_cNumOS+"'      "
				_cQuery += "                   AND Z07_SEQOS = '003' ) ) "

				TCQuery _cQuery NEW ALIAS "tZ07"

				DBSelectArea("tZ07")
				tZ07->(DBGoTop())

				if !tZ07->(EOF())
					U_FtWmsMsg("Etiqueta " + _cEtiqProd + " já conferida nesta ou outra OS! Estorne o movimento da mesma caso queira utilizá-la novamente.")
					_lRet := .F.
				Else
					_lRet := EtqSumi()
				EndIf
			Else // tela para informar a quantidade
				If (_lRet)
					sfInfQuant()
				EndIf
			EndIf

			// insere quantidade lida na relacao de itens
			If (_lRet)
				dbSelectArea("Z07")
				RecLock("Z07",.t.)
				Z07->Z07_FILIAL	:= xFilial("Z07")
				Z07->Z07_NUMOS	:= Z06->Z06_NUMOS
				Z07->Z07_SEQOS	:= Z06->Z06_SEQOS
				Z07->Z07_CLIENT	:= _cCodCliFor
				Z07->Z07_LOJA	:= _cLojCliFor
				Z07->Z07_ETQPRD	:= _cEtiqProd
				Z07->Z07_PRODUT	:= _aDadosVol[_nDadosVol][2]
				Z07->Z07_NUMSEQ	:= _aDadosVol[_nDadosVol][3]
				Z07->Z07_LOCAL	:= _aDadosVol[_nDadosVol][8]
				Z07->Z07_QUANT	:= _nQtdProd
				Z07->Z07_USUARI := _cCodOper
				Z07->Z07_DATA	:= Date()
				Z07->Z07_HORA	:= Time()
				Z07->Z07_STATUS	:= "C" // C-EM CONFERENCIA / D-CONFERIDO/DISPONIVEL / M-EM MOVIMENTO / A-ARMAZENADO / F-FINALIZADO/CARREGADO / L-LIBERADO
				Z07->Z07_ENDATU	:= _cDocaSrv
				Z07->Z07_ETQVOL := _cIdAgrupa
				Z07->Z07_PEDIDO := _cNrPedido
				Z07->Z07_EMBALA := _aDadosVol[_nDadosVol][9]
				Z07->Z07_PALLET := _aDadosVol[_nDadosVol][1]
				Z07->Z07_UNITIZ := _cCodUnit
				Z07->Z07_PLTORI := _aDadosVol[_nDadosVol][1]
				Z07->Z07_LOTCTL := _cIdLote
				Z07->Z07_PLTCLI := _cPltClie
				Z07->Z07_NUMSER := _aDadosVol[_nDadosVol][14]
				Z07->Z07_DTSERI := _aDadosVol[_nDadosVol][15]
				Z07->(MsUnLock())
			EndIf

			// grava atualizações de etiqueta para fazer na tabela Z56 (etiquetas cliente)
			If (_lRet) .AND. ( !Empty(_aColsSum) )
				For _nX := 1 To Len(_aColsSum)

					// utilizado em caso de etiquetas legado (não foram lidas na entrada)
					_cUpd := " UPDATE " + RetSQLName("Z56")
					_cUpd += " SET Z56_CODETI = '" + _cEtiqProd + "'
					_cUpd += " WHERE D_E_L_E_T_ = '' and Z56_FILIAL = '" + xFilial("Z56") + "'"
					_cUpd += " AND Z56_CODCLI = '" + _cCodCliFor     + "' "
					_cUpd += " AND Z56_LOJCLI = '" + _cLojCliFor     + "' "
					_cUpd += " AND Z56_ETQCLI = '" + _aColsSum[_nX][1] + "' "
					_cUpd += " AND Z56_CODETI = '' "

					Memowrit("c:\query\TWMSA012_update_Z56_1.txt", _cUpd)

					If (TCSQLExec(_cUpd) < 0)
						//				Return U_FtWmsMsg("TCSQLError() " + TCSQLError(),"ERRO")
						U_FtWmsMsg("Erro ao atualizar etiquetas do cliente (1)!" ,"Erro TWMSA012 - Update Z56")
					EndIf

					// grava registro de saída
					_cUpd := " UPDATE " + RetSQLName("Z56")
					_cUpd += " SET Z56_OK_SAI = 'S'"
					_cUpd += " WHERE D_E_L_E_T_ = '' and Z56_FILIAL = '" + xFilial("Z56") + "'"
					_cUpd += " AND Z56_CODCLI = '" + _cCodCliFor     + "' "
					_cUpd += " AND Z56_LOJCLI = '" + _cLojCliFor     + "' "
					_cUpd += " AND Z56_ETQCLI = '" + _aColsSum[_nX][1] + "' "

					Memowrit("c:\query\TWMSA012_update_Z56_2.txt", _cUpd)

					If (TCSQLExec(_cUpd) < 0)
						//				Return U_FtWmsMsg("TCSQLError() " + TCSQLError(),"ERRO")
						U_FtWmsMsg("Erro ao atualizar etiquetas do cliente (2)!" ,"Erro TWMSA012 - Update Z56")
					EndIf
				Next _nX
			EndIf

			// proximo item
		Next _nDadosVol

		// atualiza os dados do browse
		sfSelDados(.t.)

		// reinicia variaveis
		_cCodProd  := Space(_nTamCodPrd)
		_cDscProd  := ""
		_cEtiqProd := Space(Len(_cEtiqProd))
		_cIdPalete := Space(_nTamIdPal)
		_cIdLote   := Space(_nTamIdLot)
		_cPltClie  := Space(_nTamPlCli)

	EndIf

	// foca no objeto cod produto
	_oGetCodProd:SetFocus()

Return(.t.)

// ** funcao para informar a quantidade manualmente (para produtos de pequeno porte)
Static Function sfInfQuant()
	// objetos
	local _oBtnFoco1
	// controle para nao fechar a tela
	Local _lRetOk := .F.

	// reinicia segunda unidade de medida
	_nQtdSegUM := 0

	// monta a tela para informa a quantidade
	_oWndInfQuant := MSDialog():New(020,020,220,200,"Informe a Quantidade",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlInfQtdCab := TPanel():New(000,000,nil,_oWndInfQuant,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlInfQtdCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpInfQtdOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRetOk := sfVldObg() ,_oWndInfQuant:End() },_oPnlInfQtdCab,"Ok",,.T.)

	_oBmpInfQtdOk:Align := CONTROL_ALIGN_LEFT

	_oGetQuant   := TGet():New(033,005,{|u| If(PCount()>0,_nQtdProd:=u,_nQtdProd)},_oWndInfQuant,060,010,PesqPict("SD1","D1_QUANT")  ,{|| Positivo() .And. sfVldQuant(2)}                          ,,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nQtdProd",,,,,,,"Quantidade ("+SB1->B1_UM+"):",1)
	_oGetLotProd := TGet():New(055,005,{|u| If(PCount()>0,_cIdLote:=u,_cIdLote)},_oWndInfQuant,060,010,PesqPict("SB8","B8_LOTECTL"),{||Iif(_lCtrLote,{|| sfValIndAd("L"),_oBmpInfQtdOk:Click()},{||.T.})},,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIdLote",,,,,,,"Lote"                        ,1)
	_oGetPalCli  := TGet():New(075,005,{|u| If(PCount()>0,_cPltClie:=u,_cPltClie)},_oWndInfQuant,060,010,PesqPict("Z07","Z07_PLTCLI"),{||Iif(_lCtrLote,{||.T.},{||_oBmpInfQtdOk:Click()})}        ,,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cPltClie",,,,,,,"Plt. Clie."                  ,1)

	If !(_lInfManual)
		_oGetQuant:Disable()
	EndIf

	If !(_lCtrLote)
		_oGetLotProd:Disable()
	EndIf


	If !(_lInfManual)
		_oGetQuant:Disable()
	EndIf

	If !(_lCtrLote)
		_oGetLotProd:Disable()
	EndIf

	// seta o foco na quantidade
	_oGetQuant:SetFocus()

	// ativacao da tela com validacao
	_oWndInfQuant:Activate(,,,.T.,{|| _lRetOk })

Return()

// ** validade preenchimento de lote e data de validade
Static Function sfVldObg()

	If ( Empty(_cIdLote) ) .AND. (_lCtrLote)
		U_FtWmsMsg("O lote precisa ser informado.","Atenção")
		Return (.F.)
	EndIf

	If ( Empty(_nQtdProd) )
		U_FtWmsMsg("A quantidade precisa ser informada.","Atenção")
		Return (.F.)
	EndIf

Return (.T.)

// ** funcao que calcula as unidade de medidas
Static Function sfVldQuant(mvUndRet)

	If (_nQtdProd>0) .Or. (_nQtdSegUM>0)
		If (!Empty(SB1->B1_SEGUM)) .And. (SB1->B1_CONV>0)
			// retorna a 1a Unid Medida
			If (mvUndRet==1)
				_nQtdProd := ConvUM(SB1->B1_COD,_nQtdProd,_nQtdSegUM,mvUndRet)
				// 2a Unid Medida
			ElseIf (mvUndRet==2)
				_nQtdSegUM := ConvUM(SB1->B1_COD,_nQtdProd,_nQtdSegUM,mvUndRet)
			EndIf
		EndIf
	EndIf

Return(.T.)

// ** Função para validar Quantidade e Lote
Static Function sfValIndAd(mvCampoVal)

	Local _lRet        := .T.
	Default mvCampoVal := "Q" //Q=Quantidade | L= Lote | P= Palete Cliente

	If (mvCampoVal == "Q")

		If (_lInfManual)
			If (_nQtdProd <= 0)
				_lRet := .F.
				U_FtWmsMsg("Informar Quantidade Maior que 0 !","ATENCAO")
				_oGetQuant:SetFocus()
				Return(_lRet)
			EndIf
		EndIf

		sfVldQuant(2)

	ElseIf (mvCampoVal == "L")

		If (_lCtrLote)
			If (Empty(_cIdLote))
				_lRet := .F.
				U_FtWmsMsg("Obrigatório informar Lote !","ATENCAO")
				_oGetLotProd:SetFocus()
				Return(_lRet)
			Else

				//Verifica se Lote existe para o produto
				DbSelectArea("Z45")
				Z45->(DbSetOrder(3))//Z45_FILIAL+Z45_LOCAL+Z45_CODPRO+Z45_LOTCTL+Z45_PEDIDO
				Z45->(DbGoTop())

				If !Z45->(DbSeek(xFilial("Z45") + _cArmzServ + SB1->B1_COD + _cIdLote + _cPedido))
					_lRet := .F.
					U_FtWmsMsg("Lote informado não encontrado!","ATENCAO")
					_oGetLotProd:SetFocus()
				EndIf

				//Verifica se lote lido corresponde ao lote da etiqueta
				DbSelectArea("Z16")
				Z16->(DbSetOrder(2))	//Z16_FILIAL, Z16_ETQPRD, R_E_C_N_O_, D_E_L_E_T_
				Z16->(DbGoTop())

				//posiciona na etiqueta
				Z16->( DbSeek( xFilial("Z16") + _cEtiqProd ) )

				If ( _cIdLote != Z16->Z16_LOTCTL )
					_lRet := .F.
					U_FtWmsMsg("Lote informado não encontrado!","ATENCAO")
					_oGetLotProd:SetFocus()
				EndIf

			EndIf
		EndIf

	ElseIf (mvCampoVal == "P")

	EndIf

Return(_lRet)

// ** funcao que apresenta os detalhes da conferencia
Static Function sfDetConfer()
	// objetos
	local _oWndConfDet
	local _oPnlConfDet
	local _oBmpConsDetSair
	local _oBrwConsDet
	// browse
	local _aHeadDet := {}
	local _aColsDet := {}
	local _cQuery
	// quantidade total
	local _nQtdTot := 0
	// total de paletes
	local _nTotPalete := 0
	// total de volumes
	local _nTotVolume := 0

	// botão de estorno
	local _oBmpEstorno
	// botão de sair
	local _oBmpConsDetSair

	// variaveis temporarias
	local _cTmpPlt := ""
	local _cTmpVlm := ""

	// monta a query
	_cQuery := "SELECT CASE WHEN Z07_STATUS = 'L' THEN 'OK' ELSE '  ' END Z07_STATUS, "
	_cQuery += "SUM(Z07_QUANT) Z07_QUANT, B1_COD, B1_DESC, Z07_PALLET, Z07_ETQPRD, Z07_ETQVOL, Z07_ETQCLI, '.F.' IT_DEL "
	// itens carregados/conferidos
	_cQuery += "FROM " + RetSqlTab("Z07") + " (nolock) "

	// itens da ordem de servico
	_cQuery += " INNER JOIN " + RetSqlTab("Z06") + " (nolock)  ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z07_NUMOS AND Z06_SEQOS = Z07_SEQOS "
	_cQuery += " AND Z06_SERVIC IN " + _cSqlCodSrv + " AND Z06_TAREFA = '" + _cCodTaref + "' "

	// cad. produtos
	_cQuery += " INNER JOIN " + RetSqlTab("SB1") + " (nolock)  ON " + RetSqlCond("SB1") + " AND B1_COD = Z07_PRODUT "

	// filtro padrao
	_cQuery += "WHERE " + RetSqlCond("Z07") + " "

	// numero da OS
	_cQuery += "AND Z07_NUMOS IN " + _cNumOrdSrv
	// cliente e loja
	_cQuery += "AND Z07_CLIENT = '" + _cCodCliFor + "' AND Z07_LOJA  = '" + _cLojCliFor + "' "
	// status
	_cQuery += "AND Z07_STATUS IN ('C','L')" // C-EM CONFERENCIA / L-LIBERADO
	// conferencia por pedido
	If (_lPorPedido)
		_cQuery += " AND Z07_PEDIDO = '" + _cPedUnico + "' "
	EndIf
	// agrupamento dos dados
	_cQuery += "GROUP BY CASE WHEN Z07_STATUS = 'L' THEN 'OK' ELSE '  ' END, B1_COD, B1_DESC, Z07_PALLET, Z07_ETQPRD, Z07_ETQVOL, Z07_ETQCLI "
	// ordem dos dados
	_cQuery += "ORDER BY Z07_PALLET, Z07_ETQPRD, Z07_ETQVOL, Z07_ETQCLI "

	memowrit("C:\query\TWMSA020_sfDetConfer.txt",_cQuery)

	// atualiza o vetor do browse
	_aColsDet := U_SqlToVet(_cQuery)

	// calcula a quantidade total de palete
	aEval(_aColsDet,{|x| _nQtdTot += x[2] , IIf(_cTmpPlt <> x[5], _nTotPalete ++, Nil), _cTmpPlt := x[5] })

	// calcula a quantidade total de volume
	aEval(_aColsDet,{|x| IIf(_cTmpVlm <> (x[6] + x[7] + x[8]), _nTotVolume ++, Nil), _cTmpVlm := (x[6] + x[7] + x[8]) })

	// adiciona a linha com o total
	aAdd(_aColsDet,{"",_nQtdTot   ,"TOTAL"    ,"","","","","",.F.})
	aAdd(_aColsDet,{"",_nTotVolume,"TOTAL VOL","","","","","",.F.})
	aAdd(_aColsDet,{"",_nTotPalete,"TOTAL PLT","","","","","",.F.})

	// define o header
	aAdd(_aHeadDet,{"Sts"        , "Z07_STATUS"  ,""                           ,2                      ,0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Quant"      , "Z07_QUANT"   ,PesqPict("Z07","Z07_QUANT")  ,TamSx3("Z07_QUANT")[1] ,TamSx3("Z07_QUANT")[2],Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Produto"    , "B1_COD"      ,""                           ,TamSx3("B1_COD")[1]    ,0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Desc Prod"  , "B1_DESC"     ,""                           ,TamSx3("B1_DESC")[1]   ,0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Id Palete"  , "Z07_PALLET"  ,PesqPict("Z07","Z07_PALLET") ,TamSx3("Z07_PALLET")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Etq Produto", "Z07_ETQPRD"  ,PesqPict("Z07","Z07_ETQPRD") ,TamSx3("Z07_ETQPRD")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Etq Volume" , "Z07_ETQVOL"  ,PesqPict("Z07","Z07_ETQVOL") ,TamSx3("Z07_ETQVOL")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Etq.Cliente", "Z07_ETQCLI"  ,PesqPict("Z07","Z07_ETQCLI") ,TamSx3("Z07_ETQCLI")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })

	// monta o dialogo do monitor
	_oWndConfDet := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Detalhes",,,.F.,,,,,,.T.,,,.T. )
	_oWndConfDet:lEscClose := .F.

	// cria o panel do cabecalho - botoes
	_oPnlConfDet := TPanel():New(000,000,nil,_oWndConfDet,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlConfDet:Align:= CONTROL_ALIGN_TOP

	// -- BOTAO DE ESTORNO
	_oBmpEstorno := TBtnBmp2():New(000,000,030,022,"ESTOMOVI",,,,{|| If( sfEstornoPlt(_oBrwConsDet:aCols[_oBrwConsDet:nAt][6], _oBrwConsDet:aCols[_oBrwConsDet:nAt][7], _oBrwConsDet:aCols[_oBrwConsDet:nAt][8]), _oWndConfDet:End(), Nil) },_oPnlConfDet,"Estornar conferência",,.T.)
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
Static Function sfFinalizaOS(mvTela, mvOk)

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

	// area atual
	Local aAreaAtu := GetArea()

	// estrutura do arquivo de trabalho e Browse
	Local aEstBrowse := {}
	Local aHeadBrowse := {}
	Local cMarca := Z07->(GetMark())

	// controle de divergencias
	Local _lDiverg := .F.

	// informacoes do resumo
	local _nTotPesoB  := 0
	local _nTotCubag  := 0
	local _nTotVolume := 0
	local _nTotPalete := 0

	// controle de confirmacao da tela
	local _lOk := .F.

	private cArqTmp
	private _TRBCNF := GetNextAlias()

	// confirmacao do processamento
	If ( ! U_FtYesNoMsg("Finalizar Pedido?", "Atenção"))
		Return(.F.)
	EndIf

	// verifica se ha algum palete nao finalizado
	_cQryConf := " SELECT COUNT(*) QTD_ITENS "
	// itens conferidos
	_cQryConf += " FROM " + RetSqlTab("Z07") + " (nolock) "
	// filtro padrao
	_cQryConf += " WHERE " + RetSqlCond("Z07") + " "
	// nr da OS
	_cQryConf += " AND Z07_NUMOS  IN " + _cNumOrdSrv
	// pedido
	_cQryConf += " AND Z07_PEDIDO IN " + _cAllPedidos
	// somente C=EM CONFERENCIA
	_cQryConf += " AND Z07_STATUS  = 'C' "

	// executa a query de verificacao
	If (U_FtQuery(_cQryConf)>0)
		// mensagem
		U_FtWmsMsg("Há paletes com conferência não finalizada!", "Finalizar")
		// retorno
		Return(.F.)
	EndIf

	// fecha o alias
	If (Select(cNewAlias)!=0)
		dbSelectArea(cNewAlias)
		dbCloseArea()
	EndIf

	// monta a query
	_cQryConf := "SELECT "
	_cQryConf += "'  ' IT_OK, "
	_cQryConf += "'OK' IT_COR, "
	_cQryConf += "C6_NUM, "
	_cQryConf += "C6_PRODUTO, "
	_cQryConf += "B1_DESC, "
	_cQryConf += "B1_UM, "
	// quantidade solicitada
	_cQryConf += "Sum(Isnull(Z45_QUANT, C6_QTDVEN)) C6_QTDVEN, "
	// quantidade CARREGADA conferida
	_cQryConf += "(SELECT ISNULL(SUM(Z07_QUANT), 0) "
	_cQryConf += "FROM " + RetSqlTab("Z07") + " (NOLOCK) "
	_cQryConf += "WHERE " + RetSqlCond("Z07")
	_cQryConf += "AND Z07_NUMOS IN " + _cNumOrdSrv
	_cQryConf += "AND Z07_SEQOS  = Z06_SEQOS "
	_cQryConf += "AND Z07_PRODUT = C6_PRODUTO "
	_cQryConf += "AND Z07_PEDIDO = C6_NUM "
	_cQryConf += "AND Z07_LOTCTL = ISNULL(Z45_LOTCTL, C6_LOTECTL) "
	_cQryConf += "AND Z07_STATUS = 'L') QTD_CARREG, "
	// quantidade na montagem de volumes
	_cQryConf += "(SELECT ISNULL(SUM(Z07_QUANT), 0) "
	_cQryConf += "FROM " + RetSqlTab("Z07") + " (NOLOCK) "
	_cQryConf += "WHERE " + RetSqlCond("Z07")
	// na versao 1, pesquisa pelo mesmo numero da ordem de sevico
	If (_nVersCarreg == 1)
		_cQryConf += "AND Z07_NUMOS IN " + _cNumOrdSrv
		_cQryConf += "AND Z07_SEQOS != Z06_SEQOS "
	EndIf
	_cQryConf += "AND Z07_PRODUT = C6_PRODUTO "
	_cQryConf += "AND Z07_PEDIDO = C6_NUM "
	_cQryConf += "AND Z07_LOTCTL = ISNULL(Z45_LOTCTL, C6_LOTECTL) "
	_cQryConf += "AND Z07_STATUS IN ('F','D')) QTD_MNTVOL, "
	// quantidade de palete conferido
	_cQryConf += "(SELECT COUNT(DISTINCT Z07_PALLET) "
	_cQryConf += "FROM " + RetSqlTab("Z07") + " (NOLOCK) "
	_cQryConf += "WHERE " + RetSqlCond("Z07")
	_cQryConf += "AND Z07_NUMOS  IN " + _cNumOrdSrv
	_cQryConf += "AND Z07_SEQOS   = Z06_SEQOS "
	_cQryConf += "AND Z07_PEDIDO IN " + _cAllPedidos
	_cQryConf += "AND Z07_PRODUT  = C6_PRODUTO "
	_cQryConf += "AND Z07_LOTCTL = ISNULL(Z45_LOTCTL, C6_LOTECTL) "
	_cQryConf += "AND Z07_STATUS  = 'L') QTD_PALETE "
	// quantidade de volumes
	If (_lCtrVolume)
		_cQryConf += ",("
		_cQryConf += " SELECT ISNULL(COUNT(DISTINCT Z07_ETQVOL + Z07_ETQCLI),0) FROM " + RetSqlTab("Z07") + " (nolock) "
		_cQryConf += " WHERE " + RetSqlCond("Z07") + " "
		_cQryConf += " AND Z07_NUMOS IN " + _cNumOrdSrv+" AND Z07_SEQOS = Z06_SEQOS
		_cQryConf += " AND Z07_PEDIDO = C6_NUM "
		_cQryConf += ") QTD_VOLUME "
	EndIf
	// ordem de servico
	_cQryConf += "FROM " + RetSqlTab("Z05") + " (NOLOCK) "

	// itens da ordem de servico
	_cQryConf += " INNER JOIN " + RetSqlTab("Z06") + " (nolock)  ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z05_NUMOS "
	_cQryConf += " AND Z06_SERVIC IN " + _cSqlCodSrv + " AND Z06_TAREFA = '" + _cCodTaref + "' "

	// itens programados para o carregamento
	_cQryConf += "        INNER JOIN " + RetSqlTab("Z43") + " (nolock) "
	_cQryConf += "                ON " + RetSqlCond("Z43")
	_cQryConf += "                   AND Z43_CESV = '" + _cNumCESV + "' "
	_cQryConf += "                   AND Z43_NUMOS = Z05_NUMOS "
	_cQryConf += "                   AND Z43_STATUS <> 'C' "

	// cab. pedido de venda
	_cQryConf += " INNER JOIN " + RetSqlTab("SC5") + " (NOLOCK) ON " + RetSqlCond("SC5") + " AND C5_ZCARGA = Z43_CARGA AND C5_NUM = Z43_PEDIDO "
	// pedido
	_cQryConf += " AND C5_NUM IN " + _cAllPedidos

	// itens do pedido de venda
	_cQryConf += " INNER JOIN " + RetSqlTab("SC6") + " (NOLOCK) ON " + RetSqlCond("SC6") + " AND C6_NUM = C5_NUM "

	// cad. de produto
	_cQryConf += " INNER JOIN " + RetSqlTab("SB1") + " (NOLOCK) ON " + RetSqlCond("SB1")+ "AND B1_COD = C6_PRODUTO "

	// reserva de lotes
	_cQryConf += "        LEFT JOIN " + RetSqlTab("Z45") + " (nolock) "
	_cQryConf += "               ON " + RetSqlCond("Z45")
	_cQryConf += "                  AND Z45_PEDIDO = C6_NUM "
	_cQryConf += "                  AND Z45_ITEM = C6_ITEM "
	_cQryConf += "                  AND Z45_CODPRO = C6_PRODUTO "

	// filtro padrao da OS
	_cQryConf += " WHERE " + RetSqlCond("Z05")

	// numero da OS
	_cQryConf += " AND Z05_NUMOS IN " + _cNumOrdSrv
	// agrupa dados
	_cQryConf += " GROUP BY C6_NUM, C6_PRODUTO, C6_LOTECTL, B1_DESC, B1_UM, Z06_SEQOS, Z45_LOTCTL "
	// ordem dos dados
	_cQryConf += " ORDER BY C6_PRODUTO "

	memowrit("c:\QUERY\twmsa020_sfFinalizaOS.txt",_cQryConf)

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

	// erro nos dados
	If ((_TRBCNF)->(Eof()))
		// mensagem
		U_FtWmsMsg("Nenhum palete conferido.","ATENCAO")
		// retorno
		Return(.F.)
	EndIf

	// verifica itens com divergencia
	(_TRBCNF)->(dbSelectArea(_TRBCNF))
	(_TRBCNF)->(dbGoTop())

	// análise das divergências
	While (_TRBCNF)->(!Eof())

		// edita registro
		(_TRBCNF)->(RecLock(_TRBCNF,.F.))
		// atualiza status do item
		(_TRBCNF)->IT_OK		:= IIf(((_TRBCNF)->C6_QTDVEN <> (_TRBCNF)->QTD_CARREG) .Or. ((_lCtrVolume) .And. ( ! _lEtqClient ) .And. ((_TRBCNF)->QTD_MNTVOL <> (_TRBCNF)->QTD_CARREG)), cMarca, Space(2))
		(_TRBCNF)->IT_COR		:= IIf(((_TRBCNF)->C6_QTDVEN <> (_TRBCNF)->QTD_CARREG) .Or. ((_lCtrVolume) .And. ( ! _lEtqClient ) .And. ((_TRBCNF)->QTD_MNTVOL <> (_TRBCNF)->QTD_CARREG)), Space(2), cMarca)
		(_TRBCNF)->(MsUnLock())

		// verifica se tem divergencias
		If ( ! Empty((_TRBCNF)->IT_OK))
			_lDiverg := .t.
		EndIf

		// atualiza variaveis do resumo
		_nTotVolume := IIf(_lCtrVolume, (_TRBCNF)->QTD_VOLUME, _nTotVolume += (_TRBCNF)->QTD_PALETE)
		_nTotPalete += (_TRBCNF)->QTD_PALETE

		// proximo item
		(_TRBCNF)->(dbSkip())
	EndDo

	// atualiza variaveis do resumo
	_nTotCubag := sfRetCubEmb()

	// abre o arquivo de trabalho
	(_TRBCNF)->(dbSelectArea(_TRBCNF))
	(_TRBCNF)->(dbGoTop())

	// inclui detalhes e titulos dos campos do browse
	aAdd(aHeadBrowse,{"IT_OK"     , Nil, "  "           , "@!"                        })
	aAdd(aHeadBrowse,{"C6_PRODUTO", Nil, "Cód. Produto" , "@!"                        })
	aAdd(aHeadBrowse,{"B1_DESC"   , Nil, "Descrição"    , "@!"                        })
	aAdd(aHeadBrowse,{"B1_UM"     , Nil, "Und.Med."     , "@!"                        })
	aAdd(aHeadBrowse,{"C6_QTDVEN" , Nil, "Qtd.PV"       , PesqPict("SC6","C6_QTDVEN") })
	aAdd(aHeadBrowse,{"QTD_CARREG", Nil, "Qtd.Carregada", PesqPict("Z07","Z07_QUANT") })
	aAdd(aHeadBrowse,{"QTD_MNTVOL", Nil, "Qtd.Mnt.Vol." , PesqPict("Z07","Z07_QUANT") })

	// abre o arquivo de trabalho
	(_TRBCNF)->(dbSelectArea(_TRBCNF))
	(_TRBCNF)->(dbGoTop())

	// monta a tela com os detalhes da finalizacao total da OS
	_oWndConFinal := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Conf. Carregamento",,,.F.,,,,,,.T.,,,.T. )
	_oWndConFinal:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlCfeFinCab1 := TPanel():New(000,000,nil,_oWndConFinal,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlCfeFinCab1:Align:= CONTROL_ALIGN_TOP

	// INICIO - define os botoes de operacao  =====

	// define o botao para finalizar a conferencia - botão só é aparente quando NÃO há divergências
	If ( ! _lDiverg )
		_oBmpCfeFinConf := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| MsgRun("Aguarde. Finalizando Dados...",,{|| _lOk := sfFinServico(@_oWndConFinal) }) },_oPnlCfeFinCab,"Finaliza a Conferência",,.T. )
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
	_oBrwFinaliza := MsSelect():New( _TRBCNF,"IT_OK",,aHeadBrowse,,cMarca,{15,1,183,373},,,,,;
	{{"Empty((_TRBCNF)->IT_COR)","DISABLE"},{"!(Empty((_TRBCNF)->IT_COR))","ENABLE"}})
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
	local _aAreaIni := SaveOrd({"Z07","SZZ","Z16","SC5"})
	// variavel de retorno
	local _lRet := .t.
	// finaliza conferência
	local _cQryZ07 := ""
	// itens conferidos
	local _aDadosZ07 := {}
	local _nDadosZ07
	// retorna o próximo serviço
	local _aPrxServico := {}

	// numero da carga
	local _cNumCarga := ""

	// se todo o processo ocorreu corretamente
	If (_lRet)

		// monta SQL para estornar o palete
		_cQryZ07 := " SELECT Z07.R_E_C_N_O_ Z07RECNO, ISNULL(Z16.R_E_C_N_O_,0) Z16RECNO, Z07_PEDIDO, Z16_CARGA, Z07_NUMOS, Z07_SEQOS "
		// itens em conferencia
		_cQryZ07 += " FROM " + RetSqlTab("Z07") + " (nolock) "

		// itens da ordem de servico
		_cQryZ07 += " INNER JOIN " + RetSqlTab("Z06") + " (nolock)  ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z07_NUMOS AND Z06_SEQOS = Z07_SEQOS "
		_cQryZ07 += " AND Z06_SERVIC IN " + _cSqlCodSrv + " AND Z06_TAREFA = '" + _cCodTaref + "' "

		// composicao do palete
		_cQryZ07 += " INNER JOIN " + RetSqlTab("Z16") + " (nolock)  ON " + RetSqlCond("Z16") + " AND Z16_ETQPAL = Z07_PALLET "
		_cQryZ07 += "      AND Z16_ETQVOL = Z07_ETQVOL AND Z16_ETQPRD = Z07_ETQPRD "
		_cQryZ07 += "      AND Z16_CODPRO = Z07_PRODUT AND Z16_ENDATU = Z07_ENDATU "
		_cQryZ07 += "      AND Z16_ETQCLI = Z07_ETQCLI "

		// filtro padrao
		_cQryZ07 += " WHERE " + RetSqlCond("Z07")
		// filtro por OS
		_cQryZ07 += " AND Z07_NUMOS IN " + _cNumOrdSrv
		// cliente e loja
		_cQryZ07 += " AND Z07_CLIENT = '" + _cCodCliFor + "' AND Z07_LOJA  = '" + _cLojCliFor + "' "
		// L-LIBERADO / F-FINALIZADO
		_cQryZ07 += " AND Z07_STATUS IN ('L', 'F') "
		// somente os pedidos selecionados anteriormente
		_cQryZ07 += " AND Z07_PEDIDO IN " + _cAllPedidos

		memowrit("c:\query\twmsa020_sfFinServico.txt",_cQryZ07)

		// atualiza os dados dos itens conferidos
		_aDadosZ07 := U_SqlToVet(_cQryZ07)

		// valida quantidade de dados
		If (Len(_aDadosZ07) == 0)
			// mensagem
			U_FtWmsMsg("Inconsistência na operação para finalizar carregamento!","ATENCAO")
			// variavel de retorno
			_lRet := .F.
			// retorno
			Return(_lRet)
		EndIf

		// inicia transacao
		BEGIN TRANSACTION

			// varre todos os itens para atualiza o status e o saldo por palete
			For _nDadosZ07 := 1 to Len(_aDadosZ07)

				// posiciona no registro - 1-RECNO Z07
				dbSelectArea("Z07")
				Z07->( dbGoTo(_aDadosZ07[_nDadosZ07][1]) )

				// atualiza o STATUS
				RecLock("Z07")
				Z07->Z07_STATUS := "F" // F-FINALIZADO/CARREGADO
				Z07->(MsUnLock())

				// posiciona no registro para atualiza o saldo do palete - 2-RECNO Z16
				dbSelectArea("Z16")
				Z16->( dbGoTo( _aDadosZ07[_nDadosZ07][2] ) )

				// zera o saldo da etiqueta
				RecLock("Z16")
				Z16->Z16_SALDO := 0
				Z16->(MsUnLock())

				// atualiza numero da carga
				_cNumCarga := _aDadosZ07[_nDadosZ07][4]

				// se nao tem informado no palete, busca da ordem de servico
				If (Empty(_cNumCarga))
					_cNumCarga := _cCargaUnic
				EndIf

				// atualiza campo de carregamento baseado no pedido
				dbSelectArea("SC5")
				SC5->( dbSetOrder(1) )
				SC5->( dbSeek( xFilial("SC5") + _aDadosZ07[_nDadosZ07][3] ) )

				// grava os dados na C5
				Reclock("SC5")
				SC5->C5_ZCARREG := "S"
				SC5->(MsUnlock())

				// atualiza o status do Pedido relacionado ao CESV
				dbSelectArea("Z43")
				Z43->(DbSetOrder(3)) // 3-Z43_FILIAL, Z43_NUMOS, Z43_CARGA, Z43_PEDIDO, Z43_CESV
				If ( Z43->(DbSeek( _cSeekZ43 := xFilial("Z43") + _aDadosZ07[_nDadosZ07][5] + _cNumCarga + _aDadosZ07[_nDadosZ07][3] + _cNumCESV ) ) )
					// atualiza status
					RecLock("Z43")
					Z43->Z43_STATUS := "R" // R-Realizado / P-Planejado / C-Cancelado
					Z43->(MsUnLock())
				EndIf

				// se for etiqueta de cliente
				If (_lEtqClient) .And. ( ! Empty(Z16->Z16_ETQCLI) )

					// procura o codigo da etiqueta do cliente / importado anteriormente
					dbSelectArea("Z56")
					Z56->( DbSetOrder(2) ) // 2-Z56_FILIAL, Z56_ETQCLI, Z56_CODCLI, Z56_LOJCLI
					If ( Z56->( DbSeek( xFilial("Z56") + Z16->Z16_ETQCLI + _cCodCliFor + _cLojCliFor )) )
						RecLock("Z56", .F.)
						Z56->Z56_OK_SAI := "S"
						Z56->(MsUnLock())
					EndIf

				EndIf

				// proximo item
			Next _nDadosZ07

			// finaliza transacao
		END TRANSACTION

		// fecha a tela principal
		mvWndConFinal:End()
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni,.t.)
	RestArea(_aArea)

Return(_lRet)

// ** funcao para gerar um novo palete
Static Function sfNovoPalete()
	local _cUpdZ07
	local _nX
	// aCols temporaria
	local _aTmpCols := aClone(_oBrwConfExpe:aCols)
	// posicao do campo ID Palete
	local _nPosIdPlt  := aScan(_aHeadConf,{|x| (AllTrim(x[2]) == "Z07_PALLET" ) })
	// posicao do campo etiqueta produto
	local _nPosEtqPrd := aScan(_aHeadConf,{|x| (AllTrim(x[2]) == "Z07_PRODUT" ) })

	// mensagem de confirmacao
	If ( ! U_FTYesNoMsg("Confirma novo palete ?", "Palete"))
		Return(.F.)
	EndIf

	// varre todos os itens do browse
	For _nX := 1 to Len(_aTmpCols)

		// finaliza os itens conferidos
		_cUpdZ07 := "UPDATE " + RetSqlName("Z07") + " "
		// status finalizado // L-LIBERADO
		_cUpdZ07 += "SET Z07_STATUS = 'L' "
		// filtro padrao
		_cUpdZ07 += "WHERE Z07_FILIAL = '" + xFilial("Z07") + "' AND D_E_L_E_T_ = ' ' "
		// filtro da OS especifica
		_cUpdZ07 += "AND Z07_NUMOS IN " + _cNumOrdSrv
		// status C=EM CONFERENCIA
		_cUpdZ07 += "AND Z07_STATUS = 'C' "
		// id palete
		_cUpdZ07 += "AND Z07_PALLET = '" + _aTmpCols[_nX][_nPosIdPlt] + "' "
		// etiqueta produto
		_cUpdZ07 += "AND Z07_PRODUT = '" + _aTmpCols[_nX][_nPosEtqPrd] + "' "

		// executa o update
		TcSQLExec(_cUpdZ07)

	Next _nX

	// atualiza variaveis
	_lNovoPalete := .t.
	_cEtiqProd   := Space(Len(_cEtiqProd))
	_cCodProd    := Space(_nTamCodPrd)
	_nQtdProd    := 1
	_cIdPalete   := Space(_nTamIdPal)

	// atualiza os dados
	sfSelDados( .T. )

	// atualiza o objeto para receber o foco
	_oGetCodProd:SetFocus()

Return( .T. )

// ** funcao para estorno do palete
Static Function sfEstornoPlt(mvEtqProd, mvEtqVolume, mvEtqCliente)
	// query
	local _cQryZ07, _cUpd
	// variaveis temporarias
	local _aTmpRecno := {}
	local _nX
	// variavel de retorno
	local _lRet := .F.

	// valida dados
	If (Empty(mvEtqProd)) .And. (Empty(mvEtqVolume)) .And. (Empty(mvEtqCliente))
		// mensagem
		U_FtWmsMsg("Não há dados para estorno!","ATENCAO")
		// retorno
		Return(_lRet)
	EndIf

	// confirmacao do processamento
	If ( ! Empty(mvEtqProd) ) .And. ( ! U_FtYesNoMsg("Confirmar estorno da etiqueta "+Transf(mvEtqProd,_cMskEtiq) + "?", "Atenção"))
		// retorno
		Return(_lRet)
	ElseIf ( ! Empty(mvEtqVolume) ) .And. ( ! U_FtYesNoMsg("Confirmar estorno do volume "+Transf(mvEtqVolume,_cMskEtiq) + "?", "Atenção"))
		// retorno
		Return(_lRet)
	ElseIf ( ! Empty(mvEtqCliente) ) .And. ( ! U_FtYesNoMsg("Confirmar estorno da etq cliente " + Transf(mvEtqCliente, _cMskCodBar) + " ?", "Atenção"))
		// retorno
		Return(_lRet)
	EndIf

	// monta SQL para estornar o palete
	_cQryZ07 := " SELECT Z07.R_E_C_N_O_ Z07RECNO, Z16.R_E_C_N_O_ Z16RECNO "
	// itens em conferencia
	_cQryZ07 += " FROM " + RetSqlTab("Z07")
	// itens da ordem de servico
	_cQryZ07 += " INNER JOIN " + RetSqlTab("Z06") + " (nolock)  ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z07_NUMOS AND Z06_SEQOS = Z07_SEQOS "
	_cQryZ07 += " AND Z06_SERVIC IN " + _cSqlCodSrv + " AND Z06_TAREFA = '" + _cCodTaref + "' "

	// itens componentes do palete
	_cQryZ07 += "        INNER JOIN " + RetSqlTab("Z16")
	_cQryZ07 += "                ON " + RetSqlCond("Z16")
	_cQryZ07 += "                   AND Z16_ETQVOL = Z07_ETQVOL "
	_cQryZ07 += "                   AND Z16_ETQPRD = Z07_ETQPRD "
	_cQryZ07 += "                   AND Z16_ETQPAL = Z07_PALLET "
	_cQryZ07 += "                   AND Z16_ETQCLI = Z07_ETQCLI "

	// filtro padrao
	_cQryZ07 += " WHERE " + RetSqlCond("Z07")
	// filtro por OS
	_cQryZ07 += " AND Z07_NUMOS  IN " + _cNumOrdSrv
	// cliente
	_cQryZ07 += " AND Z07_CLIENT  = '" + _cCodCliFor + "' AND Z07_LOJA  = '" + _cLojCliFor + "' "
	// pedido
	_cQryZ07 += " AND Z07_PEDIDO IN " + _cAllPedidos
	// codigo da etiqueta agrupadora
	If ( ! Empty(mvEtqVolume) )
		_cQryZ07 += " AND Z07_ETQVOL = '" + mvEtqVolume + "' "
	EndIf
	// codigo da etiqueta de produto
	If ( ! Empty(mvEtqProd) )
		_cQryZ07 += " AND Z07_ETQPRD = '" + mvEtqProd + "' "
	EndIf
	// codigo da etiqueta de cliente
	If ( ! Empty(mvEtqCliente) )
		_cQryZ07 += " AND Z07_ETQCLI = '" + mvEtqCliente + "' "
	EndIf
	// status L-LIBERADO
	_cQryZ07 += " AND Z07_STATUS in ('C', 'L') " // para os status conferido e cancelado permite estornar

	// alimenta o vetor
	_aTmpRecno := U_SqlToVet(_cQryZ07)

	memowrit("C:\query\twmsa020_sfEstornoPlt.txt",_cQryZ07)

	// varre todos os recno
	For _nX := 1 to Len(_aTmpRecno)
		// posiciona no registro real
		dbSelectArea("Z07")
		Z07->(dbGoTo( _aTmpRecno[_nX][1] ))

		// estorna registro de saída na tabela Z56 (processo barcode Sumitomo - Integração GWS x Totvs)
		If (_cCodCliFor == "000316") .AND. (lSumiBar)
			_cUpd := " UPDATE " + RetSQLName("Z56")
			_cUpd += " SET Z56_OK_SAI = 'N'"
			_cUpd += " WHERE D_E_L_E_T_ = '' AND Z56_FILIAL = '" + xFilial("Z56") + "'"
			_cUpd += " AND Z56_CODCLI = '" + _cCodCliFor     + "' "
			_cUpd += " AND Z56_LOJCLI = '" + _cLojCliFor     + "' "
			_cUpd += " AND Z56_CODETI = '" + Z07->Z07_ETQPRD + "' "

			MemoWrit("c:\query\TWMSA020_update_Z56_sfEstornoPlt_1.txt", _cUpd)

			If (TCSQLExec(_cUpd) < 0)
				DisarmTransaction()
				U_FtWmsMsg("Erro ao estornar etiquetas do cliente!" ,"Erro TWMSA020 - Update Z56 - 01")
				Exit // sai do loop
			EndIf

			// apaga vínculo com etiqueta tecadi se for etiqueta de barcode legado (z56_ok_ent = 'N')
			_cUpd := " UPDATE " + RetSQLName("Z56")
			_cUpd += " SET Z56_CODETI = ''"
			_cUpd += " WHERE D_E_L_E_T_ = '' AND Z56_FILIAL = '" + xFilial("Z56") + "'"
			_cUpd += " AND Z56_CODCLI = '" + _cCodCliFor     + "' "
			_cUpd += " AND Z56_LOJCLI = '" + _cLojCliFor     + "' "
			_cUpd += " AND Z56_CODETI = '" + Z07->Z07_ETQPRD + "' "
			_cUpd += " AND Z56_OK_ENT != 'S' "  // apenas etiqueta que não teve entrada pelo processo de barcode (Sumitomo)

			Memowrit("c:\query\TWMSA020_update_Z56_sfEstornoPlt_2.txt", _cUpd)

			If (TCSQLExec(_cUpd) < 0)
				DisarmTransaction()
				U_FtWmsMsg("Erro ao estornar etiquetas do cliente!" ,"Erro TWMSA020 - Update Z56 - 02")
				Exit // sai do loop
			EndIf
		EndIf

		//apaga registro de conferência
		RecLock("Z07")
		Z07->(dbDelete())
		Z07->(MsUnLock())

		// atualiza variavel de retorno
		_lRet := .t.
	Next _nX

	If (_lRet)
		U_FtWmsMsg("Estorno realizado com sucesso!","ATENCAO")
		sfSelDados( .T. )
	Else
		U_FtWmsMsg("Não foi possivel estornar o pallet: " + mvEtqProd ,"ATENCAO")
	EndIf

Return(_lRet)


// ** funcao que pesquisa o palete pela etiqueta do produto
Static Function sfRetNrPalete(mvIdEtqPrd)
	local _cRetIdPal := Space(Len(mvIdEtqPrd))
	local _cQryPlt

	_cQryPlt := " SELECT DISTINCT Z16_ETQPAL "
	// composicao de palete
	_cQryPlt += " FROM " + RetSqlTab("Z16") + " (nolock) "
	// filtro padrao
	_cQryPlt += " WHERE " + RetSqlCond("Z16")
	// etiqueta do produto
	_cQryPlt += " AND Z16_ETQPRD = '" + mvIdEtqPrd + "' "
	// saldo
	_cQryPlt += " AND Z16_SALDO != 0 "
	// executa a query
	_cRetIdPal := U_FtQuery(_cQryPlt)

	memowrit("c:\query\twmsa020_sfRetNrPalete.txt", _cQryPlt)

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
	// itens da ordem de servico
	_cQryZ07 += " INNER JOIN " + RetSqlTab("Z06") + " (nolock)  ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z07_NUMOS AND Z06_SEQOS = Z07_SEQOS "
	_cQryZ07 += " AND Z06_SERVIC IN " + _cSqlCodSrv + " AND Z06_TAREFA = '" + _cCodTaref + "' "
	// filtro padrao
	_cQryZ07 += " WHERE " + RetSqlCond("Z07")
	// filtro por OS
	_cQryZ07 += " AND Z07_NUMOS IN " + _cNumOrdSrv
	_cQryZ07 += " AND Z07_CLIENT = '" + _cCodCliFor + "'  AND Z07_LOJA  = '" + _cLojCliFor + "' "
	// status / C=EM CONFERENCIA
	_cQryZ07 += " AND Z07_STATUS = 'C' "

	// executa a query
	_cRetIdPlt := U_FtQuery(_cQryZ07)

	// atualiza variavel ID do palete
	If ( ! Empty(_cRetIdPlt) )
		_cIdPalete := _cRetIdPlt
	EndIf

Return

// ** função que valida a etiqueta agrupadora
Static Function sfVldAgrupa(mvOk)
	// variavel de retorno
	local _lRet := .t.
	// query
	local _cQuery

	// dados do volume
	local _aDadosVol := {}
	local _nDadosVol

	// numero da OS
	local _cNrOSVol   := CriaVar("Z06_NUMOS", .F.)
	local _cSeqSrvVol := CriaVar("Z06_SEQOS", .F.)
	local _cNrOSCar   := CriaVar("Z06_NUMOS", .F.)
	local _cSeqSrvCar := CriaVar("Z06_SEQOS", .F.)
	// carga
	local _cNrCarga := ""
	// pedido
	local _cNrPedido := ""

	// variaveis para seek
	local _cSeekZ05 := "", _cSeekZ06 := "", _cSeekZ43 := ""

	// retorna o proximo servico
	local _aPrxServico := {}

	// doca de serviço
	local _cDocaSrv := ""

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11") + _cIdAgrupa ))
			U_FtWmsMsg("Identificador da agrupadora não encontrado no sistema!","ATENCAO")
			_lRet := .F.
		ElseIf (Z11->Z11_TIPO != '04')
			U_FtWmsMsg("Identificador da agrupadora inválido!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// se a etiqueta já foi usada/lida alguma vez no mesmo carregamento
	If (_lRet)

		// query de validação do uso do volume
		_cQuery := " SELECT COUNT(Z07_PEDIDO) QTD_PEDIDO "
		// itens conferidos
		_cQuery += " FROM " + RetSqlTab("Z07") + " (nolock) "

		// itens da ordem de servico
		_cQuery += " INNER JOIN " + RetSqlTab("Z06") + " (nolock)  ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z07_NUMOS AND Z06_SEQOS = Z07_SEQOS "
		_cQuery += " AND Z06_SERVIC IN " + _cSqlCodSrv + " AND Z06_TAREFA = '" + _cCodTaref + "' "

		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z07")
		// nr e seq da OS
		_cQuery += " AND Z07_NUMOS IN " + _cNumOrdSrv
		// cliente
		_cQuery += " AND Z07_CLIENT = '" + _cCodCliFor + "' AND Z07_LOJA  = '" + _cLojCliFor + "' "
		// codigo da etiqueta agrupadora
		If (_lEtqIdInt) // ident interna
			_cQuery += " AND Z07_ETQPRD = '" + _cEtiqProd + "' "
		ElseIf (_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIdDUN)
			_cQuery += " AND Z07_ETQVOL = '" + _cIdAgrupa + "' "
		ElseIf (_lEtqClient)
			_cQuery += " AND Z07_ETQCLI = '" + _cEtqCodBar + "' "
		EndIf

		memowrit("c:\query\twmsa020_sfVldAgrupa_1.txt", _cQuery)

		// se encontrou algum registro, vai informar ao usuário
		If (U_FtQuery(_cQuery) != 0)
			// mensagem
			U_FtWmsMsg("Essa etiqueta de volume, produto ou cliente já foi utilizada!","ATENÇÃO")
			// variavel de retorno
			_lRet := .F.
		EndIf

	EndIf

	// busca todos os produtos contidos no volume, na tarefa de montagem de volumes
	If (_lRet)

		// query de validação do uso do volume
		_cQuery := " SELECT Z16_ETQPAL, Z16_CODPRO, Z16_NUMSEQ, Z16_ETQPRD, Z16_ETQVOL, SUM(Z07_QUANT) Z07_QUANT, Z16_ENDATU, Z16_LOCAL, Z16_EMBALA, Z07_NUMOS, Z07_SEQOS, Z07_PEDIDO, Z16_CARGA, "
		_cQuery += " SUM(Z07_QTSEGU) Z07_QTSEGU, Z07_LOTCTL, Z16_ETQCLI, Z43_NUMOS, Z16_TPESTO, Z16_VLDLOT, Z16_NUMSER, Z16_DTSERI "

		// composicao do palete
		_cQuery += " FROM " + RetSqlTab("Z16") + " (nolock) "

		// pedidos planejados para carregamento
		_cQuery += "        INNER JOIN " + RetSqlTab("Z43") + " (nolock) "
		_cQuery += "                ON " + RetSqlCond("Z43")
		_cQuery += "                   AND Z43_PEDIDO = Z16_PEDIDO "
		_cQuery += "                   AND Z43_STATUS = 'P' "
		_cQuery += "                   AND Z43_CESV = '" + _cNumCESV + "' "

		// conferencia na montagem de volumes
		_cQuery += "        INNER JOIN " + RetSqlTab("Z07") + " (nolock) "
		_cQuery += "                ON " + RetSqlCond("Z07")
		_cQuery += "                   AND Z07_ETQVOL = Z16_ETQVOL "
		_cQuery += "                   AND Z07_LOTCTL = Z16_LOTCTL "
		_cQuery += "                   AND Z07_ETQPRD = Z16_ETQPRD "
		_cQuery += "                   AND Z07_PRODUT = Z16_CODPRO "
		_cQuery += "                   AND Z07_VOLORI = Z16_VOLORI "
		_cQuery += "                   AND Z07_ETQCLI = Z16_ETQCLI "
		_cQuery += "                   AND Z07_CLIORI = Z16_CLIORI "
		_cQuery += "                   AND Z07_STATUS = 'F' "
		_cQuery += "                   AND Z07_PEDIDO = Z16_PEDIDO "
		_cQuery += "                   AND Z07_PLTCLI = Z16_PLTCLI "
		_cQuery += "                   AND Z07_CODBAR = Z16_CODBAR "

		// itens da ordem de servico
		_cQuery += "        INNER JOIN " + RetSqlTab("Z06") + " (nolock) "
		_cQuery += "                ON " + RetSqlCond("Z06")
		_cQuery += "                   AND Z06_NUMOS = Z07_NUMOS "
		_cQuery += "                   AND Z06_SEQOS = Z07_SEQOS "
		_cQuery += "                   AND Z06_SERVIC IN " + _cSqlCodSrv

		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z16")

		// etiqueta de volume
		If (_lEtqIdInt) // ident interna
			_cQuery += " AND Z16_ETQPRD = '" + _cEtiqProd + "' "
		ElseIf (_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIdDUN)
			_cQuery += " AND Z16_ETQVOL = '" + _cIdAgrupa + "' "
		ElseIf (_lEtqClient)
			_cQuery += " AND Z16_ETQCLI = '" + _cEtqCodBar + "' "
		EndIf

		// somente com saldo
		_cQuery += " AND Z16_SALDO > 0 "
		// pedido
		_cQuery += " AND Z16_PEDIDO IN " + _cAllPedidos
		// agrupa dados
		_cQuery += " GROUP BY Z16_ETQPAL, Z16_CODPRO, Z16_NUMSEQ, Z16_ETQPRD, Z16_ETQVOL, Z16_ENDATU, Z16_LOCAL, Z16_EMBALA, Z07_NUMOS, Z07_SEQOS, Z07_PEDIDO, Z16_CARGA, Z07_LOTCTL, Z16_ETQCLI, Z43_NUMOS, Z16_TPESTO, Z16_VLDLOT, Z16_NUMSER, Z16_DTSERI "
		// ordem dos dados
		_cQuery += " ORDER BY Z16_ETQPAL, Z16_ETQVOL, Z16_ETQCLI "

		memowrit("c:\query\twmsa020_sfVldAgrupa_2.txt", _cQuery)

		// atualizo variavel com os dados do volume
		_aDadosVol := U_SqlToVet(_cQuery, {"Z16_VLDLOT", "Z16_DTSERI"})

		// se encontrou algum registro, vai informar ao usuário
		If (Len(_aDadosVol) == 0)
			U_FtWmsMsg("Etiqueta não encontrada!","TWMSA020 - sfVldAgrupa")
			// variavel de retorno
			_lRet := .F.
		EndIf

	EndIf

	// se encontrou dados, valida dados da OS correspondente
	If (_lRet) .And. (Len(_aDadosVol) > 0)

		// varre todos os itens do volume para gravar o carregamento
		For _nDadosVol := 1 to Len(_aDadosVol)

			// dados da ordem de servico
			_cNrOSVol   := _aDadosVol[_nDadosVol][10]
			_cSeqSrvVol := _aDadosVol[_nDadosVol][11]
			_cNrOSCar   := _aDadosVol[_nDadosVol][17]
			_cSeqSrvCar := Space(Len(_cSeqSrvCar))
			// dados do pedido
			_cNrPedido  := _aDadosVol[_nDadosVol][12]
			// dados da carga
			_cNrCarga   := _aDadosVol[_nDadosVol][13]

			// na versao 1, pesquisa o CESV da OS selecionada
			If (_lRet) .And. (_nVersCarreg == 1)
				// planejamento de carregamento por CESV
				dbSelectArea("Z43")
				Z43->(DbSetOrder(3)) // 3-Z43_FILIAL+Z43_NUMOS+Z43_CARGA+Z43_PEDIDO
				If ! Z43->(DbSeek( _cSeekZ43 := xFilial("Z43") + _cNrOSVol + _cNrCarga + _cNrPedido ))
					// mensagem
					U_FtWmsMsg("A OS " + _cNrOSVol + ", Carga " + _cNrCarga + " ou Pedido " + _cNrPedido + " ainda não foram liberados para carregamento.")
					// retorno
					_lRet := .F.
					// sai do loop
					Exit
				EndIf
			EndIf

			// posiciono na Z05
			dbSelectArea("Z05")
			Z05->(DbSetOrder(1)) // 1-FILIAL+NUMOS
			If ! Z05->(DbSeek( _cSeekZ05 := xFilial("Z05") + _cNrOSVol ))
				// mensagem
				U_FtWmsMsg("OS " + _cNrOSVol + " não encontrada!")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit
			EndIf

			// posiciono na Z06
			dbSelectArea("Z06")
			Z06->(DbSetOrder(1)) // 1-FILIAL+NUMOS+SEQOS
			If ! Z06->(DbSeek( _cSeekZ06 := xFilial("Z06") + _cNrOSVol + _cSeqSrvVol ))
				// mensagem
				U_FtWmsMsg("Sequencia " +_cSeqSrvVol + " da OS " + _cNrOSVol + " não encontrada!")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit
			EndIf

			// armazena doca de servico da montagem de volumes
			If (_lRet)
				_cDocaSrv := Z06->Z06_ENDSRV
			EndIf

			// valida se a montagem de volumes ja foi encerrada
			If (_lRet) .And. (Z06->Z06_STATUS != "FI")
				// mensagem
				U_FtWmsMsg("A OS " + Z06->Z06_NUMOS + " ainda não foi liberada para carregamento.")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit
			EndIf

			// pesqquisa sequencia de carregamento
			If (_lRet)

				// na versao 1, usa a ordem de servico do mapa de expedicao e montagem de volumes
				If (_nVersCarreg == 1)

					// retorna o proximo servico, tarefa e atividades planejada da OS
					// 1-Num OS
					// 2-Seq OS
					// 3-Cod Servico
					// 4-Dsc Servico
					// 5-Cod Tarefa
					// 6-Dsc Tarefa
					// 7-Funcao/Rotina
					_aPrxServico := U_FtPrxSrv(_cNrOSVol, _cSeqSrvVol, _cCodCliFor, _cLojCliFor)

					// atualiza sequencia do proximo servico
					_cSeqSrvCar := _aPrxServico[1][2]

					// atualiza numero da os de carregamento
					_cNrOSCar := _cNrOSVol

					// na versao 2, usa a ordem de carregamento
				ElseIf (_nVersCarreg == 2)
					// retorna o proximo servico, tarefa e atividades planejada da OS
					// 1-Num OS
					// 2-Seq OS
					// 3-Cod Servico
					// 4-Dsc Servico
					// 5-Cod Tarefa
					// 6-Dsc Tarefa
					// 7-Funcao/Rotina
					_aPrxServico := U_FtPrxSrv(_cNrOSCar, "", _cCodCliFor, _cLojCliFor)

					// atualiza sequencia do proximo servico
					_cSeqSrvCar := _aPrxServico[1][2]
				EndIf
			EndIf

			// posiciono na Z06
			dbSelectArea("Z06")
			Z06->(DbSetOrder(1)) // 1-FILIAL+NUMOS+SEQOS
			If ! Z06->(DbSeek( _cSeekZ06 := xFilial("Z06") + _cNrOSCar + _cSeqSrvCar ))
				// mensagem
				U_FtWmsMsg("Sequencia " + _cSeqSrvCar + " da OS " + _cNrOSCar + " não encontrada!")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit
			EndIf

			// starto a OS selecionada
			If (Z06->Z06_STATUS $ "AG/IN")
				// atualiza o status do servico para EX-EM EXECUCAO
				U_FtWmsSta(;
				Z06->Z06_STATUS,;
				"EX"           ,;
				Z06->Z06_NUMOS ,;
				Z06->Z06_SEQOS  )

			ElseIf (Z06->Z06_STATUS == "PL")
				dbSelectArea("Z06")
				Reclock("Z06")
				Z06->Z06_STATUS := "EX"
				Z06->Z06_DTEMIS := Date()
				Z06->Z06_HREMIS := Time()
				Z06->Z06_DTINIC := Date()
				Z06->Z06_HRINIC := Time()
				Z06->Z06_ENDSRV := _cDocaSrv
				Z06->(MsUnlock())

			ElseIf (Z06->Z06_STATUS == "FI")
				// caso a OS ja tenha sido finalizada
				U_FtWmsMsg("A OS "+Z06->Z06_NUMOS+" já foi finalizada! Aguarde saída do veículo!")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit

			EndIf

			// insere quantidade lida na relacao de itens
			If (_lRet)
				dbSelectArea("Z07")
				RecLock("Z07",.t.)
				Z07->Z07_FILIAL	:= xFilial("Z07")
				Z07->Z07_NUMOS	:= Z06->Z06_NUMOS
				Z07->Z07_SEQOS	:= Z06->Z06_SEQOS
				Z07->Z07_CLIENT	:= _cCodCliFor
				Z07->Z07_LOJA	:= _cLojCliFor
				Z07->Z07_PRODUT	:= _aDadosVol[_nDadosVol][ 2]
				Z07->Z07_NUMSEQ	:= _aDadosVol[_nDadosVol][ 3]
				Z07->Z07_LOCAL	:= _aDadosVol[_nDadosVol][ 8]
				Z07->Z07_QUANT	:= _aDadosVol[_nDadosVol][ 6]
				Z07->Z07_QTSEGU := _aDadosVol[_nDadosVol][14]
				Z07->Z07_USUARI := _cCodOper
				Z07->Z07_DATA	:= Date()
				Z07->Z07_HORA	:= Time()
				Z07->Z07_STATUS	:= "C" // C-EM CONFERENCIA / D-CONFERIDO/DISPONIVEL / M-EM MOVIMENTO / A-ARMAZENADO / F-FINALIZADO/CARREGADO / L-LIBERADO
				Z07->Z07_ENDATU	:= _cDocaSrv
				Z07->Z07_ETQVOL := _aDadosVol[_nDadosVol][ 5]
				Z07->Z07_PEDIDO := _cNrPedido
				Z07->Z07_EMBALA := _aDadosVol[_nDadosVol][ 9]
				Z07->Z07_PALLET := _aDadosVol[_nDadosVol][ 1]
				Z07->Z07_PLTORI := _aDadosVol[_nDadosVol][ 1]
				Z07->Z07_LOTCTL := _aDadosVol[_nDadosVol][15]
				Z07->Z07_ETQCLI := _aDadosVol[_nDadosVol][16]
				Z07->Z07_TPESTO := _aDadosVol[_nDadosVol][18]
				Z07->Z07_VLDLOT := _aDadosVol[_nDadosVol][19]
				Z07->Z07_NUMSER := _aDadosVol[_nDadosVol][20]
				Z07->Z07_DTSERI := _aDadosVol[_nDadosVol][21]
				Z07->(MsUnLock())
			EndIf

			_nSomaVol := _nSomaVol + _aDadosVol[_nDadosVol][ 6]

			// proximo item
		Next _nDadosVol

	EndIf

	If (_lRet)

		// atualiza os dados do browse
		sfSelDados( .T. )

		// reinicia variaveis
		_cIdAgrupa  := Space(Len(_cIdAgrupa))
		_cEtqCodBar := Space(Len(_cEtqCodBar))

		// foca no campo GET correto para continuar
		_oGetEtqAgrupa:SetFocus()
	EndIf

	// pra retornar o parâmetro da rotina
	mvOk := _lRet

	// retorno a variavel
Return (_lRet)

// ** funcao para gerar um novo volume no mesmo palete
Static Function sfNovoVolume()

	// query na Z07
	local _cUpdZ07 := ""

	// solicita confirmacao
	If ( ! U_FtYesNoMsg("Confirma novo volume/pallet?"))
		Return(.F.)
	EndIf

	// zera contador de volumes
	_nSomaVol := 0

	// finaliza os itens conferidos
	_cUpdZ07 := " UPDATE " + RetSqlName("Z07")
	// status finalizado // L-LIBERADO
	_cUpdZ07 += " SET Z07_STATUS = 'L' "
	// filtro padrao
	_cUpdZ07 += " WHERE Z07_FILIAL = '" + xFilial("Z07") + "' AND D_E_L_E_T_ = ' ' "
	// filtro da OS especifica
	_cUpdZ07 += " AND Z07_NUMOS  IN " + _cNumOrdSrv
	// pedido
	_cUpdZ07 += " AND Z07_PEDIDO IN " + _cAllPedidos
	// status C=EM CONFERENCIA
	_cUpdZ07 += " AND Z07_STATUS  = 'C' "

	memowrit("c:\query\twmsa020_sfNovoVolume_upd.txt", _cUpdZ07)

	// executa o update
	TcSQLExec(_cUpdZ07)

	// atualiza variaveis
	_cEtiqProd  := Space(Len(_cEtiqProd))
	_cIdAgrupa  := Space(Len(_cIdAgrupa))
	_cEtqCodBar := Space(Len(_cEtqCodBar))

	// atualiza os dados
	sfSelDados()

	// foca no campo correto para continuar
	_oGetEtqAgrupa:SetFocus()

Return( .T. ) 

// ** funcao que calcula a cubagem por embalagem
Static Function sfRetCubEmb()
	// variavel de retorno
	local _nRet := 0
	// query
	local _cQuery
	// dados temporarios
	local _aDadosCub := {}

	// monta a query para buscar os volumes por pedido
	_cQuery := " SELECT Z07_ETQVOL, Z31_CUBAGE "

	// itens conferidos/volumes montados
	_cQuery += " FROM " + RetSqlTab("Z07") + " (nolock) "

	// itens da ordem de servico
	_cQuery += " INNER JOIN " + RetSqlTab("Z06") + " (nolock)  ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z07_NUMOS "
	_cQuery += " AND Z06_SERVIC IN " + _cSqlCodSrv + " AND Z06_TAREFA = '" + _cCodTaref + "' "

	// cad. clientes
	_cQuery += " INNER JOIN " + RetSqlTab("SA1") + " (nolock)  ON " + RetSqlCond("SA1") + " AND A1_COD = Z07_CLIENT AND A1_LOJA = Z07_LOJA "

	// cad. embalagens
	_cQuery += " INNER JOIN " + RetSqlTab("Z31") + " (nolock)  ON " + RetSqlCond("Z31") + " AND Z31_CODIGO = Z07_EMBALA AND Z31_SIGLA = A1_SIGLA "

	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z07")
	// numero e seq da OS
	_cQuery += " AND Z07_NUMOS  IN " + _cNumOrdSrv
	// cliente e loja
	_cQuery += " AND Z07_CLIENT  = '" + _cCodCliFor + "' AND Z07_LOJA  = '" + _cLojCliFor + "' "
	// nr do pedido
	_cQuery += " AND Z07_PEDIDO IN " + _cAllPedidos

	// agrupa dados
	_cQuery += " GROUP BY Z07_ETQVOL, Z31_CUBAGE "

	memowrit("c:\query\twmsa020_sfRetCubEmb.txt", _cQuery)

	// atualiza vetor
	_aDadosCub := U_SqlToVet(_cQuery)

	// calcula a quantidade total de palete
	aEval(_aDadosCub,{|x| _nRet += x[2] })

Return(_nRet)

// ** função que finaliza o carregamento
Static Function sfFinalCar (mvCesv)
	// variavel de retorno
	local _lRet := .T.
	// query que retorna os pedidos por CESV
	local _aPedidos := sfQryPedidos(mvCesv)
	// array com todas as OS processadas
	local _aNumOS := {}
	// controle de loop
	local _nX := 0
	// query
	local _cQryZ06 := ""


	// objetos da caixa de seleção de impressora
	local _oWndSelImp, _oCBxTpEtiq, _oBtnEtqOk, _oBtnEtqCan
	local _cImpSelec, _lImpRom := .F.
	local _aImpWindows := {}

	// pergunta inicial
	_lRet := U_FtYesNoMsg("Deseja Finalizar Carregamento?")

	If (_lRet)

		// vou fazer a validação baseada na query de pedidos
		For _nX := 1 to Len(_aPedidos)
			// 1ª validação - Verifica se todos os pedidos foram processados
			If ( Empty(_aPedidos[_nX][1]) )
				// mensagem
				U_FtWmsMsg("Há pedidos não finalizados. Verifique!")
				// retorno
				Return(.F.)
			EndIf

			// guarda todas as OS do CESV
			if ( aScan(_aNumOS, _aPedidos[_nX][6]) == 0 )
				aAdd(_aNumos, _aPedidos[_nX][6] )
			EndIf

		Next _nX

		// starto a transação
		BeginTran()

		// verifique se posso finalizar a OS ou se preciso interromper
		For _nX := 1 to Len(_aNumOS)

			// pega a última atividade da OS
			_cQryZ06 := "SELECT MAX(Z06_SEQOS) Z06_SEQOS FROM " + RetSqlTab("Z06") + " WHERE " + RetSqlCond("Z06")+ " AND Z06_NUMOS = '" + _aNumOS[_nX] + "'"

			// posiciona na OS
			DbSelectArea("Z06")
			DbSetOrder(1)  // Z06_FILIAL, Z06_NUMOS, Z06_SEQOS, R_E_C_N_O_, D_E_L_E_T_
			Z06->(dbSeek(xFilial("Z06") + _aNumOS[_nX] + U_FtQuery(_cQryZ06)))

			U_FtWmsSta(Z06->Z06_STATUS, "FI" ,	Z06->Z06_NUMOS , Z06->Z06_SEQOS )

		Next _nX

		// finalizo a operação
		dbSelectArea("SZZ")
		SZZ->(dbSetOrder(1)) // 1-ZZ_FILIAL, ZZ_CESV
		If ( ! SZZ->(dbSeek( xFilial("SZZ") + mvCesv )) )
			// mensagem
			U_FtWmsMsg("Erro na pesquisa pelo CESV ao finalizar carregamento.","ATENCAO")
			// variavel de retorno
			_lRet := .F.
			DisarmTransaction()
			Break
		Else
			Reclock("SZZ")
			SZZ->ZZ_STATUS := "09" // saída liberada
			SZZ->ZZ_OPWMS  := "S"  // operado pelo WMS
			SZZ->(MsUnlock())
		EndIf

		// finaliza a transação
		EndTran()

		// libera todos os registros
		MsUnLockAll()

		If (_lRet)
			// envia e-mail de aviso de mercadoria carregada
			IF ( U_FtWmsParam("WMS_EXPEDICAO_EMAIL_AVISO_FIM_CARREGAMENTO", "L", .F., .F., "", SZZ->ZZ_CLIENTE, SZZ->ZZ_LOJA, Nil, Nil) )
				U_FTMail02(mvCesv)
			EndIf
			
			// Pergunta e grava o número do lacre
			IF ( U_FtWmsParam("WMS_CARREGAMENTO_LACRE_COLETOR", "L", .F., .F., "", SZZ->ZZ_CLIENTE, SZZ->ZZ_LOJA, Nil, Nil) )
				sfLacre()
			EndIf

			// se processo de EDI Sumitomo ativo, gera arquivo de integraçao
			If ( (SZZ->(ZZ_CLIENTE+ZZ_LOJA) == GetNewPar("TC_SRBTI","00031601") .Or. SZZ->(ZZ_CLIENTE+ZZ_LOJA) == GetNewPar("TC_SRBTP","00031602")) .AND. (lSumiBar) )
				If ExistBlock("TWMSA048")
					ExecBlock("TWMSA048",.F.,.F.,{"S", Z06->Z06_NUMOS, Z06->Z06_SEQOS, SZZ->ZZ_CLIENTE, SZZ->ZZ_LOJA} )
				EndIf	
			EndIf

			// Gera arquivo de EDI padrão TECADI TECADI-EDI-03 no FTP
			IF ( U_FtWmsParam("WMS_EXPEDICAO_EDI_FTP_FIM_CARREGAMENTO", "L", .F., .F., "", SZZ->ZZ_CLIENTE, SZZ->ZZ_LOJA, Nil, Nil) )
				// se cliente Danuri
				// TODO fazer esta parte via parâmetro
				If (SZZ->ZZ_CLIENTE == "000547")
					// Cria arquivo EDI e envia por FTP
					U_FTPSend2( U_TEDI003(mvCesv),;
					"103_EDI003_" + mvCesv + ".txt",;
					"C:\TEMP\",;
					"10.3.0.211",;
					21,;
					"luminatti",;
					"7Usp8tUwat&a",;
					"/EDI/expedicao/",;
					.T.)
				EndIf
			EndIf


			// pergunta se deseja imprimir o romaneio de carga pelo coletor
			If (U_FtYesNoMsg("Deseja imprimir o romaneio de carga do CESV  " + _cNumCESV + "?", "Impressão de romaneio!"))  
				// pega as impressoras previamente cadastradas (tipo 2 = impressora laser)
				_aImpWindows := U_FtRetImp(2)

				// tela para selecionar as impressoras de etiquetas disponiveis
				_oWndSelImp := MSDialog():New(000,000,080,210,"Impressoras laser",,,.F.,,,,,,.T.,,,.T. )
				_oCBxTpEtiq := TComboBox():New( 004,004,{|u| If(PCount()>0,_cImpSelec:=u,_cImpSelec)},_aImpWindows,100,010,_oWndSelImp,,,,,,.T.,,"",,,,,,,_cImpSelec )
				_oBtnEtqOk  := SButton():New( 021,021,1,{ || _lImpRom := .T. , _oWndSelImp:End() },_oWndSelImp,,"", )
				_oBtnEtqCan := SButton():New( 021,055,2,{ || _oWndSelImp:End() },_oWndSelImp,,"", )
				_oWndSelImp:Activate(,,,.T.)

				if (_lImpRom)
					_cImpSelec := Separa(_cImpSelec,"|")[2]

					// dispara impressão do relatório
					U_TWMSR019(_cNumCESV, _cImpSelec)
				EndIf
			EndIf

			// informa a finalização do carregamento
			U_FtWmsMsg("Carregamento finalizado!")
		EndIf
	EndIf

Return (_lRet)

// Função responsável por requisitar e gravar o número de Lacre
Static Function sfLacre()
	Local _lRet		:= .T.
	Local _lFixaWnd	:= .F.
	Local _cLacre	:= CriaVar("ZZ_LACRE",.F.)
	Local _oPnInMvCb
	Local _oPnInMvCen
	Local _oBmpOK

	Private _oGetLacre
	Private _oWndLacre

	// monta o dialogo do monitor
	_oWndLacre := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Número de Lacre",,,.F.,,,,,,.T.,,,.T. )
	_oWndLacre:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnInMvCb := TPanel():New(000,000,nil,_oWndLacre,,.F.,.F.,,CLR_HGRAY,20,20,.T.,.F.)
	_oPnInMvCb:Align:= CONTROL_ALIGN_TOP

	// Confirmar o número de lacre
	_oBmpOK := TBtnBmp2():New(000,000,060,022,"OK",,,,;
	{|| IIF(!EMPTY(_cLacre),IIf(U_FtYesNoMsg("Confirma o número de Lacre digitado?", "ATENÇÃO"),;
	(sfGrvLacre(_cLacre),(_lFixaWnd := .T. ,_oWndLacre:End())),Nil),;
	U_FtWmsMsg("Necessário informar número de Lacre!","ATENCAO")) },_oPnInMvCb,"Confirmar",,.T.)
	_oBmpOK:Align := CONTROL_ALIGN_LEFT

	// cria o panel para os campos
	_oPnInMvCen := TPanel():New(000,000,nil,_oWndLacre,,.F.,.F.,,,110,110,.T.,.F.)
	_oPnInMvCen:Align:= CONTROL_ALIGN_TOP

	// Numero o Lacre
	_oGetLacre := TGet():New(001,001,{|u| If(PCount()>0,_cLacre:=u,_cLacre)},_oPnInMvCen,110,015,"@!",{|| },,,_oFnt03,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cLacre",,,,,, .T. ,"Número do Lacre", 1)
	_oGetLacre:SetFocus()

	// ativa a tela
	_oWndLacre:Activate(,,,.F.,{|| _lFixaWnd },,)

Return(_lRet)

// Realiza a gravação do número de Lacre
Static Function sfGrvLacre(mvLacre)

	RecLock("SZZ",.F.)
	SZZ->ZZ_LACRE := mvLacre
	SZZ->( MsUnLock() )

Return

// ** função que retorna o RECNO da Z06 pela carga para OS de carregamento
Static Function sfRecnoZ06 (mvNumos)
	// variaveis
	local _nRecno := 0
	local _cQuery := ""

	// query que retorna um recno baseado na carga na Z05
	_cQuery := " SELECT Z06.R_E_C_N_O_ Z06RECNO "
	_cQuery += "	FROM   " + RetSqlTab("Z06") + " (nolock) "
	_cQuery += "	WHERE  Z06_NUMOS = '" + mvNumos + "' "
	_cQuery += "	AND " + RetSqlCond("Z06") 
	_cQuery += "	AND Z06_SERVIC IN " + _cSqlCodSrv
	_cQuery += "	AND Z06_TAREFA = '" + _cCodTaref + "' "

	// grava query pra consulta
	memowrit("C:\query\twmsa20_recno.txt",_cQuery)

	// jogo o conteudo da query pra variavel
	_nRecno := U_FtQuery(_cQuery)

Return (_nRecno)

// ** função que valida se a OS pode ser finalizada ou deve ser interrompida
Static Function sfVldFinOS(mvNumOs, mvCarga)
	// variavel de retorno
	local _cStatus := ""
	// query de análise
	local _cQuery := ""
	// array que receberá os dados para análise
	local _aStatus := ""

	// query analitica dos registros
	_cQuery := " SELECT (SELECT Count(*) "
	_cQuery += "     	   FROM  " + RetSqlTab("Z43") + " (nolock) "
	_cQuery += "          WHERE  " + RetSqlCond("Z43")
	_cQuery += "            AND Z43_NUMOS = Z05_NUMOS "
	_cQuery += "            AND Z43_CARGA IN (Z05_CARGA,'" + mvCarga + "') "
	_cQuery += "            AND Z43_STATUS IN ( 'R' , 'C') ) Z43TOT, "
	_cQuery += "        (SELECT Count(*) "
	_cQuery += "           FROM  " + RetSqlTab("SC5") + " (nolock) "
	_cQuery += "          WHERE  " + RetSqlCond("SC5")
	_cQuery += "            AND C5_ZCARGA != ' ' "
	_cQuery += "            AND C5_ZCARGA IN (Z05_CARGA,'" + mvCarga + "')) SC5TOT "
	_cQuery += "  FROM   " + RetSqlTab("Z05") + " (nolock) "
	_cQuery += " WHERE  " + RetSqlCond("Z05")
	_cQuery += "   AND Z05_NUMOS = '" + mvNumOs + "' "

	memowrit("c:\query\twmsa020_sfVldFinOS.txt", _cQuery)

	// dados jogados na query pra análise
	_aStatus := U_SqlToVet(_cQuery)

	// primeira validação
	// se for igual a 0 já interrompe a OS
	// se a Z43 for menor que SC5 interrompe também

	// se não houveram já realizados (carregados) na CESV ou se a quantidade total dos pedidos já realizados (carregados) daquela CESV/CARGA for menor
	// que o total, então interrompe a OS, pois ainda há pedidos a serem carregados
	If (_aStatus[1][1] == 0) .Or. (_aStatus[1][1] < _aStatus[1][2]) 
		_cStatus := "IN"
	ElseIf (_aStatus[1][1] == _aStatus[1][2]) .OR. (_aStatus[1][1] >= _aStatus[1][2])   // se todos os pedidos do CESV/CARGA já foram realizados (carregados) então finaliza de vez a OS
		_cStatus := "FI"
	EndIf

Return (_cStatus)

// ** funcao para informar container ** //
Static Function sfInfCnt()

	// objetos
	local _oBtnFoco1
	// controle para nao fechar a tela
	Local _lRetOk := .F.
	// objetos locais
	local _oGetCnt, _oWndInfCnt, _oPnlInfCnt, _oBmpInfCnt

	// monta a tela para informa a quantidade
	_oWndInfCnt := MSDialog():New(020,020,200,220,"Def. Container",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlInfCnt := TPanel():New(000,000,nil,_oWndInfCnt,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlInfCnt:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpInfCnt := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRetOk := .T.,_oWndInfCnt:End() },_oPnlInfCnt,"Ok",,.T.)

	_oBmpInfCnt:Align := CONTROL_ALIGN_LEFT

	_oGetCnt := TGet():New(033,005,{|u| If(PCount()>0,_cContainer:=u,_cContainer)},_oWndInfCnt,060,010,"@!",{|| _lRetOk := sfVldCnt() },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cContainer",,,,,,,"Informe o container a ser carregado: ",1)

	// seta o foco na quantidade
	_oGetCnt:SetFocus()

	// ativacao da tela com validacao
	_oWndInfCnt:Activate(,,,.T.,{|| _lRetOk })

Return _lRetOk

// ** função para validar o container digitado ** //
Static Function sfVldCnt()

	// variavel de controle
	local _lRet := .t.

	If ( Empty( _cContainer ) )
		U_FtWmsMsg("O container precisa ser informado.")
		_lRet := .F.
	EndIf

Return _lRet

// ** função da tela para selecionar os clientes vinculados ao CESV x Carga
Static Function sfSelCliente(mvCesv)
	// variavel de controle
	local _lRet := .F.
	// objetos locais
	local _oWmsClientes, _oPnlCliCab, _oBmpOk, _oBmpSair, _oBrwClientes, _oBmpOpcoes
	// arrays do browse
	local _aHeadCli := {}
	local _aColsCli := {}

	// query
	local _cQuery

	// query para buscar todos os clientes disponiveis
	_cQuery := " SELECT C5_CLIENTE, "
	_cQuery += "        C5_LOJACLI, "
	_cQuery += "        A1_NOME, "
	_cQuery += "        Count(DISTINCT C5_ZPEDCLI) QTD_PEDIDOS, "
	_cQuery += "        '.F.' IT_DEL "
	_cQuery += " FROM   " + RetSqlTab("SC5") + " (nolock) "
	_cQuery += "        INNER JOIN " + RetSqlTab("SA1") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("SA1")
	_cQuery += "                   AND A1_COD = C5_CLIENTE "
	_cQuery += "                   AND A1_LOJA = C5_LOJACLI "
	_cQuery += "        INNER JOIN " + RetSqlTab("SC9") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("SC9")
	_cQuery += "                   AND C9_PEDIDO = C5_NUM "
	// valida se precisa de NF para carregamento
	If ( ! _lCESVSemNf )
		_cQuery += "                   AND C9_NFISCAL <> ' ' "
	EndIf
	_cQuery += "        INNER JOIN " + RetSqlTab("Z43") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("Z43")
	_cQuery += "                   AND Z43_CARGA = C5_ZCARGA "
	_cQuery += "                   AND Z43_PEDIDO = C5_NUM "
	If ( ! _lUsrGeren ) .AND. ( ! _lUsrAccou ) .AND. ( ! _lUsrSuper )
		_cQuery += "                   AND Z43_STATUS IN ( 'P', 'R' ) "
	Else 			//se for gerente, account ou supervisor pega também os cancelados, para poder reabrir o carregamento em caso de erros
		_cQuery += "                   AND Z43_STATUS IN ( 'P', 'R', 'C' ) "
	EndIf
	_cQuery += "                   AND Z43_CESV = '" + mvCesv + "' "
	_cQuery += " WHERE  " + RetSqlCond("SC5")
	_cQuery += "        AND C5_TIPOOPE = 'P' "
	_cQuery += " GROUP  BY C5_CLIENTE, "
	_cQuery += "           C5_LOJACLI, "
	_cQuery += "           A1_NOME "
	_cQuery += " ORDER  BY C5_CLIENTE, "
	_cQuery += "           C5_LOJACLI "

	memowrit("c:\query\twmsa020_sfSelCliente.txt", _cQuery)

	// atualiza vetor, com os dados da query
	_aColsCli := U_SqlToVet(_cQuery)

	// quando nao ha mais pedidos/clientes liberados
	If (len(_aColsCli) == 0)
		// mensagem
		U_FtWmsMsg("Todos os pedidos já foram carregados ou não há pedidos liberados para carregamento.")
		// retorno
		Return(_lRet)
	EndIf

	// monta o dialogo do monitor
	_oWmsClientes := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Selecione o Cliente",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes de operacao
	_oPnlCliCab := TPanel():New(000,000,nil,_oWmsClientes,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlCliCab:Align:= CONTROL_ALIGN_TOP

	// botao que seleciona um cliente
	_oBmpOk := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| _lRet := .t., _oWmsClientes:End() },_oPnlCliCab,"OK",,.T.)
	_oBmpOk:Align := CONTROL_ALIGN_LEFT

	// botao que seleciona um pedido
	_oBmpSair := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| _oWmsClientes:End() },_oPnlCliCab,"Sair",,.T.)
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// define array do browse
	aAdd(_aHeadCli,{"Código"     , "C5_CLIENTE" , ""      , TamSx3("C5_CLIENTE")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadCli,{"Loja"       , "C5_LOJACLI" , ""      , TamSx3("C5_LOJACLI")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadCli,{"Nome"       , "A1_NOME"    , ""      , TamSx3("A1_NOME")[1]   ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadCli,{"Qtd.Pedidos", "QTD_PEDIDOS", "@E 999", 3                      ,0,Nil,Nil,"N",Nil,"R",,,".F." })

	// browse
	_oBrwClientes := MsNewGetDados():New(078,000,148,118,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsCli),'AllwaysTrue()','','AllwaysTrue()',_oWmsClientes,_aHeadCli,_aColsCli)
	_oBrwClientes:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwClientes:oBrowse:bLdblClick := {|| _oBmpOk:Click() }

	// ativacao da tela
	ACTIVATE MSDIALOG _oWmsClientes

	// se foi confirmado, atualiza variaveis
	If (_lRet)
		_cCodCliFor := _oBrwClientes:aCols[_oBrwClientes:nAt][1]
		_cLojCliFor := _oBrwClientes:aCols[_oBrwClientes:nAt][2]
	EndIf

Return(_lRet)

// ** função que valida a etiqueta de cliente
Static Function sfVldEtqCli(mvOk)
	// variavel de retorno
	local _lRet := .t.
	// query
	local _cQuery

	// dados do volume
	local _aDadosVol := {}
	local _nDadosVol

	// variaveis para seek
	local _cSeekZ05 := "", _cSeekZ06 := "", _cSeekZ43 := ""

	// doca de serviço
	local _cDocaSrv := ""

	// verifica se etiqueta foi informada
	If (_lRet) .And. (Empty(_cEtqCodBar))
		// mensagem
		U_FtWmsMsg("Necessário informar etiqueta de identificação da mercadoria!","ATENCAO")
		// variavel de retorno
		_lRet := .F.
	EndIf

	// se o volume já foi usado uma vez no mesmo carregamento
	If (_lRet)

		// query de validação do uso do volume
		_cQuery := " SELECT COUNT(Z07_PEDIDO) QTD_PEDIDO "
		// itens conferidos
		_cQuery += " FROM " + RetSqlTab("Z07")

		// itens da ordem de servico
		_cQuery += " INNER JOIN " + RetSqlTab("Z06") + " (nolock)  ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z07_NUMOS AND Z06_SEQOS = Z07_SEQOS "
		_cQuery += " AND Z06_SERVIC IN " + _cSqlCodSrv + " AND Z06_TAREFA = '" + _cCodTaref + "' "

		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z07")
		// nr e seq da OS
		_cQuery += " AND Z07_NUMOS IN " + _cNumOrdSrv
		// cliente
		_cQuery += " AND Z07_CLIENT = '" + _cCodCliFor + "' AND Z07_LOJA  = '" + _cLojCliFor + "' "
		// codigo da etiqueta agrupadora
		If (_lEtqIdInt) // ident interna
			_cQuery += " AND Z07_ETQPRD = '" + _cEtiqProd + "' "
		ElseIf (_lEtqIdEAN) .Or. (_lEtqCod128) .Or. (_lEtqIdDUN)
			_cQuery += " AND Z07_ETQVOL = '" + _cIdAgrupa + "' "
		ElseIf (_lEtqClient)
			_cQuery += " AND Z07_ETQCLI = '" + _cEtqCodBar + "' "
		EndIf

		memowrit("c:\query\twmsa020_sfVldEtqCli_1.txt", _cQuery)

		// se encontrou algum registro, vai informar ao usuário
		If (U_FtQuery(_cQuery) != 0)
			// mensagem
			U_FtWmsMsg("Essa etiqueta de volume, produto ou etiqueta de cliente já foi utilizada!","ATENCAO")
			// variavel de retorno
			_lRet := .F.
		EndIf

	EndIf

	// busca todos os produtos contidos no volume, na tarefa de montagem de volumes
	If (_lRet)

		// query de validação do uso do volume
		_cQuery := " SELECT Z16_ETQPAL, "
		_cQuery += "        Z16_CODPRO, "
		_cQuery += "        Z16_NUMSEQ, "
		_cQuery += "        Z16_ETQPRD, "
		_cQuery += "        Z16_ETQVOL, "
		_cQuery += "        Z16_SALDO, "
		_cQuery += "        Z16_ENDATU, "
		_cQuery += "        Z16_LOCAL, "
		_cQuery += "        Z16_EMBALA, "
		_cQuery += "        Z16_PEDIDO, "
		_cQuery += "        Z16_CARGA, "
		_cQuery += "        Z16_QTSEGU, "
		_cQuery += "        Z16_LOTCTL, "
		_cQuery += "        Z16_ETQCLI "
		// composicao do palete
		_cQuery += " FROM   " + RetSqlTab("Z16") + " WITH(INDEX(" + RetSqlName("Z16") + "5),nolock) "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z16")
		// etiqueta do cliente
		_cQuery += "        AND Z16_ETQCLI = '" + _cEtqCodBar + "' "
		// somente com saldo
		_cQuery += "        AND Z16_SALDO != 0 "
		// pedido
		_cQuery += "        AND Z16_PEDIDO IN " + _cAllPedidos
		// ordem dos dados
		_cQuery += " ORDER  BY Z16_ETQPAL, "
		_cQuery += "           Z16_ETQVOL, "
		_cQuery += "           Z16_ETQCLI "

		memowrit("c:\query\twmsa020_sfVldEtqCli_2.txt", _cQuery)

		// atualizo variavel com os dados do volume
		_aDadosVol := U_SqlToVet(_cQuery)

		// se encontrou algum registro, vai informar ao usuário
		If (Len(_aDadosVol) == 0)
			// mensagem para usuario
			U_FtWmsMsg("Essa etiqueta de mercadoria de cliente não encontrada!","ATENCAO")
			// variavel de retorno
			_lRet := .F.
		EndIf

	EndIf

	// se encontrou dados, valida dados da OS correspondente
	If (_lRet) .And. (Len(_aDadosVol) > 0)

		// varre todos os itens do volume para gravar o carregamento
		For _nDadosVol := 1 to Len(_aDadosVol)

			// pesquisa o CESV da OS selecionada
			dbSelectArea("Z43")
			Z43->(DbSetOrder(3)) // 3-Z43_FILIAL+Z43_NUMOS+Z43_CARGA+Z43_PEDIDO
			If ! Z43->(DbSeek( _cSeekZ43 := xFilial("Z43") + _cNrOSUnica + _cCargaUnic + _cPedUnico ))
				// mensagem
				U_FtWmsMsg("A OS " + _cNrOSUnica + ", Carga " + _cCargaUnic + " ou Pedido " + _cPedUnico + " ainda não foram liberados para carregamento.")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit
			EndIf

			// posiciono na Z05
			dbSelectArea("Z05")
			Z05->(DbSetOrder(1)) // 1-FILIAL+NUMOS
			If ! Z05->(DbSeek( _cSeekZ05 := xFilial("Z05") + _cNrOSUnica ))
				// mensagem
				U_FtWmsMsg("OS " + _cNrOSUnica + " não encontrada!")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit
			EndIf

			// posiciono na Z06
			dbSelectArea("Z06")
			Z06->(DbSetOrder(1)) // 1-FILIAL+NUMOS+SEQOS
			If ! Z06->(DbSeek( _cSeekZ06 := xFilial("Z06") + _cNrOSUnica ))
				// mensagem
				U_FtWmsMsg("Sequencia 001 da OS " + _cNrOSUnica + " não encontrada!")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit
			EndIf

			// armazena doca de servico do carregamento
			If (_lRet)
				_cDocaSrv := Z06->Z06_ENDSRV
			EndIf

			// verifica se nao esta finalizada
			If (Z06->Z06_STATUS == "FI")
				// caso a OS ja tenha sido finalizada
				U_FtWmsMsg("A OS " + Z06->Z06_NUMOS + " já foi finalizada! Aguarde saída do veículo!")
				// retorno
				_lRet := .F.
				// sai do loop
				Exit

			EndIf

			// starto a OS selecionada
			If (Z06->Z06_STATUS $ "AG/IN")
				// atualiza o status do servico para EX-EM EXECUCAO
				U_FtWmsSta(;
				Z06->Z06_STATUS,;
				"EX"           ,;
				Z06->Z06_NUMOS ,;
				Z06->Z06_SEQOS  )
			EndIf

			// insere quantidade lida na relacao de itens
			If (_lRet)
				dbSelectArea("Z07")
				RecLock("Z07",.t.)
				Z07->Z07_FILIAL	:= xFilial("Z07")
				Z07->Z07_NUMOS	:= Z06->Z06_NUMOS
				Z07->Z07_SEQOS	:= Z06->Z06_SEQOS
				Z07->Z07_CLIENT	:= _cCodCliFor
				Z07->Z07_LOJA	:= _cLojCliFor
				Z07->Z07_PRODUT	:= _aDadosVol[_nDadosVol][ 2]
				Z07->Z07_NUMSEQ	:= _aDadosVol[_nDadosVol][ 3]
				Z07->Z07_LOCAL	:= _aDadosVol[_nDadosVol][ 8]
				Z07->Z07_QUANT	:= _aDadosVol[_nDadosVol][ 6]
				Z07->Z07_QTSEGU := _aDadosVol[_nDadosVol][12]
				Z07->Z07_USUARI := _cCodOper
				Z07->Z07_DATA	:= Date()
				Z07->Z07_HORA	:= Time()
				Z07->Z07_STATUS	:= "C" // C-EM CONFERENCIA / D-CONFERIDO/DISPONIVEL / M-EM MOVIMENTO / A-ARMAZENADO / F-FINALIZADO/CARREGADO / L-LIBERADO
				Z07->Z07_ENDATU	:= _cDocaSrv
				Z07->Z07_ETQVOL := _aDadosVol[_nDadosVol][ 5]
				Z07->Z07_PEDIDO := _aDadosVol[_nDadosVol][10]
				Z07->Z07_EMBALA := _aDadosVol[_nDadosVol][ 9]
				Z07->Z07_PALLET := _aDadosVol[_nDadosVol][ 1]
				Z07->Z07_PLTORI := _aDadosVol[_nDadosVol][ 1]
				Z07->Z07_LOTCTL := _aDadosVol[_nDadosVol][13]
				Z07->Z07_ETQCLI := _aDadosVol[_nDadosVol][14]
				Z07->(MsUnLock())
			EndIf

			// proximo item
		Next _nDadosVol

	EndIf

	If (_lRet)

		// atualiza os dados do browse
		sfSelDados( .T. )

		// reinicia variaveis
		_cIdAgrupa  := Space(Len(_cIdAgrupa))
		_cEtqCodBar := Space(Len(_cEtqCodBar))
		// foca no objeto Etq Agrupadora
		_oGetEtqAgrupa:SetFocus()

	EndIf

	// pra retornar o parâmetro da rotina
	mvOk := _lRet

	// retorno a variavel
Return (_lRet)

// ** funcao que retorna a versao do processo de carregamento
// 1 - Planeja Carregamento com Mapa de Separacao
// 2 - Ordem de Servico de Carregamento Independente das demais
Static Function sfRetVersao( mvRetProc )
	// query
	local _cQuery := ""
	// retorno da versao
	local _nRetVersao := 0
	// dados temporarios
	local _aTmpDados := {}
	local _nX
	local _nTmpVers

	// prepara query
	_cQuery += " SELECT Z43_NUMOS, "
	_cQuery += "        (SELECT Count(Z06_NUMOS) "
	_cQuery += "         FROM   " + RetSqlTab("Z06") + " (nolock) "
	_cQuery += "         WHERE  " + RetSqlCond("Z06")
	_cQuery += "                AND Z06_NUMOS = Z43_NUMOS) QTD_OS_EXP "
	_cQuery += " FROM   " + RetSqlTab("Z43") + " (nolock) "
	_cQuery += " WHERE  " + RetSqlCond("Z43")
	_cQuery += "        AND Z43_STATUS = 'P' "
	_cQuery += "        AND Z43_CESV = '" + _cNumCESV + "' "

	// atualiza dados temporarios
	_aTmpDados := U_SqlToVet( _cQuery )

	// varre todas as ordens de servico da CESV
	For _nX := 1 to Len(_aTmpDados)

		// verifica tipo da versao da OS
		_nTmpVers := IIf( _aTmpDados[_nX][2] > 1, 1, 2)

		// atualiza versao geral
		If (_nRetVersao == 0)
			// atualiza variavel
			_nRetVersao := _nTmpVers

		ElseIf (_nRetVersao != 0) .And. (_nRetVersao != _nTmpVers)
			// atualiza variavel de retorno
			mvRetProc := .F.
			// avisa usuario
			U_FtWmsMsg("Não é permitido carregamento com dois tipos de processo de carregamento. Solicite ao atendimento alteração da CESV!","ATENCAO")
			// sai do Loop
			Exit

		EndIf

	Next _nX

Return( _nRetVersao )


//-------------------------------------------------------------------------------------------------
Static Function EtqSumi()
	// objetos da tela
	local _oBmpEstorno, _oBmpConsDetSair
	local _oPnlConfDet, _oPnlConfRod
	local _lRet := .F.

	// variaveis do browse
	local _aHeadSum		:= {}

	Local oFont18		:= TFont():New('Arial',,-18,,.F.)
	Local oFont14n		:= TFont():New('Arial',,-14,,.T.)

	Private nQtdSum		:= 0
	Private _cProdBp	:= SPACE(8)
	private _oBrwSum
	Private _oGetSum
	Private _oSayTS
	Private oDlgEtqS

	// define o header
	aAdd(_aHeadSum,{"Etq Cliente" ,"Z11_CODETI"  ,"@!"                         ,8                      , 0, Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadSum,{"Quant"       ,"Z11_QTD1"    ,_cMaskQuant                  ,1                      , 0, Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHeadSum,{"Produto"     ,"B1_COD"      ,PesqPict("SB1","B1_COD")     ,TamSx3("B1_COD")[1]    , 0, Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadSum,{"Desc Prod"   ,"B1_DESC"     ,PesqPict("SB1","B1_DESC")    ,TamSx3("B1_DESC")[1]   , 0, Nil,Nil,"C",Nil,"R",,,".F." })

	_aColsSum := {}
	_nQtdProd := 0  //zera quantidade padrão

	// monta o dialogo do monitor
	oDlgEtqS := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Receb. Sumitomo",,,.F.,,,,,,.T.,,,.T. )
	oDlgEtqS:lEscClose := .F.

	// cria o panel do cabecalho - botoes
	_oPnlConfDet := TPanel():New(000,000,nil,oDlgEtqS,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlConfDet:Align:= CONTROL_ALIGN_TOP

	// Total de produtos bipados
	_oSayTS       := TSay():New(005,005,{|| "Total conferido: " + AllTrim(Str(nQtdSum)) },_oPnlConfDet,,oFont14n,.F.,.F.,.F.,.T.)
	_oSayTS:Align := CONTROL_ALIGN_CENTER

	// -- CONFIRMACAO
	_oBtnSrvConf := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| ConfSum() },_oPnlConfDet,"Ok",,.T.)
	_oBtnSrvConf:Align := CONTROL_ALIGN_RIGHT

	// monta o browse com os produtos conferidos
	_oBrwSum := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsSum),'AllwaysTrue()','','AllwaysTrue()',oDlgEtqS,_aHeadSum,_aColsSum)
	_oBrwSum:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// cria o panel do rodape - botoes
	_oPnlConfRod := TPanel():New(000,000,nil,oDlgEtqS,,.F.,.F.,,,020,020,.T.,.F. )
	_oPnlConfRod:Align:= CONTROL_ALIGN_BOTTOM

	// Campo para bipar os produtos
	_oGetSum := TGet():New(005,005,{|u| If(PCount()>0,_cProdBp:=u,_cProdBp)},_oPnlConfRod,060,008,,{|| (Vazio()) .Or. AddBrwS( _cProdBp ),_cProdBp := Space(8) },,,oFont18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cProdBp",,)
	_oGetSum:Align := CONTROL_ALIGN_LEFT
	_oGetSum:SetFocus()

	// -- BOTAO DE ESTORNO
	_oBmpEstorno := TBtnBmp2():New(000,000,040,040,"ESTOMOVI",,,,{|| EstrSum(_oBrwSum:aCols[_oBrwSum:nAt][1], _oBrwSum:nAt) },_oPnlConfRod,"Estornar conferência",,.T.)
	_oBmpEstorno:Align := CONTROL_ALIGN_RIGHT

	// ativa o dialogo
	oDlgEtqS:Activate(,,,.F.,,,)

	// Retorno
	If (_nQtdProd > 0)
		_lRet := .T.
	EndIf

Return (_lRet)
//-------------------------------------------------------------------------------------------------
Static Function ConfSum()

	// se não fez nenhuma leitura
	If ( Len(_aColsSum) == 0 )
		U_FtWmsMsg("Nenhuma etiqueta foi bipada. Faça alguma leitura para poder retornar a tela principal")
		Return
	Else
		If U_FtYesNoMsg("Finaliza conferência desta etiqueta?")
			_nQtdProd	:= Len(_aColsSum)
			oDlgEtqS:End()
		EndIf
	EndIf

Return
//-------------------------------------------------------------------------------------------------
Static Function EstrSum(cEtiqCli,nPos)

	// se estiver vazio, não faz nada para não gerar errlogs
	If !(Empty(cEtiqCli))
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
	EndIf

	_oSayTS:Refresh( .T. )

Return
//-------------------------------------------------------------------------------------------------
Static Function AddBrwS(_cProdBp)
	Local _nX
	Local lRet       := .T.
	Local cQuery     := ""
	Local _cRet      := ""
	local _aRetZ56   := {}
	local _aRetZ07   := {}
	local lEtqLegado := .T.    // se etiqueta faz parte do banco de dados legado, que deu entrada sem vincular com nossa
	Local _cSequen

	// Valida se a etiqueta já foi conferida (em memória/tela)
	If (lRet)
		For _nX := 1 to Len(_aColsSum)
			If ( ASCAN(_aColsSum, { |x| x[1] == _cProdBp }) > 0 )
				U_FtWmsMsg("A etiqueta " + AllTrim(_cProdBp) + " já foi adicionada!")
				lRet := .F.
				_cProdBp := Space(8)
				_oGetSum:Refresh(.T.)
				_oGetSum:SetFocus()
			EndIf
		Next _nX
	EndIf

	// Valida se tem 8 digitos
	If (lRet)
		If (Len(_cProdBp) < 8 )
			U_FtWmsMsg("Barcode " + AllTrim(_cProdBp) + " inválido!")
			lRet := .F.
			_cProdBp := Space(8)
			_oGetSum:Refresh(.T.)
			_oGetSum:SetFocus()
		EndIf
	EndIf


	// valida se etiqueta bipada faz parte da carga de etiquetas/banco de dados legado
	// que já existia no sistema antes da rotina e portanto, não foi vinculado o código de barras com uma etiqueta
	// Tecadi na conferência de entrada
	// pressupôe-se que toda etiqueta é parte de legado, até que a query/validação altere isso e passe a fazer
	// mais validações abaixo
	If (lRet)
		cQuery := " SELECT TOP 1 Z56_CODETI"
		cQuery += " FROM "  + RetSqlTab("Z56") + " (nolock) "
		cQuery += " WHERE " + RetSqlCond("Z56")
		cQuery += " AND Z56_CODCLI = '" + _cCodCliFor  + "' "
		cQuery += " AND Z56_LOJCLI = '" + _cLojCliFor  + "' "
		cQuery += " AND Z56_ETQCLI = '" + _cProdBp  + "' "

		_cRet := U_FTQuery(cQuery)

		// se trouxe resultado, significa que etiqueta Tecadi já foi vinculada em algum momento e não é etiqueta legado
		if !Empty(_cRet)
			lEtqLegado := .F.
		EndIf
	EndIf

	// validações da etiqueta do cliente
	If (lRet)
		// caso etiqueta seja legado, valida se equivale ao produto sendo lido/fracionado
		If (lEtqLegado)
			cQuery := " SELECT Z56_CODPRO"
			cQuery += " FROM "  + RetSqlTab("Z56") + " (nolock) "
			cQuery += " WHERE " + RetSqlCond("Z56")
			cQuery += " AND Z56_CODCLI = '" + _cCodCliFor  + "' "
			cQuery += " AND Z56_LOJCLI = '" + _cLojCliFor  + "' "
			cQuery += " AND Z56_ETQCLI = '" + _cProdBp  + "' "
			cQuery += " AND Z56_OK_ENT = 'N' "

			_cRet := U_FTQuery(cQuery)

			// se não localizou o código do produto para esta etiqueta, significa que ela não existe
			If Empty(_cRet)
				// Pulo-do-gato (do inglês Jump-of-the-cat) criado em 11/07/19 para virada da integração Sumitomo GWS x Totvs
				// visto que NEM SABEM que barcodes enviar para subirmos na base... então como foi liberado para o estoque existente não validar nada,
				// então cria registro na tabela Z56 do tipo "etiqueta legado" (sem entrada correta) para ir pra frente de qualquer jeito e que se dane...
				// Claro, assumimos que PIMPOWS biparam o código de produto certo...

				// pega o número sequencial máximo da máxima remessa 
				cQuery := " SELECT IsNull(MAX(Z56_SEQUEN), '0001') FROM " + RetSqlTab("Z56") + " WHERE " + RetSqlCond("Z56") + " AND Z56_REMESS = '0000000000'"
				_cSequen := Soma1(U_FTQuery(cQuery)) 

				_cInsZ56 := "INSERT INTO Z56010"
				_cInsZ56 += " (Z56_FILIAL, Z56_REMESS, Z56_SEQUEN, Z56_ETQCLI, Z56_CODCLI, Z56_LOJCLI, Z56_CODPRO, Z56_CODETI, Z56_QUANT, Z56_OK_ENT, Z56_OK_SAI, R_E_C_N_O_)"
				_cInsZ56 += " VALUES "
				_cInsZ56 += " ('"+xFilial("Z56")+"', '0000000000','" + _cSequen + "' ,'"+_cProdBp+"', '"+_cCodCliFor+"', '"+_cLojCliFor+"', '"+_cCodProd+"', '"+_cEtiqProd+"', 1, 'N', 'N', (SELECT MAX(R_E_C_N_O_) + 1  FROM Z56010) ) "

				// injeta no banco e não trata retorno, pq eu sou doidão
				TcSQLExec(_cInsZ56)
			EndIf

			// se produto da etiqueta é diferente do que está sendo fracionado/operacionalizado
			If (_cRet != _cCodProd) .AND. !( Empty(_cRet) )
				U_FtWmsMsg("Produto incorreto!" + CRLF + "Leitura: " + _cRet + CRLF + "Esperado: " + _cCodProd, "TWMSA012 - valida etq" )
				lRet := .F.
				_cProdBp := Space(8)
				_oGetSum:Refresh(.T.)
				_oGetSum:SetFocus()
			EndIf
		Else
			// caso não seja etiqueta cliente legado (que não teve vínculo na entrada)
			// valida se código de barras lido está relacionado com o pallet/etiqueta sendo fracionada
			cQuery := " SELECT Z56_CODPRO,Z56_CODETI,B1_DESC "
			cQuery += " FROM " + RetSQLTab("Z56") + " (nolock) "
			cQuery += " 	INNER JOIN " + RetSQLTab("SB1") + " (nolock) "
			cQuery += " 	ON "  + RetSqlCond("SB1")
			cQuery += " 	AND B1_COD = Z56_CODPRO "
			cQuery += " WHERE " + RetSqlCond("Z56")
			cQuery += " AND Z56_CODCLI = '" + _cCodCliFor + "'"
			cQuery += " AND Z56_LOJCLI = '" + _cLojCliFor + "'"
			cQuery += " AND Z56_ETQCLI = '" + _cProdBp    + "'"
			//			cQuery += " and Z56_CODPRO = '" + AllTrim(_cCodProd)   + "'"
			//			cQuery += " and Z56_CODETI = '" + AllTrim(_cEtiqProd)  + "'"

			_aRetZ56 := U_SqlToVet(cQuery)

			// se não encontrou resultado
			If (Len(_aRetZ56) != 1)
				U_FtWmsMsg("Código de barras (barcode) não localizado no banco de dados. Acione o CLIENTE para solicitar o envio.")
				lRet := .F.
				_cProdBp := Space(8)
				_oGetSum:Refresh(.T.)
				_oGetSum:SetFocus()
			EndIf

			// se encontrou, faz mais validações
			If (lRet)
				// verificar se barcode é do mesmo SKU
				if  ( _aRetZ56[1][1] != _cCodProd)
					U_FtWmsMsg("Barcode não corresponde ao produto da etiqueta! " + CRLF + "Barcode: " + AllTrim(_aRetZ56[1][1]) + CRLF + "Etiqueta: " + AllTrim(_cCodProd) + ".",;
					"TWMSA012 - addbrw")
					U_FtWmsMsg("Solicite verificação pelo account no sistema ou correção pelo cliente. Não é necessário abrir chamado.")
					lRet := .F.
					_cProdBp := Space(8)
					_oGetSum:Refresh(.T.)
					_oGetSum:SetFocus()
				EndIf

				// verificar se está lendo barcode atrelado a esta etiqueta
				if  ( _aRetZ56[1][2] != _cEtiqProd) .AND. (lret)
					U_FtWmsMsg("Este barcode não pertence a esta etiqueta!" + CRLF + "Etiq. vinculada: " + AllTrim(_aRetZ56[1][2]) + CRLF + "Etiq. lida: " + AllTrim(_cEtiqProd) + ".",;
					"TWMSA012 - addbrw")
					U_FtWmsMsg("Solicite verificação pelo account no sistema ou correção pelo cliente. Não é necessário abrir chamado.")
					lRet := .F.
					_cProdBp := Space(8)
					_oGetSum:Refresh(.T.)
					_oGetSum:SetFocus()
				EndIf

				// verificar se este barcode já foi lido em outra OS
				if (lRet)
					cQuery := "SELECT Z07_NUMOS, Z07_ETQPRD FROM " + RetSqlTab("z07") + " (nolock) "
					cQuery += " WHERE " + RetSqlCond("Z07") 
					cQuery += " AND Z07_ETQPRD = '" + _aRetZ56[1][2] + "'"
					cQuery += " AND Z07_NUMOS != '" + Z06->Z06_NUMOS + "'"
					cQuery += " AND Z07_SEQOS != '001'"

					_aRetZ07 := U_SQLToVet(cQuery)

					If (Len(_aRetZ07) > 0)
						U_FtWmsMsg("Barcode já lido na OS: " + AllTrim(_aRetZ07[1][1]) + CRLF + "Etiqueta: " + AllTrim(_aRetZ07[1][2]) + ".",;
						"TWMSA012 - addbrw")
						U_FtWmsMsg("Acesse a OS mencionada e faça os devidos estornos/correções. Não é necessário abrir chamado.")
						lRet := .F.
						_cProdBp := Space(8)
						_oGetSum:Refresh(.T.)
						_oGetSum:SetFocus()
					EndIf
				EndIf
			EndIf

		EndIf
	EndIf

	// valida se etiqueta do cliente já teve saída
	cQuery := " SELECT R_E_C_N_O_ "
	cQuery += " FROM " + RetSQLTab("Z56") + " (nolock) "
	cQuery += " WHERE " + RetSqlCond("Z56")
	cQuery += " AND Z56_CODCLI = '" + _cCodCliFor + "'"
	cQuery += " AND Z56_LOJCLI = '" + _cLojCliFor + "'"
	cQuery += " AND Z56_ETQCLI = '" + _cProdBp    + "'"
	cQuery += " AND Z56_OK_SAI = 'S'"

	_cRet := U_FTQuery(cQuery)

	// se encontrou resultado
	If !Empty(_cRet) .AND. (lRet)
		U_FtWmsMsg("Código de barras já teve conferência OU saída registrada.")
		lRet := .F.
		_cProdBp := Space(8)
		_oGetSum:Refresh(.T.)
		_oGetSum:SetFocus()
	EndIf

	// Adiciona no Browser e atualiza
	If (lRet)

		AADD(_aColsSum, {AllTrim(_cProdBp), 1, IIf(lEtqLegado, _cRet, _aRetZ56[1][1]), IIf(lEtqLegado, "", _aRetZ56[1][3]), .F.})
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
