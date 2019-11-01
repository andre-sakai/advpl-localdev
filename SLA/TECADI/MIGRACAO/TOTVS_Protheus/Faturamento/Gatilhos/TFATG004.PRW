#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TFATF004                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Tela utilizada para seleção dos filtros customizados.   !
!                  ! Chamado na validação do campo A1_ZTPARQU.               !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe Jose Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 07/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function TFATG004(lTipoRet)

	Local cTitulo :=""
	Local MvParDef:=""
	Local cTiFil  :=""
	Local cOpcao  :=""
	Local nTamKey :=01
	Local MvPar
	Private aSit:={}

	DEFAULT lTipoRet := .T.

	IF lTipoRet
		MvPar:=&(Alltrim(ReadVar()))// Carrega Nome da Variavel do Get em Questao
		mvRet:=Alltrim(ReadVar())	// Iguala Nome da Variavel ao Nome variavel de Retorno
	EndIF

	Aadd(aSit,"Boleto Bancário")
	Aadd(aSit,"Mapa Fat. por Pedido")
	Aadd(aSit,"Mapa Fat. por Processo")
	Aadd(aSit,"Mapa Movim. de Produto")
	Aadd(aSit,"Pré-Nota")

	MvParDef:="12345"

	cTitulo :="Filtro Customizado"
	nElemRet:=Len(aSit)

	IF lTipoRet
		If	f_Opcoes(@MvPar    ,;//Variavel de Retorno
			cTitulo            ,;//Titulo da Coluna com as opcoes
			@aSit              ,;//Opcoes de Escolha (Array de Opcoes)
			@MvParDef          ,;//String de Opcoes para Retorno
			NIL                ,;//Nao Utilizado
			NIL                ,;//Nao Utilizado
			.F.                ,;//Se a Selecao sera de apenas 1 Elemento por vez
			nTamKey            ,;//Tamanho da Chave
			nElemRet           ,;//No maximo de elementos na variavel de retorno
			.T.                ,;//Inclui Botoes para Selecao de Multiplos Itens
			.F.                ,;//Se as opcoes serao montadas a partir de ComboBox de Campo ( X3_CBOX )
			NIL                ,;//Qual o Campo para a Montagem do aOpcoes
			.F.                ,;//Nao Permite a Ordenacao
			.F.                ,;//Nao Permite a Pesquisa
			.F.                ,;//Forca o Retorno Como Array
			""                  ;//Consulta F3
			)
			&MvRet := mvpar// Devolve Resultado
		EndIF
	EndIF
Return( IF( lTipoRet , .T. , MvParDef ) )