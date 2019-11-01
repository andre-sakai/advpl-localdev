#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada para Validação de inclusão ou          !
!                  ! alteração do Produto.                                   !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe                      ! Data de Criacao ! 04/2015 !
+------------------+--------------------------------------------------------*/

User Function A010TOK()

	// Area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSB2 := SB2->(GetArea())
	local _aAreaSA1 := SA1->(GetArea())
	local _aAreaSB1 := SB1->(GetArea())
	local _aAreaZ32 := Z32->(GetArea())

	// Variavel de retorno
	Local _lRet := .t.

	//Saldo do Produto
	Local _nSaldo := 0

	// valida se o WMS esta ativo por cliente
	Local _lWmsAtivo := .f.

	// variavel usuarios com permissão total
	Local _cUsuario := Alltrim(SuperGetMv("TC_USRALTP", .F., "000000"))

	// seek
	local _cSeekSB2
	local _lSeekZ32

	// controle de uso de grupo de estoque ativo
	local _lUsoGrpEst := .f.

	// consulta saldo SB2
	local _cQrySldSB2 := ""

	// log de gravação
	local _cLogMsg := ""

	// verifica se o controle de lote esta ativo por cliente
	local _lLotAtivo := .f.

	// query
	local _cQuery

	// dados do cadastro
	local _aTmpDados

	// se for chamado através da rotina de importação de XML, então está utilizando o cadastro de produtos (tabela SB1) em formato MVC e não precisa validar no formato antigo
	IF (IsInCallStack("SFADDPROD")) 
		Return ( .T. )
	Endif

	// -------------- INICIO solução temporária para chamado 14818 - luiz poleza
	// ao chamar este ponto de entrada na versão 12, o ponteiro da tabela SB1 não está posicionado no produto
	// segundo a Totvs, através do chamado 1751041 , isto se deve ao fato deste ponto de entrada ter sido alterado
	// para padrão MVC na versão 12, sendo necessário reescrever o ponto de entrada
	// ---
	// sendo assim, a solução paliativa é posicionar novamente de acordo com o código do produto em memória M->B1_COD
	// até que a rotina seja refeita

	If (Altera)
		dbSelectArea("SB1")
		SB1->( dbSetOrder(1) )     // B1_FILIAL, B1_COD, R_E_C_N_O_, D_E_L_E_T_
		SB1->( dbSeek( xFilial("SB1") + M->B1_COD ))
	EndIf
	// -------------- FIM SOLUÇÃO TEMPORÁRIA CHAMADO TECADI 14818 / CHAMADO TOTVS 1751041

	// somente 01-Armazens, valida somente na alteracao
	If (cEmpAnt == "01").and.(M->B1_ZTIPPRO == "A")

		// Pesquisa o cliente
		dbSelectArea("SA1")
		SA1->(dbOrderNickName("A1_SIGLA")) // A1_FILIAL+A1_SIGLA
		If ! SA1->(dbSeek( xFilial("SA1") + M->B1_GRUPO ))
			// mensagem de aviso
			Aviso("A010TOK","Cliente não relacionado ao produto!",{"Fechar"})
			// restaura area inicial
			RestArea(_aAreaSA1)
			RestArea(_aAreaSB2)
			RestArea(_aAreaSB1)
			RestArea(_aAreaAtu)
			RestArea(_aAreaZ32)
			// retorno
			Return(.f.)
		EndIf

		// controle de uso de grupo de estoque ativo
		_lUsoGrpEst := U_FtWmsParam("WMS_USA_GRUPO_ESTOQUE", "L", .f., .f., Nil, SA1->A1_COD, SA1->A1_LOJA, Nil, Nil)

		// verifica se o WMS esta ativo
		_lWmsAtivo  := U_FtWmsParam("WMS_ATIVO_POR_CLIENTE", "L", .f., .f., Nil, SA1->A1_COD, SA1->A1_LOJA, Nil, Nil)

		// verifica se o controle de lote esta ativo por cliente
		_lLotAtivo := U_FtWmsParam("WMS_CONTROLE_POR_LOTE", "L", .F., .F., Nil, SA1->A1_COD, SA1->A1_LOJA, Nil, Nil)

		// verifica se cliente ativo para utilizar segunda unidade de medida
		_lUsa2UM   := U_FtWmsParam("WMS_PRODUTO_USA_SEGUNDA_UNIDADE_MEDIDA", "L", .F. , .F., Nil, SA1->A1_COD, SA1->A1_LOJA, Nil, Nil)

		// valida informacoes
		If (_lUsoGrpEst).and.(Empty(M->B1_ZGRPEST))
			// mensagem de aviso
			Aviso("A010TOK","Obrigatório informar o Grupo de Estoque.",{"Fechar"})
			// restaura area inicial
			RestArea(_aAreaSA1)
			RestArea(_aAreaSB2)
			RestArea(_aAreaSB1)
			RestArea(_aAreaAtu)
			RestArea(_aAreaZ32)
			Return(.f.)
		EndIf

		// valida informacoes do enderecamento de mercadorias
		If (_lWmsAtivo).and.(M->B1_LOCALIZ != "S").and.(AllTrim(FunName()) == "MATA010")
			// mensagem de aviso
			Aviso("A010TOK","Cliente com WMS Ativo. Favor definir controle de endereço como SIM.",{"Fechar"})
			// restaura area inicial
			RestArea(_aAreaSA1)
			RestArea(_aAreaSB1)
			RestArea(_aAreaSB2)
			RestArea(_aAreaAtu)
			RestArea(_aAreaZ32)
			// retorno
			Return(.f.)
		EndIf

		// valida informacoes do controle por lote
		If (_lLotAtivo).and.(M->B1_RASTRO != "L").and.(AllTrim(FunName()) == "MATA010")
			// mensagem de aviso
			Aviso("A010TOK","Cliente com WMS Ativo. Favor definir controle de LOTE como SIM.",{"Fechar"})
			// restaura area inicial
			RestArea(_aAreaSA1)
			RestArea(_aAreaSB1)
			RestArea(_aAreaSB2)
			RestArea(_aAreaAtu)
			RestArea(_aAreaZ32)
			// retorno
			Return(.f.)
		EndIf

		//valida se já possui cadastro de código de barras na tabela de cadastro SKU
		dbSelectArea("Z32")
		Z32->( dbSetOrder(1) )     // Z32_FILIAL, Z32_CODPRO, Z32_ORDEM, R_E_C_N_O_, D_E_L_E_T_
		_lSeekZ32 := Z32->( dbSeek( xFilial("Z32") + M->B1_COD ))

		If (( !Empty(M->B1_ZTPBAR) ) .OR. ( !Empty(M->B1_CODBAR) )) .AND. (_lSeekZ32) .AND. (_lWmsAtivo)
			// mensagem de aviso
			Aviso("A010TOK",;
			+ "O produto " + M->B1_COD + " já possui códigos de barras cadastrados na rotina CADASTRO DE SKU." + CRLF; 
			+ "Para evitar duplicidade ou conflitolimpe os campos 'código de barras' e 'tipo do código de barras'.";
			,{"Fechar"})

			// restaura area inicial
			RestArea(_aAreaSA1)
			RestArea(_aAreaSB2)
			RestArea(_aAreaSB1)
			RestArea(_aAreaAtu)
			RestArea(_aAreaZ32)
			// retorno
			Return( .F. )
		EndIf

		// não permite alterar a unidade de medida caso já esteja cadastrada
		If (Altera)
			// se a unidade de medida em memória for diferente da já cadastrada
			If (M->B1_UM <> SB1->B1_UM)
				// valido se tem saldo na SB2 independente da filial
				_cQrySldSB2 := " SELECT SUM(B2_QATU) FROM "+RetSqlTab("SB2")+" WHERE B2_COD = '"+ SB1->B1_COD + "' AND D_E_L_E_T_ = '' "

				// valido se encontrou saldo
				If ( U_FtQuery(_cQrySldSB2) > 0 )
					// informa o usuário
					MsgStop("Não é permitido alterar a unidade de medida de produtos que possuem saldo!")
					// retorno da função
					Return(.F.)
				Else
					// log
					_cLogMsg := "A010TOK ->Usuário: "+__cUserId+"-"+UsrRetName(__cUserId)+" "
					_cLogMsg += "alterou Unidade de Medida do produto "+ALLTRIM(SB1->B1_COD)+" de: "+SB1->B1_UM+" -> para: "+M->B1_UM+". "
					_cLogMsg += "Data: " + DTOS(Date()) + " "
					// gravo o log da alteração
					U_FtGeraLog(cFilAnt, "SB1", cFilAnt+SB1->B1_COD, _cLogMsg, "WMS", "")
				EndIf
			EndIf
			// se está alterando dados da 2ª UM
			If (M->B1_CONV <> SB1->B1_CONV) .OR. (M->B1_SEGUM <> SB1->B1_SEGUM) .OR. (M->B1_TIPCONV <> SB1->B1_TIPCONV)

				// se não usa 2ª UM, não deixa alterar
				If (!_lUsa2UM)
					// informa o usuário
					MsgStop("Cliente não configurado para utilizar 2ª U.M. . Não efetue alteração nos campos: fator de conversão, unidade da 2ª UM ou tipo de conversão.","Erro A010TOK")
					// retorno da função
					Return( .F. )
				EndIf  

				// valido se tem saldo na SB2 independente da filial
				_cQrySldSB2 := " SELECT SUM(B2_QATU) FROM "+RetSqlTab("SB2")+" WHERE B2_COD = '"+ SB1->B1_COD + "' AND D_E_L_E_T_ = '' "

				// valido se encontrou saldo
				If ( U_FtQuery(_cQrySldSB2) > 0 )
					// informa o usuário
					MsgStop("Não é permitido alterar o fator de conversão, unidade da 2ª UM ou tipo de conversão de produtos que possuem saldo!","Erro A010TOK")
					// retorno da função
					Return(.F.)
				Else
					// log
					_cLogMsg := "A010TOK ->Usuário: " + __cUserId + "-" + UsrRetName(__cUserId) + " "
					_cLogMsg += "alterou dados da 2ª UM do produto " + ALLTRIM(SB1->B1_COD) 
					_cLogMsg += " B1_CONV de: "    + AllTrim(Str(SB1->B1_CONV)) + " -> para: " + AllTrim(Str(M->B1_CONV)) + " / "
					_cLogMsg += " B1_SEGUM de: "   + SB1->B1_SEGUM   + " -> para: " + M->B1_SEGUM     + " / "
					_cLogMsg += " B1_TIPCONV de: " + SB1->B1_TIPCONV + " -> para: " + M->B1_TIPCONV   + "."

					// gravo o log da alteração
					U_FtGeraLog(cFilAnt, "SB1", cFilAnt+SB1->B1_COD, _cLogMsg, "WMS", "")
				EndIf
			EndIf
		EndIf

		// para alteracoes,
		If (Altera).and.(M->B1_DESC <> SB1->B1_DESC) .And. (!(__cUserId $ _cUsuario ))

			// valida clientes com WMS ativo, se ativo não permitir alteração.
			If (_lWmsAtivo).and.(AllTrim(FunName()) == "MATA010")
				Aviso("A010TOK","Clientes com WMS ativo. Alteração na descrição do produto não permitida!",{"Fechar"})
				// restaura area inicial
				RestArea(_aAreaSA1)
				RestArea(_aAreaSB2)
				RestArea(_aAreaSB1)
				RestArea(_aAreaAtu)
				RestArea(_aAreaZ32)
				Return(.f.)
			EndIf

			// consulta o saldo do produto
			dbSelectArea("SB2")
			SB2->(dbsetorder(1)) // 1-B2_FILIAL, B2_COD, B2_LOCAL
			SB2->(dbseek( _cSeekSB2 := xFilial("SB2") + M->B1_COD ))

			If (_lWmsAtivo)
				// varre todos os armazens
				While SB2->(!Eof()).and.(SB2->(B2_FILIAL+B2_COD) == _cSeekSB2)

					// Verifica saldo disponivel no estoque.(SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QACLASS - SB2->B2_QEMP)
					_nSaldo := SaldoSb2()

					//Verifica se tem saldo Disponivel.
					If (_nSaldo <> 0)
						Aviso("A010TOK","Alteração na descrição do produto não permitida !" + CRLF + "Produto já possui saldo.",{"Fechar"})
						// restaura area inicial
						RestArea(_aAreaSA1)
						RestArea(_aAreaSB2)
						RestArea(_aAreaSB1)
						RestArea(_aAreaAtu)
						RestArea(_aAreaZ32)
						Return(.f.)
					EndIf

					// proximo armazem
					SB2->(dbSkip())
				EndDo
			EndIf

		EndIf

		// para inclusoes / alteracoes, valida duplicidade do codigo de barras
		If ((Altera) .OR. (Inclui)) .AND. ( !Empty(M->B1_CODBAR) ) .AND. (_lWmsAtivo)

			// prepara query para validacao do codigo de barras
			_cQuery := " SELECT B1_COD "
			_cQuery += " FROM   " + RetSqlTab("SB1")
			_cQuery += " WHERE  " + RetSqlCond("SB1")
			_cQuery += "        AND B1_GRUPO = '" + M->B1_GRUPO + "' "
			_cQuery += "        AND B1_COD != '" + M->B1_COD + "' "
			_cQuery += "        AND B1_CODBAR = '" + M->B1_CODBAR + "' "

			// executa query
			_aTmpDados := U_SqlToVet(_cQuery)

			// executa query
			If (Len(_aTmpDados) != 0)
				// mensagem
				MsgStop("Código de Barras (Ean/Code128) já está em uso por outro produto/item!" + CRLF + "Produto (Cadastro): " + AllTrim(_aTmpDados[1]))
				// restaura area inicial
				RestArea(_aAreaSA1)
				RestArea(_aAreaSB2)
				RestArea(_aAreaSB1)
				RestArea(_aAreaAtu)
				RestArea(_aAreaZ32)
				// retorno
				Return(.f.)
			EndIf

			// prepara query para validacao do codigo de barras - Cad Sku
			_cQuery := " SELECT Z32_CODPRO "
			_cQuery += " FROM   " + RetSqlTab("Z32")
			_cQuery += " WHERE  " + RetSqlCond("Z32")
			_cQuery += "        AND SUBSTRING(Z32_CODPRO,1,4) = '" + M->B1_GRUPO + "' "
			_cQuery += "        AND Z32_CODBAR = '" + M->B1_CODBAR + "' "

			// executa query
			_aTmpDados := U_SqlToVet(_cQuery)

			// valida se tem produto duplicado
			If (Len(_aTmpDados) != 0)
				// mensagem
				MsgStop("Código de Barras (Ean/Code128) já está em uso por outro produto/item!" + CRLF + "Produto (Sku): " + AllTrim(_aTmpDados[1]))
				// variavel de retorno
				_lRet := .f.
			EndIf

		EndIf

	EndIf

	// restaura area inicial
	RestArea(_aAreaSA1)
	RestArea(_aAreaSB2)
	RestArea(_aAreaSB1)
	RestArea(_aAreaAtu)
	RestArea(_aAreaZ32)

Return(_lRet)