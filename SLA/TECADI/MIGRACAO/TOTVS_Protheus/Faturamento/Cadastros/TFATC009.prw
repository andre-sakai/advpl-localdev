#include "rwmake.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "FONT.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Cadastro de lotes dos itens do Pedido de Venda          !
+------------------+---------------------------------------------------------+
!Autor             ! Eliane (Dataroute)          ! Data de Criacao ! 09/2015 !
+------------------+--------------------------------------------------------*/

User Function TFATC009(mvMntPedido)
	// salva area atual
	local _aAreaAtu := GetArea()

	// posicao dos campos
	local _nP_Cod   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_PRODUTO"})
	local _nP_Desc  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_DESCRI" })
	local _nP_Qtd   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_QTDVEN" })
	local _nP_Ite   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ITEM"   })
	local _nP_Tes   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_TES"    })
	local _nP_NFOri := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_NFORI"  })
	local _nP_Lote  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_LOTECTL"})

	local _oFont  := TFont():New( "Arial",0,-11,,.T.,0,,700,.F.,.F.,,,,,, )
	local _nGrava := 0

	// objetos da tela
	local _oPanelTop, _oPanelCen, _oPanelBut
	local _oCbPltComp

	// controle de mapa gerado
	local _lMapaExp := U_FtMapExp(M->C5_NUM)

	// objetos da tela
	private _oDlgLote := Nil
	private _oBrwLot
	private _aHeadLo  := {}
	private _aCpoLot  := {}
	private _noBrw    := 0
	private _aCpoAlt  := {}
	private	_oGetTotal, _oGetPltSel

	// variaveis para controle de totais selecionados
	private _nQtdTotal  := 0
	private _nQtdLote   := 0
	private _nQtdPltSel := 0
	private _nQtdVolume := 0

	// posicoes do  aCols dos lotes
	private _nPosMark   := 1
	private _nPosLote   := 2
	private _nPosLocal  := 3
	private _nPosEtqPrd := 4
	private _nPosSaldo  := 5
	private _nPosEnd    := 6
	private _nPosDoc    := 7
	private _nPosSer    := 8
	private _nPosDat    := 9
	private _nPosSeq    := 10
	private _nPosPallet := 11
	private _nPosEtqVol := 12
	private _nPosCamPlt := 13
	private _nPosDelete := 0

	// variaveis do pedido
	private _cProdPV  := aCols[N,_nP_Cod]
	private _cDescPrd := aCols[N,_nP_Desc]
	private _cItemPV  := aCols[N,_nP_Ite]
	private _nQtdPV   := aCols[N,_nP_Qtd]
	private _cTES     := aCols[N,_nP_Tes]
	private _cNFOri   := aCols[N,_nP_NFOri]

	// dimensoes da tela
	private _aSizeWnd := MsAdvSize()

	// posicoes do _aLotesPV
	private _nL_Ite    := 1
	private _nL_Cod    := 2
	private _nL_Amz    := 3
	private _nL_Lot    := 4
	private _nL_End    := 5
	private _nL_Pal    := 6
	private _nL_Qtd    := 7
	private _nL_Seq    := 8
	private _nL_EtqVol := 9

	// verifica se o lote eh obrigatorio na saida da nota
	private _lLotObrSai := .f.

	// selecao de palete completo
	private _lSelPltComp := .f.

	if (M->C5_TIPO <> "N") .or. (M->C5_TIPOOPE <> "P")
		Aviso("Tecadi: TCFAT009","Tipo de pedido/operacao nao necessita informar lotes.",{"Voltar"})
		return
	endif

	if aCols[N,Len(aHeader)+1]
		Aviso("Tecadi: TCFAT009","Posicione em uma linha nao deletada.",{"Voltar"})
		return
	endif

	if empty(M->C5_CLIENTE) .or. empty(M->C5_LOJACLI)
		Aviso("Tecadi: TCFAT009","Informe cliente/loja.",{"Voltar"})
		return
	endif

	if empty(aCols[N,_nP_Cod])
		Aviso("Tecadi: TCFAT009","Informe o produto.",{"Voltar"})
		return
	endif

	// valido se a TES foi informada par amostrar a TELA
	If ( ! Empty(_cTES) ) .and. ( Empty(_cNFOri) )

		// somente para TES de Expedição
		If( Posicione( "SF4", 1, xFilial("SF4") + _cTES, "F4_TIPO" ) == "S" )

			// funcao que posta os lotes por nota fisca
			sfLstNfLote( _cProdPV )

			Return
		EndIf
	EndIf

	if empty(aCols[N,_nP_Qtd])
		Aviso("Tecadi: TCFAT009","Informe a quantidade.",{"Voltar"})
		return
	endif

	// verifica se o produto tem controle de lote
	if ( ! Rastro(aCols[N,_nP_Cod],"L") )
		Aviso("Tecadi: TCFAT009","Produto sem rastro, nao necessita informar lotes.",{"Voltar"})
		return
	endif

	// se for manutencao, valida se ja tem mapa gerado
	If (mvMntPedido).and.(_lMapaExp)
		Aviso("Tecadi: TCFAT009","Alteração do lote não permitida pois já possui mapa de expedição gerado.",{"Voltar"})
		return
	EndIf

	// verifica se o lote eh obrigatorio na saida da nota
	_lLotObrSai := U_FtWmsParam("WMS_LOTE_OBRIGATORIO_SAIDA","L",.F.,.F.,Nil, M->C5_CLIENTE, M->C5_LOJACLI, Nil, Nil)

	// valida se o lote foi informado
	If (_lLotObrSai) .and. ( Empty(aCols[N,_nP_Lote]) )
		Aviso("Tecadi: TCFAT009","Lote do produto é obrigatório para seleção de paletes/volumes.",{"Voltar"})
		return
	EndIf

	// preparacao da montagem da tela
	_oDlgLote := MSDialog():New(000,000,480,800,"[TFATC009] Selecionar Lotes",,,.F.,,,,,,.T.,,,.T. )

	// cria os paineis
	_oPanelTop := TPanel():New( 010,000,"",_oDlgLote,,.F.,.F.,,,000,030,.T.,.F. )
	_oPanelTop:Align := CONTROL_ALIGN_TOP
	_oPanelCen := TPanel():New( 040,000,"",_oDlgLote,,.F.,.F.,,,000,000,.T.,.F. )
	_oPanelCen:Align := CONTROL_ALIGN_ALLCLIENT
	_oPanelBut := TPanel():New( 300,000,"",_oDlgLote,,.F.,.F.,,,000,030,.T.,.F. )
	_oPanelBut:Align := CONTROL_ALIGN_BOTTOM

	_oSayCodPro := TSay():New(005,010,{||"Produto: "},_oPanelTop,,_oFont,.F.,.F.,.F.,.T.,,,040,008)
	_oGetCodPro := TGet():New(003,050,{|u| If(PCount()>0,_cProdPV:=u,_cProdPV)},_oPanelTop,150,010,'',  ,,,,,,.T.,"",,,.F.,.F.,,.T.,.F.,,"_cProdPV",,)

	_oSayDscPro := TSay():New(018,010,{||"Descrição: "},_oPanelTop,,_oFont,.F.,.F.,.F.,.T.,,,040,008)
	_oGetDesPro := TGet():New(016,050,{|u| If(PCount()>0,_cDescPrd:=u,_cDescPrd)},_oPanelTop,150,010,'',  ,,,,,,.T.,"",,,.F.,.F.,,.T.,.F.,,"_cDescPrd",,)

	// se for manutencao do pedido
	If (mvMntPedido)
		_oMarcar    := TButton():New( 003,240,"Marcar Todos"   ,_oPanelTop,{|| sfMarcaTudo() },060,012,,_oFont,,.T.,,"Marcar Todos"   ,,,,.F.)
		_oDesmarcar := TButton():New( 003,300,"Desmarcar Todos",_oPanelTop,{|| sfDesmarcar() },060,012,,_oFont,,.T.,,"Desmarcar Todos",,,,.F.)
		_oCbPltComp := TCheckBox():New(018,220,"Seleção de Palete Completo", {|u| If(PCount()>0,_lSelPltComp:=u,_lSelPltComp)},_oPanelTop,100,12,,,_oFont,,,,,.T.,"",, )
	EndIf

	// monta o header do browse
	sfMontaHe()

	_oBrwLot := MsNewGetDados():New(100,000,400,520,GD_UPDATE,'AllwaysTrue()','AllwaysTrue()','',_aCpoAlt,0,999,'AllwaysTrue()','','AllwaysTrue()',_oPanelCen,_aHeadLo,_aCpoLot )
	_oBrwLot:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// se for manutencao do pedido
	If (mvMntPedido)
		_oBrwLot:oBrowse:bLDblClick := {|| sfMarca() }
	EndIf

	// totais geral e paletes
	_oSayTotal  := TSay():New(008,010,{||"Qtd Total: "},_oPanelBut,,_oFont,.F.,.F.,.F.,.T.,,,040,008)
	_oGetTotal  := TGet():New(006,050,{|u| If(PCount()>0,_nQtdTotal:=u,_nQtdTotal)},_oPanelBut,060,010,PesqPict("Z16","Z16_SALDO"),,,,,,,.T.,"",,,.F.,.F.,,.T.,.F.,,"_nQtdTotal",,)
	_oSayPltSel := TSay():New(018,010,{||"Qtd Palete: "},_oPanelBut,,_oFont,.F.,.F.,.F.,.T.,,,040,008)
	_oGetPltSel := TGet():New(016,050,{|u| If(PCount()>0,_nQtdPltSel:=u,_nQtdPltSel)},_oPanelBut,060,010,PesqPict("Z16","Z16_QTDVOL"),,,,,,,.T.,"",,,.F.,.F.,,.T.,.F.,,"_nQtdPltSel",,)

	// total de lotes e volumes
	_oSayLote   := TSay():New(008,120,{||"Qtd Lotes: "},_oPanelBut,,_oFont,.F.,.F.,.F.,.T.,,,040,008)
	_oGetLote   := TGet():New(006,160,{|u| If(PCount()>0,_nQtdLote:=u,_nQtdLote)},_oPanelBut,060,010,PesqPict("Z16","Z16_QTDVOL"),,,,,,,.T.,"",,,.F.,.F.,,.T.,.F.,,"_nQtdLote",,)
	_oSayQtdVol := TSay():New(018,120,{||"Qtd Volumes: "},_oPanelBut,,_oFont,.F.,.F.,.F.,.T.,,,040,008)
	_oGetQtdVol := TGet():New(016,160,{|u| If(PCount()>0,_nQtdVolume:=u,_nQtdVolume)},_oPanelBut,060,010,PesqPict("Z16","Z16_QTDVOL"),,,,,,,.T.,"",,,.F.,.F.,,.T.,.F.,,"_nQtdVolume",,)

	// botao para confirmar
	If (mvMntPedido)
		_oConfLot := TButton():New( 010,300,"Confirmar",_oPanelBut,{|| _nGrava := sfVldConfirma(),iif(_nGrava==1,_oDlgLote:End(),"")},040,012,,_oFont,,.T.,,"Confirmar",,,,.F. )
	EndIf
	_oCancLot := TButton():New( 010,340,"Cancelar",_oPanelBut,{|| _nGrava:=0,_oDlgLote:End() },040,012,,_oFont,,.T.,,"Sair",,,,.F. )

	// atualiza os itens
	sfMontaCo(_cProdPV, mvMntPedido)

	_oDlgLote:Activate(,,,.T.)

	// se foi onfirmado, grava dados
	If ( _nGrava == 1)
		sfGrava()
	EndIf

	// restaura area inicial
	restArea(_aAreaAtu)

return

// monta aHeader
static function sfMontaHe

	_aCpoAlt := {"LOTE_MARK"}
	_aHeadLo := {}

	// coluna para selecao
	aAdd( _aHeadLo, { '', 'LOTE_MARK', '@BMP', 10, 0,,, 'C',, 'V' ,  ,  , 'mark'   , 'V', 'S' } )
	Aadd(_aHeadLo,{Trim(GetSX3Cache("Z16_LOTCTL","X3_TITULO"));
				 ,GetSX3Cache("Z16_LOTCTL","X3_CAMPO");
				 ,GetSX3Cache("Z16_LOTCTL","X3_PICTURE");
				 ,GetSX3Cache("Z16_LOTCTL","X3_TAMANHO");
				 ,GetSX3Cache("Z16_LOTCTL","X3_DECIMAL"),"","";
				 ,GetSX3Cache("Z16_LOTCTL","X3_TIPO"),"",""})
	Aadd(_aHeadLo,{Trim(GetSX3Cache("Z16_LOCAL","X3_TITULO"));
				 ,GetSX3Cache("Z16_LOCAL","X3_CAMPO");
				 ,GetSX3Cache("Z16_LOCAL","X3_PICTURE");
				 ,GetSX3Cache("Z16_LOCAL","X3_TAMANHO");
				 ,GetSX3Cache("Z16_LOCAL","X3_DECIMAL"),"","";
				 ,GetSX3Cache("Z16_LOCAL","X3_TIPO"),"",""})
	Aadd(_aHeadLo,{Trim(GetSX3Cache("Z16_ETQPRD","X3_TITULO"));
				 ,GetSX3Cache("Z16_ETQPRD","X3_CAMPO");
				 ,GetSX3Cache("Z16_ETQPRD","X3_PICTURE");
				 ,GetSX3Cache("Z16_ETQPRD","X3_TAMANHO");
				 ,GetSX3Cache("Z16_ETQPRD","X3_DECIMAL"),"","";
				 ,GetSX3Cache("Z16_ETQPRD","X3_TIPO"),"",""})
	Aadd(_aHeadLo,{Trim(GetSX3Cache("Z16_SALDO","X3_TITULO"));
				 ,GetSX3Cache("Z16_SALDO","X3_CAMPO");
				 ,GetSX3Cache("Z16_SALDO","X3_PICTURE");
				 ,GetSX3Cache("Z16_SALDO","X3_TAMANHO");
				 ,GetSX3Cache("Z16_SALDO","X3_DECIMAL"),"","";
				 ,GetSX3Cache("Z16_SALDO","X3_TIPO"),"",""})
	Aadd(_aHeadLo,{Trim(GetSX3Cache("Z16_ENDATU","X3_TITULO"));
				 ,GetSX3Cache("Z16_ENDATU","X3_CAMPO");
				 ,GetSX3Cache("Z16_ENDATU","X3_PICTURE");
				 ,GetSX3Cache("Z16_ENDATU","X3_TAMANHO");
				 ,GetSX3Cache("Z16_ENDATU","X3_DECIMAL"),"","";
				 ,GetSX3Cache("Z16_ENDATU","X3_TIPO"),"",""})
	Aadd(_aHeadLo,{Trim(GetSX3Cache("B6_DOC","X3_TITULO"));
				 ,GetSX3Cache("B6_DOC","X3_CAMPO");
				 ,GetSX3Cache("B6_DOC","X3_PICTURE");
				 ,GetSX3Cache("B6_DOC","X3_TAMANHO");
				 ,GetSX3Cache("B6_DOC","X3_DECIMAL"),"","";
				 ,GetSX3Cache("B6_DOC","X3_TIPO"),"",""})
	Aadd(_aHeadLo,{Trim(GetSX3Cache("B6_SERIE","X3_TITULO"));
				 ,GetSX3Cache("B6_SERIE","X3_CAMPO");
				 ,GetSX3Cache("B6_SERIE","X3_PICTURE");
				 ,GetSX3Cache("B6_SERIE","X3_TAMANHO");
				 ,GetSX3Cache("B6_SERIE","X3_DECIMAL"),"","";
				 ,GetSX3Cache("B6_SERIE","X3_TIPO"),"",""})
	Aadd(_aHeadLo,{Trim(GetSX3Cache("B6_EMISSAO","X3_TITULO"));
				 ,GetSX3Cache("B6_EMISSAO","X3_CAMPO");
				 ,GetSX3Cache("B6_EMISSAO","X3_PICTURE");
				 ,GetSX3Cache("B6_EMISSAO","X3_TAMANHO");
				 ,GetSX3Cache("B6_EMISSAO","X3_DECIMAL"),"","";
				 ,GetSX3Cache("B6_EMISSAO","X3_TIPO"),"",""})
	Aadd(_aHeadLo,{Trim(GetSX3Cache("Z16_NUMSEQ","X3_TITULO"));
				 ,GetSX3Cache("Z16_NUMSEQ","X3_CAMPO");
				 ,GetSX3Cache("Z16_NUMSEQ","X3_PICTURE");
				 ,GetSX3Cache("Z16_NUMSEQ","X3_TAMANHO");
				 ,GetSX3Cache("Z16_NUMSEQ","X3_DECIMAL"),"","";
				 ,GetSX3Cache("Z16_NUMSEQ","X3_TIPO"),"",""})
	Aadd(_aHeadLo,{Trim(GetSX3Cache("Z16_ETQPAL","X3_TITULO"));
				 ,GetSX3Cache("Z16_ETQPAL","X3_CAMPO");
				 ,GetSX3Cache("Z16_ETQPAL","X3_PICTURE");
				 ,GetSX3Cache("Z16_ETQPAL","X3_TAMANHO");
				 ,GetSX3Cache("Z16_ETQPAL","X3_DECIMAL"),"","";
				 ,GetSX3Cache("Z16_ETQPAL","X3_TIPO"),"",""})
	Aadd(_aHeadLo,{Trim(GetSX3Cache("Z16_ETQVOL","X3_TITULO"));
				 ,GetSX3Cache("Z16_ETQVOL","X3_CAMPO");
				 ,GetSX3Cache("Z16_ETQVOL","X3_PICTURE");
				 ,GetSX3Cache("Z16_ETQVOL","X3_TAMANHO");
				 ,GetSX3Cache("Z16_ETQVOL","X3_DECIMAL"),"","";
				 ,GetSX3Cache("Z16_ETQVOL","X3_TIPO"),"",""})
	Aadd(_aHeadLo,{Trim(GetSX3Cache("Z16_CAMPLT","X3_TITULO"));
				 ,GetSX3Cache("Z16_CAMPLT","X3_CAMPO");
				 ,GetSX3Cache("Z16_CAMPLT","X3_PICTURE");
				 ,GetSX3Cache("Z16_CAMPLT","X3_TAMANHO");
				 ,GetSX3Cache("Z16_CAMPLT","X3_DECIMAL"),"","";
				 ,GetSX3Cache("Z16_CAMPLT","X3_TIPO"),"",""})

	// atualiza posicao do campo delete
	_nPosDelete := Len(_aHeadLo)+1

return

// funcao que monta acols
static function sfMontaCo(_cProdPV, mvMntPedido)

	// variaveis temporarias
	local _cQry	:= ""
	local _cArqTmp	:= GetNextAlias()
	local _lMarca	:= .F.
	local _nY := 0
	local _lUtiliza:= .T.
	local _nPos

	// posicao dos campo
	local _nP_B6    := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_IDENTB6"})
	local _nP_Ite   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ITEM"   })
	local _nP_Lote  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_LOTECTL"})
	local _nP_TpEst := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ZTPESTO"})

	// estruturas fisicas de Picking
	local _aEstPicking := U_SqlToVet("SELECT DC8_CODEST FROM "+RetSqlTab("DC8")+" WHERE "+RetSqlCond("DC8")+" AND DC8_TPESTR = '2'")

	// estruturas fisicas disponiveis para geracao de mapa de separacao
	local _cEstFisMapa := SuperGetMv("TC_ESTFISM",.f.,"")

	// estruturas fisicas de Picking
	local _cEstPicking := ""

	// atualiza variavel de estutura fisica de picking
	aEval(_aEstPicking,{|x| _cEstPicking += (x)+"/" })

	_oBrwLot:aCols := {}

	// se for manutencao do pedido, busca lotes da Z16 relacionados a NF de remessa original, traz marcados os que ja estavam selecionados se estiver editando
	If (mvMntPedido)
		// montagem da query
		_cQry := " SELECT Z16_LOTCTL, Z16_LOCAL, Z16_SALDO, Z16_NUMSEQ, Z16_ENDATU, Z16_ETQPAL, B6_DOC, B6_SERIE, B6_EMISSAO, Z16_ETQPRD, "

		// quantidade utilizada em outros pedidos
		_cQry += " ( SELECT Isnull(Sum(Z45_QUANT), 0) FROM "+retSqlTab("Z45")
		_cQry += " 				WHERE " + RetSqlCond("Z45")
		_cQry += " 				AND Z45_ETQPAL = Z16_ETQPAL "
		_cQry += " 				AND Z45_ETQVOL = Z16_ETQVOL "
		_cQry += " 				AND Z45_PEDIDO <> '"+M->C5_NUM+"') Z45_QUANT, "
		_cQry += " 				Z16_ETQVOL, Z16_CAMPLT "

		// saldo detalhado do produto por palete
		_cQry += " FROM "+RetSqlTab("Z16")

		// saldo do produto no endereco
		_cQry += " INNER JOIN "+RetSqlTab("SBF")+" ON "+RetSqlCond("SBF")+" AND BF_LOCAL = Z16_LOCAL AND BF_LOCALIZ = Z16_ENDATU "
		// codigo do produto
		_cQry += " AND BF_PRODUTO = Z16_CODPRO "
		// lote
		_cQry += " AND BF_LOTECTL = Z16_LOTCTL "
		// estrutura fisica - porta palete e picking
		_cQry += " AND BF_ESTFIS IN "+FormatIn(_cEstFisMapa+"/"+_cEstPicking,"/")+" "

		// saldo de terceiros, por nota
		_cQry += " INNER JOIN "+RetSqlTab("SB6")+" ON "+RetSqlCond("SB6")
		_cQry += " AND B6_IDENT = '" +aCols[N,_nP_B6]+ "' "
		_cQry += " AND B6_CLIFOR = '"+M->C5_CLIENTE+"' AND B6_LOJA = '"+M->C5_LOJACLI+"' "
		_cQry += " AND B6_PODER3 = 'R' "

		// filtro padrao
		_cQry += " WHERE "+RetSqlCond("Z16")
		_cQry += "        AND Z16_CODPRO =  '"+_cProdPV+"' "
		_cQry += "        AND Z16_SALDO > 0 "
		_cQry += "        AND Z16_LOTCTL <> ' ' "
		If (_lLotObrSai)
			_cQry += "        AND Z16_LOTCTL = '" + aCols[N, _nP_Lote] + "' "
		EndIf
		_cQry += "        AND Z16_TPESTO = '" +aCols[N,_nP_TpEst]+ "' "
		// filtro de numseq (quando for subida de inventario WMS, desconsidera NumSeq)
		_cQry += "        AND ( ( Z16_ORIGEM = 'Z19' AND Z16_NUMSEQ IN ('','" +aCols[N,_nP_B6]+ "') ) OR ( Z16_ORIGEM != 'Z19' AND Z16_NUMSEQ = '"+aCols[N,_nP_B6]+"' ) ) "

		// ordem dos dados
		_cQry += " ORDER BY Z16_LOTCTL, Z16_ETQPRD, Z16_ETQPAL "

		// quando for visualizacao, busca dados armazenados
	ElseIf ( ! mvMntPedido )
		// montagem da query
		_cQry := " SELECT Z16_LOTCTL, Z16_LOCAL, Z16_SALDO, Z16_NUMSEQ, Z16_ENDATU, Z16_ETQPAL, Z16_ETQPRD, D1_DOC B6_DOC, D1_SERIE B6_SERIE, D1_EMISSAO B6_EMISSAO, 0 Z45_QUANT, Z16_ETQVOL, Z16_CAMPLT "
		// paletes selecionados
		_cQry += " FROM "+RetSqlTab("Z45")
		// pra pegar as informações corretas do pallet
		_cQry += " INNER JOIN "+RetSqlTab("Z16")+" ON Z16_ETQPAL = Z45_ETQPAL AND Z16_LOTCTL = Z45_LOTCTL AND Z16_NUMSEQ = Z45_NUMSEQ AND "+RetSqlCond("Z16")+" AND Z16_ETQVOL = Z45_ETQVOL "
		// notas de entrada pra trazer os dados da nf selecionada
		_cQry += " INNER JOIN "+RetSqlTab("SD1")+" ON D1_COD = Z45_CODPRO AND D1_NUMSEQ = Z45_NUMSEQ AND "+RetSqlCond("SD1")
		// filtro padrao
		_CQrY += " WHERE "+RetSqlCond("Z45")
		// numero do pedido
		_cQry += " AND Z45_PEDIDO = '"+M->C5_NUM+"' "
		// item do pedido
		_cQry += " AND Z45_ITEM = '"+aCols[N,_nP_Ite]+"' "
		// ordem dos dados
		_cQry += " ORDER BY Z16_LOTCTL, Z16_ETQPRD, Z16_ETQPAL "

	EndIf

	MemoWrite("c:\query\tcfat009.txt",_cQry)

	if Select(_cArqTmp) <> 0
		(_cArqTmp)->(dbCloseArea())
	endIf

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,_cQry),_cArqTmp,.T.,.T.)

	(_cArqTmp)->(dbGoTop())

	while (_cArqTmp)->(!eof())

		// reinicia variaveis
		_lUtiliza := .T.
		_lMarca   := .F.

		// verifica se o pallet e etiqueta ja foram utilizados neste item (ja existe _alotesPV e esta sendo alterado)
		_nPos := aScan(_aLotesPV,{|x| (x[_nL_Pal]==(_cArqTmp)->Z16_ETQPAL) .and. (x[_nL_Ite]==_cItemPV) .and. (x[_nL_EtqVol]==(_cArqTmp)->Z16_ETQVOL)  })

		If (_nPos > 0)
			_lMarca := .T.
		elseif (_cArqTmp)->Z16_SALDO <= (_cArqTmp)->Z45_QUANT  // verifica se o pallet tem saldo
			(_cArqTmp)->(dbSkip())
			loop
		else  // verifica se este pallet e volume foi utilizado em outro item do mesmo pedido
			for _nY := 1 to Len(_aLotesPV)
				if (_aLotesPV[_nY,_nL_Pal] == (_cArqTmp)->Z16_ETQPAL) .and. (_aLotesPV[_nY,_nL_Ite] <> _cItemPV) .and. (_aLotesPV[_nY,_nL_EtqVol] == (_cArqTmp)->Z16_ETQVOL)
					// verifica se o item do pedido nao esta deletado
					_nPos := aScan(aCols,{|x| x[_nP_Ite] == _aLotesPV[_nY,_nL_Ite]})

					if (!aCols[_nPos][Len(aHeader)+1])
						_lUtiliza := .F.
						exit
					endif
				endif
			next _nY
		endif

		if (_lMarca) .or. (_lUtiliza)

			Aadd(_oBrwLot:aCols,Array(Len(_oBrwLot:aHeader)+1))

			_oBrwLot:aCols[Len(_oBrwLot:aCols)][_nPosMark]   := IIf(_lMarca,'LBOK','LBNO')
			_oBrwLot:aCols[Len(_oBrwLot:aCols)][_nPosLote]   := (_cArqTmp)->Z16_LOTCTL
			_oBrwLot:aCols[Len(_oBrwLot:aCols)][_nPosLocal]  := (_cArqTmp)->Z16_LOCAL
			_oBrwLot:aCols[Len(_oBrwLot:aCols)][_nPosEtqPrd] := (_cArqTmp)->Z16_ETQPRD
			_oBrwLot:aCols[Len(_oBrwLot:aCols)][_nPosSaldo]  := (_cArqTmp)->Z16_SALDO-(_cArqTmp)->Z45_QUANT
			_oBrwLot:aCols[Len(_oBrwLot:aCols)][_nPosEnd]    := (_cArqTmp)->Z16_ENDATU
			_oBrwLot:aCols[Len(_oBrwLot:aCols)][_nPosDoc]    := (_cArqTmp)->B6_DOC
			_oBrwLot:aCols[Len(_oBrwLot:aCols)][_nPosSer]    := (_cArqTmp)->B6_SERIE
			_oBrwLot:aCols[Len(_oBrwLot:aCols)][_nPosDat]    := stod((_cArqTmp)->B6_EMISSAO)
			_oBrwLot:aCols[Len(_oBrwLot:aCols)][_nPosSeq]    := (_cArqTmp)->Z16_NUMSEQ
			_oBrwLot:aCols[Len(_oBrwLot:aCols)][_nPosPallet] := (_cArqTmp)->Z16_ETQPAL
			_oBrwLot:aCols[Len(_oBrwLot:aCols)][_nPosEtqVol] := (_cArqTmp)->Z16_ETQVOL
			_oBrwLot:aCols[Len(_oBrwLot:aCols)][_nPosCamPlt] := (_cArqTmp)->Z16_CAMPLT
			_oBrwLot:aCols[Len(_oBrwLot:aCols)][_nPosDelete] := .F.

		endif

		(_cArqTmp)->(dbSkip())
	enddo

	(_cArqTmp)->(dbCloseArea())

	// atualiza browse
	_oBrwLot:SetArray(_oBrwLot:aCols ,.T. )
	_oBrwLot:ForceRefresh()

	// atualiza o total
	sfAtuTotal()

return

// marcar desmarcar
static function sfMarca()
	// registro de -> ate
	local _nTmpReg := 0
	local _nRegAtu := _oBrwLot:nAt
	local _nRegDe  := IIf(_lSelPltComp, 1                  , _nRegAtu)
	local _nRegAte := IIf(_lSelPltComp, Len(_oBrwLot:aCols), _nRegAtu)
	// id do palete
	local _cTmpIdPlt := _oBrwLot:aCols[_nRegAtu, _nPosPallet]

	// varre todos os registro
	For _nTmpReg := _nRegDe to _nRegAte
		// valida condicao
		If ( ! _lSelPltComp ) .or. ((_lSelPltComp) .and. (_cTmpIdPlt == _oBrwLot:aCols[_nTmpReg, _nPosPallet]))
			// se marcado, desmarca
			if (_oBrwLot:aCols[_nTmpReg,_nPosMark] == 'LBOK')
				_oBrwLot:aCOLS[_nTmpReg,_nPosMark] := 'LBNO'
				// marca
			elseif sfValQtd(_oBrwLot:aCols[_nTmpReg,_nPosLote], _oBrwLot:aCols[_nTmpReg,_nPosLocal], _oBrwLot:aCols[_nTmpReg,_nPosSaldo], _oBrwLot:aCols[_nTmpReg,_nPosPallet],  _oBrwLot:aCols[_nTmpReg][_nPosEtqVol])
				_oBrwLot:aCOLS[_nTmpReg,_nPosMark] := 'LBOK'
			endif
		EndIf
	Next _nTmpReg

	// atualiza browse
	_oBrwLot:SetArray(_oBrwLot:aCols, .f.)
	_oBrwLot:Refresh()

	// volta posicao inicial do cursor
	_oBrwLot:GoTo(_nRegAtu)

	// atualiza o total
	sfAtuTotal()

return

// Marcar todos os itens
Static Function sfMarcaTudo()

	local _nX := 0
	local _nP_Qtd := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_QTDVEN"})


	// varre tos os itens do brwose
	For _nX:=1 to len(_oBrwLot:aCols)
		if _oBrwLot:aCols[_nX,_nPosMark]=='LBNO' .and. sfValQtd(_oBrwLot:aCols[_nX,_nPosLote],_oBrwLot:aCols[_nX,_nPosLocal],_oBrwLot:aCols[_nX,_nPosSaldo], _oBrwLot:aCols[_nX,_nPosPallet], _oBrwLot:aCols[_nX][_nPosEtqVol])
			_oBrwLot:aCols[_nX][_nPosMARK] := 'LBOK'
		endif
	Next

	// atualiza browse
	_oBrwLot:SetArray(_oBrwLot:aCols ,.T. )
	_oBrwLot:ForceRefresh()

	// atualiza o total
	sfAtuTotal()

return

// Desmarcar todos os itens
Static Function sfDesmarcar()

	local _nX := 0

	// varre todos os itens do browse
	For _nX := 1 to len(_oBrwLot:aCols)
		_oBrwLot:aCols[_nX][_nPosMARK] := 'LBNO'
	Next _nX

	// atualiza itens do browse
	_oBrwLot:SetArray(_oBrwLot:aCols ,.T. )
	_oBrwLot:ForceRefresh()

	// atualiza o total
	sfAtuTotal()

return

// ** funcao que valida a confirmacao dos lotes selecionados
static function sfVldConfirma()
	// retorno
	local _nGrava := 1

	If (_nQtdTotal == 0) .and. (aScan(_aLotesPV,{|x| x[_nL_Ite]==_cItemPV }) > 0)
		If ! MsgBox("Confirma cancelamento dos lotes deste item ?","Escolha","YESNO")
			_nGrava := 0
			return(_nGrava)
		endif
	endif

return(_nGrava)

// gravar lotes no array _aLotesPV
static function sfGrava
	local _nX   := 0
	local _nPos := 0

	local _nP_Qtd    := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_QTDVEN"})
	local _nP_Val    := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_VALOR"})
	local _nP_Unit   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_PRCVEN"})
	local _nP_Qli    := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_QTDLIB"})
	local _nP_QtSeg  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_UNSVEN"})
	local _nP_Qli2   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_QTDLIB2"})

	local _aArea := GetArea()

	// elimina linhas do _aLotesPV deste item para refazer o array
	_nPos := aScan(_aLotesPV,{|x| x[_nL_Ite]==_cItemPV })
	while _nPos > 0
		Adel(_aLotesPV, _nPos)
		ASize(_aLotesPV,Len(_aLotesPV)-1)
		_nPos := aScan(_aLotesPV,{|x| x[_nL_Ite]==_cItemPV })
	enddo

	_nQtdLote   := 0
	_nQtdPltSel := 0

	for _nX:=1 to Len(_oBrwLot:aCols)
		if _oBrwLot:aCols[_nX][_nPosMARK] == 'LBOK'
			Aadd(_aLotesPV, {;
			_cItemPV                       ,;
			_cProdPV                       ,;
			_oBrwLot:aCols[_nX,_nPosLocal] ,;
			_oBrwLot:aCols[_nX,_nPosLote]  ,;
			_oBrwLot:aCols[_nX,_nPosEnd]   ,;
			_oBrwLot:aCols[_nX,_nPosPallet],;
			_oBrwLot:aCols[_nX,_nPosSaldo] ,;
			_oBrwLot:aCols[_nX,_nPosSeq]   ,;
			_oBrwLot:aCols[_nX,_nPosEtqVol]})

			_nQtdLote   += _oBrwLot:aCols[_nX,_nPosSaldo]
			_nQtdPltSel += 1
		endif
	next

	// ajusta qtd do pedido e executa gatilhos
	if _nQtdLote > 0
		dbSelectArea("SC6")

		//ajusta qtd do pedido de venda
		aCols[N,_nP_Qtd] := _nQtdLote
		M->C6_QTDVEN := _nQtdLote

		If ExistTrigger("C6_QTDVEN ")
			RunTrigger(2,N,Nil,,"C6_QTDVEN ")
		Endif

		//ajusta qtd 2ª UM do pedido de venda
		aCols[N,_nP_QtSeg] := _nQtdVolume
		M->C6_UNSVEN := _nQtdVolume

		If ExistTrigger("C6_UNSVEN ")
			RunTrigger(2,N,Nil,,"C6_UNSVEN ")
		Endif

		aCols[N,_nP_Val] := A410Arred(_nQtdLote*aCols[N,_nP_Unit],"C6_VALOR")

		//qtd liberada 1ª UM
		aCols[N,_nP_Qli] := _nQtdLote
		//qtd liberada 2ª UM
		aCols[N,_nP_Qli2] := _nQtdVolume

	endif

	RestArea(_aArea)

return

// funcao para validar saldo do lote escolhido
static function sfValQtd(_cLote, _cLocal, _nQuant, mvIdPalete, mvEtqVol)

	local _lRet := .T.

	local _nUsado   := 0
	local _nSalLote := 0
	local _nSaldo   := 0
	local _nEstorno := 0
	local _aSaldos  := {}

	local _nX   := 0
	local _nPos := 0

	local _nP_Ite := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_ITEM"})

	// soma qtd de outros itens deste pedido com mesmo produto, lote e armazem (se ocorrer)
	for _nX := 1 to Len(_aLotesPV)

		if (_aLotesPV[_nX,_nL_Ite] <> _cItemPV) .and. (_aLotesPV[_nX,_nL_Cod] == _cProdPV) .and. (_aLotesPV[_nX,_nL_Lot] == _cLote) .and. (_aLotesPV[_nX,_nL_Amz] == _cLocal) .and. (_aLotesPV[_nX,_nL_Pal] == mvIdPalete)

			// verifica se o item do pedido nao esta deletado
			_nPos := aScan(aCols,{|x| x[_nP_Ite]==_aLotesPV[_nX,_nL_Ite]})

			if (!aCols[_nPos][Len(aHeader)+1])
				_nUsado += _aLotesPV[_nX,_nL_Qtd]
			endif

		endif
	next _nX

	// soma itens de mesmo lote marcados no acols (item que esta sendo informado no momento)
	for _nX := 1 to Len(_oBrwLot:aCols)
		if (_oBrwLot:aCols[_nX][_nPosMARK] == 'LBOK').and.(_oBrwLot:aCols[_nX,_nPosLote] == _cLote).and.(_oBrwLot:aCols[_nX,_nPosLocal] == _cLocal).and.(_oBrwLot:aCols[_nX,_nPosPallet] == mvIdPalete)
			_nUsado += _oBrwLot:aCols[_nX,_nPosSaldo]
		endif
	next _nX

	// soma a quantidade de outros pedidos de venda do mesmo produto, local e lote
	_nUsado += U_ftSomaLot(_cProdPV, _cLocal, _cLote, M->C5_NUM, mvIdPalete, mvEtqVol)
	// soma quantidade que está sendo marcada
	_nUsado += _nQuant

	SB1->(dbSetOrder(1))
	SB1->(dbSeek(xFilial("SB1")+_cProdPv))

	_nSalLote := U_ftPesqLo(_cProdPV, _cLote, _cLocal)

	// se estiver alterando o pedido desconsidera as liberacoes da SC9 para este produto, item,lote e armazem
	// pois ja foram subtraidas do saldo da SB8 e serao excluidas
	if INCLUI
		_nSaldo := _nSalLote - _nUsado
	else
		_nEstorno := U_ftSomaLib(M->C5_NUM,_cProdPV,_cLote,_cLocal)
		_nSaldo   := _nSalLote - _nUsado + _nEstorno
	endif

	if (_nSaldo < 0)
		Aviso("Tecadi: TCFAT009","Lote nao tem saldo em estoque para atender o pedido.",{"Aviso"})
		_lRet := .F.
	endif

return _lRet


user function ftPesqLo(_cCod, _cLotctl, _cLocal)

	local _nRet := 0
	local _cQuery	:= ""
	local _cArqTmp	:= GetNextAlias()

	_cQuery := " SELECT SUM(B8_SALDO - B8_EMPENHO) SALDO "
	_cQuery += " FROM "+RetSqlTab("SB8")
	_cQuery += "	WHERE SB8.B8_FILIAL='"+xFilial("SB8")+"' "
	_cQuery += " AND SB8.B8_PRODUTO='"+_cCod+"' "
	_cQuery += " AND SB8.B8_LOTECTL='"+_cLotCtl+"' "
	_cQuery += " AND SB8.B8_LOCAL='"+_cLocal+"' "
	_cQuery += "	AND SB8.B8_SALDO > 0 AND SB8.D_E_L_E_T_=' ' "

	_cQuery:= ChangeQuery(_cQuery)

	if Select(_cArqTmp)<>0
		(_cArqTmp)->(DbCloseArea())
	Endif
	dbUseArea(.T.,"TOPCONN",TCGenQry(,,_cQuery),_cArqTmp,.T.,.T.)

	_nRet := (_cArqTmp)->SALDO

	(_cArqTmp)->(DbCloseArea())

return(_nRet)

//  funcao para retornar qtd liberada do produto,local e lote na SC9
// transferir para TFAXFUN
user function ftSomaLib(_cPedido,_cCodigo,_cLote,_cLocal)

	local _nRet := 0
	local _cQry := ""

	_cQry:= " SELECT SUM(C9_QTDLIB) C9_QTDLIB "
	_cQry+= " FROM "+RetSqlTab("SC9")
	_cQry+= " WHERE C9_FILIAL = '"+xFilial("SC9")+"'"
	_cQry+= " AND C9_PEDIDO   = '"+_cPedido+"' "
	_cQry+= " AND C9_PRODUTO  = '"+_cCodigo+"' "
	_cQry+= " AND C9_LOTECTL  = '"+_cLote+"' "
	_cQry+= " AND C9_LOCAL    = '"+_cLocal+"' "
	_cQry+= " AND C9_NFISCAL  = ' ' "
	_cQry+= " AND C9_BLEST IN ('  ','10')  "
	_cQry+= " AND D_E_L_E_T_ = ' ' "

	// atualiza variavel de retorno
	_nRet := U_FtQuery(_cQry)

return(_nRet)

// funcao para retornar quantidade utilizada do lote em pedidos de venda com bloqueio de estoque
// e que nao estao empenhados na SB8
// transferir para a TFATXFUN apos validacao
// utilizada no ponto de entrada MTSLDLOT
User Function ftSomaLot(_cProduto, _cLocal, _cLote, _cPedido, mvIdPalete, mvEtqVol)

	local _nRet := 0
	local _cQry := ""

	Default mvEtqVol := ""

	// valor padrao
	Default mvIdPalete := CriaVar("Z11_CODETI",.T.)

	_cQry := " SELECT SUM(Z45_QUANT) TOTAL "
	_cQry += " FROM "+RetSqlTab("Z45")
	_cQry += " WHERE Z45_FILIAL = '"+xFilial("Z45")+"'"
	_cQry += " AND Z45_CODPRO = '"+_cProduto+"' "
	_cQry += " AND Z45_LOCAL  = '"+_cLocal+"' "
	_cQry += " AND Z45_LOTCTL = '"+_cLote+"' "

	// pesquisa pelo ID do Palete
	If ( ! Empty(mvIdPalete) )
		_cQry += " AND Z45_ETQPAL = '"+mvIdPalete+"' "
	EndIf

	// se estiver sendo chamado da funcao MATA410, desconsidera o pedido atual
	if ( ! Empty(_cPedido) )
		_cQry += " AND Z45_PEDIDO <> '"+_cPedido+"' "
	endif

	// se estiver usando etiqueta de volume
	if ( ! Empty(mvEtqVol) )
		_cQry += " AND Z45_ETQVOL  = '" + mvEtqVol + "' "
	endif

	_cQry += " AND Z45.D_E_L_E_T_ = ' ' "

	// atualiza variavel de retorno
	_nRet := U_FtQuery(_cQry)

return(_nRet)

Static Function sfLstNfLote( mvCodProd )

	// objetos locais
	local _oDlgNf, _oPnlCabec, _oGet01Lote, _oBmpPesq, _oGet01Prod, _oGet01Desc, _oBtn01Fechar, _oPnlLote
	// lote informado
	local _cNumLote := CriaVar("B8_LOTECTL", .t.)
	// header do browse
	local _aHeadNf := {}
	// acols do browse
	local _aColsNf := {}
	// descrição do produto
	local _cDescProd := Posicione( "SB1", 1, xFilial("SB1") + mvCodProd, "B1_DESC" )
	// browse
	private _oBrwDetNf

	// defino o header
	If( Len(_aHeadNf) == 0)
		aAdd(_aHeadNf,{"Lote"     , "B8_LOTECTL", PesqPict("SB8", "B8_LOTECTL"), TamSx3("B8_LOTECTL")[1] , 0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadNf,{"Saldo"    , "B8_SALDO"  , PesqPict("SB8", "B8_SALDO")  , TamSx3("B8_SALDO")[1]   , 0,Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadNf,{"N.Fiscal" , "D1_DOC"    , PesqPict("SD1", "D1_DOC")    , TamSx3("D1_DOC")[1]     , 0,Nil,Nil,"C",Nil,"R",,,".F." })
	EndIf

	// monta o dialogo do monitor
	_oDlgNf := MSDialog():New(_aSizeWnd[7],000,_aSizeWnd[6]/2,_aSizeWnd[5]/2,"Lista de Notas Fiscais por Lote",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho (opcoes da pesquisa)
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgNf,,.F.,.F.,,,000,025,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP

	_oPnlLote := TPanel():New(000,000,nil,_oDlgNf,,.F.,.F.,,,000,025,.T.,.F. )
	_oPnlLote:Align:= CONTROL_ALIGN_TOP

	// cria o panel do browse
	_oPnlBrw := TPanel():New(000,000,nil,_oDlgNf,,.F.,.F.,,,000,030,.T.,.F. )
	_oPnlBrw:Align:= CONTROL_ALIGN_ALLCLIENT

	// produto
	_oGet01Prod := TGet():New(002,004,{|u| If(PCount()>0, mvCodProd := u, mvCodProd)},_oPnlCabec,050,010,PesqPict("SB1","B1_COD")    ,,,,,,,.T.,"",,,.F.,.F.,,.T.,.F.,,"mvCodProd" ,,,,,, .T. ,"Produto:",1,)
	_oGet01Prod:Disable()

	// descrição do produto
	_oGet01Desc := TGet():New(002,060,{|u| If(PCount()>0, _cDescProd := u, _cDescProd)},_oPnlCabec,224,010,PesqPict("SB1","B1_DESC") ,,,,,,,.T.,"",,,.F.,.F.,,.T.,.F.,,"_cDescProd" ,,,,,, .T. ,"Descrição do Produto:",1,)
	_oGet01Desc:Disable()

	// define lote
	_oGet01Lote := TGet():New(002,004,{|u| If(PCount()>0, _cNumLote := u, _cNumLote)},_oPnlLote,050,010,PesqPict("SBF","BF_LOTECTL"), { || _oBmpPesq:Click(), .T. },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,,"_cNumLote" ,,,,,, .T. ,"Informe parte do lote para pesquisar:",1,)

	// pesquisar
	_oBmpPesq := TBtnBmp2():New(012,106,040,040,"PESQUISA",,,,{|| _aColsNf := sfLoadNf( mvCodProd, _cNumLote, .f. ) },_oPnlLote,"Pesquisar",,.T. )

	// define o botao Sair
	_oBtn01Fechar := TBtnBmp2():New(001,001,040,040,"FINAL",,,,{|| _oDlgNf:End() },_oPnlCabec,"Sair",,.T. )
	_oBtn01Fechar:Align := CONTROL_ALIGN_RIGHT

	// define acols inicial
	_aColsNf := sfLoadNf( mvCodProd, _cNumLote, .t. )

	// monta o browse
	_oBrwDetNf := MsNewGetDados():New(000,000,400,400,,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsNf),'AllwaysTrue()','','AllwaysTrue()',_oPnlBrw,_aHeadNf,_aColsNf)
	_oBrwDetNf:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oDlgNf CENTERED

Return

Static Function sfLoadNf( mvProduto, mvLote, mvFirst )

	// variavel de retorno
	local _aRet := {}
	// query de pesquisa
	local _cQuery := ""

	// pesquisa os dados do lote pela SB8 e NF de Entrada
	_cQuery := " SELECT DISTINCT B8_LOTECTL, "
	_cQuery += "        B8_SALDO, "
	_cQuery += "        D1_DOC, '.f.' IT_DEL "
	_cQuery += "   FROM " + RetSqlTab("SB8")
	// tabela de pallets
	_cQuery += "   LEFT JOIN " + RetSqlTab("Z16")
	_cQuery += "     ON " + RetSqlCond("Z16")
	_cQuery += "    AND Z16_CODPRO = B8_PRODUTO "
	_cQuery += "    AND Z16_LOTCTL = B8_LOTECTL
	_cQuery += "    AND Z16_SALDO > 0
	// tabela de pallets
	_cQuery += "  INNER JOIN " + RetSqlTab("SD1")
	_cQuery += "     ON " + RetSqlCond("SD1")
	_cQuery += "    AND D1_NUMSEQ = Z16_NUMSEQ
	// tabela de saldo por lote
	_cQuery += "  WHERE  " + RetSqlCond("SB8")
	_cQuery += "    AND B8_SALDO > 0
	_cQuery += "    AND B8_PRODUTO = '" + mvProduto + "' "

	// se informado o lote mostra pelo lote
	If( ! Empty(mvLote) )
		_cQuery += "    AND B8_LOTECTL LIKE '%" + AllTrim(mvLote) + "%' "
	EndIf

	// ordenação pela NF
	_cQuery += "  ORDER BY D1_DOC "

	// txt pra debug
	memowrit("C:\query\tfatc009_consulta_nf_lote.txt", _cQuery)

	// jogo o resultado da query pro array
	_aRet := U_SqlToVet(_cQuery)

	// informa o usuário se não encontrou registro
	If( Len(_aRet) == 0)
		MsgInfo("Nenhuma Nota Fiscal encontrada para o lote e produto informados.", "Atenção")
	EndIf

	// refresh do browse se não for primeiro acesso
	If( ! mvFirst )
		_oBrwDetNf:aCols := aClone(_aRet)
		_oBrwDetNf:Refresh()
	EndIf

Return _aRet

// ** funcao que atualiza o total selecionado
Static Function sfAtuTotal()
	// variaveis temporarias
	local _nX
	local _cIdPlt   := ""
	local _aTotPlt  := {}
	local _cIdVol   := ""
	local _aTotVol  := {}
	local _cIdPrd   := ""
	local _aTotPrd  := {}
	local _cIdLote  := ""
	local _aTotLote := {}

	// zera variaveis
	_nQtdTotal  := 0
	_nQtdPltSel := 0
	_nQtdLote   := 0
	_nQtdVolume := 0

	// varre todas as linhas
	For _nX := 1 to Len(_oBrwLot:aCols)

		// verifica se o item esta selecionado
		If (_oBrwLot:aCols[_nX][_nPosMark] == "LBOK")

			// extrai ID de cada etiqueta
			_cIdPlt  := _oBrwLot:aCols[_nX][_nPosPallet]
			_cIdVol  := _oBrwLot:aCols[_nX][_nPosEtqVol]
			_cIdPrd  := _oBrwLot:aCols[_nX][_nPosEtqPrd]
			_cIdLote := _oBrwLot:aCols[_nX][_nPosLote]

			// atualiza quantidade total geral
			_nQtdTotal += _oBrwLot:aCols[_nX][_nPosSaldo]

			// verifica o total de paletes
			If ( ! Empty(_cIdPlt) ).and.(Ascan(_aTotPlt, _cIdPlt) == 0)
				// adiciona para controle
				aAdd(_aTotPlt, _cIdPlt)
				// controle do total
				_nQtdPltSel ++
			EndIf

			// verifica o total de volumes
			If ( ! Empty(_cIdVol) ).and.(Ascan(_aTotVol, _cIdVol) == 0)
				// adiciona para controle
				aAdd(_aTotVol, _cIdVol)
				// controle do total
				_nQtdVolume ++
			EndIf

			// verifica o total de produtos
			If ( ! Empty(_cIdPrd) ).and.(Ascan(_aTotPrd, _cIdPrd) == 0)
				// adiciona para controle
				aAdd(_aTotPrd, _cIdPrd)
				// controle do total
				_nQtdVolume ++
			EndIf

			// verifica o total de lote
			If ( ! Empty(_cIdLote) ).and.(Ascan(_aTotLote, _cIdLote) == 0)
				// adiciona para controle
				aAdd(_aTotLote, _cIdLote)
				// controle do total
				_nQtdLote ++
			EndIf

		EndIf

	Next _nX

	// atualiza campos
	_oGetTotal:Refresh()
	_oGetPltSel:Refresh()
	_oGetLote:Refresh()
	_oGetQtdVol:Refresh()

Return