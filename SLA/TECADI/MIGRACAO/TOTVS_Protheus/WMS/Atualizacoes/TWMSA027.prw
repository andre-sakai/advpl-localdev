#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSA027                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Alteração tipo de Estoque do Produto.                   !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe Jose Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 05/2015                                                !
+------------------+--------------------------------------------------------*/

User Function TWMSA027()

	// dimensoes da tela
	Local _aSizeWnd := MsAdvSize()
	
	// grupo de perguntas
	local _cPerg := PadR("TWMSA027",10)
	
	//Variavel de controle
	Local _nLin  := 0
	Local _nx    := 0
	
	//Variaveis SQL
	Private _aRetSQL := {}
	Private _cQuery  := ""

	// funcao que monta os dados do operador logado no sistema
	Private _aUsrInfo := U_FtWmsOpe()

	// codigo do Operador
	Private _lUsrAccou  := (_aUsrInfo[2]=="A")
	Private _lUsrColet	:= (_aUsrInfo[2]=="C")
	Private _lUsrSuper	:= (_aUsrInfo[2]=="S")
	Private _lUsrGeren  := (_aUsrInfo[2]=="G")
	Private _lUsrMonit  := (_aUsrInfo[2]=="M")

	// arrays do browse
	private _aHeadEsq := {}, _aHeadDir := {}
	private _aColsEsq := {}, _aColsDir := {}

	//Variaveis para posição dos campos na Grid
	private _nPosEND := 0
	private _nPosPAL := 0
	private _nPosPRO := 0
	private _nPosSAL := 0
	private _nPosTPE := 0
	private _nPosSER := 0

	//Objetos
	Private _oDlgEnd,_oPnlRight,_oPnlLeft,_oPnlBottom,_oBrwEsq,_oBrwDir,_oBtReserv,_oBtSair
	
	// validacao do perfil de usuario para acesso a rotina
	If (! (_lUsrSuper)) .And. (! (_lUsrGeren)) .And. (! (_lUsrAccou))
		MsgStop("Apenas Account, Supervisor ou Gerente pode utilizar esta Rotina" , "Usuário sem permissão")
		Return
	EndIf

	// chama a tela de parametros
	If ! Pergunte(_cPerg,.T.)
		Return
	EndIf

	If Empty(mv_par01) .Or.  Empty(mv_par02) .Or. Empty(mv_par15)
		MsgStop("Rotina contém parâmetros obrigatórios não preenchidos, favor Revisar." , "Parâmetros não preenchidos")
		Return
	EndIf

	//Montando SQL para Colunas dinamicas conforme tipo de estoques na tabela Z16.
	_cQuery := " SELECT Z16_ENDATU,Z16_ETQPAL,Z16_ETQVOL,Z16_CODPRO,Z16_SALDO,Z16_ETQPRD,Z16_TPESTO,Z16_NUMSER,Z16.R_E_C_N_O_"
	// Tipo de estoque
	_cQuery += " FROM "+RetSqlName("Z16")+" Z16 (nolock) "
	// Produtos
	_cQuery += " INNER JOIN "+RetSqlName("SB1")+" SB1 (nolock) ON "+RetSqlCond("SB1")+" AND Z16.Z16_CODPRO = SB1.B1_COD  "
	// codigo do produto
	_cQuery += " AND B1_COD   BETWEEN '" + mv_par10 + "' AND '" + mv_par11 + "'"
	// Clientes
	_cQuery += " INNER JOIN "+RetSqlName("SA1")+" SA1 (nolock) ON "+RetSqlCond("SA1")+" AND SB1.B1_GRUPO = SA1.A1_SIGLA "
	// por Código Cliente
	_cQuery += " AND A1_COD  = '" + mv_par01 + "'"
	// por Loja Cliente
	_cQuery += " AND A1_LOJA = '" + mv_par02 + "'"
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond('Z16')+" "
	// Filtro Rua
	_cQuery += " AND SUBSTRING(Z16_ENDATU, 1, 2) BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' "
	// Filtro Lado
	If (mv_par05 == 2)
		_cQuery += " AND SUBSTRING(Z16_ENDATU, 3, 1) = 'A'  "
	ElseIf (mv_par05 == 3)
		_cQuery += " AND SUBSTRING(Z16_ENDATU, 3, 1) = 'B'  "
	EndIf
	// Filtro Predio
	_cQuery += " AND SUBSTRING(Z16_ENDATU, 4, 2) BETWEEN '"+mv_par06+"' AND '"+mv_par07+"' "
	// Filtro Andar
	_cQuery += " AND SUBSTRING(Z16_ENDATU, 6, 2) BETWEEN '"+mv_par08+"' AND '"+mv_par09+"' "
	// filtro de endereço completo
	_cQuery += " AND Z16_ENDATU BETWEEN '"+mv_par12+"' AND '"+mv_par13+"' "
	// filtro de etiqueta
	If ( ! Empty(mv_par14) )
		_cQuery += " AND Z16_ETQPRD = '"+mv_par14+"' "
	EndIf
	// somente com saldo
	_cQuery += " AND Z16_SALDO > 0 "

	// somente exibe registro com tipo de estoque diferente de 000023-Conferencia sem NF
	_cQuery += " AND Z16_TPESTO != '000023' "

	// verifica se deve filtrar por nota fiscal
	If ( ! Empty(mv_par16) )
		_cQuery += "        AND Z16_NUMSEQ IN (SELECT B6_IDENT "
		_cQuery += "                           FROM   "+RetSqlTab("SB6")+" (nolock) "
		_cQuery += "                           WHERE  "+RetSqlCond("SB6")
		_cQuery += "                                  AND B6_CLIFOR = A1_COD "
		_cQuery += "                                  AND B6_LOJA = A1_LOJA "
		_cQuery += "                                  AND B6_DOC = '"+mv_par16+"' "
		_cQuery += "                                  AND B6_SALDO > 0 "
		_cQuery += "                                  AND B6_PODER3 = 'R') "
	EndIf

	// ordenação
	_cQuery += " ORDER BY Z16_ENDATU "

	// Gravamos o log para posterior auditoria
	memowrit("c:\query\twmsa027_troca_tpestoque.txt",_cQuery)

	// carrega resultado do SQL na variavel.
	_aRetSQL := U_SqlToVet(_cQuery)

	// monta a tela
	_oDlgEnd := MSDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"Alterar tipo de estoque",,,.F.,,,,,,.T.,,,.T. )
	_oDlgEnd:lMaximized := .T.

	// cria o panel da esquerda com as opções para abastecimento
	_oPnlLeft := TPanel():New(000,000,nil,_oDlgEnd,,.F.,.F.,,,(_aSizeWnd[5]/4),(_aSizeWnd[5]/4),.T.,.F. )
	_oPnlLeft:Align := CONTROL_ALIGN_LEFT

	// cria o panel da direita com as opções para abastecimento já escolhidas
	_oPnlRight := TPanel():New(_aSizeWnd[7],000,nil,_oDlgEnd,,.F.,.F.,,,(_aSizeWnd[5]/4),(_aSizeWnd[5]/4),.T.,.F. )
	_oPnlRight:Align := CONTROL_ALIGN_RIGHT

	// cria o panel da direita com as opções para abastecimento já escolhidas
	_oPnlBottom := TPanel():New(000,000,nil,_oDlgEnd,,.F.,.F.,,,000,030,.T.,.F. )
	_oPnlBottom:Align := CONTROL_ALIGN_BOTTOM

	Aadd(_aHeadEsq,{'    ','ZE0_AMARK','@BMP',10,0,,,'C',,'V',,,'mark','V','S'})
	Aadd(_aHeadDir,{'    ','ZE0_AMARK','@BMP',10,0,,,'C',,'V',,,'mark','V','S'})

	Aadd(_aHeadEsq,{"End. Atual","Z16_ENDATU","@!",15,0,"","","C","",""})
	Aadd(_aHeadDir,{"End. Atual","Z16_ENDATU","@!",15,0,"","","C","",""})

	Aadd(_aHeadEsq,{"Etiq Palete","Z16_ETQPAL","@R **********",10,0,"","","C","",""})
	Aadd(_aHeadDir,{"Etiq Palete","Z16_ETQPAL","@R **********",10,0,"","","C","",""})

	Aadd(_aHeadEsq,{"Cod Produto","Z16_CODPRO","@!",30,0,"","","C","",""})
	Aadd(_aHeadDir,{"Cod Produto","Z16_CODPRO","@!",30,0,"","","C","",""})

	Aadd(_aHeadEsq,{"Quantidade","Z16_SALDO","@E 999,999.9999",11,4,"","","N","",""})
	Aadd(_aHeadDir,{"Quantidade","Z16_SALDO","@E 999,999.9999",11,4,"","","N","",""})

	Aadd(_aHeadEsq,{"Tp. Estoque","Z16_TPESTO","@!",6,0,"","","C","",""})
	Aadd(_aHeadDir,{"Tp. Estoque","Z16_TPESTO","@!",6,0,"","","C","",""})

	Aadd(_aHeadEsq,{"Num.Serie","Z16_NUMSER",PesqPict("Z16", "Z16_NUMSER"),10,0,"","","C","",""})
	Aadd(_aHeadDir,{"Num.Serie","Z16_NUMSER",PesqPict("Z16", "Z16_NUMSER"),10,0,"","","C","",""})

	//Verifica posição dos campos na Grid
	_nPosMARK := GDFIELDPOS("ZE0_AMARK"   , _aHeadEsq )
	_nPosEND  := GDFIELDPOS("Z16_ENDATU"  , _aHeadEsq )
	_nPosPAL  := GDFIELDPOS("Z16_ETQPAL"  , _aHeadEsq )
	_nPosPRO  := GDFIELDPOS("Z16_CODPRO"  , _aHeadEsq )
	_nPosSAL  := GDFIELDPOS("Z16_SALDO"   , _aHeadEsq )
	_nPosTPE  := GDFIELDPOS("Z16_TPESTO"  , _aHeadEsq )
	_nPosSER  := GDFIELDPOS("Z16_NUMSER"  , _aHeadEsq )

	For _nx := 1 To Len(_aRetSQL)
		// incremento da linha de controle
		_nLin++
		// cria nova linha no vetor
		Aadd(_aColsEsq,Array(Len(_aHeadEsq)+1))
		Aadd(_aColsDir,Array(Len(_aHeadDir)+1))

		_aColsEsq[_nLin][_nPosMARK] :='LBNO'
		_aColsEsq[_nLin][_nPosEND]         := _aRetSQL[_nx][1]
		_aColsEsq[_nLin][_nPosPAL]         := _aRetSQL[_nx][2]
		_aColsEsq[_nLin][_nPosPRO]         := _aRetSQL[_nx][4]
		_aColsEsq[_nLin][_nPosSAL]         := _aRetSQL[_nx][5]
		_aColsEsq[_nLin][_nPosTPE]         := _aRetSQL[_nx][7]
		_aColsEsq[_nLin][_nPosSER]         := _aRetSQL[_nx][8]
		_aColsEsq[_nLin][Len(_aHeadEsq)+1] := .F.

		_aColsDir[_nLin][_nPosMARK] :='LBNO'
		_aColsDir[_nLin][_nPosEND]         := _aRetSQL[_nx][1]
		_aColsDir[_nLin][_nPosPAL]         := _aRetSQL[_nx][2]
		_aColsDir[_nLin][_nPosPRO]         := _aRetSQL[_nx][4]
		_aColsDir[_nLin][_nPosSAL]         := _aRetSQL[_nx][5]
		_aColsDir[_nLin][_nPosTPE]         := mv_par15
		_aColsDir[_nLin][_nPosSER]         := _aRetSQL[_nx][8]
		_aColsDir[_nLin][Len(_aHeadDir)+1] := .F.

	Next _nx
	// browse com os detalhes dos endereços a abastercer
	_oBrwEsq := MsNewGetDados():New(000,000,999,999,Nil,'AllwaysTrue()','AllwaysTrue()','',,,,'AllwaysTrue()','','AllwaysTrue()',_oPnlLeft,_aHeadEsq,_aColsEsq)
	_oBrwEsq:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwEsq:oBrowse:bLDblClick := {|| InvMark(1)}

	// browse com os detalhes dos endereços a abastercer
	_oBrwDir := MsNewGetDados():New(000,000,999,999,Nil,'AllwaysTrue()','AllwaysTrue()','',,,,'AllwaysTrue()','','AllwaysTrue()',_oPnlRight,_aHeadDir,_aColsDir)
	_oBrwDir:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwDir:oBrowse:bLDblClick := {|| InvMark(2)}

	// botão que irá reservar os endereços
	_oBtReserv := TButton():New( 010, 010, "Confirmar Alteração",_oPnlBottom,{|| sfAlttpest(),_oDlgEnd:END() }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// botão que irá marcar todas as linhas
	_oBtMarca := TButton():New( 010, 100, "Marca Todos",_oPnlBottom,{|| InvMark(3,"M") }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// botão que irá Desmarcar todas as linhas
	_oBtDesma := TButton():New( 010, 190, "Desmarcar Todos",_oPnlBottom,{|| InvMark(3,"D") }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// botão que irá sair da rotina
	_oBtSair := TButton():New( 010, 280,"Cancelar",_oPnlBottom,{|| IIF(MsgYesNo("Desejar Sair?"), _oDlgEnd:END(), Nil) }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// ativacao da tela
	_oDlgEnd:Activate(,,,.T.,)

Return

Static Function InvMark(mvTip,mvMarDes)

	Local   _yi       := 1
	Local  _cMarca    := ""
	Default mvTip     := 1
	Default mvMarDes  := ""

	If Empty(mvMarDes)
		If mvTip = 1
			_oBrwDir:aCOLS[_oBrwEsq:nAt,_nPosMARK] := Iif(_oBrwDir:aCOLS[_oBrwEsq:nAt,_nPosMARK]=='LBOK','LBNO','LBOK')
			_oBrwEsq:aCOLS[_oBrwEsq:nAt,_nPosMARK] := Iif(_oBrwEsq:aCOLS[_oBrwEsq:nAt,_nPosMARK]=='LBOK','LBNO','LBOK')
			_cPalet := _oBrwEsq:aCOLS[_oBrwEsq:nAt,_nPosPAL]
			_cMarca := _oBrwDir:aCOLS[_oBrwEsq:nAt,_nPosMARK]
		Else
			_oBrwDir:aCOLS[_oBrwDir:nAt,_nPosMARK] := Iif(_oBrwDir:aCOLS[_oBrwDir:nAt,_nPosMARK]=='LBOK','LBNO','LBOK')
			_oBrwEsq:aCOLS[_oBrwDir:nAt,_nPosMARK] := Iif(_oBrwEsq:aCOLS[_oBrwDir:nAt,_nPosMARK]=='LBOK','LBNO','LBOK')
			_cPalet := _oBrwDir:aCOLS[_oBrwDir:nAt,_nPosPAL]
			_cMarca := _oBrwDir:aCOLS[_oBrwDir:nAt,_nPosMARK]
		EndIf

		For _yi :=  1 To Len(_oBrwDir:aCOLS)

			If 	_cPalet	== _oBrwDir:aCOLS[ _yi , _nPosPAL ]
				_oBrwDir:aCOLS[_yi,_nPosMARK] := _cMarca
				_oBrwEsq:aCOLS[_yi,_nPosMARK] := _cMarca
			EndIf

		Next _yi

	ElseIf(mvMarDes == "M")
		For _yi :=  1 To Len(_oBrwDir:aCOLS)

			_oBrwDir:aCOLS[_yi,_nPosMARK] := 'LBOK'
			_oBrwEsq:aCOLS[_yi,_nPosMARK] := 'LBOK'

		Next _yi
	ElseIf(mvMarDes == "D")
		For _yi :=  1 To Len(_oBrwDir:aCOLS)

			_oBrwDir:aCOLS[_yi,_nPosMARK] := 'LBNO'
			_oBrwEsq:aCOLS[_yi,_nPosMARK] := 'LBNO'

		Next _yi
	EndIF
	_oBrwEsq:Refresh()
	_oBrwDir:Refresh()

Return()

//Atualiza valores na tabela Z16.
Static Function sfAlttpest()
	//Variaveis Temporarias
	Local _cInfoLog := ""
	Local _iy
	Local lSumibar := .F.

	If ( ! MsgYesNo("Confirma alteração do tipo de estoque?"))
		Return( .F. )
	EndIf

	// INICIA TRANSACAO
	BEGIN TRANSACTION

		//WMS - COMPOSICAO PALETE
		dbSelectArea("Z16")
		Z16->(dbsetorder(1))// 1-Z16_FILIAL, Z16_ETQPAL
		For _iy := 1 To Len(_aRetSQL)

			If _oBrwEsq:aCOLS[_iy,_nPosMARK]=='LBOK'

				Z16->(DbGoTo( _aRetSQL[_iy][9] ))

				// Cliente Sumitomo não permite alteração de estoque após 22/07/19 devido integração de sistemas GWS x Totvs. Alteração deve ser feita pela Sumitomo.
				// 23/09/2019 - Bruno Seára: SOMENTE PARA PRODUTOS QUE CONTROLAM BARCODE
				If ( Substr(Z16->Z16_CODPRO,1,4) == "SUMI" ) .AND. !(_lUsrGeren) .AND. (Posicione("SB1",1,xFilial("SB1") + Z16->Z16_CODPRO,"B1_ZNUMSER") == "S")
					DisarmTransaction()
					MsgStop("Um dos paletes envolvidos neste processo possui produtos Sumitomo que controla barcode. Neste caso, a alteração de estoque só é permitida pela própria Sumitomo através de integração de sistemas." + CRLF + CRLF + "Operação abortada.", "Sumitomo - Controle por barcode.")
					Return ( .F. )
				EndIf
				_cInfoLog := "Alteração Tipo de Estoque de " + Z16->Z16_TPESTO + " Para " + mv_par15

				RecLock("Z16", .F.)
				Z16->Z16_TPESTO := _oBrwDir:Acols[_iy][_nPosTPE]
				Z16->(MsUnLock())

				//Gera Log da Alteração
				U_FtGeraLog(cfilAnt,"Z16",xFilial("Z16") + Z16->Z16_ETQPAL + Z16->Z16_ETQPRD + Z16->Z16_ETQVOL + Z16->Z16_CODPRO,_cInfoLog,"","")

			EndIf

		Next _iy

		// FINALIZA TRANSACAO
	END TRANSACTION

	MsgInfo("Alteração Realizada", "TWMSA027" )

Return()