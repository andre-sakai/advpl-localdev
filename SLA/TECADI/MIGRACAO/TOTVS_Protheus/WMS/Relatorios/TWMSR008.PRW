#Include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para impressao de etiquetas do WMS               !
!                  ! - Identificacao do produto da nota fiscal               !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 08/2012 !
+------------------+---------------------------------------------------------+
!Observacoes       !                                                         !
+------------------+--------------------------------------------------------*/

User Function TWMSR008(mvCliente, mvLoja, mvCesv, mvCarga)
	// variavel de retorno
	local _lRet := .f.
	// reimpressao
	local _lReimprime := (ValType(mvCliente) != "C")
	//FWTemporaryTable
	private _TRBITENS := GetNextAlias()
	private _oAlTrb

	// rotina para impressao dos dados
	Processa ({|| _lRet := sfImpressao(_lReimprime, mvCliente, mvLoja, mvCesv, mvCarga) },"Gerando etiquetas...")
	
	If Type("_oAlTrb") == "O"
		_oAlTrb:Delete()
	Endif

Return(_lRet)

//** funcao para impressao dos dados
Static Function sfImpressao(mvReimprime, mvCliente, mvLoja, mvCesv, mvCarga)
	// impressoras disponiveis no windows
	local _aImpWindows := U_FtRetImp()

	// objetos
	local _oWndSelImp
	local _oCBxTpEtiq
	local _oBtnEtqOk, _oBtnEtqCan

	// tela para selecao dos itens
	local _oWndSelItens
	local _oPnlSrvCabec
	local _oBtnConfirma, _oBtnFechar
	local _oBrwRelSrv

	// retorna a pasta temporaria da maquina
	local _cPathTemp := AllTrim(GetTempPath())
	local _cTmpEtiq

	local _cQryEtiq := ""
	local _nQtdReg := 0

	// quantidade de etiquetas
	local _nQtdTotal := 0
	local _nEtiq := 0

	// referencia do cliente
	local _cRefCliente := ""

	// mascara container
	local _cMskCont := PesqPict("SZC","ZC_CODIGO")

	// perguntas
	local _cPerg := PadR("TWMSR008",10)
	local _aPerg := {}

	// codigo da etiqueta
	local _cCodEtiq := ""

	local _lOk := .f.
	local _cImpSelec := U_FtImpZbr()

	// quantidade informada / impressao por palete
	local _lInfQtdMan := .f.

	// arquivos temporarios
	local _cTmpArquivo, _cTmpBat, _nTmpHdl

	// quantidade de produto por palete
	local _nQtdMaxPalete := 0

	// estrutura do arquivo de trabalho
	local _aEstTrb := {}
	local _cArqTmp
	local _aHeadBrw := {}
	local _cMarcaBrw := GetMark()

	// controle dos itens a serem impressora
	local _cImpItem := ""

	// valida o arquivo gerado
	local _lImpressOk := .f.

	// centraliza tela
	local _lDlgCenter := (Type("_aSizeDlg")=="U")
	// largura da tela
	local _nDlgLarg := If(Type("_aSizeDlg")=="U",700,(_aSizeDlg[1]-6 ))
	// altura da tela
	local _nDlgAltu := If(Type("_aSizeDlg")=="U",300,(_aSizeDlg[2]-20))

	//Quantidade de Pelates.
	local _aRetPal := {}

	// quant palete cheio
	local _nQtdPltChe := 0
	// quant palete fracionado
	local _nQtdPltFra := 0

	// descricao do produto
	local _cDescProd := ""

	// valores padroes
	Default mvCarga := CriaVar("DAK_COD",.f.)

	// quando for reimpressao
	If ((mvReimprime) .and. (Empty(mvCarga)))
		// monta a lista de perguntas
		aAdd(_aPerg,{"Etiqueta de ?" , "C", TamSx3("Z11_CODETI")[1], 0, "G",,"",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par01
		aAdd(_aPerg,{"Etiqueta Até ?", "C", TamSx3("Z11_CODETI")[1], 0, "G",,"",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par02
		aAdd(_aPerg,{"CESV ?"        , "C", TamSx3("ZZ_CESV")[1]   , 0, "G",,"",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par03
		aAdd(_aPerg,{"Ordem Serviço?", "C", TamSx3("Z05_NUMOS")[1] , 0, "G",,"",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par04

		// cria o grupo de perguntas
		U_FtCriaSX1(_cPerg,_aPerg)

		// abre os parametros
		If ( ! Pergunte(_cPerg,.T.) )
			Return(.f.)
		EndIf
	EndIf

	// tela para selecionar as impressoras de etiquetas disponiveis
	_oWndSelImp := MSDialog():New(000,000,080,210,"Impressoras de etiquetas",,,.F.,,,,,,.T.,,,.T. )
	_oCBxTpEtiq := TComboBox():New( 004,004,{|u| If(PCount()>0,_cImpSelec:=u,_cImpSelec)},_aImpWindows,100,010,_oWndSelImp,,,,,,.T.,,"",,,,,,,_cImpSelec )
	_oBtnEtqOk  := SButton():New( 021,021,1,{ || _lOk := .t. , _oWndSelImp:End() },_oWndSelImp,,"", )
	_oBtnEtqCan := SButton():New( 021,055,2,{ || _oWndSelImp:End() },_oWndSelImp,,"", )

	_oWndSelImp:Activate(,,,.T.)

	If (_lOk)

		// grava informacoes da impressora selecionada
		U_FtImpZbr(_cImpSelec)

		// remove texto e mantem só o caminho
		_cImpSelec := Separa(_cImpSelec,"|")[2]

		// define o arquivo temporario com o conteudo da etiqueta
		_cTmpArquivo := _cPathTemp+"wms_etiq_prod.txt"

		// cria e abre arquivo texto
		_nTmpHdl := fCreate(_cTmpArquivo)

		// testa se o arquivo de Saida foi Criado Corretamente
		If (_nTmpHdl == -1)
			// mensagem
			MsgAlert("O arquivo de nome "+_cTmpArquivo+" nao pode ser executado! Verifique os parametros.", "Atencao!")
			// retorno
			Return(.f.)
		Endif

		// reimpressao
		If (mvReimprime)
			// monta query para buscar os dados
			_cQryEtiq := "SELECT F1_FORNECE, Z11_PROCES F1_PROGRAM, Z11_DOC F1_DOC, Z11_SERIE F1_SERIE, Z11_QTD1, Z11_QTD2, F1_DTDIGIT, ISNULL(ZZ_CNTR01,'') ZZ_CNTR01, D1_COD, D1_DESCRIC, "
			_cQryEtiq += "Z11_CODETI, (Z11_QTDIMP + 1) Z11_QTDIMP, "
			// endereco atual
			_cQryEtiq += " ISNULL((SELECT DISTINCT Z16_ENDATU "
			_cQryEtiq += " FROM "+RetSqlTab("Z16")
			_cQryEtiq += " WHERE "+RetSqlCond("Z16")+" AND Z16_ETQPRD = Z11_CODETI AND Z16_NUMSEQ = D1_NUMSEQ),'') Z16_ENDATU, "
			// ordem de servico
			_cQryEtiq += " ISNULL(Z05_NUMOS,'') Z05_NUMOS, D1_LOTECTL "
			// cadastro de etiquetas
			_cQryEtiq += " FROM " + RetSqlTab("Z11")
			// nota fiscal
			_cQryEtiq += " INNER JOIN " + RetSqlTab("SF1") + " ON " + RetSqlCond("SF1") + " AND F1_DOC = Z11_DOC AND F1_SERIE = Z11_SERIE AND F1_TIPO = Z11_TIPONF "
			_cQryEtiq += " AND F1_FORNECE = Z11_CLIENT AND F1_LOJA = Z11_LOJA "
			// movimentacao de veiculo
			_cQryEtiq += " INNER JOIN " + RetSqlTab("SZZ") + " ON " + RetSqlCond("SZZ") + " AND ZZ_CESV   = Z11_CESV "
			// ordem de servico
			_cQryEtiq += " INNER JOIN " + RetSqlTab("Z05") + " ON " + RetSqlCond("Z05") + " AND Z05_CESV  = Z11_CESV "
			// filtra pela ordem de servico
			If ( ! Empty(mv_par04) )
				_cQryEtiq += " AND Z05_NUMOS = '" + mv_par04 + "' "
			EndIf
			// itens da nota fiscal
			_cQryEtiq += " INNER JOIN "+RetSqlTab("SD1")+" ON "+RetSqlCond("SD1")+" AND D1_NUMSEQ = Z11_NUMSEQ "
			// filtro padrao
			_cQryEtiq += " WHERE "+RetSqlCond("Z11")
			// filtro das etiquetas
			_cQryEtiq += " AND Z11_CODETI BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' "
			// filtro por CESV
			If ( ! Empty(mv_par03) )
				_cQryEtiq += " AND Z11_CESV = '" + mv_par03 + "' "
			EndIf
			// somente tipo 01-produtos
			_cQryEtiq += " AND Z11_TIPO = '01' "
			// filtra pela carga
			If ( ! Empty(mvCarga) )
				_cQryEtiq += " AND Z11_CARGA = '" + mvCarga + "' "
			EndIf
			// ordem dos dados
			_cQryEtiq += "ORDER BY Z11_CODETI"

		ElseIf ( ! mvReimprime )

			// define a estrutura do TRB
			aAdd(_aEstTrb,{"IT_OK"     , "C", 2                      , 0                      })
			aAdd(_aEstTrb,{"D1_ITEM"   , "C", TamSx3("D1_ITEM")[1]   , 0                      })
			aAdd(_aEstTrb,{"D1_COD"    , "C", TamSx3("D1_COD")[1]    , 0                      })
			aAdd(_aEstTrb,{"D1_DESCRIC", "C", TamSx3("D1_DESCRIC")[1], 0                      })
			aAdd(_aEstTrb,{"Z04_QUANT" , "N", TamSx3("Z04_QUANT")[1] , TamSx3("Z04_QUANT")[2] })
			aAdd(_aEstTrb,{"IT_QTDPAL" , "N", TamSx3("Z04_QTDPAL")[1], TamSx3("Z04_QTDPAL")[2]})

			// define o header do browse
			aAdd(_aHeadBrw,{"IT_OK"     ,"@!" ,"  "})
			aAdd(_aHeadBrw,{"D1_ITEM"   ,"@!" ,"Item NF"})
			aAdd(_aHeadBrw,{"D1_COD"    ,"@!" ,"Produto"})
			aAdd(_aHeadBrw,{"D1_DESCRIC","@!" ,"Descrição"})
			aAdd(_aHeadBrw,{"Z04_QUANT" ,PesqPict("Z04","Z04_QUANT") , "Quantidade"})
			aAdd(_aHeadBrw,{"IT_QTDPAL" ,PesqPict("Z04","Z04_QTDPAL"), "Qtd Palete"})

			// fecha o alias do TRB
			If (Select(_TRBITENS)<>0)
				(_TRBITENS)->(dbSelectArea(_TRBITENS))
				(_TRBITENS)->(dbCloseArea())
			EndIf

			// cria o TRB
			_oAlTrb := FWTemporaryTable():New(_TRBITENS)
			_oAlTrb:SetFields(_aEstTrb)
			_oAlTrb:Create()

			// monta query para buscar os dados
			_cQryEtiq := "SELECT F1_FORNECE, F1_LOJA, F1_TIPO, F1_DOC, F1_SERIE, F1_DTDIGIT, D1_ITEM, D1_COD, D1_DESCRIC, D1_LOCAL, F1_PROGRAM, D1_NUMSEQ, Z04_QUANT, "
			_cQryEtiq += "ZZ_CNTR01, ZZ_CESV, ISNULL(Z05_NUMOS,'') Z05_NUMOS, "
			_cQryEtiq += "CASE WHEN Z04_QTDPAL = 0 THEN ((Z04_LASTRO * Z04_CAMADA) + Z04_ADICIO) / Z04_QUANT ELSE Z04_QTDPAL END IT_QTDPAL, Z04_QTDPAL, D1_LOTECTL "
			// nota fiscal
			_cQryEtiq += " FROM "+RetSqlTab("SF1")
			// itens da nota fiscal
			_cQryEtiq += " INNER JOIN "+RetSqlTab("SD1")+" ON "+RetSqlCond("SD1")+" AND D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE "
			_cQryEtiq += " AND D1_FORNECE = F1_FORNECE AND D1_LOJA = F1_LOJA "
			// saldo a enderecar
			_cQryEtiq += " LEFT  JOIN "+RetSqlTab("SDA")+" ON "+RetSqlCond("SDA")+" AND DA_PRODUTO = D1_COD AND DA_LOCAL = D1_LOCAL AND DA_NUMSEQ = D1_NUMSEQ "
			_cQryEtiq += " AND DA_DOC = D1_DOC AND DA_SERIE = D1_SERIE AND DA_CLIFOR = D1_FORNECE AND DA_LOJA = D1_LOJA "
			// saldo poder de terceiros
			_cQryEtiq += " INNER JOIN "+RetSqlTab("SB6")+" ON "+RetSqlCond("SB6")+" AND B6_IDENT = D1_IDENTB6 AND B6_SALDO > 0 "
			// movimentacao do veiculo
			_cQryEtiq += " INNER JOIN "+RetSqlTab("SZZ")+" ON "+RetSqlCond("SZZ")+" AND ZZ_CESV = '" + mvCesv + "' "
			// ordem de servico
			_cQryEtiq += " LEFT  JOIN "+RetSqlTab("Z05")+" ON "+RetSqlCond("Z05")+" AND Z05_CESV = ZZ_CESV "
			// itens de mercadoria por container/veiculo
			_cQryEtiq += " INNER JOIN "+RetSqlTab("Z04")+" ON "+RetSqlCond("Z04")+" AND Z04_CLIENT = F1_FORNECE AND Z04_LOJA = F1_LOJA AND Z04_TIPONF = F1_TIPO "
			_cQryEtiq += " AND Z04_NF   = F1_DOC AND Z04_SERIE = F1_SERIE AND Z04_ITEMNF = D1_ITEM AND Z04_PROD = D1_COD "
			_cQryEtiq += " AND Z04_CESV = ZZ_CESV "
			// filtr da nota fiscal
			_cQryEtiq += " WHERE "+RetSqlCond("SF1")
			_cQryEtiq += " AND F1_TIPO IN ('B','D') "
			_cQryEtiq += " AND F1_STATUS != ' ' "
			_cQryEtiq += " AND F1_FORNECE = '" + mvCliente + "' AND F1_LOJA  = '" + mvLoja + "' "
			// verifica se ja existe etiqueta para este processo/veiculo
			_cQryEtiq += " AND NOT EXISTS (SELECT Z11_CODETI FROM "+RetSqlTab("Z11")+" WHERE " + RetSqlCond("Z11")
			_cQryEtiq += " AND Z11_TIPO   = '01' "
			_cQryEtiq += " AND Z11_DOC    = F1_DOC  AND Z11_SERIE  = F1_SERIE AND Z11_TIPONF = F1_TIPO   AND Z11_CLIENT = F1_FORNECE AND Z11_LOJA = F1_LOJA "
			_cQryEtiq += " AND Z11_ITEMNF = D1_ITEM AND Z11_CODPRO = D1_COD   AND Z11_NUMSEQ = D1_NUMSEQ "
			_cQryEtiq += " AND Z11_CESV   = ZZ_CESV) "
			// ordem dos dados
			_cQryEtiq += " ORDER BY D1_ITEM "

			// alimenta o TRB
			SqlToTrb(_cQryEtiq, _aEstTrb, _TRBITENS)

			// abre o arquivo de trabalho
			(_TRBITENS)->(dbSelectArea(_TRBITENS))
			(_TRBITENS)->(dbGoTop())

			// monta tela com os servicos
			_oWndSelItens := MSDialog():New(000,000,_nDlgAltu,_nDlgLarg,"Relação de Itens da Nota",,,.F.,,,,,,.T.,,,.T. )

			// cria o panel do cabecalho - botoes de operacao
			_oPnlSrvCabec := TPanel():New(000,000,nil,_oWndSelItens,,.F.,.F.,,,000,022,.T.,.F. )
			_oPnlSrvCabec:Align:= CONTROL_ALIGN_TOP

			// -- botao que confirma os servicos
			_oBtnConfirma := TButton():New(005,005,"Confirmar",_oPnlSrvCabec,{|| _lOk := .t. ,_oWndSelItens:End() },040,010,,,,.T.,,"",,,,.F. )
			// -- botao para fechar a tela
			_oBtnFechar := TButton():New(005,050,"Fechar",_oPnlSrvCabec,{|| _oWndSelItens:End() },040,010,,,,.T.,,"",,,,.F. )

			// browse com a listagem dos produtos conferidos
			_oBrwRelSrv := MsSelect():New(_TRBITENS,"IT_OK",,_aHeadBrw,,_cMarcaBrw,{15,1,183,373},,,,,)
			_oBrwRelSrv:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

			// ativa a tela
			_oWndSelItens:Activate(,,,(_lDlgCenter),,,)

			// se a tela foi confirmada
			If (_lOk)
				(_TRBITENS)->(dbSelectArea(_TRBITENS))
				(_TRBITENS)->(dbGoTop())
				While (_TRBITENS)->(!Eof())
					// item selecionado
					If (!Empty((_TRBITENS)->IT_OK))
						_cImpItem += (_TRBITENS)->D1_ITEM+";"
					EndIf
					// proximo item
					(_TRBITENS)->(dbSkip())
				EndDo
			ElseIf (!_lOk)
				// fecha arquivo texto
				fClose(_nTmpHdl)
				Return(.f.)
			EndIf

		EndIf

		memowrit("c:\query\twmsr008.txt",_cQryEtiq)

		If Select("_QRYETIQ") <> 0
			dbSelectArea("_QRYETIQ")
			dbCloseArea()
		EndIf

		// executa a query
		dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQryEtiq),"_QRYETIQ",.F.,.T.)
		dbSelectArea("_QRYETIQ")

		If _QRYETIQ->(Eof())
			// mensagem
			MsgAlert("Não há etiquetas disponíveis para impressão.", "Atenção")
			// fecha arquivo texto
			fClose(_nTmpHdl)
			// retorno
			Return(.f.)
		EndIf

		If (mvReimprime)
			dbEval({|| _nQtdReg += 1 })
		ElseIf (!mvReimprime)
			dbEval({|| _nQtdReg += Z04_QUANT })
		EndIf

		// quantidade total da regua de prcessamento
		ProcRegua(_nQtdReg)

		// seleciona alias
		dbSelectArea("_QRYETIQ")
		_QRYETIQ->(dbGoTop())

		// define o conteudo inicial da etiqueta a ser impressa
		_cTmpEtiq := "CT~~CD,~CC^~CT~"+CRLF
		_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
		_cTmpEtiq += "^XA"+CRLF

		// grava a Linha no Arquivo Texto
		fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

		// varre todos os itens
		While _QRYETIQ->( ! Eof() )

			// quanto for impressao, verifica os itens selecionados
			If (!mvReimprime)
				// verifica se o item esta selecionado
				If ( ! (_QRYETIQ->D1_ITEM $ _cImpItem))
					_QRYETIQ->(dbSkip())
					Loop
				EndIf
			EndIf

			// reinicia variaveis
			_nQtdMaxPalete := 0

			// define a quantidade para impressao
			If (mvReimprime)
				_nQtdTotal := 1
			ElseIf (!mvReimprime)
				// verifica como deve ser a immpressao (por produto / por palete)
				_lInfQtdMan := (Posicione("SB1",1,xFilial("SB1")+_QRYETIQ->D1_COD,"B1_ZINFQTD")=="S")

				// verifica se a impressao deve ser por palete
				If (_lInfQtdMan)
					// calcula norma de paletizacao do produto
					// estrutura do retorno
					// 1-Quantidade Total de Palete
					// 2-Quantidade de Paletes Cheios
					// 3-Quantidade de Paletes Fracionados
					// 4-Quantidade Maxima de SKU/Volumes por Palete
					// 5-Tipo do Calculo (Q-Quant Unitarios / P-Quant Palete Informado)
					_aRetPal := U_FtWmsNorma(_QRYETIQ->D1_COD, _QRYETIQ->D1_LOCAL, Nil, Nil, Nil, _QRYETIQ->ZZ_CESV, _QRYETIQ->D1_NUMSEQ, Nil, _QRYETIQ->Z04_QUANT, _QRYETIQ->Z04_QTDPAL)

					// atualiza variavel de controle de acordo com o calculo da funcao FtWmsNorma
					_nQtdTotal  := _aRetPal[1]
					_nQtdPltChe := _aRetPal[2]
					_nQtdPltFra := _aRetPal[3]

					// impressao por produto/quantidade
				ElseIf (!_lInfQtdMan)
					_nQtdTotal := _QRYETIQ->Z04_QUANT
				EndIf
			EndIf

			// define a referencia do cliente
			_cRefCliente := AllTrim(Posicione("SZ1",1, xFilial("SZ1")+_QRYETIQ->F1_PROGRAM ,"Z1_REFEREN"))

			// executa impressao pela quantidade
			For _nEtiq := 1 to _nQtdTotal

				// incremento da regua
				IncProc()

				// reimpressao
				If (mvReimprime)
					_cCodEtiq := _QRYETIQ->Z11_CODETI

				ElseIf ( ! mvReimprime )
					// conteudo passado como parametro
					_aTmpConteudo := {_QRYETIQ->F1_FORNECE, _QRYETIQ->F1_LOJA,;
					_QRYETIQ->F1_TIPO, _QRYETIQ->F1_DOC, _QRYETIQ->F1_SERIE,;
					_QRYETIQ->D1_ITEM, _QRYETIQ->D1_COD,;
					_QRYETIQ->D1_NUMSEQ, _QRYETIQ->F1_PROGRAM,;
					mvCesv,;
					_nEtiq, _nQtdTotal}

					// gera codigo da etiqueta
					_cCodEtiq := U_FtGrvEtq("01",_aTmpConteudo)
				EndIf

				// define conteudo no arquivo
				_lImpressOk := .t.

				// descricao do produto
				_cDescProd := AllTrim(_QRYETIQ->D1_COD) + "-" + AllTrim(_QRYETIQ->D1_DESCRIC)

				// inicio das informações
				_cTmpEtiq := "^MMT"+CRLF
				_cTmpEtiq += "^PW759"+CRLF
				_cTmpEtiq += "^LL0440"+CRLF
				_cTmpEtiq += "^LS0"+CRLF
				_cTmpEtiq += "^FO32,0^GFA,03072,03072,00032,:Z64:"+CRLF

				// imagem codificada
				_cTmpEtiq += "eJzt1TFrFEEUB/CZ7B0bRLgcJoWgbDwRLBTyBdwxRKwsjHCg4BewOwshRbjbkMLSyjogWBhII6TOWsiVKjZ2rlgEK1eCsIFxnv/Z2eyO8WausZJ7xRX327fz9r2"+;
				"ZXcZm8Q8iotTrRLnX+YimrCASTzZRGnoKiIgoWfHcGy7Pup10eO5fuvsBeenuBwzIv0DlzgVC49LlHePK5RFVBUb0A1ehkE0mcvz87TkpTpl2xYaT80MUKtHSpHZReVLmd1Cown/pJE"+;
				"d+RJJrz2ofWflqN0oUPO7kjf/sVw0ccqycDDmxOGx8g5kRwXVlTATfkzhofMDNiKp8xksvak8FfTvJJxljIHDe+BahbkSGfJL4Oxyntm83bvJP+dPSZZUvMLBxZvsz48Lka98+7UfwM"+;
				"K/qFxHcqh/z/woPMvP8SRxRZj+/8V+pyY9SjCC3+2f8OB/o9fX8BBXxwR9+CJcruv7K7fnBx3C1XOYHlA95Yc//xE1+6dLeP2HpR2TymRZp7z/Lkc8uYHsp7F/bdYuw/uSo3HlAcf50"+;
				"C5znB44jcDjNneeT601PYzg/v9Tiq92F7uLq0s1b9QWkcETeFYy19tZ2L21df33mee/Ti/uNy8rvfHk8WF+7sn/uYrr45GHto9Lx/pjf6169O/eq1bvWe//2duMFjtjnjLH+/oNHH9ov+"+;
				"x/bl9dv3Ktd5PCdzFU/i3Ls7p3U6Z0MfpA4PXwDF04u36Aq9jg6rDan+IbHsQPkwM3LGH+Run0B7T323H4e7Sv8y/u/j0K/PDzBvZ8nxBwlXmdtP89iFv9l/AYffxVt:1465"+CRLF

				// detalhes e posicionamento das informações
				_cTmpEtiq += "^BY4,3,110^FT86,395^BCN,,N,N"+CRLF
				_cTmpEtiq += "^FD>:"+_cCodEtiq+"^FS"+CRLF
				_cTmpEtiq += "^FO26,75^GB705,0,1^FS"+CRLF

				// descrição do produto em até duas linhas (caso tenha)
				_cTmpEtiq += "^FT45,239^A0N,25,24^FH\^FD"+Substr(_cDescProd, 1, 51)+"^FS"+CRLF
				_cTmpEtiq += "^FT45,271^A0N,25,24^FH\^FD"+Substr(_cDescProd,52, 50)+"^FS"+CRLF

				// numero do container
				If ( ! Empty(_QRYETIQ->ZZ_CNTR01))
					_cTmpEtiq += "^FT406,172^A0N,25,24^FH\^FDCNTR: "+Transf(_QRYETIQ->ZZ_CNTR01,_cMskCont)+"^FS"+CRLF
				EndIf

				// número do lote
				If ( ! Empty(_QRYETIQ->D1_LOTECTL))
					_cTmpEtiq += "^FT45,204^A0N,25,24^FH\^FDLote: "+AllTrim(_QRYETIQ->D1_LOTECTL)+"^FS"+CRLF
				EndIf

				// posicao/endereco atual
				If ( ! Empty(mvCarga))
					_cTmpEtiq += "^FT406,217^A0N,28,28^FH\^FDCNTR: "+Transf(_QRYETIQ->Z16_ENDATU,"@R 99.A.99.99.99999")+"^FS"+CRLF
				EndIf

				// data da digitação da nota
				_cTmpEtiq += "^FT45,172^A0N,25,24^FH\^FDEnt.Doc.: "+DtoC(StoD(_QRYETIQ->F1_DTDIGIT))+"^FS"+CRLF

				// quantidades
				If (mvReimprime)
					_cTmpEtiq += "^FT406,139^A0N,25,24^FH\^FDQuant.: "+AllTrim(Str(_QRYETIQ->Z11_QTD1))+"/"+AllTrim(Str(_QRYETIQ->Z11_QTD2))+"^FS"+CRLF
				ElseIf (!mvReimprime)
					_cTmpEtiq += "^FT406,139^A0N,25,24^FH\^FDQuant.: "+AllTrim(Str(_nEtiq))+"/"+AllTrim(Str(_nQtdTotal))+"^FS"+CRLF
				EndIf

				// dados adicionais
				// ref cliente
				_cTmpEtiq += "^FT292,108^A0N,25,24^FH\^FDRef.: "+Substr(AllTrim(_cRefCliente),1,32)+"^FS"+CRLF
				// doc/serie
				_cTmpEtiq += "^FT44,140^A0N,25,24^FH\^FDDoc/S\82rie: "+AllTrim(_QRYETIQ->F1_DOC)+"/"+AllTrim(_QRYETIQ->F1_SERIE)+"^FS"+CRLF
				// programação
				_cTmpEtiq += "^FT45,107^A0N,25,24^FH\^FDPG: "+_QRYETIQ->F1_PROGRAM+"^FS"+CRLF
				// codetiq
				_cTmpEtiq += "^FT287,424^A0N,28,28^FH\^FD"+Transf(_cCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				// inf da etiqueta
				_cTmpEtiq += "^FT301,33^A0N,23,21^FH\^FDWMS.PRODUTO^FS"+CRLF
				// ordem de serviço
				_cTmpEtiq += "^FT524,62^A0N,23,21^FH\^FDOrd.Srv.: "+_QRYETIQ->Z05_NUMOS+"^FS"+CRLF
				// data da impressão
				_cTmpEtiq += "^FT525,33^A0N,23,21^FH\^FDDt.Imp.: "+DtoC(Date())+If(!mvReimprime,""," *"+AllTrim(Str(_QRYETIQ->Z11_QTDIMP))+"*")+"^FS"+CRLF
				// filiai
				_cTmpEtiq += "^FT300,61^A0N,23,21^FH\^FDFilial: "+AllTrim(SM0->M0_CODFIL)+"-"+AllTrim(SM0->M0_FILIAL)+"^FS"+CRLF
				// fecha etiqueta
				_cTmpEtiq += "^FO275,8^GB0,66,2^FS"+CRLF
				
				// Se for cliente SUMITOMO (000316)
				If (_QRYETIQ->F1_FORNECE == "000316")
				 	// imprime a etiqueta em duas vias
					_cTmpEtiq += "^PQ2,0,1,Y^XZ"+CRLF
				Else
					// para qualquer outra situação, somente em uma via
					_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
				Endif

				_cTmpEtiq += "^XA"+CRLF

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

				// incrementa quantidade de impressoes
				dbSelectArea("Z11")
				Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
				Z11->(dbSeek( xFilial("Z11")+_cCodEtiq ))
				RecLock("Z11")
				Z11->Z11_QTDIMP += 1
				MsUnLock()

			Next _nEtiq

			// proximo produto
			_QRYETIQ->(dbSkip())

		EndDo

		// fecha arquivo texto
		fClose(_nTmpHdl)

		// define o arquivo .BAT para execucao da impressao da etiqueta
		_cTmpBat := _cPathTemp+"wms_imp_etiq.bat"

		// grava o arquivo .BAT
		MemoWrit(_cTmpBat,"copy "+_cTmpArquivo+" "+_cImpSelec)

		// executa o comando (.BAT) para impressao
		If (_lImpressOk)
			WinExec(_cTmpBat)
		EndIf

	EndIf

Return(.t.)
