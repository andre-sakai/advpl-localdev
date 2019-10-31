#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado apos a gravacao do item do  !
!                  ! contrato - WMS                                          !
!                  ! 1. Botao para visualizar os detalhes de cada servico    !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 01/2012                                                 !
+------------------+--------------------------------------------------------*/

User Function AT250AAN
// opcao selecionada
local _nOpcSelec := ParamIxb[1]
// opcao de copia de contrato
local _lCopiaCont := (_nOpcSelec == 7)
// query
local _cQuery
// tabelas customizadas
local _aTabCust := {{"SZU","ZU_CONTRT","ZU_ITCONTR"},{"SZ9","Z9_CONTRAT","Z9_ITEM"}}
local _nTabCust
local _cTabCust
// alias temporaria
Local _cTmpAlias := GetNextAlias()
local _cTmpCampo
local _aCampos := {}

// na exclusao, remove itens de tabelas customizadas
If (!Inclui).and.(!Altera).and.(!_lCopiaCont)
	// Exclusão dos produtos do pacote logistico
	_cQuery := "DELETE FROM "+RetSqlName("SZU")+" WHERE ZU_FILIAL = '"+XFILIAL("SZU")+"' AND ZU_CONTRT = '"+M->AAM_CONTRT+"' "
	TCSQLEXEC(_cQuery)
	// Exclusão das atividades
	_cQuery := "DELETE FROM "+RetSqlName("SZ9")+" WHERE Z9_FILIAL = '"+XFILIAL("SZ9")+"' AND Z9_CONTRAT = '"+M->AAM_CONTRT+"' "
	TCSQLEXEC(_cQuery)
ENDIF

// quando for copia de contrato, copia tabelas customizadas
If (!Inclui).and.(!Altera).and.(_lCopiaCont)

	// varre todas as tabelas customizadas
	For _nTabCust := 1 to Len(_aTabCust)

		// atualiza variavel
		_cTabCust := _aTabCust[_nTabCust][1]

		// monta query para buscar todos os registro do contrato anterior
		_cQuery := "SELECT * FROM "+RetSqlName(_cTabCust)+" "+_cTabCust+" "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond(_cTabCust)+" "
		// filtro por contrato
		_cQuery += "AND "+_aTabCust[_nTabCust][2]+" = '"+M->AAM_ZORIGE+"' "
		// item do contrato
		_cQuery += "AND "+_aTabCust[_nTabCust][3]+" = '"+AAN->AAN_ITEM+"' "
		// ordem dos dados
		_cQuery += "ORDER BY R_E_C_N_O_ "

		// fecha alias em uso
		If (Select(_cTmpAlias) <> 0)
			dbSelectArea(_cTmpAlias)
			dbCloseArea()
		EndIf

		// abre novo alias da query
		DbUseArea(.T.,'TOPCONN',TcGenQry(,,_cQuery),(_cTmpAlias),.T.,.F.)
		dbSelectArea(_cTmpAlias)

		// varre todos os registros, para incluir no novo contrato
		While (_cTmpAlias)->(!Eof())

			// inclui novo
			dbSelectArea(_cTabCust)
			RecLock(_cTabCust,.t.)

			// varre todos os campos da tabela
			_aCampos := FWSX3Util():GetAllFields(_cTabCust,.F.)
			
			For _nX := 1 To Len(_aCampos)
				
				// armazena nome do campo
				_cTmpCampo := _aCampos[_nX]
				// atualiza conteudo do campo do novo registro
				If (AllTrim(_cTmpCampo) == AllTrim(_aTabCust[_nTabCust][2])) // campo chave
					(_cTabCust)->&(_cTmpCampo) := M->AAM_CONTRT
				Else
					(_cTabCust)->&(_cTmpCampo) := (_cTmpAlias)->(FieldGet(FieldPos(_aCampos[_nX])))
				EndIf
				
			Next _nX
			
			// salva novo registro
			(_cTabCust)->(MsUnLock())

			// proximo item
			dbSelectArea(_cTmpAlias)
			(_cTmpAlias)->(dbSkip())
		EndDo

	Next _nTabCust

EndIf

Return(.t.)