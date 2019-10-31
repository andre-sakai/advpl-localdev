#Include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para impressao de etiquetas do WMS               !
!                  ! - Identificacao de volumes                              !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 07/2014 !
+------------------+--------------------------------------------------------*/

User Function TWMSR013(mvCliente, mvLoja, mvOperacao, mvCesv, mvEtqDe, mvEtqAte, mvQuant, mvLayout)
	// variavel de retorno
	local _lRet := .f.
	//FWTemporaryTable
	private _TRBITENS := GetNextAlias()
	private _oAlTrb

	// valores padroes
	Default mvOperacao := 1
	Default mvCesv     := CriaVar("ZZ_CESV", .f.)
	Default mvEtqDe    := "  "
	Default mvEtqAte   := "ZZ"
	Default mvQuant    := 0
	Default mvLayout   := 1

	// rotina para impressao dos dados
	Processa ({|| _lRet := sfImpressao(mvCliente, mvLoja, mvOperacao, mvCesv, mvEtqDe, mvEtqAte, mvQuant, mvLayout) },"Gerando etiquetas...")
	
Return(_lRet)

// ** funcao para impressao dos dados
Static Function sfImpressao(mvCliente, mvLoja, mvOperacao, mvCesv, mvEtqDe, mvEtqAte, mvQuant, mvLayout)

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

	// total geral de etiquetas
	local _nTotGeral := 0
	local _nTotImpre := 0

	// quantidade de etiquetas
	local _nQtdTotal := 0
	local _nEtiq := 0

	// referencia do cliente
	local _cRefCliente := ""

	// mascara container
	local _cMskCont := PesqPict("SZC","ZC_CODIGO")

	// perguntas
	local _cPerg := PadR("TWMSR013",10)
	local _aPerg := {}

	// codigo da etiqueta
	local _cCodEtiq := ""

	local _lOk := .f.
	local _cImpSelec := U_FtImpZbr()

	// arquivos temporarios
	local _cTmpArquivo, _cTmpBat, _nTmpHdl

	// estrutura do arquivo de trabalho
	local _aEstTrb := {}
	local _aHeadBrw := {}
	local _cMarcaBrw := GetMark()

	// controle dos itens a serem impressora
	local _cImpItem := ""

	// valida o arquivo gerado
	local _lImpressOk := .f.

	// centraliza tela
	local _lDlgCenter := (Type("_aSizeDlg")=="U")
	// largura da tela
	local _nDlgLarg := If(Type("_aSizeDlg")=="U",700,(_aSizeDlg[1]))
	// altura da tela
	local _nDlgAltu := If(Type("_aSizeDlg")=="U",300,(_aSizeDlg[2]))

	// controle para impressao de 2 etiquetas por 'pagina'
	local _lEtqSup := .f.
	local _lEtqInf := .f.

	// define se deve apresentar os parametros
	local _lShowParam := (mvCliente == Nil)

	// etiquetas avulsas
	local _nAvulsa := 0

	// controle das informacoes "Volume De->Ate (ex: 21 de 60)
	local _nVolDe  := 0
	local _nVolAte := 0

	// campo utilizado para calcula da quantidade total de etiquetas de volumes (por quantidade, por caixa ou por palete)
	local _cTpImpEtq := U_FtWmsParam("WMS_RECEBIMENTO_ETIQ_VOLUME_QUANT_IMPRESSAO", "C", "QUANT_ITEM_NOTA", .f., "", Nil, Nil, Nil, Nil)
	local _cCmpQuant := IIf(AllTrim(_cTpImpEtq) == "QUANT_ITEM_NOTA", "Z04_QUANT", "Z04_QTDPAL")

	// modelo etiqueta de volumes
	local _cLayoutEtq := U_FtWmsParam("WMS_LAYOUT_ETIQ_VOLUME", "C", "PADRAO", .f., "", Nil, Nil, Nil, Nil)
	local _lLayoutOk := .f.
	
	//Gustavo, SLA
	//medidas das etiquetas de 4 colunas
	local nXPEtiq	:= 200
	local nXTit		:= 55
	local nXCBar	:= 155
	local nXNum		:= 185
	local aEtiAvul	:= {}
	local aEtiCESV	:= {}

	// monta a lista de perguntas
	aAdd(_aPerg,{"Operação ?"    , "N", 1                      , 0, "C",{"CESV","Reimpressão","Avulso"},""})      //mv_par01
	aAdd(_aPerg,{"CESV ?"        , "C", TamSx3("ZZ_CESV")[1]   , 0, "G",,"",{{"X1_VALID","U_FtStrZero()"}}})      //mv_par02
	aAdd(_aPerg,{"Etiqueta de ?" , "C", TamSx3("Z11_CODETI")[1], 0, "G",,"",{{"X1_VALID","U_FtStrZero()"}}})      //mv_par03
	aAdd(_aPerg,{"Etiqueta Até ?", "C", TamSx3("Z11_CODETI")[1], 0, "G",,"",{{"X1_VALID","U_FtStrZero()"}}})      //mv_par04
	aAdd(_aPerg,{"Quantidade?"   , "N", 3                      , 0, "G",,""})                                     //mv_par05
	aAdd(_aPerg,{"Layout ?"      , "N", 1                      , 0, "C",{"1 Col/Etiqueta","2 Col/Etiqueta", "4 Col/Etiqueta"},""}) //mv_par06

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// solicita parametros
	If (_lShowParam)

		// abre os parametros
		If ! Pergunte(_cPerg, .t.)
			Return(.f.)
		EndIf

		// valida quantidade de etiquetas avulsas
		If (mv_par01 == 3).and.(mv_par05 == 0)
			U_FtWmsMsg("Para etiquetas avulsas, favor informar a quantidade.","ATENCAO")
			Return(.f.)
		EndIf

		// atualiza os parametros, quando for por rotina automatica (chamada externa)
	ElseIf ( ! _lShowParam )

		// cria os mv_par??
		Pergunte(_cPerg, .f.)

		// define conteudo
		mv_par01 := mvOperacao
		mv_par02 := mvCesv
		mv_par03 := mvEtqDe
		mv_par04 := mvEtqAte
		mv_par05 := mvQuant
		mv_par06 := mvLayout

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
		_cTmpArquivo := _cPathTemp+"wms_etiq_volume.txt"

		// cria e abre arquivo texto
		_nTmpHdl := fCreate(_cTmpArquivo)

		// testa se o arquivo de Saida foi Criado Corretamente
		If (_nTmpHdl == -1)
			MsgAlert("O arquivo de nome "+_cTmpArquivo+" nao pode ser executado! Verifique os parametros.","Atencao!")
			Return(.f.)
		Endif

		If (mv_par01 == 1) // Gerar novas etiquetas conforme CESV

			// posiciona no CESV
			dbSelectArea("SZZ")
			SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
			SZZ->(dbSeek( xFilial("SZZ")+mv_par02 ))

			// campo utilizado para calcula da quantidade total de etiquetas de volumes (por quantidade, por caixa ou por palete)
			_cTpImpEtq := U_FtWmsParam("WMS_RECEBIMENTO_ETIQ_VOLUME_QUANT_IMPRESSAO", "C", "QUANT_ITEM_NOTA", .f., "", SZZ->ZZ_CLIENTE, SZZ->ZZ_LOJA, Nil, Nil)
			// define campo
			If (AllTrim(_cTpImpEtq) == "QUANT_ITEM_NOTA")
				_cCmpQuant := "Z04_QUANT"
			ElseIf (AllTrim(_cTpImpEtq) == "QUANT_PALETE")
				_cCmpQuant := "Z04_QTDPAL"
			ElseIf (AllTrim(_cTpImpEtq) == "QTD_SEG_UM_ITEM_NOTA")
				_cCmpQuant := "Z04_QTSEGU"
			EndIf

			// modelo etiqueta de volumes por cliente
			_cLayoutEtq := U_FtWmsParam("WMS_LAYOUT_ETIQ_VOLUME", "C", "PADRAO", .f., "", SZZ->ZZ_CLIENTE, SZZ->ZZ_LOJA, Nil, Nil)
			// layout definido
			_lLayoutOk := .t.

			// define a estrutura do TRB
			aAdd(_aEstTrb,{"IT_OK"     , "C", 2                      , 0                      })
			aAdd(_aEstTrb,{"Z04_ITEMNF", "C", TamSx3("D1_ITEM")[1]   , 0                      })
			aAdd(_aEstTrb,{"Z04_PROD"  , "C", TamSx3("D1_COD")[1]    , 0                      })
			aAdd(_aEstTrb,{"D1_DESCRIC", "C", TamSx3("D1_DESCRIC")[1], 0                      })
			aAdd(_aEstTrb,{"Z04_QUANT" , "N", TamSx3("Z04_QUANT")[1] , TamSx3("Z04_QUANT")[2] })
			aAdd(_aEstTrb,{"Z04_QTDPAL", "N", TamSx3("Z04_QTDPAL")[1], TamSx3("Z04_QTDPAL")[2]})
			aAdd(_aEstTrb,{"Z04_QTSEGU", "N", TamSx3("Z04_QTSEGU")[1], TamSx3("Z04_QTSEGU")[2]})
			aAdd(_aEstTrb,{"LOTE_CTL"  , "C", TamSx3("Z04_LOTCTL")[1], 0                      })

			// define o header do browse
			aAdd(_aHeadBrw,{"IT_OK"     , Nil, "  "          , "@!"                        })
			aAdd(_aHeadBrw,{"Z04_ITEMNF", Nil, "Item NF"     , "@!"                        })
			aAdd(_aHeadBrw,{"Z04_PROD"  , Nil, "Produto"     , "@!"                        })
			aAdd(_aHeadBrw,{"D1_DESCRIC", Nil, "Descrição"   , "@!"                        })
			aAdd(_aHeadBrw,{"Z04_QUANT" , Nil, "Quantidade"  , PesqPict("Z04","Z04_QUANT") })
			aAdd(_aHeadBrw,{"Z04_QTDPAL", Nil, "Qtd. Paletes", PesqPict("Z04","Z04_QTDPAL")})
			aAdd(_aHeadBrw,{"Z04_QTSEGU", Nil, "Qtd. 2 UM", PesqPict("Z04","Z04_QTSEGU")})
			aAdd(_aHeadBrw,{"LOTE_CTL"  , Nil, "Lote"        , PesqPict("Z04","Z04_LOTCTL")})

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
			_cQryEtiq += "SELECT "
			// codigo e loja do cliente
			_cQryEtiq += "   Z04_CLIENT, Z04_LOJA, "
			// processo
			_cQryEtiq += "   Z04_PROCES IT_PROCES, "
			// nota fiscal e serie
			_cQryEtiq += "   Z04_NF IT_NF, Z04_SERIE IT_SERIE, "
			// container
			_cQryEtiq += "   ZZ_CNTR01, ZZ_CNTR02, "
			_cQryEtiq += "   Z04_TIPONF, Z04_ITEMNF, Z04_NUMSEQ, Z04_PROD, "
			_cQryEtiq += "CASE "
			_cQryEtiq += "  WHEN ( ( Z04_SEQKIT = ' ' ) OR ( Z04_SEQKIT != ' ' AND Z04_NUMSEQ != ' ' ) ) THEN (SELECT D1_DESCRIC FROM "+RetSqlName("SD1")+" SD1 WHERE "+RetSqlCond("SD1")+" AND D1_NUMSEQ = Z04_NUMSEQ) "
			_cQryEtiq += "  WHEN ( (Z04_SEQKIT != ' ' AND Z04_NUMSEQ = ' ') ) THEN (SELECT DISTINCT Z29_DSCKIT FROM "+RetSqlName("Z29")+" Z29 WHERE "+RetSqlCond("Z29")+" AND Z29_CODKIT = Z04_CODKIT) "
			_cQryEtiq += "END D1_DESCRIC, "
			_cQryEtiq += "   Z04_LOCAL, "
			_cQryEtiq += "   Z04_QUANT, "
			_cQryEtiq += " Z04_LASTRO, Z04_CAMADA, Z04_ADICIO, "
			_cQryEtiq += " Z04_SEQKIT, "
			_cQryEtiq += " Z04_CODKIT, "
			_cQryEtiq += " Z04_QTDPAL, "
			_cQryEtiq += " Z04_QTSEGU, "
			_cQryEtiq += " Z04_LOTCTL LOTE_CTL, "
			_cQryEtiq += " F1_DTDIGIT, "
			_cQryEtiq += " Z05_NUMOS "

			// itens de mercadoria por container/veiculo
			_cQryEtiq += " FROM "+RetSqlTab("Z04")

			// cabecalho da nota fiscal
			_cQryEtiq += "        LEFT JOIN "+RetSqlTab("SF1")
			_cQryEtiq += "               ON "+RetSqlCond("SF1")
			_cQryEtiq += "                  AND F1_DOC = Z04_NF "
			_cQryEtiq += "                  AND F1_SERIE = Z04_SERIE "
			_cQryEtiq += "                  AND F1_FORNECE = Z04_CLIENT "
			_cQryEtiq += "                  AND F1_LOJA = Z04_LOJA "
			_cQryEtiq += "                  AND F1_TIPO = Z04_TIPONF "

			// movimentacao de veiculo
			_cQryEtiq += "        LEFT JOIN "+RetSqlTab("SZZ")
			_cQryEtiq += "               ON "+RetSqlCond("SZZ")
			_cQryEtiq += "                  AND ZZ_CESV = Z04_CESV "

			// numero da ordem de servico
			_cQryEtiq += "        LEFT JOIN "+RetSqlTab("Z05")
			_cQryEtiq += "               ON "+RetSqlCond("Z05")
			_cQryEtiq += "                  AND Z05_CESV = Z04_CESV

			// filtro padrao
			_cQryEtiq += " WHERE "+RetSqlCond("Z04")
			// numero do CESV
			_cQryEtiq += " AND  Z04_CESV = '"+mv_par02+"' "
			// controle de Kit/volume
			_cQryEtiq += " AND ( "
			_cQryEtiq += "   (Z04_SEQKIT  = ' ' AND Z04_NUMSEQ != ' ') "
			_cQryEtiq += "   OR "
			_cQryEtiq += "   (Z04_SEQKIT != ' ' AND Z04_NUMSEQ = ' ') "
			_cQryEtiq += "   ) "
			// verifica se ja existe etiqueta para este processo/veiculo
			_cQryEtiq += " AND NOT EXISTS (SELECT Z11_CODETI FROM "+RetSqlTab("Z11")+" WHERE "+RetSqlCond("Z11")
			_cQryEtiq += " AND Z11_TIPO   = '04' "
			_cQryEtiq += " AND Z11_DOC    = Z04_NF     AND Z11_SERIE  = Z04_SERIE AND Z11_TIPONF = Z04_TIPONF AND Z11_CLIENT = Z04_CLIENT AND Z11_LOJA = Z04_LOJA "
			_cQryEtiq += " AND Z11_ITEMNF = Z04_ITEMNF AND Z11_CODPRO = Z04_PROD  AND Z11_NUMSEQ = Z04_NUMSEQ "
			_cQryEtiq += " AND Z11_CESV   = Z04_CESV "
			_cQryEtiq += " AND Z11_SEQKIT = Z04_SEQKIT "
			_cQryEtiq += " AND Z11_CODKIT = Z04_CODKIT) "
			// ordem dos dados
			_cQryEtiq += " ORDER BY Z04_NF, Z04_SERIE, Z04_ITEMNF "

			memowrit("c:\query\TWMSR013_selec_itens_nota.txt",_cQryEtiq)

			// alimenta o TRB
			SqlToTrb(_cQryEtiq,_aEstTrb,_TRBITENS)

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
						_cImpItem += (_TRBITENS)->Z04_ITEMNF+";"
					EndIf
					// proximo item
					(_TRBITENS)->(dbSkip())
				EndDo
			ElseIf (!_lOk)
				// fecha arquivo texto
				fClose(_nTmpHdl)
				Return(.f.)
			EndIf

		ElseIf (mv_par01 == 2) .OR. (mv_par01 == 3) // 2-reimpressao ou 3-avulso

			// se for avulso, gera etiquetas conforme quantidade
			If (mv_par01 == 3) .AND. (mv_par05 > 0)

				// loop para gerar novas etiquetas
				For _nAvulsa := 1 to mv_par05

					// conteudo passado como parametro
					_aTmpConteudo := {;
					""         ,;
					""         ,;
					""         ,;
					""         ,;
					""         ,;
					""         ,;
					""         ,;
					""         ,;
					""         ,;
					""         ,;
					""         ,;
					""         ,;
					_nAvulsa   ,;
					mv_par05    }

					// gera codigo da etiqueta 04-volume
					_cCodEtiq := U_FtGrvEtq("04",_aTmpConteudo)

					// define "Etiqueta De"
					If (_nAvulsa == 1)
						mv_par03 := _cCodEtiq
					EndIf

					// define "Etiqueta Ate"
					If (_nAvulsa == mv_par05)
						mv_par04 := _cCodEtiq
					EndIf

				Next _nAvulsa

			EndIf

			// monta query para buscar os dados
			_cQryEtiq := " SELECT Z11_PROCES IT_PROCES, Z11_DOC IT_NF, Z11_SERIE IT_SERIE, Z11_QTD1, Z11_QTD2, F1_DTDIGIT, ISNULL(ZZ_CNTR01,'') ZZ_CNTR01, D1_DESCRIC, "
			_cQryEtiq += " Z11_CODETI, (Z11_QTDIMP + 1) Z11_QTDIMP, "
			// endereco atual
			_cQryEtiq += " ISNULL((SELECT DISTINCT Z16_ENDATU "
			_cQryEtiq += " FROM "+RetSqlTab("Z16")
			_cQryEtiq += " WHERE "+RetSqlCond("Z16")+" AND Z16_ETQPRD = Z11_CODETI AND Z16_NUMSEQ = D1_NUMSEQ),'') Z16_ENDATU, "
			_cQryEtiq += " D1_LOTECTL LOTE_CTL, "
			_cQryEtiq += " Z05_NUMOS "
			// cadastro de etiquetas
			_cQryEtiq += " FROM "+RetSqlTab("Z11")
			// nota fiscal
			_cQryEtiq += " LEFT JOIN "+RetSqlTab("SF1")+" ON "+RetSqlCond("SF1")+" AND F1_DOC = Z11_DOC AND F1_SERIE = Z11_SERIE AND F1_TIPO = Z11_TIPONF "
			_cQryEtiq += " AND F1_FORNECE = Z11_CLIENT AND F1_LOJA = Z11_LOJA "
			// movimentacao de veiculo
			_cQryEtiq += " LEFT JOIN "+RetSqlTab("SZZ")+" ON "+RetSqlCond("SZZ")+" AND ZZ_CESV   = Z11_CESV "
			// ordem de servico
			_cQryEtiq += " LEFT JOIN "+RetSqlTab("Z05")+" ON "+RetSqlCond("Z05")+" AND Z05_CESV = ZZ_CESV "
			// itens da nota fiscal
			_cQryEtiq += " LEFT JOIN "+RetSqlTab("SD1")+" ON "+RetSqlCond("SD1")+" AND D1_NUMSEQ = Z11_NUMSEQ "
			// filtro padrao
			_cQryEtiq += " WHERE "+RetSqlCond("Z11")
			// filtro das etiquetas
			_cQryEtiq += " AND Z11_CODETI BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' "
			// somente tipo 04-volumes
			_cQryEtiq += " AND Z11_TIPO = '04' "
			// filtra pelo CESV se tiver sido informado e se o tipo de impressão for reimpressão
			If ( !Empty(mv_par02) ) .AND. ( mv_par01 == 2 )
				_cQryEtiq += " AND Z11_CESV = '"+mv_par02+"' "
			EndIf
			// ordem dos dados
			_cQryEtiq += " ORDER BY Z11_CODETI "

			memowrit("c:\query\TWMSR013_sfimpressao_etiq_"+AllTrim(Str(mv_par01))+".txt",_cQryEtiq)

		EndIf

		If Select("_QRYETIQ") <> 0
			dbSelectArea("_QRYETIQ")
			dbCloseArea()
		EndIf

		// executa a query
		dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQryEtiq),"_QRYETIQ",.F.,.T.)
		dbSelectArea("_QRYETIQ")

		If _QRYETIQ->( Eof() )
			// mensagem
			U_FtWmsMsg("Não há etiquetas para impressão.","ATENCAO")
			// fecha arquivo texto
			fClose(_nTmpHdl)
			// retorno
			Return(.f.)
		EndIf

		If (mv_par01 == 1)
			dbEval({|| _nTotGeral += IIf((_TRBITENS)->Z04_ITEMNF $ _cImpItem, (&(_cCmpQuant)), 0) })
		ElseIf (mv_par01 == 2).or.(mv_par01 == 3)
			dbEval({|| _nTotGeral += 1 })
		EndIf

		// quantidade total da regua de prcessamento
		ProcRegua(_nTotGeral)

		// seleciona alias
		dbSelectArea("_QRYETIQ")
		_QRYETIQ->(dbGoTop())

		// Impressão com duas colunas
		If (mv_par06 == 2)
			// define o conteudo inicial da etiqueta a ser impressa
			_cTmpEtiq := "CT~~CD,~CC^~CT~"+CRLF
			_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
			_cTmpEtiq += "~DG000.GRF,02304,012,"+CRLF
			_cTmpEtiq += ",:::L07FIF82C,L07FIF82A,L07FIF814,L07FIF8,L0K5H04,S02,R01C,R024,N050I04,M03FF,M07FFC03C,M0IFE028,L01FIF03E,L03FCFF0"
			_cTmpEtiq += ",L03F01F028,L03E00F82A,L07C00F83C,L07C00F8,L07C007814,L07C00F822,L07FIF824,L07FIF818,L07FIF8,:L07FIF804,R02A,R038,,P0183E,"
			_cTmpEtiq += "P0780C,O01F810,O0HF820,N07FF820,M01FHF02A,M0IFC038,L03FHFC0,L07FC3C020,L07F03C03A,L07FD3C024,L07FFBC002,L01FHFC004,M03FFE034,"
			_cTmpEtiq += "N07FF81C,N01FF802,O07F83C,P0F838,P01804,R020,M0307,M0F07801A,L01F07C02C,L03F07E028,L03F07F014,L07E01F002,L07C01F81C,L07800F834,"
			_cTmpEtiq += "L07800F80C,L07800F8,:L07C00F82A,L07C01F028,L03F03F02A,L03FDFF010,L01FHFE0,M0IFC002,M07FF001C,M01FC0034,S0E,,P0F824,L07C78F822,"
			_cTmpEtiq += "L07C78F83C,L07C78F8,L07C78F83E,L07C78F8,L07C78F820,L07C78F83C,L07C78F820,L07FIF814,L07FIF82A,L07FIF83A,L07FIF804,L07FIF87C,,S04,"
			_cTmpEtiq += "R02A,L07C0I020,L07E0I01C,:L07E0I0H2,L07C0I0H2,L07FIF822,L07FIF81C,L07FIF802,L07FIF8,L07FIF83E,L07E,:L07C,L07E,L054,,:::::O02E0,"
			_cTmpEtiq += "N07FC4,M07FF,L01FHF,L07FFE3F,L0IFC7FC0,K01FHFC7FF8,K01FHF8FHFC,K03FHF8FHFE,K07FHF1FIF,K07FHF1FIFC0,K07FHF01FHFC0,J02FIFE00FFE0,"
			_cTmpEtiq += "K0LFC1FF0,J04FLF81F8,J0DFMF03C,J0DFMFE0C,I01DFNFC4,I019FOF0,I039FOFC,I0H3PFE,I073FPF80,I073FPFC0,I073FPFE0,:I0H7RF0,I0E7FQF0,"
			_cTmpEtiq += "I067FQF0,I0E7FQF0,I067FQF0,I0EFQFE0,I06FQFE0,I06FHFE03FKFE0,I04FHFE001FJFE0,I06FHFE0H07FIFE0,I04FHFE7F007FHFE0,I04FHFE7FE00FHFE0,"
			_cTmpEtiq += "J0IFE7FFC01FFC0,J0IFE7FHF80FFC0,J0IFE7FHFE01FC0,J0IFE7FIF80FC0,J0IFE7FIFE07C0,J0IFE7FJF0380,J0IFE7FJF8180,J0IFE7FJFC180,J07FFE7FJFC180,"
			_cTmpEtiq += ":J07FFE7FJFC1,J03FFE7FJF80,J03FFE7FJF04,J01FFE7FIFC18,J01FFE7FIF8,K0HFE3FHFE0,K07FF1FHFC0,K01FF0FFC,L07F0140,L03F80,M0780,N0E0,,"
			_cTmpEtiq += ":::::::::::::::::::::~DG001.GRF,02304,012,"+CRLF
			_cTmpEtiq += ",::M040404,L01FIFE0A80,:L01FIFE05,L01FIFE04,L01FIFE0F80,S0180,S07,S0D,O080H0180,N07FC0,M03FHFH0F,M07FHF80A,M07FHFC0F80,M0HF5FC,"
			_cTmpEtiq += "M0F807E0A80,M0F003E0A,L01F003E0F80,L01F001E,L01F003E03,L01F001E08,L01F003E0880,L01FIFE07,L01FIFE,:L01FIFE01,S0A80,S0E80,S05,Q020F80,"
			_cTmpEtiq += "P01E01,P07E06,O01FE0F,O0HFE,N07FFE0A,M01FHFH0A80,M07FHFH0F,L01FF8F00880,L01FC0F00C,L01FE0F00B80,L01FFEF0,M07FHFH0180,N0IF80D,N01FFE07,"
			_cTmpEtiq += "O07FE01,O01FE,P07E0D,Q0E0180,S04,N041800F80,M01C1E00480,M03C1F00B,M07C1F80A,M0FC1FC0F80,L01F807C,L01F007E03,L01F003E0D,L01E003E07,"
			_cTmpEtiq += "L01E001E0080,L01E003E,L01F003E,L01F007E0A80,L01F807C0A80,M0FE3FC0F80,M07FHF8,M03FHF0,M01FFE001,N07F8009,O040H07,T080,S01,L01F023E0880,"
			_cTmpEtiq += "L01F1E3E0880,L01F1E3E07,L01F1E3E,:L01F1E3E08,L01F1E3E0F80,L01F1E3E08,L01FIFE,L01FIFE0F,L01FIFE0A80,L01FIFE05,L01FIFE,L015I541F,,S09,"
			_cTmpEtiq += "S0H80,L01F0J05,L01F80,L01F80I07,L01F80I0H80,L01FIFE08,L01FIFE07,L01FIFE,L01FIFE0080,L01FIFE05,L01F88080F80,L01F80,:L01F,L01F80,,"
			_cTmpEtiq += "::::::O0IF,N07FF080,M03FFC0,M0IF87,L03FHF8FE0,L07FHF1FF8,L07FFE3FFE,L0IFE3FHF,L0IFE3FHFC0,K01FHFC7FHFE0,K01FHFC7FIF0,K01FHFC05FHF8,"
			_cTmpEtiq += "K0BFJF01FFC,J013FKF01FC,J013FKFE07E,J037FLFC0F,J037FMF83,J067FNF0,J067FNFE,J0C7FOF,J0CFPFC0,I01CFQF0,I01CFQF8,:I01DFQFC,:I039FQFC,"
			_cTmpEtiq += "I019FQFC,I039FQFC,I019FQFC,I03BFQF8,I01BFQF8,I01BFHF80FLF8,I013FHF8007FJF8,I01BFHF8C00FJF8,I013FHF9FC01FIF8,J03FHF9FFC01FHF8,"
			_cTmpEtiq += "J03FHF9FHF807FF0,J03FHF9FHFE01FF0,J03FHF9FIFC07F0,J03FHF9FIFE03F0,J03FHF9FJF81F0,J03FHF9FJFC0E0,J03FHF9FJFE060,J03FHF9FKF060,"
			_cTmpEtiq += "J01FHF9FKF060,:J01FHF9FKF040,K0IF9FJFE0,K0IF9FJFC1,K07FF9FJF06,K07FF8FIFE,K01FF8FIF8,K01FFC7FHF0,L07FC3FF,L01FC050,M0FE0,M01E0,"
			_cTmpEtiq += "N038,,::::::::::::::::::::"+CRLF
			// grava a Linha no Arquivo Texto
			fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

			//Impressão com uma coluna
		ElseIf (mv_par06 == 1)
			// inicio da etiqueta
			_cTmpEtiq := "CT~~CD,~CC^~CT~"+CRLF
			_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
			// grava a Linha no Arquivo Texto
			fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))
		EndIf

		// reinicia variaveis
		_lEtqSup := .t.
		_lEtqInf := .f.
		nXTit	:= 55
		nXCBar	:= 155
		nXNum	:= 185
		aEtiAvul:= {}
		aEtiCESV:= {}
		// varre todos os itens
		While _QRYETIQ->(!Eof())

			// quanto for impressao, verifica os itens selecionados
			If (mv_par01 == 1)
				// verifica se o item esta selecionado
				If ( ! (_QRYETIQ->Z04_ITEMNF $ _cImpItem))
					_QRYETIQ->(dbSkip())
					Loop
				EndIf
			EndIf

			// define a quantidade para impressao
			If (mv_par01 == 1) // novas
				_nQtdTotal := _QRYETIQ->(&(_cCmpQuant))

			ElseIf (mv_par01 == 2) // reimpressao 
				_nQtdTotal := mv_par05
			Elseif (mv_par01 == 3) // etiqueta avulsa
				_nQtdTotal := 1
			EndIf

			// define controle das informacoes "Volume De->Ate (ex: 21 de 60)
			If (mv_par01 == 1) // novas
				_nVolDe  := _nEtiq
				_nVolAte := _nQtdTotal

			ElseIf (mv_par01 == 2).or.(mv_par01 == 3) // reimpressao ou avulsa
				_nVolDe  := _QRYETIQ->Z11_QTD1
				_nVolAte := _QRYETIQ->Z11_QTD2

			EndIf

			// define a referencia do cliente
			_cRefCliente := AllTrim(Posicione("SZ1",1, xFilial("SZ1")+_QRYETIQ->IT_PROCES ,"Z1_REFEREN"))

			// verifica se tem programacao, para definir layout conforme cliente
			If ( ! Empty(_QRYETIQ->IT_PROCES) ).and.( ! _lLayoutOk )

				// posiciona na programacao
				dbSelectArea("SZ1")
				SZ1->(dbSetOrder(1)) // 1-Z1_FILIAL, Z1_CODIGO
				SZ1->(dbSeek( xFilial("SZ1")+_QRYETIQ->IT_PROCES ))

				// modelo etiqueta de volumes por cliente
				_cLayoutEtq := U_FtWmsParam("WMS_LAYOUT_ETIQ_VOLUME", "C", "PADRAO", .f., "", SZ1->Z1_CLIENTE, SZ1->Z1_LOJA, Nil, Nil)
				// layout ok
				_lLayoutOk := .t.

			EndIf

			// executa impressao pela quantidade
			For _nEtiq := 1 to _nQtdTotal

				// incremento da regua
				IncProc()

				If (mv_par01 == 1) // novas

					// conteudo passado como parametro
					_aTmpConteudo := {;
					_QRYETIQ->Z04_CLIENT ,;
					_QRYETIQ->Z04_LOJA   ,;
					_QRYETIQ->IT_PROCES  ,;
					mv_par02             ,;
					_QRYETIQ->IT_NF      ,;
					_QRYETIQ->IT_SERIE   ,;
					_QRYETIQ->Z04_TIPONF ,;
					_QRYETIQ->Z04_ITEMNF ,;
					_QRYETIQ->Z04_PROD   ,;
					_QRYETIQ->Z04_NUMSEQ ,;
					_QRYETIQ->Z04_SEQKIT ,;
					_QRYETIQ->Z04_CODKIT ,;
					_nEtiq               ,;
					_nQtdTotal            }

					// gera codigo da etiqueta 04-volume
					_cCodEtiq := U_FtGrvEtq("04",_aTmpConteudo)

				ElseIf (mv_par01 == 2).or.(mv_par01 == 3) // reimpressao ou avulsa

					_cCodEtiq := _QRYETIQ->Z11_CODETI

				EndIf

				// define conteudo no arquivo
				_lImpressOk := .t.

				//Inico Lógica para impressão de duas colunas na etiqueta.
				If mv_par06 == 2
					If (_lEtqSup) // etiqueta superior

						// inicio de etiqueta
						_cTmpEtiq := "^XA"+CRLF
						_cTmpEtiq += "^MMT"+CRLF
						_cTmpEtiq += "^PW759"+CRLF
						_cTmpEtiq += "^LL0440"+CRLF
						_cTmpEtiq += "^LS0"+CRLF

						// conteudo da etiqueta superior
						_cTmpEtiq += "^FT0,448^XG000.GRF,1,1^FS"+CRLF
						_cTmpEtiq += "^BY2,3,116^FT343,365^BCB,,N,N"+CRLF
						_cTmpEtiq += "^FD>:"+_cCodEtiq+"^FS"+CRLF
						_cTmpEtiq += "^FO1,241^GB74,0,2^FS"+CRLF
						_cTmpEtiq += "^FO75,5^GB0,433,1^FS"+CRLF
						_cTmpEtiq += "^FT362,309^A0B,18,31^FH\^FD"+Transf(_cCodEtiq,"@R 99999-99999")+"^FS"+CRLF
						_cTmpEtiq += "^FT107,435^A0B,28,28^FH\^FDPG: "+_QRYETIQ->IT_PROCES+"^FS"+CRLF

						_cTmpEtiq += "^FT18,241^A0B,17,16^FH\^FDWMS.VOLUME^FS"+CRLF
						If ( ! Empty(_QRYETIQ->ZZ_CNTR01))
							_cTmpEtiq += "^FT211,434^A0B,28,28^FH\^FDCNTR: "+Transf(_QRYETIQ->ZZ_CNTR01,_cMskCont)+"^FS"+CRLF
						EndIf
						_cTmpEtiq += "^FT70,115^A0B,17,14^FH\^FDFilial: "+AllTrim(SM0->M0_CODFIL)+"-"+AllTrim(SM0->M0_FILIAL)+"^FS"+CRLF
						_cTmpEtiq += "^FT176,435^A0B,28,28^FH\^FDRef.: "+_cRefCliente+"^FS"+CRLF
						_cTmpEtiq += "^FT141,434^A0B,28,28^FH\^FDDoc/S\82rie: "+AllTrim(_QRYETIQ->IT_NF)+"/"+AllTrim(_QRYETIQ->IT_SERIE)+"^FS"+CRLF
						_cTmpEtiq += "^FT140,97^A0B,59,62^FH\^FD"+AllTrim(Str(_nVolDe))+"^FS"+CRLF
						_cTmpEtiq += "^FT180,96^A0B,24,31^FH\^FDDE "+AllTrim(Str(_nVolAte))+"^FS"+CRLF

						// controle de impressao
						_lEtqSup   := .f.
						_lEtqInf   := .t.
						_nTotImpre += 1

					ElseIf (_lEtqInf) // etiqueta inferior

						// conteudo da etiqueta inferior
						_cTmpEtiq += "^FT384,448^XG001.GRF,1,1^FS"+CRLF
						_cTmpEtiq += "^BY2,3,116^FT726,365^BCB,,N,N"+CRLF
						_cTmpEtiq += "^FD>:"+_cCodEtiq+"^FS"+CRLF
						_cTmpEtiq += "^FO384,241^GB74,0,2^FS"+CRLF
						_cTmpEtiq += "^FO379,13^GB0,415,1^FS"+CRLF
						_cTmpEtiq += "^FO458,5^GB0,433,1^FS"+CRLF
						If ( ! Empty(_QRYETIQ->ZZ_CNTR01))
							_cTmpEtiq += "^FT594,434^A0B,28,28^FH\^FDCNTR: "+Transf(_QRYETIQ->ZZ_CNTR01,_cMskCont)+"^FS"+CRLF
						EndIf
						_cTmpEtiq += "^FT490,434^A0B,28,28^FH\^FDPG: "+_QRYETIQ->IT_PROCES+"^FS"+CRLF
						_cTmpEtiq += "^FT401,240^A0B,17,16^FH\^FDWMS.VOLUME^FS"+CRLF
						_cTmpEtiq += "^FT559,434^A0B,28,28^FH\^FDRef.: "+_cRefCliente+"^FS"+CRLF
						_cTmpEtiq += "^FT744,309^A0B,18,31^FH\^FD"+Transf(_cCodEtiq,"@R 99999-99999")+"^FS"+CRLF
						_cTmpEtiq += "^FT524,434^A0B,28,28^FH\^FDDoc/S\82rie: "+AllTrim(_QRYETIQ->IT_NF)+"/"+AllTrim(_QRYETIQ->IT_SERIE)+"^FS"+CRLF
						_cTmpEtiq += "^FT453,115^A0B,17,14^FH\^FDFilial: "+AllTrim(SM0->M0_CODFIL)+"-"+AllTrim(SM0->M0_FILIAL)+"^FS"+CRLF
						_cTmpEtiq += "^FT523,97^A0B,59,62^FH\^FD"+AllTrim(Str(_nVolDe))+"^FS"+CRLF
						_cTmpEtiq += "^FT563,96^A0B,24,31^FH\^FDDE "+AllTrim(Str(_nVolAte))+"^FS"+CRLF

						// controle de impressao
						_lEtqSup   := .t.
						_lEtqInf   := .f.
						_nTotImpre += 1

					EndIf

					// se for a ultima etiqueta do item, inclui comando para encerrar
					If (_lEtqSup).or.(_nTotImpre == _nTotGeral)
						_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
					EndIf

					// grava a Linha no Arquivo Texto
					If (_lEtqSup).or.((!_lEtqSup).and.(_nEtiq == _nQtdTotal))
						fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))
					EndIf
					//Inico Lógica para impressão de uma coluna na etiqueta.
				ElseIf (mv_par06 == 1)

					// modelo padrao
					If (AllTrim(_cLayoutEtq) == "PADRAO")
						// inicio das informações por etiqueta
						_cTmpEtiq := "^XA"+CRLF
						_cTmpEtiq += "^MMT"+CRLF
						_cTmpEtiq += "^PW767"+CRLF
						_cTmpEtiq += "^LL0240"+CRLF
						_cTmpEtiq += "^LS0"+CRLF
						_cTmpEtiq += "^BY6,3,125^FT44,167^BCN,,N,N"+CRLF
						_cTmpEtiq += "^FD>;"+_cCodEtiq+"^FS"+CRLF
						_cTmpEtiq += "^FT158,206^A0N,34,76^FH\^FD"+_cCodEtiq+"^FS"+CRLF
						_cTmpEtiq += "^FT44,27^A0N,25,31^FH\^FDTECADI - Volume^FS"+CRLF
						_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
					ElseIf (AllTrim(_cLayoutEtq) == "ITEM_NOTA_COM_LOTE")
						// inicio das informações por etiqueta
						_cTmpEtiq := "^XA"+CRLF
						_cTmpEtiq += "^MMT"+CRLF
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
						_cTmpEtiq += "^FT45,239^A0N,25,24^FH\^FD"+Substr(AllTrim(_QRYETIQ->D1_DESCRIC),1,51)+"^FS"+CRLF
						_cTmpEtiq += "^FT45,271^A0N,25,24^FH\^FD"+Substr(AllTrim(_QRYETIQ->D1_DESCRIC),52,50)+"^FS"+CRLF

						// numero do container
						If ( ! Empty(_QRYETIQ->ZZ_CNTR01))
							_cTmpEtiq += "^FT406,172^A0N,25,24^FH\^FDCNTR: "+Transf(_QRYETIQ->ZZ_CNTR01,_cMskCont)+"^FS"+CRLF
						EndIf

						// número do lote
						If ( ! Empty(_QRYETIQ->LOTE_CTL))
							_cTmpEtiq += "^FT45,204^A0N,25,24^FH\^FDLote: "+AllTrim(_QRYETIQ->LOTE_CTL)+"^FS"+CRLF
						EndIf

						// data da digitação da nota
						_cTmpEtiq += "^FT45,172^A0N,25,24^FH\^FDEnt.Doc.: "+DtoC(StoD(_QRYETIQ->F1_DTDIGIT))+"^FS"+CRLF

						// quantidades
						If (mv_par01 == 2) // 2-Reimpressao
							_cTmpEtiq += "^FT406,139^A0N,25,24^FH\^FDQuant.: "+AllTrim(Str(_QRYETIQ->Z11_QTD1))+"/"+AllTrim(Str(_QRYETIQ->Z11_QTD2))+"^FS"+CRLF
						Else
							_cTmpEtiq += "^FT406,139^A0N,25,24^FH\^FDQuant.: "+AllTrim(Str(_nEtiq))+"/"+AllTrim(Str(_nQtdTotal))+"^FS"+CRLF
						EndIf

						// dados adicionais
						// ref cliente
						_cTmpEtiq += "^FT292,108^A0N,25,24^FH\^FDRef.: "+Substr(AllTrim(_cRefCliente),1,32)+"^FS"+CRLF
						// doc/serie
						_cTmpEtiq += "^FT44,140^A0N,25,24^FH\^FDDoc/S\82rie: "+AllTrim(_QRYETIQ->IT_NF)+"/"+AllTrim(_QRYETIQ->IT_SERIE)+"^FS"+CRLF
						// programação
						_cTmpEtiq += "^FT45,107^A0N,25,24^FH\^FDPG: "+_QRYETIQ->IT_PROCES+"^FS"+CRLF
						// codetiq
						_cTmpEtiq += "^FT287,424^A0N,28,28^FH\^FD"+Transf(_cCodEtiq,"@R 99999-99999")+"^FS"+CRLF
						// inf da etiqueta
						_cTmpEtiq += "^FT301,33^A0N,23,21^FH\^FDWMS.VOLUME^FS"+CRLF
						// ordem de serviço
						_cTmpEtiq += "^FT524,62^A0N,23,21^FH\^FDOrd.Srv.: "+_QRYETIQ->Z05_NUMOS+"^FS"+CRLF
						// data da impressão
						_cTmpEtiq += "^FT525,33^A0N,23,21^FH\^FDDt.Imp.: "+DtoC(Date())+"^FS"+CRLF
						// filiai
						_cTmpEtiq += "^FT300,61^A0N,23,21^FH\^FDFilial: "+AllTrim(SM0->M0_CODFIL)+"-"+AllTrim(SM0->M0_FILIAL)+"^FS"+CRLF
						// fecha etiqueta
						_cTmpEtiq += "^FO275,8^GB0,66,2^FS"+CRLF
						_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF

					EndIf

					// grava a Linha no Arquivo Texto
					fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

				//Gustavo, SLA
				// inicio das lógica para impressão com 4 colunas/etiquetas
				ElseIf (mv_par06 == 3)
					// impressão por CESV
					IF MV_PAR01 == 1

						AADD(aEtiCESV,_cCodEtiq)

					// impressão "avulsa" (gera novas)
					ElseIf MV_PAR01 == 3

						AADD(aEtiAvul,_cCodEtiq)

						//Proxima etiqueta
						_nEtiq++
						loop
					//Reimpressao
					Else
						_cTmpEtiq := ""
						_nNumEtiq := MV_PAR05
						For _nNext := 1 to _nNumEtiq
							//Cabeçalho etiqueta
							_cTmpEtiq += "CT~~CD,~CC^~CT~"+CRLF
							_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
							_cTmpEtiq += "^XA"+CRLF
							_cTmpEtiq += "^MMT"+CRLF
							_cTmpEtiq += "^PW900"+CRLF
							_cTmpEtiq += "^LL0350"+CRLF
							_cTmpEtiq += "^LS0"+CRLF
							
							nXTit	:= 55
							nXCBar	:= 155
							nXNum	:= 185
							
							//Corpo da etiqueta
							_cTmpEtiq += "^FT"+Str(nXTit)+",320^A0B,25,31^FH\^FDTECADI - Volume^FS"+CRLF
							_cTmpEtiq += "^BY3,3,90^FT"+Str(nXCBar)+",320^BCB,,N,N^FD>;"+_cCodEtiq+"^FS"+CRLF
							_cTmpEtiq += "^FT"+Str(nXNum)+",285^A0B,32,40^FH\^FD"+_cCodEtiq+"^FS"+CRLF
							
							/*If _nNext+1 <= _nNumEtiq
								_nNext++
							EndIf*/
							If _nNext >= _nNumEtiq
								//Fecha a etiqueta
								_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
								Exit
							EndIf
							nXTit	+= nXPEtiq
							nXCBar	+= nXPEtiq
							nXNum	+= nXPEtiq

							//Corpo da etiqueta
							_cTmpEtiq += "^FT"+Str(nXTit)+",320^A0B,25,31^FH\^FDTECADI - Volume^FS"+CRLF
							_cTmpEtiq += "^BY3,3,90^FT"+Str(nXCBar)+",320^BCB,,N,N^FD>;"+_cCodEtiq+"^FS"+CRLF
							_cTmpEtiq += "^FT"+Str(nXNum)+",285^A0B,32,40^FH\^FD"+_cCodEtiq+"^FS"+CRLF
							
							If _nNext+1 <= _nNumEtiq
								_nNext++
							EndIf
							If _nNext >= _nNumEtiq
								//Fecha a etiqueta
								_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
								Exit
							EndIf
							nXTit	+= nXPEtiq
							nXCBar	+= nXPEtiq
							nXNum	+= nXPEtiq

							//Corpo da etiqueta
							_cTmpEtiq += "^FT"+Str(nXTit)+",320^A0B,25,31^FH\^FDTECADI - Volume^FS"+CRLF
							_cTmpEtiq += "^BY3,3,90^FT"+Str(nXCBar)+",320^BCB,,N,N^FD>;"+_cCodEtiq+"^FS"+CRLF
							_cTmpEtiq += "^FT"+Str(nXNum)+",285^A0B,32,40^FH\^FD"+_cCodEtiq+"^FS"+CRLF
							
							If _nNext+1 <= _nNumEtiq
								_nNext++
							EndIf
							If _nNext >= _nNumEtiq
								//Fecha a etiqueta
								_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
								Exit
							EndIf
							nXTit	+= nXPEtiq
							nXCBar	+= nXPEtiq
							nXNum	+= nXPEtiq

							//Corpo da etiqueta
							_cTmpEtiq += "^FT"+Str(nXTit)+",320^A0B,25,31^FH\^FDTECADI - Volume^FS"+CRLF
							_cTmpEtiq += "^BY3,3,90^FT"+Str(nXCBar)+",320^BCB,,N,N^FD>;"+_cCodEtiq+"^FS"+CRLF
							_cTmpEtiq += "^FT"+Str(nXNum)+",285^A0B,32,40^FH\^FD"+_cCodEtiq+"^FS"+CRLF
							
							If _nNext+1 <= _nNumEtiq
								_nNext++
							EndIf
							//Fecha a etiqueta
							_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF

						Next _nNext
						_nEtiq := _nNumEtiq
						fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))
					EndIf
				EndIf
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

		//Fim do arquivo 2 colunas
		If (mv_par06 == 2)
			// final do arquivo texto
			_cTmpEtiq := "^XA^ID000.GRF^FS^XZ"+CRLF
			_cTmpEtiq += "^XA^ID001.GRF^FS^XZ"+CRLF
			// grava a Linha no Arquivo Texto
			fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))
		EndIf

		//Impressao da etiqueta avulsa 4 colunas
		If MV_PAR01 == 3 .And. MV_PAR06 == 3
			nAux := 1
			_cTmpEtiq := ""
			For nNumAv:=1 to Len(aEtiAvul)

				If nAux == 1
					//Cabeçalho etiqueta
					_cTmpEtiq += "CT~~CD,~CC^~CT~"+CRLF
					_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
					_cTmpEtiq += "^XA"+CRLF
					_cTmpEtiq += "^MMT"+CRLF
					_cTmpEtiq += "^PW900"+CRLF
					_cTmpEtiq += "^LL0350"+CRLF
					_cTmpEtiq += "^LS0"+CRLF
				EndIf
				//Corpo da etiqueta
				_cTmpEtiq += "^FT"+Str(nXTit)+",320^A0B,25,31^FH\^FDTECADI - Volume^FS"+CRLF
				_cTmpEtiq += "^BY3,3,90^FT"+Str(nXCBar)+",320^BCB,,N,N^FD>;"+aEtiAvul[nNumAv]+"^FS"+CRLF
				_cTmpEtiq += "^FT"+Str(nXNum)+",285^A0B,32,40^FH\^FD"+aEtiAvul[nNumAv]+"^FS"+CRLF
				
				If nAux == 4
					nAux := 0
					nXTit	:= 55
					nXCBar	:= 155
					nXNum	:= 185
					_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
					//Cabeçalho etiqueta
					_cTmpEtiq += "CT~~CD,~CC^~CT~"+CRLF
					_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
					_cTmpEtiq += "^XA"+CRLF
					_cTmpEtiq += "^MMT"+CRLF
					_cTmpEtiq += "^PW900"+CRLF
					_cTmpEtiq += "^LL0350"+CRLF
					_cTmpEtiq += "^LS0"+CRLF
				Else
					nXTit	+= nXPEtiq
					nXCBar	+= nXPEtiq
					nXNum	+= nXPEtiq
				EndIf

				If nNumAv == Len(aEtiAvul) .And. nAux != 4
					//Fecha a etiqueta
					_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
				EndIf
				nAux++
			Next nNumAv
			fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))
		EndIf

		////Impressao da etiqueta CESV 4 colunas
		IF MV_PAR01 == 1 .And. mv_par06 == 3

			nTotDiv := Len(aEtiCESV)/4
			nTotDiv := Ceiling(nTotDiv)
			xYz := 1
			_cTmpEtiq := ""
			For X := 1 to nTotDiv
				//Cabeçalho etiqueta
				_cTmpEtiq += "CT~~CD,~CC^~CT~"+CRLF
				_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
				_cTmpEtiq += "^XA"+CRLF
				_cTmpEtiq += "^MMT"+CRLF
				_cTmpEtiq += "^PW900"+CRLF
				_cTmpEtiq += "^LL0350"+CRLF
				_cTmpEtiq += "^LS0"+CRLF
				nXTit	:= 55
				nXCBar	:= 155
				nXNum	:= 185
				For Y:=1 to 4
					//Corpo da etiqueta
					_cTmpEtiq += "^FT"+Str(nXTit)+",320^A0B,25,31^FH\^FDTECADI - Volume^FS"+CRLF
					_cTmpEtiq += "^BY3,3,90^FT"+Str(nXCBar)+",320^BCB,,N,N^FD>;"+aEtiCESV[xYz]+"^FS"+CRLF
					_cTmpEtiq += "^FT"+Str(nXNum)+",285^A0B,32,40^FH\^FD"+aEtiCESV[xYz]+"^FS"+CRLF
					nXTit	+= nXPEtiq
					nXCBar	+= nXPEtiq
					nXNum	+= nXPEtiq
					If xYz == Len(aEtiCESV)
						Exit
					EndIf
					xYz++
				Next Y
				//Final da etiqueta
				_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
			Next X
			fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))
		endif

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
	
	// fecha tabela temporaria
	If ValType(_oAlTrb) == "O"
		_oAlTrb:Delete()
	EndIf

Return(.T.)