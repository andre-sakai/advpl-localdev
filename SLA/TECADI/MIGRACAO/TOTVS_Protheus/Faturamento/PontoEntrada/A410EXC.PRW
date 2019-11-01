#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+                                                                              
!Descricao         ! Ponto de Entrada que valida a Exclusao do Pedido de     !
!                  ! Venda                                                   !
+------------------+---------------------------------------------------------+
!Uso               ! 1. Utilizado para validar se o pedido de venda possui   !
!                  !    outros pedidos mais recentes dentro do mesmo processo!
+------------------+---------------------------------------------------------+
!Retorno           ! .T. = Permite a Exclusão / .F. = Não Permite a Exclusão !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 01/2012                                                 !
+------------------+--------------------------------------------------------*/

User Function A410EXC()
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSB1 := SB1->(GetArea())
	local _aAreaSC6 := SC6->(GetArea())
	// variavel de retorno
	local _lVldExcl := .t.
	// tipo do servico
	local _cTpServ := ""
	// seek do SC6
	local _cSeekSC6
	// validação do WMS ativo
	local _lWmsAtivo := .f.
	
	// somente pedido normal e do tipo SERVICO
	If (SC5->C5_TIPO=="N").and.(SC5->C5_TIPOOPE=="S")
		// varre todos o itens do pedido de venda
		dbSelectArea("SC6")
		SC6->(dbSetOrder(1)) //1-C6_FILIAL, C6_NUM, C6_ITEM, C6_PRODUTO
		SC6->(dbSeek( _cSeekSC6 := xFilial("SC6")+SC5->C5_NUM ))
		
		While SC6->(!Eof()).and.(SC6->(C6_FILIAL+C6_NUM)==_cSeekSC6)

			// retorna o tipo do servico
			_cTpServ := Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_TIPOSRV")
	
			// ** 1-ARMAZENAGEM DE CONTAINER
			If (_lVldExcl).and.(_cTpServ == "1")
				// rotina que valida se eh permitido a exclusao do pedido
				If ! (_lVldExcl := sfRetPedRec("SZG","ZG",.f.))
					Aviso(	"A410EXC - Arm Containers",;
							"Não é permitido a exclusão deste pedido pois há pedidos mais recentes emitidos neste processo com o mesmo tipo de serviço.",;
							{"Fechar"})			
				EndIf	

			// ** 2-ARMAZENAGEM DE PRODUTOS
			ElseIf (_lVldExcl).and.(_cTpServ == "2")
				// rotina que valida se eh permitido a exclusao do pedido
				If ! (_lVldExcl := sfRetPedRec("SZH","ZH",.t.))
					Aviso(	"A410EXC - Arm Produtos",;
							"Não é permitido a exclusão deste pedido pois há pedidos mais recentes emitidos neste processo com o mesmo tipo de serviço.",;
							{"Fechar"})			
				EndIf
/*
			// ** 3-PACOTE LOGISTICO
			ElseIf (_lVldExcl).and.(_cTpServ == "3")
				// rotina que valida se eh permitido a exclusao do pedido
				If ! (_lVldExcl := sfRetPedRec("SZJ","ZJ",.f.))
					Aviso(	"A410EXC - Pacote Logístico",;
							"Não é permitido a exclusão deste pedido pois há pedidos mais recentes emitidos neste processo com o mesmo tipo de serviço.",;
							{"Fechar"})			
				EndIf
*/
/*
			// ** 4-TRANSF INTERNA / FRETE
			ElseIf (_lVldExcl).and.(_cTpServ == "4")
				// rotina que valida se eh permitido a exclusao do pedido
				If ! (_lVldExcl := sfRetPedRec("SZK","ZK",.f.))
					Aviso(	"A410EXC - Fretes",;
							"Não é permitido a exclusão deste pedido pois há pedidos mais recentes emitidos neste processo com o mesmo tipo de serviço.",;
							{"Fechar"})			
				EndIf
*/
			// ** 5-SEGUROS
			ElseIf (_lVldExcl).and.(_cTpServ == "5")
				// rotina que valida se eh permitido a exclusao do pedido
				If ! (_lVldExcl := sfRetPedRec("SZI","ZI",.t.))
					Aviso(	"A410EXC - Seguros",;
							"Não é permitido a exclusão deste pedido pois há pedidos mais recentes emitidos neste processo com o mesmo tipo de serviço.",;
							{"Fechar"})			
				EndIf
/*
			// ** 7-SERVICOS DIVERSOS
			ElseIf (_lVldExcl).and.(_cTpServ == "7")
				// rotina que valida se eh permitido a exclusao do pedido
				If ! (_lVldExcl := sfRetPedRec("SZL","ZL",.f.))
					Aviso(	"A410EXC - Serviços Diversos",;
							"Não é permitido a exclusão deste pedido pois há pedidos mais recentes emitidos neste processo com o mesmo tipo de serviço.",;
							{"Fechar"})			
				EndIf
*/
			// ** 8-VALORES FIXOS / ALUGUEIS
			ElseIf (_lVldExcl).and.(_cTpServ == "8")
				// rotina que valida se eh permitido a exclusao do pedido
				If ! (_lVldExcl := sfRetPedRec("SZM","ZM",.f.))
					Aviso(	"A410EXC - Valores Fixos / Aluguéis",;
							"Não é permitido a exclusão deste pedido pois há pedidos mais recentes emitidos neste processo com o mesmo tipo de serviço.",;
							{"Fechar"})			
				EndIf

			EndIf

			// proximo item
			SC6->(dbSkip())
		EndDo
			
	EndIf
	
	// quando for saída de produtos
	If ( SC5->C5_TIPO == "N" ) .and. ( SC5->C5_TIPOOPE == "P" )
		
		// verifica se o WMS esta ativo
		_lWmsAtivo := StaticCall(TWMSXFUN, WmsMltCntr, "MATA410", "WMS_ATIVO_POR_CLIENTE", SC5->C5_CLIENTE, SC5->C5_LOJACLI)
		
		// se o WMS está ativo, vai validar se possui mapa
		If ( _lWmsAtivo )
			// valido se possui MAPA
			If ( U_FtMapExp(SC5->C5_NUM) )
				Aviso(	"A410EXC - Mapa de Apanhe",;
						"Não é permitido a exclusão deste pedido pois há Mapa de Apanhe gerado.",;
						{"Fechar"})
				// retorno da rotina	
				_lVldExcl := .f.
			EndIf 
		EndIf
	EndIf
	
	// restaura area inicial
	RestArea(_aAreaSC6)
	RestArea(_aAreaSB1)
	RestArea(_aAreaAtu)

Return(_lVldExcl)

// ** funcao que pesquisa item mais recentes
Static Function sfRetPedRec(mvAlias,mvPrefixo,mvDoc)
	local _lRet := .f.
	local _cQuery
	// numero e serie da nota
	local _cNota, _cSerie
	// data referencia
	local _dDtFim
	
	// 2-ARMAZENAGEM DE PRODUTOS
	If (mvDoc).and.(mvAlias $ "SZH")
		// armazenagem de produtos
		dbSelectArea("SZH")
		SZH->(dbOrderNickName("ZH_PEDIDO")) //4-ZH_FILIAL, ZH_PEDIDO, ZH_ITEMPED
		SZH->(dbSeek( xFilial("SZH")+SC5->C5_NUM+SC6->C6_ITEM ))
		// armazena o numero e serie da nota e a data
		_cNota  := SZH->ZH_DOC
		_cSerie := SZH->ZH_SERIE
		_dDtFim := SZH->ZH_DTFIM

	// 5-SEGUROS
	ElseIf (mvDoc).and.(mvAlias $ "SZI")
		// seguros
		dbSelectArea("SZI")
		SZI->(dbOrderNickName("ZI_PEDIDO")) //4-ZI_FILIAL, ZI_PEDIDO, ZI_ITEMPED
		SZI->(dbSeek( xFilial("SZI")+SC5->C5_NUM+SC6->C6_ITEM ))
		// armazena o numero e serie da nota e a data
		_cNota  := SZI->ZI_DOC
		_cSerie := SZI->ZI_SERIE
		_dDtFim := SZI->ZI_DTFIM
	EndIf

	// conta a quantidade de registros
	_cQuery := "SELECT COUNT(*) QTD_ITENS "
	// tabela
	_cQuery += "FROM "+RetSqlName(mvAlias)+" "+mvAlias+" "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond(mvAlias)+" "
	_cQuery += "AND "+mvPrefixo+"_STATUS IN ('C','F') "
	_cQuery += "AND "+mvPrefixo+"_IDPROCE = ' ' "
	_cQuery += "AND "+mvPrefixo+"_CONTRT = '"+SC6->C6_CONTRT+"'   AND "+mvPrefixo+"_ITCONTR = '"+SC6->C6_ITCONTR+"' "
	_cQuery += "AND "+mvPrefixo+"_PRODUTO = '"+SC6->C6_PRODUTO+"' "
	_cQuery += "AND "+mvPrefixo+"_CLIENTE = '"+SC6->C6_CLI+"'     AND "+mvPrefixo+"_LOJA   = '"+SC6->C6_LOJA+"' "
	// nao filtra processo para valores fixos
	If (mvAlias != "SZM")
		_cQuery += "AND "+mvPrefixo+"_PROCES  = '"+SC6->C6_ZPROCES+"' AND "+mvPrefixo+"_ITPROC = '"+SC6->C6_ZITPROC+"' "
	EndIf
	// verifica a necessidade de filtro por documento
	If (mvDoc)
		// documento e serie
		_cQuery += "AND "+mvPrefixo+"_DOC = '"+_cNota+"' AND "+mvPrefixo+"_SERIE = '"+_cSerie+"' "
		// filta a data
		_cQuery += "AND "+mvPrefixo+"_DTINI >= '"+DtoS(_dDtFim)+"' "
	EndIf
	// descarta o numero do pedido
	_cQuery += "AND "+mvPrefixo+"_PEDIDO > '"+SC6->C6_NUM+"' "

memowrit("c:\query\A410EXC_"+mvAlias+".txt",_cQuery)
	
	// executa a query
	_lRet := (U_FtQuery(_cQuery)==0)

Return(_lRet)