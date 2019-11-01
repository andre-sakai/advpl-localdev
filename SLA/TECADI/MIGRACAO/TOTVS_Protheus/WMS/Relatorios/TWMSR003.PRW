#INCLUDE "TOTVS.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Impressao do Romaneio de Carga                          !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2010                                                 !
+------------------+--------------------------------------------------------*/
 
User Function TWMSR003(mvOSIni, mvOSFim)
	// auxiliar
	Local _cAuxPrd := ""

	// valor padrao
	Default mvOSIni := CriaVar("Z6_NUMOS", .f.)
	Default mvOSFim := CriaVar("Z6_NUMOS", .f.)

	// quantidade de produtos por pagina
	Private _nProdPag := 5
	// controle do item ja impresso
	Private _nItProd := 1
	// numero e serie da NF
	Private _cNumNf := ""
	Private _cSerNf := ""
	// numero do pedido de venda
	Private _cNumPed := ""
	// codigo da transportadora
	Private _cCodTrans := ""
	// Cria Objeto para impressao Grafica
	Private _oPrn := TMSPrinter():New("Romaneio de Carga")
	// fontes utilizadas
	PRIVATE _oFont01n := TFontEx():New(_oPrn,"Tahoma",16,16,.T.,.F.,.F.)// bold / italic / under
	PRIVATE _oFont02  := TFontEx():New(_oPrn,"Arial Narrow",12,12,.F.,.F.,.F.)// bold / italic / under
	PRIVATE _oFont03  := TFontEx():New(_oPrn,"Arial Narrow",11,11,.F.,.F.,.F.)// bold / italic / under
	PRIVATE _oFont02n := TFontEx():New(_oPrn,"Arial Narrow",14,14,.T.,.F.,.F.)// bold / italic / under
	PRIVATE _oFont02b := TFontEx():New(_oPrn,"Arial Narrow",12,12,.T.,.F.,.F.)// bold / italic / under

	// imagem da logo
	Private _cImagem := "\"+AllTrim(CurDir())+"\logo_tecadi.jpg"
	// produtos
	// 1-Item
	// 2-Descricao
	// 3-Quant 1a UM
	// 4-1a UM
	// 5-Quant 2a UM
	// 6-2a UM
	// 7-Doc/Pedido
	// 8-Serie
	Private _aProdutos := {}
	// detalhes do servico
	Private _aServicos := {}
	// observacoes
	Private _aObserv := {}
	// lista de avarias
	Private _aAvarias := sfAvarias()
	// controle da linha
	Private _nLin := 0
	// total de pagina
	Private _nPagTot := 1
	// pagina atual
	Private _nPagAtu := 1
	// parametros
	Private cPerg := PadR("WMSR003",10)
	// total de produtos
	Private _nTotProd := 0

	// define como retrato
	_oPrn:SetPortrait()
	// chama a rotina de Configuracao da impressao
//	if ( ! _oPrn:Setup())
//		Return
//	EndIf
	
	If ( !_oPrn:IsPrinterActive() ) 
		_oPrn:Setup()	//-- Escolhe a impressora	
		
		If ( ! _oPrn:IsPrinterActive() )	
			Help(" ",1,"NOPRINTGRA")	//-- Nao foi encontrada configuracao de impressora. ##Certifique-se de que as configurações da impressora estão corretas ou se há alguma impressora conectada.
			Return(Nil)
		Endif
	Endif   
	
	
	// define como retrato
	_oPrn:SetPortrait()

	// cria o grupo de perguntas
	ValidPerg()

	// verifica se deve apresentar parametros
	If ( Empty(mvOSIni) )
		If ! Pergunte(cPerg,.T.)
			Return
		EndIf
	Else
		// carrega parametros mv_par??
		Pergunte(cPerg, .f.)
		
		// atualiza variaveis
		mv_par01 := mvOSIni
		mv_par02 := mvOSFim
	EndIf

	dbSelectArea("SZ6")
	dbSetOrder(1)
	dbSeek(xFilial("SZ6")+mv_par01)

	While SZ6->(!EOF()) .And. SZ6->Z6_NUMOS >= mv_par01 .AND. SZ6->Z6_NUMOS <= mv_par02

		_nItProd   := 1
		_aProdutos := sfRetProd()
		_aServicos := sfRetServ()
		_aObserv   := sfRetObs()

		// reinicia a cada registro do while
		_nTotProd := Len(_aProdutos)

		// calcula quantos produtos distintos
		//aEval(_aProdutos, { |x| Iif( ! Empty(x[1]), Iif(x[1] != _cAuxPrd, _nTotProd++, Nil),Nil), _cAuxPrd := x[1] } )

		// caso não tenha nenhum produto, imprime uma página em branco
		_nTotProd := Iif( _nTotProd == 0, 1, _nTotProd)

		// calcula quantidade de paginas
		_nPagTot := Int(_nTotProd/_nProdPag)

		// resto da divisao
		If (Mod(_nTotProd,_nProdPag) > 0)
			_nPagTot ++
		EndIf

		// impressao dos dados
		For _nPagAtu := 1 to _nPagTot
			// impressao do cabecalho
			sfCabec()
			// impressao dos detalhes
			sfDetalhes()
			// impressao do rodape
			sfRodape()
		Next _nPagAtu

		// grava impressao da via
		RecLock("SZ6",.F.)
		SZ6->Z6_QTDVIAS := SZ6->Z6_QTDVIAS + 1
		MsUnLock()

		SZ6->(dbSkip())

	EndDo

	// preview
	_oPrn:Preview()

Return

Static Function sfAvarias()

	_aTmp:={}

	// define lista de avarias
	aAdd(_aTmp,{"Diferença de Peso"								,"Riscado"						})
	aAdd(_aTmp,{"Amassado"										,"Vazamento" 					})
	aAdd(_aTmp,{"Quebrado"										,"Rasgado"						})
	aAdd(_aTmp,{"Refitado"										,"Furado"						})
	aAdd(_aTmp,{"Aberto"										,"Molhado"						})
	aAdd(_aTmp,{"Despregado"									,"Repregado"					})
	aAdd(_aTmp,{"Indícios de Violação"							,""								})
	aAdd(_aTmp,{"Lacre Violado / Divergente"					,""								})
	aAdd(_aTmp,{"Carga Recebida com Alteração de Informação"	,""								})
	aAdd(_aTmp,{"Carga Lacrada Pelo Fiel Depositário"			,""								})
	aAdd(_aTmp,{"Outros / Observações"							,""								})

Return _aTmp

//** funcao para impressao do cabecalho
Static Function sfCabec()
	// controle temporario da linha
	Local _nTmpLin := 0
	// detalhes da movimentacao
	// estrutura
	// 1 - Nr RIC
	// 2 - Nr Container
	// 3 - Tipo Container
	// 4 - Lacre
	// 5 - Conteudo Container (C-Cheio/V-Vazio)
	// 6 - Tamanho Container (20 / 40 / CS)
	// 7 - Transportadora
	// 8 - Placa 1
	// 9 - Placa 2
	// 10- Cod. Motorista
	Local _aDetCont := sfDetCont()
	Local _cQuery   := ""
	Local _cRefPg   := "" // referencia da PG

	// cria nova Pagina
	_oPrn:StartPage()

	_nLin := 70

	// primeira linha - box
	_oPrn:Box(_nLin,0060,_nLin+260,2290)
	// logo
	_oPrn:SayBitmap(_nLin+10,0070,_cImagem,744.8,239.4)
	// coluna - antes "ROMANEIO DE CARGA"
	_oPrn:Line(_nLin,0980,_nLin+260,0980)
	// titulo
	_oPrn:Say(_nLin+90,1640,"ROMANEIO DE CARGA - NR "+Transf(SZ6->Z6_NUMOS,PesqPict("SZ6","Z6_NUMOS")),_oFont01n:oFont,,,,2)
	_oPrn:Say(_nLin+165,1660,"PROGRAMAÇÃO - NR "+SZ6->Z6_CODIGO,_oFont02:oFont,,,,2)
	// controle de vias impressas
	_oPrn:Say(_nLin+200,1170,AllTrim(STR(SZ6->Z6_QTDVIAS+1))+"ª Via(s)",_oFont02:oFont,,,,1)
	// controle de paginas
	_oPrn:Say(_nLin+200,2270,"Pág.: "+AllTrim(Str(_nPagAtu))+" de "+AllTrim(Str(_nPagTot)),_oFont02:oFont,,,,1)
	_nLin += 260

	// segunda linha - box - dados do cliente
	_oPrn:Box(_nLin,0060,_nLin+520,2290)
	_nTmpLin := 30

	_oPrn:Say(_nLin+_nTmpLin,0080,"Data:",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,0390,DtoC(SZ6->Z6_EMISSAO),_oFont02:oFont)

	_oPrn:Say(_nLin+_nTmpLin,0660,"Hora Início: ___ : ___",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,1060,"Hora Término: ___ : ___",_oFont02:oFont)

	_oPrn:Say(_nLin+_nTmpLin,1560,"Movimentação:",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,2270,U_FtX3CBox("Z6_TIPOMOV",SZ6->Z6_TIPOMOV,2,3),_oFont02n:oFont,,,,1)
	_nTmpLin += 70

	_oPrn:Say(_nLin+_nTmpLin,0080,"Cliente:",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,0390,Posicione("SA1",1, xFilial("SA1")+SZ6->Z6_CLIENTE+SZ6->Z6_LOJA ,"A1_NOME") ,_oFont02n:oFont)
	_oPrn:Say(_nLin+_nTmpLin,1560,"Unidade:",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,1820,AllTrim(SM0->M0_FILIAL),_oFont02:oFont)
	_nTmpLin += 70

	// dados do container
	_oPrn:Say(_nLin+_nTmpLin,0080,"Container:",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,0390,If(SZ6->Z6_TIPOMOV=="E",Transf(SZ6->Z6_CONTAIN,PesqPict("SZC","ZC_CODIGO")),""),_oFont02:oFont)

	_oPrn:Say(_nLin+_nTmpLin,0800,"Tipo do Container: ",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,1200,If(SZ6->Z6_TIPOMOV=="E",Tabela("ZA",_aDetCont[1,3]),""),_oFont02:oFont)

	_oPrn:Say(_nLin+_nTmpLin,1560,"Lacre:",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,1820,If(SZ6->Z6_TIPOMOV=="E",_aDetCont[1,4],""),_oFont02:oFont)
	// controle da linha
	_nTmpLin += 70

	// dados do container
	_oPrn:Say(_nLin+_nTmpLin,0080,"Conteúdo:",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,0390,If(SZ6->Z6_TIPOMOV=="E",_aDetCont[1,5],""),_oFont02n:oFont)

	_oPrn:Say(_nLin+_nTmpLin,0800,"Tamanho: ",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,1200,If(SZ6->Z6_TIPOMOV=="E",_aDetCont[1,6],""),_oFont02:oFont)
	// controle da linha
	_nTmpLin += 70

	// na entrada, pega a transp da movimentacao
	If (SZ6->Z6_TIPOMOV=="E")
		_cCodTrans := _aDetCont[1,7]
		// na saida, do pedido de vendas
	ElseIf (SZ6->Z6_TIPOMOV=="S")
		_cCodTrans := Posicione("SC5",1, xFilial("SC5")+_cNumPed ,"C5_TRANSP")
	EndIf

	_oPrn:Say(_nLin+_nTmpLin,0080,"Transportador:",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,0390,If(SZ6->Z6_TIPOMOV=="I","",Posicione("SA4",1, xFilial("SA4")+_cCodTrans ,"A4_NOME")),_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,1560,"Placas:",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,1820,If(SZ6->Z6_TIPOMOV=="I","",_aDetCont[1,8] +" / "+ _aDetCont[1,9]),_oFont02:oFont)
	_nTmpLin += 70

	// tipo do caminhao
	_oPrn:Say(_nLin+_nTmpLin,0080,"Tipo Caminhão:",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,0390,If(SZ6->Z6_TIPOMOV=="I","",Posicione("DA3",1, xFilial("DA3")+_aDetCont[1,8] ,"DA3_DESC")),_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,0800,"Motorista:",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,1020,If(SZ6->Z6_TIPOMOV $ "E",Posicione("DA4",1, xFilial("DA4")+_aDetCont[1,10] ,"DA4_NOME"),""),_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,1805,If(SZ6->Z6_TIPOMOV $ "E","DOC: "+Transf(DA4->DA4_CPF,PesqPict("DA4","DA4_CPF")),""),_oFont02:oFont)
	_nTmpLin += 70

	// -- David 20/12/13
	// pega a referência para colocar no cabeçalho do romaneio
	_cQuery := "select Z1_REFEREN "
	_cQuery += "  from "+RetSqlName("SZ1")+" SZ1 "
	_cQuery += " where "+RetSqlCond("SZ1")+" "
	_cQuery += "   and Z1_CODIGO = '"+SZ6->Z6_CODIGO+"' "

	// incluo a referência da PG
	_cRefPg := U_FtQuery(_cQuery)

	// documentos
	_oPrn:Say(_nLin+_nTmpLin,0080,"DI/NF:",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,0220,If(SZ6->Z6_TIPOMOV=="I","",Posicione("SZ2",1, xFilial("SZ2")+SZ6->Z6_CODIGO+SZ6->Z6_ITEM ,"Z2_DOCUMEN")),_oFont02:oFont)

	// Referência da PG
	_oPrn:Say(_nLin+_nTmpLin,0800,"REF.:",_oFont02:oFont)
	_oPrn:Say(_nLin+_nTmpLin,0900,_cRefPg,_oFont02:oFont)
	_nTmpLin += 70

	// controle da linha
	_nLin += _nTmpLin
	_nLin += 20

Return

//** funcao para impressao dos detalhes
Static Function sfDetalhes()
	// variavel temporaria
	Local _nX
	// controle temporario da linha
	Local _nTmpLin := 0, _nTmpDesc := 0
	// controle temporario da linha de avarias
	Local _nTmpLin2 := 0
	// itens por pagina
	Local _nTmpItens := 0
	// dados do produto
	local _cCodProd   := ""
	local _cDescProd  := ""
	local _cInfAdProd := ""
	local _cLoteCtl   := ""

	// controle de descrição de info adicional
	local _nCtrlInfo := 0

	// quantidade de paletes e volumes
	local _cQtdPltVol := ""

	// numero do pedido do cliente (por item)
	local _cNrPedCli := ""

	// terceira linha - box - dados dos produtos
	_oPrn:Say(_nLin,0080,"PRODUTOS",_oFont02n:oFont)
	_nLin += 70
	_nTmpLin := 30
	_nTmpDesc := 50
	_nTmpInfAdic := 50

	// impressao dos produtos
	For _nX := _nItProd to Len(_aProdutos)

		// reinicia variaveis
		_cQtdPltVol := ""
		_cNrPedCli  := ""

		// verifica se é linha valida
		If (!Empty(_aProdutos[_nX,2]))
			// detalhes do item
			// dados do produto
			_cCodProd   := AllTrim(_aProdutos[_nX,1])
			_cDescProd  := AllTrim(_aProdutos[_nX,2])
			_cInfAdProd := AllTrim(_aProdutos[_nX,11])

			// caso o movimento não seja de saída e tenha o item do pedido
			If (SZ6->Z6_TIPOMOV $ "E|I").and.( ! Empty(_aProdutos[_nX,1]))
				_cCodProd  := " (    ) " + _cCodProd
			EndIf

			// caso seja movimentado de entrada ou saída e tenha o lote
			If (SZ6->Z6_TIPOMOV $ "E|S").and.( ! Empty(_aProdutos[_nX,10]))
				_cLoteCtl := " - Lote: " + AllTrim(_aProdutos[_nX,10])
			EndIf

			// caso seja movimentado de saída e tenha quantidade de paletes e volumes informados
			If (SZ6->Z6_TIPOMOV == "S").and.((_aProdutos[_nX,12] + _aProdutos[_nX,13]) > 0)
				_cQtdPltVol := " - "+AllTrim(Str(_aProdutos[_nX,12]))+" Palete(s) / "+AllTrim(Str(_aProdutos[_nX,13]))+" Volume(s)"
			EndIf

			// caso seja movimentado de saída e tenha numero do pedido do cliente
			If (SZ6->Z6_TIPOMOV == "S").and.( ! Empty(_aProdutos[_nX,14]) )
				_cNrPedCli := " - Pedido Cliente: "+AllTrim(_aProdutos[_nX,14])
			EndIf

			// se o produto foi informado (para casos onde a descrição + infoadicional são excedentes)
			If ( ! Empty(_aProdutos[_nX,1]) )
				// codigo do produto
				_oPrn:Say(_nLin+_nTmpLin,0080, "Cod.: " + _cCodProd + _cLoteCtl + _cQtdPltVol + _cNrPedCli,_oFont02:oFont)
				// descrição do produto
				_oPrn:Say(_nLin+_nTmpLin + _nTmpDesc,0080, "Desc.: " + _cDescProd,_oFont02:oFont)
				// info adicional
				If ( ! Empty(_cInfAdProd) )
					_oPrn:Say(_nLin+_nTmpLin + _nTmpDesc + _nTmpInfAdic,0080, _cInfAdProd,_oFont02:oFont)
				EndIf
			EndIf

			// quando for o complemento da descricao, nao imprime os valores das quantidades (segunda linha)
			If (!Empty(_aProdutos[_nX,1]))
				// quantidade
				_oPrn:Say(_nLin+_nTmpLin,1680,"Qtd.:",_oFont02:oFont)

				// só imprime quantidade na saida
				If (SZ6->Z6_TIPOMOV=="S")

					// primeira unidade de medida
					_oPrn:Say(_nLin+_nTmpLin,2030,Transf(_aProdutos[_nX,3],PesqPict("SC6","C6_QTDVEN"))+" "+_aProdutos[_nX,4],_oFont02:oFont,,,,1) //OGA - 15/08

					// segunda unidade de medida
					If (_aProdutos[_nX,5] > 0)
						_oPrn:Say(_nLin+_nTmpLin,2310,Transf(_aProdutos[_nX,5],PesqPict("SC6","C6_QTDVEN"))+" "+_aProdutos[_nX,6],_oFont02:oFont,,,,1)//OGA - 15/08
					EndIf

					// ENTRADA
				ElseIf (SZ6->Z6_TIPOMOV $ "E|I")
					_oPrn:Say(_nLin+_nTmpLin,2000,"____________",_oFont02:oFont)
				EndIf
			EndIf
		EndIf

		// controle de linha
		_nTmpLin += 80 + _nTmpDesc + Iif( ! Empty(_cInfAdProd), _nTmpInfAdic, 0)
		// controle de item do vetor ja impresso
		_nItProd ++
		// controle de itens impresso por pagina
		Iif( ! Empty(_aProdutos[_nX][1]), _nTmpItens ++, 0)

		// caso atenda os itens por pagina, sai do Loop
		If (_nTmpItens == _nProdPag)
			Exit
		EndIf
	Next _nX

	// default de valores pra que tudo fique fixo
	_nLin    := 940
	_nTmpLin := 930

	// ao final da impressao dos produtos, cria o box
	_oPrn:Box(_nLin,0060,_nLin+_nTmpLin,2290)

	// quarta linha - box - dados dos servicos
	_nLin += _nTmpLin
	_nLin += 20
	_oPrn:Say(_nLin,0080,"SERVIÇOS",_oFont02n:oFont)
	_oPrn:Say(_nLin,1320,"AVARIAS / FOTOS",_oFont02n:oFont)
	_nLin += 70

	// servicos
	_nTmpLin := 30
	For _nX := 1 to Len(_aServicos)
		_oPrn:Say(_nLin+_nTmpLin,0080,_aServicos[_nX,2],_oFont02:oFont)
		_nTmpLin += 60
	Next _nX

	// adiciona a info do operador
	_oPrn:Say((_nLin+_nTmpLin)-210,0080,"Operador: ________________________________________",_oFont02:oFont)
	_nTmpLin += 60

	// opcoes de avarias
	_nTmpLin2 := 30
	_oPrn:Say(_nLin+_nTmpLin2,1320,"Fotos - Quant ________",_oFont02:oFont)
	_nTmpLin2 += 60

	For _nX := 1 to Len(_aAvarias)
		If (!Empty(_aAvarias[_nX,1]))
			_oPrn:Say(_nLin+_nTmpLin2,1320,"[    ] "+_aAvarias[_nX,1],_oFont02:oFont)
		EndIf
		If (!Empty(_aAvarias[_nX,2]))
			_oPrn:Say(_nLin+_nTmpLin2,1800,"[    ] "+_aAvarias[_nX,2],_oFont02:oFont)
		EndIf
		_nTmpLin2 += 60
	Next _nX

	// aumento o espaço pra próxima informação
	_nTmpLin2 += 60

	// linha para informação da CUBAGEM
	_oPrn:Say((_nLin+_nTmpLin2)-30,1320,"Informar Cubagem ___________",_oFont02:oFont)

	// ao final da impressao dos servicos, cria o box
	_oPrn:Box(_nLin,0060,(_nLin+_nTmpLin)-200,2290)
	// coluna separadora (servico | avarias)
	_oPrn:Line(_nLin,1300,(_nLin+_nTmpLin)-200,1300)
	// controle da linha
	_nLin += _nTmpLin
	_nLin += 20

Return

//** funcao para impressao do rodape
Static Function sfRodape()
	// controle temporario da linha
	Local _nTmpLin := 0
	// linha do tamanho correto
	_nLin := _nLin - 200
	// quinta linha - box - observacoes
	_oPrn:Say(_nLin,0080,"OBSERVAÇÕES",_oFont02n:oFont)
	_nLin += 70
	_oPrn:Box(_nLin,0060,_nLin+250,2290)
	_nTmpLin += 20
	For _nX := 1 to Len(_aObserv)
		_oPrn:Say((_nLin+_nTmpLin),0080,_aObserv[_nX],_oFont03:oFont)
		_nTmpLin += 60
	Next _nX
	// controle da linha
	_nLin += _nTmpLin
	_nLin += 140

	// assinaturas
	_oPrn:Say(_nLin-20,0060,"Ass. Motorista"+Replicate("_",30),_oFont02b:oFont)
	_oPrn:Say(_nLin-20,1200,"Ass. Conferente"+Replicate("_",30),_oFont02b:oFont)

	// finaliza pagina
	_oPrn:EndPage()

Return

//** funcao que retorna os servicos da Ordem
Static Function sfRetServ()
	Local _aRet := {}
	Local _cSeekSZ7
	Local _nServPag := 16
	Local _nX
	Local _nResto


	// posiciona nos servicos da ordem
	dbSelectArea("SZ7")
	SZ7->(dbSetOrder(1))//1-Z7_FILIAL, Z7_NUMOS, Z7_CODATIV
	SZ7->(dbSeek( _cSeekSZ7 := xFilial("SZ7")+SZ6->Z6_NUMOS ))
	While SZ7->(!Eof()).and.(SZ7->(Z7_FILIAL+Z7_NUMOS)==_cSeekSZ7)
		// adiciona o servico
		aAdd(_aRet,{SZ7->Z7_ORDEM, AllTrim(Posicione("SZT",1, xFilial("SZT")+SZ7->Z7_CODATIV ,"ZT_DESCRIC"))+" ("+SZ7->Z7_UNIDCOB+")" } )
		// proximo registro
		SZ7->(dbSkip())
	EndDo

	// ordena os dados pela coluna: ordem
	aSort(_aRet,,,{|x,y|x[1]<y[1]})

	// padroniza vetor
	_nResto := (Mod(Len(_aRet),_nServPag))

	If (_nResto > 0)
		For _nX := 1 to (_nServPag - _nResto)
			aAdd(_aRet,{"",""})
		Next _nX
	EndIf

	// adiciona a linha para informar o operador
	//aAdd(_aRet,{"","Operador: _______________________________"})

Return(_aRet)

//** funcao para retonar os produtos da nota/pedido
Static Function sfRetProd()
	// estrutura
	// 1-Item
	// 2-Descricao
	// 3-Quantidade
	// 4-Num NF
	// 5-Serie NF
	Local _aRet := {}
	Local _cQuery
	Local _nX, _nY
	Local _nResto
	local _aItens := {}
	local _cTmpDesc
	local _cTmpInfAdic
	local _lSegLinha := .f.
	// maximo de caracteres por linha
	local _nMaxChar
	// controle de descrição
	local _nDescMax := 0

	// monta a query para buscar os dados
	// ENTRADA
	If (SZ6->Z6_TIPOMOV=="E")

		_cQuery := "SELECT D1_COD, RTRIM(B1_DESC) + " - " + RTRIM(B1_ZINFADI) IT_DESCR, "
		_cQuery += "D1_QUANT, D1_UM, D1_QTSEGUM, D1_SEGUM, D1_DOC, D1_SERIE, D1_ITEM, D1_LOTECTL, 0 QTD_PALETES, 0 QTD_VOLUMES, '' NR_PEDCLI "
		_cQuery += "FROM "+RetSqlName("SD1")+" SD1 "
		// cadastro de produtos
		_cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON B1_FILIAL = '"+xFilial("SB1")+"' AND B1_COD = D1_COD AND SB1.D_E_L_E_T_ = ' ' "
		// filtro da nota
		_cQuery += "WHERE D1_FILIAL = '"+xFilial("SD1")+"' AND SD1.D_E_L_E_T_ = ' ' "
		_cQuery += "AND D1_FORNECE = '"+SZ6->Z6_CLIENTE+"' AND D1_LOJA = '"+SZ6->Z6_LOJA+"' "
		_cQuery += "AND D1_TIPO = 'B' "
		_cQuery += "AND D1_PROGRAM = '"+SZ6->Z6_CODIGO+"' AND D1_ITEPROG = '"+SZ6->Z6_ITEM+"' "
		_cQuery += "ORDER BY D1_COD"
		// alimenta vetor
		_aItens := U_SqlToVet(_cQuery)

		// SAIDA
	ElseIf (SZ6->Z6_TIPOMOV=="S")

		_cQuery := " SELECT C6_PRODUTO, RTRIM(B1_DESC) + " - " + RTRIM(B1_ZINFADI) IT_DESCR, "
		_cQuery += " C6_QTDVEN, C6_UM, C6_UNSVEN, C6_SEGUM, C6_NUM, '' IT_SERIE, C6_ITEM, C6_LOTECTL, C6_ZQTDPLT, C6_ZQTDVOL, C6_PEDCLI NR_PEDCLI "
		// itens do pedido de venda
		_cQuery += " FROM "+RetSqlTab("SC6")
		// relaciona com o item da nota fiscal de entrada
		_cQuery += " INNER JOIN "+RetSqlTab("SD1")+" ON "+RetSqlCond("SD1")
		_cQuery += "       AND D1_DOC = C6_NFORI AND D1_SERIE = C6_SERIORI AND D1_ITEM = C6_ITEMORI "
		_cQuery += "       AND D1_FORNECE = C6_CLI AND D1_LOJA = C6_LOJA "
		_cQuery += "       AND D1_PROGRAM = '"+SZ6->Z6_CODIGO+"' AND D1_ITEPROG = '"+SZ6->Z6_ITEM+"' "
		// cadastro de produtos
		_cQuery += " INNER JOIN "+RetSqlTab("SB1")+" ON "+RetSqlCond("SB1")+" AND B1_COD = C6_PRODUTO "
		// filtro da nota
		_cQuery += " WHERE "+RetSqlCond("SC6")
		// numero do pedido de venda
		_cQuery += " AND C6_NUM = '"+SZ6->Z6_PEDIDO+"' "
		// ordem dos dados
		_cQuery += " ORDER BY C6_PRODUTO"
		// alimenta vetor
		_aItens := U_SqlToVet(_cQuery)

		// INTERNOS
	ElseIf (SZ6->Z6_TIPOMOV=="I")

		_cQuery := "SELECT D1_COD, RTRIM(B1_DESC) + " - " + RTRIM(B1_ZINFADI) IT_DESCR, "
		_cQuery += "D1_QUANT, D1_UM, D1_QTSEGUM, D1_SEGUM, D1_DOC, D1_SERIE, D1_ITEM, D1_LOTECTL, 0 QTD_PALETES, 0 QTD_VOLUMES, '' NR_PEDCLI "
		_cQuery += "FROM "+RetSqlName("SD1")+" SD1 "
		// cadastro de produtos
		_cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON B1_FILIAL = '"+xFilial("SB1")+"' AND B1_COD = D1_COD AND SB1.D_E_L_E_T_ = ' ' "
		// filtro da nota
		_cQuery += "WHERE D1_FILIAL = '"+xFilial("SD1")+"' AND SD1.D_E_L_E_T_ = ' ' "
		_cQuery += "AND D1_DOC+D1_SERIE = '"+SZ6->Z6_DOCSERI+"' "
		_cQuery += "AND D1_FORNECE = '"+SZ6->Z6_CLIENTE+"' AND D1_LOJA = '"+SZ6->Z6_LOJA+"' "
		_cQuery += "AND D1_PROGRAM = '"+SZ6->Z6_CODIGO+"' AND D1_ITEPROG = '"+SZ6->Z6_ITEM+"' "
		_cQuery += "ORDER BY D1_COD"
		// alimenta vetor
		_aItens := U_SqlToVet(_cQuery)

	EndIf

	// grava a query pra debug
	memowrit("C:\query\twmsr003.txt",_cQuery)

	// se for entrada, pega o numero da NF
	If (SZ6->Z6_TIPOMOV=="E").and.(Len(_aItens)>0)
		_cNumNf := _aItens[1,7]
		_cSerNf := _aItens[1,8]
		// na saida, peGa o numero do pedido
	ElseIf (SZ6->Z6_TIPOMOV=="S").and.(Len(_aItens)>0)
		_cNumPed := _aItens[1,7]
	EndIf

	// varre todo o vetor, para fazer a quebra da descricao do produto
	For _nY := 1 to Len(_aItens)
		// prepara descricao do produto
		_cTmpTexto   := SubStr( AllTrim(_aItens[_nY,2]),1,74)
		_cTmpInfAdic := SubStr( AllTrim(_aItens[_nY,2]),75,150)

		// alimenta variavel de retorno
		aAdd(_aRet,{ ;
			_aItens[_nY,1] ,; // 1 -codigo
			_cTmpTexto     ,; // 2 -descricao
			_aItens[_nY,3] ,; // 3 -qtd 1a Unidade
			_aItens[_nY,4] ,; // 4 -1a Unidade Med
			_aItens[_nY,5] ,; // 5 -qtd 2a Unidade
			_aItens[_nY,6] ,; // 6 -2a Unidade Med
			_aItens[_nY,7] ,; // 7 -nota
			_aItens[_nY,8] ,; // 8 -serie
			_aItens[_nY,9] ,; // 9 -item
			_aItens[_nY,10],; // 10-lote
			_cTmpInfAdic   ,; // 11-infadic
			_aItens[_nY,11],; // 12-quantidade de paletes
			_aItens[_nY,12],; // 13-quantidade de volumes
			_aItens[_nY,13]}) // 14-Nr Pedido Cliente

	Next _nY

	// padroniza vetor
	_nResto := (Mod(Len(_aRet),_nProdPag))

Return(_aRet)

//** funca para retornar as observacoes
Static Function sfRetObs()
	Local _aRet := {}
	Local _nObsPag := 4
	Local _nX

	cObserv:=SZ6->Z6_OBSERVA
	For _nX := 1 to Min(MLCount(cObserv,150),_nObsPag)
		aAdd(_aRet,MemoLine(cObserv,150,_nX))
	Next _nX

	// padrozinha vetor
	For _nX := 1 to (_nObsPag - Len(_aRet))
		// adiciona linhas em branco
		aAdd(_aRet,"")
	Next _nX

Return(_aRet)

//** funcao para retorno dos dados da movimentacao
Static Function sfDetCont()
	// estrutura de retorno
	// 1 - Nr RIC
	// 2 - Nr Container
	// 3 - Tipo Container
	// 4 - Lacre
	// 5 - Conteudo Container (C-Cheio/V-Vazio)
	// 6 - Tamanho Container (20 / 40 / CS)
	// 7 - Transportadora
	// 8 - Placa 1
	// 9 - Placa 2
	// 10- Cod. Motorista
	Local _aRet := {}
	// query
	Local _cQuery

	// se for entrada, busca os dados do container
	If (SZ6->Z6_TIPOMOV=="E")
		_cQuery := "SELECT Z3_RIC, Z3_CONTAIN, Z3_TIPCONT, Z3_LACRE, "
		// conteudo
		_cQuery += "CASE WHEN Z3_CONTEUD = 'C' THEN 'CHEIO' ELSE 'VAZIO' END Z3_CONTEUD, "
		// tamanho
		_cQuery += "CASE WHEN Z3_TAMCONT = 'CS' THEN 'CARGA SOLTA' ELSE Z3_TAMCONT END Z3_TAMCONT, "
		_cQuery += "Z3_TRANSP, Z3_PLACA1, Z3_PLACA2, Z3_MOTORIS "
		// movimentacao
		_cQuery += "FROM "+RetSqlName("SZ3")+" SZ3 "
		// filtros
		_cQuery += "WHERE Z3_FILIAL = '"+xFilial("SZ3")+"' AND SZ3.D_E_L_E_T_ = ' ' "
		_cQuery += "AND Z3_PROGRAM = '"+SZ6->Z6_CODIGO+"' AND Z3_ITEPROG = '"+SZ6->Z6_ITEM+"' "
		_cQuery += "AND Z3_CLIENTE = '"+SZ6->Z6_CLIENTE+"' AND Z3_LOJA = '"+SZ6->Z6_LOJA+"' "
		_cQuery += "AND Z3_CONTAIN = '"+SZ6->Z6_CONTAIN+"' "
		_cQuery += "AND Z3_RIC     = '"+SZ6->Z6_RIC+"' "
		_cQuery += "AND Z3_TPMOVIM = '"+SZ6->Z6_TIPOMOV+"' "

		// retorna o conteudo para o vetor
		_aRet := U_SqlToVet(_cQuery)
	EndIf

	// se nao retornou dados
	If (Len(_aRet)==0)
		aAdd(_aRet,{"",;
			"",;
			"",;
			"",;
			"",;
			"",;
			"",;
			IIF(SZ6->Z6_TIPOMOV=="S",SZ6->Z6_PLACA1,""),;
			"",;
			""})
	EndIf

Return(_aRet)

//** funcao para criar o grupo de perguntas
Static Function ValidPerg

	Local _sAlias := Alias()
	Local aRegs := {}
	Local i,j

	dbSelectArea("SX1")
	dbSetOrder(1)

	//+--------------------------------------------------------------+
	//¦ Variaveis utilizadas para parametros                         ¦
	//¦ mv_par01             // Da Ordem de Servico                  ¦
	//¦ mv_par02             // Ate a Ordem de Servico               ¦
	//+--------------------------------------------------------------+

	aAdd(aRegs,{cPerg,"01","Da Ordem de Servico" ,"","","mv_ch1","C",9,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SZ6"})
	aAdd(aRegs,{cPerg,"02","Ate Ordem de Servico" ,"","","mv_ch2","C",9,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SZ6"})

	For i:=1 to Len(aRegs)
		If !dbSeek(cPerg+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next

	dbSelectArea(_sAlias)

Return