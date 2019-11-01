#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Gatilho para o produto do contrato                      !
+------------------+---------------------------------------------------------+
!Autor             ! Percio A. de Oliveira       ! Data de Criacao ! 12/2010 !
+------------------+--------------------------------------------------------*/

User Function TWMSG002(mvVisual)

	// variaveis de controle
	local _cAntProd
	local _cTpSrv

	// novos metodos para controle de modelo de cadastro com MVC
	local _oModelPad  := FwModelActive()
	local _oModelGrid := _oModelPad:GetModel("MdGridIAAN")

	// linha atual
	local _nLinAtu    := _oModelGrid:nLine

	// variaveis para uso na funcao
	//local _cItem     := _oModelGrid:GetValue('AAN_ITEM'  , _nLinAtu)
	local _cCodProd  := _oModelGrid:GetValue('AAN_CODPRO', _nLinAtu)
	local _cDscProd  := _oModelGrid:GetValue('AAN_ZDESCR', _nLinAtu)
	local _dDtUltPed := _oModelGrid:GetValue('AAN_ULTPED', _nLinAtu)

	// numero e item de contrato
	Private _cNrContrt := ""
	Private _cItContrt := ""

	// define somente visualizacao
	Default mvVisual := (AllTrim(FunName()) <> "TECA250")

	// verifica a permissao de alterar/incluir
	If ( ! mvVisual ) .and. ( ! Altera ) .and. ( ! Inclui )
		mvVisual := .t.
	EndIf

	// armazena numero e item do contrato
	_cNrContrt := M->AAM_CONTRT
	_cItContrt := _oModelGrid:GetValue('AAN_ITEM', _nLinAtu)

	// se for alteracao verifica duplicidade de itens
	If (Altera)
		// verifica se o produto/servico ja foi utilizado em outro item
		_cAntProd := Posicione("AAN", 1, xFilial("AAN") + _cNrContrt + _cItContrt, "AAN_CODPRO")
		// valida o codigo do produto/servico
		If (_cAntProd <> _cCodProd) .AND. ( ! Empty(_cAntProd) )
			// mensagem
			Alert("Nao e permitido alterar o produto de um item do contrato ja configurado. Deletar a linha e criar um novo item !!")
			// atualiza _aCols
			_oModelGrid:SetValue("AAN_CODPRO", _cAntProd)
			// retorno
			Return("")
		EndIf
	EndIf

	// posiciona no cadastro de produtos
	dbSelectArea("SB1")
	SB1->(dbSetOrder(1))
	SB1->(dbSeek(xFilial( "SB1" ) + _cCodProd))

	// extrai a descricao do servico
	_cDscProd := IIf(Empty(_cDscProd), SB1->B1_DESC, _cDscProd)
	_cTpSrv   := SB1->B1_TIPOSRV

	// atualiza data de emissao do pedido
	If (Empty(_dDtUltPed))
		_oModelGrid:LoadValue("AAN_ULTEMI", CtoD('//'))
	EndIf

	// atualiza inicio e fim de cobranca
	_oModelGrid:LoadValue("AAN_INICOB", M->AAM_INIVIG)
	_oModelGrid:LoadValue("AAN_FIMCOB", M->AAM_FIMVIG)

	// gatilho para Tipo de Armazenamento
	If (_cTpSrv <> "2")
		_oModelGrid:LoadValue("AAN_TIPOAR", "")
	EndIf

	//Gatilho para definir parametros de cada tipo de servico
	U_TWMSA003(_cTpSrv, 1, mvVisual, _oModelGrid)

Return(_cDscProd)

// Gatilho do Produto do Pacote Logistico
User Function WMSG002P(mvVisual)

	// variavel de retorno
	local _cRet := ""
	// variaveis de controle
	local _cTpSrv
	// posicao dos campos no header
	local _itCodPro

	// define somente visualizacao
	Default mvVisual := (AllTrim(FunName()) <> "TECA250")

	// verifica a posicao do campo no browse
	_itCodPro := aScan(_aHeadPrd,{|x| AllTrim(Upper(x[2]))=="ZU_PRODUTO"})

	// posiciona no cadastro de produtos
	dbSelectArea("SB1")
	dbSetOrder(1)
	dbSeek( xFilial("SB1") + oBrwPrd:aCols[oBrwPrd:nAt,_itCodPro] )

	_cRet := SB1->B1_DESC
	_cTpSrv := SB1->B1_TIPOSRV

	If (_cTpSrv == "7")
		U_TWMSA003(_cTpSrv, 2, mvVisual, Nil)
	EndIf

Return _cRet