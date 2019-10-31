#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSA026                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Enviar informações do processo de expedição para o      !
!                  ! cliente via TXT.                                        !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe Jose Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/2015                                                !
+------------------+--------------------------------------------------------*/

User Function TWMSA026(mvRotAuto, mvFTPAuto)
	// grupo de perguntas
	local _cPerg := PadR("TWMSA026",10)
	local _aPerg := {}
	Local _cArq  := ""
	local lRet := .T.

	// opcoes de nome de arquivo de saida
	local _aOpcArqSai := {"Fil+Data+Hora",;    // 1
	"Agrupadora",;       // 2
	"Chv Nfe Retorno",;  // 3
	"Pedido Cliente"}    // 4
	
	private _lRotAuto := mvRotAuto
	private _lFTPAuto := mvFTPAuto
	
	Default mvRotAuto := .F.     // se é rotina automatizada
	Default mvFTPAuto := .F.     // se envia por FTP ao invés de solicitar onde salvar

	// monta a lista de perguntas
	aAdd(_aPerg,{"Cliente De:"           , "C",TamSx3("A1_COD")[1]     ,0,"G",Nil        ,"SA1"}) //mv_par01
	aAdd(_aPerg,{"Loja De:"              , "C",TamSx3("A1_LOJA")[1]    ,0,"G",Nil        ,""   }) //mv_par02
	aAdd(_aPerg,{"Cliente Até:"          , "C",TamSx3("A1_COD")[1]     ,0,"G",Nil        ,"SA1"}) //mv_par03
	aAdd(_aPerg,{"Loja Até:"             , "C",TamSx3("A1_LOJA")[1]    ,0,"G",Nil        ,""   }) //mv_par04
	aAdd(_aPerg,{"Nr. CESV:"             , "C",TamSx3("Z04_CESV")[1]   ,0,"G",Nil        ,""   }) //mv_par05
	aAdd(_aPerg,{"Agrupadora:"           , "C",TamSx3("C5_ZAGRUPA")[1] ,0,"G",Nil        ,""   }) //mv_par06
	aAdd(_aPerg,{"Pedido De:"            , "C",TamSx3("C5_NUM")[1]     ,0,"G",Nil        ,"SC5"}) //mv_par07
	aAdd(_aPerg,{"Pedido Até:"           , "C",TamSx3("C5_NUM")[1]     ,0,"G",Nil        ,"SC5"}) //mv_par08
	aAdd(_aPerg,{"NF Venda cliente De:"  , "C",TamSx3("C5_NUM")[1]     ,0,"G",Nil        ,"SC5"}) //mv_par09
	aAdd(_aPerg,{"NF Venda cliente Até:" , "C",TamSx3("C5_NUM")[1]     ,0,"G",Nil        ,"SC5"}) //mv_par10
	aAdd(_aPerg,{"Nome Arq. Saída:"      , "N",1                       ,0,"C",_aOpcArqSai,""   }) //mv_par11

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	If !(mvRotAuto)  // se não for rotina automatica
		// chama a tela de parametros
		If ! Pergunte(_cPerg, .T.)
			Return ( .F. )
		EndIf
	Else    // é rotina automatica, chamada do menu de pedido de venda
		Pergunte(_cPerg, .F.)    //carrega perguntas em memória

		// substitui pelos dados do pedido posicionado
		MV_PAR01 := MV_PAR03 := SC5->C5_CLIENTE      // cliente de / até
		MV_PAR02 := MV_PAR04 := SC5->C5_LOJACLI      // loja de/até
		MV_PAR05 := MV_PAR06 := MV_PAR09 := ""       // CESV / agrupadora / NF cliente DE
		MV_PAR07 := MV_PAR08 := SC5->C5_NUM          // pedido de/até
		MV_PAR10 := "ZZZZZZ"                         // NF cliente até
		MV_PAR11 := 4                                // nomenclatura de saída do arquivo, 4 = número pedido cliente

	EndIf

	//Pasta onde sera salvo o arquivo.
	IF (!mvFTPAuto)
		_cArq := cGetFile( '*.txt' , '', 1, 'C:\', .T., nor( GETF_LOCALHARD, GETF_RETDIRECTORY ),.T., .T. )
	Else
		_cArq := "C:\TEMP\EDI\"
	EndIf
	
	lRet := MsgRun("Por Favor Aguarde... Executando consulta no banco de dados...", "Executando consulta no banco de dados",{||fGetDados(_cArq)})
	
Return lRet

Static Function fGetDados(_cArq)
	local lRet := .T.
	
	Private _aPedCa := {}
	
	// busca Pedidos.
	_cQuery := " SELECT C5_NUM, C9_CARGA, DAK_DATA, C5_EMISSAO, C5_VOLUME1, C5_PESOL, C5_PBRUTO, C5_CUBAGEM, C5_ZPEDCLI, C6_ITEM, C6_PRODUTO, C6_DESCRI, C6_QTDVEN, C5_ZAGRUPA, C5_ZCHVNFV, F2_CHVNFE, Z58_CODIGO"
	
	//Cabeçalho Pedido de Venda
	_cQuery += " FROM "+RetSqlTab("SC5") + " (nolock) "
	
	//itens Pedido
	_cQuery += " INNER JOIN " + RetSqlTab("SC6") + " (nolock) ON " + RetSqlCond("SC6") + " AND SC5.C5_NUM = SC6.C6_NUM "
	
	//itens liberados por pedido
	_cQuery += " INNER JOIN " + RetSqlTab("SC9") + " (nolock) ON " + RetSqlCond("SC9") + " AND SC5.C5_NUM = SC9.C9_PEDIDO AND SC6.C6_ITEM = SC9.C9_ITEM "
	// somente com nota fiscal
	_cQuery += " AND C9_NFISCAL != ' ' "
	
	// cabecalho da nota fiscal de retorno
	_cQuery += " INNER JOIN " + RetSqlTab("SF2") + " (nolock) ON " + RetSqlCond("SF2") + " AND F2_DOC = C9_NFISCAL AND F2_SERIE = C9_SERIENF AND F2_CLIENTE = C9_CLIENTE AND F2_LOJA = C9_LOJA "
	
	// cabecalho de cargas
	_cQuery += " LEFT JOIN " + RetSqlTab("DAK") + " (nolock) ON " + RetSqlCond("DAK") + " AND SC9.C9_CARGA = DAK.DAK_COD AND SC9.C9_SEQCAR = DAK.DAK_SEQCAR "
	
	// onda de separação
	_cQuery += " LEFT JOIN " + RetSqlTab("Z58") + " (nolock) ON " + RetSqlCond("Z58") + " AND Z58.Z58_PEDIDO = SC5.C5_NUM "
	
	// WMS - ORDEM DE SERVICO
	_cQuery += " INNER JOIN " + RetSqlTab("Z05")+" (nolock) ON " + RetSqlCond("Z05") + " AND ( Z05.Z05_ONDSEP = Z58.Z58_CODIGO OR SC9.C9_CARGA = Z05.Z05_CARGA ) "
	//Filtro Cesv
	If ! Empty(mv_par05)
		_cQuery += " AND Z05.Z05_CESV = '" + mv_par05 + "'"
	EndIF
	
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond('SC5')
	
	//Filtro cliente.
	_cQuery += " AND SC5.C5_CLIENTE BETWEEN '"+mv_par01+"' AND '"+mv_par03+"' "
	//Filtro Loja
	_cQuery += " AND SC5.C5_LOJACLI BETWEEN '"+mv_par02+"' AND '"+mv_par04+"' "
	
	//Filtro Agrupadora
	If ! Empty(mv_par06)
		_cQuery += " AND SC5.C5_ZAGRUPA       = '"+mv_par06+"'"
	EndIF
	
	//Filtro numero do PV
	_cQuery += " AND SC5.C5_NUM     BETWEEN '"+mv_par07+"' AND '"+mv_par08+"' "
	
	//Filtro numero da nota fiscal de venda do CLIENTE
	_cQuery += " AND SC5.C5_ZDOCCLI BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "' "
	
	// Tipo de pedido: Produto
	_cQuery += " AND SC5.C5_TIPOOPE = 'P' "
	
	// ordem dos dados
	_cQuery += " ORDER BY C5_NUM,C6_ITEM "
	
	memowrit("c:\query\twmsa026.txt",_cQuery)
	
	// carrega resultado do SQL na variavel.
	_aPedCa := U_SqlToVet(_cQuery)
	
	lRet := fGeraArq(_cArq)
	
Return lRet

Static Function fGeraArq(mvcArq)
	local _cArq := mvcArq
	local _aArq := {}
	Local _nHand
	Local _ny
	// variaveis de controle
	local _cChvPedido
	// dados temporario para geracao da linha
	local _cLinha
	
	local _cPedAtu := ""
	
	// valida quantidade de dados no vetor
	If (Len(_aPedCa) == 0) 
		IF !(_lRotAuto)
			Aviso("TWMSA026","Não foram encontrados dados para gerar o arquivo. Verifique os parâmetros informados.",{"Fechar"})
		EndIf
		Return( .F. )
	EndIf
	
	// percore todos os registros
	For _nX := 1 To Len(_aPedCa)
		// só criar um novo arquivo, caso seja um novo pedido
		If _cPedAtu <> _aPedCa[_nX][1]
			_cPedAtu := _aPedCa[_nX][1]
			// define nome completo do arquivo a ser gerado
			If (MV_PAR11 == 1)
				// sistema aguarda 2 segundos para evitar de criar arquivos com o mesmo segundo, e assim reescrever o anterior
				Sleep(2000)
				_cArq := AllTrim(mvcArq) + cFilant + "_" + Dtos(dDatabase) + "_" + strTran(Time(),":","")+".txt"
			ElseIf (MV_PAR11 == 2)
				// valida caracteres especiais
				If (Empty(mv_par06)).or.( ! sfVldArqSai(mv_par06) )
					MsgAlert("Agrupadora não informada, ou contém caracteres inválidos","Atencao!")
					Return( .F. )
				EndIf
		
				// define nome do arquiv
				_cArq := AllTrim(mvcArq) + AllTrim(mv_par06) + ".txt"
			EndIf
			
			If (MV_PAR11 == 3)    // opção de gerar o nome do arquivo de saída com a chave da NF retorno
				If !(Empty(_aPedCa[_nX][16]))
					_cArq := AllTrim(mvcArq) + _aPedCa[_nX][16] + ".txt"
				Else
					If !(_lRotAuto)
						Aviso("TWMSA026","Chave da nota fiscal de saída não localizada. Verifique se o pedido já foi faturado e a NF transmitida.",{"Fechar"})
					EndIf
					Return( .F. )
				EndIf
			Elseif (MV_PAR11 == 4)    // opção de gerar o nome do arquivo de saída com o numero do pedido do cliente
				If !(Empty(_aPedCa[_nX][9]))
					_cArq := AllTrim(mvcArq) + AllTrim(_aPedCa[_nX][9]) + ".txt"
				Else
					If !(_lRotAuto)
						Aviso("TWMSA026","Pedido do cliente não localizado. Verifique se os dados foram informados/importados no pedido Tecadi.",{"Fechar"})
					EndIf
					Return( .F. )
				EndIf
			EndIf
			// tentativa de criacao/gravacao do arquivo
			_nHand	:= FCREATE(_cArq)
			
			// testa se o arquivo foi Criado Corretamente
			If (_nHand == -1)
				If !(_lRotAuto)
					MsgAlert("O arquivo de nome " + _cArq + " não pôde ser criado! Verifique os parâmetros da rotina ou as permissões de escrita da pasta destino.","Atencao!")
				EndIf
				Return( .F. )
			Endif
			
			// gera o cabecalho geral do arquivo
			_cLinha := "0^"
			_cLinha += Alltrim(SM0->M0_CGC)              + "^"
			_cLinha += Alltrim(_aPedCa[_nX][2])            + "^"
			_cLinha += Dtoc(Stod(Alltrim(_aPedCa[_nX][3])))+ "^"
			_cLinha += Alltrim(_aPedCa[_nX][14])
			_cLinha += CRLF
			FWrite(_nHand,_cLinha)
		EndIf
		
		// varre todos os itens do pedido
		For _ny := 1 to Len(_aPedCa)
			If _cPedAtu == _aPedCa[_ny][1]
				// verifica se deve gerar dados do cabecalho do pedido
				If (_cChvPedido <> _aPedCa[_ny][1])
		
					// cubagem calculada por embalagem
					_aPedCa[_ny][8] := sfRetCubEmb(_aPedCa[_ny][1], _aPedCa[_ny][2], _aPedCa[_ny][17])
		
					// gera linha do cabecalho
					_cLinha := "1^"
					_cLinha += Alltrim(_aPedCa[_ny][1])                                         + "^"
					_cLinha += Dtoc(Stod(Alltrim(_aPedCa[_ny][3])))                             + "^"
					_cLinha += Alltrim(Transform(_aPedCa[_ny][5],PesqPict("SC5","C5_VOLUME1"))) + "^"
					_cLinha += Alltrim(Transform(_aPedCa[_ny][6],PesqPict("SC5","C5_PESOL")))   + "^"
					_cLinha += Alltrim(Transform(_aPedCa[_ny][7],PesqPict("SC5","C5_PBRUTO")))  + "^"
					_cLinha += Alltrim(Transform(_aPedCa[_ny][8],PesqPict("SC5","C5_CUBAGEM"))) + "^"
					_cLinha += Alltrim(_aPedCa[_ny][ 9])                                        + "^"
					_cLinha += Alltrim(_aPedCa[_ny][15])                                        + "^"
					_cLinha += Alltrim(_aPedCa[_ny][16])
					_cLinha += CRLF
					FWrite(_nHand,_cLinha)
		
					// atualiza chave do pedido
					_cChvPedido := _aPedCa[_ny][1]
		
				EndIf
		
				// gera linha dos itens do pedido
				_cLinha := "2^"
				_cLinha += Alltrim(_aPedCa[_ny][10])+"^"
				_cLinha += Alltrim(_aPedCa[_ny][11])+"^"
				_cLinha += Alltrim(_aPedCa[_ny][12])+"^"
				_cLinha += Alltrim(Transform(_aPedCa[_ny][13],PesqPict("SC6","C6_QTDVEN")))+"^"
				_cLinha += Alltrim(Transform(_aPedCa[_ny][13],PesqPict("SC6","C6_QTDVEN")))+""
				_cLinha += CRLF
				FWrite(_nHand,_cLinha)
			EndIf
		
		Next _ny
		//Fecha Arquivo
		FClose(_nHand)
		AADD(_aArq,{_cArq})
	Next _nX

	For _nA := 1 To Len(_aArq)
		If (_lRotAuto) .AND. (_lFtpAuto)
			// se for FTP e cliente for danuri
			If(mv_par01 == "000547") .AND. (mv_par03 == "000547")
				U_FTPSend('10.3.0.211', 21, 'luminatti', '7Usp8tUwat&a', '/EDI/expedicao/', _aArq[_nA], .T.)
				FErase(_aArq[_nA])  // apaga o arquivo gerado do disco
			EndIf
		EndIf
	
		If (mv_par01 == "000547") .AND. (mv_par03 == "000547") .AND. !(_lRotAuto)
			//FTPCON( cEndereco, nPorta, cUsr, cPass, cPastaFTP, cArq, lAuto)
			MsgRun("Enviando arquivo para o FTP...",,{|| U_FTPSend('10.3.0.211', 21, 'luminatti', '7Usp8tUwat&a', '/EDI/expedicao/', _aArq[_nA], .T.) })
		EndIf
	Next _nA

	if !(_lRotAuto)
		ApMsgAlert("Arquivo gerado com sucesso !")
	EndIf

Return ( .T. )

// ** funcao que calcula a cubagem por embalagem
Static Function sfRetCubEmb(mvPedido, mvCarga, mvOndaSep)
	// variavel de retorno
	local _nRet := 0
	// query
	local _cQuery
	// dados temporarios
	local _aDadosCub := {}

	// monta a query para buscar os volumes por pedido
	_cQuery := "SELECT Z07_ETQVOL, Z31_CUBAGE "

	// cab. da OS
	_cQuery += " FROM "+RetSqlName("Z05")+" Z05 (nolock) "

	// cad. clientes
	_cQuery += " INNER JOIN "+RetSqlName("SA1")+" SA1 (nolock) ON "+RetSqlCond("SA1")+" AND A1_COD = Z05_CLIENT AND A1_LOJA = Z05_LOJA "

	// itens da OS, somente rotina de montagem de volumes
	_cQuery += " INNER JOIN "+RetSqlName("Z06")+" Z06 (nolock) ON "+RetSqlCond("Z06")+" AND Z06_NUMOS = Z05_NUMOS AND Z06_SERVIC = '001' AND Z06_TAREFA = '007' "

	// itens conferidos/volumes montados
	_cQuery += " INNER JOIN "+RetSqlName("Z07")+" Z07 (nolock) ON "+RetSqlCond("Z07")+" AND Z07_NUMOS = Z06_NUMOS AND Z07_SEQOS = Z06_SEQOS "
	// pedido
	_cQuery += " AND Z07_PEDIDO = '"+mvPedido+"' "

	// cad. embalagens
	_cQuery += " INNER JOIN "+RetSqlName("Z31")+" Z31 (nolock) ON "+RetSqlCond("Z31")+" AND Z31_CODIGO = Z07_EMBALA AND Z31_SIGLA = A1_SIGLA "

	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z05")+" "

	// filtro por carga ou onda de separação
	IF !( Empty(mvOndaSep) )
		_cQuery += " AND Z05_ONDSEP = '" + mvOndaSep + "' "
	Else
		_cQuery += " AND Z05_CARGA = '" + mvCarga + "' "
	EndIf

	// agrupa dados
	_cQuery += " GROUP BY Z07_ETQVOL, Z31_CUBAGE "

	memowrit("c:\query\twmsa026_sfRetCubEmb.txt", _cQuery)

	// atualiza vetor
	_aDadosCub := U_SqlToVet(_cQuery)

	// calcula a quantidade total de palete
	aEval(_aDadosCub,{|x| _nRet += x[2] })

Return(_nRet)

// ** funcao que valida caracteres especiais no nome do arquivo
Static Function sfVldArqSai(mvNomeArq)

	// caracteres especiais
	local _cCharEsp := 'ÁÉÍÓÚÂÊÎÔÛÃÕÜÇ.&/_"!@#$%¨&*{}[]?/;:><|\À,~^´`+='
	// variavel de retorno
	local _lRet := .t.
	// variaveis temporarias
	local _nX

	For _nX := 1 to Len(mvNomeArq)
		// valida o caracter
		If (SubStr(mvNomeArq, _nX, 1) $ _cCharEsp)
			_lRet := .f.
			Exit
		EndIf
	Next _nX

Return(_lRet)