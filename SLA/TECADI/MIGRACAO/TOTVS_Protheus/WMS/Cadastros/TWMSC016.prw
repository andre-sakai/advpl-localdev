#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Cadastro de Armazens                                    !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 04/2017 !
+------------------+--------------------------------------------------------*/

User Function TWMSC016

	// tabela de lastro e camadas de produtos
	Private cString := "Z12"
	dbSelectArea("Z12")
	dbSetOrder(1)

	// tela padrao de cadastro
	AxCadastro(cString,"Cadastro de Armazéns","U_WMSC016A()")

Return

// ** funcao para validar se o registro podera ser excluido
User Function WMSC016A
	// variavel de retorno
	local _lRet := .t.
	// query
	local _cQuery

	// prepara query para verificar se o registro ja foi usado
	_cQuery := " SELECT Count(*) QTD_USADO "
	_cQuery += " FROM   "+RetSqlTab("SB2")
	_cQuery += " WHERE  "+RetSqlCond("SB2")
	_cQuery += "        AND B2_LOCAL = '"+Z12->Z12_CODIGO+"' "

	// executa query
	If (U_FtQuery(_cQuery) != 0)
		// mensagem
		MsgStop("Este registro está em uso e não poderá ser excluído.")
		// retorno
		_lRet := .f.
	EndIf

Return(_lRet)