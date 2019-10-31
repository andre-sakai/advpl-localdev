#INCLUDE "TOTVS.CH"
#Include 'FWMVCDEF.CH'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Gestao de Fotos Operacionais - AppFotos                 !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 09/2017 !
+------------------+---------------------------------------------------------+
!Observacoes       ! Legenda do Status Z6_FOTO                               !
!                  !   N = NAO PRECISA                                       !
!                  !   P = PENDENTE ENVIO                                    !
!                  !   R = REALIZADO                                         !
!                  !   C = CANCELADO                                         !
!                  !   O = EM OPERACAO                                       !
+------------------+--------------------------------------------------------*/

User Function TWMSA036()

	// objeto browse
	Local _oBrwOrdSrv

	// botoes da rotina
	Private aRotina	:= MenuDef()

	// variaveis necessarias para funcao padrao AxCadastro
	private cCadastro := "Gestão de Fotos Operacionais"

	// cria objeto do browse
	_oBrwOrdSrv:= FWMBrowse():New()
	_oBrwOrdSrv:SetAlias("SZ6")
	_oBrwOrdSrv:SetDescription( OemToAnsi(cCadastro) )
	_oBrwOrdSrv:DisableDetails()
	_oBrwOrdSrv:DisableConfig()
	_oBrwOrdSrv:DisableLocate()

	// filtro padrao
	_oBrwOrdSrv:SetFilterDefault("@( (Z6_FOTO != 'N') AND (Z6_EMISSAO >= '20170901') AND (Z6_SEQOS = '001') )")

	// define cores do browse
	_oBrwOrdSrv:AddLegend("( (Z6_FOTO == 'P') .and. (   Empty(Z6_USRFOTO)) )", "BR_VERMELHO")
	_oBrwOrdSrv:AddLegend("( (Z6_FOTO == 'P') .and. ( ! Empty(Z6_USRFOTO)) )", "BR_AMARELO" )
	_oBrwOrdSrv:AddLegend("( (Z6_FOTO == 'R') .and. ( ! Empty(Z6_USRFOTO)) )", "BR_VERDE"   )
	_oBrwOrdSrv:AddLegend("( (Z6_FOTO == 'C') .and. ( ! Empty(Z6_USRFOTO)) )", "BR_PRETO"   )
	_oBrwOrdSrv:AddLegend("( (Z6_FOTO == 'O') .and. ( ! Empty(Z6_USRFOTO)) )", "BR_AZUL"    )

	// cria um filtro fixo para todos
	_oBrwOrdSrv:AddFilter("Não Atribuido"    , "( (Z6_FOTO == 'P') .and. (   Empty(Z6_USRFOTO)) )", .f., .f., "SZ6", .f., {}, "ID_NAO_ATRIB"  )
	_oBrwOrdSrv:AddFilter("Pendente de Envio", "( (Z6_FOTO == 'P') .and. ( ! Empty(Z6_USRFOTO)) )", .f., .f., "SZ6", .f., {}, "ID_PEND_ENVIO" )
	_oBrwOrdSrv:AddFilter("Realizado"        , "( (Z6_FOTO == 'R') .and. ( ! Empty(Z6_USRFOTO)) )", .f., .f., "SZ6", .f., {}, "ID_REALIZADO"  )
	_oBrwOrdSrv:AddFilter("Cancelado"        , "( (Z6_FOTO == 'C') .and. ( ! Empty(Z6_USRFOTO)) )", .f., .f., "SZ6", .f., {}, "ID_CANCELADO"  )
	_oBrwOrdSrv:AddFilter("Em Operação"      , "( (Z6_FOTO == 'O') .and. ( ! Empty(Z6_USRFOTO)) )", .f., .f., "SZ6", .f., {}, "ID_EM_OPERACAO")

	// ativa browse/objeto
	_oBrwOrdSrv:Activate()

Return

// ** funcao para filtrar dados das fotos das ordens de servicos
Static Function sfGetFotos(mvNumOs, mvValida, mvColsFotos)
	// variaveis temporarias
	Local _cQuery  := ""

	// prepara query para apresentar a relacao de fotos que serao enviadas ao App
	_cQuery := " SELECT DISTINCT Z25_CODFOT, "
	_cQuery += "                 Z23_DESCRI, "
	_cQuery += "                 Z25_QUANT, "
	_cQuery += "                 Z25_OBRIGA, "
	_cQuery += "                 Z25_ORDEM, "
	_cQuery += "                 '.F.' IT_DEL "
	_cQuery += " FROM   " + RetSqlTab("SZ7")
	_cQuery += "        INNER JOIN " + RetSqlTab("SZ6")
	_cQuery += "                ON " + RetSqlCond("SZ6")
	_cQuery += "                   AND Z6_NUMOS = Z7_NUMOS "
	_cQuery += "        INNER JOIN " + RetSqlTab("Z25")
	_cQuery += "                ON " + RetSqlCond("Z25")
	_cQuery += "                   AND Z25_ORIGEM = 'SZ6' "
	_cQuery += "                   AND Z25_SERVIC = Z7_CODATIV "
	_cQuery += "                   AND Z25_CODCLI = Z6_CLIENTE "
	_cQuery += "                   AND Z25_LOJCLI = Z6_LOJA "
	_cQuery += "        INNER JOIN " + RetSqlTab("Z23")
	_cQuery += "                ON " + RetSqlCond("Z23")
	_cQuery += "                   AND Z23_CODIGO = Z25_CODFOT "
	_cQuery += " WHERE  " + RetSqlCond("SZ7")
	_cQuery += "        AND Substring(Z7_NUMOS, 1, 6) = '" + mvNumOs + "' "

	MemoWrit("c:\query\twmsa036_sfGetFotos.txt", _cQuery)

	// atualiza variavel com dados das fotos
	mvColsFotos := U_SqlToVet(_cQuery)

Return(Len(mvColsFotos) != 0)

// ** funcao para filtrar dados dos log´s das ordens de servicos
Static Function sfGetLog(mvNumOs)
	// variaveis temporarias
	Local _cQuery  := ""
	// variavel de retorno
	local _aRet := {}

	// prepara query para apresentar a relacao de log das operacoes de fotos
	_cQuery := " SELECT ZN_DATA, "
	_cQuery += "        ZN_HORA, "
	_cQuery += "        ZN_NOME, "
	_cQuery += "        ZN_DESCRI, "
	_cQuery += "        '.F.' IT_DEL "
	_cQuery += " FROM   " + RetSqlTab("SZN")
	_cQuery += " WHERE  " + RetSqlCond("SZN")
	_cQuery += "        AND ZN_TABELA = 'SZ6' "
	_cQuery += "        AND Charindex('" + xFilial("SZ6") + mvNumOs + "', ZN_CHAVE) > 0 "
	_cQuery += " ORDER BY ZN_DATA, ZN_HORA "

	MemoWrit("c:\query\twmsa036_sfGetLog.txt", _cQuery)

	// atualiza variavel com dados das fotos
	_aRet := U_SqlToVet(_cQuery, {"ZN_DATA"})

Return(_aRet)

// ** funcao para atribuir uma ordem de servico para operadores
User Function WMSA036A(mvNumOs)
	// variavel de controle
	local _lRet := .t.
	// recno para atualizacao
	local _nRegAtu
	// campos que serao apresentados na tela
	local _aCposVis := {"NOUSER", "Z6_TIPOMOV", "Z6_NUMOS", "Z6_CONTAIN", "Z6_EMISSAO", "Z6_CLIENTE", "Z6_LOJA", "Z6_FOTO", "Z6_USRFOTO"}
	// campos que serao alterados na tela
	local _aCposAlt := {"Z6_USRFOTO"}
	// opcao da confirmacao da tela
	local _nOpcSel := 0
	// seek
	local _cSeek
	// codigo do usuario definido
	local _cUsrFoto

	// inicio da numeracao da ordem de servico
	local _cNumOrdSrv := SubStr(mvNumOs, 1, 6)

	// pesquisa ordem de servico
	If (_lRet)
		dbSelectArea("SZ6")
		SZ6->( DbSetOrder(1) ) // 1-Z6_FILIAL, Z6_NUMOS, Z6_CLIENTE, Z6_LOJA
		If ! SZ6->( DbSeek( xFilial("SZ6") + _cNumOrdSrv ))
			// mensagem
			MsgStop("Ordem de Serviço " + _cNumOrdSrv + " não localizada. Verifique a Origem e Chave da Ordem de Serviço.")
			// variavel de controle
			_lRet := .f.
		EndIf
	EndIf

	// valida status de fotos por ordem de servico
	If (_lRet)

		// status N-NÃO PRECISA
		If (SZ6->Z6_FOTO == "N")
			// mensagem
			MsgStop("Está Ordem de Serviço não permite atribuição, pois seu STATUS é N = NAO PRECISA")
			// variavel de controle
			_lRet := .f.

			// status R = REALIZADO
		ElseIf (SZ6->Z6_FOTO == "R")
			// mensagem
			MsgStop("Está Ordem de Serviço não permite atribuição, pois seu STATUS é R = REALIZADO")
			// variavel de controle
			_lRet := .f.

			// status C = CANCELADO
		ElseIf (SZ6->Z6_FOTO == "C")
			// mensagem
			MsgStop("Está Ordem de Serviço não permite atribuição, pois seu STATUS é C = CANCELADO")
			// variavel de controle
			_lRet := .f.

			// status O = EM OPERACAO
		ElseIf (SZ6->Z6_FOTO == "O")
			// mensagem
			MsgStop("Está Ordem de Serviço não permite atribuição, pois seu STATUS é O = EM OPERACAO")
			// variavel de controle
			_lRet := .f.

			// status P = PENDENTE ENVIO
		ElseIf ( ! Empty(SZ6->Z6_USRFOTO)) .and.  (SZ6->Z6_FOTO == "P")
			// mensagem
			MsgStop("Está Ordem de Serviço não permite atribuição, pois seu STATUS é P = PENDENTE ENVIO")
			// variavel de controle
			_lRet := .f.

		EndIf

	EndIf

	// valida, se para este cliente e ordem de servio, tem fotos
	If (_lRet)
		// valida fotos
		If ( ! sfGetFotos(_cNumOrdSrv, .t., Nil) )
			// mensagem
			MsgStop("Não há relação de fotos configuradas para está ordem de serviço x cliente. Verifique o cadastro de Fotos x Serviços x Cliente.")
			// variavel de controle
			_lRet := .f.
		EndIf
	EndIf

	// se encontroum atualiza Recno
	If (_lRet)
		_nRegAtu := SZ6->( Recno() )
	EndIf

	// chama rotina padrao de alteraca de dados
	If (_lRet)
		// tela padrao de alteracao de dados
		_nOpcSel := AxAltera("SZ6", _nRegAtu, 3, _aCposVis, _aCposAlt)
		// armazena codigo do usuario
		_cUsrFoto := SZ6->Z6_USRFOTO
	EndIf

	// esta esta ok, e foi confirmado, atualiza dados
	If (_lRet) .and. (_nOpcSel == 1)
		dbSelectArea("SZ6")
		SZ6->( DbSetOrder(1) ) // 1-Z6_FILIAL, Z6_NUMOS, Z6_CLIENTE, Z6_LOJA
		SZ6->( DbSeek( _cSeek := xFilial("SZ6") + _cNumOrdSrv ))

		// varre todas as sequencias da ordem de servico
		While SZ6->( ! Eof() ) .and. (SZ6->(Z6_FILIAL + Z6_NUMOS) >= _cSeek) .and. (SZ6->(Z6_FILIAL + Z6_NUMOS) <= _cSeek + "999")

			// atualiza campos
			RecLock("SZ6")
			SZ6->Z6_USRFOTO := _cUsrFoto
			SZ6->Z6_FOTO    := "P" // P = PENDENTE ENVIO
			SZ6->(MsUnLock())

			// proximo item
			SZ6->(dbSkip())
		EndDo
	EndIf

	// gera log
	U_FtGeraLog(xFilial("SZ6"), "SZ6", SZ6->Z6_FILIAL + SZ6->Z6_NUMOS, "AppFotos: Ordem de Serviço Atribuida para " + SZ6->Z6_USRFOTO + " - " + AllTrim(UsrFullName(SZ6->Z6_USRFOTO)) + " Status PENDENTE ENVIO", "WMS", SZ6->Z6_CODIGO)

Return(_lRet)

// ** funcao para visualizar as fotos da ordem de servico
User Function WMSA036B
	// variavel de controle
	local _lRet := .t.
	// recno para atualizacao
	local _nRegAtu

	// pesquisa ordem de servico
	If (_lRet)
		dbSelectArea("SZ6")
		SZ6->( DbSetOrder(1) ) // 1-Z6_FILIAL, Z6_NUMOS, Z6_CLIENTE, Z6_LOJA
		If ! SZ6->( DbSeek( xFilial("SZ6") + _cNumOrdSrv ))
			// mensagem
			MsgStop("Ordem de Serviço " + _cNumOrdSrv + " não localizada. Verifique a Origem e Chave da Ordem de Serviço.")
			// variavel de controle
			_lRet := .f.
		EndIf
	EndIf

	// valida status de fotos por ordem de servico
	If (_lRet)

		// status diferente de R = REALIZADO
		If (SZ6->Z6_FOTO != "R")
			// mensagem
			MsgStop("Está Ordem de Serviço não permite visualização de fotos, pois não foi executada, realizada ou concluída.")
			// variavel de controle
			_lRet := .f.

		EndIf

	EndIf

	// valida status de fotos por ordem de servico
	If (_lRet)
		// abre o navegador
		ShellExecute("open", AllTrim(SZ6->Z6_LINKFOT), "", "", 5)
	EndIf

Return(_lRet)

// ** funcao para definir o menu
Static Function MenuDef()

	// variavel de retorno
	local _aRetMenu := {}

	ADD OPTION _aRetMenu TITLE 'Pesquisar'  ACTION 'PesqBrw'                   OPERATION 1 ACCESS 0
	ADD OPTION _aRetMenu TITLE 'Visualizar' ACTION 'VIEWDEF.TWMSA036'          OPERATION 2 ACCESS 0
	ADD OPTION _aRetMenu TITLE 'Atribuir'   ACTION 'U_WMSA036A(SZ6->Z6_NUMOS)' OPERATION 4 ACCESS 0
	ADD OPTION _aRetMenu TITLE 'Detalhes'   ACTION 'U_WMSA036C(SZ6->Z6_NUMOS)' OPERATION 4 ACCESS 0
	ADD OPTION _aRetMenu TITLE 'Legenda'    ACTION 'U_WMSA036E()'              OPERATION 4 ACCESS 0

Return (_aRetMenu)

// ** funcao que Monta a Legenda
User Function WMSA036E()

	// funcao padrao para lengendas
	BrwLegenda(cCadastro,;
	"Status " + cCadastro,{;
	{"BR_VERMELHO", "Não Atribuido"     },;
	{"BR_AMARELO" , "Pendente de Envio" },;
	{"BR_VERDE"   , "Realizado"         },;
	{"BR_PRETO"   , "Cancelado"         },;
	{"BR_AZUL"    , "Em Operação"       }})

Return .T.

// ** funcao que mostra a lista de fotos
User Function WMSA036C(mvNumOs)
	// variavel de controle
	local _lRet := .t.
	// seek
	local _cSeek
	// inicio da numeracao da ordem de servico
	local _cNumOrdSrv := SubStr(mvNumOs, 1, 6)

	// dimensoes da tela
	local _aSizeDlg := MsAdvSize()

	// variaveis do browse de fotos
	local _aHeadFotos := {}
	local _aColsFotos := {}

	// variaveis do browse de log
	local _aHeadLogOp := {}
	local _aColsLogOp := {}

	// objetos da tela
	local _oDlg01Fotos
	local _oLay01
	local _oPnlSup, _oPnlInf
	local _oBr01Fotos, _oBr01LogOp

	// pesquisa ordem de servico
	If (_lRet)
		dbSelectArea("SZ6")
		SZ6->( DbSetOrder(1) ) // 1-Z6_FILIAL, Z6_NUMOS, Z6_CLIENTE, Z6_LOJA
		If ! SZ6->( DbSeek( xFilial("SZ6") + _cNumOrdSrv ))
			// mensagem
			MsgStop("Ordem de Serviço " + _cNumOrdSrv + " não localizada. Verifique a Origem e Chave da Ordem de Serviço.")
			// variavel de controle
			_lRet := .f.
		EndIf
	EndIf

	// valida, se para este cliente e ordem de servio, tem fotos
	If (_lRet)
		// valida fotos
		If ( ! sfGetFotos(_cNumOrdSrv, .f., @_aColsFotos) )
			// mensagem
			MsgStop("Não há relação de fotos configuradas para está ordem de serviço x cliente. Verifique o cadastro de Fotos x Serviços x Cliente.")
			// variavel de controle
			_lRet := .f.
		EndIf
	EndIf

	// consulta log das operacoes
	If (_lRet)
		// consulta log da operacao
		_aColsLogOp := sfGetLog(_cNumOrdSrv)
	EndIf


	// se ha dados, apresenta tela
	If (_lRet) .and. (Len(_aColsFotos) != 0)

		// monta o header das fotos
		aAdd(_aHeadFotos,{"Código"     , "Z25_CODFOT", PesqPict("Z25","Z25_CODFOT"), TamSx3("Z25_CODFOT")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadFotos,{"Descrição"  , "Z23_DESCRI", PesqPict("Z25","Z23_DESCRI"), TamSx3("Z23_DESCRI")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadFotos,{"Quantidade" , "Z25_QUANT" , PesqPict("Z25","Z25_QUANT") , TamSx3("Z25_QUANT")[1] , 0,Nil,Nil,"N",Nil,"R",,,".F."  })
		aAdd(_aHeadFotos,{"Obrigatório", "Z25_OBRIGA", PesqPict("Z25","Z25_OBRIGA"), TamSx3("Z25_OBRIGA")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadFotos,{"Ordem"      , "Z25_ORDEM" , PesqPict("Z25","Z25_ORDEM") , TamSx3("Z25_ORDEM")[1] , 0,Nil,Nil,"C",Nil,"R",,,".F."  })

		// monta o header dos logs
		aAdd(_aHeadLogOp,{"Data"     , "ZN_DATA"  , PesqPict("SZN","ZN_DATA")  , TamSx3("ZN_DATA")[1]  , 0,Nil,Nil,"D",Nil,"R",,,".F."  })
		aAdd(_aHeadLogOp,{"Hora"     , "ZN_HORA"  , PesqPict("SZN","ZN_HORA")  , TamSx3("ZN_HORA")[1]  , 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadLogOp,{"Usuário"  , "ZN_NOME"  , PesqPict("SZN","ZN_NOME")  , TamSx3("ZN_NOME")[1]  , 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadLogOp,{"Descrição", "ZN_DESCRI", PesqPict("SZN","ZN_DESCRI"), TamSx3("ZN_DESCRI")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })

		// definicao da tela
		_oDlg01Fotos := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Lista de Fotos e Log por Operação",,,.F.,,,,,,.T.,,,.T. )
		_oDlg01Fotos:lMaximized := .T.

		// inicializa o FWLayer
		_oLay01 := FWLayer():new()
		_oLay01:Init(_oDlg01Fotos, .F.)

		// adicionando coluna à primeira linha
		_oLay01:AddLine('LIN1',40,.F.)
		_oLay01:AddCollumn('COL1',100, .T. ,'LIN1')

		// adicionando colunas à segunda linha
		_oLay01:AddLine('LIN2',60,.F.)
		_oLay01:addCollumn('COL1',100, .T. ,'LIN2')

		// painel
		_oPnlSup := _oLay01:getColPanel('COL1','LIN1') // Janela de cima - MsNewGetDados
		_oPnlInf := _oLay01:getColPanel('COL1','LIN2') // Janela de Baixo - MsNewGetDados

		// browse com os detalhes das fotos
		_oBr01Fotos := MsNewGetDados():New(000,000,_aSizeDlg[6],_aSizeDlg[5],Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsFotos),'AllwaysTrue()','','AllwaysTrue()', _oPnlSup, _aHeadFotos, _aColsFotos)
		_oBr01Fotos:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// browse com os detalhes das fotos
		_oBr01LogOp := MsNewGetDados():New(000,000,_aSizeDlg[6],_aSizeDlg[5],Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsFotos),'AllwaysTrue()','','AllwaysTrue()', _oPnlInf, _aHeadLogOp, _aColsLogOp)
		_oBr01LogOp:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// ativa a tela
		ACTIVATE MSDIALOG _oDlg01Fotos CENTERED ON INIT EnchoiceBar(_oDlg01Fotos,{||_oDlg01Fotos:End()},{||_oDlg01Fotos:End()},.T.,{},0,'',.F.,.F.,.F.,.F.,.F.,'ID_TELA01',)

	EndIf
Return

// ModelDef - Modelo padrao para MVC
Static Function ModelDef()

	// variaveis para modelo
	Local _oModel  := Nil
	Local _oStrSZ6 := FwFormStruct( 1, "SZ6", Nil )

	// Cria o formulario
	_oModel := MPFormModel():New( 'MD_TWMSA036' )
	_oModel:SetDescription(cCadastro)

	// define campos do cabecalho
	_oModel:AddFields( 'SZ6MASTER', /*cOwner*/, _oStrSZ6 )

Return (_oModel)

// ** Função que define a interface do cadastro de Movimentacao de Veiculos para o MVC
Static Function ViewDef()

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local _oModel := FWLoadModel('TWMSA036')
	Local _oView  := Nil
	// Cria a estrutura a ser usada na View
	Local _oStrSZ6 := FWFormStruct( 2, 'SZ6', Nil )

	// Cria o objeto de View
	_oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	_oView:SetModel( _oModel )

	// Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	_oView:AddField('VIEW_SZ6', _oStrSZ6, 'SZ6MASTER')

	// Criar um "box" horizontal para receber algum elemento da view
	_oView:CreateHorizontalBox( 'TELA' , 100 )

	// Relaciona o identificador (ID) da View com o "box" para exibição
	_oView:SetOwnerView( 'VIEW_SZ6', 'TELA' )

	/* Desabilita o novo botao "salvar e criar novo" */
	_oView:SetCloseOnOK({ || .T. })

Return (_oView)