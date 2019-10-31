#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Informar informações adicionais no Pedido de venda.     !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe José Limas        ! Data de Criacao ! 20/03/2015 !
+------------------+--------------------------------------------------------*/

User Function TWMSA022()

	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaSC5 := SC5->(GetArea())

	// dimensoes da tela
	local _aSizeWnd := MsAdvSize()

	// objetos da tela
	local _oDlgDados, _oDlgImport
	local _oGetAgrup, _oGetPedid, _oGetClien, _oGetEstad, _oGetCidad, _oGetEndEnt, _oBtnSair,  _oBtnImpXml
	local _oBtnOk, _oBtnCanc, _oGetNota, _oBtnFile
	local _oBmpSair
	local _oPnl01Cabec

	// tipo de arquivo selecionado
	Private _cTipoArq := ""

	//Fontes utilizadas
	Private _oFonte01 := TFont():New("Verdana",,18,,.T.)

	//Variaveis para manipulação das informações
	Private _cAgrupa   := ""
	Private _cPedCli   := ""
	Private _cCliente  := ""
	Private _cEstado   := ""
	Private _cCidade   := ""
	Private _cEndEntre := ""
	Private _cNotaCli  := ""

	// mensagem de erro
	Private _cErroLog := ""

	//Variavel contendo o caminho do arquivo XML no servidor abaixo do Rootpath.
	Private _cArqSer := ""

	// controle da estrutura do XML
	// 1. Versao 1.10 : _oXML:_NFEPROC:_NFE:_INFNFE
	// 2. Versao 2.00 : _oXML:_NFE:_INFNFE
	private _cBaseXML := ""

	// controle de permite processamento
	private _lProcOk := .T.

	// bloco executado no botao CONFIRMA
	Private _bConfirma := {|| MsAguarde({|| AtuaXmlPed() }, "Atualizando Informações...")}

	// campos do browse das ordens de servico
	private _aHdArqXml := {}
	private _aCoArqXml := {}
	private _oBrwArqXml

	// objetos de cores para usar na coluna de status do grid
	Private _oVerde    := LoadBitmap( GetResources(), "BR_VERDE"   )
	Private _oVermelho := LoadBitmap( GetResources(), "BR_VERMELHO")
	Private _oAmarelo  := LoadBitmap( GetResources(), "BR_AMARELO" )

	//Tela para definir o tipo de arquivo que sera importado
	If ( ! sfDefTpArq() )
		// restaura area atual
		RestArea(_aAreaSC5)
		RestArea(_aAreaAtu)
		Return(.F.)
	EndIf

	//Se for escolhido importar arquivo XML.
	If (_cTipoArq == "XML")

		// define colunas do browse
		Aadd(_aHdArqXml, {""                 , "IMAGEM"  , "@BMP",  3, 0, ".F.", "", "C", "", "V", "", "", "", "V"})
		Aadd(_aHdArqXml, {"Nome Arquivo"     , "ARQ_NOME", "@!"  ,210, 0, ""   , "", "C", "", "R", "", "", "", Nil})
		Aadd(_aHdArqXml, {"Log Processamento", "ARQ_LOG" , "@!"  , 10, 0, ""   , "", "M", "", "R", "", "", "", Nil})

		// monta o dialogo do monitor
		_oDlgImport := MSDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"Atualização de Dados Adicionais para WMS",,,.F.,,,,,,.T.,,,.T. )
		_oDlgImport:lMaximized := .T.

		// cria o panel do cabecalho (opcoes da pesquisa)
		_oPnl01Cabec := TPanel():New(000,000,nil,_oDlgImport,,.F.,.F.,,,000,030,.T.,.F. )
		_oPnl01Cabec:Align:= CONTROL_ALIGN_TOP

		// botao para selecao do arquivo
		_oBtnFile := TButton():New(007,005,"&Adiciona " + _cTipoArq, _oPnl01Cabec,{|| fGetFile() } ,040,015,,,,.T.,,"",,,,.F. )

		// funcao para validar os dados do XML
		_oBtnImpXml := TButton():New(007,055,"&Importar",_oPnl01Cabec,{|| Eval(_bConfirma) },040,015,,,,.T.)

		// define o botao Sair
		_oBmpSair := TBtnBmp2():New(001,001,040,040,"FINAL",,,,{|| _oDlgImport:End() },_oPnl01Cabec,"Sair",,.T. )
		_oBmpSair:Align := CONTROL_ALIGN_RIGHT

		// browse com a listagem dos arquivos
		_oBrwArqXml := MsNewGetDados():New(000, 000, _aSizeWnd[6], _aSizeWnd[5], Nil, 'AllwaysTrue()', 'AllwaysTrue()', '',,,Len(_aCoArqXml),'AllwaysTrue()','','AllwaysTrue()',_oDlgImport,_aHdArqXml,_aCoArqXml)
		_oBrwArqXml:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// ativa a tela
		ACTIVATE MSDIALOG _oDlgImport CENTERED

		//Se for escolhido atualizar pedido Posicionado.
	ElseIf (_cTipoArq == "PED")
		_cAgrupa   := SC5->C5_ZAGRUPA
		_cPedCli   := SC5->C5_ZPEDCLI
		_cCliente  := SC5->C5_ZCLIENT
		_cEstado   := SC5->C5_ZUFENTR
		_cCidade   := SC5->C5_ZCIDENT
		_cEndEntre := SC5->C5_ZENDENT
		_cNotaCli  := SC5->C5_ZDOCCLI

		// monta a tela principal
		_oDlgDados  := MSDialog():New( 136,233,470,566,"Informações Adicionais WMS",,,.F.,,,,,,.T.,,,.T. )
		_oGetAgrup  := TGet():New( 005,004,{|u| If(PCount()>0,_cAgrupa:=u   ,_cAgrupa )}    , _oDlgDados,125,008,'@!',,,,,,,.T.,"",,{|| .F. },.F.,.F.,,.F.,.F.,""  ,"_cAgrupa"  ,,,,,, .T. ,"Agrupadora"     , 1 )
		_oGetPedid  := TGet():New( 025,004,{|u| If(PCount()>0,_cPedCli:=u   ,_cPedCli )}    , _oDlgDados,125,008,'@!',,,,,,,.T.,"",,{|| .T. },.F.,.F.,,.F.,.F.,""  ,"_cPedCli"  ,,,,,, .T. ,"Pedido Cliente" , 1 )
		_oGetClien  := TGet():New( 045,004,{|u| If(PCount()>0,_cCliente:=u  ,_cCliente)}    , _oDlgDados,125,008,'@!',,,,,,,.T.,"",,{|| .T. },.F.,.F.,,.F.,.F.,""  ,"_cCliente" ,,,,,, .T. ,"Nome Cliente"   , 1 )
		_oGetEstad  := TGet():New( 065,004,{|u| If(PCount()>0,_cEstado:=u   ,_cEstado )}    , _oDlgDados,125,008,'@!',,,,,,,.T.,"",,{|| .T. },.F.,.F.,,.F.,.F.,"12","_cEstado"  ,,,,,, .T. ,"Estado"         , 1 )
		_oGetCidad  := TGet():New( 085,004,{|u| If(PCount()>0,_cCidade:=u   ,_cCidade )}    , _oDlgDados,125,008,'@!',,,,,,,.T.,"",,{|| .T. },.F.,.F.,,.F.,.F.,""  ,"_cCidade"  ,,,,,, .T. ,"Cidade"         , 1 )
		_oGetEndEnt := TGet():New( 105,004,{|u| If(PCount()>0,_cEndEntre:=u ,_cEndEntre )}  , _oDlgDados,125,008,'@!',,,,,,,.T.,"",,{|| .T. },.F.,.F.,,.F.,.F.,""  ,"_cEndEntre",,,,,, .T. ,"Endereço"       , 1 )
		_oGetNota   := TGet():New( 125,004,{|u| If(PCount()>0,_cNotaCli:=u  ,_cNotaCli)}    , _oDlgDados,125,008,'@!',,,,,,,.T.,"",,{|| .T. },.F.,.F.,,.F.,.F.,""  ,"_cNotaCli" ,,,,,, .T. ,"Nº Nota Fiscal" , 1 )

		// botoes
		_oBtnOk   := TButton():New( 150, 008, "Gravar"   , _oDlgDados,{|| U_WMSA022A(Nil, Nil, _cAgrupa, _cPedCli, _cNotaCli, _cCliente, _cCidade, _cEstado, _cEndEntre, Nil, Nil, Nil, Nil), _oDlgDados:End() } ,40,010,,,.F.,.T.,.F.,,.F.,,,.F. )
		_oBtnCanc := TButton():New( 150, 052, "Cancelar" , _oDlgDados,{|| _oDlgDados:End() }             ,40,010,,,.F.,.T.,.F.,,.F.,,,.F. )

		// ativa tela
		_oDlgDados:Activate(,,,.T.)
	EndIf

	// restaura area atual
	RestArea(_aAreaSC5)
	RestArea(_aAreaAtu)

Return

// ** funcao que processa todos os XML selecionados
Static Function AtuaXmlPed()

	Local _nArqAtu  := 0
	Local _cTmpArq	:= "" // nome do arquivo
	Local _cTmpExt	:= "" // extensao do arquivo
	Local _cTmpDir  := "" // Diretotio do Arquivo
	Local _cTmpDri  := "" // Drive do Arquivo
	Local _lRet     := .T.
	local _lLogErro := .F.

	// valida se o processamento foi executado
	If ( ! _lProcOk )
		Help(,,'Help',,"Processamento já executado. Realize novo acesso à rotina.",1,0)
		Return(.F.)
	EndIf

	// validacao de arquivos selecionados
	If (Len(_aCoArqXml) == 0)
		Aviso("TWMSA022 -> sfGravDoc","Nenhum arquivo selecionado para importação.",{"Fechar"})
		Return(.F.)
	EndIf

	// varre todos os arquivos selecionados
	For _nArqAtu := 1 to Len(_aCoArqXml)

		// reinicia variaveis por arquiv
		_cErroLog := ""
		_lRet     := .T.

		//Funcao para Atualizar os pedidos de Venda.
		MsAguarde({|| _lRet := sfAtualPed(_aCoArqXml[_nArqAtu][2]) },"Atualizando dados...")

		//Divide um caminho de disco completo em todas as suas subpartes (drive, diretório, nome e extensão).
		SplitPath(_aCoArqXml[_nArqAtu][2], @_cTmpDri, @_cTmpDir, @_cTmpArq, @_cTmpExt)
		// exclui o arquivo
		FErase(_cArqSer + _cTmpArq + _cTmpExt)

		//Se o pedido foi atualizado sem erros Acrescenta 'OK_' no inicio do arquivo.
		If (_lRet)
			// renomeia arquivo
			fRename(_cTmpDri + _cTmpDir + _cTmpArq + _cTmpExt , _cTmpDri + _cTmpDir + "OK_"+_cTmpArq + _cTmpExt)
			// atualiza browse
			_aCoArqXml[_nArqAtu][1] := _oVerde
			_aCoArqXml[_nArqAtu][3] := _cErroLog
			//Se ocorreu erros na atualização acrescenta 'Erro_' no inicio do arquivo.
		ElseIf ( ! _lRet )
			// renomeia arquivo
			fRename(_cTmpDri + _cTmpDir + _cTmpArq + _cTmpExt , _cTmpDri + _cTmpDir + "Erro_"+_cTmpArq + _cTmpExt)
			// atualiza browse
			_aCoArqXml[_nArqAtu][1] := _oVermelho
			_aCoArqXml[_nArqAtu][3] := _cErroLog
			// log geral
			_lLogErro := .T.
		EndIf

	Next _nArqAtu

	//Setar array do aCols do Objeto.
	_oBrwArqXml:SetArray(_aCoArqXml, .T.)

	//Atualizo as informações no grid
	_oBrwArqXml:Refresh()

	// se ocorreu algum erro, apresenta mensagem
	If ( _lLogErro )
		// mensagem
		Help(,,'Help',,"Processamento concluído com ERRO(S). Favor verificar o Log de cada arquivo processado.",1,0)
	ElseIf ( ! _lLogErro )
		Help(,,'Help',,"Processamento concluído com SUCESSO!",1,0)
	EndIf

	// controle de processmento geral
	_lProcOk := .F.

Return()

// ** Tela para definir o tipo de arquivo a ser utilizado na atualização.
Static Function sfDefTpArq()

	local _oDlgOpcoes, _oBtnXML, _oBtnTXT, _oBtnSair
	local _lFixaMain := .F.

	// definicao da tela
	_oDlgOpcoes := MSDialog():New(000,000,200,218,"Opções de Arquivos",,,.F.,,,,,,.T.,,,.T. )
	// opcoes de arquivos
	_oBtnXML := TButton():New(010,010,"Arquivo XML",_oDlgOpcoes,{|| _lFixaMain := .T. , _cTipoArq := "XML" , _oDlgOpcoes:End() },090,020,,_oFonte01,,.T.,,"",,,,.F. )
	_oBtnTXT := TButton():New(040,010,"Pedido"     ,_oDlgOpcoes,{|| _lFixaMain := .T. , _cTipoArq := "PED" , _oDlgOpcoes:End() },090,020,,_oFonte01,,.T.,,"",,,,.F. )
	// botao para sair
	_oBtnSair  := TButton():New(070,010,"Sair",_oDlgOpcoes,{|| _oDlgOpcoes:End() },090,020,,_oFonte01,,.T.,,"",,,,.F. )
	// ativa o dialogo
	_oDlgOpcoes:Activate(,,,.T.,)

Return(_lFixaMain)

// ** Funcao para selecionar a pasta com os arquivos a ser atualizado.
Static Function fGetFile()

	// variavel com os Arquivos XML para ser Atualizados.
	local _aFilesImp := {}

	//Local da Pasta com os Arquivos *.XML
	Local _cArquivo := cGetFile("Notas Fiscais de Venda|*." + _cTipoArq, ("Selecione a Pasta..."),,,.T.,(GETF_LOCALHARD+GETF_RETDIRECTORY),.F.)

	// variaveis temporarias
	Local _nX := 0

	// Pega todos os arquivos XML da pasta selecionada.
	_aFilesImp := Directory(_cArquivo + "*.xml")

	// se tem arquivos, zera listagem atual
	If (Len(_aFilesImp) != 0)
		// limpa o conteudo do TRB
		_aCoArqXml := {}
	EndIf

	// varre todos os arquivo da pasta
	For _nX :=  1 To Len(_aFilesImp)

		// copia o arquivo para o servidor
		sfCopiaArq(_cArquivo + _aFilesImp[_nX][1])

		// inclui arquivo na lsitagem
		aAdd(_aCoArqXml, {_oAmarelo, _cArquivo + _aFilesImp[_nX][1], "", .F.} )

	Next _nX

	//Setar array do aCols do Objeto.
	_oBrwArqXml:SetArray(_aCoArqXml, .T.)

	//Atualizo as informações no grid
	_oBrwArqXml:Refresh()

Return()

// ** Funcao que copia o arquivo local para o servidor
Static Function sfCopiaArq(mvArquivo)

	// cria os diretorios necessarios
	MakeDir("\tecadi")
	MakeDir("\tecadi\" + _cTipoArq)
	MakeDir("\tecadi\" + _cTipoArq + "\temp")

	// atualiza caminho completo do diretorio temporario
	_cArqSer := "\tecadi\" + _cTipoArq + "\temp\"

	// copia o arquivo do local para o servidor
	CpyT2S(mvArquivo, _cArqSer, .F.)

Return(.T.)

// ** Funcao para atualizar os pedidos do XML selecionados.
Static Function sfAtualPed(mvArquivo)
	//Variavel controle de erro na Função.
	Local _lRet := .T.

	Local _cTmpArq	:= "" // nome do arquivo
	Local _cTmpExt	:= "" // extensao do arquivo
	Local _cTmpDir  := "" // Diretotio do Arquivo
	Local _cTmpDri  := "" // Drive do Arquivo

	// mensagens retornadas da funcao XmlParserFile
	local _cError := ""
	local _cWarning := ""
	// chave da NFe para consulta do status no SEFAZ
	local _cNfvChave := ""
	// CNPJ temporario do Cliente
	local _cTmpCnpj := ""
	// numero da nota e serie
	local _cNfvNrNota, _cNfvSerie
	// valor da nota fiscal de venda
	local _nNfvVlrTot := 0
	// data de emissao da nota fiscal de venda
	local _dNfvDtEmis := CtoD("//")
	// CNPJ do cliente da nota fiscal de venda
	local _cNfvCnpj := ""
	// nome do cliente da nota fiscal de venda
	local _cNfvNomCli := ""
	// cidade do cliente da nota fiscal de venda
	local _cNfvCidEnt := ""
	// UF do cliente da nota fiscal de venda
	local _cNfvUfEnt := ""
	// endereco do cliente da nota fiscal de venda
	local _cNfvEndEnt := ""

	// Marcar Pocição da String
	Local _nPosI := 0
	Local _nPosF := 0

	//chave de pesquisa para buscar numero do Pedido na String.
	Local _cChvPesq := ""

	// controle se permite emitir etiquetas sem nota fiscal de retorno
	local _lEtqSemNfRet := .F.

	// controle se necessario validar os dados da nota fiscal de venda x pedido
	local _lVldPedNota := .F.

	// seek
	local _cSeekSC5

	// valida de pedido encontrado
	local _lPedLocaliz := .F.

	//Divide um caminho de disco completo em todas as suas subpartes (drive, diretório, nome e extensão).
	SplitPath(mvArquivo, @_cTmpDri, @_cTmpDir, @_cTmpArq, @_cTmpExt)

	// abertura do arquivo XML e estrutura do objeto
	_oXML := XmlParserFile(_cArqSer + _cTmpArq + _cTmpExt, "_", @_cError, @_cWarning )

	// verifica erros no XML
	If (ValType(_oXML) != "O")
		_cErroLog += "Falha ao gerar Objeto XML : " + _cError + " / " + _cWarning + CRLF
		_oXML  := Nil
		_lRet  := .F.
		Return(_lRet)
	Endif

	//Monta a base da estrutura do XML de acordo com a versao
	//Versao 1.10
	If (Type("_oXML:_NFEPROC:_NFE") == "O")
		_cBaseXML := "_oXML:_NFEPROC:_NFE:"
		//Versao 2.00
	ElseIf (Type("_oXML:_NFE") == "O")
		_cBaseXML := "_oXML:_NFE:"
		//Erro
	Else
		_cErroLog += "Erro na estrutura do arquivo XML."+ CRLF
		_lRet  := .F.
		Return(_lRet)
	EndIf

	// Retorno do CNPJ
	_cTmpCnpj := &(_cBaseXML + "_INFNFE:_EMIT:_CNPJ:TEXT")

	//Se o CNPJ estiver em branco
	If (Empty(_cTmpCnpj))
		_cErroLog += "Não foi possível localizar o CNPJ do cliente no arquivo XML !" + CRLF
		_lRet  := .F.
		Return(_lRet)
	Else
		//Pesquisa o cliente
		dbSelectArea("SA1")
		SA1->(dbSetOrder(3)) //3-A1_FILIAL, A1_CGC
		If ( ! SA1->(dbSeek(xFilial("SA1") + _cTmpCnpj )))
			_cErroLog += "Cliente com CNPJ " + Transf(_cTmpCnpj, PesqPict("SA1","A1_CGC")) + " não cadastrado." + CRLF
			_lRet  := .F.
			Return(_lRet)
		Else

			// controle se permite emitir etiquetas sem nota fiscal de retorno
			_lEtqSemNfRet := U_FtWmsParam("WMS_EXPEDICAO_ETIQUETA_PACKING_SEM_NOTA_RETORNO", "L", .T., .F. , "", SA1->A1_COD, SA1->A1_LOJA, Nil, Nil)

			// verifica a chave de pesquisa por cliente
			_cChvPesq := U_FtWmsParam("WMS_PEDIDO_PREFIXO_CHAVE_PEDIDO_CLIENTE", "C", "", .F., "", SA1->A1_COD, SA1->A1_LOJA, Nil, Nil)
			// padroniza em maiusculo
			_cChvPesq := Upper(_cChvPesq)

			// controle se necessario validar os dados da nota fiscal de venda x pedido
			_lVldPedNota := U_FtWmsParam("WMS_PEDIDO_VALIDA_DADOS_PEDIDO_X_NOTA_VENDA", "L", .F., .F. , "", SA1->A1_COD, SA1->A1_LOJA, Nil, Nil)

			// Verifica se chave de pesquisa não esta em branco.
			If ( ! Empty(_cChvPesq) )

				// Prepara e padroniza o numero e serie da nota
				_cNfvNrNota := StrZero(Val(&(_cBaseXML+"_INFNFE:_IDE:_NNF:TEXT")),(Len(SF2->F2_DOC)))
				_cNfvSerie  := AllTrim(&(_cBaseXML+"_INFNFE:_IDE:_SERIE:TEXT"))

				// Informaçoes Adicionais para pegar o Pedido de Venda.
				_cInfoAdi := _oXML:_NFEPROC:_NFE:_INFNFE:_INFADIC:_INFCPL:TEXT
				_cPedCli  := ""

				// busca valor total da venda
				_nNfvVlrTot := Val(&(_cBaseXML + "_INFNFE:_TOTAL:_ICMSTOT:_VPROD:TEXT"))

				// busca data de emissao da nota fiscal venda
				_dNfvDtEmis := &(_cBaseXML+"_INFNFE:_IDE:_DHEMI:TEXT")
				_dNfvDtEmis := SubStr(_dNfvDtEmis, 1, 10)

				// converte a data (Str to Date)
				_dNfvDtEmis := StoD(StrTran(_dNfvDtEmis,"-",""))

				// cnpj do cliente da nota fiscal de venda
				If ( Type(_cBaseXML + "_INFNFE:_DEST:_CNPJ:TEXT") == "C" )
					_cNfvCnpj := &(_cBaseXML + "_INFNFE:_DEST:_CNPJ:TEXT")
				ElseIf ( Type(_cBaseXML + "_INFNFE:_DEST:_CNPJ:TEXT") == "C" )
					_cNfvCnpj := &(_cBaseXML + "_INFNFE:_DEST:_CPF:TEXT")
				EndIf

				// nome do cliente da nota fiscal de venda
				_cNfvNomCli := &(_cBaseXML + "_INFNFE:_DEST:_XNOME:TEXT")

				// cidade do cliente da nota fiscal de venda
				_cNfvCidEnt := &(_cBaseXML + "_INFNFE:_DEST:_ENDERDEST:_XMUN:TEXT")

				// UF do cliente da nota fiscal de venda
				_cNfvUfEnt := &(_cBaseXML + "_INFNFE:_DEST:_ENDERDEST:_UF:TEXT")

				// endereco do cliente da nota fiscal de venda
				// endereco + numero
				_cNfvEndEnt := &(_cBaseXML+"_INFNFE:_DEST:_ENDERDEST:_XLGR:TEXT")
				_cNfvEndEnt += ", "
				_cNfvEndEnt += &(_cBaseXML+"_INFNFE:_DEST:_ENDERDEST:_NRO:TEXT")
				// complemento de endereco
				If (Type(_cBaseXML + "_INFNFE:_DEST:_ENDERDEST:_XCPL:TEXT") == "C")
					_cNfvEndEnt += " " + &(_cBaseXML+"_INFNFE:_DEST:_ENDERDEST:_XCPL:TEXT")
				EndIf

				// chave da nota fiscal de venda
				If (Type("_oXML:_NFEPROC:_PROTNFE:_INFPROT:_CHNFE:TEXT")=="C")
					// chave da nota
					_cNfvChave := _oXML:_NFEPROC:_PROTNFE:_INFPROT:_CHNFE:TEXT
					// se nao encontrou no campo especifico, tenta em outro
				ElseIf (Type("_oXML:_NFE:_INFNFE:_ID:TEXT")=="C")
					// chave da nota
					_cNfvChave := SubStr(_oXML:_NFE:_INFNFE:_ID:TEXT,4)
				EndIf

				// busca posição inicial atraves da chave de pesquisa para busca do Pedido do Cliente
				_nPosI    := AT(_cChvPesq, Upper(_cInfoAdi))
				_cInfoAdi := AllTrim(Substr(_cInfoAdi, _nPosI + Len(_cChvPesq)))
				_nPosF    := AT(" ", _cInfoAdi)
				_nPosF    := IIf(_nPosF == 0, Len(_cInfoAdi), _nPosF - 1)
				
				// carrega array dos itens da nota
				_aItXml := &(_cBaseXML + "_INFNFE:_DET")

				// se nao conseguiu carrega os itens corretamente
				If ( ValType(_aItXml) <> "A")
					_aItXml := {}
					aAdd(_aItXml, &(_cBaseXML + "_INFNFE:_DET"))
					
					If XmlChildEx ( _oXML:_NFEPROC:_NFE:_INFNFE:_DET:_PROD , "_XPED" ) != Nil
						_cNumPedCli := _aItXml[1]:_PROD:_XPED:TEXT
					Else
						_cNumPedCli := ''
					Endif
					
				Elseif XmlChildEx ( _oXML:_NFEPROC:_NFE:_INFNFE:_DET[1]:_PROD , "_XPED" ) != Nil
					_cNumPedCli := _aItXml[1]:_PROD:_XPED:TEXT
				Else
					_cNumPedCli := ''
				Endif
				
				//Se não encontrou na tag XPED nem na chave de busca (parâmetro configurado na Z30), então retorna erro.
				If Empty(_cNumPedCli) .and. (_nPosI == 0)
					_cErroLog += "Não encontrado chave de pesquisa para busca de Nº Pedido no XML." + CRLF
					_lRet  := .F.
					Return(_lRet)
				Else
					// define o numero do Pedido do cliente para incluir no pedido de venda
					// (prioriza a tag XPED do XML)
					If !(Empty(_cNumPedCli))
						_cPedCli := _cNumPedCli
					Else
						_cPedCli := Substr(_cInfoAdi, 1,_nPosF)
						_cPedCli := PadR(_cPedCli, TamSx3("C5_ZPEDCLI")[1])
					Endif

					//Pesquisa pedido de venda
					dbSelectArea("SC5")
					SC5->(DbOrderNickName("SC50000001")) // C5_FILIAL+C5_ZPEDCLI

					// Verifica se encontra pedido para fazer a atualização.
					If SC5->(dbSeek( _cSeekSC5 := xFilial("SC5") + _cPedCli ))

						// verifica se é do mesmo cliente
						While (SC5->( ! Eof() )) .And. ( AllTrim(SC5->C5_FILIAL + SC5->C5_ZPEDCLI) == _cSeekSC5)

							// valida se é o mesmo cliente
							If (SC5->C5_CLIENTE == SA1->A1_COD) .And. (SC5->C5_LOJACLI == SA1->A1_LOJA)

								// valida de pedido encontrado
								_lPedLocaliz := .T.

								// valida se o pedido ja esta faturado
								If ( Empty(SC5->C5_NOTA) ) .And. ( ! _lEtqSemNfRet )
									_cErroLog += "Pedido de venda " + AllTrim(_cPedCli) + " não faturado." + CRLF
									_lRet  := .F.
									Return(_lRet)
								EndIf

								// valida se os dados ja foram informados anteriormente
								If ( ! Empty(SC5->C5_ZDOCCLI) )
									_cErroLog += "Pedido de venda " + AllTrim(_cPedCli) + " com documento fiscal já informado." + CRLF
									_lRet  := .F.
									Return(_lRet)
								EndIf

								// verifica necessidade de validar dados do pedido x nota (redmine #86)
								If (_lRet) .And. (_lVldPedNota)

									// funcao para validacao de dados
									If ( ! (_lRet := sfVldGeral(_cTmpArq)) )
										Return(_lRet)
									EndIf

								EndIf

								// Chama função para gravar Informações Adicionais do cliente, no pedido de venda.
								U_WMSA022A( SC5->C5_FILIAL, SC5->C5_NUM , Nil, Nil, _cNfvNrNota, _cNfvNomCli, _cNfvCidEnt, _cNfvUfEnt, _cNfvEndEnt, _nNfvVlrTot, _dNfvDtEmis, _cNfvCnpj, _cNfvChave)

								// atualiza log
								_cErroLog += "Atualizado com sucesso" + CRLF
							EndIf

							// proximo pedido
							SC5->(dbSkip())
						EndDo

					EndIf

					// se nao localizou o pedido para o cliente
					If ( ! _lPedLocaliz )
						_cErroLog += "Pedido de venda " + AllTrim(_cPedCli) + " não encontrado na Base de dados para este cliente." + CRLF
						_lRet  := .F.
						Return(_lRet)

					EndIf

				EndIf
			Else
				_cErroLog += "Cliente com CNPJ " + AllTrim(Transf(_cTmpCnpj, PesqPict("SA1","A1_CGC"))) + " Sem chave de pesquisa cadastrada." + CRLF
				_lRet  := .F.
				Return(_lRet)
			EndIf
		Endif
	EndIf

Return(_lRet)

// ** Função para gravar Informações Adicionais do cliente, no pedido de venda.
User Function WMSA022A(mvCodFil, mvNumero, mvCodAgrup, mvNrPedCli, mvNfVenda, mvCliEnt, mvCidEnt, mvEstEnt, mvEndEnt, mvNfvValor, mvDtEmisNfv, mvNfvCnpj, mvNfvChave)

	// armazena area inicial
	local _aAreaSC5 := SC5->(GetArea())

	// chamada externa
	local _lChaExterna := (mvCodFil != Nil) .And. (mvNumero != Nil)

	local _lLibSemNF := U_FtWmsParam("WMS_LIBERA_CARREGAMENTO_SEM_NF_VENDA","L",.F.,.F.,Nil, SC5->C5_CLIENTE, SC5->C5_LOJACLI, Nil, Nil)

	// valores padroes
	Default mvCodAgrup  := CriaVar("C5_ZAGRUPA",.F.)
	Default mvNrPedCli  := CriaVar("C5_ZPEDCLI",.F.)
	Default mvNfVenda   := CriaVar("C5_ZDOCCLI",.F.)
	Default mvCliEnt    := CriaVar("C5_ZCLIENT",.F.)
	Default mvCidEnt    := CriaVar("C5_ZCIDENT",.F.)
	Default mvEstEnt    := CriaVar("C5_ZUFENTR",.F.)
	Default mvEndEnt    := CriaVar("C5_ZENDENT",.F.)
	Default mvNfvValor  := CriaVar("C5_ZNFVVLR",.F.)
	Default mvDtEmisNfv := CriaVar("C5_ZEMINFV",.F.)
	Default mvNfvCnpj   := CriaVar("C5_ZCGCENT",.F.)
	Default mvNfvChave  := CriaVar("C5_ZCHVNFV",.F.)

	// se for chamada externa
	If (_lChaExterna) .And. (SC5->C5_FILIAL != mvCodFil) .And. (SC5->C5_NUM != mvNumero)
		// cabecalho do pedido de venda
		dbSelectArea("SC5")
		SC5->(dbSetOrder(1)) // 1-C5_FILIAL, C5_NUM
		If ! SC5->(dbSeek( mvCodFil + mvNumero ))
			Return(.F.)
		EndIf
	EndIf

	// atualiza os dados
	RecLock("SC5",.F.)

	If ( ! Empty(mvCodAgrup) )
		SC5->C5_ZAGRUPA := mvCodAgrup
	EndIf

	If ( ! Empty(mvCidEnt) )
		SC5->C5_ZCIDENT := mvCidEnt
	EndIf

	If ( ! Empty(mvCliEnt) )
		SC5->C5_ZCLIENT := mvCliEnt
	EndIf

	If ( ! Empty(mvEstEnt) )
		SC5->C5_ZUFENTR := mvEstEnt
	EndIf

	If ( ! Empty(mvEndEnt) )
		SC5->C5_ZENDENT := mvEndEnt
	EndIf

	// aceita informacoes complementares somente quanto o pedido esta faturado
	If ( ! Empty(SC5->C5_NOTA) .OR. !(_lLibSemNF) ) .And. ( ! Empty(mvNfVenda) )
		SC5->C5_ZDOCCLI := mvNfVenda

		// insere o log
		U_FtGeraLog(cFilAnt, "SC5", SC5->(C5_FILIAL+C5_NUM), "Informado documento fiscal "+AllTrim(mvNfVenda)+" para o pedido", "WMS")

	EndIf

	If ( ! Empty(mvNrPedCli) )
		SC5->C5_ZPEDCLI := mvNrPedCli

		// insere o log
		U_FtGeraLog(cFilAnt, "SC5", SC5->(C5_FILIAL+C5_NUM), "Informado pedido do cliente " + AllTrim(mvNrPedCli) + " para o pedido", "WMS")

	EndIf

	// atualiza valor total da nota fiscal de venda do cliente
	If (mvNfvValor != 0)
		SC5->C5_ZNFVVLR := mvNfvValor
	EndIf

	// atualiza data emissao da nota fiscal de venda do cliente
	If ( ! Empty(mvDtEmisNfv) )
		SC5->C5_ZEMINFV := mvDtEmisNfv
	EndIf

	// atualiza CNPJ cliente nota fiscal de venda do cliente
	If ( ! Empty(mvNfvCnpj) )
		SC5->C5_ZCGCENT := mvNfvCnpj
	EndIf

	// atualiza CHAVE nota fiscal de venda do cliente
	If ( ! Empty(mvNfvChave) )
		SC5->C5_ZCHVNFV := mvNfvChave
	EndIf

	SC5->(MsUnLock())

	// atualiza status da OS de carregamento
	If ( ! Empty(SC5->C5_NOTA) ) .And. ( ! Empty(SC5->C5_ZDOCCLI) )

		// funcao que atualiza o status da OS de carregamento
		sfAtuStsOS()

	EndIf

	// apresenta mensagem quando for tela de interface com usuario
	If ( ! _lChaExterna)
		ApMsgAlert("Informações Atualizadas")
	EndIf

	// restaura area inicial
	RestArea(_aAreaSC5)

Return(.T.)

// ** funcao que atualiza o status da OS de carregamento
Static Function sfAtuStsOS()

	// query
	local _cQuery

	// dados da OS atual
	local _aDadosOS := {}

	// data e hora de emissao
	local _dDtEmissao := Date()
	local _cHrEmissao := Time()

	// endereco de servico da atividade de conferencia
	local _cTmpEndSrv := ""

	// retorna o proximo servico, tarefa e atividades planejada da OS
	// 1-Num OS
	// 2-Seq OS
	// 3-Cod Servico
	// 4-Dsc Servico
	// 5-Cod Tarefa
	// 6-Dsc Tarefa
	// 7-Funcao/Rotina
	local _aPrxServico := {}

	// monta a query para buscar a sequencia da OS do servicos de montagem de volumes
	_cQuery := " SELECT DISTINCT Z43_NUMOS, Z06_SEQOS, Z06_ENDSRV, Z06_STATUS, Z06_SERVIC, Z06_TAREFA, Z06_ATUEST "
	// itens liberados do pedido
	_cQuery += " FROM " + RetSqlTab("SC9")
	// cab. da OS
	_cQuery += " INNER JOIN " + RetSqlTab("Z43") + " ON " + RetSqlCond("Z43") + " AND Z43_CARGA = C9_CARGA AND Z43_PEDIDO = C9_PEDIDO AND Z43_STATUS = 'P' "
	// itens da OS (Servicos e Tarefas)
	_cQuery += " INNER JOIN " + RetSqlTab("Z06") + " ON " + RetSqlCond("Z06") + " AND Z06_NUMOS = Z43_NUMOS AND Z06_SERVIC = '001' AND Z06_TAREFA = '007' "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("SC9")
	// filtro do nr pedido
	_cQuery += " AND C9_PEDIDO = '" + SC5->C5_NUM + "' "
	// ordem dos dados
	_cQuery += " ORDER BY Z06_SEQOS "

	// dados da OS atual
	_aDadosOS := U_SqlToVet(_cQuery)

	// valida dados
	If (Len(_aDadosOS)==0)
		//U_FtWmsMsg("Erro na liberação da OS de Carregamento!","ATENCAO")
		Return(.F.)
	EndIf

	// endereco de servico da atividade de conferencia
	_cTmpEndSrv := _aDadosOS[1][3]

	// retorna o proximo servico, tarefa e atividades planejada da OS
	// 1-Num OS
	// 2-Seq OS
	// 3-Cod Servico
	// 4-Dsc Servico
	// 5-Cod Tarefa
	// 6-Dsc Tarefa
	// 7-Funcao/Rotina
	_aPrxServico := U_FtPrxSrv(_aDadosOS[1][1], _aDadosOS[1][2], SC5->C5_CLIENTE, SC5->C5_LOJACLI, Nil)

	// pesquisa o proximo item da OS
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	If ! Z06->(dbSeek( xFilial("Z06") + _aPrxServico[1,1] + _aPrxServico[1,2] ))
		U_FtWmsMsg("Erro na liberação da OS de Carregamento!","ATENCAO")
		Return(.F.)
	EndIf

	// atualiza o proximo item da OS
	If (Z06->Z06_STATUS=="PL")
		RecLock("Z06")
		Z06->Z06_ENDSRV	:= _cTmpEndSrv
		Z06->Z06_DTEMIS := _dDtEmissao
		Z06->Z06_HREMIS := _cHrEmissao
		Z06->Z06_STATUS := "AG"
		Z06->Z06_PRIOR  := "99"
		Z06->(MsUnLock())
	EndIf

Return(.T.)

// ** funcao para validacao geral de dados
Static Function sfVldGeral(mvTmpArq)

	// variavel de retorno
	local _lRet := .T.

	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"SC5", "SC6", "SB1"})

	// variaveis temporarias
	local _nItXML
	local _nPos
	local _nItPed

	// itens do pedido
	local _aItensPed := {}

	// CNPJ Transportadora
	local _cTraCnpj := ""
	// quantidade de volumes
	local _nVolQuant := 0
	// CNPJ Destinatario / Entrega
	local _cEntCnpj := ""

	// seek
	local _cSeekSC6

	// codigo do produto
	local _cCodPrdCli := ""
	local _nQtdSolic  := 0

	// lista de produtos da nota (tem q ser private pra funcionar o Type)
	Private _aItXml := {}

	// se tem dados da transportadora
	If ( Type(_cBaseXML + "_INFNFE:_TRANSP:_TRANSPORTA") == "O")
		// atualiza o CNPJ
		_cTraCnpj := &(_cBaseXML + "_INFNFE:_TRANSP:_TRANSPORTA:_CNPJ:TEXT")
		// padroniza CNPJ
		_cTraCnpj := AllTrim(_cTraCnpj)
		// remove pontos
		_cTraCnpj := StrTran(_cTraCnpj,".","")
		// remove barras
		_cTraCnpj := StrTran(_cTraCnpj,"/","")
		// remove hifen
		_cTraCnpj := StrTran(_cTraCnpj,"-","")

		// verifica se pedido tem transportadora
		If ( Empty(SC5->C5_TRANSP) )
			// mensagem do Log
			_cErroLog += "Pedido de venda " + AllTrim(_cPedCli) + " sem transportadora informada." + CRLF
			// variavel de control
			_lRet := .F.
		EndIf

		// valida dados - compara CNPJ
		If (_lRet)
			// compara cnpj e codigo
			If (SC5->C5_TRANSP != Posicione("SA4", 3, xFilial("SA4") + _cTraCnpj, "A4_COD"))
				// mensagem do Log
				_cErroLog += "Pedido de Venda " + AllTrim(_cPedCli) + " com divergência de transportadora." + CRLF
				// variavel de control
				_lRet := .F.
			EndIf
		EndIf
	Else
		// mensagem do Log
		_cErroLog += "Pedido de venda " + AllTrim(_cPedCli) + " sem dados de transportadora no XML." + CRLF
		// variavel de control
		_lRet := .F.

	EndIf

	// se tem dados de volumes
	If ( Type(_cBaseXML + "_INFNFE:_TRANSP:_VOL:_QVOL") == "O")
		// quantidade de volumes
		_nVolQuant := Val(&(_cBaseXML + "_INFNFE:_TRANSP:_VOL:_QVOL:TEXT"))

		// verifica se pedido tem transportadora
		If ( SC5->C5_VOLUME1 == 0 )
			// mensagem do Log
			_cErroLog += "Pedido de venda " + AllTrim(_cPedCli) + " sem quantidade de volumes informado." + CRLF
			// variavel de control
			_lRet := .F.
		EndIf

		// valida dados - compara quantidade de volumes
		If (_lRet)
			// compara cnpj e codigo
			If (SC5->C5_VOLUME1 != _nVolQuant)
				// mensagem do Log
				_cErroLog += "Pedido de Venda " + AllTrim(_cPedCli) + " com divergência na quantidade de volumes." + CRLF
				// variavel de control
				_lRet := .F.
			EndIf
		EndIf
	Else
		// mensagem do Log
		_cErroLog += "Pedido de venda " + AllTrim(_cPedCli) + " sem dados de quantidade de volumes no XML." + CRLF
		// variavel de control
		_lRet := .F.

	EndIf

	// se tem dados do destinatario / cliente entrega
	If ( Type(_cBaseXML + "_INFNFE:_DEST") == "O")
		// atualiza o CNPJ
		If ( Type(_cBaseXML + "_INFNFE:_DEST:_CNPJ:TEXT") == "C" )
			_cEntCnpj := &(_cBaseXML + "_INFNFE:_DEST:_CNPJ:TEXT")
		ElseIf ( Type(_cBaseXML + "_INFNFE:_DEST:_CNPJ:TEXT") == "C" )
			_cEntCnpj := &(_cBaseXML + "_INFNFE:_DEST:_CPF:TEXT")
		EndIf
		// padroniza CNPJ
		_cEntCnpj := AllTrim(_cEntCnpj)
		// remove pontos
		_cEntCnpj := StrTran(_cEntCnpj,".","")
		// remove barras
		_cEntCnpj := StrTran(_cEntCnpj,"/","")
		// remove hifen
		_cEntCnpj := StrTran(_cEntCnpj,"-","")

		// verifica se pedido tem cgc do cliente de entrega
		If ( Empty(SC5->C5_ZCGCENT) )
			// mensagem do Log
			_cErroLog += "Pedido de venda " + AllTrim(_cPedCli) + " sem CNPJ do cliente de entrega informado." + CRLF
			// variavel de controle
			_lRet := .F.
		EndIf

		// valida dados - compara CNPJ
		If (_lRet)
			// compara cnpj
			If (SC5->C5_ZCGCENT != _cEntCnpj)
				// mensagem do Log
				_cErroLog += "Pedido de Venda " + AllTrim(_cPedCli) + " com divergência de CNPJ do cliente de entrega." + CRLF
				// variavel de controle
				_lRet := .F.
			EndIf
		EndIf

	EndIf

	// valida dos itens da nota fiscal
	// primeiro, carrega e organiza os itens do pedido de venda
	dbSelectArea("SC6")
	SC6->(dbSetOrder(1)) // 1 - C6_FILIAL, C6_NUM, C6_ITEM, C6_PRODUTO
	// Verifica se encontra pedido para fazer a atualização.
	SC6->( dbSeek( _cSeekSC6 := xFilial("SC6") + SC5->C5_NUM ))

	// percorre todos os itens do pedido de venda
	While SC6->( ! Eof() ) .And. ((SC6->C6_FILIAL + SC6->C6_NUM) == _cSeekSC6)

		// posiciona no cadastro de produto
		dbSelectArea("SB1")
		SB1->( DbSetOrder(1) ) // 1 - B1_FILIAL, B1_COD
		SB1->( DbSeek( xFilial("SB1") + SC6->C6_PRODUTO ) )

		// verifica se o item ja esta na relacao
		_nPos := aScan(_aItensPed,{|x| (x[1] == SB1->B1_CODCLI) })

		// se nao tem, cria
		If (_nPos == 0)
			aAdd(_aItensPed, { SB1->B1_CODCLI, SC6->C6_QTDVEN, SC6->C6_QTDVEN})
		ElseIf (_nPos != 0) // se tem, atualiza quantidade de saldo
			_aItensPed[_nPos][2] += SC6->C6_QTDVEN
			_aItensPed[_nPos][3] += SC6->C6_QTDVEN
		EndIf

		// proximo item
		SC6->( DbSkip() )
	EndDo


	// carrega array dos itens da nota
	_aItXml := &(_cBaseXML + "_INFNFE:_DET")

	// se nao conseguiu carrega os itens corretamente
	If ( ValType(_aItXml) <> "A")
		_aItXml := {}
		aAdd(_aItXml, &(_cBaseXML + "_INFNFE:_DET"))
	Endif

	// varre todos os itens do XML
	For _nItXML := 1 to Len(_aItXml)

		// codigo do produto
		_cCodPrdCli := PadR(_aItXml[_nItXML]:_PROD:_CPROD:TEXT, Len(SB1->B1_CODCLI))

		// quantidade solicitada
		_nQtdSolic := Val(_aItXml[_nItXML]:_PROD:_QCOM:TEXT)

		// verifica se o item ja esta na relacao
		_nPos := aScan(_aItensPed,{|x| (x[1] == _cCodPrdCli) })

		// se nao tem, cria
		If (_nPos == 0)
			aAdd(_aItensPed, { _cCodPrdCli, _nQtdSolic, _nQtdSolic})
		ElseIf (_nPos != 0) // se tem, atualiza (reduz) quantidade de saldo
			_aItensPed[_nPos][3] -= _nQtdSolic
		EndIf

	Next _nItXML

	// ao final, varre todos os itens do pedido e valida se o saldo foi atendido
	For _nItPed := 1 to Len(_aItensPed)

		// consulta coluna de saldo
		If (_aItensPed[_nItPed][3] != 0)
			// mensagem do Log
			_cErroLog += "Pedido de Venda " + AllTrim(_cPedCli) + " com divergência no Sku " + AllTrim(_aItensPed[_nItPed][1]) + CRLF
			// variavel de controle
			_lRet := .F.
		EndIf

	Next _nItPed

	// restaura areas iniciais
	RestOrd(_aAreaIni, .T.)
	RestArea(_aAreaAtu)

Return( _lRet )