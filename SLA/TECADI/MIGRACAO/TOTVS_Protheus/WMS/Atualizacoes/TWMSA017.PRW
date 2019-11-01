#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para configuracao do cadastro do produto         !
!                  ! - Chamada a partir da rotina TWMSA009/TACDA002          !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 10/2012 !
+------------------+---------------------------------------------------------+
!Observacoes       ! Odair - 22/07/13 Alterado pesquisa Cfg.Produto por Etiqueta.          !
+------------------+--------------------------------------------------------*/

User Function TWMSA017()
	// objetos
	local _oWndCfgProd, _oPnlCfgPrdCab, _oSayIDEtiq, _oGetIDEtiq //,_oSayCodProd, _oGetCodProd
	local _oBmpCfgPrdOk, _oBmpCfgPrdSair
	local _oBrwDetProd

	// header do browse
	local _aHeadCfgPrd := {}
	// arquivo de trabalho temporario
	local _aEstTrb := {}
	local _cArqTmp
	local _cAlTrb  := GetNextAlias()

	// cod do produto
	local _cCodProd := CriaVar("B1_COD",.f.)
	// Id do produto
	local _cEtiqProd := CriaVar("Z11_CODETI",.f.)
	// campo codigo de barras
	local _cEtqEanPrd

	// query do update
	local _cQryUpd
	local cCmpo  :=""
	local cAliasZ:=""
	local lGrvZ20 := .f.

	// variaveis temporarias
	local _cTmpCampo := ""

	// controle de confirmacao
	local _lOk := .f.

	// gravacao ok
	local _lGravaOk := .f.

	// define o tipo de etiqueta de pesquisa
	local _cTpIdEtiq := sfTipoEtq()

	// define o tipo de etiqueta para pesquisa
	private _lEtqCodInt := (AllTrim(_cTpIdEtiq) == "B1_COD")
	private _lEtqIdInt  := (AllTrim(_cTpIdEtiq) == "INTERNA")
	private _lEtqIdEAN  := (AllTrim(_cTpIdEtiq) == "EAN") .OR. (AllTrim(_cTpIdEtiq) == "EAN13")
	private _lEtqIdDUN  := (AllTrim(_cTpIdEtiq) == "DUN14")

	// prepara tamanho do codigo de barras
	If (_lEtqIdEAN)
		_cEtqEanPrd := Space(13)
	ElseIf (_lEtqIdDUN)
		_cEtqEanPrd := Space(14)
	ElseIf (_cTpIdEtiq == "SAIR")
		Return // fecha a tela
	EndIf

	// define o header
	aAdd(_aHeadCfgPrd,{"IT_TITULO","","Titulo"})
	aAdd(_aHeadCfgPrd,{"IT_DESCRI","","Descrição"})

	// define a estrutura do TRB
	aAdd(_aEstTrb,{"IT_PRODUTO","C",Len(SB1->B1_COD)    ,0})
	aAdd(_aEstTrb,{"IT_TABELA" ,"C",3                   ,0})
	aAdd(_aEstTrb,{"IT_CAMPO"  ,"C",10                  ,0})
	aAdd(_aEstTrb,{"IT_EDITA"  ,"C",                   1,0})
	aAdd(_aEstTrb,{"IT_TIPO"   ,"C",                   1,0})
	aAdd(_aEstTrb,{"IT_TITULO" ,"C",                  15,0})
	aAdd(_aEstTrb,{"IT_DESCRI" ,"C",                 200,0})

	// verifica se o alias existe
	If (Select(_cAlTrb) <> 0)
		dbSelectArea(_cAlTrb)
		dbCloseArea()
	EndIf

	// criar um arquivo de trabalho
	_cArqTmp := FWTemporaryTable():New( _cAlTrb )
	_cArqTmp:SetFields( _aEstTrb )
	_cArqTmp:Create()

	// definicao da tela de consultas
	_oWndCfgProd := MSDialog():New(000,000,(_aSizeDlg[2]),(_aSizeDlg[1]),"WMS - Cfg. Produtos",,,.F.,,,,,,.T.,,,.T. )

	// -- painel com as opcoes disponiveis
	_oPnlCfgPrdCab := TPanel():New(000,000,nil,_oWndCfgProd,,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlCfgPrdCab:Align:= CONTROL_ALIGN_TOP
	_oPnlCfgPrdCab:nClrPane := CLR_HGRAY

	// codigo do produto para pesquisa
	If (_lEtqCodInt) // codigo interna (b1_cod)
		_oSayIDEtiq := TSay():New(001,003,{||"Cod. Produto"},_oPnlCfgPrdCab,,,.F.,.F.,.F.,.T.)
		_oGetIDEtiq := TGet():New(008,003,{|u| If(PCount()>0,_cCodProd:=u,_cCodProd)},_oPnlCfgPrdCab,070,010,PesqPict("SB1","B1_COD"),{|| sfVldProduto(_cCodProd, _cTpIdEtiq, _cAlTrb, @_oBrwDetProd) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cCodProd",,)
	ElseIf (_lEtqIdInt) // etiqueta interna
		_oSayIDEtiq := TSay():New(001,003,{||"Etiq. Produto"},_oPnlCfgPrdCab,,,.F.,.F.,.F.,.T.)
		_oGetIDEtiq := TGet():New(008,003,{|u| If(PCount()>0,_cEtiqProd:=u,_cEtiqProd)},_oPnlCfgPrdCab,070,010,PesqPict("Z11","Z11_CODETI"),{|| sfVldProduto(_cEtiqProd, _cTpIdEtiq, _cAlTrb, @_oBrwDetProd) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtiqProd",,)
	ElseIf (_lEtqIdEAN) .OR. (_lEtqIdDUN) // ean 13 / DUN14
		_oSayIDEtiq := TSay():New(001,003,{||"Cód. Barras"},_oPnlCfgPrdCab,,,.F.,.F.,.F.,.T.)
		_oGetIDEtiq := TGet():New(008,003,{|u| If(PCount()>0,_cEtqEanPrd:=u,_cEtqEanPrd)},_oPnlCfgPrdCab,070,010,PesqPict("SB1","B1_CODBAR"),{|| sfVldProduto(_cEtqEanPrd, _cTpIdEtiq, _cAlTrb, @_oBrwDetProd) },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEtqEanPrd",,)
	EndIf

	// -- BOTAO SAIR
	_oBmpCfgPrdSair := TBtnBmp2():New(000,000,040,022,"FINAL",,,,{|| _oWndCfgProd:End() },_oPnlCfgPrdCab,"Sair",,.T.)
	_oBmpCfgPrdSair:Align := CONTROL_ALIGN_RIGHT

	// -- BOTAO OK
	//	_oBmpCfgPrdOk := TBtnBmp2():New(000,000,040,022,"OK",,,,{|| _lOk := .t., _oWndCfgProd:End() },_oPnlCfgPrdCab,"Ok",,.T.)
	//	_oBmpCfgPrdOk:Align := CONTROL_ALIGN_RIGHT

	// browse com os detalhes do produto
	_oBrwDetProd := MsSelect():New((_cAlTrb),"",,_aHeadCfgPrd,,,{15,1,183,373},,,_oWndCfgProd,,)
	_oBrwDetProd:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// desabilitado 28/09/18 - chamado 17148 / redmine 353
	//	_oBrwDetProd:oBrowse:BlDblClick := {|| sfEdita(_cAlTrb) }

	// ativa a tela
	ACTIVATE MSDIALOG _oWndCfgProd

	// se for true é que dá pra continuar
	If (_lOk)

		// mensagem de confirmacao
		If ( ! MsgYesNo("Confirma gravação dos dados?"))
			Return(.f.)
		EndIf

		// adiciona o conteudo
		(_cAlTrb)->(dbSelectArea(_cAlTrb))
		(_cAlTrb)->(dbGoTop())

		//Variável de controle de gravação.
		lGrvZ20 := .f.

		// varre todos os campos disponiveis
		While (_cAlTrb)->(!Eof())
			// armazena nome do campo
			_cTmpCampo := AllTrim((_cAlTrb)->IT_CAMPO)

			// verifica se o campo esta liberado para edicao
			If ((_cAlTrb)->IT_EDITA == "S").Or.(_cTmpCampo == "B1_ZCUBAGE")

				// valida o tipo da tabela
				If ((_cAlTrb)->IT_TABELA == "SB1")
					// atualiza SB1
					dbSelectArea("SB1")
					SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
					If SB1->(dbSeek( xFilial("SB1")+(_cAlTrb)->IT_PRODUTO) )

						// atualiza os dados
						Reclock("SB1",.F.)
						If (_cTmpCampo == "B1_ZCUBAGE")
							SB1->B1_ZCUBAGE := (SB5->B5_ALTURA * SB5->B5_LARG * SB5->B5_COMPR)
						ElseIf ((_cAlTrb)->IT_TIPO == "N")
							SB1->&( _cTmpCampo ) := Val((_cAlTrb)->IT_DESCRI)
						ElseIf ((_cAlTrb)->IT_TIPO == "D")
							SB1->&( _cTmpCampo ) := CtoD(AllTrim((_cAlTrb)->IT_DESCRI))
						Else
							SB1->&( _cTmpCampo ) := AllTrim((_cAlTrb)->IT_DESCRI)
						EndIf
						SB1->(MSUnlock())

					EndIf
				EndIf

				// valida o tipo da tabela
				If ((_cAlTrb)->IT_TABELA == "SB5")
					// atualiza SB5
					dbSelectArea("SB5")
					SB5->(dbSetOrder(1)) // filial+codpro
					// se encontrou grava os dados
					If SB5->(dbSeek( xFilial("SB5")+(_cAlTrb)->IT_PRODUTO) )
						// altura
						If (_cTmpCampo == "B5_ALTURA")
							Reclock("SB5",.f.)
							SB5->B5_ALTURLC := Val((_cAlTrb)->IT_DESCRI)
							SB5->B5_ALTURA  := Val((_cAlTrb)->IT_DESCRI)
							MsUnlock()
							// largura
						ElseIf (_cTmpCampo == "B5_LARG")
							Reclock("SB5",.f.)
							SB5->B5_LARGLC  := Val((_cAlTrb)->IT_DESCRI)
							SB5->B5_LARG    := Val((_cAlTrb)->IT_DESCRI)
							MsUnlock()
							// comprimento
						ElseIf (_cTmpCampo == "B5_COMPR")
							Reclock("SB5",.f.)
							SB5->B5_COMPRLC := Val((_cAlTrb)->IT_DESCRI)
							SB5->B5_COMPR   := Val((_cAlTrb)->IT_DESCRI)
							MsUnlock()
						EndIf
					EndIf
				EndIf
			EndIf
			// tudo ok
			_lGravaOk := .t.
			// proximo campo
			(_cAlTrb)->(dbSkip())
		EndDo

	EndIf

	If ValType(_cArqTmp) == "O"
		_cArqTmp:Delete()
	EndIf

Return

// ** funcao para pesquisar o produto e seus detalhes
Static Function sfVldProduto(_cChvPesq, mvTpIdEtiq, mvAliasTRB, mvObjBrowse)
	// variavel de retorno
	local _lRet := .t.
	// campos do cad. de produtos
	local _aCampos := {}
	local _nCmp
	local _cTmpCampo
	local _cTmpAlias
	// area iniacial SX3
	local _aAreaSX3 := SX3->(GetArea())

	// lastro, camada e adicional
	local _nLastro := 0
	local _nCamada := 0
	local _nAdicio := 0

	// variaveis para a funcao U_FtCodBar
	local _lInfQtdMan := .f.
	local _cNumSeq := ""


	// codigo do produto para pesquisa
	local _cTmpCodProd := Space(TamSx3("B1_COD")[1])

	// realiza a pesquisa do produto, podendo ser feita pelo codigo de barras
	If (_lRet).and.( ! U_FtCodBar(_cChvPesq, @_cTmpCodProd, @_lInfQtdMan, @_cNumSeq, mvTpIdEtiq) )
		// variavel de retorno
		_lRet := .f.
	EndIf

	// valida se encontrou codigo do produto
	If (_lRet).and.(Empty(_cTmpCodProd))
		// variavel de retorno
		_lRet := .f.
		// fecha funcao
		Return(_lRet)
	EndIf

	// Define os campos que permite alteracao
	If (_lRet)
		// campos do browse
		aAdd(_aCampos,{"SB1","B1_COD"     ,"Código"      ,.f.})
		aAdd(_aCampos,{"SB1","B1_DESC"    ,"Descrição"   ,.f.})
		aAdd(_aCampos,{"SB1","B1_CODBAR"  ,"Cod.Barras"  ,.t.})
		aAdd(_aCampos,{"SB1","B1_PESBRU"  ,"Peso Bruto"  ,.t.})
		aAdd(_aCampos,{"SB1","B1_PESO"    ,"Peso Liq"    ,.t.})
		aAdd(_aCampos,{"SB5","B5_ALTURA"  ,"Altura"      ,.t.})
		aAdd(_aCampos,{"SB5","B5_LARG"    ,"Largura"     ,.t.})
		aAdd(_aCampos,{"SB5","B5_COMPR"   ,"Comprimento" ,.t.})
		aAdd(_aCampos,{"SB1","B1_ZCUBAGE" ,"Cubagem"     ,.f.})

		// pesquisa a existencia do produto
		dbSelectArea("SB1")
		SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
		If ! SB1->(dbSeek( xFilial("SB1")+_cTmpCodProd ))
			U_FtWmsMsg("Produto não encontrado!","ATENCAO")
			_lRet := .f.
		EndIf

		// valida os dados SB5
		If (_lRet)
			dbSelectArea("SB5")
			SB5->(dbSetOrder(1)) // filial+codpro
			// caso não encontrou vai criar para depois só atualizar
			If ! SB5->(dbSeek( xFilial("SB5")+_cTmpCodProd ))
				// grava registro
				Reclock("SB5",.t.)
				SB5->B5_COD  := _cTmpCodProd // codpro
				SB5->B5_CEME := SB1->B1_DESC // descrição
				MsUnlock()
			EndIf
		EndIf
	EndIf

	// seleciona e zera o arquivo de trabalho
	If (_lRet)

		// apaga os dados da tabela
		(mvAliasTRB)->(dbSelectArea(mvAliasTRB))
		(mvAliasTRB)->(__DbZap())

		// adiciona o conteudo
		For _nCmp := 1 to Len(_aCampos)

			// variavel temporaria
			_cTmpAlias := _aCampos[_nCmp][1]
			_cTmpCampo := _aCampos[_nCmp][2]

			// seleciona novamente a área pra gravar os dados
			(mvAliasTRB)->(dbSelectArea(mvAliasTRB))

			// reclock para inclusão
			(mvAliasTRB)->(RecLock(mvAliasTRB,.t.))
			(mvAliasTRB)->IT_PRODUTO := _cTmpCodProd
			(mvAliasTRB)->IT_TABELA  := _cTmpAlias
			(mvAliasTRB)->IT_CAMPO   := _cTmpCampo
			(mvAliasTRB)->IT_EDITA   := If(_aCampos[_nCmp][4],"S","N")
			(mvAliasTRB)->IT_TIPO    := Posicione("SX3",2,_cTmpCampo,"X3_TIPO")
			(mvAliasTRB)->IT_TITULO  := _aCampos[_nCmp][3]

			// adaptação dos campos para as tabelas B1 e B5
			If ((mvAliasTRB)->IT_TABELA == "SB1").Or.((mvAliasTRB)->IT_TABELA == "SB5")
				// tipo numerico
				If ((mvAliasTRB)->IT_TIPO == "N")
					(mvAliasTRB)->IT_DESCRI := Str( (_cTmpAlias)->(&(_cTmpCampo)) , TamSx3(_cTmpCampo)[1], TamSx3(_cTmpCampo)[2])
					// data
				ElseIf ((mvAliasTRB)->IT_TIPO == "D")
					(mvAliasTRB)->IT_DESCRI := DtoC( (_cTmpAlias)->(&(_cTmpCampo)) )
					// demais
				Else
					(mvAliasTRB)->IT_DESCRI := (_cTmpAlias)->(&(_cTmpCampo))
				EndIf
			EndIf
			// finaliza a operação
			(mvAliasTRB)->(MsUnLock())

		Next _nCmp
	EndIf

	// restaura area iniacial SX3
	RestArea(_aAreaSX3)

	(mvAliasTRB)->(dbSelectArea(mvAliasTRB))
	(mvAliasTRB)->(dbGoTop())

	// refresh do browse
	mvObjBrowse:oBrowse:Refresh()

Return(_lRet)

//** funcao para editar o campo
Static Function sfEdita(mvAliasTRB)
	// objetos da tela
	local _oWndCfgEdit
	local _oPnlCfgEdtCab
	local _oBmpCfgEdtOk, _oBmpCfgEdtSair
	local _oSayCfgTit, _oGetCfgCampo
	// campos
	local _cDscCampo := (mvAliasTRB)->IT_TITULO
	local _cTmpConteudo
	local _cTmpCampo := (mvAliasTRB)->IT_CAMPO
	// controle de confirmacao
	local _lOk := .f.
	// mascara do campo
	local _cMskCampo := X3Picture((mvAliasTRB)->IT_CAMPO)

	// controle de edicao
	If ((mvAliasTRB)->IT_EDITA != "S")
		U_FtWmsMsg("Campo não disponível para edição.","ATENCAO")
		Return(.f.)
	EndIf

	// controle do tipo de campo
	If ((mvAliasTRB)->IT_TIPO == "N")
		_cTmpConteudo := Val(AllTrim((mvAliasTRB)->IT_DESCRI))
	ElseIf ((mvAliasTRB)->IT_TIPO == "D")
		_cTmpConteudo := CtoD(AllTrim((mvAliasTRB)->IT_DESCRI))
	ElseIf ((mvAliasTRB)->IT_TIPO == "C")
		_cTmpConteudo := PadR(AllTrim((mvAliasTRB)->IT_DESCRI),TamSx3((mvAliasTRB)->IT_CAMPO)[1])
	EndIf

	// definicao da tela de consultas
	_oWndCfgEdit := MSDialog():New(020,020,120,226,"WMS - Editar",,,.F.,,,,,,.T.,,,.T. )

	// -- painel com as opcoes disponiveis
	_oPnlCfgEdtCab := TPanel():New(000,000,nil,_oWndCfgEdit,,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlCfgEdtCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMA A ALTERACAO
	_oBmpCfgEdtOk := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| IIF( sfVldCampo(_cTmpConteudo, @_lOk, (mvAliasTRB)->IT_TIPO), _oWndCfgEdit:End(),"") },_oPnlCfgEdtCab,"Ok",,.T. )
	_oBmpCfgEdtOk:Align := CONTROL_ALIGN_LEFT

	// -- BOTAO PARA FECHAR A TELA
	_oBmpCfgEdtSair := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| _oWndCfgEdit:End() },_oPnlCfgEdtCab,"Sair",,.T. )
	_oBmpCfgEdtSair:Align := CONTROL_ALIGN_RIGHT

	// controle por palete
	_oSayCfgTit   := TSay():New(030,003,{|| _cDscCampo },_oWndCfgEdit,,,.F.,.F.,.F.,.T.)
	_oGetCfgCampo := TGet():New(037,003,{|u| If(PCount()>0,_cTmpConteudo:=u,_cTmpConteudo)},_oWndCfgEdit,100,010,_cMskCampo,{|| .T. },,,_oFnt02,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cTmpConteudo",,)
	// ativa a tela
	ACTIVATE MSDIALOG _oWndCfgEdit

	If (_lOk)

		// gravando dados no trb
		(mvAliasTRB)->(dbSelectArea(mvAliasTRB))
		(mvAliasTRB)->(RecLock(mvAliasTRB))
		If ((mvAliasTRB)->IT_TIPO == "N")
			(mvAliasTRB)->IT_DESCRI := Str( _cTmpConteudo , TamSx3(_cTmpCampo)[1], TamSx3(_cTmpCampo)[2])
		ElseIf ((mvAliasTRB)->IT_TIPO == "D")
			(mvAliasTRB)->IT_DESCRI := DtoC( _cTmpConteudo )
		Else
			(mvAliasTRB)->IT_DESCRI := _cTmpConteudo
		EndIf
		(mvAliasTRB)->(MsUnLock())

	EndIf

Return

// ** funcao para validar o conteudo digitado
Static Function sfVldCampo(mvQuant, mvOK, mvTpCampo)
	// valido se o campo é maior que zero
	If ((mvTpCampo $ "C/D").and.(Empty(mvQuant))).or.((mvTpCampo == "N").and.(mvQuant <= 0))
		U_FtWmsMsg("Favor preencher corretamente o campo.","Atenção")
		mvOK := .f.
	Else
		mvOk := .t.
	EndIf
Return(mvOK)

// ** funcao que define o tipo de etiqueta de pesquisa
Static Function sfTipoEtq()
	// variavel de retorno
	local _cRetTpEtq := ""

	// objetos da tela
	local _oDlgSelEtq
	local _oCBxTpEtiq
	local _oBtnEtqOk, _oBtnEtqCan

	// tela para selecionar o tipo da etiqueta
	_oDlgSelEtq := MSDialog():New(000,000,080,200,"Tipos de Etiquetas",,,.F.,,,,,,.T.,,,.T. )
	_oCBxTpEtiq := TComboBox():New( 004,004,{|u| If(PCount()>0,_cRetTpEtq:=u,_cRetTpEtq)},{"01=Cod.Tecadi","02-Etq.Interna","03-Ean13","04-DUN14"},092,010,_oDlgSelEtq,,,,,,.T.,,"",,,,,,,"_cTipoEtiq" )
	_oBtnEtqOk  := SButton():New( 018,040,1,{ || _oDlgSelEtq:End() },_oDlgSelEtq,,"", )
	_oBtnEtqCan := SButton():New( 018,068,2,{ || _cRetTpEtq := "SAIR", _oDlgSelEtq:End() },_oDlgSelEtq,,"", )
	// ativa a tela
	_oDlgSelEtq:Activate(,,,.T.)

	// valida retorno
	If (SubS(_cRetTpEtq,1,2)) == "01" // cod interno - B1_COD
		_cRetTpEtq := "B1_COD"
	ElseIf (SubS(_cRetTpEtq,1,2)) == "02" // etq interno
		_cRetTpEtq := "INTERNA"
	ElseIf (SubS(_cRetTpEtq,1,2)) == "03" // ean13
		_cRetTpEtq := "EAN"
	ElseIf (SubS(_cRetTpEtq,1,2)) == "04" // DUN14
		_cRetTpEtq := "DUN14"
	EndIf

Return(_cRetTpEtq)

