#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela para    !
!                  ! selecao de pedido de venda para emissao de nota fiscal  !
!                  ! USAR EM CONJUNTO COM : M460FIL / M460QRY                !
!                  ! 1. Filtrar pedidos de acordo com o contrato             !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 11/2015 !
+------------------+--------------------------------------------------------*/

User Function M460QRY
	// filtro de retorno
	local _cFilRet := Paramixb[1]
	// grupo de perguntas
	local _cPerg := "M460QRY"
	local _aPerg := {}

	// condicao de filtro para não apresentar dados
	local _cFilNaoOk := " And (1 = 0) "

	// parametros atuais
	local _aAtuParam := {}

	// 01-Armazem Geral e Modulo Faturamento
	If (cEmpAnt == "01") .And. (cModulo == "FAT")

		// salvar parametros atuais do grupo de perguntas
		_aAtuParam := U_FtSavSx1(30)

		// monta grupo de perguntas
		aAdd(_aPerg,{"Tipo de Pedido?" ,"N",1,0,"C",{"Produto","Serviço","Consumo"},""}) //mv_par01
		aAdd(_aPerg,{"Contrato de ?"   ,"C",TamSx3("AAM_CONTRT")[1],0,"G",,"AAM",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par02
		aAdd(_aPerg,{"Contrato Até ?"  ,"C",TamSx3("AAM_CONTRT")[1],0,"G",,"AAM",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par03

		// cria o grupo de perguntas
		U_FtCriaSX1(_cPerg, _aPerg)

		// abre os parametros
		If ( ! Pergunte(_cPerg,.T.) )
			// se pergunta foi cancelada, nao mostra nada
			_cFilRet += _cFilNaoOk
			// restaura grupo de perguntas
			U_FtResSx1(_aAtuParam)
			// retorno
			Return(_cFilRet)
		Endif

		// filtra somente para PRODUTOS
		If (mv_par01 == 1)
			// inclui condicao do grupo de produtos
			_cFilRet += " And SC9.C9_GRUPO != '9000' "

			// funcao para validacao de pedidos aptos a faturar
			If ( ! U_FtFatVld( .F., "P", _aAtuParam[5][2], _aAtuParam[6][2], _aAtuParam[7][2], _aAtuParam[8][2], _aAtuParam[9][2], _aAtuParam[10][2], _aAtuParam[11][2], _aAtuParam[12][2], Nil, Nil, Nil, Nil) )
				_cFilRet += _cFilNaoOk
			EndIf

			// filtra somente para SERVICOS
		ElseIf (mv_par01 == 2)
			_cFilRet += " And SC9.C9_GRUPO = '9000' And SC9.C9_ZCONTRT >= '" + mv_par02 + "' And SC9.C9_ZCONTRT <= '" + mv_par03 + "' "
			// filtra somente para CONSUMO
		ElseIf (mv_par01 == 3)
			_cFilRet += " And SC9.C9_GRUPO != '9000' "
		EndIf

		// restaura grupo de perguntas
		U_FtResSx1(_aAtuParam)

	EndIf

Return(_cFilRet)