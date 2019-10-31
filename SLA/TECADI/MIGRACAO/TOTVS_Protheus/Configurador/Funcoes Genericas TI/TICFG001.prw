#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!     *********  FUNCAO DE USO RESTRITA DO DEPARTAMENTO DE TI  *********     !
+------------------+---------------------------------------------------------+
!Descricao         ! Movimentar em massa de mercadorias entre enderecos      !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 07/2017 !
+------------------+--------------------------------------------------------*/

User Function TICFG001()

	// dimensoes da tela
	local _aSizeDlg	:= MsAdvSize()

	// objetos
	local _oWndMovPlt
	local _oPnlBtnOpr, _oPnlBrwSC6
	local _oBrwSC6, _oBrwMovPlt
	local _oBtnConfInt, _oBtnImpPla, _oBtnFechar
	local _oSayEndDes, _oGetEndDes

	// estrutura do arquivo de trabalho e Browse - Itens PV
	local _cQrySC6
	Local _aStruSC6 := {}
	Local _aHeadSC6 := {}
	Local _cTrbSC6  := ""

	// estrutura do arquivo de trabalho e Browse - Movimentacao de Paletes
	local _cQryMov
	Local _aStruMov := {}
	Local _aHeadMov := {}

	// fontes utilizadas
	private _oFnt01 := TFont():New("Tahoma",,18,,.t.)

	// tabela temporaria
	private _cTrbMov
	private _TRBMOV := GetNextAlias()

	// -- monta o arquivo de trabalho - movimentacao de palete
	aAdd(_aStruMov,{"MOV_COR"   ,"C", 2 ,0})
	aAdd(_aStruMov,{"MOV_PROD"  ,"C", TamSx3("C6_PRODUTO")[1] ,0})
	aAdd(_aStruMov,{"MOV_LOTE"  ,"C", TamSx3("C6_LOTECTL")[1] ,0})
	aAdd(_aStruMov,{"MOV_LOTED" ,"C", TamSx3("C6_LOTECTL")[1] ,0})
	aAdd(_aStruMov,{"MOV_LOCORI","C", TamSx3("BE_LOCAL")[1] ,0})
	aAdd(_aStruMov,{"MOV_ENDORI","C", TamSx3("BE_LOCALIZ")[1] ,0})
	aAdd(_aStruMov,{"MOV_SALDO" ,"N", TamSx3("BF_QUANT")[1],TamSx3("BF_QUANT")[2]})
	aAdd(_aStruMov,{"MOV_QUANT" ,"N", TamSx3("BF_QUANT")[1],TamSx3("BF_QUANT")[2]})
	aAdd(_aStruMov,{"MOV_QTDSEG","N", TamSx3("BF_QTSEGUM")[1],TamSx3("BF_QTSEGUM")[2]})
	aAdd(_aStruMov,{"MOV_LOCDES","C", TamSx3("BE_LOCAL")[1] ,0})
	aAdd(_aStruMov,{"MOV_ENDDES","C", TamSx3("BE_LOCALIZ")[1] ,0})
	aAdd(_aStruMov,{"MOV_ETQPLT","C", TamSx3("Z11_CODETI")[1] ,0})
	aAdd(_aStruMov,{"MOV_NUMOS" ,"C", TamSx3("Z06_NUMOS")[1] ,0})
	aAdd(_aStruMov,{"MOV_SEQOS" ,"C", TamSx3("Z06_SEQOS")[1] ,0})

	If (Select(_TRBMOV)<>0)
		dbSelectArea(_TRBMOV)
		dbCloseArea()
	EndIf

	// criar um arquivo de trabalho
	_cTrbMov := FWTemporaryTable():New( _TRBMOV )
	_cTrbMov:SetFields( _aStruMov )
	_cTrbMov:Create()

	// define header
	aAdd(_aHeadMov,{"MOV_PROD"  ,"","Produto"})
	aAdd(_aHeadMov,{"MOV_LOTE"  ,"","Lote Org"})
	aAdd(_aHeadMov,{"MOV_LOTED"  ,"","Lote Des"})
	aAdd(_aHeadMov,{"MOV_LOCORI","","Local.Origem"})
	aAdd(_aHeadMov,{"MOV_ENDORI","","End.Origem"})
	aAdd(_aHeadMov,{"MOV_LOCDES","","Local.Destino"})
	aAdd(_aHeadMov,{"MOV_ENDDES","","End.Destino"})
	aAdd(_aHeadMov,{"MOV_SALDO" ,"","Sld.Endereço",PesqPict("SBF","BF_QUANT")})
	aAdd(_aHeadMov,{"MOV_QUANT" ,"","Quant.Mov."  ,PesqPict("SBF","BF_QUANT")})
	aAdd(_aHeadMov,{"MOV_QTDSEG" ,"","Seg.Um.Mov."  ,PesqPict("SBF","BF_QTSEGUM")})
	aAdd(_aHeadMov,{"MOV_ETQPLT","","Etq.Palete"})
	aAdd(_aHeadMov,{"MOV_NUMOS","","Ord.Srv."})
	aAdd(_aHeadMov,{"MOV_SEQOS","","Seq.OS"})


	// abre o arquivo de trabalho
	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	(_TRBMOV)->(dbGoTop())

	// monta o dialogo
	_oWndMovPlt := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Movimentação de Palete",,,.F.,,,,,,.T.,,,.T. )
	_oWndMovPlt:lMaximized := .T.

	// panel para os botoes de comando
	_oPnlBtnOpr := TPanel():New(000,000,Nil,_oWndMovPlt,,.F.,.F.,,,26,26,.T.,.F. )
	_oPnlBtnOpr:Align := CONTROL_ALIGN_TOP

	// -- botao confirmar
	_oBtnConfInt := TButton():New(005,005,"Confirmar",_oPnlBtnOpr,{|| sfProcessa(@_oWndMovPlt) },030,015,,,,.T.,,"",,,,.F. )

	// -- botao importar planilha
	_oBtnImpPla := TButton():New(005,040,"Import.CSV",_oPnlBtnOpr,{|| sfImpPlanilha() },030,015,,,,.T.,,"",,,,.F. )

	// -- botao fechar
	_oBtnFechar := TButton():New(005,((_aSizeDlg[5]/2)-35),"Fechar",_oPnlBtnOpr,{|| _oWndMovPlt:End() },030,015,,,,.T.,,"",,,,.F. )

	// browse com a listagem dos manifestos
	_oBrwMovPlt := MsSelect():New(_TRBMOV,,,_aHeadMov,,,{000,000,2000,2000},,,_oWndMovPlt,,;
	{{"Empty((_TRBMOV)->MOV_COR)","DISABLE"},{" ! Empty((_TRBMOV)->MOV_COR)","ENABLE"}})
	_oBrwMovPlt:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oWndMovPlt CENTERED

	// fecha arquivo de trabalho
	If ValType(_cTrbMov) == "O"
		_cTrbMov:Delete()
	EndIf

Return

//** funcao para processamento da movimentacao dos produtos
Static Function sfProcessa(mvObjWnd)
	// controle do processamento
	local _lOk := .f.
	// variaveis da rotina automatica
	local _aItemSD3 := {}
	local _aTmpItem := {}
	// documento
	local _cDoctoSD3

	// variaveis usadas na rotina a260processa
	Private cCusMed := SuperGetMV('MV_CUSMED')
	Private aRegSD3 := {}

	If ( ! MsgYesNo("Confirma a movimentação da carga?"))
		Return(.f.)
	EndIf

	// chama o grupo de perguntas padrao da rotina MATA260
	pergunte("MTA260",.f.)

	// define o parametro "Considera Saldo poder de 3" como NAO
	mv_par03 := 2

	// zera variaveis
	_aItemSD3 := {}
	_aTmpItem := {}

	// inicia transacao
	BEGIN TRANSACTION

		// itens e enderecos dos produtos a movimentar
		(_TRBMOV)->(dbSelectArea(_TRBMOV))
		(_TRBMOV)->(DbGoTop())
		While (_TRBMOV)->( ! Eof() )

			// documento SD3
			_cDoctoSD3 := NextNumero("SD3",2,"D3_DOC",.T.)

			// controle de regua de processamento
			IncProc("Produto: "+AllTrim((_TRBMOV)->MOV_PROD))

			// posiciona no cadastro de produtos
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
			SB1->(dbSeek( xFilial("SB1")+(_TRBMOV)->MOV_PROD ))

			// zera variavel
			_aTmpItem := {}
			_aItemSD3 := {}

			// itens para movimentacao de transferencia
			_aTmpItem := {;
			(_TRBMOV)->MOV_PROD       ,;
			SB1->B1_DESC            ,;
			SB1->B1_UM              ,;
			(_TRBMOV)->MOV_LOCORI     ,;
			(_TRBMOV)->MOV_ENDORI     ,;
			(_TRBMOV)->MOV_PROD       ,;
			SB1->B1_DESC            ,;
			SB1->B1_UM              ,;
			(_TRBMOV)->MOV_LOCDES     ,;
			(_TRBMOV)->MOV_ENDDES     ,;
			CriaVar("D3_NUMSERI")   ,;
			(_TRBMOV)->MOV_LOTE       ,;
			CriaVar("D3_NUMLOTE")   ,;
			CtoD("31/12/2049")      ,;
			0                       ,;
			(_TRBMOV)->MOV_QUANT      ,;
			(_TRBMOV)->MOV_QTDSEG     ,;
			CriaVar("D3_ESTORNO")   ,;
			CriaVar("D3_NUMSEQ")    ,;
			(_TRBMOV)->MOV_LOTED      ,;
			Date()                  ,;
			CriaVar("D3_SERVIC")    ,;
			CriaVar("D3_ITEMGRD")   ,;
			CriaVar("D3_IDDCF")     ,;
			CriaVar("D3_OBSERVA")   ,;
			(_TRBMOV)->MOV_NUMOS      ,;
			(_TRBMOV)->MOV_SEQOS      ,;
			(_TRBMOV)->MOV_ETQPLT     ,;
			""                      ,;
			""                      ,;
			""                       }

			_aItemSD3 := {{_cDoctoSD3,dDataBase}}

			// adiciona o item
			aAdd(_aItemSD3,_aTmpItem)

			lMsHelpAuto := .T.
			lMsErroAuto := .F.

			// executa rotina automatica
			MsExecAuto({|x,y|MATA261(x,y)},_aItemSD3,3) // 3-transferencia

			// controle de erro na transferencia
			If (lMsErroAuto)
				// controle de retorno
				_lOk := .f.
				// rollback na transacao
				DisarmTransaction()
				// libera todos os registros
				MsUnLockAll()
				// mensagem de erro
				MostraErro()
				// retorno da funcao
				Break
			EndIf

			// proximo item
			(_TRBMOV)->(dbSkip())
		EndDo

		// finaliza transacao
	END TRANSACTION

	If _lOk
		MsgInfo("Processamento Ok")

		// fecha a janela
		mvObjWnd:End()
	EnDIf

Return _lOk

//** funcao para importar a planilha com os enderecos
Static Function sfImpPlanilha()
	// busca arquivo XML
	local _cArquivo := cGetFile("Planilhas|*.CSV", ("Selecione arquivo CSV"),,,,GETF_LOCALHARD,.f.)
	// arquivos temporarios
	local _vLinha := {}
	// codigo do produto
	local _cCodProd := ""
	// codigo do endereco
	local _cLocOrig := ""
	local _cEndOrig := ""
	local _cLocDest := ""
	local _cEndDest := ""
	// lote
	local _cLoteCtl := ""
	local _cLoteDes := ""
	// quantidade
	local _nQuant := 0
	local _nQtdSeg := 0
	// numero da OS
	local _cNumOS := ""
	local _cSeqOS := ""
	// id palete
	local _cIdPalete := ""
	// saldo no endereco
	local _nSaldoSBF := 0

	// verifica se o arquivo existe
	If ( ! File(_cArquivo) )
		Aviso("TWMSA099 -> sfImpPlanilha","Arquivo "+AllTrim(_cArquivo)+" não encontrado.",{"Fechar"})
		Return(.f.)
	EndIf

	// abre o arquivo TXT
	FT_FUse(_cArquivo)
	FT_FGoTop()

	// varre todas as linhas do arquivo
	While ( ! FT_FEof() )

		// extrai e separa os dados da linha corrente
		_vLinha := Separa(FT_FReadln(),";")

		// armazem origem
		_cLocOrig := AllTrim(_vLinha[1])
		// padroniza o codigo
		_cLocOrig := PadR(_cLocOrig,TamSx3("BE_LOCAL")[1])

		// endereco origem
		_cEndOrig := AllTrim(_vLinha[2])
		// padroniza o codigo
		_cEndOrig := PadR(_cEndOrig,TamSx3("BE_LOCALIZ")[1])

		// armazem destino
		_cLocDest := AllTrim(_vLinha[3])
		// padroniza o codigo
		_cLocDest := PadR(_cLocDest,TamSx3("BE_LOCAL")[1])

		// endereco destino
		_cEndDest := AllTrim(_vLinha[4])
		// padroniza o codigo
		_cEndDest := PadR(_cEndDest,TamSx3("BE_LOCALIZ")[1])

		// extrai o codigo do produto
		_cCodProd := AllTrim(_vLinha[5])
		// padroniza o codigo
		_cCodProd := PadR(_cCodProd,TamSx3("B1_COD")[1])

		// extrai o lote origem
		_cLoteCtl := AllTrim(_vLinha[6])
		// padroniza o codigo
		_cLoteCtl := PadR(_cLoteCtl,TamSx3("B8_LOTECTL")[1])

		// extrai o id palete
		_cIdPalete := AllTrim(_vLinha[7])
		// padroniza o codigo
		_cIdPalete := PadR(_cIdPalete,TamSx3("Z11_CODETI")[1])

		// quantidade
		_nQuant := Val(StrTran(StrTran(_vLinha[8],".",""),",","."))

		// quantidade seg unid medida
		_nQtdSeg := Val(StrTran(StrTran(_vLinha[9],".",""),",","."))

		// extrai o numero os
		_cNumOS := AllTrim(_vLinha[10])
		// padroniza o codigo
		_cNumOS := PadR(_cNumOS,TamSx3("Z06_NUMOS")[1])

		// extrai o sequencia os
		_cSeqOS := AllTrim(_vLinha[11])
		// padroniza o codigo
		_cSeqOS := PadR(_cSeqOS,TamSx3("Z06_SEQOS")[1])

		// extrai o lote destino
		_cLoteDes := AllTrim(_vLinha[12])
		// padroniza o codigo
		_cLoteDes := PadR(_cLoteDes,TamSx3("B8_LOTECTL")[1])

		// verifica se o endereco destino existe
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
		If ( ! SBE->(dbSeek( xFilial("SBE") + _cLocDest + _cEndDest )) )
			// mensagem
			MsgStop("Endereço destino "+_cEndDest+" não encontrado!")
			// retorno
			Return(.f.)
		EndIf

		// verifica se o endereco origem existe
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
		If ( ! SBE->(dbSeek( xFilial("SBE") + _cLocOrig + _cEndOrig )) )
			// mensagem
			MsgStop("Endereço origem "+_cEndOrig+" não encontrado!")
			// retorno
			Return(.f.)
		EndIf

		// Atualiza arquivo de saldos em estoque
		dbSelectArea("SB2")
		SB2->(DbSetOrder(1)) // 1-B2_FILIAL, B2_COD, B2_LOCAL
		If ! SB2->(dbSeek( xFilial("SB2") + _cCodProd + _cLocDest ))
			// cria saldo no armazem de destino
			CriaSB2(_cCodProd, _cLocDest)
		EndIf
		//		// verifica o saldo do produto no endereco de origem
		//		_nSaldoSBF := SaldoSBF(;
		//		_cLocOrig    ,;
		//		_cEndOrig    ,;
		//		_cCodProd    ,;
		//		NIL          ,;
		//		_cLoteCtl    ,;
		//		NIL          ,;
		//		.F.          ,;
		//		SBE->BE_ESTFIS)

		// inclui o registro
		(_TRBMOV)->(dbSelectArea(_TRBMOV))
		(_TRBMOV)->(RecLock(_TRBMOV,.t.))
		(_TRBMOV)->MOV_COR    := "OK"
		(_TRBMOV)->MOV_PROD   := _cCodProd
		(_TRBMOV)->MOV_LOTE   := _cLoteCtl
		(_TRBMOV)->MOV_LOTED  := _cLoteDes
		(_TRBMOV)->MOV_LOCORI := _cLocOrig
		(_TRBMOV)->MOV_ENDORI := _cEndOrig
		(_TRBMOV)->MOV_SALDO  := _nSaldoSBF
		(_TRBMOV)->MOV_QUANT  := _nQuant
		(_TRBMOV)->MOV_QTDSEG := _nQtdSeg
		(_TRBMOV)->MOV_LOCDES := _cLocDest
		(_TRBMOV)->MOV_ENDDES := _cEndDest
		(_TRBMOV)->MOV_NUMOS  := _cNumOS
		(_TRBMOV)->MOV_SEQOS  := _cSeqOS
		(_TRBMOV)->MOV_ETQPLT := _cIdPalete
		(_TRBMOV)->(MsUnLock())

		// proxima linha
		FT_FSkip()
	EndDo

	// fecha o arquivo
	ft_FUse()

	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	(_TRBMOV)->(dbGoTop())

Return
