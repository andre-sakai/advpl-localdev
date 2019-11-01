#include 'protheus.ch'
#include 'parmtype.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotinas de geração e/ou leitura de EDI                  !
!                  !                                                         !
+------------------+---------------------------------------------------------+
!Autor             ! Luiz Poleza                 ! Data de Criacao ! 02/2019 !
+------------------+--------------------------------------------------------*/


// Gera arquivo EDI no padrão Tecadi dos pedidos do carregamento
// Código interno - TECA-EDI-03
// Parâmetros: mvCesv - Código do CESV da filial corrente do qual se deseja extrair os dados e gerar o EDI
// Retorno: Nil se não gerou o arquivo, _cRet com os dados de EDI caso conseguiu gerar
User Function TEDI003 (mvCesv)

	local _cQry, _aRetQry, _nX
	local _aAreaSA1 := SA1->(GetArea())

	local _cRet := ""  // variável com os dados do EDI

	// prepara query
	_cQry := " SELECT Z43_CESV,             "  //1
	_cQry += "        Z43_CLIENT,           "
	_cQry += "        Z43_LOJA,             "
	_cQry += "        Z43_PEDIDO,           "
	_cQry += "        Z43_PEDCLI,           "  //5
	_cQry += "        Z43_SEQAGE,           "
	_cQry += "        ZZ_DTCHEG,            "
	_cQry += "        ZZ_HRCHEG,            "
	_cQry += "        ZZ_TRANSP,            "
	_cQry += "        ZZ_MOTORIS,           "  //10
	_cQry += "        ZZ_PLACA1,            "
	_cQry += "        ZZ_DTSAI,             "
	_cQry += "        ZZ_HRSAI,             "
	_cQry += "        A4_CGC,               "
	_cQry += "        DA4_CPF ,             "  //15
	_cQry += "        C5_NOTA,              "
	_cQry += "        Left(C5_ZCLIENT, 60) C5_ZCLIENT,"
	_cQry += "        Left(C5_VOLUME1, 3)  C5_VOLUME1,"
	_cQry += "        C5_ZDOCCLI            "  //19
	_cQry += " FROM " + RetSqlTab("Z43") + " (NOLOCK) "
	_cQry += "     INNER JOIN " + RetSqlTab("SZZ") + " (NOLOCK) "
	_cQry += "                ON " + RetSqlCond("SZZ")
	_cQry += "                   AND SZZ.ZZ_CESV = Z43_CESV     "
	_cQry += "     INNER JOIN " + RetSqlTab("SA4") + " (NOLOCK) "
	_cQry += "                ON " + RetSqlCond("SA4")
	_cQry += "                   AND SA4.A4_COD = SZZ.ZZ_TRANSP "
	_cQry += "     INNER JOIN " + RetSqlTab("DA4") + " (NOLOCK) "
	_cQry += "                ON " + RetSqlCond("DA4")
	_cQry += "                   AND DA4_COD = SZZ.ZZ_MOTORIS   "
	_cQry += "     INNER JOIN " + RetSqlTab("SC5") + " (NOLOCK) "
	_cQry += "                ON " + RetSqlCond("SC5")
	_cQry += "                   AND SC5.C5_NUM = Z43_PEDIDO    "
	_cQry += " WHERE " + RetSqlCond("Z43")
	_cQry += "        AND Z43_CESV = '" + mvCesv + "'"

	_aRetQry := U_SqlToVet(_cQry)

	//	MemoWrit("c:\query\TEDI001_"+mvCesv+".txt", _cQry)

	// se não teve dados 
	IF (Len(_aRetQry) == 0)
		Return ( Nil )
	EndIf

	// posiciona no cadastro do cliente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1))     // 1 - A1_FILIAL, A1_COD, A1_LOJA
	SA1->(dbSeek( xFilial("SA1") + _aRetQry[1][2] + _aRetQry[1][3] ))

	// ---- Bloco 1 - cabeçalho arquivo ----

	// Identificador de cabeçalho
	_cRet := "0^"
	// CNPJ armazém Tecadi
	_cRet += SM0->M0_CGC + "^"
	// CNPJ cliente
	_cRet += SA1->A1_CGC

	// ---- Bloco 2 - cabeçalho carga----

	// Identificador de cabeçalho
	_cRet += CRLF + "1^"
	// CESV
	_cRet += mvCesv + "^"
	// Agendamento
	_cRet += _aRetQry[1][6] + "^"
	// Transportadora CNPJ
	_cRet += _aRetQry[1][14] + "^"
	// Motorista CPF
	_cRet += _aRetQry[1][15] + "^"
	// Placa
	_cRet += _aRetQry[1][11] + "^"
	// Data/hora entrada
	_cRet += _aRetQry[1][7] + _aRetQry[1][8] + "^"
	// Data/hora saída
	_cRet += _aRetQry[1][12] + _aRetQry[1][13]

	// ---- Bloco 3 - detalhes pedidos ----
	For _nX := 1 to Len(_aRetQry)
		// Identificador de cabeçalho
		_cRet += CRLF + "2^"
		// Sequencia
		_cRet += PadL(_nX, 3, "0") + "^"
		// Pedido cliente
		_cRet += _aRetQry[_nX][5] + "^"
		// NF cliente
		_cRet += _aRetQry[_nX][19] + "^"
		// Nome cliente final
		_cRet += _aRetQry[_nX][17] + "^"
		//Pedido Tecadi
		_cRet += _aRetQry[_nX][4] + "^"
		// NF Tecadi
		_cRet += _aRetQry[_nX][16] + "^"
		// Qtd volumes
		_cRet += _aRetQry[_nX][18]
	Next _nX

	memowrit("c:\temp\aaa.txt", _cRet)

	// restaura areas desposicionadas
	RestArea(_aAreaSA1)

Return (_cRet)

// Gera arquivo EDI no padrão Tecadi contendo os produtos que foram integrados ao estoque (disponível para pedidos)
// Código interno - TECA-EDI-04
// Parâmetros: mvNumOS - Número da OS de conferência no qual os produtos foram conferidos
// Retorno: Nil se não gerou o arquivo, _cRet com os dados de EDI caso conseguiu gerar
User Function TEDI004 (mvNumOS)

	local _cQry, _aRetQry, _nX
	local _cRet := ""          // variável com os dados do EDI
	local _aAreaSA1 := SA1->(GetArea())
	local _aAreaZ06 := Z06->(GetArea())


	// busca os produtos que foram conferidos nesta OS
	_cQry := " SELECT B1_CODCLI,                            "
	_cQry += "        Z07_NUMSEQ,                           "
	_cQry += "        B1_DESC,                              "
	_cQry += "        Sum(Z07_QUANT) AS QTD,                "
	_cQry += "        Z07_TPESTO,                           "
	_cQry += "        Z34_DESCRI,                           "
	_cQry += "        Z07_NUMOS,                            "
	_cQry += "        Z07_CLIENT,                           "
	_cQry += "        Z07_LOJA,                             "
	_cQry += "        D1_DOC,                               "
	_cQry += "        D1_SERIE                              "
	_cQry += " FROM " + RetSqlTab("Z07") + " (NOLOCK) "
	_cQry += "        INNER JOIN " + RetSqlTab("Z34") + " (NOLOCK) "
	_cQry += "                ON " + RetSqlCond("Z34")
	_cQry += "                AND Z34_CODIGO = Z07_TPESTO   "
	_cQry += "        INNER JOIN " + RetSqlTab("SB1") + " (NOLOCK) "
	_cQry += "                ON " + RetSqlCond("SB1")
	_cQry += "                AND SB1.B1_COD = Z07_PRODUT   "
	_cQry += "        INNER JOIN " + RetSqlTab("SD1") + " (NOLOCK) "
	_cQry += "                ON " + RetSqlCond("SD1")
	_cQry += "                AND D1_FORNECE = Z07_CLIENT   "
	_cQry += "                AND D1_LOJA = Z07_LOJA        "
	_cQry += "                AND D1_NUMSEQ = Z07_NUMSEQ    "
	_cQry += " WHERE " + RetSqlCond("Z07")
	_cQry += "        AND Z07_NUMOS = '"+mvNumOS+"'         "
	_cQry += "        AND Z07_SEQOS = '001'                 "
	_cQry += " GROUP  BY B1_CODCLI,                         "
	_cQry += "           Z07_TPESTO,                        "
	_cQry += "           Z07_NUMOS,                         "
	_cQry += "           Z34_DESCRI,                        "
	_cQry += "           Z07_CLIENT,                        "
	_cQry += "           Z07_LOJA,                          "
	_cQry += "           Z07_NUMSEQ,                        "
	_cQry += "           B1_DESC,                           "
	_cQry += "           D1_DOC,                            "
	_cQry += "           D1_SERIE                           "
	_cQry += " ORDER  BY 1                                  " 

	_aRetQry := U_SqlToVet(_cQry)

	// se não teve dados 
	IF (Len(_aRetQry) == 0)
		Return ( Nil )
	EndIf

	// posiciona no cadastro do cliente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1))     // 1 - A1_FILIAL, A1_COD, A1_LOJA
	SA1->(dbSeek( xFilial("SA1") + _aRetQry[1][8] + _aRetQry[1][9] ))
	
	// posiciona na ordem de serviço
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1))     // 1 - Z06_FILIAL, Z06_NUMOS, Z06_SEQOS, R_E_C_N_O_, D_E_L_E_T_
	Z06->(dbSeek( xFilial("Z06") + _aRetQry[1][7] + "002" ))  // sequencia 002 - endereçamento
	
	// ---- Bloco 1 - cabeçalho arquivo ----

	// Identificador de cabeçalho
	_cRet := "0^"
	// CNPJ armazém Tecadi
	_cRet += SM0->M0_CGC + "^"
	// CNPJ cliente
	_cRet += SA1->A1_CGC

	// ---- Bloco 2 - cabeçalho da ordem de serviço ----

	// Identificador de cabeçalho
	_cRet += CRLF + "1^"
	// Número OS
	_cRet += mvNumOS + "^"
	// Data hora
	_cRet += DtoS(Z06->Z06_DTFIM) + Z06->Z06_HRFIM + "^"

	// ---- Bloco 3 - detalhes itens ----
	For _nX := 1 to Len(_aRetQry)
		// Identificador de cabeçalho
		_cRet += CRLF + "2^"
		// Código produto
		_cRet += _aRetQry[_nX][1] + "^"
		// Descrição produto
		_cRet += SubStr(_aRetQry[_nX][3],1,50) + "^"
		// Quantidade
		_cRet += PadL(_aRetQry[_nX][4],17,"") + "^"
		// Tipo Estoque
		_cRet += Substr(_aRetQry[_nX][6],1,20) + "^"
		// Nota fiscal
		_cRet += _aRetQry[_nX][10] + "^"
		// Série NF
		_cRet += _aRetQry[_nX][11]
	Next _nX

//	memowrit("c:\temp\aaa.txt", _cRet)

	// restaura areas desposicionadas
	RestArea(_aAreaSA1)
	RestArea(_aAreaZ06)


Return (_cRet)