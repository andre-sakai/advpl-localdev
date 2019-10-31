#include 'protheus.ch'
#include 'parmtype.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina de "Saldo Por Etiqueta de Cliente"               !
!                  !                                                         !
!                  ! Possibilita ao usuário ter uma visão ampla, completa e  !
!                  ! facil de todo o saldo, endereços, notas fiscais         !
!                  ! e demais análises pertinentes de uma                    !
!                  ! determinada etiqueta de cliente no WMS                  !
+------------------+---------------------------------------------------------+
!Autor             ! Felippe Mercurio            ! Data de Criacao ! 03/2019 !
+------------------+--------------------------------------------------------*/


user function TWMSV012()

	private mvFirst := .T.
	private mvCount := 0
	// dimensoes da tela
	private _aSizeDlg := MsAdvSize()

	// objetos da tela inicial
	private _oDlg, _oPnlCab, _oPnlEtiq, _oPnlEnd, _oBtSair, _oSayProd, _oGetProd, _oBtRefresh, _oBtLegEnd

	// objetos do painel central
	private _oSProd, _oSNFEnt, _oSSerEnt, _oSEnder, _oSSldLog, _oSSldFis  
	private _oGProd, _oGNFEnt, _oGSerEnt, _oGEnder, _oGSldLog, _oGSldFis 

	// pastas do FOLDER
	private _aFolders := {'Entradas/Saídas Fiscais da Etiqueta','Movimentação Interna da Etiqueta'}

	// fontes utilizadas
	private _oFnt01 := TFont():New("Tahoma",,18,,.t.)

	// legenda da grid de endereços
	private _aCorEnd := {}

	private lAchou := .T.

	// variáveis para info etiqueta
	private _cProduto	:= ''
	private _cProDesc	:= ''
	private _cEtqPlt	:= ''
	private _cEtqTec	:= ''
	private _cOrigem	:= ''
	private _cPltOri	:= ''
	private _cOriPrdVol := ''
	private _cLote		:= ''
	private _cNFEnt		:= ''
	private _cSerEnt	:= ''
	private _cEnder		:= ''
	private _nSldLog	:= 0

	// variáveis informações adicionais
	private _cRua      := ""
	private _cLado     := ""
	private _cPredio   := ""
	private _cNivel    := ""
	private _cSeque    := ""
	private _cDoca     := ""
	private _cBloco    := ""


	// Aba saídas de etiquetas
	private _aHeadSai := {}
	private _cTrabSai
	private _aStruSai := {}
	private _oBrwSai
	private _cAlSai   := GetNextAlias()

	// Aba movimentação de etiquetas
	private _aHeadMov := {}
	private _cTrabMov
	private _aStruMov := {}
	private _oBrwMov
	private _cAlMov   := GetNextAlias()

	// objetos para exibir composição do porta-pallet
	private _oSayRua, _oSayLado, _oSayPred, _oSayNivel, _oSaySeq, _oGrPP

	// variáveis gerais
	private cCadastro := "Saldo Por Etiqueta"
	private _cEtiqueta := CriaVar("Z56_ETQCLI", .F.)

	// cores da legenda para endereços
	aAdd(_aCorEnd, {"Empty((_cAlEnd)->CONTROLE)","BR_VERDE_ESCURO"})    // status OK
	aAdd(_aCorEnd, {"(_cAlEnd)->CONTROLE == 'DOC'","BR_PRETO"})         // estrutura do endereço é docas
	aAdd(_aCorEnd, {"(_cAlEnd)->CONTROLE == 'RUA'","BR_AMARELO"})       // em rua
	aAdd(_aCorEnd, {"(_cAlEnd)->CONTROLE == 'SAL'","BR_VERMELHO"})      // divergência de saldo fiscal X lógico
	aAdd(_aCorEnd, {"(_cAlEnd)->CONTROLE == 'SKU'","BR_CINZA"})         // múltiplos SKU
	aAdd(_aCorEnd, {"(_cAlEnd)->CONTROLE == 'EST'","BR_PINK"})          // tipo de estoque diferente de normal
	aAdd(_aCorEnd, {"(_cAlEnd)->CONTROLE == 'BLQ'","BR_CANCEL"})        // tipo de estoque diferente de normal

	sfMontaTela()
return

static function sfMontaTela()
	// cria os arquivos de trabalho, alias e dados necessários
	//lAchou := sfRefresh( .T. )

	If lAchou

		//Monta tela principal.
		_oDlg := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5], cCadastro,,,.F.,,,,,,.T.,,,.T. )
		_oDlg:lMaximized := .T.

		//-- INICIO PAINEL SUPERIOR --

		//Painel superior com informações da OS
		_oPnlCab := TPanel():New(000,000,nil,_oDlg,,.F.,.F.,,,00,26,.T.,.F. )
		_oPnlCab:Align:= CONTROL_ALIGN_TOP

		// produto
		_oSayProd := TSay():New(007,005,{||"Cód. Etiq. Cliente:"},_oPnlCab,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGetProd := TGet():New(005,080,{|u| If(PCount()>0,_cEtiqueta:=u,_cEtiqueta)},_oPnlCab,100,012,PesqPict("Z56","Z56_ETQCLI"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtiqueta",,)

		//Botão Refresh dos dados
		_oBtRefresh := TBtnBmp2():New(005,400,040,040,"RELOAD",,,,{|| sfRefresh() },_oPnlCab,"Atualiza dados",,.T. )

		// define o botao Sair
		_oBtSair := TBtnBmp2():New(001,001,040,040,"FINAL",,,,{|| _oDlg:End() },_oPnlCab,"Sair",,.T. )
		_oBtSair:Align := CONTROL_ALIGN_RIGHT

		//-- FIM PAINEL SUPERIOR --

		//-- INICIO PAINEL DO MEIO --
		//Painel do meio com saldos
		_oPnlEtiq := TPanel():New(000,000,nil,_oDlg,,.F.,.F.,,,00,135,.T.,.F. )
		_oPnlEtiq:Align:= CONTROL_ALIGN_TOP

		// codigo do produto
		_oSProd := TSay():New(007,005,{||"Código do Produto:"},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGProd := TGet():New(005,180,{|u| If(PCount()>0,_cProduto:=u,_cProduto)},_oPnlEtiq,200,012,PesqPict("SB1","B1_COD"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cProduto",,)

		// descrição do produto
		_oSNFEnt := TSay():New(018,005,{||"Descrição do Produto:"},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGNFEnt := TGet():New(020,180,{|u| If(PCount()>0,_cProDesc:=u,_cProDesc)},_oPnlEtiq,200,012,PesqPict("SB1","B1_DESC"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cProDesc",,)

		// codigo de etiqueta atrelada
		_oSNFEnt := TSay():New(033,005,{||"Etiq. Tecadi Atrelada:"},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGNFEnt := TGet():New(035,180,{|u| If(PCount()>0,_cEtqTec:=u,_cEtqTec)},_oPnlEtiq,100,012,PesqPict("Z11","Z11_CODETI"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cEtqTec",,)

		// lote
		_oSNFEnt := TSay():New(048,005,{||"Lote:"},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGNFEnt := TGet():New(050,180,{|u| If(PCount()>0,_cLote:=u,_cLote)},_oPnlEtiq,100,012,PesqPict("Z16","Z16_LOTCTL"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cLote",,)

		// nf de entrada
		_oSNFEnt := TSay():New(063,005,{||"Nota fiscal atrelada:"},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGNFEnt := TGet():New(065,180,{|u| If(PCount()>0,_cNFEnt:=u,_cNFEnt)},_oPnlEtiq,70,012,PesqPict("SD1","D1_DOC"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cNFEnt",,)

		// serie de entrada
		_oSSerEnt := TSay():New(078,005,{||"Série NF atrelada:"},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGSerEnt := TGet():New(080,180,{|u| If(PCount()>0,_cSerEnt:=u,_cSerEnt)},_oPnlEtiq,70,012,PesqPict("SD1","D1_SERIE"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cSerEnt",,)

		// endereço
		_oSEnder := TSay():New(093,005,{||"Cód. Endereço:"},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGEnder := TGet():New(095,180,{|u| If(PCount()>0,_cEnder:=u,_cEnder)},_oPnlEtiq,100,012,PesqPict("Z16","Z16_ENDATU"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cEnder",,)

		// saldo lógico
		_oSSldLog := TSay():New(108,005,{||"Saldo:"},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGSldLog := TGet():New(110,180,{|u| If(PCount()>0,_nSldLog:=u,_nSldLog)},_oPnlEtiq,70,012,PesqPict("Z16","Z16_SALDO"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nSldLog",,)

		// ativa a tela
		ACTIVATE MSDIALOG _oDlg CENTERED

	EndIf
	// antes de sair da rotina, apaga áreas de trabalho criadas
	If ValType(_cTrabSai) == "O"
		_cTrabSai:Delete()
	EndIf
	
	If ValType(_cTrabMov) == "O"
		_cTrabMov:Delete()
	EndIf

return

// ** funcao que carrega os dados da programacao
Static Function sfRefresh()

	mvCount = mvCount++
	lAchou := sfAtuInfo()
	If mvCount > 1
		mvFirst = .F.
	EndIf

	If lAchou
		MsgRun("Atualizando informacoes...", "Aguarde...", {||	CursorWait(),;
		sfAtuSai(mvFirst),;
		sfAtuMov(mvFirst),;
		CursorArrow()})

		// group panel para exibir composição do endereço caso seja porta pallet
		_oGrPP   := TGroup():New(007,450,093,550,'Coordenadas do Endereço',_oPnlEtiq,,,.T.)

		If SubStr(_cRua+_cLado+_cPredio+_cNivel+_cSeque,1,10) == "TRANSITORI"
			_cRua	 := "TRANSITORI"
			_cLado	 := ""
			_cPredio := ""
			_cNivel	 := ""
			_cSeque	 := ""			
		Endif
		If SubStr(_cRua+_cLado+_cPredio+_cNivel+_cSeque,1,10) == "RETRABALHO"
			_cRua	 := "RETRABALHO"
			_cLado	 := ""
			_cPredio := ""
			_cNivel	 := ""
			_cSeque	 := ""			
		Endif
		If SubStr(_cRua+_cLado+_cPredio+_cNivel+_cSeque,1,9) == "QUALIDADE"
			_cRua	 := "QUALIDADE"
			_cLado	 := ""
			_cPredio := ""
			_cNivel	 := ""
			_cSeque	 := ""
		Endif
		If SubStr(_cRua+_cLado+_cPredio+_cNivel+_cSeque,1,10) == "NAOCONFORM"
			_cRua	 := "NAOCONFORM"
			_cLado	 := ""
			_cPredio := ""
			_cNivel	 := ""
			_cSeque	 := ""
		Endif
		If SubStr(_cRua+_cLado+_cPredio+_cNivel+_cSeque,1,7) == "STAGEIN"
			_cRua	 := "STAGEIN " + SubStr(_cRua+_cLado+_cPredio+_cNivel+_cSeque,8,Len(_cRua+_cLado+_cPredio+_cNivel+_cSeque))
			_cLado	 := ""
			_cPredio := ""
			_cNivel	 := ""
			_cSeque	 := ""			
		Endif
		If SubStr(_cRua+_cLado+_cPredio+_cNivel+_cSeque,1,8) == "STAGEOUT"
			_cRua	 := "STAGEOUT " + SubStr(_cRua+_cLado+_cPredio+_cNivel+_cSeque,9,Len(_cRua+_cLado+_cPredio+_cNivel+_cSeque))
			_cLado	 := ""
			_cPredio := ""
			_cNivel	 := ""
			_cSeque	 := ""		
		Endif
		If SubStr(_cRua+_cLado+_cPredio+_cNivel+_cSeque,1,4) == "DOCA"
			_cRua	 := "DOCA " + SubStr(_cRua+_cLado+_cPredio+_cNivel+_cSeque,5,Len(_cRua+_cLado+_cPredio+_cNivel+_cSeque))
			_cLado	 := ""
			_cPredio := ""
			_cNivel	 := ""
			_cSeque	 := ""
		Endif
		If SubStr(_cRua+_cLado+_cPredio+_cNivel+_cSeque,1,5) == "BLOCO"
			_cRua	 := "BLOCO " + SubStr(_cRua+_cLado+_cPredio+_cNivel+_cSeque,6,Len(_cRua+_cLado+_cPredio+_cNivel+_cSeque))
			_cLado	 := ""
			_cPredio := ""
			_cNivel	 := ""
			_cSeque	 := ""
		Endif

		If !mvFirst
			// atualiza objetos da composição do porta pallet
			_oSayRua:Refresh()
			_oSayLado:Refresh()
			_oSayPred:Refresh()
			_oSayNivel:Refresh()
			_oSaySeq:Refresh()
		EndIf

		_oSayRua   := TSay():New(020,455,{|| "Rua:    " + _cRua    },_oGrPP,,_oFnt01,.F.,.F.,.F.,.T.)
		_oSayLado  := TSay():New(035,455,{|| "Lado:   " + _cLado   },_oGrPP,,_oFnt01,.F.,.F.,.F.,.T.)
		_oSayPred  := TSay():New(050,455,{|| "Prédio: " + _cPredio },_oGrPP,,_oFnt01,.F.,.F.,.F.,.T.)
		_oSayNivel := TSay():New(065,455,{|| "Nível:  " + _cNivel  },_oGrPP,,_oFnt01,.F.,.F.,.F.,.T.)
		_oSaySeq   := TSay():New(080,455,{|| "Seq.:   " + _cSeque  },_oGrPP,,_oFnt01,.F.,.F.,.F.,.T.)

		_oSOrigem  := TSay():New(100,450,{||"Origem Etiqueta: " + _cOrigem},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)

		//-- FIM PAINEL DO MEIO --

		// pastas 
		_oFolder := TFolder():New(900,500,_aFolders,,_oDlg,,,,.T.,,500,1200)
		_oFolder:Align:= CONTROL_ALIGN_ALLCLIENT

		// browse com a listagem das saídas de etiquetas 
		_oBrwSai := MsSelect():New((_cAlSai),,,_aHeadSai,,,{001,001,400,1000},,,_oFolder:aDialogs[1])
		_oBrwSai:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// browse com a listagem das movimentações da etqiueta
		_oBrwMov := MsSelect():New((_cAlMov),,,_aHeadMov,,,{001,001,400,1000},,,_oFolder:aDialogs[2])
		_oBrwMov:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// refresh do browse
		If (_oBrwMov <> nil)	
			_oBrwMov:oBrowse:Refresh()
		EndIf

		// refresh do browse
		If (_oBrwSai <> nil)
			_oBrwSai:oBrowse:Refresh()
		EndIf

	EndIf

Return lAchou

// ** funcao que retorna as informações principais da etiqueta
Static Function sfAtuInfo()
	local _cQuery

	_cQuery := " SELECT DISTINCT " 
	_cQuery += " Z11_FILIAL, "
	_cQuery += " Z11_CODETI, "
	_cQuery += " Z56_ETQCLI, "
	_cQuery += " Z16_ORIGEM, "
	_cQuery += " Z16_PLTORI, "
	_cQuery += " Z16_ETQPAL, "
	_cQuery += " CASE WHEN Z16_PRDORI = '' "
	_cQuery += " 	  THEN Z16_VOLORI "
	_cQuery += " 	  ELSE Z16_PRDORI "
	_cQuery += " END AS Z16_ORI, "
	_cQuery += " Z16_CODPRO, "
	_cQuery += " B1_DESC, "
	_cQuery += " Z16_LOTCTL, "
	_cQuery += " Z11_DOC, "
	_cQuery += " Z11_SERIE, "
	_cQuery += " Z16_SALDO, "
	_cQuery += " Z16_ENDATU, "
	_cQuery += " Z16_LOCAL, "
	_cQuery += " Z16_LOTCTL, "
	_cQuery += " Z16_VLDLOT, "
	_cQuery += " BE_STATUS, "
	_cQuery += " Substring(BE_LOCALIZ, 1, 2) AS RUA," 
	_cQuery += " Substring(BE_LOCALIZ, 3, 1) AS LADO, " 
	_cQuery += " Substring(BE_LOCALIZ, 4, 2) AS PREDIO, " 
	_cQuery += " Substring(BE_LOCALIZ, 6, 2) AS NIVEL, "
	_cQuery += " Substring(BE_LOCALIZ, 8, 5) AS SEQUENCIA " 
	_cQuery += " FROM "+ RetSqlTab("Z56") +" (nolock) "
	_cQuery += " LEFT JOIN "+ RetSqlTab("Z11") +" (nolock) "
	_cQuery += " 	ON "+ RetSqlCond("Z11") 
	_cQuery += " 	AND (Z11_CODETI = Z56_CODETI) "
	_cQuery += " LEFT JOIN "+ RetSqlTab("Z16") +" (nolock) " 
	_cQuery += " 	ON "+ RetSqlCond("Z16")  
	_cQuery += " 	AND (Z11_CODETI = Z16_ETQPRD OR Z11_CODETI = Z16_ETQVOL) "
	_cQuery += " LEFT JOIN "+ RetSqlTab("SBE") +" (nolock) "  
	_cQuery += " 	ON "+RetSqlCond("SBE")
	_cQuery += " 	AND Z16_LOCAL = BE_LOCAL "
	_cQuery += " 	AND Z16_ENDATU = BE_LOCALIZ "
	_cQuery += " LEFT JOIN "+ RetSqlTab("SB1") +" (nolock) "
	_cQuery += " 	ON "+RetSqlCond("SB1")
	_cQuery += " 	AND Z16_CODPRO = B1_COD "
	_cQuery += " WHERE  "+RetSqlCond("Z56")
	_cQuery += " AND Z56_ETQCLI = '"+_cEtiqueta+"'"

	memowrit("C:\query\twmsv012_sfAtuInfo.txt",_cQuery)

	// verifica se o alias da query existe
	If (Select("_QRYETQ") != 0)
		dbSelectArea("_QRYETQ")
		dbCloseArea()
	Endif
	// executa a query
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),"_QRYETQ",.F.,.T.)
	DbSelectArea("_QRYETQ")

	If empty(_QRYETQ->Z56_ETQCLI)
		If mvCount == 1
			mvCount := 0
		Endif
		MsgAlert("Etiqueta não encontrada - Verifique se Filial está correta")
		Return(.F.)
	Elseif !empty(_QRYETQ->Z56_ETQCLI) .and. empty(_QRYETQ->Z16_ETQPAL)
		If mvCount == 1
			mvCount := 0
		Endif
		MsgAlert("Etiqueta do Cliente não vinculada a etiqueta Tecadi")
		Return(.F.)
	Else
		_cProduto	:= _QRYETQ->Z16_CODPRO
		_cProDesc	:= _QRYETQ->B1_DESC
		_cEtqTec	:= _QRYETQ->Z11_CODETI
		_cEtqPlt	:= _QRYETQ->Z16_ETQPAL
		_cOrigem	:= _QRYETQ->Z16_ORIGEM
		_cPltOri	:= _QRYETQ->Z16_PLTORI
		_cOriPrdVol	:= _QRYETQ->Z16_ORI
		_cNFEnt		:= _QRYETQ->Z11_DOC 
		_cSerEnt	:= _QRYETQ->Z11_SERIE
		_cLote		:= _QRYETQ->Z16_LOTCTL
		_cEnder		:= _QRYETQ->Z16_ENDATU
		_nSldLog	:= _QRYETQ->Z16_SALDO
		//Info Endereço
		_cRua		:= _QRYETQ->RUA
		_cLado		:= _QRYETQ->LADO
		_cPredio	:= _QRYETQ->PREDIO
		_cNivel		:= _QRYETQ->NIVEL
		_cSeque		:= _QRYETQ->SEQUENCIA
	EndIf

	_cEtqPlt := "'"+_cEtqPlt+"'"

	Do While !(Empty(_cPltOri))
		_cQuery := " SELECT Z16_FILIAL, " 
		_cQuery += " Z16_ETQPAL, " 
		_cQuery += " Z16_PLTORI, " 
		_cQuery += " CASE WHEN Z16_PRDORI = '' "
		_cQuery += " 	  THEN Z16_VOLORI "
		_cQuery += " 	  ELSE Z16_PRDORI "
		_cQuery += " END AS Z16_ORI "
		_cQuery += " FROM  " + RetSqlTab("Z16") + " (NOLOCK) " 
		_cQuery += " WHERE " + RetSqlCond("Z16") 
		_cQuery += " AND Z16_ETQPAL = '"+_cPltOri+"' "
		_cQuery += " AND (Z16_ETQPRD = '"+_cOriPrdVol+"' OR Z16_ETQVOL = '"+_cOriPrdVol+"')"

		memowrit("C:\query\twmsv012_sfAtuInfo_PalOri.txt",_cQuery)

		// verifica se o alias da query existe
		If (Select("_QRYORI") != 0)
			dbSelectArea("_QRYORI")
			dbCloseArea()
		Endif
		// executa a query
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),"_QRYORI",.F.,.T.)
		DbSelectArea("_QRYORI")

		If !(Empty(_QRYORI->Z16_ETQPAL))
			_cEtqPlt := _cEtqPlt+",'"+_QRYORI->Z16_ETQPAL+"'"
		EndIf

		_cPltOri 	:= _QRYORI->Z16_PLTORI
		_cOriPrdVol := _QRYORI->Z16_ORI
	EndDo

Return .T.

Static Function sfAtuSai(mvFirst)
	local 	_cQuery

	If (mvFirst)
		// monta a estrutura do arquivo de trabalho
		aAdd(_aStruSai,{"DB_LOCALIZ","C", TamSx3("DB_LOCALIZ")[1], 0}); aAdd(_aHeadSai,{"DB_LOCALIZ","","Endereço",PesqPict("SDB","DB_LOCALIZ")})
		aAdd(_aStruSai,{"DB_DATA"   ,"D", TamSx3("DB_DATA")	  [1], 0}); aAdd(_aHeadSai,{"DB_DATA"   ,"","Data",PesqPict("SDB","DB_DATA")})
		aAdd(_aStruSai,{"DB_HRINI"	,"C", TamSx3("DB_HRINI")  [1], 0}); aAdd(_aHeadSai,{"DB_HRINI"	,"","Hora",PesqPict("SDB","DB_HRINI")})
		aAdd(_aStruSai,{"DB_DOC"	,"C", TamSx3("DB_DOC")	  [1], 0}); aAdd(_aHeadSai,{"DB_DOC"	,"","Nota Fiscal",PesqPict("SDB","DB_DOC")})
		aAdd(_aStruSai,{"DB_SERIE"	,"C", TamSx3("DB_SERIE")  [1], 0}); aAdd(_aHeadSai,{"DB_SERIE"	,"","Série",PesqPict("SDB","DB_SERIE")})
		aAdd(_aStruSai,{"DB_QUANT"	,"N", TamSx3("DB_QUANT")  [1], 0}); aAdd(_aHeadSai,{"DB_QUANT"	,"","Qtd.Mov.",PesqPict("SDB","DB_QUANT")})
		aAdd(_aStruSai,{"DB_ORIGEM"	,"C", 30					 , 0}); aAdd(_aHeadSai,{"DB_ORIGEM"	,"","Origem Mov.","@!"})
		aAdd(_aStruSai,{"DB_TM"		,"C", TamSx3("DB_TM")	  [1], 0}); aAdd(_aHeadSai,{"DB_TM"		,"","Tp.Movim",PesqPict("SDB","DB_TM")})
		aAdd(_aStruSai,{"DB_ZNUMOS"	,"C", TamSx3("DB_ZNUMOS") [1], 0}); aAdd(_aHeadSai,{"DB_ZNUMOS"	,"","Num. OS" ,PesqPict("SDB","DB_ZNUMOS")})
		aAdd(_aStruSai,{"DB_ZSEQOS" ,"C", TamSx3("DB_ZSEQOS") [1], 0}); aAdd(_aHeadSai,{"DB_ZSEQOS" ,"","Seq. OS" ,PesqPict("SDB","DB_ZSEQOS")})
		aAdd(_aStruSai,{"Z16_ORIGEM","C", TamSx3("Z16_ORIGEM")[1], 0}); aAdd(_aHeadSai,{"Z16_ORIGEM","","Origem",PesqPict("Z16","Z16_ORIGEM")})
		aAdd(_aStruSai,{"Z16_PLTORI","C", TamSx3("Z16_PLTORI")[1], 0}); aAdd(_aHeadSai,{"Z16_PLTORI","","Plt. Ori",PesqPict("Z16","Z16_PLTORI")})
		aAdd(_aStruSai,{"CONTROLE"  ,"C", 3                      , 0})

		// fecha alias do TRB
		If (Select(_cAlSai) <> 0)
			dbSelectArea(_cAlSai)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrabSai := FWTemporaryTable():New( _cAlSai )
		_cTrabSai:SetFields( _aStruSai )
		_cTrabSai:Create()
	EndIf

	// limpa o conteudo do TRB
	(_cAlSai)->(dbSelectArea(_cAlSai))
	(_cAlSai)->(__DbZap())

	_cQuery := " SELECT 'ENTRADA' AS 'MOVIMENTO', " 
	_cQuery += " DB_LOCALIZ, " 
	_cQuery += " DB_DATA, " 
	_cQuery += " DB_HRINI, " 
	_cQuery += " DB_DOC, " 
	_cQuery += " DB_SERIE, " 
	_cQuery += " DB_QUANT, " 
	_cQuery += " CASE " 
	_cQuery += " 	WHEN DB_ORIGEM = 'ACE' THEN 'ACERTO INVENTÁRIO' " 
	_cQuery += " 	WHEN DB_ORIGEM = 'SC6' THEN 'SAÍDA PV' " 
	_cQuery += " 	WHEN DB_ORIGEM = 'SD1' THEN 'ENTRADA NF'  " 
	_cQuery += " 	WHEN DB_ORIGEM = 'SD3' THEN 'MOVIMEN. INTERN.'  " 
	_cQuery += " ELSE DB_ORIGEM  " 
	_cQuery += " END       AS DB_ORIGEM, " 
	_cQuery += " CASE " 
	_cQuery += " 	WHEN DB_TM = '499' THEN 'ENTRADA' " 
	_cQuery += " 	WHEN DB_TM = '999' THEN 'SAIDA' " 
	_cQuery += " ELSE DB_TM " 
	_cQuery += " END       AS DB_TM, " 
	_cQuery += " DB_ZNUMOS, " 
	_cQuery += " DB_ZSEQOS, " 
	_cQuery += " Z16_ORIGEM, " 
	_cQuery += " Z16_PLTORI " 
	_cQuery += " FROM "+ RetSqlTab("SDB") +" (nolock) "
	_cQuery += " JOIN "+ RetSqlTab("Z16") +" (nolock) "
	_cQuery += " 	ON "+ RetSqlCond("Z16") 
	_cQuery += " 	AND DB_FILIAL = Z16_FILIAL
	_cQuery += " 	AND DB_ZPALLET = Z16_ETQPAL
	_cQuery += " WHERE  "+ RetSqlCond("SDB") 
	_cQuery += " 	AND DB_ZPALLET IN ( "+ _cEtqPlt +") " 
	_cQuery += " 	AND DB_ESTORNO = '' " 
	_cQuery += " 	AND DB_ORIGEM <> 'SD3' " 

	_cQuery += " UNION ALL " 

	_cQuery += " SELECT 'SAIDA' AS 'MOVIMENTO', " 
	_cQuery += " DB_LOCALIZ, " 
	_cQuery += " DB_DATA, " 
	_cQuery += " DB_HRINI, " 
	_cQuery += " DB_DOC, " 
	_cQuery += " DB_SERIE, " 
	_cQuery += " Z16_QUANT, " 
	_cQuery += " CASE " 
	_cQuery += " 	WHEN DB_ORIGEM = 'ACE' THEN 'ACERTO INVENTÁRIO' " 
	_cQuery += " 	WHEN DB_ORIGEM = 'SC6' THEN 'SAÍDA PV' " 
	_cQuery += " 	WHEN DB_ORIGEM = 'SD1' THEN 'ENTRADA NF' " 
	_cQuery += " 	WHEN DB_ORIGEM = 'SD3' THEN 'MOVIMEN. INTERN.' " 
	_cQuery += " ELSE DB_ORIGEM " 
	_cQuery += " END     AS DB_ORIGEM, " 
	_cQuery += " CASE " 
	_cQuery += " 	WHEN DB_TM = '499' THEN 'ENTRADA' " 
	_cQuery += " 	WHEN DB_TM = '999' THEN 'SAIDA' " 
	_cQuery += " ELSE DB_TM " 
	_cQuery += " END     AS DB_TM, " 
	_cQuery += " DB_ZNUMOS, " 
	_cQuery += " DB_ZSEQOS, " 
	_cQuery += " Z16_ORIGEM, " 
	_cQuery += " Z16_PLTORI " 
	_cQuery += " FROM "+ RetSqlTab("SDB") +" (nolock) "
	_cQuery += " JOIN "+ RetSqlTab("Z16") +" (nolock) "
	_cQuery += " 	ON "+ RetSqlCond("Z16") 
	_cQuery += " 	AND DB_FILIAL = Z16_FILIAL "
	_cQuery += " 	AND Z16_ETQPAL IN ( "+ _cEtqPlt +")"
	_cQuery += " WHERE  "+ RetSqlCond("SDB") 
	_cQuery += " 	AND DB_DOC = (SELECT C5_NOTA SC5010
	_cQuery += " 					FROM  "+ RetSqlTab("SC5") +" (nolock) "
	_cQuery += " 					WHERE "+ RetSqlCond("SC5") 
	_cQuery += " 						AND SC5.C5_ZNOSSEP = (SELECT SDB2.DB_ZNUMOS "
	_cQuery += " 												FROM  "+ RetSqlName("SDB") +" SDB2 (nolock) "
	_cQuery += " 												WHERE 	SDB2.DB_FILIAL = "+ xFilial('SDB') 
	_cQuery += " 													AND SDB2.D_E_L_E_T_ = '' " 
	_cQuery += " 													AND Substring(SDB2.DB_LOCALIZ,1,4) = 'DOCA' "
	_cQuery += " 													AND SDB2.DB_TM = '499' "
	_cQuery += " 													AND SDB2.DB_ZPALLET = Z16_ETQPAL " 
	_cQuery += "													AND SDB2.D_E_L_E_T_ = '' "
	_cQuery += " 													AND SDB2.DB_ESTORNO = '')) "
	_cQuery += " 	AND DB_ESTORNO = '' "
	_cQuery += " 	AND DB_PRODUTO = Z16_CODPRO "
	_cQuery += " 	AND DB_ORIGEM = 'SC6' "

	memowrit("C:\query\twmsv012_sfAtuSai.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQuery,_aStruSai,_cAlSai)

	// abre o arquivo de trabalho
	(_cAlSai)->(dbSelectArea(_cAlSai))
	(_cAlSai)->(dbGoTop())

Return

Static Function sfAtuMov(mvFirst)
	local 	_cQuery

	If (mvFirst)
		// monta a estrutura do arquivo de trabalho
		aAdd(_aStruMov,{"Z17_ENDORI","C", TamSx3("Z17_ENDORI")[1], 0}); aAdd(_aHeadMov,{"Z17_ENDORI","","End. Ori",PesqPict("Z17","Z17_ENDORI")})
		aAdd(_aStruMov,{"Z17_ENDDES","C", TamSx3("Z17_ENDDES")[1], 0}); aAdd(_aHeadMov,{"Z17_ENDDES","","End. Des",PesqPict("Z17","Z17_ENDDES")})
		aAdd(_aStruMov,{"Z17_DTINI"	,"D", TamSx3("Z17_DTINI") [1], 0}); aAdd(_aHeadMov,{"Z17_DTINI"	,"","Dt.Ini." ,PesqPict("Z17","Z17_DTINI")})
		aAdd(_aStruMov,{"Z17_HRINI"	,"C", TamSx3("Z17_HRINI") [1], 0}); aAdd(_aHeadMov,{"Z17_HRINI"	,"","Hr.Ini." ,PesqPict("Z17","Z17_HRINI")})
		aAdd(_aStruMov,{"Z17_DTFIM"	,"D", TamSx3("Z17_DTFIM") [1], 0}); aAdd(_aHeadMov,{"Z17_DTFIM"	,"","Dt.Fin." ,PesqPict("Z17","Z17_DTFIM")})
		aAdd(_aStruMov,{"Z17_HRFIM"	,"C", TamSx3("Z17_HRFIM") [1], 0}); aAdd(_aHeadMov,{"Z17_HRFIM"	,"","Hr.Fin." ,PesqPict("Z17","Z17_HRFIM")})
		aAdd(_aStruMov,{"Z17_NUMOS"	,"C", TamSx3("Z17_NUMOS") [1], 0}); aAdd(_aHeadMov,{"Z17_NUMOS"	,"","Num. OS" ,PesqPict("Z17","Z17_NUMOS")})
		aAdd(_aStruMov,{"Z17_SEQOS" ,"C", TamSx3("Z17_SEQOS") [1], 0}); aAdd(_aHeadMov,{"Z17_SEQOS"	,"","Seq. OS" ,PesqPict("Z17","Z17_SEQOS")})
		aAdd(_aStruMov,{"Z17_STATUS","C", TamSx3("Z17_STATUS")[1], 0}); aAdd(_aHeadMov,{"Z17_STATUS","","Status"  ,PesqPict("Z17","Z17_STATUS")})
		aAdd(_aStruMov,{"Z17_OPERAD","C", TamSx3("Z17_OPERAD")[1], 0}); aAdd(_aHeadMov,{"Z17_OPERAD","","Cód.Oper",PesqPict("Z17","Z17_OPERAD")})
		aAdd(_aStruMov,{"DCD_NOMFUN","C", TamSx3("DCD_NOMFUN")[1], 0}); aAdd(_aHeadMov,{"DCD_NOMFUN","","Nom.Oper",PesqPict("Z17","DCD_NOMFUN")})
		aAdd(_aStruMov,{"Z16_ORIGEM","C", TamSx3("Z16_ORIGEM")[1], 0}); aAdd(_aHeadMov,{"Z16_ORIGEM","","Origem",PesqPict("Z16","Z16_ORIGEM")})
		aAdd(_aStruMov,{"Z16_PLTORI","C", TamSx3("Z16_PLTORI")[1], 0}); aAdd(_aHeadMov,{"Z16_PLTORI","","Plt. Ori",PesqPict("Z16","Z16_PLTORI")})
		aAdd(_aStruMov,{"CONTROLE"  ,"C", 3                      , 0})

		// fecha alias do TRB
		If (Select(_cAlMov) <> 0)
			dbSelectArea(_cAlMov)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrabMov := FWTemporaryTable():New( _cAlMov )
		_cTrabMov:SetFields( _aStruMov )
		_cTrabMov:Create()
	EndIf

	// limpa o conteudo do TRB
	(_cAlMov)->(dbSelectArea(_cAlMov))
	(_cAlMov)->(__DbZap())

	_cQuery := " SELECT Z17_ENDORI, " 
	_cQuery += " Z17_ENDDES, "
	_cQuery += " Z17_DTINI, "
	_cQuery += " Z17_HRINI, "
	_cQuery += " Z17_DTFIM, "
	_cQuery += " Z17_HRFIM, "
	_cQuery += " Z17_NUMOS, "
	_cQuery += " Z17_SEQOS, "
	_cQuery += " Z17_STATUS, "
	_cQuery += " Z17_OPERAD, "
	_cQuery += " DCD_NOMFUN, "
	_cQuery += " Z16_ORIGEM, "
	_cQuery += " Z16_PLTORI "
	_cQuery += " FROM "+ RetSqlTab("Z17") +" (nolock) "
	_cQuery += " 	JOIN "+ RetSqlTab("DCD") +" (nolock) " 
	_cQuery += " 	ON "+ RetSqlCond("DCD")  
	_cQuery += " 	AND Z17_OPERAD = DCD_CODFUN " 
	_cQuery += " JOIN Z16010 (nolock) "
	_cQuery += " 	ON Z17_FILIAL = Z16_FILIAL "
	_cQuery += "	AND Z17_ETQPLT = Z16_ETQPAL "
	_cQuery += " WHERE "+ RetSqlCond("Z17") 
	_cQuery += " AND Z17_ETQPLT IN ("+ _cEtqPlt +")" 
	_cQuery += " ORDER BY Z17.Z17_DTINI, Z17_HRINI,Z17.R_E_C_N_O_ " 	

	memowrit("C:\query\twmsv012_sfAtuMov.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQuery,_aStruMov,_cAlMov)

	// abre o arquivo de trabalho
	(_cAlMov)->(dbSelectArea(_cAlMov))
	(_cAlMov)->(dbGoTop())

Return
