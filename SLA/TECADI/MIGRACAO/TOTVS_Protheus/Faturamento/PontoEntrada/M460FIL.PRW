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

User Function M460FIL
	// filtro de retorno
	local _cFilRet := " C9_FILIAL = '"+xFilial("SC9")+"' "
	// grupo de perguntas
	local _cPerg := "M460QRY"

	// condicao de filtro para não apresentar dados
	local _cFilNaoOk := " .And. (1 = 0) "

	// parametros atuais
	local _aAtuParam := {}

	// 01-Armazem Geral e Modulo Faturamento
	If (cEmpAnt == "01") .And. (cModulo == "FAT")

		// salvar parametros atuais do grupo de perguntas
		_aAtuParam := U_FtSavSx1(30)

		// abre os parametros
		Pergunte(_cPerg, .F.)

		// filtra somente para PRODUTOS
		If (mv_par01 == 1)
			// inclui condicao do grupo de produtos
			_cFilRet += " .And. C9_GRUPO != '9000' "

			// funcao para validacao de pedidos aptos a faturar
			If ( ! U_FtFatVld( .T., "P", _aAtuParam[5][2], _aAtuParam[6][2], _aAtuParam[7][2], _aAtuParam[8][2], _aAtuParam[9][2], _aAtuParam[10][2], _aAtuParam[11][2], _aAtuParam[12][2], Nil, Nil, Nil, Nil) )
				_cFilRet += _cFilNaoOk
			EndIf

			// filtra somente para SERVICOS
		ElseIf (mv_par01 == 2)
			_cFilRet += " .And. C9_GRUPO = '9000' .And. C9_ZCONTRT >= '" + mv_par02 + "' .And. C9_ZCONTRT <= '" + mv_par03 + "' "
			// filtra somente para CONSUMO
		ElseIf (mv_par01 == 3)
			_cFilRet += " .And. C9_GRUPO != '9000' "
		EndIf

		// restaura grupo de perguntas
		U_FtResSx1(_aAtuParam)

	EndIf

Return(_cFilRet)