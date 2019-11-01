#include "protheus.ch"
#include "parmtype.ch"
#Include "FwMVCDef.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Portal Cliente - Consulta Acompanhamento de Pedidos     !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 02/2017 !
+------------------+--------------------------------------------------------*/

User Function TPRTV004()

	// lista de pergunta (parametros)
	Local _vPerg := {}
	local _cPerg := PadR("TPRTV004",10)

	// variaveis temporarias
	local _nSigla, _nCpoBrw
	local _nCodCli
	local _nPosStr

	// filtro por sigla
	local _cFilSigla := ""

	// objeto browse
	Local _oBrwMntPed := Nil

	// campos do cabecalho
	local _aCposCabec := {}

	// estrutura dos campos iniciais do browse
	local _aStrArqTrb := {}
	local _cAlArqTrb  := GetNextAlias()
	local _cNomArqTrb := GetNextAlias()
	local _aSeekTrb   := {}
	local _aCpoFilter := {}

	// variaveis para filtro
	Private mvDataDe   := (Date()-7) //mv_par01
	Private mvDataAte  := Date()     //mv_par02

	// filtro por codigo do cliente
	private _cFilCodCli := ""

	// titulo da tela principal
	Private cCadastro := "Monitor de Pedidos de Venda/Separação"

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

	// define filtro por codigo de cliente
	For _nCodCli := 1 to Len(___aPrtDepos)
		_cFilCodCli += ___aPrtDepos[_nCodCli][1] + "|"
	Next _nCodCli

	// lista de perguntas (parametros)
	aAdd(_vPerg,{"Data De?" , "D", 8, 0, "G", Nil,"",}) //mv_par01
	aAdd(_vPerg,{"Data Até?", "D", 8, 0, "G", Nil,"",}) //mv_par02

	// cria grupo de perguntas
	U_FtCriaSX1( _cPerg, _vPerg )

	// apresenta perguntas na tela
	If ( ! Pergunte(_cPerg, .T.) )
		Return
	EndIf

	// atualiza as variaveis
	mvDataDe   := mv_par01
	mvDataAte  := mv_par02

	// define campos e colunas do browse
	aAdd(_aCposCabec, {"C5_ZPEDCLI", .T., "Pedido CLIENTE"          , PesqPict("SC5", "C5_ZPEDCLI") ,0 ,  5, 0                      , .T., Nil, Nil, Nil})
	aAdd(_aCposCabec, {"C5_ZCLIENT", .T., "Cliente Entrega"         , PesqPict("SC5", "C5_ZCLIENT") ,0 , 10, 0                      , .T., Nil, Nil, Nil})
	aAdd(_aCposCabec, {"C5_NOTA"   , .T., "Nota Fiscal Retorno"     , PesqPict("SC5", "C5_NOTA")    ,0 ,  5, 0                      , .T., Nil, Nil, Nil})
	aAdd(_aCposCabec, {"C5_ZDOCCLI", .T., "Nota Fiscal Venda"       , PesqPict("SC5", "C5_ZDOCCLI") ,0 ,  5, 0                      , .T., Nil, Nil, Nil})
	aAdd(_aCposCabec, {"STS_NF_RET", .T., "Status Nota Retorno"     , "@!"                          ,0 , 20, 0                      , .F., "C", 100, 0  })
	aAdd(_aCposCabec, {"STS_SEPARA", .T., "Status Separação"        , "@!"                          ,0 , 20, 0                      , .F., "C", 100, 0  })
	aAdd(_aCposCabec, {"STS_MNTVOL", .T., "Status Montagem Volumes" , "@!"                          ,0 , 20, 0                      , .F., "C", 100, 0  })
	aAdd(_aCposCabec, {"STS_CARREG", .T., "Status Carregamento"     , "@!"                          ,0 , 20, 0                      , .F., "C", 100, 0  })
	aAdd(_aCposCabec, {"C5_NUM"    , .T., "Pedido TECADI"           , PesqPict("SC5", "C5_NUM")     ,0 ,  5, 0                      , .F., Nil, Nil, Nil})
	aAdd(_aCposCabec, {"C5_EMISSAO", .T., "Dt.Registro.TECADI"      , PesqPict("SC5", "C5_EMISSAO") ,0 ,  5, 0                      , .T., Nil, Nil, Nil})

	// define estrutura dos campos iniciais do browse
	_aStrArqTrb := sfDefCpoPad(_aCposCabec, .F.)

	// antes de criar a tabela, verificar se a mesma já foi aberta
	If (Select(_cAlArqTrb) <> 0)
		(_cAlArqTrb)->(dbSelectArea(_cAlArqTrb))
		(_cAlArqTrb)->(dbCloseArea())
	Endif

	//Criar tabela temporária
	_oAlTrb := FWTemporaryTable():New(_cAlArqTrb)
	_oAlTrb:SetFields(_aStrArqTrb)
	_oAlTrb:AddIndex("01", {"C5_ZPEDCLI"} )
	_oAlTrb:AddIndex("02", {"C5_ZDOCCLI"} )
	_oAlTrb:Create()

	// busca dados
	sfRfrDados( .T., _cAlArqTrb, _aStrArqTrb )

	// abre TRB e posiciona no primeiro registro
	(_cAlArqTrb)->(dbSelectArea(_cAlArqTrb))
	(_cAlArqTrb)->(DbGoTop())

	// campos que irão compor o combo de pesquisa na tela principal
	Aadd(_aSeekTrb,{"Pedido DEPOSITANTE", {{"", "C", TamSx3("C5_ZPEDCLI")[1], 0, "C5_ZPEDCLI", "@!"}}, 1, .T. } )
	Aadd(_aSeekTrb,{"Nota Fiscal Venda" , {{"", "C", TamSx3("C5_ZDOCCLI")[1], 0, "C5_ZDOCCLI", "@!"}}, 2, .T. } )

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
	_oBrwMntPed := FWMBrowse():New()
	_oBrwMntPed:SetAlias(_cAlArqTrb)
	_oBrwMntPed:SetDescription( cCadastro )
	_oBrwMntPed:SetSeek(.T., _aSeekTrb)
	_oBrwMntPed:SetTemporary(.T.)
	_oBrwMntPed:SetLocate()
	_oBrwMntPed:SetUseFilter(.T.)
	_oBrwMntPed:SetDBFFilter(.T.)
	_oBrwMntPed:SetFilterDefault( "" )
	_oBrwMntPed:SetFieldFilter(_aCpoFilter)
	_oBrwMntPed:DisableDetails()

	// inclui etalhes das colunas que serão exibidas
	For _nCpoBrw := 1 to Len(_aCposCabec)

		// valida se campo deve ser apresentado no browse
		If (_aCposCabec[_nCpoBrw][2])
			// inclui coluna
			_oBrwMntPed:SetColumns(sfAddColumn(_aCposCabec[_nCpoBrw][1], _aCposCabec[_nCpoBrw][3], _aCposCabec[_nCpoBrw][4], _aCposCabec[_nCpoBrw][5], _aCposCabec[_nCpoBrw][6], _aCposCabec[_nCpoBrw][7]))
		EndIf
	Next _nCpoBrw

	// ativa objeto browse
	_oBrwMntPed:Activate()

	// exclui informacoes temporarias
	If ( ! Empty(_cNomArqTrb) )
		fErase(_cNomArqTrb + GetDBExtension())
		fErase(_cNomArqTrb + OrdBagExt())
		(_cAlArqTrb)->(DbCloseArea())
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

		// valida se eh campo com permissao de uso
		If ! Empty(cX3Campo)
			// campo do dicionario de dados
			aAdd( _aFields, { ;
				  cX3Campo	 ,;
				  cX3Tipo	 ,;
				  nX3Taman	 ,;
				  nX3Decim	})

		Else
			// padroniza tamanho do campo
			_cTmpCpo := PadR(mvCposCabec[_nCpo][1],10)
			
			// campo criado em tempo de execucao
			aAdd( _aFields, {      ;
			_cTmpCpo              ,;
			mvCposCabec[_nCpo][ 9],;
			mvCposCabec[_nCpo][10],;
			mvCposCabec[_nCpo][11]})

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

// ** funcao usada para atualizar os dados
Static Function sfRfrDados(mvFirst, mvAlArqTrb, mvStrArqTrb)
	MsgRun("Atualizando a Tela do Monitor de Serviços...", "Aguarde...", {|| CursorWait(), sfSelDados(mvFirst, mvAlArqTrb, mvStrArqTrb), CursorArrow()})
Return( Nil )

// ** funcao para filtrar servicos de acordo com os parametros e configuracao do operador
Static Function sfSelDados(mvFirst, mvAlArqTrb, mvStrArqTrb)
	// query dos dados
	local _cQuery := ""
	// area inicial do TRB
	local _aAreaTRB := IIf(mvFirst, Nil, (mvAlArqTrb)->(GetArea()))

	// limpa o conteudo do TRB
	If ( ! mvFirst )
		dbSelectArea(mvAlArqTrb)
		__DbZap()
	EndIf

	// prepara query para extracao de dados
	_cQuery := " SELECT C5_FILIAL, "
	_cQuery += "        C5_NUM, "
	_cQuery += "        C5_ZPEDCLI, "
	_cQuery += "        C5_ZCLIENT, "
	_cQuery += "        C5_NOTA, "
	_cQuery += "        CASE "
	_cQuery += "          WHEN C5_NOTA != '' THEN 'NOTA RETORNO EMITIDA' "
	_cQuery += "          ELSE 'AGUARDANDO EMISSÃO DE NOTA FISCAL DE RETORNO' "
	_cQuery += "        END                                                                  STS_NF_RET, "
	_cQuery += "        C5_EMISSAO, "
	_cQuery += "        C5_ZDOCCLI, "
	_cQuery += "        C5_ZCARGA, "
	_cQuery += "        Sum(C6_QTDVEN)                                                       QTD_PEDIDO, "
	_cQuery += "        Sum(C9_QTDLIB)                                                       QTD_LIB_PED, "
	_cQuery += " (SELECT CASE                                                                   "
	_cQuery += "                 WHEN ( Z06_STATUS = 'EX' ) THEN 'EM PROCESSO DE SEPARAÇÃO'     "
	_cQuery += "                 WHEN ( Z06_STATUS = 'FI' ) THEN 'SEPARAÇÃO CONCLUÍDA'          "
	_cQuery += "                 WHEN ( Z06_STATUS = 'PL' )                                     "
	_cQuery += "                       OR ( Z06_STATUS = 'AG' ) THEN 'GERADO MAPA DE SEPARAÇÃO' "
	_cQuery += "                 ELSE '-'                                                       "
	_cQuery += "               END                                                              "
	_cQuery += "        FROM   (SELECT Z06_STATUS                                               "
	_cQuery += "                FROM " + RetSqlTab("Z06")
	_cQuery += "                WHERE " + RetSqlCond("Z06")
	_cQuery += "                       AND Z06_SEQOS = '001'                                    "
	_cQuery += "                       AND Z06_NUMOS = C5_ZNOSSEP) AS SEPARA) STS_SEPARA,       "
	_cQuery += "       (SELECT CASE                                                             "
	_cQuery += "                 WHEN ( Z06_STATUS = 'EX' ) THEN 'EM PROCESSO DE MONTAGEM'      "
	_cQuery += "                 WHEN ( Z06_STATUS = 'FI' ) THEN 'MONTAGEM DE VOLUMES CONCLUIDA'"
	_cQuery += "                 WHEN ( Z06_STATUS = 'PL' )                                     "
	_cQuery += "                       OR ( Z06_STATUS = 'AG' ) THEN 'AGUARDANDO'               "
	_cQuery += "                 ELSE '-'                                                       "
	_cQuery += "               END                                                              "
	_cQuery += "        FROM   (SELECT Z06_STATUS                                               "
	_cQuery += "                FROM " + RetSqlTab("Z06")
	_cQuery += "                WHERE " + RetSqlCond("Z06")
	_cQuery += "                       AND Z06_SEQOS = '002'                                    "
	_cQuery += "                       AND Z06_NUMOS = C5_ZNOSMNT) AS MONTAG) STS_MNTVOL,       "
	_cQuery += "       (SELECT CASE                                                             "
	_cQuery += "                 WHEN ( Z06_STATUS = 'EX' ) THEN 'EM PROCESSO DE CARREGAMENTO'  "
	_cQuery += "                 WHEN ( Z06_STATUS = 'FI' ) THEN 'CARREGAMENTO CONCLUIDO'       "
	_cQuery += "                 WHEN ( Z06_STATUS = 'PL' )                                     "
	_cQuery += "                       OR ( Z06_STATUS = 'AG' ) THEN 'AGUARDANDO'               "
	_cQuery += "                 ELSE '-'                                                       "
	_cQuery += "               END                                                              "
	_cQuery += "        FROM   (SELECT Z06_STATUS                                               "
	_cQuery += "                FROM " + RetSqlTab("Z06")
	_cQuery += "                WHERE " + RetSqlCond("Z06")
	_cQuery += "                       AND Z06_SEQOS = '001'                                    "
	_cQuery += "                       AND Z06_NUMOS = C5_ZNOSEXP) AS CARREG) STS_CARREG        "
	_cQuery += " FROM   " + RetSqlTab("SC5") + " (NOLOCK) "
	_cQuery += "        INNER JOIN " + RetSqlTab("SC6") + " (NOLOCK) "
	_cQuery += "                ON " + RetSqlCond("SC6")
	_cQuery += "                   AND C6_NUM = C5_NUM "
	_cQuery += "        INNER JOIN " + RetSqlTab("SC9") + " (NOLOCK) "
	_cQuery += "                ON " + RetSqlCond("SC9")
	_cQuery += "                   AND C9_PEDIDO = C6_NUM "
	_cQuery += "                   AND C9_ITEM = C6_ITEM "
	_cQuery += "                   AND C9_PRODUTO = C6_PRODUTO "
	_cQuery += "                   AND C9_CARGA != '' "
	_cQuery += " WHERE  " + RetSqlCond("SC5")
	_cQuery += "        AND C5_TIPOOPE = 'P' "
	// filtro por cliente
	_cQuery += "        AND C5_CLIENTE IN " + FormatIn(_cFilCodCli,"|")
	// filtro por data
	_cQuery += "        AND C5_EMISSAO BETWEEN '" + DtoS(mvDataDe) + "' AND '" + DtoS(mvDataAte) + "' "
	// agrupamento de colunas
	_cQuery += " GROUP  BY C5_FILIAL,  "
	_cQuery += "           C5_NUM,     "
	_cQuery += "           C5_ZPEDCLI, "
	_cQuery += "           C5_ZCLIENT, "
	_cQuery += "           C5_NOTA,    "
	_cQuery += "           C5_EMISSAO, "
	_cQuery += "           C5_ZCARGA,  "
	_cQuery += "           C5_CLIENTE, "
	_cQuery += "           C5_LOJACLI, "
	_cQuery += "           C9_CARGA,   "
	_cQuery += "           C5_ZDOCCLI, "
	_cQuery += "           C5_ZNOSSEP, "
	_cQuery += "           C5_ZNOSMNT, "
	_cQuery += "           C5_ZNOSEXP  "

//	memowrit("c:\query\tprtv004_sfSelDados.txt", _cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery, mvStrArqTrb, (mvAlArqTrb))

	// varre todos o TRB para atualizar o status
	dbSelectArea(mvAlArqTrb)
	(mvAlArqTrb)->(dbSetOrder(1))
	(mvAlArqTrb)->(dbGoTop())

	// reposiciona cursor no browse
	If (mvFirst)
		dbSelectArea(mvAlArqTrb)
		(mvAlArqTrb)->(dbGoTop())
	ElseIf (!mvFirst)
		// area inicial do TRB
		RestArea(_aAreaTRB)
	EndIf

Return( Nil )