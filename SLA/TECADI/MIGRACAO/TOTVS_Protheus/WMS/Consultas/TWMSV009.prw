#include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para consulta da composição do palete            !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 11/2016 !
+------------------+--------------------------------------------------------*/

User Function TWMSV009

	// alias do arquivo trabalho/apoio
	local _cAlias := "Z16"

	// validacoes com a tabela principal
	chkFile(_cAlias)
	dbSelectArea(_cAlias)
	(_cAlias)->(dbSetOrder(1))

	// titulo a ser utilizado nas operações
	private cCadastro := "Composição dos Paletes"

	// opcoes do menu
	private aRotina := {;
		{"Pesquisar" , "AxPesqui", 0, 1},;
		{"Visualizar", "AxVisual", 0, 2} }

	dbSelectArea(_cAlias)
	mBrowse( 6, 1, 22, 75, _cAlias,,,,,,,,,,,,,,"Z16_SALDO > 0")

Return