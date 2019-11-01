#include "totvs.ch"
#include "TopConn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para execucao do servico de enderecamento de     !
!                  ! produtos                                                !
!                  ! - Chamada a partir da rotina TWMSA009/TACDA002          !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 07/2012 !
+------------------+--------------------------------------------------------*/

User Function TWMSA011(mvQryUsr)

	// controle da continuacao do processo
	local _lContProc := .T.
	// variaveis temporarias para controle de endereco de origem e destino de paletes fracionados na expedicao
	local _cTmpEndOri := CriaVar("BE_LOCALIZ",.F.)
	local _cTmpEndDes := CriaVar("BE_LOCALIZ",.F.)
	// variavel novo pallet
	local _cNovoPltFra := ""
	// array de informações do pallet
	local _aItemRet := {}

	// data e hora das movimentações de fracionamento
	local _dDtIni
	local _dDtFim

	// produtos da feira
	private _aPrdFeira := {}
	// tamanho do ID
	private _nTamIdEtq := TamSx3("Z11_CODETI")[1]
	// mascara da etiqueta
	private _cMskEtiq := PesqPict("Z11","Z11_CODETI")
	// ID palete
	private _cIdPalete := Space(_nTamIdEtq)
	// ID etiqueta lida
	private _cIdEtiqLida  := Space(_nTamIdEtq) // refere-se a etiqueta lida, podendo ser de produto, agrupadora ou pallet
	// codigo do unitizador
	private _cCodUnit  := CriaVar("Z11_UNITIZ",.F.)
	// ID endereco
	private _cIdEndere := Space(_nTamIdEtq)
	// ID de etiqueta (indefinida)
	private _cIdEtiqueta := Space(_nTamIdEtq)
	// armazem/local atual
	private _cArmzAtual := CriaVar("BE_LOCAL",.F.)
	// variavel de controle de armazem de destino
	private _cArmzDesti := CriaVar("BE_LOCAL",.F.)
	// tamanho do campo endereco
	private _nTamEndere := TamSx3("BE_LOCALIZ")[1]
	// salva o endereco atual
	private _cEndAtual := CriaVar("BE_LOCALIZ",.F.)
	// endereco de origem
	private _cEndOrige := CriaVar("BE_LOCALIZ",.F.)
	// endereco de destino
	private _cEndDesti := CriaVar("BE_LOCALIZ",.F.)
	// endereco de transacao entre movimentos (Pick And Drop)
	private _cEndPicDro := CriaVar("BE_LOCALIZ",.F.)
	// enderecos de servico
	private _aEndServ := {}
	private _cEndServ := ""
	// numero das OS disponiveis, em formato SQL
	private _cQryNumOS := ""
	private _cQryChrIn := ""
	private _cChOrdSrv := ""
	// numero e sequencia da OS
	private _cNumOrdSrv := ""
	private _cSeqOrdSrv := ""
	// tipo da operacao da OS (E-Ent/S-Sai/I-Int)
	private _cTipoOper := ""
	// status da OS
	private _cCodStatus := ""
	// armazena o RECNO do mapa (Z08)
	private _nRecnoZ08 := 0
	// controle de ha paletes disponiveis
	private _lPltDisponivel := .F.
	// codigo do produto no palete
	private _cCdProdPlt := CriaVar("B1_COD",.F.)
	// controle se deve encerrar OS
	private _lEncOrdSrv := .F.
	// ruas disponiveis para filtro
	private _aRuaDisp := {}
	private _cFiltraRua := "TODAS"
	// controle do folder ativo
	private _nFldAtivo := 0
	// OS de recebimento
	private _lOSRec := .F.
	// OS de expedicao
	private _lOSExp := .F.
	// OS interna
	private _lOSInt := .F.
	// feirinha ativa por cliente
	private _lFeiraAtiva := .F.
	// controle por volume
	private _lCtrVolume := .F.
	// pallet genérico para procedimento de feirinha
	private _cIdPltGen := CriaVar("Z11_CODETI",.F.)
	// variaveis dos dados do cliente
	private _cCodCliMov := ""
	private _cLjCliMov  := ""
	// endereço de destino
	private _cEndFimMov := ""
	// valida primeiro nível
	private _lArmPrimNiv := .F.
	// nova etiqueta de pallet
	private _cIdNewPalete := ""
	// variavel de controle para acionamento da feirinha
	private _lAcionaFeira := .F.
	// variável que receberá o conteúdo da query para comparação
	private _aQryZ16 := {}
	// variavel que receberá a quantidade na Z08
	private _aQryZ08 := {}
	// variavel do produto durante o fracionamento
	private _cProdFra := ""
	// tipo de fracionamento
	private _cTipFra := ""
	// variavel para fracionamento
	private _cFraPal 	:= "N"
	// private unitario - forma simples de fazer a contage
	private _lUnit := .F.
	// data e hora inicial para preenchimento
	private _cDtIni := ""
	private _cHrIni := ""
	// array que receberá os produtos fracionados onde a caixa original foi levada e uma nova caixa foi deixada na posição
	private _aSldPrd := {}
	// recno da Z17 para ajuste das movimentações
	private _nRecnoZ17 := 0

	// id palete automatico para feirinha
	private _cPltAutFra := PadR("EXP_" + _cCodOper, _nTamIdEtq)

	// codigo do unitizador padrao
	private _cUnitPdr := SuperGetMV('TC_PLTPADR',.F.,"000001")

	// mascara para campos quantidade
	private _cMaskQuant := PesqPict("SD1","D1_QUANT")

	// lote do palete
	private _cLotePlt := CriaVar("B8_LOTECTL", .F.)

	// endereco transitorio para movimentacao entre armazens
	Private _cEndTransit := PadR("TRANSITORIO", TamSx3("BE_LOCALIZ")[1])

	// tipo de estoque do palete
	private _cMovTpEst := CriaVar("Z16_TPESTO", .F.)

	// quantidade maxima de registros na coleta da feirinha
	private _nQtdRegFei := SuperGetMV('TC_QREGFEI', .F., 10)

	// valida identificacao do produto
	private _cTpIdEtiq := ""

	// array de controle etiquetas Sumitomo
	private _aColsSum	:= {}

	// valida se ha equipamento informado
	If (Empty(_cCodEquip))
		// mensagem
		U_FtWmsMsg("É obrigatório informar um equipamento!","ATENCAO")
		// retorno
		Return(.F.)
	EndIf

	// relacao de RECNO bloqueados
	private _aRegLock := {}
	private _aLockZ08 := {}

	memowrit("C:\query\twmsa011_qry.txt",mvQryUsr)

	// define mensagem no monitor
	U_FtMsgMon()

	// verifica e corrige movimentacoes pendentes/erros
	sfMovPltPend()

	// retorna os produtos da feira
	_aPrdFeira := sfARetFeira()

	// valido se há informações da feirinha não finalizada
	If ( Len(_aPrdFeira) > 0 )
		U_FtWmsMsg("Há volumes em processo de coleta. Favor verificar!", "Atenção")
	EndIf

	// loop do processamento
	While (_lContProc)

		// reinicia as variaveis
		_aEndServ  := {}
		_cEndServ  := ""
		_cQryNumOS := ""
		_cQryChrIn := ""
		_cChOrdSrv := ""
		_aQryZ08   := {}
		_aRegLock := {}
		_aLockZ08 := {}

		// reinicia variaveis
		_cEndOrige   := Space(Len(_cEndOrige))
		_cEndDesti   := Space(Len(_cEndDesti))
		_cEndPicDro  := Space(Len(_cEndPicDro))
		_cArmzAtual  := Space(Len(_cArmzAtual))
		_cArmzDesti  := Space(Len(_cArmzDesti))
		_cIdPalete   := Space(_nTamIdEtq)
		_cCodUnit    := Space(Len(_cCodUnit))
		_cIdEndere   := Space(_nTamIdEtq)
		_cIdEtiqueta := Space(_nTamIdEtq)
		_nRecnoZ08   := 0
		_cIdPltGen   := Space(_nTamIdEtq)
		// controle de ha paletes disponiveis
		_lPltDisponivel := .F.

		// codigo do produto no palete
		_cCdProdPlt := Space(Len(_cCdProdPlt))

		// lote
		_cLotePlt := Space(Len(_cLotePlt))

		// tipo de estoque
		_cMovTpEst := Space(Len(_cMovTpEst))

		// OS de Recebimento, Expedicao ou interna
		_lOSRec := .F.
		_lOSExp := .F.
		_lOSInt := .F.

		// variavel para fracionamento
		_cFraPal := "N"

		// controle se deve encerrar OS
		_lEncOrdSrv := .F.

		// ruas disponiveis para filtro
		_aRuaDisp := {"TODAS"}

		// atualiza e retorna os produtos/quantidade em coleta atual (feirinha)
		_aPrdFeira := sfARetFeira()

		// valido se há informações da feirinha não finalizada
		If ( Len(_aPrdFeira) > 0 )
			_cIdPltGen := _aPrdFeira[1][3] // se ainda existir feira pendente, continua com o mesmo número de Z08_PLTFEI
		EndIf

		// variavel de controle para acionamento da feirinha
		If ( Len(_aPrdFeira) == 0 )
			_lAcionaFeira := .F.
		EndIf

		// funcao padrao da TOTVS que libera todos os registros com LOCK do SofLock
		LibLock(_aRegLock)
		LibLock(_aLockZ08)
		// libera todos os registros
		MsUnLockAll()

		// inicio da solução criada para a feirinha
		If (_lContProc)
			// chama funcao para iniciar uma movimentacao de mercadoria
			_lContProc := sfInicMovim(mvQryUsr)
		EndIf

		// valida feirinha ativa somente para expedíção
		If (_lContProc) .And. (_lOSExp)
			// valido se a feirinha está ativa
			_lFeiraAtiva := U_FtWmsParam("WMS_FEIRINHA_ATIVA_POR_CLIENTE", "L", .F., .F., Nil, _cCodCliMov, _cLjCliMov, Nil, Nil)
		EndIf

		// mascara para campos quantidade
		If (_lContProc) .And. (_lOSExp)
			_cMaskQuant := U_FtWmsParam("WMS_MASCARA_CAMPO_QUANTIDADE", "C", PesqPict("SD1","D1_QUANT"), .F., "", _cCodCliMov, _cLjCliMov, Nil, Nil)
		EndIf

		// funcao para leitura do palete no endereco selecionado
		If (_lContProc) .And. ( Empty(_cIdPalete) )
			// chama funcao para leitura do palete
			_lContProc := sfPegaPalete()
		EndIf

		// para ordens de servico de expedicao, verifica se o mapa tem DOCA de destino definida
		If (_lContProc) .And. (_lOSExp) .And. ( ! Empty(_cIdPalete) ) .And. (Empty(_cEndDesti))

			// avisa usuario
			U_FtWmsMsg("Doca ainda não definida para OS. Obrigatório escolher na próxima tela ou processo será abortado.", "Atenção!" )

			// tenta bloqueio da OS para impedir que outro usuário na mesma OS defina a doca também
			if ( ! sfLockOS(Z08->Z08_NUMOS) )
				_lContProc := .F.     // não continua processo
				U_FtWmsMsg("Não foi possível bloquear a OS " + Z08->Z08_NUMOS + " para definição da doca. Outro usuário está operando nesta OS.", "Erro!" )

			Else             // conseguiu bloquear
				// funcao para definicao de DOCA de expedicao
				_lContProc := sfDefDocExp( _cCodCliMov, _cLjCliMov )
			EndIf

			// funcao padrao da TOTVS que libera todos os registros com LOCK do SofLock
			LibLock(_aLockZ08)

		EndIf

		// se já tem coisa na feirinha não deixa continuar, desde que esteja na rua
		If (_lContProc) .And. (Len(_aPrdFeira) > 0) .And. (_lFeiraAtiva) .And. (Len(Trim(Z08->Z08_ENDSRV)) == 2)
			// valida se o endereço de destino é o mesmo do que já está na feirinha atual
			If (Z08->Z08_ENDDES <> _aPrdFeira[1][2])
				U_FtWmsMsg("Pallet incompatível com a coleta atual. Finalize a coleta atual!")
				_lContProc := .F.
			EndIf
		EndIf

		// _cFraPal = S=SIM / N=NÃO / D=DEPOIS

		// validação para verificar se é necessário o fracionamento do palete para expedição e OS Interna
		If (_lContProc)
			// somente para OS de expedição
			If ( Empty(Z08->Z08_NEWPLT) ) .And. ( Empty(Z08->Z08_ENDRET) ) // quando não for OS de retrabalho

				If (_lOSExp) .Or. (_lOSInt)

					// valido se é pra fracionar o pallet
					_cFraPal := sfValFrac()

					// se deu erro ao verificar o fracionamento, informa ao usuário e não deixa prosseguir
					If (_cFraPal == Nil) .Or. ( Empty(_cFraPal) )
						// se deu erro na consulta, não deixa continuar
						U_FtWmsMsg("Erro ao validar o fracionamento do pallet.","ATENCAO")
						// controle de processamento
						_lContProc := .F.

					Else
						// se vai fracionar, atualiza o registro na Z17 o tipo de lançamento
						If (_cFraPal == "S")
							// posiciono no registro da Z17 para alterar o tipo de lançamento
							dbSelectArea("Z17")
							Z17->( dbGoTo(_nRecnoZ17) )
							Reclock("Z17")
							Z17->Z17_TIPLAN = "FR"
							Z17->( MsUnlock() )
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf

		// também quando não precisa fracionar mas pode fazer a feirinha
		If (_lContProc) .And. (_lOSExp) .And. (_cFraPal == "N") .And. (_lFeiraAtiva) .And. (_lCtrVolume)
			_lAcionaFeira := .T. // aciona a feirinha
			_cEndDesti    := ""  // zera endereço de destino para o usuário decidir onde vai deixar a mercadoria
		EndIf

		// quando nao controla volumes;
		// e para fracionamento de blocos;
		// e que nao tem endereco de transacao, nao aceita fracionar no endereco de destino
		If (_lContProc) .And. (_lOSExp) .And. (_cFraPal == "S") .And. ( ! _lCtrVolume ) .And. (Empty(_cEndPicDro)) .And. (sfRetTpEnd(_cEndDesti, _cArmzDesti) == "5")
			_cEndDesti := ""  // zera endereço de destino para o usuário decidir onde vai deixar a mercadoria
		EndIf

		// caso o pallet esteja em rua e ainda pendente de fracionar, e seja bipado pelo paleteiro, não pode levar para destino final (Doca/stage) para fracionar
		// então substitui endereço de destino para a própria RUA para continuar o movimento
		// (isto corrige o cenário da empilhadeira baixar e nao fracionar, deixa em rua, e paleteiro em movimento diferente, levava para doca para fracionar)
		If (_lContProc) .And. (_lOSExp) .And. (_cFraPal == "S") .And. ( ! _lCtrVolume ) .AND. (_cEndDesti == Z08->Z08_ENDDES)
			_cEndDesti := Z08->Z08_ENDSRV
		EndIf

		// valida o tipo da OS pra verificar se pode confirmar o destino
		If (_lContProc)
			// chama funcao para validar/confirmar o endereco de destino
			_lContProc := sfConfDest( .F. , (_cFraPal $ "S|D") )
		EndIf

		// verifica se endereço destino está em branco
		If (_lContProc) .And. (Empty(_cEndDesti))
			// mensagem
			U_FtWmsMsg('ERRO: TWMSA011 - Endereço de destino em branco.','ATENCAO')
			// controle de processamento
			_lContProc := .F.
		EndIf

		// se tudo deu certo, chama funcao para enderecamento final
		If (_lContProc)
			// chama funcao para enderecamento final
			If ( ! sfGrvEndDest(_cTipoOper, .F., .T.) )
				// mensagem
				U_FtWmsMsg('Erro ao realizar o Endereçamento. Favor repetir a operação.','ATENCAO')
				// controle de processamento
				_lContProc := .F.
			EndIf
		EndIf

		// incluido 23/05
		If (_lContProc) .And. (_cFraPal == "S") .And. ( Empty(Z08->Z08_NEWPLT) ) .And. (_lCtrVolume)
			If ( ! sfFraPlt(_cTipFra, _aQryZ08))
				_lAcionaFeira := .F.
			Else
				// agora não precisa mais fracionar
				_cFraPal      := "N"
				_lAcionaFeira := .T. // aciona a feirinha
			EndIf
		EndIf

		// Feira Ativa  = Parametro Ativo
		// Aciona Feira = Rotina Ativada

		// somente se a feirinha estiver ativa e ativada é que vai realizar a inclusão na feirinha
		If (_lContProc) .And. (_lCtrVolume) .And. (_lOSExp) .And. ((_lFeiraAtiva) .And. (_lAcionaFeira)) .And. (_cFraPal == "N")
			// se o id estiver em branco eu gravo
			If ( Empty(_cIdPltGen) )
				_cIdPltGen := U_FtGrvEtq("03",{_cUnitPdr,""})
			EndIf

			// inclui os dados na tabela
			dbSelectArea("Z08")
			RecLock("Z08",.F.)
			Z08->Z08_PLTFEI := _cIdPltGen
			MsUnlock()

		EndIf

		/// Verifica se o pallet precisa ser fracionado ou não - alterado 17/02/14 - David
		If (_lContProc) .And. ( (_lOSExp) .Or. (_lOSInt) ) .And. (_cFraPal == "S") .And. ( ! _lCtrVolume )

			// novo palete gerado
			_cNovoPltFra := Space(_nTamIdEtq)

			// define os itens a serem retirados do palete
			_aItemRet := {{ Z08->Z08_QUANT, Z08->Z08_PRODUT, Z08->Z08_NUMSEQ, Z08->Z08_TPESTO, Z08->Z08_LOTCTL, Z08->Z08_VLDLOT }}

			// rotina para desmontar/fracionar um palete
			If ( ! sfDesmPalete(Z08->Z08_PALLET, _aItemRet, @_cNovoPltFra) )

				// atualizo variaveis
				_cTmpEndOri := _cEndOrige
				_cTmpEndDes := _cEndDesti
				_cEndOrige  := _cTmpEndDes
				_cEndDesti  := _cTmpEndOri

				// atualiza status
				dbSelectArea("Z08")
				RecLock("Z08")
				Z08->Z08_STATUS := "P" // P-Planejado / R-Realizado / M-Movimento / E-Erro
				Z08->Z08_ENDSRV := _cEndDesti
				Z08->Z08_ENDTRA := _cEndPicDro
				Z08->(MsUnLock())

				// data de inicio e fim do movimento
				_dDtIni := Date()
				_dDtFim := Time()

				// alerta para o usuário
				U_FtWmsMsg("Armazene o palete novamente em sua posição original.","Atenção")

				// tela para confirmar
				If ( sfConfDest( .F. , .F.) )

					// Gera registro de movimentacao de devolução do palete original
					dbSelectArea("Z17")
					RecLock("Z17",.T.)
					Z17->Z17_FILIAL := xFilial("Z17")
					Z17->Z17_ETQPLT := Z08->Z08_PALLET
					Z17->Z17_ENDORI := _cEndOrige
					Z17->Z17_ENDDES := _cEndDesti
					Z17->Z17_DTINI  := _dDtIni
					Z17->Z17_HRINI  := _dDtFim
					Z17->Z17_DTFIM  := Date()
					Z17->Z17_HRFIM  := Time()
					Z17->Z17_OPERAD := _cCodOper
					Z17->Z17_EQUIPA := _cCodEquip
					Z17->Z17_NUMOS  := Z08->Z08_NUMOS
					Z17->Z17_SEQOS  := Z08->Z08_SEQOS
					Z17->Z17_TEMPO  := 0
					Z17->Z17_STATUS := "R"  // R=Realizado / C=Cancelado / M=Em Movimento
					Z17->Z17_TIPLAN := "DF" // NM=Normal / ES=Estorno / AJ=Ajuste / DV=Devolução / FR=Fracionamento / DF=Dev. Fracion.
					Z17->Z17_ORILAN := "A"  // A=Automática / M=Manual
					Z17->Z17_LOCORI := Z08->Z08_LOCAL
					Z17->Z17_LOCDES := Z08->Z08_LOCDES
					Z17->Z17_LOCDES := "MV"
					Z17->(MsUnLock())

					// retornar o endereco do palete que foi fracionado
					U_FtEndPlt(_cIdPalete, _cEndOrige, _cEndDesti, _cArmzAtual)

					// funcao para enderecamento final
					If ( ! sfGrvEndDest(_cTipoOper, .T., .T.))
						U_FtWmsMsg('Erro ao realizar o Endereçamento. Favor repetir a operação.','ATENCAO')
						_lContProc := .F.
					EndIf

				EndIf
				// se deu tudo certo na armazenagem
			ElseIf (_lContProc)
				// atualizo variaveis
				_cTmpEndOri := _cEndOrige
				_cTmpEndDes := _cEndDesti
				_cEndOrige  := _cTmpEndDes
				_cEndDesti  := _cTmpEndOri

				// posiciona no registro da tabela
				dbSelectArea("Z08")
				Z08->( dbGoTo( _nRecnoZ08 ) )

				RecLock("Z08")
				// atualiza o ID e o ENDSRV do novo palete
				Z08->Z08_NEWPLT := _cNovoPltFra
				Z08->Z08_ENDSRV := _cEndOrige
				Z08->Z08_FRAPLT := "S" // alterado dia 19/03/2015 - DAVID
				Z08->(MsUnLock())

				// data de inicio e fim do movimento
				_dDtIni := Date()
				_dDtFim := Time()

				// alerta para o usuário
				U_FtWmsMsg("Armazene o palete novamente em sua posição original.","Atenção")

				// tela para confirmar
				If ( sfConfDest( .F. , .F.) )

					// Gera registro de movimentacao de devolução do palete original
					dbSelectArea("Z17")
					RecLock("Z17",.T.)
					Z17->Z17_FILIAL := xFilial("Z17")
					Z17->Z17_ETQPLT := Z08->Z08_PALLET
					Z17->Z17_ENDORI := _cEndOrige
					Z17->Z17_ENDDES := _cEndDesti
					Z17->Z17_DTINI  := _dDtIni
					Z17->Z17_HRINI  := _dDtFim
					Z17->Z17_DTFIM  := Date()
					Z17->Z17_HRFIM  := Time()
					Z17->Z17_OPERAD := _cCodOper
					Z17->Z17_EQUIPA := _cCodEquip
					Z17->Z17_NUMOS  := Z08->Z08_NUMOS
					Z17->Z17_SEQOS  := Z08->Z08_SEQOS
					Z17->Z17_TEMPO  := 0
					Z17->Z17_STATUS := "R"  // R=Realizado / C=Cancelado / M=Em Movimento
					Z17->Z17_TIPLAN := "DF" // NM=Normal / ES=Estorno / AJ=Ajuste / DV=Devolução / FR=Fracionamento / DF=Dev. Fracion.
					Z17->Z17_ORILAN := "A"  // A=Automática / M=Manual
					Z17->Z17_LOCORI := Z08->Z08_LOCAL
					Z17->Z17_LOCDES := Z08->Z08_LOCDES
					Z17->(MsUnLock())

					// retornar o endereco do palete que foi fracionado
					U_FtEndPlt(_cIdPalete,_cEndOrige,_cEndDesti, _cArmzAtual)

					// funcao para enderecamento final
					If ( ! sfGrvEndDest(_cTipoOper, .T., .T.))
						// mensagem
						U_FtWmsMsg('Erro ao realizar o Endereçamento. Favor repetir a operação.','ATENCAO')
						// controle de processamento
						_lContProc := .F.
					EndIf
				EndIf
			EndIf
		EndIf
	EndDo

Return( .T. )

// ** grava endereço final da feirinha
Static Function sfGrvFeira(mvEndDes, mvPltGen, mvNumos)
	local _cQryZ08    := "" //querys de consulta
	local _aRecFeiZ08 := {} // array de dados
	local _lRet       := .T.// controle de transação
	local _nZ08       := 0  // controle do for
	local _cLocAtual  := ""
	local _cLocDesti  := ""
	local _cSeekZ17   := ""
	local _cCliFeira  := Posicione("Z05", 1, xFilial("Z05") + mvNumOS, "Z05_CLIENT")

	// solicita confirmação
	If ( ! U_FtYesNoMsg("Deseja movimentar os produtos coletados para o endereço de destino?") )
		Return ( .F. )
	EndIf

	// controle de semáforo para descarregar apenas uma feirinha por vez (por cliente)
	If !LockByName("COLETA_" + cFilAnt + _cCliFeira,.T.,.T.,.T.)
		U_FtWmsMsg("Há uma descarga de coleta atual em andamento por outro usuário. Tente novamente dentro de alguns segundos.")
		Return ( .F. )
	EndIf

	// especifico para feirinha
	_cQryZ08 := " SELECT CASE WHEN Z08_NEWPLT != '' THEN Z08_NEWPLT ELSE Z08_PALLET END, "
	_cQryZ08 += " Z08_NUMOS, Z08_SEQOS, Z05_CLIENT, Z05_LOJA, Z08_ENDSRV, Z08_LOCAL, Z08_LOCDES   "
	_cQryZ08 += " FROM " + RetSqlTab("Z08") + " (nolock) "
	_cQryZ08 += " INNER JOIN " + RetSqlTab("Z05") + " (nolock)  ON Z05_NUMOS = Z08_NUMOS AND " + RetSqlCond("Z05")
	_cQryZ08 += " WHERE " + RetSqlCond("Z08")
	_cQryZ08 += " AND Z08_PLTFEI = '" + mvPltGen + "' "
	_cQryZ08 += " AND Z08_USUARI = '" + __cUserId + "' "
	_cQryZ08 += " AND Z08_NUMOS = '" + mvNumOs + "' "
	_cQryZ08 += " AND Z08_STATUS <> 'R' " // somente os registros que ainda não foram movimentados

	memowrit("C:\query\TWMSA011_query_feirinha.txt", _cQryZ08)

	// jogo os RECNO pro array pra finalizar o endereçamento
	_aRecFeiZ08 := U_SqlToVet(_cQryZ08)

	// se não encontrou feirinha, aborta rotina
	If (Len(_aRecFeiZ08) < 1)
		Return( .F. )
	EndIf

	// inicio da pesquisa pra gravar a feirinha
	// se endereço final ainda não definido, avisa usuario
	If ( Empty(mvEndDes) )
		U_FtWmsMsg("Doca ainda não definida para OS. Obrigatório escolher na próxima tela ou processo será abortado.", "Atenção!" )

		// se não há cliente ou loja preenchido (como por exemplo em erro ou queda de conexão do coletor e entra novamente na rotina)
		// então preencho com base na feirinha corrente
		If ( Empty(_cCodCliMov) .OR. Empty(_cLjCliMov) )
			_cCodCliMov := _aRecFeiZ08[1][4]
			_cLjCliMov  := _aRecFeiZ08[1][5]
		EndIf

		// se não há número de OS preenchido (como por exemplo em erro ou queda de conexão do coletor e entra novamente na rotina)
		// então preencho com base na feirinha corrente
		If (Empty(_cNumOrdSrv))
			_cNumOrdSrv := _aRecFeiZ08[1][2]
		EndIf

		If (Empty(_cArmzAtual))
			_cArmzAtual := _aRecFeiZ08[1][7]
		EndIf

		// funcao para definicao de DOCA de expedicao
		_lRet := sfDefDocExp( _cCodCliMov, _cLjCliMov )
	Else
		// atualizo a variável que informa o endereço final aonde a feirinha será descarregada
		_cEndDesti := mvEndDes
	EndIf

	// atualiza tipo de operação
	_cTipoOper := "S"

	// defino a data da operação de finalização
	If (Empty(_cDtIni)) .And. (Empty(_cHrIni))
		_cDtIni := Date()
		_cHrIni := Time()
	EndIf

	// tela pra confirmação de endereço onde posiciona a Z08 e demais dados para poder comparar
	If (_lRet)
		_lRet := sfConfDest( .T. , .F. )
	EndIf

	// se confirmou o endereço de destino, continua
	If (_lRet)
		// percorre o array para descarregar a feirinha
		For _nZ08 := 1 to Len(_aRecFeiZ08)
			// preencho a variável pra finalizar o registro
			_cIdPalete := _aRecFeiZ08[_nZ08][1]

			// preencho os dados da Os para ser finalizada
			_cNumOrdSrv := _aRecFeiZ08[_nZ08][2]
			_cSeqOrdSrv := _aRecFeiZ08[_nZ08][3]
			_cCodCliMov := _aRecFeiZ08[_nZ08][4]
			_cLjCliMov  := _aRecFeiZ08[_nZ08][5]
			// endereço de origem para atualização
			_cEndOrige  := _aRecFeiZ08[_nZ08][6]
			// definição dos armazéns pra gravar na Z17
			_cLocAtual  := _aRecFeiZ08[_nZ08][7]
			_cLocDesti  := _aRecFeiZ08[_nZ08][8]

			If (_lRet)
				// cria registro da movimentação na Z17
				dbSelectArea("Z17")
				Z17->( dbSetOrder(1) )
				Z17->( dbSeek( _cSeekZ17 := xFilial("Z17") + _cIdPalete ) )

				// para os registros encontrados, validamos se foi daquele movimento específico
				While (Z17->( ! EoF()) ) .And. (Z17->(Z17_FILIAL + Z17_ETQPLT) == _cSeekZ17)
					// valido o endereço de origem e o endereço de destino
					If (Z17->Z17_ENDORI != _cEndOrige) .And. (Z17->Z17_ENDDES != _cEndDesti)
						// grava registro de movimento na Z17
						dbSelectArea("Z17")
						RecLock("Z17",.T.)
						Z17->Z17_FILIAL := xFilial("Z17")
						Z17->Z17_ETQPLT := _cIdPalete
						Z17->Z17_ENDORI := _cEndOrige
						Z17->Z17_ENDDES := _cEndDesti
						Z17->Z17_DTINI  := Date()
						Z17->Z17_HRINI  := Time()
						Z17->Z17_OPERAD := _cCodOper
						Z17->Z17_EQUIPA := _cCodEquip
						Z17->Z17_NUMOS  := _cNumOrdSrv
						Z17->Z17_SEQOS  := _cSeqOrdSrv
						Z17->Z17_STATUS := "M" // R=Realizado / C=Cancelado / M=Em Movimento
						Z17->Z17_TIPLAN := "NM" // NM=Normal / ES=Estorno / AJ=Ajuste / DV=Devolução / FR=Fracionamento / DF=Dev. Fracion.
						Z17->Z17_ORILAN := "A" // A=Automática / M=Manual
						Z17->Z17_LOCORI := _cLocAtual
						Z17->Z17_LOCDES := _cLocDesti
						Z17->(MsUnLock())
					EndIf
					Z17->( dbSkip() )
				EndDo
			EndIf

			If (_lRet)
				// chamo a rotina específica para a feirinha
				If ( ! sfGrvEndDest(_cTipoOper, .F., .T.) )
					U_FtWmsMsg('Erro ao realizar o endereçamento dos produtos coletados. Acesse novamente a coleta atual para continuar o processo.','ATENCAO')
					_lRet := .F.
					UnLockByName("COLETA_" + cFilAnt + _cCliFeira,.T.,.T.,.T.)
					Return(_lRet)
				EndIf
			EndIf
		Next _nZ08
	EndIf

	// destrava semáforo quando chegou ao final da tentativa da descarga da coleta atual
	UnLockByName("COLETA_" + cFilAnt + _cCliFeira,.T.,.T.,.T.)

Return (_lRet)

// ** função que verifica se há saldo no pallet
Static Function sfVldArmSld()

	// variavel de retorno
	local _lRet := .F.
	// query
	local _cQry := ""
	local _aCompara := {}

	// pesquiso se sobrou saldo no pallet e que não possui OS pra ele ainda
	_cQry := " SELECT ISNULL(SUM(Z16_SALDO),0) SALDOZ16, Z16_CODPRO "
	_cQry += " FROM " + RetSqlTab("Z16") + " (nolock) "
	_cQry += " WHERE Z16_ETQPAL = '" +  _cIdPalete +"' "
	_cQry += " AND " + RetSqlCond("Z16")
	_cQry += " AND Z16_SALDO > 0 "
	_cQry += " GROUP BY Z16_CODPRO "

	memowrit("C:\query\TWMSA011_sfVldArmSld.txt",_cQry)

	// jogo pra variavel de comparação
	_aCompara := U_SqlToVet(_cQry)

	// se tiver mais de um produto já armazena de volta
	If (Len(_aCompara) > 1)
		_lRet := .T.

		// se tiver só um registro pesquisa na Z08 pra ver se existe a necessidade daquele pallet ser levado pro enddes
	ElseIf (Len(_aCompara) == 1)
		_cQry := " SELECT COUNT(*) QTDREG "
		_cQry += " FROM " + RetSqlTab("Z08") + " (nolock) "
		_cQry += " WHERE " + RetSqlCond("Z08")
		_cQry += " AND Z08_NUMOS = '"+_cNumOrdSrv+"'"                   // mesma OS
		_cQry += " AND Z08_PRODUT = '"+CVALTOCHAR(_aCompara[1][2])+"' " // mesmo PRODUTO
		_cQry += " AND Z08_QUANT  = '"+CVALTOCHAR(_aCompara[1][1])+"' "  // mesma QUANTIDADE
		_cQry += " AND Z08_PALLET = '"+_cIdPalete+"' "				// mesmo PALLET
		_cQry += " AND Z08_NEWPLT = '' "								// NEWPLT em branco

		// caso não seja encontrado registro
		If (U_FtQuery(_cQry) == 0)
			_lRet := .T.
		EndIf
	EndIf

Return (_lRet)

// ** função para validar se o saldo é para ser fracionado
Static Function sfVldFraSld()
	local _cQuery := ""
	local _lRet := .F.

	_cQuery := "  SELECT COUNT(DISTINCT Z16_CODPRO)"
	_cQuery += "  FROM "+RetSqlTab("Z16")+" (nolock) "
	_cQuery += "  WHERE Z16_ETQPAL = '"+Z08->Z08_PALLET+"' "
	_cQuery += "  AND "+RetSqlCond("Z16")
	_cQuery += "  AND Z16_SALDO > 0 "
	_cQuery += "  AND EXISTS ( "
	_cQuery += "  SELECT * FROM "+RetSqlTab("Z08")+" (nolock) "
	_cQuery += "  WHERE Z08_FILIAL = Z16_FILIAL "
	_cQuery += "  AND D_E_L_E_T_ = '' "
	_cQuery += "  AND Z08_PALLET = Z16_ETQPAL "
	_cQuery += "  AND Z08_NUMOS = '"+_cNumOrdSrv+"' "
	_cQuery += "  AND Z08_STATUS <> 'R' )"

	memowrit("C:\query\TWMSA011_sfVldFraSld.txt",_cQuery)

	If (U_FtQuery(_cQuery) == 1)
		_lRet := .T.
	EndIf

Return(_lRet)

// ** funcao para validacao do id da etiqueta (palete ou endereco)
Static Function sfVldEtiqueta(mvContProc, mvWndOrig, mvFechaTela)
	// variavel de retorno
	local _lRet := .T.
	// query
	local _cQuery
	local _aLinhaZ08
	local _lMailLock

	local _lApOpo := .F.

	// variavel temporaria
	local _aTmpPalete := {}
	local _cTmpEtique

	// conteudo a ser retidado do palete (desmontagem)
	local _aItemRet := {}

	// incremento da quantidade de leitura
	local _nIncLeiEtq := 0

	// novo palete gerado
	local _cNovoPltFra := Space(_nTamIdEtq)

	// encontrou registro no cadastro de etiquetas
	local _lAchouEtq := .F.

	// tentativas de localizar etiqueta
	local _nTent

	// variável para guardar o retorno da OS de inventário
	local _cOSInv := CriaVar("Z05_NUMOS",.F.)

	// variável para loop de identificação de feirinha
	local _nLin := 0

	// atualiza feira
	_aPrdFeira := sfARetFeira()

	// valida quantidade de registros na coleta da feirinha
	If (Len(_aPrdFeira) > _nQtdRegFei)
		// mensagem
		U_FtWmsMsg("ATENÇÃO: Excedeu o número máximo de volumes para coleta. Finalize a coleta atual!")
		// variavel de controle
		_lRet := .F.
	EndIf

	// pesquisa se a etiqueta é valida
	If (_lRet)

		// faz 2 tentativas de busca da etiqueta
		For _nTent := 1 to 2

			// se encontrou, sai do Loop
			If (_lAchouEtq)
				Exit
			EndIf

			// tentativa 1 - Cod Etiqueta Interna
			If (_nTent == 1)

				// padroniza tamanho da pesquisa
				_cTmpEtique := PadR(_cIdEtiqueta, Len(Z11->Z11_CODETI))

				// cadastro de etiquetas
				dbSelectArea("Z11")
				Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
				If Z11->(dbSeek( xFilial("Z11") + _cTmpEtique )) .And. (Z11->Z11_TIPO != "07")
					_lAchouEtq := .T.
				EndIf

				// tentativa 2 - Cod Etiqueta Cliente
			ElseIf (_nTent == 2)

				// padroniza tamanho da pesquisa
				_cTmpEtique := PadR(_cIdEtiqueta, Len(Z11->Z11_ETIQUE))

				// cadastro de etiquetas
				dbSelectArea("Z11")
				Z11->(dbSetOrder(2)) // 1 - Z11_FILIAL, Z11_ETIQUE, Z11_CLIENT
				If Z11->(dbSeek( xFilial("Z11") + _cTmpEtique )) .And. (Z11->Z11_TIPO == "07")
					_lAchouEtq := .T.
				EndIf

			EndIf

		Next _nTent

		// tratamento do retorno
		If ( ! _lAchouEtq )
			// mensagem
			U_FtWmsMsg("Etiqueta inválida!", "ATENCAO")
			// variavel de controle
			_lRet := .F.
		EndIf

	EndIf

	// reinicia variaveis
	_cEndOrige   := Space(Len(_cEndOrige))
	_cEndDesti   := Space(Len(_cEndDesti))
	_cEndPicDro  := Space(Len(_cEndPicDro))
	_cArmzAtual  := Space(Len(_cArmzAtual))
	_cArmzDesti  := Space(Len(_cArmzDesti))
	_cIdPalete   := Space(_nTamIdEtq)
	_cCodUnit    := Space(Len(_cCodUnit))
	_cIdEndere   := Space(_nTamIdEtq)

	// valida o tipo da etiqueta lida
	If (_lRet)

		If (Z11->Z11_TIPO == "01") .Or. (Z11->Z11_TIPO == "04") .Or. (Z11->Z11_TIPO == "07") // 01 - etiqueta de produto | 04 - etiqueta agrupadora | 07 - Etiqueta do Cliente
			// pesquisa um palete
			_cIdEtiqueta := sfRetNrPalete(_cIdEtiqueta, Z11->Z11_TIPO)
			// valida se encontrou o palete
			_lRet := ( ! Empty(_cIdEtiqueta) )
			// se encontrou, reposiciona
			If (_lRet)
				dbSelectArea("Z11")
				Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
				If ! Z11->(dbSeek( xFilial("Z11")+_cIdEtiqueta ))
					U_FtWmsMsg("Identificador do palete inválido!","ATENCAO")
					_lRet := .F.
				EndIf

				// atualiza os dados do palete
				If (_lRet)
					_cCodUnit  := Z11->Z11_UNITIZ
					_cIdPalete := _cIdEtiqueta
				EndIf
				// incremento da quantidade de leitura
				_nIncLeiEtq := 1

			EndIf

		ElseIf (Z11->Z11_TIPO == "02") // 02 - etiqueta de endereco
			// atualiza variaveis do endereco atual e origem
			_cArmzAtual := Z11->Z11_LOCAL
			_cArmzDesti := Z11->Z11_LOCAL
			_cEndOrige  := Z11->Z11_ENDERE
			_cEndAtual  := Z11->Z11_ENDERE
			// incremento da quantidade de leitura
			_nIncLeiEtq := 0

		ElseIf (Z11->Z11_TIPO == "03") // 03 - etiqueta de palete
			_cCodUnit  := Z11->Z11_UNITIZ
			_cIdPalete := _cIdEtiqueta
			// incremento da quantidade de leitura
			_nIncLeiEtq := 1

		Else
			U_FtWmsMsg("Tipo de etiqueta inválida!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	If (_lRet)

		// paletes disponiveis para RECEBIMENTO/ARMAZENAGEM
		_cQuery := " SELECT DISTINCT Z05_TPOPER, Z07_NUMOS NUM_OS, Z07_SEQOS SEQ_OS, Z16_ETQPAL ETQ_PLT, Z07_LOCAL ARMORI, Z16_ENDATU END_ATU, "
		_cQuery += " CASE WHEN Z16_ETQVOL <> '' AND Z16_CODKIT <> '' THEN Z16_CODKIT ELSE Z16_CODPRO END COD_PROD, Z05_CLIENT CODCLI, Z05_LOJA LOJACLI, Z16_LOCAL ARMPLT, "
		_cQuery += " Z16_LOTCTL PLT_LOTE, Z16_TPESTO "
		// formacao de paletes
		_cQuery += " FROM " + RetSqlTab("Z16") + " WITH(NOLOCK) "

		// paletes conferidos no recebimento
		_cQuery += " INNER JOIN " + RetSqlTab("Z07") + " WITH(NOLOCK) ON " + RetSqlCond("Z07") + " AND Z07_PALLET = Z16_ETQPAL "
		_cQuery += " AND Z07_ETQVOL = Z16_ETQVOL AND Z16_CODPRO = Z07_PRODUT AND Z07_CODBAR = Z16_CODBAR AND Z07_STATUS = 'D' "
		_cQuery += " AND Z07_LOTCTL = Z16_LOTCTL "

		// filtro por numero de OS (alterado para CHARINDEX, pois sub-query e IN perde performance)
		_cQuery += " AND CHARINDEX(Z07_NUMOS, '"+_cQryChrIn+"') > 0 "

		// cab. da OS
		_cQuery += " INNER JOIN " + RetSqlTab("Z05") + " WITH(NOLOCK,INDEX("+RetSqlName("Z05")+"1)) ON " + RetSqlCond("Z05") + " AND Z05_NUMOS = Z07_NUMOS "

		// somente OS de entrada
		_cQuery += " AND Z05_TPOPER = 'E' "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("Z16")
		// filtra o ID do palete
		_cQuery += " AND (Z16_ETQPAL = '" + _cIdPalete + "' OR Z16_ENDATU = '" + _cEndOrige + "') "
		// filtra somente no endereco de servico que o usuario tem acesso
		_cQuery += " AND Z16_ENDATU IN " + FormatIn(_cEndServ, "|")
		// filtra somente no endereco que o equipamento pode trabalhar
		_cQuery += " AND "+StrTran(_cQryEndEq,"CMP_ENDSRV","Z16_ENDATU")+" "

		_cQuery += "UNION ALL "

		// paletes disponiveis para EXPEDICAO/PALETEIRO e INTERNA
		_cQuery += "SELECT DISTINCT Z05_TPOPER, Z08_NUMOS NUM_OS, Z08_SEQOS SEQ_OS,
		_cQuery += " CASE "
		_cQuery += " WHEN Z08_FRAPLT = 'S' AND Z08_NEWPLT != ' ' "
		_cQuery += " THEN Z08_NEWPLT  "
		_cQuery += " ELSE Z16_ETQPAL END ETQ_PLT, Z08_LOCAL ARMORI, Z16_ENDATU END_ATU, "
		_cQuery += " CASE WHEN Z16_ETQVOL <> '' AND Z16_CODKIT <> '' THEN Z16_CODKIT ELSE Z16_CODPRO END COD_PROD, Z05_CLIENT CODCLI, Z05_LOJA LOJACLI, Z08_LOCDES ARMDES, "
		_cQuery += " Z16_LOTCTL PLT_LOTE, Z16_TPESTO "
		// mapa de separacao/expedicao
		_cQuery += " FROM "+RetSqlTab("Z08") + " (nolock) "
		// formacao de paletes
		_cQuery += " INNER JOIN "+RetSqlTab("Z16")+" (nolock)  ON "+RetSqlCond("Z16")+" AND Z16_SALDO > 0 AND Z16_ETQPAL = ("
		_cQuery += "  CASE "
		_cQuery += "    WHEN Z08_FRAPLT = 'S' AND Z08_NEWPLT != ' ' THEN Z08_NEWPLT "
		_cQuery += "    ELSE Z08_PALLET "
		_cQuery += "  END "
		_cQuery += "  ) "

		// cab. da OS
		_cQuery += " INNER JOIN "+RetSqlTab("Z05")+" (nolock)  ON "+RetSqlCond("Z05")+" AND Z05_NUMOS = Z08_NUMOS "

		// OS de saida ou interna
		_cQuery += " AND Z05_TPOPER IN ('S','I') "
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("Z08")

		// filtro por numero de OS (alterado para CHARINDEX, pois sub-query e IN perde performance)
		_cQuery += " AND CHARINDEX(Z08_NUMOS, '"+_cQryChrIn+"') > 0 "

		// filtra pelo codigo do endereco OU palete (somente no endereco de transacao)
		_cQuery += "AND ( "
		_cQuery += "      (Z08_ENDSRV = '"+_cEndAtual+"') "
		_cQuery += "      OR "
		// adicionei parte de sql pra pegar o id do new pallet
		_cQuery += "      ( (Z08_FRAPLT = 'N' AND Z08_PALLET = '"+_cIdPalete+"') "
		_cQuery += "         OR "
		_cQuery += "        (Z08_FRAPLT = 'S' AND Z08_NEWPLT != ' ' AND Z08_NEWPLT = '"+_cIdPalete+"') "
		_cQuery += "         OR "
		_cQuery += "        (Z08_FRAPLT = 'S' AND Z08_NEWPLT  = ' ' AND Z08_PALLET = '"+_cIdPalete+"') "
		_cQuery += "      ) "
		_cQuery += "    ) "

		// filtra somente no endereco que o equipamento pode trabalhar
		_cQuery += " AND " + StrTran(_cQryEndEq, "CMP_ENDSRV", "Z16_ENDATU")

		// status do mapa
		_cQuery += " AND Z08_STATUS = 'P' "

		// filtra somente no endereco de servico que o usuario tem acesso
		_cQuery += " AND Z08_ENDSRV IN " + FormatIn(_cEndServ, "|")

		memowrit("c:\query\twmsa011_sfVldEtiqueta1.txt",_cQuery)

		// atualiza a variavel temporaria
		_aTmpPalete := U_SqlToVet(_cQuery)

		// verifica a quantidade de paletes encontrado
		If (Len(_aTmpPalete) == 0) .AND. !( sfPegaOpor(_cIdPalete, @_aTmpPalete, _cQuery ) )              // não encontrou o pallet/produto lido nas pendências de movimentação e não conseguiu apanhe de oportunidade
			U_FtWmsMsg("Palete não encontrado, não disponível ou não permitido para esta ordem serviço!","ATENCAO")
			_lRet := .F.
			//		ElseIf (Len(_aTmpPalete) > 0)
		Else
			// define o tipo da operacao da OS (E-Ent/S-Sai/I-Int)
			_cTipoOper := _aTmpPalete[1][1]
			// numero da OS
			_cNumOrdSrv := _aTmpPalete[1][2]

			// define se eh OS de Recebimento ou Expedicao
			_lOSRec := (_cTipoOper == "E")
			_lOSExp := (_cTipoOper == "S")
			_lOSInt := (_cTipoOper == "I")

			// define o endereco de origem
			_cEndOrige  := _aTmpPalete[1][6]

			// define armazéns
			_cArmzAtual := _aTmpPalete[1][5]

			// codigo do produto no palete
			_cCdProdPlt := _aTmpPalete[1][7]

			// dados do cliente
			_cCodCliMov := _aTmpPalete[1][8]
			_cLjCliMov  := _aTmpPalete[1][9]

			// validação da armazenagem no primeiro nível
			_lArmPrimNiv := U_FtWmsParam("WMS_CONTROLE_ARM_PRIMEIRO_NIVEL","L",.F.,.F.,Nil, _cCodCliMov, _cLjCliMov, Nil, Nil)

			// permite validação por volumes
			_lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.F.,.F.,Nil, _cCodCliMov, _cLjCliMov, Nil, Nil)

			// lote
			_cLotePlt := _aTmpPalete[1][11]

			// tipo de estoque
			_cMovTpEst := _aTmpPalete[1][12]

			// atualiza a ABA ativa
			If (_lOSRec) // recebimento
				_nFldAtivo := 1
			EndIf
			If (_lOSExp) // expedicao
				_nFldAtivo := 2
			EndIf
			If (_lOSInt) // interna
				_nFldAtivo := 3
			EndIf
		EndIf

	EndIf

	// valida se o endereco de origem está bloqueado
	If (_lRet)
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
		If SBE->(dbSeek( xFilial("SBE") + _cArmzAtual + _cEndOrige)) .And. (SBE->BE_STATUS == "3")
			U_FtWmsMsg("O endereço de origem está bloqueado. A operação não pode ser realizada!")
			_lRet := .F.
		EndIf
	EndIf

	// valida se o endereço de origem está em processo de inventário
	If (_lRet)
		If ( U_FTEndInv(_cEndOrige, _cArmzAtual, @_cOSInv) )
			U_FtWmsMsg("O endereço de origem está em processo de inventário na OS " + _cOSInv + ". A operação não pode ser realizada!")
			_lRet := .F.
		EndIf
	EndIf

	// pesquisa itens disponiveis para movimentacao
	If (_lRet) .And. ( ! Empty(_cIdPalete) )
		// monta a query pra buscar os dados
		_cQuery := " SELECT Z08.R_E_C_N_O_ Z08RECNO, Z08_LOCAL, Z08_ENDDES, "
		_cQuery += " CASE "
		_cQuery += " WHEN Z08_FRAPLT = 'S' AND Z08_NEWPLT != ' ' "
		_cQuery += " THEN Z08_NEWPLT  "
		_cQuery += " ELSE Z08_PALLET END Z08_PALLET, "
		_cQuery += " Z08_LOTCTL, "
		_cQuery += " Z06_ATUEST "
		// itens da ordem de servico
		_cQuery += " FROM "+RetSqlTab("Z06") + " (nolock) "
		// cab. da OS
		_cQuery += " INNER JOIN "+RetSqlTab("Z05")+" (nolock)  ON "+RetSqlCond("Z05")+" AND Z05_NUMOS = Z06_NUMOS "
		// itens conferidos
		_cQuery += " INNER JOIN "+RetSqlTab("Z08")+" (nolock)  ON "+RetSqlCond("Z08")+" AND Z08_NUMOS = Z06_NUMOS AND Z08_SEQOS = Z06_SEQOS "
		// numero de contagens
		_cQuery += " AND Z08_NRCONT = Z06_NRCONT "
		// somente itens pendentes
		_cQuery += " AND Z08_DTFINA = ' ' "
		// itens planejados
		_cQuery += " AND Z08_STATUS = 'P' "

		If (_lOSRec) // tratamento para OS de Recebimento
			// filtra pelo endereco de servico/origem
			_cQuery += " AND Z08_ENDSRV = '"+_cEndOrige+"' "
			// identificador do palete / ou endereco de ORIGEM igual a do SERVICO
			_cQuery += " AND ( Z08_PALLET = '"+_cIdPalete+"' OR (Z08_PALLET = ' ' AND Z08_ENDORI = Z08_ENDSRV )) "
			// filtra endereco reservado para o produto do palete
			_cQuery += " AND Z08_PRODUT = '"+_cCdProdPlt+"' "
			// uso do lote
			_cQuery += " AND ( Z08_LOTCTL = ' ' OR Z08_LOTCTL = '" + _cLotePlt + "' ) "
			// tipo de estoque
			_cQuery += " AND ( Z08_TPESTO = ' ' OR Z08_TPESTO = '" + _cMovTpEst + "' ) "

		ElseIf (_lOSExp) .Or. (_lOSInt) // tratamento para OS de Expedicao / interna
			// filtra pelo codigo do endereco OU palete (somente no endereco de transacao)
			_cQuery += " AND ( "
			_cQuery += "       (Z08_ENDSRV = '" + _cEndAtual + "') "
			_cQuery += "       OR "
			// adicionei parte de sql pra pegar o id do new pallet
			_cQuery += "       ( (Z08_FRAPLT = 'N' AND Z08_PALLET = '" + _cIdPalete + "') "
			_cQuery += "          OR "
			_cQuery += "         (Z08_FRAPLT = 'S' AND Z08_NEWPLT != ' ' AND Z08_NEWPLT = '" + _cIdPalete + "') "
			_cQuery += "          OR "
			_cQuery += "         (Z08_FRAPLT = 'S' AND Z08_NEWPLT  = ' ' AND Z08_PALLET = '" + _cIdPalete + "') "
			_cQuery += "       ) "
			_cQuery += "     ) "
		EndIf

		// insere o filtro padrao do usuario/operador
		_cQuery += " WHERE " + cQryFilZ06
		// filtro do numero da OS
		_cQuery += " AND Z06_NUMOS = '" + _cNumOrdSrv + "' "

		// filtra somente no endereco que o equipamento pode trabalhar
		_cQuery += " AND " + StrTran(_cQryEndEq, "CMP_ENDSRV", "Z08_ENDSRV")+" "

		// ordem dos dados
		_cQuery += " ORDER BY SUBSTRING(Z08_ENDDES,1,2), SUBSTRING(Z08_ENDDES,4,2), SUBSTRING(Z08_ENDDES,3,1), SUBSTRING(Z08_ENDDES,8,5), SUBSTRING(Z08_ENDDES,6,2) "

		memowrit("c:\query\twmsa011_sfVldEtiqueta2.txt",_cQuery)

		// alimenta variavel temporaria
		_aLinhaZ08 := U_SqlToVet(_cQuery)

		// verifica se encontrou o pallet
		If (Len(_aLinhaZ08) == 0)
			// mensagem
			U_FtWmsMsg("Este palete não está disponível!","ATENCAO")
			// variavel de retorno
			_lRet := .F.
		EndIf

		// valida se tem alguma coisa na feirinha
		If  ( Len(_aPrdFeira) > 0 )
			// valida se o endereço destino do pallet bipado é o mesmo da coleta atual (feirinha) caso esteja em processo de apanhe
			For _nLin := 1 to Len(_aLinhaZ08)
				If (_aPrdFeira[1][2] != _aLinhaZ08[_nLin][3] ) .OR. ( Empty(_aLinhaZ08[_nLin][3]) )
					U_FtWmsMsg("O endereço destino deste pallet/volume é diferente do que a coleta atual. Descarregue seu pallet e tente novamente.")
					_lRet := .F.
				EndIf
			Next _nLin
		EndIf

	EndIf

	// se encontrou os dados do palete tenta reservar itens para movimentacao
	If (_lRet) .And. ( ! Empty(_cIdPalete) )

		// tenta reserva completa do palete
		_lRet := sfLockPlt(_cIdPalete)

	EndIf

	//	// verifica se há bloqueio registro do mapa, antes de tentar a gravação (poderia ficar trancado)
	//	If (_lRet) .AND. ( ! Z08->( MsRLock()) )   // está bloqueado
	//		U_FtWmsMsg("OS " + Z08->Z08_NUMOS + " bloqueada (em transação) por outro usuário." + CRLF + "Aguarde 1 minuto e tente novamente! (3) - RECNO" + Str( Z08->( Recno() )), "TWMSA011 - sfLockOS (3)", .F., .T.)
	//		_lRet := .F.
	//	endIf

	// se encontrou os dados do palete, define status como M-Em Movimento e realiza as gravações necessárias
	If (_lRet) .And. ( ! Empty(_cIdPalete) )

		// atualiza o RECNO do Z08
		_nRecnoZ08 := _aLinhaZ08[1][1]

		// limpa flag do email (evita envio em duplicidade)
		_lMailLock := .F.

		// posiciona no registro da tabela
		dbSelectArea("Z08")
		Z08->(dbGoTo( _nRecnoZ08 ))

		//testa se ja esta bloqueado
		While ( ! Z08->( MsRLock()) )
			// mensagem apos movimentacao, para nao bloquear transacao
			U_FtWmsMsg("Registro " + Str( _nRecnoZ08 ) + " bloqueado por outro usuário.Aguarde alguns segundos e tente novamente!", "Atenção", .F., .T.)

			//envia o email
			if !(_lMailLock)
				U_FtMail( "Pallet -" + _cIdPalete + "/Filial-" + cFilAnt + "/usuario-" + __cUserId + "/Recno-Z08- " + Str(_nRecnoZ08) ,;
				"Lock detectado na movimentação (1)! - Z08 RECNO" + Str(_nRecnoZ08),;
				"ti@tecadi.com.br")
				_lMailLock := .T.
			Endif

			// loop
			Loop
		EndDo

		// tenta bloquear o registro do mapa
		While ( ! SoftLock("Z08") )
			// mensagem apos movimentacao, para nao bloquear transacao
			U_FtWmsMsg("Não foi possível bloquear o registro do mapa da OS. RECNO " + Str( Z08->( Recno() )) + CRLF + "Favor tentar novamente!", "TWMSA011 - sfVldEtiqueta", .F., .T.)

			//envia o email
			if !(_lMailLock)
				U_FtMail( "Pallet -" + _cIdPalete + "/Filial-" + cFilAnt + "/usuario-" + __cUserId + "/Recno-Z08- " + Str(_nRecnoZ08) ,;
				"Lock detectado na movimentação (2)! - Z08 RECNO" + Str(_nRecnoZ08),;
				"ti@tecadi.com.br")
				_lMailLock := .T.
			Endif

			Loop
		EndDo

		// adiciona RECNO para controle
		Aadd(_aRegLock, {"Z08", Z08->( RecNo() )} )

		// define os armazéns para transferência entre armazéns
		_cArmzAtual := Z08->Z08_LOCAL
		_cArmzDesti := Z08->Z08_LOCDES

		// sequencial da OS
		_cSeqOrdSrv := Z08->Z08_SEQOS

		// atualiza o endereco de destino
		_cEndDesti := sfRetEndDest(Z08->Z08_ENDDES, Z08->Z08_ENDTRA)

		// valida se o endereço de destino está em processo de inventário
		If (_lRet) .AND. ( U_FTEndInv(_cEndDesti, _cArmzAtual, @_cOSInv) )
			U_FtWmsMsg("O endereço de destino está em processo de inventário na OS " + _cOSInv + ". A operação não pode ser realizada!")
			_lRet := .F.
		EndIf

		// valida se o endereco de destino eh valido
		If (_lRet)
			dbSelectArea("SBE")
			SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
			If SBE->(dbSeek(xFilial("SBE") + _cArmzAtual + _cEndDesti)) .And. (SBE->BE_STATUS == "3")
				U_FtWmsMsg("Endereço de destino " + _cEndDesti + " bloqueado. Entre em contato com o seu supervisor para desbloquear.", "End. bloqueado - sfVldEtiqueta")
				_lRet := .F.
			EndIf
		EndIf

		// grava movimentação no mapa se passou nas validações
		If (_lRet)
			// atualiza os dados do mapa
			RecLock("Z08")
			Z08->Z08_DTINIC := Date()
			Z08->Z08_HRINIC := Time()
			Z08->Z08_STATUS := "M" // P-Planejado / R-Realizado / M-Movimento / E-Erro
			Z08->Z08_USUARI := _cCodOper
			Z08->Z08_USRMOV := _cCodOper
			Z08->Z08_EQUIPA := _cCodEquip
			// atualiza o palete e lote somente para OS de Recebimento
			If (_lOSRec) .And. (Empty(Z08->Z08_PALLET))
				// palete
				Z08->Z08_PALLET := _cIdPalete
				// atualiza lote
				If (Empty(Z08->Z08_LOTCTL))
					Z08->Z08_LOTCTL := sfLotPalet(_cIdPalete)
				EndIf
			EndIf
			Z08->(MsUnLock())

			// preencho as variaveis inicias de data e hora
			_cDtIni := Z08->Z08_DTINIC
			_cHrIni := Z08->Z08_HRINIC

			// utilizado para feirinha
			_cEndFimMov := Z08->Z08_ENDDES

			// atualiza endereco de transacao entre movimentos (Pick And Drop)
			_cEndPicDro := Z08->Z08_ENDTRA

			// atualiza o status da conferência se for OS de recebimento
			If (_lOSRec)
				// atualiza o status do palete para M-EM MOVIMENTO
				_cQuery := " UPDATE " + RetSqlName("Z07")
				_cQuery += " SET Z07_STATUS = 'M' "
				// filtros
				_cQuery += " WHERE Z07_FILIAL = '" + xFilial("Z07") + "' AND D_E_L_E_T_ = ' ' "
				_cQuery += " AND Z07_NUMOS  = '" + _cNumOrdSrv + "' "
				_cQuery += " AND Z07_PALLET = '" + _cIdPalete + "' "
				_cQuery += " AND Z07_STATUS = 'D' "
				// executa o update
				TcSQLExec(_cQuery)
			EndIf
		EndIf
	EndIf

	// atualiza a quantidade de leitura
	If (_lRet)
		RecLock("Z11")
		Z11->Z11_QTDLEI += _nIncLeiEtq
		Z11->(MsUnLock())
	EndIf

	// registra o inicio do movimento da mercadoria
	If (_lRet) .And. ( ! Empty(_cIdPalete) )

		// gera registro de movimentacao
		dbSelectArea("Z17")
		RecLock("Z17",.T.)
		Z17->Z17_FILIAL	:= xFilial("Z17")
		Z17->Z17_ETQPLT := Iif(!Empty(Z08->Z08_NEWPLT),Z08->Z08_NEWPLT,Z08->Z08_PALLET)
		Z17->Z17_ENDORI	:= Iif( ! Empty(Z08->Z08_NEWPLT), Z08->Z08_ENDTRA, _cEndOrige)
		Z17->Z17_DTINI	:= Date()
		Z17->Z17_HRINI	:= Time()
		Z17->Z17_OPERAD	:= _cCodOper
		Z17->Z17_EQUIPA	:= _cCodEquip
		Z17->Z17_NUMOS	:= Z08->Z08_NUMOS
		Z17->Z17_SEQOS	:= Z08->Z08_SEQOS
		Z17->Z17_STATUS := "M"  // R=Realizado / C=Cancelado / M=Em Movimento
		Z17->Z17_TIPLAN := "NM" // NM=Normal / ES=Estorno / AJ=Ajuste / DV=Devolução / FR=Fracionamento / DF=Dev. Fracion.
		Z17->Z17_ORILAN := "A"  // A=Automática / M=Manual
		Z17->Z17_LOCORI := Z08->Z08_LOCAL
		Z17->Z17_LOCDES := Z08->Z08_LOCDES
		Z17->(MsUnLock())

		// gravo o recno para identificar a movimentação atual
		_nRecnoZ17 := Z17->( Recno() )

	EndIf

	// variavel de retorno para continuacao do processo
	mvContProc := _lRet

	// se existir o objeto, fecha
	If (mvWndOrig <> nil) .And. (_lRet)
		// permite fechar a tela
		mvFechaTela := .T.
		// fecha a tela
		mvWndOrig:End()
	EndIf

Return(_lRet)

// ** funcao que Retorna o erro da Rotina Automatica
Static Function sfAchaErro()
	Local cStartPath:= GetSrvProfString("Startpath","")
	Local cFileLog	:= Alltrim(cStartPath) + Alltrim(NomeAutoLog())

	Local cRet		:= ""

	//Pega o Conteudo do Arquivo Texto do LOG
	Local cConteudo	:= MemoRead( cFileLog )

	Local nPos

	memowrit("C:\query\error_movi.txt",cConteudo)

	If "HELP: OBRIGAT" $ cConteudo
		cRet := StrTran(cConteudo,chr(13)+chr(10)," ")
	Else

		aConteudo := Separa(cConteudo,chr(13)+chr(10))

		For nPos := 1 to Len(aConteudo)
			If (nPos == 1) .Or. (nPos == 2)
				cRet += aConteudo[nPos] +" "
			ElseIf "< -- Invalido" $ aConteudo[nPos]
				cRet += aConteudo[nPos] +" "
			EndIf

		Next nPos

	EndIf

	fErase(cFileLog)

Return cRet

// ** funcao que confirma o movimento de distribuicao
Static Function sfGrvEndDest(mvTipoOper, mvDevPosIni, mvAbreTrans)

	// variavel de retorno
	Local _lRet := .T.
	// se abre a transação, utiliza o BEGIN pra garantir a integridade dos dados
	IIf(mvAbreTrans, BeginTran() ,Nil)

	// mostra informação de processando para o usuário
	MsgRun("Gravando dados...", "Aguarde...", {|| _lRet := sfProcEndDest(mvTipoOper, mvDevPosIni) })

	// caso tenha dado qualquer erro, rollback na transação
	If ( ! _lRet) .And. (mvAbreTrans)
		_lRet := .F.
		DisarmTransaction()
		Break
	EndIf

	// commita a transação
	IIf(mvAbreTrans, EndTran() ,Nil)

	// libera todos os registros
	MsUnLockAll()

	// encerra a ordem de serviço
	If (_lEncOrdSrv) .And. _lRet

		// atualiza o status do servico para FI-FINALIZADO
		U_FtWmsSta(_cCodStatus,;
		"FI",;
		_cNumOrdSrv,;
		_cSeqOrdSrv)

		// Gera arquivo de EDI padrão TECADI TECADI-EDI-04 no FTP
		IF (_lOSRec) .AND. ( U_FtWmsParam("WMS_RECEBIMENTO_EDI_FTP_DISP_ESTOQUE", "L", .F., .F., "", Z08->Z08_CLIENT, Z08->Z08_LOJA, Nil, Nil) )
			// se cliente Danuri
			// TODO fazer esta parte via parâmetro
			If (Z08->Z08_CLIENT == "000547")
				// Cria arquivo EDI e envia por FTP
				U_FTPSend2( U_TEDI004(_cNumOrdSrv),;
				"103_EDI004_" + _cNumOrdSrv + ".txt",;
				"C:\TEMP\",;
				"10.3.0.211",;
				21,;
				"luminatti",;
				"7Usp8tUwat&a",;
				"/EDI/recebimento/",;
				.T.)
			EndIf
		EndIf

		// mensagem apos movimentacao, para nao bloquear transacao
		U_FtWmsMsg("Último movimento da OS: "+_cNumOrdSrv+". A OS será finalizada!", "Atenção", .F., .T.)

		// reseta variavel, caso tenha outra feirinha em coleta
		_lEncOrdSrv := .F.

	EndIf

Return _lRet

// ** funcao que realizar o processamento de enderecamento da mercadoria
Static Function sfProcEndDest(mvTipoOper, mvDevPosIni)
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z05","Z06","Z07","Z08"})
	local _aAreaTmp

	Local _lRet := .T.
	local _cItemDB := "0001"

	// variaveis temporarias
	local _aAreaZ06, _aAreaSBE
	local _aCabSDA, _aItemSDB
	local _aItemSD3, _aTmpItem
	Local _nQtdPlt

	// produtos do palete
	local _aProdPlt := {}
	local _nProd := 0

	// endereco final/definitivo
	local _lEndFinal := .F.

	// seek do Z17
	local _cSeekZ17

	// variaveis temporarias
	local _cQuery

	// tempo total
	local _nTempoTot := 0

	// indica se efetua o endereçamento ou não para endereçamento sem nota fiscal
	local _lOSEndSNF := .F.

	// retorna o proximo servico, tarefa e atividades planejada da OS
	// 1-Num OS
	// 2-Seq OS
	// 3-Cod Servico
	// 4-Dsc Servico
	// 5-Cod Tarefa
	// 6-Dsc Tarefa
	// 7-Cod Atividade
	// 8-Dsc Atividade
	// 9-Atualiza Estoque
	local _aPrxServico := U_FtPrxSrv(_cNumOrdSrv,_cSeqOrdSrv, _cCodCliMov, _cLjCliMov, Nil)

	// array de recnos
	local _aRecZ08 := {}
	// controle de loop
	local _nRecZ08 := 0, _nZ17 := 0

	// verifica se o lote eh obrigatorio na entrada da nota
	local _lLotObrEnt := U_FtWmsParam("WMS_LOTE_OBRIGATORIO_ENTRADA", "L", .F., .F., Nil, _cCodCliMov, _cLjCliMov, , Nil)

	// validação da área de armazenagem do cliente
	local _cAreaArm := U_FtWmsParam("WMS_AREA_ARMAZENAGEM_POR_CLIENTE", "C", "", .F., "", _cCodCliMov, _cLjCliMov, , Nil)

	// valida uso de logistica reversa
	local _lUsoLogRev := U_FtWmsParam("WMS_LOGISTICA_REVERSA", "L", .F. , .F., "", _cCodCliMov, _cLjCliMov, , Nil)

	// valida se o cliente permite endereçamento sem nota fiscal
	local _lEndSNF := U_FtWmsParam("WMS_ENDERECAMENTO_SEM_NF", "L", .F. , .F., "", _cCodCliMov, _cLjCliMov, , Nil)

	// variavel utilizada nas funcoes automaticas
	private lMsErroAuto := .F.

	// verifico se há mais de um registro no pallet, para movimentar junto
	_cQuery := " SELECT R_E_C_N_O_ FROM " + RetSqlTab("Z08") + " (nolock) "
	_cQuery += " WHERE " + RetSqlCond("Z08")
	_cQuery += " AND '" + _cIdPalete + "' = ( CASE WHEN Z08_NEWPLT <> '' THEN Z08_NEWPLT ELSE Z08_PALLET END ) "
	_cQuery += " AND Z08_NUMOS = '" + _cNumOrdSrv + "' "
	_cQuery += " AND Z08_SEQOS = '" + _cSeqOrdSrv + "' "
	_cQuery += " AND Z08_STATUS <> 'R' "
	_cQuery += " AND Z08_DTFINA = '' "

	// array recebe os dados para comparação
	_aRecZ08 := U_SqlToVet(_cQuery)

	// todos os registros serão movimentados
	For _nRecZ08 := 1 to Len(_aRecZ08)

		// posiciona no registro da tabela
		dbSelectArea("Z08")
		Z08->(dbGoTo( _aRecZ08[_nRecZ08] ))

		// atualiza as variáveis de armazém atual e destino
		_cArmzAtual := Z08->Z08_LOCAL
		_cArmzDesti := Z08->Z08_LOCDES
		// retorna a variável indicativa de endereço final
		_lEndFinal := .F.

		// valida se o endereco de origem é válido
		If (_lRet)
			dbSelectArea("SBE")
			SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
			If SBE->(dbSeek( xFilial("SBE")+_cArmzAtual+_cEndOrige )) .And. (SBE->BE_STATUS == "3")
				U_FtWmsMsg("O endereço de origem está bloqueado. A operação não pode ser realizada!")
				_lRet := .F.
			EndIf
		EndIf

		// valida se o endereco de destino eh valido
		If (_lRet)
			dbSelectArea("SBE")
			SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
			If SBE->(dbSeek( xFilial("SBE")+_cArmzAtual+_cEndDesti )) .And. (SBE->BE_STATUS == "3")
				U_FtWmsMsg("O endereço de destino está bloqueado. A operação não pode ser realizada!")
				_lRet := .F.
			EndIf
		EndIf

		// realiza o movimento de distribuicao
		If (_lRet)

			// posiciona na sequencia da ordem de servico
			dbSelectArea("Z06")
			Z06->(dbSetOrder(1)) //1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
			Z06->(dbSeek( xFilial("Z06") + Z08->Z08_NUMOS + Z08->Z08_SEQOS ))

			// Se o cliente for habilitado para efetuar endereçamento sem NF, e ainda não tiver NF vinculada a OS, então não efetua a transferencia de saldo
			If _lEndSNF .And. Z06->Z06_SERVIC == "015"

				dbSelectArea("Z05")
				Z05->(dbSetOrder(1))
				Z05->(dbSeek( xFilial("Z05") + Z08->Z08_NUMOS))

				_cQuery := " SELECT Count(F1_DOC) "
				_cQuery += " FROM "+RetSQLName("SF1")+" (NOLOCK) "
				_cQuery += " where D_E_L_E_T_ = '' "
				_cQuery += " and F1_FILIAL = '"+xFilial("SF1")+"' "
				_cQuery += " and F1_FORNECE = '"+Z05->Z05_CLIENT+"' "
				_cQuery += " and F1_LOJA = '"+Z05->Z05_LOJA+"' "
				_cQuery += " and SUBSTRING(F1_ZOBS,4,6) = '" + Z08->Z08_NUMOS + "' "

				If (Empty(U_FtQuery(_cQuery)))
					_lOSEndSNF := .T.
				EndIf

				If (_lOSEndSNF)
					If (_cEndDesti == Z08->Z08_ENDDES)
						// endereco final/definitivo
						_lEndFinal := .T.
					EndIf
				Endif
			EndIf

			// realiza o movimento de distribuicao SE existe NF de entrada para endereçamento (SDA)
			If (_lRet) .And. (!_lOSEndSNF)

				// se o endereco de destino definido de acordo com o tipo de equipamento eh igual ao definido no mapa
				// -- endereca a mercadoria para o endereco definido no mapa
				If (_cEndDesti == Z08->Z08_ENDDES)

					// endereco final/definitivo
					_lEndFinal := .T.

					// operacao de E-Entrada/Recebimento
					If (mvTipoOper=="E") .And. (Z06->Z06_SERVIC != "T03")

						// retorna os produtos que compoe o palete
						// 1-Cod Produto
						// 2-Num Seq
						// 3-Quantidade
						// 4-Lote
						// 5-Validade do Lote
						_aProdPlt := sfProdPalete(_cIdPalete)

						// chama o grupo de perguntas padrao da rotina MATA260
						pergunte("MTA260",.F.)

						// varre todos os produtos do palete
						For _nProd := 1 to Len(_aProdPlt)

							// posiciona nos itens a enderecar
							dbSelectArea("SDA")
							SDA->(dbOrderNickName("DA_NUMSEQ")) // 2-DA_FILIAL, DA_PRODUTO, DA_NUMSEQ

							If ! SDA->(dbSeek( xFilial("SDA")+_aProdPlt[_nProd][1]+_aProdPlt[_nProd][2] ))
								// mensagem
								U_FtWmsMsg("Erro verificando saldo SDA", "ATENCAO")
								// variavel de controle
								_lRet := .F.
								// sai do loop
								Exit
							EndIf

							// pesquisa a ultimo item utilizado
							_cItemDB := A265UltIt('C')
							// proximo item valido
							_cItemDB := Soma1(_cItemDB)

							// tratamento especifico para enderecamento no mesmo local/armazem do lancamento da nota fiscal
							If (SDA->DA_LOCAL == _cArmzDesti)

								// zera variaveis
								_aCabSDA := {}
								_aItemSDB := {}

								_aCabSDA := {;
								{"DA_FILIAL"	,SDA->DA_FILIAL ,NIL},;
								{"DA_PRODUTO"	,SDA->DA_PRODUTO,NIL},;
								{"DA_QTDORI"	,SDA->DA_QTDORI	,NIL},;
								{"DA_SALDO"		,SDA->DA_SALDO	,NIL},;
								{"DA_DATA"  	,dDataBase		,NIL},;
								{"DA_LOTECTL"	,SDA->DA_LOTECTL,NIL},;
								{"DA_DOC"		,SDA->DA_DOC	,NIL},;
								{"DA_SERIE"		,SDA->DA_SERIE	,NIL},;
								{"DA_CLIFOR"	,SDA->DA_CLIFOR	,NIL},;
								{"DA_LOJA"		,SDA->DA_LOJA	,NIL},;
								{"DA_TIPONF"	,SDA->DA_TIPONF	,NIL},;
								{"DA_NUMSEQ"	,SDA->DA_NUMSEQ	,NIL},;
								{"DA_LOCAL"		,SDA->DA_LOCAL	,NIL},;
								{"DA_ORIGEM"	,SDA->DA_ORIGEM	,NIL}}

								// item a enderecar
								Aadd(_aItemSDB,  {;
								{"DB_FILIAL"	,xFilial("SDB")	      ,NIL},;
								{"DB_ITEM"		,_cItemDB		      ,NIL},;
								{"DB_LOCAL"		,_cArmzDesti	      ,NIL},;
								{"DB_ESTORNO" 	," "			      ,Nil},;
								{"DB_LOCALIZ"	,Z08->Z08_ENDDES      ,NIL},;
								{"DB_PRODUTO"	,SDA->DA_PRODUTO      ,NIL},;
								{"DB_DOC"		,SDA->DA_DOC	      ,NIL},;
								{"DB_SERIE"		,SDA->DA_SERIE        ,NIL},;
								{"DB_NUMSEQ"	,SDA->DA_NUMSEQ	      ,NIL},;
								{"DB_DATA"	    ,dDataBase            ,NIL},;
								{"DB_QUANT"		,_aProdPlt[_nProd][3] ,NIL},;
								{"DB_ZPALLET"	,Z08->Z08_PALLET      ,NIL},;
								{"DB_ZNUMOS"	,Z08->Z08_NUMOS       ,NIL},;
								{"DB_ZSEQOS"	,Z08->Z08_SEQOS       ,NIL},;
								{"DB_ZLOTECT"	,_aProdPlt[_nProd][4] ,NIL},;
								{"DB_ZVLDLOT"	,_aProdPlt[_nProd][5] ,NIL}})

								// rotina automatica de distribuicao/enderecamento
								lMsErroAuto := .F.
								MSExecAuto({|x,y,z| mata265(x,y,z)},_aCabSDA,_aItemSDB,3) //3-Distribui

								// se deu erro, fechar rotina
								If (lMsErroAuto)
									Exit
								EndIf

								// tratamento especifico para enderecamento em local/armazem DIFERENTE do lancamento da nota fiscal
								// 1- primeiro endereca em endereco "transitorio", 2- depois transfere entre armazens
							ElseIf (SDA->DA_LOCAL != _cArmzDesti)

								// 1- primeiro endereca em endereco "transitorio"

								// zera variaveis
								_aCabSDA := {}
								_aItemSDB := {}

								// armazena area atual
								_aAreaTmp := SaveOrd({"SDA"})

								// preenche cabecalho
								_aCabSDA := {;
								{"DA_FILIAL"	,SDA->DA_FILIAL ,NIL},;
								{"DA_PRODUTO"	,SDA->DA_PRODUTO,NIL},;
								{"DA_QTDORI"	,SDA->DA_QTDORI	,NIL},;
								{"DA_SALDO"		,SDA->DA_SALDO	,NIL},;
								{"DA_DATA"  	,dDataBase		,NIL},;
								{"DA_LOTECTL"	,SDA->DA_LOTECTL,NIL},;
								{"DA_DOC"		,SDA->DA_DOC	,NIL},;
								{"DA_SERIE"		,SDA->DA_SERIE	,NIL},;
								{"DA_CLIFOR"	,SDA->DA_CLIFOR	,NIL},;
								{"DA_LOJA"		,SDA->DA_LOJA	,NIL},;
								{"DA_TIPONF"	,SDA->DA_TIPONF	,NIL},;
								{"DA_NUMSEQ"	,SDA->DA_NUMSEQ	,NIL},;
								{"DA_LOCAL"		,SDA->DA_LOCAL	,NIL},;
								{"DA_ORIGEM"	,SDA->DA_ORIGEM	,NIL}}

								// item a enderecar
								Aadd(_aItemSDB,  {;
								{"DB_FILIAL" , xFilial("SDB")      , NIL},;
								{"DB_ITEM"   , _cItemDB            , NIL},;
								{"DB_LOCAL"  , SDA->DA_LOCAL       , NIL},;
								{"DB_ESTORNO", " "                 , Nil},;
								{"DB_LOCALIZ", _cEndTransit        , NIL},;
								{"DB_PRODUTO", SDA->DA_PRODUTO     , NIL},;
								{"DB_DOC"    , SDA->DA_DOC         , NIL},;
								{"DB_SERIE"  , SDA->DA_SERIE       , NIL},;
								{"DB_NUMSEQ" , SDA->DA_NUMSEQ      , NIL},;
								{"DB_DATA"   , dDataBase           , NIL},;
								{"DB_QUANT"  , _aProdPlt[_nProd][3], NIL},;
								{"DB_ZPALLET", Z08->Z08_PALLET     , NIL},;
								{"DB_ZNUMOS" , Z08->Z08_NUMOS      , NIL},;
								{"DB_ZSEQOS" , Z08->Z08_SEQOS      , NIL},;
								{"DB_ZLOTECT", _aProdPlt[_nProd][4], NIL},;
								{"DB_ZVLDLOT", _aProdPlt[_nProd][5], NIL}})

								// rotina automatica de distribuicao/enderecamento
								lMsErroAuto := .F.
								MSExecAuto({|x,y,z| mata265(x,y,z)},_aCabSDA,_aItemSDB,3) //3-Distribui

								// se deu erro, fechar rotina
								If (lMsErroAuto)
									Exit
								EndIf

								// logo apos colocar no endereco transitorio, transferir (interno) para endereco final
								// 2- depois transfere entre armazens

								// restaura areas iniciais
								RestOrd(_aAreaTmp, .T.)

								// Atualiza arquivo de saldos em estoque
								dbSelectArea("SB2")
								SB2->(DbSetOrder(1)) // 1-B2_FILIAL, B2_COD, B2_LOCAL
								If ! SB2->(dbSeek( xFilial("SB2") + Z08->Z08_PRODUT + _cArmzDesti ))
									// cria saldo no armazem de destino
									CriaSB2(Z08->Z08_PRODUT, _cArmzDesti)
								EndIf

								// chama o grupo de perguntas padrao da rotina MATA260
								//pergunte("MTA260",.F.)

								// define o parametro "Considera Saldo poder de 3" como NAO
								mv_par03 := 2

								// zera variaveis
								_aItemSD3 := {}
								_aTmpItem := {}

								// cabecalho
								_aItemSD3 := {{NextNumero("SD3", 2, "D3_DOC", .T.), dDataBase}}

								// posiciona no cadastro de produtos
								dbSelectArea("SB1")
								SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
								SB1->(dbSeek( xFilial("SB1") + Z08->Z08_PRODUT ))

								// itens para movimentacao de transferencia
								aAdd(_aTmpItem, Z08->Z08_PRODUT      )
								aAdd(_aTmpItem, SB1->B1_DESC         )
								aAdd(_aTmpItem, SB1->B1_UM           )
								aAdd(_aTmpItem, SDA->DA_LOCAL        )
								aAdd(_aTmpItem, _cEndTransit         )
								aAdd(_aTmpItem, Z08->Z08_PRODUT      )
								aAdd(_aTmpItem, SB1->B1_DESC         )
								aAdd(_aTmpItem, SB1->B1_UM           )
								aAdd(_aTmpItem, _cArmzDesti          )
								aAdd(_aTmpItem, Z08->Z08_ENDDES      )
								aAdd(_aTmpItem, CriaVar("D3_NUMSERI"))
								aAdd(_aTmpItem, _aProdPlt[_nProd][4] )
								aAdd(_aTmpItem, CriaVar("D3_NUMLOTE"))
								aAdd(_aTmpItem, _aProdPlt[_nProd][5] )
								aAdd(_aTmpItem, 0                    )
								aAdd(_aTmpItem, _aProdPlt[_nProd][3] )
								aAdd(_aTmpItem, 0                    )
								aAdd(_aTmpItem, CriaVar("D3_ESTORNO"))
								aAdd(_aTmpItem, CriaVar("D3_NUMSEQ") )
								aAdd(_aTmpItem, _aProdPlt[_nProd][4] )
								aAdd(_aTmpItem, _aProdPlt[_nProd][5] )
								aAdd(_aTmpItem, CriaVar("D3_SERVIC") )
								aAdd(_aTmpItem, CriaVar("D3_ITEMGRD"))
								If (SD3->(FieldPos("D3_IDDCF")) > 0)
									aAdd(_aTmpItem, CriaVar("D3_IDDCF"))
								EndIf
								If (SD3->(FieldPos("D3_OBSERVA")) > 0)
									aAdd(_aTmpItem, CriaVar("D3_OBSERVA"))
								EndIf
								aAdd(_aTmpItem, Z08->Z08_NUMOS       )
								aAdd(_aTmpItem, Z08->Z08_SEQOS       )
								aAdd(_aTmpItem, Z08->Z08_PALLET      )
								aAdd(_aTmpItem, Z05->Z05_CARGA       )
								aAdd(_aTmpItem, ""                   )
								aAdd(_aTmpItem, ""                   )

								// adiciona o item
								aAdd(_aItemSD3, _aTmpItem)

								// variaveis padroes da rotina automatica
								lMsHelpAuto := .T.
								lMsErroAuto := .F.

								// executa rotina automatica
								MsExecAuto({|x,y|MATA261(x,y)},_aItemSD3,3) // 3-transferencia

								If (lMsErroAuto)
									//Exit
								EndIf

							EndIf

						Next _nProd

						// operacao de S-Saida/Expedicao OU I-Interna (Transferencias) OU T03 (cancelamento de carregamento)
					ElseIf (mvTipoOper=="S") .Or. (mvTipoOper=="I") .Or. ( (mvTipoOper=="E") .And. (Z06->Z06_SERVIC == "T03") )

						// area atual
						_aAreaZ06 := Z06->(GetArea())
						_aAreaSBE := SBE->(GetArea())

						// verifica se deve movimentar mercadoria / nota fiscal ja liberada
						If (Z06->Z06_ATUEST == "S")

							// retorna os produtos que compoe o palete
							// 1-Cod Produto
							// 2-Num Seq
							// 3-Quantidade
							// 4-Lote
							// 5-Validade do Lote
							_aProdPlt := sfProdPalete(_cIdPalete)

							// chama o grupo de perguntas padrao da rotina MATA260
							//pergunte("MTA260",.F.)

							// define o parametro "Considera Saldo poder de 3" como NAO
							mv_par03 := 2

							// zera variaveis
							_aItemSD3 := {}
							_aTmpItem := {}
							_nQtdPlt  := 0

							// cabecalho
							_aItemSD3 := {{NextNumero("SD3",2,"D3_DOC",.T.),dDataBase}}

							// posiciona no cadastro de produtos
							dbSelectArea("SB1")
							SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
							SB1->(dbSeek( xFilial("SB1")+Z08->Z08_PRODUT ))

							// itens para movimentacao de transferencia
							aAdd(_aTmpItem, Z08->Z08_PRODUT      )
							aAdd(_aTmpItem, SB1->B1_DESC         )
							aAdd(_aTmpItem, SB1->B1_UM           )
							aAdd(_aTmpItem, _cArmzAtual          ) // estou considerando o campo Z08_LOCAL
							aAdd(_aTmpItem, Z08->Z08_ENDORI      )
							aAdd(_aTmpItem, Z08->Z08_PRODUT      )
							aAdd(_aTmpItem, SB1->B1_DESC         )
							aAdd(_aTmpItem, SB1->B1_UM           )
							aAdd(_aTmpItem, _cArmzDesti          ) // estou considerando o novo campo Z08_LOCDES
							aAdd(_aTmpItem, Z08->Z08_ENDDES      )
							aAdd(_aTmpItem, CriaVar("D3_NUMSERI"))
							aAdd(_aTmpItem, _aProdPlt[1][4]      )
							aAdd(_aTmpItem, CriaVar("D3_NUMLOTE"))
							aAdd(_aTmpItem, _aProdPlt[1][5]      )
							aAdd(_aTmpItem, 0                    )
							If ( (mvTipoOper == "E") .And. (Z06->Z06_SERVIC == "T03") )  //se for cancelamento, tem que pegar da conferencia
							AEval(_aProdPlt, { |x| _nQtdPlt += x[3] })
							aAdd(_aTmpItem, _nQtdPlt )
							Else      //senão, considera quantidade da Z08 para outros serviços
								aAdd(_aTmpItem, Z08->Z08_QUANT       )
							EndIf
							aAdd(_aTmpItem, 0                    )
							aAdd(_aTmpItem, CriaVar("D3_ESTORNO"))
							aAdd(_aTmpItem, CriaVar("D3_NUMSEQ") )
							aAdd(_aTmpItem, _aProdPlt[1][4]      )
							aAdd(_aTmpItem, _aProdPlt[1][5]      )
							aAdd(_aTmpItem, CriaVar("D3_SERVIC") )
							aAdd(_aTmpItem, CriaVar("D3_ITEMGRD"))
							If (SD3->(FieldPos("D3_IDDCF")) > 0)
								aAdd(_aTmpItem, CriaVar("D3_IDDCF"))
							EndIf
							If (SD3->(FieldPos("D3_OBSERVA")) > 0)
								aAdd(_aTmpItem, CriaVar("D3_OBSERVA"))
							EndIf
							aAdd(_aTmpItem, Z08->Z08_NUMOS       )
							aAdd(_aTmpItem, Z08->Z08_SEQOS       )
							aAdd(_aTmpItem, _cIdPalete           )
							aAdd(_aTmpItem, Z05->Z05_CARGA       )
							aAdd(_aTmpItem, ""                   )
							aAdd(_aTmpItem, ""                   )

							// adiciona o item
							aAdd(_aItemSD3, _aTmpItem)

							// variaveis padroes da rotina automatica
							lMsHelpAuto := .T.
							lMsErroAuto := .F.

							// Atualiza arquivo de saldos em estoque
							dbSelectArea("SB2")
							SB2->(DbSetOrder(1)) // 1-B2_FILIAL, B2_COD, B2_LOCAL
							If ! SB2->(dbSeek( xFilial("SB2") + Z08->Z08_PRODUT + _cArmzDesti ))
								// cria saldo no armazem de destino
								CriaSB2(Z08->Z08_PRODUT, _cArmzDesti)
							EndIf

							// executa rotina automatica
							MsExecAuto({|x,y|MATA261(x,y)},_aItemSD3,3) // 3-transferencia

							If (lMsErroAuto)
								//alert("deu erro")
							EndIf

						EndIf

						// libera o novo item da OS para execucao
						If (Len(_aPrxServico) > 0)

							dbSelectArea("Z06")
							Z06->(dbSetOrder(1)) //1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
							If Z06->(dbSeek( xFilial("Z06")+_cNumOrdSrv+_aPrxServico[1,2] ))
								// soh habilita quando o servico esta planejado
								If (Z06->Z06_STATUS=="PL")
									RecLock("Z06")
									Z06->Z06_DTEMIS := Date()
									Z06->Z06_HREMIS := Time()
									Z06->Z06_STATUS := "AG"
									Z06->Z06_ENDSRV	:= Z08->Z08_ENDDES
									Z06->(MsUnLock())
								EndIf

							EndIf

						EndIf

						// restaura area atual
						RestArea(_aAreaZ06)
						RestArea(_aAreaSBE)

					EndIf

					// se deu erro na atualizacao
					If (lMsErroAuto)
						// apresenta mensagem com o error.log
						U_FtWmsMsg(sfAchaErro(),"ATENCAO")
						// variavel de retorno
						_lRet := .F.
					EndIf

					// -- se for diferente, deixa o palete disponivel para a outra maquina
				ElseIf (_cEndDesti != Z08->Z08_ENDDES)

					// somente nos casos que NAO for devolucao da mercadoria apos fracionar paletes
					If ( ! mvDevPosIni)
						dbSelectArea("Z08")
						RecLock("Z08")
						Z08->Z08_STATUS := "P" // P-Planejado / R-Realizado / M-Movimento / E-Erro
						Z08->Z08_ENDSRV := _cEndDesti
						Z08->Z08_ENDTRA := IIF(Empty(Z08->Z08_ENDTRA),_cEndDesti,Z08->Z08_ENDTRA)
						Z08->Z08_USUARIO := __cUserId
						Z08->Z08_EQUIPA  := _cCodEquip
						Z08->(MsUnLock())
					EndIf

					// atualiza o status do palete para D-DISPONIVEL
					If (_lOSRec)
						_cQuery := "UPDATE "+RetSqlName("Z07")+" "
						_cQuery += "SET Z07_STATUS = 'D', "
						_cQuery += "Z07_ENDATU = '"+_cEndDesti+"' "
						// filtros
						_cQuery += "WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
						_cQuery += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' "
						_cQuery += "AND Z07_PALLET = '"+_cIdPalete+"' "
						_cQuery += "AND Z07_STATUS = 'M' "

						// executa o update
						TcSQLExec(_cQuery)
					EndIf

				EndIf
			EndIf
		Endif
		// se for uma armazenagem de recebimento sem NF, e for uma movimentação de PE para a rua
		// atualiza a finalização do movimento
		If (_lOSRec .AND. (_lEndSNF .AND. _lOSEndSNF) .AND. _cEndDesti == Z08->Z08_ENDTRA)

			// atualiza o status da Z08 para Pendente
			dbSelectArea("Z08")
			RecLock("Z08")
			Z08->Z08_STATUS := "P" // P-Planejado / R-Realizado / M-Movimento / E-Erro
			Z08->Z08_ENDSRV := _cEndDesti
			Z08->Z08_ENDTRA := IIF(Empty(Z08->Z08_ENDTRA),_cEndDesti,Z08->Z08_ENDTRA)
			Z08->Z08_USUARIO := __cUserId
			Z08->Z08_EQUIPA  := _cCodEquip
			Z08->(MsUnLock())

			// atualiza o status do palete para D-DISPONIVEL
			_cQuery := "UPDATE "+RetSqlName("Z07")+" "
			_cQuery += "SET Z07_STATUS = 'D', "
			_cQuery += "Z07_ENDATU = '"+_cEndDesti+"' "
			// filtros
			_cQuery += "WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
			_cQuery += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' "
			_cQuery += "AND Z07_PALLET = '"+_cIdPalete+"' "
			_cQuery += "AND Z07_STATUS = 'M' "
			// executa o update
			TcSQLExec(_cQuery)
		EndIf

		// se enderecou, atualiza dados do mapa
		If (_lRet)

			// atualiza dados finais da movimentação dos pallets principais e dos pallets fracionados
			// passa duas vezes pra considerar os dois tipos de pallets
			For _nZ17 := 1 to 2
				dbSelectArea("Z17")
				Z17->(dbSetOrder(1)) // 1-Z17_FILIAL, Z17_ETQPLT
				Z17->(dbSeek( _cSeekZ17 := xFilial("Z17") + Iif(_nZ17 == 1, _cIdPalete, Z08->Z08_NEWPLT) ))

				// compara o numero da OS
				While Z17->(!Eof()) .And. (Z17->(Z17_FILIAL+Z17_ETQPLT)==_cSeekZ17)

					// verifica OS, Data, Status e operador
					If (Z17->Z17_NUMOS == Z08->Z08_NUMOS) .And. (Z17->Z17_SEQOS == Z08->Z08_SEQOS).And.;
					(Empty(Z17->Z17_DTFIM)) .And. (Z17->Z17_STATUS == "M") .And. (Z17->Z17_OPERAD == _cCodOper)

						RecLock("Z17")
						// define o endereço de destino - END_DES_Z17 - David 10/03/16
						If (Empty(Z17->Z17_ENDDES))
							Z17->Z17_ENDDES := Iif(Empty(_cEndDesti), Z08->Z08_ENDDES, _cEndDesti)
						EndIf

						// define o tipo de movimento realizado baseado no registro já gerado da Z17
						Z17->Z17_TIPMOV := sfRetTpMov(Z17->Z17_ENDORI, Z17->Z17_ENDDES, Z17->Z17_LOCORI, Z17->Z17_LOCDES)

						// data e hora final
						Z17->Z17_DTFIM  := Date()
						Z17->Z17_HRFIM  := Time()
						Z17->Z17_STATUS := "R" // R=Realizado / C=Cancelado / M=Em Movimento

						// calcula o tempo da operacao (retorno em centesimal)
						_nTempoTot := A680Tempo(Z17->Z17_DTINI,;
						Left(Z17->Z17_HRINI,5),;
						Z17->Z17_DTFIM,;
						Left(Z17->Z17_HRFIM,5) )

						// converte para horas normais
						_nTempoTot := fConvHr(_nTempoTot,"H")

						// tempo total
						Z17->Z17_TEMPO := _nTempoTot

						Z17->(MsUnLock())
					EndIf
					// proximo item
					Z17->(dbSkip())
				EndDo
			Next _nZ17

			// para os casos de transferencia, atualiza o armazém também mas só na última movimentação
			// atualiza o novo endereco do palete
			U_FtEndPlt(_cIdPalete, _cEndOrige, _cEndDesti, _cArmzAtual, /*mvCodProd*/, /*mvSaldo*/, IIF( _lEndFinal, _cArmzDesti, _cArmzAtual) )

			// se enderecou para endereco final/definitivo, finaliza item do mapa
			If (_lEndFinal)

				// para OS internas / OS Entrada
				// estou validando após o fluxo normal da rotina visto que as validações de novo endereço são muitas
				// estou usando _nRecZ08 == Len(_aRecZ08) para validar se no laço o movimento corrente é o último do pallet
				If (mvTipoOper $ "E/I")
					If ( ! sfAgrPltEnd(_cEndDesti, _cIdPalete, (_nRecZ08 == Len(_aRecZ08)) ) )
						U_FtWmsMsg("Erro ao gravar dados do novo pallet no endereço de destino.","ATENÇÃO")
						Return(.F.)
					EndIf
				EndIf

				// finaliza registro na Z08
				dbSelectArea("Z08")
				RecLock("Z08")
				Z08->Z08_STATUS  := "R" // P-Planejado / R-Realizado / M-Movimento / E-Erro
				Z08->Z08_ENDSRV  := _cEndDesti
				Z08->Z08_USUARIO := __cUserId
				Z08->Z08_EQUIPA  := _cCodEquip
				// caso o campo de data não estiver preenchido, preenche com as informações do inicio da movimentação
				If ( Empty(Z08->Z08_DTINIC) )
					Z08->Z08_DTINIC := _cDtIni
					Z08->Z08_HRINIC := _cHrIni
				EndIf
				Z08->Z08_DTFINA  := Date()
				Z08->Z08_HRFINA  := Time()
				If (_lEndSNF .AND. _lOSEndSNF)
					Z08->Z08_TPESTO := "000023"
				Endif
				Z08->(MsUnLock())
				
				If (_lEndSNF .AND. _lOSEndSNF)
				DbSelectArea("Z16")
				Z16->(dbSetOrder(1)) // 1-Z16_FILIAL, Z16_ETQPAL, R_E_C_N_O_, D_E_L_E_T_
				If (Z16->(dbSeek(xFilial("Z16") + _cIdPalete )))
					While Z16->Z16_ETQPAL == _cIdPalete .AND. !Z16->(Eof())
						RecLock("Z16",.F.)
						Z16->Z16_TPESTO := "000023"
						Z16->(MsUnlock())
						Z16->(DbSkip())
					Enddo
				Endif
				Endif

				// Se for Conferência sem NF bloqueia o endereço que será usado para armazenar
				If (_lEndSNF .AND. _lOSEndSNF)
					dbSelectArea("SBE")
					dbSetOrder(1) //BE_FILIAL, BE_LOCAL, BE_LOCALIZ, BE_ESTFIS
					If dbSeek(xFilial("SBE")+_cArmzAtual+_cEndDesti)
						RecLock("SBE",.F.)
						SBE->BE_STATUS	:= "3" //Bloqueio de Endereço
						MsUnLock()
					EndIf
				EndIf

				// atualiza o status do palete para A-ARMAZENADO
				If (_lOSRec)
					_cQuery := " UPDATE "+RetSqlName("Z07")
					_cQuery += " SET Z07_STATUS = 'A', "
					_cQuery += " Z07_ENDATU = '"+_cEndDesti+"' "
					// filtros
					_cQuery += " WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
					_cQuery += " AND Z07_NUMOS  = '"+_cNumOrdSrv+"' " //AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
					_cQuery += " AND Z07_PALLET = '"+_cIdPalete+"' "
					_cQuery += " AND Z07_STATUS = 'M' "
					// executa o update
					TcSQLExec(_cQuery)
				EndIf

			EndIf

			// realiza o cancalemto do movimento
		ElseIf ( ! _lRet)

			// chama funcao para relizar o cancelamento da movimentacao
			sfExCancMov( Z08->(RecNo()) ,;
			_cCodOper )

		EndIf
	Next _nRecZ08

	// controle de transacao para finalizar a OS
	If (_lRet)
		// valido se pode finalizar a OS na Z06 e aviso o usuário
		_cQuery := " SELECT COUNT(*) QTD_REG FROM " + RetSqlTab("Z08") + " (nolock) "
		_cQuery += " WHERE "+RetSqlCond("Z08")
		_cQuery += " AND Z08_NUMOS = '"+_cNumOrdSrv+"'"
		_cQuery += " AND Z08_SEQOS = '"+_cSeqOrdSrv+"'"
		_cQuery += " AND Z08_STATUS <> 'R' "

		// caso não tenha encontrado nenhum registro diferente de realizado avisa que irá finalizar a OS.
		If (U_FtQuery(_cQuery) == 0)

			If Select("tZ07Z08") > 0
				DBSelectArea("tZ07Z08")
				tZ07Z08->(DBCloseArea())
			EndIf

			cQuery := " SELECT (SELECT COUNT(DISTINCT(Z07_PALLET)) QTD "
			cQuery += " FROM "+RetSQLName("Z07")+" (NOLOCK) "
			cQuery += " WHERE D_E_L_E_T_ = '' "
			cQuery += " AND Z07_FILIAL = '"+xFilial("Z07")+"' "
			cQuery += " AND Z07_NUMOS = '"+_cNumOrdSrv+"' "
			cQuery += " AND Z07_SEQOS = '001') as Z07, "
			cQuery += " (SELECT COUNT(*) QTD "
			cQuery += " FROM "+RetSQLName("Z08")+" (NOLOCK) "
			cQuery += " WHERE D_E_L_E_T_ = '' "
			cQuery += " AND Z08_FILIAL = '"+xFilial("Z08")+"' "
			cQuery += " AND Z08_NUMOS = '"+_cNumOrdSrv+"' "
			cQuery += " AND Z08_SEQOS = '002') AS Z08 "

			TCQuery cQuery NEW ALIAS "tZ07Z08"

			DBSelectArea("tZ07Z08")
			tZ07Z08->(DBGoTop())

			if !tZ07Z08->(EOF())
				If tZ07Z08->Z07 > tZ07Z08->Z08
					U_FtWmsMsg("O número de pallets montados é maior que número de endereços reservados. Informe novos endereços.","ATENÇÃO")

					// posiciona na OS
					dbSelectArea("Z05")
					Z05->(dbSetOrder(1)) //1-Z05_FILIAL, Z05_NUMOS
					Z05->(dbSeek( xFilial("Z05")+_cNumOrdSrv ))

					U_sfGeraMapa( .T. , {_cNumOrdSrv,_cSeqOrdSrv,_cCodCliMov,_cLjCliMov,Z05->Z05_CESV,_lLotObrEnt,_cMaskQuant,_cAreaArm,_lUsoLogRev} )

					// controle para não encerrar ordem de servico
					_lEncOrdSrv := .F.

				Else
					// status atual da OS
					_cCodStatus := Posicione("Z06", 1, xFilial("Z06") + _cNumOrdSrv + _cSeqOrdSrv, "Z06_STATUS")
					// controle para encerrar ordem de servico
					_lEncOrdSrv := .T.
				EndIf
			EndIf
		EndIf
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aArea)

Return(_lRet)

// ** funcao que permite alterar o endereco de destino
Static Function sfTrocaDest(mvColsEnd,mvObjBrowse)
	// controle de validacaoes
	local _lVldNewEnd := .F.
	local _lVldCodMot := .F.
	// variavel de retorno
	local _lRet := .T.
	local _cNewIdEnder := Space(_nTamIdEtq)
	local _cNewEnderec := ""
	//local _cNewEstru :=
	local _cCodMotivo := Space(3)
	// armazem de destino
	local _cNewLocal := ""

	// objetos
	local _oSayNewEndTit, _oSayMotivo, _oSayNewEnd
	local _oGetMotivo

	// monta a tela para informar o novo endereco
	_oWndNewEnder := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Novo Endereço",,,.F.,,,,,,.T.,,,.T. )
	_oWndNewEnder:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlNewEndCab := TPanel():New(000,000,nil,_oWndNewEnder,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlNewEndCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpNewEndOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _oWndNewEnder:End() },_oPnlNewEndCab,"Confirmar",,.T.)
	_oBmpNewEndOk:Align := CONTROL_ALIGN_LEFT
	// -- SAIR
	_oBmpNewEndSair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _oWndNewEnder:End() },_oPnlNewEndCab,"Sair",,.T.)
	_oBmpNewEndSair:Align := CONTROL_ALIGN_RIGHT

	// titulo
	_oSayNewEndTit := TSay():New(025,000,{||"    Troca de Endereço"},_oWndNewEnder,,_oFnt03,.F.,.F.,.F.,.T.,CLR_WHITE,CLR_BLACK,120,12,,,,,,.T.)

	// confirmacao do do novo endereco de destino
	_oSayNewEnd := TSay():New(045,005,{||"Confirme o endereço:"},_oWndNewEnder,,,.F.,.F.,.F.,.T.)
	_oGetNewEnd := TGet():New(043,060,{|u| If(PCount()>0,_cNewIdEnder:=u,_cNewIdEnder)},_oWndNewEnder,050,010,_cMskEtiq,{|| _lVldNewEnd := sfVldNewEndereco(@_cNewLocal,_cNewIdEnder,@_cNewEnderec) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNewIdEnder",,)

	// motivo de troca de endereco
	_oSayMotivo := TSay():New(060,005,{||"Motivo da Troca:"},_oWndNewEnder,,,.F.,.F.,.F.,.T.)
	_oGetMotivo := TGet():New(058,060,{|u| If(PCount()>0,_cCodMotivo:=u,_cCodMotivo)},_oWndNewEnder,020,010,"@R 999",{|| _lVldCodMot := sfVldMotivo(_cCodMotivo) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cCodMotivo",,)

	// foco para confirmar o endereco
	_oGetNewEnd:SetFocus()

	// ativa a tela
	_oWndNewEnder:Activate(,,,.F.,,,)

	// se houve a troca, atualiza variaveis
	If (_lRet := ((!Empty(_cNewIdEnder)) .And. (!Empty(_cCodMotivo)) .And. (_lVldNewEnd) .And. (_lVldCodMot)))
		// atualiza novo endereco
		mvColsEnd := aClone(U_FtCfgEnd(_cEndDesti, _cNewLocal))
		// atualiza os dados do browse
		mvObjBrowse:aCols := aClone(mvColsEnd)
		mvObjBrowse:Refresh()
		// atualiza o ID da etiqueta do endereco
		_cIdEndere := _cNewIdEnder
		// atualiza a variavel do endereco de destino
		_cEndDesti  := _cNewEnderec
		// atualiza o registro do Z08
		dbSelectArea("Z08")
		RecLock("Z08")
		Z08->Z08_OLDLOC := Z08->Z08_LOCAL
		Z08->Z08_OLDEND := Z08->Z08_ENDDES
		Z08->Z08_LOCAL  := _cNewLocal
		Z08->Z08_ENDDES := _cNewEnderec
		Z08->Z08_MOTTRC	:= _cCodMotivo
		If (!Empty(Z08->Z08_ENDTRA))
			Z08->Z08_ENDTRA	:= _cNewEnderec
		EndIf
		Z08->(MsUnLock())
	EndIf

Return(_lRet)

// ** funcao que valida o novo endereco
Static Function sfVldNewEndereco(mvNewLocal,mvIdNewEnd,mvNewEnderec)
	// variavel de retorno
	local _lRet := .T.
	// saldo do endereco
	local _nSaldoSBF := 0

	// quando for vazio, retornar verdadeiro
	If (_lRet) .And. (Empty(mvIdNewEnd))
		Return(_lRet)
	EndIf

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11")+mvIdNewEnd ))
			U_FtWmsMsg("Identificador do endereço inválido!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// valida o tipo da etiqueta lida
	If (_lRet)
		If (Z11->Z11_TIPO != "02")
			U_FtWmsMsg("Tipo de etiqueta inválida!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// valida a existencia do endereco
	If (_lRet)
		// posiciona no cadastro do endereco
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
		If ! SBE->(dbSeek( xFilial("SBE")+Z11->Z11_LOCAL+Z11->Z11_ENDERE ))
			U_FtWmsMsg("Endereço não encontrado!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// verifica se o endereco esta bloqueado
	If (_lRet)
		If (SBE->BE_STATUS == '3')
			U_FtWmsMsg("Endereço bloqueado para uso!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// valida se o endereco esta vazio, somente se for porta palete
	If (_lRet) .And. (Len(AllTrim(Z11->Z11_ENDERE)) > 6)

		// verifica o saldo do endereco de destino
		_nSaldoSBF := QuantSBF(Z11->Z11_LOCAL, Z11->Z11_ENDERE) //SaldoSBF(Z11->Z11_LOCAL, Z11->Z11_ENDERE, mvProduto,NIL,NIL,NIL,.F.,SBE->BE_ESTFIS)

		// calculo do saldo por endereco, considerando servicos a executar
		U_ConSldRF(Z11->Z11_LOCAL, Z11->Z11_ENDERE, Nil, @_nSaldoSBF)

		// se o endereco ja possuir saldo, tenta outro endereco
		If (_nSaldoSBF > 0)
			// proximo endereco
			U_FtWmsMsg("Endereço ocupado ou reservado!","ATENCAO")
			_lRet := .F.
		EndIf

	EndIf

	// atualiza novo endereco
	If (_lRet)
		// atualiza novo local/armazem
		mvNewLocal   := SBE->BE_LOCAL
		// endereco
		mvNewEnderec := SBE->BE_LOCALIZ
	EndIf

Return(_lRet)

// ** funcao que valida o motivo da troca de endereco
Static Function sfVldMotivo(mvCodMotivo)
	local _lRet := .T.

	// quando for vazio, retornar verdadeiro
	If (_lRet) .And. (Empty(mvCodMotivo))
		Return(_lRet)
	EndIf

	// valida se o codigo do motivo existe
	If (_lRet) .And. (!Empty(mvCodMotivo))
		//U_FtWmsMsg("Favor informar o motivo da troca!","ATENCAO")
		//_lRet := .F.
	EndIf

Return(_lRet)

// ** funcao que pesquisa o palete pela etiquetad do produto
Static Function sfRetNrPalete(mvIdEtqPrd, mvTpEtq)
	local _cRetIdPal := Space(Len(mvIdEtqPrd))
	local _cQryPlt

	// nesse momento eu gravo a etiqueta lida, pois depois ela vai se tornar a etiqueta de pallet
	_cIdEtiqLida := _cIdEtiqueta

	// prepara query
	_cQryPlt := " SELECT DISTINCT Z16_ETQPAL "
	// composicao de palete
	_cQryPlt += " FROM " + RetSqlTab("Z16") + " (nolock) "
	// filtro padrao
	_cQryPlt += " WHERE " + RetSqlCond("Z16")

	// valida o tipo da etiqueta
	// 01 =  Produto | 04 = Agrupadora

	// Produto
	If (mvTpEtq == "01")
		_cQryPlt += " AND Z16_ETQPRD = '" + mvIdEtqPrd + "' "
		// Agrupadora
	ElseIf (mvTpEtq == "04")
		_cQryPlt += " AND Z16_ETQVOL = '" + mvIdEtqPrd + "' "
		// etiqueta do cliente
	ElseIf (mvTpEtq == "07")
		_cQryPlt += " AND Z16_ETQCLI = '" + mvIdEtqPrd + "' "
	Else
		_cQryPlt += " AND (1 = 0) "
	EndIf

	// saldo na Z16 tem que ser maior que zero
	_cQryPlt += " AND Z16_SALDO != 0 "

	memowrit("c:\query\twmsa011_sfRetNrPalete.txt", _cQryPlt)

	// executa a query
	_cRetIdPal := U_FtQuery(_cQryPlt)

	If (Empty(_cRetIdPal))
		U_FtWmsMsg("Etiqueta não encontrada!","ATENCAO")
	EndIf

Return(_cRetIdPal)

// ** funcao para iniciar uma movimentacao de mercadoria
Static Function sfInicMovim(mvQryUsr)
	// controle de confirmacao da tela
	local _lFixaWnd := .F.
	// variavel de retorno
	local _lRet := .F.
	// objetos locais
	local _oWndInicMov
	local _oPnInMvCb, _oPnInMvRd
	local _oPnInMvFld
	local _oBmpInicMSair, _oBmpOpcoes, _oBmpRefresh
	local _oGetIdEtiq
	local _oFldPltDisp
	local _oBrwPltRec, _oBrwPltExp, _oBrwPltInt
	// sub-menu
	local _oMnuOpcoes := nil
	local _oSbMnOpc1 := nil
	local _oSbMnOpc2 := nil
	local _oSbMnOpc3 := nil

	// pastas do FOLDER
	local _aFolders := {'Receb.','Exped.','Transf.'}

	// posicao da coluna do endereco de servico
	local _nPosEndSrv := 0

	// temporizador/Refresh da tela (7 segundos)
	local _oTimerRefresh

	// variaveis para o browse de palete disponiveis para RECEBIMENTO
	Private _cAlPltRec  := GetNextAlias()
	Private _cTrPltRec
	Private _aStPltRec  := {}
	Private _aHdPltRec  := {}
	Private _aCorPltRec := {}

	// variaveis para o browse de palete disponiveis para EXPEDICAO
	Private _cAlPltExp  := GetNextAlias()
	Private _cTrPltExp
	Private _aStPltExp  := {}
	Private _aHdPltExp  := {}
	Private _aCorPltExp := {}

	// variaveis para o browse de palete disponiveis para TRANSFERENCIAS
	Private _cAlPltInt  := GetNextAlias()
	Private _cTrPltInt
	Private _aStPltInt  := {}
	Private _aHdPltInt  := {}
	Private _aCorPltInt := {}

	// -- estrutura do TRB - Recebimento
	aAdd(_aStPltRec,{"REC_COR"    ,"C",  3,0})
	aAdd(_aStPltRec,{"REC_RUA"    ,"C",  2,0})
	aAdd(_aStPltRec,{"REC_ENDORI" ,"C", 16,0})
	aAdd(_aStPltRec,{"REC_QTD"    ,"N", TamSx3("C6_QTDVEN")[1] ,TamSx3("C6_QTDVEN")[2]})
	aAdd(_aStPltRec,{"REC_ORDEM"  ,"C", TamSx3("BE_LOCALIZ")[1] ,0})
	
	

	// cria arquivo de trabalho
	_cTrPltRec := FWTemporaryTable():New( _cAlPltRec )
	_cTrPltRec:SetFields( _aStPltRec )
	_cTrPltRec:AddIndex("01", {"REC_ORDEM"} )
	_cTrPltRec:Create()

	// define header - recebimento
	aAdd(_aHdPltRec,{"REC_ENDORI" ,"","End.Orig."})
	// não utilizar mascará pois estou o tamanho do campo na tela do coletor
	aAdd(_aHdPltRec,{"REC_QTD"    ,"","Quant."})

	// define cores da legenda do browse
	aAdd(_aCorPltRec,{"(_cAlPltRec)->REC_COR == 'RUA'","BR_AZUL"    })
	aAdd(_aCorPltRec,{"(_cAlPltRec)->REC_COR == 'FRA'","BR_VERMELHO"})
	aAdd(_aCorPltRec,{"(_cAlPltRec)->REC_COR == 'TOT'","BR_VERDE"   })

	// -- estrutura do TRB - Expedicao
	aAdd(_aStPltExp,{"EXP_COR"    ,"C",  3,0})
	aAdd(_aStPltExp,{"EXP_RUA"    ,"C",  2,0})
	aAdd(_aStPltExp,{"EXP_ENDORI" ,"C", 16,0})
	aAdd(_aStPltExp,{"EXP_QTD"    ,"N", TamSx3("C6_QTDVEN")[1] ,TamSx3("C6_QTDVEN")[2]})
	aAdd(_aStPltExp,{"EXP_ORDEM"  ,"C", TamSx3("BE_LOCALIZ")[1] ,0})

	// cria arquivo de trabalho
	_cTrPltExp := FWTemporaryTable():New( _cAlPltExp )
	_cTrPltExp:SetFields( _aStPltExp )
	_cTrPltExp:AddIndex("01", {"EXP_ORDEM"} )
	_cTrPltExp:Create()

	// define header - expedicao
	aAdd(_aHdPltExp,{"EXP_ENDORI" ,"","End.Orig."})
	// não utilizar mascará pois estou o tamanho do campo na tela do coletor
	aAdd(_aHdPltExp,{"EXP_QTD"    ,"","Quant."})

	// define cores da legenda do browse
	aAdd(_aCorPltExp,{"(_cAlPltExp)->EXP_COR == 'RUA'","BR_AZUL"  })
	aAdd(_aCorPltExp,{"(_cAlPltExp)->EXP_COR == 'FRA'","BR_PRETO" })
	aAdd(_aCorPltExp,{"(_cAlPltExp)->EXP_COR == 'TOT'","BR_VERDE" })

	// -- estrutura do TRB - Internas
	aAdd(_aStPltInt,{"INT_DIRECA" ,"C",  3,0})
	aAdd(_aStPltInt,{"INT_RUA"    ,"C",  2,0})
	aAdd(_aStPltInt,{"INT_ENDORI" ,"C", 16,0})
	aAdd(_aStPltInt,{"INT_ENDDES" ,"C", 16,0})
	aAdd(_aStPltInt,{"INT_QTD"    ,"N", TamSx3("C6_QTDVEN")[1] ,TamSx3("C6_QTDVEN")[2]})
	aAdd(_aStPltInt,{"INT_ORDEM"  ,"C", 3 + TamSx3("BE_LOCALIZ")[1] ,0})

	// cria arquivo de trabalho
	_cTrPltInt := FWTemporaryTable():New( _cAlPltInt )
	_cTrPltInt:SetFields( _aStPltInt )
	_cTrPltInt:AddIndex("01", {"INT_ORDEM"} )
	_cTrPltInt:Create()

	// define header - Internas
	aAdd(_aHdPltInt,{"INT_ENDORI" ,"","End.Orig."})
	// não utilizar mascará pois estou o tamanho do campo na tela do coletor
	aAdd(_aHdPltInt,{"INT_QTD"    ,"","Quant."})

	// define cores da legenda do browse
	aAdd(_aCorPltInt,{"(_cAlPltInt)->INT_DIRECA == 'ARM'","WMS_MOV_ARM"})
	aAdd(_aCorPltInt,{"(_cAlPltInt)->INT_DIRECA == 'BAI'","WMS_MOV_BAI"})
	aAdd(_aCorPltInt,{"(_cAlPltInt)->INT_DIRECA == 'TRA'","WMS_MOV_TRA"})

	// zera variaveis
	_cNumOrdSrv := ""
	_cSeqOrdSrv := ""
	_cTipoOper  := ""

	// status da OS
	mvQryUsr += " AND Z06_STATUS = 'EX' "
	// filtra se o operador eh recurso da OS
	mvQryUsr += " AND " + cQryUsrZ18

	// complementa a ordem dos dados
	mvQryUsr += "ORDER BY Z06_PRIOR, Z05_NUMOS"

	memowrit("C:\query\twmsa011_sfInicMovim.txt",mvQryUsr)

	//=================


	// apresenta tela para selecionar um palete/endereço
	_oWndInicMov := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Movim.Mercadoria",,,.F.,,,,,,.T.,,,.T. )
	_oWndInicMov:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnInMvCb := TPanel():New(000,000,nil,_oWndInicMov,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnInMvCb:Align:= CONTROL_ALIGN_TOP

	// -- REFRESH
	_oBmpRefresh := TBtnBmp2():New(000,000,040,040,"RELOAD",,,,{|| sfAtuDados(mvQryUsr, (_cAlPltRec), (_cAlPltExp), (_cAlPltInt), @_oGetIdEtiq) },_oPnInMvCb,"Atualizar",,.T.)
	_oBmpRefresh:Align := CONTROL_ALIGN_LEFT


	// sub-itens do menus
	_oMnuOpcoes := TMenu():New(0,0,0,0,.T.)
	// adiciona itens no Menu

	// -- FILTRAR RUAS DISPONIVEIS
	_oSbMnOpc1 := TMenuItem():New(_oPnInMvCb,"Filtrar Rua",,,,{|| sfFiltroRua(),_oBmpRefresh:Click() },,"FILTRO",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc1)

	// -- CONSULTAR FEIRINHA
	_oSbMnOpc2 := TMenuItem():New(_oPnInMvCb,"Coleta Atual",,,,{|| sfFeiraAtual(),_oBmpRefresh:Click() },,"AVGBOX1",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc2)

	// -- CONSULTAR ETIQUETA
	_oSbMnOpc3 := TMenuItem():New(_oPnInMvCb,"Cons.Etiq.",,,,{|| U_TWMSA015(),_oBmpRefresh:Click() },,"ACDIMG32",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc3)


	// -- BOTAO COM MAIS OPCOES
	_oBmpOpcoes := TBtnBmp2():New(000,000,060,022,"SDUAPPEND",,,,{||},_oPnInMvCb,"",{||})
	_oBmpOpcoes:Align := CONTROL_ALIGN_LEFT
	_oBmpOpcoes:SetPopupMenu(_oMnuOpcoes)

	// -- INTERROMPER
	_oBmpInicMSair := TBtnBmp2():New(000,000,040,040,"FINAL",,,,{|| _lRet := .F., _lFixaWnd := sfComColeta(), _oWndInicMov:End()  },_oPnInMvCb,"Sair",,.T.)
	_oBmpInicMSair:Align := CONTROL_ALIGN_RIGHT

	// cria o panel para o Folder/pastas
	_oPnInMvFld := TPanel():New(000,000,nil,_oWndInicMov,,.F.,.F.,,,110,110,.T.,.F.)
	_oPnInMvFld:Align:= CONTROL_ALIGN_ALLCLIENT

	// pastas com as opcoes de visualizacao
	_oFldPltDisp := TFolder():New(000,000,_aFolders,,_oPnInMvFld,,,,.T.,,100,200)
	_oFldPltDisp:Align:= CONTROL_ALIGN_ALLCLIENT

	// mantem a ABA aberta
	If (_nFldAtivo > 1)
		_oFldPltDisp:SetOption(_nFldAtivo)
	EndIf

	// 1a PASTA - list-box com a listagem dos paletes disponiveis para RECEBIMENTO/ARMAZENAGEM
	_oBrwPltRec := MsSelect():New((_cAlPltRec),,,_aHdPltRec,,,{0,0,203,373},,,_oFldPltDisp:aDialogs[1],,_aCorPltRec)
	_oBrwPltRec:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// 2a PASTA - browse com a listagem dos paletes disponiveis para EXPEDICAO
	_oBrwPltExp := MsSelect():New((_cAlPltExp),,,_aHdPltExp,,,{0,0,203,373},,,_oFldPltDisp:aDialogs[2],,_aCorPltExp)
	_oBrwPltExp:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// 3a PASTA - browse com a listagem dos paletes disponiveis para movimentacoes INTERNAS
	_oBrwPltInt := MsSelect():New((_cAlPltInt),,,_aHdPltInt,,,{0,0,203,373},,,_oFldPltDisp:aDialogs[3],,_aCorPltInt)
	_oBrwPltInt:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// cria o panel para o campo de confirmacao do endereco
	_oPnInMvRd := TPanel():New(000,000,nil,_oWndInicMov,,.F.,.F.,,CLR_LIGHTGRAY,22,22,.T.,.F.)
	_oPnInMvRd:Align := CONTROL_ALIGN_BOTTOM

	// leitura de etiqueta (palete ou endereco de origem)
	_oGetIdEtiq := TGet():New(001,005,{|u| If(PCount()>0,_cIdEtiqueta:=u,_cIdEtiqueta)},_oPnInMvRd,050,010, "@!",{|| (Vazio()) .Or. (sfVldEtiqueta(@_lRet, _oWndInicMov, @_lFixaWnd)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIdEtiqueta",,,,,,,"Informe a Etiqueta",1)
	_oGetIdEtiq:bWhen := {|| (_lPltDisponivel) }

	// temporizador/Refresh da tela (15 segundos)
	_oTimerRefresh := TTimer():New(15000,{|| _oBmpRefresh:Click() },_oWndInicMov)
	_oTimerRefresh:lActive := .T.

	// executa a primeira atualizacao
	_oBmpRefresh:Click()

	// seta o foco no id palete
	_oGetIdEtiq:SetFocus()

	// ativa a tela
	_oWndInicMov:Activate(,,,.F.,{|| _lFixaWnd },,)

	// Exclui tabelas temporárias no banco
	_cTrPltRec:Delete()
	_cTrPltExp:Delete()
	_cTrPltInt:Delete()

Return(_lRet)

// ** mostra todos os produtos coletados para a feirinha
user Function FeiraAtual()

	msgalert('teste de feria atual','teste')
	
return .t.


static Function sfFeiraAtual()//sfFeiraAtual()
	// variavel de controle
	local _lRet      := .F.
	// objetos locais
	local _oWmsFeira, _oPnlFeiCab, _oBmpOk, _oBmpSair, _oBrwFeira
	// arrays do browse
	local _aHeadFei  := {}
	// define o acols
	local _aColsFei  := sfARetFeira()

	
	memowrit("C:\query\twmsa011_sfARetFeira_var.txt",varinfo('_aColsFei',_aColsFei))
	
	// se não tiver nenhuma info ele
	If ( len(_aColsFei) = 0)
		U_FtWmsMsg("Não há coleta pendente.")
		Return .F.
	EndIf

	// monta o dialogo do monitor
	_oWmsFeira := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Coleta Atual",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes de operacao
	_oPnlFeiCab := TPanel():New(000,000,nil,_oWmsFeira,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlFeiCab:Align:= CONTROL_ALIGN_TOP

	// botao que finaliza
	_oBmpOk := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| sfGrvFeira(_oBrwFeira:aCols[1][2], _oBrwFeira:aCols[1][3], _oBrwFeira:aCols[1][4]), _oWmsFeira:End() },_oPnlFeiCab,"Finaliza",,.T.)
	_oBmpOk:Align := CONTROL_ALIGN_LEFT

	// botao que sai
	_oBmpSair := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| _oWmsFeira:End()},_oPnlFeiCab,"Sair",,.T.)
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// define array do browse
	aAdd(_aHeadFei,{"Etq.Vol"     ,"Z16_ETQVOL" ,"@!" ,TamSx3("Z16_ETQVOL")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadFei,{"End.Desti"   ,"Z08_ENDDES" ,"@!" ,TamSx3("Z08_ENDDES")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadFei,{"Plt.Feira"   ,"Z08_PLTFEI" ,"@!" ,TamSx3("Z08_PLTFEI")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadFei,{"Num.Os"      ,"Z08_NUMOS"  ,"@!" ,TamSx3("Z08_NUMOS")[1] ,0,Nil,Nil,"C",Nil,"R",,,".F." })

	// browse
	_oBrwFeira := MsNewGetDados():New(078,000,148,118,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsFei),'AllwaysTrue()','','AllwaysTrue()',_oWmsFeira,_aHeadFei,_aColsFei)
	_oBrwFeira:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativacao da tela
	ACTIVATE MSDIALOG _oWmsFeira

Return (_lRet)

// ** função que retorna o array de pedidos
//user Function sfARetFeira()
Static Function sfARetFeira()
	// array que vai receber os dados
	local _aFeira := {}
	// query para busca de pedidos
	local _cQuery   := ""

	// busco os pedidos baseado na carga
	_cQuery := " SELECT DISTINCT Z16_ETQVOL, Z08_ENDDES, Z08_PLTFEI, Z08_NUMOS, '.F.' IT_DEL "
	// mapa de expedicao/armazenagem
	_cQuery += " FROM " +RetSqlTab("Z08")+" (nolock) "
	// composicao do palete
	_cQuery += " INNER JOIN " + RetSqlTab("Z16") + " (nolock)  ON " + RetSqlCond("Z16")
	// id do palete
	_cQuery += " AND Z16_ETQPAL = ( CASE WHEN Z08_NEWPLT <> '' THEN Z08_NEWPLT ELSE Z08_PALLET END ) AND Z16_CODPRO = Z08_PRODUT AND Z16_ENDATU = Z08_ENDSRV "
	// somente com saldo
	_cQuery += " AND Z16_SALDO > 0 "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z08")
	_cQuery += " AND Z08_PLTFEI <> ' ' "
	_cQuery += " AND Z08_STATUS <> 'R'  "
	_cQuery += " AND Z08_USUARI = '" + __cUserId + "' " // somente os volumes startados por aquele operador
	// ordem dos dados
	_cQuery += " ORDER BY Z16_ETQVOL "

	// jogo os dados pro array
	_aFeira := U_SqlToVet(_cQuery)

	// caso tenha encontrado registros, insere o totalizador
	If (Len(_aFeira) > 0)
		// incluo mais um linha com o total de registros
		aAdd(_aFeira, { "", "", "TOTAL:", CVALTOCHAR(Len(_aFeira)), .F.} )
	EndIf

	// informação para debug
	memowrit("C:\query\twmsa011_sfARetFeira.txt",_cQuery)
	memowrit("C:\query\twmsa011_sfARetFeira2.txt",valtype(_aFeira))
	memowrit("C:\query\twmsa011_sfARetFeira3.txt",varinfo('a'))

	// retorno o array
Return (_aFeira)

// ** validação do endereço de destino para saber se é endereço de transação ou destino
Static Function sfVldTpEnd(mvEnd, mvCodArmaz)
	// variaveis de controle
	local _cQuery := ""
	local _lRet   := .F.

	// codigo do armazem
	Default mvCodArmaz := CriaVar("BE_LOCAL", .F.)

	// query que trata o tipo de endereço com dados baseados na DC8
	_cQuery := " SELECT COUNT(*) "
	_cQuery += " FROM "+RetSqlTab("SBE")+" (nolock) "
	_cQuery += " WHERE "+RetSqlCond("SBE")
	_cQuery += " AND BE_LOCAL = '" +mvCodArmaz+ "' "
	_cQuery += " AND BE_LOCALIZ = '"+mvEnd+"' "
	_cQuery += " AND EXISTS ( "
	_cQuery += " SELECT * FROM "+RetSqlTab("DC8")+" (nolock) "
	_cQuery += " WHERE DC8_CODEST = BE_ESTFIS "
	_cQuery += " AND DC8_TPESTR IN ( '4', '5' ) "
	_cQuery += " AND "+RetSqlCond("DC8") + " )"

	// informação para debug
	memowrit("C:\query\TWMSA011_sfVldTpEnd.txt",_cQuery)

	// caso encontre algum registro ele retorna verdadeiro
	If (U_FtQuery(_cQuery) >= 1)
		_lRet := .T.
	EndIf

Return(_lRet)

// ** funcao que valida o endereco de destino, de acordo com o equipamento utilizado
Static Function sfRetEndDest(mvEndDest, mvEndTran)
	// variavel de retorno
	local _cRetEndDest := ""

	// independente do equipamento, no caso de transf armazem, deixa a mercadoria na rua
	If (_cArmzAtual != _cArmzDesti)
		// somente para casos onde o endereço de origem é rua no caso da transferência
		If (Len(TRIM(Z08->Z08_ENDSRV)) == 2)
			If !(_cTipEquip == "PE1")
				_cRetEndDest := mvEndDest
			Else
				_cRetEndDest := Substr(mvEndDest,1,2)
			EndIf
		Else
			_cRetEndDest := mvEndTran
		EndIf
	Else
		If (_cTipEquip == "PE1") // paleteira eletrica
			// OS recebimento e OS interna
			If (_lOSRec) .Or. (_lOSInt)

				// se for no nível 1, deixa o paleteiro guardar no endereço final
				If (SubStr(mvEndDest,6,2) == "01") .And. (_lArmPrimNiv)
					_cRetEndDest := mvEndDest

					// doca/blocado/mezanino e etc
				ElseIf ( sfVldTpEnd(mvEndDest, _cArmzDesti) )
					_cRetEndDest := mvEndDest

					// somente para casos onde o endereço de origem é rua
				ElseIf (Len(TRIM(Z08->Z08_ENDSRV)) == 2)
					// se não, armazena na rua
					_cRetEndDest := mvEndDest

				Else
					// se não, armazena na rua
					_cRetEndDest := mvEndTran
				EndIf

			ElseIf (_lOSExp)
				If (cFilAnt == "105") .And. (Z08->Z08_ENDSRV == Z08->Z08_ENDORI) .And. (SubStr(Z08->Z08_ENDORI,6,2) == "01")
					_cRetEndDest := mvEndTran
				Else
					_cRetEndDest := mvEndDest
				EndIf
			EndIf

		ElseIf (_cTipEquip $ "ER1/EG1/EE1")// empilhadeira eletrica
			If (_lOSRec)
				// se for no nível 1, deixa o operador guardar no endereço final
				If (SUBSTR(mvEndDest,6,2) == "01") .And. (_lArmPrimNiv)
					_cRetEndDest := mvEndDest

				ElseIf (sfVldTpEnd(mvEndDest, _cArmzDesti)) // se destino for endereço blocado/doca/stage
					_cRetEndDest := mvEndDest

				ElseIf (sfVldTpEnd(Z08->Z08_ENDORI, _cArmzAtual)) // se origem for endereço blocado/doca/stage
					_cRetEndDest := mvEndDest

				ElseIf (Len(TRIM(Z08->Z08_ENDSRV)) == 2) // se a origem é na rua
					_cRetEndDest := mvEndDest

				Else
					// se não, armazena na rua
					_cRetEndDest := mvEndTran
				EndIf
			ElseIf (_lOSExp) .Or. (_lOSInt)
				_cRetEndDest := mvEndDest
			EndIf

		ElseIf (_cTipEquip == "TE1") // trilateral eletrica
			If (_lOSRec)
				_cRetEndDest := mvEndDest
			ElseIf (_lOSExp)
				_cRetEndDest := mvEndTran
			ElseIf (_lOSInt)
				// se for na mesma rua, nao precisa de paleteira
				If ( SubS(mvEndDest,1,2) == SubS(mvEndTran,1,2) ) .Or. (Empty(mvEndTran))
					_cRetEndDest := mvEndDest
				ElseIf ( SubS(mvEndDest,1,2) != SubS(mvEndTran,1,2) ) .And. ( ! Empty(mvEndTran))
					_cRetEndDest := mvEndTran
				Else
					_cRetEndDest := mvEndDest
				EndIf
			EndIf
		EndIf
	EndIf

	// padroniza o tamanho do conteudo
	_cRetEndDest := Padr(_cRetEndDest,_nTamEndere)

Return(_cRetEndDest)

// ** funcao para validar/confirmar o endereco de destino
Static Function sfConfDest(mvCancMov, mvFracPlt)
	// controle de confirmacao da tela
	local _lFixaWnd := .F.
	// variavel de retorno
	local _lRet := .F.
	// objetos locais
	local _oW01EndDest
	local _oP01Cab, _oP01Folder, _oP01EndDest
	local _oBmpCancMov
	local _oGetEndDest
	local _oBw01InfPlt, _oBw01EndDest
	local _oF01InfDet

	// define o header para detalhes do endereco
	local _aHeadEnd := {{"Endereço","IT_DETALHE" ,"" ,30,0,Nil,Nil,"C",Nil,"R",,,".F." }}
	local _aColsEnd := {}
	local _aBrwEnd  := {}

	// query
	local _cQuery

	// controle de cancelamento de movimento
	local _lCancMov := .F.

	// define o header e acosl para o palete movimentado
	local _aHeadPlt := {}
	local _aColsPlt := sfRetPltMov(_cIdPalete)

	// pastas do FOLDER
	local _aFolders := {'End.Destino', 'Itens do Palete'}

	// valores padroes
	Default mvFracPlt := .F.

	// define campos do browse do palete
	aAdd(_aHeadPlt,{"Quant"       ,"Z16_SALDO" , PesqPict("Z16","Z16_SALDO") , TamSx3("Z16_SALDO")[1] , TamSx3("Z16_SALDO")[2] ,Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHeadPlt,{"Etiqueta"    ,"Z16_ETQPRD", PesqPict("Z16","Z16_ETQPRD"), TamSx3("Z16_ETQPRD")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPlt,{"Descricao"   ,"B1_DESC"   , PesqPict("SB1","B1_DESC")   , TamSx3("B1_DESC")[1]   , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPlt,{"Produto"     ,"B1_COD"    , PesqPict("SB1","B1_COD")    , TamSx3("B1_COD")[1]    , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPlt,{"Lote"        ,"Z16_LOTCTL", PesqPict("Z16","Z16_LOTCTL"), TamSx3("Z16_LOTCTL")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPlt,{"Dt Valid"    ,"Z16_VLDLOT", PesqPict("Z16","Z16_VLDLOT"), TamSx3("Z16_VLDLOT")[1], 0                      ,Nil,Nil,"D",Nil,"R",,,".F." })
	aAdd(_aHeadPlt,{"Quant Seg UM","Z16_QTSEGU", PesqPict("Z16","Z16_QTSEGU"), TamSx3("Z16_QTSEGU")[1], TamSx3("Z16_QTSEGU")[2],Nil,Nil,"N",Nil,"R",,,".F." })

	// zera variaveis
	_cIdEndere := Space(_nTamIdEtq)

	// validação para OS de Transferência
	If ( ! Empty(_cEndDesti) )
		_aColsEnd := aClone( U_FtCfgEnd(_cEndDesti, _cArmzAtual) )
	Else
		// preencho o browse para indicar ao usuário qual endereço ele quer deixar a mercadoria
		aAdd(_aBrwEnd, {"Informe o endereço desejado!",.F.})
		_aColsEnd := aClone(_aBrwEnd)
	EndIf

	// apresenta tela para definir o endereco atual/origem
	_oW01EndDest := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Endereçamento",,,.F.,,,,,,.T.,,,.T. )
	_oW01EndDest:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oP01Cab := TPanel():New(000,000,nil,_oW01EndDest,,.F.,.F.,,,22,22,.T.,.F.)
	_oP01Cab:Align := CONTROL_ALIGN_TOP

	// -- BOTÃO PARA CANCELAR MOVIMENTO
	If (mvCancMov)
		_oBmpCancMov := TBtnBmp2():New(000,000,030,022,"ESTOMOVI",,,,{|| sfCancMovim(@_lCancMov, @_lFixaWnd, @_oW01EndDest) },_oP01Cab,"Canc.Movim.",,.T.)
		_oBmpCancMov:Align := CONTROL_ALIGN_RIGHT
	EndIf

	// cria o panel para o folder
	_oP01Folder := TPanel():New(000,000,nil,_oW01EndDest,,.F.,.F.,,,400,400,.T.,.F.)
	_oP01Folder:Align:= CONTROL_ALIGN_ALLCLIENT

	// pastas com as opcoes de visualizacao
	_oF01InfDet := TFolder():New(000,000,_aFolders,,_oP01Folder,,,,.T.,,100,200)
	_oF01InfDet:Align:= CONTROL_ALIGN_ALLCLIENT

	// browse com os detalhes do endereco de destino
	_oBw01EndDest := MsNewGetDados():New(000,000,400,400,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsEnd),'AllwaysTrue()','','AllwaysTrue()',_oF01InfDet:aDialogs[1],_aHeadEnd,_aColsEnd)
	_oBw01EndDest:oBrowse:oFont := _oFnt04
	_oBw01EndDest:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// browse com os detalhes da composicao do palete
	_oBw01InfPlt := MsNewGetDados():New(000,000,400,400,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsEnd),'AllwaysTrue()','','AllwaysTrue()', _oF01InfDet:aDialogs[2], _aHeadPlt, _aColsPlt)
	_oBw01InfPlt:oBrowse:oFont := _oFnt04
	_oBw01InfPlt:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// cria o panel para o campo de confirmacao do endereco
	_oP01EndDest := TPanel():New(000,000,nil,_oW01EndDest,,.F.,.F.,,CLR_LIGHTGRAY,22,22,.T.,.F.)
	_oP01EndDest:Align:= CONTROL_ALIGN_BOTTOM

	// confirmacao do endereco de destino
	_oGetEndDest := TGet():New(001,005,{|u| If(PCount()>0,_cIdEndere:=u,_cIdEndere)},_oP01EndDest,050,010,_cMskEtiq,{|| (Vazio()) .Or. (sfVldEndDes(_cIdEndere, _cEndDesti, @_lRet, _oW01EndDest, @_lFixaWnd, mvFracPlt)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIdEndere",,,,,,,"Confirme o endereço:",1)

	// seta o foco no id palete
	_oGetEndDest:SetFocus()

	// ativa a tela
	_oW01EndDest:Activate(,,,.F.,{|| _lFixaWnd },,)

	// verifica se o movimento foi cancelado
	If (_lCancMov)

		// funcao que executa o cancelamento do movimento iniciado
		sfExCancMov( Z08->(RecNo()) ,;
		_cCodOper )

	EndIf

Return(_lRet)

// ** funcao para confirmar o cancelamento do movimento
Static Function sfCancMovim(mvRet,mvFixaWnd,mvObjTela)

	If ( ! U_FtYesNoMsg("Cancela Movimento"+CRLF+"da Mercadoria?","Cancela Movimento") )
		Return(mvRet)
	EndIf

	// atualiza variaveus e fecha a tela
	mvRet     := .T.
	mvFixaWnd := .T.
	mvObjTela:End()

Return(mvRet)

// ** funcao que executa o cancelamento do movimento iniciado
// aceita o estorno de um registro por vez
// parâmetros (Recno Z08 , código do operador)
Static Function sfExCancMov( mvRecnoZ08 , mvCodOper)
	// seek do Z17
	local _cSeekZ17
	// seek do Z16
	local _cSeekZ16
	// query
	local _cQryUpd
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z17","Z08"})

	// variaveis de controle
	local _cTmpNumOs := ""
	local _cTmpIdPlt := ""

	// variavel de endereço
	local _cEndSrv := ""

	// INICIA TRANSACAO
	BEGIN TRANSACTION

		// posiciona no registro
		dbSelectArea("Z08")
		Z08->(dbGoTo( mvRecnoZ08 ))

		// atualiza variaveis
		_cTmpNumOs := Z08->Z08_NUMOS

		// atualiza ID palete
		If (Z08->Z08_FRAPLT == "N")
			_cTmpIdPlt := Z08->Z08_PALLET
		ElseIf ( (Z08->Z08_FRAPLT == "S") .And. ( ! Empty(Z08->Z08_NEWPLT )) )
			_cTmpIdPlt := Z08->Z08_NEWPLT
		ElseIf ( (Z08->Z08_FRAPLT == "S") .And. ( Empty(Z08->Z08_NEWPLT) ) )
			_cTmpIdPlt := Z08->Z08_PALLET
		EndIf

		// coloca em modo edicao
		RecLock("Z08")
		Z08->Z08_STATUS := "P" // P-Planejado / R-Realizado / M-Movimento / E-Erro

		// apaga o conteudo dos campos somente quando for o primeiro movimento
		If (Z08->Z08_TPOPER == "E") .And. (Z08->Z08_ENDSRV == Z08->Z08_ENDORI)
			Z08->Z08_PALLET := Space(Len(Z08->Z08_PALLET))
			Z08->Z08_LOTCTL := Space(Len(Z08->Z08_LOTCTL))
			Z08->Z08_DTINIC := CtoD("//")
			Z08->Z08_HRINIC := ""
			Z08->Z08_USUARI := ""
			Z08->Z08_EQUIPA := ""
			// preencho a variavel de endereço de serviço (inicio da movimentação)
			_cEndSrv := Z08->Z08_ENDSRV

		ElseIf (Z08->Z08_TPOPER == "E") .And. (Z08->Z08_ENDSRV == Z08->Z08_ENDTRA)
			// preencho a variavel de endereço de serviço (inicio da movimentação)
			_cEndSrv := Z08->Z08_ENDTRA

		EndIf
		Z08->(MsUnLock())

		// para OS de recebimento, também volta status conferência para "D-Disponível"
		If (Z08->Z08_TPOPER == "E")
			// atualiza o status do palete para D-DISPONIVEL
			_cQryUpd := "UPDATE "+RetSqlName("Z07")+" "
			// seta conteudo
			_cQryUpd += "SET Z07_STATUS = 'D' "
			// filtros
			_cQryUpd += "WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
			// numero da OS
			_cQryUpd += "AND Z07_NUMOS  = '"+_cTmpNumOs+"' "
			// ID palete
			_cQryUpd += "AND Z07_PALLET = '"+_cTmpIdPlt+"' "
			// status
			_cQryUpd += "AND Z07_STATUS = 'M' "
			// executa o update
			TcSQLExec(_cQryUpd)

		EndIf

		// atualiza o status do movimento para cancelado
		dbSelectArea("Z17")
		Z17->(dbSetOrder(1)) // 1-Z17_FILIAL, Z17_ETQPLT
		Z17->(dbSeek( _cSeekZ17 := xFilial("Z17")+_cTmpIdPlt ))
		// compara o numero da OS
		While Z17->(!Eof()) .And. (Z17->(Z17_FILIAL+Z17_ETQPLT)==_cSeekZ17)
			If (Z17->Z17_NUMOS == Z08->Z08_NUMOS) .And. (Z17->Z17_SEQOS == Z08->Z08_SEQOS) .And. (Empty(Z17->Z17_DTFIM)) .And. (Z17->Z17_STATUS == "M") .And. (Z17->Z17_OPERAD == mvCodOper)
				RecLock("Z17")
				Z17->Z17_STATUS := "C"
				Z17->(MsUnLock())
			EndIf
			// proximo item
			Z17->(dbSkip())
		EndDo

		// seek no registro na Z16
		dbSelectArea("Z16")
		Z16->(dbSetOrder(1)) // 1-Z16_FILIAL, Z16_ETQPAL
		Z16->(dbSeek( _cSeekZ16 := xFilial("Z16")+_cTmpIdPlt ))
		// corrige/estorna o endereço atual de todos os itens contidos no pallet
		While Z16->(!Eof()) .And. (Z16->(Z16_FILIAL + Z16_ETQPAL) == _cSeekZ16)
			RecLock("Z16")
			Z16->Z16_ENDATU := Z08->Z08_ENDSRV // atualiza o endereço do pallet
			Z16->(MsUnLock())

			// proximo item do pallet
			Z16->(dbSkip())
		EndDo

		// FINALIZA TRANSACAO
	END TRANSACTION

	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aArea)

Return

// ** funcao que retorna os produtos que compoe o palete
Static Function sfProdPalete(mvIdPalete)
	local _aRet := {}
	local _cQryZ16

	_cQryZ16 := " SELECT Z16_CODPRO, Z16_NUMSEQ, SUM(Z16_SALDO) Z16_SALDO, Z16_LOTCTL, Z16_VLDLOT "
	// formacao do palete
	_cQryZ16 += " FROM "+RetSqlTab("Z16")+" (nolock) "
	// filtro padrao
	_cQryZ16 += " WHERE "+RetSqlCond("Z16")
	// filtro do ID palete
	_cQryZ16 += " AND Z16_ETQPAL = '"+mvIdPalete+"' "
	// filtro do armazém
	_cQryZ16 += " AND Z16_LOCAL = '"+_cArmzAtual+"' "
	// considera o saldo
	_cQryZ16 += " AND Z16_SALDO > 0 "
	// agrupa por produto e numseq
	_cQryZ16 += " GROUP BY Z16_CODPRO, Z16_NUMSEQ, Z16_LOTCTL, Z16_VLDLOT "
	// atualiza variavel de retorno
	_aRet := U_SqlToVet(_cQryZ16,{"Z16_VLDLOT"})

	memowrit("C:\query\sfprodpalete_TWMSA011.txt",_cQryZ16)

Return(_aRet)

// ** funcao para atualizar os dados
Static Function sfAtuDados(mvQryUsr, mvAlPltRec, mvAlPltExp, mvAlPltInt, mvObjGetPlt)
	// gera novo alias
	local _cNewAlQry := GetNextAlias()
	// itens
	local _aColsOS := {}
	// query paletes disponveis
	local _cQryPltDisp
	// variavel temporaria
	local _aTmpPltDisp := {}
	local _aTmpPltExp := {}
	local _aTmpPltInt := {}
	local _nPltDisp := 0
	local _nPltExp := 0
	local _nPltInt := 0
	// variaveis temporarias para inicio da operação
	local _cTmpEndere
	local _cTmpArmaz

	// posicao inicial
	local _aAreaRec := (mvAlPltRec)->(GetArea())
	local _aAreaExp := (mvAlPltExp)->(GetArea())
	local _aAreaInt := (mvAlPltInt)->(GetArea())

	// mantem no primeiro registro
	local _lFirstRec := ((mvAlPltRec)->(RecCount()) == 0)
	local _lFirstExp := ((mvAlPltExp)->(RecCount()) == 0)
	local _lFirstInt := ((mvAlPltInt)->(RecCount()) == 0)

	// zera variaveis
	_aEndServ  := {}
	_cEndServ  := ""
	_cQryNumOS := ""
	_cQryChrIn := ""
	_cChOrdSrv := ""
	// ruas disponiveis para filtro
	_aRuaDisp := {"TODAS"}

	// apaga o conteudo do TRB - Recebimento
	dbSelectArea(mvAlPltRec)
	__DbZap()

	// apaga o conteudo do TRB - Expedicao
	dbSelectArea(mvAlPltExp)
	__DbZap()

	// apaga o conteudo do TRB - Mov. Internas
	dbSelectArea(mvAlPltInt)
	__DbZap()

	// reinicia variavel
	_lPltDisponivel := .F.

	// verifica se o alias esta aberto
	If (Select(_cNewAlQry) <> 0)
		dbSelectArea(_cNewAlQry)
		dbCloseArea()
	EndIf

	// executa o select
	DbUseArea(.T.,'TOPCONN',TCGENQRY(,,mvQryUsr),_cNewAlQry,.F.,.T.)
	(_cNewAlQry)->(DbGoTop())

	// alimenta vetor das OSs pendentes
	While (_cNewAlQry)->( ! Eof() )

		// atualiza os itens do browse
		aAdd(_aColsOS,{ (_cNewAlQry)->Z05_NUMOS,;
		(_cNewAlQry)->Z06_SEQOS,;
		(_cNewAlQry)->DSC_OPER,;
		(_cNewAlQry)->PG_CARGA,;
		(_cNewAlQry)->A1_NREDUZ,;
		(_cNewAlQry)->Z06_PRIOR,;
		(_cNewAlQry)->Z06_ENDSRV,;
		(_cNewAlQry)->DSC_SERVIC,;
		(_cNewAlQry)->DSC_TAREFA,;
		(_cNewAlQry)->Z06_SERVIC,;
		(_cNewAlQry)->Z06_TAREFA,;
		.F.	 })

		// numero das OS disponiveis, em formato SQL
		_cQryNumOS += IIf(Empty(_cQryNumOS),"",",") + "'" + (_cNewAlQry)->Z05_NUMOS + "'"
		_cQryChrIn += (_cNewAlQry)->Z05_NUMOS + "|"

		// atualizar os paletes disponiveis
		If ( (_cNewAlQry)->DSC_OPER == "REC" )
			_cQryPltDisp := " SELECT Z07_ENDATU, COUNT(DISTINCT Z07.Z07_PALLET) QTD_PLTDIS "
			// conferencia de mercadoria
			_cQryPltDisp += " FROM " + RetSqlTab("Z07") + " (nolock) "

			// cabecalho da OS
			_cQryPltDisp += " INNER JOIN " + RetSqlTab("Z05") + " (nolock)  ON " + RetSqlCond("Z05") + " AND Z05_NUMOS = Z07_NUMOS "

			// filtro padrao
			_cQryPltDisp += " WHERE " + RetSqlCond("Z07")
			// filtra numero da OS
			_cQryPltDisp += " AND Z07_NUMOS = '" + (_cNewAlQry)->Z05_NUMOS + "' "
			// status D-CONFERIDO/DISPONIVEL
			_cQryPltDisp += " AND Z07_STATUS = 'D' "

			// filtra somente no endereco que o equipamento pode trabalhar
			_cQryPltDisp += " AND " + StrTran(_cQryEndEq, "CMP_ENDSRV", "Z07_ENDATU")

			// agrupa dados por enderecos de servico
			_cQryPltDisp += " GROUP BY Z07_ENDATU "

		ElseIf ( (_cNewAlQry)->DSC_OPER == "EXP" )

			// query para agrupar dados de expedicao
			_cQryPltDisp := "SELECT Z08_ENDSRV, "
			_cQryPltDisp += "       Sum(QTD_PLTDIS) QTD_PLTDIS "
			_cQryPltDisp += "FROM   ( "

			// query com todos os dados de expedicao
			_cQryPltDisp += "SELECT CASE "
			_cQryPltDisp += "  WHEN (SELECT Count(*) "
			_cQryPltDisp += "        FROM   "+RetSqlName("SBE")+" SBE (nolock)  "
			_cQryPltDisp += "      WHERE  "+RetSqlCond("SBE")
			_cQryPltDisp += "             AND BE_LOCALIZ = Z08_ENDSRV "
			_cQryPltDisp += "             AND EXISTS (SELECT * "
			_cQryPltDisp += "                         FROM   "+RetSqlName("DC8")+" DC8 (nolock)  WHERE "+RetSqlCond("DC8")
			_cQryPltDisp += "                         AND  DC8_CODEST = BE_ESTFIS AND DC8_TPESTR = '4')) > 0 THEN Z08_ENDSRV "
			_cQryPltDisp += " ELSE Substring(Z08_ENDSRV, 1, 2) "
			_cQryPltDisp += " END                        Z08_ENDSRV, "
			_cQryPltDisp += " COUNT(DISTINCT Z08_PALLET) QTD_PLTDIS "
			// mapa de apanhe
			_cQryPltDisp += " FROM " + RetSqlTab("Z08")+ " (nolock) "
			// composicao do palete
			_cQryPltDisp += " INNER JOIN " + RetSqlTab("Z16") + " (nolock)  ON " + RetSqlCond("Z16") + " AND Z16_ETQPAL = (CASE WHEN Z08_NEWPLT <> '' THEN Z08_NEWPLT ELSE Z08_PALLET END) "
			// endereco atual do palete
			_cQryPltDisp += " AND Z16_ENDATU = Z08_ENDSRV "
			// cabecalho da OS
			_cQryPltDisp += " INNER JOIN " + RetSqlTab("Z05") + " (nolock)  ON " + RetSqlCond("Z05") + " AND Z05_NUMOS = Z08_NUMOS "
			// filtro padrao
			_cQryPltDisp += " WHERE " + RetSqlCond("Z08")
			// filtra numero da OS
			_cQryPltDisp += " AND Z08_NUMOS = '" + (_cNewAlQry)->Z05_NUMOS + "' "
			// status
			_cQryPltDisp += " AND Z08_STATUS = 'P' "
			// filtra somente no endereco que o equipamento pode trabalhar
			_cQryPltDisp += " AND " + StrTran(_cQryEndEq, "CMP_ENDSRV", "Z08_ENDSRV")
			// agrupa dados por enderecos de servico
			_cQryPltDisp += " GROUP BY SUBSTRING(Z08_ENDSRV,1,2), Z08_ENDSRV "

			// fecha query que agrupa dados
			_cQryPltDisp += ") AS MOV_EXPEDICAO "
			// agrupa ruas
			_cQryPltDisp += "GROUP BY Z08_ENDSRV "

		ElseIf ( (_cNewAlQry)->DSC_OPER == "INT" )

			_cQryPltDisp := "SELECT SUBSTRING(Z16_ENDATU,1,2) Z16_ENDATU, COUNT(DISTINCT Z08_PALLET) QTD_PLTDIS "
			// mapa de apanhe
			_cQryPltDisp += "FROM "+RetSqlName("Z08")+" Z08 (nolock)  "
			// cabecalho da OS
			_cQryPltDisp += "INNER JOIN "+RetSqlName("Z05")+" Z05 (nolock)  ON "+RetSqlCond("Z05")+" AND Z05_NUMOS  = Z08_NUMOS "
			// composicao do palete
			_cQryPltDisp += "INNER JOIN "+RetSqlName("Z16")+" Z16 (nolock)  ON "+RetSqlCond("Z16")+" AND Z16_ETQPAL = CASE WHEN Z08_NEWPLT <> '' THEN Z08_NEWPLT ELSE Z08_PALLET END "
			// endereco atual do palete
			_cQryPltDisp += "AND Z16_ENDATU = Z08_ENDSRV "
			// filtro padrao
			_cQryPltDisp += "WHERE "+RetSqlCond("Z08")+" "
			// filtra numero da OS
			_cQryPltDisp += "AND Z08_NUMOS = '"+(_cNewAlQry)->Z05_NUMOS+"' "
			// status
			_cQryPltDisp += "AND Z08_STATUS = 'P' "
			// filtra somente no endereco que o equipamento pode trabalhar
			_cQryPltDisp += "AND "+StrTran(_cQryEndEq,"CMP_ENDSRV","Z16_ENDATU")+" "
			// tratamento especifico para Trilateral
			If (_cTipEquip $ "TE1")
				_cQryPltDisp += "AND ( "
				_cQryPltDisp += "      (Z08_ENDTRA != ' ' AND SUBSTRING(Z08_ENDSRV,1,2) = SUBSTRING(Z08_ENDTRA,1,2) AND SUBSTRING(Z16_ENDATU,3,1) != ' ' ) "
				_cQryPltDisp += "       OR "
				_cQryPltDisp += "      (Z08_ENDTRA  = ' ') "
				_cQryPltDisp += "    ) "
				// tratamento especifico para paleteira
			ElseIf (_cTipEquip=="PE1") // validação para primeiro nível
				_cQryPltDisp += "       AND ( ( Z08_ENDTRA != ' ' ) "
				_cQryPltDisp += "               OR ( SUBSTRING(Z08_ENDSRV, 6, 2 ) = '01' ) "
				_cQryPltDisp += "               OR ( SUBSTRING(Z08_ENDSRV, 1, 5 ) = 'BLOCO' ) "
				_cQryPltDisp += "               OR ( SUBSTRING(Z08_ENDSRV, 1, 11) = 'NAOCONFORME' )
				_cQryPltDisp += "               OR ( SUBSTRING(Z08_ENDSRV, 1, 7 ) = 'ANALISE' )
				_cQryPltDisp += "           ) "
			EndIf
			// agrupa dados por enderecos de servico
			_cQryPltDisp += "GROUP BY SUBSTRING(Z16_ENDATU,1,2) "

		EndIf

		memowrit("C:\query\twmsa011_sfatudados_1.txt", _cQryPltDisp)

		// atualiza os dados temporarios
		_aTmpPltDisp := U_SqlToVet(_cQryPltDisp)

		For _nPltDisp := 1 to Len(_aTmpPltDisp)

			// informacoes de paletes para RECEBIMENTO
			If ( (_cNewAlQry)->DSC_OPER == "REC" )

				// padroniza o tamanho do campo
				_cTmpEndere := PadR(_aTmpPltDisp[_nPltDisp][1],_nTamEndere)

				// atualiza os dados do arquivo de trabalho
				dbSelectArea(mvAlPltRec)
				(mvAlPltRec)->(dbSetOrder(1))
				If (mvAlPltRec)->(dbSeek( _cTmpEndere ))
					RecLock((mvAlPltRec))
					(mvAlPltRec)->REC_QTD += _aTmpPltDisp[_nPltDisp][2]
					(mvAlPltRec)->(MsUnLock())
				Else
					RecLock((mvAlPltRec),.T.)
					(mvAlPltRec)->REC_COR    := "RUA"
					(mvAlPltRec)->REC_RUA    := _aTmpPltDisp[_nPltDisp][1]
					(mvAlPltRec)->REC_ENDORI := If(Len(AllTrim(_cTmpEndere))==2,"RUA: ","")+AllTrim(_aTmpPltDisp[_nPltDisp][1])
					(mvAlPltRec)->REC_ORDEM  := SubStr(_cTmpEndere,1,2) + SubStr(_cTmpEndere,4,2) + SubStr(_cTmpEndere,3,1) + SubStr(_cTmpEndere,8,5) + SubStr(_cTmpEndere,6,2) // organiza os dados por (rua, predio, lado, posicao, andar)
					(mvAlPltRec)->REC_QTD    := _aTmpPltDisp[_nPltDisp][2]
					(mvAlPltRec)->(MsUnLock())
				EndIf

				// atualiza variavel de palete disponivel
				_lPltDisponivel := .T.

				// informacoes de paletes para EXPEDICAO
			ElseIf ( (_cNewAlQry)->DSC_OPER == "EXP" )

				// adiciona a rua para disponibilizar o filtro
				aAdd(_aRuaDisp, AllTrim(_aTmpPltDisp[_nPltDisp][1]))

				// verifica o filtro de RUA na expedicao
				If (Empty(_cFiltraRua)) .Or. (_cFiltraRua=="TODAS") .Or. (_cFiltraRua == AllTrim(_aTmpPltDisp[_nPltDisp][1]) )

					// padroniza o tamanho do campo
					_cTmpEndere := PadR(_aTmpPltDisp[_nPltDisp][1],_nTamEndere)

					// atualiza os dados do arquivo de trabalho
					dbSelectArea(mvAlPltExp)
					(mvAlPltExp)->(dbSetOrder(1))
					If (mvAlPltExp)->(dbSeek( _cTmpEndere ))
						RecLock((mvAlPltExp))
						(mvAlPltExp)->EXP_QTD += _aTmpPltDisp[_nPltDisp][2]
						(mvAlPltExp)->(MsUnLock())
					Else
						RecLock((mvAlPltExp),.T.)
						(mvAlPltExp)->EXP_COR    := "RUA"
						(mvAlPltExp)->EXP_RUA    := _aTmpPltDisp[_nPltDisp][1]
						(mvAlPltExp)->EXP_ENDORI := IIf(Len(AllTrim(_cTmpEndere))==2,"RUA: ","")+AllTrim(_aTmpPltDisp[_nPltDisp][1])
						(mvAlPltExp)->EXP_ORDEM  := SubStr(_cTmpEndere,1,2) + SubStr(_cTmpEndere,4,2) + SubStr(_cTmpEndere,3,1) + SubStr(_cTmpEndere,8,5) + SubStr(_cTmpEndere,6,2) // organiza os dados por (rua, predio, lado, posicao, andar)
						(mvAlPltExp)->EXP_QTD    := _aTmpPltDisp[_nPltDisp][2]
						(mvAlPltExp)->(MsUnLock())
					EndIf

					// atualiza variavel de palete disponivel
					_lPltDisponivel := .T.

					// detalha todos os enderecos para retirada do produto
					_cQryPltDisp := " SELECT DISTINCT Z08_ENDSRV, Z08_QUANT, Z08_FRAPLT, Z08_LOCAL "
					// mapa de apanhe
					_cQryPltDisp += " FROM " + RetSqlTab("Z08") + " (nolock) "
					// cabecalho da OS
					_cQryPltDisp += " INNER JOIN " + RetSqlTab("Z05") + " (nolock)  ON " + RetSqlCond("Z05") + " AND Z05_NUMOS = Z08_NUMOS "
					// filtro padrao
					_cQryPltDisp += " WHERE " + RetSqlCond("Z08")
					// filtra numero da OS
					_cQryPltDisp += " AND Z08_NUMOS = '" + (_cNewAlQry)->Z05_NUMOS + "' "
					// status
					_cQryPltDisp += " AND Z08_STATUS = 'P' "
					// filtra somente no endereco que o equipamento pode trabalhar
					_cQryPltDisp += " AND " + StrTran(_cQryEndEq, "CMP_ENDSRV", "Z08_ENDSRV")+" "
					// filtra somente a rua
					_cQryPltDisp += " AND SUBSTRING(Z08_ENDSRV,1,2) = '"+AllTrim(_aTmpPltDisp[_nPltDisp][1])+"' "
					// endereco de servico
					_cQryPltDisp += " AND SUBSTRING(Z08_ENDSRV,1,2) = '"+AllTrim(_aTmpPltDisp[_nPltDisp][1])+"' "

					memowrit("C:\query\twmsa011_sfatudados_exp.txt",_cQryPltDisp)

					// atualiza os dados temporarios
					_aTmpPltExp := U_SqlToVet(_cQryPltDisp)

					// atualiza todos os enderecos da rua
					For _nPltExp := 1 to Len(_aTmpPltExp)

						// padroniza o tamanho do campo
						_cTmpEndere := PadR(_aTmpPltExp[_nPltExp][1],_nTamEndere)
						_cTmpArmaz  := _aTmpPltExp[_nPltExp][4]

						// verifica o tipo de endereco, só atualiza Sub-Total da rua quando for estrutura porta palete
						If ( Posicione("SBE",1, xFilial("SBE")+_cTmpArmaz+_cTmpEndere ,"BE_ESTFIS") $ "000002/000010" )

							// atualiza os dados do arquivo de trabalho
							dbSelectArea(mvAlPltExp)
							(mvAlPltExp)->(dbSetOrder(1))
							If (mvAlPltExp)->(dbSeek( _cTmpEndere ))
								RecLock((mvAlPltExp))
								(mvAlPltExp)->EXP_QTD += _aTmpPltExp[_nPltExp][2]
								(mvAlPltExp)->(MsUnLock())
							Else
								RecLock((mvAlPltExp),.T.)
								(mvAlPltExp)->EXP_COR    := If(_aTmpPltExp[_nPltExp][3]=="N","TOT","FRA")
								(mvAlPltExp)->EXP_ENDORI := Transf(AllTrim(_cTmpEndere),"@R 99.A.99.99.99999")
								(mvAlPltExp)->EXP_ORDEM  := SubStr(_cTmpEndere,1,2) + SubStr(_cTmpEndere,4,2) + SubStr(_cTmpEndere,3,1) + SubStr(_cTmpEndere,8,5) + SubStr(_cTmpEndere,6,2) // organiza os dados por (rua, predio, lado, posicao, andar)
								(mvAlPltExp)->EXP_QTD    := _aTmpPltExp[_nPltExp][2]
								(mvAlPltExp)->(MsUnLock())
							EndIf

						EndIF

						// atualiza os enderecos de servico
						If ( aScan(_aEndServ,{|x| (x[1] == _cTmpEndere) }) == 0 )

							// atualiza vetor
							aAdd(_aEndServ, { _cTmpEndere , (_cNewAlQry)->DSC_OPER } )

							// para query
							_cEndServ += AllTrim(_cTmpEndere) + "|"

						EndIf

					Next _nPltExp

				EndIf

				// informacoes de paletes para movimentacoes INTERNAS
			ElseIf ( (_cNewAlQry)->DSC_OPER == "INT" )

				// adiciona a rua para disponibilizar o filtro
				aAdd(_aRuaDisp,AllTrim(_aTmpPltDisp[_nPltDisp][1]))

				// verifica o filtro de RUA na expedicao
				If (Empty(_cFiltraRua)) .Or. (_cFiltraRua=="TODAS") .Or. (_cFiltraRua == AllTrim(_aTmpPltDisp[_nPltDisp][1]) )

					// padroniza o tamanho do campo
					_cTmpEndere := PadR(_aTmpPltDisp[_nPltDisp][1],_nTamEndere)

					// atualiza os dados do arquivo de trabalho
					dbSelectArea(mvAlPltInt)
					(mvAlPltInt)->(dbSetOrder(1))
					If (mvAlPltInt)->(dbSeek( _cTmpEndere+".01" ))
						RecLock((mvAlPltInt))
						(mvAlPltInt)->INT_QTD += _aTmpPltDisp[_nPltDisp][2]
						(mvAlPltInt)->(MsUnLock())
					Else
						RecLock((mvAlPltInt),.T.)
						(mvAlPltInt)->INT_DIRECA := "   "
						(mvAlPltInt)->INT_RUA    := _aTmpPltDisp[_nPltDisp][1]
						(mvAlPltInt)->INT_ENDORI := "TOTAL RUA: "+AllTrim(_aTmpPltDisp[_nPltDisp][1])
						(mvAlPltInt)->INT_ORDEM  := _cTmpEndere+".01"
						(mvAlPltInt)->INT_QTD    := _aTmpPltDisp[_nPltDisp][2]
						(mvAlPltInt)->(MsUnLock())
					EndIf

					// atualiza variavel de palete disponivel
					_lPltDisponivel := .T.

					// detalha todos os enderecos para retirada do produto
					_cQryPltDisp := "SELECT Z16_ENDATU, Z08_QUANT, Z08_FRAPLT, SUM(Z16_QUANT) Z16_QUANT, Z08_ENDSRV, Z08_ENDORI, Z08_ENDTRA, Z08_ENDDES, "
					// direcao da movimentacao
					_cQryPltDisp += "CASE "
					_cQryPltDisp += "  WHEN SUBSTRING(Z08_ENDSRV,1,2) = SUBSTRING(Z08_ENDTRA,1,2) AND SUBSTRING(Z16_ENDATU,3,1) != ' ' THEN 'BAI' "
					_cQryPltDisp += "  WHEN SUBSTRING(Z08_ENDSRV,1,2) = SUBSTRING(Z08_ENDTRA,1,2) AND SUBSTRING(Z16_ENDATU,3,1)  = ' ' THEN 'TRA' "
					_cQryPltDisp += "  WHEN Z08_ENDTRA  = '' THEN 'ARM' "
					_cQryPltDisp += "END INT_DIRECA "
					// mapa de apanhe/transferencias
					_cQryPltDisp += "FROM "+RetSqlName("Z08")+" Z08 (nolock)  "
					// cabecalho da OS
					_cQryPltDisp += "INNER JOIN "+RetSqlName("Z05")+" Z05 (nolock)  ON "+RetSqlCond("Z05")+" AND Z05_NUMOS = Z08_NUMOS "
					// composicao do palete
					_cQryPltDisp += "INNER JOIN "+RetSqlName("Z16")+" Z16 (nolock)  ON "+RetSqlCond("Z16")+" AND Z16_ETQPAL = Z08_PALLET "
					// endereco atual do palete
					_cQryPltDisp += "AND Z16_ENDATU = Z08_ENDSRV "
					// filtro padrao
					_cQryPltDisp += "WHERE "+RetSqlCond("Z08")+" "
					// filtra numero da OS
					_cQryPltDisp += "AND Z08_NUMOS = '"+(_cNewAlQry)->Z05_NUMOS+"' "
					// status
					_cQryPltDisp += "AND Z08_STATUS = 'P' "
					// filtra somente no endereco que o equipamento pode trabalhar
					_cQryPltDisp += "AND "+StrTran(_cQryEndEq,"CMP_ENDSRV","Z16_ENDATU")+" "
					// filtra somente a rua
					_cQryPltDisp += "AND SUBSTRING(Z16_ENDATU,1,2) = '"+AllTrim(_aTmpPltDisp[_nPltDisp][1])+"' "
					// RUA de servico
					_cQryPltDisp += "AND SUBSTRING(Z08_ENDSRV,1,2) = '"+AllTrim(_aTmpPltDisp[_nPltDisp][1])+"' "
					// tratamento especifico para Trilateral
					If (_cTipEquip=="TE1")
						_cQryPltDisp += "AND ( "
						_cQryPltDisp += "      (Z08_ENDTRA != ' ' AND SUBSTRING(Z08_ENDSRV,1,2) = SUBSTRING(Z08_ENDTRA,1,2) AND SUBSTRING(Z16_ENDATU,3,1) != ' ' ) "
						_cQryPltDisp += "       OR "
						_cQryPltDisp += "      (Z08_ENDTRA  = ' ') "
						_cQryPltDisp += "    ) "
					EndIf
					// agrupa dados por enderecos de servico
					_cQryPltDisp += "GROUP BY Z16_ENDATU, Z08_QUANT, Z08_FRAPLT, Z08_ENDSRV, Z08_ENDORI, Z08_ENDTRA, Z08_ENDDES "

					memowrit("C:\query\sfatudados_twmsa011_int.txt",_cQryPltDisp)

					// atualiza os dados temporarios
					_aTmpPltInt := U_SqlToVet(_cQryPltDisp)

					// atualiza todos os enderecos da rua
					For _nPltInt := 1 to Len(_aTmpPltInt)

						// padroniza o tamanho do campo
						_cTmpEndere := PadR(_aTmpPltInt[_nPltInt][1],_nTamEndere)

						// atualiza os dados do arquivo de trabalho
						dbSelectArea(mvAlPltInt)
						(mvAlPltInt)->(dbSetOrder(1))
						If (mvAlPltInt)->(dbSeek( _cTmpEndere+".02" ))
							RecLock((mvAlPltInt))
							(mvAlPltInt)->INT_QTD += _aTmpPltInt[_nPltInt][2]
							(mvAlPltInt)->(MsUnLock())
						Else
							RecLock((mvAlPltInt),.T.)
							(mvAlPltInt)->INT_DIRECA := _aTmpPltInt[_nPltInt][9]
							(mvAlPltInt)->INT_ENDORI := Transf(AllTrim(_cTmpEndere),"@R 99.A.99.99.99999")
							(mvAlPltInt)->INT_ORDEM  := SubStr(_cTmpEndere,1,2) + SubStr(_cTmpEndere,4,2) + SubStr(_cTmpEndere,3,1) + SubStr(_cTmpEndere,8,5) + SubStr(_cTmpEndere,6,2) + ".02" // organiza os dados por (rua, predio, lado, posicao, andar)
							(mvAlPltInt)->INT_QTD    := _aTmpPltInt[_nPltInt][2]
							(mvAlPltInt)->(MsUnLock())
						EndIf

						// atualiza os enderecos de servico
						If ( aScan(_aEndServ,{|x| (x[1] == _cTmpEndere) }) == 0 )

							// atualiza vetor
							aAdd(_aEndServ, { _cTmpEndere , (_cNewAlQry)->DSC_OPER } )

							// para query
							_cEndServ += AllTrim(_cTmpEndere) + "|"

						EndIf

					Next _nPltInt

				EndIf

			EndIf

			// palete disponivel
			_lPltDisponivel := .T.

			// padroniza o tamanho do campo
			_cTmpEndere := PadR(_aTmpPltDisp[_nPltDisp][1],_nTamEndere)

			// atualiza os enderecos de servico
			If ( aScan(_aEndServ,{|x| (x[1] == _cTmpEndere) }) == 0 )

				// atualiza vetor
				aAdd(_aEndServ, { _cTmpEndere , (_cNewAlQry)->DSC_OPER } )

				// para query
				_cEndServ += AllTrim(_cTmpEndere) + "|"

			EndIf

		Next _nPltDisp

		// proximo OS/item
		dbSelectArea(_cNewAlQry)
		(_cNewAlQry)->(dbSkip())
	EndDo

	// atualiza os produtos da feira
	_aPrdFeira := sfARetFeira()

	// quando nao ha dados, inclui linha em branco
	If (Len(_aColsOS) == 0)
		aAdd(_aColsOS,{ "",;
		"",;
		"",;
		"",;
		"",;
		"",;
		"",;
		"",;
		"",;
		"",;
		"",;
		"",;
		"",;
		.F.	 })
	EndIf

	// fecha a query
	dbSelectArea(_cNewAlQry)
	dbCloseArea()

	// verifica se deve posiciona no primeiro registro OU posicao inicial
	IIf(_lFirstRec, (mvAlPltRec)->(dbGoTop()), RestArea(_aAreaRec))
	IIf(_lFirstExp, (mvAlPltExp)->(dbGoTop()), RestArea(_aAreaExp))
	IIf(_lFirstInt, (mvAlPltInt)->(dbGoTop()), RestArea(_aAreaInt))

	// foco no objeto
	If (_lPltDisponivel)
		mvObjGetPlt:SetFocus()
	EndIf

	// ordem ds dados das ruas disponiveis para expedicao
	aSort(_aRuaDisp,,, {|x,y| x < y })

Return(.T.)

// ** funcao para selecionar um palete no endereco selecionado
Static Function sfPegaPalete()

	// controle de confirmacao da tela
	local _lFixaWnd := .F.
	// variavel de retorno
	local _lRet := .F.
	// objetos locais
	local _oWndPegaPlt
	local _oPnPgPltCb, _oPlPgPltEnd, _oPnPgPltBrw, _oPnPgPltRod
	local _oBmpCancMov, _oBmpOpcoes
	local _oGetEtiqPlt
	local _oBrwPltEnd

	// sub-menu
	local _oMnuOpcoes := nil
	local _oSbMnOpc1 := nil
	local _oSbMnOpc2 := nil

	// variaveis do browse
	local _aHeadPlt := {}
	local _aColsPlt := sfRetPltEnd()

	// posicao do campo de reservao
	local _nP_Reserv := 0

	// define campos do browse de kit montados
	aAdd(_aHeadPlt,{"Quant"       ,"Z16_SALDO" , PesqPict("Z16","Z16_SALDO") , TamSx3("Z16_SALDO")[1] , TamSx3("Z16_SALDO")[2] ,Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHeadPlt,{"Etiqueta"    ,"Z16_ETQPRD", PesqPict("Z16","Z16_ETQPRD"), TamSx3("Z16_ETQPRD")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPlt,{"Descricao"   ,"B1_DESC"   , PesqPict("SB1","B1_DESC")   , TamSx3("B1_DESC")[1]   , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPlt,{"Produto"     ,"B1_COD"    , PesqPict("SB1","B1_COD")    , TamSx3("B1_COD")[1]    , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPlt,{"Lote"        ,"Z16_LOTCTL", PesqPict("Z16","Z16_LOTCTL"), TamSx3("Z16_LOTCTL")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadPlt,{"Dt Valid"    ,"Z16_VLDLOT", PesqPict("Z16","Z16_VLDLOT"), TamSx3("Z16_VLDLOT")[1], 0                      ,Nil,Nil,"D",Nil,"R",,,".F." })
	aAdd(_aHeadPlt,{"Quant Seg UM","Z16_QTSEGU", PesqPict("Z16","Z16_QTSEGU"), TamSx3("Z16_QTSEGU")[1], TamSx3("Z16_QTSEGU")[2],Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHeadPlt,{"Reserva"     ,"ETQ_RESERV", ""                          , 3                      , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." }) ; _nP_Reserv := Len(_aHeadPlt)

	// sub-itens do menus
	_oMnuOpcoes := TMenu():New(0,0,0,0,.T.)
	// adiciona itens no Menu

	// -- CONSULTAR DETALHES DA OS
	_oSbMnOpc1 := TMenuItem():New(_oMnuOpcoes,"Cons. Detalhe OS",,,,{|| U_ACDA002B(_cNumOrdSrv, _cSeqOrdSrv,.F.) },,"NOTE",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc1)

	// apresenta tela para selecionar o palete do endereco informado
	_oWndPegaPlt := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Apanhe de Palete",,,.F.,,,,,,.T.,,,.T. )
	_oWndPegaPlt:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnPgPltCb := TPanel():New(000,000,nil,_oWndPegaPlt,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnPgPltCb:Align:= CONTROL_ALIGN_TOP

	// -- BOTAO COM MAIS OPCOES
	_oBmpOpcoes := TBtnBmp2():New(000,000,060,040,"SDUAPPEND",,,,{|| Nil },_oPnPgPltCb,"",,.T.)
	_oBmpOpcoes:Align := CONTROL_ALIGN_LEFT
	_oBmpOpcoes:SetPopupMenu(_oMnuOpcoes)

	// -- CANCELAR MOVIMENTO
	_oBmpCancMov := TBtnBmp2():New(000,000,040,040,"ESTOMOVI",,,,{|| _lRet := .F., _lFixaWnd := .T., _oWndPegaPlt:End()  },_oPnPgPltCb,"Canc.Movim.",,.T.)
	_oBmpCancMov:Align := CONTROL_ALIGN_RIGHT

	// panel com a informacao do endereco atual
	_oPlPgPltEnd := TPanel():New(000,000,nil,_oWndPegaPlt,,.F.,.F.,,CLR_LIGHTGRAY,13,13,.T.,.F.)
	_oPlPgPltEnd:Align:= CONTROL_ALIGN_TOP
	_oPlPgPltEnd:oFont := _oFnt05
	_oPlPgPltEnd:cCaption := "End. Atual: "+Transf(_cEndAtual,"@R 99.A.99.99.99999")

	// cria o panel para o browse
	_oPnPgPltBrw := TPanel():New(000,000,nil,_oWndPegaPlt,,.F.,.F.,,,300,400,.T.,.F.)
	_oPnPgPltBrw:Align:= CONTROL_ALIGN_ALLCLIENT

	// monta o browse com a lista de produtos no endereco
	_oBrwPltEnd := MsNewGetDados():New(000,000,400,400,,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsPlt),'AllwaysTrue()','','AllwaysTrue()',_oPnPgPltBrw,_aHeadPlt,_aColsPlt)
	_oBrwPltEnd:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwPltEnd:oBrowse:SetBlkBackColor({|| IIF(_oBrwPltEnd:aCols[_oBrwPltEnd:nAt][_nP_Reserv] == "SIM", CLR_YELLOW, CLR_WHITE) })

	// cria o panel para leitura do palete solicitado
	_oPnPgPltRod := TPanel():New(000,000,nil,_oWndPegaPlt,,.F.,.F.,,CLR_LIGHTGRAY,22,22,.T.,.F.)
	_oPnPgPltRod:Align:= CONTROL_ALIGN_BOTTOM

	// leitura de etiqueta do palete
	_oGetEtiqPlt := TGet():New(001,005,{|u| If(PCount()>0,_cIdPalete:=u,_cIdPalete)},_oPnPgPltRod,050,010, "@!", {|| (Vazio()) .Or. (sfVldIdPlt(@_lRet, _oWndPegaPlt, @_lFixaWnd)) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIdPalete",,,,,,,"Selecione um Palete",1)

	// seta o foco no id palete
	_oGetEtiqPlt:SetFocus()

	// ativa a tela
	_oWndPegaPlt:Activate(,,,.F.,{|| _lFixaWnd },,)

Return(_lRet)

// ** funcao para validar o palete no endereco de origem (para EXPEDICAO)
Static Function sfVldIdPlt(mvContProc, mvWndOrig, mvFechaTela)
	// variavel de retorno
	local _lRet := .T.
	// query
	local _cQuery

	// novo palete gerado
	local _cNovoPltFra := Space(_nTamIdEtq)

	// conteudo a ser retidado do palete (desmontagem)
	local _aItemRet := {}

	// tentativas de localizar etiqueta
	local _nTent

	// variaveis temporarias
	local _cTmpEtique

	// encontrou registro no cadastro de etiquetas
	local _lAchouEtq := .F.

	// pesquisa se a etiqueta é valida
	If (_lRet)

		// faz 2 tentativas de busca da etiqueta
		For _nTent := 1 to 2

			// se encontrou, sai do Loop
			If (_lAchouEtq)
				Exit
			EndIf

			// tentativa 1 - Cod Etiqueta Interna
			If (_nTent == 1)

				// padroniza tamanho da pesquisa
				_cTmpEtique := PadR(_cIdPalete, Len(Z11->Z11_CODETI))

				// cadastro de etiquetas
				dbSelectArea("Z11")
				Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
				If Z11->(dbSeek( xFilial("Z11") + _cTmpEtique )) .And. (Z11->Z11_TIPO != "07")
					_lAchouEtq := .T.
				EndIf

				// tentativa 2 - Cod Etiqueta Cliente
			ElseIf (_nTent == 2)

				// padroniza tamanho da pesquisa
				_cTmpEtique := PadR(_cIdPalete, Len(Z11->Z11_ETIQUE))

				// cadastro de etiquetas
				dbSelectArea("Z11")
				Z11->(dbSetOrder(2)) // 1 - Z11_FILIAL, Z11_ETIQUE, Z11_CLIENT
				If Z11->(dbSeek( xFilial("Z11") + _cTmpEtique )) .And. (Z11->Z11_TIPO == "07")
					_lAchouEtq := .T.
				EndIf

			EndIf

		Next _nTent

		// tratamento do retorno
		If ( ! _lAchouEtq )
			// mensagem
			U_FtWmsMsg("Identificador do palete inválido!", "ATENCAO")
			// variavel de controle
			_lRet := .F.
		EndIf

	EndIf

	// valida o tipo da etiqueta lida
	If (_lRet) .And. (Z11->Z11_TIPO != "03")
		// verifica se eh etiqueta de produto
		If (Z11->Z11_TIPO == "01") .Or. (Z11->Z11_TIPO == "04") .Or. (Z11->Z11_TIPO == "07") // 01 - etiqueta de produto | 04 - etiqueta agrupadora | 07 - Etiqueta do Cliente
			// pesquisa um palete
			_cIdPalete := sfRetNrPalete(_cIdPalete, Z11->Z11_TIPO)
			// valida se encontrou o palete
			_lRet := (!Empty(_cIdPalete))
			// se encontrou, reposiciona
			If (_lRet)
				dbSelectArea("Z11")
				Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
				If ! Z11->(dbSeek( xFilial("Z11") + _cIdPalete ))
					U_FtWmsMsg("Identificador do palete inválido!","ATENCAO")
					_lRet := .F.
				EndIf
			EndIf
		Else
			U_FtWmsMsg("Tipo de etiqueta inválida!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// define o codigo do unitizador
	If (_lRet)
		_cCodUnit := Z11->Z11_UNITIZ
	EndIf

	If (_lRet)

		If (_lOSRec) // paletes disponiveis para RECEBIMENTO/ARMAZENAGEM
			_cQuery := "SELECT DISTINCT Z05_TPOPER, Z07_NUMOS NUM_OS, Z07_SEQOS SEQ_OS, Z16_ETQPAL ETQ_PLT, Z07_LOCAL ARMAZEM, Z16_ENDATU END_ATU, "
			_cQuery += "CASE WHEN Z16_ETQVOL <> '' AND Z16_CODKIT <> '' THEN Z16_CODKIT ELSE Z16_CODPRO END COD_PROD "
			// formacao de paletes
			_cQuery += " FROM "+RetSqlTab("Z16")+" (nolock) "

			// paletes conferidos no recebimento
			_cQuery += " INNER JOIN "+RetSqlTab("Z07")+" (nolock)  ON "+RetSqlCond("Z07")+" AND Z07_PALLET = Z16_ETQPAL AND Z07_STATUS = 'D' "
			// filtro por numero de OS (alterado para CHARINDEX, pois sub-query e IN perde performance)
			_cQuery += " AND CHARINDEX(Z07_NUMOS, '"+_cQryChrIn+"') > 0 "

			// cab. da OS
			_cQuery += "INNER JOIN "+RetSqlTab("Z05")+" (nolock)  ON "+RetSqlCond("Z05")+" AND Z05_NUMOS  = Z07_NUMOS "

			// somente operacao de E=Entrada
			_cQuery += "AND Z05_TPOPER = 'E' "

			// filtro padrao
			_cQuery += "WHERE " + RetSqlCond("Z16")

			// filtra o ID do palete / ou palete em branco na DOCA de origem
			_cQuery += " AND Z16_ETQPAL = '" + _cIdPalete + "' "
			// filtra endereco atual
			_cQuery += " AND Z16_ENDATU = '" + _cEndOrige + "' "
			// filtra somente no endereco de servico que o usuario tem acesso
			_cQuery += " AND Z16_ENDATU IN " + FormatIn(_cEndServ, "|")

		ElseIf (_lOSExp) .Or. (_lOSInt) // paletes disponiveis para EXPEDICAO ou INTERNA
			_cQuery := " SELECT DISTINCT Z05_TPOPER, Z08_NUMOS NUM_OS, Z08_SEQOS SEQ_OS, "
			_cQuery += "  CASE "
			_cQuery += "  WHEN Z08_FRAPLT = 'S' AND Z08_NEWPLT != ' ' "
			_cQuery += "  THEN Z08_NEWPLT  "
			_cQuery += "  ELSE Z16_ETQPAL END ETQ_PLT, "
			_cQuery += "  Z08_LOCAL ARMAZEM, Z16_ENDATU END_ATU, "
			_cQuery += "  Z16_CODPRO COD_PROD "
			// formacao de paletes
			_cQuery += " FROM "+RetSqlTab("Z16")+" (nolock) "
			// paletes disponiveis no mapa de apanhe
			_cQuery += " INNER JOIN "+RetSqlTab("Z08")+" (nolock)  ON "+RetSqlCond("Z08")
			// status
			_cQuery += " AND Z08_STATUS = 'P' "
			// endereco atual
			_cQuery += " AND Z08_ENDSRV = '"+_cEndOrige+"' "
			// ID do palete
			_cQuery += " AND Z16_ETQPAL IN (Z08_PALLET,Z08_NEWPLT) "
			// lote
			_cQuery += " AND Z16_LOTCTL = Z08_LOTCTL "

			// cab. da OS
			_cQuery += " INNER JOIN "+RetSqlTab("Z05")+" (nolock)  ON "+RetSqlCond("Z05")+" AND Z05_NUMOS = Z08_NUMOS "
			// somente operacao de S=Saida / I=Interna
			_cQuery += " AND Z05_TPOPER IN ('S','I') "
			// filtro por numero de OS (alterado para CHARINDEX, pois sub-query e IN perde performance)
			_cQuery += " AND CHARINDEX(Z05_NUMOS, '"+_cQryChrIn+"') > 0 "

			// filtro padrao
			_cQuery += " WHERE " + RetSqlCond("Z16")

			// filtra o ID do palete / ou palete em branco na DOCA de origem
			_cQuery += " AND Z16_ETQPAL = '" + _cIdPalete + "' "
			// filtra endereco atual
			_cQuery += " AND Z16_ENDATU = '" + _cEndOrige + "' "
			// filtra somente no endereco de servico que o usuario tem acesso
			_cQuery += " AND Z16_ENDATU IN " + FormatIn(_cEndServ, "|")

			// filtra somente no endereco que o equipamento pode trabalhar
			_cQuery += " AND " + StrTran(_cQryEndEq, "CMP_ENDSRV", "Z16_ENDATU")

		EndIf

		memowrit("c:\query\twmsa011_sfVldIdPlt1.txt",_cQuery)

		// atualiza a variavel temporaria
		_aTmpPalete := U_SqlToVet(_cQuery)

		// mensagem de validacao se encontrou o palete
		If (Len(_aTmpPalete) == 0)
			U_FtWmsMsg("Palete não disponível!","ATENCAO")
			_lRet := .F.

		ElseIf (Len(_aTmpPalete)  > 0)
			// define o tipo da operacao da OS (E-Ent/S-Sai/I-Int)
			_cTipoOper := _aTmpPalete[1][1]
			// numero e sequencial da OS
			_cNumOrdSrv := _aTmpPalete[1][2]
			_cSeqOrdSrv := _aTmpPalete[1][3]

			// codigo do produto no palete
			_cCdProdPlt := _aTmpPalete[1][7]

		EndIf

	EndIf

	// pesquisa enderecos disponiveis para o destino
	If (_lRet)

		// monta a query pra buscar os dados
		_cQuery := " SELECT Z08.R_E_C_N_O_ Z08RECNO, Z08_LOCAL, Z08_ENDDES, "
		_cQuery += "  CASE "
		_cQuery += "  WHEN Z08_FRAPLT = 'S' AND Z08_NEWPLT != ' ' "
		_cQuery += "  THEN Z08_NEWPLT  "
		_cQuery += "  ELSE Z08_PALLET END Z08_PALLET, "
		_cQuery += "  Z06_ATUEST "
		// itens da ordem de servico
		_cQuery += " FROM "+RetSqlTab("Z06")+" (nolock) "
		// cab. da OS
		_cQuery += " INNER JOIN "+RetSqlTab("Z05")+" (nolock)  ON "+RetSqlCond("Z05")+" AND Z05_NUMOS = Z06_NUMOS "
		// itens conferidos
		_cQuery += " INNER JOIN "+RetSqlTab("Z08")+" (nolock)  ON "+RetSqlCond("Z08")+" AND Z08_NUMOS = Z06_NUMOS AND Z08_SEQOS = Z06_SEQOS "
		// numero de contagens
		_cQuery += " AND Z08_NRCONT = Z06_NRCONT "
		// somente itens pendentes
		_cQuery += " AND Z08_DTFINA = ' ' "
		// itens planejados
		_cQuery += " AND Z08_STATUS = 'P' "

		// filtra pelo codigo do endereco OU palete (somente no endereco de transacao)
		_cQuery += " AND ( "
		// adicionei parte de sql pra pegar o id do new pallet
		_cQuery += "       (Z08_FRAPLT = 'N' AND Z08_PALLET = '"+_cIdPalete+"') "
		_cQuery += "        OR "
		_cQuery += "       (Z08_FRAPLT = 'S' AND Z08_NEWPLT != ' ' AND Z08_NEWPLT = '"+_cIdPalete+"') "
		_cQuery += "        OR "
		_cQuery += "       (Z08_FRAPLT = 'S' AND Z08_NEWPLT  = ' ' AND Z08_PALLET = '"+_cIdPalete+"') "
		_cQuery += "     ) "

		// filtra pelo endereco de servico/origem
		_cQuery += " AND Z08_ENDSRV = '"+_cEndOrige+"' "
		// filtra endereco reservado para o produto do palete
		_cQuery += " AND Z08_PRODUT IN (SELECT DISTINCT Z16_CODPRO FROM "+RetSqlTab("Z16")+" (nolock)  WHERE "+RetSqlCond("Z16")+" AND Z16_ETQPAL = '"+_cIdPalete+"' "
		_cQuery += "                    AND Z16_LOCAL = Z08_LOCAL AND Z16_ENDATU = Z08_ENDSRV) "

		// insere o filtro padrao do usuario/operador
		_cQuery += " WHERE "+cQryFilZ06
		// filtro do numero da OS
		_cQuery += " AND Z06_NUMOS = '"+_cNumOrdSrv+"' "//AND Z06_SEQOS = '"+_cSeqOrdSrv+"' "

		// filtra somente no endereco que o equipamento pode trabalhar
		_cQuery += " AND "+StrTran(_cQryEndEq,"CMP_ENDSRV","Z08_ENDSRV")+" "

		// ordem dos dados
		_cQuery += " ORDER BY SUBSTRING(Z08_ENDDES,1,2), SUBSTRING(Z08_ENDDES,4,2), SUBSTRING(Z08_ENDDES,3,1), SUBSTRING(Z08_ENDDES,8,5), SUBSTRING(Z08_ENDDES,6,2) "

		memowrit("c:\query\twmsa011_sfVldIdPlt2.txt",_cQuery)

		// alimenta variavel temporaria
		_aLinhaZ08 := U_SqlToVet(_cQuery)

		// verifica se encontrou o pallet
		If (Len(_aLinhaZ08) == 0)
			U_FtWmsMsg("Identificador do palete não encontrado no mapa de armazenagem/expedição!","ATENCAO")
			// variavel de retorno
			_lRet := .F.
		EndIf

		// valida se retornou resultados e tem alguma coisa na feirinha
		If  ( Len(_aPrdFeira) > 0 ) .AND. ( Len(_aLinhaZ08) > 0 )
			// valida se o endereço destino do pallet bipado é o mesmo da coleta atual (feirinha) caso esteja em processo de apanhe
			If (_aPrdFeira[1][2] != _aLinhaZ08[1][3] )
				U_FtWmsMsg("O endereço destino deste pallet/volume é diferente do que a coleta atual. Descarregue seu pallet e tente novamente.")
				_lRet := .F.
			EndIf
		EndIf
	EndIf

	// se encontrou os dados do palete, posiciona no registro do mapa
	If (_lRet)

		// atualiza o RECNO do Z08
		_nRecnoZ08 := _aLinhaZ08[1][1]

		// posiciona no registro da tabela
		dbSelectArea("Z08")
		Z08->(dbGoTo( _nRecnoZ08 ))

		// sequencial da OS
		_cSeqOrdSrv := Z08->Z08_SEQOS

		// atualiza os dados para movimentacao
		RecLock("Z08")
		Z08->Z08_DTINIC := Date()
		Z08->Z08_HRINIC := Time()
		Z08->Z08_STATUS := "M" // P-Planejado / R-Realizado / M-Movimento / E-Erro
		Z08->Z08_USUARI := _cCodOper
		Z08->Z08_EQUIPA := _cCodEquip
		// no recebimento, atualiza o ID do palete
		If (_lOSRec)
			Z08->Z08_PALLET := _cIdPalete
			Z08->Z08_LOTCTL := sfLotPalet(_cIdPalete)
		EndIf
		Z08->(MsUnLock())

		// variaveis contendo a data e hora pra comparação posterior
		_cDtIni := Z08->Z08_DTINIC
		_cHrIni := Z08->Z08_HRINIC

	EndIf

	// atualiza variavel do endereco de destino e a movimento do item conferido
	If (_lRet)

		// atualiza o endereco de destino
		_cEndDesti := sfRetEndDest(Z08->Z08_ENDDES, Z08->Z08_ENDTRA)

		// OS de recebimento
		If (_lOSRec)

			// atualiza o status do palete para M-EM MOVIMENTO
			_cQuery := "UPDATE "+RetSqlName("Z07")+" "
			_cQuery += "SET Z07_STATUS = 'M' "
			// filtros
			_cQuery += "WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND D_E_L_E_T_ = ' ' "
			_cQuery += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"' " //AND Z07_SEQOS = '"+_cSeqOrdSrv+"' "
			_cQuery += "AND Z07_PALLET = '"+_cIdPalete+"' "
			_cQuery += "AND Z07_STATUS = 'D' "
			// executa o update
			TcSQLExec(_cQuery)

		EndIf

	EndIf

	// atualiza a quantidade de leitura
	If (_lRet)
		RecLock("Z11")
		Z11->Z11_QTDLEI += 1
		Z11->(MsUnLock())

		// posiciona na OS
		dbSelectArea("Z05")
		Z05->(dbSetOrder(1)) //1-Z05_FILIAL, Z05_NUMOS
		Z05->(dbSeek( xFilial("Z05")+_cNumOrdSrv ))

		// define o tipo da operacao da OS (E-Ent/S-Sai/I-Int)
		_cTipoOper := Z05->Z05_TPOPER

		// posiciona no item da OS
		dbSelectArea("Z06")
		Z06->(dbSetOrder(1)) //1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
		Z06->(dbSeek( xFilial("Z06")+_cNumOrdSrv+_cSeqOrdSrv ))

		// gera registro de movimentacao
		dbSelectArea("Z17")
		RecLock("Z17",.T.)
		Z17->Z17_FILIAL	:= xFilial("Z17")
		Z17->Z17_ETQPLT := _cIdPalete
		Z17->Z17_ENDORI	:= _cEndOrige
		//Z17->Z17_ENDDES Preenchido no final da movimentação - Pesquise por END_DES_Z17 - David 10/03/16
		Z17->Z17_DTINI	:= Date()
		Z17->Z17_HRINI	:= Time()
		Z17->Z17_OPERAD	:= _cCodOper
		Z17->Z17_EQUIPA	:= _cCodEquip
		Z17->Z17_NUMOS	:= Z08->Z08_NUMOS
		Z17->Z17_SEQOS	:= Z08->Z08_SEQOS
		Z17->Z17_STATUS := "M"  // R=Realizado / C=Cancelado / M=Em Movimento
		Z17->Z17_TIPLAN := "NM" // NM=Normal / ES=Estorno / AJ=Ajuste / DV=Devolução / FR=Fracionamento / DF=Dev. Fracion.
		Z17->Z17_ORILAN := "A"  // A=Automática / M=Manual
		Z17->Z17_LOCORI := Z08->Z08_LOCAL
		Z17->Z17_LOCDES := Z08->Z08_LOCDES
		Z17->(MsUnLock())

		// gravo recno para validar o tipo de movimento
		_nRecnoZ17 := Z17->( Recno() )

	EndIf

	// variavel de retorno para continuacao do processo
	mvContProc := _lRet

	// se existir o objeto, fecha
	If (mvWndOrig <> nil) .And. (_lRet)
		// permite fechar a tela
		mvFechaTela := .T.
		// fecha a tela
		mvWndOrig:End()
	EndIf

Return(_lRet)

// ** funcao para desmontar um palete
Static Function sfDesmPalete(mvIdPalete, mvItemRet, mvNovoPltFra)
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z05","Z08","Z17"})

	// controle de confirmacao da tela
	local _lFixaWnd := .F.

	// variavel de retorno
	local _lRet := .F.

	// etiqueta do produto
	local _cIdEtqProd := Space(_nTamIdEtq)

	// objetos locais
	local _oWndDesmPlt
	local _oPnDesm01, _oPnDesm02
	local _oBmpDesmOk, _oBmpDesmSair, _oBmpDesmInic
	local _oSayEtiqueta
	local _oGetIdEtiq
	local _oBrwItmRet, _oBrwPltAtu, _oBrwNewPlt
	local _oFolder

	// seek Z16
	local _cSeekZ16

	// seek do Z17
	local _cSeekZ17

	// desmontagem de palete iniciado
	local _lDesmInic := .F.

	// variaveis dos browser's
	local _aHeadPlt := {;
	{"Quant."     , "IT_QUANT"  , "", 5                      , 0,Nil,Nil,"N",Nil,"R",,,".F."},;
	{"Produto"    , "IT_PRODUTO", "", TamSx3("B1_COD")[1]    , 0,Nil,Nil,"C",Nil,"R",,,".F."},;
	{"Descrição"  , "IT_DESCRIC", "", TamSx3("B1_DESC")[1]   , 0,Nil,Nil,"C",Nil,"R",,,".F."},;
	{"NumSeq"     , "IT_NUMSEQ" , "", TamSx3("D1_NUMSEQ")[1] , 0,Nil,Nil,"C",Nil,"R",,,".F."},;
	{"Etq.Produto", "IT_ETQPRD" , "", TamSx3("Z11_CODETI")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."},;
	{"Etq.Origem" , "IT_PRDORI" , "", TamSx3("Z11_CODETI")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."},;
	{"Tp.Estoque" , "IT_TPESTO" , "", TamSx3("Z16_TPESTO")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."},;
	{"Lote"       , "IT_LOTECTL", "", TamSx3("Z16_LOTCTL")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."},;
	{"Dt.Validade", "IT_VLDLOT" , "", TamSx3("Z16_VLDLOT")[1], 0,Nil,Nil,"D",Nil,"R",,,".F."} }
	// itens do browse
	local _aItmPltAtu := sfRetCompPlt(mvIdPalete)
	local _aItmNewPlt := {{0, "", "", "", "", "", "", "", CtoD("//"), .F.}}

	// header do browse de itens a retirar
	local _aHeadItRet := {;
	{"Quant."     , "IT_QUANT"  , "", 5                      , 0,Nil,Nil,"N",Nil,"R",,,".F."},;
	{"Separado"   , "IT_QTDSEP" , "", 5                      , 0,Nil,Nil,"N",Nil,"R",,,".F."},;
	{"Produto"    , "IT_PRODUTO", "", TamSx3("B1_COD")[1]    , 0,Nil,Nil,"C",Nil,"R",,,".F."},;
	{"Descrição"  , "IT_DESCRIC", "", TamSx3("B1_DESC")[1]   , 0,Nil,Nil,"C",Nil,"R",,,".F."},;
	{"NumSeq"     , "IT_NUMSEQ" , "", TamSx3("D1_NUMSEQ")[1] , 0,Nil,Nil,"C",Nil,"R",,,".F."},;
	{"Tp.Estoque" , "IT_TPESTO" , "", TamSx3("Z16_TPESTO")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."},;
	{"Lote"       , "IT_LOTECTL", "", TamSx3("Z16_LOTCTL")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."},;
	{"Dt.Validade", "IT_VLDLOT" , "", TamSx3("Z16_VLDLOT")[1], 0,Nil,Nil,"D",Nil,"R",,,".F."} }
	local _aColsItRet := sfPadItmRet(mvItemRet)

	// vetor com os dados completos do novo palete
	local _aCompNewPlt := {}
	local _nX

	// pastas do FOLDER
	local _aFolders := {'Retirar', 'Palete Atual', 'Novo Palete'}

	// tenta reserva completa do palete
	While ( ! sfLockPlt(mvIdPalete) )
		Sleep(3000)
		Loop
	EndDo

	// posiciona na OS
	dbSelectArea("Z05")
	Z05->(dbSetOrder(1)) //1-Z05_FILIAL, Z05_NUMOS
	Z05->(dbSeek( xFilial("Z05") + Z08->Z08_NUMOS ))

	// apresenta tela para desmontar um palete
	_oWndDesmPlt := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Desmontar Palete",,,.F.,,,,,,.T.,,,.T. )
	_oWndDesmPlt:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnDesm01 := TPanel():New(000,000,nil,_oWndDesmPlt,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnDesm01:Align:= CONTROL_ALIGN_TOP

	// -- INICIAR DESMONTAGEM DE PALETE
	_oBmpDesmInic := TBtnBmp2():New(000,000,040,040,"CFGIMG32",,,,{|| _lDesmInic := sfInicDesm(@_oBmpDesmInic, @_oBmpDesmOk, @_oBmpDesmSair, @_oGetIdEtiq) },_oPnDesm01,"Iniciar...",,.T.)
	_oBmpDesmInic:Align := CONTROL_ALIGN_LEFT
	_oBmpDesmInic:lVisible := ( ! _lDesmInic)

	// -- CONFIRMACAO
	_oBmpDesmOk := TBtnBmp2():New(000,000,040,040,"OK",,,,{|| IIf(_lRet := sfVldDesmPlt(_oBrwItmRet,_oBrwNewPlt,@_lFixaWnd),_oWndDesmPlt:End(),Nil) },_oPnDesm01,"Ok",,.T.)
	_oBmpDesmOk:Align := CONTROL_ALIGN_LEFT
	_oBmpDesmOk:lVisible := (_lDesmInic)

	// -- FECHAR A TELA
	_oBmpDesmSair := TBtnBmp2():New(000,000,040,040,"FINAL",,,,{|| _lFixaWnd := .T., _oWndDesmPlt:End() },_oPnDesm01,"Sair",,.T.)
	_oBmpDesmSair:Align := CONTROL_ALIGN_RIGHT
	_oBmpDesmSair:lVisible := ( ! _lDesmInic )

	// pastas com as opcoes de visualizacao
	_oFolder := TFolder():New(000,000,_aFolders,,_oWndDesmPlt,,,,.T.,,100,200)
	_oFolder:Align:= CONTROL_ALIGN_ALLCLIENT

	// 1a PASTA - cria o panel para leitura da etiqueta
	_oPnDesm02 := TPanel():New(000,000,nil,_oFolder:aDialogs[1],,.F.,.F.,,CLR_LIGHTGRAY,200,14,.T.,.F.)
	_oPnDesm02:Align:= CONTROL_ALIGN_TOP

	// 1A PASTA - leitura de etiqueta (palete ou endereco de origem)
	_oSayEtiqueta := TSay():New(003,005,{||"Informe a nova Etiqueta"},_oPnDesm02,,,.F.,.F.,.F.,.T.)
	_oGetIdEtiq := TGet():New(001,070,{|u| If(PCount()>0,_cIdEtqProd:=u,_cIdEtqProd)},_oPnDesm02,050,010,_cMskEtiq,{|| sfVldProd(@_cIdEtqProd, mvIdPalete, @_aCompNewPlt, @_aItmNewPlt, @_oBrwNewPlt, @_oGetIdEtiq, @_oBrwItmRet, _aItmPltAtu, Z05->Z05_CLIENT) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIdEtqProd",,)
	_oGetIdEtiq:bWhen := {|| _lDesmInic }

	// 1a PASTA - browse com os itens a serem retirados
	_oBrwItmRet := MsNewGetDados():New(000,000,200,200,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsItRet),'AllwaysTrue()','','AllwaysTrue()',_oFolder:aDialogs[1],_aHeadItRet,_aColsItRet)
	_oBrwItmRet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// 2a PASTA - browse com os itens do palete origem / atual
	_oBrwPltAtu := MsNewGetDados():New(000,000,200,200,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aItmPltAtu),'AllwaysTrue()','','AllwaysTrue()',_oFolder:aDialogs[2],_aHeadPlt,_aItmPltAtu)
	_oBrwPltAtu:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// 3a PASTA - browse com os itens do novo palete
	_oBrwNewPlt := MsNewGetDados():New(000,000,200,200,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aItmNewPlt),'AllwaysTrue()','','AllwaysTrue()',_oFolder:aDialogs[3],_aHeadPlt,_aItmNewPlt)
	_oBrwNewPlt:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	_oWndDesmPlt:Activate(,,,.F.,{|| _lFixaWnd },,)

	// controle de confirmacao para geracao do novo palete
	If (_lRet)

		// inicia transacao
		BEGIN TRANSACTION

			// posiciona na OS
			dbSelectArea("Z05")
			Z05->(dbSetOrder(1)) //1-Z05_FILIAL, Z05_NUMOS
			Z05->(dbSeek( xFilial("Z05") + Z08->Z08_NUMOS ))

			// funcao generica para geracao do Id Palete
			_cIdNewPalete := U_FtGrvEtq("03",{_cUnitPdr, Z05->Z05_CARGA})
			// define o codigo do unitizador
			_cCodUnit := Z11->Z11_UNITIZ

			// grava o novo palete
			For _nX := 1 to Len(_aCompNewPlt)

				dbSelectArea("Z16")
				RecLock("Z16", .T.)
				Z16->Z16_FILIAL := xFilial("Z16")
				Z16->Z16_ETQPAL := _cIdNewPalete
				Z16->Z16_UNITIZ := Z11->Z11_UNITIZ // direto do registro posicionado
				Z16->Z16_ETQPRD := _aCompNewPlt[_nX][2]
				Z16->Z16_CODPRO := _aCompNewPlt[_nX][3]
				Z16->Z16_NUMSEQ := _aCompNewPlt[_nX][4]
				Z16->Z16_QUANT  := _aCompNewPlt[_nX][5]
				Z16->Z16_QTDVOL := _aCompNewPlt[_nX][5]
				Z16->Z16_SALDO  := _aCompNewPlt[_nX][5]
				Z16->Z16_QTSEGU := _aCompNewPlt[_nX][6]
				Z16->Z16_TPESTO := _aCompNewPlt[_nX][8]
				Z16->Z16_STATUS := "P" // P=Parcial / T=Total / V-Vazio
				Z16->Z16_ENDATU := Z08->Z08_ENDTRA
				Z16->Z16_ORIGEM := "FRA"
				Z16->Z16_PLTORI := mvIdPalete
				Z16->Z16_LOCAL  := Z08->Z08_LOCAL
				Z16->Z16_DATA   := Date()
				Z16->Z16_HORA   := Time()
				Z16->Z16_PRDORI := _aCompNewPlt[_nX][7]
				Z16->Z16_LOTCTL := _aCompNewPlt[_nX][9]
				Z16->Z16_VLDLOT := _aCompNewPlt[_nX][10]
				Z16->(MsUnLock())

				// atualiza o saldo do palete original
				dbSelectArea("Z16")
				Z16->(dbOrderNickName("Z16_ETQPAL")) // 1-Z16_FILIAL, Z16_ETQPAL
				Z16->(dbSeek( _cSeekZ16 := xFilial("Z16") + mvIdPalete ))

				// varre todos os itens do palete
				While Z16->( ! Eof() ) .And. ((Z16->Z16_FILIAL + Z16->Z16_ETQPAL) == _cSeekZ16)
					// atualiza o saldo do produto/etiqueta
					If (Z16->Z16_CODPRO == _aCompNewPlt[_nX][3]) .And. (Z16->Z16_NUMSEQ == _aCompNewPlt[_nX][4])
						RecLock("Z16")
						Z16->Z16_SALDO  -= _aCompNewPlt[_nX][5]
						Z16->Z16_STATUS := "P" // P=Parcial / T=Total / V-Vazio
						Z16->(MsUnLock())
					EndIf
					// proximo item
					Z16->(dbSkip())
				EndDo

			Next _nX

			// finaliza transacao
		END TRANSACTION

		// atualiza o codigo do novo palete
		mvNovoPltFra := _cIdNewPalete

		// se foi cancelado
	ElseIf ( ! _lRet)

		// atualiza o status para cancelado
		dbSelectArea("Z17")
		Z17->(dbSetOrder(1)) // 1-Z17_FILIAL, Z17_ETQPLT
		Z17->(dbSeek( _cSeekZ17 := xFilial("Z17")+Z08->Z08_PALLET ))
		// compara o numero da OS
		While Z17->(!Eof()) .And. (Z17->(Z17_FILIAL+Z17_ETQPLT)==_cSeekZ17)
			If (Z17->Z17_NUMOS == Z08->Z08_NUMOS) .And. (Z17->Z17_SEQOS == Z08->Z08_SEQOS) .And. (Empty(Z17->Z17_DTFIM)) .And. (Z17->Z17_STATUS == "M") .And. (Z17->Z17_OPERAD == _cCodOper)
				RecLock("Z17")
				Z17->Z17_STATUS := "C"
				Z17->(MsUnLock())
			EndIf
			// proximo item
			Z17->(dbSkip())
		EndDo

	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aArea)

Return(_lRet)

// ** funcao que retorna a composicao do palete
Static Function sfRetCompPlt(mvIdPalete)
	local _aRet := {}
	local _cQuery

	_cQuery := " SELECT SUM(Z16_SALDO) Z16_SALDO, Z16_CODPRO, B1_DESC, Z16_NUMSEQ, Z16_ETQPRD, Z16_PRDORI, Z16_TPESTO, Z16_LOTCTL, Z16_VLDLOT, '.F.' IT_DEL "
	// composicao do palete
	_cQuery += " FROM " + RetSqlTab("Z16") + " (nolock) "
	// cad. de produtos
	_cQuery += " INNER JOIN " + RetSqlTab("SB1") + " (nolock)  ON "+RetSqlCond("SB1")+" AND B1_COD = Z16_CODPRO "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z16")
	// filtra ID Palete
	_cQuery += " AND Z16_ETQPAL = '" + mvIdPalete + "' "
	// somente se tiver saldo
	_cQuery += " AND Z16_SALDO <> 0 "
	// group by
	_cQuery += " GROUP BY Z16_CODPRO, B1_DESC, Z16_NUMSEQ, Z16_ETQPRD, Z16_PRDORI, Z16_TPESTO, Z16_LOTCTL, Z16_VLDLOT "

	// atualiza variavel de retorno
	_aRet := U_SqlToVet(_cQuery, {"Z16_VLDLOT"})

Return(_aRet)

// ** funcao para validacao do codigo do produto digitado (lido)
Static Function sfVldProd(mvIdEtqProd, mvIdPalete, mvCompNewPlt, mvItmNewPlt, mvBrwNewPlt, mvGetIdEtiq, mvBrwItmRet, mvItmPltAtu, mvCodCli)
	local _nX
	local _nPos
	local _nPosAtu
	// controla se informa a quantidade manual
	Local _lInfQtdMan := .F.
	// controle de retorno
	local _lRet := .T.
	// num seq do documento de entrada
	local _cNumSeq := ""
	// codigo do produto
	local _cCodProd := ""
	// quantidade do produto
	local _nQtdProd  := 1
	local _nQtdSegUM := 0
	// quantidade maxima no palete
	local _nQtdMaxPalete := 0
	// descricao do produto
	local _cPrdDesc := ""
	// quantidade ja separada
	local _nQtdJaSep := 0
	Local _aRetPal := {}
	// seek do Z17
	local _cSeekZ17
	// tempo total
	local _nTempoTot := 0
	// query para validações
	local _cQuery := ""
	// tipo do estoque
	local _cTpEsto := ""
	// etiqueta de produto origem
	local _cPrdOrig := ""
	// lote
	local _cLote := ""
	// data validade
	local _dDtVldLot := CtoD("//")
	// se processo de integração de sistemas Totvs x GWS Sumitomo (Barcodes) está ativo
	local lSumiBar := U_FtWmsParam("WMS_SUMITOMO_LEITURA_BARCODE", "L", .F., .F., Nil, _cCodCliMov, _cLjCliMov, Nil, Nil)

	// atualização de etiquetas de cliente
	local _cUpd

	// valida se etiqueta foi informada
	If (Empty(mvIdEtqProd))
		//U_FtWmsMsg("É necessário informar a etiqueta do produto!","ATENCAO")
		Return(_lRet)
	EndIf

	// verifica se a etiqueta do produto lida nao é a mesma do palete atual. Obrigatorio ler nova etiqueta de fracionado
	If (_lRet) .And. ( aScan(mvItmPltAtu,{|x| (x[5] == mvIdEtqProd) }) > 0 )
		// mensagem
		U_FtWmsMsg("Etiqueta de produto não pode ser a do palete atual. Favor utilizar uma nova etiqueta em branco!", "ATENÇÃO")
		// variavel de controle
		_lRet := .F.
	EndIf

	// posiciona na etiqueta pra pegar o tipo
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ( ! Z11->(dbSeek( xFilial("Z11") + mvIdPalete )) )
			// mensagem
			U_FtWmsMsg("Etiqueta não encontrada.", "ATENCAO")
			// variavel de controle
			_lRet := .F.
		EndIf
	EndIf

	// valida se a etiqueta já está/foi utilizada
	If ( _lRet )
		_cQuery := " SELECT COUNT(*) FROM " + RetSqlTab("Z16") + " (nolock)  WHERE " + RetSqlCond("Z16") + " AND Z16_ETQPRD = '" + mvIdEtqProd + "' "

		// se possui a etiqueta em outros pallets
		If ( U_FtQuery(_cQuery) > 0 )
			// mensagem
			U_FtWmsMsg("Etiqueta já utilizada em outro pallet.", "ATENCÃO")
			// variavel de controle
			_lRet := .F.
		EndIf
	EndIf

	// transfere os dados da etiqueta antiga para a nova
	If (_lRet) .And. ( ! sfGrvNewEtq(mvIdPalete, mvIdEtqProd))  // 1 origem, 2 destino
		// variavel de retorno
		_lRet := .F.
	EndIf

	// realiza a pesquisa do produto
	If (_lRet) .And. ( ! U_FtCodBar(@mvIdEtqProd, @_cCodProd, @_lInfQtdMan, @_cNumSeq, "INTERNA", mvCodCli) )
		// variavel de retorno
		_lRet := .F.
	EndIf

	// verifica se produto está setado para leitura de barcodes Sumitomo, conforme projeto de integração GWS x Totvs 2019
	// Redmine 414
	If (_lRet) .And. (mvCodCli == '000316') .AND. (lSumiBar) .AND. (Posicione("SB1",01,xFilial("SB1")+AllTrim(_cCodProd),"B1_ZNUMSER") == "S")
		_lRet := EtqSumi(@_nQtdProd, @_nQtdSegUM, mvCodCli, _cCodProd, mvIdPalete, mvBrwItmRet:acols[1][1] - mvBrwItmRet:acols[1][2], mvIdEtqProd )
		// verifica se o produto pode informar quantidades
	ElseIf (_lRet) .And. (_lInfQtdMan)
		// tela para informar a quantidade
		sfInfQuant(@_nQtdProd, @_nQtdSegUM)
	EndIf

	// quantidade para unitizar
	If (_lRet)
		// estrutura do retorno
		// 1-Quantidade Total de Palete
		// 2-Quantidade de Paletes Cheios
		// 3-Quantidade de Paletes Fracionados
		// 4-Quantidade Maxima de SKU/Volumes por Palete
		// 5-Tipo do Calculo (Q-Quant Unitarios / P-Quant Palete Informado)
		_aRetPal := U_FtWmsNorma(_cCodProd, _cArmzAtual, Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)

		// atualiza variavel de controle de acordo com o calculo da funcao FtWmsNorma
		_nQtdMaxPalete := _aRetPal[4]
	EndIf

	// se validou e a quantidade foi informada
	If (_lRet) .And. (_nQtdProd > 0)

		// pesquisa dados do palete atual, que a mercadoria esta sendo retidada
		_nPosAtu := aScan(mvItmPltAtu,{|x| (x[2] == _cCodProd) .And. (x[4] == _cNumSeq)  })

		// atualiza tipo de estoque
		If (_nPosAtu != 0)
			_cPrdOrig  := mvItmPltAtu[_nPosAtu][5]
			_cTpEsto   := mvItmPltAtu[_nPosAtu][7]
			_cLote     := mvItmPltAtu[_nPosAtu][8]
			_dDtVldLot := mvItmPltAtu[_nPosAtu][9]
		EndIf

		// pesquisa se o ID produto ja esta na composicao do novo palete
		_nPos := aScan(mvCompNewPlt,{|x| (x[2] == mvIdEtqProd) .And. (x[4] == _cNumSeq) })

		// insere quantidade lida na composicao do novo palete
		If (_nPos == 0)
			aAdd(mvCompNewPlt,{mvIdPalete, mvIdEtqProd, _cCodProd, _cNumSeq, _nQtdProd, _nQtdSegUM, _cPrdOrig, _cTpEsto, _cLote, _dDtVldLot})
			// atualiza a quantidade
		ElseIf (_nPos > 0)
			mvCompNewPlt[_nPos][5] := _nQtdProd
			mvCompNewPlt[_nPos][6] := _nQtdSegUM
		EndIf

		// zera variavel
		mvItmNewPlt := {}
		// vare todos os itens da composicao do novo palete
		For _nX := 1 to Len(mvCompNewPlt)
			// pesquisa se o produto ja esta na composicao do novo palete
			_nPos := aScan(mvItmNewPlt,{|x| (x[2] == _cCodProd) .And. (x[4] == _cNumSeq) })

			// atualiza quantidade
			If (_nPos > 0)
				// atualiza quantidade
				mvItmNewPlt[_nPos][1] += _nQtdProd
				// quantidade ja separada do produto
				_nQtdJaSep := mvItmNewPlt[_nPos][1]

			ElseIf (_nPos == 0)
				aAdd(mvItmNewPlt,{_nQtdProd, _cCodProd, _cPrdDesc, _cNumSeq, mvIdEtqProd, _cPrdOrig, _cTpEsto, _cLote, _dDtVldLot, .F.})
				// quantidade ja separada do produto
				_nQtdJaSep := _nQtdProd

			EndIf
		Next _nX
		// padroniza variavel sem dados
		If (Len(mvItmNewPlt) == 0)
			mvItmNewPlt := {{0, "", "", "", "", "", "", "", CtoD("//"), .F.}}
		EndIf

		// se houver atualizações de etiqueta para fazer na tabela Z56 (etiquetas cliente)
		If (_lRet) .AND. ( !Empty(_aColsSum) )
			For _nX := 1 To Len(_aColsSum)
				_cUpd := " UPDATE " + RetSQLName("Z56")
				_cUpd += " SET Z56_CODETI = '" + mvIdEtqProd + "'
				_cUpd += " WHERE D_E_L_E_T_ = '' and Z56_FILIAL = '" + xFilial("Z56") + "'"
				_cUpd += " AND Z56_CODCLI = '" + mvCodCli     + "' "
				_cUpd += " AND Z56_ETQCLI = '" + _aColsSum[_nX][1] + "' "

				Memowrit("c:\query\TWMSA011_sfVldProd_update_Z56.txt", _cUpd)

				// executa update
				If (TCSQLExec(_cUpd) < 0)
					U_FtWmsMsg("Erro ao atualizar etiquetas do cliente!" ,"Erro TWMSA011 - Update Z56")
				EndIf
			Next _nX
			// limpa array
			_aColsSum := {}
		EndIf

		// atualiza o saldo o de itens separados
		_nPos := aScan(mvBrwItmRet:aCols,{|x| (AllTrim(x[3]) == AllTrim(_cCodProd)) .And. (AllTrim(_cNumSeq) $ AllTrim(x[5])) })
		If (_nPos > 0)
			mvBrwItmRet:aCols[_nPos][2] := _nQtdJaSep
		EndIf
		mvBrwItmRet:Refresh()

		// atualiza os dados do browse
		mvBrwNewPlt:aCols := aClone(mvItmNewPlt)
		mvBrwNewPlt:Refresh()

	EndIf
	// reinicia variaveis
	mvIdEtqProd := Space(Len(mvIdEtqProd))
	mvGetIdEtiq:Refresh()

	// foca no objeto cod produto
	mvGetIdEtiq:SetFocus()

Return(_lRet)

// ** funcao para informar a quantidade manualmente (para produtos de pequeno porte)
Static Function sfInfQuant(mvQtdProd, mvQtdSegum)
	// objetos
	local _oBtnFoco1
	local _oGetQuant, _oGetQtdSeg
	// controle para nao fechar a tela
	Local _lRetOk := .F.

	// reinicia segunda unidade de medida
	mvQtdSegum := 0

	// monta a tela para informa a quantidade
	_oWndInfQuant := MSDialog():New(020,020,200,180,"Informe a Quantidade",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlInfQtdCab := TPanel():New(000,000,nil,_oWndInfQuant,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlInfQtdCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpInfQtdOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRetOk := .T., _oWndInfQuant:End() },_oPnlInfQtdCab,"Ok",,.T.)
	_oBmpInfQtdOk:Align := CONTROL_ALIGN_LEFT

	// botao para usar como foco (nao é usado pra nada)
	_oBtnFoco1 := TButton():New(032,005,"",_oWndInfQuant,{|| Nil },010,010,,,,.T.,,"",,,,.F. )

	// quantidade
	_oGetQuant  := TGet():New(025, 005, {|u| If(PCount()>0,mvQtdProd :=u,mvQtdProd )}, _oWndInfQuant, 060, 010, _cMaskQuant, {|| sfVldQuant(2, @mvQtdProd, @mvQtdSegum) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","mvQtdProd" ,,,,,,,"Quantidade ("+SB1->B1_UM+"):"   ,1)
	_oGetQtdSeg := TGet():New(045, 005, {|u| If(PCount()>0,mvQtdSegum:=u,mvQtdSegum)}, _oWndInfQuant, 060, 010, _cMaskQuant, {|| sfVldQuant(1, @mvQtdProd, @mvQtdSegum) },,,_oFnt02,,,.T.,"",,{|| ! Empty(SB1->B1_SEGUM) },.F.,.F.,,.F.,.F.,"","mvQtdSegum",,,,,,,"Qtd Seg UM ("+SB1->B1_SEGUM+"):",1)

	// seta o foco na mensagem
	_oGetQuant:SetFocus()

	// ativacao da tela com validacao
	_oWndInfQuant:Activate(,,,.T.,{|| _lRetOk })

Return

// ** funcao que calcula as unidade de medidas
Static Function sfVldQuant(mvUndRet, mvQtdProd, mvQtdSegum)
	// verifica se as quantidades foram informadas
	If (mvQtdProd > 0) .Or. (mvQtdSegum > 0)
		// verifica se precisa calcular a segunda unidade de medida
		If ( ! Empty(SB1->B1_SEGUM) ) .And. (SB1->B1_CONV>0)
			// retorna a 1a Unid Medida
			If (mvUndRet==1)
				mvQtdProd := ConvUM(SB1->B1_COD, mvQtdProd, mvQtdSegum, mvUndRet)
				// 2a Unid Medida
			ElseIf (mvUndRet==2)
				mvQtdSegum := ConvUM(SB1->B1_COD, mvQtdProd, mvQtdSegum, mvUndRet)
			EndIf
		EndIf
	EndIf

Return(.T.)

// ** funcao para validar a montagem do novo palete
Static Function sfVldDesmPlt(mvBrwItmRet, mvBrwNewPlt, mvFixaWnd)
	// variavel de retorno
	local _lRet := .F.
	// variaveis aCols dos Browser's
	local _aItensRet := aClone(mvBrwItmRet:aCols)
	local _aNovoPlt  := aClone(mvBrwNewPlt:aCols)
	// variaveis temporarias
	local _nItRet
	local _nSaldoRet

	// verifica o saldo atendido
	For _nItRet := 1 to Len(_aItensRet)

		// reinicia variavel
		_lRet := .F.
		// saldo a retirar
		_nSaldoRet := _aItensRet[_nItRet][1]
		// verifica no novo palete a quantidade retirada
		aEval(_aNovoPlt,{|x| (_nSaldoRet -= x[1]) })
		// valida o saldo de retorno
		_lRet := (_nSaldoRet == 0)

		// se deu erro no saldo, fecha o loop
		If (!_lRet)
			// mensagem
			U_FtWmsMsg("Saldo de retirada incorreto!","ATENCAO")
			// sai do loop
			Exit
		EndIf

	Next _nItRet

	// atualiza variavel que controla a tela aberta
	mvFixaWnd := _lRet

Return(_lRet)

// ** funcao que padroniza o aCols para o browse
Static Function sfPadItmRet(mvItemRet)
	local _aRet := {}
	local _nX
	// area inicial
	local _aAreaSB1 := SB1->(GetArea())

	For _nX := 1 to Len(mvItemRet)
		// adiciona os detalhes
		aAdd(_aRet,{;
		mvItemRet[_nX][1],;
		0                ,;
		mvItemRet[_nX][2],;
		Posicione("SB1",1, xFilial("SB1")+mvItemRet[_nX][2] ,"B1_DESC"),;
		mvItemRet[_nX][3],;
		mvItemRet[_nX][4],;
		mvItemRet[_nX][5],;
		mvItemRet[_nX][6],;
		.F.})
	Next _nX

	// restaura area inicial
	RestArea(_aAreaSB1)

Return(_aRet)

// ** funcao para validacao do id do endereco de destino
Static Function sfVldEndDes(mvIdEtq, mvEndDest, mvContProc, mvWndOrig, mvFechaTela, mvFracPlt)
	// variavel de retorno
	local _lRet := .T.
	// query
	local _cQuery

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11") + mvIdEtq ))
			// mensagem
			U_FtWmsMsg("Endereço inválido!","ATENCAO")
			// controle
			_lRet := .F.
		EndIf
	EndIf

	// valida, quando necessario fracionar palete, se permite no endereco informado
	If (_lRet) .And. (mvFracPlt) .And. ( Empty(mvEndDest) )

		// validando o endereço escolhido permite fracionamento
		If (_lRet)
			dbSelectArea("SBE")
			SBE->( dbSetOrder(1) )
			If ( ! SBE->( dbSeek( xFilial("SBE") + Z11->Z11_LOCAL + Z11->Z11_ENDERE ) ) )
				// avisa o usuário
				U_FtWmsMsg("O endereço de DESTINO não foi encontrado.")
				// controle
				_lRet := .F.
			EndIf
		EndIf

		// validando a estrutura física do endereço
		If (_lRet)
			dbSelectArea("DC8")
			DC8->( dbSetOrder(1) )
			If ( ! DC8->( dbSeek( xFilial("DC8") + SBE->BE_ESTFIS ) ) )
				// avisa o usuário
				U_FtWmsMsg("O tipo de estrutura física do endereço de DESTINO não foi encontrado.")
				// controle
				_lRet := .F.
			EndIf
		EndIf

		// nao permite DOCA ou BLOCADO
		If (_lRet) .and. ((DC8->DC8_CODEST == "000001") .OR. (DC8->DC8_CODEST == "000007"))
			// avisa o usuário
			U_FtWmsMsg("Não é permitido fracionar em endereço do tipo doca/bloco. Fracione em RUA.")
			// controle
			_lRet := .F.
		EndIf

	EndIf

	// caso a transação esteja em branco
	If (_lRet)
		If ( Empty(mvEndDest) )
			// se for diferente de DOCA ou STAGE, pega a RUA
			If ( ! sfVldTpEnd(Z11->Z11_ENDERE, Z11->Z11_LOCAL) ) .And. (Len(AllTrim(Z11->Z11_ENDERE)) > 2)
				_cEndDesti := SUBSTR(Z11->Z11_ENDERE,1,2)
			ElseIf ( sfVldTpEnd(Z11->Z11_ENDERE, Z11->Z11_LOCAL) )
				_cEndDesti := Z11->Z11_ENDERE
			EndIf
		EndIf
	EndIf

	// valida o tipo da etiqueta lida
	If (_lRet) .And. (Z11->Z11_TIPO != "02")
		U_FtWmsMsg("Etiqueta de endereço inválida!","ATENCAO")
		_lRet := .F.
	EndIf

	// valida o endereco
	If (_lRet)
		// compara o endereco
		If (Z11->Z11_ENDERE != mvEndDest)
			// verifica se eh um endereco de transacao
			If (mvEndDest != Z08->Z08_ENDDES)
				// verifica se esta na rua correta
				If (Left(mvEndDest,2) != Left(Z11->Z11_ENDERE,2)) .And. ( ! Empty(mvEndDest))
					U_FtWmsMsg("Endereço "+Z11->Z11_ENDERE+" incorreto!","ATENCAO")
					_lRet := .F.
				EndIf

				// tratamento para casos de devolucao
				If (mvEndDest == Z08->Z08_ENDORI) .And. (mvEndDest != Z11->Z11_ENDERE)
					U_FtWmsMsg("Endereço "+Z11->Z11_ENDERE+" incorreto!","ATENCAO")
					_lRet := .F.
				EndIf

			ElseIf (mvEndDest == Z08->Z08_ENDDES) .And. ( ! Empty(SubS(Z08->Z08_ENDDES,3,1)))
				U_FtWmsMsg("Endereço "+Z11->Z11_ENDERE+" incorreto!","ATENCAO")
				_lRet := .F.

			EndIf
		EndIf
	EndIf

	// variavel de retorno para continuacao do processo
	mvContProc := _lRet
	// permite fechar a tela
	mvFechaTela := _lRet

	// se existir o objeto, fecha
	If (mvWndOrig <> nil) .And. (_lRet)
		mvWndOrig:End()
	EndIf

Return(_lRet)

// ** funcao que retorna os paletes disponiveis no endereco
Static Function sfRetPltEnd()
	// variavel de retorno
	local _aTmpDados := {}
	// query
	local _cQuery

	// volumes (caixas) ja selecionados no pedido de venda
	local _lVolJaDef := U_FtWmsParam("WMS_EXPEDICAO_ESCOLHE_VOLUMES", "L", .F., .F., Nil, _cCodCliMov, _cLjCliMov, Nil, Nil)

	// permite conferencia/recebimento por volumes
	local _lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.F.,.F.,"", _cCodCliMov, _cLjCliMov, Nil, Nil)

	// prepara query
	_cQuery := " SELECT Z16_SALDO, "
	_cQuery += "        CASE "
	_cQuery += "          WHEN Z16_ETQPRD != '' THEN Z16_ETQPRD "
	_cQuery += "          ELSE Z16_ETQVOL "
	_cQuery += "        END ETQ_IDENT, "
	_cQuery += "        B1_DESC, "
	_cQuery += "        B1_COD, "
	_cQuery += "        Z16_LOTCTL, "
	_cQuery += "        Z16_VLDLOT, "
	_cQuery += "        Z16_QTSEGU, "
	_cQuery += "        CASE "
	_cQuery += "          WHEN (Z08_NUMOS IS NULL) " +IIf((_lVolJaDef) .And. (_lCtrVolume), " OR ( Z45_PEDIDO IS NULL ) ", "")+ " THEN 'NÃO' "
	_cQuery += "          ELSE 'SIM' "
	_cQuery += "        END ETQ_RESERV, "
	_cQuery += "        '.F.' IT_DEL "

	// composicao do palete
	_cQuery += " FROM   "+RetSqlTab("Z16")+" (nolock) "

	// cad. do produto
	_cQuery += "        INNER JOIN "+RetSqlTab("SB1")+" (nolock) "
	_cQuery += "                ON "+RetSqlCond("SB1")
	_cQuery += "                   AND B1_COD = Z16_CODPRO "

	// caixas reservadas
	If (_lVolJaDef) .And. (_lCtrVolume)
		_cQuery += "        LEFT JOIN " + RetSqlTab("Z45") + " (nolock) "
		_cQuery += "               ON " + RetSqlCond("Z45")
		_cQuery += "                  AND Z45_ETQPAL = Z16_ETQPAL "
		_cQuery += "                  AND Z45_CODPRO = Z16_CODPRO "
		_cQuery += "                  AND Z45_ETQVOL = Z16_ETQVOL "
	EndIf

	// mapa de movimentacao
	_cQuery += "        LEFT JOIN "+RetSqlTab("Z08")+" (nolock) "
	_cQuery += "               ON "+RetSqlCond("Z08")
	_cQuery += "                  AND CHARINDEX(Z08_NUMOS, '"+_cQryChrIn+"') > 0 "
	_cQuery += "                  AND CASE "
	_cQuery += "                        WHEN Z08_NEWPLT != '' THEN Z08_NEWPLT "
	_cQuery += "                        ELSE Z08_PALLET "
	_cQuery += "                      END = Z16_ETQPAL "
	_cQuery += "                  AND Z08_LOTCTL = Z16_LOTCTL "

	// filtro padrao
	_cQuery += " WHERE  "+RetSqlCond("Z16")
	// endereco
	_cQuery += "        AND Z16_ENDATU = '"+_cEndOrige+"' "
	// somente com saldo
	_cQuery += "        AND Z16_SALDO > 0 "

	memowrit("c:\query\twmsa011_sfRetPltEnd.txt", _cQuery)

	// atualiza variavel de retorno
	_aTmpDados := U_SqlToVet(_cQuery, {"Z16_VLDLOT"})

Return(_aTmpDados)

// ** funcao para habilitar o filtro por rua
Static Function sfFiltroRua()
	// objetos da tela
	local _oWndFltRua
	local _oPnlFltRua
	local _oSayRua
	local _oCBoxRua
	local _oBtnFltOk, _oBtnFltSair
	// controle de confirmacao da tela
	local _lOk := .F.

	// monta a tela para selecionar a rua
	_oWndFltRua := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Filtrar Rua",,,.F.,,,,,,.T.,,,.T. )
	_oWndFltRua:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlFltRua := TPanel():New(000,000,nil,_oWndFltRua,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlFltRua:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBtnFltOk := TBtnBmp2():New(000,000,040,040,"OK",,,,{|| _lOk := .T., _oWndFltRua:End() },_oPnlFltRua,"Confirmar",,.T.)
	_oBtnFltOk:Align := CONTROL_ALIGN_LEFT
	// -- SAIR
	_oBtnFltSair := TBtnBmp2():New(000,000,040,040,"FINAL",,,,{|| _oWndFltRua:End() },_oPnlFltRua,"Sair",,.T.)
	_oBtnFltSair:Align := CONTROL_ALIGN_RIGHT

	// RUA
	_oSayRua  := TSay():New( 040,005,{||"Rua:"},_oWndFltRua,,,.F.,.F.,.F.,.T.,,,032,008)
	// box para selecionar as ruas disponiveis
	_oCBoxRua := TComboBox():New(038,050,{|u| If(PCount()>0,_cFiltraRua:=u,_cFiltraRua)},_aRuaDisp,050,010,_oWndFltRua,,,,,,.T.,,"",,,,,,,_cFiltraRua)

	// ativa a tela
	_oWndFltRua:Activate(,,,.F.,,,)

Return

// ** funcao para inciar a operacao de desmontagem de palete
Static Function sfInicDesm(mvBmpDesmInic, mvBmpDesmOk, mvBmpDesmSair, mvGetIdEtiq)
	// variavel de retorno
	local _lRet := .F.
	// seek do Z17
	local _cSeekZ17
	// tempo total
	local _nTempoTot := 0

	// solicita confirmacao do processo
	If ( ! U_FtYesNoMsg("Iniciar desmontagem" + CRLF + "de palete?","Desmontagem") )
		Return(_lRet)
	EndIf

	// atualiza variavel de retorno
	_lRet := .T.

	// atualiza a visibilidade dos botoes
	mvBmpDesmInic:lVisible := ( ! _lRet)
	mvBmpDesmOk:lVisible   := (_lRet)
	mvBmpDesmSair:lVisible := ( ! _lRet)
	mvGetIdEtiq:bWhen      := {|| _lRet }
	// seta o foco no id palete
	mvGetIdEtiq:SetFocus()

	// atualiza o status do movimento
	dbSelectArea("Z17")
	Z17->(dbSetOrder(1)) // 1-Z17_FILIAL, Z17_ETQPLT
	Z17->(dbSeek( _cSeekZ17 := xFilial("Z17")+Z08->Z08_PALLET ))
	// compara o numero da OS
	While Z17->(!Eof()) .And. (Z17->(Z17_FILIAL+Z17_ETQPLT)==_cSeekZ17)
		If (Z17->Z17_NUMOS == Z08->Z08_NUMOS) .And. (Z17->Z17_SEQOS == Z08->Z08_SEQOS) .And. (Empty(Z17->Z17_DTFIM)) .And. (Z17->Z17_STATUS == "M") .And. (Z17->Z17_OPERAD == _cCodOper)
			RecLock("Z17")
			// data e hora final
			Z17->Z17_DTFIM  := Date()
			Z17->Z17_HRFIM  := Time()
			Z17->Z17_STATUS := "R" // R=Realizado / C=Cancelado / M=Em Movimento

			// calcula o tempo da operacao (retorno em centesimal)
			_nTempoTot := A680Tempo(Z17->Z17_DTINI,;
			Left(Z17->Z17_HRINI,5),;
			Z17->Z17_DTFIM,;
			Left(Z17->Z17_HRFIM,5) )

			// converte para horas normais
			_nTempoTot := fConvHr(_nTempoTot,"H")

			// tempo total
			Z17->Z17_TEMPO := _nTempoTot

			Z17->(MsUnLock())
		EndIf
		// proximo item
		Z17->(dbSkip())
	EndDo

Return(_lRet)

// ** funcao que verifica e corrige movimentacoes pendentes/erros
Static Function sfMovPltPend()
	// query
	local _cQuery
	// movimentacoes
	local _aTmpMovim := {}
	local _nTmpMovim

	// monta query para buscar movimentacoes pendentes/com erros
	_cQuery := " SELECT Z08.R_E_C_N_O_ Z08RECNO, "
	_cQuery += "        Z17_OPERAD, "
	_cQuery += "        Z08_NUMOS, "
	_cQuery += "        Z08_PALLET, "
	_cQuery += "        Z08_ENDORI "
	// mapa de armazenagem/separacao
	_cQuery += " FROM " + RetSqlName("Z08") + " Z08 (NOLOCK) "
	// movimentacoes
	_cQuery += "        INNER JOIN " + RetSqlName("Z17") + " Z17 (NOLOCK) "
	_cQuery += "                ON " + RetSqlCond("Z17")
	_cQuery += "                   AND Z17_NUMOS = Z08_NUMOS "
	_cQuery += "                   AND Z17_ETQPLT IN ( Z08_PALLET, Z08_NEWPLT ) "
	// status M-Em Movimento
	_cQuery += "                   AND ( ( Z17_STATUS = 'M' ) "
	// status R-Realizado, verifica se na Z08 o status for M e na Z17 o movimento foi realizado, compara se o palete realmente movimentou corretamente
	_cQuery += "                          OR ( Z17_STATUS = 'R' "
	_cQuery += "                               AND Z17_ENDDES = (SELECT DISTINCT(Z16_ENDATU) "
	_cQuery += "                                                 FROM   " + RetSqlName("Z16") + " Z16 (NOLOCK) "
	_cQuery += "                                                 WHERE  " + RetSqlCond("Z16")
	// verifica mesmo se depois de fracionado
	_cQuery += "                                                        AND ( ( Z08_NEWPLT != '' "
	_cQuery += "                                                                AND Z16_ETQPAL = Z08_NEWPLT ) "
	_cQuery += "                                                               OR ( Z08_NEWPLT = '' "
	_cQuery += "                                                                    AND Z16_ETQPAL = Z08_PALLET ) ) "
	// valida também se o palete realmente tem o saldo solicitado
	_cQuery += "                                                        GROUP  BY Z16_ENDATU "
	_cQuery += "                                                        HAVING Sum(Z16_SALDO) >= Z08_QUANT ) ) ) "
	// somente do operador OU de outro operador parado a mais de 10 min
	_cQuery += "                   AND ( ( Z17_OPERAD = '" + _cCodOper + "') "
	_cQuery += "                          OR ( Z17_OPERAD != '" + _cCodOper + "' "
	_cQuery += "                               AND Datediff(MINUTE, CONVERT(DATETIME, Z17_DTINI + ' ' + Z17_HRINI), Getdate()) > 10 ) ) "
	// filtro padrao
	_cQuery += " WHERE  " +RetSqlCond("Z08")
	_cQuery += "        AND Z08_STATUS = 'M' "
	// valida se o endereço de serviço é o mesmo do palete
	_cQuery += "        AND Z08_ENDSRV = (SELECT DISTINCT(Z16_ENDATU) "
	_cQuery += "                          FROM   " + RetSqlName("Z16") + " Z16 (NOLOCK) "
	_cQuery += "                          WHERE  " + RetSqlCond("Z16")
	// verifica mesmo se depois de fracionado
	_cQuery += "                                 AND ( ( Z08_NEWPLT != '' "
	_cQuery += "                                         AND Z16_ETQPAL = Z08_NEWPLT ) "
	_cQuery += "                                        OR ( Z08_NEWPLT = '' "
	_cQuery += "                                             AND Z16_ETQPAL = Z08_PALLET ) ) "
	// valida também se o palete realmente tem o saldo solicitado
	_cQuery += "                                 GROUP  BY Z16_ENDATU "
	_cQuery += "                                 HAVING Sum(Z16_SALDO) >= Z08_QUANT ) "
	_cQuery += " ORDER  BY Z17.R_E_C_N_O_  "

	//log da query executada
	memowrit("C:\query\twmsa011_sfMovPltPend.txt",_cQuery)

	// atualiza variavel com as movimentacoes
	_aTmpMovim := U_SqlToVet(_cQuery)

	// varre todas as movimentacoes
	For _nTmpMovim := 1 to Len(_aTmpMovim)

		// chama funcao para relizar o cancelamento da movimentacao
		sfExCancMov( _aTmpMovim[_nTmpMovim][1] ,; // recno
		_aTmpMovim[_nTmpMovim][2])// operador

	Next _nTmpMovim

Return

// ** função para validar se é necessário fracionar o palete ou não
Static Function sfValFrac()

	// query Z08
	local _cQryZ08 := ""
	// query Z16
	local _cQryZ16 := ""
	// controle de loop
	local _nZ16 := 0
	local _nZ08 := 0
	// variavel de retorno
	local _cRet := "N"

	// query para verificação do que está sendo pedido na OS
	_cQryZ08 := " SELECT Z08_PRODUT, Z08_QUANT, Z08_QTSEGU, Z08.R_E_C_N_O_ Z08RECNO, Z08_LOTCTL "
	_cQryZ08 += " FROM " + RetSqlTab("Z08") + " (nolock) "
	_cQryZ08 += " WHERE " + RetSqlCond("Z08")
	_cQryZ08 += " AND Z08_NUMOS  =  '" + _cNumOrdSrv + "' "
	_cQryZ08 += " AND Z08_PALLET =  '" + _cIdPalete + "' "
	_cQryZ08 += " AND Z08_STATUS <> 'R' "
	_cQryZ08 += " ORDER BY Z08_PRODUT, Z08_LOTCTL "

	MemoWrit("c:\query\twmsa011_sfValFrac_1_z08.txt", _cQryZ08)

	// array base pra consulta dos endereços
	_aQryZ08 := U_SqlToVet(_cQryZ08)

	If (Len(_aQryZ08) == 0) .Or. (Len(_aQryZ08) == Nil)
		// avisa o usuário
		U_FtWmsMsg("Não há Os para esse pallet!")
		// retorno
		Return (Nil)
	EndIf

	// query para verificação do que está está no pallet
	_cQryZ16 := " SELECT Z16_CODPRO, SUM(Z16_SALDO) Z16_SALDO, Z16_LOTCTL "
	_cQryZ16 += " FROM " + RetSqlTab("Z16") + " (nolock) "
	_cQryZ16 += " WHERE " + RetSqlCond("Z16")
	_cQryZ16 += " AND Z16_ETQPAL = '" + _cIdPalete + "' "
	_cQryZ16 += " AND Z16_SALDO <> 0 "
	_cQryZ16 += " GROUP BY Z16_CODPRO, Z16_LOTCTL "
	_cQryZ16 += " ORDER BY Z16_CODPRO, Z16_LOTCTL "

	MemoWrit("c:\query\twmsa011_sfValFrac_2_z16.txt", _cQryZ16)

	// array base pra consulta dos endereços
	_aQryZ16 := U_SqlToVet(_cQryZ16)

	// validação dos dados do pallet
	If (Len(_aQryZ16) == 0) .Or. (Len(_aQryZ16) == Nil)
		// avisa o usuário
		U_FtWmsMsg("Não há dados para esse pallet!")
		// retorno
		Return (Nil)
	EndIf

	// validando o endereço de serviço para verificar onde está o pallet
	dbSelectArea("SBE")
	SBE->( dbSetOrder(1) )
	If ( ! SBE->( dbSeek( xFilial("SBE") + Z08->Z08_LOCAL + Z08->Z08_ENDSRV ) ) )
		// avisa o usuário
		U_FtWmsMsg("O endereço de serviço não foi encontrado.")
		// retorno
		Return (Nil)
	EndIf

	// validando o endereço de serviço para verificar onde está o pallet
	dbSelectArea("DC8")
	DC8->( dbSetOrder(1) )
	If ( ! DC8->( dbSeek( xFilial("DC8") + SBE->BE_ESTFIS ) ) )
		// avisa o usuário
		U_FtWmsMsg("O endereço de serviço não foi encontrado.")
		// retorno
		Return (Nil)
	EndIf

	// validações iniciais para OS de Expedição
	If (_lCtrVolume) .And. ((_lOSInt) .Or. (_lOSExp))

		// caso precise apenas de um produto e na Z16 possui apenas um produto
		If (Len(_aQryZ08) == 1) .And. (Len(_aQryZ16) == 1)

			// se as quantidades forem diferentes chama o fracionamento e não for OS interna
			If (_aQryZ16[1][2] > _aQryZ08[1][2])

				// tipo de fracionamento
				_cTipFra := "SINGLE"

				// pergunta se já quer fracionar a mercadoria
				If (U_FtYesNoMsg("Será necessário fracionar esse pallet. Deseja iniciar? T=S"))

					// retorno do fracionamento
					_cRet := "S"
				Else

					// retorno do fracionamento
					_cRet := "D"
				EndIf

				// pra escolher onde quer deixar a mercadoria
				_cEndDesti := ""

				// quando a quantidade não bater e na Z16 for menor que na Z08
			ElseIf (_aQryZ16[1][2] < _aQryZ08[1][2])

				// avisa o usuário
				U_FtYesNoMsg("Não há saldo para o produto solicitado!")
				// pra mostrar o erro
				Return(Nil)

			EndIf

			// quando é o kit/peças que é o solicitado
		Else

			// valida a quantidade de cada array pra definir que tipo de fracionamento ocorrerá
			If (Len(_aQryZ08) < Len(_aQryZ16))

				// tipo de fracionamento
				_cTipFra := IIF(_lOSInt, "PEÇAS", "KIT")
			Else

				// se as quantidades forem diferentes chama o fracionamento
				// faço esse for pra validar as quantidades de TODOS os produtos no pallet
				For _nZ08 := 1 to Len(_aQryZ08)

					// os for aninhados são para a comparação dos registros na Z16
					For _nZ16 := 1 to Len(_aQryZ16)

						// faço as comparações necessárias de produto
						If ( _aQryZ08[_nZ08][1] == _aQryZ16[_nZ16][1] ) .And. ( _aQryZ08[_nZ08][5] == _aQryZ16[_nZ16][3] )

							// faço as comparações necessárias de produto e quantidade
							If ( _aQryZ08[_nZ08][2] <= _aQryZ16[_nZ16][2] )
								// tipo de fracionamento
								_cTipFra := IIF(_lOSInt, "PEÇAS", "KIT")

								// caso a quantidade na Z08 for maior do que o que está pedindo na Z16
							ElseIf ( _aQryZ08[_nZ08][2] > _aQryZ16[_nZ16][2] )
								// mensagem pro usuário
								U_FtWmsMsg("A quantidade solicitada é maior que a quantidade do pallet!")
								// retorno
								Return(Nil)

							EndIf
						EndIf

					Next _nZ16

				Next _nZ08

			EndIf

			// caso seja necessário fracionar, chama a pergunta
			If (_cTipFra == "KIT") .Or. (_cTipFra == "PEÇAS")

				// pergunta se já quer fracionar a mercadoria
				If(U_FtYesNoMsg("Será necessário fracionar esse pallet. Deseja iniciar? T=" + Substr(_cTipFra,1,1)))
					_cRet := "S"
				Else
					_cRet := "D"
				EndIf

				// pra escolher onde quer deixar a mercadoria
				_cEndDesti := ""

			EndIf

		EndIf

	ElseIf (_aQryZ16[1][2] > _aQryZ08[1][2])

		// mensagem para o usuário
		U_FtWmsMsg("Será necessário fracionar esse pallet. Solicite um pallet ao paleteiro","Atenção")
		_cRet := "S"

	EndIf

Return(_cRet)

// ** função para gravar dados da etiqueta antiga na nova
Static Function sfGrvNewEtq(mvEtqOri, mvEtqDes)
	// variavel que receberá a query de origem Z11
	local _cQryZ11 := ""
	// array que receberá os dados da query de origem
	local _aOriZ11 := {}
	// variave de controle
	local _lRet := .T.

	if(_lRet)
		// query para pegar dados da etiqueta de origem
		_cQryZ11 := " SELECT Z11_CLIENT, Z11_PROCES, Z11_LOJA, "
		_cQryZ11 += " Z11_DOC, Z11_SERIE, Z11_TIPONF, "
		_cQryZ11 += " Z11_ITEMNF, Z11_CODPRO, Z11_NUMSEQ, "
		_cQryZ11 += " Z11_CESV, Z11_QTDLEI, Z11_QTDIMP, "
		_cQryZ11 += " Z11_QTD1, Z11_QTD2, Z11_CARGA, Z11_SEQKIT, Z11_CODKIT, Z11_EMBALA "
		_cQryZ11 += "  FROM " + RetSqlTab("Z11") + " (NOLOCK) "
		_cQryZ11 += " WHERE " + RetSqlCond("Z11")
		_cQryZ11 += " AND Z11_CODETI = (SELECT DISTINCT CASE WHEN Z16_ETQPRD = '' THEN Z16_ETQVOL ELSE Z16_ETQPRD END
		_cQryZ11 += "					FROM " + RetSqlTab("Z16") + " (NOLOCK) "
		_cQryZ11 += "					WHERE " + RetSqlCond("Z16")
		_cQryZ11 += "					AND " + IIF(_lCtrVolume, "Z16_ETQVOL", "Z16_ETQPAL")+" = '" + mvEtqOri + "' AND Z16_SALDO > 0) "

		memowrit("C:\query\twmsa011_sfGrvNewEtq.txt",_cQryZ11)

		// jogo o resultado da query num array
		_aOriZ11 := U_SqlToVet(_cQryZ11)

		// se não tem nada no array
		If (Len(_aOriZ11) == 0)
			// mensagem
			U_FtWmsMsg("Nenhum dado encontrado para a etiqueta informada")
			// variavel de controle
			_lRet := .F.
		EndIf
	EndIf

	If (_lRet)
		// valido novamente a etiqueta nova
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ! Z11->(dbSeek( xFilial("Z11") + mvEtqDes ))
			// mensagem
			U_FtWmsMsg("Etiqueta inválida!", "ATENCAO")
			// variavel de controle
			_lRet := .F.
		EndIf
	EndIf

	If (_lRet)
		// gravo os registros na nova etiqueta
		RecLock("Z11")
		Z11->Z11_CLIENT := _aOriZ11[1][1]
		Z11->Z11_PROCES := _aOriZ11[1][2]
		Z11->Z11_LOJA   := _aOriZ11[1][3]
		Z11->Z11_DOC    := _aOriZ11[1][4]
		Z11->Z11_SERIE  := _aOriZ11[1][5]
		Z11->Z11_TIPONF := _aOriZ11[1][6]
		Z11->Z11_ITEMNF := _aOriZ11[1][7]
		Z11->Z11_CODPRO := _aOriZ11[1][8]
		Z11->Z11_NUMSEQ := _aOriZ11[1][9]
		Z11->Z11_CESV   := _aOriZ11[1][10]
		Z11->Z11_QTDLEI := _aOriZ11[1][11]
		Z11->Z11_QTDIMP := _aOriZ11[1][12]
		Z11->Z11_QTD1   := _aOriZ11[1][13]
		Z11->Z11_QTD2   := _aOriZ11[1][14]
		Z11->Z11_CARGA  := _aOriZ11[1][15]
		Z11->Z11_SEQKIT := _aOriZ11[1][16]
		Z11->Z11_CODKIT := _aOriZ11[1][17]
		Z11->Z11_EMBALA := _aOriZ11[1][18]
		Z11->(MsUnLock())
	EndIf

Return (_lRet)

// ** rotina para fracionamento de pallet com volumes - somente quando volume está habilitado
Static Function sfDesmontaVol(mvCodPro, mvOper, mvSair)

	// objetos locais
	local _oPnlFraPlt
	local _oBmpNovoVol, _oBmpOpcoes, _oBmpFraCons, _oBmpCaixa, _oCmbCodEmb
	local _oSayEan, _oSayNova, _oSayAntiga, _oSayCodEmb
	local _oWmsFraPlt
	// controle de confirmacao da tela
	local _lFixaWnd := .F.

	// sub-menu
	local _oMnuOpcoes := nil
	local _oSbMnOpc1  := nil
	local _oSbMnOpc2  := nil
	local _oSbMnOpc3  := nil

	// controle
	local _lOk := .T.

	// mascaras dos objetos
	local _cMskEtiq := PesqPict("Z11","Z11_CODETI")

	// aqui é um jeitin brasileiro pra poder mostrar ou não os campos na tela
	local _lROKit := (mvOper == "KIT")
	local _lROSin := (mvOper == "SINGLE")

	// variaveis temporarias
	local _nX

	// variaveis que recebem valores dos textbox
	private _cEtqNova    := CriaVar("Z11_CODETI",.F.)
	private _cEtqAntiga  := CriaVar("Z11_CODETI",.F.)
	private _cCodBar     := Space(13)

	// get private
	private _oGetAntiga, _oGetEan, _oGetNova

	// dados do browse
	private _aHeadFra := {}
	private _aColsFra := {}

	// browse
	private _oBrwFraPlt
	private _aOpcoesEmb := sfRetTpEmbala(_cCodCliMov) // retorna todas as embalagens disponíveis
	private _cTpEmbala  := "" // tipo da embalagem

	Default mvCodPro := ""
	Default mvOper   := "PEÇAS" // por peça

	// tenta reserva completa do palete
	While ( ! sfLockPlt(_cIdPalete) )
		Loop
	EndDo

	// atualiza etiqueta identificacao do produto
	_cTpIdEtiq := U_FtWmsParam("WMS_PRODUTO_ETIQ_IDENT", "C", "INTERNA", .F., "", _cCodCliMov, _cLjCliMov, Nil, _cNumOrdSrv)

	// atualiza os dados
	sfSelDadosFra()

	// monta o dialogo do monitor
	_oWmsFraPlt := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Fracionamento de Palete",,,.F.,,,,,,.T.,,,.T. )
	_oWmsFraPlt:lEscClose := .F.

	// sub-itens do menus
	_oMnuOpcoes := TMenu():New(0,0,0,0,.T.)
	// adiciona itens no Menu

	// -- VER ETIQUETAS
	_oSbMnOpc1 := TMenuItem():New(_oMnuOpcoes,"Ver Etiquetas",,,,{|| sfEtqSelFra() },,"SELECT",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc1)

	// -- FINALIZAR
	_oSbMnOpc2 := TMenuItem():New(_oMnuOpcoes,"Finalizar",,,,{|| IIf(sfFinalFra(@_lFixaWnd, mvCodPro), _oWmsFraPlt:END(), Nil) },,"CHECKED",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc2)

	// -- SAIR
	_oSbMnOpc3 := TMenuItem():New(_oMnuOpcoes,"Sair",,,,{|| IIF( sfVldSair(@_lFixaWnd, @mvSair), _oWmsFraPlt:END(), Nil ) },,"FINAL",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOpc3)

	// cria o panel do cabecalho - botoes de operacao
	_oPnlFraPlt := TPanel():New(000,000,nil,_oWmsFraPlt,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlFraPlt:Align:= CONTROL_ALIGN_TOP

	// -- BOTAO COM MAIS OPCOES
	_oBmpOpcoes := TBtnBmp2():New(000,000,060,022,"SDUAPPEND",,,,{|| Nil },_oPnlFraPlt,"",,.T.)
	_oBmpOpcoes:Align := CONTROL_ALIGN_RIGHT
	_oBmpOpcoes:SetPopupMenu(_oMnuOpcoes)

	// -- NOVO VOLUME
	_oBmpNovoVol := TBtnBmp2():New(000,000,060,022,"AVGARMAZEM",,,,{|| sfNovoVolume() },_oPnlFraPlt,"Novo Volume",,.T.)
	_oBmpNovoVol:Align := CONTROL_ALIGN_LEFT

	// -- CONSULTA DETALHES
	_oBmpFraCons := TBtnBmp2():New(000,000,060,022,"MDIHELP",,,,{|| sfDetFra()} ,_oPnlFraPlt,"Informações",,.T.)
	_oBmpFraCons:Align := CONTROL_ALIGN_LEFT

	// quando for single ele apresenta o botão
	If (_lROSin)
		// -- BLOQ VOLUME
		_oBmpCaixa := TBtnBmp2():New(000,000,060,022,"AVGBOX1",,,,{|| IIF( ! _lUnit, _oGetNova:Disable(), _oGetNova:Enable()), IIF( ! _lUnit, _lUnit := .T., _lUnit := .F.)  },_oPnlFraPlt,"Bloqueia Volume",,.T.)
		_oBmpCaixa:Align := CONTROL_ALIGN_LEFT
	EndIf

	// tipos de embalagem
	_oSayCodEmb := TSay():New(024,003,{||"Embalagem"},_oWmsFraPlt,,,.F.,.F.,.F.,.T.)
	_oCmbCodEmb := TComboBox():New(023,034,{|u| If(PCount()>0,_cTpEmbala:=u,_cTpEmbala)},_aOpcoesEmb,085,008,_oWmsFraPlt,,,,,,.T.,,"",,,,,,,_cTpEmbala)
	_oCmbCodEmb:bWhen := {|| Len(_aOpcoesEmb) != 0 }

	// controle por palete - ETQ NOVA
	_oSayNova := TSay():New(037,003,{||"Etq.Nova"},_oWmsFraPlt,,,.F.,.F.,.F.,.T.)
	_oGetNova := TGet():New(035,034,{|u| If(PCount()>0,_cEtqNova:=u,_cEtqNova)},_oWmsFraPlt,050,010,_cMskEtiq,{|| sfVldEtiqFra(_cEtqNova, _cEtqAntiga, _cCodBar, "NOVA", @_lOk, mvCodPro, mvOper, Nil) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtqNova",,)
	// validação do campo
	If(_lROKit)
		_oGetNova:Disable()
	EndIf

	// controle por palete - ETQ Antiga
	_oSayAntiga := TSay():New(050,003,{||"Etq.Antiga"},_oWmsFraPlt,,,.F.,.F.,.F.,.T.)
	_oGetAntiga := TGet():New(048,034,{|u| If(PCount()>0,_cEtqAntiga:=u,_cEtqAntiga)},_oWmsFraPlt,050,010,_cMskEtiq,{|| sfVldEtiqFra(_cEtqNova, _cEtqAntiga, _cCodBar, IIF(((_lROKit) .Or. (_lROSin)), "KIT", "ANTIGA"), @_lOk, mvCodPro, mvOper, Nil) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtqAntiga",,)

	// controle por palete - ETQ EAN
	_oSayEan := TSay():New(063,003,{||"Cod.Barras"},_oWmsFraPlt,,,.F.,.F.,.F.,.T.)
	_oGetEan := TGet():New(061,034,{|u| If(PCount()>0,_cCodBar:=u,_cCodBar)},_oWmsFraPlt,050,010,,{|| sfVldEtiqFra(_cEtqNova, _cEtqAntiga, _cCodBar, "CODBAR", @_lOk, mvCodPro, mvOper, _cTpIdEtiq) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cCodBar",,)
	// validação do campo
	If(_lROKit) .Or. (_lROSin)
		_oGetEan:Disable()
	EndIf

	// browse com a listagem dos produtos separados
	_oBrwFraPlt := MsNewGetDados():New(078,000,148,118,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsFra),'AllwaysTrue()','','AllwaysTrue()',_oWmsFraPlt,_aHeadFra,_aColsFra)

	// foco na etq de volume nova
	_oGetNova:SetFocus()

	// ativa a tela
	_oWmsFraPlt:Activate(,,,.F.,{|| _lFixaWnd },,)

	// se sair, sem desmontar, varre todos os registros para liberar a movimentacao
	If (mvSair) .And. (_lFixaWnd)

		// varre todos os registro
		For _nX := 1 to Len(_aQryZ08)
			// atualizo o status do mapa
			dbSelectArea("Z08")
			Z08->(DbGoTo(_aQryZ08[_nX][4]))
			RecLock("Z08")
			Z08->Z08_STATUS := "P" // P-Planejado / R-Realizado / M-Movimento / E-Erro
			Z08->(MsUnLock())

		Next _nX

	EndIf

Return (_lOk)

// ** rotina para validação da etiqueta informada
Static Function sfVldEtiqFra(mvNovaEtiq, mvAntigaEtiq, mvCodBar, mvTipo, mvRet, mvCodPro, mvOper, mvTpIdEtiq)

	// query na Z16
	local _cQryZ16 := ""
	// query na SB1
	local _cQrySB1 := ""
	// array para complemento do pallet
	local _aComPlt := {}
	// código de produto
	local _cCodPro := mvCodPro
	// validação da quantidade do volume
	local _nTotVol := 0
	// informa quantidade manual
	local _lInfQtdMan := .F.
	// total de produtos
	local _aTotProd := {}
	local _nTotProd := 0
	// controle de for
	local _nX,_nZ08,_nZ16 := 0
	// quantidade
	local _nQtd      := 1
	local _nQtdSegUM := 0

	// volumes (caixas) ja selecionados no pedido de venda
	local _lVolJaDef := U_FtWmsParam("WMS_EXPEDICAO_ESCOLHE_VOLUMES", "L", .F., .F., Nil, _cCodCliMov, _cLjCliMov, Nil, Nil)

	// permite conferencia/recebimento por volumes
	local _lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.F.,.F.,"", _cCodCliMov, _cLjCliMov, Nil, Nil)

	// retorno positivo
	mvRet := .T.

	// validação pra garantir que vai pro registro certo para movimentação unitária
	If (_lUnit)
		mvTipo := "KIT"
	EndIf

	// validações etiqueta nova
	If (mvTipo == "NOVA")

		// só valida se o campo já tiver sido preenchido
		If ( ! Empty(mvNovaEtiq))
			dbSelectArea("Z11")
			Z11->( dbSetOrder(1) ) // Z11_FILIAL+Z11_CODETI
			If (! Z11->( dbSeek( xFilial("Z11")+mvNovaEtiq ) ))
				U_FtWmsMsg("A etiqueta nova informada não foi encontrada!")
				mvRet := .F.
				Return (mvRet)
			ElseIf (Z11->Z11_TIPO <> "04")
				U_FtWmsMsg("A etiqueta nova informada é inválida!")
				mvRet := .F.
				Return (mvRet)
			EndIf

			// valido se aquele volume já foi utilizada
			_cQryZ16 := " SELECT COUNT(*) "
			_cQryZ16 += "  FROM "+RetSqlTab("Z16")+" (nolock) "
			_cQryZ16 += " WHERE Z16_ETQVOL = '"+mvNovaEtiq+"' "
			_cQryZ16 += " AND "+RetSqlCond("Z16")

			// verifico a quantidade, se for maior indica que já foi utilizada, então não deixa prosseguir
			If (U_FtQuery(_cQryZ16) > 0)
				// mensagem
				U_FtWmsMsg("A Nova Etiqueta de volume informada já foi utilizada. Verifique!")
				// variavel de controle
				mvRet := .F.
				// retorno
				Return (mvRet)
			EndIf

			// valido se aquele volume está naquele pallet
			_cQryZ16 := " SELECT COUNT(DISTINCT Z16_CODPRO) "
			_cQryZ16 += " FROM " + RetSqlTab("Z16")
			_cQryZ16 += " WHERE " + RetSqlCond("Z16")
			_cQryZ16 += " AND Z16_ETQVOL = '" + mvNovaEtiq + "' "
			_cQryZ16 += " AND Z16_ETQPAL = '"+_cPltAutFra+"' "
			_cQryZ16 += " AND Z16_SALDO > 0 "

			// o valor todo na variavel
			_nTotVol := U_FtQuery(_cQryZ16)

			If (_nTotVol > 0)
				U_FtWmsMsg("Etiqueta já utilizada para esse pallet. Verifique!")
				mvRet := .F.
				Return (mvRet)
			EndIf

			// variavel de retorno
			mvRet := .T.
		EndIf

		// valida etiqueta Antiga
	ElseIf (mvTipo == "ANTIGA")

		// só valida se o campo já tiver sido preenchido
		If ( ! Empty(mvAntigaEtiq) )

			// seek na Z11 para encontrar a etiqueta
			dbSelectArea("Z11")
			Z11->( dbSetOrder(1) ) // Z11_FILIAL+Z11_CODETI
			If (! Z11->( dbSeek( xFilial("Z11")+mvAntigaEtiq ) ))
				U_FtWmsMsg("A etiqueta antiga informada não foi encontrada!")
				mvRet := .F.
				Return (mvRet)
			ElseIf (Z11->Z11_TIPO <> "04")
				U_FtWmsMsg("A etiqueta informada é inválida!")
				mvRet := .F.
				Return (mvRet)
			EndIf

			// valido se aquele volume está naquele pallet
			_cQryZ16 := " SELECT ISNULL(SUM(Z16_SALDO),0) "
			// composicao do palete
			_cQryZ16 += " FROM " + RetSqlTab("Z16")
			// volumes reservados
			If (_lVolJaDef) .And. (_lCtrVolume)
				_cQryZ16 += "        INNER JOIN " + RetSqlTab("Z45")
				_cQryZ16 += "                ON " + RetSqlCond("Z45")
				_cQryZ16 += "                   AND Z45_ETQPAL = Z16_ETQPAL
				_cQryZ16 += "                   AND Z45_CODPRO = Z16_CODPRO
				_cQryZ16 += "                   AND Z45_ETQVOL = Z16_ETQVOL
			EndIf
			// filtro padrao
			_cQryZ16 += " WHERE " + RetSqlCond("Z16")
			_cQryZ16 += " AND Z16_ETQVOL = '" + mvAntigaEtiq + "' "
			_cQryZ16 += " AND Z16_ETQPAL = '" + _cIdPalete + "' "
			_cQryZ16 += " AND Z16_SALDO > 0 "

			// o valor todo na variavel
			_nTotVol := U_FtQuery(_cQryZ16)

			// verifico a quantidade, se não encontrar nada, avisa o usuário
			If (Empty(_nTotVol)) .Or. (_nTotVol == 0)
				// mensagem
				U_FtWmsMsg("A Etiqueta de volume informada não foi encontrada nesse pallet ou não possui saldo. Verifique!")
				// variavel de controle
				mvRet := .F.
				// retorno
				Return (mvRet)
			EndIf

			// valido se aquele volume está naquele pallet
			_cQryZ16 := " SELECT COUNT(DISTINCT Z16_CODPRO) "
			_cQryZ16 += "  FROM " + RetSqlTab("Z16")
			_cQryZ16 += " WHERE "+RetSqlCond("Z16")
			_cQryZ16 += " AND Z16_VOLORI = '" + mvAntigaEtiq + "' "
			_cQryZ16 += " AND Z16_ETQPAL = '"+_cPltAutFra+"' "
			_cQryZ16 += " AND Z16_SALDO > 0 "

			// o valor todo na variavel
			_nTotVol := U_FtQuery(_cQryZ16)

			If (_nTotVol > 0)
				U_FtWmsMsg("Etiqueta já utilizada para esse pallet. Verifique!")
				mvRet := .F.
				Return (mvRet)
			EndIf

			// variavel de retorno
			mvRet := .T.
		EndIf

	ElseIf (mvTipo == "CODBAR")

		// só valida se o campo já tiver sido preenchido
		If ( ! Empty(mvCodBar) )

			// somente para transações unitarias
			If ( ! Empty(mvNovaEtiq) )  .And. ( mvAntigaEtiq != mvNovaEtiq )
				// valido se aquele volume já foi gravado
				_cQryZ16 := " SELECT COUNT(*) "
				_cQryZ16 += " FROM "+RetSqlTab("Z16") + " (nolock) "
				_cQryZ16 += " WHERE "+RetSqlCond("Z16")
				_cQryZ16 += " AND Z16_ETQVOL = '" + mvNovaEtiq + "' "
				_cQryZ16 += " AND Z16_CODBAR = '" + mvCodBar + "' "
				_cQryZ16 += " AND Z16_SALDO > 0 "

				// verifico a quantidade, se for maior indica que já foi utilizada, então não deixa prosseguir
				If (U_FtQuery(_cQryZ16) > 0)
					// mensagem
					U_FtWmsMsg("A Nova Etiqueta de volume informada já foi utilizada nesse pallet. Verifique!")
					// variavel de controle
					mvRet := .F.
					// retorno
					Return (mvRet)
				EndIf
			EndIf

			// validação dos dados da etq e se não der certo avisa o usuário
			If ( ! U_FtCodBar(mvCodBar, @_cCodPro, @_lInfQtdMan, "", mvTpIdEtiq, _cCodCliMov) )
				// mensagem
				U_FtWmsMsg("Não foi possível consultar a etiqueta de EAN!")
				// variavel de controle
				mvRet := .F.
				// retorno
				Return (mvRet)
			EndIf

			// somente para transações unitarias
			If ( ! Empty(mvCodPro))
				// valida se o produto é o que foi esperado
				If (_cCodPro <> mvCodPro)
					// mensagem
					U_FtWmsMsg("Produto não compatível com o solicitado para esse fracionamento!")
					// variavel de controle
					mvRet := .F.
					// retorno
					Return (mvRet)
				EndIf
			EndIf

			// informação de quantidade manual
			If (_lInfQtdMan)
				// tela para informar a quantidade
				sfInfQuant(@_nQtd, @_nQtdSegUM)
			EndIf

			// composição do array sfRetDadosPlt
			/*
			1  - Z16_CODPRO
			2  - Z16_NUMSEQ
			3  - QTDINF
			4  - Z16_ENDATU
			5  - Z16_ETQPAL
			6  - Z16_LOCAL
			7  - Z16_EMBALA
			8  - Z16_TPESTO
			9  - R_E_C_N_O_
			10 - Z16_SALDO
			11 - Z16_LOTCTL
			12 - Z16_PLTCLI
			13 - Z16_VLDLOT
			14 - Z16_QTSEGU
			15 - Z16_NUMSER
			16 - Z16_DTSERI
			*/

			// 1º - Dados do pallet e volume antigos (utilizando o pallet direto da tabela pra não confundir como novo pallet)
			_aComPlt := sfRetDadosPlt(mvAntigaEtiq, _cCodPro, Z08->Z08_PALLET, .F.)

			// valido se há informações no resultado da query
			If (Len(_aComPlt) <= 0)
				// mensagem
				U_FtWmsMsg("Pallet sem saldo para o produto ou inexistente!")
				// variavel de controle
				mvRet := .F.
				// foco em objeto
				_oGetNova:SetFocus()
				// retorno
				Return (mvRet)
			EndIf

			// somente para transações unitarias
			If ( ! Empty(mvNovaEtiq))
				// faz a duplicação de dados da etiqueta Antiga para a nova
				If( ! sfGrvNewEtq (mvAntigaEtiq, mvNovaEtiq) )
					// mensagem
					U_FtWmsMsg("Não foi possível salvar os dados da etiqueta lida.")
					// variavel de controle
					mvRet := .F.
					// retorno
					Return (mvRet)
				EndIf
			EndIf

			// grava os dados do novo pallet baseado nas informações do pallet antigo
			If ( ! sfGrNovoCompPlt(_aComPlt, _nQtd, _nQtdSegUM, .F.) )
				// mensagem
				U_FtWmsMsg("Não foi possível salvar os dados do novo registro.")
				// variavel de controle
				mvRet := .F.
				// retorno
				Return (mvRet)
			EndIf

			// caso as etiquetas sejam iguais, vai perguntar onde quer deixar a mercadoria restante
			If ( mvAntigaEtiq == mvNovaEtiq )
				// mensagem
				U_FtWmsMsg("Será necessário informar a etiqueta nova onde o saldo desse volume ficará armazenado!")

				// zera a variavel pra fazer a gravação correta
				_cEtqNova := Space(Len(_cEtqNova))

				// chama tela pra informar novo volume
				sfInfVol(@_cEtqNova)

				// composição do array sfRetDadosPlt
				/*
				1  - Z16_CODPRO
				2  - Z16_NUMSEQ
				3  - QTDINF
				4  - Z16_ENDATU
				5  - Z16_ETQPAL
				6  - Z16_LOCAL
				7  - Z16_EMBALA
				8  - Z16_TPESTO
				9  - R_E_C_N_O_
				10 - Z16_SALDO
				11 - Z16_LOTCTL
				12 - Z16_PLTCLI
				13 - Z16_VLDLOT
				14 - Z16_QTSEGU
				15 - Z16_NUMSER
				16 - Z16_DTSERI
				*/

				// 1º - Dados do pallet e volume antigos sem o produto para poder gravar corretamente o saldo
				_aComPlt := sfRetDadosPlt(mvAntigaEtiq, _cCodPro, Z08->Z08_PALLET, .T.)

				// valida se foi preenchido a variavel
				If ( ! Empty(_cEtqNova) )
					// faz a duplicação de dados da etiqueta Antiga para do saldo no Volume
					If( ! sfGrvNewEtq (mvAntigaEtiq, _cEtqNova))
						U_FtWmsMsg("Não foi possível salvar os dados da etiqueta lida para o saldo do volume.")
						mvRet := .F.
						Return (mvRet)
					EndIf

					// gravo o novo pallet
					If ( ! sfGrNovoCompPlt(_aComPlt, 0, 0, .T.) )
						U_FtWmsMsg("Não foi possível salvar os dados do novo registro.")
						mvRet := .F.
						Return (mvRet)
					EndIf

					// para cada produto informado, alimenta o array
					For _nX := 1 to Len(_aComPlt)
						aAdd(_aSldPrd, { _aComPlt[_nX][1], _aComPlt[_nX][5], _aComPlt[_nX][10], mvAntigaEtiq, _cEtqNova} )
					Next _nX

					// zera a variavel pra fazer a gravação correta
					_cEtqNova := Space(Len(_cEtqNova))
				EndIf
			EndIf

			// limpa os dados e seta o focus
			_cCodBar    := Space(13)
			// somente para transações unitarias
			_cEtqAntiga := Space(TamSx3("Z11_CODETI")[1])
			// variavel de controle
			mvRet := .T.

			//Refresh no browse
			sfSelDadosFra()
		EndIf

		// caso seja a retirada de um volume completo não preenche etiq nova nem codbar
	ElseIf (mvTipo == "KIT")

		// só valida se o campo já tiver sido preenchido
		If ( ! Empty(mvNovaEtiq) )
			dbSelectArea("Z11")
			Z11->( dbSetOrder(1) ) // Z11_FILIAL+Z11_CODETI
			If (! Z11->( dbSeek( xFilial("Z11")+mvNovaEtiq ) ))
				U_FtWmsMsg("A etiqueta nova informada não foi encontrada!")
				mvRet := .F.
				Return (mvRet)
			ElseIf (Z11->Z11_TIPO <> "04")
				U_FtWmsMsg("A etiqueta nova informada é inválida!")
				mvRet := .F.
				Return (mvRet)
			EndIf

			// valido se aquele volume já foi gravado
			_cQryZ16 := " SELECT COUNT(*) "
			_cQryZ16 += "  FROM "+RetSqlTab("Z16")
			_cQryZ16 += " WHERE Z16_ETQVOL = '"+mvNovaEtiq+"' "
			_cQryZ16 += " AND "+RetSqlCond("Z16")

			// verifico a quantidade, se for maior indica que já foi utilizada, então não deixa prosseguir
			If (U_FtQuery(_cQryZ16) > 0)
				// mensagem
				U_FtWmsMsg("A Nova Etiqueta de volume informada já foi utilizada. Verifique!")
				// variavel de controle
				mvRet := .F.
				// retorno
				Return (mvRet)
			EndIf

			// variavel de retorno
			mvRet := .T.
		EndIf

		// validação da etiqueta antiga
		If ( ! Empty(mvAntigaEtiq) )

			// valida se a etiqueta é correta
			dbSelectArea("Z11")
			Z11->( dbSetOrder(1) ) // Z11_FILIAL+Z11_CODETI
			If (! Z11->( dbSeek( xFilial("Z11")+mvAntigaEtiq ) ))
				U_FtWmsMsg("A etiqueta antiga informada não foi encontrada!")
				mvRet := .F.
				Return (mvRet)
			ElseIf (Z11->Z11_TIPO <> "04")
				U_FtWmsMsg("A etiqueta informada é inválida!")
				mvRet := .F.
				Return (mvRet)
			EndIf

			// valido se aquele volume está naquele pallet
			_cQryZ16 := " SELECT DISTINCT Z16_CODPRO, ISNULL(SUM(Z16_SALDO) - "
			_cQryZ16 += " ( SELECT ISNULL(SUM(Z16_SALDO),0) "
			_cQryZ16 += " 	FROM  " + RetSqlName("Z16") + " Z16N "
			_cQryZ16 += " 	WHERE Z16N.Z16_FILIAL = Z16_FILIAL "
			_cQryZ16 += "     AND Z16N.D_E_L_E_T_ = '' "
			_cQryZ16 += "	  AND Z16N.Z16_CODPRO = Z16.Z16_CODPRO "
			_cQryZ16 += " 	  AND Z16N.Z16_ETQVOL = Z16.Z16_ETQVOL "
			_cQryZ16 += " 	  AND Z16N.Z16_LOTCTL = Z16.Z16_LOTCTL "
			_cQryZ16 += " 	  AND Z16N.Z16_ETQPAL = '"+_cPltAutFra+"' ), 0) SALDO, "
			_cQryZ16 += "  Z16_LOTCTL "
			_cQryZ16 += "  FROM " + RetSqlTab("Z16")
			// volumes reservados
			If (_lVolJaDef) .And. (_lCtrVolume)

				_cQryZ16 += "        INNER JOIN " + RetSqlTab("Z05") + " (nolock) "
				_cQryZ16 += "                ON " + RetSqlCond("Z05")
				_cQryZ16 += "                   AND Z05_NUMOS = '" + _cNumOrdSrv + "' "

				_cQryZ16 += "        INNER JOIN " + RetSqlTab("SC9") + " (nolock) "
				_cQryZ16 += "                ON " + RetSqlCond("SC9")
				_cQryZ16 += "                   AND C9_CARGA = Z05_CARGA "
				_cQryZ16 += "                   AND C9_PRODUTO = Z16_CODPRO "

				_cQryZ16 += "        INNER JOIN " + RetSqlTab("Z45") + " (nolock) "
				_cQryZ16 += "                ON " + RetSqlCond("Z45")
				_cQryZ16 += "                   AND Z45_ETQPAL = Z16_ETQPAL "
				_cQryZ16 += "                   AND Z45_CODPRO = Z16_CODPRO "
				_cQryZ16 += "                   AND Z45_ETQVOL = Z16_ETQVOL "
				_cQryZ16 += "                   AND Z45_PEDIDO = C9_PEDIDO "
				_cQryZ16 += "                   AND Z45_ITEM = C9_ITEM "

			EndIf
			// filtro padrao
			_cQryZ16 += " WHERE Z16_ETQVOL = '" + mvAntigaEtiq + "' "
			_cQryZ16 += "   AND Z16_ETQPAL = '" + Z08->Z08_PALLET + "' "
			_cQryZ16 += "   AND Z16_SALDO > 0 "
			_cQryZ16 += "   AND "+RetSqlCond("Z16")
			_cQryZ16 += " GROUP BY Z16_CODPRO, Z16_ETQVOL, Z16_LOTCTL "

			memowrit("C:\query\twsa011_valida_saldo_vldetiqfra.txt", _cQryZ16)

			// o valor todo na variavel
			_aTotProd := U_SqlToVet(_cQryZ16)

			// verifico a quantidade, se não encontrar nada, avisa o usuário
			If (Len(_aTotProd) == 0)
				// mensagem
				U_FtWmsMsg("A Etiqueta de volume informada não foi encontrada nesse pallet ou não possui saldo - EAN. Verifique!")
				// variavel de controle
				mvRet := .F.
				// retorno
				Return (mvRet)
				// volume não é compatível com o solicitado
			ElseIf ( Len(_aTotProd) < Len(_aQryZ08) )
				// controle de volumes por palete
				_nTotProd := 0

				// validação para produtos já informados
				For _nZ16 := 1 to Len(_aTotProd)
					// para cada produto na Z08
					For _nZ08 := 1 to Len(_aQryZ08)
						// caso os produtos sejam iguais
						If (_aTotProd[_nZ16][1] == _aQryZ08[_nZ08][1]) .And. (_aTotProd[_nZ16][3] == _aQryZ08[_nZ08][5])
							// para cada produto encontrada, aumenta um na variavel
							_nTotProd++
						EndIf
					Next _nZ08
				Next _nZ16

				// se não encontrou nenhum produto compatível, avisa o usuário
				If (_nTotProd == 0)
					U_FtWmsMsg("Volume não compatível com o solicitado. Verifique!")
					mvRet := .F.
					Return (mvRet)
				EndIf
			EndIf

			// valido se aquele volume está naquele pallet
			_cQryZ16 := " SELECT COUNT(DISTINCT Z16_CODPRO) Z16_CODPRO "
			_cQryZ16 += " FROM " + RetSqlTab("Z16") + " (nolock) "
			_cQryZ16 += " WHERE Z16_ETQVOL = '" + mvAntigaEtiq + "' "
			_cQryZ16 += " AND Z16_ETQPAL = '"+_cPltAutFra+"' "
			_cQryZ16 += " AND "+RetSqlCond("Z16")

			// o valor todo na variavel
			_nTotVol := U_FtQuery(_cQryZ16)

			// validação da quantidade ou da etiqueta utilizada
			If (_nTotVol > 0)
				U_FtWmsMsg("Etiqueta já utilizada para esse pallet. Verifique!")
				mvRet := .F.
				Return (mvRet)
			EndIf

			// se informa manual a quantidade ou se o volume tem mais do que o solicitado
			If (_lInfQtdMan) .Or. (mvOper == "SINGLE")
				// tela para informar a quantidade
				sfInfQuant(@_nQtd, @_nQtdSegUM)
			EndIf

			// validação para quantidade informada
			For _nZ16 := 1 to Len(_aTotProd)
				// para cada produto na Z08
				For _nZ08 := 1 to Len(_aQryZ08)
					// caso os produtos sejam iguais
					If (_aTotProd[_nZ16][1] == _aQryZ08[_nZ08][1])
						// para cada produto encontrado, valida a quantidade
						If (_nQtd > _aTotProd[_nZ16][2])
							// mensagem
							U_FtWmsMsg("A quantidade informada é maior do que o saldo do produto para o volume informado!","ATENCAO")
							// variavel de retorno
							_mvRet := .F.
							// foco em objeto
							_oGetAntiga:SetFocus()
							// retorno
							Return (mvRet)
						EndIf

						// se for pegar os volumes, valida se restou saldo na etq antiga para não duplicar Z16
						If (Empty(mvNovaEtiq))
							If ( (_aTotProd[_nZ16][2] - _nQtd) != 0 )
								// caso a quantidade solicitada menos a quantidade existente no pallet for maior que 0 informa ao usuário
								U_FtWmsMsg("Para utilizar a Etq.Antiga é necessário pegar a quantidade total do volume!","ATENCAO")
								// variavel de retorno
								_mvRet := .F.
								_oGetAntiga:SetFocus()
								Return (mvRet)
							EndIf
						EndIf
					EndIf
				Next _nZ08
			Next _nZ16

			// composição do array sfRetDadosPlt
			/*
			1  - Z16_CODPRO
			2  - Z16_NUMSEQ
			3  - QTDINF
			4  - Z16_ENDATU
			5  - Z16_ETQPAL
			6  - Z16_LOCAL
			7  - Z16_EMBALA
			8  - Z16_TPESTO
			9  - R_E_C_N_O_
			10 - Z16_SALDO
			11 - Z16_LOTCTL
			12 - Z16_PLTCLI
			13 - Z16_VLDLOT
			14 - Z16_QTSEGU
			15 - Z16_NUMSER
			16 - Z16_DTSERI
			*/

			// 1º - Dados do pallet e volume antigos (utilizando o pallet direto da tabela pra não confundir como novo pallet)
			_aComPlt := sfRetDadosPlt(mvAntigaEtiq, "", Z08->Z08_PALLET, .F.)

			// valido se há informações
			If (Len(_aComPlt) <= 0)
				U_FtWmsMsg("Pallet sem saldo para o produto ou volume inexistente!")
				mvRet := .F.
				_oGetNova:SetFocus()
				Return (mvRet)
			EndIf

			// grava os dados do novo pallet
			If ( ! sfGrNovoCompPlt(_aComPlt, _nQtd, _nQtdSegUM, .F.) )
				U_FtWmsMsg("Não foi possível salvar os dados do novo registro.")
				mvRet := .F.
				Return (mvRet)
			EndIf

			// limpa os dados e seta o focus
			_cCodBar    := Space(13)
			// somente para transações unitarias
			_cEtqAntiga := Space(TamSx3("Z11_CODETI")[1])
			_cEtqNova   := Space(TamSx3("Z11_CODETI")[1])

			// detalho o foco ao final da operação
			If (mvOper == "SINGLE")
				_oGetAntiga:SetFocus()
			Else
				_oGetNova:SetFocus()
			EndIf

			mvRet := .T.
			//Refresh no browse
			sfSelDadosFra()
		EndIf

	EndIf

Return(mvRet)

// ** retorna os dados do pallet com base na etiqueta de volume
Static Function sfRetDadosPlt(mvAntigaEtiq, mvProd, mvPlt, mvSld)

	// query na Z16
	local _cQryZ16 := ""
	// array de retorno
	local _aDados := {}

	//Dados do pallet
	_cQryZ16 := " SELECT Z16_CODPRO, Z16_NUMSEQ, 0 QTDINF, Z16_ENDATU, Z16_ETQPAL, Z16_LOCAL, Z16_EMBALA, Z16_TPESTO, R_E_C_N_O_, Z16_SALDO, Z16_LOTCTL, Z16_PLTCLI, Z16_VLDLOT, Z16_QTSEGU, Z16_NUMSER, Z16_DTSERI "
	_cQryZ16 += "  FROM "+RetSqlTab("Z16")+" (nolock) "
	_cQryZ16 += " WHERE Z16_ETQVOL = '"+mvAntigaEtiq+"' "

	// caso o produto venha preenchido
	If ( ! mvSld) .And. ( ! Empty(mvProd) )
		_cQryZ16 += " AND Z16_CODPRO = '"+mvProd+"' "
	EndIf

	// caso seja saldo, ele desconsidera o produto informado e grava apenas o que será movimentado
	If (mvSld) .And. ( ! Empty(mvProd) )
		_cQryZ16 += " AND Z16_CODPRO <> '"+mvProd+"' "
	EndIf

	_cQryZ16 += " AND Z16_ETQPAL = '" + mvPlt + "' "
	_cQryZ16 += " AND Z16_SALDO > 0 "
	_cQryZ16 += " AND "+RetSqlCond("Z16")

	memowrit("C:\query\TWMSA011_sfvldetiqfra.txt",_cQryZ16)

	// dados jogados no array
	_aDados := U_SqlToVet(_cQryZ16,{"Z16_VLDLOT", "Z16_DTSERI"})

Return (_aDados)

// ** rotina para geração do novo pallet
Static Function sfGrNovoCompPlt(mvArrNewPlt, mvQtd, mvQtdSegUM, mvSldVol)

	// controle de transação
	local _lRet := .T.
	// unitizador
	local _cCodUnit := ""
	// controle do for
	local _nX := 0
	// variaveis de data
	local _cDtTran := Date() // data da geração da Z16
	local _cHrTran := Time() // hora da geração da Z16

	// tratativa diferenciada para quando a variável mvSldVol for verdadeira

	// controle de confirmacao para geracao do novo palete
	If (_lRet)

		// inicia transacao
		BEGIN TRANSACTION

			// composição do array sfRetDadosPlt / mvArrNewPlt
			/*
			1  - Z16_CODPRO
			2  - Z16_NUMSEQ
			3  - QTDINF
			4  - Z16_ENDATU
			5  - Z16_ETQPAL
			6  - Z16_LOCAL
			7  - Z16_EMBALA
			8  - Z16_TPESTO
			9  - R_E_C_N_O_
			10 - Z16_SALDO
			11 - Z16_LOTCTL
			12 - Z16_PLTCLI
			13 - Z16_VLDLOT
			14 - Z16_QTSEGU
			15 - Z16_NUMSER
			16 - Z16_DTSERI
			*/

			// todos os registros do array serão gravados
			For _nX := 1 to Len(mvArrNewPlt)

				// valida o saldo, ou quantidade informada
				If ((mvSldVol) .And. (mvArrNewPlt[_nX][10] == 0)) .Or. (( ! mvSldVol ) .And. (mvQtd)==0)
					Loop
				EndIf

				// define o codigo do unitizador
				_cCodUnit := Z11->Z11_UNITIZ

				// gravo o novo pallet na Z16
				dbSelectArea("Z16")
				RecLock("Z16",.T.)
				Z16->Z16_FILIAL := xFilial("Z16")
				Z16->Z16_ETQPAL := _cPltAutFra
				Z16->Z16_UNITIZ := _cCodUnit
				Z16->Z16_CODPRO := mvArrNewPlt[_nX][1]
				Z16->Z16_NUMSEQ := mvArrNewPlt[_nX][2]
				Z16->Z16_QUANT  := IIF(mvSldVol, mvArrNewPlt[_nX][10], mvQtd)
				Z16->Z16_QTDVOL := IIF(mvSldVol, mvArrNewPlt[_nX][10], mvQtd)
				Z16->Z16_SALDO  := IIF(mvSldVol, mvArrNewPlt[_nX][10], mvQtd)
				Z16->Z16_STATUS := "P" // P=Parcial / T=Total / V-Vazio
				Z16->Z16_ENDATU := mvArrNewPlt[_nX][4]
				Z16->Z16_ORIGEM := IIF(mvSldVol, "SLD", "FRA")
				Z16->Z16_PLTORI := mvArrNewPlt[_nX][5]
				Z16->Z16_LOCAL  := mvArrNewPlt[_nX][6]
				Z16->Z16_EMBALA := _cTpEmbala // conforme definido pelo usuário
				Z16->Z16_TPESTO := mvArrNewPlt[_nX][8]
				Z16->Z16_CODBAR := _cCodBar
				Z16->Z16_ETQVOL := IIF( Empty(_cEtqNova),_cEtqAntiga,_cEtqNova )
				Z16->Z16_VOLORI := _cEtqAntiga
				Z16->Z16_DATA   := _cDtTran
				Z16->Z16_HORA   := _cHrTran
				Z16->Z16_LOTCTL := mvArrNewPlt[_nX][11]
				Z16->Z16_PLTCLI := mvArrNewPlt[_nX][12]
				Z16->Z16_VLDLOT := mvArrNewPlt[_nX][13]
				Z16->Z16_QTSEGU := IIF(mvSldVol, mvArrNewPlt[_nX][14], mvQtdSegUM)
				Z16->Z16_NUMSER := mvArrNewPlt[_nX][15]
				Z16->Z16_DTSERI := mvArrNewPlt[_nX][16]
				Z16->(MsUnLock())
			Next _nX

			// finaliza transacao
		END TRANSACTION

	EndIf

Return(_lRet)

// ** funcao para filtrar os itens já fracionados
Static Function sfSelDadosFra()
	// query que retorna os dados
	Local _cQuery := ""
	// reinicia variaveis dos itens
	_aColsFra := {}

	// verifica a necessidade de criar o Header
	If (Len(_aHeadFra)==0)

		aAdd(_aHeadFra,{"Lido"      , "Z16_SALDO" , _cMaskQuant, TamSx3("Z16_SALDO")[1] ,TamSx3("Z16_SALDO")[2] , Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadFra,{"Esperado"  , "Z08_QUANT" , _cMaskQuant, TamSx3("Z08_QUANT")[1] ,TamSx3("Z08_QUANT")[2] , Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadFra,{"Qtd Seg UM", "Z08_QTSEGU", _cMaskQuant, TamSx3("Z08_QTSEGU")[1],TamSx3("Z08_QTSEGU")[2], Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadFra,{"Produto"   , "Z08_PRODUT", ""         , TamSx3("Z08_PRODUT")[1],0                      , Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadFra,{"Descr."    , "B1_DESC"   , ""         , TamSx3("B1_DESC")[1]   ,0                      , Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadFra,{"Lote"      , "Z08_LOTCTL", ""         , TamSx3("Z08_LOTCTL")[1],0                      , Nil,Nil,"C",Nil,"R",,,".F." })

	EndIf

	// monta a query para buscar os itens já fracionados
	_cQuery := " SELECT ISNULL((SELECT SUM(Z16_SALDO) FROM " + RetSqlTab("Z16") + " (nolock)  WHERE " + RetSqlCond("Z16") + " AND Z16_ETQPAL = '"+_cPltAutFra+"' AND Z16_CODPRO = Z08_PRODUT AND Z16_ORIGEM = 'FRA' ),0) Z16_SALDO, "
	_cQuery += "  Z08_QUANT, Z08_QTSEGU, Z08_PRODUT, B1_DESC, Z08_LOTCTL, '.F.' IT_DEL "
	_cQuery += "  FROM  "+RetSqlTab("Z08")+" (nolock) "
	_cQuery += " INNER JOIN "+RetSqlTab("SB1")+" (nolock)  ON B1_COD = Z08_PRODUT AND "+RetSqlCond("SB1")
	_cQuery += " WHERE  "+RetSqlCond("Z08")
	_cQuery += "   AND Z08_NUMOS = '" + _cNumOrdSrv + "' "
	_cQuery += "   AND Z08_PALLET = '" + _cIdPalete + "' "

	// filtragem marota do browse quando for apenas um produto
	IIF( ! Empty(_cProdFra), _cQuery += " AND Z08_PRODUT = '" + _cProdFra + "' ", Nil)
	_cQuery += " GROUP BY Z08_QUANT, Z08_QTSEGU, Z08_PRODUT, B1_DESC, Z08_LOTCTL "
	_cQuery += " ORDER BY Z08_PRODUT "

	memowrit("c:\query\twmsa011_sfSelDadosFra.txt",_cQuery)

	// atualiza os dados do vetor
	_aColsFra := U_SqlToVet(_cQuery)

	// se não tiver nada, monta um browse limpo
	If (Len(_aColsFra) == 0)
		aAdd(_aColsFra, {0, 0, 0, "", "", "", .F.} )
	EndIf

	// atualiza os itens do browse
	If (_oBrwFraPlt <> nil)
		_oBrwFraPlt:aCols := aClone( _aColsFra )
		_oBrwFraPlt:Refresh(.T.)
	EndIf

Return(.T.)

// ** função para gerar novo volume
Static Function sfNovoVolume()

	// tela de confirmação
	If ( ! U_FtYesNoMsg("Confirma novo Volume ?","Novo Volume") )
		Return(.F.)
	EndIf

	// limpa os dados e seta o focus
	_cCodBar    := Space(13)
	_cEtqAntiga := Space(TamSx3("Z11_CODETI")[1])
	_cEtqNova   := Space(TamSx3("Z11_CODETI")[1])
	_oGetNova:SetFocus()

Return(.T.)

// ** funcao para estorno do palete
Static Function sfEstorno(mvPlt, mvVol, mvEan)
	// query
	local _cQryZ16 := ""
	// variaveis temporarias
	local _aTmpRecno := {}
	local _nX
	// variavel de retorno
	local _lRet := .T.
	// opção escolhida
	local _cOpcEst := ""

	// valida id do palete
	If (Empty(mvPlt))
		// mensagem
		U_FtWmsMsg("Não há palete para estorno!","ATENCAO")
		// retorno
		Return(_lRet)
	EndIf

	// chama a tela de opções para estorno
	_cOpcEst := sfRetOpcEst(mvPlt, mvVol, mvEan)

	// caso tenha cancelado o estorno
	If (Empty(_cOpcEst))
		// retorno
		Return(_lRet)
	EndIf

	// inicio de transacao
	BEGIN TRANSACTION

		// monta SQL para estornar a composicao o palete
		If (_lRet)
			_cQryZ16 := "SELECT Z16.R_E_C_N_O_ Z16RECNO "
			// composicao do palete
			_cQryZ16 += "FROM " + RetSqlName("Z16") + " Z16 "
			// filtro padrao
			_cQryZ16 += "WHERE " + RetSqlCond("Z16") + " "
			// numero id do palete
			_cQryZ16 += "AND Z16_ETQPAL = '" + mvPlt + "' "
			// onde o saldo é maior que zero
			_cQryZ16 += "AND Z16_SALDO > 0 "

			// validação do estorno do volume
			If (_cOpcEst == "VOL" ) .Or. (_cOpcEst == "LIN" )
				_cQryZ16 += "AND (Z16_ETQVOL = '" + mvVol + "' OR Z16_VOLORI = '"+mvVol+"') "
			EndIf

			// validação do estorno do produto
			If (_cOpcEst == "LIN" )
				_cQryZ16 += "AND Z16_CODBAR = '" + CVALTOCHAR(mvEan) + "' "
			EndIf

			// alimenta o vetor
			_aTmpRecno := U_SqlToVet(_cQryZ16)

			// varre todos os recno
			For _nX := 1 to Len(_aTmpRecno)
				// posiciona no registro real
				dbSelectArea("Z16")
				Z16->(dbGoTo( _aTmpRecno[_nX] ))

				// exclui o registro
				RecLock("Z16")
				Z16->(dbDelete())
				Z16->(MsUnLock())
			Next _nX
		EndIf

		// fim de transacao
	END TRANSACTION

	// mensagem para o usuário
	If (_lRet)
		U_FtWmsMsg("Estorno realizado com sucesso!","ATENCAO")
	Else
		U_FtWmsMsg("Estorno não permitido!","ATENCAO")
	EndIf

Return(_lRet)

// ** rotina com opções para estorno
Static Function sfRetOpcEst (mvPlt, mvVol, mvEan)

	// objetos
	local _oWmsOpcEst, _oPnlOpcCab, _oPnlOpcMei, _oBmpConvSair, _oBmpPlt, _oBmpVol, _oBmpLinha
	// retorno
	local _cRetOpc := ""
	// controle de transação
	local _lRet := .F.
	// array do retorno de totais
	local _aTotais := sfRetTotalPorTipo(mvPlt, mvVol, mvEan)

	// monta o dialogo do monitor
	_oWmsOpcEst := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Opções de Estorno",,,.F.,,,,,,.T.,,,.T. )
	_oWmsOpcEst:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlOpcCab := TPanel():New(000,000,nil,_oWmsOpcEst,,.F.,.F.,,CLR_WHITE,20,20,.T.,.F.)
	_oPnlOpcCab:Align:= CONTROL_ALIGN_TOP

	// -- botao Sair
	_oBmpConvSair := TBtnBmp2():New(000,000,040,040,"FINAL",,,,{|| If(U_FtYesNoMsg("Cancelar Estorno?","ATENÇÃO"),_oWmsOpcEst:End(),Nil) },_oPnlOpcCab,"Sair",,.T. )
	_oBmpConvSair:Align := CONTROL_ALIGN_RIGHT

	// cria o panel do rodape
	_oPnlOpcMei := TPanel():New(000,000,nil,_oWmsOpcEst,,.F.,.F.,,CLR_WHITE,,,.T.,.F.)
	_oPnlOpcMei:Align:= CONTROL_ALIGN_ALLCLIENT

	// -- botao Pallet
	_oBmpPlt := TButton():New( 002, 010, "Estorna Pallet? "+CRLF+_aTotais[1],_oPnlOpcMei,{|| _cRetOpc := "PLT",_oWmsOpcEst:End()  }, 100,30,,,.F.,.T.,.F.,,.F.,,,.F. )
	_oBmpPlt:Align := CONTROL_ALIGN_CENTER
	// O CSS abaixo remove a cor degrade do fundo
	_oBmpPlt:SetCss(sfPadrCSS())

	// -- botao Volume
	_oBmpVol := TButton():New( 040, 010, "Estorna Volume? "+CRLF+_aTotais[2],_oPnlOpcMei,{|| _cRetOpc := "VOL",_oWmsOpcEst:End() },100,30,,,.F.,.T.,.F.,,.F.,,,.F. )
	_oBmpVol:Align := CONTROL_ALIGN_CENTER
	// O CSS abaixo remove a cor degrade do fundo
	_oBmpVol:SetCss(sfPadrCSS())

	// -- botao Linha
	_oBmpLinha := TButton():New( 078, 010, "Estorna Linha Selecionada? "+CRLF+_aTotais[3],_oPnlOpcMei,{|| _cRetOpc := "LIN",_oWmsOpcEst:End()  }, 100,30,,,.F.,.T.,.F.,,.F.,,,.F. )
	_oBmpLinha:Align := CONTROL_ALIGN_CENTER
	// O CSS abaixo remove a cor degrade do fundo
	_oBmpLinha:SetCss(sfPadrCSS())

	// ativa a tela
	_oWmsOpcEst:Activate(,,,.F.,{|| .T. },,)

Return (_cRetOpc)

// ** retorna quantidade de registros por tipo
Static Function sfRetTotalPorTipo(mvPlt, mvVol, mvEan)

	// variavel de retorno
	local _aTotal := {}
	// query pra consulta
	local _cQuery := ""

	// consulto os dados pra trazer o retorno
	_cQuery := " SELECT CAST(COUNT(*) AS VARCHAR)+' REGISTRO(S)' FROM "+RetSqlName("Z16")+" Z16 (nolock)  "
	_cQuery += "	WHERE "+RetSqlCond("Z16")
	_cQuery += "	AND Z16_ETQPAL = '"+mvPlt+"' "
	_cQuery += "	AND Z16_SALDO > 0 "
	_cQuery += "	UNION ALL "
	_cQuery += "	SELECT CAST(COUNT(*) AS VARCHAR)+' REGISTRO(S)' FROM "+RetSqlName("Z16")+" Z16 (nolock)  "
	_cQuery += "	WHERE "+RetSqlCond("Z16") "
	_cQuery += "	AND Z16_ETQPAL = '"+mvPlt+"' "
	_cQuery += "	AND Z16_SALDO > 0 "
	// etiquetas de volume que também podem ser da origem
	_cQuery += "	AND (Z16_ETQVOL = '"+mvVol+"' OR Z16_VOLORI = '"+mvVol+"') "
	_cQuery += "	UNION ALL "
	_cQuery += "	SELECT CAST(COUNT(*) AS VARCHAR)+' REGISTRO(S)' FROM "+RetSqlName("Z16")+" Z16 (nolock)  "
	_cQuery += "	WHERE "+RetSqlCond("Z16")
	_cQuery += "	AND Z16_ETQPAL = '"+mvPlt+"' "
	_cQuery += "	AND Z16_SALDO > 0 "
	// etiquetas de volume que também podem ser da origem
	_cQuery += "	AND (Z16_ETQVOL = '"+mvVol+"' OR Z16_VOLORI = '"+mvVol+"') "
	_cQuery += "	AND Z16_CODBAR = '"+mvEan+"' "

	// total dos registros
	_aTotal := U_SqlToVet(_cQuery)

Return (_aTotal)

// ** funcao que define o CSS padrao para botoes
Static Function sfPadrCSS()

	// varivel de retorno
	local _cRet := ""

	// define o CSS
	_cRet := "QPushButton{ background-repeat: none; margin: 2px;"+;
	" background-position: center top; "+;
	" background-color: #CCCCCC; "+;
	" text-align: justify; }"

Return(_cRet)

// ** funcao que apresenta os detalhes da conferencia
Static Function sfDetFra()

	// obejtos da tela
	local _oWndFraDet
	local _oBmpEstorno, _oBmpConsDetSair, _oBrwFraDet
	local _oBrwFraDet
	local _oPnlFraDet, _oPnlFraRod

	// variaveis do browse
	local _aHeadDet := {}
	local _aColsDet := {}
	local _cQuery

	// monta a query
	_cQuery := " SELECT 'OK' Z16_STATUS, Z16_ETQPAL, Z16_ETQVOL, Z16_VOLORI, Z16_CODBAR, Sum(Z16_SALDO) Z16_SALDO, B1_COD, B1_DESC, '.F.' IT_DEL "
	_cQuery += " FROM " + RetSqlTab("Z16")
	_cQuery += "      INNER JOIN "+RetSqlTab("SB1")+" (nolock)  ON "+RetSqlCond("SB1")
	_cQuery += "            AND B1_COD = Z16_CODPRO "
	_cQuery += " WHERE "+RetSqlCond("Z16")
	_cQuery += "   AND Z16_ETQPAL = '"+_cPltAutFra+"' "
	_cQuery += "   AND Z16_ORIGEM = 'FRA' " // somente os que tem origem de fracionamento
	_cQuery += " GROUP  BY Z16_STATUS, Z16_ETQPAL, Z16_ETQVOL, Z16_VOLORI, Z16_CODBAR, B1_COD, B1_DESC  "
	_cQuery += " ORDER  BY Z16_ETQVOL "

	memowrit("c:\query\twmsa011_sfDetFra.txt",_cQuery)

	// atualiza o vetor do browse
	_aColsDet := U_SqlToVet(_cQuery)

	// define o header
	aAdd(_aHeadDet,{"Sts"        ,"Z16_STATUS"  ,Nil                          ,2                      ,0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Id Palete"  ,"Z16_ETQPAL"  ,PesqPict("Z16","Z16_ETQPAL") ,TamSx3("Z16_ETQPAL")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Id Volume"  ,"Z16_ETQVOL"  ,PesqPict("Z16","Z16_ETQVOL") ,TamSx3("Z16_ETQVOL")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Vol Origem" ,"Z16_VOLORI"  ,PesqPict("Z16","Z16_VOLORI") ,TamSx3("Z16_VOLORI")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Etq Produto","Z16_CODBAR"  ,PesqPict("Z16","Z16_CODBAR") ,TamSx3("Z16_CODBAR")[1],0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Quant"      ,"Z16_SALDO"   ,PesqPict("Z16","Z16_SALDO")  ,TamSx3("Z16_SALDO")[1] ,TamSx3("Z16_SALDO")[2],Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Produto"    ,"B1_COD"      ,PesqPict("SB1","B1_COD")     ,TamSx3("B1_COD")[1]    ,0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Desc Prod"  ,"B1_DESC"     ,PesqPict("SB1","B1_DESC")    ,TamSx3("B1_DESC")[1]   ,0                     ,Nil,Nil,"C",Nil,"R",,,".F." })

	// monta o dialogo do monitor
	_oWndFraDet := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Detalhes",,,.F.,,,,,,.T.,,,.T. )
	_oWndFraDet:lEscClose := .F.

	// cria o panel do cabecalho - botoes
	_oPnlFraDet := TPanel():New(000,000,nil,_oWndFraDet,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlFraDet:Align:= CONTROL_ALIGN_TOP

	// -- BOTAO DE ESTORNO
	_oBmpEstorno := TBtnBmp2():New(000,000,030,022,"ESTOMOVI",,,,{|| If( sfEstorno(_oBrwFraDet:aCols[_oBrwFraDet:nAt][2], _oBrwFraDet:aCols[_oBrwFraDet:nAt][3], _oBrwFraDet:aCols[_oBrwFraDet:nAt][4]), _oWndFraDet:End(), Nil),sfSelDadosFra() },_oPnlFraDet,"Estornar conferência",,.T.)
	_oBmpEstorno:Align := CONTROL_ALIGN_LEFT

	// -- CONFIRMACAO
	_oBmpConsDetSair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _oWndFraDet:End() },_oPnlFraDet,"Sair",,.T.)
	_oBmpConsDetSair:Align := CONTROL_ALIGN_RIGHT

	// cria o panel do rodape - botoes
	_oPnlFraRod := TPanel():New(000,000,nil,_oWndFraDet,,.F.,.F.,,,020,020,.T.,.F. )
	_oPnlFraRod:Align:= CONTROL_ALIGN_BOTTOM

	// monta o browse com os motivos de interrupcoes
	_oBrwFraDet := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDet),'AllwaysTrue()','','AllwaysTrue()',_oWndFraDet,_aHeadDet,_aColsDet)
	_oBrwFraDet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa o dialogo
	_oWndFraDet:Activate(,,,.F.,,,)

Return(.T.)

// ** função que valida o fracionamento
Static Function sfFinalFra(mvFixaWnd, mvCodPro)

	// variaveis temporarias para controle de endereco de origem e destino de paletes fracionados
	local _cTmpEndOri := CriaVar("BE_LOCALIZ",.F.)
	local _cTmpEndDes := CriaVar("BE_LOCALIZ",.F.)
	// querys para consulta
	local _cQryZ08 := ""
	local _cQryZ16 := ""
	// resultado das querys
	local _nQtdZ08 := 0
	local _nSalZ16 := 0
	// controle do for
	local _nX := 0
	// arrays de recno para atualização
	local _aRecZ16 := {}
	// arrays da Z08
	local _aRecZ08 := {}

	// valida se os campos estão em limpos pra poder prosseguir
	If ( ! Empty(_cEtqNova) ) .Or. ( ! Empty(_cEtqAntiga) ) .Or. ( ! Empty(_cCodBar) )
		U_FtWmsMsg("Existe fracionamento em aberto. Favor verificar antes de prosseguir.")
		Return(.F.)
	EndIf

	// valida se deseja finalizar
	If ( ! U_FtYesNoMsg("Deseja finalizar a desmontagem do pallet?") )
		Return(.F.)
	EndIf

	BEGIN TRANSACTION

		// ** VALIDAÇÃO QUANTIDADE NA Z08 ** //

		// valido se atingiu a quantidade solicitada
		_cQryZ08 := " SELECT SUM(Z08_QUANT) Z08_QUANT "
		_cQryZ08 += " FROM " + RetSqlTab("Z08")
		_cQryZ08 += " WHERE " + RetSqlCond("Z08")
		_cQryZ08 += " AND Z08_NUMOS  = '" + _cNumOrdSrv + "'"
		_cQryZ08 += " AND Z08_PALLET = '" + _cIdPalete  + "'"

		// somente se o código de produto tiver sido preenchido
		IIF ( ! Empty(mvCodPro), _cQryZ08 += " AND Z08_PRODUT = '" + mvCodPro + "' ", "")

		memowrit("C:\query\TWMSA011_sfFinalFra.txt",_cQryZ08)

		// quantidade na Z08
		_nQtdZ08 := U_FtQuery(_cQryZ08)

		// se não existir o pallet consultado
		If (_nQtdZ08 == 0)
			DisarmTransaction()
			// variável de retorno
			U_FtWmsMsg("Não foi possível consultar o saldo do palete (Z08). Informe seu supervisor.","ATENCAO")
			Return(.F.)
		EndIf

		// ** VALIDAÇÃO QUANTIDADE NA Z16 ** //

		// query que busca o saldo na Z16 para comparação
		_cQryZ16 := " SELECT ISNULL(SUM(Z16_SALDO),0) Z16_SALDO FROM "+RetSqlTab("Z16")
		_cQryZ16 += " WHERE "+RetSqlCond("Z16")
		_cQryZ16 += " AND Z16_ETQPAL = '"+_cPltAutFra+"' "
		_cQryZ16 += " AND Z16_PLTORI = '"+ _cIdPalete+ "' "
		_cQryZ16 += " AND Z16_ORIGEM = 'FRA' " // obrigatório usar FRA pra diferencial do SLD que é o saldo da posição

		memowrit("C:\query\TWMSA011_sfFinalFra_z16_final.txt",_cQryZ16)

		// jogo o conteúdo da query para uma variável
		_nSalZ16 := U_FtQuery(_cQryZ16)

		// caso não possua saldo, eu aviso o usuário
		If (_nSalZ16 == 0)
			DisarmTransaction()
			U_FtWmsMsg("Ainda não há saldo fracionado. Realize a leitura de todas as etiquetas antes de finalizar o fracionamento.","ATENCAO")
			Return(.F.)
		EndIf

		// comparo com a quantidade da OS
		If (_nQtdZ08 <> _nSalZ16)
			DisarmTransaction()
			U_FtWmsMsg("A quantidade solicitada é diferente da quantidade separada. Favor validar!","ATENCAO")
			Return(.F.)
		EndIf

		// ** ATUALIZAÇÃO DE SALDO NA Z16 ANTIGA ** //

		// query pra pegar os dados do volume de origem pra poder diminuir o saldo
		_cQryZ16 := " SELECT SUM(Z16_SALDO) Z16_SALDO, "
		_cQryZ16 += "        Z16_VOLORI "
		_cQryZ16 += " FROM   " + RetSqlTab("Z16")
		_cQryZ16 += " WHERE  " + RetSqlCond("Z16")
		_cQryZ16 += "        AND Z16_ETQPAL = '"+_cPltAutFra+"' "
		_cQryZ16 += "        AND Z16_PLTORI = '" + _cIdPalete + "' "
		_cQryZ16 += "        AND Z16_VOLORI <> '' "
		_cQryZ16 += "        AND Z16_ORIGEM = 'FRA' "
		_cQryZ16 += "        AND Z16_SALDO > 0 "
		// agrupa dados
		_cQryZ16 += " GROUP  BY Z16_VOLORI "

		// esse array é o cara dos saldos, ele é quem manda
		_aRecZ16 := U_SqlToVet(_cQryZ16)

		memowrit("C:\query\TWMSA011_select_z16_1.txt",_cQryZ16)

		// atualiza os dados já lidos e baixa o saldo do pallet antigo
		For _nX := 1 to Len(_aRecZ16)
			_cQryZ16 := " UPDATE " + RetSqlName("Z16") + " SET Z16_SALDO -= " + CVALTOCHAR(_aRecZ16[_nX][1]) + " "
			_cQryZ16 += " WHERE Z16_FILIAL = '" + xFilial("Z16") + "' "
			_cQryZ16 += " AND D_E_L_E_T_ = ' ' "
			_cQryZ16 += " AND Z16_ETQVOL = '" + _aRecZ16[_nX][2] + "' "
			_cQryZ16 += " AND Z16_ETQPAL = '" + _cIdPalete + "' "
			_cQryZ16 += " AND Z16_SALDO  > 0 "
			// se tiver o produto o filtro é sempre por ele
			IIF( ! Empty(mvCodPro), _cQryZ16 += " AND Z16_CODPRO = '" + mvCodPro + "' ", Nil)

			// executa o update
			// caso tenha dado algum erro, avisa o usuário e não deixa prosseguir
			If (TcSQLExec(_cQryZ16) < 0)
				DisarmTransaction()
				U_FtWmsMsg("Erro ao realizar a atualização de saldo no pallet antigo. Informe o setor de TI!","ATENCAO")
				Return(.F.)
			EndIf
		Next _nX

		// se for os interna e tiver saldo no array, vai fazer a atualização do saldo
		If (_lOSInt) .And. (Len(_aSldPrd) > 0)

			/* Composição do array _aSldPrd
			1 - Produto
			2 - Pallet
			3 - Saldo
			4 - Etq.Antiga
			5 - Etq.Nova
			*/

			// varro todo o array pra fazer as deduções de saldo
			For _nX := 1 to Len(_aSldPrd)
				// update nos dados antigos pra dedução de saldo
				_cQryZ16 := " UPDATE " + RetSqlName("Z16") + " SET Z16_SALDO -= " + CVALTOCHAR(_aSldPrd[_nX][3]) + " "
				_cQryZ16 += " WHERE Z16_FILIAL = '" + xFilial("Z16") + "'
				_cQryZ16 += " AND D_E_L_E_T_ = '' "
				_cQryZ16 += " AND Z16_ETQVOL = '" + _aSldPrd[_nX][4] + "' "
				_cQryZ16 += " AND Z16_ETQPAL = '" + _cIdPalete + "' "
				_cQryZ16 += " AND Z16_SALDO > 0 "
				_cQryZ16 += " AND Z16_CODPRO = '" + _aSldPrd[_nX][1] + "' "

				// executa o update
				// caso tenha dado algum erro, avisa o usuário e não deixa prosseguir
				If (TcSQLExec(_cQryZ16) < 0)
					DisarmTransaction()
					U_FtWmsMsg("Erro ao realizar a atualização de saldo no pallet de saldo. Informe o setor de TI!","ATENCAO")
					Return(.F.)
				EndIf
			Next _nX

			// limpo o array
			_aSldPrd := {}
		EndIf

		// ** ATUALIZAÇÃO DE PALLET NA Z16 ** //

		// id novo palete - rotina genérica que cria o novo ID
		_cIdNewPalete := U_FtGrvEtq("03",{_cUnitPdr,""})
		// define o codigo do unitizador
		_cCodUnit := Z11->Z11_UNITIZ

		// atualizo os dados do pallet conferido gravando número dele
		_cQryZ16 := " UPDATE " + RetSqlName("Z16") + " "
		// isso vai funcionar para os casos onde for selecionado um novo volume para o saldo, no caso de usar a caixa antiga no fracionamento
		_cQryZ16 += " SET Z16_ETQPAL = (CASE WHEN Z16_ORIGEM = 'FRA' THEN '" + _cIdNewPalete + "' ELSE '" + _cIdPalete + "' END), Z16_UNITIZ = '"+_cCodUnit+"' "
		_cQryZ16 += " WHERE Z16_FILIAL = '" + xFilial("Z16") + "'
		_cQryZ16 += " AND D_E_L_E_T_ = '' "
		_cQryZ16 += " AND Z16_PLTORI = '" + _cIdPalete + "' "
		// se tiver o produto o filtro é sempre por ele
		If( ! Empty(mvCodPro) )
			_cQryZ16 += "  AND ( Z16_CODPRO = '" + mvCodPro + "' OR EXISTS ("
			_cQryZ16 += " SELECT * FROM " + RetSqlName("Z16") + " Z16 "
			_cQryZ16 += " WHERE " + RetSqlCond("Z16")
			_cQryZ16 += " AND Z16_PLTORI = '" + _cIdPalete + "' "
			_cQryZ16 += " AND Z16_ETQPAL = '"+_cPltAutFra+"' "
			_cQryZ16 += " AND Z16_ORIGEM = 'SLD')) "
		EndIf
		// somente o pallet disponível
		_cQryZ16 += " AND Z16_ETQPAL = '"+_cPltAutFra+"' "

		memowrit("C:\query\TWMSA011_update_sffinalfra_1.txt",_cQryZ16)

		// caso tenha dado algum erro, avisa o usuário e não deixa prosseguir
		If (TcSQLExec(_cQryZ16) < 0)
			DisarmTransaction()
			U_FtWmsMsg("Erro ao realizar a atualização do novo pallet. Informe o setor de TI!","ATENCAO")
			Return(.F.)
		EndIf

		// ** ATUALIZAÇÃO DOS REGISTROS NA Z08 PARA NOVO PALLET ** //

		// atualizo a Z08
		_cQryZ08 := " SELECT R_E_C_N_O_ Z08RECNO "
		_cQryZ08 += " FROM " + RetSqlTab("Z08") + " (NOLOCK) "
		_cQryZ08 += " WHERE " + RetSqlCond("Z08")
		// se tiver o produto o filtro é sempre por ele+OS
		If ( ! Empty(mvCodPro) )
			_cQryZ08 += " AND Z08_PRODUT = '" + mvCodPro + "' "
		EndIf
		_cQryZ08 += " AND Z08_PALLET = '" + _cIdPalete + "' "
		_cQryZ08 += " AND Z08_NEWPLT = '' "
		_cQryZ08 += " AND Z08_NUMOS  = '" + _cNumOrdSrv + "' "
		_cQryZ08 += " AND Z08_USUARI = '" + _cCodOper + "' "

		// gravo os registros no vetor
		_aRecZ08 := U_SqlToVet(_cQryZ08)

		memowrit("C:\query\TWMSA011_select_z08_recno_1.txt",_cQryZ08)

		// caso não tenha encontrado os registros vai informar ao usuário
		If (Len(_aRecZ08) < 1)
			// avisa aos heróis do TI temos problemas
			U_FtMail(_cQryZ08,"Bug finalfra", "ti@tecadi.com.br", /* Anexos */, "celularesop@tecadi.com.br" , "qeru26eyuyeC" , "celularesop@tecadi.com.br")
			DisarmTransaction()

			U_FtWmsMsg("Não foi encontrado registro do pallet para atualização. Avise o setor de TI: RECNO: " + cValToChar(_aRecZ08[1]) )
			Return(.F.)
		EndIf

		// select na Z08
		dbSelectArea("Z08")
		For _nX := 1 to Len(_aRecZ08)
			// atualiza os dados na Z08
			Z08->( dbGoTo( _aRecZ08[_nX] ) )
			RecLock("Z08")
			Z08->Z08_NEWPLT := _cIdNewPalete
			Z08->Z08_STATUS := "P"
			Z08->Z08_FRAPLT := "S"
			Z08->(MsUnLock())
		Next _nX

		// grava registro de movimento do novo pallet na Z17
		dbSelectArea("Z17")
		RecLock("Z17",.T.)
		Z17->Z17_FILIAL := xFilial("Z17")
		Z17->Z17_ETQPLT := _cIdNewPalete
		Z17->Z17_ENDORI := Z08->Z08_ENDSRV
		Z17->Z17_ENDDES := Z08->Z08_ENDDES
		Z17->Z17_DTINI  := Date()
		Z17->Z17_HRINI  := Time()
		Z17->Z17_OPERAD := _cCodOper
		Z17->Z17_EQUIPA := _cCodEquip
		Z17->Z17_NUMOS  := Z08->Z08_NUMOS
		Z17->Z17_SEQOS  := Z08->Z08_SEQOS
		Z17->Z17_STATUS := "M"  // R=Realizado / C=Cancelado / M=Em Movimento
		Z17->Z17_TIPLAN := "NM" // NM=Normal / ES=Estorno / AJ=Ajuste / DV=Devolução / FR=Fracionamento / DF=Dev. Fracion.
		Z17->Z17_ORILAN := "A"  // A=Automática / M=Manual
		Z17->Z17_LOCORI := Z08->Z08_LOCAL
		Z17->Z17_LOCDES := Z08->Z08_LOCDES
		Z17->(MsUnLock())

	END TRANSACTION

	// se finalizou corretamente, alerta o usuário
	If ( ! Empty(mvCodPro))
		U_FtWmsMsg("Fracionamento do produto: " + mvCodPro + " foi finalizado com sucesso.","SUCESSO")
	Else
		U_FtWmsMsg("Fracionamento finalizado com sucesso.","SUCESSO")
	EndIf

	// libera a tela pra ser fechada
	mvFixaWnd := .T.
	_lUnit := .F. // reinicia a variável private de controle da tela

Return( .T. )

// ** função que valida e chama rotina de fracionamento - fiz isso pra economizar código
Static Function sfFraPlt(mvOper, mvPrdQtd)
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SB1"})

	// receberá os pallet a fracionar
	local _aPrdFra := {}
	// variavel de controle
	local _lRet := .T.
	// tempo total da movimentacao
	local _nTempoTot  := 0
	local _nRecnoDF  := 0
	// se habilitou sair
	local _lSair      := .F.
	Local _nX

	// unidades de medida
	local _nQuant   := 0
	local _cUnMed   := ""
	local _nQtSegum := 0
	local _cSegUM   := ""

	// inicia as validações
	If (_lRet)

		// array recebido via parâmetro que contem as necessidades
		_aPrdFra := mvPrdQtd

		// varre todos os registros para reservar a movimentacao
		For _nX := 1 to Len(_aPrdFra)

			// atualizo o status do mapa
			dbSelectArea("Z08")
			Z08->(DbGoTo(_aPrdFra[_nX][4]))
			RecLock("Z08")
			Z08->Z08_STATUS := "M" // P-Planejado / R-Realizado / M-Movimento / E-Erro
			Z08->(MsUnLock())

		Next _nX

		// varro todos os registros para que o fraciomanento ocorra apenas uma vez
		For _nX := 1 to Len(_aPrdFra)

			// se for kit ou single (unitário), eu fraciono por volume
			If (mvOper == "KIT") .Or. (mvOper == "SINGLE")

				// posiciona no cadastro do produto
				dbSelectArea("SB1")
				SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
				SB1->(dbSeek( xFilial("SB1")+_aPrdFra[_nX][1] ))

				// define quantidade
				_nQuant   := _aPrdFra[_nX][2]
				_cUnMed   := SB1->B1_UM
				_nQtSegum := _aPrdFra[_nX][3]
				_cSegUM   := SB1->B1_SEGUM

				// só mostra quando for SINGLE
				If (mvOper == "SINGLE")
					U_FtWmsMsg("Pegue: " + CRLF + CRLF +;
					CVALTOCHAR(_nQuant) + " " + IIF(mvOper = "KIT", "volume(s)!", _cUnMed) + ;
					IIF(_nQtSegum != 0, CRLF + " OU " + CRLF + CVALTOCHAR(_nQtSegum) + " " + IIF(mvOper = "KIT", "volume(s)!", _cSegUM), ""), Nil, Nil, Nil, 3)
				EndIf

				// chamo a rotina de fracionamento sem parametro de produto mas com a operação
				If ( ! sfDesmontaVol("", mvOper, @_lSair) )
					U_FtWmsMsg("Não foi possível realizar o fracionamento. Verifique!")
					_lRet := .F.
				Else
					// exit e goto não devem ser usados, mas, né, POG é POG
					Exit
				EndIf

				// aqui está o complicado
				// precisa validar quais produtos serão fracionados e então mostrar pro usuário
			ElseIf (mvOper == "PEÇAS")

				// valida fracionamento do saldo do pallet
				If (sfVldFraSld())
					Exit
				EndIf

				// a variável _cProdFra é a que recebe o produto a ser fracionado.
				// ela é uma private e é utilizada em diversos lugares a partir do momento que é preenchida
				// então deve-se ter cuidado ao manipulá-la.

				// tela de produtos disponíveis
				If ( ! sfTRetProd() )
					// mensagem
					U_FtWmsMsg("Não foi possível escolher o produto para fracionamento!")
					// restaura areas iniciais
					RestOrd(_aAreaIni,.T.)
					RestArea(_aArea)
					// retorno
					Return(.F.)
				Else
					// caso não tenha o produto para fracionar
					If ( Empty(_cProdFra) )
						// mensagem
						U_FtWmsMsg("Nenhum produto para fracionar!")
						// restaura areas iniciais
						RestOrd(_aAreaIni,.T.)
						RestArea(_aArea)
						// retorno
						Return(.F.)
					Else
						// busco pela Z08 para posicionar no registro escolhido
						dbSelectArea("Z08")
						Z08->( dbSetOrder(3) ) //filial+numos+pallet+produto
						If ( ! dbSeek( xFilial("Z08") + _cNumOrdSrv + _cIdPalete + _cProdFra) )
							// menagem
							U_FtWmsMsg("Não foi possível posicionar o registro. Informe a TI!")
							// restaura areas iniciais
							RestOrd(_aAreaIni,.T.)
							RestArea(_aArea)
							// retorno
							Return(.F.)
						EndIf
					EndIf
				EndIf

				// rotina de fracionamento com o produto escolhido e operação
				If ( ! sfDesmontaVol(_cProdFra, mvOper, @_lSair) )
					// mensagem
					U_FtWmsMsg("Não foi possível realizar o fracionamento. Verifique!")
					// variavel de controle
					_lRet := .F.
				EndIf

			EndIf

		Next _nX

		// caso escolheu sair, retorna falso para nao gravar nada
		If (_lSair)
			// controle de continuidade de processamento
			_lRet := .F.
		EndIf

	EndIf

	// zero a variável
	_cProdFra := ""

	// valida se ainda há saldo no pallet e não há OS para ele e então armazena o pallet na posição original
	If (sfVldArmSld()) .And. ( ! _lSair)

		// alerta para o usuário caso precise armazenar o pallet no endereço de origem
		U_FtWmsMsg("Armazene o palete novamente em sua posição original.","Atenção")

		// atualizo variaveis
		_cEndOrige  := Z08->Z08_ENDSRV
		_cEndDesti  := Z08->Z08_ENDORI
		_cEndPicDro := Z08->Z08_ENDTRA
		_cIdPalete  := Z08->Z08_PALLET

		// Gera registro de movimentacao de devolução do palete original
		dbSelectArea("Z17")
		RecLock("Z17",.T.)
		Z17->Z17_FILIAL := xFilial("Z17")
		Z17->Z17_ETQPLT := Z08->Z08_PALLET
		Z17->Z17_ENDORI := _cEndOrige
		Z17->Z17_ENDDES := _cEndDesti
		Z17->Z17_DTINI  := Date()
		Z17->Z17_HRINI  := Time()
		Z17->Z17_OPERAD := _cCodOper
		Z17->Z17_EQUIPA := _cCodEquip
		Z17->Z17_NUMOS  := Z08->Z08_NUMOS
		Z17->Z17_SEQOS  := Z08->Z08_SEQOS
		Z17->Z17_STATUS := "M"  // R=Realizado / C=Cancelado / M=Em Movimento
		Z17->Z17_TIPLAN := "DF" // NM=Normal / ES=Estorno / AJ=Ajuste / DV=Devolução / FR=Fracionamento / DF=Dev. Fracion.
		Z17->Z17_ORILAN := "A"  // A=Automática / M=Manual
		Z17->Z17_LOCORI := Z08->Z08_LOCAL
		Z17->Z17_LOCDES := Z08->Z08_LOCDES
		Z17->(MsUnLock())

		// pra impedir que posicione em outro registro
		_nRecnoDF := Z17->( Recno() )

		// tela para confirmar o endereço solicitado
		While ! sfConfDest( .F. , .F. )
			Loop
		EndDo

		// retornar o endereco do palete que foi fracionado
		U_FtEndPlt(_cIdPalete, _cEndOrige, _cEndDesti, _cArmzAtual) // endereços invertidos para devolução do pallet - vide Z16

		// funcao para enderecamento final
		If ( ! sfGrvEndDest(_cTipoOper, .T., .T.) )
			U_FtWmsMsg("Erro ao realizar o Endereçamento. Favor repetir a operação.","ATENCAO")
			_lRet := .F.
		Else
			// finaliza o registro na Z17
			dbSelectArea("Z17")
			Z17->( dbGoTo( _nRecnoDF ) )
			RecLock("Z17")
			// data e hora final
			Z17->Z17_DTFIM  := Date()
			Z17->Z17_HRFIM  := Time()
			Z17->Z17_STATUS := "R" // R=Realizado / C=Cancelado / M=Em Movimento

			// calcula o tempo da operacao (retorno em centesimal)
			_nTempoTot := A680Tempo(Z17->Z17_DTINI,;
			Left(Z17->Z17_HRINI,5),;
			Z17->Z17_DTFIM,;
			Left(Z17->Z17_HRFIM,5) )

			// define o tipo de movimento realizado baseado no registro já gerado da Z17
			Z17->Z17_TIPMOV := sfRetTpMov(Z17->Z17_ENDORI, Z17->Z17_ENDDES, Z17->Z17_LOCORI, Z17->Z17_LOCDES)

			// converte para horas normais
			_nTempoTot := fConvHr(_nTempoTot,"H")

			// tempo total
			Z17->Z17_TEMPO := _nTempoTot

			Z17->(MsUnLock())
		EndIf
	EndIf

	// atualizo variaveis do endereço de destino
	// fiz isso pq, se notar antes de movimentar, eu inverto os endereços
	_cEndDesti := Z08->Z08_ENDDES

	// restaura areas iniciais
	RestOrd(_aAreaIni,.T.)
	RestArea(_aArea)

Return (_lRet)

// ** função da tela de produtos a serem fracionados
Static Function sfTRetProd ()
	// variavel de controle
	local _lRet      := .F.
	// objetos locais
	local _oWmsProd, _oPnlPedCab, _oBmpOk, _oBmpSair, _oBrwProd
	// arrays do browse
	local _aHeadProd  := {}
	local _aColsProd  := {}
	local _aAux      := aClone(_aQryZ08)
	local _nX        := 0

	// monta o dialogo do monitor
	_oWmsProd := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Produtos para Fracionar",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes de operacao
	_oPnlPedCab := TPanel():New(000,000,nil,_oWmsProd,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlPedCab:Align:= CONTROL_ALIGN_TOP

	// botao que seleciona um pedido
	_oBmpOk := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| _cProdFra := _oBrwProd:aCols[_oBrwProd:nAt][1], _lRet:= .T., _oWmsProd:End() },_oPnlPedCab,"OK",,.T.)
	_oBmpOk:Align := CONTROL_ALIGN_LEFT

	// define array do browse
	aAdd(_aHeadProd,{"Cod.Pro"      ,"Z08_PRODUT"  ,"" ,TamSx3("Z08_PRODUT")[1] ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadProd,{"Descrição"    ,"B1_DESC"     ,"" ,TamSx3("B1_DESC")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadProd,{"Quantidade"   ,"Z08_QUANT"   ,"" ,TamSx3("Z08_QUANT")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })

	// define o acols de acordo com a query na Z08
	For _nX := 1 to Len(_aAux)
		// se o produto não tiver sido preenchido, mostra todos os produtos no browse de escolha
		If (Empty(_cProdFra))
			aAdd(_aColsProd, { _aAux[_nX][1], Posicione("SB1",1, xFilial("SB1")+_aAux[_nX][1] ,"B1_DESC"), _aAux[_nX][2], .F. } )
		Else
			//valida se já incluiu pra não incluir o que já foi fracionado
			If (_aAux[_nX][1] != _cProdFra)
				aAdd(_aColsProd, { _aAux[_nX][1], Posicione("SB1",1, xFilial("SB1")+_aAux[_nX][1] ,"B1_DESC"), _aAux[_nX][2], .F. } )
			EndIf
		EndIf
	Next _nX

	// caso não exista retorna um false para que mostre o erro ao usuário
	If (_aColsProd == Nil) .Or. (Len(_aColsProd) == 0)
		Return (.F.)
	EndIf

	// browse
	_oBrwProd := MsNewGetDados():New(078,000,148,118,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsProd),'AllwaysTrue()','','AllwaysTrue()',_oWmsProd,_aHeadProd,_aColsProd)
	_oBrwProd:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativacao da tela
	ACTIVATE MSDIALOG _oWmsProd
Return (_lRet)

// ** função que atualiza o endereço de destino, não deixando mais de um pallet no mesmo endereço ** //
Static Function sfAgrPltEnd(mvEndDes, mvPltNovo, mvUltMov)

	// query responsavel pelas pesquisas da função
	local _cQuery     := ""
	// variavel que receberá o pallet antigo para substituição
	local _cPltAntigo := ""
	// array de recnos da Z08
	local _aZ08Rec    := {}
	Local _nX

	// primeiro valida se o endereço de destino possui mais de um pallet
	_cQuery := " SELECT COUNT(DISTINCT Z16_ETQPAL) "
	_cQuery += "   FROM " + RetSqlTab("Z16") + " (NOLOCK) "
	_cQuery += "  WHERE " + RetSqlCond("Z16")
	_cQuery += "    AND Z16_ENDATU = '" + mvEndDes + "' "
	_cQuery += "    AND Z16_LOCAL  = '" + _cArmzDesti + "' "
	_cQuery += "    AND Z16_SALDO  > 0"
	_cQuery += " 	AND EXISTS (SELECT * FROM " + RetSqlTab("SBE") + " (NOLOCK) "
	_cQuery += "                WHERE " + RetSqlCond("SBE")
	_cQuery += "                AND BE_LOCAL  = Z16_LOCAL "
	_cQuery += " 	            AND BE_LOCALIZ = Z16_ENDATU "
	_cQuery += " 	            AND BE_ESTFIS IN ( '000002', '000010' ) ) "
	_cQuery += " GROUP BY Z16_ENDATU "

	memowrit("C:\query\TWMSA011_sfAgrPltEnd_1.txt", _cQuery)

	// caso o resultado seja maior que zero, vai pesquisar o pallet pra poder atualizar o registro
	If ( U_FtQuery(_cQuery) > 1 )

		// vou pesquisar o menor número de pallet da posição
		_cQuery := " SELECT MIN(Z16_ETQPAL) Z16_ETQPAL FROM " + RetSqlTab("Z16")
		_cQuery += " WHERE " + RetSqlCond("Z16")
		_cQuery += " AND Z16_ENDATU = '" + mvEndDes + "' "
		_cQuery += " AND Z16_LOCAL  = '" + _cArmzDesti + "' "
		_cQuery += " AND Z16_SALDO > 0 "

		memowrit("C:\query\TWMSA011_sfAgrPltEnd_palete_antigo.txt", _cQuery)

		// jogo o pallet para a variável para realizar a atualização
		_cPltAntigo := U_FtQuery(_cQuery)

		// faço o update dos registros na Z16
		_cQuery := " UPDATE " + RetSqlName("Z16")
		_cQuery += " SET Z16_ETQPAL = '" + _cPltAntigo + "', Z16_PLTORI = '" + mvPltNovo + "' "
		_cQuery += " WHERE Z16_FILIAL = '" + xFilial("Z16") + "' "
		_cQuery += " AND D_E_L_E_T_ = ' ' "
		_cQuery += " AND Z16_CODPRO = '" + Z08->Z08_PRODUT + "' "
		_cQuery += " AND Z16_LOCAL  = '" + _cArmzDesti + "' "
		_cQuery += " AND Z16_ENDATU = '" + mvEndDes + "' "
		_cQuery += " AND Z16_SALDO > 0 "

		memowrit("C:\query\TWMSA011_sfAgrPltEnd_update_z16.txt", _cQuery)

		// caso tenha dado algum erro, avisa o usuário e não deixa prosseguir
		If (TcSQLExec(_cQuery) < 0)
			U_FtWmsMsg("Erro ao realizar a atualização do novo pallet. Informe o setor de TI!","ATENCAO")
			Return(.F.)
		EndIf

		// agora vou atualizar o novo pallet na Z08
		// fiz isso pq só pode atualizar no último movimento
		If (mvUltMov)
			// atualizo a Z08
			_cQuery := " SELECT R_E_C_N_O_ RECNO FROM " + RetSqlTab("Z08") + " (nolock) "
			_cQuery += " WHERE " + RetSqlCond("Z08")
			_cQuery += " AND Z08_PALLET = '" + Z08->Z08_PALLET + "' "
			_cQuery += " AND Z08_NUMOS = '" + Z08->Z08_NUMOS + "' "

			// gravo os registros no vetor
			_aZ08Rec := U_SqlToVet(_cQuery)

			memowrit("C:\query\TWMSA011_sfAgrPltEnd_update_z08.txt", _cQuery)

			// caso não tenha encontrado os registros vai informar ao usuário
			If (Len(_aZ08Rec) <= 0)
				U_FtWmsMsg("Não foi encontrado registro do pallet para atualização do Z08_NEWPLT. Avise o setor de TI")
				Return(.F.)
			EndIf

			// seleciono a área apesar de já estar posicionado, para garantir o novo registro baseado no RECNO
			dbSelectArea("Z08")
			For _nX := 1 to Len(_aZ08Rec)
				// atualiza os dados na Z08
				Z08->( dbGoTo( _aZ08Rec[_nX] ) )
				RecLock("Z08")
				// atualiza o novo palete
				Z08->Z08_NEWPLT := _cPltAntigo
				Z08->(MsUnLock())
			Next _nX

		EndIf
	EndIf

Return(.T.)

// ** funcao para informar a quantidade manualmente (para produtos de pequeno porte)
Static Function sfInfVol(mvNewVol)
	// objetos
	local _oBtnFoco1, _oWndInfVol, _oPnlInfVolCab, _oSayVol, _oGetVol
	// controle para nao fechar a tela
	Local _lRetOk := .F.

	// reinicia segunda unidade de medida
	_nQtdSegUM := 0

	// monta a tela para informa a quantidade
	_oWndInfVol := MSDialog():New(020,020,120,200,"Informe o volume de destino",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlInfVolCab := TPanel():New(000,000,nil,_oWndInfVol,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlInfVolCab:Align:= CONTROL_ALIGN_TOP

	// titulo
	_oSayVol := TSay():New(025,005,{|| "Etq.Volume:" },_oWndInfVol,,_oFnt02,.F.,.F.,.F.,.T.)

	// botao para usar como foco (nao é usado pra nada)
	_oBtnFoco1 := TButton():New(033,030,"",_oWndInfVol,{|| Nil },010,010,,,,.T.,,"",,,,.F. )
	_oGetVol   := TGet():New( 033,030,{|u| If(PCount()>0,mvNewVol:=u,mvNewVol)},_oWndInfVol,60,010,PesqPict("Z11","Z11_CODETI"),{|| , IIF( sfVldVol(mvNewVol), {_lRetOk := .T., _oWndInfVol:END()}, Nil)  },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","mvNewVol",,)

	// seta o foco na mensagem
	_oGetVol:SetFocus()

	// ativacao da tela com validacao
	_oWndInfVol:Activate(,,,.T.,{|| _lRetOk })

Return

// ** validação de volume informado
Static Function sfVldVol(mvVol)

	// controle
	local _lRet := .T.
	// controle de volume
	local _nTotVol := 0

	// pesquisa se a etiqueta é valida
	If (_lRet)
		dbSelectArea("Z11")
		Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
		If ( Z11->(dbSeek( xFilial("Z11")+mvVol ) ) )
			If ( Z11->Z11_TIPO != "04")
				_lRet := .F.
			EndIf
		Else
			_lRet := .F.
		EndIf
	EndIf

	If (_lRet)
		// valido se aquele volume está naquele pallet
		_cQryZ16 := " SELECT COUNT(DISTINCT Z16_CODPRO) "
		_cQryZ16 += "  FROM " + RetSqlName("Z16") + " Z16 (nolock)  "
		_cQryZ16 += " WHERE Z16_ETQVOL = '" + mvVol + "' "
		_cQryZ16 += " AND "+RetSqlCond("Z16")

		// o valor todo na variavel
		_nTotVol := U_FtQuery(_cQryZ16)

		If (_nTotVol > 0)
			U_FtWmsMsg("Etiqueta já utilizada!. Verifique!")
			_lRet := .F.
			Return (_lRet)
		EndIf
	EndIf

	// informa o usuário
	If ( ! _lRet)
		U_FtWmsMsg("Etiqueta inválida!","ATENCAO")
	EndIf

Return (_lRet)

// ** função para validar a saída do fracionamento de volumes ** //
Static Function sfVldSair(mvOk, mvSair)

	// controle de laço
	local _nX := 0
	// controle de transação
	local _lRet := .T.

	// valida se o usuário quer mesmo sair ou clicou por engano
	_lRet := U_FtYesNoMsg("Deseja sair?","Atenção")

	// se o usuário deseja sair, vou validar as leituras já realizadas
	If (_lRet)
		aEval(_oBrwFraPlt:aCols, { |x| IIF( x[1] != 0, (_lRet := .F.), Nil) } )
	EndIf

	// habilita fechar a tela
	mvOk := _lRet

	// se não puder sair
	If ( ! mvOk)
		U_FtWmsMsg("Fracionamento já iniciado. Para sair, será necessário estornar o fracionamento já iniciado!")
	Else
		// confirma a saída
		mvSair := mvOk
	EndIf

Return (_lRet)

// ** função que retorna array que contem tipos de estoque
Static Function sfRetTpEmbala(mvCodCli)

	// query para consulta
	local _cQuery := ""
	// array pra retorno
	local _aTpEmbala := {}

	// consulto os tipos de estoque disponíveis na tabela
	_cQuery := " SELECT Z31_CODIGO +'-'+Z31_DESCRI TPEMBALA FROM "+RetSqlName("Z31")+" Z31  (nolock)  "
	_cQuery += " WHERE "+RetSqlCond("Z31")
	_cQuery += " AND Z31_SIGLA = (SELECT DISTINCT A1_SIGLA FROM "+RetSqlName("SA1")+" SA1 (nolock)  WHERE "+RetSqlCond("SA1")+" AND A1_COD = '"+mvCodCli+"') "

	// jogo os dados pro array
	_aTpEmbala := U_SqlToVet(_cQuery)

Return (_aTpEmbala)

// ** funcao que retorna o lote que compoe o palete
Static Function sfLotPalet(mvIdPalete)
	local _cRet := ""
	local _cQryZ16

	_cQryZ16 := "SELECT Z16_LOTCTL"
	// formacao do palete
	_cQryZ16 += " FROM "+RetSqlName("Z16")+" Z16 (nolock)  "
	// filtro padrao
	_cQryZ16 += " WHERE "+RetSqlCond("Z16")+" "
	// filtro do ID palete
	_cQryZ16 += " AND Z16_ETQPAL = '"+mvIdPalete+"' "

	// executa a query
	_cRet := U_FtQuery(_cQryZ16)

Return(_cRet)

// ** retorna tipo de endereço
Static Function sfRetTpEnd(mvEnd, mvArm)
	// variaveis de controle
	local _cQuery := ""
	local _cRet   := ""

	// query que trata o tipo de endereço com dados baseados na DC8
	_cQuery := " SELECT DC8_TPESTR "
	_cQuery += " FROM "+RetSqlTab("SBE")+" (nolock) "
	_cQuery += " INNER JOIN "+RetSqlTab("DC8")+" (nolock)  ON DC8_CODEST = BE_ESTFIS AND "+RetSqlCond("DC8")
	_cQuery += " WHERE "+RetSqlCond("SBE")
	_cQuery += " AND BE_LOCAL   = '"+mvArm+"' "
	_cQuery += " AND BE_LOCALIZ = '"+mvEnd+"' "

	// informação para debug
	memowrit("C:\query\TWMSA011_sfRetTpEnd.txt",_cQuery)

	// retorno direto da query
	_cRet := U_FtQuery(_cQuery)

Return(_cRet)

// ** função para retornar o tipo de movimento
Static Function sfRetTpMov (mvEndOri, mvEndDes, mvArmOri, mvArmDes)

	// variavel de retorno da função
	local _cRet := ""
	local _cTpOri := sfRetTpEnd(mvEndOri, mvArmOri)
	local _cTpDes := sfRetTpEnd(mvEndDes, mvArmDes)

	/* Retornos da função sfRetTpEnd
	1	PORTA PALETE A1
	1	ANALISE TECNICA
	2	PICKING
	4	MEZANINO A1
	4	NAO CONFORME
	4	TRANSF FILIAIS
	4	QUALIDADE
	4	BLOCADO A1 - CTBA
	5	DOCAS A1
	7	RUA/CORREDOR
	*/

	// Origem das DOCAS	/ STAGE
	If (_cTpOri == "5")

		// Destino BLOCOS / RUAS
		If (_cTpDes $ "4/7")
			_cRet := "MH"
		Else
			_cRet := "MV"
		EndIf
	EndIf

	// Origem BLOCO / RUA / STAGE
	If (_cTpOri $ "4/5/7")

		// Destino Porta Pallet
		If (_cTpDes $ "1/2")
			_cRet := "MV"
		Else
			_cRet := "MH"
		EndIf
	EndIf

	// Origem ENDEREÇO / PICKING
	If (_cTpOri $ "1/2")

		// Destino BLOCOS / RUAS / DOCAS / STAGE / PICKING / PORTAPALLET
		If (_cTpDes $ "4/5/7") .Or. (_cTpDes $ "1/2")
			_cRet := "MV"
		Else
			_cRet := "MH"
		EndIf

	EndIf

Return _cRet

// ** funcao que avisa usuario que tem coleta ativa
Static Function sfComColeta()
	// retorna dados da feita ativa
	local _aTmpColeta := sfARetFeira()
	// variavel de controle
	local _lRet := .T.

	// avisa usuario que tem coleta pentende
	If ( Len(_aTmpColeta) != 0 )
		// mensagem
		U_FtWmsMsg("Há coleta de mercadoria Pendente. Antes de Sair, confirme a movimentação no endereço de destino. Favor verificar!", "Atenção")
		// variavel de controle
		_lRet := .F.
	EndIf

Return(_lRet)

// ** funcao que retorna os dados do palete em movimento
Static Function sfRetPltMov(mvIdPalete)
	// variavel de retorno
	local _aTmpDados := {}
	// query
	local _cQuery

	// prepara query
	_cQuery := " SELECT Z16_SALDO, "
	_cQuery += "        CASE "
	_cQuery += "          WHEN Z16_ETQPRD != '' THEN Z16_ETQPRD "
	_cQuery += "          ELSE Z16_ETQVOL "
	_cQuery += "        END ETQ_IDENT, "
	_cQuery += "        B1_DESC, "
	_cQuery += "        B1_COD, "
	_cQuery += "        Z16_LOTCTL, "
	_cQuery += "        Z16_VLDLOT, "
	_cQuery += "        Z16_QTSEGU, "
	_cQuery += "        '.F.' IT_DEL "

	// composicao do palete
	_cQuery += " FROM   " + RetSqlTab("Z16")

	// cad. do produto
	_cQuery += "        INNER JOIN " + RetSqlTab("SB1") + " (nolock) "
	_cQuery += "                ON " + RetSqlCond("SB1")
	_cQuery += "                   AND B1_COD = Z16_CODPRO "

	// filtro padrao
	_cQuery += " WHERE  " + RetSqlCond("Z16")
	// endereco
	_cQuery += "        AND Z16_ETQPAL = '" + mvIdPalete + "' "
	// somente com saldo
	_cQuery += "        AND Z16_SALDO > 0 "

	memowrit("c:\query\twmsa011_sfRetPltMov.txt", _cQuery)

	// atualiza variavel de retorno
	_aTmpDados := U_SqlToVet(_cQuery, {"Z16_VLDLOT"})

Return(_aTmpDados)

// ** funcao que apresenta as etiquetas esperadas
Static Function sfEtqSelFra()
	// objetos locais
	local _oWndSelVlm
	local _oPnSelVlm
	local _oBmpSair
	local _oBrwSelVlm

	// variaveis do browse
	local _aHeadVlm := {}
	local _aColsVlm := sfRetSelVlm()

	// define campos do browse de kit montados
	aAdd(_aHeadVlm,{"Quant"       ,"Z16_SALDO" , PesqPict("Z16","Z16_SALDO") , TamSx3("Z16_SALDO")[1] , TamSx3("Z16_SALDO")[2] ,Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHeadVlm,{"Etiqueta"    ,"Z16_ETQPRD", PesqPict("Z16","Z16_ETQPRD"), TamSx3("Z16_ETQPRD")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadVlm,{"Descricao"   ,"B1_DESC"   , PesqPict("SB1","B1_DESC")   , TamSx3("B1_DESC")[1]   , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadVlm,{"Produto"     ,"B1_COD"    , PesqPict("SB1","B1_COD")    , TamSx3("B1_COD")[1]    , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadVlm,{"Lote"        ,"Z16_LOTCTL", PesqPict("Z16","Z16_LOTCTL"), TamSx3("Z16_LOTCTL")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadVlm,{"Dt Valid"    ,"Z16_VLDLOT", PesqPict("Z16","Z16_VLDLOT"), TamSx3("Z16_VLDLOT")[1], 0                      ,Nil,Nil,"D",Nil,"R",,,".F." })
	aAdd(_aHeadVlm,{"Quant Seg UM","Z16_QTSEGU", PesqPict("Z16","Z16_QTSEGU"), TamSx3("Z16_QTSEGU")[1], TamSx3("Z16_QTSEGU")[2],Nil,Nil,"N",Nil,"R",,,".F." })

	// apresenta tela para selecionar o palete do endereco informado
	_oWndSelVlm := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Apanhe de Palete",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes de operacao
	_oPnSelVlm := TPanel():New(000,000,nil,_oWndSelVlm,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnSelVlm:Align:= CONTROL_ALIGN_TOP

	// botao que sai
	_oBmpSair := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| _oWndSelVlm:End()}, _oPnSelVlm,"Sair",,.T.)
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// monta o browse com a lista de produtos no endereco
	_oBrwSelVlm := MsNewGetDados():New(000,000,400,400,,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsVlm),'AllwaysTrue()','','AllwaysTrue()', _oWndSelVlm, _aHeadVlm, _aColsVlm)
	_oBrwSelVlm:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	_oWndSelVlm:Activate(,,,.F.,{|| Nil },,)

Return

// ** funcao que retorna os paletes e etiquetas esperados
Static Function sfRetSelVlm()
	// variavel de retorno
	local _aTmpDados := {}
	// query
	local _cQuery

	// volumes (caixas) ja selecionados no pedido de venda
	local _lVolJaDef := U_FtWmsParam("WMS_EXPEDICAO_ESCOLHE_VOLUMES", "L", .F., .F., Nil, _cCodCliMov, _cLjCliMov, Nil, Nil)

	// permite conferencia/recebimento por volumes
	local _lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.F.,.F.,"", _cCodCliMov, _cLjCliMov, Nil, Nil)

	// prepara query
	_cQuery := " SELECT Z16_SALDO, "
	_cQuery += "        CASE "
	_cQuery += "          WHEN Z16_ETQPRD != '' THEN Z16_ETQPRD "
	_cQuery += "          ELSE Z16_ETQVOL "
	_cQuery += "        END ETQ_IDENT, "
	_cQuery += "        B1_DESC, "
	_cQuery += "        B1_COD, "
	_cQuery += "        Z16_LOTCTL, "
	_cQuery += "        Z16_VLDLOT, "
	_cQuery += "        Z16_QTSEGU, "
	_cQuery += "        '.F.' IT_DEL "

	// composicao do palete
	_cQuery += " FROM   "+RetSqlTab("Z16")

	// cad. do produto
	_cQuery += "        INNER JOIN "+RetSqlTab("SB1")+" (nolock) "
	_cQuery += "                ON "+RetSqlCond("SB1")
	_cQuery += "                   AND B1_COD = Z16_CODPRO "

	// caixas reservadas
	If (_lVolJaDef) .And. (_lCtrVolume)

		_cQuery += "        INNER JOIN " + RetSqlTab("Z05") + " (nolock) "
		_cQuery += "                ON " + RetSqlCond("Z05")
		_cQuery += "                   AND Z05_NUMOS = '" + _cNumOrdSrv + "' "

		_cQuery += "        INNER JOIN " + RetSqlTab("SC9") + " (nolock) "
		_cQuery += "                ON " + RetSqlCond("SC9")
		_cQuery += "                   AND C9_CARGA = Z05_CARGA "
		_cQuery += "                   AND C9_PRODUTO = Z16_CODPRO "

		_cQuery += "        INNER JOIN " + RetSqlTab("Z45") + " (nolock) "
		_cQuery += "                ON " + RetSqlCond("Z45")
		_cQuery += "                   AND Z45_ETQPAL = Z16_ETQPAL "
		_cQuery += "                   AND Z45_CODPRO = Z16_CODPRO "
		_cQuery += "                   AND Z45_ETQVOL = Z16_ETQVOL "
		_cQuery += "                   AND Z45_PEDIDO = C9_PEDIDO "
		_cQuery += "                   AND Z45_ITEM = C9_ITEM "

	EndIf

	// filtro padrao
	_cQuery += " WHERE  "+RetSqlCond("Z16")
	// endereco
	_cQuery += "        AND Z16_ETQPAL = '" + _cIdPalete + "' "
	// somente com saldo
	_cQuery += "        AND Z16_SALDO > 0 "

	memowrit("c:\query\twmsa011_sfRetSelVlm.txt", _cQuery)

	// atualiza variavel de retorno
	_aTmpDados := U_SqlToVet(_cQuery, {"Z16_VLDLOT"})

Return(_aTmpDados)

// ** funcao que bloqueia registro da composicao do palete
Static Function sfLockPlt(mvIdPalete)

	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"Z16"})

	// variavel de retorno
	local _lLockOk := .T.

	// query na Z16
	local _cQryZ16 := ""

	// array de retorno
	local _aRecnoZ16 := {}
	local _nRecZ16

	//Dados do pallet
	_cQryZ16 := " SELECT Z16.R_E_C_N_O_ Z16RECNO "
	_cQryZ16 += " FROM   " + RetSqlTab("Z16") + " (nolock) "
	_cQryZ16 += " WHERE  " + RetSqlCond("Z16")
	_cQryZ16 += "        AND Z16_ETQPAL = '" + mvIdPalete + "' "
	_cQryZ16 += "        AND Z16_SALDO > 0 "

	memowrit("C:\query\TWMSA011_sfLockPlt.txt",_cQryZ16)

	// dados jogados no array
	_aRecnoZ16 := U_SqlToVet(_cQryZ16)

	// varre todos os registros do palete, para tentar bloquear
	For _nRecZ16 := 1 to Len(_aRecnoZ16)

		// posiciona no registro
		dbSelectArea("Z16")
		Z16->( dbGoTo( _aRecnoZ16[_nRecZ16] ) )

		//testa se ja esta bloqueado
		If ( ! Z16->( MsRLock()) )
			// mensagem apos movimentacao, para nao bloquear transacao
			U_FtWmsMsg("Registro do palete bloqueado por outro usuário." + CRLF + "Favor tentar novamente!", "sfLockPlt Z16", .F., .T.)
			// controle
			_lLockOk := .F.
			// sai do For
			Exit
		EndIf

		// tenta bloquear o registro do mapa
		If ( ! SoftLock("Z16") )
			// mensagem apos movimentacao, para nao bloquear transacao
			U_FtWmsMsg("Registro do palete bloqueado por outro usuário." + CRLF + "Favor tentar novamente!", "sfLockPlt Z16", .F., .T.)
			// controle
			_lLockOk := .F.
			// sai do For
			Exit
		EndIf

		// adiciona RECNO para controle
		Aadd(_aRegLock, {"Z16", Z16->( RecNo() )} )

	Next _nRecZ16

	// restaura areas iniciais
	RestOrd(_aAreaIni, .T.)
	RestArea(_aAreaAtu)

Return( _lLockOk )

// ** funcao para definicao de DOCA de expedicao
Static Function sfDefDocExp(mvCodCli, mvLojCli)
	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"Z06", "Z08"})

	// variável de retorno
	Local _lRet := .T.

	// controle de confirmacao da tela
	local _lFixaWnd := .F.

	// relacao docas
	local _aColsDoca := {}
	local _aHeadDoca := {}

	// variável que receberá a query de consulta
	Local _cQrySBE := ""

	// seek
	local _cSeekZ08

	// objetos da tela
	local _oBmpOK, _oBmpSaida
	local _oPnlDefDoca, _oBrwDefDoca, _oWndDefDoca

	// define header do browse
	aAdd(_aHeadDoca, {"Docas", "BE_LOCALIZ", "", TamSx3("BE_LOCALIZ")[1], 0, Nil, Nil, "C", Nil,"R" })

	// Query simples pra trazer todas as DOCAS cadastradas para o cliente disponíveis e que não estejam BLOQUEADAS (BE_STATUS = 3)
	_cQrySBE += " SELECT BE_LOCALIZ, "
	_cQrySBE += "        '.F.' IT_DEL "
	_cQrySBE += " FROM   " + RetSqlTab("SBE") + " (nolock) "
	_cQrySBE += "        INNER JOIN " + RetSqlTab("DC8") + " (nolock) "
	_cQrySBE += "                ON " + RetSqlCond("DC8")
	_cQrySBE += "                   AND DC8_CODEST = BE_ESTFIS "
	_cQrySBE += "                   AND DC8_TPESTR = '5' "
	_cQrySBE += " WHERE  " + RetSqlCond("SBE")
	_cQrySBE += "        AND BE_LOCAL = '" + _cArmzAtual + "' "
	_cQrySBE += "        AND BE_STATUS != '3' "
	_cQrySBE += "        AND BE_ZCODCLI = '" + mvCodCli + "' "
	_cQrySBE += " ORDER  BY BE_LOCALIZ "

	MemoWrit("c:\query\twmsa011_sfDefDocExp.txt", _cQrySBE )

	// jogo o resultado da query no array
	_aColsDoca := U_SqlToVet(_cQrySBE)

	// monta o dialogo do monitor
	_oWndDefDoca := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Definir Doca",,,.F.,,,,,,.T.,,,.T. )
	_oWndDefDoca:lEscClose := .F.

	// cria o panel do cabecalho - botoes
	_oPnlDefDoca := TPanel():New(000,000,nil,_oWndDefDoca,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlDefDoca:Align:= CONTROL_ALIGN_TOP

	// -- BOTAO DE OK
	_oBmpOK := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lRet := .T., _lFixaWnd := .T., _oWndDefDoca:End() },_oPnlDefDoca,"Definir Doca",,.T.)
	_oBmpOK:Align := CONTROL_ALIGN_LEFT

	// -- BOTAO DE SAIDA
	_oBmpSaida := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _lRet := .F., _oWndDefDoca:End() },_oPnlDefDoca,"Sair",,.T.)
	_oBmpSaida:Align := CONTROL_ALIGN_RIGHT

	// monta o browse
	_oBrwDefDoca := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDoca),'AllwaysTrue()','','AllwaysTrue()',_oWndDefDoca,_aHeadDoca,_aColsDoca)
	_oBrwDefDoca:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa o dialogo
	_oWndDefDoca:Activate(,,,.F.,{|| _lFixaWnd },,)

	// se for confirmado tela
	If (_lRet)

		// atualiza endereco de destino
		_cEndDesti := _oBrwDefDoca:aCols[_oBrwDefDoca:nAt][1]

		// atualiza endereco de destino da ordem de servico
		dbSelectArea("Z08")
		Z08->( DbSetOrder(1) ) // 1 - Z08_FILIAL, Z08_NUMOS
		Z08->( DbSeek( _cSeekZ08 := xFilial("Z08") + _cNumOrdSrv ) )

		// varre todos os itens do mapa de expedicao
		While Z08->( ! Eof() ) .And. ((Z08->Z08_FILIAL + Z08->Z08_NUMOS) == _cSeekZ08)

			// atualiza campo endereco de destino
			RecLock("Z08")
			Z08->Z08_ENDDES := _cEndDesti
			Z08->( MsUnLock() )
			// proximo item
			Z08->( DbSkip() )
		EndDo

		// atualiza endereco de destino da sequencia do servico
		dbSelectArea("Z06")
		Z06->( DbSetOrder(1) ) // 1 - Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
		If Z06->( DbSeek( xFilial("Z06") + _cNumOrdSrv + _cSeqOrdSrv ) )
			// atualiza campo de endereco
			RecLock("Z06")
			Z06->Z06_ENDSRV := _cEndDesti
			Z06->( MsUnLock() )
		EndIf

	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni, .T.)
	RestArea(_aAreaAtu)

Return( _lRet )

// ** funcao que bloqueia registro da composicao do palete
Static Function sfLockOS(mvNumOS)

	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"Z08"})

	// variavel de retorno
	local _lLockOk := .T.

	// query na Z08
	local _cQryZ08 := ""

	// array de retorno
	local _aRecnoZ08 := {}
	local _nRecZ08

	//Dados do pallet
	_cQryZ08 := " SELECT Z08.R_E_C_N_O_ Z08RECNO "
	_cQryZ08 += " FROM   " + RetSqlTab("Z08") + " (nolock) "
	_cQryZ08 += " WHERE  " + RetSqlCond("Z08")
	_cQryZ08 += "        AND Z08_NUMOS = '" + mvNumOS + "' "

	memowrit("C:\query\TWMSA011_sfLockOS.txt", _cQryZ08)

	// dados jogados no array
	_aRecnoZ08 := U_SqlToVet(_cQryZ08)

	// varre todos os registros da OS, para tentar bloquear
	For _nRecZ08 := 1 to Len(_aRecnoZ08)

		// posiciona no registro
		dbSelectArea("Z08")
		Z08->( dbGoTo( _aRecnoZ08[_nRecZ08] ) )

		//testa se ja esta bloqueado
		If ( ! Z08->( MsRLock()) )
			// mensagem apos movimentacao, para nao bloquear transacao
			U_FtWmsMsg("OS bloqueada (em transação) por outro usuário." + CRLF + "Aguarde 1 minuto e tente novamente! (1)", "TWMSA011 - sfLockOS - 1", .F., .T.)
			// controle
			_lLockOk := .F.
			// sai do For
			Exit
		EndIf

		// tenta bloquear o registro do mapa
		If ( ! SoftLock("Z08") )
			// mensagem apos movimentacao, para nao bloquear transacao
			U_FtWmsMsg("OS bloqueada (em transação) por outro usuário." + CRLF + "Aguarde 1 minuto e tente novamente! (2)", "TWMSA011 - sfLockOS - 2", .F., .T.)
			// controle
			_lLockOk := .F.
			// sai do For
			Exit
		EndIf

		// adiciona RECNO para controle
		Aadd(_aLockZ08, {"Z08", Z08->( RecNo() )} )

	Next _nRecZ08

	// restaura areas iniciais
	RestOrd(_aAreaIni, .T.)
	RestArea(_aAreaAtu)

Return( _lLockOk )

//-------------------------------------------------------------------------------------------------
// função auxiliar para leitura individual de etiquetas barcode Sumitomo
// Parâmetros : [1] - Qtd de produtos/códigos de barra lidos (1² UM) a serem retornados por referência para loop principal
//              [2] - Qtd de produtos/códigos de barra lidos (2² UM) a serem retornados por referência para loop principal
//              [3] - Código cliente
//              [4] - Código produto
//              [5] - ID do pallet original (sendo fracionado)
//              [6] - Quantidade necessária para fracionar (informativo ao usuário)
Static Function EtqSumi(mvQtdProd, mvQtdSegum, mvCodCli, _cCodProd, mvIdPalete, mvQtd, mvIdEtqProd)
	// obejtos da tela
	local _oBmpEstorno, _oBmpConsDetSair
	local _oPnlConfDet, _oPnlConfRod

	// variaveis do browse
	local _aHeadSum		:= {}

	Local oFont18		:= TFont():New('Arial',,-18,,.F.)
	Local oFont14n		:= TFont():New('Arial',,-14,,.T.)
	Local oFont12n		:= TFont():New('Arial',,-12,,.T.)

	local cRetorno := .T.

	Private nQtdSum		:= 0
	Private _cProdBp	:= SPACE(8)
	Private _cProdCf	:= SPACE(8)
	private _oBrwSum
	Private _oGetSum
	Private _oGetConf
	Private _oSayTS
	Private oDlgEtqS

	// define o header
	aAdd(_aHeadSum,{"Etq Cliente","Z11_CODETI"  ,"@!"                         ,8                      , 0                    ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadSum,{"Quant"      ,"Z11_QTD1"    ,_cMaskQuant                  ,1                      , 0                    ,Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHeadSum,{"Produto"    ,"B1_COD"      ,PesqPict("SB1","B1_COD")     ,TamSx3("B1_COD")[1]    , 0                    ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadSum,{"Desc Prod"  ,"B1_DESC"     ,PesqPict("SB1","B1_DESC")    ,TamSx3("B1_DESC")[1]   , 0                    ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadSum,{"Legado"     ,"cLegado"     ,"@!"                         ,1                      , 0                    ,Nil,Nil,"C",Nil,"R",,,".F." })

	_aColsSum	:= {}

	// monta o dialogo do monitor
	oDlgEtqS := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Expedição Sumitomo",,,.F.,,,,,,.T.,,,.T. )
	oDlgEtqS:lEscClose := .F.

	// cria o panel do cabecalho - botoes
	_oPnlConfDet := TPanel():New(000,000,nil,oDlgEtqS,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlConfDet:Align:= CONTROL_ALIGN_TOP

	// Total de produtos bipados
	_oSayTS       := TSay():New(005,001,{|| "Qtd lida: " + AllTrim(Str(nQtdSum)) + "/" + AllTrim(Str(mvQtd)) },_oPnlConfDet,,oFont12n,.F.,.F.,.F.,.T.)
	_oSayTS:Align := CONTROL_ALIGN_CENTER

	// -- CONFIRMACAO
	_oBtnSrvConf := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| ConfSum(@mvQtdProd,@mvQtdSegum) },_oPnlConfDet,"Ok",,.T.)
	_oBtnSrvConf:Align := CONTROL_ALIGN_RIGHT

	// -- BOTAO DE ESTORNO
	_oBmpEstorno := TBtnBmp2():New(000,000,040,040,"ESTOMOVI",,,,{|| EstrSum(_oBrwSum:aCols[_oBrwSum:nAt][1],_oBrwSum:nAt,_oBrwSum:aCols[_oBrwSum:nAt][5]) },_oPnlConfDet,"Estornar leitura de etiqueta",,.T.)
	_oBmpEstorno:Align := CONTROL_ALIGN_RIGHT

	// monta o browse com os motivos de interrupcoes
	_oBrwSum := MsNewGetDados():New(018,001,137,122,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsSum),'AllwaysTrue()','','AllwaysTrue()',oDlgEtqS,_aHeadSum,_aColsSum)

	// cria o panel do rodape - botoes
	_oPnlConfRod := TPanel():New(000,000,nil,oDlgEtqS,,.F.,.F.,,,020,025,.T.,.F. )
	_oPnlConfRod:Align:= CONTROL_ALIGN_BOTTOM

	// Campo para bipar as etiquetas
	_oSay := TSay():New(004,002,{|| "Barcode: " },_oPnlConfRod,,oFont12n,.F.,.F.,.F.,.T.)
	_oGetSum := TGet():New(001,060,{|u| If(PCount()>0,_cProdBp:=u,_cProdBp)},_oPnlConfRod,042,008,"@R 99999999",{|| (Vazio()) .Or. AddBrwS( _cProdBp, _cProdCf, mvCodCli, _cCodProd, mvIdPalete, mvIdEtqProd) },,,oFont18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cProdBp",,)
	_oGetSum:bWhen := {|| (nQtdSum) < (mvQtd) }
	_oGetSum:SetFocus()

	// Campo para bipar a confirmação da etiqueta
	_oSay := TSay():New(016,002,{|| "Confirmação: " },_oPnlConfRod,,oFont12n,.F.,.F.,.F.,.T.)
	_oGetConf := TGet():New(014,060,{|u| If(PCount()>0,_cProdCf:=u,_cProdCf)},_oPnlConfRod,042,008,"@R 99999999",;
	{|| IIF(sfVldBip(_cProdBp,_cProdCf),(AddBrwS( _cProdBp, _cProdCf, mvCodCli, _cCodProd, mvIdPalete, mvIdEtqProd)),.F.),_cProdCf:=Space(8), _cProdBp := Space(8), _oGetConf:Disable(),_oGetSum:SetFocus() },;
	,,oFont18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cProdCf",,)
	_oGetConf:Disable()

	// ativa o dialogo
	oDlgEtqS:Activate(,,,.F.,,,)

	// se cancelou ou não bipou nada
	if (Len(_aColsSum) == 0)
		cRetorno := .F.
	EndIf

Return(cRetorno)
//-------------------------------------------------------------------------------------------------
Static Function ConfSum(mvQtdProd,mvQtdSegum)

	// se não fez nenhuma leitura
	If (mvQtdProd == 0)
		U_FtWmsMsg("Nenhuma etiqueta foi bipada. Faça alguma leitura para poder retornar a tela principal")
		Return
	EndIf

	// solicita confirmação para encerrar o fracionamento nesta etiqueta
	If U_FtYesNoMsg("Confirma os itens bipados ?")
		mvQtdProd	:= ConvUM(SB1->B1_COD, Len(_aColsSum), 0, 1) //Valida a quantidade da primeira UM
		mvQtdSegum	:= ConvUM(SB1->B1_COD, Len(_aColsSum), 0, 2) //Valida a quantidade da segunda UM
		oDlgEtqS:End()
	EndIf

Return
//-------------------------------------------------------------------------------------------------
Static Function ExitSum()

	If U_FtYesNoMsg("Deseja sair e cancelar os itens bipados ?")
		_aColsSum := {}
		oDlgEtqS:End()
	EndIf

Return
//-------------------------------------------------------------------------------------------------
Static Function EstrSum(cEtiqCli,nPos,_cLegado)

	If (Empty(cEtiqCli))
		Return
	Else
		If U_FtYesNoMsg("Estornar etiqueta " + AllTrim(cEtiqCli) + " ?")
			// se for etiqueta de legado, exclui o registro na Z56
			If _cLegado == "S" // se a etiqueta selecionada for Legado, exclui o registro criado na Z56
				// necessário uso de update para marcar como deletado, pois com Reclock da registro bloqueado
				_cUpdate := " Update "+RetSQLName("Z56")+" set D_E_L_E_T_ = '*',R_E_C_D_E_L_ = R_E_C_N_O_  "
				_cUpdate += " where Z56_FILIAL = '"+xFilial("Z56")+"' and Z56_ETQCLI = '"+cEtiqCli+"' "
				_cUpdate += " and Z56_CODCLI = '"+_cCodCliMov+"' and Z56_LOJCLI = '"+_cLjCliMov+"' "
				TcSQLExec(_cUpdate)
			EndIf
			ADEL(_aColsSum,nPos)
			ASIZE(_aColsSum,Len(_aColsSum)-1)
			nQtdSum := Len(_aColsSum)
			_oBrwSum:aCols := aClone(_aColsSum)
			_oBrwSum:Refresh(.T.)
			_cProdBp := Space(8)
			_oGetSum:Refresh(.T.)
			_oGetSum:SetFocus()
		EndIf

		_oSayTS:Refresh(.T.)
	EndIf
Return
//-------------------------------------------------------------------------------------------------
Static Function AddBrwS( _cProdBp, _cProdCf, mvCodCli, _cCodProd, mvIdPalete, mvIdEtqProd)
	Local _nX
	Local lRet       := .T.
	Local cQuery     := ""
	Local _cRet      := ""
	local _aRetZ56   := {}
	local _cInsZ56   := ""
	local lEtqLegado := .T.    // se etiqueta faz parte do estoque legado, que deu entrada sem vincular com etiqueta Tecadi de produto
	Local _cSequen
	Private _cConfPrd:= Space(8)

	// Valida se a etiqueta já foi adicionada
	If (lRet)
		For _nX :=1 to Len(_aColsSum)
			If ( ASCAN(_aColsSum, { |x| x[1] == _cProdBp }) > 0 )
				U_FtWmsMsg("A etiqueta " + AllTrim(_cProdBp) + " já foi lida neste fracionamento!")
				lRet := .F.
				_cProdBp := Space(8)
				_oGetSum:Refresh(.T.)
				_oGetSum:SetFocus()
			EndIf
		Next _nX
	EndIf

	// Valida se tem 8 digitos
	If (lRet)
		If (Len(AllTrim(_cProdBp)) <> 8 )
			U_FtWmsMsg("Barcode " + AllTrim(_cProdBp) + " inválido!")
			lRet := .F.
			_cProdBp := Space(8)
			_oGetSum:Refresh(.T.)
			_oGetSum:SetFocus()
		EndIf
	EndIf

	// valida se etiqueta bipada faz parte da carga de etiquetas/banco de dados legado
	// que já existia no sistema antes da rotina e portanto, não foi vinculado o código de barras com uma etiqueta
	// Tecadi na conferência de entrada
	// pressupôe-se que toda etiqueta é parte de legado, até que a query/validação altere isso e passe a fazer
	// mais validações abaixo
	If (lRet)
		cQuery := " SELECT TOP 1 Z56_CODETI"
		cQuery += " FROM "  + RetSqlTab("Z56") + " (nolock) "
		cQuery += " WHERE " + RetSqlCond("Z56")
		cQuery += " AND Z56_CODCLI = '" + mvCodCli  + "' "
		cQuery += " AND Z56_ETQCLI = '" + _cProdBp     + "' "

		_cRet := U_FTQuery(cQuery)

		// se trouxe resultado, significa que etiqueta Tecadi já foi vinculada em algum momento e não é legado
		if !Empty(_cRet)
			lEtqLegado := .F.
		EndIf
	EndIf

	// validações da etiqueta do cliente
	If (lRet)
		// caso etiqueta seja legado, valida se equivale ao produto sendo lido/fracionado
		If (lEtqLegado)
			cQuery := " SELECT Z56_CODPRO"
			cQuery += " FROM "  + RetSqlTab("Z56") + " (nolock) "
			cQuery += " WHERE " + RetSqlCond("Z56")
			cQuery += " AND Z56_CODCLI = '" + _cCodCliMov  + "' "
			cQuery += " AND Z56_LOJCLI = '" + _cLjCliMov   + "' "
			cQuery += " AND Z56_ETQCLI = '" + _cProdBp     + "' "

			// Recebe o código do produto (SKU) buscado pela etiqueta do cliente (BARCODE)
			_cRet := U_FTQuery(cQuery)
			// se produto da etiqueta é diferente do que está sendo fracionado/operacionalizado (Z56 barcodes VS z16/z11)
			If (!( Empty(_cRet)) .AND. _cRet != _cCodProd)
				U_FtWmsMsg("Produto incorreto!" + CRLF + "Leitura: " + _cRet + CRLF + "Esperado: " + _cCodProd, "TWMSA011 - valida etq" )
				lRet := .F.
				_cProdBp := Space(8)
				_oGetSum:Refresh(.T.)
				_oGetSum:SetFocus()
			EndIf

			If (lEtqLegado .And. Empty(_cProdCf))
				U_FtWmsMsg("O barcode não possui vínculo com etiqueta Tecadi e será necessário confirmação. Leia novamente no campo de confirmação abaixo.","ATENCAO")
			Endif

			// se não localizou o código do produto para esta etiqueta, significa que ela não existe
			If Empty(_cRet) .And. !Empty(_cProdCf)
				// Pulo-do-gato (do inglês Jump-of-the-cat) criado em 11/07/19 para virada da integração Sumitomo GWS x Totvs
				// visto que NEM SABEM que barcodes enviar para subirmos na base... então como foi liberado para o estoque existente não validar nada,
				// então cria registro na tabela Z56 do tipo "etiqueta legado" (sem entrada correta) para ir pra frente de qualquer jeito e que se dane...
				// Claro, assumimos que PIMPOWS biparam o código de produto certo...

				If lRet
					// pega o número sequencial máximo da máxima remessa
					cQuery := " SELECT IsNull(MAX(Z56_SEQUEN), '0001') FROM " + RetSqlTab("Z56") + " WHERE " + RetSqlCond("Z56") + " AND Z56_REMESS = '0000000000'"
					_cSequen := Soma1(U_FTQuery(cQuery))

					_cInsZ56 := "INSERT INTO Z56010"
					_cInsZ56 += " (Z56_FILIAL, Z56_REMESS, Z56_SEQUEN, Z56_ETQCLI, Z56_CODCLI, Z56_LOJCLI, Z56_CODPRO, Z56_CODETI, Z56_QUANT, Z56_OK_ENT, Z56_OK_SAI, R_E_C_N_O_)"
					_cInsZ56 += " VALUES "
					_cInsZ56 += " ('"+xFilial("Z56")+"', '0000000000','" + _cSequen + "' ,'"+_cProdBp+"', '"+_cCodCliMov+"', '"+_cLjCliMov+"', '"+_cCodProd+"', '"+mvIdEtqProd+"', 1, 'N', 'N', (SELECT MAX(R_E_C_N_O_) + 1  FROM Z56010) ) "

					// injeta no banco e não trata retorno, pq eu sou doidão
					TcSQLExec(_cInsZ56)
				Else
					_cProdBp := Space(8)
					_oGetSum:Refresh(.T.)
					_oGetSum:SetFocus()
				EndIf
			EndIf

		Else
			// caso não seja etiqueta cliente legado (ou seja, teve vínculo na entrada - recebimento)
			// valida se código de barras lido está relacionado com o pallet/etiqueta sendo fracionada
			cQuery := " SELECT Z56_CODPRO,Z56_CODETI,B1_DESC "
			cQuery += " FROM " + RetSQLTab("Z56") + " (nolock) "
			cQuery += " 	inner join " + RetSQLTab("SB1") + " (nolock) "
			cQuery += " 	on " + RetSqlCond("SB1")
			cQuery += " 	and B1_COD = Z56_CODPRO "
			cQuery += " where " + RetSqlCond("Z56")
			cQuery += " and Z56_CODCLI = '" + mvCodCli  + "' "
			cQuery += " and Z56_ETQCLI = '" + _cProdBp  + "' "
			cQuery += " and Z56_CODPRO = '" + _cCodProd + "' "
			cQuery += " and Z56_CODETI IN (SELECT Z16_ETQPRD "
			cQuery += "					FROM " + RetSQLTab("Z16")
			cQuery += "					WHERE "  + RetSqlCond("Z56")
			cQuery += "					AND Z16_ETQPAL = '" + mvIdPalete + "' "
			cQuery += "					and Z16_ETQPRD != '') "

			_aRetZ56 := U_SqlToVet(cQuery)

			// se não encontrou resultado
			If (Len(_aRetZ56) < 1)
				U_FtWmsMsg("Código de barras não localizado ou relacionado com o pallet original sendo fracionado.")
				lRet := .F.
				_cProdBp := Space(8)
				_oGetSum:Refresh(.T.)
				_oGetSum:SetFocus()
			EndIf
		EndIf
	EndIf

	// Tudo deu certo, adiciona no array de etiquetas lidas
	If (lRet)
		If lEtqLegado .And. Empty(_cProdCf)
			Sleep(2000)
			_oGetConf:Enable()
			_cProdCf := Space(8)
			_oGetConf:SetFocus()
		Else
			Sleep(1000)
			AADD(_aColsSum, {AllTrim(_cProdBp), 1, IIf(lEtqLegado, _cRet, _aRetZ56[1][1]), IIf(lEtqLegado, "", _aRetZ56[1][3]),IIF(lEtqLegado,"S","N"), .F.})

			nQtdSum := Len(_aColsSum)

			// atualiza os objetos
			_oSayTS:Refresh(.T.)
			_oBrwSum:aCols := aClone(_aColsSum)
			_oBrwSum:Refresh(.T.)
			_cProdCf := Space(8)
			_oGetConf:Disable()
			_cProdBp := Space(8)
			_oGetSum:Refresh(.T.)
			_oGetSum:SetFocus()
		EndIf
	EndIf

Return (lRet)
//-------------------------------------------------------------------------------------------------
// função auxiliar para verificar se é possível um apanhe de oportunidade
Static Function sfPegaOpor(mvIdPalete, mvTmpPal, mvQuery)

	local _lRet     := .F.
	Local _cQryOpo  := ""
	Local _aRetOpo  := ""
	local _nX       := 0
	local _aAreaZ16 := Z16->( GetArea() )
	local _aAreaZ08 := Z08->( GetArea() )
	local _dDtSeri
	Local _nRangeDt := SuperGetMV("TC_LIMISER",.F.,30)

	// posiciona no pallet lido para pegar os dados
	DbSelectArea("Z16")
	Z16->( DbSetOrder(1) )    // Z16_FILIAL, Z16_ETQPAL, R_E_C_N_O_, D_E_L_E_T_
	Z16->( dbSeek( xFilial("Z16") + mvIdPalete ) )

	// TODO validação temporária apenas para cliente MIDEA (EM TESTES)
	If (Substr(Z16->Z16_CODPRO,1,4) != "SPRI")
		Return (_lRet)
	EndIf

	// guarda informações do pallet lido para validações posteriores
	_dDtSeri := Z16->Z16_DTSERI

	// pega o RECNO do pallet lido (se está reservado em outra OS)
	_cQryOpo := "SELECT COUNT(R_E_C_N_O_) QTD FROM " + RetSqlTab("Z08") + " WHERE " + RetSqlCond("Z08") + " AND Z08_PALLET = '" + mvIdPalete + "' AND Z08_STATUS != 'R'"

	// Se pallet já reservado em outra OS, aborta
	If (U_FTQuery(_cQryOpo) != 0)
		Return (_lRet)
	EndIf

	// agora procura se há alguma OS em aberta, para o mesmo endereço/produto/lote/data serie/operador que possibilite trocar por este pallet
	// obs: não preciso validar se o pallet bipado já está em outra OS, pois antes de entrar nesta função, a função principal sfVldEtiqueta já faz isso
	// ou seja, vai procurar se existe um registro na Z08 "parecido" que permita ser trocado
	// na prática, o operador leu o "pallet errado" e agora vai procurar se tem algum registro que permita trocar por ele
	_cQryOpo := " SELECT Z08.R_E_C_N_O_  "
	_cQryOpo += " FROM " + RetSqlTab("Z08")
	_cQryOpo += " INNER JOIN " + RetSqlTab("Z18")
	_cQryOpo += "        ON "  + RetSqlCond("Z18")
	_cQryOpo += "  AND  Z18_STATUS = 'R'
	_cQryOpo += "              AND Z18_OPERAD = '" + _CCODOPER + "'
	_cQryOpo += "              AND Z08_NUMOS = Z18_NUMOS
	_cQryOpo += " WHERE " + RetSqlCond("Z08")
	_cQryOpo += "        AND Z08_PRODUT = '" + Z16->Z16_CODPRO + "'"
	_cQryOpo += "        AND Z08_ENDORI = '" + Z16->Z16_ENDATU + "'"
	_cQryOpo += "        AND Z08_ENDORI = Z08_ENDSRV"
	_cQryOpo += "        AND Z08_QUANT  = '" + Str(Z16->Z16_SALDO)  + "'"
	_cQryOpo += "        AND Z08_TPESTO = '" + Z16->Z16_TPESTO + "'"
	_cQryOpo += "        AND Z08_LOTCTL = '" + Z16->Z16_LOTCTL + "'"
	_cQryOpo += "        AND Z08_STATUS = 'P'"
	_cQryOpo += "  ORDER BY Z08.R_E_C_N_O_"

	memowrit("c:\query\twmsa011_apanhe_opo.txt", _cQryOpo )
	_aRetOpo := U_SqlToVet(_cQryOpo)

	// se encontrou RECNO elegível para a troca
	If Len(_aRetOpo) > 0
		For _nX := 1 to Len(_aRetOpo)
			Z08->(DbGoto(_aRetOpo[_nX]))                               // posiciona no registro do mapa de apanhe (já reservado)
			Z16->(DbSeek(xFilial("Z16") + Z08->Z08_PALLET))            // posiciona no pallet original do mapa de apanhe para validações/comparações

			// validações adicionais se o pallet é elegível
			If ( DateDiffDay(Z16->Z16_DTSERI, _dDtSeri) <= _nRangeDt )
				// solicita confirmação para troca
				If U_FtYesNoMsg("Apanhe de oportunidade possível para OS " + Alltrim(Z08->Z08_NUMOS) + CRLF + "Confirma?" , "Apanhe de oportunidade!")
					RecLock("Z08")
					Z08->Z08_PALLET := mvIdPalete    // substitui o mapa pelo pallet lido para continuar o processo
					Z08->( MsUnlock() )

					// refaz a busca para devolver a nova consulta para a rotina principal sfVldEtiqueta continuar seu processo
					// ainda que seja a mesma query, é necessário rodá-la novamente pois, agora, encontrará um registro na Z08 e irá preencher o array do pallet
					// TODO melhorar esta busca ou devolver já preenchido o array, FIZ NA PRESSAO - URGENTE URGENTE URGENTE e não pensei em algo melhor no momento (LUIZ)
					mvTmpPal := U_SqlToVet(mvQuery)
					_lRet := .T.
					Exit
				Else
					// caso não confirmou, usuário não se interessou em utilizar o pallet, então sai do loop e abandona o processo
					Exit
				EndIf
			Else
				Loop  // tenta outro registro
			EndIf
		Next _nX
	EndIf

	RestArea(_aAreaZ16)
	RestArea(_aAreaZ08)

Return (_lRet)
//-------------------------------------------------------------------------------------------------
// função para validar se as etiquetas bipadas de legado são válidas
Static Function sfVldBip(_cProdBp,_cProdCf)
	Local _lRet := .T.

	If Len(AllTrim(_cProdBp)) <> 8 .Or. Len(AllTrim(_cProdCf)) <> 8
		U_FtWmsMsg("Tamanho de etiqueta inválido!","ATENCAO")
		_lRet := .F.
	EndIf

	If _lRet
		If _cProdBp <> _cProdCf
			U_FtWmsMsg("Os barcodes lidos são divergentes. Verifique se a leitura está correta ou se a etiqueta não está suja ou falhada.","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

Return(_lRet)