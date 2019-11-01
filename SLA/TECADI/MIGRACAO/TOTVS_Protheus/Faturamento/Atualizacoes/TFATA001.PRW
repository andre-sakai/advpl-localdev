#include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina de importação de XML da Nota Eletronica, para    !
!                  ! Pedidos de Venda (devolucao de mercadoria de cliente)   !
!                  ! Implementado funcionalidade para importar TXT, conforme !
!                  ! layout pré-definido                                     !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 08/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function TFATA001()

	// bloco executado no botao CONFIRMA
	private _bConfirma := { || MsAguarde( { || fGeraPedVen() }, "Gerando Pedido de Venda..." ) }
	// objeto do XML aberto
	private _oXML
	// nome do arquivo TRB
	private _cNomArq
	// codigo, loja, CNPJ e sigla do cliente
	private _cCodCli := ""
	private _cLojaCli := ""
	private _cSiglaCli := ""
	private _cCnpjCli := ""
	// notas fiscais informadas
	private _cNotasSel := ""
	// controle se o arquivo esta Ok para importacao
	private _lClienOk  := .t.
	private _lItensOk  := .t.
	private _lTranspOk := .t.
	private _lLoteOk   := .t.

	// sequencia do pedido do cliente
	private _cSeqPedCli := StrZero(0, TamSx3("C6_ITEM")[1])

	// controle da estrutura do XML
	// 1. Versao 1.10 : _oXML:_NFEPROC:_NFE:_INFNFE
	// 2. Versao 2.00 : _oXML:_NFE:_INFNFE
	private _cBaseXML := ""
	// fontes utilizadas
	private _oFonte01 := TFont():New("Courier New",,16)
	private _oFonte02 := TFont():New("Verdana",,18,,.t.)
	// lista de arquivos para importar
	private _vListaArq := {}
	// tipo de arquivo a ser importado
	private _cTipoArq := ""
	// documento/nota do cliente
	private _cDocNfCli := ""
	// chave da NFe para consulta do status no SEFAZ
	private _cChaveNFe := ""
	// placa do veiculo
	private _cPlacaPed := ""
	// transportadora
	private _cTranspPed := ""

	// agrupadora
	private _cRefAgrupa := ""

	// detalhes de entrega do pedido
	private _aDadosEnt := {}

	// data de emissao da nota importada
	private _dEmissNFe := CtoD("//")

	// valita controle de lote ativo.
	Private _lLotAtivo := .F.

	// local padrao para as fotos
	Private _cLcPdrArq := U_FtGetFld("0")

	// controle se deve validar o numero do pedido do cliente
	private _lVldNrPed := .f.

	// controle se deve validar a chave da nota de venda do cliente
	private _lVldChvNfv := .f.

	// controle se deve agrupar todos os XML em unico pedido para separacao
	private _lAgrUnicPed := .t.

	// dados da transportadora
	private _aDadTransp := {}


	// tela para definir o tipo de arquivo que sera importado
	If ( ! sfDefTpArq() )
		Return(.f.)
	EndIf

	// realiza a leitura das coordenadas da tela
	_oDlgImport := MsDialog():New(000,000,280,500,"Pedido de Venda de Devolução",,,.F.,,,,,,.T.,,,.F.)
	// selecao do arquivo
	_oSayTitulo := TSay():New(007,010,{||"Arquivos "+_cTipoArq},_oDlgImport,,,,,,.T.,,,040,30)
	// lista dos arquivos
	_oListArquivos := TListBox():New(017,010,,_vListaArq,230,100,,_oDlgImport,,,,.T.,,,_oFonte01,"",,,,,,, )
	// botao para selecao do arquivo
	_oBtnFile := TButton():New(122,010,"&Adiciona "+_cTipoArq,_oDlgImport , {|| IIf( ! fGetFile(), _oDlgImport:End(), Nil) },40,11,,,,.T.)

	// botao para definir as notas
	If ( _cTipoArq == "XML" )
		_oBtnDefNot := TButton():New(122,055,"&Def. Notas",_oDlgImport,{|| sfDefNotas() },40,11,,,,.T.)
	EndIf

	// funcao para validar os dados do XML
	_oBtnImpXml := TButton():New(122,100,"&Importar",_oDlgImport,{||Eval(_bConfirma)},40,11,,,,.T.)
	// botao para fechar a tela
	_oBtnSair := TButton():New(122,200,"&Fechar",_oDlgImport , {|| _oDlgImport:End() },40,11,,,,.T.)

	// ativa a tela
	Activate MSDialog _oDlgImport Centered

Return

// ** funcao para selecionar o arquivo a ser importado
Static Function fGetFile()

	// arquivo
	local _cArquivo  := ""
	local _aTmpArqui := {}

	// parametro para usuário SUMITOMO
	local _cUsrSumi := ALLTRIM(SuperGetMV("TC_USRSUMI",.f.,""))
	// parametro para usuário PORTOBELLO
	local _cUsrPtbl := ALLTRIM(SuperGetMV("TC_USRPTBL",.f.,""))

	// variaveis temporarias
	Local _cTmpDrv	:= "" // drive
	Local _cTmpDir	:= "" // diretorio
	local _nTmpArq

	// arquivo SUMITOMO
	If ( cFilAnt $ "103/105/106" ).and.( _cTipoArq == "TXT" )

		// pergunta se é cliente SUMITOMO (layout próprio)
		//		If (__cUserId $ _cUsrSumi).and.( MsgYesNo("Pedido de Venda Sumitomo?") )
		If ( MsgYesNo("Pedido de Venda Sumitomo?") )

			// busca arquivo CSV
			_cArquivo := cGetFile("Ordem de Venda|*.CSV", ("Selecione arquivo..."),,_cLcPdrArq,.t.,GETF_LOCALHARD,.f.)

			// padroniza arquivo CSV para TXT
			If ( ! Empty(_cArquivo))

				_cArquivo := sfPadArqTXT(_cArquivo,"SUMI")
			EndIf
		Else

			// busca arquivo
			_cArquivo := cGetFile("Pedidos em TXT|*."+_cTipoArq, ("Selecione arquivo..."),,_cLcPdrArq,.t.,GETF_LOCALHARD+GETF_MULTISELECT,.f.)
		EndIf

		// arquivo PORTOBELLO
	ElseIf ( ( cFilAnt $ "103" ) .and. ( _cTipoArq == "XML" ) )

		// opção exclusiva para cliente PORTOBELLO
		If ( __cUserId $ _cUsrPtbl ) .and. ( MsgYesNo("Usar XML de Percurso?") )

			// busca arquivo XML
			_cArquivo := cGetFile("XML de Percurso|PERCURSO*.XML", ("Selecione arquivo..."),,_cLcPdrArq,.t.,GETF_LOCALHARD+GETF_MULTISELECT ,.f.)

			// padroniza arquivo XML para TXT
			If ( ! Empty(_cArquivo))

				_cArquivo := sfPadArqTXT(_cArquivo, "PTBL")
			EndIf

			// depois de converter o arquivo, muda o tipo
			_cTipoArq := "TXT"
		Else

			// busca arquivo
			_cArquivo := cGetFile("Notas Fiscais|*."+_cTipoArq, ("Selecione arquivo..."),,_cLcPdrArq,.t.,GETF_LOCALHARD+GETF_MULTISELECT ,.f.)
		EndIf
	Else

		// busca arquivo
		_cArquivo := cGetFile("Notas Fiscais|*."+_cTipoArq, ("Selecione arquivo..."),,_cLcPdrArq,.t.,GETF_LOCALHARD+GETF_MULTISELECT ,.f.)
	EndIf

	// extrai informacoes do arquivo, para mudar o local padrao do anexo
	If ( ! Empty(_cArquivo) )

		// extrai os dados, separando por |
		_aTmpArqui := Separa(_cArquivo, "|")

		// varre todos os arquivos selecionados
		For _nTmpArq := 1 to Len(_aTmpArqui)

			// define caminho completo do arquivo
			_cArquivo := AllTrim(_aTmpArqui[_nTmpArq])

			// ex: SplitPath ( < cArquivo>, [ @cDrive], [ @cDiretorio], [ @cNome], [ @cExtensao] )
			SplitPath(AllTrim(_cArquivo), @_cTmpDrv, @_cTmpDir)
			// muda o local padrao
			_cLcPdrArq := _cTmpDrv+_cTmpDir

			// copia o arquivo local para o servidor
			sfCopiaArq(@_cArquivo)

			// adiciona o arquivo na lista
			If ( aScan(_vListaArq,_cArquivo) == 0 )
				// adiciona o arquivo
				aAdd( _vListaArq, _cArquivo )
				// atualiza a lista de arquivos
				_oListArquivos:SetItems( _vListaArq )
			Else
				Aviso( "TFATA001 -> fGetFile","O arquivo " + AllTrim(_cArquivo) + " já consta na lista de importação.", {"Fechar"} )
			EndIf

		Next _nTmpArq

	EndIf

Return( ! Empty(_cArquivo))

// ** funcao que copia o arquivo local para o servidor
Static Function sfCopiaArq(mvArquivo)
	Local _cTmpArq	:= "" // nome do arquivo
	Local _cTmpExt	:= "" // extensao do arquivo

	// cria os diretorios necessarios
	MakeDir("\tecadi")
	MakeDir("\tecadi\"+_cTipoArq)
	MakeDir("\tecadi\"+_cTipoArq+"\saidas")
	MakeDir("\tecadi\"+_cTipoArq+"\saidas\importados")
	// copia o arquivo do local para o servidor
	CpyT2S(mvArquivo,"\tecadi\"+_cTipoArq+"\saidas",.f.)
	// ex: SplitPath ( < cArquivo>, [ @cDrive], [ @cDiretorio], [ @cNome], [ @cExtensao] )
	SplitPath(mvArquivo,,,@_cTmpArq,@_cTmpExt)
	// muda o caminho do arquivo para o servidor
	mvArquivo := "\tecadi\"+_cTipoArq+"\saidas\"+_cTmpArq+_cTmpExt
Return(.t.)

// ** funcao para gerar o pedido de venda
Static Function fGeraPedVen()
	// variaveis da rotina padrao do pedido de venda
	local _aCabAuto	:= {}
	local _aIteAuto	:= {}
	local _aLinha	:= {}
	// item do pedido
	local _cItem := StrZero(1,TamSx3("C6_ITEM")[1])
	// controle do arquivo na lista
	local _nArqAtu
	// volumes
	local _nVolumes  := CriaVar("C5_VOLUME1",.f.)
	local _nCliVolum := CriaVar("C5_VOLUME1",.f.)
	// especies
	local _cCodEspVol := CriaVar("C5_ZCDESP1",.f.)
	local _cEspecie   := CriaVar("C5_ESPECI1",.f.)
	local _cCliCodEsp := CriaVar("C5_ZCDESP1",.f.)
	local _cCliEspec  := CriaVar("C5_ESPECI1",.f.)

	// chave de controle de geracao de pedidos
	local _cChvPedido := StrZero(999,TamSx3("C6_ITEM")[1])

	// pedidos gerados
	local _cNewPedido := ""

	// variaveis temporarias
	local _nPosEntreg := 0
	local _nPosQtdVol := 0
	local _nX	:= 0

	// mensagem de validacao da nota XML
	local _lMsgConsNF := .t.

	// tipo do frete padrao
	local _cTpFrete := CriaVar("C5_TPFRETE",.f.)

	// codigo da mensagem padrao
	local _cMensPadr := CriaVar("C5_MENPAD",.f.)

	// sequencia de pedido do cliente
	_cSeqPedCli := StrZero(0,TamSx3("C6_ITEM")[1])

	// validacao de arquivos selecionados
	If (Len(_vListaArq) == 0)
		Aviso("TFATA001 -> fGeraPedVen","Nenhum arquivo selecionado para importação.",{"Fechar"})
		ClearGlbVars("_aGlbLot")
		Return(.f.)
	EndIf

	// cria o arquivo de trabalho dos itens
	fCriaTrb(.t.)

	// validacao completa do arquivo
	_lImpAllOk := .t.
	_lClienOk  := .t.
	_lItensOk  := .t.
	_lTranspOk := .t.
	_lLoteOk   := .t.

	// reinicia variaveis
	_cCodCli   := ""
	_cLojaCli  := ""
	_cSiglaCli := ""
	_cCnpjCli  := ""
	_aDadosEnt := {}

	// varre todos os arquivos selecionados
	For _nArqAtu := 1 to Len(_vListaArq)
		// funcao para validar as informacoes antes de importar
		MsAguarde({|| _lImpAllOk := sfVldArquivo(_vListaArq[_nArqAtu], .f., .f., @_lMsgConsNF) },"Validando dados...")

	Next _nArqAtu

	// se nao validou os dados
	If ( ! _lImpAllOk ).or.( ! _lClienOk ).or.( ! _lItensOk ).or.( ! _lTranspOk ).or.( ! _lLoteOk )
		Return(.f.)
	EndIf

	// posiciona no 1o Item
	dbSelectArea("_TRBSC6")
	_TRBSC6->(dbGoTop())

	// mensagem de confirmacao
	If (Aviso("TFATA001 -> fGeraPedVen","Confirma a importação do Pedido de Venda?",{"Sim","Não"}) <> 1)
		Return(.f.)
	EndIf

	// define o tipo de frete padrao para o cliente
	_cTpFrete := U_FtWmsParam("WMS_PEDIDO_TIPO_FRETE_PADRAO", "C", _cTpFrete, .F., "", _cCodCli, _cLojaCli, Nil, Nil)

	// define o codigo da mensagem padrao para o cliente
	_cMensPadr := U_FtWmsParam("WMS_PEDIDO_MENSAGEM_PADRAO_FORMULA", "C", _cMensPadr, .F., "", _cCodCli, _cLojaCli, Nil, Nil)

	// define o codigo da especie dos volumes
	_cCliCodEsp := U_FtWmsParam("WMS_PEDIDO_VOLUME_ESPECIE", "C", _cEspecie, .F., "", _cCodCli, _cLojaCli, Nil, Nil)
	_cCliEspec  := Tabela("CL",_cCliCodEsp)

	// define a quantidade de volumes padrao
	_nCliVolum := U_FtWmsParam("WMS_PEDIDO_VOLUME_QUANTIDADE", "N", _nVolumes, .F., "", _cCodCli, _cLojaCli, Nil, Nil)

	// INICIO DA TRANSACAO
	BEGIN TRANSACTION

		dbSelectArea("_TRBSC6")
		_TRBSC6->(dbGoTop())

		// varre todos os itens
		While _TRBSC6->( ! Eof() )

			// posiciona no cadastro de cliente
			dbSelectArea("SA1")
			SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
			SA1->(dbSeek( xFilial("SA1")+_cCodCli+_cLojaCli ))

			// define a quantidade de volumes
			_nVolumes += (_TRBSC6->C6_ZQTDVOL + _TRBSC6->C6_ZQTDPLT)

			// verifica quebra de pedido
			If (_cChvPedido <> _TRBSC6->IT_SEQPED)

				// define volume padrao
				If (_nVolumes == 0)
					_nVolumes := _nCliVolum
				EndIf

				// define especie padrao
				If (Empty(_cEspecie))
					_cCodEspVol := _cCliCodEsp
					_cEspecie   := _cCliEspec
				EndIf

				// necessario informar volumes / especies
				If (_nVolumes == 0).or.(Empty(_cEspecie))

					// solicita quantidade de volumes para usuario
					sfVolumes(@_nVolumes, @_cEspecie)

					// valida volume / especies
					If (_nVolumes <= 0).or.(Empty(_cEspecie))
						// mensagem
						Aviso("TFATA001 -> fGeraPedVen","É obrigatório informar a quantidade de volumes/espécies",{"Fechar"})
						// rollback na transacao
						DisarmTransaction()
						// retorno
						Return(.f.)
					EndIf

				EndIf

				// zera variavel
				_aCabAuto := {}
				_aIteAuto := {}

				// item do pedido
				_cItem := StrZero(1,TamSx3("C6_ITEM")[1])

				// pesquisa os dados de endereco de entrega
				_nPosEntreg := aScan(_aDadosEnt,{|x| (x[1] == _TRBSC6->IT_SEQPED) })

				// dados do cabecalho do pedido de venda
				aadd(_aCabAuto,{"C5_TIPO"	,"N"                 , nil}) // Tipo do Pedido - N-Normal
				aadd(_aCabAuto,{"C5_CLIENTE",SA1->A1_COD         , nil}) // Cod. Cliente
				aadd(_aCabAuto,{"C5_LOJACLI",SA1->A1_LOJA        , nil}) // Loja
				aadd(_aCabAuto,{"C5_CLIENT"	,SA1->A1_COD         , nil}) // Cod. Cliente Ent
				aadd(_aCabAuto,{"C5_LOJAENT",SA1->A1_LOJA        , nil}) // Loja Ent
				aadd(_aCabAuto,{"C5_TIPOCLI",SA1->A1_TIPO        , nil}) // Tipo do Cliente
				aadd(_aCabAuto,{"C5_CONDPAG","001"               , nil}) // Condicao de Pagamento (padrao 001)
				aadd(_aCabAuto,{"C5_TIPOOPE","P"                 , nil}) // tipo da operacao: P-Produto / S-Servido
				aadd(_aCabAuto,{"C5_EMISSAO",dDataBase           , nil}) // data de emissao
				aadd(_aCabAuto,{"C5_VOLUME1",_nVolumes           , nil}) // volumes
				aadd(_aCabAuto,{"C5_ZCDESP1",_cCodEspVol         , nil}) // codigo da especie do volume
				aadd(_aCabAuto,{"C5_ESPECI1",_cEspecie           , nil}) // descricao especie do volume
				aadd(_aCabAuto,{"C5_MENNOTA",""                  , nil}) // mensagem para nota fiscal
				aadd(_aCabAuto,{"C5_MENPAD"	,_cMensPadr          , nil}) // codigo da mensagem padrao
				aadd(_aCabAuto,{"C5_ZDOCCLI",_TRBSC6->C5_ZDOCCLI , nil}) // documento/nota do cliente
				aadd(_aCabAuto,{"C5_ZCHVNFV",_TRBSC6->C5_ZCHVNFV , nil}) // chave da NFe para consulta do status no SEFAZ
				aadd(_aCabAuto,{"C5_ZEMINFV",_TRBSC6->C5_ZEMINFV , nil}) // data de emissao da nota fiscal importada
				aadd(_aCabAuto,{"C5_ZPEDCLI",_TRBSC6->C5_ZPEDCLI , nil}) // numero do pedido do cliente
				aadd(_aCabAuto,{"C5_VEICULO",_TRBSC6->C5_VEICULO , nil}) // placa do veiculo
				aadd(_aCabAuto,{"C5_TRANSP" ,_TRBSC6->C5_TRANSP  , nil}) // transportadora
				aadd(_aCabAuto,{"C5_ZAGRUPA",_TRBSC6->C5_ZAGRUPA , nil}) // Agrupadora
				aadd(_aCabAuto,{"C5_TPFRETE",_cTpFrete           , nil}) // tipo de frete
				aadd(_aCabAuto,{"C5_ZAGRUPA",_TRBSC6->C5_ZAGRUPA , nil}) // Agrupadora
				aadd(_aCabAuto,{"C5_ZORIGEM", "02"               , nil}) // Origem do pedido 02 = via importação/EDI

				// inclui dados de endereco de entrega
				If (_nPosEntreg > 0)
					aadd(_aCabAuto,{"C5_ZCGCENT",_aDadosEnt[_nPosEntreg][2] ,nil}) // CGC do cliente de entrega
					aadd(_aCabAuto,{"C5_ZCLIENT",_aDadosEnt[_nPosEntreg][3] ,nil}) // Nome do cliente de entrega
					aadd(_aCabAuto,{"C5_ZENDENT",_aDadosEnt[_nPosEntreg][4] ,nil}) // endereco de entrega
					aadd(_aCabAuto,{"C5_ZCIDENT",_aDadosEnt[_nPosEntreg][5] ,nil}) // Nome da Cidade De entrega
					aadd(_aCabAuto,{"C5_ZUFENTR",_aDadosEnt[_nPosEntreg][6] ,nil}) // Estado de entrega
				EndIf

				// verifica quebra de pedido
				_cChvPedido := _TRBSC6->IT_SEQPED

			EndIf

			// zera vetor da linha
			_aLinha := {}
			// alimenta os itens do pedido de venda
			aadd(_aLinha,{"C6_ITEM"   , _cItem             , Nil})
			aadd(_aLinha,{"C6_PRODUTO", _TRBSC6->C6_PRODUTO, Nil})
			aadd(_aLinha,{"C6_DESCRI" , _TRBSC6->C6_DESCRI , Nil})
			aadd(_aLinha,{"C6_QTDVEN" , _TRBSC6->C6_QTDVEN , Nil})
			aadd(_aLinha,{"C6_PRCVEN" , _TRBSC6->C6_PRCVEN , Nil})
			// tratamento para arredondamento do valor total (conforme cada cliente) - devolucao total
			If (_TRBSC6->C6_QTDVEN == _TRBSC6->D1_QUANT)
				aadd(_aLinha,{"C6_VALOR" , _TRBSC6->D1_TOTAL , Nil})
			EndIf
			aadd(_aLinha,{"C6_TES"    , _TRBSC6->C6_TES    , Nil})
			aadd(_aLinha,{"C6_NFORI"  , _TRBSC6->C6_NFORI  , Nil})
			aadd(_aLinha,{"C6_SERIORI", _TRBSC6->C6_SERIORI, Nil})
			aadd(_aLinha,{"C6_ITEMORI", _TRBSC6->C6_ITEMORI, Nil})
			aadd(_aLinha,{"C6_IDENTB6", _TRBSC6->C6_IDENTB6, Nil})
			aadd(_aLinha,{"C6_LOCAL"  , _TRBSC6->C6_LOCAL  , Nil})
			aadd(_aLinha,{"C6_LOTECTL", _TRBSC6->C6_LOTECTL, Nil})
			aadd(_aLinha,{"C6_ZTPESTO", "000001"           , Nil})
			aadd(_aLinha,{"C6_PEDCLI" , _TRBSC6->C5_ZPEDCLI, Nil})
			aadd(_aLinha,{"C6_ZQTDVOL", _TRBSC6->C6_ZQTDVOL, Nil})
			aadd(_aLinha,{"C6_ZQTDPLT", _TRBSC6->C6_ZQTDPLT, Nil})
			aadd(_aLinha,{"AUTDELETA" , "N"                , Nil})

			// atualiza vetor da rotina automatica
			aadd(_aIteAuto,_aLinha)

			// incrementa proximo item
			_cItem := SomaIt(_cItem)

			// proximo item
			_TRBSC6->(dbSkip())

			// verifica quebra de pedido
			If (_cChvPedido <> _TRBSC6->IT_SEQPED).Or.( _TRBSC6->(EoF()) )

				// pesquisa a posicao do campo Qtd Volumes
				_nPosQtdVol := aScan(_aCabAuto,{|x| (AllTrim(x[1]) == "C5_VOLUME1") })

				// altera a quantidade de volumes
				_aCabAuto[_nPosQtdVol][2] := _nVolumes

				// prepara variaveis para rotina automatica
				lMsErroAuto := .F.
				dbSelectArea("SC5")
				dbSelectArea("SC6")

				// rotina automatica do pedido de venda
				MsExecAuto({|x,y,z| Mata410(x,y,z)},_aCabAuto,_aIteAuto,3) // 3-inclusao

				// operacao se deu erro
				If ( lMsErroAuto )
					// rollback na transacao
					DisarmTransaction()
					MostraErro()
					Return(.f.)
				EndIf

				// incrementa pedidos
				_cNewPedido += IIf(Empty(_cNewPedido),"",", ")+SC5->C5_NUM

				// zera variaveis
				_nVolumes := 0

			EndIf
		EndDo

		// FIM DA TRANSACAO
	END TRANSACTION

	// aviso de pedido de venda gerado
	Aviso("TFATA001 -> fGeraPedVen","Pedido(s) de Venda "+_cNewPedido+" gerado(s) com sucesso.",{"Fechar"})

	// fecha a tela
	If (IsInCallStack("U_TFATA001") )
		_oDlgImport:End()
	Endif

Return(.T.)

// ** funcao que valida os Arquivos selecionados antes de gerar o Pedido de Venda
Static Function sfVldArquivo(mvArquivo, mvPesqNota, mvGetCli, mvMsgConsNF)
	// mensagens retornadas da funcao XmlParserFile
	local _cError := ""
	local _cWarning := ""
	// CNPJ temporario do Cliente
	local _cTmpCnpj := ""
	// numero e serie da nota do cliente
	local _aTmpNotas := {}
	local _nNota
	// ID da empresa
	local _cIdEnt := ""
	// numero da nota e serie
	local _cTmpNota, _cTmpSerie

	// lista de produtos da nota (tem que ser private pra funcionar o Type)
	private _aItensSol := {}

	// lista dos lotes de produtos
	// estrutura do vetor _aLotesSol
	// 1-seq pedido do cliente
	// 2-seq item no arquivo
	// 3-codigo do produto
	// 4-numero do lote
	// 5-ID do palete
	// 6-Quantidade
	// 7-Saldo
	private _aLotesSol := {}

	// variavel usada pra validar se o acesso a rotina é só pra pegar o cliente
	default mvGetCli := .f.
	// mensagem de validacao da nota XML
	default mvMsgConsNF := .t.




	// verifica se foi selecionado algum arquivo
	If (Empty(mvArquivo))
		Aviso("TFATA001 -> sfVldArquivo","É obrigatório selecionar um arquivo.",{"Fechar"})
		Return(.f.)
	EndIf

	// abertura do arquivo XML e estrutura do objeto
	If (_cTipoArq=="XML")

		// cria objeto com parse do XML
		_oXML := XmlParserFile(mvArquivo, "_", @_cError, @_cWarning )

		// verifica erros no XML
		If (ValType(_oXML) != "O")
			// mensagem
			Aviso("TFATA001 -> sfVldArquivo","Falha ao gerar Objeto XML : "+_cError+" / "+_cWarning,{"Fechar"})
			// zera variavel
			_oXML := Nil
			// retorno
			Return(.f.)
		Endif

		// monta a base da estrutura do XML de acordo com a versao
		// versao 1.10
		If (Type("_oXML:_NFEPROC:_NFE")=="O")
			// define a base do XML
			_cBaseXML := "_oXML:_NFEPROC:_NFE:"
			// versao 2.00
		ElseIf (Type("_oXML:_NFE")=="O")
			// define a base do XML
			_cBaseXML := "_oXML:_NFE:"
		Else
			// mensagem
			Aviso("TFATA001 -> sfVldArquivo","ATENÇÃO: Erro na estrutura do arquivo XML.",{"Fechar"})
			// retorno
			Return(.f.)
		EndIf

		// chave da NFe para consulta do status no SEFAZ
		If (Type("_oXML:_NFEPROC:_PROTNFE:_INFPROT:_CHNFE:TEXT")=="C")
			// chave da nota
			_cChaveNFe := _oXML:_NFEPROC:_PROTNFE:_INFPROT:_CHNFE:TEXT
			// se nao encontrou no campo especifico, tenta em outro
		ElseIf (Type("_oXML:_NFE:_INFNFE:_ID:TEXT")=="C")
			// chave da nota
			_cChaveNFe := SubStr(_oXML:_NFE:_INFNFE:_ID:TEXT,4)
		EndIf

		// retorno do CNPJ
		_cTmpCnpj := &(_cBaseXML+"_INFNFE:_EMIT:_CNPJ:TEXT")

		// prepara e padroniza o numero e serie da nota
		_cTmpNota	:= StrZero(Val(&(_cBaseXML+"_INFNFE:_IDE:_NNF:TEXT")),(Len(SF1->F1_DOC)))
		_cTmpSerie	:= AllTrim(&(_cBaseXML+"_INFNFE:_IDE:_SERIE:TEXT"))

		// adiciona a nota para validacao de itens
		aAdd(_aTmpNotas,{_cTmpNota,_cTmpSerie})

		// data de emissao da nota importada
		If (TYPE(_cBaseXML+"_INFNFE:_IDE:_DHEMI:TEXT") == "C") // 3.0
			_dEmissNFe := &(_cBaseXML+"_INFNFE:_IDE:_DHEMI:TEXT")
			_dEmissNFe := SUBSTR(_dEmissNFe,1,10)
		ElseIf (TYPE(_cBaseXML+"_INFNFE:_IDE:_DEMI:TEXT") == "C") // 2.0
			_dEmissNFe := &(_cBaseXML+"_INFNFE:_IDE:_DEMI:TEXT")
		Else
			Aviso("TFATA001 -> sfVldArquivo","ATENÇÃO: Data de Emissão da NF inválida!",{"Fechar"})
			Return(.f.)
		EndIf

		// converte a data (Str to Date)
		_dEmissNFe := StoD(StrTran(_dEmissNFe,"-",""))

		// valida os dados do cliente
		If ( ! sfVldCliente(_cTmpCnpj))
			_lClienOk := .f.
		EndIf

		// caso a consulta seja apenas para validar o cliente
		If ( mvGetCli )
			Return .t.
		EndIf

		// se dados do cliente Ok
		If (_lClienOk)

			// verifica o uso de referencia agrupadora por cliente
			_lUsaRefAgrup := U_FtWmsParam("WMS_USO_REFERENCIA_AGRUPADORA_PEDIDO", "L", .f., .f., "", _cCodCli, _cLojaCli, Nil, Nil)

			// verifica se o controle de lote esta ativo
			_lLotAtivo := U_FtWmsParam("WMS_CONTROLE_POR_LOTE", "L", .F. , .F., Nil, _cCodCli, _cLojaCli, Nil, Nil)

			// controle se deve validar o numero do pedido do cliente
			_lVldNrPed := U_FtWmsParam("WMS_PEDIDO_VALIDA_PEDIDO_CLIENTE", "L", .F. , .F., Nil, _cCodCli, _cLojaCli, Nil, Nil)

			// controle se deve validar a chave da nota de venda do cliente
			_lVldChvNfv := U_FtWmsParam("WMS_PEDIDO_VALIDA_CHAVE_NOTA_VENDA", "L", .F. , .F., Nil, _cCodCli, _cLojaCli, Nil, Nil)

			// controle se deve agrupar todos os XML em unico pedido para separacao
			_lAgrUnicPed := U_FtWmsParam("WMS_PEDIDO_AGRUPAR_XML_UNICO_PEDIDO", "L", .T. , .F., Nil, _cCodCli, _cLojaCli, Nil, Nil)

		EndIf

		// se for pesquisa de notas, fecha a validacao
		If (mvPesqNota)
			Return(.t.)
		EndIf

		// define o numero da nota do cliente para incluir no pedido de venda
		If (_lAgrUnicPed)
			_cDocNfCli += If(Empty(_cDocNfCli),"",", ") + (_cTmpNota+"/"+_cTmpSerie)
		Else
			_cDocNfCli := _cTmpNota+"/"+_cTmpSerie
		EndIf

		// nao encontrou a chave da NFe
		If SuperGetMv("TC_CONSNFE",.f.,.t.)
			If (Empty(_cChaveNFe))
				If (Aviso("TFATA001 -> sfVldArquivo","Não foi possível encontrar a chave da nota fiscal. Deseja continuar a importação sem verificar a nota?",{"Continuar","Cancelar"})==2)
					Return(.f.)
				EndIf

				// verifica o status da nota no SEFAZ
			ElseIf ( ! Empty(_cChaveNFe))
				// pesquisa o ID da empresa
				_cIdEnt := RetIdEnti()
				// se nao encontrou o ID da Empresa
				If (Empty(_cIdEnt))
					Aviso("TFATA001 -> sfVldArquivo","Erro do retorno do ID da Empresa.",{"Abortar"})
					Return(.f.)
				EndIf
				// consulta o status no SEFAZ
				If ( ! ConsNFeChave(_cChaveNFe, _cIdEnt, @mvMsgConsNF))
					Return(.f.)
				EndIf
			EndIf
		Else
			Aviso("TFATA001 -> sfVldArquivo","Atenção!!! A consulta da nota fiscal eletrônica está desabilitada. Favor consultar o documento através do site da SEFAZ.",{"Ok"})
		EndIf

		// abertura do arquivo TXT
	ElseIf (_cTipoArq=="TXT")
		// funcao para validar a estrutura do arquivo TXT
		If ( ! sfVldArqTxt(mvArquivo, @_cTmpCnpj, mvGetCli) )
			Return(.f.)
		EndIf

		aAdd(_aTmpNotas,{"",""})

	EndIf

	// varre todas as notas
	For _nNota := 1 to Len(_aTmpNotas)
		// valida os itens da nota
		If ( ! sfVldItens(_aTmpNotas[_nNota][1], _aTmpNotas[_nNota][2]))
			_lItensOk := .f.
		EndIf
	Next _nNota

Return(.t.)

// ** funcao para criar o arquivo de trabalho dos itens da nota
Static Function fCriaTrb(mvNew)

	local _aStruc   := {}
	local _aTamSx3  := {}
	local _aAreaSX3 := SX3->(GetArea())

	// arquivo novo
	If (mvNew)
		// sequencia pedido cliente
		_aTamSx3 := TamSX3("C6_ITEM")    ; aAdd(_aStruc,{"IT_SEQPED" ,"C",_aTamSx3[1],_aTamSx3[2]})
		// pedido do cliente
		_aTamSx3 := TamSX3("C5_ZAGRUPA") ; aAdd(_aStruc,{"C5_ZAGRUPA", "C",_aTamSx3[1],_aTamSx3[2]})
		// pedido do cliente
		_aTamSx3 := TamSX3("C5_ZPEDCLI") ; aAdd(_aStruc,{"C5_ZPEDCLI", "C",_aTamSx3[1],_aTamSx3[2]})
		// campo produto
		_aTamSx3 := TamSX3("C6_PRODUTO") ; aAdd(_aStruc,{"C6_PRODUTO", "C",_aTamSx3[1],_aTamSx3[2]})
		// descricao produto
		_aTamSx3 := TamSX3("C6_DESCRI")  ; aAdd(_aStruc,{"C6_DESCRI" , "C",_aTamSx3[1],_aTamSx3[2]})
		// campo quantidade
		_aTamSx3 := TamSX3("C6_QTDVEN")  ; aAdd(_aStruc,{"C6_QTDVEN" , "N",_aTamSx3[1],_aTamSx3[2]})
		// campo preco de venda
		_aTamSx3 := TamSX3("C6_PRCVEN")  ; aAdd(_aStruc,{"C6_PRCVEN" , "N",_aTamSx3[1],_aTamSx3[2]})
		// nota fiscal de origem
		_aTamSx3 := TamSX3("C6_NFORI")   ; aAdd(_aStruc,{"C6_NFORI"  , "C",_aTamSx3[1],_aTamSx3[2]})
		// serie da nota fiscal de origem
		_aTamSx3 := TamSX3("C6_SERIORI") ; aAdd(_aStruc,{"C6_SERIORI", "C",_aTamSx3[1],_aTamSx3[2]})
		// item da nota fiscal de origem
		_aTamSx3 := TamSX3("C6_ITEMORI") ; aAdd(_aStruc,{"C6_ITEMORI", "C",_aTamSx3[1],_aTamSx3[2]})
		// ID do controle do SB6
		_aTamSx3 := TamSX3("C6_IDENTB6") ; aAdd(_aStruc,{"C6_IDENTB6", "C",_aTamSx3[1],_aTamSx3[2]})
		// local / armazem
		_aTamSx3 := TamSX3("C6_LOCAL")   ; aAdd(_aStruc,{"C6_LOCAL"  , "C",_aTamSx3[1],_aTamSx3[2]})
		// TES de Saida
		_aTamSx3 := TamSX3("C6_TES")     ; aAdd(_aStruc,{"C6_TES"    , "C",_aTamSx3[1],_aTamSx3[2]})
		// transportadora
		_aTamSx3 := TamSX3("C5_TRANSP")  ; aAdd(_aStruc,{"C5_TRANSP" , "C",_aTamSx3[1],_aTamSx3[2]})
		// placa
		_aTamSx3 := TamSX3("C5_VEICULO") ; aAdd(_aStruc,{"C5_VEICULO", "C",_aTamSx3[1],_aTamSx3[2]})
		// campo item do pedido para controlar lotes somente
		_aTamSx3 := TamSX3("C6_ITEM")    ; aAdd(_aStruc,{"IT_SEQLOTE", "C",_aTamSx3[1],_aTamSx3[2]})
		// lote do produto
		_aTamSx3 := TamSX3("C6_LOTECTL") ; aAdd(_aStruc,{"C6_LOTECTL", "C",_aTamSx3[1],_aTamSx3[2]})
		// quantidade de volumes
		_aTamSx3 := TamSX3("C6_ZQTDVOL") ; aAdd(_aStruc,{"C6_ZQTDVOL", "N",_aTamSx3[1],_aTamSx3[2]})
		// quantidade de paletes
		_aTamSx3 := TamSX3("C6_ZQTDPLT") ; aAdd(_aStruc,{"C6_ZQTDPLT", "N",_aTamSx3[1],_aTamSx3[2]})
		// chave nota fiscal de venda
		_aTamSx3 := TamSX3("C5_ZCHVNFV") ; aAdd(_aStruc,{"C5_ZCHVNFV", "C",_aTamSx3[1],_aTamSx3[2]})
		// data emissao fiscal de venda
		_aTamSx3 := TamSX3("C5_ZEMINFV") ; aAdd(_aStruc,{"C5_ZEMINFV", "D",_aTamSx3[1],_aTamSx3[2]})
		// numero nota fiscal de venda do cliente
		_aTamSx3 := TamSX3("C5_ZDOCCLI") ; aAdd(_aStruc,{"C5_ZDOCCLI", "C",_aTamSx3[1],_aTamSx3[2]})
		// quantidade total da nota de entrada
		_aTamSx3 := TamSX3("D1_QUANT")   ; aAdd(_aStruc,{"D1_QUANT"  , "N",_aTamSx3[1],_aTamSx3[2]})
		// valor total da nota de entrada
		_aTamSx3 := TamSX3("D1_TOTAL")   ; aAdd(_aStruc,{"D1_TOTAL"  , "N",_aTamSx3[1],_aTamSx3[2]})

		// fecha alias do arquivo de trabalho
		If Select("_TRBSC6") <> 0
			dbSelectArea("_TRBSC6")
			dbCloseArea()
		EndiF
		// cria o TRB
		_cNomArq := CriaTrab(_aStruc, .t.)
		dbUseArea(.t.,,_cNomArq,"_TRBSC6",.F.,.F.)

		// cria TRB para os lotes
		_aStruc	:= {}
		_aTamSx3	:= {}

		// sequencia pedido cliente
		_aTamSx3 := TamSX3("C6_ITEM")    ; aAdd(_aStruc,{"IT_SEQPED" ,"C",_aTamSx3[1],_aTamSx3[2]})
		// campo produto
		_aTamSx3 := TamSX3("C6_PRODUTO") ; aAdd(_aStruc,{"C6_PRODUTO","C",_aTamSx3[1],_aTamSx3[2]})
		// campo data de validade do lote
		_aTamSx3 := TamSX3("B8_DTVALID")  ; aAdd(_aStruc,{"B8_DTVALID" ,"D",_aTamSx3[1],_aTamSx3[2]})
		// campo lote
		_aTamSx3 := TamSX3("Z16_LOTCTL")  ; aAdd(_aStruc,{"Z16_LOTCTL" ,"C",_aTamSx3[1],_aTamSx3[2]})
		// campo local
		_aTamSx3 := TamSX3("Z16_LOCAL")  ; aAdd(_aStruc,{"Z16_LOCAL" ,"C",_aTamSx3[1],_aTamSx3[2]})
		// campo pallet
		_aTamSx3 := TamSX3("Z16_ETQPAL")  ; aAdd(_aStruc,{"Z16_ETQPAL" ,"C",_aTamSx3[1],_aTamSx3[2]})
		// campo ident B6
		_aTamSx3 := TamSX3("Z16_NUMSEQ")  ; aAdd(_aStruc,{"Z16_NUMSEQ" ,"C",_aTamSx3[1],_aTamSx3[2]})
		// campo quantidade do lote
		_aTamSx3 := TamSX3("Z16_SALDO")  ; aAdd(_aStruc,{"Z16_SALDO" ,"N",_aTamSx3[1],_aTamSx3[2]})
		// campo quantidade usada em pedidos
		_aTamSx3 := TamSX3("C6_QTDVEN")  ; aAdd(_aStruc,{"C6_QTDVEN" ,"N",_aTamSx3[1],_aTamSx3[2]})

		If Select("_TRBLOT") <> 0
			dbSelectArea("_TRBLOT")
			dbCloseArea()
		EndiF
		// cria o TRB
		_cNomArq := CriaTrab(_aStruc, .t.)
		dbUseArea(.t.,,_cNomArq,"_TRBLOT",.F.,.F.)
		IndRegua("_TRBLOT",_cNomArq,"IT_SEQPED+C6_PRODUTO+Z16_ETQPAL+dtos(B8_DTVALID)+Z16_LOTCTL",,,"Selecionando Registros...")

	EndIf

	// limpa o conteudo do TRB
	dbSelectArea("_TRBSC6")
	__DbZap()

	dbSelectArea("_TRBLOT")
	__DbZap()

Return

// ** funcao que valida os dados do cliente
Static Function sfVldCliente(mvCnpj)
	// posicao inicial das tabelas
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"SA1"})

	// se o CNPJ estiver em branco
	If (Empty(mvCnpj))
		Aviso("TFATA001 -> sfVldCliente","Não foi possível localizar o CNPJ do cliente no arquivo XML!",{"Fechar"})
		// restaura areas iniciais
		RestOrd(_aAreaIni,.t.)
		RestArea(_aAreaAtu)
		// retorno
		Return(.f.)
	Else
		// pesquisa o cliente
		dbSelectArea("SA1")
		SA1->(dbSetOrder(3)) //3-A1_FILIAL, A1_CGC
		If ( ! SA1->(dbSeek(xFilial("SA1") + mvCnpj )))
			Aviso("TFATA001 -> sfVldCliente","Cliente com CNPJ "+Transf(mvCnpj,PesqPict("SA1","A1_CGC"))+" não cadastrado.",{"Fechar"})
			// restaura areas iniciais
			RestOrd(_aAreaIni,.t.)
			RestArea(_aAreaAtu)
			// retorno
			Return(.f.)
		Endif

		// armazena informacoes do cliente
		If (Empty(_cCnpjCli))
			_cCodCli	:= SA1->A1_COD
			_cLojaCli	:= SA1->A1_LOJA
			_cSiglaCli	:= SA1->A1_SIGLA
			_cCnpjCli	:= SA1->A1_CGC

			// verifica eh o mesmo CNPJ
		ElseIf (_cCnpjCli <> SA1->A1_CGC)
			Aviso("TFATA001 -> sfVldCliente","CNPJ "+Transf(mvCnpj,PesqPict("SA1","A1_CGC"))+" não confere com a nota anterior",{"Fechar"})
			// restaura areas iniciais
			RestOrd(_aAreaIni,.t.)
			RestArea(_aAreaAtu)
			// retorno
			Return(.f.)
		EndIf
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni,.t.)
	RestArea(_aAreaAtu)

Return(.t.)

// ** funcao que valida os itens da nota
Static Function sfVldItens( mvNota, mvSerie )
	// controle do retorno
	local _lRet := .t.
	// controle do item
	local _nItem
	// mensagem de erro
	local _cErroLog := ""
	// controle do item da nota
	local _nItNota
	// relacao de notas de entrada do produto
	local _aNotasEnt := {}
	// item
	local _cItem
	// codigo do produto
	local _cCodProd
	// descricao do produto
	local _cDescProd
	// saldo a ser atendido da quantidade solicitada
	local _nQtdSolic := 0
	// quantidade utilizada da nota
	local _nQuant := 0
	// variavel temporaria de lote
	local _cTmpLotPed  := ""
	local _cTmpLotNf   := ""
	local _cTmpLotProd := ""
	local _cTmpLotSeq  := ""
	local _nTmpLotSel  := 0

	// TES
	local _cTes := ""

	// lote soliciado
	local _cLoteSolic := CriaVar("C6_LOTECTL")

	// variaveis temporarias
	local _cTmpNota, _cTmpSerie
	local _nLote

	// unidade de medida do arquivo
	local _cArqUM := ""

	// itens atendidos
	local _nItensOk := 0

	// numero do pedido do cliente
	local _cNrPedCli := ""

	// quantidade de volumes
	local _nQtdVolumes := 0


	//CNPJ do Cliente de Entrega
	local _cCnpjEnt := ""
	//Nome do cliente de entrega
	local _cNomCliEnt := ""
	// endereco de entrega
	local _cEnderEnt := ""
	//Nome da Cidade De entrega
	local _cNomCidEnt := ""
	//Estado de entrega
	local _cNomEstEnt := ""

	// variaveis temporarias para controle da informacao de quantidade de paletes e volumes
	local _nTmpQtdPlt := 0
	local _nTmpQtdVol := 0

	// carrega array dos itens do XML
	If ( _cTipoArq == "XML" )
		// carrega os itens da nota
		_aItensSol := &( _cBaseXML + "_INFNFE:_DET")
		// se nao conseguiu carrega os itens corretamente
		If (ValType(_aItensSol)<>'A')
			_aItensSol := {}
			aAdd( _aItensSol, &( _cBaseXML + "_INFNFE:_DET") )
		Endif
	EndIf

	// carrega array dos itens do XML
	If ( _cTipoArq == "XML" )

		// reinicia variaveis
		_cTranspPed := ""
		_cPlacaPed  := ""

		// carrega os dados da transportadora
		_aDadTransp := &( _cBaseXML + "_INFNFE:_TRANSP")
		// se nao conseguiu carrega os itens corretamente
		If (ValType(_aDadTransp) <> "A")
			// zera variaveis
			_aDadTransp := {}
			// alimenta vetor com os dados da transportadora
			aAdd( _aDadTransp, &( _cBaseXML + "_INFNFE:_TRANSP") )

			// valida os dados da transportadora
			If ( ! sfVldTransp( Nil, Nil, _aDadTransp ) )
				_lTranspOk := .f.
			EndIf

		Endif
	EndIf

	// adiciona os itens no TRB
	For _nItem := 1 to Len(_aItensSol)

		// zera variaveis
		_cNrPedCli := ""

		// item
		If (_cTipoArq=="XML")
			_cItem := StrZero( Val(_aItensSol[_nItem]:_NITEM:TEXT), 3 )
		ElseIf (_cTipoArq=="TXT")
			_cItem := StrZero(_nItem,3)
		EndIf

		// monta o codigo do produto (sigla + codigo do XML)
		_cCodProd := AllTrim(_cSiglaCli)

		// complementa o codigo do produto
		If (_cTipoArq=="XML")
			_cCodProd += sfLimpaStr(_aItensSol[_nItem]:_PROD:_CPROD:TEXT)
			// se possuir a UM, preenche para posterior validação
			_cArqUM   := Iif( Type("_aItensSol["+AllTrim(Str(_nItem))+"]:_PROD:_UCOM:TEXT") == "C", sfLimpaStr(_aItensSol[_nItem]:_PROD:_UCOM:TEXT), "" )
		ElseIf (_cTipoArq=="TXT")
			_cCodProd += sfLimpaStr(_aItensSol[_nItem][1])
		EndIf

		// padroniza o tamanho do codigo do produto
		_cCodProd := PadR(_cCodProd,Len(SB1->B1_COD))

		// verifica se o produto existe
		dbSelectArea("SB1")
		SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
		If ( ! SB1->(dbSeek( xFilial("SB1")+_cCodProd )))

			// verifica se existe mais de um codigo para o mesmo produto
			If ( (_cSiglaCli == "SUMI") .and. ( Empty(sfVldNewCod(_cCodProd)) ) ) .or. (_cSiglaCli != "SUMI")

				// variavel de retorno
				_lRet := .f.
				// atualiza mensagem de LOG
				_cErroLog += "Incosistência: Item: " + _cItem + " - Produto " + _cCodProd + " não cadastrado!" + CRLF + CRLF
				// loop
				Loop

			EndIf
		EndIf

		// descricao do produto
		_cDescProd := SB1->B1_DESC

		// numero do pedido do cliente
		If (_cTipoArq == "XML").and.(Type("_aItensSol["+AllTrim(Str(_nItem))+"]:_PROD:_xPed:TEXT") == "C")
			_cNrPedCli := AllTrim(_aItensSol[_nItem]:_PROD:_xPed:TEXT)
		ElseIf (_cTipoArq == "TXT")
			_cNrPedCli := _aItensSol[_nItem][ 6]
		EndIf

		// pesquisa pedido de venda
		If ( ! Empty(_cNrPedCli) ).and.(_lVldNrPed)

			// padroniza tamanho do campo
			_cNrPedCli := PadR(_cNrPedCli, TamSx3("C5_ZPEDCLI")[1])

			// pesquisa pelo pedido do cliente no cabecalho
			dbSelectArea("SC5")
			SC5->(DbOrderNickName("SC50000001")) // C5_FILIAL+C5_ZPEDCLI

			// Verifica se encontra pedido para fazer a atualização.
			If SC5->(dbSeek( _cSeekSC5 := xFilial("SC5") + _cNrPedCli ))

				// verifica se é do mesmo cliente
				While (_lRet).and.(SC5->( ! Eof() )).and.(SC5->(C5_FILIAL+C5_ZPEDCLI) == _cSeekSC5)

					// valida se é o mesmo cliente
					If (SC5->C5_CLIENTE == _cCodCli) .and. (SC5->C5_LOJACLI == _cLojaCli)
						// variavel de retorno
						_lRet := .f.
						// atualiza mensagem de LOG
						_cErroLog += "Incosistência: Item: " + _cItem + " - Produto " + AllTrim(_cCodProd) + " / Pedido "+AllTrim(_cNrPedCli)+" já registrado. Número: "+SC5->C5_NUM + CRLF
					EndIf

					// proximo pedido
					SC5->(dbSkip())
				EndDo
			EndIf

			// padroniza tamanho do campo
			_cNrPedCli := PadR(_cNrPedCli, TamSx3("C6_PEDCLI")[1])

			// pesquisa pelo pedido do cliente no cabecalho
			dbSelectArea("SC6")
			SC6->(dbSetOrder(11)) // 11-C6_FILIAL, C6_CLI, C6_LOJA, C6_PEDCLI

			// Verifica se encontra pedido para fazer a atualização.
			If (_lRet).and.(SC6->(dbSeek( _cSeekSC6 := xFilial("SC6") + _cCodCli + _cLojaCli + _cNrPedCli  )))
				// variavel de retorno
				_lRet := .f.
				// atualiza mensagem de LOG
				_cErroLog += "Incosistência: Item: " + _cItem + " - Produto " + AllTrim(_cCodProd) + " / Pedido "+AllTrim(_cNrPedCli)+" já registrado. Número: "+SC6->C6_NUM + CRLF
			EndIf

		EndIf

		// pesquisa chave da nota fiscal de venda
		If ( ! Empty(_cChaveNFe) ).and.(_lVldChvNfv)

			// padroniza tamanho do campo
			_cChaveNFe := PadR(_cChaveNFe, TamSx3("C5_ZCHVNFV")[1])

			// pesquisa pela chave da nota fiscal de venda do cliente no cabecalho
			dbSelectArea("SC5")
			SC5->(DbOrderNickName("C5_ZCHVNFV")) // C5_FILIAL + C5_ZCHVNFV

			// Verifica se encontra a chave da nota fiscal
			If SC5->(dbSeek( _cSeekSC5 := xFilial("SC5") + _cChaveNFe ))

				// verifica se é do mesmo cliente
				While (_lRet).and.(SC5->( ! Eof() )).and.(SC5->(C5_FILIAL+C5_ZCHVNFV) == _cSeekSC5)

					// valida se é o mesmo cliente
					If (SC5->C5_CLIENTE == _cCodCli) .and. (SC5->C5_LOJACLI == _cLojaCli)
						// variavel de retorno
						_lRet := .f.
						// atualiza mensagem de LOG
						_cErroLog += "Incosistência: Item: " + _cItem + " - Produto " + AllTrim(_cCodProd) + " / Chave "+AllTrim(_cChaveNFe)+" já registrado. Número: "+SC5->C5_NUM + CRLF
					EndIf

					// proximo pedido
					SC5->(dbSkip())
				EndDo
			EndIf

		EndIf

		// valido a unidade medida quando for arquivo XML
		If ( _cTipoArq == "XML" )

			// valida a unidade de medida
			If ( ! Empty(_cArqUM) ) .and. ( _cArqUM <> SB1->B1_UM )

				// atualiza mensagem de LOG
				_cErroLog += "Inconsistência: Unidade de Medida do XML (UM: " + _cArqUM + ") é diferente da Unidade de Medida cadastrada (UM: " + SB1->B1_UM + "). Item: "+_cItem+" - Produto " + AllTrim(_cCodProd) + "!" + CRLF
				// controle do retorno
				_lRet := .f.
			EndIf
		EndIf

		// define nota fiscal de origem
		_cTmpNota  := IIf( _cTipoArq == "TXT", _aItensSol[_nItem][3], "" )
		_cTmpSerie := IIf( _cTipoArq == "TXT", _aItensSol[_nItem][4], "" )

		// pesquisa notas fiscais de entrada
		// estrutura do vetor _aNotasEnt
		// 1-B6_DOC
		// 2-B6_SERIE
		// 3-D1_ITEM
		// 4-(B6_SALDO - B6_QULIB)
		// 5-D1_VUNIT
		// 6-D1_TES
		// 7-C6_IDENTB6
		// 8-B6_PRODUTO
		// 9-D1_DESCRIC
		//10-local/armazem
		//11-D1_LOTECTL
		//12-D1_QUANT
		//13-D1_TOTAL

		If ( ! sfVldNfEnt(_cCodProd, @_aNotasEnt, _cTmpNota, _cTmpSerie, "") )
			// variavel de retorno
			_lRet := .f.
			// atualiza mensagem de LOG
			_cErroLog += "Inconsistência : Item: "+_cItem+" - Não foi possível localizar notas fiscais de entrada com saldo suficiente ou disponível/liberado para o produto " + _cCodProd + CRLF + CRLF
			Loop
		EndIf

		// saldo a ser atendido da quantidade solicitada
		If ( _cTipoArq=="XML" )

			_nQtdSolic := Val(_aItensSol[_nItem]:_PROD:_QCOM:TEXT)
		ElseIf ( _cTipoArq=="TXT" )

			_nQtdSolic := _aItensSol[_nItem][2]
		EndIf

		// quantidade de volumes da nota fiscal de venda
		If ( _cTipoArq=="XML" ) .and. (Len(_aDadTransp) > 0) .and. (Type("_aDadTransp[1]:_VOL:_QVOL:TEXT") != "U")
			// define a quantidade de volumes
			_nQtdVolumes := Val(_aDadTransp[1]:_VOL:_QVOL:TEXT)
		EndIf

		// define quantidade de paletes e volumes
		_nTmpQtdPlt := IIf( _cTipoArq == "TXT", _aItensSol[_nItem][12], 0 )
		_nTmpQtdVol := IIf( _cTipoArq == "TXT", _aItensSol[_nItem][11], _nQtdVolumes )

		// varre todas as notas ateh atender o saldo solicitado
		For _nItNota := 1 to Len(_aNotasEnt)

			// somente notas com saldo
			If (_aNotasEnt[_nItNota][4] <= 0)
				Loop
			EndIf

			// zera variavel do lote
			_cLoteSolic := CriaVar("C6_LOTECTL")

			// reinicio a variavel
			_nQuant := 0

			// estrutura do vetor _aNotasEnt
			// 1-B6_DOC
			// 2-B6_SERIE
			// 3-D1_ITEM
			// 4-(B6_SALDO - B6_QULIB)
			// 5-D1_VUNIT
			// 6-D1_TES
			// 7-C6_IDENTB6
			// 8-B6_PRODUTO
			// 9-D1_DESCRIC
			//10-Local/Armazem
			//11-D1_LOTECTL
			//12-D1_QUANT
			//13-D1_TOTAL

			// verifica o saldo por lote
			If ( _lLotAtivo ) .and. ( Rastro(_cCodProd,"L") )

				// estrutura do vetor _aLotesSol
				// 1-seq pedido do cliente
				// 2-seq item no arquivo
				// 3-codigo do produto
				// 4-numero do lote
				// 5-ID do palete
				// 6-Quantidade
				// 7-Saldo

				// varre o vetor de lotes para selecionar de acordo com o item
				For _nLote := 1 to Len(_aLotesSol)

					// controle do saldo do lote
					If (_aLotesSol[_nLote][7] != 0)

						// variavel temporária pro lote
						_cTmpLotProd := PadR( AllTrim(_aLotesSol[_nLote][3])   , TamSx3("D1_COD")[1] )
						_cTmpLotPed  := PadR( AllTrim(_aLotesSol[_nLote][4])   , TamSx3("B8_LOTECTL")[1] )
						_cTmpLotNf   := PadR( AllTrim(_aNotasEnt[_nItNota][11]), TamSx3("D1_LOTECTL")[1] )
						_cTmpLotSeq  := _aLotesSol[_nLote][2]

						// se o produto e lote solicitado é o que foi encontrado nas notas
						If( _cCodProd == _cTmpLotProd ).and.( _cTmpLotPed == _cTmpLotNf ).and.(_aItensSol[_nItem][10] == _cTmpLotSeq)

							// define lote
							_cLoteSolic := _cTmpLotPed

							// grava posicao do vetor, para controle de saldo
							_nTmpLotSel := _nLote

							// sai do loop
							Exit
						EndIf
					EndIf

				Next _nLote

			EndIf

			// se controla lote e não encontrou o lote solicitado vai pra próxima nota
			If ( _lLotAtivo ) .and. ( Rastro(_cCodProd,"L") ) .and. ( Empty(_cLoteSolic) )
				If ( _nItNota == Len(_aNotasEnt) ) .AND. ( Empty(_cLoteSolic) )   //varri todas as notas, mas não consegui localizar saldo para o produto
					// variavel de retorno
					_lRet := .F.

					// atualiza mensagem de LOG
					_cErroLog += "Inconsistência: Não há saldo em NOTAS FISCAIS para o produto " + _aLotesSol[_nItem][3] + "/" + _aLotesSol[_nItem][4] + " ."+CRLF
					_cErroLog += "Solução: Verifique manualmente se não foram devolvidas notas fiscais trocadas ou se o produto " 
					_cErroLog += "é originado de inventário e está aguardando envio de nota fiscal ou com nota incorreta." + CRLF + CRLF

				Else
					Loop
				EndIf
			EndIf

			// se for igual ou menor que o saldo da nota
			If (_nQtdSolic <= _aNotasEnt[_nItNota][4])

				_nQuant := _nQtdSolic
			Else

				_nQuant := _aNotasEnt[_nItNota][4]
			EndIf

			// só carrega as informações quando estiver tudo ok
			If ( _lRet )

				// defino a TES
				_cTes := Posicione("SF4", 1, xFilial("SF4") + _aNotasEnt[_nItNota][6], "F4_TESDV")

				// verifica o cadastro de TES
				If ( Posicione("SF4", 1, xFilial("SF4") + _cTes, "F4_MSBLQL") == "1" )
					// variavel de retorno
					_lRet := .f.
					// atualiza mensagem de LOG
					_cErroLog += "Incosistência: Item: "+_cItem+" - TES " + SF4->F4_CODIGO + " bloqueada para uso" + CRLF + CRLF
					Loop
				EndIf

				// grava os dados no arquivo de trabalho
				dbSelectArea("_TRBSC6")
				RecLock("_TRBSC6", .t.)
				_TRBSC6->IT_SEQPED  := IIf( _cTipoArq == "TXT", _aItensSol[_nItem][ 7], IIf(_lAgrUnicPed, "", _cSeqPedCli) )
				_TRBSC6->C5_ZAGRUPA := IIf( _cTipoArq == "TXT", _aItensSol[_nItem][ 5], "" )
				_TRBSC6->C5_ZPEDCLI := _cNrPedCli
				_TRBSC6->C6_PRODUTO	:= _aNotasEnt[_nItNota][ 8]  // codigo do produto
				_TRBSC6->C6_DESCRI	:= _aNotasEnt[_nItNota][ 9]  // descricao do produto
				_TRBSC6->C6_QTDVEN	:= _nQuant                   // quantidade
				_TRBSC6->C6_PRCVEN	:= _aNotasEnt[_nItNota][ 5]  // preco de venda
				_TRBSC6->C6_NFORI   := _aNotasEnt[_nItNota][ 1]  // nota fiscal de origem
				_TRBSC6->C6_SERIORI := _aNotasEnt[_nItNota][ 2]  // serie da nota fiscal de origem
				_TRBSC6->C6_ITEMORI := _aNotasEnt[_nItNota][ 3]  // item da nota fiscal de origem
				_TRBSC6->C6_IDENTB6 := _aNotasEnt[_nItNota][ 7]  // NUMSEQ de origem
				_TRBSC6->C6_LOCAL   := _aNotasEnt[_nItNota][10]  // local de origem
				_TRBSC6->C6_TES     := _cTes                     // TES de Devolucao
				_TRBSC6->C5_TRANSP  := IIf( _cTipoArq == "TXT", _aItensSol[_nItem][ 8], _cTranspPed )
				_TRBSC6->C5_VEICULO := IIf( _cTipoArq == "TXT", _aItensSol[_nItem][ 9], _cPlacaPed )
				_TRBSC6->C6_LOTECTL := _cLoteSolic
				_TRBSC6->C6_ZQTDVOL := _nTmpQtdVol
				_TRBSC6->C6_ZQTDPLT := _nTmpQtdPlt
				_TRBSC6->C5_ZCHVNFV := _cChaveNFe
				_TRBSC6->C5_ZEMINFV := _dEmissNFe
				_TRBSC6->C5_ZDOCCLI := _cDocNfCli
				_TRBSC6->D1_QUANT   := _aNotasEnt[_nItNota][12] // quantidade total da nota de entrada
				_TRBSC6->D1_TOTAL   := _aNotasEnt[_nItNota][13] // valor total da nota de entrada
				_TRBSC6->(MsUnLock())

				// controle da quantidade atendida
				_nQtdSolic -= _nQuant
				// diminui o saldo da nota
				_aNotasEnt[_nItNota][4] -= _nQuant

				// zera variaveis, para nao duplicar linhas do pedido quando usar o saldo de mais de uma nota fiscal
				_nTmpQtdVol := 0
				_nTmpQtdPlt := 0

				// diminui o saldo do controle do lote
				If ( _lLotAtivo ) .and. ( Rastro(_cCodProd,"L") ) .and. ( ! Empty(_cLoteSolic) ).and.(_nTmpLotSel != 0)
					// reduza controle de saldo do lote
					_aLotesSol[_nTmpLotSel][7] -= _nQuant
				EndIf

				// se o saldo da quantidade solicitada foi atendido
				If ( _nQtdSolic == 0 )
					Exit
					// se nao tem saldo suficiente para atender a quandidade solicitada
				ElseIf ( _nQtdSolic > 0 ) .and. ( Len(_aNotasEnt) == _nItNota )

					// variavel de retorno
					_lRet := .f.
					// atualiza mensagem de LOG
					_cErroLog += "Inconsistência: Item: " + _cItem + " - Saldo Insuficiente do produto: " + AllTrim(_cCodProd) + CRLF + CRLF
					Loop
				EndIf

			EndIf

		Next _nItNota

		// se não conseguiu atender a quantidade solicitada com as notas fiscais localizadas (chegou aqui com quantidade maior que zero)
		If ( _nQtdSolic > 0 )
			// variavel de retorno
			_lRet := .F.
			// atualiza mensagem de LOG
			_cErroLog += "Inconsistência: Item: " + _cItem + " - Saldo fiscal insuficiente do produto: " + AllTrim(_cCodProd) + CRLF + CRLF
			_cErroLog += "Solução: Verifique se as notas fiscais estão classificadas, se existem notas válidas e/ou se as notas foram operacionalizadas com WMS (não há pendências - OS) " + CRLF + CRLF
		EndIf

	Next _nItem

	// atualiza dados de entrega do pedido
	If (_lRet) .AND. (_cTipoArq=="XML" )

		// reinicia variaveis
		_cCnpjEnt   := ""
		_cNomCliEnt := ""
		_cEnderEnt  := ""
		_cNomCidEnt := ""
		_cNomEstEnt := ""

		// cnpj/cpf de entrega
		If (Type(_cBaseXML+"_INFNFE:_DEST:_CNPJ:TEXT") == "C")
			_cCnpjEnt := &(_cBaseXML+"_INFNFE:_DEST:_CNPJ:TEXT")
		ElseIf (Type(_cBaseXML+"_INFNFE:_DEST:_CPF:TEXT") == "C")
			_cCnpjEnt := &(_cBaseXML+"_INFNFE:_DEST:_CPF:TEXT")
		EndIf

		// nome cliente
		_cNomCliEnt := &(_cBaseXML+"_INFNFE:_DEST:_XNOME:TEXT")

		// endereco + numero
		_cEnderEnt := &(_cBaseXML+"_INFNFE:_DEST:_ENDERDEST:_XLGR:TEXT")
		_cEnderEnt += ", "
		_cEnderEnt += &(_cBaseXML+"_INFNFE:_DEST:_ENDERDEST:_NRO:TEXT")
		// complemento de endereco
		If (Type(_cBaseXML+"_INFNFE:_DEST:_ENDERDEST:_XCPL:TEXT") == "C")
			_cEnderEnt += " " + &(_cBaseXML+"_INFNFE:_DEST:_ENDERDEST:_XCPL:TEXT")
		EndIf

		// cidade
		_cNomCidEnt := &(_cBaseXML+"_INFNFE:_DEST:_ENDERDEST:_XMUN:TEXT")

		// estado
		_cNomEstEnt := &(_cBaseXML+"_INFNFE:_DEST:_ENDERDEST:_UF:TEXT")

		// adiciona os dados do endereco de entrega
		aAdd(_aDadosEnt,{_cSeqPedCli             ,;
		sfLimpaStr(_cCnpjEnt  ,.f. ,.t., "A1_CGC")     ,;
		sfLimpaStr(_cNomCliEnt,.f. ,.t., "C5_ZCLIENT") ,;
		sfLimpaStr(_cEnderEnt ,.f. ,.t., "C5_ZENDENT") ,;
		sfLimpaStr(_cNomCidEnt,.f. ,.t., "C5_ZCIDENT") ,;
		sfLimpaStr(_cNomEstEnt,.f. ,.t., "C5_ZUFENTR") })

	EndIf

	// quando for XML, faz o controle da sequencia de pedidos
	If (_cTipoArq=="XML" ).and.( ! _lAgrUnicPed )
		// sequencia do pedido do cliente
		_cSeqPedCli := Soma1(_cSeqPedCli)
	EndIf

	// se controla lote, vou validar se encontrou tudo que precisava
	If ( _lLotAtivo )

		// volta pro inicio do TRB
		_TRBSC6->( dbGoTop() )
		While ( _TRBSC6->( ! EoF() ) )
			// valida se controla rastro
			If ( Rastro(_TRBSC6->C6_PRODUTO,"L") .and. Empty( _TRBSC6->C6_LOTECTL ) )

				// variavel de retorno
				_lRet := .f.

				// atualiza mensagem de LOG
				_cErroLog += "Inconsistência: Não há saldo em lote para o produto " + _TRBSC6->C6_PRODUTO + "."+CRLF
				_cErroLog += "Solução: Verifique se há saldo do lote solicitado para o produto informado." + CRLF + CRLF
				_nItensOk := (_nItensOk-1)
			EndIf

			_TRBSC6->( dbSkip() )
		EndDo
	EndIf

	// se ocorreu algum erro, apresenta mensagem
	If ( ! _lRet ) .and. ( ! Empty(_cErroLog) )

		HS_MsgInf("LOG de Importação:"+CRLF+_cErroLog,"Log de Importação","Inconsistência" + ;
		Iif( ! Empty(mvNota), ": Nota: " + mvNota+" / Série: "+mvSerie, "" ) )
	EndIf

Return(_lRet)

// ** funcao que remove os acentos e caracteres especiais
Static Function sfLimpaStr(mvString, mvRemovSpc, mvRemSpcDpl, mvCampo)
	Local cChar  := ""
	Local nX     := 0
	Local nY     := 0
	Local cVogal := "AEIOU"
	Local cAgudo := "ÁÉÍÓÚ"
	Local cCircu := "ÂÊÎÔÛ"
	Local cTrema := "ÄËÏÖÜ"
	Local cCrase := "ÀÈÌÒÙ"
	Local cTio   := "ÃÕ"
	Local cCecid := "Ç"

	// tamanho do campo
	local _nTamCampo := 0

	// controle de while
	local _lProc := .f.

	// define o padrao para nao remover
	default mvRemovSpc  := .f.
	default mvRemSpcDpl := .f.
	default mvCampo     := ""

	// maiusculo
	mvString := Upper(mvString)
	// sem espacos
	mvString := AllTrim(mvString)

	// remove todos os espacos em branco
	If (mvRemovSpc)
		mvString := StrTran(mvString," ","")
	EndIf

	// remove todos os espacos em branco duplicados
	If (mvRemSpcDpl)

		// verifica a necessidade de processar espacos duplicados
		_lProc := (At("  ",mvString) > 0)

		// remove espaco em branco duplicados (dois espacos)
		While (_lProc)
			// remove espacos duplicados
			mvString := StrTran(mvString,"  "," ")
			// verifica a necessidade de processar espacos duplicados
			_lProc := (At("  ",mvString) > 0)
		EndDo

	EndIf

	// tamanho do campo
	If ( ! Empty(mvCampo) )
		_nTamCampo := TamSx3(mvCampo)[1]
	Else
		_nTamCampo := Len(mvString)
	EndIf

	// varre todos os caracteres
	For nX := 1 To Len(mvString)
		cChar := SubStr(mvString, nX, 1)
		IF (cChar $ cAgudo+cCircu+cTrema+cCecid+cTio+cCrase)
			nY:= At(cChar,cAgudo)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCircu)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTrema)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCrase)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTio)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr("AO",nY,1))
			EndIf
			nY:= At(cChar,cCecid)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr("C",nY,1))
			EndIf
		Endif
	Next

	For nX := 1 To Len(mvString)
		cChar := SubStr(mvString, nX, 1)
		If (Asc(cChar) < 32).Or.(Asc(cChar) > 123).Or.(cChar $ '&').Or.(cChar $ '"').Or.(cChar $ "'")
			mvString := StrTran(mvString,cChar,".")
		Endif
	Next nX

	// limita o retorno confome tamanho do campo
	mvString := SubStr(mvString,1,_nTamCampo)

Return(mvString)

// ** funcao interna padrao do SPEDNFE
// utilizada para consultar o status da NFe no SEFAZ
Static Function ConsNFeChave(cChaveNFe, cIdEnt, mvMsgConsNF)

	Local cURL      := PadR(GetNewPar("MV_SPEDURL","http://"),250)
	Local cMensagem := ""
	Local oWS
	local _lRet := .f.

	oWs := WsNFeSBra():New()
	oWs:cUserToken   := "TOTVS"
	oWs:cID_ENT    := cIdEnt
	ows:cCHVNFE		 := cChaveNFe
	oWs:_URL         := AllTrim(cURL)+"/NFeSBRA.apw"

	If oWs:ConsultaChaveNFE()

		If !Empty(oWs:oWSCONSULTACHAVENFERESULT:cVERSAO)
			cMensagem += "Versão da mensagem: "+oWs:oWSCONSULTACHAVENFERESULT:cVERSAO+CRLF
		EndIf

		cMensagem += "Ambiente: "+IIf(oWs:oWSCONSULTACHAVENFERESULT:nAMBIENTE==1,"Produção","Homologação")+CRLF
		cMensagem += "Cod.Ret.NFe: "+oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE+CRLF
		cMensagem += "Msg.Ret.NFe: "+oWs:oWSCONSULTACHAVENFERESULT:cMSGRETNFE+CRLF

		// variavel de retorno (nota valida e ambiente producao)
		_lRet := (AllTrim(oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE)=="100").and.(oWs:oWSCONSULTACHAVENFERESULT:nAMBIENTE==1)

		If !Empty(oWs:oWSCONSULTACHAVENFERESULT:cPROTOCOLO)
			cMensagem += "Protocolo: "+oWs:oWSCONSULTACHAVENFERESULT:cPROTOCOLO+CRLF
		EndIf

		// verifica se deve apresentar mensagens de confirmacao da nota valida
		If (mvMsgConsNF)
			mvMsgConsNF := (Aviso("Consulta NF",cMensagem,{"Ok", "Ok - Todas"},3) == 1)
		EndIf
	Else
		Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"Ok"},3)
	EndIf

Return(_lRet)

// ** funcao que pesquisa as notas de entrada para o produto
Static Function sfVldNfEnt(mvCodProd, mvNotasEnt, mvNfEnt, mvSerEnt, mvLoteCtl)
	// variavel de retorno
	local _lRet := .f.
	// query de pesquisa
	local _cQuery := ""
	// area inicial
	local _aAreaTRB := _TRBSC6->(GetArea())
	// variaveis temporarias
	local _nX
	// novo codigo de produto
	local _cNewCodProd := CriaVar("B1_COD",.f.)

	// valor padrao
	Default mvLoteCtl := CriaVar("B8_LOTECTL", .f.)

	// zera a variavel
	mvNotasEnt := {}

	// verifica se existe mais de um codigo para o mesmo produto
	If (_cSiglaCli == "SUMI")
		_cNewCodProd := sfVldNewCod(mvCodProd)
	EndIf

	// busca todas as notas de entrada deste produto com saldo
	_cQuery := "SELECT B6_DOC, B6_SERIE, D1_ITEM, "
	_cQuery += "(B6_SALDO - B6_QULIB "
	_cQuery += " - Isnull((SELECT Sum(C0_QUANT) FROM " +RetSqlTab("SC0")+ " WHERE SB6.B6_IDENT = C0_ZIDENT AND SB6.B6_DOC = C0_ZNOTA AND SB6.B6_SERIE = C0_ZSERIE AND "+RetSqlCond("SC0")+"),0) "
	_cQuery += " - Isnull((SELECT Sum(DA_SALDO) FROM " +RetSqlTab("SDA")+ " WHERE SB6.B6_IDENT = DA_NUMSEQ AND SB6.B6_DOC = DA_DOC AND SB6.B6_SERIE = DA_SERIE AND "+RetSqlCond("SDA")+"),0)) B6_SALDO,   "
	_cQuery += "D1_VUNIT, D1_TES, B6_IDENT, B6_PRODUTO, D1_DESCRIC, B6_LOCAL, D1_LOTECTL, D1_QUANT, D1_TOTAL "
	// saldo poder de terceiros
	_cQuery += "FROM "+RetSqlName("SB6")+" SB6 "
	// dados dos itens das notas de entrada
	_cQuery += "INNER JOIN "+RetSqlName("SD1")+" SD1 ON D1_FILIAL = B6_FILIAL AND SD1.D_E_L_E_T_ = ' ' "
	_cQuery += "      AND D1_DOC = B6_DOC AND D1_SERIE = B6_SERIE AND D1_FORNECE = B6_CLIFOR AND D1_LOJA = B6_LOJA "
	_cQuery += "      AND D1_COD = B6_PRODUTO AND D1_IDENTB6 = B6_IDENT "
	_cQuery += "      AND D1_TIPO = 'B' "
	// filtro do poder de terceiros
	_cQuery += "WHERE B6_FILIAL = '"+xFilial("SB6")+"' AND SB6.D_E_L_E_T_ = ' ' "
	_cQuery += "AND B6_CLIFOR = '"+_cCodCli+"' AND B6_LOJA = '"+_cLojaCli+"' "
	_cQuery += "AND ("
	_cQuery += "     B6_PRODUTO = '"+mvCodProd+"' "
	If ( ! Empty(_cNewCodProd))
		_cQuery += " OR B6_PRODUTO = '"+_cNewCodProd+"' "
	EndIf
	_cQuery += ") "
	// tipo (Cliente ou Fornecedor)
	_cQuery += "AND B6_TPCF = 'C' "
	// poder de 3o - REMESSA
	_cQuery += "AND B6_PODER3 = 'R' "
	// somente com saldo
	_cQuery += "AND (B6_SALDO - B6_QULIB - Isnull((SELECT Sum(C0_QUANT) FROM " +RetSqlName("SC0")+ " SC0 WHERE SB6.B6_IDENT = C0_ZIDENT AND SB6.B6_DOC = C0_ZNOTA AND SB6.B6_SERIE = C0_ZSERIE AND "+RetSqlCond("SC0")+"),0)) > 0 "
	// filtra informacoes por nota, caso tenha sido informado
	If (_cTipoArq=="XML").and.( ! Empty(_cNotasSel) )
		_cQuery += "AND B6_DOC+B6_SERIE IN ("+StrTran(_cNotasSel,"/","")+")

	ElseIf (_cTipoArq=="TXT").and.( ! Empty(mvNfEnt) ).and.( ! Empty(mvSerEnt) )
		_cQuery += "AND B6_DOC = '"+mvNfEnt+"' AND B6_SERIE = '"+mvSerEnt+"' "

	EndIf

	// ordem por data de digitacao de documentos
	_cQuery += "ORDER BY B6_DTDIGIT, B6_SERIE, B6_DOC "

	MemoWrit("c:\query\tfata001_sfVldNfEnt.txt", _cQuery)

	// converte resultado para ARRAY
	mvNotasEnt := U_SqlToVet(_cQuery)
	// variavel de retorno
	_lRet := (Len(mvNotasEnt)>0)

	// varre as notas com saldo para descontar o saldo utilizado em outros arquivos XML
	For _nX := 1 to Len(mvNotasEnt)
		// varre o arquivo TRB para descontar o saldo utilizado em outros arquivos XML
		dbSelectArea("_TRBSC6")
		_TRBSC6->(dbGoTop())
		While _TRBSC6->(!Eof())
			// verifica se eh mesma nota, serie e item
			If (_TRBSC6->C6_NFORI == mvNotasEnt[_nX][1]).and.(_TRBSC6->C6_SERIORI == mvNotasEnt[_nX][2]).and.;
			(_TRBSC6->C6_ITEMORI == mvNotasEnt[_nX][3]).and.(_TRBSC6->C6_PRODUTO == mvCodProd)

				// desconta o saldo disponivel
				mvNotasEnt[_nX][4] -= _TRBSC6->C6_QTDVEN

			EndIf
			// proximo item
			_TRBSC6->(dbSkip())
		EndDo
	Next _nX

	// restaura area inicial
	RestArea(_aAreaTRB)

Return(_lRet)

// ** funcao para selecionar as notas
Static Function sfDefNotas()
	// query
	local _cQuery
	local _nX
	// notas disponiveis
	local _aListaNf := {}
	// controle da confirmacao
	local _lRet := .f.
	// mensagem de validacao da nota XML
	local _lMsgConsNF := .t.

	// verifica se tem arquivo XML selecionado
	If (Len(_vListaArq)==0)
		Aviso("TFATA001 -> sfDefNotas","É obrigatório selecionar um arquivo.",{"Fechar"})
		Return(.f.)
	EndIf

	// executa leitura do XML para buscar o codigo do cliente
	If ( ! sfVldArquivo(_vListaArq[1], .t., .t., @_lMsgConsNF) )
		Return(.f.)
	EndIf

	// reinicia variaveis
	_cNotasSel := ""

	// executa a pesquisa das notas do cliente com saldo
	_cQuery := "SELECT DISTINCT '[ ] '+B6_DOC+'/'+B6_SERIE IT_NOTAS "
	// saldo de terceiros
	_cQuery += "FROM "+RetSqlName("SB6")+" SB6 "
	// filtro das notas
	_cQuery += "WHERE "+RetSqlCond("SB6")+" "
	_cQuery += "AND B6_CLIFOR = '"+_cCodCli+"' AND B6_LOJA = '"+_cLojaCli+"' "
	_cQuery += "AND B6_PODER3 = 'R' "
	_cQuery += "AND B6_TPCF = 'C' "
	_cQuery += "AND (B6_SALDO - B6_QULIB - Isnull((SELECT Sum(C0_QUANT) FROM " +RetSqlName("SC0")+ " SC0 WHERE SB6.B6_IDENT = C0_ZIDENT AND SB6.B6_DOC = C0_ZNOTA AND SB6.B6_SERIE = C0_ZSERIE AND "+RetSqlCond("SC0")+"),0)) > 0 "
	// ordem dos dados
	_cQuery += "ORDER BY IT_NOTAS "
	// alimenta o vetor
	_aListaNf := U_SqlToVet(_cQuery)

	If (Len(_aListaNf)==0)
		Aviso("TFATA001 -> sfDefNotas","Não há notas fiscais com saldo disponível.",{"Fechar"})
		Return(.f.)
	EndIf

	// definicao da tela com as notas para selecionar
	_oDlgNfDisp := MSDialog():New(000,000,260,190,"Notas disponíveis",,,.F.,,,,,,.T.,,,.T. )
	// cria o panel do cabecalho
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgNfDisp,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// botao para detahes do dia
	oBtnConfirma := TButton():New(005,005,"Confirmar",_oPnlCabec,{|| _lRet:=.t.,_oDlgNfDisp:End() },040,010,,,,.T.,,"",,,,.F. )
	// botao pra fechar
	oBtnSair := TButton():New(005,050,"Fechar",_oPnlCabec,{||_oDlgNfDisp:End()},040,010,,,,.T.,,"",,,,.F. )
	// lista com as notas disponiveis
	_oLstNfDisp := TListBox():New(000,000,,_aListaNf,260,140,,_oDlgNfDisp,,,,.T.,,{|| sfSelItem(_oLstNfDisp) },_oFonte01,"",,,,,,, )
	_oLstNfDisp:Align := CONTROL_ALIGN_ALLCLIENT
	// ativa o dialogo
	_oDlgNfDisp:Activate(,,,.T.,)

	// se confirmou
	If (_lRet)
		// varre verifica as notas selecionadas
		For _nX := 1 to Len(_aListaNf)
			If (SubStr(_aListaNf[_nX],2,1)=="X")
				_cNotasSel += If(Empty(_cNotasSel),"",",")+"'"+SubStr(_aListaNf[_nX],5)+"'"
			EndIf
		Next _nX
	EndIf

Return

// ** funcao para selecionar o item dentro do ListBox
Static Function sfSelItem(mvListBox)
	// retorna os itens do objeto
	local _aItensLista := mvListBox:aItems
	// retorna o conteudo da linha atual
	local _cLinhaAtu := _aItensLista[mvListBox:nAt]
	// opcao do item atual
	local _cOpcAtu := Left(_cLinhaAtu,3)
	// nova condicao
	local _cOpcNew := If(_cOpcAtu=="[ ]","[X]","[ ]")

	// altera opcao
	mvListBox:Modify(_cOpcNew + SubStr(_cLinhaAtu,4),mvListBox:nAt)

Return

// ** funcao que monta tela para informar volumes/especies
Static Function sfVolumes(mvVolume, mvEspecie)
	local _lOk := .f.
	local _oDlgInfVlr, _oBtnConf
	// cod. especie
	private _cCodEspe := CriaVar("C5_ZCDESP1",.f.)

	// monta a tela para alterar o peso e a cubagem
	_oDlgInfVlr := MSDialog():New(000,000,160,240,"Volumes/Espécies",,,.F.,,,,,,.T.,,,.T. )
	// volume
	_oSayVol := TSay():New(017,010,{||"Volumes:"},_oDlgInfVlr,,,.F.,.F.,.F.,.T.)
	_oGetVol := TGet():New(015,050,{|u| If(PCount()>0,mvVolume:=u,mvVolume)},_oDlgInfVlr,060,010,PesqPict("SC5","C5_VOLUME1"),,,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","mvVolume",,)
	// especie
	_oSayEsp := TSay():New(032,010,{||"Espécie:"},_oDlgInfVlr,,,.F.,.F.,.F.,.T.)
	_oGetEsp := TGet():New(030,050,{|u| If(PCount()>0,_cCodEspe:=u,_cCodEspe)},_oDlgInfVlr,060,010,PesqPict("SC5","C5_ZCDESP1"),{||ExistCpo("SX5","CL"+_cCodEspe)},,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"CL","_cCodEspe",,)

	// botao para confirmar
	_oBtnConf := TButton():New(060,040,"Confirmar",_oDlgInfVlr,{||_lOk:=.t.,_oDlgInfVlr:End()},050,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgInfVlr:Activate(,,,.T.,{|| ((mvVolume > 0).and.(!Empty(_cCodEspe))) })

	// atualiza a descricao
	mvEspecie := Tabela("CL",_cCodEspe)

Return(_lOk)

// ** tela para definir o tipo de arquivo a ser importado
Static Function sfDefTpArq()

	local _oDlgOpcoes, _oBtnXML, _oBtnTXT, _oBtnSair
	local _lFixaMain := .f.

	// definicao da tela
	_oDlgOpcoes := MSDialog():New(000,000,200,218,"Opções de Arquivos",,,.F.,,,,,,.T.,,,.T. )
	// opcoes de arquivos
	_oBtnXML := TButton():New(010,010,"Arquivo XML",_oDlgOpcoes,{|| _lFixaMain := .t. , _cTipoArq := "XML" , _oDlgOpcoes:End() },090,020,,_oFonte02,,.T.,,"",,,,.F. )
	_oBtnTXT := TButton():New(040,010,"Arquivo TXT",_oDlgOpcoes,{|| _lFixaMain := .t. , _cTipoArq := "TXT" , _oDlgOpcoes:End() },090,020,,_oFonte02,,.T.,,"",,,,.F. )
	// botao para sair
	_oBtnSair  := TButton():New(070,010,"Sair",_oDlgOpcoes,{|| _oDlgOpcoes:End() },090,020,,_oFonte02,,.T.,,"",,,,.F. )
	// ativa o dialogo
	_oDlgOpcoes:Activate(,,,.T.,)

Return(_lFixaMain)

// ** funcao para validar a estrutura do arquivo TXT
Static Function sfVldArqTxt( mvArquivo, mvCnpj, mvGetCli )
	// variaveis temporarias
	local _vLinha := {}
	// CPNJ
	local _cTmpCnpj := ""
	// sigla do cliente
	local _cTmpSigla
	//Nome do Arquivo
	Local _cNomArq := ""

	// verifica o uso de referencia agrupadora por cliente
	local _lUsaRefAgrup := .f.

	// numero do pedido do cliente
	local _cNrPedCli := ""
	local _cTmpPedCli := ""

	//CNPJ do Cliente de Entrega
	local _cCnpjEnt := ""
	//Nome do cliente de entrega
	local _cNomCliEnt := ""
	// endereco de entrega
	local _cEnderEnt := ""
	//Nome da Cidade De entrega
	local _cNomCidEnt := ""
	//Estado de entrega
	local _cNomEstEnt := ""

	// seek
	local _cSeekSC5
	local _cSeekSC6

	// dados para valiacao do pallet
	local _cCodPrdLot := ""
	local _cNrLote    := ""
	local _cIdPalete  := ""
	local _nQtdSolLot := 0

	// referente do item dentro do arquivo (sempre iniciar com 0-Zero)
	local _cItemArq := StrZero(0,TamSx3("C6_ITEM")[1])

	// quantidade de volumes
	local _nQtdVolumes := 0

	// quantidade de paletes
	local _nQtdPaletes := 0

	// variavel usada pra validar se o acesso a rotina é só pra pegar o cliente
	default mvGetCli := .f.

	// verifica se o arquivo existe
	If ( ! File(mvArquivo) )
		Aviso("TFATA001 -> sfVldArqTxt","Arquivo "+AllTrim(mvArquivo)+" não encontrado.",{"Fechar"})
		Return(.f.)
	EndIf

	// abre o arquivo TXT
	FT_FUse(mvArquivo)
	FT_FGoTop()

	//Divide um caminho de disco completo em todas as suas subpartes (drive, diretório, nome e extensão)
	SplitPath(mvArquivo,,,@_cNomArq,)

	// varre todas as linhas do arquivo
	While ( ! FT_FEof() )

		// extrai e separa os dados da linha corrente
		_vLinha := Separa(FT_FReadln(),"^")

		// verifica se eh o cabecalho
		If (Len(_vLinha)>0).and.(AllTrim(_vLinha[1])=="0")
			// pega o codigo do CNPJ
			If (Len(_vLinha)>1)
				_cTmpCnpj := AllTrim(_vLinha[2])
				// remove pontos
				_cTmpCnpj := StrTran(_cTmpCnpj,".","")
				// remove barras
				_cTmpCnpj := StrTran(_cTmpCnpj,"/","")
				// remove hifen
				_cTmpCnpj := StrTran(_cTmpCnpj,"-","")
			EndIf

			// verifica se a base do CNPJ é o mesmo
			If ( ! Empty(mvCnpj) ).and.(Left(_cTmpCnpj,8) <> Left(mvCnpj,8))
				Aviso("TFATA001 -> sfVldArqTxt","Só são permitidos pedidos de um mesmo cliente.",{"Fechar"})
				Return(.f.)
			EndIf

			// valida os dados do cliente
			If ( ! sfVldCliente(_cTmpCnpj) )
				_lClienOk := .f.
			EndIf

			// caso a consulta seja apenas para validar o cliente
			If ( mvGetCli )
				Return .t.
			EndIf

			// se dados do cliente Ok
			If (_lClienOk)

				// verifica o uso de referencia agrupadora por cliente
				_lUsaRefAgrup := U_FtWmsParam("WMS_USO_REFERENCIA_AGRUPADORA_PEDIDO", "L", .f., .f., "", _cCodCli, _cLojaCli, Nil, Nil)

				// verifica se o controle de lote esta ativo
				_lLotAtivo := U_FtWmsParam("WMS_CONTROLE_POR_LOTE", "L", .F. , .F.,Nil, _cCodCli, _cLojaCli, Nil, Nil)

			EndIf

			// para Samsonite, pega o nome do Agrupador para informar no PV que sempre sera o nome do Arquivo.
			If (_lUsaRefAgrup).and.(_cSiglaCli == "SAMS")
				_cRefAgrupa := AllTrim(Upper(_cNomArq))
			EndIf

			// se nao usar Referencia Agrupadora, zera conteudo
			If ( ! _lUsaRefAgrup)
				_cRefAgrupa := CriaVar("C5_ZAGRUPA", .f.)
			EndIf

			// sequencia do pedido do cliente
			_cSeqPedCli := Soma1(_cSeqPedCli)

			// numero do pedido do cliente / agrupadora
			If (Len(_vLinha)>=3)
				// para cliente Portobello, utiliza o número do pedido do cabeçalho como a agrupadora (chamado de "percurso" pelo cliente)
				If (_cSiglaCli == "PTBL")
					_cRefAgrupa := AllTrim(_vLinha[3])
					_cRefAgrupa := PadR(_cRefAgrupa,TamSx3("C5_ZAGRUPA")[1])
				Else
					_cNrPedCli := AllTrim(_vLinha[3])
					_cNrPedCli := PadR(_cNrPedCli,TamSx3("C5_ZPEDCLI")[1])
				EndIf

				// verifica se o pedido ja foi importado
				dbSelectArea("SC6")
				SC6->(dbSetOrder(11)) // 11-C6_FILIAL, C6_CLI, C6_LOJA, C6_PEDCLI

				// Verifica se encontra pedido para fazer a atualização.
				If !Empty(_cNrPedCli) .AND. SC6->(dbSeek( _cSeekSC6 := xFilial("SC6") + _cCodCli + _cLojaCli + _cNrPedCli  ))
					Aviso("TFATA001 -> sfVldArqTxt","Ped.Cliente: "+AllTrim(_cNrPedCli)+" --> Pedido do Cliente já importado no Nosso Pedido: "+SC6->C6_NUM,{"Fechar"})
					_lItensOk := .f.
					Return(.f.)
				EndIf

			Else
				_cNrPedCli := ""
			EndIf

			// transportadora
			If (Len(_vLinha)>=4) .AND. !(Empty(_vLinha[4]))
				// valida os dados da transportadora
				If ( ! sfVldTransp(AllTrim(_vLinha[4]), IIf(Len(_vLinha)>=5,AllTrim(_vLinha[5]),""), Nil ))
					_lTranspOk := .f.
				EndIf
			Else
				_cTranspPed := ""
				_cPlacaPed  := ""
			EndIf

			// Nota Fiscal do Cliente
			If (Len(_vLinha)>=6)
				_cNrDocCli := AllTrim(_vLinha[6])
			EndIf

		// verifica se eh o item
		ElseIf (Len(_vLinha)>0).and.(AllTrim(_vLinha[1])=="1")

			// reinicia variaveis
			_nQtdVolumes := 0
			_nQtdPaletes := 0

			// pega o codigo do produto
			If (Len(_vLinha)>1)

				// verifica se tem pedido do cliente informado no cabeçalho, caso contrário, utiliza o pedido da linha
				// e para cliente Portobello, o número do pedido do cabeçalho é a agrupadora (percurso) então deve utilizar sempre o da linha também
				If (Len(_vLinha) >= 7) .AND. (Empty(_cNrPedCli) .OR. (_cSiglaCli == "PTBL"))
					// extrai o numero do pedido do cliente
					_cNrPedCli := AllTrim(_vLinha[7])
					_cNrPedCli := PadR(_cNrPedCli,TamSx3("C6_PEDCLI")[1])

					// no segundo pedido do arquivo, compara para verificar necessidade de quebra de pedidos
					If ( ! Empty(_cTmpPedCli) ).and.(AllTrim(_cTmpPedCli) != AllTrim(_cNrPedCli))
						// sequencia do pedido do cliente
						_cSeqPedCli := Soma1(_cSeqPedCli)
					EndIf

					// verifica se o pedido ja foi importado
					dbSelectArea("SC6")
					SC6->(dbSetOrder(11)) // 11-C6_FILIAL, C6_CLI, C6_LOJA, C6_PEDCLI

					// Verifica se encontra pedido para fazer a atualização.
					If !Empty(_cNrPedCli) .AND. SC6->(dbSeek( _cSeekSC6 := xFilial("SC6") + _cCodCli + _cLojaCli + _cNrPedCli  ))
						Aviso("TFATA001 -> sfVldArqTxt","Ped.Cliente: "+AllTrim(_cNrPedCli)+" --> Pedido do Cliente já importado no Nosso Pedido: "+SC6->C6_NUM,{"Fechar"})
						_lItensOk := .f.
						Return(.f.)
					EndIf

					// atualiza controle
					_cTmpPedCli := _cNrPedCli

				EndIf

				// verifica se tem quantidade volumes por item informado
				If (Len(_vLinha) >= 8)
					_nQtdVolumes := Val(_vLinha[8])
				EndIf

				// verifica se tem quantidade de paletes por item informado
				If (Len(_vLinha) >= 9)
					_nQtdPaletes := Val(_vLinha[9])
				EndIf

				// verifica se conseguiu importar um número de pedido do cliente (seja pela linha de item ou pelo cabeçalho)
				If ( Empty(_cNrPedCli) )
					Aviso("TFATA001 -> sfVldArqTxt","Layout do arquivo de importação inválido."; 
					 + CRLF;
					 + "Não foi encontrado o número do pedido do cliente no arquivo, seja nas linhas do item ou no cabeçalho.";
					 + CRLF;
					 + "O número do pedido do cliente é OBRIGATÓRIO e este arquivo será recusado.",;
					{"Fechar"})
					_lItensOk := .F.
					Return( .F. )
				EndIf
				
				// incremento do item
				_cItemArq := Soma1(_cItemArq)

				// adiciona as informacoes do item
				aAdd(_aItensSol,{;
				AllTrim(_vLinha[2])                          ,; // 1- cod produto
				StoV(_vLinha[4])                             ,; // 2- quantidade solicitada
				IIf((Len(_vLinha)>4),AllTrim(_vLinha[5]),"") ,; // 3- nota fiscal
				IIf((Len(_vLinha)>5),AllTrim(_vLinha[6]),"") ,; // 4- serie da nota fiscal
				_cRefAgrupa                                  ,; // 5- ref agrupadora do cliente
				_cNrPedCli                                   ,; // 6- numero do pedido do cliente
				_cSeqPedCli                                  ,; // 7- Seq Pedido Cliente
				_cTranspPed                                  ,; // 8- Transportadora
				_cPlacaPed                                   ,; // 9- Placa
				_cItemArq                                    ,; //10- Ref Item no Arquivo
				_nQtdVolumes                                 ,; //11- Quantidade de Volumes
				_nQtdPaletes                                 }) //12- Quantidade de Paletes

			EndIf

			// Verifica se é informações adicionais Dados de Entrega.
		ElseIf (Len(_vLinha)>0).and.(AllTrim(_vLinha[1])=="2")

			// pega o codigo do CNPJ
			If (Len(_vLinha)>1)
				_cCnpjEnt := AllTrim(_vLinha[2])
				// remove pontos
				_cCnpjEnt := StrTran(_cCnpjEnt,".","")
				// remove barras
				_cCnpjEnt := StrTran(_cCnpjEnt,"/","")
				// remove hifen
				_cCnpjEnt := StrTran(_cCnpjEnt,"-","")
			EndIf

			// Nome Cliente de entrega
			If (Len(_vLinha)>=3)
				_cNomCliEnt := AllTrim(_vLinha[3])
			Else
				_cNomCliEnt := ""
			EndIf

			// Endereço de entrega
			If (Len(_vLinha)>=4)
				_cEnderEnt := AllTrim(_vLinha[4])
			Else
				_cEnderEnt := ""
			EndIf

			// Cidade de entrega
			If (Len(_vLinha)>=5)
				_cNomCidEnt := AllTrim(_vLinha[5])
			Else
				_cNomCidEnt := ""
			EndIf

			// UF de entrega
			If (Len(_vLinha)>=6)
				_cNomEstEnt := AllTrim(_vLinha[6])
			Else
				_cNomEstEnt := ""
			EndIf

			// atualiza dados de entrega do pedido
			aAdd(_aDadosEnt,{_cSeqPedCli             ,;
			sfLimpaStr(_cCnpjEnt  ,.f. ,.t., "A1_CGC")     ,;
			sfLimpaStr(_cNomCliEnt,.f. ,.t., "C5_ZCLIENT") ,;
			sfLimpaStr(_cEnderEnt ,.f. ,.t., "C5_ZENDENT") ,;
			sfLimpaStr(_cNomCidEnt,.f. ,.t., "C5_ZCIDENT") ,;
			sfLimpaStr(_cNomEstEnt,.f. ,.t., "C5_ZUFENTR") })

			// valida dados do lote
		ElseIf (Len(_vLinha)>0).and.(AllTrim(_vLinha[1])=="3").and.(_lLotAtivo)

			// valida estrutura das informacoes do TXT
			If (Len(_vLinha) < 3)
				Aviso("TFATA001 -> sfVldArqTxt","Sequencia: "+_cSeqPedCli+"-->Faltam informacoes no registro 3.",{"Fechar"})
				_lLoteOk := .f.
				Return(.f.)
			EndIf

			// valida codigo do produto
			If (Empty(_vLinha[2]))
				Aviso("TFATA001 -> sfVldArqTxt","Sequencia: "+_cSeqPedCli+"-->Codigo do produto do cliente não informado no registro 3.",{"Fechar"})
				_lLoteOk := .f.
				Return(.f.)
			EndIf

			// valida o lote do produto
			if empty(_vLinha[3])
				Aviso("TFATA001 -> sfVldArqTxt","Sequencia: "+_cSeqPedCli+"-->Lote do produto "+alltrim(_vLinha[2])+" não informado no registro 3.",{"Fechar"})
				_lLoteOk := .f.
				Return(.f.)
			endif

			// monta o codigo do produto (sigla + codigo do XML)
			_cCodPrdLot := AllTrim(_cSiglaCli)
			_cCodPrdLot += sfLimpaStr(_vLinha[2])

			// numero do lote
			_cNrLote    := sfLimpaStr(_vLinha[3])

			// id do palete
			_cIdPalete  := sfLimpaStr(_vLinha[4])

			// quantidade solicitada
			_nQtdSolLot := StoV(_vLinha[5])

			// atualiza variavel dos lotes selecionados
			aAdd(_aLotesSol,{;
			_cSeqPedCli     ,; // 1-seq pedido do cliente
			_cItemArq       ,; // 2-seq item no arquivo
			_cCodPrdLot     ,; // 3-codigo do produto
			UPPER(_cNrLote) ,; // 4-numero do lote
			_cIdPalete      ,; // 5-ID do palete
			_nQtdSolLot     ,; // 6-Quantidade
			_nQtdSolLot     }) // 7-Saldo
		EndIf

		// proxima linha
		FT_FSkip()
	EndDo

	// fecha o arquivo
	ft_FUse()

Return(.t.)

// ** funcao que converve as string em valores
Static Function StoV(mvString)
	// remove os pontos (.)
	mvString := Replace(mvString,".","")
	// substitui os separadores decimais == virgulas (,) por ponto (.)
	mvString := Replace(mvString,",",".")
	// converte de string para valor
Return(Val(mvString))

// ** funcao que valida os dados da transportadora
Static Function sfVldTransp(mvCnpj, mvPlaca, mvDadTransp )
	// posicao inicial das tabelas
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"SA4","DA3"})

	// dados da transportadora
	local _cTrNome  := ""
	local _cTrEnd   := ""
	local _cTrMun   := ""
	local _cTrEst   := ""
	local _cCodIBGE := ""

	// variaveis para rotina automatica
	Local _aDadosSA4 := {}
	Private lMsErroAuto := .f.

	// valores padroes
	Default mvCnpj      := ""
	Default mvPlaca     := ""
	Default mvDadTransp := {}

	// se tem dados da transportadora, faz um teste se existe, se for necessario, ja cadastra
	If (Len(mvDadTransp) > 0).and.(Type(_cBaseXML + "_INFNFE:_TRANSP:_TRANSPORTA") == "O")

		// atualiza o CNPJ
		mvCnpj := mvDadTransp[1]:_TRANSPORTA:_CNPJ:TEXT

		// dados completos
		_cTrNome := mvDadTransp[1]:_TRANSPORTA:_XNOME:TEXT
		_cTrEnd  := mvDadTransp[1]:_TRANSPORTA:_XENDER:TEXT
		_cTrMun  := mvDadTransp[1]:_TRANSPORTA:_XMUN:TEXT
		_cTrEst  := mvDadTransp[1]:_TRANSPORTA:_UF:TEXT
		_cTrEst  := mvDadTransp[1]:_TRANSPORTA:_UF:TEXT

	EndIf

	// padroniza CNPJ
	mvCnpj := AllTrim(mvCnpj)
	// remove pontos
	mvCnpj := StrTran(mvCnpj,".","")
	// remove barras
	mvCnpj := StrTran(mvCnpj,"/","")
	// remove hifen
	mvCnpj := StrTran(mvCnpj,"-","")

	// padroniza placa
	mvPlaca := AllTrim(Upper(mvPlaca))
	// remove hifen
	mvPlaca := StrTran(mvPlaca,"-","")

	// se o CNPJ estiver em branco
	If (Empty(mvCnpj))
		// restaura areas iniciais
		RestOrd(_aAreaIni,.t.)
		RestArea(_aAreaAtu)
		// retorno
		Return(.t.)
	Else
		// pesquisa a transportadora
		dbSelectArea("SA4")
		SA4->(dbSetOrder(3)) // 3-A4_FILIAL, A4_CGC
		If ( ! SA4->(dbSeek( xFilial("SA4") + mvCnpj )))

			// verifica se tem os dados completos, realiza o cadastro
			If ( ! Empty(_cTrNome) )

				// Verifica código do IBGE (municipio)
				_cCodIBGE := sfRetMunic(_cTrEst, _cTrMun)

				// para dados da rotina automatica
				aAdd(_aDadosSA4, {"A4_NOME"   , _cTrNome , nil})
				aAdd(_aDadosSA4, {"A4_NREDUZ" , _cTrNome , nil})
				aAdd(_aDadosSA4, {"A4_END"    , _cTrEnd  , nil})
				aAdd(_aDadosSA4, {"A4_BAIRRO" , "CENTRO" , nil})
				aAdd(_aDadosSA4, {"A4_EST"    , _cTrEst  , nil})
				aAdd(_aDadosSA4, {"A4_COD_MUN", _cCodIBGE, nil})
				aAdd(_aDadosSA4, {"A4_MUN"    , _cTrMun  , nil})
				aAdd(_aDadosSA4, {"A4_CGC"    , mvCnpj   , nil})
				aAdd(_aDadosSA4, {"A4_CODPAIS", "01058"  , nil})

				// padronizao ordem dos campos
				_aDadosSA4 := FWVetByDic(_aDadosSA4, "SA4", .F.)

				// rotina automatica de cadastro de transportadoras
				MSExecAuto({|x,y| Mata050(x,y)}, _aDadosSA4, 3) // 3-Incluir

				// em caso de erro, apresenta mensagem
				If (lMsErroAuto)
					// mensagem
					Aviso("TFATA001 -> sfVldTransp","Erro ao tentar cadastrar a transportadora com CNPJ "+Transf(mvCnpj,PesqPict("SA4","A4_CGC"))+". Favor verifique os detalhes na próxima mensagem.",{"Ok"})
					// mostra erro da rotina automatica
					MostraErro()
					// restaura areas iniciais
					RestOrd(_aAreaIni,.t.)
					RestArea(_aAreaAtu)
					// retorno
					Return(.f.)
				EndIf

				// armazena informacoes da transportadora
				_cTranspPed	:= SA4->A4_COD

			Else
				// mensagem
				Aviso("TFATA001 -> sfVldTransp","Transportadora com CNPJ "+Transf(mvCnpj,PesqPict("SA4","A4_CGC"))+" não cadastrada.",{"Fechar"})
				// restaura areas iniciais
				RestOrd(_aAreaIni,.t.)
				RestArea(_aAreaAtu)
				// retorno
				Return(.f.)
			EndIf
		Endif

		// armazena informacoes da transportadora
		_cTranspPed	:= SA4->A4_COD

	EndIf

	// se a PLACA estiver em branco
	If (Empty(mvPlaca))
		// restaura areas iniciais
		RestOrd(_aAreaIni,.t.)
		RestArea(_aAreaAtu)
		// retorno
		Return(.t.)
	Else
		// pesquisa a placa
		dbSelectArea("DA3")
		DA3->(dbSetOrder(3)) // 3-DA3_FILIAL, DA3_PLACA
		If ( ! DA3->(dbSeek( xFilial("DA3") + mvPlaca )))
			Aviso("TFATA001 -> sfVldTransp","Veículo com Placa "+Transf(mvPlaca,PesqPict("DA3","DA3_PLACA"))+" não cadastrado.",{"Fechar"})
			// restaura areas iniciais
			RestOrd(_aAreaIni,.t.)
			RestArea(_aAreaAtu)
			// retorno
			Return(.f.)
		Endif
		// armazena informacoes da transportadora
		_cPlacaPed := DA3->DA3_COD
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni,.t.)
	RestArea(_aAreaAtu)

Return(.t.)

// ** funcao que padroniza arquivo CSV para TXT
Static Function sfPadArqTXT(mvArquivo, mvSigla)
	// novo arquivo
	local _cNewArq := ""
	// handle do novo arquivo
	local _nHdl
	// linha temporaria
	local _cTmpLinha
	// numero do pedido
	local _cNumPedCli := CriaVar("C5_ZPEDCLI", .f.)
	local _cTmpPedCli := CriaVar("C5_ZPEDCLI", .f.)
	// agrupadora de carga/percurso
	local _cAgrupador := ""
	// produtos
	local _lProdOk := .f.

	// controle da linha corrente
	local _nLinAtu := 0

	// mensagens retornadas da funcao XmlParserFile
	local _cError := ""
	local _cWarning := ""

	// itens do percurso
	local _aItePerc  := {}
	local _nItePerc  := 0

	// codigo do produto TECADI
	local _cCodProd := ""

	// codigo produto solicitado
	local _cProdSolic := ""

	// quantidade solicitada
	local _nQtdSolic := 0

	// lote solicitado
	local _cLoteSolic := ""

	// saldo do produto
	local _nSaldoSb2 := 0

	// detalhes do saldo do lote
	local _aSldLote := {}
	local _nSldLote := 0

	// formas de pesquisa
	local _nForma

	// seek
	local _cSeekSB2

	// variaveis temporarias
	local _nX

	// unidade de medida
	local _cUnidMed := ""

	// variavel de log
	local _cLog := ""
	// variavel de retorno
	local _lRet := .t.

	// quantidade de volumes
	local _nQtdVolumes := 0

	// quantidade de paletes
	local _nQtdPaletes := 0

	// CNPJ do Cliente de Entrega
	local _cCnpjEnt := ""
	//Nome do cliente de entrega
	local _cNomCliEnt := ""
	// endereco de entrega
	local _cEnderEnt := ""
	//Nome da Cidade De entrega
	local _cNomCidEnt := ""
	//Estado de entrega
	local _cNomEstEnt := ""

	// vetor temporario para armazenar informacoes do arquivo e ordenar antes de gerar o novo TXT
	local _aTmpDados := {}
	local _nTmpDados

	// verifica dados do endereco de entrega
	local _nPosEnt

	// controle sequencia das linhas do arquivo
	local _cSeqTxt := "000000"

	// XML de Origem
	private _oXmlOrig

	// define nova extensao para o arquivo
	If (mvSigla == "SUMI")
		_cNewArq := AllTrim(StrTran(mvArquivo,".csv",".txt"))
	ElseIf (mvSigla == "PTBL")
		_cNewArq := AllTrim(StrTran(mvArquivo,".xml",".txt"))
	EndIf

	// Regra para SUMITOMO
	If (mvSigla == "SUMI")

		// handle do novo arquivo
		_nHdl := fCreate(_cNewArq)

		// abre o arquivo TXT
		FT_FUse(mvArquivo)
		FT_FGoTop()

		// varre todas as linhas do arquivo
		While ( ! FT_FEof() )

			// controle de linha atual
			_nLinAtu ++

			// extrai e separa os dados da linha corrente
			_vLinha := Separa(FT_FReadln(),";")

			// numero do pedido do cliente
			If (_nLinAtu==1).and.(AllTrim(Upper(_vLinha[1]))=="PEDIDO")
				_cNumPedCli := AllTrim(_vLinha[2])

				// cria a linha do cabecalho
				_cTmpLinha := "0^"
				_cTmpLinha += If(cFilAnt=="103","13816470000412^","13816470000170^")
				_cTmpLinha += _cNumPedCli
				_cTmpLinha += CRLF
				// grava o conteudo no arquivo
				fWrite(_nHdl,_cTmpLinha,Len(_cTmpLinha))
				// proxima linha
				FT_FSkip()
				Loop
			EndIf

			// linha em branco
			If (Empty(_vLinha[1]))
				If (_lProdOk)
					Exit
				Else
					// proxima linha
					FT_FSkip()
					Loop
				EndIf
			EndIf

			// produtos
			If (_nLinAtu >= 7)

				// cria a linha dos produtos
				_cTmpLinha := "1^"
				_cTmpLinha += AllTrim(_vLinha[2])+"^"
				_cTmpLinha += AllTrim(_vLinha[3])+"^"
				_cTmpLinha += AllTrim(_vLinha[4])
				_cTmpLinha += CRLF

				// grava o conteudo no arquivo
				fWrite(_nHdl,_cTmpLinha,Len(_cTmpLinha))

				// define flag de produtos importados
				_lProdOk := .t.

			EndIf

			// proxima linha
			FT_FSkip()
		EndDo

		// fecha o arquivo
		ft_FUse()

		// fecha o novo arquivo
		fClose(_nHdl)

		// Regra para PORTOBELLO
	ElseIf (mvSigla == "PTBL")

		// copia o arquivo para o servidor (necessario para XmlParserFile)
		sfCopiaArq(@mvArquivo)

		// abertura do arquivo XML e estrutura do objeto
		_oXmlOrig := XmlParserFile(mvArquivo, "_", @_cError, @_cWarning )

		// verifica erros no XML
		If (ValType(_oXmlOrig) != "O")
			Aviso("TFATA001 -> sfPadArqTXT","Falha ao gerar Objeto XML : "+_cError+" / "+_cWarning,{"Fechar"})
			_oXmlOrig := Nil
			Return("")
		Endif

		// verifica erros na estrutura do XML
		If (Type("_OXMLORIG:_WMSX12011PB:_LIST_G_LIST_CONF") != "O")
			Aviso("TFATA001 -> sfPadArqTXT","Falha ao gerar Objeto XML : "+_cError+" / "+_cWarning,{"Fechar"})
			_oXmlOrig := Nil
			Return("")

		EndIf

		// agrupadora
		_cAgrupador := _oXmlOrig:_WMSX12011PB:_P_PERCURSO:TEXT

		// quantidade de itens no percurso
		_aItePerc := _OXMLORIG:_WMSX12011PB:_LIST_G_LIST_CONF:_G_LIST_CONF

		// se nao conseguiu carregar os itens corretamente
		If ( ValType(_aItePerc) <> 'A' )
			_aItePerc := {}
			aAdd(_aItePerc,_OXMLORIG:_WMSX12011PB:_LIST_G_LIST_CONF:_G_LIST_CONF)
		Endif

		// cria a linha do cabecalho
		_cTmpLinha := "0"               // identificador
		_cTmpLinha += "^83475913000272" // cnpj do cliente
		_cTmpLinha += "^"+_cAgrupador   // agrupadora/percurso

		// adiciona dados
		aAdd(_aTmpDados,{"0", _cAgrupador, _cNumPedCli, "A", _cSeqTxt, _cTmpLinha})
		// incrementa sequencial
		_cSeqTxt := Soma1(_cSeqTxt)

		// varre todos os itens do percurso
		For _nItePerc := 1 to Len(_aItePerc)

			// quantidade solicitada
			_nQtdSolic := Val(_aItePerc[_nItePerc]:_QDE_SOLIC:TEXT)

			// lote solicitado
			_cLoteSolic := AllTrim(_aItePerc[_nItePerc]:_COD_TONAL_CALIBRE:TEXT)
			// padroniza campo
			_cLoteSolic := UPPER(PadR(_cLoteSolic,TamSx3("B8_LOTECTL")[1]))

			// unidade de medida
			_cUnidMed := AllTrim(Upper(_aItePerc[_nItePerc]:_UNIDADE_MEDIDA:TEXT))

			// quantidade de volumes
			_nQtdVolumes := Val(_aItePerc[_nItePerc]:_QT_CAIXA:TEXT)

			// quantidade de paletes
			_nQtdPaletes := Val(_aItePerc[_nItePerc]:_QT_PALLET:TEXT)

			// pedido do cliente
			_cNumPedCli := AllTrim(Upper(_aItePerc[_nItePerc]:_NR_PEDIDO:TEXT))

			// controle de quebra de pedido
			If (AllTrim(_cTmpPedCli) != AllTrim(_cNumPedCli))

				// controle para inclusao dos dados de entrega antes do proximo pedido
				If (_lRet).and.( ! Empty(_cTmpPedCli) ).and.( ! Empty(_cEnderEnt) )

					// cria a linha com os dados de entrega
					_cTmpLinha := "2"               // identificador
					_cTmpLinha += "^" + _cCnpjEnt   // cnpj do cliente
					_cTmpLinha += "^" + _cNomCliEnt // nome do cliente
					_cTmpLinha += "^" + _cEnderEnt  // endereco de entrega
					_cTmpLinha += "^" + _cNomCidEnt // cidade de entrega
					_cTmpLinha += "^" + _cNomEstEnt // UF de entrega

					// verifica se ja tem o endereco de entrega do pedido
					_nPosEnt := aScan(_aTmpDados,{|x| (x[1] == "2") .and. (AllTrim(x[2]) == (_cAgrupador)) .and. (AllTrim(x[3]) == (_cTmpPedCli)) })

					// adiciona dados
					If (_nPosEnt == 0)
						// adiciona dados no vetor
						aAdd(_aTmpDados,{"2", _cAgrupador, _cTmpPedCli, "Z", _cSeqTxt, _cTmpLinha})
						// incrementa sequencial
						_cSeqTxt := Soma1(_cSeqTxt)
					EndIf

				EndIf

				// CNPJ do Cliente de Entrega
				_cCnpjEnt := AllTrim(Upper(_aItePerc[_nItePerc]:_CPF_CNPJ_CLI_ENT:TEXT))
				_cCnpjEnt := StrTran(_cCnpjEnt,".","")
				_cCnpjEnt := StrTran(_cCnpjEnt,"/","")
				_cCnpjEnt := StrTran(_cCnpjEnt,"-","")
				// Nome do cliente de entrega
				_cNomCliEnt := AllTrim(Upper(_aItePerc[_nItePerc]:_CLIENTE_ENT:TEXT))
				// endereco de entrega
				_cEnderEnt := AllTrim(Upper(_aItePerc[_nItePerc]:_ENDERECO_ENT:TEXT))
				// Nome da Cidade De entrega
				_cNomCidEnt := AllTrim(Upper(_aItePerc[_nItePerc]:_CIDADE_ENT:TEXT))
				// Estado de entrega
				_cNomEstEnt := AllTrim(Upper(_aItePerc[_nItePerc]:_ESTADO_ENT:TEXT))

				// controle de quebra de pedido
				_cTmpPedCli := _cNumPedCli

			EndIf

			// busca as informacoes do produto de duas forma
			// 1-Cod Prod + Lote
			// 2-Cod Prod
			For _nForma := 1 to 2
				// codigo do produto
				_cProdSolic := AllTrim(_aItePerc[_nItePerc]:_COD_PRODUTO:TEXT)

				// incrementa o lote
				If (_nForma == 1)
					_cProdSolic += " " + UPPER(AllTrim(_aItePerc[_nItePerc]:_COD_TONAL_CALIBRE:TEXT))
				EndIf

				// monta o codigo do produto TECADI (sigla + codigo do XML)
				_cCodProd := AllTrim(mvSigla)
				_cCodProd += _cProdSolic

				// padroniza codigo
				_cCodProd := PadR(_cCodProd,Len(SB1->B1_COD))

				// procura se esta no cadastro
				dbSelectArea("SB1")
				SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
				If ( ! SB1->(dbSeek( xFilial("SB1")+_cCodProd )))
					Loop
				EndIf

				// verifica saldo do produto por armazem
				dbSelectArea("SB2")
				SB2->(dbsetorder(1)) // 1-B2_FILIAL, B2_COD, B2_LOCAL
				SB2->(dbseek( _cSeekSB2 := xFilial("SB2") + SB1->B1_COD ))
				// varre todos os armazens do produto
				While SB2->( ! Eof() ).and.(SB2->(B2_FILIAL+B2_COD) == _cSeekSB2)

					// verifica saldo disponivel no estoque.(SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QACLASS - SB2->B2_QEMP)
					_nSaldoSb2 := SaldoSb2()

					// se nao tem saldo Disponivel, faz outro teste
					If (_nSaldoSb2 == 0)
						// proximo registro de saldo
						SB2->(dbSkip())
						// retorna o while
						Loop
					Else
						Exit
					EndIf

					// proximo registro de saldo
					SB2->(dbSkip())
				EndDo

				// caso saldo não foi encontrado na SB2, retorna o FOR do nForma
				If( _nSaldoSb2 == 0 )
					Loop
				EndIf

				// verifica o saldo por lote
				_aSldLote := SldPorLote(SB1->B1_COD, SB2->B2_LOCAL, _nQtdSolic, 0, _cLoteSolic)

				// zera variavel
				_nSldLote := 0

				// soma total do lote
				aEval(_aSldLote, { |lot| _nSldLote++ } )

				// valida se tem saldo
				If (_nSldLote == 0)
					Loop
				EndIf

				// valida unidade de medida
				If (SB1->B1_UM <> _cUnidMed)
					_cLog += "Inconsistência: Unidade de medida solicitada é diferente do cadastro. " + CRLF
					_cLog += " - Produto: " + AllTrim(SB1->B1_COD) + CRLF
					_cLog += " Solicitada: " + _cUnidMed + CRLF
					_cLog += " Cadastrada: " + SB1->B1_UM + CRLF
					_cLog += CRLF + "Solução: Importe novo arquivo com a unidade de medida correta. " + CRLF
					_cLog += CRLF

					// atualiza variável
					_lRet := .f.
				EndIf

				// se encontrou o saldo necessário, sai rotina
				If ( _nSaldoSb2 > 0 ) .and. ( _nSldLote > 0 )
					Exit
				EndIf

			Next _nForma

			// caso não tenha encontrado o saldo necessário
			If ( _lRet ) .and. ( ( _nSaldoSb2 <= 0 ) .Or. ( _nSldLote <= 0 ) )

				// retorna falso se não achou saldo
				_lRet := .f.
				// mensagem para o usuário
				_cLog += "Inconsistência: Não há saldo para o Produto / Lote: " + AllTrim(_cCodProd)  + " / " + AllTrim(_cLoteSolic) + "." + CRLF
				_cLog += "Solução: Verifique se há saldo em lote para o produto e lote solicitados pelo cliente." + CRLF
				_cLog += CRLF
			EndIf

			// só continua se deu tudo certo até aqui
			If ( _lRet )
				// cria a linha dos produtos
				_cTmpLinha := "1"
				_cTmpLinha += "^"+AllTrim(_cProdSolic)                                        // cod produto
				_cTmpLinha += "^"+AllTrim(_aItePerc[_nItePerc]:_DES_PRODUTO:TEXT)             // descricao do produto
				_cTmpLinha += "^"+AllTrim(Transform(_nQtdSolic, PesqPict("SD1", "D1_QUANT"))) // quantidade solicitada
				_cTmpLinha += "^"                                                             // nota fiscal de remessa
				_cTmpLinha += "^"                                                             // serie fiscal de remessa
				_cTmpLinha += "^"+AllTrim(_cNumPedCli)                                        // numero pedido cliente
				_cTmpLinha += "^"+AllTrim(Str(_nQtdVolumes))                                  // quantidade de volumes para o item
				_cTmpLinha += "^"+AllTrim(Str(_nQtdPaletes))                                  // quantidade de paletes para o item

				// adiciona dados
				aAdd(_aTmpDados,{"1", _cAgrupador, _cNumPedCli, "A", _cSeqTxt, _cTmpLinha})
				// incrementa sequencial
				_cSeqTxt := Soma1(_cSeqTxt)

				// cria a linha com o lote do produto
				_cTmpLinha := "3^"                                                        // identificador
				_cTmpLinha += AllTrim(_cProdSolic)+"^"                                    // cod produto
				_cTmpLinha += AllTrim(_cLoteSolic)+"^"                                    // lote
				_cTmpLinha += "^"                                                         // id do palete
				_cTmpLinha += AllTrim(Transform(_nQtdSolic, PesqPict("SD1", "D1_QUANT"))) // quantidade solicitada

				// adiciona dados
				aAdd(_aTmpDados,{"3", _cAgrupador, _cNumPedCli, "A", _cSeqTxt, _cTmpLinha})
				// incrementa sequencial
				_cSeqTxt := Soma1(_cSeqTxt)

			EndIf

		Next _nItePerc

		// controle para inclusao dos dados de entrega antes do proximo pedido
		If (_lRet).and.( ! Empty(_cTmpPedCli) ).and.( ! Empty(_cEnderEnt) )

			// cria a linha com os dados de entrega
			_cTmpLinha := "2"               // identificador
			_cTmpLinha += "^" + _cCnpjEnt   // cnpj do cliente
			_cTmpLinha += "^" + _cNomCliEnt // nome do cliente
			_cTmpLinha += "^" + _cEnderEnt  // endereco de entrega
			_cTmpLinha += "^" + _cNomCidEnt // cidade de entrega
			_cTmpLinha += "^" + _cNomEstEnt // UF de entrega

			// verifica se ja tem o endereco de entrega do pedido
			_nPosEnt := aScan(_aTmpDados,{|x| (x[1] == "2") .and. (AllTrim(x[2]) == (_cAgrupador)) .and. (AllTrim(x[3]) == (_cTmpPedCli)) })

			// adiciona dados
			If (_nPosEnt == 0)
				// adiciona dados no vetor
				aAdd(_aTmpDados,{"2", _cAgrupador, _cTmpPedCli, "Z", _cSeqTxt, _cTmpLinha})
				// incrementa sequencial
				_cSeqTxt := Soma1(_cSeqTxt)
			EndIf

		EndIf

		// se tem algum log, não permite continuar
		If ( ! _lRet ) .and. ( ! Empty(_cLog) )
			// se encontrou algum problema, avisa o usuário
			HS_MsgInf("LOG de Importação:"+CRLF+_cLog,"Log de Importação","Inconsistência" )
			// zera nome do arquivo
			_cNewArq := ""
		EndIf

		// se dados ok, gera o arquivo
		If ( _lRet ) .and. (Len(_aTmpDados) != 0)

			// handle do novo arquivo
			_nHdl := fCreate(_cNewArq)

			// reordena os itens por Agrupadora + Pedido + Tipo + Sequencial
			_aTmpDados := aSort(_aTmpDados,,,{ |x, y| (x[2] + x[3] + x[4] + x[5]) < (y[2] + y[3] + y[4] + y[5]) })

			// varre todos os registros do vetor para gerar o arquivo TXT
			For _nTmpDados := 1 to Len(_aTmpDados)

				// extrai linha com detalhes
				_cTmpLinha := _aTmpDados[_nTmpDados][6] + CRLF

				// grava o conteudo no arquivo
				fWrite(_nHdl,_cTmpLinha,Len(_cTmpLinha))

			Next _nTmpDados

			// fecha o novo arquivo
			fClose(_nHdl)

		EndIf

		// define flag de produtos importados
		_lProdOk := _lRet

	EndIf

Return(_cNewArq)

// ** funcao que verifica se existe mais de um codigo para o mesmo produto
Static Function sfVldNewCod(mvCodProd)
	// variavel de retorno
	local _cRetCodProd := Space(Len(mvCodProd))
	// query
	local _cQuery

	// monta a query para buscar o codigo de produto relacionado
	_cQuery := " SELECT A7_PRODUTO "
	_cQuery += " FROM "+RetSqlTab("SA7")
	_cQuery += " WHERE "+RetSqlCond("SA7")
	_cQuery += " AND A7_CLIENTE = '"+_cCodCli+"' AND A7_LOJA = '"+_cLojaCli+"' "
	_cQuery += " AND A7_CODCLI = '"+mvCodProd+"' "
	// executa a query
	_cRetCodProd := U_FtQuery(_cQuery)

Return(_cRetCodProd)

// ** funcao que define o codigo do municipio
Static Function sfRetMunic(mvEst, mvMunic)
	// armazena area inicial
	Local _aAreaCC2 := CC2->(GetArea())
	// codigo do retorno
	Local _cCodRet := CriaVar("CC2_CODMUN",.f.)

	// padroniza a descricao do municipio
	mvMunic := NoAcento(mvMunic)
	mvMunic := Upper(mvMunic)
	mvMunic := AllTrim(mvMunic)

	// se for estrangeiro
	If (mvEst == "EX")
		mvMunic := "ESTRANGEIRO"
	EndIf

	// cadastro de municipio
	dbSelectArea("CC2")
	CC2->(dbSetOrder(2)) //1-CC2_FILIAL, CC2_MUN
	If CC2->(dbSeek( xFilial("CC2")+mvMunic ))
		While ( ! CC2->(Eof()) ) .and. (AllTrim(CC2->CC2_MUN) == mvMunic)
			// se for de outro estado
			If (CC2->CC2_EST <> mvEst)
				CC2->(dbskip())
				Loop
			EndIf
			// retorna codigo do municipio
			_cCodRet := CC2->CC2_CODMUN
			// sai do loop
			Exit
		EndDo
	EndIf

	// restaura area inicial
	RestArea(_aAreaCC2)

Return( _cCodRet )