#include "totvs.ch"

/*---------------------------------------------------------------------------+
!                         FICHA TECNICA DO PROGRAMA                          !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para divisao de palete                           !
+------------------+---------------------------------------------------------+
!Autor             ! David                       ! Data de Criacao ! 06/2015 !
+------------------+--------------------------------------------------------*/

User Function TWMSA029 (mvQryUsr)
	// controle de operação
	local _lRet := .F.

	// permite conferencia/recebimento por volumes
	private _lCtrVolume := .F.

	// valida se ha equipamento informado
	If ( ! Empty(_cCodEquip) )
		U_FtWmsMsg("No processo de retrabalho de volumes não é necessário equipamento!","ATENCAO")
		Return(.F.)
	EndIf

	// inclui o codigo do servico de conferencia (montagem) na query
	mvQryUsr += " AND Z06_SERVIC = 'T05' AND Z06_TAREFA = 'T05' "

	// txt para debug
	memowrit("C:\query\twmsa029_query.txt",mvQryUsr)

	// chama funcao para visualizar o resumo da OS
	If ( _lRet := U_ACDA002C(mvQryUsr,"EX",.T.,.T.,.F.,.F.) )
		// chama a rotina
		U_WMSA029A(	Z06->Z06_SERVIC,;
		Z06->Z06_TAREFA, ;
		Z06->Z06_STATUS, ;
		Z06->Z06_NUMOS, Z06->Z06_SEQOS, ;
		Z05->Z05_CLIENT, Z05->Z05_LOJA, ;
		Z06->Z06_PRIOR )
	EndIf

Return

// ** rotina principal para divisao de palete
User Function WMSA029A(mvCodServ, mvCodTaref, mvStatus, mvNumOS, mvSeqOS, mvCodCli, mvLojCli, mvPriori)

	// objetos locais
	local _oWmsDivEst
	local _oPnlDivCab
	local _oBmpDivNvPlt, _oBmpDivNvVol, _oBmpDivCons, _oBmpOpcoes
	local _oSayNewAgrupa, _oSayCodProd, _oSayCodEmb
	local _oCmbCodEmb

	// sub-menu
	local _oMnuOpcoes := nil
	local _oSbMnOpc1  := nil
	local _oSbMnOpc2  := nil
	local _oSbMnOpc3  := nil
	local _oSbMnOpc4  := nil

	// valida identificacao do produto
	local _cTpIdEtiq := U_FtWmsParam("WMS_PRODUTO_ETIQ_IDENT","C","INTERNA",.F.,"", mvCodCli, mvLojCli, "", mvNumOS)

	// controle de while
	local _lRet := .T.

	// controle de confirmacao
	local _lOk := .F.

	// query
	local _cQuery

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
	private _cEtiqEAN   := Space(13)
	Private _nTamCodPrd := TamSx3("B1_COD")[1]
	Private _cCodProd   := Space(_nTamCodPrd)
	Private _cNewAgrup  := Space(_nTamEtqInt)
	Private _cOldAgrup  := Space(_nTamEtqInt)
	Private _cDscProd   := ""
	Private _nQtdProd   := 1

	// Id do palete
	private _nTamIdPal := TamSx3("Z11_CODETI")[1]
	private _cIdPalete := Space(_nTamIdPal)
	private _cPltOrig  := Space(_nTamIdPal)
	private _cMskEtiq  := PesqPict("Z11","Z11_CODETI")
	private _cMskEAN   := PesqPict("SB1","B1_CODBAR")
	private _cCodUnit  := CriaVar("DC1_CODUNI",.F.)

	// objetos private
	private _oGetNewAgrupa, _oGetOldAgrupa, _oGetCodProd

	// variaveis do browse
	private _oBrwConfMont
	private _aHeadConf := {}
	private _aColsConf := {}

	// controle de apontamento de palete
	private _lNovoPalete := .T.

	// controle de apontamento de volume
	private _lNovoVolume := .T.

	// tipos de estoque
	private _cTpEmbala := ""
	private _aOpcoesEmb := sfRetTpEmbala(mvCodCli, mvLojCli) // retorna todas as embalagens disponíveis

	// codigo do unitizador padrao
	private _cUnitPdr   := SuperGetMV('TC_PLTPADR',.F.,"000001")
	// validação do controle por volume
	private _lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME", "L", .F., .F., "", Z05->Z05_CLIENT, Z05->Z05_LOJA, Nil, Z05->Z05_NUMOS)

	// armazem
	private _cArmzServ := Z06->Z06_LOCAL
	// endereco de retrabalho (o endereço de serviço vem a partir da geração da OS)
	private _cEndServ  := Z06->Z06_ENDSRV

	// mascara para campos quantidade
	private _cMaskQuant := U_FtWmsParam("WMS_MASCARA_CAMPO_QUANTIDADE", "C", PesqPict("SD1","D1_QUANT"), .F., "", Z05->Z05_CLIENT, Z05->Z05_LOJA, Nil, Z05->Z05_NUMOS)

	// define mensagem no monitor
	U_FtMsgMon()

	// valida sem tem estoque/palete disponivel no endereco
	_cQuery := "SELECT COUNT(DISTINCT Z16_ETQPAL) QTD_PALETE "
	// saldo por endereco
	_cQuery += "FROM "+RetSqlName("SBF")+" SBF "
	// saldo de mercadoria por palete
	_cQuery += "INNER JOIN "+RetSqlName("Z16")+" Z16 ON "+RetSqlCond("Z16")+" AND Z16_LOCAL = BF_LOCAL AND Z16_ENDATU = BF_LOCALIZ "
	_cQuery += "AND Z16_CODPRO = BF_PRODUTO "
	_cQuery += "AND Z16_SALDO > 0 "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SBF")+" "
	// endereco
	_cQuery += "AND BF_LOCALIZ = '"+_cEndServ+"' "

	// executa query
	If (U_FtQuery(_cQuery) == 0)
		// mensagem
		U_FtWmsMsg("Não há paletes disponíveis para divisão de estoque!","ATENCAO")
		// estorno
		Return(.F.)
	EndIf

	// atualiza os dados
	sfSelDados(.F.)

	// define novo pallet
	_lNovoPalete := (Empty(_cIdPalete))

	// monta o dialogo do monitor
	_oWmsDivEst := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Divisão de Estoque",,,.F.,,,,,,.T.,,,.T. )
	_oWmsDivEst:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlDivCab := TPanel():New(000,000,nil,_oWmsDivEst,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlDivCab:Align:= CONTROL_ALIGN_TOP

	// opcoes de operacoes

	// -- NOVO PALLET
	_oBmpDivNvPlt := TBtnBmp2():New(000,000,060,022,"ARMIMG32",,,,{|| sfNovoPalete() },_oPnlDivCab,"Novo Palete",,.T.)
	_oBmpDivNvPlt:Align := CONTROL_ALIGN_LEFT

	// -- NOVO VOLUME
	_oBmpDivNvVol := TBtnBmp2():New(000,000,060,022,"AVGARMAZEM",,,,{|| sfNovoVolume() },_oPnlDivCab,"Novo Volume",,.T.)
	_oBmpDivNvVol:Align := CONTROL_ALIGN_LEFT

	// -- CONSULTA DETALHES
	_oBmpDivCons := TBtnBmp2():New(000,000,060,022,"MDIHELP",,,,{|| sfDetConfer() } ,_oPnlDivCab,"Informações",,.T.)
	_oBmpDivCons:Align := CONTROL_ALIGN_LEFT

	// sub-itens do menus
	_oMnuOpcoes := TMenu():New(0,0,0,0,.T.)
	// adiciona itens no Menu
	// INTERROMPER
	_oSbMnOpc1 := TMenuItem():New(_oMnuOpcoes,"Interromper",,,,{|| sfInterromper(_oWmsDivEst, @_lOk) },,"STOP"   ,,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc1)
	// -- FINALIZAR OS
	_oSbMnOpc2 := TMenuItem():New(_oMnuOpcoes,"Finalizar Divisão",,,,{|| sfFinalizaOS(_oWmsDivEst, @_lOk) },,"CHECKED",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc2)
	// -- CONSULTAR DETALHES
	_oSbMnOpc3 := TMenuItem():New(_oMnuOpcoes,"Cons. Detalhe OS",,,,{|| U_ACDA002B(_cNumOrdSrv, _cSeqOrdSrv,.F.) },,"NOTE",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc3)
	// -- SAIR SEM INTERROMPER
	If ( (_lUsrGeren) .Or. (_lUsrAccou) .Or. (_lUsrSuper) )
		_oSbMnOpc4 := TMenuItem():New(_oMnuOpcoes,"Sair",,,,{|| _lOk := .T. , _oWmsDivEst:End()},,"FINAL",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOpc4)
	EndIf

	// -- BOTAO COM MAIS OPCOES
	_oBmpOpcoes := TBtnBmp2():New(000,000,060,022,"SDUAPPEND",,,,{|| Nil },_oPnlDivCab,"",,.T.)
	_oBmpOpcoes:Align := CONTROL_ALIGN_RIGHT
	_oBmpOpcoes:SetPopupMenu(_oMnuOpcoes)

	// tipos de embalagem
	_oSayCodEmb := TSay():New(025,003,{||"Embalagem"},_oWmsDivEst,,,.F.,.F.,.F.,.T.)
	_oCmbCodEmb := TComboBox():New(023,035,{|u| If(PCount()>0,_cTpEmbala:=u,_cTpEmbala)},_aOpcoesEmb,085,008,_oWmsDivEst,,,,,,.T.,,"",,,,,,,_cTpEmbala)
	_oCmbCodEmb:bWhen := {|| .T. }

	// nova etiqueta agrupadora (Destino)
	_oSayNewAgrupa := TSay():New(038,003,{||"Nova Agrupadora"},_oWmsDivEst,,,.F.,.F.,.F.,.T.)
	_oGetNewAgrupa := TGet():New(036,050,{|u| If(PCount()>0,_cNewAgrup:=u,_cNewAgrup)},_oWmsDivEst,050,010,_cMskEtiq,{|| Vazio().Or.sfVldAgrupa(@_lOk, _cNewAgrup, .T.) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNewAgrup",,)
	//_oGetNewAgrupa:bWhen := {|| (_lCtrVolume) }
	_oGetNewAgrupa:bWhen := {|| ( .T. ) }
	_oGetNewAgrupa:lReadOnly := ( ! _lNovoVolume )

	// etiqueta agrupadora antiga (origem)
	_oSayOldAgrupa := TSay():New(051,003,{||"Agrup. Origem"},_oWmsDivEst,,,.F.,.F.,.F.,.T.)
	_oGetOldAgrupa := TGet():New(049,050,{|u| If(PCount()>0,_cOldAgrup:=u,_cOldAgrup)},_oWmsDivEst,050,010,_cMskEtiq,{|| Vazio().Or.sfVldAgrupa(@_lOk, _cOldAgrup, .F.) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cOldAgrup",,)
	//_oSayOldAgrupa:bWhen := {|| (_lCtrVolume) }
	_oSayOldAgrupa:bWhen := {|| ( .T. ) }

	// informacoes do produto lido
	_oSayCodProd := TSay():New(064,003,{||"Etiq.Produto"},_oWmsDivEst,,,.F.,.F.,.F.,.T.)
	_oGetCodProd := TGet():New(062,050,{|u| If(PCount()>0,_cEtiqEAN:=u,_cEtiqEAN)},_oWmsDivEst,050,010,_cMskEAN,{|| Vazio() .Or. sfVldProd(@_oWmsDivEst, @_lOk, _cTpIdEtiq) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtiqEAN",,)

	// browse com a listagem dos produtos conferidos
	_oBrwConfMont := MsNewGetDados():New(075,003,154,118,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsConf),'AllwaysTrue()','','AllwaysTrue()',_oWmsDivEst,_aHeadConf,_aColsConf)

	// foco na etq de volume
	_oGetNewAgrupa:SetFocus()

	// ativa a tela
	_oWmsDivEst:Activate(,,,.F.,{|| _lOk },,)

Return

// ** função que valida a etiqueta agrupadora
Static Function sfVldAgrupa(mvOk, mvCodAgrup, mvNovaEtiq)
	// variavel de retorno
	local _lRet := .T.
	// query
	local _cQuery

	// dados do palete original
	local _aPltOrig := {}

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11")+mvCodAgrup ))
			U_FtWmsMsg("Identificador da agrupadora não encontrado no sistema!","ATENCAO")
			_lRet := .F.
		ElseIf !(Z11->Z11_TIPO $ "04|01")
			U_FtWmsMsg("Identificador da agrupadora inválido!","ATENCAO")
			_lRet := .F.
		ElseIf !mvNovaEtiq .and. POSICIONE("Z11", 1, xFilial("Z11") + mvCodAgrup, "Z11_TIPO") <> POSICIONE("Z11", 1, xFilial("Z11") + _cNewAgrup, "Z11_TIPO") 
			U_FtWmsMsg("Tipo de etiqueta (volume OU produto) diferente da antiga!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// se o volume já foi usado uma vez na mesma montagem ou conferencia
	If (_lRet) .And. (mvNovaEtiq)

		// query de validação do uso do volume
		_cQuery := " SELECT COUNT(*) QTD_ETIQ FROM "+RetSqlTab("Z07")
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("Z07")
		// codigo da etiqueta agrupadora
		_cQuery += " AND Z07_ETQVOL = '" + mvCodAgrup + "' "

		MemoWrit("c:\query\twmsa029_sfVldAgrupa_new_etq_Z07.txt", _cQuery)

		// se encontrou algum registro, vai informar ao usuário
		If (U_FtQuery(_cQuery) != 0)
			// mensagem
			U_FtWmsMsg("Essa etiqueta de volume já foi usada anteriomente. Use outra etiqueta!","ATENCAO")
			// variavel de retorno
			_lRet := .F.
		EndIf

	EndIf

	// se o volume já foi usado em algum palete
	If (_lRet) .And. (mvNovaEtiq)

		// query de validação do uso do volume
		_cQuery := " SELECT COUNT(*) QTD_ETIQ FROM "+RetSqlTab("Z16")
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("Z16")
		// codigo da etiqueta agrupadora
		_cQuery += " AND '" + mvCodAgrup + "' IN (Z16_ETQVOL,Z16_VOLORI) "

		MemoWrit("c:\query\twmsa029_sfVldAgrupa_new_etq_Z16.txt", _cQuery)

		// se encontrou algum registro, vai informar ao usuário
		If (U_FtQuery(_cQuery) != 0)
			// mensagem
			U_FtWmsMsg("Essa etiqueta de volume já foi usada anteriomente. Use outra etiqueta!","ATENCAO")
			// variavel de retorno
			_lRet := .F.
		EndIf

	EndIf


	// valida se a etiqueta antiga esta disponivel
	If (_lRet) .And. ( ! mvNovaEtiq )

		// funcao que retorna a composicao do palete, conforme etiqueta agrupadora
		// estrutura:
		// 1- Id Palete
		// 2- Cod. Produto
		// 3- Etq Produto
		// 4- Etq Volume
		// 5. Saldo
		// 6. End. Atual
		// 7. Saldo Atual
		// 8. Tipo de Estoque
		// 9. NumSeq
		//10. lote
		//11. dt validade lote
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
		If (mvNovaEtiq)
			// atualiza variaveis de controle
			_lNovoVolume := .F.
			// atualiza objetos
			_oGetNewAgrupa:lReadOnly := ( ! _lNovoVolume )
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
	_cQuery := " SELECT CASE WHEN Z07_ETQVOL <> '' THEN Z07_ETQVOL ELSE Z07_ETQPRD END AS Z07_ETQVOL, Z07_PRODUT, B1_DESC, SUM(Z07_QUANT) Z07_QUANT, Z07_TPESTO "
	// tabela de itens conferidos
	_cQuery += " FROM "+RetSqlTab('Z07')
	// cadastro de produtos
	_cQuery += " INNER JOIN "+RetSqlTab('SB1')+" ON "+RetSqlCond("SB1")+" AND B1_COD = Z07_PRODUT "
	// filtros
	_cQuery += " WHERE "+RetSqlCond("Z07")
	_cQuery += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	_cQuery += " AND Z07_CLIENT = '"+_cCodCliFor+"' AND Z07_LOJA  = '"+_cLojCliFor+"' "
	// somente que nao C-EM CONFERENCIA
	_cQuery += " AND Z07_STATUS = 'C' "
	// agrupamento de informacoes
	_cQuery += " GROUP BY CASE WHEN Z07_ETQVOL <> '' THEN Z07_ETQVOL ELSE Z07_ETQPRD END, Z07_PRODUT, B1_DESC, Z07_TPESTO "
	// ordem dos dados
	_cQuery += " ORDER BY CASE WHEN Z07_ETQVOL <> '' THEN Z07_ETQVOL ELSE Z07_ETQPRD END, Z07_PRODUT "

	memowrit("c:\query\twmsa029_sfSelDados.txt",_cQuery)

	// executa a query
	dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),"QRYCNF",.F.,.T.)

	// verifica a necessidade de criar o Header
	If (Len(_aHeadConf)==0)
		// browse de acompanhamento
		aAdd(_aHeadConf,{"Etq.Vol/Prd", "Z07_ETQVOL", _cMskEtiq                   , TamSx3("Z07_ETQVOL")[1], TamSx3("Z07_ETQVOL")[2],Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Produto"   , "Z07_PRODUT", PesqPict("Z07","Z07_PRODUT"), TamSx3("Z07_PRODUT")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Descr."    , "B1_DESC"   , PesqPict("SB1","B1_DESC")   , TamSx3("B1_DESC")[1]   , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Quant"     , "Z07_QUANT" , _cMaskQuant                 , TamSx3("Z07_QUANT")[1] , TamSx3("Z07_QUANT")[2] ,Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadConf,{"Tp.Estoque", "Z07_TPESTO", PesqPict("Z07","Z07_TPESTO"), TamSx3("Z07_TPESTO")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
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

	// data e hora da criação da Z16
	local _dDtTran, _cHrTran
	local _lRet := .T.

	// mensagem de confirmacao
	If ( ! U_FtYesNoMsg("Confirma novo palete ?") )
		Return(.F.)
	EndIf

	// inicia transacao
	BEGIN TRANSACTION

		// funcao generica para geracao do Id Palete
		_cIdPalete := U_FtGrvEtq("03",{_cUnitPdr,""})
		// define o codigo do unitizador
		_cCodUnit := Z11->Z11_UNITIZ

		// data e hora da criação da Z16
		_dDtTran := Date()
		_cHrTran := Time()

		// finaliza os itens conferidos
		_cUpdZ07 := " UPDATE " + RetSqlName("Z07")
		// status finalizado
		_cUpdZ07 += " SET Z07_STATUS = 'D', Z07_PALLET = '" + _cIdPalete + "', Z07_UNITIZ = '" + _cCodUnit + "' "
		// filtro padrao
		_cUpdZ07 += " WHERE Z07_FILIAL = '" + xFilial("Z07") + "' AND D_E_L_E_T_ = ' ' "
		// filtro da OS especifica
		_cUpdZ07 += " AND Z07_NUMOS  = '" + _cNumOrdSrv + "' AND Z07_SEQOS = '" + _cSeqOrdSrv + "' "
		// status C=Em Conferência
		_cUpdZ07 += " AND Z07_STATUS = 'C' "
		// usuario
		_cUpdZ07 += " AND Z07_USUARI = '" + _cCodOper + "' "

		// executa o update
		If (TcSQLExec(_cUpdZ07) < 0)
			// rollback na transacao
			DisarmTransaction()
			// mensagem
			U_FtWmsMsg("*** ERRO NA ATUALIZACAO DO SALDO POR PALETE (sfNovoPalete.1) ***" + CRLF + CRLF + TCSQLError(),"ATENCAO")
			// retorno
			_lRet := .F.
			Break
		EndIf

		If (_lRet)
			// realiza a formacao da composicao do palete selecionado
			_cQryPalete := " SELECT Z07_LOCAL, Z07_PALLET, Z07_PLTORI, Z07_ETQPRD, Z07_PRODUT, Z07_NUMSEQ, Z07_UNITIZ, SUM(Z07_QUANT) QTD_ENDERE, Z07_EMBALA, Z07_TPESTO, Z07_CODBAR, Z07_ETQVOL, Z07_VOLORI, Z07_ENDATU, Z07_LOTCTL, Z07_VLDLOT "
			// itens conferidos da OS
			_cQryPalete += " FROM " + RetSqlTab("Z07")
			// filtro padrao
			_cQryPalete += " WHERE " + RetSqlCond("Z07")
			// filtro da OS especifica
			_cQryPalete += " AND Z07_NUMOS  = '" + _cNumOrdSrv + "' AND Z07_SEQOS = '" + _cSeqOrdSrv + "' "
			// status C=Em Conferência
			_cQryPalete += " AND Z07_STATUS = 'D' "
			// ID Palete
			_cQryPalete += " AND Z07_PALLET = '" + _cIdPalete + "' "
			// usuario
			_cQryPalete += " AND Z07_USUARI = '" + _cCodOper + "' "
			// agrupa dados
			_cQryPalete += " GROUP BY Z07_LOCAL, Z07_PALLET, Z07_PLTORI, Z07_ETQPRD, Z07_PRODUT, Z07_NUMSEQ, Z07_UNITIZ, Z07_EMBALA, Z07_TPESTO, Z07_CODBAR, Z07_ETQVOL, Z07_VOLORI, Z07_ENDATU, Z07_LOTCTL, Z07_VLDLOT "
			
			// para debug
			memowrit("C:\query\update_twmsa029_cQryPalete.txt", _cQryPalete)
			
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
				RecLock("Z16", .T.)
				Z16->Z16_FILIAL   := xFilial("Z16")
				Z16->Z16_ETQPAL   := _QRYIDPLT->Z07_PALLET
				Z16->Z16_PLTORI   := _QRYIDPLT->Z07_PLTORI
				Z16->Z16_UNITIZ   := _QRYIDPLT->Z07_UNITIZ
				Z16->Z16_ETQPRD   := _QRYIDPLT->Z07_ETQPRD
				Z16->Z16_CODPRO   := _QRYIDPLT->Z07_PRODUT
				Z16->Z16_QUANT    := _QRYIDPLT->QTD_ENDERE
				Z16->Z16_SALDO    := _QRYIDPLT->QTD_ENDERE
				Z16->Z16_NUMSEQ   := _QRYIDPLT->Z07_NUMSEQ
				Z16->Z16_STATUS   := "T" // V=Vazio / T=Total / P=Parcial
				Z16->Z16_QTDVOL   := _QRYIDPLT->QTD_ENDERE
				Z16->Z16_ENDATU   := _QRYIDPLT->Z07_ENDATU
				Z16->Z16_ORIGEM   := "DIV"
				Z16->Z16_LOCAL    := _QRYIDPLT->Z07_LOCAL
				Z16->Z16_TPESTO   := _QRYIDPLT->Z07_TPESTO
				Z16->Z16_CODBAR   := _QRYIDPLT->Z07_CODBAR
				Z16->Z16_EMBALA   := _QRYIDPLT->Z07_EMBALA
				Z16->Z16_ETQVOL   := _QRYIDPLT->Z07_ETQVOL
				Z16->Z16_VOLORI   := _QRYIDPLT->Z07_VOLORI
				Z16->Z16_DATA     := _dDtTran
				Z16->Z16_HORA     := _cHrTran
				Z16->Z16_LOTCTL   := _QRYIDPLT->Z07_LOTCTL
				Z16->Z16_VLDLOT   := StoD(_QRYIDPLT->Z07_VLDLOT)
				Z16->(MsUnLock())

				// atualiza o saldo do palete de origem
				_cUpdZ16 := " UPDATE " + RetSqlName("Z16") + " SET Z16_SALDO = Z16_SALDO - " + AllTrim(Str(_QRYIDPLT->QTD_ENDERE))
				// filtro padrao
				_cUpdZ16 += " WHERE Z16_FILIAL = '" + xFilial("Z16") + "' AND D_E_L_E_T_ = ' ' "
				// id do palete ORIGEM
				_cUpdZ16 += " AND Z16_ETQPAL = '" + _QRYIDPLT->Z07_PLTORI + "' "
				// etiqueta produto
				//_cUpdZ16 += " AND Z16_ETQPRD = '" + _QRYIDPLT->Z07_ETQPRD + "' "
				// codigo do produto
				_cUpdZ16 += " AND Z16_CODPRO = '" + _QRYIDPLT->Z07_PRODUT + "' "
				// etiqueta de volume ORIGEM
				_cUpdZ16 += " AND (case when z16_etqvol <> '' then z16_etqvol else z16_etqprd end) = '" + _QRYIDPLT->Z07_VOLORI + "' "
				// etiqueta de TIPO DE ESTOQUE
				_cUpdZ16 += " AND Z16_TPESTO = '" + _QRYIDPLT->Z07_TPESTO + "' "
				// LOTE
				_cUpdZ16 += " AND Z16_LOTCTL = '" + _QRYIDPLT->Z07_LOTCTL + "' "
				
				// para debug
				memowrit("C:\query\update_twmsa029_cUpdZ16.txt", _cUpdZ16)
				
				// executa o update
				If (TcSQLExec(_cUpdZ16) < 0)
					// rollback na transacao
					DisarmTransaction()
					// mensagem
					U_FtWmsMsg("*** ERRO NA ATUALIZACAO DO SALDO POR PALETE (sfNovoPalete.2) ***"+CRLF+CRLF+TCSQLError(),"ATENCAO")
					// retorno
					_lRet := .F.
					Break
				EndIf

				// proximo item
				_QRYIDPLT->(dbSkip())
			EndDo

			// ao confirmar novo palete, verifica necessidade de agrupar registros da composicao de palete
			// redmine: Defeito #71
			If (_lRet)
				sfAgrVolPlt(_cIdPalete)
			EndIf
		EndIf

		// finaliza transacao
	END TRANSACTION

	If (_lRet)
		// atualiza variaveis
		_lNovoPalete := .T.
		_lNovoVolume := .T.
		_cEtiqProd   := Space(Len(_cEtiqProd))
		_cCodProd    := Space(_nTamCodPrd)
		_nQtdProd    := 1
		_cIdPalete   := Space(_nTamIdPal)
		_cPltOrig    := Space(_nTamIdPal)
		_cNewAgrup   := Space(_nTamEtqInt)
		_cOldAgrup   := Space(_nTamEtqInt)

		// atualiza os dados
		sfSelDados(.T.)

		// atualiza objeto para pemitir novas leituras
		_oGetNewAgrupa:lReadOnly := (!_lCtrVolume) .And. (!_lNovoVolume)

		// foco no campo
		_oGetNewAgrupa:SetFocus()
	EndIf

Return(_lRet)

// ** funcao para gerar novo volume
Static Function sfNovoVolume()
	// variavel de retorno
	local _lRet := .T.

	// solicita confirmacao
	If (_lRet) .And. ( ! U_FtYesNoMsg("Confirma novo volume?"))
		_lRet := .F.
		Return(_lRet)
	EndIf

	// dados ok
	If (_lRet)
		// reinicia variaveis
		_cCodProd    := Space(Len(_cCodProd))
		_cEtiqProd   := Space(Len(_cEtiqProd))
		_nQtdProd    := 1
		_cNewAgrup   := Space(_nTamEtqInt)
		_cOldAgrup   := Space(_nTamEtqInt)
		_lNovoVolume := .T.

		// atualiza objeto para pemitir novas leituras
		_oGetNewAgrupa:lReadOnly := (!_lCtrVolume) .And. (!_lNovoVolume)

		// atualiza os dados
		sfSelDados()

		// foco de objetos
		_oGetNewAgrupa:SetFocus()
	EndIf

Return(_lRet)

// ** funcao para interromper o servico atual
Static Function sfInterromper(mvTela, mvTelaOk)
	// solicita confirmacao do usuario
	If ( ! U_FtYesNoMsg("Interromper?","ATENÇÃO"))
		Return(.F.)
	EndIf
	// funcao generica para interromper atividade
	U_FtWmsMtInt(_cNumOrdSrv, _cSeqOrdSrv)
	mvTelaOk := .T.
	mvTela:End()
Return(.T.)

// ** funcao para validacao do codigo do produto digitado (lido)
Static Function sfVldProd(mvDlg, mvOk, mvTpIdEtiq)
	// query
	Local _cQuery := ""
	// controla se informa a quantidade manual
	Local _lInfManual := .F.
	// controle de retorno
	local _lRet := .T.
	// num seq do documento de entrada
	local _cNumSeq := ""
	// controle de for
	local _nX := 0

	// dados do palete original
	local _aPltOrig := {}

	// tipo de estoque do produto
	local _cTpEsto := ""

	// informacoes do lote
	local _cLoteProd := ""
	local _dDtVldLot := CtoD("//")

	// verifica se foi informado a etiqueta do produto
	If (_lRet) .and. ( Empty(_cEtiqEAN) )
		// mensagem
		U_FtWmsMsg("É necessário informar a etiqueta do produto!","ATENCAO")
		// variavel de controle
		_lRet := .F.
	EndIf

	// verifica se foi informado a etiqueta de origem
	If (_lRet) .and. ( Empty(_cOldAgrup) )
		// mensagem
		U_FtWmsMsg("É necessário informar a etiqueta de volume de ORIGEM!","ATENCAO")
		// variavel de controle
		_lRet := .F.
	EndIf

	// verifica se foi informado a etiqueta de destino
	If (_lRet) .and. ( Empty(_cNewAgrup) )
		// mensagem
		U_FtWmsMsg("É necessário informar a etiqueta de volume de DESTINO!","ATENCAO")
		// variavel de controle
		_lRet := .F.
	EndIf

	// realiza a pesquisa do produto, podendo ser feita pelo codigo de barras
	If (_lRet) .and. ( ! U_FtCodBar(@_cEtiqEAN, @_cCodProd, @_lInfManual, @_cNumSeq, mvTpIdEtiq, _cCodCliFor))
		U_FtWmsMsg("Dados do produto não encontrados.","ATENCAO")
		// variavel de retorno
		_lRet := .F.
	EndIf

	// valida se o produtos compoe a agrupadora
	If (_lRet)

		// funcao que retorna a composicao do palete, conforme etiqueta agrupadora
		// estrutura:
		// 1- Id Palete
		// 2- Cod. Produto
		// 3- Etq Produto
		// 4- Etq Volume
		// 5. Saldo
		// 6. End. Atual
		// 7. Saldo Atual
		// 8. Tipo de Estoque
		// 9. NumSeq
		//10. lote
		//11. dt validade lote
		_aPltOrig := sfRetCompos(_cOldAgrup, _cCodProd)

		// valida se encontrou dados
		If (Len(_aPltOrig) == 0)
			// mensagem
			U_FtWmsMsg("Produto não pertence a essa etiqueta de volume!","ATENCAO")
			// variavel de retorno
			_lRet := .F.
		EndIf

	EndIf

	// atualiza descricao do produto
	_cDscProd := SB1->B1_DESC

	// reinicia a variavel de quantidade
	_nQtdProd := 1

	// verifica se o produto pode informar quantidades
	If (_lRet) .and. (_lInfManual)
		// tela para informar a quantidade
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

				Else
					// define o tipo de estoque
					_cTpEsto := _aPltOrig[_nX][8]
					// atualiza numseq original
					_cNumSeq := _aPltOrig[_nX][9]
					// informacoes do lote
					_cLoteProd := _aPltOrig[_nX][10]
					_dDtVldLot := _aPltOrig[_nX][11]
					// sai do Loop
					Exit

				EndIf

			EndIf
		Next _nX
	EndIf

	// se validou todos os itens, grava item conferido
	If (_lRet) .and. (_nQtdProd > 0)

		// insere quantidade lida na relacao de itens
		dbSelectArea("Z07")
		RecLock("Z07",.T.)
		Z07->Z07_FILIAL	:= xFilial("Z07")
		Z07->Z07_NUMOS	:= _cNumOrdSrv
		Z07->Z07_SEQOS	:= _cSeqOrdSrv
		Z07->Z07_CLIENT	:= _cCodCliFor
		Z07->Z07_LOJA	:= _cLojCliFor
		iIf(Z11->Z11_TIPO == "01", Z07->Z07_ETQPRD := _cNewAgrup, Z07->Z07_ETQPRD := _cEtiqProd)
		Z07->Z07_PRODUT	:= _cCodProd
		Z07->Z07_NUMSEQ	:= _cNumSeq
		Z07->Z07_LOCAL	:= _cArmzServ
		Z07->Z07_QUANT	:= _nQtdProd
		Z07->Z07_USUARI := _cCodOper
		Z07->Z07_DATA	:= Date()
		Z07->Z07_HORA	:= Time()
		Z07->Z07_PALLET	:= _cIdPalete
		Z07->Z07_PLTORI := _cPltOrig
		Z07->Z07_UNITIZ := _cCodUnit
		Z07->Z07_STATUS	:= "C" // C-EM CONFERENCIA / D-CONFERIDO/DISPONIVEL / M-EM MOVIMENTO / A-ARMAZENADO
		Z07->Z07_ENDATU	:= _cEndServ
		iIf(Z11->Z11_TIPO <> "01", Z07->Z07_ETQVOL := _cNewAgrup, Z07->Z07_ETQVOL := _cEtiqProd)
		Z07->Z07_VOLORI := _cOldAgrup
		Z07->Z07_CODBAR := _cEtiqEAN
		Z07->Z07_EMBALA := _cTpEmbala
		Z07->Z07_TPESTO := _cTpEsto
		Z07->Z07_LOTCTL := _cLoteProd
		Z07->Z07_VLDLOT := _dDtVldLot
		Z07->(MsUnLock())

		// atualiza os dados do browse
		sfSelDados(.T.)

	EndIf

	// reinicia variaveis
	_cCodProd  := Space(_nTamCodPrd)
	_cDscProd  := ""
	_cEtiqProd := Space(Len(_cEtiqProd))
	_cEtiqEAN  := Space(Len(_cEtiqEAN))

	// foca no objeto cod produto
	_oGetCodProd:SetFocus()

Return(.T.)

// ** funcao para realizar a finalizacao/encerramento total do servico de conferencia da OS
Static Function sfFinalizaOS(mvTela, mvOk)
	// array pra verificar se há novo serviço
	local _aPrxServico := U_FtPrxSrv(_cNumOrdSrv,_cSeqOrdSrv, Z05->Z05_CLIENT, Z05->Z05_LOJA, Nil)

	// confirmacao do processamento
	If ( ! U_FtYesNoMsg("Finalizar Divisão?"))
		Return(.F.)
	EndIf

	// verifica se tem mais usuarios na mesma contagem em conferencia
	_cQryConf := " SELECT COUNT(*) QTD_ITENS FROM "+RetSqlTab("Z07")
	// itens conferidos
	_cQryConf += " WHERE "+RetSqlCond("Z07")
	// numero da OS
	_cQryConf += " AND Z07_NUMOS   = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	// somente disponiveis
	_cQryConf += " AND Z07_STATUS = 'C' "

	// executa a query de verificacao
	If (U_FtQuery(_cQryConf)>0)
		U_FtWmsMsg("Existem Operadores com montagem em aberto. Favor verificar antes de prosseguir.", "Finalizar")
		Return(.F.)
	EndIf

	// verifica se ha algum palete nao finalizado
	_cQryConf := "SELECT COUNT(*) QTD_ITENS FROM "+RetSqlName("Z07")+" Z07 "
	// itens conferidos
	_cQryConf += "WHERE "+RetSqlCond("Z07")+" "
	// numero da OS
	_cQryConf += "AND Z07_NUMOS   = '"+_cNumOrdSrv+"' AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
	// somente disponiveis
	_cQryConf += "AND Z07_STATUS  = 'C' "

	// executa a query de verificacao
	If (U_FtQuery(_cQryConf)>0)
		U_FtWmsMsg("Há paletes com conferência não finalizada!", "Finalizar")
		Return(.F.)
	EndIf

	// finaliza os registros pendentes na Z07
	_cQryConf := " UPDATE "+RetSqlName("Z07")+" SET Z07_STATUS = 'F' "
	_cQryConf += " WHERE Z07_FILIAL = '"+xFilial("Z07")+"' "
	_cQryConf += " AND D_E_L_E_T_ = '' "
	_cQryConf += " AND Z07_STATUS = 'D' "
	_cQryConf += " AND Z07_NUMOS = '"+_cNumOrdSrv+"' "
	_cQryConf += " AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "

	// para debug
	memowrit("C:\query\update_twmsa029_finaliza.txt", _cQryConf)

	// executa o update
	If (TcSQLExec(_cQryConf) < 0)
		U_FtWmsMsg("Erro ao finalizar dados na tabela Z07!", "Finalizar")
		Return(.F.)
	EndIf

	// atualiza o status do servico para FI-FINALIZADO
	If ( ! U_FtWmsSta(;
	_cCodStatus,;
	"FI"        ,;
	_cNumOrdSrv ,;
	_cSeqOrdSrv  ) )
		// mensagem
		U_FtWmsMsg("Erro ao finalizar serviço!", "Finalizar")
		// retorno
		Return(.F.)
	EndIf

	// libera o novo item da OS para execucao
	If (Len(_aPrxServico) > 0)
		// busca na Z06 os próximos serviços para liberá-los
		dbSelectArea("Z06")
		Z06->(dbSetOrder(1)) //1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
		If Z06->(dbSeek( xFilial("Z06") + _cNumOrdSrv + _aPrxServico[1,2] ))

			// soó habilita quando o servico esta planejado
			If (Z06->Z06_STATUS == "PL")
				RecLock("Z06")
				Z06->Z06_DTEMIS := Date()
				Z06->Z06_HREMIS := Time()
				Z06->Z06_STATUS := "AG"
				Z06->Z06_ENDSRV	:= _cEndServ
				Z06->(MsUnLock())
			EndIf
		EndIf
	EndIf

	// mostra mensagem pro usuário e fecha a tela
	U_FtWmsMsg("Divisão de Estoque Finalizada!", "Finalizar")
	mvOk := .T.
	mvTela:End()

Return(mvOk)

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
	If ( ! U_FtYesNoMsg("Confirmar estorno da etiqueta " + Transf(mvIdVolume,_cMskEtiq) + " ?") )
		Return(_lRet)
	EndIf

	// monta SQL para estornar o palete
	_cQryZ07 := " SELECT Z07.R_E_C_N_O_ Z07RECNO, ISNULL(Z16.R_E_C_N_O_,0) Z16RECNO "
	// itens em conferencia
	_cQryZ07 += " FROM " + RetSqlTab("Z07")
	// composicao do palete
	_cQryZ07 += " LEFT JOIN " + RetSqlTab("Z16") + " ON " + RetSqlCond("Z16") + " AND Z16_ETQPAL = Z07_PALLET "
	_cQryZ07 += "      AND Z16_ETQVOL = Z07_ETQVOL AND Z16_ETQPRD = Z07_ETQPRD AND Z16_CODBAR = Z07_CODBAR "
	_cQryZ07 += "      AND Z16_CODPRO = Z07_PRODUT AND Z16_ENDATU = Z07_ENDATU "
	_cQryZ07 += "      AND Z16_TPESTO = Z07_TPESTO "
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

	// alimenta o vetor
	_aTmpRecno := U_SqlToVet(_cQryZ07)

	memowrit("C:\query\twmsa029_sfEstornoVol.txt",_cQryZ07)

	// inicia transacao
	BEGIN TRANSACTION

		// varre todos os recno
		For _nX := 1 to Len(_aTmpRecno)

			// posiciona no registro real
			dbSelectArea("Z07")
			Z07->(dbGoTo( _aTmpRecno[_nX][1] ))

			// atualiza o saldo do palete de origem
			If (Z07->Z07_STATUS == "D") // D-Disponivel (palete montado e saldo atualizado)

				// monta update para atualizacao de saldo
				_cUpdZ16 := "UPDATE " + RetSqlName("Z16") + " SET Z16_SALDO = Z16_SALDO + " + AllTrim(Str(Z07->Z07_QUANT))
				// filtro padrao
				_cUpdZ16 += " WHERE Z16_FILIAL = '"+xFilial("Z16")+"' AND D_E_L_E_T_ = ' ' "
				// id do palete ORIGEM
				_cUpdZ16 += " AND Z16_ETQPAL = '" + Z07->Z07_PLTORI + "' "
				// etiqueta produto
				//_cUpdZ16 += " AND Z16_ETQPRD = '" + Z07->Z07_ETQPRD + "' "
				// codigo do produto
				_cUpdZ16 += " AND Z16_CODPRO = '" + Z07->Z07_PRODUT + "' "
				// etiqueta de volume ORIGEM
				_cUpdZ16 += " AND (case when z16_etqvol <> '' then z16_etqvol else z16_etqprd end) = " + Z07->Z07_VOLORI + "' "
				// etiqueta de TIPO DE ESTOQUE
				_cUpdZ16 += " AND Z16_TPESTO = '" + Z07->Z07_TPESTO + "' "
				// LOTE
				_cUpdZ16 += " AND Z16_LOTCTL = '" + Z07->Z07_LOTCTL + "' "

				// executa o update
				If (TcSQLExec(_cUpdZ16) < 0)
					// rollback na transacao
					DisarmTransaction()
					_lRet := .F.
					U_FtWmsMsg("*** ERRO NA ATUALIZACAO DO SALDO POR PALETE (sfEstornoVol) ***"+CRLF+CRLF+TCSQLError(),"ATENCAO")
					Break
				EndIf

			EndIf

			// exclui o registro da conferencia
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
	local _nQtdTot := 0
	// total de paletes
	local _nTotPalete := 0
	// total de volumes
	local _nTotVolume := 0

	// variaveis temporarias
	local _cTmpPlt := ""
	local _cTmpVlm := ""

	// botão de estorno
	local _oBmpEstorno
	// botão de sair
	local _oBmpConsDetSair

	// monta a query
	_cQuery := " SELECT CASE WHEN Z07_STATUS = 'C' THEN '  ' ELSE 'OK' END Z07_STATUS, B1_COD, B1_DESC, Z07_ETQVOL, SUM(Z07_QUANT) Z07_QUANT, Z07_PALLET, '.F.' IT_DEL "
	// itens conferidos
	_cQuery += " FROM " + RetSqlTab("Z07")
	// cad. produtos
	_cQuery += " INNER JOIN " + RetSqlTab("SB1") + " ON " + RetSqlCond("SB1") + " AND B1_COD = Z07_PRODUT "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z07")
	// ordem de servico
	_cQuery += " AND Z07_NUMOS  = '" + _cNumOrdSrv + "' AND Z07_SEQOS = '" + _cSeqOrdSrv + "' "
	// cliente
	_cQuery += " AND Z07_CLIENT = '" + _cCodCliFor + "'  AND Z07_LOJA  = '" + _cLojCliFor + "' "
	// agrupamento dos dados
	_cQuery += " GROUP BY Z07_STATUS, Z07_ETQVOL, B1_COD, B1_DESC, Z07_PALLET "
	// ordem dos dados
	_cQuery += " ORDER BY Z07_PALLET, Z07_ETQVOL "

	memowrit("C:\query\TWSMA029_sfDetConfer.txt",_cQuery)

	// atualiza o vetor do browse
	_aColsDet := U_SqlToVet(_cQuery)

	// calcula a quantidade total de palete
	aEval(_aColsDet,{|x| _nQtdTot += x[5] , IIf(_cTmpPlt <> x[6], _nTotPalete ++, Nil), _cTmpPlt := x[6] })

	// calcula a quantidade total de volume
	aEval(_aColsDet,{|x| IIf(_cTmpVlm <> x[4], _nTotVolume ++, Nil), _cTmpVlm := x[4] })

	// adiciona a linha com o total
	aAdd(_aColsDet,{"", "", "TOTAL"    , "", _nQtdTot      ,"",.F.})
	aAdd(_aColsDet,{"", "", "TOTAL VLM", "", _nTotVolume   ,"",.F.})
	aAdd(_aColsDet,{"", "", "TOTAL PLT", "", _nTotPalete   ,"",.F.})

	// define o header
	aAdd(_aHeadDet,{"Sts"      , "Z07_STATUS", ""                       , 2                      , 0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Produto"  , "B1_COD"    , PesqPict("SB1","B1_COD") , TamSx3("B1_COD")[1]    , 0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Desc Prod", "B1_DESC"   , PesqPict("SB1","B1_DESC"), TamSx3("B1_DESC")[1]   , 0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Id Volume", "Z07_ETQVOL", _cMskEtiq                , TamSx3("Z07_ETQVOL")[1], 0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Quant"    , "Z07_QUANT" , _cMaskQuant              , TamSx3("Z07_QUANT")[1] , TamSx3("Z07_QUANT")[2],Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Id Palete", "Z07_PALLET", _cMskEtiq                , TamSx3("Z07_PALLET")[1], 0                     ,Nil,Nil,"C",Nil,"R",,,".F." })

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
Static Function sfRetTpEmbala(mvCodCli, mvLojaCli)

	// query para consulta
	local _cQuery := ""
	// array pra retorno
	local _aTpEmbala := {}

	// consulto os tipos de estoque disponíveis na tabela
	_cQuery := " SELECT Z31_CODIGO +'-'+Z31_DESCRI TPEMBALA FROM "+RetSqlName("Z31")+" Z31  "
	_cQuery += " WHERE "+RetSqlCond("Z31")
	_cQuery += " AND Z31_SIGLA = (SELECT A1_SIGLA FROM "+RetSqlName("SA1")+" SA1 WHERE "+RetSqlCond("SA1")+" AND A1_COD = '"+mvCodCli+"' AND A1_LOJA = '" + mvLojaCli + "') "

	memowrit("C:\query\sfretemb_twmsa029.txt", _cQuery)

	// jogo os dados pro array
	_aTpEmbala := U_SqlToVet(_cQuery)

Return (_aTpEmbala)

// ** funcao que retorna os dados da camposicao do palete, comforme etiqueta agrupadora
Static Function sfRetCompos(mvEtqAgrup, mvCodProd)
	// variavel de retorno
	local _aRet := {}
	// query
	local _cQuery

	// valores padroes
	Default mvEtqAgrup := Space(_nTamEtqInt)
	Default mvCodProd  := Space(_nTamCodPrd)

	// cria query principal para filtrar saldo
	_cQuery := " SELECT * FROM ( "

	// query de validação do uso do volume
	_cQuery += " SELECT Z16_ETQPAL, Z16_CODPRO, Z16_ETQPRD, "
	_cQuery += " case when z16_etqvol <> '' then z16_etqvol else z16_etqprd end as z16_etqvol, " 
	_cQuery += " SUM(Z16_SALDO) Z16_SALDO, Z16_ENDATU, "
	// consulta de saldo para que os registros não fiquem  negativos na Z16
	_cQuery += " Isnull(Sum(Z16_SALDO) - "
	_cQuery += " (SELECT Isnull(Sum(Z07_QUANT),0) FROM "+RetSqlTab("Z07")
	_cQuery += "  WHERE "+RetSqlCond("Z07")
	_cQuery += "   AND ( (case when z07_etqvol <> '' then z07_etqvol else z07_etqprd end) = (case when z16_etqvol <> '' then z16_etqvol else z16_etqprd end) "
	_cQuery += "      OR Z07_VOLORI = Z16_ETQVOL ) "
	_cQuery += "   AND Z07_PLTORI = Z16_ETQPAL "
	_cQuery += "   AND Z07_PRODUT = Z16_CODPRO "
	_cQuery += "   AND Z07_ENDATU = Z16_ENDATU "
	_cQuery += "   AND Z07_TPESTO = Z16_TPESTO "
	_cQuery += "   AND Z07_STATUS = 'C'), 0) SALDOPLT, " // usar somente status C pois o status D já teve o saldo baixado
	// tipo de estoque
	_cQuery += " Z16_TPESTO, Z16_NUMSEQ, Z16_LOTCTL, Z16_VLDLOT "
	// mapa de separacao
	_cQuery += " FROM "+RetSqlTab("Z08")
	// composicao de paletes
	_cQuery += " INNER JOIN "+RetSqlTab("Z16")+" ON "+RetSqlCond("Z16")
	// codigo id do palete
	_cQuery += " AND Z16_ETQPAL = (CASE WHEN Z08_NEWPLT <> ' ' THEN Z08_NEWPLT ELSE Z08_PALLET END) "
	// cod. produto
	_cQuery += " AND Z16_CODPRO = Z08_PRODUT "
	// etiqueta do volume
	_cQuery += " AND (case when z16_etqvol <> '' then z16_etqvol else z16_etqprd end) = '"+mvEtqAgrup+"' "
	// somente com saldo
	_cQuery += " AND Z16_SALDO > 0 "
	// cadastro produto
	If ( ! Empty(mvCodProd))
		// cad. produto
		_cQuery += "INNER JOIN "+RetSqlTab("SB1")+" ON "+RetSqlCond("SB1")+" AND B1_COD = '"+mvCodProd+"' AND B1_COD = Z16_CODPRO "
		// grupo/sigla
		_cQuery += "AND B1_GRUPO IN (SELECT A1_SIGLA FROM "+RetSqlTab("SA1")+" WHERE "+RetSqlCond("SA1")+" AND A1_COD = '"+_cCodCliFor+"' AND A1_LOJA = '"+_cLojCliFor+"') "
	EndIf
	// filtro do mapa
	_cQuery += "WHERE "+RetSqlCond("Z08")+" "
	// nr da OS
	_cQuery += "AND Z08_NUMOS = '"+_cNumOrdSrv+"' "
	// statuso R=Realizado
	_cQuery += "AND Z08_STATUS = 'R' "
	// agrupa dados
	_cQuery += "GROUP BY Z16_ETQPAL, Z16_CODPRO, Z16_ETQPRD, Z16_ETQVOL, Z16_ENDATU, Z16_TPESTO, Z16_NUMSEQ, Z16_LOTCTL, Z16_VLDLOT "

	// fecha query principal
	_cQuery += ") AS COMPOSICAO_PALETE "

	// somente com saldo
	_cQuery += " WHERE SALDOPLT <> 0 "

	// ordem dos dados
	_cQuery += " ORDER BY Z16_ETQPAL "

	MemoWrit("c:\query\twmsa029_sfVldAgrupa_sfRetCompos.txt",_cQuery)

	// dados do palete original
	// estrutura:
	// 1- Id Palete
	// 2- Cod. Produto
	// 3- Etq Produto
	// 4- Etq Volume
	// 5. Saldo
	// 6. End. Atual
	// 7. Saldo Atual
	// 8. Tipo de Estoque
	// 9. NumSeq
	//10. lote
	//11. dt validade lote
	_aRet := U_SqlToVet(_cQuery, {"Z16_VLDLOT"})

Return(_aRet)

// ** funcao para informar a quantidade manualmente (para produtos de pequeno porte)
Static Function sfInfQuant()
	// objetos
	local _oBtnFoco1
	// controle para nao fechar a tela
	Local _lRetOk := .F.

	// reinicia segunda unidade de medida
	_nQtdSegUM := 0

	// monta a tela para informa a quantidade
	_oWndInfQuant := MSDialog():New(020,020,120,200,"Informe a Quantidade",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlInfQtdCab := TPanel():New(000,000,nil,_oWndInfQuant,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlInfQtdCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpInfQtdOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRetOk := .T.,_oWndInfQuant:End() },_oPnlInfQtdCab,"Ok",,.T.)
	_oBmpInfQtdOk:Align := CONTROL_ALIGN_LEFT

	// titulo
	_oSayQuant := TSay():New(025,005,{||"Quantidade (" + SB1->B1_UM + "):"},_oWndInfQuant,,_oFnt02,.F.,.F.,.F.,.T.)

	// botao para usar como foco (nao é usado pra nada)
	_oBtnFoco1 := TButton():New(033,030,"",_oWndInfQuant,{|| Nil },010,010,,,,.T.,,"",,,,.F. )
	_oGetQuant := TGet():New( 033,030,{|u| If(PCount()>0,_nQtdProd:=u,_nQtdProd)},_oWndInfQuant,60,010, _cMaskQuant, {|| Positivo().and.sfVldQuant(2) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nQtdProd",,)

	// seta o foco na mensagem
	_oGetQuant:SetFocus()

	// ativacao da tela com validacao
	_oWndInfQuant:Activate(,,,.T.,{|| _lRetOk })

Return

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

	// executa a funcao do botao Ok
	_oBmpInfQtdOk:Click()

Return(.T.)

// ** funcao que agrupa registros da composicao de palete
// redmine: Defeito #71
Static Function sfAgrVolPlt(mvIdPalete)
	// variavel de retorno
	local _lRet := .F.
	// query dos dados
	local _cQuery
	// alias temporario
	local _cAlEtqPlt := GetNextAlias()
	// recno
	local _aTmpRecno := {}
	local _nTmpRecno

	// prepara consulta para verificar os registros duplicados
	_cQuery := " SELECT Z16_FILIAL, "
	_cQuery += "        Z16_ETQPAL, "
	_cQuery += "        Z16_UNITIZ, "
	_cQuery += "        Z16_ETQPRD, "
	_cQuery += "        Z16_CODPRO, "
	_cQuery += "        Sum(Z16_QUANT)             Z16_QUANT, "
	_cQuery += "        Sum(Z16_QTDVOL)            Z16_QTDVOL, "
	_cQuery += "        Z16_ENDATU, "
	_cQuery += "        Sum(Z16_SALDO)             Z16_SALDO, "
	_cQuery += "        Count(DISTINCT Z16_PLTORI) QTD_PLTORI, "
	_cQuery += "        Z16_LOCAL, "
	_cQuery += "        Z16_EMBALA, "
	_cQuery += "        Z16_TPESTO, "
	_cQuery += "        Z16_CODBAR, "
	_cQuery += "        Z16_ETQVOL, "
	_cQuery += "        Z16_SEQKIT, "
	_cQuery += "        Z16_CODKIT, "
	_cQuery += "        Count(DISTINCT Z16_VOLORI) QTD_VOLORI, "
	_cQuery += "        Z16_LOTCTL, "
	_cQuery += "        Z16_VLDLOT, "
	_cQuery += "        Sum(Z16_QTSEGU)            Z16_QTSEGU, "
	// relacao dos RECNO
	_cQuery += "        (SELECT Rtrim(Z16REC.R_E_C_N_O_) + ';' "
	_cQuery += "         FROM   " + RetSqlName("Z16") + " Z16REC "
	_cQuery += "         WHERE  Z16REC.Z16_FILIAL = Z16.Z16_FILIAL "
	_cQuery += "                AND Z16REC.D_E_L_E_T_ = ' ' "
	_cQuery += "                AND Z16REC.Z16_ETQPAL = Z16.Z16_ETQPAL "
	_cQuery += "                AND Z16REC.Z16_UNITIZ = Z16.Z16_UNITIZ "
	_cQuery += "                AND Z16REC.Z16_ETQPRD = Z16.Z16_ETQPRD "
	_cQuery += "                AND Z16REC.Z16_CODPRO = Z16.Z16_CODPRO "
	_cQuery += "                AND Z16REC.Z16_ENDATU = Z16.Z16_ENDATU "
	_cQuery += "                AND Z16REC.Z16_LOCAL = Z16.Z16_LOCAL "
	_cQuery += "                AND Z16REC.Z16_EMBALA = Z16.Z16_EMBALA "
	_cQuery += "                AND Z16REC.Z16_TPESTO = Z16.Z16_TPESTO "
	_cQuery += "                AND Z16REC.Z16_CODBAR = Z16.Z16_CODBAR "
	_cQuery += "                AND Z16REC.Z16_ETQVOL = Z16.Z16_ETQVOL "
	_cQuery += "                AND Z16REC.Z16_SEQKIT = Z16.Z16_SEQKIT "
	_cQuery += "                AND Z16REC.Z16_CODKIT = Z16.Z16_CODKIT "
	_cQuery += "                AND Z16REC.Z16_LOTCTL = Z16.Z16_LOTCTL "
	_cQuery += "                AND Z16REC.Z16_VLDLOT = Z16.Z16_VLDLOT "
	_cQuery += "         FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(400)') REL_RECNO "
	// composicado do palete
	_cQuery += " FROM   " + RetSqlTab("Z16")
	// filtro padrao e id Palete
	_cQuery += " WHERE  " + RetSqlCond("Z16")
	_cQuery += "        AND Z16_ETQPAL = '" + mvIdPalete + "' "
	_cQuery += "        AND Z16_SALDO != 0 "
	// agrupamentos dos dados
	_cQuery += " GROUP  BY Z16_FILIAL, "
	_cQuery += "           Z16_ETQPAL, "
	_cQuery += "           Z16_UNITIZ, "
	_cQuery += "           Z16_ETQPRD, "
	_cQuery += "           Z16_CODPRO, "
	_cQuery += "           Z16_ENDATU, "
	_cQuery += "           Z16_LOCAL, "
	_cQuery += "           Z16_EMBALA, "
	_cQuery += "           Z16_TPESTO, "
	_cQuery += "           Z16_CODBAR, "
	_cQuery += "           Z16_ETQVOL, "
	_cQuery += "           Z16_SEQKIT, "
	_cQuery += "           Z16_CODKIT, "
	_cQuery += "           Z16_LOTCTL, "
	_cQuery += "           Z16_VLDLOT "

	MemoWrit("c:\query\twmsa029_sfAgrVolPlt.txt", _cQuery)

	// verifica se a query esta aberta
	If (Select(_cAlEtqPlt) != 0)
		dbSelectArea(_cAlEtqPlt)
		dbCloseArea()
	EndIf

	// executa a query
	dbUseArea(.T., 'TOPCONN', TCGENQRY(,,_cQuery), (_cAlEtqPlt), .F., .T.)
	dbSelectArea(_cAlEtqPlt)

	// varre a composicao do palete
	While (_cAlEtqPlt)->( ! Eof() )

		// se tem varias etiquetas de volume de origem
		If ((_cAlEtqPlt)->QTD_VOLORI > 1)

			// pega relacao de RECNO para excluir a origem
			_aTmpRecno := StrTokArr(AllTrim((_cAlEtqPlt)->REL_RECNO), ";")

			// varre todos os recno e exclui
			For _nTmpRecno := 1 to Len(_aTmpRecno)

				// abre a tabela origem
				dbSelectArea("Z16")
				Z16->(DbGoTo( Val(_aTmpRecno[_nTmpRecno]) ))
				// exclui o registro da composicao do palete
				RecLock("Z16")
				Z16->(dbDelete())
				Z16->(MsUnLock())

			Next _nTmpRecno

			// grava novo registro, com os dados agrupados
			dbSelectArea("Z16")
			RecLock("Z16", .T.)
			Z16->Z16_FILIAL   := xFilial("Z16")
			Z16->Z16_ETQPAL   := (_cAlEtqPlt)->Z16_ETQPAL
			Z16->Z16_PLTORI   := (_cAlEtqPlt)->Z16_ETQPAL
			Z16->Z16_UNITIZ   := (_cAlEtqPlt)->Z16_UNITIZ
			Z16->Z16_ETQPRD   := (_cAlEtqPlt)->Z16_ETQPRD
			Z16->Z16_CODPRO   := (_cAlEtqPlt)->Z16_CODPRO
			Z16->Z16_QUANT    := (_cAlEtqPlt)->Z16_QUANT
			Z16->Z16_SALDO    := (_cAlEtqPlt)->Z16_SALDO
			Z16->Z16_STATUS   := "T" // V=Vazio / T=Total / P=Parcial
			Z16->Z16_QTDVOL   := (_cAlEtqPlt)->Z16_QTDVOL
			Z16->Z16_ENDATU   := (_cAlEtqPlt)->Z16_ENDATU
			Z16->Z16_ORIGEM   := "AGR"
			Z16->Z16_LOCAL    := (_cAlEtqPlt)->Z16_LOCAL
			Z16->Z16_TPESTO   := (_cAlEtqPlt)->Z16_TPESTO
			Z16->Z16_CODBAR   := (_cAlEtqPlt)->Z16_CODBAR
			Z16->Z16_EMBALA   := (_cAlEtqPlt)->Z16_EMBALA
			Z16->Z16_ETQVOL   := (_cAlEtqPlt)->Z16_ETQVOL
			Z16->Z16_DATA     := Date()
			Z16->Z16_HORA     := Time()
			Z16->Z16_LOTCTL   := (_cAlEtqPlt)->Z16_LOTCTL
			Z16->Z16_VLDLOT   := StoD((_cAlEtqPlt)->Z16_VLDLOT)
			Z16->Z16_QTSEGU   := (_cAlEtqPlt)->Z16_QTSEGU
			Z16->(MsUnLock())

			// variavel de retorno
			_lRet := .T.
		EndIf

		// proxmo registro
		dbSelectArea(_cAlEtqPlt)
		(_cAlEtqPlt)->(dbSkip())
	EndDo

Return( _lRet )