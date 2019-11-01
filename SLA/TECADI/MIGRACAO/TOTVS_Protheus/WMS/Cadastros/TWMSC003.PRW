#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Cadastro de Recursos Humanos/Regras do WMS              !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 08/2014 !
+------------------+--------------------------------------------------------*/

User Function TWMSC003

	// variaveis temporarias
	local _nCat

	// controle de acesso a rotina
	local _lAcesso := .f.

	// retorna os grupos do usuario logado
	local _aGrupos := FWSFUsrGrps(__cUserId)

	// categorias
	private _aFilCateg  := {{"A", "Account"}, {"S", "Supervisor"}, {"L", "Lider"}, {"O", "Operador"}}
	private _cFilCateg  := ""
	// categorias
	private _aCatRecHum := {}

	// titulo
	Private cCadastro := "Cadastro de Recursos Humanos/Regras do WMS"

	// opcoes disponiveis
	Private aRotina := MenuDef()

	// funcao que monta os dados do operador logado no sistema
	Private _aUsrInfo := U_FtWmsOpe()

	// codigo do operador
	Private _lUsrAccou := (_aUsrInfo[2] == "A")
	Private _lUsrColet := (_aUsrInfo[2] == "C")
	Private _lUsrSuper := (_aUsrInfo[2] == "S")
	Private _lUsrLider := (_aUsrInfo[2] == "L")
	Private _lUsrGeren := (_aUsrInfo[2] == "G")
	Private _lUsrMonit := (_aUsrInfo[2] == "M")

	// verifica o grupo do usuario logado
	If (aScan(_aGrupos, "000000") != 0) .or. (_lUsrGeren)
		// inclui demais categorias
		aAdd(_aFilCateg,{"G", "Gerente"})
		// define que o usuario tem acesso
		_lAcesso := .t.
	EndIf

	// valida o grupo ou categoria do usuario no WMS
	// somente GERENTE ou ADMIN pode usar
	// Definicao Daniel em 26/10 por erros em cadastros por parte de Supervisores e Accounts
	If ( ! _lAcesso )
		// mensagem
		MsgAlert("Usuário sem permissão de acesso à rotina de cadastro de Recursos WMS", "Perfil Cadastro")
		// retorno
		Return(.f.)
	EndIf

	// formata filtro conforme categorias
	For _nCat := 1 to Len(_aFilCateg)
		// inclui categoria
		_cFilCateg += _aFilCateg[_nCat][1] + IIf(_nCat == Len(_aFilCateg), "", "|")
		// inclui categoria, para usar o campo ComboBox
		aAdd(_aCatRecHum, _aFilCateg[_nCat][1] + "=" + _aFilCateg[_nCat][2])
	Next _nCat

	// formata filtro para uso em IN
	_cFilCateg := FormatIn(_cFilCateg,"|")

	// abertura do mBrowse
	dbSelectArea("DCD")
	DCD->(dbSetOrder(1))
	mBrowse(06, 01, 22, 75, "DCD",,,,,,,,,,,,,, "DCD_ZCATEG IN " + _cFilCateg)

Return

// ** funcao para atualizacao do registro
User Function WMSC003A(mvOpc)

	// objetos da tela
	local _oWnd01Manut
	local _oPnl01Cab, _oPnl01Func
	local _oScr01Cab
	local _oBrw01Func, _oBrw01Ativ
	local _oSayCodRecHum, _oSayCatRecHum, _oSayBlqRecHum, _oSayArmazem, _oSayFilial
	local _oGetCodRecHum, _oGetNomRecHum, _oGetFilial, _oGetMatRecHum
	local _oCmbCatRecHum, _oCmbBlqRecHum, _oCmbArmDisp
	// controle botao Ok
	local _lOk := .f.

	// permite edicao de dados
	local _lEdita := ( (mvOpc==3).or.(mvOpc==4) )

	// variaveis para o Browse de funcoes
	Local _aColsFunc := {}
	Local _aHeadFunc := {}

	// variaveis para o Browse de Atividades
	Local _aColsAtiv := {}
	Local _aHeadAtiv := {}

	// dimensoes da tela
	local _oSizeDlg

	// variaveis
	private _cCodRecHum := CriaVar("DCD_CODFUN",.f.)
	private _cNomRecHum := CriaVar("DCD_NOMFUN",.f.)
	private _cBlqRecHum := CriaVar("DCD_MSBLQL",.t.)
	private _cCatRecHum := CriaVar("DCD_ZCATEG",.f.)
	private _aArmazDisp := U_SqlToVet("SELECT Z12_CODIGO+'='+Z12_DESCRI IT_ARMAZEM FROM " + RetSqlTab("Z12") + " WHERE " + RetSqlCond("Z12") + " AND Z12_CODIGO <> '99' ORDER BY Z12_CODIGO")
	private _cCodArmaz  := _aArmazDisp[1]
	private _cFilDispo  := CriaVar("DCD_ZFLDIS",.f.)
	private _cMatRecHum := CriaVar("DCD_ZMATRI",.f.)

	// atualiza dados
	If (mvOpc == 2).or.((_lEdita).and.(mvOpc != 3)).or.(mvOpc == 5)
		_cCodRecHum := DCD->DCD_CODFUN
		_cNomRecHum := Upper(DCD->DCD_NOMFUN)
		_cBlqRecHum := IIf(DCD->DCD_MSBLQL=="1", "1", "2")
		_cCatRecHum := DCD->DCD_ZCATEG
		_cMatRecHum := DCD->DCD_ZMATRI
		_cFilDispo  := DCD->DCD_ZFLDIS

		// tentativa de atualizacao da matricula
		If (Empty(_cMatRecHum))
			// pesquisa a filial e matricula do funcionario
			_cMatRecHum := U_FtRetMat(_cCodRecHum)[2]
		EndIf

	EndIf

	// se for exclusao, valida se o registro esta em uso para historico
	If (mvOpc == 5).and.( ! sfVldExclusao() )
		Return(.f.)
	EndIf

	// busca as funcoes/cargos disponiveis
	sfGetFuncoes(@_aHeadFunc, @_aColsFunc)

	// busca os servicos e regras disponiveis
	sfGetAtividades(@_aHeadAtiv, @_aColsAtiv)

	// faz calculo da proporcao dos objetos distribuidos na tela
	_oSizeDlg := FwDefSize():New()
	_oSizeDlg:AddObject("CABEC_01" ,  100, 30, .T., .T. )
	_oSizeDlg:AddObject("BROWSE_01",  100, 40, .T., .T. )
	_oSizeDlg:AddObject("BROWSE_02",  100, 40, .T., .T. )

	// define como Proporcional
	_oSizeDlg:lProp := .T.
	_oSizeDlg:aMargins := {3, 3, 3, 3} // Espaco ao lado dos objetos 0, entre eles 3

	// Dispara os calculos
	_oSizeDlg:Process()

	// monta o dialogo da manutecao do cadastro
	DEFINE MSDIALOG _oWnd01Manut TITLE cCadastro FROM _oSizeDlg:aWindSize[1],_oSizeDlg:aWindSize[2] TO _oSizeDlg:aWindSize[3],_oSizeDlg:aWindSize[4] OF oMainWnd PIXEL

	// panel - dados do usuario
	_oPnl01Cab := TPanel():New(_oSizeDlg:GetDimension("CABEC_01","LININI"),_oSizeDlg:GetDimension("CABEC_01","COLINI"),nil,_oWnd01Manut,,.F.,.F.,,,_oSizeDlg:GetDimension("CABEC_01","XSIZE"),_oSizeDlg:GetDimension("CABEC_01","YSIZE"),.T.,.F. )

	// scroll principal com todos as campos disponiveis
	_oScr01Cab := TScrollBox():New(_oPnl01Cab,_oSizeDlg:GetDimension("CABEC_01","LININI"),_oSizeDlg:GetDimension("CABEC_01","COLINI"),_oSizeDlg:GetDimension("CABEC_01","XSIZE"),_oSizeDlg:GetDimension("CABEC_01","YSIZE"),.T.,.T.,.T.)
	_oScr01Cab:Align := CONTROL_ALIGN_ALLCLIENT

	// codigo e descricao do usuario
	_oSayCodRecHum := TSay():New(006,012,{||"Usuário"},_oScr01Cab,,,.F.,.F.,.F.,.T.)
	_oGetCodRecHum := TGet():New(004,070,{|u| If(PCount()>0,_cCodRecHum:=u,_cCodRecHum)},_oScr01Cab,040,010,"@R 999999",{|| ExistChav("DCD",_cCodRecHum,1).and.sfVldCodRecHum() },,,,,,.T.,"",,{|| (mvOpc == 3) },.F.,.F.,,.F.,.F.,"US2","_cCodRecHum",,)
	_oGetNomRecHum := TGet():New(004,115,{|u| If(PCount()>0,_cNomRecHum:=u,_cNomRecHum)},_oScr01Cab,130,010,,,,,,,,.T.,"",,{|| .F. },.F.,.F.,,.F.,.F.,"","_cNomRecHum",,)
	_oGetMatRecHum := TGet():New(004,250,{|u| If(PCount()>0,_cMatRecHum:=u,_cMatRecHum)},_oScr01Cab,040,010,"@R 999999",,,,,,,.T.,"",,{|| .F. },.F.,.F.,,.F.,.F.,"","_cMatRecHum",,)

	// categoria
	_oSayCatRecHum := TSay():New(021,012,{||"Categoria"},_oScr01Cab,,,.F.,.F.,.F.,.T.)
	_oCmbCatRecHum := TComboBox():New(019,070,{|u| If(PCount()>0,_cCatRecHum:=u,_cCatRecHum)},_aCatRecHum,060,010,_oScr01Cab,,,,,,.T.,,"",,{|| _lEdita },,,,,_cCatRecHum)

	// bloqueado
	_oSayBlqRecHum := TSay():New(036,012,{||"Bloqueado"},_oScr01Cab,,,.F.,.F.,.F.,.T.)
	_oCmbBlqRecHum := TComboBox():New(034,070,{|u| If(PCount()>0,_cBlqRecHum:=u,_cBlqRecHum)},{"1=Sim","2=Não"},060,010,_oScr01Cab,,,,,,.T.,,"",,{|| _lEdita },,,,,_cBlqRecHum)

	// armazem
	_oSayArmazem   := TSay():New(051,012,{||"Armazém"},_oScr01Cab,,,.F.,.F.,.F.,.T.)
	_oCmbArmDisp   := TComboBox():New(049,070,{|u| If(PCount()>0,_cCodArmaz:=u,_cCodArmaz)},_aArmazDisp,100,010,_oScr01Cab,,,,,,.T.,,"",,{|| _lEdita },,,,,_cCodArmaz)
	_oCmbArmDisp:bChange := {|| sfGetAtividades(@_aHeadAtiv, @_aColsAtiv), _oBrw01Ativ:aCols := aClone(_aColsAtiv), _oBrw01Ativ:Refresh() }

	// filial
	_oSayFilial   := TSay():New(066,012,{||"Filial(is)"},_oScr01Cab,,,.F.,.F.,.F.,.T.)
	_oGetFilial   := TGet():New(064,070,{|u| If(PCount()>0,_cFilDispo:=u,_cFilDispo)},_oScr01Cab,130,010,"@!",{|| .T. },,,,,,.T.,"",,{|| _lEdita },.F.,.F.,,.F.,.F.,"","_cFilDispo",,)

	// panel - funcoes
	_oPnl01Func := TPanel():New(_oSizeDlg:GetDimension("BROWSE_01","LININI"),_oSizeDlg:GetDimension("BROWSE_01","COLINI"),nil,_oWnd01Manut,,.F.,.F.,,,_oSizeDlg:GetDimension("BROWSE_01","XSIZE"),_oSizeDlg:GetDimension("BROWSE_01","YSIZE"),.T.,.F. )

	// browse com a listagem das funcoes disponiveis
	_oBrw01Func := MsNewGetDados():New(000,000,1000,1000,IIf(_lEdita,GD_UPDATE,Nil),'AllwaysTrue()','AllwaysTrue()','',{"FUNC_OK"},0,,'AllwaysTrue()','','AllwaysTrue()',_oPnl01Func,_aHeadFunc,_aColsFunc)
	_oBrw01Func:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrw01Func:oBrowse:SetBlkBackColor( {|| IIf(_oBrw01Func:aCols[_oBrw01Func:nAt,1]=='S',CLR_HGREEN,CLR_WHITE) } )

	// browse com as regras e filtros por atividade
	_oBrw01Ativ := MsNewGetDados():New(_oSizeDlg:GetDimension("BROWSE_02","LININI"),_oSizeDlg:GetDimension("BROWSE_02","COLINI"),_oSizeDlg:GetDimension("BROWSE_02","LINEND"),_oSizeDlg:GetDimension("BROWSE_02","COLEND"),If(_lEdita,GD_UPDATE,Nil),'AllwaysTrue()','AllwaysTrue()','',{"ATV_OK","ATV_ENDINI","ATV_ENDFIM"},0,,'AllwaysTrue()','','AllwaysTrue()',_oWnd01Manut,_aHeadAtiv,_aColsAtiv)
	_oBrw01Ativ:oBrowse:SetBlkBackColor( {|| IIf(_oBrw01Ativ:aCols[_oBrw01Ativ:nAt,1]=='S',CLR_HGREEN,CLR_WHITE) } )

	// ativa a tela
	ACTIVATE MSDIALOG _oWnd01Manut CENTERED ON INIT EnchoiceBar(_oWnd01Manut, {|| _lOk := sfGrvDados(mvOpc, _oBrw01Func, _oBrw01Ativ, @_oWnd01Manut) }, {|| _oWnd01Manut:End() }, .f., {}, Nil, Nil, .F., .F., .F., .T., .F., 'ID_TELA01',)

Return

// ** funcao que carrega as funcoes/cargos
Static Function sfGetFuncoes(mvHeadFunc, mvColsFunc)

	// query
	local _cQuery

	//                Titulo    Campo        Masc  Tam                   Dec Vld Usd Tipo  f3 contexto Combo Box
	aAdd(mvHeadFunc, {"Ativo?", "FUNC_OK"  , "@!", 1                     , 0, "", "", "C", "",     "R","S=Sim;N=Nao"})
	aAdd(mvHeadFunc, {"Código", "FUNC_COD" , "@!", TamSx3("RJ_FUNCAO")[1], 0, "", "", "C", "",     "R",""           })
	aAdd(mvHeadFunc, {"Função", "FUNC_DESC", "@!", TamSx3("RJ_DESC")[1]  , 0, "", "", "C", "",     "R",""           })

	// atualiza as funcoes disponiveis
	_cQuery := "SELECT "
	// item ja relacionado
	_cQuery += " CASE WHEN DCI_CODFUN IS NULL THEN 'N' ELSE 'S' END FUNC_OK, "
	_cQuery += " RJ_FUNCAO FUNC_COD, "
	_cQuery += " RJ_DESC FUNC_DESC, "
	// controle de linha ativa
	_cQuery += " '.F.' IT_DEL "
	// cad. funcoes
	_cQuery += "FROM "+RetSqlName("SRJ")+" SRJ "
	// funcoes por usuario
	_cQuery += "LEFT JOIN "+RetSqlName("DCI")+" DCI ON "+RetSqlCond("DCI")+" AND DCI_FUNCAO = RJ_FUNCAO AND DCI_CODFUN = '"+_cCodRecHum+"' "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SRJ")
	// filtra codigo da funcao
	_cQuery += "AND ( "
	_cQuery += "      (RJ_FUNCAO LIKE 'WMS%')
	_cQuery += "       OR "
	_cQuery += "      (RJ_FUNCAO IN (SELECT DCI_FUNCAO FROM "+RetSqlName("DCI")+" DCI WHERE "+RetSqlCond("DCI")+" AND DCI_CODFUN = '"+_cCodRecHum+"')) "
	_cQuery += "    ) "
	// ordem dos dados
	_cQuery += "ORDER BY RJ_DESC"

	// atualiza itens
	mvColsFunc := U_SqlToVet(_cQuery)

Return

// ** funcao que carrega as regras/servicos/atividades
Static Function sfGetAtividades(mvHeadAtiv, mvColsAtiv)

	// query
	local _cQuery

	//                Titulo    Campo        Masc  Tam                   Dec Vld Usd Tipo  f3 contexto Combo Box
	aAdd(mvHeadAtiv, {"Ativo?"     , "ATV_OK"     , "@!", 1                      , 0, "", "", "C", "",     "R","S=Sim;N=Nao"})
	aAdd(mvHeadAtiv, {"Cod.Serv."  , "ATV_CODSRV" , "@!", TamSx3("DC5_SERVIC")[1], 0, "", "", "C", "",     "R",""           })
	aAdd(mvHeadAtiv, {"Dsc.Serviço", "ATV_DSCSRV" , "@!", 30                     , 0, "", "", "C", "",     "R",""           })
	aAdd(mvHeadAtiv, {"Cod.Tarefa" , "ATV_CODTRF" , "@!", TamSx3("DC5_TAREFA")[1], 0, "", "", "C", "",     "R",""           })
	aAdd(mvHeadAtiv, {"Dsc.Tarefa" , "ATV_DSCTRF" , "@!", 30                     , 0, "", "", "C", "",     "R",""           })
	aAdd(mvHeadAtiv, {"End.Inicial", "ATV_ENDINI" , "@!", TamSx3("DCQ_ENDINI")[1], 0, "", "", "C", "",     "R",""           })
	aAdd(mvHeadAtiv, {"End.Final"  , "ATV_ENDFIM" , "@!", TamSx3("DCQ_ENDFIM")[1], 0, "", "", "C", "",     "R",""           })
	aAdd(mvHeadAtiv, {"Cód.Função" , "ATV_FUNCAO" , "@!", TamSx3("DC6_FUNCAO")[1], 0, "", "", "C", "",     "R",""           })

	// atualiza as atividades disponiveis
	_cQuery := "SELECT "
	// item ja relacionado
	_cQuery += " CASE WHEN DCQ_SERVIC IS NULL THEN 'N' ELSE 'S' END ATV_OK, "
	// servico
	_cQuery += " DC5_SERVIC ATV_CODSRV, "
	_cQuery += " UPPER(SX5SRV.X5_DESCRI) ATV_DSCSRV, "
	// tarefa
	_cQuery += " DC5_TAREFA ATV_CODTRF, "
	_cQuery += " UPPER(SX5TRF.X5_DESCRI) ATV_DSCTRF, "
	// filtro de endereco
	_cQuery += " ISNULL(DCQ_ENDINI,'') ATV_ENDINI, "
	_cQuery += " ISNULL(DCQ_ENDFIM,'') ATV_ENDFIM, "
	// cod funcao
	_cQuery += " DC6_FUNCAO, "
	// controle de linha ativa
	_cQuery += " '.F.' IT_DEL "

	// configuracao de servico
	_cQuery += "FROM "+RetSqlName("DC5")+" DC5 "
	// cadastro de servico
	_cQuery += "INNER JOIN "+RetSqlName("SX5")+" SX5SRV "
	_cQuery += "   ON SX5SRV.X5_FILIAL = '"+xFilial("SX5")+"' AND SX5SRV.D_E_L_E_T_ = ' ' "
	_cQuery += "  AND SX5SRV.X5_TABELA = 'L4' AND SX5SRV.X5_CHAVE = DC5_SERVIC "
	// cadastro de tarefa
	_cQuery += "INNER JOIN "+RetSqlName("SX5")+" SX5TRF "
	_cQuery += "   ON SX5TRF.X5_FILIAL = '"+xFilial("SX5")+"' AND SX5TRF.D_E_L_E_T_ = ' ' "
	_cQuery += "  AND SX5TRF.X5_TABELA = 'L2' AND SX5TRF.X5_CHAVE = DC5_TAREFA "
	// cadastro de tarefa
	_cQuery += "INNER JOIN "+RetSqlName("DC6")+" DC6 "
	_cQuery += "   ON "+RetSqlCond("DC6")+" AND DC6_TAREFA = DC5_TAREFA "
	// regras por usuario/operador
	_cQuery += "LEFT  JOIN "+RetSqlName("DCQ")+" DCQ "
	_cQuery += "   ON "+RetSqlCond("DCQ")+" AND DCQ_CODFUN = '"+_cCodRecHum+"' "
	_cQuery += "  AND DCQ_SERVIC = DC5_SERVIC "
	_cQuery += "  AND DCQ_TAREFA = DC6_TAREFA "
	// armazem
	_cQuery += "  AND DCQ_LOCAL  = '"+Left(_cCodArmaz,TamSx3("BE_LOCAL")[1])+"' "

	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("DC5")
	// ordem dos dados
	_cQuery += "ORDER BY DC5_SERVIC, DC5_ORDEM, DC6_ORDEM "

	// atualiza itens
	mvColsAtiv := U_SqlToVet(_cQuery)

Return

// ** funcao que valida o codigo do recurso humano informado
Static Function sfVldCodRecHum()
	// area atual
	Local _aAreaAnt := GetArea()
	// validacao
	local _lRet := .t.
	// dados do funcionario
	local _aDadosFunc := {"",""}

	// atualiza variavel de retorno
	_cNomRecHum := Upper(UsrFullName(_cCodRecHum))

	// valida retorno
	If (Empty(_cNomRecHum))
		MsgStop("Código não encontrado!")
		_lRet := .f.
	EndIf

	// pesquisa a filial e matricula do funcionario
	_aDadosFunc := U_FtRetMat(_cCodRecHum)

	// atualiza filial
	_cFilDispo := PadR(_aDadosFunc[1],Len(_cFilDispo))

	// atualiza matricula
	_cMatRecHum := _aDadosFunc[2]

	// restaura area atual
	RestArea(_aAreaAnt)

Return(_lRet)

// ** funcao para gravar os dados
Static Function sfGrvDados(mvOpc, mvBrwFuncoes, mvBrwAtivid, mvWnd01Manut)

	// variaveis temporarias
	local _nItFunc
	local _aTmpFunc := aClone(mvBrwFuncoes:aCols)
	local _nItAtiv
	local _aTmpAtiv  := aClone(mvBrwAtivid:aCols)
	local _cTmpArmaz := Left(_cCodArmaz,TamSx3("BE_LOCAL")[1])
	// codigo da zona
	local _cTmpCodZon := CriaVar("DCQ_CODZON",.f.)

	// ordem da funcao
	local _nOrdFunc := 1

	If (Empty(_cCodRecHum)).or.(Empty(_cNomRecHum))
		MsgStop("Código e nome do usuário são obrigatórios!")
		Return(.f.)
	EndIf

	// inicia transacao
	BEGIN TRANSACTION

		// seleciona tabela
		dbSelectArea("DCD")
		RecLock("DCD",(mvOpc==3))
		// se for inclusao
		If (mvOpc==3)
			DCD->DCD_FILIAL := xFilial("DCD")
			DCD->DCD_CODFUN := _cCodRecHum
			DCD->DCD_NOMFUN := _cNomRecHum
			DCD->DCD_STATUS := "1"      // status - inserido dia 23/06/15 @david
		EndIf

		// atualiza demais campos
		If (mvOpc==3).or.(mvOpc==4)
			DCD->DCD_MSBLQL := _cBlqRecHum
			DCD->DCD_ZCATEG := _cCatRecHum
			DCD->DCD_ZFLDIS := _cFilDispo
		EndIf

		// exclusao
		If (mvOpc==5)
			DCD->(dbDelete())
		EndIf

		// confirma
		DCD->(MsUnLock())

		// valida as funcoes
		For _nItFunc := 1 to Len(_aTmpFunc)

			// verifica a funcao esta relacionado ao usuario
			dbSelectArea("DCI")
			DCI->(dbSetOrder(2)) // 2-DCI_FILIAL, DCI_CODFUN, DCI_FUNCAO, DCI_ORDFUN
			DCI->(dbSeek( xFilial("DCI")+_cCodRecHum+_aTmpFunc[_nItFunc][2] ))

			// inclusao
			If (DCI->(Eof())).and.(_aTmpFunc[_nItFunc][1]=="S").and.((mvOpc==3).or.(mvOpc==4))
				RecLock("DCI",.t.)
				DCI->DCI_FILIAL := xFilial("DCI")
				DCI->DCI_CODFUN := _cCodRecHum
				DCI->DCI_ORDFUN := _nOrdFunc
				DCI->DCI_FUNCAO := _aTmpFunc[_nItFunc][2]
				DCI->(MsUnLock())

				// alteracao/exclusao
			ElseIf (DCI->(Found())).and.((mvOpc==4).or.(mvOpc==5))

				// alteracao
				If (mvOpc==4).and.(_aTmpFunc[_nItFunc][1]=="S")
					RecLock("DCI")
					DCI->DCI_ORDFUN := _nOrdFunc
					DCI->(MsUnLock())

					// proxima ordem
					_nOrdFunc ++

					// exclusao
				ElseIf (mvOpc==5).or.((mvOpc==4).and.(_aTmpFunc[_nItFunc][1]=="N"))
					RecLock("DCI")
					DCI->(dbDelete())
					DCI->(MsUnLock())

				EndIf
			EndIf

			// proxima funcao
		Next _nItFunc

		// valida as atividades/regras
		For _nItAtiv := 1 to Len(_aTmpAtiv)

			// verifica se a atividade esta relacionado ao usuario
			dbSelectArea("DCQ")
			DCQ->(dbSetOrder(1)) // 1-DCQ_FILIAL, DCQ_TPREGR, DCQ_STATUS, DCQ_LOCAL, DCQ_CODFUN, DCQ_CODZON, DCQ_SERVIC, DCQ_TAREFA, DCQ_ATIVID
			DCQ->(dbSeek( xFilial("DCI")+"1"+"1"+_cTmpArmaz+_cCodRecHum+_cTmpCodZon+_aTmpAtiv[_nItAtiv][2]+_aTmpAtiv[_nItAtiv][4] ))

			// inclusao
			If (DCQ->(Eof())).and.(_aTmpAtiv[_nItAtiv][1]=="S").and.((mvOpc==3).or.(mvOpc==4))
				RecLock("DCQ",.t.)
				DCQ->DCQ_FILIAL := xFilial("DCQ")
				DCQ->DCQ_TPREGR := "1"
				DCQ->DCQ_STATUS := "1"
				DCQ->DCQ_LOCAL  := _cTmpArmaz
				DCQ->DCQ_CODFUN := _cCodRecHum
				DCQ->DCQ_CODZON := _cTmpCodZon
				DCQ->DCQ_SERVIC := _aTmpAtiv[_nItAtiv][2]
				DCQ->DCQ_TAREFA := _aTmpAtiv[_nItAtiv][4]
				DCQ->DCQ_ENDINI := _aTmpAtiv[_nItAtiv][6]
				DCQ->DCQ_ENDFIM := _aTmpAtiv[_nItAtiv][7]
				DCQ->DCQ_RESEND := "2"
				DCQ->DCQ_LIBEND := "1"
				DCQ->DCQ_ORDEM  := "1"
				DCQ->DCQ_DOCEXC := "2"
				DCQ->DCQ_PRIORI := "01"
				DCQ->(MsUnLock())

				// alteracao/exclusao
			ElseIf (DCQ->(Found())).and.((mvOpc==4).or.(mvOpc==5))

				// alteracao
				If (mvOpc==4).and.(_aTmpAtiv[_nItAtiv][1]=="S")
					RecLock("DCQ")
					DCQ->DCQ_ENDINI := _aTmpAtiv[_nItAtiv][6]
					DCQ->DCQ_ENDFIM := _aTmpAtiv[_nItAtiv][7]
					DCQ->(MsUnLock())

					// exclusao
				ElseIf (mvOpc==5).or.((mvOpc==4).and.(_aTmpAtiv[_nItAtiv][1]=="N"))
					RecLock("DCQ")
					DCQ->(dbDelete())
					DCQ->(MsUnLock())

				EndIf
			EndIf

			// proxima atividade
		Next _nItAtiv

		// finaliza transacao
	END TRANSACTION

	// fecha tela
	mvWnd01Manut:End()

Return

// ** funcao para definir o menu
Static Function MenuDef()
	// variavel de retorno
	local _aRetMenu := {;
	{OemToAnsi("Pesquisar")	, "axPesqui"     , 0, 1},;
	{OemToAnsi("Visualizar"), 'U_WMSC003A(2)', 0, 2},;
	{OemToAnsi("Incluir")	, 'U_WMSC003A(3)', 0, 3},;
	{OemToAnsi("Alterar")	, 'U_WMSC003A(4)', 0, 4},;
	{OemToAnsi("Excluir")	, 'U_WMSC003A(5)', 0, 5} }
Return(_aRetMenu)

// ** funcao que valida se o registro esta em uso para historico
Static Function sfVldExclusao()
	// variavel de retorno
	local _lRet := .t.
	// query
	local _cQuery

	If (_lRet)
		// usuario x OS
		_cQuery := " SELECT COUNT(*) QTD_REG "
		_cQuery += " FROM   "+RetSqlTab("Z18")
		_cQuery += " WHERE  D_E_L_E_T_ = ' ' "
		_cQuery += "        AND ( Z18_OPERAD = '"+_cCodRecHum+"' OR Z18_USUARI = '"+_cCodRecHum+"' ) "
		// valida query
		_lRet := (U_FtQuery(_cQuery) == 0)
		// mensagem
		If ( ! _lRet )
			MsgAlert("Usuário não poderá ser excluído pois está relacionado à ordens de serviço.", "Usuário x OS")
		EndIf
	EndIf

	If (_lRet)
		// conferencias
		_cQuery := " SELECT COUNT(*) QTD_REG "
		_cQuery += " FROM   "+RetSqlTab("Z07")
		_cQuery += " WHERE  D_E_L_E_T_ = ' ' "
		_cQuery += "        AND Z07_USUARI = '"+_cCodRecHum+"' "
		// valida query
		_lRet := (U_FtQuery(_cQuery) == 0)
		// mensagem
		If ( ! _lRet )
			MsgAlert("Usuário não poderá ser excluído pois está relacionado à ordens de serviço de conferência.", "OS de Conferência")
		EndIf
	EndIf

	If (_lRet)
		// movimentacoes
		_cQuery := " SELECT COUNT(*) QTD_REG "
		_cQuery += " FROM   "+RetSqlTab("Z17")
		_cQuery += " WHERE  D_E_L_E_T_ = ' ' "
		_cQuery += "        AND Z17_OPERAD = '"+_cCodRecHum+"' "
		// valida query
		_lRet := (U_FtQuery(_cQuery) == 0)
		// mensagem
		If ( ! _lRet )
			MsgAlert("Usuário não poderá ser excluído pois está relacionado à ordens de serviço de movimentação de mercadorias.", "OS de Movimentação")
		EndIf
	EndIf

	If (_lRet)
		// inventario
		_cQuery := " SELECT COUNT(*) QTD_REG "
		_cQuery += " FROM   "+RetSqlTab("Z19")
		_cQuery += " WHERE  D_E_L_E_T_ = ' ' "
		_cQuery += "        AND Z19_USER = '"+_cCodRecHum+"' "
		// valida query
		_lRet := (U_FtQuery(_cQuery) == 0)
		// mensagem
		If ( ! _lRet )
			MsgAlert("Usuário não poderá ser excluído pois está relacionado à ordens de serviço de inventário.", "OS de Inventário")
		EndIf
	EndIf

Return(_lRet)