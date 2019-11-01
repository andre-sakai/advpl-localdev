#include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Estorno de pedido de vendas gerado por TFAA             !
+------------------+---------------------------------------------------------+
!Autor             ! Luiz                        ! Data de Criacao ! 02/2018 !
+------------------+---------------------------------------------------------+
!Observacoes       !                                                         !
!                  !                                                         !
!                  !                                                         !
!                  !                                                         !
!                  !                                                         !
!                  !                                                         !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. - estornado com sucesso                             !
!                  ! .F. - erro em uma das etapas do processamento           !
+------------------+--------------------------------------------------------*/


//TODO tratamento para estornar produtos com LOTE (desmontar primeiro)

User function TFATA003 (mvNumOS)
	
	local _nErro	 := 0
	local _cTfaa     := ""
	local _cPedTfaa  := ""
	local _cQuery    := ""

	local _cSeekZ42  := ""
	local _cSeekZ06  := ""
	
	local _nX        := ""

	//localiza as colunas do acols, pois neste momento, SC6 já está deletada e não há como posicionar via DbSeek, e SQL seria arriscado
	//pois poderia haver registros duplicados (já excluidos anteriormente)
	local _nPosProd  := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_PRODUTO" })
	local _nPosLote  := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_LOTECTL" })
	local _nPosNFOri := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_NFORI"   })
	local _nPosSerie := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_SERIORI" })
	local _nPosIdent := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_IDENTB6" })
	local _nPosLocal := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_LOCAL"   })	

	// controle de modulo, antes de chamar rotina automatica
	local _nModOld := nModulo

	//valida se OS existe e captura os dados do TFAA
	DBSelectArea("Z05")
	Z05->( DbSetOrder(1) )         //Z05_FILIAL, Z05_NUMOS, R_E_C_N_O_, D_E_L_E_T_
	If	( !Z05->( DbSeek(xFilial("Z05") + mvNumOS) ))
		MsgAlert("Erro: a OS " + mvNumOS + " não foi encontrada para estornar o TFAA!", "TFATA003")
		Return( .F. )
	Else
		_cTfaa    := Z05->Z05_TFAA
		_cPedTfaa := Z05->Z05_PVTFAA
	EndIf


	Begin Transaction

		//estorna cada movimento de acordo com acols
		For _nX := 1 to Len(aCols)

			// zera variaveis
			_aCabSDA  := {}
			_aItemSDB := {}

			// cabecalho de movimentacao da mercadoria
			_aCabSDA := {;
			{"DA_PRODUTO"	, aCols[_nX][_nPosProd]  ,NIL},;
			{"DA_LOTECTL"	, aCols[_nX][_nPosLote]  ,NIL},;
			{"DA_DOC"		, aCols[_nX][_nPosNFOri] ,NIL},;
			{"DA_SERIE"	    , aCols[_nX][_nPosSerie] ,NIL},;
			{"DA_CLIFOR"	, SC5->C5_CLIENTE      ,NIL},;
			{"DA_LOJA"		, SC5->C5_LOJACLI      ,NIL},;
			{"DA_NUMSEQ"	, aCols[_nX][_nPosIdent] ,NIL},;
			{"DA_LOCAL"	    , aCols[_nX][_nPosLocal] ,NIL}}

			// pego o recno do registro original, que foi parar em endereço de devolução
			_cQuery := " SELECT R_E_C_N_O_ RECNO FROM " + RetSqlTab("SDB")
			_cQuery += " WHERE " + RetSqlCond("SDB")
			_cQuery += " AND DB_LOCALIZ = 'DEVMERCCLI'"
			//			_cQuery += " AND DB_ZNUMOS = '"  + mvNumOS + "' "
			_cQuery += " AND DB_NUMSEQ = '"  + aCols[_nX][_nPosIdent] + "'"
			_cQuery += " AND DB_LOTECTL = '" + aCols[_nX][_nPosLote] + "'"
			_cQuery += " AND DB_DOC     = '" + aCols[_nX][_nPosNFOri] + "'"
			_cQuery += " AND DB_ESTORNO = '' "

			// gero arquivo para debug
			memowrit("C:\query\TFATA003_recnosdb.txt",_cQuery)

			// retorno o RECNO para a variável
			_nRecnoSDB := U_FtQuery(_cQuery)

			// posiciono no item sendo estornado
			dbSelectArea("SDB")
			SDB->( dbGoTo(_nRecnoSDB) )

			// se o registro na SDB não foi encontrado ou já foi estornado, pula item
			If ( SDB->( EoF() ) )
				Loop
			EndIf

			// item da movimentacao da mercadoria
			Aadd(_aItemSDB,  {{"DB_FILIAL"	,SDB->DB_FILIAL	,NIL},;
			{"DB_ITEM"		,SDB->DB_ITEM        ,NIL},;
			{"DB_LOCAL"		,SDB->DB_LOCAL       ,NIL},;
			{"DB_ESTORNO" 	,"S"                 ,Nil},;    // S=Sim - Para estornar o registro
			{"DB_LOCALIZ"	,"DEVMERCCLI"        ,NIL},;    //TODO tratamento para endereço de devolução específico do cliente
			{"DB_PRODUTO"	,SDB->DB_PRODUTO     ,NIL},;
			{"DB_DOC"		,SDB->DB_DOC         ,NIL},;
			{"DB_SERIE"		,SDB->DB_SERIE       ,NIL},;
			{"DB_NUMSEQ"	,SDB->DB_NUMSEQ      ,NIL},;
			{"DB_DATA"		,SDB->DB_DATA        ,NIL},;
			{"DB_QUANT"		,SDB->DB_QUANT       ,NIL}})

			// rotina automatica de endereçamento - usada pro estorno
			lMsErroAuto := .F.
			MSExecAuto({|x,y,z| mata265(x,y,z)}, _aCabSDA, _aItemSDB, 4)     //4-Estorno

			// se deu erro ao realizar o estorno
			If (lMsErroAuto)
				_nErro := 1
				DisarmTransaction()
				Break
			EndIf

		Next _nX

		//--- Limpa tabelas de TFAA ---

		//apaga TFAA (cabeçalho)
		DbSelectArea("Z41")
		Z41->( DbSetOrder(1) )   //Z41_FILIAL, Z41_CODIGO, R_E_C_N_O_, D_E_L_E_T_

		//se não encontrou o TFAA para excluir, aborta o processo
		If ( !Z41->(DbSeek(xFilial("Z41") + _cTfaa)) )
			_nErro := 2
			DisarmTransaction()
			Break
		Else
			Reclock("Z41", .F. )
			Z41->(dbDelete())
			MsUnLock()
		EndIf

		//apaga TFAA (itens)
		DbSelectArea("Z42")
		Z42->(DbSetOrder(1))   //Z42_FILIAL, Z42_CODIGO, Z42_ITEM, R_E_C_N_O_, D_E_L_E_T_

		//se não encontrou os itens do TFAA para excluir, aborta o processo
		If ( !Z42->( DbSeek( _cSeekZ42 := xFilial("Z42") + _cTfaa)) )
			_nErro := 3
			DisarmTransaction()
			Break
		Else
			While ( Z42->( !EoF() ) .AND. ( Z42->(Z42_FILIAL + Z42_CODIGO) == _cSeekZ42) )
				Reclock("Z42", .F. )
				Z42->(dbDelete())
				MsUnLock()

				//próximo item do TFAA
				Z42->(dbSkip())
			EndDo
		EndIf

		//--- Tratativas Z06 (reabrir sequencias) ---

		DbSelectArea("Z06")
		Z06->(dbSetOrder(1))             //Z06_FILIAL, Z06_NUMOS, Z06_SEQOS, R_E_C_N_O_, D_E_L_E_T_

		If ( !Z06->( DbSeek( _cSeekZ06 := xFilial("Z06") + mvNumOS)) )
			_nErro := 4
			DisarmTransaction()
			Break
		Else
			//reabre todas as sequencias da OS, para permitir conferir novamente, endereçar, etc
			While ( Z06->( !EoF() ) .AND. ( Z06->(Z06_FILIAL + Z06_NUMOS) == _cSeekZ06) )
				If ( Z06->Z06_STATUS == "FI")
					U_FtWmsSta( Z06->Z06_STATUS, "EX", Z06_NUMOS, Z06->Z06_SEQOS)
				EndIf

				//próxima sequência da OS
				Z06->(dbSkip())
			EndDo
		EndIf


		//TODO tratativas Z07, reabrir conferencia, etc

		//TODO tratativas Z08, reabrir mapa ou estornar, etc


		//--- Tratativas Z05 (limpeza campos do TFAA) ---
		//certifico que estou posicionado na OS correta
		If ( Z05->( DbSeek(xFilial("Z05") + mvNumOS) ) )
			//limpa campos
			RecLock("Z05", .F. )
			Z05->Z05_TFAA   := ""
			Z05->Z05_PVTFAA := ""
			MsUnLock()
		EndIf

		// insere o log
		U_FtGeraLog(cFilAnt,;
		"SC5",;
		xFilial("SC5") + _cPedTfaa,;
		"Estorno de pedido de venda com TFAA realizado com sucesso. Pedido: " + _cPedTfaa + " TFAA: " + _cTFAA + " OS: " + mvNumOS ,;
		"WMS")


	End Transaction
	
	If _nErro == 1
		// apresenta mensagem com o error.log
		U_FtWmsMsg(sfAchaErro(),"ERRO - TFATA003 / 01")
		// variavel de retorno
		Return( .F. )
	EndIf
	
	If _nErro == 2
		MsgStop("Processo abortado: erro ao excluir cabeçalho do TFAA " + _cTfaa ,"Erro TFATA003 / 02")
		Return( .F. )
	EndIf
	
	If _nErro == 3
		MsgStop("Processo abortado: erro ao excluir itens do TFAA " + _cTfaa ,"Erro TFATA003 / 03")
		Return( .F. )
	EndIf
	
	If _nErro == 4
		MsgStop("Processo abortado: OS origem " + mvNumOS + " não encontrada!" ,"Erro TFATA003 / 04")
		Return( .F. )
	EndIf
	
	// retorna o modulo padrao
	nModulo := _nModOld


return ( .T. )