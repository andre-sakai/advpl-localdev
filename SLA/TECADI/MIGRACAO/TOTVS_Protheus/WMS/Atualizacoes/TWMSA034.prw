#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Alteração de dados (em massa) de endereços WMS          !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 05/2015 !
+------------------+--------------------------------------------------------*/

User Function TWMSA034()

	// dimensoes da tela
	Local _aSizeWnd := MsAdvSize()
	// grupo de perguntas
	local _cPerg := PadR("TWMSA034",10)
	local _aPerg := {}

	// tipo de status de endereco
	local _aStsEnder := {"Desocupado","Bloqueado"}

	// variaveis SQL
	local _cQuery  := ""

	// funcao que monta os dados do operador logado no sistema
	local _aUsrInfo := U_FtWmsOpe()

	// usuário administrador
	local _aGrupos   := FWSFUsrGrps(__cUserId)

	// codigo do Operador
	Private _lUsrAccou  := (_aUsrInfo[2]=="A")
	Private _lUsrColet	:= (_aUsrInfo[2]=="C")
	Private _lUsrSuper	:= (_aUsrInfo[2]=="S")
	Private _lUsrGeren  := (_aUsrInfo[2]=="G")
	Private _lUsrMonit  := (_aUsrInfo[2]=="M")
	Private _lUsrAdmin  := ((__cUserId $ "000000/000373") .or. (aScan(_aGrupos,"000000") > 0))

	// variaveis para posição dos campos na Grid
	private _nPosMARK  := 0
	private _nPosLocal := 0
	private _nPosEnder := 0
	private _nPosStAtu := 0
	private _nPosStNew := 0
	private _nPosClAtu := 0
	private _nPosNmAtu := 0
	private _nPosClNew := 0
	private _nPosNmNew := 0
	private _nPosEstFi := 0

	// arrays do browse
	private _aHeadEnd := sfDefHead()
	private _aColsEnd := {}

	// Objetos da tela
	private _oDlgEnd
	private _oPnlBottom
	private _oBrwEnder
	private _oBtReserv, _oBtMarca, _oBtDesma, _oBtSair 

	// valida se eh supervisor ou gerente
	If ( ! _lUsrSuper ) .And. ( ! _lUsrGeren ) .And. ( ! _lUsrAdmin ) 
		// mensagem
		MsgStop("Apenas Supervisor ou Gerente pode utilizar esta Rotina", "TWMSA034")
		// retorno
		Return
	EndIf
	
	//pede senha de supervisor ou gerente
	If ( !StaticCall(TWMSA010, sfVldUser, "G|S") )
		MessageBox("É necessária senha de supervisor/gerente para confirmar a alteração em massa!","Erro WMSA034",48)
		Return
	EndIf

	// define grupo de perguntas/parametros
	aAdd(_aPerg,{"Local/Armazém?"          ,"C",TamSx3("BE_LOCAL")[1]           ,0,"G",                 ,"Z12"}) //mv_par01
	aAdd(_aPerg,{"Rua De?"                 ,"C",2                               ,0,"G",                 ,""   }) //mv_par02
	aAdd(_aPerg,{"Rua Até?"                ,"C",2                               ,0,"G",                 ,""   }) //mv_par03
	aAdd(_aPerg,{"Lado:"                   ,"N",1                               ,0,"C",{"Ambos","A","B"},,    }) //mv_par04
	aAdd(_aPerg,{"Prédio De?"              ,"C",2                               ,0,"G",                 ,""   }) //mv_par05
	aAdd(_aPerg,{"Prédio Até?"             ,"C",2                               ,0,"G",                 ,""   }) //mv_par06
	aAdd(_aPerg,{"Andar De?"               ,"C",2                               ,0,"G",                 ,""   }) //mv_par07
	aAdd(_aPerg,{"Andar Até?"              ,"C",2                               ,0,"G",                 ,""   }) //mv_par08
	aAdd(_aPerg,{"Endereço De:"            ,"C",TamSx3("BE_LOCALIZ")[1]         ,0,"G",                 ,"SBE"}) //mv_par09
	aAdd(_aPerg,{"Endereço Até:"           ,"C",TamSx3("BE_LOCALIZ")[1]         ,0,"G",                 ,"SBE"}) //mv_par10
	aAdd(_aPerg,{"Alterar Cliente?"        ,"N",1                               ,0,"C",{"Sim","Não"}    ,,    }) //mv_par11
	aAdd(_aPerg,{"Do Cliente:"             ,"C",TamSx3("A1_COD")[1]             ,0,"G",                 ,"SA1",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par12
	aAdd(_aPerg,{"Para Cliente:"           ,"C",TamSx3("A1_COD")[1]             ,0,"G",                 ,"SA1",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par13
	aAdd(_aPerg,{"Alterar Status?"         ,"N",1                               ,0,"C",{"Sim","Não"}    ,,    }) //mv_par14
	aAdd(_aPerg,{"Do Status:"              ,"N",1                               ,0,"C",_aStsEnder       ,,    }) //mv_par15
	aAdd(_aPerg,{"Para Status:"            ,"N",1                               ,0,"C",_aStsEnder       ,,    }) //mv_par16

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// chama a tela de parametros
	If ( ! Pergunte(_cPerg,.T.) )
		Return
	EndIf

	// valida preenchimento dos parametros - cliente
	If (mv_par11 == 1).and.(mv_par12 == mv_par13)
		Help(,, 'TWMSA034.F01.002',, "Alteração para status igual.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"Quando selecionada a opção de alterar CLIENTE, favor preencher corretamente os parâmetros 'Do Cliente' e 'Para Cliente'. Não podem ser iguais!"}) 
		Return
	EndIf

	// se ativou mudança de status mas não é admin, não deixa
//	If (mv_par14 == 1) .AND. (!_lUsrAdmin)
//		Help(,, 'TWMSA034.F01.001',, "Tentativa de alteração de status por não administrador.", 1, 0,;
//		NIL, NIL, NIL, NIL, NIL,;
//		{"Altere o parâmetro 14 - 'Altera Status' para não."}) 
//		Return
//	EndIf

	// valida preenchimento dos parametros - status
	If (mv_par14 == 1).and.(mv_par15 == mv_par16)
		Help(,, 'TWMSA034.F01.002',, "Alteração para status igual.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"Quando selecionada a opção de alterar STATUS, favor preencher corretamente os parâmetros 'Do Status' e 'Para Status'. Favor Revisar parâmetros 15 e 16."}) 
		Return
	EndIf

	// monta query para filtro dos enderecos conforme parametros
	_cQuery := " SELECT DISTINCT 'LBNO'                               ZE0_AMARK, "
	_cQuery += "                 BE_LOCAL                             COD_LOCAL, "
	_cQuery += "                 BE_LOCALIZ                           COD_ENDER, "
	_cQuery += "                 BE_STATUS                            STS_ATUAL, "
	_cQuery += "                 '" + IIf(MV_PAR14 == 1, IIf(mv_par16 == 1, "1", "3"), "") + "' STS_NOVO, "
	_cQuery += "                 BE_ZCODCLI                           CLI_ATUAL, "
	_cQuery += "                 Isnull(SA1ATU.A1_NOME, '')           NOM_ATUAL, "
	_cQuery += "                 '" +mv_par13+ "'                     CLI_NOVO, "
	_cQuery += "                 Isnull(SA1NEW.A1_NOME, '')           NOM_NOVO, "
	_cQuery += "                 DC8_DESEST                           EST_FISICA, "
	_cQuery += "                 '.F.'                                IT_DEL "
	// cad. de enderecos
	_cQuery += " FROM   " + RetSqlTab("SBE") + " (nolock) "
	// cad. estrutura fisica
	_cQuery += "        LEFT JOIN " + RetSqlTab("DC8") + " (nolock) "
	_cQuery += "               ON " + RetSqlCond("DC8")
	_cQuery += "                  AND DC8_CODEST = BE_ESTFIS "
	// cad. de clientes - atual
	_cQuery += "        LEFT JOIN " + RetSqlName("SA1") + " SA1ATU (nolock)  "
	_cQuery += "               ON SA1ATU.A1_FILIAL = '" +xFilial("SA1")+ "' AND SA1ATU.D_E_L_E_T_ = '' "
	_cQuery += "                  AND SA1ATU.A1_COD = BE_ZCODCLI "
	// cad. de clientes - novo
	_cQuery += "        LEFT JOIN " + RetSqlName("SA1") + " SA1NEW  (nolock) "
	_cQuery += "               ON SA1NEW.A1_FILIAL = '" +xFilial("SA1")+ "' AND SA1NEW.D_E_L_E_T_ = '' "
	_cQuery += "                  AND SA1NEW.A1_COD = '" +mv_par13+ "' "
	// filtros
	_cQuery += " WHERE  " + RetSqlCond("SBE")
	// local/armazem
	_cQuery += "        AND BE_LOCAL = '" +mv_par01+ "' "
	// rua
	_cQuery += "        AND Substring(BE_LOCALIZ, 1, 2) BETWEEN '" +mv_par02+ "' AND '" +mv_par03+ "' "
	// lado
	If (mv_par04 != 1)
		_cQuery += "        AND Substring(BE_LOCALIZ, 3, 1) = '" +IIf(mv_par04 == 2, "A", "B")+ "' "
	EndIf
	// predio
	_cQuery += "        AND Substring(BE_LOCALIZ, 4, 2) BETWEEN '" +mv_par05+ "' AND '" +mv_par06+ "' "
	// andar
	_cQuery += "        AND Substring(BE_LOCALIZ, 6, 2) BETWEEN '" +mv_par07+ "' AND '" +mv_par08+ "' "
	// endereco
	_cQuery += "        AND BE_LOCALIZ BETWEEN '" +mv_par09+ "' AND '" +mv_par10+ "' "
	// alterar cliente
	If (mv_par11 == 1)
		_cQuery += "        AND BE_ZCODCLI = '" +mv_par12+ "' "
	EndIf
	// alterar status
	If (mv_par14 == 1)
		_cQuery += "        AND BE_STATUS = '" +IIf(mv_par15 == 1, "1", "3")+ "' "
	EndIf
	// descarta enderecos reservados
	_cQuery += "        AND NOT EXISTS (SELECT Z08_NUMOS "
	_cQuery += "                        FROM   " + RetSqlTab("Z08") + " (nolock) "
	_cQuery += "                        WHERE  " + RetSqlCond("Z08")
	_cQuery += "                               AND Z08_LOCAL = BE_LOCAL "
	_cQuery += "                               AND ( Z08_ENDORI = BE_LOCALIZ "
	_cQuery += "                                      OR Z08_ENDDES = BE_LOCALIZ ) "
	_cQuery += "                               AND Z08_STATUS != 'R') "
	// descarta endereços com saldo fiscal
	_cQuery += "        AND NOT EXISTS (SELECT BF_LOCALIZ "
	_cQuery += "                        FROM   " + RetSqlTab("SBF") + " (nolock) "
	_cQuery += "                        WHERE  " + RetSqlCond("SBF")
	_cQuery += "                               AND BF_LOCAL = BE_LOCAL "
	_cQuery += "                               AND BF_LOCALIZ = BE_LOCALIZ "
	_cQuery += "                               AND BF_QUANT != 0 ) "
	// descarta endereços com saldo fiscal
	_cQuery += "        AND NOT EXISTS (SELECT Z16_ENDATU "
	_cQuery += "                        FROM   " + RetSqlTab("Z16") + " (nolock) "
	_cQuery += "                        WHERE  " + RetSqlCond("Z16")
	_cQuery += "                               AND Z16_LOCAL = BE_LOCAL "
	_cQuery += "                               AND Z16_ENDATU = BE_LOCALIZ "
	_cQuery += "                               AND Z16_SALDO != 0 )"
	// ordem dos dados
	_cQuery += " ORDER  BY BE_LOCAL, "
	_cQuery += "           BE_LOCALIZ "

	// Gravamos o log para posterior auditoria
	memowrit("c:\query\twmsa034_sfBuscaEnd.txt", _cQuery)

	// carrega resultado do SQL na variavel.
	_aColsEnd := U_SqlToVet(_cQuery)

	// monta a tela
	_oDlgEnd := MSDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"Alterar Dados de Endereços",,,.F.,,,,,,.T.,,,.T. )
	_oDlgEnd:lMaximized := .T.

	// cria o panel da direita com as opções para abastecimento já escolhidas
	_oPnlBottom := TPanel():New(000,000,nil,_oDlgEnd,,.F.,.F.,,,000,030,.T.,.F. )
	_oPnlBottom:Align := CONTROL_ALIGN_BOTTOM

	// browse com os detalhes dos endereços a abastercer
	_oBrwEnder := MsNewGetDados():New(000,000,999,999,Nil,'AllwaysTrue()','AllwaysTrue()','',,,,'AllwaysTrue()','','AllwaysTrue()', _oDlgEnd, _aHeadEnd, _aColsEnd)
	_oBrwEnder:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwEnder:oBrowse:bLDblClick := {|| sfInvMark(1, Nil)}
	_oBrwEnder:oBrowse:SetBlkBackColor({|| sfDestCor(_oBrwEnder:aCols ,_oBrwEnder:nAt) })

	// botão que irá reservar os endereços
	_oBtReserv := TButton():New( 010, 010, "Confirmar Alteração",_oPnlBottom,{|| sfConfAlt(),_oDlgEnd:END() }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// botão que irá marcar todas as linhas
	_oBtMarca := TButton():New( 010, 100, "Marca Todos",_oPnlBottom,{|| sfInvMark(2, "M") }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// botão que irá Desmarcar todas as linhas
	_oBtDesma := TButton():New( 010, 190, "Desmarcar Todos",_oPnlBottom,{|| sfInvMark(2, "D") }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// botão que irá sair da rotina
	_oBtSair := TButton():New( 010, 280,"Cancelar",_oPnlBottom,{|| IIF(MsgYesNo("Desejar Sair?"), _oDlgEnd:END(), Nil) }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// ativacao da tela
	_oDlgEnd:Activate(,,,.T.,)

Return

// funcao para marcar/desmarcar todos os registros
Static Function sfInvMark(mvTip, mvMarDes)
	// variaveis temporarias
	Local _nX

	// se for selecao de item unico
	If (mvTip == 1)
		_oBrwEnder:aCOLS[_oBrwEnder:nAt,_nPosMARK] := IIf(_oBrwEnder:aCOLS[_oBrwEnder:nAt,_nPosMARK]=="LBOK", "LBNO", "LBOK")
		// multiplos
	ElseIf (mvTip == 2)
		// varre todos os itens do browse
		For _nX :=  1 To Len(_oBrwEnder:aCOLS)
			// atualiza campo de controle de marcacao
			_oBrwEnder:aCOLS[_nX,_nPosMARK] := IIf(mvMarDes == "M", "LBOK", "LBNO")
		Next _nX
	EndIf

	// refresh do browse
	_oBrwEnder:Refresh()

Return()

// funcao que atualiza os dados
Static Function sfConfAlt()
	// variaveis Temporarias
	Local _cInfoLog := ""
	Local _nEnd
	local _lRet := .f.
	// conteudo atual / novo
	local _cStAtu := ""
	local _cStNew := ""
	local _cClAtu := ""
	local _cClNew := ""

	// solicita confirmacao do processo
	If ( ! MsgYesNo("Confirma atualização das informações dos itens selecionados?"))
		Return(.f.)
	EndIf

	// INICIA TRANSACAO
	BEGIN TRANSACTION

		// cadastro de enderecos
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1))// 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ

		// varre todos os itens do browse
		For _nEnd := 1 To Len(_oBrwEnder:aCOLS)
			// verifica se o item esta selecionado
			If (_oBrwEnder:aCOLS[_nEnd,_nPosMARK] == "LBOK")

				// zera log
				_cInfoLog := "Alteração:"

				// posiciona no registro
				If SBE->(dbSeek( xFilial("SBE") + _oBrwEnder:aCOLS[_nEnd,_nPosLocal] + _oBrwEnder:aCOLS[_nEnd,_nPosEnder] ))

					// cliente atual / novo
					If (mv_par11 == 1).and.(_oBrwEnder:aCOLS[_nEnd][_nPosClAtu] != _oBrwEnder:aCOLS[_nEnd][_nPosClNew])
						// cliente atual
						_cClAtu := SBE->BE_ZCODCLI
						// cliente novo
						_cClNew := _oBrwEnder:aCOLS[_nEnd][_nPosClNew]
						// atualiza log
						_cInfoLog += " Cliente De: " + _cClAtu + " Para: " + _cClNew
						// atualiza dados
						RecLock("SBE", .F.)
						SBE->BE_ZCODCLI := _cClNew
						SBE->(msUnLock())
					EndIf

					// status atual / novo
					If (mv_par14 == 1).and.(_oBrwEnder:aCOLS[_nEnd][_nPosStAtu] != _oBrwEnder:aCOLS[_nEnd][_nPosStNew])
						// status atual
						_cStAtu := SBE->BE_STATUS
						// status novo
						_cStNew := _oBrwEnder:aCOLS[_nEnd][_nPosStNew]
						// atualiza log
						_cInfoLog += " Status De: " + _cStAtu + " Para: " + _cStNew
						// atualiza dados
						RecLock("SBE", .F.)
						SBE->BE_STATUS  := _cStNew
						SBE->(msUnLock())

					EndIf

					//Gera Log da Alteração
					U_FtGeraLog(xFilial("SBE"), "SBE", SBE->(BE_FILIAL + BE_LOCAL + BE_LOCALIZ), _cInfoLog, "", "")

					// controle de processamento
					_lRet := .t.

				EndIf

			EndIf

		Next _nEnd

		// FINALIZA TRANSACAO
	END TRANSACTION

	If (_lRet)
		MsgInfo("Alteração Realizada", "TWMSA034" )
	ElseIf ( ! _lRet )
		MsgAlert("Alteração Não Realizada", "TWMSA034" )
	EndIf

Return()

// ** funcao que define header
Static Function sfDefHead()
	// variavel de retorno
	local _aRet := {}
	// area atual
	local _aAreaSX3 := SX3->(GetArea())

	// define campo de marcacao
	Aadd(_aRet,{'    ','ZE0_AMARK','@BMP',10,0,,,'C',,'V',,,'mark','V','S'})
	_nPosMARK := Len(_aRet)

	// local/armazém
	Aadd(_aRet,{"Armazem","BE_LOCAL","@!",2,0,"","","C","",""})
	_nPosLocal := Len(_aRet)
	// endereço
	Aadd(_aRet,{"Endereco","BE_LOCALIZ","@!",15,0,"","","C","",""})
	_nPosEnder := Len(_aRet)
	// status atual / novo
	Aadd(_aRet,{"Status Atual","BE_STATUS","@!",1,0,"","","C","",""})
	_nPosStAtu := Len(_aRet)
	Aadd(_aRet,{"Novo Status","BE_STATUS","@!",1,0,"","","C","",""})
	_nPosStNew := Len(_aRet)
	// codigo cliente atual
	Aadd(_aRet,{"Cliente Atual","BE_ZCODCLI","@!",6,0,"","","C","",""})
	_nPosClAtu := Len(_aRet)
	Aadd(_aRet,{"Nome","A1_NOME","@!",40,0,"","","C","",""})
	_nPosNmAtu := Len(_aRet)
	// codigo cliente novo
	Aadd(_aRet,{"Novo Cliente","BE_ZCODCLI","@!",6,0,"","","C","",""})
	_nPosClNew := Len(_aRet)
	Aadd(_aRet,{"Nome","A1_NOME","@!",40,0,"","","C","",""})
	_nPosNmNew := Len(_aRet)
	// estrutura fisica
	Aadd(_aRet,{"Descricao","DC8_DESEST","@!",30,0,"","","C","",""})
	_nPosEstFi := Len(_aRet)
	
	// restaura area inicial
	RestArea(_aAreaSX3)

Return(_aRet)

// ** funcao que destaca a cor da linha do grid
Static Function sfDestCor(mvBrwCols, mvLinPos)
	// cor padrao
	local _nCorRet := CLR_WHITE
	// cor destaque
	Local _nCorDestaque := CLR_YELLOW

	// compara opcoes de alteracao
	If (mvBrwCols[mvLinPos,_nPosMARK]=="LBOK").and.( ( (mv_par11 == 1).and.(mvBrwCols[mvLinPos][_nPosClAtu] != mvBrwCols[mvLinPos][_nPosClNew]) ) .or. ( (mv_par14 == 1).and.(mvBrwCols[mvLinPos][_nPosStAtu] != mvBrwCols[mvLinPos][_nPosStNew]) ) )
		_nCorRet := _nCorDestaque
	Endif

Return(_nCorRet)