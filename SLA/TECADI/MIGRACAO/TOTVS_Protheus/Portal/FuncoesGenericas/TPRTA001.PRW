#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Definicao de menu especifico para usuarios do portal    !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 05/2014                                                 !
+------------------+--------------------------------------------------------*/

User Function TPRTA001
	// estrutura do TRB
	Local _aStrTrb   := {}
	Local _aBrwTrb   := {}
	local _cBrwMarca := GetMark()
	local _cAlTrb    := GetNextAlias()
	
	// objetos da tela
	local _oDlgSelMenu
	local _oPnlCabec
	local _oSayTitulo
	local _oBrwItMenu
	
	// controle de confirmacao da tela
	local _lRetOk := .f.
	
	// codigo do portal
	local _cCodPortal := "000011"
	
	// cria a tabela de menus
	dbSelectArea("Z28")
	
	// define campos do TRB
	aadd(_aStrTrb,{"IT_OK"    ,"C", 2,0})
	aadd(_aStrTrb,{"IT_CODMNU","C", 6,0})
	aadd(_aStrTrb,{"IT_CODPAI","C", 6,0})
	aadd(_aStrTrb,{"IT_CHAVE" ,"C",20,0})
	aadd(_aStrTrb,{"IT_DESCR" ,"C",60,0})
	
	// define campos do browse do TRB
	aadd(_aBrwTrb,{"IT_OK"    ,,"",""})
	//aadd(_aBrwTrb,{"IT_CODMNU",,"Menu",""})
	//aadd(_aBrwTrb,{"IT_CODPAI",,"Pai",""})
	//aadd(_aBrwTrb,{"IT_CHAVE" ,,"Chave",""})
	aadd(_aBrwTrb,{"IT_DESCR" ,,"Descrição",""})
	
	// fecha alias do arquivo de trabalho
	If (Select(_cAlTrb)<>0)
		(_cAlTrb)->(dbSelectArea(_cAlTrb))
		(_cAlTrb)->(dbCloseArea())
	EndIf
	
	// cria o TRB
	_oAlTrb := FWTemporaryTable():New(_cAlTrb)
	_oAlTrb:SetFields(_aStrTrb)
	_oAlTrb:Create()

	IndRegua((_cAlTrb),_oAlTrb:cIndexName,"IT_CODMNU")
	
	// atualiza os dados no TRB
	sfAtuDados((_cAlTrb),_cBrwMarca, _cCodPortal)
	
	// seleciona o TRB
	(_cAlTrb)->(dbSelectArea(_cAlTrb))
	IndRegua((_cAlTrb),_oAlTrb:cIndexName,"IT_CHAVE")
	(_cAlTrb)->(dbSetOrder(1))
	(_cAlTrb)->(dbGotop())
	
	// monta o dialogo
	_oDlgSelMenu := MSDialog():New(000,000,460,700,"Definição de menu por usuário",,,.F.,,,,,,.T.,,,.T. )
	
	// cria o panel com o titulo
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgSelMenu,,.F.,.F.,,,020,020,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP
	
	// titulo com o nome do usuario
	_oSayTitulo := TSay():New(007,010,{||"Usuário: "+AllTrim(AI3->AI3_NOME) },_oPnlCabec,,,.F.,.F.,.F.,.T.)
	
	// browse com a listagem dos itens no meno
	_oBrwItMenu := MsSelect():New ((_cAlTrb),"IT_OK",Nil, _aBrwTrb, .F., _cBrwMarca, {000,000,400,600})
	_oBrwItMenu:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwItMenu:bMark := {|| sfVldMark(_cAlTrb, _cBrwMarca, _oBrwItMenu) }
	
	// ativa a tela
	ACTIVATE MSDIALOG _oDlgSelMenu CENTERED ON INIT EnchoiceBar(_oDlgSelMenu,{|| _lRetOk := .t., _oDlgSelMenu:End()} ,{|| _oDlgSelMenu:End() })
	
	// se foi confirmado
	If (_lRetOk)
		
		// varre todos os itens do TRB
		dbSelectArea(_cAlTrb)
		(_cAlTrb)->(dbGoTop())
		While (_cAlTrb)->(!Eof())
			
			// verifica se o item existe na tabela Z28
			dbSelectArea("Z28")
			Z28->(dbSetOrder(1)) // 1-Z28_FILIAL, Z28_PORTAL, Z28_CODUSU, Z28_CODMNU
			If Z28->(dbSeek( xFilial("Z28")+_cCodPortal+AI3->AI3_CODUSU+(_cAlTrb)->IT_CODMNU ))
				If (Empty((_cAlTrb)->IT_OK)) // excluir
					RecLock("Z28")
					Z28->(DbDelete())
					Z28->(MsUnLock())
				EndIf
	
			ElseIf ( ! Empty((_cAlTrb)->IT_OK)) // incluir
				RecLock("Z28",.t.)
				Z28->Z28_FILIAL := xFilial("Z28")
				Z28->Z28_CODUSU := AI3->AI3_CODUSU
				Z28->Z28_PORTAL := _cCodPortal
				Z28->Z28_CODMNU := (_cAlTrb)->IT_CODMNU
				Z28->(MsUnLock())
				
			EndIf
			
			// proximo item
			(_cAlTrb)->(dbSkip())
		EndDo
	EndIf
	
	// exclui informacoes temporarias
	If ( ! Empty(_cAlTrb) )
		fErase(_cAlTrb + GetDBExtension())
		fErase(_cAlTrb + OrdBagExt())
		(_cAlTrb)->(DbCloseArea())
		_oAlTrb:Delete()
	Endif
	
Return
	
// ** funcao que atualiza o TRB e organiza os menus na ordem correta
Static Function sfAtuDados(mvAlTrb, mvBrwMarca, mvCodPortal)
	// variaveis temporarias
	local _cQuery := ""
	local _aTmpMenu := {}
	local _nTmpMenu
	local _cNivel     := "01"
	local _cSubNivel  := ""
	local _cCodMnuPai := ""
	
	// monta query para buscar os acessos disponiveis por usuario
	_cQuery := "SELECT "
	_cQuery += "CASE WHEN Z28_CODMNU IS NULL THEN '  ' ELSE '"+mvBrwMarca+"' END IT_OK, "
	_cQuery += "AI8_CODMNU, AI8_CODPAI, AI8_TEXTO, Z28_CODMNU, AI8_ORDEM "
	// cadastro de todos os menus
	_cQuery += "FROM "+RetSqlName("AI8")+" AI8 "
	// menus especificos do usuario
	_cQuery += "LEFT JOIN "+RetSqlName("Z28")+" Z28 ON "+RetSqlCond("Z28")+" AND Z28_PORTAL = AI8_PORTAL AND Z28_CODMNU = AI8_CODMNU "
	// codigo do usuario
	_cQuery += "AND Z28_CODUSU = '"+AI3->AI3_CODUSU+"'
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("AI8")
	// codigo menu portal de clientes
	_cQuery += "AND AI8_PORTAL = '"+mvCodPortal+"' "
	// ordem dos dados
	_cQuery += "ORDER BY AI8_CODPAI, AI8_ORDEM"
	
	// alimenta o vetor com o resultado do SQL
	_aTmpMenu := U_SqlToVet(_cQuery)
	
	// atualiza o TRB
	For _nTmpMenu := 1 to Len(_aTmpMenu)
		
		// pesquisa no TRB chave existente
		dbSelectArea(mvAlTrb)
		(mvAlTrb)->(dbSetOrder(1))
		If (mvAlTrb)->(dbSeek( _aTmpMenu[_nTmpMenu][3] ))
			// nivel
			_cNivel := (mvAlTrb)->IT_CHAVE
			
			// novo sub-nivel
			If (_cCodMnuPai != _aTmpMenu[_nTmpMenu][3])
				_cCodMnuPai := _aTmpMenu[_nTmpMenu][3]
				_cSubNivel  := "01"
			Else
				_cSubNivel  := Soma1(_cSubNivel)
			EndIf
	
		EndIf
		
		// inclui o registro
		dbSelectArea(mvAlTrb)
		RecLock(mvAlTrb,.t.)
		(mvAlTrb)->IT_OK     := _aTmpMenu[_nTmpMenu][1]
		(mvAlTrb)->IT_CODMNU := _aTmpMenu[_nTmpMenu][2]
		(mvAlTrb)->IT_CHAVE  := AllTrim(_cNivel) + AllTrim(_cSubNivel)
		(mvAlTrb)->IT_CODPAI := _aTmpMenu[_nTmpMenu][3]
		(mvAlTrb)->IT_DESCR  := "| "+Replicate(". ",Len(AllTrim((mvAlTrb)->IT_CHAVE)))+_aTmpMenu[_nTmpMenu][4]
		(mvAlTrb)->(MsUnLock())
		
		// proxima sequencia do nivel
		_cNivel := Soma1(_cNivel)
		
	Next _nTmpMenu
	
Return
	
// ** funcao que valida a marcacao do item
Static Function sfVldMark(mvAlTrb, mvMarca, mvBrwItMenu)
	// area inicial
	local _aAreaAtu   := (mvAlTrb)->(GetArea())
	local _cTmpChave  := ""
	local _nTamChave  := 0
	local _cTmpMarca  := (mvAlTrb)->IT_OK
	local _cTmpCodPai := ""
	
	// controle de deve mudar status
	local _lMudaStatus := .t.
	
	// armazena variaveis
	_cTmpChave := AllTrim((mvAlTrb)->IT_CHAVE)
	_nTamChave := Len(_cTmpChave)
	
	// verifica todos os itens com a mesma chave (marca itens abaixo com dependencia ao item selecionado)
	dbSelectArea(mvAlTrb)
	(mvAlTrb)->(dbGoTop())
	While (mvAlTrb)->(!Eof())
		// verifica se esta desmarcado
		If (SubStr((mvAlTrb)->IT_CHAVE,1,_nTamChave) == _cTmpChave)
			// atualiza o status do campo
			RecLock(mvAlTrb)
			(mvAlTrb)->IT_OK := _cTmpMarca
			(mvAlTrb)->(MsUnLock())
		EndIf
		// proximo item
		(mvAlTrb)->(dbSkip())
	EndDo
	
	// restaura area inicial
	RestArea(_aAreaAtu)
	
	// armazena codigo pai
	_cTmpCodPai := (mvAlTrb)->IT_CODPAI
	
	// posiciona no fim do TRB (valida de baixo pra cima)
	dbSelectArea(mvAlTrb)
	(mvAlTrb)->(dbGoBottom())
	
	// verifica a necessidade de selecionar itens pais
	While (mvAlTrb)->(!Bof())
		
		// verifica necessidade de marcar/desmarcar itens ACIMA
		If (_lMudaStatus)
			// se foi desmarcado, for outra chave, tem o mesmo pai e esta selecionado
			If (Empty(_cTmpMarca)) .and. (AllTrim((mvAlTrb)->IT_CHAVE) <> _cTmpChave) .and. (_cTmpCodPai == (mvAlTrb)->IT_CODPAI) .and. ( ! Empty((mvAlTrb)->IT_OK) )
				_lMudaStatus := .f.
			EndIf
		EndIf
	
		// se for outra chave e o for o "pai", atualiza status do Ok	
		If (AllTrim((mvAlTrb)->IT_CHAVE) <> _cTmpChave).and.(_cTmpCodPai == (mvAlTrb)->IT_CODMNU)
			
			// define novo codigo do menu "pai"
			_cTmpCodPai := (mvAlTrb)->IT_CODPAI
			
			// se deve atualizar status
			If (_lMudaStatus)
				RecLock(mvAlTrb)
				(mvAlTrb)->IT_OK := _cTmpMarca
				(mvAlTrb)->(MsUnLock())
				
				// volta para o final para uma nova analise com o novo menu "pai"
				(mvAlTrb)->(dbGoBottom())
				
			EndIf
			
		EndIf
		
		// proximo item
		(mvAlTrb)->(dbSkip(-1))
	EndDo
	
	// restaura area inicial
	RestArea(_aAreaAtu)
	
	// refresh do browse
	mvBrwItMenu:oBrowse:Refresh()

Return(.t.)