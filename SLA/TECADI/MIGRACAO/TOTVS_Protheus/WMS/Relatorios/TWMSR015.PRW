#Include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para impressao de etiquetas do WMS               !
!                  ! - CODEAN                                                !
+------------------+---------------------------------------------------------+
!Autor             ! David Branco                ! Data de Criação ! 03/2015 !
+------------------+--------------------------------------------------------*/

User Function TWMSR015()

	// variavel de retorno
	local _lRet := .F.

	// objetos da tela
	local _oDlgSelImp
	local _oCBxTpEtiq
	local _oBtnEtqOk, _oBtnEtqCan

	// impressoras disponiveis no windows
	local _aImpWindows := U_FtRetImp()

	// arquivos temporarios
	local _cTmpArquivo := ""
	local _cTmpBat     := ""
	local _nTmpHdl

	// retorna a pasta temporaria da maquina
	local _cPathTemp := AllTrim(GetTempPath())
	local _cTmpEtiq := "" // arquivo para criação da etiqueta

	// query da etiqueta
	local _cQryEtiq := ""
	local _nQtdReg := 0

	// perguntas
	local _cPerg := PadR("TWMSR015",10)

	// codigo da etiqueta
	local _cCodEtiq := ""

	// controle de transação
	local _lOk := .f.
	local _cImpSelec := U_FtImpZbr()

	// tipo da etiqueta
	local _cTpEtq := ""

	// tipos de etiquetas
	local _cOrigEtiq := ""

	// tipo do codigo de barras
	local _lEan13 := .F.
	local _lUpc12 := .F.
	local _lCod128 := .F.

	// medidas para as etiquetas de 4 colunas
	local nXPEtiq	:= 200
	local nXTit		:= 55
	local nXEan13	:= 155
	local nXCode	:= 185
	Local _nNumEtiq	:= 0
	Local lEtiqUnic	:= .F.

	// abre os parametros
	If ! Pergunte(_cPerg,.T.)
		Return( .F. )
	EndIf

	// tela para selecionar as impressoras de etiquetas disponiveis
	_oDlgSelImp := MSDialog():New(000,000,080,300,"Impressoras de etiquetas",,,.F.,,,,,,.T.,,,.T. )
	_oCBxTpEtiq := TComboBox():New( 004,004,{|u| If(PCount()>0,_cImpSelec:=u,_cImpSelec)},_aImpWindows,142,010,_oDlgSelImp,,,,,,.T.,,"",,,,,,,_cImpSelec )
	_oBtnEtqOk  := SButton():New( 018,100,1,{ || _lOk := .t. , _oDlgSelImp:End() },_oDlgSelImp,,"", )
	_oBtnEtqCan := SButton():New( 018,128,2,{ || _oDlgSelImp:End() },_oDlgSelImp,,"", )

	_oDlgSelImp:Activate(,,,.T.)

	//se confirmou no OK,  tipo de impressão é avulsa e produto
	If (_lOk .AND. ( (MV_PAR01 == 1 .AND. !Empty(MV_PAR02) .AND. !Empty(MV_PAR04)) .OR. (MV_PAR01 == 2 .AND. !Empty(MV_PAR06)) ))

		// grava informacoes da impressora selecionada
		U_FtImpZbr(_cImpSelec)

		// remove texto e mantem só o caminho
		_cImpSelec := Separa(_cImpSelec,"|")[2]
		// define o arquivo temporario com o conteudo da etiqueta
		_cTmpArquivo := _cPathTemp+"wms_etiq_produto_ean.txt"

		// cria e abre arquivo texto
		_nTmpHdl := fCreate(_cTmpArquivo)

		// testa se o arquivo de Saida foi Criado Corretamente
		If (_nTmpHdl == -1)
			// mensagem
			MsgAlert("O arquivo de nome " + _cTmpArquivo + " nao pode ser executado! Verifique os parametros.","Atencao!")
			// retorno
			Return( .F. )
		Endif

		// define tipos de etiquetas
		// {"Cad.Produto", "Sku Item", "Sku Caixa/Vol", "Sku Palete"}
		If (mv_par05 == 2) // 2-Sku Item
			_cOrigEtiq := "0"
		ElseIf (mv_par05 == 3) // 3-Sku Caixa/Vol
			_cOrigEtiq := "1"
		ElseIf (mv_par05 == 4) // 4-Sku Palete
			_cOrigEtiq := "9"
		EndIf

		// monta query para buscar os dados
		_cQryEtiq := " SELECT B1_CODCLI, "
		_cQryEtiq += "        " + IIf(mv_par05 == 1, "B1_CODBAR, B1_ZTPBAR, ", "Z32_CODBAR, Z32_ZTPBAR, ")
		_cQryEtiq += "        B1_DESC, B1_COD "
		_cQryEtiq += " FROM   " + RetSqlTab("SB1")
		If (mv_par05 != 1)
			_cQryEtiq += "        LEFT JOIN "+RetSqlTab("Z32")
			_cQryEtiq += "               ON "+RetSqlCond("Z32")
			_cQryEtiq += "                  AND Z32_CODPRO = B1_COD "
			_cQryEtiq += "                  AND Z32_TIPO = '" +_cOrigEtiq+ "' "
		EndIf
		_cQryEtiq += " WHERE  " + RetSqlCond("SB1")
		_cQryEtiq += "        AND B1_COD "
		If (mv_par01 = 1)      //etiqueta avulsa
			_cQryEtiq += " ='" + mv_par02 + "' "
		Elseif (mv_par01 = 2)  //por CESV
			_cQryEtiq += "IN ( SELECT Z04_PROD FROM " + RetSqlTab("Z04") + " WHERE " + RetSqlCond("Z04") + " AND Z04_CESV = '" + mv_par06 + "')"
		Endif

		memowrit("c:\query\TWMSR015.txt",_cQryEtiq)

		// jogo o conteudo da query para um array
		_aImpEtq := U_SqlToVet(_cQryEtiq)

		// valida se encontrou dados
		If (Len(_aImpEtq) == 0)
			// mensagem
			MsgStop("Não foram encontradas etiquetas para impressão.","Falha - TWMSR015A")
			// fecha arquivo texto
			fClose(_nTmpHdl)
			// retorno
			Return( .F. )
		EndIf

		// valida se encontrou mais que 1 código de barras
		If ( Len(_aImpEtq) > 1 )
			// mensagem
			MsgStop("Existe mais que um código de barras cadastrado para este produto, somente é permitido 1 código de barras por tipo de SKU. Verifique.","Falha - TWMSR015B")
			// fecha arquivo texto
			fClose(_nTmpHdl)
			// retorno
			Return( .F. )
		EndIf

		// Se não encontrou codigo de barras
		If (Empty(_aImpEtq[1][2]))
			// mensagem
			MsgStop("Não foi encontrado código de barras cadastrado para o produto em questão com esta origem. Verifique!","Falha - TWMSR015C")
			// fecha arquivo texto
			fClose(_nTmpHdl)
			// retorno
			Return( .F. )
		Endif

		// Se o tipo é DUN14, não já suporte AINDA
		If (_aImpEtq[1][3] == "4")
			// mensagem
			MsgStop("Não é possível imprimir códigos de barra do tipo DUN14. Sem suporte. Verifique!","Falha - TWMSR015D")
			// fecha arquivo texto
			fClose(_nTmpHdl)
			// retorno
			Return( .F. )
		Endif

		If (mv_par07 == 2)
			// valido o tipo da etiqueta
			If ( _aImpEtq[1][3] == "1" ) // 1=EAN13
				_cTpEtq := "BEB" // EAN13
				_lEan13 := .T.
			ElseIf ( _aImpEtq[1][3] == "2" ) // 2=UPC-A
				_cTpEtq := "BUN" // UPC-A
				_lUpc12 := .T.
			ElseIf ( (_aImpEtq[1][3] == "3") .OR. (Empty(_aImpEtq[1][3])) ) // 3=CODE128
				_cTpEtq := "BCB" // CODE128
				_lCod128 := .T.

			EndIf
			nIndice := 0 // indice usado para gerar o número de etiquetas
			If MV_PAR01 = 1 .And. !EMPTY(MV_PAR02) // se for Avulsa e informado Produto, trata a geração de etiquetas de
				_nNumEtiq	:= mv_par04 // numero de etiquetas a gerar
				nIndice		:= mv_par04 // indice para ser usado no For
				lEtiqUnic	:= .T. // flag para evitar erro log ao gerar etiqueta Avulsa e de Produtos
			Else
				_nNumEtiq	:= IIF(Empty(mv_par04),Len(_aImpEtq),mv_par04)  // numero de etiquetas a gerar
				nIndice		:= Len(_aImpEtq)  // indice para ser usado no For
			EndIf
			_cTmpEtiq		:= ""

			For _nReg := 1 TO nIndice Step 1

				// inicia montagem da etiqueta
				_cTmpEtiq += "CT~~CD,~CC^~CT~"+CRLF
				_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
				_cTmpEtiq += "^XA"+CRLF
				_cTmpEtiq += "^MMT"+CRLF
				_cTmpEtiq += "^PW900"+CRLF
				_cTmpEtiq += "^LL0350"+CRLF
				_cTmpEtiq += "^LS0"+CRLF

				// cordenadas da etiqueta
				nXTit	:= 55
				nXEan13	:= 145
				nXCode	:= 155

				_cTmpEtiq += "^FT"+Str(nXTit)+",320^A0B,25,31^FH\^FD" + AllTrim(_aImpEtq[IIF(lEtiqUnic,1,_nReg)][1]) + "^FS"+CRLF // B1_CODCLI
				If (_lEan13).or.(_lUpc12)
					_cTmpEtiq += "^BY3,3,80^FT"+Str(nXEan13)+",305^"+_cTpEtq+",,Y,N^FD>;" + AllTrim(_aImpEtq[IIF(lEtiqUnic,1,_nReg)][2]) + "^FS"+CRLF // B1_CODBAR
				ElseIf (_lCod128)
					_cTmpEtiq += "^BY3,3,90^FT"+Str(nXCode)+",320^"+_cTpEtq+",,Y,N^FD>;" + AllTrim(_aImpEtq[IIF(lEtiqUnic,1,_nReg)][2]) + "^FS"+CRLF // B1_CODBAR
				EndIf

				If _nReg >= _nNumEtiq
					//Fecha a etiqueta
					_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
					Exit
				EndIf
				// cordenadas da etiqueta
				nXTit	+= nXPEtiq
				nXEan13	+= nXPEtiq
				nXCode	+= nXPEtiq

				//Corpo da etiqueta
				_cTmpEtiq += "^FT"+Str(nXTit)+",320^A0B,25,31^FH\^FD" + AllTrim(_aImpEtq[IIF(lEtiqUnic,1,_nReg)][1]) + "^FS"+CRLF // B1_CODCLI
				If (_lEan13).or.(_lUpc12)
					_cTmpEtiq += "^BY3,3,80^FT"+Str(nXEan13)+",305^"+_cTpEtq+",,Y,N^FD>;" + AllTrim(_aImpEtq[IIF(lEtiqUnic,1,_nReg)][2]) + "^FS"+CRLF // B1_CODBAR
				ElseIf (_lCod128)
					_cTmpEtiq += "^BY3,3,90^FT"+Str(nXCode)+",320^"+_cTpEtq+",,Y,N^FD>;" + AllTrim(_aImpEtq[IIF(lEtiqUnic,1,_nReg)][2]) + "^FS"+CRLF // B1_CODBAR
				EndIf

				If _nReg+1 <= _nNumEtiq
					_nReg++
				EndIf
				If _nReg >= _nNumEtiq
					//Fecha a etiqueta
					_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
					Exit
				EndIf
				// cordenadas da etiqueta
				nXTit	+= nXPEtiq
				nXEan13	+= nXPEtiq
				nXCode	+= nXPEtiq

				//Corpo da etiqueta
				_cTmpEtiq += "^FT"+Str(nXTit)+",320^A0B,25,31^FH\^FD" + AllTrim(_aImpEtq[IIF(lEtiqUnic,1,_nReg)][1]) + "^FS"+CRLF // B1_CODCLI
				If (_lEan13).or.(_lUpc12)
					_cTmpEtiq += "^BY3,3,80^FT"+Str(nXEan13)+",305^"+_cTpEtq+",,Y,N^FD>;" + AllTrim(_aImpEtq[IIF(lEtiqUnic,1,_nReg)][2]) + "^FS"+CRLF // B1_CODBAR
				ElseIf (_lCod128)
					_cTmpEtiq += "^BY3,3,90^FT"+Str(nXCode)+",320^"+_cTpEtq+",,Y,N^FD>;" + AllTrim(_aImpEtq[IIF(lEtiqUnic,1,_nReg)][2]) + "^FS"+CRLF // B1_CODBAR
				EndIf

				If _nReg+1 <= _nNumEtiq
					_nReg++
				EndIf
				If _nReg >= _nNumEtiq
					//Fecha a etiqueta
					_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
					Exit
				EndIf
				// cordenadas da etiqueta
				nXTit	+= nXPEtiq
				nXEan13	+= nXPEtiq
				nXCode	+= nXPEtiq

				//Corpo da etiqueta
				_cTmpEtiq += "^FT"+Str(nXTit)+",320^A0B,25,31^FH\^FD" + AllTrim(_aImpEtq[IIF(lEtiqUnic,1,_nReg)][1]) + "^FS"+CRLF // B1_CODCLI
				If (_lEan13).or.(_lUpc12)
					_cTmpEtiq += "^BY3,3,80^FT"+Str(nXEan13)+",305^"+_cTpEtq+",,Y,N^FD>;" + AllTrim(_aImpEtq[IIF(lEtiqUnic,1,_nReg)][2]) + "^FS"+CRLF // B1_CODBAR
				ElseIf (_lCod128)
					_cTmpEtiq += "^BY3,3,90^FT"+Str(nXCode)+",320^"+_cTpEtq+",,Y,N^FD>;" + AllTrim(_aImpEtq[IIF(lEtiqUnic,1,_nReg)][2]) + "^FS"+CRLF // B1_CODBAR
				EndIf

				If _nReg+1 <= _nNumEtiq
					_nReg++
				EndIf

				_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF

			Next _nReg
		Elseif (mv_par07 == 1)
			// valido o tipo da etiqueta
			If ( _aImpEtq[1][3] == "1" ) // 1=EAN13
				_cTpEtq := "BEN" // EAN13
				_lEan13 := .T.
			ElseIf ( _aImpEtq[1][3] == "2" ) // 2=UPC-A
				_cTpEtq := "BUN" // UPC-A
				_lUpc12 := .T.
			ElseIf ( (_aImpEtq[1][3] == "3").or.(Empty(_aImpEtq[1][3])) ) // 3=CODE128
				_cTpEtq := "BCN" // CODE128
				_lCod128 := .T.
			EndIf

			//itera sobre as etiquetas
			For _nReg := 1 TO Len(_aImpEtq) Step 1

				// inicia montagem da etiqueta
				_cTmpEtiq := "CT~~CD,~CC^~CT~"+CRLF
				_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
				_cTmpEtiq += "^XA"+CRLF
				_cTmpEtiq += "^MMT"+CRLF
				_cTmpEtiq += "^PW759"+CRLF
				_cTmpEtiq += "^LL0440"+CRLF
				_cTmpEtiq += "^LS0"+CRLF
				//_cTmpEtiq += "^FT89,86^A0N,39,38^FH\^FD" + AllTrim(_aImpEtq[_nReg][4]) + "^FS"+CRLF // B1_DESC
				//_cTmpEtiq += "^FT275,144^A0N,39,38^FH\^FD" + AllTrim(_aImpEtq[_nReg][1]) + "^FS"+CRLF // B1_CODCLI
				_cTmpEtiq += "^FO50,30^A0N,30,30^TBN,800,200^FD"+ AllTrim(_aImpEtq[_nReg][1]) + " - " + AllTrim(_aImpEtq[_nReg][4]) +"^FS"
				If (_lEan13).or.(_lUpc12)
					_cTmpEtiq += "^BY3,4,130^FT50,200^" + _cTpEtq + ",,Y,N"+CRLF
					_cTmpEtiq += "^FD" + AllTrim(_aImpEtq[_nReg][2]) + "^FS"+CRLF // B1_CODBAR
				ElseIf (_lCod128)
					_cTmpEtiq += "^BY3,4,130^FT50,200^" + _cTpEtq + ",,Y,N"+CRLF
					_cTmpEtiq += "^FD>:" + AllTrim(_aImpEtq[_nReg][2]) + "^FS"+CRLF // B1_CODBAR
				EndIf

				//Quantidade de etiquetas a imprimir
				If (mv_par01 = 1)      //por etiqueta avulsa
					_cTmpEtiq += "^PQ" + AllTrim(Str(mv_par04)) + ",0,1,Y^XZ" + CRLF // QUANTIDADE DIGITADA
				Elseif (mv_par01 = 2)  //por CESV
					//verifica qual quantidade se basear para imprimir as etiquetas pelo CESV
					_cQry := "SELECT " + IIf (mv_par03 = 1, "Z04_QUANT", "Z04_QTSEGU")
					_cQry += " FROM " + RETSQLTAB("Z04")
					_cQry += " WHERE Z04_CESV = '" + MV_PAR06 + "'"
					_cQry += " AND Z04_PROD = '" + _AIMPETQ[_NREG][5] + "'"
					_cQry += " AND " + RETSQLCOND("Z04")

					_nQtd := U_FTQuery(_cQry)

					_cTmpEtiq += "^PQ" + Str(_nQtd) + ",0,1,Y^XZ" + CRLF // qtd 2ª UM
				EndIf
			Next _nReg
		Endif
		// grava a Linha no Arquivo Texto
		fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

		// fecha arquivo texto
		fClose(_nTmpHdl)

		// define o arquivo .BAT para execucao da impressao da etiqueta
		_cTmpBat := _cPathTemp + "wms_imp_etiq.bat"

		// grava o arquivo .BAT
		MemoWrit( _cTmpBat,"copy " + _cTmpArquivo + " " + _cImpSelec )

		// executa o comando (.BAT) para impressao
		WinExec(_cTmpBat)

	EndIf

Return( .T. )