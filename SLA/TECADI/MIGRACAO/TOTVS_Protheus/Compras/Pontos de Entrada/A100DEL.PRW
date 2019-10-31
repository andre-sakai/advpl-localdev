#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada antes da exclusao da Nota Fiscal de    !
!                  ! Entrada                                                 !
!                  ! 1. Nao permite excluir nota fiscal ja faturada          !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 07/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function A100DEL
	// variavel de retorno
	local _lRet := .T.
	local _cTabWMS := Space(10)
	Local cUpd := ""
	LOCAL cMsg := ""

	//variaveis de controle para validar presença de registros ativos que impeçam a exclusão de nota fiscal
	Private _lZ04Ret := .f.
	Private _lZ11Ret := .f.

	// Nao permite excluir notas que já passaram pelo processo de faturamento
	If (cEmpAnt=="01").And.(SF1->F1_TIPO=="B").And.(!Empty(SF1->F1_DTFATPR)).Or.(!Empty(SF1->F1_DTFATSE))
		Aviso("Tecadi: A100DEL","Não é permitido a exclusão desta nota fiscal pois a mesma encontra-se faturada.",{"OK"})
		// retorno
		_lRet := .f.
	EndIf

	If (cEmpAnt=="01") .And. (_lRet) .And. (SF1->F1_TIPO=="B")   //se verdadeiro, o documento passou pelas validacoes iniciais.

		sfPesqCsv()

		// OGA - 16/08/13 Efetua a consulta se existem movimentacao de mercadoria ativa ou se existem etiquetas ativas lancadas para esta nota a ser excluida.
		if	( _lZ04Ret .Or. _lZ11Ret )
			Do Case
				Case	( _lZ04Ret .And. _lZ11Ret )
				_cTabWMS := "Z04/Z11"
				Case	( _lZ04Ret .And. !_lZ11Ret )
				_cTabWMS := "Z04"
				Case	( !_lZ04Ret .And. _lZ11Ret )
				_cTabWMS := "Z11"
			EndCase

			// OGA - 16/08/13 - Se verdadeira
			Aviso("Tecadi: A100DEL","Nota não pode ser excluída, pois existem vinculos ativos com o controle WMS, no ERP Protheus. -> "+_cTabWMS,{"OK"})
			// retorno
			_lRet := .F.
		EndIf

		//Tratamento para exclusão do vínculo das notas fiscais na tabela de etiquetas (específico Sumitomo)
		If (_lRet) .And. (SF1->F1_TIPO == "B") .And. ( SF1->F1_FORNECE == SubStr(GetNewPar("TC_SRBTI","00031601"), 1, TamSX3("A1_COD")[1]) )
			cUpd:= "UPDATE "+RetSQLName("Z56")
			cUpd+= " SET Z56_NOTA = '', Z56_SERIE = '', Z56_ITEMNF = '' "
			cUpd+= " WHERE Z56_FILIAL = '"+SF1->F1_FILIAL+"' "
			cUpd+= " AND Z56_NOTA   = '"+SF1->F1_DOC+"' "
			cUpd+= " AND Z56_SERIE  = '"+SF1->F1_SERIE+"' "
			cUpd+= " AND Z56_CODCLI = '"+SF1->F1_FORNECE+"' "
			cUpd+= " AND Z56_LOJCLI = '"+SF1->F1_LOJA+"'   "
			cUpd+= " AND D_E_L_E_T_ ='' "
			
			If ( TcSQLExec(cUpd) < 0 )
				cMsg:= " Erro SQL ao desvincular as etiquetas da nota fiscal "+ TCSQLError()				   
				U_FtGeraLog(SF1->F1_FILIAL, "SF1", SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA), cMsg,"001", "","000000")
				Aviso("Erro",cMsg,{"Fechar"},3)
				_lRet := .F. 	
			EndIf
		EndIf
	EndIf

Return(_lRet)

//** funcao que monta a query principal
Static Function sfPesqCsv()
	local _cQryPesCv := ""

	// monta a query para buscar as pendencias da atividade
	_cQryPesCv := "SELECT Z04_CESV, Z04_NF, Z04_SERIE, Z04_NUMSEQ "

	// itens da ordem de servico
	_cQryPesCv += "FROM "+RetSqlName("Z04")+" Z04 "

	// insere o filtro padrao de filial
	_cQryPesCv += "INNER JOIN "+RetSqlName("SD1")+" SD1 ON "+RetSqlCond("SD1")+" AND Z04_NUMSEQ = D1_NUMSEQ AND Z04_NF = D1_DOC AND Z04_SERIE = D1_SERIE "

	// equipara
	_cQryPesCv += "AND D1_DOC     = '" + SF1->F1_DOC     + "' AND D1_SERIE = '" + SF1->F1_SERIE + "' "
	_cQryPesCv += "AND D1_FORNECE = '" + SF1->F1_FORNECE + "' AND D1_LOJA  = '" + SF1->F1_LOJA  + "' "
	_cQryPesCv += "AND D1_TIPO    = '" + SF1->F1_TIPO    + "' "

	// filtra a nota, serie e numseq
	_cQryPesCv += "WHERE  "+RetSqlCond("Z04")+"  "

	memowrit("c:\query\a100del_sfPesqZ04.txt",_cQryPesCv)

	If (Select("_QRYZ04")<>0)
		dbSelectArea("_QRYZ04")
		dbCloseArea()
	EndIf
	DbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQryPesCv),"_QRYZ04",.F.,.F.)
	dbSelectArea("_QRYZ04")

	// posiciona no primeiro registro
	dbSelectArea("_QRYZ04")
	_QRYZ04->(dbGoTop())
	// valida se tem dados
	_lZ04Ret := _QRYZ04->(!Eof())

	_cQryPesCv := ""

	// monta a query para buscar informações na Z11
	_cQryPesCv := "SELECT Z11_CODETI, Z11_DOC, Z11_SERIE, Z11_NUMSEQ "

	// itens da ordem de servico
	_cQryPesCv += "FROM "+RetSqlName("Z11")+" Z11 "

	// insere o filtro padrao de filial
	_cQryPesCv += "INNER JOIN "+RetSqlName("SD1")+" SD1 ON "+RetSqlCond("SD1")+" AND Z11_NUMSEQ = D1_NUMSEQ AND Z11_DOC = D1_DOC AND Z11_SERIE = D1_SERIE "

	// equipara
	_cQryPesCv += "AND D1_DOC     = '" + SF1->F1_DOC     + "' AND D1_SERIE = '" + SF1->F1_SERIE + "' "
	_cQryPesCv += "AND D1_FORNECE = '" + SF1->F1_FORNECE + "' AND D1_LOJA  = '" + SF1->F1_LOJA  + "' "
	_cQryPesCv += "AND D1_TIPO    = '" + SF1->F1_TIPO    + "' "

	// filtra a nota, serie e numseq
	_cQryPesCv += "WHERE  "+RetSqlCond("Z11")+"  "

	memowrit("c:\query\a100del_sfPesqZ11.txt",_cQryPesCv)

	If (Select("_QRYZ11")<>0)
		dbSelectArea("_QRYZ11")
		dbCloseArea()
	EndIf
	DbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQryPesCv),"_QRYZ11",.F.,.F.)
	dbSelectArea("_QRYZ11")

	// posiciona no primeiro registro
	dbSelectArea("_QRYZ11")
	_QRYZ11->(dbGoTop())
	// valida se tem dados
	_lZ11Ret := _QRYZ11->(!Eof())

Return()