#include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para execucao do servico de enderecamento de     !
!                  ! produtos quando mapa for de livre movimentacao          !
!                  ! - Chamada a partir da rotina TWMSA009/TACDA002          !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 02/2017 !
+------------------+--------------------------------------------------------*/

User Function TWMSA033(mvQryUsr)
	// variavel de retorno
	local _lRet := .F.
	// status para filtrar OS
	local _cStsFiltro := "EX"

	// valida se ha equipamento informado
	If (Empty(_cCodEquip))
		U_FtWmsMsg("É obrigatório informar um equipamento!","ATENCAO")
		Return(.F.)
	EndIf

	// inclui o codigo do servico de "transferencia" e tarefa de "movimentacao livre"
	mvQryUsr += " AND Z06_SERVIC = '014' AND Z06_TAREFA = 'T08' "
	// filtra se o operador eh recurso da OS
	mvQryUsr += " AND " + cQryUsrZ18

	// chama funcao para visualizar o resumo da OS (o condicional com o mvGeraMapa é apenas para não alterar o status da OS)
	If ( _lRet := U_ACDA002C(mvQryUsr, _cStsFiltro, .T., .T., .F., .T.) )

		// rotina generica de conferencia
		U_WMSA033A(	Z06->Z06_SERVIC, Z06->Z06_TAREFA, Z06->Z06_STATUS, ;
		Z06->Z06_NUMOS , Z06->Z06_SEQOS, ;
		Z05->Z05_CLIENT, Z05->Z05_LOJA,  ;
		Z06->Z06_PRIOR )

	EndIf

Return

// ** funcao principal de movimentacao de mercadoria livre
User Function WMSA033A(mvCodServ, mvCodTaref, mvStatus, mvNumOS, mvSeqOS, mvCodCli, mvLojCli, mvPriori)

	// controle da continuacao do processo
	local _lContProc := .T.
	// reiniciar processo
	local _lReinicia := .F.

	// verifica se permite transferência de volume unitário
	local _lTrsfVol := U_FtWmsParam("WMS_TRANSF_LIVRE_PERMITE_VOLUME_UNICO", "L", .F., .F., Nil, mvCodCli, mvLojCli, Nil, Nil)

	// tamanho do ID
	private _nTamIdEtq := TamSx3("Z11_CODETI")[1]
	// mascara da etiqueta
	private _cMskEtiq  := PesqPict("Z11","Z11_CODETI")

	// endereco de origem
	private _cArmzOrige  := CriaVar("BE_LOCAL",.F.)
	private _cEndOrige   := CriaVar("BE_LOCALIZ",.F.)
	private _lEndOriOk   := .F.
	private _cEtqEndOri  := Space(_nTamIdEtq)

	// endereco de destino
	private _cArmzDesti  := CriaVar("BE_LOCAL",.F.)
	private _cEndDesti   := CriaVar("BE_LOCALIZ",.F.)
	private _cEtqEndDes  := Space(_nTamIdEtq)
	private _lEndDesOk   := .F.

	// ID etiqueta lida
	private _cIdEtiqProd := Space(_nTamIdEtq) // refere-se a etiqueta lida, podendo ser de produto ou agrupadora

	// ID palete
	private _cIdPalete   := Space(_nTamIdEtq)
	private _lIdPaleOk   := .F.
	// codigo do unitizador
	private _cCodUnit    := CriaVar("Z11_UNITIZ",.F.)

	// mascara para campos quantidade
	private _cMaskQuant := U_FtWmsParam("WMS_MASCARA_CAMPO_QUANTIDADE", "C", PesqPict("SD1","D1_QUANT"), .F., "", mvCodCli, mvLojCli, "", mvNumOS)

	// dados do item da ordem de servico
	Private _cCodStatus := mvStatus
	private _cNumOrdSrv := mvNumOS
	private _cSeqOrdSrv := mvSeqOS
	Private _cCodCliFor := mvCodCli
	Private _cLojCliFor := mvLojCli

	// sigla do cliente
	private _cCliSigla  := Posicione("SA1", 1, xFilial("SA1") + _cCodCliFor + _cLojCliFor , "A1_SIGLA")

	// data e hora inicial
	private _dDataIni := CtoD("//")
	private _cHoraIni := ""

	// relacao de RECNO bloqueados
	private _aRegLock := {}
	private _aTmpLock := {}

	// controle geral WMS se permite agrupar paletes similares, validando SKU
	private _lAgrPalete := U_FtWmsParam("WMS_TRANSF_LIVRE_PERMITE_AGRUPAR_PALETE", "L", .F., .F., Nil, mvCodCli, mvLojCli, Nil, Nil)

	// controle geral da rotina se permite agrupar paletes similares, validando SKU
	private _lAgrPltEnd := .F.

	// controle de endereco de destino ocupado
	private _lEndDestOcup := .F.

	// tipo de transferência (01 - Pallet inteiro / 02 - Volume unitário)
	Private _cTipoTf := "01"

	// verifica se cliente está configurado para permitir movimentar volume individualmente ou apenas transferir pallet inteiro
	If ( _lTrsfVol ) 
		_cTipoTf := U_FtMultRet("Pallet inteiro", "Volume unitário", "01", "02", "Transferência livre", "Escolha o tipo de transferência:")
		IIf (_cTipoTf == "02", _lAgrPltEnd := .T., Nil)
	EndIf

	// loop do processamento
	While (_lContProc)

		// reinicia variaveis
		_cArmzOrige  := Space(Len(_cArmzOrige))
		_cEndOrige   := Space(Len(_cEndOrige))
		_cEtqEndOri  := Space(_nTamIdEtq)
		_lEndOriOk   := .F.

		_cEndDesti   := Space(Len(_cEndDesti))
		_cEtqEndDes  := Space(_nTamIdEtq)
		_cArmzDesti  := Space(Len(_cArmzDesti))
		_lEndDesOk   := .F.

		_cIdEtiqProd := Space(_nTamIdEtq)

		_cIdPalete   := Space(_nTamIdEtq)
		_lIdPaleOk   := .F.
		_cCodUnit    := Space(Len(_cCodUnit))

		_lReinicia   := .F.

		_dDataIni    := CtoD("//")
		_cHoraIni    := ""

		_aRegLock := {}
		_aTmpLock := {}

		_lEndDestOcup := .F.

		// tela principal para inicio da movimentacao
		If (_lContProc)
			// chama funcao para iniciar uma movimentacao de mercadoria
			_lContProc := sfInicMovim(@_lReinicia)
		EndIf

		// valida se a OS esta liberada para operacao
		If (_lContProc)
			_lContProc := sfVldOSEnc()
		EndIf

		// verifica se deve reiniciar
		If (_lReinicia)
			Loop
		EndIf

		// valida o tipo da OS pra verificar se pode confirmar o destino
		If (_lContProc)
			// chama funcao para validar/confirmar o endereco de destino
			_lContProc := sfConfDest(@_lReinicia)
		EndIf

		// valida se a OS esta liberada para operacao
		If (_lContProc)
			_lContProc := sfVldOSEnc()
		EndIf

		//se a OS nao esta liberada
		If (!_lContProc)
			//destrava os locks anteriormente realizados quando pegou o pallet
			LibLock(_aRegLock)
			MsUnLockAll()
		EndIf

		// verifica se deve reiniciar a movimentação
		If (_lReinicia)
			//destrava os locks anteriormente realizados quando pegou o pallet
			LibLock(_aRegLock)
			MsUnLockAll()

			//volta pro inicio do processo
			Loop
		EndIf

		// verifica se pode endereçar
		If (_lContProc)

			// funcao para enderecamento final
			If (Empty(_cEndDesti))
				// mensagem
				U_FtWmsMsg('Endereço de destino não informado.','ATENCAO')
				// controle de loop
				_lContProc := .F.

				//destrava os locks anteriormente realizados quando pegou o pallet
				LibLock(_aRegLock)
				MsUnLockAll()
			EndIf

			// funcao para realizar a movimentacao da mercadoria
			If (_lContProc)
				If ( ! sfGrvEndDest() )
					// mensagem
					U_FtWmsMsg('Erro ao realizar o Endereçamento. Favor repetir a operação.','ATENCAO')
					// controle de loop
					_lContProc := .F.

					//destrava os locks anteriormente realizados quando pegou o pallet
					LibLock(_aRegLock)
					MsUnLockAll()
				EndIf
			EndIf
		EndIf

	EndDo

Return( .T. )

// ** funcao para iniciar uma movimentacao de mercadoria
Static Function sfInicMovim(mvReinicia)

	// variavel de retorno
	local _lRet := .F.

	// controle de confirmacao da tela
	local _lFixaWnd := .F.

	// objetos locais
	local _oWndInicMov
	local _oPnInMvCb, _oPnInMvCen
	local _oSayNrOrdSrv
	local _oSayDscOri
	local _oGetEndOri
	local _oGetEtqProd
	local _oBtnFoco

	// botao com sub-opcoes
	local _oBmpOpcoes

	// sub-menu
	local _oMnuOpcoes := nil
	local _oSbMnOp01 := nil
	local _oSbMnOp02 := nil
	local _oSbMnOp03 := Nil
	local _oSbMnOp04 := Nil

	// monta o dialogo do monitor
	_oWndInicMov := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Transferência Livre 3.0",,,.F.,,,,,,.T.,,,.T. )
	_oWndInicMov:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnInMvCb := TPanel():New(000,000,nil,_oWndInicMov,,.F.,.F.,,CLR_HGRAY,20,20,.T.,.F.)
	_oPnInMvCb:Align:= CONTROL_ALIGN_TOP

	// titulo com a ordem de servico
	_oSayNrOrdSrv := TSay():New(006,005,{||"Ord.Serv: " + _cNumOrdSrv },_oPnInMvCb,,_oFnt05,.F.,.F.,.F.,.T.)

	// opcoes de operacoes

	// sub-itens do menus
	_oMnuOpcoes := TMenu():New(0,0,0,0,.T.)

	// adiciona itens no Menu
	// -- REINICIAR
	_oSbMnOp01 := TMenuItem():New(_oMnuOpcoes,"Reiniciar Mov. Atual",,,,{|| mvReinicia := .T., _lRet := .T., _lFixaWnd := .T. , _oWndInicMov:End() },,"RELOAD",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOp01)

	// -- FINALIZAR ORDEM DE SERVICO
	_oSbMnOp02 := TMenuItem():New(_oMnuOpcoes,"Finalizar OS",,,,{|| sfFinalizaOS(_oWndInicMov, @_lFixaWnd, @_lRet) },,"CHECKED",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOp02)

	// -- PERMITE MOVIMENTOS PARA ENDEREÇOS OCUPADOS
	If (_lAgrPalete) .AND. (_cTipoTf != "02")
		_oSbMnOp03 := TMenuItem():New(_oMnuOpcoes,"Conf. Movimen. p/ Ender. Ocupado",,,,{|| sfCfgAgrpPlt() },,"SDUCOUNT",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOp03)
	EndIf

	// -- SAIR
	_oSbMnOp04 := TMenuItem():New(_oMnuOpcoes,"Sair",,,,{|| _lFixaWnd := .T. , _oWndInicMov:End() },,"FINAL",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOp04)

	// -- BOTAO AÇÕES ADICIONAIS
	_oBmpOpcoes := TBtnBmp2():New(000,000,060,022,"SDUAPPEND",,,,{|| Nil },_oPnInMvCb,"",,.T.)
	_oBmpOpcoes:Align := CONTROL_ALIGN_RIGHT
	_oBmpOpcoes:SetPopupMenu(_oMnuOpcoes)

	// cria o panel para os campos
	_oPnInMvCen := TPanel():New(000,000,nil,_oWndInicMov,,.F.,.F.,,,110,110,.T.,.F.)
	_oPnInMvCen:Align:= CONTROL_ALIGN_TOP

	// etiqueta - endereco de origem
	If (_cTipoTf != "02")
		_oGetEndOri := TGet():New(005,003,{|u| If(PCount()>0,_cEtqEndOri:=u,_cEtqEndOri)},_oPnInMvCen,048,008,_cMskEtiq,{|| (Vazio()) .Or. (sfVldEtiqueta("02", _cEtqEndOri, @_lRet, _oWndInicMov, @_lFixaWnd, "ORI", Nil)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtqEndOri",,,,,, .T. ,"Endereço de Origem", 1)
		_oGetEndOri:bWhen := {|| ( ! _lEndOriOk ) }
		// endereco completo
		_oSayDscOri := TSay():New(025,010,{||">> " + _cEndOrige },_oPnInMvCen,,_oFnt05,.F.,.F.,.F.,.T.)
	Else
		_oSayDscOri := TSay():New(025,010,{||"Transf. de volume único ativada! "},_oPnInMvCen,,_oFnt05,.F.,.F.,.F.,.T.)
	EndIf

	// etiqueta de controle de produto
	_oGetEtqProd := TGet():New(040,003,{|u| If(PCount()>0,_cIdEtiqProd:=u,_cIdEtiqProd)},_oPnInMvCen,048,008,_cMskEtiq,{|| (Vazio()) .Or. (sfVldEtiqueta("01_04", _cIdEtiqProd, @_lRet, _oWndInicMov, @_lFixaWnd, Nil, Nil)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIdEtiqProd",,,,,, .T. ,"Etiqueta de Volume/Produto", 1)

	// cria um botao, que nao executa nada, serve apenas para receber o foco
	_oBtnFoco := TButton():New(000,000,"",_oPnInMvCen,{|| Nil },000,000,,,,.T.,,"",,,,.F. )

	// volta o foco para o Etiqueta Endereco Origem
	If (_cTipoTf == "02") // apenas volume
		_oGetEtqProd:SetFocus()
	Else
		_oGetEndOri:SetFocus()
	EndIf

	// ativa a tela
	_oWndInicMov:Activate(,,,.F.,{|| _lFixaWnd },,)

	// se dados ok, armazenada data e hora inicial da movimentacao
	If (_lRet) .And. ( ! mvReinicia ) .And. (_lFixaWnd)
		_dDataIni := Date()
		_cHoraIni := Time()
	EndIf

Return(_lRet)

// ** funcao para validacao do id da etiqueta (palete ou endereco)
Static Function sfVldEtiqueta(mvTpEtiq, mvIdEtiqueta, mvContProc, mvWndOrig, mvFechaTela, mvTipoEnd, mvCompPlt)
	// variavel de retorno
	local _lRet := .T.
	// query
	local _cQuery

	// variaveis temporarias
	local _nTmpReserv := 0
	local _nItPlt

	// variável para guardar o retorno da OS de inventário
	local _cOSInv := CriaVar("Z05_NUMOS",.F.) 

	// valores padroes
	Default mvTipoEnd := ""
	Default mvCompPlt := {}

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11") + mvIdEtiqueta ))
			U_FtWmsMsg("Etiqueta inválida!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// valida o tipo da etiqueta lida
	If (_lRet)

		If (Z11->Z11_TIPO $ "01_04") .And. (Z11->Z11_TIPO $ mvTpEtiq) // 01 - etiqueta de produto | 04 - etiqueta agrupadora
			// pesquisa um palete
			_cIdPalete := sfRetNrPalete(mvIdEtiqueta, Z11->Z11_TIPO)
			// valida se encontrou o palete
			_lRet := ( ! Empty(_cIdPalete) )
			// se encontrou, reposiciona no id do palete
			If (_lRet)
				dbSelectArea("Z11")
				Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
				If ! Z11->(dbSeek( xFilial("Z11") + _cIdPalete ))
					U_FtWmsMsg("Identificador do palete inválido!","ATENCAO")
					_lRet := .F.
				EndIf

				// atualiza os dados do palete
				If (_lRet)
					_cCodUnit  := Z11->Z11_UNITIZ
					_lIdPaleOk := .T.

				EndIf

			EndIf

		ElseIf (Z11->Z11_TIPO == "02") .And. (Z11->Z11_TIPO == mvTpEtiq) // 02 - etiqueta de endereco

			If (mvTipoEnd == "ORI") // origem
				_cArmzOrige := Z11->Z11_LOCAL
				_cEndOrige  := Z11->Z11_ENDERE
				_lEndOriOk  := .T.
			ElseIf (mvTipoEnd == "DES") // destino
				_cArmzDesti := Z11->Z11_LOCAL
				_cEndDesti  := Z11->Z11_ENDERE
				_lEndDesOk  := .T.
			EndIf

		ElseIf (Z11->Z11_TIPO == "03") .And. (Z11->Z11_TIPO == mvTpEtiq) // 03 - etiqueta de palete
			_cCodUnit  := Z11->Z11_UNITIZ

		Else
			U_FtWmsMsg("Tipo de etiqueta inválida!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// valida se o endereco de origem está bloqueado
	If (_lRet) .And. (Z11->Z11_TIPO == "02") .And. (Z11->Z11_TIPO == mvTpEtiq) .And. (mvTipoEnd == "ORI") // 02 - etiqueta de endereco
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
		If SBE->(dbSeek( xFilial("SBE") + _cArmzOrige + _cEndOrige)) .And. (SBE->BE_STATUS == "3")
			// mensagem
			U_FtWmsMsg("O endereço de origem está bloqueado. A operação não pode ser realizada!")
			// controle de edicao de campo
			_lEndOriOk := .F.
			// variavel de retorno
			_lRet := .F.
		EndIf
	EndIf

	// valida se o endereco de origem está vazio
	If (_lRet) .And. (Z11->Z11_TIPO == "02") .And. (Z11->Z11_TIPO == mvTpEtiq) .And. (mvTipoEnd == "ORI") // 02 - etiqueta de endereco
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
		If SBE->(dbSeek( xFilial("SBE") + _cArmzOrige + _cEndOrige)) .And. (SBE->BE_STATUS == "1")
			// mensagem
			U_FtWmsMsg("O endereço de origem está VAZIO. A operação não pode ser realizada!")
			// controle de edicao de campo
			_lEndOriOk := .F.
			// variavel de retorno
			_lRet := .F.
		EndIf
	EndIf

	/*
	// valida se o endereco de origem está bloqueado por softlock
	If (_lRet) .And. (Z11->Z11_TIPO == "02") .And. (Z11->Z11_TIPO == mvTpEtiq) .And. (mvTipoEnd == "ORI") // 02 - etiqueta de endereco
	dbSelectArea("SBE")
	SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
	If SBE->(dbSeek( xFilial("SBE") + _cArmzOrige + _cEndOrige))
	If ( ! SBE->( MsRLock()) )
	// mensagem
	U_FtWmsMsg("Endereço " + AllTrim(_cEndOrige) + " está bloqueado em outro processo/movimento.","TWMSA033 -> sfVldEtiqueta!")
	// controle de edicao de campo
	_lEndOriOk := .F.
	// variavel de retorno
	_lRet := .F.
	Else
	// adiciona RECNO para controle
	Aadd(_aTmpLock, {"SBE", SBE->( RecNo() )} )
	EndIf
	EndIf
	EndIf
	*/
	// valida se o endereço de origem está em processo de inventário
	If (_lRet) .And. (Z11->Z11_TIPO == "02") .And. (Z11->Z11_TIPO == mvTpEtiq) .And. (mvTipoEnd == "ORI")
		If ( U_FTEndInv(_cEndOrige, _cArmzOrige, @_cOSInv) )
			U_FtWmsMsg("O endereço de origem está em processo de inventário na OS " + _cOSInv + ". A operação não pode ser realizada!")
			_lRet := .F.
		EndIf
	EndIf

	// valida se o endereco de destino está bloqueado
	If (_lRet) .And. (Z11->Z11_TIPO == "02") .And. (Z11->Z11_TIPO == mvTpEtiq) .And. (mvTipoEnd == "DES") // 02 - etiqueta de endereco
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
		If SBE->(dbSeek( xFilial("SBE") + _cArmzDesti + _cEndDesti)) .And. (SBE->BE_STATUS == "3")
			// mensagem
			U_FtWmsMsg("O endereço de destino está BLOQUEADO. A operação não pode ser realizada!")
			// controle de edicao de campo
			_lEndDesOk := .F.
			// variavel de retorno
			_lRet := .F.
		EndIf
	EndIf

	// valida se o endereco de destino é válido - cliente
	If (_lRet) .And. (Z11->Z11_TIPO == "02") .And. (Z11->Z11_TIPO == mvTpEtiq) .And. (mvTipoEnd == "DES") // 02 - etiqueta de endereco
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
		If SBE->(dbSeek( xFilial("SBE") + _cArmzDesti + _cEndDesti ))
			// valida codigo do cliente
			If (SBE->BE_ZCODCLI != _cCodCliFor)
				// mensagem
				U_FtWmsMsg("O endereço de destino não está disponível para este cliente. A operação não pode ser realizada!")
				// controle de edicao de campo
				_lEndDesOk := .F.
				// variavel de retorno
				_lRet := .F.
			EndIf
		EndIf
	EndIf

	// valida se o endereco de destino é diferente da origem
	If (_lRet) .And. (Z11->Z11_TIPO == "02") .And. (Z11->Z11_TIPO == mvTpEtiq) .And. (mvTipoEnd == "DES") // 02 - etiqueta de endereco
		// verfica se endereco de origem e destino sao iguais
		If ((_cArmzOrige + _cEndOrige) == (_cArmzDesti + _cEndDesti))
			// mensagem
			U_FtWmsMsg("O endereço de destino não pode ser igual ao endereço de origem. A operação não pode ser realizada!")
			// controle de edicao de campo
			_lEndDesOk := .F.
			// variavel de retorno
			_lRet := .F.
		EndIf
	EndIf

	// prepara query para validar se ha reservas do endereco ou palete
	// não precisa validar se for endereço destino e a estrutura destino do tipo bloco ou docas (docas são usadas para transf. entre armazém)
	If (_lRet) .AND.  !(Z11->Z11_TIPO == "02" .AND. SBE->BE_ESTFIS $ "000007/000001")
		_cQuery := " SELECT Count(*) QTD_PREVISTO "
		_cQuery += " FROM   " + RetSqlTab("Z08")
		_cQuery += " WHERE  " + RetSqlCond("Z08")
		// valida endereco
		If (Z11->Z11_TIPO == "02") .And. (Z11->Z11_TIPO == mvTpEtiq) // 02 - etiqueta de endereco
			_cQuery += "        AND ( Z08_ENDORI = '" + Z11->Z11_ENDERE + "' OR Z08_ENDDES = '" + Z11->Z11_ENDERE + "' )
			_cQuery += "        AND Z08_LOCAL = '" + Z11->Z11_LOCAL + "'"
		EndIf
		// valida palete, somente na leitura do Id Palete ou Endereco de Origem
		If ((Empty(mvTipoEnd)) .Or. (mvTipoEnd == "ORI")) .And. ( ! Empty(_cIdPalete) ) // 01 - etiqueta de produto | 04 - etiqueta agrupadora
			_cQuery += "        AND ( Z08_PALLET = '" + _cIdPalete + "' OR Z08_NEWPLT = '" + _cIdPalete + "' ) "
		EndIf
		// status
		_cQuery += "        AND Z08_STATUS != 'R' "

		memowrit("c:\query\twmsa033_" + mvTpEtiq+"_sfVldEtiqueta.txt", _cQuery)

		// atualiza a variavel temporaria
		_nTmpReserv := U_FtQuery(_cQuery)

		// verifica a quantidade de paletes encontrado
		If (_nTmpReserv != 0)
			// mensagem
			U_FtWmsMsg("Palete ou endereço já reservado para outra ordem de serviço!","ATENCAO")
			// controle de
			If (Z11->Z11_TIPO == "02") .And. (Z11->Z11_TIPO == mvTpEtiq) // 02 - etiqueta de endereco
				If (mvTipoEnd == "ORI")
					_cArmzOrige := Space(Len(_cArmzOrige))
					_cEndOrige  := Space(Len(_cEndOrige))
					_lEndOriOk  := .F.
				ElseIf (mvTipoEnd == "DES") // destino
					_cArmzDesti := Space(Len(_cArmzDesti))
					_cEndDesti  := Space(Len(_cEndDesti))
					_lEndDesOk  := .F.
				EndIf
			EndIf
			// controle de id palete
			_lIdPaleOk := .F.
			// variavel de retorno
			_lRet := .F.
		EndIf
	EndIf

	// valida se o endereco de destino é válido
	If (_lRet) .And. (Z11->Z11_TIPO == "02") .And. (Z11->Z11_TIPO == mvTpEtiq) .And. (mvTipoEnd == "DES") // 02 - etiqueta de endereco

		// cadastro de endereco
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
		If SBE->(dbSeek( xFilial("SBE") + _cArmzDesti + _cEndDesti ))
			// posiciona no cadastro da estrutura fisica
			dbSelectArea("DC8")
			DC8->(dbSetOrder(1)) // 1-DC8_FILIAL, DC8_CODEST
			If DC8->(dbSeek( xFilial("DC8") + SBE->BE_ESTFIS ))
				// para estruturas fisicas porta paletes, valida se o endereco esta ocupado
				If (DC8->DC8_TPESTR $ "1/2") .And. (SBE->BE_STATUS == "2")

					// controle de endereco de destino ocupado
					_lEndDestOcup := .T.

					// valida se aceita movimentacao para enderecos ja ocupados (agrupar)
					If ( ! _lAgrPltEnd )
						// mensagem
						U_FtWmsMsg("O endereço de destino está OCUPADO. A operação não pode ser realizada!")
						// controle de edicao de campo
						_lEndDesOk := .F.
						// variavel de retorno
						_lRet := .F.
					EndIf

					// se permite agrupar palete, valida a composicao de SKU (nao permite misturar)
					If (_lRet) .And. (_lAgrPltEnd)

						// varre todos os itens do palete movimentado
						For _nItPlt := 1 to Len(mvCompPlt)

							// composição do palete (mvCompPlt)
							// 1-Quantidade
							// 2-Cod Produto
							// 3-Descricao
							// 4-Lote
							// 5-Validade do Lote
							// 6-Data número série
							// 7-Etq de volume
							// 8-Etq de produto
							// 9-Controle DELETE

							// valida se o produto existe no endereço destino
							dbSelectArea("SBF")
							SBF->(dbSetOrder(1)) // 1-BF_FILIAL, BF_LOCAL, BF_LOCALIZ, BF_PRODUTO, BF_NUMSERI, BF_LOTECTL, BF_NUMLOTE
							If ! SBF->(dbSeek( xFilial("SBF") + _cArmzDesti + _cEndDesti + mvCompPlt[_nItPlt][2] ))
								// mensagem
								U_FtWmsMsg("O endereço de DESTINO não possui o item " + mvCompPlt[_nItPlt][2] + ". A operação não pode ser realizada!")
								// controle de edicao de campo
								_lEndDesOk := .F.
								// variavel de retorno
								_lRet := .F.
								// sai do Loop
								Exit
							EndIf

							// valida se é o mesmo lote 
							SBF->(dbSetOrder(2))  // 2 - BF_FILIAL, BF_PRODUTO, BF_LOCAL, BF_LOTECTL, BF_NUMLOTE, BF_PRIOR, BF_LOCALIZ, BF_NUMSERI, R_E_C_N_O_, D_E_L_E_T_
							If ! SBF->(dbSeek( xFilial("SBF") + mvCompPlt[_nItPlt][2] + _cArmzDesti + mvCompPlt[_nItPlt][4]))
								// mensagem
								U_FtWmsMsg("O endereço de DESTINO não possui o lote " + mvCompPlt[_nItPlt][4] +". A operação não pode ser realizada!")
								// controle de edicao de campo
								_lEndDesOk := .F.
								// variavel de retorno
								_lRet := .F.
								// sai do Loop
								Exit
							EndIf

							// valida se possui outras datas de série (não deixa misturar)
							_cQuery := " SELECT COUNT(DISTINCT Z16_DTSERI) QTD FROM " + RetSqlTab("Z16") + " WHERE " + RetSqlCond("Z16") 
							_cQuery += " AND Z16_LOCAL  = '" + _cArmzDesti + "' " 
							_cQuery += " AND Z16_ENDATU = '" + _cEndDesti + "' " 
							_cQuery += " AND Z16_DTSERI != '" + DtoS(mvCompPlt[_nItPlt][6]) + "'  "
							_cQuery += " AND Z16_SALDO > 0 "

							If ( U_FTQuery(_cQuery) > 0)
								// mensagem
								U_FtWmsMsg("O endereço de DESTINO possui outra data de série. A operação não pode ser realizada!")
								// controle de edicao de campo
								_lEndDesOk := .F.
								// variavel de retorno
								_lRet := .F.
								// sai do Loop
								Exit
							EndIf
						Next _nItPlt
					EndIf

				EndIf
			EndIf
		EndIf
	EndIf

	// valida se o endereço de destino está em processo de inventário
	If (_lRet) .And. (Z11->Z11_TIPO == "02") .And. (Z11->Z11_TIPO == mvTpEtiq) .And. (mvTipoEnd == "DES")
		If ( U_FTEndInv(_cEndDesti, _cArmzOrige, @_cOSInv) )
			U_FtWmsMsg("O endereço de origem está em processo de inventário na OS " + _cOSInv + ". A operação não pode ser realizada!")
			_lRet := .F.
		EndIf
	EndIf

	/*
	// tenta bloquear o registro do endereço de origem
	If (_lEndOriOk) .And. (_lIdPaleOk) .And. (_lRet)

	dbSelectArea("SBE")
	SBE->(dbGoto( _aTmpLock[1][2] ))
	If ( ! SBE->( MsRLock()) )
	// mensagem
	U_FtWmsMsg("O endereço está bloqueado por outro movimento/operação. Tente novamente em alguns minutos!")
	// variavel de retorno
	_lRet := .F.
	Else
	//bloqueia o registro
	IF ( ! SoftLock("SBE")  )
	// mensagem
	U_FtWmsMsg("O endereço está bloqueado por outro movimento/operação. Tente novamente em alguns minutos!")
	// variavel de retorno
	_lRet := .F.
	Else
	_aRegLock := Aclone(_aTmpLock)
	EndIf
	Endif
	EndIf
	*/
	// se existir o objeto, fecha
	If (mvWndOrig <> nil) .And. (_lEndOriOk) .And. (_lIdPaleOk) .And. (_lRet)
		// continuacao do processo
		mvContProc := .T.
		// permite fechar a tela
		mvFechaTela := .T.
		// fecha a tela
		mvWndOrig:End()
	EndIf

Return(_lRet)

// ** funcao que pesquisa o palete pela etiqueta do produto
Static Function sfRetNrPalete(mvIdEtqPrd, mvTpEtq)
	// variavel de retorno
	local _cRetIdPal := Space(_nTamIdEtq)
	// query
	local _cQryPlt

	// prepara query para buscar o Id do Palete
	_cQryPlt := " SELECT DISTINCT Z16_ETQPAL "
	// composicao de palete
	_cQryPlt += " FROM "+RetSqlTab("Z16")
	// filtro padrao
	_cQryPlt += " WHERE "+RetSqlCond("Z16")
	// 01 = Produto
	If (mvTpEtq == "01")
		_cQryPlt += " AND Z16_ETQPRD = '"+mvIdEtqPrd+"' "
		// 04 = Agrupadora
	ElseIf (mvTpEtq == "04")
		_cQryPlt += " AND Z16_ETQVOL = '"+mvIdEtqPrd+"' "
	EndIf
	// saldo na Z16 tem que ser maior que zero
	_cQryPlt += " AND Z16_SALDO > 0 "
	// somente no endereco
	If (_cTipoTf != "02")
		_cQryPlt += " AND Z16_ENDATU = '"+_cEndOrige+"' "
	EndIf
	// valida se o produto pertence ao cliente
	_cQryPlt += " AND SUBSTRING(Z16_CODPRO,1,4) = '"+_cCliSigla+"' "

	// executa a query
	_cRetIdPal := U_FtQuery(_cQryPlt)

	If (Empty(_cRetIdPal))
		U_FtWmsMsg("Etiqueta não encontrada no endereço!","ATENCAO")
	EndIf

	// se tipo de transferência for volume, também pega os dados do endereço
	If (_cTipoTf == "02") // apenas volume
		_cArmzOrige := Posicione("Z16", 1, xFilial("Z16") + _cRetIdPal, "Z16_LOCAL")
		_cEndOrige  := Posicione("Z16", 1, xFilial("Z16") + _cRetIdPal, "Z16_ENDATU")
		_lEndOriOk  := .T.
	EndIf

Return(_cRetIdPal)

// ** funcao para validar/confirmar o endereco de destino
Static Function sfConfDest(mvReinicia)

	// controle de confirmacao da tela
	local _lFixaWnd := .F.
	// variavel de retorno
	local _lRet := .F.

	// objetos locais
	local _oWndEndDest
	local _oPnlEndDestCab, _oPnlEndDest
	local _oBmpCancMov
	local _oGetEndDest
	local _oBrwEndDest

	// define o header para detalhes do endereco
	local _aHeadPlt := {}
	local _aColsPlt := {}

	// query
	local _cQuery

	// define header
	aAdd(_aHeadPlt,{"Quant"    , "IT_QUANT"  , _cMaskQuant, TamSx3("BF_QUANT")[1]  , TamSx3("BF_QUANT")[1]  ,Nil,Nil,"N",Nil,"R",,,".F."})
	aAdd(_aHeadPlt,{"Código"   , "IT_CODPROD", ""         , TamSx3("BF_PRODUTO")[1], TamSx3("BF_PRODUTO")[1],Nil,Nil,"C",Nil,"R",,,".F."})
	aAdd(_aHeadPlt,{"Descrição", "IT_DSCPROD", ""         , TamSx3("B1_DESC")[1]   , TamSx3("B1_DESC")[1]   ,Nil,Nil,"C",Nil,"R",,,".F."})
	aAdd(_aHeadPlt,{"Lote"     , "IT_LOTECTL", ""         , TamSx3("Z16_LOTCTL")[1], TamSx3("Z16_LOTCTL")[1],Nil,Nil,"C",Nil,"R",,,".F."})
	aAdd(_aHeadPlt,{"Validade" , "IT_VLDLOTE", ""         , TamSx3("Z16_VLDLOT")[1], TamSx3("Z16_VLDLOT")[1],Nil,Nil,"D",Nil,"R",,,".F."})
	aAdd(_aHeadPlt,{"Dt.Serie" , "IT_DTSERI" , ""         , TamSx3("Z16_DTSERI")[1], TamSx3("Z16_DTSERI")[1],Nil,Nil,"D",Nil,"R",,,".F."})

	// retorna o conteudo do palete
	_aColsPlt := sfRetCompPlt(_cIdPalete, _cEndOrige)

	If (Len(_aColsPlt) == 0)
		U_FtWmsMsg("Não foi possível localizar os dados da etiqueta!", "TWMSA033 - sfconfdest")
		Return(_lRet)
	EndIf

	// apresenta tela para definir o endereco atual/origem
	_oWndEndDest := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Endereçamento",,,.F.,,,,,,.T.,,,.T. )
	_oWndEndDest:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlEndDestCab := TPanel():New(000,000,nil,_oWndEndDest,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlEndDestCab:Align:= CONTROL_ALIGN_TOP

	// -- CANCELAR MOVIMENTO
	_oBmpCancMov := TBtnBmp2():New(000,000,030,022,"ESTOMOVI",,,,{|| mvReinicia := .T., _lRet := .T., _lFixaWnd := .T. , _oWndEndDest:End() },_oPnlEndDestCab,"Canc.Movim.",,.T.)
	_oBmpCancMov:Align := CONTROL_ALIGN_RIGHT


	// cria o panel para o browse
	_oPnlDefEndBrw := TPanel():New(000,000,nil,_oWndEndDest,,.F.,.F.,,,100,100,.T.,.F.)
	_oPnlDefEndBrw:Align:= CONTROL_ALIGN_TOP

	// browse com a listagem das OS's selecionadas
	_oBrwEndDest := MsNewGetDados():New(000,000,400,400,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsPlt),'AllwaysTrue()','','AllwaysTrue()',_oPnlDefEndBrw,_aHeadPlt,_aColsPlt)
	_oBrwEndDest:oBrowse:oFont := _oFnt04
	_oBrwEndDest:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// cria o panel para o campo de confirmacao do endereco
	_oPnlEndDest := TPanel():New(000,000,nil,_oWndEndDest,,.F.,.F.,,CLR_LIGHTGRAY,100,100,.T.,.F.)
	_oPnlEndDest:Align:= CONTROL_ALIGN_TOP

	// confirmacao do endereco de destino
	_oGetEndDest := TGet():New(006,005,{|u| If(PCount()>0,_cEtqEndDes:=u,_cEtqEndDes)},_oPnlEndDest,050,010,_cMskEtiq,{|| (Vazio()) .Or. (sfVldEtiqueta("02", _cEtqEndDes, @_lRet, _oWndEndDest, @_lFixaWnd, "DES", _aColsPlt)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtqEndDes",,,,,, .T. ,"Confirme o endereço de DESTINO", 1)

	// seta o foco no id palete
	_oGetEndDest:SetFocus()

	// ativa a tela
	_oWndEndDest:Activate(,,,.F.,{|| _lFixaWnd },,)

Return(_lRet)

// ** funcao que retorna a composicao do palete
Static Function sfRetCompPlt(mvIdPalete, mvEndOrig)
	// variavel de retorno
	local _aRet := {}
	// query
	local _cQuery

	// campos da query
	If (_cTipoTf == "01")
		_cQuery := " SELECT SUM(Z16_SALDO) Z16_SALDO, Z16_CODPRO, B1_DESC, Z16_LOTCTL, Z16_VLDLOT, Z16_DTSERI, '.F.' IT_DEL "
	Else
		_cQuery := " SELECT SUM(Z16_SALDO) Z16_SALDO, Z16_CODPRO, B1_DESC, Z16_LOTCTL, Z16_VLDLOT, Z16_DTSERI, Z16_ETQVOL, Z16_ETQPRD, '.F.' IT_DEL "
	EndIf
	// composicao do palete
	_cQuery += " FROM " + RetSqlTab("Z16")
	// cad. de produtos
	_cQuery += " INNER JOIN " + RetSqlTab("SB1") + " ON " + RetSqlCond("SB1") + " AND B1_COD = Z16_CODPRO AND B1_GRUPO = '" + _cCliSigla + "' "
	// saldo no endereco
	_cQuery += " INNER JOIN " + RetSqlTab("SBF") + " ON "+RetSqlCond("SBF") + " AND BF_PRODUTO = Z16_CODPRO AND Z16_LOCAL = BF_LOCAL AND Z16_ENDATU = BF_LOCALIZ AND Z16_LOTCTL = BF_LOTECTL "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z16")
	// filtra ID Palete
	_cQuery += " AND Z16_ETQPAL = '" + mvIdPalete + "' "
	// endereco
	_cQuery += " AND Z16_ENDATU = '" + mvEndOrig + "' "
	// somente se tiver saldo
	_cQuery += " AND Z16_SALDO > 0 "
	// valida se o produto pertence ao cliente
	_cQuery += " AND SUBSTRING(Z16_CODPRO,1,4) = '" + _cCliSigla + "' "

	// se for transferência de volume/produto, seleciona apenas a etiqueta bipada
	If (_cTipoTf == "02")
		_cQuery += " AND (Z16_ETQPRD = '" + _cIdEtiqProd + "' OR  Z16_ETQVOL = '" + _cIdEtiqProd + "')"
	EndIf
	// se for dados resumidos
	If (_cTipoTf == "01")
		_cQuery += " GROUP BY Z16_CODPRO, B1_DESC, Z16_LOTCTL, Z16_VLDLOT, Z16_DTSERI "
	Else	
		_cQuery += " GROUP BY Z16_CODPRO, B1_DESC, Z16_LOTCTL, Z16_VLDLOT, Z16_ETQVOL, Z16_ETQPRD, Z16_DTSERI "
	EndIf

	memowrit("C:\query\twmsa033_sfRetCompPlt.txt", _cQuery)

	// atualiza variavel de retorno
	_aRet := U_SqlToVet(_cQuery,{"Z16_VLDLOT", "Z16_DTSERI"})

Return(_aRet)

// ** funcao que confirma o movimento de distribuicao
Static Function sfGrvEndDest()

	// variavel de retorno
	Local _lRet := .F.

	// se abre a transação, utiliza o BEGIN pra garantir a integridade dos dados
	BeginTran()

	// mostra informação de processando para o usuário
	MsgRun("Gravando dados...", "Aguarde...", {|| _lRet := sfProcEndDest() })

	// caso tenha dado qualquer erro, rollback na transação
	If ( ! _lRet)
		// rollback
		DisarmTransaction()
	EndIf

	// commita a transação
	EndTran()

Return(_lRet)

// ** funcao que realiza a gravacao da transferencia de endereco
Static Function sfProcEndDest()

	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z05","Z06","Z07","Z08"})
	// variavel retorno
	Local _lRet := .T.

	// variaveis temporarias
	local _aAreaZ06, _aAreaSBE

	// itens para movimentacao da transferencia
	local _aItemSD3
	local _aTmpItem

	// produtos do palete
	local _aProdPlt := {}
	local _nProd := 0

	// comandos SQL temporárias temporarias
	local _cQuery  := ""
	local _cUpdZ16 := ""
	local _aRetQry := {}

	// ID do novo palete (id do palete atual - endereco de destino ocupado)
	local _cPltEndDes := ""
	local _cUnitPdr := SuperGetMV('TC_PLTPADR',.F.,"000001")

	// recno do mapa (Z08) para atualizacao de novo palete, nos casos de agrupamento
	local _aRecnoZ08 := {}
	local _nRecZ08

	// novo pallet gerado caso endereço esteja vazio
	local _cNewPlt := ""

	// variavel utilizada nas funcoes automaticas
	private lMsErroAuto := .F.

	// realiza o movimento de distribuicao
	If (_lRet)

		// area atual
		_aAreaZ06 := Z06->(GetArea())
		_aAreaSBE := SBE->(GetArea())

		// verifica se deve movimentar mercadoria / estoque
		If (Z06->Z06_ATUEST == "S")

			BEGIN TRANSACTION

				// retorna os produtos que compoe o palete
				// 1-Quantidade
				// 2-Cod Produto
				// 3-Descricao
				// 4-Lote
				// 5-Validade do Lote
				// 6-Data número série
				// 7-Etq de volume
				// 8-Etq de produto
				// 9-Controle DELETE
				_aProdPlt := sfRetCompPlt(_cIdPalete, _cEndOrige)
				
				// se retornou mais de um pallet
				If (Len(_aProdPlt) <= 0)
					// rollback na transacao
					DisarmTransaction()
					_lRet := .F.
					U_FtWmsMsg("Palete de origem não encontrado." + CRLF + CRLF + TCSQLError(),"ATENCAO")
					Break
				EndIf

				// chama o grupo de perguntas padrao da rotina MATA260
				pergunte("MTA260",.F.)

				// define o parametro "Considera Saldo poder de 3" como NAO
				mv_par03 := 2

				// zera variaveis
				_aItemSD3 := {}
				_aTmpItem := {}

				// cabecalho
				_aItemSD3 := {{NextNumero("SD3",2,"D3_DOC",.T.),dDataBase}}

				// varre todos os produtos do palete
				For _nProd := 1 to Len(_aProdPlt)

					// reinicia variaveis
					_aTmpItem := {}

					// posiciona no cadastro de produtos
					dbSelectArea("SB1")
					SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
					SB1->(dbSeek( xFilial("SB1")+_aProdPlt[_nProd][2] ))

					// Atualiza arquivo de saldos em estoque
					dbSelectArea("SB2")
					SB2->(DbSetOrder(1)) // 1-B2_FILIAL, B2_COD, B2_LOCAL
					If ! SB2->(dbSeek( xFilial("SB2") + SB1->B1_COD + _cArmzDesti ))
						// cria saldo no armazem de destino
						CriaSB2(SB1->B1_COD, _cArmzDesti)
					EndIf

					// itens para movimentacao de transferencia
					// ** origem
					aAdd(_aTmpItem, _aProdPlt[_nProd][2] ) // D3_COD
					aAdd(_aTmpItem, SB1->B1_DESC         ) // D3_DESCRI
					aAdd(_aTmpItem, SB1->B1_UM           ) // D3_UM
					aAdd(_aTmpItem, _cArmzOrige          ) // D3_LOCAL
					aAdd(_aTmpItem, _cEndOrige           ) // D3_LOCALIZ
					// destino
					aAdd(_aTmpItem, _aProdPlt[_nProd][2] ) // D3_COD
					aAdd(_aTmpItem, SB1->B1_DESC         ) // D3_DESCRI
					aAdd(_aTmpItem, SB1->B1_UM           ) // D3_UM
					aAdd(_aTmpItem, _cArmzDesti          ) // D3_LOCAL
					aAdd(_aTmpItem, _cEndDesti           ) // D3_LOCALIZ
					aAdd(_aTmpItem, CriaVar("D3_NUMSERI")) // D3_NUMSERI
					aAdd(_aTmpItem, _aProdPlt[1][4]      ) // D3_LOTECTL
					aAdd(_aTmpItem, CriaVar("D3_NUMLOTE")) // D3_NUMLOTE
					aAdd(_aTmpItem, _aProdPlt[1][5]      ) // D3_DTVALID
					aAdd(_aTmpItem, 0                    ) // D3_POTENCI
					aAdd(_aTmpItem, _aProdPlt[_nProd][1] ) // D3_QUANT
					aAdd(_aTmpItem, 0                    ) // D3_QTSEGUM
					aAdd(_aTmpItem, CriaVar("D3_ESTORNO")) // D3_ESTORNO
					aAdd(_aTmpItem, CriaVar("D3_NUMSEQ") ) // D3_NUMSEQ
					aAdd(_aTmpItem, _aProdPlt[1][4]      ) // D3_LOTECTL
					aAdd(_aTmpItem, _aProdPlt[1][5]      ) // D3_DTVALID
					aAdd(_aTmpItem, CriaVar("D3_SERVIC") ) // D3_SERVIC
					aAdd(_aTmpItem, CriaVar("D3_ITEMGRD")) // D3_ITEMGRD
					aAdd(_aTmpItem, CriaVar("D3_IDDCF")  ) // D3_IDDCF
					aAdd(_aTmpItem, CriaVar("D3_OBSERVA")) // D3_OBSERVA
					aAdd(_aTmpItem, _cNumOrdSrv          ) // D3_ZNUMOS
					aAdd(_aTmpItem, _cSeqOrdSrv          ) // D3_ZSEQOS
					aAdd(_aTmpItem, _cIdPalete           ) // D3_ZETQPLT
					aAdd(_aTmpItem, ""                   ) // D3_ZCARGA
					aAdd(_aTmpItem, ""                   ) // D3_ZPEDIDO
					aAdd(_aTmpItem, ""                   ) // D3_ZITPEDI

					// adiciona o item
					aAdd(_aItemSD3, _aTmpItem)

				Next _nProd

				// prepara variaveis para funcao automatica
				lMsErroAuto := .F.

				// executa rotina automatica
				MsExecAuto({|x,y| MATA261(x,y) },_aItemSD3,3) // 3-transferencia

				// restaura area atual
				RestArea(_aAreaZ06)
				RestArea(_aAreaSBE)

				// se deu erro na atualizacao
				If (lMsErroAuto)
					// apresenta mensagem com o error.log
					U_FtWmsMsg(U_FtAchaErro(), "ATENCAO")
					// variavel de retorno
					_lRet := .F.
				EndIf

				// gera registro de movimentacao no mapa
				If (_lRet)

					// varre todos os produtos do palete
					For _nProd := 1 to Len(_aProdPlt)

						dbSelectArea("Z08")
						RecLock("Z08",.T.)
						Z08->Z08_FILIAL := xFilial("Z08")
						Z08->Z08_NUMOS  := _cNumOrdSrv
						Z08->Z08_SEQOS	:= _cSeqOrdSrv
						Z08->Z08_LOCAL  := _cArmzOrige
						Z08->Z08_SERVIC := Z06->Z06_SERVIC
						Z08->Z08_TAREFA := Z06->Z06_TAREFA
						Z08->Z08_ENDSRV := _cEndOrige
						Z08->Z08_ENDORI := _cEndOrige
						Z08->Z08_ENDTRA := ""
						Z08->Z08_ENDDES := _cEndDesti
						Z08->Z08_DTEMIS := Z06->Z06_DTEMIS
						Z08->Z08_HREMIS := Z06->Z06_HREMIS
						Z08->Z08_DTINIC := _dDataIni
						Z08->Z08_HRINIC := _cHoraIni
						Z08->Z08_DTFINA := Date()
						Z08->Z08_HRFINA := Time()
						Z08->Z08_STATUS := "R" // P-Planejado / R-Realizado / M-Movimento / E-Erro
						Z08->Z08_PALLET := _cIdPalete
						Z08->Z08_USUARI := _cCodOper
						Z08->Z08_EQUIPA := _cCodEquip
						Z08->Z08_PRODUT := _aProdPlt[_nProd][2]
						Z08->Z08_QUANT  := _aProdPlt[_nProd][1]
						Z08->Z08_PRIOR  := "99"
						Z08->Z08_FRAPLT	:= "N"
						Z08->Z08_NUMSEQ	:= ""
						Z08->Z08_TPOPER := Z05->Z05_TPOPER
						Z08->Z08_SEQUEN := ""
						Z08->Z08_SEQKIT := ""
						Z08->Z08_LOCDES := _cArmzDesti
						Z08->Z08_LOTCTL := _aProdPlt[_nProd][4]
						Z08->Z08_VLDLOT := _aProdPlt[_nProd][5]
						Z08->(MsUnLock())

						// guarda Z08
						aAdd(_aRecnoZ08, Z08->( RecNo() ) )

					Next _nProd

					// gera registro de movimentacao
					dbSelectArea("Z17")
					RecLock("Z17",.T.)
					Z17->Z17_FILIAL	:= xFilial("Z17")
					Z17->Z17_ETQPLT := _cIdPalete
					Z17->Z17_ENDORI	:= _cEndOrige
					Z17->Z17_ENDDES := _cEndDesti
					Z17->Z17_DTINI	:= _dDataIni
					Z17->Z17_HRINI	:= _cHoraIni
					Z17->Z17_DTFIM  := Date()
					Z17->Z17_HRFIM  := Time()
					Z17->Z17_OPERAD	:= _cCodOper
					Z17->Z17_EQUIPA	:= _cCodEquip
					Z17->Z17_NUMOS	:= _cNumOrdSrv
					Z17->Z17_SEQOS	:= _cSeqOrdSrv
					Z17->Z17_STATUS := "R"  // R=Realizado / C=Cancelado / M=Em Movimento
					Z17->Z17_TIPLAN := "NM" // NM=Normal / ES=Estorno / AJ=Ajuste / DV=Devolução / FR=Fracionamento / DF=Dev. Fracion.
					Z17->Z17_ROTORI := "TWMSA033"
					Z17->Z17_ORILAN := "M"  // A=Automática / M=Manual
					Z17->Z17_LOCORI := _cArmzOrige
					Z17->Z17_LOCDES := _cArmzDesti
					Z17->Z17_TIPMOV := _cTipoTf
					Z17->Z17_ESTORN := "N"
					Z17->(MsUnLock())

					// atualiza a Z16-Composicao do Palete
					If (_cTipoTf == "01") // atualiza o pallet inteiro, pois movimentou ele inteiro
						U_FtEndPlt(_cIdPalete, _cEndOrige, _cEndDesti, _cArmzOrige, Nil, Nil, _cArmzDesti)
					Elseif (_cTipoTf == "02")  // atualiza apenas o volume bipado
						// busca numeração do pallet destino para atualizar no volume
						_cQuery  := " SELECT DISTINCT Z16_ETQPAL FROM " + RetSqlTab("Z16") + " WHERE " + RetSqlCond("Z16") + " AND Z16_ENDATU = '" + _cEndDesti + "' AND Z16_SALDO > 0 AND Z16_LOCAL = '" + _cArmzDesti + "'"
						_aRetQry := U_SqlToVet(_cQuery)

						// se retornou mais de um pallet
						If (Len(_aRetQry) > 1)
							// rollback na transacao
							DisarmTransaction()
							_lRet := .F.
							U_FtWmsMsg("*** ERRO NA ATUALIZACAO DO ENDEREÇO DO VOLUME (2) ***"+CRLF+CRLF+TCSQLError(),"ATENCAO")
							Break
						EndIf

						// se não encontrou nada, endereço está vazio
						If (Len(_aRetQry) == 0)
							// cria nova etiqueta de pallet
							// funcao generica para geracao do Id Palete
							_cNewPlt := U_FtGrvEtq("03",{_cUnitPdr,""})
						EndIf

						// atualiza registro do volume
						_cUpdZ16 := "UPDATE " + RetSqlName("Z16") + " SET Z16_ENDATU = '" + _cEndDesti + "', Z16_LOCAL = '" + _cArmzDesti + "', Z16_ETQPAL = '" + IIf(Empty(_cNewPlt), _aRetQry[1], _cNewPlt) + "'"
						_cUpdZ16 += " WHERE Z16_FILIAL = '" + xFilial("Z16") + "' AND D_E_L_E_T_ = '' "
						_cUpdZ16 += " AND Z16_CODPRO = '" + _aProdPlt[1][2] +  "' 
						_cUpdZ16 += " AND Z16_ETQVOL = '" + _aProdPlt[1][7] +  "' 
						_cUpdZ16 += " AND Z16_ETQPRD = '" + _aProdPlt[1][8] +  "' 
						_cUpdZ16 += " AND Z16_ENDATU = '" + _cEndOrige +  "' 
						_cUpdZ16 += " AND Z16_ETQPAL = '" + _cIdPalete +  "' 
						_cUpdZ16 += " AND Z16_LOCAL  = '" + _cArmzOrige +  "' 

						// log para debug
						MemoWrit("c:\query\TWMSA033_updZ16.txt", _cUpdZ16)

						// executa o update
						If (TcSQLExec(_cUpdZ16) < 0)
							// rollback na transacao
							DisarmTransaction()
							_lRet := .F.
							U_FtWmsMsg("*** ERRO NA ATUALIZACAO DO ENDEREÇO DO VOLUME (2) ***"+CRLF+CRLF+TCSQLError(),"ATENCAO")
							Break
						EndIf


					EndIf

					// se o endereco de destino estava ocupado no inicio da operacao, agrupa os paletes
					If (_lRet) .And. (_lEndDestOcup) .AND. !(_cTipoTf == "02")

						// agrupa Id palete
						If ( ! U_FtAgrPlt(_cArmzDesti, _cEndDesti, _cIdPalete, Z08->Z08_PRODUT, @_cPltEndDes, @_aRegLock) )
							// mensagem
							U_FtWmsMsg("Ocorreu um erro ao realizar o agrupamento da composição do palete! A operação não pode ser realizada!")
							// variavel de controle
							_lRet := .F.
						EndIf

						// agrupa etiquetas do palete
						If (_lRet)
							// funcao generica que agrupa etiquetas repetidas no palete
							U_FtAgrEtq(_cArmzDesti, _cEndDesti, _cPltEndDes)
						EndIf

						// atualiza novo palete (agrupado) no mapa de movimentacoes
						If (_lRet)

							// varre todos os registros do mapa gerado
							For _nRecZ08 := 1 to Len(_aRecnoZ08)

								// posiciono no registro
								dbSelectArea("Z08")
								Z08->( DbGoTo(_aRecnoZ08[_nRecZ08] ) )

								// atualiza campos
								RecLock("Z08", .F.)
								Z08->Z08_NEWPLT := _cPltEndDes
								Z08->(MsUnLock())

							Next _nRecZ08

						EndIf

					EndIf
				EndIf

			END TRANSACTION

			// funcao padrao da TOTVS que libera todos os registros com LOCK do SofLock
			LibLock(_aRegLock)

			// libera todos os registros
			MsUnLockAll()

			// caso foi movido para endereço em branco, avisa usuario que foi gerado um novo pallet
			If !Empty(_cNewPlt)
				U_FtWmsMsg("Novo ID de pallet gerado " + _cNewPlt + ".","Endereço vazio!")
			EndIf
		EndIf

	Else
		// TODO - implementar ação caso não atualize estoque
	EndIf



	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aArea)

Return(_lRet)

// ** funcao para finalizar a ordem de servico
Static Function sfFinalizaOS(mvTela, mvFixaWnd, mvOk)

	// confirmacao do processamento
	If ( ! MsgYesNo("Finalizar Ordem de Serviço?", "Finalizar"))
		Return(.F.)
	EndIf

	// atualiza o status do servico para FI-FINALIZADO
	U_FtWmsSta(;
	_cCodStatus,;
	"FI"       ,;
	_cNumOrdSrv,;
	_cSeqOrdSrv )

	// fecha a tela
	mvFixaWnd := .T.
	mvOk      := .F.
	mvTela:End()

Return(mvOk)

// ** funcao que valida se a ordem de servico esta ativa
Static Function sfVldOSEnc()
	// variavel de retorno
	local _lRet := .T.
	// query
	local _cQuery

	// prepara query
	_cQuery := " SELECT Z06_STATUS "
	_cQuery += " FROM   "+RetSqlTab("Z06")
	_cQuery += " WHERE  "+RetSqlCond("Z06")
	_cQuery += "        AND Z06_NUMOS = '"+_cNumOrdSrv+"' "
	_cQuery += "        AND Z06_SEQOS = '"+_cSeqOrdSrv+"' "

	// valida status
	_lRet := (U_FtQuery(_cQuery) == "EX")

	If ( ! _lRet )
		// mensagem
		U_FtWmsMsg("Ordem de Serviço Finalizada ou Bloqueada! A operação não pode ser realizada!")
	EndIf

Return(_lRet)

// ** funcao que muda o status de permissao para agrupar palete em enderecos ja ocupados
Static Function sfCfgAgrpPlt()
	// mensagem
	local _cMensag := "Permite movimentos para endereços ocupados: " + IIf(_lAgrPltEnd, "ATIVADO", "DESATIVADO") + CRLF + CRLF + "Deseja " + IIf(_lAgrPltEnd, "DESATIVAR", "ATIVAR") + "?"

	// apresenta mensagem
	If ( U_FtYesNoMsg(_cMensag) )
		// atualiza parametro de controle
		_lAgrPltEnd := ( ! _lAgrPltEnd )
		// gera log
		U_FtGeraLog(xFilial("Z06"), "Z06", xFilial("Z06") + _cNumOrdSrv + _cSeqOrdSrv, "Usuário " + IIf(_lAgrPltEnd, "ATIVOU", "DESATIVOU") + " opção que permite movimentos para endereços ocupados.", "WMS", "")
	EndIf

Return( Nil )