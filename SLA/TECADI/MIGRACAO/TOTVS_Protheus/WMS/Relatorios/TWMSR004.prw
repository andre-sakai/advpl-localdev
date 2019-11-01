#INCLUDE "PROTHEUS.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "FONT.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "RPTDEF.CH"
//#Include "ISAMQry.ch"

/*---------------------------------------------------------------------------
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSR004                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Impressao dos detalhes do faturamento de Contratos      !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 10/02/11                                                !
+------------------+--------------------------------------------------------*/

User Function TWMSR004

	// grupo de perguntas (parametros)
	Local _aPerg := {}
	Local _cPerg := PadR("TWMSR004",10)

	// criacao das Perguntas
	aAdd(_aPerg,{"Pedido de Venda De?" ,"C",TamSx3("C5_NUM")[1],0,"G",,"SC5"}) //mv_par01
	aAdd(_aPerg,{"Pedido de Venda Até?" ,"C",TamSx3("C5_NUM")[1],0,"G",,"SC5"}) //mv_par02
	aAdd(_aPerg,{"Cliente De?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par03
	aAdd(_aPerg,{"Cliente Até?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par04
	aAdd(_aPerg,{"Loja De?" ,"C",TamSx3("A1_LOJA")[1],0,"G",,""}) //mv_par05
	aAdd(_aPerg,{"Loja Até?" ,"C",TamSx3("A1_LOJA")[1],0,"G",,""}) //mv_par06
	aAdd(_aPerg,{"Data Emissão De?" ,"D",8,0,"G",,""}) //mv_par07
	aAdd(_aPerg,{"Data Emissão Até?" ,"D",8,0,"G",,""}) //mv_par08

	// cria grupo de perguntas
	U_FtCriaSX1( _cPerg,_aPerg )

	If ! Pergunte(_cPerg,.T.)
		Return ()
	EndIf

	// chama a rotina que posiciona o pedido de venda para impressão
	Processa({ || U_WMSR004A(mv_par01,mv_par02,mv_par03,mv_par04,mv_par05,mv_par06,mv_par07,mv_par08,.F.,1) },"Gerando relatório...",,.T.)

Return ()

// ** funcao responsavel pelo posicionamento no cabecalho do pedido de venda
User Function WMSR004A(mvPedDe,mvPedAte,mvCodCliDe,mvCodCliAte,mvLojCliDe,mvLojCliAte,mvEmissDe,mvEmissAte,mvAuto,mv_Imp,mv_Local,mv_Arquivo)
	// area inicial do SC5
	Local _aAreaSC5 := SC5->(GetArea())
	// lista de pedidos
	local _aNrPedidos := 0
	local _nNrPedido := 0

	// controle de quebra de paginas
	Local _lFirstPag := .t.
	//Tipo de Impressão
	Private lFWMS := .F.

	// variaveis para gerenciar a criação do PDF
	Private lAdjustToLegacy		:= .T.
	Private lDisableSetup 		:= .T.
	Private lServer 			:= .T.
	Private lPDFAsPNG			:= .F.
	Private lViewPDF			:= .T.
	Private cDirPrint			:= ""
	Private cFileOP				:= ""
	Private cArqDir				:= ""
	Private cArqTemp			:= ""

	// Cria Objeto para impressao Grafica
	Private _oPrn
	// fontes utilizadas
	Private _oFont01n
	Private _oFont02
	Private _oFont02n

	// imagem da logo
	Private _cImagem := "\"+AllTrim(CurDir())+"\logo_tecadi.jpg"

	//Controle de Colunas
	Private _nCol01
	Private _nCol02

	// define conteudo padrao
	Default mvCodCliDe  := PadR("  ",TamSx3("A1_COD")[1])
	Default mvCodCliAte := PadR("ZZ",TamSx3("A1_COD")[1])
	Default mvLojCliDe  := PadR("  ",TamSx3("A1_LOJA")[1])
	Default mvLojCliAte := PadR("ZZ",TamSx3("A1_LOJA")[1])
	Default mvEmissDe   := CtoD("01/01/2010")
	Default mvEmissAte  := CtoD("31/12/2049")
	//Tipo de chamada se for chamada via  rotina automatica parametro recebe .T. .
	Default mvAuto      := .F.
	//1 - Impressão em PDF e 2 - impressão em TELA.
	Default mv_Imp      := 1
	Default mv_Local    := ""
	Default mv_Arquivo  := ""

	cDirPrint	:= Iif(Empty(mv_Local)  ,AllTrim(GetTempPath()),mv_Local)
	cFileOP		:= Iif(Empty(mv_Arquivo),"TWMSR004"            ,mv_Arquivo)
	cArqDir		:= cDirPrint + cFileOP + ".pdf"
	cArqTemp	:= cDirPrint + cFileOP + ".rel"

	//Apaga arquivos Temporarios
	FErase(cArqDir)
	FErase(cArqTemp)

	//Variavel responsavel pelo tipo de Impressão (.T. = FWMsPrinter PDF, .F. = TMSPrinter Tela)
	lFWMS := (mv_Imp==1)

	// Cria Objeto para impressao Grafica
	_oPrn := IIF(lFWMS,FWMsPrinter():New(cFileOP+".pdf",IMP_PDF,lAdjustToLegacy,cDirPrint,lDisableSetup, /*[lTReport]*/, /*[@oPrintSetup]*/, /*[ cPrinter]*/, lServer, lPDFAsPNG, /*[ lRaw]*/, lViewPDF, /*[ nQtdCopy]*/ ),TMSPrinter():New("Detalhes do Faturamento"))

	// imagem da logo
	_cImagem := "\"+AllTrim(CurDir())+"\logo_tecadi.jpg"

	//Impressão com o componente FWMsPrinter PDF
	If lFWMS
		// fontes utilizadas
		_oFont01n  := TFont():New("Arial" ,,-20,,.T.,,,,.F.,.F.)
		_oFont02   := TFont():New("Arial" ,,-14,,.F.,,,,.F.,.F.)
		_oFont02n  := TFont():New("Arial" ,,-14,,.T.,,,,.F.,.F.)
		_oPrn:SetResolution(78) //Tamanho estipulado para a Danfe
		_oPrn:SetPortrait()
		_oPrn:SetPaperSize(DMPAPER_A4)
		_oPrn:SetMargin(60,60,60,60)
		_oPrn:nDevice  := IMP_PDF
		_oPrn:cPathPDF := cDirPrint

		IF (!mvAuto)
			_oPrn:Setup()
			If _oPrn:nModalResult == 2
				//Apaga arquivos Temporarios
				FErase(_oPrn:cPathPDF + cFileOP + ".pdf")
				FErase(_oPrn:cPathPDF + cFileOP + ".rel")
				_oPrn:Cancel()
				_oPrn:Deactivate()
				Return()
			EndIf
			_oPrn:GetViewPDF(.T.)
			_oPrn:SetViewPDF(.T.)
		Else
			_oPrn:GetViewPDF(.F.)
			_oPrn:SetViewPDF(.F.)
		EndIF

		//Apaga arquivos Temporarios
		FErase(_oPrn:cPathPDF + cFileOP + ".pdf")
		FErase(_oPrn:cPathPDF + cFileOP + ".rel")

		_nCol01 := 0020
		_nCol02 := 0070

		//Impressão com o componente TMSPrinter.
	Else
		// fontes utilizadas
		_oFont01n  := TFont():New("Arial" ,,-15,,.T.,,,,.F.,.F.)
		_oFont02   := TFont():New("Arial" ,,-10,,.F.,,,,.F.,.F.)
		_oFont02n  := TFont():New("Arial" ,,-10,,.T.,,,,.F.,.F.)
		// define como retrato
		_oPrn:SetPortrait()
		// chama a rotina de Configuracao da impressao
		_oPrn:Setup()
		// define como retrato
		_oPrn:SetPortrait()

		_nCol01 := 0080
		_nCol02 := 0150

	EndIF

	// retornar a lista de pedidos a processar
	_aNrPedidos := U_SQlToVet("SELECT SC5.R_E_C_N_O_ SC5RECNO FROM "+RetSqlName("SC5")+" SC5 WHERE "+RetSqlCond("SC5")+" AND C5_NUM BETWEEN '"+mvPedDe+"' AND '"+mvPedAte+"' AND C5_TIPOOPE = 'S' "+;
	"AND C5_CLIENTE BETWEEN '"+mvCodCliDe+"' AND '"+mvCodCliAte+"' AND C5_LOJACLI BETWEEN '"+mvLojCliDe+"' AND '"+mvLojCliAte+"' "+;
	"AND C5_EMISSAO BETWEEN '"+DtoS(mvEmissDe)+"' AND '"+DtoS(mvEmissAte)+"'")

	If (Len(_aNrPedidos) <= 0)
		If (!mvAuto)
			MsgStop("Sem informações para Imprimir")
			//Apaga arquivos Temporarios
			FErase(_oPrn:cPathPDF + cFileOP + ".pdf")
			FErase(_oPrn:cPathPDF + cFileOP + ".rel")
		EndIf
		Return()
	EndIf

	// defina a quatidade de registro da regua de processamento
	ProcRegua( Len(_aNrPedidos) )

	// pesquisa o numero do pedido
	For _nNrPedido := 1 to Len(_aNrPedidos)

		// posiciona no pedido
		dbSelectArea("SC5")
		SC5->(dbGoTo( _aNrPedidos[_nNrPedido] ))

		// incrementa a regua
		IncProc("Pedido: "+SC5->C5_NUM)

		// chama a rotina para impressao dos detalhes do pedido
		sfImprimir(@_lFirstPag)

	Next _nNrPedido

	_oPrn:Print()

	// restaura area inicial
	RestArea(_aAreaSC5)

Return

// ** funcao para impressao dos dados
Static Function sfImprimir(mvFirstPag)

	// controle de pesquisa atraves do SEEK
	Local _cSeekSC6
	// detalhes do pacote logistico
	Local _aDetPacLog := {}
	// variaveis temporarias
	Local _nX, _nY
	// detalhes do produto
	Local _aDetalhes := {}
	// controle de linha
	Private _nLin := 3000

	// varre todos os itens do pedido de venda
	dbSelectArea("SC6")
	SC6->(dbSetOrder(1)) //1-C6_FILIAL, C6_NUM, C6_ITEM, C6_PRODUTO
	SC6->(dbSeek( _cSeekSC6 := xFilial("SC6")+SC5->C5_NUM ))

	While SC6->(!Eof()).and.(SC6->(C6_FILIAL+C6_NUM)==_cSeekSC6)
		// impressao do cabecalho
		If (_nLin >= 3000)
			// funcao para impressao do cabecalho
			sfCabec( mvFirstPag )
			// atualiza variavel
			mvFirstPag := .f.
		EndIf

		// posiciona no cadastro de produtos
		dbSelectArea("SB1")
		SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
		SB1->(dbSeek( xFilial("SB1")+SC6->C6_PRODUTO ))

		// impressao dos detalhes do itemfe
		_oPrn:Say(_nLin,_nCol01,"Item NF: "+SC6->C6_ITEM+" - "+AllTrim(SC6->C6_PRODUTO)+" "+AllTrim(SC6->C6_DESCRI)+" "+;
		"- R$ "+AllTrim(Transf(SC6->C6_VALOR,PesqPict("SC6","C6_VALOR"))),_oFont02n)
		_nLin += 50

		// zera a variavel de detalhes
		_aDetalhes := {}

		// 1-ARMAZENAGEM DE CONTAINER
		If (SB1->B1_TIPOSRV=="1")
			// busca os detalhes da armazenagem de container
			_aDetalhes := sfDetArmCnt()
			// impressao dos dados
			For _nX := 1 to Len(_aDetalhes)
				// imprime linha
				_oPrn:Say(_nLin,_nCol02,_aDetalhes[_nX],_oFont02)
				_nLin += 50

				// impressao do cabecalho
				If (_nLin >= 3000)
					// funcao para impressao do cabecalho
					sfCabec(.f.)
				EndIf

			Next _nX
			// 2-ARMAZENAGEM DE PRODUTO
		ElseIf (SB1->B1_TIPOSRV=="2")
			// busca os detalhes da armazenagem de produtos
			_aDetalhes := sfDetArmPrd()
			// impressao dos dados
			For _nX := 1 to Len(_aDetalhes)
				// imprime a periodicidade
				If (_nX==1)
					// imprime linha do cabecalho
					_oPrn:Say(_nLin,_nCol02,_aDetalhes[_nX][1],_oFont02)
					_nLin += 50
					// impressao do cabecalho
					If (_nLin >= 3000)
						// funcao para impressao do cabecalho
						sfCabec(.f.)
					EndIf
				EndIf

				// imprime linha
				_oPrn:Say(_nLin,_nCol02,_aDetalhes[_nX][2],_oFont02)
				_nLin += 50

				// impressao do cabecalho
				If (_nLin >= 3000)
					// funcao para impressao do cabecalho
					sfCabec(.f.)
				EndIf

			Next _nX

			// 3-PACOTE LOGISTICO / A-PACOTE LOGISTICO EXPORTACAO / B-PACOTE DE SERVICOS
		ElseIf (SB1->B1_TIPOSRV $ "3/A/B")

			// retorna os produto do pacote logistico
			// estrutura
			// 1-numero do pacote
			// 2-produtos
			_aDetPacLog := sfPrdPacLog()

			// impressao dos detalhes
			For _nX := 1 to Len(_aDetPacLog)
				// impressao do item do pacote
				_oPrn:Say(_nLin,_nCol02,AllTrim(_aDetPacLog[_nX][2])+" - "+Posicione("SB1",1, xFilial("SB1")+_aDetPacLog[_nX][2] ,"B1_DESC"),_oFont02)
				_nLin += 50

				// zera vetor dos detalhes
				_aDetalhes := {}
				/*
				// 1-PACOTE LOGISTICO
				If (SB1->B1_TIPOSRV=="3")
				// busca os detalhes do pacote logistico
				_aDetalhes := sfDetPacLog(_aDetPacLog[_nX][1],_aDetPacLog[_nX][2])
				EndIF
				*/
				// 4-FRETES
				If (SB1->B1_TIPOSRV=="4")
					// busca os detalhes dos fretes
					_aDetalhes := sfDetFrete(_aDetPacLog[_nX][1])//,_aDetPacLog[_nX][2])

					// 7-SERVICOS DIVERSOS
				ElseIf (SB1->B1_TIPOSRV=="7")
					// busca os detalhes dos servicos
					_aDetalhes := sfDetServicos(_aDetPacLog[_nX][1])//,_aDetPacLog[_nX][2])

				Else
					MsgStop("Erro no relatório. Ver item "+SB1->B1_TIPOSRV)
				EndIf

				// impressao dos dados
				For _nY := 1 to Len(_aDetalhes)
					// imprime linha
					_oPrn:Say(_nLin,0200,_aDetalhes[_nY],_oFont02)
					_nLin += 50

					// impressao do cabecalho
					If (_nLin >= 3000)
						// funcao para impressao do cabecalho
						sfCabec(.f.)
					EndIf

				Next _nY

				// linha entre itens do pacote logistico
				_nLin += 30
			Next _nX

			// 4-FRETE
		ElseIf (SB1->B1_TIPOSRV=="4")
			// busca os detalhes dos fretes
			_aDetalhes := sfDetFrete("")
			// impressao dos dados
			For _nX := 1 to Len(_aDetalhes)
				// imprime linha
				_oPrn:Say(_nLin,_nCol02,_aDetalhes[_nX],_oFont02)
				_nLin += 50

				// impressao do cabecalho
				If (_nLin >= 3000)
					// funcao para impressao do cabecalho
					sfCabec(.f.)
				EndIf

			Next _nX

			// 5-SEGUROS
		ElseIf (SB1->B1_TIPOSRV=="5")
			// busca os detalhes do seguro
			_aDetalhes := sfDetSeguro()
			// impressao dos dados
			For _nX := 1 to Len(_aDetalhes)
				// imprime a periodicidade
				If (_nX==1)
					// imprime linha do cabecalho

					_oPrn:Say(_nLin,_nCol02,_aDetalhes[_nX][1],_oFont02)

					_nLin += 50
					// impressao do cabecalho
					If (_nLin >= 3000)
						// funcao para impressao do cabecalho
						sfCabec(.f.)
					EndIf
				EndIf

				// imprime linha
				_oPrn:Say(_nLin,_nCol02,_aDetalhes[_nX][2],_oFont02)

				_nLin += 50

				// impressao do cabecalho
				If (_nLin >= 3000)
					// funcao para impressao do cabecalho
					sfCabec(.f.)
				EndIf

			Next _nX

		ElseIf (SB1->B1_TIPOSRV=="6")

			// 7-SERVICOS DIVERSOS
		ElseIf (SB1->B1_TIPOSRV=="7")
			// busca os detalhes dos servicos
			_aDetalhes := sfDetServicos("")
			// impressao dos dados
			For _nX := 1 to Len(_aDetalhes)
				// imprime linha
				_oPrn:Say(_nLin,_nCol02,_aDetalhes[_nX],_oFont02)
				_nLin += 50

				// impressao do cabecalho
				If (_nLin >= 3000)
					// funcao para impressao do cabecalho
					sfCabec(.f.)
				EndIf

			Next _nX
		ElseIf (SB1->B1_TIPOSRV=="8")

		ElseIf (SB1->B1_TIPOSRV=="9")

		EndIf

		// linha entre itens do pedido
		_nLin += 60

		// proximo item do pedido
		dbSelectArea("SC6")
		SC6->(dbSkip())
	EndDo

Return

// ** funcao que retorna os produto do pacote logistico
Static Function sfPrdPacLog()
	// variavel temporaria
	local _cQrySzo
	// variavel de retorno
	Local _aSrvPacote := {}
	// area inicial
	Local _aArea := GetArea()
	/*
	// relaciona todos os itens/servicos que compoe o pacote logistico
	_cQrySzu := "SELECT DISTINCT ZU_PRODUTO "
	// servicos do pacote
	_cQrySzu += "FROM "+RetSqlName("SZU")+" SZU "
	// filtro dos servicos do contrato e item
	_cQrySzu += "WHERE "+RetSqlCond("SZU")+" "
	_cQrySzu += "AND ZU_CONTRT = '"+SZL->ZL_CONTRT+"' AND ZU_ITCONTR = '"+SZL->ZL_ITCONTR+"' "
	// ordem dos dados
	_cQrySzu += "ORDER BY ZU_PRODUTO
	// alimenta o vetor com o resultado do SQL
	_aSrvPacote := U_SqlToVet(_cQrySzu)
	*/

	// relaciona todos os itens/servicos que compoe o pacote logistico
	_cQrySzo := "SELECT DISTINCT ZO_PACOTE, ZO_PRODUTO "
	// pacote logistico
	_cQrySzo += "FROM "+RetSqlName("SZJ")+" SZJ "
	// itens do pacote logistico
	_cQrySzo += "INNER JOIN "+RetSqlName("SZO")+" SZO ON ZO_FILIAL = ZJ_FILIAL AND ZO_PACOTE = ZJ_PACOTE AND ZO_SEQPACO = ZJ_SEQPACO AND SZO.D_E_L_E_T_ = ' ' "
	// nao trazer o item do PACOTE LOGISTICO
	_cQrySzo += "AND ZO_PRODUTO != '"+SC6->C6_PRODUTO+"' "
	// filtro o pacote do item do pedido
	_cQrySzo += "WHERE "+RetSqlCond("SZJ")+" "
	// pedido e item
	_cQrySzo += "AND ZJ_PEDIDO = '"+SC6->C6_NUM+"' AND ZJ_ITEMPED = '"+SC6->C6_ITEM+"' "
	// ordem dos dados
	_cQrySzo += "ORDER BY ZO_PACOTE, ZO_PRODUTO "
	// alimenta o vetor com o resultado do SQL
	_aSrvPacote := U_SqlToVet(_cQrySzo)

	// restaura area inicial
	RestArea(_aArea)

Return(_aSrvPacote)

// ** funcao para retornar os detalhes do servico
Static Function sfDetServicos(mvCodPacte)//,mvSeqPacte)
	// area inicial
	local _aAreaSZL := SZL->(GetArea())
	// variavel de retorno
	local _aRet := {}
	// seek SZL
	local _cSeekSZL
	// referencia do tipo de movimentacao (nota, pedido ou container)
	local _cOrigRef

	// padroniza o codigo do pacote
	mvCodPacte := PadR(mvCodPacte,Len(SZL->ZL_PACOTE))

	// informacoes de fretes
	dbSelectArea("SZL")
	SZL->(dbOrderNickName("ZL_PEDIDO")) // 4-ZL_FILIAL, ZL_PEDIDO, ZL_ITEMPED
	SZL->(dbSeek( _cSeekSZL := xFilial("SZL")+SC6->(C6_NUM+C6_ITEM) ))

	// varre todos os itens
	While SZL->(!Eof()).and.(SZL->(ZL_FILIAL+ZL_PEDIDO+ZL_ITEMPED)==_cSeekSZL)

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
			aAdd(_aRet,	_cOrigRef +;
			"   Data: "+DtoC(SZL->ZL_DTINIOS) +;
			"   Quant.: "+If(SZL->ZL_UNIDCOB=="M3",AllTrim(Transf(SZL->ZL_CUBAGEM,PesqPict("SZL","ZL_CUBAGEM"))), AllTrim(Transf(SZL->ZL_QUANT,PesqPict("SZL","ZL_QUANT"))))+" ("+SZL->ZL_UNIDCOB+")" +;
			If(Empty(mvCodPacte),"  Tarifa: R$ "+AllTrim(Transf(SZL->ZL_VLRUNIT,PesqPict("SZL","ZL_TOTAL"))) ,"") +;
			If(Empty(mvCodPacte),"  Valor: R$ "+AllTrim(Transf(SZL->ZL_TOTAL,PesqPict("SZL","ZL_TOTAL"))) ,"") +;
			"   Atividade: "+AllTrim(SZL->ZL_CODATIV)+"-"+AllTrim(Posicione("SZT",1, xFilial("SZT")+SZL->ZL_CODATIV ,"ZT_DESCRIC")) )
			*/

			aAdd(_aRet,	_cOrigRef +;
			"   Data: "   + DtoC(SZL->ZL_DTINIOS) +;
			"   Quant.: " + IIf(SZL->ZL_UNIDCOB=="M3", AllTrim(Transf(SZL->ZL_CUBAGEM,PesqPict("SZL","ZL_CUBAGEM"))), IIf( SZL->ZL_UNIDCOB=="TO", AllTrim(Transf(SZL->ZL_PESOBRU,PesqPict("SZL","ZL_PESOBRU"))),  AllTrim(Transf(SZL->ZL_QUANT,PesqPict("SZL","ZL_QUANT")))) ) + " ("+SZL->ZL_UNIDCOB+")" +;
			If(Empty(mvCodPacte),"  Tarifa: R$ "+AllTrim(Transf(SZL->ZL_VLRUNIT,PesqPict("SZL","ZL_TOTAL"))) ,"") +;
			If(Empty(mvCodPacte),"  Valor: R$ "+AllTrim(Transf(SZL->ZL_TOTAL,PesqPict("SZL","ZL_TOTAL"))) ,"") +;
			"   Atividade: "+AllTrim(SZL->ZL_CODATIV)+"-"+AllTrim(Posicione("SZT",1, xFilial("SZT")+SZL->ZL_CODATIV ,"ZT_DESCRIC")) )

		EndIf

		// proximo item
		SZL->(dbSkip())
	EndDo

	// restaura area inicial
	RestArea(_aAreaSZL)

Return(_aRet)

// ** funcao para retornar os detalhes do frete
Static Function sfDetFrete(mvCodPacte)//,mvSeqPacte)
	// area inicial
	local _aAreaSZK := SZK->(GetArea())
	// variavel de retorno
	local _aRet := {}
	// seek SZK
	local _cSeekSZK

	// padroniza o codigo do pacote
	mvCodPacte := PadR(mvCodPacte,Len(SZK->ZK_PACOTE))

	// informacoes de fretes
	dbSelectArea("SZK")
	SZK->(dbOrderNickName("ZK_PEDIDO")) // 4-ZK_FILIAL, ZK_PEDIDO, ZK_ITEMPED
	SZK->(dbSeek( _cSeekSZK := xFilial("SZK")+SC6->(C6_NUM+C6_ITEM) ))

	// varre todos os itens
	While SZK->(!Eof()).and.(SZK->(ZK_FILIAL+ZK_PEDIDO+ZK_ITEMPED)==_cSeekSZK)

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

		// detalhes
		aAdd(_aRet,	If(Empty(SZK->ZK_SEQPACO),"","Seq: "+SZK->ZK_SEQPACO+"  ") +;
		"Data: "+DtoC(SZK->ZK_DTMOVIM) +;
		"   "+If(SZK->ZK_TPMOVIM=="E","ENTRADA","SAIDA  ") +;
		"   Container: "+Transf(SZK->ZK_CONTAIN,PesqPict("SZK","ZK_CONTAIN")) +;
		"   Tamanho: "+SZK->ZK_TAMCONT +;
		"   Conteudo: "+If(SZK->ZK_CONTEUD=="C","CHEIO","VAZIO")  +;
		If(Empty(mvCodPacte),"","  -  Valor Pacote Logístico R$ " + AllTrim(Transf(sfRetVlrPac(),PesqPict("SZS","ZS_TOTAL")))))

		// detalhes das pracas (quebra em 2 linhas)
		aAdd(_aRet,	"    Praça: Origem "+AllTrim(Posicione("SZB",1, xFilial("SZB")+SZK->ZK_PRCORIG ,"ZB_DESCRI")) +;
		" -> Destino "+AllTrim(Posicione("SZB",1, xFilial("SZB")+SZK->ZK_PRCDEST ,"ZB_DESCRI")) )

		// proximo item
		SZK->(dbSkip())
	EndDo

	// restaura area inicial
	RestArea(_aAreaSZK)

Return(_aRet)

/*
// ** funcao que detalha o pacote logistico
Static Function sfDetPacLog(mvCodPacte)
// area inicial
local _aAreaSZJ := SZJ->(GetArea())
// variavel de retorno
local _aRet := {}
// seek SZJ
local _cSeekSZJ

// informacoes do pacote logistico
dbSelectArea("SZJ")
SZJ->(dbOrderNickName("ZJ_PEDIDO")) // 4-ZJ_FILIAL, ZJ_PEDIDO, ZJ_ITEMPED
SZJ->(dbSeek( _cSeekSZJ := xFilial("SZJ")+SC6->(C6_NUM+C6_ITEM) ))

// varre todos os itens
While SZJ->(!Eof()).and.(SZJ->(ZJ_FILIAL+ZJ_PEDIDO+ZJ_ITEMPED)==_cSeekSZJ)

// se FATURA estiver como NAO
If (SZJ->ZJ_FATURAR=="N")
// proximo item
SZJ->(dbSkip())
Loop
EndIf

// veririca se eh pacote logistico
If (SZJ->ZJ_PACOTE != mvCodPacte)
// proximo item
SZJ->(dbSkip())
Loop
EndIf

// detalhes
aAdd(_aRet,	"Data: "+DtoC(SZJ->ZJ_DTMOVIM) +;
"  "+If(SZJ->ZJ_TPMOVIM=="E","ENTRADA","SAIDA  ") +;
"  Container: "+Transf(SZJ->ZJ_CONTAIN,PesqPict("SZC","ZC_CODIGO")) +;
"  Tamanho: "+SZJ->ZJ_TAMCONT +;
"  Conteudo: "+If(SZJ->ZJ_CONTEUD=="C","CHEIO","VAZIO") +;
"  Praça: "+AllTrim(Posicione("SZB",1, xFilial("SZB")+SZJ->ZJ_PRCORIG ,"ZB_DESCRI")) +;
" / "+AllTrim(Posicione("SZB",1, xFilial("SZB")+SZJ->ZJ_PRCDEST ,"ZB_DESCRI")) )

// proximo item
SZJ->(dbSkip())
EndDo

// restaura area inicial
RestArea(_aAreaSZJ)

Return(_aRet)
*/

// ** funcao que retorna os detalhes da armazenagem de container
Static Function sfDetArmCnt()
	// area inicial
	local _aAreaSZG := SZG->(GetArea())
	// variavel de retorno
	local _aRet := {}
	// seek SZG
	local _cSeekSZG

	// informacoes de armazenazem de containet
	dbSelectArea("SZG")
	SZG->(dbOrderNickName("ZG_PEDIDO")) // 4-ZG_FILIAL, ZG_PEDIDO, ZG_ITEMPED
	SZG->(dbSeek( _cSeekSZG := xFilial("SZG")+SC6->(C6_NUM+C6_ITEM) ))

	// varre todos os itens
	While SZG->(!Eof()).and.(SZG->(ZG_FILIAL+ZG_PEDIDO+ZG_ITEMPED)==_cSeekSZG)

		// se FATURA estiver como NAO
		If (SZG->ZG_FATURAR=="N")
			// proximo item
			SZG->(dbSkip())
			Loop
		EndIf

		// detalhes
		aAdd(_aRet,	"Container: "+Transf(SZG->ZG_CONTAIN,PesqPict("SZC","ZC_CODIGO")) +;
		"   Dt Entrada: "+DtoC(SZG->ZG_DTENTRA) +;
		"   Dt Saída: "+DtoC(SZG->ZG_DTSAIDA) +;
		"   Data Ini: "+DtoC(SZG->ZG_DTINI) +;
		"   Data Fim: "+DtoC(SZG->ZG_DTFIM) +;
		"   Day Free: "+Str(SZG->ZG_DAYFREE,3) +;
		"   Quantidade: "+Str(SZG->ZG_QUANT,3) +;
		"   Tamanho: "+SZG->ZG_TAMCONT )

		// proximo item
		SZG->(dbSkip())
	EndDo

	// restaura area inicial
	RestArea(_aAreaSZG)

Return(_aRet)

// ** funcao que retorna os detalhes da armazenagem de produtos
Static Function sfDetArmPrd()
	// area inicial
	local _aAreaSZH := SZH->(GetArea())
	// variavel de retorno
	local _aRet := {}
	// seek SZH
	local _cSeekSZH

	// informacoes de armazenagem de produtos
	dbSelectArea("SZH")
	SZH->(dbOrderNickName("ZH_PEDIDO")) // 4-ZH_FILIAL, ZH_PEDIDO, ZH_ITEMPED
	SZH->(dbSeek( _cSeekSZH := xFilial("SZH")+SC6->(C6_NUM+C6_ITEM) ))

	// varre todos os itens
	While SZH->(!Eof()).and.(SZH->(ZH_FILIAL+ZH_PEDIDO+ZH_ITEMPED)==_cSeekSZH)

		// se FATURA estiver como NAO
		If (SZH->ZH_FATURAR=="N")
			// proximo item
			SZH->(dbSkip())
			Loop
		EndIf

		// detalhes
		aAdd(_aRet,{"Periodicidade: " + Alltrim(Str(SZH->ZH_DIASPER,3)) + " dias", ;
		"Período: "       + Alltrim(Str(SZH->ZH_PERIODO,3)) + ;
		" NF Remessa: "   + Alltrim(SZH->ZH_DOC+"/"+SZH->ZH_SERIE) +;
		" Tarifa: R$ "    + Alltrim(Transf(SZH->ZH_VLRUNIT,PesqPict("SZH","ZH_TOTAL"))) +;
		" Saldo NF: "     + Alltrim(Transf(SZH->ZH_SALDO,PesqPict("SZH","ZH_SALDO"))) +" ("+AllTrim(sfCBoxDescr("ZH_TPARMAZ",SZH->ZH_TPARMAZ,2,3))+")"+;
		" Valor: R$ "     + Alltrim(Transf(SZH->ZH_TOTAL,PesqPict("SZH","ZH_TOTAL"))) +;
		" Dt Inic.: "     + Alltrim(DtoC(SZH->ZH_DTINI))+;
		" Dt Final: "     + Alltrim(DtoC(SZH->ZH_DTFIM)) } )

		// proximo item
		SZH->(dbSkip())
	EndDo

	// restaura area inicial
	RestArea(_aAreaSZH)

Return(_aRet)

// ** funcao que retorna os detalhes do seguro
Static Function sfDetSeguro()
	// variavel de retorno
	local _aRet := {}
	// area inicial
	local _aAreaSZI := SZH->(GetArea())
	// seek SZI
	local _cSeekSZI

	// informacoes de seguros
	dbSelectArea("SZI")
	SZI->(dbOrderNickName("ZI_PEDIDO")) // 4-ZI_FILIAL, ZI_PEDIDO, ZI_ITEMPED
	SZI->(dbSeek( _cSeekSZI := xFilial("SZI")+SC6->(C6_NUM+C6_ITEM) ))

	// varre todos os itens
	While SZI->(!Eof()).and.(SZI->(ZI_FILIAL+ZI_PEDIDO+ZI_ITEMPED)==_cSeekSZI)

		// se FATURA estiver como NAO
		If (SZI->ZI_FATURAR=="N")
			// proximo item
			SZI->(dbSkip())
			Loop
		EndIf

		// detalhes
		aAdd(_aRet, {"Periodicidade: "+ Alltrim(Str(SZI->ZI_DIASPER,3)) + " dias", ;
		"Período: "       + Alltrim(Str(SZI->ZI_PERIODO,3))                           +;
		" NF Remessa: "   + Alltrim(SZI->ZI_DOC+"/"+SZI->ZI_SERIE)                    +;
		" Saldo NF: R$ "  + AllTrim(Transf(SZI->ZI_SALDO,PesqPict("SZI","ZI_SALDO"))) +;
		" Tarifa: "       + AllTrim(Transf(SZI->ZI_VLRUNIT,PesqPict("SZI","ZI_VLRUNIT"))) +" % "+;
		" Valor: R$ "     + AllTrim(Transf(SZI->ZI_TOTAL,PesqPict("SZI","ZI_TOTAL"))) +;
		" Dt Inic.: "     + Alltrim(DtoC(SZI->ZI_DTINI))                              +;
		" Dt Final: "     + Alltrim(DtoC(SZI->ZI_DTFIM))})

		// proximo item
		SZI->(dbSkip())
	EndDo

	// restaura area inicial
	RestArea(_aAreaSZI)

Return(_aRet)

// ** funcao que retorna a descricao de campo combobox
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

// ** funcao para impressao do cabecalho
Static Function sfCabec( mvFirstPag )

	Local _nColCabDA
	Local _nColCabDE
	Local _nColCabRE
	Local _nColCabDO

	// finaliza pagina
	If ( ! mvFirstPag)
		_oPrn:EndPage()
	EndIf

	// cria nova Pagina
	_oPrn:StartPage()
	// reinicia linha
	If lFWMS
		_nLin := 00

		// primeira linha - box
		_oPrn:Box(_nLin,0000,_nLin+220,2400)

		// coluna - antes "DETALHES DO FATURAMENTO"
		_oPrn:Line(_nLin,0980,_nLin+220,0980)

		// titulo
		_oPrn:Say(_nLin+100,1300,"MAPA DE MOVIMENTAÇÕES",_oFont01n,,,,2)
		_nLin += 220

		// logo
		_oPrn:SayBitmap(10,0170,_cImagem,691.6,222.3)

		// segunda linha - box - dados do cliente
		_oPrn:Box(_nLin,0000,_nLin+200,2400)
		_nTmpLin := 40

		_nColCabDA := 0950
		_nColCabDE := 0950
		_nColCabRE := 1450
		_nColCabDO := 2050

	Else
		_nLin := 70
		// logo
		_oPrn:SayBitmap(_nLin,0170,_cImagem,691.6,222.3)
		// primeira linha - box
		_oPrn:Box(_nLin,0060,_nLin+220,2290)
		// coluna - antes "DETALHES DO FATURAMENTO"
		_oPrn:Line(_nLin,0980,_nLin+220,0980)
		// titulo
		_oPrn:Say(_nLin+80,1700,"MAPA DE MOVIMENTAÇÕES",_oFont01n,,,,2)
		_nLin += 220

		// segunda linha - box - dados do cliente
		_oPrn:Box(_nLin,0060,_nLin+200,2290)
		_nTmpLin := 20

		_nColCabDA := 0940
		_nColCabDE := 0940
		_nColCabRE := 1440
		_nColCabDO := 2010

	EndIf

	// informacoes do cliente
	_oPrn:Say(_nLin+_nTmpLin,_nCol01,"Cliente:",_oFont02)
	_oPrn:Say(_nLin+_nTmpLin,0390,SC5->C5_CLIENTE +"/"+SC5->C5_LOJACLI+": "+Posicione("SA1",1, xFilial("SA1")+SC5->(C5_CLIENTE+C5_LOJACLI) ,"A1_NOME"),_oFont02n)
	_nTmpLin += 60

	// programacao
	_oPrn:Say(_nLin+_nTmpLin,_nCol01,"Programação:",_oFont02)
	_oPrn:Say(_nLin+_nTmpLin,0390,SC5->C5_ZPROCES,_oFont02n)
	// data abertura
	_oPrn:Say(_nLin+_nTmpLin,0600,"Data de Abertura: ",_oFont02)
	_oPrn:Say(_nLin+_nTmpLin,_nColCabDA,DtoC(Posicione("SZ1",1, xFilial("SZ1")+SC5->C5_ZPROCES ,"Z1_DTABERT")),_oFont02)
	// referencia
	_oPrn:Say(_nLin+_nTmpLin,1200,"Referência:",_oFont02)
	_oPrn:Say(_nLin+_nTmpLin,_nColCabRE,SZ1->Z1_REFEREN,_oFont02n)
	// documento
	_oPrn:Say(_nLin+_nTmpLin,1770,"Documento:",_oFont02)
	_oPrn:Say(_nLin+_nTmpLin,_nColCabDO,Posicione("SZ2",1, xFilial("SZ2")+SZ1->Z1_CODIGO+SC6->C6_ZITPROC ,"Z2_DOCUMEN"),_oFont02n)
	_nTmpLin += 60

	// numero do pedido
	_oPrn:Say(_nLin+_nTmpLin,_nCol01,"Pedido:",_oFont02)
	_oPrn:Say(_nLin+_nTmpLin,0390,SC5->C5_NUM,_oFont02)
	// data de emissao do pedido
	_oPrn:Say(_nLin+_nTmpLin,0600,"Data de Emissão:",_oFont02)
	_oPrn:Say(_nLin+_nTmpLin,_nColCabDE,DtoC(SC5->C5_EMISSAO),_oFont02)
	_nTmpLin += 60

	If lFWMS
		// controle da linha
		_nLin += 250
	Else
		// controle da linha
		_nLin += 220
	EndIF
Return

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