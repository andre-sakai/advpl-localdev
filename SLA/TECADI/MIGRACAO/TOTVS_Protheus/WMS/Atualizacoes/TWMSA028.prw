#include "totvs.ch"

/*---------------------------------------------------------------------------+
!                         FICHA TECNICA DO PROGRAMA                          !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para geracao de OS de retrabalho                 !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 06/2015 !
+------------------+--------------------------------------------------------*/

User Function TWMSA028(mvNumOs)

	// dimensoes da tela
	Local _aSizeWnd := MsAdvSize()

	// grupo de perguntas
	Local _cPerg := PadR("TWMSA028",10)

	// lista de pergunta (parametros)
	Local _vPerg := {}

	// query
	local _cQuery  := ""
	Local _aRetSQL := {}

	Local _aHead := {}
	Local _aCols := {}
	Local _nLin  := 0
	Local _nx    := 0

	// objetos da tela
	Local _oSayEndDes, _oSayNrOs

	// Campos a serem alterados pelo usuario
	Local _aAltEnch := {}
	// Opção da MsNewGetDados
	Local _nOpcX	:= GD_UPDATE

	Local _cSeqOS     := ""
	Local _cIdPltOrdSrv  := ""

	// seq OS de devolucao
	local _cSeqOsDev := ""

	// valor padrao
	Default mvNumOs := CriaVar("Z05_NUMOS", .f.)

	// opção escolhida
	Private _nOpc := Aviso("TWMSA028","Selecione a opção desejada:",{"Nova OS","Gera Mapa","Fechar"})

	// selecionar a opcao de operacao
	Private _lGeraMapa := ( _nOpc == 2 )

	// endereco de destino
	Private _cEndDest := CriaVar("BE_LOCALIZ",.F.)
	Private _aMapaApanhe := {}

	// fontes utilizadas
	Private _oFnt01 := TFont():New("Tahoma",,18,,.T.)

	// posicao dos campos
	Private _nPosMARK   := 0
	Private _nPosLOCA   := 0
	Private _nPosCALI   := 0
	Private _nPosETQP   := 0
	Private _nPosPROD   := 0
	Private _nPosSALD   := 0
	Private _nPosRegra  := 0
	Private _nPosEndDes := 0
	Private _nPosLote   := 0

	// variaveis recebidas de parametro
	private _cNumOrdSrv := mvNumOS
	private _cSeqOrdSrv := ""

	// se escolheu fechar a tela
	If ( _nOpc == 3 )
		Return
	EndIf

	// grupo de perguntas
	aAdd(_vPerg,{"Cliente:"            ,"C",TamSx3("A1_COD")[1]  ,0,"G",,"SA1", {{"X1_VALID","U_FtStrZero()"}} }) // mv_par01
	aAdd(_vPerg,{"Loja:"               ,"C",TamSx3("A1_LOJA")[1] ,0,"G",,""   , {{"X1_VALID","U_FtStrZero()"}} }) // mv_par02
	aAdd(_vPerg,{"Armazém:"            ,"C",TamSx3("BE_LOCAL")[1],0,"G",,"Z12", {{"X1_VALID","U_FtStrZero()"}} }) // mv_par03
	aAdd(_vPerg,{"Rua De:"             ,"C",2,0,"G",,""})                          // mv_par04
	aAdd(_vPerg,{"Rua Até:"            ,"C",2,0,"G",,""})                          // mv_par05
	aAdd(_vPerg,{"Lado:"               ,"N",1,0,"C",{"Ambos","A","B"},""})         // mv_par06
	aAdd(_vPerg,{"Prédio De:"          ,"C",2,0,"G",,""})                          // mv_par07
	aAdd(_vPerg,{"Prédio Até:"         ,"C",2,0,"G",,""})                          // mv_par08
	aAdd(_vPerg,{"Nível De:"           ,"C",2,0,"G",,""})                          // mv_par09
	aAdd(_vPerg,{"Nível Até:"          ,"C",2,0,"G",,""})                          // mv_par10
	aAdd(_vPerg,{"Endereço De:"        ,"C",TamSx3("BE_LOCALIZ")[1],0,"G",,"SBE"}) // mv_par11
	aAdd(_vPerg,{"Endereço Até:"       ,"C",TamSx3("BE_LOCALIZ")[1],0,"G",,"SBE"}) // mv_par12
	aAdd(_vPerg,{"Produto De:"         ,"C",TamSx3("B1_COD")[1],0,"G",,"SB1"})     // mv_par13
	aAdd(_vPerg,{"Produto Até:"        ,"C",TamSx3("B1_COD")[1],0,"G",,"SB1"})     // mv_par14
	aAdd(_vPerg,{"Transf. Paletes?"    ,"N",1,0,"C",{"Sim","Não"},Nil})            // mv_par15

	// cria grupo de perguntas
	U_FtCriaSX1(_cPerg, _vPerg)

	// apresenta parametros
	If ( ! _lGeraMapa )
		If ! Pergunte(_cPerg, .T.)
			Return ()
		EndIf
		// se for geracao de mapa de devolucao
	ElseIf ( _lGeraMapa )

		// posiciona na Ordem de Servico
		dbSelectArea("Z05")
		Z05->(dbSetOrder(1)) // 1-Z05_FILIAL, Z05_NUMOS
		Z05->(dbSeek( xFilial("Z05")+_cNumOrdSrv ))

		// valida se a OS está disponivel Buscando a Tarefa T05 Finalizada.
		_cSeqOsDev := sfVldMapa(_cNumOrdSrv, "009", .F.)

		// se nao validou, cancela processo
		If ( Empty(_cSeqOsDev) )
			Aviso("TWMSA028","Ordem de Serviço " + _cNumOrdSrv + " não liberada para emissão do mapa.",{"Fechar"})
			Return(.f.)
		EndIf

		// posiciona no item da Ordem de Servico
		dbSelectArea("Z06")
		Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
		Z06->(dbSeek( xFilial("Z06") + _cNumOrdSrv + _cSeqOsDev ))

		// se ja estiver finalizada
		If (Z06->Z06_STATUS == "FI")
			Aviso("TWMSA028","Ordem de Serviço " + _cNumOrdSrv + " não liberada para emissão do mapa, pois encontra-se finalizada!",{"Fechar"})
			Return(.f.)
		EndIf

		// valida se a OS está disponivel Buscando a Tarefa T05 Finalizada.
		_cSeqOrdSrv := sfVldMapa(_cNumOrdSrv, "T05", .T.)

		// se nao validou, cancela processo
		If ( Empty(_cSeqOrdSrv) )
			Aviso("TWMSA028","Ordem de Serviço "+_cNumOrdSrv+" não liberada para emissão do mapa.",{"Fechar"})
			Return(.f.)
		EndIf

		// posiciona no item da Ordem de Servico
		dbSelectArea("Z06")
		Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
		Z06->(dbSeek( xFilial("Z06") + _cNumOrdSrv + _cSeqOrdSrv ))

		// executa perguntas, para preencher mv_par??
		Pergunte(_cPerg, .f.)

		// atualiza parametros
		mv_par01 := Z05->Z05_CLIENT // Cliente
		mv_par02 := Z05->Z05_LOJA   // Loja
		mv_par03 := Z06->Z06_LOCAL  // Armazém
		mv_par04 := "  "            // Rua De
		mv_par05 := "ZZ"            // Rua Ate
		mv_par06 := 1               // Lado (1-Ambos/2-A/3-B)
		mv_par07 := "  "            // Prédio De
		mv_par08 := "ZZ"            // Prédio Ate
		mv_par09 := "  "            // Nivel De
		mv_par10 := "ZZ"            // Nivel Ate
		mv_par11 := Z06->Z06_ENDSRV // Endereco De
		mv_par12 := Z06->Z06_ENDSRV // Endereco Ate
		mv_par15 := 1               // Transf. Paletes? (1-Sim/2-Nao)

		//Busca Seguencia de OS para a Tarefa "002"
		_cSeqOS := sfVldMapa(_cNumOrdSrv, "002", .F.)
		//Monta filtro de Palet para a OS correspondente.
		_cIdPltOrdSrv := sfPltOrdSrv(_cNumOrdSrv, _cSeqOS)

	EndIf

	// pesquisa o cliente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1))
	If ! (SA1->(dbSeek(xFilial("SA1") + MV_PAR01 + MV_PAR02 )))
		Aviso("TWMSA028","Cliente Informado não Cadastrado!",{"Fechar"})
		Return()
	EndIf

	// valida se cliente/loja está configurado para permitir OS do retrabalho
	IF !(U_FTVldSrv(MV_PAR01, MV_PAR02, "T05", "T05"))
		MsgAlert("Cliente " + MV_PAR01 + "/" + MV_PAR02 + " não configurado para retrabalho!","Não permitido - TWMSA028")
		Return (.F.)
	EndIf

	// prepara query para filtrar dados
	_cQuery := "SELECT BF_LOCAL, "
	_cQuery += "       BF_LOCALIZ, "
	_cQuery += "       Z16_ETQPAL, "
	_cQuery += "       BF_PRODUTO, "
	_cQuery += "       Sum(Z16_SALDO) Z16_SALDO, "
	_cQuery += "       Z16_LOTCTL "

	// saldo por endereco
	_cQuery += " FROM   "+RetSqlTab("SBF")

	// composicao do palete
	_cQuery += "       INNER JOIN "+RetSqlTab("Z16")
	_cQuery += "               ON "+RetSqlCond("Z16")
	_cQuery += "                  AND Z16_LOCAL = BF_LOCAL "
	_cQuery += "                  AND Z16_ENDATU = BF_LOCALIZ "
	_cQuery += "                  AND Z16_CODPRO = BF_PRODUTO "
	_cQuery += "                  AND Z16_LOTCTL = BF_LOTECTL "

	If ( _lGeraMapa )
		// pallets vinculados de alguma forma à OS correspondente
		_cQuery += "              AND (Z16_ETQPAL  IN " + FormatIn(_cIdPltOrdSrv, ";") + " OR Z16_PLTORI  IN " + FormatIn(_cIdPltOrdSrv, ";") + ") "
	EndIf
	// somente saldo
	_cQuery += "                  AND Z16_SALDO > 0 "
	// filtro padrao
	_cQuery += " WHERE  " + RetSqlCond("SBF")
	// armazem
	_cQuery += "       AND BF_LOCAL = '" + mv_par03 + "' "
	// endereco
	_cQuery += "       AND BF_LOCALIZ BETWEEN '" + mv_par11 + "' AND '" + mv_par12 + "' "
	// descarta enderecos reservados para movimentacao
	_cQuery += "       AND BF_LOCALIZ NOT IN (SELECT DISTINCT Z08_ENDORI "
	_cQuery += "                              FROM   " + RetSqlTab("Z08") + " (nolock) "
	_cQuery += "                                     INNER JOIN " + RetSqlTab("Z06") + " (nolock) "
	_cQuery += "                                             ON " + RetSqlCond("Z06")
	_cQuery += "                                                AND Z06_NUMOS = Z08_NUMOS "
	_cQuery += "                                                AND Z06_SEQOS = Z08_SEQOS "
	_cQuery += "                                                AND Z06_ATUEST = 'S' "
	_cQuery += "                              WHERE  " + RetSqlCond("Z08")+ " "
	_cQuery += "                                     AND Z08_STATUS IN ( 'P', 'M' ) "
	_cQuery += "                                     AND Z08_LOCAL = BF_LOCAL "
	_cQuery += "                                     AND Z08_ENDORI = BF_LOCALIZ) "

	// filtros somente para Geracao de OS
	If ( ! _lGeraMapa )
		// rua De->Ate
		_cQuery += "       AND Substring(BF_LOCALIZ, 1, 2) BETWEEN '"+mv_par04+"' AND '"+mv_par05+"' "
		// lado
		If (mv_par06 > 1)
			_cQuery += "   AND Substring(BF_LOCALIZ, 3, 1) = '" + IIf(mv_par06==2, "A", "B") + "' "
		EndIf
		// predio De->Ate
		_cQuery += "       AND Substring(BF_LOCALIZ, 4, 2) BETWEEN '"+mv_par07+"' AND '"+mv_par08+"' "
		// Nivel/Andar De->Ate
		_cQuery += "       AND Substring(BF_LOCALIZ, 6, 2) BETWEEN '"+mv_par09+"' AND '"+mv_par10+"' "
		// Produto De->Até
		_cQuery += "       AND BF_LOCALIZ = SOME (SELECT SBF01.BF_LOCALIZ "
		_cQuery += "          FROM   "+RetSqlName("SBF")+" SBF01  (nolock)  "
		_cQuery += "          WHERE  SBF01.BF_FILIAL = SBF.BF_FILIAL AND SBF01.D_E_L_E_T_ = ''
		_cQuery += "                 AND SBF01.BF_PRODUTO BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "') "
	EndIf

	// somente com saldo
	_cQuery += "       AND BF_QUANT > 0 "
	// somente produtos do cliente informado
	_cQuery += "       AND BF_PRODUTO IN (SELECT B1_COD "
	_cQuery += "                          FROM   "+RetSqlTab("SB1")+" (nolock) "
	_cQuery += "                          WHERE  "+RetSqlCond("SB1")
	_cQuery += "                                 AND B1_GRUPO IN (SELECT A1_SIGLA "
	_cQuery += "                                                  FROM   "+RetSqlTab("SA1")+" (nolock) "
	_cQuery += "                                                  WHERE  "+RetSqlCond("SA1")+ " AND A1_COD = '"+mv_par01+"' AND A1_LOJA = '"+mv_par02+"')) "
	// agrupa dados
	_cQuery += "GROUP  BY BF_LOCAL, "
	_cQuery += "          BF_LOCALIZ, "
	_cQuery += "          Z16_ETQPAL, "
	_cQuery += "          BF_PRODUTO, "
	_cQuery += "          Z16_LOTCTL "

	// Ordena dados
	_cQuery += "ORDER BY Z16_ETQPAL "

	// grava dados no txt para debug
	memowrit("c:\query\twmsa028.txt",_cQuery)

	// carrega resultado do SQL na variavel.
	_aRetSQL := U_SqlToVet(_cQuery)

	// avaliação de resultado da query
	If Len(_aRetSQL) == 0
		Aviso("TWMSA028","Sem Informações para apresentar!",{"Fechar"})
		Return()
	EndIf
	If !(_lGeraMapa)
		// cria o head do browse com as informações
		Aadd(_aHead,{'    ','BF_AMARK','@BMP',10,0,,,'C',,'V',,,'mark','V','S'})
	EndIf

	Aadd(_aHead,{"Armazem","BF_LOCAL","@!",2,0,"","","C","",""})

	Aadd(_aHead,{"Endereco","BF_LOCALIZ","@!",15,0,"","","C","",""})

	Aadd(_aHead,{"Etiq Palete","Z16_ETQPAL","@R 99999-99999",10,0,"","","C","",""})

	Aadd(_aHead,{"Produto","BF_PRODUTO","@!",30,0,"","","C","",""})

	Aadd(_aHead,{"Saldo","Z16_SALDO","@E 999,999.9999",11,4,"","","N","",""})

	Aadd(_aHead,{"Lote","Z16_LOTCTL","@!",30,0,"","","C","",""})
	
	/*
	SX3->(dbSeek("C5_TIPOCLI"))
	Aadd(_aHead,{ AlLTrim( X3Titulo() ),; // 01 - Titulo
	SX3->X3_CAMPO	,;			// 02 - Campo
	SX3->X3_Picture	,;			// 03 - Picture
	SX3->X3_TAMANHO	,;			// 04 - Tamanho
	SX3->X3_DECIMAL	,;			// 05 - Decimal
	SX3->X3_Valid  	,;			// 06 - Valid
	SX3->X3_USADO  	,;			// 07 - Usado
	SX3->X3_TIPO   	,;			// 08 - Tipo
	SX3->X3_F3		,;			// 09 - F3
	SX3->X3_CONTEXT ,;       	// 10 - Contexto
	SX3->X3_CBOX	,; 	  		// 11 - ComboBox
	SX3->X3_RELACAO , } )  		// 12 - Relacao
	*/
	// inclui campo endereco de destino
	If (_lGeraMapa)

		// campo tipo de regra
		Aadd(_aHead,{"Regra","IT_REGRA","@!",1,0,"U_WMSA028B()","","C","","","1=Pulmão;2=Picking;4=Blocado"})
		aAdd(_aAltEnch,"IT_REGRA")

		// endereco de destino
		SX3->(dbSeek("BF_LOCALIZ"))
		Aadd(_aHead,{"End.Destino","IT_ENDDES","@!",15,0,"U_WMSA028A(M->IT_ENDDES)","","C","SBE",""})
		aAdd(_aAltEnch,"IT_ENDDES")

	EndIf

	//Verifica posição dos campos na Grid
	_nPosMARK   := GDFIELDPOS("BF_AMARK"  , _aHead )
	_nPosLOCA   := GDFIELDPOS("BF_LOCAL"  , _aHead )
	_nPosCALI   := GDFIELDPOS("BF_LOCALIZ", _aHead )
	_nPosETQP   := GDFIELDPOS("Z16_ETQPAL", _aHead )
	_nPosPROD   := GDFIELDPOS("BF_PRODUTO", _aHead )
	_nPosSALD   := GDFIELDPOS("Z16_SALDO" , _aHead )
	_nPosRegra  := GDFIELDPOS("IT_REGRA"  , _aHead )
	_nPosEndDes := GDFIELDPOS("IT_ENDDES" , _aHead )
	_nPosLote   := GDFIELDPOS("Z16_LOTCTL", _aHead )

	// resultado da query com os registros de acordo com os parâmetros
	For _nx := 1 To Len(_aRetSQL)
		// incremento da linha de controle
		_nLin++
		// cria nova linha no vetor
		Aadd(_aCols,Array(Len(_aHead)+1))

		If _nPosMARK > 0
			_aCols[_nLin][_nPosMARK]         := 'LBNO'
		EndIF
		_aCols[_nLin][_nPosLOCA]         := _aRetSQL[_nx][1]
		_aCols[_nLin][_nPosCALI]         := _aRetSQL[_nx][2]
		_aCols[_nLin][_nPosETQP]         := _aRetSQL[_nx][3]
		_aCols[_nLin][_nPosPROD]         := _aRetSQL[_nx][4]
		_aCols[_nLin][_nPosSALD]         := _aRetSQL[_nx][5]

		If _nPosRegra > 0
			_aCols[_nLin][_nPosRegra]  := " "
		EndIf

		If _nPosEndDes > 0
			_aCols[_nLin][_nPosEndDes] := CriaVar("BF_LOCALIZ", .f.)
		EndIf

		_aCols[_nLin][_nPosLote]         := _aRetSQL[_nx][6]

		_aCols[_nLin][Len(_aHead)+1]     := .F.

	Next _nx

	// monta a tela
	_oDlgPrinc := MSDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"Geração de OS Retrabalho",,,.F.,,,,,,.T.,,,.T. )
	_oDlgPrinc:lMaximized := .T.

	//Cria Paineis para separação melhor dos Objetos
	_oPnlTop := TPanel():New(000,000,nil,_oDlgPrinc,,.F.,.F.,,,026,026,.T.,.F. )
	_oPnlTop:Align := CONTROL_ALIGN_TOP
	_oPnlAll := TPanel():New(_aSizeWnd[7],000,nil,_oDlgPrinc,,.F.,.F.,,,000,000,.T.,.F. )
	_oPnlAll:Align := CONTROL_ALIGN_ALLCLIENT

	// -- botao confirmar
	_oBtnConfInt := TButton():New(005,005,"Confirmar"   ,_oPnlTop,{|| Processa({ || sfGerTrans(),'Gerando OS / Transferências...'}) } ,030,015,,,,.T.,,"",,,,.F. )

	If ( _lGeraMapa )
		_oBtnConfReg := TButton():New(005,040,"Executar Regra",_oPnlTop,{|| Processa({ || sfAplicReg(),'Aplicando Regras...'}) } ,040,015,,,,.T.,,"",,,,.F. )
	EndIf

	// campo para informar o endereco de destino
	If ( ! _lGeraMapa ) .And. (mv_par15 == 1)
		_oSayEndDes := TSay():New(008,100,{||"End.Destino"},_oPnlTop,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGetEndDes := TGet():New(005,150,{|u| If(PCount()>0,_cEndDest:=u,_cEndDest)},_oPnlTop,100,012,PesqPict("SBE","BE_LOCALIZ"),{|| IIF(Empty(_cEndDest),.T.,ExistCpo("SBE" , mv_par03 + _cEndDest)) },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SBE","_cEndDest",,)
	ElseIf ( _lGeraMapa )
		_oSayNrOs := TSay():New(008,100,{||"Ord. Serviço: "+_cNumOrdSrv },_oPnlTop,,_oFnt01,.F.,.F.,.F.,.T.)
	EndIf

	// -- botao fechar
	_oBtnFechar := TButton():New(005,((_aSizeWnd[5]/2)-35),"Fechar",_oPnlTop,{|| IIF(MsgYesNo("Desejar Sair?"), _oDlgPrinc:End(), Nil) },030,015,,,,.T.,,"",,,,.F. )

	// browse com os detalhes dos endereços a abastercer
	_oBrwNewG := MsNewGetDados():New(000,000,999,999,_nOpcX,'AllwaysTrue()','AllwaysTrue()','',_aAltEnch,,,'AllwaysTrue()','','AllwaysTrue()',_oPnlAll,_aHead,_aCols)
	_oBrwNewG:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwNewG:oBrowse:bLDblClick := {||sfInvMark()}

	// ativacao da tela
	_oDlgPrinc:Activate(,,,.T.,)
Return

// ** Função para a marcação do Browser no Duplo Clickfe
Static Function sfInvMark()
	// variavel de controle de for
	Local _nX := 0

	//Se for um duplo Click no checkBox realiza a ação de Marcação.
	If (_oBrwNewG:oBrowse:ColPos() = 1) .And. !(_lGeraMapa)
		// define status inicial da marcação
		_oBrwNewG:aCOLS[_oBrwNewG:nAt,_nPosMARK] := IIf(_oBrwNewG:aCOLS[_oBrwNewG:nAt,_nPosMARK]=='LBOK', 'LBNO', 'LBOK')

		// varro todo o browse pra setar os a nova posição dos endereços (sejam marcados ou nãõ)
		For _nX := 1 To Len(_oBrwNewG:aCOLS)
			// se igualo os registros de acordo com o definido
			If (_oBrwNewG:aCOLS[_oBrwNewG:nAt,_nPosETQP] == _oBrwNewG:aCOLS[_nX,_nPosETQP])
				_oBrwNewG:aCOLS[_nX,_nPosMARK] := _oBrwNewG:aCOLS[_oBrwNewG:nAt,_nPosMARK]
			EndIf
			// próximo registro
		Next _nX
	Else
		_oBrwNewG:EditCell()
	EndIf
	// refresh no browse
	_oBrwNewG:Refresh()

Return()

// ** Função para gerar a OS de retrabalho.
Static Function sfGerTrans()
	// variavel temporaria
	Local _nX := 0
	local _cTmpIdPlt := ""
	// tamanho do campo
	local _nTamCmp := TamSx3("Z08_SEQUEN")[1]
	// sequencial da OS
	local _nSeqOS    := 0
	Local _cSeqOSTra := ""
	
	Local _lRet := .T.

	//Gerar OS
	If !(_lGeraMapa)

		// valida endereco de destino
		If (Empty(_cEndDest))
			Aviso("TWMSA028 -> sfGerTrans","É obrigatório informar o endereço de destino!",{"Fechar"})
			Return()
		EndIf

		// verifica se o endereco de destino é uma DOCA
		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ
		SBE->(dbSeek( xFilial("SBE") + mv_par03 + _cEndDest ))

		// validação do tipo de estrutura (nova estrutura 000011-RETRABALHO) e do cadastro de cliente X endereço
		If (SBE->BE_ESTFIS != "000011") .Or. (SBE->BE_ZCODCLI != mv_par01)
			Help( ,, 'Help (TWMSA028001)',, "Endereço " + AllTrim(_cEndDest) + " não está liberado para uso deste cliente.", 1, 0 )
			Return()
		EndIf

		// valida se o endereço está bloqueado
		If ( SBE->BE_STATUS == "3" )
			Help( ,, 'Help (TWMSA028002)',, "Endereço " + AllTrim(_cEndDest) + " está com o status bloqueado!", 1, 0 )
			Return()
		EndIf

		// reinicia variavel
		//  1-cod produto
		//  2-local/armazem
		//  3-end retirada
		//  4-quant
		//  5-end destino
		//  6-ID palete
		//  7-fraciona palete
		//  8-serie nota orig
		//  9-nota orig
		// 10-item nota orig
		// 11-sequencial
		// 12-numseq
		// 13-id volume
		// 14-Lote
		// 15-Tipo de Estoque
		// 16-Quantidade Seg Unid
		_aMapaApanhe := {}

		// varre todos os itens do browse
		For _nX := 1 To Len(_oBrwNewG:aCOLS)

			// verifica se o item esta selecionado
			If (_oBrwNewG:aCOLS[_nX,_nPosMARK] == 'LBOK')

				// controle sequencial dentro da OS
				If (_cTmpIdPlt != _oBrwNewG:aCOLS[_nX,_nPosETQP])
					// atualiza controle
					_cTmpIdPlt := _oBrwNewG:aCOLS[_nX,_nPosETQP]
					// controle do sequencial
					_nSeqOS ++
				EndIf

				// inclui o item selecionado no mapa de apanhe
				aAdd(_aMapaApanhe,{;
				_oBrwNewG:aCOLS[_nX,_nPosPROD] ,; // 1-cod prod
				_oBrwNewG:aCOLS[_nX,_nPosLOCA] ,; // 2-armazem
				_oBrwNewG:aCOLS[_nX,_nPosCALI] ,; // 3-endereco origem
				_oBrwNewG:aCOLS[_nX,_nPosSALD] ,; // 4-saldo/quantidade
				_cEndDest                      ,; // 5-endereco destino
				_oBrwNewG:aCOLS[_nX,_nPosETQP] ,; // 6-id palete
				"N"                            ,; // 7-fraciona palete
				""                             ,; // 8-serie nota
				""                             ,; // 9-nota fiscal
				""                             ,; //10-item nota fiscal
				StrZero(_nSeqOS,_nTamCmp)      ,; //11-sequencial dentro da OS
				""                             ,; //12-numseq
				""                             ,; //13-id volume
				_oBrwNewG:aCOLS[_nX,_nPosLote] ,; //14-lote
				""                             ,; //15-tipo estoque
				0                              }) //16-Quantidade Seg Unid

			EndIf

		Next _nX

		// valida quantidade de itens
		If (Len(_aMapaApanhe) == 0)
			// mensagem
			Aviso("TWMSA028 -> sfGerTrans","Nenhum Endereço selecionado !",{"Fechar"})
			// retorno
			Return()
		Endif

		// chama a rotina padrao para geracao de OS
		_lOk := U_WMSA009B(Nil, "03", Nil, "ZZZ", _aMapaApanhe, .t., "T05", mv_par01, mv_par02, .F.) // gera OS sem mostrar a OS gerada ao final do processamento

		If (_lOk)
			MsgInfo("Processamento Ok. Ordem de Serviço gerada: "+Z05->Z05_NUMOS+".")
		EndIf
		//Gerar Mapa
	Else

		BEGIN TRANSACTION //Inicia Transacao

			// valida se a OS está disponivel Buscando a Tarefa 009 finalizada.
			_cSeqOSTra := sfVldMapa(_cNumOrdSrv,"009",.F.)

			// posiciona no item da Ordem de Servico
			dbSelectArea("Z06")
			Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
			Z06->(dbSeek( xFilial("Z06") + _cNumOrdSrv + _cSeqOSTra ))

			// varre todos os itens do browse e valida de Tem linhas com edereço de destino em Branco.
			// Se estiver OK Realiza a gravação na Tabela
			For _nX := 1 To Len(_oBrwNewG:aCOLS)

				If Empty(_oBrwNewG:aCOLS[_nX,_nPosEndDes])
					//Rollback na transacao
					DisarmTransaction()
					_lRet := .F.
					Help( ,, 'TWMSA028-002 sfGerTrans',, "Endereço de Destino em Branco !", 1, 0 )
					Break
				EndIf

				RecLock("Z08",.T.)
				Z08->Z08_FILIAL := xFilial("Z08")
				Z08->Z08_NUMOS  := Z06->Z06_NUMOS
				Z08->Z08_SEQOS  := Z06->Z06_SEQOS
				Z08->Z08_LOCAL  := _oBrwNewG:aCOLS[_nX,_nPosLOCA]
				Z08->Z08_SERVIC := Z06->Z06_SERVIC
				Z08->Z08_TAREFA := Z06->Z06_TAREFA
				Z08->Z08_ENDSRV := _oBrwNewG:aCOLS[_nX,_nPosCALI]
				Z08->Z08_DTEMIS := Date()
				Z08->Z08_HREMIS := Time()
				Z08->Z08_STATUS := "P" // P-Planejado / R-Realizado / M-Movimento / E-Erro
				Z08->Z08_PRIOR  := "99"
				Z08->Z08_PRODUT := _oBrwNewG:aCOLS[_nX,_nPosPROD]
				Z08->Z08_QUANT  := _oBrwNewG:aCOLS[_nX,_nPosSALD]
				Z08->Z08_ENDORI := _oBrwNewG:aCOLS[_nX,_nPosCALI]
				Z08->Z08_ENDTRA := SubStr(_oBrwNewG:aCOLS[_nX,_nPosEndDes],1,2)
				Z08->Z08_ENDDES := _oBrwNewG:aCOLS[_nX,_nPosEndDes]
				Z08->Z08_PALLET := _oBrwNewG:aCOLS[_nX,_nPosETQP]
				Z08->Z08_FRAPLT := "N"
				Z08->Z08_SEQUEN := Alltrim(StrZero(_nX,_nTamCmp))
				Z08->Z08_TPOPER := "I"
				Z08->Z08_LOCDES := _oBrwNewG:aCOLS[_nX,_nPosLOCA]
				Z08->(MsUnLock())

			Next _nX

		END TRANSACTION //Final Transacao
		
		If (_lRet)
			Help( ,, 'TWMSA028-002',, "Processamento Ok. Mapa Gerado !", 1, 0 )
		EndIf
	EndIf
	// fecha a janela
	_oDlgPrinc:END()

Return()

// ** funcao que valida se a OS está disponivel
Static Function sfVldMapa(mvNrOrdSrv, mvTarefa, mvFinal)
	// variavel de retorno
	local _cRet := ""
	// seek
	local _cSeekZ06

	// valores padroes
	Default mvNrOrdSrv := ""
	Default mvTarefa   := ""
	Default mvFinal    := .T.

	// posiciona no item da Ordem de Servico
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	Z06->(dbSeek( _cSeekZ06 := xFilial("Z06") + mvNrOrdSrv ))

	// varre todos os itens
	While Z06->( ! Eof() ) .And. ((Z06->Z06_FILIAL+Z06->Z06_NUMOS) == _cSeekZ06)
		If mvFinal
			// compara as validacoes necessarias
			If (Z06->Z06_SERVIC == "T05") .And. (Z06->Z06_TAREFA == mvTarefa) .And. (Z06->Z06_STATUS == "FI")
				// armazena sequencia da OS
				_cRet := Z06->Z06_SEQOS
				// sai do Loop
				Exit
			EndIf
		Else
			// compara as validacoes necessarias
			If (Z06->Z06_SERVIC == "T05") .And. (Z06->Z06_TAREFA == mvTarefa)
				// armazena sequencia da OS
				_cRet := Z06->Z06_SEQOS
				// sai do Loop
				Exit
			EndIf
		EndIf
		// proximo item
		Z06->(dbSkip())
	EndDo

Return(_cRet)

// ** Função para validar Regra escolhida pelo usuario.
User Function WMSA028B()
	// variavel de retorno
	local _lRet := .T.
	//Variavel Temporaria
	Local _nX := 0
	Local _cPalet := _oBrwNewG:aCOLS[_oBrwNewG:nAt,_nPosETQP]

	//PICKING
	If M->IT_REGRA == "2"
		// Verifica se o endereço ja foi escolhido na Tela.
		For _nX := 1 To Len(_oBrwNewG:aCOLS)
			If _nX <> _oBrwNewG:nAt

				If _oBrwNewG:aCOLS[_nX,_nPosETQP] = _cPalet
					Aviso("TWMSA028 -> WMSA028B","Para aplicar regra de PICKING produto tem que ser unico no Palete !",{"Fechar"})
					_lRet := .F.
					Return(_lRet)
				EndIf

			EndIf
		Next _nX
	EndIf

	// Deixar todas as Regras iguais para o mesmo Palet
	For _nX := 1 To Len(_oBrwNewG:aCOLS)
		// se igualo os registros de acordo com o definido
		If (_oBrwNewG:aCOLS[_oBrwNewG:nAt,_nPosETQP] == _oBrwNewG:aCOLS[_nX,_nPosETQP])
			_oBrwNewG:aCOLS[_nX,_nPosRegra] := M->IT_REGRA
		EndIf
		// próximo registro
	Next _nX

	// refresh no browse
	_oBrwNewG:Refresh()

Return(_lRet)

// ** Função para Aplicar as regras de endereço.
Static Function sfAplicReg()

	//Variavel Temporaria
	Local _nZ,_nY    := 0
	Local _aRetEnder := {}

	//
	For _nZ := 1 To Len(_oBrwNewG:aCOLS)

		If !(Empty(_oBrwNewG:aCOLS[_nZ,_nPosRegra])) .And. Empty(_oBrwNewG:aCOLS[_nZ,_nPosEndDes])

			//Busca todos os endereços disponiveis
			_aRetEnder := sfPegEnder(_oBrwNewG:aCOLS[_nZ,_nPosRegra], _oBrwNewG:aCOLS[_nZ,_nPosCALI], _oBrwNewG:aCOLS[_nZ,_nPosPROD], _oBrwNewG:aCOLS[_nZ,_nPosETQP], _oBrwNewG:aCOLS[_nZ,_nPosLOCA])

			// varre todos os enderecos
			For _nY := 1 To Len(_aRetEnder)
				// executa validacao do endereco
				If U_WMSA028A(_aRetEnder[_nY], .F., _nZ)
					Exit
				EndIf
			Next _nY

		EndIf

	Next _nZ

	// refresh no browse
	_oBrwNewG:Refresh()

Return()

// ** funcao que escolhe endereco para geracao do mapa de devolucao de retrabalho conforme regra
Static Function sfPegEnder(mvRegra, mvEndOri, mvProduto, mvPalet, mvLocal)

	Local _cQuery     := ""
	Local _aretSQL    := {}

	Default mvRegra   := ""
	Default mvEndOri  := ""
	Default mvProduto := ""
	Default mvPalet   := ""
	Default mvLocal   := ""

	// monta query para buscar enderecos disponiveis
	_cQuery := " SELECT BE_LOCALIZ "
	// cad. enderecos
	_cQuery += " FROM "+RetSqlTab("SBE")+" (nolock) "
	// cad. estrutura fisica
	_cQuery += " INNER JOIN "+RetSqlTab("DC8")+" (nolock) ON "+RetSqlCond("DC8")+" AND BE_ESTFIS = DC8_CODEST "
	_cQuery += " AND DC8_TPESTR = '" + mvRegra + "' "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond('SBE')
	// diferente do endereco de origem
	_cQuery += " AND BE_LOCALIZ <> '" + mvEndOri + "'"
	// no mesmo armazem
	_cQuery += " AND BE_LOCAL    = '" + mvLocal  + "'"
	// para o cliente da OS
	_cQuery += " AND BE_ZCODCLI = '" + Z05->Z05_CLIENT + "' "
	// status disponivel
	_cQuery += " AND BE_STATUS = '1' "
	//PICKING
	If (mvRegra  == "2")
		_cQuery += " AND BE_CODPRO = '" + mvProduto + "'"
	EndIf
	// descarca enderecos que estao no plano de enderecamento
	_cQuery += " AND BE_LOCALIZ NOT IN ("
	_cQuery += "   SELECT DISTINCT Z08_ENDDES FROM "+RetSqlTab("Z08")+" (nolock) "
	_cQuery += "   WHERE "+RetSqlCond("Z08")+" AND Z08_STATUS IN ('P','M') AND Z08_LOCAL = '"+mvLocal+"' "
	_cQuery += " ) "

	// descarca enderecos que estao no plano de expedicao
	_cQuery += "AND BE_LOCALIZ NOT IN ("
	_cQuery += "  SELECT DISTINCT Z08_ENDORI FROM "+RetSqlTab("Z08")+" (nolock) "
	_cQuery += "  WHERE "+RetSqlCond("Z08")+" AND Z08_STATUS IN ('P','M') AND Z08_LOCAL = '"+mvLocal+"' "
	_cQuery += ") "

	memowrit("c:\query\twmsa028_sfPegEnder.txt", _cQuery)

	// carrega resultado do SQL na variavel.
	_aretSQL := U_SqlToVet(_cQuery)

Return(_aretSQL)

// ** Função para validar endereço destino digitado pelo usuario.
User Function WMSA028A(mvEndereco, mvMensagem, mvLinha)
	// variavel de retorno
	local _lRet := .T.
	// saldo do endereco
	local _nSaldoSBF := 0
	// saldo na Z16
	local _nSaldoZ16 := 0
	//Variavel Temporaria
	Local _nX := 0
	//Variavel de retorno OS Pendente
	Local lVerOs := .F.

	Default mvEndereco := ""
	Default mvMensagem := .T.
	Default mvLinha    := _oBrwNewG:nAt

	If !(Empty(mvEndereco))

		dbSelectArea("SBE")
		SBE->(dbSetOrder(1)) // 1-BE_FILIAL + BE_LOCAL + BE_LOCALIZ
		If (SBE->(dbSeek( xFilial("SBE") + _oBrwNewG:aCOLS[mvLinha,_nPosLOCA] +  mvEndereco )))

			If (_oBrwNewG:aCOLS[mvLinha,_nPosCALI] == mvEndereco)
				If mvMensagem
					Aviso("TWMSA028 -> WMSA028A","Endereço destino não pode ser igual ao endereço Origem !",{"Fechar"})
				EndIf
				_lRet := .F.
				Return(_lRet)
			EndIf

			dbSelectArea("DC8")
			DC8->(dbSetOrder(1)) // 1-DC8_FILIAL+DC8_CODEST
			If (DC8->(dbSeek( xFilial("DC8") + SBE->BE_ESTFIS )))
				If (DC8->DC8_TPESTR $ "3/5")
					If mvMensagem
						Aviso("TWMSA028 -> WMSA028A","Endereço destino não pode ser CROSS DOCKING ou DOCA !",{"Fechar"})
					EndIf
					_lRet := .F.
					Return(_lRet)
				EndIf
			EndIf

			// Verifica se o endereço ja foi escolhido na Tela.
			For _nX := 1 To Len(_oBrwNewG:aCOLS)
				If ((_oBrwNewG:aCOLS[mvLinha,_nPosETQP] <> _oBrwNewG:aCOLS[_nX,_nPosETQP]) .And. _oBrwNewG:aCOLS[_nX,_nPosEndDes] == mvEndereco ) .AND. !(DC8->DC8_TPESTR $ "4")
					If mvMensagem
						Aviso("TWMSA028 -> WMSA028A","Endereço Já escolhido !",{"Fechar"})
					EndIf
					_lRet := .F.
					Return(_lRet)
				EndIf
			Next _nX

			//Verifica se o endereço esta Bloqueado.
			If (SBE->BE_STATUS == "3")
				If mvMensagem
					Aviso("TWMSA028 -> WMSA028A","Endereço escolhido esta Bloqueado !",{"Fechar"})
				EndIf
				_lRet := .F.
				Return(_lRet)
			EndIf

			// verifica o saldo do endereco de destino na Tabala SBF
			_nSaldoSBF := QuantSBF(_oBrwNewG:aCOLS[mvLinha,_nPosLOCA] , mvEndereco)

			If (_nSaldoSBF > 0) .AND. !(DC8->DC8_TPESTR $ "4")
				If mvMensagem
					Aviso("TWMSA028 -> WMSA028A","O endereço já possui saldo fiscal vinculado ou está reservado!",{"Fechar"})
				EndIf
				_lRet := .F.
				Return(_lRet)
			EndIf

			// verifica o saldo do endereco de destino na Tabala Z16
			_nSaldoZ16 := sfSaldoZ16(mvEndereco,_oBrwNewG:aCOLS[mvLinha,_nPosLOCA])

			If (_nSaldoZ16 > 0) .AND. !(DC8->DC8_TPESTR $ "4")
				If mvMensagem
					Aviso("TWMSA028 -> WMSA028A","O endereço já possui saldo em etiquetas WMS vinculadas ou está reservado!",{"Fechar"})
				EndIf
				_lRet := .F.
				Return(_lRet)
			EndIf

			//Verifica se tem OS em aberto com este endereço.
			lVerOs := sfVerPenOS(mvEndereco,_oBrwNewG:aCOLS[mvLinha,_nPosLOCA])

			If (lVerOs)
				If mvMensagem
					Aviso("TWMSA028 -> WMSA028A","Existem OS em aberto para este endereço!",{"Fechar"})
				EndIf
				_lRet := .F.
				Return(_lRet)
			EndIf

			// valida se o endereco pertence ao cliente
			If (SBE->BE_ZCODCLI != Z05->Z05_CLIENT)
				If mvMensagem
					Aviso("TWMSA028 -> WMSA028A","Endereço escolhido não é indicado para uso deste cliente !",{"Fechar"})
				EndIf
				_lRet := .F.
				Return(_lRet)
			EndIf

		Else
			//Endereço digitado invalido.
			If mvMensagem
				Aviso("TWMSA028 -> WMSA028A","Endereço Invalido !",{"Fechar"})
			EndIF
			_lRet := .F.
			Return(_lRet)

		EndIf

		If _lRet
			// Deixar todos os endereços iguais para o mesmo Palet
			For _nX := 1 To Len(_oBrwNewG:aCOLS)
				// se igualo os registros de acordo com o definido
				If (_oBrwNewG:aCOLS[mvLinha,_nPosETQP] == _oBrwNewG:aCOLS[_nX,_nPosETQP])
					_oBrwNewG:aCOLS[_nX,_nPosEndDes] := mvEndereco
				EndIf
				// próximo registro
			Next _nX
		EndIF
		// refresh no browse
		_oBrwNewG:Refresh()
	EndIF
Return(_lRet)

// ** Função para buscar o saldo do endereço na Tabela Z16.
Static Function sfSaldoZ16(mvEndereco,mvLocal)
	// variavel de retorno
	Local _nRet := 0
	// query
	Local _cQuery:= ""
	Default mvEndereco := ""
	Default mvLocal := ""

	_cQuery := " SELECT SUM(Z16_SALDO)  SALDO"
	_cQuery += " FROM "+RetSqlName("Z16")+" Z16 (nolock) "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond('Z16')+" "
	// filtros
	_cQuery += " AND Z16.Z16_ENDATU = '" + mvEndereco + "'"
	_cQuery += " AND Z16.Z16_LOCAL = '" + mvLocal + "'"
	_cQuery += " AND Z16.Z16_SALDO > 0 "

	// Retorno com o saldo do endereço.
	_nRet := U_FtQuery(_cQuery)

Return(_nRet)

// ** Função para verificar se tem OS em aberto para o endereço no parametro.
Static Function sfVerPenOS(mvEndereco,mvLocal)
	// variavel de retorno
	Local _lRet := .F.
	// query
	Local _cQuery:= ""
	Default mvEndereco := ""
	Default mvLocal    := ""

	_cQuery := " SELECT COUNT(*) QTD "
	_cQuery += " FROM "+RetSqlName("Z08")+" Z08 (nolock) "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond('Z08')+" "
	// filtros
	_cQuery += " AND (Z08_ENDDES = '" + mvEndereco + "' OR Z08_ENDORI = '" + mvEndereco + "')"
	_cQuery += " AND Z08_LOCAL = '" + mvLocal + "'"
	_cQuery += " AND Z08_STATUS IN ('P','M')"

	// Retorno com o saldo do endereço.
	_lRet := U_FtQuery(_cQuery)	> 0

Return(_lRet)

// ** Função para pegar apenas os Palets referentes a OS passada no parametro.
Static Function sfPltOrdSrv(mvNumOS, mvSeq)
	// variavel de retorno
	Local _cRet := ""
	// query
	Local _cQuery  := ""
	Local _aRetSQL := {}
	Local _xU      := 0

	// valores padroes
	Default mvNumOS := ""
	Default mvSeq   := ""

	_cQuery := " SELECT Z08_PALLET IDPALETE "
	_cQuery += " FROM   " + RetSqlTab("Z08") + " (nolock) "
	_cQuery += " WHERE  " + RetSqlCond('Z08')
	_cQuery += "        AND Z08_NUMOS = '" + mvNumOS + "' "
	_cQuery += "        AND Z08_SEQOS = '" + mvSeq   + "' "
	_cQuery += " UNION ALL "
	_cQuery += " SELECT DISTINCT Z07_PALLET IDPALETE "
	_cQuery += " FROM   " + RetSqlTab("Z07")
	_cQuery += " WHERE  " + RetSqlCond('Z07')
	_cQuery += "        AND Z07_NUMOS = '" + mvNumOS + "' "

	// grava dados no txt para debug
	memowrit("c:\query\twmsa028_sfPltOrdSrv.txt", _cQuery)

	// Retorno com o saldo do endereço.
	_aRetSQL := U_SqlToVet(_cQuery)

	For _xU := 1 To Len(_aRetSQL)
		_cRet += _aRetSQL[_xU] + IIf(_xU == Len(_aRetSQL), "", ";")
	Next _xU

Return(_cRet)