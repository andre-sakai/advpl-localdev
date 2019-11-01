#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para consulta detalhada por etiqueta             !
!                  ! - Chamada a partir da rotina TWMSA009/TACDA002          !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 10/2012 !
+------------------+--------------------------------------------------------*/

User Function TWMSA015
	// objetos locais
	local _oWndConsEtq
	local _oPn01Cab
	local _oSayIdEtiqueta
	local _oBmpOpcoes

	// sub-menu
	local _oMnuOpcoes := nil
	local _oSbMnOp01 := nil
	local _oSbMnOp02 := nil
	local _oSbMnOp03 := nil

	// variaveis do browse
	local _aHeadDetEtq := {}
	local _aColsDetEtq := {{"","",.f.}}
	// variaveis de local
	private _cArmzOrigem := ""

	// ID etiqueta
	private _nTamIdEtq := TamSx3("Z11_CODETI")[1]
	private _cIdEtique := Space(_nTamIdEtq)
	private _cMskEtiq  := PesqPict("Z11","Z11_CODETI")

	// objetos private
	private _oBrwDetCons, _oBmpEtqBlq
	private _oPn02Tit
	private _oGetIdEtiqueta

	private _lSetaFocus := .F.

	// pastas do FOLDER
	private _aFolders := {'Dados da Etiqueta', 'Dados Adicionais'}
	// arrays do browse
	private _aHeadDetAdi := {}
	private _aColsDetAdi := {}
	// objeto do browse
	private _oBrwDetAdic

	// define o header do browse
	aAdd(_aHeadDetEtq,{"Titulo"   ,"IT_TITULO", "",  10,0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadDetEtq,{"Descrição","IT_DESCRI", "", 100,0,Nil,Nil,"C",Nil,"R" })

	// só cria quando precisa
	If (Len(_aHeadDetAdi) == 0)
		// define o header do browse adicional
		aAdd(_aHeadDetAdi,{"Titulo"   ,"IT_TITULO", "",  10,0,Nil,Nil,"C",Nil,"R" })
		aAdd(_aHeadDetAdi,{"Descrição","IT_DESCRI", "", 100,0,Nil,Nil,"C",Nil,"R" })
	EndIf

	// definicao da tela de consultas
	_oWndConsEtq := MSDialog():New(000,000,320,240,"WMS - Consulta",,,.F.,,,,,,.T.,,,.T.)

	// pastas com as opcoes de visualizacao
	_oFldDadosPrd := TFolder():New(000,000,_aFolders,,_oWndConsEtq,,,,.T.,,200,200)
	_oFldDadosPrd:Align:= CONTROL_ALIGN_ALLCLIENT
	_oFldDadosPrd:aEnable(2, .F.)

	// sub-menu de opções
	_oMnuOpcoes := TMenu():New(0,0,0,0,.T.)
	_oSbMnOp01 := TMenuItem():New(_oMnuOpcoes,"Detalhes Movim.",,,,{|| sfDetMovim(_cIdEtique) },,"PMSIMG32",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOp01)
	_oSbMnOp02 := TMenuItem():New(_oMnuOpcoes,"Sair",,,,{|| _lOk := .t. , _oWndConsEtq:End()},,"FINAL",,,,,,,.T.)
	_oMnuOpcoes:Add(_oSbMnOp02)

	// -- painel com as opcoes disponiveis
	_oPn01Cab := TPanel():New(000,000,nil,_oWndConsEtq,,.F.,.F.,,,22,22,.T.,.F. )
	_oPn01Cab:Align:= CONTROL_ALIGN_TOP
	_oPn01Cab:nClrPane := CLR_HGRAY
	// mais opções
	_oBmpOpcoes := TBtnBmp2():New(000,000,060,022,"SDUAPPEND",,,,{|| Nil },_oPn01Cab,"",,.T.)
	_oBmpOpcoes:Align := CONTROL_ALIGN_RIGHT
	_oBmpOpcoes:SetPopupMenu(_oMnuOpcoes)

	// campos da etiqueta
	_oSayIdEtiqueta := TSay():New(001,003,{||"Etiqueta"},_oPn01Cab,,,.F.,.F.,.F.,.T.)
	_oGetIdEtiqueta := TGet():New(008,003,{|u| If(PCount()>0,_cIdEtique:=u,_cIdEtique)},_oPn01Cab,050,010,_cMskEtiq,{|| Vazio().Or.sfVldEtiqueta(@_oBmpEtqBlq)},,,_oFnt02,,,.T.,"",,,.F.,.F.,{|| _lSetaFocus := .T. },.F.,.F.,"","_cIdEtique",,)

	// -- BOTAO BLOQUEAR ENDERECO
	If ((_lUsrGeren) .Or. (_lUsrAccou) .Or. (_lUsrSuper))
		_oBmpEtqBlq := TBtnBmp2():New(000,000,040,040,"PIN",,,,{|| If(sfBloqEnd(), sfVldEtiqueta(@_oBmpEtqBlq), Nil) },_oPn01Cab,"Bloq.Endereço",,.T.)
		_oBmpEtqBlq:Align := CONTROL_ALIGN_RIGHT
		_oBmpEtqBlq:lActive := .f.
	EndIf

	// -- painel com o titulo
	_oPn02Tit := TPanel():New(000,000,"",_oWndConsEtq,,.F.,.F.,,,13,13,.T.,.F. )
	_oPn02Tit:Align:= CONTROL_ALIGN_TOP
	_oPn02Tit:oFont := _oFnt03

	// browse com os detalhes da consulta
	_oBrwDetCons := MsNewGetDados():New(000,000,600,600,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDetEtq),'AllwaysTrue()','','AllwaysTrue()',_oFldDadosPrd:aDialogs[1],_aHeadDetEtq,_aColsDetEtq)
	_oBrwDetCons:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwDetCons:oBrowse:oFont := _oFnt02
	//	_oBrwDetCons:oBrowse:BlDblClick := {|| IIf(sfEdita(_oBrwDetCons), sfVldEtiqueta(_oBmpEtqBlq), Nil) }
	_oBrwDetCons:oBrowse:SetBlkBackColor({|| IIf( _oBrwDetCons:aCols[_oBrwDetCons:nAt][1] == "Nova transp.", CLR_YELLOW, CLR_WHITE  ) })

	// browse com os detalhes da consulta da aba adicional
	_oBrwDetAdic := MsNewGetDados():New(000,000,600,600,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDetAdi),'AllwaysTrue()','','AllwaysTrue()',_oFldDadosPrd:aDialogs[2],_aHeadDetAdi,_aColsDetAdi)
	_oBrwDetAdic:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwDetAdic:oBrowse:oFont := _oFnt02

	// ativa a tela
	ACTIVATE MSDIALOG _oWndConsEtq

Return

// ** função para setar focus no campo
Static Function sfSetFocus(mvGet)

	// se foi alterado o campo da etiqueta seta o focus
	If (_lSetaFocus)
		// seta foco
		mvGet:SetFocus()
		// desabilita
		_lSetaFocus := .F.
	EndIf

Return ()

// ** funcao para pesquisar a etiqueta e atualizar os detalhes
Static Function sfVldEtiqueta(mvObjBloq)
	// variavel de retorno
	local _lRet := .t.
	// tipo da etiqueta
	local _cTitulo := ""

	// bloqueio de objeto
	If (mvObjBloq != Nil)
		mvObjBloq:lActive := .f.
	EndIf

	// pesquisa a existencia da etiqueta
	dbSelectArea("Z11")
	Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
	If ! Z11->(dbSeek( xFilial("Z11")+_cIdEtique ))
		U_FtWmsMsg("Etiqueta Inválida!","Atenção")
		_lRet := .f.
	EndIf

	If (_lRet)
		If (Z11->Z11_TIPO == "01") // 01-PRODUTO
			// atualiza titulo
			_cTitulo := "PRODUTO"
			// consulta dados
			sfAtuProduto()

		ElseIf (Z11->Z11_TIPO == "02") // 02-ENDERECO
			// bloqueio de objeto
			If (mvObjBloq != Nil)
				mvObjBloq:lActive := .t.
			EndIf
			// atualiza titulo
			_cTitulo := "ENDERECO"
			// consulta dados
			sfAtuEndereco()

		ElseIf (Z11->Z11_TIPO == "03") // 03-PALETE
			// atualiza titulo
			_cTitulo := "PALETE"
			// consulta dados
			sfAtuPalete()

		ElseIf (Z11->Z11_TIPO == "04") // 04-VOLUME
			// atualiza titulo
			_cTitulo := "VOLUME"
			// consulta dados
			sfAtuVolume()

		Else
			// mensagem
			U_FtWmsMsg("Tipo da Etiqueta não permite consulta!", "Atenção")
			// variavel de retorno
			_lRet := .f.
		EndIf
	EndIf

	// atualiza o titulo
	_oPn02Tit:cCaption := _cTitulo

	// valida o foco da etiqueta
	sfSetFocus(_oGetIdEtiqueta)

Return(.t.)

// ** funcao para consulta de dados de produtos
Static Function sfAtuProduto()
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SF1","Z11","Z05"})
	local _aTmpDados := {}
	// id do palete
	local _cIdPalete := sfRetNrPalete(Z11->Z11_CODETI, Z11->Z11_TIPO)
	// endereco atual
	local _cEndAtual  := ""
	// saldo atual
	local _nSaldoAtual := 0
	// array tmp
	local _aTmpAdic := {}

	// caso nao encontre etiqueta do produto na Z16
	If Empty(_cIdPalete)
		Return
	EndIf

	// busca o endereco atual do palete
	U_FtEndPlt(_cIdPalete, @_cEndAtual, Nil, @_cArmzOrigem, Nil, @_nSaldoAtual)

	// posiciona na nota fiscal
	dbSelectArea("SF1")
	SF1->(dbSetOrder(1)) //1-F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_FORMUL
	SF1->(dbSeek( xFilial("SF1")+Z11->Z11_DOC+Z11->Z11_SERIE+Z11->Z11_CLIENT+Z11->Z11_LOJA ))

	// posiciona na movimentacao de entrada/saida de veiculos
	dbSelectArea("SZZ")
	SZZ->(dbSetOrder(1)) // 1-ZZ_FILIAL, ZZ_CESV
	SZZ->(dbSeek( xFilial("SZZ")+Z11->Z11_CESV ))

	// posiciona na ordem de servico
	dbSelectArea("Z05")
	Z05->(dbSetOrder(2)) // 2-Z05_FILIAL, Z05_CESV
	Z05->(dbSeek( xFilial("Z05")+Z11->Z11_CESV ))

	// limpa a variável a cada nova consulta
	_aTmpDados := {}

	// padroniza o detalhes
	aAdd(_aTmpDados,{"Produto"    ,AllTrim(Z11->Z11_CODPRO)+"-"+AllTrim(Posicione("SB1",1,xFilial("SB1")+Z11->Z11_CODPRO,"B1_DESC")),.f.})
	aAdd(_aTmpDados,{"Quantidade" ,AllTrim(Transf(Z11->Z11_QTD1,PesqPict("SD1","D1_QUANT")))+" de "+AllTrim(Transf(Z11->Z11_QTD2,PesqPict("SD1","D1_QUANT"))),.f.})
	aAdd(_aTmpDados,{"Id.Palete"  ,_cIdPalete,.f.})
	aAdd(_aTmpDados,{"End.Atual"  ,_cArmzOrigem+" / "+AllTrim(_cEndAtual),.f.})
	// saldo, somente para Gerente, Account e Supervisor
	If ((_lUsrGeren) .Or. (_lUsrAccou) .Or. (_lUsrSuper))
		aAdd(_aTmpDados,{"Saldo Atual",AllTrim(Transf(_nSaldoAtual,PesqPict("SD1","D1_QUANT"))),.f.})
	EndIf

	// crio um novo browse, pra ser colocado na aba 2 do folder
	If (Len(_aFolders) > 1)

		// limpo o array pra não duplicar os registros
		_aColsDetAdi := {}
		_aTmpAdic     := {}

		// define o acols do novo folder
		aAdd(_aTmpAdic,{"Item NF"    ,Z11->Z11_ITEMNF,.f.})
		aAdd(_aTmpAdic,{"Cliente"    ,Z11->Z11_CLIENT+"/"+Z11->Z11_LOJA+"-"+AllTrim(Posicione("SA1",1, xFilial("SA1")+Z11->(Z11_CLIENT+Z11_LOJA),"A1_NOME")),.f.})
		aAdd(_aTmpAdic,{"Nota Fiscal",Z11->Z11_DOC+" / "+Z11->Z11_SERIE,.f.})
		aAdd(_aTmpAdic,{"Programação",Z11->Z11_PROCES,.f.})
		aAdd(_aTmpAdic,{"Ord.Serv."  ,Z05->Z05_NUMOS,.f.})
		aAdd(_aTmpAdic,{"Referência" ,Posicione("SZ1",1,xFilial("SZ1")+Z11->Z11_PROCES,"Z1_REFEREN"),.f.})
		aAdd(_aTmpAdic,{"Container"  ,Transf(SZZ->ZZ_CNTR01,PesqPict("SZC","ZC_CODIGO"))+If(Empty(SZZ->ZZ_CNTR02),""," / "+Transf(SZZ->ZZ_CNTR02,PesqPict("SZC","ZC_CODIGO"))),.f.})
		aAdd(_aTmpAdic,{"Dt. Entrada",DtoC(SF1->F1_DTDIGIT),.f.})

	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni)
	RestArea(_aArea)

	// atualiza o browse
	// 1 aba
	If(Len(_aTmpDados)=0)
		_aTmpDados := {{"","",.f.}}
	EndIf
	_oBrwDetCons:aCols := aClone(_aTmpDados)
	_oBrwDetCons:oBrowse:Refresh()
	
	// 2 aba
	If(Len(_aTmpAdic)=0)
		aAdd(_aTmpAdic,{"","",.f.})
	EndIf
	_oBrwDetAdic:aCols := aClone(_aTmpAdic)
	_oBrwDetAdic:oBrowse:Refresh()

	// habilito as abas
	_oFldDadosPrd:aEnable(2, .T.)

Return

// ** funcao para consulta de dados do endereco
Static Function sfAtuEndereco()
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SBE","SBF","SB1"})

	// variveis temporarias
	local _aTmpCfgEnd := {}
	local _aTmpDados := {}
	local _nCfg
	local _cSeekSBF
	// quantidade de saldo
	local _nSeq := 1
	// organiza os dados da propriedade do endereco
	local _aTmpProp := {}
	// saldo no endereco
	local _nSaldoAtual := 0
	// produto
	local _cCodProd := ""
	// query
	local _cQuery := ""
	// etiqueta de produto
	local _cEtqPrd := ""

	// posiciona no cadastro do endereco
	dbSelectArea("SBE")
	SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
	If ! SBE->(dbSeek( xFilial("SBE")+Z11->Z11_LOCAL+Z11->Z11_ENDERE ))
		U_FtWmsMsg("Endereço não encontrado com esta etiqueta!","Atenção")
		Return(.f.)
	EndIf

	// organiza o endereco para demonstrar no browse
	_aTmpCfgEnd := aClone(U_FtCfgEnd(Z11->Z11_ENDERE, Z11->Z11_LOCAL))
	// inclui todas as informacoes do endereco
	For _nCfg := 1 to Len(_aTmpCfgEnd)
		// separa os dados da propriendade
		_aTmpProp := sfRetProp(_aTmpCfgEnd[_nCfg][1])
		// inclui a propriedade
		aAdd(_aTmpDados,{AllTrim(_aTmpProp[1]), AllTrim(_aTmpProp[2]),.f.})
	Next _nCfg

	// padroniza o restante das informacoes do endereco
	//	aAdd(_aTmpDados,{"Altura"     ,Str(SBE->BE_ALTURLC ,TamSx3("BE_ALTURLC")[1], TamSx3("BE_ALTURLC")[2]),.f.})
	//	aAdd(_aTmpDados,{"Largura"    ,Str(SBE->BE_LARGLC  ,TamSx3("BE_LARGLC")[1] , TamSx3("BE_LARGLC")[2]),.f.})
	//	aAdd(_aTmpDados,{"Comprimento",Str(SBE->BE_COMPRLC ,TamSx3("BE_COMPRLC")[1], TamSx3("BE_COMPRLC")[2]),.f.})
	//	aAdd(_aTmpDados,{"Cap.Max.Kg" ,Str(SBE->BE_CAPACID ,TamSx3("BE_CAPACID")[1], TamSx3("BE_CAPACID")[2]),.f.})
	If (SBE->BE_STATUS == "1")
		aAdd(_aTmpDados,{"Status","DISPONIVEL",.f.})
	ElseIf (SBE->BE_STATUS == "2")
		aAdd(_aTmpDados,{"Status","OCUPADO",.f.})
	ElseIf (SBE->BE_STATUS == "3")
		aAdd(_aTmpDados,{"Status","BLOQUEADO",.f.})
	ElseIf (SBE->BE_STATUS == "I")
		aAdd(_aTmpDados,{"Status","RESERVA FUTURA",.f.})
	EndIf

	// saldo, somente para gerente, account e Supervisor
	If ((_lUsrGeren) .Or. (_lUsrAccou) .Or. (_lUsrSuper))

		// posiciona no saldo de produto por endereco
		dbSelectArea("SBF")
		SBF->(dbSetOrder(1)) //1-BF_FILIAL, BF_LOCAL, BF_LOCALIZ, BF_PRODUTO, BF_NUMSERI, BF_LOTECTL, BF_NUMLOTE
		If SBF->(dbSeek( _cSeekSBF := xFilial("SBF")+ Z11->Z11_LOCAL + Z11->Z11_ENDERE ))
			// varre todos os saldos do endereco
			While SBF->(!Eof()) .And. ((SBF->BF_FILIAL + SBF->BF_LOCAL + SBF->BF_LOCALIZ) == _cSeekSBF )

				// atualiza codigo do produto
				_cCodProd := SBF->BF_PRODUTO

				// calcula saldo do produto no endereco
				_nSaldoAtual := QuantSBF(SBF->BF_LOCAL,;
				SBF->BF_LOCALIZ,;
				SBF->BF_PRODUTO)

				// atualiza browse
				aAdd(_aTmpDados,{"Produto "+AllTrim(Str(_nSeq)) ,AllTrim(_cCodProd)+"-"+AllTrim(Posicione("SB1",1,xFilial("SB1")+_cCodProd,"B1_DESC")),.f.})
				aAdd(_aTmpDados,{"Saldo "+AllTrim(Str(_nSeq))   ,AllTrim(Transf(_nSaldoAtual,PesqPict("SD1","D1_QUANT"))),.f.})
				/*
				// query para pegar a etiqueta de produto
				_cQuery := "SELECT MAX(Z16_ETQPRD) Z16_ETQPRD FROM "+RetSqlName("Z16")+" Z16"
				_cQuery += " WHERE "+RetSqlCond("Z16")
				_cQuery += " AND Z16_LOCAL  = '"+SBF->BF_LOCAL+"'
				_cQuery += " AND Z16_ENDATU = '"+SBF->BF_LOCALIZ+"' "
				_cQuery += " AND Z16_CODPRO = '"+SBF->BF_PRODUTO+"' "
				_cQuery += " AND Z16_SALDO > 0 "

				// preencho a variável com o resultado da query
				_cEtqPrd := U_FtQuery(_cQuery)

				// insiro a variavel no array do browse
				aAdd(_aTmpDados,{"Etiqueta: "+AllTrim(Str(_nSeq)) ,AllTrim(_cEtqPrd),.f.})
				*/
				// atualiza sequencial
				_nSeq ++

				// proximo registro
				SBF->(dbSkip())
			EndDo
		EndIf

	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni)
	RestArea(_aArea)

	// atualiza o browse
	If(Len(_aTmpDados)=0)
		aAdd(_aTmpDados,{"","",.f.})
	EndIf
	
	_oBrwDetCons:aCols := aClone(_aTmpDados)
	_oBrwDetCons:oBrowse:Refresh()

Return(.t.)

// ** funcao para consulta de dados do palete
Static Function sfAtuPalete()
	local _cAliasNew := GetNextAlias()
	local _cQuery
	local _aTmpDados := {}

	_cQuery := "SELECT Z16_CODPRO, B1_DESC, SUM(Z16_SALDO) Z16_SALDO "
	// estrutura do palete
	_cQuery += "FROM "+RetSqlName("Z16")+" Z16 "
	// cad. de produto
	_cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND B1_COD = Z16_CODPRO "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z16")+" "
	// filtro pelo codigo da etiqueta
	_cQuery += "AND Z16_ETQPAL = '"+_cIdEtique+"' "
	// somente com saldo
	_cQuery += "AND Z16_SALDO > 0 "
	// agrupa dados
	_cQuery += "GROUP BY Z16_CODPRO, B1_DESC "

	If (Select(_cAliasNew) <> 0)
		dbSelectArea(_cAliasNew)
		dbCloseArea()
	EndIf

	// executa o select
	DbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),(_cAliasNew),.F.,.T.)
	(_cAliasNew)->(DbGoTop())

	// inclui informacoes
	While (_cAliasNew)->(!Eof())
		// padroniza o detalhes
		aAdd(_aTmpDados,{"Produto" ,AllTrim((_cAliasNew)->Z16_CODPRO)+"-"+AllTrim((_cAliasNew)->B1_DESC), .f.})
		aAdd(_aTmpDados,{"Saldo"   ,Transf((_cAliasNew)->Z16_SALDO,PesqPict("SD1","D1_QUANT"))          , .f.})
		// proximo item
		(_cAliasNew)->(dbSkip())
	EndDo

	// fecha a query
	dbSelectArea(_cAliasNew)
	dbCloseArea()

	// atualiza o browse
	if(Len(_aTmpDados)=0)
		_aTmpDados := {{"","",.f.}}
	endif

	_oBrwDetCons:aCols := aClone(_aTmpDados)
	_oBrwDetCons:oBrowse:Refresh()

Return

// ** funcao para bloqueio de enderecos
Static Function sfBloqEnd()
	local _cNovoSts := ""

	// se estiver 1=DISPONIVEL
	If (SBE->BE_STATUS == "1")
		If ( ! MsgYesNo("Bloquear Endereço?"))
			Return(.f.)
		EndIf
		// novo status
		_cNovoSts := "3"

		// se estiver 2=OCUPADO
	ElseIf (SBE->BE_STATUS == "2")
		U_FtWmsMsg("Não é permitido o bloqueio de endereços OCUPADOS","Atenção")
		Return(.f.)

		// se estiver 3=BLOQUEADO
	ElseIf (SBE->BE_STATUS == "3")
		If ( ! MsgYesNo("Desbloquear Endereço?"))
			Return(.f.)
		EndIf
		// novo status
		_cNovoSts := "1"

	EndIF

	// atualiza status do endereco
	dbSelectArea("SBE")
	RecLock("SBE")
	SBE->BE_STATUS := _cNovoSts
	SBE->(MsUnLock())

	// insere o log
	U_FtGeraLog(cFilAnt, "SBE", xFilial("SBE") + SBE->BE_LOCAL + SBE->BE_LOCALIZ, "Endereço " + IIf(_cNovoSts=="3", "Bloqueado!", "Desbloqueado!"), "WMS", "BE_LOCALIZ")

Return(.t.)

// ** funcao para editar o campo
Static Function sfEdita(mvBrowse)
	// objetos da tela
	local _oWndCnsEdit
	local _oPnlCnsEdtCab
	local _oBmpCnsEdtOk, _oBmpCnsEdtSair
	local _oSayCnsTit, _oGetCnsCampo
	// campos
	local _cDscCampo := mvBrowse:aCols[mvBrowse:nAt][1]
	local _nTmpConteudo := Val(mvBrowse:aCols[mvBrowse:nAt][2])
	local _cTmpCampo := ""
	// controle de confirmacao
	local _lOk := .f.
	// mascara do campo
	local _cMskCampo := ""

	// controle de edicao
	If ( ! (AllTrim(Upper(_cDscCampo)) $ "ALTURA/LARGURA/COMPRIMENTO/CAP.MAX.KG"))
		U_FtWmsMsg("Campo não disponível para edição.","Atenção")
		Return(.f.)
	EndIf

	// define o campo
	If (AllTrim(Upper(_cDscCampo)) $ "ALTURA")
		_cTmpCampo := "BE_ALTURLC"
	ElseIf (AllTrim(Upper(_cDscCampo)) $ "LARGURA")
		_cTmpCampo := "BE_LARGLC"
	ElseIf (AllTrim(Upper(_cDscCampo)) $ "COMPRIMENTO")
		_cTmpCampo := "BE_COMPRLC"
	ElseIf (AllTrim(Upper(_cDscCampo)) $ "CAP.MAX.KG")
		_cTmpCampo := "BE_CAPACID"
	EndIf

	// mascara do campo
	_cMskCampo := X3Picture(_cTmpCampo)

	// definicao da tela de consultas
	_oWndCnsEdit := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"WMS - Editar",,,.F.,,,,,,.T.,,,.T. )

	// -- painel com as opcoes disponiveis
	_oPnlCnsEdtCab := TPanel():New(000,000,nil,_oWndCnsEdit,,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlCnsEdtCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMA A ALTERACAO
	_oBmpCnsEdtOk := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| _lOk := .t. , _oWndCnsEdit:End() },_oPnlCnsEdtCab,"Ok",,.T. )
	_oBmpCnsEdtOk:Align := CONTROL_ALIGN_LEFT

	// -- BOTAO PARA FECHAR A TELA
	_oBmpCnsEdtSair := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| _oWndCnsEdit:End() },_oPnlCnsEdtCab,"Sair",,.T. )
	_oBmpCnsEdtSair:Align := CONTROL_ALIGN_RIGHT

	// titulo do campo
	_oSayCnsTit   := TSay():New(030,003,{|| _cDscCampo },_oWndCnsEdit,,,.F.,.F.,.F.,.T.)
	_oGetCnsCampo := TGet():New(037,003,{|u| If(PCount()>0,_nTmpConteudo:=u,_nTmpConteudo)},_oWndCnsEdit,100,010,_cMskCampo,{|| .T. },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nTmpConteudo",,)

	// ativa a tela
	ACTIVATE MSDIALOG _oWndCnsEdit

	If (_lOk)
		dbSelectArea("SBE")
		RecLock("SBE")
		SBE->&(_cTmpCampo) := _nTmpConteudo
		SBE->(MsUnLock())
	EndIf

Return(_lOk)

// ** funcao que organiza a propriedade do endereco
Static Function sfRetProp(mvPropEnd)
	local _aRet := {}

	// adiciona a propriedade
	aAdd(_aRet,AllTrim( SubS(mvPropEnd,1,At(" ",mvPropEnd))))
	// adiciona a definicao da propriedade
	aAdd(_aRet,AllTrim( SubS(mvPropEnd,At(" ",mvPropEnd))))

Return(_aRet)

// ** funcao que pesquisa o palete pela etiqueta do produto
Static Function sfRetNrPalete(mvIdEtqPrd, mvTpEtiq)
	// variavel de retorno
	local _cRetIdPal := Space(Len(mvIdEtqPrd))
	local _cQryPlt

	_cQryPlt := "SELECT DISTINCT Z16_ETQPAL "
	// composicao de palete
	_cQryPlt += "FROM "+RetSqlName("Z16")+" Z16 "
	// filtro padrao
	_cQryPlt += "WHERE "+RetSqlCond("Z16")+" "
	// filtra por etiqueta de produto
	If (mvTpEtiq == "01")
		_cQryPlt += "AND Z16_ETQPRD = '"+mvIdEtqPrd+"' "

		// filtra por etiqueta de volume
	ElseIf (mvTpEtiq == "04")
		_cQryPlt += "AND Z16_ETQVOL = '"+mvIdEtqPrd+"' "
	EndIf
	// somente com saldo
	_cQryPlt += "AND Z16_SALDO > 0 "

	// executa a query
	_cRetIdPal := U_FtQuery(_cQryPlt)

	If (Empty(_cRetIdPal))
		U_FtWmsMsg("Etiqueta não encontrada!","Atenção")
	EndIf

Return(_cRetIdPal)

// ** funcao para consulta de dados de volumes
Static Function sfAtuVolume()
	local _aAreaAtu    := GetArea()
	local _cAliasNew   := GetNextAlias()
	local _cAliasDet   := GetNextAlias()
	local _cQuery      := ""
	local _aTmpDados   := {}
	local _cTmpEnder   := ""
	local _cTmpMasca   := "@!"
	local _aColsDetAdi := {}
	local _aTmpAdic    := {}
	local _cIdPalete   := ""
	local _cTransp     := ""

	// prepara query
	_cQuery := " SELECT Z16_ETQVOL, Z16_CODPRO, B1_DESC, SUM(Z16_SALDO) Z16_SALDO, Z16_LOCAL, Z16_ENDATU, Z16_LOTCTL, Z16_PEDIDO, C5_ZPEDCLI, C5_ZDOCCLI, C5_ZAGRUPA, Z05_NUMOS, Z05_CESV, Z16_ETQPAL, C5_TRANSP, ZZ_TRANSP "
	// estrutura do palete
	_cQuery += " FROM "+RetSqlTab("Z16")
	// cad. de produto
	_cQuery += " INNER JOIN " + RetSqlTab("SB1") + " ON " + RetSqlCond("SB1") + " AND B1_COD = Z16_CODPRO "
	//PEDIDO DE VENDA
	_cQuery += " LEFT JOIN " + RetSqlTab("SC5") + " ON " + RetSqlCond("SC5") + " AND C5_NUM = Z16_PEDIDO "
	// cabeçalho ordem de serviço
	_cQuery += " LEFT JOIN " + RetSqlTab("Z05") + " ON " + RetSqlCond("Z05") + " AND Z05_CARGA = C5_ZCARGA 	AND C5_ZCARGA != '' "
	//CESV
	_cQuery += " LEFT JOIN " + RetSqlTab("SZZ") + " ON " + RetSqlCond("SZZ") + " AND ZZ_CESV = Z05_CESV "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z16") + " "
	// filtro pelo codigo da etiqueta
	_cQuery += " AND Z16_ETQVOL = '" + _cIdEtique + "' "
	// somente com saldo
	_cQuery += " AND Z16_SALDO > 0 "
	// agrupa dados
	_cQuery += " GROUP BY Z16_ETQVOL, Z16_CODPRO, B1_DESC, Z16_LOCAL, Z16_ENDATU, Z16_LOTCTL, Z16_PEDIDO, C5_ZPEDCLI, C5_ZDOCCLI, C5_ZAGRUPA, Z05_NUMOS, Z05_CESV, Z16_ETQPAL, C5_TRANSP, ZZ_TRANSP"

	MemoWrit("c:\query\twmsa015_sfAtuVolume.txt", _cQuery)

	If (Select(_cAliasNew) <> 0)
		dbSelectArea(_cAliasNew)
		dbCloseArea()
	EndIf

	// executa o select
	DbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),(_cAliasNew),.F.,.T.)
	(_cAliasNew)->(DbGoTop())

	//se a consulta voltou em branco
	If (_cAliasNew)->( EoF() )
		U_FtWmsMsg("Etiqueta inválida, não retornou resultados. Pode já ter sido expedida, excluída ou está incorreta.","Alerta TWMSA015!")
	Else    		 //consulta retornou resultados
		//armazena pallet lido
		_cIdPalete := (_cAliasNew)->Z16_ETQPAL

		// inclui informacoes
		While (_cAliasNew)->( !Eof() )

			// posiciona no endereco
			If (_cTmpEnder != (_cAliasNew)->Z16_ENDATU)
				dbSelectArea("SBE")
				SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
				SBE->(dbSeek( xFilial("SBE")+(_cAliasNew)->(Z16_LOCAL+Z16_ENDATU) ))

				// pesquisa mascara do endereco no tipo de estrutura
				dbSelectArea("DC8")
				DC8->(dbSetOrder(1)) // 1-DC8_FILIAL, DC8_CODEST
				DC8->(dbSeek( xFilial("DC8")+SBE->BE_ESTFIS ))

				// atualiza mascara
				_cTmpMasca := DC8->DC8_ZMASCA
			EndIf

			// padroniza o detalhes
			aAdd(_aTmpDados,{"Etiq.Volume", Transf((_cAliasNew)->Z16_ETQVOL,_cMskEtiq)                          , .f.})
			aAdd(_aTmpDados,{"Produto"    , AllTrim((_cAliasNew)->Z16_CODPRO)+"-"+AllTrim((_cAliasNew)->B1_DESC), .f.})
			aAdd(_aTmpDados,{"Saldo"      , Transf((_cAliasNew)->Z16_SALDO,PesqPict("SD1","D1_QUANT"))          , .f.})
			aAdd(_aTmpDados,{"End.Atual"  , Transf((_cAliasNew)->Z16_ENDATU,_cTmpMasca)                         , .f.})

			// Transportadora
			If ( ! Empty((_cAliasNew)->ZZ_TRANSP)) .AND. ( (_cAliasNew)->ZZ_TRANSP != (_cAliasNew)->C5_TRANSP ) // se tiver transportadora no CESV e for diferente do pedido
				_cTransp := AllTrim( Posicione("SA4",1, xFilial("SA4") + (_cAliasNew)->ZZ_TRANSP,"A4_NOME") )
				aAdd(_aTmpDados,{"Nova transp.", _cTransp , .F.})
			ElseIf ( ! Empty((_cAliasNew)->C5_TRANSP))  // transportadora está preenchida no pedido
				_cTransp := AllTrim( Posicione("SA4",1, xFilial("SA4") + (_cAliasNew)->C5_TRANSP,"A4_NOME") )
				aAdd(_aTmpDados,{"Transp.", _cTransp , .F.})
			EndIf

			// CESV
			IF ( !Empty((_cAliasNew)->Z05_CESV ))
				aAdd(_aTmpDados,{"CESV"   , (_cAliasNew)->Z05_CESV, .F.})
			EndIf

			// dados do lote
			If ( ! Empty((_cAliasNew)->Z16_LOTCTL) )
				aAdd(_aTmpDados,{"Lote", (_cAliasNew)->Z16_LOTCTL, .f.})
			EndIf
			// dados do pedido
			If ( ! Empty((_cAliasNew)->Z16_PEDIDO) )

				// pedido de venda tecadi
				aAdd(_aTmpDados,{"Ped. Tecadi", (_cAliasNew)->Z16_PEDIDO, .f.})

				// pedido cliente
				If ( ! Empty((_cAliasNew)->C5_ZPEDCLI) )
					aAdd(_aTmpDados,{"Ped. cliente", (_cAliasNew)->C5_ZPEDCLI, .f.})
				EndIf
				// nota fiscal de venda do cliente
				If ( ! Empty((_cAliasNew)->C5_ZDOCCLI) )
					aAdd(_aTmpDados,{"NF Cliente", (_cAliasNew)->C5_ZDOCCLI, .f.})
				EndIf
				// agrupadora
				If ( ! Empty((_cAliasNew)->C5_ZAGRUPA) )
					aAdd(_aTmpDados,{"Agrupadora", (_cAliasNew)->C5_ZAGRUPA, .f.})
				EndIf
			EndIf

			// proximo item
			(_cAliasNew)->(dbSkip())
		EndDo

		//*** preenche dados adicionais (2ª aba)

		_cQuery := " SELECT Z08_NUMOS, Z05_CARGA, DAI_PEDIDO, C5_ZPEDCLI"
		_cQuery += " FROM " + RetSqlTab("Z08")
		//cabeçalho da OS
		_cQuery += "       INNER JOIN " + RetSqlTab("Z05")
		_cQuery += "               ON " + RetSqlCond("Z05")
		_cQuery += "                  AND Z05_NUMOS = Z08_NUMOS"
		//carga
		_cQuery += "       INNER JOIN " + RetSqlTab("DAI")
		_cQuery += "               ON " + RetSqlCond("DAI")
		_cQuery += "                  AND DAI_COD = Z05_CARGA"
		//pedido de venda
		_cQuery += "	   INNER JOIN " + RetSqlTab("SC5")
		_cQuery += "				  ON " + RetSqlCond("SC5")
		_cQuery += "                     AND C5_NUM = DAI_PEDIDO"
		//conforme pallet bipado (adquirido da etiqueta de volume)
		_cQuery += " WHERE " + RetSqlCond("Z08")
		_cQuery += "       AND ( Z08_PALLET = '" + _cIdPalete + "' OR Z08_NEWPLT = '" + _cIdPalete +"' )"
		_cQuery += "       AND Z08_STATUS = 'R'"

		MemoWrit("c:\query\twmsa015_sfAtuVolume_Adic.txt", _cQuery)

		If (Select(_cAliasDet) <> 0)
			dbSelectArea(_cAliasDet)
			dbCloseArea()
		EndIf

		// executa o select
		DbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQuery),(_cAliasDet),.F.,.T.)
		(_cAliasDet)->(DbGoTop())

		// inclui informações adicionais
		aAdd(_aTmpAdic,{"OS Origem"    , (_cAliasDet)->Z08_NUMOS, .F.})
		aAdd(_aTmpAdic,{"Carga origem" , (_cAliasDet)->Z05_CARGA, .F.})

		//adiciona todos os pedidos
		While (_cAliasDet)->( !EoF() )
			aAdd(_aTmpAdic,{"Ped. Tecadi"  , (_cAliasDet)->DAI_PEDIDO, .F.})
			aAdd(_aTmpAdic,{"Ped. Cliente" , (_cAliasDet)->C5_ZPEDCLI, .F.})

			//proximo registro
			(_cAliasDet)->( DbSkip() )
		EndDo

		// fecha a query dados adicionais
		dbSelectArea(_cAliasDet)
		dbCloseArea()

	EndIf

	// fecha a query dados principal da etiqueta
	dbSelectArea(_cAliasNew)
	dbCloseArea()

	// restaura areas iniciais
	RestArea(_aAreaAtu)

	// atualiza a tela
	// 1 aba
	If(len(_aTmpDados)=0)
		aAdd(_aTmpDados,{"","",.f.})
	EndIf
	
	_oBrwDetCons:aCols := aClone(_aTmpDados)
	_oBrwDetCons:oBrowse:Refresh()

	// 2 aba
	If(len(_aTmpAdic)=0)
		aAdd(_aTmpAdic,{"","",.f.})
	EndIf
	
	_oBrwDetAdic:aCols := aClone(_aTmpAdic)
	_oBrwDetAdic:oBrowse:Refresh()

	// habilito as abas
	_oFldDadosPrd:aEnable(2, .T.)
Return

// ** função que retorna os movimentos da etiqueta ** //
Static Function sfDetMovim(mvIdEtiq)

	// objetos
	local _oWndDetMovim, _oBrwDetMovim, _oPnlDetMovim, _oGetDetMovim, _oBmpOpcoes, _oPnlSeptMovim
	// variavel de retorno
	local _lRet := .T.
	// area inicial
	local _aArea := GetArea()
	// seek nas tabelas de pallet e movimentos
	local _cSeekZ16 := ""
	local _cSeekZ17 := ""
	// idpallet
	local _aIdPalete := {}
	local _cAuxPlt := ""
	// status do movimento
	local _cStatMovim := ""
	local _cTipLan    := ""
	local _cTipMov    := ""
	local _cEstorno   := ""
	// arrays do browse
	local _a01ClBrw := {}, _a01HdBrw := {}
	// sub menu e opções
	local _oMnuOpcoes, _oSbMnOp01, _oSbMnOp02, _oSbMnOp03
	// controle de loop
	local _nPal := 0

	// array para movimentos da tabela Z17
	private _aZ17Movim := {}

	//01-ETIQUETA DE PRODUTO
	//04-ETIQUETA DE VOLUME

	If Empty(mvIdEtiq)
		Return( .F. )
	EndIf

	// valido o tipo da etiqueta, pra não deixar apresentar movimentações de etiq de pallet ou endereço
	// somente Produto e Volume
	If (Z11->Z11_TIPO != "01") .And. (Z11->Z11_TIPO != "04")
		U_FtWmsMsg("Opção disponível somente para Etiquetas de Produto ou Etiquetas de Volume.","Atenção")
		_lRet := .F.
	EndIf

	// se a etiqueta é a certa, prossegue com as informações
	// pega o num do palete
	If (_lRet)
		// posiciono no registro do pallet
		dbSelectArea("Z16")

		// validação pro tipo de order na consulta
		// PRODUTO
		If (Z11->Z11_TIPO == "01")

			Z16->( dbSetOrder(2) ) //FILIAL+ETQPRD
			_lRet := Z16->( dbSeek( _cSeekZ16 := xFilial("Z16")+mvIdEtiq ) )

			// pra todos os registros encontrados
			While (_lRet) .And. (Z16->( ! EoF() )) .And. (Z16->Z16_FILIAL + Z16->Z16_ETQPRD == _cSeekZ16)
				// pra evitar duplicação de regtistros
				If (Empty(_cAuxPlt)) .Or. (_cAuxPlt != Z16->Z16_ETQPAL)
					aAdd(_aIdPalete, { Z16->Z16_ETQPAL } )
				EndIf

				_cAuxPlt := Z16->Z16_ETQPAL
				// prox registro
				Z16->( dbSkip() )
			EndDo
			// VOLUME
		ElseIf (Z11->Z11_TIPO == "04")

			Z16->( dbSetOrder(4) ) //FILIAL+ETQVOL
			_lRet := Z16->( dbSeek( _cSeekZ16 := xFilial("Z16")+mvIdEtiq ) )

			// pra todos os registros encontrados
			While (_lRet) .And. (Z16->( ! EoF() )) .And. (Z16->(Z16_FILIAL+Z16_ETQVOL) == _cSeekZ16)
				// pra evitar duplicação de regtistros
				If (Empty(_cAuxPlt)) .Or. (_cAuxPlt != Z16->Z16_ETQPAL)
					aAdd(_aIdPalete, { Z16->Z16_ETQPAL } )
				EndIf

				_cAuxPlt := Z16->Z16_ETQPAL
				// prox registro
				Z16->( dbSkip() )
			EndDo
		EndIf

		// se não encontrou registro de pallet
		If (Len(_aIdPalete) == 0)
			U_FtWmsMsg("Nenhum registro de pallet encontrado.","Atenção")
			_lRet := .F.
		EndIf
	EndIf

	// pega a info das movimentações
	If (_lRet)
		// posiciono no registro do pallet
		dbSelectArea("Z17")
		Z17->( dbSetOrder(1) ) //FILIAL+ETQPAL

		// pra todos os registros de pallets encontrados
		For _nPal := 1 to Len(_aIdPalete)
			Z17->( dbSeek( _cSeekZ17 := xFilial("Z17")+_aIdPalete[_nPal][1] ) )

			// pra todos os registros encontrados, vou validar se o código do pallet é único
			While (Z17->( ! EoF() )) .And. (Z17->(Z17_FILIAL+Z17_ETQPLT) == _cSeekZ17)
				// somente para registros que foram realizados
				If (Z17->Z17_STATUS != "C")
					// preencho o array com os movimentos
					_cStatMovim := sfRetDesc(Z17->Z17_STATUS, "Z17_STATUS")
					// tipo de lançamento
					_cTipLan    := sfRetDesc(Z17->Z17_TIPLAN, "Z17_TIPLAN")
					// tipo de movimento
					_cTipMov    := sfRetDesc(Z17->Z17_TIPMOV, "Z17_TIPMOV")
					// estorno
					_cEstorno   := Iif(Z17->Z17_ESTORN == "S","Sim", "")
					// insiro os dados no array
					aAdd(_aZ17Movim, { Z17->Z17_ENDORI, Z17->Z17_ENDDES, ;
					Z17->Z17_NUMOS, Z17->Z17_OPERAD,  ;
					_cTipLan, _cTipMov, _cEstorno,    ;
					_cStatMovim, Z17->Z17_ETQPLT,     ;
					Z17->( Recno() ), .F. } )
				EndIf

				// prox registro
				Z17->( dbSkip() )
			EndDo
		Next _nPal

		// valido se encontrou algum registro
		If (Len(_aZ17Movim) == 0)
			U_FtWmsMsg("Nenhum registro de movimentação encontrado!","Atenção")
			_lRet := .F.
		Else
			// ordena o array do mais novo pro mais velho (com base no RECNO)
			aSort(_aZ17Movim ,,,{ |x,y| x[10] > y[10]} )
		EndIf
	EndIf

	// preencho o acols do browse e defino o header
	If (_lRet)
		If (Len(_a01HdBrw) == 0)
			aAdd(_a01HdBrw,{"Origem"       ,"IT_ORIGEM", PesqPict("SBE","BE_LOCALIZ"),  TamSx3("BE_LOCALIZ")[1],0,Nil,Nil,"C",Nil,"R" })
			aAdd(_a01HdBrw,{"Destino"      ,"IT_DESTINO",PesqPict("SBE","BE_LOCALIZ"),  TamSx3("BE_LOCALIZ")[1],0,Nil,Nil,"C",Nil,"R" })
			aAdd(_a01HdBrw,{"Num. OS"      ,"IT_NUMOS",  "",  TamSx3("Z17_NUMOS")[1] ,0,Nil,Nil,"C",Nil,"R" })
			aAdd(_a01HdBrw,{"Operador"     ,"IT_OPERAD", "",  TamSx3("Z17_OPERAD")[1],0,Nil,Nil,"C",Nil,"R" })
			aAdd(_a01HdBrw,{"Tp.Movim"     ,"IT_TPMOVI", "",  15                     ,0,Nil,Nil,"C",Nil,"R" })
			aAdd(_a01HdBrw,{"Tp.Lanc"      ,"IT_TPLANC", "",  15                     ,0,Nil,Nil,"C",Nil,"R" })
			aAdd(_a01HdBrw,{"Estorno"      ,"IT_ESTORN", "",  3                      ,0,Nil,Nil,"C",Nil,"R" })
			aAdd(_a01HdBrw,{"Status"       ,"IT_STATUS", "",  10                     ,0,Nil,Nil,"C",Nil,"R" })
			aAdd(_a01HdBrw,{"Etiqueta.Plt" ,"IT_PALETE", PesqPict("Z17","Z17_ETQPLT"),  TamSx3("Z17_ETQPLT")[1],0,Nil,Nil,"C",Nil,"R" })
		EndIf
		// acols do browse sendo preenchido
		_a01ClBrw := aClone(_aZ17Movim)

		// definicao da tela de movimentos
		_oWndDetMovim := MSDialog():New(000,000,320,240,"WMS - Movimentos",,,.F.,,,,,,.T.,,,.T.)

		// sub-menu de opções
		_oMnuOpcoes := TMenu():New(0,0,0,0,.T.)
		_oSbMnOp01 := TMenuItem():New(_oMnuOpcoes,"Estornar Ult. Movim.",,,,{ || Processa({ || U_FtEstMov(@_lRet, _oBrwDetMovim:aCols[_oBrwDetMovim:nAt][Len(_a01HdBrw)]) },,"Validando dados..."), Iif(_lRet, { _oWndDetMovim:End(), sfVldEtiqueta(@_oBmpEtqBlq)}, Nil) },,"ESTOMOVI",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOp01)
		// filtra somente quando for supervisor
		If ((_lUsrGeren) .Or. (_lUsrAccou) .Or. (_lUsrSuper))
			_oSbMnOp02 := TMenuItem():New(_oMnuOpcoes,"Reabrir OS",,,,{|| U_WMSA009I(_oBrwDetMovim:aCols[_oBrwDetMovim:nAt][3], .f.)},,"DEVOLNF",,,,,,,.T.)
			_oMnuOpcoes:Add(_oSbMnOp02)
		EndIf
		_oSbMnOp03 := TMenuItem():New(_oMnuOpcoes,"Sair",,,,{|| _oWndDetMovim:End(), sfVldEtiqueta(@_oBmpEtqBlq)},,"FINAL",,,,,,,.T.)
		_oMnuOpcoes:Add(_oSbMnOp03)

		// painel com as opcoes disponiveis
		_oPnlDetMovim := TPanel():New(000,000,nil,_oWndDetMovim,,.F.,.F.,,,22,22,.T.,.F. )
		_oPnlDetMovim:Align:= CONTROL_ALIGN_TOP
		_oPnlDetMovim:nClrPane := CLR_HGRAY

		// painel separador
		_oPnlSeptMovim := TPanel():New(000,000,nil,_oWndDetMovim,,.F.,.F.,,,5,5,.T.,.F. )
		_oPnlSeptMovim:Align:= CONTROL_ALIGN_TOP

		// informação da etiqueta utilizada
		_oSayIdEtiqueta := TSay():New(001,003,{||"Etiqueta"},_oPnlDetMovim,,,.F.,.F.,.F.,.T.)
		_oGetDetMovim := TGet():New(008,003,{|u| If(PCount()>0,mvIdEtiq:=u,mvIdEtiq)},_oPnlDetMovim,050,010,_cMskEtiq,/**/,,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","mvIdEtiq",,)
		_oGetDetMovim:lActive := .F.

		// mais opções
		_oBmpOpcoes := TBtnBmp2():New(000,000,060,022,"SDUAPPEND",,,,{|| Nil },_oPnlDetMovim,"",,.T.)
		_oBmpOpcoes:Align := CONTROL_ALIGN_RIGHT
		_oBmpOpcoes:SetPopupMenu(_oMnuOpcoes)

		// browse com os detalhes da movimentação
		_oBrwDetMovim := MsNewGetDados():New(000,000,600,600,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_a01ClBrw),'AllwaysTrue()','','AllwaysTrue()',_oWndDetMovim,_a01HdBrw,_a01ClBrw)
		_oBrwDetMovim:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
		_oBrwDetMovim:oBrowse:oFont := _oFnt02

		// ativa a tela
		ACTIVATE MSDIALOG _oWndDetMovim

	EndIf

Return (_lRet)

// ** função que vai realizar o estorno da movimentação ** //
User Function FtEstMov(mvRet, mvPlt)

	// variavel de controle
	local _lRet := .T.
	// area inicial
	local _aArea := GetArea()
	// seek na Z05
	local _cSeekZ05 := ""
	// seek na Z06
	local _cSeekZ06 := ""
	// seek na Z07
	local _cSeekZ07 := ""
	// seek na Z08
	local _cSeekZ08 := ""
	// seek na Z16
	local _cSeekZ16 := ""
	// seek na Z17
	local _cSeekZ17 := ""
	// array de dados do pallet
	local _aProdPlt := {}
	// array de movimentos internos
	local _aMovInt := {}
	// controle de loop
	local _nProd := 0
	// query de análise
	local _cQuery := ""
	local _aCabSDA, _aItemSDB
	// recno para posicionar registro
	local _nRecnoSDB := 0
	local _aAreaSDA := {}
	// variaveis para movimentação
	local _aDadosMov := {}
	// tipo de movimento de origem
	local _cTpOriMov := ""
	// variavel para controle de for
	local _nX := 0
	// itens para estorno da transferencia de mercadoria
	local _aItemSD3 := {}
	// tipo de operação
	local _cTpOper := ""
	// controle de modulo, antes de chamar rotina automatica
	local _nModOld

	// controle de estorno da movimentacao
	local _lEstMovOk := .F.

	// controle de estorno sem NF
	local _lEstSNF := .F.

	// se o endereço atual estorna *DE* rua, o que significa que não é necessário estorno em tabelas padrão (SDB/SDA/SD3/etc), apenas as customizadas
	local _lEstRua := .F.
	
	// se o emdereço atual estorna *DE* BLOCO e armazenamento foi sem NF necessário utilizar tipo de estoque origem
	local _lEstBloc := .F.
	
	// tipo de estoque da OS
	local _cTpEsto := ""

	/*
	002=APANHA DE PRODUTOS
	003=CONFERENCIA
	004=CARREGAR VEICULOS
	005=CHEGADA VEICULOS - PORTARIA
	007=MONTAR PALETE
	009=ENDERECAMENTO
	013=TRANSFERENCIA
	T02=INVENTARIO
	T05=RETRABALHO
	*/

	// Nota para Programador: Adicione os outros movimentos que sejam possíveis estornar para controle
	/*
	1 - Recebimento de Mercadoria
	2 - Transferência Interna (Exceto Retrabalho)
	*/

	// variavel utilizada nas funcões automáticas
	private lMsErroAuto := .F.
	private lMsHelpAuto := .T.

	// pergunta pro usuário se quer realizar o estorno
	_lRet := U_FtYesNoMsg("Deseja realizar o estorno?","Atenção")

	// se optou por estornar
	If (_lRet)
		// pego o último movimento realizado, que não foi estornado
		_cQuery := " SELECT TOP 1 Z17_ENDORI, Z17_ENDDES, Z17_LOCORI, Z17_LOCDES, Z17_NUMOS, Z17_SEQOS, Z17_TIPMOV, Z17.R_E_C_N_O_ "
		_cQuery += " FROM   " + RetSqlTab("Z17")
		_cQuery += " WHERE " + RetSqlCond("Z17")
		_cQuery += "       AND Z17_ETQPLT = '"+mvPlt+"' "
		_cQuery += "       AND Z17_TIPLAN <> 'ES' "
		_cQuery += "       AND Z17_STATUS = 'R' "
		_cQuery += "       AND Z17_ESTORN = '' "
		_cQuery += " ORDER BY  R_E_C_N_O_ DESC "

		// gero arquivo para debug
		memowrit("C:\query\twmsa015_ftestmov.txt",_cQuery)

		// dados do movimento
		_aDadosMov := U_SqlToVet(_cQuery)

		// caso não tenha encontrado registros
		If (Len(_aDadosMov) == 0)
			// avisa usuario
			U_FtWmsMsg("Não foram encontrados registros para estorno.","Atenção")
			// variavel de controle
			_lRet := .F.
		Else
			// preencho as variáveis usadas no sistema
			_cOriMov   := _aDadosMov[1][2] // invertido - origem
			_cDesMov   := _aDadosMov[1][1] // invertido - destino
			_cLocOri   := _aDadosMov[1][4] // invertido - local de origem
			_cLocDes   := _aDadosMov[1][3] // invertido - local de destino
			_cNumOs    := _aDadosMov[1][5] // número da os
			_cSeqOs    := _aDadosMov[1][6] // sequência da os
			_cTpOriMov := _aDadosMov[1][7] // tipo de movimento de origem (MV/MH/MA)
		EndIf
	EndIf

	// se encontrou dados, prossegue
	If (_lRet)
		// posiciono na OS, pra validar se é de recebimento
		dbSelectArea("Z05")
		Z05->( dbSetOrder(1) ) // FILIAL+NUMOS
		If ( Z05->( dbSeek( _cSeekZ05 := xFilial("Z05") + _cNumOs ) ) )
			_cTpOper := Z05->Z05_TPOPER
		EndIf

		// se não for OS de recebimento, não deixa prosseguir
		If ( ! _cTpOper $ "E/I" )
			U_FtWmsMsg("Rotina disponível somente para OS de Recebimento e Transferência Interna.","Atenção")
			_lRet := .F.
		EndIf
	EndIf

	// validação da OS
	If (_lRet)
		// posiciono na OS, pra validar se está disponível pra estornar
		dbSelectArea("Z06")
		Z06->( dbSetOrder(1) ) // FILIAL+NUMOS+SEQOS
		Z06->( dbSeek( _cSeekZ06 := xFilial("Z06") + _cNumOs + _cSeqOS) )

		// pra todos os movimentos da OS
		While (Z06->( ! EoF() )) .And. (Z06->Z06_FILIAL + Z06->Z06_NUMOS + Z06->Z06_SEQOS == _cSeekZ06)

			// endereçamento/transferência/conferencia de recebimento
			If ( (Z06->Z06_TAREFA == "009") .AND. (Z06->Z06_STATUS != "EX") ) .OR. ;
			( (Z06->Z06_TAREFA == "013") .AND. (Z06->Z06_STATUS != "EX") ) .OR. ;
			( (Z06->Z06_TAREFA == "003") .AND. (Z06->Z06_SERVIC == "003") .AND. (Z06->Z06_STATUS != "EX") )
				// avisa usuario
				U_FtWmsMsg("A OS "+Z06->Z06_NUMOS+" não está liberada. Favor solicitar ao Supervisor a liberação da OS.","Atenção")
				// variavel de controle
				_lRet := .F.
			EndIf
			// próx registro
			Z06->( dbSkip() )
		EndDo
	EndIf

	// valida se pallet já não está no plano/mapa de outra OS
	If (_lRet)
		_cQuery := "SELECT COUNT(R_E_C_N_O_) QTD_REG FROM " + RetSqlTab("Z08") + " (NOLOCK) "
		_cQuery += " WHERE " + RetSqlCond("Z08")
		_cQuery += " AND Z08_PALLET = '" + mvPlt + "' AND Z08_STATUS != 'R' "
		_cQuery += " AND Z08_NUMOS != '" + _cNumOs + "'"  // se não for a própria OS

		// se encontrou registro, cancela
		If (U_FtQuery(_cQuery) > 0)
			// avisa usuario
			U_FtWmsMsg("Não é possível o estorno pois o pallet está previsto/reservado em outra OS!","Atenção")
			_lRet := .F.
		EndIf
	EndIf

	// se passou pelas validações da OS, começa a preparar os dados
	If (_lRet)

		// efetua consulta na Z08 para verificar se o Pallet é tipo de estoque 000023-Conferencia sem NF
		_cQuery := " SELECT Count(*) "
		_cQuery += " FROM " + RetSqlName("Z08") + " Z08 (NOLOCK) "
		_cQuery += " INNER JOIN " + RetSqlName("Z16") + " Z16 (NOLOCK) "
		_cQuery += " ON Z08.Z08_FILIAL = Z16.Z16_FILIAL "
		_cQuery += " AND Z16.D_E_L_E_T_ = '' "
		_cQuery += " AND Z08.Z08_LOCAL = Z16.Z16_LOCAL "
		_cQuery += " AND Z08.Z08_ENDSRV = Z16.Z16_ENDATU "
		_cQuery += " AND Z08.Z08_PRODUT = Z16.Z16_CODPRO "
		_cQuery += " AND Z08.Z08_PALLET = Z16.Z16_ETQPAL "
		_cQuery += " AND Z08.Z08_TPESTO = Z16.Z16_TPESTO "
		_cQuery += " AND Z16.Z16_SALDO > 0 "
		_cQuery += " WHERE Z08.Z08_FILIAL = '" + xFilial("Z08") + "' "
		_cQuery += " AND Z08.D_E_L_E_T_ = '' "
		_cQuery += " AND Z08.Z08_NUMOS = '" + _cNumOs + "' "
		_cQuery += " AND Z08.Z08_STATUS IN ('R','P') "
		_cQuery += " AND Z08.Z08_PALLET = '" + mvPlt + "' "
		_cQuery += " AND Z08.Z08_TPESTO = '000023' "
		memowrit("C:\query\twmsa015_TpEsto.txt",_cQuery)

		If (U_FtQuery(_cQuery) > 0)
			// Então é estorno sem NF - tipo de estoque 23
			_lEstSNF := .T.
		EndIf

		If (_lRet) .And. ( _cTpOper == "E" )
			// posiciona no cadastro do endereco
			dbSelectArea("SBE")
			SBE->(dbSetOrder(1)) // BE_FILIAL, BE_LOCAL, BE_LOCALIZ, R_E_C_N_O_, D_E_L_E_T_
			SBE->( dbSeek( xFilial("SBE") + _cLocOri + _cOriMov ))

			// flag que simboliza se o endereço sendo estornado é RUA/TRANSITORIO
			_lEstRua := (SBE->BE_ESTFIS == "000009")
			
			If (!_lEstRua)
				_lEstBloc := (SBE->BE_ESTFIS == "000007")
			Endif
		Endif
		
		// inicio a transação
		BeginTran()
		// se for tipo de estoque 000023-Conferencia sem NF, não efetua o estorno SDB/SDA
		If (!_lEstSNF)
			// estorno a armazenagem padrão MATA265
			If (_lRet) .And. ( _cTpOper == "E" )

				// retorna os produtos que compoe o palete
				// 1-Cod Produto
				// 2-Num Seq
				// 3-Quantidade
				// 4-Lote
				// 5-Validade do Lote
				// 6-Endereço Atual
				// 7-Armazém Atual
				_aProdPlt := sfRetPlt( Nil, mvPlt, _cLocOri)

				// caso não tenha encontrado nenhum registro
				If (Len(_aProdPlt) == 0)
					// mensagem
					U_FtWmsMsg("Nenhum dado encontrado para estorno da rotina automática.","Atenção")
					// variavel de controle
					_lRet := .F.
				Else

					// processamento da tela
					ProcRegua(Len(_aProdPlt))

					// varre todos os produtos do palete
					For _nProd := 1 to Len(_aProdPlt)

						//increase de processamento
						IncProc()

						// posiciona nos itens a estornar
						dbSelectArea("SDA")
						SDA->(dbOrderNickName("DA_NUMSEQ")) // 2-DA_FILIAL, DA_PRODUTO, DA_NUMSEQ

						// valido os dados da SDA
						If ! SDA->(dbSeek( xFilial("SDA") + _aProdPlt[_nProd][1] + _aProdPlt[_nProd][2] ))
							// mensagem
							U_FtWmsMsg("Erro verificando dados na SDA","Atenção")
							// variavel de controle
							_lRet := .f.
							// pra sair do for
							Exit
						EndIf

						// guarda posicao do SDA
						_aAreaSDA := SDA->(GetArea())

						// caso aquele produto específico preciso desmontar o lote
						If (_lRet) .And. (Rastro(SDA->DA_PRODUTO)) .And. (SDA->DA_LOTECTL <> _aProdPlt[_nProd][4])

							// rotina pra desmontagem de lote
							_lRet := U_FtEstDes(SDA->DA_PRODUTO, mvPlt, _cLocOri, .F.)

							// caso não foi realizado o estorno e desmontagem avisa o usuário e sai do for
							If ( ! _lRet )
								// mensagem
								U_FtWmsMsg("Erro ao realizar a Desmontagem do Lote.","Atenção")
								// pra sair do for
								Exit
							EndIf

						EndIf

						If (_lRet)

							// restaura posicao do SDA
							RestArea(_aAreaSDA)

							// valida se eh armazem diferente / se for, estorna a trasnferencia entre armazens
							If (SDA->DA_LOCAL != _cLocOri)

								// monta a query para buscar os movimentos do SD3
								_cQuery := " SELECT R_E_C_N_O_ D3_RECNO "
								// movimento interno
								_cQuery += " FROM "+RetSqlTab("SD3")
								// filtro padrão
								_cQuery += " WHERE "+RetSqlCond("SD3")
								// numero da ordem de servico
								_cQuery += " AND D3_ZNUMOS  = '" + _cNumOs + "' "
								_cQuery += " AND D3_ZSEQOS = '" + _cSeqOs + "' "
								// pallet correspondente
								_cQuery += " AND D3_ZETQPLT  = '" + mvPlt + "' "
								// estorno
								_cQuery += " AND D3_ESTORNO = ' ' "
								// somente um dos enderecos
								_cQuery += " AND D3_LOCALIZ = '" + _aProdPlt[_nProd][6] + "' "

								// avisa o usuário
								memowrit("c:\query\twmsa015_estorno_transf_arm_diferente.txt", _cQuery)

								// joga os dados pro array
								_aMovInt := U_SqlToVet( _cQuery )

								// chama o grupo de perguntas padrao da rotina MATA260
								pergunte("MTA260",.f.)

								// define o parametro "Considera Saldo poder de 3" como NAO
								mv_par03 := 2

								// varre todos os enderecos
								For _nX := 1 to len(_aMovInt)

									// posiciona na movimentacao
									dbSelectArea("SD3")
									SD3->( dbGoTo( _aMovInt[_nX] ) )

									// reinicia variáveis
									lMsHelpAuto := .T.
									lMsErroAuto := .F.

									// executa rotina automatica
									MSExecAuto( { |x,y| mata261(x,y) }, _aItemSD3, 6 ) // 6-estorno

									// se alguma coisa deu errada
									If (lMsErroAuto)
										// apresenta mensagem com o error.log
										U_FtWmsMsg( sfAchaErro(),"Atenção - Int" )
										// variável de retorno
										_lRet := .f.
										// sai da rotina para rollback
										Exit
									EndIf

								Next _nX

							EndIf
						EndIf

						If (_lRet)

							// restaura posicao do SDA
							RestArea(_aAreaSDA)

							// pego o recno do registro que precisa movimentar
							_cQuery := " SELECT R_E_C_N_O_ RECNO FROM "+RetSqlTab("SDB")
							_cQuery += " WHERE "+RetSqlCond("SDB")
							_cQuery += " AND DB_ZPALLET = '"+mvPlt+"' "
							_cQuery += " AND DB_ZNUMOS = '"+_cNumOs+"' "
							_cQuery += " AND DB_ZSEQOS = '"+_cSeqOs+"' "
							_cQuery += " AND DB_LOTECTL = '"+SDA->DA_LOTECTL+"' "
							_cQuery += " AND DB_NUMSEQ = '"+SDA->DA_NUMSEQ+"' "
							_cQuery += " AND DB_ESTORNO = '' "

							// gero arquivo para debug
							memowrit("C:\query\twmsa015_recnosdb.txt",_cQuery)

							// retorno o RECNO para a variável
							_nRecnoSDB := U_FtQuery(_cQuery)

							// posiciono na D1 pra pegar o ITEM
							dbSelectArea("SDB")
							SDB->( dbGoTo(_nRecnoSDB) )

							// se o registro na SDB não foi encontrado ou já foi estornado, não deixa prosseguir
							If ( SDB->( EoF() ) )
								Loop
							EndIf

							// zera variaveis
							_aCabSDA := {}
							_aItemSDB := {}

							// armazena modulo atual
							_nModOld := nModulo

							// muda o modulo para WMS
							nModulo := 4

							// chama o grupo de perguntas padrao da rotina MATA265
							pergunte("MTA265", .f.)

							// cabeçalho com base ba SDA
							_aCabSDA := {;
							{"DA_PRODUTO"	,SDA->DA_PRODUTO,NIL},;
							{"DA_QTDORI"	,SDA->DA_QTDORI	,NIL},;
							{"DA_SALDO"		,SDA->DA_SALDO	,NIL},;
							{"DA_DATA"  	,SDA->DA_DATA	,NIL},;
							{"DA_LOTECTL"	,SDA->DA_LOTECTL,NIL},;
							{"DA_DOC"		,SDA->DA_DOC	,NIL},;
							{"DA_SERIE"		,SDA->DA_SERIE	,NIL},;
							{"DA_CLIFOR"	,SDA->DA_CLIFOR	,NIL},;
							{"DA_LOJA"		,SDA->DA_LOJA	,NIL},;
							{"DA_TIPONF"	,SDA->DA_TIPONF	,NIL},;
							{"DA_NUMSEQ"	,SDA->DA_NUMSEQ	,NIL},;
							{"DA_LOCAL"		,SDA->DA_LOCAL	,NIL},;
							{"DA_ORIGEM"	,SDA->DA_ORIGEM	,NIL}}

							// item a estornar
							aAdd(_aItemSDB,{;
							{"DB_ITEM"		,SDB->DB_ITEM     ,NIL},;
							{"DB_ESTORNO" 	,"S"			  ,Nil},; // S=Sim - Para estornar o registro
							{"DB_DATA"	    ,SDB->DB_DATA     ,NIL},;
							{"DB_QUANT"		,SDB->DB_QUANT    ,NIL}})

							// rotina automatica de endereçamento - usada pro estorno
							lMsErroAuto := .F.
							MSExecAuto({|x,y,z| mata265(x,y,z)}, _aCabSDA, _aItemSDB, 4) //4-Estorno

							// retorna o modulo padrao
							nModulo := _nModOld

							// se deu erro ao realizar o estorno
							If (lMsErroAuto)
								// apresenta mensagem com o error.log
								U_FtWmsMsg(sfAchaErro(),"Atenção - Rec")
								// variavel de retorno
								_lRet := .F.
							EndIf

							// atualiza variavel de movimentacao
							_lEstMovOk := _lRet

						EndIf

					Next _nProd

				EndIf

			EndIf

			// para operações internas, quando a origem for blocado ou portapallet
			If ( _lRet ) .And. ( _cTpOper == "I" )

				// monta a query para buscar os movimentos do SD3
				_cQuery := " SELECT R_E_C_N_O_ D3_RECNO"
				// movimento interno
				_cQuery += " FROM "+RetSqlTab("SD3")
				// filtro padrão
				_cQuery += " WHERE "+RetSqlCond("SD3")
				// numero da carga
				_cQuery += " AND D3_ZNUMOS  = '" + _cNumOs + "' "
				// pallet correspondente
				_cQuery += " AND D3_ZETQPLT  = '" + mvPlt + "' "
				// estorno
				_cQuery += " AND D3_ESTORNO = ' ' "

				// avisa o usuário
				memowrit("c:\query\twmsa015_estorno_mov_interno.txt", _cQuery)

				// joga os dados pro array
				_aMovInt := U_SqlToVet( _cQuery )

				// chama o grupo de perguntas padrao da rotina MATA260
				pergunte("MTA260",.f.)

				// define o parametro "Considera Saldo poder de 3" como NAO
				mv_par03 := 2

				// varre todos os enderecos
				For _nX := 1 to len(_aMovInt)

					// posiciona na movimentacao
					dbSelectArea("SD3")
					SD3->( dbGoTo( _aMovInt[_nX] ) )

					// reinicia variáveis
					lMsHelpAuto := .T.
					lMsErroAuto := .F.

					// executa rotina automatica
					MSExecAuto( { |x,y| mata261(x,y) }, _aItemSD3, 6 ) // 6-estorno

					// se alguma coisa deu errada
					If (lMsErroAuto)

						// apresenta mensagem com o error.log
						U_FtWmsMsg( sfAchaErro(),"Atenção - Int" )
						// variável de retorno
						_lRet := .f.
						// sai da rotina para rollback
						Exit
					EndIf
				Next _nX
			EndIf
		EndIf

		// só prossegue com o controle de transação
		If (_lRet) .And. ( _cTpOper $ "E/I" ) .And. ((_lEstMovOk .OR. _lEstRua) .OR. (_lEstSNF))     //se em rua (BE_ESTFIS = 9 ), não há movimento na SDB, mas preciso continuar

			// posiciono na OS, pra validar se está disponível pra estornar
			dbSelectArea("Z08")
			Z08->( dbGoTop() )
			Z08->( dbSetOrder(3) ) // FILIAL+NUMOS+PALLET
			// se achou, grava os dados
			If (  Z08->( dbSeek( _cSeekZ08 := xFilial("Z08") + _cNumOs + mvPlt) ) )

				// pra todos os movimentos da OS no mapa
				While (Z08->( ! EoF() )) .And. (Z08->Z08_FILIAL + Z08->Z08_NUMOS + Z08->Z08_PALLET == _cSeekZ08)

					// registros pro pallet específico
					If (Z08->Z08_PALLET == mvPlt) .And. ( ! Empty(Z08->Z08_DTINIC) )

						If (_lEstSNF .AND. (Z08->Z08_ENDSRV == Z08->Z08_ENDDES) .AND. Z08->Z08_STATUS == "R" .AND. !_lEstRua)
							// Verifica se o endereço da distribuição está bloqueado e muda o Status para Desocupado
							dbSelectArea("SBE")
							dbSetOrder(1) //BE_FILIAL, BE_LOCAL, BE_LOCALIZ, BE_ESTFIS
							IF dbSeek(xFilial("SBE")+Z08->Z08_LOCAL+Z08->Z08_ENDDES)
								If SBE->BE_STATUS == "3" // Endereço Bloqueado
									RecLock("SBE",.F.)
									SBE->BE_STATUS	:= "1" // Endereço desocupado
									MsUnLock()
								EndIf
							EndIf

						EndIf

						// Se for estorno com origem na rua, realmente é ultimo movimento inverso, então "devolvo o tipo de estoque original"
						If (_lEstSNF .AND. (_lEstRua .OR. _lEstBloc))
							_cQuery := " SELECT Z07_TPESTO "
							_cQuery += " FROM  	" + RetSqlTab("Z07") + " (NOLOCK) "
							_cQuery += " WHERE  " + RetSqlCond("Z07")
							_cQuery += "        AND Z07_NUMOS = '" + _cNumOs + "' "
							_cQuery += "        AND Z07_PALLET = '" + mvPlt + "' "

							_cTpEsto := U_FtQuery(_cQuery)
						Endif

						// se o destino do estorno for rua
						If (Len(AllTrim(_cDesMov)) == 2)

							Reclock("Z08")
							Z08->Z08_DTFINA := CtoD("//")
							Z08->Z08_HRFINA := ""
							Z08->Z08_USUARI := ""
							Z08->Z08_USRMOV := ""
							Z08->Z08_STATUS := "P"
							Z08->Z08_ENDSRV := _cDesMov
							Z08->Z08_LOCAL  := _cLocOri
							Z08->Z08_LOCDES := _cLocDes
							Z08->Z08_USRMOV := Space(Len(Z08->Z08_USRMOV))
							Z08->( MsUnlock() )
							// se a origem do estorno for a rua
						ElseIf (Len(AllTrim(_cOriMov)) == 2)

							Reclock("Z08")
							Z08->Z08_PALLET := Iif( _cTpOper == "E", Space(Len(Z08->Z08_PALLET)), mvPlt ) // específico para entrada
							Z08->Z08_LOTCTL := Space(Len(Z08->Z08_LOTCTL))
							Z08->Z08_DTINIC := CtoD("//")
							Z08->Z08_HRINIC := ""
							Z08->Z08_USUARI := ""
							Z08->Z08_USRMOV := ""
							Z08->Z08_EQUIPA := ""
							Z08->Z08_STATUS := "P"
							Z08->Z08_ENDSRV := _cDesMov
							Z08->Z08_LOCAL  := _cLocOri
							Z08->Z08_LOCDES := _cLocDes
							If ( _lEstSNF .AND. (_lEstRua .OR. _lEstBloc) .AND. !Empty(_cTpEsto) )
								Z08->Z08_TPESTO := ""
							Endif
							Z08->( MsUnlock() )
						Else

							// limpa tudo e deixa disponível
							Reclock("Z08")
							Z08->Z08_PALLET := Iif( _cTpOper == "E", Space(Len(Z08->Z08_PALLET)), mvPlt ) // específico para entrada
							Z08->Z08_LOTCTL := Space(Len(Z08->Z08_LOTCTL))
							Z08->Z08_DTINIC := CtoD("//")
							Z08->Z08_HRINIC := ""
							Z08->Z08_USUARI := ""
							Z08->Z08_EQUIPA := ""
							Z08->Z08_STATUS := "P"
							Z08->Z08_ENDSRV := _cDesMov
							Z08->Z08_DTFINA := CtoD("//")
							Z08->Z08_HRFINA := ""
							Z08->Z08_USUARI := ""
							Z08->Z08_USRMOV := ""
							Z08->Z08_STATUS := "P"
							Z08->Z08_LOCAL  := _cLocOri
							Z08->Z08_LOCDES := _cLocDes
							If ( _lEstSNF .AND. (_lEstRua .OR. _lEstBloc) .AND. !Empty(_cTpEsto) )
								Z08->Z08_TPESTO := ""
							Endif
							Z08->( MsUnlock() )
						EndIf

					EndIf

					// próx registro
					Z08->( dbSkip() )
				EndDo
			Else
				// qualquer retorno com erro, preenche variavel como falso
				U_FtWmsMsg("Mapa não encontrado para alteração.", "Atenção")
				// variavel de controle
				_lRet := .F.
			EndIf
		EndIf

		// se transação está OK
		If (_lRet) .And. ( _cTpOper $ "E/I" ) .And. (_lEstMovOk .OR. _lEstRua .OR. _lEstSNF)  //se em rua (BE_ESTFIS = 9 ), não há movimento na SDB, mas preciso continuar

			// atualizo informações do pallet
			dbSelectArea("Z16")
			Z16->( dbSetOrder(1) ) // FILIAL+ETQPAL
			If ( Z16->( dbSeek( _cSeekZ16 := xFilial("Z16")+mvPlt ) ) )

				// atualizo todos os registros do pallet
				While (Z16->( ! EoF() )) .And. (Z16->(Z16_FILIAL+Z16_ETQPAL) == _cSeekZ16)

					Reclock("Z16")
					Z16->Z16_ENDATU := _cDesMov
					Z16->Z16_LOCAL  := _cLocDes
					If ( _lEstSNF .AND. (_lEstRua .OR. _lEstBloc) .AND. !Empty(_cTpEsto) )
						Z16->Z16_TPESTO := _cTpEsto
					Endif
					Z16->( MsUnlock() )
					// próx registro
					Z16->( dbSkip() )
				EndDo
			Else
				// qualquer retorno com erro, preenche variavel como falso
				U_FtWmsMsg("Pallet não encontrado para alteração.", "Atenção")
				// variavel de controle
				_lRet := .F.
			EndIf
		EndIf

		// somente para recebimento altera a Z07
		If (_lRet) .And. (_cTpOper == "E") .And. (_lEstMovOk .OR. _lEstRua .OR. _lEstSNF) //se em rua (BE_ESTFIS = 9 ), não há movimento na SDB, mas preciso continuar

			// posiciono na OS, pra validar se está disponível pra estornar
			dbSelectArea("Z07")
			Z07->( dbSetOrder(1) ) // FILIAL+NUMOS
			If (Z07->( dbSeek( _cSeekZ07 := xFilial("Z07") + _cNumOs) ))

				// pra todos as conferências daquele pallet
				While (Z07->( ! EoF() )) .And. ((Z07->Z07_FILIAL + Z07->Z07_NUMOS) == _cSeekZ07)

					// disponibiliza o registro na Z07 daquele pallet
					If (Z07->Z07_PALLET == mvPlt)
						Reclock("Z07")
						Z07->Z07_ENDATU := _cDesMov
						Z07->Z07_STATUS := "D"
						Z07->( MsUnlock() )
					EndIf
					// próx registro
					Z07->( dbSkip() )
				EndDo
			Else
				// qualquer retorno com erro, preenche variavel como falso
				U_FtWmsMsg("Conferência não encontrada para alteração.", "Atenção")
				// variavel de controle
				_lRet := .F.
			EndIf

		EndIf

		// continua com a transação ok
		If (_lRet) .And. (_lEstMovOk .OR. (_lEstRua .OR. _lEstBloc) .OR. _lEstSNF)     //se em rua (BE_ESTFIS = 9 ), não há movimento na SDB, mas preciso continuar
			// posiciono na Z17 e pra registrar o estorno
			dbSelectArea("Z17")
			Z17->( dbSetOrder(1) ) // Z17_FILIAL, Z17_ETQPLT, R_E_C_N_O_, D_E_L_E_T_
			Z17->( dbSeek( _cSeekZ17 := xFilial("Z17") + mvPlt ) )
			// pra encontrar o registro de movimentação que está sendo estornado
			While ( Z17->( ! EoF() )) .And. (Z17->Z17_FILIAL + Z17->Z17_ETQPLT == _cSeekZ17)
				// para registro de movimentação já realizada e que não foi estornada
				If (Z17->Z17_ENDORI == _cDesMov) .And. (Z17->Z17_ENDDES == _cOriMov) .And. (Z17->Z17_TIPLAN != "ES") .And. (Empty(Z17->Z17_ESTORN))
					// grava o registro de estorno
					Reclock("Z17")
					Z17->Z17_ESTORN = "S"
					Z17->( MsUnlock() )
				EndIf

				// próx registro
				Z17-> ( dbSkip() )
			EndDo

			// grava registro de movimento inverso na Z17
			dbSelectArea("Z17")
			RecLock("Z17",.t.)
			Z17->Z17_FILIAL := xFilial("Z17")
			Z17->Z17_ETQPLT := mvPlt
			Z17->Z17_ENDORI := _cOriMov
			Z17->Z17_ENDDES := _cDesMov
			Z17->Z17_DTINI  := Date()
			Z17->Z17_HRINI  := Time()
			Z17->Z17_OPERAD := _cCodOper
			Z17->Z17_EQUIPA := _cCodEquip
			Z17->Z17_NUMOS  := _cNumOs
			Z17->Z17_SEQOS  := _cSeqOS
			Z17->Z17_STATUS := "R" // R=Realizado / C=Cancelado / M=Em Movimento
			Z17->Z17_TEMPO  := 0
			Z17->Z17_TIPLAN := "ES" // NM=Normal / ES=Estorno / AJ=Ajuste / DV=Devolução / FR=Fracionamento / DF=Dev. Fracion.
			Z17->Z17_TIPMOV := _cTpOriMov
			Z17->Z17_ORILAN := "A" // A=Automática / M=Manual
			Z17->Z17_LOCORI := _cLocOri
			Z17->Z17_LOCDES := _cLocDes
			Z17->Z17_ESTORN := "S" // S=Sim
			Z17->(MsUnLock())
		EndIf

		// se deu erro, dá disarm na transação
		If ( ! _lRet )
			// rolback na transação
			DISARMTRANSACTION()
		Else
			// finalizo a transação
			EndTran()
			// informa o usuário do sucesso da operação
			U_FtWmsMsg("Estorno realizado com sucesso!","Atenção")
		EndIF
	EndIf

	// retorno passado por parâmetro
	mvRet := _lRet

	// restaura área inicial
	RestArea(_aArea)

Return (_lRet)

// função que retorna a descrição do status dos movimentos na Z17
Static Function sfRetDesc(mvStatus, mvCampo)

	// variavel de retorno
	local _cRet := ""

	// decode por status
	If (mvCampo == "Z17_STATUS")
		If (mvStatus == "R")
			_cRet := "Realizado"
		ElseIf (mvStatus == "M")
			_cRet := "Em Movim."
		ElseIf (mvStatus == "C")
			_cRet := "Cancelado"
		Else
			_cRet := "Undefined"
		EndIf
		// decode por tipo de lançamento
	ElseIf (mvCampo == "Z17_TIPLAN")
		If (mvStatus == "ES")
			_cRet := "Estorno"
		ElseIf (mvStatus == "AJ")
			_cRet := "Ajuste"
		ElseIf (mvStatus == "NM")
			_cRet := "Normal"
		ElseIf (mvStatus == "DV")
			_cRet := "Devolução"
		ElseIf (mvStatus == "FR")
			_cRet := "Fracionamento"
		ElseIf (mvStatus == "DF")
			_cRet := "Dev.Fracion."
		Else
			_cRet := "Undefined"
		EndIf
		// decode por tipo de movimento
	ElseIf (mvCampo == "Z17_TIPMOV")
		If (mvStatus == "MH")
			_cRet := "Movto.Horiz."
		ElseIf (mvStatus == "MV")
			_cRet := "Movto.Verti."
		ElseIf (mvStatus == "MA")
			_cRet := "Movto.Ajust."
		Else
			_cRet := "Undefined"
		EndIf
	EndIf

	// retorno
Return (_cRet)

// função para realizar o estorno da desmontagem
User Function FtEstDes(mvCodProd, mvPlt, mvLocal, mvMostraMsg)

	// area inicial
	local _aArea := GetArea()
	// controle de loop
	local _nProd := 0
	// array de produtos
	local _aProdPlt := {}, _aAutoCab, _aAutoItens
	// variavel de retorno
	local _lRet := .T.
	// variavel de apoio para querys
	local _cQuery := ""
	local _nRecno := 0
	// retorno pra rotinas automáticas
	private lMsErroAuto := .F.

	// retorna os produtos que compoe o palete
	// 1-Cod Produto
	// 2-Num Seq
	// 3-Quantidade
	// 4-Lote
	// 5-Validade do Lote
	// 6-Endereço Atual
	// 7-Armazém Atual
	_aProdPlt := sfRetPlt(mvCodProd, mvPlt, mvLocal)

	If (Len(_aProdPlt) == 0)
		U_FtWmsMsg("Não foram encontradas informações para o pallet informado. Verifique.","Atenção")
		_lRet := .F.
	EndIf

	// se encontrou dados, prossegue
	If (_lRet)
		// varre todos os produtos do palete
		For _nProd := 1 to Len(_aProdPlt)

			// vou pegar o recno da transferência na SD3
			_cQuery := " SELECT MAX(R_E_C_N_O_) RECNO "
			_cQuery += " FROM "+RetSqlTab("SD3")
			_cQuery += " WHERE "+RetSqlCond("SD3")
			_cQuery += "  AND D3_COD = '" + _aProdPlt[_nProd][1] + "' "     // código do produto
			_cQuery += "  AND D3_DOC = '" + Posicione("SD1", 4, xFilial("SD1") + _aProdPlt[_nProd][2], "D1_DOC") + "' " // documento
			_cQuery += "  AND D3_LOTECTL = '" + _aProdPlt[_nProd][4] + "' " // lote desmontado
			_cQuery += "  AND D3_CF = 'DE7' "                               // somente operações de desmontagem
			_cQuery += "  AND D3_ESTORNO = ' ' "                             // não estornados
			_cQuery += "  AND D3_LOCALIZ = '" + _aProdPlt[_nProd][6] + "' " // daquele endereço
			_cQuery += "  AND D3_ZETQPLT = '" +mvPlt+ "' "

			// arquivo texto para debug
			memowrit("C:\query\twmsa015_ftestdes_recno.txt",_cQuery)

			// jogo o recno encontrado na variável
			_nRecno := U_FtQuery(_cQuery)

			// não achou registro, já desmontou o lote em estorno de movimentação anterior
			If ( Empty(_nRecno) )
				Loop
			EndIf

			// posiciono na SD3 pra pegar estornar os registros
			dbSelectArea("SD3")
			SD3->( dbGoTop() )
			SD3->( dbGoTo(_nRecno) ) // pesquisa pelo RECNO

			// dados do lote inicial
			dbSelectArea("SD5")
			SD5-> ( dbSetOrder(3) ) // D5_FILIAL+D5_NUMSEQ+D5_PRODUTO+D5_LOCAL
			SD5-> ( dbSeek( xFilial("SD5") + _aProdPlt[_nProd][2] + _aProdPlt[_nProd][1] + _aProdPlt[_nProd][7] ) )

			// se controla rastro e o lote da DA for diferente do da Z16
			If (Rastro(SD5->D5_PRODUTO)) .And. (SD5->D5_LOTECTL <> _aProdPlt[_nProd][4])

				// zera variaveis
				_aAutoCab   := {}
				_aAutoItens := {}

				// cabeçalho das informações para estorno
				_aAutoCab := { {"cProduto", SD5->D5_PRODUTO    ,NIL},;
				{"cLocOrig"   , SD5->D5_LOCAL	           ,Nil},;
				{"nQtdOrig"   , SD5->D5_QUANT              ,Nil},;
				{"nQtdOrigSe" , SD5->D5_QTSEGUM            ,Nil},;
				{"cDocumento" , SD5->D5_DOC                ,Nil},;
				{"cNumLote"   , SD5->D5_NUMLOTE		       ,Nil},;
				{"cLoteDigi"  , SD5->D5_LOTECTL		       ,Nil},;
				{"dDtValid"   , SD5->D5_DTVALID		       ,Nil},;
				{"nPotencia"  , SD5->D5_POTENCI		       ,Nil},;
				{"cLocaliza"  , _aProdPlt[_nProd][6]       ,Nil},;
				{"cNumSerie"  , CriaVar("D3_NUMSERI")      ,Nil} }

				// itens a serem estornados
				aAdd(_aAutoItens, {{"D3_COD", SD5->D5_PRODUTO  ,NIL},;
				{"D3_LOCAL"	  , SD5->D5_LOCAL              ,NIL},;
				{"D3_QUANT"	  , _aProdPlt[_nProd][3]       ,NIL},;
				{"D3_QTSEGUM" , CriaVar("D3_QTSEGUM")      ,NIL},;
				{"D3_RATEIO"  , 100                        ,NIL},;
				{"D3_NUMLOTE" , CriaVar("D3_NUMLOTE")      ,NIL},;
				{"D3_NUMSERI" , CriaVar("D3_NUMSERI")      ,NIL},;
				{"D3_DTVALID" , _aProdPlt[_nProd][5]       ,NIL},;
				{"D3_LOTECTL" , _aProdPlt[_nProd][4]       ,NIL},;
				{"D3_LOCALIZ" , _aProdPlt[_nProd][6]       ,NIL}})

				// ordenar o vetor conforme o dicionário para uso de rotinas via MSExecAuto
				_aAutoItens := FWVetByDic(_aAutoItens, "SD3", .T.)
				// padronização da variavel
				lMsErroAuto := .F.

				// chama rotina automática de desmontagem de produtos
				MSExecAuto({|v,x,y,z| Mata242(v,x,y,z)}, _aAutoCab, _aAutoItens, 5, .T.) //5-ESTORNO

				// se deu erro ao realizar o estorno
				If (lMsErroAuto)
					// apresenta mensagem com o error.log
					U_FtWmsMsg(sfAchaErro(),"Atenção - Lote")
					// variavel de retorno
					_lRet := .f.
				EndIf
			Else
				// se mostra mensagem a partir de rotina automática
				If (mvMostraMsg)
					U_FtWmsMsg("Produto informado não possui registro de Desmontagem e/ou não controla lote. Estorno não permitido.","Atenção")
					_lRet := .F.
				EndIf
			EndIf
		Next _nProd
	EndIf

	// caso deu tudo certo
	If (_lRet)
		// se mostra mensagem a partir de rotina automática
		If (mvMostraMsg)
			U_FtWmsMsg("Desmontagem concluída.")
		EndIf
	EndIf

	// retorna area inicial
	RestArea(_aArea)
Return (_lRet)

// ** funcao que retorna os produtos que compoe o palete
Static Function sfRetPlt(mvCodProd, mvIdPalete, mvLocal)
	local _aRet := {}
	local _cQryZ16

	// valor padrao
	Default mvCodProd := CriaVar("B1_COD", .F.)

	// prepara query
	_cQryZ16 := " SELECT Z16_CODPRO, Z16_NUMSEQ, SUM(Z16_QUANT) Z16_QUANT, Z16_LOTCTL, Z16_VLDLOT, Z16_ENDATU, Z16_LOCAL "
	// formacao do palete
	_cQryZ16 += " FROM " + RetSqlTab("Z16")
	// filtro padrao
	_cQryZ16 += " WHERE " + RetSqlCond("Z16")
	// filtro do ID palete
	_cQryZ16 += " AND Z16_ETQPAL = '" + mvIdPalete + "' "
	// saldo tem que ser maior que zero
	_cQryZ16 += " AND Z16_SALDO > 0 "

	// do produto específico
	If ( ! Empty(mvCodProd) )
		_cQryZ16 += " AND Z16_CODPRO = '" + mvCodProd + "' "
	EndIf

	// filtro do armazém
	_cQryZ16 += " AND Z16_LOCAL = '" + mvLocal + "' "
	// agrupa por produto e numseq
	_cQryZ16 += " GROUP BY Z16_CODPRO, Z16_NUMSEQ, Z16_LOTCTL, Z16_VLDLOT, Z16_ENDATU, Z16_LOCAL "
	// atualiza variavel de retorno
	_aRet := U_SqlToVet(_cQryZ16,{"Z16_VLDLOT"})

	memowrit("C:\query\TWMSA015_sfRetPlt.txt", _cQryZ16)

Return(_aRet)

// ** funcao que Retorna o erro da Rotina Automatica (copia da função do fonte TWMSA011)
Static Function sfAchaErro()
	Local cStartPath:= GetSrvProfString("Startpath","")
	Local cFileLog	:= Alltrim(cStartPath) + Alltrim(NomeAutoLog())

	Local cRet		:= ""

	//Pega o Conteudo do Arquivo Texto do LOG
	Local cConteudo	:= MemoRead( cFileLog )

	Local nPos

	memowrit("C:\query\error_movi.txt",cConteudo)

	If "HELP: OBRIGAT" $ cConteudo
		cRet := StrTran(cConteudo,chr(13)+chr(10)," ")
	Else

		aConteudo := Separa(cConteudo,chr(13)+chr(10))

		For nPos := 1 to Len(aConteudo)
			If nPos == 1 .Or. nPos == 2
				cRet += aConteudo[nPos] +" "
			ElseIf "< -- Invalido" $ aConteudo[nPos]
				cRet += aConteudo[nPos] +" "
			EndIf

		Next nPos

	EndIf

	fErase(cFileLog)

Return cRet