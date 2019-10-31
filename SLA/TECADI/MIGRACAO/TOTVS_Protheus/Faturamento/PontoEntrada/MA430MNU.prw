#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada para adicionar botões a rotina de      !
!				   ! controle de reservas                                    !
+------------------+---------------------------------------------------------+
!Retorno           ! Array                                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 05/2016                                                 !
+------------------+---------------------------------------------------------+
!Autor             ! David Branco                                            !
+------------------+--------------------------------------------------------*/

User Function MA430MNU()

	// definição dos botões
	// importar XLS
	aadd(aRotina,{'Importar Pallets'                , 'MsgRun("Importando dados...",   "Aguarde...", {|| U_MA430IMP() })', 0, 1, 0, nil})
	// visualização de pallets importados
	aadd(aRotina,{'Visualizar Pallets'              , 'MsgRun("Selecionando dados...", "Aguarde...", {|| U_MA430VIS(SC0->C0_ZAGRUPA) })', 0, 1, 0, nil})
	// geração de OS
	aadd(aRotina,{'Gerar OS para Seleção de Pallets', 'U_MA430PLT()', 0, 1, 0, nil})

Return

// chama função para geração da OS
User Function MA430PLT ()

	// variavel de controle de transação
	local _lRet := .t.
	// seek na Z18
	local _cSeekSC0 := ""
	// obs
	local _cObs := ""

	// monto a observação da OS
	_cObs := "Dica: Use o botão ( ? ) para identificar os pallets que estão disponíveis para serem selecionados." + CRLF + CRLF

	// adicional da observação da OS
	_cObs := Iif ( Empty(SC0->C0_OBS), _cObs, SC0->C0_OBS)

	_lRet := MsgYesNo("Deseja gerar OS para Seleção de Pallets?")

	// informa caso já tenha OS gerada
	If ( _lRet ) .and. ( ! Empty(SC0->C0_ZOSPLT) )

		// informa o usuário
		MsgStop("Já existe OS gerada para essa reserva: " + SC0->C0_ZOSPLT + ".")
		_lRet := .f.
	EndIf

	// caso seja pra gerar a OS
	If ( _lRet )

		// vai gerar OS para selecionar os pallets
		MsgRun("Gerando Ordem de Serviço...", "Aguarde...", {|| CursorWait(),sfGeraOs( SC0->C0_ZCLIENT, SC0->C0_ZLOJA, _cObs ), CursorArrow()})
	EndIf

Return

// ** função que vai selecionar arquivo para importação ** //
User Function MA430IMP()

	local _cLinha  := ""
	// arrays da operação
	local _aDados  := {}
	// dados do pallet
	local _aDadosPlt := {}
	// array de apoio
	local _nX := 0
	// variavel de controle
	local _lRet := .t.
	// arquivos importados
	local _nArqOK := 0
	// log de informações
	local _cDetLog := ""
	// seek na Z47
	local _cSeekZ47 := ""
	// validação de registro na Z47
	local _lSeekZ47 := .f.
	// validação de registros duplicados
	local _lFound := .f.

	// arquivo para upload
	private _cArquivo
	// diretorio local padrao
	private _cDirLocPdr := "c:\"

	_lRet := ( ! Empty(SC0->C0_ZAGRUPA) )

	If ( ! _lRet )
		MsgStop("Agrupador não informado para a reserva selecionada.")
	EndIf

	If ( _lRet )
		_lRet := MsgYesNo("Deseja Importar Arquivo para o Agrupador " + AllTrim(SC0->C0_ZAGRUPA) + "?")
	EndIf

	If ( _lRet )

		// posiciono no registro pra ver se já existe algum registro para esse booking
		dbSelectArea("Z47")
		Z47->( dbSetOrder(3) ) // Z47_FILIAL, Z47_AGRUPA, R_E_C_N_O_, D_E_L_E_T_
		If ( Z47->( dbSeek( _cSeekZ47 := xFilial("Z47") + AllTrim(SC0->C0_ZAGRUPA)) ) )
			// atualiza informação
			_lSeekZ47 := .t.
		EndIf

		// busca arquivo XML
		_cArquivo := cGetFile("Planilha|*.csv", ("Selecione arquivo CSV"),,_cDirLocPdr,.f.,GETF_LOCALHARD,.f.)

		// copia o arquivo local para o servidor
		If ( ! Empty(_cArquivo) )
			sfCopiaArq(@_cArquivo)
		EndIf

		// se o arquivo foi encontrado
		If ( ! Empty(_cArquivo) )

			// abre o arquivo
			FT_FUSE(_cArquivo)

			// define o processamento
			ProcRegua(FT_FLASTREC())

			// vai pro início do arquivo
			FT_FGOTOP()

			// lê linha a linha
			While ( ! FT_FEOF() )

				// informa o usuario
				IncProc("Lendo arquivo csv...")

				// define o inicio da leitura
				_cLinha := FT_FREADLN()
				_cValue := Separa(_cLinha,";",.T.)

				// dados
				If ( ! Empty(_cValue) )
					AADD( _aDados, _cValue )
				EndIf

				FT_FSKIP()
			EndDo

			// fecha o arquivo
			FT_FUSE()

			// se encontrou registros, vai gravar os dados
			If ( len(_aDados) > 0)

				// inicia a transação
				BeginTran()

				// pra cada registro encontrado anteriormente, insere o registro na tabela
				For _nX := 1 to len(_aDados)

					// informa o usuario
					IncProc("Gravando arquivo csv...")

					// se não foi preenchido, passa pro próximo registro
					If ( Empty(_aDados[_nX][1]) )
						loop
					EndIf

					/*
					1-PALLET
					2-SALDO
					3-COD CLIENTE
					4-LOJA CLIENTE
					5-NUMSEQ
					6-COD PROD
					7-DESC PROD
					8-END ATUAL
					9-LOCAL
					*/
					// posiciono na Z126
					_aDadosPlt := sfRetPlt( _aDados[_nX][1] )

					// se não encontrou avisa o usuári
					If ( len(_aDadosPlt) == 0 )
						_cDetLog += "O lote " + AllTrim(_aDados[_nX][1]) + " não foi encontrado. Dê entrada no lote ou remova o mesmo do arquivo csv." + CRLF + CRLF
						_lRet := .f.
						loop
					EndIf

					// se já encontrou registros, vai incrementar os dados
					If ( _lSeekZ47)

						// valida o que já existe e só adiciona o que for diferente
						While ( ! Z47->( EoF() ) ) .and. ( AllTrim(Z47->(Z47_FILIAL+Z47_AGRUPA)) == AllTrim(_cSeekZ47) )

							// caso encontre o lote, para pro próximo registro
							If ( AllTrim(_aDados[_nX][1]) == AllTrim(Z47->Z47_LOTCTL) )
								_lFound := .t.
								Exit
							EndIf

						// próx registro
						Z47->( DbSkip() )
						EndDo

						// se o registro foi encontrado, loop
						If ( _lFound )
							_lFound := .f.
							loop
						EndIf
					EndIf

					// só insere registros únicos
					If ( ! _lSeekZ47 ) .or. ( ( _lSeekZ47 ) .and. ( ! _lFound ) )

						// insiro o registro na tabela
						Reclock("Z47", .t.)
						Z47->Z47_FILIAL := xFilial("Z47")
						Z47->Z47_ETQPLT := _aDadosPlt[1][1]
						Z47->Z47_QUANT  := Val(StrTran(_aDados[_nX][2], ",", "."))
						Z47->Z47_CLIENT := _aDadosPlt[1][3]
						Z47->Z47_LOJA   := _aDadosPlt[1][4]
						Z47->Z47_LOTCTL := _aDados[_nX][1]
						Z47->Z47_NUMSEQ := _aDadosPlt[1][5]
						Z47->Z47_AGRUPA := SC0->C0_ZAGRUPA
						Z47->( MsUnlock() )

						// controle de importação
						_nArqOK++
					EndIf

				Next _nX

				// se houve divergencia
				If ( ! _lRet)

					// rollback nas informações
					DisarmTransaction()
					// caso nenhum arquivo tenha sido informado
					If ( _nArqOK == 0)
						_cDetLog += "Nenhum registro importado." +CRLF
					EndIf

					HS_MsgInf("Resumo da Operação:" +CRLF+ _cDetLog ,;
						"Log de Importação de Pallets",;
						"Log de Importação de Pallets" )
				EndIf

				// finalizo a transação
				EndTran()

				If ( _lRet )
					// caso nenhum arquivo tenha sido informado
					If ( _nArqOK == 0)
						MsgInfo( "Nenhum registro importado.")
					Else
						MsgInfo( "Arquivo importado. Total de registros: " + AllTrim( Str( _nArqOK ) ) )
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
Return

// ** gera mapa de pallets a serem selecionados ** //
Static Function sfGeraOs( mvCliente, mvLoja, mvObs )

	// recupera area inicial
	local _aArea := GetArea()

	// posiciono no registro pra ver se já existe algum registro para esse booking
	dbSelectArea("Z47")
	Z47->( dbSetOrder(3) ) // Z47_FILIAL, Z47_AGRUPA, R_E_C_N_O_, D_E_L_E_T_
	If ( ! Empty(SC0->C0_ZAGRUPA) ) .and. ( ! Z47->( dbSeek( xFilial("Z47") + SC0->C0_ZAGRUPA) ) )
		MsgStop("Não existem pallets informados para esse agrupador.")
		Return
	Else

		// gera OS para seleção de pallets
		If ( U_WMSA009B(nil, "03", nil, "ZZZ", nil, .f., "T06", mvCliente, mvLoja, .t., mvObs) )

			// grava o número da os respectivo a reserva
			Reclock("SC0")
			SC0->C0_ZOSPLT := Z06->Z06_NUMOS
			MsUnlock()
		EndIf
	EndIf

	// restaura area inicial
	RestArea(_aArea)

Return

// ** função que retorno o pallet pelo lote na Z16 ** //
Static Function sfRetPlt ( mvLote )

	// query
	local _cQuery := ""
	// pallet para retorno
	local _aDadosPlt := {}

	// pega o pallet na Z16 baseado no pallet
	_cQuery := " SELECT DISTINCT Z16_ETQPAL, Z16_SALDO, D1_FORNECE, D1_LOJA, Z16_NUMSEQ, Z16_CODPRO, B1_DESC, Z16_ENDATU, Z16_LOCAL "
	_cQuery += " FROM " + RetSqlTab("Z16")
	_cQuery += " INNER JOIN " + RetSqlTab("SD1") + " ON D1_NUMSEQ = Z16_NUMSEQ AND " + RetSqlCond("SD1")
	_cQuery += " INNER JOIN " + RetSqlTab("SB1") + " ON B1_COD = Z16_CODPRO AND " + RetSqlCond("SB1")
	_cQuery += " WHERE " + RetSqlCond("Z16") + " AND Z16_SALDO > 0 AND Z16_LOTCTL = '" + mvLote + "' "

	// info para debug
	memowrit("C:\query\ma430mnu_retplt.txt", _cQuery)

	// jogo o retorno da query para a variável
	_aDadosPlt := U_SqlToVet(_cQuery)

// retorna o array
Return _aDadosPlt

// ** funcão que informa o max load por container ** //
Static Function sfMaxLoad( mvMaxLoad )

	local _lOk := .f.
	local _oDlgInfVlr, _oBtnConf

	// define o valor inicial
	mvMaxLoad := 29.740

	// monta a tela para alterar informar o max load do container
	_oDlgInfVlr := MSDialog():New(000,000,160,240,"Max Load Container",,,.F.,,,,,,.T.,,,.T. )

	// max load
	_oSayEsp := TSay():New(032,010,{||"Peso Máximo:"},_oDlgInfVlr,,,.F.,.F.,.F.,.T.)
	_oGetEsp := TGet():New(030,050,{|u| If(PCount()>0,mvMaxLoad:=u,mvMaxLoad)},_oDlgInfVlr,060,010,PesqPict("SC6","C6_QTDVEN"), ,,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,,"mvMaxLoad",,)

	// botao para confirmar
	_oBtnConf := TButton():New(060,040,"Confirmar",_oDlgInfVlr,{||_lOk:=.t.,_oDlgInfVlr:End()},050,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgInfVlr:Activate(,,,.T.,{|| ( mvMaxLoad > 0 ) } )

Return(_lOk)

// ** funcao que copia o arquivo local para o servidor ** //
Static Function sfCopiaArq(mvArquivo)
	Local _cTmpArq	:= "" // nome do arquivo
	Local _cTmpExt	:= "" // extensao do arquivo
	local _cTmpDrv  := "" // drive do arquivo origem
	local _cTmpDir  := "" // diretorio do arquivo origem

	// cria os diretorios necessarios
	MakeDir("\tecadi")
	MakeDir("\tecadi\xls")
	MakeDir("\tecadi\xls\importados")
	// copia o arquivo do local para o servidor
	CpyT2S(mvArquivo,"\tecadi\xls",.f.)
	// ex: SplitPath ( < cArquivo>, [ @cDrive], [ @cDiretorio], [ @cNome], [ @cExtensao] )
	SplitPath(mvArquivo,@_cTmpDrv,@_cTmpDir,@_cTmpArq,@_cTmpExt)

	// atualiza pasta padrao
	_cDirLocPdr := _cTmpDrv + _cTmpDir

	// muda o caminho do arquivo para o servidor
	mvArquivo := "\tecadi\xls\"+_cTmpArq+_cTmpExt

Return .t.

//** funcao que demonstra os detalhes do endereco selecionado
USer Function MA430VIS( mvAgrupa )
	// objetos
	local _oWndConsEtq
	local _oBrwDetCons
	local _cQuery := ""

	// variaveis do browse
	local _aHeadDet := {}
	local _aColsDet := {}

	If ( Empty(mvAgrupa) )
		MsgStop("Agrupador não encontrado.")
		Return
	EndIf

	// define o header do browse
	aAdd(_aHeadDet,{"Status"    ,"IT_STAT"    , "" , 2                      , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadDet,{"Lote"      ,"Z47_LOTCTL" , "" , TamSx3("Z47_LOTCTL")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadDet,{"Cod.Prod"  ,"B1_COD"     , "" , TamSx3("B1_COD")[1]    , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadDet,{"Descrição" ,"B1_DESC"    , "" , TamSx3("B1_DESC")[1]   , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadDet,{"Etiq.Prod" ,"Z16_ETQPRD" , "" , TamSx3("Z16_ETQPRD")[1], 0,Nil,Nil,"C",Nil,"R" })

	// busca os dados na tabela
	_cQuery := " SELECT CASE "
	_cQuery += "       WHEN Z47_IDRES <> '' THEN 'OK' "
	_cQuery += "      ELSE '  ' "
	_cQuery += "    END IT_STAT, "
	_cQuery += "    Z47_LOTCTL, "
	_cQuery += "    B1_COD, "
	_cQuery += "    B1_DESC, "
	_cQuery += "    Z16_ETQPRD, "
	_cQuery += "    '.f.' "
	_cQuery += " FROM   " + RetSqlTab("Z47")
	_cQuery += "   INNER JOIN " + RetSqlTab("Z16")
	_cQuery += "           ON " + RetSqlCond("Z16")
	_cQuery += "              AND Z16_ETQPAL = Z47_ETQPLT "
	_cQuery += "   INNER JOIN " + RetSqlTab("SB1")
	_cQuery += "           ON " + RetSqlCond("SB1")
	_cQuery += "              AND B1_COD = Z16_CODPRO "
	_cQuery += " WHERE " + RetSqlCond("Z47")
	_cQuery += "   AND Z47_AGRUPA = '" + AllTrim(mvAgrupa) + "' "
	_cQuery += " ORDER  BY Z47_LOTCTL,
	_cQuery += "           Z16_ETQPRD "

	// jogo os dados pro array
	_aColsDet := U_SqlToVet(_cQuery)

	// definicao da tela de consultas
	_oWndConsEtq := MSDialog():New(000,000,200,400,"Pallets Importados",,,.F.,,,,,,.T.,,,.T. )

	// browse com os detalhes da consulta
	_oBrwDetCons := MsNewGetDados():New(000,000,600,600,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDet),'AllwaysTrue()','','AllwaysTrue()',_oWndConsEtq,_aHeadDet,_aColsDet)
	_oBrwDetCons:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oWndConsEtq CENTERED

Return