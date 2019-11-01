#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Consulta notas fiscais já lançadas com base na planilha !
!                  ! CSV enviada diariamente pela contabilidade              !
!                  ! (planilha extraída do SEFAZ)                            !
+------------------+---------------------------------------------------------+
!Autor             ! Luiz Poleza              ! Data de Criacao ! 19/09/2016 !
+------------------+--------------------------------------------------------*/

User Function TCOMC001()

	//salva a area
	local _aArea := GetArea()
	
	// dimensoes da tela
	local _aSizeWnd := MsAdvSize()

	// objetos da tela
	local _oDlg
	local _oSayArqTXT 
	local _oGetArqTXT
	local _oPnlTop
	local _oBtnFile, _oBtnSai, _oBtnXLS

	// arquivo selecionado
	Local _cArquivo	:= ""

	// campos do browse dos itens a importar
	private _aHdTRB := {}
	private _cTabTemp := ""
	private _aCamTRB := {}
	private _oBrwNota
	private _cAliasTRB := GetNextAlias()

	// acao do botao cancela
	Private _bCancel  := {|| _oDlg:End() }

	//acao do botao gerar excel
	Private _bExcel   := {|| sfExpExcel() }
	
	// diretorio local padrao
	private _cDirLocPdr := "c:\temp"

	// cria o arquivo de trabalho dos itens
	sfCriaTrb(.t.)

	// monta o dialogo
	_oDlg := MsDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"Consulta notas fiscais já lançadas no sistema",,,.F.,,,,,,.T.,,,.T. )
	_oDlg:lMaximized := .T.

	// cabecalho
	_oPnlTop := TPanel():New(000,000,,_oDlg,,.T.,.F.,,,040,040,,)
	_oPnlTop:Align := CONTROL_ALIGN_TOP

	//****ITENS DA TELA****
	
	// selecao do arquivo CSV
	_oSayArqTXT := TSay():New(007,005,{|| "Arquivo CSV:" },_oPnlTop,,,,,,.T.,,,080,30)
	// get com o local do arquivo CSV
	_oGetArqTXT := TGet():New(005,070,bSetGet(_cArquivo),_oPnlTop,230,10,"@!",,,,,,,.T.,,,{|| .F.})
	// botao para selecao do arquivo CSV
	_oBtnFile := TButton():New(005,310, OemToAnsi("&Abrir...") ,_oPnlTop , {|| sfGetFile(@_cArquivo) }, 40,12,,,,.T.)
	// botão para fechar a tela
	_oBtnSai  := TButton():New(005,370, OemToAnsi("&Fechar") ,_oPnlTop,{|| Eval(_bCancel) },40,12,,,,.T.)
	// botão para exportar excel
	_oBtnXLS  := TButton():New(005,430, OemToAnsi("Gerar Excel") ,_oPnlTop,{|| Eval(_bExcel) },40,12,,,,.T.)



	//****MONTAGEM DO BROWSE****
	// monta o browse com os itens da nota
	//	MsSelect(): New ( < cAlias>, [ cCampo], [ cCpo], [ aCampos], [ lInv], [ cMar], < aCord>, [ cTopFun], [ cBotFun], < oWnd>, [ uPar11], [ aColors] ) --> oSelf
	_oBrwNota := MsSelect():New((_cAliasTRB), /*[ cCampo]*/ , /*[ cCpo]*/ ,_aHdTRB,/* [ lInv] */, /* [ cMar] */,{1,1,1,1},,,,,;
		{{"(_cAliasTRB)->IT_STATUS == 'DI'","DISABLE"},{"(_cAliasTRB)->IT_STATUS == 'OK'","ENABLE"},{"(_cAliasTRB)->IT_STATUS == 'IM'","BR_AMARELO"}})
	_oBrwNota:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	Activate MSDialog _oDlg Centered
	
	//restaura area antes de retornar para o sistema
	RestArea(_aArea)
	
	_cTabTemp:Delete()

Return( Nil )

// ** funcao para criar o arquivo de trabalho dos itens da nota
Static Function sfCriaTrb(mvFirst)

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		//adiciona o cabeçalho e a primeira linha
		aAdd(_aCamTRB,{"IT_STATUS"   ,"C",002,000})
		aAdd(_aCamTRB,{"IT_LOG"      ,"C",080,000}) ; aAdd(_aHdTRB,{"IT_LOG"     ,, "Log - Observações"     , "@!"})
		aAdd(_aCamTRB,{"IT_NOME"     ,"C",050,000}) ; aAdd(_aHdTRB,{"IT_NOME"    ,, "Nome"                  , ""})
		aAdd(_aCamTRB,{"IT_SERIE"    ,"C",002,000}) ; aAdd(_aHdTRB,{"IT_SERIE"   ,, "Serie"                 , ""})
		aAdd(_aCamTRB,{"IT_DOC"      ,"C",009,000}) ; aAdd(_aHdTRB,{"IT_DOC"     ,, "Documento"             , ""})
		aAdd(_aCamTRB,{"IT_CHV2"     ,"C",046,000}) ; aAdd(_aHdTRB,{"IT_CHV2"    ,, "Chave acesso"          , ""})
		aAdd(_aCamTRB,{"IT_OP"       ,"C",001,000}) ; aAdd(_aHdTRB,{"IT_OP"      ,, "Op."                   , ""})
		aAdd(_aCamTRB,{"IT_SIT"      ,"C",015,000}) ; aAdd(_aHdTRB,{"IT_SIT"     ,, "Situação"              , ""})
		aAdd(_aCamTRB,{"IT_CHV"      ,"C",046,000}) ; aAdd(_aHdTRB,{"IT_CHV"     ,, "Chave 1"               , ""})
		aAdd(_aCamTRB,{"IT_MODDOC"   ,"C",002,000}) ; aAdd(_aHdTRB,{"IT_MODDOC"  ,, "Mod."                  , ""})
		aAdd(_aCamTRB,{"IT_CODFOR"   ,"C",014,000}) ; aAdd(_aHdTRB,{"IT_CODFOR"  ,, "CNPJ"                  , ""})
		aAdd(_aCamTRB,{"IT_IE"       ,"C",009,000}) ; aAdd(_aHdTRB,{"IT_IE"      ,, "Ins. Est."             , ""})
		aAdd(_aCamTRB,{"IT_UF"       ,"C",002,000}) ; aAdd(_aHdTRB,{"IT_UF"      ,, "UF"                    , ""})
		aAdd(_aCamTRB,{"IT_CODDEST"  ,"C",014,000}) ; aAdd(_aHdTRB,{"IT_CODDEST" ,, "CNPJ Destino"          , ""})
		aAdd(_aCamTRB,{"IT_IEDEST"   ,"C",009,000}) ; aAdd(_aHdTRB,{"IT_IEDEST"  ,, "Ins. Estadual Destino" , ""})
		aAdd(_aCamTRB,{"IT_NOMEDES"  ,"C",050,000}) ; aAdd(_aHdTRB,{"IT_NOMEDES" ,, "Nome destinatario"     , ""})
		aAdd(_aCamTRB,{"IT_UFDEST"   ,"C",002,000}) ; aAdd(_aHdTRB,{"IT_UFDEST"  ,, "UF dest"               , ""})
		aAdd(_aCamTRB,{"IT_EMISSAO"  ,"D",010,000}) ; aAdd(_aHdTRB,{"IT_EMISSAO" ,, "Dt Emissao"            , ""})
		aAdd(_aCamTRB,{"IT_BCICMS"   ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_BCICMS"  ,, "Base ICMS"             , PesqPict("SE2","E2_VALOR")})
		aAdd(_aCamTRB,{"IT_TOTICM"   ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_TOTICM"  ,, "Total ICMS"            , PesqPict("SE2","E2_VALOR")})
		aAdd(_aCamTRB,{"IT_BCICMST"  ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_BCICMST" ,, "Base ICMS ST"          , PesqPict("SE2","E2_VALOR")})
		aAdd(_aCamTRB,{"IT_TOTALST"  ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_TOTALST" ,, "Total ICMS ST"         , PesqPict("SE2","E2_VALOR")})
		aAdd(_aCamTRB,{"IT_VALORNF"  ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_VALORNF" ,, "Valor prod serv"       , PesqPict("SE2","E2_VALOR")})
		aAdd(_aCamTRB,{"IT_FRETE"    ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_FRETE"   ,, "Frete"                 , PesqPict("SE2","E2_VALOR")})
		aAdd(_aCamTRB,{"IT_SEGURO"   ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_SEGURO"  ,, "Seguro"                , PesqPict("SE2","E2_VALOR")})
		aAdd(_aCamTRB,{"IT_DESPAC"   ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_DESPAC"  ,, "Despesas aces."        , PesqPict("SE2","E2_VALOR")})
		aAdd(_aCamTRB,{"IT_IPI"      ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_IPI"     ,, "Valor IPI"             , PesqPict("SE2","E2_VALOR")})
		aAdd(_aCamTRB,{"IT_TOTALNF"  ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_TOTALNF" ,, "Valor total NF"        , PesqPict("SE2","E2_VALOR")})
		aAdd(_aCamTRB,{"IT_DESCO"    ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_DESCO"   ,, "Valor total descontos" , PesqPict("SE2","E2_VALOR")})
		aAdd(_aCamTRB,{"IT_IMP"      ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_IMP"     ,, "Valor total impostos"  , PesqPict("SE2","E2_VALOR")})
		aAdd(_aCamTRB,{"IT_SRVISS"   ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_SRVISS"  ,, "Valor serviços ISS"    , PesqPict("SE2","E2_VALOR")})
		aAdd(_aCamTRB,{"IT_BASEISS"  ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_BASEISS" ,, "Valor base ISS"        , PesqPict("SE2","E2_VALOR")})
		aAdd(_aCamTRB,{"IT_VLRISS"   ,"N",020,002}) ; aAdd(_aHdTRB,{"IT_VLRISS"  ,, "Valor ISS"             , PesqPict("SE2","E2_VALOR")})

		
		// fecha alias do TRB
		If (Select(_cAliasTRB) != 0)
			dbSelectArea(_cAliasTRB)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTabTemp := FWTemporaryTable():New( _cAliasTRB )
		_cTabTemp:SetFields( _aCamTRB )
		_cTabTemp:AddIndex("01", {"IT_DOC"} )
		_cTabTemp:Create()

	EndIf

	// limpa o conteudo do TRB
	If ( ! mvFirst )
		dbSelectArea(_cAliasTRB)
		__DbZap()
	EndIf

	//-- Abre o indice do Arquivo de Trabalho.
	dbSelectArea(_cAliasTRB)
	(_cAliasTRB)->(dbSetOrder(1))
	(_cAliasTRB)->(dbGoTop())

Return( Nil )

// ** funcao para selecionar o arquivo CSV a ser importado
Static Function sfGetFile(mvArquivo)
	Local _nGets

	// busca arquivo CSV
	mvArquivo := cGetFile("Arquivo CSV|*.CSV", ("Selecione arquivo CSV"),,_cDirLocPdr,.f.,GETF_LOCALHARD + GETF_NETWORKDRIVE,.f.)

	// solicita confirmacao da importacao do arquivo
	If ( ! Empty(mvArquivo)).and.(MsgYesNo("Confirma a leitura e validação do arquivo " +AllTrim(mvArquivo)+ " ?"))
		// rotina para ler o arquivo TXT
		MsAguarde({|| sfVldArqui(mvArquivo) },"Validando dados...")
	EndIF

Return( Nil )

// ** funcao para leitura do arquivo CSV e atualizacao do arquivo de trabalho
Static Function sfVldArqui(mvArquivo)

	// variaveis temporarias
	local _vLinha
	local _cTmpLinha
	local _lValida := .T.
	
	//colunas especiais do TRB
	local _cDetLog := ""     // dados do log
	local _cStsAtu := ""  	// status
	local _nLinAtu := 0   	// linha atual

	//variaveis para absorver os dados do TRB
	local _cOP			//operacao
	local _cSIT      	//Situação              
	local _cCHV      	//Chave 1               
	local _cCHV2     	//Chave acesso          
	local _cMODDOC   	//Modelo doc.           
	local _cSERIE    	//Serie                 
	local _cDOC      	//Documento             
	local _cCODFOR   	//CNPJ                  
	local _cIE       	//Ins. Estadual         
	local _cNOME     	//Nome                  
	local _cUF       	//UF                    
	local _cCODDEST  	//CNPJ Destino          
	local _cIEDEST   	//Ins. Estadual Destino 
	local _cNOMEDEST 	//Nome destinatario     
	local _cUFDEST   	//UF dest               
	local _dEMISSAO  	//Dt Emissao            
	local _nBCICMS   	//Base ICMS             
	local _nTOTALICM 	//Total ICMS            
	local _nBCICMST  	//Base ICMS ST          
	local _nTOTALST  	//Total ICMS ST         
	local _nVALORNF  	//Valor prod serv       
	local _nFRETE    	//Frete                 
	local _nSEGURO   	//Seguro                
	local _nDESPAC   	//Despesas aces.        
	local _nIPI      	//Valor IPI             
	local _nTOTALNF  	//Valor total NF        
	local _nDESCONTO 	//Valor total descontos 
	local _nIMPOSTO  	//Valor total impostos  
	local _nSERVISS  	//Valor serviços ISS    
	local _nBASEISS  	//Valor base ISS        
	local _nVLRISS 	    //Valor ISS 

	// zera dados do TRB
	sfCriaTrb(.f.)

	// abre o arquivo TXT
	FT_FUse(mvArquivo)
	FT_FGoTop()

	// varre todas as linhas do arquivo
	While ( ! FT_FEof() )

		// reinicia variaveis
		_lValida	:= .T.
		_cDetLog    :=  ""
		_cOP		:=  ""
		_cSIT      	:=  ""
		_cCHV      	:=  ""
		_cCHV2     	:=  ""
		_cMODDOC   	:=  ""
		_cSERIE    	:=  ""
		_cDOC      	:=  ""
		_cCODFOR   	:=  ""
		_cIE       	:=  ""
		_cNOME     	:=  ""
		_cUF       	:=  ""
		_cCODDEST  	:=  ""
		_cIEDEST   	:=  ""
		_cNOMEDEST 	:=  ""
		_cUFDEST   	:=  ""
		_dEMISSAO  	:=  CtoD("//")
		_nBCICMS   	:=  0
		_nTOTALICM 	:=  0
		_nBCICMST  	:=  0
		_nTOTALST  	:=  0
		_nVALORNF  	:=  0
		_nFRETE    	:=  0
		_nSEGURO   	:=  0
		_nDESPAC   	:=  0
		_nIPI      	:=  0
		_nTOTALNF  	:=  0
		_nDESCONTO 	:=  0
		_nIMPOSTO  	:=  0
		_nSERVISS  	:=  0
		_nBASEISS  	:=  0
		_nVLRISS 	:=  0

		// extrai dados da linha posicionada
		_cTmpLinha := FT_FReadln()

		// descarta linhas em branco
		If (Empty(_cTmpLinha))
			// proxima linha
			FT_FSkip()
			// loop do while
			Loop
		EndIf

		// extrai e separa os dados da linha corrente
		_vLinha := Separa(_cTmpLinha,";")

		// controle de linha
		_nLinAtu ++

		// atualiza variaveis
		_cStsAtu    := "DI"										//padrão é nota não lançada/encontrada, então desativa (bola vermelha)
		_cDetLog	:= "Nota fiscal não encontrada/lançada"		//mensagem padrão
		_cOP		:=  _vLinha[1]
		_cSIT      	:=  _vLinha[2]
		_cCHV      	:=  _vLinha[3]
		_cCHV2     	:=  _vLinha[4]
		_cMODDOC   	:=  _vLinha[5]
		_cSERIE    	:=  AllTrim(_vLinha[6])
		_cDOC      	:=  PadL(_vLinha[7],9,"0")
		_cCODFOR   	:=  PadL(_vLinha[8],14,"0")
		_cIE       	:=  _vLinha[9]
		_cNOME     	:=  _vLinha[10]
		_cUF       	:=  _vLinha[11]
		_cCODDEST  	:=  _vLinha[12]
		_cIEDEST   	:=  _vLinha[13]
		_cNOMEDEST 	:=  _vLinha[14]
		_cUFDEST   	:=  _vLinha[15]
		_dEMISSAO  	:=  CtoD(_vLinha[16])
		_nBCICMS   	:=  Val(_vLinha[17])
		_nTOTALICM 	:=  Val(_vLinha[18])
		_nBCICMST  	:=  Val(_vLinha[19])
		_nTOTALST  	:=  Val(_vLinha[20])
		_nVALORNF  	:=  Val(_vLinha[21])
		_nFRETE    	:=  Val(_vLinha[22])
		_nSEGURO   	:=  Val(_vLinha[23])
		_nDESPAC   	:=  Val(_vLinha[24])
		_nIPI      	:=  Val(_vLinha[25])
		_nTOTALNF  	:=  Val(_vLinha[26])
		_nDESCONTO 	:=  Val(_vLinha[27])
		_nIMPOSTO  	:=  Val(_vLinha[28])
		_nSERVISS  	:=  Val(_vLinha[29])
		_nBASEISS  	:=  Val(_vLinha[30])
		_nVLRISS 	:=  Val(_vLinha[31])
		
		//*** Inicio validações ***
		
		//valida se a linha é o cabeçalho
		If ( Upper(AllTrim(_cOP)) == "OPERACAO" )
			//pula a linha e volta pro laço
			FT_FSkip()
			Loop
		EndIf
		
		//valida cliente
		dbSelectArea("SA1") //clientes
		SA1->(dbSetOrder(3))    //a1_filial + a1_CGC
		SA1->(dbGoTop())
		
		if ( !SA1->( DBSeek( xFilial() + _cCODFOR )) .AND. _lValida)
			_cDetLog := "Não foi encontrado cliente com CNPJ " + _cCODFOR
			
			//se nem encontrou o cliente, nao precisa as outras validações
			_lValida := .F.
		endIf
		
		//procura se nota foi lançada pela chave de acesso
		dbSelectArea("SF1")		//cabeçalho NF de entrada
		SF1->(dbSetOrder(8))	//F1_FILIAL + F1_CHVNFE
		SF1->(dbGoTop())
		
		if ( SF1->( DBSeek( xFilial() + _cCHV2 )) .AND. _lValida )		
			_cDetLog := "Nota lançada em : " + DtoC(SF1->F1_DTDIGIT) + " - Localizada pela chave da DANFE"
			_cStsAtu := "OK"	
			
			//já encontrei a NF, posso pular as demais validações
			_lValida := .F.
		endIf
		
		//procura se nota foi lançada pela número + serie
		SF1->(dbSetOrder(1))	//F1_FILIAL + F1_DOC +  F1_SERIE + F1_FORNECE + F1_LOJA + F1_TIPO
		SF1->(dbGoTop())
		
		//continuo com SA1 posicionada no cliente
		if ( SF1->( DBSeek( xFilial() + _cDOC + _cCODFOR + _cSERIE + SA1->A1_COD + SA1->A1_LOJA)) .AND. _lValida)		
			_cDetLog := "Nota lançada em : " + DtoC(SF1->F1_DTDIGIT) + " - Localizada pelo documento"
			_cStsAtu := "OK"	
			
			//já encontrei a NF, posso pular as demais validações
			_lValida := .F.
		endIf
		
		
		//*** Fim validações de linha ***
		
		//posiciona e trava TRB para inserção
		dbSelectArea(_cAliasTRB)
		RecLock((_cAliasTRB),.t.)
		
		//preenche TRB
		(_cAliasTRB)->IT_STATUS   := _cStsAtu  
		(_cAliasTRB)->IT_OP       := _cOP
		(_cAliasTRB)->IT_SIT      := _cSIT     
		(_cAliasTRB)->IT_CHV      := _cCHV     
		(_cAliasTRB)->IT_CHV2     := _cCHV2    
		(_cAliasTRB)->IT_MODDOC   := _cMODDOC  
		(_cAliasTRB)->IT_SERIE    := _cSERIE   
		(_cAliasTRB)->IT_DOC      := _cDOC     
		(_cAliasTRB)->IT_CODFOR   := _cCODFOR  
		(_cAliasTRB)->IT_IE       := _cIE      
		(_cAliasTRB)->IT_NOME     := _cNOME    
		(_cAliasTRB)->IT_UF       := _cUF      
		(_cAliasTRB)->IT_CODDEST  := _cCODDEST 
		(_cAliasTRB)->IT_IEDEST   := _cIEDEST  
		(_cAliasTRB)->IT_NOMEDES  := _cNOMEDEST
		(_cAliasTRB)->IT_UFDEST   := _cUFDEST  
		(_cAliasTRB)->IT_EMISSAO  := _dEMISSAO 
		(_cAliasTRB)->IT_BCICMS   := _nBCICMS  
		(_cAliasTRB)->IT_TOTICM   := _nTOTALICM
		(_cAliasTRB)->IT_BCICMST  := _nBCICMST 
		(_cAliasTRB)->IT_TOTALST  := _nTOTALST 
		(_cAliasTRB)->IT_VALORNF  := _nVALORNF 
		(_cAliasTRB)->IT_FRETE    := _nFRETE   
		(_cAliasTRB)->IT_SEGURO   := _nSEGURO  
		(_cAliasTRB)->IT_DESPAC   := _nDESPAC  
		(_cAliasTRB)->IT_IPI      := _nIPI     
		(_cAliasTRB)->IT_TOTALNF  := _nTOTALNF 
		(_cAliasTRB)->IT_DESCO    := _nDESCONTO
		(_cAliasTRB)->IT_IMP      := _nIMPOSTO 
		(_cAliasTRB)->IT_SRVISS   := _nSERVISS 
		(_cAliasTRB)->IT_BASEISS  := _nBASEISS 
		(_cAliasTRB)->IT_VLRISS   := _nVLRISS 
		(_cAliasTRB)->IT_LOG      := _cDetLog
		
		//destrava TRB para gravação
		MsUnLock(_cAliasTRB)

		// proxima linha
		FT_FSkip()

	EndDo

	// fecha o arquivo
	ft_FUse()

	//-- Abre o indice do Arquivo de Trabalho.
	dbSelectArea(_cAliasTRB)
	(_cAliasTRB)->(dbSetOrder(1))
	(_cAliasTRB)->(dbGoTop())

Return( Nil )


Static Function sfExpExcel()

	//declara variaveis
	Local _aCab  		:= {}
	Local _aItens		:= {}
	 
	//cabeçalho excel
	aAdd(_aCab,"Log - Observações")
	aAdd(_aCab,"Nome")
	aAdd(_aCab,"Serie")
	aAdd(_aCab,"Num. Documento")
	aAdd(_aCab,"Chave acesso")
	aAdd(_aCab,"Data emissão")
	
	//seleciona a tabela gerada
	dbSelectArea(_cAliasTRB)
	(_cAliasTRB)->(dbGoTop())
	
	Do While (_cAliasTRB)->( !EOF() )
		//se é um registro com "problema" a ser tratado (legenda vermelha)
		If((_cAliasTRB)->IT_STATUS == "DI" )
			aAdd(_aItens, {(_cAliasTRB)->IT_LOG,;
						   (_cAliasTRB)->IT_NOME,;
						   CHR(160) + (_cAliasTRB)->IT_SERIE,;
						   CHR(160) + (_cAliasTRB)->IT_DOC,;
						   CHR(160) + (_cAliasTRB)->IT_CHV2,;
						   (_cAliasTRB)->IT_EMISSAO})
		EndIf

		(_cAliasTRB)->( dbSkip() )
	EndDo

	//gera excel
	MsgRun("Favor Aguardar.....", "Exportando os Registros para o Excel", {|| DlgToExcel({{"ARRAY", "Consulta de NF já lançadas", _aCab, _aItens } } ) } )
	 
Return( Nil )
