#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Funcoes Genericas utilizadas no modulo CTB              !
!                  ! 1. Retorna a natureza da nota de entrada                !
!                  ! 2. Retorna Conta Contábil conforme amarracoes contabeis !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 01/2012                                                 !
+------------------+--------------------------------------------------------*/

//-- 1. Retorna a natureza da nota de entrada
User Function FtRetNat
	local _cCodNat := CriaVar("ED_CODIGO",.f.)
	local _cQuery

	// monta a query para retornar a natureza
	_cQuery := "SELECT DISTINCT E2_NATUREZ "
	_cQuery += "FROM "+RetSqlName("SE2")+" SE2 "
	_cQuery += "WHERE "+RetSqlCond("SE2")+" "
	_cQuery += "AND E2_PREFIXO = '"+SF1->F1_PREFIXO+"' "
	_cQuery += "AND E2_NUM = '"+SF1->F1_DOC+"' "
	_cQuery += "AND E2_TIPO = 'NF' "
	_cQuery += "AND E2_FORNECE = '"+SF1->F1_FORNECE+"' AND E2_LOJA = '"+SF1->F1_LOJA+"' "
	// executa a query
	_cCodNat := U_FtQuery(_cQuery)

Return(_cCodNat)

//-- 2. Retorna Conta Contábil conforme amarracoes contabeis
User Function FtCtbConta(mvCentroCus, mvItContab, mvValida)

	// objetos da tela
	local _oWndOpcCtb, _oPnlCabec
	local _oBmpBtnOk
	local _oBrwOpcCtb

	// controle de confirmacao da tela
	local _lTelaOk := .f.

	// query
	local _cQuery
	// variaveis do browse
	local _aHeadBrw := {}
	// vetor com os dados
	local _aOpcoesCtb := {}

	// retorna o RECNO
	local _nRecnoCT1 := 0

	// variavel de retorno
	local _cRetConta := CriaVar("CT1_CONTA",.f.)

	// variavel de retorno, quando validacao
	local _lRetOk := .t.

	// parametros recebidos na funcao
	Default mvCentroCus := CriaVar("CTT_CUSTO",.f.)
	Default mvItContab  := CriaVar("CTD_ITEM",.f.)
	Default mvValida    := .f.

	// detalhes da conta contabil
	_cQuery := "SELECT CT1_CONTA, CT1_DESC01, CT1.R_E_C_N_O_ CT1RECNO, '.F.' IT_DEL " "
	// cad. de amarracoes contabeis
	_cQuery += "FROM "+RetSqlName("CTA")+" CTA "
	// cad. de contas contabeis
	_cQuery += "INNER JOIN "+RetSqlName("CT1")+" CT1 ON "+RetSqlCond("CT1")+" AND CT1_CONTA = CTA_CONTA "
	// filtro da amarracao
	_cQuery += "WHERE "+RetSqlCond("CTA")+" "
	_cQuery += "AND CTA_CUSTO = '"+mvCentroCus+"' "
	_cQuery += "AND CTA_ITEM  = '"+mvItContab+"' "
	// ordem dos dados
	_cQuery += "ORDER BY CT1_DESC01 "

	// alimenta array conforme resultado do select
	_aOpcoesCtb := U_SqlToVet(_cQuery)

	// se for rotina de validacao
	If (mvValida)
		// valida se ha amarracoes
		If (Len(_aOpcoesCtb) == 0)
			// mensagem
			Aviso("Tecadi: TCTBXFUN","Não há amarração contábil para o centro de custo "+AllTrim(mvCentroCus)+" e item contábil "+AllTrim(mvItContab),{"OK"})
			// variavel de retorno
			_lRetOk := .f.
		EndIf
		// retorno da funcao
		Return(_lRetOk)
	EndIf

	// caso não encontre amarracoes
	If (Len(_aOpcoesCtb) == 0)
		Aviso("Tecadi: TCTBXFUN","Não há amarração contábil para o centro de custo "+AllTrim(mvCentroCus)+" e item contábil "+AllTrim(mvItContab),{"OK"})

	ElseIf (Len(_aOpcoesCtb) == 1)
		// posiciona no registro da conta contabil
		dbSelectArea("CT1")
		CT1->(dbGoTo( _aOpcoesCtb[1][3] ))

		// atualiza variavel de retorno
		_cRetConta := CT1->CT1_CONTA

	ElseIf (Len(_aOpcoesCtb) > 1)
		// define todos os campos do header
		aAdd(_aHeadBrw,{"Código"    ,"CT1_CONTA"  ,"" ,TamSx3("CT1_CONTA")[1] ,0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadBrw,{"Descrição" ,"CT1_DESC01" ,"" ,TamSx3("CT1_DESC01")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadBrw,{"Recno"     ,"CT1RECNO"   ,"" ,10                     ,0,Nil,Nil,"N",Nil,"R",,,".F." })

		// monta o dialogo
		_oWndOpcCtb := MSDialog():New(000,000,400,660,"Opções de Contas Contábeis",,,.F.,,,,,,.T.,,,.T. )
		_oWndOpcCtb:lEscClose := .F.

		// cria o panel do cabecalho - botoes
		_oPnlCabec := TPanel():New(000,000,nil,_oWndOpcCtb,,.F.,.F.,,,022,022,.T.,.F. )
		_oPnlCabec:Align:= CONTROL_ALIGN_TOP

		// -- CONFIRMACAO
		_oBmpBtnOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lTelaOk := .t., _nRecnoCT1 := _oBrwOpcCtb:aCols[_oBrwOpcCtb:nAt][Len(_oBrwOpcCtb:aHeader)], _oWndOpcCtb:End() },_oPnlCabec,"Ok",,.T.)
		_oBmpBtnOk:Align := CONTROL_ALIGN_LEFT

		// monta o browse com as opcoes de contas contabeis conforme amarracao
		_oBrwOpcCtb := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aOpcoesCtb),'AllwaysTrue()','','AllwaysTrue()',_oWndOpcCtb,_aHeadBrw,_aOpcoesCtb)
		_oBrwOpcCtb:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// ativa o dialogo
		_oWndOpcCtb:Activate(,,,.T.,{|| _lTelaOk },,)

		// posiciona no registro da conta contabil
		dbSelectArea("CT1")
		CT1->(dbGoTo( _nRecnoCT1 ))

		// atualiza variavel de retorno
		_cRetConta := CT1->CT1_CONTA

	EndIf

Return(_cRetConta)