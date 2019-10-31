#INCLUDE "PROTHEUS.CH"
#INCLUDE "MSMGADD.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSC006                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Cadastro de Agrupadores/Kit de Produtos                 !
!                  !                                                         !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe Jose Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/03/15                                                !
+------------------+--------------------------------------------------------*/

User Function TWMSC006()

	Local _cCadastro:='Agrupadores/Kit de Produtos"
	Private aRotina:= {}

	//Montar o vetor aRotina, obrigatorio para utilização da função mBrowse()
	aAdd( aRotina, {"Pesquisar"  , "AxPesqui"                      , 0, 1 })
	aAdd( aRotina, {"Visualizar" , "StaticCall(TWMSC006,sfManuz29,'Z29',Z29->(Recno()),2)", 0, 2 })
	aAdd( aRotina, {"Incluir"    , "StaticCall(TWMSC006,sfManuz29,'Z29',Z29->(Recno()),3)", 0, 3 })
	aAdd( aRotina, {"Alterar"    , "StaticCall(TWMSC006,sfManuz29,'Z29',Z29->(Recno()),4)", 0, 4 })
	aAdd( aRotina, {"Excluir"    , "StaticCall(TWMSC006,sfManuz29,'Z29',Z29->(Recno()),5)", 0, 5 })

	// cadastro de kit/agrupadora
	dbSelectArea("Z29")
	Z29->(DbSetOrder(1))

	//Executar a função mBrowse para a tabela mencionada
	mBrowse(,,,,"Z29")

Return

// ** Função para manuntenção da tabela(Inclusão/Alteração/Exclusão)
Static Function sfManuz29(cAlias,mvRecno,mvOpcao)

	local   _aCpoEnch := {}
	local   _aAltEnch := {}
	Local   _lAltKit  := .F.
	Local   _nOpcG    := mvOpcao
	Private _aHeader  := {}
	Private _aCols    := {}
	Private _aSizeDlg := MsAdvSize()
	Private _nPosPRO
	Private _nPosPRC
	Private _nPosDES
	Private _nPosQTD

	// campos que permite alteracao
	private _aAlterEnch := {}

	// Campos que irão para o Cabeçalho
	aadd(_aCpoEnch,"NOUSER" )
	aadd(_aCpoEnch,"Z29_SIGLA" )
	aadd(_aCpoEnch,"Z29_CODIGO")
	aadd(_aCpoEnch,"Z29_CODKIT")
	aadd(_aCpoEnch,"Z29_DSCKIT")
	aadd(_aCpoEnch,"Z29_EMBALA")
	aadd(_aCpoEnch,"Z29_DESEMB")
	aadd(_aCpoEnch,"Z29_LASTRO")
	aadd(_aCpoEnch,"Z29_CAMADA")
	aadd(_aCpoEnch,"Z29_ADICIO")
	aadd(_aCpoEnch,"Z29_MSBLQL")

	// campos que podem ser alterados
	_aAlterEnch := aclone(_aCpoEnch)

	// atualiza variaveis da memoria
	Regtomemory(cAlias,If(mvOpcao==3,.T.,.F.))

	// na alteracao ou exclusao, verifica se o Kit ja foi utilizado.
	If (mvOpcao == 4 .Or. mvOpcao == 5)
		_lAltKit := sfVldManut()
	EndIf

	// validacoes se permite editar o Kit/Agrupadora
	If (_lAltKit) .And. (mvOpcao == 4)
		_nOpcG := 0
		MsgStop("Kit Ja utilizado! Não sera permitida alteração na estrutura dos Produtos.","TWMSC006 - Agrupadores/Kit de Produtos")
	ElseIf (_lAltKit) .And. (mvOpcao == 5)
		MsgStop("Kit Ja utilizado! Exclusão não permitida.","TWMSC006 - Agrupadores/Kit de Produtos")
		Return()
	ElseIf (!_lAltKit) .And. (mvOpcao == 4 .Or. mvOpcao == 3)
		_nOpcG := GD_INSERT+GD_DELETE+GD_UPDATE
	Else
		_nOpcG := 0
	EndIf

	// cria tela principal
	_oTela            := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Agrupadores/Kit de Produtos",,,.F.,,,,,,.T.,,,.T. )
	_oTela:bInit      := {||EnchoiceBar(_oTela,{|| sfProcessa(mvOpcao) },{||(_oTela:End())},.F.,{})}
	_oPanelTop        := TPanel():New(000,000,"",_oTela,,.F.,.F.,,,280,100,.T.,.F. )
	_oPanelCen        := TPanel():New(080,008,"",_oTela,,.F.,.F.,,,280,104,.T.,.F. )
	_oPanelTop:Align  := CONTROL_ALIGN_TOP
	_oPanelCen:Align  := CONTROL_ALIGN_ALLCLIENT

	//Criar o vetor aHeader, que é o vetor que tem as caracteristicas para os campos da Getdados
	_aHeader := ApBuildHeader("Z29",{"Z29_CODKIT","Z29_DSCKIT","Z29_SIGLA","Z29_CODIGO","Z29_EMBALA","Z29_DESEMB","Z29_LASTRO","Z29_CAMADA","Z29_ADICIO","Z29_MSBLQL"})

	//Verifica posição dos campos na Grid
	_nPosPRO := GDFIELDPOS("Z29_PRODUT" , _aHeader )
	_nPosPRC := GDFIELDPOS("Z29_PROCLI" , _aHeader )
	_nPosDES := GDFIELDPOS("Z29_DESPRO" , _aHeader )
	_nPosQTD := GDFIELDPOS("Z29_QUANT"  , _aHeader )

	// cria enchoice (cabecalho)
	_oEnchoice := MsMGet():New("Z29",,mvOpcao,,,,_aCpoEnch,{0,0,0,0}  ,_aAlterEnch,,,,,_oPanelTop,,.T.)
	_oEnchoice:oBox:Align := CONTROL_ALIGN_ALLCLIENT

	// cria browse
	_oGetDados := MsNewGetDados():New(004,008,064,148,_nOpcG,'AllwaysTrue()','AllwaysTrue()','',,0,99,'','','AllwaysTrue()',_oPanelCen,_aHeader,_aCols )
	_oGetDados:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oGetDados:cFieldOk      := "StaticCall(TWMSC006,sfValidaCp)"

	// Se não for inclusão popular Grid com os produtos do Kit
	If (! Inclui)
		sfPopuGrid()
	EndIf

	// ativa a tela
	_oTela:Activate(,,,.T.)

Return

// ** Função para gravar na Base de dados(Inclusão/Alteração/Exclusão)
Static Function sfProcessa(mvOpcao)

	Local _i         := 0
	Local _LinValida := 0

	Begin Transaction

		// se for inclusao
		If (Inclui)

			For _i := 1 To Len(_oGetDados:Acols)
				If !_oGetDados:Acols[_i][Len(_aHeader)+1]
					_LinValida++
				EndIf
			Next _i

			If (_LinValida < 2)
				MsgStop("Minimo de 2 produtos para formar 1 Kit.","TWMSC006 - Agrupadores/Kit de Produtos")
			Else
				For _i := 1 To Len(_oGetDados:Acols)
					If ! _oGetDados:Acols[_i][Len(_aHeader)+1]

						RecLock("Z29", .T.)
						Z29->Z29_FILIAL := xFilial("Z29")
						Z29->Z29_CODKIT := M->Z29_CODKIT
						Z29->Z29_DSCKIT := M->Z29_DSCKIT
						Z29->Z29_SIGLA  := M->Z29_SIGLA
						Z29->Z29_CODIGO := M->Z29_CODIGO
						Z29->Z29_EMBALA := M->Z29_EMBALA
						Z29->Z29_LASTRO := M->Z29_LASTRO
						Z29->Z29_CAMADA := M->Z29_CAMADA
						Z29->Z29_ADICIO := M->Z29_ADICIO
						Z29->Z29_MSBLQL := M->Z29_MSBLQL
						Z29->Z29_PRODUT := _oGetDados:Acols[_i,_nPosPRO]
						Z29->Z29_PROCLI := _oGetDados:Acols[_i,_nPosPRC]
						Z29->Z29_QUANT  := _oGetDados:Acols[_i,_nPosQTD]
						Z29->(msUnLock())

						// cad. de lastro e camada do produto por filial
						dbSelectArea("Z20")
						RecLock("Z20",.t.)
						Z20->Z20_FILIAL := xFilial("Z20")
						Z20->Z20_CODPRO := M->Z29_CODKIT
						//Z20->Z20_LOCAL  := _cArmzAtual
						Z20->Z20_UNITIZ := SuperGetMV('TC_PLTPADR',.F.,"000001")
						Z20->Z20_LASTRO := M->Z29_LASTRO
						Z20->Z20_CAMADA := M->Z29_CAMADA
						Z20->Z20_ADICIO := M->Z29_ADICIO
						Z20->(MsUnLock())

					EndIf
				Next _i

				// fecha a tela
				_oTela:End()

			EndIf

			// se for alteracao
		ElseIf (Altera)

			For _i := 1 To Len(_oGetDados:Acols)
				If !_oGetDados:Acols[_i][Len(_aHeader)+1]
					_LinValida++
				EndIf
			Next _i

			If (_LinValida < 2)
				MsgStop("Minimo de 2 produtos para formar 1 Kit.","TWMSC006 - Agrupadores/Kit de Produtos")
			Else
				For _i := 1 To Len(_oGetDados:Acols)

					// cadastro do kit/agrupadora
					dbSelectArea("Z29")
					Z29->(dbsetorder(4)) // 4-Z29_FILIAL+Z29_SIGLA+Z29_CODIGO+Z29_CODKIT+Z29_PRODUT

					// verifica se nao esta deletado
					If (_oGetDados:Acols[_i][Len(_aHeader)+1])

						// pesquisa pelo kit/agrupadora
						If Z29->(dbseek(xFilial("Z29") + M->Z29_SIGLA + M->Z29_CODIGO + M->Z29_CODKIT + _oGetDados:Acols[_i,_nPosPRO] ))
							RecLock("Z29",.F.)
							Z29->( dbDelete() )
							Z29->(msUnLock())
						EndIf

					Else

						// pesquisa pelo kit/agrupadora
						If Z29->(dbseek(xFilial("Z29") + M->Z29_SIGLA + M->Z29_CODIGO + M->Z29_CODKIT + _oGetDados:Acols[_i,_nPosPRO] ))
							RecLock("Z29",.F.)
						Else
							RecLock("Z29",.T.)
						EndIf
						// atualiza campos
						Z29->Z29_FILIAL := xFilial("Z29")
						Z29->Z29_CODKIT := M->Z29_CODKIT
						Z29->Z29_DSCKIT := M->Z29_DSCKIT
						Z29->Z29_SIGLA  := M->Z29_SIGLA
						Z29->Z29_CODIGO := M->Z29_CODIGO
						Z29->Z29_EMBALA := M->Z29_EMBALA
						Z29->Z29_LASTRO := M->Z29_LASTRO
						Z29->Z29_CAMADA := M->Z29_CAMADA
						Z29->Z29_ADICIO := M->Z29_ADICIO
						Z29->Z29_MSBLQL := M->Z29_MSBLQL
						Z29->Z29_PRODUT := _oGetDados:Acols[_i,_nPosPRO]
						Z29->Z29_PROCLI := _oGetDados:Acols[_i,_nPosPRC]
						Z29->Z29_QUANT  := _oGetDados:Acols[_i,_nPosQTD]
						Z29->(msUnLock())

						// cad. de lastro e camada do produto por filial
						dbSelectArea("Z20")
						Z20->(dbOrderNickName("Z20_CODPRO")) // Z20_FILIAL, Z20_CODPRO, Z20_LOCAL, Z20_UNITIZ
						If Z20->(dbSeek( xFilial("Z20")+M->Z29_CODKIT ))
							RecLock("Z20",.F.)
						Else
							RecLock("Z20",.T.)

							Z20->Z20_FILIAL := xFilial("Z20")
							Z20->Z20_CODPRO := M->Z29_CODKIT
							//Z20->Z20_LOCAL  := _cArmzAtual
							Z20->Z20_UNITIZ := SuperGetMV('TC_PLTPADR',.F.,"000001")

						EndIf

						Z20->Z20_LASTRO := M->Z29_LASTRO
						Z20->Z20_CAMADA := M->Z29_CAMADA
						Z20->Z20_ADICIO := M->Z29_ADICIO

						Z20->(MsUnLock())

					EndIf
				Next _i
				// fecha a tela
				_oTela:End()
			EndIf

		ElseIf (mvOpcao == 5) //Exclusão.

			For _i := 1 To Len(_oGetDados:Acols)

				// cadastro do kit/agrupadora
				dbSelectArea("Z29")
				Z29->(dbsetorder(4)) // 4-Z29_FILIAL+Z29_SIGLA+Z29_CODIGO+Z29_CODKIT+Z29_PRODUT

				// pesquisa pelo kit/agrupadora
				If Z29->(dbseek(xFilial("Z29") + Z29->Z29_SIGLA + Z29->Z29_CODIGO + Z29->Z29_CODKIT + _oGetDados:Acols[_i,_nPosPRO] ))
					RecLock("Z29",.F.)
					Z29->( dbDelete() )
					Z29->(msUnLock())
				EndIf
			Next _i

			// fecha a tela
			_oTela:End()

		EndIf

	End Transaction

Return()

// ** Função para validar campos da Grid.
Static Function sfValidaCp()
	Local _i
	Local _lRet := .T.
	If ReadVar() == "M->Z29_PRODUT"
		//Verifica se produto pertence ao grupo escolhido.
		If Posicione("SB1",1,xFilial("SB1") + M->Z29_PRODUT ,"B1_GRUPO") <> M->Z29_SIGLA
			MsgStop("Produto não pertence a Grupo de cliente informado.","TWMSC006 - Agrupadores/Kit de Produtos")
			_lRet := .F.
			Return(_lRet)
		EndIf
		//Verifica duplicidade do produto na grid.
		For _i := 1 To Len(_oGetDados:Acols)
			If M->Z29_PRODUT == _oGetDados:Acols[_i,_nPosPRO] .And. _oGetDados:nAt <> _i
				MsgStop("Produto Duplicado","TWMSC006 - Agrupadores/Kit de Produtos")
				_lRet := .F.
				Exit
			EndIf
		Next _i
	EndIf
Return(_lRet)

// ** Função para validar Chave duplicada Z29_FILIAL+Z29_SIGLA+Z29_CODIGO+Z29_CODKIT+Z29_PRODUT chamada no SX3 do campos - Z29_SIGLA e Z29_CODIGO.
Static Function sfValZ29()
	Local _lRet := .T.
	If !Empty(M->Z29_SIGLA) .And. !Empty(M->Z29_CODIGO)
		Z29->(dbgotop())
		Z29->(dbsetorder(4))//Z29_FILIAL+Z29_SIGLA+Z29_CODIGO+Z29_CODKIT+Z29_PRODUT
		If(Z29->(dbseek(xFilial("Z29") + M->Z29_SIGLA + M->Z29_CODIGO )))
			MsgStop("Código Duplicado","TWMSC006 - Agrupadores/Kit de Produtos")
			_lRet := .F.
		EndIf
	EndIf
Return(_lRet)

// ** Função para popular a grid com os itens do KIT.
Static Function sfPopuGrid()
	// area inicial
	local _aAreaZ29 := Z29->(GetArea())
	// Seek Z29
	local _cSeekZ29
	Local _nLin      := 0

	// zera conteudo
	_aCols := {}

	dbSelectArea("Z29")
	Z29->(dbSetOrder(4)) // 4-Z29_FILIAL+Z29_SIGLA+Z29_CODIGO+Z29_CODKIT+Z29_PRODUT
	Z29->(dbSeek( _cSeekZ29 := xFilial("Z29") + Z29->Z29_SIGLA + Z29->Z29_CODIGO + Z29->Z29_CODKIT))

	// varre os registros do kit
	While Z29->(!Eof()).and.(Z29->(Z29_FILIAL+Z29_SIGLA+Z29_CODIGO+Z29_CODKIT) == _cSeekZ29 )

		// incremento da linha de controle
		_nLin++

		// cria nova linha no vetor
		Aadd(_aCols,Array(Len(_aHeader)+1))

		// atualiza os dados do novo registro
		_aCols[_nLin][_nPosPRO]        := Z29->Z29_PRODUT
		_aCols[_nLin][_nPosPRC]        := Z29->Z29_PROCLI
		_aCols[_nLin][_nPosDES]        := Posicione("SB1",1,xFilial("SB1") + Z29->Z29_PRODUT ,"B1_DESC")
		_aCols[_nLin][_nPosQTD]        := Z29->Z29_QUANT
		_aCols[_nLin][Len(_aHeader)+1] := .F.

		// proximo item do kit
		Z29->(dbSkip())
	EndDo

	// atualizar dados no Browse
	_oGetDados:SetArray(_aCols ,.T. )
	_oGetDados:ForceRefresh()

	// restaura area inicial
	RestArea(_aAreaZ29)

Return()

// ** Função para validar se o Kit ja foi utilizado, se sim não podera sofrer alteração ou exclusão.
Static Function sfVldManut()
	// variavel de retorno
	Local _lRet := .F.

	// vinculo de nota fiscal com CESV
	dbSelectArea("Z04")
	Z04->(dbsetorder(2)) // 2-Z04_FILIAL+Z04_CODKIT+Z04_SEQKIT

	// pesquisa o kit/agrupadora
	_lRet := Z04->(dbseek(xFilial("Z04") + M->Z29_CODKIT ))

Return(_lRet)