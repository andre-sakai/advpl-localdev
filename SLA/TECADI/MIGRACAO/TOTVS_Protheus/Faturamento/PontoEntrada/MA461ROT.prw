#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela para    !
!                  ! selecao de pedido de venda para emissao de nota fiscal  !
!                  ! 1. Filtrar pedidos de acordo com o contrato             !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 11/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function MA461ROT
	// variavel de retorno
	local _aRetBut := {}

	// 01-Armazem Geral e Modulo Faturamento
	If (cEmpAnt == "01").and.(cModulo == "FAT")
		// adiciona opcao para resumo de faturamento
		aAdd(_aRetBut,{"Resumo Faturamento","StaticCall(MA461ROT,sfResFatSrv)",0,4})
	EndIf

Return(_aRetBut)

// resumo do faturamento de servicos
Static Function sfResFatSrv()
	// area atual
	local _aAreaAtu := GetArea()

	// resumo do faturamento
	local _aResFatSrv := {}

	// variavel temporaria
	local _nTmpTotal := 0
	local _nX
	local _cMsgTotal := ""

	// query
	local _cQuery

	// prepara condicao de inverter selecao
	Local _lInverte := ThisInv()
	Local _cMarca   := ThisMark()

	// retorna o filtro padrao do Browse (ver PE M460FIL e M460QRY)
	Local _aFiltroBrw := Eval(bFiltraBrw,1)
	Local _cFilSC9    := _aFiltroBrw[1]
	Local _cQrySC9    := _aFiltroBrw[2]
	Local _cFilBrw    := _aFiltroBrw[3]
	Local _cQryBrw    := _aFiltroBrw[4]

	// monta a query
	_cQuery := "SELECT C9_PRODUTO, SUM(C9_QTDLIB * C9_PRCVEN) C9_TOTAL, C9_OK "
	// itens liberados do pedido
	_cQuery += "FROM "+RetSqlName("SC9")+" SC9 "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SC9")
	// filtro padrao do browe
	_cQuery += "AND "+_cQrySC9+" "
	// filtro padrao de nota
	_cQuery += "AND C9_BLEST <> '10' AND C9_BLEST <> 'ZZ' AND C9_TPOP <> '2' "
	// filtro de itens marcados
	_cQuery += "AND C9_OK " + IIF(_lInverte,"<>","=") + " '"+_cMarca+"' "
	// agrupa itens
	_cQuery += "GROUP BY C9_PRODUTO, C9_OK "

	MemoWrit("c:\query\ma461rot.txt",_cQuery)

	// atualiza vetor
	_aResFatSrv := U_SqlToVet(_cQuery)

	// varre todo o total para montar a mensagem
	For _nX := 1 To Len(_aResFatSrv)
		// atualiza a mensagem
		_cMsgTotal += AllTrim(Posicione("SB1",1,xFilial("SB1")+_aResFatSrv[_nX,1],"B1_DESC"))
		_cMsgTotal += " = R$ "
		_cMsgTotal += AllTrim(Transform(_aResFatSrv[_nX,2],"@E 9,999,999.99")) +CRLF
		// total geral
		_nTmpTotal += _aResFatSrv[_nX,2]
	Next _nX
	// total geral
	_cMsgTotal += CRLF+"TOTAL GERAL = R$ "+AllTrim(Transform(_nTmpTotal,"@E 9,999,999.99"))

	// apresenta a mensagem na tela
	Aviso(	"Resumo Faturamento SErviços",;
		"== Resumo Geral =="+CRLF+;
		_cMsgTotal,;
		{"Fechar"},3)

	// restaura area atual
	RestArea(_aAreaAtu)
Return