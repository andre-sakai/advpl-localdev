#Include 'Protheus.ch'
#include "TOTVS.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSR018                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Espelho NF                                              !
!                  !                                                         !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe Jose Limas                                       !
+------------------+---------------------------------------------------------+
!Alterado por      ! David Branco                                            !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSR018()

	// grupo de perguntas
	local _cPerg   := PadR("TWMSR018",10)
	local _aPerg   := {}
	Local _cQuery  := ""

	//Variavel Temporaria.
	Local _nItens  := 0
	Local _nBox    := 0
	Local _nCab    := 0

	//Controle de Posicionamento de colunas
	Private lin  := 50      // Distancia da linha vertical da margem esquerda
	Private lin1 := 330     // Distancia da linha vertical da margem superior
	Private lin2 := 1950    // Tamanho verttical da linha
	Private	_nLinBox1 := 0
	Private	_nLinBox2 := 0

	Private _aRetSQL  := {}
	Private _cPedCont := ""
	Private _cEtiCont := ""
	Private _aEtiCont := {}

	// Totalizadores Peso Quantudade e Cubagem
	Private _nSunPes := 0
	Private _nSunQtd := 0
	Private _nSunCub := 0

	//Fontes
	Private oFont10  := TFont():New("Arial",10,10,,.F.,,,,.T.,.F.)
	Private oFont10n := TFont():New("Arial",10,10,,.T.,,,,.T.,.F.)
	Private oFont13  := TFont():New("Arial",13,13,,.F.,,,,.T.,.F.)
	Private oFont28n := TFont():New("Arial",28,28,,.T.,,,,.T.,.F.)//Fonte28 Negrito

	// monta a lista de perguntas
	aAdd(_aPerg,{"Nota Tecadi: "           ,"C",TamSx3("F2_DOC")[1]    ,0,"G",,"SF202"}) //mv_par01
	aAdd(_aPerg,{"Serie:"                  ,"C",TamSx3("F2_SERIE")[1]  ,0,"G",,""})      //mv_par02
	aAdd(_aPerg,{"NF Venda (Cliente) de: " ,"C",TamSx3("C5_ZDOCCLI")[1],0,"G",,""})      //mv_par03
	aAdd(_aPerg,{"NF Venda (Cliente) até:" ,"C",TamSx3("C5_ZDOCCLI")[1],0,"G",,""})      //mv_par04
	aAdd(_aPerg,{"Cliente de:"             ,"C",TamSx3("C5_CLIENTE")[1],0,"G",,"SA1"})   //mv_par05
	aAdd(_aPerg,{"Cliente até:"            ,"C",TamSx3("C5_CLIENTE")[1],0,"G",,"SA1"})   //mv_par06

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// chama a tela de parametros
	// abre os parametros
	If !Pergunte(_cPerg,.T.)
		Return(.f.)
	EndIf
	
	// se nada foi preenchido, avisa o usuário
	If ( Empty(mv_par01) ) .AND. ( Empty(mv_par02) ) .AND. ( Empty(mv_par03) ) .AND. ( Empty(mv_par04) ) .AND. ( Empty(mv_par05) ) .AND. ( Empty(mv_par06) ) 
		MsgStop("Nenhum parâmetro preenchido", "Atenção")
		Return .f.
	EndIf
	
	oBrush1 := TBrush():New( , CLR_HGRAY )
	oBrush2 := TBrush():New( , CLR_WHITE )

	// Buscar Notas.
	_cQuery := "SELECT D2_DOC,D2_SERIE,A4_NOME,C5_ZAGRUPA,D2_EMISSAO,"
	_cQuery += " CASE WHEN ZZ_DOCA IS NULL THEN C6_LOCALIZ ELSE ZZ_DOCA END ZZ_DOCA,"
	_cQuery += " Z07_ETQVOL,D2_COD,B1_DESC,"

	_cQuery += "(SELECT SUM(Z07_QUANT)   "
	_cQuery += " FROM "+RetSqlName("Z07")+" Z07SUM "
	_cQuery += " WHERE Z07_FILIAL = '"+xFilial("Z07")+"' AND Z07SUM.D_E_L_E_T_ = ' '
	_cQuery += " AND Z07SUM.Z07_PRODUT = SB1.B1_COD"
	_cQuery += " AND Z07SUM.Z07_ETQVOL = Z07.Z07_ETQVOL"
	_cQuery += " AND Z07SUM.Z07_NUMOS  = Z07.Z07_NUMOS"
	_cQuery += " AND Z07SUM.Z07_SEQOS  = '002') Z07_QUANT, "

	_cQuery += "(SELECT AVG(SC6PES.C6_ZPESOB/SC6PES.C6_QTDVEN) "
	// itens da nota fiscal
	_cQuery += " FROM "+RetSqlName("SD2")+" SD2PES "
	// itens liberados
	_cQuery += " INNER JOIN "+RetSqlName("SC9")+" SC9PES ON SC9PES.C9_FILIAL = '"+xFilial("SC9")+"' AND SC9PES.D_E_L_E_T_ = ' ' AND SD2PES.D2_PEDIDO  = SC9PES.C9_PEDIDO AND SC9PES.C9_ITEM = SD2PES.D2_ITEMPV AND SD2PES.D2_COD = SC9PES.C9_PRODUTO "
	// itens do pedido de venda
	_cQuery += " INNER JOIN "+RetSqlName("SC6")+" SC6PES ON SC6PES.C6_FILIAL = '"+xFilial("SC6")+"' AND SC6PES.D_E_L_E_T_ = ' '  AND SD2PES.D2_PEDIDO     = SC6PES.C6_NUM AND SD2PES.D2_COD = SC6PES.C6_PRODUTO  "
	// filtro padraofe
	_cQuery += " WHERE SD2PES.D2_FILIAL = '"+xFilial("SD2")+"' AND SD2PES.D_E_L_E_T_ = ' '
	// documento / Serie / Produto
	_cQuery += " AND SD2PES.D2_DOC   = SD2.D2_DOC"
	_cQuery += " AND SD2PES.D2_SERIE = SD2.D2_SERIE"
	_cQuery += " AND SD2PES.D2_COD   = SD2.D2_COD ) B1_PESBRU, "

	_cQuery += " Z31_CUBAGE,F2_HORA,C5_ZPEDCLI,C5_ZDOCCLI,C5_NUM,Z07_NUMOS"

	// itens da nota fiscal de retorno
	_cQuery += " FROM "+RetSqlName("SD2")+" SD2 "
	// cab. da nota fiscal
	_cQuery += " INNER JOIN "+RetSqlName("SF2")+" SF2 ON "+RetSqlCond("SF2")+" AND SF2.F2_DOC     = SD2.D2_DOC AND SF2.F2_SERIE = SD2.D2_SERIE AND F2_CLIENTE = D2_CLIENTE AND F2_LOJA =D2_LOJA"
	// itens liberados
	_cQuery += " INNER JOIN "+RetSqlName("SC9")+" SC9 ON "+RetSqlCond("SC9")+" AND SD2.D2_PEDIDO  = SC9.C9_PEDIDO AND SC9.C9_ITEM = SD2.D2_ITEMPV AND SD2.D2_COD = SC9.C9_PRODUTO AND D2_DOC = C9_NFISCAL"
	// cadastro de produtos
	_cQuery += " INNER JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND B1_COD         = D2_COD "
	// pedido de venda
	_cQuery += " INNER JOIN "+RetSqlName("SC5")+" SC5 ON "+RetSqlCond("SC5")+" AND SC5.C5_NUM     = SC9.C9_PEDIDO"
	// filta Apenas com nota do cliente preenchida.
	_cQuery += " AND C5_ZDOCCLI <> '' "
	// itens do pedido de venda
	_cQuery += " INNER JOIN "+RetSqlName("SC6")+" SC6 ON "+RetSqlCond("SC6")+" AND SC5.C5_NUM     = SC6.C6_NUM AND SD2.D2_COD = SC6.C6_PRODUTO AND C6_ITEM = D2_ITEMPV  "
	// itens conferidos
	_cQuery += " INNER JOIN "+RetSqlName("Z07")+" Z07 ON "+RetSqlCond("Z07")+" AND SC5.C5_NUM     = Z07.Z07_PEDIDO AND SD2.D2_COD = Z07.Z07_PRODUT AND Z07_SEQOS = '002' "
	//
	_cQuery += " INNER JOIN "+RetSqlName("Z06")+" Z06 ON "+RetSqlCond("Z06")+" AND Z06.Z06_NUMOS  = Z07.Z07_NUMOS AND Z06_SEQOS = Z07_SEQOS AND Z06_TAREFA = '007'"
	//cadastro de embalagens
	_cQuery += " LEFT JOIN "+RetSqlName("Z31")+" Z31 ON "+RetSqlCond("Z31")+" AND Z31.Z31_CODIGO = Z07.Z07_EMBALA"
	// cab. Ord Servico
	_cQuery += " INNER JOIN "+RetSqlName("Z05")+" Z05 ON "+RetSqlCond("Z05")+" AND Z05.Z05_NUMOS  = Z07.Z07_NUMOS AND D2_COD = Z07_PRODUT "
	// pra contemplar a nova rotina de vinculação de pedidos a CESV
	_cQuery += " LEFT JOIN "+RetSqlName("Z43")+" Z43 ON "+RetSqlCond("Z43")+" AND Z43_NUMOS = Z05_NUMOS AND Z43_CARGA = Z05_CARGA AND Z43_PEDIDO = C6_NUM "
	// movimentacao de veiculo
	_cQuery += " LEFT JOIN "+RetSqlName("SZZ")+" SZZ ON "+RetSqlCond("SZZ")+" AND SZZ.ZZ_CESV = (CASE WHEN Z05_CESV = '' THEN Z43_CESV ELSE Z05_CESV END) "
	// cad. transportadora
	_cQuery += " LEFT JOIN "+RetSqlName("SA4")+" SA4 ON "+RetSqlCond("SA4")+" AND SZZ.ZZ_TRANSP  = SA4.A4_COD  "

	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond('SD2')+" "
	
	// caso a consulta seja pelo doc/serie
	If ( ! Empty(mv_par01) ) .and. ( ! Empty(mv_par02) )
		// documento emitido
		_cQuery += " AND SD2.D2_DOC   = '"+mv_par01+"'"
		_cQuery += " AND SD2.D2_SERIE = '"+mv_par02+"'"
	EndIf
	
	// caso a consulta seja pelo doc do cliente
	If ( ! Empty(mv_par03) ) .and. ( ! Empty(mv_par04) )
		// documento do cliente
		_cQuery += " AND SC5.C5_ZDOCCLI BETWEEN '" + AllTrim(mv_par03) + "' AND '" + AllTrim(mv_par04) + "' "
	EndIf
	
	// cliente de/ate foi informado
	If ( ! Empty(mv_par05) ) .and. ( ! Empty(mv_par06) )
		// documento do cliente
		_cQuery += " AND SC5.C5_CLIENTE BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
	EndIf

	//Agrupa Campos
	_cQuery += " GROUP BY D2_DOC,D2_SERIE,A4_NOME,C5_ZAGRUPA,D2_EMISSAO,ZZ_DOCA,Z07_ETQVOL,D2_COD,B1_DESC,B1_PESBRU,Z31_CUBAGE,F2_HORA,C5_ZPEDCLI,C5_ZDOCCLI,C5_NUM,C6_LOCALIZ,Z07_NUMOS,B1_COD "

	// ordem dos dados
	_cQuery += " ORDER BY D2_DOC, C5_NUM, Z07_ETQVOL"
	
	memowrit("c:\query\TWMSR018.txt",_cQuery)
	
	// carrega resultado do SQL na variavel.
	_aRetSQL := U_SqlToVet(_cQuery)

	If Len(_aRetSQL) <= 0
		MsgStop("Sem informações para Imprimir")
		Return(.F.)
	EndIf

	// Monta objeto para impressão
	_oPrint:= TMSPrinter():New("Espelho NF")
	_oPrint:SetPortrait()
	_oPrint:Setup()

	//_cPedCont := _aRetSQL[1][14]
	//sfCabenf(_cPedCont,_aRetSQL[1][15])

	For _nBox:= 1 To Len(_aRetSQL)

		// informação do número do pedido
		// fiz isso pra validar se posso incluir um novo cabeçalho
		If ( _cPedCont != AllTrim(_aRetSQL[_nBox][14]) )
			// caso não seja a primeira vez que tá rodando, preenche o rodapé
			If( ! Empty(_cPedCont))
				sfRodanf(.t., _nSunPes, _nSunQtd, _nSunCub)
				_oPrint:EndPage()
			EndIf
			
			// defini os campos e inclu cabeçalho
			_cPedCont := _aRetSQL[_nBox][14]
			sfCabenf(_cPedCont, _aRetSQL[_nBox][15])
		EndIf

		If Alltrim(_cPedCont) == Alltrim(_aRetSQL[_nBox][14])

			//Logica para Impressão dos volumes
			If (aScan(_aEtiCont,Alltrim(_aRetSQL[_nBox][7])) == 0)
				Aadd(_aEtiCont,Alltrim(_aRetSQL[_nBox][7]))
				// WMS - ETIQUETAS
				dbSelectArea("Z11")
				Z11->(dbsetorder(1))//Z11_FILIAL+Z11_CODETI
				Z11->(dbSeek(xFilial("Z11") + _aRetSQL[_nBox][7] ))
				_cVolume  := Alltrim(Str(Z11->Z11_QTD1)) + "/" + Alltrim(Str(Z11->Z11_QTD2))
				_cCubag := Alltrim(TransForm(_aRetSQL[_nBox][12],"@E 99,999,999.9999"))
				_nSunCub := _nSunCub + _aRetSQL[_nBox][12]
			Else
				_cVolume  := ""
				_cCubag   := ""
			EndIf

			//Controle de Pagina.
			If  _nItens = 34

				sfRodanf()
				_oPrint:EndPage()
				sfCabenf(_aRetSQL[_nBox][16],_aRetSQL[_nBox][15])
				_nItens  := 1

				_nPesoB  := _aRetSQL[_nBox][10] * _aRetSQL[_nBox][11]//sfPegPesB(_aRetSQL[_nBox][1],_aRetSQL[_nBox][2],_aRetSQL[_nBox][8])
				_nSunPes := _nSunPes + _nPesoB
				//_nQtdPes := sfPegVolu(_aRetSQL[_nBox][7],_aRetSQL[_nBox][8],_aRetSQL[_nBox][17])
				_nQtdPes := _aRetSQL[_nBox][10]
				_nSunQtd := _nSunQtd + _nQtdPes

				_oPrint:Say(_nLinBox1  ,0060 ,_cVolume                                                     ,oFont10)//VOLUME
				_oPrint:Say(_nLinBox1  ,0230 ,Alltrim(_aRetSQL[_nBox][8])                                  ,oFont10)//CÓDIGO
				_oPrint:Say(_nLinBox1  ,0550 ,Alltrim(_aRetSQL[_nBox][9])                                  ,oFont10)//PRODUTO
				_oPrint:Say(_nLinBox1  ,1800 ,Alltrim(TransForm(_nQtdPes,"@E 99,999,999.9999"))            ,oFont10, , , ,2)//QUANTIDADE PEÇAS
				_oPrint:Say(_nLinBox1  ,2000 ,Alltrim(TransForm(_nPesoB,"@E 99,999,999.9999"))             ,oFont10, , , ,2)//P. BRUTO
				_oPrint:Say(_nLinBox1  ,2220 ,_cCubag                                                      ,oFont10, , , ,2)//CUBAGEM

				_nPesoB := 0

				_nLinBox1 := _nLinBox1 + 50
				_nLinBox2 := _nLinBox2 + 50

			Else

				_nPesoB  := _aRetSQL[_nBox][10] * _aRetSQL[_nBox][11]//sfPegPesB(_aRetSQL[_nBox][1],_aRetSQL[_nBox][2],_aRetSQL[_nBox][8])
				_nSunPes := _nSunPes + _nPesoB
				//_nQtdPes := sfPegVolu(_aRetSQL[_nBox][7],_aRetSQL[_nBox][8],_aRetSQL[_nBox][17])
				_nQtdPes := _aRetSQL[_nBox][10]
				_nSunQtd := _nSunQtd + _nQtdPes

				_oPrint:Say(_nLinBox1  ,0060 ,_cVolume                                                    ,oFont10)//VOLUME
				_oPrint:Say(_nLinBox1  ,0230 ,Alltrim(_aRetSQL[_nBox][8])                                 ,oFont10)//CÓDIGO
				_oPrint:Say(_nLinBox1  ,0550 ,Alltrim(_aRetSQL[_nBox][9])                                 ,oFont10)//PRODUTO
				_oPrint:Say(_nLinBox1  ,1800 ,Alltrim(TransForm(_nQtdPes,"@E 99,999,999.9999"))           ,oFont10, , , ,2)//QUANTIDADE PEÇAS
				_oPrint:Say(_nLinBox1  ,2000 ,Alltrim(TransForm(_nPesoB,"@E 99,999,999.9999"))            ,oFont10, , , ,2)//P. BRUTO
				_oPrint:Say(_nLinBox1  ,2220 ,_cCubag                                                     ,oFont10, , , ,2)//CUBAGEM

				_nPesoB := 0
				_nLinBox1 := _nLinBox1 + 50
				_nLinBox2 := _nLinBox2 + 50
				_nItens++

			EndIf

		Else

			sfRodanf(.t.,_nSunPes,_nSunQtd,_nSunCub)
			_oPrint:EndPage()
			_cPedCont := _aRetSQL[_nBox][14]
			sfCabenf(_cPedCont,_aRetSQL[_nBox][15])
			_nItens   := 1
			_aEtiCont := {}
			_nSunPes  := 0
			_nSunQtd  := 0
			_nSunCub  := 0

			//Logica para Impressão dos volumes
			If (aScan(_aEtiCont,Alltrim(_aRetSQL[_nBox][7])) == 0)
				Aadd(_aEtiCont,Alltrim(_aRetSQL[_nBox][7]))
				// WMS - ETIQUETAS
				dbSelectArea("Z11")
				Z11->(dbsetorder(1))//Z11_FILIAL+Z11_CODETI
				Z11->(dbSeek(xFilial("Z11") + _aRetSQL[_nBox][7] ))
				_cVolume := Alltrim(Str(Z11->Z11_QTD1)) + "/" + Alltrim(Str(Z11->Z11_QTD2))
				_cCubag  := Alltrim(TransForm(_aRetSQL[_nBox][12],"@E 99,999,999.9999"))
				_nSunCub := _nSunCub + _aRetSQL[_nBox][12]
			Else
				_cVolume := ""
				_cCubag  := ""
			EndIf

			_nPesoB  := _aRetSQL[_nBox][10] * _aRetSQL[_nBox][11]//sfPegPesB(_aRetSQL[_nBox][1],_aRetSQL[_nBox][2],_aRetSQL[_nBox][8])
			_nSunPes := _nSunPes + _nPesoB
			//_nQtdPes := sfPegVolu(_aRetSQL[_nBox][7],_aRetSQL[_nBox][8],_aRetSQL[_nBox][17])
			_nQtdPes := _aRetSQL[_nBox][10]
			_nSunQtd := _nSunQtd + _nQtdPes

			_oPrint:Say(_nLinBox1  ,0060 ,_cVolume                                                     ,oFont10)//VOLUME
			_oPrint:Say(_nLinBox1  ,0230 ,Alltrim(_aRetSQL[_nBox][8])                                  ,oFont10)//CÓDIGO
			_oPrint:Say(_nLinBox1  ,0550 ,Alltrim(_aRetSQL[_nBox][9])                                  ,oFont10)//PRODUTO
			_oPrint:Say(_nLinBox1  ,1800 ,Alltrim(TransForm(_nQtdPes,"@E 99,999,999.9999"))            ,oFont10, , , ,2)//QUANTIDADE PEÇAS
			_oPrint:Say(_nLinBox1  ,2000 ,Alltrim(TransForm(_nPesoB,"@E 99,999,999.9999"))             ,oFont10, , , ,2)//P. BRUTO
			_oPrint:Say(_nLinBox1  ,2220 , _cCubag                                                     ,oFont10, , , ,2)//CUBAGEM

			_nPesoB := 0

			_nLinBox1 := _nLinBox1 + 50
			_nLinBox2 := _nLinBox2 + 50

		EndIf

	Next _nBox

	sfRodanf(.t.,_nSunPes,_nSunQtd,_nSunCub)

	// Visualiza a impressão
	_oPrint:EndPage()
	_oPrint:Preview()
Return()

//Imprime Cabeçalho do relatório
Static Function sfCabenf(mvNumPed,mvNumDoc)

	Default mvNumPed := ""

	_oPrint:StartPage()
	_oPrint:SayBitmap(-0100,0001,"logo_tecadi_group.png",1100,0700 )// Logo
	_oPrint:Say(0150,1500,"Espelho",oFont28n)
	_oPrint:Say(0280,1290,"Informação dos produtos e embalagens",oFont13)
	_oPrint:Say(0330,1540,"Packing Info",oFont13)

	_nLinBox1 := 500
	_nLinBox2 := 500

	_oPrint:fillRect( { _nLinBox1, 050, _nLinBox1 + 50, 2300}, oBrush1 )
	_nLinBox1 := _nLinBox1 + 5
	_nLinBox2 := _nLinBox2 + 5
	//505
	_oPrint:Say(_nLinBox1  ,0060 ,"Dados básicos",oFont10)

	_nLinBox1 := _nLinBox1 + 50
	_nLinBox2 := _nLinBox2 + 50

	//1ª linha
	_oPrint:Say(_nLinBox1,0060 ,"NF. Venda: "                          ,oFont10 , , , ,)
	_oPrint:Say(_nLinBox1,0360 ,Alltrim(mvNumDoc)                      ,oFont10n, , , ,)
	_oPrint:Say(_nLinBox1,1200 ,"Nº Agrupadora: "                      ,oFont10 , , , ,)
	_oPrint:Say(_nLinBox1,1470 ,Alltrim(_aRetSQL[1][4])                ,oFont10n, , , ,)
	_oPrint:Say(_nLinBox1,1800 ,"Data: "                               ,oFont10 , , , ,)
	_oPrint:Say(_nLinBox1,1900 ,Alltrim(dtoc(Stod(_aRetSQL[1][5])))    ,oFont10n, , , ,)

	_nLinBox1 := _nLinBox1 + 50
	_nLinBox2 := _nLinBox2 + 50

	//2ª linha
	_oPrint:Say(_nLinBox1,0060 ,"Transportadora: "         ,oFont10 , , , ,)
	_oPrint:Say(_nLinBox1,0360 ,Alltrim(_aRetSQL[1][3])    ,oFont10n, , , ,)
	_oPrint:Say(_nLinBox1,1200 ,"Stage/Doca: "             ,oFont10 , , , ,)
	_oPrint:Say(_nLinBox1,1470 ,Alltrim(_aRetSQL[1][6])    ,oFont10n, , , ,)
	_oPrint:Say(_nLinBox1,1800 ,"Hora: "                   ,oFont10 , , , ,)
	_oPrint:Say(_nLinBox1,1900 ,Alltrim(_aRetSQL[1][13])   ,oFont10n, , , ,)
	

	_nLinBox1 := _nLinBox1 + 50
	_nLinBox2 := _nLinBox2 + 50

	//3ª linha
	_oPrint:Say(_nLinBox1,0060 ,"Nº Ped Cliente: "         ,oFont10 , , , ,)
	_oPrint:Say(_nLinBox1,0360 ,Alltrim(mvNumPed)          ,oFont10n, , , ,)

	_nLinBox1 := _nLinBox1 + 100
	_nLinBox2 := _nLinBox2 + 100

	_oPrint:fillRect( { _nLinBox1, 050, _nLinBox1 + 50, 2300}, oBrush1 )
	_oPrint:Say(_nLinBox1  ,0060 ,"Detalhamento do pedido",oFont10)

	_nLinBox1 := _nLinBox1 + 50
	_nLinBox2 := _nLinBox2 + 50

	_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,0220 )
	_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,0540 )
	_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,1650 )
	_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,1880 )
	_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,2080 )
	_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,2300 )

	_oPrint:Say(_nLinBox1  ,0060 ,"VOLUME"           ,oFont10n)
	_oPrint:Say(_nLinBox1  ,0230 ,"CÓDIGO"           ,oFont10n)
	_oPrint:Say(_nLinBox1  ,0550 ,"PRODUTO"          ,oFont10n)
	_oPrint:Say(_nLinBox1  ,1660 ,"QT. PEÇAS"        ,oFont10n)
	_oPrint:Say(_nLinBox1  ,1890 ,"P. BRUTO"         ,oFont10n)
	_oPrint:Say(_nLinBox1  ,2090 ,"CUBAGEM"          ,oFont10n)
	_nLinBox1 := _nLinBox1 + 50
	_nLinBox2 := _nLinBox2 + 50

	For _nCab:= 1 To 35
		_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,0220 )
		_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,0540 )
		_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,1650 )
		_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,1880 )
		_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,2080 )
		_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,2300 )
		_nLinBox1 := _nLinBox1 + 50
		_nLinBox2 := _nLinBox2 + 50
	Next _nCab

	_nLinBox1 := 855
	_nLinBox2 := 855

Return

//Imprime Rodapé do relatório.
Static Function sfRodanf(_mvImp,_mvSunPes,_mvSunQtd,_mvSunCub)

	Default _mvSunPes := 0
	Default _mvSunQtd := 0
	Default _mvSunCub := 0
	Default _mvImp    := .f.

	_nLinBox1 := 2555
	_nLinBox2 := 2555

	_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,0220 )
	_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,1650 )
	_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,1880 )
	_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,2080 )
	_oPrint:Box( _nLinBox1,050 ,_nLinBox2 + 50,2300 )

	_oPrint:Say(_nLinBox1 ,0060 ,"TOTAL"          ,oFont10n)

	If _mvImp
		_oPrint:Say(_nLinBox1 ,1800 ,Alltrim(TransForm(_mvSunQtd,"@E 99,999,999.9999")) ,oFont10n, , , ,2)//QUANTIDADE PEÇAS
		_oPrint:Say(_nLinBox1 ,1980 ,Alltrim(TransForm(_mvSunPes,"@E 99,999,999.9999")) ,oFont10n, , , ,2)//P. BRUTO
		_oPrint:Say(_nLinBox1 ,2220 ,Alltrim(TransForm(_mvSunCub,"@E 99,999,999.9999")) ,oFont10n, , , ,2)//CUBAGEM
	EndIf

	_nLinBox1 := _nLinBox1 + 100
	_nLinBox2 := _nLinBox2 + 100

	_oPrint:fillRect( { _nLinBox1, 050, _nLinBox1 + 50, 2300}, oBrush1 )
	_oPrint:Say(_nLinBox1  ,0060 ,"Comprovante de Coleta",oFont10,2300)

	_nLinBox1 := _nLinBox1 + 110
	_nLinBox2 := _nLinBox2 + 110

	_oPrint:Say(_nLinBox1 - 50 ,0060 ,"Nome da transportadora:",oFont10,2300)
	_oPrint:Say(_nLinBox1 - 50 ,1200 ,"TECADI / Carregado por:",oFont10,2300)
	_oPrint:Box( _nLinBox1,050  ,_nLinBox2 + 80,1100)
	_oPrint:Box( _nLinBox1,1200 ,_nLinBox2 + 80,2300)
	_nLinBox1 := _nLinBox1 + 150
	_nLinBox2 := _nLinBox2 + 150

	_oPrint:Say(_nLinBox1 - 50 ,0060 ,"Nome do responsável da transportadora:",oFont10,2300)
	_oPrint:Say(_nLinBox1 - 50 ,1200 ,"TECADI / Conferido por:",oFont10,2300)
	_oPrint:Box( _nLinBox1,050  ,_nLinBox2 + 80,1100)
	_oPrint:Box( _nLinBox1,1200 ,_nLinBox2 + 80,2300)
	_nLinBox1 := _nLinBox1 + 150
	_nLinBox2 := _nLinBox2 + 150

	_oPrint:Say(_nLinBox1 - 50 ,0060 ,"Data e assinatura:",oFont10,2300)
	_oPrint:Say(_nLinBox1 - 50 ,1200 ,"Data e assinatura:",oFont10,2300)
	_oPrint:Box( _nLinBox1,050  ,_nLinBox2 + 80,1100)
	_oPrint:Box( _nLinBox1,1200 ,_nLinBox2 + 80,2300)
Return()

//Função que faz a media de peso do produto em uma determinada Nota Fiscal
Static Function sfPegPesB(mvDoc,mvSerie,mvProd)
	Local _nRet     := 0
	Local _cQueryPB := ""
	Default mvDoc   := ""
	Default mvSerie := ""
	Default mvProd  := ""

	// Inicio SQL.
	_cQueryPB := "SELECT AVG(C6_ZPESOB/C6_QTDVEN) C6_ZPESOB  "
	// itens da nota fiscal
	_cQueryPB += " FROM "+RetSqlName("SD2")+" SD2 "
	// itens liberados
	_cQueryPB += " INNER JOIN "+RetSqlName("SC9")+" SC9 ON "+RetSqlCond("SC9")+" AND SD2.D2_PEDIDO  = SC9.C9_PEDIDO AND SC9.C9_ITEM = SD2.D2_ITEMPV AND SD2.D2_COD = SC9.C9_PRODUTO "
	// itens do pedido de venda
	_cQueryPB += " INNER JOIN "+RetSqlName("SC6")+" SC6 ON "+RetSqlCond("SC6")+" AND SD2.D2_PEDIDO     = SC6.C6_NUM AND SD2.D2_COD = SC6.C6_PRODUTO  "
	// filtro padraofe
	_cQueryPB += " WHERE "+RetSqlCond('SD2')+" "
	// documento / Serie / Produto
	_cQueryPB += " AND SD2.D2_DOC   = '" + mvDoc   + "'"
	_cQueryPB += " AND SD2.D2_SERIE = '" + mvSerie + "'"
	_cQueryPB += " AND SD2.D2_COD   = '" + mvProd  + "'"

	//memowrit("c:\query\sfPegPesB.txt",_cQueryPB)

	// carrega resultado do SQL na variavel.
	_nRet := U_FTQuery(_cQueryPB)

Return(_nRet)

//Função para pagar quantidade de peças do volume
Static Function sfPegVolu(mvEtqvol,mvProd,mvNunos)
	Local _nRet      := 0
	Local _cQueryPB  := ""
	Default mvEtqvol := ""
	Default mvProd   := ""
	Default mvNunos  := ""

	// Inicio SQL.
	_cQueryPB := "SELECT SUM(Z07_QUANT) Z07_QUANT  "
	_cQueryPB += " FROM "+RetSqlName("Z07")+" Z07 "
	// filtro padrao
	_cQueryPB += " WHERE "+RetSqlCond('Z07')+" "
	_cQueryPB += " AND Z07_PRODUT = '" + mvProd   + "'"
	_cQueryPB += " AND Z07_ETQVOL = '" + mvEtqvol + "'"
	_cQueryPB += " AND Z07_NUMOS  = '" + mvNunos  + "'"
	_cQueryPB += " AND Z07_SEQOS  = '002' "

	//memowrit("c:\query\sfPegVolu.txt",_cQueryPB)

	// carrega resultado do SQL na variavel.
	_nRet := U_FTQuery(_cQueryPB)

Return(_nRet)