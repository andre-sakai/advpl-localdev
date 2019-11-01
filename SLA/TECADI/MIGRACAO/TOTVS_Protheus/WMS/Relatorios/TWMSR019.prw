#Include 'Protheus.ch'
#include "TOTVS.CH"
#Include 'FWPrintSetup.ch'
#Include 'RPTDEF.CH'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para impressao do Romaneio Carga                 !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe Jose Limas         ! Data de Criação   ! 05/2015 !
+------------------+--------------------------------------------------------*/

User Function TWMSR019(mvCESV,mvPrinter)
	//Se passado por parâmetro sobreescreve os parâmetros do Pergunte
	Local cCESV := mvCESV
	
	//Caso chamado a função com o parâmetro preenchido ele irá imprimir na impressora passada no parâmetro,
	//caso contrário vai chamar o Setup para o usuário imprimir em PDF 
	Local cPrinter := mvPrinter

	// grupo de perguntas
	local _cPerg   := PadR("TWMSR019",10)
	local _aPerg   := {}
	Local _cQuery  := ""
	Local _nItens  := 0

	// parametros ok
	local _lParamOk := .f.

	//Quantidade de Volumes
	Private _nQtdvol := 0

	//Numero total de Paginas
	Private _nPagTot   := 0
	Private _nPag      := 0
	Private _nTotItens := 0

	Private _aRetSQL  := {}
	Private _cDocMot  := ""
	Private _nLinBox1 := 0
	Private _nLinBox2 := 0

	// Totalizadores Peso, Volume e Cubagem
	Private _nSunPes := 0
	Private _nSunVol := 0
	Private _nSunCub := 0

	Private oBrush1 := TBrush():New( , CLR_HGRAY )
	Private oBrush2 := TBrush():New( , CLR_WHITE )

	//Controle de Posicionamento de colunas
	Private lin  := 50      // Distancia da linha vertical da margem esquerda
	Private lin1 := 330     // Distancia da linha vertical da margem superior
	Private lin2 := 1950    // Tamanho verttical da linha

	Private oFont10  := TFont():New("Arial",,-10,,.F.,,,,.F.,.F.)
	Private oFont10n := TFont():New("Arial",,-10,,.T.,,,,.F.,.F.)
	Private oFont11  := TFont():New("Arial",,-11,,.F.,,,,.F.,.F.)
	Private oFont12  := TFont():New("Arial",,-13,,.F.,,,,.F.,.F.)
	Private oFont13  := TFont():New("Arial",,-13,,.F.,,,,.F.,.F.)
	Private oFont20n := TFont():New("Arial",,-20,,.T.,,,,.F.,.F.)
	Private oFont28n := TFont():New("Arial",,-28,,.T.,,,,.F.,.F.)//Fonte28 Negrito

	// permite o carregamento sem a nota fiscal de venda do cliente
	private _lSemNfVend := .f.

	Private nFatVer	:= 0.250
	Private nFatHor	:= 0.240
	
	// monta a lista de perguntas
	aAdd(_aPerg,{"Carga: " , "C", TamSx3("DAK_COD")[1], 0, "G",,"", {{"X1_VALID","U_FtStrZero()"}} })//mv_par01
	aAdd(_aPerg,{"CESV:  " , "C", TamSx3("ZZ_CESV")[1], 0, "G",,"", {{"X1_VALID","U_FtStrZero()"}} })//mv_par02

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg, _aPerg)

	If EMPTY(cCESV)
		// chama a tela de parametros
		// abre os parametros
		If ! Pergunte(_cPerg,.T.)
			Return(.f.)
		EndIf
	Else
		MV_PAR01 := ""
		MV_PAR02 := cCESV
	EndIf
	// pesquisa a carga, para validar cliente
	If ( ! _lParamOk ) .and. ( ! Empty(mv_par01) )
		// itens da carga
		dbSelectArea("DAI")
		DAI->(dbSetOrder(1)) // 1-DAI_FILIAL, DAI_COD, DAI_SEQCAR, DAI_SEQUEN, DAI_PEDIDO
		If DAI->(dbSeek( xFilial("DAK") + mv_par01 ))
			// permite o carregamento sem a nota fiscal de venda do cliente
			_lSemNfVend := U_FtWmsParam("WMS_LIBERA_CARREGAMENTO_SEM_NF_VENDA", "L", .f., .f., "", DAI->DAI_CLIENT, DAI->DAI_LOJA, Nil, Nil)
			// parametros ok
			_lParamOk := .t.
		EndIf
	EndIf

	// pesquisa a cesv, para validar cliente
	If ( ! _lParamOk ) .and. ( ! Empty(mv_par02) )
		// cesv
		dbSelectArea("SZZ")
		SZZ->(dbSetOrder(1)) // 1-ZZ_FILIAL, ZZ_CESV
		If SZZ->(dbSeek( xFilial("SZZ") + mv_par02 ))
			// permite o carregamento sem a nota fiscal de venda do cliente
			_lSemNfVend := U_FtWmsParam("WMS_LIBERA_CARREGAMENTO_SEM_NF_VENDA", "L", .f., .f., "", SZZ->ZZ_CLIENTE, SZZ->ZZ_LOJA, Nil, Nil)
			// parametros ok
			_lParamOk := .t.
		EndIf
	EndIf


	// busca Cargas montadas com  os pedidos.
	_cQuery := " SELECT C9_PEDIDO,D2_DOC,D2_SERIE,D2_EMISSAO,C9_CARGA,C5_ZAGRUPA,C5_PBRUTO, C5_CUBAGEM, Z43_CESV, ZZ_DTCHEG, ZZ_HRCHEG, "
	_cQuery += " CASE WHEN ZZ_DOCA IS NULL THEN C6_LOCALIZ ELSE ZZ_DOCA END ZZ_DOCA,"
	_cQuery += " ZZ_DTSAI,ZZ_HRSAI,DA4_NOME,A4_NOME,ZZ_PLACA1,DA4_RG ,C5_ZPEDCLI,C5_ZDOCCLI,C5_VOLUME1,DA4_NUMCNH,DA4_CPF,  "
	_cQuery += " ZY_DTAGEND,ZY_HRAGEND,ZY_DTINIC,ZY_HRINIC,Z05_NUMOS "
	// cabecalho de cargas
	_cQuery += " FROM "+RetSqlTab("DAK")
	// item/pedidos da carga
	_cQuery += " INNER JOIN "+RetSqlTab("DAI")+" ON "+RetSqlCond('DAK')+" AND DAI_COD = DAK_COD "
	// cab. pedido de venda
	_cQuery += " INNER JOIN "+RetSqlTab("SC5")+" ON "+RetSqlCond("SC5")+" AND C5_NUM = DAI_PEDIDO "
	// filta Apenas com nota do cliente preenchida.
	If ( ! _lSemNfVend )
		_cQuery += " AND C5_ZDOCCLI <> ' ' "
	EndIf
	// itens do pedido de venda
	_cQuery += " INNER JOIN "+RetSqlTab("SC6")+" ON "+RetSqlCond("SC6")+" AND C6_NUM = C5_NUM "
	// itens liberados por pedido
	_cQuery += " INNER JOIN "+RetSqlTab("SC9")+" ON "+RetSqlCond("SC9")+" AND C9_PEDIDO = C6_NUM AND C9_ITEM = C6_ITEM AND C9_PRODUTO = C6_PRODUTO "
	// itens da nota fiscal
	_cQuery += " LEFT  JOIN "+RetSqlTab("SD2")+" ON "+RetSqlCond("SD2")+" AND SD2.D2_PEDIDO = C9_PEDIDO and D2_ITEMPV = C9_ITEM AND D2_COD = C9_PRODUTO "
	// conferencia de produtos
	_cQuery += " INNER JOIN "+RetSqlTab("Z07")+" ON "+RetSqlCond("Z07")+" AND SC5.C5_NUM = Z07.Z07_PEDIDO"
	// cab. OS
	_cQuery += " INNER JOIN "+RetSqlTab("Z05")+" ON "+RetSqlCond("Z05")+" AND Z05.Z05_NUMOS = Z07.Z07_NUMOS "
	// cad de embalagem
	_cQuery += " LEFT  JOIN "+RetSqlTab("Z31")+" ON "+RetSqlCond("Z31")+" AND Z31.Z31_CODIGO = Z07.Z07_EMBALA"
	// pra contemplar a nova rotina de vinculação de pedidos a CESV
	_cQuery += " LEFT JOIN "+RetSqlTab("Z43")+" ON "+RetSqlCond("Z43")+" AND Z43_NUMOS = Z05_NUMOS AND Z43_PEDIDO = C6_NUM AND Z43_STATUS = 'R' "
	// movimentacao de veiculo
	_cQuery += " LEFT JOIN "+RetSqlTab("SZZ")+" ON "+RetSqlCond("SZZ")+" AND SZZ.ZZ_CESV = Z43_CESV "
	// Motoristas
	_cQuery += " LEFT JOIN "+RetSqlTab("DA4")+" ON "+RetSqlCond("DA4")+" AND SZZ.ZZ_MOTORIS = DA4.DA4_COD  "
	// Transportadoras
	_cQuery += " LEFT JOIN "+RetSqlTab("SA4")+" ON "+RetSqlCond("SA4")+" AND SZZ.ZZ_TRANSP = SA4.A4_COD  "
	// Agendamento
	_cQuery += " LEFT JOIN "+RetSqlTab("SZY")+" ON "+RetSqlCond("SZY")+" AND SZY.ZY_SEQUENC = ZZ_AGENDA  "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond('DAK')
	// filta codigo da carga
	If ( ! Empty(mv_par01) )
		_cQuery += " AND DAK.DAK_COD = '"+mv_par01+"' "
	EndIf
	// se a pesquisa for por CESV
	If ( ! Empty(mv_par02) )
		_cQuery += " AND DAK.DAK_COD = (CASE WHEN Z05_CARGA = '' THEN Z43_CARGA ELSE Z05_CARGA END) "
		_cQuery += " AND Z43_CESV = '"+mv_par02+"' "
	EndIf

	// ordem dos dados
	_cQuery += " GROUP  BY C9_PEDIDO,D2_DOC,D2_SERIE,D2_EMISSAO,C9_CARGA,C5_PBRUTO, C5_CUBAGEM, C5_ZAGRUPA,Z05_CESV,ZZ_DTCHEG,ZZ_HRCHEG,ZZ_DOCA,C6_LOCALIZ,ZZ_DTSAI,ZZ_HRSAI,DA4_NOME,A4_NOME,ZZ_PLACA1,DA4_RG,C5_ZPEDCLI,C5_ZDOCCLI,C5_VOLUME1,DA4_NUMCNH,DA4_CPF,  "
	_cQuery += " ZY_DTAGEND,ZY_HRAGEND,ZY_DTINIC,ZY_HRINIC,Z05_NUMOS, Z43_CESV "

	memowrit("c:\query\TWMSR019.txt",_cQuery)

	// carrega resultado do SQL na variavel.
	_aRetSQL := U_SqlToVet(_cQuery)

	If (Len(_aRetSQL) <= 0)
		MsgStop("Sem informações para Imprimir." + CRLF + " Verifique se o carregamento já foi concluído pelo coletor de dados (operação finalizada).")

		//mensagem de ajuda complementar, caso o cliente tenha o parâmetro setado para não liberar carregamento sem NF venda.
		If (!_lSemNfVend)
			MsgStop("Cliente código " + SZZ->ZZ_CLIENTE + " exige que os pedidos de venda estejam com os campos 'Documento cliente' e/ou 'Pedido cliente' preenchidos. Verifique com o account responsável pela conta!")
		EndIf
		Return(.F.)
	EndIf

	// total de itens
	_nTotItens := Len(_aRetSQL)

	// divisao de pagina 40 itens a partir da 2ª pagina.
	_nPagTot := 1

	// recalcula quantidade de itens restantes
	_nTotItens -= 10

	// quantidade de paginas adicionais
	If Int(_nTotItens / 40) > 0
		_nPagTot += Int(_nTotItens / 40)

		_nTotItens -= 40 * Int(_nTotItens / 40)
	EndIf

	If _nTotItens > 0
		_nPagTot ++
	EndIF

	// Monta objeto para impressão
	//oPrint:= TMSPrinter():New("Romaneio de Carga")
	If EMPTY(cPrinter)
		oPrint := FWMSPrinter():New('CESV'+AllTrim(MV_PAR02)+AllTrim(Str(Randomize(1,10000))),IMP_PDF,.F.,,.F.)
		// verifica se impressora ja esta configurada
		If ( ! oPrint:IsPrinterActive() )
			//-- Escolhe a impressora
			oPrint:Setup()
			// verifica novamente se impressora ja esta configurada
			If ( ! oPrint:IsPrinterActive() )
				Help(" ",1,"NOPRINTGRA")
				Return(Nil)
			Endif
		Endif
	Else
		oPrint := FWMSPrinter():New('CESV'+AllTrim(MV_PAR02)+AllTrim(Str(Randomize(1,10000))),IMP_SPOOL,.F.,,.T.,,,cPrinter,.T.)
	EndIf
	
	// forca orientacao da pagina
	oPrint:SetPortrait()

	// total de itens
	_nTotItens := Len(_aRetSQL)

	sfCabenf()

	// varre todos os itens da carga
	For _nBox := 1 To Len(_aRetSQL)

		// busca cubagem do pedido
		_nCubag := sfPegCubag(_aRetSQL[_nBox][01])

		// quando nao calcular cubagem pela embalagem, usar do cabecalho do pedido
		If (_nCubag == 0)
			_nCubag := _aRetSQL[_nBox][08]
		EndIf

		_nSunVol += _aRetSQL[_nBox][21]
		_nSunPes += _aRetSQL[_nBox][07]
		_nSunCub += _nCubag

		oPrint:Say(_nLinBox1*nFatHor  ,0100*nFatHor ,Alltrim(_aRetSQL[_nBox][01])                                  ,oFont10)
		oPrint:Say(_nLinBox1*nFatHor  ,0310*nFatHor ,Alltrim(_aRetSQL[_nBox][19])                                  ,oFont10)
		oPrint:Say(_nLinBox1*nFatHor  ,0590*nFatHor ,Alltrim(_aRetSQL[_nBox][20])                                  ,oFont10)
		oPrint:Say(_nLinBox1*nFatHor  ,0910*nFatHor ,Alltrim(dtoc(Stod(_aRetSQL[_nBox][4])))                       ,oFont10)
		oPrint:Say(_nLinBox1*nFatHor  ,1210*nFatHor ,Alltrim(_aRetSQL[_nBox][5])                                   ,oFont10)
		oPrint:Say(_nLinBox1*nFatHor  ,1720*nFatHor ,Alltrim(TransForm(_aRetSQL[_nBox][21] ,"@E 99,999,999.9999")) ,oFont10, , , ,2)
		oPrint:Say(_nLinBox1*nFatHor  ,1970*nFatHor ,Alltrim(TransForm(_aRetSQL[_nBox][7]  ,"@E 99,999,999.9999")) ,oFont10, , , ,2)
		oPrint:Say(_nLinBox1*nFatHor  ,2220*nFatHor ,Alltrim(TransForm(_nCubag             ,"@E 99,999,999.9999")) ,oFont10, , , ,2)

		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50
		_nItens++

		If (_nItens == 10) .And. Len(_aRetSQL) == 10
			sfRodanf(_nPag,.T.)
			_nItens := 0
			_nPag++
			oPrint:EndPage()
		ElseIf (_nItens == 10) .And. (_nPag == 1)
			sfRodanf(_nPag,.F.)
			oPrint:EndPage()
			sfCabenf()
			_nItens := 0
		ElseIf(Len(_aRetSQL) == _nBox)
			sfRodanf(_nPag,.T.)
			_nPag++
			_nItens := 0
			oPrint:EndPage()
		ElseIf (_nItens == 40)
			sfRodanf(_nPag,.F.)
			oPrint:EndPage()
			sfCabenf()
			_nItens := 0
		EndIf

	Next _nBox
	
	If EMPTY(cPrinter)
		// Visualiza a impressão
		oPrint:Preview()
	Else
		//Manda direto para a impressora caso seja passada por parâmetro
		oPrint:Print()
	EndIf
	
Return()

//Função que faz a media de peso do produto em uma determinada Nota Fiscal
Static Function sfPegCubag(mvPedido)

	Local _nRet      := 0
	Local _nx        := 0
	Local _cQueryPB  := ""
	Local _aRetCub   := ""
	Default mvpedido := ""

	// Buscar Notas.
	_cQueryPB := "SELECT "
	_cQueryPB += " DISTINCT(Z07_ETQVOL) Z07_ETQVOL,Z31_CUBAGE"
	// itens da nota fiscal de retorno
	_cQueryPB += " FROM "+RetSqlTab("SD2")
	// cab. da nota fiscal
	_cQueryPB += " INNER JOIN "+RetSqlTab("SF2")+" ON "+RetSqlCond("SF2")+" AND SF2.F2_DOC     = SD2.D2_DOC AND SF2.F2_SERIE = SD2.D2_SERIE "
	// itens liberados
	_cQueryPB += " INNER JOIN "+RetSqlTab("SC9")+" ON "+RetSqlCond("SC9")+" AND SD2.D2_PEDIDO  = SC9.C9_PEDIDO AND SC9.C9_ITEM = SD2.D2_ITEMPV AND SD2.D2_COD = SC9.C9_PRODUTO "
	// pedido de venda
	_cQueryPB += " INNER JOIN "+RetSqlTab("SC5")+" ON "+RetSqlCond("SC5")+" AND SC5.C5_NUM     = SC9.C9_PEDIDO"
	// filta Apenas com nota do cliente preenchida.
	If ( ! _lSemNfVend )
		_cQueryPB += " AND C5_ZDOCCLI <> '' "
	EndIf
	// itens conferidos
	_cQueryPB += " INNER JOIN "+RetSqlTab("Z07")+" ON "+RetSqlCond("Z07")+" AND SC5.C5_NUM     = Z07.Z07_PEDIDO AND SD2.D2_COD = Z07.Z07_PRODUT AND Z07_SEQOS = '002'"
	//
	_cQueryPB += " INNER JOIN "+RetSqlTab("Z06")+" ON "+RetSqlCond("Z06")+" AND Z06.Z06_NUMOS  = Z07.Z07_NUMOS AND Z06_SEQOS = Z07_SEQOS AND Z06_TAREFA = '007'"
	//
	_cQueryPB += " INNER JOIN "+RetSqlTab("Z31")+" ON "+RetSqlCond("Z31")+" AND Z31.Z31_CODIGO = Z07.Z07_EMBALA"
	// cab. Ord Servico
	_cQueryPB += " INNER JOIN "+RetSqlTab("Z05")+" ON "+RetSqlCond("Z05")+" AND Z05.Z05_NUMOS  = Z07.Z07_NUMOS AND D2_COD = Z07_PRODUT "

	// filtro padrao
	_cQueryPB += " WHERE "+RetSqlCond('SD2')
	// documento emitido
	_cQueryPB += " AND SC5.C5_NUM   = '"+mvPedido+"'"

	memowrit("c:\query\twmsr019_sfPegCubag.txt",_cQueryPB)

	// carrega resultado do SQL na variavel.
	_aRetCub := U_SqlToVet(_cQueryPB)

	For _nx := 1 To Len(_aRetCub)

		_nRet += _aRetCub[_nx][2]

	Next _nx

Return(_nRet)


//Função para pegar a maior sequencia de uma OS.
Static Function sfBusMaxSq(mvCarga)

	Local _cRet      := ""
	Local _cQuerySQ  := ""
	Default mvCarga  := ""

	// Buscar Notas.
	_cQuerySQ := "SELECT "
	_cQuerySQ += " MAX(Z06_SEQOS) Z06_SEQOS"
	// itens da nota fiscal de retorno
	_cQuerySQ += " FROM "+RetSqlTab("SD2")
	// cab. da nota fiscal
	_cQuerySQ += " INNER JOIN "+RetSqlTab("SF2")+" ON "+RetSqlCond("SF2")+" AND SF2.F2_DOC     = SD2.D2_DOC AND SF2.F2_SERIE = SD2.D2_SERIE "
	// itens liberados
	_cQuerySQ += " INNER JOIN "+RetSqlTab("SC9")+" ON "+RetSqlCond("SC9")+" AND SD2.D2_PEDIDO  = SC9.C9_PEDIDO AND SC9.C9_ITEM = SD2.D2_ITEMPV AND SD2.D2_COD = SC9.C9_PRODUTO "
	// pedido de venda
	_cQuerySQ += " INNER JOIN "+RetSqlTab("SC5")+" ON "+RetSqlCond("SC5")+" AND SC5.C5_NUM     = SC9.C9_PEDIDO"
	// filta Apenas com nota do cliente preenchida.
	If ( ! _lSemNfVend )
		_cQuerySQ += " AND C5_ZDOCCLI <> ' ' "
	EndIf
	// itens conferidos
	_cQuerySQ += " INNER JOIN "+RetSqlTab("Z07")+" ON "+RetSqlCond("Z07")+" AND SC5.C5_NUM     = Z07.Z07_PEDIDO AND SD2.D2_COD = Z07.Z07_PRODUT "
	//
	_cQuerySQ += " INNER JOIN "+RetSqlTab("Z06")+" ON "+RetSqlCond("Z06")+" AND Z06.Z06_NUMOS  = Z07.Z07_NUMOS AND Z06_SEQOS = Z07_SEQOS "
	//
	_cQuerySQ += " INNER JOIN "+RetSqlTab("Z31")+" ON "+RetSqlCond("Z31")+" AND Z31.Z31_CODIGO = Z07.Z07_EMBALA"
	// cab. Ord Servico
	_cQuerySQ += " INNER JOIN "+RetSqlTab("Z05")+" ON "+RetSqlCond("Z05")+" AND Z05.Z05_NUMOS  = Z07.Z07_NUMOS AND D2_COD = Z07_PRODUT "

	// filtro padrao
	_cQuerySQ += " WHERE "+RetSqlCond('SD2')
	// documento emitido
	_cQuerySQ += " AND SC9.C9_CARGA   = '"+mvCarga+"'"

	memowrit("c:\query\twmsr019_sfPegeqMax.txt",_cQuerySQ)

	// carrega resultado do SQL na variavel.
	_cRet := U_FTQuery(_cQuerySQ)

Return(_cRet)

//Imprime Cabeçalho do relatório
Static Function sfCabenf(mvNumPed,mvNumDoc)

	Local _iy := 0
	_cDocMot := ""
	_nPag++
	oPrint:StartPage()

	oPrint:SayBitmap(-40,3,"logo_tecadi_group.png",275,175 )// Logo
	oPrint:Say(0150*nFatVer,1100*nFatHor,"Romaneio de Carga",oFont28n)
	oPrint:Say(0280*nFatVer,1000*nFatHor,"Comprovante de carregamento e Protocolo de Documentos",oFont13)

	_nLinBox1 := 500
	_nLinBox2 := 500

	oPrint:fillRect( { 115, 050*nFatVer, 130, 2300*nFatVer}, oBrush1 )
	_nLinBox1 := _nLinBox1 + 5
	_nLinBox2 := _nLinBox2 + 5
	//505

	oPrint:Say((_nLinBox1-70)*nFatVer  ,2220*nFatHor ,"Pag " + Alltrim(Str(_nPag)) +  "/" + Alltrim(Str(_nPagTot)) ,oFont10n, , , ,2)
	oPrint:Say(_nLinBox1*nFatVer       ,0100*nFatHor ,"Dados de controle",oFont10)

	_nLinBox1 := _nLinBox1 + 50
	_nLinBox2 := _nLinBox2 + 50

	oPrint:Say((_nLinBox1)*nFatVer,0100*nFatHor ,"Nº CESV: "              ,oFont10 , , , ,)
	oPrint:Say((_nLinBox1)*nFatVer,0400*nFatHor ,Alltrim(_aRetSQL[1][9])  ,oFont10n, , , ,)
	oPrint:Say((_nLinBox1)*nFatVer,1250*nFatHor ,"Nº Carga (DLN): "       ,oFont10 , , , ,)
	oPrint:Say((_nLinBox1)*nFatVer,1550*nFatHor ,Alltrim(_aRetSQL[1][6])  ,oFont10n, , , ,)

	_nLinBox1 := _nLinBox1 + 50
	_nLinBox2 := _nLinBox2 + 50

	oPrint:Say((_nLinBox1)*nFatVer,0100*nFatHor ,"Data/hora prevista: "                               ,oFont10 , , , ,)
	oPrint:Say((_nLinBox1)*nFatVer,0400*nFatHor ,Alltrim(dtoc(Stod(_aRetSQL[1][24]))) + " / " + Alltrim(_aRetSQL[1][25]),oFont10n, , , ,)
	oPrint:Say((_nLinBox1)*nFatVer,1250*nFatHor ,"Stage/Doca: "                                       ,oFont10 , , , ,)
	oPrint:Say((_nLinBox1)*nFatVer,1550*nFatHor ,Alltrim(_aRetSQL[1][12])                             ,oFont10n, , , ,)

	_nLinBox1 := _nLinBox1 + 50
	_nLinBox2 := _nLinBox2 + 50

	oPrint:Say((_nLinBox1)*nFatVer,0100*nFatHor ,"Data/hora início: "                                  ,oFont10 , , , ,)
	oPrint:Say((_nLinBox1)*nFatVer,0400*nFatHor ,Alltrim(dtoc(Stod(_aRetSQL[1][26]))) + " / " + Alltrim(_aRetSQL[1][27]) ,oFont10n, , , ,)

	_cMaxSeq := sfBusMaxSq(_aRetSQL[1][05])

	dbSelectArea("Z06")
	Z06->(dbsetorder(1))//Z06_FILIAL+Z06_NUMOS+Z06_SEQOS
	If (Z06->(dbSeek(xFilial("Z06") + _aRetSQL[1][28] + _cMaxSeq )))
		oPrint:Say((_nLinBox1)*nFatVer,1250*nFatHor ,"Data/hora término: "                                 ,oFont10 , , , ,)
		oPrint:Say((_nLinBox1)*nFatVer,1550*nFatHor ,Alltrim(dtoc(Z06->Z06_DTFIM)) + " / " + Alltrim(Z06->Z06_HRFIM) ,oFont10n, , , ,)
	Else
		oPrint:Say((_nLinBox1)*nFatVer,1250*nFatHor ,"Data/hora término: "                                 ,oFont10 , , , ,)
		oPrint:Say((_nLinBox1)*nFatVer,1550*nFatHor ,"" + " / " + "" ,oFont10n, , , ,)
	EndIf
	_nLinBox1 := _nLinBox1 + 100
	_nLinBox2 := _nLinBox2 + 100

	oPrint:fillRect( { 177, 050*nFatVer,192, 2300*nFatVer}, oBrush1 )
	oPrint:Say(_nLinBox1*nFatVer  ,0100*nFatHor ,"Dados do transporte"      ,oFont10)

	_nLinBox1 := _nLinBox1 + 50
	_nLinBox2 := _nLinBox2 + 50

	oPrint:Say((_nLinBox1)*nFatVer,0100*nFatHor ,"Transportadora: "         ,oFont10 , , , ,)
	oPrint:Say((_nLinBox1)*nFatVer,0400*nFatHor ,Alltrim(_aRetSQL[1][16])   ,oFont10n, , , ,)
	oPrint:Say((_nLinBox1)*nFatVer,1250*nFatHor ,"Motorista: "              ,oFont10 , , , ,)
	oPrint:Say((_nLinBox1)*nFatVer,1550*nFatHor ,Alltrim(_aRetSQL[1][15])   ,oFont10n, , , ,)

	_nLinBox1 := _nLinBox1 + 50
	_nLinBox2 := _nLinBox2 + 50

	If !(Empty(_aRetSQL[1][18]))
		_cDocMot:= "RG: " + Alltrim(_aRetSQL[1][18])+" "
	End


	If !(Empty(_aRetSQL[1][22]))
		_cDocMot+= "CNH: " + Alltrim(_aRetSQL[1][22])+" "
	End

	If !(Empty(_aRetSQL[1][23]))
		_cDocMot+= "CPF: " + Alltrim(_aRetSQL[1][23])+" "
	End

	oPrint:Say((_nLinBox1)*nFatVer,0100*nFatHor ,"Veículo(placas): "        ,oFont10 , , , ,)
	oPrint:Say((_nLinBox1)*nFatVer,0400*nFatHor ,Alltrim(_aRetSQL[1][17])   ,oFont10n, , , ,)
	oPrint:Say((_nLinBox1)*nFatVer,1250*nFatHor ,"Doc. Motorista: "         ,oFont10 , , , ,)
	oPrint:Say((_nLinBox1)*nFatVer,1550*nFatHor ,_cDocMot                   ,oFont10n, , , ,)

	_nLinBox1 := _nLinBox1 + 100
	_nLinBox2 := _nLinBox2 + 100

	oPrint:fillRect( { 230, 050*nFatVer, 245, 2300*nFatVer}, oBrush1 )
	oPrint:Say(_nLinBox1*nFatVer  ,0100*nFatHor ,"Detalhamento da carga",oFont10)

	_nLinBox1 := _nLinBox1 + 50
	_nLinBox2 := _nLinBox2 + 50

	oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,0275*nFatVer )
	oPrint:Box( _nLinBox1*nFatHor,0275*nFatVer,(_nLinBox2 + 50)*nFatHor,0515*nFatVer )
	oPrint:Box( _nLinBox1*nFatHor,0515*nFatVer ,(_nLinBox2 + 50)*nFatHor,0800*nFatVer )
	oPrint:Box( _nLinBox1*nFatHor,0800*nFatVer ,(_nLinBox2 + 50)*nFatHor,1050*nFatVer )
	oPrint:Box( _nLinBox1*nFatHor,1050*nFatVer ,(_nLinBox2 + 50)*nFatHor,1450*nFatVer )
	oPrint:Box( _nLinBox1*nFatHor,1450*nFatVer ,(_nLinBox2 + 50)*nFatHor,1800*nFatVer )
	oPrint:Box( _nLinBox1*nFatHor,1800*nFatVer ,(_nLinBox2 + 50)*nFatHor,2050*nFatVer )
	oPrint:Box( _nLinBox1*nFatHor,2050*nFatVer ,(_nLinBox2 + 50)*nFatHor,2300*nFatVer )

	oPrint:Say(_nLinBox1*nFatVer  ,0100*nFatHor ,"PEDIDO "           ,oFont10n)
	oPrint:Say(_nLinBox1*nFatVer  ,0310*nFatHor ,"PEDIDO CLI."       ,oFont10n)
	oPrint:Say(_nLinBox1*nFatVer  ,0590*nFatHor ,"NF. VENDA"         ,oFont10n)
	oPrint:Say(_nLinBox1*nFatVer  ,0910*nFatHor ,"EMISSÃO"           ,oFont10n)
	oPrint:Say(_nLinBox1*nFatVer  ,1210*nFatHor ,"Nº CARGA"          ,oFont10n)
	oPrint:Say(_nLinBox1*nFatVer  ,1610*nFatHor ,"QT. VOLUMES"       ,oFont10n)
	oPrint:Say(_nLinBox1*nFatVer  ,1930*nFatHor ,"P. BRUTO"          ,oFont10n)
	oPrint:Say(_nLinBox1*nFatVer  ,2155*nFatHor ,"CUBAGEM"           ,oFont10n)
	_nLinBox1 := _nLinBox1 + 50
	_nLinBox2 := _nLinBox2 + 50

	If _nPag == 1

		_nTotItens := _nTotItens - 10

		For _iy:= 1 To 11
			oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,0275*nFatVer )
			oPrint:Box( _nLinBox1*nFatHor,0275*nFatVer,(_nLinBox2 + 50)*nFatHor,0515*nFatVer )
			oPrint:Box( _nLinBox1*nFatHor,0515*nFatVer ,(_nLinBox2 + 50)*nFatHor,0800*nFatVer )
			oPrint:Box( _nLinBox1*nFatHor,0800*nFatVer ,(_nLinBox2 + 50)*nFatHor,1050*nFatVer )
			oPrint:Box( _nLinBox1*nFatHor,1050*nFatVer ,(_nLinBox2 + 50)*nFatHor,1450*nFatVer )
			oPrint:Box( _nLinBox1*nFatHor,1450*nFatVer ,(_nLinBox2 + 50)*nFatHor,1800*nFatVer )
			oPrint:Box( _nLinBox1*nFatHor,1800*nFatVer ,(_nLinBox2 + 50)*nFatHor,2050*nFatVer )
			oPrint:Box( _nLinBox1*nFatHor,2050*nFatVer ,(_nLinBox2 + 50)*nFatHor,2300*nFatVer )
			_nLinBox1 := _nLinBox1 + 50
			_nLinBox2 := _nLinBox2 + 50
		Next _iy

		//_nLinBox1 := 1055
		//_nLinBox2 := 1055
		_nLinBox1 := 1090
		_nLinBox2 := 1090

	Else

		If _nTotItens >= 40

			For _iy:= 1 To 41
				oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,0275*nFatVer )
				oPrint:Box( _nLinBox1*nFatHor,0275*nFatVer,(_nLinBox2 + 50)*nFatHor,0515*nFatVer )
				oPrint:Box( _nLinBox1*nFatHor,0515*nFatVer ,(_nLinBox2 + 50)*nFatHor,0800*nFatVer )
				oPrint:Box( _nLinBox1*nFatHor,0800*nFatVer ,(_nLinBox2 + 50)*nFatHor,1050*nFatVer )
				oPrint:Box( _nLinBox1*nFatHor,1050*nFatVer ,(_nLinBox2 + 50)*nFatHor,1450*nFatVer )
				oPrint:Box( _nLinBox1*nFatHor,1450*nFatVer ,(_nLinBox2 + 50)*nFatHor,1800*nFatVer )
				oPrint:Box( _nLinBox1*nFatHor,1800*nFatVer ,(_nLinBox2 + 50)*nFatHor,2050*nFatVer )
				oPrint:Box( _nLinBox1*nFatHor,2050*nFatVer ,(_nLinBox2 + 50)*nFatHor,2300*nFatVer )
				_nLinBox1 := _nLinBox1 + 50
				_nLinBox2 := _nLinBox2 + 50
			Next _iy
			_nTotItens := _nTotItens - 40
		Else

			For _iy:= 1 To (_nTotItens )
				oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,0275*nFatVer )
				oPrint:Box( _nLinBox1*nFatHor,0275*nFatVer,(_nLinBox2 + 50)*nFatHor,0515*nFatVer )
				oPrint:Box( _nLinBox1*nFatHor,0515*nFatVer ,(_nLinBox2 + 50)*nFatHor,0800*nFatVer )
				oPrint:Box( _nLinBox1*nFatHor,0800*nFatVer ,(_nLinBox2 + 50)*nFatHor,1050*nFatVer )
				oPrint:Box( _nLinBox1*nFatHor,1050*nFatVer ,(_nLinBox2 + 50)*nFatHor,1450*nFatVer )
				oPrint:Box( _nLinBox1*nFatHor,1450*nFatVer ,(_nLinBox2 + 50)*nFatHor,1800*nFatVer )
				oPrint:Box( _nLinBox1*nFatHor,1800*nFatVer ,(_nLinBox2 + 50)*nFatHor,2050*nFatVer )
				oPrint:Box( _nLinBox1*nFatHor,2050*nFatVer ,(_nLinBox2 + 50)*nFatHor,2300*nFatVer )
				_nLinBox1 := _nLinBox1 + 50
				_nLinBox2 := _nLinBox2 + 50
			Next _iy
			_nTotItens := _nTotItens - _nTotItens
		EndIF
		//_nLinBox1 := 1055
		//_nLinBox2 := 1055
		_nLinBox1 := 1090
		_nLinBox2 := 1090

	EndIf
Return()

//Imprime Rodapé do relatório.
Static Function sfRodanf(mvPagina,mvFim)


	//é o final do arquivo e primeira pagina. Imprimir totalizador e informações para assinatura
	If (mvFim) .And. (mvPagina == 1)
		//_nLinBox1 := 1590
		//_nLinBox2 := 1590
		_nLinBox1 := 1620
		_nLinBox2 := 1620
		oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,0300*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,0580*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,0900*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,1200*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,1500*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,1800*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,2050*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,2300*nFatVer )

		oPrint:Say((_nLinBox1)*nFatHor,0100*nFatVer,"TOTAL"          ,oFont10n)
		oPrint:Say((_nLinBox1)*nFatHor  ,0310*nFatVer ,Alltrim(Str(Len(_aRetSQL)))+" NOTA(S)"                 ,oFont10n, , , , )
		oPrint:Say((_nLinBox1)*nFatHor  ,1610*nFatVer ,Alltrim(TransForm(_nSunVol     ,"@E 99,999,999.9999")) ,oFont10n, , , ,2)
		oPrint:Say((_nLinBox1)*nFatHor  ,1900*nFatVer ,Alltrim(TransForm(_nSunPes     ,"@E 99,999,999.9999")) ,oFont10n, , , ,2)
		oPrint:Say((_nLinBox1)*nFatHor  ,2155*nFatVer ,Alltrim(TransForm(_nSunCub     ,"@E 99,999,999.9999")) ,oFont10n, , , ,2)

		_nLinBox1 := _nLinBox1 + 130
		_nLinBox2 := _nLinBox2 + 130

		oPrint:fillRect( { 395, 050*nFatVer, 410, 2300*nFatVer}, oBrush1 )
		oPrint:Say(_nLinBox1*nFatHor  ,0100*nFatVer ,"Condições dos volumes/mercadorias",oFont10,2300)

		_nLinBox1 := _nLinBox1 + 100
		_nLinBox2 := _nLinBox2 + 100

		oPrint:Box( (_nLinBox1-25)*nFatHor,100*nFatVer ,(_nLinBox2)*nFatHor,0125*nFatVer )
		oPrint:Say((_nLinBox1)*nFatHor,0150*nFatVer ,"Volumes/mercadorias em perfeitas condições"                            ,oFont10 ,2300*nFatHor , , ,)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50

		oPrint:Box( (_nLinBox1-25)*nFatHor,100*nFatVer ,(_nLinBox2)*nFatHor,0125*nFatVer )
		oPrint:Say((_nLinBox1)*nFatHor,0150*nFatVer ,"Volumes/mercadorias com avarias ou indícios de violação"               ,oFont10 ,2300*nFatHor , , ,)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50

		oPrint:Box( (_nLinBox1-25)*nFatHor,100*nFatVer ,(_nLinBox2)*nFatHor,0125*nFatVer )
		oPrint:Say((_nLinBox1)*nFatHor,0150*nFatVer ,"Outros (especificar):___________________________________________________________________________________________",oFont10 ,2300*nFatHor , , ,)
		_nLinBox1 := _nLinBox1 + 100
		_nLinBox2 := _nLinBox2 + 100
		oPrint:Say((_nLinBox1)*nFatHor,0100*nFatVer ,"______________________________________________________________________________________________________________"  ,oFont10 ,2300*nFatHor, , ,)

		_nLinBox1 := _nLinBox1 + 100
		_nLinBox2 := _nLinBox2 + 100

		oPrint:fillRect( { 490, 050*nFatVer, 505, 2300*nFatVer}, oBrush1 )
		oPrint:Say(_nLinBox1*nFatHor  ,0100*nFatVer ,"Protocolo de documentos",oFont10,1400*nFatHor)

		_nLinBox1 := _nLinBox1 + 100
		_nLinBox2 := _nLinBox2 + 100

		oPrint:Box( (_nLinBox1-25)*nFatHor,100*nFatVer ,(_nLinBox2)*nFatHor,0125*nFatVer )
		oPrint:Say((_nLinBox1)*nFatHor,0150*nFatHor ,"Nota Fiscal",oFont10 ,2300*nFatHor , , ,)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50

		oPrint:Box( (_nLinBox1-25)*nFatHor,100*nFatVer ,(_nLinBox2)*nFatHor,0125*nFatVer )
		oPrint:Say((_nLinBox1)*nFatHor,0150*nFatVer ,"Certificados (lote , análise, etc) - apenas se aplicavel",oFont10 ,2300*nFatHor, , ,)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50

		oPrint:Box( (_nLinBox1-25)*nFatHor,100*nFatVer ,(_nLinBox2)*nFatHor,0125*nFatVer )
		oPrint:Say((_nLinBox1)*nFatHor,0150*nFatVer ,"Ficha de emergência - apenas se aplicável",oFont10 , 2300*nFatHor, , ,)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50

		oPrint:Box( (_nLinBox1-25)*nFatHor,100*nFatVer ,(_nLinBox2)*nFatHor,0125*nFatVer )
		oPrint:Say((_nLinBox1)*nFatHor,0150*nFatVer ,"Outros (especificar):___________________________________________________________________________________________"   ,oFont10 , 2300*nFatHor, , ,)
		_nLinBox1 := _nLinBox1 + 100
		_nLinBox2 := _nLinBox2 + 100
		oPrint:Say((_nLinBox1)*nFatHor,0100*nFatVer ,"______________________________________________________________________________________________________________"   ,oFont10 ,2300*nFatHor , , ,)

		_nLinBox1 := _nLinBox1 + 100
		_nLinBox2 := _nLinBox2 + 100

		oPrint:fillRect( { 600, 050*nFatVer, 615, 2300*nFatVer}, oBrush1 )
		oPrint:Say(_nLinBox1*nFatHor  ,0100*nFatVer ,"Declaração e Assinatura",oFont10,)

		_nLinBox1 := _nLinBox1 + 100
		_nLinBox2 := _nLinBox2 + 100

		oPrint:Say((_nLinBox1)*nFatHor  ,0100*nFatVer ,"Eu, ________________________________________________________________, portador do documento ______________________,     ",oFont10,2300*nFatHor)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50
		oPrint:Say((_nLinBox1)*nFatHor  ,0100*nFatVer ,"por ser verdade, firmo que recebi e conferi os volumes/mercadorias das notas fiscais acima relacionadas, conforme carrega-  ",oFont10,2300*nFatHor)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50
		oPrint:Say((_nLinBox1)*nFatHor  ,0100*nFatVer ,"mento realizado nesta data, ficando, desde então, sob minha responsabilidade a guarda de toda carga e documentos fiscais     ",oFont10,2300*nFatHor)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50
		oPrint:Say((_nLinBox1)*nFatHor  ,0100*nFatVer ,"até a entrega ao destino final.",oFont10)

		_nLinBox1 := _nLinBox1 + 150
		_nLinBox2 := _nLinBox2 + 150

		oPrint:Say((_nLinBox1)*nFatHor      ,0060*nFatVer ,"__________________________________",oFont10n, , , , 0)
		oPrint:Say((_nLinBox1 + 50)*nFatHor ,0350*nFatVer ,"Data",oFont10n, , , , 0)

		oPrint:Say((_nLinBox1)*nFatHor      ,850*nFatVer ,"__________________________________",oFont10n, , , , 2)
		oPrint:Say((_nLinBox1 + 50)*nFatHor ,0950*nFatVer ,"Responsavel da Transportadora"     ,oFont10n, , , , 0)

		oPrint:Say((_nLinBox1)*nFatHor      ,1650*nFatVer ,"__________________________________",oFont10n, , , , 1)
		oPrint:Say((_nLinBox1 + 50)*nFatHor ,1850*nFatVer ,"Conferente",oFont10n, , , , 0)

		//É o final do arquivo e não é primeira pagina apenas totalizador.
	ElseIf mvFim

		/*oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,0275*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,0275*nFatVer,(_nLinBox2 + 50)*nFatHor,0515*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,0515*nFatVer ,(_nLinBox2 + 50)*nFatHor,0800*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,0800*nFatVer ,(_nLinBox2 + 50)*nFatHor,1050*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,1050*nFatVer ,(_nLinBox2 + 50)*nFatHor,1450*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,1450*nFatVer ,(_nLinBox2 + 50)*nFatHor,1800*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,1800*nFatVer ,(_nLinBox2 + 50)*nFatHor,2050*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,2050*nFatVer ,(_nLinBox2 + 50)*nFatHor,2300*nFatVer )*/
		//_nLinBox1 := 3105 - 50
		oPrint:Say((_nLinBox1)*nFatHor,0100*nFatVer,"TOTAL"          ,oFont10n)
		oPrint:Say((_nLinBox1)*nFatHor  ,0310*nFatVer ,Alltrim(Str(Len(_aRetSQL)))+" NOTA(S)"                 ,oFont10n, , , , )
		oPrint:Say((_nLinBox1)*nFatHor  ,1610*nFatVer ,Alltrim(TransForm(_nSunVol     ,"@E 99,999,999.9999")) ,oFont10n, , , ,2)
		oPrint:Say((_nLinBox1)*nFatHor  ,1900*nFatVer ,Alltrim(TransForm(_nSunPes     ,"@E 99,999,999.9999")) ,oFont10n, , , ,2)
		oPrint:Say((_nLinBox1)*nFatHor  ,2155*nFatVer ,Alltrim(TransForm(_nSunCub     ,"@E 99,999,999.9999")) ,oFont10n, , , ,2)

		//Não é final de arquivo e é primeira pagina. imprime informações para assinatura.
	ElseIf !(mvFim) .And. (mvPagina == 1)

		_nLinBox1 := 1555
		_nLinBox2 := 1555
		//_nLinBox1 := 1585
		//_nLinBox2 := 1585
		oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,0275*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,0275*nFatVer,(_nLinBox2 + 50)*nFatHor,0515*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,0515*nFatVer ,(_nLinBox2 + 50)*nFatHor,0800*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,0800*nFatVer ,(_nLinBox2 + 50)*nFatHor,1050*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,1050*nFatVer ,(_nLinBox2 + 50)*nFatHor,1450*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,1450*nFatVer ,(_nLinBox2 + 50)*nFatHor,1800*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,1800*nFatVer ,(_nLinBox2 + 50)*nFatHor,2050*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,2050*nFatVer ,(_nLinBox2 + 50)*nFatHor,2300*nFatVer )

		oPrint:Say( (_nLinBox1+40)*nFatHor,070*nFatVer,"CONTINUA..."          ,oFont10n)

		_nLinBox1 := _nLinBox1 + 130
		_nLinBox2 := _nLinBox2 + 130

		oPrint:fillRect( { 395, 050*nFatVer, 410, 2300*nFatVer}, oBrush1 )
		oPrint:Say(_nLinBox1*nFatHor  ,0100*nFatVer ,"Condições dos volumes/mercadorias",oFont10,2300)

		_nLinBox1 := _nLinBox1 + 100
		_nLinBox2 := _nLinBox2 + 100

		oPrint:Box( (_nLinBox1-25)*nFatHor,100*nFatVer ,(_nLinBox2)*nFatHor,0125*nFatVer )
		oPrint:Say((_nLinBox1)*nFatHor,0150*nFatVer ,"Volumes/mercadorias em perfeitas condições"                            ,oFont10 ,2300*nFatHor , , ,)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50

		oPrint:Box( (_nLinBox1-25)*nFatHor,100*nFatVer ,(_nLinBox2)*nFatHor,0125*nFatVer )
		oPrint:Say((_nLinBox1)*nFatHor,0150*nFatVer ,"Volumes/mercadorias com avarias ou indícios de violação"               ,oFont10 ,2300*nFatHor , , ,)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50

		oPrint:Box( (_nLinBox1-25)*nFatHor,100*nFatVer ,(_nLinBox2)*nFatHor,0125*nFatVer )
		oPrint:Say((_nLinBox1)*nFatHor,0150*nFatVer ,"Outros (especificar):___________________________________________________________________________________________",oFont10 ,2300*nFatHor , , ,)
		_nLinBox1 := _nLinBox1 + 100
		_nLinBox2 := _nLinBox2 + 100
		oPrint:Say((_nLinBox1)*nFatHor,0100*nFatVer ,"______________________________________________________________________________________________________________"  ,oFont10 ,2300*nFatHor, , ,)

		_nLinBox1 := _nLinBox1 + 100
		_nLinBox2 := _nLinBox2 + 100

		oPrint:fillRect( { 490, 050*nFatVer, 505, 2300*nFatVer}, oBrush1 )
		oPrint:Say(_nLinBox1*nFatHor  ,0100*nFatVer ,"Protocolo de documentos",oFont10,1400*nFatHor)

		_nLinBox1 := _nLinBox1 + 100
		_nLinBox2 := _nLinBox2 + 100

		oPrint:Box( (_nLinBox1-25)*nFatHor,100*nFatVer ,(_nLinBox2)*nFatHor,0125*nFatVer )
		oPrint:Say((_nLinBox1)*nFatHor,0150*nFatHor ,"Nota Fiscal",oFont10 ,2300*nFatHor , , ,)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50

		oPrint:Box( (_nLinBox1-25)*nFatHor,100*nFatVer ,(_nLinBox2)*nFatHor,0125*nFatVer )
		oPrint:Say((_nLinBox1)*nFatHor,0150*nFatVer ,"Certificados (lote , análise, etc) - apenas se aplicavel",oFont10 ,2300*nFatHor, , ,)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50

		oPrint:Box( (_nLinBox1-25)*nFatHor,100*nFatVer ,(_nLinBox2)*nFatHor,0125*nFatVer )
		oPrint:Say((_nLinBox1)*nFatHor,0150*nFatVer ,"Ficha de emergência - apenas se aplicável",oFont10 , 2300*nFatHor, , ,)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50

		oPrint:Box( (_nLinBox1-25)*nFatHor,100*nFatVer ,(_nLinBox2)*nFatHor,0125*nFatVer )
		oPrint:Say((_nLinBox1)*nFatHor,0150*nFatVer ,"Outros (especificar):___________________________________________________________________________________________"   ,oFont10 , 2300*nFatHor, , ,)
		_nLinBox1 := _nLinBox1 + 100
		_nLinBox2 := _nLinBox2 + 100
		oPrint:Say((_nLinBox1)*nFatHor,0100*nFatVer ,"______________________________________________________________________________________________________________"   ,oFont10 ,2300*nFatHor , , ,)

		_nLinBox1 := _nLinBox1 + 100
		_nLinBox2 := _nLinBox2 + 100

		oPrint:fillRect( { 600, 050*nFatVer, 615, 2300*nFatVer}, oBrush1 )
		oPrint:Say(_nLinBox1*nFatHor  ,0100*nFatVer ,"Declaração e Assinatura",oFont10,)

		_nLinBox1 := _nLinBox1 + 100
		_nLinBox2 := _nLinBox2 + 100

		oPrint:Say((_nLinBox1)*nFatHor  ,0100*nFatVer ,"Eu, ________________________________________________________________, portador do documento ______________________,     ",oFont10,2300*nFatHor)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50
		oPrint:Say((_nLinBox1)*nFatHor  ,0100*nFatVer ,"por ser verdade, firmo que recebi e conferi os volumes/mercadorias das notas fiscais acima relacionadas, conforme carrega-  ",oFont10,2300*nFatHor)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50
		oPrint:Say((_nLinBox1)*nFatHor  ,0100*nFatVer ,"mento realizado nesta data, ficando, desde então, sob minha responsabilidade a guarda de toda carga e documentos fiscais     ",oFont10,2300*nFatHor)
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50
		oPrint:Say((_nLinBox1)*nFatHor  ,0100*nFatVer ,"até a entrega ao destino final.",oFont10)

		_nLinBox1 := _nLinBox1 + 150
		_nLinBox2 := _nLinBox2 + 150

		oPrint:Say((_nLinBox1)*nFatHor      ,0060*nFatVer ,"__________________________________",oFont10n, , , , 0)
		oPrint:Say((_nLinBox1 + 50)*nFatHor ,0350*nFatVer ,"Data",oFont10n, , , , 0)

		oPrint:Say((_nLinBox1)*nFatHor      ,850*nFatVer ,"__________________________________",oFont10n, , , , 2)
		oPrint:Say((_nLinBox1 + 50)*nFatHor ,0950*nFatVer ,"Responsavel da Transportadora"     ,oFont10n, , , , 0)

		oPrint:Say((_nLinBox1)*nFatHor      ,1650*nFatVer ,"__________________________________",oFont10n, , , , 1)
		oPrint:Say((_nLinBox1 + 50)*nFatHor ,1850*nFatVer ,"Conferente",oFont10n, , , , 0)
		//Continua impressão.
	Else
		_nLinBox1 := 1555
		_nLinBox2 := 1555
		/*oPrint:Box( _nLinBox1*nFatHor,050*nFatVer ,(_nLinBox2 + 50)*nFatHor,0275*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,0275*nFatVer,(_nLinBox2 + 50)*nFatHor,0515*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,0515*nFatVer ,(_nLinBox2 + 50)*nFatHor,0800*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,0800*nFatVer ,(_nLinBox2 + 50)*nFatHor,1050*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,1050*nFatVer ,(_nLinBox2 + 50)*nFatHor,1450*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,1450*nFatVer ,(_nLinBox2 + 50)*nFatHor,1800*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,1800*nFatVer ,(_nLinBox2 + 50)*nFatHor,2050*nFatVer )
		oPrint:Box( _nLinBox1*nFatHor,2050*nFatVer ,(_nLinBox2 + 50)*nFatHor,2300*nFatVer )*/
		_nLinBox1 := 3105 - 50
		oPrint:Say( (_nLinBox1+40)*nFatHor,070*nFatVer,"CONTINUA..."          ,oFont10n)
	EndIf

Return()