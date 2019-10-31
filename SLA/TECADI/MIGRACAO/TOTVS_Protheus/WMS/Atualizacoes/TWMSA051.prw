#Include 'Protheus.ch'

/*/{Protheus.doc} TWMSA051
Função destinada a endereçar automaticamente produtos com base em uma OS.
@type function
@author Luiz Fernando Berti
@since 15/07/2019
/*/
User Function TWMSA051(mvNumos, mvSeqOS)

	LOCAL cNumOs    := mvNumos
	LOCAL cSeqOS    := mvSeqOS
	LOCAL cQuery    := ""
	LOCAL _aEnd     := {}
	LOCAL nQtde     := 0
	LOCAL cDocumen  := "" 
	LOCAL cCliente  := ""
	LOCAL cLoja     := ""
	LOCAL _lArmExp  := .F.
	LOCAL aRecnoZ08 := {}
	Local _dDataIN := Date()
	Local _cHoraIN := Time()
	
	//valida se sequência 01 já está finalizada
	DBSelectArea("Z05")
	Z05->(DBSetOrder(1))   // 1 - Z05_FILIAL, Z05_NUMOS, R_E_C_N_O_, D_E_L_E_T_
	Z05->(MsSeek( xFilial("Z05") + mvNumos ) )
	
	cCliente := Z05->Z05_CLIENT
	cLoja    := Z05->Z05_LOJA
	
	_lArmExp := U_FtWmsParam("WMS_PERMITE_ARMAZENAMENTO_EXPRESSO","L",.F.,.F.,Nil, cCliente, cLoja, Nil, Nil)
	
	If (!_lArmExp)
		U_FtWmsMsg("Cliente não configurado para realizar Armazenamento Expresso.", "Armazenamento Expresso", .F., .F.)  
		Return
	Endif

	//valida se sequência 01 já está finalizada
	DBSelectArea("Z06")
	Z06->(DBSetOrder(1))   // 1 - Z06_FILIAL, Z06_NUMOS, Z06_SEQOS, R_E_C_N_O_, D_E_L_E_T_
	Z06->(MsSeek(xFilial("Z06") + mvNumos + "001"))

	// Se OS não está finalizada
	If (Z06->Z06_STATUS != "FI")
		U_FtWmsMsg("A conferência da ordem de serviço não está finalizada. Finalize antes de usar esta rotina.", "Armazenamento Expresso", .F., .F.)  
		Return
	Else
		// reposiciona na sequência correta
		Z06->(MsSeek(xFilial("Z06") + mvNumos + mvSeqOS))
	EndIf

	DBSelectArea("SDA")
	//DBSelectArea("Z06")
	DBSelectArea("Z08")
	SDA->(DBSetOrder(01))  // 01 - DA_FILIAL+DA_PRODUTO+DA_LOCAL+DA_NUMSEQ+DA_DOC+DA_SERIE+DA_CLIFOR+DA_LOJA

	//Verifica se há endereços diferentes.
	cQuery:= "SELECT DISTINCT Z08_ENDDES, Z08_LOCAL"
	cQuery+= " FROM "+RetSQLTab("Z08")
	cQuery+= " WHERE " + RetSqlCond("Z08")
	cQuery+= " AND Z08_NUMOS = '"+cNumOs+"' "
	cQuery+= " AND Z08_SEQOS = '"+cSeqOS+"' "

	_aEnd := U_SqlToVet(cQuery)
	memowrit("c:\query\twmsa051_enderecos_diferentes.txt", cQuery)

	// testa se retornou mais de um endereço
	If Len(_aEnd) > 1
		U_FtWmsMsg("Há mais de um endereço para a OS."+CRLF+" Não é possível realizar o endereçamento expresso.", "Armazenamento Express", .F., .F.)  
		Return
	Elseif Len(_aEnd) == 0
		U_FtWmsMsg("A ordem de serviço selecionada não possui mapa de armazenagem gerado!.", "Armazenamento Express", .F., .F.)  
		Return
	EndIf

	// valida se endereço é um blocado
	If (GetAdvFVal("SBE", "BE_ESTFIS", xFilial("SBE") + _aEnd[1][2] + _aEnd[1][1], 1) != "000007") // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ, BE_ESTFIS, R_E_C_N_O_, D_E_L_E_T_
		U_FtWmsMsg("Endereço destino da OS não é um blocado."+CRLF+" Não é possível realizar o endereçamento expresso.", "Armazenamento Expresso", .F., .F.)  
		Return
	EndIf
	
	
	// Query para pegar o docmento de entrada
	cQuery := " SELECT F1_DOC "
	cQuery += " FROM " + RetSQLTab("SF1")
	cQuery += " WHERE " + RetSqlCond("SF1")
	cQuery += "        AND F1_FORNECE = '" + cCliente + "' "
	cQuery += "        AND F1_LOJA = '" + cLoja + "' "
	cQuery += "        AND F1_TIPO = 'B' "
	cQuery += "        AND F1_ZOBS = 'OS:" + AllTrim(mvNumos) + "' "
	
	cDocumen := U_SqlToVet(cQuery)
	memowrit("c:\query\twmsa051_documento_entrada.txt", cQuery)
	
	
	//Busca as movimentações do WMS
	cQuery:= " SELECT DISTINCT Z08_FILIAL, Z08_PRODUT,Z08_ENDSRV,Z08_ENDDES,Z08_LOCAL, SUM(Z07_QUANT) Z08_QUANT,Z08_DOC,Z08_SERIE,Z08_NUMSEQ,Z05_CLIENT,Z05_LOJA,Z08_NUMOS,"
	cQuery+= " Z08_SEQOS " //, Z08.R_E_C_N_O_ REGZ08, Z06.R_E_C_N_O_ REGZ06 "
	cQuery+= " FROM " + RetSQLTab("Z08")
	cQuery+= " INNER JOIN " + RetSQLTab("Z05")
	cQuery+= "     ON " + RetSqlCond("Z05")
	cQuery+= "     AND Z05_FILIAL = Z08_FILIAL "
	cQuery+= "     AND Z05_NUMOS = Z08_NUMOS "
	cQuery+= " INNER JOIN " + RetSQLTab("Z06")
	cQuery+= "     ON " + RetSqlCond("Z06")
	cQuery+= "       AND Z06_FILIAL = Z08_FILIAL "
	cQuery+= "       AND Z06_NUMOS = Z08_NUMOS "
	cQuery+= "       AND Z06_TAREFA = '009' " // endereçamento
	cQuery+= "       AND Z06_SERVIC IN ('015','003') " // pre-conferencia
	cQuery+= " INNER JOIN " + RetSQLTab("Z07")
    cQuery+= "    ON " + RetSqlCond("Z07")
    cQuery+= "       AND Z07_NUMOS = Z08_NUMOS "
    cQuery+= "       AND Z07_PRODUT = Z08_PRODUT "
    cQuery+= "       AND Z07_NUMSEQ = Z08_NUMSEQ "
	cQuery+= " WHERE " + RetSqlCond("Z08")
	cQuery+= "   AND Z08_NUMOS = '"+cNumOs+"' "
	cQuery+= "   AND Z08_SEQOS = '"+cSeqOS+"' "
	cQuery+= "   GROUP BY 		"
	cQuery+= "   Z07_PALLET,	"
	cQuery+= "   Z08_FILIAL,	"
    cQuery+= "   Z08_PRODUT,	"
    cQuery+= "   Z08_ENDSRV,	"
    cQuery+= "   Z08_ENDDES,	"
    cQuery+= "   Z08_LOCAL,		"
    cQuery+= "   Z08_QUANT,		"
    cQuery+= "   Z08_DOC,		"
    cQuery+= "   Z08_SERIE,		"
    cQuery+= "   Z08_NUMSEQ,	"
    cQuery+= "   Z05_CLIENT,	"
    cQuery+= "   Z05_LOJA,		"
    cQuery+= "   Z08_NUMOS,		"
    cQuery+= "   Z08_SEQOS		"
	cQuery+= " ORDER BY Z08_FILIAL,Z08_NUMOS "
	
	memowrit("c:\query\twmsa051_movimentacoes_mapa.txt", cQuery)
	
	If Select("TRBZ08") <> 0
		DBSelectArea("TRBZ08")
		DBCloseArea()
	EndIf

	DBUseArea(.T., "TOPCONN", TCGenQry(NIL,NIL,cQuery), "TRBZ08" , .F., .T. )
	TRBZ08->(DBEval( { || nQtde++  } ))//Contador para régua de processamento.
	TRBZ08->(DBGoTop())

	// calcula régua de processamento
	ProcRegua(nQtde)
	
	

	// confirma e dale!
	If U_FTYesNoMsg("Endereçando OS "+cNumOs+" no endereço " + _aEnd[1][1] + CRLF + "Deseja continuar?", "Endereçamento Expresso")
		Begin Transaction
			// percorre toda a ordem de serviço
			Do While !TRBZ08->( Eof() )
				IncProc()
				If SDA->( MSSeek(xFilial("SDA") + TRBZ08->(Z08_PRODUT + Z08_LOCAL + AllTrim(Z08_NUMSEQ) )))

					If SDA->DA_SALDO <= 0
						TRBZ08->( DBSkip() )
						Loop
					EndIf

					// pesquisa a ultimo item utilizado
					cItemDB := Soma1(A265UltIt('C'))			

					// zera variaveis
					aCabSDA  := {}
					aItemSDB := {}

					// cabecalho de movimentacao da mercadoria
					aCabSDA := {{"DA_FILIAL",SDA->DA_FILIAL ,NIL},;
					{"DA_PRODUTO"	,SDA->DA_PRODUTO,NIL},;
					{"DA_QTDORI"	,SDA->DA_QTDORI	,NIL},;
					{"DA_SALDO"		,SDA->DA_SALDO	,NIL},;
					{"DA_DATA"		,dDataBase		,NIL},;
					{"DA_LOTECTL"	,SDA->DA_LOTECTL,NIL},;
					{"DA_DOC"		,SDA->DA_DOC	,NIL},;
					{"DA_SERIE"		,SDA->DA_SERIE	,NIL},;
					{"DA_CLIFOR"	,SDA->DA_CLIFOR	,NIL},;
					{"DA_LOJA"		,SDA->DA_LOJA	,NIL},;
					{"DA_TIPONF"	,SDA->DA_TIPONF	,NIL},;
					{"DA_NUMSEQ"	,SDA->DA_NUMSEQ	,NIL},;
					{"DA_LOCAL"		,SDA->DA_LOCAL	,NIL},;
					{"DA_ORIGEM"	,SDA->DA_ORIGEM	,NIL}}

					// item da movimentacao da mercadoria
					Aadd(aItemSDB,{{"DB_FILIAL",xFilial("SDB"),NIL},;
					{"DB_ITEM"		,cItemDB			,NIL},;
					{"DB_LOCAL"		,SDA->DA_LOCAL		,NIL},;
					{"DB_ESTORNO"	," "				,Nil},;
					{"DB_LOCALIZ"	,TRBZ08->Z08_ENDDES	,NIL},;
					{"DB_PRODUTO"	,SDA->DA_PRODUTO	,NIL},;
					{"DB_DOC"		,SDA->DA_DOC		,NIL},;
					{"DB_SERIE"		,SDA->DA_SERIE		,NIL},;
					{"DB_NUMSEQ"	,SDA->DA_NUMSEQ	    ,NIL},;
					{"DB_DATA"		,dDataBase			,NIL},;
					{"DB_QUANT"		,TRBZ08->Z08_QUANT	,NIL},;
					{"DB_ZNUMOS"	,TRBZ08->Z08_NUMOS	,NIL},;
					{"DB_ZSEQOS"	,TRBZ08->Z08_SEQOS	,NIL},;
					{"DB_ZLOTECT"	,SDA->DA_LOTECTL	,NIL}})

					// executa funcao padrao de distribuicao da mercadoria
					lMsErroAuto := .F.
					MSExecAuto({|x,y,z| mata265(x,y,z)},aCabSDA,aItemSDB,3) //Distribui

					// se ocorreu erro na rotina automatica
					If (lMsErroAuto)
						DisarmTransaction()
						U_FtWmsMsg(sfAchaErro(),"ATENCAO")
						Exit
					Else
						cQuery := " UPDATE Z08010 "
						cQuery += " SET    Z08_STATUS = 'R', "
						cQuery += "        Z08_ENDSRV = Z08_ENDDES, "
						cQuery += "        Z08_DTINIC = '" + DtoS(_dDataIN) + "', "
						cQuery += "        Z08_DTFINA = '" + DtoS(Date()) + "', "
						cQuery += "        Z08_HRINIC = '" + Substr(_cHoraIN,1,5) + "', "
						cQuery += "        Z08_HRFINA = '" + Substr(Time(),1,5) + "', "
						cQuery += "        Z08_USUARI = '" + __cUserID + "' "
						cQuery += " WHERE  Z08_FILIAL = '" + TRBZ08->Z08_FILIAL + "' "
						cQuery += "        AND Z08_NUMOS = '" + TRBZ08->Z08_NUMOS + "' "
						cQuery += "        AND Z08_SEQOS = '" + TRBZ08->Z08_SEQOS + "' "
						cQuery += "        AND Z08_LOCAL = '" + TRBZ08->Z08_LOCAL + "' "
						cQuery += "        AND Z08_PRODUT = '" + SDA->DA_PRODUTO + "' "
						cQuery += "        AND Z08_NUMSEQ = '" + Alltrim(TRBZ08->Z08_NUMSEQ) + "' "
						cQuery += "        AND D_E_L_E_T_ = '' "
						IF ( TcSQLExec(cQuery) < 0 )
							DisarmTransaction()
							U_FtWmsMsg("Falha ao atualizar o mapa de apanhe." + CRLF + "OS: " + cNumOs + CRLF + "Produto:" + AllTrim(SDA->DA_PRODUTO) ,"ERRO TWMSA051 - UPD Z08")
							Exit
						EndIf
						
						//WMS - CONFERENCIA MERCADORIA  
						cQuery:= "UPDATE "+RetSQLName("Z07")
						cQuery+= " SET Z07_ENDATU = '"+TRBZ08->Z08_ENDDES+"', Z07_STATUS = 'A'"
						cQuery+= " WHERE Z07_FILIAL = '"+TRBZ08->Z08_FILIAL+"' "
						cQuery+= " AND Z07_NUMOS = '"+TRBZ08->Z08_NUMOS+"' "
						cQuery+= " AND Z07_SEQOS = '001' " 
						cQuery+= " AND Z07_PRODUT = '"+SDA->DA_PRODUTO+"' "
						cQuery+= " AND Z07_NUMSEQ = '" + Alltrim(TRBZ08->Z08_NUMSEQ) + "' "
						cQuery+= " AND D_E_L_E_T_ = '' "				
						IF ( TcSQLExec(cQuery) < 0 )
							DisarmTransaction()
							U_FtWmsMsg("Erro ao atualizar dados da conferência." + CRLF + "OS: " + cNumOs + CRLF + "NUMSEQ:" + AllTrim(TRBZ08->Z08_NUMSEQ) ,"ERRO TWMSA051 - UPD Z07")
							Exit
						EndIf
						
						
						//WMS - CONFERENCIA MERCADORIA  
						cQuery:= "UPDATE "+RetSQLName("Z07")
						cQuery+= " SET Z07_ENDATU = '"+TRBZ08->Z08_ENDDES+"', Z07_STATUS = 'A'"
						cQuery+= " WHERE Z07_FILIAL = '"+TRBZ08->Z08_FILIAL+"' "
						cQuery+= " AND Z07_NUMOS = '"+TRBZ08->Z08_NUMOS+"' "
						cQuery+= " AND Z07_SEQOS = '001' " 
						cQuery+= " AND Z07_PRODUT = '"+SDA->DA_PRODUTO+"' "
						cQuery+= " AND Z07_NUMSEQ = '" + Alltrim(TRBZ08->Z08_NUMSEQ) + "' "
						cQuery+= " AND D_E_L_E_T_ = '' "				
						IF ( TcSQLExec(cQuery) < 0 )
							DisarmTransaction()
							U_FtWmsMsg("Erro ao atualizar dados da conferência." + CRLF + "OS: " +cNumOs + CRLF + "NUMSEQ:" + AllTrim(TRBZ08->Z08_NUMSEQ) ,"ERRO TWMSA051 - UPD Z07")
							Exit
						EndIf

						//WMS - COMPOSICAO PALETE       
						cQuery:= " UPDATE "+RetSQLName("Z16")
						cQuery+= " SET Z16_ENDATU = '"+TRBZ08->Z08_ENDDES+"'"
						cQuery+= " WHERE D_E_L_E_T_ = '' "
						cQuery+= " AND Z16_FILIAL = '"+TRBZ08->Z08_FILIAL+"' "
						cQuery+= " AND Z16_CODPRO = '"+SDA->DA_PRODUTO+"' "
						cQuery+= " AND Z16_LOCAL  = '"+TRBZ08->Z08_LOCAL+"' "
						cQuery+= " AND Z16_NUMSEQ = '" + Alltrim(TRBZ08->Z08_NUMSEQ) + "' "
						IF ( TcSQLExec(cQuery) < 0 )
							DisarmTransaction()
							U_FtWmsMsg("Erro ao atualizar dados do pallet." + CRLF + "OS: " +cNumOs + CRLF + "NUMSEQ:" + AllTrim(TRBZ08->Z08_NUMSEQ) ,"ERRO TWMSA051 - UPD Z16")
							Exit
						EndIf
					Endif
				EndIf
				TRBZ08->(DBSkip())
			EndDo
			
				//Verifica se há endereços diferentes.
				cQuery:= " SELECT R_E_C_N_O_ "
				cQuery+= " FROM " + RetSQLTab("Z08")
				cQuery+= " WHERE " + RetSqlCond("Z08")
				cQuery+= " AND Z08_NUMOS = '" + cNumOs + "' "
				cQuery+= " AND Z08_SEQOS = '" + cSeqOS + "' "
				cQuery+= " AND Z08_STATUS != 'R' "
				
				aRecnoZ08 := U_SqlToVet(cQuery)
				memowrit("c:\query\twmsa051_recno_Z08_pendente.txt", cQuery)
				
				If (Empty(aRecnoZ08))
					// atualiza o status do servico para FI-FINALIZADO
					//WMS - ITENS ORDEM SERVICO
					Z06->(DBSetOrder(1))   // 1 - Z06_FILIAL, Z06_NUMOS, Z06_SEQOS, R_E_C_N_O_, D_E_L_E_T_
					Z06->(MsSeek(xFilial("Z06") + mvNumos + cSeqOS ))
					RecLock("Z06",.F.)
					Z06->Z06_STATUS := "FI"
					Z06->Z06_DTFIM  := dDataBase
					Z06->Z06_HRFIM  := Time()
					Z06->Z06_USRFIM:= __cUserID
					MSUnLock()		
				Else	
					DisarmTransaction()
					U_FtWmsMsg("Falha ao tentar finalizar a OS." + CRLF + "Ainda existem produtos não endereçados.","TWMSA051 - Z08")
					Return .F.
				Endif

		End Transaction
	EndIf

	// fecha tabelas temporárias
	If Select("TRBZ07") <> 0
		DBSelectArea("TRBZ07")
		DBCloseArea()
	EndIf

	If Select("TRBZ08") <> 0
		DBSelectArea("TRBZ08")
		DBCloseArea()
	EndIf
	
	U_FtWmsMsg("Ordem de Serviço " + cNumOs + " armazenada com sucesso.","Sucesso - TWMSA051")
	
Return

// ** funcao para apresentar as ordens de servicos com mapa gerado
User Function WMSA051A(mvQryUsr)
	// status para filtrar OS
	local _cStsFiltro := "AG"

	// areas de armazenagem
	Private _cAreaArm := ""

	// inclui o codigo do servico de pré-conferencia na query
	mvQryUsr += " AND Z06_SERVIC IN ('015','003') AND Z06_TAREFA = '009' "
	// só mostra OS que já tiveram conferencia finalizada
	mvQryUsr += " AND Z06_NUMOS IN (SELECT DISTINCT Z07CONF.Z07_NUMOS FROM "+RetSqlName("Z07")+" Z07CONF (nolock)  WHERE Z07CONF.Z07_FILIAL = Z06_FILIAL AND Z07CONF.Z07_NUMOS = Z06_NUMOS AND Z07CONF.D_E_L_E_T_ = '' )

	// chama funcao para visualizar o resumo da OS (o condicional com o mvGeraMapa é apenas para não alterar o status da OS)
	If U_ACDA002C(mvQryUsr,_cStsFiltro,.T., .F. ,.F.,.T.) 
		U_TWMSA051(Z06->Z06_NUMOS , Z06->Z06_SEQOS)
	EndIf

Return()