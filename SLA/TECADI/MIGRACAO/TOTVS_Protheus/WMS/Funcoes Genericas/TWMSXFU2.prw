#Include "Totvs.ch"
#include "protheus.ch"
#Include "topconn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descrição         ! Funcoes Genericas pertinentes a inventário utilizadas   !
!                  ! no modulo WMS                                           !
! 1 - FTFecInv     ! Função para fechamento de inventario inicial de cliente !
!                  ! Cria etiquetas lidas no inventário e gera o saldo no    !
!                  ! endereço (carga inicial de dados)                       !
! 2 - FTEndInv     ! Valida se um determinado endereço e local está em       !
!                  ! algum inventário pendente de finalização                !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 08/2016 !
+------------------+--------------------------------------------------------*/

// rotina principal para fechamento de inventário e subida de carga de dados inicial
// (sobe informações de posição e etiquetas com base em inventário realizado)
User Function FtFecInv()

	// objetos da tela
	local _aSays := {}
	local _aButtons := {}

	// controle de confirmacao
	local _lOk := .f.

	// grupo de perguntas
	Local _aPerg := {}
	Local _cPerg := PadR("FTFECINV",10)

	// mensagem da tela principal
	Aadd(_aSays,"Rotina para fechamento de inventário (carga inicial de dados)")
	Aadd(_aSays,"Conferir parametro para execução da rotina.")

	// opcoes disponiveis
	Aadd(_aButtons, {01, .T., {|o| _lOk := .t.          , o:oWnd:End() }}) // Ok 01
	Aadd(_aButtons, {02, .T., {|o| _lOk := .f.          , o:oWnd:End() }}) // Cancela 02
	Aadd(_aButtons, {05, .T., {|o| Pergunte(_cPerg, .t.), Nil          }}) // parametros 05

	// criacao das Perguntas
	aAdd(_aPerg,{"Cliente?"          , "C", TamSx3("A1_COD")[1],0,"G",,"SA1"})                 //mv_par01
	aAdd(_aPerg,{"Loja?"             , "C", TamSx3("A1_LOJA")[1],0,"G",,""})                   //mv_par02
	aAdd(_aPerg,{"Tipo Movimentacao?", "N", 1,0,"C",{"Por Volumes", "Por Lote - Blocado"},""}) //mv_par03
	aAdd(_aPerg,{"Armazém?"          , "C", TamSx3("BE_LOCAL")[1],0,"G",,"Z12"})               //mv_par04
	aAdd(_aPerg,{"Rua?"              , "C", 2,0,"G",,""})                                      //mv_par05
	aAdd(_aPerg,{"Lado?"             , "N", 2,0,"C",{"Lado A", "Lado B"},""})                  //mv_par06
	aAdd(_aPerg,{"Endereço?"         , "C", TamSx3("BE_LOCALIZ")[1],0,"G",,"Z12"})             //mv_par07
	aAdd(_aPerg,{"Ord.Serv.De?"      , "C", TamSx3("Z05_NUMOS")[1],0,"G",,""})                 //mv_par08
	aAdd(_aPerg,{"Ord.Serv.Ate?"     , "C", TamSx3("Z05_NUMOS")[1],0,"G",,""})                 //mv_par09

	// cria grupo de perguntas
	U_FtCriaSX1(_cPerg, _aPerg)

	// carrega memoria
	Pergunte(_cPerg, .f.)

	// formulario padrao para escolha das opcoes
	FormBatch("Fechamento de Inventário", _aSays, _aButtons)

	// se foi confirmado
	If (_lOk)

		// valida conteudo dos campos
		If (Empty(mv_par01)) .Or. (Empty(mv_par02))
			MsgStop("Favor informar código e loja do cliente!")
			Return
		EndIf

		// valida se o cliente existe
		dbSelectArea("SA1")
		SA1->(dbSetOrder(1)) // 1-A1_FILIAL, A1_COD, A1_LOJA
		If ! SA1->(dbSeek( xFilial("SA1")+mv_par01+mv_par02 ))
			MsgStop("Cliente não encontrado. Favor verificar código e loja do cliente!")
			Return
		EndIf

		If (mv_par03 == 1) // 1 - Volume - Controle de Mercadoria por Volumes/Caixas
			sfFecVolume()
		ElseIf (mv_par03 == 2) // 2 - Lote - Inventário em Blocado
			sfFecLotBlc()
		EndIf

	EndIf

Return

// ** fechamento de inventario para cliente com controle de Volumes
Static Function sfFecVolume()

	// controle de divergencias
	local _lDiverg := .f.

	// recno SBE
	local _aRecnoSBE := {}
	local _nRecnoSBE := 0

	// recno Z19
	local _aDadosZ19 := {}
	local _nItemZ19 := 0

	// arquivo de log
	local _cEndBloq  := ""
	local _cEndVazio := ""
	local _nEndVazio := 0
	local _cProdNorm := ""
	local _cSaldoNor := ""
	local _cEndAtual := ""
	local _cLog := ""

	// codigo do produto
	local _cCodProd := ""

	// etiqueta de volume
	local _cEtqVolume := ""

	// etiqueta de cliente
	local _cEtqClient := ""

	// quantidade inventariada
	local _nQtdInvent := 0
	local _nQtdSegum  := 0

	// tipo de embalagem
	local _cTpEmbala := ""

	// tipo de estoque
	local _cTpEstoque := ""

	// codigo de barras
	local _cCodBar := ""

	// lote
	local _cLote := ""

	// querys
	local _cQrySBE
	local _cQryZ19
	local _cQryZ06

	// dados do palete
	local _cIdPalete  := ""
	local _cCodUnit   := ""
	local _aEstPalete := {}
	local _aSaldoProd := {}
	local _nPosSaldo  := 0
	local _nZ16 := 0
	local _nSBF := 0

	// codigo do unitizador padrao
	local _cUnitPdr := SuperGetMV('TC_PLTPADR',.F.,"000001")

	// controle de palete com etiqueta parcial
	local _aTmpConteudo := {}
	local _cCodEtiq := ""

	// posicao dos campos
	local _nPosLocal  := 1
	local _nPosEnder  := 2
	local _nPosEtqVol := 3
	local _nPosCodPro := 4
	local _nPosQuant  := 5
	local _nPosTpEmb  := 6
	local _nPosTpEst  := 7
	local _nPosCdBar  := 8
	local _nPosLote   := 9
	local _nPosQtSeg  := 10
	local _nPosEtqCli := 11

	// Obtem numero sequencial do movimento
	LOCAL _cNumSeq := ""
	// Numero do Item do Movimento
	Local _cCounter	:= ""

	// atualiza variaveis
	local _cLadoRua := IIf(mv_par06==1, "A", "B")

	// gera saldo inicial por lote
	local _lGeraSBJ := .F.

	// valida identificacao do produto
	local _cTpIdEtiq := U_FtWmsParam("WMS_PRODUTO_ETIQ_IDENT", "C", "INTERNA", .F., "", mv_par01, mv_par02, Nil, Nil)

	// tipo de identificacao
	local _lEtqIdInt  := (AllTrim(_cTpIdEtiq) == "INTERNA")
	local _lEtqIdEAN  := (AllTrim(_cTpIdEtiq) == "EAN") .Or. (AllTrim(_cTpIdEtiq) == "EAN13")
	local _lEtqIdDUN  := (AllTrim(_cTpIdEtiq) == "DUN14")
	local _lEtqCod128 := (AllTrim(_cTpIdEtiq) == "CODE128")
	local _lEtqClient := (AllTrim(_cTpIdEtiq) == "CLIENTE")

	// query das OS em aberto
	_cQryZ06 := " SELECT Z05_NUMOS "
	// ordem de servico
	_cQryZ06 += " FROM   " + RetSqlTab("Z05") + " (nolock) "
	_cQryZ06 += "        INNER JOIN " + RetSqlTab("Z06") + " (nolock) "
	_cQryZ06 += "                ON " + RetSqlCond("Z06")
	_cQryZ06 += "                   AND Z06_NUMOS = Z05_NUMOS "
	_cQryZ06 += "                   AND Z06_STATUS <> 'FI' "
	_cQryZ06 += "                   AND Z06_SERVIC = 'T02' "
	_cQryZ06 += " WHERE  " + RetSqlCond("Z05")
	_cQryZ06 += "        AND Z05_CLIENT = '" + mv_par01 + "' "
	_cQryZ06 += "        AND Z05_LOJA = '" + mv_par02 + "' "
	_cQryZ06 += "        AND Z05_NUMOS BETWEEN '" + mv_par08 + "' AND '" + mv_par09 + "' "

	// filta todos os enderecos conforme parametros
	_cQrySBE := " SELECT SBE.R_E_C_N_O_ SBERECNO "
	_cQrySBE += " FROM "+RetSqlTab("SBE")+" (nolock) "
	_cQrySBE += " WHERE "+RetSqlCond("SBE")
	_cQrySBE += " AND BE_LOCAL = '"+mv_par04+"' "

	If (Empty(mv_par07))
		_cQrySBE += " AND SUBSTRING(BE_LOCALIZ,1,3) = '"+mv_par05+_cLadoRua+"' "
		// filtra somente um endereco
	ElseIf ( ! Empty(mv_par07) )
		_cQrySBE += " AND BE_LOCALIZ = '"+mv_par07+"' "
	EndIf

	// descarta itens ja finalizados
	_cQrySBE += " AND BE_LOCALIZ NOT IN (SELECT DISTINCT Z16_ENDATU FROM "+RetSqlTab("Z16")+" (nolock)  WHERE "+RetSqlCond("Z16")+" AND Z16_ORIGEM = 'Z19') "
	// ordem dos dados
	_cQrySBE += " ORDER BY BE_LOCALIZ "

	memowrit("c:\query\FtFecInv2.txt",_cQrySBE)

	// joga os dados para o vetor
	_aRecnoSBE := U_SqlToVet(_cQrySBE)

	For _nRecnoSBE := 1 to Len(_aRecnoSBE)

		// posiciona no registro real da tabela
		dbSelectArea("SBE")
		SBE->(dbGoTo( _aRecnoSBE[_nRecnoSBE] ))

		// marca divergencia
		_lDiverg := .f.

		// verifica se o endereco esta bloqueado
		If (SBE->BE_STATUS == "3")
			_cEndBloq += SBE->BE_LOCALIZ
			_cEndBloq += CRLF

		ElseIf (SBE->BE_STATUS != "3")

			//-- verifica se houve inventario
			_cQryZ19 := " SELECT Z19_LOCAL, Z19_ENDERE, Z19_ETQVOL, Z19_CODPRO, SUM(Z19_QUANT) Z19_QUANT, Z19_TPEMBA, Z19_TPESTO, Z19_CODEAN, Z19_LOTCTL, Sum(Z19_QTSEGU) Z19_QTSEGU, Z19_ETQCLI "
			_cQryZ19 += " FROM " + RetSqlTab("Z19") + " (nolock) "
			_cQryZ19 += " WHERE " + RetSqlCond("Z19")
			_cQryZ19 += " AND Z19_IDENT IN (" + _cQryZ06 + ") "
			_cQryZ19 += " AND Z19_LOCAL  = '" + SBE->BE_LOCAL + "' "
			_cQryZ19 += " AND Z19_ENDERE = '" + SBE->BE_LOCALIZ + "' "
			_cQryZ19 += " AND Z19_CODPRO <> ' ' "
			_cQryZ19 += " AND Z19_CONTAG = (SELECT MAX(Z19_CONTAG) FROM Z19010 (nolock)  WHERE Z19_FILIAL = Z19.Z19_FILIAL AND Z19_IDENT = Z19.Z19_IDENT AND Z19_ETQVOL = Z19.Z19_ETQVOL AND Z19_ETQCLI = Z19.Z19_ETQCLI AND Z19_LOTCTL = Z19.Z19_LOTCTL AND Z19.Z19_ENDERE = Z19_ENDERE) "
			_cQryZ19 += " GROUP BY Z19_LOCAL, Z19_ENDERE, Z19_ETQVOL, Z19_CODPRO, Z19_TPEMBA, Z19_TPESTO, Z19_CODEAN, Z19_LOTCTL, Z19_ETQCLI "
			_cQryZ19 += " ORDER BY Z19_ETQVOL, Z19_CODPRO, Z19_ETQCLI "

			// joga os dados para o vetor
			_aDadosZ19 := U_SqlToVet(_cQryZ19)

			If (Len(_aDadosZ19) == 0)
				// marca divergencia
				_lDiverg := .T.
				// gera o log
				_cEndVazio += SBE->BE_LOCALIZ
				_cEndVazio += CRLF
				// quantidade
				_nEndVazio ++
				// loop
				Loop
			EndIf

			// zera variaveis
			_nQtdInvent := 0
			_nQtdSegum  := 0
			_cCodProd   := ""
			_cEtqVolume := ""
			_cEtqClient := ""
			_cTpEmbala  := ""
			_cTpEstoque := ""
			_cCodBar    := ""
			_cLote      := ""

			// dados do palete
			_cIdPalete  := ""
			_cCodUnit   := ""
			_aEstPalete := {}
			_aSaldoProd := {}


			// varre todos os itens inventariados
			For _nItemZ19 := 1 to Len(_aDadosZ19)

				// define o codigo do produto
				_cCodProd   := _aDadosZ19[_nItemZ19][_nPosCodPro]

				// etiqueta de volume
				_cEtqVolume := _aDadosZ19[_nItemZ19][_nPosEtqVol]

				// quantidade saldo inventariado
				_nQtdInvent := _aDadosZ19[_nItemZ19][_nPosQuant]

				// codigo tipo da embalagem
				_cTpEmbala  := _aDadosZ19[_nItemZ19][_nPosTpEmb]

				// codigo tipo da embalagem
				_cTpEstoque := _aDadosZ19[_nItemZ19][_nPosTpEst]

				// codigo de barras
				_cCodBar    := _aDadosZ19[_nItemZ19][_nPosCdBar]

				// lotectl
				_cLote      := _aDadosZ19[_nItemZ19][_nPosLote]

				// quantidade seg unid medida
				_nQtdSegum  := _aDadosZ19[_nItemZ19][_nPosQtSeg]

				// etiqueta de cliente
				_cEtqClient := _aDadosZ19[_nItemZ19][_nPosEtqCli]

				// consulta existencia de etiquetas
				If ( !_lEtqClient )
					// verfifica se existe etiqueta de volume
					dbSelectArea("Z11")
					Z11->(dbSetOrder(1)) // 1-Z11_FILIAL, Z11_CODETI
					If ( ! Z11->(dbSeek( xFilial("Z11") + _cEtqVolume )))
						MsgStop("Erro Z11 ## Eti Volume não localizada  - " + _cEtqVolume)
						Loop
					EndIf

				ElseIf (_lEtqClient)
					// verfifica se existe etiqueta de cliente
					dbSelectArea("Z11")
					Z11->(dbSetOrder(2)) // 2 - Z11_FILIAL, Z11_ETIQUE, Z11_CLIENT, Z11_LOJA
					If ( ! Z11->(dbSeek( xFilial("Z11") + _cEtqClient + mv_par01 + mv_par02 )))
						// mensagem de aviso
						MsgStop("Erro Z11 ## Etiq Cliente não localizada -" + _cEtqClient)
						// Loop
						Loop
					EndIf

				EndIf

				// adiciona os dados do palete
				aAdd(_aEstPalete,{;
				_cEtqVolume     ,;
				_cCodProd       ,;
				_nQtdInvent     ,;
				SBE->BE_LOCAL   ,;
				SBE->BE_LOCALIZ ,;
				_cTpEmbala      ,;
				_cTpEstoque     ,;
				_cCodBar        ,;
				_cLote          ,;
				_nQtdSegum      ,;
				_cEtqClient     })

				// totaliza por produto
				_nPosSaldo := aScan(_aSaldoProd,{|x| (x[1] == _cCodProd) .And. (x[3] == _cLote) })

				// atualiza saldo
				If (_nPosSaldo > 0)
					_aSaldoProd[_nPosSaldo][2] += _nQtdInvent
					_aSaldoProd[_nPosSaldo][4] += _nQtdSegum
				Else
					aAdd(_aSaldoProd, {_cCodProd, _nQtdInvent, _cLote, _nQtdSegum} )
				EndIf

			Next _nItemZ19

			// se estiver OK, gera o palete
			If ( ! _lDiverg ) .And. (Len(_aEstPalete) > 0)

				// inicia transacao especifica por endereco
				BEGIN TRANSACTION

					// gera Id do palete
					_cIdPalete := U_FtGrvEtq("03", {_cUnitPdr,""})
					// define o codigo do unitizador
					_cCodUnit := Z11->Z11_UNITIZ

					// gera Z16
					For _nZ16 := 1 to Len(_aEstPalete)

						// grava a estutura do palete
						dbSelectArea("Z16")
						RecLock("Z16", .T.)
						Z16->Z16_FILIAL := xFilial("Z16")
						Z16->Z16_ETQPAL := _cIdPalete
						Z16->Z16_UNITIZ := _cCodUnit
						Z16->Z16_ETQPRD := ""
						Z16->Z16_CODPRO := _aEstPalete[_nZ16][2]
						Z16->Z16_QUANT  := _aEstPalete[_nZ16][3]
						Z16->Z16_NUMSEQ := sfRetNumSeq( _aEstPalete[_nZ16][2] )
						Z16->Z16_STATUS := ""
						Z16->Z16_QTDVOL := _aEstPalete[_nZ16][3]
						Z16->Z16_LOCAL  := _aEstPalete[_nZ16][4]
						Z16->Z16_ENDATU := _aEstPalete[_nZ16][5]
						Z16->Z16_SALDO  := _aEstPalete[_nZ16][3]
						Z16->Z16_ORIGEM := "Z19"
						Z16->Z16_EMBALA := _aEstPalete[_nZ16][6]
						Z16->Z16_TPESTO := _aEstPalete[_nZ16][7]
						Z16->Z16_ETQVOL := _aEstPalete[_nZ16][1]
						Z16->Z16_DATA   := dDataBase
						Z16->Z16_HORA   := Time()
						Z16->Z16_CODBAR := _aEstPalete[_nZ16][8]
						Z16->Z16_LOTCTL := _aEstPalete[_nZ16][9]
						Z16->Z16_VLDLOT := CtoD("31/12/2049")
						Z16->Z16_QTSEGU := _aEstPalete[_nZ16][10]
						Z16->Z16_ETQCLI := _aEstPalete[_nZ16][11]
						Z16->(MsUnLock())

					Next _nZ16

					For _nSBF := 1 to Len(_aSaldoProd)

						// inclui saldo inicial por lote
						If (_lGeraSBJ)

							// codigo do produto
							_cCodProd := PadR(_aSaldoProd[_nSBF][1], TamSx3("B1_COD")[1])

							// lote
							_cLote    := PadR(_aSaldoProd[_nSBF][3], TamSx3("B8_LOTECTL")[1])

							dbSelectArea("SBJ")
							SBJ->(dbSetOrder(1)) // 1-BJ_FILIAL, BJ_COD, BJ_LOCAL, BJ_LOTECTL, BJ_NUMLOTE, BJ_DATA
							If SBJ->(dbSeek( xFilial("SBJ") + _cCodProd + SBE->BE_LOCAL + _cLote ))
								RecLock("SBJ")
								SBJ->BJ_QINI    += _aSaldoProd[_nSBF][2]
								SBJ->BJ_QISEGUM += _aSaldoProd[_nSBF][4]
								SBJ->(MsUnLock())
							Else
								RecLock("SBJ",.t.)
								SBJ->BJ_FILIAL  := xFilial("SBJ")
								SBJ->BJ_COD     := _cCodProd
								SBJ->BJ_LOCAL   := SBE->BE_LOCAL
								SBJ->BJ_LOTECTL := _cLote
								SBJ->BJ_DATA    := dDataBase
								SBJ->BJ_DTVALID := CtoD("31/12/2049")
								SBJ->BJ_QINI    := _aSaldoProd[_nSBF][2]
								SBJ->BJ_QISEGUM := _aSaldoProd[_nSBF][4]
								SBJ->(MsUnLock())
							EndIf
						EndIf

						// Obtem numero sequencial do movimento
						_cNumSeq  := ProxNum()
						// Numero do Item do Movimento
						_cCounter := StrZero(1, TamSx3('DB_ITEM')[1])

						// Cria registro de movimentacao por Localizacao (SDB)           ³
						CriaSDB(;
						_aSaldoProd[_nSBF][1],;	 // Produto
						SBE->BE_LOCAL,;          // Armazem
						_aSaldoProd[_nSBF][2],;  // Quantidade
						SBE->BE_LOCALIZ,;        // Localizacao
						"",;                     // Numero de Serie
						"",;                     // Doc
						"",;                     // Serie
						"",;                     // Cliente / Fornecedor
						"",;                     // Loja
						"",;                     // Tipo NF
						"ACE",;                  // Origem do Movimento
						dDataBase,;              // Data
						_aSaldoProd[_nSBF][3],;  // Lote
						"",;                     // Sub-Lote
						_cNumSeq,;               // Numero Sequencial
						"499",;                  // Tipo do Movimento
						"M",;                    // Tipo do Movimento (Distribuicao/Movimento)
						_cCounter,;              // Item
						.F.,;                    // Flag que indica se e' mov. estorno
						0,;                      // Quantidade empenhado
						_aSaldoProd[_nSBF][4] )  // Quantidade segunda UM

						//³Soma saldo em estoque por localizacao fisica (SBF)            ³
						GravaSBF("SDB")

						// log de processamento
						_cEndAtual += "End: "+AllTrim(SBE->BE_LOCALIZ)
						_cEndAtual += " / Prod "+AllTrim(_aSaldoProd[_nSBF][1])
						_cEndAtual += " / Quant "+AllTrim(Str(_aSaldoProd[_nSBF][2]))
						_cEndAtual += " / Lote "+AllTrim(_aSaldoProd[_nSBF][3])
						_cEndAtual += CRLF

					Next _nSBF

					// finaliza transacao especifica por endereco
				END TRANSACTION

			EndIf

		EndIf

	Next _nRecnoSBE

	// enderecos bloqueados
	If ( ! Empty(_cEndBloq))
		_cLog += CRLF
		_cLog += ">> ENDEREÇOS BLOQUEADOS"+CRLF
		_cLog += _cEndBloq
	EndIf

	// enderecos com produtos duplicados
	If ( ! Empty(_cEndVazio))
		_cLog += CRLF
		_cLog += ">> ENDEREÇOS VAZIOS - "+AllTrim(Str(_nEndVazio))+CRLF
		_cLog += _cEndVazio
	EndIf

	// enderecos com produtos duplicads
	If ( ! Empty(_cProdNorm))
		_cLog += CRLF
		_cLog += ">> PRODUTOS SEM LASTRO E CAMADA"+CRLF
		_cLog += _cProdNorm
	EndIf

	// saldo do endereco diferente da norma
	If ( ! Empty(_cSaldoNor))
		_cLog += CRLF
		_cLog += ">> SALDO NO ENDEREÇO DIFERENTE DA NORMA"+CRLF
		_cLog += _cSaldoNor
	EndIf

	// saldo atualizado
	If ( ! Empty(_cEndAtual))
		_cLog += CRLF
		_cLog += ">> SALDO ATUALIZADO CORRETAMENTE"+CRLF
		_cLog += _cEndAtual
	EndIf

	// grava o arquivo de log
	MemoWrit("c:\TEMP\log_inventario_"+mv_par05+"_"+_cLadoRua+".log",_cLog)

	MsgInfo("Ok")

Return

// ** fechamento de inventario para cliente com controle de lotes, realizado em blocado
Static Function sfFecLotBlc()

	// controle de divergencias
	local _lDiverg := .f.

	// recno SBE
	local _aRecnoSBE := {}
	local _nRecnoSBE := 0

	// recno Z19
	local _aDadosZ19 := {}
	local _nItemZ19 := 0

	// arquivo de log
	local _cEndBloq  := ""
	local _cEndVazio := ""
	local _nEndVazio := 0
	local _cProdNorm := ""
	local _cSaldoNor := ""
	local _cEndAtual := ""
	local _cLog := ""

	// codigo do produto
	local _cCodProd := ""
	// etiqueta de produto
	local _cEtqProduto := ""
	// quantidade inventariada
	local _nQtdInvent := 0
	local _nQtdSegum  := 0
	// lote
	local _cLoteCtl := ""
	local _dVldLote := CtoD("//")
	// num seq origem
	local _cNrSqOrig := ""

	// querys
	local _cQrySBE
	local _cQryZ19
	local _cQryZ06

	// dados do palete
	local _cIdPalete  := ""
	local _cCodUnit   := ""
	local _aEstPalete := {}
	local _aSaldoProd := {}
	local _nPosSaldo  := 0

	// codigo do unitizador padrao
	local _cUnitPdr := SuperGetMV('TC_PLTPADR', .F., "000001")

	// controle de palete com etiqueta parcial
	local _aTmpConteudo := {}
	local _cCodEtiq := ""

	// posicao dos campos
	local _nPosLocal  := 1
	local _nPosEnder  := 2
	local _nPosEtqPro := 3
	local _nPosCodPro := 4
	local _nPosQuant  := 5
	local _nPosLote   := 6
	local _nPosVldLot := 7
	local _nPosEtqVol := 8
	local _nPosTpEmb  := 9
	local _nPosTpEst  := 10
	local _nPosCodBar := 11
	local _nPosQtdSeg := 12

	// Obtem numero sequencial do movimento
	Local _cNumSeq := ""
	// Numero do Item do Movimento
	Local _cCounter	:= ""

	// etiqueta de volume
	local _cEtqVolume := ""

	// tipo da embalagem
	local _cTipoEmb := ""

	// tipo de estoque
	local _cTpEstoq := ""

	// codigo de barras
	local _cCodBar := ""

	// gera saldo inicial por lote
	local _lGeraSBJ := .f.

	// query das OS em aberto
	_cQryZ06 := " SELECT Z05_NUMOS "
	// ordem de servico
	_cQryZ06 += " FROM   " + RetSqlTab("Z05") + " (nolock) "
	_cQryZ06 += "        INNER JOIN " + RetSqlTab("Z06") + " (nolock) "
	_cQryZ06 += "                ON " + RetSqlCond("Z06")
	_cQryZ06 += "                   AND Z06_NUMOS = Z05_NUMOS "
	_cQryZ06 += "                   AND Z06_STATUS <> 'FI' "
	_cQryZ06 += "                   AND Z06_SERVIC = 'T02' "
	// filtro padrao
	_cQryZ06 += " WHERE  " + RetSqlCond("Z05")
	// cliente
	_cQryZ06 += "        AND Z05_CLIENT = '" + mv_par01 + "' "
	_cQryZ06 += "        AND Z05_LOJA = '" + mv_par02 + "' "
	// ordens de servico
	_cQryZ06 += "        AND Z05_NUMOS BETWEEN '" + mv_par08 + "' AND '" + mv_par09 + "' "


	// filtra todos os enderecos conforme parametros
	_cQrySBE := " SELECT SBE.R_E_C_N_O_ SBERECNO "
	// cad. enderecos
	_cQrySBE += " FROM   "+RetSqlTab("SBE")+" (nolock) "
	// filtro padrao
	_cQrySBE += " WHERE  "+RetSqlCond("SBE")

	// filtro de armazem
	_cQrySBE += "        AND BE_LOCAL = '"+mv_par04+"' "

	// filtra somente um endereco
	_cQrySBE += "        AND BE_LOCALIZ = '"+mv_par07+"' "

	// ordem dos dados
	_cQrySBE += "ORDER BY BE_LOCALIZ "

	memowrit("c:\query\twmsxfu2_cad_endereco.txt",_cQrySBE)

	// joga os dados para o vetor
	_aRecnoSBE := U_SqlToVet(_cQrySBE)

	For _nRecnoSBE := 1 to Len(_aRecnoSBE)

		// posiciona no registro real da tabela
		dbSelectArea("SBE")
		SBE->(dbGoTo( _aRecnoSBE[_nRecnoSBE] ))

		// marca divergencia
		_lDiverg := .f.

		// verifica se o endereco esta bloqueado
		If (SBE->BE_STATUS == "3")
			_cEndBloq += SBE->BE_LOCALIZ
			_cEndBloq += CRLF

		ElseIf (SBE->BE_STATUS != "3")

			// -- verifica se houve inventario
			_cQryZ19 := " SELECT Z19_LOCAL, "
			_cQryZ19 += "        Z19_ENDERE, "
			_cQryZ19 += "        Z19_ETQPRO, "
			_cQryZ19 += "        Z19_CODPRO, "
			_cQryZ19 += "        Z19_QUANT, "
			_cQryZ19 += "        Z19_LOTCTL, "
			_cQryZ19 += "        Z19_VLDLOT, "
			_cQryZ19 += "        Z19_ETQVOL, "
			_cQryZ19 += "        Z19_TPEMBA, "
			_cQryZ19 += "        Z19_TPESTO, "
			_cQryZ19 += "        Z19_CODEAN, "
			_cQryZ19 += "        Z19_QTSEGU "
			// itens inventariados
			_cQryZ19 += " FROM   "+RetSqlTab("Z19")+" (nolock) "
			// composicao do palete
			_cQryZ19 += " LEFT JOIN "+RetSqlTab("Z16")+" WITH(INDEX("+RetSqlName("Z16")+"_ENDATU), NOLOCK) "
			_cQryZ19 += "              ON "+RetSqlCond("Z16")
			// etiqueta de produto
			_cQryZ19 += "                 AND Z16_ETQPRD = Z19_ETQPRO "
			// etiqueta de volume
			_cQryZ19 += "                 AND Z16_ETQVOL = Z19_ETQVOL "
			// endereco
			_cQryZ19 += "                 AND Z16_ENDATU = Z19_ENDERE "
			// filtro padrao
			_cQryZ19 += " WHERE  "+RetSqlCond("Z19")
			// somente relacionado a ordens de servico
			_cQryZ19 += "        AND Z19_IDENT IN ("+_cQryZ06+") "
			// armazem
			_cQryZ19 += "        AND Z19_LOCAL  = '"+SBE->BE_LOCAL+"' "
			//endereco
			_cQryZ19 += "        AND Z19_ENDERE = '"+SBE->BE_LOCALIZ+"' "
			// que tenha produto
			_cQryZ19 += "        AND Z19_CODPRO <> ' ' "
			// somente os que nao tem palete gerado
			_cQryZ19 += "        AND Z16_ETQPAL IS NULL "
			// ordem dos dados
			_cQryZ19 += " ORDER  BY Z19_ETQPRO, "
			_cQryZ19 += "           Z19_CODPRO "

			memowrit("c:\query\twmsxfu2_inventario_endereco.txt",_cQryZ19)

			// joga os dados para o vetor
			_aDadosZ19 := U_SqlToVet(_cQryZ19,{"Z19_VLDLOT"})

			// verifica se ha dados
			If (Len(_aDadosZ19) == 0)
				// marca divergencia
				_lDiverg := .t.
				// gera o log
				_cEndVazio += SBE->BE_LOCALIZ
				_cEndVazio += CRLF
				// quantidade
				_nEndVazio ++
				// loop
				Loop
			EndIf

			// varre todos os itens inventariados
			For _nItemZ19 := 1 to Len(_aDadosZ19)

				// dados do palete
				_cIdPalete  := ""
				_cCodUnit   := ""

				// define o codigo do produto
				_cCodProd    := _aDadosZ19[_nItemZ19][_nPosCodPro]

				// etiqueta de produto
				_cEtqProduto := _aDadosZ19[_nItemZ19][_nPosEtqPro]

				// quantidade saldo inventariado
				_nQtdInvent  := _aDadosZ19[_nItemZ19][_nPosQuant]

				// lote conferido
				_cLoteCtl    := _aDadosZ19[_nItemZ19][_nPosLote]

				// validade do lote
				_dVldLote    := _aDadosZ19[_nItemZ19][_nPosVldLot]

				// etiqueta de volume
				_cEtqVolume  := _aDadosZ19[_nItemZ19][_nPosEtqVol]

				// tipo da embalagem
				_cTipoEmb    := _aDadosZ19[_nItemZ19][_nPosTpEmb]

				// tipo de estoque
				_cTpEstoq    := _aDadosZ19[_nItemZ19][_nPosTpEst]

				// codigo de barras
				_cCodBar     := _aDadosZ19[_nItemZ19][_nPosCodBar]

				// segunda unidade de medida
				_nQtdSegum   := _aDadosZ19[_nItemZ19][_nPosQtdSeg]



				// verifica se existe etiqueta de PRODUTO
				If ( ! Empty(_cEtqProduto) )
					dbSelectArea("Z11")
					Z11->(dbSetOrder(1)) // 1-Z11_FILIAL, Z11_CODETI
					If ( ! Z11->(dbSeek( xFilial("Z11")+_cEtqProduto )))
						MsgStop("Erro Z11 ## Eti Produto Não Encontrada " + _cEtqProduto)
						Loop
					EndIf

					// valida o tipo da etiqueta
					If (Z11->Z11_TIPO != "01")
						MsgStop("Erro Z11 ## Eti Produto com tipo errado" + _cEtqProduto)
						Loop
					EndIf
				EndIf

				// verifica se existe etiqueta de VOLUME
				If ( ! Empty(_cEtqVolume) )
					dbSelectArea("Z11")
					Z11->(dbSetOrder(1)) // 1-Z11_FILIAL, Z11_CODETI
					If ( ! Z11->(dbSeek( xFilial("Z11")+_cEtqVolume )))
						MsgStop("Erro Z11 ## Eti Volume Não Encontrada " + _cEtqVolume)
						Loop
					EndIf

					// valida o tipo da etiqueta
					If (Z11->Z11_TIPO != "04")
						MsgStop("Erro Z11 ## Eti Volume com tipo errado" + _cEtqVolume)
						Loop
					EndIf
				EndIf

				// num seq da origem
				_cNrSqOrig := Z11->Z11_NUMSEQ

				// inicia transacao especifica por endereco
				BEGIN TRANSACTION

					// gera Id do palete
					_cIdPalete := U_FtGrvEtq("03",{_cUnitPdr,""})
					// define o codigo do unitizador
					_cCodUnit := Z11->Z11_UNITIZ

					// grava a estutura do palete
					dbSelectArea("Z16")
					RecLock("Z16",.t.)
					Z16->Z16_FILIAL := xFilial("Z16")
					Z16->Z16_ETQPAL := _cIdPalete
					Z16->Z16_UNITIZ := _cCodUnit
					Z16->Z16_ETQPRD := _cEtqProduto
					Z16->Z16_CODPRO := _cCodProd
					Z16->Z16_QUANT  := _nQtdInvent
					Z16->Z16_NUMSEQ := _cNrSqOrig
					Z16->Z16_STATUS := "P"
					Z16->Z16_QTDVOL := 0
					Z16->Z16_ENDATU := SBE->BE_LOCALIZ
					Z16->Z16_SALDO  := _nQtdInvent
					Z16->Z16_ORIGEM := "Z19"
					Z16->Z16_PLTORI := ""
					Z16->Z16_LOCAL  := SBE->BE_LOCAL
					Z16->Z16_EMBALA := _cTipoEmb
					Z16->Z16_TPESTO := _cTpEstoq
					Z16->Z16_CODBAR := _cCodBar
					Z16->Z16_ETQVOL := _cEtqVolume
					Z16->Z16_DATA   := Date()
					Z16->Z16_HORA   := Time()
					Z16->Z16_LOTCTL := _cLoteCtl
					Z16->Z16_VLDLOT := _dVldLote
					Z16->Z16_QTSEGU := _nQtdSegum
					Z16->(MsUnLock())

					// inclui saldo inicial por lote
					If (_lGeraSBJ)

						// codigo do produto
						_cCodProd := PadR(_aSaldoProd[_nSBF][1], TamSx3("B1_COD")[1])

						// lote
						_cLoteCtl := PadR(_aSaldoProd[_nSBF][3], TamSx3("B8_LOTECTL")[1])

						dbSelectArea("SBJ")
						SBJ->(dbSetOrder(1)) // 1-BJ_FILIAL, BJ_COD, BJ_LOCAL, BJ_LOTECTL, BJ_NUMLOTE, BJ_DATA
						If SBJ->(dbSeek( xFilial("SBJ") + _cCodProd + SBE->BE_LOCAL + _cLoteCtl ))
							RecLock("SBJ")
							SBJ->BJ_QINI    += _aSaldoProd[_nSBF][2]
							SBJ->BJ_QISEGUM += _aSaldoProd[_nSBF][4]
							SBJ->(MsUnLock())
						Else
							RecLock("SBJ",.t.)
							SBJ->BJ_FILIAL  := xFilial("SBJ")
							SBJ->BJ_COD     := _cCodProd
							SBJ->BJ_LOCAL   := SBE->BE_LOCAL
							SBJ->BJ_LOTECTL := _cLoteCtl
							SBJ->BJ_DATA    := dDataBase
							SBJ->BJ_DTVALID := _dVldLote
							SBJ->BJ_QINI    := _aSaldoProd[_nSBF][2]
							SBJ->BJ_QISEGUM := _aSaldoProd[_nSBF][4]
							SBJ->(MsUnLock())
						EndIf

					EndIf

					// Obtem numero sequencial do movimento
					_cNumSeq  := ProxNum()
					// Numero do Item do Movimento
					_cCounter := StrZero(1,TamSx3('DB_ITEM')[1])

					// Cria registro de movimentacao por Localizacao (SDB)
					CriaSDB(;
					_cCodProd,;              // Produto
					SBE->BE_LOCAL,;          // Armazem
					_nQtdInvent,;            // Quantidade
					SBE->BE_LOCALIZ,;        // Localizacao
					"",;                     // Numero de Serie
					"",;                     // Doc
					"",;                     // Serie
					"",;                     // Cliente / Fornecedor
					"",;                     // Loja
					"",;                     // Tipo NF
					"ACE",;                  // Origem do Movimento
					dDataBase,;              // Data
					_cLoteCtl,;              // Lote
					"",;                     // Sub-Lote
					_cNumSeq,;               // Numero Sequencial
					"499",;                  // Tipo do Movimento
					"M",;                    // Tipo do Movimento (Distribuicao/Movimento)
					_cCounter,;              // Item
					.F.,;                    // Flag que indica se e' mov. estorno
					0,;                      // Quantidade empenhado
					_nQtdSegum )             // Quantidade segunda UM

					// Soma saldo em estoque por localizacao fisica (SBF)
					GravaSBF("SDB")

					_cEndAtual += "End: "+AllTrim(SDB->DB_LOCALIZ)
					_cEndAtual += " / Prod "+AllTrim(SDB->DB_PRODUTO)
					_cEndAtual += " / Quant "+AllTrim(Str(SDB->DB_QUANT))
					_cEndAtual += " / Lote "+AllTrim(SDB->DB_LOTECTL)
					If (_nQtdSegum != 0)
						_cEndAtual += " / Quant Seg UM "+AllTrim(Str(SDB->DB_QTSEGUM))
					EndIf
					_cEndAtual += CRLF

					// finaliza transacao especifica por endereco
				END TRANSACTION

			Next _nItemZ19

		EndIf

	Next _nRecnoSBE

	// enderecos bloqueados
	If ( ! Empty(_cEndBloq))
		_cLog += CRLF
		_cLog += ">> ENDEREÇOS BLOQUEADOS"+CRLF
		_cLog += _cEndBloq
	EndIf

	// enderecos com produtos duplicados
	If ( ! Empty(_cEndVazio))
		_cLog += CRLF
		_cLog += ">> ENDEREÇOS VAZIOS - "+AllTrim(Str(_nEndVazio))+CRLF
		_cLog += _cEndVazio
	EndIf

	// enderecos com produtos duplicads
	If ( ! Empty(_cProdNorm))
		_cLog += CRLF
		_cLog += ">> PRODUTOS SEM LASTRO E CAMADA"+CRLF
		_cLog += _cProdNorm
	EndIf

	// saldo do endereco diferente da norma
	If ( ! Empty(_cSaldoNor))
		_cLog += CRLF
		_cLog += ">> SALDO NO ENDEREÇO DIFERENTE DA NORMA"+CRLF
		_cLog += _cSaldoNor
	EndIf

	// saldo atualizado
	If ( ! Empty(_cEndAtual))
		_cLog += CRLF
		_cLog += ">> SALDO ATUALIZADO CORRETAMENTE"+CRLF
		_cLog += _cEndAtual
	EndIf

	// grava o arquivo de log
	MemoWrit("c:\TEMP\log_inventario_"+AllTrim(mv_par07)+".log",_cLog)

	MsgInfo("Fechamento Endereço "+AllTrim(mv_par07)+" Ok")

Return

// ** funcao generica para geracao de enderecos porta pallet em massa
User Function FtGeraEnd()

	local _cPerg := PadR("FTGERAEND",10)
	local _vPerg := {}

	// armazem/local
	local _cArmazem := ""
	// rua
	local _nRua
	local _cRua
	// lado
	local _cLado
	local _nLado
	local _nLadIni
	local _nLadFim

	// predio
	local _nPredio := 0
	local _nMaxPredio := 0
	// colunas do predio
	local _nColPre := 1
	local _nMaxColPre := 2
	// andares
	local _nAndar := 1
	local _nMaxAndar := 0
	// posicao
	local _cPosicao := ""
	// variavel temporaria
	local _cTmpEnder := ""
	// status
	local _cStatus := ""
	// quantidade de enderecos gerados
	local _nQtdGerado := 0

	// controle de seta
	local _nSeta := 0
	local _cSeta := ""

	// controle de picking
	local _nPicking := 2
	local _cEstFis := ""

	// funcao que monta os dados do operador logado no sistema
	local _aUsrInfo := U_FtWmsOpe()

	// codigo do Operador
	Private _lUsrAccou  := (_aUsrInfo[2]=="A")
	Private _lUsrColet	:= (_aUsrInfo[2]=="C")
	Private _lUsrSuper	:= (_aUsrInfo[2]=="S")
	Private _lUsrGeren  := (_aUsrInfo[2]=="G")
	Private _lUsrMonit  := (_aUsrInfo[2]=="M")

	// valida se eh supervisor, account ou gerente
	If ( ! _lUsrGeren ) 
		// mensagem
		MsgStop("Apenas Gerente pode utilizar esta Rotina" , "FtGeraEnd")
		// retorno
		Return
	EndIf

	// define o grupo de perguntas
	aAdd(_vPerg,{"Armazém"          ,"C"	,TamSx3("BE_LOCAL")[1]		,0	,"G",							,"Z12"}) 	//mv_par01
	aAdd(_vPerg,{"Rua Inicial"      ,"C"	,2							,0	,"G",							,""}) 		//mv_par02
	aAdd(_vPerg,{"Lado"             ,"N"	,1							,0	,"C",{"A","B","Ambos"}			,""}) 		//mv_par03
	aAdd(_vPerg,{"Prédio Inicial"   ,"C"	,2							,0	,"G",							,""}) 		//mv_par04
	aAdd(_vPerg,{"Status Inicial"   ,"N"	,1							,0	,"C",{"Desocupado","Bloqueado"}	,""}) 		//mv_par05
	aAdd(_vPerg,{"Prédio Até"       ,"C"	,2							,0	,"G",							,""}) 		//mv_par06
	aAdd(_vPerg,{"Quant. de Ruas"   ,"N"	,2							,0	,"G",							,""}) 		//mv_par07
	aAdd(_vPerg,{"Quant. de Andares","N"	,2							,0	,"G",							,""}) 		//mv_par08
	aAdd(_vPerg,{"Zona armazenagem" ,"C"	,TamSx3("BE_CODZON")[1]		,0	,"G",							,"DC4"}) 	//mv_par09
	aAdd(_vPerg,{"Estrutura Física" ,"C"	,TamSx3("BE_ESTFIS")[1]		,0	,"G",							,"DC8"}) 	//mv_par10
	aAdd(_vPerg,{"Configuração"     ,"C"	,TamSx3("BE_CODCFG")[1]		,0	,"G",							,"DC7"}) 	//mv_par11
	aAdd(_vPerg,{"Qtd Col Prédio"   ,"N"	,2							,0	,"G",							,""}) 		//mv_par12
	aAdd(_vPerg,{"Seta Inicial"     ,"N"	,1							,0	,"C",{"Direita","Esquerda"}	    ,""}) 		//mv_par13
	aAdd(_vPerg,{"Utiliza picking"  ,"N"	,1							,0	,"C",{"Sim","Não"}	            ,""}) 		//mv_par14

	// cria grupo de perguntas
	U_FtCriaSX1(_cPerg, _vPerg)

	// cria os parametros mv_par, para substituir a data até pela database
	If ! Pergunte(_cPerg, .T. )
		Return
	EndIf

	// valida codigos de configuracao
	If ( (Empty(mv_par09)) .Or. (Empty(mv_par10)) .Or. (Empty(mv_par11)) )
		MsgSTop("Códigos de configuração devem ser informados")
		Return ( .F. )
	EndIf

	// valida quantida de ruas
	If (MV_PAR07 == 0 .OR. Empty(MV_PAR07))
		MsgSTop("Quantidade de ruas deve ser maior que 0")
		Return( .F. )
	EndIf

	// define quantidade de andares
	_nMaxAndar := mv_par08

	// gera enderecos para todos os predios da rua
	For _nRua := Val(mv_par02) to ((Val(mv_par02) + mv_par07) - 1)

		_nLadIni := IIf(mv_par03 == 3, 1, mv_par03)
		_nLadFim := IIf(mv_par03 == 3, 2, mv_par03)

		For _nLado := _nLadIni to _nLadFim

			// define as variaveis
			_cArmazem	:= mv_par01
			_cRua		:= StrZero(_nRua,2)
			_cLado		:= IIf(_nLado==1, "A", "B")
			_nMaxPredio	:= Val(mv_par06)    //Quantidade maxima de predios a ser gerada.
			_cStatus	:= IIf(mv_par05==1, "1", "3")
			_nMaxColPre := mv_par12

			// busca a ultima posicao
			_cPosicao := sfRetMaxPos(_cArmazem)
			cPredio:= mv_par04

			For _nPredio := 1 to _nMaxPredio

				For _nColPre := 1 to _nMaxColPre

					// varre todos os andares da rua
					For _nAndar := 1 to _nMaxAndar

						// reinicia valor das variaveis
						_cSeta := ""
						_cEstFis := mv_par10

						// verifica se o é primeiro andar
						If (StrZero(_nAndar,2) == "01")
							// verifica se chegou ao fim do controle de seta
							If (_nSeta <= 1)
								Do Case
									// caso esteja passando a primeira vez da sequencia gerada
									Case _nSeta == 0
									// atribui o valor da seta inicial selecionado
									_cSeta := Iif(mv_par13 == 1,"D","E")
									// incrementa o cotrole para proxima iteração
									_nSeta := 1
									// caso esteja passando pela segunda vez da sequencia gerada	
									Case _nSeta == 1
									// atribui o valor inverso da seta inicial selecionado
									_cSeta := Iif(mv_par13 == 1,"E","D")
									// decrementa o controle para próxima iteração da próxima sequencia a ser gerada 
									_nSeta := 0
								Endcase
							Endif

							// Se utiliza picking
							If (mv_par14 == 1)
								// atribui aos endereços do 1 andar a estrutura de picking
								_cEstFis := "000010"
							Endif
						Endif

						// cria o codigo do endereco
						_cTmpEnder := _cRua               // RUA
						_cTmpEnder += _cLado              // LADO
						_cTmpEnder += cPredio             // PREDIO
						_cTmpEnder += StrZero(_nAndar,2)  // ANDAR
						_cTmpEnder += _cPosicao           // POSICAO

						dbSelectArea("SBE")
						RecLock("SBE",.t.)
						SBE->BE_FILIAL	:= xFilial("SBE")
						SBE->BE_LOCAL	:= _cArmazem
						SBE->BE_LOCALIZ	:= _cTmpEnder
						SBE->BE_DESCRIC	:= _cTmpEnder
						SBE->BE_PRIOR	:= "ZZZ"
						SBE->BE_CODZON	:= mv_par09
						SBE->BE_STATUS	:= _cStatus
						SBE->BE_ESTFIS	:= _cEstFis
						SBE->BE_CODCFG	:= mv_par11
						SBE->BE_CAPACID := 3000
						SBE->BE_ALTURLC := 1.80
						SBE->BE_LARGLC  := 1.20
						SBE->BE_COMPRLC := 1.20
						SBE->BE_DATGER  := Date()
						SBE->BE_HORGER  := Time()
						SBE->BE_ZSETA   := Iif(StrZero(_nAndar,2) == "01",_cSeta,"")
						SBE->(MsUnLock())

						// proxima posicao
						_cPosicao := Soma1(_cPosicao)

						// controle de quantidade gerado
						_nQtdGerado ++

					Next _nAndar

				Next _nColPre

				cPredio := Soma1(cPredio)
			Next _nPredio

		Next _nLado

	Next _nRua

	MsgInfo(AllTrim(Str(_nQtdGerado))+" endereços gerados!")

Return

// função para gerar endereços blocados em massa
User Function FtGeraBloc()

	LOCAL aSays     := {}
	LOCAL aButtons  := {}
	LOCAL cPerg     := "ENDBLOCO"
	LOCAL cCadastro := "Processamento de Endereços Bloco."
	
	// funcao que monta os dados do operador logado no sistema
	local _aUsrInfo := U_FtWmsOpe()
	
	// codigo do Operador
	Private _lUsrAccou  := (_aUsrInfo[2]=="A")
	Private _lUsrColet	:= (_aUsrInfo[2]=="C")
	Private _lUsrSuper	:= (_aUsrInfo[2]=="S")
	Private _lUsrGeren  := (_aUsrInfo[2]=="G")
	Private _lUsrMonit  := (_aUsrInfo[2]=="M")

	// valida se eh supervisor, account ou gerente
	If ( ! _lUsrGeren ) 
		// mensagem
		MsgStop("Apenas Gerente pode utilizar esta Rotina" , "FtGeraBloc")
		// retorno
		Return
	EndIf

	Pergunte(cPerg,.F.)

	aadd(aSays,"Esta rotina tem como finalidade gerar Endereços de Blocos em massa.")

	aadd(aButtons, { 1,.T.,{|| Processa({|| fGrBloco()},"Processamento","Geração de Blocos em Massa..."),FechaBatch() }} )
	aadd(aButtons, { 2,.T.,{|| FechaBatch() }} )
	aadd(aButtons, { 5,.T.,{|| Pergunte(cPerg,.T. ) } } )

	FormBatch( cCadastro, aSays, aButtons,, 160 )

Return

/*/{Protheus.doc} fGrBloco
Função auxiliar de processamento, para geração de endereços Bloco.
@type function
@author Luiz Fernando
@since 28/06/2019
/*/
Static Function fGrBloco()

	LOCAL cQuery := ""
	LOCAL cBloco := ""
	LOCAL cSeq   := ""
	LOCAL cPrefix:= "BLOCO"
	LOCAL nQtde  := MV_PAR04
	LOCAL nFor   := 0
	LOCAL cMsg1             := ""
	LOCAL aStruct   		:= {}
	cMsg1+= chr(13)+chr(10)
	cMsg1+= "fGrBloco"	
	cMsg1+= chr(13)+chr(10)
	cMsg1+= (" Usuario=["+cUsername+"] Computador=["+GetComputerName()+"]")
	cMsg1+= (" IP=["+Getclientip()+"]")
	cMsg1+= (" Thread=["+cValToChar(ThreadId())+"]")
	cMsg1+= chr(13)+chr(10)

	DBSelectArea("SBE")
	aStruct:= SBE->(DbStruct())

	If !ExistCpo("Z12",MV_PAR01 )
		Alert("Armazém informado é inválido.")
		return
	EndIf
	If !ExistCpo("DC4",MV_PAR02 )
		Alert("Zona de Armazenagem é inválida.")
		return
	EndIf
	If !ExistCpo("DC7",MV_PAR03 )
		Alert("Configuração de endereço é inválida.")
		return
	EndIf

	cQuery := "SELECT MAX(SUBSTRING(BE_LOCALIZ,1,8)) AS ULTIMOBLOCO" 
	cQuery += " FROM "+RetSQLName("SBE")+ " SBE "
	cQuery += " WHERE "
	cQuery += " BE_FILIAL = '"+xFilial("SBE")+"'"
	cQuery += " AND BE_LOCAL = '"+MV_PAR01+"'"
	cQuery += " AND BE_ESTFIS = '000007' "
	cQuery += " AND SUBSTRING(BE_LOCALIZ,1,5) = 'BLOCO' "
	cQuery += " AND LEN(BE_LOCALIZ) = '8' "
	cQuery += " AND SBE.D_E_L_E_T_ <> '*'"
	cMsg1+= "[cQuery] "+chr(13)+chr(10)
	cMsg1+= cQuery+ chr(13)+chr(10)
	If Select("TRBSBE") <> 0
		DBSelectArea("TRBSBE")
		DBCloseArea()
	EndIf
	TCQuery cQuery New Alias "TRBSBE"
	If !TRBSBE->(Eof())
		cBloco:= AllTrim(StrTran(TRBSBE->ULTIMOBLOCO,cPrefix,""))
	EndIF
	If Select("TRBSBE") <> 0
		DBSelectArea("TRBSBE")
		DBCloseArea()
	EndIf
	If Empty(cBloco)
		cBloco := "000"
	EndIf
	cMsg1+= "[cBloco INI ] "+cBloco+chr(13)+chr(10)
	cMsg1+= "[nQtde] "+cValToChar(nQtde)+chr(13)+chr(10)
	ProcRegua(nQtde)

	Begin Transaction

		For nFor:= 1 To nQtde
			IncProc()
			cBloco := Soma1(cBloco)

			RecLock("SBE",.T.)
			SBE->BE_FILIAL	:= xFilial("SBE")
			SBE->BE_LOCAL	:= MV_PAR01 
			SBE->BE_LOCALIZ	:= cPrefix+cBloco 
			SBE->BE_DESCRIC	:= cPrefix+cBloco
			SBE->BE_PRIOR	:= "ZZZ"
			SBE->BE_CODZON	:= MV_PAR02
			SBE->BE_STATUS	:= IIf(mv_par05==1, "1", "3")
			SBE->BE_ESTFIS	:= '000007'
			SBE->BE_CODCFG	:= MV_PAR03
			SBE->BE_CAPACID := 3000
			SBE->BE_ALTURLC := 1.80
			SBE->BE_LARGLC  := 1.20
			SBE->BE_COMPRLC := 1.20
			SBE->BE_DATGER  := Date()
			SBE->BE_HORGER  := Time()
			SBE->(MsUnLock())
			cMsg1+=Replicate("-",10)+chr(13)+chr(10)	
			aEval(aStruct, {|aLinha| iif((aLinha[2])== "C",cMsg1+= (aLinha[1])+":"+ SBE->&(aLinha[1])+chr(13)+chr(10), cMsg1+="" )} )
			cMsg1+=+chr(13)+chr(10)
		Next

	End Transaction

	If !ExistDir( "\loggen\" )
		MakeDir( "\loggen\" )
	EndIf
	cMsg1+= "[FIM]"
	memoWrit("\loggen\FtGeraBloc_"+FWTimeStamp(1,Date(),Time())+".txt",cMsg1)

Return

// ** funcao que retorna o ultimo sequencial utilizado
Static Function sfRetMaxPos(mvArmazem)
	local _cRet := Soma1(U_FtQuery("SELECT ISNULL(MAX(SUBSTRING(BE_LOCALIZ,8,5)),'00000') ULT_SEQ FROM "+RetSqlTab("SBE")+" (nolock)  "+;
	"WHERE "+RetSqlCond("SBE")+" AND BE_LOCAL = '"+mvArmazem+"' AND BE_ESTFIS IN ('000002', '000010')"))
Return(_cRet)

// ** funcao para trocar codigo de produto de todas as movimentacoes
User Function FtAltPrd(mvCodCli, mvProdDe, mvProdAte)

	// alias
	local _cAlProd := GetNextAlias()

	// log do processamento
	local _cLogProc := ""

	// sequencia de processamento
	local _cSeqProc := "001"

	// query
	local _cQuery

	// controle de codigo de produtos
	local _cProdAtu := ""
	local _cProdNew := ""

	// data e hora
	local _dDataProc := Date()
	local _cDataLog  := Replace(DtoC(_dDataProc), "/", "-")
	local _cHoraProc := Time()
	local _cHoraLog  := Replace(_cHoraProc, ":", "-")

	// arquivo de log
	local _nTmpHdl, _cTmpArquivo

	// controle de processamento
	local _lProcOk := .t.

	// seek
	local _cSeek

	// recno
	local _aTmpRecno :=	{}
	local _nTmpRecno :=	0

	// dados para registro do SB1
	local _aRegSB1  := {}
	local _lCadProd := .f.
	local _nTmpCmp

	// controle de tabelas para atualizacao
	_lAtuSB1 := .t.
	_lAtuSB2 := .t.
	_lAtuSB5 := .t.
	_lAtuSB6 := .t.
	_lAtuSB8 := .t.
	_lAtuSC6 := .t.
	_lAtuSC9 := .t.
	_lAtuSD1 := .t.
	_lAtuSD2 := .t.
	_lAtuSD3 := .t.
	_lAtuSD5 := .t.
	_lAtuSFT := .t.
	_lAtuCD2 := .t.
	_lAtuCT2 := .t.

	// define valores padroes dos parametros
	Default mvCodCli  := CriaVar("A1_COD", .f.)
	Default mvProdDe  := CriaVar("B1_COD", .f.)
	Default mvProdAte := CriaVar("B1_COD", .f.)

	// padroniza tamanho de variaveis
	mvCodCli  := PadR(mvCodCli , TamSx3("A1_COD")[1])
	mvProdDe  := PadR(mvProdDe , TamSx3("B1_COD")[1])
	mvProdAte := PadR(mvProdAte, TamSx3("B1_COD")[1])

	// monta query que busca os produtos que permitem alteracao
	_cQuery := " SELECT D1_LOTECTL                                                                          LOTE_ATUAL, "
	_cQuery += "        D1_LOTECTL                                                                          LOTE_NOVO, "
	_cQuery += "        D1_COD                                                                              COD_ATUAL, "
	//_cQuery += "        Substring(D1_COD, 1, Charindex(Rtrim(Ltrim(D1_LOTECTL)), Rtrim(Ltrim(D1_COD))) - 2) COD_NOVO "
	_cQuery += "        Substring(D1_COD, 1, Charindex(' ', Rtrim(Ltrim(D1_COD))))                          COD_NOVO
	_cQuery += " FROM   " + RetSqlTab("SD1") + " (nolock) "
	_cQuery += " WHERE  " + RetSqlCond("SD1")
	_cQuery += "        AND D1_FORNECE = '" +mvCodCli+ "' "
	_cQuery += "        AND Charindex(' ', Rtrim(Ltrim(D1_COD))) > 0 "
	_cQuery += "        AND D1_SERIE != 'DI' "
	//_cQuery += "        AND Charindex(Rtrim(Ltrim(D1_LOTECTL)), Rtrim(Ltrim(D1_COD))) > 0 "
	//_cQuery += "        AND D1_LOTECTL != ' ' "
	_cQuery += "        AND D1_COD BETWEEN '" +mvProdDe+ "' AND '" +mvProdAte+ "' "
	_cQuery += " ORDER  BY 3 "

	MemoWrit("c:\query\twmsxfu2_ftaltprd.txt", _cQuery)

	// fecha alias da query
	If (Select(_cAlProd)<>0)
		dbSelectArea(_cAlProd)
		dbCloseArea()
	EndIf

	// executa o select
	DbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),_cAlProd,.F.,.T.)
	(_cAlProd)->(DbGoTop())

	// define o arquivo temporario com o conteudo do log
	_cTmpArquivo := "c:\temp\log_FtAltPrd_"+_cDataLog+"_"+_cHoraLog+".log"

	// cria e abre arquivo texto
	_nTmpHdl := fCreate(_cTmpArquivo)

	// testa se o arquivo de Saida foi Criado Corretamente
	If (_nTmpHdl == -1)
		MsgAlert("O arquivo de nome "+_cTmpArquivo+" nao pode ser executado! Verifique os parametros e permissões da pasta C:\temp\.","Atencao!")
		Return(.f.)
	Endif

	// log de processamento
	_cLogProc := "ALTERAÇÃO DE CÓDIGOS DE PRODUTOS - " + DtoC(_dDataProc) + " " + _cHoraProc + CRLF
	_cLogProc += "Usuário: " + AllTrim(UsrFullName(__cUserId)) + CRLF
	_cLogProc += "Parâmetros: " + "Cliente: " + mvCodCli + " / Prod De: " + AllTrim(mvProdDe)+ " / Prod Até: " + AllTrim(mvProdAte) + CRLF
	_cLogProc += Replicate("-",100) + CRLF

	// grava a Linha no Arquivo Texto
	fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

	// varre todos os produtos
	While (_cAlProd)->( ! Eof() )

		// reinicia variaveis
		_lProcOk  := .t.
		_aRegSB1  := {}
		_lCadProd := .f.

		// padroniza tamanho de variaveis
		_cProdAtu := PadR((_cAlProd)->COD_ATUAL, TamSx3("B1_COD")[1])
		_cProdNew := PadR((_cAlProd)->COD_NOVO , TamSx3("B1_COD")[1])

		// log de processamento
		_cLogProc := ":: Seq: "+_cSeqProc
		_cLogProc += " / Prod Atual "+AllTrim(_cProdAtu)
		_cLogProc += " / Prod Novo "+AllTrim(_cProdNew)
		_cLogProc += CRLF

		// grava a Linha no Arquivo Texto
		fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))


		// inicia transacao especifica por produto / linha da nota
		BEGIN TRANSACTION

			If (_lProcOk) .And. (_lAtuSB1)

				// reinicia log
				_cLogProc := ""

				// CADASTRO DE PRODUTOS - SB1 - VERIFICA SE O CODIGO DO PRODUTO, SEM LOTE, EXISTE
				dbSelectArea("SB1")
				SB1->( dbSetOrder(1) ) // 1-B1_FILIAL, B1_COD
				If ! SB1->( dbSeek( xFilial("SB1") + _cProdNew ))
					// controle para gravar novo produto sem lote
					_lCadProd := .t.
				EndIf

				// CADASTRO DE PRODUTOS - SB1 - BLOQUEIA
				dbSelectArea("SB1")
				SB1->( dbSetOrder(1) ) // 1-B1_FILIAL, B1_COD
				If ! SB1->( dbSeek( xFilial("SB1") + _cProdAtu ))
					// log de processamento
					_cLogProc := "   :: SB1 - Cadastro não encontrado. Produto/item ignorado."
					_cLogProc += CRLF
					// controle de processamento
					_lProcOk := .f.
				Else

					// se precisa incluir novo, varre todos os campos e armazena conteudo
					If (_lCadProd)
						// loop dos campos do SB1
						For _nTmpCmp := 1 to FCount()
							aAdd(_aRegSB1, FieldGet(_nTmpCmp))
						Next _nTmpCmp
					EndIf

					// bloqueia produto
					RecLock("SB1", .f.)
					SB1->B1_MSBLQL := "1"
					SB1->(MsUnLock())
					// log de processamento
					_cLogProc := "   :: SB1 - Bloqueio realizado"
					_cLogProc += CRLF

					// se precisa incluir novo
					If (_lCadProd)
						// novo registro
						RecLock("SB1", .t.)
						// todos os campos
						For _nTmpCmp := 1 TO FCount()
							// posicao do campo
							If (_nTmpCmp == FieldPos("B1_COD"))
								FieldPut(_nTmpCmp, _cProdNew)
							ElseIf (_nTmpCmp == FieldPos("B1_CODCLI"))
								FieldPut(_nTmpCmp, SubS(_cProdNew, 5))
							Else
								FieldPut(_nTmpCmp, _aRegSB1[_nTmpCmp])
							Endif
						Next _nTmpCmp
						// confirma gravacao
						MsUnlock()

						// log de processamento
						_cLogProc := "   :: SB1 - Cadastro Novo Produto: " + AllTrim(_cProdNew)
						_cLogProc += CRLF

					EndIf

				EndIf

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

			EndIf

			If (_lProcOk) .And. (_lAtuSB2)
				// SALDO DE PRODUTOS POR ARMAZEM - SB2
				dbSelectArea("SB2")
				SB2->( dbSetOrder(1) ) // 1-B2_FILIAL, B2_COD, B2_LOCAL
				SB2->( dbSeek( _cSeek := xFilial("SB2") + _cProdAtu ) )
				// varre todos os registro do produto
				While SB2->( ! Eof() ) .And. ((SB2->B2_FILIAL + SB2->B2_COD) == _cSeek)

					// log de processamento
					_cLogProc := "   :: SB2 - Exclusão de saldo - Arm: " + SB2->B2_LOCAL
					_cLogProc += CRLF

					// exclui registros
					RecLock("SB2", .f.)
					SB2->(dbDelete())
					SB2->(MsUnLock())

					// proximo item
					SB2->( dbSkip() )
				EndDo

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

			EndIf

			If (_lProcOk) .And. (_lAtuSB5)
				// COMPLEMENTO DE PRODUTOS - SB5 - BLOQUEIA
				dbSelectArea("SB5")
				SB5->( dbSetOrder(1) ) // 1-B5_FILIAL, B5_COD
				SB5->( dbSeek( _cSeek := xFilial("SB5") + _cProdAtu ) )
				// varre todos os registro do produto
				While SB5->( ! Eof() ) .And. (SB5->(B5_FILIAL + B5_COD) == _cSeek)

					// log de processamento
					_cLogProc := "   :: SB5 - Exclusão do complemento " + AllTrim(SB5->B5_COD)
					_cLogProc += CRLF

					// exclui registros
					RecLock("SB5", .f.)
					SB5->(dbDelete())
					SB5->(MsUnLock())

					// proximo item
					SB5->( dbSkip() )
				EndDo

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

			EndIf

			If (_lProcOk) .And. (_lAtuSB6)
				// NOTAS FISCAIS PODER3 - SB6
				_cQuery := " SELECT SB6.R_E_C_N_O_ "
				_cQuery += " FROM   " + RetSqlTab("SB6") + " (nolock) "
				_cQuery += " WHERE  " + RetSqlCond("SB6")
				_cQuery += "        AND B6_PRODUTO = '" + _cProdAtu + "' "
				_cQuery += "        AND B6_CLIFOR = '" + mvCodCli + "' "
				_cQuery += " ORDER  BY 1 "

				// atualiza vetor com RECNO
				_aTmpRecno := U_SqlToVet(_cQuery)

				// varre todos os registros
				For _nTmpRecno := 1 to Len(_aTmpRecno)

					// posiciona no registros real
					dbSelectArea("SB6")
					SB6->( dbGoTo( _aTmpRecno[_nTmpRecno] ) )

					// atualiza campos
					RecLock("SB6", .f.)
					SB6->B6_PRODUTO := _cProdNew
					SB6->(MsUnLock())

					// log de processamento
					_cLogProc := "   :: SB6 - Alterado Cod Produto (ident: " + SB6->B6_IDENT + ") De: " + AllTrim(_cProdAtu) + " Para: " + AllTrim(_cProdNew)
					_cLogProc += CRLF

				Next _nTmpRecno

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

			EndIf

			If (_lProcOk) .And. (_lAtuSB8)
				// SALDOS POR LOTE - SB8
				_cQuery := " SELECT SB8.R_E_C_N_O_ "
				_cQuery += " FROM   " + RetSqlTab("SB8") + " (nolock) "
				_cQuery += " WHERE  " + RetSqlCond("SB8")
				_cQuery += "        AND B8_PRODUTO = '" + _cProdAtu + "' "
				_cQuery += " ORDER  BY 1 "

				// atualiza vetor com RECNO
				_aTmpRecno := U_SqlToVet(_cQuery)

				// varre todos os registros
				For _nTmpRecno := 1 to Len(_aTmpRecno)

					// posiciona no registros real
					dbSelectArea("SB8")
					SB8->( dbGoTo( _aTmpRecno[_nTmpRecno] ) )

					// log de processamento
					_cLogProc := "   :: SB8 - Exclusão Saldo do Lote: " + AllTrim(SB8->B8_LOTECTL) + " Prod: " + AllTrim(_cProdAtu)
					_cLogProc += CRLF

					// atualiza campos
					RecLock("SB8", .f.)
					SB8->(dbDelete())
					SB8->(MsUnLock())

				Next _nTmpRecno

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

			EndIf

			If (_lProcOk) .And. (_lAtuSC6)
				// ITENS DO PEDIDO DE VENDA - SC6
				_cQuery := " SELECT SC6.R_E_C_N_O_ "
				_cQuery += " FROM   " + RetSqlTab("SC6") + " (nolock) "
				_cQuery += " WHERE  " + RetSqlCond("SC6")
				_cQuery += "        AND C6_PRODUTO = '" + _cProdAtu + "' "
				_cQuery += "        AND C6_CLI = '" + mvCodCli + "' "
				_cQuery += " ORDER  BY 1 "

				// atualiza vetor com RECNO
				_aTmpRecno := U_SqlToVet(_cQuery)

				// varre todos os registros
				For _nTmpRecno := 1 to Len(_aTmpRecno)

					// posiciona no registros real
					dbSelectArea("SC6")
					SC6->( dbGoTo( _aTmpRecno[_nTmpRecno] ) )

					// atualiza campos
					RecLock("SC6", .f.)
					SC6->C6_PRODUTO := _cProdNew
					SC6->(MsUnLock())

					// log de processamento
					_cLogProc := "   :: SC6 - Alterado Cod Produto (Pedido: " + SC6->C6_NUM + " / Item: " +SC6->C6_ITEM+ ") De: " + AllTrim(_cProdAtu) + " Para: " + AllTrim(_cProdNew)
					_cLogProc += CRLF

				Next _nTmpRecno

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

			EndIf

			If (_lProcOk) .And. (_lAtuSC9)
				// ITENS LIBERADOS DO PEDIDO DE VENDA - SC9
				_cQuery := " SELECT SC9.R_E_C_N_O_ "
				_cQuery += " FROM   " + RetSqlTab("SC9") + " (nolock) "
				_cQuery += " WHERE  " + RetSqlCond("SC9")
				_cQuery += "        AND C9_PRODUTO = '" + _cProdAtu + "' "
				_cQuery += "        AND C9_CLIENTE = '" + mvCodCli + "' "
				_cQuery += " ORDER  BY 1 "

				// atualiza vetor com RECNO
				_aTmpRecno := U_SqlToVet(_cQuery)

				// varre todos os registros
				For _nTmpRecno := 1 to Len(_aTmpRecno)

					// posiciona no registros real
					dbSelectArea("SC9")
					SC9->( dbGoTo( _aTmpRecno[_nTmpRecno] ) )

					// atualiza campos
					RecLock("SC9", .f.)
					SC9->C9_PRODUTO := _cProdNew
					SC9->(MsUnLock())

					// log de processamento
					_cLogProc := "   :: SC9 - Alterado Cod Produto (Pedido: " + SC9->C9_PEDIDO + " / Item: " +SC9->C9_ITEM+ ") De: " + AllTrim(_cProdAtu) + " Para: " + AllTrim(_cProdNew)
					_cLogProc += CRLF

				Next _nTmpRecno

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

			EndIf

			If (_lProcOk) .And. (_lAtuSD1)
				// NOTAS FISCAIS DE ENTRADA - SD1
				_cQuery := " SELECT SD1.R_E_C_N_O_ "
				_cQuery += " FROM   " + RetSqlTab("SD1") + " (nolock) "
				_cQuery += " WHERE  " + RetSqlCond("SD1")
				_cQuery += "        AND D1_COD = '" + _cProdAtu + "' "
				_cQuery += "        AND D1_FORNECE = '" + mvCodCli + "' "
				_cQuery += " ORDER  BY 1 "

				// atualiza vetor com RECNO
				_aTmpRecno := U_SqlToVet(_cQuery)

				// varre todos os registros
				For _nTmpRecno := 1 to Len(_aTmpRecno)

					// posiciona no registros real
					dbSelectArea("SD1")
					SD1->( dbGoTo( _aTmpRecno[_nTmpRecno] ) )

					// atualiza campos
					RecLock("SD1", .f.)
					SD1->D1_COD := _cProdNew
					SD1->(MsUnLock())

					// log de processamento
					_cLogProc := "   :: SD1 - Alterado Cod Produto (Nota: " + SD1->D1_DOC + " / Item: " +SD1->D1_ITEM+ ") De: " + AllTrim(_cProdAtu) + " Para: " + AllTrim(_cProdNew)
					_cLogProc += CRLF

				Next _nTmpRecno

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

			EndIf

			If (_lProcOk) .And. (_lAtuSD2)
				// NOTAS FISCAIS DE SAIDA - SD2
				_cQuery := " SELECT SD2.R_E_C_N_O_ "
				_cQuery += " FROM   " + RetSqlTab("SD2") + " (nolock) "
				_cQuery += " WHERE  " + RetSqlCond("SD2")
				_cQuery += "        AND D2_COD = '" + _cProdAtu + "' "
				_cQuery += "        AND D2_CLIENTE = '" + mvCodCli + "' "
				_cQuery += " ORDER  BY 1 "

				// atualiza vetor com RECNO
				_aTmpRecno := U_SqlToVet(_cQuery)

				// varre todos os registros
				For _nTmpRecno := 1 to Len(_aTmpRecno)

					// posiciona no registros real
					dbSelectArea("SD2")
					SD2->( dbGoTo( _aTmpRecno[_nTmpRecno] ) )

					// atualiza campos
					RecLock("SD2", .f.)
					SD2->D2_COD := _cProdNew
					SD2->(MsUnLock())

					// log de processamento
					_cLogProc := "   :: SD2 - Alterado Cod Produto (Nota: " + SD2->D2_DOC + " / Item: " +SD2->D2_ITEM+ ") De: " + AllTrim(_cProdAtu) + " Para: " + AllTrim(_cProdNew)
					_cLogProc += CRLF

				Next _nTmpRecno

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

			EndIf

			If (_lProcOk) .And. (_lAtuSD3)
				// MOVIMENTACOES INTERNAS - SD3
				_cQuery := " SELECT SD3.R_E_C_N_O_ "
				_cQuery += " FROM   " + RetSqlTab("SD3") + " (nolock) "
				_cQuery += " WHERE  " + RetSqlCond("SD3")
				_cQuery += "        AND D3_COD = '" + _cProdAtu + "' "
				_cQuery += " ORDER  BY 1 "

				// atualiza vetor com RECNO
				_aTmpRecno := U_SqlToVet(_cQuery)

				// varre todos os registros
				For _nTmpRecno := 1 to Len(_aTmpRecno)

					// posiciona no registros real
					dbSelectArea("SD3")
					SD3->( dbGoTo( _aTmpRecno[_nTmpRecno] ) )

					// atualiza campos
					RecLock("SD3", .f.)
					SD3->D3_COD := _cProdNew
					SD3->(MsUnLock())

					// log de processamento
					_cLogProc := "   :: SD3 - Alterado Cod Produto (Doc: " + SD3->D3_DOC + " / NumSeq: " +SD3->D3_NUMSEQ+ ") De: " + AllTrim(_cProdAtu) + " Para: " + AllTrim(_cProdNew)
					_cLogProc += CRLF

				Next _nTmpRecno

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

			EndIf

			If (_lProcOk) .And. (_lAtuSD5)
				// REQUISICOES POR LOTE - SD5
				_cQuery := " SELECT SD5.R_E_C_N_O_ "
				_cQuery += " FROM   " + RetSqlTab("SD5") + " (nolock) "
				_cQuery += " WHERE  " + RetSqlCond("SD5")
				_cQuery += "        AND D5_PRODUTO = '" + _cProdAtu + "' "
				_cQuery += " ORDER  BY 1 "

				// atualiza vetor com RECNO
				_aTmpRecno := U_SqlToVet(_cQuery)

				// varre todos os registros
				For _nTmpRecno := 1 to Len(_aTmpRecno)

					// posiciona no registros real
					dbSelectArea("SD5")
					SD5->( dbGoTo( _aTmpRecno[_nTmpRecno] ) )

					// atualiza campos
					RecLock("SD5", .f.)
					SD5->D5_PRODUTO := _cProdNew
					SD5->(MsUnLock())

					// log de processamento
					_cLogProc := "   :: SD5 - Alterado Cod Produto (Doc: " + SD5->D5_DOC + " / NumSeq: " +SD5->D5_NUMSEQ+ ") De: " + AllTrim(_cProdAtu) + " Para: " + AllTrim(_cProdNew)
					_cLogProc += CRLF

				Next _nTmpRecno

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

			EndIf

			If (_lProcOk) .And. (_lAtuSFT)
				// LIVRO FISCAL POR ITEM DE NF - SFT
				_cQuery := " SELECT SFT.R_E_C_N_O_ "
				_cQuery += " FROM   " + RetSqlTab("SFT") + " (nolock) "
				_cQuery += " WHERE  " + RetSqlCond("SFT")
				_cQuery += "        AND FT_PRODUTO = '" + _cProdAtu + "' "
				_cQuery += "        AND FT_CLIEFOR = '" + mvCodCli + "' "
				_cQuery += " ORDER  BY 1 "

				// atualiza vetor com RECNO
				_aTmpRecno := U_SqlToVet(_cQuery)

				// varre todos os registros
				For _nTmpRecno := 1 to Len(_aTmpRecno)

					// posiciona no registros real
					dbSelectArea("SFT")
					SFT->( dbGoTo( _aTmpRecno[_nTmpRecno] ) )

					// atualiza campos
					RecLock("SFT", .f.)
					SFT->FT_PRODUTO := _cProdNew
					SFT->(MsUnLock())

					// log de processamento
					_cLogProc := "   :: SFT - Alterado Cod Produto (Doc: " + SFT->FT_NFISCAL + " / Mov: " + SFT->FT_TIPOMOV+ " / Item: " +SFT->FT_ITEM+ ") De: " + AllTrim(_cProdAtu) + " Para: " + AllTrim(_cProdNew)
					_cLogProc += CRLF

				Next _nTmpRecno

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

			EndIf

			If (_lProcOk) .And. (_lAtuCD2)
				// LIVRO DIGITAL DE IMPOSTOS-SPED - CD2
				_cQuery := " SELECT CD2.R_E_C_N_O_ "
				_cQuery += " FROM   " + RetSqlTab("CD2") + " (nolock) "
				_cQuery += " WHERE  " + RetSqlCond("CD2")
				_cQuery += "        AND CD2_CODPRO = '" + _cProdAtu + "' "
				_cQuery += "        AND CD2_CODCLI = '" + mvCodCli + "' "
				_cQuery += " ORDER  BY 1 "

				// atualiza vetor com RECNO
				_aTmpRecno := U_SqlToVet(_cQuery)

				// varre todos os registros
				For _nTmpRecno := 1 to Len(_aTmpRecno)

					// posiciona no registros real
					dbSelectArea("CD2")
					CD2->( dbGoTo( _aTmpRecno[_nTmpRecno] ) )

					// atualiza campos
					RecLock("CD2", .f.)
					CD2->CD2_CODPRO := _cProdNew
					CD2->(MsUnLock())

					// log de processamento
					_cLogProc := "   :: CD2 - Alterado Cod Produto (Doc: " + CD2->CD2_DOC + " / Mov: " + CD2->CD2_TPMOV+ " / Item: " +CD2->CD2_ITEM+ ") De: " + AllTrim(_cProdAtu) + " Para: " + AllTrim(_cProdNew)
					_cLogProc += CRLF

				Next _nTmpRecno

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

			EndIf

			If (_lProcOk) .And. (_lAtuCT2)
				// LANCAMENTOS CONTABEIS - CT2
				_cQuery := " SELECT CT2.R_E_C_N_O_ "
				_cQuery += " FROM   " + RetSqlTab("CT2") + " (nolock) "
				_cQuery += " WHERE  " + RetSqlCond("CT2")
				_cQuery += "        AND ( CT2_LOTE = '008810' OR CT2_LOTE = '008820' ) "
				_cQuery += "        AND CT2_KEY LIKE '%" + AllTrim(_cProdAtu) + "%' "
				_cQuery += " ORDER  BY 1 "

				// atualiza vetor com RECNO
				_aTmpRecno := U_SqlToVet(_cQuery)

				// varre todos os registros
				For _nTmpRecno := 1 to Len(_aTmpRecno)

					// posiciona no registros real
					dbSelectArea("CT2")
					CT2->( dbGoTo( _aTmpRecno[_nTmpRecno] ) )

					// atualiza campos
					RecLock("CT2", .f.)
					CT2->CT2_KEY := Replace(CT2->CT2_KEY, _cProdAtu, _cProdNew)
					CT2->(MsUnLock())

					// log de processamento
					_cLogProc := "   :: CT2 - Alterado Cod Produto (Lote: " + CT2->CT2_LOTE + " / Sub: " + CT2->CT2_SBLOTE+ " / Doc: " +CT2->CT2_DOC+ " / Linha: " +CT2->CT2_LINHA+ ") De: " + AllTrim(_cProdAtu) + " Para: " + AllTrim(_cProdNew)
					_cLogProc += CRLF

				Next _nTmpRecno

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl, _cLogProc, Len(_cLogProc))

			EndIf

			// finaliza transacao especifica por endereco
		END TRANSACTION

		// proxima sequencia
		_cSeqProc := Soma1(_cSeqProc)

		// proximo item
		(_cAlProd)->( dbSkip() )
	EndDo

	// fecha arquivo texto
	fClose(_nTmpHdl)

	// mensagem final
	MsgInfo("Processamento concluído com sucesso." + CRLF + "Verifique o log em: " + _cTmpArquivo)

Return

// ** funcao que retorna o numseq do produto
Static Function sfRetNumSeq(mvCodProd)
	// query
	local _cQuery
	// retorno
	local _cRetNumSeq := ""
	// dados temporarios
	local _aTmpDados

	// prepara query
	_cQuery := " SELECT DISTINCT B6_IDENT "
	_cQuery += " FROM   " + RetSqlTab("SB6") + " (nolock) "
	_cQuery += " WHERE  " + RetSqlCond("SB6")
	_cQuery += "        AND B6_PRODUTO = '" +mvCodProd+ "' "
	_cQuery += "        AND B6_SALDO != 0 "
	_cQuery += "        AND B6_PODER3 = 'R' "

	// atualiza vetor
	_aTmpDados := U_SqlToVet(_cQuery)

	// se for apenas um registro
	If (Len(_aTmpDados) == 1)
		_cRetNumSeq := _aTmpDados[1]
	EndIf

Return(_cRetNumSeq)

// ** funcao generica para importacao de cadastro de produtos
User Function FtImpPrd()

	// codigo do produto
	local _cCodProd

	// dados do produto
	Local _aDadosPro := {}

	// dados de codigos de barras
	local _cSeqCodBar
	local _aCodBarPrd := {}

	// variaveis temporarias
	local _cQuery
	local _nCodBar

	// alias
	local _cAlProd := GetNextAlias()

	// busca dados de tabela temporarias
	_cQuery := " SELECT * "
	_cQuery += " FROM   (SELECT 'DANU'                                         AS B1_GRUPO, "
	_cQuery += "                LUM_DET.[Código]                               AS B1_CODCLI, "
	_cQuery += "                'DANU' + LUM_DET.[Código]                      AS B1_COD, "
	_cQuery += "                LUM_DET.[Descrição]                            AS B1_DESC, "
	_cQuery += "                'ME'                                           AS B1_TIPO, "
	_cQuery += "                LUM_DET.[1UOM]                                 AS B1_UM, "
	_cQuery += "                LUM_DET.[2UOM]                                 AS B1_SEGUM, "
	_cQuery += "                LUM_DET.[Fator Conversão]                      AS B1_CONV, "
	_cQuery += "                'D'                                            AS B1_TIPCONV, "
	_cQuery += "                '01'                                           AS B1_LOCPAD, "
	_cQuery += "                'S'                                            AS B1_LOCALIZ, "
	_cQuery += "                '0'                                            AS B1_ORIGEM, "
	_cQuery += "                '00000000'                                     AS B1_POSIPI, "
	_cQuery += "                ''                                             AS B1_ZINFADI, "
	_cQuery += "                'A'                                            AS B1_ZTIPPRO, "
	_cQuery += "                '2'                                            AS B1_GARANT, "
	_cQuery += "                'N'                                            AS B1_ZINFQTD, "
	_cQuery += "                'N'                                            AS B1_RASTRO, "
	_cQuery += "                ''                                             AS B1_ZGRPEST, "
	_cQuery += "                ''                                             AS B1_CODBAR, "
	_cQuery += "                ''                                             AS B1_ZTPBAR, "
	_cQuery += "                Isnull(Str([CODE INDIVIDUAL (13)], 13, 0), '') AS EAN_UNIT, "
	_cQuery += "                Isnull(Str([CODE INNER (14)], 14, 0), '')      AS DUN_INNER, "
	_cQuery += "                Isnull([Qty Into Inner], 0)                    AS QTD_INNER, "
	_cQuery += "                Isnull(Str([CODE MASTER (14)], 14, 0), '')     AS DUN_MASTER, "
	_cQuery += "                Isnull([Qty Master], 0)                        AS QTD_MASTER "
	_cQuery += "         FROM   TOTVS_TESTE..LUM_CAD "
	_cQuery += "                INNER JOIN TOTVS_TESTE..LUM_DET "
	_cQuery += "                        ON LUM_DET.[Código] = LUM_CAD.[Código] "
	_cQuery += "                           AND LUM_DET.[Estoque] != 0) AS CADASTRO_LUMINATTI "
	_cQuery += " WHERE  1 = 1 "
	_cQuery += "        AND EAN_UNIT != '' "

	// convertido em VIEW
	_cQuery := " SELECT * FROM TOTVS_TESTE..V_WMS_CAD_PROD "

	// fecha alias da query
	If (Select(_cAlProd)<>0)
		dbSelectArea(_cAlProd)
		dbCloseArea()
	EndIf

	// executa o select
	DbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),_cAlProd,.F.,.T.)
	(_cAlProd)->(DbGoTop())


	// varre todos os itens da query
	While (_cAlProd)->( ! Eof() )

		// codigo do produto
		_cCodProd := PadR((_cAlProd)->B1_COD, TamSx3("B1_COD")[1])

		// verifica se produto ja esta cadastrado
		dbSelectArea("SB1")
		SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
		If (SB1->(dbSeek( xFilial("SB1") + _cCodProd )))
			// proximo item
			(_cAlProd)->(dbSkip())
			Loop
		EndIf

		// zera variaveis
		_aDadosPro  := {}
		_aCodBarPrd := {}
		_cSeqCodBar := "0001"

		// alimenta Vetor com os dados do produto a ser cadastrado
		aAdd(_aDadosPro,{"B1_GRUPO"  , Padr((_cAlProd)->B1_GRUPO, TamSx3("B1_GRUPO")[1])    , NIL} )
		aAdd(_aDadosPro,{"B1_CODCLI" , Padr((_cAlProd)->B1_CODCLI, TamSx3("B1_CODCLI")[1])  , NIL} )
		aAdd(_aDadosPro,{"B1_COD"    , Padr((_cAlProd)->B1_COD, TamSx3("B1_COD")[1])        , NIL} )
		aAdd(_aDadosPro,{"B1_DESC"   , Padr((_cAlProd)->B1_DESC, TamSx3("B1_DESC")[1])      , NIL} )
		aAdd(_aDadosPro,{"B1_TIPO"   , Padr((_cAlProd)->B1_TIPO, TamSx3("B1_TIPO")[1])      , NIL} )
		aAdd(_aDadosPro,{"B1_UM"     , Padr((_cAlProd)->B1_UM, TamSx3("B1_UM")[1])          , NIL} )
		aAdd(_aDadosPro,{"B1_SEGUM"  , Padr((_cAlProd)->B1_SEGUM, TamSx3("B1_SEGUM")[1])    , NIL} )
		aAdd(_aDadosPro,{"B1_CONV"   , (_cAlProd)->B1_CONV                                  , NIL} )
		aAdd(_aDadosPro,{"B1_TIPCONV", Padr((_cAlProd)->B1_TIPCONV, TamSx3("B1_TIPCONV")[1]), NIL} )
		aAdd(_aDadosPro,{"B1_LOCPAD" , (_cAlProd)->B1_LOCPAD                                , NIL} )
		aAdd(_aDadosPro,{"B1_LOCALIZ", (_cAlProd)->B1_LOCALIZ                               , NIL} )
		aAdd(_aDadosPro,{"B1_ORIGEM" , (_cAlProd)->B1_ORIGEM                                , NIL} )
		aAdd(_aDadosPro,{"B1_POSIPI" , (_cAlProd)->B1_POSIPI                                , NIL} )
		aAdd(_aDadosPro,{"B1_ZINFADI", (_cAlProd)->B1_ZINFADI                               , NIL} )
		aAdd(_aDadosPro,{"B1_ZTIPPRO", (_cAlProd)->B1_ZTIPPRO                               , NIL} )
		aAdd(_aDadosPro,{"B1_GARANT" , (_cAlProd)->B1_GARANT                                , NIL} )
		aAdd(_aDadosPro,{"B1_ZINFQTD", (_cAlProd)->B1_ZINFQTD                               , NIL} )
		aAdd(_aDadosPro,{"B1_RASTRO" , (_cAlProd)->B1_RASTRO                                , NIL} )
		aAdd(_aDadosPro,{"B1_ZGRPEST", (_cAlProd)->B1_ZGRPEST                               , NIL} )
		aAdd(_aDadosPro,{"B1_CODBAR" , (_cAlProd)->B1_CODBAR                                , NIL} )
		aAdd(_aDadosPro,{"B1_ZTPBAR" , (_cAlProd)->B1_ZTPBAR                                , NIL} )

		// padronizao ordem dos campos
		_aDadosPro := FWVetByDic(_aDadosPro,'SB1',.F.)

		// verifica se tem caixa master
		If ( ! Empty((_cAlProd)->DUN_MASTER) ) .And. ((_cAlProd)->QTD_MASTER > 0)
			// prepara dados de codigos de barras
			aAdd(_aCodBarPrd,{_cSeqCodBar, "1", "CAIXA MASTER", (_cAlProd)->QTD_MASTER, "4", Padr((_cAlProd)->DUN_MASTER, TamSx3("Z32_CODBAR")[1])})
			_cSeqCodBar := Soma1(_cSeqCodBar)
		EndIf

		// verifica se tem caixa inner
		If ( ! Empty((_cAlProd)->DUN_INNER) ) .And. ((_cAlProd)->QTD_INNER > 0)
			// prepara dados de codigos de barras
			aAdd(_aCodBarPrd,{_cSeqCodBar, "1", "CAIXA INNER", (_cAlProd)->QTD_INNER, "4", PadR((_cAlProd)->DUN_INNER, TamSx3("Z32_CODBAR")[1])})
			_cSeqCodBar := Soma1(_cSeqCodBar)
		EndIf

		// prepara dados de codigos de barras unitario
		aAdd(_aCodBarPrd,{_cSeqCodBar, "0", "UNITARIO", 1, "1", PadR((_cAlProd)->EAN_UNIT, TamSx3("Z32_CODBAR")[1])})

		//Executa a Rotina Automatica
		lMsErroAuto := .F.

		// rotina padrao para cadastro de produtos
		MSExecAuto({|x,y| MATA010(x,y)}, _aDadosPro, 3) // 3-Inclusao/4-Alteracao

		If (lMsErroAuto)
			MostraErro()
			Return(.f.)
		EndIf

		// se cadastrou o produto, adiciona codigos de barras de SKU
		For _nCodBar := 1 to Len(_aCodBarPrd)

			// insere os registros
			Reclock("Z32",.T.)
			Z32->Z32_FILIAL := xFilial("Z32")
			Z32->Z32_CODPRO := _cCodProd
			Z32->Z32_ORDEM  := _aCodBarPrd[_nCodBar][1]
			Z32->Z32_TIPO   := _aCodBarPrd[_nCodBar][2]
			Z32->Z32_DESC   := _aCodBarPrd[_nCodBar][3]
			Z32->Z32_QUANT  := _aCodBarPrd[_nCodBar][4]
			Z32->Z32_ZTPBAR := _aCodBarPrd[_nCodBar][5]
			Z32->Z32_CODBAR := _aCodBarPrd[_nCodBar][6]
			MsUnlock()

		Next _nCodBar

		// proximo item
		(_cAlProd)->(dbSkip())
	EndDo

	MsgInfo("Processamento Ok", "Imp.Produtos")

Return

// ** função que atualiza o Id Palete, não deixando mais de um Id pallet no mesmo endereço
// redmine: Defeito #71
User Function FtAgrPlt(mvLocal, mvEndereco, mvIdPltMov, mvCodPro ,mvIdPltAtu, mvRegLock)
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"Z16"})

	// query responsavel pelas pesquisas da função
	local _cQuery := ""

	// recno do Z16
	local _aRecnoZ16 := {}
	local _nRecZ16

	// variavel que receberá o pallet antigo para substituição
	Default mvIdPltAtu := ""

	// relacao de RECNO bloqueados
	Default mvRegLock := {}

	// primeiro valida se o endereço de destino possui mais de um pallet
	_cQuery := " SELECT Count(DISTINCT Z16_ETQPAL) QTD_PLT_ENT "
	_cQuery += " FROM   " + RetSqlTab("Z16") + " (NOLOCK) "
	_cQuery += " WHERE  " + RetSqlCond("Z16")
	_cQuery += "        AND Z16_ENDATU = '" + mvEndereco + "' "
	_cQuery += "        AND Z16_LOCAL = '" + mvLocal + "' "
	_cQuery += "        AND Z16_SALDO > 0 "
	_cQuery += "        AND EXISTS (SELECT BE_LOCALIZ "
	_cQuery += "                    FROM   " + RetSqlTab("SBE") + " (NOLOCK) "
	_cQuery += "                    WHERE  " + RetSqlCond("SBE")
	_cQuery += "                           AND BE_LOCAL = Z16_LOCAL "
	_cQuery += "                           AND BE_LOCALIZ = Z16_ENDATU "
	_cQuery += "                           AND BE_ESTFIS IN ( '000002', '000010' )) "
	_cQuery += " GROUP  BY Z16_ENDATU "

	memowrit("C:\query\twmsxfun2_FtAgrPlt_1.txt", _cQuery)

	// caso o resultado seja maior que UM, vai pesquisar o pallet pra poder atualizar o registro
	If ( U_FtQuery(_cQuery) > 1 )

		// vou pesquisa se há pallet com saldo na posição de destino
		_cQuery := " SELECT MIN(Z16_ETQPAL) Z16_ETQPAL "
		_cQuery += " FROM   " + RetSqlTab("Z16") + " (NOLOCK) "
		_cQuery += " WHERE  " + RetSqlCond("Z16")
		_cQuery += "        AND Z16_ENDATU = '" + mvEndereco + "' "
		_cQuery += "        AND Z16_LOCAL  = '" + mvLocal + "' "
		_cQuery += "        AND Z16_SALDO > 0 "
		_cQuery += "        AND Z16_ETQPAL != '" + mvIdPltMov + "' "

		memowrit("C:\query\twmsxfun2_FtAgrPlt_id_palete_antigo.txt", _cQuery)

		// jogo o pallet para a variavél para realizar a atualização
		mvIdPltAtu := U_FtQuery(_cQuery)

		// busco todos os registros que precisam de alteracao
		_cQuery := " SELECT Z16.R_E_C_N_O_ Z16RECNO "
		_cQuery += " FROM   " + RetSqlTab("Z16") + " (NOLOCK) "
		_cQuery += " WHERE  " + RetSqlCond("Z16")
		_cQuery += "        AND Z16_ETQPAL = '" + mvIdPltMov + "' "
		_cQuery += "        AND Z16_LOCAL  = '" + mvLocal    + "' "
		_cQuery += "        AND Z16_ENDATU = '" + mvEndereco + "' "
		_cQuery += "        AND Z16_CODPRO = '" + mvCodPro   + "' "
		_cQuery += "        AND Z16_SALDO > 0 "

		memowrit("C:\query\twmsxfun2_FtAgrPlt_recno_atualizacao.txt", _cQuery)

		// atualizo variavel com os recno para Loop
		_aRecnoZ16 := U_SqlToVet(_cQuery)

		// loop nos RECNOs para atualizacao
		For _nRecZ16 := 1 to Len(_aRecnoZ16)

			// agrega RECLOK
			aAdd(mvRegLock,{"Z16", _aRecnoZ16[_nRecZ16]})

			// abre a tabela de composicao do palete
			dbSelectArea("Z16")
			Z16->( DbGoTo( _aRecnoZ16[_nRecZ16] ) )

			// atualiza informacoes
			RecLock("Z16", .F.)
			Z16->Z16_ETQPAL := mvIdPltAtu
			Z16->Z16_PLTORI := mvIdPltMov
			Z16->(MsUnLock())

		Next _nRecZ16

	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni, .T.)
	RestArea(_aAreaAtu)

Return( .T. )

// ** funcao que agrupa registros da composicao de palete
// redmine: Defeito #71
User Function FtAgrEtq(mvLocal, mvEndAtual, mvIdPalete)
	// variavel de retorno
	local _lRet := .F.
	// query dos dados
	local _cQuery
	// alias temporario
	local _cAlEtqPlt := GetNextAlias()
	// recno
	local _aTmpRecno := {}
	local _nTmpRecno

	// prepara consulta para verificar os registros duplicados
	_cQuery := " SELECT Z16_FILIAL, "
	_cQuery += "        Z16_ETQPAL, "
	_cQuery += "        Z16_UNITIZ, "
	_cQuery += "        Z16_ETQPRD, "
	_cQuery += "        Z16_CODPRO, "
	_cQuery += "        Sum(Z16_QUANT)             Z16_QUANT, "
	_cQuery += "        Sum(Z16_QTDVOL)            Z16_QTDVOL, "
	_cQuery += "        Z16_ENDATU, "
	_cQuery += "        Sum(Z16_SALDO)             Z16_SALDO, "
	_cQuery += "        Count(DISTINCT Z16_PLTORI) QTD_PLTORI, "
	_cQuery += "        Z16_LOCAL, "
	_cQuery += "        Z16_EMBALA, "
	_cQuery += "        Z16_TPESTO, "
	_cQuery += "        Z16_CODBAR, "
	_cQuery += "        Z16_ETQVOL, "
	_cQuery += "        Z16_SEQKIT, "
	_cQuery += "        Z16_CODKIT, "
	_cQuery += "        Count(DISTINCT Z16_VOLORI) QTD_VOLORI, "
	_cQuery += "        Z16_LOTCTL, "
	_cQuery += "        Z16_VLDLOT, "
	_cQuery += "        Sum(Z16_QTSEGU)            Z16_QTSEGU, "
	// relacao dos RECNO
	_cQuery += "        (SELECT Rtrim(Z16REC.R_E_C_N_O_) + ';' "
	_cQuery += "         FROM   " + RetSqlName("Z16") + " Z16REC (nolock)  "
	_cQuery += "         WHERE  Z16REC.Z16_FILIAL = Z16.Z16_FILIAL "
	_cQuery += "                AND Z16REC.D_E_L_E_T_ = ' ' "
	_cQuery += "                AND Z16REC.Z16_ETQPAL = Z16.Z16_ETQPAL "
	_cQuery += "                AND Z16REC.Z16_UNITIZ = Z16.Z16_UNITIZ "
	_cQuery += "                AND Z16REC.Z16_ETQPRD = Z16.Z16_ETQPRD "
	_cQuery += "                AND Z16REC.Z16_CODPRO = Z16.Z16_CODPRO "
	_cQuery += "                AND Z16REC.Z16_ENDATU = Z16.Z16_ENDATU "
	_cQuery += "                AND Z16REC.Z16_LOCAL = Z16.Z16_LOCAL "
	_cQuery += "                AND Z16REC.Z16_EMBALA = Z16.Z16_EMBALA "
	_cQuery += "                AND Z16REC.Z16_TPESTO = Z16.Z16_TPESTO "
	_cQuery += "                AND Z16REC.Z16_CODBAR = Z16.Z16_CODBAR "
	_cQuery += "                AND Z16REC.Z16_ETQVOL = Z16.Z16_ETQVOL "
	_cQuery += "                AND Z16REC.Z16_SEQKIT = Z16.Z16_SEQKIT "
	_cQuery += "                AND Z16REC.Z16_CODKIT = Z16.Z16_CODKIT "
	_cQuery += "                AND Z16REC.Z16_LOTCTL = Z16.Z16_LOTCTL "
	_cQuery += "                AND Z16REC.Z16_VLDLOT = Z16.Z16_VLDLOT "
	_cQuery += "         FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(400)') REL_RECNO "
	// composicado do palete
	_cQuery += " FROM   " + RetSqlTab("Z16") + " (NOLOCK) "
	// filtro padrao e id Palete
	_cQuery += " WHERE  " + RetSqlCond("Z16")
	_cQuery += "        AND Z16_ETQPAL = '" + mvIdPalete + "' "
	_cQuery += "        AND Z16_SALDO != 0 "
	_cQuery += "        AND Z16_LOCAL = '" + mvLocal + "' "
	_cQuery += "        AND Z16_ENDATU = '" + mvEndAtual + "' "
	// agrupamentos dos dados
	_cQuery += " GROUP  BY Z16_FILIAL, "
	_cQuery += "           Z16_ETQPAL, "
	_cQuery += "           Z16_UNITIZ, "
	_cQuery += "           Z16_ETQPRD, "
	_cQuery += "           Z16_CODPRO, "
	_cQuery += "           Z16_ENDATU, "
	_cQuery += "           Z16_LOCAL, "
	_cQuery += "           Z16_EMBALA, "
	_cQuery += "           Z16_TPESTO, "
	_cQuery += "           Z16_CODBAR, "
	_cQuery += "           Z16_ETQVOL, "
	_cQuery += "           Z16_SEQKIT, "
	_cQuery += "           Z16_CODKIT, "
	_cQuery += "           Z16_LOTCTL, "
	_cQuery += "           Z16_VLDLOT "

	MemoWrit("c:\query\twmsxfu2_FtAgrEtq.txt", _cQuery)

	// verifica se a query esta aberta
	If (Select(_cAlEtqPlt) != 0)
		dbSelectArea(_cAlEtqPlt)
		dbCloseArea()
	EndIf

	// executa a query
	dbUseArea(.T., 'TOPCONN', TCGENQRY(,,_cQuery), (_cAlEtqPlt), .F., .T.)
	dbSelectArea(_cAlEtqPlt)

	// varre a composicao do palete
	While (_cAlEtqPlt)->( ! Eof() )

		// se tem varias etiquetas de volume de origem
		If ((_cAlEtqPlt)->QTD_VOLORI > 1)

			// pega relacao de RECNO para excluir a origem
			_aTmpRecno := StrTokArr(AllTrim((_cAlEtqPlt)->REL_RECNO), ";")

			// varre todos os recno e exclui
			For _nTmpRecno := 1 to Len(_aTmpRecno)

				// abre a tabela origem
				dbSelectArea("Z16")
				Z16->(DbGoTo( Val(_aTmpRecno[_nTmpRecno]) ))
				// exclui o registro da composicao do palete
				RecLock("Z16")
				Z16->(dbDelete())
				Z16->(MsUnLock())

			Next _nTmpRecno

			// grava novo registro, com os dados agrupados
			dbSelectArea("Z16")
			RecLock("Z16", .T.)
			Z16->Z16_FILIAL   := xFilial("Z16")
			Z16->Z16_ETQPAL   := (_cAlEtqPlt)->Z16_ETQPAL
			Z16->Z16_PLTORI   := (_cAlEtqPlt)->Z16_ETQPAL
			Z16->Z16_UNITIZ   := (_cAlEtqPlt)->Z16_UNITIZ
			Z16->Z16_ETQPRD   := (_cAlEtqPlt)->Z16_ETQPRD
			Z16->Z16_CODPRO   := (_cAlEtqPlt)->Z16_CODPRO
			Z16->Z16_QUANT    := (_cAlEtqPlt)->Z16_QUANT
			Z16->Z16_SALDO    := (_cAlEtqPlt)->Z16_SALDO
			Z16->Z16_STATUS   := "T" // V=Vazio / T=Total / P=Parcial
			Z16->Z16_QTDVOL   := (_cAlEtqPlt)->Z16_QTDVOL
			Z16->Z16_ENDATU   := (_cAlEtqPlt)->Z16_ENDATU
			Z16->Z16_ORIGEM   := "AGR"
			Z16->Z16_LOCAL    := (_cAlEtqPlt)->Z16_LOCAL
			Z16->Z16_TPESTO   := (_cAlEtqPlt)->Z16_TPESTO
			Z16->Z16_CODBAR   := (_cAlEtqPlt)->Z16_CODBAR
			Z16->Z16_EMBALA   := (_cAlEtqPlt)->Z16_EMBALA
			Z16->Z16_ETQVOL   := (_cAlEtqPlt)->Z16_ETQVOL
			Z16->Z16_DATA     := Date()
			Z16->Z16_HORA     := Time()
			Z16->Z16_LOTCTL   := (_cAlEtqPlt)->Z16_LOTCTL
			Z16->Z16_VLDLOT   := StoD((_cAlEtqPlt)->Z16_VLDLOT)
			Z16->Z16_QTSEGU   := (_cAlEtqPlt)->Z16_QTSEGU
			Z16->(MsUnLock())

			// variavel de retorno
			_lRet := .T.
		EndIf

		// proxmo registro
		dbSelectArea(_cAlEtqPlt)
		(_cAlEtqPlt)->(dbSkip())
	EndDo

Return( _lRet )

// função para carga inicial de inventário Klabin
// para ativação do WMS "manual" em 27/12/2017
// Luiz Poleza
User function FTKlabin

	local _lRet     := .F.
	local _nRecno   := 2142
	local _cNumSeq  := ""
	local _cCounter :=""

	_lret := MsgYesNo("Confirma klabin?")

	If (_lRet)

		// inicia transacao especifica por endereco
		BEGIN TRANSACTION

			DbSelectArea("SBJ")

			While ( _nRecno <= 2263 )

				//vai para o registro da SBJ (de 2142 a 2263 para este inventario)
				SBJ-> (DBGoTo(_nRecno))

				// Obtem numero sequencial do movimento
				_cNumSeq  := ProxNum()
				// Numero do Item do Movimento
				_cCounter := StrZero(1,TamSx3('DB_ITEM')[1])

				// Cria registro de movimentacao por Localizacao (SDB)           ³
				CriaSDB(;
				SBJ->BJ_COD,;	         // Produto
				"02",;                   // Armazem
				SBJ->BJ_QINI,;           // Quantidade
				"BLOCOA",;               // Localizacao
				"",;                     // Numero de Serie
				"",;                     // Doc
				"",;                     // Serie
				"",;                     // Cliente / Fornecedor
				"",;                     // Loja
				"",;                     // Tipo NF
				"ACE",;                  // Origem do Movimento
				dDataBase,;              // Data
				SBJ->BJ_LOTECTL,;        // Lote
				"",;                     // Sub-Lote
				_cNumSeq,;               // Numero Sequencial
				"499",;                  // Tipo do Movimento
				"M",;                    // Tipo do Movimento (Distribuicao/Movimento)
				_cCounter,;              // Item
				.F.,;                    // Flag que indica se e' mov. estorno
				0,;                      // Quantidade empenhado
				SBJ->BJ_QISEGUM )        // Quantidade segunda UM

				//³Soma saldo em estoque por localizacao fisica (SBF)            ³
				GravaSBF("SDB")

				_nRecno++
			EndDo
			// finaliza transacao especifica por endereco
		END TRANSACTION

	Endif

	Alert("Fim do processo")

Return

// função que retorna se um determinado endereço está sob processo de inventário não finalizado
// Retorno TRUE = endereço consta em inventário
// Retorno FALSE = endereço não está sob inventário
// variável mvNumOS , passada por parâmetro, pode ser utilizada capturar o número da OS em que consta o endereço de inventário
User Function FTEndInv (mvLocaliz, mvLocal, mvNumOs)

	local _lRet    := .F.
	local _cQuery  := ""
	local _aRetQry := {}

	Default mvNumos := ""

	_cQuery := "SELECT TOP 1 Z21_IDENT "
	_cQuery += "FROM " + RetSqlTab("Z21") + " (nolock) "
	_cQuery += "       INNER JOIN " + RetSqlTab("Z05") + " (nolock) "
	_cQuery += "               ON " + RetSqlCond("Z05")
	_cQuery += "                  AND Z05_NUMOS = Z21_IDENT "
	_cQuery += "                  AND Z05_TPOPER = 'I'      "
	_cQuery += "       INNER JOIN " + RetSqlTab("Z06") + " (nolock) "
	_cQuery += "               ON " + RetSqlCond("Z06")
	_cQuery += "                  AND Z06_NUMOS = Z05_NUMOS "
	_cQuery += "                  AND Z06_STATUS NOT IN ( 'FI', 'CA' )     "
	_cQuery += " WHERE " + RetSqlCond("Z21")
	_cQuery += "       AND Z21_LOCAL  = '" + mvLocal + "'"
	_cQuery += "       AND Z21_LOCALI = '" + mvLocaliz + "'"
	_cQuery += " ORDER  BY Z21_IDENT ASC "

	// verifica se encontrou resultados (endereços em inventário)
	_aRetQry := U_SqlToVet(_cQuery)
	_lRet := ( Len(_aRetQry) > 0)

	If (_lRet)
		mvNumos := _aRetQry[1]
	EndIf


Return ( _lRet )


// ** funcao que envia email com as etiquetas do cliente conferidas na ordem de serviço
User Function FTMailEt(_cNumOS, _cSeqOS, _cCodCli, _cLojCli)

	// area inicial
	local _aArea    := GetArea()

	// query
	local _cQuery := ""

	// dados do pedido
	local _aTmpDados := {}
	local _nItPed

	// html da mensagem de email
	local _cHtml := ""

	// destinatarios
	local _cDestin := ""

	// status da os
	local _cStatus := ""
	local _cTPOper := ""

	// prepara query
	_cQuery := " SELECT RTRIM(Z07_NUMOS) OS,CONVERT(VARCHAR(10), CONVERT(DATE, Z06_DTFIM), 103) Z06_DTFIM,Z06_HRFIM,RTRIM(Z56_CODETI) Etiqueta_Pallet, RTRIM(Z56_ETQCLI) Etiqueta_Cliente, "
	_cQuery += " RTRIM(Z56_CODPRO) Produto,RTRIM(B1_DESC) Descricao,Z56_QUANT Quantidade "
	_cQuery += " FROM " + RetSQLTab("Z07") + " (nolock) "
	// itens da ordem de serviço
	_cQuery += " inner join " + RetSQLTab("Z06") + " (nolock) "
	_cQuery += " on " + RetSqlCond("Z06")
	_cQuery += " and Z06_FILIAL = Z07_FILIAL "
	_cQuery += " and Z06_NUMOS = Z07_NUMOS "
	_cQuery += " and Z06_SEQOS = Z07_SEQOS "
	// etiquetas do cliente
	_cQuery += " inner join " + RetSQLTab("Z56") + " (nolock) "
	_cQuery += " on " + RetSqlCond("Z56")
	_cQuery += " and Z56_FILIAL = Z07_FILIAL "
	_cQuery += " and Z56_CODCLI = Z07_CLIENT "
	_cQuery += " and Z56_LOJCLI = Z07_LOJA "
	_cQuery += " and Z56_CODETI = Z07_ETQPRD "
	// cadastro de produtos
	_cQuery += " inner join "  + RetSQLTab("SB1") + " (nolock) "
	_cQuery += " on " + RetSqlCond("SB1")
	_cQuery += " and B1_COD = Z56_CODPRO "
	// conferência (Z07)
	_cQuery += " where " + RetSqlCond("Z07")
	_cQuery += " and Z07_NUMOS = '"  + _cNumOS  + "' "
	_cQuery += " and Z07_SEQOS = '"  + _cSeqOS  + "' "
	_cQuery += " and Z07_CLIENT = '" + _cCodCli + "' "
	_cQuery += " and Z07_LOJA = '"   + _cLojCli + "' "
	_cQuery += " order by Z56_CODETI,Z07_DATA,Z07_HORA "

	// atualiza variavel com dados do pedido
	// estrutura do _aTmpDados
	// 1 - Número OS
	// 2 - Data finalização
	// 3 - Hora finalização
	// 4 - Etiqueta_Pallet
	// 5 - Etiqueta_Cliente
	// 6 - Produto
	// 7 - Descricao
	// 8 - Quantidade
	_aTmpDados := U_SqlToVet(_cQuery)

	MemoWrit("c:\query\ftmailet.txt", _cQuery)

	// se não teve dados para enviar email
	IF (Len(_aTmpDados) == 0)
		Return ( .F. )
	EndIf

	_cTPOper := Posicione("Z05", 1, xFilial("Z05") + _aTmpDados[1][1], "Z05_TPOPER")

	// nomenclatura do relatório
	If (_cTPOper) == "E"
		_cStatus := "Finalizado Conferencia de Entrada"
	ElseIf (_cTPOper) == "S"
		_cStatus := "Finalizado Conferencia de Saida"
	EndIf

	// posiciona no cadastro do cliente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1))     // 1 - A1_FILIAL, A1_COD, A1_LOJA
	SA1->(dbSeek( xFilial("SA1") + _cCodCli + _cLojCli ))

	// inicio da mensagem de email
	_cHtml += '<table width="780px" align="center">'
	_cHtml += '   <tr>'
	_cHtml += '      <td>'
	_cHtml += '         <table style="border-collapse: collapse;font-family: Tahoma; font-size: 12px;" border="1" width="100%" cellpadding="2" cellspacing="0" align="center" >'
	_cHtml += '            <tr>'
	_cHtml += '               <td height="30" colspan="2" style="background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Status de Separacao e Preparacao de Pedidos</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Filial</td>'
	_cHtml += '               <td width="80%" >' + AllTrim(SM0->M0_CODFIL) + "-" + AllTrim(SM0->M0_FILIAL) + '</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Data/Hora</td>'
	_cHtml += '               <td width="80%" >' + AllTrim(_aTmpDados[1][2]) + ' as ' + AllTrim(_aTmpDados[1][3]) + ' h</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Depositante</td>'
	_cHtml += '               <td width="80%" >' + SA1->A1_COD + ' / ' + SA1->A1_LOJA + ' - ' + AllTrim(SA1->A1_NOME) + '</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Ordem de Servico </td>'
	_cHtml += '               <td width="80%" >' + _cNumOS + '</td>'
	_cHtml += '            </tr>'
	// se conferência de saída, informa o pedido do cliente
	If (_cTPOper) == "S"
		_cQuery := "SELECT C5_ZPEDCLI FROM " + RetSqlTab("SC5") + " WHERE " + RetSqlCond("SC5") 
		_cQuery += " AND C5_ZNOSEXP = '" + _cNumOS + "'"
		_cQuery += " AND C5_CLIENTE = '" + _cCodCli + "'"
		_cQuery += " AND C5_LOJACLI = '" + _cLojCli + "'"

		_cHtml += '            <tr>'
		_cHtml += '               <td width="20%" >Pedido do cliente </td>'
		_cHtml += '               <td width="80%" >' + AllTrim(U_FTQuery(_cQuery)) + '</td>'
		_cHtml += '            </tr>'
	Endif
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Status</td>'
	_cHtml += '               <td width="80%" ><span style="background-color: #80d22d">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>&nbsp;'
	_cHtml += _cStatus
	_cHtml += '</td>'
	_cHtml += '            </tr>'
	_cHtml += '         </table>'
	_cHtml += '         <br>'
	_cHtml += '         <table style="border-collapse: collapse;font-family: Tahoma; font-size: 12px;" border="1" width="100%" cellpadding="2" cellspacing="0" align="center" >'
	_cHtml += '            <tr>'
	_cHtml += '               <td height="20" colspan="7" style="background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Relacao de etiquetas/itens conferidas</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr style="background-color: #87CEEB;">'
	_cHtml += '               <td width="10%" >Etiqueta Tecadi</td>'
	_cHtml += '               <td width="10%" >Barcode Pneu</td>'
	_cHtml += '               <td width="10%" >Produto</td>'
	_cHtml += '               <td width="60%" >Descricao</td>'
	_cHtml += '               <td width="10%" >Quantidade</td>'
	_cHtml += '            </tr>'

	// varre todos os itens dos detalhes
	For _nItPed := 1 to Len(_aTmpDados)
		// estrutura do _aTmpDados
		// 1 - Número OS
		// 2 - Data finalização
		// 3 - Hora finalização
		// 4 - Etiqueta_Pallet
		// 5 - Etiqueta_Cliente
		// 6 - Produto
		// 7 - Descricao
		// 8 - Quantidade

		// insere item / linha na mensagem
		_cHtml += '            <tr>'
		_cHtml += '               <td width="10%" >' + AllTrim(_aTmpDados[_nItPed][4]) + '</td>'
		_cHtml += '               <td width="10%" >' + AllTrim(_aTmpDados[_nItPed][5]) + '</td>'
		_cHtml += '               <td width="10%" >' + AllTrim(_aTmpDados[_nItPed][6]) + '</td>'
		_cHtml += '               <td width="45%" >' + AllTrim(_aTmpDados[_nItPed][7]) + '</td>'
		_cHtml += '               <td width="5%" >' + AllTrim(Str(_aTmpDados[_nItPed][8])) + '</td>'
		_cHtml += '            </tr>'
	Next _nItPed

	_cHtml += '         </table>'
	_cHtml += '         <br>'
	_cHtml += '      </td>'
	_cHtml += '   </tr>'
	_cHtml += '</table>'

	// prepara relacao de destinatarios
	_cDestin := AllTrim(SA1->A1_USRCONT)

	// envio de email
	U_FtMail(_cHtml, "TECADI - Resumo de conferencia - " + _cNumOS + " - " + DtoC(Date()), _cDestin)

	// restaura areas iniciais
	RestArea(_aArea)

Return( .T. )


// ** funcao que envia email informando quais pedidos foram carregados e os dados do veículo
// para o cliente acompanhar o rastreamento com a transportadora
User Function FTMail02(mvCesv)

	// area inicial
	local _aArea    := GetArea()

	// query
	local _cQry    := ""
	local _aRetQry := {}
	local _nX

	// html da mensagem de email
	local _cHtml := ""

	// destinatarios
	local _cDestin := ""

	// prepara query
	_cQry := " SELECT Z43_CESV,             "  //1
	_cQry += "        Z43_CLIENT,           "
	_cQry += "        Z43_LOJA,             "
	_cQry += "        Z43_PEDIDO,           "
	_cQry += "        Z43_PEDCLI,           "  //5
	_cQry += "        Z43_SEQAGE,           "
	_cQry += "        REPLACE( CONVERT(VARCHAR, CONVERT(DATE,ZZ_DTCHEG,103),105),'-','/') ZZ_DTCHEG,"
	_cQry += "        ZZ_HRCHEG,            "
	_cQry += "        ZZ_TRANSP,            "
	_cQry += "        ZZ_MOTORIS,           "  //10
	_cQry += "        ZZ_PLACA1,            "
	_cQry += "        REPLACE( CONVERT(VARCHAR, CONVERT(DATE,ZZ_DTSAI,103),105),'-','/') DT_SAI,"
	_cQry += "        ZZ_HRSAI,             "
	_cQry += "        A4_NOME,              "
	_cQry += "        DA4_NOME,             "  //15
	_cQry += "        C5_NOTA,              "
	_cQry += "        Left(C5_ZCLIENT, 60), "
	_cQry += "        C5_VOLUME1,           "
	_cQry += "        C5_ZDOCCLI            "  //19
	_cQry += " FROM " + RetSqlTab("Z43") + " (NOLOCK) "
	_cQry += "     INNER JOIN " + RetSqlTab("SZZ") + " (NOLOCK) "
	_cQry += "                ON " + RetSqlCond("SZZ")
	_cQry += "                   AND SZZ.ZZ_CESV = Z43_CESV     "
	_cQry += "     INNER JOIN " + RetSqlTab("SA4") + " (NOLOCK) "
	_cQry += "                ON " + RetSqlCond("SA4")
	_cQry += "                   AND SA4.A4_COD = SZZ.ZZ_TRANSP "
	_cQry += "     INNER JOIN " + RetSqlTab("DA4") + " (NOLOCK) "
	_cQry += "                ON " + RetSqlCond("DA4")
	_cQry += "                   AND DA4_COD = SZZ.ZZ_MOTORIS   "
	_cQry += "     INNER JOIN " + RetSqlTab("SC5") + " (NOLOCK) "
	_cQry += "                ON " + RetSqlCond("SC5")
	_cQry += "                   AND SC5.C5_NUM = Z43_PEDIDO    "
	_cQry += " WHERE " + RetSqlCond("Z43")
	_cQry += "        AND Z43_CESV = '" + mvCesv + "'"
	_cQry += "        AND Z43_STATUS = 'R'"

	_aRetQry := U_SqlToVet(_cQry)

	MemoWrit("c:\query\ftmail02.txt", _cQry)

	// se não teve dados para enviar email
	IF (Len(_aRetQry) == 0)
		Return ( .F. )
	EndIf

	// posiciona no cadastro do cliente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1))     // 1 - A1_FILIAL, A1_COD, A1_LOJA
	SA1->(dbSeek( xFilial("SA1") + _aRetQry[1][2] + _aRetQry[1][3] ))

	// inicio da mensagem de email
	_cHtml += '<table width="780px" align="center">'
	_cHtml += '   <tr>'
	_cHtml += '      <td>'

	// *** início cabeçalho
	_cHtml += '         <table style="border-collapse: collapse;font-family: Tahoma; font-size: 12px;" border="1" width="100%" cellpadding="2" cellspacing="0" align="center" >'
	_cHtml += '            <tr>'
	_cHtml += '               <td height="30" colspan="2" style="background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Informações de despacho de pedidos</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Filial</td>'
	_cHtml += '               <td width="80%" >' + AllTrim(SM0->M0_CODFIL) + "-" + AllTrim(SM0->M0_FILIAL) + '</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Depositante</td>'
	_cHtml += '               <td width="80%" >' + SA1->A1_COD + ' / ' + SA1->A1_LOJA + ' - ' + AllTrim(SA1->A1_NOME) + '</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Transportadora</td>'
	_cHtml += '               <td width="80%" >' + AllTrim(_aRetQry[1][14]) + '</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Motorista</td>'
	_cHtml += '               <td width="80%" >' + AllTrim(_aRetQry[1][15]) + '</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Placa</td>'
	_cHtml += '               <td width="80%" >' + AllTrim(_aRetQry[1][11]) + '</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Data/Hora Entrada</td>'
	_cHtml += '               <td width="80%" >' + AllTrim(_aRetQry[1][7]) + ' as ' + AllTrim(_aRetQry[1][8]) + ' h</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Data/Hora Saída</td>'
	_cHtml += '               <td width="80%" >' + AllTrim(_aRetQry[1][12]) + ' as ' + AllTrim(_aRetQry[1][13]) + ' h</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td width="20%" >Controles </td>'
	_cHtml += '               <td width="80%" >CESV: ' + AllTrim(_aRetQry[1][1]) + ' - Agendamento: ' + AllTrim(_aRetQry[1][6]) + '</td>'
	_cHtml += '            </tr>'
	_cHtml += '         </table>'

	// *** fim cabeçalho

	// *** inicio corpo
	_cHtml += '         <br>'
	_cHtml += '         <table style="border-collapse: collapse;font-family: Tahoma; font-size: 12px;" border="1" width="100%" cellpadding="2" cellspacing="0" align="center" >'
	_cHtml += '            <tr>'
	_cHtml += '               <td height="20" colspan="7" style="background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Informações da carga</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr style="background-color: #87CEEB;">'
	_cHtml += '               <td width="10%" align="center">Seu pedido</td>'
	_cHtml += '               <td width="10%" align="center">Sua nota fiscal</td>'
	_cHtml += '               <td width="60%" align="center">Cliente final</td>'
	_cHtml += '               <td width="10%" align="center">Pedido Tecadi</td>'
	_cHtml += '               <td width="10%" align="center">NF Tecadi retorno</td>'
	_cHtml += '            </tr>'

	// varre todos os itens dos detalhes
	For _nX := 1 to Len(_aRetQry)
		// insere item / linha na montagem do HTML
		_cHtml += '            <tr>'
		_cHtml += '               <td width="10%" align="center">' + AllTrim(_aRetQry[_nX][5])  + '</td>'
		_cHtml += '               <td width="10%" align="center">' + AllTrim(_aRetQry[_nX][19]) + '</td>'
		_cHtml += '               <td width="60%" >' + AllTrim(_aRetQry[_nX][17]) + '</td>'
		_cHtml += '               <td width="10%" align="center">' + AllTrim(_aRetQry[_nX][4])  + '</td>'
		_cHtml += '               <td width="10%" align="center">' + AllTrim(_aRetQry[_nX][16]) + '</td>'
		_cHtml += '            </tr>'
	Next _nItPed

	_cHtml += '         </table>'
	_cHtml += '         <br>'
	_cHtml += '      </td>'
	_cHtml += '   </tr>'
	_cHtml += '</table>'

	// rodapé
	_cHtml += '<div align="center"><span style="font-family: Tahoma; font-size: 11px; background-color: #FFFFFF; color: #000000;">'
	_cHtml += 'Os dados aqui informados representam a data/hora em que foram inseridos no sistema, e não necessariamente quando ocorreram.'
	_cHtml += '<BR>'
	_cHtml += 'Podem haver pequenas variações no intervalo de tempo apresentado.'
	_cHtml += '</span> </div> <BR>'
	_cHtml += '<div align="center"><span style="font-family: Tahoma; font-size: 11px; background-color: #FFFFFF; color: #000000;">Não responda este E-mail - Mensagem automática utilizando o serviço de Workflow TECADI - Proudly made by TECADI IT Team</span> </div>'

	// prepara relacao de destinatarios
	_cDestin := AllTrim(SA1->A1_USRCONT)

	// envio de email
	U_FtMail(_cHtml, "TECADI - Sua carga foi despachada! (" + mvCesv + ")", _cDestin)


Return( .T. )

//----------------------------------------------------------------------------------//
// Programa: TECF01()  |   Autor: Gustavo Schumann    |   Data: 05/09/2018			//
//----------------------------------------------------------------------------------//
// Descrição: Atalho para executar funções, mesmo funcionamento do antigo formulas.	//
//----------------------------------------------------------------------------------//

User Function TECF01()
	Local oFont12	:= TFont():New('Arial',,-12,,.F.)
	Local oFont12n	:= TFont():New('Arial',,-12,,.T.)
	Local cFunc		:= Space(254)

	oDlgF01	:= MSDialog():new(75,30,120,550,"Executar função",,,,,CLR_BLACK,CLR_WHITE,,,.t.)
	oGet	:= TGet():New(005,005,{|u|if(PCount()>0,cFunc:=u,cFunc)},oDlgF01,190,005,"@!",,CLR_BLACK,CLR_WHITE,oFont12,,,.T.,,,{||},,,{||},.F.,.F.,,'',,,,.T.,.F.)
	oSBtn	:= SButton():New(005,198,1,{|| IIF(!EMPTY(cFunc),TECF01A(cFunc),MsgAlert("Nenhuma instrução a executar")) },oDlgF01,.T.,,)
	oSBtn	:= SButton():New(005,228,2,{||oDlgF01:End()},oDlgF01,.T.,,)
	oDlgF01:Activate()

Return

Static Function TECF01A(cFunc)
	Local aFunc	:= {'cFunction'}
	Local xExec
	Private cFunction:= cFunc

	xExec := &(&(aFunc[1]))

Return .T.


//----------------------------------------------------------------------------------//
// Programa: U_EncProg()  |   Autor: Felippe - LOGINFO    |   Data: 19/02/2019	    //
//----------------------------------------------------------------------------------//
// Descrição: Função para encerrar em massa programações em aberto sem saldo.    	//
//----------------------------------------------------------------------------------//

user function EncProg()

	Processa( {|| sfEncProg() }, "Aguarde, encerrando programações sem saldo...", "Pré processamento...",.F.)

static function sfEncProg()
	local _cTranspPro := '000023'
	local cMensagem := ""
	local nTotReg := 0

	// controle de validacao
	local _lOk := .t.

	// controle de mensagem do cabecalho
	local _lCabOk := .f.

	// nota fiscais de entrada na programacao
	local _aDocEntrada := {}
	local _nDocEntrada

	// indica programacao aberta
	local _aProgAberta := {}

	// grupo de estoque do cliente
	local _aGrpEstCli := {}
	local _cGrpEstCli := ""

	// saldo dos itens da nota fiscal
	local _aSldItens := {}
	local _aPerg := {}
	private _cPerg := PadR("TENCPROG",10)

	cHorIni := Time()
	cMensagem += "Inicio: "+Time()+CRLF

	// monta a lista de perguntas
	aAdd(_aPerg,{"Contrato de ?" ,"C",TamSx3("AAM_CONTRT")[1],0,"G",,"AAM",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par01
	aAdd(_aPerg,{"Contrato Até ?" ,"C",TamSx3("AAM_CONTRT")[1],0,"G",,"AAM",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par02

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// abre os parametros
	if !Pergunte(_cPerg,.T.)
		Return
	endif

	If Empty(mv_par01)
		_cQryWhile =  " select * from V_FAT_PROG_EM_ABERTO where filial = "+ cFilAnt +" and saldo <= 0 order by contrat,prog"
		_cQryTot =  " select count(*) as total from V_FAT_PROG_EM_ABERTO where filial = "+ cFilAnt +" and saldo <= 0"
	Else
		_cQryWhile =  " select * from V_FAT_PROG_EM_ABERTO where filial = "+ cFilAnt +" and contrat between '"+ mv_par01 +"' and '"+ mv_par02 +"' and saldo <= 0 order by contrat,prog"
		_cQryTot =  " select count(*) as total from V_FAT_PROG_EM_ABERTO where filial = "+ cFilAnt +" and contrat between '"+ mv_par01 +"' and '"+ mv_par02 +"' and saldo <= 0"
	EndIf

	memoWrit("c:\query\EncProg_While.txt",_cQryWhile)
	memoWrit("c:\query\EncProg_TotalReg.txt",_cQryTot)

	// verifica se o alias da query existe
	If (Select("_QRYWHILE")<>0)
		dbSelectArea("_QRYWHILE")
		dbCloseArea()
	EndIf
	// executa a query
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQryWhile),"_QRYWHILE",.F.,.T.)
	dbSelectArea("_QRYWHILE")

	// verifica se o alias da query existe
	If (Select("_QRYTOTAL")<>0)
		dbSelectArea("_QRYTOTAL")
		dbCloseArea()
	EndIf
	// executa a query
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQryTot),"_QRYTOTAL",.F.,.T.)
	dbSelectArea("_QRYTOTAL")

	nTotReg := _QRYTOTAL->total 

	_QRYWHILE->(dbGotop())

	ProcRegua(nTotReg)

	While _QRYWHILE->(!Eof())

		// controle da regua de processamento
		IncProc("Processo: "+_QRYWHILE->prog+" - Contrato: "+_QRYWHILE->contrat)

		// posiciona no cadastro do cliente
		dbSelectArea("SA1")
		SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
		SA1->(dbSeek( xFilial("SA1") + _QRYWHILE->Z1_CLIENTE + _QRYWHILE->Z1_LOJA ))

		// atualiza o grupo de estoque do cliente
		_aGrpEstCli := U_SqlToVet("SELECT Z36_CODIGO FROM "+RetSqlTab("Z36")+" (nolock)  WHERE "+RetSqlCond("Z36")+" AND Z36_SIGLA = '" + SA1->A1_SIGLA + "'")
		// converte array em string
		aEval(_aGrpEstCli,{|_aGrpEstCli| _cGrpEstCli += _aGrpEstCli + ";" })

		// 1. Valida se o processo possui ordens de servico em aberto
		_cQuery := "SELECT Z6_NUMOS, Z6_EMISSAO "
		// ordens de servico
		_cQuery += "FROM "+RetSqlName("SZ6")+" SZ6 (nolock)  "
		// filtro de ordens de servico em aberto
		_cQuery += "WHERE "+RetSqlCond("SZ6")+" "
		// sem data de finalizacao
		_cQuery += "AND Z6_DTFINAL = ' ' "
		// status de OS Aberta
		_cQuery += "AND Z6_STATUS  = 'A' "
		// filtra o cliente
		_cQuery += "AND Z6_CLIENTE = '" + _QRYWHILE->Z1_CLIENTE + "' AND Z6_LOJA = '" + _QRYWHILE->Z1_LOJA + "' "
		// filtra o processo
		_cQuery += "AND Z6_CODIGO  = '" + _QRYWHILE->prog + "' "
		// ordem dos dados
		_cQuery += "ORDER BY Z6_NUMOS "
		// executa a query
		_aOrdAbert := U_SqlToVet(_cQuery,{"Z6_EMISSAO"})

		memowrit("c:\query\EncProg_os_em_aberto.txt",_cQuery)

		// apresenta mensagem caso tiver OS em aberto
		If (Len(_aOrdAbert) > 0)
			// incrementa LOG
			If _lCabOk
				cMensagem += ""
			Else
				cMensagem += "[001-ORDENS DE SERVICOS EM ABERTO] Prog: "+ _QRYWHILE->prog +" Contrato: "+ _QRYWHILE->contrat +CRLF
			Endif

			// atualiza todas as OS na mensagem
			aEval(_aOrdAbert,{|_aOrdAbert| cMensagem += " Nr OS: "+_aOrdAbert[1]+"  Data Abertura: "+DtoC(_aOrdAbert[2])+CRLF })
			// variavel de retorno
			_lOk := .f.
			// cabecalho ok
			_lCabOk := .t.
		EndIf

		// reinicia variavel
		_lCabOk := .f.

		// 2. Valida se tem OS com saldo a faturar
		_cQuery := "SELECT Z6_NUMOS, Z6_EMISSAO "
		// cabecalho da OS
		_cQuery += "FROM "+RetSqlName("SZ6")+" SZ6 (nolock)  "
		// itens da OS
		_cQuery += "INNER JOIN "+RetSqlName("SZ7")+" SZ7 (nolock)  ON "+RetSqlCond("SZ7")+" AND Z7_NUMOS = Z6_NUMOS AND (Z7_DTFATAT = ' ' OR Z7_SALDO > 0) "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("SZ6")+" "
		_cQuery += "AND Z6_CLIENTE = '" + _QRYWHILE->Z1_CLIENTE + "' AND Z6_LOJA = '" + _QRYWHILE->Z1_LOJA + "' "
		_cQuery += "AND Z6_CODIGO  = '" + _QRYWHILE->prog + "' "
		// ordem dos dados
		_cQuery += "ORDER BY Z6_NUMOS "
		// executa a query
		_aOrdAbert := U_SqlToVet(_cQuery,{"Z6_EMISSAO"})

		memowrit("c:\query\EncProg_os_com_saldo_faturar.txt",_cQuery)

		// apresenta mensagem caso tiver OS em aberto
		If (Len(_aOrdAbert) > 0)
			// incrementa LOG
			If _lCabOk
				cMensagem += ""
			Else
				cMensagem += "[002-ORDENS DE SERVICOS COM SALDO A FATURAR] Prog: "+ _QRYWHILE->prog +" Contrato: "+ _QRYWHILE->contrat +CRLF
			Endif

			// atualiza todas as OS na mensagem
			aEval(_aOrdAbert,{|_aOrdAbert| cMensagem += " Nr OS: "+_aOrdAbert[1]+"  Data Abertura: "+DtoC(_aOrdAbert[2])+CRLF })
			// variavel de retorno
			_lOk := .f.
			// cabecalho ok
			_lCabOk := .t.
		EndIf

		// reinicia variavel
		_lCabOk := .f.

		// 3. valida se a quantidade programada foi atendida
		dbSelectArea("SZ2")
		SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM
		SZ2->(dbSeek( _cSeekSZ2 := xFilial("SZ2") + _QRYWHILE->prog ))
		While SZ2->( ! Eof() ) .and. ((SZ2->Z2_FILIAL + SZ2->Z2_CODIGO) == _cSeekSZ2)
			// verifica a quantidade
			If (SZ2->Z2_QTDREC < SZ2->Z2_QUANT)
				// incrementa LOG
				If _lCabOk
					cMensagem += ""
				Else
					cMensagem += "[003-SALDO DE VEICULOS EM ABERTO] Prog: "+ _QRYWHILE->prog +" Contrato: "+ _QRYWHILE->contrat +CRLF
				Endif

				// detalhe do item
				cMensagem += " Item "+SZ2->Z2_ITEM+" Programado: "+Str(SZ2->Z2_QUANT,2)+" -> Recebido: "+Str(SZ2->Z2_QTDREC,2)+CRLF
				// variavel de retorno
				_lOk := .f.
				// cabecalho ok
				_lCabOk := .t.
			EndIf
			// proximo item
			SZ2->(dbSkip())
		EndDo

		// reinicia variavel
		_lCabOk := .f.


		// 4. valida se ha movimentacao de veiculos para faturar
		_cQuery := "SELECT Z3_DTMOVIM, CASE WHEN Z3_TPMOVIM = 'E' THEN 'ENTRADA' ELSE 'SAIDA' END Z3_TPMOVIM, Z3_CONTAIN "
		// movimentacao de veiculos
		_cQuery += "FROM "+RetSqlName("SZ3")+" SZ3 (nolock)  "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("SZ3")+" "
		// quando NAO for pacote de servicos, FILTAR transportadora propria
		_cQuery += "AND ((Z3_TPMOVIM = 'E' AND Z3_TRACONT = '"+_cTranspPro+"') OR (Z3_TPMOVIM = 'S' AND Z3_TRANSP = '"+_cTranspPro+"')) "
		// cobranca de frete
		_cQuery += "AND Z3_DTFATFR = ' ' "
		// codigo e loja do cliente
		_cQuery += "AND Z3_CLIENTE = '" + _QRYWHILE->Z1_CLIENTE + "' AND Z3_LOJA = '" + _QRYWHILE->Z1_LOJA + "' "
		// programacao
		_cQuery += "AND Z3_PROGRAM = '" + _QRYWHILE->prog + "' "
		// ordem dos dados
		_cQuery += "ORDER BY Z3_DTMOVIM, Z3_CONTAIN "
		// executa a query
		_aMovVeicu := U_SqlToVet(_cQuery,{"Z3_DTMOVIM"})

		memowrit("c:\query\EncProg_mov_veiculos.txt",_cQuery)

		// apresenta mensagem caso tiver movimentacao de veiculos em aberto
		If (Len(_aMovVeicu) > 0)
			// incrementa LOG
			If _lCabOk
				cMensagem += ""
			Else
				cMensagem += "[004-MOVIMENTACAO DE VEICULOS - COBRANÇA DE FRETE] Prog: "+ _QRYWHILE->prog +" Contrato: "+ _QRYWHILE->contrat +CRLF
			Endif

			// atualiza todas as movimentacoes na mensagem
			aEval(_aMovVeicu,{|_aMovVeicu| cMensagem += " Data: "+DtoC(_aMovVeicu[1])+"  "+_aMovVeicu[2]+"  Unidade: "+Transf(_aMovVeicu[3],PesqPict("SZ3","Z3_CONTAIN"))+CRLF })
			// variavel de retorno
			_lOk := .f.
			// cabecalho ok
			_lCabOk := .t.
		EndIf

		// reinicia variavel
		_lCabOk := .f.

		// 5. valida se ha movimentacao de veiculos ainda no patio
		_cQuery := "SELECT Z3_DTMOVIM, CASE WHEN Z3_TPMOVIM = 'E' THEN 'ENTRADA' ELSE 'SAIDA' END Z3_TPMOVIM, Z3_CONTAIN "
		// movimentacao de veiculos
		_cQuery += "FROM "+RetSqlName("SZ3")+" SZ3 (nolock)  "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("SZ3")+" "
		// ainda no patio
		_cQuery += "AND Z3_DTSAIDA = ' ' "
		// codigo e loja do cliente
		_cQuery += "AND Z3_CLIENTE = '" + _QRYWHILE->Z1_CLIENTE + "' AND Z3_LOJA = '" + _QRYWHILE->Z1_LOJA + "' "
		// programacao
		_cQuery += "AND Z3_PROGRAM = '" + _QRYWHILE->prog + "' "
		// ordem dos dados
		_cQuery += "ORDER BY Z3_DTMOVIM, Z3_CONTAIN "
		// executa a query
		_aMovVeicu := U_SqlToVet(_cQuery,{"Z3_DTMOVIM"})

		memowrit("c:\query\EncProg_mov_veiculos_patio.txt",_cQuery)

		// apresenta mensagem caso tiver movimentacao de veiculos no patio
		If (Len(_aMovVeicu) > 0)
			// incrementa LOG
			If _lCabOk
				cMensagem += ""
			Else
				cMensagem += "[005-VEICULOS/CONTAINER NO PATIO] Prog: "+ _QRYWHILE->prog +" Contrato: "+ _QRYWHILE->contrat +CRLF
			Endif

			// atualiza todas as movimentacoes na mensagem
			aEval(_aMovVeicu,{|_aMovVeicu| cMensagem += " Data: "+DtoC(_aMovVeicu[1])+"  "+_aMovVeicu[2]+"  Unidade: "+Transf(_aMovVeicu[3],PesqPict("SZ3","Z3_CONTAIN"))+CRLF })
			// variavel de retorno
			_lOk := .f.
			// cabecalho ok
			_lCabOk := .t.
		EndIf

		// reinicia variavel
		_lCabOk := .f.

		// 6. valida se ha saldo de produtos para faturar
		_cQuery := "SELECT F1_DOC, F1_SERIE "
		// notas fiscais
		_cQuery += "FROM "+RetSqlName("SF1")+" SF1 (nolock)  "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("SF1")+" "
		// codigo e loja do cliente
		_cQuery += "AND F1_FORNECE = '" + _QRYWHILE->Z1_CLIENTE + "' AND F1_LOJA = '" + _QRYWHILE->Z1_LOJA + "' "
		// programacao
		_cQuery += "AND F1_PROGRAM = '" + _QRYWHILE->prog + "' "
		// tipo da nota
		_cQuery += "AND F1_TIPO    = 'B' "
		// ordem dos dados
		_cQuery += "ORDER BY F1_DTDIGIT, F1_DOC "
		// executa a query
		_aDocEntrada := U_SqlToVet(_cQuery)

		memowrit("c:\query\EncProg_saldo_notas.txt",_cQuery)

		// apresenta mensagem caso tiver saldo de produtos a faturar
		For _nDocEntrada := 1 to Len(_aDocEntrada)

			// saldo dos itens da nota fiscal
			_aSldItens := {}

			// calculo o saldo da nota
			_nSaldo := StaticCall(TFATA002,sfSaldoNota,Date()+30,;
			Nil                          ,;
			_QRYWHILE->Z1_CLIENTE        ,;
			_QRYWHILE->Z1_LOJA           ,;
			_aDocEntrada[_nDocEntrada,1] ,;
			_aDocEntrada[_nDocEntrada,2] ,;
			"4"                          ,;
			.f.                          ,;
			Nil                          ,;
			_cGrpEstCli                  ,;
			@_aSldItens                   )

			// incrementa LOG
			If (_nSaldo > 0)
				If _lCabOk
					cMensagem += ""
				Else
					cMensagem += "[006-SALDO DE MERCADORIA] Prog: "+ _QRYWHILE->prog +" Contrato: "+ _QRYWHILE->contrat +CRLF
				Endif

				// atualiza todas as movimentacoes na mensagem
				cMensagem += " Nota Fiscal: "+_aDocEntrada[_nDocEntrada,1]+"/"+_aDocEntrada[_nDocEntrada,2]+" Saldo: "+Transf(_nSaldo,PesqPict("SD1","D1_QUANT"))+CRLF
				// variavel de retorno
				_lOk := .f.
				// cabecalho ok
				_lCabOk := .t.
			EndIf

		Next _nDocEntrada

		// reinicia variavel
		_lCabOk := .f.

		// 7. valida se ha saldo de produtos a enderecar
		_cQuery := " SELECT DA_DOC, DA_SERIE, Sum(DA_SALDO) DA_SALDO "
		// notas fiscais
		_cQuery += " FROM " + RetSqlTab("SD1") + " (nolock) "
		// saldo a enderecar do WMS
		_cQuery += "        INNER JOIN " + RetSqlTab("SDA") + " (nolock) "
		_cQuery += "                ON " + RetSqlCond("SDA")
		_cQuery += "                   AND DA_PRODUTO = D1_COD "
		_cQuery += "                   AND DA_NUMSEQ = D1_NUMSEQ "
		_cQuery += "                   AND DA_SALDO != 0 "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("SD1")
		// codigo e loja do cliente
		_cQuery += " AND D1_FORNECE = '" + _QRYWHILE->Z1_CLIENTE + "' AND D1_LOJA = '" + _QRYWHILE->Z1_LOJA + "' "
		// programacao
		_cQuery += " AND D1_PROGRAM = '" + _QRYWHILE->prog + "' "
		// tipo da nota
		_cQuery += " AND D1_TIPO    = 'B' "
		// agrupa dados
		_cQuery += " GROUP BY DA_DOC, DA_SERIE "

		// executa a query
		_aDocEntrada := U_SqlToVet(_cQuery)

		memowrit("c:\query\EncProg_saldo_notas_wms.txt",_cQuery)

		// apresenta mensagem caso tiver saldo de produtos a faturar
		For _nDocEntrada := 1 to Len(_aDocEntrada)

			// saldo da nota
			_nSaldo := _aDocEntrada[_nDocEntrada, 3]

			// incrementa LOG
			If (_nSaldo > 0)
				// define cabecalho
				If _lCabOk
					cMensagem += ""
				Else
					cMensagem += "[007-SALDO DE MERCADORIA WMS (FALTA ENDEREÇAMENTO)] Prog: "+ _QRYWHILE->prog +" Contrato: "+ _QRYWHILE->contrat +CRLF
				Endif

				// atualiza todas as movimentacoes na mensagem
				cMensagem += " Nota Fiscal: "+_aDocEntrada[_nDocEntrada,1] + "/" + _aDocEntrada[_nDocEntrada,2] + " Saldo: " + Transf(_nSaldo, PesqPict("SD1","D1_QUANT")) + CRLF
				// variavel de retorno
				_lOk := .f.
				// cabecalho ok
				_lCabOk := .t.
			EndIf

		Next _nDocEntrada


		// reinicia variavel
		_lCabOk := .f.

		// 8. valida se exite armazenagem calculada pendente de faturamento
		_cQuery := " SELECT 1 as ARMZ_ABERTA"
		_cQuery += " FROM " + RetSqlTab("SZH") + " (nolock) "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("SZH")
		// cálculo de armazenagem em aberto
		_cQuery += " AND (ZH_PRODUTO = '' OR ZH_PEDIDO = '' ) "
		// programacao
		_cQuery += " AND ZH_PROCES = '" + _QRYWHILE->prog + "' "

		// executa a query
		_aProg := U_SqlToVet(_cQuery)

		memowrit("c:\query\EncProg_armz_pendente.txt",_cQuery)

		// apresenta mensagem caso tiver armazenagem calculada sem faturamento
		If Len(_aProg) > 0
			cMensagem += "[008-SERVICO DE ARMAZENAGEM CALCULADO SEM FATURAMENTO] Prog: "+ _QRYWHILE->prog +" Contrato: "+ _QRYWHILE->contrat +CRLF
			_lOk := .f.
		Endif

		// reinicia variavel
		_lCabOk := .f.

		// 9. valida se exite seguro calculada pendente de faturamento
		_cQuery := " SELECT 1 as SEGUR_ABERTA"
		_cQuery += " FROM " + RetSqlTab("SZI") + " (nolock) "
		// filtro padrao
		_cQuery += " WHERE " + RetSqlCond("SZI")
		// cálculo de armazenagem em aberto
		_cQuery += " AND (ZI_PRODUTO = '' OR ZI_PEDIDO = '' ) "
		// programacao
		_cQuery += " AND ZI_PROCES = '" + _QRYWHILE->prog + "' "

		// executa a query
		_aProg := U_SqlToVet(_cQuery)

		memowrit("c:\query\EncProg_segur_pendente.txt",_cQuery)

		// apresenta mensagem caso tiver armazenagem calculada sem faturamento
		If Len(_aProg) > 0
			cMensagem += "[009-SERVICO DE SEGURO CALCULADO SEM FATURAMENTO] Prog: "+ _QRYWHILE->prog +" Contrato: "+ _QRYWHILE->contrat +CRLF
			_lOk := .f.
		Endif

		// se ocorreu algum erro, apresenta mensagem
		If ( ! _lOk )

			cMensagem += "ATENÇÃO: Não é possível finalizar o processo! Prog: "+ _QRYWHILE->prog +" Contrato: "+ _QRYWHILE->contrat +CRLF+CRLF

			// se estiver tudo Ok
		ElseIf (_lOk)
			// atualiza da data de encerramento do processo
			dbSelectArea("SZ1")
			SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
			SZ1->(dbSeek( xFilial("SZ1") + _QRYWHILE->prog ))
			RecLock("SZ1")
			SZ1->Z1_DTFINFA	:= Date()
			SZ1->Z1_USFINFA	:= __cUserId
			SZ1->(MsUnLock())

			// gera o LOG de finalizacao do processo
			//U_FtGeraLog(cFilAnt, "SZ1", SZ1->(Z1_FILIAL+Z1_CODIGO), "ENCERRAMENTO GERAL DO PROCESSO", "FAT", "Z1_CODIGO")

			// mensagem
			cMensagem += "Encerramento realizado com sucesso! Encerramento Geral Prog: "+ _QRYWHILE->prog +" Contrato: "+ _QRYWHILE->contrat +CRLF+CRLF
		EndIf

		_QRYWHILE->( dbSkip() )

	EndDo

	cMensagem += "Final: "+Time()+CRLF+" Tempo Total: "+ElapTime(cHorIni,Time())

	memoWrit("c:\query\EncProg_LogGeral.txt",cMensagem)

	MsgInfo("Fim do processamento: "+Time()+CRLF+" Tempo Total: "+ElapTime(cHorIni,Time()))

return
