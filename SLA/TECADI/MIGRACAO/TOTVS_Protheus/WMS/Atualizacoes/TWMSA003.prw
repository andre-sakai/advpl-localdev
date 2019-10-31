#Include "Totvs.ch"
#Include "Colors.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Atividades dos produtos do contrato                     !
+------------------+---------------------------------------------------------+
!Autor             ! Percio de Oliveira          ! Data de Criacao ! 12/2010 !
+------------------+--------------------------------------------------------*/

User Function TWMSA003(_cTpSrv, _cOrigem, mvVisual, mvModelGrid)

	// area inicial
	local _aAreaAtu := GetArea()

	// descricao do botao
	private _cDscBtn := IIf(mvVisual, "Fechar", "Confirmar")

	Do Case
		// detalhes armazenagem de container
		Case _cTpSrv == "1"
		sfDetArmCnt(mvVisual, mvModelGrid)
		// detalhes armazenagem de produto
		Case _cTpSrv == "2"
		sfDetArmPrd(mvVisual, mvModelGrid)
		// detalhes do 3-pacote logistico, A-pacote logistico exportacao e B-pacote de servicos
		Case _cTpSrv $ "3/A/B"
		sfDetPacteLog(mvVisual, mvModelGrid)
		// detalhes do frete
		Case _cTpSrv == "4"
		sfDetFrete(mvVisual, mvModelGrid)
		// detalhes cobranca de seguro
		Case _cTpSrv == "5"
		sfDetSeguro(mvVisual, mvModelGrid)
		// detalhes dos servicos diversos
		Case _cTpSrv == "7"
		sfDetServDiv(_cOrigem, mvVisual, mvModelGrid)
		// valor fixo / aluguel
		Case _cTpSrv == "8"
		sfDetFixo(mvVisual, mvModelGrid)

	EndCase

	// restaura area inicial
	RestArea(_aAreaAtu)

Return(.t.)

// ** funcao para detalhar a armazenagem de container
Static Function sfDetArmCnt(mvVisual, mvModelGrid)

	// controle na nao fechar a tela sem confirmar
	Local _lFixaMain  := .F.

	// linha atual
	local _nLinAtu := mvModelGrid:nLine

	// objetos da tela
	local _oSayTamCont

	// fonte utilizada na tela
	Private _oFntRoda := TFont():New("Tahoma",,16,,.t.)

	// conteudo dos campos
	Private _nPerDias  := mvModelGrid:GetValue('AAN_QUANT'  , _nLinAtu)
	Private _nDaysFree := mvModelGrid:GetValue('AAN_DAYFRE' , _nLinAtu)
	Private _nTarifa   := mvModelGrid:GetValue('AAN_VLRUNI' , _nLinAtu)
	Private _cTamCont  := mvModelGrid:GetValue('AAN_TAMCON' , _nLinAtu)
	Private _aTamCont  := sfCboxToArray("AAN_TAMCON")

	// monta a tela para alterar o valor
	_oDlgDetArmCnt := MSDialog():New(000,000,230,320,"Armazenagem Container",,,.F.,,,,,,.T.,,,.T. )
	_oSayPerDias  := TSay():New( 007,010,{||"Periodos:"},_oDlgDetArmCnt,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetPerDias  := TGet():New( 005,070,{|u| If(PCount()>0,_nPerDias:=u,_nPerDias)},_oDlgDetArmCnt,60,10,PesqPict("AAN","AAN_QUANT"),{||Positivo()},,,_oFntRoda,,,.T.,"",,{||(!mvVisual)},.F.,.F.,,.F.,.F.,"","_nPerDias",,)
	_oSayDaysFree := TSay():New( 022,010,{||"Days Free:"},_oDlgDetArmCnt,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetDaysFree := TGet():New( 020,070,{|u| If(PCount()>0,_nDaysFree:=u,_nDaysFree)},_oDlgDetArmCnt,60,10,PesqPict("AAN","AAN_DAYFRE"),{||Positivo()},,,_oFntRoda,,,.T.,"",,{||(!mvVisual)},.F.,.F.,,.F.,.F.,"","_nDaysFree",,)
	_oSayTarifa   := TSay():New( 042,010,{||"Tarifa:"},_oDlgDetArmCnt,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetTarifa   := TGet():New( 040,070,{|u| If(PCount()>0,_nTarifa:=u,_nTarifa)},_oDlgDetArmCnt,60,10,PesqPict("AAN","AAN_VLRUNI"),{||Positivo()},,,_oFntRoda,,,.T.,"",,{||(!mvVisual)},.F.,.F.,,.F.,.F.,"","_nTarifa",,)
	_oSayTamCont  := TSay():New( 062,010,{||"Tam.Container:"},_oDlgDetArmCnt,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetTamCont  :=  TComboBox():New( 060,070,{|u| If(PCount()>0,_cTamCont:=u,_cTamCont)},_aTamCont, 60,10,_oDlgDetArmCnt,,,,,,.T.,_oFntRoda,"",,{||(!mvVisual)},,,,,_cTamCont)

	// botao para confirmar
	_oBtnConfirmar := TButton():New(082,050,_cDscBtn,_oDlgDetArmCnt,{||_lFixaMain:=.t.,_oDlgDetArmCnt:End()},050,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgDetArmCnt:Activate(,,,.T.,{|| _lFixaMain })

	// se foi confirmado
	If (_lFixaMain) .and. ( ! mvVisual )
		// atualiza informacoes
		mvModelGrid:LoadValue("AAN_QUANT" , _nPerDias  )
		mvModelGrid:LoadValue("AAN_DAYFRE", _nDaysFree )
		mvModelGrid:LoadValue("AAN_VALOR" , _nTarifa   )
		mvModelGrid:LoadValue("AAN_VLRUNI", _nTarifa   )
		mvModelGrid:LoadValue("AAN_TAMCON", sfCBoxDescr("AAN_TAMCON", _cTamCont, 3, 2) )
	Endif

Return(.t.)

// ** funcao para detalhar a armazenagem de produtos
Static Function sfDetArmPrd(mvVisual, mvModelGrid)

	// objetos da tela
	local _oDlgDetArmPrd
	local _oSayPerDias, _oSayDaysFree, _oSayTarifa, _oSayTipoArm, _oSayGrpEst
	local _oGetPerDias, _oGetDaysFree, _oGetTarifa, _oGetTipoArm, _oGetTipoArm
	local _oBtnConfirmar, _oBtnGrpEst

	// linha atual
	local _nLinAtu := mvModelGrid:nLine

	// controle na nao fechar a tela sem confirmar
	Local _lFixaMain := .f.

	// fonte utilizada na tela
	Private _oFntRoda  := TFont():New("Tahoma",,16,,.t.)

	// conteudo dos campos
	Private _nPerDias  := mvModelGrid:GetValue('AAN_QUANT'  , _nLinAtu)
	Private _nDaysFree := mvModelGrid:GetValue('AAN_DAYFRE' , _nLinAtu)
	Private _nTarifa   := mvModelGrid:GetValue('AAN_VLRUNI' , _nLinAtu)
	private _cCodTpArm := mvModelGrid:GetValue('AAN_TIPOAR' , _nLinAtu)
	Private _aTipoArm  := sfCboxToArray("AAN_TIPOAR")
	Private _cTipoArm  := sfCBoxDescr("AAN_TIPOAR", _cCodTpArm, 2, 3)
	Private _cGrpEsto  := mvModelGrid:GetValue('AAN_ZGRPES' , _nLinAtu)

	// monta a tela para alterar o valor
	_oDlgDetArmPrd := MSDialog():New(000,000,230,360,"Armazenagem Produto",,,.F.,,,,,,.T.,,,.T. )
	_oSayPerDias   := TSay():New( 007,010,{||"Períodos:"},_oDlgDetArmPrd,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetPerDias   := TGet():New( 005,070,{|u| If(PCount()>0,_nPerDias:=u,_nPerDias)},_oDlgDetArmPrd,60,10,PesqPict("AAN","AAN_QUANT"),{|| Positivo() },,,_oFntRoda,,,.T.,"",,{||(!mvVisual)},.F.,.F.,,.F.,.F.,"","_nPerDias",,)
	_oSayDaysFree  := TSay():New( 022,010,{||"Days Free:"},_oDlgDetArmPrd,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetDaysFree  := TGet():New( 020,070,{|u| If(PCount()>0,_nDaysFree:=u,_nDaysFree)},_oDlgDetArmPrd,60,10,PesqPict("AAN","AAN_DAYFRE"),{|| Positivo() },,,_oFntRoda,,,.T.,"",,{||(!mvVisual)},.F.,.F.,,.F.,.F.,"","_nDaysFree",,)
	_oSayTarifa    := TSay():New( 037,010,{||"Tarifa:"},_oDlgDetArmPrd,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetTarifa    := TGet():New( 035,070,{|u| If(PCount()>0,_nTarifa:=u,_nTarifa)},_oDlgDetArmPrd,60,10,PesqPict("AAN","AAN_VLRUNI"),{|| Positivo() },,,_oFntRoda,,,.T.,"",,{||(!mvVisual)},.F.,.F.,,.F.,.F.,"","_nTarifa",,)
	_oSayTipoArm   := TSay():New( 052,010,{||"Tipo Armaz.:"},_oDlgDetArmPrd,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetTipoArm   := TComboBox():New( 050,070,{|u| If(PCount()>0,_cTipoArm:=u,_cTipoArm)},_aTipoArm, 60,10,_oDlgDetArmPrd,,,,,,.T.,_oFntRoda,"",,{|| (!mvVisual) },,,,,_cTipoArm)

	// grupo de estoque
	_oSayGrpEst := TSay():New( 067,010,{||"Grupo Estoque:"},_oDlgDetArmPrd,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetGrpEst := TGet():New( 065,070,{|u| If(PCount()>0,_cGrpEsto:=u,_cGrpEsto)},_oDlgDetArmPrd,60,10,PesqPict("AAN","AAN_ZGRPES"),{||.T.},,,_oFntRoda,,,.T.,"",,{|| .f. },.F.,.F.,,.F.,.F.,"","_cGrpEsto",,)
	_oBtnGrpEst := TButton():New(065,135,"Grp.Estoque",_oDlgDetArmPrd,{|| sfBtnGrpEst(mvVisual) },040,012,,,,.T.,,"",,,,.F. )

	// botao para confirmar
	_oBtnConfirmar := TButton():New(090,050,_cDscBtn,_oDlgDetArmPrd,{||_lFixaMain:=.t.,_oDlgDetArmPrd:End()},050,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgDetArmPrd:Activate(,,,.T.,{||_lFixaMain})

	// se foi confirmado
	If (_lFixaMain) .and. ( ! mvVisual )
		// atualiza informacoes
		mvModelGrid:LoadValue("AAN_QUANT" , _nPerDias  )
		mvModelGrid:LoadValue("AAN_DAYFRE", _nDaysFree )
		mvModelGrid:LoadValue("AAN_VLRUNI", _nTarifa   )
		mvModelGrid:LoadValue("AAN_VALOR" , _nTarifa   )
		// tipo de armazenagem
		mvModelGrid:LoadValue("AAN_TIPOAR", sfCBoxDescr("AAN_TIPOAR", _cTipoArm, 3, 2) )
		// grupo de estoque
		mvModelGrid:LoadValue("AAN_ZGRPES", _cGrpEsto  )
	Endif

Return(.t.)

// ** funcao para detalhar as movimentacoes internas / frete
Static Function sfDetFrete(mvVisual, mvModelGrid)

	// controle na nao fechar a tela sem confirmar
	Local _lFixaMain := .f.

	// linha atual
	local _nLinAtu := mvModelGrid:nLine

	// fonte utilizada na tela
	Private _oFntRoda  := TFont():New("Tahoma",,16,,.t.)

	// conteudo dos campos
	Private _cTabFrete := mvModelGrid:GetValue('AAN_TABELA', _nLinAtu)

	// monta a tela para alterar o valor
	_oDlgDetFrete := MSDialog():New(000,000,100,240,"Frete",,,.F.,,,,,,.T.,,,.T. )
	_oSayTabela := TSay():New( 007,010,{||"Tabela:"},_oDlgDetFrete,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetTabela := TGet():New(005,050,{|u| If(PCount()>0,_cTabFrete:=u,_cTabFrete)},_oDlgDetFrete,060,010,PesqPict("AAN","AAN_TABELA"),,,,_oFntRoda,,,.T.,"",,{||(!mvVisual)},.F.,.F.,,.F.,.F.,"SZ4","_cTabFrete",,)

	// botao para confirmar
	_oBtnConfirmar := TButton():New(025,040,_cDscBtn,_oDlgDetFrete,{||_lFixaMain:=.t.,_oDlgDetFrete:End()},050,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgDetFrete:Activate(,,,.T.,{|| _lFixaMain })

	// se foi confirmado
	If (_lFixaMain) .and. ( ! mvVisual )
		// atualiza os campos da tela principal de contratos
		mvModelGrid:LoadValue("AAN_TABELA", _cTabFrete )
	Endif


Return(.t.)

// ** funcao para detalhes do pacote logistico
Static Function sfDetPacteLog(mvVisual, mvModelGrid)

	// controle na nao fechar a tela sem confirmar
	Local _lFixaMain := .f.

	// variaveis temporarias
	local _nItPcte
	local _cQuery

	// seek
	local _cSeekSZ9

	// controle de edicao do browse
	local _nOpcBrw := IIf(mvVisual, nil, GD_UPDATE+GD_DELETE+GD_INSERT)

	// linha atual
	local _nLinAtu := mvModelGrid:nLine

	// fonte utilizada na tela
	Private _oFntRoda  := TFont():New("Tahoma",,16,,.t.)

	// conteudo dos campos
	Private _cPraca     := mvModelGrid:GetValue('AAN_PRACA'  , _nLinAtu)
	Private _aTipoCa    := sfCboxToArray("AAN_TIPOCA")
	private _cCodTpCar  := mvModelGrid:GetValue('AAN_TIPOCA' , _nLinAtu)
	Private _cTipoCa    := sfCBoxDescr("AAN_TIPOCA", _cCodTpCar, 2, 3)
	Private _nTrfPacote := mvModelGrid:GetValue('AAN_VLRUNI' , _nLinAtu)

	// variaveis do browse
	Private _aHeadPrd := {}
	Private _aColsPrd := {}

	// monta a tela para alterar o valor
	_oDlgDetPctLog := MSDialog():New(000,000,300,470,"Pacote Logistico",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho
	oPnlCabec := TPanel():New(000,000,nil,_oDlgDetPctLog,,.F.,.F.,,,000,040,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP

	_oSayTarifa := TSay():New( 007,005,{||"Tarifa:"},oPnlCabec,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetTarifa := TGet():New( 005,045,{|u| If(PCount()>0,_nTrfPacote:=u,_nTrfPacote)},oPnlCabec,60,10,PesqPict("AAN","AAN_VLRUNI"),{|| Positivo() },,,_oFntRoda,,,.T.,"",,{||(!mvVisual)},.F.,.F.,,.F.,.F.,"","_nTrfPacote",,)
	_oSayTipoCa := TSay():New( 023,005,{||"Tipo Carga:"},oPnlCabec,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetTipoCa :=  TComboBox():New( 021,045,{|u| If(PCount()>0,_cTipoCa:=u,_cTipoCa)},_aTipoCa, 60,10,oPnlCabec,,,,,,.T.,_oFntRoda,"",,{|| ( ! mvVisual ) },,,,,_cTipoCa)

	// botao para confirmar
	_oBtnConfirmar := TButton():New(005,180,_cDscBtn,oPnlCabec,{||_lFixaMain:=.t.,_oDlgDetPctLog:End()},050,012,,,,.T.,,"",,,,.F. )
	_oBtnPraca     := TButton():New(023,180,"Praca" ,oPnlCabec,{|| sfBtnPraca(mvVisual) }              ,050,012,,,,.T.,,"",,,,.F. )
	// somente quado for visualizacao
	If (mvVisual)
		_oBtnDetSrv := TButton():New(023,120,"Det. Serviço",oPnlCabec,{|| U_WMSG002P(mvVisual, mvModelGrid) },050,012,,,,.T.,,"",,,,.F. )
	EndIf

	aAdd(_aHeadPrd,{"Produto"  , "ZU_PRODUTO", PesqPict("SZU","ZU_PRODUTO"), TamSx3("ZU_PRODUTO")[1], TamSx3("ZU_PRODUTO")[2],Nil,Nil,"C",Nil,"R",,,".T."  })
	aAdd(_aHeadPrd,{"Descricao", "ZU_DESCRI" , PesqPict("SZU","ZU_DESCRI") , TamSx3("ZU_DESCRI")[1] , TamSx3("ZU_DESCRI")[2] ,Nil,Nil,"C",Nil,"R",,,".F."  })

	// busca dados do pacote
	_cQuery := " SELECT ZU_PRODUTO, B1_DESC, '.F.' IT_DEL "
	_cQuery += " FROM " + RetSqlTab("SZU,SB1")
	_cQuery += " WHERE " + RetSqlCond("SZU,SB1")
	_cQuery += " AND ZU_PRODUTO = B1_COD "
	_cQuery += " AND ZU_CONTRT = '" + _cNrContrt + "' AND ZU_ITCONTR = '" + _cItContrt + "' "
	_cQuery += " ORDER BY ZU_PRODUTO "
	// alimenta o acols com o resultado do SQL
	_aColsPrd := U_SqlToVet(_cQuery)

	// monta browse
	oBrwPrd := MsNewGetDados():New(000,000,400,400,_nOpcBrw,'AllwaysTrue()','AllwaysTrue()','',,,99,'AllwaysTrue()','','AllwaysTrue()',_oDlgDetPctLog,_aHeadPrd,_aColsPrd)
	oBrwPrd:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativacao da tela com validacao
	_oDlgDetPctLog:Activate(,,,.T.,{||_lFixaMain})

	// se foi confirmado
	If (_lFixaMain) .and. ( ! mvVisual )

		// atualiza os campos da tela principal de contratos
		mvModelGrid:LoadValue("AAN_PRACA" , _cPraca    )
		mvModelGrid:LoadValue("AAN_VALOR" , _nTrfPacote)
		mvModelGrid:LoadValue("AAN_VLRUNI", _nTrfPacote)
		mvModelGrid:LoadValue("AAN_TIPOCA", sfCBoxDescr("AAN_TIPOCA", _cTipoCa, 3, 2))

		// varre os servicos principais do pacote
		For _nItPcte := 1 To Len(oBrwPrd:aCols)
			// verifica se o item nao esta deletado e preenchido
			If ( ! oBrwPrd:aCols[_nItPcte,Len(oBrwPrd:aHeader)+1] ) .And. ( ! Empty(oBrwPrd:aCols[_nItPcte,1]) )
				// abre tabela de itens do pacote
				dbSelectArea("SZU")
				SZU->(dbSetOrder(1)) // 1-ZU_FILIAL, ZU_CONTRT, ZU_ITCONTR, ZU_PRODUTO
				If ! SZU->(dbSeek( xFilial("SZU") + _cNrContrt + _cItContrt + oBrwPrd:aCols[_nItPcte,1] ))
					Reclock("SZU", .t.)
					SZU->ZU_FILIAL  := xFilial("SZU")
					SZU->ZU_CONTRT  := _cNrContrt
					SZU->ZU_ITCONTR := _cItContrt
					SZU->ZU_PRODUTO := oBrwPrd:aCols[_nItPcte,1]
					SZU->(MsUnlock())
				Else
					Reclock("SZU", .f.)
					SZU->ZU_PRODUTO := oBrwPrd:aCols[_nItPcte,1]
					SZU->(MsUnlock())
				EndIf
			Else
				// Caso Linha seja deletada e produto seja do tipo outros servicos
				If (Posicione("SB1", 1, xFilial("SB1") + oBrwPrd:aCols[_nItPcte,1], "B1_TIPOSRV") == "7")
					// abre tabela das atividades dos servicos diversos do pacote
					dbSelectArea("SZ9")
					SZ9->(dbSetOrder(1)) // 1-Z9_FILIAL, Z9_CONTRAT, Z9_ITEM, Z9_CODATIV
					SZ9->(dbSeek( _cSeekSZ9 := xFilial("SZ9") + _cNrContrt + _cItContrt ))
					// varre todas as atividades
					While SZ9->( ! Eof() ) .and. (SZ9->Z9_FILIAL + SZ9->Z9_CONTRAT + SZ9->Z9_ITEM == _cSeekSZ9)
						// exclui item
						RecLock("SZ9", .f.)
						SZ9->(DBDelete())
						MsUnLock("SZ9")
						// proximo item
						SZ9->(dbSkip())
					EndDo

				EndIf
			EndIf
		Next _nItPcte

	EndIf

Return(.t.)

// ** funcao que detalha as pracas do pacote logistico
Static Function sfBtnPraca(mvVisual)

	// variaveis temporarias
	local _nX

	Local _aStruTrb 	:= {}
	Local _aBrowse 		:= {}
	local _cMsgPraca	:= ""
	Private _cMarca		:= 	GetMark ()
	Private PRC			:= GetNextAlias()
	Private _cArqPrc

	aadd(_aStruTrb,{"PRC_OK","C",2,0})
	aadd(_aStruTrb,{"PRC_COD","C",4,0})
	aadd(_aStruTrb,{"PRC_DESC","C",50,0})

	aadd(_aBrowse,{"PRC_OK",,""})
	aadd(_aBrowse,{"PRC_COD",,"Codigo"})
	aadd(_aBrowse,{"PRC_DESC",,"Descrição"})

	If (Select(PRC)<>0)
		dbSelectArea(PRC)
		dbCloseArea()
	EndIf

	_cArqPrc := FWTemporaryTable():New( PRC )
	_cArqPrc:SetFields( _aStruTrb )
	_cArqPrc:AddIndex("01", {"PRC_COD"} )
	_cArqPrc:Create()

	_cQuery := " SELECT ZB_CODIGO, ZB_DESCRI "
	_cQuery += " FROM " + RetSqlTab("SZB") + " (nolock) "
	_cQuery += " WHERE " + RetSqlCond("SZB")
	// se for somente visualizacao
	If (mvVisual)
		_cQuery += " AND ZB_CODIGO IN " + FormatIn(_cPraca,";")
	EndIf
	_cQuery += " ORDER BY ZB_CODIGO "
	// alimenta o acols com o resultado do SQL
	_aColsProg := U_SqlToVet(_cQuery)

	// se for visualizacao, mostra mensagem com as pracao
	If (mvVisual)
		For _nX := 1 To Len(_aColsProg)
			_cMsgPraca += _aColsProg[_nX][1] + "-" + AllTrim(_aColsProg[_nX][2]) + CRLF
		Next _nX
		// apresenta mensagem
		HS_MsgInf(_cMsgPraca, "Praças do Pacote", "Praças do Pacote")
		// retorno
		Return(.f.)
	EndIf

	// verifica se há historicos para visualizar
	If (Len(_aColsProg)==0)
		// mensagem
		MsgStop("Não há pracas cadastradas !")
		// retorno
		Return(.f.)
	EndIf

	For _nX := 1 To Len(_aColsProg)
		// verifica o codigo da praca
		If _aColsProg[_nX][01] $ _cPraca
			_cOK := _cMarca
		Else
			_cOK := ""
		EndIf
		(PRC)->(RecLock(PRC,.T.))
		(PRC)->PRC_OK   := _cOK
		(PRC)->PRC_COD  := AllTrim(_aColsProg[_nX][01])
		(PRC)->PRC_DESC := AllTrim(_aColsProg[_nX][02])
		(PRC)->(MsUnLock())
	Next _nX

	// posiciona no primeiro registro
	(PRC)->(dbGotop())

	// monta o dialogo
	oDlgProgRec := MSDialog():New(000,000,400,600,"Pracas do Pacote Logistico",,,.F.,,,,,,.T.,,,.T. )

	// browse com a listagem dos produtos conferidos
	oBrwProgRec := MsSelect():New (PRC,"PRC_OK",Nil, _aBrowse, .F., _cMarca, {000,000,400,600})
	oBrwProgRec:oBrowse:lHasMark 	:= .T.
	oBrwProgRec:oBrowse:lCanAllMark	:= .T.
	oBrwProgRec:oBrowse:bAllMark 	:= {|| MarkAll (PRC, "PRC_OK", _cMarca, @oDlgProgRec)}
	oBrwProgRec:oBrowse:Align       := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG oDlgProgRec CENTERED

	(PRC)->(dbGotop())
	_cPraca := ""
	While (PRC)->(!EOF())
		// verifica se item esta selecionado
		If ((PRC)->PRC_OK == _cMarca)
			_cPraca += AllTrim((PRC)->PRC_COD) + ";"
		EndIf
		// proximo item
		(PRC)->(dbSkip())
	EndDo

	// remove ultimo ";"
	_cPraca := SubStr(_cPraca,1,Len(_cPraca)-1)
	
	_cArqPrc:Delete()

Return(.t.)

// ** funcao para detalhar as informacoes de seguros
Static Function sfDetSeguro(mvVisual, mvModelGrid)

	// controle de confirmacao da tela
	Local _lFixaMain := .F.

	// linha atual
	local _nLinAtu := mvModelGrid:nLine

	// fonte
	Private _oFntRoda := TFont():New("Tahoma",,16,,.t.)

	// conteudo dos campos
	Private _nTarifa  := mvModelGrid:GetValue('AAN_VLRUNI', _nLinAtu)
	Private _nPerDias := mvModelGrid:GetValue('AAN_QUANT' , _nLinAtu)

	// monta a tela para alterar o valor
	_oDlgDetSeg := MSDialog():New(000,000,140,240,"Seguro",,,.F.,,,,,,.T.,,,.T. )
	_oSayTarifa := TSay():New( 007,010,{||"Tarifa (%):"},_oDlgDetSeg,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetTarifa := TGet():New( 005,050,{|u| If(PCount()>0,_nTarifa:=u,_nTarifa)},_oDlgDetSeg,60,10,PesqPict("AAN","AAN_VLRUNI"),{||Positivo()},,,_oFntRoda,,,.T.,"",,{||(!mvVisual)},.F.,.F.,,.F.,.F.,"","_nTarifa",,)

	_oSayPerDias := TSay():New( 022,010,{||"Períodos:"},_oDlgDetSeg,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetPerDias := TGet():New( 020,050,{|u| If(PCount()>0,_nPerDias:=u,_nPerDias)},_oDlgDetSeg,60,10,PesqPict("AAN","AAN_QUANT"),{||Positivo()},,,_oFntRoda,,,.T.,"",,{||(!mvVisual)},.F.,.F.,,.F.,.F.,"","_nPerDias",,)

	// botao para confirmar
	_oBtnConfirmar := TButton():New(040,040,_cDscBtn,_oDlgDetSeg,{||_lFixaMain:=.t.,_oDlgDetSeg:End()},050,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgDetSeg:Activate(,,,.T.,{||_lFixaMain})

	// se foi confirmado
	If (_lFixaMain) .and. ( ! mvVisual )
		mvModelGrid:LoadValue("AAN_VALOR" , _nTarifa )
		mvModelGrid:LoadValue("AAN_VLRUNI", _nTarifa )
		mvModelGrid:LoadValue("AAN_QUANT" , _nPerDias)
	Endif

Return(.t.)

// ** funcao para detalhar as informacoes de valores fixos / alugueis
Static Function sfDetFixo(mvVisual, mvModelGrid)

	// controle de confirmacao da tela
	Local _lFixaMain := .f.

	// linha atual
	local _nLinAtu := mvModelGrid:nLine

	// fonte
	Private _oFntRoda := TFont():New("Tahoma",,16,,.t.)

	// conteudo dos campos
	Private _nTarifa  := mvModelGrid:GetValue('AAN_VLRUNI', _nLinAtu)

	// monta a tela para alterar o valor
	_oDlgDetFixo := MSDialog():New(000,000,100,240,"Valor Fixo",,,.F.,,,,,,.T.,,,.T. )
	_oSayTarifa := TSay():New( 007,010,{||"Tarifa:"},_oDlgDetFixo,,_oFntRoda,.F.,.F.,.F.,.T.)
	_oGetTarifa := TGet():New( 005,050,{|u| If(PCount()>0,_nTarifa:=u,_nTarifa)},_oDlgDetFixo,60,10,PesqPict("AAN","AAN_VLRUNI"),{||Positivo()},,,_oFntRoda,,,.T.,"",,{||(!mvVisual)},.F.,.F.,,.F.,.F.,"","_nTarifa",,)

	// botao para confirmar
	_oBtnConfirmar := TButton():New(025,040,_cDscBtn,_oDlgDetFixo,{||_lFixaMain:=.t.,_oDlgDetFixo:End()},050,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgDetFixo:Activate(,,,.T.,{|| _lFixaMain })

	// se foi confirmado
	If (_lFixaMain) .and. ( ! mvVisual )
		mvModelGrid:LoadValue("AAN_VALOR" , _nTarifa )
		mvModelGrid:LoadValue("AAN_VLRUNI", _nTarifa )
	Endif


Return(.t.)

// ** funcao para detalhes dos servicos diversos
Static Function sfDetServDiv(_cOrigem, mvVisual, mvModelGrid)

	// quantidade maximo do servico no pacote
	local _nQtdMaxPac := 0
	// valor minimo do servico
	local _nVlrMin := 0
	// valor maximo do servico
	local _nVlrMax := 0
	// unid. medida de cobranca
	local _cUnidCob := ""

	// variaveis temporarias
	local _nX

	// linha atual
	local _nLinAtu := 0

	Local _cQuery
	Local _aStruTrb := {}
	Local _aBrowse 	:= {}
	Local _nPosCodSrv := 0
	Local _nPosDscSrv := 0

	Private _cMarca := GetMark ()
	Private _cNrContrt := M->AAM_CONTRT

	// arquivo de trabalho
	Private _cArquivo
	Private ATI := GetNextAlias()

	// fontes
	Private oFntVerd13 := TFont():New("Verdana",,13,,.T.)
	Private _oFntRoda  := TFont():New("Tahoma",,16,,.t.)

	// descricao do produto/servico
	Private _cNomPrd := ""

	// seta teclas de atalho
	SetKey(VK_F5,{|| oBtnConfirmar:Click() } )
	SetKey(VK_F6,{|| IIf(mvVisual, nil, oBtnEditar:Click() ) } )

	// define informacoes, de acordo com origem
	If (_cOrigem == 2)
		_nPosCodSrv := aScan(_aHeadPrd,{|x| AllTrim(Upper(x[2])) == "ZU_PRODUTO"})
		_nPosDscSrv := aScan(_aHeadPrd,{|x| AllTrim(Upper(x[2])) == "ZU_DESCRI"})
		_cNomPrd    := Posicione("SB1", 1, xFilial("SB1") + oBrwPrd:aCols[oBrwPrd:nAt,_nPosCodSrv], "B1_DESC")
	Else
		// linha atual
		_nLinAtu    := mvModelGrid:nLine
		// extrai dados do browse
		_cNomPrd    := mvModelGrid:GetValue('AAN_ZDESCR', _nLinAtu)
	EndIf

	// define estrutura do TRB
	aadd(_aStruTrb,{"ATI_OK"    ,"C",2                      ,0                      })
	aadd(_aStruTrb,{"ATI_COD"   ,"C",TamSx3("Z9_CODATIV")[1],0                      })
	aadd(_aStruTrb,{"ATI_DESC"  ,"C",50                     ,0                      })
	aadd(_aStruTrb,{"ATI_UNICOB","C",TamSx3("Z9_UNIDCOB")[1],0                      })
	aadd(_aStruTrb,{"ATI_VALOR" ,"N",TamSx3("Z9_VALOR")[1]  ,TamSx3("Z9_VALOR")[2]  })
	aadd(_aStruTrb,{"ATI_MAXPAC","N",TamSx3("Z9_MAXPACO")[1],TamSx3("Z9_MAXPACO")[2]})
	aadd(_aStruTrb,{"ATI_VLRMIN","N",TamSx3("Z9_VLRMIN")[1] ,TamSx3("Z9_VLRMIN")[2] })
	aadd(_aStruTrb,{"ATI_VLRMAX","N",TamSx3("Z9_VLRMAX")[1] ,TamSx3("Z9_VLRMAX")[2] })

	If (!mvVisual)
		aadd(_aBrowse,{"ATI_OK",,"",""})
	EndIf
	aadd(_aBrowse,{"ATI_COD",,"Codigo",""})
	aadd(_aBrowse,{"ATI_DESC",,"Descrição",""})
	aadd(_aBrowse,{"ATI_UNICOB",,"UM Cobr.",""})

	If (_cOrigem == 1) // servicos diversos
		aadd(_aBrowse,{"ATI_VALOR" ,,"Valor"       ,PesqPict("SZ9","Z9_VALOR")})
		aadd(_aBrowse,{"ATI_VLRMIN",,"Valor Mínimo",PesqPict("SZ9","Z9_VLRMIN")})
		aadd(_aBrowse,{"ATI_VLRMAX",,"Valor Máximo",PesqPict("SZ9","Z9_VLRMAX")})
	ElseIf (_cOrigem == 2) // pacote logistico
		aadd(_aBrowse,{"ATI_MAXPAC",,"Qtd Max",PesqPict("SZ9","Z9_MAXPACO")})
	EndIf

	// limpa dados do TRB
	If (Select(ATI)<>0)
		dbSelectArea(ATI)
		dbCloseArea()
	EndIf
	
	_cArquivo := FWTemporaryTable():New( ATI )
	_cArquivo:SetFields( _aStruTrb )
	_cArquivo:AddIndex("01", {"ATI_DESC"} )
	_cArquivo:Create()

	_cQuery := " SELECT ZT_CODIGO, ZT_DESCRIC, ZT_UM, ZT_VALOR "
	_cQuery += " FROM "+RetSqlTab("SZT")+" (nolock) "
	_cQuery += " WHERE "+RetSqlCond("SZT")
	_cQuery += " ORDER BY ZT_CODIGO"
	// alimenta o acols com o resultado do SQL
	_aColsProg := U_SqlToVet(_cQuery)

	// verifica se há historicos para visualizar
	If (Len(_aColsProg)==0)
		// mensagem
		MsgStop("Não há atividades cadastradas !")
		// retorno
		Return(.f.)
	EndIf

	For _nX := 1 To Len(_aColsProg)
		// valor padrao
		_nValor := _aColsProg[_nX][04]
		// quantidade maxima padrao
		_nQtdMaxPac := 0
		// valor minimo padrao do servico
		_nVlrMin := 0.01
		// valor maximo padrao do servico
		_nVlrMax := 999999.99
		// unid. medida de cobranca
		_cUnidCob := AllTrim(_aColsProg[_nX][03])

		// pesquisa se a atividade ja faz parte do item do contrato
		dbSelectArea("SZ9")
		SZ9->(dbSetOrder(1)) // 1-Z9_FILIAL, Z9_CONTRAT, Z9_ITEM, Z9_CODATIV
		If SZ9->(dbSeek( xFilial("SZ9") + _cNrContrt + _cItContrt + _aColsProg[_nX][01] ))
			// verifica se a unid esta preenchida
			If ( ! Empty(SZ9->Z9_UNIDCOB) )
				_cUnidCob := SZ9->Z9_UNIDCOB
			EndIf
			// valores
			_nValor		:= SZ9->Z9_VALOR
			_nQtdMaxPac	:= SZ9->Z9_MAXPACO
			_nVlrMin	:= SZ9->Z9_VLRMIN
			_nVlrMax	:= SZ9->Z9_VLRMAX
			_cOK		:= _cMarca
		Else
			_cOK := ""
			// se for visualizacao, descarta servico que nao estao no contrato
			If (mvVisual)
				Loop
			EndIf
		EndIf

		// inclui o registro no arquivo de trabalho
		(ATI)->(RecLock(ATI, .t.))
		(ATI)->ATI_OK		:= _cOK
		(ATI)->ATI_COD	:= AllTrim(_aColsProg[_nX][01])
		(ATI)->ATI_DESC	:= AllTrim(_aColsProg[_nX][02])
		(ATI)->ATI_UNICOB	:= _cUnidCob
		(ATI)->ATI_MAXPAC	:= _nQtdMaxPac
		(ATI)->ATI_VLRMIN	:= _nVlrMin
		(ATI)->ATI_VLRMAX	:= _nVlrMax
		(ATI)->ATI_VALOR	:= _nValor
		(ATI)->(MsUnLock())

	Next _nX

	// posiciona no primeiro registro
	(ATI)->(dbGotop())

	// monta o dialogo
	oDlgProgRec := MSDialog():New(000,000,400,800,"Atividades x Item do Contrato",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho
	oPnlCabec := TPanel():New(000,000,nil,oDlgProgRec,,.F.,.F.,,,000,020,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// Produto
	oGetNomPrd := TGet():New(003,003,{|u| If(PCount()>0,_cNomPrd:=u,_cNomPrd)},oPnlCabec,170,011,PesqPict("SB1","B1_DESC"),,,,oFntVerd13,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomPrd",,)
	oGetNomPrd:Disable()
	// botao para detahes do dia
	oBtnConfirma := TButton():New(003,275,"Confirmar (F5)",oPnlCabec,{|| sfConfAtiv(_cOrigem,mvVisual) },060,013,,,,.T.,,"",,,,.F. )
	If (!mvVisual)
		oBtnEditar := TButton():New(003,340,"Editar Valor (F6)",oPnlCabec,{|| sfEditVlr(_cOrigem) },060,013,,,,.T.,,"",,,,.F. )
	endIf

	// browse com a listagem dos produtos conferidos
	oBrwProgRec := MsSelect():New (ATI,IIf(mvVisual,nil,"ATI_OK"),Nil, _aBrowse, .F., _cMarca, {000,000,400,600})
	If ( ! mvVisual )
		oBrwProgRec:oBrowse:lHasMark 	:= .T.
		oBrwProgRec:oBrowse:lCanAllMark	:= .T.
		oBrwProgRec:oBrowse:bAllMark 	:= {|| MarkAll (ATI, "ATI_OK", _cMarca, @oDlgProgRec)}
	EndIf
	oBrwProgRec:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG oDlgProgRec CENTERED

	SetKey(VK_F5,{|| Nil } )
	SetKey(VK_F6,{|| Nil } )

Return

// funcao para editar valor ou quantidade maximo do servico
Static Function sfEditVlr(mvOrigem)

	Local _lFixaMain := .F.
	Private _nVlrInfor := (ATI)->ATI_VALOR
	Private _nQtdMaxPac := (ATI)->ATI_MAXPAC
	Private _nVlrMinSrv := (ATI)->ATI_VLRMIN
	Private _nVlrMaxSrv := (ATI)->ATI_VLRMAX
	private _cUnidCob	:= (ATI)->ATI_UNICOB

	// monta a tela para alterar o valor
	_oDlgInfVlr := MSDialog():New(000,000,180,260,"Informe o Valor",,,.F.,,,,,,.T.,,,.T. )

	// servicos diveros
	If (mvOrigem == 1)
		_oSayValor := TSay():New( 007,010,{||"Valor R$:"},_oDlgInfVlr,,_oFntRoda,.F.,.F.,.F.,.T.)
		_oGetValor := TGet():New( 005,070,{|u| If(PCount()>0,_nVlrInfor:=u,_nVlrInfor)},_oDlgInfVlr,50,10,PesqPict("SZT","ZT_VALOR"),{||Positivo()},,,_oFntRoda,,,.T.,"",,{|| (mvOrigem==1) },.F.,.F.,,.F.,.F.,"","_nVlrInfor",,)
		// valor minimo
		_oSayVlrMin := TSay():New( 022,010,{||"Valor Mínimo R$:"},_oDlgInfVlr,,_oFntRoda,.F.,.F.,.F.,.T.)
		_oGetVlrMin := TGet():New( 020,070,{|u| If(PCount()>0,_nVlrMinSrv:=u,_nVlrMinSrv)},_oDlgInfVlr,60,10,PesqPict("SZ9","Z9_VLRMIN"),{||Positivo()},,,_oFntRoda,,,.T.,"",,{|| (mvOrigem==1) },.F.,.F.,,.F.,.F.,"","_nVlrMinSrv",,)
		// valor maximo
		_oSayVlrMax := TSay():New( 037,010,{||"Valor Máximo R$:"},_oDlgInfVlr,,_oFntRoda,.F.,.F.,.F.,.T.)
		_oGetVlrMax := TGet():New( 035,070,{|u| If(PCount()>0,_nVlrMaxSrv:=u,_nVlrMaxSrv)},_oDlgInfVlr,60,10,PesqPict("SZ9","Z9_VLRMAX"),{||Positivo()},,,_oFntRoda,,,.T.,"",,{|| (mvOrigem==1) },.F.,.F.,,.F.,.F.,"","_nVlrMaxSrv",,)
		// unidade de medida de cobranca
		_oSayUnidCob := TSay():New( 052,010,{||"Unid. Cobrança:"},_oDlgInfVlr,,_oFntRoda,.F.,.F.,.F.,.T.)
		_oGetUnidCob := TGet():New( 050,070,{|u| If(PCount()>0,_cUnidCob:=u,_cUnidCob)},_oDlgInfVlr,30,10,PesqPict("SZ9","Z9_UNIDCOB"),{|| ExistCpo("SAH") },,,_oFntRoda,,,.T.,"",,{|| (mvOrigem==1) },.F.,.F.,,.F.,.F.,"SAH","_cUnidCob",,)

		// pacote logistico
	ElseIf (mvOrigem == 2)
		// quantidade maxima do pacote
		_oSayQtdMax := TSay():New( 007,010,{||"Quant. Máxima"},_oDlgInfVlr,,_oFntRoda,.F.,.F.,.F.,.T.)
		_oGetQtdMax := TGet():New( 005,070,{|u| If(PCount()>0,_nQtdMaxPac:=u,_nQtdMaxPac)},_oDlgInfVlr,60,10,PesqPict("SZ9","Z9_MAXPACO"),{||Positivo()},,,_oFntRoda,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nQtdMaxPac",,)
		// unidade de medida de cobranca
		_oSayUnidCob := TSay():New( 022,010,{||"Unid. Cobrança:"},_oDlgInfVlr,,_oFntRoda,.F.,.F.,.F.,.T.)
		_oGetUnidCob := TGet():New( 020,070,{|u| If(PCount()>0,_cUnidCob:=u,_cUnidCob)},_oDlgInfVlr,30,10,PesqPict("SZ9","Z9_UNIDCOB"),{|| ExistCpo("SAH") },,,_oFntRoda,,,.T.,"",,{|| .t. },.F.,.F.,,.F.,.F.,"SAH","_cUnidCob",,)

	EndIf

	// botao para confirmar
	_oBtnConfirmar := TButton():New(070,040,"Confirmar",_oDlgInfVlr,{||_lFixaMain:=.t.,_oDlgInfVlr:End()},050,012,,,,.T.,,"",,,,.F. )

	// ativacao da tela com validacao
	_oDlgInfVlr:Activate(,,,.T.,{||_lFixaMain})

	// se foi confirmado
	If (_lFixaMain)
		(ATI)->(RecLock(ATI,.F.))
		(ATI)->ATI_VALOR	:= _nVlrInfor
		(ATI)->ATI_MAXPAC	:= _nQtdMaxPac
		(ATI)->ATI_VLRMIN	:= _nVlrMinSrv
		(ATI)->ATI_VLRMAX	:= _nVlrMaxSrv
		(ATI)->ATI_UNICOB	:= _cUnidCob
		(ATI)->(MsUnLock())
	Endif

Return(.t.)

// ** funcao para confirmar o recebimento
Static Function sfConfAtiv(_cOrigem,mvVisual)

	//Valida Valores
	If ( ! mvVisual )
		(ATI)->(dbSelectArea(ATI))
		(ATI)->(dbGotop())
		While !(ATI)->(EOF())
			If (ATI)->ATI_OK == _cMarca
				// se for servicos diversos
				If (_cOrigem == 1)
					// verifica se o valor esta informado
					If ((ATI)->ATI_VALOR <= 0)
						Alert("ERRO !! Existem atividades selecionadas com valor zerado !! ")
						Return(.f.)
					EndIf
					// verifica se o valor minimo esta informado
					If ((ATI)->ATI_VLRMIN <= 0)
						Alert("ERRO !! Existem atividades selecionadas com valor mínimo zerado !! ")
						Return(.f.)
					EndIf
					// verifica se o valor maximo esta informado
					If ((ATI)->ATI_VLRMAX <= 0)
						Alert("ERRO !! Existem atividades selecionadas com valor máximo zerado !! ")
						Return(.f.)
					EndIf
					// verifica se o valor minimo menor que valor maximo
					If ((ATI)->ATI_VLRMAX <= (ATI)->ATI_VLRMIN)
						Alert("ERRO !! Existem atividades selecionadas com valor máximo menor e/ou igual ao valor mínimo !! ")
						Return(.f.)
					EndIf

				EndIf
				// se for pacote logistico, verifica se a quantidade maxima esta informado
				If (_cOrigem == 2).and.( (ATI)->ATI_MAXPAC <= 0)
					Alert("ERRO !! Existem atividades selecionadas com quantidade máxima zerada !! ")
					Return(.f.)
				EndIf
			EndIf
			(ATI)->(dbSkip())
		EndDo

		// Limpa atividades
		cQuery := "UPDATE "+RetSqlName("SZ9")+" SET D_E_L_E_T_ = '*' WHERE Z9_FILIAL = '"+xFilial("SZ9")+"' AND D_E_L_E_T_ = ' ' "
		cQuery += "AND Z9_CONTRAT = '"+_cNrContrt+"' AND Z9_ITEM = '" + _cItContrt + "' "
		TCSQLEXEC(cQuery)

		// Grava atividades do item do contrato
		(ATI)->(dbSelectArea(ATI))
		(ATI)->(dbGotop())
		While (ATI)->( ! EOF() )
			If ((ATI)->ATI_OK == _cMarca)
				dbSelectArea("SZ9")
				RecLock("SZ9",.T.)
				SZ9->Z9_FILIAL	:= xFilial("SZ9")
				SZ9->Z9_CONTRAT	:= _cNrContrt
				SZ9->Z9_ITEM	:= _cItContrt
				SZ9->Z9_CODATIV	:= (ATI)->ATI_COD
				SZ9->Z9_UNIDCOB	:= (ATI)->ATI_UNICOB
				SZ9->Z9_MAXPACO	:= (ATI)->ATI_MAXPAC
				SZ9->Z9_VALOR	:= (ATI)->ATI_VALOR
				SZ9->Z9_VLRMIN	:= (ATI)->ATI_VLRMIN
				SZ9->Z9_VLRMAX	:= (ATI)->ATI_VLRMAX
				MsUnlock()
			EndIf
			(ATI)->(dbSkip())
		EndDo

		sfLimpaArq()
	EndIf

	oDlgProgRec:End()

Return(.t.)

Static Function sfLimpaArq()
	
	_cArquivo:Delete()
	
Return(.t.)

// ** Funcao que marca todos os itens quando clicar no header da coluna
Static Function MarkAll (mvAlias, mvCampo, mvFlag, mvDlg)
	// area inicial
	Local _nReg := (mvAlias)->(RecNo ())
	// posiciona primeiro registro
	(mvAlias)->(DbGoTop ())
	// atualiza campo
	DbEval ({|| (RecLock (mvAlias, .F.), &(mvAlias+"->"+mvCampo) := Iif (Empty (&(mvAlias+"->"+mvCampo)), mvFlag, " "), MsUnLock ())})
	// posicao inicial
	(mvAlias)->(DbGoto(_nReg))
	// atualiza browse
	mvDlg:Refresh ()
Return (.T.)

// ** funcao que retorna as opcoes do campo X3_CBOX
Static Function sfCboxToArray(mvCampo)
	Local _aArea    := GetArea()
	Local _aAreaSX3 := SX3->(GetArea())
	Local _cBox     := ""
	Local _aBox     := {}
	Local _nPosicao1:= 0
	Local _nPosicao2:= 0
	Local _cElem    := ""

	dbSelectArea("SX3")
	dbSetOrder(2)
	If ( MsSeek(mvCampo) )
		_cBox := x3CBox()
		While ( !Empty(_cBox) )
			_nPosicao1 := At(";",_cBox)
			If ( _nPosicao1 == 0 )
				_nPosicao1 := Len(_cBox)+1
			EndIf
			_nPosicao2	:= At("=",_cBox)
			_cElem		:= SubStr(_cBox,_nPosicao2+1,_nPosicao1-_nPosicao2-1)
			aadd(_aBox,_cElem)
			_cBox := SubStr(_cBox,_nPosicao1+1)
		EndDo
	EndIf
	aadd(_aBox,"")
	// restaura area inicial
	RestArea(_aAreaSX3)
	RestArea(_aArea)

Return(_aBox)

// ** funcao que retorna a descricao de campo combobox
Static Function sfCBoxDescr(mvCampo,mvConteudo,mvPesq,mvRet)
	Local _aAreaSX3 := SX3->(GetArea())
	// retorno em array
	// 1 -> S=Sim
	// 2 -> S
	// 3 -> Sim
	Local _aCbox := RetSx3Box(Posicione('SX3',2,mvCampo,'X3CBox()'),,,TamSx3(mvCampo)[1])
	Local _nPos  := aScan( _aCbox , {|x| AllTrim(x[mvPesq]) == AllTrim(mvConteudo) } )
	Local _cRet  := If(_nPos>0,_aCbox[_nPos,mvRet],"")
	// restaura area inicial
	RestArea(_aAreaSX3)
Return(_cRet)

// ** funcao que apresenta todos os grupos de estoque
Static Function sfBtnGrpEst(mvVisual)

	// objetos da tela
	local _oDlgGrpEst
	local _oBrwGrpEst

	// estrutuar do TRB
	local _cArqTrb
	local _TRBGRPEST := GetNextAlias()
	Local _aStruTrb  := {}
	Local _aBrowse   := {}
	local _cMarcaTrb := GetMark()

	// variavel temporaria
	local _aTmpGrpEst
	local _nGrpEst

	// query
	local _cQuery

	// variavel usada para visualizacao
	local _cMsgGrpEst := ""

	// valida se o alias esta aberto
	If (Select(_TRBGRPEST)==0)

		// estrutuar do TRB
		aadd(_aStruTrb,{"GRP_OK"   ,"C",2,0})
		aadd(_aStruTrb,{"GRP_COD"  ,"C",TamSx3("Z36_CODIGO")[1],0})
		aadd(_aStruTrb,{"GRP_DESC" ,"C",TamSx3("Z36_DESCRI")[1],0})
		
		If (Select(_TRBGRPEST)<>0)
			dbSelectArea(_TRBGRPEST)
			dbCloseArea()
		EndIf
		// cria o arquivo de trabalho
		_cArqTrb := FWTemporaryTable():New( _TRBGRPEST )
		_cArqTrb:SetFields( _aStruTrb )
		_cArqTrb:Create()
		
	Else
		// limpa o conteudo do TRB
		(_TRBGRPEST)->(dbSelectArea(_TRBGRPEST))
		__DbZap()

	EndIf

	// campos do browse
	aadd(_aBrowse,{"GRP_OK"  ,,""})
	aadd(_aBrowse,{"GRP_COD" ,,"Codigo"})
	aadd(_aBrowse,{"GRP_DESC",,"Descrição"})

	// prepara query para buscar os dados
	_cQuery := " SELECT Z36_CODIGO, Z36_DESCRI "
	// cad. de cliente
	_cQuery += " FROM " + RetSqlTab("SA1") + " (nolock) "
	// cad. de grupo de estoque
	_cQuery += " INNER JOIN " + RetSqlTab("Z36") + " (nolock)  ON " + RetSqlCond("Z36") + " AND Z36_SIGLA = A1_SIGLA "
	// se for somente visualizacao
	If (mvVisual)
		_cQuery += " AND Z36_CODIGO IN " + FormatIn(_cGrpEsto,";")
	EndIf
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("SA1")
	// codigo e loja do cliente
	_cQuery += " AND A1_COD = '" + M->AAM_CODCLI + "' AND A1_LOJA = '" + M->AAM_LOJA + "' "
	// ordem dos dados
	_cQuery += " ORDER BY Z36_CODIGO "

	// alimenta o acols com o resultado do SQL
	_aTmpGrpEst := U_SqlToVet(_cQuery)

	// se for visualizacao, mostra mensagem com as pracao
	If (mvVisual)
		For _nGrpEst := 1 To Len(_aTmpGrpEst)
			_cMsgGrpEst += _aTmpGrpEst[_nGrpEst][1]+"-"+AllTrim(_aTmpGrpEst[_nGrpEst][2])+CRLF
		Next _nGrpEst
		// apresenta mensagem
		HS_MsgInf(_cMsgGrpEst,"Grupos de Estoque","Grupos de Estoque")
		Return(.f.)
	EndIf

	// verifica se há historicos para visualizar
	If (Len(_aTmpGrpEst)==0)
		MsgStop("Não há Grupos de Estoque disponíveis.")
		Return(.f.)
	EndIf

	// atualiza o arquivo de trabalho
	For _nGrpEst := 1 To Len(_aTmpGrpEst)
		(_TRBGRPEST)->(RecLock(_TRBGRPEST,.T.))
		(_TRBGRPEST)->GRP_OK   := IIf(_aTmpGrpEst[_nGrpEst][01] $ _cGrpEsto, _cMarcaTrb, "")
		(_TRBGRPEST)->GRP_COD  := AllTrim(_aTmpGrpEst[_nGrpEst][01])
		(_TRBGRPEST)->GRP_DESC := AllTrim(_aTmpGrpEst[_nGrpEst][02])
		(_TRBGRPEST)->(MsUnLock())
	Next _nGrpEst
	// posiciona no primeiro item
	(_TRBGRPEST)->(dbGotop())

	// monta o dialogo
	_oDlgGrpEst := MSDialog():New(000,000,400,600,"Grupos de Estoque",,,.F.,,,,,,.T.,,,.T. )

	// browse com a listagem do grupo de estoque
	_oBrwGrpEst := MsSelect():New(_TRBGRPEST,"GRP_OK",Nil, _aBrowse, .F., _cMarcaTrb, {000,000,400,600})
	_oBrwGrpEst:oBrowse:lHasMark    := .T.
	_oBrwGrpEst:oBrowse:lCanAllMark := .T.
	_oBrwGrpEst:oBrowse:bAllMark    := {|| MarkAll (_TRBGRPEST, "GRP_OK", _cMarcaTrb, @_oDlgGrpEst)}
	_oBrwGrpEst:oBrowse:Align       := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oDlgGrpEst CENTERED

	// atualiza informacoes
	(_TRBGRPEST)->(dbGotop())
	// zera variavel
	_cGrpEsto := ""
	// varre todos os itens
	While (_TRBGRPEST)->( ! Eof() )
		If ((_TRBGRPEST)->GRP_OK == _cMarcaTrb)
			_cGrpEsto += AllTrim((_TRBGRPEST)->GRP_COD)+";"
		EndIf
		// proximo item
		(_TRBGRPEST)->(dbSkip())
	EndDo

	// padroniza variavel de retorno
	_cGrpEsto := SubStr(_cGrpEsto,1,Len(_cGrpEsto)-1)

Return(.t.)