#INCLUDE "TOTVS.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "FILEIO.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Consulta detalhada da Ordem de Serviço - WMS            !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSA023(mvNumOs)

	// dimensoes da tela
	local _aSizeDlg := MsAdvSize()

	// objetos da tela
	local _oDlg01Consulta
	local _oPnl01Botoes
	local _oBmp01Refresh
	local _oPnl01Cabec
	local _oPnl01Servi, _oPnl01Palet, _oPnl01Central, _oPnl01Compo, _oPnl01Movim
	local _oSay01CodEtq
	local _oGet01CodEtq
	local _oBtn01Fechar

	// mapa de movimentação - 999
	local _oPnl01Mapa
	local _oBtImpMapa

	// definição de abas mov
	local _aAbasMov := {}

	//Variavel For
	Local _yx

	// detalhes da legenda
	local _aDetLeg := { {"BR_AMARELO" , "Mov. Planejado" }, {"BR_AZUL", "Em Movimento"}, {"ENABLE", "Mov. Realizado"}, {"BR_PRETO", "Mov. Cancelado"} }
	// título da legenda
	local _cLegTit := "Detalhes da Movimentação"

	// mapa de movimentação - 999
	Private _oBrwMapa
	Private _aHeadMapa := {}, _aColsMapa := {}

	// botão específico para legenda
	Private _oBtn01Leg
	// exclusivo para uso na legenda
	Private cCadastro := "Consulta detalhada da Ordem de Serviço"

	// funcao que monta os dados do operador logado no sistema
	Private _aUsrInfo := U_FtWmsOpe()
	Private _lUsrAccou  := (_aUsrInfo[2]=="A")
	Private _lUsrColet	:= (_aUsrInfo[2]=="C")
	Private _lUsrSuper	:= (_aUsrInfo[2]=="S")
	Private _lUsrGeren  := (_aUsrInfo[2]=="G")
	Private _lUsrMonit  := (_aUsrInfo[2]=="M")
	Private _lUsrLider  := (_aUsrInfo[2]=="L")

	private _oGet01NrOS

	// controle de consulta unica (chamada de outras funcoes)
	private _lConsUnica := (ValType(mvNumOs)=="C")

	// nr da OS
	private _cNrOSWms := IIf(_lConsUnica, mvNumOs, CriaVar("Z06_NUMOS",.f.))

	//Serviço
	Private _cCodServ := ""
	Private _cServico := ""
	//Cliente
	Private _cCliente := ""

	//TFAA
	Private _aTFAA    := {}

	// numero da etiqueta
	private _cCodEtqPesq := CriaVar("Z11_CODETI",.f.)

	//Quantidade de Sequencia da OS
	Private _aSeqOS := {}

	// fontes utilizadas
	Private _oFnt01 := TFont():New("Tahoma",,18,,.t.)
	Private _oFnt02 := TFont():New("Tahoma",,10,,.t.)

	// estrutura de campos do browse/trb - servicos da OS
	private _aHdServicos := {}
	private _cTrServicos
	private _aStServicos := {}
	private _cAlTrbServ  := GetNextAlias()
	private _oBrwServicos

	//Estrutura para OS - Tarefas -	Inicio

	//Variaveis para tela da TAREFA  002 -> APANHA DE PRODUTOS
	//Grid - Mapa
	//Função responsavel para carregar informações sfTar02Map.
	private _aSt02Mapa  := {}
	private _aHd02Mapa  := {}
	private _cTr02Mapa
	private _cAl02Mapa  := GetNextAlias()
	private _aLe02Mapa  := {}
	private _oBr02Mapa
	//Grid - Aba Produto
	//Função responsavel para carregar informações sfTar02Pro.
	private _aSt02Prod    := {}
	private _aHd02Prod    := {}
	private _cTr02Prod
	private _cAl02Prod	  := GetNextAlias()
	private _oBr02Prod
	//Grid - Aba Saldo Endereço
	//Função responsavel para carregar informações sfTar02End.
	private _aSt02Ende    := {}
	private _aHd02Ende    := {}
	private _cTr02Ende
	private _cAl02Ende	  := GetNextAlias()
	private _oBr02Ende
	private _aAllPalet    := {}
	private _aAllEnder    := {}
	//Grid - Aba Coleta
	//Função responsavel para carregar informações sfTar02Col.
	private _aSt02Cole    := {}
	private _aHd02Cole    := {}
	private _cTr02Cole
	private _cAl02Cole	  := GetNextAlias()
	private _oBr02Cole
	private _aAllColet    := {}
	//Grid - Aba Movimentação
	//Função responsavel para carregar informações sfTar02Mov.
	private _aSt02Movi    := {}
	private _aHd02Movi    := {}
	private _cTr02Movi
	private _cAl02Movi    := GetNextAlias()
	private _aLe02Movi    := {}
	private _oBr02Movi

	//Variaveis para tela da TAREFA  003 -> CONFERENCIA
	//Grid - Paletes conferidos
	//Função responsavel para carregar informações sfTar03Pal.
	private _aSt03Pale    := {}
	private _aHd03Pale    := {}
	private _cTr03Pale
	private _cAl03Pale	  := GetNextAlias()
	private _oBr03Pale
	//Grid - Movimentação dos Paletes
	//Função responsavel para carregar informações sfTar03DPa                                            .
	private _aSt03DtPa    := {}
	private _aHd03DtPa    := {}
	private _cTr03DtPa
	private _cAl03DtPa	  := GetNextAlias()
	private _oBr03DtPa

	//Variaveis para tela da TAREFA  004 -> CARREGAR VEICULOS
	//Grid - Pedidos de venda
	//Função responsavel para carregar informações sfTar04ped.
	private _aSt04ped    := {}
	private _aHd04ped    := {}
	private _cTr04ped
	private _cAl04ped	 := GetNextAlias()
	private _oBr04ped
	//Grid - Paletes conferidos
	//Função responsavel para carregar informações sfTar04Pal.
	private _aSt04Pale    := {}
	private _aHd04Pale    := {}
	private _cTr04Pale
	private _cAl04Pale	  := GetNextAlias()
	private _oBr04Pale
	//Grid - Movimentação dos Paletes
	//Função responsavel para carregar informações sfTar04DPa.
	private _aSt04DtPa    := {}
	private _aHd04DtPa    := {}
	private _cTr04DtPa
	private _cAl04DtPa	  := GetNextAlias()
	private _aLe04DtPa    := {}
	private _oBr04DtPa

	//Variaveis para tela da TAREFA  007 -> MOTAR PALETE
	//Grid - Pedidos
	//Função responsavel para carregar informações sfTar07Ped.
	private _aSt07Pedi    := {}
	private _aHd07Pedi    := {}
	private _cTr07Pedi
	private _cAl07Pedi	  := GetNextAlias()
	private _oBr07Pedi
	//Grid - Paletes
	//Função responsavel para carregar informações sfTar07Pal.
	private _aSt07Pale    := {}
	private _aHd07Pale    := {}
	private _cTr07Pale
	private _cAl07Pale	  := GetNextAlias()
	private _oBr07Pale
	//Grid - Detalhes Paletes
	//Função responsavel para carregar informações sfTar07DPa.
	private _aSt07DtPa    := {}
	private _aHd07DtPa    := {}
	private _cTr07DtPa
	private _cAl07DtPa	  := GetNextAlias()
	private _oBr07DtPa

	//Variaveis para tela da TAREFA  T05 -> RETRABALHO
	//Grid - Paletes
	//Função responsavel para carregar informações sfTarT5Pal.
	private _aStT5Pale    := {}
	private _aHdT5Pale    := {}
	private _cTrT5Pale
	private _cAlT5Pale	  := GetNextAlias()
	private _oBrT5Pale
	//Grid - Detalhes Paletes
	//Função responsavel para carregar informações sfTarT5DPa.
	private _aStT5DtPa    := {}
	private _aHdT5DtPa    := {}
	private _cTrT5DtPa
	private _cAlT5DtPa	  := GetNextAlias()
	private _oBrT5DtPa

	//Variaveis para tela da TAREFA  009 -> Transferencia
	//Grid - Paletes
	//Função responsavel para carregar informações sfTar09Pal.
	private _aSt09Pale    := {}
	private _aHd09Pale    := {}
	private _cTr09Pale
	private _cAl09Pale	  := GetNextAlias()
	private _oBr09Pale
	private _aLe09Pale    := {}
	//Grid - Aba Produto
	//Função responsavel para carregar informações sfTar09Pro.
	private _aSt09Prod    := {}
	private _aHd09Prod    := {}
	private _cTr09Prod
	private _cAl09Prod	  := GetNextAlias()
	private _oBr09Prod
	//Grid - Aba Movimentação Paletes
	//Função responsavel para carregar informações sfTar09Mov.
	private _aSt09Movi    := {}
	private _aHd09Movi    := {}
	private _cTr09Movi
	private _cAl09Movi	  := GetNextAlias()
	private _oBr09Movi
	private _aLe09Movi    := {}

	//Estrutura para OS - Tarefas - Fim

	// estrutura de campos do browse/trb - etiquetas/paletes
	private _aHdEtqPalet  := {}
	private _cTrEtqPalet
	private _aStEtqPalet  := {}
	private _cAlTrbEtqPlt := GetNextAlias()
	private _oBrwEtqPalet

	// estrutura de campos do browse/trb - composicao do palete
	private _aHdCompPlt   := {}
	private _cTrCompPlt
	private _aStCompPlt   := {}
	private _cAlTrbCmpPlt := GetNextAlias()
	private _oBrwCompPlt

	// valida identificacao do produto
	private _cTpIdEtiq := ""

	// tipo de identificacao
	private _lEtqIdInt  := .F.
	private _lEtqIdEAN  := .F.
	private _lEtqIdDUN  := .F.
	private _lEtqCod128 := .F.
	private _lEtqClient := .F.

	// executa a selecao da dados a 1a vez
	sfSelDados( .t. )

	// na consulta unica, atualiza os dados
	If (_lConsUnica)
		sfVldNrOs( .F. )
	EndIf

	//Momta tela principal.
	_oDlg01Consulta := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5], cCadastro,,,.F.,,,,,,.T.,,,.T. )
	_oDlg01Consulta:lMaximized := .T.

	//Painel superior com informações da OS
	_oPnl01Cabec := TPanel():New(000,000,nil,_oDlg01Consulta,,.F.,.F.,,,00,36,.T.,.F. )
	_oPnl01Cabec:Align:= CONTROL_ALIGN_TOP

	//Botão Refresh dos dados
	_oBmp01Refresh := TBtnBmp2():New(007,100,040,040,"RELOAD",,,,{|| sfSelDados(.f.) },_oPnl01Cabec,"Refresh",,.T. )
	_oBmp01Refresh:Align := CONTROL_ALIGN_LEFT

	//Numero da OS
	_oGet01NrOS := TGet():New(005,050,{|u| If(PCount()>0,_cNrOSWms:=u,_cNrOSWms)},_oPnl01Cabec,050,012,PesqPict("Z06","Z06_NUMOS"),{|| (Vazio()) .Or. ((U_FtStrZero()) .And. (sfVldNrOs(.f.))) },,,_oFnt01,,,.T.,"",,{|| (!_lConsUnica) },.F.,.F.,,.F.,.F.,,"_cNrOSWms" ,,,,,, .T. ,"Ordem de Serviço",1,_oFnt02)

	// tipo de serviço
	_oGet02Serv := TGet():New(005,120,{|u| If(PCount()>0,_cServico:=u,_cServico)},_oPnl01Cabec,100,012,                           ,{||                                                   },,,_oFnt01,,,.T.,"",,{|| (!_lConsUnica) },.F.,.F.,,.F.,.F.,,"_cServico" ,,,,,, .T. ,"Tipo de Serviço" ,1,_oFnt02)

	// cliente
	_oGet02Clie := TGet():New(005,230,{|u| If(PCount()>0,_cCliente:=u,_cCliente)},_oPnl01Cabec,200,012,                           ,{||                                                   },,,_oFnt01,,,.T.,"",,{|| (!_lConsUnica) },.F.,.F.,,.F.,.F.,,"_cCliente" ,,,,,, .T. ,"Cliente"         ,1,_oFnt02)

	//define os dados do TFAA para mostrar no cabeçalho da tela
	_aTFAA := sfRetTFAA(mvNumOs)

	If ( !Empty(_aTFAA) )  //se existe TFAA, mostro na tela
		_cTFAA := "TFAA " + _aTFAA[1] + " - PV: " + _aTFAA[2] + " - " +  DtoC(_aTFAA[3]) + " " + _aTFAA[4] + " " + _aTFAA[5]
		_oGet03TFAA := TGet():New(005,450,{|u| If(PCount()>0, _cTFAA := u, _cTFAA)},_oPnl01Cabec,200,012,                           ,{||                                                   },,,_oFnt01,,,.T.,"",,{|| (!_lConsUnica) },.F.,.F.,,.F.,.F.,,"_cTFAA" ,,,,,, .T. ,"TFAA encontrado para esta OS!"         ,1,_oFnt02,CLR_HRED)
	Endif

	// Campo adicional para OS do tipo cancelamento de pedido, para mostrar os dados do pedido/os cancelados
	If ( !Empty(Z05->Z05_OSORIG) )  //se existe uma OS de origem, mostro na tela
		_cOrigem   := SubStr(Z06->Z06_OBS,32)
		_oGet04Ori := TGet():New(005,450,{|u| If(PCount()>0, _cOrigem := u, _cOrigem)},_oPnl01Cabec,200,012,                           ,{||                                                   },,,_oFnt01,,,.T.,"",,{|| (!_lConsUnica) },.F.,.F.,,.F.,.F.,,"_cOrigem" ,,,,,, .T. ,"Dados adicionais desta OS de cancelamento:"         ,1,_oFnt02,CLR_HRED)
	Endif

	// define o botao Sair
	_oBtn01Fechar := TBtnBmp2():New(001,001,040,040,"FINAL",,,,{|| _oDlg01Consulta:End() },_oPnl01Cabec,"Sair",,.T. )
	_oBtn01Fechar:Align := CONTROL_ALIGN_RIGHT

	// legenda
	_oBtn01Leg := TBtnBmp2():New(001,001,040,040,"COLOR",,,,{|| U_WMSA023L( cCadastro, _cLegTit, _aDetLeg ) },_oPnl01Cabec,"Legenda",,.T. )
	_oBtn01Leg:Align := CONTROL_ALIGN_LEFT
	_oBtn01Leg:Disable()

	// se na for consulta de unica ordem de serviço
	If ( ! _lConsUnica)
		// referencia
		_oSay01CodEtq := TSay():New(007,130,{||"Etq.Produto:"},_oPnl01Cabec,,_oFnt01,.F.,.F.,.F.,.T.)
		_oGet01CodEtq := TGet():New(005,180,{|u| If(PCount()>0,_cCodEtqPesq:=u,_cCodEtqPesq)},_oPnl01Cabec,060,012,PesqPict("Z11","Z11_CODETI"),{|| Vazio().or.((U_FtStrZero()).and.(sfVldNrOs(.t.))) },,,_oFnt01,,,.T.,"",,,.F.,.F.,,.F.,.F.,,"_cCodEtqPesq",,)
	EndIf

	// painel superior com os servicos
	_oPnl01Servi := TPanel():New(000,000,nil,_oDlg01Consulta,,.F.,.F.,,,060,060,.T.,.F. )
	_oPnl01Servi:Align:= CONTROL_ALIGN_TOP

	// Painel preenchendo toda a área abaixo do Painel Superior
	_oPnl01All:= tPanel():New(0,0,"",_oDlg01Consulta,,,,,,00,030)
	_oPnl01All:align:= CONTROL_ALIGN_ALLCLIENT

	//Folder Principal dinamico conforme quantidade de Sequencia das OS
	_oFlderPri      := TFolder():New( 036,004,,,_oPnl01All,,,,.T.,.F.,400,3000,)
	_oFlderPri:align:= CONTROL_ALIGN_ALLCLIENT

	For _yx := 1 To Len(_aSeqOS)
		_oFlderPri:AddItem(Alltrim(_aSeqOS[_yx,1]) + " - " + Alltrim(_aSeqOS[_yx,2]) , .T. )
	Next _yx

	//Verifica o Tipo da OS selecionada para abrir a tela especifica.
	If ( _cCodServ $ '001/002/014' )// Expedicao

		For _yx := 1 To Len(_aSeqOS)
			//TELA PARA TAREFA  002 -> APANHA DE PRODUTOS / 013-TRANSFERENCIA / T08-TRANSFERENCIA LIVRE / T09-APANHE LIVRE
			If ( Alltrim(_aSeqOS[_yx,3]) $ '002/013/T08/T09' )

				_oFWLayer02 := FWLayer():New()
				_oFWLayer02:Init( _oFlderPri:aDialogs[_yx], .F., .T. )
				_oFWLayer02:AddCollumn( 'COLESQ', 30, .T.,)    //Coluna da esquerda que ocupa 30% da Dialog
				_oFWLayer02:AddCollumn( 'COLDIR', 70, .T.,)    //Coluna da direita que ocupa 70% da Dialog
				_oPalEsq02 := _oFWLayer02:getColPanel( "COLESQ" )//Cria Painel na Coluna da Esquerda
				_oPalDir02 := _oFWLayer02:getColPanel( "COLDIR" )//Cria Painel na Coluna da Direita

				//Grid - Mapa
				_oBr02Mapa := MsSelect():New((_cAl02Mapa),,,_aHd02Mapa,,,{001,001,3000,3000},,,_oPalEsq02,,_aLe02Mapa)
				_oBr02Mapa:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				_oBr02Mapa:oBrowse:bChange := {|| sfFilTar02( (_cAl02Mapa)->ID_PALETE,(_cAl02Mapa)->Z08_PALLET, (_cAl02Mapa)->Z08_ENDORI )  }
				IIf (!_lUsrGeren,	_oBr02Mapa:oBrowse:aColumns[2]:cPicture := "**********" , Nil)  // esconde coluna do número do pallet

				//Criando Abas
				_oFlderDet      := TFolder():New( 036,004, {"Produto", "Saldo Endereço", "Coleta", "Movimentação"},{},_oPalDir02,,,,.T.,.F.,400,3000,)
				_oFlderDet:align:= CONTROL_ALIGN_ALLCLIENT

				//Grid - Aba Produto
				_oBr02Prod := MsSelect():New((_cAl02Prod),,,_aHd02Prod,,,{001,001,4000,4000},,,_oFlderDet:aDialogs[1],,)
				_oBr02Prod:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				IIf (!_lUsrGeren, _oBr02Prod:oBrowse:aColumns[1]:cPicture := "**********", Nil)  // esconde coluna da etiqueta de volume

				//Grid - Aba Saldo Endereço
				_oBr02Ende := MsSelect():New((_cAl02Ende),,,_aHd02Ende,,,{001,001,4000,4000},,,_oFlderDet:aDialogs[2],,)
				_oBr02Ende:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				IIf (!_lUsrGeren, _oBr02Ende:oBrowse:aColumns[2]:cPicture := "**********", Nil)  // esconde coluna da etiqueta de pallet

				//Grid - Aba Coleta
				_oBr02Cole := MsSelect():New((_cAl02Cole),,,_aHd02Cole,,,{001,001,4000,4000},,,_oFlderDet:aDialogs[3],,)
				_oBr02Cole:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				IIf (!_lUsrGeren, _oBr02Cole:oBrowse:aColumns[1]:cPicture := "**********",Nil)  // esconde coluna da etiqueta de pallet
				
				//Grid - Aba Movimentação
				_oBr02Movi := MsSelect():New((_cAl02Movi),,,_aHd02Movi,,,{001,001,4000,4000},,,_oFlderDet:aDialogs[4],,_aLe02Movi)
				_oBr02Movi:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

				// habilita botão de legelnda
				_oBtn01Leg:Enable()

				// exclusivo pro uso na expedição/apanhe
				If ( Alltrim(_aSeqOS[_yx,3]) <> "002" )
					_oFlderDet:aEnable(2,.F.)
					_oFlderDet:aEnable(3,.F.)
				EndIf

				//TELA PARA TAREFA  007 -> MONTAR PALETE e 003 -  CONFERENCIA EXPEDIÇÃO
			ElseIf ( Alltrim(_aSeqOS[_yx,3]) $ '003/007' )

				_oFWLayer07 := FWLayer():New()
				_oFWLayer07:Init( _oFlderPri:aDialogs[_yx], .F., .T. )
				_oFWLayer07:AddCollumn( 'COLESQ07', 30, .T.,)    //Coluna da esquerda que ocupa 30% da Dialog
				_oFWLayer07:AddCollumn( 'COLDIR07', 70, .T.,)    //Coluna da direita que ocupa 70% da Dialog
				_oPalEsq07 := _oFWLayer07:getColPanel( "COLESQ07" )//Cria Painel na Coluna da Esquerda
				_oPalDir07 := _oFWLayer07:getColPanel( "COLDIR07" )//Cria Painel na Coluna da Direita

				_oFWLEsqu := FWLayer():New()
				_oFWLEsqu:Init(_oPalEsq07, .F., .T. )
				_oFWLEsqu:addLine("LINHA0107", 	50, .T.)
				_oFWLEsqu:addLine("LINHA0207",	50, .T.)
				_oPalLinhA := _oFWLEsqu:getLinePanel ( "LINHA0107" )
				_oPalLinhB := _oFWLEsqu:getLinePanel ( "LINHA0207" )

				//Grid - Pedidos
				_oBr07Pedi := MsSelect():New((_cAl07Pedi),,,_aHd07Pedi,,,{001,001,4000,4000},,,_oPalLinhA,,{})
				_oBr07Pedi:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				_oBr07Pedi:oBrowse:bChange := {|| sfFilTar07((_cAl07Pale)->Z07_PEDIDO,(_cAl07Pale)->Z07_PALLET)  }

				//Grid - Paletes
				_oBr07Pale := MsSelect():New((_cAl07Pale),,,_aHd07Pale,,,{001,001,4000,4000},,,_oPalLinhB,,{})
				_oBr07Pale:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				_oBr07Pale:oBrowse:bChange := {|| sfFilTar07((_cAl07Pale)->Z07_PEDIDO,(_cAl07Pale)->Z07_PALLET) }
				IIf (!_lUsrGeren, _oBr07Pale:oBrowse:aColumns[1]:cPicture := "**********", Nil)  // esconde coluna da etiqueta de pallet

				//Grid - Detalhes Paletes
				_oBr07DtPa := MsSelect():New((_cAl07DtPa),,,_aHd07DtPa,,,{001,001,4000,4000},,,_oPalDir07,,{})
				_oBr07DtPa:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				IIf (!_lUsrGeren,_oBr07DtPa:oBrowse:aColumns[1]:cPicture := "**********" , Nil) // esconde coluna da etiqueta de volume origem
				IIf (!_lUsrGeren,_oBr07DtPa:oBrowse:aColumns[2]:cPicture := "**********" , Nil) // esconde coluna da etiqueta de volume destino

				//TELA PARA TAREFA  004 -> CARREGAR VEICULOS
			ElseIf ( Alltrim(_aSeqOS[_yx,3]) == '004' )

				_oFWLayer04 := FWLayer():New()
				_oFWLayer04:Init( _oFlderPri:aDialogs[_yx], .F., .T. )
				_oFWLayer04:AddCollumn( 'COLESQ04', 30, .T.,)      //Coluna da esquerda que ocupa 30% da Dialog
				_oFWLayer04:AddCollumn( 'COLDIR04', 70, .T.,)      //Coluna da direita que ocupa 70% da Dialog
				_oPalEsq04 := _oFWLayer04:getColPanel( "COLESQ04" )//Cria Painel na Coluna da Esquerda
				_oPalDir04 := _oFWLayer04:getColPanel( "COLDIR04" )//Cria Painel na Coluna da Direita

				_oFWLEsqu4 := FWLayer():New()
				_oFWLEsqu4:Init(_oPalEsq04, .F., .T. )
				_oFWLEsqu4:addLine("LINHA0104", 50, .T.)
				_oFWLEsqu4:addLine("LINHA0204",	50, .T.)
				_oPalLin4A := _oFWLEsqu4:getLinePanel ( "LINHA0104" )
				_oPalLin4B := _oFWLEsqu4:getLinePanel ( "LINHA0204" )

				//GRID PEDIDOS DE VENDA
				_oBr04ped := MsSelect():New((_cAl04ped),,,_aHd04ped,,,{001,001,4000,4000},,,_oPalLin4A,,{})
				_oBr04ped:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				_oBr04ped:oBrowse:bChange := {|| sfFilTar04((_cAl04ped)->Z07_PEDIDO,Nil) }

				//Grid - Paletes conferidos
				_oBr04Pale := MsSelect():New((_cAl04Pale),,,_aHd04Pale,,,{001,001,4000,4000},,,_oPalLin4B,,{})
				_oBr04Pale:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				_oBr04Pale:oBrowse:bChange := {|| sfFilTar04((_cAl04Pale)->Z07_PEDIDO,(_cAl04Pale)->Z07_PALLET) }
				IIf (!_lUsrGeren,_oBr04Pale:oBrowse:aColumns[1]:cPicture := "**********", Nil)    // esconde coluna da etiqueta de pallet

				//Grid - Movimentação dos Paletes
				_oBr04DtPa := MsSelect():New((_cAl04DtPa),,,_aHd04DtPa,,,{001,001,4000,4000},,,_oPalDir04,,_aLe04DtPa)
				_oBr04DtPa:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				IIf (!_lUsrGeren,_oBr04DtPa:oBrowse:aColumns[1]:cPicture := "**********", Nil)    // esconde coluna da etiqueta de volume

			EndIf

		Next _yx
	ElseIf (_cCodServ == "T05")  //Retrabalho
		For _yx := 1 To Len(_aSeqOS)

			//TELA PARA TAREFA  002 -> APANHA DE PRODUTOS
			If Alltrim(_aSeqOS[_yx,3]) == '002'
				_oFWLayer02 := FWLayer():New()
				_oFWLayer02:Init( _oFlderPri:aDialogs[_yx], .F., .T. )
				_oFWLayer02:AddCollumn( 'COLESQ', 30, .T.,)    //Coluna da esquerda que ocupa 30% da Dialog
				_oFWLayer02:AddCollumn( 'COLDIR', 70, .T.,)    //Coluna da direita que ocupa 70% da Dialog
				_oPalEsq02 := _oFWLayer02:getColPanel( "COLESQ" )//Cria Painel na Coluna da Esquerda
				_oPalDir02 := _oFWLayer02:getColPanel( "COLDIR" )//Cria Painel na Coluna da Direita

				//Grid - Mapa
				_oBr02Mapa := MsSelect():New((_cAl02Mapa),,,_aHd02Mapa,,,{001,001,3000,3000},,,_oPalEsq02,,_aLe02Mapa)
				_oBr02Mapa:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				_oBr02Mapa:oBrowse:bChange := {|| sfFilTar09("002",(_cAl02Mapa)->ID_PALETE,(_cAl02Mapa)->Z08_PALLET) }
				IIf (!_lUsrGeren,_oBr02Mapa:oBrowse:aColumns[2]:cPicture := "**********", Nil)  // esconde coluna do número do pallet

				//Criando Abas
				_oFlderDet      := TFolder():New( 036,004,{"Produto","Movimentação"},{},_oPalDir02,,,,.T.,.F.,400,3000,)
				_oFlderDet:align:= CONTROL_ALIGN_ALLCLIENT

				//Grid - Aba Produto
				_oBr02Prod := MsSelect():New((_cAl02Prod),,,_aHd02Prod,,,{001,001,4000,4000},,,_oFlderDet:aDialogs[1],,)
				_oBr02Prod:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				IIf (!_lUsrGeren,_oBr02Prod:oBrowse:aColumns[1]:cPicture := "**********", Nil)  // esconde coluna da etiqueta de volume

				//Grid - Aba Movimentação
				_oBr02Movi := MsSelect():New((_cAl02Movi),,,_aHd02Movi,,,{001,001,4000,4000},,,_oFlderDet:aDialogs[2],,_aLe02Movi)
				_oBr02Movi:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				//TELA PARA TAREFA  T05 -> RETRABALHO
			ElseIf Alltrim(_aSeqOS[_yx,3]) == 'T05'

				_oFWLayerT5 := FWLayer():New()
				_oFWLayerT5:Init( _oFlderPri:aDialogs[_yx], .F., .T. )
				_oFWLayerT5:AddCollumn( 'COLESQT5', 30, .T.,)    //Coluna da esquerda que ocupa 30% da Dialog
				_oFWLayerT5:AddCollumn( 'COLDIRT5', 70, .T.,)    //Coluna da direita que ocupa 70% da Dialog
				_oPalEsqT5 := _oFWLayerT5:getColPanel( "COLESQT5" )//Cria Painel na Coluna da Esquerda
				_oPalDirT5 := _oFWLayerT5:getColPanel( "COLDIRT5" )//Cria Painel na Coluna da Direita

				//Grid - Paletes
				_oBrT5Pale := MsSelect():New((_cAlT5Pale),,,_aHdT5Pale,,,{001,001,4000,4000},,,_oPalEsqT5,,{})
				_oBrT5Pale:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				_oBrT5Pale:oBrowse:bChange := {|| sfFilTarT5((_cAlT5Pale)->Z07_PALLET) }
				IIf (!_lUsrGeren,_oBrT5Pale:oBrowse:aColumns[1]:cPicture := "**********" , Nil) // esconde coluna da etiqueta de pallet

				//Grid - Detalhes Paletes
				_oBrT5DtPa := MsSelect():New((_cAlT5DtPa),,,_aHdT5DtPa,,,{001,001,4000,4000},,,_oPalDirT5,,{})
				_oBrT5DtPa:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				IIf (!_lUsrGeren,_oBrT5DtPa:oBrowse:aColumns[1]:cPicture := "**********" , Nil) // esconde coluna da etiqueta de volume
				IIf (!_lUsrGeren,_oBrT5DtPa:oBrowse:aColumns[2]:cPicture := "**********" , Nil) // esconde coluna da etiqueta de volume

				//TELA PARA TAREFA  009 -> ENDERECAMENTO
			ElseIf Alltrim(_aSeqOS[_yx,3]) == '009'

				_oFWLayer09 := FWLayer():New()
				_oFWLayer09:Init( _oFlderPri:aDialogs[_yx], .F., .T. )
				_oFWLayer09:AddCollumn( 'COLESQ09', 30, .T.,)    //Coluna da esquerda que ocupa 30% da Dialog
				_oFWLayer09:AddCollumn( 'COLDIR09', 70, .T.,)    //Coluna da direita que ocupa 70% da Dialog
				_oPalEsq09 := _oFWLayer09:getColPanel( "COLESQ09" )//Cria Painel na Coluna da Esquerda
				_oPalDir09 := _oFWLayer09:getColPanel( "COLDIR09" )//Cria Painel na Coluna da Direita

				//Grid - Palete
				_oBr09Pale := MsSelect():New((_cAl09Pale),,,_aHd09Pale,,,{001,001,3000,3000},,,_oPalEsq09,,_aLe09Pale)
				_oBr09Pale:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				_oBr09Pale:oBrowse:bChange := {|| sfFilTar09("009",(_cAl09Pale)->ID_PALETE,(_cAl09Pale)->Z08_PALLET) }

				//Criando Abas
				_oFolderD9      := TFolder():New( 036,004,{"Produto","Movimentação"},{},_oPalDir09,,,,.T.,.F.,400,3000,)
				_oFolderD9:align:= CONTROL_ALIGN_ALLCLIENT

				//Grid - Aba Produto
				_oBr09Prod := MsSelect():New((_cAl09Prod),,,_aHd09Prod,,,{001,001,4000,4000},,,_oFolderD9:aDialogs[1],,)
				_oBr09Prod:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				IIf (!_lUsrGeren,_oBr09Prod:oBrowse:aColumns[1]:cPicture := "**********", Nil)  // esconde coluna da etiqueta de produto

				//Grid - Aba Movimentação
				_oBr09Movi := MsSelect():New((_cAl09Movi),,,_aHd09Movi,,,{001,001,4000,4000},,,_oFolderD9:aDialogs[2],,_aLe09Movi)
				_oBr09Movi:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

				// habilita botão de legelnda
				_oBtn01Leg:Enable()
			EndIf
		Next _yx
	ElseIf ( _cCodServ == "003") .OR. ( _cCodServ == "T03")  .OR. ( _cCodServ == "015")  //003 - Recebimento ** T03 - cancelamento de pedidos ** 015 - pre-recebimento sem doc
		For _yx := 1 To Len(_aSeqOS)
			If Alltrim(_aSeqOS[_yx,3]) $ '003_014'
				_oFWLayer03 := FWLayer():New()
				_oFWLayer03:Init( _oFlderPri:aDialogs[_yx], .F., .T. )
				_oFWLayer03:AddCollumn( 'COLESQ03', 30, .T.,)    //Coluna da esquerda que ocupa 30% da Dialog
				_oFWLayer03:AddCollumn( 'COLDIR03', 70, .T.,)    //Coluna da direita que ocupa 70% da Dialog
				_oPalEsq03 := _oFWLayer03:getColPanel( "COLESQ03" )//Cria Painel na Coluna da Esquerda
				_oPalDir03 := _oFWLayer03:getColPanel( "COLDIR03" )//Cria Painel na Coluna da Direita

				//Grid - Paletes
				_oBr03Pale := MsSelect():New((_cAl03Pale),,,_aHd03Pale,,,{001,001,4000,4000},,,_oPalEsq03,,{})
				_oBr03Pale:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				_oBr03Pale:oBrowse:bChange := {|| sfFilTar03((_cAl03Pale)->Z07_PALLET) }
				IIf (!_lUsrGeren,_oBr03Pale:oBrowse:aColumns[1]:cPicture := "**********", Nil)  // esconde coluna da etiqueta de pallet

				//Grid - Detalhes Paletes
				_oBr03DtPa := MsSelect():New((_cAl03DtPa),,,_aHd03DtPa,,,{001,001,4000,4000},,,_oPalDir03,,{})
				_oBr03DtPa:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				IIf (!_lUsrGeren,_oBr03DtPa:oBrowse:aColumns[1]:cPicture := "**********", Nil)  // esconde coluna da etiqueta de pallet

			ElseIf Alltrim(_aSeqOS[_yx,3]) == '009'
				_oFWLayer09:= FWLayer():New()
				_oFWLayer09:Init( _oFlderPri:aDialogs[_yx], .F., .T. )
				_oFWLayer09:AddCollumn( 'COLESQ09', 30, .T.,)    //Coluna da esquerda que ocupa 30% da Dialog
				_oFWLayer09:AddCollumn( 'COLDIR09', 70, .T.,)    //Coluna da direita que ocupa 70% da Dialog
				_oPalEsq09 := _oFWLayer09:getColPanel( "COLESQ09" )//Cria Painel na Coluna da Esquerda
				_oPalDir09 := _oFWLayer09:getColPanel( "COLDIR09" )//Cria Painel na Coluna da Direita

				//Grid - Palete
				_oBr09Pale := MsSelect():New((_cAl09Pale),,,_aHd09Pale,,,{001,001,3000,3000},,,_oPalEsq09,,_aLe09Pale)
				_oBr09Pale:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				_oBr09Pale:oBrowse:bChange := {|| sfFilTar09("009",(_cAl09Pale)->ID_PALETE,(_cAl09Pale)->Z08_PALLET) }

				//Criando Abas
				_oFolderD9 := TFolder():New( 036,004,{"Produto","Movimentação"},{},_oPalDir09,,,,.T.,.F.,400,3000,)
				_oFolderD9:align:= CONTROL_ALIGN_ALLCLIENT

				//Grid - Aba Produto
				_oBr09Prod := MsSelect():New((_cAl09Prod),,,_aHd09Prod,,,{001,001,4000,4000},,,_oFolderD9:aDialogs[1],,)
				_oBr09Prod:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
				IIf (!_lUsrGeren,_oBr09Prod:oBrowse:aColumns[2]:cPicture := "**********", Nil)  // esconde coluna da etiqueta de produto

				//Grid - Aba Movimentação
				_oBr09Movi := MsSelect():New((_cAl09Movi),,,_aHd09Movi,,,{001,001,4000,4000},,,_oFolderD9:aDialogs[2],,_aLe09Movi)
				_oBr09Movi:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

				// habilita botão de legelnda
				_oBtn01Leg:Enable()
			EndIf
		Next _yx
	EndIf

	/// *** DADOS ESPECÍFICOS PARA MAPA DE MOVIMENTAÇÂO - INICIO *** ///

	// inclui mais um folder pro mapa
	_oFlderPri:AddItem(" 999 - Mapa de Movimentação " , .T. )

	// panel do mapa de movimentação
	_oPnl01Mapa := TPanel():New(000,000,nil,_oFlderPri:aDialogs[Len(_oFlderPri:aDialogs)],,.F.,.F.,,,00,20,.T.,.F. )
	_oPnl01Mapa:Align:= CONTROL_ALIGN_TOP

	// posiciona na Z05 para pegar a carga
	dbSelectArea("Z05")
	Z05->( dbSetOrder(1) ) // Z05_FILIAL, Z05_NUMOS, R_E_C_N_O_, D_E_L_E_T_
	Z05->( dbSeek( xFilial("Z05") + _cNrOSWms ) )

	// somente para OS de saída
	If ( Z05->Z05_TPOPER == "S" )
		// botão para impressão do mapa
		_oBtImpMapa := TBtnBmp2():New(007,100,040,040,"IMPRESSAO",,,,{|| U_TWMSA019( Z05->Z05_CARGA, Z05->Z05_ONDSEP, Nil ) },_oPnl01Mapa,"Ver/Imprimir Mapa",,.T. )
		_oBtImpMapa:Align := CONTROL_ALIGN_LEFT
	EndIf

	// função que retorna acols e aheader do newgetdados
	sfRetMapa( .T. )

	// browse com os detalhes da consulta
	_oBrwMapa := MsNewGetDados():New(000,000,600,600,Nil,'AllwaysTrue()','AllwaysTrue()','',,1,Len(_aColsMapa),'AllwaysTrue()','','AllwaysTrue()',_oFlderPri:aDialogs[Len(_oFlderPri:aDialogs)],_aHeadMapa,_aColsMapa)
	_oBrwMapa:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	/// *** DADOS ESPECÍFICOS PARA MAPA DE MOVIMENTAÇÂO - FIM *** ///

	// browse os servicos da OS
	_oBrwServicos                 := MsSelect():New((_cAlTrbServ),,,_aHdServicos,,,{001,001,400,1000},,,_oPnl01Servi)
	_oBrwServicos:oBrowse:Align   := CONTROL_ALIGN_ALLCLIENT
	_oBrwServicos:oBrowse:bChange := {|| sfTrocaFol(Val((_cAlTrbServ)->Z06_SEQOS)) }
	// ativa a tela
	ACTIVATE MSDIALOG _oDlg01Consulta CENTERED

	// apaga tabelas temporarias criadas para a rotina
	SfApagaTab()

Return

// ** funcao para filtrar informações da TELA de APANHA DE PRODUTOS
Static Function sfFilTar02(mvIdPalete, mvEtqPalet, mvEndOri)

	Default mvIdPalete := ""
	Default mvEtqPalet := ""

	// Filtra - Grid - Aba Produto
	(_cAl02Prod)->(dbSelectArea(_cAl02Prod))
	(_cAl02Prod)->(DbGoTop())
	//Caso o arquivo temporário fique em branco desabilita a ABA para visualização
	//Também evita errorlog ao utilizar classe FWTemporaryTable, onde o Alias, quando em branco, permanece objeto e não "char"
	//	If (_cAl02Prod)->(BOF()) .and. (_cAl02Prod)->(EOF())
	If (_cAl02Prod)->(BOF()) .and. (_cAl02Prod)->(EOF())
		_oFlderDet:aEnable(2,.F.)
	Else
		(_cAl02Prod)->(IndRegua((_cAl02Prod),(_cTr02Prod),"ID_PALETE",,(_cAl02Prod)+'->ID_PALETE == "'+ mvIdPalete + '"',"Selecionando Registros..."))
		_oFlderDet:aEnable(2,.T.)
		_oBr02Prod:oBrowse:Refresh()
	EndIf

	// deabilita os folders pra transferência
	If ( _cCodServ == '014' )
		_oFlderDet:aEnable(2,.F.)
		_oFlderDet:aEnable(3,.F.)
	EndIf

	//Apenas para Expedicao
	If _cCodServ == '001'
		// Filtra - Grid - Aba Saldo Endereço
		(_cAl02Ende)->(dbSelectArea(_cAl02Ende))
		(_cAl02Ende)->(DbGoTop())
		//Caso o arquivo temporário fique em branco desabilita a ABA para visualização
		//Também evita errorlog ao utilizar classe FWTemporaryTable, onde o Alias, quando em branco, permanece objeto e não "char"
		If (_cAl02Ende)->(BOF()) .and. (_cAl02Ende)->(EOF())
			_oFlderDet:aEnable(2,.F.)
		Else
			IndRegua((_cAl02Ende),(_cTr02Ende),"Z16_ENDATU",,(_cAl02Ende)+'->Z16_ENDATU = "' + Alltrim(mvEndOri) + '"',"Selecionando Registros...")
			_oFlderDet:aEnable(2,.T.)
			_oBr02Ende:oBrowse:Refresh()
		EndIf
	EndIf

	//Apenas para Expedicao
	If _cCodServ == '001'
		// Filtra - Grid - Aba Coleta
		(_cAl02Cole)->(dbSelectArea(_cAl02Cole))
		(_cAl02Cole)->(DbGoTop())
		//Caso o arquivo temporário fique em branco desabilita a ABA para visualização
		//Também evita errorlog ao utilizar classe FWTemporaryTable, onde o Alias, quando em branco, permanece objeto e não "char"
		If (_cAl02Cole)->(BOF()) .and. (_cAl02Cole)->(EOF())
			If (_cAl02Cole)->(BOF()) .and. (_cAl02Cole)->(EOF())
				_oFlderDet:aEnable(3,.F.)
			Else
				_oFlderDet:aEnable(3,.T.)
				_oBr02Cole:oBrowse:Refresh()
			EndIf
		Else
			IndRegua((_cAl02Cole),(_cTr02Cole),"Z16_ETQPAL",,(_cAl02Cole)+'->Z16_ETQPAL = "' + mvIdPalete + '"',"Selecionando Registros...")
			_oFlderDet:aEnable(3,.T.)
			_oBr02Cole:oBrowse:Refresh()
		EndIf
	EndIf

	// Filtra - Grid - Aba Movimentação
	//Caso o arquivo temporário fique em branco com o filtro aplicado, desabilita a ABA para visualização.
	//Apenas deixar a aba habilitado quando tiver informações para visualizar.
	(_cAl02Movi)->(dbSelectArea(_cAl02Movi))
	(_cAl02Movi)->(DbGoTop())
	If !(_cAl02Movi)->(EOF())
		(_cAl02Movi)->(IndRegua((_cAl02Movi),(_cTr02Movi),"Z17_ETQPLT",,(_cAl02Movi)+'->Z17_ETQPLT == "' + mvIdPalete + '"',"Selecionando Registros..."))
		If (_cAl02Movi)->(EOF())
			_oFlderDet:aEnable(4,.F.)
		Else
			(_cAl02Movi)->(dbSelectArea(_cAl02Movi))
			(_cAl02Movi)->(DbGoTop())
			(_cAl02Movi)->(IndRegua((_cAl02Movi),(_cTr02Movi),"Z17_ETQPLT",,(_cAl02Movi)+'->Z17_ETQPLT == "' + mvEtqPalet + '"',"Selecionando Registros..."))
			If (_cAl02Movi)->(EOF())
				_oFlderDet:aEnable(4,.F.)
			Else
				_oFlderDet:aEnable(4,.T.)
				_oBr02Movi:oBrowse:Refresh()
			EndIf
		EndIf
	Else
		_oFlderDet:aEnable(4,.F.)
	EndIf

Return

// ** funcao para filtrar informações da TELA de enderecamento
Static Function sfFilTar09(mvTar,mvIdPalete,mvEtqPalet)

	Default mvIdPalete := ""
	Default mvEtqPalet := ""
	Default mvTar      := ""

	If mvTar == "009"

		// Filtra - Grid - Aba Produto
		(_cAl09Prod)->(dbSelectArea(_cAl09Prod))
		(_cAl09Prod)->(DbGoTop())
		//Caso o arquivo temporário fique em branco desabilita a ABA para visualização
		//Também evita errorlog ao utilizar classe FWTemporaryTable, onde o Alias, quando em branco, permanece objeto e não "char"
		If (_cAl09Prod)->(BOF()) .and. (_cAl09Prod)->(EOF())
			_oFolderD9:aEnable(1,.F.)
		Else
			IndRegua((_cAl09Prod),(_cTr09Prod),"ID_PALETE",,(_cAl09Prod)+'->ID_PALETE == "'+mvIdPalete+'"',"Selecionando Registros...")
			_oFolderD9:aEnable(1,.T.)
			_oBr09Prod:oBrowse:Refresh()
		EndIf

		// Filtra - Grid - Aba Movimentação
		(_cAl09Movi)->(dbSelectArea(_cAl09Movi))
		(_cAl09Movi)->(DbGoTop())
		//Caso o arquivo temporário fique em branco desabilita a ABA para visualização
		//Também evita errorlog ao utilizar classe FWTemporaryTable, onde o Alias, quando em branco, permanece objeto e não "char"
		If (_cAl09Movi)->(BOF()) .and. (_cAl09Movi)->(EOF())
			_oFolderD9:aEnable(2,.F.)
		Else
			IndRegua((_cAl09Movi),(_cTr09Movi),"Z17_ETQPLT",,(_cAl09Movi)+'->Z17_ETQPLT == "' + mvIdPalete + '"',"Selecionando Registros...")
			_oFolderD9:aEnable(2,.T.)
			_oBr09Movi:oBrowse:Refresh()
		EndIf
	ElseIf mvTar == "002"

		// Filtra - Grid - Aba Produto
		(_cAl02Prod)->(dbSelectArea(_cAl02Prod))
		(_cAl02Prod)->(DbGoTop())
		//Caso o arquivo temporário fique em branco desabilita a ABA para visualização
		//Também evita errorlog ao utilizar classe FWTemporaryTable, onde o Alias, quando em branco, permanece objeto e não "char"
		If (_cAl02Prod)->(BOF()) .and. (_cAl02Prod)->(EOF())
			_oFlderDet:aEnable(1,.F.)
		Else
			IndRegua((_cAl02Prod),(_cTr02Prod),"ID_PALETE",,(_cAl02Prod)+'->ID_PALETE == "'+mvIdPalete+'"',"Selecionando Registros...")
			_oFlderDet:aEnable(1,.T.)
			_oBr02Prod:oBrowse:Refresh()
		EndIf

		// Filtra - Grid - Aba Movimentação
		(_cAl02Movi)->(dbSelectArea(_cAl02Movi))
		(_cAl02Movi)->(DbGoTop())
		//Caso o arquivo temporário fique em branco desabilita a ABA para visualização
		//Também evita errorlog ao utilizar classe FWTemporaryTable, onde o Alias, quando em branco, permanece objeto e não "char"
		If (_cAl02Movi)->(BOF()) .and. (_cAl02Movi)->(EOF())
			_oFlderDet:aEnable(2,.F.)
		Else
			IndRegua((_cAl02Movi),(_cTr02Movi),"Z17_ETQPLT",,(_cAl02Movi)+'->Z17_ETQPLT == "' + mvIdPalete + '"',"Selecionando Registros...")
			_oFlderDet:aEnable(2,.T.)
			_oBr02Movi:oBrowse:Refresh()
		EndIf

	EndIf
Return

// ** funcao para filtrar informações da TELA de MONTAR PALETE
Static Function sfFilTar07(mvPedido,mvPalete)

	// filtro por pedido e pallet
	local _cDeFilPePa := ""

	Default mvPedido := ""
	Default mvPalete := ""

	If !(Empty(mvPedido)) .And. Empty(mvPalete)

		// Filtra - Grid - Paletes
		(_cAl07Pale)->(dbSelectArea(_cAl07Pale))
		(_cAl07Pale)->(DbGoTop())
		//Cria indice somente se houver dados
		//evita errorlog ao utilizar classe FWTemporaryTable, onde o Alias, quando em branco, permanece objeto e não "char"
		If !( (_cAl07Pale)->(BOF()) .and. (_cAl07Pale)->(EOF()) )
			IndRegua((_cAl07Pale),(_cTr07Pale),"Z07_PEDIDO",,(_cAl07Pale)+'->Z07_PEDIDO == "'+mvPedido+'"',"Selecionando Registros...")
			_oBr02Prod:oBrowse:Refresh()
		EndIf
	EndIf

	If !(Empty(mvPedido)) .And. !(Empty(mvPalete))

		// Filtra - Grid - Detalhes Paletes
		(_cAl07DtPa)->(dbSelectArea(_cAl07DtPa))
		(_cAl07DtPa)->(DbGoTop())

		// definição do filtro de dois campos
		_cDeFilPePa := (_cAl07DtPa) + '->Z07_PEDIDO == "' + mvPedido + '" .AND. ' + (_cAl07DtPa) + '->Z07_PALLET == "' + mvPalete + '"'

		//Cria indice somente se houver dados
		//evita errorlog ao utilizar classe FWTemporaryTable, onde o Alias, quando em branco, permanece objeto e não "char"
		If !( (_cAl07DtPa)->(BOF()) .and. (_cAl07DtPa)->(EOF()) )
			IndRegua((_cAl07DtPa),(_cTr07DtPa),"Z07_PEDIDO+Z07_PALLET",, _cDeFilPePa,"Selecionando Registros...")
			_oBr07DtPa:oBrowse:Refresh()
		EndIf

	EndIf

Return

// ** funcao para filtrar informações
Static Function sfFilTarT5(mvPalete)

	Default mvPalete := ""

	// Filtra - Grid - Detalhes Paletes
	(_cAlT5DtPa)->(dbSelectArea(_cAlT5DtPa))
	(_cAlT5DtPa)->(DbGoTop())

	//Cria indice somente se houver dados
	//evita errorlog ao utilizar classe FWTemporaryTable, onde o Alias, quando em branco, permanece objeto e não "char"
	If !( (_cAlT5DtPa)->(BOF()) .and. (_cAlT5DtPa)->(EOF()) )
		IndRegua((_cAlT5DtPa),(_cTrT5DtPa),"Z16_ETQPAL",,(_cAlT5DtPa)+'->Z16_ETQPAL == "'+mvPalete+'"',"Selecionando Registros...")
		_oBrT5DtPa:oBrowse:Refresh()
	EndIf

Return

// ** funcao para filtrar informações
Static Function sfFilTar03(mvPalete)

	Default mvPalete := ""

	// Filtra - Grid - Detalhes Paletes
	(_cAl03DtPa)->(dbSelectArea(_cAl03DtPa))
	(_cAl03DtPa)->(DbGoTop())

	//Cria indice somente se houver dados
	//evita errorlog ao utilizar classe FWTemporaryTable, onde o Alias, quando em branco, permanece objeto e não "char"
	If !( (_cAl03DtPa)->(BOF()) .and. (_cAl03DtPa)->(EOF()) )
		IndRegua((_cAl03DtPa),(_cTr03DtPa),"Z16_ETQPAL",,(_cAl03DtPa)+'->Z16_ETQPAL == "'+mvPalete+'"',"Selecionando Registros...")
		_oBr03DtPa:oBrowse:Refresh()
	EndIf

Return


// ** funcao para filtrar informações da TELA de CARREGAR VEICULOS
Static Function sfFilTar04(mvPedido,mvPalete)

	Default mvPedido := ""
	Default mvPalete := ""

	If !(Empty(mvPedido)) .And. Empty(mvPalete)

		// Filtra - Grid - Paletes
		(_cAl04Pale)->(dbSelectArea(_cAl04Pale))
		(_cAl04Pale)->(DbGoTop())

		//Cria indice somente se houver dados
		//evita errorlog ao utilizar classe FWTemporaryTable, onde o Alias, quando em branco, permanece objeto e não "char"
		If !( (_cAl04Pale)->(BOF()) .and. (_cAl04Pale)->(EOF()) )
			IndRegua((_cAl04Pale),(_cTr04Pale),"Z07_PEDIDO",,(_cAl04Pale)+'->Z07_PEDIDO == "'+ mvPedido + '"',"Selecionando Registros...")
			_oBr04Pale:oBrowse:Refresh()
		EndIf

	EndIf

	If !(Empty(mvPedido)) .And. !(Empty(mvPalete))

		// Filtra - Grid - Detalhes Paletes
		(_cAl04DtPa)->(dbSelectArea(_cAl04DtPa))
		(_cAl04DtPa)->(DbGoTop())

		//Cria indice somente se houver dados
		//evita errorlog ao utilizar classe FWTemporaryTable, onde o Alias, quando em branco, permanece objeto e não "char"
		If !( (_cAl04DtPa)->(BOF()) .and. (_cAl04DtPa)->(EOF()) )
			IndRegua((_cAl04DtPa),(_cTr04DtPa),"Z07_PEDIDO+Z07_PALLET",,(_cAl04DtPa) + '->Z07_PEDIDO == "' + mvPedido + '" .AND. ' + (_cAl04DtPa) + '->Z07_PALLET == "' + mvPalete + '"',"Selecionando Registros...")
			_oBr04DtPa:oBrowse:Refresh()
		EndIf
	EndIf

Return


// ** funcao que realiza a troca de folder conforme usuario da um click na grid da OS
Static Function sfTrocaFol(mvSeq)

	//Variavel temporaria For
	Local _ws := 0
	Default mvSeq := 0

	For _ws := 1 To Len(_aSeqOS)
		If (Val(_aSeqOS[_ws][1]) == mvSeq)
			_oFlderPri:aEnable( Val(_aSeqOS[_ws][1]) , .T. )
			_oFlderPri:SetOption(mvSeq)
			_oFlderPri:ShowPage( mvSeq )
		Else
			_oFlderPri:aEnable( Val(_aSeqOS[_ws][1]) , .F. )
		EndIf
	Next _ws

	_oFlderPri:Refresh()

Return
// ** funcao que faz a validacao do numero da OS digitada
Static Function sfVldNrOs(mvReferen)
	// variavel de retorno
	local _lRet := .t.

	// verifica se a pesquisa eh por etiqueta
	If (mvReferen)
		// chama a pesquisa por etiqueta
		If ( ! sfPesqEtiqueta() )
			Return( .T. )
		EndIf
	Else
		// limpa a referencia
		_cCodEtqPesq := Space(Len(_cCodEtqPesq))
	EndIf

	// cabecalho da programacao
	dbSelectArea("Z05")
	Z05->(dbSetOrder(1)) // 1-Z05_FILIAL, Z05_NUMOS
	If ( ! Z05->(dbSeek( xFilial("Z05") + _cNrOSWms )))
		MsgStop("Ordem de Serviço não encontrada!")
		Return(.f.)
	EndIf

	// atualiza nome do cliente
	_cCliente := Z05->Z05_CLIENT + "/" + Z05->Z05_LOJA + " - " + Alltrim((Posicione("SA1",1,XFILIAL("SA1")+Z05->Z05_CLIENT + Z05->Z05_LOJA,"A1_NOME")))

	// valida identificacao do produto
	_cTpIdEtiq := U_FtWmsParam("WMS_PRODUTO_ETIQ_IDENT", "C", "INTERNA", .F., "", Z05->Z05_CLIENT, Z05->Z05_LOJA, Nil, Nil)

	// tipo de identificacao
	_lEtqIdInt  := (AllTrim(_cTpIdEtiq) == "INTERNA")
	_lEtqIdEAN  := (AllTrim(_cTpIdEtiq) == "EAN") .Or. (AllTrim(_cTpIdEtiq) == "EAN13")
	_lEtqIdDUN  := (AllTrim(_cTpIdEtiq) == "DUN14")
	_lEtqCod128 := (AllTrim(_cTpIdEtiq) == "CODE128")
	_lEtqClient := (AllTrim(_cTpIdEtiq) == "CLIENTE")

	// se encontrar a OS, atualiza os dados
	sfSelDados( .F. )

Return( _lRet )

// ** funcao que carrega os dados da programacao
Static Function sfSelDados(mvFirst)

	MsgRun("Atualizando informações...", "Aguarde...", {|| CursorWait(), sfServicos(mvFirst), CursorArrow() })

	// atualiza aba 999 - Mapa de Movimentação
	If ( ! mvFirst )
		// atualiza dados do mapa
		sfRetMapa( mvFirst )
	EndIf

	// Na consulta unica.
	If (_lConsUnica)
		//Verifica o Tipo da OS selecionada e carrega variaveis e TRB especificas do processo.
		If _cCodServ $ '001/002' // 001-Expedicao / 002-Carregamento
			If(mvFirst)
				_cAl02Mapa := GetNextAlias()
				_cAl02Prod := GetNextAlias()
				_cAl02Ende := GetNextAlias()
				_cAl02Cole := GetNextAlias()
				_cAl02Movi := GetNextAlias()
				_cAl04ped  := GetNextAlias()
				_cAl04Pale := GetNextAlias()
				_cAl04DtPa := GetNextAlias()
				_cAl07Pedi := GetNextAlias()
				_cAl07Pale := GetNextAlias()
				_cAl07DtPa := GetNextAlias()
				_aLe02Mapa := {{_cAl02Mapa+"->Z08_STATUS=='R'","ENABLE"  },{_cAl02Mapa+"->Z08_STATUS=='M'","BR_AZUL"},{_cAl02Mapa+"->Z08_STATUS=='P'","BR_AMARELO"}}
				_aLe02Movi := {{_cAl02Movi+"->Z17_STATUS=='C'","BR_PRETO"},{_cAl02Movi+"->Z17_STATUS=='M'","BR_AZUL"},{_cAl02Movi+"->Z17_STATUS=='R'","ENABLE"}}
				_aLe04DtPa := {{_cAl04DtPa+"->Z07_QUANT == 0 ","BR_PRETO"},{_cAl04DtPa+"->Z07_QUANT < " + _cAl04DtPa+"->Z07_QUANT" , "BR_AZUL"},{_cAl04DtPa+"->Z07_QUANT = " + _cAl04DtPa+"->Z07_QUANT","ENABLE"}}
			EndIf
			MsgRun("Atualizando informações OS de Expedicao/Interna ..", "Aguarde...", {||	CursorWait(),;
			sfTar02Map(mvFirst),;
			sfTar02Pro(mvFirst),;
			sfTar02End(mvFirst),;
			sfTar02Col(mvFirst),;
			sfTar02Mov(mvFirst),;
			sfTar07Ped(mvFirst),;
			sfTar07Pal(mvFirst),;
			sfTar07DPa(mvFirst),;
			sfTar04ped(mvFirst),;
			sfTar04Pal(mvFirst),;
			sfTar04DPa(mvFirst),;
			CursorArrow()})
		ElseIf _cCodServ == "014" // 014-Transferencia
			If(mvFirst)
				_cAl02Mapa := GetNextAlias()
				_cAl02Prod := GetNextAlias()
				_cAl02Ende := GetNextAlias()
				_cAl02Cole := GetNextAlias()
				_cAl02Movi := GetNextAlias()
				_aLe02Mapa := {{_cAl02Mapa+"->Z08_STATUS=='R'","ENABLE"  },{_cAl02Mapa+"->Z08_STATUS=='M'","BR_AZUL"},{_cAl02Mapa+"->Z08_STATUS=='P'","BR_AMARELO"}}
				_aLe02Movi := {{_cAl02Movi+"->Z17_STATUS=='C'","BR_PRETO"},{_cAl02Movi+"->Z17_STATUS=='M'","BR_AZUL"},{_cAl02Movi+"->Z17_STATUS=='R'","ENABLE"}}
			EndIf
			MsgRun("Atualizando informações OS de Expedicao/Interna ..", "Aguarde...", {||	CursorWait(),;
			sfTar02Map(mvFirst),;
			sfTar02Pro(mvFirst),;
			sfTar02End(mvFirst),;
			sfTar02Col(mvFirst),;
			sfTar02Mov(mvFirst),;
			CursorArrow()})
		ElseIf _cCodServ $ '003/T03/015'// 003-Recebimento / T03-Cancelamento de Carregamento / 015 - pré-recebimento sem documento fiscal
			If(mvFirst)
				_cAl03Pale := GetNextAlias()
				_cAl03DtPa := GetNextAlias()
				_cAl09Pale := GetNextAlias()
				_cAl09Prod := GetNextAlias()
				_cAl09Movi := GetNextAlias()
				_aLe09Pale := {{_cAl09Pale+"->Z08_STATUS=='R'","ENABLE"}  ,{_cAl09Pale+"->Z08_STATUS=='M'","BR_AZUL"},{_cAl09Pale+"->Z08_STATUS=='P'","BR_AMARELO"}}
				_aLe09Movi := {{_cAl09Movi+"->Z17_STATUS=='C'","BR_PRETO"},{_cAl09Movi+"->Z17_STATUS=='M'","BR_AZUL"},{_cAl09Movi+"->Z17_STATUS=='R'","ENABLE"}}
			EndIf

			MsgRun("Atualizando informações OS de Recebimento...", "Aguarde...", {||	CursorWait(),;
			sfTar03Pal(mvFirst),;
			sfTar03DPa(mvFirst),;
			sfTar09Pal(mvFirst),;
			sfTar09Pro(mvFirst),;
			sfTar09Mov(mvFirst),;
			CursorArrow()})
		ElseIf _cCodServ == 'T05'//Retrabalho
			If(mvFirst)
				_cAl02Mapa := GetNextAlias()
				_cAl02Prod := GetNextAlias()
				_cAl02Movi := GetNextAlias()
				_cAlT5DtPa := GetNextAlias()
				_cAlT5Pale := GetNextAlias()
				_cAl09Pale := GetNextAlias()
				_cAl09Prod := GetNextAlias()
				_cAl09Movi := GetNextAlias()
				_aLe02Mapa := {{_cAl02Mapa+"->Z08_STATUS=='R'","ENABLE"}  ,{_cAl02Mapa+"->Z08_STATUS=='M'","BR_AZUL"},{_cAl02Mapa+"->Z08_STATUS=='P'","BR_AMARELO"}}
				_aLe09Pale := {{_cAl09Pale+"->Z08_STATUS=='R'","ENABLE"}  ,{_cAl09Pale+"->Z08_STATUS=='M'","BR_AZUL"},{_cAl09Pale+"->Z08_STATUS=='P'","BR_AMARELO"}}
				_aLe02Movi := {{_cAl02Movi+"->Z17_STATUS=='C'","BR_PRETO"},{_cAl02Movi+"->Z17_STATUS=='M'","BR_AZUL"},{_cAl02Movi+"->Z17_STATUS=='R'","ENABLE"}}
				_aLe09Movi := {{_cAl09Movi+"->Z17_STATUS=='C'","BR_PRETO"},{_cAl09Movi+"->Z17_STATUS=='M'","BR_AZUL"},{_cAl09Movi+"->Z17_STATUS=='R'","ENABLE"}}
			EndIf
			MsgRun("Atualizando informações OS de Retrabalho...", "Aguarde...", {||	CursorWait(),;
			sfTar02Map(mvFirst),;
			sfTar02Pro(mvFirst),;
			sfTar02Mov(mvFirst),;
			sfTarT5Pal(mvFirst),;
			sfTarT5DPa(mvFirst),;
			sfTar09Pal(mvFirst),;
			sfTar09Pro(mvFirst),;
			sfTar09Mov(mvFirst),;
			CursorArrow()})
		EndIf
	EndIf
Return

// ** funcao que retorna os itens da ordem de servico
Static Function sfServicos(mvFirst)
	local _cQuery := ""
	local _izz    := 0
	local aRetSQL := {}

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStServicos,{"Z06_NUMOS"  ,"C", TamSx3("Z06_NUMOS")[1],0})
		aAdd(_aStServicos,{"Z06_SEQOS"  ,"C", TamSx3("Z06_SEQOS")[1],0})		; aAdd(_aHdServicos,{"Z06_SEQOS" ,"","Seq.OS"  ,PesqPict("Z06","Z06_SEQOS")})
		aAdd(_aStServicos,{"OS_CODSERV" ,"C", TamSx3("X5_CHAVE")[1],0})
		aAdd(_aStServicos,{"OS_SERVICO" ,"C", TamSx3("X5_DESCRI")[1],0})
		aAdd(_aStServicos,{"OS_TAREFA"  ,"C", TamSx3("X5_DESCRI")[1],0})		; aAdd(_aHdServicos,{"OS_TAREFA" ,"","Tarefa"  ,"@!"})
		aAdd(_aStServicos,{"Z06_STATUS"  ,"C", TamSx3("Z06_STATUS")[1],0})		; aAdd(_aHdServicos,{"Z06_STATUS" ,"","Status"  ,"@!"})
		aAdd(_aStServicos,{"OS_EMISSAO" ,"C", 16,0})							; aAdd(_aHdServicos,{"OS_EMISSAO","","Emissão" ,""})
		aAdd(_aStServicos,{"OS_INICIO"  ,"C", 16,0})							; aAdd(_aHdServicos,{"OS_INICIO" ,"","Início da Operação"  ,""})
		aAdd(_aStServicos,{"OS_FINALIZ" ,"C", 16,0})							; aAdd(_aHdServicos,{"OS_FINALIZ","","Fim da Operação",""})

		// fecha alias do TRB
		If (Select(_cAlTrbServ)<>0)
			(_cAlTrbServ)->(dbSelectArea(_cAlTrbServ))
			(_cAlTrbServ)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTrServicos := FWTemporaryTable():New( _cAlTrbServ )
		_cTrServicos:SetFields( _aStServicos )
		_cTrServicos:Create()

	EndIf

	// limpa o conteudo do TRB
	(_cAlTrbServ)->(dbSelectArea(_cAlTrbServ))
	(_cAlTrbServ)->(__dbZap())

	// busca itens da OS
	_cQuery := " SELECT Z06_NUMOS, Z06_SEQOS, SX5SRV.X5_DESCRI OS_SERVICO, SX5TRF.X5_DESCRI OS_TAREFA, "
	// data de emissao da OS
	_cQuery += " CASE WHEN Z06_DTEMIS = '' THEN '' ELSE CONVERT(VARCHAR(10),CAST(Z06_DTEMIS AS DATETIME),103)+' '+Z06_HREMIS END OS_EMISSAO, "
	// data de inicioo da OS
	_cQuery += " CASE WHEN Z06_DTINIC = '' THEN '' ELSE CONVERT(VARCHAR(10),CAST(Z06_DTINIC AS DATETIME),103)+' '+Z06_HRINIC END OS_INICIO, "
	// data de finalizacao da OS
	_cQuery += " CASE WHEN Z06_DTFIM  = '' THEN '' ELSE CONVERT(VARCHAR(10),CAST(Z06_DTFIM  AS DATETIME),103)+' '+Z06_HRFIM  END OS_FINALIZ, "
	_cQuery += " SX5TRF.X5_CHAVE,SX5SRV.X5_CHAVE OS_CODSER, Z06_STATUS "
	// itens da OS
	_cQuery += " FROM " + RetSqlTab("Z06") + " (nolock) "
	// desc. servico - tab L4
	_cQuery += " INNER JOIN " + RetSqlName("SX5") + " SX5SRV (nolock) ON SX5SRV.X5_FILIAL = '" + xFilial("SX5") + "' AND SX5SRV.D_E_L_E_T_ = ' ' AND SX5SRV.X5_TABELA = 'L4' AND SX5SRV.X5_CHAVE = Z06_SERVIC "
	// desc. tafefa - tab L4
	_cQuery += " INNER JOIN " + RetSqlName("SX5") + " SX5TRF (nolock) ON SX5TRF.X5_FILIAL = '" + xFilial("SX5") + "' AND SX5TRF.D_E_L_E_T_ = ' ' AND SX5TRF.X5_TABELA = 'L2' AND SX5TRF.X5_CHAVE = Z06_TAREFA "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z06")
	// filtra numero da os
	_cQuery += " AND Z06_NUMOS = '" + _cNrOSWms + "' "
	// ordem dos dados
	_cQuery += " ORDER BY Z06_NUMOS, Z06_SEQOS "

	memowrit("c:\query\twmsa023_sfServicos.txt",_cQuery)

	//Pega as Sequencias da OS e salva em uma variavel para saber a quantidade de folder a ser utilizada
	aRetSQL := U_SqlToVet(_cQuery)
	_aSeqOS := {}
	For _izz := 1 To Len(aRetSQL)
		Aadd(_aSeqOS,{aRetSQL[_izz][2],aRetSQL[_izz][4],aRetSQL[_izz][8]})
	Next _izz

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aStServicos,(_cAlTrbServ))

	// abre o arquivo de trabalho
	(_cAlTrbServ)->(dbSelectArea(_cAlTrbServ))
	(_cAlTrbServ)->(dbGoTop())

	_cCodServ := AllTrim(aRetSQL[1][9])
	_cServico := (_cAlTrbServ)->OS_SERVICO

	// refresh do browse
	If (_oBrwServicos <> nil)
		_oBrwServicos:oBrowse:Refresh()
	EndIf

Return

// ** funcao que retorna os itens da ordem de servico
Static Function sfTar02Map(mvFirst)
	local _cQuery
	local _cSeqOS := ""
	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		//Mapa De Separação
		aAdd(_aSt02Mapa,{"Z08_STATUS" ,"C", TamSx3("Z08_STATUS")[1],0})
		aAdd(_aSt02Mapa,{"ID_PALETE"  ,"C", TamSx3("Z08_PALLET")[1],0})			; aAdd(_aHd02Mapa,{"ID_PALETE" ,"","Palete"  ,""})
		aAdd(_aSt02Mapa,{"Z08_ENDORI" ,"C", TamSx3("Z08_ENDORI")[1],0})			; aAdd(_aHd02Mapa,{"Z08_ENDORI","","Origem"  ,""})
		aAdd(_aSt02Mapa,{"Z08_ENDDES" ,"C", TamSx3("Z08_ENDDES")[1],0})			; aAdd(_aHd02Mapa,{"Z08_ENDDES","","Destino" ,""})
		aAdd(_aSt02Mapa,{"Z08_PALLET" ,"C", TamSx3("Z08_PALLET")[1],0})
		aAdd(_aSt02Mapa,{"Z08_NEWPLT" ,"C", TamSx3("Z08_NEWPLT")[1],0})

		// fecha alias do TRB
		If Select(_cAl02Mapa) <> 0
			(_cAl02Mapa)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr02Mapa := FWTemporaryTable():New( _cAl02Mapa )
		_cTr02Mapa:SetFields( _aSt02Mapa )
		_cTr02Mapa:Create()

	EndIf
	(_cAl02Mapa)->(dbSelectArea(_cAl02Mapa))
	(_cAl02Mapa)->(__dbZap())

	// prepara query
	_cQuery := " SELECT DISTINCT(CASE WHEN Z08_NEWPLT <> '' THEN Z08_NEWPLT ELSE Z08_PALLET END) ID_PALETE, MAX(Z08_ENDORI) Z08_ENDORI, MAX(Z08_ENDDES) Z08_ENDDES, Z08_PALLET, Z08_NEWPLT,Z08_STATUS "
	// itens do mapa de armazenagem / expedicao
	_cQuery += " FROM " + RetSqlTab("Z08") + " (nolock) "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z08")
	// filtra numero da os
	_cQuery += " AND Z08_NUMOS = '" + _cNrOSWms + "' "

	//Busca Seguencia de OS para a Tarefa 002 -> APANHA DE PRODUTOS / 013-TRANSFERENCIA / T08-TRANSFERENCIA LIVRE / T09-APANHE LIVRE
	_cSeqOS := sfBusSecOS(_cNrOSWms,"002/013/T08/T09")

	_cQuery += " AND Z08_SEQOS = '" + _cSeqOS + "' "
	// agrupa os dados
	_cQuery += " GROUP BY Z08_PALLET, Z08_NEWPLT, Z08_STATUS "
	// ordem dos dados
	_cQuery += " ORDER BY Z08_PALLET"

	memowrit("c:\query\twmsa023_sfTar02Map.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aSt02Mapa,(_cAl02Mapa))

	// abre o arquivo de trabalho
	(_cAl02Mapa)->(dbSelectArea(_cAl02Mapa))
	(_cAl02Mapa)->(dbGoTop())

	// refresh do browse
	If (_oBr02Mapa <> nil)
		_oBr02Mapa:oBrowse:Refresh()
	EndIf

Return()

// ** funcao que retorna os produtos do Palet
Static Function sfTar02Pro(mvFirst)
	local _cSeqOS := ""
	local _cQuery
	local _izz    := 0
	local aRetSQL := {}

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		//Mapa De Separação
		aAdd(_aSt02Prod,{"ID_PALETE"  ,"C", TamSx3("Z08_PALLET")[1],0})					   /*; aAdd(_aHd02Prod,{"ID_PALETE" ,"","Palet"     ,""})*/
		aAdd(_aSt02Prod,{"IT_ETQ"     ,"C", TamSx3("Z16_ETQVOL")[1],0})				       ; aAdd(_aHd02Prod,{"IT_ETQ"     ,"","Etiqueta"     ,""})
		aAdd(_aSt02Prod,{"Z08_PRODUT" ,"C", TamSx3("Z08_PRODUT")[1],0})					   ; aAdd(_aHd02Prod,{"Z08_PRODUT" ,"","Produto"   ,""})
		aAdd(_aSt02Prod,{"B1_DESC"    ,"C", TamSx3("B1_DESC")[1],0})					   ; aAdd(_aHd02Prod,{"B1_DESC"    ,"","Descrição"  ,PesqPict("SB1","B1_DESC")})
		aAdd(_aSt02Prod,{"Z08_QUANT"  ,"N", TamSx3("Z08_QUANT")[1],TamSx3("Z08_QUANT")[2]}); aAdd(_aHd02Prod,{"Z08_QUANT"  ,"","Quantidade",""})
		aAdd(_aSt02Prod,{"Z08_PALLET" ,"C", TamSx3("Z08_PALLET")[1],0})
		aAdd(_aSt02Prod,{"Z08_NEWPLT" ,"C", TamSx3("Z08_NEWPLT")[1],0})

		// fecha alias do TRB
		If Select(_cAl02Prod) <> 0
			(_cAl02Prod)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr02Prod := FWTemporaryTable():New( _cAl02Prod )
		_cTr02Prod:SetFields( _aSt02Prod )
		_cTr02Prod:Create()
	EndIf

	(_cAl02Prod)->(dbSelectArea(_cAl02Prod))
	(_cAl02Prod)->(__dbZap())

	// prepara query
	_cQuery := "SELECT CASE WHEN Z08_NEWPLT <> '' THEN Z08_NEWPLT ELSE Z08_PALLET END ID_PALETE,Z08_PRODUT,B1_DESC,Z08_QUANT, Z08_PALLET, Z08_NEWPLT, CASE WHEN Z16_ETQPRD = '' THEN Z16_ETQVOL ELSE Z16_ETQPRD END IT_ETQ, Z08_ENDORI"
	// itens do mapa de armazenagem / expedicao
	_cQuery += " FROM " + RetSqlTab("Z08") + " (nolock) "
	// cad. produtos
	_cQuery += " INNER JOIN " + RetSqlTab("SB1") + " (nolock) ON " + RetSqlCond("SB1") + " AND B1_COD = Z08_PRODUT "
	_cQuery += " INNER JOIN " + RetSqlTab("Z16") + " (nolock) ON " + RetSqlCond("Z16") + " AND Z16_CODPRO = Z08_PRODUT AND (CASE WHEN Z08_NEWPLT <> '' THEN Z08_NEWPLT ELSE Z08_PALLET END) = Z16_ETQPAL "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z08")
	// filtra numero da os
	_cQuery += " AND Z08_NUMOS = '" + _cNrOSWms + "' "

	//Busca Seguencia de OS para a Tarefa 002 -> APANHA DE PRODUTOS / 013-TRANSFERENCIA / T08-TRANSFERENCIA LIVRE / T09-APANHE LIVRE
	_cSeqOS := sfBusSecOS(_cNrOSWms, "002/013/T08/T09")

	// sequencia da OS
	_cQuery += " AND Z08_SEQOS = '" + _cSeqOS + "' "
	// ordem dos dados
	_cQuery += " ORDER BY Z08_PALLET, Z16_ETQVOL, Z08_PRODUT"

	memowrit("c:\query\twmsa023_sfTar02Pro.txt",_cQuery)

	aRetSQL    := U_SqlToVet(_cQuery)
	_aAllPalet := {}
	_aAllColet := {}
	_aAllEnder := {}

	For _izz := 1 To Len(aRetSQL)
		If !(Empty(aRetSQL[_izz,5]))
			IIf( Ascan(_aAllPalet, "'"+Alltrim(aRetSQL[_izz,5])+"'") == 0, Aadd(_aAllPalet, "'" + Alltrim(aRetSQL[_izz,5]) + "'"), Nil )
			IIf( Ascan(_aAllColet, "'"+Alltrim(aRetSQL[_izz,1])+"'") == 0, Aadd(_aAllColet, "'" + Alltrim(aRetSQL[_izz,1]) + "'"), Nil )
			IIf( Ascan(_aAllEnder, "'"+Alltrim(aRetSQL[_izz,8])+"'") == 0, Aadd(_aAllEnder, "'" + Alltrim(aRetSQL[_izz,8]) + "'"), Nil )
		EndIf
	Next _izz

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aSt02Prod,(_cAl02Prod))

	// abre o arquivo de trabalho
	(_cAl02Prod)->(dbSelectArea(_cAl02Prod))
	(_cAl02Prod)->(dbGoTop())

	// refresh do browse
	If (_oBr02Prod <> nil)
		_oBr02Prod:oBrowse:Refresh()
	EndIf

Return()

// ** funcao que retorna saldo dos produtos por Palet.
Static Function sfTar02End(mvFirst)
	local _cQuery
	Local _nX 

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		//Mapa De Separação
		aAdd(_aSt02Ende,{"Z16_ENDATU" ,"C", TamSx3("Z16_ENDATU")[1],0})					   ; aAdd(_aHd02Ende,{"Z16_ENDATU","","Endereço"  ,""})
		aAdd(_aSt02Ende,{"Z16_ETQPAL" ,"C", TamSx3("Z16_ETQPAL")[1],0})					   ; aAdd(_aHd02Ende,{"Z16_ETQPAL","","Pallet"     ,""})
		aAdd(_aSt02Ende,{"Z16_CODPRO" ,"C", TamSx3("Z16_CODPRO")[1],0})					   ; aAdd(_aHd02Ende,{"Z16_CODPRO","","Produto"   ,""})
		aAdd(_aSt02Ende,{"B1_DESC"    ,"C", TamSx3("B1_DESC")[1],0})					   ; aAdd(_aHd02Ende,{"B1_DESC"   ,"","Descrição" ,PesqPict("SB1","B1_DESC")})
		aAdd(_aSt02Ende,{"Z16_SALDO"  ,"N", TamSx3("Z16_SALDO")[1],TamSx3("Z16_SALDO")[2]}); aAdd(_aHd02Ende,{"Z16_SALDO" ,"","Saldo",""})

		// fecha alias do TRB
		If Select(_cAl02Ende) <> 0
			(_cAl02Ende)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr02Ende := FWTemporaryTable():New( _cAl02Ende )
		_cTr02Ende:SetFields( _aSt02Ende )
		_cTr02Ende:Create()


	EndIf

	(_cAl02Ende)->(dbSelectArea(_cAl02Ende))
	(_cAl02Ende)->(__DbZap())

	// prepara query
	_cQuery := " SELECT Z16_ETQPAL, Z16_CODPRO, B1_DESC, SUM(Z16_SALDO) Z16_SALDO, Z16_ENDATU "
	// composicao do palete
	_cQuery += " FROM " + RetSqlTab("Z16") + " (nolock) "
	// cad. produtos
	_cQuery += " INNER JOIN " + RetSqlTab("SB1") + " (nolock) ON " + RetSqlCond("SB1") + " AND B1_COD = Z16_CODPRO "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z16")
	// somente com saldo
	_cQuery += " AND Z16_SALDO != 0 "

	//Filtro por um ou mais Paletes
	If !( Len(_aAllEnder) == 0 )
		//		_cQuery += " AND Z16_ENDATU IN (" + _cAllEnder + ") "
		_cQuery += " AND Z16_ENDATU IN ("
		For _nX := 1 to Len(_aAllEnder)
			_cQuery += _aAllEnder[_nX]
			If _nX != Len(_aAllEnder)  // não é o último elemento, separa por vírgula
				_cQuery += ","
			Else  // é o último elemento, fecha a expressão IN do SQL
				_cQuery += ")"
			EndIf
		Next _nX
	Else
		_cQuery += " AND 1 = 0 " // quando nao ha paletes / enderecos para filtrar
	EndIf

	// agrupa dados
	_cQuery += " GROUP BY Z16_ETQPAL, Z16_CODPRO, B1_DESC, Z16_ENDATU "
	// ordem dos dados
	_cQuery += " ORDER BY Z16_ETQPAL, Z16_CODPRO"

	memowrit("c:\query\twmsa023_sfTar02End.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aSt02Ende,(_cAl02Ende))

	// abre o arquivo de trabalho
	(_cAl02Ende)->(dbSelectArea(_cAl02Ende))
	(_cAl02Ende)->(dbGoTop())

	// refresh do browse
	If (_oBr02Ende <> nil)
		_oBr02Ende:oBrowse:Refresh()
	EndIf

Return()

// ** Função que retorna as coletas da OS
Static Function sfTar02Col(mvFirst)

	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		//Mapa De Separação
		aAdd(_aSt02Cole,{"Z16_ETQPAL"  ,"C", TamSx3("Z16_ETQPAL")[1],0})
		aAdd(_aSt02Cole,{"IT_ETQ"      ,"C", TamSx3("Z16_ETQVOL")[1],0})					;aAdd(_aHd02Cole,{"IT_ETQ"    ,"","Etiqueta",""})
		aAdd(_aSt02Cole,{"Z16_CODPRO"  ,"C", TamSx3("Z08_PRODUT")[1],0})					;aAdd(_aHd02Cole,{"Z16_CODPRO","","Produto",""})
		aAdd(_aSt02Cole,{"B1_DESC"     ,"C", TamSx3("B1_DESC")[1],0})						;aAdd(_aHd02Cole,{"B1_DESC"   ,"","Descrição"  ,PesqPict("SB1","B1_DESC")})
		aAdd(_aSt02Cole,{"Z16_QUANT"   ,"N", TamSx3("Z16_QUANT")[1],TamSx3("Z16_QUANT")[2]});aAdd(_aHd02Cole,{"Z16_QUANT" ,"","Quantidade",""})

		// fecha alias do TRB
		If Select(_cAl02Cole) <> 0
			(_cAl02Cole)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr02Cole := FWTemporaryTable():New( _cAl02Cole )
		_cTr02Cole:SetFields( _aSt02Cole )
		_cTr02Cole:Create()

	EndIf
	(_cAl02Cole)->(dbSelectArea(_cAl02Cole))
	(_cAl02Cole)->(__DbZap())

	// se nao tem paletes, nao executa select
	If (Len(_aAllColet) == 0)
		Return()
	EndIF

	// busca itens da OS
	_cQuery := " SELECT Z16_ETQPAL,CASE WHEN Z16_ETQPRD = '' THEN Z16_ETQVOL ELSE Z16_ETQPRD END IT_ETQ,Z16_CODPRO,B1_DESC,Z16_QUANT  "
	// composicao do palete
	_cQuery += " FROM " + RetSqlTab("Z16") + " (nolock) "
	// cad. produtos
	_cQuery += " INNER JOIN " + RetSqlTab("SB1") + " (nolock) ON " + RetSqlCond("SB1") + " AND B1_COD = Z16_CODPRO "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z16")
	//Filtro por Pelete
	_cQuery += " AND Z16_ETQPAL IN ("
	For _nX := 1 to Len(_aAllColet)
		_cQuery += _aAllColet[_nX]

		If _nX != Len(_aAllColet)  // não é o último elemento, separa por vírgula
			_cQuery += ","
		Else  // é o último elemento, fecha a expressão IN do SQL
			_cQuery += ")"
		EndIf
	Next _nX

	// ordem dos dados
	_cQuery += " ORDER BY Z16_ETQPAL, IT_ETQ,Z16_CODPRO "

	memowrit("c:\query\twmsa023_sfTar02Col.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aSt02Cole,(_cAl02Cole))

	// abre o arquivo de trabalho
	(_cAl02Cole)->(dbSelectArea(_cAl02Cole))
	(_cAl02Cole)->(dbGoTop())

	// refresh do browse
	If (_oBr02Cole <> nil)
		_oBr02Cole:oBrowse:Refresh()
	EndIf

Return()

// ** funcao que retorna as movimentacoes de cada palete
Static Function sfTar02Mov(mvFirst)
	local _cQuery
	local _cSeqOS := ""

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aSt02Movi,{"Z17_STATUS","C", TamSx3("Z17_STATUS")[1],0})
		aAdd(_aSt02Movi,{"Z17_ETQPLT","C", TamSx3("Z17_ETQPLT")[1],0})							; /*aAdd(_aHdMovPlt,{"Z17_ETQPLT","","Id.Palete"  ,PesqPict("Z17","Z17_ETQPLT")})*/
		aAdd(_aSt02Movi,{"Z17_ENDORI","C", TamSx3("Z17_ENDORI")[1],0})							; aAdd(_aHd02Movi,{"Z17_ENDORI","","End.Origem" ,PesqPict("Z17","Z17_ENDORI")})
		aAdd(_aSt02Movi,{"Z17_ENDDES","C", TamSx3("Z17_ENDDES")[1],0})							; aAdd(_aHd02Movi,{"Z17_ENDDES","","End.Destino",PesqPict("Z17","Z17_ENDDES")})
		aAdd(_aSt02Movi,{"Z17_DTINI" ,"D", TamSx3("Z17_DTINI")[1],0})							; aAdd(_aHd02Movi,{"Z17_DTINI" ,"","Data.Inic." ,PesqPict("Z17","Z17_DTINI")})
		aAdd(_aSt02Movi,{"Z17_HRINI" ,"C", TamSx3("Z17_HRINI")[1],0})							; aAdd(_aHd02Movi,{"Z17_HRINI" ,"","Hora.Inic." ,PesqPict("Z17","Z17_HRINI")})
		aAdd(_aSt02Movi,{"Z17_OPERAD","C", TamSx3("Z17_OPERAD")[1],0})							; aAdd(_aHd02Movi,{"Z17_OPERAD","","Cod.Operad.",PesqPict("Z17","Z17_OPERAD")})
		aAdd(_aSt02Movi,{"DCD_NOMFUN","C", TamSx3("DCD_NOMFUN")[1],0})							; aAdd(_aHd02Movi,{"DCD_NOMFUN","","Operador"   ,PesqPict("DCD","DCD_NOMFUN")})
		aAdd(_aSt02Movi,{"Z17_EQUIPA","C", TamSx3("Z17_EQUIPA")[1],0})							; aAdd(_aHd02Movi,{"Z17_EQUIPA","","Cod.Equip." ,PesqPict("Z17","Z17_EQUIPA")})
		aAdd(_aSt02Movi,{"ZQ_DESCRIC","C", TamSx3("ZQ_DESCRIC")[1],0})							; aAdd(_aHd02Movi,{"ZQ_DESCRIC","","Equipamento",PesqPict("SZQ","ZQ_DESCRIC")})

		// fecha alias do TRB
		If Select(_cAl02Movi) <> 0
			(_cAl02Movi)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr02Movi := FWTemporaryTable():New( _cAl02Movi )
		_cTr02Movi:SetFields( _aSt02Movi )
		_cTr02Movi:Create()

	EndIf

	// limpa o conteudo do TRB
	(_cAl02Movi)->(dbSelectArea(_cAl02Movi))
	(_cAl02Movi)->(__DbZap())

	// busca etiquetas da ordem de servico
	_cQuery := " SELECT Z17_STATUS, Z17_ETQPLT, Z17_ENDORI, Z17_ENDDES, Z17_DTINI, Z17_HRINI, Z17_OPERAD, DCD_NOMFUN, Z17_EQUIPA, ZQ_DESCRIC "
	// ordem de servico
	_cQuery += " FROM " + RetSqlTab("Z17") + " (nolock) "
	// cad. de operadores
	_cQuery += " LEFT JOIN " + RetSqlTab("DCD") + " (nolock) ON " + RetSqlCond("DCD") + " AND DCD_CODFUN = Z17_OPERAD "
	// cad. de equioamentos
	_cQuery += " LEFT JOIN " + RetSqlTab("SZQ") + " (nolock) ON " + RetSqlCond("SZQ") + " AND ZQ_CODIGO  = Z17_EQUIPA "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z17")
	// filtra numero da os
	_cQuery += " AND Z17_NUMOS = '" + _cNrOSWms + "' "

	//Busca Seguencia de OS para a Tarefa 002 -> APANHA DE PRODUTOS / 013-TRANSFERENCIA / T08-TRANSFERENCIA LIVRE / T09-APANHE LIVRE
	_cSeqOS := sfBusSecOS(_cNrOSWms,"002/013/T08/T09")

	// sequencia da OS
	_cQuery += " AND Z17_SEQOS = '"+_cSeqOS+"' "

	// ordem dos dados
	_cQuery += " ORDER BY Z17_ETQPLT, Z17.R_E_C_N_O_ "

	memowrit("c:\query\twmsa023_sfTar02Mov.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aSt02Movi,(_cAl02Movi))

	// abre o arquivo de trabalho
	(_cAl02Movi)->(dbSelectArea(_cAl02Movi))
	(_cAl02Movi)->(dbGoTop())

	// refresh do browse
	If (_oBr02Movi <> nil)
		_oBr02Movi:oBrowse:Refresh()
	EndIf
Return


// ** funcao que retorna os Pedidos de Venda
Static Function sfTar07Ped(mvFirst)
	local _cSeqOS := ""
	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aSt07Pedi,{"Z07_PEDIDO"  ,"C", TamSx3("Z07_PEDIDO")[1],0})			; aAdd(_aHd07Pedi,{"Z07_PEDIDO" ,"","Pedido"  ,""})

		// fecha alias do TRB
		If Select(_cAl07Pedi) <> 0
			(_cAl07Pedi)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr07Pedi := FWTemporaryTable():New( _cAl07Pedi )
		_cTr07Pedi:SetFields( _aSt07Pedi )
		_cTr07Pedi:Create()

	EndIf

	(_cAl07Pedi)->(dbSelectArea(_cAl07Pedi))
	(_cAl07Pedi)->(__DbZap())

	// busca itens da OS
	_cQuery := " SELECT DISTINCT(Z07_PEDIDO) Z07_PEDIDO "
	// itens conferido
	_cQuery += " FROM " + RetSqlTab("Z07") + " (nolock) "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z07")
	// filtra numero da os
	_cQuery += " AND Z07_NUMOS = '" + _cNrOSWms + "' "

	//Busca Seguencia de OS para a Tarefa 007 - MONTAR PALETE e 003 - CONFERENCIA EXPEDICAO
	_cSeqOS := sfBusSecOS(_cNrOSWms, "007/003")
	// sequencia da OS
	_cQuery += " AND Z07_SEQOS = '" + _cSeqOS + "' "
	// ordem dos dados
	_cQuery += " ORDER BY Z07_PEDIDO"

	memowrit("c:\query\twmsa023_sfTar07Ped.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aSt07Pedi,(_cAl07Pedi))

	// abre o arquivo de trabalho
	(_cAl07Pedi)->(dbSelectArea(_cAl07Pedi))
	(_cAl07Pedi)->(dbGoTop())

	// refresh do browse
	If (_oBr07Pedi <> nil)
		_oBr07Pedi:oBrowse:Refresh()
	EndIf

Return()

// ** funcao que retorna os paletes do Pedidos de Venda
Static Function sfTar07Pal(mvFirst)
	local _cSeqOS := ""
	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aSt07Pale,{"Z07_PEDIDO"  ,"C", TamSx3("Z07_PEDIDO")[1],0})
		aAdd(_aSt07Pale,{"Z07_PALLET"  ,"C", TamSx3("Z07_PALLET")[1],0})			        ; aAdd(_aHd07Pale,{"Z07_PALLET" ,"","Palete"      ,""})
		aAdd(_aSt07Pale,{"Z07_QUANT"   ,"N", TamSx3("Z07_QUANT")[1],TamSx3("Z07_QUANT")[2]}); aAdd(_aHd07Pale,{"Z07_QUANT"  ,"","Quantidade",""})

		// fecha alias do TRB
		If Select(_cAl07Pale) <> 0
			(_cAl07Pale)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr07Pale := FWTemporaryTable():New( _cAl07Pale )
		_cTr07Pale:SetFields( _aSt07Pale )
		_cTr07Pale:Create()

	EndIf

	(_cAl07Pale)->(dbSelectArea(_cAl07Pale))
	(_cAl07Pale)->(__DbZap())

	// busca itens da OS
	_cQuery := "SELECT DISTINCT(Z07_PALLET) Z07_PALLET,Z07_PEDIDO,SUM(Z07_QUANT) Z07_QUANT  "
	_cQuery += "FROM "+RetSqlName("Z07")+" Z07 (nolock) "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z07")
	// Filtra numero da os
	_cQuery += "AND Z07_NUMOS = '"+_cNrOSWms+"' "
	//Busca Seguencia de OS para a Tarefa 007 -> MOTAR PALETE
	_cSeqOS    := sfBusSecOS(_cNrOSWms,"007/003")
	_cQuery += "AND Z07_SEQOS = '"+_cSeqOS+"' "
	//Agrupa
	_cQuery += " GROUP BY Z07_PALLET,Z07_PEDIDO"
	// ordem dos dados
	_cQuery += " ORDER BY Z07_PEDIDO,Z07_PALLET"

	memowrit("c:\query\twmsa023_sfTar07Pal.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aSt07Pale,(_cAl07Pale))

	// abre o arquivo de trabalho
	(_cAl07Pale)->(dbSelectArea(_cAl07Pale))
	(_cAl07Pale)->(dbGoTop())

	// refresh do browse
	If (_oBr07Pale <> nil)
		_oBr07Pale:oBrowse:Refresh()
	EndIf

Return()

// ** funcao que retorna Detalhe dos Paletes
Static Function sfTar07DPa(mvFirst)
	local _cSeqOS := ""
	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aSt07DtPa,{"Z07_PEDIDO"  ,"C", TamSx3("Z07_PEDIDO")[1],0})
		aAdd(_aSt07DtPa,{"Z07_PALLET"  ,"C", TamSx3("Z07_PALLET")[1],0})
		aAdd(_aSt07DtPa,{"IT_VOLORI"   ,"C", TamSx3("Z07_VOLORI")[1],0}); aAdd(_aHd07DtPa,{"IT_VOLORI"  ,"","Etq. Origem"   ,""})
		aAdd(_aSt07DtPa,{"IT_ETQ"      ,"C", TamSx3("Z07_ETQVOL")[1],0}); aAdd(_aHd07DtPa,{"IT_ETQ"     ,"","Etq. Destino"  ,""})
		aAdd(_aSt07DtPa,{"Z07_PRODUT"  ,"C", TamSx3("Z07_PRODUT")[1],0}); aAdd(_aHd07DtPa,{"Z07_PRODUT" ,"","Produto"  ,""})
		aAdd(_aSt07DtPa,{"B1_DESC"     ,"C", TamSx3("B1_DESC")[1],0})   ; aAdd(_aHd07DtPa,{"B1_DESC"    ,"","Descrição",""})
		aAdd(_aSt07DtPa,{"Z07_LOTCTL"  ,"C", TamSx3("Z07_LOTCTL")[1],0}); aAdd(_aHd07DtPa,{"Z07_LOTCTL" ,"","Lote"  ,""})
		aAdd(_aSt07DtPa,{"Z07_QUANT"   ,"N", TamSx3("Z07_QUANT")[1],TamSx3("Z07_QUANT")[2]}); aAdd(_aHd07DtPa,{"Z07_QUANT"  ,"","Quantidade",""})

		// fecha alias do TRB
		If Select(_cAl07DtPa) <> 0
			(_cAl07DtPa)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr07DtPa := FWTemporaryTable():New( _cAl07DtPa )
		_cTr07DtPa:SetFields( _aSt07DtPa )
		_cTr07DtPa:Create()

	EndIf

	(_cAl07DtPa)->(dbSelectArea(_cAl07DtPa))
	(_cAl07DtPa)->(__DbZap())

	// busca itens da OS
	_cQuery := "SELECT Z07_PALLET,"
	_cQuery += " CASE WHEN Z07_VOLORI = '' THEN Z07_ETQPRD ELSE Z07_VOLORI END IT_VOLORI,"
	_cQuery += " CASE WHEN Z07_ETQPRD = '' THEN Z07_ETQVOL ELSE Z07_ETQPRD END IT_ETQ,   "
	_cQuery += " Z07_PRODUT, "
	_cQuery += " Z07_QUANT,  "
	_cQuery += " Z07_PEDIDO, "
	_cQuery += " B1_DESC,    "
	_cQuery += " Z07_LOTCTL  "
	_cQuery += "FROM " + RetSqlName("Z07") + " Z07 (nolock) "
	// cad. produtos
	_cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 (nolock) ON "+RetSqlCond("SB1")+" AND B1_COD = Z07_PRODUT "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z07")
	// filtra numero da os
	_cQuery += "AND Z07_NUMOS = '"+_cNrOSWms+"' "
	//Busca Seguencia de OS para a Tarefa 007 -> MOTAR PALETE e 003 - Conferencia de Expedição

	_cSeqOS    := sfBusSecOS(_cNrOSWms,"007/003")
	_cQuery += "AND Z07_SEQOS = '"+_cSeqOS+"' "
	// ordem dos dados
	_cQuery += " ORDER BY Z07_PEDIDO, Z07_PALLET, IT_ETQ, Z07_PRODUT"

	memowrit("c:\query\twmsa023_sfTar07DPa.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aSt07DtPa,(_cAl07DtPa))

	// abre o arquivo de trabalho
	(_cAl07DtPa)->(dbSelectArea(_cAl07DtPa))
	(_cAl07DtPa)->(dbGoTop())

	// refresh do browse
	If (_oBr07DtPa <> nil)
		_oBr07DtPa:oBrowse:Refresh()
	EndIf

Return()


// ** funcao que retorna os Pedidos de Venda TAREFA 004
Static Function sfTar04ped(mvFirst)
	local _cSeqOS := ""
	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aSt04ped,{"Z07_PEDIDO", "C", TamSx3("Z07_PEDIDO")[1],0})			; aAdd(_aHd04ped,{"Z07_PEDIDO", "","Pedido",""})
		aAdd(_aSt04ped,{"Z43_CESV"  , "C", TamSx3("Z43_CESV")[1]  ,0})			; aAdd(_aHd04ped,{"Z43_CESV"  , "","CESV"  ,""})

		// fecha alias do TRB
		If Select(_cAl04ped) <> 0
			(_cAl04ped)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr04ped := FWTemporaryTable():New( _cAl04ped )
		_cTr04ped:SetFields( _aSt04ped )
		_cTr04ped:Create()

	EndIf
	(_cAl04ped)->(dbSelectArea(_cAl04ped))
	(_cAl04ped)->(__DbZap())

	// busca itens da OS
	_cQuery := " SELECT DISTINCT(Z07_PEDIDO) Z07_PEDIDO, Z43_CESV "
	// itens conferidos
	_cQuery += " FROM "+RetSqlTab("Z07")+" (nolock) "
	// vinculo com cesv
	_cQuery += "        LEFT JOIN "+RetSqlTab("Z43")+" (nolock) "
	_cQuery += "               ON "+RetSqlCond("Z43")
	_cQuery += "                  AND Z43_NUMOS = Z07_NUMOS "
	_cQuery += "                  AND Z43_PEDIDO = Z07_PEDIDO "
	_cQuery += "                  AND Z43_STATUS != 'C' "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z07")
	// filtra numero da os
	_cQuery += " AND Z07_NUMOS = '"+_cNrOSWms+"' "
	//Busca Seguencia de OS para a Tarefa CARREGAR VEICULOS -> 004
	_cSeqOS    := sfBusSecOS(_cNrOSWms,"004")
	_cQuery += " AND Z07_SEQOS = '"+_cSeqOS+"' "
	// ordem dos dados
	_cQuery += " ORDER BY Z07_PEDIDO"

	memowrit("c:\query\twmsa023_sfTar04ped.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aSt04ped,(_cAl04ped))

	// abre o arquivo de trabalho
	(_cAl04ped)->(dbSelectArea(_cAl04ped))
	(_cAl04ped)->(dbGoTop())

	// refresh do browse
	If (_oBr04ped <> nil)
		_oBr04ped:oBrowse:Refresh()
	EndIf

Return()

// ** funcao que retorna os paletes fonferidos do Pedidos de Venda
Static Function sfTar04Pal(mvFirst)

	local _cQuery
	local _cSeqOS := ""

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aSt04Pale,{"Z07_PEDIDO"  ,"C", TamSx3("Z07_PEDIDO")[1],0})
		aAdd(_aSt04Pale,{"Z07_PALLET"  ,"C", TamSx3("Z07_PALLET")[1],0})			        ; aAdd(_aHd04Pale,{"Z07_PALLET" ,"","Pallet"        ,""})
		aAdd(_aSt04Pale,{"Z07_CONFE"   ,"N", TamSx3("Z07_QUANT")[1],TamSx3("Z07_QUANT")[2]}); aAdd(_aHd04Pale,{"Z07_CONFE"  ,"","Qtd. Conferida",""})

		// fecha alias do TRB
		If Select(_cAl04Pale) <> 0
			(_cAl04Pale)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr04Pale := FWTemporaryTable():New( _cAl04Pale )
		_cTr04Pale:SetFields( _aSt04Pale )
		_cTr04Pale:Create()

	EndIf

	(_cAl04Pale)->(dbSelectArea(_cAl04Pale))
	(_cAl04Pale)->(__DbZap())

	// busca itens da OS
	_cQuery := "SELECT DISTINCT( Z07_PALLET ) Z07_PALLET,Z07_PEDIDO,SUM(Z07_QUANT) Z07_CONFE"
	_cQuery += " FROM "+RetSqlName("Z07")+" Z07 (nolock) "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z07")
	// Filtra numero da os
	_cQuery += " AND Z07_NUMOS = '"+_cNrOSWms+"' "
	//Busca Seguencia de OS para a Tarefa CARREGAR VEICULOS -> 004
	_cSeqOS    := sfBusSecOS(_cNrOSWms,"004")
	_cQuery += "AND Z07_SEQOS = '"+_cSeqOS+"' "
	//Agrupa
	_cQuery += " GROUP BY Z07_PALLET,Z07_PEDIDO"
	// ordem dos dados
	_cQuery += " ORDER BY Z07_PEDIDO,Z07_PALLET"

	memowrit("c:\query\twmsa023_sfTar04Pal.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aSt04Pale,(_cAl04Pale))

	// abre o arquivo de trabalho
	(_cAl04Pale)->(dbSelectArea(_cAl04Pale))
	(_cAl04Pale)->(dbGoTop())

	// refresh do browse
	If (_oBr04Pale <> nil)
		_oBr04Pale:oBrowse:Refresh()
	EndIf

Return()

// ** funcao que retorna movimentação dos Paletes
Static Function sfTar04DPa(mvFirst)
	local _cQuery
	local _cSeqOS := ""

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)

		aAdd(_aSt04DtPa,{"Z07_STATUS"  ,"C", TamSx3("Z08_STATUS")[1],0})
		aAdd(_aSt04DtPa,{"Z07_PEDIDO"  ,"C", TamSx3("Z07_PEDIDO")[1],0})
		aAdd(_aSt04DtPa,{"Z07_PALLET"  ,"C", TamSx3("Z07_PALLET")[1],0})
		aAdd(_aSt04DtPa,{"IT_ETQ"      ,"C", TamSx3("Z07_ETQVOL")[1],0})					; aAdd(_aHd04DtPa,{"IT_ETQ"     ,"","Etiqueta"     ,""})
		aAdd(_aSt04DtPa,{"Z07_QUANT"   ,"N", TamSx3("Z07_QUANT")[1],TamSx3("Z07_QUANT")[2]}); aAdd(_aHd04DtPa,{"Z07_QUANT"  ,"","Quantidade",""})

		// fecha alias do TRB
		If Select(_cAl04DtPa) <> 0
			(_cAl04DtPa)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr04DtPa := FWTemporaryTable():New( _cAl04DtPa )
		_cTr04DtPa:SetFields( _aSt04DtPa )
		_cTr04DtPa:Create()

	EndIf

	(_cAl04DtPa)->(dbSelectArea(_cAl04DtPa))
	(_cAl04DtPa)->(__DbZap())

	// busca itens da OS
	_cQuery := "SELECT Z07_PEDIDO,Z07_PALLET, "
	_cQuery += " CASE WHEN Z07_ETQCLI != '' THEN Z07_ETQCLI"
	_cQuery += "      WHEN Z07_ETQVOL != '' THEN Z07_ETQVOL"
	_cQuery += "      ELSE Z07_ETQPRD END IT_ETQ,"
	_cQuery += " SUM(Z07_QUANT)Z07_QUANT, "
	_cQuery += " ISNULL((SELECT SUM(Z16_QUANT) "
	_cQuery += " FROM " + RetSqlName("Z16") + " Z16 (nolock) WHERE " + RetSqlCond("Z16")
	_cQuery += " AND Z16.Z16_PEDIDO = Z07.Z07_PEDIDO "
	_cQuery += " AND Z16.Z16_ETQPAL = Z07.Z07_PALLET "
	_cQuery += " AND Z16.Z16_CODPRO = Z07.Z07_PRODUT "
	_cQuery += " AND Z16.Z16_ETQCLI = Z07.Z07_ETQCLI "
	_cQuery += " AND Z16.Z16_ETQVOL = Z07.Z07_ETQVOL ),0) Z16_QUANT "
	_cQuery += " FROM " + RetSqlName("Z07") + " Z07 (nolock) "
	//filtro padrao
	_cQuery += "WHERE " + RetSqlCond("Z07")
	//filtra numero da os
	_cQuery += "AND Z07_NUMOS = '" + _cNrOSWms + "' "
	//Busca Seguencia de OS para a Tarefa CARREGAR VEICULOS -> 004
	_cSeqOS    := sfBusSecOS(_cNrOSWms,"004")
	_cQuery += "AND Z07_SEQOS = '"+_cSeqOS+"' "
	_cQuery += " GROUP  BY Z07_PEDIDO,Z07_PALLET, Z07_ETQVOL, Z07_ETQPRD, Z07_ETQCLI, Z07_PRODUT"
	// ordem dos dados
	_cQuery += " ORDER BY Z07_PEDIDO, Z07_PALLET, IT_ETQ "

	memowrit("c:\query\twmsa023_sfTar04DPa.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aSt04DtPa,(_cAl04DtPa))

	// abre o arquivo de trabalho
	(_cAl04DtPa)->(dbSelectArea(_cAl04DtPa))
	(_cAl04DtPa)->(dbGoTop())

	// refresh do browse
	If (_oBr04DtPa <> nil)
		_oBr04DtPa:oBrowse:Refresh()
	EndIf

Return()

// ** funcao que retorna os paletes da OS de retrabalho
Static Function sfTarT5Pal(mvFirst)
	local _cSeqOS := ""
	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStT5Pale,{"Z07_PALLET"  ,"C", TamSx3("Z07_PALLET")[1],0})			        ; aAdd(_aHdT5Pale,{"Z07_PALLET" ,"","Palete"      ,""})
		aAdd(_aStT5Pale,{"Z07_QUANT"   ,"N", TamSx3("Z07_QUANT")[1],TamSx3("Z07_QUANT")[2]}); aAdd(_aHdT5Pale,{"Z07_QUANT"  ,"","Quantidade",""})

		// fecha alias do TRB
		If Select(_cAlT5Pale) <> 0
			(_cAlT5Pale)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTrT5Pale := FWTemporaryTable():New( _cAlT5Pale )
		_cTrT5Pale:SetFields( _aStT5Pale )
		_cTrT5Pale:Create()
	EndIf

	(_cAlT5Pale)->(dbSelectArea(_cAlT5Pale))
	(_cAlT5Pale)->(__DbZap())

	// busca itens da OS
	_cQuery := "SELECT DISTINCT(Z07_PALLET) Z07_PALLET,SUM(Z07_QUANT) Z07_QUANT  "
	_cQuery += "FROM "+RetSqlName("Z07")+" Z07 (nolock) "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z07")
	// Filtra numero da os
	_cQuery += "AND Z07_NUMOS = '"+_cNrOSWms+"' "
	//Busca Seguencia de OS para a Tarefa T05 -> RETRABALHO
	_cSeqOS    := sfBusSecOS(_cNrOSWms,"T05")
	_cQuery += " AND Z07_SEQOS = '"+_cSeqOS+"' "
	//Agrupa
	_cQuery += " GROUP BY Z07_PALLET"
	// ordem dos dados
	_cQuery += " ORDER BY Z07_PALLET"

	memowrit("c:\query\twmsa023_sfTarT5Pal.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aStT5Pale,(_cAlT5Pale))

	// abre o arquivo de trabalho
	(_cAlT5Pale)->(dbSelectArea(_cAlT5Pale))
	(_cAlT5Pale)->(dbGoTop())

	// refresh do browse
	If (_oBrT5Pale <> nil)
		_oBrT5Pale:oBrowse:Refresh()
	EndIf

Return()

// ** funcao que retorna Detalhe dos Paletes
Static Function sfTarT5DPa(mvFirst)
	local _cSeqOS := ""
	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStT5DtPa,{"Z16_ETQPAL"  ,"C", TamSx3("Z16_ETQPAL")[1],0})
		aAdd(_aStT5DtPa,{"Z16_VOLORI"  ,"C", TamSx3("Z16_VOLORI")[1],0}); aAdd(_aHdT5DtPa,{"Z16_VOLORI" ,"","Vol.Origem"   ,""})
		aAdd(_aStT5DtPa,{"Z16_ETQVOL"  ,"C", TamSx3("Z16_ETQVOL")[1],0}); aAdd(_aHdT5DtPa,{"Z16_ETQVOL" ,"","Vol.Destino"  ,""})
		aAdd(_aStT5DtPa,{"Z16_CODPRO"  ,"C", TamSx3("Z16_CODPRO")[1],0}); aAdd(_aHdT5DtPa,{"Z16_CODPRO" ,"","Produto"  ,""})
		aAdd(_aStT5DtPa,{"B1_DESC"     ,"C", TamSx3("B1_DESC")[1],0})   ; aAdd(_aHdT5DtPa,{"B1_DESC"    ,"","Descrição",""})
		aAdd(_aStT5DtPa,{"Z16_QUANT"   ,"N", TamSx3("Z16_QUANT")[1],TamSx3("Z16_QUANT")[2]}); aAdd(_aHdT5DtPa,{"Z16_QUANT"  ,"","Qtd. Volumes",""})

		// fecha alias do TRB
		If Select(_cAlT5DtPa) <> 0
			(_cAlT5DtPa)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTrT5DtPa := FWTemporaryTable():New( _cAlT5DtPa )
		_cTrT5DtPa:SetFields( _aStT5DtPa )
		_cTrT5DtPa:Create()
	EndIf

	(_cAlT5DtPa)->(dbSelectArea(_cAlT5DtPa))
	(_cAlT5DtPa)->(__DbZap())

	// busca itens da OS
	_cQuery := "SELECT Z16_ETQPAL,Z16_VOLORI,Z16_ETQVOL,Z16_CODPRO,Z16_QUANT,B1_DESC  "
	_cQuery += "FROM "+RetSqlName("Z16")+" Z16 (nolock) "
	// cad. produtos
	_cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 (nolock) ON "+RetSqlCond("SB1")+" AND B1_COD = Z16_CODPRO "

	_cQuery += " INNER JOIN "+RetSqlName("Z07")+" Z07 (nolock) ON "+RetSqlCond("Z07")+" AND Z16.Z16_ETQVOL = Z07.Z07_ETQVOL AND Z16_ETQPAL =  Z07_PALLET AND Z16.Z16_CODPRO = Z07.Z07_PRODUT "

	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("Z16")
	// filtra numero da os
	_cQuery += " AND Z07_NUMOS = '"+_cNrOSWms+"' "
	//Busca Seguencia de OS para a Tarefa T05 -> RETRABALHO
	_cSeqOS    := sfBusSecOS(_cNrOSWms,"T05")
	_cQuery += " AND Z07_SEQOS = '"+_cSeqOS+"' "
	// ordem dos dados
	_cQuery += " ORDER BY Z07_PALLET,Z07_ETQVOL,Z07_PRODUT"

	memowrit("c:\query\twmsa023_sfTarT5DPa.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aStT5DtPa,(_cAlT5DtPa))

	// abre o arquivo de trabalho
	(_cAlT5DtPa)->(dbSelectArea(_cAlT5DtPa))
	(_cAlT5DtPa)->(dbGoTop())

	// refresh do browse
	If (_oBrT5DtPa <> nil)
		_oBrT5DtPa:oBrowse:Refresh()
	EndIf

Return()

// ** funcao que retorna os itens da ordem de servico Retrabalho
Static Function sfTar09Pal(mvFirst)

	local _cQuery
	local _cSeqOS := ""

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		//Palet
		aAdd(_aSt09Pale,{"Z08_STATUS" ,"C", TamSx3("Z08_STATUS")[1],0})
		aAdd(_aSt09Pale,{"ID_PALETE"  ,"C", TamSx3("Z08_PALLET")[1],0})			//; aAdd(_aHd09Pale,{"ID_PALETE" ,"","Palete"  ,""})
		aAdd(_aSt09Pale,{"Z08_ENDORI" ,"C", TamSx3("Z08_ENDORI")[1],0})			; aAdd(_aHd09Pale,{"Z08_ENDORI","","Origem"  ,""})
		aAdd(_aSt09Pale,{"Z08_ENDDES" ,"C", TamSx3("Z08_ENDDES")[1],0})			; aAdd(_aHd09Pale,{"Z08_ENDDES","","Destino" ,""})
		aAdd(_aSt09Pale,{"Z08_PALLET" ,"C", TamSx3("Z08_PALLET")[1],0})
		aAdd(_aSt09Pale,{"Z08_NEWPLT" ,"C", TamSx3("Z08_NEWPLT")[1],0})

		// fecha alias do TRB
		If Select(_cAl09Pale) <> 0
			(_cAl09Pale)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr09Pale := FWTemporaryTable():New( _cAl09Pale )
		_cTr09Pale:SetFields( _aSt09Pale )
		_cTr09Pale:Create()
	EndIf
	(_cAl09Pale)->(dbSelectArea(_cAl09Pale))
	(_cAl09Pale)->(__DbZap())

	_cQuery := "SELECT DISTINCT(CASE WHEN Z08_NEWPLT <> '' THEN Z08_NEWPLT ELSE Z08_PALLET END) ID_PALETE,Z08_ENDORI,Z08_ENDDES, Z08_PALLET, Z08_NEWPLT,Z08_STATUS "
	_cQuery += "FROM "+RetSqlName("Z08")+" Z08 (nolock)  "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z08")
	// filtra numero da os
	_cQuery += "AND Z08_NUMOS = '"+_cNrOSWms+"' "

	//Busca Seguencia de OS para a Tarefa 009 -> Endereçamento
	_cSeqOS    := sfBusSecOS(_cNrOSWms,"009")

	_cQuery += "AND Z08_SEQOS = '"+_cSeqOS+"' "

	// ordem dos dados
	_cQuery += " ORDER BY Z08_PALLET"

	memowrit("c:\query\twmsa023_sfTar09Pal.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aSt09Movi,(_cAl09Pale))

	// abre o arquivo de trabalho
	(_cAl09Pale)->(dbSelectArea(_cAl09Pale))
	(_cAl09Pale)->(dbGoTop())

	// refresh do browse
	If (_oBr09Pale <> nil)
		_oBr09Pale:oBrowse:Refresh()
	EndIf

Return()

// ** funcao que retorna os produtos do Palet
Static Function sfTar09Pro(mvFirst)
	local _cSeqOS := ""
	local _cQuery

	// campo de controle de etiqueta
	local _cCmpChave := ""

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)

		// define campo de etiqueta
		If (_lEtqClient)
			_cCmpChave := "Z16_ETQCLI"
		ElseIf (_lEtqIdInt)
			_cCmpChave := "Z16_ETQPRD"
		Else
			_cCmpChave := "Z16_ETQVOL"
		EndIf

		//Mapa De Separação
		aAdd(_aSt09Prod,{"ID_PALETE"  ,"C", TamSx3("Z08_PALLET")[1],0})					   /*; aAdd(_aHd09Prod,{"ID_PALETE" ,"","Palet"     ,""})*/
		aAdd(_aSt09Prod,{"IT_ETQ"     ,"C", TamSx3("Z16_ETQPRD")[1],0})				       ; aAdd(_aHd09Prod,{"IT_ETQ"    ,"","Etiqueta"     ,""})
		aAdd(_aSt09Prod,{"Z08_PRODUT" ,"C", TamSx3("Z08_PRODUT")[1],0})					   ; aAdd(_aHd09Prod,{"Z08_PRODUT","","Produto"   ,""})
		aAdd(_aSt09Prod,{"B1_DESC"    ,"C", TamSx3("B1_DESC")[1],0})					   ; aAdd(_aHd09Prod,{"B1_DESC"   ,"","Descrição"  ,PesqPict("SB1","B1_DESC")})
		aAdd(_aSt09Prod,{"Z08_QUANT"  ,"N", TamSx3("Z08_QUANT")[1],TamSx3("Z08_QUANT")[2]}); aAdd(_aHd09Prod,{"Z08_QUANT" ,"","Quantidade",""})
		aAdd(_aSt09Prod,{"Z08_PALLET" ,"C", TamSx3("Z08_PALLET")[1],0})
		aAdd(_aSt09Prod,{"Z08_NEWPLT" ,"C", TamSx3("Z08_NEWPLT")[1],0})

		// fecha alias do TRB
		If Select(_cAl09Prod) <> 0
			(_cAl09Prod)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr09Prod := FWTemporaryTable():New( _cAl09Prod )
		_cTr09Prod:SetFields( _aSt09Prod )
		_cTr09Prod:Create()
	EndIf

	(_cAl09Prod)->(dbSelectArea(_cAl09Prod))
	(_cAl09Prod)->(__DbZap())

	// busca dados de produtos por palete
	_cQuery := " SELECT CASE "
	_cQuery += "          WHEN Z08_NEWPLT <> '' THEN Z08_NEWPLT "
	_cQuery += "          ELSE Z08_PALLET "
	_cQuery += "        END ID_PALETE, "
	_cQuery += "        Z08_PRODUT, "
	_cQuery += "        B1_DESC, "
	_cQuery += "        Z08_QUANT, "
	_cQuery += "        Z08_PALLET, "
	_cQuery += "        Z08_NEWPLT, "
	_cQuery += "        CASE "
	_cQuery += "          WHEN Z16_ETQPRD != '' THEN Z16_ETQPRD "
	_cQuery += "          WHEN Z16_ETQVOL != '' THEN Z16_ETQVOL "
	_cQuery += "          WHEN Z16_ETQCLI != '' THEN Z16_ETQCLI "
	_cQuery += "        END IT_ETQ "

	// mapa de movimentacao
	_cQuery += " FROM " + RetSqlTab("Z08") + " (nolock) "
	// cad. produtos
	_cQuery += " INNER JOIN " + RetSqlTab("SB1") + " (nolock) ON " + RetSqlCond("SB1") + " AND B1_COD = Z08_PRODUT "
	_cQuery += " INNER JOIN " + RetSqlTab("Z16") + " (nolock) ON " + RetSqlCond("Z16") + " AND Z16_CODPRO = Z08_PRODUT AND (CASE WHEN Z08_NEWPLT <> '' THEN Z08_NEWPLT ELSE Z08_PALLET END) = Z16_ETQPAL"
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z08")
	// filtra numero da os
	_cQuery += " AND Z08_NUMOS = '" + _cNrOSWms + "' "

	//Busca Seguencia de OS para a Tarefa 009 -> ENDERECAMENTO
	_cSeqOS    := sfBusSecOS(_cNrOSWms,"009")

	_cQuery += " AND Z08_SEQOS = '"+_cSeqOS+"' "
	// ordem dos dados
	_cQuery += " ORDER BY Z08_PALLET, Z08_QUANT, Z08_PRODUT "

	memowrit("c:\query\twmsa023_sfTar09Pro.txt", _cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aSt09Prod,(_cAl09Prod))

	// abre o arquivo de trabalho
	(_cAl09Prod)->(dbSelectArea(_cAl09Prod))
	(_cAl09Prod)->(dbGoTop())

	// refresh do browse
	If (_oBr09Prod <> nil)
		_oBr09Prod:oBrowse:Refresh()
	EndIf

Return()

// ** funcao que retorna os produtos do Palet
Static Function sfTar09Mov(mvFirst)

	local _cQuery
	local _cSeqOS := ""

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aSt09Movi,{"Z17_STATUS","C", TamSx3("Z17_STATUS")[1],0})
		aAdd(_aSt09Movi,{"Z17_ETQPLT","C", TamSx3("Z17_ETQPLT")[1],0})							; /*aAdd(_aHdMovPlt,{"Z17_ETQPLT","","Id.Palete"  ,PesqPict("Z17","Z17_ETQPLT")})*/
		aAdd(_aSt09Movi,{"Z17_ENDORI","C", TamSx3("Z17_ENDORI")[1],0})							; aAdd(_aHd09Movi,{"Z17_ENDORI","","End.Origem" ,PesqPict("Z17","Z17_ENDORI")})
		aAdd(_aSt09Movi,{"Z17_ENDDES","C", TamSx3("Z17_ENDDES")[1],0})							; aAdd(_aHd09Movi,{"Z17_ENDDES","","End.Destino",PesqPict("Z17","Z17_ENDDES")})
		aAdd(_aSt09Movi,{"Z17_DTINI" ,"D", TamSx3("Z17_DTINI")[1],0})							; aAdd(_aHd09Movi,{"Z17_DTINI" ,"","Data.Inic." ,PesqPict("Z17","Z17_DTINI")})
		aAdd(_aSt09Movi,{"Z17_HRINI" ,"C", TamSx3("Z17_HRINI")[1],0})							; aAdd(_aHd09Movi,{"Z17_HRINI" ,"","Hora.Inic." ,PesqPict("Z17","Z17_HRINI")})
		aAdd(_aSt09Movi,{"Z17_OPERAD","C", TamSx3("Z17_OPERAD")[1],0})							; aAdd(_aHd09Movi,{"Z17_OPERAD","","Cod.Operad.",PesqPict("Z17","Z17_OPERAD")})
		aAdd(_aSt09Movi,{"DCD_NOMFUN","C", TamSx3("DCD_NOMFUN")[1],0})							; aAdd(_aHd09Movi,{"DCD_NOMFUN","","Operador"   ,PesqPict("DCD","DCD_NOMFUN")})
		aAdd(_aSt09Movi,{"Z17_EQUIPA","C", TamSx3("Z17_EQUIPA")[1],0})							; aAdd(_aHd09Movi,{"Z17_EQUIPA","","Cod.Equip." ,PesqPict("Z17","Z17_EQUIPA")})
		aAdd(_aSt09Movi,{"ZQ_DESCRIC","C", TamSx3("ZQ_DESCRIC")[1],0})							; aAdd(_aHd09Movi,{"ZQ_DESCRIC","","Equipamento",PesqPict("SZQ","ZQ_DESCRIC")})

		// fecha alias do TRB
		If Select(_cAl09Movi) <> 0
			(_cAl09Movi)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr09Movi := FWTemporaryTable():New( _cAl09Movi )
		_cTr09Movi:SetFields( _aSt09Movi )
		_cTr09Movi:Create()
	EndIf

	// limpa o conteudo do TRB
	(_cAl09Movi)->(dbSelectArea(_cAl09Movi))
	(_cAl09Movi)->(__DbZap())

	If ( ! mvFirst)
		// busca etiquetas da ordem de servico
		_cQuery := "SELECT Z17_STATUS, Z17_ETQPLT, Z17_ENDORI, Z17_ENDDES, Z17_DTINI, Z17_HRINI, Z17_OPERAD, DCD_NOMFUN, Z17_EQUIPA, ZQ_DESCRIC "
		// ordem de servico
		_cQuery += "FROM "+RetSqlName("Z17")+" Z17 (nolock) "
		// cad. de operadores
		_cQuery += "LEFT JOIN "+RetSqlName("DCD")+" DCD (nolock) ON "+RetSqlCond("DCD")+" AND DCD_CODFUN = Z17_OPERAD "
		// cad. de operadores
		_cQuery += "LEFT JOIN "+RetSqlName("SZQ")+" SZQ (nolock) ON "+RetSqlCond("SZQ")+" AND ZQ_CODIGO  = Z17_EQUIPA "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("Z17")
		// filtra numero da os
		_cQuery += "AND Z17_NUMOS = '"+_cNrOSWms+"' "
		//Busca Seguencia de OS para a Tarefa 009 -> ENDERECAMENTO
		_cSeqOS    := sfBusSecOS(_cNrOSWms,"009")

		_cQuery += "AND Z17_SEQOS = '"+_cSeqOS+"' "

		// ordem dos dados
		_cQuery += "ORDER BY Z17_ETQPLT, Z17.R_E_C_N_O_ "

		memowrit("c:\query\twmsa023_sfTar09Mov.txt",_cQuery)

		// adiciona o conteudo da query para o arquivo de trabalho
		U_SqlToTrb(_cQuery,_aSt09Movi,(_cAl09Movi))
	EndIf

	// abre o arquivo de trabalho
	(_cAl09Movi)->(dbSelectArea(_cAl09Movi))
	(_cAl09Movi)->(dbGoTop())

	// refresh do browse
	If (_oBr09Movi <> nil)
		_oBr09Movi:oBrowse:Refresh()
	EndIf


Return()

// ** funcao que retorna os paletes do Pedidos de Venda
Static Function sfTar03Pal(mvFirst)
	local _cSeqOS := ""
	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aSt03Pale,{"Z07_PALLET"  ,"C", TamSx3("Z07_PALLET")[1],0})			        ; aAdd(_aHd03Pale,{"Z07_PALLET" ,"","Palete"      ,""})
		aAdd(_aSt03Pale,{"Z07_QUANT"   ,"N", TamSx3("Z07_QUANT")[1],TamSx3("Z07_QUANT")[2]}); aAdd(_aHd03Pale,{"Z07_QUANT"  ,"","Quantidade",""})

		// fecha alias do TRB
		If Select(_cAl03Pale) <> 0
			(_cAl03Pale)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr03Pale := FWTemporaryTable():New( _cAl03Pale )
		_cTr03Pale:SetFields( _aSt03Pale )
		_cTr03Pale:Create()
	EndIf

	(_cAl03Pale)->(dbSelectArea(_cAl03Pale))
	(_cAl03Pale)->(__DbZap())

	// busca itens da OS
	_cQuery := "SELECT DISTINCT(Z07.Z07_PALLET) , "
	_cQuery += "(SELECT COUNT(DISTINCT(Z07VOL.Z07_ETQVOL + Z07VOL.Z07_ETQCLI)) FROM " + RetSqlName("Z07") + " Z07VOL (nolock) WHERE "
	_cQuery += " Z07VOL.Z07_FILIAL  = '" + xFilial("Z07") + "' AND Z07VOL.D_E_L_E_T_ = ' ' AND Z07VOL.Z07_PALLET = Z07.Z07_PALLET AND Z07VOL.Z07_NUMOS = Z07.Z07_NUMOS AND Z07VOL.Z07_SEQOS = Z07.Z07_SEQOS AND Z07VOL.Z07_STATUS = Z07.Z07_STATUS ) Z07_QUANT  "
	// itens conferidos
	_cQuery += " FROM " + RetSqlTab("Z07") + " (nolock) "
	// filtro padrao
	_cQuery += "WHERE " + RetSqlCond("Z07")
	// Filtra numero da os
	_cQuery += "AND Z07.Z07_NUMOS = '" + _cNrOSWms + "' "
	//Busca Seguencia de OS para a Tarefa 003 -> CONFERENCIA // 014 - pre-conferencia sem doc fiscal.
	_cSeqOS := sfBusSecOS(_cNrOSWms, IIf(_cCodServ == "015", "014", "003"))
	_cQuery += " AND Z07.Z07_SEQOS = '" + _cSeqOS + "' "
	//Agrupa
	_cQuery += " GROUP BY Z07.Z07_PALLET, Z07.Z07_NUMOS, Z07.Z07_SEQOS, Z07.Z07_STATUS "
	// ordem dos dados
	_cQuery += " ORDER BY Z07.Z07_PALLET"

	memowrit("c:\query\twmsa023_sfTar03Pal.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aSt03Pale,(_cAl03Pale))

	// abre o arquivo de trabalho
	(_cAl03Pale)->(dbSelectArea(_cAl03Pale))
	(_cAl03Pale)->(dbGoTop())

	// refresh do browse
	If (_oBr03Pale <> nil)
		_oBr03Pale:oBrowse:Refresh()
	EndIf

Return()

// ** funcao que retorna movimentação dos Paletes
Static Function sfTar03DPa(mvFirst)

	// query
	local _cQuery
	local _cSeqOS := ""

	// campo de controle de etiqueta
	local _cCmpChave := ""

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)

		// define campo de etiqueta
		If (_lEtqClient)
			_cCmpChave := "Z16_ETQCLI"
		ElseIf (_lEtqIdInt)
			_cCmpChave := "Z16_ETQPRD"
		Else
			_cCmpChave := "Z16_ETQVOL"
		EndIf

		// define estrutura do TRB
		aAdd(_aSt03DtPa,{"Z16_ETQPAL", "C", TamSx3("Z16_ETQPAL")[1],0})
		aAdd(_aSt03DtPa,{"Z16_VOLORI", "C", TamSx3("Z16_VOLORI")[1],0})
		aAdd(_aSt03DtPa,{"IT_ETQ"    , "C", TamSx3(_cCmpChave)[1],0})  ; aAdd(_aHd03DtPa,{"IT_ETQ"     ,"","Etiqueta"  ,""})
		aAdd(_aSt03DtPa,{"Z16_CODPRO", "C", TamSx3("Z16_CODPRO")[1],0}); aAdd(_aHd03DtPa,{"Z16_CODPRO" ,"","Produto"  ,""})
		aAdd(_aSt03DtPa,{"B1_DESC"   , "C", TamSx3("B1_DESC")[1],0})   ; aAdd(_aHd03DtPa,{"B1_DESC"    ,"","Descrição",""})
		aAdd(_aSt03DtPa,{"Z16_QUANT" , "N", TamSx3("Z16_QUANT")[1],TamSx3("Z16_QUANT")[2]}); aAdd(_aHd03DtPa,{"Z16_QUANT"  ,"","Qtd. Volumes",""})

		// fecha alias do TRB
		If Select(_cAl03DtPa) <> 0
			(_cAl03DtPa)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTr03DtPa := FWTemporaryTable():New( _cAl03DtPa )
		_cTr03DtPa:SetFields( _aSt03DtPa )
		_cTr03DtPa:Create()
	EndIf

	(_cAl03DtPa)->(dbSelectArea(_cAl03DtPa))
	(_cAl03DtPa)->(__DbZap())

	// busca itens da OS
	_cQuery := " SELECT Z16_ETQPAL, "
	_cQuery += "        Z16_VOLORI, "
	_cQuery += "        CASE "
	_cQuery += "          WHEN Z16_ETQPRD != '' THEN Z16_ETQPRD "
	_cQuery += "          WHEN Z16_ETQVOL != '' THEN Z16_ETQVOL "
	_cQuery += "          WHEN Z16_ETQCLI != '' THEN Z16_ETQCLI "
	_cQuery += "        END IT_ETQ, "
	_cQuery += "        Z16_CODPRO, "
	_cQuery += "        Z16_QUANT, "
	_cQuery += "        B1_DESC "

	// composicao do palete
	_cQuery += " FROM " + RetSqlTab("Z16") + " (nolock) "

	// cad. produtos
	_cQuery += " INNER JOIN " + RetSqlTab("SB1") + " (nolock) ON " + RetSqlCond("SB1") + " AND B1_COD = Z16_CODPRO "
	_cQuery += " INNER JOIN " + RetSqlTab("Z07") + " (nolock) ON " + RetSqlCond("Z07") + " AND Z16.Z16_ETQVOL = Z07.Z07_ETQVOL AND Z16_ETQPAL =  Z07_PALLET AND Z16.Z16_CODPRO = Z07.Z07_PRODUT AND Z16.Z16_ETQCLI = Z07.Z07_ETQCLI "

	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond("Z16")

	// filtra numero da os
	_cQuery += " AND Z07_NUMOS = '" + _cNrOSWms + "' "

	//Busca Seguencia de OS para a Tarefa 003 -> CONFERENCIA // 014 - pre-conferencia sem doc fiscal.
	_cSeqOS := sfBusSecOS(_cNrOSWms, IIf(_cCodServ == "015", "014", "003"))

	_cQuery += " AND Z07_SEQOS = '" + _cSeqOS + "' "

	// ordem dos dados
	_cQuery += " ORDER BY Z16_ETQPAL, Z16_ETQVOL, Z16_CODPRO, Z16_QUANT, B1_DESC "

	memowrit("c:\query\twmsa023_sfTar03DPa.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery, _aSt03DtPa, (_cAl03DtPa))

	// abre o arquivo de trabalho
	(_cAl03DtPa)->(dbSelectArea(_cAl03DtPa))
	(_cAl03DtPa)->(dbGoTop())

	// refresh do browse
	If (_oBr03DtPa <> nil)
		_oBr03DtPa:oBrowse:Refresh()
	EndIf

Return()

// ** funcao que retorna as etiquetas e paletes
Static Function sfEtqPalete(mvFirst)
	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStEtqPalet,{"PLT_STATUS","C", TamSx3("Z07_STATUS")[1],0})
		aAdd(_aStEtqPalet,{"PLT_IDPALE","C", TamSx3("Z07_PALLET")[1],0})						; aAdd(_aHdEtqPalet,{"PLT_IDPALE","","Id.Palete",PesqPict("Z11","Z11_CODETI")})
		aAdd(_aStEtqPalet,{"PLT_ETQPRD","C", TamSx3("Z11_CODETI")[1],0})						; aAdd(_aHdEtqPalet,{"PLT_ETQPRD","","Etq.Produto",PesqPict("Z11","Z11_CODETI")})
		aAdd(_aStEtqPalet,{"PLT_ENDATU","C", TamSx3("Z07_ENDATU")[1],0})						; aAdd(_aHdEtqPalet,{"PLT_ENDATU","","End.Atual",PesqPict("Z07","Z07_ENDATU")})

		// fecha alias do TRB
		If (Select(_cAlTrbEtqPlt)<>0)
			(_cAlTrbEtqPlt)->(dbSelectArea(_cAlTrbEtqPlt))
			(_cAlTrbEtqPlt)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTrEtqPalet := FWTemporaryTable():New( _cAlTrbEtqPlt )
		_cTrEtqPalet:SetFields( _aStEtqPalet )
		_cTrEtqPalet:Create()
	EndIf

	// limpa o conteudo do TRB
	(_cAlTrbEtqPlt)->(dbSelectArea(_cAlTrbEtqPlt))
	(_cAlTrbEtqPlt)->(__DbZap())

	If ( ! mvFirst )

		// tipo ordem de servico - ENTRADA/RECEBIMENTO
		If (Z05->Z05_TPOPER == "E")
			// busca etiquetas da ordem de servico
			_cQuery := "SELECT DISTINCT Z07_STATUS PLT_STATUS, Z07_PALLET PLT_IDPALE, CASE WHEN Z11_TIPO = '01' THEN Z07_ETQPRD ELSE '' END PLT_ETQPRD, Z07_ENDATU PLT_ENDATU "
			// ordem de servico
			_cQuery += "FROM "+RetSqlName("Z05")+" Z05 (nolock) "
			// etiquetas
			_cQuery += "LEFT JOIN "+RetSqlName("Z07")+" Z07 (nolock) ON "+RetSqlCond("Z07")+" AND Z07_NUMOS = Z05_NUMOS "
			// etiquetas
			_cQuery += "LEFT JOIN "+RetSqlName("Z11")+" Z11 (nolock) ON "+RetSqlCond("Z11")+" AND Z11_CESV  IN (Z05_CESV,'') AND Z11_TIPO IN ('01','04') "
			_cQuery += "AND Z11_CODETI IN (Z07_ETQPRD,Z07_ETQVOL) "
			// filtro padrao
			_cQuery += "WHERE "+RetSqlCond("Z05")
			// filtra numero da os
			_cQuery += "AND Z05_NUMOS = '"+_cNrOSWms+"' "
			// ordem dos dados
			_cQuery += "ORDER BY PLT_ETQPRD "

			// tipo ordem de servico - SAIDA/EXPEDICAO
		ElseIf (Z05->Z05_TPOPER == "S")
			// busca etiquetas da ordem de servico
			_cQuery := "SELECT DISTINCT Z08_STATUS PLT_STATUS, "
			// id. palete
			_cQuery += "CASE WHEN Z08_NEWPLT != ' ' THEN Z08_NEWPLT ELSE Z08_PALLET END PLT_IDPALE, "
			// produto
			_cQuery += "Z16_ETQPRD PLT_ETQPRD, Z16_ENDATU PLT_ENDATU "
			// ordem de servico
			_cQuery += "FROM "+RetSqlName("Z08")+" Z08 (nolock) "
			// composicao do palete
			_cQuery += "LEFT JOIN "+RetSqlName("Z16")+" Z16 (nolock) ON "+RetSqlCond("Z16")+" "
			// etiqueta de palete
			_cQuery += "AND Z16_ETQPAL = ( CASE WHEN Z08_NEWPLT != ' ' THEN Z08_NEWPLT ELSE Z08_PALLET END ) "
			// valida o endereco
			_cQuery += "AND Z16_ENDATU IN (Z08_ENDORI, Z08_ENDTRA, Z08_ENDDES) "
			// filtro padrao
			_cQuery += "WHERE "+RetSqlCond("Z08")
			// filtra numero da os
			_cQuery += "AND Z08_NUMOS = '"+_cNrOSWms+"' "
			// ordem dos dados
			_cQuery += "ORDER BY Z16_ETQPRD "

		ElseIf (Z05->Z05_TPOPER == "I")
			// busca etiquetas da ordem de servico
			_cQuery := "SELECT DISTINCT Z08_STATUS PLT_STATUS, "
			// id. palete
			_cQuery += "CASE WHEN Z08_NEWPLT != ' ' THEN Z08_NEWPLT ELSE Z08_PALLET END PLT_IDPALE, "
			// produto
			_cQuery += "Z16_ETQPRD PLT_ETQPRD, Z16_ENDATU PLT_ENDATU "
			// ordem de servico
			_cQuery += "FROM "+RetSqlName("Z08")+" Z08 (nolock) "
			// composicao do palete
			_cQuery += "LEFT JOIN "+RetSqlName("Z16")+" Z16 (nolock) ON "+RetSqlCond("Z16")+" "
			// etiqueta de palete
			_cQuery += "AND Z16_ETQPAL = ( CASE WHEN Z08_NEWPLT != ' ' THEN Z08_NEWPLT ELSE Z08_PALLET END ) "
			// valida o endereco
			_cQuery += "AND Z16_ENDATU IN (Z08_ENDORI, Z08_ENDTRA, Z08_ENDDES) "
			// filtro padrao
			_cQuery += "WHERE "+RetSqlCond("Z08")
			// filtra numero da os
			_cQuery += "AND Z08_NUMOS = '"+_cNrOSWms+"' "
			// ordem dos dados
			_cQuery += "ORDER BY Z16_ETQPRD "

		EndIf

		// adiciona o conteudo da query para o arquivo de trabalho
		U_SqlToTrb(_cQuery,_aStEtqPalet,(_cAlTrbEtqPlt))

	EndIf

	// abre o arquivo de trabalho
	(_cAlTrbEtqPlt)->(dbSelectArea(_cAlTrbEtqPlt))
	(_cAlTrbEtqPlt)->(dbGoTop())

	// refresh do browse
	If (_oBrwEtqPalet <> nil)
		_oBrwEtqPalet:oBrowse:Refresh()
	EndIf

Return

// ** funcao que retorna a composicao de cada palete
Static Function sfCompPalete(mvFirst)
	local _cQuery

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStCompPlt,{"Z16_ETQVOL" ,"C", TamSx3("Z16_ETQVOL")[1],0})							; aAdd(_aHdCompPlt,{"Z16_ETQVOL","","Etq.Volume"  ,PesqPict("Z16","Z16_ETQVOL")})
		aAdd(_aStCompPlt,{"Z16_ETQPRD" ,"C", TamSx3("Z16_ETQPRD")[1],0})							; aAdd(_aHdCompPlt,{"Z16_ETQPRD","","Etq.Produto",PesqPict("Z16","Z16_ETQPRD")})
		aAdd(_aStCompPlt,{"Z16_CODPRO" ,"C", TamSx3("Z16_CODPRO")[1],0})							; aAdd(_aHdCompPlt,{"Z16_CODPRO","","Produto"    ,PesqPict("Z16","Z16_CODPRO")})
		aAdd(_aStCompPlt,{"B1_DESC"    ,"C", TamSx3("B1_DESC")[1],0})								; aAdd(_aHdCompPlt,{"B1_DESC"   ,"","Descrição"  ,PesqPict("SB1","B1_DESC")})
		aAdd(_aStCompPlt,{"Z16_QUANT"  ,"N", TamSx3("Z16_QUANT")[1],TamSx3("Z16_QUANT")[2]})		; aAdd(_aHdCompPlt,{"Z16_QUANT" ,"","Quantidade" ,PesqPict("Z16","Z16_QUANT")})
		aAdd(_aStCompPlt,{"Z16_ENDATU" ,"C", TamSx3("Z16_ENDATU")[1],0})							; aAdd(_aHdCompPlt,{"Z16_ENDATU","","End.Atual"  ,PesqPict("Z16","Z16_ENDATU")})
		aAdd(_aStCompPlt,{"Z16_ETQPAL" ,"C", TamSx3("Z16_ETQPAL")[1],0})

		// fecha alias do TRB
		If (Select(_cAlTrbCmpPlt)<>0)
			(_cAlTrbCmpPlt)->(dbSelectArea(_cAlTrbCmpPlt))
			(_cAlTrbCmpPlt)->(dbCloseArea())
		EndIf

		// criar um arquivo de trabalho
		_cTrCompPlt := FWTemporaryTable():New( _cAlTrbCmpPlt )
		_cTrCompPlt:SetFields( _aStCompPlt )
		_cTrCompPlt:Create()
	EndIf

	// limpa o conteudo do TRB
	(_cAlTrbCmpPlt)->(dbSelectArea(_cAlTrbCmpPlt))
	(_cAlTrbCmpPlt)->(__DbZap())

	If ( ! mvFirst)
		// busca etiquetas da ordem de servico
		_cQuery := "SELECT Z16_ETQVOL, Z16_ETQPRD, Z16_CODPRO, B1_DESC, Z16_QUANT, Z16_ENDATU, Z16_ETQPAL "
		// composicao de palete
		_cQuery += "FROM "+RetSqlName("Z16")+" Z16 (nolock) "
		// cad. produtos
		_cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 (nolock) ON "+RetSqlCond("SB1")+" AND B1_COD = Z16_CODPRO "
		// filtro padrao
		_cQuery += "WHERE "+RetSqlCond("Z16")
		// filtra por id de palete
		_cQuery += "AND Z16_ETQPAL IN ("
		// etiquetas conferidas na ordem de servico - ENTRADA/RECEBIMENTO
		If (Z05->Z05_TPOPER == "E")
			_cQuery += "                   SELECT DISTINCT Z07_PALLET "
			_cQuery += "                     FROM "+RetSqlName("Z07")+" Z07 (nolock) "
			_cQuery += "                    WHERE "+RetSqlCond("Z07")
			_cQuery += "                      AND Z07_NUMOS = '"+_cNrOSWms+"' "
			// etiquetas conferidas na ordem de servico - SAIDA/EXPEDICAO
		ElseIf (Z05->Z05_TPOPER == "S")
			_cQuery += "                   SELECT DISTINCT (CASE WHEN Z08_NEWPLT <> '' THEN Z08_NEWPLT ELSE Z08_PALLET END) "
			_cQuery += "                     FROM "+RetSqlName("Z08")+" Z08 (nolock) "
			_cQuery += "                    WHERE "+RetSqlCond("Z08")
			_cQuery += "                      AND Z08_NUMOS = '"+_cNrOSWms+"' "
		ElseIf (Z05->Z05_TPOPER == "I")
			_cQuery += "                   SELECT DISTINCT (CASE WHEN Z08_NEWPLT <> '' THEN Z08_NEWPLT ELSE Z08_PALLET END) "
			_cQuery += "                     FROM "+RetSqlName("Z08")+" Z08 (nolock) "
			_cQuery += "                    WHERE "+RetSqlCond("Z08")
			_cQuery += "                      AND Z08_NUMOS = '"+_cNrOSWms+"' "
		EndIf
		_cQuery += ")"
		// ordem dos dados
		_cQuery += "ORDER BY Z16_ETQPAL, Z16_ETQPRD "

		memowrit("c:\query\twmsa023_sfCompPalete.txt",_cQuery)

		// adiciona o conteudo da query para o arquivo de trabalho
		U_SqlToTrb(_cQuery,_aStCompPlt,(_cAlTrbCmpPlt))
	EndIf

	// abre o arquivo de trabalho
	(_cAlTrbCmpPlt)->(dbSelectArea(_cAlTrbCmpPlt))
	(_cAlTrbCmpPlt)->(dbGoTop())

	// refresh do browse
	If (_oBrwCompPlt <> nil)
		_oBrwCompPlt:oBrowse:Refresh()
	EndIf

Return

// ** funcao que pesquisa a ordem de servico por etiqueta
Static Function sfPesqEtiqueta()
	local _cQuery
	// itens do retorno
	local _aItens := {}
	// variavel de retorno
	local _lRet := .f.

	// objetos da tela
	local _oDlgSelOS
	local _oBrwOrdSrv

	// monta a query de pesquisa
	_cQuery := "SELECT DISTINCT Z07_NUMOS, Z07_SEQOS "
	// etiquetas conferidas
	_cQuery += "FROM "+RetSqlName("Z07")+" Z07 (nolock) "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z07")
	// codigo da etiqueta do produto, ou do volume
	_cQuery += "AND '"+_cCodEtqPesq+"' IN (Z07_ETQPRD,Z07_ETQVOL) "
	// ordem das informacoes
	_cQuery += "ORDER BY Z07_NUMOS"
	// retorno dos dados em vetor
	_aItens := U_SqlToVet(_cQuery)

	// se nao encontrou itens
	If (Len(_aItens) == 0)
		Aviso("TWMSA023 -> sfPesqRef","Nenhuma Ordem de Serviço encontrada com esta referência.",{"Fechar"})
		Return(.f.)

		// se retornou 1 item
	ElseIf (Len(_aItens) == 1)
		// retorna o numero da programacao
		_cNrOSWms := _aItens[1][1]
		Return(.t.)

		// se retornou mais de um item, apresenta tela para o usuario escolher
	ElseIf (Len(_aItens) > 1)
		// monta a tela
		_oDlgSelOS := MSDialog():New(000,000,300,500,"Ordens de Serviço...",,,.F.,,,,,,.T.,,,.T. )
		// cria o objeto do brose
		_oBrwOrdSrv := TWBrowse():New(000,000,300,500,,{ RetTitle("Z07_NUMOS"),;
		RetTitle("Z07_SEQOS") },{20,20,30,30},_oDlgSelOS,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
		_oBrwOrdSrv:Align:= CONTROL_ALIGN_ALLCLIENT

		// seta os itens do browse
		_oBrwOrdSrv:SetArray(_aItens)

		// escreve as linhas do browse
		_oBrwOrdSrv:bLine := {|| {_aItens[_oBrwOrdSrv:nAt,01],;
		_aItens[_oBrwOrdSrv:nAt,02] }}

		// funcao do duplo-click
		_oBrwOrdSrv:bLDblClick := {|| _lRet := .t., _cNrOSWms := _aItens[_oBrwOrdSrv:nAt,01] , _oDlgSelOS:End() }

		// ativa a tela
		ACTIVATE MSDIALOG _oDlgSelOS CENTERED ON INIT EnchoiceBar(_oDlgSelOS,{|| _lRet := .t., _cNrOSWms := _aItens[_oBrwOrdSrv:nAt,01], _oDlgSelOS:End()} , {|| _oDlgSelOS:End() })
	EndIf

Return(_lRet)

// ** funcao que Busca a sequencia da tarefa em uma OS.
Static Function sfBusSecOS(mvNrOrdSrv, mvTarefa)
	// variavel de retorno
	local _cRet := ""
	// seek
	local _cSeekZ06
	// tarefas
	local _aTarefas := {}
	// controle de loop
	local _nZ := 0

	Default mvNrOrdSrv := ""
	Default mvTarefa   := ""

	// posiciona no item da Ordem de Servico
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	Z06->(dbSeek( _cSeekZ06 := xFilial("Z06")+mvNrOrdSrv ))

	// varre todos os itens
	While Z06->( ! Eof() ) .And. ((Z06->Z06_FILIAL + Z06->Z06_NUMOS) == _cSeekZ06)
		// compara as validacoes necessarias

		If ( Alltrim(Z06->Z06_TAREFA) $ mvTarefa )
			// armazena sequencia da OS
			_cRet := Z06->Z06_SEQOS
			// sai do Loop
			Exit
		EndIf

		// proximo item
		Z06->(dbSkip())
	EndDo

Return(_cRet)

// ** funcão que retorna a legenda
User Function WMSA023L( mvCadastro, mvLegTit, mvDetLeg)

	// monta a tela de legenda e apresenta pro usuário
	BrwLegenda( mvCadastro, mvLegTit, mvDetLeg )

Return .f.

// ** função que retorna o mapa para apresentar no browse
Static Function sfRetMapa ( mvFirst )

	// variavel de retorno
	local _lRet := .f.
	// seek na Z08
	local _cSeekZ08 := ""
	// legenda do browse
	Local _oGreen  := LoadBitmap( GetResources(), "BR_VERDE")
	Local _oYellow := LoadBitmap( GetResources(), "BR_AMARELO")
	local _oBlue   := LoadBitmap( GetResources(), "BR_AZUL")
	local _cLegMapa := ""
	// descrição do produto
	local _cDescProd := ""
	// pallet da operação
	local _cPltOper := ""

	// crio o header do browse
	If ( mvFirst )

		aAdd(_aHeadMapa,{"Status"        ,"IT_STAT"     , "@BMP" , 1, 0, .t., Nil, Nil, Nil, "R" })
		aAdd(_aHeadMapa,{"End.Serv"      ,"Z08_ENDSRV"  , PesqPict("Z08","Z08_ENDSRV"), TamSx3("Z08_ENDSRV")[1], 0, Nil, Nil, "C", Nil, "R" })
		aAdd(_aHeadMapa,{"End.Origem"    ,"Z08_ENDORI"  , PesqPict("Z08","Z08_ENDORI"), TamSx3("Z08_ENDORI")[1], 0, Nil, Nil, "C", Nil, "R" })
		aAdd(_aHeadMapa,{"End.Transação" ,"Z08_ENDTRA"  , PesqPict("Z08","Z08_ENDTRA"), TamSx3("Z08_ENDTRA")[1], 0, Nil, Nil, "C", Nil, "R" })
		aAdd(_aHeadMapa,{"End.Destino"   ,"Z08_ENDDES"  , PesqPict("Z08","Z08_ENDDES"), TamSx3("Z08_ENDDES")[1], 0, Nil, Nil, "C", Nil, "R" })
		aAdd(_aHeadMapa,{"Cod.Produto"   ,"Z08_PRODUT"  , PesqPict("Z08","Z08_PRODUT"), TamSx3("Z08_PRODUT")[1], 0, Nil, Nil, "C", Nil, "R" })
		aAdd(_aHeadMapa,{"Desc.Produto"  ,"IT_DESC"     , PesqPict("SB1","B1_DESC")   , TamSx3("B1_DESC")[1]   , 0, Nil, Nil, "C", Nil, "R" })
		aAdd(_aHeadMapa,{"Etq.Pallet"    ,"Z08_PALLET"  , IIf (!_lUsrGeren,"**********", PesqPict("Z08","Z08_PALLET")) , TamSx3("Z08_PALLET")[1], 0, Nil, Nil, "C", Nil, "R" })
	EndIf

	// limpo a variável
	_aColsMapa := {}

	// posiciono na Z08 para popular o acols
	dbSelectArea("Z08")
	Z08->( dbSetOrder(1) ) // Z08_FILIAL, Z08_NUMOS, R_E_C_N_O_, D_E_L_E_T_
	Z08->( dbSeek ( _cSeekZ08 := xFilial("Z08") + _cNrOSWms ) )

	// pra todos os registros encontrados
	While ( Z08->( ! Eof() ) ) .and. ( Z08->( Z08_FILIAL + Z08_NUMOS ) == _cSeekZ08 )

		// definição da legenda
		If ( Z08->Z08_STATUS == "P" )
			_cLegMapa := _oYellow
		ElseIf ( Z08->Z08_STATUS == "M" )
			_cLegMapa := _oBlue
		ElseIf ( Z08->Z08_STATUS == "R" )
			_cLegMapa := _oGreen
		EndIf

		// definição da descrição do produto
		_cDescProd := Posicione( "SB1", 1, xFilial("SB1") + Z08->Z08_PRODUT, "B1_DESC" )

		// definição do pallet
		_cPltOper := Iif( ! Empty(Z08->Z08_NEWPLT), Z08->Z08_NEWPLT, Z08->Z08_PALLET )

		// populo o array com as informações encontradas
		aAdd(_aColsMapa, { _cLegMapa,         ;
		Z08->Z08_ENDSRV,   ;
		Z08->Z08_ENDORI,   ;
		Z08->Z08_ENDTRA,   ;
		Z08->Z08_ENDDES,   ;
		Z08->Z08_PRODUT,   ;
		_cDescProd,        ;
		_cPltOper,         ;
		.f. } )

		// atualiza o retorno
		_lRet := .t.

		// próx registro
		Z08->( dbSkip() )
	EndDo

	// atualiza o browse
	If ( ! mvFirst )
		// refresh do browse
		If (_oBrwMapa <> nil)
			_oBrwMapa:aCols := _aColsMapa
			_oBrwMapa:oBrowse:Refresh()
		EndIf
	EndIf

Return _lRet

//função que retorna os dados do TFAA
Static Function sfRetTFAA (mvNumOS)

	local _aRet := {}

	local _aAreaZ05 := Z05->(GetArea())
	local _aAreaZ41 := Z41->(GetArea())

	//busca se existe TFAA
	dbSelectArea("Z05")
	Z05->( dbSetOrder(1) ) // Z05_FILIAL, Z05_NUMOS, R_E_C_N_O_, D_E_L_E_T_

	If (Z05->(dbSeek( xFilial("Z05") + mvNumOS )))
		//se gerou TFAA, pega as informações
		If (!Empty(Z05->Z05_TFAA))
			aAdd(_aRet,Z05->Z05_TFAA)                   //[01] - número do TFAA
			aAdd(_aRet,Z05->Z05_PVTFAA)                 //[02] - Pedido de venda do TFAA

			dbSelectArea("Z41")
			Z41->( dbSetOrder(1) ) // Z41_FILIAL, Z41_CODIGO, R_E_C_N_O_, D_E_L_E_T_

			//se achou o TFAA corretamente gerado
			If (Z41->(dbSeek( xFilial("Z41") + Z05->Z05_TFAA )))
				aAdd(_aRet,Z41->Z41_DTEMIS)       //[03] - data da geração do TFAA
				aAdd(_aRet,Z41->Z41_HREMIS)             //[04] - hora da geração do TFAA
				aAdd(_aRet,Z41->Z41_USREMI)             //[05] - usuário gerador do TFAA
			EndIf
		EndIf
	EndIf

	//restaura areas que foram desposicionadas
	RestArea(_aAreaZ05)
	RestArea(_aAreaZ41)

	/*
	Estrutura do vetor de retorno

	[01] - número do TFAA
	[02] - Pedido de venda do TFAA
	[03] - data da geração do TFAA
	[04] - hora da geração do TFAA
	[05] - usuário gerador do TFAA
	*/

Return (_aRet)


// apaga as tabelas temporarias criadas (arquivos de trabalho)
Static Function SfApagaTab()
	If ValType(_cTrServicos) == "O"
		_cTrServicos:Delete()
	EndIf
	If ValType(_cTr02Mapa  ) == "O"
		_cTr02Mapa:Delete()
	Endif
	If ValType(_cTr02Prod  ) == "O"
		_cTr02Prod:Delete()
	EndIf
	If ValType(_cTr02Ende  ) == "O"
		_cTr02Ende:Delete()
	EndIf
	If ValType(_cTr02Cole  ) == "O"
		_cTr02Cole:Delete()
	Endif
	If ValType(_cTr02Movi  ) == "O"
	Endif
	If ValType(_cTr07Pedi  ) == "O"
		_cTr07Pedi:Delete()
	Endif
	If ValType(_cTr07Pale  ) == "O"
		_cTr07Pale:Delete()
	Endif
	If ValType(_cTr07DtPa  ) == "O"
		_cTr07DtPa:Delete()
	Endif
	If ValType(_cTr04ped   ) == "O"
		_cTr04ped:Delete()
	Endif
	If ValType(_cTr04Pale  ) == "O"
		_cTr04Pale:Delete()
	Endif
	If ValType(_cTr04DtPa  ) == "O"
		_cTr04DtPa:Delete()
	Endif
	If ValType(_cTrT5Pale  ) == "O"
		_cTrT5Pale:Delete()
	Endif
	If ValType(_cTrT5DtPa  ) == "O"
		_cTrT5DtPa:Delete()
	Endif
	If ValType(_cTr09Pale  ) == "O"
		_cTr09Pale:Delete()
	Endif
	If ValType(_cTr09Prod  ) == "O"
		_cTr09Prod:Delete()
	Endif
	If ValType(_cTr09Movi  ) == "O"
		_cTr09Movi:Delete()
	Endif
	If ValType(_cTr03Pale  ) == "O"
		_cTr03Pale:Delete()
	Endif
	If ValType(_cTr03DtPa  ) == "O"
		_cTr03DtPa:Delete()
	Endif
	If ValType(_cTrEtqPalet) == "O"
		_cTrEtqPalet:Delete()
	Endif
	If ValType(_cTrCompPlt ) == "O"
		_cTrCompPlt:Delete()
	Endif
Return