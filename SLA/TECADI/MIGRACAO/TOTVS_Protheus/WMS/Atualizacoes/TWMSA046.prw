#include 'protheus.ch'
#include 'parmtype.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina de "Saldo Fácil"                                 !
!                  !                                                         !
!                  ! Possibilita ao usuário ter uma visão ampla, completa e  !
!                  ! facil de todo o saldo, ordens de serviço, endereços,    !
!                  ! notas fiscais e demais análises pertinentes de um       !
!                  ! determinado produto utilizado no WMS                    !
+------------------+---------------------------------------------------------+
!Autor             ! Luiz Poleza                 ! Data de Criacao ! 08/2018 !
+------------------+--------------------------------------------------------*/


user function TWMSA046()

	// dimensoes da tela
	local _aSizeDlg := MsAdvSize()

	// objetos da tela inicial
	local _oDlg, _oPnlCab, _oPnlSaldo, _oPnlEnd, _oBtSair, _oSayProd, _oGetProd, _oBtRefresh, _oBtLegEnd, _oBtCorrig

	// objetos das quantidades
	local _oSQtdDisp, _oSQtdPed, _OSQtdRec, _oSQtdRes
	local _oGQtdDisp, _oGQtdPed, _OGQtdRec, _oGQtdRes

	// pastas do FOLDER
	local _aFolders := {'Pedidos de venda não encerrados','Ord. Serviço em aberto','Endereços (saldo lógico)', "Notas fiscais com saldo"}

	// fontes utilizadas
	local _oFnt01 := TFont():New("Tahoma",,18,,.t.)

	// legenda da grid de endereços
	local _aCorEnd := {}

	// variáveis para saldo
	private _nQtdDisp  := 0
	private _nQtdPed   := 0
	private _nQtdReceb := 0
	private _nQtdReser := 0
	private _nQtdTotal := 0

	// Aba endereços
	private _aHeadEnd := {}
	private _cTrabEnd
	private _aStruEnd := {}
	private _oBrwEnd
	private _cAlEnd   := GetNextAlias()

	// Aba pedidos de venda
	private _aHeadPV := {}
	private _cTrabPV
	private _aStruPV := {}
	private _oBrwPV
	private _cAlPV   := GetNextAlias()

	// Aba pedidos de venda
	private _aHeadOS := {}
	private _cTrabOS
	private _aStruOS := {}
	private _oBrwOS
	private _cAlOS   := GetNextAlias()

	// Aba notas fiscais com saldo
	private _aHeadNF := {}
	private _cTrabNF
	private _aStruNF := {}
	private _oBrwNF
	private _cAlNF   := GetNextAlias()

	// variáveis gerais
	private cCadastro := "Saldo Fácil"
	private _cProduto := CriaVar("B1_COD", .F.)

	// cores da legenda para endereços
	aAdd(_aCorEnd, {"Empty((_cAlEnd)->CONTROLE)","BR_VERDE_ESCURO"})    // status OK
	aAdd(_aCorEnd, {"(_cAlEnd)->CONTROLE == 'DOC'","BR_PRETO"})         // estrutura do endereço é docas
	aAdd(_aCorEnd, {"(_cAlEnd)->CONTROLE == 'RUA'","BR_AMARELO"})       // em rua
	aAdd(_aCorEnd, {"(_cAlEnd)->CONTROLE == 'SAL'","BR_VERMELHO"})      // divergência de saldo fiscal X lógico
	aAdd(_aCorEnd, {"(_cAlEnd)->CONTROLE == 'SKU'","BR_CINZA"})         // múltiplos SKU
	aAdd(_aCorEnd, {"(_cAlEnd)->CONTROLE == 'EST'","BR_PINK"})          // tipo de estoque diferente de normal
	aAdd(_aCorEnd, {"(_cAlEnd)->CONTROLE == 'BLQ'","BR_CANCEL"})        // tipo de estoque diferente de normal

	// cria os arquivos de trabalho, alias e dados necessários
	sfRefresh( .T. )

	//Monta tela principal.
	_oDlg := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5], cCadastro,,,.F.,,,,,,.T.,,,.T. )
	_oDlg:lMaximized := .T.

	//-- INICIO PAINEL SUPERIOR --

	//Painel superior com informações da OS
	_oPnlCab := TPanel():New(000,000,nil,_oDlg,,.F.,.F.,,,00,26,.T.,.F. )
	_oPnlCab:Align:= CONTROL_ALIGN_TOP

	// produto
	_oSayProd := TSay():New(007,005,{||"Código do produto:"},_oPnlCab,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGetProd := TGet():New(005,080,{|u| If(PCount()>0,_cProduto:=u,_cProduto)},_oPnlCab,100,012,PesqPict("SB1","B1_COD"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cProduto",,)

	//Botão Refresh dos dados
	_oBtRefresh := TBtnBmp2():New(005,400,040,040,"RELOAD",,,,{|| sfRefresh( .F. ) },_oPnlCab,"Atualiza dados",,.T. )

	// define o botao Sair
	_oBtSair := TBtnBmp2():New(001,001,040,040,"FINAL",,,,{|| _oDlg:End() },_oPnlCab,"Sair",,.T. )
	_oBtSair:Align := CONTROL_ALIGN_RIGHT

	//-- FIM PAINEL SUPERIOR --

	//-- INICIO PAINEL DO MEIO --
	//Painel do meio com saldos
	_oPnlSaldo := TPanel():New(000,000,nil,_oDlg,,.F.,.F.,,,00,100,.T.,.F. )
	_oPnlSaldo:Align:= CONTROL_ALIGN_TOP

	// saldo disponivel
	_oSQtdDisp := TSay():New(007,005,{||"A - Saldo fiscal disponível/livre para solicitação do cliente (B - C - D - E):"},_oPnlSaldo,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGQtdDisp := TGet():New(005,260,{|u| If(PCount()>0,_nQtdDisp:=u,_nQtdDisp)},_oPnlSaldo,70,012,PesqPict("SB2","B2_QATU"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nQtdDisp",,)

	// saldo total
	_oSQtdPed := TSay():New(030,005,{||"B - Saldo total FISCAL:"},_oPnlSaldo,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGQtdPed := TGet():New(028,260,{|u| If(PCount()>0,_nQtdTotal:=u,_nQtdTotal)},_oPnlSaldo,70,012,PesqPict("SB2","B2_QATU"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nQtdTotal",,)

	// saldo em pedido de venda
	_oSQtdPed := TSay():New(045,005,{||"C - Saldo em ped. venda ainda não baixado (em apanhe/montagem):"},_oPnlSaldo,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGQtdPed := TGet():New(042,260,{|u| If(PCount()>0,_nQtdPed:=u,_nQtdPed)},_oPnlSaldo,70,012,PesqPict("SB2","B2_QPEDVEN"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nQtdPed",,)

	// saldo em recebimento
	_OSQtdRec := TSay():New(060,005,{||"D - Saldo em recebimento (nota a classificar ou OS a endereçar):"},_oPnlSaldo,,_oFnt01,.F.,.F.,.F.,.T.)
	_OGQtdRec := TGet():New(058,260,{|u| If(PCount()>0,_nQtdReceb:=u,_nQtdReceb)},_oPnlSaldo,70,012,PesqPict("SB2","B2_QACLASS"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nQtdReceb",,)

	// saldo reservado
	_oSQtdRes := TSay():New(075,005,{||"E - Saldo reservado em pedido venda aguardando emissão NF retorno:"},_oPnlSaldo,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGQtdRes := TGet():New(073,260,{|u| If(PCount()>0,_nQtdReser:=u,_nQtdReser)},_oPnlSaldo,70,012,PesqPict("SB2","B2_RESERVA"),{|| },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","_nQtdReser",,)

	//-- FIM PAINEL DO MEIO --

	// pastas 
	_oFolder := TFolder():New(900,500,_aFolders,,_oDlg,,,,.T.,,500,1200)
	_oFolder:Align:= CONTROL_ALIGN_ALLCLIENT

	// browse com a listagem pedidos de venda
	_oBrwPV := MsSelect():New((_cAlPV),,,_aHeadPV,,,{001,001,400,1000},,,_oFolder:aDialogs[1])
	_oBrwPV:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// browse com a listagem das OS em aberto do produto
	_oBrwOS := MsSelect():New((_cAlOS),,,_aHeadOS,,,{001,001,400,1000},,,_oFolder:aDialogs[2])
	_oBrwOS:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ------ PASTA ENDEREÇOS ------
	// painel de cabeçalho
	_oPnlEnd := TPanel():New(000,000,nil,_oFolder:aDialogs[3],,.F.,.F.,,,00,26,.T.,.F. )
	_oPnlEnd:Align:= CONTROL_ALIGN_TOP

	//Botão legenda do endereço
	_oBtLegEnd := TBtnBmp2():New(005,010,040,040,"COLOR",,,,{|| sfLegEnd() },_oPnlEnd,"Legenda para endereços",,.T. )
	_oBtLegEnd:Align := CONTROL_ALIGN_LEFT  
	//Botão corrige movimento do endereço
	_oBtCorrig := TBtnBmp2():New(005,010,040,040,"sdurepl",,,,{|| sfCorrige( (_cAlEnd)->Z16_ETQPAL, (_cAlEnd)->Z16_ENDATU ) },_oPnlEnd,"Corrige pallet em rua",,.T. )
	_oBtCorrig:Align := CONTROL_ALIGN_LEFT

	// browse com a listagem endereços do produto
	_oBrwEnd := MsSelect():New((_cAlEnd),,,_aHeadEnd,,,{001,001,400,1000},,,_oFolder:aDialogs[3],, _aCorEnd)
	_oBrwEnd:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// browse com a listagem das OS em aberto do produto
	_oBrwNF := MsSelect():New((_cAlNF),,,_aHeadNF,,,{001,001,400,1000},,,_oFolder:aDialogs[4])
	_oBrwNF:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oDlg CENTERED
	
	// antes de sair da rotina, apaga áreas de trabalho criadas
	If ValType(_cTrabEnd) == "O"
		_cTrabEnd:Delete()
	EndIf
	
	If ValType(_cTrabPV) == "O"
		_cTrabPV:Delete()
	EndIf
	
	If ValType(_cTrabOS) == "O"
		_cTrabOS:Delete()
	EndIf
	
	If ValType(_cTrabNF) == "O"
		_cTrabNF:Delete()
	EndIf

return

// ** funcao que carrega os dados da programacao
Static Function sfRefresh(mvFirst)

	MsgRun("Atualizando informacoes...", "Aguarde...", {||	CursorWait(),;
	sfAtuEnd(mvFirst)   ,;
	sfAtuPV(mvFirst)    ,;
	sfAtuOS(mvFirst)    ,;
	sfAtuSaldo(mvFirst) ,;
	sfAtuNF(mvFirst)    ,;
	CursorArrow()})

Return

// ** funcao que retorna os endereços onde consta o produto
Static Function sfAtuEnd(mvFirst)
	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStruEnd,{"Z16_ENDATU","C", TamSx3("Z16_ENDATU")[1],0})							; aAdd(_aHeadEnd,{"Z16_ENDATU","","Endereço"    ,PesqPict("Z16","Z16_ENDATU")})
		aAdd(_aStruEnd,{"Z16_SALDO" ,"N", TamSx3("Z16_SALDO")[1] ,TamSx3("Z16_SALDO")[2]})		; aAdd(_aHeadEnd,{"Z16_SALDO" ,"","Saldo Etiq"  ,PesqPict("Z16","Z16_SALDO")})
		aAdd(_aStruEnd,{"BF_QUANT"  ,"N", TamSx3("BF_QUANT")[1]  ,TamSx3("BF_QUANT")[2]})		; aAdd(_aHeadEnd,{"BF_QUANT"  ,"","Saldo fiscal",PesqPict("SBF","BF_QUANT")})
		aAdd(_aStruEnd,{"Z16_LOCAL" ,"C", TamSx3("Z16_LOCAL")[1] ,0})							; aAdd(_aHeadEnd,{"Z16_LOCAL" ,"","Armazém"     ,PesqPict("Z16","Z16_LOCAL")})
		aAdd(_aStruEnd,{"CONT_ETIQ" ,"N", 3                      ,0})						    ; aAdd(_aHeadEnd,{"CONT_ETIQ" ,"","Qtd. Etiq."  ,PesqPict("Z16","Z16_SALDO")})
		aAdd(_aStruEnd,{"QTD_SKU"   ,"N", 3                      ,0})						    ; aAdd(_aHeadEnd,{"QTD_SKU"   ,"","Qtd. SKU"    ,PesqPict("Z16","Z16_SALDO")})
		aAdd(_aStruEnd,{"Z16_TPESTO","C", TamSx3("Z16_TPESTO")[1],0})						    ; aAdd(_aHeadEnd,{"Z16_TPESTO","","Tipo estoque",PesqPict("Z16","Z16_TPESTO")})
		aAdd(_aStruEnd,{"Z16_LOTCTL","C", TamSx3("Z16_LOTCTL")[1],0})	                        ; aAdd(_aHeadEnd,{"Z16_LOTCTL","","Lote"        ,PesqPict("Z16","Z16_LOTCTL")})
		aAdd(_aStruEnd,{"Z16_ETQCLI","C", TamSx3("Z16_ETQCLI")[1],0})	                        ; aAdd(_aHeadEnd,{"Z16_ETQCLI","","Etq. Cliente",PesqPict("Z16","Z16_ETQCLI")})
		aAdd(_aStruEnd,{"BE_STATUS" ,"C", 10                     ,0})	                        ; aAdd(_aHeadEnd,{"BE_STATUS" ,"","Status End." ,PesqPict("SBE","BE_STATUS")})
		aAdd(_aStruEnd,{"Z16_ETQPAL","C", TamSx3("Z16_ETQPAL")[1],0})	                        //; aAdd(_aHeadEnd,{"Z16_ETQPAL","","Etq. Cliente",PesqPict("Z16","Z16_ETQCLI")})
		aAdd(_aStruEnd,{"CONTROLE"  ,"C", 3                      ,0})                           //; aAdd(_aHeadEnd,{"CONTROLE"  ,"","Controle"    ,"@!"})

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
		_cQuery := " SELECT Z16_ENDATU,                                                       "
		_cQuery += "        Z16_SALDO,                                                        "
		_cQuery += "        Z16_LOCAL,                                                        "
		_cQuery += "        CONT_ETIQ,                                                        "
		_cQuery += "        QTD_SKU,                                                          "
		_cQuery += "        Z16_TPESTO,                                                       "
		_cQuery += "        Z16_LOTCTL,                                                       "
		_cQuery += "        Z16_ETQCLI,                                                       "
		_cQuery += "        Z16_ETQPAL,                                                       "
		_cQuery += "        IsNull(BF_QUANT,0) AS BF_QUANT,                                   "
		_cQuery += "        CASE                                                              "
		_cQuery += "          WHEN ( BE_STATUS = '1' )  THEN 'Desocupado'                     "
		_cQuery += "          WHEN ( BE_STATUS = '2' )  THEN 'Ocupado'                        "
		_cQuery += "          WHEN ( BE_STATUS >= '3' ) THEN 'Bloqueado'                      "
		_cQuery += "          ELSE ''                                                         "
		_cQuery += "        END AS BE_STATUS,                                                 "
		// coluna de controle para legenda
		_cQuery += "        CASE                                                              "
		// se for estrutura do tipo DOCA
		_cQuery += "          WHEN ( BE_ESTFIS = '000001' ) THEN 'DOC'                        "
		// se estiver em RUA
		_cQuery += "          WHEN Len(Z16_ENDATU) < 6 THEN 'RUA'                             "
		// se tiver qualquer divergência entre saldo lógico X fiscal
		_cQuery += "          WHEN ( ROUND(Z16_SALDO,4) != IsNull(ROUND(BF_QUANT,4) ,0) AND Len(Z16_ENDATU) >= 12 ) THEN 'SAL'"
		// mais de 1 SKU no endereço, quando não for BLOCO
		_cQuery += "          WHEN (QTD_SKU > 1 AND BE_ESTFIS != '000007') THEN 'SKU'         "
		// tipo de estoque diferente de normal
		_cQuery += "          WHEN (Z16_TPESTO != '000001') THEN 'EST'                        "
		// endereço bloqueado
		_cQuery += "          WHEN (BE_STATUS = '3') THEN 'BLQ'                               "
		_cQuery += "          ELSE ''                                                         "
		_cQuery += "        END AS CONTROLE                                                   "
		// busca de dados principal
		_cQuery += " FROM   (SELECT Z16_ENDATU,                                               "
		_cQuery += "                Sum(Z16_SALDO)                               AS Z16_SALDO,"
		_cQuery += "                Count(Z16.R_E_C_N_O_)                        AS CONT_ETIQ,"
		_cQuery += "                (SELECT COUNT(DISTINCT Z16_CODPRO)                        "
		_cQuery += "                 FROM Z16010 (NOLOCK)                                     "
		_cQuery += "                 WHERE Z16_ENDATU = Z16.Z16_ENDATU                        "
		_cQuery += "                 AND Z16_SALDO >0                                         " 
		_cQuery += "                 AND D_E_L_E_T_ = '' )                       AS QTD_SKU,  "
		_cQuery += "                Z16_LOCAL,                                                "
		_cQuery += "                Z16_TPESTO,                                               "
		_cQuery += "                Z16_LOTCTL,                                               "
		_cQuery += "                Z16_ETQCLI,                                               "
		_cQuery += "                Z16_ETQPAL,                                               "
		_cQuery += "                (SELECT Sum(BF_QUANT) AS EXPR1                            "
		_cQuery += "                 FROM " + RetSqlTab("SBF") + " (nolock) "
		_cQuery += "                 WHERE " + RetSqlCond("SBF")
		_cQuery += "                        AND ( BF_PRODUTO = Z16.Z16_CODPRO )               "
		_cQuery += "                        AND ( BF_LOCALIZ = Z16.Z16_ENDATU )               "
		_cQuery += "                        AND ( BF_LOTECTL = Z16.Z16_LOTCTL )) AS BF_QUANT, "
		_cQuery += "                BE_ESTFIS,                                                "
		_cQuery += "                BE_STATUS                                                 "
		_cQuery += "         FROM " + RetSqlTab("Z16") + " (nolock) "
		_cQuery += "                INNER JOIN " + RetSqlTab("SBE") + " (NOLOCK) "
		_cQuery += "                        ON " + RetSqlCond("SBE")
		_cQuery += "                           AND BE_LOCALIZ = Z16_ENDATU                    "
		_cQuery += "                           AND BE_LOCAL   = Z16_LOCAL                     "
		_cQuery += "         WHERE " + RetSqlCond("Z16")
		_cQuery += "                AND ( Z16_CODPRO = '" + _cProduto + "' )                  "
		_cQuery += "                AND ( Z16_SALDO > 0 )                                     "
		_cQuery += "         GROUP  BY Z16_ENDATU,                                            "
		_cQuery += "                   Z16_LOCAL,                                             "
		_cQuery += "                   Z16_TPESTO,                                            "
		_cQuery += "                   Z16_LOTCTL,                                            "
		_cQuery += "                   Z16_ETQPAL,                                            "
		_cQuery += "                   Z16_ETQCLI,                                            "
		_cQuery += "                   Z16_CODPRO,                                            "
		_cQuery += "                   BE_STATUS,                                            "
		_cQuery += "                   BE_ESTFIS) AS CONSULTA                                 "
		_cQuery += " ORDER  BY Z16_ENDATU, Z16_LOCAL                                          "

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

// ** funcao que retorna os pedidos de venda não encerrados para o produto
Static Function sfAtuPV(mvFirst)
	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStruPV,{"C5_NUM"    ,"C", TamSx3("C5_NUM")[1]    , 0})							; aAdd(_aHeadPV,{"C5_NUM"    ,"","Pedido"        ,PesqPict("SC5","C5_NUM")})
		aAdd(_aStruPV,{"C5_NOTA"   ,"C", TamSx3("C5_NOTA")[1]   , 0})		                    ; aAdd(_aHeadPV,{"C5_NOTA"   ,"","NF Tecadi"     ,PesqPict("SC5","C5_NOTA")})
		aAdd(_aStruPV,{"C5_EMISSAO","D", TamSx3("C5_EMISSAO")[1], 0})							; aAdd(_aHeadPV,{"C5_EMISSAO","","Emissão"       ,PesqPict("SC5","C5_EMISSAO")})
		aAdd(_aStruPV,{"C5_ZPEDCLI","C", TamSx3("C5_ZPEDCLI")[1], 0})						    ; aAdd(_aHeadPV,{"C5_ZPEDCLI","","Ped. Cliente"  ,PesqPict("SC5","C5_ZPEDCLI")})
		aAdd(_aStruPV,{"C5_ZDOCCLI","C", TamSx3("C5_ZDOCCLI")[1], 0})	                        ; aAdd(_aHeadPV,{"C5_ZDOCCLI","","NF Cliente"    ,PesqPict("SC5","C5_ZDOCCLI")})
		aAdd(_aStruPV,{"C5_ZMNTVOL","C", TamSx3("C5_ZMNTVOL")[1], 0})	                        ; aAdd(_aHeadPV,{"C5_ZMNTVOL","","Montado?"      ,PesqPict("SC5","C5_ZMNTVOL")})
		aAdd(_aStruPV,{"C5_ZCARREG","C", TamSx3("C5_ZCARREG")[1], 0})	                        ; aAdd(_aHeadPV,{"C5_ZCARREG","","Carregado?"    ,PesqPict("SC5","C5_ZCARREG")})
		aAdd(_aStruPV,{"C5_ZONDSEP","C", TamSx3("C5_ZONDSEP")[1], 0})	                        ; aAdd(_aHeadPV,{"C5_ZONDSEP","","Onda Separação",PesqPict("SC5","C5_ZONDSEP")})
		aAdd(_aStruPV,{"C5_ZNOSSEP","C", TamSx3("C5_ZNOSSEP")[1], 0})	                        ; aAdd(_aHeadPV,{"C5_ZNOSSEP","","OS Separação"  ,PesqPict("SC5","C5_ZNOSSEP")})
		aAdd(_aStruPV,{"C6_QTDVEN" ,"N", TamSx3("C6_QTDVEN")[1] , TamSx3("C6_QTDVEN")[2]})	    ; aAdd(_aHeadPV,{"C6_QTDVEN" ,"","Quant."        ,PesqPict("SC6","C6_QTDVEN")})
//		aAdd(_aStruPV,{"CONTROLE"  ,"C", 3                      , 0})                           //; aAdd(_aHeadEnd,{"CONTROLE"  ,"",RetTitle("C6_ZCUBAGE"),PesqPict("SC6","C6_ZCUBAGE")})

		// fecha alias do TRB
		If (Select(_cAlPV) <> 0)
			dbSelectArea(_cAlPV)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrabPV := FWTemporaryTable():New( _cAlPV )
		_cTrabPV:SetFields( _aStruPV )
		_cTrabPV:Create()
	EndIf

	// limpa o conteudo do TRB
	(_cAlPV)->(dbSelectArea(_cAlPV))
	(_cAlPV)->(__DbZap())

	If (!mvFirst)
		_cQuery := "SELECT C5_NUM,     "
		_cQuery += "       C5_NOTA,    "
		_cQuery += "       C5_EMISSAO, "
		_cQuery += "       C5_ZPEDCLI, "
		_cQuery += "       C5_ZDOCCLI, "
		_cQuery += "       C5_ZMNTVOL, "
		_cQuery += "       C5_ZCARREG, "
		_cQuery += "       C5_ZONDSEP, "
		_cQuery += "       C5_ZNOSSEP, "
		_cQuery += "       Sum(C6_QTDVEN) C6_QTDVEN  "
		_cQuery += " FROM " + RetSqlTab("SC5") + " (nolock) "
		_cQuery += "       INNER JOIN " + RetSqlTab("SC6") + " (NOLOCK) "
		_cQuery += "               ON " + RetSqlCond("SC6")
		_cQuery += "                  AND C6_NUM = C5_NUM "
		_cQuery += "                  AND C6_CLI = C5_CLIENTE  "
		_cQuery += "                  AND C6_LOJA = C5_LOJACLI "
		_cQuery += "                  AND C6_FILIAL = C5_FILIAL"
		_cQuery += "                  AND C6_PRODUTO = '" + _cProduto +"'"
		_cQuery += " WHERE " + RetSqlCond("SC5")
		_cQuery += "       AND C5_TIPOOPE = 'P'"
		_cQuery += "       AND C5_NOTA    = '' "
		_cQuery += "       AND C5_ZCARREG = '' "
		_cQuery += "GROUP  BY C5_NUM, "
        _cQuery += "  C5_NOTA,   "
        _cQuery += "  C5_EMISSAO,"
        _cQuery += "  C5_ZPEDCLI,"
        _cQuery += "  C5_ZDOCCLI,"
        _cQuery += "  C5_ZMNTVOL,"
        _cQuery += "  C5_ZCARREG,"
        _cQuery += "  C5_ZONDSEP,"
        _cQuery += "  C5_ZNOSSEP " 

		// adiciona o conteudo da query para o arquivo de trabalho
		SqlToTrb(_cQuery,_aStruPV,_cAlPV)
	EndIf

	// abre o arquivo de trabalho
	(_cAlPV)->(dbSelectArea(_cAlPV))
	(_cAlPV)->(dbGoTop())

	// refresh do browse
	If (_oBrwPV <> nil)
		_oBrwPV:oBrowse:Refresh()
	EndIf

Return


// ** funcao que retorna as ordens de serviço em aberto para o produto
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
		// busca OS de conferência
		_cQuery := "SELECT Z07_NUMOS NUMOS,                              "
		_cQuery += "       Z07_SEQOS SEQOS,                              "
		_cQuery += "       Z06_DTEMIS DTEMIS,                            "
		_cQuery += "       Z06_DTINIC DTINIC,                            "
		_cQuery += "       Z06_STATUS STATUS,                            "
		_cQuery += "       CASE                                          "
		_cQuery += "         WHEN Z05_TPOPER = 'S' THEN 'EXPEDIÇÃO'      "
		_cQuery += "         WHEN Z05_TPOPER = 'E' THEN 'RECEBIMENTO'    "
		_cQuery += "         WHEN Z05_TPOPER = 'I' THEN 'INTERNA'        "
		_cQuery += "         ELSE 'DESCONHECIDA'                         "
		_cQuery += "       END             AS OPERACAO,                  "
		_cQuery += "       'CONF/MONTAGEM' AS ATIVIDADE,                 "
		_cQuery += "       Z07_ENDATU AS ENDERECO,                       "
		_cQuery += "       Z05_ONDSEP ONDSEP                             "
		_cQuery += " FROM " + RetSqlTab("Z07") + " (nolock) "
		_cQuery += "       INNER JOIN " + RetSqlTab("Z05") + " (nolock) "
		_cQuery += "               ON " + RetSqlCond("Z05")
		_cQuery += "                  AND Z07_NUMOS = Z05_NUMOS"
		_cQuery += "       INNER JOIN " + RetSqlTab("Z06") + " (nolock) "
		_cQuery += "               ON " + RetSqlCond("Z06")
		_cQuery += "                  AND Z06_NUMOS = Z07_NUMOS"
		_cQuery += "                  AND Z06_SEQOS = Z07_SEQOS"
		_cQuery += "                  AND Z06_STATUS NOT IN ( 'FI', 'CA' )   "
		_cQuery += " WHERE " + RetSqlCond("Z07")
		_cQuery += "       AND Z07_PRODUT = '" + _cProduto + "'"
		_cQuery += "       AND Z07_STATUS NOT IN ( 'F', 'A' )  "
		// busca OS de apanhe ou transferência
		_cQuery += "UNION ALL                                           "
		_cQuery += "SELECT Z08_NUMOS NUMOS,                             "
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
		_cQuery += "       AND Z08_PRODUT = '" + _cProduto + "'"
		_cQuery += "       AND Z08_STATUS != 'R' "
		// busca OS de inventário
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
		_cQuery += "       AND Z21_PROD = '" + _cProduto + "'"
		// CESV de recebimento
		_cQuery += "UNION ALL                                       "
		_cQuery += "SELECT Z05_NUMOS    NUMOS,                             "
		_cQuery += "       Z06_SEQOS    SEQOS,                             "
		_cQuery += "       Z06_DTEMIS   DTEMIS,                            "
		_cQuery += "       Z06_DTINIC   DTINIC,                            "
		_cQuery += "       Z06_STATUS   STATUS,                            "
		_cQuery += "       CASE                                            "
		_cQuery += "         WHEN Z05_TPOPER = 'S' THEN 'EXPEDIÇÃO'        "
		_cQuery += "         WHEN Z05_TPOPER = 'E' THEN 'RECEBIMENTO'      "
		_cQuery += "         WHEN Z05_TPOPER = 'I' THEN 'INTERNA'          "
		_cQuery += "         ELSE 'DESCONHECIDA'                           "
		_cQuery += "       END          AS OPERACAO,                       "
		_cQuery += "       'CESV RECEB' AS ATIVIDADE,                      "
		_cQuery += "       'NÃO ENDEREÇADO' AS ENDERECO,                   "
		_cQuery += "       Z05_ONDSEP   ONDSEP                             "
		_cQuery += "FROM " + RetSqlTab("Z04") + " (nolock) "
		_cQuery += "       INNER JOIN " + RetSqlTab("Z05") + " (nolock) "
		_cQuery += "               ON " + RetSqlCond("Z05")
		_cQuery += "                  AND Z04_CESV = Z05_CESV              "
		_cQuery += "				  AND Z05_TPOPER = 'E'                 "
		_cQuery += "       INNER JOIN " + RetSqlTab("Z06") + " (nolock) "
		_cQuery += "               ON " + RetSqlCond("Z06")
		_cQuery += "                  AND Z06_NUMOS = Z05_NUMOS            "
		_cQuery += "                  AND Z06_STATUS NOT IN ( 'FI', 'CA' ) "
		_cQuery += "WHERE " + RetSqlCond("Z04")
		_cQuery += "       AND Z04_PROD = '" + _cProduto + "'" 

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


// função para cálculo dos saldos
Static Function sfAtuSaldo (mvFirst)
	dbSelectArea("SB2")
	SB2->(dbsetorder(1)) // 1-B2_FILIAL, B2_COD, B2_LOCAL

	If ( SB2->(dbseek( xFilial("SB2") + _cProduto )) )

		_nQtdDisp  := SB2->B2_QATU - (SB2->B2_QPEDVEN + SB2->B2_RESERVA + SB2->B2_QACLASS)
		_nQtdTotal := SB2->B2_QATU
		_nQtdPed   := SB2->B2_QPEDVEN
		_nQtdReser := SB2->B2_RESERVA
		_nQtdReceb := SB2->B2_QACLASS

	EndIf

Return

// ** funcao que retorna as notas fiscais do cliente que ainda têm saldo
Static Function sfAtuNF(mvFirst)
	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStruNF,{"B6_EMISSAO" ,"D", TamSx3("B6_EMISSAO")[1] , 0})						    ; aAdd(_aHeadNF,{"B6_EMISSAO" ,"","Data emissão"   ,PesqPict("SB6","B6_EMISSAO")})
		aAdd(_aStruNF,{"B6_DOC"     ,"C", TamSx3("B6_DOC")[1]     , 0})		                    ; aAdd(_aHeadNF,{"B6_DOC"     ,"","Nota fiscal"    ,PesqPict("SB6","B6_DOC")})
		aAdd(_aStruNF,{"B6_SERIE"   ,"C", TamSx3("B6_SERIE")[1]   , 0})							; aAdd(_aHeadNF,{"B6_SERIE"   ,"","Série"          ,PesqPict("SB6","B6_SERIE")})
		aAdd(_aStruNF,{"B6_LOCAL"   ,"C", TamSx3("B6_LOCAL")[1]   , 0})						    ; aAdd(_aHeadNF,{"B6_LOCAL"   ,"","Local"          ,PesqPict("SB6","B6_LOCAL")})
		aAdd(_aStruNF,{"B6_QUANT"   ,"N", TamSx3("B6_QUANT")[1]   , TamSx3("B6_QUANT")[2]})	    ; aAdd(_aHeadNF,{"B6_QUANT"   ,"","Qtd. original"  ,PesqPict("SB6","B6_QUANT")})
		aAdd(_aStruNF,{"B6_SALDO"   ,"N", TamSx3("B6_SALDO")[1]   , TamSx3("B6_SALDO")[2]})	    ; aAdd(_aHeadNF,{"B6_SALDO"   ,"","Saldo restante" ,PesqPict("SB6","B6_SALDO")})

		// fecha alias do TRB
		If (Select(_cAlNF) <> 0)
			dbSelectArea(_cAlNF)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrabNF := FWTemporaryTable():New( _cAlNF )
		_cTrabNF:SetFields( _aStruNF )
		_cTrabNF:Create()
	EndIf

	// limpa o conteudo do TRB
	(_cAlNF)->(dbSelectArea(_cAlNF))
	(_cAlNF)->(__DbZap())

	If (!mvFirst)
		_cQuery := "SELECT B6_EMISSAO, B6_DOC, B6_SERIE, B6_LOCAL, B6_QUANT, B6_SALDO "
		_cQuery += " FROM " + RetSqlTab("SB6") + " (nolock) "
		_cQuery += " WHERE " + RetSqlCond("SB6")
		_cQuery += "       AND B6_PRODUTO = '" + _cProduto + "'"
		_cQuery += "       AND B6_SALDO > 0                    "
		_cQuery += "	   AND B6_PODER3 = 'R'                 "
		_cQuery += " ORDER BY 1,2                              "

		// adiciona o conteudo da query para o arquivo de trabalho
		SqlToTrb(_cQuery,_aStruNF,_cAlNF)
	EndIf

	// abre o arquivo de trabalho
	(_cAlNF)->(dbSelectArea(_cAlNF))
	(_cAlNF)->(dbGoTop())

	// refresh do browse
	If (_oBrwNF <> nil)
		_oBrwNF:oBrowse:Refresh()
	EndIf

Return

// ** funcao que apresenta a legenda para a aba de endereços
Static Function sfLegEnd()

	Local _aCores := {}

	// inclui opcoes e cores do status
	aAdd(_aCores,{"BR_VERDE_ESCURO", "Endereço válido e com saldo OK"  })
	aAdd(_aCores,{"BR_AMARELO"     , "Pallet em rua / movimentação abandonada ou perdida" })
	aAdd(_aCores,{"BR_VERMELHO"    , "Divergência entre saldo fiscal e em etiquetas"})
	aAdd(_aCores,{"BR_PINK"        , "Tipo de estoque não-normal"  })
	aAdd(_aCores,{"BR_PRETO"       , "Endereços do tipo doca / stageout"  })
	aAdd(_aCores,{"BR_CINZA"       , "Múltiplos SKU em endereço que não é do tipo bloco ou multi-produto"  })
	aAdd(_aCores,{"BR_CANCEL"      , "Endereço bloqueado"  })

	// funcao padrao para apresentar as legendas
	BrwLegenda(cCadastro,"Legenda para endereços",_aCores)

Return NIL

// ** função para corrigir pallet com movimentação perdida em rua
Static function sfCorrige( mvEtqPal, mvEndAtu   )

	local _cEndere := CriaVar("Z16_ENDATU", .F.)
	local _aArea   := GetArea()

	// só permite tentar corrigir pallet com status "em rua"
	If (_cAlEnd)->CONTROLE != "RUA"
		MsgAlert("Só é permitido corrigir pallet com status 'em rua'.")
		Return()
	EndIf
	
	// valida se é possível corrigir o movimento
	if sfValCor( mvEtqPal, mvEndAtu, @_cEndere )
		If MsgYesNo("Confirma a correção do pallet " + mvEtqPal + " para o endereço " + _cEndere + "?", "Atenção" )
			dbSelectArea("Z16")
			Z16->(dbSetOrder(1))  // Z16_FILIAL, Z16_ETQPAL, R_E_C_N_O_, D_E_L_E_T_
			
			// procura pela etiqueta de pallet
			If ! Z16->(dbSeek( xFilial("Z16") + mvEtqPal ))  
				MsgAlert("Etiqueta de pallet não encontrada para correção.")
			EndIf
			
			// corrige endereço atual
			Reclock("Z16")
			Z16->Z16_ENDATU := _cEndere
			Z16->( MsUnLock() )
			
			// força atualização da tela
			sfRefresh( .F. )
			
		Else
			MsgAlert("Processo de correção cancelado.")
		EndIf
	Else
		MsgAlert("Correção não permitida.")
	EndIf

	RestArea(_aArea)

Return Nil


// função auxiliar para as validações de se é possivel corrigir automaticamente o endereço
Static Function sfValCor ( mvEtqPal, mvEndAtu, mvEnder)

	local _lRet      := .T.
	local _cQuery    := ""
	local _cEnd      := CriaVar("Z16_ENDATU", .F.)
	local _cEndZ08   := CriaVar("Z16_ENDATU", .F.)
	local _cEndZ17   := CriaVar("Z16_ENDATU", .F.)
	local _cEstFis   := CriaVar("BE_ESTFIS" , .F.)
	local _aRet      := {}

	// verifica se pallet está em alguma OS pendente
	If (_lRet)
		_cQry := " SELECT Count(*)                         "
		_cQry += " FROM " + RetSqlTab("Z08") + " (nolock) "
		_cQry += " WHERE " + RetSqlCond("Z08")
		_cQry += "        AND ( Z08_PALLET = '" + mvEtqPal + "'      "
		_cQry += "           OR Z08_NEWPLT = '" + mvEtqPal + "' )"
		_cQry += "        AND Z08_STATUS != 'R'            "


		If (U_FTQuery(_cQry) > 0)
			_lRet := .F.

			Help(,, 'TWMSA046.F01.001',, "Correção de pallet não permitida", 1, 0,;
			NIL, NIL, NIL, NIL, NIL,;
			{"Este pallet está previsto e pendente em uma ou mais ordens de serviço. Consulte a aba 'Ordens de serviço' ou a rotina 'Monitor de serviço'."})
		EndIf
	EndIf

	// valida endereço de origem e destino (últimas movimentações das etiquetas)
	If (_lRet)

		// pega ultimo endereço de origem conforme movimentos na Z08
		_cQry := " SELECT TOP 1 Z08_ENDORI "
		_cQry += " FROM " + RetSqlTab("Z08") + " (nolock) "
		_cQry += " WHERE  " + RetSqlCond("Z08")
		_cQry += "        AND Z08_PALLET = '" + mvEtqPal + "' "
		_cQry += "        AND Z08_LOCAL  = '" + (_cAlEnd)->Z16_LOCAL + "' "
		_cQry += "        AND Z08_STATUS = 'R' "
		_cQry += " ORDER  BY R_E_C_N_O_ DESC   "

		_cEndZ08 := U_FTQuery(_cQry)
		
		// pega último movimento de destino na Z17
		_cQry := " SELECT TOP 1 Z17_ENDDES          "
		_cQry += " FROM   z17010  (nolock)          "
		_cQry += " WHERE  Z17_ETQPLT = '0001053012' "
		_cQry += " ORDER  BY R_E_C_N_O_ DESC        "

		_cEndZ17 := U_FTQuery(_cQry)
		
		// compara os 2 endereços, com a finalidade de saber se o pallet foi pego no endereço origem e também foi devolvido
		// caso não tenha o mesmo registro, significa que ainda não foi realizado o movimento, ou devolvido para lugar divergente, ou já teve outros movimentos

		If ( _cEndZ08 != _cEndZ17  ) .OR. ( Empty(_cEndZ08) .OR. Empty(_cEndZ17) )
			_lRet := .F.

			Help(,, 'TWMSA046.F01.002',, "Correção de pallet não permitida", 1, 0,;
			NIL, NIL, NIL, NIL, NIL,;
			{"Divergência na localização do último movimento do pallet." + CRLF + CRLF + "Mapa : " + _cEndZ08 + CRLF + "Movimento : " + _cEndZ17})
		Else
			// atualiza endereço a ser ajustado
			_cEnd := _cEndZ08
		EndIf

	EndIf

	// valida se o endereço está apto a estornar
	If (_lRet)

		// pega o tipo de estrutura física do endereço
		_cQry := " SELECT BE_ESTFIS                      "
		_cQry += " FROM " + RetSqlTab("SBE") + " (nolock) "
		_cQry += " WHERE " + RetSqlCond("SBE")
		_cQry += "        AND BE_LOCALIZ = '" + _cEnd + "'"

		_cEstFis := U_FTQuery(_cQry)

		// se porta pallet pulmão ou picking
		If ( _cEstFis == "000002" ) .OR. ( _cEstFis == "000010" )
			// verifica se o endereço está vazio

			_cQry := " SELECT Count(*) AS QTD                       "
			_cQry += "       FROM " + RetSqlTab("Z16") + " (nolock) "
			_cQry += "       WHERE " + RetSqlCond("Z16")
			_cQry += "              AND Z16_SALDO > 0               "
			_cQry += "              AND Z16_ENDATU = '" + _cEnd + "'"
			_cQry += "              AND Z16_LOTCTL = '" + (_cAlEnd)->Z16_LOTCTL + "' "

			If (U_FTQuery(_cQry) != 0)
				_lRet := .F.

				Help(,, 'TWMSA046.F01.004',, "Correção de pallet não permitida", 1, 0,;
				NIL, NIL, NIL, NIL, NIL,;
				{ "O endereço " + _cEnd + " localizado como origem não está vazio. Verifique o saldo lógico do endereço"} )
			EndIf

		ElseIf ( _cEstFis == "000007" )   // se blocado
			// valida se bate o saldo fiscal X saldo da etiqueta (somando possíveis outros pallets do mesmo produto)
			_cQry := " SELECT (SELECT SUM(BF_QUANT)                                    "
			_cQry += "         FROM " + RetSqlTab("SBF") + " (nolock) "
			_cQry += "         WHERE " + RetSqlCond("SBF")
			_cQry += "                AND BF_LOCALIZ = '" + _cEnd + "'                 "
			_cQry += "                AND BF_LOTECTL = '" + (_cAlEnd)->Z16_LOTCTL + "' "
			_cQry += "                AND BF_PRODUTO = 'DANULM569') AS SBF,            " // TODO
			_cQry += "        (SELECT ISNULL(SUM(Z16_SALDO), 0)                        "
			_cQry += "         FROM  " + RetSqlTab("Z16") + " (nolock) "
			_cQry += "         WHERE " + RetSqlCond("Z16")
			_cQry += "                AND Z16_ENDATU = '" + _cEnd + "'               "
			_cQry += "                AND Z16_LOTCTL = '" + (_cAlEnd)->Z16_LOTCTL + "' "
			_cQry += "                AND Z16_SALDO > 0 "
			_cQry += "                AND Z16_CODPRO = 'DANULM569')                    "  // TODO
			_cQry += "        + (SELECT Z16_SALDO                                      "
			_cQry += "           FROM " + RetlSqlTab("Z16") + " (nolock) "
			_cQry += "           WHERE " + RetlSqlCond("Z16")
			_cQry += "                  AND Z16_SALDO > 0                              "
			_cQry += "                  AND Z16_CODPRO = 'DANULM569    '               " // TODO
			_cQry += "                  )    AS Z16   "

			_aRet := U_SqlToVet(_cQry)

			If ( _aRet[1][1] != _aRet[1][2])
				_lRet := .F.

				Help(,, 'TWMSA046.F01.005',, "Correção de pallet não permitida", 1, 0,;
				NIL, NIL, NIL, NIL, NIL,;
				{ "Divergência entre saldo lógico e fiscal do endereço " + _cEnd + " . Não é possível a correção automática"} )
			EndIf
		Else
			_lRet := .F.
	
			Help(,, 'TWMSA046.F01.003',, "Correção de pallet não permitida", 1, 0,;
			NIL, NIL, NIL, NIL, NIL,;
			{ "O tipo de estrutura física do endereço não permite a correção automática. Será necessário submeter a análise do TI via chamado"} )
		EndIf

	EndIf

	// passou em todas as validações, preenche a variável de retorno do endereço
	If (_lRet)
		mvEnder := _cEnd
	Endif

Return (_lRet)


