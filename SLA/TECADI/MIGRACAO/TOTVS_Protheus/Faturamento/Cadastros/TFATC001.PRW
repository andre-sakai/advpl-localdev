#INCLUDE "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Cadastro de Programacao de Recebimento                  !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 09/2010 !
+------------------+--------------------------------------------------------*/

User Function TFATC001

	// objeto browse
	Local _oBrwProcesso := Nil

	// cabecalho
	dbSelectArea("SZ1")
	// itens
	dbSelectArea("SZ2")

	// variaveis internas de controle de validacao de campo
	Private _lInclui
	Private _lAltera

	// titulo
	Private _cCadastro := "Processos/Planejamento"

	Private aRotina := MenuDef()

	// cria objeto do browse
	_oBrwProcesso := FWMBrowse():New()
	_oBrwProcesso:SetAlias('SZ1')
	_oBrwProcesso:SetDescription(_cCadastro)

	// define cores do browse
	_oBrwProcesso:AddLegend('( Empty(Z1_DTFINFA)).and.( Empty(Z1_DTFECHA)).and.( Empty(Z1_DTABERT))',"ENABLE"    )
	_oBrwProcesso:AddLegend('( Empty(Z1_DTFINFA)).and.( Empty(Z1_DTFECHA)).and.(!Empty(Z1_DTABERT))',"BR_AMARELO")
	_oBrwProcesso:AddLegend('( Empty(Z1_DTFINFA)).and.(!Empty(Z1_DTFECHA)).and.(!Empty(Z1_DTABERT))',"BR_AZUL"   )
	_oBrwProcesso:AddLegend('(!Empty(Z1_DTFINFA)).and.(!Empty(Z1_DTABERT))'                         ,"DISABLE"   )

	// cria um filtro fixo para todos
	_oBrwProcesso:AddFilter("Disponíveis"    , "( Empty(Z1_DTFINFA))"                                                  , .f., .t., "SZ1", .f., {}, "ID_DISPONIVEIS")
	_oBrwProcesso:AddFilter("Aberta"         , "( Empty(Z1_DTFINFA)).and.( Empty(Z1_DTFECHA)).and.( Empty(Z1_DTABERT))", .f., .f., "SZ1", .f., {}, "ID_ABERTA"     )
	_oBrwProcesso:AddFilter("Iniciada"       , "( Empty(Z1_DTFINFA)).and.( Empty(Z1_DTFECHA)).and.(!Empty(Z1_DTABERT))", .f., .f., "SZ1", .f., {}, "ID_INICIADA"   )
	_oBrwProcesso:AddFilter("Encerrado WMS"  , "( Empty(Z1_DTFINFA)).and.(!Empty(Z1_DTFECHA)).and.(!Empty(Z1_DTABERT))", .f., .f., "SZ1", .f., {}, "ID_ENC_WMS"    )
	_oBrwProcesso:AddFilter("Encerrado Geral", "(!Empty(Z1_DTFINFA)).and.(!Empty(Z1_DTABERT))"                         , .f., .f., "SZ1", .f., {}, "ID_ENC_GERAL"  )

	// ativa objeto browse
	_oBrwProcesso:Activate()

Return

// ** funcao de Cadastro do Cabecalho e Itens
User Function FATC001B(mvOpcao)
	// dimensoes da tela
	Local _aSize := MsAdvSize()
	// tamanho utilizado para o modelo 3
	Local _aSizeMod3 := {_aSize[7],_aSize[1],_aSize[6],_aSize[5]}

	// controle da confirmacao da tela
	Local _lRet := .f.
	// posicao inicial do SX3
	Local _aAreaSx3 := SX3->(GetArea())
	// opcao selecionada
	Private _cOpcao
	// variavel com o Header
	Private aHeader := {}
	// variavel do aCols
	Private aCols := {}
	// define o valor da variavel padrao N
	Private N := 1
	// controle se permite a exclusao
	Private _lDelOk := .t.

	// controle sequencial do item
	private _cSeqItem

	// controle de variaveis da opcao selecionada
	Do Case
		Case mvOpcao==1; _cOpcao:="VISUALIZAR"; nOpcE:=2 ; nOpcG:=2 ; _lInclui := .f. ; _lAltera := .f.
		Case mvOpcao==2; _cOpcao:="INCLUIR";    nOpcE:=3 ; nOpcG:=3 ; _lInclui := .t. ; _lAltera := .f.
		Case mvOpcao==3; _cOpcao:="ALTERAR";    nOpcE:=3 ; nOpcG:=3 ; _lInclui := .f. ; _lAltera := .t.
		Case mvOpcao==4; _cOpcao:="EXCLUIR";    nOpcE:=2 ; nOpcG:=2 ; _lInclui := .f. ; _lAltera := .f.
	EndCase

	//Cria variaveis M->??? da Enchoice
	RegToMemory("SZ1",(_cOpcao=="INCLUIR"))

	// atualiza a filial
	If (_cOpcao=="INCLUIR")
		M->Z1_FILIAL := xFilial("SZ1")
	EndIf

	// valida exclusao quando ja houver nota
	If (_cOpcao=="EXCLUIR").and.( ! Empty(M->Z1_DTDOC) )
		MsgStop("Não é permitido a exclusão quando há relacionamento com nota fiscal!")
		Return(.f.)
	EndIf

	// valida se o processo ja esta encerrado
	If ((mvOpcao == 3).or.(mvOpcao == 4)).and.( ! Empty(M->Z1_DTFINFA) )
		MsgStop("Não é permitido alterar dados de processos encerrados. Contate o setor de Faturamento!")
		Return(.f.)
	EndIf

	// cria o aHeader
	aX3SZ2 := FWSX3Util():GetAllFields( "SZ2" )
	For nX := 1 to Len(aX3SZ2)
		
		lUsado	  := X3Uso(GetSX3Cache(aX3SZ2[Nx],"X3_USADO"))
		cX3Nivel  := GetSX3Cache(aX3SZ2[Nx],"X3_NIVEL")
		cX3Browse := GetSX3Cache(aX3SZ2[Nx],"X3_BROWSE")
		
		If lUsado .and. cNivel >= cX3Nivel .and. cX3Browse == 'S'
			Aadd(aHeader, {;
			TRIM(GetSX3Cache(aX3SZ2[Nx],"X3_TITULO")),;
			GetSX3Cache(aX3SZ2[Nx],"X3_CAMPO")		 ,;
			GetSX3Cache(aX3SZ2[Nx],"X3_PICTURE")	 ,;
			GetSX3Cache(aX3SZ2[Nx],"X3_TAMANHO")	 ,;
			GetSX3Cache(aX3SZ2[Nx],"X3_DECIMAL")	 ,;
			"U_FATC001C(.t.)"						 ,;
			GetSX3Cache(aX3SZ2[Nx],"X3_USADO")		 ,;
			GetSX3Cache(aX3SZ2[Nx],"X3_TIPO")		 ,;
			GetSX3Cache(aX3SZ2[Nx],"X3_ARQUIVO")	 ,;
			GetSX3Cache(aX3SZ2[Nx],"X3_CONTEXT")	 ,;
			})
		EndIf
		
	Next nX

	// restaura area inicial do X3
	RestArea(_aAreaSx3)

	// definicao e montagem do aCols
	aCols := sfRetItens()

	// controle se permite a exclusao
	If ( ! _lDelOk )
		MsgStop("Não é permitido a exclusão quando há itens com Saldo Recebido!")
		Return(.f.)
	EndIf

	// abre a tela de Cadastro
	_lRet := Modelo3(_cCadastro,"SZ1","SZ2",,"U_FATC001C(.f.)","U_FATC001F()",nOpcE,nOpcG,"AllwaysTrue()",,99,,,,_aSizeMod3,150)

	If _lRet
		// ** grava os dados do recebimento
		sfConfirma()
	Else
		RollBackSX8()
	Endif

Return

// ** funcao que retorna os itens da programacao
Static Function sfRetItens()
	Local _vRetItens := {}
	Local _nX
	// chave de pesquisa
	Local _cSeek

	// reinicia sequencial do item
	_cSeqItem := StrZero(1,TamSx3("Z2_ITEM")[1])

	// abre tabela dos itens da programacao
	dbSelectArea("SZ2")
	SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM

	// opcao ed inclusao
	If (_cOpcao=="INCLUIR").or.( ! SZ2->(dbSeek( _cSeek:=xFilial("SZ2")+M->Z1_CODIGO )) )
		// cria a linha de acordo com os campos do Header
		_vRetItens := Array(1,Len(aHeader)+1)
		// cria as variaveis
		For _nX := 1 to Len(aHeader)
			_vRetItens[1,_nX] := CriaVar(aHeader[_nX,2],.t.)
		Next _nX
		// trata item deletado
		_vRetItens[Len(_vRetItens),Len(aHeader)+1] := .F.

		// sequencial do item
		_cSeqItem := SomaIt(_cSeqItem)

	Else
		// inclui todos os itens da programacao
		While SZ2->(!Eof()).and.(SZ2->(Z2_FILIAL+Z2_CODIGO)==_cSeek)
			// quando for exclusao, verifica se tem item com saldo
			If (_cOpcao=="EXCLUIR").and.(SZ2->Z2_QTDREC > 0)
				_lDelOk := .f.
			EndIf
			// cria a linha de acordo com os campos do Header
			aAdd(_vRetItens,Array(Len(aHeader)+1))
			// atualiza o conteudo de acordo com cada campo
			For _nX := 1 to Len(aHeader)
				_vRetItens[Len(_vRetItens),_nX] := FieldGet(FieldPos(aHeader[_nX,2]))
			Next _nX
			// trata item deletado
			_vRetItens[Len(_vRetItens),Len(aHeader)+1] := .F.

			// proximo item
			SZ2->(dbSkip())

		EndDo
	EndIf

Return(_vRetItens)

// ** Funcao responsavel pela gravacao dos dados
Static Function sfConfirma()
	Local bCampo := {|nCPO| Field(nCPO)}
	Local _nCpoAtu := 0
	Local _nItemAtu := 0
	Local _lIncluir := (_cOpcao=="INCLUIR")
	Local _lExcluir := (_cOpcao=="EXCLUIR")
	// posicao dos campos
	Local _nPosItem := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="Z2_ITEM"})

	// Grava Cabecalho
	Begin Transaction

		// Grava todas as Informacoes da Tabela (cabecalho)
		dbSelectArea("SZ1")
		RecLock("SZ1",_lIncluir)
		// verifica se é exclusao
		If (_lExcluir)
			SZ1->(dbDelete())
			// inclusao/alteracao
		Else

			// gera log de alteracao
			If ( ! _lIncluir).and.(M->Z1_TIPO != SZ1->Z1_TIPO)

				// insere o log
				U_FtGeraLog(xFilial("SZ1"), "SZ1", xFilial("SZ1") + M->Z1_CODIGO, "Realizado alteração no Tipo de Recebimento da Programação, de "+SZ1->Z1_TIPO+" para "+M->Z1_TIPO, "WMS")

			EndIf

			// gravacao dos demais campo
			For _nCpoAtu := 1 to FCount()
				FieldPut(_nCpoAtu,M->&(EVAL(bCampo,_nCpoAtu)))
			Next _nCpoAtu
		EndIf

		// salva/confirma alteracoes
		SZ1->(MsUnLock())

		// grava os itens
		dbSelectArea("SZ2")
		SZ2->(dbSetOrder(1))//1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM

		For _nItemAtu := 1 to Len(aCols)
			// posiciona no item
			If (!_lIncluir)
				SZ2->(dbSeek( xFilial("SZ2")+M->Z1_CODIGO+aCols[_nItemAtu,_nPosItem] ))
			EndIf

			// verifica se nao esta deletado
			If (!_lExcluir) .and. (!aCols[_nItemAtu,Len(aHeader)+1])
				// operacao no registro
				If (_lIncluir)
					RecLock("SZ2",_lIncluir)
				Else
					RecLock("SZ2",(SZ2->(!Found())))
				EndIf
				// grava itens
				If (_lIncluir).or.(SZ2->(!Found()))
					SZ2->Z2_FILIAL	:= xFilial("SZ2")
					SZ2->Z2_CODIGO	:= M->Z1_CODIGO
				EndIf
				// grava campos do browse
				For _nCpoAtu := 1 to Len(aHeader)
					// verifica se eh campo virtual
					If (aHeader[_nCpoAtu][10] != "V")
						// gera log de alteracao de quantidade programada
						If ( ! _lIncluir ).and.(AllTrim(aHeader[_nCpoAtu][2]) == "Z2_QUANT").and.(aCols[_nItemAtu,_nCpoAtu] != SZ2->Z2_QUANT)
							// insere o log
							U_FtGeraLog(xFilial("SZ2"), "SZ2", xFilial("SZ2") + SZ2->Z2_CODIGO + SZ2->Z2_ITEM, "Realizado alteração da quantidade programada, de: "+AllTrim(Str(SZ2->Z2_QUANT))+" para "+AllTrim(Str(aCols[_nItemAtu,_nCpoAtu])),"WMS", SZ2->Z2_CODIGO)
						EndIf
						// grava conteudo do campo
						FieldPut(FieldPos(aHeader[_nCpoAtu,2]),aCols[_nItemAtu,_nCpoAtu])
					EndIf
				Next _nCpoAtu
				// confirma gravacao
				SZ2->(MsUnLock())
			Else
				If (!_lIncluir).or.(_lExcluir)
					// verifica a existencia do item
					If SZ2->(Found())
						RecLock("SZ2",.F.)
						SZ2->(dbDelete())
						SZ2->(MsUnLock())
					Endif
				Endif
			EndIf

		Next _nItemAtu

		// finaliza transacao
	End Transaction

	If (_lIncluir)
		ConfirmSX8()
	EndIf

Return

// ** funcao que Monta a Legenda
User Function FATC001A()

	BrwLegenda(_cCadastro, "Status "+_cCadastro,{;
	{"ENABLE"    , "Aberta"         },;
	{"BR_AMARELO", "Iniciada"       },;
	{"BR_AZUL"   , "Encerrado WMS"  },;
	{"DISABLE"   , "Encerrado Geral"}})

Return .T.

// ** funcao para validacao da linha
User Function FATC001C(mvVldGet)
	// posicao do campo Quant Recebida
	Local _nPosQtdRec := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="Z2_QTDREC"})
	Local _nPosQuant  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="Z2_QUANT"})
	// posicao do campo Tipo Container
	Local _nPosTipo := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="Z2_TIPCONT"})
	// posicao do campo Tamanho Container
	Local _nPosTamCo := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="Z2_TAMCONT"})
	// posicao do campo Item
	Local _nPosItem := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="Z2_ITEM"})

	// armazena o item atual
	_cSeqItem := aCols[N,_nPosItem]

	// validacao do campo somente na alteracao
	If (_lAltera)
		If (mvVldGet)
			If (AllTrim(ReadVar())=="M->Z2_QUANT").and.(M->Z2_QUANT < aCols[N,_nPosQtdRec])
				MsgStop("A quantidade programada não pode ser inferior a quantidade já recebida!")
				Return(.f.)
			EndIf
			// verifica se tem registro de chegada de caminhao
			If (aCols[N,_nPosTamCo]=="CS")
				If ( ! sfTemChegada(M->Z1_CODIGO,aCols[N,_nPosItem]))
					MsgStop("Há registros de chegada de caminhão em aberto!")
					Return(.f.)
				EndIf
			EndIf

			// validacao da linha
		ElseIf (!mvVldGet)
			If (aCols[N,Len(aHeader)+1]).and.(aCols[N,_nPosQuant] < aCols[N,_nPosQtdRec])
				MsgStop("A quantidade programada não pode ser inferior a quantidade já recebida!")
				Return(.f.)
			EndIf
			// valida o tipo da carga
			If (aCols[N,Len(aHeader)+1]).and.(aCols[N,_nPosTipo]<>"99").and.(aCols[N,_nPosTamCo]=="CS")
				MsgStop("Verifique os campos: Tip Contain. e Tam Contain.")
				Return(.f.)
			EndIf
			// verifica se tem registro de chegada de caminhao
			If (aCols[N,Len(aHeader)+1]).and.(aCols[N,_nPosTamCo]=="CS")
				If ( ! sfTemChegada(M->Z1_CODIGO,aCols[N,_nPosItem]) )
					MsgStop("Há registros de chegada de caminhão em aberto!")
					Return(.f.)
				EndIf
			EndIf
		EndIf
	EndIf

	// incrementa o sequencual do item
	_cSeqItem := SomaIt(_cSeqItem)

Return(.t.)

// ** funcao que define se o campo esta editavel
User Function FATC001D()
	Local _lRet := .t.
	// posicao do campo Tipo Container
	Local _nPosTipo := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="Z2_TIPCONT"})
	// se for carga solta, nao permite editar
	If (aCols[N,_nPosTipo]=="99")
		_lRet := .f.
	EndIf
Return(_lRet)

// ** funcao que verifica se tem movimentacao de chegada de caminhoes em aberto
Static Function sfTemChegada(mvNumProg,mvIteProg)
	Local _cQuery
	Local _lRet

	_cQuery := " SELECT COUNT(Z3_FILIAL) QTD_MOVIM "
	_cQuery += " FROM "+RetSqlTab("SZ3")
	_cQuery += " WHERE "+RetSqlCond("SZ3")
	_cQuery += " AND Z3_PROGRAM = '"+mvNumProg+"' AND Z3_ITEPROG = '"+mvIteProg+"' "
	_cQuery += " AND Z3_TPMOVIM = 'E' "
	_cQuery += " AND Z3_TAMCONT = 'CS' "
	_cQuery += " AND Z3_DTMOVIM = ' ' "
	// executa a query
	_lRet := (U_FtQuery(_cQuery)==0)

	memowrit("c:\query\tfatc001_sfTemChegada.txt",_cQuery)

Return(_lRet)

// ** funcao que define se o campo tipo de carga pode ser alterado
User Function FATC001E()
	Local _cQuery
	Local _lRet

	_cQuery := " SELECT COUNT(Z3_FILIAL) QTD_MOVIM "
	// mov. de cargas
	_cQuery += " FROM "+RetSqlTab("SZ3")
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("SZ3") "
	// processo
	_cQuery += " AND Z3_PROGRAM = '"+M->Z1_CODIGO+"' "
	// data de faturamento
	_cQuery += " AND Z3_DTFATPA <> ' ' "
	// executa a query
	_lRet := (U_FtQuery(_cQuery)==0)

Return(_lRet)

// ** funcao para validacao toda a tela
User Function FATC001F()
	// variaveis temporarias
	local _nItemAtu
	// quantidade de itens
	local _nQtdItens := 0

	// validacao se ha itens no processo
	If (_lInclui).or.(_lAltera)
		// varre todos os itens
		For _nItemAtu := 1 to Len(aCols)
			// verifica se nao esta deletado
			If ( ! aCols[_nItemAtu,Len(aHeader)+1] )
				_nQtdItens ++
			EndIf
		Next _nItemAtu
	EndIf

	// quantidade de itens
	If (_nQtdItens == 0)
		MsgStop("É obrigatório informar itens no processo!")
		Return(.f.)
	EndIf

Return(.t.)

// ** função para alterar o tipo de programação ** //
User Function FATC001T ()

	// objetos de tela
	local _oWndTipo, _oPnlBottom, _oTpMovim, _oTGetProg, _oSayProg, _oSayReason, _oTGetReason, _oSayTpMovim
	local _oBmpConf, _oBmpCanc
	// opções do combobox
	local _aTpMovim := {"E=Entrada", "C=Carregamento"}
	local _cTpMovim := ""
	// numero da programação entrada
	local _cProgEnt := CriaVar("Z1_CODIGO", .f.)
	// motivo da alteração
	local _cMotAlt := ""

	// monta o dialogo
	_oWndTipo := MSDialog():New(000,000,265,250,"Alterar Tipo de Movimento da Programação",,,.F.,,,,,,.T.,,,.T. )

	// panel para os botoes de comando
	_oPnlBottom := TPanel():New(000,000,Nil,_oWndTipo,,.F.,.F.,,,0,20,.T.,.F. )
	_oPnlBottom:Align := CONTROL_ALIGN_BOTTOM

	// tipo de movimento
	_oSayTpMovim := TSay():New(04,04,{||"Tipo de Movimento"},_oWndTipo,,,.F.,.F.,.F.,.T.)
	_oTpMovim := TComboBox():New(14,04,{|u|if(PCount()>0,_cTpMovim:=u,_cTpMovim)},;
	_aTpMovim,100,20,_oWndTipo,,{|| Iif( _cTpMovim == "C", _oTGetProg:Enable(), _oTGetProg:Disable() ) } ,,,,.T.,,,,,,,,,'_cTpMovim')

	// programação de entrada
	_oSayProg  := TSay():New(32,04,{||"Programação de Entrada"},_oWndTipo,,,.F.,.F.,.F.,.T.)
	_oTGetProg := TGet():New(42,04,{|u| If(PCount()>0,_cProgEnt:=u,_cProgEnt)},_oWndTipo,050,008,PesqPict("SZ1","Z1_CODIGO"),,,,,,,.T.,"",,{||  },.F.,.F.,,.F.,.F.,"SZ1","_cProgEnt",,,,,,,)
	_oTGetProg:Disable()

	// motivo da alteração
	_oSayReason  := TSay():New(60,04,{||"Motivo da Alteração"},_oWndTipo,,,.F.,.F.,.F.,.T.)
	_oTGetReason := TMultiget():NEW(72,04,{|u|if(pCount()>0,_cMotAlt:=u,_cMotAlt)}, _oWndTipo,119,30,,,,,,.t. )

	// confirmar
	_oBtConf := TButton():New( 006, 006, "Confirmar",_oPnlBottom,{|| sfConfAlt(_cTpMovim, SZ1->Z1_CODIGO, _cProgEnt, _cMotAlt, _oWndTipo) }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// cancelar
	_oBtCanc := TButton():New( 006, 056, "Cancelar",_oPnlBottom,{|| _oWndTipo:End() }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// ativa a tela
	ACTIVATE MSDIALOG _oWndTipo CENTERED

Return .t.

// ** funcao que faz a validacao do numero da programacao digita
Static Function sfConfAlt( mvTpMovim, mvProg, mvProgEnt, mvMotivo, mvDlg )
	// variavel de retorno
	local _lRet := .t.
	// get area atual
	local _aAreaAtual := GetArea()

	// se a programação já estiver encerrada
	If ( _lRet ) .and.( ! Empty(SZ1->Z1_DTFINFA) )
		// avisa o usuário
		MsgInfo("Programação já foi encerrada pelo faturamento.","Atenção")
		_lRet := .f.
	EndIf

	// se não houve alteração
	If ( _lRet ) .and.( SZ1->Z1_TPMOVIM == mvTpMovim )
		// avisa o usuário
		MsgInfo("Tipo de Movimento selecionado é igual ao atual.","Atenção")
		_lRet := .f.
	EndIf

	// se for do tipo carregamento, precisa da programação de entrada
	If ( _lRet ) .and. (  mvTpMovim == "C" ) .and. ( Empty(mvProgEnt) )

		// avisa o usuário
		MsgInfo("É necessário informar a Programação de Entrada para Programações de Carregamento.","Atenção")
		_lRet := .f.
	EndIf

	// valida se a programação de entrada está correta
	If ( _lRet ) .and. (  mvTpMovim == "C" ) .and. ( ! Empty(mvProgEnt) )

		// posiciona na programação atual
		dbSelectArea("SZ1")
		SZ1->( dbSetOrder(1) ) // Z1_FILIAL, Z1_CODIGO, R_E_C_N_O_, D_E_L_E_T_
		If ( SZ1->( dbSeek( xFilial("SZ1") + mvProgEnt ) ) )
			// se o tipo de movimetno não for ENTRADA
			If ( SZ1->Z1_TPMOVIM != "E" )

				// avisa o usuário
				MsgInfo("Tipo de Programação de Entrada Inválida.","Atenção")
				_lRet := .f.
			EndIf
		EndIf
	EndIf

	// valida se o motivo foi preenchido
	If ( _lRet ) .and. ( Empty(mvMotivo) )
		// avisa o usuário
		MsgInfo("O motivo precisa ser informado.","Atenção")
		_lRet := .f.
	EndIf

	// se deu tudo certo, faz as alterações
	If ( _lRet )

		// posiciona na programação atual
		dbSelectArea("SZ1")
		SZ1->( dbSetOrder(1) ) // Z1_FILIAL, Z1_CODIGO, R_E_C_N_O_, D_E_L_E_T_
		If ( SZ1->( dbSeek( xFilial("SZ1") + mvProg ) ) )

			// faz a alteração
			Reclock("SZ1")
			SZ1->Z1_TPMOVIM := mvTpMovim
			SZ1->Z1_PROGENT := mvProgEnt
			SZ1->( MsUnlock() )

			// insere o log
			U_FtGeraLog(xFilial("SZ1"), "SZ1", xFilial("SZ1") + SZ1->Z1_CODIGO, "Realizado alteração no Tipo de Movimento da Programação " + SZ1->Z1_CODIGO + ". Motivo: " + mvMotivo + "", "WMS")

			// avisa o usuário
			MsgInfo("Alteração realizada com sucesso!", "Sucesso")
			mvDlg:End()
		EndIf

	EndIf

	// restaura area inicial
	RestArea(_aAreaAtual)

Return(_lRet)

// ** funcao para alterar o conteudo da carga dos itens
User Function FATC001G
	// objetos locais
	local _oWndAltCont, _oBrwItens
	// arrays do browse
	local _aHeadItens := {}
	local _aColsItens := {}

	// controle de confirmacao da tela
	local _lOk := .f.
	// alteracao de dados
	local _lDadosAlt := .f.

	// posicao dos campos no browse
	local _nP_Item    := 0
	local _nP_Conteud := 0

	// chave de pesquisa
	local _cSeekSZ2

	// variaveis temporarias
	local _nX

	// se a programação já estiver encerrada
	If ( ! Empty(SZ1->Z1_DTFINFA) )
		// avisa o usuário
		MsgInfo("Programação já foi encerrada pelo faturamento.","Atenção")
		// retorno
		Return(.f.)
	EndIf

	// define array do browse
	aAdd(_aHeadItens,{"Item"        , "Z2_ITEM"   , "", TamSx3("Z2_ITEM")[1]   , 0                     ,Nil,Nil,"C",Nil,"R",,,".F." }) ; _nP_Item    := Len(_aHeadItens)
	aAdd(_aHeadItens,{"Documento"   , "Z2_DOCUMEN", "", TamSx3("Z2_DOCUMEN")[1], 0                     ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadItens,{"Conteúdo"    , "Z2_CONTEUD", "", TamSx3("Z2_CONTEUD")[1], 0                     ,Nil,Nil,"C",Nil,"R",,,".T." }) ; _nP_Conteud := Len(_aHeadItens)
	aAdd(_aHeadItens,{"Quant.Progr.", "Z2_QUANT"  , "", TamSx3("Z2_QUANT")[1]  , TamSx3("Z2_QUANT")[2] ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadItens,{"Quant.Receb.", "Z2_QTDREC" , "", TamSx3("Z2_QTDREC")[1] , TamSx3("Z2_QTDREC")[2],Nil,Nil,"C",Nil,"R",,,".F." })

	// varre todos os itens da programacao para alimentar o aCols
	dbSelectArea("SZ2")
	SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM
	SZ2->(dbSeek( _cSeekSZ2 := xFilial("SZ2")+SZ1->Z1_CODIGO ))

	// inclui todos os itens da programacao
	While SZ2->( ! Eof() ).and.(SZ2->(Z2_FILIAL+Z2_CODIGO)==_cSeekSZ2)
		// cria a linha de acordo com os campos do Header
		aAdd(_aColsItens,Array(Len(_aHeadItens)+1))
		// atualiza o conteudo de acordo com cada campo
		For _nX := 1 to Len(_aHeadItens)
			_aColsItens[Len(_aColsItens),_nX] := FieldGet(FieldPos(_aHeadItens[_nX,2]))
		Next _nX
		// trata item deletado
		_aColsItens[Len(_aColsItens),Len(_aHeadItens)+1] := .F.

		// proximo item
		SZ2->(dbSkip())

	EndDo

	// monta o dialogo da tela de alteracao dos dados
	_oWndAltCont := MSDialog():New(000,000,300,600,"Alteração de Conteúdo de Carga",,,.F.,,,,,,.T.,,,.T. )

	// browse
	_oBrwItens := MsNewGetDados():New(000,000,300,400,GD_UPDATE,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsItens),'AllwaysTrue()','','AllwaysTrue()',_oWndAltCont,_aHeadItens,_aColsItens)
	_oBrwItens:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativacao da tela
	ACTIVATE MSDIALOG _oWndAltCont ON INIT EnchoiceBar(_oWndAltCont,{|| _lOk := .t., _oWndAltCont:End() },{|| _oWndAltCont:End() }) CENTERED

	// verifica se a tela foi confirmada
	If (_lOk)

		// varre todos os itens da programacao para alterar o conteudo
		For _nX := 1 to Len(_oBrwItens:aCols)

			// posiciona no item
			dbSelectArea("SZ2")
			SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM
			If SZ2->(dbSeek( xFilial("SZ2")+SZ1->Z1_CODIGO+_oBrwItens:aCols[_nX][_nP_Item] ))

				// compara conteudo
				If ( SZ2->Z2_CONTEUD != _oBrwItens:aCols[_nX][_nP_Conteud] )

					// insere o log
					U_FtGeraLog(xFilial("SZ2"), "SZ2", xFilial("SZ2") + SZ2->Z2_CODIGO + SZ2->Z2_ITEM, "Realizado alteração no Conteúdo da Carga, de "+SZ2->Z2_CONTEUD+" para "+_oBrwItens:aCols[_nX][_nP_Conteud], "WMS")

					// atualiza conteudo
					RecLock("SZ2")
					SZ2->Z2_CONTEUD := _oBrwItens:aCols[_nX][_nP_Conteud]
					SZ2->(MsUnLock())

					// addos alterados
					_lDadosAlt := .t.

				EndIf
			EndIf

		Next _nX

		// avisa o usuário
		If (_lDadosAlt)
			MsgInfo("Dados Atualizados com Sucesso!","Atenção")
		EndIf

	EndIf

Return(_lOk)

// ** funcao para definir o menu
Static Function MenuDef()
	// variavel de retorno
	local _aRetMenu := 	{;
	{ "Pesquisar"                      ,"AxPesqui"     , 0 , 1 },;
	{ "Visualizar"                     ,"U_FATC001B(1)", 0 , 2 },;
	{ "Incluir"                        ,"U_FATC001B(2)", 0 , 3 },;
	{ "Alterar"                        ,"U_FATC001B(3)", 0 , 4 },;
	{ "Excluir"                        ,"U_FATC001B(4)", 0 , 5 },;
	{ "Alterar Tipo de Mov. da Prog."  ,"U_FATC001T()" , 0 , 4 },;
	{ "Alterar Conteúdo da Carga"      ,"U_FATC001G()" , 0 , 4 },;
	{ "Encerrar Processo"              ,"U_FATA002I(.f., SZ1->Z1_CODIGO)", 0 , 4 },;
	{ "Legenda"                        ,"U_FATC001A()" , 0 , 1 } }
Return(_aRetMenu)