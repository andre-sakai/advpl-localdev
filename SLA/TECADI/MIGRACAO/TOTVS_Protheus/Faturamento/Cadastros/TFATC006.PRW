#INCLUDE "Totvs.ch"
#Define _CRLF Chr(13)+Chr(10)

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Cadastro de Tabela de Preco de Fretes                   !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2010                                                 !
+------------------+--------------------------------------------------------*/

User Function TFATC006
	
	// filtro de tabela
	local _cFiltro := ""

	// cabecalho
	dbSelectArea("SZ4")
	// itens
	dbSelectArea("SZ5")

	// variaveis internas de controle de validacao de campo
	Private _lInclui
	Private _lAltera

	Private _cCadastro := "Tabela de Preço de Frete"

	Private aRotina := { { "Pesquisar"  ,"AxPesqui"		,0,1},;
	      				 { "Visualizar" ,"U_FATC006B(1)",0,2},;
	      				 { "Incluir"    ,"U_FATC006B(2)",0,3},;
	      				 { "Alterar"    ,"U_FATC006B(3)",0,4},;
	      				 { "Excluir"    ,"U_FATC006B(4)",0,5} }

	// define o filtro, quando acessado pelo WMS
	If (cModulo == "WMS")
		// valida usuarios (gustavo, renan, luiz, giovanni)
		If (!(__cUserId $ AllTrim(SuperGetMv("TC_USRFRET",.f.,""))))
			Aviso("Tecadi: TFATC006","Usuário sem permissão para utilizar esta rotina.",{"OK"})
			Return(.f.)
		// valida usuarios (gustavo, renan e luiz)
		ElseIf (__cUserId $ AllTrim(SuperGetMv("TC_USRFRET",.f.,"")))
			_cFiltro := "Z4_CODIGO = '001'"
		EndIf
	EndIf
	
	DbSelectArea("SZ4")
	SZ4->(DbSetOrder(1))
	mBrowse(6,1,22,75,"SZ4",,,,,,,,,,,,,,_cFiltro)
   
Return

//** funcao de Cadastro do Cabecalho e Itens
User Function FATC006B(mvOpcao)
	// dimensoes da tela
	Local _aSize := MsAdvSize()
	// tamanho utilizado para o modelo 3
	Local _aSizeMod3 := {_aSize[7],_aSize[1],_aSize[6],_aSize[5]}

	// controle da confirmacao da tela
	Local _lRet := .f.
	// posicao inicial do SX3
	Local _aAreaSx3 := SX3->(GetArea())
	// opcao selecionada
	Private _cOpcao
	// variavel com o Header
	Private aHeader := {}
	// variavel do aCols
	Private aCols := {}
	// define o valor da variavel padrao N
	Private N := 1

	// controle de variaveis da opcao selecionada
	Do Case
		Case mvOpcao==1; _cOpcao:="VISUALIZAR"; nOpcE:=2 ; nOpcG:=2 ; _lInclui := .f. ; _lAltera := .f.
		Case mvOpcao==2; _cOpcao:="INCLUIR";    nOpcE:=3 ; nOpcG:=3 ; _lInclui := .t. ; _lAltera := .f.
		Case mvOpcao==3; _cOpcao:="ALTERAR";    nOpcE:=3 ; nOpcG:=3 ; _lInclui := .f. ; _lAltera := .t.
		Case mvOpcao==4; _cOpcao:="EXCLUIR";    nOpcE:=2 ; nOpcG:=2 ; _lInclui := .f. ; _lAltera := .f.
	EndCase
	
	//Cria variaveis M->??? da Enchoice
	RegToMemory("SZ4",(_cOpcao=="INCLUIR"))
	
	// atualiza a filial
	If (_cOpcao=="INCLUIR")
		M->Z4_FILIAL := xFilial("SZ4")
	EndIf

	// cria o aHeader
	aX3SZ5 := FWSX3Util():GetAllFields( "SZ5" )
	For nX := 1 to Len(aX3SZ5)
		
		lUsado	  := X3Uso(GetSX3Cache(aX3SZ5[Nx],"X3_USADO"))
		cX3Nivel  := GetSX3Cache(aX3SZ5[Nx],"X3_NIVEL")
		cX3Browse := GetSX3Cache(aX3SZ5[Nx],"X3_BROWSE")
		
		If lUsado .and. cNivel >= cX3Nivel .and. cX3Browse == 'S'
			Aadd(aHeader, {;
			TRIM(GetSX3Cache(aX3SZ5[Nx],"X3_TITULO")),;
			GetSX3Cache(aX3SZ5[Nx],"X3_CAMPO")		 ,;
			GetSX3Cache(aX3SZ5[Nx],"X3_PICTURE")	 ,;
			GetSX3Cache(aX3SZ5[Nx],"X3_TAMANHO")	 ,;
			GetSX3Cache(aX3SZ5[Nx],"X3_DECIMAL")	 ,;
			GetSX3Cache(aX3SZ5[Nx],"X3_VALID")	 	 ,;
			GetSX3Cache(aX3SZ5[Nx],"X3_USADO")		 ,;
			GetSX3Cache(aX3SZ5[Nx],"X3_TIPO")		 ,;
			GetSX3Cache(aX3SZ5[Nx],"X3_ARQUIVO")	 ,;
			GetSX3Cache(aX3SZ5[Nx],"X3_CONTEXT")	 ,;
			GetSX3Cache(aX3SZ5[Nx],"X3_NIVEL")	 	 ,;
			GetSX3Cache(aX3SZ5[Nx],"X3_RELACAO")	 ,;
			GetSX3Cache(aX3SZ5[Nx],"X3_INIBRW")		 ,;
			})
		EndIf
		
	Next nX
		
	// definicao e montagem do aCols
	aCols := sfRetItens()
	
	// abre a tela de Cadastro
	_lRet := Modelo3(_cCadastro,"SZ4","SZ5",,,"U_FATC006C()",nOpcE,nOpcG,"AllwaysTrue()",,,,,,_aSizeMod3,80)

	If _lRet
		//** grava os dados da tabela de preco
        sfConfirma()
	Else
		RollBackSX8()
	Endif
	
Return

//** funcao que retorna os itens da tabela de preco
Static Function sfRetItens()
	Local _vRetItens := {}
	Local _nX
	// chave de pesquisa
	Local _cSeek
	
	dbSelectArea("SZ5")
	SZ5->(dbSetOrder(1)) //1-Z5_FILIAL, Z5_CODIGO, Z5_ITEM
	
	If (_cOpcao=="INCLUIR").or.(!SZ5->(dbSeek( _cSeek:=xFilial("SZ5")+M->Z4_CODIGO )))
		// cria a linha de acordo com os campos do Header
		_vRetItens := Array(1,Len(aHeader)+1)
		// cria as variaveis
		For _nX := 1 to Len(aHeader)
			_vRetItens[1,_nX] := CriaVar(aHeader[_nX,2],.t.)
		Next _nX
		// trata item deletado
		_vRetItens[Len(_vRetItens),Len(aHeader)+1] := .F.
	Else
		// inclui todos os itens da programacao
		While SZ5->(!Eof()).and.(SZ5->(Z5_FILIAL+Z5_CODIGO)==_cSeek)
			// cria a linha de acordo com os campos do Header
			aAdd(_vRetItens,Array(Len(aHeader)+1))
			// atualiza o conteudo de acordo com cada campo
			For _nX := 1 to Len(aHeader)
				// se for campo virtual, executa inic. padrao
				If (aHeader[_nX][10]=="V")
					_vRetItens[Len(_vRetItens),_nX] := &(aHeader[_nX][13])
				Else
					_vRetItens[Len(_vRetItens),_nX] := FieldGet(FieldPos(aHeader[_nX,2]))
				EndIf
			Next _nX
			// trata item deletado
			_vRetItens[Len(_vRetItens),Len(aHeader)+1] := .F.
			// proximo item
			SZ5->(dbSkip())
		EndDo
	EndIf

Return(_vRetItens)


//** Funcao responsavel pela gravacao dos dados
Static Function sfConfirma()
	Local bCampo := {|nCPO| Field(nCPO)}
	Local _nCpoAtu := 0
	Local _nItemAtu := 0
	Local _lIncluir := (_cOpcao=="INCLUIR")
	Local _lExcluir := (_cOpcao=="EXCLUIR")
	// posicao dos campos
	Local _nPosItem := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="Z5_ITEM"})
	// controle da nova sequencia para os itens
	local _nNewSeq := 1
	// Seek do SZ5
	local _cSeekSZ5

	// Grava Cabecalho
	Begin Transaction

	// Grava todas as Informacoes da Tabela (cabecalho)
	dbSelectArea("SZ4")
	RecLock("SZ4",_lIncluir)
		// verifica se é exclusao
		If (_lExcluir)
			SZ4->(dbDelete())
		// inclusao/alteracao
		Else
			// gravacao dos demais campo
			For _nCpoAtu := 1 to FCount()
				FieldPut(_nCpoAtu,M->&(EVAL(bCampo,_nCpoAtu)))
			Next _nCpoAtu
		EndIf
  	SZ4->(MsUnLock())
  	
  	// grava os itens
	dbSelectArea("SZ5")
	SZ5->(dbSetOrder(1))//1-Z5_FILIAL, Z5_CODIGO, Z5_ITEM

	For _nItemAtu := 1 to Len(aCols)
		// posiciona no item
		If (!_lIncluir)
			SZ5->(dbSeek( xFilial("SZ5")+M->Z4_CODIGO+aCols[_nItemAtu,_nPosItem] ))
		EndIf

	    // verifica se nao esta deletado
	    If (!_lExcluir) .and. (!aCols[_nItemAtu,Len(aHeader)+1])
			// operacao no registro
			If (_lIncluir)
				RecLock("SZ5",_lIncluir)
			Else
				RecLock("SZ5",(SZ5->(!Found())))
			EndIf
	    	// grava itens
	    	If (_lIncluir).or.(SZ5->(!Found()))
		    	SZ5->Z5_FILIAL	:= xFilial("SZ5")
		    	SZ5->Z5_CODIGO	:= M->Z4_CODIGO
		    EndIf
	    	// grava campos do browse
	    	For _nCpoAtu := 1 to Len(aHeader)
	    		// somente campos reais
				If (aHeader[_nCpoAtu][10] <> "V")
	    			FieldPut(FieldPos(aHeader[_nCpoAtu,2]),aCols[_nItemAtu,_nCpoAtu])
	    		EndIf
	    	Next _nCpoAtu
			// confirma gravacao
			SZ5->(MsUnLock())
	    Else
	        If (!_lIncluir).or.(_lExcluir)
		        // verifica a existencia do item 
		        If SZ5->(Found())
		            RecLock("SZ5",.F.)
			            SZ5->(dbDelete())
		            SZ5->(MsUnLock())
		     	Endif
		    Endif
	    EndIf

	Next _nItemAtu

	//Reordena os Itens 
	dbSelectArea("SZ5")
	SZ5->(dbSetOrder(1))//1-Z5_FILIAL, Z5_CODIGO, Z5_ITEM
	// posiciona no primeiro registros
	SZ5->(dbSeek( _cSeekSZ5 := xFilial("SZ5")+M->Z4_CODIGO ))
	While SZ5->(!EOF()).and.(SZ5->(Z5_FILIAL+Z5_CODIGO)==_cSeekSZ5)
		// muda a seq do item
	    RecLock("SZ5")
		    SZ5->Z5_ITEM := StrZero(_nNewSeq,Len(SZ5->Z5_ITEM))
	    SZ5->(MsUnLock())
	    // proxima sequencia
	    _nNewSeq++
	    // proximo item
	    SZ5->(dbSkip())
	EndDo

	// finaliza transacao
	End Transaction
	
	If (_lIncluir)
		ConfirmSX8()
	EndIf	
	
Return

//** funcao para verificar duplicidade de itens
User Function FATC006C()
	// retorno
	local _lRet := .t.
	// mensagem completa dos erros
	local _cMsgErro := ""
	// variaveis temporarias
	local _nX
	// posicao dos campos PRACAS
	local _nPosPrcOri := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="Z5_PRCORIG"})
	local _nPosPrcDes := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="Z5_PRCDEST"})
	local _nPosCont := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="Z5_CONTEUD"})
	local _nPosTipo := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="Z5_TIPCONT"})
	local _nPosItem := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="Z5_ITEM"})
	local _nPosDel := (Len(aHeader)+1)
	// linha do item duplicado
	local _nTmpLin := 0

	For _nX := 1 to Len(aCols)
		// descarta deletados
		If (aCols[_nX,Len(aHeader)+1])
			Loop
		EndIf

		// verifica se as duas pracas sao iguais
		If (aCols[_nX][_nPosPrcOri] $ aCols[_nX][_nPosPrcDes])
			// mensagem de erro
			_cMsgErro += "Item "+aCols[_nX][_nPosItem]+": Praça iguais"+_CRLF
			// variavel de retorno
			_lRet := .f.
		EndIf
		
		// verifica o item em duplicidade
		If (_nTmpLin := aScan(aCols,;
							  {|x| (x[_nPosItem] != aCols[_nX][_nPosItem]) .and. ;
							       (x[_nPosCont] == aCols[_nX][_nPosCont]) .and. ;
							       (x[_nPosTipo]  $ aCols[_nX][_nPosTipo]) .and. ;
							       ( !x[_nPosDel] ) .and. ;
							       ( (( AllTrim(x[_nPosPrcOri]) $ AllTrim(aCols[_nX][_nPosPrcOri])).and.(AllTrim(x[_nPosPrcDes]) $ AllTrim(aCols[_nX][_nPosPrcDes]))) .or. ;
							         (( AllTrim(x[_nPosPrcDes]) $ AllTrim(aCols[_nX][_nPosPrcOri])).and.(AllTrim(x[_nPosPrcOri]) $ AllTrim(aCols[_nX][_nPosPrcDes]))) ) ;
							  })) > 1
					
			// mensagem de erro
			_cMsgErro += "Item "+aCols[_nX][_nPosItem]+": Informações duplicadas com o item "+aCols[_nTmpLin][_nPosItem]+_CRLF
			// variavel de retorno
			_lRet := .f.
		EndIf
	Next _nX

	// mensagem de erro
	If (!_lRet)
		HS_MsgInf(_cMsgErro,;
				  "TFATC006 -> TudoOk()",;
				  "Inconsistência de dados" )
	EndIf
	

Return(_lRet)

//** funcao que detalha as pracas/tipos de containers da tabela de preco
User Function FATC006D(mvAlias)
	// area inicial
	local _aAreaAtu := GetArea()
	// pracas/tipos informados
	local _cConteudInf := &(ReadVar())
	// estrutura do TRB
	Local _aStrTrb	:= {}
	Local _aBrwTrb	:= {}
	local _cMarca	:= GetMark()
	// variaveis temporarias
	local _nX
	local _cQuery := ""
	// controle de confirmacao dos dados
	local _lOk := .f.
	//FWTemporaryTable
	local _TRBTMP := GetNextAlias()
	
	// define campos do TRB
	aadd(_aStrTrb,{"IT_OK","C",2,0})
	aadd(_aStrTrb,{"IT_COD","C",4,0})
	aadd(_aStrTrb,{"IT_DESC","C",50,0})
	
	// define campos do browse do TRB
	aadd(_aBrwTrb,{"IT_OK",,""})
	aadd(_aBrwTrb,{"IT_COD",,"Codigo"})
	aadd(_aBrwTrb,{"IT_DESC",,"Descrição"})    
	
	If (Select(_TRBTMP)<>0)
		(_TRBTMP)->(dbSelectArea(_TRBTMP))
		(_TRBTMP)->(dbCloseArea())
	EndiF
	
	_oTrbTmp := FWTemporaryTable():New(_TRBTMP)
	_oTrbTmp:SetFields(_aStrTrb)
	_oTrbTmp:Create()
	
	// monta a query para buscar as pracas
	If (mvAlias == "SZB")
		_cQuery := "SELECT CASE WHEN ZB_CODIGO IN "+FormatIn(_cConteudInf,';')+" THEN '"+_cMarca+"' ELSE '  ' END IT_OK, "
		_cQuery += "ZB_CODIGO IT_COD, ZB_DESCRI IT_DESC "
		_cQuery += "FROM "+RetSqlName("SZB")+" SZB "
		_cQuery += "WHERE "+RetSqlCond("SZB")+" "
		_cQuery += "ORDER BY ZB_CODIGO"
	// tipos de container
	ElseIf (mvAlias == "ZA")
		_cQuery := "SELECT CASE WHEN X5_CHAVE IN "+FormatIn(_cConteudInf,';')+" THEN '"+_cMarca+"' ELSE '  ' END IT_OK, "
		_cQuery += "X5_CHAVE IT_COD, X5_DESCRI IT_DESC "
		_cQuery += "FROM "+RetSqlName("SX5")+" SX5 "
		_cQuery += "WHERE "+RetSqlCond("SX5")+" "
		_cQuery += "AND X5_TABELA = 'ZA' "
		_cQuery += "ORDER BY X5_CHAVE "
	EndIf

	// alimenta o TRB com o resultado do SQL
	U_SqlToTrb(_cQuery,_aStrTrb,_TRBTMP)
	
	(_TRBTMP)->(dbSelectArea(_TRBTMP))
    (_TRBTMP)->(dbGotop())  
    
	// monta o dialogo
	_oDlgTabFrete := MSDialog():New(000,000,400,600,"Pracas/Tp Containers da Tabela de Frete",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel com os botoes
	_oPnlFreteBtn := TPanel():New(000,000,nil,_oDlgTabFrete,,.F.,.F.,,,025,025,.T.,.F. )
	_oPnlFreteBtn:Align:= CONTROL_ALIGN_TOP
	// botao para confirmar
	_oBtnFreteConf := TButton():New(005,005,"Confirmar",_oPnlFreteBtn,{|| _lOk := .t., _oDlgTabFrete:End() },045,012,,,,.T.,,"",,,,.F. )
	// botao para fechar
	_oBtnFreteFechar := TButton():New(005,055,"Fechar",_oPnlFreteBtn,{|| _oDlgTabFrete:End() },045,012,,,,.T.,,"",,,,.F. )
    
	// browse com a listagem dos itens
	_oBrwTabFrete := MsSelect():New (_TRBTMP,"IT_OK",Nil, _aBrwTrb, .F., _cMarca, {000,000,400,600})
	_oBrwTabFrete:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	
	// ativa a tela
	ACTIVATE MSDIALOG _oDlgTabFrete CENTERED 
	
	// caso a tela tenha sido confirmada
	If (_lOk)
		// zera a variavel de retorno
		_cConteudInf := ""
	
		(_TRBTMP)->(dbSelectArea(_TRBTMP))
		(_TRBTMP)->(dbGotop())
		While (_TRBTMP)->(!EOF()) 
			// verifica se o item esta marcado
			If ((_TRBTMP)->IT_OK == _cMarca)
		    	_cConteudInf += If(Empty(_cConteudInf),"",";")+AllTrim((_TRBTMP)->IT_COD)
		 	EndIf
			(_TRBTMP)->(dbSkip())
		EndDo
	EndIf

	// fecha o TRB
	(_TRBTMP)->(dbSelectArea(_TRBTMP))
	(_TRBTMP)->(dbCloseArea())

	// restaura area inicial
	RestArea(_aAreaAtu)
	
	//deleta tabela do banco
	_oTrbTmp:Delete()

Return(_cConteudInf)