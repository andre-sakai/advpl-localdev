#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Importacao de Arquivo Financeiro (Senior)               !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 07/2016 !
+------------------+--------------------------------------------------------*/

User Function TFINA003()

	// dimensoes da tela
	local _aSizeWnd := MsAdvSize()

	// objetos da tela
	local _oDlgIntFin
	local _oSayArqTXT, _oSayVlrTot
	local _oGetArqTXT
	local _oPnlTop
	local _oBtnConf, _oBtnFile, _oBtnSai

	// arquivo selecionado
	Local _cArquivo	:= ""

	// campos do browse dos itens a importar
	private _aHdTitFin := {}
	private _cTrTitFin := ""
	private _aStTitFin := {}
	private _oBrwTitFin
	private _cAlTrTitFin := GetNextAlias()
	private _cMrcTitFin  := GetMark()

	// acao do botao confirma
	Private _bConfirma := {|| MsAguarde({|| sfGravaInt() },"Gravando dados...") }
	// acao do botao cancela
	Private _bCancel   := {|| _oDlgIntFin:End()}

	// valor total
	private _nVlrTotal := 0
	private _oGetVlrTot

	// diretorio local padrao
	private _cDirLocPdr := "c:\"

	// cria o arquivo de trabalho dos itens
	sfCriaTrb(.t.)

	// monta o dialogo
	_oDlgIntFin := MsDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"Integração Financeira Totvs x Senior",,,.F.,,,,,,.T.,,,.T. )
	_oDlgIntFin:lMaximized := .T.

	// cabecalho
	_oPnlTop := TPanel():New(000,000,,_oDlgIntFin,,.T.,.F.,,,040,040,,)
	_oPnlTop:Align := CONTROL_ALIGN_TOP

	// selecao do arquivo XML
	_oSayArqTXT := TSay():New(007,005,{|| "Arquivo Integração:" },_oPnlTop,,,,,,.T.,,,080,30)
	// get com o local do arquivo XML
	_oGetArqTXT := TGet():New(005,070,bSetGet(_cArquivo),_oPnlTop,230,10,"@!",,,,,,,.T.,,,{|| .F.})
	// botao para selecao do arquivo XML
	_oBtnFile := TButton():New(005,310, OemToAnsi("&Abrir...") ,_oPnlTop , {|| sfGetFile(@_cArquivo) }, 40,12,,,,.T.)
	// funcao para confirmar a importacao de dados
	_oBtnConf := TButton():New(005,360, OemToAnsi("&Importar Dados") ,_oPnlTop,{|| Eval(_bConfirma) },40,12,,,,.T.)
	// botão para fechar a tela
	_oBtnSai  := TButton():New(005,410, OemToAnsi("&Fechar") ,_oPnlTop,{|| Eval(_bCancel) },40,12,,,,.T.)

	// valor total
	_oSayVlrTot := TSay():New(022,005,{|| "Valor Total" },_oPnlTop,,,,,,.T.,,,080,30)
	// get com o valor total
	_oGetVlrTot := TGet():New(020,070,bSetGet(_nVlrTotal),_oPnlTop,060,10,PesqPict("SE2","E2_VALOR"),,,,,,,.T.,,,{|| .F.})

	// monta o browse com os itens da nota
	_oBrwTitFin := MsSelect():New((_cAlTrTitFin),"IT_SELEC",,_aHdTitFin,,_cMrcTitFin,{1,1,1,1},,,,,;
	{{"(_cAlTrTitFin)->IT_STATUS == 'DI'","DISABLE"},{"(_cAlTrTitFin)->IT_STATUS == 'OK'","ENABLE"},{"(_cAlTrTitFin)->IT_STATUS == 'IM'","BR_AMARELO"}})
	_oBrwTitFin:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwTitFin:bMark := {|| sfVldMark(_cMrcTitFin) }
	_oBrwTitFin:oBrowse:bAllMark := {|| sfMarkAll(_cMrcTitFin) }

	// ativa a tela
	Activate MSDialog _oDlgIntFin Centered

Return

// ** funcao para criar o arquivo de trabalho dos itens da nota
Static Function sfCriaTrb(mvFirst)

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)

		aAdd(_aStTitFin,{"IT_SELEC"    ,"C", 002                    , 000                  }) ; aAdd(_aHdTitFin,{"IT_SELEC"	 ,, " "             , ""})
		aAdd(_aStTitFin,{"IT_STATUS"   ,"C", 002                    , 000                  })
		aAdd(_aStTitFin,{"IT_CODINT"   ,"C", 003                    , 000                  }) ; aAdd(_aHdTitFin,{"IT_CODINT" ,, "Cód.Int."      , ""})
		aAdd(_aStTitFin,{"IT_DESCRI"   ,"C", 120                    , 000                  }) ; aAdd(_aHdTitFin,{"IT_DESCRI" ,, "Descrição"     , ""})
		aAdd(_aStTitFin,{"IT_PREFIXO"  ,"C", 003                    , 000                  }) ; aAdd(_aHdTitFin,{"IT_PREFIXO",, "Prefixo"       , ""})
		aAdd(_aStTitFin,{"IT_TIPO"     ,"C", 003                    , 000                  }) ; aAdd(_aHdTitFin,{"IT_TIPO"   ,, "Tipo"          , ""})
		aAdd(_aStTitFin,{"IT_CODFOR"   ,"C", TamSx3("A2_COD")[1]    , 000                  }) ; aAdd(_aHdTitFin,{"IT_CODFOR" ,, "Código"        , ""})
		aAdd(_aStTitFin,{"IT_LOJFOR"   ,"C", TamSx3("A2_LOJA")[1]   , 000                  }) ; aAdd(_aHdTitFin,{"IT_LOJFOR" ,, "Loja"          , ""})
		aAdd(_aStTitFin,{"IT_NOMFOR"   ,"C", TamSx3("A2_NOME")[1]   , 000                  }) ; aAdd(_aHdTitFin,{"IT_NOMFOR" ,, "Nome"          , ""})
		aAdd(_aStTitFin,{"IT_VENCTO"   ,"D", TamSx3("E2_VENCREA")[1], 000                  }) ; aAdd(_aHdTitFin,{"IT_VENCTO" ,, "Vencimento"    , ""})
		aAdd(_aStTitFin,{"IT_VALOR"    ,"N", TamSx3("E2_VALOR")[1]  , TamSx3("E2_VALOR")[2]}) ; aAdd(_aHdTitFin,{"IT_VALOR"  ,, "Valor"         , PesqPict("SE2","E2_VALOR")})
		aAdd(_aStTitFin,{"IT_CCD"      ,"C", TamSx3("E2_CCD")[1]    , TamSx3("E2_CCD")[2]})   ; aAdd(_aHdTitFin,{"IT_CCD"    ,, "Centro Custo"  , PesqPict("SE2","E2_CCD")  })
		aAdd(_aStTitFin,{"IT_ITEMD"    ,"C", TamSx3("E2_ITEMD")[1]  , TamSx3("E2_ITEMD")[2]}) ; aAdd(_aHdTitFin,{"IT_ITEMD"  ,, "Item Contábil" , PesqPict("SE2","E2_ITEMD")})
		aAdd(_aStTitFin,{"IT_DEBITO"   ,"C", TamSx3("E2_DEBITO")[1] , TamSx3("E2_DEBITO")[2]}); aAdd(_aHdTitFin,{"IT_DEBITO" ,, "Conta Contábil", PesqPict("SE2","E2_DEBITO")})
		aAdd(_aStTitFin,{"IT_LOG"      ,"C", 200                    , 000                  }) ; aAdd(_aHdTitFin,{"IT_LOG"    ,, "Log"           , "@!"})
		aAdd(_aStTitFin,{"IT_NRCONTR"  ,"C", 10                     , 000                  })
		aAdd(_aStTitFin,{"IT_CONTRAT"  ,"C", 20                     , 000                  }) ; aAdd(_aHdTitFin,{"IT_CONTRAT",, "Contrato"      , "@!"})
		aAdd(_aStTitFin,{"IT_OPERADO"  ,"C", 20                     , 000                  }) ; aAdd(_aHdTitFin,{"IT_OPERADO",, "Operadora"     , "@!"})

		// fecha alias do TRB
		If (Select(_cAlTrTitFin)<>0)
			(_cAlTrTitFin)->(dbSelectArea(_cAlTrTitFin))
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrTitFin := FWTemporaryTable():New(_cAlTrTitFin)
		_cTrTitFin:SetFields(_aStTitFin)
		_cTrTitFin:Create()

		// criacao de indice por OS
		IndRegua((_cAlTrTitFin),(_cTrTitFin:cIndexName),"IT_CODINT",,, "Indexando Arquivo de Trabalho")

	EndIf

	// limpa o conteudo do TRB
	If ( ! mvFirst )
		(_cAlTrTitFin)->(dbSelectArea(_cAlTrTitFin))
		(_cAlTrTitFin)->(__DbZap())
	EndIf

	//-- Abre o indice do Arquivo de Trabalho.
	(_cAlTrTitFin)->(dbSelectArea(_cAlTrTitFin))
	(_cAlTrTitFin)->(dbSetOrder(1))
	(_cAlTrTitFin)->(dbGoTop())

Return

// ** funcao para selecionar o arquivo XML a ser importado
Static Function sfGetFile(mvArquivo)

	// busca arquivo XML
	mvArquivo := cGetFile("Arquivo Financeiro|*.TXT", ("Selecione arquivo TXT"),,_cDirLocPdr,.f.,GETF_LOCALHARD + GETF_NETWORKDRIVE,.f.)

	// solicita confirmacao da importacao do arquivo
	If ( ! Empty(mvArquivo)).and.(MsgYesNo("Confirma a leitura e validação do arquivo " +AllTrim(mvArquivo)+ " ?"))
		// rotina para ler o arquivo TXT
		MsAguarde({|| sfVldArqui(mvArquivo) },"Validando dados...")
	EndIF

Return

// ** funcao para leitura do arquivo TXT e atualizacao do arquivo de trabalho
Static Function sfVldArqui(mvArquivo)

	// variaveis temporarias
	local _vLinha
	local _cTmpLinha
	// dados do log
	local _cDetLog := ""
	// status
	local _cStsAtu := ""
	// linha atual
	local _nLinAtu := 0

	// variavel temporaria para controle de marcacao do item
	local _cTmpMarca

	// codigo e descricao da integracao
	local _cCodInt
	local _cDscInt
	// prefixo
	local _cPrefTit
	// tipo
	local _cTipoTit
	// codigo, loja e nome do fornecedor
	local _cCodForn
	local _cLojForn
	local _cNomForn
	// data de vencimento
	local _dDtVencto
	// valor
	local _nVlrTit

	// consulta de titulo já existente
	local _cQry := ""

	// centro de custo
	local _cCenCusto
	// item contabil
	local _cItemCont
	// conta contabil
	local _cContaCon

	// tabela tipo de titulo
	local _cTabTipTit := PadR("05",2)

	// numero do contato
	local _cNrContr
	local _cContrato
	
	// operadora de frete
	local _cOperado

	// zera valor total
	_nVlrTotal := 0

	// zera dados do TRB
	sfCriaTrb(.f.)

	// abre o arquivo TXT
	FT_FUse(mvArquivo)
	FT_FGoTop()

	// varre todas as linhas do arquivo
	While ( ! FT_FEof() )

		// reinicia variaveis
		_cDetLog   := ""
		_cTmpMarca := _cMrcTitFin
		_cStsAtu   := "OK"
		_cCodInt   := ""
		_cDscInt   := ""
		_cPrefTit  := ""
		_cTipoTit  := ""
		_cCodForn  := ""
		_cLojForn  := ""
		_cNomForn  := ""
		_dDtVencto := CtoD("//")
		_nVlrTit   := 0
		_cCenCusto := ""
		_cItemCont := ""
		_cContaCon := ""
		_cNrContr  := ""
		_cContrato := ""
		_cOperado  := ""
		_cQry      := ""

		// extrai dados da linha posicionada
		_cTmpLinha := FT_FReadln()

		// descarta linhas em branco
		If (Empty(_cTmpLinha))
			// proxima linha
			FT_FSkip()
			// loop do while
			Loop
		EndIf

		// extrai e separa os dados da linha corrente
		_vLinha := Separa(_cTmpLinha,";")

		// controle de linha
		_nLinAtu ++

		// valida tamanho da linha
		If (Len(_vLinha) < 14)
			// mensagem
			_cDetLog   := "Os dados da linha "+AllTrim(Str(_nLinAtu))+" estão fora da configuração pré-estabelecida. Favor verificar o layout do arquivo."
			// zera vetor
			_vLinha    := {"","","","","","","","//",0,"","","","",""}
			// altera status
			_cStsAtu   := "DI"
			// controle de marcacao
			_cTmpMarca := ""

		EndIf

		// atualiza variaveis
		_cCodInt   := _vLinha[1]
		_cDscInt   := _vLinha[2]
		_cPrefTit  := _vLinha[3]
		_cTipoTit  := PadR(_vLinha[4],TamSx3("E2_TIPO")[1])
		_cCodForn  := PadR(_vLinha[5],TamSx3("A2_COD")[1])
		_cLojForn  := PadR(_vLinha[6],TamSx3("A2_LOJA")[1])
		_cNomForn  := _vLinha[7]
		_dDtVencto := CtoD(_vLinha[8])
		_nVlrTit   := Val(_vLinha[9])
		_cCenCusto := PadR(_vLinha[10],TamSx3("E2_CCD")[1])
		_cItemCont := PadR(_vLinha[11],TamSx3("E2_ITEMD")[1])
		_cContaCon := PadR(_vLinha[12],TamSx3("E2_DEBITO")[1])
		_cNrContr  := AllTrim(_vLinha[13])
		_cContrato := AllTrim(_vLinha[14])
		_cOperado  := AllTrim(_vLinha[16])

		// valida codigo de integracao
		If ( ! (AllTrim(_cCodInt) $ "01A/01B/01C/01D/01E/01F/01G/02A/03A/04A/04B/04C/04D/04E/04F/04G/04H/05A/05B") )
			// mensagem
			_cDetLog   := "Código de integração "+_cCodInt+" não permitido"
			// altera status
			_cStsAtu   := "DI"
			// controle de marcacao
			_cTmpMarca := ""

		EndIf

		// valida codigo do prefixo
		If ( AllTrim(_cPrefTit) <> "GPE" )
			// mensagem
			_cDetLog   := "Prefixo do título "+_cPrefTit+" não permitido"
			// altera status
			_cStsAtu   := "DI"
			// controle de marcacao
			_cTmpMarca := ""

		EndIf

		// valida tipo do titulo
		If ( ! (AllTrim(_cTipoTit) $ "131/132/ADI/FER/FGT/FOL/INS/RES/RPA/TX" ) )
			// mensagem
			_cDetLog   := "Tipo do título "+_cTipoTit+" não permitido"
			// altera status
			_cStsAtu   := "DI"
			// controle de marcacao
			_cTmpMarca := ""

		EndIf

		// verifica se o tipo do titulo esta cadastrado
		dbSelectArea("SX5")
		SX5->(dbSetOrder(1)) // 1-X5_FILIAL, X5_TABELA, X5_CHAVE
		If ! SX5->(dbSeek(xFilial("SX5")+_cTabTipTit+_cTipoTit))
			// mensagem
			_cDetLog   := "Tipo do título "+_cTipoTit+" não permitido"
			// altera status
			_cStsAtu   := "DI"
			// controle de marcacao
			_cTmpMarca := ""
		EndIf

		// valida o fornecedor
		DbSelectArea("SA2")
		SA2->( dbSetOrder(1) ) // 1-A2_FILIAL, A2_COD, A2_LOJA
		If ! SA2->( dbSeek( xFilial("SA2")+_cCodForn+_cLojForn ))
			// mensagem
			_cDetLog   := "Fornecedor "+_cCodForn+"/"+_cLojForn+" - "+AllTrim(_cNomForn)+" não encontrado"
			// altera status
			_cStsAtu   := "DI"
			// controle de marcacao
			_cTmpMarca := ""

		EndIf

		// valida data de vencimento
		If (Empty(_dDtVencto)).or.(_dDtVencto < dDataBase)
			// mensagem
			_cDetLog   := "Vencimento "+DtoC(_dDtVencto)+" do título fora do período permitido"
			// altera status
			_cStsAtu   := "DI"
			// controle de marcacao
			_cTmpMarca := ""

		EndIf

		// valida valor
		If (_nVlrTit <= 0)
			// mensagem
			_cDetLog   := "Valor inválido "+AllTrim(Transf(_nVlrTit,PesqPict("SE2","E2_VALOR")))
			// altera status
			_cStsAtu   := "DI"
			// controle de marcacao
			_cTmpMarca := ""

		EndIf

		// valida se o centro de custo existe
		DbSelectArea("CTT")
		CTT->( dbSetOrder(1) ) // 1-CTT_FILIAL, CTT_CUSTO
		If ! CTT->( dbSeek( xFilial("CTT")+_cCenCusto ))
			// mensagem
			_cDetLog   := "Centro de Custo "+_cCenCusto+" não cadastrado"
			// altera status
			_cStsAtu   := "DI"
			// controle de marcacao
			_cTmpMarca := ""

		EndIf

		// valida se o item contabil existe
		DbSelectArea("CTD")
		CTD->( dbSetOrder(1) ) // 1-CTD_FILIAL, CTD_ITEM
		If ! CTD->( dbSeek( xFilial("CTD")+_cItemCont )) .AND. (cEmpAnt != "03") //exceto FOUR que não usa item contabil
			// mensagem
			_cDetLog   := "Item Contábil "+_cItemCont+" não cadastrado"
			// altera status
			_cStsAtu   := "DI"
			// controle de marcacao
			_cTmpMarca := ""

		EndIf

		// valida se a conta contabil existe
		DbSelectArea("CT1")
		CT1->( dbSetOrder(1) ) // 1-CT1_FILIAL, CT1_CONTA
		If ! CT1->( dbSeek( xFilial("CT1")+_cContaCon ))
			// mensagem
			_cDetLog   := "Conta Contábil "+_cContaCon+" não cadastrada"
			// altera status
			_cStsAtu   := "DI"
			// controle de marcacao
			_cTmpMarca := ""

		EndIf

		// valida se o título já foi importado
		_cQry := "SELECT R_E_C_N_O_				 "
		_cQry += "FROM " + RetSqlTab("SE2")
		_cQry += "WHERE " + RetSqlCond("SE2")
		_cQry += "       AND E2_FORNECE = '" + _cCodForn + "'"
		_cQry += "       AND E2_TIPO =    '" + _cTipoTit + "'"
		_cQry += "       AND E2_PREFIXO = '" + _cPrefTit + "'"
		_cQry += "       AND E2_VALOR = " + Str(_nVlrTit) 
		_cQry += "       AND E2_VENCREA = " + DtoS(_dDtVencto)
		// valida viagem caso empresa = FOUR
		If (cEmpAnt == "03" .AND. _cTipoTit == "RPA" .AND. _cPrefTit == "GPE")
			_cQry += " AND E2_HIST = '" + _cOperado + "-" +_cContrato + "'  "
		Endif

		If ( !Empty(U_FTQuery(_cQry)) )
			// mensagem
			_cDetLog   := "Título já integrado ou existente no sistema"
			// altera status
			_cStsAtu   := "DI"
			// controle de marcacao
			_cTmpMarca := ""
		EndIf

		// grava os dados no TRB
		(_cAlTrTitFin)->(dbSelectArea(_cAlTrTitFin))
		(_cAlTrTitFin)->(RecLock(_cAlTrTitFin,.t.))
		(_cAlTrTitFin)->IT_SELEC   := _cTmpMarca
		(_cAlTrTitFin)->IT_STATUS  := _cStsAtu
		(_cAlTrTitFin)->IT_CODINT  := _cCodInt
		(_cAlTrTitFin)->IT_DESCRI  := _cDscInt
		(_cAlTrTitFin)->IT_PREFIXO := _cPrefTit
		(_cAlTrTitFin)->IT_TIPO    := _cTipoTit
		(_cAlTrTitFin)->IT_CODFOR  := _cCodForn
		(_cAlTrTitFin)->IT_LOJFOR  := _cLojForn
		(_cAlTrTitFin)->IT_NOMFOR  := _cNomForn
		(_cAlTrTitFin)->IT_VENCTO  := _dDtVencto
		(_cAlTrTitFin)->IT_CCD     := _cCenCusto

		if(cEmpAnt != "03") //se diferente de FOUR
			(_cAlTrTitFin)->IT_ITEMD   := _cItemCont 	//usa o item contabil lido do TXT
		Else				//se FOUR
			(_cAlTrTitFin)->IT_ITEMD   := "" 			//nao possui item contabil
		endIf

		(_cAlTrTitFin)->IT_DEBITO  := _cContaCon
		(_cAlTrTitFin)->IT_VALOR   := _nVlrTit
		(_cAlTrTitFin)->IT_LOG     := _cDetLog
		(_cAlTrTitFin)->IT_NRCONTR := _cNrContr
		(_cAlTrTitFin)->IT_CONTRAT := _cContrato
		(_cAlTrTitFin)->IT_OPERADO := _cOperado
		(_cAlTrTitFin)->(MsUnLock())

		// controle de valor total
		If (_cStsAtu == "OK")
			_nVlrTotal += _nVlrTit
		EndIf

		// proxima linha
		FT_FSkip()

	EndDo

	// fecha o arquivo
	ft_FUse()

	//-- Abre o indice do Arquivo de Trabalho.
	(_cAlTrTitFin)->(dbSelectArea(_cAlTrTitFin))
	(_cAlTrTitFin)->(dbSetOrder(1))
	(_cAlTrTitFin)->(dbGoTop())

Return

// ** funcao que grava os dados
Static Function sfGravaInt()
	// area atual
	Local _aAreaAtu := (_cAlTrTitFin)->(GetArea())

	// dados do titulo
	local _aDadTitPag := {}

	// novo numero do titulo de integracao
	local _cNovoNum
	Local _cQry

	// natureza (busca do cadastro de integracao padrao)
	local _cNaturTit

	// variaveis temporarias
	local _cQbrChv := ""
	
	// parcela
	Local _cParcTit := CriaVar("E2_PARCELA",.f.)

	// historico
	local _cHistTit

	// mensagem de confirmacao
	If ! MsgYesNo("Confirma a integração dos títulos selecionados?")
		Return(.f.)
	EndIf

	// varre todos os titulos disponiveis
	(_cAlTrTitFin)->(dbSelectArea(_cAlTrTitFin))
	(_cAlTrTitFin)->(dbGoTop())

	While (_cAlTrTitFin)->( ! Eof() )

		// zera variaveis
		_cHistTit := ""

		// verifica se o item esta selecionado
		If ( Empty((_cAlTrTitFin)->IT_SELEC) )
			// proximo item
			(_cAlTrTitFin)->(DbSkip())
			// loop do while
			Loop
		EndIf

		// natureza (busca do cadastro de integracao padrao)
		If ( _cQbrChv != (_cAlTrTitFin)->IT_CODINT )
			// natureza
			_cNaturTit := sfRetNat((_cAlTrTitFin)->IT_CODINT)
			// chave de controle
			_cQbrChv   := (_cAlTrTitFin)->IT_CODINT
		EndIf
		
		// FOUR usa historico com o numero da viagem
		If (cEmpAnt == "03")
			_cHistTit := AllTrim((_cAlTrTitFin)->IT_OPERADO) + "-" + AllTrim((_cAlTrTitFin)->IT_CONTRAT)
		EndIf

		// define novo numero de titulo
		_cQry := "SELECT MAX(E2_NUM) FROM " + RetSqlTab("SE2")
		_cQry += " WHERE " + RetSqlCond("SE2")
		_cQry += " AND E2_TIPO = '" + (_cAlTrTitFin)->IT_TIPO + "' AND E2_PREFIXO= '" + (_cAlTrTitFin)->IT_PREFIXO + "'"

		_cNovoNum := Soma1(U_FTQuery(_cQry))

		// define dados do titulo
		_aDadTitPag := {;
		{"E2_PREFIXO", (_cAlTrTitFin)->IT_PREFIXO, Nil},;
		{"E2_NUM"    , _cNovoNum                 , Nil},;
		{"E2_PARCELA", _cParcTit                 , Nil},;
		{"E2_TIPO"   , (_cAlTrTitFin)->IT_TIPO   , Nil},;
		{"E2_FORNECE", (_cAlTrTitFin)->IT_CODFOR , Nil},;
		{"E2_LOJA"   , (_cAlTrTitFin)->IT_LOJFOR , Nil},;
		{"E2_NATUREZ", _cNaturTit                , Nil},;
		{"E2_HIST"   , _cHistTit                 , Nil},;
		{"E2_EMISSAO", dDatabase                 , Nil},;
		{"E2_VENCTO" , (_cAlTrTitFin)->IT_VENCTO , Nil},;
		{"E2_VENCREA", (_cAlTrTitFin)->IT_VENCTO , Nil},;
		{"E2_VALOR"  , (_cAlTrTitFin)->IT_VALOR  , Nil},;
		{"E2_CCD"    , (_cAlTrTitFin)->IT_CCD    , Nil},;
		{"E2_ITEMD"  , (_cAlTrTitFin)->IT_ITEMD  , Nil},;
		{"E2_DEBITO" , (_cAlTrTitFin)->IT_DEBITO , Nil},;
		{"E2_MOEDA"  , 1                         , Nil} }

		// padroniza conforme dicionario de dados
		_aDadTitPag := FWVetByDic(_aDadTitPag, 'SE2', .f.)

		// reinicia variaveis da rotina automatica
		lMsErroAuto := .f.

		// executa rotina automatica de titulos a pagar
		MSExecAuto({|x,y,z| FINA050(x,y,z)},_aDadTitPag,,3) // 3-Inclusao

		// quando erro da rotina automatica
		If (lMsErroAuto)
			// apresenta erro
			MostraErro()
		Else
			// quanto ok, atualiza status
			(_cAlTrTitFin)->(RecLock(_cAlTrTitFin))
			(_cAlTrTitFin)->IT_SELEC  := Space(2)
			(_cAlTrTitFin)->IT_STATUS := "IM"
			(_cAlTrTitFin)->(MsUnLock())

		EndIf

		// proximo item
		(_cAlTrTitFin)->(dbSkip())
	EndDo

	// mensagem
	MsgInfo("Importação realizada. Favor consultar o status dos títulos.")

	// restaura area atual
	RestArea(_aAreaAtu)

REturn

// ** funcao que valida a marcacao do item
Static Function sfVldMark(mvMarca)

	// em caso divergencia, não aceita marcacao
	If ( (_cAlTrTitFin)->IT_STATUS != "OK" )
		// mantem o item desmarcado
		(_cAlTrTitFin)->(RecLock(_cAlTrTitFin))
		(_cAlTrTitFin)->IT_SELEC := Space(2)
		(_cAlTrTitFin)->(MsUnLock())
		// mensagem
		MsgInfo("Não é permitido a seleção de itens com divergência.")

	EndIf

	// atualiza o valor total
	sfAtuTotal()

Return(.t.)

// ** funcao que marca todos os itens quando clicar no header da coluna
Static Function sfMarkAll(mvMarca)
	// area atual
	Local _aAreaAtu := (_cAlTrTitFin)->(GetArea())

	// seleciona o arquivo de trabalho
	(_cAlTrTitFin)->(dbSelectArea(_cAlTrTitFin))
	(_cAlTrTitFin)->(dbGoTop())
	// atualiza o campo Ok
	DbEval({|| (_cAlTrTitFin)->(RecLock(_cAlTrTitFin)) ,;
	(_cAlTrTitFin)->IT_SELEC :=  IIf( ((_cAlTrTitFin)->IT_STATUS != "OK"), Space(2), IIf(Empty((_cAlTrTitFin)->IT_SELEC), mvMarca, Space(2)) ) ,;
	(_cAlTrTitFin)->(MsUnLock()) })

	// restaura area atual
	RestArea(_aAreaAtu)

	// atualiza o valor total
	sfAtuTotal()

Return(.t.)

// ** funcao que calcula os valores totais do radapé
Static Function sfAtuTotal()
	// area atual
	Local _aAreaAtu := (_cAlTrTitFin)->(GetArea())

	// zera variaveis
	_nVlrTotal := 0

	(_cAlTrTitFin)->(dbSelectArea(_cAlTrTitFin))
	(_cAlTrTitFin)->(dbGoTop())

	// varre todos os titulos
	While (_cAlTrTitFin)->(!Eof())

		// verifica se esta desmarcado
		If (Empty((_cAlTrTitFin)->IT_SELEC))
			// proximo item
			(_cAlTrTitFin)->(dbSkip())
			// loop do while
			Loop
		EndIf

		// atualiza valores
		_nVlrTotal += (_cAlTrTitFin)->IT_VALOR

		// proximo item
		(_cAlTrTitFin)->(dbSkip())
	EndDo

	// restaura area inicial
	RestArea(_aAreaAtu)

	// atualiza os campos
	_oGetVlrTot:Refresh()

Return(.t.)

// ** funcao que retorna a natureza
Static Function sfRetNat(mvCodInt)
	// variavel de retorno
	local _cRetNat := CriaVar("ED_CODIGO",.f.)

	// cadastro padrao de integracao GPE x FIN
	dbSelectArea("RC0")
	RC0->(dbSetOrder(1)) // 1-RC0_FILIAL, RC0_CODTIT, RC0_SEQUEN
	If RC0->(dbSeek( xFilial("RC0")+mvCodInt ))
		_cRetNat := RC0->RC0_NATURE
	EndIf

Return(_cRetNat)