#Include "RwMake.Ch"
#Include "Colors.ch"
#Include "DBTree.ch"
#Include "TopConn.ch"
#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Cadastro de Gerencias x Alçadas                         !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 01/2014 !
+------------------+---------------------------------------------------------+
!Observacoes       !                                                         !
+------------------+--------------------------------------------------------*/

User Function TCOMC002()

	// objetos da tela
	local _oPnl01Cab1, _oPnl01Tree, _oPnl01Rod, _oPnl01Esq, _oPnl01Dir
	local _oSayLegenda, _oSayAnoBase
	local _oCmbAnoBase
	local _oMnuMulti

	// variaveis temporarias
	local _nLeg, _nMnu

	// opções do menu
	private _aOpcMenu := {}

	// objeto do tree view
	private _oTreeCC
	private _oTreeLegenda

	// objetos de tela
	private _oWnd01Princ

	// dimensoes da tela
	private _aSizeDlg := MsAdvSize()

	// busca os niveis disponiveis para os usuarios
	private _aNiveis := sfRetOpcoes("Z26_NIVEL",1)

	// monta vetor da legenda
	private _aLegenda := sfLegenda()

	// estrutura BASE do tree view
	Private _aEstrutura := {}

	// ANO base para filtro das informacoes
	private _aAnoBase := sfRetAnoBase()
	private _cAnoBase := Str(Year(Date()),4,0)

	// fontes utilizadas
	Private _oFnt01 := TFont():New("Tahoma",,18,,.t.)

	// apresentar perfil bloqueado
	private _lVisPrfBlq := .f.

	Private _cArqTmp
	Private _TRBITEM := GetNextAlias()

	// adiciona opções do menu
	aAdd(_aOpcMenu, {"Incluir"             , 'sfDetalhes("I",_oTreeCC:GetCargo(),"")'                  } )
	aAdd(_aOpcMenu, {"Alterar"             , 'sfDetalhes("A",_oTreeCC:GetCargo(),"")'                  } )
	aAdd(_aOpcMenu, {"Excluir"             , 'sfVldExclusao("E",_oTreeCC:GetCargo())'                  } )
	aAdd(_aOpcMenu, {"Replicar It.Contábil", 'IIf(sfRepNivInf(_oTreeCC:GetCargo()), sfAtuTree(), Nil)' } )
	aAdd(_aOpcMenu, {"Perfil Bloqueado?"   , 'IIf(sfMudaVis(), sfAtuTree(), Nil)'                      } )
	aAdd(_aOpcMenu, {"Sair"                , 'IIf(MsgYesNo("Deseja Sair?"), _oWnd01Princ:End(), Nil)'  } )

	// monta o dialogo do cadastro de alcadas
	_oWnd01Princ := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Cadastro de Gerências/Alçadas",,,.F.,,,,,,.T.,,,.T. )
	_oWnd01Princ:lMaximized := .T.

	// cria o panel do cabecalho - titulo
	_oPnl01Cab1 := TPanel():New(000,000,nil,_oWnd01Princ,,.F.,.F.,,,40,40,.T.,.F.)
	_oPnl01Cab1:Align:= CONTROL_ALIGN_TOP

	// ANO base
	_oSayAnoBase := TSay():New(002,005,{||"Ano Base"},_oPnl01Cab1,,,.F.,.F.,.F.,.T.)
	_oCmbAnoBase := TComboBox():New(008,005,{|u| If(PCount()>0,_cAnoBase:=u,_cAnoBase)},_aAnoBase,040,010,_oPnl01Cab1,,{|| sfAtuTree() },,,,.T.,,"",,,,,,,_cAnoBase)

	// menu principal
	_oMnuMulti := tMultiBtn():New(001, 080, 'Cadastro de Gerências/Alçada', _oPnl01Cab1, {|x,y| (_cExec := _aOpcMenu[y,2], &_cExec ) },200,150, 'GPEIMG32', 0, '', 3)
	_oMnuMulti:SetFonts('Tahoma',10,'Tahoma',08)
	For _nMnu := 1 to Len(_aOpcMenu)
		_oMnuMulti:AddButton(_aOpcMenu[_nMnu][1])
	Next _nMnu

	// cria o panel do rodape - botoes de operacao
	_oPnl01Rod := TPanel():New(000,000,nil,_oWnd01Princ,,.F.,.F.,,,30,30,.T.,.F.)
	_oPnl01Rod:Align:= CONTROL_ALIGN_BOTTOM

	// cria o panel da lateral esquerda - botoes de operacao
	_oPnl01Esq := TPanel():New(000,000,nil,_oWnd01Princ,,.F.,.F.,,,80,80,.T.,.F.)
	_oPnl01Esq:Align:= CONTROL_ALIGN_LEFT

	// cria o panel da lateral direita - botoes de operacao
	_oPnl01Dir := TPanel():New(000,000,nil,_oWnd01Princ,,.F.,.F.,,,100,100,.T.,.F.)
	_oPnl01Dir:Align:= CONTROL_ALIGN_RIGHT

	// titulo da legenda
	_oSayLegenda := TSay():New(004,010,{|| "Legenda" },_oPnl01Dir,,_oFnt01,.F.,.F.,.F.,.T.,,,180,180,,,,,,.t.)

	// monta tree view das legendas
	_oTreeLegenda := DbTree():New(015,005,120,105,_oPnl01Dir,,,.T.)

	For _nLeg := 1 to Len(_aLegenda)
		DBAddItem _oTreeLegenda Prompt _aLegenda[_nLeg,1] Resource _aLegenda[_nLeg,2] Cargo _aLegenda[_nLeg,2]
	Next _nLeg

	// monta o Objeto TreeView
	_oTreeCC := DbTree():New(000,000,_aSizeDlg[6],_aSizeDlg[5],_oWnd01Princ,,,.T.)
	_oTreeCC:Align := CONTROL_ALIGN_ALLCLIENT

	// funcao que Atualiza o Tree View
	sfAtuTree()

	// ativa a tela
	ACTIVATE MSDIALOG _oWnd01Princ CENTERED
	
	If ValType(_cArqTmp) == "O"
		_cArqTmp:Delete()
	EndIf
	
Return

// ** funcao que retorna os Centros de Custo do perfil selecionado
Static Function sfRetCC(mvCodPerfil, mvRetBrw)
	// variaveis temporaias
	local _cQuery
	// variavel de retorno
	Local _aRet := {}

	// monta query para buscar os centros de custos do perfil selecionado
	_cQuery := "SELECT "
	// se for retorno para browse
	If (mvRetBrw)
		_cQuery += "DISTINCT Z27_CC, CTT_DESC01, '.F.' IT_DEL "
	Else
		_cQuery += "DISTINCT Z27_CC, CTT_DESC01, CTT_BLOQ "
	EndIf
	// centros de custo do perfil
	_cQuery += "FROM "+RetSQLName("Z27")+" Z27 "
	// cad. de centro de custo
	_cQuery += "INNER JOIN "+RetSQLName("CTT")+" CTT ON "+RetSqlCond("CTT")+" AND CTT_CUSTO = Z27_CC "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z27")
	// filtro do perfil
	_cQuery += "AND Z27_PERFIL = '"+mvCodPerfil+"' "
	// ano base
	_cQuery += "AND Z27_CALEND = '"+_cAnoBase+"' "
	// ordem dos dados
	_cQuery += "ORDER BY Z27_CC"

	// atualiza variavel de retorno
	_aRet := U_SqlToVet(_cQuery)

Return(_aRet)

// ** funcao que monta a tela com os delahes do Setor (Inclusão, Alteração, Visualização)
Static Function sfDetalhes(mvTipoOpe, mvCodCargo, ciNivPer)

	// controle de edicao de campos
	local _lEdita    := .T.
	Local _lEdtSuper := .T.

	// centros de custo do departamento/perfil
	Local _aCC := {}

	// codigo do setor selecionado
	local _aTmpCargo := Separa(mvCodCargo,";")
	local _cTmpTipo := _aTmpCargo[1]
	local _cCodPflSelec := PadR(_aTmpCargo[2],TamSx3("Z26_PERFID")[1])

	// objetos da tela
	local _oWnd02Manut
	local _oBtnOk, _oBtnFechar, _oBtnSelCC, _oBtnDefIteC
	local _oSayBloq
	local _oCmbBloq

	// controle botao Ok
	local _lOk := .f.


	// objetos do browse
	private _aHeadCC := {}
	private _aColsCC := {}
	// objetos da tela
	private _oBrw01CC

	// variaveis
	private _cCodPerfil := CriaVar("Z26_PERFID",.f.)
	private _cDscSetor  := CriaVar("Z26_SETOR",.f.)
	private _cCodUser   := CriaVar("Z26_CODUSU",.f.)
	private _cNomeGeren := CriaVar("Z26_GERENT",.f.)
	private _cNvlPerf   := CriaVar("Z26_NIVEL",.f.)
	private _cIdSuperi  := CriaVar("Z26_PERSUP",.f.)
	private _cDscSuper  := ""

	// opcoes do campo MSBLQL
	private _cMsBloq    := CriaVar("Z26_MSBLQL",.f.)
	private _aOpcBloq   := sfRetOpcoes("Z26_MSBLQL", 1)


	// valida edicao em centros de custo
	If (_cTmpTipo == "C")
		Aviso("Centro de Custo","Não é permitido Alterar dados do Centro de Custo",{"OK"})
		Return(.f.)
	EndIf

	// inclusao
	If (mvTipoOpe == "I")

		// conteudo padrao para campo bloqueado
		_cMsBloq := "2" // 2-Nao

		// atualiza os dados do ID Superior
		If ( ! Empty(_cCodPflSelec) )
			// codigo
			_cIdSuperi := _cCodPflSelec
			// descricao
			_cDscSuper := sfRetDscSup(_cIdSuperi)
		EndIf

		// alteracao / visualizacao
	ElseIf (mvTipoOpe != "I")

		_lEdtSuper	:= .F. //nao deixa edidar o superior

		// atualiza codigo do perfil selecionado
		_cCodPerfil := _cCodPflSelec

		// posiciona no registro da tabela
		DBSelectArea("Z26")
		Z26->(dbSetOrder(1)) // 1-Z26_FILIAL, Z26_CALEND, Z26_PERFID
		If ! Z26->(dbSeek( xFilial("Z26")+_cAnoBase+_cCodPerfil ))
			MsgStop("Erro Seek SZ6 ## 1")
		EndIf

		// atualiza dados
		_cDscSetor  := Z26->Z26_SETOR
		_cCodUser   := Z26->Z26_CODUSU
		_cNomeGeren := Z26->Z26_GERENT
		_cNvlPerf   := Z26->Z26_NIVEL
		_cIdSuperi  := Z26->Z26_PERSUP
		_cDscSuper	:= If(Empty(_cIdSuperi),Space(Len(_cDscSuper)),sfRetDscSup(_cIdSuperi))
		// controle de bloqueio de perfil
		_cMsBloq    := Z26->Z26_MSBLQL

	EndIf

	// atualiza dados do Browse
	_aHeadCC := sfMntHeader(mvTipoOpe)
	_aColsCC := sfRetCC(_cCodPerfil,.t.)

	// prepara TRB com as informacoes dos itens contabeis
	MsgRun( "Organizando dados por centro de custo..." , "Aguarde..." , { || sfMntTrbItem(_aColsCC) } )

	// monta o dialogo do monitor
	_oWnd02Manut := MSDialog():New(000,000,450,653,"Manutenção de Gerência",,,.F.,,,,,,.T.,,,.T. )

	// botao ok
	_oBtnOk := TButton():New(002,210,"Confirmar",_oWnd02Manut,{|| _lOk := sfValDados(@_oWnd02Manut) },055,014,,,,.T.,,"",,,,.F. )

	// botao fechar
	_oBtnFechar := TButton():New(002,270,"Fechar",_oWnd02Manut,{|| _oWnd02Manut:End() },055,014,,,,.T.,,"",,,,.F. )

	// dados do setor
	@ 015,003 To 110,325 Title "Dados do Setor"

	// codigo e descricao do setor
	_oSayCodSet := TSay():New(025,012,{||"Código / Setor"},_oWnd02Manut,,,.F.,.F.,.F.,.T.)
	_oGetCodSet := TGet():New(023,070,{|u| If(PCount()>0,_cCodPerfil:=u,_cCodPerfil)},_oWnd02Manut,040,010,"@!",,,,,,,.T.,"",,{|| .F. },.F.,.F.,,.F.,.F.,"","_cCodPerfil",,)
	_oGetDscSet := TGet():New(023,115,{|u| If(PCount()>0,_cDscSetor:=u,_cDscSetor)},_oWnd02Manut,130,010,"@!",,,,,,,.T.,"",,{|| _lEdita },.F.,.F.,,.F.,.F.,"","_cDscSetor",,)

	// aprovador / resposavel
	_oSayIdAprov  := TSay():New(039,012,{||"Cód.Usr.Resp."},_oWnd02Manut,,,.F.,.F.,.F.,.T.)
	_oGetIdAprov  := TGet():New(037,070,{|u| If(PCount()>0,_cCodUser:=u,_cCodUser)},_oWnd02Manut,040,010,"@!",{|| Vazio().or.sfVldIdAprov() },,,,,,.T.,"",,{|| _lEdita },.F.,.F.,,.F.,.F.,"USR","_cCodUser",,)
	_oGetDscAprov := TGet():New(037,115,{|u| If(PCount()>0,_cNomeGeren:=u,_cNomeGeren)},_oWnd02Manut,130,010,"@!",,,,,,,.T.,"",,{|| _lEdita },.F.,.F.,,.F.,.F.,"","_cNomeGeren",,)

	// nivel
	_oSayNivel := TSay():New(054,012,{||"Nível"},_oWnd02Manut,,,.F.,.F.,.F.,.T.)
	_oCmbNivel := TComboBox():New(052,070,{|u| If(PCount()>0,_cNvlPerf:=u,_cNvlPerf)},_aNiveis,060,010,_oWnd02Manut,,,,,,.T.,,"",,{|| _lEdita },,,,,_cNvlPerf)

	// id superior
	_oSayIdSuper  := TSay():New(069,012,{||"ID Alçada Superior"},_oWnd02Manut,,,.F.,.F.,.F.,.T.)
	_oGetIdSuper  := TGet():New(067,070,{|u| If(PCount()>0,_cIdSuperi:=u,_cIdSuperi)},_oWnd02Manut,040,010,,{|| Vazio().or.sfVldSuper() },,,,,,.T.,"",,{|| _lEdtSuper },.F.,.F.,,.F.,.F.,"Z26","_cIdSuperi",,)
	_oGetDscSuper := TGet():New(067,115,{|u| If(PCount()>0,_cDscSuper:=u,_cDscSuper)},_oWnd02Manut,130,010,,,,,,,,.T.,"",,{|| .F. },.F.,.F.,,.F.,.F.,"","_cDscSuper",,)

	// controle de bloqueio
	_oSayBloq := TSay():New(084,012,{||"Perfil Bloqueado?"},_oWnd02Manut,,,.F.,.F.,.F.,.T.,)
	_oCmbBloq := TComboBox():New(082,070,{|u| If(PCount()>0,_cMsBloq:=u,_cMsBloq)},_aOpcBloq,060,010,_oWnd02Manut,,,,,,.T.,,"",,{|| .t. },,,,,_cMsBloq)

	// centros de custo
	@ 113,003 To 205,325 Title "Centros de Custo"

	// browse com a listagem dos centros de custos
	_oBrw01CC := MsNewGetDados():New(122,008,201,320,GD_DELETE,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsCC),'AllwaysTrue()','','U_COMC002B(_cCodUser, _oBrw01CC:aCols[_oBrw01CC:nAt][1], Nil, _cCodPerfil)',_oWnd02Manut,_aHeadCC,_aColsCC)

	// botoes de operacao
	// -- SELECIONAR CC
	_oBtnSelCC := TButton():New(209,010,"Selecionar C.C.",_oWnd02Manut,{|| sfSelCenCus(@_oBrw01CC) },055,014,,,,.T.,,"",,,,.F. )

	// -- DEFINIR ITEM CONTABIL E ALCADAS
	_oBtnDefIteC := TButton():New(209,070,"Define Item Contábil",_oWnd02Manut,{|| sfDefItemCtb(_oBrw01CC:aCols[_oBrw01CC:nAt][1]) },055,014,,,,.T.,,"",,,,.F. )

	// ativa a tela
	ACTIVATE MSDIALOG _oWnd02Manut CENTERED

	// controle de confirmacao
	If (_lOk)

		// funcao para atualizar os dados
		Processa( {|lEnd| sfAtuDados(mvTipoOpe) }, "Aguarde...","Executando rotina.", .T. )

		// Atualiza Arvore
		sfAtuTree()

	EndIf
	

Return

// ** funcao que busca a Lista de Niveis disponiveis
Static Function sfRetOpcoes(mvCampo, mvPosRet)
	// area inicial
	Local _aAreaSX3 := SX3->(GetArea())
	// variaveis temporarias
	Local _aRet := {}
	Local _nY

	// retorno em array
	// 1 -> S=Sim
	// 2 -> S
	// 3 -> Sim
	Local _aCboxX3 := RetSx3Box(Posicione('SX3',2,mvCampo,'X3CBox()'),,,TamSx3(mvCampo)[1])
	// restaura area inicial
	RestArea(_aAreaSX3)

	// prepara vetor de retorno
	For _nY := 1 to Len(_aCboxX3)
		// verifica se nao esta vazio
		If ( ! Empty(_aCboxX3[_nY][mvPosRet]))
			// adiciona opcao
			aAdd(_aRet,_aCboxX3[_nY][mvPosRet])
		EndIf
	Next _nY

Return(_aRet)

// ** funcao para selecionar os centros de custos disponiveis, conforme hierarquia
Static Function sfSelCenCus(mvObjBrowse)
	// variavel de retorno
	local _lRet := .f.

	// variaveis temporarias
	local _cQryCTT

	// centros de custos ja selecionados
	local _cCcJaUtili := ""

	// centros de custos que pode utilizar
	local _cCcDisponivel := ""

	// objetos da tela
	local _oWndSelCC
	local _oPnlCab1
	local _oBrwCC

	// estrutura do Browse
	Local _aHeadBrw := {" "," ","Centro de Custo","Descrição"}
	local _aCenCusto := {}

	// variaveis temporarias
	local _aTmpCCSup := {}
	local _nX

	// imagens da legenda
	local _oVermelho := LoadBitMap(GetResources(), "BR_VERMELHO")
	local _oVerde    := LoadBitMap(GetResources(), "BR_VERDE")
	local _oAmarelo  := LoadBitMap(GetResources(), "BR_AMARELO")

	// busca os centros de custo do ID superior
	If ( ! Empty(_cIdSuperi))
		// funcao que retorno os CC do perfil
		_aTmpCCSup := sfRetCC(_cIdSuperi,.f.)
		// atualiza relacao de CC que podera ser utilizado
		aEval(_aTmpCCSup,{|X| _cCcDisponivel += X[1] + "|" })
	EndIf

	// coloca os centros de custos ja utilizados em formato IN de SQL
	aEval(mvObjBrowse:aCols,{|X| _cCcJaUtili += X[1] + "|" })

	// monta query para buscar os CC disponiveis
	_cQryCTT := "SELECT ' ' IT_SELECT, "
	// cores da legenda
	_cQryCTT += "CASE "
	_cQryCTT += "  WHEN CTT_CUSTO IN "+FormatIn(_cCcJaUtili,"|")+" THEN 'OK' "
	_cQryCTT += "  WHEN CTT_CLASSE = '1' THEN 'BL' "
	// se nao estiver na relacao de CC disponivel, nao permite selecao
	If ( ! Empty(_cCcDisponivel) )
		_cQryCTT += "  WHEN CTT_CUSTO NOT IN "+FormatIn(_cCcDisponivel,"|")+" THEN 'BL' "
	EndIf
	_cQryCTT += "ELSE "
	_cQryCTT += "  '  ' END IT_COR, "
	// codigo e descricao
	_cQryCTT += "CTT_CUSTO, CTT_DESC01 "
	// cad. de centro de custo
	_cQryCTT += "FROM "+RetSqlName("CTT")+" CTT "
	// filtro padrao
	_cQryCTT += "WHERE "+RetSqlCond("CTT")
	// somente desbloqueados
	_cQryCTT += "AND CTT_BLOQ != '1' "
	// ordem dos dados
	_cQryCTT += "ORDER BY CTT_CUSTO "

	// alimenta vetor de centro de custo
	_aCenCusto := U_SqlToVet(_cQryCTT)

	// atualiza OBJETO da coluna na relacao de CC que podera ser utilizado
	aEval(_aCenCusto,{|_xVetor| _xVetor[2] := If(_xVetor[2]=="OK",_oAmarelo,If(_xVetor[2]=="BL",_oVermelho,_oVerde)) })


	// monta o dialogo do monitor
	_oWndSelCC := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Definição de CC",,,.F.,,,,,,.T.,,,.T. )
	_oWndSelCC:lMaximized := .T.

	// cria o panel do cabecalho - botoes de operacao
	_oPnlCab1 := TPanel():New(000,000,nil,_oWndSelCC,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnlCab1:Align:= CONTROL_ALIGN_TOP

	// browse com a listagem dos centros de custos disponiveis
	_oBrwCC := TWBrowse():New(020,020,480,0270,,_aHeadBrw,,_oWndSelCC,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	// seta vetor com o conteudo
	_oBrwCC:SetArray(_aCenCusto)
	// informacoes por coluna
	_oBrwCC:bLine := {|| {_aCenCusto[_oBrwCC:nAT][1],_aCenCusto[_oBrwCC:nAT][2],_aCenCusto[_oBrwCC:nAT][3],_aCenCusto[_oBrwCC:nAT][4]}}
	// duplo clique
	_oBrwCC:bldblClick := {|| sfAtuLegBrw(@_oBrwCC,@_aCenCusto) }
	_oBrwCC:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oWndSelCC CENTERED ON INIT EnchoiceBar(_oWndSelCC,{|| _lRet := .t., _oWndSelCC:End() } , {|| _oWndSelCC:End() })

	// se confirmou, atualiza a lista de CC
	If (_lRet)

		// varre todos os itens selecionados
		For _nX := 1 to Len(_aCenCusto)
			// verifica se o CC já está na lista
			If ( AllTrim(_aCenCusto[_nX][2]:cName)=="BR_VERDE" ).and.( ! Empty(_aCenCusto[_nX][1]) ).and.( aScan( _aColsCC, {|x| x[1] == _aCenCusto[_nX][3] }) == 0 )
				// adiciona novo CC
				aAdd(_aColsCC,{_aCenCusto[_nX][3], _aCenCusto[_nX][4], .f.})
			EndIf
		Next _nX

		// atualiza aCols do browse
		mvObjBrowse:aCols := aClone(_aColsCC)

	EndIF

Return(_lRet)

// ** funcao para atualizar a lengenda do browse
Static Function sfAtuLegBrw(mvObjBrowse,mvCenCusto)
	mvCenCusto[mvObjBrowse:nAT][1] := If( Empty(mvCenCusto[mvObjBrowse:nAT][1]) ,"X"," ")
Return

// ** funcao que monta o vetor da hierarquia em cima do Cadastro de Gerencia
Static Function sfMntVetor()
	// variaveis temporarias
	Local _aTemp := {}
	Local _aRet  := {}
	// perfil superior
	Local _cUsrSupe := ""

	Local _cNivel    := "001"
	Local _cSubNivel := ""
	Local _nPos		:= 0
	Local _nPosSub := 0

	// monta select para buscar o cadastro de gerencia
	_cQuery := "SELECT Z26_PERFID, Z26_SETOR, Z26_GERENT, Z26_NIVEL, Z26_PERSUP, "
	_cQuery += "Z26_MSBLQL "
	// cadastro da gerencia/niveis
	_cQuery += "FROM "+RetSqlTab("Z26")
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z26")
	// ano base
	_cQuery += "AND Z26_CALEND = '"+_cAnoBase+"' "
	// controle de perfil bloqueado
	If ( ! _lVisPrfBlq )
		_cQuery += "AND Z26_MSBLQL != '1' "
	EndIf
	// ordem dos dados
	_cQuery += "ORDER BY Z26_NIVEL, Z26_PERSUP DESC"

	memowrit("c:\query\tcomc002_sfMntVetor.txt", _cQuery)

	If (Select("_QRYSZ7") <> 0)
		DBSelectArea("_QRYSZ7")
		_QRYSZ7->(DBCloseArea())
	Endif

	// executa o select
	dbUseArea(.T., "TOPCONN", TCGENQRY(,,_cQuery), "_QRYSZ7", .F., .T.)
	DBSelectArea("_QRYSZ7")
	_QRYSZ7->(DBGoTop())

	// varre todos os itens
	If ( ! _QRYSZ7->(Eof()))

		// armazena codigo do perfil superior
		_cUsrSupe := _QRYSZ7->Z26_PERSUP

		While (! _QRYSZ7->(Eof()))

			_cSubNivel	:= "001"
			_nPosSub	:= 1

			// procura se ja tem algum codigo igual ao do Superior
			_nPos := aScan( _aTemp, {|x| x[2] == _QRYSZ7->Z26_PERSUP})

			// verifica se ja tem um subnivel igual
			If _nPos > 0
				While _nPosSub > 0
					_nPosSub := aScan(_aTemp, {|x| x[1] == _aTemp[_nPos,1]+_cSubNivel+"."})
					If _nPosSub > 0
						_cSubNivel := Soma1(_cSubNivel)
					EndIf
				EndDo

				AAdd(_aTemp,{_aTemp[_nPos,1]+_cSubNivel+".",_QRYSZ7->Z26_PERFID,_QRYSZ7->Z26_SETOR,_QRYSZ7->Z26_GERENT,_QRYSZ7->Z26_NIVEL,_QRYSZ7->Z26_PERSUP,_QRYSZ7->Z26_MSBLQL})

			Else
				If (_cUsrSupe <> _QRYSZ7->Z26_PERSUP)
					Aviso("Relacionamento","Erro no cadastro. Verifique os perfis desativados" +CRLF+ "Cód. Perfil: "+_QRYSZ7->Z26_PERFID+" - Cód. Superior: "+_QRYSZ7->Z26_PERSUP,{"OK"})
				Else
					AAdd(_aTemp,{_cNivel+".",_QRYSZ7->Z26_PERFID,_QRYSZ7->Z26_SETOR,_QRYSZ7->Z26_GERENT,_QRYSZ7->Z26_NIVEL,_QRYSZ7->Z26_PERSUP,_QRYSZ7->Z26_MSBLQL})
					_cNivel := Soma1(_cNivel)
				EndIF
			EndIf

			_cUsrSupe := _QRYSZ7->Z26_PERSUP

			// proximo item
			_QRYSZ7->(DBSkip())
		EndDo
	EndIf

	// ordena os dados para retorno
	_aRet := aSort(_aTemp,,, { |x, y| x[1] < y[1] })

Return(_aRet)

// ** funcao que Monta o TreeView baseado no vetor _aEstrutura
Static Function sfMntTreeView()
	local _nUltPos := 0
	local _nPos := 0
	local _nX := 0
	local _nTamKey := 30

	ProcRegua(Len(_aEstrutura))

	For _nPos := 1 to Len(_aEstrutura)-1

		Incproc()

		If Len(AllTrim(_aEstrutura[_nPos,1])) < Len(AllTrim(_aEstrutura[_nPos+1,1]))

			DBAddTree _oTreeCC Prompt PadR(AllTrim(_aEstrutura[_nPos,4])+" ("+AllTrim(_aEstrutura[_nPos,3])+")",100) Resource sfRetImgUsr(_aEstrutura[_nPos,5], _aEstrutura[_nPos,7]) Cargo PadR("S;"+_aEstrutura[_nPos,2],_nTamKey)

			_aCC := sfRetCC(_aEstrutura[_nPos,2],.f.)

			If Len(_aCC) > 0
				For niCC := 1 to Len(_aCC)
					DBAddItem _oTreeCC Prompt AllTrim(_aCC[niCC,1])+"-"+_aCC[niCC,2] Resource sfRetImgCC(_aCC[niCC,3]) Cargo PadR("C;"+_aEstrutura[_nPos,2]+";"+_aCC[niCC,1],_nTamKey)
				Next niCC
			EndIf

		ElseIf Len(AllTrim(_aEstrutura[_nPos,1])) > Len(AllTrim(_aEstrutura[_nPos+1,1]))

			_aCC := sfRetCC(_aEstrutura[_nPos,2],.f.)

			If Len(_aCC) > 0
				DBAddTree _oTreeCC Prompt PadR(AllTrim(_aEstrutura[_nPos,4])+" ("+AllTrim(_aEstrutura[_nPos,3])+")",100) Resource sfRetImgUsr(_aEstrutura[_nPos,5], _aEstrutura[_nPos,7]) Cargo PadR("S;"+_aEstrutura[_nPos,2],_nTamKey)

				For niCC := 1 to Len(_aCC)
					DBAddItem _oTreeCC Prompt AllTrim(_aCC[niCC,1])+"-"+_aCC[niCC,2] Resource sfRetImgCC(_aCC[niCC,3]) Cargo PadR("C;"+_aEstrutura[_nPos,2]+";"+_aCC[niCC,1],_nTamKey)
				Next niCC

				DBEndTree _oTreeCC
			Else

				DBAddItem _oTreeCC Prompt PadR(AllTrim(_aEstrutura[_nPos,4])+" ("+AllTrim(_aEstrutura[_nPos,3])+")",100) Resource _aLegenda[Val(_aEstrutura[_nPos,5])+1,2] Cargo PadR("S;"+_aEstrutura[_nPos,2],_nTamKey)

			EndIf

			_nUltPos := _nPos

			For _nX := 1 to (Len(AllTrim(_aEstrutura[_nPos,1])) - Len(AllTrim(_aEstrutura[_nPos+1,1]))) Step 4
				DBEndTree _oTreeCC
			Next _nX
		Else
			_aCC := sfRetCC(_aEstrutura[_nPos,2],.f.)

			If Len(_aCC) > 0

				DBAddTree _oTreeCC Prompt PadR(AllTrim(_aEstrutura[_nPos,4])+" ("+AllTrim(_aEstrutura[_nPos,3])+")",100) Resource sfRetImgUsr(_aEstrutura[_nPos,5], _aEstrutura[_nPos,7]) Cargo PadR("S;"+_aEstrutura[_nPos,2],_nTamKey)

				For niCC := 1 to Len(_aCC)
					DBAddItem _oTreeCC Prompt AllTrim(_aCC[niCC,1])+"-"+_aCC[niCC,2] Resource sfRetImgCC(_aCC[niCC,3]) Cargo PadR("C;"+_aEstrutura[_nPos,2]+";"+_aCC[niCC,1],_nTamKey)
				Next niCC

				DBEndTree _oTreeCC

			Else

				DBAddItem _oTreeCC Prompt PadR(AllTrim(_aEstrutura[_nPos,4])+" ("+AllTrim(_aEstrutura[_nPos,3])+")",100) Resource sfRetImgUsr(_aEstrutura[_nPos,5], _aEstrutura[_nPos,7]) Cargo PadR("S;"+_aEstrutura[_nPos,2],_nTamKey)

			EndIf

			_nUltPos := _nPos
		EndIf
	Next _nPos

	If _nUltPos <= Len(_aEstrutura)

		_aCC := sfRetCC(_aEstrutura[_nPos,2],.f.)

		If Len(_aCC) > 0
			DBAddTree _oTreeCC Prompt PadR(AllTrim(_aEstrutura[_nPos,4])+" ("+AllTrim(_aEstrutura[_nPos,3])+")",100) Resource sfRetImgUsr(_aEstrutura[_nPos,5], _aEstrutura[_nPos,7]) Cargo PadR("S;"+_aEstrutura[_nPos,2],_nTamKey)

			For niCC := 1 to Len(_aCC)
				DBAddItem _oTreeCC Prompt AllTrim(_aCC[niCC,1])+"-"+_aCC[niCC,2] Resource sfRetImgCC(_aCC[niCC,3]) Cargo PadR("C;"+_aEstrutura[_nPos,2]+";"+_aCC[niCC,1],_nTamKey)
			Next niCC

			DBEndTree _oTreeCC
		Else

			DBAddItem _oTreeCC Prompt PadR(AllTrim(_aEstrutura[_nPos,4])+" ("+AllTrim(_aEstrutura[_nPos,3])+")",100) Resource sfRetImgUsr(_aEstrutura[_nPos,5], _aEstrutura[_nPos,7]) Cargo PadR("S;"+_aEstrutura[_nPos,2],_nTamKey)

		EndIf

		_nPos	:=	Len(_aEstrutura)

		For _nX := 1 to Len(AllTrim(_aEstrutura[_nPos,1])) Step 4
			DBEndTree _oTreeCC
		Next _nX
	EndIf

	DBEndTree _oTreeCC

	// atualiza o Objeto TreeView
	_oTreeCC:Refresh()

Return

// ** funcao que retorna a descricao do ID superior
Static Function sfRetDscSup(mvIDSuper)
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z26"})
	// variavel de retorno
	local _cRet := Posicione("Z26",1, xFilial("Z26")+_cAnoBase+mvIDSuper ,"Z26_GERENT")

	// restaura areas iniciais
	RestOrd(_aAreaIni,.t.)
	RestArea(_aArea)

Return(_cRet)

// ** funcao que Retorna o nome da Imagem (CC Bloq = IRACCB001, CC = BMPCPO) vetor _aLegenda
Static Function sfRetImgCC(mvBloqCC)
	local _cRetImg := ""
	local _nPosLeg := aScan( _aLegenda , {|x| x[3] == "CC"+If(mvBloqCC=="2","OK","BL") } )

	// prepara retorno
	If (_nPosLeg > 0)
		_cRetImg += _aLegenda[_nPosLeg][2]
	EndIf

Return(_cRetImg)

// ** funcao que Retorna o nome da Imagem do usuário vetor _aLegenda
Static Function sfRetImgUsr(mvNivel, mvBloq)
	// inicio do conteudo da imagem
	local _cRetImg := "COM_USR_"
	local _nPosNiv := aScan( _aLegenda , {|x| AllTrim(x[3]) == AllTrim(mvNivel) } )

	// prepara retorno
	If (mvBloq != "1")
		_cRetImg += _aLegenda[_nPosNiv][3]
	Else
		_cRetImg := "DBG09"
	EndIf

Return(_cRetImg)

// ** funcao que Atualiza o Tree View
Static Function sfAtuTree()

	// atualiza estrutura do cadastro de gerencia
	_aEstrutura := sfMntVetor()

	// eleta toda a Arvore
	_oTreeCC:Reset()

	If Len(_aEstrutura) > 0
		Processa({ || sfMntTreeView() },"Montando Tree View...","",.F.)
	EndIf

Return

// ** funcao que Monta o aHeader do browse de centros de custos
Static Function sfMntHeader(ciAltCmp)
	// variavel de retorno
	Local _aRet := {}

	// alimenta o header
	aAdd(_aRet,{"Centro Custo", "CTT_CUSTO" , PesqPict("CTT","CTT_CUSTO") , TamSx3("CTT_CUSTO")[2] , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aRet,{"Descrição"   , "CTT_DESC01", PesqPict("CTT","CTT_DESC01"), TamSx3("CTT_DESC01")[2], 0,Nil,Nil,"C",Nil,"R" })

Return(_aRet)

// ** funcao que atualiza os Dados
Static Function sfAtuDados(mvTipoOpe)
	// variaveis temporarias
	local _cTmpCodCC
	local _cTmpCodItem
	local _nSeqMes := 1
	local _cCampoMes
	local _dDtIniPer
	local _dDtFimPer
	local _nPosCC

	// atualiza variavel com os dados do browse
	_aColsCC := aClone(_oBrw01CC:aCols)

	// define regua de processamento
	procregua( Len(_aColsCC) )

	// INICIA transacao
	Begin Transaction

		// seleciona tabela do perfil
		dbSelectArea("Z26")
		// define operacao RecLock (Inclusao/Alteracao)
		RecLock("Z26",(mvTipoOpe=="I"))
		// na inclusao, cria no ID do perfil
		If (mvTipoOpe == "I")
			Z26->Z26_FILIAL := xFilial("Z26")
			Z26->Z26_PERFID := GetSX8Num("Z26","Z26_PERFID")
			Z26->Z26_CALEND := _cAnoBase
			ConfirmSX8()
			// atualiza codigo do novo perfil
			_cCodPerfil := Z26->Z26_PERFID
		EndIf
		// atualiza demais campos
		Z26->Z26_SETOR  := _cDscSetor
		Z26->Z26_CODUSU := _cCodUser
		Z26->Z26_GERENT := _cNomeGeren
		Z26->Z26_NIVEL	:= _cNvlPerf
		Z26->Z26_PERSUP := _cIdSuperi
		// controle de bloqueio de perfil
		Z26->Z26_MSBLQL := _cMsBloq
		// grava dados
		Z26->(MsUnLock())


		// varre todos os item do browse CC
		For _nPosCC := 1 to Len(_aColsCC)

			// codigo do centro de custo
			_cTmpCodCC := _aColsCC[_nPosCC,1]

			// incremento da regua
			IncProc("Gravando itens CC "+_cTmpCodCC+" ...")

			// abre arquivo de trabalho
			(_TRBITEM)->(dbSelectArea(_TRBITEM))
			(_TRBITEM)->(dbSetOrder(1)) // 1-IT_CC, IT_ITEM

			// pesquisa no TRB
			(_TRBITEM)->(dbSeek( _cTmpCodCC ))

			// varre todos os itens do TRB do centro de custo posicionado
			While (_TRBITEM)->( !Eof() ).and.((_TRBITEM)->IT_CC == _cTmpCodCC)

				// item contabil
				_cTmpCodItem := (_TRBITEM)->IT_ITEM

				// varre todos os meses
				For _nSeqMes := 1 to 12

					// define o campo MES
					_cCampoMes := "IT_LIM"+StrZero(_nSeqMes,2)

					// data de inicio e fim do periodo
					_dDtIniPer := CtoD("01/"+StrZero(_nSeqMes,2)+"/"+_cAnoBase)
					_dDtFimPer := LastDay(_dDtIniPer)

					// cadastro de alcada x perfil x mes
					dbSelectArea("Z27")
					Z27->(dbSetOrder(3)) // 3-Z27_FILIAL, Z27_CALEND, Z27_PERFIL, Z27_CC, Z27_ITEMC, Z27_DATAIN, Z27_DATAFM

					// Posiciona no Registro Certo
					If Z27->(DBSeek( xFilial("Z27")+_cAnoBase+_cCodPerfil+_cTmpCodCC+_cTmpCodItem+DtoS(_dDtIniPer)+DtoS(_dDtFimPer) ))

						// verifica se o item esta deletado no Browse
						If (_aColsCC[_nPosCC,Len(_aHeadCC)+1]).or.((_TRBITEM)->IT_DELITEM == "S")
							// deleta Registro
							RecLock("Z27",.F.)
							Z27->(DBDelete())
							MsUnLock("Z27")
						Else
							// atualiza Dados
							RecLock("Z27",.F.)
							Z27->Z27_LIMITE := (_TRBITEM)->(&(_cCampoMes))
							Z27->Z27_MSBLQL := _cMsBloq
							MsUnLock("Z27")

						EndIf
					Else
						// Adiciona Registros
						RecLock("Z27",.T.)
						Z27->Z27_FILIAL := xFilial("Z27")
						Z27->Z27_CALEND := _cAnoBase
						Z27->Z27_LIMPID := _cCodPerfil
						Z27->Z27_PERFIL := _cCodPerfil
						Z27->Z27_CC     := _cTmpCodCC
						Z27->Z27_ITEMC  := _cTmpCodItem
						Z27->Z27_LIMITE := (_TRBITEM)->(&(_cCampoMes))
						Z27->Z27_DATAIN := _dDtIniPer
						Z27->Z27_DATAFM := _dDtFimPer
						Z27->Z27_MSBLQL := _cMsBloq
						MsUnLock("Z27")
					EndIf

				Next _nSeqMes

				// proximo item do TRB
				(_TRBITEM)->(dbSkip())
			EndDo

		Next _nPosCC

		// FINALIZA transacao
	End Transaction

Return(.t.)

// ** funcao que valida os dados e Salva Alterações
Static Function sfValDados(mvObjTela)
	// area atual
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z26","Z27"})
	// variaveis temporarias
	local _nCC
	Local _cTmpCodCC := ""
	// variavel de retorno
	local _lRet := .t.

	// atualiza variavel com os dados do browse
	_aColsCC := aClone(_oBrw01CC:aCols)

	//Campos em Branco
	If Empty(_cDscSetor)
		Aviso("Cadastro","É necessário informar o Setor.",{"OK"})
		_lRet := .f.
	ElseIf Empty(_cCodUser)
		Aviso("Cadastro","É necessário informar o Código do Aprovador.",{"OK"})
		_lRet := .f.
	ElseIf Empty(_cNomeGeren)
		Aviso("Cadastro","É necessário informar o Nome do Aprovador.",{"OK"})
		_lRet := .f.
	EndIf

	// valida se o nivel do Superior é maior que o nível informado
	If (_lRet).and.(Posicione("Z26",1, xFilial("Z26")+_cAnoBase+_cIdSuperi ,"Z26_NIVEL") >= _cNvlPerf)
		Aviso("Superior","Nível do Superior deve ser maior que o nível desta Gerência!!!",{"OK"})
		_lRet := .f.
	EndIf

	// verifica se pode bloquear o cadastro
	If (_lRet).and.(_cMsBloq == "1").and.( ! Empty(Posicione("Z26",4, xFilial("Z26")+_cAnoBase+_cCodPerfil ,"Z26_PERFID")))
		Aviso("Bloqueio","Este Perfil não pode ser bloqueado pois existem Alçadas relacionadas à este cadastro.",{"OK"})
		_lRet := .f.
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni,.t.)
	RestArea(_aArea)

	// validao ok, fecha a tela
	If (_lRet)
		mvObjTela:End()
	EndIf

Return(_lRet)

// ** funcao que Valida o ID do Superior
Static Function sfVldSuper()
	// variavel de retorno
	local _lRet := .t.

	If ( ! Empty(_cIdSuperi))

		// retorna a descricao do Id Superior
		_cDscSuper := sfRetDscSup(_cIdSuperi)//oga - 28/01/14

		// valida retorno
		If Empty(_cDscSuper)
			Aviso("Superior","Usuário não encontrado!",{"OK"})
			_lRet := .f.
		EndIf
	Else
		_cDscSuper := Space(Len(_cDscSuper))
	EndIf

Return(_lRet)

// ** funcao que Valida o Usuário aprovador
Static Function sfVldIdAprov()

	// verifica se o usuario esta no cadastro de solicitantes
	dbSelectArea("SAI")
	SAI->(dbSetOrder(2)) // 2-AI_FILIAL, AI_USER
	If ! SAI->(dbSeek( xFilial("SAI")+_cCodUser ))
		MsgAlert("Usuário não cadastrado como solicitante!")
		_cNomeGeren := CriaVar("Z26_GERENT",.f.)
		Return(.f.)
	EndIf

	// atualiza o Nome do Gerente
	_cNomeGeren := UsrFullName(_cCodUser)

	// padroniza o tamanho do campo
	_cNomeGeren := PadR(_cNomeGeren,TamSx3("Z26_GERENT")[1])
	_cNomeGeren := Upper(_cNomeGeren)

	// valida retorno
	If (Empty(_cNomeGeren))
		MsgAlert("Usuário não encontrado!")
		_cNomeGeren := CriaVar("Z26_GERENT",.f.)
		Return(.f.)
	EndIf

Return(.t.)

// ** funcao que monta o Vetor com as Legendas e imagens de cada Nivel
Static Function sfLegenda()
	// variaveis temporarias
	local _nX
	local _aRet := {}

	// varre todos os niveis
	For _nX := 1 to Len(_aNiveis)
		// adiciona opcao
		aAdd( _aRet , { PadR(SubStr(_aNiveis[_nX],3,Len(_aNiveis[_nX])),20) ,;
			"COM_USR_"+SubS(_aNiveis[_nX],1,1),;
			SubS(_aNiveis[_nX],1,1) })
	Next _nX

	// legenda Centro de Custo
	aAdd(_aRet,{"Centro de Custo","COM_CC_OK","CCOK" })

	// perfil bloqueado
	aAdd(_aRet,{"Perfil Bloqueado","DBG09","DBG09" })

Return(_aRet)

// ** funcao que prepara TRB com as informacoes dos itens contabeis
Static Function sfMntTrbItem(mvColsCC)
	// estrutura do arquivo de trabalho dos itens contabeis
	local _aEstruTrb := {}
	// variaveis temporarias
	local _nSeqMes := 1
	local _cCampoMes
	local _nCC
	local _cQryZ27
	local _aRecnoZ27
	local _nRecnoZ27
	local _dDtReferen

	// codigo do centro de custo
	local _cCodCenCus
	
	// define estrutura do TRB de centro de custo
	aAdd(_aEstruTrb,{"IT_CC"     ,"C",TamSx3("CTT_CUSTO")[1],0})
	aAdd(_aEstruTrb,{"IT_ITEM"   ,"C",TamSx3("CTD_ITEM")[1],0})
	For _nSeqMes := 1 to 12
		aAdd(_aEstruTrb,{"IT_LIM"+StrZero(_nSeqMes,2) ,"N",TamSx3("Z27_LIMITE")[1],TamSx3("Z27_LIMITE")[2]})
	Next _nSeqMes
	// deletar informacoes
	aAdd(_aEstruTrb,{"IT_DELITEM","C",1,0})

	// fecha alias em uso
	If (Select(_TRBITEM)<>0)
		dbSelectArea(_TRBITEM)
		dbCloseArea()
	EndIf

	// criar um arquivo de trabalho
	_cArqTmp:= FWTemporaryTable():New(_TRBITEM)
	_cArqTmp:SetFields(_aEstruTrb)
	_cArqTmp:AddIndex("01", {"IT_CC","IT_ITEM"} )
	_cArqTmp:Create()

	// varre todos os meses
	For _nSeqMes := 1 to 12

		// define o campo MES
		_cCampoMes  := "IT_LIM"+StrZero(_nSeqMes,2)

		// define data de referencia
		_dDtReferen := CtoD( "01/" + StrZero(_nSeqMes,2)+"/"+_cAnoBase )

		// varre todos os centros de custos selecionados
		For _nCC := 1 to Len(mvColsCC)

			// define o centro de custo
			_cCodCenCus := mvColsCC[_nCC][1]

			// monta quer para verificar os centros de custo existentes no perfil
			_cQryZ27 := "SELECT Z27.R_E_C_N_O_ Z27RECNO "
			// centro de custo e itens do perfil
			_cQryZ27 += "FROM "+RetSqlName("Z27")+" Z27 "
			// filtro padrao
			_cQryZ27 += "WHERE "+RetSqlCond("Z27")
			// filtro por perfil e centro de custo
			_cQryZ27 += "AND Z27_PERFIL = '"+_cCodPerfil+"' AND Z27_CC = '"+_cCodCenCus+"' "
			// ano base
			_cQryZ27 += "AND Z27_CALEND = '"+_cAnoBase+"' "
			// filtro do mes
			_cQryZ27 += "AND '"+DtoS(_dDtReferen)+"' BETWEEN Z27_DATAIN AND Z27_DATAFM "
			// alimenta vetor com os RECNOs
			_aRecnoZ27 := U_SqlToVet(_cQryZ27)

			// varre todos os itens contabeis do centro de custo
			For _nRecnoZ27 := 1 to Len(_aRecnoZ27)

				// posiciona no registro real da tabela
				dbSelectArea("Z27")
				Z27->(dbGoTo(_aRecnoZ27[_nRecnoZ27]))


				(_TRBITEM)->(dbSelectArea(_TRBITEM))
				(_TRBITEM)->(dbSetOrder(1)) // 1-IT_CC, IT_ITEM

				// pesquisa no TRB
				If ! (_TRBITEM)->(dbSeek( Z27->(Z27_CC+Z27_ITEMC) ))
					// inclui novo registro no TRB
					(_TRBITEM)->(RecLock(_TRBITEM,.t.))
					(_TRBITEM)->IT_CC           := Z27->Z27_CC
					(_TRBITEM)->IT_ITEM         := Z27->Z27_ITEMC
					(_TRBITEM)->(&(_cCampoMes)) := Z27->Z27_LIMITE
					(_TRBITEM)->(MsUnLock())
				Else
					// atualiza valor do mes
					(_TRBITEM)->(RecLock(_TRBITEM,.f.))
					(_TRBITEM)->(&(_cCampoMes)) := Z27->Z27_LIMITE
					(_TRBITEM)->(MsUnLock())

				EndIf

			Next _nRecnoZ27

		Next _nCC

	Next _nSeqMes
	

Return

// ** funcao para definicao de item contabil e alcadas
Static Function sfDefItemCtb(mvCodCenCus)
	// controle de dados Ok
	local _lOk := .f.

	// objetos da tela
	local _oWnd03Alcada
	local _oPnl03Cab1, _oPnl03Cab2
	local _oSay03ItCon, _oSay03DsCon, _oSay03Valor, _oSay03CenCus, _oSay03Setor, _oSay03Resp
	local _oGet03ItCon, _oGet03Valor
	local _oBtn03Add, _oBtn03Sup, _oBtn03Inf

	// codigo do item contabil
	local _cCodItCtb := CriaVar("CTD_ITEM",.f.)
	local _cDscItCtb := CriaVar("CTD_DESC01",.f.)
	local _nVlrRepli := 0

	// objetos do browse
	private _aHeadItem := sfMntHdIte()
	private _aColsItem := sfColsAlca(mvCodCenCus)
	// objetos da tela
	private _oBrw03ItCont

	// variaveis temporarias
	private _cTmp03CdCC := mvCodCenCus

	// seleciona arquivo de trabalho
	(_TRBITEM)->(dbSelectArea(_TRBITEM))
	(_TRBITEM)->(dbSetOrder(1)) // 1-IT_CC, IT_ITEM

	// monta o dialogo do monitor
	_oWnd03Alcada := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Definição de Itens Contábeis",,,.F.,,,,,,.T.,,,.T. )
	_oWnd03Alcada:lMaximized := .T.

	// cria o panel do cabecalho - titulo
	_oPnl03Cab1 := TPanel():New(000,000,,_oWnd03Alcada,,.T.,.F.,,,000,030,.T.,.F.)
	_oPnl03Cab1:Align:= CONTROL_ALIGN_TOP

	// setor
	_oSay03Setor  := TSay():New(001,005,{||"Setor: "+_cDscSetor},_oPnl03Cab1,,_oFnt01,.F.,.F.,.F.,.T.)
	// gerente
	_oSay03Resp   := TSay():New(011,005,{||"Responsável: "+_cNomeGeren},_oPnl03Cab1,,_oFnt01,.F.,.F.,.F.,.T.)
	// centro de custo
	_oSay03CenCus := TSay():New(021,005,{||"Centro de Custo: "+AllTrim(mvCodCenCus)+" - "+Posicione("CTT",1, xFilial("CTT")+mvCodCenCus ,"CTT_DESC01") },_oPnl03Cab1,,_oFnt01,.F.,.F.,.F.,.T.)

	// cria o panel do cabecalho - campos e opcoes
	_oPnl03Cab2 := TPanel():New(000,000,nil,_oWnd03Alcada,,.F.,.F.,,,22,22,.T.,.F.)
	_oPnl03Cab2:Align:= CONTROL_ALIGN_TOP

	// item contabil
	_oSay03ItCon := TSay():New(007,005,{||"Item Contábil"},_oPnl03Cab2,,,.F.,.F.,.F.,.T.)
	_oGet03ItCon := TGet():New(005,040,{|u| If(PCount()>0,_cCodItCtb:=u,_cCodItCtb)},_oPnl03Cab2,040,010,PesqPict("CTD","CTD_ITEM"),{|| sfVldItCtb(_cCodItCtb,@_cDscItCtb,@_oSay03DsCon) },,,,,,.T.,"",,{|| .t. },.F.,.F.,,.F.,.F.,"CTD","_cCodItCtb",,)
	_oSay03DsCon := TSay():New(007,100,{|| _cDscItCtb },_oPnl03Cab2,,,.F.,.F.,.F.,.T.)

	// valor
	_oSay03Valor := TSay():New(007,240,{||"Valor"},_oPnl03Cab2,,,.F.,.F.,.F.,.T.)
	_oGet03Valor := TGet():New(005,260,{|u| If(PCount()>0,_nVlrRepli:=u,_nVlrRepli)},_oPnl03Cab2,055,010,PesqPict("Z27","Z27_LIMITE"),{|| .t. },,,,,,.T.,"",,{|| .t. },.F.,.F.,,.F.,.F.,"","_nVlrRepli",,)

	// adicionar unico item
	_oBtn03Add := TButton():New(005,320,"Adicionar Item",_oPnl03Cab2,{|| sfAddValor(_cCodItCtb,_nVlrRepli,@_oBrw03ItCont,@_aColsItem ) },050,012,,,,.T.,,"",,,,.F. )

	// replicar nivel superior
	_oBtn03Sup := TButton():New(005,410,"Replicar Niv. Sup.",_oPnl03Cab2,{|| sfRepNivSup(_cTmp03CdCC, @_oBrw03ItCont,@_aColsItem ) },050,012,,,,.T.,,"",,,,.F. )

	// browse com a listagem dos itens contabeis
	_oBrw03ItCont := MsNewGetDados():New(122,008,201,320,GD_INSERT + GD_UPDATE + GD_DELETE,'U_COMC002C(_cTmp03CdCC, _oBrw03ItCont:aCols[_oBrw03ItCont:nAt][1], _oBrw03ItCont:aCols, _oBrw03ItCont:nAt, _cIdSuperi, .t.)','AllwaysTrue()','',,,999,'AllwaysTrue()','','U_COMC002B(_cCodUser, _cTmp03CdCC, _oBrw03ItCont:aCols[_oBrw03ItCont:nAt][1], _cCodPerfil)',_oWnd03Alcada,_aHeadItem,_aColsItem)
	_oBrw03ItCont:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oWnd03Alcada CENTERED ON INIT EnchoiceBar(_oWnd03Alcada,{|| MsgRun( "Validando Cadastro..." , "Aguarde..." , { || _lOk := sfVldDefIte(@_oWnd03Alcada, _oBrw03ItCont, mvCodCenCus) } ) } , {|| _oWnd03Alcada:End() })

Return

// ** funcao que monta header dos itens contabeis/alcadas
Static Function sfMntHdIte()
	// variavel de retorno
	local _aRet := {}
	// variaveis temporarias
	local _nSeqMes
	local _cSiglaMes
	local _cMskAlcada := PesqPict("Z27","Z27_LIMITE")

	// alimenta o header
	aAdd(_aRet,{"Item Contábil", "CTD_ITEM"   , PesqPict("CTD","CTD_ITEM")   , TamSx3("CTD_ITEM")[1]  , 0,"U_COMC002A()",Nil,"C",Nil,"R" })
	aAdd(_aRet,{"Descrição"    , "CTD_DESC01" , PesqPict("CTD","CTD_DESC01") , TamSx3("CTD_DESC01")[1], 0,Nil           ,Nil,"C",Nil,"V" })

	// cria campo para todos os meses
	For _nSeqMes := 1 to 12
		// descricao do mes
		_cSiglaMes := Left(MesExtenso(_nSeqMes),3)
		// adiciona o mes
		aAdd(_aRet,{"Alçada "+_cSiglaMes+" R$", "IT_LIM"+StrZero(_nSeqMes,2), _cMskAlcada, 0, 0,Nil,Nil,"N",Nil,"R" })
	Next _nSeqMes

Return(_aRet)


// ** funcao que monta o aCols das alcadas
Static Function sfColsAlca(mvCodCenCus)
	// variavel de retorno
	local _aRet := {}
	// variaveis temporarias
	local _nTmpLin
	local _nSeqMes
	local _cCampoMes
	
	_TRBITEM := _cArqTmp:GetAlias()
	(_TRBITEM)->(dbSelectArea(_TRBITEM))
	(_TRBITEM)->(dbGoTop())

	// varre todos os itens do TRB
	While (_TRBITEM)->( ! Eof())

		// valida o Centro de Custo
		If ((_TRBITEM)->IT_CC != mvCodCenCus).or.((_TRBITEM)->IT_DELITEM == "S")
			// proximo item
			(_TRBITEM)->(dbSkip())
			Loop
		EndIf

		// cria nova linha em branco
		aAdd(_aRet, Array(Len(_aHeadItem)+1))
		// define posicao da linha
		_nTmpLin := Len(_aRet)

		// atualiza codigo e descricao
		_aRet[_nTmpLin][1] := (_TRBITEM)->IT_ITEM
		_aRet[_nTmpLin][2] := Posicione("CTD",1, xFilial("CTD")+(_TRBITEM)->IT_ITEM ,"CTD_DESC01" )

		// atualiza alcada de cada mes
		For _nSeqMes := 1 to 12

			// define o campo MES
			_cCampoMes := "IT_LIM"+StrZero(_nSeqMes,2)

			// atualiza browse com conteudo do TRB]
			_aRet[_nTmpLin][_nSeqMes+2] := (_TRBITEM)->(&(_cCampoMes))

		Next _nSeqMes

		// controle de item deletado
		_aRet[_nTmpLin][Len(_aHeadItem)+1] := .f.

		// proximo item
		(_TRBITEM)->(dbSkip())
	EndDo

Return(_aRet)

// ** funcao que valida o item contabil digitado
User Function COMC002A
	// variavel de retorno
	local _lRet := .t.
Return(_lRet)

// ** funcao para retornar o ANO base para filtro das informacoes
Static Function sfRetAnoBase()
	// variavel temporaria
	local _cAnoDisp := SuperGetMv("TC_CADALC",.f.,"2013/2014/2015/2016")
	// variavel de retorno
	local _aRet := Separa(_cAnoDisp, "/", .f.)
Return(_aRet)

// ** funcao para validacao total dos itens contabeis e atualizacao do TRB
Static Function sfVldDefIte(mvObjTela, mvBrwItemCont, mvCodCenCus)
	// variavel de retorno
	local _lRet := .t.

	// variaveis temporarias
	local _nLinBrw
	local _aTmpDados := aClone(mvBrwItemCont:aCols)
	local _cTmpItem
	local _nSeqMes := 1
	local _cCampoMes

	// posicao dos campos
	local _nPosItem   := aScan(_aHeadItem, {|x| AllTrim(x[2]) == "CTD_ITEM"})
	local _nPosMes
	local _nPosDelete := Len(_aHeadItem)+1

	// varre todas as linhas do browse para verificar se o valor nao eh maior que o do superior
	For _nLinBrw := 1 to Len(_aTmpDados)

		// item contabil
		_cTmpItem := _aTmpDados[_nLinBrw][_nPosItem]

		// se nao estiver deletado
		If ( ! _aTmpDados[_nLinBrw][_nPosDelete])

			// valida item em branco
			If (Empty(_cTmpItem))
				MsgStop("Item contábil não pode ser vazio!")
				Return(.f.)
			EndIf

			// valida se o item existe
			_cTmpItem := Posicione("CTD",1, xFilial("CTD")+_cTmpItem , "CTD_ITEM" )

			// valida item em branco
			If (Empty(_cTmpItem))
				MsgStop("Item contábil não encontrado!")
				Return(.f.)
			EndIf

			// funcao que valida o valor do item contabil digitado
			If ( ! U_COMC002C(mvCodCenCus, _cTmpItem, _aTmpDados, _nLinBrw, _cIdSuperi, .t.))
				Return(.f.)
			EndIf

			// valida a hierarquia completa do cadastro
			If ( ! sfVldHierarquia(mvCodCenCus, _cTmpItem) )
				Return(.f.)
			EndIf

		EndIf

	Next _nLinBrw

	// varre todas as linhas do browse
	For _nLinBrw := 1 to Len(_aTmpDados)

		// item contabil
		_cTmpItem := _aTmpDados[_nLinBrw][_nPosItem]

		// abre arquivo de trabalho
		(_TRBITEM)->(dbSelectArea(_TRBITEM))
		(_TRBITEM)->(dbSetOrder(1)) // 1-IT_CC, IT_ITEM

		// pesquisa no TRB
		If ! (_TRBITEM)->(dbSeek( mvCodCenCus+_cTmpItem ))
			// inclui novo registro no TRB
			(_TRBITEM)->(RecLock(_TRBITEM,.t.))
			(_TRBITEM)->IT_CC   := mvCodCenCus
			(_TRBITEM)->IT_ITEM := _cTmpItem
			(_TRBITEM)->(MsUnLock())
		Else
			// verifica se o item esta deletado
			If (_aTmpDados[_nLinBrw][_nPosDelete])
				// marca o TRB para deletar
				(_TRBITEM)->(RecLock(_TRBITEM))
				(_TRBITEM)->IT_DELITEM := "S"
				(_TRBITEM)->(MsUnLock())
				Loop
			EndIf
		EndIf

		// varre todos os meses do browse
		For _nSeqMes := 1 to 12

			// define o campo MES
			_cCampoMes := "IT_LIM"+StrZero(_nSeqMes,2)

			// posicao do campo no browse
			_nPosMes := aScan(_aHeadItem, {|x| AllTrim(x[2]) == _cCampoMes})

			// atualiza valor do mes
			(_TRBITEM)->(RecLock(_TRBITEM,.f.))
			(_TRBITEM)->(&(_cCampoMes)) := _aTmpDados[_nLinBrw][_nPosMes]
			(_TRBITEM)->(MsUnLock())

		Next _nSeqMes

	Next _nLinBrw

	// validao ok, fecha a tela
	If (_lRet)
		mvObjTela:End()
	EndIf

Return(_lRet)


// ** funcao que valida o codigo do item contabil
Static Function sfVldItCtb(mvCodItCtb,mvDscItCtb,mvSay03DsCon)
	// variavel de retorno
	local _lRet := .t.

	// verifica conteudo
	If (Empty(mvCodItCtb))
		Return(_lRet)
	EndIf

	// pesquisa o codigo do item contabil
	mvDscItCtb := Posicione("CTD",1, xFilial("CTD")+mvCodItCtb ,"CTD_DESC01" )
	// refresh
	mvSay03DsCon:SetText(mvDscItCtb)
	mvSay03DsCon:CtrlRefresh()

	// atualiza retorno
	_lRet := ( ! Empty(mvDscItCtb) )

Return(_lRet)

// ** funcao para replicar o valor nos demais meses
Static Function sfAddValor( mvCodItCtb, mvVlrRepli, mvBrwItemCont, mvColsItem )
	// controle de confirmacao
	local _lOk := .f.
	// objetos da tela
	local _oWnd04AddValor
	local _oList04Meses
	// variaveis temporarias
	local _nSeqMes
	local _cDscMes
	// itens do list box
	local _aMeses := {}
	local _nMeses := 0
	local _aTmpMeses := {}
	// verifica se o Item Contabil ja existe
	local _nLinhaIt := aScan(mvBrwItemCont:aCols, {|x| (x[1] == mvCodItCtb) })
	// variaveis temporarias
	local _bAddArray

	// coloca conteudo em private, pois Macro (&) não funciona em local
	private _aIxbItemCtb := aClone(mvBrwItemCont:aCols)

	// varre todos os meses
	For _nSeqMes := 1 to 12

		// prepara os dados do mes
		_cDscMes := "[X] - "+MesExtenso(_nSeqMes)+"/"+_cAnoBase
		// adiciona o item
		aAdd(_aMeses,_cDscMes)

	Next _nSeqMes

	// valida informacoes
	If (Empty(mvCodItCtb)).or.(mvVlrRepli <= 0)
		MsgStop("Dados inválidos. Favor verificar!")
		Return(.f.)
	EndIf

	// monta o dialogo do monitor
	_oWnd04AddValor := MSDialog():New(000,000,300,400,"Selecione os Meses",,,.F.,,,,,,.T.,,,.T. )

	// meses disponiveis
	_oList04Meses := TListBox():New(000,000,{|u|if(Pcount()>0,_nMeses:=u,_nMeses)},_aMeses,400,400,,_oWnd04AddValor,,,,.T.,,{|| sfSelListBox(@_oList04Meses) })
	_oList04Meses:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oWnd04AddValor CENTERED ON INIT EnchoiceBar(_oWnd04AddValor,{|| _aTmpMeses := aClone(_oList04Meses:aItems), _lOk := .t., _oWnd04AddValor:End() } , {|| _oWnd04AddValor:End() })

	// se foi confirmado
	If (_lOk)

		// adiciona o valor no browse
		If (_nLinhaIt == 0)
			// inicia sintaxe Advpl
			_bAddArray := "aAdd(_aIxbItemCtb,{"
			// codigo
			_bAddArray += "'"+mvCodItCtb+"', "
			// descricao
			_bAddArray += "'"+Posicione("CTD",1, xFilial("CTD")+mvCodItCtb ,"CTD_DESC01")+"' "
		EndIf

		// varre todos os itens disponiveis
		For _nSeqMes := 1 to Len(_aTmpMeses)
			// verifica se esta selecionado
			If (SubStr(_aTmpMeses[_nSeqMes],1,3) == "[X]")
				// novo registro
				If (_nLinhaIt == 0)
					_bAddArray += ", "+Str(mvVlrRepli,TamSx3("Z27_LIMITE")[1],TamSx3("Z27_LIMITE")[2])
				Else
					_aIxbItemCtb[_nLinhaIt][_nSeqMes+2] := mvVlrRepli
				EndIf
			Else
				// novo registro
				If (_nLinhaIt == 0)
					_bAddArray += ", 0"
				EndIf
			EndIf
		Next _nSeqMes

		// finaliza sintaxe Advpl
		If (_nLinhaIt == 0)
			// cria nova linha no browse
			_bAddArray += ", .f. })
			// executa comando
			(&(_bAddArray))
		EndIf

		// atualiza browse
		mvBrwItemCont:aCols := aClone(_aIxbItemCtb)
		mvColsItem := aClone(_aIxbItemCtb)

	EndIf

Return

// ** funcao para modificar/selecionar o item
Static Function sfSelListBox(mvList04Meses)
	// retorna os itens do objeto
	local _aItensLista := mvList04Meses:aItems
	// retorna o conteudo da linha atual
	local _cItemSelec := _aItensLista[mvList04Meses:nAt]
	// opcao do item atual
	local _cOpcAtu := Left(_cItemSelec,3)
	// nova condicao
	local _cOpcNew := If(_cOpcAtu=="[ ]","[X]","[ ]")

	// altera opcao
	If (mvList04Meses:nAt > 0)
		mvList04Meses:Modify(_cOpcNew + SubStr(_cItemSelec,4),mvList04Meses:nAt)
	EndIf

Return

// ** funcao para validar/confirmar exclusao de itens
Static Function sfVldExclusao(mvTipoOpe, mvCodCargo)
	// variavel de retorno
	local _lRet := .t.
	// codigo do setor selecionado
	local _aTmpCargo := Separa(mvCodCargo,";")
	local _cTmpTipo := _aTmpCargo[1]
	local _cCodPflSelec := _aTmpCargo[2]
	// variaveis temporarias
	local _cQuery
	local _aTmpItens := {}
	local _nTmpItens := 0
	local _cSeekZ27

	// codigo do usuario aprovador
	local _cCodIdGeren := ""

	// valida edicao em centros de custo
	If (_lRet)
		If (_cTmpTipo == "C")
			Aviso("Centro de Custo","Não é permitido Excluir dados do Centro de Custo",{"OK"})
			Return(.f.)
		EndIf
	EndIf

	// posiciona no registro da tabela
	DBSelectArea("Z26")
	Z26->(dbSetOrder(1)) // 1-Z26_FILIAL, Z26_CALEND, Z26_PERFID
	If ! Z26->(dbSeek( xFilial("Z26")+_cAnoBase+_cCodPflSelec ))
		MsgStop("Erro Seek SZ6 ## 2")
		_lRet := .f.
	EndIf

	// atualiza codigo do ID do gerente
	_cCodIdGeren := Z26->Z26_CODUSU

	// valida ID superior
	If (_lRet)
		// monta query para verificar se possuir gerencias relaciondas
		_cQuery := "SELECT COUNT(*) AS IT_CAMPO "
		// cad. gerencia
		_cQuery += "FROM "+RetSQLName("Z26")+" Z26 "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("Z26")
		// ano base
		_cQuery += "AND Z26_CALEND = '"+_cAnoBase+"' "
		// código superior
		_cQuery += "AND Z26_PERSUP = '"+_cCodPflSelec+"' "

		// executa query
		If (U_FtQuery(_cQuery) > 0)
			Aviso("Exclusão","Esta Gerência não pode ser excluída porque existem gerências relacionadas.",{"OK"})
			_lRet := .f.
		EndIf
	EndIf

	// valida se ha pendencias por centro de custo / item contabil
	If (_lRet)

		// monta query para buscar os centro de custos
		_cQuery := "SELECT DISTINCT Z27_CC "
		// itens da alcada por gerencia
		_cQuery += "FROM "+RetSQLName("Z27")+" Z27 "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("Z27")
		// codigo do perfil
		_cQuery += "AND Z27_PERFIL = '"+_cCodPflSelec+"' "
		// ano base
		_cQuery += "AND Z27_CALEND = '"+_cAnoBase+"' "

		// atualiza variavel temporaria
		_aTmpItens := U_SqlToVet(_cQuery)

		// valida se ha pendencias de Pedidos por Centro de custo
		For _nTmpItens := 1 to Len(_aTmpItens)

			// funcao que pesquisa pedidos por CC
			If ( ! U_COMC002B(_cCodIdGeren, _aTmpItens[_nTmpItens], Nil, Nil) )
				_lRet := .f.
				Exit
			EndIf

		Next _nTmpItens
	EndIf

	// se validou, solicita confirmacao
	If (_lRet)

		// solicita confirmacao da exclusao do perfil
		If (_lRet := MsgYesNo("Confirma a exclusão do perfil "+AllTrim(_cCodPflSelec)+" contendo "+AllTrim(Str(Len(_aTmpItens)))+" Centro(s) de Custo?","TCOMC002 -> sfVldExclusao"))

			// posiciona no registro da tabela
			DBSelectArea("Z26")
			Z26->(dbSetOrder(1)) // 1-Z26_FILIAL, Z26_CALEND, Z26_PERFID
			If ! Z26->(dbSeek( xFilial("Z26")+_cAnoBase+_cCodPflSelec ))
				MsgStop("Erro Seek SZ6 ## 2")
				_lRet := .f.
			EndIf

			// pesquisa alcada x perfil x mes
			dbSelectArea("Z27")
			Z27->(dbSetOrder(3)) // 3-Z27_FILIAL, Z27_CALEND, Z27_PERFIL, Z27_CC, Z27_ITEMC, Z27_DATAIN, Z27_DATAFM
			Z27->(DBSeek( _cSeekZ27 := xFilial("Z27")+_cAnoBase+_cCodPflSelec ))

			// INICIA TRANSACAO
			BEGIN TRANSACTION

				// varre todos os itens do perfil selecionado
				While Z27->(!Eof()).and.(Z27->(Z27_FILIAL+Z27_CALEND+Z27_PERFIL) == _cSeekZ27)

					// exclui o item posicionado
					RecLock("Z27")
					Z27->(DBDelete())
					MsUnLock("Z27")

					// proximo item
					Z27->(dbSkip())
				EndDo

				// gera log
				U_FtGeraLog(cFilAnt, "Z26", Z26->( Z26_FILIAL+Z26_PERFID ), "Gerência Excluida Manualmente ("+AllTrim(Z26->Z26_SETOR)+")", "COM")

				// exclui o cadastro do perfil
				RecLock("Z26",.F.)
				Z26->(DBDelete())
				MsUnLock("Z26")

				// FINALIZA TRANSACAO
			END TRANSACTION

		EndIf
	EndIf

	// atualiza dados
	If (_lRet)
		sfAtuTree()
	EndIf

Return(_lRet)

// ** funcao para validar exclusao de itens
User Function COMC002B(mvCdUsrGer, mvCodCC, mvCodItem, mvIdSetor)
	// variavel de retorno
	local _lRet := .t.
	// variaveis temporarias
	local _cQuery
	local _aTmpPedidos := {}
	local _cTmpPedidos := ""
	local _aTmpAlcDepe := {}
	local _cTmpAlcDepe := ""


	// valor padrao
	Default mvCdUsrGer := CriaVar("C7_ZUSRSC" ,.f.)
	Default mvCodCC    := CriaVar("CTT_CUSTO" ,.f.)
	Default mvCodItem  := CriaVar("CTD_ITEM"  ,.f.)
	Default mvIdSetor  := CriaVar("Z26_PERFID",.f.)

	// monta query para buscar pedidos de compras conforme CC e Item
	_cQuery := "SELECT C7_NUM "
	// pedidos
	_cQuery += "FROM "+RetSqlName("SC7")+" SC7 "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SC7")
	// data de emissao / necessidade
	_cQuery += "AND ( C7_DATPRF >= '"+_cAnoBase+"0101' OR C7_EMISSAO >= '"+_cAnoBase+"0101' ) "
	// centro de custo
	If ( ! Empty(mvCodCC))
		_cQuery += "AND C7_CC = '"+mvCodCC+"' "
	EndIf
	// item contabil
	If ( ! Empty(mvCodItem))
		_cQuery += "AND C7_ITEMCTA = '"+mvCodItem+"' "
	EndIf
	// codigo do gerente/solicitante
	If ( ! Empty(mvCdUsrGer))
		_cQuery += "AND C7_ZUSRSC = '"+mvCdUsrGer+"' "
	EndIf
	// ordem de dados
	_cQuery += "ORDER BY C7_NUM "

	// atualiza vetor
	_aTmpPedidos := U_SqlToVet(_cQuery)

	// caso tenha pedidos
	If (Len(_aTmpPedidos) > 0)

		// variavel de retorno
		_lRet := .f.

		// solicita detalhamento
		If MsgYesNo("Não é permitido excluir perfil com movimentações relacionadas à Centro de Custo e/ou Item Contábil."+CRLF+"Deseja visualizar a relação de pedidos?","TCOMC002 -> COMC002B - Validação")

			// atualiza relação de pedidos de compras
			aEval(_aTmpPedidos,{|_cPed| _cTmpPedidos += (_cPed + CRLF) })

			// apresenta mensagen
			HS_MsgInf("ATENÇÃO: Relação de Pedidos de Compras:"+CRLF+;
				AllTrim(Str(Len(_aTmpPedidos)))+" Pedido(s):"+CRLF+CRLF+_cTmpPedidos ,;
				"Relação de Pedidos de Compras",;
				"Relação de Pedidos de Compras" )

		EndIf

	EndIf

	// valida se ha alcadas abaixo com dependencia
	If ( ! Empty(mvIdSetor))
		// monta query para buscar pedidos de compras conforme CC e Item
		_cQuery := " SELECT DISTINCT Z26_PERFID+'-'+RTRIM(LTRIM(Z26_GERENT))+ '('+RTRIM(LTRIM(Z26_SETOR))+')' IT_CAMPO "
		// cadastro de alcadas
		_cQuery += " FROM "+RetSqlTab("Z26")
		// itens da alcada
		_cQuery += " INNER JOIN "+RetSqlTab("Z27")+" ON "+RetSqlCond("Z27")+" AND Z27_CALEND = Z26_CALEND AND Z27_PERFIL = Z26_PERFID "
		// centro de custo
		If ( ! Empty(mvCodCC) )
			_cQuery += " AND Z27_CC = '"+mvCodCC+"' "
		EndIf
		// item contabil
		If ( ! Empty(mvCodItem))
			_cQuery += " AND Z27_ITEMC = '"+mvCodItem+"' "
		EndIf
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("Z26")
		// calendario
		_cQuery += " AND Z26_CALEND = '"+_cAnoBase+"' "
		// perfil superior
		_cQuery += " AND Z26_PERSUP = '"+mvIdSetor+"' "

		// atualiza vetor
		_aTmpAlcDepe := U_SqlToVet(_cQuery)

		// caso tenha pedidos
		If (Len(_aTmpAlcDepe) > 0)

			// variavel de retorno
			_lRet := .f.

			// solicita detalhamento
			If MsgYesNo("Não é permitido excluir este cadastro, pois há setores relacionados à este perfil."+CRLF+"Deseja visualizar detalhes?","TCOMC002 -> COMC002B - Validação")

				// atualiza relação de setores relacionados
				aEval(_aTmpAlcDepe,{|_cDetPerfil| _cTmpAlcDepe += (_cDetPerfil + CRLF) })

				// apresenta mensagen
				HS_MsgInf("ATENÇÃO: Setores relacionados:"+CRLF+;
					_cTmpAlcDepe ,;
					"Setores relacionados",;
					"Setores relacionados" )

			EndIf

		EndIf
	EndIf

Return(_lRet)

// ** funcao que valida o item contabil digitado
User Function COMC002C(mvCodCC, mvCodItem, mvColsCC, mvLinhaBrw, mvIdSuperi, mvVldGrid)
	// variavel de retorno
	local _lRet := .t.
	// variaveis de controle
	local _nSeqMes := 1
	local _cCampoMes
	local _dDtReferen
	local _cQryZ27
	// valor informado
	local _nVlrAlcada := 0
	// valor alcada do superior
	local _nVlrAlcSup := 0

	// nao valida para usuario sem superior
	If (Empty(mvIdSuperi))
		Return(_lRet)
	EndIf

	// executa validacao se existe amarracao contabil
	_lRet := U_FtCtbConta(mvCodCC, mvCodItem, .t.)

	// varre todos os meses do browse
	For _nSeqMes := 1 to 12

		// define data de referencia
		_dDtReferen := CtoD( "01/" + StrZero(_nSeqMes,2)+"/"+_cAnoBase )

		// validacao do tipo GRID
		If (mvVldGrid)
			// define o campo MES
			_cCampoMes := "IT_LIM"+StrZero(_nSeqMes,2)

			// posicao do campo no browse
			_nPosMes := aScan(_aHeadItem, {|x| AllTrim(x[2]) == _cCampoMes})

			// atualiza valor do mes
			_nVlrAlcada := mvColsCC[mvLinhaBrw][_nPosMes]

			// validacao de variavel vetor 2 colunas (1a Data Referencia / 2a Valor)
		ElseIf ( ! mvVldGrid )
			// posicao do valor no browse
			_nPosMes := aScan(mvColsCC, {|x| x[1] == _dDtReferen})

			// atualiza valor do mes
			_nVlrAlcada := mvColsCC[_nPosMes][2]

		EndIf

		// monta quer para verificar os centros de custo existentes no perfil
		_cQryZ27 := "SELECT Z27_LIMITE "
		// centro de custo e itens do perfil
		_cQryZ27 += "FROM "+RetSqlName("Z27")+" Z27 "
		// filtro padrao
		_cQryZ27 += "WHERE "+RetSqlCond("Z27")
		// filtro por perfil
		_cQryZ27 += "AND Z27_PERFIL = '"+mvIdSuperi+"' "
		// centro de custo
		_cQryZ27 += "AND Z27_CC     = '"+mvCodCC+"' "
		// item contabil
		_cQryZ27 += "AND Z27_ITEMC  = '"+mvCodItem+"' "
		// ano base
		_cQryZ27 += "AND Z27_CALEND = '"+_cAnoBase+"' "
		// filtro do mes
		_cQryZ27 += "AND '"+DtoS(_dDtReferen)+"' BETWEEN Z27_DATAIN AND Z27_DATAFM "

		// alimenta valor alcada do superior
		_nVlrAlcSup := U_FtQuery(_cQryZ27)

		// valida valor informado / tem que ser menor
		If (_nVlrAlcada > _nVlrAlcSup)

			// apresenta mensagen
			HS_MsgInf("ATENÇÃO: Alçada x Superior"+CRLF+CRLF+;
				"O valor informado não pode exceder ao valor da gerência superior"+CRLF+;
				"Centro de Custo: "+mvCodCC+CRLF+;
				"It.Contábil: "+mvCodItem+CRLF+;
				"Mês: "+AllTrim(MesExtenso(_nSeqMes))+CRLF+;
				"Vlr.Informado: R$ "+AllTrim( Transf(_nVlrAlcada,PesqPict("Z27","Z27_LIMITE")))+CRLF+;
				"Vlr.Alçada Superior: R$ "+AllTrim( Transf(_nVlrAlcSup,PesqPict("Z27","Z27_LIMITE")) ) ,;
				"Alçada x Superior",;
				"Alçada x Superior" )

			// retorno
			_lRet := .f.
		EndIf

	Next _nSeqMes

Return(_lRet)


// ** funcao para replicar os itens contabeis conforme ID superior
Static Function sfRepNivSup(mvCodCC, mvBrwItemCont, mvColsItem)
	// grupo de perguntas
	local _aPerg := {}
	local _cPerg := PadR("TCOMC002",10)
	// query
	local _cQryZ27
	// variaveis temporarias
	local _aTmpItCont  := {}
	local _nTmpItCont  := 0
	local _cTmpCodItem := ""
	// verifica se o Item Contabil ja existe
	local _nLinhaIt
	// data de referencia
	local _dDtReferen
	// valor alcada superior
	local _nVlrAlcSup := 0
	// valor alcada calculada
	local _nVlrAlcada := 0
	// posicao do campo delete
	local _nPosDelete := Len(_aHeadItem)+1

	// coloca conteudo em private, pois Macro (&) não funciona em local
	private _aIxbItemCtb := aClone(mvBrwItemCont:aCols)

	// monta a lista de perguntas
	aAdd(_aPerg,{"Percentual?" ,"N",6,2,"G",,""}) // mv_par01

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// nao valida para usuario sem superior
	If (Empty(_cIdSuperi))
		Aviso("Replicar","Neste perfil não há nível superior.",{"OK"})
		Return(.f.)
	EndIf

	// abre os parametros
	If ! Pergunte(_cPerg,.T.)
		Return(.f.)
	endif

	// monta quer para verificar itens contabeis do ID superior
	_cQryZ27 := "SELECT DISTINCT Z27_ITEMC "
	// centro de custo e itens do perfil
	_cQryZ27 += "FROM "+RetSqlName("Z27")+" Z27 "
	// filtro padrao
	_cQryZ27 += "WHERE "+RetSqlCond("Z27")
	// filtro por perfil
	_cQryZ27 += "AND Z27_PERFIL = '"+_cIdSuperi+"' "
	// centro de custo
	_cQryZ27 += "AND Z27_CC     = '"+mvCodCC+"' "
	// ano base
	_cQryZ27 += "AND Z27_CALEND = '"+_cAnoBase+"' "

	// atualiza a relacao de itens contabeis do superior
	_aTmpItCont := U_SqlToVet(_cQryZ27)

	// varre todos os itens contabeis do ID Superior
	For _nTmpItCont := 1 to Len(_aTmpItCont)

		// atualiza codigo do item contabil
		_cTmpCodItem := _aTmpItCont[_nTmpItCont]

		// verifica se o Item Contabil ja existe
		_nLinhaIt := aScan(mvBrwItemCont:aCols, {|x| (x[1] == _cTmpCodItem) })

		// adiciona o valor no browse
		If (_nLinhaIt == 0)
			// inicia sintaxe Advpl
			_bAddArray := "aAdd(_aIxbItemCtb,{"
			// codigo
			_bAddArray += "'"+_cTmpCodItem+"', "
			// descricao
			_bAddArray += "'"+Posicione("CTD",1, xFilial("CTD")+_cTmpCodItem ,"CTD_DESC01")+"' "
		EndIf

		// varre todos os itens disponiveis
		For _nSeqMes := 1 to 12

			// define data de referencia
			_dDtReferen := CtoD( "01/" + StrZero(_nSeqMes,2)+"/"+_cAnoBase )

			// monta quer para buscar o valor do item contabil conforme mes atual
			_cQryZ27 := "SELECT Z27_LIMITE "
			// centro de custo e itens do perfil
			_cQryZ27 += "FROM "+RetSqlName("Z27")+" Z27 "
			// filtro padrao
			_cQryZ27 += "WHERE "+RetSqlCond("Z27")
			// filtro por perfil
			_cQryZ27 += "AND Z27_PERFIL = '"+_cIdSuperi+"' "
			// centro de custo
			_cQryZ27 += "AND Z27_CC     = '"+mvCodCC+"' "
			// item contabil
			_cQryZ27 += "AND Z27_ITEMC  = '"+_cTmpCodItem+"' "
			// ano base
			_cQryZ27 += "AND Z27_CALEND = '"+_cAnoBase+"' "
			// filtro do mes
			_cQryZ27 += "AND '"+DtoS(_dDtReferen)+"' BETWEEN Z27_DATAIN AND Z27_DATAFM "

			// valor alcada superior
			_nVlrAlcSup := U_FtQuery(_cQryZ27)

			// valor alcada calculada
			If (_nVlrAlcSup > 0)
				_nVlrAlcada := (_nVlrAlcSup * mv_par01) / 100
			Else
				_nVlrAlcada := 0
			EndIf

			// novo registro
			If (_nLinhaIt == 0)
				_bAddArray += ", "+Str(_nVlrAlcada,TamSx3("Z27_LIMITE")[1],TamSx3("Z27_LIMITE")[2])
			Else
				_aIxbItemCtb[_nLinhaIt][_nSeqMes+2]  := _nVlrAlcada
				_aIxbItemCtb[_nLinhaIt][_nPosDelete] := .f.
			EndIf
		Next _nSeqMes

		// finaliza sintaxe Advpl
		If (_nLinhaIt == 0)
			// cria nova linha no browse
			_bAddArray += ", .f. })
			// executa comando
			(&(_bAddArray))
		EndIf

	Next _nTmpItCont

	// atualiza browse
	mvBrwItemCont:aCols := aClone(_aIxbItemCtb)
	mvColsItem := aClone(_aIxbItemCtb)

Return

// ** funcao que valida toda a hierarqui do cadastro
Static Function sfVldHierarquia(mvCodCC, mvCodItem)
	// variavel de retorno
	local _lRet := .t.

	// variaveis de controle
	local _nSeqMes := 1
	local _cCampoMes
	local _dDtReferen
	local _cQryZ27

	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"Z26"})

	// codigo temporario do Perfil Superior
	local _cTmpCdPerfil := _cIdSuperi

	// mensagem de Log
	local _cLogAlcada := ""
	local _cLogPerfil := ""

	// setor
	local _cTmpDscPerfil := ""

	// gerente
	local _cTmpGerente := ""

	// nao valida para usuario sem superior
	If (Empty(_cTmpCdPerfil))
		Return(_lRet)
	EndIf

	// Loop até encontrar perfil sem superior
	While ( .t. )

		// verifica a necessidade de pesquisar o setor
		If (_cTmpCdPerfil <> Z26->Z26_PERFID)
			// posiciona no cadastro do setor
			dbSelectArea("Z26")
			Z26->(dbSetOrder(1)) // 1-Z26_FILIAL, Z26_CALEND, Z26_PERFID
			Z26->(dbSeek( xFilial("Z26")+_cAnoBase+_cTmpCdPerfil ))

			// descricao do setor
			_cTmpDscPerfil := AllTrim(Z26->Z26_SETOR)

			// gerente
			_cTmpGerente := AllTrim(Z26->Z26_GERENT)
		EndIf

		// zera variavel
		_cLogPerfil := ""

		// varre todos os meses do browse
		For _nSeqMes := 1 to 12

			// define data de referencia
			_dDtReferen := CtoD( "01/" + StrZero(_nSeqMes,2)+"/"+_cAnoBase )

			// define o campo MES
			_cCampoMes := "IT_LIM"+StrZero(_nSeqMes,2)

			// posicao do campo no browse
			_nPosMes := aScan(_aHeadItem, {|x| AllTrim(x[2]) == _cCampoMes})

			// monta quer para verificar os centros de custo existentes no perfil
			_cQryZ27 := "SELECT COUNT(*) QTD_ALCADA "
			// centro de custo e itens do perfil
			_cQryZ27 += "FROM "+RetSqlName("Z27")+" Z27 "
			// filtro padrao
			_cQryZ27 += "WHERE "+RetSqlCond("Z27")
			// filtro por perfil
			_cQryZ27 += "AND Z27_PERFIL = '"+_cTmpCdPerfil+"' "
			// centro de custo
			_cQryZ27 += "AND Z27_CC     = '"+mvCodCC+"' "
			// item contabil
			_cQryZ27 += "AND Z27_ITEMC  = '"+mvCodItem+"' "
			// ano base
			_cQryZ27 += "AND Z27_CALEND = '"+_cAnoBase+"' "
			// filtro do mes
			_cQryZ27 += "AND '"+DtoS(_dDtReferen)+"' BETWEEN Z27_DATAIN AND Z27_DATAFM "

			// alimenta valor alcada do superior
			If (U_FtQuery(_cQryZ27) == 0)

				// variavel de retorno
				_lRet := .f.

				// atualiza Log de Erro no Cadastro de Alcada
				If (Empty(_cLogPerfil))
					_cLogPerfil := CRLF
					_cLogPerfil += "ERRO -->> Setor: "+_cTmpDscPerfil+" / Resp.: "+_cTmpGerente + CRLF
					_cLogPerfil += "CC: "+mvCodCC+" / Item: "+mvCodItem + CRLF
					_cLogPerfil += "Meses: "
				EndIf

				// adiciona meses
				_cLogPerfil += AllTrim(MesExtenso(_nSeqMes)) + ", "

			EndIf

		Next _nSeqMes

		// log por por setor
		If ( Empty(_cLogPerfil) )
			_cLogPerfil := "OK -->> Setor: "+_cTmpDscPerfil+" / Resp.: "+_cTmpGerente + CRLF
		EndIf

		// atualiza log do setor no Log Geral
		_cLogAlcada += _cLogPerfil

		// define novo perfil superior
		_cTmpCdPerfil := Posicione("Z26",1, xFilial("Z26")+_cAnoBase+_cTmpCdPerfil ,"Z26_PERSUP")

		// se nao haver mais Perfil Superior, finaliza validacao
		If (Empty(_cTmpCdPerfil))
			Exit
		EndIf

	EndDo

	// mensagem de erro de cadastro
	If ( ! _lRet)

		// apresenta mensagen
		HS_MsgInf("ATENÇÃO: Alçada x Superior"+CRLF+CRLF+;
			"Erro no cadastro da Hierarquia"+CRLF+;
			_cLogAlcada ,;
			"Alçada x Superior",;
			"Alçada x Superior" )

	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni,.t.)
	RestArea(_aArea)

Return(_lRet)

// ** funcao para replicar itens contabeis do centro de custos para os niveis abaixo do posicionado
Static Function sfRepNivInf(mvCodCargo)
	// variavel de retorno
	local _lRet := .f.

	// codigo do setor selecionado
	local _aTmpCargo := Separa(mvCodCargo,";")
	local _cTmpTipo := _aTmpCargo[1]
	local _cCodPflSelec := _aTmpCargo[2]
	local _cCodCenCus := IIf(Len(_aTmpCargo) > 2 , _aTmpCargo[3], "")
	local _cDscCenCus := Posicione("CTT",1, xFilial("CTT")+_cCodCenCus ,"CTT_DESC01")

	// flag para replicar valores
	local _lRepValores := .f.

	// flag para controle de criacao do centro de custo quando nao existir
	local _lAddCenCus := .f.

	// flag para controle de criacao do item contabil quando nao existir
	local _lAddIteCtb := .f.

	// variaveis temporarias
	local _cQryZ27
	local _aCadAlcada := sfMntVetor()
	local _nCadAlcada

	// dados do perfil atual
	local _aDadosAtu := {}
	local _nDadosAtu := 0

	// itens contabeis
	local _aItemCont := {}
	local _nItemCont := 0

	// gerencias
	local _aGerencias := {}
	local _nGerencias := 0

	// objetos da tela
	local _oWnd05ItCont
	local _oList05Item, _oList05Geren
	local _oPnl05Cab1, _oPnl05Cab2, _oPnl05Cab3
	local _oPnl05Item, _oPnl05Geren
	local _oCmb05Valor, _oCmb05AddIt, _oCmb05AddCC
	local _oSay05CenCus, _oSay05Setor, _oSay05Resp

	// variaveis para o titulo
	local _cTitSetor
	local _cTitRespo

	// valida edicao em centros de custo
	If (_cTmpTipo <> "C").or.( Empty(_cCodCenCus) )
		Aviso("Centro de Custo","Opção disponível somente para Centro de Custo",{"OK"})
		Return(_lRet)
	EndIf

	// padroniza o tamanho do campo
	_cCodCenCus := PadR(_cCodCenCus,TamSx3("CTT_CUSTO")[1])

	// funcao que buscar no cadastro de alcadas todos os niveis abaixo do perfil selecionado
	For _nCadAlcada := 1 to Len(_aCadAlcada)

		// compara a base da estrutura do cadastro
		If ( _aCadAlcada[_nCadAlcada][6] == _cCodPflSelec)
			// inclui o perfil
			aAdd(_aGerencias,"[ ] "+_aCadAlcada[_nCadAlcada][2] +"-"+ AllTrim(_aCadAlcada[_nCadAlcada][3]) +" ("+AllTrim(_aCadAlcada[_nCadAlcada][4])+")")
		EndIf

	Next _nCadAlcada

	// valida se ha setores relacionados abaixo
	If (Len(_aGerencias) == 0)
		MsgAlert("Não há setores/usuários relacionados à este perfil")
		Return(_lRet)
	EndIf

	// busca todos os itens contabeis do centro de custo selecionado
	If (Len(_aCadAlcada) > 0).and.(Len(_aGerencias) > 0)
		// monta quer para buscar os itens contabeis do centro de custo
		_cQryZ27 := "SELECT DISTINCT '[ ] '+RTRIM(Z27_ITEMC)+' - '+RTRIM(CTD_DESC01) AS ITEM_CTB "
		// centro de custo e itens do perfil
		_cQryZ27 += "FROM "+RetSqlName("Z27")+" Z27 "
		// cad. item contabil
		_cQryZ27 += "INNER JOIN "+RetSqlName("CTD")+" CTD ON "+RetSqlCond("CTD")+" AND CTD_ITEM = Z27_ITEMC "
		// filtro padrao
		_cQryZ27 += "WHERE "+RetSqlCond("Z27")
		// filtro por perfil
		_cQryZ27 += "AND Z27_PERFIL = '"+_cCodPflSelec+"' "
		// centro de custo
		_cQryZ27 += "AND Z27_CC     = '"+_cCodCenCus+"' "
		// ano base
		_cQryZ27 += "AND Z27_CALEND = '"+_cAnoBase+"' "

		// atualiza a relacao de itens contabeis
		_aItemCont := U_SqlToVet(_cQryZ27)

		// posiciona no cadastro do perfil
		DbSelectArea("Z26")
		Z26->(dbSetOrder(1)) // 1-Z26_FILIAL, Z26_CALEND, Z26_PERFID
		Z26->(dbSeek( xFilial("Z26")+_cAnoBase+_cCodPflSelec ))

		// atualiza dados do titulo
		_cTitSetor := AllTrim(Z26->Z26_SETOR)
		_cTitRespo := AllTrim(Z26->Z26_GERENT)

		// monta o dialogo do monitor
		_oWnd05ItCont := MSDialog():New(000,000,600,600,"Itens Contábeis",,,.F.,,,,,,.T.,,,.T. )

		// panel do cabecalho - itens
		_oPnl05Cab1 := TPanel():New(000,000,,_oWnd05ItCont,_oFnt01,.F.,.F.,,,000,030	,.T.,.F.)
		_oPnl05Cab1:Align:= CONTROL_ALIGN_TOP

		// setor
		_oSay05Setor  := TSay():New(001,005,{||"Setor Origem: "+_cTitSetor},_oPnl05Cab1,,_oFnt01,.F.,.F.,.F.,.T.)
		// gerente
		_oSay05Resp   := TSay():New(011,005,{||"Responsável: "+_cTitRespo},_oPnl05Cab1,,_oFnt01,.F.,.F.,.F.,.T.)
		// centro de custo
		_oSay05CenCus := TSay():New(021,005,{||"Centro de Custo: "+AllTrim(_cCodCenCus)+" - "+_cDscCenCus },_oPnl05Cab1,,_oFnt01,.F.,.F.,.F.,.T.)

		// panel do cabecalho - itens
		_oPnl05Cab2 := TPanel():New(000,000,"Itens Contábeis",_oWnd05ItCont,,.T.,.F.,,,027,027,.T.,.F.)
		_oPnl05Cab2:Align:= CONTROL_ALIGN_TOP

		// flag para replicar os valores
		_oCmb05Valor := TCheckBox():New(003,005,"Replica Valores?",{|u| If(PCount()>0,_lRepValores:=u,_lRepValores)},_oPnl05Cab2,100,230,,,,,,,,.T.,"Se selecionado, atualiza os valores, se não ativado, cria registro com valor zerado.",,)

		// flag cadastrar o centro de custo quando nao existe
		_oCmb05AddCC := TCheckBox():New(010,005,"Incluir Centro de Custo quando Replicar?",{|u| If(PCount()>0,_lAddCenCus:=u,_lAddCenCus)},_oPnl05Cab2,120,230,,,,,,,,.T.,,,)

		// flag cadastrar o item contabil quando nao existe
		_oCmb05AddIt := TCheckBox():New(017,005,"Incluir Item Contábil quando Replicar?",{|u| If(PCount()>0,_lAddIteCtb:=u,_lAddIteCtb)},_oPnl05Cab2,120,230,,,,,,,,.T.,,,)

		// panel para os itens contabeis disponiveis
		_oPnl05Item := TPanel():New(000,000,nil,_oWnd05ItCont,,.F.,.F.,,,100,100,.T.,.F.)
		_oPnl05Item:Align:= CONTROL_ALIGN_TOP

		// panel do cabecalho - gerencias
		_oPnl05Cab3 := TPanel():New(000,000,"Replicar para as Gerências",_oWnd05ItCont,,.T.,.F.,,,16,16,.T.,.F.)
		_oPnl05Cab3:Align:= CONTROL_ALIGN_TOP

		// listas do itens contabeis disponiveis
		_oList05Item := TListBox():New(000,000,{|u|if(Pcount()>0,_nItemCont:=u,_nItemCont)},_aItemCont,700,700,,_oPnl05Item,,,,.T.,,{|| sfSelListBox(@_oList05Item) })
		_oList05Item:Align := CONTROL_ALIGN_ALLCLIENT

		// panel para as gerencias inferiores disponiveis
		_oPnl05Geren := TPanel():New(000,000,nil,_oWnd05ItCont,,.F.,.F.,,,100,100,.T.,.F.)
		_oPnl05Geren:Align:= CONTROL_ALIGN_ALLCLIENT

		// gerencias inferiores disponiveis
		_oList05Geren := TListBox():New(000,000,{|u|if(Pcount()>0,_nGerencias:=u,_nGerencias)},_aGerencias,700,700,,_oPnl05Geren,,,,.T.,,{|| sfSelListBox(@_oList05Geren) })
		_oList05Geren:Align := CONTROL_ALIGN_ALLCLIENT

		// ativa a tela
		ACTIVATE MSDIALOG _oWnd05ItCont CENTERED ON INIT EnchoiceBar(_oWnd05ItCont,{|| _aItemCont := aClone(_oList05Item:aItems), _aGerencias := aClone(_oList05Geren:aItems), _lRet := sfVldRepIt(_cCodPflSelec, _cCodCenCus, _aItemCont, _aGerencias, _lRepValores, _lAddCenCus, _lAddIteCtb, @_oWnd05ItCont ) } , {|| _oWnd05ItCont:End() })

	EndIf

Return(_lRet)

// ** funcao que valida e grava as informacoes de replicacao de item contabil
Static Function sfVldRepIt(mvCodPflSelec, mvCodCenCus, mvItemCont, mvGerencias, mvRepValores, mvAddCenCus, mvAddIteCtb, mvObjDlg)

	// variavel de retorno
	local _lRet := .f.

	// itens contabeis
	local _nSeqItem

	// gerencias
	local _nSeqGeren

	// variaveis para uso na replicacao de dados
	local _cTmpCdPerfil := ""
	local _cTmpDscSetor := ""
	local _cTmpItCont   := ""

	// perfil superior
	local _cCodPflSup

	// variveis temporarias
	local _aTmpDados := {}

	// controle de centro de custo ok
	local _lCenCusOk := .f.

	// valida quantidade de registros
	If (Len(mvItemCont) == 0).or.(Len(mvGerencias) == 0)
		// mensagem
		MsgInfo("Não há Itens Contábeis ou Setores para realizar a replicação de dados.")
		// retorno
		Return(_lRet)
	EndIf

	// mensagem de confirmacao
	If ! MsgYesNo("Replicar os valores dos Itens Contábeis selecionados deste centro de Custo:"+CRLF+mvCodCenCus+"-"+Posicione("CTT",1, xFilial("CTT")+mvCodCenCus ,"CTT_DESC01"))
		Return(_lRet)
	EndIf

	// pesquisa se as gerencias selecionadas ja possuem o centro de custo
	For _nSeqGeren := 1 to Len(mvGerencias)

		// verifica se esta selecionado
		If (SubStr(mvGerencias[_nSeqGeren],1,3) == "[X]")
			// define codigo da gerencia selecionado
			_cTmpCdPerfil := mvGerencias[_nSeqGeren]
			_cTmpCdPerfil := SubStr(_cTmpCdPerfil,5,Len(_cTmpCdPerfil))
			_cTmpCdPerfil := SubStr(_cTmpCdPerfil,1,At("-",_cTmpCdPerfil)-1)
			_cTmpCdPerfil := PadR(_cTmpCdPerfil,TamSx3("Z26_PERFID")[1])

			// descricao do setor
			_cTmpDscSetor := mvGerencias[_nSeqGeren]
			_cTmpDscSetor := AllTrim(SubStr(_cTmpDscSetor,At("-",_cTmpDscSetor)+1))

			// busca os dados do perfil e centro de custo selecionado para
			_cQryZ27 := " SELECT COUNT(*) QTD_REG_CC  "
			// centro de custo e itens do perfil
			_cQryZ27 += " FROM "+RetSqlTab("Z27")
			// filtro padrao
			_cQryZ27 += " WHERE "+RetSqlCond("Z27")
			// filtro por perfil
			_cQryZ27 += " AND Z27_PERFIL = '"+_cTmpCdPerfil+"' "
			// ano base
			_cQryZ27 += " AND Z27_CALEND = '"+_cAnoBase+"' "
			// centro de custo
			_cQryZ27 += " AND Z27_CC     = '"+mvCodCenCus+"' "

			// atualiza os dados do vetor
			If ( ! mvAddCenCus ).and.(U_FtQuery(_cQryZ27) == 0)
				// mensagem
				MsgAlert("Este centro de custo não está relacionado ao setor "+_cTmpDscSetor)
				// retorno
				Return(_lRet)
			EndIf

			// se estiver ok, atualiza controle
			_lCenCusOk := .t.

		EndIf

	Next _nSeqGeren


	// varre todos os itens disponiveis
	For _nSeqItem := 1 to Len(mvItemCont)
		// verifica se esta selecionado
		If (SubStr(mvItemCont[_nSeqItem],1,3) == "[X]")
			// define codigo do item contabil selecionado
			_cTmpItCont := mvItemCont[_nSeqItem]
			_cTmpItCont := SubStr(_cTmpItCont,5,Len(_cTmpItCont))
			_cTmpItCont := SubStr(_cTmpItCont,1,At("-",_cTmpItCont)-1)
			_cTmpItCont := PadR(_cTmpItCont,TamSx3("CTD_ITEM")[1])

			// pesquisa as gerencias seleciodas
			For _nSeqGeren := 1 to Len(mvGerencias)
				// verifica se esta selecionado
				If (SubStr(mvGerencias[_nSeqGeren],1,3) == "[X]")

					// zera variaveis
					_aTmpDados := {}

					// define codigo da gerencia selecionado
					_cTmpCdPerfil := mvGerencias[_nSeqGeren]
					_cTmpCdPerfil := SubStr(_cTmpCdPerfil,5,Len(_cTmpCdPerfil))
					_cTmpCdPerfil := SubStr(_cTmpCdPerfil,1,At("-",_cTmpCdPerfil)-1)
					_cTmpCdPerfil := PadR(_cTmpCdPerfil,TamSx3("Z26_PERFID")[1])

					// busca o codigo do perfil superior
					_cCodPflSup := Posicione("Z26",1, xFilial("Z26")+_cAnoBase+_cTmpCdPerfil ,"Z26_PERSUP")

					// busca os dados do perfil e centro de custo selecionado para
					_cQryZ27 := "SELECT Z27_CC, Z27_ITEMC, Z27_LIMITE, Z27_DATAIN, Z27_DATAFM, Z27_TIPO "
					// centro de custo e itens do perfil
					_cQryZ27 += "FROM "+RetSqlName("Z27")+" Z27 "
					// filtro padrao
					_cQryZ27 += "WHERE "+RetSqlCond("Z27")
					// filtro por perfil
					_cQryZ27 += "AND Z27_PERFIL = '"+mvCodPflSelec+"' "
					// ano base
					_cQryZ27 += "AND Z27_CALEND = '"+_cAnoBase+"' "
					// centro de custo
					_cQryZ27 += "AND Z27_CC     = '"+mvCodCenCus+"' "
					// centro de custo
					_cQryZ27 += "AND Z27_ITEMC  = '"+_cTmpItCont+"' "

					// atualiza os dados do vetor
					_aDadosAtu := U_SqlToVet(_cQryZ27,{"Z27_DATAIN","Z27_DATAFM"})

					// padroniza os dados para utilizar na validacao
					aEval(_aDadosAtu,{|X| aAdd(_aTmpDados,{x[4], x[3]}) })

					// valida se o superior tem alcada disponivel
					If ( ! U_COMC002C(mvCodCenCus, _cTmpItCont, _aTmpDados, Nil, _cCodPflSup, .f.) )
						MsgAlert("As informações NÃO foram replicadas. Favor verificar o cadastro do setor superior e realizar a operação novamente.")
						Return(_lRet)
					EndIf

					// inicia transacao
					BEGIN TRANSACTION

						// grava os valores para o novo perfil
						For _nDadosAtu := 1 to Len(_aDadosAtu)

							// verifica se os dados existem
							dbSelectArea("Z27")
							Z27->(dbSetOrder(3)) // 3-Z27_FILIAL, Z27_CALEND, Z27_PERFIL, Z27_CC, Z27_ITEMC, Z27_DATAIN, Z27_DATAFM
							If (Z27->(dbSeek( xFilial("Z27")+_cAnoBase+_cTmpCdPerfil+mvCodCenCus+_cTmpItCont+DtoS(_aDadosAtu[_nDadosAtu][4])+DtoS(_aDadosAtu[_nDadosAtu][5]) )))
								// verifica se replica valores
								If (mvRepValores)
									// atualiza dados
									RecLock("Z27")
									Z27->Z27_LIMITE := _aDadosAtu[_nDadosAtu][3]
									Z27->(MsUnLock())
									// atualizou dados
									_lRet := .t.
								EndIf

							Else

								// centro de custo Ok, e adiciona item contabil
								If (_lCenCusOk).and.(mvAddIteCtb)

									// inclui dados
									RecLock("Z27",.t.)
									Z27->Z27_FILIAL := xFilial("Z27")
									Z27->Z27_CALEND := _cAnoBase
									Z27->Z27_LIMPID := _cTmpCdPerfil
									Z27->Z27_PERFIL := _cTmpCdPerfil
									Z27->Z27_CC     := mvCodCenCus
									Z27->Z27_ITEMC  := _cTmpItCont
									Z27->Z27_LIMITE := IIf(mvRepValores, _aDadosAtu[_nDadosAtu][3], 0)
									Z27->Z27_DATAIN := _aDadosAtu[_nDadosAtu][4]
									Z27->Z27_DATAFM := _aDadosAtu[_nDadosAtu][5]
									Z27->(MsUnLock())

									// atualizou dados
									_lRet := .t.

								EndIf

							EndIf

						Next _nDadosAtu

						// finaliza transacao
					END TRANSACTION

				EndIf

			Next _nSeqGeren

		EndIf
	Next _nSeqItem

	// mensagem
	If (_lRet)
		MsgInfo("Dados Atualizados")
	ElseIf ( ! _lRet)
		MsgAlert("Dados Não Atualizados")
	EndIf

	// se dados atualizados, fecha tela
	If (_lRet)
		mvObjDlg:End()
	EndIf

Return(_lRet)

// ** funcao para ativar/desativar visualizacao de perfil bloqueado
Static Function sfMudaVis()
	// variavel de controle
	local _lRet := .f.

	// ativar
	If ( ! _lVisPrfBlq ).and.(MsgYesNo("Deseja Ativar Visualização de Perfil Bloqueado?"))
		_lVisPrfBlq := .t.
		_lRet       := .t.
	ElseIf ( _lVisPrfBlq ).and.(MsgYesNo("Deseja Desativar Visualização de Perfil Bloqueado?"))
		_lVisPrfBlq := .f.
		_lRet       := .t.
	EndIf

Return(_lRet)