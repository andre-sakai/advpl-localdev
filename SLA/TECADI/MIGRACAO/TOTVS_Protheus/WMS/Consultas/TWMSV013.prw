#include 'protheus.ch'
#include 'parmtype.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina de "Saldo Por Etiqueta Tecadi"                   !
!                  !                                                         !
!                  ! Possibilita ao usuário ter uma visão ampla, completa e  !
!                  ! facil de todo o saldo, endereços, notas fiscais         !
!                  ! e demais análises pertinentes de uma                    !
!                  ! determinada etiqueta Tecadi no WMS                      !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schumann            ! Data de Criacao ! 08/2019 !
+------------------+--------------------------------------------------------*/

user function TWMSV013()

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
	private _aFolders := {'Produtos e saldos da Etiqueta','Utilização em Ordens Serv.','Movimentação Interna da Etiqueta','Etiquetas de Clientes Vinculadas'}

	// fontes utilizadas
	private _oFnt01 := TFont():New("Tahoma",,18,,.t.)

	// legenda da grid de endereços
	private _aCorEnd := {}

	private lAchou := .T.

	// variáveis para info etiqueta
	private _cProduto	:= ''
	private _cProDesc	:= ''
	private _cEtqPlt	:= ''
	//private _cEtqCli	:= ''
	private _cOrigem	:= ''
	private _cPltOri	:= ''
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

	// Aba produtos e saldos
	private _aHeadSld := {}
	private _cTrabSld
	private _aStruSld := {}
	private _oBrwSld
	private _cAlSld   := GetNextAlias()

	// Aba utilização em ordens serviço
	private _aHeadOS := {}
	private _cTrabOS
	private _aStruOS := {}
	private _oBrwOS
	private _cAlOS   := GetNextAlias()

	// Aba movimentação de etiquetas
	private _aHeadMov := {}
	private _cTrabMov
	private _aStruMov := {}
	private _oBrwMov
	private _cAlMov   := GetNextAlias()

	// Aba etiquetas clientes vinculadas
	private _aHeadCli := {}
	private _cTrabCli
	private _aStruCli := {}
	private _oBrwCli
	private _cAlCli   := GetNextAlias()

	// objetos para exibir composição do porta-pallet
	private _oSayRua, _oSayLado, _oSayPred, _oSayNivel, _oSaySeq, _oGrPP

	// variáveis gerais
	private cCadastro := "Saldo Por Etiqueta - v 1.0"
	private _cEtiqueta := CriaVar("Z56_CODETI", .F.)

	// cores da legenda para endereços
	aAdd(_aCorEnd, {"(_cAlOS)->STATUS == 'FI'","BR_VERDE"})		// Finalizada
	aAdd(_aCorEnd, {"(_cAlOS)->STATUS == 'AG'","BR_PINK"})		// Agendado
	aAdd(_aCorEnd, {"(_cAlOS)->STATUS == 'AN'","BR_AMARELO"})	// Analise
	aAdd(_aCorEnd, {"(_cAlOS)->STATUS == 'BL'","BR_VERMELHO"})	// Bloqueada
	aAdd(_aCorEnd, {"(_cAlOS)->STATUS == 'EX'","BR_PRETO_0"})	// Execucao
	aAdd(_aCorEnd, {"(_cAlOS)->STATUS == 'IN'","BR_MARROM"})	// Interrompida
	aAdd(_aCorEnd, {"(_cAlOS)->STATUS == 'PL'","BR_CINZA"})		// Planejada
	aAdd(_aCorEnd, {"(_cAlOS)->STATUS == 'CA'","BR_CANCEL"})	// Cancelada

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
		_oSayProd := TSay():New(007,005,{||"Cód. Etiq. Tecadi:"},_oPnlCab,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGetProd := TGet():New(005,080,{|u| If(PCount()>0,_cEtiqueta:=u,_cEtiqueta)},_oPnlCab,100,012,PesqPict("Z56","Z56_CODETI"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtiqueta",,)

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
		//_oSNFEnt := TSay():New(033,005,{||"Etiq. Tecadi Atrelada:"},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)
		//_oGNFEnt := TGet():New(035,180,{|u| If(PCount()>0,_cEtqCli:=u,_cEtqTec)},_oPnlEtiq,100,012,PesqPict("Z11","Z11_CODETI"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cEtqTec",,)

		// lote
		_oSNFEnt := TSay():New(033,005,{||"Lote:"},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGNFEnt := TGet():New(035,180,{|u| If(PCount()>0,_cLote:=u,_cLote)},_oPnlEtiq,100,012,PesqPict("Z16","Z16_LOTCTL"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cLote",,)

		// nf de entrada
		_oSNFEnt := TSay():New(048,005,{||"Nota fiscal atrelada:"},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGNFEnt := TGet():New(050,180,{|u| If(PCount()>0,_cNFEnt:=u,_cNFEnt)},_oPnlEtiq,70,012,PesqPict("SD1","D1_DOC"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cNFEnt",,)

		// serie de entrada
		_oSSerEnt := TSay():New(063,005,{||"Série NF atrelada:"},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGSerEnt := TGet():New(065,180,{|u| If(PCount()>0,_cSerEnt:=u,_cSerEnt)},_oPnlEtiq,70,012,PesqPict("SD1","D1_SERIE"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cSerEnt",,)

		// endereço
		_oSEnder := TSay():New(078,005,{||"Cód. Endereço:"},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGEnder := TGet():New(080,180,{|u| If(PCount()>0,_cEnder:=u,_cEnder)},_oPnlEtiq,100,012,PesqPict("Z16","Z16_ENDATU"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cEnder",,)

		// saldo lógico
		_oSSldLog := TSay():New(093,005,{||"Saldo:"},_oPnlEtiq,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGSldLog := TGet():New(095,180,{|u| If(PCount()>0,_nSldLog:=u,_nSldLog)},_oPnlEtiq,70,012,PesqPict("Z16","Z16_SALDO"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nSldLog",,)

		// ativa a tela
		ACTIVATE MSDIALOG _oDlg CENTERED

	EndIf

	If ValType(_cTrabMov) == "O"
		_cTrabMov:Delete()
	EndIf

	If ValType(_cTrabOS) == "O"
		_cTrabOS:Delete()
	EndIf

	If ValType(_cTrabCli) == "O"
		_cTrabCli:Delete()
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
		sfAtuMov(mvFirst),;
		sfAtuOS(mvFirst),;
		sfAtuCli(mvFirst),;
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

		// browse com a listagem produtos e saldos
		_oBrwSld := MsSelect():New((_cAlSld),,,_aHeadSld,,,{001,001,400,1000},,,_oFolder:aDialogs[1])
		_oBrwSld:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// painel de cabeçalho
		_oPnlEnd := TPanel():New(000,000,nil,_oFolder:aDialogs[2],,.F.,.F.,,,00,26,.T.,.F. )
		_oPnlEnd:Align:= CONTROL_ALIGN_TOP

		//Botão legenda do endereço
		_oBtLegEnd := TBtnBmp2():New(005,010,040,040,"COLOR",,,,{|| sfLegEnd() },_oPnlEnd,"Legenda",,.T. )
		_oBtLegEnd:Align := CONTROL_ALIGN_LEFT

		// browse com a listagem utilizações em ordens serviço
		_oBrwOS := MsSelect():New((_cAlOS),,,_aHeadOS,,,{001,001,400,1000},,,_oFolder:aDialogs[2],, _aCorEnd)
		_oBrwOS:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// browse com a listagem das movimentações da etqiueta
		_oBrwMov := MsSelect():New((_cAlMov),,,_aHeadMov,,,{001,001,400,1000},,,_oFolder:aDialogs[3])
		_oBrwMov:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// browse com a listagem das etiquetas de clientes vinculadas
		_oBrwCli := MsSelect():New((_cAlCli),,,_aHeadCli,,,{001,001,400,1000},,,_oFolder:aDialogs[4])
		_oBrwCli:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// refresh do browse
		If (_oBrwSld <> nil)
			_oBrwSld:oBrowse:GoTop()
			_oBrwSld:oBrowse:Refresh()
		EndIf

		// refresh do browse
		If (_oBrwMov <> nil)
			_oBrwMov:oBrowse:Refresh()
		EndIf

		// refresh do browse
		If (_oBrwOS <> nil)
			_oBrwOS:oBrowse:Refresh()
		EndIf

		// refresh do browse
		If (_oBrwCli <> nil)
			_oBrwCli:oBrowse:Refresh()
		EndIf

	EndIf

Return lAchou

// ** funcao que retorna as informações principais da etiqueta
Static Function sfAtuInfo()
	local _cQuery
	local _aEtiqueta
	//Local _lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.F.,.F.,Nil, mvCli, mvLj, Nil, Nil)
	_aStruSld := {}
	_aHeadSld := {}
	aAdd(_aStruSld,{"Z16_CODPRO","C", TamSx3("Z16_CODPRO")[1], 0}); aAdd(_aHeadSld,{"Z16_CODPRO","","Codigo Produto",PesqPict("Z16","Z16_CODPRO")})
	aAdd(_aStruSld,{"B1_DESC"   ,"C", TamSx3("B1_DESC")	  [1], 0}); aAdd(_aHeadSld,{"B1_DESC"   ,"","Descrição",PesqPict("SB1","B1_DESC")})
	aAdd(_aStruSld,{"Z16_LOTCTL","C", TamSx3("Z16_LOTCTL")[1], 0}); aAdd(_aHeadSld,{"Z16_LOTCTL","","Lote",PesqPict("Z16","Z16_LOTCTL")})
	aAdd(_aStruSld,{"D1_DOC"	,"C", TamSx3("D1_DOC")	  [1], 0}); aAdd(_aHeadSld,{"D1_DOC"	,"","Nota Fiscal Atrelada",PesqPict("Z11","D1_DOC")})
	aAdd(_aStruSld,{"D1_SERIE"	,"C", TamSx3("D1_SERIE") [1], 0}); aAdd(_aHeadSld,{"D1_SERIE"	,"","Serie",PesqPict("Z11","D1_SERIE")})
	aAdd(_aStruSld,{"Z16_SALDO"	,"N", TamSx3("Z16_SALDO")[1], TamSx3("Z16_SALDO")[2]}); aAdd(_aHeadSld,{"Z16_SALDO","","Saldo",PesqPict("Z16","Z16_SALDO")})

	// fecha alias do TRB
	If (Select(_cAlSld) <> 0)
		dbSelectArea(_cAlSld)
		dbCloseArea()
	EndIf

	// criar um arquivo de trabalho
	_cTrabSld := FWTemporaryTable():New( _cAlSld )
	_cTrabSld:SetFields( _aStruSld )
	_cTrabSld:Create()

	// limpa o conteudo do TRB
	(_cAlSld)->(dbSelectArea(_cAlSld))
	(_cAlSld)->(__DbZap())

	dbSelectArea("Z11")
	dbSetOrder(1)
	IF !dbSeek(xFilial("Z11")+_cEtiqueta)
		MsgAlert("Etiqueta não encontrada! Favor verificar!")
		Return
	EndIf

	// Z16_ETQPAL -> Z16_ETQPRD/Z16_ETQVOL -> Z56_CODETI
	_cQuery := " SELECT "

	If Z11->Z11_TIPO == "01" // Se for etiqueta de Produto
		_cQuery += " Z16_ETQPRD as ETIQ,Z16_CODPRO as PROD "
	ElseIf Z11->Z11_TIPO == "04" // Se for etiqueta de Volume
		_cQuery += " Z16_ETQVOL as ETIQ,Z16_CODPRO as PROD  "
	Else
		MsgAlert("Tipo de etiqueta incorreta para esta consulta!")
		Return
	EndIf

	_cQuery += " FROM "+RetSQLName("Z16")+" Z16 (nolock) "
	_cQuery += "     inner join "+RetSQLName("SB1")+" SB1 (nolock) "
	_cQuery += "     on SB1.D_E_L_E_T_ = '' "
	_cQuery += "     and B1_COD = Z16_CODPRO "
	_cQuery += " where Z16.D_E_L_E_T_ = '' "
	_cQuery += " and Z16_FILIAL = '"+xFilial("Z16")+"' "

	If Z11->Z11_TIPO == "01" // Se for etiqueta de Produto
		_cQuery += " and Z16_ETQPRD = '"+_cEtiqueta+"' "
	ElseIf Z11->Z11_TIPO == "04" // Se for etiqueta de Volume
		_cQuery += " and Z16_ETQVOL = '"+_cEtiqueta+"' "
	EndIf

	_aEtiqueta := U_SqlToVet(_cQuery)

	memowrit("C:\query\TWMSV013_sfAtuInfo_1.txt",_cQuery)

	If Empty(_aEtiqueta)
		MsgAlert("O tipo da etiqueta está divergente entre os registros de Etiqueta e Produto/Volume!")
		Return
	EndIf

	_cQuery := " SELECT top 1 "
	_cQuery += " Z11_FILIAL,  "
	_cQuery += " Z11_CODETI,  "
	_cQuery += " Z16_ORIGEM,  "
	_cQuery += " Z16_PLTORI,  "
	_cQuery += " Z16_ETQPAL,  "
	_cQuery += " CASE WHEN Z16_PRDORI = ''  "
	_cQuery += " 	  THEN Z16_VOLORI  "
	_cQuery += " 	  ELSE Z16_PRDORI  "
	_cQuery += " END AS Z16_ORI,  "
	_cQuery += " Z16_CODPRO, "
	_cQuery += " B1_DESC,  "
	_cQuery += " Z16_LOTCTL, "
	If Z11->Z11_TIPO == "01" // Se for etiqueta de Produto
		_cQuery += " Z11_DOC as DOC, "
		_cQuery += " Z11_SERIE as SERIE, "
	ElseIf Z11->Z11_TIPO == "04" // Se for etiqueta de Volume
		_cQuery += " D1_DOC as DOC, "
		_cQuery += " D1_SERIE as SERIE, "
	EndIf
	_cQuery += " Z16_SALDO,  "
	_cQuery += " Z16_ENDATU,  "
	_cQuery += " Z16_LOCAL,  "
	_cQuery += " Z16_LOTCTL,  "
	_cQuery += " Z16_VLDLOT,  "
	_cQuery += " BE_STATUS,  "
	_cQuery += " Substring(BE_LOCALIZ, 1, 2) AS RUA,  "
	_cQuery += " Substring(BE_LOCALIZ, 3, 1) AS LADO,   "
	_cQuery += " Substring(BE_LOCALIZ, 4, 2) AS PREDIO,   "
	_cQuery += " Substring(BE_LOCALIZ, 6, 2) AS NIVEL,  "
	_cQuery += " Substring(BE_LOCALIZ, 8, 5) AS SEQUENCIA   "
	_cQuery += " FROM "+RetSQLName("Z16")+" Z16 (nolock) "
	_cQuery += " LEFT JOIN "+RetSQLName("Z11")+" Z11 (nolock)  "
	_cQuery += " 	ON Z11.D_E_L_E_T_ = ' ' "
	_cQuery += "	 and Z11_FILIAL = Z16_FILIAL "
	If Z11->Z11_TIPO == "01" // Se for etiqueta de Produto
		_cQuery += " AND Z11_CODETI = Z16_ETQPRD "
	ElseIf Z11->Z11_TIPO == "04" // Se for etiqueta de Volume
		_cQuery += " AND Z11_CODETI =  Z16_ETQVOL "
	EndIf
	_cQuery += " LEFT JOIN "+RetSQLName("SBE")+" SBE (nolock)  "
	_cQuery += " 	ON SBE.D_E_L_E_T_ = ' ' "
	_cQuery += " 	AND Z16_LOCAL = BE_LOCAL  "
	_cQuery += " 	AND Z16_ENDATU = BE_LOCALIZ  "
	_cQuery += " LEFT JOIN "+RetSQLName("SB1")+" SB1 (nolock)  "
	_cQuery += " 	ON SB1.D_E_L_E_T_ = ' ' "
	_cQuery += " 	AND Z16_CODPRO = B1_COD  "
	If Z11->Z11_TIPO == "04" // Se for etiqueta de Volume
		_cQuery += "  LEFT JOIN "+RetSQLName("SD1")+" SD1 (nolock) "
		_cQuery += "             on SD1.D_E_L_E_T_ = '' "
		_cQuery += "             and D1_FILIAL = Z16_FILIAL "
		_cQuery += "             and D1_COD = Z16_CODPRO "
		_cQuery += "             and D1_NUMSEQ = Z16_NUMSEQ "
	EndIf
	_cQuery += " WHERE  Z16.D_E_L_E_T_ = ' ' "
	_cQuery += " AND Z16_FILIAL = '"+xFilial("Z16")+"' "
	If Z11->Z11_TIPO == "01" // Se for etiqueta de Produto
		_cQuery += " and Z16_ETQPRD = '"+_cEtiqueta+"' "
	ElseIf Z11->Z11_TIPO == "04" // Se for etiqueta de Volume
		_cQuery += " and Z16_ETQVOL = '"+_cEtiqueta+"' "
	EndIf
	_cQuery += " order by Z16.R_E_C_N_O_ desc "

	memowrit("C:\query\TWMSV013_sfAtuInfo_2.txt",_cQuery)

	// verifica se o alias da query existe
	If (Select("_QRYETQ") != 0)
		dbSelectArea("_QRYETQ")
		dbCloseArea()
	Endif
	// executa a query
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),"_QRYETQ",.F.,.T.)
	DbSelectArea("_QRYETQ")

	_cProduto	:= _QRYETQ->Z16_CODPRO
	_cProDesc	:= _QRYETQ->B1_DESC
	_cEtqTec	:= _QRYETQ->Z11_CODETI
	_cEtqPlt	:= _QRYETQ->Z16_ETQPAL
	_cOrigem	:= _QRYETQ->Z16_ORIGEM
	_cPltOri	:= _QRYETQ->Z16_PLTORI
	_cNFEnt		:= _QRYETQ->DOC
	_cSerEnt	:= _QRYETQ->SERIE
	_cLote		:= _QRYETQ->Z16_LOTCTL
	_cEnder		:= _QRYETQ->Z16_ENDATU
	_nSldLog	:= _QRYETQ->Z16_SALDO
	_cRua		:= _QRYETQ->RUA
	_cLado		:= _QRYETQ->LADO
	_cPredio	:= _QRYETQ->PREDIO
	_cNivel		:= _QRYETQ->NIVEL
	_cSeque		:= _QRYETQ->SEQUENCIA

	_cEtqPlt := "'"+_cEtqPlt+"'"

	_QRYETQ->(DBGoTop())

	While !_QRYETQ->(EOF())
		(_cAlSld)->(dbSelectArea(_cAlSld))
		(_cAlSld)->(RecLock(_cAlSld,.t.))
		(_cAlSld)->Z16_CODPRO	:= _QRYETQ->Z16_CODPRO
		(_cAlSld)->B1_DESC		:= _QRYETQ->B1_DESC
		(_cAlSld)->Z16_LOTCTL	:= _QRYETQ->Z16_LOTCTL
		(_cAlSld)->D1_DOC		:= _QRYETQ->DOC
		(_cAlSld)->D1_SERIE	:= _QRYETQ->SERIE
		(_cAlSld)->Z16_SALDO	:= _QRYETQ->Z16_SALDO
		(_cAlSld)->(MsUnLock())
		_QRYETQ->(DBSkip())
	EndDo

	_QRYETQ->(DBGoTop())

	//	Do While !(Empty(_cPltOri))
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

	memowrit("C:\query\TWMSV013_sfAtuInfo_3.txt",_cQuery)

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
	//	EndDo

Return .T.

// ** funcao que apresenta a legenda para a aba de endereços
Static Function sfLegEnd()

	Local _aCores := {}

	// inclui opcoes e cores do status
	aAdd(_aCores,{"BR_VERDE"	,"Finalizada"})
	aAdd(_aCores,{"BR_PINK",	"Agendado"})
	aAdd(_aCores,{"BR_AMARELO",	"Analise"})
	aAdd(_aCores,{"BR_VERMELHO","Bloqueada"})
	aAdd(_aCores,{"BR_PRETO_0",	"Execucao"})
	aAdd(_aCores,{"BR_MARROM",	"Interrompida"})
	aAdd(_aCores,{"BR_CINZA",	"Planejada"})
	aAdd(_aCores,{"BR_CANCEL",	"Cancelada"})

	// funcao padrao para apresentar as legendas
	BrwLegenda(cCadastro,"Legenda para endereços",_aCores)

Return NIL

Static Function sfAtuMov(mvFirst)
	local 	_cQuery

	If (mvFirst)
		// monta a estrutura do arquivo de trabalho
		_aStruMov := {}
		_aHeadMov := {}
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

	_cQuery := " SELECT DISTINCT Z17_ENDORI, "
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
	_cQuery += " LEFT JOIN "+ RetSqlTab("DCD") +" (nolock) "
	_cQuery += " 	ON "+ RetSqlCond("DCD")
	_cQuery += " 	AND Z17.Z17_OPERAD = DCD.DCD_CODFUN "
	_cQuery += " LEFT JOIN "+ RetSqlTab("Z16") +"(nolock) "
	_cQuery += " 	ON "+ RetSqlCond("Z16")
	_cQuery += "	AND Z17_ETQPLT = Z16_ETQPAL "
	_cQuery += " WHERE "+ RetSqlCond("Z17")
	_cQuery += " AND Z17_ETQPLT IN ("+ _cEtqPlt +")"
	_cQuery += " ORDER BY Z17.Z17_DTINI, Z17.Z17_HRINI"

	memowrit("C:\query\TWMSV013_sfAtuMov.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQuery,_aStruMov,_cAlMov)

	// abre o arquivo de trabalho
	(_cAlMov)->(dbSelectArea(_cAlMov))
	(_cAlMov)->(dbGoTop())

Return

Static Function sfAtuOS(mvFirst)
	local 	_cQuery

	If (mvFirst)
		// monta a estrutura do arquivo de trabalho
		_aStruOS := {}
		_aHeadOS := {}
		aAdd(_aStruOS,{"Z06_NUMOS","C",	TamSx3("Z06_NUMOS")[1],	0});aAdd(_aHeadOS,{"Z06_NUMOS",	"","Numero OS",	PesqPict("Z06","Z06_NUMOS")})
		aAdd(_aStruOS,{"Z06_SEQOS","C",	TamSx3("Z06_SEQOS")[1],	0});aAdd(_aHeadOS,{"Z06_SEQOS",	"","Seq OS",	PesqPict("Z06","Z06_SEQOS")})
		aAdd(_aStruOS,{"SERVICO","C",	TamSx3("X5_DESCRI")[1],	0});aAdd(_aHeadOS,{"SERVICO",	"","Servico" ,	PesqPict("SX5","X5_DESCRI")})
		aAdd(_aStruOS,{"TAREFA","C",	TamSx3("X5_DESCRI")[1],	0});aAdd(_aHeadOS,{"TAREFA",	"","Tarefa",	PesqPict("SX5","X5_DESCRI")})
		aAdd(_aStruOS,{"STATUS_MOV","C",TamSx3("X5_DESCRI")[1],	0});aAdd(_aHeadOS,{"STATUS_MOV","","Status Mov.",PesqPict("SX5","X5_DESCRI")})
		aAdd(_aStruOS,{"EMISSAO","C",	10,						0});aAdd(_aHeadOS,{"EMISSAO",	"","Emissao",	PesqPict("Z06","Z06_NUMOS")})
		aAdd(_aStruOS,{"DTINICIO","C",	10,						0});aAdd(_aHeadOS,{"DTINICIO",	"","Data Inicio",PesqPict("Z06","Z06_SEQOS")})
		aAdd(_aStruOS,{"DTFIM","C",		10,						0});aAdd(_aHeadOS,{"DTFIM",		"","Data Fim",	PesqPict("Z06","Z06_NUMOS")})
		aAdd(_aStruOS,{"OPERADOR","C",	TamSx3("DCD_NOMFUN")[1],0});aAdd(_aHeadOS,{"OPERADOR",	"","Operador",	PesqPict("DCD","DCD_NOMFUN")})
		aAdd(_aStruOS,{"STATUS"  ,"C",	2,						0})

		// fecha alias do TRB
		If (Select(_cAlOS) <> 0)
			dbSelectArea(_cAlOS)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrabOS := FWTemporaryTable():New( _cAlOS )
		_cTrabOS:SetFields( _aStruOS )
		_cTrabOS:Create()
	EndIf

	// limpa o conteudo do TRB
	(_cAlOS)->(dbSelectArea(_cAlOS))
	(_cAlOS)->(__DbZap())

	_cQuery := " SELECT Z06_NUMOS, Z06_SEQOS, "
	_cQuery += "        Upper(SX5SRV.X5_DESCRI) AS 'SERVICO', "
	_cQuery += "        Upper(SX5TRF.X5_DESCRI) AS 'TAREFA', "
	_cQuery += "        CASE "
	_cQuery += "          WHEN Z07_STATUS = 'F' THEN 'FINALIZADO' "
	_cQuery += "          WHEN Z07_STATUS = 'A' THEN 'ARMAZENADO' "
	_cQuery += "          WHEN Z07_STATUS = 'M' THEN 'MOVIMENTO' "
	_cQuery += "          WHEN Z07_STATUS = 'R' THEN 'REALIZADO' "
	_cQuery += "          WHEN Z07_STATUS = 'P' THEN 'PENDENTE' "
	_cQuery += "          WHEN Z07_STATUS = 'D' THEN 'DISPONÍVEL' "
	_cQuery += "        END                     AS 'STATUS_MOV', "
	_cQuery += "        Z06_STATUS              AS 'STATUS', "
	_cQuery += "        CASE "
	_cQuery += "          WHEN Z06.Z06_DTEMIS = '' THEN '' "
	_cQuery += "          ELSE CONVERT (VARCHAR, CONVERT(DATETIME, Z06.Z06_DTEMIS, 110), 103) "
	_cQuery += "        END                     AS 'EMISSAO', "
	_cQuery += "        CASE "
	_cQuery += "          WHEN Z06.Z06_DTINIC = '' THEN '' "
	_cQuery += "          ELSE CONVERT (VARCHAR, CONVERT(DATETIME, Z06.Z06_DTINIC, 110), 103) "
	_cQuery += "        END                     AS 'DTINICIO', "
	_cQuery += "        CASE "
	_cQuery += "          WHEN Z06.Z06_DTFIM = '' THEN '' "
	_cQuery += "          ELSE CONVERT (VARCHAR, CONVERT(DATETIME, Z06.Z06_DTFIM, 110), 103) "
	_cQuery += "        END                     AS 'DTFIM', "
	_cQuery += "        DCD_NOMFUN AS 'OPERADOR', "
	_cQuery += "        Z07.R_E_C_N_O_ AS 'TBLRECNO' "
	_cQuery += " FROM   "+RetSQLName("Z07")+" Z07 (Nolock) "
	_cQuery += "        INNER JOIN "+RetSQLName("Z06")+" Z06 (Nolock)  "
	_cQuery += "                ON Z06.Z06_FILIAL = Z07.Z07_FILIAL "
	_cQuery += "                   AND Z06.Z06_NUMOS = Z07.Z07_NUMOS "
	_cQuery += "                   AND Z06.D_E_L_E_T_ = '' "
	_cQuery += "                   AND Z06.Z06_SEQOS = Z07.Z07_SEQOS "
	_cQuery += "        INNER JOIN "+RetSQLName("SX5")+" SX5SRV (Nolock)  "
	_cQuery += "                ON ( SX5SRV.X5_TABELA = 'L4' "
	_cQuery += "                     AND SX5SRV.X5_CHAVE = Z06.Z06_SERVIC ) "
	_cQuery += "        INNER JOIN "+RetSQLName("SX5")+" SX5TRF (Nolock)  "
	_cQuery += "                ON ( SX5TRF.X5_TABELA = 'L2' "
	_cQuery += "                     AND SX5TRF.X5_CHAVE = Z06.Z06_TAREFA ) "
	_cQuery += "        INNER JOIN "+RetSQLName("DCD")+" DCD (Nolock)  "
	_cQuery += "                ON ( DCD.DCD_CODFUN = Z07.Z07_USUARI "
	_cQuery += "                      OR DCD.DCD_CODFUN = Z06.Z06_USUARI ) "
	_cQuery += " WHERE " + RetSqlCond("Z07")
	_cQuery += "        AND Z07.Z07_PRODUT = '"+_cProduto+"' "
	_cQuery += "        AND CASE "
	_cQuery += "              WHEN Z07.Z07_ETQVOL = '' THEN Z07.Z07_ETQPRD "
	_cQuery += "              ELSE Z07.Z07_ETQVOL "
	_cQuery += "            END = '"+_cEtiqueta+"' "
	if (_cOrigem != "VOL")
		_cQuery += " UNION ALL "
		_cQuery += " SELECT Z06_NUMOS, Z06_SEQOS, "
		_cQuery += "        Upper(SX5SRV.X5_DESCRI) AS 'SERVICO', "
		_cQuery += "        Upper(SX5TRF.X5_DESCRI) AS 'TAREFA', "
		_cQuery += "        CASE "
		_cQuery += "          WHEN Z08_STATUS = 'F' THEN 'FINALIZADO' "
		_cQuery += "          WHEN Z08_STATUS = 'A' THEN 'ARMAZENADO' "
		_cQuery += "          WHEN Z08_STATUS = 'M' THEN 'MOVIMENTO' "
		_cQuery += "          WHEN Z08_STATUS = 'R' THEN 'REALIZADO' "
		_cQuery += "          WHEN Z08_STATUS = 'P' THEN 'PENDENTE' "
		_cQuery += "          WHEN Z08_STATUS = 'D' THEN 'DISPONÍVEL' "
		_cQuery += "        END                     AS 'STATUS_MOV', "
		_cQuery += "        Z06_STATUS              AS 'STATUS', "
		_cQuery += "        CASE "
		_cQuery += "          WHEN Z06.Z06_DTEMIS = '' THEN '' "
		_cQuery += "          ELSE CONVERT (VARCHAR, CONVERT(DATETIME, Z06.Z06_DTEMIS, 110), 103) "
		_cQuery += "        END                     AS 'EMISSAO', "
		_cQuery += "        CASE "
		_cQuery += "          WHEN Z06.Z06_DTINIC = '' THEN '' "
		_cQuery += "          ELSE CONVERT (VARCHAR, CONVERT(DATETIME, Z06.Z06_DTINIC, 110), 103) "
		_cQuery += "        END                     AS 'DTINICIO', "
		_cQuery += "        CASE "
		_cQuery += "          WHEN Z06.Z06_DTFIM = '' THEN '' "
		_cQuery += "          ELSE CONVERT (VARCHAR, CONVERT(DATETIME, Z06.Z06_DTFIM, 110), 103) "
		_cQuery += "        END                     AS 'DTFIM', "
		_cQuery += "        DCD_NOMFUN AS 'OPERADOR', "
		_cQuery += "        Z08.R_E_C_N_O_ AS 'TBLRECNO' "
		_cQuery += " FROM   " + RetSQLName("Z08") + " Z08 (Nolock)  "
		_cQuery += "        INNER JOIN "+RetSQLName("Z06")+" Z06 (Nolock)  "
		_cQuery += "                ON " + RetSqlCond("Z06")
		_cQuery += "                   AND Z06.Z06_NUMOS = Z08.Z08_NUMOS "
		_cQuery += "                   AND Z06.D_E_L_E_T_ = '' "
		_cQuery += "                   AND Z06.Z06_SEQOS = Z08.Z08_SEQOS "
		_cQuery += "                   AND Z06.Z06_SERVIC = Z08.Z08_SERVIC "
		_cQuery += "        INNER JOIN "+RetSQLName("SX5")+" SX5SRV  (Nolock) "
		_cQuery += "                ON ( SX5SRV.X5_TABELA = 'L4' "
		_cQuery += "                     AND SX5SRV.X5_CHAVE = Z06.Z06_SERVIC ) "
		_cQuery += "        INNER JOIN "+RetSQLName("SX5")+" SX5TRF (Nolock)  "
		_cQuery += "                ON ( SX5TRF.X5_TABELA = 'L2' "
		_cQuery += "                     AND SX5TRF.X5_CHAVE = Z06.Z06_TAREFA ) "
		_cQuery += "        INNER JOIN "+RetSQLName("DCD")+" DCD (Nolock)  "
		_cQuery += "                ON ( DCD.DCD_CODFUN = Z08.Z08_USUARI "
		_cQuery += "                      OR DCD.DCD_CODFUN = Z06.Z06_USUARI ) "
		_cQuery += " WHERE "  + RetSqlCond("Z08")
		_cQuery += "        AND Z08.Z08_PRODUT = '"+_cProduto+"' "
		If Empty(_cPltOri)
			_cQuery += " and (Z08_PALLET in ("+_cEtqPlt+") or Z08_NEWPLT in ("+_cEtqPlt+")) "
		Else
			_cQuery += " and (Z08_PALLET in ("+_cPltOri+") or Z08_NEWPLT in ("+_cPltOri+")) "
		EndIf
	EndIf
	_cQuery += " ORDER  BY 1, Z06_SEQOS"

	memowrit("C:\query\TWMSV013_sfAtuOS.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQuery,_aStruOS,_cAlOS)

	// abre o arquivo de trabalho
	(_cAlOS)->(dbSelectArea(_cAlOS))
	(_cAlOS)->(dbGoTop())

Return

Static Function sfAtuCli(mvFirst)
	local 	_cQuery

	If (mvFirst)
		// monta a estrutura do arquivo de trabalho
		_aStruCli := {}
		_aHeadCli := {}
		aAdd(_aStruCli,{"Z56_ETQCLI","C", TamSx3("Z56_ETQCLI")[1], 0}); aAdd(_aHeadCli,{"Z56_ETQCLI","","Etiqueta Cliente",PesqPict("Z56","Z56_ETQCLI")})
		aAdd(_aStruCli,{"Z56_CODPRO","C", TamSx3("Z56_CODPRO")[1], 0}); aAdd(_aHeadCli,{"Z56_CODPRO","","Produto",PesqPict("Z56","Z56_CODPRO")})
		aAdd(_aStruCli,{"Z56_NOTA","C", TamSx3("Z56_NOTA")[1], 0}); aAdd(_aHeadCli,{"Z56_NOTA","","Nota Fiscal",PesqPict("Z56","Z56_NOTA")})
		aAdd(_aStruCli,{"Z56_SERIE","C", TamSx3("Z56_SERIE")[1], 0}); aAdd(_aHeadCli,{"Z56_SERIE","","Serie NF",PesqPict("Z56","Z56_SERIE")})
		aAdd(_aStruCli,{"Z56_ITEMNF","C", TamSx3("Z56_ITEMNF")[1], 0}); aAdd(_aHeadCli,{"Z56_ITEMNF","","Item NF",PesqPict("Z56","Z56_ITEMNF")})
		aAdd(_aStruCli,{"Z56_OK_ENT","C", TamSx3("Z56_OK_ENT")[1], 0}); aAdd(_aHeadCli,{"Z56_OK_ENT","","Entrada",PesqPict("Z56","Z56_OK_ENT")})
		aAdd(_aStruCli,{"Z56_OK_SAI","C", TamSx3("Z56_OK_SAI")[1], 0}); aAdd(_aHeadCli,{"Z56_OK_SAI","","Saida",PesqPict("Z56","Z56_OK_SAI")})
		aAdd(_aStruCli,{"Z56_QUANT"	,"N", TamSx3("Z56_QUANT")[1], 0}); aAdd(_aHeadCli,{"Z56_QUANT"	,"","Quantidade" ,PesqPict("Z56","Z56_QUANT")})

		// fecha alias do TRB
		If (Select(_cAlCli) <> 0)
			dbSelectArea(_cAlCli)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrabCli := FWTemporaryTable():New( _cAlCli )
		_cTrabCli:SetFields( _aStruCli )
		_cTrabCli:Create()
	EndIf

	// limpa o conteudo do TRB
	(_cAlCli)->(dbSelectArea(_cAlCli))
	(_cAlCli)->(__DbZap())

	_cQuery := " SELECT Z56_ETQCLI,Z56_CODPRO,Z56_NOTA,Z56_SERIE,Z56_ITEMNF, "
	_cQuery += " 	Case when Z56_OK_ENT = 'N' Then 'NAO' else 'SIM' End Z56_OK_ENT, "
	_cQuery += "     Case when Z56_OK_SAI = 'N' Then 'NAO' else 'SIM' End Z56_OK_SAI,Z56_QUANT "
	_cQuery += " FROM "+RetSqlName("Z56")+" (NoLock) "
	_cQuery += " where D_E_L_E_T_ = '' "
	_cQuery += " and Z56_FILIAL = '"+xFilial("Z56")+"' "
	_cQuery += " and Z56_CODETI = '"+_cEtiqueta+"' "
	_cQuery += " order by R_E_C_N_O_ desc "

	memowrit("C:\query\TWMSV013_sfAtuCli.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQuery,_aStruCli,_cAlCli)

	// abre o arquivo de trabalho
	(_cAlCli)->(dbSelectArea(_cAlCli))
	(_cAlCli)->(dbGoTop())

Return
