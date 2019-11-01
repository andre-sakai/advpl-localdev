#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina de analise de pedidos de compra                  !
+------------------+---------------------------------------------------------+
!Autor             ! Odair                                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 10/2013                                                 !
+------------------+--------------------------------------------------------*/

User Function TCOMA005()

	// nivel do usuario logado
	Private _cNivAlUsr := U_FtCom06A(__cUserId) //Verifica o nível do usuário

	// id do perfil do usuario
	Private _cIdPerfUs := ""

	Private _nTVtot1 := 0 // VALOR PENDENTE ALCADA
	Private _nTQtot1 := 0 // QTDE PENDENTE ALCADA
	Private _nTVtot2 := 0 // Valor pendente abaixo
	Private _nTQtot2 := 0 // total pendente abaixo
	Private _nTQtot3 := 0 // total pendente acima
	Private _nTVtot3 := 0 // Valor pendente acima

	// legendas
	Private _oPreto    := LoadBitMap(GetResources(), "BR_PRETO")    // Com outra alçada
	Private _oVermelho := LoadBitMap(GetResources(), "BR_VERMELHO") // Aprovados
	Private _oAmarelo  := LoadBitMap(GetResources(), "BR_AMARELO")  // Pendente
	Private _oVerde    := LoadBitMap(GetResources(), "BR_VERDE")    // Aprovados / Media
	Private _oAzul     := LoadBitMap(GetResources(), "BR_AZUL")     // Aprovados
	Private _oBranco   := LoadBitMap(GetResources(), "BR_BRANCO")   // Aprovados

	// lista dos perfis disponiveis por usuario
	Private _aOpcPerfil := sfTabZ26()
	Private _cOpcPerfil := IIf(Len(_aOpcPerfil)==0, "", _aOpcPerfil[1])

	Private _oCorLeg

	Private _aPcAprvR := {}

	// valida perfil do usuario logado
	If (Empty(_cOpcPerfil))
		// mensagem
		MsgAlert("Usuário sem acesso para uso desta rotina, ou cadastro de alçadas/orçamentos não está disponível para este perfil.")
		// retorno
		Return(.f.)
	EndIf

	// abre a tela de analise de dados
	sfDlgAnalise()

Return

// ** funcao que apresenta a tela com o resumo/pendencias por perfil
Static Function sfDlgAnalise()
	// area atual
	Local _aAreaAtu := GetArea()

	// dimensoes da tela
	Local _aSizeDlg := MsAdvSize()

	Local oBold

	Local _aRelPcApr := {}

	// objetos da tela
	local _oPnlDivSu, _oPnlDivIn
	local _oPnlCabSu, _oPnCabIn1, _oPnCabIn2
	local _oSayQtd1, _oSayVlr1, _oSayQtd2, _oSayVlr2, _oSayQtd3, _oSayVlr3
	local _oGetQtd1, _oGetVlr1, _oGetQtd2, _oGetVlr2, _oGetQtd3, _oGetVlr3
	local _oFldOutNiv
	local _oBtnAnalise, _oBtnFechar, _oBtnJustif, _oBtnVisPC

	// pastas do FOLDER
	local _aFolders := {'Pedidos Pendentes de Alçadas Inferiores','Pedidos Pendentes de Alçadas Superiores'}

	// objetos da tela
	Private _oDlgAnalise
	Private _oBrwMeus, _oBrwAbaixo, _oBrwAcima

	// variavel com a relacao de pedidos na alcada do usuario logado
	Private _aPedMeus := {}

	// variavel com a relacao de pedidos na alcada abaixo do usuario logado
	Private _aPedAbaixo := {}

	// variavel com a relacao de pedidos na alcada acima do usuario logado
	Private _aPedAcima := {}

	// processa consulta/atualizacao de dados
	sfProcPed(_cOpcPerfil)

	// fontes utilizadas
	DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD

	DEFINE MSDIALOG _oDlgAnalise FROM _aSizeDlg[7],000 TO _aSizeDlg[6],_aSizeDlg[5] TITLE "Relação de Pedidos Bloqueados " Of oMainWnd PIXEL
	_oDlgAnalise:lMaximized := .T.

	// painel Cabeçalho
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgAnalise,,.F.,.F.,,,028,028,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// legendas
	@ 002, 005 BITMAP oBmp RESNAME "BR_VERMELHO" oF _oPnlCabec SIZE 20,20 NOBORDER WHEN .F. PIXEL
	@ 002, 015 Say "Prior. Alta" of _oPnlCabec PIXEL SIZE 60,9 FONT oBold

	@ 010, 005 BITMAP oBmp RESNAME "BR_AMARELO" oF _oPnlCabec SIZE 20,20 NOBORDER WHEN .F. PIXEL
	@ 010, 015 Say "Prior. Média" of _oPnlCabec PIXEL SIZE 60,9 FONT oBold

	@ 018, 005 BITMAP oBmp RESNAME "BR_AZUL" oF _oPnlCabec SIZE 20,20 NOBORDER WHEN .F. PIXEL
	@ 018, 015 Say "Prior. Baixa" of _oPnlCabec PIXEL SIZE 60,9 FONT oBold

	// perfil e botoes de controle
	@ 007, 060  Say "Perfil ===> " of _oPnlCabec  PIXEL SIZE 40,30 FONT oBold
	_oGetPerf := TComboBox():New(006,100,{|u| If(PCount()>0,_cOpcPerfil:=u,_cOpcPerfil)},_aOpcPerfil,130,025,_oPnlCabec,,,,,,.T.,oBold,"",,,,,,,_cOpcPerfil)
	_oBtnAnalise := TButton():New(005,300, "Atualizar", _oPnlCabec, { || sfAtuDados(_cOpcPerfil) }, 080, 13,,oBold,, .T. )
	_oBtnFechar  := TButton():New(005,390, "Fechar"   , _oPnlCabec, { || _oDlgAnalise:End() }, 080, 13,,oBold,, .T. )

	// painel divisor (superior)
	_oPnlDivSu := TPanel():New(010,010,'',_oDlgAnalise,,.F.,.F.,,,((_aSizeDlg[6]/2)/2),((_aSizeDlg[6]/2)/2),.T.,.F. )
	_oPnlDivSu:Align:= CONTROL_ALIGN_TOP

	// painel cabecalho do painel superior (_oPnlDivSu)
	_oPnlCabSu := TPanel():New(000,000,'',_oPnlDivSu,,.F.,.F.,,,20,20,.T.,.F. )
	_oPnlCabSu:Align:= CONTROL_ALIGN_TOP

	//painel 1
	@ 005, 050  Say "Pedidos Pendentes Alçada  ===> " of _oPnlCabSu  PIXEL SIZE 100,15 FONT oBold

	// quantidade de pedidos pendentes para a alcada do usuario logado
	_oSayQtd1 := TSay():New(007,170,{||"Quantidade"},_oPnlCabSu,,oBold,.F.,.F.,.F.,.T.,,,060,008)
	_oGetQtd1 := TGet():New(005,210,{|u| If(PCount()>0,_nTQtot1:=u,_nTQtot1)},_oPnlCabSu,070,009,"@E 999,999",,,,oBold,,,.T.,"Quantidade de Pedidos Pendentes",,{|| .f. },.F.,.F.,,.F.,.F.,"","_nTQtot1",,)

	// valor total pendente para a alcada do usuario logado
	_oSayVlr1 := TSay():New(007,300,{||"Valor Total:"},_oPnlCabSu,,oBold,.F.,.F.,.F.,.T.,,,060,008)
	_oGetVlr1 := TGet():New(005,350,{|u| If(PCount()>0,_nTVtot1:=u,_nTVtot1)},_oPnlCabSu,070,009,PesqPict("SC7","C7_TOTAL"),,,,oBold,,,.T.,"Valor Total Pendente",,{|| .f. },.F.,.F.,,.F.,.F.,"","_nTVtot1",,)

	// browse superior com dados dos pedido do usuario logado
	_oBrwMeus:= TWBrowse():New(000,002,_aSizeDlg[6],400,,{"1", "Pedido", "Valor", "Centro de Custo", "Desc. C.Custo", "Item Contábil", "Desc. Item", "Conta contábil", "Desc. Conta", "Usuário", "Controle Alçada" },,_oPnlDivSu,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	_oBrwMeus:Align:= CONTROL_ALIGN_ALLCLIENT
	_oBrwMeus:SetArray(_aPedMeus)
	_oBrwMeus:bLine	:= { || {;
	_aPedMeus[_oBrwMeus:nAT][ 1] ,;
	_aPedMeus[_oBrwMeus:nAT][ 2] ,;
	Transf(_aPedMeus[_oBrwMeus:nAT][9],PesqPict("SC7","C7_TOTAL")) , ;
	_aPedMeus[_oBrwMeus:nAT][ 3] ,;
	_aPedMeus[_oBrwMeus:nAT][ 4] ,;
	_aPedMeus[_oBrwMeus:nAT][ 5] ,;
	_aPedMeus[_oBrwMeus:nAT][ 6] ,;
	_aPedMeus[_oBrwMeus:nAT][ 7] ,;
	_aPedMeus[_oBrwMeus:nAT][ 8] ,;
	_aPedMeus[_oBrwMeus:nAT][11] ,;
	_aPedMeus[_oBrwMeus:nAT][12] }}
	// duplo clique
	_oBrwMeus:bldblClick := {|| ;
	sfDlgDetalhes("1", _aPedMeus[_oBrwMeus:nAT][3], _aPedMeus[_oBrwMeus:nAT][5] ) ,;
	sfAtuDados(_cOpcPerfil),;
	_oGetQtd1:Refresh()    ,;
	_oGetVlr1:Refresh()    ,;
	_oGetQtd2:Refresh()    ,;
	_oGetVlr2:Refresh()    ,;
	_oBrwMeus:Refresh()    ,;
	_oBrwAbaixo:Refresh()   }

	// painel divisor (inferior)
	_oPnlDivIn := TPanel():New(010,010,'',_oDlgAnalise,,.F.,.F.,,,_aSizeDlg[6],_aSizeDlg[6],.T.,.F. )
	_oPnlDivIn:Align:= CONTROL_ALIGN_ALLCLIENT

	// pastas com as opcoes de visualizacao de outras alcadas
	_oFldOutNiv := TFolder():New(000,000,_aFolders,,_oPnlDivIn,,,,.T.,,200,200)
	_oFldOutNiv:Align:= CONTROL_ALIGN_ALLCLIENT

	// painel Folder 1
	_oPnCabIn1 := TPanel():New(010,010,'',_oFldOutNiv:aDialogs[1],,.F.,.F.,CLR_BLACK,,20,20,.T.,.F. )
	_oPnCabIn1:Align:= CONTROL_ALIGN_TOP

	// painel 2
	@ 005, 020 Say "Pedidos Pendentes de Alçadas Inferiores ===> " of _oPnCabIn1 PIXEL SIZE 150,15 FONT oBold
	// quantidade de pedidos pendentes para a alcada abaixo do usuario logado
	_oSayQtd2 := TSay():New(007,170,{||"Quantidade"},_oPnCabIn1,,oBold,.F.,.F.,.F.,.T.,,,060,008)
	_oGetQtd2 := TGet():New(005,210,{|u| If(PCount()>0,_nTQtot2:=u,_nTQtot2)},_oPnCabIn1,070,009,"@E 999,999",,,,oBold,,,.T.,"Quantidade de Pedidos Pendentes",,{|| .f. },.F.,.F.,,.F.,.F.,"","_nTQtot2",,)

	// valor total pendente para a alcada abaixo do usuario logado
	_oSayVlr2 := TSay():New(007,300,{||"Valor Total:"},_oPnCabIn1,,oBold,.F.,.F.,.F.,.T.,,,060,008)
	_oGetVlr2 := TGet():New(005,350,{|u| If(PCount()>0,_nTVtot2:=u,_nTVtot2)},_oPnCabIn1,070,009,PesqPict("SC7","C7_TOTAL"),,,,oBold,,,.T.,"Valor Total Pendente",,{|| .f. },.F.,.F.,,.F.,.F.,"","_nTVtot2",,)

	// browse inferior com dados dos pedidos abaixo do perfil do usuario logado
	_oBrwAbaixo:= TWBrowse():New(500,002,_aSizeDlg[6],400,,{"2", "Pedido", "Valor", "Centro de Custo", "Desc. C.Custo", "Item Contábil", "Desc. Item","Conta contábil","Desc. Conta","Usuário"," Alçada Responsavel" },,_oFldOutNiv:aDialogs[1],,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	_oBrwAbaixo:Align:= CONTROL_ALIGN_ALLCLIENT
	_oBrwAbaixo:SetArray(_aPedAbaixo)
	_oBrwAbaixo:bLine := { || {;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 1] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 2] ,;
	Transf(_aPedAbaixo[_oBrwAbaixo:nAT][9],PesqPict("SC7","C7_TOTAL")) ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 3] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 4] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 5] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 6] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 7] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 8] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][11] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][12] }}
	// duplo clique
	_oBrwAbaixo:bldblClick := {|| ;
	sfDlgDetalhes("2", _aPedAbaixo[_oBrwAbaixo:nAT][3], _aPedAbaixo[_oBrwAbaixo:nAT][5] ), ;
	sfAtuDados(_cOpcPerfil),;
	_oGetQtd1:Refresh()    ,;
	_oGetVlr1:Refresh()    ,;
	_oGetQtd2:Refresh()    ,;
	_oGetVlr2:Refresh()    ,;
	_oBrwMeus:Refresh()    ,;
	_oBrwAbaixo:Refresh()   }

	// painel Folder 2
	_oPnCabIn2 := TPanel():New(010,010,'',_oFldOutNiv:aDialogs[2],,.F.,.F.,CLR_BLACK,,20,20,.T.,.F. )
	_oPnCabIn2:Align:= CONTROL_ALIGN_TOP

	// painel 2
	@ 006, 008 Say "Pedidos Pendentes de Alçadas Superiores ===> " of _oPnCabIn2 PIXEL SIZE 150,15 FONT oBold
	// quantidade de pedidos pendentes para a alcada abaixo do usuario logado
	_oSayQtd3 := TSay():New(007,150,{||"Quantidade"},_oPnCabIn2,,oBold,.F.,.F.,.F.,.T.,,,060,008)
	_oGetQtd3 := TGet():New(005,190,{|u| If(PCount()>0,_nTQtot3:=u,_nTQtot3)},_oPnCabIn2,030,009,"@E 999,999",,,,oBold,,,.T.,"Quantidade de Pedidos Pendentes",,{|| .f. },.F.,.F.,,.F.,.F.,"","_nTQtot3",,)

	// valor total pendente para a alcada acima do usuario logado
	_oSayVlr3 := TSay():New(007,230,{||"Valor Total:"},_oPnCabIn2,,oBold,.F.,.F.,.F.,.T.,,,060,008)
	_oGetVlr3 := TGet():New(005,270,{|u| If(PCount()>0,_nTVtot3:=u,_nTVtot3)},_oPnCabIn2,070,009,PesqPict("SC7","C7_TOTAL"),,,,oBold,,,.T.,"Valor Total Pendente",,{|| .f. },.F.,.F.,,.F.,.F.,"","_nTVtot3",,)

	// botao que permite justificar
	_oBtnJustif := TButton():New(003,360, "Justificar", _oPnCabIn2, {|| sfObseRec(_aPedAcima[_oBrwAcima:nAT][2], _aPedAcima[_oBrwAcima:nAT][3], _aPedAcima[_oBrwAcima:nAT][5], _aPedAcima[_oBrwAcima:nAT][13], _aPedAcima[_oBrwAcima:nAT][9], "J") }, 060, 13,,oBold,, .T. )

	// botao que permite visualizar o pedido
	_oBtnVisPC := TButton():New(003,430, "Visual. Pedido", _oPnCabIn2, {|| sfVisuPc(_aPedAcima[_oBrwAcima:nAT][2]) }, 060, 13,,oBold,, .T. )

	// browse da segunda aba com dados dos pedidos acima do perfil do usuario logado
	_oBrwAcima:= TWBrowse():New(500,002,_aSizeDlg[6],400,,{"3", "Pedido", "Valor", "Centro de Custo", "Desc. C.Custo", "Item Contábil", "Desc. Item","Conta contábil","Desc. Conta","Usuário"," Alçada Responsavel" },,_oFldOutNiv:aDialogs[2],,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	_oBrwAcima:Align:= CONTROL_ALIGN_ALLCLIENT
	_oBrwAcima:SetArray(_aPedAcima)
	_oBrwAcima:bLine := { || {;
	_aPedAcima[_oBrwAcima:nAT][ 1] ,;
	_aPedAcima[_oBrwAcima:nAT][ 2] ,;
	Transf(_aPedAcima[_oBrwAcima:nAT][9],PesqPict("SC7","C7_TOTAL")) ,;
	_aPedAcima[_oBrwAcima:nAT][ 3] ,;
	_aPedAcima[_oBrwAcima:nAT][ 4] ,;
	_aPedAcima[_oBrwAcima:nAT][ 5] ,;
	_aPedAcima[_oBrwAcima:nAT][ 6] ,;
	_aPedAcima[_oBrwAcima:nAT][ 7] ,;
	_aPedAcima[_oBrwAcima:nAT][ 8] ,;
	_aPedAcima[_oBrwAcima:nAT][11] ,;
	_aPedAcima[_oBrwAcima:nAT][12] }}

	// ativa a tela
	ACTIVATE MSDIALOG _oDlgAnalise CENTERED

	// restaura area inicial
	RestArea(_aAreaAtu)

Return

// ** funcao para atualizar os dados da tela
Static Function sfAtuDados(mvOpcPerfil)

	Processa( {|lEnd| sfProcPed(mvOpcPerfil) }, "Aguarde...","Analisando Alçadas", .T. )
	sfatutela()

Return

// ** funcao para atualizar os dados das variaveis de controle
Static Function sfProcPed(mvOpcPerfil)
	// atualiza nivel do usuario
	_cNivAlUsr := Substr(mvOpcPerfil,8,1)
	// atualiza codigo do perfil
	_cIdPerfUs := Substr(mvOpcPerfil,1,6)

	// zera variaveis
	_aPcAprvR := {}
	_nTVtot1  := 0
	_nTQtot1  := 0
	_nTVtot2  := 0
	_nTQtot2  := 0
	_nTVtot3  := 0
	_nTQtot3  := 0

	// regua de processamento
	Procregua(3)

	incproc('Alçada Atual')
	_aPedMeus := sfAtPesq01("1")
	_aPcAprvR := {}

	incproc('Alçadas Inferiores')
	_aPedAbaixo := sfAtPesq01("2")
	_aPcAprvR := {}

	incproc('Alçadas Superiores')
	_aPedAcima := sfAtPesq01("3")
	_aPcAprvR := {}

Return

// ** funcao que atualiza area de trabalho da primeira tela
Static Function sfAtPesq01(_cTpFol)

	// codigo do usuario responsavel pela alcada
	local _cCodUsrAlc := ""

	// detalhes da alcara responsavel (ID Alcada + Nivel + Nome Responavel)
	local _cDetAlcRes := ""

	Local _aPcRelat1 := {}
	Local _aPedid := {}
	Local _nSalCC := 0
	local _ni := 0

	_aPcRelat1 := sfApPesq1(_cTpFol, _cIdPerfUs, _cNivAlUsr)

	if ( len(_aPcRelat1) > 0 )

		For _ni := 1 to len(_aPcRelat1)

			// posiciona no centro de custo
			dbSelectArea('CTT')
			dbSetOrder(1)
			dbSeek(xFilial()+_aPcRelat1[_ni][3])

			// posiciona no item contabil
			dbSelectArea('CTD')
			dbSetOrder(1)
			dbSeek(xFilial()+_aPcRelat1[_ni][4])

			// posiciona na conta contabil
			dbSelectArea('CT1')
			dbSetOrder(1)
			dbSeek(xFilial()+_aPcRelat1[_ni][7])

			// pesquisa o usuario responsavel pelo ID da Alcada
			_cCodUsrAlc := U_FtAlcID(_aPcRelat1[_ni][9], _aPcRelat1[_ni][3], _aPcRelat1[_ni][4], dDataBase,.T.)

			// prepara variavel com detalhes da alcada responsavel
			_cDetAlcRes := _aPcRelat1[_ni][9]+"-"+_aPcRelat1[_ni][8]+" / "+ALLTRIM(upper(_cCodUsrAlc))

			// aplica o padrão de legenda baseada na prioridade.
			Do Case
				Case (_aPcRelat1[_ni][10] == "1")
				_oCorLeg := _oVermelho
				Case (_aPcRelat1[_ni][10] == "2")
				_oCorLeg := _oAmarelo
				Case (_aPcRelat1[_ni][10] == "3")
				_oCorLeg := _oAzul
			EndCase

			// adiciona os dados no vetor de retorno
			aAdd(_aPedid,{;
			_oCorLeg           ,;
			_aPcRelat1[_ni][1] ,;
			_aPcRelat1[_ni][3] ,;
			CTT->CTT_DESC01    ,;
			_aPcRelat1[_ni][4] ,;
			CTD->CTD_DESC01    ,;
			_aPcRelat1[_ni][7] ,;
			CT1->CT1_DESC01    ,;
			_aPcRelat1[_ni][5] ,;
			_nSalCC            ,;
			_aPcRelat1[_ni][11] ,;
			_cDetAlcRes        ,;
			_aPcRelat1[_ni][6] })

			// atualiza variaveis de total
			IF (_cTpFol == '1')
				_nTVTot1 += _aPcRelat1[_ni][5]
				_nTQTot1 += 1
			ElseIF (_cTpFol == '2')
				_nTVTot2 += _aPcRelat1[_ni][5]
				_nTQTot2 += 1
			ElseIF (_cTpFol == '3')
				_nTVtot3 += _aPcRelat1[_ni][5]
				_nTQtot3 += 1
			Endif

		Next _ni
	Else
		aAdd(_aPedid,{_oVERMELHO,"","","","","","","","","","",""})
	EndIf

Return(_aPedid)


//Pesquisa PC aguardando aprovação
Static Function sfApPesq1(_cTpfol, _cPerAT, _cNivAT)

	Local _cQryPesCv := ""
	Local _aPcAprv   := {}

	// variaveis temporarias
	local _ni := 0

	// prepara query
	_cQryPesCv := "SELECT C7_NUM, C7_DATPRF, C7_CC, C7_ITEMCTA, SUM(C7_TOTAL), C7_ZUSRSC, "
	_cQryPesCv += " C7_CONTA, C7_ZNIVRAP, C7_ZALCRAP, C7_ZPRIORI,Case When DCD_NOMFUN IS NULL Then 'Cadastrar ID no WMS: '+C7_ZUSRSC Else DCD_NOMFUN End as Nome "
	// ped. compras / cad. TES
	_cQryPesCv += " FROM "+RetSqlName("SC7")+" SC7 (nolock) "
	
	_cQryPesCv += " inner join "+RetSqlName("SF4")+" SF4 (nolock) "
	_cQryPesCv += " on SF4.D_E_L_E_T_ = '' "
	_cQryPesCv += " and F4_FILIAL = '"+xFilial("SF4")+"' "

	_cQryPesCv += " Left join "+RetSqlName("DCD")+" DCD (nolock) "
	_cQryPesCv += " on DCD.D_E_L_E_T_ = '' "
	_cQryPesCv += " and DCD_CODFUN = C7_ZUSRSC "
	
	// filtro padrao
	_cQryPesCv += " WHERE "+RetSqlCond("SC7,SF4")
	// TES / Gera Financeiro
	_cQryPesCv += " AND C7_TES = F4_CODIGO AND F4_DUPLIC = 'S' "
	// somente itens bloqueados
	_cQryPesCv += " AND C7_CONAPRO = 'B' "
	// descarta itens ja recusados / eliminados por residuo
	_cQryPesCv += " AND C7_ZCONTAL <> 'X' AND C7_RESIDUO <> 'S' "
	// periodo/calendario
	_cQryPesCv += " AND SUBSTRING(C7_DATPRF,1,6) = '"+SubS(DtoS(dDatabase),1,6)+"' "

	// valida o nível onde se encontra o pedido em aprovação.
	If (_cTpfol == '1') //PEGA OS PCS PARA APROVACAO DA ALCADA
		_cQryPesCv += "    AND C7_ZALCRAP = '"+_cPerAT+"'  "
		_cQryPesCv += "    AND C7_ZNIVRAP = '"+_cNivAT+"'  "

	ElseIf (_cTpfol == '2') //PEGA OS PCS PARA APROVACAO DA ALCADA - ABAIXO
		_cQryPesCv += "AND C7_ZALCRAP IN "
		_cQryPesCv += "( SELECT Z26_PERFID FROM "+RetSqlName("Z26")+" Z26 WHERE "+RetSqlCond("Z26")+"  "
		_cQryPesCv += "    AND Z26_CALEND =  '"+SubS(DtoS(dDatabase),1,4)+"' "
		_cQryPesCv += "    AND Z26_PERSUP = '"+_cPerAT+"'  "
		_cQryPesCv += "    AND Z26_PERSUP IN "
		_cQryPesCv += "   (  "
		_cQryPesCv += "         SELECT Z27B.Z27_PERFIL FROM "+RetSqlName("Z27")+" Z27B "
		_cQryPesCv += "            WHERE Z27B.Z27_FILIAL = '"+xFilial("Z27")+"' AND Z27B.D_E_L_E_T_ = '' "
		_cQryPesCv += "            AND Z27B.Z27_CC = C7_CC "
		_cQryPesCv += "            AND Z27B.Z27_ITEMC = C7_ITEMCTA "
		_cQryPesCv += "            AND Z27B.Z27_CALEND = Z26.Z26_CALEND "
		_cQryPesCv += "            AND SUBSTRING(Z27_DATAIN,1,6) = '"+SubS(DtoS(dDatabase),1,6)+"' "
		_cQryPesCv += "   )
		_cQryPesCv += ") "

	ElseIf (_cTpfol == '3') //PEGA OS PCS PARA APROVACAO DA ALCADA - ACIMA

		_cQryPesCv += " AND C7_ZIDALCA IN " + sfRetAbaixo(_cPerAT)
		_cQryPesCv += " AND C7_ZNIVRAP < '"+_cNivAT+"' "

	Endif
	// agrupa dados
	_cQryPesCv += "GROUP BY C7_NUM,C7_DATPRF, C7_CC, C7_ITEMCTA, C7_NUM, DCD_NOMFUN, C7_ZUSRSC, C7_CONTA,  C7_ZNIVRAP, C7_ZALCRAP,C7_ZPRIORI "
	// ordem dos dados
	_cQryPesCv += "ORDER BY C7_ZNIVRAP, C7_ZALCRAP, C7_DATPRF, C7_CC, C7_ITEMCTA "

	memowrit("c:\query\TCOMA005.Seleciona_PC_"+_cTpfol+"_"+_cPerAT+".txt",_cQryPesCv)

	// atualiza variavel com dados da query
	_aPcAprv := U_SqlToVet(_cQryPesCv)

	For _ni := 1 to len(_aPcAprv)
		aadd(_aPcAprvR,{_aPcAprv[_Ni][1],_aPcAprv[_Ni][2],_aPcAprv[_Ni][3],_aPcAprv[_Ni][4],_aPcAprv[_Ni][5],_aPcAprv[_Ni][6],_aPcAprv[_Ni][7],_aPcAprv[_Ni][8],_aPcAprv[_Ni][9],_aPcAprv[_Ni][10],_aPcAprv[_Ni][11]})
	Next _ni

	// faz novamente para buscar todos pois temos um nivel abaixo
	If (Len(_aPcAprv) > 0) .and. (_cTpfol == '2')
		For _ni := 1 to len(_aPcAprv)
			if (_cPerAT <> _aPcAprv[_NI][9]) //se existir outros pcs de outras alçadas
				sfApPesq1(_cTpfol,_aPcAprv[_NI][9],_aPcAprv[_NI][8])
				Exit
			Endif
		Next _ni
	Endif

Return ( _aPcAprvr	)


// ** funcao que monta a tela do histórico de aprovações
Static Function sfDlgDetalhes(_cTpFol, mvCenCusto, mvItemCtbl)

	// area inicial
	Local _aAreaAtu := GetArea()
	Local _aAreaSC7 := SC7->(GetArea())

	// dimensoes da tela
	local _aSizeDlg := MsAdvSize()

	Local aPedidos	:= {}

	Local oBold
	Local _oBold2
	Local oListBox
	Local _oDlg2

	// objetos da tela
	Local _oBtnAprPC, _oBtnVisPC, _oBtnRecPC
	Local _oFont1

	Local _aRelPcApr := {}

	// descricao do centro de custo
	Local _cDscCenCusto := Alltrim(mvCenCusto)+" - "+Posicione("CTT",1, xFilial("CTT")+mvCenCusto, "CTT_DESC01")
	// descricao do item contabil
	Local _cDscIteConta := Alltrim(mvItemCtbl)+" - "+Posicione("CTD",1, xFilial("CTD")+mvItemCtbl, "CTD_DESC01")

	Local _nVlrSd := 0

	// controle do saldo para apresentar no browse
	Local _nSldDispBrw := 0

	Local _cStaSC := ""
	Local _oStaCl
	Local _cMsgBtm := ""
	Local _cPcReincd := ""

	// codigo do usuario responsavel pela alcada
	local _cCodUsrAlc := ""

	// detalhes da alcara responsavel (ID Alcada + Nivel + Nome Responavel)
	local _cDetAlcRes := ""

	// fontes
	local _oFont1 := TFont():New( "Arial",0,-13,,.F.,0,,400,.F.,.F.,,,,,, )
	local _oFont2 := TFont():New( "Arial",0,-15,,.F.,0,,400,.F.,.F.,,,,,, )

	// variaveis temporarias
	local _nNrPed

	// valor limite por alcada
	private _nVlrLimAlc := 0

	// total pendente
	private _nTotPendente := 0

	// total aprovado no mes
	private _nTotAprovado := 0

	// saldo total disponivel
	private _nSaldoDisp := 0

	// valor limite da alcada
	_nVlrLimAlc := U_FTCOM08A(__cUserId, '', "L", mvCenCusto, mvItemCtbl, dDataBase)

	// total ja aprovado/consumido no mes
	_nTotAprovado := U_FTVALPC(mvCenCusto, mvItemCtbl, dDataBase, Nil, .t.)

	// calculo do saldo disponivel
	_nSaldoDisp := _nVlrLimAlc - _nTotAprovado

	// atualiza o saldo usado no browse
	_nSldDispBrw := _nSaldoDisp

	// busca todos os pedidos disponiveis
	_aRelPcApr := sfApPesq2(_cTpFol, mvCenCusto, mvItemCtbl)

	if ( len(_aRelPcApr) > 0 )

		For _nNrPed := 1 to len(_aRelPcApr)

			// reinicia variaveis
			_cPcReincd := ""

			// saldo total disponivel
			If (_aRelPcApr[_nNrPed][8]=="B").and.(_aRelPcApr[_nNrPed][9]<>"X")
				_nSldDispBrw -= _aRelPcApr[_nNrPed][4]
				_nSaldoDisp  -= _aRelPcApr[_nNrPed][4]
			EndIf

			// posiciona no pedido de compras
			dbSelectArea('SC7')
			SC7->(dbSetOrder(1)) // 1 - C7_FILIAL, C7_NUM, C7_ITEM, C7_SEQUEN
			SC7->(dbSeek( xFilial("SC7")+_aRelPcApr[_nNrPed][1]) )

			// pesquisa o usuario responsavel pelo ID da Alcada
			_cCodUsrAlc := U_FtAlcId(_aRelPcApr[_nNrPed][10], mvCenCusto, mvItemCtbl, dDataBase,.T.)

			// prepara variavel com detalhes da alcada responsavel
			_cDetAlcRes := _aRelPcApr[_nNrPed][10]+"-"+_aRelPcApr[_nNrPed][11]+" / "+ALLTRIM(upper(_cCodUsrAlc))

			dbSelectArea('CT1')
			dbSetOrder(1)
			dbSeek(xFilial()+_aRelPcApr[_nNrPed][3])

			Do Case

				Case (_aRelPcApr[_nNrPed][8]=="B").and.(_aRelPcApr[_nNrPed][9] <> "X")
				_oStaCl := _oAmarelo
				_nTotPendente += _aRelPcApr[_nNrPed][4]

				Case (_aRelPcApr[_nNrPed][8]=="B").and.(_aRelPcApr[_nNrPed][9]=="X") //Item bloqueado e já recusado
				_oStaCl := _oPreto

				Case (_aRelPcApr[_nNrPed][8]=="L")
				_oStaCl := _oVerde

				OtherWise
				_oStaCl := _oBranco

			EndCase

			// verifica se o pedido eh reincidente
			if ( _aRelPcApr[_nNrPed][8] == "B" ).and.(_aRelPcApr[_nNrPed][16] > 0)
				_cPcReincd := "Consulte log"
			EndIf

			// inclui a linha com os detalhes
			aAdd(aPedidos,{;
			_oStaCl                             ,;
			_aRelPcApr[_nNrPed][ 1]             ,;
			DTOC(STOD(_aRelPcApr[_nNrPed][2]))  ,;
			_aRelPcApr[_nNrPed][ 3]             ,;
			CT1->CT1_DESC01                     ,;
			_aRelPcApr[_nNrPed][ 4]             ,;
			_nSldDispBrw                        ,;
			_aRelPcApr[_nNrPed][17]             ,;
			_aRelPcApr[_nNrPed][5]              ,;
			StrZero(_aRelPcApr[_nNrPed][12],3)+" / "+StrZero(_aRelPcApr[_nNrPed][13],3),;
			_aRelPcApr[_nNrPed][ 8]             ,;
			_cPcReincd                          ,;
			_aRelPcApr[_nNrPed][14]             ,;
			_aRelPcApr[_nNrPed][15]             ,;
			_cDetAlcRes                         })

		Next _nNrPed
	Else
		aAdd(aPedidos,{_oAmarelo,"","","","","","","","","","","","","",""})
	EndIf


	DEFINE MSDIALOG _oDlg2 FROM _aSizeDlg[7],000 TO _aSizeDlg[6],_aSizeDlg[5] TITLE "Histórico do Centro de Custo e Item Contábil no Mês" Of oMainWnd PIXEL

	// painel Cabeçalho
	_oPnlCabT2 := TPanel():New(000,000,nil,_oDlg2,,.F.,.F.,,,100,100,.T.,.F. )
	_oPnlCabT2:Align:= CONTROL_ALIGN_TOP

	// botao para aprovar um pedido de compras
	_oBtnAprPC := TButton():New(070, 010, "Aprova Pedido/Item", _oPnlCabT2, { || aPedidos[oListBox:nAT][1] := sfBtnApro(aPedidos[oListBox:nAT][2], mvCenCusto, mvItemCtbl, aPedidos[oListBox:nAT][9], aPedidos[oListBox:nAT][6], "S", aPedidos[oListBox:nAT][11], aPedidos[oListBox:nAT][1] ), oListBox:Refresh(), _oDlg2:Refresh() }, 100, 20,,_oFont2,, .T. )
	_oBtnAprPC:bWhen := {|| _cTpFol != "3" }

	// botao para visualizar o pedido de compras
	_oBtnVisPC := TButton():New(070, 140, "Visualiza Pedido"  , _oPnlCabT2, { || sfVisuPc(aPedidos[oListBox:nAT][2]) }, 100, 20,,_oFont2,, .T. )

	// botao para recusar pedido de compras
	_oBtnRecPC := TButton():New(070, 270, "Recusa Solicitação", _oPnlCabT2, { || aPedidos[oListBox:nAT][1] := sfBtnApro(aPedidos[oListBox:nAT][2], mvCenCusto, mvItemCtbl, aPedidos[oListBox:nAT][9], aPedidos[oListBox:nAT][6], "R", aPedidos[oListBox:nAT][11], aPedidos[oListBox:nAT][1] ), oListBox:Refresh(), _oDlg2:Refresh() }, 100, 20,,_oFont2,, .T. )
	_oBtnRecPC:bWhen := {|| _cTpFol != "3" }

	//Cria objeto de menu
	_oMenu := TMenu():New(0,0,0,0,.T.)
	// Adiciona detalhes dos itens no Menu
	_oTMenuIt1 := TMenuItem():New(_oPnlCabT2,"Log Operação"  ,,,,{|| MsgRun("Selecionando informações...", "Aguarde...", {|| sfConsLog(aPedidos[oListBox:nAT][2], mvCenCusto, mvItemCtbl, STRZERO(aPedidos[oListBox:nAT][6],15,2), aPedidos[oListBox:nAT][8]) }),},,,,,,,,,.T.)
	_oTMenuIt2 := TMenuItem():New(_oPnlCabT2,"Justificativa" ,,,,{|| sfObseRec(aPedidos[oListBox:nAT][2], mvCenCusto, mvItemCtbl, aPedidos[oListBox:nAT][9], aPedidos[oListBox:nAT][6], "J") } ,,,,,,,,,.T.)
	// Adiciona itens no Menu
	_oMenu:Add(_oTMenuIt1)
	_oMenu:Add(_oTMenuIt2)

	//Botão para seleção de operação
	_oBtnCc := TButton():New(070,400,"Opções",_oPnlCabT2,{|| } ,080,020,,_oFont2,,.T.,,"",,,,.F. )
	//Define o botão como menu
	_oBtnCc:SetPopupMenu(_oMenu)

	oListBox := TWBrowse():New(080,2,480,205,,{" ", "Pedido" , "Necessidade", "Valor", "Saldo", "Usuário", "Itens do Pedido", "Reincidente", "Fornecedor", "Cond.Pagto", "Alçada Responsavel"},,_oDlg2,,,,,,,,/*fore*/,/*back*/,,,.F.,,.T.,,.F.,,,)
	//Alinha browse em toda a tela
	oListBox:Align:= CONTROL_ALIGN_ALLCLIENT
	//Carrega browse com o array
	oListBox:SetArray(aPedidos)
	//Carrega linha selecionada
	oListBox:bLine := {|| {;
	aPedidos[oListBox:nAT][ 1] ,;
	aPedidos[oListBox:nAT][ 2] ,;
	aPedidos[oListBox:nAT][ 3] ,;
	transform(aPedidos[oListBox:nAT][6],PesqPict("SC7","C7_TOTAL")),;
	transform(aPedidos[oListBox:nAT][7],PesqPict("SC7","C7_TOTAL")),;
	aPedidos[oListBox:nAT][ 8] ,;
	aPedidos[oListBox:nAT][10] ,;
	aPedidos[oListBox:nAT][12] ,;
	aPedidos[oListBox:nAT][13] ,;
	aPedidos[oListBox:nAT][14] ,;
	aPedidos[oListBox:nAT][15] }}
	//Atualiza Browse
	oListBox:Refresh()

	_oGrupo1    := TGroup():New( 005,002,065,478,"",_oPnlCabT2,RGB(0,0,0),,.T.,.F. )

	_oSay1      := TSay():New( 012,005,{||"Centro de Custo:"},_oGrupo1,,_oFont1,.F.,.F.,.F.,.T.,	  RGB(0,0,156),RGB(255,255,255),060,008)
	_oCCusto    := TGet():New( 010,060,{|u| If(PCount()>0,_cDscCenCusto:=u,_cDscCenCusto)},_oGrupo1,170,010,'',,RGB(255,0,0),RGB(255,255,255),_oFont1,,,.T.,"Centro de Custo",,,.F.,.F.,,.T.,.F.,"","mvCenCusto",,)

	_oSay2      := TSay():New( 012,235,{||"Item Contábil:"},_oGrupo1,,_oFont1,.F.,.F.,.F.,.T., 	 RGB(0,0,156),RGB(255,255,255),060,008)
	_oIteCo     := TGet():New( 010,280,{|u| If(PCount()>0,_cDscIteConta:=u,_cDscIteConta)},  _oGrupo1,180,010,'',,RGB(255,0,0),RGB(255,255,255),_oFont1,,,.T.,"Item Contábil",,,.F.,.F.,,.T.,.F.,"","mvItemCtbl",,)

	_oSay3      := TSay():New( 029,005,{||"Limite Alçada:"},_oGrupo1,,_oFont1,.F.,.F.,.F.,.T., 	 RGB(0,0,156),RGB(255,255,255),060,008)
	_oLimAl     := TGet():New( 027,060,{|u| If(PCount()>0,_nVlrLimAlc:=u,_nVlrLimAlc)},  _oGrupo1,070,010,PesqPict("SC7","C7_TOTAL"),,RGB(66,111,66),RGB(255,255,255),_oFont1,,,.T.,"Limite da Alçada",,,.F.,.F.,,.T.,.F.,"","_nVlrLimAlc",,)

	_oSay4      := TSay():New( 029,235,{||"Saldo Alçada:"},_oGrupo1,,_oFont1,.F.,.F.,.F.,.T., 	 RGB(0,0,156),RGB(255,255,255),060,008)
	_oSalSl     := TGet():New( 027,280,{|u| If(PCount()>0,_nSaldoDisp:=u,_nSaldoDisp)},  _oGrupo1,070,010,PesqPict("SC7","C7_TOTAL"),,RGB(66,111,66),RGB(255,255,255),_oFont1,,,.T.,"Saldo disponível para Aprovações de Compras",,,.F.,.F.,,.T.,.F.,"","_nSaldoDisp",,)

	_oSay5      := TSay():New( 046,005,{||"Total Pendente:"},_oGrupo1,,_oFont1,.F.,.F.,.F.,.T., 	 RGB(0,0,156),RGB(255,255,255),060,008)
	_oTotPe     := TGet():New( 044,060,{|u| If(PCount()>0,_nTotPendente:=u,_nTotPendente)},  _oGrupo1,070,010,PesqPict("SC7","C7_TOTAL"),,RGB(66,111,66),RGB(255,255,255),_oFont1,,,.T.,"Total Pendente",,,.F.,.F.,,.T.,.F.,"","_nTotPendente",,)

	_oSay6      := TSay():New( 046,235,{||"Aprovado Mês:"},_oGrupo1,,_oFont1,.F.,.F.,.F.,.T., 	 RGB(0,0,156),RGB(255,255,255),060,008)
	_oTotApM    := TGet():New( 044,280,{|u| If(PCount()>0,_nTotAprovado:=u,_nTotAprovado)},  _oGrupo1,070,010,PesqPict("SC7","C7_TOTAL"),,RGB(66,111,66),RGB(255,255,255),_oFont1,,,.T.,"Aprovado Mês",,,.F.,.F.,,.T.,.F.,"","_nTotAprovado",,)

	// Painel Rodapé
	_oPnlRodT2 := TPanel():New(000,000,nil,_oDlg2,,.F.,.F.,,,20,20,.T.,.F. )
	_oPnlRodT2:Align:= CONTROL_ALIGN_BOTTOM

	@ 005, 55 BITMAP oBmp RESNAME "BR_AMARELO" oF _oPnlRodT2 SIZE 20,20 NOBORDER WHEN .F. PIXEL
	@ 005, 65 Say "Aguardando Análise" of _oPnlRodT2 PIXEL SIZE 60,9

	@ 005, 155 BITMAP oBmp RESNAME "BR_VERDE" oF _oPnlRodT2 SIZE 20,20 NOBORDER WHEN .F. PIXEL
	@ 005, 165 Say "Aprovados" of _oPnlRodT2 PIXEL SIZE 60,9

	@ 005, 255 BITMAP oBmp RESNAME "BR_PRETO" oF _oPnlRodT2 SIZE 20,20 NOBORDER WHEN .F. PIXEL
	@ 005, 265 Say "Recusados" of _oPnlRodT2 PIXEL SIZE 60,9


	ACTIVATE MSDIALOG _oDlg2 ON INIT EnchoiceBar(_oDlg2,{||_oDlg2:End()},{||_oDlg2:End()},,) CENTERED

	// restaura area inicial
	RestArea(_aAreaSC7)
	RestArea(_aAreaAtu)

Return

// ** funcao que consulta log existente e retorna o resultado
Static Function sfConsLog(mvNrPedCom, mvCenCusto, mvItemCtbl, mvUsrSolic)

	DbSelectArea("SZN")
	DbSetOrder(1)
	if	SZN->( dbSeek(xFilial("SZN")+"SC7"+cFilAnt+mvNrPedCom+"0001" ) )
		U_FtConsLog(cFilAnt, "SC7", cFilAnt+mvNrPedCom+"0001" )
	Else
		U_FtConsLog(cFilAnt, "SC7", cFilAnt+mvNrPedCom+mvCenCusto+mvItemCtbl+_cVlrAp+_cNUsuario )
	EndIf

Return

//SQL de pesquisa dos Centros de custo e Itens contábeis da Tela 2 da aprovação
//Histórico de aprovações
Static Function sfApPesq2(_cTpFol, _cCenCusto, _cItemCtbl)

	// query
	Local _cQryPesCv := ""

	// variavel de retorno
	Local _aRetPedidos := {}

	// prepara query
	_cQryPesCv := " SELECT C7_NUM, C7_DATPRF, C7_CONTA, SUM(C7_TOTAL) C7_TOTAL, C7_ZUSRSC , C7_CC, C7_ITEMCTA, C7_CONAPRO, C7_ZCONTAL, C7_ZALCRAP, C7_ZNIVRAP, COUNT(*) ITENS, "

	_cQryPesCv += "(	SELECT COUNT(*) FROM "+RetSqlName("SC7")+" SC7TOTITE "
	//
	_cQryPesCv += " 		WHERE SC7TOTITE.C7_NUM = SC7.C7_NUM  "
	//
	_cQryPesCv += " 		   AND SC7TOTITE.D_E_L_E_T_ = '' AND SC7TOTITE.C7_FILIAL = '"+xFilial("SC7")+"' ) "
	//
	_cQryPesCv += " AS TOTAL_ITENS_PEDIDO,  "

	_cQryPesCv += " A2_NOME, E4_DESCRI, "

	// verifica se eh reincidente
	_cQryPesCv += "        (SELECT Count(*) "
	_cQryPesCv += "         FROM   "+RetSqlTab("SZN")
	_cQryPesCv += "         WHERE  "+RetSqlCond("SZN")
	_cQryPesCv += "                AND ZN_TABELA = 'SC7' "
	_cQryPesCv += "                AND ZN_CHAVE IN (SELECT DISTINCT C7_FILIAL+C7_NUM+C7_ITEM "
	_cQryPesCv += "                                 FROM   "+RetSqlName("SC7")+" SC7LOG "
	_cQryPesCv += "                                 WHERE  SC7LOG.C7_NUM = SC7.C7_NUM "
	_cQryPesCv += "                                        AND SC7LOG.D_E_L_E_T_ = ' ' "
	_cQryPesCv += "                                        AND SC7LOG.C7_FILIAL = '"+xFilial("SC7")+"' "
	_cQryPesCv += " 									   AND SC7LOG.C7_CC = SC7.C7_CC "
	_cQryPesCv += " 									   AND SC7LOG.C7_ITEMCTA = SC7.C7_ITEMCTA "
	_cQryPesCv += " 									   AND SC7LOG.C7_ZUSRSC = SC7.C7_ZUSRSC ) "
	_cQryPesCv += " 									   AND (ZN_DESCRI LIKE '%VALORES DENTRO%' OR ZN_DESCRI LIKE '%LIBERADO%')) TOT_REINC, "
	
	// pega o nome do usuário
	_cQryPesCv += " Case When DCD_NOMFUN IS NULL Then 'Cadastrar ID no WMS: '+C7_ZUSRSC Else DCD_NOMFUN End as Nome "

	// pedidos de compras
	_cQryPesCv += " FROM "+RetSqlTab("SC7")+" (nolock) "
	// cad. fornecedor
	_cQryPesCv += " INNER JOIN "+RetSqlName("SA2")+" SA2 (nolock) ON "+RetSqlCond("SA2")+" AND A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA "
	// cad. cond. pagamento
	_cQryPesCv += " LEFT  JOIN "+RetSqlName("SE4")+" SE4 (nolock) ON "+RetSqlCond("SE4")+" AND E4_CODIGO = C7_COND "
	// pegar nome do usuario
	_cQryPesCv += " Left join "+RetSqlName("DCD")+" DCD (nolock) "
	_cQryPesCv += " on DCD.D_E_L_E_T_ = '' "
	_cQryPesCv += " and DCD_CODFUN = C7_ZUSRSC "
	// filtro padrao
	_cQryPesCv += " WHERE  "+RetSqlCond("SC7")
	// centro de custo
	_cQryPesCv += " AND C7_CC = '"+_cCenCusto+"' "
	// periodo (mes + ano)
	_cQryPesCv += " AND  SUBSTRING(C7_DATPRF,1,6) = '"+SubS(DtoS(dDatabase),1,6)+"' "
	// item contabil
	_cQryPesCv += " AND C7_ITEMCTA = '"+_cItemCtbl+"' "
	// agrupa dados
	_cQryPesCv += " GROUP BY C7_DATPRF, C7_CONTA, C7_NUM, DCD_NOMFUN, C7_ZUSRSC, C7_CC, C7_ITEMCTA, C7_CONAPRO, C7_ZCONTAL, C7_ZALCRAP, C7_ZNIVRAP, A2_NOME, E4_DESCRI "
	// ordem dos dados
	_cQryPesCv += " ORDER BY C7_DATPRF DESC, C7_NUM "

	memowrit("c:\query\TCOMA005.Seleciona_Tela2_"+_cTpFol+".txt",_cQryPesCv)

	// atualiza dados para retorno
	_aRetPedidos := U_SqlToVet(_cQryPesCv)

Return(_aRetPedidos)

// ** funcao para confirmar a Aprovacao ou Reprovacao do pedido de compra
Static Function sfBtnApro(mvNrPedCom, mvCenCusto, mvItemCtbl, mvUsrSolic, _nVlrApr, _cOperSt, mvStsAtual, mvCorLegen)

	// texto da pergunda
	Local _cTextoPerg := ""

	// novo status do pedido
	Local _cNovoStatus := ""

	// texto para novo status
	Local _cTextoNewSts := ""

	// observacao da recusa
	Local _cObsRec := ""

	// Seek SC7
	local _cSeekSC7

	// cor da legenda atual
	local _oCorStsAtu := mvCorLegen

	Do Case
		Case ( _cOperSt == "S" )
		_cTextoPerg   := "Autoriza orçamento para pedido de compra "+mvNrPedCom+" ?"
		_cNovoStatus  := "L"
		_cTextoNewSts := "Item do pedido de compra LIBERADO"
		Case ( _cOperSt == "R" )
		_cTextoPerg   := "Reprovar o pedido de compra "+mvNrPedCom+" ?"
		_cNovoStatus  := "X"
		_cTextoNewSts := "Item do pedido de compra RECUSADO"
	EndCase

	// validacao antes de confirmar os dados
	If ((_cOperSt == "S").and.(mvStsAtual == "L")).or.((_cOperSt == "R").and.(mvStsAtual == "L")).or.(_oCorStsAtu == _oPreto).or.(_oCorStsAtu == _oVerde)
		MsgAlert("Pedido "+mvNrPedCom+" não pode ter múltiplas aprovações.")
		Return(_oCorStsAtu)
	EndIf

	// solicita mensagem de confirmacao
	If (MsgYesNo(_cTextoPerg,'ATENÇÃO'))

		// inicia transacao
		BeginTran()

		// posiciona no pedido de compras
		dbSelectArea("SC7")
		SC7->(dbSetOrder(1)) // 1 - C7_FILIAL, C7_NUM, C7_ITEM, C7_SEQUEN
		SC7->(dbSeek( _cSeekSC7 := xFilial("SC7")+mvNrPedCom ))

		While SC7->( ! Eof() ).and.(SC7->(C7_FILIAL+C7_NUM) == _cSeekSC7)

			// valida centro de custo, item contabil, usuario solicitante e status
			If (SC7->C7_CC == mvCenCusto).and.(SC7->C7_ITEMCTA == mvItemCtbl).and.(SC7->C7_ZUSRSC == mvUsrSolic).and.(SC7->C7_CONAPRO <> "L")

				if ( _cNovoStatus == "L" )
					RecLock("SC7",.f.)
					SC7->C7_CONAPRO := _cNovoStatus
					SC7->C7_ZNIVAPR := _cNivAlUsr
					SC7->C7_ZALCAPR := _cIdPerfUs
					SC7->C7_ZUSRAPR := __cUserId
					SC7->(MsUnLock())
				Else
					RecLock("SC7",.f.)
					SC7->C7_RESIDUO := "S"
					SC7->C7_ZCONTAL := _cNovoStatus
					SC7->C7_ZNIVAPR := _cNivAlUsr
					SC7->C7_ZALCAPR := _cIdPerfUs
					SC7->C7_ZUSRAPR := __cUserId
					SC7->(MsUnLock())
				EndIf

				// gera log
				U_FtGeraLog(cFilAnt, "SC7", SC7->(C7_FILIAL+C7_NUM+C7_ITEM), _cTextoNewSts +" "+ AllTrim(_cOpcPerfil), "COM", "")

			EndIf

			// proximo item
			SC7->(dbSkip())
		EndDo

		dbSelectArea("SCR")
		dbSetOrder(1)
		if	SCR->(dbSeek(xFilial("SCR")+"PC"+mvNrPedCom))
			//Gravação da tabela de aprovação de pedidos de compra padrão
			Reclock("SCR",.f.)
			if	( _cNovoStatus == "L" )
				IF	( SCR->CR_TOTAL == ( SCR->CR_VALLIB + _nVlrApr ) )
					SCR->CR_STATUS  := "03"
					SCR->CR_DATALIB := dDataBase
					SCR->CR_USERLIB := __cUserId
					SCR->CR_VALLIB  := IIF( SCR->CR_VALLIB > 0, SCR->CR_VALLIB + _nVlrApr, _nVlrApr )
				Else
					SCR->CR_VALLIB  := IIF( SCR->CR_VALLIB > 0, SCR->CR_VALLIB + _nVlrApr, _nVlrApr )
				EndIf
			Else
				SCR->CR_STATUS := "04"
			EndIf
			MsUnlock()

			// gera log
			U_FtGeraLog(cFilAnt, "SCR", SCR->(CR_FILIAL+CR_TIPO+CR_NUM), _cTextoNewSts +" "+ AllTrim(_cOpcPerfil), "COM", "")

		EndIf

		// atualiza total aprovado
		_nTotAprovado := U_FTVALPC(mvCenCusto, mvItemCtbl, dDataBase, Nil, .t.)

		// atualiza o saldo disponivel
		_nSaldoDisp := _nVlrLimAlc - _nTotAprovado

		// atualiza totais
		if	( _cNovoStatus == "L" )
			///_nSaldoDisp   := U_FTCOM08A(__cUserId, _cNivAlUsr, "S", mvCenCusto, mvItemCtbl, dDataBase)
			_nTotPendente := _nTotPendente - _nVlrApr

		Else
			//Observação de recusa do pedido de compra
			_cObsRec := sfObseRec(mvNrPedCom, mvCenCusto, mvItemCtbl, mvUsrSolic, _nVlrApr, "R")
		EndIf

		// envia email para o usuario solicitante
		U_FtMailPC(mvNrPedCom, mvCenCusto, mvItemCtbl, mvUsrSolic, _cObsRec)

		// quando for recusado, envia email para o suprimentos
		If (_cNovoStatus == "X")
			U_FtMailPC(mvNrPedCom, mvCenCusto, mvItemCtbl, mvUsrSolic, _cObsRec)
		EndIf

		// atualiza cor da legenda
		If (_cNovoStatus == "L")
			_oCorStsAtu := _oVerde
		ElseIf (_cNovoStatus == "X")
			_oCorStsAtu := _oPreto
		EndIf

		// encerra/confirma transacao
		EndTran()

		// libera todos os registros
		MsUnLockAll()

	EndIf

Return(_oCorStsAtu)

// ** funcao que visualiza pedido de compra
Static Function sfVisuPc(mvNrPedCom)

	// posiciona no pedido de compras
	DbSelectArea("SC7")
	SC7->(DbSetOrder(1)) // 1-C7_FILIAL, C7_NUM, C7_ITEM, C7_SEQUEN
	If MsSeek(xFilial("SC7")+mvNrPedCom)
		Mata120(NIL,NIL,NIL,2)
	EndIf

Return

//Tela de observação
Static Function sfObseRec(_cPed, mvCenCusto, mvItemCtbl, mvUsrSolic, _nVlrApr, _cStObs)

	Local _oDlgObs
	Local _cObserv 	:= ""
	Local _oFont1
	Local _cObsText := ""
	Local _cTitObs := ""
	local _cPrfObs := ""

	// valida numero do pedido
	If (Empty(_cPed))
		Alert("Nenhum pedido pendente para justificar.")
		Return(.f.)
	EndIf

	_oFont1 := TFont():New( "Arial",0,-12,,.F.,0,,400,.F.,.F.,,,,,, )

	//Verifica a Finalidade da Observação ( Recusa ou Justificativa ).
	Do Case
		Case ( _cStObs == "R" )
		_cPrfObs := "RECUSADO"
		_cTitObs := "Observação sobre Recusa da solicitação de compra"
		Case	( _cStObs == "J" )
		_cPrfObs := "JUSTIFICATIVA"
		_ctitObs := "Justificativa do Gestor sobre estouro do Limite da Alçada"
	EndCase

	// Definição da Tela
	_oDlgObs := MSDialog():New(000,000,200,600,_cTitObs,,,.F.,,,,,,.T.,,,.T. )
	// -- Botão para confirmar observação e Gerar Log
	_oBtnConf := TButton():New(005,005,"Confirmar",_oDlgObs,{|| _cObsText := sfLogObs(_cPrfObs, _cObserv,_cPed, mvCenCusto, mvItemCtbl, _nVlrApr, mvUsrSolic), _oDlgObs:End() },040,010,,,,.T.,,"",,,,.F. )
	//Campo para preenchimento das observações
	_oSayObs := TSay():New(018,005,{|| _ctitObs },_oDlgObs,,_oFont1,.F.,.F.,.F.,.T.)
	@ 028,005 GET oGetObs  VAR _cObserv MEMO SIZE 300,060 OF _oDlgObs PIXEL

	// ativa o dialogo
	_oDlgObs:Activate(,,,.T.,)

Return ( _cObsText )

//Gera log com a recusa
Static Function sfLogObs(_cPrfObs, _cObsRecu, _cPed, mvCenCusto, mvItemCtbl, _nVlrApr, mvUsrSolic)

	// seek SC7
	local _cSeekSC7
	Local _cObsText := _cPrfObs+": "
	local _nX

	// valida tamanho da justificativa
	If (Len(AllTrim(_cObsRecu)) < 10)
		Alert("Favor preencher a observação com no mínimo 10 caracteres.")
		Return("")
	EndIf

	For _nX := 1 to Min(MLCount(_cObsRecu,100),10)
		_cObsText += ALLTRIM(MemoLine(_cObsRecu,100,_nX))
	Next _nX

	// posiciona no pedido de compras
	dbSelectArea("SC7")
	SC7->(dbSetOrder(1)) // 1 - C7_FILIAL, C7_NUM, C7_ITEM, C7_SEQUEN
	SC7->(dbSeek( _cSeekSC7 := xFilial("SC7")+_cPed ))

	While SC7->( ! Eof() ).and.(SC7->(C7_FILIAL+C7_NUM) == _cSeekSC7)

		// valida centro de custo, item contabil, usuario solicitante e status
		If (SC7->C7_CC == mvCenCusto).and.(SC7->C7_ITEMCTA == mvItemCtbl).and.(SC7->C7_ZUSRSC == mvUsrSolic).and.(C7_CONAPRO <> "L")

			// gera log
			U_FtGeraLog(cFilAnt, "SC7", SC7->(C7_FILIAL+C7_NUM+C7_ITEM), _cObsText, "COM", "")

		EndIf

		// proximo item
		SC7->(dbSkip())
	EndDo

Return ( _cObsText )

// ** funcao que retorna as alçadas que poderão ser consultadas pelo usuário
Static Function sfTabZ26()
	// query
	local _cQuery
	// variavel de retorno
	local _aRetOpc := {}

	// prepara query
	_cQuery := " SELECT DISTINCT Z26_PERFID+'-'+Z26_NIVEL+' / '+Z26_SETOR AS IT_SETOR "
	// cad. alcadas
	_cQuery += " FROM "+RetSqlTab("Z26")
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z26")
	// codigo do usuario
	_cQuery += " AND Z26_CODUSU = '"+__cUserId+"' "
	// calendario
	_cQuery += " AND Z26_CALEND = '"+Subs(Dtos(dDataBase),1,4)+"' "
	// bloqueado
	_cQuery += " AND Z26_MSBLQL <> '1' "

	memowrit("c:\query\TCOMA005_sfTabZ26.txt",_cQuery)

	// atualiza variavel de retorno
	_aRetOpc := U_SqlToVet(_cQuery)

Return(_aRetOpc)

// ** funcao que retorna o email dos compradores
Static Function sfRetMailCom()
	local _cRetMail := ""
	local _cQuery

	// obs: sub-select para nomear colunar
	_cQuery := "SELECT (SELECT RTRIM(Y1_EMAIL) + '; ' "
	// cad. de compradores
	_cQuery += "FROM "+RetSqlName("SY1")+" SY1 "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SY1")+" "
	// conversor de dados
	_cQuery += "FOR XML PATH(''), TYPE).value('.[1]','VARCHAR(400)') AS IT_RETMAIL "

	// atualiza variavel de retorno
	_cRetMail := U_FtQuery(_cQuery)

Return(_cRetMail)

//atualiza os Pedidos
Static Function sfatutela()

	//atualiza a tela
	_oBrwMeus:SetArray(_aPedMeus)
	_oBrwMeus:bLine	:= { || { ;
	_aPedMeus[_oBrwMeus:nAT][ 1] ,;
	_aPedMeus[_oBrwMeus:nAT][ 2] ,;
	transform(_aPedMeus[_oBrwMeus:nAT][9],PesqPict("SC7","C7_TOTAL")) ,;
	_aPedMeus[_oBrwMeus:nAT][ 3] ,;
	_aPedMeus[_oBrwMeus:nAT][ 4] ,;
	_aPedMeus[_oBrwMeus:nAT][ 5] ,;
	_aPedMeus[_oBrwMeus:nAT][ 6] ,;
	_aPedMeus[_oBrwMeus:nAT][ 7] ,;
	_aPedMeus[_oBrwMeus:nAT][ 8] ,;
	_aPedMeus[_oBrwMeus:nAT][11] ,;
	_aPedMeus[_oBrwMeus:nAT][12] }}

	// pedidos alçadas abaixo
	_oBrwAbaixo:SetArray(_aPedAbaixo)
	_oBrwAbaixo:bLine := { || { ;
	_aPedAbaixo[_oBrwAbaixo:nAT][1] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 2] ,;
	transform(_aPedAbaixo[_oBrwAbaixo:nAT][9],PesqPict("SC7","C7_TOTAL")) ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 3] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 4] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 5] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 6] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 7] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][ 8] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][11] ,;
	_aPedAbaixo[_oBrwAbaixo:nAT][12] }}

	// pedidos alçadas acima
	_oBrwAcima:SetArray(_aPedAcima)
	_oBrwAcima:bLine := { || { ;
	_aPedAcima[_oBrwAcima:nAT][1] ,;
	_aPedAcima[_oBrwAcima:nAT][ 2] ,;
	transform(_aPedAcima[_oBrwAcima:nAT][9],PesqPict("SC7","C7_TOTAL")) ,;
	_aPedAcima[_oBrwAcima:nAT][ 3] ,;
	_aPedAcima[_oBrwAcima:nAT][ 4] ,;
	_aPedAcima[_oBrwAcima:nAT][ 5] ,;
	_aPedAcima[_oBrwAcima:nAT][ 6] ,;
	_aPedAcima[_oBrwAcima:nAT][ 7] ,;
	_aPedAcima[_oBrwAcima:nAT][ 8] ,;
	_aPedAcima[_oBrwAcima:nAT][11] ,;
	_aPedAcima[_oBrwAcima:nAT][12] }}

	// atualiza browse
	_oBrwMeus:Refresh()
	_oBrwAbaixo:Refresh()
	_oBrwAcima:Refresh()

Return

// ** funcao que retorna todos os perfis abaixo do ID informado no parametro
Static Function sfRetAbaixo(mvIdAtual)
	// variavel de controle do Loop
	local _lBusca := .t.
	// controle de ID
	local _aTmpIdPesq := {mvIdAtual}
	local _aIdPesq := {}
	local _nIdPesq
	// id selecioados
	local _aIdPrfSel := {mvIdAtual}
	// variavel de retorno
	local _cRetSqlIn := ""
	// calendario
	local _cCodCalend := SubS(DtoS(dDatabase),1,4)
	// variaveis temporarias
	local _nX
	// seek
	local _cSeekZ26

	While (_lBusca)

		// zera variaveis
		_aIdPesq    := aClone(_aTmpIdPesq)
		_aTmpIdPesq := {}

		// se nao tem itens, sai do Loop
		If (Len(_aIdPesq) == 0)
			_lBusca := .f.
			Loop
		EndIf

		// varre todos os id para pesquisa
		For _nIdPesq := 1 to Len(_aIdPesq)

			// pesquisa outros ID com o perfil superior
			dbSelectArea("Z26")
			Z26->(dbSetOrder(4)) // 4-Z26_FILIAL, Z26_CALEND, Z26_PERSUP, Z26_CODUSU
			If ! Z26->(dbSeek( _cSeekZ26 := xFilial("Z26") + _cCodCalend + _aIdPesq[_nIdPesq] ))
				_lBusca := .f.
				Loop
			EndIf

			// se encontrou, atualiza variaveis
			While Z26->( ! Eof() ).and.(Z26->(Z26_FILIAL + Z26_CALEND + Z26_PERSUP) == _cSeekZ26)
				// adiciona no vetor
				aAdd(_aIdPrfSel , Z26->Z26_PERFID)
				aAdd(_aTmpIdPesq, Z26->Z26_PERFID)
				// proximo item
				Z26->(dbSkip())
			EndDo

		Next _nIdPesq

	EndDo

	// formata array em query
	For _nX := 1 to Len(_aIdPrfSel)

		// adiciona itens do perfil
		_cRetSqlIn += _aIdPrfSel[_nX]+"|"

	Next _nX

	// converte para SQL IN
	_cRetSqlIn := FormatIn(_cRetSqlIn,"|")

Return (_cRetSqlIn)