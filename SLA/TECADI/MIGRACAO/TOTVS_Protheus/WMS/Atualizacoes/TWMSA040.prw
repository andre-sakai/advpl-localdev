#Include "Totvs.ch"
#Include "Protheus.ch"
#Include 'FWMVCDEF.CH'
#include "tbiconn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Cadastro das etiquetas do cliente de identificação da   !
!                  ! mercadoria                                              !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 04/2018 !
+------------------+--------------------------------------------------------*/

User Function TWMSA040(mvCabAuto, mvItmAuto, mvOpcAuto)

	// objeto browse
	Local _oBrwCadEtiq := Nil

	// variaveis de controle de rotina automatica
	Local _lRotAuto   := (ValType(mvCabAuto) == "A") .And. (ValType(mvItmAuto) == "A")
	Local _aAutoCab   := {}
	Local _aAutoItens := {}

	// cabecalho e itens
	dbSelectArea("Z55")
	dbSelectArea("Z56")

	// titulo
	Private cCadastro := "Cadastro das etiquetas do cliente de identificação da mercadoria"

	// controle de opcoes do menu
	Private aRotina := MenuDef()

	// se for rotina automatica
	If (_lRotAuto)
		// define variaveis
		_aAutoCab   := aClone( mvCabAuto )
		_aAutoItens := aClone( mvItmAuto )

		// chamada da rotina automatica através do MVC
		FwMvcRotAuto(ModelDef(), "Z55", mvOpcAuto, { { "Z55MASTER", _aAutoCab }, { "Z56DETAIL", _aAutoItens }  } )

		// fecha processo
		Return
	EndIf

	// cria objeto do browse
	_oBrwCadEtiq := FWMBrowse():New()
	_oBrwCadEtiq:SetAlias('Z55')
	_oBrwCadEtiq:SetDescription(cCadastro)

	// define funcao executada para tecla de atalho F5
	SetKey(VK_F5,{|| _oBrwCadEtiq:Refresh() })

	// ativa objeto browse
	_oBrwCadEtiq:Activate()

	// define funcao executada para tecla de atalho F5
	SetKey(VK_F5, Nil)

Return

// ** funcao para definir o menu
Static Function MenuDef()
	// variavel de retorno
	Local _aRetMenu := {}

	aAdd(_aRetMenu,{'Pesquisar'          , 'PesqBrw'         , 0, 1, 0, .F. })
	aAdd(_aRetMenu,{'Visualizar'         , 'VIEWDEF.TWMSA040', 0, 2, 0, Nil })
	aAdd(_aRetMenu,{'Incluir'            , 'VIEWDEF.TWMSA040', 0, 3, 0, Nil })
	aAdd(_aRetMenu,{'Alterar'            , 'VIEWDEF.TWMSA040', 0, 4, 0, Nil })
	aAdd(_aRetMenu,{'Excluir'            , 'VIEWDEF.TWMSA040', 0, 5, 0, Nil })
	aAdd(_aRetMenu,{'Definir Nota Fiscal', 'U_WMSA040A()'    , 0, 4, 0, Nil })

Return(_aRetMenu)

// ModelDef - Modelo padrao para MVC
Static Function ModelDef()

	// variaveis para modelo
	Local _oModel    := Nil
	Local _oStrCbZ55 := Nil
	Local _oStrItZ56 := Nil
	Local _aRelacZ56 := {}

	// define estruturas
	_oStrCbZ55 := FwFormStruct( 1, "Z55", Nil )
	_oStrItZ56 := FwFormStruct( 1, "Z56", Nil )

	// remove obrigatoriedade de campos chaves
	_oStrItZ56:SetProperty('Z56_REMESS', MODEL_FIELD_OBRIGAT, .F.)
	_oStrItZ56:SetProperty('Z56_CODCLI', MODEL_FIELD_OBRIGAT, .F.)
	_oStrItZ56:SetProperty('Z56_LOJCLI', MODEL_FIELD_OBRIGAT, .F.)
	_oStrItZ56:SetProperty('Z56_NOTA'  , MODEL_FIELD_OBRIGAT, .F.)
	_oStrItZ56:SetProperty('Z56_SERIE' , MODEL_FIELD_OBRIGAT, .F.)
	_oStrItZ56:SetProperty('Z56_ITEMNF', MODEL_FIELD_OBRIGAT, .F.)

	// Cria o formulario
	_oModel := MpFormModel():New("MD_TWMSA040", /* bPreValid(oModel) */, { |oModel| bTudoOk(oModel) }, { |oModel| bCommit(oModel) }, /*bCancel*/)
	_oModel:SetDescription(cCadastro)

	// validação de ativação do modelo
	_oModel:SetVldActivate( { |oModel| bPreVldForm(oModel) } )

	// define campos do cabecalho
	_oModel:AddFields("Z55MASTER", Nil, _oStrCbZ55, /*prevalid*/ ,, /*bCarga*/ )
	_oModel:SetPrimaryKey({'Z55_FILIAL', 'Z55_REMESS' })

	// modelo do grid
	_oModel:AddGrid("Z56DETAIL", "Z55MASTER", _oStrItZ56 , /*bLinePre*/ , /*bLinePost*/ , /*bPre*/ , /*bPost*/, /*bLoad*/)

	// relacionamento da tabela Cabecalho x Itens
	aAdd(_aRelacZ56,{'Z56_FILIAL', 'xFilial("Z56")'})
	aAdd(_aRelacZ56,{'Z56_REMESS', 'Z55_REMESS'    })
	aAdd(_aRelacZ56,{'Z56_CODCLI', 'Z55_CODCLI'    })
	aAdd(_aRelacZ56,{'Z56_LOJCLI', 'Z55_LOJCLI'    })

	// Faz relaciomaneto entre os compomentes do model
	_oModel:SetRelation("Z56DETAIL", _aRelacZ56, Z56->( IndexKey(1) ))

	// Liga o controle de nao repeticao de linha
	_oModel:GetModel("Z56DETAIL"):SetUniqueLine( {'Z56_ETQCLI'} )

	// seta quantidade maxima de linhas por GRID
	_oModel:GetModel("Z56DETAIL"):SetMaxLine(10000)

	// Adiciona a descricao do Componente do Modelo de Dados
	_oModel:GetModel('Z55MASTER'):SetDescription('Detalhes da Remessa de Etiquetas do Cliente')
	_oModel:GetModel('Z56DETAIL'):SetDescription('Itens da Remessa de Etiquetas do Cliente')

Return( _oModel )

// ** Função que define a interface do cadastro de Solicitacao de Cargas para o MVC
Static Function ViewDef()

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local _oModel := FWLoadModel('TWMSA040')
	Local _oView  := Nil
	// Cria a estrutura a ser usada na View
	Local _oStrZ55 := FWFormStruct( 2, 'Z55', Nil )
	Local _oStrZ56 := FWFormStruct( 2, 'Z56', Nil )

	// Remove campos da estrutura
	_oStrZ56:RemoveField( 'Z56_REMESS' )
	_oStrZ56:RemoveField( 'Z56_CODCLI' )
	_oStrZ56:RemoveField( 'Z56_LOJCLI' )

	// Cria o objeto de View
	_oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	_oView:SetModel( _oModel )

	// Adiciona no nosso View um controle do tipo FormFields (antiga enchoice)
	_oView:AddField('VIEW_Z55', _oStrZ55, 'Z55MASTER')

	// Adiciona no nosso View um controle do tipo FormGrid (antiga newgetdados)
	_oView:AddGrid('VIEW_Z56', _oStrZ56, 'Z56DETAIL')

	// define campo incremental do grid
	_oView:AddIncrementField('VIEW_Z56', 'Z56_SEQUEN')

	// Criar "box" horizontal para receber algum elemento da view
	_oView:CreateHorizontalBox('SUPERIOR' , 40 )
	_oView:CreateHorizontalBox('INFERIOR' , 60 )

	// Relaciona o ID da View com o "box" para exibicao
	_oView:SetOwnerView('VIEW_Z55', 'SUPERIOR')
	_oView:SetOwnerView('VIEW_Z56', 'INFERIOR')

	// Liga a identificacao do componente
	_oView:EnableTitleView( 'VIEW_Z55' )
	_oView:EnableTitleView( 'VIEW_Z56' )

Return(_oView)

// ** funcao dentro do commit para gravacao de dados complementares
Static Function bCommit(oModel)
	// variavel de retorno
	local _lTudoOk := .T.

	// modelos de cabecalho e itens
	local _oModelCbZ55 := oModel:GetModel('Z55MASTER')
	local _oModelItZ56 := oModel:GetModel('Z56DETAIL')

	// variaveis temporarias
	local _nX

	// posicao atual das linhas do browse
	local _aSaveLines := FWSaveRows()

	//Operacao executada no modelo de dados.
	local _nOperation := oModel:GetOperation()

	// conteudo para geracao da etiqueta
	local _aTmpConteudo := {}

	// numero da etiqueta
	local _cEtqCliente

	// codigo da etiqueta registrada internamente
	local _cCodEtiq

	// codigo e loja do cliente
	local _cCodCli
	local _cLojCli

	// controle se etiqueta ja registrada
	local _lEtqJaReg := .F.

	// seek
	local _cSeekZ11

	// se for exclusao
	If (_lTudoOk) .And. (_nOperation == MODEL_OPERATION_DELETE)

		// varre todos os itens do browse
		For _nX := 1 to _oModelItZ56:Length()

			// posiciona na linha do browse
			_oModelItZ56:GoLine( _nX )

			// etiqueta de controle interno
			_cCodEtiq := _oModelItZ56:GetValue("Z56_CODETI")

			// codigo e loja do cliente
			_cCodCli := _oModelCbZ55:GetValue("Z55_CODCLI")
			_cLojCli := _oModelCbZ55:GetValue("Z55_LOJCLI")

			// verifica se etiqueta ja existe
			dbSelectArea("Z11")
			Z11->(dbSetOrder(1)) // 1 - Z11_FILIAL, Z11_CODETI
			Z11->(dbSeek( _cSeekZ11 := xFilial("Z11") + _cCodEtiq ))

			// varre todas as etiquetas com a mesma chave de pesquisa
			While (Z11->( ! Eof() )) .And. ((Z11->Z11_FILIAL + Z11->Z11_CODETI) == _cSeekZ11) .And. (Z11->Z11_TIPO == "07")

				// valida cliente
				If (Z11->Z11_CLIENT == _cCodCli) .And. (Z11->Z11_LOJA == _cLojCli)

					// exclui etiqueta
					RecLock("Z11", .F.)
					Z11->(DbDelete())
					Z11->(MsUnLock())

				EndIf

				// proximo registro
				Z11->( dbSkip() )
			EndDo

		Next _nX

		// realiza a gravação do Modelo
		_lTudoOk := FWFormCommit(oModel)

		// retorno da funcao
		Return( _lTudoOk )
	EndIf

	// se for inclusao
	If (_lTudoOk) .And. ((_nOperation == MODEL_OPERATION_INSERT) .Or. (_nOperation == MODEL_OPERATION_UPDATE))

		// varre todos os itens do browse
		For _nX := 1 to _oModelItZ56:Length()

			// reinicia variaveis
			_lEtqJaReg := .F.

			// posiciona na linha do browse
			_oModelItZ56:GoLine( _nX )

			// etiqueta do cliente
			_cEtqCliente := _oModelItZ56:GetValue("Z56_ETQCLI")

			// codigo e loja do cliente
			_cCodCli := _oModelCbZ55:GetValue("Z55_CODCLI")
			_cLojCli := _oModelCbZ55:GetValue("Z55_LOJCLI")

			// estrutura do vetor mvConteudo
			//  1 - Cod Cliente
			//  2 - Loja Cliente
			//  3 - Nf - Tipo
			//  4 - Nf - Numero
			//  5 - Nf - Serie
			//  6 - Nf - Item/Sequencia
			//  7 - Nf - Cod Produto/Item
			//  8 - Nf - NumSeq
			//  9 - Nf - Quantidade
			// 10 - Nf - Lote
			// 11 - Nf - Processo
			// 12 - Numero da Etiqueta

			// conteudo passado como parametro
			_aTmpConteudo := {                   ;
			_cCodCli                            ,; //  1
			_cLojCli                            ,; //  2
			""                                  ,; //  3
			_oModelItZ56:GetValue("Z56_NOTA")   ,; //  4
			_oModelItZ56:GetValue("Z56_SERIE")  ,; //  5
			""                                  ,; //  6
			_oModelItZ56:GetValue("Z56_CODPRO") ,; //  7
			""                                  ,; //  8
			_oModelItZ56:GetValue("Z56_QUANT")  ,; //  9
			_oModelItZ56:GetValue("Z56_LOTCTL") ,; // 10
			""                                  ,; // 11
			_cEtqCliente                         } // 12

			// verifica se etiqueta ja existe
			dbSelectArea("Z11")
			Z11->(dbSetOrder(2)) // 2 - Z11_FILIAL, Z11_ETIQUE, Z11_CLIENT, Z11_LOJA
			If Z11->(dbSeek( _cSeekZ11 := xFilial("Z11") + _cEtqCliente + _cCodCli + _cLojCli )) .AND. !( Empty(_cEtqCliente) )
				_lEtqJaReg := .T.
			EndIf

			// se for uma atualização dos dados, pode ser que a etiqueta tenha sido deletada pelo usuário, então vamos excluí-la
			If ( _oModelItZ56:IsDeleted() ) .And. (_lEtqJaReg)
				// varre todas as etiquetas com a mesma chave de pesquisa
				While (Z11->( ! Eof() )) .And. ((Z11->Z11_FILIAL + Z11->Z11_ETIQUE + Z11->Z11_CLIENT + Z11->Z11_LOJA) == _cSeekZ11)

					// exclui etiqueta
					RecLock("Z11", .F.)
					Z11->(DbDelete())
					Z11->(MsUnLock())

					// proximo registro
					Z11->( dbSkip() )
				EndDo
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
	Local _oModelCbZ55 := oModel:GetModel('Z55MASTER')
	Local _oModelItZ56 := oModel:GetModel('Z56DETAIL')

	//Operacao executada no modelo de dados.
	local _nOperation := oModel:GetOperation()

	// sigla do cliente
	local _cCliSigla := CriaVar("A1_SIGLA", .F.)

	// se for exclusao
	If (_lTudoOk) .And. (_nOperation == MODEL_OPERATION_DELETE)
		// retorno da funcao
		Return(_lTudoOk)
	EndIf

	// posiciona e valida cadastro do cliente
	If (_lTudoOk)
		// cadastro do cliente
		dbSelectArea("SA1")
		SA1->(dbSetOrder(1)) // 1-A1_FILIAL, A1_COD, A1_LOJA
		If ( ! SA1->(dbSeek( xFilial("SA1") + _oModelCbZ55:GetValue("Z55_CODCLI") + _oModelCbZ55:GetValue("Z55_LOJCLI") )))
			// avisa usuario
			Help( ,, 'TWMSA040.F01.001',, "Cadastro do cliente não é válido.", 1, 0 )
			// variavel de controle
			_lTudoOk := .F.
		Else
			// sigla do cliente
			_cCliSigla := SA1->A1_SIGLA

		EndIf
	EndIf

	// validacoes dos itens
	If (_lTudoOk)

		// varre todos os itens do browse
		For _nX := 1 to _oModelItZ56:Length()

			// posiciona na linha do browse
			_oModelItZ56:GoLine( _nX )

			// testa a linha deletada
			If ( ! _oModelItZ56:IsDeleted() )

				// cadastro do produto
				dbSelectArea("SB1")
				SB1->(dbSetOrder(1))
				SB1->(dbSeek( xFilial("SB1") + _oModelItZ56:GetValue("Z56_CODPRO") ))

				// valida se o produto pertece ao depositante
				If (_lTudoOk) .And. (_cCliSigla != SB1->B1_GRUPO)
					// avisa usuario
					Help( ,, 'TWMSA040.F01.002',, "O Produto/Sku " + AllTrim(_oModelItZ56:GetValue("Z56_CODPRO")) + " não pertence à este Cliente/Depositante.", 1, 0 )
					// variavel de controle
					_lTudoOk := .F.
				EndIf

				// valida se a etiqueta informada nao esta em duplicidade
				If (_lTudoOk)

					// tabela de etiquetas do cliente
					dbSelectArea("Z56")
					Z56->( DbSetOrder(2) ) // 2- Z56_FILIAL, Z56_ETQCLI, Z56_CODCLI, Z56_LOJCLI, R_E_C_N_O_, D_E_L_E_T_
					If Z56->( DbSeek( xFilial("Z56") + _oModelItZ56:GetValue("Z56_ETQCLI") + _oModelCbZ55:GetValue("Z55_CODCLI") + _oModelCbZ55:GetValue("Z55_LOJCLI") ) )
						// valida tambem numero da remessa
						// avisa usuario
						If (Z56->Z56_OK_SAI != "S")
							Help( ,, 'TWMSA040.F01.003',, "A etiqueta " + AllTrim(_oModelItZ56:GetValue("Z56_ETQCLI")) + " já está registrada. Operação não permitida.", 1, 0 )
							// variavel de controle
							_lTudoOk := .F.
						EndIf
					EndIf

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

	// modelos de cabecalho e itens
	Local _oModelCbZ55 := oModel:GetModel('Z55MASTER')
	Local _oModelItZ56 := oModel:GetModel('Z56DETAIL')

	//Operacao executada no modelo de dados.
	local _nOperation := oModel:GetOperation()

Return( _lTudoOk )

// ** funcao para definir/preencher nota fiscal, serie e item
User Function WMSA040A

	// variavel de retorno
	local _lRetOk := .F.

	// atualizado algum campo
	local _lDadosAlt := .F.

	// seek dos dados
	local _cSeekZ56

	// numero da remessa
	local _cNrRemessa := Z55->Z55_REMESS

	// grupo de perguntas
	local _cPerg := PadR("WMSA040A", 10)

	// chama a tela de parametros
	If ( ! Pergunte(_cPerg,.T.) )
		Return(_lRetOk)
	EndIf

	// busca os item da remessa
	dbSelectArea("Z56")
	Z56->( DbSetOrder(1) ) // 1 - Z56_FILIAL, Z56_REMESS, Z56_SEQUEN
	Z56->( DbSeek( _cSeekZ56 := xFilial("Z56") + _cNrRemessa ) )

	// varre todos os itens do arquivo de remessa
	While Z56->( ! Eof() ) .And. ((Z56->Z56_FILIAL + Z56->Z56_REMESS) == _cSeekZ56)

		// valida sequencias
		If (Z56->Z56_SEQUEN >= mv_par04) .And. ((Z56->Z56_SEQUEN <= mv_par05)) .And. (Z56->Z56_OK_ENT == "N") .And. (Z56->Z56_OK_SAI == "N")

			// atualiza dados da nota
			RecLock("Z56")
			// numero da nota
			If ( ! Empty(mv_par01) )
				// atualiza conteudo
				Z56->Z56_NOTA := mv_par01
				// controle de campo alterado
				_lDadosAlt := .T.
			EndIf
			// serie da nota
			If ( ! Empty(mv_par02) )
				// atualiza conteudo
				Z56->Z56_SERIE := mv_par02
				// controle de campo alterado
				_lDadosAlt := .T.
			EndIf
			// item da nota
			If ( ! Empty(mv_par03) )
				// atualiza conteudo
				Z56->Z56_ITEMNF := mv_par03
				// controle de campo alterado
				_lDadosAlt := .T.
			EndIf
			Z56->( MsUnLock() )

			// verifica se etiqueta ja existe
			dbSelectArea("Z11")
			Z11->(dbSetOrder(2)) // 2 - Z11_FILIAL, Z11_ETIQUE, Z11_CLIENT, Z11_LOJA
			If Z11->(dbSeek( xFilial("Z11") + Z56->Z56_ETQCLI + Z55->Z55_CODCLI + Z55->Z55_LOJCLI ))

				// atualiza dados da nota
				RecLock("Z11", .F.)
				Z11->Z11_DOC    := Z56->Z56_NOTA
				Z11->Z11_SERIE  := Z56->Z56_SERIE
				Z11->Z11_ITEMNF := Z56->Z56_ITEMNF
				Z11->(MsUnLock())

			EndIf

		EndIf

		// variavel geral de atualizacao
		_lRetOk := _lDadosAlt

		// proximo item
		Z56->( DbSkip() )
	EndDo

	// apresenta mensagem
	If (_lRetOk)
		MsgInfo("Dados alterados com sucesso!")
	ElseIf ( ! _lRetOk )
		MsgAlert("Nenhuma informação foi alterada. Verifique os parâmetros.")
	EndIf

Return(_lRetOk)