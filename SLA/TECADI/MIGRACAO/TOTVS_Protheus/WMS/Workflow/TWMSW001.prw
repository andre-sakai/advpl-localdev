#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina geracao de relatorio com informacoes do saldo de !
!                  ! produtos por endereco                                   !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 07/2017 !
+------------------+---------------------------------------------------------+
!Dados Cliente     ! IP: 190.14.57.85            ! Porta 85                  !
!                  ! DEV: Usuario: tecadi_dev    ! Password: tecadidev       !
!                  ! QAS: Usuario: tecadi_qas    ! Password: tecadiqas       !
!                  ! PRD: Usuario: tecadi_prd    ! Password: tecadiprd       !
+---------------------------------------------------------------------------*/

User Function TWMSW001()
	// query
	local _cQuery
	// temporario
	local _aTmpDados
	local _nTmpDados
	// linha do CSV
	local _cTmpLinha
	// arquivo
	local _cNomArq := DtoS(Date()) + StrTran(Time(),":","") + ".csv"
	local _cTmpOri := "\tecadi\" + _cNomArq
	local _nTmpHdl := fCreate(_cTmpOri)
	// cabeclho ok
	local _lCabecOk := .f.
	local _lArqOk := .f.
	local _lConexOk := .t.

	// prepara query
	_cQuery := " SELECT TOP 10 BF_LOCAL, "
	_cQuery += "        BF_LOCALIZ, "
	_cQuery += "        BF_PRODUTO, "
	_cQuery += "        Sum(BF_QUANT) BF_QUANT "
	_cQuery += " FROM   SBF010 SBF, "
	_cQuery += "        SBE010 SBE "
	_cQuery += " WHERE  BF_FILIAL = BE_FILIAL "
	_cQuery += "        AND BF_LOCAL = BE_LOCAL "
	_cQuery += "        AND BF_LOCALIZ = BE_LOCALIZ "
	_cQuery += "        AND SBF.D_E_L_E_T_ = '' "
	_cQuery += "        AND SBE.D_E_L_E_T_ = '' "
	_cQuery += "        AND Substring(BF_PRODUTO, 1, 4) = 'SAMS' "
	_cQuery += " GROUP  BY BF_LOCAL, "
	_cQuery += "           BF_LOCALIZ, "
	_cQuery += "           BF_PRODUTO "
	_cQuery += " ORDER  BY BF_LOCAL, "
	_cQuery += "           BF_LOCALIZ, "
	_cQuery += "           BF_PRODUTO  "

	// atualiza os dados em vetor
	_aTmpDados := U_SqlToVet(_cQuery)

	// varre todos os itens do vetor
	For _nTmpDados := 1 to Len(_aTmpDados)

		// gera o cabecalho
		If ( ! _lCabecOk )
			// prepara dados da linha
			_cTmpLinha := "Data;"
			_cTmpLinha += "Armazém;"
			_cTmpLinha += "Endereço;"
			_cTmpLinha += "CodProduto;"
			_cTmpLinha += "Quantidade"+CRLF
			// grava a Linha no Arquivo Texto
			fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))
			// controle de geracao do cabecalho
			_lCabecOk := .t.

		EndIf
		// prepara dados da linha
		_cTmpLinha := DtoC(Date())+";"
		_cTmpLinha += AllTrim(_aTmpDados[_nTmpDados][1])+";"
		_cTmpLinha += AllTrim(_aTmpDados[_nTmpDados][2])+";"
		_cTmpLinha += AllTrim(_aTmpDados[_nTmpDados][3])+";"
		_cTmpLinha += AllTrim(Str(_aTmpDados[_nTmpDados][4]))+CRLF
		// grava a Linha no Arquivo Texto
		fWrite(_nTmpHdl, _cTmpLinha, Len(_cTmpLinha))

		// dados ok
		_lArqOk := .t.

	Next _nTmpDados

	// fecha arquivo texto
	fClose(_nTmpHdl)

	// tenta se conectar ao servidor ftp
	If (_lArqOk).and.(_lConexOk).and.( ! FTPConnect("190.14.57.85", 85, "tecadi_dev", "tecadidev") )
		// mensagem
		MsgStop( "Nao foi possivel se conectar!!" )
		// controle
		_lConexOk := .f.
	EndIf

	// tenta realizar o upload do arquivo gerado
	If (_lArqOk).and.(_lConexOk).and.( ! FTPUpLoad(_cTmpOri, "\" + _cNomArq) )
		// mensagem
		MsgSTop( "Nao foi possivel realizar o upload!!" )
	EndIf

	//Tenta desconectar do servidor ftp
	If (_lArqOk).and.(_lConexOk)
		// desconecta
		FTPDisconnect()
	EndIf

Return NIL