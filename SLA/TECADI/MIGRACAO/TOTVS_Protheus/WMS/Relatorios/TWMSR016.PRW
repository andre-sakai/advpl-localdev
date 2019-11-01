#Include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para impressao de etiquetas do WMS               !
!                  ! - Packing                                               !
+------------------+---------------------------------------------------------+
!Autor             ! David                       ! Data de Criação ! 03/2015 !
+------------------+--------------------------------------------------------*/

// ** função principal a ser chamada a partir da tela de Impressão de Etiquetas
User Function TWMSR016()

	// perguntas
	local _cPerg := PadR("TWMSR016",10)
	local _aPerg := {}

	// monta a lista de perguntas
	aAdd(_aPerg,{"CESV:"              , "C", TamSx3("ZZ_CESV")[1]   ,0,"G",,"SZZ"}) //mv_par01
	aAdd(_aPerg,{"Volumes De:"        , "C", TamSx3("Z07_ETQVOL")[1],0,"G",,""   }) //mv_par02
	aAdd(_aPerg,{"Volumes Até:"       , "C", TamSx3("Z07_ETQVOL")[1],0,"G",,""   }) //mv_par03
	aAdd(_aPerg,{"Pedido:"            , "C", TamSx3("C9_PEDIDO")[1] ,0,"G",,""   }) //mv_par04
	aAdd(_aPerg,{"Carga:"             , "C", TamSx3("Z05_CARGA")[1] ,0,"G",,""   }) //mv_par05
	aAdd(_aPerg,{"Agrupadora:"        , "C", TamSx3("C5_ZAGRUPA")[1],0,"G",,""   }) //mv_par06
	aAdd(_aPerg,{"Ped.Cliente:"       , "C", TamSx3("C5_ZPEDCLI")[1],0,"G",,""   }) //mv_par07
	aAdd(_aPerg,{"NF Venda (Cliente):", "C", TamSx3("C5_ZDOCCLI")[1],0,"G",,""   }) //mv_par08
	aAdd(_aPerg,{"Cliente:"           , "C", TamSx3("C5_CLIENTE")[1],0,"G",,"SA1"}) //mv_par09
	aAdd(_aPerg,{"Onda de Separação:" , "C", TamSx3("Z57_CODIGO")[1],0,"G",,""   }) //mv_par10
	aAdd(_aPerg,{"Qtd etiq (manual):" , "N", 3                      ,0,"G",,""   }) //mv_par11

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// abre os parametros
	If ! Pergunte(_cPerg,.T.)
		Return(.f.)
	EndIf

	// chama a função de processamento
	U_WMSR016A(mv_par01, mv_par02, mv_par03, mv_par04, mv_par05, mv_par06, mv_par07, mv_par08, mv_par09, mv_par10, mv_par11)


Return(.t.)

// ** função que pode ser chamada de qualquer tela para impressão de etiquetas
User Function WMSR016A(mvCesv, mvVolDe, mvVolAte, mvPed, mvCarga, mvAgru, mvPedCli, mvNfCli, mvCodCli, mvNrOndSep, mvQtdEtq)

	// variavel de retorno
	local _lRet := .f.
	// objetos
	local _oDlgSelImp, _oCBxTpEtiq, _oBtnEtqOk, _oBtnEtqCan
	// impressoras disponiveis no windows
	local _aImpWindows := U_FtRetImp()
	// arquivos temporarios
	local _cTmpArquivo := ""
	local _cTmpBat     := ""
	local _nTmpHdl
	// retorna a pasta temporaria da maquina
	local _cPathTemp := AllTrim(GetTempPath())
	local _cTmpEtiq := "" // arquivo para criação da etiqueta
	// quantidade de etiquetas
	local _nQtdTotal := 0
	// codigo da etiqueta
	local _cCodEtiq := ""
	// impressora selecionada
	local _cImpSelec := U_FtImpZbr()
	// query que vai retornar os registros de volumes para o packing
	local _cQryVol := ""
	// array que vai receber os dados
	local _aVolToImp := ""
	// controle de laço
	local _nX := 0
	// valida o arquivo gerado
	local _lImpressOk := .f.
	// quantidade de produto por etiqueta
	local _nProdEtiq := 1
	// linha do item (quando o volume possui mais de 1 item)
	local _nItem := 1
	// controle de impressao
	local _cEtqVolAtu := ""

	// controle se permite emitir etiquetas sem nota fiscal de retorno do Tecadi
	local _lEtqSemNfRet := U_FtWmsParam("WMS_EXPEDICAO_ETIQUETA_PACKING_SEM_NF_TECADI", "L", .F., .F. , "", mvCodCli, "", "", Nil)

	// permite imprimir o packing mesmo sem nota fiscal do cliente informada/importada
	local _lSemNFCli := U_FtWmsParam("WMS_EXPEDICAO_ETIQUETA_PACKING_SEM_NF_CLIENTE", "L", .F., .F., "", mvCodCli, "", "", Nil)

	//layout da etiqueta de packing do cliente
	//01 - etiqueta com codigo de barras EAN + SKU em destaque + descricao do item / limite de cerca de 5 itens impressos
	//02 - etiqueta com SKU + descricao (sem destaque) / limite de cerca de 30 itens impressos na etiqueta
	//03 - etiqueta apenas do cabeçalho
	local _cLayout := U_FtWmsParam("WMS_EXPEDICAO_ETQ_PACKING_LAYOUT_PADRAO", "C", "01", .f. , "", mvCodCli, "", Nil, Nil)

	// dados para impressao da etiqueta
	private _cInfoEtq := ""

	// valida codigo do cliente
	If (Empty(mvCodCli))
		MsgAlert("Favor informar o código do cliente")
		Return(.f.)
	EndIf

	// tela para selecionar as impressoras de etiquetas disponiveis
	_oDlgSelImp := MSDialog():New(000,000,080,300,"Impressoras de etiquetas",,,.F.,,,,,,.T.,,,.T. )
	_oCBxTpEtiq := TComboBox():New( 004,004,{|u| If(PCount()>0,_cImpSelec:=u,_cImpSelec)},_aImpWindows,142,010,_oDlgSelImp,,,,,,.T.,,"",,,,,,,_cImpSelec )
	_oBtnEtqOk  := SButton():New( 018,100,1,{ || _lRet := .t. , _oDlgSelImp:End() },_oDlgSelImp,,"", )
	_oBtnEtqCan := SButton():New( 018,128,2,{ || _oDlgSelImp:End() },_oDlgSelImp,,"", )

	_oDlgSelImp:Activate(,,,.T.)

	// se alguma impressora foi selecionada continua
	If (_lRet)

		// grava informacoes da impressora selecionada
		U_FtImpZbr(_cImpSelec)

		// remove texto e mantem só o caminho
		_cImpSelec := Separa(_cImpSelec,"|")[2]
		// define o arquivo temporario com o conteudo da etiqueta
		_cTmpArquivo := _cPathTemp+"wms_etiq_packing.txt"

		// cria e abre arquivo texto
		_nTmpHdl := fCreate(_cTmpArquivo)
		// testa se o arquivo de Saida foi Criado Corretamente
		If (_nTmpHdl == -1)
			MsgAlert("O arquivo de nome "+_cTmpArquivo+" nao pode ser executado! Verifique os parametros.","Atencao!")
			Return(.f.)
		Endif

		// query que receberá os parâmetros para consulta - TODOS os parametros passam por ela
		_cQryVol := " SELECT "
		_cQryVol += "	   C5_ZPEDCLI, "
		_cQryVol += "	   Z07_ETQVOL,   "
		_cQryVol += "      Z07_CODBAR,   "
		_cQryVol += "      CAST(SUM(Z07_QUANT) AS VARCHAR) + ' ' + B1_UM Z07_QUANT, "
		_cQryVol += "      C5_ZCLIENT,   "
		_cQryVol += "      C5_ZENDENT,   "
		_cQryVol += "      C5_ZCIDENT,   "
		_cQryVol += "      C5_ZUFENTR,   "
		_cQryVol += "      C5_ZDOCCLI, "
		_cQryVol += "      B1_CODCLI, "
		_cQryVol += "      B1_DESC, "
		_cQryVol += "      Z11_QTD1, "
		_cQryVol += "      Z11_QTD2, "
		_cQryVol += "	   Z07_NUMOS, "
		_cQryVol += "	   Z07_PEDIDO "
		// itens conferidos
		_cQryVol += " FROM "+RetSqlName("Z07")+" Z07 (NOLOCK)  "
		// ord. servico
		_cQryVol += " INNER JOIN "+RetSqlName("Z05")+" Z05 (NOLOCK) ON Z05_NUMOS = Z07_NUMOS AND "+RetSqlCond("Z05")
		// CESV
		If (!Empty(mvCesv))
			_cQryVol += " AND Z05_CESV = '"+mvCesv+"'"
		EndIf
		// CARGA
		If (!Empty(mvCarga))
			_cQryVol += " AND Z05_CARGA = '"+mvCarga+"'"
		EndIf
		// ONDA DE SEPARACAO
		If ( ! Empty(mvNrOndSep) )
			_cQryVol += " AND Z05_ONDSEP = '" + mvNrOndSep + "'"
		EndIf
		// ord. servico
		_cQryVol += " INNER JOIN "+RetSqlTab("Z06")+" (NOLOCK) ON Z06_NUMOS = Z05_NUMOS AND Z06_SEQOS = Z07_SEQOS AND "+RetSqlCond("Z06")
		// somente finalizada
		If ( ! _lEtqSemNfRet )
			_cQryVol += " AND Z06_STATUS = 'FI' "
		EndIf
		// somente tarefa de Montagem de Volumes
		_cQryVol += " AND Z06_TAREFA = '007' "
		// pedido de venda
		_cQryVol += " INNER JOIN "+RetSqlTab("SC5")+" (NOLOCK) ON C5_NUM = Z07_PEDIDO AND "+RetSqlCond("SC5")
		// somente pedido faturado
		If ( ! _lEtqSemNfRet )
			_cQryVol += " AND C5_NOTA != ' ' "
		EndIf
		// somente com nota fiscal de venda do cliente
		If ( ! _lSemNFCli )
			_cQryVol += " AND C5_ZDOCCLI != ' ' "
		EndIf
		// somente quando os volumes já foram conferidos/montados
		_cQryVol += " AND C5_ZMNTVOL = 'S' "
		// AGRUPADORA
		If ( ! Empty(mvAgru))
			_cQryVol += " AND C5_ZAGRUPA = '"+mvAgru+"' "
		EndIf
		// PEDIDO DO CLIENTE
		If ( ! Empty(mvPedCli))
			_cQryVol += " AND C5_ZPEDCLI = '"+mvPedCli+"' "
		EndIf
		// NOTA VENDA DO CLIENTE
		If ( ! Empty(mvNfCli))
			_cQryVol += " AND C5_ZDOCCLI = '"+mvNfCli+"' "
		EndIf
		//apenas do cliente informado
		_cQryVol += " AND C5_CLIENTE = '" + mvCodCli + "' "
		// cad. produtos
		_cQryVol += " INNER JOIN "+RetSqlTab("SB1")+" (NOLOCK) ON B1_COD = Z07_PRODUT AND "+RetSqlCond("SB1")
		// cad. etiquetas
		_cQryVol += " INNER JOIN "+RetSqlTab("Z11")+" (NOLOCK) ON Z11_CODETI = Z07_ETQVOL AND "+RetSqlCond("Z11")
		// filtro padrao
		_cQryVol += " WHERE "+RetSqlCond("Z07")
		// nr pedido
		If ( ! Empty(mvPed) )
			_cQryVol += " AND Z07_PEDIDO = '"+mvPed+"' "
		EndIf
		// etiquetas de volume
		_cQryVol += " AND Z07_ETQVOL BETWEEN '"+mvVolDe+"' AND '"+mvVolAte+"' "
		// status F=Finalizado
		_cQryVol += " AND Z07_STATUS = 'F' "
		// ordeno pelo número do volume e agrupo
		_cQryVol += " GROUP BY Z07_NUMOS, Z07_PEDIDO, Z07_ETQVOL, Z07_CODBAR, C5_ZCLIENT, C5_ZENDENT, C5_ZCIDENT, C5_ZUFENTR, C5_ZDOCCLI, C5_ZPEDCLI, B1_CODCLI, B1_DESC, B1_UM, Z11_QTD1, Z11_QTD2  "
		// ordem dos dados
		_cQryVol += " ORDER BY Z07_NUMOS, Z07_PEDIDO, Z07_ETQVOL "

		memowrit("C:\query\twmsr016.txt",_cQryVol)

		// executo a query e jogo dentro de um array
		_aVolToImp := U_SqlToVet(_cQryVol)

		// calculo da quantidade total de etiquetas a imprimir
		_nQtdTotal := Len(_aVolToImp)

		// se não trouxe nada na query é que os parâmetros estão errados
		If (_nQtdTotal == 0)
			// fecha arquivo texto
			fClose(_nTmpHdl)
			// mensagem
			U_FtWmsMsg("Não foram encontrados etiquetas para os parâmetros informados. Verifique!")
			// retorno da funcao
			Return(.f.)
		EndIf

		// quantidade total da regua de prcessamento
		ProcRegua(_nQtdTotal)

		// se não for o layout apenas cabeçalho, gera etiqueta completa
		If ( _cLayout != "03" ) 

			// varro todos os registros para salvar criar as etiquetas
			For _nX := 1 to _nQtdTotal

				// valida se deve gerar um novo cabecalho, caso seja uma nova etiqueta de volume
				If (_cEtqVolAtu != _aVolToImp[_nX][2])

					// verifica necessidade de gerar o rodape por etiqueta
					If ( ! Empty(_cEtqVolAtu))
						// funcao que gera o rodape da etiqueta
						_cTmpEtiq := sfRetRodape()
						// grava a Linha no Arquivo Texto
						fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))
					EndIf

					// funcao para gerar o cabecalho
					_cTmpEtiq := sfRetCabec(_aVolToImp[_nX][2], ;
					_aVolToImp[_nX][1]    ,;
					cValToChar(_aVolToImp[_nX][12]) + "/" + cValToChar(_aVolToImp[_nX][13]), ;
					_aVolToImp[_nX][5]    ,;
					_aVolToImp[_nX][6]    ,;
					_aVolToImp[_nX][7] + "/" + _aVolToImp[_nX][8], ;
					Nil                   ,;
					Nil                   ,;
					_aVolToImp[_nX][9]     )

					// grava a Linha no Arquivo Texto
					fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

					// controle de etiqueta
					_cEtqVolAtu := _aVolToImp[_nX][2]

					// reinicia contador de produto por etiqueta
					_nProdEtiq := 1

					// reinicia item / linha do item
					_nItem := 1
				EndIf

				If ( _cLayout == "01" )           // layout 1 - com código de barras
					_cTmpEtiq := sfRetCodBar(_aVolToImp[_nX][10],;   //1 - B1_CODCLI
					AllTrim(_aVolToImp[_nX][ 3]) ,;                  //2 - Z07_CODBAR
					AllTrim(_aVolToImp[_nX][11]) ,;                  //3 - B1_DESC
					@_nProdEtiq                  ,;                  //4 - quantidade de codigos a imprimir
					_aVolToImp[_nX][4]           ,;                  //5 - Z07_QUANT
					_aVolToImp[_nX][2]            )                  //6 - Z07_ETQVOL
				Elseif ( _cLayout == "02" )       // layout 2 - apenas SKU e descrição
					_cTmpEtiq := sfProduto(_aVolToImp[_nX][10],;     //1 - B1_CODCLI
					AllTrim(_aVolToImp[_nX][11]),;                   //2 - B1_DESC
					@_nItem                     ,;                   //3 - item atual / linha
					_aVolToImp[_nX][4])                              //4 - Z07_QUANT
				EndIf

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

				// controle da impressão
				_lImpressOk := .t.

			Next _nX

		Else  // gera apenas cabeçalho

			_nQtdTotal := mvQtdEtq
			For _nX := 1 to _nQtdTotal

				_cTmpEtiq := sfRetCabec(0, ;
				_aVolToImp[1][1]    ,;
				cValToChar(_nX) + "/" + cValToChar(_nQtdTotal), ;
				_aVolToImp[1][5]    ,;
				_aVolToImp[1][6]    ,;
				_aVolToImp[1][7] + "/" + _aVolToImp[1][8], ;
				Nil                   ,;
				Nil                   ,;
				_aVolToImp[1][9]     )

				// grava a etiqueta no Arquivo Texto
				fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

				// funcao que gera o rodape da etiqueta
				_cTmpEtiq := sfRetRodape()

				// grava o rodapé no Arquivo Texto
				fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

				// controle da impressão
				_lImpressOk := .t.

			Next _nX

		EndIf

		If ( _cLayout != "03" ) // caso não seja o layout apenas cabeçalho, precisa imprimir a última etiqueta 
			// funcao que gera o rodape da etiqueta
			_cTmpEtiq := sfRetRodape()
			// grava a Linha no Arquivo Texto
			fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))
		EndIf
		// fecha arquivo texto
		fClose(_nTmpHdl)

		// define o arquivo .BAT para execucao da impressao da etiqueta
		_cTmpBat := _cPathTemp+"wms_imp_etiq.bat"

		// grava o arquivo .BAT
		MemoWrit(_cTmpBat,"copy "+_cTmpArquivo+" "+_cImpSelec)

		// executa o comando (.BAT) para impressao
		If (_lImpressOk)
			WinExec(_cTmpBat)
			Sleep(1000)
		EndIf

		// reseta a info de impressões
		_lImpressOk := .f.

	EndIf

Return (_lRet)

// ** retorna o cabeçalho da etiqueta
Static Function sfRetCabec(mvVol, mvPedCli, mvSeq, mvDestName, mvDestEnd, mvDestCidUF, mvCep, mvTel, mvNf)

	// retorno
	local _cCabEtq  := ""
	// volume
	local _cVolume  := ""
	// sequencia
	local _cSeq     := ""
	// destinatário da carga
	local _cDest    := ""
	// nota fiscal
	local _cNota    := ""
	// pedido do cliente
	local _cPedCli := ""

	// info da etiq preenche só uma vez
	If ( Empty(_cInfoEtq) )
		// dados da etiqueta - info
		_cInfoEtq := "CT~~CD,~CC^~CT~"+CRLF
		_cInfoEtq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
		_cInfoEtq += "^XA"+CRLF

		_cCabEtq += _cInfoEtq
	EndIf

	// cabecalho indispensável para etiqueta
	_cPedCli += "^MMT"+CRLF
	_cPedCli += "^PW799"+CRLF
	_cPedCli += "^LL1047"+CRLF
	_cPedCli += "^LS0"+CRLF

	// pedido do cliente
	_cPedCli += "^FT89,40^A0N,20,19^FH\^FDPedido: ^FS"+CRLF
	_cPedCli += "^FT114,83^A0N,45,45^FH\^FD" + SubString(AllTrim(mvPedCli),1,15) + "^FS"+CRLF

	// volume
	_cVolume := "^FT35,248^A0B,20,19^FH\^FDVolume: ^FS"+CRLF
	_cVolume += "^FT70,215^A0B,28,28^FH\^FD"+ TRANSFORM(AllTrim(mvVol), PesqPict("Z11", "Z11_CODETI")) + "^FS"+CRLF

	// sequencia
	_cSeq := "^FT480,27^A0N,20,19^FH\^FDSequ\88ncia:^FS"+CRLF
	_cSeq += "^FT519,83^A0N,45,45^FH\^FD" + AllTrim(mvSeq) + "^FS"+CRLF

	// destinatário da carga
	_cDest := "^FT89,109^A0N,20,19^FH\^FDDestinat\A0rio:^FS"+CRLF
	_cDest += "^FT89,130^A0N,23,22^FH\^FD"+ MemoLine(AllTrim(mvDestName),33,1)+"^FS"+CRLF
	_cDest += "^FT89,151^A0N,23,22^FH\^FD"+ MemoLine(AllTrim(mvDestName),33,2)+"^FS"+CRLF
	_cDest += "^FT89,179^A0N,23,22^FH\^FD"+ MemoLine(AllTrim(mvDestEnd),33,1)+"^FS"+CRLF
	_cDest += "^FT89,207^A0N,23,22^FH\^FD"+ MemoLine(AllTrim(mvDestEnd),33,2)+"^FS"+CRLF
	_cDest += "^FT89,235^A0N,23,22^FH\^FD"+ SubString(AllTrim(mvDestCidUf),1,33)+"^FS"+CRLF
	//_cDest += "^FT95,235^A0N,23,22^FH\^FD"+ AllTrim(mvCep)+"^FS"+CRLF //Comentado, pois está sendo passado Nil como valor fixo
	_cDest += "^FT89,259^A0N,23,22^FH\^FDTel.:^FS"+CRLF

	// nota fiscal
	_cNota := "^FT480,111^A0N,20,19^FH\^FDNota Fiscal: ^FS"+CRLF
	_cNota += "^FT480,206^A0N,80,60^FH\^FD" + AllTrim(mvNf) + "^FS"+CRLF

	// junta tudo pra retornar os dados do cabeçalho
	_cCabEtq += _cPedCli + _cVolume + _cSeq + _cDest + _cNota

Return (_cCabEtq)

// ** função que retorna o rodapé da etiqueta
Static Function sfRetRodape ()

	// rodape
	local _cRodape := ""

	// dados da etiqueta - rodapé
	_cRodape := "^FO80,12^GB0,256,4^FS"+CRLF
	_cRodape += "^FO9,11^GB0,257,2^FS"+CRLF
	_cRodape += "^FO8,6^GB780,0,4^FS"+CRLF
	_cRodape += "^FO470,11^GB0,257,3^FS"+CRLF
	_cRodape += "^FO82,89^GB707,0,3^FS"+CRLF
	_cRodape += "^FO790,10^GB0,257,2^FS"+CRLF
	_cRodape += "^FO8,268^GB784,0,2^FS"+CRLF
	_cRodape += "^PQ1,0,1,Y^XZ"+CRLF
	_cRodape += "^XA"+CRLF

Return (_cRodape)

// ** função que retorna o contéudo da etiqueta para layout 1 (com código de barras)
Static Function sfRetCodBar(mvCodPro, mvCodBar, mvDesc, mvQtdImp, mvQtd, mvVol)

	// retorno
	local _cCodBarras := ""
	// quebra descrição
	local _aDesc      := QbTexto(AllTrim(mvDesc) ,30," ")
	local _cDesc1     := ""
	local _cDesc2     := ""
	local _cDesc3     := ""
	local _cTpEtq     := ""

	// valido o length pra não dar erro no array
	If (Len(_aDesc) >= 1)
		_cDesc1 := _aDesc[1]
	EndIf
	If (Len(_aDesc) >= 2)
		_cDesc2 := _aDesc[2]
	EndIf
	If (Len(_aDesc) >= 3)
		_cDesc3 := _aDesc[3]
	EndIf

	// valido o tipo da etiqueta, para os casos de EAN13 e UPC-A
	If ( Len(ALLTRIM(mvCodBar)) == 13 )
		_cTpEtq := "BEN" // EAN13
	ElseIf ( Len(ALLTRIM(mvCodBar)) == 12 )
		_cTpEtq := "BUN" // UPC-A
	EndIf

	// primeiro código de barras, olhando a etiqueta de cima pra baixo
	If (mvQtdImp == 1)
		_cCodBarras := "^BY4,2,121^FT47,409^"+_cTpEtq+",,Y,N"+CRLF
		_cCodBarras += "^FD"+mvCodBar+"^FS"+CRLF
		_cCodBarras += "^FT451,342^A0N,20,19^FH\^FD"+_cDesc1+"^FS"+CRLF
		_cCodBarras += "^FT449,368^A0N,20,19^FH\^FD"+_cDesc2+"^FS"+CRLF
		_cCodBarras += "^FT449,394^A0N,20,19^FH\^FD"+_cDesc3+"^FS"+CRLF
		_cCodBarras += "^FT449,314^A0N,34,33^FH\^FD"+AllTrim(mvCodPro)+" - "+AllTrim(cValToChar(mvQtd))+"^FS"+CRLF

		// segundo código de barras, olhando a etiqueta de cima pra baixo
	ElseIf (mvQtdImp == 2)
		_cCodBarras := "^BY4,2,121^FT46,565^"+_cTpEtq+",,Y,N"+CRLF
		_cCodBarras += "^FD"+mvCodBar+"^FS"+CRLF
		_cCodBarras += "^FT451,498^A0N,20,19^FH\^FD"+_cDesc1+"^FS"+CRLF
		_cCodBarras += "^FT448,524^A0N,20,19^FH\^FD"+_cDesc2+"^FS"+CRLF
		_cCodBarras += "^FT448,550^A0N,20,19^FH\^FD"+_cDesc3+"^FS"+CRLF
		_cCodBarras += "^FT448,470^A0N,34,33^FH\^FD"+AllTrim(mvCodPro)+" - "+AllTrim(cValToChar(mvQtd))+"^FS"+CRLF

		// terceiro código de barras, olhando a etiqueta de cima pra baixo
	ElseIf (mvQtdImp == 3)
		_cCodBarras := "^BY4,2,121^FT46,717^"+_cTpEtq+",,Y,N"+CRLF
		_cCodBarras += "^FD"+mvCodBar+"^FS"+CRLF
		_cCodBarras += "^FT451,650^A0N,20,19^FH\^FD"+_cDesc1+"^FS"+CRLF
		_cCodBarras += "^FT448,676^A0N,20,19^FH\^FD"+_cDesc2+"^FS"+CRLF
		_cCodBarras += "^FT448,702^A0N,20,19^FH\^FD"+_cDesc3+"^FS"+CRLF
		_cCodBarras += "^FT448,625^A0N,34,33^FH\^FD"+AllTrim(mvCodPro)+" - "+AllTrim(cValToChar(mvQtd))+"^FS"+CRLF

		// quarto código de barras, olhando a etiqueta de cima pra baixo
	ElseIf (mvQtdImp == 4)
		_cCodBarras := "^BY4,2,121^FT46,869^"+_cTpEtq+",,Y,N"+CRLF
		_cCodBarras += "^FD"+mvCodBar+"^FS"+CRLF
		_cCodBarras += "^FT451,802^A0N,20,19^FH\^FD"+_cDesc1+"^FS"+CRLF
		_cCodBarras += "^FT448,828^A0N,20,19^FH\^FD"+_cDesc2+"^FS"+CRLF
		_cCodBarras += "^FT448,854^A0N,20,19^FH\^FD"+_cDesc3+"^FS"+CRLF
		_cCodBarras += "^FT448,773^A0N,34,33^FH\^FD"+AllTrim(mvCodPro)+" - "+AllTrim(cValToChar(mvQtd))+"^FS"+CRLF

		// quarto código de barras, olhando a etiqueta de cima pra baixo
	ElseIf (mvQtdImp == 5)
		_cCodBarras := "^BY4,2,121^FT46,1022^"+_cTpEtq+",,Y,N"+CRLF
		_cCodBarras += "^FD"+mvCodBar+"^FS"+CRLF
		_cCodBarras += "^FT451,955^A0N,20,19^FH\^FD"+_cDesc1+"^FS"+CRLF
		_cCodBarras += "^FT448,981^A0N,20,19^FH\^FD"+_cDesc2+"^FS"+CRLF
		_cCodBarras += "^FT448,1007^A0N,20,19^FH\^FD"+_cDesc3+"^FS"+CRLF
		_cCodBarras += "^FT448,926^A0N,34,33^FH\^FD"+AllTrim(mvCodPro)+" - "+AllTrim(cValToChar(mvQtd))+"^FS"+CRLF

	EndIf

	//quantidade de impressões
	mvQtdImp ++

Return (_cCodBarras)

// ** função que retorna o conteudo da etiqueta para layout 2 (SKU + descricao)
Static Function sfProduto(mvCodPro, mvDesc, mvItem, mvQuant)

	// retorno
	local _cRetorno := ""

	//pulo de linha
	local _nPulo := 25
	//linha inicial
	local _nLinhaIni := 320
	//linha para imprimir
	local _nLin := (mvItem * _nPulo) + _nLinhaIni

	//monta a linha
	If (mvItem == 1) //se for o primeiro item, então escrevo o rótulo também
		_cRetorno := "^FT10,310^A0N,30,30^FH\^FDConteudo do volume: ^FS" + CRLF
		_cRetorno += "^FT10," + AllTrim(Str(_nLin)) + "^A0N,25,25^FH\^FD" + AllTrim(StrZero(mvItem,2)) + " - "+ AllTrim(mvCodPro) + " - " + AllTrim(mvDesc) + " -- "  + AllTrim(mvQuant) + "^FS" + CRLF
	Else
		_cRetorno := "^FT10," + AllTrim(Str(_nLin)) + "^A0N,25,25^FH\^FD" + AllTrim(StrZero(mvItem,2)) + " - "+ AllTrim(mvCodPro) + " - " + AllTrim(mvDesc) + " -- "  + AllTrim(mvQuant) + "^FS" + CRLF
	Endif

	//incrementa sequência do itemitem
	mvItem++

Return (_cRetorno)