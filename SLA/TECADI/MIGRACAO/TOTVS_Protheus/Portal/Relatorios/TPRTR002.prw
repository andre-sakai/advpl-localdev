#INCLUDE "PROTHEUS.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "TOTVS.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Impressao dos historico completo dos detalhes do fatura-!
!                  ! mento da programação                                    !
!                  ! Cópia literal do relatório TFATR003, porém adaptado para!
!                  ! acesso web                                              !
+------------------+---------------------------------------------------------+
!Autor             ! Luiz Poleza                                             !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 10/02/11                                                !
+------------------+---------------------------------------------------------+
!Data Atualização  ! 19/07/13											     !
+---------------------------------------------------------------------------*/

User Function TPRTR002

	Local cProg  // programação

	Local nOpc			:= 0
	Local aMensagens 	:= {}	
	Local aBotoes 		:= {}	

	// tela de confirmação
	aAdd( aMensagens, "Esta rotina irá gerar o relatório de detalhes financeiros da programação.")
	aAdd( aMensagens, "")
	aAdd( aMensagens, "Ao clicar em continuar e informar a programação, o sistema irá processar e enviar")
	aAdd( aMensagens, "o relatório em formato PDF para o(s) e-mail(s) cadastrado para seu usuário.")
	aAdd( aBotoes, { 1, .T., { || nOpc := 1, FechaBatch() } } )
	aAdd( aBotoes, { 2, .T., { || nOpc := 2, FechaBatch() } } )

	FormBatch("Relatório de detalhes da programação", aMensagens, aBotoes)

	// se confirmou
	If (nOpc == 1)	
		// valida o login do usuario (se pode utilizar a rotina/portal do usuário)
		If ( ! U_FtPrtVld(__cUserId) )
			Return( .F. )
		EndIf
	elseif (nOpc == 2)
		Return
	EndIf

	// pergunta a programação
	cProg := FWInputBox("Informe a programação desejada:","")  

	If ( Empty(cProg) )
		MsgAlert("Não foi informada a programação!")
		Return
	EndIf

	// posiciona na programação para validar se pode exibir (conforme cliente/usuário logado no portal)
	DbSelectArea("SZ1")
	SZ1->(dbSetOrder(1))  // 1 - Z1_FILIAL, Z1_CODIGO, R_E_C_N_O_, D_E_L_E_T_

	//se não encontrou
	If !(SZ1->(dbSeek(xFilial("SZ1") + cProg)))
		MsgAlert("Número de programação inválido. Verifique e tente novamente")
		Return
	Else
		DbSelectArea("SA1")
		SA1->(DBSetOrder(1))
		SA1->( dbSeek(xFilial("SA1") + SZ1->Z1_CLIENTE) )

		// valida se cliente liberado para o usuário que está rodando o relatório
		If ( aScan( ___aPrtSigla, {|x| (x == SA1->A1_SIGLA) } ) == 0)
			MsgAlert("Você não tem permissão para acessar esta programação ou ela não pertence a sua empresa." + CRLF + "Para clientes que operam em várias filiais, verifique se está conectado na filial correta e tente novamente.")
			Return
		EndIf

	EndIf

	// chama a rotina que posiciona o pedido de venda para impressão
	Processa({ || U_PRTR002(cProg, 1) },"Gerando relatório...",,.T.)

Return ()

//** funcao responsavel pelo posicionamento no processo e impressao dos detalhes
User Function PRTR002(mvProcesso, mvMostraFin)
	// area inicial do SZ1
	Local _aAreaSZ1 := SZ1->(GetArea())
	// quantidade itens a processar
	local _nQtdReg := 0
	// seek do SZ1
	local _cSeekSZ1

	local _aArq := {}
	Local cFileOP, cFileTMP, cArqTMP,cArqRel

	// Cria Objeto para impressao Grafica
	Private _oPrn
	// fontes utilizadas
	Private _oFont01n
	Private _oFont02
	Private _oFont02n
	// imagem da logo
	Private _cImagem := "\"+AllTrim(CurDir())+"\logo_tecadi.jpg"
	// contrato e item
	private _cNrCont := ""
	private _cItCont := ""
	// resumo financeiro
	private _aResumoFin := {}
	// valor total
	private _aValorTot := {}
	// maximo de linhas
	private _nMaxLin := 3100
	// resumo por tipo de servico
	private _aResumoSrv := {}
	// mostra a situação financeira
	private _lMosSitFin := (mvMostraFin == 1)

	//Executa as funções quando a situação é escondida
	private _cExeRetFin := ""

	// variaveis para gerenciar a criação do PDF
	Private lAdjustToLegacy		:= .T.
	Private lDisableSetup 		:= .T.
	Private lServer 			:= .T.
	Private lPDFAsPNG			:= .F.
	Private lViewPDF			:= .F.
	Private cDirPrint			:= ""

	// diretorio para gerar o arquivo temporariamente dentro do protheusdata
	cDirPrint	:= "\temp\"

	cFileOP		:= mvProcesso +".pdf"
	cFileTMP	:= mvProcesso +".rel"
	cArqRel		:= cDirPrint + cFileOP 
	cArqTMP 	:= cDirPrint + cFileOP 

	//Apaga arquivos Temporarios se existir
	FErase(cArqRel)
	FErase(cArqTMP)

	// Cria Objeto para impressao Grafica
	_oPrn := FWMsPrinter():New(cFileOP, IMP_PDF, lAdjustToLegacy, cDirPrint,lDisableSetup, /*[lTReport]*/, /*[@oPrintSetup]*/, /*[ cPrinter]*/, lServer, lPDFAsPNG, /*[ lRaw]*/, lViewPDF, /*[ nQtdCopy]*/ )

	//Impressão com o componente FWMsPrinter PDF
	// fontes utilizadas

	_oFont01n  := TFont():New("Arial" ,,17,,.T.,,,,.F.,.F.)
	_oFont02   := TFont():New("Arial" ,,13,,.F.,,,,.F.,.F.)
	_oFont02n  := TFont():New("Arial" ,,13,,.T.,,,,.F.,.F.)
	_oPrn:SetResolution(78) //Tamanho estipulado para a Danfe
	_oPrn:SetPortrait()
	_oPrn:SetPaperSize(DMPAPER_A4)
	_oPrn:SetMargin(60,60,60,60)
	_oPrn:nDevice  := IMP_PDF
	_oPrn:cPathPDF := cDirPrint
	_oPrn:GetViewPDF(.F.)
	_oPrn:SetViewPDF(.F.)


	// calcula a quantidade de pedidos a processar
	_nQtdReg := U_FtQuery("SELECT COUNT(*) QTD_REG FROM "+RetSqlName("SC5")+" SC5 WHERE "+RetSqlCond("SC5")+" AND C5_ZPROCES = '"+mvProcesso+"' AND C5_TIPOOPE = 'S'")

	If (_nQtdReg <= 0)
		MsgStop("Sem informações para imprimir")
		Return()
	EndIf

	// defina a quatidade de registro da regua de processamento
	ProcRegua(_nQtdReg)

	// posiciona no processo
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	SZ1->(dbSeek( _cSeekSZ1 := xFilial("SZ1")+mvProcesso ))

	// varre todos os processo informados nos parametros
	While SZ1->(!Eof()).and.(SZ1->(Z1_FILIAL+Z1_CODIGO)==_cSeekSZ1)

		// incrementa a regua
		IncProc("Programação: "+SZ1->Z1_CODIGO)

		// chama a rotina para impressao dos detalhes do processo
		sfImprimir()

		// proxima processo
		SZ1->(dbSkip())
	EndDo

	_oPrn:Print()

	// restaura area inicial
	RestArea(_aAreaSZ1)

	aAdd(_aArq, cArqRel )

	// envia por email
	U_FTMail("Segue em anexo o relatório de detalhamento de programação solicitado no portal de clientes Tecadi",;
	"TECADI - Relatório de detalhamento de programação",;
	___aPrtLogin[8],;
	_aArq)
	
	MsgInfo("Relatório gerado com sucesso e agendado para envio por e-mail." + CRLF + "Aguarde até 5 minutos para o recebimento.")
	
	// apaga arquivo temporário
	FErase(cArqRel)
	FErase(cFileTMP)
	
Return

//** funcao para impressao dos dados
Static Function sfImprimir()
	// controle de quebra de paginas
	Local _cNumProc := ""
	// servicos do historico
	local _aSrvHist := {}
	local _nSrvHist := {}
	// quebra do pedido
	local _cQuebraPed := ""
	// variaveis temporarias
	local _nResFin
	local _nResTot
	// area incial
	local _aAreaSB1
	// seek do SD2
	local _cSeekSD2
	// total geral
	local _nTotGeral := 0
	// detalhes do pacote logistico
	Local _aDetPacLog := {}
	// variaveis temporarias
	Local _nX, _nY, _nTmpLin
	// resumo total por produto
	local _nPosResSrv := 0
	// detalhes do produto
	Local _aDetalhes := {}
	// Armazena pedido
	local _cNrPed := ""
	// controle de linha
	Private _nLin := 4000

	// busca todos os serviços do faturamento
	_cQrySZR := "SELECT DISTINCT ZR_CODSRV, ZR_DESCRI, ZR_CONTRT, ZR_ITEM "
	_cQrySZR += "FROM "+RetSqlName("SZR")+" SZR "
	// pedido de venda
	_cQrySZR += "INNER JOIN "+RetSqlName("SC5")+" SC5 ON "+RetSqlCond("SC5")+" AND C5_NUM = ZR_PEDIDO "
	// somente servico
	_cQrySZR += "AND C5_TIPOOPE = 'S' "
	// ignora pedidos eliminados por residuo
	_cQrySZR += "AND C5_NOTA <> '"+Replicate("X",TamSx3("C5_NOTA")[1])+"' "
	// filtro padrao
	_cQrySZR += "WHERE "+RetSqlCond("SZR")+" "
	// filtra pelo processo
	_cQrySZR += "AND ZR_PROGRAM = '"+SZ1->Z1_CODIGO+"' "
	// ordem dos dados
	_cQrySZR += "ORDER BY ZR_CODSRV"
	// armazena os servicos
	_aSrvHist := U_SqlToVet(_cQrySZR)

	// impressao dos detalhes de cada servico
	For _nSrvHist := 1 to Len(_aSrvHist)

		// impressao do cabecalho
		If (_nLin >= _nMaxLin).or.(_cNumProc <> SZ1->Z1_CODIGO)
			// funcao para impressao do cabecalho
			sfCabec( !Empty(_cNumProc) )
			// controle da quebra de paginas
			_cNumProc := SZ1->Z1_CODIGO
		EndIf

		// atualiza o numero e item do contrato
		_cNrCont := _aSrvHist[_nSrvHist][3]
		_cItCont := _aSrvHist[_nSrvHist][4]

		// posiciona no cadastro de produtos
		dbSelectArea("SB1")
		SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
		SB1->(dbSeek( xFilial("SB1")+_aSrvHist[_nSrvHist][1] ))

		// impressao do cabecalho do items
		_oPrn:Say(_nLin,0020,"Serviço: "+AllTrim(SB1->B1_COD)+" "+AllTrim(_aSrvHist[_nSrvHist][2]),_oFont02n)
		_nLin += 50

		// zera a variavel de detalhes
		_aDetalhes := {}

		// 1-ARMAZENAGEM DE CONTAINER
		If (SB1->B1_TIPOSRV=="1")
			// busca os detalhes da armazenagem de container
			_aDetalhes := sfDetArmCnt()
			// zera variavels
			_cQuebraPed := ""

			// impressao dos dados
			For _nX := 1 to Len(_aDetalhes)
				// dados do pedido, nota e sit financeira
				If (_cQuebraPed <> _aDetalhes[_nX][1])
					// inclui espaco para separar o pedido
					_nLin += 20

					//Incremente número do pedido
					_cNrPed += _aDetalhes[_nX][1] + "-"

					// imprime dados do pedido
					_oPrn:Say(_nLin,0050,"Pedido de Venda: "+_aDetalhes[_nX][1]+;
					"  Nota Fiscal: "+_aDetalhes[_nX][2]+"/"+_aDetalhes[_nX][3] ,_oFont02)

					// executa funcao para retornar a Situacao Financeira
					_cExeRetFin := "Situação Financeira: "+sfRetPosFin(_aDetalhes[_nX][2],_aDetalhes[_nX][3],_aDetalhes[_nX][1])

					If (_lMosSitFin)
						_oPrn:Say(_nLin,1700,_cExeRetFin,_oFont02n,,,,1)
						//_oPrn:SayAlign(_nLin,1700,_cExeRetFin  ,_oFont02n,1000,200,,)
					Endif

					_nLin += 50
					// controle de quebra
					_cQuebraPed := _aDetalhes[_nX][1]
				EndIf

				// imprime linha
				_oPrn:Say(_nLin,0080,_aDetalhes[_nX][4],_oFont02)
				_nLin += 50

				// impressao do cabecalho
				If (_nLin >= _nMaxLin)
					// funcao para impressao do cabecalho
					sfCabec(.t.)
				EndIf

			Next _nX

			// 2-ARMAZENAGEM DE PRODUTO
		ElseIf (SB1->B1_TIPOSRV=="2")
			// busca os detalhes da armazenagem de produtos
			_aDetalhes := sfDetArmPrd()
			// zera variavels
			_cQuebraPed := ""

			// impressao dos dados
			For _nX := 1 to Len(_aDetalhes)
				// imprime a periodicidade
				If (_nX==1)
					// imprime linha do cabecalho
					_oPrn:Say(_nLin,0080,_aDetalhes[_nX][4],_oFont02)
					_nLin += 50
					// impressao do cabecalho
					If (_nLin >= _nMaxLin)
						// funcao para impressao do cabecalho
						sfCabec(.t.)
					EndIf
				EndIf

				// dados do pedido, nota e sit financeira
				If (_cQuebraPed <> _aDetalhes[_nX][1])
					// inclui espaco para separar o pedido
					_nLin += 20

					//Incremente número do pedido
					_cNrPed += _aDetalhes[_nX][1] + "-"

					// imprime dados do pedido
					_oPrn:Say(_nLin,0050,"Pedido: "+_aDetalhes[_nX][1]+;
					"  Nota Fiscal: "+_aDetalhes[_nX][2]+"/"+_aDetalhes[_nX][3] ,_oFont02)

					// executa rotina Situação Financeira
					_cExeRetFin := "Situação Financeira: "+sfRetPosFin(_aDetalhes[_nX][2],_aDetalhes[_nX][3],_aDetalhes[_nX][1])

					//Se o usuário quer que mostre a situação financeira
					if (_lMosSitFin)
						_oPrn:Say(_nLin,1700,_cExeRetFin ,_oFont02n,,,,1)
						//_oPrn:SayAlign(_nLin,1700,_cExeRetFin  ,_oFont02n,1000,200,,)
					EndIf

					_nLin += 50

					// controle de quebra
					_cQuebraPed := _aDetalhes[_nX][1]
				EndIf

				// imprime linha
				_oPrn:Say(_nLin,0080,_aDetalhes[_nX][5],_oFont02)
				_nLin += 50

				// impressao do cabecalho
				If (_nLin >= _nMaxLin)
					// funcao para impressao do cabecalho
					sfCabec(.t.)
				EndIf

			Next _nX

			// 3-PACOTE LOGISTICO
		ElseIf (SB1->B1_TIPOSRV=="3")

			// area inicial do cad de produto
			_aAreaSB1 := SB1->(GetArea())

			// retorna os produto do pacote logistico
			// estrutura
			// 1-numero do pacote
			// 2-produtos
			_aDetPacLog := sfPrdPacLog()

			// impressao dos detalhes
			For _nX := 1 to Len(_aDetPacLog)

				// posiciona no cadastro de produtos
				dbSelectArea("SB1")
				SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
				SB1->(dbSeek( xFilial("SB1")+_aDetPacLog[_nX][2] ))

				// zera vetor dos detalhes
				_aDetalhes := {}

				// 4-FRETES
				If (SB1->B1_TIPOSRV=="4")
					// busca os detalhes dos fretes
					_aDetalhes := sfDetFrete(_aDetPacLog[_nX][1])

					// 7-SERVICOS DIVERSOS
				ElseIf (SB1->B1_TIPOSRV=="7")
					// busca os detalhes dos servicos
					_aDetalhes := sfDetServicos(_aDetPacLog[_nX][1])

				Else
					MsgStop("Erro no relatório. Ver item "+SB1->B1_TIPOSRV)
				EndIf

				// zera variavels
				_cQuebraPed := ""

				// impressao dos dados
				For _nY := 1 to Len(_aDetalhes)

					// dados do pedido, nota e sit financeira
					If (_cQuebraPed <> _aDetalhes[_nY][1])
						// inclui espaco para separar o pedido
						_nLin += 20

						// outros servicos
						If (SB1->B1_TIPOSRV != "7")
							//Incremente número do pedido
							_cNrPed += _aDetalhes[_nX][1] + "-"

							// imprime dados do pedido
							_oPrn:Say(_nLin,0050,"Pedido: "+_aDetalhes[_nY][1]+;
							"  Nota Fiscal: "+_aDetalhes[_nY][2]+"/"+_aDetalhes[_nY][3] ,_oFont02)
							// executa rotina Situação Financeira
							_cExeRetFin := "Situação Financeira: "+sfRetPosFin(_aDetalhes[_nY][2],_aDetalhes[_nY][3],_aDetalhes[_nY][1])

							//Se o usuário quer que mostre a situação financeira
							if (_lMosSitFin)
								_oPrn:Say(_nLin,1700,_cExeRetFin,_oFont02n,,,,1)
								//_oPrn:SayAlign(_nLin,1700,_cExeRetFin  ,_oFont02n,1000,200,,)
							EndIf

							// 7-SERVICOS DIVERSOS
						ElseIf (SB1->B1_TIPOSRV=="7")
							// imprime dados do pedido
							_oPrn:Say(_nLin,0050,"Atividade: "+_aDetalhes[_nY][1]+;
							"  Nota Fiscal: "+_aDetalhes[_nY][2]+"/"+_aDetalhes[_nY][3] ,_oFont02)

							// executa rotina Situação Financeira
							_cExeRetFin := "Situação Financeira: "+sfRetPosFin(_aDetalhes[_nY][2],_aDetalhes[_nY][3],_aDetalhes[_nY][4])

							//Se o usuário quer que mostre a situação financeira
							if (_lMosSitFin)
								_oPrn:Say(_nLin,1700,_cExeRetFin,_oFont02n,,,,1)
								//_oPrn:SayAlign(_nLin,1700,_cExeRetFin  ,_oFont02n,1000,200,,)
							EndIf

						EndIf

						// controle da linha
						_nLin += 50

						// controle de quebra
						_cQuebraPed := _aDetalhes[_nY][1]

						// impressao do item do pacote
						_oPrn:Say(_nLin,0080,AllTrim(_aDetPacLog[_nX][2])+" - "+Posicione("SB1",1, xFilial("SB1")+_aDetPacLog[_nX][2] ,"B1_DESC"),_oFont02)
						_nLin += 50

					EndIf

					// imprime linha
					_oPrn:Say(_nLin,0080,_aDetalhes[_nY][Len(_aDetalhes[_nY])],_oFont02)
					_nLin += 50

					// impressao do cabecalho
					If (_nLin >= _nMaxLin)
						// funcao para impressao do cabecalho
						sfCabec(.t.)
					EndIf

				Next _nY

				// linha entre itens do pacote logistico
				_nLin += 30
			Next _nX

			// restaura area inicial do cad de produto
			RestArea(_aAreaSB1)

			// 4-FRETE
		ElseIf (SB1->B1_TIPOSRV=="4")
			// busca os detalhes dos fretes
			_aDetalhes := sfDetFrete("")
			// zera variavels
			_cQuebraPed := ""

			// impressao dos dados
			For _nX := 1 to Len(_aDetalhes)
				// dados do pedido, nota e sit financeira
				If (_cQuebraPed <> _aDetalhes[_nX][1])
					// inclui espaco para separar o pedido
					_nLin += 20

					//Incremente número do pedido
					_cNrPed += _aDetalhes[_nX][1] + "-"

					// imprime dados do pedido
					_oPrn:Say(_nLin,0050,"Pedido: "+_aDetalhes[_nX][1]+;
					"  Nota Fiscal: "+_aDetalhes[_nX][2]+"/"+_aDetalhes[_nX][3],_oFont02)

					// executa rotina Situação Financeira
					_cExeRetFin := "Situação Financeira: "+sfRetPosFin(_aDetalhes[_nX][2],_aDetalhes[_nX][3],_aDetalhes[_nX][1])

					//Se o usuário quer que mostre a situação financeira
					if (_lMosSitFin)
						_oPrn:Say(_nLin,1700,_cExeRetFin,_oFont02n,,,,1)
						//_oPrn:SayAlign(_nLin,1700,_cExeRetFin  ,_oFont02n,1000,200,,)
					EndIf

					_nLin += 50
					// controle de quebra
					_cQuebraPed := _aDetalhes[_nX][1]
				EndIf
				// imprime linha
				_oPrn:Say(_nLin,0080,_aDetalhes[_nX][4],_oFont02)
				_nLin += 50

				// impressao do cabecalho
				If (_nLin >= _nMaxLin)
					// funcao para impressao do cabecalho
					sfCabec(.t.)
				EndIf

			Next _nX

			// 5-SEGUROS
		ElseIf (SB1->B1_TIPOSRV=="5")
			// busca os detalhes do seguro
			// 1-pedido
			// 2-nota fiscal
			// 3-serie nota
			// 4-data inicial
			// 5-periodicidade
			// 6-detalhes
			_aDetalhes := sfDetSeguro()
			// zera variavels
			_cQuebraPed := ""

			// impressao dos dados
			For _nX := 1 to Len(_aDetalhes)
				// imprime a periodicidade
				If (_nX==1)
					// imprime linha do cabecalho
					_oPrn:Say(_nLin,0080,_aDetalhes[_nX][5],_oFont02)
					_nLin += 50
					// impressao do cabecalho
					If (_nLin >= _nMaxLin)
						// funcao para impressao do cabecalho
						sfCabec(.t.)
					EndIf
				EndIf

				// dados do pedido, nota e sit financeira
				If (_cQuebraPed <> _aDetalhes[_nX][1])
					// inclui espaco para separar o pedido
					_nLin += 20

					//Incremente número do pedido
					_cNrPed += _aDetalhes[_nX][1] + "-"

					// imprime dados do pedido
					_oPrn:Say(_nLin,0050,"Pedido: "+_aDetalhes[_nX][1]+;
					"  Nota Fiscal: "+_aDetalhes[_nX][2]+"/"+_aDetalhes[_nX][3],_oFont02)

					// executa rotina Situação Financeira
					_cExeRetFin := "Situação Financeira: "+sfRetPosFin(_aDetalhes[_nX][2],_aDetalhes[_nX][3],_aDetalhes[_nX][1])

					//Se o usuário quer que mostre a situação financeira
					if (_lMosSitFin)
						_oPrn:Say(_nLin,1700,_cExeRetFin,_oFont02n,,,,1)
						//_oPrn:SayAlign(_nLin,1700,_cExeRetFin  ,_oFont02n,1000,200,,)
					EndIf
					_nLin += 50
					// controle de quebra
					_cQuebraPed := _aDetalhes[_nX][1]
				EndIf
				// imprime linha
				_oPrn:Say(_nLin,0080,_aDetalhes[_nX][6],_oFont02)
				_nLin += 50

				// impressao do cabecalho
				If (_nLin >= _nMaxLin)
					// funcao para impressao do cabecalho
					sfCabec(.t.)
				EndIf

			Next _nX

		ElseIf (SB1->B1_TIPOSRV=="6")

			// 7-SERVICOS DIVERSOS
		ElseIf (SB1->B1_TIPOSRV=="7")
			// busca os detalhes dos servicos
			_aDetalhes := sfDetServicos("")
			// zera variavels
			_cQuebraPed := ""

			// impressao dos dados
			For _nX := 1 to Len(_aDetalhes)
				// dados do pedido, nota e sit financeira
				If (_cQuebraPed <> _aDetalhes[_nX][1])
					// inclui espaco para separar o pedido
					_nLin += 20

					// imprime dados do pedido
					_oPrn:Say(_nLin,0050,"Atividade: "+_aDetalhes[_nX][1]+;
					"  Nota Fiscal: "+_aDetalhes[_nX][2]+"/"+_aDetalhes[_nX][3] ,_oFont02)

					// executa rotina Situação Financeira
					_cExeRetFin := "Situação Financeira: "+sfRetPosFin(_aDetalhes[_nX][2],_aDetalhes[_nX][3],_aDetalhes[_nX][4])

					//Se o usuário quer que mostre a situação financeira
					if (_lMosSitFin)
						_oPrn:Say(_nLin,1700,_cExeRetFin,_oFont02n,,,,1)
						//_oPrn:SayAlign(_nLin,1700,_cExeRetFin  ,_oFont02n,1000,200,,)
					EndIf

					_nLin += 50

					// controle de quebra
					_cQuebraPed := _aDetalhes[_nX][1]
				EndIf

				// imprime linha
				_oPrn:Say(_nLin,0080,_aDetalhes[_nX][5],_oFont02)
				_nLin += 50

				// impressao do cabecalho
				If (_nLin >= _nMaxLin)
					// funcao para impressao do cabecalho
					sfCabec(.t.)
				EndIf

			Next _nX
		ElseIf (SB1->B1_TIPOSRV=="8")

		ElseIf (SB1->B1_TIPOSRV=="9")

		EndIf

		// linha entre itens do pedido
		_nLin += 60

	Next _nSrvHist

	// re-ordena os dados do resumo por nota
	aSort(_aResumoFin,,,{|x,y| x[1] < y[1] })

	// impressao do cabecalho
	If (Len(_aResumoFin)>0).and.((_nLin+120) >= _nMaxLin)
		// funcao para impressao do cabecalho
		sfCabec(.t.)
	EndIf

	// impressao do resumo financeiro
	For _nResFin := 1 to Len(_aResumoFin)
		// imprime titulo do resumo
		If (_nResFin==1)

			// linha separadora do resumo
			_oPrn:Line(_nLin-30,0020,_nLin-30,2400)

			// titulo
			_oPrn:Say(_nLin,0020,"Resumo Financeiro",_oFont02n)
			// controle de linha
			_nLin += 60
		EndIf

		// impressao do cabecalho
		If (_nLin >= _nMaxLin)
			// funcao para impressao do cabecalho
			sfCabec(.t.)
		EndIf

		// executa rotina Situação Financeira
		_cExeRetFin := "Situação Financeira: "+_aResumoFin[_nResFin][5]+;
		If(_aResumoFin[_nResFin][4]>0," R$ "+AllTrim(Transf(_aResumoFin[_nResFin][4],PesqPict("SE1","E1_VALOR"))),"")+;
		If(_aResumoFin[_nResFin][6]>0," R$ "+AllTrim(Transf(_aResumoFin[_nResFin][6],PesqPict("SE1","E1_VALOR"))),"")


		//Se o usuário quer que mostre a situação financeira
		if (_lMosSitFin)
			// imprime dados do resumo
			_oPrn:Say(_nLin,0020,"Nota Fiscal: "+DtoC(_aResumoFin[_nResFin][1])+"  "+_aResumoFin[_nResFin][2]+"/"+_aResumoFin[_nResFin][3] + " - " + _cExeRetFin,_oFont02)
			//_oPrn:Say(_nLin,0700,_cExeRetFin,_oFont02)
		Else
			_oPrn:Say(_nLin,0020,"Nota Fiscal: "+DtoC(_aResumoFin[_nResFin][1])+"  "+_aResumoFin[_nResFin][2]+"/"+_aResumoFin[_nResFin][3],_oFont02)
		EndIf

		// controle de linha
		_nLin += 60

		// imprime os itens da nota fiscal
		dbSelectArea("SD2")
		SD2->(dbSetOrder(3)) //3-D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, D2_COD, D2_ITEM, R_E_C_N_O_, D_E_L_E_T_
		SD2->(dbSeek( _cSeekSD2 := xFilial("SD2")+_aResumoFin[_nResFin][2]+_aResumoFin[_nResFin][3] ))
		While SD2->(!Eof()).and.(SD2->(D2_FILIAL+D2_DOC+D2_SERIE) == _cSeekSD2)

			// Verifica campo pedido
			If (SD2->D2_PEDIDO $ _cNrPed)
				// impressao do cabecalho
				If (_nLin >= _nMaxLin)
					// funcao para impressao do cabecalho
					sfCabec(.t.)
				EndIf

				// itens
				_oPrn:Say(_nLin,0080,"Item "+SD2->D2_ITEM+;
				" - "+AllTrim(SD2->D2_COD)+;
				" "+AllTrim(Posicione("SC6",1,xFilial("SC6")+SD2->(D2_PEDIDO+D2_ITEMPV),"C6_DESCRI"))+;
				"  R$ "+AllTrim(Transf(SD2->D2_TOTAL,PesqPict("SD2","D2_TOTAL"))) , _oFont02)

				// controle de linha
				_nLin += 60

				// pesquisa se a situacao ja esta na relacao do resumo total por servico
				_nPosResSrv := aScan(_aResumoSrv, {|x|(x[1]==SD2->D2_COD)} )

				// caso nao tenha encontrado o valor, adiciona
				If (_nPosResSrv == 0)

					// adiciona item
					aAdd(_aResumoSrv,{SD2->D2_COD, ;
					AllTrim(Posicione("SC6",1,xFilial("SC6")+SD2->(D2_PEDIDO+D2_ITEMPV),"C6_DESCRI")), ;
					SD2->D2_TOTAL })
					// caso tenha o servico no resumo, atualiza o total
				ElseIf (_nPosResSrv != 0)
					// atualiza o total
					_aResumoSrv[_nPosResSrv][3] += SD2->D2_TOTAL
				EndIf

			EndIf

			// proximo item
			SD2->(dbSkip())

		EndDo

	Next _nResFin

	// re-ordena os dados do resumo por servico
	aSort(_aResumoSrv,,,{|x,y| x[1] < y[1] })

	// impressao do cabecalho
	If (Len(_aResumoSrv)>0).and.((_nLin+120) >= _nMaxLin)
		// funcao para impressao do cabecalho
		sfCabec(.t.)
	EndIf

	// impressao do resumo por produto
	For _nResTot := 1 to Len(_aResumoSrv)

		// imprime titulo do resumo total
		If (_nResTot==1)
			// linha separadora do resumo
			_oPrn:Line(_nLin-30,0020,_nLin-30,2400)

			// titulo
			_oPrn:Say(_nLin + 10,0020,"Resumo por Serviço",_oFont02n)
			// controle de linha
			_nLin += 60
		EndIf

		// impressao do cabecalho
		If (_nLin >= _nMaxLin)
			// funcao para impressao do cabecalho
			sfCabec(.t.)
		EndIf
		// imprime detalhe
		_oPrn:SayAlign(_nLin,0020,AllTrim(_aResumoSrv[_nResTot][1])+"-"+AllTrim(_aResumoSrv[_nResTot][2])+":",_oFont02n,1000,200,,)
		_oPrn:SayAlign(_nLin,0950,"R$"                                                  ,_oFont02n,1000,200,,)
		_oPrn:SayAlign(_nLin,0400,AllTrim(Transf(_aResumoSrv[_nResTot][3],PesqPict("SE1","E1_VALOR"))),_oFont02n,1000,200,,1)

		// controle de linha
		_nLin += 60

	Next _nResTot

	// controle de linha
	_nLin += 20

	// re-ordena os dados do resumo total
	aSort(_aValorTot,,,{|x,y| x[1] < y[1] })
	// zera variaveis
	_nTotGeral := 0

	// impressao do cabecalho
	If (Len(_aValorTot)>0).and.((_nLin+120) >= _nMaxLin)
		// funcao para impressao do cabecalho
		sfCabec(.t.)
	EndIf

	// impressao do resumo financeiro total
	For _nResTot := 1 to Len(_aValorTot)

		//Se o usuário quer que mostre a situação financeira
		if (_lMosSitFin)
			// imprime titulo do resumo total
			If (_nResTot==1)
				// linha separadora do resumo
				_oPrn:Line(_nLin-30,0020,_nLin-30,2400)
				// titulo
				_oPrn:Say(_nLin + 10,0020,"RESUMO TOTAL GERAL",_oFont02n)

				// controle de linha
				_nLin += 60
			EndIf

			// impressao do cabecalho
			If (_nLin >= _nMaxLin)
				// funcao para impressao do cabecalho
				sfCabec(.t.)
			EndIf
			// imprime detalhe
			_oPrn:SayAlign(_nLin,0020,_aValorTot[_nResTot][1]+":",_oFont02n,1000,200,,)
			_oPrn:SayAlign(_nLin,0950,"R$"                                                  ,_oFont02n,1000,200,,)
			_oPrn:SayAlign(_nLin,0400,AllTrim(Transf(_aValorTot[_nResTot][2],PesqPict("SE1","E1_VALOR"))),_oFont02n,1000,200,,1)

			// controle de linha
			_nLin += 60

			// atualiza total geral
			_nTotGeral += _aValorTot[_nResTot][2]

		EndIf

	Next _nResTot

	//Se o usuário quer que mostre a situação financeira
	if (_lMosSitFin)
		// linha final - total geral
		_oPrn:SayAlign(_nLin,0020,"TOTALIZADOR",_oFont02n,1000,200,,)
		_oPrn:SayAlign(_nLin,0950,"R$"                                                  ,_oFont02n,1000,200,,)
		_oPrn:SayAlign(_nLin,0400,AllTrim(Transf(_nTotGeral,PesqPict("SE1","E1_VALOR"))),_oFont02n,1000,200,,1)
	EndIf
Return

//** funcao que retorna os produto do pacote logistico
Static Function sfPrdPacLog()
	// variavel de retorno
	Local _aSrvPacote := {}
	// variavel temporaria
	local _cQrySzo
	// area inicial
	Local _aArea := GetArea()

	// relaciona todos os itens/servicos que compoe o pacote logistico
	_cQrySzo := "SELECT DISTINCT ZO_PACOTE, ZO_PRODUTO "
	// pacote logistico
	_cQrySzo += "FROM "+RetSqlName("SZJ")+" SZJ "
	// itens do pacote logistico
	_cQrySzo += "INNER JOIN "+RetSqlName("SZO")+" SZO ON ZO_FILIAL = ZJ_FILIAL AND ZO_PACOTE = ZJ_PACOTE AND ZO_SEQPACO = ZJ_SEQPACO AND SZO.D_E_L_E_T_ = ' ' "
	// nao trazer o item do PACOTE LOGISTICO
	_cQrySzo += "AND ZO_PRODUTO != '"+SB1->B1_COD+"' "
	// filtro o pacote do item do pedido
	_cQrySzo += "WHERE "+RetSqlCond("SZJ")+" "
	// pedido e item
	_cQrySzo += "AND ZJ_PROCES = '"+SZ1->Z1_CODIGO+"' "
	// ordem dos dados
	_cQrySzo += "ORDER BY ZO_PACOTE, ZO_PRODUTO "
	// alimenta o vetor com o resultado do SQL
	_aSrvPacote := U_SqlToVet(_cQrySzo)

	// restaura area inicial
	RestArea(_aArea)

Return(_aSrvPacote)

//** funcao para retornar os detalhes do servico
Static Function sfDetServicos(mvCodPacte)
	// variavel de retorno
	local _aRet := {}
	// referencia do tipo de movimentacao (nota, pedido ou container)
	local _cOrigRef
	// area inicial
	local _aAreaSZL := SZL->(GetArea())
	// seek SZL
	local _cSeekSZL

	// padroniza o codigo do pacote
	mvCodPacte := PadR(mvCodPacte,Len(SZL->ZL_PACOTE))

	// informacoes de fretes
	dbSelectArea("SZL")
	SZL->(dbSetOrder(1)) // 1-ZL_FILIAL, ZL_PROCES, ZL_ITPROC
	SZL->(dbSeek( _cSeekSZL := xFilial("SZL")+SZ1->Z1_CODIGO ))

	// varre todos os itens
	While SZL->(!Eof()).and.(SZL->(ZL_FILIAL+ZL_PROCES)==_cSeekSZL)

		// descarta itens temporarios
		If (Empty(SZL->ZL_STATUS))
			// proximo item
			SZL->(dbSkip())
			Loop
		EndIf

		// se FATURA estiver como NAO
		If (Empty(mvCodPacte)).and.(SZL->ZL_FATURAR=="N")
			// proximo item
			SZL->(dbSkip())
			Loop
		EndIf

		// veririca se eh pacote logistico
		If (SZL->ZL_PACOTE != mvCodPacte)
			// proximo item
			SZL->(dbSkip())
			Loop
		EndIf

		// controle do numero do contrato e item
		If (SZL->ZL_CONTRT != _cNrCont).or.(SZL->ZL_ITCONTR != _cItCont)
			// proximo item
			SZL->(dbSkip())
			Loop
		EndIf

		// posiciona no item pedido de venda
		dbSelectArea("SC6")
		SC6->(dbSetOrder(1)) //1-C6_FILIAL, C6_NUM, C6_ITEM
		If SC6->(dbSeek( xFilial("SC6")+SZL->(ZL_PEDIDO+ZL_ITEMPED) ))

			// descarta pedidos eliminados pro residuo
			If (AllTrim(SC6->C6_BLQ)=="R")
				// proximo item
				dbSelectArea("SZL")
				SZL->(dbSkip())
				Loop
			EndIf

			// define a origem
			If (SZL->ZL_TIPOMOV=="E") // entrada
				_cOrigRef := "Container: "+Transf(SZL->ZL_CONTAIN,PesqPict("SZL","ZL_CONTAIN"))
			ElseIf (SZL->ZL_TIPOMOV=="I") // interna
				_cOrigRef := "Nota/Série: "+AllTrim(SZL->ZL_NFCARRE)+"/"+AllTrim(SZL->ZL_SERCARR)
			ElseIf (SZL->ZL_TIPOMOV=="S") // saida
				_cOrigRef := "Pedido: "+AllTrim(SZL->ZL_PVCARRE)
			EndIf
			/*
			// detalhes
			aAdd(_aRet,{SZL->ZL_PEDIDO, SC6->C6_NOTA, SC6->C6_SERIE,;
			_cOrigRef +;
			"  Data: "+DtoC(SZL->ZL_DTINIOS) +;
			"  Ativid.: "+AllTrim(SZL->ZL_CODATIV)+"-"+AllTrim(Posicione("SZT",1, xFilial("SZT")+SZL->ZL_CODATIV ,"ZT_DESCRIC")) +;
			"  Quant.: "+If(SZL->ZL_UNIDCOB=="M3",AllTrim(Transf(SZL->ZL_CUBAGEM,PesqPict("SZL","ZL_CUBAGEM"))),Str(SZL->ZL_QUANT,4))+" ("+SZL->ZL_UNIDCOB+")" +;
			If(Empty(mvCodPacte),"  Tarifa: R$ "+AllTrim(Transf(SZL->ZL_VLRUNIT,PesqPict("SZL","ZL_VLRUNIT"))) ,"") +;
			If(Empty(mvCodPacte),"  Valor: R$ "+AllTrim(Transf(SZL->ZL_TOTAL,PesqPict("SZL","ZL_TOTAL"))) ,"") })
			*/
			// detalhes
			aAdd(_aRet,{SZL->ZL_CODATIV+"-"+AllTrim(Posicione("SZT",1, xFilial("SZT")+SZL->ZL_CODATIV ,"ZT_DESCRIC")),SC6->C6_NOTA, SC6->C6_SERIE, SZL->ZL_PEDIDO, ;
			_cOrigRef +;
			"  Data: "+DtoC(SZL->ZL_DTINIOS) +;
			"  Quant.: " + IIf(SZL->ZL_UNIDCOB=="M3", AllTrim(Transf(SZL->ZL_CUBAGEM,PesqPict("SZL","ZL_CUBAGEM"))), IIf( SZL->ZL_UNIDCOB=="TO", AllTrim(Transf(SZL->ZL_PESOBRU,PesqPict("SZL","ZL_PESOBRU"))),  AllTrim(Transf(SZL->ZL_QUANT,PesqPict("SZL","ZL_QUANT")))) ) + " ("+SZL->ZL_UNIDCOB+")" +;
			If(Empty(mvCodPacte),"  Tarifa: R$ "+AllTrim(Transf(SZL->ZL_VLRUNIT,PesqPict("SZL","ZL_TOTAL"))) ,"") +;
			If(Empty(mvCodPacte),"  Valor: R$ "+AllTrim(Transf(SZL->ZL_TOTAL,PesqPict("SZL","ZL_TOTAL"))) ,"") })

		EndIf

		// proximo item
		SZL->(dbSkip())
	EndDo

	// restaura area inicial
	RestArea(_aAreaSZL)

	// re-ordena os dados pedido
	aSort(_aRet,,,{|x,y| x[1]+x[4] < y[1]+y[4] })

Return(_aRet)

//** funcao para retornar os detalhes do frete
Static Function sfDetFrete(mvCodPacte)
	// variavel de retorno
	local _aRet := {}
	// area inicial
	local _aAreaSZK := SZK->(GetArea())
	// seek SZK
	local _cSeekSZK

	// padroniza o codigo do pacote
	mvCodPacte := PadR(mvCodPacte,Len(SZK->ZK_PACOTE))

	// informacoes de fretes
	dbSelectArea("SZK")
	SZK->(dbSetOrder(1)) // 1-ZK_FILIAL, ZK_PROCES, ZK_ITPROC
	SZK->(dbSeek( _cSeekSZK := xFilial("SZK")+SZ1->Z1_CODIGO ))

	// varre todos os itens
	While SZK->(!Eof()).and.(SZK->(ZK_FILIAL+ZK_PROCES)==_cSeekSZK)

		// descarta itens temporarios
		If (Empty(SZK->ZK_STATUS))
			// proximo item
			SZK->(dbSkip())
			Loop
		EndIf

		// se FATURA estiver como NAO
		If (SZK->ZK_FATURAR=="N")
			// proximo item
			SZK->(dbSkip())
			Loop
		EndIf

		// veririca se eh pacote logistico
		If (SZK->ZK_PACOTE != mvCodPacte)//.and.(SZK->ZK_SEQPACO != mvSeqPacte)
			// proximo item
			SZK->(dbSkip())
			Loop
		EndIf

		// controle do numero do contrato e item
		If (SZK->ZK_CONTRT != _cNrCont).or.(SZK->ZK_ITCONTR != _cItCont)
			// proximo item
			SZK->(dbSkip())
			Loop
		EndIf

		// no pacote logistico, mostra somente movimentacao de entrada
		If (!Empty(mvCodPacte)).and.(SZK->ZK_TPMOVIM != "E")
			// proximo item
			SZK->(dbSkip())
			Loop
		EndIf

		// posiciona no item pedido de venda
		dbSelectArea("SC6")
		SC6->(dbSetOrder(1)) //1-C6_FILIAL, C6_NUM, C6_ITEM
		If SC6->(dbSeek( xFilial("SC6")+SZK->(ZK_PEDIDO+ZK_ITEMPED) ))
			// descarta pedidos eliminados pro residuo
			If (AllTrim(SC6->C6_BLQ)=="R")
				// proximo item
				dbSelectArea("SZK")
				SZK->(dbSkip())
				Loop
			EndIf
			// detalhes
			aAdd(_aRet,{SZK->ZK_PEDIDO, SC6->C6_NOTA, SC6->C6_SERIE,;
			If(Empty(SZK->ZK_SEQPACO),"","Seq: "+SZK->ZK_SEQPACO+"  ") +;
			"Data: "+DtoC(SZK->ZK_DTMOVIM) +;
			"  "+If(SZK->ZK_TPMOVIM=="E","ENTRADA","SAIDA  ") +;
			"  Container: "+Transf(SZK->ZK_CONTAIN,PesqPict("SZC","ZC_CODIGO")) +;
			"  Tamanho: "+SZK->ZK_TAMCONT +;
			"  Conteudo: "+If(SZK->ZK_CONTEUD=="C","CHEIO","VAZIO") +;
			If(Empty(mvCodPacte),"","  -  Valor Pacote Logístico R$ "+AllTrim(Transf(sfRetVlrPac(),PesqPict("SZS","ZS_TOTAL")))) })

			// detalhes das pracas (quebra em 2 linhas)
			aAdd(_aRet,{SZK->ZK_PEDIDO, SC6->C6_NOTA, SC6->C6_SERIE,;
			"    Praça: Origem "+AllTrim(Posicione("SZB",1, xFilial("SZB")+SZK->ZK_PRCORIG ,"ZB_DESCRI")) +;
			" -> Destino "+AllTrim(Posicione("SZB",1, xFilial("SZB")+SZK->ZK_PRCDEST ,"ZB_DESCRI")) })
		EndIf

		// proximo item
		SZK->(dbSkip())
	EndDo

	// restaura area inicial
	RestArea(_aAreaSZK)

Return(_aRet)

//** funcao que retorna os detalhes da armazenagem de container
Static Function sfDetArmCnt()
	// variavel de retorno
	local _aRet := {}
	// area inicial
	local _aAreaSZG := SZG->(GetArea())
	// seek SZG
	local _cSeekSZG

	// informacoes de armazenazem de containet
	dbSelectArea("SZG")
	SZG->(dbSetOrder(1)) // 1-ZG_FILIAL, ZG_PROCES, ZG_ITPROC
	SZG->(dbSeek( _cSeekSZG := xFilial("SZG")+SZ1->Z1_CODIGO ))

	// varre todos os itens
	While SZG->(!Eof()).and.(SZG->(ZG_FILIAL+ZG_PROCES)==_cSeekSZG)

		// descarta itens temporarios
		If (Empty(SZG->ZG_STATUS))
			// proximo item
			SZG->(dbSkip())
			Loop
		EndIf

		// se FATURA estiver como NAO
		If (SZG->ZG_FATURAR=="N")
			// proximo item
			SZG->(dbSkip())
			Loop
		EndIf

		// controle do numero do contrato e item
		If (SZG->ZG_CONTRT != _cNrCont).or.(SZG->ZG_ITCONTR != _cItCont)
			// proximo item
			SZG->(dbSkip())
			Loop
		EndIf

		// posiciona no item pedido de venda
		dbSelectArea("SC6")
		SC6->(dbSetOrder(1)) //1-C6_FILIAL, C6_NUM, C6_ITEM
		If SC6->(dbSeek( xFilial("SC6")+SZG->(ZG_PEDIDO+ZG_ITEMPED) ))
			// descarta pedidos eliminados pro residuo
			If (AllTrim(SC6->C6_BLQ)=="R")
				// proximo item
				dbSelectArea("SZG")
				SZG->(dbSkip())
				Loop
			EndIf
			// detalhes
			aAdd(_aRet,{SZG->ZG_PEDIDO, SC6->C6_NOTA, SC6->C6_SERIE,;
			"Container: "+Transf(SZG->ZG_CONTAIN,PesqPict("SZC","ZC_CODIGO")) +;
			"  Data Ini: "+DtoC(SZG->ZG_DTINI) +;
			"  Data Fim: "+DtoC(SZG->ZG_DTFIM) +;
			"  Day Free: "+Str(SZG->ZG_DAYFREE,3) +;
			"  Quantidade: "+Str(SZG->ZG_QUANT,3) +;
			"  Tamanho: "+SZG->ZG_TAMCONT })
		EndIf

		// proximo item
		SZG->(dbSkip())
	EndDo

	// restaura area inicial
	RestArea(_aAreaSZG)

	// re-ordena os dados pedido
	aSort(_aRet,,,{|x,y| x[1] < y[1] })

Return(_aRet)

//** funcao que retorna os detalhes da armazenagem de produtos
Static Function sfDetArmPrd()
	// variavel de retorno
	local _aRet := {}
	// area inicial
	local _aAreaSZH := SZH->(GetArea())
	// seek SZH
	local _cSeekSZH

	// informacoes de armazenagem de produtos
	dbSelectArea("SZH")
	SZH->(dbSetOrder(1)) //1-ZH_FILIAL, ZH_PROCES, ZH_ITPROC
	SZH->(dbSeek( _cSeekSZH := xFilial("SZG")+SZ1->Z1_CODIGO ))

	// varre todos os itens
	While SZH->(!Eof()).and.(SZH->(ZH_FILIAL+ZH_PROCES)==_cSeekSZH)

		// descarta itens temporarios
		If (Empty(SZH->ZH_STATUS))
			// proximo item
			SZH->(dbSkip())
			Loop
		EndIf

		// se FATURA estiver como NAO
		If (SZH->ZH_FATURAR=="N")
			// proximo item
			SZH->(dbSkip())
			Loop
		EndIf

		// controle do numero do contrato e item
		If (SZH->ZH_CONTRT != _cNrCont).or.(SZH->ZH_ITCONTR != _cItCont)
			// proximo item
			SZH->(dbSkip())
			Loop
		EndIf

		// posiciona no item pedido de venda
		dbSelectArea("SC6")
		SC6->(dbSetOrder(1)) //1-C6_FILIAL, C6_NUM, C6_ITEM
		If SC6->(dbSeek( xFilial("SC6")+SZH->(ZH_PEDIDO+ZH_ITEMPED) ))
			// descarta pedidos eliminados pro residuo
			If (AllTrim(SC6->C6_BLQ)=="R")
				// proximo item
				dbSelectArea("SZH")
				SZH->(dbSkip())
				Loop
			EndIf
			// detalhes
			aAdd(_aRet,{SZH->ZH_PEDIDO, SC6->C6_NOTA, SC6->C6_SERIE,;
			"Periodicidade: "+Str(SZH->ZH_DIASPER,3)+" dias", ;
			"Período: "+Str(SZH->ZH_PERIODO,3) +;
			"  NF Remessa: "+SZH->ZH_DOC+"/"+SZH->ZH_SERIE +;
			"  Tarifa: R$ "+AllTrim(Transf(SZH->ZH_VLRUNIT,PesqPict("SZH","ZH_TOTAL"))) +;
			"  Saldo NF: "+AllTrim(Transf(SZH->ZH_SALDO,PesqPict("SZH","ZH_SALDO"))) +" ("+AllTrim(sfCBoxDescr("ZH_TPARMAZ",SZH->ZH_TPARMAZ,2,3))+")"+;
			"  Valor: R$ "+AllTrim(Transf(SZH->ZH_TOTAL,PesqPict("SZH","ZH_TOTAL"))) +;
			"  Dt Inic.: "+DtoC(SZH->ZH_DTINI)+;
			"  Dt Final: "+DtoC(SZH->ZH_DTFIM) })
		EndIf

		// proximo item
		SZH->(dbSkip())
	EndDo

	// restaura area inicial
	RestArea(_aAreaSZH)

	// re-ordena os dados pedido pedido
	aSort(_aRet,,,{|x,y| x[1]+x[5] < y[1]+y[5] })

Return(_aRet)

//** funcao que retorna os detalhes do seguro
Static Function sfDetSeguro()
	// variavel de retorno
	local _aRet := {}
	// area inicial
	local _aAreaSZI := SZH->(GetArea())
	// seek SZI
	local _cSeekSZI

	// informacoes de seguros
	dbSelectArea("SZI")
	SZI->(dbSetOrder(1)) // 1-ZI_FILIAL, ZI_PROCES, ZI_ITPROC
	SZI->(dbSeek( _cSeekSZI := xFilial("SZI")+SZ1->Z1_CODIGO ))

	// varre todos os itens
	While SZI->(!Eof()).and.(SZI->(ZI_FILIAL+ZI_PROCES)==_cSeekSZI)

		// descarta itens temporarios
		If (Empty(SZI->ZI_STATUS))
			// proximo item
			SZI->(dbSkip())
			Loop
		EndIf

		// se FATURA estiver como NAO
		If (SZI->ZI_FATURAR=="N")
			// proximo item
			SZI->(dbSkip())
			Loop
		EndIf

		// controle do numero do contrato e item
		If (SZI->ZI_CONTRT != _cNrCont).or.(SZI->ZI_ITCONTR != _cItCont)
			// proximo item
			SZI->(dbSkip())
			Loop
		EndIf

		// posiciona no item pedido de venda
		dbSelectArea("SC6")
		SC6->(dbSetOrder(1)) //1-C6_FILIAL, C6_NUM, C6_ITEM
		If SC6->(dbSeek( xFilial("SC6")+SZI->(ZI_PEDIDO+ZI_ITEMPED) ))
			// descarta pedidos eliminados pro residuo
			If (AllTrim(SC6->C6_BLQ)=="R")
				// proximo item
				dbSelectArea("SZI")
				SZI->(dbSkip())
				Loop
			EndIf
			// detalhes
			aAdd(_aRet,{SZI->ZI_PEDIDO, SC6->C6_NOTA, SC6->C6_SERIE, SZI->ZI_DTINI, ;
			"Periodicidade: "+Str(SZI->ZI_DIASPER,3)+" dias", ;
			"Período: "+Str(SZI->ZI_PERIODO,3) +;
			"  NF Remessa: "+SZI->ZI_DOC+"/"+SZI->ZI_SERIE +;
			"  Saldo NF: R$ "+AllTrim(Transf(SZI->ZI_SALDO,PesqPict("SZI","ZI_SALDO"))) +;
			"  Tarifa: "+AllTrim(Transf(SZI->ZI_VLRUNIT,PesqPict("SZI","ZI_TOTAL")))+" % "+;
			"  Valor: R$ "+AllTrim(Transf(SZI->ZI_TOTAL,PesqPict("SZI","ZI_TOTAL"))) +;
			"  Dt Inic: "+DtoC(SZI->ZI_DTINI) +;
			"  Dt Final: "+DtoC(SZI->ZI_DTFIM) })
		EndIf

		// proximo item
		SZI->(dbSkip())
	EndDo

	// re-ordena os dados pedido
	aSort(_aRet,,,{|x,y| x[1]+DtoS(x[4]) < y[1]+DtoS(y[4]) })

	// restaura area inicial
	RestArea(_aAreaSZI)

Return(_aRet)

//** funcao que retorna a descricao de campo combobox
Static Function sfCBoxDescr(mvCampo,mvConteudo,mvPesq,mvRet)
	Local _aAreaSX3 := SX3->(GetArea())
	// retorno em array
	// 1 -> S=Sim
	// 2 -> S
	// 3 -> Sim
	Local _aCbox := RetSx3Box(Posicione('SX3',2,mvCampo,'X3CBox()'),,,TamSx3(mvCampo)[1])
	Local _nPos  := aScan( _aCbox , {|x| AllTrim(x[mvPesq]) == AllTrim(mvConteudo) } )
	Local _cRet  := If(_nPos>0,_aCbox[_nPos,mvRet],"")
	// restaura area inicial
	RestArea(_aAreaSX3)
Return(_cRet)

//** funcao para impressao do cabecalho
Static Function sfCabec(mvEndPage)

	// finaliza pagina
	If (mvEndPage)
		_oPrn:EndPage()
	EndIf

	// cria nova Pagina
	_oPrn:StartPage()
	// reinicia linha
	_nLin := 00

	// primeira linha - box
	_oPrn:Box(_nLin,0000,_nLin+220,2400)

	// coluna - antes "DETALHES DO FATURAMENTO"
	_oPrn:Line(_nLin,0980,_nLin+220,0980)

	// data e hora de impressao
	_oPrn:SayAlign(_nLin + 10,1850,"Dt Impr: "+DtoC(Date())+" "+Time(),_oFont02,500,200,,1)
	// filial
	_oPrn:SayAlign(_nLin + 60,1850,"Filial: "+AllTrim(SM0->M0_CODFIL)+"-"+AllTrim(SM0->M0_FILIAL),_oFont02,500,200,,1)
	// titulo
	_oPrn:SayAlign(_nLin + 100,1100,"MAPA DE MOVIMENTAÇÕES",_oFont01n,1000,200,,2)
	_nLin += 220
	// logo
	_oPrn:SayBitmap(10,0170,_cImagem,691.6,222.3)

	// segunda linha - box - dados do cliente
	_oPrn:Box(_nLin,0000,_nLin+200,2400)
	_nTmpLin := 60

	// informacoes do cliente
	_oPrn:Say(_nLin+_nTmpLin,0020,"Cliente:",_oFont02)
	_oPrn:Say(_nLin+_nTmpLin,0330,SZ1->Z1_CLIENTE +"/"+SZ1->Z1_LOJA+": "+Posicione("SA1",1, xFilial("SA1")+SZ1->(Z1_CLIENTE+Z1_LOJA) ,"A1_NOME"),_oFont02n)
	_nTmpLin += 60

	// programacao
	_oPrn:Say(_nLin+_nTmpLin,0020,"Programação:",_oFont02)
	_oPrn:Say(_nLin+_nTmpLin,0330,SZ1->Z1_CODIGO,_oFont02n)
	// data abertura
	_oPrn:Say(_nLin+_nTmpLin,0600,"Data de Abertura: ",_oFont02)
	_oPrn:Say(_nLin+_nTmpLin,0900,DtoC(SZ1->Z1_DTABERT),_oFont02)
	// referencia
	_oPrn:Say(_nLin+_nTmpLin,1200,"Referência:",_oFont02)
	_oPrn:Say(_nLin+_nTmpLin,1400,SZ1->Z1_REFEREN,_oFont02n)
	// documento
	_oPrn:Say(_nLin+_nTmpLin,1800,"Documento:",_oFont02)
	_oPrn:Say(_nLin+_nTmpLin,2000,Posicione("SZ2",1, xFilial("SZ2")+SZ1->Z1_CODIGO ,"Z2_DOCUMEN"),_oFont02n)
	_nTmpLin += 60


	// controle da linha
	_nLin += 250
Return

//** funcao que retornar a situacao do titulo de cobranca
Static Function sfRetPosFin(mvNota,mvSerie,mvPedido)
	// area inicial
	local _aAreaSF2 := SF2->(GetArea())
	local _aAreaSE1 := SE1->(GetArea())
	local _aAreaSC5 := SC5->(GetArea())
	// seek do SE1
	local _cSeekSE1
	// variavel de retorno
	local _cRetSit := "XXXXX"
	// saldo financeiro
	local _nSaldo := 0
	// valor pago
	local _nVlrPago := 0
	// posicao da nota fiscal no resumo
	local _nPosNota := 0
	// resumo total
	local _nPosSit := 0
	// data
	local _dDtRef := CtoD("//")
	// prefixo e numero da fatura
	local _cPrfFatura := ""
	local _cNumFatura := ""
	// saldo da fatura
	local _nSldFatura := 0

	// pesquisa se a nota ja esta na relacao do resumo
	If ((_nPosNota := aScan(_aResumoFin, {|x|(x[2]==mvNota).and.(x[3]==mvSerie)} )) == 0)
		// posiciona na nota fiscal
		dbSelectArea("SF2")
		SF2->(dbSetOrder(1)) //1-F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA
		If SF2->(dbSeek( xFilial("SF2")+mvNota+mvSerie ))

			// se encontrou a nota
			_cRetSit := "PAGA"

			// valor total pago
			_nVlrPago := 0

			// data de emissao
			_dDtRef := SF2->F2_EMISSAO

			// posiciona no titulo da nota
			dbSelectArea("SE1")
			SE1->(dbSetOrder(2)) //1-E1_FILIAL, E1_CLIENTE, E1_LOJA, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO
			SE1->(dbSeek( _cSeekSE1 := xFilial("SE1")+SF2->(F2_CLIENTE+F2_LOJA+F2_PREFIXO+F2_DOC) ))

			// varre todas as parcelas do titulo
			While SE1->(!Eof()).and.(SE1->(E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM)==_cSeekSE1)

				// zera variaveis
				_nSldFatura := 0

				// verifica se foi gerado fatura
				If (!Empty(SE1->E1_FATURA))
					// se encontrou a FATURA, calcula o saldo da fatura
					_nSldFatura := sfSldFatura(SF2->F2_CLIENTE,SF2->F2_LOJA,SE1->E1_FATPREF,SE1->E1_FATURA)
				EndIf

				// calculo o valor do boleto
				_nSaldo += SaldoTit(SE1->E1_PREFIXO, ;
				SE1->E1_NUM, ;
				SE1->E1_PARCELA, ;
				SE1->E1_TIPO, ;
				SE1->E1_NATUREZ, ;
				"R", ;
				SE1->E1_CLIENTE, ;
				1, ;
				SE1->E1_VENCREA,, ;
				SE1->E1_LOJA,, ;
				SE1->E1_TXMOEDA)

				// valor total pago
				If (_nSldFatura == 0)
					_nVlrPago += (SE1->E1_VALOR - _nSaldo)
					// fatura com saldo em aberto
				ElseIf (_nSldFatura  > 0)
					_nSaldo += SE1->E1_VALOR
				EndIf

				// proxima parcela
				SE1->(dbSkip())
			EndDo
			// caso nao tenha encontrado a nota, pesquisa se eh pedido eliminado residuo
		ElseIf (Empty(mvNota))
			// posiciona no pedido de venda
			dbSelectArea("SC5")
			SC5->(dbSetOrder(1)) //1-C5_FILIAL, C5_NUM
			If SC5->(dbSeek(xFilial("SC5")+mvPedido))
				// faturamento pendente
				If (Empty(SC5->C5_NOTA))
					_cRetSit := "FATURAMENTO PENDENTE"
					// residuo
				ElseIf (AllTrim(SC5->C5_NOTA)=="XXXXXXXXX")
					_cRetSit := "RESIDUO"
				EndIf

				// emissao do pedido
				_dDtRef := SC5->C5_EMISSAO

			EndIF

		EndIf

		// se haver saldo
		If (_nSaldo > 0)
			_cRetSit := "SALDO EM ABERTO"
		EndIf

		// atualiza o vetor
		aAdd(_aResumoFin,{	_dDtRef ,;
		mvNota ,;
		mvSerie ,;
		_nSaldo ,;
		_cRetSit ,;
		_nVlrPago })

		// pesquisa se a situacao ja esta na relacao do resumo total
		_nPosSit := aScan(_aValorTot, {|x|(x[1]==_cRetSit)} )

		// caso nao tenha encontrado o valor, adiciona
		If (_nPosSit == 0)
			// adiciona item
			aAdd(_aValorTot,{_cRetSit, (_nSaldo+_nVlrPago) })
			// caso tenha a situacao no resumo, atualiza o total
		ElseIf (_nPosSit != 0)
			// atualiza o total
			_aValorTot[_nPosSit][2] += (_nSaldo+_nVlrPago)
		EndIf

		// caso a nota ja exista na relacao, atualiza a variavel de retorno
	Else
		_cRetSit := _aResumoFin[_nPosNota][5]
	EndIf

	// restaura area inicial
	RestArea(_aAreaSC5)
	RestArea(_aAreaSE1)
	RestArea(_aAreaSF2)

Return(_cRetSit)

//** funcao que retorna o valor do pacote logistico
Static Function sfRetVlrPac()
	// query
	local _cQrySZJ

	_cQrySZJ := "SELECT ZJ_VALOR "
	_cQrySZJ += "FROM "+RetSqlName("SZJ")+" SZJ "
	_cQrySZJ += "WHERE "+RetSqlCond("SZJ")+" "
	_cQrySZJ += "AND ZJ_PROCES  = '"+SZK->ZK_PROCES+"' AND ZJ_ITPROC  = '"+SZK->ZK_ITPROC+"' "
	_cQrySZJ += "AND ZJ_CONTRT  = '"+SZK->ZK_CONTRT+"' AND ZJ_ITCONTR = '"+SZK->ZK_ITCONTR+"' "
	_cQrySZJ += "AND ZJ_CONTAIN = '"+SZK->ZK_CONTAIN+"' "
	_cQrySZJ += "AND ZJ_PACOTE  = '"+SZK->ZK_PACOTE+"' "
	// corrigi sequencia do pacote
	//AND ZJ_SEQPACO = '"+SZK->ZK_SEQPACO+"' "
	_cQrySZJ += "AND ZJ_RIC     = '"+SZK->ZK_RIC+"' "

Return(U_FtQuery(_cQrySZJ))

//** funcao que retorna o saldo da fatura
Static Function sfSldFatura(mvCliente,mvLoja,mvPrefFat,mvNumFat)
	// area inicial
	local _aAreaSE1 := SE1->(GetArea())
	// saldo da fatura
	local _nSldFt := 0
	// seek do SE1
	local _cSeekSE1

	// posiciona no titulo da nota
	dbSelectArea("SE1")
	SE1->(dbSetOrder(2)) //1-E1_FILIAL, E1_CLIENTE, E1_LOJA, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO
	SE1->(dbSeek( _cSeekSE1 := xFilial("SE1")+mvCliente+mvLoja+mvPrefFat+mvNumFat ))

	// varre todas as parcelas do titulo
	While SE1->(!Eof()).and.(SE1->(E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM)==_cSeekSE1)
		// calculo o valor do titulo
		_nSldFt += SaldoTit(SE1->E1_PREFIXO, ;
		SE1->E1_NUM, ;
		SE1->E1_PARCELA, ;
		SE1->E1_TIPO, ;
		SE1->E1_NATUREZ, ;
		"R", ;
		SE1->E1_CLIENTE, ;
		1, ;
		SE1->E1_VENCREA,, ;
		SE1->E1_LOJA,, ;
		SE1->E1_TXMOEDA)
		// proxima parcela
		SE1->(dbSkip())
	EndDo

	// restura area inicial
	RestArea(_aAreaSE1)

Return(_nSldFt)