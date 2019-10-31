#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado no botao Confirmar da Nota  !
!                  ! Fiscal de Entrada                                       !
!                  ! 1. Relacionar a programacao de recebimentos             !
!                  ! 2. Ratear o peso bruto/liquido entre os itens da nota   !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 09/2010 !
+------------------+--------------------------------------------------------*/

User Function MT100TOK()
	// area atual
	Local _aAreaAtu	:= GetArea()
	// variavel de retorno
	Local _lRet := .t.
	// controle Tela de programação
	Local _lInfProg := .f.
	// variavel temporaria
	local _nX := 0

	// verifica se o WMS esta ativo
	local _lWmsAtivo := .f.

	// verifica se o controle de lote esta
	local _lLotAtivo := .f.

	// verifica se o lote eh obrigatorio na entrada da nota
	local _lLotObrEnt := .f.

	// indica se o cliente utiliza etiqueta própria para o WMS
	local _lEtqProp := .F.

	// verifica se eh nota de armazenagem/poder de terceiros
	local _lPoder3 := .f.

	// conteudo do campo para logistica reversa
	local _cLogReversa := "N"

	// query SQL
	local _cQuery := ""
	
	// validação do valor total do item com o calulado (quant * vlr unit)
	local _nTotDigi := 0
	local _nTotCalc := 0

	// codigo e item da Programacao
	Private _cCodProg := CriaVar("D1_PROGRAM",.f.)
	Private _cIteProg := CriaVar("D1_ITEPROG",.f.)
	// cubagem total
	private _nCubagem := 0
	// posicao dos campos no header
	private _nP_Item    := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_ITEM"})    // campo ITEM
	private _nP_CodProd := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_COD"})     // codigo do produto
	private _nP_CodRec  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_PROGRAM"}) // codigo da prog de recebimentos
	private _nP_IteRec  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_ITEPROG"}) // item da prog de recebimentos
	private _nP_LotCtl  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_LOTECTL"}) // lote do produto
	private _nP_TES     := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_TES"})     // TES
	private _nP_UnidMed := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_UM"})      // uniadde de medida
	private _nP_SegUm   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_SEGUM"})   // segunda unidade de medida
	private _nP_QtSegUm := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_QTSEGUM"}) // quantidade segunda unidade de medida
	private _nP_LogRev  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_ZLOGREV"}) // controle se eh nota de logistica reversa
	private _nP_Quant   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_QUANT"})   // quantidade
	private _nP_Total   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_TOTAL"})   // preco total
	private _nP_VlrUn   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_VUNIT"})   // valor unitário

	// valida o controle de uso de segunda unidade de medida
	private _lUsoSegUM := .f.

	// valida uso de logistica reversa
	private _lUsoLogRev := .f.

	// valida o controle de uso de segunda unidade de medida, se podera ser fracionada
	private _lSegUMFrac := .f.

	// Se está inutilizando uma NFE, desconsidera o ponto de entrada
	If (IsInCallStack('SPEDNFEINUT'))
		Return(_lRet)
	EndIf

	// Na Transportadora, quando for lançamento de nota fiscal de saída
	If (AllTrim(FunName()) $ "TTMSXSGT/TTMSXDAT/TMSXDATW/RPC/MATA920")
		Return(_lRet)
	EndIf

	// valida a chave da nf-e para documentos SPED
	If (_lRet).and.(AllTrim(cEspecie)=="SPED").and.(cFormul=="N")
		// valida o conteudo
		If (Empty(aNFEDanfe[13])).or.(Len(AllTrim(aNFEDanfe[13])) < TamSx3("F1_CHVNFE")[1] )
			Aviso("Tecadi: MT100TOK","É obrigatório informar uma Chave válida da NFE na Aba: Informações DANFE.",{"OK"})
			_lRet := .f.
		EndIf
	EndIf

	// verifica se a nota fiscal movimenta estoque, e controla poder de terceiros
	If (_lRet).and.(cEmpAnt=="01").and.(cTipo $ "B/D").and.(cFormul=="N")
		// varre todos os itens da nota fiscal
		For _nX := 1 to Len(aCols)
			// se a linha nao estiver deletada
			If ( ! aCols[_nX][Len(aHeader)+1] )
				// posiciona no cadastro da TES
				dbSelectArea("SF4")
				SF4->(dbSetOrder(1)) // 1-F4_FILIAL, F4_CODIGO
				SF4->(dbSeek( xFilial("SF4")+aCols[_nX,_nP_TES] ))

				// controle de estoque, e poder de terceiros
				_lPoder3 := ((SF4->F4_TIPO == "E").and.(SF4->F4_ESTOQUE == "S").and.(SF4->F4_PODER3 == "R"))

				// se tem controle, sai do loop
				If (_lPoder3)
					Exit
				EndIf

			EndIf
		Next _nX
	EndIf

	// verifica se a NF é de cliente (tipo B - Beneficiamento / D - Devolução) 
	If (_lRet).and.(cTipo $ "B/D").and.(cFormul=="N").and.(_lPoder3)

		// estrutura do vetor aNFEDanfe
		// 1-F1_TRANSP
		// 2-F1_PLIQUI
		// 3-F1_PBRUTO
		// valida se o peso bruto e liquido foram informados
		If ((aNFEDanfe[2]==0).or.(aNFEDanfe[3]==0))
			Aviso("Tecadi: MT100TOK","É obrigatório informar o peso bruto e peso líquido na Aba: Informações DANFE.",{"OK"})
			_lRet := .f.
		EndIf

		// valida se o peso bruto eh maior que o peso liquido
		If (aNFEDanfe[3] < aNFEDanfe[2])
			Aviso("Tecadi: MT100TOK","O peso bruto não pode ser inferior ao peso liquido.",{"OK"})
			_lRet := .f.
		EndIf

		// se o peso bruto e peso liquido foram informados, rateia o peso entre os itens
		If (_lRet)
			// solicita a cubagem
			sfCubagem()
			// funcao de rateio do peso bruto e liquido
			_lRet := sfRatPeso()
		EndIf

		// varre todos os itens da nota fiscal
		For _nX := 1 to Len(aCols)
			// se a linha nao estiver deletada
			If ( ! aCols[_nX][Len(aHeader)+1] )

				// Verifica Se o codigo e item da Programacao estão preenchidos.
				If (Empty(aCols[_nX,_nP_CodRec])) .Or. (Empty(aCols[_nX,_nP_IteRec]))
					_lInfProg := .t.
				Else
					_cCodProg := aCols[_nX,_nP_CodRec]
					_cIteProg := aCols[_nX,_nP_IteRec]
				EndIf

				// verifica se a TES esta de acordo com a Operacao
				If ((aCols[_nX,_nP_TES] == "49A").and.(AllTrim(cSerie) != "DI")).or.((aCols[_nX,_nP_TES] != "49A").and.(AllTrim(cSerie) == "DI"))
					Aviso("Tecadi: MT100TOK","Favor verificar a TES utilizada para documentos do tipo DI.",{"OK"})
					_lRet := .f.
				EndIf

			EndIf
		Next _nX

		// clientes com nota fiscal série DI, previne digitação com valor total diferente do unitário X quantidade
		// devido a arredondamento/truncamento das casas decimais no sistema do cliente
		// previne erro padrão A410TOTAL quando ocorre TFAA / devolução da nota fiscal
		If ( AllTrim(cSerie) == "DI" ) .AND. (cEmpAnt == "01")
			// varre todos os itens da nota fiscal
			For _nX := 1 to Len(aCols)
				// se a linha nao estiver deletada
				If ( ! aCols[_nX][Len(aHeader)+1] )
				
					// atribui valores às vairáveis
					_nTotDigi := Round( aCols[_nX,_nP_Total] , 2) // total do item digitado/importado da NF do cliente
					_nTotCalc := Round( aCols[_nX,_nP_Quant] * aCols[_nX,_nP_VlrUn] ,2) // calculo do sistema (quantidade * preço unitario)

					// verifica se o valor total digitado é igual ao calculado (considera 1 centavo pra mais ou para menos)
					If ( ( (_nTotCalc - _nTotDigi) > 0.01)	.OR. ( ( _nTotDigi - _nTotCalc) > 0.01) )
						Aviso("Tecadi: MT100TOK","A quantidade do item "+AllTrim(aCols[_nX,_nP_Item])+" multiplicado pelo seu preço unitário é diferente do valor total digitado. Verifique e digite de acordo.",{"OK"})
						_lRet := .f.
					EndIf
				EndIf
			Next _nX

		EndIf

		// tela para selecionar a Prog de Recebimentos
		If (_lRet) .And. (_lInfProg)
			_lRet := sfProgReceb()
		EndIf

		// posiciona na programacao
		dbSelectArea("SZ1")
		SZ1->( dbSetOrder(1) ) //1-Z1_FILIAL, Z1_CODIGO
		SZ1->( dbSeek( xFilial("SZ1")+_cCodProg ) )

		// verifica se o WMS esta ativo
		_lWmsAtivo := U_FtWmsParam("WMS_ATIVO_POR_CLIENTE","L",.f.,.f.,Nil, cA100For, cLoja, SZ1->Z1_CONTRT, Nil)

		// verifica se o controle de lote esta
		_lLotAtivo := U_FtWmsParam("WMS_CONTROLE_POR_LOTE","L",.F.,.F.,Nil, cA100For, cLoja, SZ1->Z1_CONTRT, Nil)

		// verifica se o lote eh obrigatorio na entrada da nota
		_lLotObrEnt := U_FtWmsParam("WMS_LOTE_OBRIGATORIO_ENTRADA","L",.F.,.F.,Nil, cA100For, cLoja, SZ1->Z1_CONTRT, Nil)

		// valida o controle de uso de segunda unidade de medida
		_lUsoSegUM  := U_FtWmsParam("WMS_PRODUTO_USA_SEGUNDA_UNIDADE_MEDIDA", "L", .F. , .F., Nil, cA100For, cLoja, SZ1->Z1_CONTRT, Nil)

		// valida uso de logistica reversa
		_lUsoLogRev := U_FtWmsParam("WMS_LOGISTICA_REVERSA", "L", .F. , .F., Nil, cA100For, cLoja, SZ1->Z1_CONTRT, Nil)

		// valida o controle de uso de segunda unidade de medida, se podera ser fracionada
		_lSegUMFrac := U_FtWmsParam("WMS_PRODUTO_FRACIONA_SEGUNDA_UNIDADE_MEDIDA", "L", .F. , .F., Nil, cA100For, cLoja, SZ1->Z1_CONTRT, Nil)

		// verifica se o cliente utiliza etiqueta própria para WMS
		_lEtqProp   := ( U_FtWmsParam("WMS_PRODUTO_ETIQ_IDENT","C","INTERNA",.F., Nil, cA100For, cLoja, SZ1->Z1_CONTRT, Nil) == "CLIENTE" )

	EndIf

	//se o cliente utiliza etiqueta própria, é exigido que os dados da etiqueta já estejam devidamente importados (redmine #164 19/04/18)
	If (_lRet) .AND. (_lWmsAtivo) .AND. (_lEtqProp)
		//verifica para cada linha da nota fiscal se já foram importadas etiquetas
		For _nX := 1 to Len(aCols)
			// se a linha nao estiver deletada
			If ( ! aCols[_nX][Len(aHeader)+1] )

				//consulta se existe etiqueta e quantidade é correta
				_cQuery := " SELECT ISNULL(SUM(Z56_QUANT),0) QTD FROM " + RetSqlTab("Z56") + " WHERE " + RetSqlCond("Z56") 
				//cliente e loja
				_cQuery += " AND Z56_CODCLI = '" + cA100For + "' AND Z56_LOJCLI = '" + CLOJA + "'"
				//nota fiscal e serie
				_cQuery += " AND Z56_NOTA = '" + CNFISCAL + "' AND Z56_SERIE = '" + CSERIE + "'" 
				//produto
				_cQuery += " AND Z56_CODPRO = '" + aCols[_nX,_nP_CodProd] + "'"
				//lote
				_cQuery += " AND Z56_LOTCTL = '" + aCols[_nX,_nP_LotCtl] + "'"

				memowrit("c:\query\MT100TOK_valida_etq_propria.txt", _cQuery)  

				_nQtdEtq := U_FtQuery(_cQuery)

				// se falhou em alguma, já sai do loop. Tem que bater quantidade EXATA
				If ( _nQtdEtq != aCols[_nX,_nP_Quant] )
					MsgStop("Não é possível classificar a nota fiscal pois o produto " + CRLF ;
					+ AllTrim(aCols[_nX, _nP_Item]) + " - " + AllTrim(aCols[_nX,_nP_CodProd]) + CRLF ;
					+ " não possui etiquetas do cliente importadas ou a quantidade delas é diferente da nota fiscal";
					+ CRLF;
					+ "Quant. necessária = " + AllTrim(Str(aCols[_nX,_nP_Quant])) + CRLF ;
					+ "Quant. existente = " + AllTrim(Str(_nQtdEtq)) )

					//cancela classificação
					_lRet := .F.

					//sai do loop
					Exit
				EndIf

			EndIf
		Next _nX


	EndIf


	// 23/01/14 Validação para compras
	If (_lRet).and.(cTipo == "N").and.(cFormul=="N").and.( ! _lPoder3 )
		_lRet := sfValNeces()
	EndIf

	// valida se o lote eh obrigatorio na entrada da nota
	If (_lRet).and.(cTipo $ "B/D").and.(cFormul=="N").and.(_lLotAtivo).and.(_lLotObrEnt).and.(_lPoder3)
		// varre todos os itens da nota fiscal
		For _nX := 1 to Len(aCols)

			// posiciona no cadastro do produto
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1))
			SB1->(dbSeek( xFilial("SB1")+aCols[_nX,_nP_CodProd]) )

			// se a linha nao estiver deletada / e se o lote do produto foi informado
			If ( ! aCols[_nX][Len(aHeader)+1] ).and.(Rastro(aCols[_nX,_nP_CodProd],"L")).and.(Empty(aCols[_nX,_nP_LotCtl]))
				// mensagem
				Aviso("Tecadi: MT100TOK","É obrigatório informar o lote do produto. Item: "+aCols[_nX][_nP_Item],{"OK"})
				// controle da validacoes/retorno
				_lRet := .f.
			EndIf
		Next _nX
	EndIf

	// valida unidades de medida na entrada da nota
	If (_lRet).and.(cTipo $ "B/D").and.(cFormul=="N").and.(_lPoder3)
		// varre todos os itens da nota fiscal
		For _nX := 1 to Len(aCols)

			// posiciona no cadastro do produto
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1))
			SB1->(dbSeek( xFilial("SB1")+aCols[_nX,_nP_CodProd]) )

			// se a linha nao estiver deletada / valida unidades de medidas
			If ( ! aCols[_nX][Len(aHeader)+1] ).and.(Empty(aCols[_nX,_nP_UnidMed]))
				// mensagem
				Aviso("Tecadi: MT100TOK","É obrigatório informar a unidade de medida do produto. Item: "+aCols[_nX][_nP_Item],{"OK"})

				// controle da validacoes/retorno
				_lRet := .f.
			EndIf

			// se a linha nao estiver deletada / valida unidades de medidas
			If ( ! aCols[_nX][Len(aHeader)+1] ).and.(_lUsoSegUM).and.((Empty(aCols[_nX,_nP_SegUm])).or.(aCols[_nX,_nP_QtSegUm] == 0))
				// mensagem
				Aviso("Tecadi: MT100TOK","É obrigatório informar a segunda unidade de medida do produto. Item: "+aCols[_nX][_nP_Item],{"OK"})
				// controle da validacoes/retorno
				_lRet := .f.
			EndIf

			// se a linha nao estiver deletada / valida unidades de medidas
			If ( ! aCols[_nX][Len(aHeader)+1] ) .and. (_lUsoSegUM) .and. ( ! Empty(aCols[_nX,_nP_SegUm]) ) .and. (Mod(aCols[_nX,_nP_QtSegUm],1) != 0) .and. ( ! _lSegUMFrac )
				// mensagem
				Aviso("Tecadi: MT100TOK","Não é permtido recebimento de caixa fracionada. Item: "+aCols[_nX][_nP_Item],{"OK"})
				// controle da validacoes/retorno
				_lRet := .f.
			EndIf

		Next _nX
	EndIf

	// verifica a necessidade de relacionar a nota fiscal à Programacao de Recebimentos
	If (_lRet).and.(cTipo $ "B/D").and.(cFormul=="N").and.(_lPoder3).and.(_lUsoLogRev)

		// apresenta tela para definicao de logistica reversa
		_cLogReversa := sfLogRever()

		// varre todos os itens da nota fiscal
		For _nX := 1 to Len(aCols)
			// se a linha nao estiver deletada
			If ( ! aCols[_nX][Len(aHeader)+1] )
				// atualiza os dados de controle de logistica reversa
				aCols[_nX,_nP_LogRev] := _cLogReversa
			EndIf
		Next _nX

	EndIf

	// cliente júlio andó, previne digitação
	If (_lRet).and.(cTipo $ "B/D").and.(cFormul=="N").and.(_lPoder3).and.(_lUsoLogRev)

		// apresenta tela para definicao de logistica reversa
		_cLogReversa := sfLogRever()

		// varre todos os itens da nota fiscal
		For _nX := 1 to Len(aCols)
			// se a linha nao estiver deletada
			If ( ! aCols[_nX][Len(aHeader)+1] )
				// atualiza os dados de controle de logistica reversa
				aCols[_nX,_nP_LogRev] := _cLogReversa
			EndIf
		Next _nX

	EndIf


	private _nP_Quant   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_QUANT"})   // quantidade
	private _nP_Total   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_TOTAL"})   // preco total
	private _nP_VlrUn   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_VUNIT"})   // valor unitário


	// restaura area atual
	RestArea(_aAreaAtu)

Return(_lRet)

//Função para validar se a data de necessidade é maior que a data de Digitação
Static Function sfValNeces()
	// variavel temporaria
	local _nX := 0
	// posicao dos campos PESO no header
	local _nP_DtDig := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_DTDIGIT"}) // data de digitacao
	local _nP_Ped   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_PEDIDO"})  // NR pedido
	//retorno lógico
	Local _lRetNec := .t.

	// varre todos os itens da nota fiscal para calcula a quant total de itens e a soma total dos itens
	For _nX := 1 to Len(aCols)
		// se a linha nao estiver deletada
		If (!aCols[_nX][Len(aHeader)+1])
			// atualiza as quantidades totais
			if	( !Empty(aCols[_nX][_nP_Ped]) )
				if	( Month(aCols[_nX][_nP_Dtdig]) <> Month(Posicione("SC7",1,xFilial("SC7")+aCols[_nX][_nP_Ped],"C7_DATPRF")) )
					Aviso("Tecadi: MT100TOK","Somente é permitido o lançamento de nota de pedido de compra relacionado ao mesmo mês. Verifique!",{"OK"} )
					_lRetNec := .f.
				EndIf
			EndIf
		EndIf
	Next _nX

Return( _lRetNec)

// ** funcao que monta tela para selecionar a Prog de Recebimentos
Static Function sfProgReceb()
	Local _lRet := .t.
	Local _aRet := {}
	// variavel temporaria
	Local _nX

	// abre a tela com a lista de programacoes em aberta para o cliente
	// ex: retorno
	// 1-.T. / .F. - Validacao
	// 2-Codigo da Programacao
	// 3-Item da Programacao
	_aRet     := U_FtLstPrg(cA100For,cLoja)
	_lRet     := _aRet[1]
	_cCodProg := _aRet[2]
	_cIteProg := _aRet[3]

	// varre todos os itens da nota fiscal
	For _nX := 1 to Len(aCols)
		// se a linha nao estiver deletada
		If ( ! aCols[_nX][Len(aHeader)+1] )
			// atualiza os dados da programacao de recebimento
			aCols[_nX,_nP_CodRec] := _cCodProg
			aCols[_nX,_nP_IteRec] := _cIteProg
		EndIf
	Next _nX

Return(_lRet)

// ** funcao para rateio do peso bruto e peso liquido entre os itens
Static Function sfRatPeso()
	// variavel de retorno
	local _lRet := .t.
	// quantidade total de itens
	local _nQtdItens := 0
	// soma da quantidade total dos itens
	local _nQtdTotal := 0
	// quantidade de itens ja rateados (tratamento por causa dos itens deletados)
	local _nQtdItRat := 0
	// percentual de rateio do item
	local _nPercRat := 0
	// estrutura do vetor aNFEDanfe
	// 1-F1_TRANSP
	// 2-F1_PLIQUI
	// 3-F1_PBRUTO
	local _nSldLiqui := aNFEDanfe[2]
	local _nSldBruto := aNFEDanfe[3]
	local _nSldCubag := _nCubagem
	// variavel temporaria
	local _nX
	// posicao dos campos PESO no header
	local _nP_PesLiq := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_ZPESOL"}) // peso liquido
	local _nP_PesBru := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_ZPESOB"}) // peso bruto
	// posicao do campo CUBAGEM
	local _nP_Cubag := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_ZCUBAGE"}) // cubagem
	// produto com peso no cadastro
	local _lPesoCad := .f.
	// produto com peso rateado
	local _lPesoRat := .f.

	// varre todos os itens da nota fiscal para calcula a quant total de itens e a soma total dos itens
	For _nX := 1 to Len(aCols)
		// se a linha nao estiver deletada
		If ( ! aCols[_nX][Len(aHeader)+1] )
			// atualiza as quantidades totais
			_nQtdTotal += aCols[_nX,_nP_Quant]
			_nQtdItens ++
		EndIf
	Next _nX

	// varre todos os itens da nota fiscal, rateando o peso bruto, liquido e cubagem
	For _nX := 1 to Len(aCols)
		// se a linha nao estiver deletada
		If ( ! aCols[_nX][Len(aHeader)+1] )

			// quantidade de itens ja rateado
			_nQtdItRat ++

			// calcula o percentual de rateio do item
			_nPercRat := ((aCols[_nX][_nP_Quant] * 100) / _nQtdTotal) / 100

			// verifica se o peso esta informado no produto
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
			SB1->(dbSeek( xFilial("SB1")+aCols[_nX][_nP_CodProd] ))

			// calculo do peso Bruto e Liquido
			If (SB1->B1_PESO > 0).and.(SB1->B1_PESBRU > 0)
				// atualiza o peso liquido
				aCols[_nX,_nP_PesLiq] := Round((aCols[_nX,_nP_Quant] * SB1->B1_PESO),TamSx3("D1_ZPESOL")[2])
				// atualiza o peso bruto
				aCols[_nX,_nP_PesBru] := Round((aCols[_nX,_nP_Quant] * SB1->B1_PESBRU),TamSx3("D1_ZPESOB")[2])
				// marca status de produto com peso no cadastro
				_lPesoCad := .t.
			Else
				// atualiza o peso liquido
				aCols[_nX,_nP_PesLiq] := If(_nQtdItens==_nQtdItRat,_nSldLiqui,Round(aNFEDanfe[2] * _nPercRat,TamSx3("D1_ZPESOL")[2]))
				// atualiza o peso bruto
				aCols[_nX,_nP_PesBru] := If(_nQtdItens==_nQtdItRat,_nSldBruto,Round(aNFEDanfe[3] * _nPercRat,TamSx3("D1_ZPESOB")[2]))
				// marca status de produto com peso rateado
				_lPesoRat := .t.
			EndIf

			// atualiza a cubagem
			aCols[_nX,_nP_Cubag]  := If(_nQtdItens==_nQtdItRat,_nSldCubag,Round(_nCubagem * _nPercRat,TamSx3("D1_ZCUBAGE")[2]))

			// diminui o saldo do peso
			_nSldLiqui -= aCols[_nX,_nP_PesLiq]
			_nSldBruto -= aCols[_nX,_nP_PesBru]
			_nSldCubag -= aCols[_nX,_nP_Cubag]

		EndIf
	Next _nX

	// verifica se existe os dois tipos de peso (cadastro e rateado) - NAO PODE
	If (_lRet).and.(_lPesoCad).and.(_lPesoRat)
		// mensagem
		Aviso("Tecadi: MT100TOK","Não é permitido o rateio do peso quando houver produtos com o peso informado no cadastro. Favor verificar!",{"OK"})
		// variavel de controle
		_lRet := .f.
	EndIf

	// verifica se todo o saldo foi rateado corretamente
	If (_lRet).and.((_nSldLiqui <> 0).or.(_nSldBruto <> 0).or.(_nSldCubag <> 0))
		// mensagem
		Aviso("Tecadi: MT100TOK","Houve divergência no cálculo do peso bruto, peso liquido ou cubagem. Favor verificar!",{"OK"})
		// variavel de controle
		_lRet := .f.
	EndIf

Return(_lRet)

// ** funcao que monta tela para informar a cubagem
Static Function sfCubagem()
	local _lOk := .F.
	local _oFntRoda := TFont():New("Tahoma",,16,,.t.)
	// variaveis temporarias
	local _nX
	// posicao do campo CUBAGEM
	local _nP_Cubag := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="D1_ZCUBAGE"}) // cubagem

	// varre todos os itens da nota fiscal para calcula a quant total de itens e a soma total dos itens
	For _nX := 1 to Len(aCols)
		// se a linha nao estiver deletada
		If (!aCols[_nX][Len(aHeader)+1])
			// atualiza as quantidades totais
			_nCubagem += aCols[_nX,_nP_Cubag]
		EndIf
	Next _nX

	// monta a tela para alterar o peso e a cubagem
	_oDlgInfVlr := MSDialog():New(000,000,160,240,"Cubagem",,,.F.,,,,,,.T.,,,.T. )
	_oSayCuba := TSay():New(017,010,{||"Cubagem:"},_oDlgInfVlr,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetCuba := TGet():New(015,050,{|u| If(PCount()>0,_nCubagem:=u,_nCubagem)},_oDlgInfVlr,060,010,PesqPict("SF1","F1_CUBAGEM"),,,,_oFntRoda,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nCubagem",,)

	// botao para confirmar
	_oBtnConfirmar := TButton():New(060,040,"Confirmar",_oDlgInfVlr,{||_lOk:=.t.,_oDlgInfVlr:End()},050,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgInfVlr:Activate(,,,.T.,{||(_nCubagem > 0)})

Return(_lOk)

// ** funcao para definir se documento eh logistica reversa
Static Function sfLogRever()
	// controle de confirmacao da tela
	local _lOk := .f.
	// opcoes do campo Logistica Reversa
	local _aOpcLogRev := x3CboxToArray("F1_ZLOGREV")[1]
	local _cOpcLogRev := _aOpcLogRev[2]
	// objetos da tela
	local _oDlgLogRev
	local _oCmbLogRev
	local _oBtnOk

	// monta a tela para informar se logistica reversa
	_oDlgLogRev := MSDialog():New(000,000,100,220,"Logística Reversa",,,.F.,,,,,,.T.,,,.T. )
	// campo para selecionar logistica reversa
	_oCmbLogRev := TComboBox():New(008,010,{|u|if(PCount()>0,_cOpcLogRev:=u,_cOpcLogRev)},_aOpcLogRev,090,20,_oDlgLogRev,,,,,,.T.,,,,,,,,,'_cOpcLogRev',"Documento de Logística Reversa?",1)
	// botao para confirmar
	_oBtnOk := TButton():New(035,030,"Confirmar",_oDlgLogRev,{||_lOk := .t., _oDlgLogRev:End() },050,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgLogRev:Activate(,,,.T.,{|| _lOk })

Return(_cOpcLogRev)