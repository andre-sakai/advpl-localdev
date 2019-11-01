#Include "Protheus.ch"
#Include "TopConn.ch"

/*---------------------------------------------------------------------------
* Arquivo principal com todas as integrações e EDI do cliente              *
*                                   Midea / Springer Carrier               *
---------------------------------------------------------------------------*/

//--------------------------------------------------------------------------//
// Programa: TECMID01()|	Autor: Gustavo Schumann	|    	Data: 03/05/2019//
//--------------------------------------------------------------------------//
// Descrição: EDI de espelho nota fiscal e complemento do XML de entrada    //
//            modelo 3.2 cliente Midea (arquivos NFAxxxxxx.TXT)				//
//--------------------------------------------------------------------------//

User Function TECMID01(mvArquivo, _aCampos)
	Local _lRet		:= .T.
	Local _cBkp
	Private _aXML	:= {}

	// efetua a leitura do arquivo passado por parametro
	If !ReadFile(mvArquivo)
		Help(,, 'TECMID01.F01.001',, "Arquivo EDI não encontrado.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"O arquivo EDI correspondente a nota fiscal não foi localizado ou é inválido " + CRLF + "(" + AllTrim(mvArquivo) + " )"}) 

		_lRet := .F.
	EndIf

	// valida se os itens enviados pelo EDI 3.2 estão batendo com a conferência Tecadi
	If _lRet
		If !ValItens(_aCampos)
			_lRet := .F.
		EndIf
	EndIf

	If (_lRet)
		U_FtGeraLog(cFilAnt, "LOG", "INTEGRACAO-EDI", "Arquivo EDI 3.2 recebimento Midea integrado com sucesso! [TECMID01] "+mvArquivo, "003", "")

		// mover arquivo importado para basta BKP
		_cBkp := StrTran(mvArquivo, "\nf_transferencia\",  "\nf_transferencia\bkp\")  // altera caminho para pasta bkp
		FRename( mvArquivo, _cBkp )
	Else
		U_FtGeraLog(cFilAnt, "LOG", "INTEGRACAO-EDI", "Falha na integracao do arquivo EDI 3.2 recebimento Midea! [TECMID01] "+mvArquivo, "003", "")
	EndIf

Return(_lRet)
//-------------------------------------------------------------------------------------------------
Static Function ReadFile(mvArquivo)
	Local _lRet := .T.
	Private oFile

	_aXML := {}

	oFile := FWFileReader():New(mvArquivo)

	If (oFile:Open())
		_aXML := oFile:getAllLines()
		oFile:Close()

		If (Len(_aXML) == 0)
			alert("Arquivo complementar " + mvArquivo + " em branco ou falha na leitura. Abortando!")
			_lRet := .F.
		EndIf
	Else
		alert("Arquivo complementar " + mvArquivo + " não encontrado. Abortando!")
		_lRet := .F.
	EndIf

Return(_lRet)
//-------------------------------------------------------------------------------------------------
Static Function ValItens(_aCampos)
	Local _lRet			:= .T.
	Local _nNumTmp		:= 0
	Local _nNumZ07		:= 0
	Local _aAux			:= {}
	Local _aAux2		:= {}
	Local _aPcCamp		:= {}
	Local _cFilial		:= xFilial("Z07")
	Local _cProd		:= ""
	Local _cLog         := ""
	Local _nQuantNf     := 0   // quantidade de produtos na nota fiscal

	// elimina a última posição do array, caso este esteja com o caractere de final de arquivo
	If Len(_aXML[Len(_aXML)]) == 1
		ASize(_aXML,Len(_aXML)-1)
	EndIf

	aAdd(_aPcCamp,{"Z07FILIAL"  ,"C", TamSx3("Z07_FILIAL")[1] ,0})
	aAdd(_aPcCamp,{"Z07PRODUT"  ,"C", TamSx3("Z07_PRODUT")[1] ,0})
	aAdd(_aPcCamp,{"Z07NUMSER"  ,"C", TamSx3("Z07_NUMSER")[1] ,0})
	aAdd(_aPcCamp,{"Z07DTSERI"  ,"D", TamSx3("Z07_DTSERI")[1] ,0})

	If (Select(_cTabPc)<>0)
		dbSelectArea(_cTabPc)
		dbCloseArea()
	EndIf

	// tabela temporária com os dados do EDI para validação
	_cTrBArqPc := FWTemporaryTable():New( _cTabPc )
	_cTrBArqPc:SetFields( _aPcCamp )
	_cTrBArqPc:Create()


	// valida cabeçalho do EDI (NF + SERIE)
	_aAux := StrTokArr2(_aXML[1],"#",.T.)
	If ( _aAux[4] != _aCampos[NPNDOCNF][2]) .OR. (_aAux[5] != AllTrim(_aCampos[NPSERINF][2]) )
		Help(,, 'TECMID01.ValItens.005',, "EDI incorreto!", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"O cabeçalho do EDI (Nota + série) não corresponde com a nota fiscal."}) 
		_lRet := .F.

	EndIf

	// preenche tabela temporária conforme array
	If (_lRet)
		// quebra a linha separada por cerquilha para um array multidimensional
		_aAux := {}
		For _nX := 2 To Len(_aXML)
			AADD(_aAux,StrTokArr2(_aXML[_nX],"#",.T.))
		Next _nX

		// separo em um array auxiliar os produtos iguais para efetuar a consulta na SB1
		// para pegar o código do produto correto, evitando consultas redundantes 
		_aAux2 := {}
		For _nX := 1 To Len(_aAux)
			If _cProd <> _aAux[_nX][3]
				_cProd := _aAux[_nX][3]
				AADD(_aAux2,_cProd)
			EndIf
		Next _nX

		// percorre o array auxiliar e popula com o codigo do produto tecadi na posição 9
		_cProd := ""
		For _nX := 1 To Len(_aAux2)
			_cProd := sfCodPro(_aAux2[_nX]) // funcão para pegar o codigo de produto Tecadi
			For _nZ := 1 To Len(_aAux)
				If _aAux[_nZ][3] == _aAux2[_nX]
					AADD(_aAux[_nZ],_cProd)
				EndIf
			Next _nZ
		Next _nX

		// grava na tabela temporária
		BEGIN TRANSACTION
			For _nX := 1 To Len(_aAux)

				(_cTabPc)->(dbSelectArea(_cTabPc))
				(_cTabPc)->(RecLock(_cTabPc,.t.))
				(_cTabPc)->Z07FILIAL	:= _cFilial
				(_cTabPc)->Z07PRODUT	:= _aAux[_nX][9]
				(_cTabPc)->Z07NUMSER	:= _aAux[_nX][7]
				(_cTabPc)->Z07DTSERI	:= GetDtoDate(_aAux[_nX][8])
				(_cTabPc)->(MsUnLock())

			Next _nX
		END TRANSACTION
	EndIf

	// valida divergências entre EDI e conferência
	If (_lRet)
		If Select("tZ07TMP") > 0
			DBSelectArea("tZ07TMP")
			tZ07TMP->(DBCloseArea())
		EndIf

		// busca a tabela temporária criada no SQL
		// e valida se possui divergências com a conferência
		// neste caso, valida se o arquivo EDI possui mais itens que o conferido
		cQuery := " SELECT * "
		cQuery += " FROM " + _cTrBArqPc:GetRealName() + " as TMP "
		cQuery += " WHERE TMP.D_E_L_E_T_ = '' "
		cQuery += " AND NOT EXISTS ( SELECT * "
		cQuery += " 				FROM " + RetSQLTab("Z07") + " (NOLOCK) "
		cQuery += " 				where " + RetSqlCond("Z07")
		cQuery += " 				and Z07_PRODUT = TMP.Z07PRODUT "
		cQuery += " 				and Z07_NUMSER = TMP.Z07NUMSER "
		cQuery += " 				and Z07_NUMOS  = '" + _cNumos + "') "

		// log para debug
		MemoWrit("c:\query\TECMID01_ValItens_01.txt", cQuery)

		TCQuery cQuery NEW ALIAS "tZ07TMP"

		DBSelectArea("tZ07TMP")
		tZ07TMP->(DBGoTop())

		if ( !tZ07TMP->(EOF()) )
			Help(,, 'TECMID01.ValItens.001',, "Existem divergências entre os itens do EDI e da conferência Tecadi!", 1, 0,;
			NIL, NIL, NIL, NIL, NIL,;
			{"Os arquivos de EDI e conferência devem ser iguais. Valide a conferência com o supervisor ou o arquivo EDI com o cliente."}) 
			_lRet := .F.
		EndIf

		// gera log em tela
		_cLog := "Informações do arquivo EDI que não constam na conferência:" + CRLF + CRLF

		While ( !tZ07TMP->(EOF()) )
			_cLog += AllTrim(tZ07TMP->Z07PRODUT) + " -(" + tZ07TMP->Z07NUMSER + ")" + CRLF 
			tZ07TMP->(DBSkip())
		EndDo

		HS_MsgInf(_cLog , "TECMID01.ValItens.001", "Log de Importação" )

		tZ07TMP->(DBCloseArea())
	EndIf

	// valida a quantidade de itens do EDI X conferência X nota fiscal
	If (_lRet)
		cQuery := " SELECT COUNT(*) NUM "
		cQuery += " FROM " + _cTrBArqPc:GetRealName() + " AS TMP "
		cQuery += " WHERE TMP.D_E_L_E_T_ = '' "
		// log para debug
		MemoWrit("c:\query\TECMID01_ValItens_02.txt",cQuery)
		_nNumTmp := U_FTQuery(cQuery)

		// obtem quantidade de itens da conferencia
		cQuery := " SELECT COUNT(*) NUM "
		cQuery += " FROM " + RetSQLTab("Z07") + " (nolock) "
		cQuery += " WHERE " + RetSqlCond("Z07") 
		cQuery += " AND Z07_NUMOS  = '" + _cNumos + "' "
		cQuery += " AND Z07_SEQOS  = '001' "
		//cQuery += " AND Z07_STATUS = 'D' "
		// log para debug
		MemoWrit("c:\query\TECMID01_ValItens_03.txt",cQuery)
		_nNumZ07 := U_FTQuery(cQuery)

		// obtem quantidade de itens da nota fiscal (arquivo temporario em tela/browse)
		cQuery := "SELECT IsNull(SUM(D1_QUANT),0) FROM " + _cNomArq:GetRealName() + " AS NOTAFISCAL WHERE NOTAFISCAL.D_E_L_E_T_ = '' "
		// log para debug
		MemoWrit("c:\query\TECMID01_ValItens_04.txt",cQuery)
		_nQuantNf := U_FTQuery(cQuery)

		// validação quantitativa 
		If (_nNumTmp > _nNumZ07)   // EDI com mais registros que conferencia
			Help(,, 'TECMID01.ValItens.002',, "Falha na validação do EDI.", 1, 0,;
			NIL, NIL, NIL, NIL, NIL,;
			{"O arquivo EDI contêm MAIS registros do que a conferência Tecadi, e deveriam ser iguais. Valide a conferência com o supervisor ou o arquivo EDI com o cliente."}) 
			_lRet := .F.
		ElseIf (_nNumZ07 > _nNumTmp) // EDI com MENOS registros que conferencia
			Help(,, 'TECMID01.ValItens.003',, "Falha na validação do EDI.", 1, 0,;
			NIL, NIL, NIL, NIL, NIL,;
			{"O arquivo EDI contêm MENOS registros do que a conferência Tecadi, e deveriam ser iguais. Valide a conferência com o supervisor ou o arquivo EDI com o cliente."}) 
			_lRet := .F.
		ElseIf (_nQuantNf != _nNumZ07) .OR. (_nQuantNf != _nNumTmp)
			Help(,, 'TECMID01.ValItens.004',, "Falha na validação quantitativa da nota fiscal.", 1, 0,;
			NIL, NIL, NIL, NIL, NIL,;
			{"O arquivo EDI ou a conferência possuem quantidade diferente da nota fiscal importada. Valide a conferência com o supervisor ou a nota fiscal com o cliente."}) 
			_lRet := .F.
		EndIf

	EndIf

	//_cTrBArqPc:Delete()

Return(_lRet)

// função auxiliar que retorna o código do produto (B1_COD) baseado no código do cliente (B1_CODCLI) 
Static Function sfCodPro(mvProduto)
	local _cRet := ""
	local _cQry := ""

	_cQry := "SELECT B1_COD FROM " + RetSqlTab("SB1") + " (NOLOCK) WHERE " + RetSqlCond("SB1") + " AND B1_CODCLI = '" + mvProduto + "'"

Return ( U_FTQuery(_cQry) )


//--------------------------------------------------------------------------//
// Programa: TECMID03()	|	Autor: Gustavo Schumann	|	Data: 11/06/2019	//
//--------------------------------------------------------------------------//
// Descrição: Rotina que efetua a leitura do EDI 3.5 Midea e complementa	//
//			  campos complementares no pedido de venda SC5.					//
//--------------------------------------------------------------------------//

User Function TECMID03(mvArquivo)
	Local _lRet		:= .T.
	Private _aXML	:= {}

	// efetua a leitura do arquivo passado por parametro
	If !sfRead03(mvArquivo)
		FWLogMsg('ERROR',, 'SIGAFAT', FunName(), '', '01',"Arquivo EDI 3.5 não disponível: " + mvArquivo , 0, 0, {})
		_lRet := .F.
	EndIf

	// efetua a gravação das informações complementares na SC5
	If _lRet
		If !GravaSC5(mvArquivo)
			_lRet := .F.
		EndIf
	EndIf

	If _lRet
		U_FtGeraLog(xFilial("SF1"), "", "", "Arquivo EDI 3.5 NF-e Midea integrado com sucesso! [TECMID03] "+mvArquivo, "003", "")
	Else
		U_FtGeraLog(xFilial("SF1"), "", "", "Falha na integracao do arquivo EDI 3.5 NF-e Midea! [TECMID03] "+mvArquivo, "003", "")
	EndIf

Return(_lRet)
//-------------------------------------------------------------------------------------------------
Static Function sfRead03(mvArquivo)
	Local _lRet := .T.
	Local cMemo := ""

	_aXML := {}

	cMemo := MemoRead(mvArquivo)

	If EMPTY(cMemo)
		_lRet := .F.
	Else
		_aXML := StrTokArr(cMemo, Chr(13) + Chr(10))
	EndIf

Return(_lRet)
//-------------------------------------------------------------------------------------------------
Static Function GravaSC5(mvArquivo)
	Local _lRet		:= .T.
	Local _nX		:= 1
	Local _aTmp		:= {}
	Local _aAux		:= {}

	// quebra as linhas do array em um array multidimensional na cerquilha
	_aCabec  := StrTokArr2(_aXML[1],"#",.T.)
	_aPedido := StrTokArr2(_aXML[2],"#",.T.)

	DBSelectArea("SC5")
	SC5->(dbSetOrder(11))  // C5_FILIAL, C5_ZPEDCLI, R_E_C_N_O_, D_E_L_E_T_

	If SC5->( DBSeek(xFilial("SC5") + _aPedido[7]) )
		RecLock("SC5",.F.)
		SC5->C5_ZDOCCLI := _aCabec[5] + "/" + _aCabec[6]
		SC5->C5_ZNFVVLR := Val( _aCabec[11] )
		SC5->C5_ZCHVNFV := _aCabec[15]
		SC5->(MsUnlock())

		// mover arquivo importado para basta BKP
		_cBkp := StrTran(mvArquivo, "\nf_venda\",  "\nf_venda\bkp\")  // altera caminho para pasta bkp
		_cBkp := StrTran(_cBkp , ".txt", "_" + DtoS( Date() ) + "_" + StrTran( Time(), ":" ) + ".txt")
		FRename( mvArquivo, _cBkp )
	Else
		FWLogMsg('ERROR',, 'SIGAFAT', FunName(), '', '01',"Pedido do cliente não localizado, EDI 3.5 Midea, C5_ZPEDCLI = " + _aPedido[7], 0, 0, {})
		_lRet := .F.
	EndIf

Return(_lRet)


//---------------------------

//--------------------------------------------------------------------------//
// Programa: TECMID04()	|	Autor: Junior Conte	 |   	Data: 11/06/2019	//
//--------------------------------------------------------------------------//
// Descrição: Importa produtos e cadastra conforme layout de EDI         	//
//			  3.1 do cliente Midea                           				//
//--------------------------------------------------------------------------//

User Function TECMID04()

	local _lRet := .F.
	Private _cArquivo := cGetFile( 'PRODUTOS.txt|PRODUTOS.txt' , 'EDI Cadastro produtos Midea', 1, '\EDI\MIDEA\produto\', .T.,GETF_NOCHANGEDIR,.T., .T. )

	// valida se arquivo foi informado
	If Empty(_cArquivo)
		Help(,, 'TECMID04.001',, "Falha na validação do EDI.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"Arquivo não informado ou inválido."}) 
	Else
		oProc := MsNewProcess():New({|_lRet| _lRet := sfImportar(_cArquivo) },"","",.F.)	
		oProc:Activate()
	Endif

	If (_lRet)
		U_FtGeraLog(xFilial("SB1"), "", "", "Arquivo EDI 3.1 - importação/cadastro de produtos foi utilizado! [TECMID04] ", "003", "")
	Else
		U_FtGeraLog(xFilial("SB1"), "", "", "Falha na integração do arquivo EDI 3.1 importação/cadastro de produtos [TECMID04] ", "003", "")
	EndIf

Return

// funcao que processa a importacao dos dados
Static Function sfImportar(cArquivo)

	Local _cLog := ""
	Local _cBkp := ""

	//Abre o Arquivo para Importar os dados
	FT_FUse( cArquivo )
	FT_FGoTop()

	//Cria Arquivo de Log
	_cLog := StrTran(cArquivo, "\produto\",  "\produto\log\")  // coloca caminho da pasta LOG
	_cLog := StrTran(_cLog , ".txt", "_" + DtoS( Date() ) + "_" + StrTran( Time(), ":" ) + ".log")

	// se não conseguir criar o arquivo de log, aborta
	If ( ( nHdl := fCreate( _cLog, Nil, Nil, .F. ) ) == -1 )
		Return ( .F. )
	EndIf

	//Define quantidade para mostrar no processamento (linhas do arquivo)
	oProc:SetRegua1( FT_FLastRec() )

	// percorre o array, cadastrando cada produto
	While !FT_FEof()
		//Incrementa Regua 
		oProc:IncRegua1()

		//Le a linha posicionado no arquivo TXT
		cLinha	:= FT_FReadln()
		aLinha	:= Separa( cLinha , "#" )

		// importa um produto baseado na linha lida
		sfImpDados()

		// proxima linha
		FT_FSkip()
	EndDo

	//Fecha handler do Arquivo de LOG
	fClose(nHdl)
	// fecha o arquivo de dados aberto
	FT_FUse()

	// mover arquivo importado para basta BKP
	_cBkp := StrTran(cArquivo, "\produto\",  "\produto\bkp\")  // altera caminho para pasta bkp
	_cBkp := StrTran(_cBkp , ".txt", "_" + DtoS( Date() ) + "_" + StrTran( Time(), ":" ) + ".txt")
	FRename( cArquivo, _cBkp )


Return ( .F. )

// funcao responsavel pela importação dos dados do arquivo e execução do cadastro automático
// linha exemplo
// 01#04222931000195#38AFCB09F5#UNIDADE CONDENSADORA 09K FR#P##0#0#0#25,200#22,800#BB#014#Z003

Static Function sfImpDados()
	Local aDadosPro	:= {}    	

	Local cCgc    := aLinha[2]
	Local cCodigo := aLinha[3]
	Local cDesc   := StrTran( aLinha[4], '"')
	Local cNCM    := SubStr( StrTran( aLinha[15], ".") , 1,8)
	Local cUM     := AllTrim(aLinha[16])

	//	Local nPesliq   := 0 // aLinha[11]  -- comentado pois as informações que eles mandam são incorretas!
	//	Local nPesbru   := 0 // aLinha[10]  -- comentado pois as informações que eles mandam são incorretas!

	// dados complementares do produto
	Local aComplem   := {}

	// controle da tela de complemento de produto (se confirmou)
	local _lOK := .F.

	//Cria Variavel de Quebra de Linha
	local cEOL    := "CHR(13)+CHR(10)"
	cEOL	:= &cEOL

	// valida se é uma linha de produto
	If (aLinha[1] != "01")
		cLinha += " | Identificador da linha inválido " + cEol
		fWrite(nHdl,cLinha,Len(cLinha))
		Return
	EndIf

	// se não encontrou o produto no arquivo
	If Empty(cCodigo)
		cLinha += " | Código do produto não informado " + cCodigo + cEol
		fWrite(nHdl,cLinha,Len(cLinha))
		Return
	EndIf

	// valida se CNPJ do cliente MIDEA é válido
	If (cCgc != "10948651004230")
		// Cliente não existe
		cLinha := FT_FReadln() + " | CLIENTE INVALIDO CNPJ " + cCgc + cEol
		fWrite(nHdl,cLinha,Len(cLinha))
		Return	
	Else
		dbSelectArea("SA1")
		SA1->(dbSetOrder(3))

		If !(SA1->( dbSeek(xFilial("SA1") + cCgc )))  // não achou o cliente
			cLinha := FT_FReadln() + " | Não foi possível localizar o cliente na base de dados. Abortado. " + cCgc + cEol
			fWrite(nHdl,cLinha,Len(cLinha))
			Return	
		EndIf
	EndIf

	// pesquisa se produto ja existe
	dbSelectArea("SB1")
	SB1->(dbSetOrder(1)) //Por CODIGO
	If SB1->( dbSeek(xFilial("SB1") + SA1->A1_SIGLA + cCodigo ))
		// produto ja Existe
		cLinha := FT_FReadln() +" | PRODUTO JA CADASTRADO COM O CODIGO " +  SA1->A1_SIGLA + cCodigo + cEol
		fWrite(nHdl,cLinha,Len(cLinha))
		Return
	EndIf 

	// pesquisa se NCM já possui cadastro
	dbSelectArea("SYD")
	SYD->(dbSetOrder(1)) // YD_FILIAL, YD_TEC, YD_EX_NCM, YD_EX_NBM, YD_DESTAQU, R_E_C_N_O_, D_E_L_E_T_
	If !(SYD->( dbSeek(xFilial("SYD") + cNCM )))
		// NCM não existe
		cLinha := FT_FReadln() +" | NCM inválido ou não cadastrado " +  cNCM + cEol
		fWrite(nHdl,cLinha,Len(cLinha))
		Return
	EndIf 

	aComplem   := fComplProd( cDesc, cCodigo, cNCM, SA1->A1_SIGLA, cUM,  @_lOK  )

	//{_cTipo,  _cUnidMed,  _cSegUnid,  _nConver, Left(_cTipoConv,1),  _cLocPad, Left(_cLocaliz,1),   _cOrigem, _nVlrUnit,  _cCodNCM,   _cGrpEsto, AllTrim(_cCodBar),  AllTrim(_cLotePrd)  }
	//      1         2           3            4             5              6                7             8           9          10          11               12                 13

	// se confirmou a tela
	If (_lOk)
		aAdd( aDadosPro , {"B1_ZTIPPRO" , "A" 		  				  ,NIL} )  // produto do tipo ARMAZEM
		aAdd( aDadosPro , {"B1_GRUPO"   , SA1->A1_SIGLA				  ,NIL} ) 
		aAdd( aDadosPro , {"B1_CODCLI"  ,  cCodigo                    ,NIL} )
		aAdd( aDadosPro , {"B1_COD"     , SA1->A1_SIGLA + cCodigo     ,NIL} )
		aAdd( aDadosPro , {"B1_DESC"    , cDesc      				  ,NIL} )	
		aAdd( aDadosPro , {"B1_TIPO"    , aComplem[1]   			  ,NIL} )	
		aAdd( aDadosPro , {"B1_UM"      , aComplem[2]     			  ,NIL} )
		aAdd( aDadosPro , {"B1_SEGUM"   , aComplem[3]     			  ,NIL} )
		aAdd( aDadosPro , {"B1_CONV"    , aComplem[4]      			  ,NIL} )
		aAdd( aDadosPro , {"B1_TIPCONV" , aComplem[5]      			  ,NIL} )
		aAdd( aDadosPro , {"B1_LOCALIZ" , aComplem[7]	              ,NIL} )
		aAdd( aDadosPro , {"B1_LOCPAD"  , aComplem[6]			 	  ,NIL} )
		aAdd( aDadosPro , {"B1_POSIPI"  , aComplem[10] 				  ,NIL} )
		aAdd( aDadosPro , {"B1_ORIGEM"  , aComplem[8] 				  ,NIL} )
		aAdd( aDadosPro , {"B1_CODBAR"  , aComplem[12]		          ,NIL} )    
		aAdd( aDadosPro , {"B1_ZGRPEST" , aComplem[11]     		      ,NIL} )
		aAdd( aDadosPro , {"B1_PESO"    , 0				     		  ,NIL} ) 
		aAdd( aDadosPro , {"B1_PESBRU"  , 0	     					  ,NIL} )
		aAdd( aDadosPro , {"B1_GARANT"  , "2"      				      ,NIL} )           
		aAdd( aDadosPro , {"B1_ZNUMSER" , "S"      				      ,NIL} )           
		aAdd( aDadosPro , {"B1_ZINFQTD" , "N"      				      ,NIL} )           

		//Executa a Rotina Automatica de cadastro de produtos
		lMsErroAuto := .F.
		MSExecAuto({|x,y| MATA010(x,y)}, aDadosPro, 3) //Inclusao

		// se deu erro
		If (lMsErroAuto)
			MostraErro()
			cLinha := FT_FReadln() + " | ERRO NA TENTATIVA DE CADASTRO DO PRODUTO " + cCodigo + cEol
			//	cLinha += " | " + sfAchaErro() +cEol
			fWrite(nHdl, cLinha, Len(cLinha) )
			FWLogMsg('ERROR',, 'SIGAWMS', FunName(), '', '01',"Erro no cadastro de produto - EDI 3.1 Midea", 0, 0, {})
		Else
			cLinha := FT_FReadln() + " | Produto cadastrado com sucesso " + cCodigo + cEol
			fWrite(nHdl, cLinha, Len(cLinha) )
		EndIf
	Else
		cLinha := FT_FReadln() + " | Produto não importado - cancelado pelo usuário " + cCodigo + cEol
		fWrite(nHdl,cLinha,Len(cLinha))
	EndIf

Return 

// ** funcao para definir o complemento do produto
Static Function fComplProd( cDesc, cCodigo, cNCM, cSigla, cUM, mvOK )
	// controle da confirmacao na tela
	Local _lRet := .f.
	// controle da linha dos campos
	Local _nPosCmp	:= 10
	// unidade de medida
	Private _cUnidMed	:= cUM
	// descricao
	Private _cDescri	:= cDesc
	// tipo
	Private _cTipo		:= "ME"
	// segunda unidade de medida
	Private _cSegUnid	:= "  "
	// local padrao
	Private _cLocPad	:= U_FtWmsParam("WMS_ARMAZEM_POR_CLIENTE", "C", "A1", .F., Nil, SA1->A1_COD, SA1->A1_LOJA, '', Nil)
	// controla endereco
	Private _cLocaliz	:= "N"
	// origem
	Private _cOrigem	:= '1'
	// posicao do IPI / NCM
	Private _cCodNCM    := cNCM
	// conversor da seg unidade
	Private _nConver    := 0
	// grupo de estoque
	Private _cGrpEsto   := PADR("", TAMSX3("B1_ZGRPEST")[1] )
	// código EAN
	Private _cCodBar    := PADR("", TAMSX3("B1_CODBAR")[1] )

	// código do produto
	Private _cCodProt	:= cSigla + cCodigo 

	// produto usa segunda unidade de medida?
	Private  _lUsoSegUM  := U_FtWmsParam("WMS_PRODUTO_USA_SEGUNDA_UNIDADE_MEDIDA", "L", .F. , .F., Nil, SA1->A1_COD, SA1->A1_LOJA, '', Nil)

	Private  _cTipoConv := CriaVar("B1_TIPCONV")   

	// valida se o WMS esta ativo por cliente
	private _lWmsAtivo := .f.


	// tela para detalhar os dados do produto
	_oDlgDetProd := MsDialog():New(000,000,490,400,"Detalhes e Complemento do Produto",,,.F.,,,,,,.T.,,,.T. )

	// cabecalho
	_oPnlTopDet := TPanel():New(1,1,,_oDlgDetProd,,.T.,.F.,,,1,20,,)
	_oPnlTopDet:Align := CONTROL_ALIGN_TOP

	// botoes de controle de operacao
	_oBtnDetConf := TButton():New(005,005,"Confirmar",_oPnlTopDet,{|| mvOK := .T. ,_oDlgDetProd:End()},060,010,,,,.T.,,"",,,,.F. )
	_oBtnDetSair := TButton():New(005,070,"Fechar",_oPnlTopDet,{||_oDlgDetProd:End()},060,010,,,,.T.,,"",,,,.F. )

	// componente scroll
	oScrollBox := TScrollBox():New(_oDlgDetProd,000,000,400,400,.T.,.T.,.T. )
	oScrollBox:Align := CONTROL_ALIGN_ALLCLIENT

	// grupo e cod cliente
	_oSayGrupo := TSay():New(_nPosCmp,005,{||"Grupo/Sigla"},oScrollBox,,,,,,.T.,CLR_HBLUE,,040,30)
	_oGetGrupo := TGet():New(_nPosCmp-2,050,bSetGet( cSigla ),oScrollBox,040,10,"@!",,,,,,,.T.,,,{||.F.})
	_oSayCodCli := TSay():New(_nPosCmp,100,{||"Cod. Cliente"},oScrollBox,,,,,,.T.,CLR_HBLUE,,040,30)
	_oGetCodCli := TGet():New(_nPosCmp-2,135,bSetGet( cCodigo ),oScrollBox,060,10,"@!",,,,,,,.T.,,,{||.F.})
	_nPosCmp += 15

	// codigo do produto
	_oSayCodProd := TSay():New(_nPosCmp,005,{||"Cód. Produto"},oScrollBox,,,,,,.T.,CLR_HBLUE,,040,30)
	_oGetCodProd := TGet():New(_nPosCmp-2,050,bSetGet(_cCodProt),oScrollBox,145,10,"@!",,,,,,,.T.,,,{||.F.})
	_nPosCmp += 15

	// descricao
	_oSayDescri := TSay():New(_nPosCmp,005,{||"Descrição"},oScrollBox,,,,,,.T.,CLR_HBLUE,,040,30)
	_oGetDescri := TGet():New(_nPosCmp-2,050,bSetGet(_cDescri),oScrollBox,145,10,"@!",,,,,,,.T.,,,{||Iif(_lWmsAtivo,.T.,.F.)},.F.,.F.,,.F.,.F.,"","_cDescri",,)
	_nPosCmp += 15

	// tipo / UM
	_oSayTipo := TSay():New(_nPosCmp,005,{||"Tipo"},oScrollBox,,,,,,.T.,CLR_HBLUE,,040,30)
	_oGetTipo := TGet():New(_nPosCmp-2,050,bSetGet(_cTipo),oScrollBox,040,10,"@!",{||Vazio().or.ExistCpo("SX5","02"+_cTipo)},,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"02","_cTipo",,)
	_oSayUM := TSay():New(_nPosCmp,100,{||"U.M."},oScrollBox,,,,,,.T.,CLR_HBLUE,,030,30)
	_oGetUM := TGet():New(_nPosCmp-2,135,bSetGet(_cUnidMed),oScrollBox,060,10,"@!",{||Vazio().Or.ExistCpo("SAH")},,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"SAH","_cUnidMed",,)
	// se já existir o produto, não permite alterar
	_oGetUM:bWhen := {|| IIF(sfPrdExiste(_cCodProt), .F., .T.) }
	_nPosCmp += 15

	// Seg UM / fat. conversor
	_oSaySegUM := TSay():New(_nPosCmp,005,{||"Seg. U.M."},oScrollBox,,,,,,.T.,IIf(_lUsoSegUM, CLR_HBLUE, Nil),,040,30)
	_oGetSegUM := TGet():New(_nPosCmp-2,050,bSetGet(_cSegUnid),oScrollBox,040,10 ,"@!",{||Vazio().Or.ExistCpo("SAH")},,,,,,.T.,,,{|| _lUsoSegUM },.F.,.F.,,.F.,.F.,"SAH","_cSegUnid",,)
	_oSayConver := TSay():New(_nPosCmp,100,{||"Fator Conv."},oScrollBox,,,,,,.T.,,,030,30)
	_oGetConver := TGet():New(_nPosCmp-2,135,bSetGet(_nConver),oScrollBox,060,10,PesqPict("SB1","B1_CONV"),{||Positivo()},,,,,,.T.,  ,,{|| IIF(sfPrdExiste(cSigla + cCodigo), .F., .T.) .AND. _lUsoSegUM .AND. _lUsoFatConv },.F.,.F.,,.F.,.F.,"","_nConver",,)
	_nPosCmp += 15

	// Seg UM / fat. conversor
	_oSayTpConv := TSay():New(_nPosCmp,005,{||"Tipo de Conv"},oScrollBox,,,,,,.T.,,,040,30)
	_oGetTpConv := TComboBox():New(_nPosCmp,050,{|u| If(PCount()>0,_cTipoConv:=u,_cTipoConv)},{"Multiplicador","Divisor"},145,010,oScrollBox,,,,,,.T.,,"",,{|| IIF(sfPrdExiste( SA1->A1_SIGLA + cCodigo ), .F., .T.) .AND. _lUsoSegUM .AND. _lUsoFatConv },,,,,"_cTipoConv")
	_nPosCmp += 15

	// local padrao / localizacao
	_oSayLocal := TSay():New(_nPosCmp,005,{||"Armazém Padrão"},oScrollBox,,,,,,.T.,CLR_HBLUE,,)
	_oGetLocal := TGet():New(_nPosCmp-2,050,bSetGet(_cLocPad),oScrollBox,030,10,"@!",{|| Vazio().or.ExistCpo("Z12") },,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"Z12","_cLocPad",,)
	_oSayContEnd := TSay():New(_nPosCmp,100,{||"Contr. End."},oScrollBox,,,,,,.T.,CLR_HBLUE,,040,30)
	_oGetContEnd := TComboBox():New(_nPosCmp,135,{|u| If(PCount()>0,_cLocaliz:=u,_cLocaliz)},{"Sim","Nao"},060,010,oScrollBox,,,,,,.T.,,"",,{||.f.},,,,,"_cLocaliz")
	_nPosCmp += 15

	// origem / Pos IPI
	_oSayOrigem := TSay():New(_nPosCmp,005,{||"Origem"},oScrollBox,,,,,,.T.,CLR_HBLUE,,030,30)
	_oGetOrigem := TGet():New(_nPosCmp-2,050,bSetGet(_cOrigem),oScrollBox,030,10,"@!",{||Vazio().or.ExistCpo("SX5","S0"+_cOrigem)},,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"S0","_cOrigem",,)
	_oSayPosIPI := TSay():New(_nPosCmp,100,{||"Pos IPI"},oScrollBox,,,,,,.T.,CLR_HBLUE,,030,30)
	_oGetPosIPI := TGet():New(_nPosCmp-2,135,bSetGet(_cCodNCM),oScrollBox,060,10,PesqPict("SB1","B1_POSIPI"),{||Vazio().Or.ExistCpo("SYD")},,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"SYD","_cCodNCM",,)
	_nPosCmp += 20


	// grupo de estoque
	_oSayGrpEst := TSay():New(_nPosCmp,005,{||"Grupo de Estoque"},oScrollBox,,,,,,.T.,CLR_HBLUE,,)
	_oGetGrpEst := TGet():New(_nPosCmp-2,050,bSetGet(_cGrpEsto),oScrollBox,040,10,PesqPict("SB1","B1_ZGRPEST"),{||Vazio().or.ExistCpo("Z36",cSigla +_cGrpEsto)},,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"Z36PRO","_cGrpEsto",,)
	_nPosCmp += 15

	// código EAN
	_oSayEan := TSay():New(_nPosCmp,005,{||"Cód. de Barras"},oScrollBox,,,,,,.T.,CLR_HBLUE,,)
	_oGetEan := TGet():New(_nPosCmp-2,050,bSetGet(_cCodBar),oScrollBox,100,010,PesqPict("SB1","B1_CODBAR"),,,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"","_cCodBar",,)
	_nPosCmp += 15

	// ativa a tela
	Activate MSDialog _oDlgDetProd Centered

	mvOK := .T.


Return  {_cTipo,  _cUnidMed,  _cSegUnid,  _nConver, Left(_cTipoConv,1),  _cLocPad, Left(_cLocaliz,1),   _cOrigem, 0,  _cCodNCM,   _cGrpEsto, AllTrim(_cCodBar),  ''  }


// ** função pra validar se o produto já existe ** //
Static Function sfPrdExiste(mvCodProd)
	// variavel de retorno
	local _lRet     := .F.
	// salva area atual
	local _aAreaAtu := GetArea()

	dbSelectArea("SB1")
	SB1->( dbSetOrder(1) )
	// procuro o produto na tabela e se ja existir, retorna falso
	_lRet := SB1->( dbSeek( xFilial("SB1")+mvCodProd) )

	// restaura area inicial
	RestArea(_aAreaAtu)
Return _lRet



//-------------------

//--------------------------------------------------------------------------//
// Programa: TECMID05()	|	Autor: Luiz Poleza	 |   	Data: 11/06/2019	//
//--------------------------------------------------------------------------//
// Descrição: Exporta números de série e produtos conferidos na OS de      	//
//			  pré-conferência do cliente Midea para Excel                   //
//--------------------------------------------------------------------------//

User Function TECMID05(mvNumos, mvRotAuto)
	Local _cArquivo := ""
	Default mvRotAuto := .F.

	// se não foi informada a OS
	If Empty(mvNumos)
		Help(,, 'TECMID05.001',, "Falha na geração do arquivo.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"Ordem de serviço não informada."}) 
	Else
		If !(mvRotAuto)  // se não for rotina automática, pede onde salvar o arquivo excel
			_cArquivo := cGetFile("Planilhas|*.XLS", ("Escolha onde salvar o arquivo"),,,.T.,16,.f.)  
		Else
			_cArquivo := "\EDI\midea\conferencia\" + mvNumos + ".xls"
		EndIf

		If !Empty(_cArquivo)
			Processa({|| ProcExec(mvNumos, _cArquivo)}, 'Aguarde...', 'Processando exportação...')
		EndIf
	Endif

Return (_cArquivo)


Static Function ProcExec(mvNumos, mvXLS)
	Local aArea        := GetArea()
	Local cQuery        := ""
	Local oFWMsExcel

	//-- Monta regua de processamento
	ProcRegua(0)

	//-- Incremento da regua
	IncProc('Etapa 1/3 - Buscando dados da OS...')

	//Pegando os dados
	cQuery := "SELECT B1_CODCLI, B1_DESC, Z07_QUANT, Z07_NUMSER "
	cQuery += "  FROM " + RetSqlTab("Z07")
	cQuery += " INNER JOIN " + RetSqlTab("SB1") 
	cQuery += "    ON " + RetSqlCond("SB1")
	cQuery += "    AND SB1.B1_COD = Z07.Z07_PRODUT "
	cQuery += " INNER JOIN " + RetSqlTab("Z06")
	cQuery += "    ON " + RetSqlCond("Z06")
	cQuery += "    AND Z06.Z06_NUMOS = Z07.Z07_NUMOS "
	cQuery += "    AND Z06.Z06_SEQOS = Z07.Z07_SEQOS "
	cQuery += "    AND Z06.Z06_SERVIC = '015' "
	cQuery += "    AND Z06.Z06_TAREFA = '014' "
	cQuery += "    AND Z06.Z06_STATUS IN ( 'AN', 'FI') "
	cQuery += " WHERE " + RetSqlCond("Z07")
	cQuery += " AND Z07.Z07_NUMOS = '" + mvNumos + "'"
	cQuery += " AND Z07.Z07_SEQOS = '001'"
	TCQuery cQuery New Alias "QRYPRO"

	//-- Incremento da regua
	IncProc('Etapa 2/3 - Gerando estrutura Excel...')

	//Criando o objeto que irá gerar o conteúdo do Excel
	oFWMsExcel := FWMSExcel():New()

	//Aba 02 - Produtos
	oFWMsExcel:AddworkSheet("Produtos")
	//Criando a Tabela
	oFWMsExcel:AddTable ("Produtos","Produtos")
	oFWMsExcel:AddColumn("Produtos","Produtos","Codigo",1)
	oFWMsExcel:AddColumn("Produtos","Produtos","Descricao",1)
	oFWMsExcel:AddColumn("Produtos","Produtos","Qtd",1)
	oFWMsExcel:AddColumn("Produtos","Produtos","Num.Serie",1)

	//Criando as Linhas... Enquanto não for fim da query
	While !(QRYPRO->(EoF()))
		oFWMsExcel:AddRow("Produtos","Produtos",{;
		QRYPRO->B1_CODCLI,;
		QRYPRO->B1_DESC,;
		QRYPRO->Z07_QUANT,;
		QRYPRO->Z07_NUMSER	})

		//Pulando Registro
		QRYPRO->(DbSkip())
	EndDo

	//-- Incremento da regua
	IncProc('Etapa 3/3 - Gerando arquivo Excel...')

	//Ativando o arquivo e gerando o xml
	oFWMsExcel:Activate()
	oFWMsExcel:GetXMLFile(mvXLS)

	QRYPRO->(DbCloseArea())
	RestArea(aArea)
Return



//-------------------

//--------------------------------------------------------------------------//
// Programa: TECMID06()	|	Autor: Gustavo Schumann	|	Data: 10/06/2019	//
//--------------------------------------------------------------------------//
// Descrição: Rotina que efetua a leitura do EDI 3.3 Midea e converte para	//
//			  o layout EDI Tecadi.											//
//--------------------------------------------------------------------------//

User Function TECMID06(mvArquivo)
	Local _lRet := .T.
	Local _cBkp := ""
	local _cArqPed  := ""

	Private _aXML	:= {}

	// variáveis necessárias para chamada da importação via staticcall
	Private _vListaArq   := {}     // lista de arquivos para importar
	Private _cTipoArq    := "TXT"  // tipo do arquivo convertido
	Private _cRefAgrupa  := ""     // agrupadora
	Private _lLotAtivo   := .F.     // valida controle de lote ativo.
	Private _lVldNrPed   := U_FtWmsParam("WMS_PEDIDO_VALIDA_PEDIDO_CLIENTE", "L", .F. , .F., Nil, "000603", "01", Nil, Nil)   // controle se deve validar o numero do pedido do cliente
	Private _lVldChvNfv  := U_FtWmsParam("WMS_PEDIDO_VALIDA_CHAVE_NOTA_VENDA", "L", .F. , .F., Nil, "000603", "01", Nil, Nil) // controle se deve validar a chave da nota de venda do cliente
	Private _lAgrUnicPed := U_FtWmsParam("WMS_PEDIDO_AGRUPAR_XML_UNICO_PEDIDO", "L", .T. , .F., Nil, "000603", "01", Nil, Nil) // controle se deve agrupar todos os XML em unico pedido para separacao
	Private _dEmissNFe   := CtoD("//") 	// data de emissao da nota importada
	Private _cChaveNFe   := ""          // chave da NFe para consulta do status no SEFAZ
	private _cDocNfCli   := ""          // documento/nota do cliente

	// efetua a leitura do arquivo passado por parametro
	If !TECMID06A(mvArquivo)
		FWLogMsg('ERROR',, 'SIGAFAT', FunName(), '', '01',"Arquivo EDI 3.3 não disponível: "+mvArquivo , 0, 0, {})
		_lRet := .F.
	EndIf

	// efetua a conversão do EDI Midea para o padrão Tecadi
	If (_lRet)
		If !TECMID06B(mvArquivo, @_cArqped)
			_lRet := .F.
		Else
			// gerou arquivo convertido, então chama função para gerar o pedido de venda
			AAdd( _vListaArq, _cArqped)
			_lRet := StaticCall( TFATA001, fGeraPedVen)
		EndIf
	EndIf

	If (_lRet)
		// mover arquivo original para basta BKP
		_cBkp := StrTran(mvArquivo, "\lista_separacao\",  "\lista_separacao\bkp\")  // altera caminho para pasta bkp
		_cBkp := StrTran(_cBkp , ".txt", "_" + DtoS( Date() ) + "_" + StrTran( Time(), ":" ) + ".txt")
		FRename( mvArquivo, _cBkp )

		U_FtGeraLog(xFilial("SC5"), "", "", "Arquivo EDI 3.3 separacao Midea integrado com sucesso! [TECMID06] " + mvArquivo, "003", "")
	Else
		U_FtGeraLog(xFilial("SC5"), "", "", "Falha na integração do arquivo EDI 3.3 separacao Midea! [TECMID06] " + mvArquivo, "003", "")
	EndIf

Return(_lRet)
//-------------------------------------------------------------------------------------------------
Static Function TECMID06A(mvArquivo)
	Local _lRet := .T.
	Local cMemo := ""

	_aXML := {}

	cMemo := MemoRead(mvArquivo)

	If EMPTY(cMemo)
		_lRet := .F.
	Else
		_aXML := StrTokArr(cMemo, Chr(13) + Chr(10))
	EndIf

Return(_lRet)
//-------------------------------------------------------------------------------------------------
Static Function TECMID06B(mvArquivo, mvArqPed)
	Local _lRet		:= .T.
	Local _cArq		:= ""
	Local _cProduto := ""
	Local _cDesc	:= ""
	Local _nX		:= 1
	Local _aEnd		:= {}
	Local _aAux		:= {}
	Local _aTmp		:= {}
	Local _aArqTmp	:= {}
	Local _cPedcli  := ""
	Local _cDeposit := "10948651004230"   // CNPJ da midea conforme tabela SA1
	local _cBkp     := ""                 // nomenclatura do arquivo para gravar de backup

	// elimina a última posição do array, caso este esteja com o caractere de final de arquivo
	If Len(_aXML[Len(_aXML)]) == 1
		ASize(_aXML,Len(_aXML)-1)
	EndIf

	// quebra as linhas do array geral em um array multidimensional na cerquilha
	For _nX := 1 To Len(_aXML)
		_aTmp := StrTokArr2(_aXML[_nX],"#",.T.)
		AADD(_aAux,{_aTmp})
	Next _nX

	// tratamento para remover os caracteres de inicio de arquivo: ï»¿
	If Len(_aAux[1][1][1]) > 10
		_aAux[1][1][1] := SubStr(_aAux[1][1][1],4,Len(_aAux[1][1][1]))
	EndIf

	// preenche pedido do cliente
	_cPedcli := _aAux[1][1][1]  // 1 - campo VBELN

	// bloco 1 - cabeçalho
	_cArq := "0^" + _cDeposit + "^" + _cPedcli + "^^^" + CRLF

	// bloco 2 - dados do produto
	For _nX := 1 To Len(_aAux)

		If !_lRet
			Exit
		EndIf

		If Select("tSB1") > 0
			DBSelectArea("tSB1")
			tSB1->(DBCloseArea())
		EndIf

		cQuery := " SELECT B1_COD,B1_DESC, B1_CODCLI "
		cQuery += " FROM " + RetSQLTab("SB1") + " (nolock) "
		cQuery += " WHERE " + RetSqlCond("SB1")
		cQuery += " AND B1_CODCLI = '" + _aAux[_nX][1][16] + "' "

		TCQuery cQuery NEW ALIAS "tSB1"

		DBSelectArea("tSB1")
		tSB1->(DBGoTop())

		if !tSB1->(EOF())
			_cProduto	:= AllTrim(tSB1->B1_CODCLI)
			_cDesc		:= AllTrim(tSB1->B1_DESC)
			tSB1->(DBSkip())
		Else  // não achou o produto
			_lRet := .F.
		EndIf

		// 6 - ordem de compra/venda (VGBEL)
		// 17 - quantidade (LFIMG)
		_cArq += "1^"+_cProduto+"^"+_cDesc+"^"+_aAux[_nX][1][17]+"^^^" + _aAux[1][1][6] + "^^"+CRLF

		IIf ( Empty(_cRefAgrupa), _cRefAgrupa := _aAux[1][1][6], Nil )

	Next _nX

	// bloco 3 - dados de entrega
	If (_lRet)
		_aEnd := StrTokArr(_aAux[1][1][5],",")

		_cEndereco	:= _aEnd[1]+", "+_aEnd[2]+", "+_aEnd[3]+", "+_aEnd[5]
		_cCidade	:= _aEnd[Len(_aEnd)-3]
		_cEstado	:= _aEnd[Len(_aEnd)-1]

		_cArq += "2^^"+_aAux[1][1][4]+"^"+_cEndereco+"^"+_cCidade+"^"+_cEstado+""+CRLF
	EndIf

	// grava arquivo convertido
	If (_lRet)
		// ajusta o caminho/nome do arquivo original
		_aArqTmp := StrTokArr(mvArquivo,"\")
		mvArqPed := "\EDI\midea\lista_separacao\convertido\" + "tecadi_" + _aArqTmp[Len(_aArqTmp)]

		// gera o arquivo convertido
		MemoWrite( mvArqPed ,_cArq)
	EndIf

Return( _lRet )



//--------------------------------------------------------------------------//
// Programa: TECMID07()	|	Autor: Gustavo Schumann	|	Data: 12/06/2019	//
//--------------------------------------------------------------------------//
// Descrição: Tela de log de integração Midea.								//
//--------------------------------------------------------------------------//

User Function TECMID07()
	Local oBrowse
	Local _aPcCamp := {}
	Local _aTmp := {}
	// controle de opcoes do menu
	Private aRotina := MenuDef()
	Private _cTabPc := GetNextAlias()
	Private _cTrBArqPC

	// Campos da tabela temporária
	AADD(_aPcCamp,{"ZN_FILIAL"  ,"C", TamSx3("ZN_FILIAL")[1],0})
	AADD(_aPcCamp,{"ZN_TABELA"  ,"C", TamSx3("ZN_TABELA")[1],0})
	AADD(_aPcCamp,{"ZN_CHAVE"   ,"C", TamSx3("ZN_CHAVE")[1] ,0})
	AADD(_aPcCamp,{"ZN_DATA"    ,"D", TamSx3("ZN_DATA")[1]  ,0})
	AADD(_aPcCamp,{"ZN_HORA"    ,"C", TamSx3("ZN_HORA")[1]  ,0})
	AADD(_aPcCamp,{"ZN_DESCRI"  ,"C", TamSx3("ZN_DESCRI")[1],0})

	If (Select(_cTabPc)<>0)
		dbSelectArea(_cTabPc)
		dbCloseArea()
	EndIf

	// Criação da tabela temporária
	_cTrBArqPc := FWTemporaryTable():New( _cTabPc )
	_cTrBArqPc:SetFields( _aPcCamp )
	_cTrBArqPc:AddIndex("01", {"ZN_FILIAL", "ZN_TABELA", "ZN_CHAVE", "ZN_DATA", "ZN_HORA"} )
	_cTrBArqPc:Create()

	// Popula a tabela temporária
	U_ATUMID07()

	// Posiciona a tabela temporária no topo
	(_cTabPc)->(dbSelectArea(_cTabPc))
	(_cTabPc)->(dbGoTop())

	// Campos da tabela temporária que serão exibidos no Browse
	AADD(_aTmp,{"Filial"   ,"ZN_FILIAL","C",TamSx3("ZN_FILIAL")[1],0,"@!"})
	AADD(_aTmp,{"Tabela"   ,"ZN_TABELA","C",TamSx3("ZN_TABELA")[1],0,"@!"})
	AADD(_aTmp,{"Chave"    ,"ZN_CHAVE" ,"C",TamSx3("ZN_CHAVE")[1] ,0,"@!"})
	AADD(_aTmp,{"Data"     ,"ZN_DATA"  ,"D",TamSx3("ZN_DATA")[1]  ,0,})
	AADD(_aTmp,{"Hora"     ,"ZN_HORA"  ,"C",TamSx3("ZN_HORA")[1]  ,0,})
	AADD(_aTmp,{"Descricao","ZN_DESCRI","C",TamSx3("ZN_DESCRI")[1],0,"@!"})

	// Criação do Browse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias(_cTabPc)
	oBrowse:SetFields( _aTmp )
	oBrowse:SetDescription("Central de Integrações e log - Midea")
	oBrowse:SetTemporary(.T.)
	oBrowse:SetLocate()
	oBrowse:SetUseFilter(.T.)
	oBrowse:SetDBFFilter(.T.)
	oBrowse:SetFilterDefault( "" )
	oBrowse:Activate()

Return
//-------------------------------------------------------------------
Static Function MenuDef()
	// variavel de retorno
	local _aRetMenu := 	{;
	{ "Visualizar", "VIEWDEF.TECMID07", 0 , 2 },;
	{ "Imp EDI Prod 3.1"   , "Processa({|| U_TECMID04(), U_ATUMID07() },'Processamento','...')", 0 , 3 },;
	{ "Gera Excel conf."   , "Processa({|| U_fGeraEx(), U_ATUMID07() },'Processamento','...')", 0 , 3 },;
	{ "Imp EDI Sep. 3.3"   , "Processa({|| U_fGetSep(), U_ATUMID07() },'Processamento','...')", 0 , 3 },;
	{ "Exp EDI Sep. 3.4"   , "Processa({|| U_fGera34(), U_ATUMID07() },'Processamento','...')", 0 , 3 },;
	{ "Imp EDI Nf.  3.5"   , "Processa({|| U_fGetNFe(), U_ATUMID07() },'Processamento','...')", 0 , 3 }}

Return(_aRetMenu)
//-------------------------------------------------------------------
Static Function ModelDef()

	Local oStruct
	Local oModel
	Local cDesc := "Log de importação Midea"

	oStruct := FWFormStruct(1, "SZN")
	//+-------------------------------------------------------------------------------------+
	//! Define o modelo e uma função de pós-validação                                       !
	//+-------------------------------------------------------------------------------------+
	oModeMPFormModelmModel():New("MODELO")
	//+-------------------------------------------------------------------------------------+
	//! Adiciona os campos conforme a estrutura e adiciona também a chave da tabela         !
	//+-------------------------------------------------------------------------------------+
	oModel:AddFields("CAMPOS1", , oStruct)
	oModel:SetPrimaryKey({"ZN_FILIAL"})

Return oModel

//-------------------------------------------------------------------
Static Function ViewDef()

	Local oStruct
	Local oModel
	Local oView

	//+-------------------------------------------------------------------------------------+
	//! Criação da estrutura, carga do modelo e inicialização da view                       !
	//+-------------------------------------------------------------------------------------+
	oModel := ModelDef()
	oStruct:= FWFormStruct(2, "SZN")
	oView  := FWFormView():New()
	//+-------------------------------------------------------------------------------------+
	//! Configura o modelo e adiciona seus campos conforme a estrutura criada               !
	//+-------------------------------------------------------------------------------------+
	oView:SetModel(oModel)
	oView:AddField("FORMULARIO1", 'oStruct','CAMPOS1')
	oView:CreateHorizontalBox( 'BOXFORM1', 100)
	oView:SetOwnerView('FORMULARIO1','BOXFORM1')

Return oView
//-------------------------------------------------------------------------------------------------
User Function ATUMID07()

	// Seleciona a tabela temporária e apaga todos os dados para atualiza-los
	(_cTabPc)->(dbSelectArea(_cTabPc))
	(_cTabPc)->(dbGoTop())
	If (_cTabPc)->(!EOF())
		(_cTabPc)->(__DbZap())
	EndIf

	// Consulta na tabela de Logs SZN para popular a tabela temporária
	If Select("tSZN") > 0
		DBSelectArea("tSZN")
		tSZN->(DBCloseArea())
	EndIf

	cQuery := " SELECT ZN_FILIAL,ZN_TABELA,ZN_CHAVE,ZN_DATA, ZN_HORA, ZN_DESCRI "
	cQuery += " FROM " + RetSQLTab("SZN") + " (nolock) "
	cQuery += " WHERE " + RetSqlCond("SZN")
	cQuery += " AND ZN_FILIAL = '" + xFilial("SZN") + "' "
	cQuery += " AND ZN_MODULO = 'WMS' "
	cQuery += " AND ZN_DEPTO  = '003' "
	cQuery += " AND ZN_DATA >= '" + DTOS( Date() - 3 ) + "' "
	cQuery += " ORDER BY ZN_DATA, ZN_HORA "

	TCQuery cQuery NEW ALIAS "tSZN"

	DBSelectArea("tSZN")
	tSZN->(DBGoTop())

	// Popula a tabela temporária
	Begin transaction
		if !tSZN->(EOF())
			While !tSZN->(EOF())
				(_cTabPc)->(dbSelectArea(_cTabPc))
				(_cTabPc)->(RecLock(_cTabPc,.T.))
				(_cTabPc)->ZN_FILIAL:= tSZN->ZN_FILIAL
				(_cTabPc)->ZN_TABELA:= tSZN->ZN_TABELA
				(_cTabPc)->ZN_CHAVE	:= tSZN->ZN_CHAVE
				(_cTabPc)->ZN_DATA	:= StoD(tSZN->ZN_DATA)
				(_cTabPc)->ZN_HORA	:= tSZN->ZN_HORA
				(_cTabPc)->ZN_DESCRI:= tSZN->ZN_DESCRI
				(_cTabPc)->(MsUnLock())

				tSZN->(DBSkip())
			EndDo
		EndIf
	End Transaction

	// Posiciona a tabela no último registro
	(_cTabPc)->(dbGoBottom())

	// Fecha a Alias da consulta SZN
	tSZN->(DBCloseArea())

Return
//-------------------------------------------------------------------------------------------------
User Function fGetSep()

	cTargetDir	:= cGetFile( 'E*.txt|e*.txt' , 'EDI Separacao Midea', 1, '\EDI\MIDEA\lista_separacao\', .T.,GETF_NOCHANGEDIR,.T., .T. )

	If !EMPTY(cTargetDir)

		/* Luiz Fernando Berti - 13/06/2019
		Recurso técnico encontrado para contornar um defeito da função cGetFile, onde ao selecionar o arquivo
		e clicar no botão Abrir, não retorna o caminho completo do arquivo.
		Testado em Lib e binário diferentes, porém o defeito continuou.
		*/
		If U_TECMID06(cTargetDir) .Or. U_TECMID06("\EDI\MIDEA"+cTargetDir)
			MsgAlert("Arquivo EDI 3.3 separacao Midea integrado com sucesso!")
		Else
			MsgAlert("Falha na integração do arquivo EDI 3.3 separacao Midea!")
		EndIf
	EndIf

Return
//-------------------------------------------------------------------------------------------------
User Function fGetNFe()

	cTargetDir	:= cGetFile( 'NFS*.txt|nfs*.txt' , 'EDI NF-e Midea', 1, '\EDI\MIDEA\NF_VENDA\', .T.,GETF_NOCHANGEDIR,.T., .T. )

	If !EMPTY(cTargetDir)

		/* Luiz Fernando Berti - 13/06/2019
		Recurso técnico encontrado para contornar um defeito da função cGetFile, onde ao selecionar o arquivo
		e clicar no botão Abrir, não retorna o caminho completo do arquivo.
		Testado em Lib e binário diferentes, porém o defeito continuou.
		*/
		If U_TECMID03(cTargetDir) .Or. U_TECMID03("\EDI\MIDEA"+cTargetDir)
			MsgAlert("Arquivo EDI 3.5 NF-e Midea integrado com sucesso!")
		Else
			MsgAlert("Falha na integracao do arquivo EDI 3.5 NF-e Midea!")
		EndIf
	EndIf

Return
//-------------------------------------------------------------------------------------------------
User Function fGera34()

	local _cNumos := FWInputBox("Insira o número da OS para gerar","")  
	Local _lRet, _cDestino, _nX
	Local _aArquivo := {}

	If Empty(_cNumos)
		MsgAlert("OS em branco!")
		_lRet := .F.
	Else
		Processa({|| _lRet := TECMID08(_cNumos, @_aArquivo)}, 'Aguarde...', 'Processando exportação...')
	EndIf

	If (_lRet)
		U_FtGeraLog(cFilAnt, "LOG", "INTEGRACAO-EDI", "Arquivo EDI 3.4 (número de série expedição) gerado com sucesso! - OS "+_cNumOS+" - [TECMID08] ", "003", "")

		// pergunta se usuário quer gravar o arquivo gerado
		If MsgYesNo("Deseja copiar os arquivos gerados para seu computador?")
			_cDestino := cGetFile("EDI|*.TXT", ("Escolha onde salvar o arquivo"),,,.T.,16 + 128,.f.)  

			If !Empty(_cDestino)
				//Copia o arquivo do Servidor para a máquina do usuário
				For _nX := 1 to Len (_aArquivo)
					CpyS2T(_aArquivo[_nX], _cDestino)
				Next _nX
			EndIf

		EndIf

	Else
		U_FtGeraLog(cFilAnt, "LOG", "INTEGRACAO-EDI", "Falha na geração do arquivo EDI 3.4 (número de série expedição) - OS "+_cNumOS+" - [TECMID08] ", "003", "")
	EndIf


Return
//-------------------------------------------------------------------------------------------------
User Function fGeraEX()

	local _cNumos := FWInputBox("Insira o número da OS para gerar","")  

	If Empty(_cNumos)
		MsgAlert("OS em branco!")
	Else
		U_TECMID05(_cNumos)
	EndIf
Return


//--------------------------------------------------------------------------//
// Programa: TECMID08()	|	Autor: Junior Conte	|	    Data: 11/06/2019	//
//--------------------------------------------------------------------------//
// Descrição: Exportação de arquivo conforme layout 3.4 .					//
//--------------------------------------------------------------------------//

Static Function TECMID08(mvNumos, mvArquivo)

	Local cAliasQry   := GetNextAlias()
	Local cQuery 
	Local cPath			:= "\EDI\MIDEA\NUM_SERIE\" //AllTrim(GetTempPath())
	Local cArquivo		:= "" 
	Local nHandle 		:= 0  
	Local _nTotal,_nAtual  :=0
	Local _cNumped      := ""
	Local _oFile

	If Select("QRY1") <> 0
		dbSelectArea("QRY1")
		QRY1->(dbCloseArea())
	EndIf

	cQuery := "SELECT B1_CODCLI, C5_ZPEDCLI, ROW_NUMBER() OVER (PARTITION BY C5_ZPEDCLI ORDER BY C5_ZPEDCLI) AS C6_ITEM, Z06_DTFIM, Z06_HRFIM, Z06_USRFIM, Z07_NUMSER  "
	cQuery += "  FROM " + RetSqlTab("Z07")
	cQuery += " INNER JOIN " + RetSqlTab("SB1")
	cQuery += "    ON " + RetSqlCond("SB1") 
	cQuery += "   AND SB1.B1_COD = Z07.Z07_PRODUT "
	cQuery += " INNER JOIN " + RetSqlTab("SC5")
	cQuery += "    ON " + RetSqlCond("SC5")
	cQuery += "   AND SC5.C5_NUM = Z07.Z07_PEDIDO"
	cQuery += "   AND SC5.C5_TIPO    = 'N'"
	cQuery += "   AND SC5.C5_TIPOOPE = 'P'"
	cQuery += " INNER JOIN " + RetSqlTab("Z06")
	cQuery += "    ON "+ RetSqlCond("Z06")
	cQuery += "   AND Z06.Z06_NUMOS  = Z07.Z07_NUMOS "
	cQuery += "   AND Z06.Z06_SEQOS  = Z07.Z07_SEQOS "
	cQuery += "   AND Z06.Z06_STATUS = 'FI' "
	cQuery += " WHERE Z07.Z07_FILIAL  = '" + xFilial("Z07") + "' AND Z07.D_E_L_E_T_ = ' '  AND Z07.Z07_NUMOS = '" + mvNumos + "' AND Z07.Z07_SEQOS = '002'" 
	cQuery += " ORDER BY C5_ZPEDCLI " 

	memowrit("C:\QUERY\LAY34.TXT", cQuery)

	TCQuery cQuery NEW ALIAS "QRY1"   				
	dbSelectArea("QRY1") 
	//-- Monta regua de processamento
	Count to _nTotal
	ProcRegua( _nTotal )
	
	QRY1->( DbGoTop() )	
	
	// se arquivo em branco
	If QRY1->( Eof() )
		Help(,, 'TECMID08.F01.001',, "Arquivo em branco.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"Não foi possível gerar o arquivo para a OS " + mvNumos + " pois não trouxe resultados. Verifique se OS têm conferência realizada e se está FINALIZADA."}) 

		Return ( .F. )
	EndIf

	PswOrder( 1 )
	cArquivo := Upper("R" + AllTrim(QRY1->C5_ZPEDCLI) + ".TXT")
	_cNumped := QRY1->C5_ZPEDCLI

	// tenta criar o arquivo
	nHandle   := FCreate(cPath + cArquivo, Nil, Nil, .F.  ) 						

	// se deu erro
	If ( nHandle < 1 )
		Return ( .F. )
	Else
		// guarda o primeiro arquivo gerado no array
		AAdd(mvArquivo, cPath + cArquivo)
		
		// gera as linhas
		Do While QRY1->(!Eof())
			//-- Incremento da regua
			_nAtual++
			IncProc("Processando linha " + cValToChar(_nAtual) + " de " + cValToChar(_nTotal))

			if (_cNumped != QRY1->C5_ZPEDCLI) //mudou pedido
				// fecha arquivo criado
				fClose(nHandle)

				cArquivo := Upper("R" + AllTrim(QRY1->C5_ZPEDCLI) + ".TXT")
				_cNumped := QRY1->C5_ZPEDCLI

				// tenta criar o arquivo
				nHandle   := FCreate(cPath +  cArquivo , Nil, Nil, .F. ) 		
				
				// se conseguiu gerar o arquivo
				If ( nHandle < 1 )
					Help(,, 'TECMID08.F01.002',, "Erro na criação do arquivo.", 1, 0,;
					NIL, NIL, NIL, NIL, NIL,;
					{"Não foi possível gerar o arquivo de EDI referente ao pedido " + _cNumped + " em disco!"}) 
				Else
					AAdd(mvArquivo, cPath + cArquivo)
				Endif

			EndIf
			PswSeek( QRY1->Z06_USRFIM )  

			//B1_CODCLI, C5_ZPEDCLI, C6_ITEM, Z07_NUMSER, Z06_DTFIM, Z06_HRFIM, Z06_USRFIM    

			fWrite(nHandle, "500" + "#" )  // MANDANTE
			fWrite(nHandle, ALLTRIM(QRY1->C5_ZPEDCLI) + "#" )  // FORNECIMENTO
			fWrite(nHandle, ALLTRIM(Str(QRY1->C6_ITEM))    + "#" )  // ITEM FORNECIMENTO
			fWrite(nHandle, ALLTRIM(QRY1->B1_CODCLI)  + "#" )  // CODIGO MATERIAL
			fWrite(nHandle, ALLTRIM(QRY1->Z07_NUMSER) + "#" )  // NUMERO DE SERIE
			fWrite(nHandle, substr(QRY1->Z06_DTFIM, 7, 2) +  substr(QRY1->Z06_DTFIM, 5, 2) +   substr(QRY1->Z06_DTFIM, 1, 4)  + "#" )  // DATA EMBARQUE
			fWrite(nHandle, QRY1->Z06_HRFIM + "#" )  // HR EMBARQUE
			fWrite(nHandle, PswRet(1)[1][2]  )  // USUARIO
			fWrite(nHandle, Chr(13) + Chr(10) ) // Pula linha 

			// próxima linha
			QRY1->(DbSkip())	
		EndDo

		// fecha arquivo criado
		fClose(nHandle)

	EndIf

Return ( .T. )
