#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Gatilho utilizado para gerar Codigo e Loja para Novos   !
!                  ! cadastros de clientes / fornecedores                    !
+------------------+---------------------------------------------------------+
!Campos            ! A1_CGC - Regra: U_TFATG002('SA1')                       !
!                  ! A2_CGC - Regra: U_TFATG002('SA2')                       !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp       ! Data de Criacao ! 12/2010 !
+------------------+--------------------------------------------------------*/

User Function TFATG002(mvAlias)
	Local _cCodRet	:= ""
	Local _cLojRet	:= StrZero(0,TamSx3("A1_LOJA")[1])
	Local _cCNPJ	:= If(mvAlias=="SA1",M->A1_CGC,M->A2_CGC)
	Local _cBasCNPJ	:= SubStr(_cCNPJ,1,8)
	Local _cSigla	:= CriaVar("A1_SIGLA")
	Local _aAreaAtu	:= GetArea()
	Local _cSeek
	Local _cTpOper	:= ""

	// verifica o codigo do cliente
	If (mvAlias == "SA1")

		// valido o tipo de operação
		If (_cBasCNPJ == "00000000").Or.(Empty(_cBasCNPJ))
			_cTpOper := "EXP"
		Else
			_cTpOper := "IMP"
		EndIf

		dbSelectArea("SA1")
		SA1->(dbSetOrder(3)) //3-A1_FILIAL, A1_CGC
		SA1->(dbSeek( _cSeek:=xFilial("SA1")+_cBasCNPJ ))
		While SA1->(!Eof()).and.(SA1->A1_FILIAL+SubStr(SA1->A1_CGC,1,8)==_cSeek)
			//validação especial para Exportação, para que sempre crie um novo número
			If (_cTpOper == "EXP")
				_cCodRet := ""
				_cLojRet := ""
			Else
				// utiliza o mesmo codigo
				_cCodRet := SA1->A1_COD
				// utiliza a mesma sigla
				_cSigla  := SA1->A1_SIGLA
				// verifica a ultima loja
				If (SA1->A1_LOJA > _cLojRet)
					_cLojRet := SA1->A1_LOJA
				EndIf
			EndIf
			// proximo item
			SA1->(dbSkip())
		EndDo

		// verifica o codigo do fornecedor
	ElseIf (mvAlias == "SA2")
		dbSelectArea("SA2")
		SA2->(dbSetOrder(3)) //3-A2_FILIAL, A2_CGC
		SA2->(dbSeek( _cSeek := xFilial("SA2")+_cBasCNPJ ))
		While SA2->( ! Eof() ).and. (SA2->A2_FILIAL + SubStr(SA2->A2_CGC,1,8) == _cSeek)
			// utiliza o mesmo codigo
			_cCodRet := SA2->A2_COD
			// verifica a ultima loja
			If (SA2->A2_LOJA > _cLojRet)
				_cLojRet := SA2->A2_LOJA
			EndIf
			// proximo item
			SA2->(dbSkip())
		EndDo
	EndIf

	// restaura area inicial
	RestArea(_aAreaAtu)

	// atualiza o codigo da proxima loja
	_cLojRet := StrZero(Val(_cLojRet)+1,TamSx3("A1_LOJA")[1])

	// caso for cliente / fornecedor novo
	If (Empty(_cCodRet))
		// funcao que busca o proximo codigo valido
		_cCodRet := sfProxCod(mvAlias, _cTpOper)
	EndIf

	// preenche o conteudo LOJA e SIGLA
	If (mvAlias == "SA1")
		M->A1_LOJA  := _cLojRet
		M->A1_SIGLA := _cSigla
	ElseIf (mvAlias == "SA2")
		If IsInCallStack("MATA020")    //se estiver incluindo diretamento pelo cadastro de fornecedor
			FWFldPut("A2_LOJA", _cLojRet)
		Else 						   //se for via F3
			M->A2_LOJA := _cLojRet
		EndIf
	EndIf

Return(_cCodRet)

//** funcao que retorna o proximo codigo
Static Function sfProxCod(mvAlias, mvTpOper)
	Local _cQuery
	Local _cPrefTab	:= SubS(mvAlias,2)
	Local _cRetCod	:= StrZero(0,TamSx3("A1_COD")[1])

	// query para retornar o proximo codigo valido
	_cQuery := " SELECT ISNULL(MAX("+_cPrefTab+"_COD),'"+_cRetCod+"') IT_CODIGO "
	_cQuery += " FROM " + RetSqlTab(mvAlias)
	_cQuery += " WHERE " + RetSqlCond(mvAlias)

	// tratamento especial para exportação
	If (mvTpOper != "EXP")
		_cQuery += " AND " + _cPrefTab + "_CGC != ' ' "
	EndIf

	// executa a query
	_cRetCod := U_FtQuery(_cQuery)
	// proximo codigo
	_cRetCod := StrZero(Val(_cRetCod)+1,TamSx3("A1_COD")[1])

Return(_cRetCod)