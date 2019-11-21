#Include "Protheus.ch"
#Include "Topconn.ch"
#Include "XmlxFun.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ AJXMLIMP º Autor ³ Gustavo H. Baptista º Data ³            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Rotina que gera pré-documento de entrada a partir do XML daº±±
±±º          ³ Nota Fiscal Eletronica, com lay-out padrao da Scretaria    º±±
±±º          ³ da Fazenda (SEFAZ).                                        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºAlterado ³ Peterson J. Savi	20/06/2016         						   ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function DPXMLIMP()

	**********************
	Local aRotAux := {}
	Local aSays			:= {}
	Local aButtons		:= {}
	Local nOpcAux		:= 0
	Local cDir1			:= ""
	Private aRotina     := {}
	Private cPerg 		:= "DPXMLI"
	Private cCadastro 	:= "Importa XML"
	Private cCondPag	:= ""
	Private aIPI		:= {}
	Private aPIPI		:= {}
	Private aICMS		:= {}
	Private aVCST		:= {}
	Private aBCST		:= {}
	Private aBASE		:= {}
	Private aPICMS		:= {}
	Private aICMSST     := {}
	Private aDescon     := {}
	Private aOutros     := {}
	Private aFrete      := {}
	Private aSeguro     := {}
	Private cNomeDps	:= ""
	Private cNomeArq	:= ""


	aAdd( aRotina, {"Pesquisar" ,"AxPesqui",0,1} )
	aAdd( aRotina, {"Visualizar","AxVisual",0,2} )
	aAdd( aRotina, {"Incluir"   ,'AxInclui',0,3} )
	aAdd( aRotina, {"Alterar"   ,"AxAltera",0,4} )
	aAdd( aRotina, {"Excluir"   ,"AxDeleta",0,5} )

	//Antes de chamar as perguntas eu verifico se existem as tabelas ZZ3 e ZZ4
	//Tambem verifico se ja existe o parametro do diretorio e ja crio

	//Incluindo parametro do caminho dos XMLs se ele não existir
	If !GetMV("MV_ZDIRXML",.T.)
		RecLock("SX6", .T.)
		SX6->X6_FIL     := xFilial( "SX6" )
		SX6->X6_VAR     := "MV_ZDIRXML"
		SX6->X6_TIPO    := "C"
		SX6->X6_DESCRIC := "Diretorio que armazenara os XMLs de entrada..."
		SX6->X6_CONTEUD := "C:\XML\"
		MsUnlock()         
	EndIf 
	
	//Incluindo parametro do produto CTE para o lançamento dos XMLs de CTE
	If !GetMV("MV_ZCTEXML",.T.)
		RecLock("SX6", .T.)
		SX6->X6_FIL     := xFilial( "SX6" )
		SX6->X6_VAR     := "MV_ZCTEXML"
		SX6->X6_TIPO    := "C"
		SX6->X6_DESCRIC := "Produto padrão de Frete de Vendas"
		SX6->X6_CONTEUD := "FRETE"
		MsUnlock()         
	EndIf 
	
	//Incluindo parametro do produto CTE para o lançamento dos XMLs de CTE
	If !GetMV("MV_ZTESXML",.T.)
		RecLock("SX6", .T.)
		SX6->X6_FIL     := xFilial( "SX6" )
		SX6->X6_VAR     := "MV_ZTESXML"
		SX6->X6_TIPO    := "C"
		SX6->X6_DESCRIC := "TES de entrada para lançamento automático de CTE de notas de venda"
		SX6->X6_CONTEUD := "001"
		MsUnlock()         
	EndIf 

	cDir1 :=  Alltrim(GetMV("MV_ZDIRXML"))

	//Verifico se existe a pasta temp e pasta processados. Caso não tenha eu crio as duas:
	If !ExistDir( Alltrim(cDir1) )
		MakeDir( Alltrim(cDir1) )
		If !ExistDir( Alltrim(cDir1)+"Processados")
			MakeDir( Alltrim(cDir1)+"Processados")
		EndIf
	EndIf

	//Agora verifico a tabela
	IF !ChkFile("ZZ3",.F.) .And. !ChkFile("ZZ4",.F.)

		//Crio tudo na mao
		U_FSAtuSX2()

		U_FSAtuSX3()

		U_FSAtuSIX()

	EndIf

	// Chama funcao para criacao do grupo de perguntas
	////////////////////////////////////////////////////////////////////////////////////////////
	AjustaSX1()

	// Chama a tela de perguntas
	////////////////////////////////////////////////////////////////////////////////////////////

	While Pergunte(cPerg,.T.)
		//If !Pergunte(cPerg,.T.)
		//	Return
		//EndIf                    

		aButtons		:= {}
		aSays			:= {}

		MV_PAR01 := Alltrim(MV_PAR01)
		cCondPag := MV_PAR02

		// Array auxiliar para a criacao da tela de Batch
		////////////////////////////////////////////////////////////////////////////////////////////
		aadd(aSays,"Esta rotina tem o objetivo de ler o arquivo XML informado nos parametros         ")
		aadd(aSays,"e montar uma tela auxiliar com informações extraidas deste arquivo para a        ")
		aadd(aSays,"geração da pré nota de entrada.                                                  ")

		// Array auxiliar de botoes para a criacao da tela de Batch
		////////////////////////////////////////////////////////////////////////////////////////////
		aadd(aButtons, { 1,.T.,{|| (FechaBatch(), nOpcAux := 1) }} )
		aadd(aButtons, { 2,.T.,{|| FechaBatch() }} )

		// Funcao que cria tela de Batch
		////////////////////////////////////////////////////////////////////////////////////////////
		FormBatch( cCadastro, aSays, aButtons )

		//Tamanho 80 do Substr porque o parametro tem tamanho 80
		If RAT('\',MV_PAR01) = 0
			If Len(Alltrim(mv_par01)) = 44 
				cNomeArq := Alltrim(Substr(MV_PAR01,1,44)) //Informo somente o código ou somente o nome do arquivo
			Else
				cNomeArq := Alltrim(Substr(MV_PAR01,1,44)) //Informo somente o código ou somente o nome do arquivo
				If RAT('.',cNomeArq) > 0
					cNomeArq := Alltrim(Substr(cNomeArq,1,RAT('.',cNomeArq)))
				EndIf
			EndIf
		Else
			cNomeArq := AllTrim(SubStr(MV_PAR01,RAT('\',MV_PAR01)+1,80)) //Seleciono o arquivo
			If RAT('.',cNomeArq) > 0
				cNomeArq := Alltrim(Substr(cNomeArq,1,RAT('.',cNomeArq)-1))
			EndIf
		EndIf

		If nOpcAux == 1
			// Funcao necessaria pra gerar objeto XML corretamente.
			///////////////////////////////////////////////////////////////////////////
			//SetVarNameLen(255)
			cNomeDps := U_DPXMLIM2(Alltrim(cNomeArq))
					
			dbselectarea("ZZ3")
			ZZ3->(DbGoTop())
			ZZ3->(dbsetorder(1))
			
			if ZZ3->(dbseek(xFilial("ZZ3")+ cNomeDps))

				If ZZ3->ZZ3_TIPO = "NFE"
					Processa( { || I300NFE() })
				ElseIf ZZ3->ZZ3_TIPO = "CTE"
					Processa( { || I300CTE() })
				EndIf
			else
				MsgAlert("Chave de arquivo não encontrado. ")
			EndIf
		EndIf

		//aRotina		:= aClone(aRotAux)

		//Pergunte("MTA140",.F.)
		Loop
	EndDo

Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ I300NFEºAutor  ³ Gustavo Baptista     º Data ³             º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Funcao que le o XML e monta a tela auxiliar com as         º±±
±±º          ³ informacoes extraidas do arquivo.                          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ IBM300                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function I300NFE()
	***************************
	Local cXml, cAviso, cErro, nHdlMod
	Local aGetAux		:= {}
	Local nUsado 		:= 0
	Local nOpcGet		:= 0
	Local cAlias1Temp	:= "IB300A"
	Local cDoc, cSerie, cCgcFor, dEmissao, _x, _c, cProdFor, cProduto, cPedQry, aTam, _oDlg, _y, cPedido, cItem
	Local nIndAxSA2		:= SA2->(IndexOrd())
	Local aSegSA2		:= SA2->(GetArea())
	Local nPosFil
	Local nPosDoc
	Local nPosCodF
	Local nPosDesF
	Local nPosProd
	Local nPosQtd
	Local nPosVal
	Local nPosTot
	Local nPosPed
	Local nPosProF
	Local nPosProXM
	Local nPosNCM
	Local nPosPedI

	Private cAlias2Temp	:= "IB300B"
	Private aPedidos		:= {}
	Private nOpc	 	:= 3
	Private aCols	 	:= {}
	Private aHeader		:= {}
	Private a140Cab		:= {}
	Private a140Item	:= {}
	Private	oIpi		:= Nil
	Private	oIcms		:= Nil
	Private cCgcFor

	dbselectarea("ZZ3")
	dbsetorder(1)
	if dbseek(xFilial("ZZ3")+Alltrim(cNomeDps))

		cCgcFor		:= ZZ3->ZZ3_CGC
		dEmissao	:= ZZ3->ZZ3_EMISS
		cDoc		:= ZZ3->ZZ3_DOC
		cSerie		:= ZZ3->ZZ3_SERIE
		cchNFe      := ZZ3->ZZ3_CHV
		nBCST		:= ZZ3->ZZ3_BCST
		nVCST		:= ZZ3->ZZ3_VCST
		cCgcDEST    := ZZ3->ZZ3_CGCDES
	ELSE
		Aviso("Rotina abortada","Nota ainda não processada.",{"Ok"})
		return
	ENDIF

	// RETIRADO VALIDACAO SOMENTE PARA TESTES PETERSON - LIBERAR FONTE DEPOIS DE EMPRESA CADASTRADA
	//if cCgcDEST <> RetField('SM0',1,cEmpAnt+cFilAnt,'M0_CGC')
	//	Aviso("Rotina abortada","CNPJ ("+cCgcDEST+") da nota não condiz com CNPJ da empresa atual ("+RetField('SM0',1,cEmpAnt+cFilAnt,'M0_CGC')+") . ",{"Ok"})
	//	return
	
	//endif

	// Busco o Fornecedor pelo CNPJ.
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	SA2->(dbSetOrder(3))
	If !SA2->(dbSeek(xFilial("SA2")+cCgcFor))
		Aviso("Rotina Abortada","Fornecedor nao encontrado. CNPJ: "+cCgcFor,{"Ok"})
		Return
	Else
		cCodFor		:= SA2->A2_COD
		cDescFor	:= SA2->A2_NOME
	EndIf

	// Verifico se a nota ja existe.
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	SF1->(dbSetOrder(1))
	If SF1->(dbSeek(xFilial("SF1")+cDoc+cSerie+SA2->A2_cod+SA2->A2_loja+"N"))
		Aviso("Rotina Abortada","Nota fiscal ja cadastrada!",{"Ok"})
		Return
	EndIf

	// Monto o array do cabecalho da pre-nota.
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	a140Cab		:= {	{	"F1_TIPO"		, "N"							, Nil},;
	{	"F1_FORMUL"		, "N"							, Nil},;
	{	"F1_DOC"		, cDoc							, Nil},;
	{	"F1_SERIE"		, cSerie 						, Nil},;
	{	"F1_EMISSAO"	, dEmissao						, Nil},;
	{	"F1_FORNECE"	, SA2->A2_cod			 		, Nil},;
	{	"F1_LOJA"	  	, SA2->A2_loja  				, Nil},;
	{	"F1_ESPECIE" 	, "SPED"  	  					, Nil},;
	{	"F1_BRICMS" 	, nBCST  	  					, Nil},;
	{	"F1_ICMSRET" 	, nVCST  	  					, Nil},;
	{	"F1_COND" 		, cCondPag	  					, Nil},;
	{	"F1_CHVNFE" 	, cchNFe 	  					, Nil}}

	// Monta o aHeader da tela auxiliar
	///////////////////////////////////////////////////
	aHeader	:= {}
	_Desc   := ""

	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("F1_DOC",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ "Numero NF", SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf

	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("A2_COD",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ "Fornecedor", SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("A2_NOME",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf

	SX3->(dbSetOrder(2))
	If SX3->(dbSeek("C1_PRODUTO"))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("C1_DESCRI",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("A5_CODPRF",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), "A5_CODPRF", SX3->X3_picture,SX3->X3_tamanho, SX3->x3_decimal,"","", SX3->X3_tipo, "",SX3->X3_context } )
	EndIf

	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("ZZ4_DESPRD",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), SX3->X3_campo, SX3->X3_picture,;
		50, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("D1_QUANT",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("D1_VUNIT",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("D1_TOTAL",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf

	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("B1_POSIPI",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), "B1_POSIPI" , SX3->X3_picture,SX3->X3_tamanho, SX3->x3_decimal,"","", SX3->X3_tipo, "",SX3->X3_context } )
	EndIf
	
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("D1_PEDIDO",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,"",;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf
	
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("D1_ITEMPC",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), "D1_ITEMPC", SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,"",;
		"", SX3->X3_tipo, "", SX3->X3_context } )
	EndIf

	// Inicializo o aCols
	///////////////////////////////////////////////////
	aCols	:= {}

	// Vou buscar os pedidos de compras em aberto informados nos parametros.
	////////////////////////////////////////////////////////////////////////////////////////////////
	If (Select(cAlias2Temp) <> 0)
		dbSelectArea(cAlias2Temp)
		dbCloseArea()
	EndIf

	cPedQry := ""
	If !Empty(MV_PAR03)
		If !Empty(cPedQry)
			cPedQry := "','"+MV_PAR03
		Else
			cPedQry := MV_PAR03
		EndIf
	EndIf

	If !Empty(cPedQry)
		BeginSql Alias cAlias2Temp
		select
		C7_NUM, C7_ITEM, C7_PRODUTO, (C7_QUANT - C7_QUJE) as C7_SALDO, C7_PRECO, C7_TOTAL
		from
		%table:SC7%
		where
		C7_FILIAL = %xFilial:SC7% and %NotDel%
		and (C7_QUANT - C7_QUJE) >= 0
		and C7_ENCER <> 'E' and C7_RESIDUO = ' '
		and C7_NUM IN (%exp:cPedQry%)
		order by
		C7_PRODUTO
		EndSql

		aTam := TamSX3("C7_QUANT")
		TcSetField(cAlias2Temp,"C7_SALDO"		,"N"	, aTam[1]	, aTam[2]	)
		aTam := TamSX3("C7_PRECO")
		TcSetField(cAlias2Temp,"C7_PRECO"		,"N"	, aTam[1]	, aTam[2]	)
		aTam := TamSX3("C7_TOTAL")
		TcSetField(cAlias2Temp,"C7_TOTAL"		,"N"	, aTam[1]	, aTam[2]	)

		While !(cAlias2Temp)->(Eof())
			aadd(aPedidos,{"A",(cAlias2Temp)->C7_num,(cAlias2Temp)->C7_item,(cAlias2Temp)->C7_produto,(cAlias2Temp)->C7_saldo,(cAlias2Temp)->C7_preco,(cAlias2Temp)->C7_total})
			(cAlias2Temp)->(dbSkip())
		EndDo
	EndIf

	// Busco os itens da pre-nota na tabela auxiliar'
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	dbselectarea("ZZ4")
	dbsetorder(1)
	IF dbseek(xFilial("ZZ4")+ZZ3->ZZ3_CHV)
		while(!EOF() .and. ZZ3->ZZ3_CHV == ZZ4->ZZ4_CHV )

			cProdFor	:= ZZ4->ZZ4_CODPRO
			nQtdItem	:= ZZ4->ZZ4_QTD
			nVUnit		:= ZZ4->ZZ4_VUNIT
			nTotItem	:= ZZ4->ZZ4_TOTAL
			cDescPrd	:= ZZ4->ZZ4_DESPRD
			cNCM		:= ZZ4->ZZ4_NCM

			AADD(aICMS  ,STR(ZZ4->ZZ4_ICMS))
			AADD(aIPI   ,STR(ZZ4->ZZ4_IPI))
			AADD(aPIPI  ,STR(ZZ4->ZZ4_PIPI))
			AADD(aVCST  ,STR(ZZ4->ZZ4_BCST))
			AADD(aBCST  ,STR(ZZ4->ZZ4_VCST))
			AADD(aBASE  ,STR(ZZ4->ZZ4_BICM))
			AADD(aPICMS ,STR(ZZ4->ZZ4_PICM))
			AADD(aICMSST,STR(ZZ4->ZZ4_PICMST))
			AADD(aDescon,STR(ZZ4->ZZ4_DESC))
			AADD(aOutros,STR(ZZ4->ZZ4_OUTROS))
			AADD(aFrete	,STR(ZZ4->ZZ4_VALFRE))
			AADD(aSeguro,STR(ZZ4->ZZ4_VALSEG))
			cProduto	:=	Posicione("SA5",14,xFilial("SA5")+SA2->A2_COD+SA2->A2_LOJA+ PADR(AllTrim(cProdFor),20),"A5_PRODUTO")

			//buscar a TES conforme o produto...
			cTES   		:= Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_TE")
			cPedido		:= Space(6)
			cItem		:= Space(4)
			// Se existir pedidos com saldo nos parametros pelo usuario, inicio a logica de busca dos pedidos de compra.
			////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			If !Empty(Len(aPedidos))
				// Se encontrar o produto na lista de pedidos....
				////////////////////////////////////////////////////////////////////////////////
				//nPos := aScan(aPedidos,{|x| x[4] == cProduto }) retirado Peter 21/07/2016
				//If !Empty(nPos) retirado Peter 21/07/2016
				For _y := 1 To Len(aPedidos) // retirado _y := nPos substituido por 1
					// Verifico em todos os saldos de pedidos existentes para o produto, se existe a quantidade e preco exato do XML.
					/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
					If aPedidos[_y][1] == "A" .and. aPedidos[_y][6] == nVUnit
						aPedidos[_y][1] := "B"
						cPedido			:= aPedidos[_y][2]
						cItem			:= aPedidos[_y][3]
						cProduto		:= aPedidos[_y][4]
						Exit
					EndIf
					//If aPedidos[_y][4] <> cProduto
					//	Exit
					//EndIf
				Next _y
				//EndIf retirado Peter 21/07/2016
			EndIf

			If Empty(cProduto) .Or. cProduto == nil
				cProduto := Space(15)
			EndIf


			nPosDoc		:=	Ascan(aHeader, {|x| alltrim(x[2]) == "F1_DOC"})
			nPosCodF	:=	Ascan(aHeader, {|x| alltrim(x[2]) == "A2_COD"})
			nPosDesF	:=	Ascan(aHeader, {|x| alltrim(x[2]) == "A2_NOME"})
			nPosProd	:=	Ascan(aHeader, {|x| alltrim(x[2]) == "C1_PRODUTO"})
			nPosDesP	:=	Ascan(aHeader, {|x| alltrim(x[2]) == "C1_DESCRI"})
			nPosProF	:=	Ascan(aHeader, {|x| alltrim(x[2]) == "A5_CODPRF"})
			nPosProXM	:=	Ascan(aHeader, {|x| alltrim(x[2]) == "ZZ4_DESPRD"})
			nPosQtd		:=	Ascan(aHeader, {|x| alltrim(x[2]) == "D1_QUANT"})
			nPosVal		:=	Ascan(aHeader, {|x| alltrim(x[2]) == "D1_VUNIT"})
			nPosTot		:=	Ascan(aHeader, {|x| alltrim(x[2]) == "D1_TOTAL"})
			nPosNCM		:=	Ascan(aHeader, {|x| alltrim(x[2]) == "B1_POSIPI"})
			nPosPed		:=	Ascan(aHeader, {|x| alltrim(x[2]) == "D1_PEDIDO"})
			nPosPedI 	:=	Ascan(aHeader, {|x| alltrim(x[2]) == "D1_ITEMPC"})

			//GR_CODIGO
			PswOrder(2)
			lAchou       := PSWSeek(Substr(cUsuario,7,15))
			aUserFl      := PswRet(1)
			IdUsuario    := aUserFl[1][1]      // codigo do usuario
			NomeUsuario := aUserFl[1][4]      // nome do usuario
			EmailUsuario := aUserFl[1][14]     // Email

			if Len(Alltrim(cPedido))==0
				cPedido:= MV_PAR03
			endif
			aadd(aCols,Array(nUsado+1))
			aCols[Len(aCols)][nPosDoc] 	:= cDoc
			aCols[Len(aCols)][nPosCodF] := cCodFor
			aCols[Len(aCols)][nPosDesF] := cDescFor
			aCols[Len(aCols)][nPosProd] := cProduto
			aCols[Len(aCols)][nPosDesP] := Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_DESC") 
			aCols[Len(aCols)][nPosProF]	:= cProdFor
			aCols[Len(aCols)][nPosProXM]:= cDescPrd
			aCols[Len(aCols)][nPosQtd] 	:= nQtdItem
			aCols[Len(aCols)][nPosVal] 	:= nVUnit
			aCols[Len(aCols)][nPosTot] 	:= nTotItem
			aCols[Len(aCols)][nPosNCM] 	:= AllTrim(cNCM)
			aCols[Len(aCols)][nPosPed] 	:= cPedido
			aCols[Len(aCols)][nPosPedI] := cItem

			//---------------------------------------------------------------------------------------------------------------------
			aCols[Len(aCols)][nUsado+1] := .F.
			dbskip()
		enddo
	endif
	// Varro o aCols para pegar por aproximacao mais pedidos em aberto.
	//////////////////////////////////////////////////////////////////////////////////////////////
	/*
	For _x := 1 To Len(aCols)
	// Se o item ainda nao tiver pedido...
	///////////////////////////////////////////////////////////////////////////////////////////////
	If Empty(aCols[_x][8])
	For _y := 1 To Len(aPedidos)
	// Verifico em todos os saldos de pedidos existentes, se existe a quantidade e preco exato do XML.
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	If aPedidos[_y][1] == "A" .and. aPedidos[_y][5] == aCols[_x][5] .and. aPedidos[_y][7] == aCols[_x][7]
	aPedidos[_y][1] := "B"
	aCols[_x][8]	:= aPedidos[_y][2]
	Exit
	EndIf
	Next _y
	EndIf
	Next _x
	*/
	aadd(aGetAux ,"C1_PRODUTO")
	aadd(aGetAux ,"C1_DESCRI")
	//aadd(aGetAux ,"D1_ITEMPC")
	aadd(aGetAux ,"B1_POSIPI")

	//GR_CODIGO
	PswOrder(2)
	lAchou       := PSWSeek(Substr(cUsuario,7,15))
	aUserFl      := PswRet(1)
	IdUsuario    := aUserFl[1][1]      // codigo do usuario
	NomeUsuario := aUserFl[1][4]       // nome do usuario
	EmailUsuario := aUserFl[1][14]     // Email

	// Monta a tela de inclusao
	/////////////////////////////////////////////////// 0,0,450,770
	While .T.
		nOpcGet := 0
		_oDlg := TDialog():New(005,005,400,1210,"Pedido x Pré Nota de Entrada",,,,,,,,,.T.,,,,,)
		_oDlg:lCentered := .T.

		// Cria a Enchoice
		////////////////////////////////////////////////////////////////////////////////////////
		bCancel := { || (_oDlg:End(), nOpcGet := 0)}
		bOK 	:= { || If(I010OK(), (I010MANUT(), nOpcGet := 1,_oDlg:End()), " ")}

		// Cria a GetDados
		//////////////////////////////////////////////////////////////////////////////////////// 20 ,005,210,378
		oGetDados := MsGetDados():New(030,005,180,600,nOpc,"U_I030LINHAOK()","AllwaysTrue",,.F.,aGetAux,,.F.,Len(aCols),"U_AVALIA()",,,"U_I030DELOK()",_oDlg)


		ACTIVATE MSDIALOG _oDlg ON INIT (EnchoiceBar(_oDlg,bOk,bCancel)) CENTERED

		Exit

		//	aCols[n][nPosDesP] := Posicione("SB1",1,xFilial("SB1")+Posicione("SB1",1,xFilial("SB1")+aCols[n][nPosPRD],"B1_COD"),"B1_DESC")
	End
	If !Empty(Len(a140Cab)) .and. !Empty(Len(a140Item))
		// Gera a pre-nota.
		//////////////////////////////////////////////////////////////////////////////////////
		lMsErroAuto := .F.
		MsExecAuto({|x,y,z| Mata140(x,y,z)},a140Cab,a140Item,3)
		If lMsErroAuto
			MostraErro()
		Endif
		a140Cab		:= {}
		a140Item    := {}
		dbselectarea("ZZ3")
		dbsetorder(1)
		if dbseek(xFilial("ZZ3")+cchNFe)
			reclock("ZZ3",.F.)
			dbdelete()
			msunlock()
		endif
		dbselectarea("ZZ4")
		dbsetorder(1)
		if dbseek(xFilial("ZZ4")+cchNFe)
			while !EOF() .AND. ZZ4->ZZ4_CHV == cchNFe
				reclock("ZZ4",.F.)
				dbdelete()
				msunlock()
				dbskip()
			end
		endif
		aIPI		:= {}
		aICMS		:= {}
		aVCST		:= {}
		aBCST		:= {}
		aBASE		:= {}
		aPICMS		:= {}
		aICMSST     := {}
		aDescon     := {}
		aOutros     := {}
		aFrete      := {}
		aSeguro     := {}

		MSGALERT(" Pré Nota "+Alltrim(cDoc)+" Gerada Com Sucesso!")
	EndIf
	dbselectarea("SD1")
	dbclosearea()
	dbselectarea("SF1")
	dbclosearea()
	SA2->(dbSetOrder(nIndAxSA2))
	RestArea(aSegSA2)
Return

User Function AVALIA()
	Local nPosProd := Ascan(aHeader, {|x| alltrim(x[2]) == "C1_PRODUTO"})
	Local nPosDesP	:=	Ascan(aHeader, {|x| alltrim(x[2]) == "C1_DESCRI"})

	If nPosProd == 4 // "C1_PRODUTO"
		aCols[n][nPosDesP] := Posicione("SB1",1,xFilial("SB1")+SB1->B1_COD,"B1_DESC")
		oGetDados:oBrowse:Refresh()
	EndIf

Return .t.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ I030LINHAOK      ³ Gustavo Baptista   º Data ³             º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Funcao que valida a linha da MsGetDados.                   º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ IBM300                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function I030LINHAOK()
	***************************
	Local lRet := .T.
	Local i:= 0
	Local nPosPRD 	:=	Ascan(aHeader, {|x| alltrim(x[2]) == "C1_PRODUTO"})

	if Len(Alltrim(aCols[n][nPosPRD])) == 0
		msginfo("Preencha o código do Produto.")
		Return .F.
	endif
	if Len(Alltrim(Posicione("SB1",1,xFilial("SB1")+aCols[n][nPosPRD],"B1_COD") )) == 0
		msginfo("Código de Produto inválido.")
		Return .F.
	endif

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ I030DELOK        ³ Gustavo Baptista       º Data ³         º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Funcao que valida o delete da linha na MsGetDados.         º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ IBM300                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function I030DELOK()
	*************************
	Local lRet := .T.
Return lRet

/*-----------------------------------------------------------
|Função: I010OK	|	Autor: Rodrigo Nogueira de Lima         |
|Descricao: Verifica dados do aCols após a confirmação      |
|Data: 11/03/2014                                           |
-----------------------------------------------------------*/
Static Function I010OK()
	************************
	For nI := 1 To Len(aCols)
		If Empty(aCols[nI,4])
			MSGSTOP("Produto não informado na tela !","Campos não informados")
			Return .F.
		EndIf
	Next nI
Return .T.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ I010MANUT        ³ Gustavo Baptista      º Data ³          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Funcao que monta o array de itens do documento de          º±±
±±º          ³ entrada apos a confirmacao da Tela de Pedido x             º±±
±±º          ³ Documento de Entrada.                                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ NOR02A02                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function I010MANUT()
	***************************
	Local _x
	Local nTamHeader := Len(aHeader)+1

	//Caso não exista cadastrado Produto x Fornecedor faz o cadastro| Autor: Rodrigo Nogueira de Lima --------------------------------------
	For nI := 1 To Len(aCols)
		dbSelectArea("SA5")
		SA5->(dbSetOrder(1))
		If !SA5->(dbSeek(xFilial("SA5") + PADR(AllTrim(SA2->A2_COD),TamSX3("A5_FORNECE")[1]) + PADR(AllTrim(SA2->A2_LOJA),TamSX3("A5_LOJA")[1]) + PADR(AllTrim(aCols[nI,4]),TamSX3("A5_PRODUTO")[1])))
			RecLock("SA5",.T.)
			SA5->A5_FILIAL	:= xFilial("SA5")
			SA5->A5_FORNECE	:= SA2->A2_COD
			SA5->A5_LOJA	:= SA2->A2_LOJA
			SA5->A5_NOMEFOR	:= SA2->A2_NOME
			SA5->A5_PRODUTO := aCols[nI,4]
			SA5->A5_NOMPROD	:= Posicione("SB1",1,xFilial("SB1") + aCols[nI,4],"B1_DESC")
			SA5->A5_CODPRF	:= Alltrim(aCols[nI,6])
			SA5->A5_DESCPRF := Alltrim(aCols[nI,7])      //THIAGO - C101 - ADICIONADO PARA GRAVAR DESCRICAO PRODUTO FORNECEDOR.
			SA5->(msUnlock())
		EndIF
		//gustavo - pedido
		cPedQry := ""
		cProdFor:= aCols[nI,6]
		nQtdItem:= aCols[nI,8]
		nVUnit:= aCols[nI,9]
		If !Empty(MV_PAR03)
			cPedQry := MV_PAR03
		EndIf

		If (Select(cAlias2Temp) <> 0)
			dbSelectArea(cAlias2Temp)
			dbCloseArea()
		EndIf

		If !Empty(cPedQry)
			BeginSql Alias cAlias2Temp
			select
			C7_NUM, C7_ITEM, C7_PRODUTO, (C7_QUANT - C7_QUJE) as C7_SALDO, C7_PRECO, C7_TOTAL
			from
			%table:SC7%
			where
			C7_FILIAL = %xFilial:SC7% and %NotDel%
			and (C7_QUANT - C7_QUJE) >= 0
			and C7_ENCER <> 'E' and C7_RESIDUO = ' '
			and C7_NUM IN (%exp:cPedQry%)
			order by
			C7_PRODUTO
			EndSql

			aTam := TamSX3("C7_QUANT")
			TcSetField(cAlias2Temp,"C7_SALDO"		,"N"	, aTam[1]	, aTam[2]	)
			aTam := TamSX3("C7_PRECO")
			TcSetField(cAlias2Temp,"C7_PRECO"		,"N"	, aTam[1]	, aTam[2]	)
			aTam := TamSX3("C7_TOTAL")
			TcSetField(cAlias2Temp,"C7_TOTAL"		,"N"	, aTam[1]	, aTam[2]	)

			While !(cAlias2Temp)->(Eof())
				aadd(aPedidos,{"A",(cAlias2Temp)->C7_num,(cAlias2Temp)->C7_item,(cAlias2Temp)->C7_produto,(cAlias2Temp)->C7_saldo,(cAlias2Temp)->C7_preco,(cAlias2Temp)->C7_total})
				(cAlias2Temp)->(dbSkip())
			EndDo
		EndIf
		cProduto	:=	Posicione("SA5",14,xFilial("SA5")+SA2->A2_cod+SA2->A2_loja+cProdFor,"A5_PRODUTO") //PADR(AllTrim(cProdFor),15)

		cPedido		:= Space(6)
		cItem		:= Space(4)
		// Se existir pedidos com saldo nos parametros pelo usuario, inicio a logica de busca dos pedidos de compra.
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		If !Empty(Len(aPedidos))
		// Se encontrar o produto na lista de pedidos....
		////////////////////////////////////////////////////////////////////////////////
		nPos := aScan(aPedidos,{|x| x[4] == cProduto })
		If !Empty(nPos)
		For _y := nPos To Len(aPedidos)
		// Verifico em todos os saldos de pedidos existentes para o produto, se existe a quantidade e preco exato do XML.
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		If aPedidos[_y][1] == "A" //.and. aPedidos[_y][5] == nQtdItem .and. aPedidos[_y][6] == nVUnit
		aPedidos[_y][1] := "B"
		cPedido			:= aPedidos[_y][2]
		cItem			:= aPedidos[_y][3]
		GdFieldPut("D1_ITEMPC",cItem,nI)
		Exit
		EndIf
		If aPedidos[_y][4] <> cProduto
		Exit
		EndIf
		Next _y
		EndIf
		EndIf
		*/
		//
	Next nI
	//-------------------------------------------------------------------------------------------------------------------------------------

	For _x := 1 To Len(aCols)
		If !aCols[_x][nTamHeader]
			//Para preencher pedidos
			If !Empty(Len(aPedidos))
				// Se encontrar o produto na lista de pedidos....
				////////////////////////////////////////////////////////////////////////////////
				//				nPos := aScan(aPedidos,{|x| x[4] == GDFieldGet("D1_COD_AUX",_x) })
				//				If !Empty(nPos)
				For _y := 1 To Len(aPedidos)
					// Verifico em todos os saldos de pedidos existentes para o produto, se existe a quantidade e preco exato do XML.
					/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
					If aPedidos[_y][2] == mv_par03 .And. aPedidos[_y][4] = GDFieldGet("C1_PRODUTO",_x)
						cPedido := aPedidos[_y][2]
						cItem	:= aPedidos[_y][3]
					EndIf
				Next _y
				//				EndIf
			EndIf

		
			
			
			If !Empty(aIpi) .Or. !Empty(aICMS) .And. Alltrim(cPedido) == ""
				aadd(a140Item, 	{{	"D1_COD"		, GDFieldGet("C1_PRODUTO",_x)	, Nil},;
				{	"D1_QUANT" 		, GDFieldGet("D1_QUANT",_x)		, Nil},;
				{	"D1_VUNIT" 		, GDFieldGet("D1_VUNIT",_x)		, Nil},;
				{	"D1_TOTAL" 		, GDFieldGet("D1_TOTAL",_x)		, Nil},;
				{	"D1_VALIPI"		, Val(aIPI[_x])					, Nil},;
				{	"D1_IPI"		, Val(aPIPI[_x])				, Nil},;
				{	"D1_BASEICM"	, Val(aBASE[_x])				, Nil},;
				{	"D1_VALICM"		, Val(aICMS[_x])				, Nil},;
				{	"D1_ICMSRET"	, Val(aBCST[_x])				, Nil},; //{	"D1_TES"		, GDFieldGet("D1_TES",_x)	, Nil},;
				{	"D1_PICM"		, Val(aPICMS[_x])  				, Nil},; //aICMSST
				{	"D1_VALDESC"	, Val(aDescon[_x])  				, Nil},;
				{	"D1_DESPESA"	, Val(aOutros[_x])  				, Nil},;
				{	"D1_SEGURO"		, Val(aSeguro[_x])  				, Nil},;
				{	"D1_BRICMS"		, Val(aVCST[_x])			  		, Nil},;
				{	"D1_LOCAL"		, Posicione("SB1",1,xFilial("SB1") + GDFieldGet("C1_PRODUTO",_x),"B1_LOCPAD")				, Nil},;
				{	"D1_UM" 		, Posicione("SB1",1,xFilial("SB1") + GDFieldGet("C1_PRODUTO",_x),"B1_UM")	, Nil}})
				
			ElseIf !Empty(aIpi) .Or. !Empty(aICMS) .And. Alltrim(cPedido) <> ""
				aadd(a140Item, 	{{	"D1_COD"		, GDFieldGet("C1_PRODUTO",_x)	, Nil},;
				{	"D1_QUANT" 		, GDFieldGet("D1_QUANT",_x)		, Nil},;
				{	"D1_VUNIT" 		, GDFieldGet("D1_VUNIT",_x)		, Nil},;
				{	"D1_TOTAL" 		, GDFieldGet("D1_TOTAL",_x)		, Nil},;
				{	"D1_VALIPI"		, Val(aIPI[_x])					, Nil},;
				{	"D1_IPI"		, Val(aPIPI[_x])				, Nil},;
				{	"D1_BASEICM"	, Val(aBASE[_x])				, Nil},;
				{	"D1_VALICM"		, Val(aICMS[_x])				, Nil},;
				{	"D1_ICMSRET"	, Val(aBCST[_x])				, Nil},; //{	"D1_TES"		, GDFieldGet("D1_TES",_x)	, Nil},;
				{	"D1_PICM"		, Val(aPICMS[_x])  				, Nil},; //aICMSST
				{	"D1_VALDESC"	, Val(aDescon[_x])  				, Nil},;
				{	"D1_DESPESA"	, Val(aOutros[_x])  				, Nil},;
				{	"D1_SEGURO"		, Val(aSeguro[_x])  				, Nil},;
				{	"D1_BRICMS"		, Val(aVCST[_x])			  		, Nil},;
				{	"D1_LOCAL"		, Posicione("SB1",1,xFilial("SB1") + GDFieldGet("C1_PRODUTO",_x),"B1_LOCPAD")				, Nil},;
				{	"D1_UM" 		, Posicione("SB1",1,xFilial("SB1") + GDFieldGet("C1_PRODUTO",_x),"B1_UM")	, Nil},;
				{	"D1_PEDIDO"		, cPedido  				, Nil},;
				{	"D1_ITEMPC"		, cItem  				, Nil}})
				//														{	"D1_PICM"		, Val(aICMSST[_x])  				, Nil},;

			ElseIf Alltrim(cPedido) == "" .and. Alltrim(cItem) == ""
				aadd(a140Item, 	{{	"D1_COD"		, GDFieldGet("C1_PRODUTO",_x)	, Nil},;
				{	"D1_QUANT" 		, GDFieldGet("D1_QUANT",_x)		, Nil},;
				{	"D1_VUNIT" 		, GDFieldGet("D1_VUNIT",_x)		, Nil},;
				{	"D1_TOTAL" 		, GDFieldGet("D1_TOTAL",_x)		, Nil},;
				{	"D1_VALIPI"		, Val(aIPI[_x])					, Nil},;
				{	"D1_IPI"		, Val(aPIPI[_x])				, Nil},;
				{	"D1_BASEICM"	, Val(aBASE[_x])				, Nil},;
				{	"D1_VALICM"		, Val(aICMS[_x])				, Nil},;
				{	"D1_ICMSRET"	, Val(aBCST[_x])				, Nil},; //{	"D1_TES"		, GDFieldGet("D1_TES",_x)	, Nil},;
				{	"D1_PICM"		, Val(aPICMS[_x])  				, Nil},;//aICMSST
				{	"D1_VALDESC"	, Val(aDescon[_x])  				, Nil},;
				{	"D1_DESPESA"	, Val(aOutros[_x])  				, Nil},;
				{	"D1_SEGURO"		, Val(aSeguro[_x])  				, Nil},;
				{	"D1_BRICMS"		, Val(aVCST[_x])			  		, Nil},;
				{	"D1_LOCAL"		, Posicione("SB1",1,xFilial("SB1") + GDFieldGet("C1_PRODUTO",_x),"B1_LOCPAD")				, Nil},;
				{	"D1_UM" 		, Posicione("SB1",1,xFilial("SB1") + GDFieldGet("C1_PRODUTO",_x),"B1_UM")				, Nil}})
				//{	"D1_PEDIDO"		, cPedido  				, Nil},;
				//{	"D1_ITEMPC"		, cItem  				, Nil}})
				//														{	"D1_PICM"		, Val(aICMSST[_x])  				, Nil},;

			Else
				aadd(a140Item, 	{{	"D1_COD"		, GDFieldGet("C1_PRODUTO",_x)	, Nil},;
				{	"D1_QUANT" 		, GDFieldGet("D1_QUANT",_x)		, Nil},;
				{	"D1_VUNIT" 		, GDFieldGet("D1_VUNIT",_x)		, Nil},;
				{	"D1_TOTAL" 		, GDFieldGet("D1_TOTAL",_x)		, Nil},;
				{	"D1_PEDIDO"		, cPedido 				, Nil},;
				{	"D1_ITEMPC"		, cItem 				, Nil}})

			EndIf


		EndIf
	Next _x

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ I300CTEºAutor  ³ Gustavo Baptista   º Data ³ 07/08/2014    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Funcao que le o XML e monta a tela auxiliar com as         º±±
±±º          ³ informacoes extraidas do arquivo.                          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ NOR02A02                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function I300CTE()
	***************************
	Local oXml			:= Nil
	Local nXmlStatus
	Local cXml, cAviso, cErro, nHdlMod
	Local aGetAux		:= {}
	Local nUsado 		:= 0
	Local nOpcGet		:= 0
	Local cAlias1Temp	:= "IB300A"
	Local cAlias2Temp	:= "IB300B"
	Local cDoc, cSerie, cCgcFor, dEmissao, _x, _c, cProduto, cPedQry, aTam, _oDlg, _y, cPedido, cItem
	Local nIndAxSA2		:= SA2->(IndexOrd())
	Local aSegSA2		:= SA2->(GetArea())
	Local nPosFil
	Local nPosDoc
	Local nPosCodF
	Local nPosDesF
	Local nPosProd
	Local nPosDesP
	Local nPosQtd
	local nPosVal
	Local nPosTot
	Local nPosTes
	Local cNaturez
    Private _cTesFrete  := GetMv("MV_ZTESXML")
	Private aPedidos	:= {}
	Private nOpc	 	:= 3
	Private aCols	 	:= {}
	Private aHeader		:= {}
	Private a140Cab		:= {}
	Private a140Item	:= {}
	Private	oIpi		:= Nil
	Private	oIcms		:= Nil
	Private cCgcFor

	dbselectarea("ZZ3")
	dbsetorder(1)
	dbseek(xFilial("ZZ3")+Alltrim(cNomeDps))

	cCgcFor		:= ZZ3->ZZ3_CGC
	dEmissao	:= ZZ3->ZZ3_EMISS
	cDoc		:= ZZ3->ZZ3_DOC
	cSerie		:= ZZ3->ZZ3_SERIE
	cchCTe      := ZZ3->ZZ3_CHV

	// Busco o Fornecedor pelo CNPJ.
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	SA2->(dbSetOrder(3))
	If !SA2->(dbSeek(xFilial("SA2")+cCgcFor))
		Aviso("Rotina Abortada","Fornecedor nao encontrado. CNPJ: "+cCgcFor,{"Ok"})
		Return
	Else
		If !Empty(SA2->A2_COND)
			cCondPag	:= SA2->A2_COND
		EndIf
		If !Empty(SA2->A2_NATUREZ)
			cNaturez	:= SA2->A2_NATUREZ
		EndIf
		cCodFor		:= SA2->A2_COD
		cDescFor	:= SA2->A2_NOME
	EndIf

	// Verifico se a nota ja existe.
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	SF1->(dbSetOrder(1))
	If SF1->(dbSeek(xFilial("SF1")+cDoc+cSerie+SA2->A2_cod+SA2->A2_loja+"N"))
		Aviso("Rotina Abortada","Nota fiscal ja encontrada!!!",{"Ok"})
		Return
	EndIf

	// Monto o array do cabecalho da pre-nota.
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	a140Cab		:= {	{	"F1_TIPO"		, "N"							, Nil},;
	{	"F1_FORMUL"		, "N"							, Nil},;
	{	"F1_DOC"		, cDoc							, Nil},;
	{	"F1_SERIE"		, cSerie 						, Nil},;
	{	"F1_EMISSAO"	, dEmissao						, Nil},;
	{	"F1_FORNECE"	, SA2->A2_cod			 		, Nil},;
	{	"F1_LOJA"	  	, SA2->A2_loja  				, Nil},;
	{	"F1_ESPECIE" 	, "CTE"	  	  					, Nil},;
	{   "F1_COND"		, cCondPag						, Nil},;
	{	"F1_CHVNFE" 	, cchCTE 	  					, Nil}}   
		
	// Monta o aHeader da tela auxiliar
	///////////////////////////////////////////////////
	aHeader	:= {}
	_Desc   := ""

	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("F1_DOC",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ "Numero NF", SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("A2_COD",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ "Fornecedor", SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("A2_NOME",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek("C1_PRODUTO"))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("B1_DESC",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), "B1_DESC" , SX3->X3_picture,,,"","", SX3->X3_tipo, "",SX3->X3_context } )
	EndIf

	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("D1_QUANT",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("D1_VUNIT",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("D1_TOTAL",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(Padr("D1_TES",10)))
		nUsado:=nUsado+1
		aadd(aHeader,{ TRIM(SX3->X3_titulo), SX3->X3_campo, SX3->X3_picture,;
		SX3->X3_tamanho, SX3->X3_decimal,SX3->X3_vlduser,;
		SX3->X3_usado, SX3->X3_tipo, SX3->X3_arquivo, SX3->X3_context } )
	EndIf

	//----------------------------------------------------------------------------------------------------------------------

	// Inicializo o aCols
	///////////////////////////////////////////////////
	aCols	:= {}

	dbselectarea("ZZ4")
	dbsetorder(1)
	IF dbseek(xFilial("ZZ4")+ZZ3->ZZ3_CHV)
		while(!EOF() .and. ZZ3->ZZ3_CHV == ZZ4->ZZ4_CHV )
			//cProdFor	:= ZZ4->ZZ4_CODPRO
			cProduto    := ZZ4->ZZ4_CODPRO
			nQtdItem	:= ZZ4->ZZ4_QTD
			nVUnit		:= ZZ4->ZZ4_VUNIT
			nTotItem	:= ZZ4->ZZ4_TOTAL
			cDescPrd	:= ZZ4->ZZ4_DESPRD
			cNCM		:= ZZ4->ZZ4_NCM
			//	AADD(aICMS,	STR(ZZ4->ZZ4_ICMS))
			//	AADD(aIPI,	STR(ZZ4->ZZ4_IPI))

			nPosDoc		:=	Ascan(aHeader, {|x| alltrim(x[2]) == "F1_DOC"})
			nPosCodF	:=	Ascan(aHeader, {|x| alltrim(x[2]) == "A2_COD"})
			nPosDesF	:=	Ascan(aHeader, {|x| alltrim(x[2]) == "A2_NOME"})
			nPosProd	:=	Ascan(aHeader, {|x| alltrim(x[2]) == "C1_PRODUTO"})
			nPosDesP	:=	Ascan(aHeader, {|x| alltrim(x[2]) == "B1_DESC"})
			//nPosProXM   :=  Ascan(aHeader, {|x| alltrim(x[2]) == "ZZ4_DESPRD"})
			nPosQtd		:=	Ascan(aHeader, {|x| alltrim(x[2]) == "D1_QUANT"})
			nPosVal		:=	Ascan(aHeader, {|x| alltrim(x[2]) == "D1_VUNIT"})
			nPosTot		:=	Ascan(aHeader, {|x| alltrim(x[2]) == "D1_TOTAL"})
			nPosTes		:=	Ascan(aHeader, {|x| alltrim(x[2]) == "D1_TES"})

			aadd(aCols,Array(nUsado+1))
			aCols[Len(aCols)][nPosDoc] 	:= cDoc
			aCols[Len(aCols)][nPosCodF] := cCodFor
			aCols[Len(aCols)][nPosDesF] := cDescFor
			aCols[Len(aCols)][nPosProd] := PADR(cProduto,TamSX3("C1_PRODUTO")[1])
			aCols[Len(aCols)][nPosDesP] := PADR(cDescPrd,TamSX3("B1_DESC")[1])
			aCols[Len(aCols)][nPosQtd] 	:= 1
			aCols[Len(aCols)][nPosVal] 	:= nVUnit
			aCols[Len(aCols)][nPosTot] 	:= nTotItem
			aCols[Len(aCols)][nPosTes] 	:= _cTesFrete
			aCols[Len(aCols)][nUsado+1] := .F.

			ZZ4->(DbSkip())
		EndDo
	EndIF
	// Monta a tela de inclusao
	/////////////////////////////////////////////////// 0,0,450,770
	While .T.
		nOpcGet := 0
		_oDlg := TDialog():New(005,005,400,1210,"Pedido x Pré Nota de Entrada",,,,,,,,,.T.,,,,,)
		_oDlg:lCentered := .T.

		// Cria a Enchoice
		/////////////////////////////admin	///////////////////////////////////////////////////////////
		bCancel := { || (_oDlg:End(), nOpcGet := 0)}
		bOK 	:= { || If(I010OK(), ( MTARRAY(), nOpcGet := 1,_oDlg:End()), " ")}

		// Cria a GetDados
		//////////////////////////////////////////////////////////////////////////////////////// 20 ,005,210,378
		oGetDados := MsGetDados():New(030,005,180,600,nOpc,"U_I030LINHAOK()","AllwaysTrue",,.F.,aGetAux,,.F.,Len(aCols),,,,"U_I030DELOK()",_oDlg)
		//oBrowQtd:= MsGetDados():New(152,005,225,385,nOpc,"AllwaysTrue"    ,"AllwaysTrue",,.T.,aGetQtd,,   ,Len(aCols))

		ACTIVATE MSDIALOG _oDlg ON INIT (EnchoiceBar(_oDlg,bOk,bCancel)) CENTERED

		Exit
	End

	If !Empty(Len(a140Cab)) .and. !Empty(Len(a140Item))
		lMsErroAuto := .F.
		// Gera a pre-nota.
		//////////////////////////////////////////////////////////////////////////////////////
		Begin Transaction
			//MsExecAuto({|x,y,z| Mata140(x,y,z)},a140Cab,a140Item,3)
			MSExecAuto({|x,y| Mata103(x,y)},a140Cab,a140Item)
			If lMsErroAuto
				MostraErro()
				DisarmTransaction()
				Break
			Else
				MSGALERT(" Nota de Entrada "+Alltrim(cDoc)+" Gerada Com Sucesso!")
			Endif
		End Transaction
	EndIf

	SA2->(dbSetOrder(nIndAxSA2))
	RestArea(aSegSA2)
Return  
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ MTARRAY        ³ Rodrigo       º Data ³             º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Funcao que monta o array de itens do documento de          º±±
±±º          ³ entrada apos a confirmacao da Tela de Pedido x             º±±
±±º          ³ Documento de Entrada.                                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ NOR02A02                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/                   
Static Function MTARRAY()
	***************************
	Local _x
	Local nTamHeader := Len(aHeader)+1

	For _x := 1 To Len(aCols)
		If !aCols[_x][nTamHeader]
			aadd(a140Item, 	{	{	"D1_COD"	  	, GDFieldGet("C1_PRODUTO",_x)		, Nil},;
			{	"D1_QUANT" 		, GDFieldGet("D1_QUANT",_x)		, Nil},;
			{	"D1_VUNIT" 		, GDFieldGet("D1_VUNIT",_x)		, Nil},;
			{	"D1_TOTAL" 		, GDFieldGet("D1_TOTAL",_x)		, Nil},;
			{	"D1_TES" 		, GDFieldGet("D1_TES",_x)		, Nil}})
		EndIf
	Next _x

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ AjustaSX1ºAutor  ³ Gustavo Baptista   º Data ³             º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Cria grupo de perguntas.                                   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ NOR02A02                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function AjustaSX1()
	***************************
	Local aHelpPor := {}
	Local aHelpEng := {}
	Local aHelpSpa := {}
	Local aRegs := {}
	Local cPerg1   := "DPXMLI    "

	//PutSx1(cPerg1,"01","Chave Documento      ?","Chave Documento      ?","Chave Documento        ?","mv_ch1","C",80,0,0,"G","","DIR","","","MV_PAR01","","","","","","","","","","","","","","","","" )//,	{"Informe a chave do documento",	"",	""},{ },{ })
	//PutSx1(cPerg1,"02","Cond. Pgto			?","Cond. Pgto			 ?","Cond. Pgto				?","mv_ch2","C",06,0,0,"G","","SC7","","","MV_PAR02","","","","","","","","","","","","","","","",""	)
	//PutSx1(cPerg1,"03","Cond. Pgto			?","Cond. Pgto			 ?","Cond. Pgto				?","mv_ch3","C",03,0,0,"G","","SE4","","","MV_PAR03","","","","","","","","","","","","","","","",""	)
	
	//Pedido de Compra era o MV_PAR02, eu retirei.... e no lugar ficou a condição de pagamento.... 
	// Trocar condicao de pagamento para mv_par03 e adicionar a pergunta "Pedido" como mv_par02

	dbSelectArea("SX1")
	dbSetOrder(1)
	aRegs :={}

	AADD(aRegs,{cPerg1,"01","Chave Documento:","Chave Documento:","Chave Documento:","mv_ch1","C",80,0,0,"G","","DIR","","","MV_PAR01"})
	AADD(aRegs,{cPerg1,"02","Cond. Pgto:","Cond. Pgto:","Cond. Pgto:","mv_ch2","C",03,0,0,"G","","SE4","","","MV_PAR02"})
	AADD(aRegs,{cPerg1,"03","Pedido:","Pedido:","Pedido:","mv_ch3","C",06,0,0,"G","","SC7","","","MV_PAR02"})
	
	For i:=1 to LEN(aRegs)
		If !dbSeek(cPerg1 + aRegs[i,2])
			RecLock("SX1",.T.)
			SX1->X1_GRUPO := aRegs[i,1]
			SX1->X1_ORDEM := aRegs[i,2]
			SX1->X1_PERGUNT := aRegs[i,3]
			SX1->X1_PERSPA := aRegs[i,4]
			SX1->X1_PERENG := aRegs[i,5]
			SX1->X1_VARIAVL := aRegs[i,6]
			SX1->X1_TIPO := aRegs[i,7]
			SX1->X1_TAMANHO := aRegs[i,8]
			SX1->X1_DECIMAL := aRegs[i,9]
			SX1->X1_PRESEL := aRegs[i,10]
			SX1->X1_GSC := aRegs[i,11]
			SX1->X1_VALID := aRegs[i,12]
			SX1->X1_F3 := aRegs[i,13]
			SX1->X1_VAR01 := aRegs[i,16]
			MsUnlock()
		Endif
	Next i    

Return


/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ 														      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ ROTINAS ABAIXO PARA CRIAR TABELAS E INDICES SEM ACESSO     º±±
±±º          ³ EXCLUSIVO. NAO ALTERAR NADA ABAIXO.						  º±±
±±º          ³ 						                                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºAlterado ³ Peterson J. Savi	20/01/2017         						   ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function FSAtuSX2()


	Local aEstrut   := {}
	Local aSX2      := {}
	Local cAlias    := ""
	Local cCpoUpd   := "X2_ROTINA /X2_UNICO  /X2_DISPLAY/X2_SYSOBJ /X2_USROBJ /X2_POSLGT /"
	Local cEmpr     := ""
	Local cPath     := ""
	Local nI        := 0
	Local nJ        := 0

	AutoGrLog( "Ínicio da Atualização" + " SX2" + CRLF )

	aEstrut := { "X2_CHAVE"  , "X2_PATH"   , "X2_ARQUIVO", "X2_NOME"   , "X2_NOMESPA", "X2_NOMEENG", "X2_MODO"   , ;
	"X2_TTS"    , "X2_ROTINA" , "X2_PYME"   , "X2_UNICO"  , "X2_DISPLAY", "X2_SYSOBJ" , "X2_USROBJ" , ;
	"X2_POSLGT" , "X2_CLOB"   , "X2_AUTREC" , "X2_MODOEMP", "X2_MODOUN" , "X2_MODULO" }


	dbSelectArea( "SX2" )
	SX2->( dbSetOrder( 1 ) )
	SX2->( dbGoTop() )
	cPath := SX2->X2_PATH
	cPath := IIf( Right( AllTrim( cPath ), 1 ) <> "\", PadR( AllTrim( cPath ) + "\", Len( cPath ) ), cPath )
	cEmpr := Substr( SX2->X2_ARQUIVO, 4 )

	//
	// Tabela ZZ3
	//
	aAdd( aSX2, { ;
	'ZZ3'																	, ; //X2_CHAVE
	''   																	, ; //X2_PATH
	'ZZ3'+cEmpr																, ; //X2_ARQUIVO
	'IMPORTACAO XML (CAB)'													, ; //X2_NOME
	'IMPORTACAO XML (CAB)'													, ; //X2_NOMESPA
	'IMPORTACAO XML (CAB)'													, ; //X2_NOMEENG
	'C'																		, ; //X2_MODO
	''																		, ; //X2_TTS
	''																		, ; //X2_ROTINA
	''																		, ; //X2_PYME
	''																		, ; //X2_UNICO
	''																		, ; //X2_DISPLAY
	''																		, ; //X2_SYSOBJ
	''																		, ; //X2_USROBJ
	'1'																		, ; //X2_POSLGT
	'2'																		, ; //X2_CLOB
	'2'																		, ; //X2_AUTREC
	'C'																		, ; //X2_MODOEMP
	'C'																		, ; //X2_MODOUN
	0																		} ) //X2_MODULO

	//
	// Tabela ZZ4
	//
	aAdd( aSX2, { ;
	'ZZ4'																	, ; //X2_CHAVE
	''																		, ; //X2_PATH
	'ZZ4'+cEmpr																, ; //X2_ARQUIVO
	'IMPORTACAO XML (ITENS)'												, ; //X2_NOME
	'IMPORTACAO XML (ITENS)'												, ; //X2_NOMESPA
	'IMPORTACAO XML (ITENS)'												, ; //X2_NOMEENG
	'C'																		, ; //X2_MODO
	''																		, ; //X2_TTS
	''																		, ; //X2_ROTINA
	''																		, ; //X2_PYME
	''																		, ; //X2_UNICO
	''																		, ; //X2_DISPLAY
	''																		, ; //X2_SYSOBJ
	''																		, ; //X2_USROBJ
	'1'																		, ; //X2_POSLGT
	'2'																		, ; //X2_CLOB
	'2'																		, ; //X2_AUTREC
	'C'																		, ; //X2_MODOEMP
	'C'																		, ; //X2_MODOUN
	0																		} ) //X2_MODULO

	//
	// Atualizando dicionário
	//

	dbSelectArea( "SX2" )
	dbSetOrder( 1 )

	For nI := 1 To Len( aSX2 )


		If !SX2->( dbSeek( aSX2[nI][1] ) )

			If !( aSX2[nI][1] $ cAlias )
				cAlias += aSX2[nI][1] + "/"
				AutoGrLog( "Foi incluída a tabela " + aSX2[nI][1] )
			EndIf

			RecLock( "SX2", .T. )
			For nJ := 1 To Len( aSX2[nI] )
				If FieldPos( aEstrut[nJ] ) > 0
					If AllTrim( aEstrut[nJ] ) == "X2_ARQUIVO"
						FieldPut( FieldPos( aEstrut[nJ] ), SubStr( aSX2[nI][nJ], 1, 3 ) + cEmpAnt +  "0" )
					Else
						FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
					EndIf
				EndIf
			Next nJ
			MsUnLock()

		Else

			If  !( StrTran( Upper( AllTrim( SX2->X2_UNICO ) ), " ", "" ) == StrTran( Upper( AllTrim( aSX2[nI][12]  ) ), " ", "" ) )
				RecLock( "SX2", .F. )
				SX2->X2_UNICO := aSX2[nI][12]
				MsUnlock()

				If MSFILE( RetSqlName( aSX2[nI][1] ),RetSqlName( aSX2[nI][1] ) + "_UNQ"  )
					TcInternal( 60, RetSqlName( aSX2[nI][1] ) + "|" + RetSqlName( aSX2[nI][1] ) + "_UNQ" )
				EndIf

				AutoGrLog( "Foi alterada a chave única da tabela " + aSX2[nI][1] )
			EndIf

			RecLock( "SX2", .F. )
			For nJ := 1 To Len( aSX2[nI] )
				If FieldPos( aEstrut[nJ] ) > 0
					If PadR( aEstrut[nJ], 10 ) $ cCpoUpd
						FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
					EndIf

				EndIf
			Next nJ
			MsUnLock()

		EndIf

	Next nI

	AutoGrLog( CRLF + "Final da Atualização" + " SX2" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX3
Função de processamento da gravação do SX3 - Campos

@author TOTVS Protheus
@since  06/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
User Function FSAtuSX3()
	Local aEstrut   := {}
	Local aSX3      := {}
	Local cAlias    := ""
	Local cAliasAtu := ""
	Local cMsg      := ""
	Local cSeqAtu   := ""
	Local cX3Campo  := ""
	Local cX3Dado   := ""
	Local lTodosNao := .F.
	Local lTodosSim := .F.
	Local nI        := 0
	Local nJ        := 0
	Local nOpcA     := 0
	Local nPosArq   := 0
	Local nPosCpo   := 0
	Local nPosOrd   := 0
	Local nPosSXG   := 0
	Local nPosTam   := 0
	Local nPosVld   := 0
	Local nSeqAtu   := 0
	Local nTamSeek  := Len( SX3->X3_CAMPO )
	Local nSizeFil  := FWSizeFilial()

	AutoGrLog( "Ínicio da Atualização" + " SX3" + CRLF )

	aEstrut := { { "X3_ARQUIVO", 0 }, { "X3_ORDEM"  , 0 }, { "X3_CAMPO"  , 0 }, { "X3_TIPO"   , 0 }, { "X3_TAMANHO", 0 }, { "X3_DECIMAL", 0 }, { "X3_TITULO" , 0 }, ;
	{ "X3_TITSPA" , 0 }, { "X3_TITENG" , 0 }, { "X3_DESCRIC", 0 }, { "X3_DESCSPA", 0 }, { "X3_DESCENG", 0 }, { "X3_PICTURE", 0 }, { "X3_VALID"  , 0 }, ;
	{ "X3_USADO"  , 0 }, { "X3_RELACAO", 0 }, { "X3_F3"     , 0 }, { "X3_NIVEL"  , 0 }, { "X3_RESERV" , 0 }, { "X3_CHECK"  , 0 }, { "X3_TRIGGER", 0 }, ;
	{ "X3_PROPRI" , 0 }, { "X3_BROWSE" , 0 }, { "X3_VISUAL" , 0 }, { "X3_CONTEXT", 0 }, { "X3_OBRIGAT", 0 }, { "X3_VLDUSER", 0 }, { "X3_CBOX"   , 0 }, ;
	{ "X3_CBOXSPA", 0 }, { "X3_CBOXENG", 0 }, { "X3_PICTVAR", 0 }, { "X3_WHEN"   , 0 }, { "X3_INIBRW" , 0 }, { "X3_GRPSXG" , 0 }, { "X3_FOLDER" , 0 }, ;
	{ "X3_CONDSQL", 0 }, { "X3_CHKSQL" , 0 }, { "X3_IDXSRV" , 0 }, { "X3_ORTOGRA", 0 }, { "X3_TELA"   , 0 }, { "X3_POSLGT" , 0 }, { "X3_IDXFLD" , 0 }, ;
	{ "X3_AGRUP"  , 0 }, { "X3_MODAL"  , 0 }, { "X3_PYME"   , 0 } }

	aEval( aEstrut, { |x| x[2] := SX3->( FieldPos( x[1] ) ) } )


	//
	// Campos Tabela ZZ3
	//
	aAdd( aSX3, { ;
	'ZZ3'																	, ; //X3_ARQUIVO
	'01'																	, ; //X3_ORDEM
	'ZZ3_FILIAL'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	nSizeFil																, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Filial'																, ; //X3_TITULO
	'Sucursal'																, ; //X3_TITSPA
	'Branch'																, ; //X3_TITENG
	'Filial do Sistema'														, ; //X3_DESCRIC
	'Sucursal'																, ; //X3_DESCSPA
	'Branch of the System'													, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	1																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	''																		, ; //X3_VISUAL
	''																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	'033'																	, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ3'																	, ; //X3_ARQUIVO
	'02'																	, ; //X3_ORDEM
	'ZZ3_CHV'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	44																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Chave Doc'																, ; //X3_TITULO
	'Chave Doc'																, ; //X3_TITSPA
	'Chave Doc'																, ; //X3_TITENG
	'Chave Doc'																, ; //X3_DESCRIC
	'Chave Doc'																, ; //X3_DESCSPA
	'Chave Doc'																, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ3'																	, ; //X3_ARQUIVO
	'03'																	, ; //X3_ORDEM
	'ZZ3_DOC'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	9																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Numero Doc'															, ; //X3_TITULO
	'Numero Doc'															, ; //X3_TITSPA
	'Numero Doc'															, ; //X3_TITENG
	'Numero Doc'															, ; //X3_DESCRIC
	'Numero Doc'															, ; //X3_DESCSPA
	'Numero Doc'															, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ3'																	, ; //X3_ARQUIVO
	'04'																	, ; //X3_ORDEM
	'ZZ3_SERIE'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	3																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Serie'																	, ; //X3_TITULO
	'Serie'																	, ; //X3_TITSPA
	'Serie'																	, ; //X3_TITENG
	'Serie'																	, ; //X3_DESCRIC
	'Serie'																	, ; //X3_DESCSPA
	'Serie'																	, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ3'																	, ; //X3_ARQUIVO
	'05'																	, ; //X3_ORDEM
	'ZZ3_EMISS'																, ; //X3_CAMPO
	'D'																		, ; //X3_TIPO
	8																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Dt. Emissao'															, ; //X3_TITULO
	'Dt. Emissao'															, ; //X3_TITSPA
	'Dt. Emissao'															, ; //X3_TITENG
	'Dt. Emissao'															, ; //X3_DESCRIC
	'Dt. Emissao'															, ; //X3_DESCSPA
	'Dt. Emissao'															, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ3'																	, ; //X3_ARQUIVO
	'06'																	, ; //X3_ORDEM
	'ZZ3_CGC'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	14																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'CNPJ'																	, ; //X3_TITULO
	'CNPJ'																	, ; //X3_TITSPA
	'CNPJ'																	, ; //X3_TITENG
	'CNPJ'																	, ; //X3_DESCRIC
	'CNPJ'																	, ; //X3_DESCSPA
	'CNPJ'																	, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ3'																	, ; //X3_ARQUIVO
	'07'																	, ; //X3_ORDEM
	'ZZ3_TIPO'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	3																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Tipo Doc'																, ; //X3_TITULO
	'Tipo Doc'																, ; //X3_TITSPA
	'Tipo Doc'																, ; //X3_TITENG
	'Tipo Doc'																, ; //X3_DESCRIC
	'Tipo Doc'																, ; //X3_DESCSPA
	'Tipo Doc'																, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ3'																	, ; //X3_ARQUIVO
	'08'																	, ; //X3_ORDEM
	'ZZ3_CANC'																, ; //X3_CAMPO
	'L'																		, ; //X3_TIPO
	1																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Canc'																	, ; //X3_TITULO
	'Canc'																	, ; //X3_TITSPA
	'Canc'																	, ; //X3_TITENG
	'Canc'																	, ; //X3_DESCRIC
	'Canc'																	, ; //X3_DESCSPA
	'Canc'																	, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ3'																	, ; //X3_ARQUIVO
	'09'																	, ; //X3_ORDEM
	'ZZ3_BCST'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	12																		, ; //X3_TAMANHO
	2																		, ; //X3_DECIMAL
	'BASE ICMS ST'															, ; //X3_TITULO
	'BASE ICMS ST'															, ; //X3_TITSPA
	'BASE ICMS ST'															, ; //X3_TITENG
	'BASE ICMS ST'															, ; //X3_DESCRIC
	'BASE ICMS ST'															, ; //X3_DESCSPA
	'BASE ICMS ST'															, ; //X3_DESCENG
	'@E 999,999,999.99'														, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ3'																	, ; //X3_ARQUIVO
	'10'																	, ; //X3_ORDEM
	'ZZ3_VCST'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	12																		, ; //X3_TAMANHO
	2																		, ; //X3_DECIMAL
	'VAL ICMS ST'															, ; //X3_TITULO
	'VAL ICMS ST'															, ; //X3_TITSPA
	'VAL ICMS ST'															, ; //X3_TITENG
	'VAL ICMS ST'															, ; //X3_DESCRIC
	'VAL ICMS ST'															, ; //X3_DESCSPA
	'VAL ICMS ST'															, ; //X3_DESCENG
	'@E 999,999,999.99'														, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ3'																	, ; //X3_ARQUIVO
	'11'																	, ; //X3_ORDEM
	'ZZ3_CGCDES'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	14																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'CNPJ DESTINO'															, ; //X3_TITULO
	'CNPJ DESTINO'															, ; //X3_TITSPA
	'CNPJ DESTINO'															, ; //X3_TITENG
	'CNPJ DESTINO'															, ; //X3_DESCRIC
	'CNPJ DESTINO'															, ; //X3_DESCSPA
	'CNPJ DESTINO'															, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ3'																	, ; //X3_ARQUIVO
	'12'																	, ; //X3_ORDEM
	'ZZ3_PARC'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	3																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Num.Parcelas'															, ; //X3_TITULO
	'Num.Parcelas'															, ; //X3_TITSPA
	'Num.Parcelas'															, ; //X3_TITENG
	'Num.Parcelas'															, ; //X3_DESCRIC
	'Num.Parcelas'															, ; //X3_DESCSPA
	'Num.Parcelas'															, ; //X3_DESCENG
	'999'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	//
	// Campos Tabela ZZ4
	//
	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'01'																	, ; //X3_ORDEM
	'ZZ4_FILIAL'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	nSizeFil																, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Filial'																, ; //X3_TITULO
	'Sucursal'																, ; //X3_TITSPA
	'Branch'																, ; //X3_TITENG
	'Filial do Sistema'														, ; //X3_DESCRIC
	'Sucursal'																, ; //X3_DESCSPA
	'Branch of the System'													, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	1																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	''																		, ; //X3_VISUAL
	''																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	'033'																	, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'02'																	, ; //X3_ORDEM
	'ZZ4_CHV'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	44																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Chave Doc'																, ; //X3_TITULO
	'Chave Doc'																, ; //X3_TITSPA
	'Chave Doc'																, ; //X3_TITENG
	'Chave Doc'																, ; //X3_DESCRIC
	'Chave Doc'																, ; //X3_DESCSPA
	'Chave Doc'																, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'03'																	, ; //X3_ORDEM
	'ZZ4_ITEM'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	3																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Item'																	, ; //X3_TITULO
	'Item'																	, ; //X3_TITSPA
	'Item'																	, ; //X3_TITENG
	'Item'																	, ; //X3_DESCRIC
	'Item'																	, ; //X3_DESCSPA
	'Item'																	, ; //X3_DESCENG
	'999'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'04'																	, ; //X3_ORDEM
	'ZZ4_CODPRO'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	20																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Cod. Produto'															, ; //X3_TITULO
	'Cod. Produto'															, ; //X3_TITSPA
	'Cod. Produto'															, ; //X3_TITENG
	'Cod. Produto'															, ; //X3_DESCRIC
	'Cod. Produto'															, ; //X3_DESCSPA
	'Cod. Produto'															, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'05'																	, ; //X3_ORDEM
	'ZZ4_QTD'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	12																		, ; //X3_TAMANHO
	3																		, ; //X3_DECIMAL
	'Quantidade'															, ; //X3_TITULO
	'Quantidade'															, ; //X3_TITSPA
	'Quantidade'															, ; //X3_TITENG
	'Quantidade'															, ; //X3_DESCRIC
	'Quantidade'															, ; //X3_DESCSPA
	'Quantidade'															, ; //X3_DESCENG
	'@E 99,999,999.999'														, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'06'																	, ; //X3_ORDEM
	'ZZ4_VUNIT'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	12																		, ; //X3_TAMANHO
	4																		, ; //X3_DECIMAL
	'Valor Unit'															, ; //X3_TITULO
	'Valor Unit'															, ; //X3_TITSPA
	'Valor Unit'															, ; //X3_TITENG
	'Valor Unit'															, ; //X3_DESCRIC
	'Valor Unit'															, ; //X3_DESCSPA
	'Valor Unit'															, ; //X3_DESCENG
	'@E 9,999,999.9999'														, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'07'																	, ; //X3_ORDEM
	'ZZ4_TOTAL'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	12																		, ; //X3_TAMANHO
	3																		, ; //X3_DECIMAL
	'Total'																	, ; //X3_TITULO
	'Total'																	, ; //X3_TITSPA
	'Total'																	, ; //X3_TITENG
	'Total'																	, ; //X3_DESCRIC
	'Total'																	, ; //X3_DESCSPA
	'Total'																	, ; //X3_DESCENG
	'@E 99,999,999.999'														, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'08'																	, ; //X3_ORDEM
	'ZZ4_DESPRD'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	250																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Desc. Prod'															, ; //X3_TITULO
	'Desc. Prod'															, ; //X3_TITSPA
	'Desc. Prod'															, ; //X3_TITENG
	'Desc. Prod'															, ; //X3_DESCRIC
	'Desc. Prod'															, ; //X3_DESCSPA
	'Desc. Prod'															, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'09'																	, ; //X3_ORDEM
	'ZZ4_NCM'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	9																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'NCM'																	, ; //X3_TITULO
	'NCM'																	, ; //X3_TITSPA
	'NCM'																	, ; //X3_TITENG
	'NCM'																	, ; //X3_DESCRIC
	'NCM'																	, ; //X3_DESCSPA
	'NCM'																	, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'10'																	, ; //X3_ORDEM
	'ZZ4_ICMS'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	12																		, ; //X3_TAMANHO
	3																		, ; //X3_DECIMAL
	'ICMS'																	, ; //X3_TITULO
	'ICMS'																	, ; //X3_TITSPA
	'ICMS'																	, ; //X3_TITENG
	'ICMS'																	, ; //X3_DESCRIC
	'ICMS'																	, ; //X3_DESCSPA
	'ICMS'																	, ; //X3_DESCENG
	'@E 99,999,999.999'														, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'11'																	, ; //X3_ORDEM
	'ZZ4_IPI'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	12																		, ; //X3_TAMANHO
	3																		, ; //X3_DECIMAL
	'IPI'																	, ; //X3_TITULO
	'IPI'																	, ; //X3_TITSPA
	'IPI'																	, ; //X3_TITENG
	'IPI'																	, ; //X3_DESCRIC
	'IPI'																	, ; //X3_DESCSPA
	'IPI'																	, ; //X3_DESCENG
	'@E 99,999,999.999'														, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'12'																	, ; //X3_ORDEM
	'ZZ4_BCST'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	12																		, ; //X3_TAMANHO
	2																		, ; //X3_DECIMAL
	'Base ICMS ST'															, ; //X3_TITULO
	'Base ICMS ST'															, ; //X3_TITSPA
	'Base ICMS ST'															, ; //X3_TITENG
	'Base ICMS ST'															, ; //X3_DESCRIC
	'Base ICMS ST'															, ; //X3_DESCSPA
	'Base ICMS ST'															, ; //X3_DESCENG
	'@E 999,999,999.99'														, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'13'																	, ; //X3_ORDEM
	'ZZ4_VCST'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	12																		, ; //X3_TAMANHO
	2																		, ; //X3_DECIMAL
	'Val ICMS ST'															, ; //X3_TITULO
	'Val ICMS ST'															, ; //X3_TITSPA
	'Val ICMS ST'															, ; //X3_TITENG
	'Val ICMS ST'															, ; //X3_DESCRIC
	'Val ICMS ST'															, ; //X3_DESCSPA
	'Val ICMS ST'															, ; //X3_DESCENG
	'@E 999,999,999.99'														, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'14'																	, ; //X3_ORDEM
	'ZZ4_BICM'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	12																		, ; //X3_TAMANHO
	2																		, ; //X3_DECIMAL
	'Base ICMS'																, ; //X3_TITULO
	'Base ICMS'																, ; //X3_TITSPA
	'Base ICMS'																, ; //X3_TITENG
	'Base ICMS'																, ; //X3_DESCRIC
	'Base ICMS'																, ; //X3_DESCSPA
	'Base ICMS'																, ; //X3_DESCENG
	'@E 999,999,999.99'														, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'15'																	, ; //X3_ORDEM
	'ZZ4_PICM'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	6																		, ; //X3_TAMANHO
	2																		, ; //X3_DECIMAL
	'Aliq. ICMS'															, ; //X3_TITULO
	'Aliq. ICMS'															, ; //X3_TITSPA
	'Aliq. ICMS'															, ; //X3_TITENG
	'Aliq. ICMS'															, ; //X3_DESCRIC
	'Aliq. ICMS'															, ; //X3_DESCSPA
	'Aliq. ICMS'															, ; //X3_DESCENG
	'@E 999.99'																, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'16'																	, ; //X3_ORDEM
	'ZZ4_DESC'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	12																		, ; //X3_TAMANHO
	3																		, ; //X3_DECIMAL
	'Desconto'																, ; //X3_TITULO
	'Desconto'																, ; //X3_TITSPA
	'Desconto'																, ; //X3_TITENG
	'Desconto'																, ; //X3_DESCRIC
	'Desconto'																, ; //X3_DESCSPA
	'Desconto'																, ; //X3_DESCENG
	'@E 99,999,999.999'														, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'17'																	, ; //X3_ORDEM
	'ZZ4_OUTROS'															, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	12																		, ; //X3_TAMANHO
	3																		, ; //X3_DECIMAL
	'Outras Desp'															, ; //X3_TITULO
	'Outras Desp'															, ; //X3_TITSPA
	'Outras Desp'															, ; //X3_TITENG
	'Outras Desp'															, ; //X3_DESCRIC
	'Outras Desp'															, ; //X3_DESCSPA
	'Outras Desp'															, ; //X3_DESCENG
	'@E 99,999,999.999'														, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'18'																	, ; //X3_ORDEM
	'ZZ4_VALSEG'															, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	12																		, ; //X3_TAMANHO
	3																		, ; //X3_DECIMAL
	'Val. Seguro'															, ; //X3_TITULO
	'Val. Seguro'															, ; //X3_TITSPA
	'Val. Seguro'															, ; //X3_TITENG
	'Val. Seguro'															, ; //X3_DESCRIC
	'Val. Seguro'															, ; //X3_DESCSPA
	'Val. Seguro'															, ; //X3_DESCENG
	'@E 99,999,999.999'														, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'19'																	, ; //X3_ORDEM
	'ZZ4_VALFRE'															, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	12																		, ; //X3_TAMANHO
	3																		, ; //X3_DECIMAL
	'Val. Frete'															, ; //X3_TITULO
	'Val. Frete'															, ; //X3_TITSPA
	'Val. Frete'															, ; //X3_TITENG
	'Val. Frete'															, ; //X3_DESCRIC
	'Val. Frete'															, ; //X3_DESCSPA
	'Val. Frete'															, ; //X3_DESCENG
	'@E 99,999,999.999'														, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'20'																	, ; //X3_ORDEM
	'ZZ4_PICMST'															, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	6																		, ; //X3_TAMANHO
	2																		, ; //X3_DECIMAL
	'ICMS ST'																, ; //X3_TITULO
	'ICMS ST'																, ; //X3_TITSPA
	'ICMS ST'																, ; //X3_TITENG
	'ICMS ST'																, ; //X3_DESCRIC
	'ICMS ST'																, ; //X3_DESCSPA
	'ICMS ST'																, ; //X3_DESCENG
	'@E 999.99'																, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'21'																	, ; //X3_ORDEM
	'ZZ4_CFOP'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	4																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'CFOP'																	, ; //X3_TITULO
	'CFOP'																	, ; //X3_TITSPA
	'CFOP'																	, ; //X3_TITENG
	'CFOP'																	, ; //X3_DESCRIC
	'CFOP'																	, ; //X3_DESCSPA
	'CFOP'																	, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'22'																	, ; //X3_ORDEM
	'ZZ4_CST'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	3																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'CST'																	, ; //X3_TITULO
	'CST'																	, ; //X3_TITSPA
	'CST'																	, ; //X3_TITENG
	'CST'																	, ; //X3_DESCRIC
	'CST'																	, ; //X3_DESCSPA
	'CST'																	, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

	aAdd( aSX3, { ;
	'ZZ4'																	, ; //X3_ARQUIVO
	'23'																	, ; //X3_ORDEM
	'ZZ4_PIPI'																, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	14																		, ; //X3_TAMANHO
	4																		, ; //X3_DECIMAL
	'Aliq. IPI'																, ; //X3_TITULO
	'Aliq. IPI'																, ; //X3_TITSPA
	'Aliq. IPI'																, ; //X3_TITENG
	'Aliq. IPI'																, ; //X3_DESCRIC
	'Aliq. IPI'																, ; //X3_DESCSPA
	'Aliq. IPI'																, ; //X3_DESCENG
	'@E 999,999,999.9999'													, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME


	//
	// Atualizando dicionário
	//
	nPosArq := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ARQUIVO" } )
	nPosOrd := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ORDEM"   } )
	nPosCpo := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_CAMPO"   } )
	nPosTam := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_TAMANHO" } )
	nPosSXG := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_GRPSXG"  } )
	nPosVld := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_VALID"   } )

	aSort( aSX3,,, { |x,y| x[nPosArq]+x[nPosOrd]+x[nPosCpo] < y[nPosArq]+y[nPosOrd]+y[nPosCpo] } )


	dbSelectArea( "SX3" )
	dbSetOrder( 2 )
	cAliasAtu := ""

	For nI := 1 To Len( aSX3 )

		//
		// Verifica se o campo faz parte de um grupo e ajusta tamanho
		//
		/*
		If !Empty( aSX3[nI][nPosSXG] )
		SXG->( dbSetOrder( 1 ) )
		If SXG->( MSSeek( aSX3[nI][nPosSXG] ) )
		If aSX3[nI][nPosTam] <> SXG->XG_SIZE
		aSX3[nI][nPosTam] := SXG->XG_SIZE
		EndIf
		EndIf
		EndIf
		*/

		SX3->( dbSetOrder( 2 ) )

		If !( aSX3[nI][nPosArq] $ cAlias )
			cAlias += aSX3[nI][nPosArq] + "/"
			//aAdd( aArqUpd, aSX3[nI][nPosArq] )
		EndIf

		If !SX3->( dbSeek( PadR( aSX3[nI][nPosCpo], nTamSeek ) ) )

			//
			// Busca ultima ocorrencia do alias
			//
			If ( aSX3[nI][nPosArq] <> cAliasAtu )
				cSeqAtu   := "00"
				cAliasAtu := aSX3[nI][nPosArq]

				dbSetOrder( 1 )
				SX3->( dbSeek( cAliasAtu + "ZZ", .T. ) )
				dbSkip( -1 )

				If ( SX3->X3_ARQUIVO == cAliasAtu )
					cSeqAtu := SX3->X3_ORDEM
				EndIf

				nSeqAtu := Val( RetAsc( cSeqAtu, 3, .F. ) )
			EndIf

			nSeqAtu++
			cSeqAtu := RetAsc( Str( nSeqAtu ), 2, .T. )

			RecLock( "SX3", .T. )
			For nJ := 1 To Len( aSX3[nI] )
				If     nJ == nPosOrd  // Ordem
					SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), cSeqAtu ) )

				ElseIf aEstrut[nJ][2] > 0
					SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ] ) )

				EndIf
			Next nJ

			dbCommit()
			MsUnLock()

			AutoGrLog( "Criado campo " + aSX3[nI][nPosCpo] )

		EndIf

	Next nI

	AutoGrLog( CRLF + "Final da Atualização" + " SX3" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSIX
Função de processamento da gravação do SIX - Indices

@author TOTVS Protheus
@since  06/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
User Function FSAtuSIX()
	Local aEstrut   := {}
	Local aSIX      := {}
	Local lAlt      := .F.
	Local lDelInd   := .F.
	Local nI        := 0
	Local nJ        := 0

	AutoGrLog( "Ínicio da Atualização" + " SIX" + CRLF )

	aEstrut := { "INDICE" , "ORDEM" , "CHAVE", "DESCRICAO", "DESCSPA"  , ;
	"DESCENG", "PROPRI", "F3"   , "NICKNAME" , "SHOWPESQ" }

	//
	// Tabela ZZ3
	//
	aAdd( aSIX, { ;
	'ZZ3'																	, ; //INDICE
	'1'																		, ; //ORDEM
	'ZZ3_FILIAL+ZZ3_CHV+ZZ3_DOC+ZZ3_SERIE'									, ; //CHAVE
	'Chave Doc+Numero Doc+Serie'											, ; //DESCRICAO
	'Chave Doc+Numero Doc+Serie'											, ; //DESCSPA
	'Chave Doc+Numero Doc+Serie'											, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'N'																		} ) //SHOWPESQ

	//
	// Tabela ZZ4
	//
	aAdd( aSIX, { ;
	'ZZ4'																	, ; //INDICE
	'1'																		, ; //ORDEM
	'ZZ4_FILIAL+ZZ4_CHV+ZZ4_ITEM+ZZ4_CODPRO'								, ; //CHAVE
	'Chave Doc+Item+Cod. Produto'											, ; //DESCRICAO
	'Chave Doc+Item+Cod. Produto'											, ; //DESCSPA
	'Chave Doc+Item+Cod. Produto'											, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'N'																		} ) //SHOWPESQ

	//
	// Atualizando dicionário
	//

	dbSelectArea( "SIX" )
	SIX->( dbSetOrder( 1 ) )

	For nI := 1 To Len( aSIX )

		lAlt    := .F.
		lDelInd := .F.

		If !SIX->( dbSeek( aSIX[nI][1] + aSIX[nI][2] ) )
			AutoGrLog( "Índice criado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
		Else
			lAlt := .T.
			//aAdd( aArqUpd, aSIX[nI][1] )
			If !StrTran( Upper( AllTrim( CHAVE )       ), " ", "" ) == ;
			StrTran( Upper( AllTrim( aSIX[nI][3] ) ), " ", "" )
				AutoGrLog( "Chave do índice alterado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
				lDelInd := .T. // Se for alteração precisa apagar o indice do banco
			EndIf
		EndIf

		RecLock( "SIX", !lAlt )
		For nJ := 1 To Len( aSIX[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				FieldPut( FieldPos( aEstrut[nJ] ), aSIX[nI][nJ] )
			EndIf
		Next nJ
		MsUnLock()

		dbCommit()

		If lDelInd
			TcInternal( 60, RetSqlName( aSIX[nI][1] ) + "|" + RetSqlName( aSIX[nI][1] ) + aSIX[nI][2] )
		EndIf


	Next nI

	AutoGrLog( CRLF + "Final da Atualização" + " SIX" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL

