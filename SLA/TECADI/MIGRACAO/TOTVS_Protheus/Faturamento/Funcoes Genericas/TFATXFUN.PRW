#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Funcoes Genericas para os Modulos Faturamens/WMS        !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp        ! Data de Criacao ! 10/201 !
+------------------+---------------------------------------------------------+
!Observacoes       ! 1. Funcao para validar o numero do container            !
!                  ! 2. Funcao para validar/filtrar o produto de acordo com  !
!                  !    a sigla do cliente                                   !
!                  ! 3. Funcao para padronizacao a descricao de servicos na  !
!                  !    NFS-e e Pré-Nota                                     !
!                  ! 4. Funcao padrao da TOTVS para eliminacao de residuos   !
+------------------+--------------------------------------------------------*/

// #1. Funcao para validar o numero do container
User Function FtVldCnt(mvNumCont)
	Local _lRet := .f.
	// tabela MUNDIAL dos valores por letra
	Local _aTabLetra := {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
	Local _aTabValor := { 10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 34, 35, 36, 37, 38}
	Local _nVlrLetra
	Local _nPos
	Local _nPosTab
	Local _nPotenc := 0 // potencia para calculo (de 0 a 9)
	Local _cTmpChar
	Local _nTotal := 0
	Local _cDigito
	Local _cNewDigit
	Local _nMod11

	// quando nao recebe como parametro
	Default mvNumCont := &(AllTrim(ReadVar()))

	// padroniza o tamanho do do texto
	mvNumCont := PadR(mvNumCont,11)

	// extrai digito para comparar no final
	_cDigito := SubStr(mvNumCont,11,1)

	// varre ate a 10a posicao do numero
	For _nPos := 1 to 10
		// extrai o caracter da posicao
		_cTmpChar := SubStr(mvNumCont,_nPos,1)

		// calculo dos numero
		If (_cTmpChar>="0").and.(_cTmpChar<="9")
			// calcula o total
			_nTotal += (Val(_cTmpChar) * (2 ^ _nPotenc))

			// calculo da letras
		Else
			// busca o valor da letra
			_nPosTab := aScan(_aTabLetra,_cTmpChar)
			// caracter invalido
			If (_nPosTab==0)
				MsgStop("Caracter Inválido!")
				Return(_lRet)
			EndIf
			// retorna o valor
			_nVlrLetra := _aTabValor[_nPosTab]
			// calcula o total
			_nTotal += (_nVlrLetra * (2 ^ _nPotenc))
		EndIf

		// proxima potencia
		_nPotenc ++

	Next _nPos

	// calcula digito
	_nMod11 := Mod(_nTotal , 11)
	// se for maior que 10, mantem 0
	If (_nMod11>=10)
		_cNewDigit := "0"
	Else
		_cNewDigit := Str(_nMod11,1)
	EndIf

	// compara os digitos
	_lRet := (_cNewDigit==_cDigito)

	If (!_lRet)
		MsgStop("Dígito verificador incorreto!")
	EndIf

Return(_lRet)

// #2. funcao para validar/filtrar o produto de acordo com o cliente
User Function FtVldProd(mvValida)

	Local _aArea	:= GetArea()
	Local _aAreaSA1	:= SA1->(GetArea())
	Local _aAreaSB1	:= SB1->(GetArea())

	Local _lRet := .t.
	Local _cRet := ""
	Local _cSigla := ""

	// variavel
	Local _cTmpVar := &(AllTrim(ReadVar()))

	// dados do usuario logado
	local _aTmpUser := U_FtWmsFil()
	// modulo WMS
	local _lModWMS := ((_aTmpUser[1]) .and. ("P" $ _aTmpUser[2]))
	// modulo Faturamento
	local _lModFAT := ((_aTmpUser[1]) .and. ("S" $ _aTmpUser[2]))

	// só executa se for empresa 01-Armazens Gerais ou 02-Adm de Bens
	If ! (cEmpAnt $ "01/02")
		Return(If(mvValida,_lRet,_cRet))
	EndIf

	// faz o tratamento do campo, quando usado em telas diferentes (padrao ou MVC)
	If (ValType(_cTmpVar) == "U")
		_cTmpVar := AllTrim(FwFldGet(ReadVar()))
	EndIf

	// posiciona no cadastro do produto
	dbSelectArea("SB1")
	SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
	SB1->(dbSeek( xFilial("SB1")+_cTmpVar ))

	// pedido de venda
	If (AllTrim(FunName())=="MATA410")

		// verifica o tipo do pedido no modulo WMS
		If (M->C5_TIPO $ "N") .and. (M->C5_TIPOOPE $ "P") .and. (_lModWMS)
			// pesquisa o cliente
			dbSelectArea("SA1")
			SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
			SA1->(dbSeek( xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI ))
			// pega a sigla do cliente
			_cSigla := SA1->A1_SIGLA

			// se for validacao
			If (mvValida)
				// verifica se a sigla do cliente é o mesmo grupo do produto
				_lRet := ((_cSigla == SB1->B1_GRUPO).and.(SB1->B1_ZTIPPRO=="A"))
				// filtro da consulta padrao
			Else
				_cRet := "@(B1_GRUPO = '"+_cSigla+"') AND (B1_ZTIPPRO = 'A')"
			EndIf

			// verifica o tipo do pedido no modulo WMS
		ElseIf (M->C5_TIPO $ "N") .and. (M->C5_TIPOOPE $ "T") .and. (_lModWMS)

			// se for validacao
			If (mvValida)
				// verifica se a sigla do cliente é o mesmo grupo do produto
				_lRet := (SB1->B1_ZTIPPRO=="A")
				// filtro da consulta padrao
			Else
				_cRet := "@(B1_ZTIPPRO = 'A')"
			EndIf

			// verifica o tipo do pedido no modulo FATURAMENTO
		ElseIf (M->C5_TIPO $ "N") .and. (M->C5_TIPOOPE $ "S") .and. (_lModFAT)

			// se for validacao
			If (mvValida)
				// verifica se o grupo é 9000-Servicos
				_lRet := ((SB1->B1_GRUPO=="9000").and.(SB1->B1_ZTIPPRO=="S"))
				// filtro da consulta padrao
			Else
				_cRet := "@(B1_GRUPO = '9000') AND (B1_ZTIPPRO = 'S')"
			EndIf

			// outros tipos de pedidos
		ElseIf (M->C5_TIPO $ "N/D") .and. (M->C5_TIPOOPE $ "C") .and. (_lModWMS)
			// se for validacao
			If (mvValida)
				// verifica somente produtos do tipo CONSUMO/COMPRAS
				_lRet := (SB1->B1_ZTIPPRO=="C")
				// filtro da consulta padrao
			Else
				_cRet := "@(B1_ZTIPPRO = 'C') "
			EndIf
		EndIf

		// documento de entrada / pre-nota
	ElseIf (AllTrim(FunName())$"MATA103/MATA140")

		// notas fiscais de cliente para armazenagem
		If (cTipo == "B")
			// pesquisa o cliente
			dbSelectArea("SA1")
			SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
			SA1->(dbSeek( xFilial("SA1")+cA100For+cLoja ))
			// pega a sigla do cliente
			_cSigla := SA1->A1_SIGLA

			// se for validacao
			If (mvValida)
				// verifica se a sigla do cliente é o mesmo grupo do produto
				_lRet := ((_cSigla == SB1->B1_GRUPO).and.(SB1->B1_ZTIPPRO=="A"))
				// filtro da consulta padrao
			Else
				_cRet := "@(B1_GRUPO = '"+_cSigla+"') AND (B1_ZTIPPRO = 'A')"
			EndIf

			// notas fiscais de fornecedores
		ElseIf (cTipo == "N")

			// se for validacao
			If (mvValida)
				// verifica somente produtos do tipo CONSUMO/COMPRAS
				_lRet := (SB1->B1_ZTIPPRO == "C")
				// filtro da consulta padrao
			Else
				_cRet := "@(B1_ZTIPPRO = 'C')"
			EndIf

		EndIf

		// documento de saida manual
	ElseIf (AllTrim(FunName())=="MATA920")
		// verifica o tipo do pedido
		If (cTipo $ "N")
			// pesquisa o cliente
			dbSelectArea("SA1")
			SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
			SA1->(dbSeek( xFilial("SA1")+c920Client+c920Loja ))
			// pega a sigla do cliente
			_cSigla := SA1->A1_SIGLA

			// se for validacao
			If (mvValida)
				// verifica se a sigla do cliente é o mesmo grupo do produto
				_lRet := (Left(_cTmpVar,1)=="9") .OR. (_cSigla == SB1->B1_GRUPO)
				// filtro da consulta padrao
			Else
				_cRet := "@(B1_GRUPO = '"+_cSigla+"') OR (LEFT(B1_GRUPO,1) = '9') "
			EndIf

			// outros tipos de pedidos
		Else
			// se for validacao
			If (mvValida)
				// verifica somente produtos do tipo CONSUMO/COMPRAS
				_lRet := (SB1->B1_ZTIPPRO == "C")
				// filtro da consulta padrao
			Else
				_cRet := "@(B1_ZTIPPRO = 'C')"
			EndIf
		EndIf
		// Devolução de Mercadoria Sem Documento Fiscal
	ElseIf (AllTrim(FunName())=="MATA145")
		// notas fiscais de cliente para armazenagem
		If (M->DB1_TIPONF == "B")
			// pesquisa o cliente
			dbSelectArea("SA1")
			SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
			SA1->(dbSeek( xFilial("SA1") + M->DB1_CLIFOR + M->DB1_LOJA ))
			// pega a sigla do cliente
			_cSigla := SA1->A1_SIGLA

			// se for validacao
			If (mvValida)
				// verifica se a sigla do cliente é o mesmo grupo do produto
				_lRet := ((_cSigla == SB1->B1_GRUPO).and.(SB1->B1_ZTIPPRO=="A"))
				// filtro da consulta padrao
			Else
				_cRet := "@(B1_GRUPO = '"+_cSigla+"') AND (B1_ZTIPPRO = 'A')"
			EndIf
		EndIf
		// pedidos de compras
	ElseIf (AllTrim(FunName())=="MATA121")
		// se for validacao
		If (mvValida)
			// verifica somente produtos do tipo CONSUMO/COMPRAS
			_lRet := (SB1->B1_ZTIPPRO == "C")
			// filtro da consulta padrao
		Else
			_cRet := "@(B1_ZTIPPRO = 'C')"
		EndIf
	EndIf

	// restaura area inicial
	RestArea(_aAreaSB1)
	RestArea(_aAreaSA1)
	RestArea(_aArea)

Return(If(mvValida,_lRet,_cRet))

// #3. funcao para padronizacao a descricao de servicos na NFS-e e Pré-Nota
User Function FtDscNfs(mvTpRet, mvDscSrv, mvCodServ, mvQuant, mvDescri, mvPrcUnit, mvVlrTotal)

	// ex: estrutura mvDscSrv
	// 1-Cod.Produto
	// 2-Dsc.Produto
	// 3-Quantidade
	// 4-Vlr.Unitario
	// 5-Vlr.Total

	// controles
	local _lSomaQuant  := .f.
	local _lSomaPrUni  := .f.
	local _nTmpQuant   := 0

	// posicao do servico no vetor
	local _nPosServico := 0

	// variavel de retorno

	// tipo do retorno: 1-Agrupa Vetor
	If (mvTpRet == "1")

		// armazena a quantidade
		If (AllTrim(mvCodServ)=="9000005")
			_nTmpQuant  := 1
			_lSomaQuant := .f.
			_lSomaPrUni := .t.
		Else
			_nTmpQuant  := mvQuant
			_lSomaQuant := (_nTmpQuant > 1)
			_lSomaPrUni := .t.
		EndIf

		// para pacotes logisticos, separa cobranca por preco unitario
		If (AllTrim(mvCodServ) $ "9000006/9000010/9000011")
			_nPosServico := aScan(mvDscSrv,{|x| (x[1] == mvCodServ).and.(x[2] == mvDescri).and.(x[4] == mvPrcUnit) })
			_lSomaQuant  := .t.
			_lSomaPrUni  := .f.
		Else
			_nPosServico := aScan(mvDscSrv,{|x| (x[1] == mvCodServ).and.(x[2] == mvDescri) })
		EndIf

		// inclui novo servico
		If (_nPosServico == 0)

			// atualiza os dados
			aAdd(mvDscSrv,{ mvCodServ ,;
			mvDescri                  ,;
			_nTmpQuant                ,;
			mvPrcUnit                 ,;
			mvVlrTotal                })

			// atualiza dados do servico
		ElseIf (_nPosServico > 0)

			// quantidade (só incrementa quanto a quantidade for maior que 1)
			mvDscSrv[_nPosServico][3] += IIf(_lSomaQuant, _nTmpQuant, 0)
			// valor unitario
			mvDscSrv[_nPosServico][4] += IIf(_lSomaPrUni, mvPrcUnit , 0)
			// valor total
			mvDscSrv[_nPosServico][5] += mvVlrTotal

		EndIf

		// tipo do retorno: 2-Prepara Descricao
	ElseIf (mvTpRet == "2")

		For _nPosServico := 1 to Len(mvDscSrv)

			// busco a descricao do servico do pedido de vendas
			// caso ja tenha alguma informacao, inclui quebra de linha
			If ( ! Empty(mvDescri) )
				mvDescri += CRLF
			EndIf

			// atualiza campo temporario de quantidade
			_nTmpQuant := mvDscSrv[_nPosServico][3]

			// inclui os detalhes do item
			mvDescri += AllTrim(mvDscSrv[_nPosServico][2])
			// abre o parenteses principal
			mvDescri += " ("
			// quantidade
			If (_nTmpQuant > 1)
				mvDescri += "Quantidade "+Alltrim(Str(_nTmpQuant))
				// valor unitário
				mvDescri += " Valor Unitario R$ "+AllTrim(Transf(mvDscSrv[_nPosServico][4],PesqPict("SD2","D2_TOTAL")))+" "
			EndIf
			// valor total
			mvDescri += "Valor Total R$ "+AllTrim(Transf(mvDscSrv[_nPosServico][5],PesqPict("SD2","D2_TOTAL")))+")"

		Next _nPosServico

	EndIf

Return

// #4. funcao padrao da TOTVS para eliminacao de residuos
User Function FtFatRes(mvItemBloq)

	// armazena area inicial
	Local _aAreaAtu := GetArea()
	Local _aAreaSC6 := SC6->(GetArea())
	Local _aAreaSC5 := SC5->(GetArea())
	Local _aAreaSB2 := SB2->(GetArea())
	Local _aAreaSA1 := SA1->(GetArea())

	// variavel de retorno
	Local _lResidOk := .F.

	// quantidade liberada
	Local _nQtdLibSC9 := 0

	// query
	Local _cQuery := ""

	// variaveis temporarias
	local _aRecnoSC9 := {}
	local _nRecnoSC9

	// valores padroes
	Default mvItemBloq := .t.

	// posiciona na TES
	dbSelectArea("SF4")
	SF4->(dbSetOrder(1)) // 1-F4_FILIAL, F4_CODIGO
	MsSeek(xFilial("SF4") + SC6->C6_TES)

	// posiciona no cabecalho do pedido de venda
	dbSelectArea("SC5")
	SC5->(dbSetOrder(1)) // 1-C5_FILIAL, C5_NUM
	MsSeek(xFilial("SC5") + SC6->C6_NUM)

	// testa condicao para estornar a liberacao atual
	If ( Empty(SC6->C6_RESERVA) .And. ( ! SC6->C6_BLQ $ "R #S ") .And. ( SC6->C6_QTDEMP==0 .Or. mvItemBloq ) )

		// monta query que soma o total liberado no pedido
		_cQuery := " SELECT SUM(SC9.C9_QTDLIB) C9_QTDLIB  "
		_cQuery += " FROM " + RetSqlTab("SC9")
		_cQuery += " WHERE " + RetSqlCond("SC9")
		_cQuery += " AND SC9.C9_PEDIDO = '" + SC6->C6_NUM + "' "
		_cQuery += " AND SC9.C9_ITEM = '" + SC6->C6_ITEM + "' "
		_cQuery += " AND SC9.C9_PRODUTO = '" + SC6->C6_PRODUTO + "' "
		_cQuery += " AND SC9.C9_BLCRED != '10' "                      //já faturado
		_cQuery += " AND SC9.C9_BLEST != '10' "                       //já faturado
		// se deve remover itens ja liberados
		If ( mvItemBloq )
			_cQuery += " AND (SC9.C9_BLEST = '' OR SC9.C9_BLCRED = '') "    //itens liberados tem os campos em branco
		EndIF

		// atualiza total liberado
		_nQtdLibSC9 := U_FtQuery(_cQuery)

		// valida as quantidades, para estornar a liberacao
		If ( (_nQtdLibSC9 == SC6->C6_QTDEMP) .or. (_nQtdLibSC9 == SC6->C6_QTDLIB) )

			_cQuery := " SELECT SC9.R_E_C_N_O_ RECNOSC9 "
			_cQuery += " FROM " + RetSqlTab("SC9")
			_cQuery += " WHERE " + RetSqlCond("SC9")
			_cQuery += " AND SC9.C9_PEDIDO = '" + SC6->C6_NUM + "' "
			_cQuery += " AND SC9.C9_ITEM = '" + SC6->C6_ITEM + "' "
			_cQuery += " AND SC9.C9_PRODUTO = '" + SC6->C6_PRODUTO + "' "
			_cQuery += " AND SC9.C9_BLCRED != '10' "                      //já faturado
			_cQuery += " AND SC9.C9_BLEST != '10' "                       //já faturado
			// se deve remover itens ja liberados
			If ( mvItemBloq )
				_cQuery += " AND (SC9.C9_BLEST = '' OR SC9.C9_BLCRED = '') "   //itens liberados tem os campos em branco
			EndIF

			// atualiza variavel de recno
			_aRecnoSC9 := U_SqlToVet(_cQuery)

			// varre todos os recno
			For _nRecnoSC9 := 1 to Len(_aRecnoSC9)

				// posiciona no registro
				dbSelectArea("SC9")
				SC9->(MsGoTo( _aRecnoSC9[_nRecnoSC9] ))

				// chama funcao padrao de estorno
				SC9->(A460Estorna())

			Next _nRecnoSC9

		EndIf

		// atualiza status do item
		If ( SC6->C6_QTDEMP == 0 )

			// se atualiza estoque, reduz o empenho do saldo por armazem
			If ( SF4->F4_ESTOQUE == "S" )

				// saldo do produto por armazem
				dbSelectArea("SB2")
				SB2->(dbSetOrder(1)) // 1-B2_FILIAL, B2_COD, B2_LOCAL, R_E_C_N_O_, D_E_L_E_T_
				MsSeek(xFilial("SB2")+SC6->C6_PRODUTO+SC6->C6_LOCAL)
				RecLock("SB2")
				SB2->B2_QPEDVEN -= Max(SC6->C6_QTDVEN-SC6->C6_QTDEMP-SC6->C6_QTDENT, 0)
				SB2->B2_QPEDVE2 -= ConvUM(SB2->B2_COD, Max(SC6->C6_QTDVEN-SC6->C6_QTDEMP-SC6->C6_QTDENT,0), 0, 2)
				MsUnLock()
			EndIf

			// atualiza o status de controle de residuo do item
			RecLock("SC6")
			SC6->C6_BLQ     := "R"
			SC6->C6_IDENTB6 := ""            //contorno para fonte padrao da Totvs que não preve eliminação de residuo no faturamento
			MsUnLock()

			// variavel de retorno
			_lResidOk := .T.

		EndIf
	EndIf

	// restaura area inicial
	RestArea(_aAreaSC6)
	RestArea(_aAreaSC5)
	RestArea(_aAreaSB2)
	RestArea(_aAreaSA1)
	RestArea(_aAreaAtu)

Return(_lResidOk)

// ** funcao para verificacao de itens do pedido de venda aptos a faturar - somente pedidos completos
User Function FtFatVld(mvMostraMsg, mvTipoOpe, mvPedDe, mvPedAte, mvCliDe, mvCliAte, mvLojDe, mvLojAte, mvEmisDe, mvEmisAte, mvCargaDe, mvCargaAte, mvOndaDe, mvOndaAte)

	// variavel de retorno
	local _lRetOk := .T.

	// query
	local _cQuery := ""

	// variaveis temporarias
	local _aTmpPedidos := {}
	local _cTmpPedidos := ""

	// mascara de quantidade
	local _cMskQtdPed := PesqPict("SC6", "C6_QTDVEN")

	// valores padroes dos parametros
	Default mvMostraMsg := .T.
	Default mvTipoOpe   := ""
	Default mvPedDe     := "  "
	Default mvPedAte    := "ZZ"
	Default mvCliDe     := "  "
	Default mvCliAte    := "ZZ"
	Default mvLojDe     := "  "
	Default mvLojAte    := "ZZ"
	Default mvEmisDe    := CtoD("01/01/2010")
	Default mvEmisAte   := CtoD("31/12/2049")
	Default mvCargaDe   := "   "
	Default mvCargaAte  := "ZZZ"
	Default mvOndaDe    := "   "
	Default mvOndaAte   := "ZZZ"

	// prepara query de valida de dados dos pedidos
	_cQuery += " SELECT * "
	_cQuery += " FROM   (SELECT C5_NUM, "
	_cQuery += "                C6_ITEM, "
	_cQuery += "                C6_PRODUTO, "
	_cQuery += "                Sum(C6_QTDVEN)                PED_QTDVEN, "
	_cQuery += "                (SELECT Isnull(Sum(C9_QTDLIB), 0) "
	_cQuery += "                 FROM   " + RetSqlTab("SC9")
	_cQuery += "                 WHERE  " + RetSqlCond("SC9")
	_cQuery += "                        AND C9_PEDIDO = C5_NUM "
	_cQuery += "                        AND C9_ITEM = C6_ITEM "
	_cQuery += "                        AND C9_NFISCAL = ' ' "
	_cQuery += "                        AND C9_BLCRED = ' ' "
	_cQuery += "                        AND C9_BLEST = ' ' "
	_cQuery += "                        AND C9_BLCRED != '10' "
	_cQuery += "                        AND C9_BLEST != '10') LIB_QTDLIB "
	_cQuery += "         FROM   " + RetSqlTab("SC5")
	_cQuery += "                INNER JOIN " + RetSqlTab("SC6")
	_cQuery += "                        ON " + RetSqlCond("SC6")
	_cQuery += "                           AND C6_NUM = C5_NUM "
	_cQuery += "         WHERE  " + RetSqlCond("SC5")
	_cQuery += "                AND C5_NUM >= '" + mvPedDe + "' AND C5_NUM <= '" + mvPedAte +"' "
	_cQuery += "                AND C5_TIPOOPE = '" + mvTipoOpe + "' "
	_cQuery += "                AND C5_CLIENTE >= '" + mvCliDe + "' AND C5_CLIENTE <= '" + mvCliAte +"' "
	_cQuery += "                AND C5_LOJACLI >= '" + mvLojDe + "' AND C5_LOJACLI <= '" + mvLojAte + "'"
	_cQuery += "                AND C5_EMISSAO >= '" + DtoS(mvEmisDe) + "' AND C5_EMISSAO <= '" + DtoS(mvEmisAte) + "' "
	_cQuery += "                AND C5_NOTA = ' ' "
	_cQuery += "         GROUP  BY C5_NUM, "
	_cQuery += "                   C6_ITEM, "
	_cQuery += "                   C6_PRODUTO) AS PEDIDOS_OK "
	_cQuery += " WHERE  ROUND(PED_QTDVEN,2) != ROUND(LIB_QTDLIB,2) "
	_cQuery += " ORDER  BY 1 "

	// gera query
	MemoWrit("c:\query\tfatxfun_FtFatVld.txt", _cQuery)

	// atualiza variavel
	_aTmpPedidos := U_SqlToVet(_cQuery)

	// atualiza variavel de retorno
	_lRetOk := (Len(_aTmpPedidos) == 0)

	// verifica se ha pedidos com algum bloqueio
	If ( ! _lRetOk ) .And. (mvMostraMsg)

		// atualiza todos os pedidos na mensagem
		aEval(_aTmpPedidos,{|_aTmpPedidos| _cTmpPedidos += "Pedido: " + _aTmpPedidos[1] + " Qtd Pedido: " + AllTrim(Transf(_aTmpPedidos[4], _cMskQtdPed)) + " -> Qtd Liberada: " + AllTrim(Transf(_aTmpPedidos[5], _cMskQtdPed)) + " / " })

		// mensagem
		Help( ,, 'VALIDAÇÃO: Liberação de Pedido Inconsistente',, "Emissão de Nota Fiscal de Saída não permitida, pois os pedidos abaixo não estão aptos para faturamento. " + _cTmpPedidos  , 1, 0 )

	EndIf

Return( _lRetOk )

// #5. funcao para estorno de liberacao de pedidos de venda
User Function FtEstLib(mvNumPed, mvMsgConf)

	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaSC5 := SC5->(GetArea())
	local _aAreaSC6 := SC6->(GetArea())
	local _aAreaSC9 := SC9->(GetArea())

	// query dos itens do pedido
	local _cQrySC6
	local _aRecnoLib := {}
	local _nRecnoLib := 0

	// pedidos liberados
	local _aPedLiber := {}

	// validação do WMS ativo
	local _lWmsAtivo := .F.

	// valores padroes para parametros
	Default mvNumPed  := CriaVar("C5_NUM", .F.)
	Default mvMsgConf := .F.

	// posiciona no cabecalho do pedido
	dbSelectArea("SC5")
	SC5->(dbSetOrder( 1 )) // 1-C5_FILIAL, C5_NUM
	If ( ! SC5->(dbSeek( xFilial("SC5") + mvNumPed )) )
		// avisa usuario
		Help( ,, 'FTESTLIB.F01.001',, "Pedido de Venda " + mvNumPed + " não localizado.", 1, 0 )
		// retorno
		Return( .F. )
	EndIf

	// quando for saída de produtos
	If ( SC5->C5_TIPO == "N" ) .And. ( SC5->C5_TIPOOPE == "P" )

		// verifica se o WMS esta ativo
		_lWmsAtivo := U_FtWmsParam("WMS_ATIVO_POR_CLIENTE", "L", .F., .F., Nil, SC5->C5_CLIENTE, SC5->C5_LOJACLI, Nil, Nil)

		// se o WMS está ativo, vai validar se possui mapa
		If ( _lWmsAtivo )
			// valido se possui MAPA
			If ( U_FtMapExp(SC5->C5_NUM) )
				// avisa usuario
				Help( ,, 'FTESTLIB.F01.002',, "Não é permitido ESTORNO da liberação do Pedido de Venda " + mvNumPed + " pois há Mapa de Apanhe / Onda Separação gerado.", 1, 0 )
				// retorno
				Return( .F. )
			EndIf
		EndIf
	EndIf

	// solicita confirmacao
	If (mvMsgConf) .And. ( ! MsgYesNo("Confirma ESTORNO da liberação do Pedido de Venda " + mvNumPed + " ?", "TFATXFUN x FtEstLib") )
		// retorno
		Return( .F. )
	EndIf

	// monta a query para buscar os itens dos pedidos de venda da carga
	_cQrySC6 := " SELECT SC6.R_E_C_N_O_ SC6RECNO, SC9.R_E_C_N_O_ SC9RECNO "
	// itens liberados
	_cQrySC6 += " FROM " + RetSqlTab("SC9")
	// itens liberados
	_cQrySC6 += " INNER JOIN " + RetSqlTab("SC6") + " ON " + RetSqlCond("SC6") + " AND C6_NUM = C9_PEDIDO AND C6_ITEM = C9_ITEM AND C6_PRODUTO = C9_PRODUTO "
	// filtro padrao
	_cQrySC6 += " WHERE " + RetSqlCond("SC9")
	// nr do pedido
	_cQrySC6 += " AND C9_PEDIDO = '" + mvNumPed + "' "
	// sem nota fiscal emitida E sem bloqueio de WMS
	_cQrySC6 += " AND C9_NFISCAL = ' ' AND C9_BLEST IN ('  ','02') AND C9_BLWMS = ' ' "
	// ordem dos dados
	_cQrySC6 += " ORDER BY C6_NUM, C6_ITEM "

	memowrit("c:\query\tfatxfun_FtEstLib.txt", _cQrySC6)

	// alimenta o vetor com os RECNOs dos itens do pedido
	_aRecnoLib := U_SqlToVet(_cQrySC6)

	// se nao ha itens para liberacao
	If (Len(_aRecnoLib) == 0)
		// avisa usuario
		Help( ,, 'FTESTLIB.F01.003',, "Não há iten(s) liberado(s) do pedido de venda " + mvNumPed, 1, 0 )
		// retorno
		Return( .F. )
	EndIf

	// varre todo os itens dos pedidos de venda
	For _nRecnoLib := 1 to len(_aRecnoLib)

		// posiciona no registro do item liberado
		dbSelectArea("SC9")
		SC9->(dbGoTo( _aRecnoLib[_nRecnoLib][2] ))

		// posiciona no registro do item
		dbSelectArea("SC6")
		SC6->(dbGoTo( _aRecnoLib[_nRecnoLib][1] ))

		// posiciona no cabecalho do pedido
		dbSelectArea("SC5")
		SC5->(dbSetOrder( 1 )) // 1-C5_FILIAL, C5_NUM
		SC5->(dbSeek( xFilial("SC5") + SC6->C6_NUM ))

		// pedidos liberados
		If ( aScan(_aPedLiber,{|x| x == SC5->C5_NUM }) == 0 )
			aAdd(_aPedLiber, SC5->C5_NUM)
		EndIf

		// realiza o estorno da mercadoria empenhada no pedido de venda / necessario para realizar nova liberacao
		a460estorna()

	Next _nRecnoLib

	// atualiza o status do pedido de venda
	SC6->(MaLiberOk(_aPedLiber))

	// restaura area atual
	RestArea(_aAreaSC9)
	RestArea(_aAreaSC6)
	RestArea(_aAreaSC5)
	RestArea(_aAreaAtu)

Return( .T. )