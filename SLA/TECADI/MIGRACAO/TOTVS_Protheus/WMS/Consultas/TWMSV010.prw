#include 'protheus.ch'
#include 'parmtype.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina de "Endereço Fácil"                              !
!                  !                                                         !
!                  ! Possibilita ao usuário ter uma visão ampla, completa e  !
!                  ! facil de todos os dados do endereço pertinentes a       !
!                  ! utilização do WMS                                       !
+------------------+---------------------------------------------------------+
!Autor             ! Luiz Poleza                 ! Data de Criacao ! 08/2018 !
+------------------+--------------------------------------------------------*/


user function TWMSV010()

	// dimensoes da tela
	local _aSizeDlg := MsAdvSize()

	// objetos da tela inicial
	local _oDlg, _oPnlCab, _oPnlDados, _oBtSair, _oBtRefresh
	local _oGetEnd, _oSayEnd, _oGetLocal, _oSayLocal

	// objetos para exibir dados complementares
	local _oSayStat, _oSayProd, _oSayCli, _oSayMin, _oSayMax, _oSayTpEst
	local _oGetStat, _oGetProd, _oGetCli, _oGetMin, _oGetMax, _oGetTpEst

	// pastas do FOLDER
	local _aFolders := {'Ordens de serviço em aberto que usam este endereço','Saldos fiscais para o endereço'}

	// fontes utilizadas
	local _oFnt01 := TFont():New("Tahoma",,18,,.t.)

	// legenda da grid de endereços
	local _aCorEnd := {}

	// variáveis informações adicionais
	private _cStatus   := ""
	private _cCodCli   := ""
	private _cCodProd  := ""
	private _cQtdMin   := ""
	private _cQtdMax   := ""
	private _cTpEst    := ""
	private _cRua      := ""
	private _cLado     := ""
	private _cPredio   := ""
	private _cNivel    := ""
	private _cSeque    := ""

	// Aba endereços
	private _aHeadEnd := {}
	private _cTrabEnd
	private _aStruEnd := {}
	private _oBrwEnd
	private _cAlEnd   := GetNextAlias()

	// Aba ordens de serviço
	private _aHeadOS := {}
	private _cTrabOS
	private _aStruOS := {}
	private _oBrwOS
	private _cAlOS   := GetNextAlias()
	
	// objetos para exibir composição do porta-pallet
	private _oSayRua, _oSayLado, _oSayPred, _oSayNivel, _oSaySeq, _oGrPP

	// variáveis gerais
	private cCadastro  := "Endereço Fácil"
	private _cEndereco := CriaVar("BE_LOCALIZ", .F.)
	private _cLocal    := CriaVar("BE_LOCAL", .F.)

	// cria os arquivos de trabalho, alias e dados necessários
	sfRefresh( .T. )

	//Monta tela principal.
	_oDlg := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5], cCadastro,,,.F.,,,,,,.T.,,,.T. )
	_oDlg:lMaximized := .T.

	//-- INICIO PAINEL SUPERIOR --

	//Painel superior
	_oPnlCab := TPanel():New(000,000,nil,_oDlg,,.F.,.F.,,,00,26,.T.,.F. )
	_oPnlCab:Align:= CONTROL_ALIGN_TOP

	// local
	_oSayLocal := TSay():New(007,005,{||"Armazém:"},_oPnlCab,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGetLocal := TGet():New(005,050,{|u| If(PCount()>0,_cLocal:=u,_cLocal)},_oPnlCab,030,012,PesqPict("SBE","BE_LOCAL"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cLocal",,)

	// endereço
	_oSayEnd := TSay():New(007,100,{||"Endereço:"},_oPnlCab,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGetEnd := TGet():New(005,150,{|u| If(PCount()>0,_cEndereco:=u,_cEndereco)},_oPnlCab,100,012,PesqPict("SBE","BE_LOCALIZ"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cEndereco",,)

	//Botão Refresh dos dados
	_oBtRefresh := TBtnBmp2():New(005,600,040,040,"RELOAD",,,,{|| sfRefresh( .F. ) },_oPnlCab,"Atualiza dados",,.T. )

	// define o botao Sair
	_oBtSair := TBtnBmp2():New(001,001,040,040,"FINAL",,,,{|| _oDlg:End() },_oPnlCab,"Sair",,.T. )
	_oBtSair:Align := CONTROL_ALIGN_RIGHT

	//-- FIM PAINEL SUPERIOR --


	//-- INICIO PAINEL DO MEIO --

	// Painel no meio da tela com informações adicionais
	_oPnlDados := TPanel():New(000,000,nil,_oDlg,,.F.,.F.,,,00,100,.T.,.F. )
	_oPnlDados:Align:= CONTROL_ALIGN_TOP

	// status do endereço
	_oSayStat := TSay():New(007,005,{||"Status do endereço:"},_oPnlDados,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGetStat := TGet():New(005,160,{|u| If(PCount()>0,_cStatus:=u,_cStatus)},_oPnlDados,250,012,PesqPict("SBE","BE_STATUS"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cStatus",,)

	// código do cliente
	_oSayCli := TSay():New(021,005,{||"Código do cliente:"},_oPnlDados,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGetCli := TGet():New(019,160,{|u| If(PCount()>0,_cCodCli:=u,_cCodCli)},_oPnlDados,250,012,PesqPict("SA1","A1_NOME"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cCodCli",,)

	// tipo de estrutura
	_oSayTpEst := TSay():New(035,005,{||"Tipo de estrutura física:"},_oPnlDados,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGetTpEst := TGet():New(032,160,{|u| If(PCount()>0,_cTpEst:=u,_cTpEst)},_oPnlDados,250,012, "@!",{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cTpEst",,)

	// código do produto
	_oSayProd := TSay():New(049,005,{||"Código do produto para picking:"},_oPnlDados,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGetProd := TGet():New(047,160,{|u| If(PCount()>0,_cCodProd:=u,_cCodProd)},_oPnlDados,250,012,PesqPict("SB1","B1_DESC"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cCodProd",,)

	// saldo em recebimento
	_oSayMin := TSay():New(063,005,{||"Quant. mínima para reabastecer picking:"},_oPnlDados,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGetMin := TGet():New(061,160,{|u| If(PCount()>0,_cQtdMin:=u,_cQtdMin)},_oPnlDados,50,012, "@!",{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cQtdMin",,)

	// saldo reservado
	_oSayMax := TSay():New(077,005,{||"Quant. máxima para reabastecer picking:"},_oPnlDados,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGetMax := TGet():New(075,160,{|u| If(PCount()>0,_cQtdMax:=u,_cQtdMax)},_oPnlDados,50,012, "@!",{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_cQtdMax",,)


	// group panel para exibir composição do endereço caso seja porta pallet
	_oGrPP   := TGroup():New(007,450,093,550,'Composição do porta pallet',_oPnlDados,,,.T.)

	_oSayRua   := TSay():New(020,455,{|| "Rua:    "  + _cRua   } ,_oGrPP,,_oFnt01,.F.,.F.,.F.,.T.)
	_oSayLado  := TSay():New(035,455,{|| "Lado:   " + _cLado   },_oGrPP,,_oFnt01,.F.,.F.,.F.,.T.)
	_oSayPred  := TSay():New(050,455,{|| "Prédio: " + _cPredio },_oGrPP,,_oFnt01,.F.,.F.,.F.,.T.)
	_oSayNivel := TSay():New(065,455,{|| "Nível:  " + _cNivel  },_oGrPP,,_oFnt01,.F.,.F.,.F.,.T.)
	_oSaySeq   := TSay():New(080,455,{|| "Seq.:   "  + _cSeque  },_oGrPP,,_oFnt01,.F.,.F.,.F.,.T.)

	//-- FIM PAINEL DO MEIO --

	// PASTAS 
	_oFolder := TFolder():New(900,500,_aFolders,,_oDlg,,,,.T.,,1200,1200)
	_oFolder:Align:= CONTROL_ALIGN_ALLCLIENT

	// browse com a listagem das OS em aberto que utilizam o endereço
	_oBrwOS := MsSelect():New((_cAlOS),,,_aHeadOS,,,{001,001,400,1000},,,_oFolder:aDialogs[1])
	_oBrwOS:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// browse com a listagem de saldo fiscal do endereço
	_oBrwEnd := MsSelect():New((_cAlEnd),,,_aHeadEnd,,,{001,001,400,1000},,,_oFolder:aDialogs[2],, _aCorEnd)
	_oBrwEnd:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oDlg CENTERED
	
	// exclui tabelas temporárias
	If ValType(_cTrabEnd) == "O"
		_cTrabEnd:Delete()
	EndIf
	
	If ValType(_cTrabOS) == "O"
		_cTrabOS:Delete()
	EndIf

return

// ** funcao que carrega os dados da programacao
Static Function sfRefresh(mvFirst)

	If (!mvFirst) .AND. (Empty(_cLocal) .OR. Empty(_cEndereco))
		Alert("Campo 'Armazem' ou 'Endereço' está em branco.")
		Return
	EndIf

	MsgRun("Atualizando informacoes...", "Aguarde...", {||	CursorWait(),;
	sfAtuDados(mvFirst) ,;
	sfAtuOS(mvFirst)    ,;
	sfAtuEnd(mvFirst)   ,;
	CursorArrow()})


Return

// ** funcao que retorna os saldos do endereço
Static Function sfAtuEnd(mvFirst)
	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStruEnd,{"BF_LOCALIZ" ,"C", TamSx3("BF_LOCALIZ")[1] ,0})							; aAdd(_aHeadEnd,{"BF_LOCALIZ" ,"","Endereço"        ,PesqPict("SBF","BF_LOCALIZ")})
		aAdd(_aStruEnd,{"BF_LOCAL"   ,"C", TamSx3("BF_LOCAL")  [1] ,0})	                     	; aAdd(_aHeadEnd,{"BF_LOCAL"   ,"","Armazém"         ,PesqPict("SBF","BF_LOCAL")})
		aAdd(_aStruEnd,{"BF_PRODUTO" ,"C", TamSx3("BF_PRODUTO")[1] ,0})		                    ; aAdd(_aHeadEnd,{"BF_PRODUTO" ,"","Produto"         ,PesqPict("SBF","BF_PRODUTO")})
		aAdd(_aStruEnd,{"BF_LOTECTL" ,"C", TamSx3("BF_LOTECTL")[1] ,0})							; aAdd(_aHeadEnd,{"BF_LOTECTL" ,"","Lote"            ,PesqPict("SBF","BF_LOTECTL")})
		aAdd(_aStruEnd,{"BF_QUANT"   ,"N", TamSx3("BF_QUANT")  [1] ,TamSx3("BF_QUANT")[2]})		; aAdd(_aHeadEnd,{"BF_QUANT"   ,"","Saldo fiscal"    ,PesqPict("SBF","BF_QUANT")})
		aAdd(_aStruEnd,{"BF_EMPENHO" ,"N", TamSx3("BF_EMPENHO")[1] ,TamSx3("BF_EMPENHO")[2]})	; aAdd(_aHeadEnd,{"BF_EMPENHO" ,"","Saldo empenhado" ,PesqPict("SBF","BF_EMPENHO")})
		aAdd(_aStruEnd,{"Z16_SALDO"  ,"N", TamSx3("Z16_SALDO") [1] ,TamSx3("Z16_SALDO")[2]})	; aAdd(_aHeadEnd,{"Z16_SALDO"  ,"","Saldo em Etiq."  ,PesqPict("Z16","Z16_SALDO")})
		aAdd(_aStruEnd,{"QTD_ETQ"    ,"N", 3                       ,0})						    ; aAdd(_aHeadEnd,{"QTD_ETQ"    ,"","Qtd. Etiq."      ,"@!"})
		aAdd(_aStruEnd,{"CONTROLE"   ,"C", 3                       ,0})                           //; aAdd(_aHeadEnd,{"CONTROLE"  ,"","Controle"    ,"@!"})

		// fecha alias do TRB
		If (Select(_cAlEnd) <> 0)
			dbSelectArea(_cAlEnd)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrabEnd := FWTemporaryTable():New( _cAlEnd )
		_cTrabEnd:SetFields( _aStruEnd )
		_cTrabEnd:Create()
	EndIf

	// limpa o conteudo do TRB
	(_cAlEnd)->(dbSelectArea(_cAlEnd))
	(_cAlEnd)->(__DbZap())

	If (!mvFirst)
		_cQuery := " SELECT BF_LOCALIZ,                                    "
		_cQuery += "        BF_LOCAL,                                      "
		_cQuery += "        BF_PRODUTO,                                    "
		_cQuery += "        BF_LOTECTL,                                    "
		_cQuery += "        BF_QUANT,                                      "
		_cQuery += "        BF_EMPENHO,                                    "
		_cQuery += "        (SELECT SUM(Z16_SALDO)                         "
		_cQuery += "         FROM " + RetSqlTab("Z16") + " (nolock) "
		_cQuery += "         WHERE " + RetSqlCond("Z16")
		_cQuery += "                AND Z16_ENDATU = BF_LOCALIZ            "
		_cQuery += "                AND Z16_SALDO > 0                      "
		_cQuery += "                AND Z16_LOTCTL = BF_LOTECTL) Z16_SALDO,"
		_cQuery += "        (SELECT COUNT(R_E_C_N_O_)                      "
		_cQuery += "         FROM " + RetSqlTab("Z16") + " (nolock) "
		_cQuery += "         WHERE " + RetSqlCond("Z16")
		_cQuery += "                AND Z16_ENDATU = BF_LOCALIZ            "
		_cQuery += "                AND Z16_SALDO > 0                      "
		_cQuery += "                AND Z16_LOTCTL = BF_LOTECTL) QTD_ETQ   "
		_cQuery += " FROM " + RetSqlTab("SBF") + " (nolock) "
		_cQuery += "        INNER JOIN " + RetSqlTab("SBE") + " (nolock) "
		_cQuery += "                ON " + RetSqlCond("SBE")
		_cQuery += "                   AND BE_LOCALIZ = BF_LOCALIZ         "
		_cQuery += "        INNER JOIN " + RetSqlTab("DC8") + " (nolock) "
		_cQuery += "                ON " + RetSqlCond("DC8")
		_cQuery += "                   AND DC8_CODEST = BE_ESTFIS          "
		_cQuery += " WHERE " + RetSqlCond("SBF")
		_cQuery += "        AND BF_LOCALIZ = '" + _cEndereco + "'          "
		_cQuery += "        AND BF_LOCAL   = '" + _cLocal + "'          "

		// adiciona o conteudo da query para o arquivo de trabalho
		SqlToTrb(_cQuery,_aStruEnd,_cAlEnd)

	EndIf

	// abre o arquivo de trabalho
	(_cAlEnd)->(dbSelectArea(_cAlEnd))
	(_cAlEnd)->(dbGoTop())

	// refresh do browse
	If (_oBrwEnd <> nil)
		_oBrwEnd:oBrowse:Refresh()
	EndIf

Return

// ** funcao que retorna as ordens de serviço em aberto para o endereço
Static Function sfAtuOS(mvFirst)
	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStruOS,{"NUMOS"     ,"C", TamSx3("Z05_NUMOS")[1] , 0})					        ; aAdd(_aHeadOS,{"NUMOS"    ,"","Num. Os"       ,PesqPict("Z05","Z05_NUMOS")})
		aAdd(_aStruOS,{"SEQOS"     ,"C", TamSx3("Z06_SEQOS")[1] , 0})		                    ; aAdd(_aHeadOS,{"SEQOS"    ,"","Seq. OS"       ,PesqPict("Z06","Z06_SEQOS")})
		aAdd(_aStruOS,{"DTEMIS"    ,"D", TamSx3("Z06_DTEMIS")[1], 0})							; aAdd(_aHeadOS,{"DTEMIS"   ,"","Emissão"       ,PesqPict("Z06","Z06_DTEMIS")})
		aAdd(_aStruOS,{"DTINIC"    ,"D", TamSx3("Z06_DTINIC")[1], 0})						    ; aAdd(_aHeadOS,{"DTINIC"   ,"","Início"        ,PesqPict("Z06","Z06_DTINIC")})
		aAdd(_aStruOS,{"STATUS"    ,"C", TamSx3("Z06_STATUS")[1], 0})	                        ; aAdd(_aHeadOS,{"STATUS"   ,"","Status"        ,PesqPict("Z06","Z06_STATUS")})
		aAdd(_aStruOS,{"OPERACAO"  ,"C", 12                     , 0})	                        ; aAdd(_aHeadOS,{"OPERACAO" ,"","Operação"      ,"@!"})
		aAdd(_aStruOS,{"ATIVIDADE" ,"C", 15                     , 0})	                        ; aAdd(_aHeadOS,{"ATIVIDADE","","Atividade"     ,"@!"})
		aAdd(_aStruOS,{"ENDERECO"  ,"C", TamSx3("Z07_ENDATU")[1], 0})	                        ; aAdd(_aHeadOS,{"ENDERECO" ,"","Endereço"      ,PesqPict("Z07","Z07_ENDATU")})
		aAdd(_aStruOS,{"ONDSEP"    ,"C", TamSx3("Z05_ONDSEP")[1], 0})	                        ; aAdd(_aHeadOS,{"ONDSEP"   ,"","Onda Separação",PesqPict("Z05","Z05_ONDSEP")})
		aAdd(_aStruOS,{"CONTROLE"  ,"C", 3                      , 0})                           //; aAdd(_aHeadEnd,{"CONTROLE"  ,"",RetTitle("C6_ZCUBAGE"),PesqPict("SC6","C6_ZCUBAGE")})

		// fecha alias do TRB
		If (Select(_cAlOS) <> 0)
			dbSelectArea(_cAlOS)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrabOS := FWTemporaryTable():New( _cAlOS )
		_cTrabOS:SetFields( _aStruOS )
		_cTrabOS:Create()
	EndIf

	// limpa o conteudo do TRB
	(_cAlOS)->(dbSelectArea(_cAlOS))
	(_cAlOS)->(__DbZap())

	If (!mvFirst)
		_cQuery := "SELECT Z08_NUMOS NUMOS,                             "
		_cQuery += "       Z06_SEQOS SEQOS,                             "
		_cQuery += "       Z06_DTEMIS DTEMIS,                           "
		_cQuery += "       Z06_DTINIC DTINIC,                           "
		_cQuery += "       Z06_STATUS STATUS,                           "
		_cQuery += "       CASE                                         "
		_cQuery += "         WHEN Z05_TPOPER = 'S' THEN 'EXPEDIÇÃO'     "
		_cQuery += "         WHEN Z05_TPOPER = 'E' THEN 'RECEBIMENTO'   "
		_cQuery += "         WHEN Z05_TPOPER = 'I' THEN 'INTERNA'       "
		_cQuery += "         ELSE 'DESCONHECIDA'                        "
		_cQuery += "       END      AS OPERACAO,                        "
		_cQuery += "       'APANHE/TRANSF' AS ATIVIDADE,                "
		_cQuery += "       Z08_ENDSRV AS ENDERECO,                      "
		_cQuery += "       Z05_ONDSEP ONDSEP                            "
		_cQuery += " FROM " + RetSqlTab("Z08") + " (nolock) "
		_cQuery += "       INNER JOIN " + RetSqlTab("Z05") + " (nolock) "
		_cQuery += "               ON " + RetSqlCond("Z05")
		_cQuery += "                  AND Z08_NUMOS = Z05_NUMOS"
		_cQuery += "       INNER JOIN " + RetSqlTab("Z06") + " (nolock) "
		_cQuery += "               ON " + RetSqlCond("Z06")
		_cQuery += "                  AND Z06_NUMOS = Z08_NUMOS"
		_cQuery += "                  AND Z06_SEQOS = Z08_SEQOS"
		_cQuery += "                  AND Z06_STATUS NOT IN ( 'FI', 'CA' )   "
		_cQuery += " WHERE " + RetSqlCond("Z08")
		_cQuery += "       AND ( Z08_ENDDES = '" + _cEndereco + "'
		_cQuery += "             OR Z08_ENDORI = '" + _cEndereco + "' )
		_cQuery += "       AND Z08_LOCAL   = '" + _cLocal + "'"
		_cQuery += "       AND Z08_STATUS != 'R' "
		_cQuery += "UNION ALL                                                "
		_cQuery += "SELECT Z21_IDENT NUMOS,                                  "
		_cQuery += "       Z06_SEQOS SEQOS,                                  "
		_cQuery += "       Z06_DTEMIS DTEMIS,                                "
		_cQuery += "       Z06_DTINIC DTINIC,                                "
		_cQuery += "       Z06_STATUS STATUS,                                "
		_cQuery += "       CASE                                              "
		_cQuery += "         WHEN Z05_TPOPER = 'S' THEN 'EXPEDIÇÃO'          "
		_cQuery += "         WHEN Z05_TPOPER = 'E' THEN 'RECEBIMENTO'        "
		_cQuery += "         WHEN Z05_TPOPER = 'I' THEN 'INTERNA'            "
		_cQuery += "         ELSE 'DESCONHECIDA'                             "
		_cQuery += "       END          AS OPERACAO,                         "
		_cQuery += "       'INVENTARIO' AS ATIVIDADE,                        "
		_cQuery += "       Z21_LOCALI AS ENDERECO,                           "
		_cQuery += "       Z05_ONDSEP ONDSEP                                 "
		_cQuery += "FROM " + RetSqlTab("Z21") + " (nolock) "
		_cQuery += "       INNER JOIN " + RetSqlTab("Z05") + " (nolock) "
		_cQuery += "               ON " + RetSqlCond("Z05")
		_cQuery += "                  AND Z21_IDENT = Z05_NUMOS              "
		_cQuery += "       INNER JOIN " + RetSqlTab("Z06") + " (nolock) "
		_cQuery += "               ON " + RetSqlCond("Z06")
		_cQuery += "                  AND Z06_NUMOS = Z21_IDENT              "
		_cQuery += "                  AND Z06_STATUS NOT IN ( 'FI', 'CA' )   "
		_cQuery += "WHERE " + RetSqlCond("Z21")
		_cQuery += "       AND Z21_LOCALI = '" + _cEndereco + "'"
		_cQuery += "       AND Z21_LOCAL  = '" + _cLocal + "'"

		// adiciona o conteudo da query para o arquivo de trabalho
		SqlToTrb(_cQuery,_aStruOS,_cAlOS)
	EndIf

	// abre o arquivo de trabalho
	(_cAlOS)->(dbSelectArea(_cAlOS))
	(_cAlOS)->(dbGoTop())

	// refresh do browse
	If (_oBrwOS <> nil)
		_oBrwOS:oBrowse:Refresh()
	EndIf

Return


// função para preencher as informações adicionais
Static Function sfAtuDados (mvFirst)
	dbSelectArea("SBE")
	SBE->(dbsetorder(1)) // 1-BE_FILIAL, BE_LOCAL, BE_LOCALIZ, BE_ESTFIS, R_E_C_N_O_, D_E_L_E_T_

	If ( SBE->(dbseek( xFilial("SBE") + _cLocal + _cEndereco )) )

		Do case
			case (SBE->BE_STATUS == "1") 
			_cStatus := "Livre/disponível"
			case (SBE->BE_STATUS == "2") 
			_cStatus := "Ocupado"
			case (SBE->BE_STATUS == "3") 
			_cStatus := "Bloqueado"
			otherwise 
			_cStatus := "Status desconhecido"
		EndCase
		_cCodCli  := AllTrim(SBE->BE_ZCODCLI) + " - " + AllTrim(Posicione("SA1",1, xFilial("SA1") + SBE->BE_ZCODCLI ,"A1_NOME"))
		_cCodProd := AllTrim(SBE->BE_CODPRO)  + " - " + AllTrim(Posicione("SB1",1, xFilial("SB1") + SBE->BE_CODPRO ,"B1_DESC"))
		_cQtdMin  := Str(SBE->BE_ZESTMIN)
		_cQtdMax  := Str(SBE->BE_ZESTMAX)
		_cTpEst   := AllTrim(Posicione("DC8",1, xFilial("DC8") + SBE->BE_ESTFIS,"DC8_DESEST"))

		If (SBE->BE_ESTFIS $ "000002/000010")
			_cRua      := SubStr(SBE->BE_LOCALIZ,1,2)
			_cLado     := SubStr(SBE->BE_LOCALIZ,3,1)
			_cPredio   := SubStr(SBE->BE_LOCALIZ,4,2)
			_cNivel    := SubStr(SBE->BE_LOCALIZ,6,2)
			_cSeque    := SubStr(SBE->BE_LOCALIZ,8,5)

		EndIf
	Else // não achou, limpa as variáveis
		_cStatus  := ""
		_cCodCli  := ""
		_cCodProd := ""
		_cQtdMin  := ""
		_cQtdMax  := ""
		_cTpEst   := ""

		_cRua      := ""
		_cLado     := ""
		_cPredio   := ""
		_cNivel    := ""
		_cSeque    := ""
	EndIf

	// atualiza objetos da composição do porta pallet
	if !(mvFirst)
		_oSayRua:Refresh()
		_oSayLado:Refresh()
		_oSayPred:Refresh()
		_oSayNivel:Refresh()
		_oSaySeq:Refresh()
	EndIf

Return
