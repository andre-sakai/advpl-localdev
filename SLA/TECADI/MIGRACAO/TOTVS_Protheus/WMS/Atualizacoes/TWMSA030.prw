#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSA030                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Geracao de Arquivo EDI - (ENTRADA-SAIDA)                !
!Descricao         ! Este programa ira gerar um arquivo texto, conforme os   !
!Descricao         ! parametros definidos  pelo usuario,  com os registros   !
!Descricao         ! do arquivo de EDI - (ENTRADA-SAIDA)                     !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe Jose Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 09 /2015                                                !
+------------------+--------------------------------------------------------*/

User Function TWMSA030(mvNumOs,mvTpOs)

	//Declaracao de Variaveis
	// grupo de perguntas
	local _cPerg    := PadR("TWMSA030",10)
	local _aPerg    := {}
	Local _cArq     := ""
	Local _nHand    := ""
	Local _cLinha   := ""
	Local _ny       := 0
	Local _cNumCesv := CriaVar("Z05_CESV", .f.)
	// valor padrao
	Default mvNumOs := CriaVar("Z05_NUMOS", .f.)
	Default mvTpOs  := "S"

	// monta a lista de perguntas
	aAdd(_aPerg,{"Num. OS"      ,"C",TamSx3("Z05_NUMOS")[1],0,"G",,""}) //MV_PAR01
	aAdd(_aPerg,{"Num. CESV"    ,"C",TamSx3("ZZ_CESV")[1]  ,0,"G",,""}) //MV_PAR02
	aAdd(_aPerg,{"Tipo Arquivo" ,"N",1                     ,0,"C",{"RECEBIMENTO","EXPEDICAO"},,})//MV_PAR03

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	If Empty(mvNumOs)

		// chama a tela de parametros
		If ! Pergunte(_cPerg,.T.)
			Return
		EndIf

		mvNumOs   := MV_PAR01
		_cNumCesv := MV_PAR02
		mvTpOs    := Iif(MV_PAR03 == 1 ,"E","S")
	EndIf

	// busca Cargas montadas com  os pedidos.
	_cQuery := "SELECT Z05_CESV,ZZ_PLACA1,DA4_NOME,Z05_PROCES,ZZ_CNTR01,Z05_NUMOS,Z07_PALLET,Z07_PLTCLI,Z07_PRODUT,Z07_LOTCTL,Z07_QUANT"
	// cabecalho OS
	_cQuery += " FROM "+RetSqlName("Z05")+" Z05 "

	_cQuery += " INNER JOIN "+RetSqlName("Z07")+" Z07 ON "+RetSqlCond("Z07")+" AND Z05_NUMOS = Z07_NUMOS "

	// itens da ordem de servicos
	_cQuery += " INNER JOIN "+RetSqlName("Z06")+" Z06 ON "+RetSqlCond("Z06")+" AND Z06_NUMOS = Z07_NUMOS AND Z07_SEQOS = Z06_SEQOS AND Z06_TAREFA = '003' "

	// movimentacao de veiculo
	_cQuery += " INNER JOIN "+RetSqlName("SZZ")+" SZZ ON "+RetSqlCond("SZZ")+" AND Z05_CESV = ZZ_CESV "

	// Motoristas
	_cQuery += " LEFT JOIN "+RetSqlName("DA4")+" DA4 ON "+RetSqlCond("DA4")+" AND SZZ.ZZ_MOTORIS = DA4.DA4_COD  "

	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond('Z05')+" "

	If !(Empty(mvNumOs))
		_cQuery += " AND Z05_NUMOS = '"+mvNumOs+"' "
	EndIf
	If !(Empty(_cNumCesv))
		_cQuery += " AND Z05_CESV  = '"+_cNumCesv+"' "
	EndIf
	_cQuery += " AND Z06_STATUS = 'FI' "
	_cQuery += " AND Z05_TPOPER = '"+mvTpOs+"' "

	memowrit("c:\query\TWMSA030.txt",_cQuery)

	// carrega resultado do SQL na variavel.
	_aRetSQL := U_SqlToVet(_cQuery)

	If Len(_aRetSQL) <= 0
		MsgStop("Sem informações para Imprimir")
		Return(.F.)
	EndIf

	//Pasta onde sera salvo o arquivo.
	_cArq := cGetFile( '*.txt' , '', 1, 'C:\', .T., nor( GETF_LOCALHARD, GETF_RETDIRECTORY ),.T., .T. )

	// define nome completo do arquivo a ser gerado
	_cArq := AllTrim(_cArq) + Alltrim(cFilant) + "_" + Alltrim(_aRetSQL[1][01]) + Dtos(dDatabase) + "_" + strTran(Time(),":","")+".txt"

	// tentativa de criacao/gravacao do arquivo
	_nHand	:=	FCREATE(_cArq)

	// testa se o arquivo foi Criado Corretamente
	If (_nHand == -1)
		MsgAlert("O arquivo de nome "+_cArq+" nao pode ser executado! Verifique os parametros.","Atencao!")
		Return(.F.)
	Endif

	// gera o cabecalho do arquivo
	//Header: Id (fixo 0), Número CESV, Placa Veículo, Motorista, Programação, Nr Container, Nr OS
	_cLinha := "0^"
	_cLinha += Alltrim(_aRetSQL[1][01]) + "^"
	_cLinha += Alltrim(_aRetSQL[1][02]) + "^"
	_cLinha += Alltrim(_aRetSQL[1][03]) + "^"
	_cLinha += Alltrim(_aRetSQL[1][04]) + "^"
	_cLinha += Alltrim(_aRetSQL[1][05]) + "^"
	_cLinha += Alltrim(_aRetSQL[1][06]) + ""
	_cLinha += CRLF

	FWrite(_nHand,_cLinha)

	// varre todos os itens do pedido
	For _ny := 1 to Len(_aRetSQL)

		// gera linha dos Itens
		//Itens: Id (fixo 1), Id Palete Tecadi, Id Palete Cliente, Produto, Lote, Quantidade/Peso.
		_cLinha := "1^"
		_cLinha += Alltrim(_aRetSQL[_ny][07]) + "^"
		_cLinha += Alltrim(_aRetSQL[_ny][08]) + "^"
		_cLinha += Alltrim(_aRetSQL[_ny][09]) + "^"
		_cLinha += Alltrim(_aRetSQL[_ny][10]) + "^"
		_cLinha += Alltrim(Transform(_aRetSQL[_ny][11],PesqPict("Z07","Z07_QUANT"))) + ""
		_cLinha += CRLF
		FWrite(_nHand,_cLinha)

	Next _ny

	//Fecha Arquivo
	FClose(_nHand)

	ApMsgAlert("Arquivo gerado com sucesso !")

Return()