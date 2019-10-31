#Include "Totvs.ch"
#Include "Protheus.ch"
#Include 'FWMVCDEF.CH'
#include "tbiconn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Planejamento de Onda de Separacao                       !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 04/2018 !
+------------------+---------------------------------------------------------+
!Observacoes       ! Z57_STATUS: 01-Em Revisão                               !
!                  !             02-Liberado para Planejamento               !
!                  !             03-Mapa Expedição Ok                        !
+------------------+---------------------------------------------------------*/

User Function TWMSA042(mvCabAuto, mvItmAuto, mvOpcAuto)

	// objeto browse
	Local _oBrwOndaSep := Nil

	// variaveis de controle de rotina automatica
	Local _lRotAuto   := (ValType(mvCabAuto) == "A") .And. (ValType(mvItmAuto) == "A")
	Local _aAutoCab   := {}
	Local _aAutoItens := {}

	// cabecalho e itens
	dbSelectArea("Z57")
	dbSelectArea("Z58")

	// titulo
	Private cCadastro := "Planejamento de Onda de Separação"

	// controle de opcoes do menu
	Private aRotina := MenuDef()
	
	// Objeto da tabela temporaria
	private _cArqTmp

	// se for rotina automatica
	If (_lRotAuto)
		// define variaveis
		_aAutoCab   := aClone( mvCabAuto )
		_aAutoItens := aClone( mvItmAuto )
		/*
		ConOut(PadC("WMSA042Z - ANTES!", 80))

		ConOut(PadC("WMSA042Z - ValType(mvCabAuto) - " + ValType(mvCabAuto), 80))
		ConOut(PadC("WMSA042Z - ValType(_aAutoCab) - " + ValType(_aAutoCab), 80))
		ConOut(PadC("WMSA042Z - ValType(mvItmAuto) - " + ValType(mvItmAuto), 80))
		ConOut(PadC("WMSA042Z - ValType(_aAutoItens) - " + ValType(_aAutoItens), 80))
		ConOut(PadC("WMSA042Z - ValType(mvOpcAuto) - " + ValType(mvOpcAuto), 80))
		*/
		// chamada da rotina automatica através do MVC
		FwMvcRotAuto(ModelDef(), "Z57", mvOpcAuto, { { "Z57MASTER", _aAutoCab }, { "Z58DETAIL", _aAutoItens }  } )

		//		ConOut(PadC("WMSA042Z - DEPOIS!", 80))

		// fecha processo
		Return
	EndIf

	// cria objeto do browse
	_oBrwOndaSep := FWMBrowse():New()
	_oBrwOndaSep:SetAlias('Z57')
	_oBrwOndaSep:SetDescription(cCadastro)

	// define cores do browse
	_oBrwOndaSep:AddLegend("Z57_STATUS == '01'", "BR_AZUL"    )
	_oBrwOndaSep:AddLegend("Z57_STATUS == '02'", "BR_AMARELO" )
	_oBrwOndaSep:AddLegend("Z57_STATUS == '03'", "BR_VERDE"   )

	// cria um filtro fixo para todos
	_oBrwOndaSep:AddFilter("Em Revisão"                , "Z57_STATUS == '01'", .F., .F., "Z50", .F., {}, "ONDA_EM_REV" )
	_oBrwOndaSep:AddFilter("Liberado para Planejamento", "Z57_STATUS == '02'", .F., .F., "Z50", .F., {}, "ONDA_LIBERA" )
	_oBrwOndaSep:AddFilter("Mapa Expedição Ok"         , "Z57_STATUS == '03'", .F., .F., "Z50", .F., {}, "ONDA_OK"     )

	// define funcao executada para tecla de atalho F5
	SetKey(VK_F5,{|| _oBrwOndaSep:Refresh() })

	// ativa objeto browse
	_oBrwOndaSep:Activate()

	// define funcao executada para tecla de atalho F5
	SetKey(VK_F5, Nil)
	
	If ValType(_cArqTmp) == "O"
		_cArqTmp:Delete()
	EndIf

Return

// ** funcao para definir o menu
Static Function MenuDef()
	// variavel de retorno
	Local _aRetMenu := {}

	aAdd(_aRetMenu,{'Pesquisar'                 , 'PesqBrw'         , 0, 1, 0, .F. })
	aAdd(_aRetMenu,{'Visualizar'                , 'VIEWDEF.TWMSA042', 0, 2, 0, Nil })
	aAdd(_aRetMenu,{'Incluir'                   , 'VIEWDEF.TWMSA042', 0, 3, 0, Nil })
	aAdd(_aRetMenu,{'Alterar'                   , 'VIEWDEF.TWMSA042', 0, 4, 0, Nil })
	aAdd(_aRetMenu,{'Excluir'                   , 'VIEWDEF.TWMSA042', 0, 5, 0, Nil })
	aAdd(_aRetMenu,{'Planejar Onda de Separação', 'U_WMSA042A()'    , 0, 3, 0, Nil })
	aAdd(_aRetMenu,{'Liberar para Planejamento' , 'U_WMSA042E("02")', 0, 8, 0, Nil })
	aAdd(_aRetMenu,{'Gerar Mapa e Distribuir'   , 'U_WMSA042D()'    , 0, 4, 0, Nil })
	aAdd(_aRetMenu,{'Estornar Mapa'             , 'U_WMSA042F()'    , 0, 5, 0, Nil })

Return(_aRetMenu)

// ModelDef - Modelo padrao para MVC
Static Function ModelDef()

	// variaveis para modelo
	Local _oModel    := Nil
	Local _oStrCbZ57 := Nil
	Local _oStrItZ58 := Nil
	Local _aRelacZ58 := {}

	// define estruturas
	_oStrCbZ57 := FwFormStruct( 1, "Z57", Nil )
	_oStrItZ58 := FwFormStruct( 1, "Z58", Nil )

	// remove obrigatoriedade de campos chaves
	_oStrItZ58:SetProperty('Z58_CODIGO', MODEL_FIELD_OBRIGAT, .F.)

	// Cria o formulario
	_oModel := MpFormModel():New("MD_TWMSA042", /* bPreValid(oModel) */, { |oModel| bTudoOk(oModel) }, { |oModel| bCommit(oModel) }, /*bCancel*/)
	_oModel:SetDescription(cCadastro)

	// validação de ativação do modelo
	_oModel:SetVldActivate( { |oModel| bPreVldForm(oModel) } )

	// define campos do cabecalho
	_oModel:AddFields("Z57MASTER", Nil, _oStrCbZ57, /*prevalid*/ ,, /*bCarga*/ )
	_oModel:SetPrimaryKey({'Z57_FILIAL', 'Z57_CODIGO' })

	// modelo do grid
	_oModel:AddGrid("Z58DETAIL", "Z57MASTER", _oStrItZ58 , /*bLinePre*/ , /*bLinePost*/ , /*bPre*/ , /*bPost*/, /*bLoad*/)

	// relacionamento da tabela Cabecalho x Itens
	aAdd(_aRelacZ58,{'Z58_FILIAL', 'xFilial("Z58")'})
	aAdd(_aRelacZ58,{'Z58_CODIGO', 'Z57_CODIGO'    })

	// Faz relaciomaneto entre os compomentes do model
	_oModel:SetRelation("Z58DETAIL", _aRelacZ58, Z58->( IndexKey(1) ))

	// Liga o controle de nao repeticao de linha
	_oModel:GetModel("Z58DETAIL"):SetUniqueLine( {'Z58_PEDIDO'} )

	// Adiciona a descricao do Componente do Modelo de Dados
	_oModel:GetModel('Z57MASTER'):SetDescription('Detalhes da Onda de Separação')
	_oModel:GetModel('Z58DETAIL'):SetDescription('Pedidos da Onda de Separação')

Return( _oModel )

// ** Função que define a interface do cadastro de Solicitacao de Cargas para o MVC
Static Function ViewDef()

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local _oModel := FWLoadModel('TWMSA042')
	Local _oView  := Nil
	// Cria a estrutura a ser usada na View
	Local _oStrZ57 := FWFormStruct( 2, 'Z57', Nil )
	Local _oStrZ58 := FWFormStruct( 2, 'Z58', Nil )

	// Remove campos da estrutura
	_oStrZ58:RemoveField( 'Z58_CODIGO' )

	// Cria o objeto de View
	_oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	_oView:SetModel( _oModel )

	// Adiciona no nosso View um controle do tipo FormFields (antiga enchoice)
	_oView:AddField('VIEW_Z57', _oStrZ57, 'Z57MASTER')

	// Adiciona no nosso View um controle do tipo FormGrid (antiga newgetdados)
	_oView:AddGrid('VIEW_Z58', _oStrZ58, 'Z58DETAIL')

	// define campo incremental do grid
	_oView:AddIncrementField('VIEW_Z58', 'Z58_SEQUEN')

	// Criar "box" horizontal para receber algum elemento da view
	_oView:CreateHorizontalBox('SUPERIOR' , 40 )
	_oView:CreateHorizontalBox('INFERIOR' , 60 )

	// Relaciona o ID da View com o "box" para exibicao
	_oView:SetOwnerView('VIEW_Z57', 'SUPERIOR')
	_oView:SetOwnerView('VIEW_Z58', 'INFERIOR')

	// Liga a identificacao do componente
	_oView:EnableTitleView( 'VIEW_Z57' )
	_oView:EnableTitleView( 'VIEW_Z58' )

Return(_oView)

// ** funcao dentro do commit para gravacao de dados complementares
Static Function bCommit(oModel)
	// variavel de retorno
	local _lTudoOk := .T.

	// modelos de cabecalho e itens
	local _oModelCbZ57 := oModel:GetModel('Z57MASTER')
	local _oModelItZ58 := oModel:GetModel('Z58DETAIL')

	// variaveis temporarias
	local _nX

	// posicao atual das linhas do browse
	local _aSaveLines := FWSaveRows()

	//Operacao executada no modelo de dados.
	local _nOperation := oModel:GetOperation()

	// numero da onda de separacao
	local _cNrOndaSep := _oModelCbZ57:GetValue("Z57_CODIGO")

	// se for exclusao
	If (_lTudoOk) .And. (_nOperation == MODEL_OPERATION_DELETE)

		// varre todos os itens do browse
		For _nX := 1 to _oModelItZ58:Length()

			// posiciona na linha do browse
			_oModelItZ58:GoLine( _nX )

			// posiciona sobre o pedido de venda
			dbSelectArea("SC5")
			SC5->(dbSetOrder(1)) // 1 - C5_FILIAL, C5_NUM
			If SC5->(dbSeek( xFilial("SC5") + _oModelItZ58:GetValue("Z58_PEDIDO") ))

				// atualiza campos
				RecLock("SC5", .F.)
				SC5->C5_ZONDSEP := CriaVar("C5_ZONDSEP", .F.)
				SC5->C5_ZSEQOND := CriaVar("C5_ZSEQOND", .F.)
				SC5->( MsUnLock() )

			EndIf

		Next _nX

		// realiza a gravação do Modelo
		_lTudoOk := FWFormCommit(oModel)

		// retorno da funcao
		Return( _lTudoOk )
	EndIf

	// se for inclusao
	If (_lTudoOk) .And. ((_nOperation == MODEL_OPERATION_INSERT) .Or. (_nOperation == MODEL_OPERATION_UPDATE))

		// varre todos os itens do browse
		For _nX := 1 to _oModelItZ58:Length()

			// posiciona na linha do browse
			_oModelItZ58:GoLine( _nX )

			// posiciona sobre o pedido de venda
			dbSelectArea("SC5")
			SC5->(dbSetOrder(1)) // 1 - C5_FILIAL, C5_NUM
			SC5->(dbSeek( xFilial("SC5") + _oModelItZ58:GetValue("Z58_PEDIDO") ))

			// testa a linha deletada
			If ( ! _oModelItZ58:IsDeleted() )

				// atualiza campos
				RecLock("SC5", .F.)
				SC5->C5_ZONDSEP := _cNrOndaSep
				SC5->C5_ZSEQOND := _oModelItZ58:GetValue("Z58_SEQUEN")
				SC5->( MsUnLock() )

			ElseIf ( _oModelItZ58:IsDeleted() )

				// atualiza campos
				RecLock("SC5", .F.)
				SC5->C5_ZONDSEP := CriaVar("C5_ZONDSEP", .F.)
				SC5->C5_ZSEQOND := CriaVar("C5_ZSEQOND", .F.)
				SC5->( MsUnLock() )

			EndIf


		Next _nX

		// se tem controle de numeracao
		If (__lSX8)
			ConfirmSX8()
		EndIf

	EndIf

	// realiza a gravação do Modelo
	_lTudoOk := FWFormCommit(oModel)

	// restaura posicao inicial das linhas
	FWRestRows( _aSaveLines )

Return( _lTudoOk )

// ** funcao de validacao antes de gravacao
Static Function bTudoOk(oModel)
	// variavel de retorno
	local _lTudoOk := .T.

	// posicao atual das linhas do browse
	Local _aSaveLines := FWSaveRows()
	// variaveis temporarias
	local _nX
	// modelos de cabecalho e itens
	Local _oModelCbZ57 := oModel:GetModel('Z57MASTER')
	Local _oModelItZ58 := oModel:GetModel('Z58DETAIL')

	//Operacao executada no modelo de dados.
	local _nOperation := oModel:GetOperation()

	// se for exclusao
	If (_lTudoOk) .And. (_nOperation == MODEL_OPERATION_DELETE)
		// retorno da funcao
		Return(_lTudoOk)
	EndIf

	// validacoes dos itens
	If (_lTudoOk)
		// varre todos os itens do browse
		For _nX := 1 to _oModelItZ58:Length()

			// posiciona na linha do browse
			_oModelItZ58:GoLine( _nX )

			// testa a linha deletada
			If ( ! _oModelItZ58:IsDeleted() )

				// cabecalho do pedido de venda
				dbSelectArea("SC5")
				SC5->(dbSetOrder(1)) // 1 - C5_FILIAL, C5_NUM
				If ! SC5->(dbSeek( xFilial("SC5") + _oModelItZ58:GetValue("Z58_PEDIDO") ))
					// avisa usuario
					Help( ,, 'TWMSA042.F01.001',, "Pedido de venda " + AllTrim(_oModelItZ58:GetValue("Z58_PEDIDO")) + " não localizado.", 1, 0 )
					// variavel de controle
					_lTudoOk := .F.
				EndIf

				// valida se o pedido pertecence ao cliente
				If (_lTudoOk) .And. ((SC5->C5_CLIENTE != _oModelItZ58:GetValue("Z58_CODCLI")) .Or. (SC5->C5_LOJACLI != _oModelItZ58:GetValue("Z58_LOJCLI")))
					// avisa usuario
					Help( ,, 'TWMSA042.F01.002',, "Pedido de venda " + AllTrim(_oModelItZ58:GetValue("Z58_PEDIDO")) + " não percente ao cliente informado. Verificar código e loja do cliente.", 1, 0 )
					// variavel de controle
					_lTudoOk := .F.
				EndIf

				// valida se o pedido eh de WMS
				If (_lTudoOk) .And. (SC5->C5_TIPOOPE != "P")
					// avisa usuario
					Help( ,, 'TWMSA042.F01.003',, "Pedido de venda " + AllTrim(_oModelItZ58:GetValue("Z58_PEDIDO")) + " não percente à operações de WMS.", 1, 0 )
					// variavel de controle
					_lTudoOk := .F.
				EndIf

				// valida se o pedido ja esta em outra onda de separacao
				If (_lTudoOk) .And. ( ! Empty(SC5->C5_ZONDSEP) ) .And. (SC5->C5_ZONDSEP != _oModelCbZ57:GetValue("Z57_CODIGO"))
					// avisa usuario
					Help( ,, 'TWMSA042.F01.004',, "Pedido de venda " + AllTrim(_oModelItZ58:GetValue("Z58_PEDIDO")) + " já vinculado na onda de separação " + SC5->C5_ZONDSEP, 1, 0 )
					// variavel de controle
					_lTudoOk := .F.
				EndIf

				// valida se o cliente está configurado para WMS versão 2
				If (_lTudoOk) .AND. !(U_FtWmsParam("WMS_VERSAO", "N", 1, .F., "", _oModelItZ58:GetValue("Z58_CODCLI")  , _oModelItZ58:GetValue("Z58_LOJCLI"), Nil, Nil) == 2)
					// avisa usuario
					Help( ,, 'TWMSA042.F01.005',, "Cliente " + AllTrim(mv_par01) + " não configurado para utilizar onda de separação (WMS 2.0).",;
					1, 0, NIL, NIL, NIL, NIL, NIL, {"Utilize a geração de ordem de serviço no formato CARGA"} )
					// variavel de controle
					_lTudoOk := .F.
				EndIf

			EndIf

		Next _nX

	EndIf

	// restaura posicao inicial das linhas
	FWRestRows( _aSaveLines )

Return( _lTudoOk )

// ** funcao de pre validacao do formulario
Static Function bPreVldForm(oModel)
	// variavel de retorno
	local _lTudoOk := .T.
	//Operacao executada no modelo de dados.
	local _nOperation := oModel:GetOperation()
	// status atual da solicitacao
	local _cAtuStatus := ""

	// se for ALTERACAO
	If (_lTudoOk) .And. (_nOperation == MODEL_OPERATION_UPDATE) .And. ( Z57->Z57_STATUS == "03" )
		// status atual da solicitacao
		_cAtuStatus := U_FtX3CBox("Z57_STATUS", Z57->Z57_STATUS, 2, 1)
		// avisa usuario
		Help( ,, 'TWMSA042.F04.001',, "Onda de Separação não pode ser ALTERADA, pois seu status atual é " + _cAtuStatus , 1, 0 )
		// variavel de controle
		_lTudoOk := .F.
	EndIf

	// se for EXCLUSAO
	If (_lTudoOk) .And. (_nOperation == MODEL_OPERATION_DELETE) .And. ( Z57->Z57_STATUS == "03" )
		// status atual da solicitacao
		_cAtuStatus := U_FtX3CBox("Z57_STATUS", Z57->Z57_STATUS, 2, 1)
		// avisa usuario
		Help( ,, 'TWMSA037.F04.002',, "Onda de Separação não pode ser EXCLUÍDA, pois seu status atual é " + _cAtuStatus , 1, 0 )
		// variavel de controle
		_lTudoOk := .F.
	EndIf

Return( _lTudoOk )

// ** funcao para planejamento em massa de onda de separacao
User Function WMSA042A

	// grupo de perguntas
	local _cPerg := PadR("WMSA042A", 10)
	local _aPerg := {}

	// armazena opcoes do menu
	Local _aRotBack := aClone( aRotina )

	// variável que informa se o cliente está na nova versão de WMS
	local _lWmsNovo

	// alias do arquivo temporario
	private _cNewAlias := GetNextAlias()

	// define grupo de perguntas/parametros
	aAdd(_aPerg,{"Cliente De"        , "C", TamSx3("A1_COD")[1]    , 0, "G", Nil, "SA1", {{"X1_VALID","U_FtStrZero()"}}}) //mv_par01
	aAdd(_aPerg,{"Loja De"           , "C", TamSx3("A1_LOJA")[1]   , 0, "G", Nil, "", Nil                              }) //mv_par02
	aAdd(_aPerg,{"Cliente Até"       , "C", TamSx3("A1_COD")[1]    , 0, "G", Nil, "SA1", {{"X1_VALID","U_FtStrZero()"}}}) //mv_par03
	aAdd(_aPerg,{"Loja Até"          , "C", TamSx3("A1_LOJA")[1]   , 0, "G", Nil, "", Nil                              }) //mv_par04
	aAdd(_aPerg,{"Data Emissão De"   , "D", TamSx3("C5_EMISSAO")[1], 0, "G", Nil, "", Nil                              }) //mv_par05
	aAdd(_aPerg,{"Data Emissão Até"  , "D", TamSx3("C5_EMISSAO")[1], 0, "G", Nil, "", Nil                              }) //mv_par06
	aAdd(_aPerg,{"Data Entrega De"   , "D", TamSx3("C5_EMISSAO")[1], 0, "G", Nil, "", Nil                              }) //mv_par07
	aAdd(_aPerg,{"Data Entrega Até"  , "D", TamSx3("C5_EMISSAO")[1], 0, "G", Nil, "", Nil                              }) //mv_par08
	aAdd(_aPerg,{"Prioridade De"     , "C", TamSx3("Z50_PRIORI")[1], 0, "G", Nil, "", Nil                              }) //mv_par09
	aAdd(_aPerg,{"Prioridade Até"    , "C", TamSx3("Z50_PRIORI")[1], 0, "G", Nil, "", Nil                              }) //mv_par10
	aAdd(_aPerg,{"Transportadora De" , "C", TamSx3("A4_COD")[1]    , 0, "G", Nil, "SA4", {{"X1_VALID","U_FtStrZero()"}}}) //mv_par11
	aAdd(_aPerg,{"Transportadora Até", "C", TamSx3("A4_COD")[1]    , 0, "G", Nil, "SA4", {{"X1_VALID","U_FtStrZero()"}}}) //mv_par12

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg, _aPerg)

	// chama a tela de parametros
	If ( ! Pergunte(_cPerg, .T.) )
		Return( .F. )
	EndIf

	// mensagem de controle temporario
	If (mv_par01 != mv_par03) .Or. (mv_par02 != mv_par04)
		// avisa usuario
		Help( ,, 'TWMSA042.F02.001',, "Versão da rotina configurada para geração de 1 (um) cliente por onda de separação.", 1, 0 )
		// retorno
		Return( .F. )
	EndIf

	_lWmsNovo := (U_FtWmsParam("WMS_VERSAO", "N", 1, .F., "", mv_par01, mv_par02, Nil, Nil) == 2)  

	// valida se o cliente está configurado para WMS versão 2
	If (!_lWmsNovo)
		// avisa usuario
		Help( ,, 'TWMSA042.F03.005',, "Cliente " + AllTrim(mv_par01) + " não configurado para utilizar onda de separação (WMS 2.0).",;
		1, 0, NIL, NIL, NIL, NIL, NIL, {"Utilize a geração de ordem de serviço no formato CARGA"} )
		// retorno
		Return( .F. )
	EndIf

	// funcao que atualiza os dados
	sfSelDados()

	// abre a tela com os dados
	sfTelaGeral()

	// ao retornar, atualiza aRotina (menus)
	aRotina := aClone( _aRotBack )

Return( Nil )

// ** funcao que carrega os dados da programacao
Static Function sfSelDados()

	// estrutura do arquivo de trabalho
	local _aStrTrbOnda := {}

	// query para filtro de dados
	local _cQuery

	// cria o arquivo de trabalho
	If (Select(_cNewAlias) == 0)

		// cria o arquivo de trabalho para o MarkBrowse
		aAdd(_aStrTrbOnda,{"IT_OK"    , "C", TamSx3("C5_OK")[1]     , 0})
		aAdd(_aStrTrbOnda,{"IT_PEDIDO", "C", TamSx3("C5_NUM")[1]    , 0})
		aAdd(_aStrTrbOnda,{"IT_PEDCLI", "C", TamSx3("C5_ZPEDCLI")[1], 0})
		aAdd(_aStrTrbOnda,{"IT_DOCCLI", "C", TamSx3("C5_ZDOCCLI")[1], 0})
		aAdd(_aStrTrbOnda,{"IT_PRIORI", "C", TamSx3("Z50_PRIORI")[1], 0})
		aAdd(_aStrTrbOnda,{"IT_CODCLI", "C", TamSx3("C5_CLIENTE")[1], 0})
		aAdd(_aStrTrbOnda,{"IT_LOJCLI", "C", TamSx3("C5_LOJACLI")[1], 0})

		// criar um arquivo de trabalho
		_cArqTmp := FWTemporaryTable():New( _cNewAlias )
		_cArqTmp:SetFields( _aStrTrbOnda )
		_cArqTmp:Create()

		// caso o arquivo exista, limpa os dados
	ElseIf (Select(_cNewAlias) <> 0)
		// limpa o conteudo do TRB
		(_cNewAlias)->(dbSelectArea(_cNewAlias))
		(_cNewAlias)->(__DbZap())

	EndIf

	// prepara query para filtro de dados
	_cQuery := " SELECT ''         IT_OK, "
	_cQuery += "        C5_NUM     IT_PEDIDO, "
	_cQuery += "        C5_ZPEDCLI IT_PEDCLI, "
	_cQuery += "        C5_ZDOCCLI IT_DOCCLI, "
	_cQuery += "        '001'      IT_PRIORI, "
	_cQuery += "        C5_CLIENTE IT_CODCLI, "
	_cQuery += "        C5_LOJACLI IT_LOJCLI "
	// pedido de venda
	_cQuery += " FROM   " + RetSqlTab("SC5") + " (nolock) "
	// filtro padrao
	_cQuery += " WHERE  " + RetSqlCond("SC5")
	// cliente e loja
	_cQuery += "        AND C5_CLIENTE BETWEEN '" + mv_par01 + "' AND '" + mv_par03 + "' "
	_cQuery += "        AND C5_LOJACLI BETWEEN '" + mv_par02 + "' AND '" + mv_par04 + "' "
	// tipo de operacao
	_cQuery += "        AND C5_TIPOOPE = 'P' "
	// data de emissao
	_cQuery += "        AND C5_EMISSAO BETWEEN '" + DtoS(mv_par05) + "' AND '" + DtoS(mv_par06) + "' "
	// que nao tenha nota fiscal emitida
	_cQuery += "        AND C5_NOTA = ' ' "
	// sem carga gerada
	_cQuery += "        AND C5_ZCARGA = ' ' "
	// sem onda de separacao gerada
	_cQuery += "        AND C5_ZONDSEP = ' ' "
	// transportadora
	_cQuery += "        AND C5_TRANSP BETWEEN '" + mv_par11 + "' AND '" + mv_par12 + "' "
	// ordem dos dados
	_cQuery += " ORDER  BY C5_NUM "

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery, _aStrTrbOnda, _cNewAlias)

Return

// ** funcao que monta tela (browse) com a relacao de pedidos
Static Function sfTelaGeral()

	// campos do browse
	local _aHeadBrw := {}
	// legenda
	local _aCorLegenda := {}

	// variaveis para o MarkBrowse
	Private _cTrbFlag := GetMark()

	// opcoes do menus
	Private aRotina := {;
	{ "Gerar Onda", "U_WMSA042B(), CloseBrowse()", 0 , 3} }

	// inclui detalhes e titulos dos campos do browse
	aAdd(_aHeadBrw,{"IT_OK"    , Nil,"  "                  , ""})
	aAdd(_aHeadBrw,{"IT_PEDIDO", Nil,"Nr.Pedido TECADI"    , ""})
	aAdd(_aHeadBrw,{"IT_PEDCLI", Nil,"Nr.Pedido Cliente"   , ""})
	aAdd(_aHeadBrw,{"IT_DOCCLI", Nil,"Nr.Nota Fiscal Venda", ""})

	// adiciona as cores da legenda
	aAdd(_aCorLegenda,{"((_cNewAlias)->IT_PRIORI == '001')", "BR_AZUL"   })
	aAdd(_aCorLegenda,{"((_cNewAlias)->IT_PRIORI == '002')", "BR_AMARELO"})
	aAdd(_aCorLegenda,{"((_cNewAlias)->IT_PRIORI == '003')", "ENABLE"    })
	aAdd(_aCorLegenda,{"((_cNewAlias)->IT_PRIORI == '004')", "DISABLE"   })

	// seleciona o arquivo de trabalho
	(_cNewAlias)->(dbSelectArea(_cNewAlias))
	(_cNewAlias)->(dbGotop())

	// mark browse com os itens a faturar
	MarkBrow((_cNewAlias), "IT_OK", Nil, _aHeadBrw, Nil, _cTrbFlag, "StaticCall(TWMSA042, sfMarkAll)", Nil, Nil, Nil, Nil, Nil, Nil, Nil, _aCorLegenda)

	// seleciona o arquivo de trabalho
	(_cNewAlias)->(dbSelectArea(_cNewAlias))
	(_cNewAlias)->(dbCloseArea())

Return( .T. )

// ** funcao que marca todos os itens quando clicar no header da coluna
Static Function sfMarkAll()

	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaTrb := (_cNewAlias)->(GetArea())

	// seleciona alias do aruivo de trabalho
	(_cNewAlias)->(DbSelectArea(_cNewAlias))
	(_cNewAlias)->(dbGoTop())

	// varre todos os itens do arquivo de trabalho
	While (_cNewAlias)->( ! Eof() )
		// attualiza campo de controle
		(_cNewAlias)->(RecLock(_cNewAlias, .F.))
		(_cNewAlias)->IT_OK := IIf((_cNewAlias)->IT_OK == _cTrbFlag, "", _cTrbFlag )
		(_cNewAlias)->(MsUnLock())
		// proximo item
		(_cNewAlias)->(DbSkip())
	EndDo

	// refresj no browse
	MarkBRefresh()

	// restaura area inicial
	RestArea(_aAreaTrb)
	RestArea(_aAreaAtu)

Return( .T. )

// ** funcao geral responsavel por gerar onda de separacao
User Function WMSA042B

	// dados da onda de separacao
	local _aCabOndSep := {}
	local _aItmOndSep := {}
	local _aTmpItem   := {}

	// controle sequencial
	local _nSeqPedido := 1

	// numero da onda de separacao
	local _cNrOndaSep := ""

	// seleciona a cria as tabelas
	dbSelectArea("Z57")
	dbSelectArea("Z58")

	// define conteudo para rotina automatica
	aAdd(_aCabOndSep, {"Z57_OBS", mv_par01, Nil})

	// seleciona alias do aruivo de trabalho
	(_cNewAlias)->(DbSelectArea(_cNewAlias))
	(_cNewAlias)->(dbGoTop())

	// varre todos os itens do arquivo de trabalho
	While (_cNewAlias)->( ! Eof() )
		// verifica se o item esta selecionado
		If ((_cNewAlias)->IT_OK == _cTrbFlag)

			// rotina automatica
			_aTmpItem  := {}

			// atualiza campos do item
			aAdd(_aTmpItem, {"Z58_SEQUEN", StrZero(_nSeqPedido, TamSx3("Z58_SEQUEN")[1]), Nil }) // sequencial
			aAdd(_aTmpItem, {"Z58_CODCLI", (_cNewAlias)->IT_CODCLI                      , Nil }) // codigo do cliente
			aAdd(_aTmpItem, {"Z58_LOJCLI", (_cNewAlias)->IT_LOJCLI                      , Nil }) // loja do cliente
			aAdd(_aTmpItem, {"Z58_PEDIDO", (_cNewAlias)->IT_PEDIDO                      , Nil }) // numero do pedido

			// se tem saldo, e dados do produto ok
			aAdd(_aItmOndSep, _aTmpItem)

		EndIf

		// proximo item
		(_cNewAlias)->(DbSkip())
	EndDo

	// padroniza dicionario de dados
	_aItmOndSep := FWVetByDic(_aItmOndSep, 'Z58', .T.)

	// reinicia variaveis
	lMsErroAuto := .F.

	// chama rotina automatica para geracao da solicitacao de carga
	MSExecAuto({|x,y,z| U_TWMSA042(x,y,z)}, _aCabOndSep, _aItmOndSep, 3)

	// em caso de erro ou validacao
	If ( ! lMsErroAuto )
		// numero da onda de separacao
		_cNrOndaSep := Z57->Z57_CODIGO

	ElseIf (lMsErroAuto)
		// mostra o erro
		MostraErro()

	EndIf

	// apresenta mensagem
	If ( ! Empty(_cNrOndaSep) )
		MsgInfo("Onda de separação " + _cNrOndaSep + " gerada com sucesso!")
	EndIf

Return

// ** funcao para gerar onda de separacao por pedido (permite chamada externa)
User Function WMSA042C(mvStatus, mvOpcAuto)

	// armazena opcoes do menu
	Local _aRotBack := aClone( aRotina )

	// dados da onda de separacao
	local _aCabOndSep := {}
	local _aItmOndSep := {}
	local _aTmpItem   := {}

	// controle sequencial
	local _nSeqPedido := 1

	// numero da onda de separacao
	local _cNrOndaSep := ""

	// variavel de retorno
	local _lTudoOk := .T.

	// variável que informa se o cliente está na nova versão de WMS
	local _lWmsNovo := (U_FtWmsParam("WMS_VERSAO", "N", 1, .F., "", SC5->C5_CLIENTE, SC5->C5_LOJACLI, Nil, Nil) == 2)  

	// valores padroes
	Default mvStatus  := "01" // 01 - Em Revisão
	Default mvOpcAuto := 3    // 3 - Inclusao

	// valida se o cliente está configurado para WMS versão 2
	If (_lTudoOk) .And. (!_lWmsNovo)
		// avisa usuario
		Help( ,, 'TWMSA042.F03.005',, "Cliente " + AllTrim(SC5->C5_CLIENTE) + " não configurado para utilizar onda de separação (WMS 2.0).",;
		1, 0, NIL, NIL, NIL, NIL, NIL, {"Utilize a geração de ordem de serviço no formato CARGA"} )
		// variavel de controle
		_lTudoOk := .F.
	EndIf

	// valida se o pedido eh de WMS
	If (_lTudoOk) .And. (SC5->C5_TIPOOPE != "P")
		// avisa usuario
		Help( ,, 'TWMSA042.F03.001',, "Pedido de venda " + AllTrim(SC5->C5_NUM) + " não percente à operações de WMS.", 1, 0 )
		// variavel de controle
		_lTudoOk := .F.
	EndIf

	// valida se o pedido ja esta em outra onda de separacao
	If (_lTudoOk) .And. (mvOpcAuto == 3) .And. ( ! Empty(SC5->C5_ZONDSEP) )
		// avisa usuario
		Help( ,, 'TWMSA042.F03.002',, "Pedido de venda " + AllTrim(SC5->C5_NUM) + " já vinculado na onda de separação " + SC5->C5_ZONDSEP, 1, 0 )
		// variavel de controle
		_lTudoOk := .F.
	EndIf

	// valida se o pedido ja esta vinculado a alguma carga
	If (_lTudoOk) .And. ( ! Empty(SC5->C5_ZCARGA) )
		// avisa usuario
		Help( ,, 'TWMSA042.F03.003',, "Pedido de venda " + AllTrim(SC5->C5_NUM) + " já vinculado na carga " + SC5->C5_ZCARGA, 1, 0 )
		// variavel de controle
		_lTudoOk := .F.
	EndIf

	// valida se o pedido ja esta vinculado a alguma carga
	If (_lTudoOk) .And. ( ! Empty(SC5->C5_NOTA) )
		// avisa usuario
		Help( ,, 'TWMSA042.F03.004',, "Pedido de venda " + AllTrim(SC5->C5_NUM) + " já faturado", 1, 0 )
		// variavel de controle
		_lTudoOk := .F.
	EndIf

	// se dados ok, prepara informacoes da rotina automatica
	If (_lTudoOk) .And. (mvOpcAuto == 3)

		// seleciona a cria as tabelas
		dbSelectArea("Z57")
		dbSelectArea("Z58")

		// define conteudo para rotina automatica
		aAdd(_aCabOndSep, {"Z57_STATUS", mvStatus                     , Nil})
		aAdd(_aCabOndSep, {"Z57_OBS"   , "Chamado por Pedido de Venda", Nil})

		// rotina automatica
		_aTmpItem  := {}

		// atualiza campos do item
		aAdd(_aTmpItem, {"Z58_SEQUEN", StrZero(_nSeqPedido, TamSx3("Z58_SEQUEN")[1]), Nil }) // sequencial
		aAdd(_aTmpItem, {"Z58_CODCLI", SC5->C5_CLIENTE                              , Nil }) // codigo do cliente
		aAdd(_aTmpItem, {"Z58_LOJCLI", SC5->C5_LOJACLI                              , Nil }) // loja do cliente
		aAdd(_aTmpItem, {"Z58_PEDIDO", SC5->C5_NUM                                  , Nil }) // numero do pedido

		// se tem saldo, e dados do produto ok
		aAdd(_aItmOndSep, _aTmpItem)

		// padroniza dicionario de dados
		_aItmOndSep := FWVetByDic(_aItmOndSep, 'Z58', .T.)

		// reinicia variaveis
		lMsErroAuto := .F.

		// chama rotina automatica para geracao da solicitacao de carga
		MSExecAuto({|x,y,z| U_TWMSA042(x,y,z)}, _aCabOndSep, _aItmOndSep, 3)

		// em caso de erro ou validacao
		If ( ! lMsErroAuto )
			// numero da onda de separacao
			_cNrOndaSep := Z57->Z57_CODIGO

		ElseIf (lMsErroAuto)
			// mostra o erro
			MostraErro()
			// variavel de controle
			_lTudoOk := .F.

		EndIf

		// apresenta mensagem
		If ( ! Empty(_cNrOndaSep) )
			MsgInfo("Onda de separação " + _cNrOndaSep + " gerada com sucesso!")
		EndIf

	EndIf

	// ao retornar, atualiza aRotina (menus)
	aRotina := aClone( _aRotBack )

Return( _lTudoOk )

// ** funcao para geracao de mapa de expedicao
User Function WMSA042D()

	// status atual da solicitacao
	local _cAtuStatus := U_FtX3CBox("Z57_STATUS", Z57->Z57_STATUS, 2, 1)

	// valida status
	If (Z57->Z57_STATUS == "02")
		// converte em ordem de servico
		U_TWMSA019( Nil, Z57->Z57_CODIGO, .T.)

	ElseIf (Z57->Z57_STATUS != "02")
		// mensagem para usuario
		Help( ,, 'TWMSA042.F05.001',, "Ordem de Serviço de Expedição não pode ser gerado, pois status atual da Onda de Separação é " + _cAtuStatus , 1, 0 )

	EndIf

Return

// ** funcao para liberacao de conversao das solicitacoes de carga
User Function WMSA042E(mvNewStatus)
	// status atual da solicitacao
	local _cAtuStatus := U_FtX3CBox("Z57_STATUS", Z57->Z57_STATUS, 2, 1)
	// status atual
	local _cStsAtual := Z57->Z57_STATUS

	// valida status -> 02-Liberado para Integração
	If (mvNewStatus == "02") .And. (Z57->Z57_STATUS == "01")

		// mensagem de confirmacao
		If (MsgYesNo("Confirma a LIBERAÇÃO da Onda para Planejamento de Mapa de Expedição ?"))

			// atualiza campo de controle
			dbSelectArea("Z57")
			RecLock("Z57", .F.)
			Z57->Z57_STATUS := "02" // 02-Liberado para Integração
			Z57->(MsUnLock())

			// gera log
			U_FtGeraLog(xFilial("Z57"), "Z57", Z57->Z57_FILIAL + Z57->Z57_CODIGO, "LIBERADO - Onda Liberada para Planejamento (Atual: " + _cStsAtual + "| Novo: " + mvNewStatus + ")", "CFG", "")

		EndIf

	Else
		// mensagem para usuario
		Help( ,, 'TWMSA042.F04.001',, "Onda de Separação não pode ser liberada, pois seu status atual é " + _cAtuStatus , 1, 0 )

	EndIf

Return

// ** funcao para estorno do mapa da onda de separacao
User Function WMSA042F
	// status atual da solicitacao
	local _cAtuStatus := U_FtX3CBox("Z57_STATUS", Z57->Z57_STATUS, 2, 1)
	// status atual
	local _cStsAtual := Z57->Z57_STATUS

	// valida status
	If (Z57->Z57_STATUS == "03")

		// pesquisa pela ordem de servico
		dbSelectArea("Z05")
		Z05->( dbSetOrder(5) ) // 5 - Z05_FILIAL, Z05_ONDSEP
		If ! Z05->( dbSeek( xFilial("Z05") + Z57->Z57_CODIGO ))
			// mensagem para usuario
			Help( ,, 'TWMSA042.F05.002',, "Mapa de Expedição não pode ser ESTORNADO, pois seu status atual é " + _cAtuStatus , 1, 0 )
			// retorno
			Return( .F. )
		EndIf

		// mensagem de confirmacao
		If (MsgYesNo("Confirma o ESTORNO do Mapa de Expedição da Onda de Separação?"))

			// funcao generica para exclusao de ordem de servico
			U_WMSA009H(Z05->Z05_NUMOS, .T.)

		EndIf

	Else
		// mensagem para usuario
		Help( ,, 'TWMSA042.F05.001',, "Mapa de Expedição não pode ser ESTORNADO, pois seu status atual é " + _cAtuStatus , 1, 0 )

	EndIf

Return