#Include "Totvs.ch"
#Include "FwMVCDef.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Portal Cliente - Consulta Saldo Produtos por Endereco   !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 02/2017 !
+------------------+--------------------------------------------------------*/

User Function TPRTV002()

	// variaveis temporarias
	local _nSigla, _nCpoBrw
	local _nPosStr

	// objeto browse
	Local _oBrwSldEnd := Nil
	// filtro por sigla
	local _cFilSigla := ""

	// campos do cabecalho
	local _aCposCabec := {}

	// estrutura dos campos iniciais do browse
	local _aStrArqTrb := {}
	local _cAlArqTrb  := GetNextAlias()
	local _aSeekTrb   := {}
	local _cTrbInd1, _cTrbInd2
	local _aCpoFilter := {}

	// query de dados
	local _cQuery

	// titulo
	Private cCadastro := "Saldo Atual Por Endereço de Produtos em: " + DtoC( Date() )

	// controle de opcoes do menu
	Private aRotina := MenuDef()

	// valida do login do usuario
	If ( ! U_FtPrtVld(__cUserId) )
		Return(.f.)
	EndIf

	// define filtro por sigla
	For _nSigla := 1 to Len(___aPrtSigla)
		_cFilSigla += ___aPrtSigla[_nSigla] + "|"
	Next _nSigla

	// define campos e colunas do browse
	aAdd(_aCposCabec, {"BF_PRODUTO", .F., "Código Produto"           , PesqPict("SBF", "BF_PRODUTO"),0 ,  5, 0                      , .F.})
	aAdd(_aCposCabec, {"B1_CODCLI" , .T., "Código Produto/SKU"       , PesqPict("SB1", "B1_CODCLI") ,0 ,  5, 0                      , .T.})
	aAdd(_aCposCabec, {"B1_DESC"   , .T., "Descrição do Produto"     , PesqPict("SB1", "B1_DESC")   ,0 , 40, 0                      , .T.})
	aAdd(_aCposCabec, {"BF_LOCAL"  , .T., "Armazém"                  , PesqPict("SBF", "BF_LOCAL")  ,0 ,  5, 0                      , .F.})
	aAdd(_aCposCabec, {"BF_LOCALIZ", .T., "Endereço/Localização"     , PesqPict("SBF", "BF_LOCALIZ"),0 ,  5, 0                      , .F.})
	aAdd(_aCposCabec, {"BF_LOTECTL", .T., "Lote"                     , PesqPict("SBF", "BF_LOTECTL"),0 ,  5, 0                      , .F.})
	aAdd(_aCposCabec, {"BF_QUANT"  , .T., "Quantidade Atual"         , PesqPict("SBF", "BF_QUANT")  ,1 ,  5, TamSx3("BF_QUANT")[2]  , .T.})

	// define estrutura dos campos iniciais do browse
	_aStrArqTrb := sfDefCpoPad(_aCposCabec, .F.)

	// antes de criar a tabela, verificar se a mesma já foi aberta
	If (Select(_cAlArqTrb) <> 0)
		(_cAlArqTrb)->(dbSelectArea(_cAlArqTrb))
		(_cAlArqTrb)->(dbCloseArea())
	Endif

	// cria o TRB
	_oAlTrb := FWTemporaryTable():New(_cAlArqTrb)
	_oAlTrb:SetFields(_aStrArqTrb)
	_oAlTrb:AddIndex("01", {"B1_CODCLI"} )
	_oAlTrb:AddIndex("02", {"B1_DESC"} )
	_oAlTrb:Create()

	// prepara queru para filtro de dados
	_cQuery := " SELECT BF_PRODUTO, "
	_cQuery += "        B1_CODCLI, "
	_cQuery += "        B1_DESC, "
	_cQuery += "        BF_LOCAL, "
	_cQuery += "        BF_LOCALIZ, "
	_cQuery += "        BF_LOTECTL, "
	_cQuery += "        BF_QUANT "
	// saldo do produto
	_cQuery += " FROM   " + RetSqlTab("SBF") + " (NOLOCK) "
	// cad. do produto
	_cQuery += "        INNER JOIN " + RetSqlTab("SB1") + " (NOLOCK) "
	_cQuery += "                ON " + RetSqlCond("SB1")
	_cQuery += "                   AND B1_COD = BF_PRODUTO "
	// filtro padrao
	_cQuery += " WHERE  " + RetSqlCond("SBF")
	_cQuery += "        AND Substring(BF_PRODUTO, 1, 4) IN " + FormatIn(_cFilSigla, "|")

	// atualiza os dados do TRB
	U_SqlToTrb(_cQuery, _aStrArqTrb, _cAlArqTrb)

	// abre TRB e posiciona no primeiro registro
	(_cAlArqTrb)->(dbSelectArea(_cAlArqTrb))
	(_cAlArqTrb)->(DbGoTop())

	// campos que irão compor o combo de pesquisa na tela principal
	Aadd(_aSeekTrb,{"Código Produto/SKU"  , {{"", "C", TamSx3("B1_CODCLI")[1], 0, "B1_CODCLI", "@!"}}, 1, .T. } )
	Aadd(_aSeekTrb,{"Descrição do Produto", {{"", "C", TamSx3("B1_DESC")[1]  , 0, "B1_DESC"  , "@!"}}, 2, .T. } )

	// campos que irão compor a tela de filtro
	For _nCpoBrw := 1 to Len(_aCposCabec)

		// valida se campo deve ser apresentado no browse
		If (_aCposCabec[_nCpoBrw][8])

			// busca dados da estrutura
			_nPosStr := aScan(_aStrArqTrb,{|x| (AllTrim(x[1]) == AllTrim(_aCposCabec[_nCpoBrw][1])) })

			// inclui coluna
			Aadd(_aCpoFilter,{        ;
			_aCposCabec[_nCpoBrw][1] ,;
			_aCposCabec[_nCpoBrw][3] ,;
			_aStrArqTrb[_nPosStr][2] ,;
			_aStrArqTrb[_nPosStr][3] ,;
			_aStrArqTrb[_nPosStr][4] ,;
			_aCposCabec[_nCpoBrw][4] })

		EndIf

	Next _nCpoBrw

	// cria objeto do browse
	_oBrwSldEnd := FWMBrowse():New()
	_oBrwSldEnd:SetAlias(_cAlArqTrb)
	_oBrwSldEnd:SetDescription( cCadastro )
	_oBrwSldEnd:SetSeek(.T., _aSeekTrb)
	_oBrwSldEnd:SetTemporary(.T.)
	_oBrwSldEnd:SetLocate()
	_oBrwSldEnd:SetUseFilter(.T.)
	_oBrwSldEnd:SetDBFFilter(.T.)
	_oBrwSldEnd:SetFilterDefault( "" )
	_oBrwSldEnd:SetFieldFilter(_aCpoFilter)
	_oBrwSldEnd:DisableDetails()

	// inclui etalhes das colunas que serão exibidas
	For _nCpoBrw := 1 to Len(_aCposCabec)

		// valida se campo deve ser apresentado no browse
		If (_aCposCabec[_nCpoBrw][2])
			// inclui coluna
			_oBrwSldEnd:SetColumns(sfAddColumn(_aCposCabec[_nCpoBrw][1], _aCposCabec[_nCpoBrw][3], _aCposCabec[_nCpoBrw][4], _aCposCabec[_nCpoBrw][5], _aCposCabec[_nCpoBrw][6], _aCposCabec[_nCpoBrw][7]))
		EndIf
	Next _nCpoBrw

	// ativa objeto browse
	_oBrwSldEnd:Activate()

	// exclui informacoes temporarias
	If (Select(_cAlArqTrb) <> 0)
		(_cAlArqTrb)->(dbSelectArea(_cAlArqTrb))
		(_cAlArqTrb)->(__DbZap())
		(_cAlArqTrb)->(dbCloseArea())
		_oAlTrb:Delete()
	Endif

Return

// ** funcao para definir o menu
Static Function MenuDef()
	// variavel de retorno
	Local _aRetMenu := {}
Return(_aRetMenu)

// ModelDef - Modelo padrao para MVC
Static Function ModelDef()

	// variaveis para modelo
	Local _oModel    := Nil
	Local _oStrCbSBF := FWFormStruct( 1, 'SBF' )

	// Cria o formulario
	_oModel := MPFormModel():New('MD_TPRTV002')
	// define campos do cabecalho
	_oModel:AddFields("SBFMASTER", Nil, _oStrCbSBF)
	//Descrição do modelo
	_oModel:SetDescription("Saldo Atual por Endereços de Produtos")

Return( _oModel )

// ** Função que define a interface da relacao de estoque para o MVC
Static Function ViewDef()

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local _oModel := FWLoadModel('TPRTV002')
	Local _oView  := Nil
	// Cria a estrutura a ser usada na View
	Local _oStrSBF := FWFormStruct( 2, 'SBF', { |_cCampo| AllTrim(_cCampo) == "BF_FILIAL" .Or. aScan(_aCposCabec, AllTrim(_cCampo) ) > 0 } )

	// Cria o objeto de View
	_oView := FWFormView():New()
	// Define qual o Modelo de dados será utilizado na View
	_oView:SetModel( _oModel )
	// Adiciona no nosso View um controle do tipo formulário
	_oView:AddField( 'VIEW_SBF', _oStrSBF, 'SBFMASTER' )
	// Criar um "box" horizontal para receber algum elemento da view
	_oView:CreateHorizontalBox( 'TELA' , 100 )
	// Relaciona o identificador (ID) da View com o "box" para exibição
	_oView:SetOwnerView( 'VIEW_SBF', 'TELA' )

Return( _oView )

// funcao para definicao dos campos iniciais do browse
Static Function sfDefCpoPad(mvCposCabec, mvDefBrowse)
	// variavel de retorno
	Local _aFields := {}
	// variaveis temporarias
	local _nCpo
	local _cTmpCpo

	// varre todos os campos esperados
	For _nCpo := 1 to Len(mvCposCabec)
		
		cX3Campo := GetSX3Cache(mvCposCabec[_nCpo][1],"X3_CAMPO")
		cX3Tipo  := GetSX3Cache(mvCposCabec[_nCpo][1],"X3_TIPO")
		nX3Taman := GetSX3Cache(mvCposCabec[_nCpo][1],"X3_TAMANHO")
		nX3Decim := GetSX3Cache(mvCposCabec[_nCpo][1],"X3_DECIMAL")
		
		If ! Empty(cX3Campo)
			aAdd( _aFields, { ;
				  cX3Campo	 ,;
				  cX3Tipo	 ,;
				  nX3Taman	 ,;
				  nX3Decim	})
		EndIf
		
	Next _nCpo


Return( _aFields )

// ** funcao que cria as colunas e detalhes do browse
Static Function sfAddColumn(mvCampo, mvTitulo, mvPicture, mvAlign, mvSize, mvDecimal)

	Local _aColumn
	Local _bData := &("{||" + mvCampo +"}")

	/* Array da coluna
	[n][01] Título da coluna
	[n][02] Code-Block de carga dos dados
	[n][03] Tipo de dados
	[n][04] Máscara
	[n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
	[n][06] Tamanho
	[n][07] Decimal
	[n][08] Indica se permite a edição
	[n][09] Code-Block de validação da coluna após a edição
	[n][10] Indica se exibe imagem
	[n][11] Code-Block de execução do duplo clique
	[n][12] Variável a ser utilizada na edição (ReadVar)
	[n][13] Code-Block de execução do clique no header
	[n][14] Indica se a coluna está deletada
	[n][15] Indica se a coluna será exibida nos detalhes do Browse
	[n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
	*/
	// define estrutura da coluna
	_aColumn := {mvTitulo, _bData, Nil, mvPicture, mvAlign, mvSize, mvDecimal, .F., {||.T.}, .F., {||.T.}, Nil, {||.T.}, .F., .F., {}}

Return{ _aColumn }