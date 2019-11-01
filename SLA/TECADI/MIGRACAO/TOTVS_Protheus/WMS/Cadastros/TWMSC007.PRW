#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Cadastro de SKU/Item                                    !
+------------------+---------------------------------------------------------+
!Autor             ! David Branco                ! Data de Criacao ! 03/2015 !
+------------------+---------------------------------------------------------+
!Chamada           ! Chamado a partir da rotina de Cadastro de Produtos      !
+------------------+--------------------------------------------------------*/

User Function TWMSC007 ()

	// filtro do browse
	Local _cFilBrw := ""
	// label da tela
	Private _cCadastro := "Cadastro de SKU/Item"

	// inclusão de botão
	Private aRotina := { { "Cadastrar SKU"    ,"U_WMSC007A(SB1->B1_COD)",0,3} };

	// select area
	dbSelectArea("SB1")

	// filtro do browse
	_cFilBrw := "B1_ZTIPPRO = 'A' "

	// browse inicial
	SB1->(DbSetOrder(1))
	mBrowse(6,1,22,75,"SB1",,,,,,,,,,,,,,_cFilBrw)

Return

// ** funcao de cadastro de sku
User Function WMSC007A(mvCodProd)
	// label
	local _oCodPro, _oPnlCabec, _oPnlRodape, _oPnlGetDados
	// info tsay
	local _cCodDescPrd := ""
	// objetos
	local _oBtnConf, _oBtnCanc, _oTGetD, _oTGetC
	// acols do browse
	Local _aColsSku := {}
	// tamanho da tela
	local _aSizeDlg := MsAdvSize()
	// array do browse com os campos do cadastro
	Private _aHeadSku := {}
	// browse
	private _oBrwSku
	// define o valor da variavel padrao N
	Private N := 1

	// posiciono no produto
	dbSelectArea("SB1")
	SB1->(dbSetOrder(1)) // filial+codigo
	SB1->(dbSeek(xFilial("SB1") + mvCodProd))

	//valida se já possui cadastro de código de barras no cadastro de produto
	If (( !Empty(SB1->B1_ZTPBAR) ) .OR. ( !Empty(SB1->B1_CODBAR) ))
		Aviso("A010TOK",;
		+ "Este produto já possui códigos de barras cadastrados na rotina CADASTRO DE PRODUTO. Para evitar duplicidade ou conflito"; 
		+ " limpe os campos 'código de barras' e 'tipo do código de barras' no cadastro principal do produto caso queira utilizar.";
		+ " esta rotina.";
		,{"Fechar"})

		Return( .F. )
	EndIf

	// valida o típo de produto
	If (SB1->B1_ZTIPPRO != "A")
		MsgStop("Não permitido para esse produto!")
		Return
	EndIf

	// header do browse
	aAdd(_aHeadSku,{"Ordem"           , "Z32_ORDEM" , PesqPict("Z32","Z32_ORDEM") , TamSx3("Z32_ORDEM")[1] , 0                      , "U_WMSC007B(_oBrwSku,'ORDEM')"   , Nil, "C", Nil, "R",,,".F." })
	aAdd(_aHeadSku,{"Tipo"            , "Z32_TIPO"  , PesqPict("Z32","Z32_TIPO")  , TamSx3("Z32_TIPO")[1]  , TamSx3("Z32_TIPO")[2]  , "U_WMSC007B(_oBrwSku,'TIPO')"    , Nil, "C", Nil, "R",,,".T." })
	aAdd(_aHeadSku,{"Descrição"       , "Z32_DESC"  , PesqPict("Z32","Z32_DESC")  , TamSx3("Z32_DESC")[1]  , TamSx3("Z32_DESC")[2]  , "U_WMSC007B(_oBrwSku,'DESC')"    , Nil, "C", Nil, "R",,,".T." })
	aAdd(_aHeadSku,{"Quantidade"      , "Z32_QUANT" , PesqPict("Z32","Z32_QUANT") , TamSx3("Z32_QUANT")[1] , TamSx3("Z32_QUANT")[2] , "U_WMSC007B(_oBrwSku,'QUANT')"   , Nil, "N", Nil, "R",,,".T." })
	aAdd(_aHeadSku,{"Tip Cod Barras"  , "Z32_ZTPBAR", PesqPict("Z32","Z32_ZTPBAR"), TamSx3("Z32_ZTPBAR")[1], TamSx3("Z32_ZTPBAR")[2], "U_WMSC007B(_oBrwSku,'TPCODBAR')", Nil, "C", Nil, "R",,,".T." })
	aAdd(_aHeadSku,{"Código de Barras", "Z32_CODBAR", PesqPict("Z32","Z32_CODBAR"), TamSx3("Z32_CODBAR")[1], TamSx3("Z32_CODBAR")[2], "U_WMSC007B(_oBrwSku,'CODBAR')"  , Nil, "C", Nil, "R",,,".T." })

	// janela
	DEFINE DIALOG _oDlgSku TITLE "Cadastro de SKU/Item" FROM _aSizeDlg[7],000 TO _aSizeDlg[6],_aSizeDlg[5] PIXEL

	// preencho o aCols
	_aColsSku := sfRetSku(SB1->B1_COD)

	// cria o panel topo
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgSku,,.F.,.F.,,,000,040,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// cria o panel do meio
	_oPnlGetDados := TPanel():New(000,000,nil,_oDlgSku,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlGetDados:Align := CONTROL_ALIGN_ALLCLIENT

	// cria o panel do rodape
	_oPnlRodape := TPanel():New(000,000,nil,_oDlgSku,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlRodape:Align := CONTROL_ALIGN_BOTTOM

	// mostra o código do produto
	_oTGetC := TGet():New(014,006,{|| SB1->B1_COD },_oPnlCabec,096,009,"@!",,0,,,.F.,,.T.,,.F.,{||.F.},.F.,.F.,,.T.,.F.,,,,,,,,,"Código: ",2,,,, )
	// mostra a decrição do produto
	_oTGetD := TGet():New(014,124,{|| SB1->B1_DESC },_oPnlCabec,200,009,"@!",,0,,,.F.,,.T.,,.F.,{||.F.},.F.,.F.,,.T.,.F.,,,,,,,,,"Descri: ",2,,,, )
	// browse
	_oBrwSku:= MsNewGetDados():New(030,000,240,263,GD_INSERT + GD_UPDATE + GD_DELETE,"U_WMSC007B(_oBrwSku,'LINHAOK')",'AllwaysTrue()',,,,,,'AllwaysTrue()','AllwaysTrue()',_oPnlGetDados,_aHeadSku,_aColsSku)
	_oBrwSku:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// botao confirmar
	_oBtnConf := TButton():New(006, 006, "Confirmar",_oPnlRodape,{|| IIF(sfConfirma(_oBrwSku:aCols),_oDlgSku:End(),"") }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	// botao cancelar
	_oBtnCanc := TButton():New(006, 062, "Cancelar",_oPnlRodape,{|| _oDlgSku:End() }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// ativa a janela
	ACTIVATE DIALOG _oDlgSku CENTERED

Return

// ** funcao que retorna os itens da tabela Z32
Static Function sfRetSku(mvCodProd)
	// variavel de retorno
	Local _vRetItens := {}
	Local _nX
	// chave de pesquisa
	Local _cSeek
	// variavel de controle
	local _lRet := .T.

	dbSelectArea("Z32")
	Z32->(dbSetOrder(1)) //1-Z32_FILIAL, Z32_CODPRO, Z32_ORDEM
	// procuro o produto na Z32
	_lRet := Z32->(dbSeek( _cSeek := xFilial("Z32")+mvCodProd ))

	// caso não exista, eu gravo um registro na tabela
	If ( ! _lRet)
		Reclock("Z32",.T.)
		Z32->Z32_FILIAL	:= xFilial("Z32")
		Z32->Z32_CODPRO := SB1->B1_COD
		Z32->Z32_DESC   := SB1->B1_COD
		Z32->Z32_QUANT  := 1 // quantidade inicial
		Z32->Z32_ORDEM  := StrZero(1,Len(Z32->Z32_ORDEM))
		Z32->Z32_ZTPBAR := "1"
		Z32->Z32_CODBAR := SB1->B1_CODBAR
		Z32->Z32_TIPO   := "0" // 0=Unitario/Unico; 1=Por Caixa/Volume; 9=Palete Completo
		//finalizo a operação
		MsUnlock()
	EndIf

	// inclui todos os itens
	While Z32->(!Eof()).and.(Z32->(Z32_FILIAL+Z32_CODPRO)==_cSeek)
		// cria a linha de acordo com os campos do Header
		aadd(_vRetItens, { Z32->Z32_ORDEM, Z32->Z32_TIPO, Z32->Z32_DESC, Z32->Z32_QUANT, Z32_ZTPBAR, Z32->Z32_CODBAR, .f.})
		// proximo item
		Z32->(dbSkip())
	EndDo

	// define tamanho da variavel N
	N := Len(_vRetItens)

Return(_vRetItens)

// ** Funcao responsavel pela gravacao dos dados
Static Function sfConfirma(mvArrBrowse)
	// len do array
	local _nLenArray  := Len(mvArrBrowse)
	// controle de transações
	local _lRet       := .T.
	// controle da nova sequencia para os itens
	local _nNewSeq    := 1
	// variavel de log
	local _cLogMsg    := ""
	// qry pra validar a ordem
	local _cQryOrd    := ""
	// controle do for
	local _nItemAtu   := 0
	// controle do for
	local _nX		  := 0
	// controle da nova ordem
	local _nNewSeq := 1
	// array update da ordem
	local _aUpdOrd := {}

	// posicao dos campos
	local _nP_Ordem   := aScan(_aHeadSku,{|x| AllTrim(Upper(x[2]))=="Z32_ORDEM" }) // ordem
	local _nP_Tipo    := aScan(_aHeadSku,{|x| AllTrim(Upper(x[2]))=="Z32_TIPO"  }) // tipo
	local _nP_Descr   := aScan(_aHeadSku,{|x| AllTrim(Upper(x[2]))=="Z32_DESC"  }) // descricao
	local _nP_Quant   := aScan(_aHeadSku,{|x| AllTrim(Upper(x[2]))=="Z32_QUANT" }) // quantidade
	local _nP_TpCdBar := aScan(_aHeadSku,{|x| AllTrim(Upper(x[2]))=="Z32_ZTPBAR"}) // tipo codigo de barras
	local _nP_CodBar  := aScan(_aHeadSku,{|x| AllTrim(Upper(x[2]))=="Z32_CODBAR"}) // codigo de barras
	local _nP_Delete  := Len(_aHeadSku)+1                                          // deletados

	// query
	local _cQuery

	// dados do cadastro
	local _aTmpDados

	//valida se já possui cadastro de código de barras no cadastro de produto
	If (( !Empty(SB1->B1_ZTPBAR) ) .OR. ( !Empty(SB1->B1_CODBAR) ))
		Aviso("TWMSC007",;
		+ "O produto " + SB->B1_COD + " já possui códigos de barras cadastrados na rotina CADASTRO DE SKU." + CRLF; 
		+ "Para evitar duplicidade ou conflitolimpe os campos 'código de barras' e 'tipo do código de barras'.";
		,{"Fechar"})

		Return ( .F. )
	EndIf

	// varro o array fazendo as validações
	For _nItemAtu := 1 to _nLenArray

		// prepara query para validacao do codigo de barras - cad produto
		_cQuery := " SELECT B1_COD "
		_cQuery += " FROM   " + RetSqlTab("SB1")
		_cQuery += " WHERE  " + RetSqlCond("SB1")
		_cQuery += "        AND B1_GRUPO = '" + SB1->B1_GRUPO + "' "
		_cQuery += "        AND B1_CODBAR = '" + mvArrBrowse[_nItemAtu][_nP_CodBar] + "' "

		// executa query
		_aTmpDados := U_SqlToVet(_cQuery)

		// valida se tem produto duplicado
		If (Len(_aTmpDados) != 0) .AND. ( !Empty(mvArrBrowse[_nItemAtu][_nP_CodBar]) )
			// mensagem
			MsgStop("Código de Barras já está em uso por outro produto, na rotina de CADASTRO PRINCIPAL! (Linha: " + AllTrim(Str(_nItemAtu)) + ")" + CRLF + "Produto (Cadastro): " + AllTrim(_aTmpDados[1]))
			// retorno
			Return( .F. )
		EndIf

		// prepara query para validacao do codigo de barras
		_cQuery := " SELECT Z32_CODPRO "
		_cQuery += " FROM   " + RetSqlTab("Z32")
		_cQuery += " WHERE  " + RetSqlCond("Z32")
		_cQuery += "        AND SUBSTRING(Z32_CODPRO,1,4) = '" + SB1->B1_GRUPO + "' "
		_cQuery += "        AND Z32_CODPRO != '" + SB1->B1_COD + "' "
		_cQuery += "        AND Z32_CODBAR = '" + mvArrBrowse[_nItemAtu][_nP_CodBar] + "' "

		// executa query
		_aTmpDados := U_SqlToVet(_cQuery)

		// valida se tem produto duplicado
		If (Len(_aTmpDados) != 0) .AND. ( !Empty(mvArrBrowse[_nItemAtu][_nP_CodBar]) )
			// mensagem
			MsgStop("Código de Barras já está em uso por outro produto! (Linha: " + AllTrim(Str(_nItemAtu)) + ")" + CRLF + "Verifique o produto (Sku): " + AllTrim(_aTmpDados[1]))
			// retorno
			Return(.f.)
		EndIf

	Next _nItemAtu

	// Grava dados - Início
	Begin Transaction

		// procuro os dados
		dbSelectArea("Z32")
		Z32->(dbSetOrder(1))//1-Z32_FILIAL, Z32_CODPRO, Z32_ORDEM

		// varro o array fazendo as atualizacoes
		For _nItemAtu := 1 to _nLenArray

			// posiciona no item
			_lRet := (Z32->(dbSeek( xFilial("Z32") + SB1->B1_COD + mvArrBrowse[_nItemAtu][_nP_Ordem] ))) //1-Z32_FILIAL, Z32_CODPRO, Z32_ORDEM

			// caso tenha encontrado o produto, vai fazer as atualizações
			If (_lRet).And.( ! mvArrBrowse[_nItemAtu][_nP_Delete])
				// valido alterações na ordem
				If (Z32->Z32_ORDEM != mvArrBrowse[_nItemAtu][_nP_Ordem])

					// mensagem para log de alteração
					_cLogMsg := "Ordem de SKU do Produto " + ALLTRIM(SB1->B1_COD) + " alterada. "
					_cLogMsg += "Ordem Antiga: " + Z32->Z32_ORDEM + " -> Ordem Nova: " + mvArrBrowse[_nItemAtu][_nP_Ordem]

					// reclock
					Reclock("Z32",.F.)
					Z32->Z32_ORDEM := mvArrBrowse[_nItemAtu][_nP_Ordem]
					MsUnlock()

					// gravo o log de Alteração
					U_FtGeraLog(xFilial("Z32"),"Z32", Z32->Z32_FILIAL+Z32->Z32_CODPRO, _cLogMsg, "WMS", "")

				EndIf

				// valido alterações na desc
				If (Z32->Z32_DESC != mvArrBrowse[_nItemAtu][_nP_Descr])

					// mensagem para log de alteração
					_cLogMsg := "Descrição de SKU do Produto " + ALLTRIM(SB1->B1_COD) + " alterada. "
					_cLogMsg += "Descrição Antiga: " + ALLTRIM(Z32->Z32_DESC) + " -> Descrição Nova: " + ALLTRIM(mvArrBrowse[_nItemAtu][_nP_Descr])

					// reclock
					Reclock("Z32",.F.)
					Z32->Z32_DESC := mvArrBrowse[_nItemAtu][_nP_Descr]
					MsUnlock()

					// gravo o log de Alteração
					U_FtGeraLog(xFilial("Z32"),"Z32", Z32->Z32_FILIAL+Z32->Z32_CODPRO, _cLogMsg, "WMS", "")

				EndIf

				// valido alterações na quantidade
				If (Z32->Z32_QUANT != mvArrBrowse[_nItemAtu][_nP_Quant])

					// mensagem para log de alteração
					_cLogMsg := "Quantidade de SKU do Produto " + ALLTRIM(SB1->B1_COD) + " alterada. "
					_cLogMsg += "Quantidade Antiga: " + CVALTOCHAR(Z32->Z32_QUANT) + " -> Quantidade Nova: " + CVALTOCHAR(mvArrBrowse[_nItemAtu][_nP_Quant])

					// reclock
					Reclock("Z32",.F.)
					Z32->Z32_QUANT := mvArrBrowse[_nItemAtu][_nP_Quant]
					MsUnlock()

					// gravo o log de Alteração
					U_FtGeraLog(xFilial("Z32"),"Z32", Z32->Z32_FILIAL+Z32->Z32_CODPRO, _cLogMsg, "WMS", "")

				EndIf

				// valido alterações no código de barras
				If (Z32->Z32_CODBAR != mvArrBrowse[_nItemAtu][_nP_CodBar])

					// mensagem para log de alteração
					_cLogMsg := "Cod.Barras de SKU do Produto " + ALLTRIM(SB1->B1_COD) + " alterada. "
					_cLogMsg += "Cod.Barras Antigo: " + ALLTRIM(Z32->Z32_CODBAR) + " -> Cod.Barras Novo: " + ALLTRIM(mvArrBrowse[_nItemAtu][_nP_CodBar])

					// reclock
					Reclock("Z32",.F.)
					Z32->Z32_CODBAR := mvArrBrowse[_nItemAtu][_nP_CodBar]
					MsUnlock()

					// gravo o log de Alteração
					U_FtGeraLog(xFilial("Z32"),"Z32", Z32->Z32_FILIAL+Z32->Z32_CODPRO, _cLogMsg, "WMS", "")

				EndIf

				// valido alterações do tipo
				If (Z32->Z32_TIPO != mvArrBrowse[_nItemAtu][_nP_Tipo])

					// mensagem para log de alteração
					_cLogMsg := "Tipo de SKU do Produto " + ALLTRIM(SB1->B1_COD) + " alterada. "
					_cLogMsg += "Tipo Antigo: " + ALLTRIM(Z32->Z32_TIPO) + " -> Tipo Novo: " + ALLTRIM(mvArrBrowse[_nItemAtu][_nP_Tipo])

					// reclock
					Reclock("Z32",.F.)
					Z32->Z32_TIPO := mvArrBrowse[_nItemAtu][_nP_Tipo]
					MsUnlock()

					// gravo o log de Alteração
					U_FtGeraLog(xFilial("Z32"),"Z32", Z32->Z32_FILIAL+Z32->Z32_CODPRO, _cLogMsg, "WMS", "")

				EndIf

				// finalizo a transação
				MsUnlock()

				// caso não encontrou os registros, inclui na tabela
			ElseIf ( ! _lRet).And.( ! mvArrBrowse[_nItemAtu][_nP_Delete])
				// insere os registros
				Reclock("Z32",.T.)
				Z32->Z32_FILIAL := xFilial("Z32")
				Z32->Z32_CODPRO := SB1->B1_COD
				Z32->Z32_ORDEM  := mvArrBrowse[_nItemAtu][_nP_Ordem  ]
				Z32->Z32_TIPO   := mvArrBrowse[_nItemAtu][_nP_Tipo   ]
				Z32->Z32_DESC   := mvArrBrowse[_nItemAtu][_nP_Descr  ]
				Z32->Z32_QUANT  := mvArrBrowse[_nItemAtu][_nP_Quant  ]
				Z32->Z32_ZTPBAR := mvArrBrowse[_nItemAtu][_nP_TpCdBar]
				Z32->Z32_CODBAR := mvArrBrowse[_nItemAtu][_nP_CodBar ]
				MsUnlock()

			ElseIf (_lRet).And.(mvArrBrowse[_nItemAtu][_nP_Delete])
				// mensagem para log de alteração
				_cLogMsg := "SKU do Produto " + ALLTRIM(SB1->B1_COD) + " deletado. Ref: Quantidade " + CVALTOCHAR(Z32->Z32_QUANT) + " e Descrição: " + ALLTRIM(Z32->Z32_DESC)
				// caso a linha esteja deletada, deleta o item
				RecLock("Z32",.F.)
				Z32->(dbDelete())
				Z32->(MsUnLock())
				// gravo o log de Alteração
				U_FtGeraLog(xFilial("Z32"),"Z32", Z32->Z32_FILIAL+Z32->Z32_CODPRO, _cLogMsg, "WMS", "")
			EndIf

		Next _nItemAtu

		// valido as alterações e arrumo a ordem
		_cQryOrd := " SELECT R_E_C_N_O_, Z32_QUANT FROM " + RetSqlTab("Z32")
		_cQryOrd += " WHERE " + RetSqlCond("Z32")
		_cQryOrd += " AND Z32_CODPRO = '" + SB1->B1_COD + "'
		_cQryOrd += " ORDER BY Z32_QUANT DESC "

		// resultado da query para um array
		_aUpdOrd := U_SqlToVet(_cQryOrd)

		// varro todos os registros para corrigir a ordem
		For _nX := 1 to Len(_aUpdOrd)

			// posiciona no RECNO
			dbSelectArea("Z32")
			Z32->(dbGoTo(_aUpdOrd[_nX][1]))

			// atualiza a ordem
			Reclock("Z32",.F.)
			Z32->Z32_ORDEM := StrZero(_nNewSeq,Len(Z32->Z32_ORDEM))
			MsUnlock()

			// incrementa a régua
			_nNewSeq++
		Next _nX

		// finaliza transacao
	End Transaction

Return (.T.)

// ** funcao para verificar se existe aquele produto
User Function WMSC007B(mvBrowse, mvTpVal)

	// controle de transação
	local _lRet := .T.
	// controle do for
	local _nX   := 0

	// posicao dos campos
	local _nP_Ordem   := aScan(_aHeadSku,{|x| AllTrim(Upper(x[2]))=="Z32_ORDEM" }) // ordem
	local _nP_Tipo    := aScan(_aHeadSku,{|x| AllTrim(Upper(x[2]))=="Z32_TIPO"  }) // tipo
	local _nP_Descr   := aScan(_aHeadSku,{|x| AllTrim(Upper(x[2]))=="Z32_DESC"  }) // descricao
	local _nP_Quant   := aScan(_aHeadSku,{|x| AllTrim(Upper(x[2]))=="Z32_QUANT" }) // quantidade
	local _nP_TpCdBar := aScan(_aHeadSku,{|x| AllTrim(Upper(x[2]))=="Z32_ZTPBAR"}) // tipo codigo de barras
	local _nP_CodBar  := aScan(_aHeadSku,{|x| AllTrim(Upper(x[2]))=="Z32_CODBAR"}) // codigo de barras
	local _nP_Delete  := Len(_aHeadSku)+1                                          // deletados

	// query
	local _cQuery

	// dados do cadastro
	local _aTmpDados

	// validação por linha
	If (mvTpVal == "LINHAOK")
		If (Empty(mvBrowse:aCols[mvBrowse:nAt][_nP_Ordem]))   ; // ordem
		.Or.(Empty(mvBrowse:aCols[mvBrowse:nAt][_nP_Tipo]))   ; // tipo
		.Or.(Empty(mvBrowse:aCols[mvBrowse:nAt][_nP_Descr]))  ; // descrição
		.Or.(Empty(mvBrowse:aCols[mvBrowse:nAt][_nP_Quant]))  ; // quantidade
		.Or.(Empty(mvBrowse:aCols[mvBrowse:nAt][_nP_TpCdBar])); // tipo código de barras
		.Or.(Empty(mvBrowse:aCols[mvBrowse:nAt][_nP_CodBar] ))  // código de barras
			MsgStop("Todos os campos precisam estar preenchidos!")
			// variavel de retorno
			_lRet := .f.
		EndIf
	Else
		If (mvTpVal == "ORDEM")
			// valido se o registro já está inserido no array para não duplicar
			M->Z32_ORDEM := StrZero(VAL(M->Z32_ORDEM),Len(Z32->Z32_ORDEM)) // mascara
			// varre todos os itens do browse
			For _nX := 1 to len(mvBrowse:aCols)
				// se o array já contem o número do código informado, ele mostra erro pro usuário
				If (mvBrowse:aCols[_nX][_nP_Ordem] == M->Z32_ORDEM).And.( ! mvBrowse:aCols[_nX][_nP_Delete])
					// mensagem
					MsgStop("A ORDEM não pode ser igual para dois SKU diferentes!")
					// variavel de retorno
					_lRet := .f.
					// sai do loop
					EXIT
				EndIf
			Next _nX

		ElseIf (mvTpVal == "QUANT")
			// validação da quantidade
			If (M->Z32_QUANT <= 0)
				// mensagem
				MsgStop("A QUANTIDADE não pode ser 0!")
				// variavel de retorno
				_lRet := .f.
			Else
				// valido se o registro já está inserido no array para não duplicar
				For _nX := 1 to len(mvBrowse:aCols)
					// se o array já contem aquela quantidade
					If (mvBrowse:aCols[_nX][_nP_Quant] == M->Z32_QUANT).And.( ! mvBrowse:aCols[_nX][_nP_Delete] )
						// mensagem
						MsgStop("Já existe um SKU com essa quantidade. Verifique!")
						// variavel de retorno
						_lRet := .f.
						// sai do loop
						EXIT
					EndIf
				Next _nX
			EndIF
		ElseIf (mvTpVal == "DESC")
			// validação da quantidade
			If (Empty(M->Z32_DESC))
				// mensagem
				MsgStop("A DESCRIÇÃO precisa ser preenchida!")
				// variavel de retorno
				_lRet := .f.
			EndIF
		ElseIf (mvTpVal == "CODBAR")
			// validação do cod de barras do produto
			If (Empty(M->Z32_CODBAR))
				// mensagem
				MsgStop("O COD.BARRAS precisa ser preenchida!")
				// variavel de retorno
				_lRet := .f.
			Else
				// prepara query para validacao do codigo de barras - cad produto
				_cQuery := " SELECT B1_COD "
				_cQuery += " FROM   " + RetSqlTab("SB1")
				_cQuery += " WHERE  " + RetSqlCond("SB1")
				_cQuery += "        AND B1_GRUPO = '" + SB1->B1_GRUPO + "' "
				_cQuery += "        AND B1_CODBAR = '" + M->Z32_CODBAR + "' "

				// executa query
				_aTmpDados := U_SqlToVet(_cQuery)

				// valida se tem produto duplicado
				If (Len(_aTmpDados) != 0)
					// mensagem
					MsgStop("Código de Barras (Ean/Code128) já está em uso por outro produto/item!" + CRLF + "Produto (Cadastro): " + AllTrim(_aTmpDados[1]))
					// variavel de retorno
					_lRet := .f.
				EndIf

				// prepara query para validacao do codigo de barras
				_cQuery := " SELECT Z32_CODPRO "
				_cQuery += " FROM   " + RetSqlTab("Z32")
				_cQuery += " WHERE  " + RetSqlCond("Z32")
				_cQuery += "        AND SUBSTRING(Z32_CODPRO,1,4) = '" + SB1->B1_GRUPO + "' "
				_cQuery += "        AND Z32_CODPRO != '" + SB1->B1_COD + "' "
				_cQuery += "        AND Z32_CODBAR = '" + M->Z32_CODBAR + "' "

				// executa query
				_aTmpDados := U_SqlToVet(_cQuery)

				// valida se tem produto duplicado
				If (Len(_aTmpDados) != 0)
					// mensagem
					MsgStop("Código de Barras (Ean/Code128) já está em uso por outro produto/item!" + CRLF + "Produto (Sku): " + AllTrim(_aTmpDados[1]))
					// variavel de retorno
					_lRet := .f.
				EndIf

			EndIF
		ElseIf (mvTpVal == "TIPO")
			//			// valido se o registro já está inserido no array para não duplicar
			//			For _nX := 1 to len(mvBrowse:aCols)
			//				// se o array já contem aquele tipo
			//				If (mvBrowse:aCols[_nX][_nP_Tipo] == M->Z32_TIPO).And.( ! mvBrowse:aCols[_nX][_nP_Delete] )
			//					// mensagem
			//					MsgStop("Já existe um SKU com esse tipo. Verifique!")
			//					// variavel de retorno
			//					_lRet := .f.
			//					// sai do loop
			//					EXIT
			//				EndIf
			//			Next _nX
		ElseIf (mvTpVal == "TPCODBAR")
			// sem validacao especifica
		EndIf
	EndIf
Return(_lRet)