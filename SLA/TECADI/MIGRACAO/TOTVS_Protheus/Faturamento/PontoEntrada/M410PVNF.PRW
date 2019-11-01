#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado no botao Prep. Doc. Saida   !
!                  ! na rotina de Pedidos de Venda                           !
!                  ! 1. Verificar a permissao do usuario para emitir notas   !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 08/2011 !
+------------------+--------------------------------------------------------*/

User Function M410PVNF

	// Area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSC5 := SC5->(GetArea())

	// variavel de retorno
	local _lRet := .T.

	// variáveis de controle via parâmetro (tabela Z30)
	local _lLibSemNF, _lLibSemPedCli, _lWmsAtivo, _lMapaLib, _lEhTFAA
	
	// query SQL
	local _cQuery := ""

	// valida se o usuario pode utilizar este rotina
	If (cModulo == "WMS") .And. ( ! (__cUserId $ AllTrim(SuperGetMv("TC_USRNFS", .F., ""))) )
		// mensagem para usuario
		Aviso("Tecadi: M410PVNF","Usuário sem permissão para utilizar esta rotina.",{"OK"})
		// variavel de retorno
		_lRet := .F.
	EndIf

	// atualiza variaveis de controle de WMS
	If (_lRet) .And. (cEmpAnt == "01") .And. (SC5->C5_TIPOOPE == "P")
		// verifica se o WMS esta ativo
		_lWmsAtivo := U_FtWmsParam("WMS_ATIVO_POR_CLIENTE","L",.F.,.F., Nil, SC5->C5_CLIENTE, SC5->C5_LOJACLI, Nil, Nil)
		// permite o carregamento sem a nota fiscal de venda do cliente
		_lLibSemNF := U_FtWmsParam("WMS_LIBERA_CARREGAMENTO_SEM_NF_VENDA","L",.F.,.F.,Nil, SC5->C5_CLIENTE, SC5->C5_LOJACLI, Nil, Nil)
		// libera o carregamento/faturamento logo após geração do mapa de expedição
		_lMapaLib  := U_FtWmsParam("WMS_EXPEDICAO_LIBERA_EMISSAO_NF","L",.F.,.F.,Nil, SC5->C5_CLIENTE, SC5->C5_LOJACLI, Nil, Nil)
		// permite o carregamento sem o pedido do cliente informado
		_lLibSemPedCli := U_FtWmsParam("WMS_LIBERA_CARREGAMENTO_SEM_PEDIDO_CLIENTE","L",.T.,.F.,Nil, SC5->C5_CLIENTE, SC5->C5_LOJACLI, Nil, Nil)
	EndIf

	// query para verificar se o pedido é proveniente de devolução de TFAA (apenas tecadi armazéns)
	IF (_lRet) .And. (cEmpAnt == "01")
		_cQuery	 := "SELECT COUNT(Z05_NUMOS) QTD FROM " + RetSqlTab("Z05") + " WHERE " + RetSqlCond("Z05") + " AND Z05_PVTFAA = '" + SC5->C5_NUM + "'"
		// variável que informa se é um pedido de devolução TFAA (sobra de mercadoria)
		_lEhTFAA := (U_FtQuery(_cQuery) > 0)
	EndIf

	// verifica se já foi informada e criada carga antes de permitir o faturamento (chamado 17217 / redmine 355)
	If (_lRet) .And. (cEmpAnt == "01") .And. (SC5->C5_TIPOOPE == "P") .AND. (Empty(SC5->C5_ZCARGA)) .And. (_lWmsAtivo) .AND. (!_lMapaLib) .AND. (SC5->C5_CLIENTE != "000436") .AND. (!_lEhTFAA)
		Aviso("Tecadi: M410PVNF","Cliente com WMS ativo e sem carga informada/montada. Verifique processo de montagem de carga.",{"OK"})
		_lRet := .f.
	EndIf 

	// para pedidos de mercadoria armazenada, verifica se ha carga montada para este pedido de venda
	If (_lRet) .And. (cEmpAnt == "01") .And. (SC5->C5_TIPOOPE == "P") .And. (OmsHasCg(SC5->C5_NUM)) 

		// valida se ha mais pedidos da mesma agrupadora do cliente
		If ( ! Empty(SC5->C5_ZAGRUPA) ) .AND. (SC5->C5_CLIENTE != "000603")

			// fazer um Select para saber quantos pedidos tem com esta Agrupadora.
			_cQuery := "SELECT COUNT(*) QTD_REG "
			// pedido de venda
			_cQuery += "FROM "+RetSqlName("SC5")+" SC5 "
			// filtro padrao
			_cQuery += "WHERE "+RetSqlCond("SC5")+" "
			// codigo e loja do cliente
			_cQuery += "AND C5_CLIENTE = '" + SC5->C5_CLIENTE + "' AND C5_LOJACLI = '" + SC5->C5_LOJACLI + "' "
			// agrupadora
			_cQuery += "AND C5_ZAGRUPA = '" + SC5->C5_ZAGRUPA + "' "
			// tipo do pedido
			_cQuery += "AND C5_TIPOOPE = 'P' "

			// se tiver mais de um pedido para a mesma agrupadora
			If (U_FtQuery(_cQuery) > 1)
				Aviso("Tecadi: M410PVNF","Agrupadora com mais de um pedido. Faturamento permitido apenas pela Rotina de Carga.",{"OK"})
				_lRet := .f.
			EndIf
		EndIf
	Endif

	// valida se cliente tem parâmetro de bloqueio e se a nota fiscal de venda final do cliente está preenchida no pedido de venda
	If (_lRet) .And. (cEmpAnt == "01") .And. (SC5->C5_TIPOOPE == "P") .And. (_lWmsAtivo) .And. ( ! _lLibSemNF ) .And. (Empty(SC5->C5_ZDOCCLI)) .AND. (!_lEhTFAA)
		// mensagem para usuario
		Help( Nil, Nil, 'PE M410PVNF Faturamento sem documento do cliente',;
		Nil,;
		"O pedido Tecadi " + SC5->C5_NUM + " está sem documento do cliente informado. Este cliente está configurado para exigir esta informação.";
		+ CRLF + CRLF;
		+ "Informe/importe os dados necessários e repita o processo", 1, 0 )
		// variavel de retorno
		_lRet := .F.
	Endif
	
	// valida se cliente tem parâmetro de bloqueio e se a nota fiscal de venda final do cliente está preenchida no pedido de venda
	If (_lRet) .And. (cEmpAnt == "01") .And. (SC5->C5_TIPOOPE == "P") .And. (_lWmsAtivo) .And. ( ! _lLibSemPedCli ) .And. ( Empty(SC5->C5_ZPEDCLI) )
		// mensagem para usuario
		Help( Nil, Nil, 'PE M410PVNF Faturamento sem pedido do cliente',;
		Nil,;
		"O pedido Tecadi " + SC5->C5_NUM + " está sem o número do pedido de venda do cliente final informado. Este cliente está configurado para exigir esta informação.";
		+ CRLF + CRLF;
		+ "Informe/importe os dados necessários e repita o processo", 1, 0 )
		// variavel de retorno
		_lRet := .F.
	Endif

	// valida se o pedido de venda esta apto para faturamento (itens do pedido x itens liberado)
	If (_lRet) .And. (cEmpAnt == "01")

		// funcao para validacao de pedidos aptos a faturar
		_lRet := U_FtFatVld( .T., SC5->C5_TIPOOPE, SC5->C5_NUM, SC5->C5_NUM, SC5->C5_CLIENTE, SC5->C5_CLIENTE, SC5->C5_LOJACLI, SC5->C5_LOJACLI, SC5->C5_EMISSAO, SC5->C5_EMISSAO, Nil, Nil, Nil, Nil)

	EndIf

	// restaura area inicial
	RestArea(_aAreaSC5)
	RestArea(_aAreaAtu)

Return(_lRet)