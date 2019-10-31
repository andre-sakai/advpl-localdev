#Include "Totvs.ch"
#Include "Protheus.ch"
#Include 'FWMVCDEF.CH'
#include "tbiconn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina de controle de solicitacoes de cargas (expedicao)!
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 02/2018 !
+------------------+---------------------------------------------------------+
!Observacoes       ! Z50_STATUS: 01-Em Revisão                               !
!                  !             02-Liberado para Integração                 !
!                  !             03-Com Problemas                            !
!                  !             04-Cancelado                                !
!                  !             05-Integrado com Sucesso                    !
!                  !             06-Cortado                                  !
!                  !             07-Anulado                                  !
!                  ! Z51_STATUS: 01-Em Revisão                               !
!                  !             02-Liberado para Integração                 !
!                  !             03-Com Problemas                            !
!                  !             04-Cancelado                                !
!                  !             05-Integrado com Sucesso                    !
!                  !             06-Cortado                                  !
!                  !             07-Anulado                                  !
+------------------+--------------------------------------------------------*/

User Function TWMSA037(mvCabAuto, mvItmAuto, mvOpcAuto)

	// objeto browse
	Local _oBrwSolCarga := Nil

	// variaveis de controle de rotina automatica
	Local _lRotAuto   := (ValType(mvCabAuto) == "A") .And. (ValType(mvItmAuto) == "A")
	Local _aAutoCab   := {}
	Local _aAutoItens := {}

	// cabecalho e itens
	dbSelectArea("Z50")
	dbSelectArea("Z51")

	// titulo
	Private cCadastro := "Controle de Solicitações de Cargas"

	// controle de opcoes do menu
	Private aRotina := MenuDef()

	// se for rotina automatica
	If (_lRotAuto)
		// define variaveis
		_aAutoCab   := aClone( mvCabAuto )
		_aAutoItens := aClone( mvItmAuto )
/*
		ConOut(PadC("WMSA037Z - ANTES!", 80))

		ConOut(PadC("WMSA037Z - ValType(mvCabAuto) - " + ValType(mvCabAuto), 80))
		ConOut(PadC("WMSA037Z - ValType(_aAutoCab) - " + ValType(_aAutoCab), 80))
		ConOut(PadC("WMSA037Z - ValType(mvItmAuto) - " + ValType(mvItmAuto), 80))
		ConOut(PadC("WMSA037Z - ValType(_aAutoItens) - " + ValType(_aAutoItens), 80))
		ConOut(PadC("WMSA037Z - ValType(mvOpcAuto) - " + ValType(mvOpcAuto), 80))
*/
		// chamada da rotina automatica através do MVC
		FwMvcRotAuto(ModelDef(), "Z50", mvOpcAuto, { { "Z50MASTER", _aAutoCab }, { "Z51DETAIL", _aAutoItens }  } )

//		ConOut(PadC("WMSA037Z - DEPOIS!", 80))

		// fecha processo
		Return
	EndIf

	// cria objeto do browse
	_oBrwSolCarga := FWMBrowse():New()
	_oBrwSolCarga:SetAlias('Z50')
	_oBrwSolCarga:SetDescription(cCadastro)

	// define cores do browse
	_oBrwSolCarga:AddLegend("Z50_STATUS == '01'", "BR_AZUL"    )
	_oBrwSolCarga:AddLegend("Z50_STATUS == '02'", "BR_AMARELO" )
	_oBrwSolCarga:AddLegend("Z50_STATUS == '03'", "BR_VERMELHO")
	_oBrwSolCarga:AddLegend("Z50_STATUS == '04'", "BR_PRETO"   )
	_oBrwSolCarga:AddLegend("Z50_STATUS == '05'", "BR_VERDE"   )
	_oBrwSolCarga:AddLegend("Z50_STATUS == '06'", "BR_LARANJA" )
	_oBrwSolCarga:AddLegend("Z50_STATUS == '07'", "BR_BRANCO"  )

	// cria um filtro fixo para todos
	_oBrwSolCarga:AddFilter("Liberado para Integração", "Z50_STATUS == '02'", .F., .T., "Z50", .F., {}, "SOLCAR_LIBERA" )
	_oBrwSolCarga:AddFilter("Em Revisão"              , "Z50_STATUS == '01'", .F., .F., "Z50", .F., {}, "SOLCAR_EM_REV" )
	_oBrwSolCarga:AddFilter("Com Problemas"           , "Z50_STATUS == '03'", .F., .F., "Z50", .F., {}, "SOLCAR_ERRO"   )
	_oBrwSolCarga:AddFilter("Cancelada"               , "Z50_STATUS == '04'", .F., .F., "Z50", .F., {}, "SOLCAR_CANCEL" )
	_oBrwSolCarga:AddFilter("Integrada Com Sucesso"   , "Z50_STATUS == '05'", .F., .F., "Z50", .F., {}, "SOLCAR_INT_OK" )
	_oBrwSolCarga:AddFilter("Cortado"                 , "Z50_STATUS == '06'", .F., .F., "Z50", .F., {}, "SOLCAR_CORTADO")
	_oBrwSolCarga:AddFilter("Anulado"                 , "Z50_STATUS == '07'", .F., .F., "Z50", .F., {}, "SOLCAR_ANULADO")

	// define funcao executada para tecla de atalho F5
	SetKey(VK_F5,{|| _oBrwSolCarga:Refresh() })

	// ativa objeto browse
	_oBrwSolCarga:Activate()

	// define funcao executada para tecla de atalho F5
	SetKey(VK_F5, Nil)

Return

// ** funcao para definir o menu
Static Function MenuDef()
	// variavel de retorno
	Local _aRetMenu := {}

	aAdd(_aRetMenu,{'Pesquisar'                  , 'PesqBrw'         , 0, 1, 0, .F. })
	aAdd(_aRetMenu,{'Visualizar'                 , 'VIEWDEF.TWMSA037', 0, 2, 0, Nil })
	aAdd(_aRetMenu,{'Incluir'                    , 'VIEWDEF.TWMSA037', 0, 3, 0, Nil })
	aAdd(_aRetMenu,{'Alterar'                    , 'VIEWDEF.TWMSA037', 0, 4, 0, Nil })
	aAdd(_aRetMenu,{'Excluir'                    , 'VIEWDEF.TWMSA037', 0, 5, 0, Nil })
	aAdd(_aRetMenu,{'Liberar para Conversão'     , 'U_WMSA037A("02")', 0, 8, 0, Nil })
	aAdd(_aRetMenu,{'Único - Converter em Pedido', 'U_WMSA037B()'    , 0, 9, 0, Nil })
	aAdd(_aRetMenu,{'Lista - Converter em Pedido', 'U_WMSA038A()'    , 0,10, 0, Nil })
	aAdd(_aRetMenu,{'Anular solicitação'         , 'U_WMSA037A("07")', 0, 8, 0, Nil })
	aAdd(_aRetMenu,{'Consulta Log'               , 'U_WMSA037C()'    , 0, 2, 0, Nil })
	aAdd(_aRetMenu,{'Reenvio de E-mail'          , 'U_WMSA037D()'    , 0, 8, 0, Nil })

Return(_aRetMenu)

// ModelDef - Modelo padrao para MVC
Static Function ModelDef()

	// variaveis para modelo
	Local _oModel    := Nil
	Local _oStrCbZ50 := Nil
	Local _oStrItZ51 := Nil
	Local _aRelacZ51 := {}

	// define estruturas
	_oStrCbZ50 := FwFormStruct( 1, "Z50", Nil )
	_oStrItZ51 := FwFormStruct( 1, "Z51", Nil )

	// Cria o formulario
	_oModel := MpFormModel():New("MD_TWMSA037", /* bPreValid(oModel) */, { |oModel| bTudoOk(oModel) }, { |oModel| bCommit(oModel) }, /*bCancel*/)
	_oModel:SetDescription(cCadastro)

	// validação de ativação do modelo
	_oModel:SetVldActivate( { |oModel| bPreVldForm(oModel) } )

	// define campos do cabecalho
	_oModel:AddFields("Z50MASTER", Nil, _oStrCbZ50, /*prevalid*/ ,, /*bCarga*/ )
	_oModel:SetPrimaryKey({'Z50_FILIAL', 'Z50_NUMSOL' })

	// modelo do grid
	_oModel:AddGrid("Z51DETAIL", "Z50MASTER", _oStrItZ51 , /*bLinePre*/ , /*bLinePost*/ , /*bPre*/ , /*bPost*/, /*bLoad*/)

	// relacionamento da tabela Cabecalho x Itens
	aAdd(_aRelacZ51,{'Z51_FILIAL', 'xFilial("Z51")'})
	aAdd(_aRelacZ51,{'Z51_NUMSOL', 'Z50_NUMSOL'    })

	// Faz relaciomaneto entre os compomentes do model
	_oModel:SetRelation("Z51DETAIL", _aRelacZ51, Z51->( IndexKey(1) ))

	// Liga o controle de nao repeticao de linha
	_oModel:GetModel("Z51DETAIL"):SetUniqueLine( {'Z51_ITEM', 'Z51_CODPRO', 'Z51_LOTE', 'Z51_TPESTO'} )

	// Adiciona a descricao do Componente do Modelo de Dados
	_oModel:GetModel('Z50MASTER'):SetDescription('Detalhes da Solicitação de Carga')
	_oModel:GetModel('Z51DETAIL'):SetDescription('Itens da Solicitação de Carga')

Return( _oModel )

// ** Função que define a interface do cadastro de Solicitacao de Cargas para o MVC
Static Function ViewDef()

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local _oModel := FWLoadModel('TWMSA037')
	Local _oView  := Nil
	// Cria a estrutura a ser usada na View
	Local _oStrZ50 := FWFormStruct( 2, 'Z50', Nil )
	Local _oStrZ51 := FWFormStruct( 2, 'Z51', Nil )

	// Remove campos da estrutura
	_oStrZ51:RemoveField( 'Z51_NUMSOL' )

	// Cria o objeto de View
	_oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	_oView:SetModel( _oModel )

	// Adiciona no nosso View um controle do tipo FormFields (antiga enchoice)
	_oView:AddField('VIEW_Z50', _oStrZ50, 'Z50MASTER')

	// Adiciona no nosso View um controle do tipo FormGrid (antiga newgetdados)
	_oView:AddGrid('VIEW_Z51', _oStrZ51, 'Z51DETAIL')

	// define campo incremental do grid
	_oView:AddIncrementField('VIEW_Z51', 'Z51_ITEM')

	// Criar "box" horizontal para receber algum elemento da view
	_oView:CreateHorizontalBox('SUPERIOR' , 40 )
	_oView:CreateHorizontalBox('INFERIOR' , 60 )

	// Relaciona o ID da View com o "box" para exibicao
	_oView:SetOwnerView('VIEW_Z50', 'SUPERIOR')
	_oView:SetOwnerView('VIEW_Z51', 'INFERIOR')

	// Liga a identificacao do componente
	_oView:EnableTitleView( 'VIEW_Z50' )
	_oView:EnableTitleView( 'VIEW_Z51' )

Return(_oView)

// ** funcao dentro do commit para gravacao de dados complementares
Static Function bCommit(oModel)
	// variavel de retorno
	local _lTudoOk := .T.

	// modelos de cabecalho e itens
	local _oModelCbZ50 := oModel:GetModel('Z50MASTER')
	local _oModelItZ51 := oModel:GetModel('Z51DETAIL')

	// variaveis temporarias
	local _nX

	// posicao atual das linhas do browse
	local _aSaveLines := FWSaveRows()

	//Operacao executada no modelo de dados.
	local _nOperation := oModel:GetOperation()

	// se for exclusao
	If (_lTudoOk) .And. (_nOperation == MODEL_OPERATION_DELETE)
		// realiza a gravação do Modelo
		_lTudoOk := FWFormCommit(oModel)
		// retorno da funcao
		Return( _lTudoOk )
	EndIf

	// se for inclusao
	If (_lTudoOk) .And. (_nOperation == MODEL_OPERATION_INSERT)

		// varre todos os itens do browse
		For _nX := 1 to _oModelItZ51:Length( .T. )

			// posiciona na linha do browse
			_oModelItZ51:GoLine( _nX )

			// testa a linha deletada
			If ( ! _oModelItZ51:IsDeleted() )

				// atualiza quantidade disponivel igual a quantidade solicitada
				_oModelItZ51:SetValue("Z51_QTDDIS", _oModelItZ51:GetValue("Z51_QTDSOL"))

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
	Local _oModelCbZ50 := oModel:GetModel('Z50MASTER')
	Local _oModelItZ51 := oModel:GetModel('Z51DETAIL')

	//Operacao executada no modelo de dados.
	local _nOperation := oModel:GetOperation()

	// sigla do cliente
	local _cCliSigla := CriaVar("A1_SIGLA", .F.)

	// se for exclusao
	If (_lTudoOk) .And. (_nOperation == MODEL_OPERATION_DELETE)
		Return(_lTudoOk)
	EndIf

	// posiciona e valida cadastro do cliente
	If (_lTudoOk)
		// cadastro do cliente
		dbSelectArea("SA1")
		SA1->(dbSetOrder(1)) // 1-A1_FILIAL, A1_COD, A1_LOJA
		If ( ! SA1->(dbSeek( xFilial("SA1") + _oModelCbZ50:GetValue("Z50_CODCLI") + _oModelCbZ50:GetValue("Z50_LOJCLI") )))
			// avisa usuario
			Help( ,, 'TWMSA037.F01.001',, "Cadastro do cliente não é válido.", 1, 0 )
			// variavel de controle
			_lTudoOk := .F.
		Else
			// sigla do cliente
			_cCliSigla := SA1->A1_SIGLA
		EndIf
	EndIf

	// posiciona e valida cadastro do cliente
	If ( _lTudoOk ) .AND. ( Empty(_oModelCbZ50:GetValue("Z50_PEDCLI")) )
		// avisa usuario
		Help( ,, 'TWMSA037.F01.005',, "Número do pedido do cliente não informado.", 1, 0 )
		// variavel de controle
		_lTudoOk := .F.
	EndIf

	// verifica se pedido já foi importado
	If (_lTudoOk)
		dbSelectArea("SC6")
		SC6->(dbSetOrder(11)) // 11-C6_FILIAL, C6_CLI, C6_LOJA, C6_PEDCLI

		If SC6->(dbSeek(  xFilial("SC6") + _oModelCbZ50:GetValue("Z50_CODCLI") + _oModelCbZ50:GetValue("Z50_LOJCLI") + _oModelCbZ50:GetValue("Z50_PEDCLI")  ))
			// avisa usuario
			Help( ,, 'TWMSA037.F01.004',, "Pedido do cliente duplicado / já importado.", 1, 0 )
			// variavel de controle
			_lTudoOk := .F.
		EndIf
	EndIf

	// validacoes dos itens
	If (_lTudoOk)

		// varre todos os itens do browse
		For _nX := 1 to _oModelItZ51:Length( .T. )

			// posiciona na linha do browse
			_oModelItZ51:GoLine( _nX )

			// testa a linha deletada
			If ( ! _oModelItZ51:IsDeleted() )

				// cadastro do produto
				dbSelectArea("SB1")
				SB1->(dbSetOrder(1))
				SB1->(dbSeek( xFilial("SB1") + _oModelItZ51:GetValue("Z51_CODPRO") ))

				// valida se o produto pertece ao depositante
				If (_lTudoOk) .And. (_cCliSigla != SB1->B1_GRUPO)
					// avisa usuario
					Help( ,, 'TWMSA037.F01.002',, "O Produto/Sku " + AllTrim(_oModelItZ51:GetValue("Z51_CODPRO")) + " não pertence à este Cliente/Depositante.", 1, 0 )
					// variavel de controle
					_lTudoOk := .F.
				EndIf

				// valida quantidade solicitada X quantidade disponivel
				If (_lTudoOk) .And. (_oModelItZ51:GetValue("Z51_QTDSOL") < _oModelItZ51:GetValue("Z51_QTDDIS"))
					// avisa usuario
					Help( ,, 'TWMSA037.F01.003',, "A quantidade DISPONÍVEL não pode ser MAIOR que a quantidade SOLICITADA.", 1, 0 )
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
	If (_lTudoOk) .And. (_nOperation == MODEL_OPERATION_UPDATE) .And. ( Z50->Z50_STATUS $ "04|05" )
		// status atual da solicitacao
		_cAtuStatus := U_FtX3CBox("Z50_STATUS", Z50->Z50_STATUS, 2, 1)
		// avisa usuario
		Help( ,, 'TWMSA037.F02.001',, "Solicitação de Cargas não pode ser ALTERADA, pois seu status atual é " + _cAtuStatus , 1, 0 )
		// variavel de controle
		_lTudoOk := .F.
	EndIf

	// se for EXCLUSAO
	If (_lTudoOk) .And. (_nOperation == MODEL_OPERATION_DELETE) .And. ( Z50->Z50_STATUS $ "04|05" )
		// status atual da solicitacao
		_cAtuStatus := U_FtX3CBox("Z50_STATUS", Z50->Z50_STATUS, 2, 1)
		// avisa usuario
		Help( ,, 'TWMSA037.F02.003',, "Solicitação de Cargas não pode ser EXCLUÍDA, pois seu status atual é " + _cAtuStatus , 1, 0 )
		// variavel de controle
		_lTudoOk := .F.
	EndIf

Return( _lTudoOk )

// ** funcao para chamada da rotina de conversao para pedido de venda
User Function WMSA037B()
	// numero do pedido gerado
	local _cNewPedido := ""
	// retorno da funcao
	local _lRetOk := .F.

	// rotina para conversao de Solicitacao de Carga em Pedido de Venda
	FwMsgRun(, {|_lFim| _lRetOk := U_TWMSA038(.F., @_lFim, Z50->Z50_NUMSOL, @_cNewPedido) }, "Processamento", "Aguarde a finalização do processamento...")

	// tratamento do retorno da funcao
	If (_lRetOk)
		MsgInfo("Pedido de Venda " + _cNewPedido + " gerado com sucesso!")
	ElseIf ( ! _lRetOk )
		MsgAlert("Inconsistência na validação dos dados da Solicitação de Carga. Favor consultar o Log.")
	EndIf

Return

// ** funcao para liberacao de conversao das solicitacoes de carga
User Function WMSA037A(mvNewStatus)
	// status atual da solicitacao
	local _cAtuStatus := U_FtX3CBox("Z50_STATUS", Z50->Z50_STATUS, 2, 1)
	// seek
	local _cSeekZ51
	// itens ok
	local _lItensOk := .F.

	// status atual
	local _cStsAtual := ""

	// valida status -> 02-Liberado para Integração
	If (mvNewStatus == "02") .And. (Z50->Z50_STATUS $ "01|03")

		// mensagem de confirmacao
		If (MsgYesNo("Confirma a LIBERAÇÃO da solicitação para conversão em pedido?"))

			// pesquisa e varre todos os itens da solicitacao de carga
			dbSelectArea("Z51")
			Z51->(dbSetOrder(1)) // 1 - Z51_FILIAL, Z51_NUMSOL, Z51_ITEM
			Z51->(dbSeek( _cSeekZ51 := xFilial("Z51") + Z50->Z50_NUMSOL ))

			// loop dos itens
			While Z51->( ! Eof() ) .And. ((Z51->Z51_FILIAL + Z51->Z51_NUMSOL) == _cSeekZ51)

				// valida status de itens disponiveis
				If (Z50->Z50_STATUS $ "01|02|03")
					// atualiza campo de controle
					dbSelectArea("Z51")
					RecLock("Z51", .F.)
					Z51->Z51_STATUS := "02" // 02-Liberado para Integração
					Z51->(MsUnLock())
					// variaveis de controle
					_lItensOk := .T.
				EndIf

				// proximo item
				dbSelectArea("Z51")
				Z51->(dbSkip())
			EndDo

			// status atual
			_cStsAtual := Z50->Z50_STATUS

			// atualiza campo de controle
			If (_lItensOk)
				dbSelectArea("Z50")
				RecLock("Z50", .F.)
				Z50->Z50_STATUS := "02" // 02-Liberado para Integração
				Z50->(MsUnLock())
			EndIf

			// gera log
			U_FtGeraLog(xFilial("Z50"), "Z50", Z50->Z50_FILIAL + Z50->Z50_NUMSOL, "LIBERADO - Solicitação Liberada para Conversão (Atual: " + _cStsAtual + "| Novo: " + mvNewStatus + ")", "CFG", "")

		EndIf

		// valida status -> 02-Liberado para Integração
	ElseIf (mvNewStatus == "07") .And. (Z50->Z50_STATUS $ "01|03")

		// mensagem de confirmacao
		If (MsgYesNo("Confirma a ANULAÇÃO da solicitação de cargas?"))

			// pesquisa e varre todos os itens da solicitacao de carga
			dbSelectArea("Z51")
			Z51->(dbSetOrder(1)) // 1 - Z51_FILIAL, Z51_NUMSOL, Z51_ITEM
			Z51->(dbSeek( _cSeekZ51 := xFilial("Z51") + Z50->Z50_NUMSOL ))

			// loop dos itens
			While Z51->( ! Eof() ) .And. ((Z51->Z51_FILIAL + Z51->Z51_NUMSOL) == _cSeekZ51)

				// valida status de itens disponiveis
				If (Z50->Z50_STATUS $ "01|02|03")
					// atualiza campo de controle
					dbSelectArea("Z51")
					RecLock("Z51", .F.)
					Z51->Z51_STATUS := "07" // 07-Anulado
					Z51->(MsUnLock())
					// variaveis de controle
					_lItensOk := .T.
				EndIf

				// proximo item
				dbSelectArea("Z51")
				Z51->(dbSkip())
			EndDo

			// status atual
			_cStsAtual := Z50->Z50_STATUS

			// atualiza campo de controle
			If (_lItensOk)
				dbSelectArea("Z50")
				RecLock("Z50", .F.)
				Z50->Z50_STATUS := "07" // 07-Anulado
				Z50->(MsUnLock())
			EndIf

			// gera log
			U_FtGeraLog(xFilial("Z50"), "Z50", Z50->Z50_FILIAL + Z50->Z50_NUMSOL, "ANULADO - Solicitação Anulada (Atual: " + _cStsAtual + "| Novo: " + mvNewStatus + ")", "CFG", "")

		EndIf

	Else
		// mensagem para usuario
		Help( ,, 'TWMSA037.F03.001',, "Solicitação de Cargas não pode ser liberada, pois seu status atual é " + _cAtuStatus , 1, 0 )

	EndIf

Return

// ** funcao para consultar log de processamento
User Function WMSA037C
	// mostra a função padrão de consulta de Log
	U_FtConsLog(Z50->Z50_FILIAL, "Z50", Z50->Z50_FILIAL + Z50->Z50_NUMSOL)
Return

// ** funcao para reenvio de email de confirmacao
User Function WMSA037D
	// status necessario para envio de email
	local _cStatusObr := U_FtX3CBox("Z50_STATUS", "05", 2, 1)
	// retorno da funcao
	local _lRetOk := .T.

	// valida status de integrado com sucesso
	If (_lRetOk) .And. (Z50->Z50_STATUS != "05")
		// avisa usuario
		Help( ,, 'TWMSA037.F04.001',, "Reenvio não pode ser executado pois o status da solicitação é diferente de " + _cStatusObr, 1, 0 )
		// retorno
		_lRetOk := .F.
	EndIf

	// status de integrado com sucesso
	If (_lRetOk) .And. (Z50->Z50_STATUS == "05")

		// envia mensagem por email
		StaticCall(TWMSA038, sfEnviaMail)

	EndIf

Return( _lRetOk )