#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada Pedido de compras Valida a gravaçao    !
+------------------+---------------------------------------------------------+
!Autor             ! Odair                                                   !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 01/2014                                                 !
+------------------+--------------------------------------------------------*/

User Function MT120VLD

	//variavel para salvar estado das variáveis de memória
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"SC7"})

	// variavel de retorno
	Local _lRet := .t.

	// posicao dos campos
	local _nPosNec  := aScan(aHeader,{|x| alltrim(x[2]) == 'C7_DATPRF' })
	local _nPosUsu  := aScan(aHeader,{|x| alltrim(x[2]) == 'C7_ZUSRSC' })
	local _nPosCC   := aScan(aHeader,{|x| alltrim(x[2]) == 'C7_CC'     })
	local _nPosITc  := aScan(aHeader,{|x| alltrim(x[2]) == 'C7_ITEMCTA'})
	Local _cPerfil  := space(6)
	Local _cDtIni   := ""
	Local _cDtFim   := ""
	Local _cPerSup  := ""
	Local _cMens    := ""

	// posicao dos campos
	local _nPosTOT  := aScan(aHeader,{|x| alltrim(x[2]) == 'C7_TOTAL'}) //VLR TOTAL DA SC
	local _nPosALC  := aScan(aHeader,{|x| alltrim(x[2]) == 'C7_ZIDALCA'}) //ALCADA DO USUARIO
	local _nPosUsu  := aScan(aHeader,{|x| alltrim(x[2]) == 'C7_ZUSRSC'}) //USUARIO/ALCADA DO USUARIO
	local _nPostes  := aScan(aHeader,{|x| alltrim(x[2]) == 'C7_TES'}) //USUARIO/ALCADA DO USUARIO
	local _nPosDel  := (Len(aHeader) + 1)
	local _cDupl    := 'N'
	// variaveis temporarias
	local _nPos
	//Saldo Total
	Local _nSaltot := 0
	// Valor  no mes SC7/PC
	Local _nTotApPC := 0
	// Valor no mes SC1/SC
	Local _nTotApsc := 0
	// valor limite aprovação
	Local _nVlrLt  := 0
	// valor Anterior da SC
	Local _nVlrASC  := 0
	//nivel do  usuario
	local _cNivUsCo  := ""
	//Array contendo as informações dos centros de custos  / saldo para serem analisados
	local _aCCSld:={}
	local _nTotASC:=0
	//variavel para controle saldo do cc
	local _nPosSCC   := 0
	//variavel Mostra a Tela OU não
	local _lMostra := .F.
	LOCAL _cPcSc :='PC'
	Local _cPcScnum := ca120num
	local _nPosCCSLD:=0 //acumula valores atuais

	// testa exclusao
	If ( ! Inclui).and.( ! Altera) .and. ( ! lCop )
		Return ( .t. )
	EndIf

	// somente para empresa 01-Armazens
	If	( cEmpAnt <> "01" )
		Return ( .t. )
	EndIf

	//Valida data de necessidade, se for menor que a data atual, impede a gravação do pedido de compra.
	If ( aCols[N][_nPosNec] < dDatabase )
		_lRet := .f.
		_cMens := "A data de entrega não pode ser menor que a data atual. Reavalie o(s) item(ns) do pedido de compra."

	Else
		// consulta se o perfil possui alcada
		_lRet := sfConsPerf( aCols[N][_nPosNec], aCols[N][_nPosCc], aCols[N][_nPosItc], aCols[N][_nPosUsu] )

		if	( ! _lRet )
			_cMens := "Identificado que o usuário solicitante ou seu superior não possui alçada cadastrada. Verifique!"

		EndIf
	Endif

	// quando nao ha perfil
	if	( !_lRet )
		Aviso("Tecadi: MT120VLD",_cMens,{"OK"})
	EndIf

Return ( _lRet )

// ** funcao que consulta se o perfil possui alcada
Static Function sfConsPerf( _dDtNec, _cCenCTo, _cItemCst, _cCodUsu )

	// variavel de retorno
	Local _lRet := .f.
	//query
	Local _cQryPesCv
	// dados do perfil
	local _aDados := {}

	// montagem da query
	_cQryPesCv := "SELECT Z27_FILIAL, Z27_PERFIL, Z27_CC, Z27_ITEMC, Z27_DATAIN "
	// itens da ordem de servico
	_cQryPesCv += "FROM "+RetSqlTab("Z27")
	// insere o filtro padrao de filial
	_cQryPesCv += "WHERE  "+RetSqlCond("Z27")+" "
	// Valida mês
	_cQryPesCv += "AND SUBSTRING(Z27_DATAIN,5,2) = '"+StrZero(Month(dDatabase),2)+"' "
	// calendario
	_cQryPesCv += "AND Z27_CALEND = '"+StrZero(year(dDatabase),4)+"' "
	// insere o filtro padrao de filial
	_cQryPesCv += "AND Z27_CC = '"+_cCenCto+"' "
	// insere o filtro padrao de filial
	_cQryPesCv += "AND Z27_ITEMC = '"+_cItemCst+"' "
	// insere o filtro padrao de filial
	_cQryPesCv += "AND Z27_PERFIL IN (SELECT Z26_PERFID "
	// cad. alcadas
	_cQryPesCv += "                   FROM   "+RetSqlTab("Z26")
	// filtro padrao
	_cQryPesCv += "                   WHERE  "+RetSqlCond("Z26")
	// calendario
	_cQryPesCv += "                          AND Z26.Z26_CALEND = Z27.Z27_CALEND "
	// usuario
	_cQryPesCv += "                          AND Z26.Z26_CODUSU = '"+_cCodUsu+"' "
	// perfil superior
	_cQryPesCv += "                          AND ( ( Z26.Z26_PERSUP IN (SELECT Z27B.Z27_PERFIL "
	_cQryPesCv += "                                                     FROM   "+RetSqlName("Z27")+" Z27B "
	_cQryPesCv += "                                                     WHERE  Z27B.Z27_FILIAL = '"+xFilial("Z27")+"' "
	_cQryPesCv += "                                                            AND Z27B.D_E_L_E_T_ = ' ' "
	_cQryPesCv += "                                                            AND Z27B.Z27_CC = Z27.Z27_CC "
	_cQryPesCv += "                                                            AND Z27B.Z27_ITEMC = Z27.Z27_ITEMC "
	_cQryPesCv += "                                                            AND Z27B.Z27_CALEND = Z27.Z27_CALEND "
	_cQryPesCv += "                                                            AND Substring(Z27B.Z27_DATAIN, 5, 2) = '"+StrZero(Month(dDatabase),2)+"') ) "
	_cQryPesCv += "                             OR ( Z26.Z26_PERSUP = ' ' ) ) "
	// bloqueado
	_cQryPesCv += "                          AND Z26.Z26_MSBLQL <> '1' ) "

	//Grava arquivo TXT com sql gerada
	MemoWrit("c:\query\mt120vld_verif_alcada.txt",_cQryPesCv)

	// atualiza dados
	_aDados := U_SqlToVet(_cQryPesCv)

	// atualiza variavel de retorno
	_lRet := (Len(_aDados) > 0)

Return ( _lRet )