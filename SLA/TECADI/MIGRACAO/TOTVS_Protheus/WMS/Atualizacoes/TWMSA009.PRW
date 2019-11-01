#INCLUDE "TOTVS.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "RWMAKE.CH"
#Include "colors.ch"
#INCLUDE "FILEIO.CH"
#Include "TopConn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Tela para visualizacao dos servicos gerados pelo WMS.   !
!                  ! Todas as outras rotinas serao chamadas a partir desta.  !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 07/2012 !
+------------------+--------------------------------------------------------*/

User Function TWMSA009()
	// lista de pergunta (parametros)
	Local _vPerg := {}
	// cores da legenda
	local _aCoresLeg := {}

	// objetos da tela
	local _oMnuPrin1
	local _oMnu1OrdSrv, _oMnu1Devol, _oMnu1Tools

	// variaveis temporarias
	local _nX

	// grupo de perguntas
	private _cPerg := PadR("TWMSA009",10)

	// dimensoes da tela
	private _aSizeWnd := MsAdvSize()

	// fontes utilizadas
	Private _oFntBrowse := TFont():New("Verdana",,14,.f.,.f.)
	Private _oFntMenu   := TFont():New("Verdana",,14,.t.,.f.)
	Private _oFntCabec  := TFont():New("Verdana",,25,.t.,.f.)
	Private _oFntRoda   := TFont():New("Verdana",,14,.t.,.f.)
	Private _oFnt02     := TFont():New("Verdana",,14,,.f.)
	Private _oFnt04     := TFont():New("Courier New",,16,,.f.)

	// campos do browse das ordens de servico
	private _aHdOrdServ := {}
	private _cTrOrdServ
	private _aStOrdServ := {}
	private _oBrwOrdServ
	private _cAlTrOrdServ := GetNextAlias()
	Private _cAlTrbMov    := GetNextAlias()

	// campos do browse do planejamento
	private _aHdPlanej   := {}
	private _cTrPlanej
	private _aStPlanej   := {}
	private _oBrwPlanej
	private _cAlTrPlanej := GetNextAlias()
	private _TRBSERV     := GetNextAlias()
	private _cArqTmp

	// permite conferencia/recebimento por volumes
	private _lCtrVolume := .f.

	// filtro padrao para os servicos
	Private cQryFilZ06 := ""
	// condicao para filtrar somente que o operador eh recuros
	Private cQryUsrZ18 := ""

	// funcao que monta os dados do operador logado no sistema
	Private _aUsrInfo := U_FtWmsOpe()

	// valida se o usuario logado no sistema esta cadastrado como operador do WMS
	If ( ! _aUsrInfo[1] )
		Return(.f.)
	EndIf

	// titulo da tela principal
	Private cCadastro := "Monitor de Ordem de Serviços"

	// codigo do Operador
	Private _lUsrAccou  := (_aUsrInfo[2]=="A")
	Private _lUsrColet	:= (_aUsrInfo[2]=="C")
	Private _lUsrSuper	:= (_aUsrInfo[2]=="S")
	Private _lUsrGeren  := (_aUsrInfo[2]=="G")
	Private _lUsrMonit  := (_aUsrInfo[2]=="M")
	Private _lUsrLider  := (_aUsrInfo[2]=="L")
	Private _cCodOper   := IIf((_lUsrMonit).or.(_lUsrColet),Space(6),__cUserId)
	Private _cNomOper   := Space(30) // nome do operador
	private _cCodEquip	:= Space(6)
	private _cTipEquip	:= Space(3)

	// variaveis do filtro
	Private mvDataDe   := (Date()-7) //mv_par01
	Private mvDataAte  := Date()     //mv_par02
	Private mvCliDe    := " "        //mv_par03
	Private mvCliAte   := "zzz"      //mv_par04
	Private mvNumOSDe  := " "        //mv_par05
	Private mvNumOSAte := "zzz"      //mv_par06

	// filtro especifico para usuario do tipo monitor, usando em outras funcoes
	Private cQryFilMnt := IIf(_lUsrMonit, U_FtWmsFlt(_aUsrInfo[2],cCodOper), "")

	//Variaveis Tela de Filtro - INICIO
	Private _nPosMARK := 1

	//Cabeçalho e Linha Grid filtro OS finalizadas
	Private _aHeadOSF := {} //Cabec
	Private _aColsOSF := {} //Linha

	//Cabeçalho Grid filtro Operadores
	Private _aHdRecHum := {} //Cabec
	Private _aItRecHum := {} //Linha

	//Cabeçalho Grid filtro Equipamentos
	Private _aHdMaqEqu := {} //Cabec
	Private _aItMaqEqu := {} //Linha

	//Cabeçalho Grid filtro Rua
	Private _aHdRua := {} //Cabec
	Private _aItRua := {} //Linha

	//Cabeçalho Grid filtro Pedido de Venda
	Private _aHdPedVen := {} //Cabec
	Private _aItPedVen := {} //Linha

	//Cabeçalho Grid filtro Pedido Cliente
	Private _aHdPedCli := {} //Cabec
	Private _aItPedCli := {} //Linha

	//Cabeçalho Grid filtro Agrupadora
	Private _aHdIdAgru := {} //Cabec
	Private _aItIdAgru := {} //Linha

	// variaveis auxiliares para uso em filtros
	private _aOsRecHum := {}
	private _aOsMaqEqu := {}
	private _aOsRua    := {}
	private _aOsPedVen := {}
	private _aOsPedCli := {}
	private _aOsIdAgru := {}

	// cabeçalho e Linha Grid filtro de Tipo da Operacao
	Private _aHdTpOper := {} //Cabec
	Private _aItTpOper := {} //Linha

	// rodapé
	Private _oSayRoda1, _oSayRoda2, _oPnlRoda
	Private _nQtdRoda1 := 0                   // quantidade de registros no browse para exibir no rodapé

	//Variaveis Tela de Filtro - FIM
	//Variaveis Cabeçalho do filtro OS Finalizadas
	aAdd(_aHeadOSF ,{'','W1_AMARK' ,'@BMP',10,0,  ,  ,'C',  ,'V' ,  ,  , 'mark'   , 'V', 'S' } )
	Aadd(_aHeadOSF ,{'','W1_DESCRI','@!'  ,03,0,"","",'C',"",""})
	Aadd(_aColsOSF ,{'LBOK',"Exibe todas as OS",.F.})
	Aadd(_aColsOSF ,{"LBNO","Não exibe as finalizadas",.F.})
	Aadd(_aColsOSF ,{"LBNO","Exibe apenas finalizadas",.F.})
	//Variaveis Cabeçalho do filtro Operadores
	aAdd(_aHdRecHum ,{''      ,'W2_AMARK' ,'@BMP',10,0,  ,  ,'C',  ,'V' ,  ,  , 'mark'   , 'V', 'S' } )
	Aadd(_aHdRecHum ,{'Código','W2_COD'   ,'@!'  ,06,0,"","",'C',"",""})
	Aadd(_aHdRecHum ,{'Nome'  ,'W2_DESCRI','@!'  ,25,0,"","",'C',"",""})
	//Variaveis Cabeçalho do filtro Equipamentos/Maquinas
	aAdd(_aHdMaqEqu ,{''      ,'W3_AMARK' ,'@BMP',10,0,  ,  ,'C',  ,'V' ,  ,  , 'mark'   , 'V', 'S' } )
	Aadd(_aHdMaqEqu ,{'Código','W3_COD'   ,'@!'  ,06,0,"","",'C',"",""})
	Aadd(_aHdMaqEqu ,{'Nome'  ,'W3_DESCRI','@!'  ,25,0,"","",'C',"",""})
	//Variaveis Cabeçalho do filtro Rua
	aAdd(_aHdRua ,{''      ,'W4_AMARK' ,'@BMP',10,0,  ,  ,'C',  ,'V' ,  ,  , 'mark'   , 'V', 'S' } )
	Aadd(_aHdRua ,{'Rua '  ,'W4_DESCRI','@!'  ,02,0,"","",'C',"",""})
	//Variaveis Cabeçalho do filtro Pedido de Venda
	aAdd(_aHdPedVen ,{''                  ,'W5_AMARK' ,'@BMP',10,0,  ,  ,'C',  ,'V' ,  ,  , 'mark'   , 'V', 'S' } )
	Aadd(_aHdPedVen ,{'Pedido de Venda'   ,'W5_DESCRI','@!'  ,10,0,"","",'C',"",""})
	//Variaveis Cabeçalho do filtro Pedido Cliente
	aAdd(_aHdPedCli ,{''                 ,'W6_AMARK' ,'@BMP',10,0,  ,  ,'C',  ,'V' ,  ,  , 'mark'   , 'V', 'S' } )
	Aadd(_aHdPedCli ,{'Pedido Cliente'   ,'W6_DESCRI','@!'  ,20,0,"","",'C',"",""})
	//Variaveis Cabeçalho do filtro Agrupadora/DLN
	aAdd(_aHdIdAgru ,{''                 ,'W7_AMARK' ,'@BMP',10,0,  ,  ,'C',  ,'V' ,  ,  , 'mark'   , 'V', 'S' } )
	Aadd(_aHdIdAgru ,{'Agrupadora/DLN'   ,'W7_DESCRI','@!'  ,20,0,"","",'C',"",""})

	// variaveis - cabeçalho e itens do filtro de Tipo de Operacao
	aAdd(_aHdTpOper ,{'','W1_AMARK' ,'@BMP',10,0,  ,  ,'C',  ,'V' ,  ,  , 'mark'   , 'V', 'S' } )
	Aadd(_aHdTpOper ,{'','W1_DESCRI','@!'  ,03,0,"","",'C',"",""})

	// lista de perguntas (parametros)
	aAdd(_vPerg,{"Data De?"     ,"D",8                     ,0,"G",,""   , {{"X1_CNT01","'"+DtoC(mvDataDe) +"'" }} }) //mv_par01
	aAdd(_vPerg,{"Data Até?"    ,"D",8                     ,0,"G",,""   , {{"X1_CNT01","'"+DtoC(mvDataAte)+"'" }} }) //mv_par02
	aAdd(_vPerg,{"Cliente De?"  ,"C",TamSx3("A1_COD")[1]   ,0,"G",,"SA1", {{"X1_VALID","U_FtStrZero()"}} }) //mv_par03
	aAdd(_vPerg,{"Cliente Até?" ,"C",TamSx3("A1_COD")[1]   ,0,"G",,"SA1", {{"X1_VALID","U_FtStrZero()"}} }) //mv_par04
	aAdd(_vPerg,{"Nº OS De?"    ,"C",TamSx3("Z05_NUMOS")[1],0,"G",,""   , {{"X1_VALID","U_FtStrZero()"}} }) //mv_par05
	aAdd(_vPerg,{"Nº OS Até?"   ,"C",TamSx3("Z05_NUMOS")[1],0,"G",,""   , {{"X1_VALID","U_FtStrZero()"}} }) //mv_par06

	// cria grupo de perguntas
	//	U_FtCriaSX1( _cPerg, _vPerg )

	If !LockByName("TWMSA009" + cusername,.T.,.T.,.T.)
		MsgAlert("Rotina já está aberta.")
		Return
	EndIf

	// apresenta perguntas na tela
	If ! Pergunte(_cPerg, .t.)
		Return
	EndIf

	// atualiza as variaveis
	mvDataDe   := mv_par01
	mvDataAte  := mv_par02
	mvCliDe    := mv_par03
	mvCliAte   := mv_par04
	mvNumOSDe  := mv_par05
	mvNumOSAte := mv_par06

	// define as cores da legenda
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'AG'","BR_VERMELHO"}) // Aguardando
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'EX'","BR_AZUL"    }) // Em Execução
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'IN'","BR_AMARELO" }) // Interrompida
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'AN'","BR_CINZA"   }) // Em Análise
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'BL'","BR_PRETO"   }) // Bloqueada
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'FI'","BR_VERDE"   }) // Finalizada
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'PL'","BR_MARROM"  }) // Planejada
	aAdd(_aCoresLeg,{"(_cAlTrOrdServ)->Z06_STATUS == 'CA'","BR_CANCEL"  }) // Cancelada

	// faz primeira atualização dos dados na tela
	If !(sfRfrDados( .T. ))
		// se falhou, fecha tela
		Return ()
	EndIf

	// monta o dialogo do monitor
	_oDlgMntOrdServ := MSDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"Monitor de Serviços",,,.F.,,,,,,.T.,,,.T. )
	_oDlgMntOrdServ:lMaximized := .T.

	// cria o panel do cabecalho (opcoes da pesquisa)
	_oPnlCabec := TPanel():New(000,000,'Monitor de Serviços',_oDlgMntOrdServ,_oFntCabec,.T.,.F.,,,000,025,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// monta um Menu Suspenso
	_oMnuPrin1 := TMenuBar():New(_oDlgMntOrdServ)
	_oMnuPrin1:SetCss("QMenuBar{background-color:#424242;color:#ffffff}")
	_oMnuPrin1:Align     := CONTROL_ALIGN_TOP
	_oMnuPrin1:bRClicked := {||}
	_oMnuPrin1:oFont := _oFntMenu

	// sub-opcao
	_oMnu1OrdSrv := TMenu():New(0,0,0,0,.T.,,_oDlgMntOrdServ)
	_oMnu1Devol  := TMenu():New(0,0,0,0,.T.,,_oDlgMntOrdServ)
	_oMnu1Tools  := TMenu():New(0,0,0,0,.T.,,_oDlgMntOrdServ)

	// adciona opcao principal do menu
	_oMnuPrin1:AddItem('&Ordens de Serviço', _oMnu1OrdSrv, .T.)
	_oMnuPrin1:AddItem('&Devoluções'       , _oMnu1Devol , .T.)
	_oMnuPrin1:AddItem('&Ferramentas'      , _oMnu1Tools, .T.)

	// sub-opcoes - ordens de servico
	_oMnu1OrdSrv:Add(TMenuItem():New(_oDlgMntOrdServ,'Atualização/Refresh de Dados'                           ,,,,{|| sfRfrDados(.f.)                                                  },,'RELOAD'      ,,,,,,,.T.))
	_oMnu1OrdSrv:Add(TMenuItem():New(_oDlgMntOrdServ,'Planejamento de Recebimento e/ou Expedição'             ,,,,{|| sfPlanejamento()                                                 },,'PMSIMG32'    ,,,,,,,.T.))
	_oMnu1OrdSrv:Add(TMenuItem():New(_oDlgMntOrdServ,'Gerar Transferência entre Endereços'                    ,,,,{|| sfGeraParTrf()                                                   },,'EMPILHADEIRA',,,,,,,.T.))
	_oMnu1OrdSrv:Add(TMenuItem():New(_oDlgMntOrdServ,'Gerar Retrabalho em Paletes'                            ,,,,{|| U_TWMSA028( (_cAlTrOrdServ)->Z05_NUMOS )                         },,'ESTIMG32'    ,,,,,,,.T.))
	_oMnu1OrdSrv:Add(TMenuItem():New(_oDlgMntOrdServ,'Gerar Abastecimento de Picking'                         ,,,,{|| U_WMSA009G()                                                     },,'QIPIMG32'    ,,,,,,,.T.))
	_oMnu1OrdSrv:Add(TMenuItem():New(_oDlgMntOrdServ,'Visualizar Detalhes da Ordem de Serviço (duplo clique)' ,,,,{|| U_TWMSA023( (_cAlTrOrdServ)->Z05_NUMOS )                         },,'WATCH'       ,,,,,,,.T.))
	_oMnu1OrdSrv:Add(TMenuItem():New(_oDlgMntOrdServ,'Reabrir Ordem de Serviço'                               ,,,,{|| U_WMSA009I( (_cAlTrOrdServ)->Z05_NUMOS, .T.)                     },,'DEVOLNF'     ,,,,,,,.T.))
	_oMnu1OrdSrv:Add(TMenuItem():New(_oDlgMntOrdServ,'Excluir Ordem de Serviço'                               ,,,,{|| U_WMSA009H( (_cAlTrOrdServ)->Z05_NUMOS, .F.)                     },,'EXCLUIR'     ,,,,,,,.T.))
	_oMnu1OrdSrv:Add(TMenuItem():New(_oDlgMntOrdServ,'Finalizar endereçamento pelo planejado'                 ,,,,{|| U_WMSA009M( (_cAlTrOrdServ)->Z05_NUMOS )                         },,'QTDREJ'      ,,,,,,,.T.))
	_oMnu1OrdSrv:Add(TMenuItem():New(_oDlgMntOrdServ,'Autorizar recebimento com TFAA (gerente)'               ,,,,{|| sfLibTfaa ( (_cAlTrOrdServ)->Z05_NUMOS )                         },,'AVG_DOC_VIEW',,,,,,,.T.))
	_oMnu1OrdSrv:Add(TMenuItem():New(_oDlgMntOrdServ,'Atribuir Operadores'                                    ,,,,{|| U_WMSA009L( (_cAlTrOrdServ)->Z05_NUMOS )                         },,'CLIENTE'     ,,,,,,,.T.))
	_oMnu1OrdSrv:Add(TMenuItem():New(_oDlgMntOrdServ,'Sair'                                                   ,,,,{|| _oDlgMntOrdServ:End()                                            },,'FINAL'       ,,,,,,,.T.))

	// sub-opcoes - devoluções
	//	_oMnu1Devol:Add(TMenuItem():New(_oDlgMntOrdServ, 'Cancelar Carregamento'                                  ,,,,{|| U_WMSA009E()                                                     },,'ESTOMOVI'    ,,,,,,,.T.))
	_oMnu1Devol:Add(TMenuItem():New(_oDlgMntOrdServ, 'Cancelar carregamento de pedido'                                  ,,,,{|| U_WMSA009E()                                                     },,'ESTOMOVI'    ,,,,,,,.T.))

	// sub-opcoes - ferramentas
	_oMnu1Tools:Add(TMenuItem():New(_oDlgMntOrdServ, 'Filtrar Dados'                                          ,,,,{|| sfFilDados()                                                     },,'FILTRO'      ,,,,,,,.T.))
	_oMnu1Tools:Add(TMenuItem():New(_oDlgMntOrdServ, 'Definir novos parâmetros de consulta'                   ,,,,{|| sfDefParam(.f.)                                                  },,'PARAMETROS'  ,,,,,,,.T.))
	_oMnu1Tools:Add(TMenuItem():New(_oDlgMntOrdServ, 'Exportar dados para arquivo EDI'                        ,,,,{|| sfGerArEDI((_cAlTrOrdServ)->Z05_NUMOS,(_cAlTrOrdServ)->DSC_OPER) },,'HISTORIC'    ,,,,,,,.T.))
	_oMnu1Tools:Add(TMenuItem():New(_oDlgMntOrdServ, 'Distribuir Endereçamento Pre-Conferencia'               ,,,,{|| sfDistrNF((_cAlTrOrdServ)->Z05_NUMOS,(_cAlTrOrdServ)->Z05_CLIENT,(_cAlTrOrdServ)->Z05_LOJA)},,'S4WB014B'    ,,,,,,,.T.))
	_oMnu1Tools:Add(TMenuItem():New(_oDlgMntOrdServ, 'Impressão de Etiquetas (Produto/Volumes)'               ,,,,{|| U_WMSA009C( (_cAlTrOrdServ)->Z05_NUMOS )                         },,'ACDIMG32'    ,,,,,,,.T.))
	_oMnu1Tools:Add(TMenuItem():New(_oDlgMntOrdServ, 'Legenda'                                                ,,,,{|| sfLegenda()                                                      },,'COLOR'       ,,,,,,,.T.))
	_oMnu1Tools:Add(TMenuItem():New(_oDlgMntOrdServ, 'Consulta Detalhada de Etiquetas'                        ,,,,{|| U_WMSA009K()                                                     },,'BMPCONS'     ,,,,,,,.T.))
	//	_oMnu1Tools:Add(TMenuItem():New(_oDlgMntOrdServ, 'Encerrramento de OS de Expedição'                       ,,,,{|| U_WMSA023A( (_cAlTrOrdServ)->Z05_NUMOS )                         },,'APTIMG32'    ,,,,,,,.T.))

	// browse com a listagem dos servicos
	_oBrwOrdServ := MsSelect():New((_cAlTrOrdServ),,,_aHdOrdServ,,,{000,000,400,1000},,,_oDlgMntOrdServ,,_aCoresLeg)
	_oBrwOrdServ:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwOrdServ:oBrowse:oFont := _oFntBrowse

	// funcao que abre os detalhes da ordem de servico
	_oBrwOrdServ:oBrowse:bLdblClick := {|| U_TWMSA023( (_cAlTrOrdServ)->Z05_NUMOS ) }

	// cria o panel do rodapé (informações adicionais)
	_oPnlRoda := TPanel():New(000,000, /* Titulo */ ,_oDlgMntOrdServ,_oFntRoda,.T.,.F.,,,000,025,.T.,.F. )
	_oPnlRoda:Align:= CONTROL_ALIGN_BOTTOM

	// informações do rodapé
	_oSayRoda1 := TSay():New(010,003,{|| "Quantidade de registros: " + Str(_nQtdRoda1) },_oPnlRoda,,,.F.,.F.,.F.,.T.)
	_oSayRoda2 := TSay():New(010,350,{|| "Existem filtros aplicados!" },_oPnlRoda,,,.F.,.F.,.F.,.T.,CLR_RED)
	_oSayRoda2:lVisible = .F.

	// inclui teclas de atalho
	SetKey(VK_F5 , {|| sfRfrDados(.f.) } )

	// ativa a tela
	ACTIVATE MSDIALOG _oDlgMntOrdServ CENTERED

	// limpa teclas de atalho
	SetKey(VK_F5 , {|| Nil})

	UnLockByName("TWMSA009" + cusername,.T.,.T.,.T.)

	// apaga tabelas temporárias
	_cTrOrdServ:Delete()

	If ValType(_cTrPlanej) == "O"
		_cTrPlanej:Delete()
	EndIf
	If ValType(_cArqTmp) == "O"
		_cArqTmp:Delete()
	EndIf

Return()

// ** funcao usada para atualizar os dados
Static Function sfGerArEDI(mvNumOs,mvTpOs)

	If Alltrim(mvTpOs) == 'RECEBIMENTO'
		U_TWMSA030(mvNumOs,"E")
	ElseIf Alltrim(mvTpOs) == 'EXPEDICAO'
		U_TWMSA030(mvNumOs,"S")
	EndIf

Return()

// ** funcao usada para atualizar os dados
Static Function sfRfrDados(mvFirst)
	Local _lRet := .f.
	MsgRun("Atualizando a Tela do Monitor de Serviços...", "Aguarde...", {|| CursorWait(), _lRet := sfSelDados(mvFirst, Nil), CursorArrow()})
Return _lRet

// ** funcao para filtrar servicos de acordo com os parametros e configuracao do operador
Static Function sfSelDados(mvFirst, mvNumOs)
	local _cQuery     := ""
	local _nRetSta    := 0
	local _aRetSQL    := {}
	local _aTmpFiltro := {}
	local _nTmpFiltro
	// area inicial do TRB
	local _aAreaTRB  := IIf(mvFirst,Nil,(_cAlTrOrdServ)->(GetArea()))
	Local _nPos      := 0

	// variaveis temporias
	local _nTrf

	// numero das ordens de servico atualizadas no browse
	local _cSqlNrOS := ""

	// tabela de classificao do status da OS
	local _cTabClas := SuperGetMV('TC_CLASOS',.F.,"BL=3;AN=1;IN=4;PL=6;AG=5;EX=2;FI=7")
	local _aTabClas := Separa(_cTabClas,";")
	local _nTabClas
	local _aTmpStsCla

	// valor padrao para nr de OS
	Default mvNumOs  := ""

	// abre o alias
	dbSelectArea("Z05")
	dbSelectArea("Z06")
	dbSelectArea("Z18")

	// limite de busca pelas datas
	If (DateDiffDay(mvDataDe, mvDataAte) > 5)
		MsgAlert("Datas selecionadas excedem 5 dias. Diminua o período de consulta e tente novamnente.")
		Return ( .F. )
	EndIf

	// busca as movimentacoes com as tarefas para poder criar as colunas dinamicamente.
	_cQuery := "SELECT DISTINCT Z06_TAREFA, LTRIM(RTRIM(SX5TRF.X5_DESCRI)) DSC_TAREFA "
	// cabecalho da OS
	_cQuery += "FROM "+RetSqlName("Z05")+" Z05 (nolock) "
	// itens da ordem de servicos
	_cQuery += "INNER JOIN "+RetSqlName("Z06")+" Z06 (nolock) ON "+RetSqlCond("Z06")+" AND Z06_NUMOS = Z05_NUMOS "
	// cad. de tarefas
	_cQuery += "INNER JOIN "+RetSqlName("SX5")+" SX5TRF (nolock) ON SX5TRF.X5_FILIAL = '"+xFilial("SX5")+"' AND SX5TRF.D_E_L_E_T_ = ' ' AND SX5TRF.X5_TABELA = 'L2' AND SX5TRF.X5_CHAVE = Z06_TAREFA "
	// filtro da movimentacoes
	_cQuery += "WHERE "+RetSqlCond("Z05")+" "
	// filtro especifico para usuario do tipo Monitor
	_cQuery += cQryFilMnt
	// filtro por cliente
	_cQuery += "AND Z05_CLIENT BETWEEN '"+mvCliDe+"' AND '"+mvCliAte+"' "
	// filtro por data
	_cQuery += "AND Z05_DTEMIS BETWEEN '"+DtoS(mvDataDe)+"' AND '"+DtoS(mvDataAte)+"' "
	// filtro por OS
	_cQuery += "AND Z05_NUMOS BETWEEN '"+mvNumOSDe+"' AND '"+mvNumOSAte+"' "
	// filtra os inventários, para que não apareçam na lista
	_cQuery += "AND Z06_TAREFA <> 'T02' "

	memowrit("c:\query\twmsa009_sfSelDados_cod_srv.txt",_cQuery )

	// atualiza variavel
	_aRetSQL := U_SqlToVet(_cQuery)

	// monta a estrutura do arquivo de trabalho
	If (mvFirst)
		aAdd(_aStOrdServ,{"Z06_STATUS"  ,"C", TamSx3("Z06_STATUS")[1]   ,0})
		aAdd(_aStOrdServ,{"Z05_NUMOS"   ,"C", TamSx3("Z05_NUMOS")[1]    ,0})  ; aAdd(_aHdOrdServ,{"Z05_NUMOS" ,"","Número O.S."     , ""})
		aAdd(_aStOrdServ,{"Z05_DTEMIS"  ,"D", TamSx3("Z05_DTEMIS")[1]   ,0})  ; aAdd(_aHdOrdServ,{"Z05_DTEMIS","","Date Emissão"    , ""})
		aAdd(_aStOrdServ,{"IT_CODREF"   ,"C", (TamSx3("Z05_CESV")[1]+6) ,0})  ; aAdd(_aHdOrdServ,{"IT_CODREF" ,"","Cod.Ref."        , ""})
		aAdd(_aStOrdServ,{"DSC_OPER"    ,"C", 15                        ,0})  ; aAdd(_aHdOrdServ,{"DSC_OPER"  ,"","Operação"        , ""})
		aAdd(_aStOrdServ,{"Z05_CLIENT"  ,"C", TamSx3("Z05_CLIENT")[1]   ,0})
		aAdd(_aStOrdServ,{"Z05_LOJA"    ,"C", TamSx3("Z05_LOJA")[1]     ,0})
		aAdd(_aStOrdServ,{"A1_NOME"     ,"C", TamSx3("A1_NOME")[1]      ,0})  ; aAdd(_aHdOrdServ,{"A1_NOME"   ,"","Cliente"    ,"@!"})
		aAdd(_aStOrdServ,{"REL_PEDIDO"  ,"C", 30                        ,0})  ; aAdd(_aHdOrdServ,{"REL_PEDIDO" ,"","Pedidos cliente", ""})
		aAdd(_aStOrdServ,{"CLI_PED"     ,"C", 30                        ,0})  ; aAdd(_aHdOrdServ,{"CLI_PED" ,"","Cliente Pedido", ""}) //Gustavo SLA / TI, 28/08/2018, melhoria 313
		aAdd(_aStOrdServ,{"REL_NF_CLI"  ,"C", 30                        ,0})  ; aAdd(_aHdOrdServ,{"REL_NF_CLI" ,"","NF Cliente"     , ""})

		// criando as colunas conforme retorno da consulta SQL
		For _nTrf := 1 To Len(_aRetSQL)

			// inclui campo da estrutura do TRB / campo do browse
			aAdd(_aStOrdServ,{"TRF" + Alltrim(_aRetSQL[_nTrf][1]), "N", 6, 2 }) ; aAdd(_aHdOrdServ,{"TRF" + Alltrim(_aRetSQL[_nTrf][1]), "" , Alltrim(_aRetSQL[_nTrf][2]), "@E 999.99 %"})

		Next _nTrf

		// fecha alias do TRB
		If (Select(_cAlTrOrdServ)<>0)
			dbSelectArea(_cAlTrOrdServ)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cTrOrdServ := FWTemporaryTable():New( _cAlTrOrdServ )
		_cTrOrdServ:SetFields( _aStOrdServ )
		_cTrOrdServ:AddIndex("01", {"Z05_NUMOS"} )
		_cTrOrdServ:Create()

		(_cAlTrOrdServ)->(dbSetOrder(1))

	EndIf

	// limpa o conteudo do TRB
	If (!mvFirst)
		dbSelectArea(_cAlTrOrdServ)
		__DbZap()
	EndIf

	// busca as movimentacoes para criação do TRB.
	_cQuery := "SELECT "
	// status da ordem de servico
	_cQuery += "(SELECT TOP 1 Z06_STATUS "
	// itens da ordem de servico
	_cQuery += "        FROM   "+RetSqlTab("Z06") + " (nolock) "
	// filtro padrao
	_cQuery += "        WHERE  "+RetSqlCond("Z06")
	// numero da OS
	_cQuery += "               AND Z06_NUMOS = Z05_NUMOS "
	// ordem conforme tabela de classificacao
	_cQuery += "        ORDER  BY "
	// inicio da condicao de ordem de dados
	_cQuery += "CASE WHEN Z06_STATUS = 'ZZ' THEN 100 "
	// varre a tabela de classificacao
	For _nTabClas := 1 to Len(_aTabClas)

		// separa os dados
		_aTmpStsCla := Separa(_aTabClas[_nTabClas], "=", .f.)

		// complementa a query
		_cQuery += " WHEN Z06_STATUS = '"+_aTmpStsCla[1]+"' THEN "+_aTmpStsCla[2]

	Next _nTabClas
	// final da condicao de ordem de dados
	_cQuery += " ELSE 0 "
	_cQuery += " END) Z06_STATUS, "
	// nr da os
	_cQuery += "Z05_NUMOS, "
	// data de emissao
	_cQuery += "Z05_DTEMIS, "
	// descricao da operacao
	_cQuery += "CASE "
	_cQuery += "  WHEN Z05_TPOPER = 'E' THEN 'RECEBIMENTO' "
	_cQuery += "  WHEN Z05_TPOPER = 'S' THEN 'EXPEDICAO' "
	_cQuery += "  WHEN Z05_TPOPER = 'I' THEN 'INTERNA' "
	_cQuery += "END DSC_OPER, "
	// cliente
	_cQuery += "Z05_CLIENT, Z05_LOJA, A1_NOME, "
	// programacao ou carga
	_cQuery += "CASE "
	_cQuery += "  WHEN Z05_TPOPER = 'E' THEN 'PG: ' + Z05_PROCES "
	_cQuery += "  WHEN Z05_TPOPER = 'S' AND Z05_CARGA != '' AND Z05_ONDSEP  = '' THEN 'CG: ' + Z05_CARGA "
	_cQuery += "  WHEN Z05_TPOPER = 'S' AND Z05_CARGA = '' AND Z05_ONDSEP != '' THEN 'ON: ' + Z05_ONDSEP "
	_cQuery += "  WHEN Z05_TPOPER = 'S' AND Z05_CARGA = '' AND Z05_ONDSEP = '' THEN 'CESV: ' + Z05_CESV "
	_cQuery += "  ELSE '' "
	_cQuery += "END IT_CODREF, "
	// relacao de pedidos do cliente da ordem de servico
	_cQuery += "CASE "
	_cQuery += "WHEN Z05_TPOPER = 'S' AND Z05_CARGA = '' AND Z05_ONDSEP = '' THEN ("    // carregamento final modelo 2.0 -> pega por CESV
	_cQuery += " SELECT RTRIM(C5_ZPEDCLI) + ';' FROM " + RetSqlTab("SC5") + " WITH (NOLOCK) "
	_cQuery += " WHERE " + RetSqlCond("SC5")
	_cQuery += " AND C5_NUM IN (SELECT Z43_PEDIDO FROM " + RetSqlTab("Z43") + " (nolock)  WHERE " + RetSqlCond("Z43")
	_cQuery += " AND Z43_CESV = Z05_CESV  AND Z43_NUMOS = Z05_NUMOS)"
	_cQuery += " FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(400)' )"
	_cQuery += "WHEN Z05_TPOPER = 'S' AND ( Z05_CARGA = '' AND Z05_ONDSEP != '' ) THEN (" // saída por geração automática (onda de separação)
	_cQuery += " SELECT RTRIM(C5_ZPEDCLI) + ';' FROM " + RetSqlTab("SC5") + " WITH (NOLOCK) "
	_cQuery += " WHERE  " + RetSqlCond("SC5")
	_cQuery += " AND C5_TIPOOPE = 'P' AND C5_CLIENTE = Z05_CLIENT AND C5_LOJACLI = Z05_LOJA  "
	_cQuery += " AND C5_ZONDSEP = Z05_ONDSEP AND C5_ZPEDCLI != '' "
	_cQuery += " FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(400)') "

	_cQuery += "WHEN Z05_TPOPER = 'S' AND ( Z05_CARGA != '' AND Z05_ONDSEP = '' ) THEN (" // saída por OS tradicional (manual)
	_cQuery += " SELECT RTRIM(C5_ZPEDCLI) + ';' FROM " + RetSqlTab("SC5") + " WITH (NOLOCK) "
	_cQuery += " WHERE  " + RetSqlCond("SC5")
	_cQuery += " AND C5_TIPOOPE = 'P' AND C5_CLIENTE = Z05_CLIENT AND C5_LOJACLI = Z05_LOJA  "
	_cQuery += " AND C5_ZCARGA = Z05_CARGA AND C5_ZPEDCLI != '' "
	_cQuery += " FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(400)') "

	_cQuery += "ELSE '' END AS REL_PEDIDO, "

	// primeiro nome dos clientes dos pedidos
	_cQuery += " SUBSTRING(CASE "
	_cQuery += "WHEN Z05_TPOPER = 'S' AND Z05_CARGA = '' AND Z05_ONDSEP = '' THEN ("    // carregamento final modelo 2.0 -> pega por CESV
	_cQuery += " SELECT SubString(Rtrim(C5_ZCLIENT),1, CHARINDEX(' ',C5_ZCLIENT,1)) + ';' FROM " + RetSqlTab("SC5") + " WITH (NOLOCK) "
	_cQuery += " WHERE " + RetSqlCond("SC5")
	_cQuery += " AND C5_NUM IN (SELECT Z43_PEDIDO FROM " + RetSqlTab("Z43") + " (nolock)  WHERE " + RetSqlCond("Z43")
	_cQuery += " AND Z43_CESV = Z05_CESV  AND Z43_NUMOS = Z05_NUMOS)"
	_cQuery += " FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(400)' )"
	_cQuery += "WHEN Z05_TPOPER = 'S' AND ( Z05_CARGA = '' AND Z05_ONDSEP != '' ) THEN (" // saída por geração automática (onda de separação)
	_cQuery += " SELECT SubString(Rtrim(C5_ZCLIENT),1, CHARINDEX(' ',C5_ZCLIENT,1)) + ';' FROM " + RetSqlTab("SC5") + " WITH (NOLOCK) "
	_cQuery += " WHERE  " + RetSqlCond("SC5")
	_cQuery += " AND C5_TIPOOPE = 'P' AND C5_CLIENTE = Z05_CLIENT AND C5_LOJACLI = Z05_LOJA  "
	_cQuery += " AND C5_ZONDSEP = Z05_ONDSEP AND C5_ZPEDCLI != '' "
	_cQuery += " FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(400)') "

	_cQuery += "WHEN Z05_TPOPER = 'S' AND ( Z05_CARGA != '' AND Z05_ONDSEP = '' ) THEN (" // saída por OS tradicional (manual)
	_cQuery += " SELECT SubString(Rtrim(C5_ZCLIENT),1, CHARINDEX(' ',C5_ZCLIENT,1)) + ';' FROM " + RetSqlTab("SC5") + " WITH (NOLOCK) "
	_cQuery += " WHERE  " + RetSqlCond("SC5")
	_cQuery += " AND C5_TIPOOPE = 'P' AND C5_CLIENTE = Z05_CLIENT AND C5_LOJACLI = Z05_LOJA  "
	_cQuery += " AND C5_ZCARGA = Z05_CARGA AND C5_ZPEDCLI != '' "
	_cQuery += " FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(400)') "

	_cQuery += "ELSE '' END,1,50) AS CLI_PED, "

	// relacao de notas fiscais do cliente da ordem de servico
	_cQuery += "CASE "
	_cQuery += "WHEN Z05_TPOPER = 'S' AND Z05_CARGA = '' AND Z05_ONDSEP = '' THEN ("    // carregamento final modelo 2.0 -> pega por CESV
	_cQuery += " SELECT RTRIM(C5_ZDOCCLI) + ';' FROM " + RetSqlTab("SC5") + " WITH (NOLOCK) "
	_cQuery += " WHERE " + RetSqlCond("SC5")
	_cQuery += " AND C5_NUM IN (SELECT Z43_PEDIDO FROM " + RetSqlTab("Z43") + " (nolock)  WHERE " + RetSqlCond("Z43")
	_cQuery += " AND Z43_CESV = Z05_CESV  AND Z43_NUMOS = Z05_NUMOS)"
	_cQuery += " FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(400)' ) "
	_cQuery += "WHEN Z05_TPOPER = 'S' AND ( Z05_CARGA = '' AND Z05_ONDSEP != '' ) THEN (" // saída por geração de OS automática (onda)
	_cQuery += " SELECT RTRIM(C5_ZDOCCLI) + ';' "
	_cQuery += "                 FROM   " + RetSqlTab("SC5") + " WITH (NOLOCK) "
	_cQuery += "                 WHERE  " + RetSqlCond("SC5")
	_cQuery += "                        AND C5_TIPOOPE = 'P' "
	_cQuery += "                        AND C5_CLIENTE = Z05_CLIENT "
	_cQuery += "                        AND C5_LOJACLI = Z05_LOJA "
	_cQuery += "                        AND C5_ZONDSEP = Z05_ONDSEP "
	_cQuery += "                        AND C5_ZDOCCLI != '' "
	_cQuery += "                 FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(400)') "
	_cQuery += "WHEN Z05_TPOPER = 'S' AND ( Z05_CARGA != '' AND Z05_ONDSEP = '' ) THEN (" // saída por geração de OS tradicional (carga sem onda)
	_cQuery += " SELECT RTRIM(C5_ZDOCCLI) + ';' "
	_cQuery += "                 FROM   " + RetSqlTab("SC5") + " WITH (NOLOCK) "
	_cQuery += "                 WHERE  " + RetSqlCond("SC5")
	_cQuery += "                        AND C5_TIPOOPE = 'P' "
	_cQuery += "                        AND C5_CLIENTE = Z05_CLIENT "
	_cQuery += "                        AND C5_LOJACLI = Z05_LOJA "
	_cQuery += "                        AND C5_ZCARGA = Z05_CARGA "
	_cQuery += "                        AND C5_ZDOCCLI != '' "
	_cQuery += "                 FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(400)') "
	_cQuery += "WHEN Z05_TPOPER = 'E' AND Z05_CESV != '' THEN ( "
	_cQuery += "  SELECT DISTINCT RTRIM(Z04_NF) + ';' "
	_cQuery += "  FROM " + RetSqlTab("Z04") + " (NOLOCK) "
	_cQuery += "  WHERE " + RetSqlCond("Z04")
	_cQuery += "         AND Z04_CESV = Z05_CESV"
	_cQuery += "  FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(400)') "
	_cQuery += "ELSE '' END AS REL_NF_CLI, "
	// total/percentual por tarefa
	_cQuery += "COALESCE([002], 0) TRF002, "
	_cQuery += "COALESCE([003], 0) TRF003, "
	_cQuery += "COALESCE([004], 0) TRF004, "
	_cQuery += "COALESCE([007], 0) TRF007, "
	_cQuery += "COALESCE([009], 0) TRF009, "
	_cQuery += "COALESCE([013], 0) TRF013, "
	_cQuery += "COALESCE([T05], 0) TRFT05, "
	//	_cQuery += "COALESCE([T06], 0) TRFT06, "
	_cQuery += "COALESCE([T07], 0) TRFT07, "
	_cQuery += "COALESCE([T08], 0) TRFT08, "
	_cQuery += "COALESCE([T09], 0) TRFT09 "

	// sub-select com os filtros necessarios
	_cQuery += "FROM ( "
	_cQuery += "SELECT Z06_FILIAL, "
	_cQuery += "       Z06_NUMOS, "
	_cQuery += "       Z06_TAREFA, "
	_cQuery += "       CASE "

	// 002-Mov.Merc/Apanhe / 009-Enderecamento / 013-Transferencia
	_cQuery += "         WHEN Z06_TAREFA IN ( '002', '009', '013', 'T08' ) THEN (SELECT SUM(CASE "
	_cQuery += "                                                                              WHEN Z08_STATUS = 'R' THEN 1 "
	_cQuery += "                                                                              ELSE 0 "
	_cQuery += "                                                                            END) * 100 / CASE "
	_cQuery += "                                                                                           WHEN Count(*) = 0 THEN 1 "
	_cQuery += "                                                                                           ELSE Count(*) "
	_cQuery += "                                                                                         END "
	_cQuery += "                                                                 FROM   "+RetSqlName("Z08")+" Z08 WITH (NOLOCK) "
	_cQuery += "                                                                 WHERE  "+RetSqlCond("Z08")
	_cQuery += "                                                                        AND Z08_NUMOS = Z06_NUMOS "
	_cQuery += "                                                                        AND Z08_SEQOS = Z06_SEQOS) "

	// 003-Conferencia de Entrada / T03 - Cancelamento de carregamento
	_cQuery += "           WHEN Z06_SERVIC IN ('003', 'T03') "
	_cQuery += "                AND Z06_TAREFA IN ( '003' ) THEN (SELECT ( Isnull((SELECT Sum(Z07_QUANT) FROM "+RetSqlTab("Z07")+" WITH (NOLOCK) WHERE "+RetSqlCond("Z07")+" AND Z07_NUMOS = Z06_NUMOS AND Z07_SEQOS = Z06_SEQOS), 0) "
	_cQuery += "                                                           + Isnull((SELECT Sum(Z42_QTDORI - Z42_QTDCON) FROM "+RetSqlTab("Z42")+"  (nolock) WHERE "+RetSqlCond("Z42")+" AND Z42_CODIGO = Z05_TFAA), 0) ) * 100 / Sum(Z04_QUANT) "
	_cQuery += "                                                  FROM   "+RetSqlTab("Z04")+" WITH (NOLOCK) "
	_cQuery += "                                                  WHERE  "+RetSqlCond("Z04")
	_cQuery += "                                                         AND Z04_CESV = Z05_CESV "
	_cQuery += "                                                         AND ( ( Z04_SEQKIT = ' ' ) "
	_cQuery += "                                                                OR ( Z04_SEQKIT != ' ' "
	_cQuery += "                                                                     AND Z04_NUMSEQ != ' ' ) )) "

	// 001-Conferencia de Saída
	_cQuery += "         WHEN Z06_SERVIC IN ( '001' ) AND Z06_TAREFA IN ( '003','T07' ) THEN ( CASE WHEN Z06_TAREFA = 'T07' THEN ( CASE WHEN Z06_STATUS = 'FI' THEN 100 ELSE 0 END )
	_cQuery += "         															ELSE ((SELECT Isnull((SELECT Sum(Z07_QUANT) "
	_cQuery += "                                                                       FROM   " + RetSqlTab("Z07") + " WITH (NOLOCK) "
	_cQuery += "                                                                       WHERE  " + RetSqlCond("Z07")
	_cQuery += "                                                                              AND Z07_NUMOS = Z06_NUMOS "
	_cQuery += "                                                                              AND Z07_SEQOS = Z06_SEQOS), 0)) * 100 / (SELECT Sum(Z08_QUANT) "
	_cQuery += "                                                                                                                       FROM   "+RetSqlTab("Z08")+" WITH (NOLOCK) "
	_cQuery += "                                                                                                                       WHERE  "+RetSqlCond("Z08")+" "
	_cQuery += "                                                                                                                         AND Z08_NUMOS = Z06_NUMOS)) END ) "

	// 004-Carregamento
	_cQuery += "         WHEN Z06_TAREFA = '004' THEN (SELECT ((SELECT Isnull(Sum(Z07_QUANT), 0) "
	_cQuery += "                                                           FROM   " + RetSqlTab("Z07") + " WITH (NOLOCK) "
	_cQuery += "                                                           WHERE  " + RetSqlCond("Z07")
	_cQuery += "                                                                  AND Z07_SEQOS = Z06_SEQOS "
	_cQuery += "                                                                  AND Z07_NUMOS = Z06_NUMOS) * 100) / Sum(C6_QTDVEN) "
	_cQuery += "                                                   FROM   " + RetSqlTab("SC6")
	_cQuery += "                                                   WHERE  " + RetSqlCond("SC6")
	_cQuery += "                                                       AND C6_NUM IN (SELECT Z43_PEDIDO "
	_cQuery += "                                                                      FROM   " + RetSqlTab("Z43") + " (NOLOCK) "
	_cQuery += "                                                                      WHERE  " + RetSqlCond("Z43")
	_cQuery += "                                                                             AND Z43_STATUS = 'R' "
	_cQuery += "                                                                             AND Z43_NUMOS = Z06_NUMOS)) "

	// 007-Montagem de Palete/Volumes
	_cQuery += "         WHEN Z06_TAREFA = '007' THEN (SELECT (SELECT Isnull(Sum(Z07_QUANT), 0) "
	_cQuery += "                                                           FROM   " + RetSqlTab("Z07") + " WITH (NOLOCK) "
	_cQuery += "                                                           WHERE  " + RetSqlCond("Z07")
	_cQuery += "                                                                  AND Z07_SEQOS = Z06_SEQOS "
	_cQuery += "                                                                  AND Z07_NUMOS = Z06_NUMOS) * 100 / Sum(Z08_QUANT) "
	_cQuery += "                                                   FROM   "+RetSqlName("Z08")+" Z08  (nolock)  "
	_cQuery += "                                                   WHERE  "+RetSqlCond("Z08")
	_cQuery += "                                                          AND Z08_NUMOS = Z06_NUMOS) "

	// T09 - apanhe livre
	_cQuery += " WHEN Z06_TAREFA = 'T09'  THEN "
	_cQuery += " ( SELECT ROUND(( (SELECT SUM(Z08_QUANT) FROM " + RetSqlTab("Z08") + " WITH (NOLOCK) "
	_cQuery += "                  WHERE  " + RetSqlCond("Z08") + " AND Z08_NUMOS = Z06_NUMOS AND Z08_SEQOS = Z06_SEQOS "
	_cQuery += "                  AND Z08_STATUS = 'R') * 100 )"
	_cQuery += " / "
	_cQuery += "                 (SELECT SUM(Z08_QUANT) FROM " + RetSqlTab("Z08") + " WITH (NOLOCK) "
	_cQuery += "                  WHERE  " + RetSqlCond("Z08") + " AND Z08_NUMOS = Z06_NUMOS AND Z08_SEQOS = Z06_SEQOS "
	_cQuery += "                  AND Z08_STATUS = 'O') "
	_cQuery += " , 2)                "
	_cQuery += " )                                                                                                       "

	// demais não especificados
	_cQuery += "         ELSE 0 "
	_cQuery += "       END QTD_TOTAL "

	// itens da ordem de servico
	_cQuery += "FROM   "+RetSqlName("Z06")+" Z06 (NOLOCK) "

	// cab. ordem de servico
	_cQuery += "       INNER JOIN "+RetSqlName("Z05")+" Z05 (NOLOCK) "
	_cQuery += "               ON "+RetSqlCond("Z05")
	_cQuery += "                  AND Z05_NUMOS = Z06_NUMOS "

	// filtro especifico para usuario do tipo Monitor
	_cQuery += cQryFilMnt
	// filtro por cliente
	_cQuery += "                  AND Z05_CLIENT BETWEEN '"+mvCliDe+"' AND '"+mvCliAte+"' "
	// filtro por data
	_cQuery += "                  AND Z05_DTEMIS BETWEEN '"+DtoS(mvDataDe)+"' AND '"+DtoS(mvDataAte)+"' "
	// filtro por OS
	_cQuery += "                  AND Z05_NUMOS  BETWEEN '"+mvNumOSDe+"' AND '"+mvNumOSAte+"' "
	// Filtro por OS
	If ( ! Empty(mvNumOs) )
		_cQuery += "                  AND Z05_NUMOS IN (" + mvNumOs + ")"
	EndIf
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z06")
	// para não mostrar as OS de Inventário
	_cQuery += "AND Z06_TAREFA <> 'T02') REL_ORD_SRV "

	// tabela de PIVO / RESUMO
	_cQuery += "       PIVOT ( Sum(QTD_TOTAL) "
	_cQuery += "             FOR Z06_TAREFA IN ([002], "
	_cQuery += "                                [003], "
	_cQuery += "                                [004], "
	_cQuery += "                                [007], "
	_cQuery += "                                [009], "
	_cQuery += "                                [013], "
	_cQuery += "                                [T05], "
	//	_cQuery += "                                [T06], "
	_cQuery += "                                [T07], "
	_cQuery += "                                [T08], "
	_cQuery += "                                [T09]) ) TAB_PIV "
	// cab. ordem de servico
	_cQuery += "       INNER JOIN "+RetSqlName("Z05")+" Z05 (NOLOCK) "
	_cQuery += "               ON "+RetSqlCond("Z05")+" "
	_cQuery += "                  AND Z05_NUMOS = Z06_NUMOS "
	// cad. cliente
	_cQuery += "       LEFT JOIN "+RetSqlName("SA1")+" SA1  (nolock) ON "+RetSqlCond("SA1")+" AND A1_COD = Z05_CLIENT AND A1_LOJA = Z05_LOJA "

	// ordem das informacoes
	_cQuery += "ORDER BY Z05_NUMOS"

	memowrit("c:\query\twmsa009_sfSelDados_relacao_ord_srv.txt",_cQuery )

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQuery,_aStOrdServ,(_cAlTrOrdServ))
	// abre o arquivo de trabalho
	dbSelectArea(_cAlTrOrdServ)

	// varre todos o TRB para atualizar o status
	dbSelectArea(_cAlTrOrdServ)
	(_cAlTrOrdServ)->(dbSetOrder(1))
	(_cAlTrOrdServ)->(dbGoTop())

	// limpa variavel do tipo de operação
	_aItTpOper := {}

	While (_cAlTrOrdServ)->( ! Eof() )

		// complementa a relacao de OS
		_cSqlNrOS += (_cAlTrOrdServ)->Z05_NUMOS+"|"

		// verifica se o Tipo da Operacao ja esta na lista
		If (aScan(_aItTpOper,{|x| (x[2] == (_cAlTrOrdServ)->DSC_OPER ) }) == 0)
			Aadd(_aItTpOper,{'LBNO', (_cAlTrOrdServ)->DSC_OPER, .F.})
		EndIf

		// proxima OS
		(_cAlTrOrdServ)->(dbSkip())

	EndDo

	// carrega todos os operacoes das ordens de servico
	_cQuery := " SELECT DISTINCT Z18_OPERAD, DCD_NOMFUN, Z18_NUMOS "
	// recursos relacionados na OS
	_cQuery += " FROM "+RetSqlName("Z18")+" Z18 (nolock)  "
	// cad. de recursos humanos
	_cQuery += " INNER JOIN "+RetSqlName("DCD")+" DCD ON "+RetSqlCond("DCD")+" AND Z18_OPERAD = DCD_CODFUN "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond('Z18')
	// numero da OS
	_cQuery += " AND Z18_NUMOS IN "+FormatIn(_cSqlNrOS,"|")+" "
	// ordem dos dados
	_cQuery += " ORDER BY Z18_NUMOS, Z18_OPERAD "

	memowrit("c:\query\twmsa009_sfSelDados_fil_operadores.txt",_cQuery )

	// atualiza variavel temporaria
	_aOsRecHum := U_SqlToVet(_cQuery)

	// limpa variavel do filtro
	_aItRecHum := {}

	// atualiza variavel do filtro
	For _nTmpFiltro := 1 To Len(_aOsRecHum)
		// verifica se o Operador ja esta na lista
		If (aScan(_aItRecHum,{|x| (x[2] == _aOsRecHum[_nTmpFiltro,1]) }) == 0)
			Aadd(_aItRecHum,{'LBNO', _aOsRecHum[_nTmpFiltro,1], _aOsRecHum[_nTmpFiltro,2], .F.})
		EndIf
	Next _nTmpFiltro

	// carrega todos os equipamentos das ordens de servico
	_cQuery := " SELECT DISTINCT Z17_EQUIPA, ZQ_DESCRIC, Z17_NUMOS "
	// equipamentos relacionados na OS
	_cQuery += " FROM "+RetSqlName("Z17")+" Z17 (nolock)  "
	// cad. equipaementos
	_cQuery += " INNER JOIN "+RetSqlName("SZQ")+" SZQ  (nolock) ON "+RetSqlCond("SZQ")+" AND Z17_EQUIPA = ZQ_CODIGO "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond('Z17')
	// numero da OS
	_cQuery += " AND Z17_NUMOS IN "+FormatIn(_cSqlNrOS,"|")+" "
	// ordem dos dados
	_cQuery += " ORDER BY Z17_NUMOS, Z17_EQUIPA "

	memowrit("c:\query\twmsa009_sfSelDados_fil_equipamentos.txt",_cQuery )

	// atualiza variavel temporaria
	_aOsMaqEqu := U_SqlToVet(_cQuery)

	// limpa variável do filtro
	_aItMaqEqu := {}

	// atualiza variavel do filtro
	For _nTmpFiltro := 1 To Len(_aOsMaqEqu)
		// verifica se o Operador ja esta na lista
		If (aScan(_aItMaqEqu,{|x| (x[2] == _aOsMaqEqu[_nTmpFiltro,1]) }) == 0)
			Aadd(_aItMaqEqu,{'LBNO', _aOsMaqEqu[_nTmpFiltro,1], _aOsMaqEqu[_nTmpFiltro,2], .F.})
		EndIf
	Next _nTmpFiltro

	// carrega todos as ruas das ordens de servico
	// sub-select DC8 - Melhora de performance (inner join lento)
	_cQuery := " SELECT DISTINCT CASE "
	_cQuery += "                  WHEN (SELECT DC8_TPESTR "
	_cQuery += "                        FROM   "+RetSqlTab("DC8") + " (nolock) "
	_cQuery += "                        WHERE  "+RetSqlCond("DC8")
	_cQuery += "                               AND DC8_CODEST = BE_ESTFIS) IN ( '1', '2' ) THEN Substring(BE_LOCALIZ, 1, 2) "
	_cQuery += "                  ELSE BE_LOCALIZ "
	_cQuery += "                END RUA, "
	_cQuery += "                Z08_NUMOS "
	// mapa de expedicao / armazenagem / transferencias
	_cQuery += " FROM  "+RetSqlName("Z08")+" Z08 WITH (NOLOCK) "
	// cad. de endereco
	_cQuery += " INNER JOIN "+RetSqlName("SBE")+" SBE ON "+RetSqlCond("SBE")+" AND BE_LOCAL = Z08_LOCAL AND BE_LOCALIZ IN (Z08_ENDORI,Z08_ENDDES) "
	// filtro padrao
	_cQuery += " WHERE " + RetSqlCond('Z08')
	// numero da OS
	_cQuery += " AND Z08_NUMOS IN "+FormatIn(_cSqlNrOS,"|")+" "
	// ordem dos dados
	_cQuery += " ORDER BY Z08_NUMOS, RUA "

	memowrit("c:\query\twmsa009_sfSelDados_fil_ruas.txt",_cQuery )

	// atualiza variavel temporaria
	_aOsRua := U_SqlToVet(_cQuery)

	// limpa variável do filtro
	_aItRua := {}

	// atualiza variavel do filtro
	For _nTmpFiltro := 1 To Len(_aOsRua)
		// verifica se o Operador ja esta na lista
		If (aScan(_aItRua,{|x| (x[2] == _aOsRua[_nTmpFiltro,1]) }) == 0)
			Aadd(_aItRua,{'LBNO', _aOsRua[_nTmpFiltro,1], _aOsRua[_nTmpFiltro,2], .F.})
		EndIf
	Next _nTmpFiltro

	// carrega todos os Pedido de Venda/Pedido Cliente/Agrupadora das ordens de servico
	_cQuery := " SELECT Z05_NUMOS, C5_NUM, C5_ZPEDCLI, C5_ZAGRUPA "
	// cab. ordem de servico
	_cQuery += " FROM "+RetSqlName("Z05")+" Z05 (nolock)  "
	// cab. carga
	_cQuery += " INNER JOIN "+RetSqlName("DAK")+" DAK  (nolock) ON "+RetSqlCond("DAK")+" AND Z05_CARGA = DAK_COD "
	// itens da carga
	_cQuery += " INNER JOIN "+RetSqlName("DAI")+" DAI  (nolock) ON "+RetSqlCond("DAI")+" AND DAI_COD = DAK_COD "
	// cab. pedido de venda
	_cQuery += " INNER JOIN "+RetSqlName("SC5")+" SC5  (nolock) ON "+RetSqlCond("SC5")+" AND C5_NUM = DAI_PEDIDO "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond('Z05')
	// numero da OS
	_cQuery += " AND Z05_NUMOS IN "+FormatIn(_cSqlNrOS,"|")+" "
	// ordem dos dados
	_cQuery += " ORDER BY Z05_NUMOS, C5_NUM "

	memowrit("c:\query\twmsa009_sfSelDados_fil_inf_pedidos.txt",_cQuery )

	// atualiza variavel temporaria
	_aTmpFiltro := U_SqlToVet(_cQuery)

	// limpa variáveis dos pedidos
	_aItPedVen := {}
	_aItPedCli := {}
	_aItIdAgru := {}
	_aOsPedVen := {}
	_aOsPedCli := {}
	_aOsIdAgru := {}

	For _nTmpFiltro := 1 To Len(_aTmpFiltro)

		// verifica se o Pedido de Venda ja esta na lista
		If (aScan(_aItPedVen,{|x| (x[2] == _aTmpFiltro[_nTmpFiltro,2]) }) == 0)
			Aadd(_aItPedVen,{'LBNO', _aTmpFiltro[_nTmpFiltro,2], .F.})
		EndIf
		// variavel com todos os pedidos + OS
		Aadd(_aOsPedVen,{_aTmpFiltro[_nTmpFiltro,2], _aTmpFiltro[_nTmpFiltro,1]})

		//--------------------------------------------------

		// verifica se o Pedido do Cliente ja esta na lista
		If (aScan(_aItPedCli,{|x| (x[2] == _aTmpFiltro[_nTmpFiltro,3]) }) == 0)
			Aadd(_aItPedCli,{'LBNO', _aTmpFiltro[_nTmpFiltro,3], .F.})
		EndIf
		// variavel com todos os pedidos do cliente + OS
		Aadd(_aOsPedCli,{_aTmpFiltro[_nTmpFiltro,3], _aTmpFiltro[_nTmpFiltro,1]})

		//--------------------------------------------------

		// verifica se a Agrupadora ja esta na lista
		If (aScan(_aItIdAgru,{|x| (x[2] == _aTmpFiltro[_nTmpFiltro,4]) }) == 0)
			Aadd(_aItIdAgru,{'LBNO', _aTmpFiltro[_nTmpFiltro,4], .F.})
		EndIf
		// variavel com todos as agrupadoras do cliente + OS
		Aadd(_aOsIdAgru,{_aTmpFiltro[_nTmpFiltro,4],_aTmpFiltro[_nTmpFiltro,1]})

	Next _nTmpFiltro

	// reposiciona cursor no browse
	If (mvFirst)
		dbSelectArea(_cAlTrOrdServ)
		(_cAlTrOrdServ)->(dbGoTop())
	ElseIf (!mvFirst)
		// area inicial do TRB
		RestArea(_aAreaTRB)
	EndIf

	// atualiza contador total
	_nQtdRoda1 := (_cAlTrOrdServ)->( RecCount() )

	// refresh do browse
	If (_oBrwOrdServ <> nil)
		_oBrwOrdServ:oBrowse:Refresh()
		_oSayRoda1:Refresh()
		_oPnlRoda:Refresh()
	EndIf

Return .t.

// ** funcao que apresenta a legenda
Static Function sfLegenda()

	Local _aCores := {}

	// inclui opcoes e cores do status
	aAdd(_aCores,{"BR_VERMELHO", "Aguardando"  })
	aAdd(_aCores,{"BR_AZUL"    , "Em Execução" })
	aAdd(_aCores,{"BR_AMARELO" , "Interrompida"})
	aAdd(_aCores,{"BR_CINZA"   , "Em Análise"  })
	aAdd(_aCores,{"BR_PRETO"   , "Bloqueada"   })
	aAdd(_aCores,{"BR_VERDE"   , "Finalizada"  })
	aAdd(_aCores,{"BR_MARROM"  , "Planejada"   })
	aAdd(_aCores,{"BR_CANCEL"  , "Cancelada"   })

	// funcao padrao para apresentar as legendas
	BrwLegenda(cCadastro,"Legenda",_aCores)

Return NIL

// ** funcao para manutencao e planejamento
Static Function sfPlanejamento()
	// objetos da tela
	local _oWndPlaneja
	local _oPnlPlaCabec

	// menus e opcoes
	local _oMnuPlan2
	local _oMnu2OrdSrv, _oMnu2Cesv, _oMnu2Carga

	// monta a estrutura do arquivo de trabalho
	If (Len(_aHdPlanej)==0)
		aAdd(_aStPlanej,{"ZZ_CESV"     ,"C", TamSx3("ZZ_CESV")[1],0})    ; aAdd(_aHdPlanej,{"ZZ_CESV"   ,"",RetTitle("ZZ_CESV"), ""})
		aAdd(_aStPlanej,{"ZZ_DTENT"    ,"D", TamSx3("ZZ_DTENT")[1],0})   ; aAdd(_aHdPlanej,{"ZZ_DTENT"  ,"","Dt Ent."          , ""})
		aAdd(_aStPlanej,{"IT_CODSTAT"  ,"C", 2,0})
		aAdd(_aStPlanej,{"ZZ_OPERACA"  ,"C", TamSx3("ZZ_OPERACA")[1],0})
		aAdd(_aStPlanej,{"IT_OPERACA"  ,"C", 12,0})                      ; aAdd(_aHdPlanej,{"IT_OPERACA","","Operação"         , ""})
		aAdd(_aStPlanej,{"IT_PROCES"   ,"C", TamSx3("ZZ_PROCES")[1],0})  ; aAdd(_aHdPlanej,{"IT_PROCES" ,"","Processo"         , ""})
		aAdd(_aStPlanej,{"IT_ITPROC"   ,"C", TamSx3("ZZ_ITPROC")[1],0})
		aAdd(_aStPlanej,{"ZZ_CARGA"    ,"C", TamSx3("DAK_COD")[1],0})
		aAdd(_aStPlanej,{"ZZ_CLIENTE"  ,"C", TamSx3("ZZ_CLIENTE")[1],0})
		aAdd(_aStPlanej,{"ZZ_LOJA"     ,"C", TamSx3("ZZ_LOJA")[1],0})
		aAdd(_aStPlanej,{"A1_NOME"     ,"C", TamSx3("A1_NOME")[1],0})    ; aAdd(_aHdPlanej,{"A1_NOME"   ,"","Cliente"          , ""})
		aAdd(_aStPlanej,{"ZZ_DOCA"     ,"C", TamSx3("ZZ_DOCA")[1],0})    ; aAdd(_aHdPlanej,{"ZZ_DOCA"   ,"","Doca"             , ""})
		aAdd(_aStPlanej,{"ZZ_LOCAL"    ,"C", TamSx3("ZZ_LOCAL")[1],0})   ; aAdd(_aHdPlanej,{"ZZ_LOCAL"  ,"","Armazém"          , ""})
		aAdd(_aStPlanej,{"ZZ_STATUS"   ,"C", TamSx3("ZZ_STATUS")[1],0})
		aAdd(_aStPlanej,{"ZZ_PLACA1"   ,"C", TamSx3("ZZ_PLACA1")[1],0})  ; aAdd(_aHdPlanej,{"ZZ_PLACA1" ,"","Placa 1"          , PesqPict("SZZ","ZZ_PLACA1")})
		aAdd(_aStPlanej,{"ZZ_CNTR01"   ,"C", TamSx3("ZZ_CNTR01")[1],0})  ; aAdd(_aHdPlanej,{"ZZ_CNTR01" ,"","Container"        , PesqPict("SZZ","ZZ_CNTR01")})
		aAdd(_aStPlanej,{"DAK_COD"     ,"C", TamSx3("DAK_COD")[1],0})    ; aAdd(_aHdPlanej,{"DAK_COD"   ,"","Nr.Carga"         , PesqPict("DAK","DAK_COD")})
		aAdd(_aStPlanej,{"Z57_CODIGO"  ,"C", TamSx3("Z57_CODIGO")[1],0}) ; aAdd(_aHdPlanej,{"Z57_CODIGO","","Onda Separação"   , PesqPict("Z57","Z57_CODIGO")})

		// fecha alias do TRB
		If (Select(_cAlTrPlanej)<>0)
			dbSelectArea(_cAlTrPlanej)
			dbCloseArea()
		EndIf

		// cria arquivo de trabalho
		_cTrPlanej := FWTemporaryTable():New( _cAlTrPlanej )
		_cTrPlanej:SetFields( _aStPlanej )
		_cTrPlanej:Create()

	EndIf

	// atualiza os dados no arquivo de trabalho
	sfDadosPla( Nil, .T.)

	// monta o dialogo para planejamento
	_oWndPlaneja := MSDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"Planejamento",,,.F.,,,,,,.T.,,,.T. )
	_oWndPlaneja:lMaximized := .T.

	// cria o panel do cabecalho
	_oPnlPlaCabec := TPanel():New(000,000,'Planejamento de Operações de Recebimento e Expedições',_oWndPlaneja,_oFntCabec,.T.,.F.,,,000,025,.T.,.F. )
	_oPnlPlaCabec:Align:= CONTROL_ALIGN_TOP

	// monta um Menu Suspenso
	_oMnuPlan2 := TMenuBar():New(_oWndPlaneja)
	_oMnuPlan2:SetCss("QMenuBar{background-color:#424242;color:#ffffff}")
	_oMnuPlan2:Align     := CONTROL_ALIGN_TOP
	_oMnuPlan2:bRClicked := {||}
	_oMnuPlan2:oFont := _oFntMenu

	// sub-opcao
	_oMnu2OrdSrv := TMenu():New(0,0,0,0,.T.,,_oWndPlaneja)
	_oMnu2Cesv   := TMenu():New(0,0,0,0,.T.,,_oWndPlaneja)
	_oMnu2Carga  := TMenu():New(0,0,0,0,.T.,,_oWndPlaneja)

	// adciona opcao principal do menu
	_oMnuPlan2:AddItem('&Ordens de Serviço', _oMnu2OrdSrv, .T.)
	_oMnuPlan2:AddItem('&CESV'             , _oMnu2Cesv  , .T.)
	_oMnuPlan2:AddItem('Car&gas'           , _oMnu2Carga , .T.)

	// sub-opcoes - ordens de servico
	_oMnu2OrdSrv:Add(TMenuItem():New(_oWndPlaneja,'Atualização/Refresh de Dados'                           ,,,,{|| sfDadosPla(@_oBrwPlanej,.f.)                                                                                                                                             },,'RELOAD'        ,,,,,,,.T.))
	_oMnu2OrdSrv:Add(TMenuItem():New(_oWndPlaneja,'Gerar Ordem de Serviço de Recebimento e/ou Expedição'   ,,,,{|| U_WMSA009B((_cAlTrPlanej)->ZZ_CESV, (_cAlTrPlanej)->ZZ_OPERACA, (_cAlTrPlanej)->ZZ_CARGA, (_cAlTrPlanej)->ZZ_DOCA, Nil, .F., "003") },,'WMS_COLETOR_01',,,,,,,.T.))
	_oMnu2OrdSrv:Add(TMenuItem():New(_oWndPlaneja,'Gerar OS de preconferencia'                             ,,,,{|| U_WMSA009B((_cAlTrPlanej)->ZZ_CESV, (_cAlTrPlanej)->ZZ_OPERACA, (_cAlTrPlanej)->ZZ_CARGA, (_cAlTrPlanej)->ZZ_DOCA, Nil, .F., "015") },,'ALTERA',,,,,,,.T.))
	_oMnu2OrdSrv:Add(TMenuItem():New(_oWndPlaneja,'Gerar/Consultar Mapa Apanhe/Expedição'                  ,,,,{|| MsgRun("Analisando dados...", "Aguarde...", {|| U_TWMSA019( (_cAlTrPlanej)->DAK_COD, (_cAlTrPlanej)->Z57_CODIGO, Nil ) })                                                                                 },,'MENURUN'       ,,,,,,,.T.))
	_oMnu2OrdSrv:Add(TMenuItem():New(_oWndPlaneja,'Sair'                                                   ,,,,{|| _oWndPlaneja:End()                                                                                                                                                       },,'FINAL'         ,,,,,,,.T.))

	// sub-opcoes - CESV
	_oMnu2Cesv:Add(TMenuItem():New(_oWndPlaneja,'Vincular CESV com Documento de Recebimento'               ,,,,{|| U_WMSA009D( (_cAlTrPlanej)->ZZ_CESV, "1" )                                                                                                                               },,'PEDIDO'        ,,,,,,,.T.))
	_oMnu2Cesv:Add(TMenuItem():New(_oWndPlaneja,'Vincular CESV com Documento Complementar (TFAA)'          ,,,,{|| U_WMSA009D( (_cAlTrPlanej)->ZZ_CESV, "2" )                                                                                                                               },,'COPYUSER'      ,,,,,,,.T.))
	_oMnu2Cesv:Add(TMenuItem():New(_oWndPlaneja,'Vincular CESV sem Documento Definitivo'                   ,,,,{|| U_WMSA009D( (_cAlTrPlanej)->ZZ_CESV, "3" )                                                                                                                               },,'UNSELECTALL'   ,,,,,,,.T.))
	_oMnu2Cesv:Add(TMenuItem():New(_oWndPlaneja,'Atualizar dados de um documento TFAA'                     ,,,,{|| U_WMSA009F( (_cAlTrPlanej)->ZZ_CESV )                                                                                                                                    },,'SDUPROPR'      ,,,,,,,.T.))

	// sub-opcoes - Cargas
	_oMnu2Carga:Add(TMenuItem():New(_oWndPlaneja,'Cadastro e Manutenção de Cargas'                         ,,,,{|| OMSA200(), sfDadosPla(@_oBrwPlanej,.f.)                                                                                                                                  },,'TMSIMG32'      ,,,,,,,.T.))

	// browse com a listagem dos servicos
	_oBrwPlanej := MsSelect():New((_cAlTrPlanej),,,_aHdPlanej,,,{001,001,400,1000},,,_oWndPlaneja)
	_oBrwPlanej:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwPlanej:oBrowse:oFont := _oFntBrowse

	// ativa a tela
	ACTIVATE MSDIALOG _oWndPlaneja CENTERED

Return()

// ** funcao para gerar as ordens de servico
User Function WMSA009B(mvCESV, mvOperacao, mvCarga, mvEndServ, mvMapaApanhe, mvAtuEstoque, mvCodServ, mvCodCli, mvLojCli, mvMostraOS, mvObs, mvOsOrig, mvOndaSep, mvCodTaref)
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SZZ","Z05"})

	// objetos da tela
	local _oPnlSrvCabec
	local _oBtnSrvConf, _oBtnSrvSair

	// controle de validacao para geracao de OS
	local _lOk := .f.
	// tipo da operacao
	local _cTpOperaca := IIf(mvOperacao=="01", "E", IIf(mvOperacao=="02", "S", "I"))
	// codigo do servico e tarefa
	local _cSrvOper := ""
	local _cTrfOper := ""

	// retorna codigo de servico, tarefa e funcao padrao
	// 1-Cod Servico
	// 2-Dsc Servico
	// 3-Cod Tarefa
	// 4-Dsc Tarefa
	// 5-Funcao/Rotina
	local _aDetServico := {}

	// variaveis temporarias
	local _nServ
	local _cQuery

	// data e hora de emissao
	local _dDtEmissao := Date()
	local _cHrEmissao := Time()

	// estrutura do TRB
	local _aHeadBrw := {}
	local _aEstBrowse := {}

	local _cMarcaBrw := GetMark()
	local _aCorBrw := {}

	// sequencia da OS
	local _nSeqOS := 1

	// servicos planejados
	local _lServPla := .f.

	// controle do mapa de apanhe
	local _lMapaApanhe := .f.

	// controle se ha movimentacao de veiculo
	local _lSeekSZZ := .F.

	// controle se ha CESV vinculado
	local _lSeekZ04 := .F.

	// controle do codigo de cliente
	local _cCodCli := ""
	local _cLojCli := ""

	// centraliza tela
	local _lDlgCenter := (Type("_aSizeDlg")=="U")
	// largura da tela
	local _nDlgLarg := If(Type("_aSizeDlg")=="U",190,(_aSizeDlg[1]))
	// altura da tela
	local _nDlgAltu := If(Type("_aSizeDlg")=="U",240,(_aSizeDlg[2]))

	// itens da carga
	local _cSeekDAK
	local _cSeekZ58

	// atualiza estoque
	local _lAtuEstoque := mvAtuEstoque

	// armazem/local atual
	local _cArmzAtual := CriaVar("BE_LOCAL",.f.)

	// numero da programacao
	local _cCodProg := ""

	// numero do contrato
	local _cNrContrat := ""

	// define origem dos dados
	local _lPorCarga := .F.
	local _lPorOnda  := .F.

	// controle se deve atribuir automaticamente os recursos humanos
	local _lAddRecAut := .T.

	// endereco de servico
	local _cEndServ := ""

	// flag para indicar se tem barcode na expedição (cliente Sumitomo)
	Local _lTemBar := .F.

	// valores padroes
	Default mvCESV       := CriaVar("ZZ_CESV"   , .F.)
	Default mvCarga      := CriaVar("DAK_COD"   , .F.)
	Default mvEndServ    := CriaVar("BE_LOCALIZ", .F.)
	Default mvMapaApanhe := {}
	Default mvCodServ    := CriaVar("Z06_SERVIC", .F.)
	Default mvCodCli     := CriaVar("A1_COD"    , .F.)
	Default mvLojCli     := CriaVar("A1_LOJA"   , .F.)
	Default mvMostraOS   := .T. // padrão pra mostrar as mensagens
	Default mvObs        := CriaVar("Z06_OBS"   , .F.)
	Default mvOsOrig     := CriaVar("Z06_NUMOS" , .F.)
	Default mvOndaSep    := CriaVar("Z57_CODIGO", .F.)
	Default mvCodTaref   := CriaVar("Z06_TAREFA", .F.)

	// atualiza codigo do servico e tarefa
	_cSrvOper := mvCodServ
	_cTrfOper := mvCodTaref

	// atualiza codigo e loja de cliente
	_cCodCli := mvCodCli
	_cLojCli := mvLojCli

	// atualiza endereco de servico
	_cEndServ := mvEndServ

	// define origem dos dados
	_lPorCarga := ((mvCarga   != Nil) .And. ( ! Empty(mvCarga)   ))
	_lPorOnda  := ((mvOndaSep != Nil) .And. ( ! Empty(mvOndaSep) ))

	// define as cores do browse
	aAdd(_aCorBrw, {"  Empty((_TRBSERV)->IT_OBRIG)" ,"DISABLE"})
	aAdd(_aCorBrw, {"!(Empty((_TRBSERV)->IT_OBRIG))","ENABLE" })

	//TODO alerta se realmente é pre-conferencia e também fazer validação

	// registro do CESV
	If ( ! Empty(mvCESV) )
		dbSelectArea("SZZ")
		SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
		_lSeekSZZ := SZZ->(dbSeek( xFilial("SZZ") + mvCESV ))

		//CESV está vinculado
		dbSelectArea("Z04")
		Z04->(dbSetOrder(1)) // 1-Z04_FILIAL, Z04_CESV
		_lSeekZ04 := Z04->(dbSeek( xFilial("Z04") + mvCESV ))
	EndIf

	// valida o cliente
	If (_cTpOperaca $ "E|S") .And. (_lSeekSZZ) .And. (Empty(SZZ->ZZ_CLIENTE))
		// mensagem
		U_FtWmsMsg("Para utilizar esta opção é necessário definir o cliente/nota fiscal.","ATENÇÃO")
		// restaura areas iniciais
		RestOrd(_aAreaIni,.t.)
		RestArea(_aArea)
		// retorno
		Return( .F. )
	EndIf

	// valida se a doca/stage foi definido para recebimento / expedicao
	If (_cTpOperaca $ "E|S") .And. (_lSeekSZZ) .And. (Empty(SZZ->ZZ_DOCA))
		// mensagem
		U_FtWmsMsg("É necessário informar a DOCA/STAGE/PORTAO para a operação.","ATENÇÃO")

		// abre tela pra seleção de DOCA/STAGE/PORTAO
		If ( ! U_WMSA008B( SZZ->ZZ_CESV ) )
			U_FtWmsMsg("DOCA/STAGE/PORTAO não informados. Geração de OS não permitida.","ATENÇÃO")
			Return( .F. )
		EndIf

	EndIf

	// valida o status (05-LIBERADO PARA OPERACAO ou 06-EM PLANEJAMENTO)
	If (_cTpOperaca=="E") .And. (_lSeekSZZ) .And. ( ! (SZZ->ZZ_STATUS $ "05/06"))
		// mensagem
		U_FtWmsMsg("CESV não está liberado para geração de ordens de serviço. Status Atual: "+SZZ->ZZ_STATUS,"ATENÇÃO")
		// restaura areas iniciais
		RestOrd(_aAreaIni,.t.)
		RestArea(_aArea)
		// retorno
		Return(.f.)
	EndIf

	// verifica se ja existe OS para a movimentacao - RECEBIMENTO / EXPEDICAO
	If (_cTpOperaca $ "E/S") .And. (_lSeekSZZ)
		// ordens de serviço
		dbSelectArea("Z05")
		Z05->(dbOrderNickName("Z05_CESV"))
		If Z05->(dbSeek( xFilial("Z05") + SZZ->ZZ_CESV ))
			// mensagem
			U_FtWmsMsg("Ordem de Serviço já vinculada. O.S.: " + Z05->Z05_NUMOS, "ATENÇÃO")
			// restaura areas iniciais
			RestOrd(_aAreaIni,.t.)
			RestArea(_aArea)
			// retorno
			Return( .F. )
		EndIf

		// atualiza codigo do cliente
		_cCodCli  := SZZ->ZZ_CLIENTE
		_cLojCli  := SZZ->ZZ_LOJA
		_cCodProg := SZZ->ZZ_PROCES

		// valida se a programacao esta encerrada
		If ( ! Empty(_cCodProg) )
			dbSelectArea("SZ1")
			SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
			If (SZ1->(dbSeek( xFilial("SZ1") +  _cCodProg )))
				If ( ! Empty(SZ1->Z1_DTFINFA))
					// mensagem
					U_FtWmsMsg("A programação " + _cCodProg + " encontra-se encerrada." + CRLF + "Contate o setor de Faturamento.","ATENCAO")
					// retorno
					Return(.F.)
				EndIf
			Else
				// mensagem
				U_FtWmsMsg("Programação " + _cCodProg + " não encontrada." + CRLF + "Contate o setor de Faturamento.","ATENCAO")
				// retorno
				Return(.F.)
			EndIf

			// atualiza numero do contrato
			_cNrContrat := SZ1->Z1_CONTRT
		EndIf

	EndIf

	// valida se ja tem CESV vinculado a nota fiscal e não é pre-conferencia sem documento (neste caso, não tem nota fiscal)
	If (_cTpOperaca == "E") .And. ( ! _lSeekZ04 ) .AND. (_cSrvOper != "015")
		//mensagem de erro
		U_FtWmsMsg("Não é possivel gerar a OS pois o CESV " + mvCesv + " não está vinculado à uma nota fiscal de entrada/armazenagem.","ATENÇÃO")
		// restaura areas iniciais
		RestOrd(_aAreaIni,.t.)
		RestArea(_aArea)
		// retorno
		Return( .F. )
	EndIf

	// verifica se ja existe OS para a movimentacao - EXPEDICAO - por carga
	If (_cTpOperaca == "S") .And. (_lPorCarga) .And. ( ! _lPorOnda ) .And. ( ! Empty(mvCarga) )

		// posiciona na carga
		dbSelectArea("DAK")
		DAK->(dbSetOrder(1)) // 1-DAK_FILIAL, DAK_COD, DAK_SEQCAR
		DAK->(dbSeek( xFilial("DAK") + mvCarga ))

		// ordens de serviço
		dbSelectArea("Z05")
		Z05->(dbOrderNickName("Z05_CARGA"))
		If Z05->(dbSeek( xFilial("Z05") + DAK->DAK_COD ))
			// mensagem
			U_FtWmsMsg("Ordem de Serviço já vinculada. O.S.: " + Z05->Z05_NUMOS, "ATENÇÃO")
			// restaura areas iniciais
			RestOrd(_aAreaIni,.t.)
			RestArea(_aArea)
			// retorno
			Return(.f.)
		EndIf

		// aceita somente carga de um unico cliente
		dbSelectArea("DAI")
		DAI->(dbSetOrder(1)) // 1-DAI_FILIAL, DAI_COD, DAI_SEQCAR, DAI_SEQUEN, DAI_PEDIDO
		DAI->(dbSeek( _cSeekDAK := (DAK->DAK_FILIAL + DAK->DAK_COD) ))
		While DAI->(!Eof()) .And. ((DAI->DAI_FILIAL + DAI->DAI_COD) == _cSeekDAK)
			// verifica se ha mais de um cliente na mesma carga
			If ( ! Empty(_cCodCli)) .And. ((_cCodCli != DAI->DAI_CLIENT) .Or. (_cLojCli != DAI->DAI_LOJA))
				// mensagem
				U_FtWmsMsg("Não é permitido múltiplos clientes na mesma carga.","ATENÇÃO")
				// restaura areas iniciais
				RestOrd(_aAreaIni,.t.)
				RestArea(_aArea)
				// retorno
				Return(.f.)
			EndIf

			// atualiza codigo do cliente
			_cCodCli := DAI->DAI_CLIENT
			_cLojCli := DAI->DAI_LOJA

			// proximo item
			DAI->(dbSkip())
		EndDo

	EndIf

	// verifica se ja existe OS para a movimentacao - EXPEDICAO - por onda
	If (_cTpOperaca == "S") .And. ( ! _lPorCarga ) .And. (_lPorOnda) .And. ( ! Empty(mvOndaSep) )

		// posiciona na onda selecionada
		dbSelectArea("Z57")
		Z57->(dbSetOrder(1)) // 1 - Z57_FILIAL, Z57_CODIGO
		If ( ! Z57->(dbSeek( xFilial("Z57") + mvOndaSep )) )
			// avisa usuario
			Help( ,, 'TWMSA009.F01.001',, "Onda de Separação " + mvOndaSep + " não localizada.", 1, 0 )
			// retorno
			Return( .F. )
		EndIf

		// ordens de serviço
		dbSelectArea("Z05")
		Z05->(dbOrderNickName("Z05ONDSEP"))
		If Z05->(dbSeek( xFilial("Z05") + mvOndaSep ))
			// mensagem
			U_FtWmsMsg("Ordem de Serviço já vinculada. O.S.: " + Z05->Z05_NUMOS,"ATENÇÃO")
			// restaura areas iniciais
			RestOrd(_aAreaIni,.t.)
			RestArea(_aArea)
			// retorno
			RETURN( .F. )
		EndIf

		// aceita somente onda de um unico cliente
		dbSelectArea("Z58")
		Z58->(dbSetOrder(1)) // 1 - Z58_FILIAL, Z58_CODIGO, Z58_SEQUEN
		Z58->(dbSeek( _cSeekZ58 := Z57->Z57_FILIAL + Z57->Z57_CODIGO ))

		// varre todos os pedidos da onda
		While Z58->( ! Eof() ) .And. (Z58->Z58_FILIAL + Z58->Z58_CODIGO == _cSeekZ58)

			// verifica se ha mais de um cliente na mesma carga
			If ( ! Empty(_cCodCli)) .And. ((_cCodCli != Z58->Z58_CODCLI) .Or. (_cLojCli != Z58->Z58_LOJCLI))
				// mensagem
				U_FtWmsMsg("Não é permitido múltiplos clientes na mesma carga.","ATENÇÃO")
				// restaura areas iniciais
				RestOrd(_aAreaIni, .T.)
				RestArea(_aArea)
				// retorno
				Return( .F. )
			EndIf

			// atualiza codigo do cliente
			_cCodCli := Z58->Z58_CODCLI
			_cLojCli := Z58->Z58_LOJCLI

			// proximo item
			Z58->(dbSkip())
		EndDo

	EndIf

	// verifica se ja existe OS para a movimentacao - EXPEDICAO
	If (_cTpOperaca=="S") .And. (_lPorCarga) .And. ( ! _lPorOnda ) .And. ( Empty(mvCarga) ) .And. ( ! Empty(mvCESV) )
		// mensagem
		U_FtWmsMsg("Não é permitido geração de OS de Expedição sem carga.","ATENÇÃO")
		// restaura areas iniciais
		RestOrd(_aAreaIni,.t.)
		RestArea(_aArea)
		// retorno
		Return(.f.)
	EndIf

	// verifica se ja existe mapa de expedicao
	If (_cTpOperaca=="S") .And. ( Len(mvMapaApanhe) == 0 ) .And. (_cTrfOper != "004")
		// mensagem
		U_FtWmsMsg("Não é permitido geração de OS de Expedição mapa de expedição gerado.","ATENÇÃO")
		// restaura areas iniciais
		RestOrd(_aAreaIni,.t.)
		RestArea(_aArea)
		// retorno
		Return(.f.)
	EndIf

	// operacao INTERNA
	If (_cTpOperaca=="I") .And. (_lSeekSZZ)
		// atualiza codigo do cliente
		_cCodCli := SZZ->ZZ_CLIENTE
		_cLojCli := SZZ->ZZ_LOJA
	EndIf

	// operacao INTERNA, sem SZZ (ex: INVENTARIO)
	If (_cTpOperaca == "I") .And. ( ! _lSeekSZZ )
		// atualiza codigo do cliente
		_cCodCli := mvCodCli
		_cLojCli := mvLojCli
	EndIf

	// retorna codigo de servico, tarefa e funcao padrao
	// 1-Cod Servico
	// 2-Dsc Servico
	// 3-Cod Tarefa
	// 4-Dsc Tarefa
	// 5-Funcao/Rotina
	_aDetServico := U_FtRetSrv(_cSrvOper, _cTrfOper, .F., _cTpOperaca, _cCodCli, _cLojCli, Nil)

	// valida quantidade de servicos
	If (Empty(_aDetServico))
		// mensagem
		U_FtWmsMsg("Sem Atividades vinculadas! Geração de OS não Permitida. ","ATENÇÃO")
		// retorno
		Return(.F.)
	EndIf

	// define a estrutura do TRB
	aAdd(_aEstBrowse,{"IT_OK"    ,"C", 2,0})
	aAdd(_aEstBrowse,{"IT_OBRIG" ,"C", 2,0})
	aAdd(_aEstBrowse,{"CD_SERV"  ,"C", 3,0})
	aAdd(_aEstBrowse,{"DS_SERV"  ,"C",25,0})
	aAdd(_aEstBrowse,{"CD_TARE"  ,"C", 3,0})
	aAdd(_aEstBrowse,{"DS_TARE"  ,"C",20,0})

	// fecha o alias do TRB caso exista
	If ( Type("_TRBSERV") != "U")
		If (Select(_TRBSERV) != 0)
			dbSelectArea(_TRBSERV)
			dbCloseArea()
		EndIf
	Else
		_TRBSERV := GetNextAlias()
	EndIf

	// cria um arquivo de trabalho
	_cArqTmp := FWTemporaryTable():New( _TRBSERV )
	_cArqTmp:SetFields( _aEstBrowse )
	_cArqTmp:Create()

	// alimenta o TRB com os servicos
	For _nServ := 1 to Len(_aDetServico)
		dbSelectArea(_TRBSERV)
		RecLock(_TRBSERV,.t.)
		(_TRBSERV)->CD_SERV	:= _aDetServico[_nServ,1]
		(_TRBSERV)->DS_SERV	:= _aDetServico[_nServ,2]
		(_TRBSERV)->CD_TARE	:= _aDetServico[_nServ,3]
		(_TRBSERV)->DS_TARE	:= _aDetServico[_nServ,4]
		(_TRBSERV)->(MsUnLock())
	Next _nServ

	// inclui detalhes e titulos dos campos do browse
	aAdd(_aHeadBrw,{"IT_OK"     ,"@!" ,"  "})
	aAdd(_aHeadBrw,{"CD_SERV"   ,"@!" ,"Cod.Srv"})
	aAdd(_aHeadBrw,{"DS_SERV"   ,"@!" ,"Serviço"})
	aAdd(_aHeadBrw,{"CD_TARE"   ,"@!" ,"Cod.Tar"})
	aAdd(_aHeadBrw,{"DS_TARE"   ,"@!" ,"Tarefa"})

	// abre o arquivo de trabalho
	(_TRBSERV)->(dbSelectArea(_TRBSERV))
	(_TRBSERV)->(dbGoTop())

	// ativa e monta tela com os servicos
	If (mvMostraOS)

		// cria dialogo da tela com os servicos
		_oDlgRelServ := MSDialog():New(000,000,_nDlgAltu,_nDlgLarg,"Relação de Serviços",,,.F.,,,,,,.T.,,,.T. )

		// cria o panel do cabecalho - botoes de operacao
		_oPnlSrvCabec := TPanel():New(000,000,nil,_oDlgRelServ,,.F.,.F.,,,000,022,.T.,.F. )
		_oPnlSrvCabec:Align:= CONTROL_ALIGN_TOP

		// -- botao que confirma os servicos
		_oBtnSrvConf := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| If(_lOk := sfVldGerOS(_cTpOperaca, mvCarga, _cEndServ, mvOndaSep),_oDlgRelServ:End(),nil) },_oPnlSrvCabec,"Ok",,.T.)
		_oBtnSrvConf:Align := CONTROL_ALIGN_LEFT

		// -- botao para fechar a tela
		_oBtnSrvSair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{|| _lOk := .f., _oDlgRelServ:End() },_oPnlSrvCabec,"Sair",,.T.)
		_oBtnSrvSair:Align := CONTROL_ALIGN_RIGHT

		// browse com a listagem dos produtos conferidos
		_oBrwRelSrv := MsSelect():New((_TRBSERV),"IT_OK",,_aHeadBrw,,_cMarcaBrw,{15,1,183,373},,,,,_aCorBrw)
		_oBrwRelSrv:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// ativa a tela para apresentar na tela
		_oDlgRelServ:Activate(,,,(_lDlgCenter),,,)

	ElseIf ( ! mvMostraOS )       //parâmetro para não exibir
		//roda a validação automaticamente
		_lOk := sfVldGerOS(_cTpOperaca, mvCarga, _cEndServ, mvOndaSep)

	EndIf

	// se a tela foi confirmada, gera as OS
	If (_lOk)

		// busca o armazem padrao por cliente
		If (_cTpOperaca == "E")
			_cArmzAtual := U_FtWmsParam("WMS_ARMAZEM_POR_CLIENTE", "C", "A1", .f., Nil, _cCodCli, _cLojCli, _cNrContrat, Nil)
		Else
			_cArmzAtual := U_FtWmsParam("WMS_ARMAZEM_POR_CLIENTE", "C", "A1", .f., cFilAnt, _cCodCli, _cLojCli, Nil, Nil)
		EndIf

		// permite conferencia/recebimento por volumes
		_lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.f.,.f.,"", _cCodCli, _cLojCli, Nil, Nil)

		// controle se deve atribuir automaticamente os recursos humanos
		_lAddRecAut := U_FtWmsParam("WMS_ATRIBUI_RECURSOS_HUMANOS_AUTOMATICAMENTE", "L", .F., .T., "", _cCodCli, _cLojCli, Nil, Nil)

		// inicia transacao
		BEGIN TRANSACTION

			// gera cabeçalho da OS
			dbSelectArea("Z05")
			RecLock("Z05",.t.)
			Z05->Z05_FILIAL := xFilial("Z05")
			Z05->Z05_NUMOS  := GetSxeNum("Z05","Z05_NUMOS", xFilial("Z05"))
			Z05->Z05_CLIENT := _cCodCli
			Z05->Z05_LOJA   := _cLojCli
			Z05->Z05_DTEMIS := _dDtEmissao
			Z05->Z05_HREMIS := _cHrEmissao
			Z05->Z05_OSORIG := mvOsOrig

			// atualiza CESV
			If (_lSeekSZZ)
				Z05->Z05_CESV   := SZZ->ZZ_CESV
				Z05->Z05_PROCES	:= SZZ->ZZ_PROCES
			EndIf

			// demais campos de controle
			If (_cTpOperaca == "E")
				Z05->Z05_PROCES	:= SZZ->ZZ_PROCES
				Z05->Z05_ITPROC	:= SZZ->ZZ_ITPROC
			ElseIf (_cTpOperaca == "S") .And. (_lPorCarga) .And. ( ! _lPorOnda )
				Z05->Z05_CARGA  := DAK->DAK_COD
			ElseIf (_cTpOperaca == "S") .And. ( ! _lPorCarga ) .And. (_lPorOnda)
				Z05->Z05_ONDSEP := Z57->Z57_CODIGO
			EndIf

			// tipo da operacao
			Z05->Z05_TPOPER	:= _cTpOperaca
			Z05->(MsUnLock())
			// confirma sequencial
			ConfirmSx8()

			// varre todas as tarefas e atividades do servico selecionados
			dbSelectArea(_TRBSERV)
			(_TRBSERV)->(dbGoTop())

			While (_TRBSERV)->( ! Eof() )

				// inclui o item da OS
				dbSelectArea("Z06")
				RecLock("Z06", .T.)
				Z06->Z06_FILIAL := xFilial("Z06")
				Z06->Z06_NUMOS  := Z05->Z05_NUMOS
				Z06->Z06_SEQOS	:= StrZero(_nSeqOS, 3)
				Z06->Z06_SERVIC := (_TRBSERV)->CD_SERV
				Z06->Z06_TAREFA := (_TRBSERV)->CD_TARE
				If (_cTpOperaca == "E") // entrada
					Z06->Z06_LOCAL  := SZZ->ZZ_LOCAL
					Z06->Z06_ENDSRV := IIf(_lServPla,""        ,SZZ->ZZ_DOCA)
				ElseIf (_cTpOperaca == "S") // saida
					Z06->Z06_LOCAL  := _cArmzAtual
					Z06->Z06_ENDSRV := IIf(_lServPla,""        ,IIf(_lSeekSZZ, SZZ->ZZ_DOCA , _cEndServ  ))

					//grava dados da OS no pedido de venda
					If ( ! sfCompInf(Z05->Z05_CARGA, Z05->Z05_ONDSEP, (_TRBSERV)->CD_TARE, Z05->Z05_CESV) )
						// rollback na transacao
						_lOk := .F.
						DisarmTransaction()
						Break
					EndIf
				ElseIf (_cTpOperaca == "I") // interna
					Z06->Z06_LOCAL  := IIf(_lSeekSZZ, SZZ->ZZ_LOCAL, _cArmzAtual)
					Z06->Z06_ENDSRV := IIf(_lServPla,""        ,IIf(_lSeekSZZ, SZZ->ZZ_DOCA , _cEndServ  ))
				EndIf
				Z06->Z06_DTEMIS := _dDtEmissao
				Z06->Z06_HREMIS := _cHrEmissao
				Z06->Z06_STATUS := IIf(_lServPla,"PL","AG")

				// SUMITOMO - Bloqueio de Sequencia 001 - 08.08.2019 - Luiz Fernando
				// Conforme tarefa Redmine #414, quando gerar apanhe de expedição (Seq 001) do cliente SUMITOMO, gera a OS como bloqueada, pois, deve aguardar o arquivo EDI de Action Class 01, para confirmar o pedido de vendas
				// e então liberar a primeira etapa da OS. O desbloqueio acontece em TWMSA047.fAtuPed.

				If (_cTpOperaca == "S") .AND. (Z06->Z06_SEQOS $ "001,003") .AND.;
				( (Z05->(Z05_CLIENT+Z05_LOJA) == GetNewPar("TC_SRBTI","00031601")) .Or. (Z05->(Z05_CLIENT+Z05_LOJA) == GetNewPar("TC_SRBTP","00031602")) ) .AND.;
				( U_FtWmsParam("WMS_SUMITOMO_LEITURA_BARCODE", "L", .F., .F., Nil, _cCodCli, _cLojCli, Nil, Nil) )
					// verifica se o mapa tem pelo menos UM produto que está ativo integração via barcode, para então gerar a OS bloqueada (AN = em análise, pois este status não altera/libera pelo coletor)
					If ( _lTemBar := sfTemBarcode(mvMapaApanhe) )
						Z06->Z06_STATUS := "AN"
					EndIf
				EndIf
				// prioridade padrão
				Z06->Z06_PRIOR  := "99"
				// atualiza estoque
				Z06->Z06_ATUEST := IIf(_lAtuEstoque, "S", "N")
				// observações da OS
				Z06->Z06_OBS := mvObs
				Z06->(MsUnLock())

				// atribuicao automatica dos recursos humanos necessarios para operacao
				If (_lAddRecAut)
					If !( sfAddRecurso(Z06->Z06_SERVIC, Z06->Z06_TAREFA, Z06->Z06_SEQOS, Z05->Z05_CLIENT, Z05->Z05_LOJA, Z05->Z05_TPOPER, .F., _lAddRecAut) )
						_lOk := .F.
						DisarmTransaction()
						Break
					Endif
				EndIf

				// para OS de saida e servico 001, gera mapa de separacao/apanhe
				If (((_cTpOperaca=="S") .And. ((_TRBSERV)->CD_SERV=="001")) .Or. ((_cTpOperaca=="I") .And. ((_TRBSERV)->CD_SERV=="T05"))) .And. (!_lMapaApanhe)
					// funcao para gerar mapa de separacao/apanhe
					If ( ! sfMapaApanhe( mvMapaApanhe, _lCtrVolume ) )
						// rollback na transacao
						_lOk := .F.
						DisarmTransaction()
						Break
					EndIf
					// mapa gerado
					_lMapaApanhe := .t.
				EndIf

				// controle sequencial da OS
				_nSeqOS ++

				// servico planejado
				_lServPla := .t.

				// proximo item
				(_TRBSERV)->(dbSkip())
			EndDo

			// inclusao do PLANEJAMENTO de recursos necessarios para operacao com base no serviço informado
			If !(sfAddRecurso(Z06->Z06_SERVIC, Z06->Z06_TAREFA, Z06->Z06_SEQOS, Z05->Z05_CLIENT, Z05->Z05_LOJA, Z05->Z05_TPOPER, .T., .F.))
				_lOk := .F.
				DisarmTransaction()
				Break
			EndIf

			// altera o status do registro do CESV
			If (_lSeekSZZ)
				dbSelectArea("SZZ")
				RecLock("SZZ")
				SZZ->ZZ_STATUS := "06" // 06-EM PLANEJAMENTO
				SZZ->(MsUnLock())
			EndIf

			// atualiza STATUS da onda de separação
			If (_cTpOperaca == "S") .And. ( ! _lPorCarga ) .And. (_lPorOnda)
				// atualiza campo de controle
				dbSelectArea("Z57")
				RecLock("Z57", .F.)
				Z57->Z57_STATUS := "03" // 03 - MAPA GERADO
				Z57->( MsUnLock() )
			EndIf

			// final transacao
		END TRANSACTION

		// fiz essa opções pois algumas rotinas mostram a mensagem da geração da OS direto na rotina
		If (mvMostraOS)
			U_FtWmsMsg("OS " + Alltrim(Z05->Z05_NUMOS) + " gerada.","ATENCAO")
		EndIf

		// avisa usuário se tiver barcode (cliente Sumitomo)
		If (_lTemBar)
			Help( Nil, Nil, 'TWMSA009.F01.002', Nil, "OS de expedição possui integração GWS (barcodes) e foi gerada com sucesso, porém bloqueada.", 1, 0, Nil, Nil, Nil, Nil, Nil,;
			{"É necessário agora aguardar a integração sistêmica, da Sumitomo, para liberar o apanhe da OS." + CRLF + "É *OBRIGATÓRIO* informar para a Sumitomo o número do pedido de venda Tecadi desta OS junto com a NF de retorno. " + CRLF + "Dúvidas consulte o manual de operações."})
		Endif

	EndIf

Return(_lOk)

// ** funcao que valida a geracao de OS
Static Function sfVldGerOS(mvTpOperaca, mvCarga, mvDoca, mvOndaSep)
	// variavel de retorno
	local _lRet := .t.

	// para OS de saida e servico 001, verifica o endereco de destino
	If (_lRet) .And. (mvTpOperaca=="S") .And. ((_TRBSERV)->CD_SERV=="001") .And. (Empty(mvDoca)) .And. ( ! Empty(mvCarga) ) .And. ( Empty(mvOndaSep) )
		// funcao para definir endereco de destino
		_lRet := sfDefDocaDest(mvCarga, mvOndaSep)
	EndIf

Return(_lRet)

// ** funcao para vincular a mercadoria da carga
User Function WMSA009D(mvCesv, mvTipVin, mvTela)

	// variaveis para browse
	local _aHeadDet := {}
	local _aColsDet := {}
	local _cQuery := ""
	// dimensoes da tela
	local _aSizeWnd := MsAdvSize()

	// objetos
	local _oBtnTodos
	local _oBtnSelKit
	local _oBtn01Confir, _oBtn01Fechar, _oBtn01Excluir

	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SZZ","Z05"})

	// sequencia de kit
	local _cSeqKit := "001"

	// permite editar dados
	local _lEdtDados := .t.

	//Contrato
	Local _cContrat := ""
	//Programação
	Local _cCodProg

	// verifica se o lote eh obrigatorio na entrada da nota
	local _lLotObrEnt := .f.

	// variavel para armazenar de que forma será vinculado o CESV com a NF (lastro/camada , qtd pallet, etc)
	private _cQtdCESV := ""

	// define se permite trabalhar com Kit
	private _lUsaKit := .t.

	// Valita controle de lote ativo.
	Private _lLotAtivo := .F.

	// objetos da tela
	private _oBrwDetVincNf

	//Tipo de Vinculo da Nota Fiscal 1-Mercadoria da Carga/NF 2-NF Complementar (TFAA) 3-Devolução de Mercadoria Sem Documento Fiscal
	Default mvTipVin := "1"

	//Variavel para controle de Tela (.T. = Chamado de um coletor de dados | .F. = Chamado do ERP Protheus)
	Default mvTela   := .F.

	If mvTela
		// resolucao da tela
		_aSizeDlg := GetScreenRes()
		// redimensiona medidas da resolucao de tela
		If (_aSizeDlg[1] > 400)
			_aSizeDlg[1] := 240
			_aSizeDlg[2] := 320
		Else
			_aSizeDlg[1] -= 8
			_aSizeDlg[2] -= 26
		EndIf
	EndIf

	// registro do CESV
	dbSelectArea("SZZ")
	SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
	SZZ->(dbSeek( xFilial("SZZ")+mvCESV ))

	// somente operacao de entrada
	If (SZZ->ZZ_OPERACA != "01")
		U_FtWmsMsg("Opção disponível somente para processo de recebimento de mercadoria.","ATENÇÃO")
		// restaura areas iniciais
		RestOrd(_aAreaIni,.t.)
		RestArea(_aArea)
		Return(.f.)
	EndIf

	// valida o status o CESV
	If (Empty(SZZ->ZZ_CLIENTE))
		U_FtWmsMsg("Para utilizar esta opção é necessário definir o cliente.","ATENCAO")
		// restaura areas iniciais
		RestOrd(_aAreaIni,.t.)
		RestArea(_aArea)
		Return(.f.)
	EndIf

	// valida TFAA
	If (mvTipVin == '2')
		// restaura areas iniciais
		//RestOrd(_aAreaIni,.t.)
		//RestArea(_aArea)
		//Return(.f.)
	EndIf

	// valida o status
	// 02-VEICULO LIBERADO / NO PATIO
	// 04-DOCA DEFINIDA
	// 05-LIBERADO PARA OPERACAO
	If ( ! SZZ->ZZ_STATUS $ "02|04|05") .And. (mvTipVin == '1')

		// valida tipo de operacao
		_lEdtDados := .f.

		//U_FtWmsMsg("CESV não está liberado para vincular as notas fiscais. Status Atual: "+SZZ->ZZ_STATUS,"ATENCAO")
		// restaura areas iniciais
		//RestOrd(_aAreaIni,.t.)
		//RestArea(_aArea)
		//Return(.f.)
	EndIf

	_cCodProg := SZZ->ZZ_PROCES

	// define se permite trabalhar com Kit
	_lUsaKit := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.f.,.f.,Nil, SZZ->ZZ_CLIENTE, SZZ->ZZ_LOJA, Nil, Nil)

	// valida se a programacao esta encerrada
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	If (SZ1->(dbSeek( xFilial("SZ1")+ _cCodProg )))
		If ( ! Empty(SZ1->Z1_DTFINFA))
			Aviso("Tecadi: TWMSA006","A programação " + _cCodProg + " encontra-se encerrada." + CRLF + "Contate o setor de Faturamento.",{"OK"})
			Return(.F.)
		EndIf
	Else
		Aviso("Tecadi: TWMSA006","Programação " + _cCodProg + " não encontrada." + CRLF + "Contate o setor de Faturamento.",{"OK"})
		Return(.F.)
	EndIf

	_cContrat := SZ1->Z1_CONTRT

	AAN->(DbSetOrder(1))
	cSeekAAN := xFilial("AAN") + _cContrat
	If(AAN->( DbSeek( cSeekAAN ) ) )
		If AAN->AAN_ZATIVO <> "S"
			Aviso("Tecadi: TWMSA006","Contrato " + _cContrat + " não esta ativo." + CRLF +  "Contate o setor de Faturamento.",{"OK"})
			Return(.F.)
		EndIf
	Else
		Aviso("Tecadi: TWMSA006","Contrato " + _cContrat + " não encontrado." + CRLF +  "Contate o setor de Faturamento.",{"OK"})
		Return(.F.)
	EndIf

	// verifica se o controle de lote esta ativo
	_lLotAtivo  := U_FtWmsParam("WMS_CONTROLE_POR_LOTE", "L", .F., .F., Nil, SZZ->ZZ_CLIENTE, SZZ->ZZ_LOJA, _cContrat, Nil)

	// verifica se o lote eh obrigatorio na entrada da nota
	_lLotObrEnt := U_FtWmsParam("WMS_LOTE_OBRIGATORIO_ENTRADA", "L", .F., .F., Nil, SZZ->ZZ_CLIENTE, SZZ->ZZ_LOJA, _cContrat, Nil)

	// define os campos de quantidade que poderão ser utilizados para vincular o CESV com a NF de entrada
	_cQtdCESV   := U_FtWmsParam("WMS_RECEBIMENTO_QTD_VINCULO_CESV", "C", "TODAS", .F., Nil, SZZ->ZZ_CLIENTE, SZZ->ZZ_LOJA, _cContrat, Nil)

	// Tipo de Vinculo da Nota Fiscal 1-Mercadoria da Carga/NF 2-NF Complementar (TFAA)
	If (mvTipVin $ "1|2")
		// monta a query
		If (_lEdtDados)
			_cQuery := "SELECT F1_DOC, F1_SERIE, F1_TIPO, D1_ITEM, D1_NUMSEQ, D1_COD, D1_DESCRIC, D1_LOCAL, D1_UM, "
			// calcula o saldo disponivel
			_cQuery += "D1_QUANT - "
			// menos o saldo distribuido em CESV
			_cQuery += "(SELECT ISNULL(SUM(Z04_QUANT),0) FROM "+RetSqlName("Z04")+"  (nolock)  WHERE Z04_FILIAL = F1_FILIAL AND D_E_L_E_T_ = '' AND Z04_CLIENT = F1_FORNECE AND Z04_LOJA = F1_LOJA AND Z04_TIPONF = F1_TIPO "
			_cQuery += "AND Z04_NF = F1_DOC AND Z04_SERIE = F1_SERIE AND Z04_ITEMNF = D1_ITEM AND Z04_PROD = D1_COD) - "
			// menos o que foi expedido manual
			_cQuery += "        (SELECT Isnull(Sum(DB_QUANT), 0) "
			_cQuery += "         FROM   "+RetSqlTab("SDB")+" (nolock) "
			_cQuery += "         WHERE  "+RetSqlCond("SDB")
			_cQuery += "                AND DB_ESTORNO = '' "
			_cQuery += "                AND DB_NUMSEQ = DA_NUMSEQ "
			_cQuery += "                AND DB_LOCALIZ = 'EXPMANUAL') D1_QUANT, "
			// quantidade para operacao
			If (_lLotAtivo)
				_cQuery += "D1_QUANT - "
				_cQuery += "(SELECT ISNULL(SUM(Z04_QUANT),0) FROM "+RetSqlName("Z04")+"  (nolock) WHERE Z04_FILIAL = F1_FILIAL AND D_E_L_E_T_ = '' AND Z04_CLIENT = F1_FORNECE AND Z04_LOJA = F1_LOJA AND Z04_TIPONF = F1_TIPO "
				_cQuery += "AND Z04_NF = F1_DOC AND Z04_SERIE = F1_SERIE AND Z04_ITEMNF = D1_ITEM AND Z04_PROD = D1_COD) IT_SALDO, "
			Else
				_cQuery += "0 IT_SALDO, "
			EndIf
			// lastro, camada e adicional
			_cQuery += "ISNULL(Z20_LASTRO,0) IT_LASTRO, "
			_cQuery += "ISNULL(Z20_CAMADA,0) IT_CAMADA, "
			_cQuery += "ISNULL(Z20_ADICIO,0) IT_ADICIO, "
			_cQuery += "0                    Z04_QTDPAL, "
			// cria coluna em branco para controle de Kit
			_cQuery += "'' Z29_SEQKIT, "
			_cQuery += "'' Z29_CODKIT, "
			// lote
			_cQuery += " D1_LOTECTL AS LOTE_CTL, "
			// segunda unidade de medida
			_cQuery += " D1_QTSEGUM, "
			// permite editar
			_cQuery += "'.T.' IT_ALT, "
			// controle de item deletado
			_cQuery += "'.F.' IT_DEL "
			// notas de entrada
			_cQuery += " FROM "+RetSqlTab("SF1")+" (nolock) "
			// itens da nota fiscal
			_cQuery += " INNER JOIN "+RetSqlTab("SD1")+"  (nolock) ON "+RetSqlCond("SD1")+" AND D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE AND D1_FORNECE = F1_FORNECE AND D1_LOJA = F1_LOJA "
			// novo cadastro de lastro e camada
			_cQuery += " LEFT  JOIN "+RetSqlTab("Z20")+"  (nolock) ON "+RetSqlCond("Z20")+" AND Z20_CODPRO = D1_COD AND Z20_LOCAL = D1_LOCAL AND Z20_MSBLQL != 2 "
			// somente saldo a enderecar
			_cQuery += " INNER JOIN "+RetSqlTab("SDA")+"  (nolock) ON "+RetSqlCond("SDA")+" AND DA_PRODUTO = D1_COD AND DA_LOCAL = D1_LOCAL AND DA_NUMSEQ = D1_NUMSEQ AND "
			_cQuery += "                                        DA_DOC = D1_DOC AND DA_SERIE = D1_SERIE AND DA_CLIFOR = D1_FORNECE AND DA_LOJA = D1_LOJA AND DA_SALDO > 0 "
			// saldo em poder de terceiros
			_cQuery += " INNER JOIN "+RetSqlTab("SB6")+"  (nolock) ON "+RetSqlCond("SB6")+" AND B6_IDENT = D1_IDENTB6 AND B6_PODER3 = 'R' AND B6_TPCF = 'C' "
			// filtro padrao da nota
			_cQuery += " WHERE "+RetSqlCond("SF1")
			_cQuery += " AND F1_TIPO IN ('B','D') "
			// cliente
			_cQuery += "AND F1_FORNECE = '"+SZZ->ZZ_CLIENTE+"' AND F1_LOJA = '"+SZZ->ZZ_LOJA+"' "
			// programacao
			_cQuery += "AND F1_PROGRAM = '"+SZZ->ZZ_PROCES+"' "
			// somente com saldo
			_cQuery += "AND (D1_QUANT - "
			_cQuery += "(SELECT ISNULL(SUM(Z04_QUANT),0) FROM "+RetSqlName("Z04")+" (nolock)  WHERE Z04_FILIAL = F1_FILIAL AND D_E_L_E_T_ = '' AND Z04_CLIENT = F1_FORNECE AND Z04_LOJA = F1_LOJA AND Z04_TIPONF = F1_TIPO "
			_cQuery += "AND Z04_NF = F1_DOC AND Z04_SERIE = F1_SERIE AND Z04_ITEMNF = D1_ITEM AND Z04_PROD = D1_COD) - "
			// menos o que foi expedido manual
			_cQuery += "        (SELECT Isnull(Sum(DB_QUANT), 0) "
			_cQuery += "         FROM   "+RetSqlTab("SDB")+" (nolock) "
			_cQuery += "         WHERE  "+RetSqlCond("SDB")
			_cQuery += "                AND DB_ESTORNO = '' "
			_cQuery += "                AND DB_NUMSEQ = DA_NUMSEQ "
			_cQuery += "                AND DB_LOCALIZ = 'EXPMANUAL') ) > 0 "
			// agruapado de query
			_cQuery += "UNION ALL "

		EndIf

		// inclui dados definidos anteriormente
		_cQuery += " SELECT Z04_NF     F1_DOC, "
		_cQuery += "        Z04_SERIE  F1_SERIE, "
		_cQuery += "        Z04_TIPONF F1_TIPO, "
		_cQuery += "        Z04_ITEMNF D1_ITEM, "
		_cQuery += "        Z04_NUMSEQ D1_NUMSEQ, "
		_cQuery += "        Z04_PROD   D1_COD, "
		_cQuery += "        CASE "
		_cQuery += "          WHEN ( ( Z04_SEQKIT = '' ) OR  ( Z04_SEQKIT != '' AND Z04_NUMSEQ != '' ) ) THEN (SELECT D1_DESCRIC FROM "+RetSqlName("SD1")+" SD1  (nolock) WHERE "+RetSqlCond("SD1")+" AND D1_NUMSEQ = Z04_NUMSEQ) "
		_cQuery += "          WHEN ( (Z04_SEQKIT != '' AND Z04_NUMSEQ = '') ) THEN (SELECT DISTINCT Z29_DSCKIT FROM "+RetSqlName("Z29")+" Z29 (nolock)  WHERE "+RetSqlCond("Z29")+" AND Z29_CODKIT = Z04_CODKIT) "
		_cQuery += "        END        D1_DESCRIC, "
		_cQuery += "        Z04_LOCAL  D1_LOCAL, "
		_cQuery += "        (SELECT DISTINCT D1_UM FROM " + RetSqlTab("SD1") + "  (nolock) WHERE " + RetSqlCond("SD1") + " AND D1_DOC = Z04_NF AND D1_SERIE = Z04_SERIE AND D1_NUMSEQ = Z04_NUMSEQ ) D1_UM, "
		_cQuery += "        Z04_QUANT  D1_QUANT, "
		_cQuery += "        Z04_QUANT  IT_SALDO, "
		_cQuery += "        Z04_LASTRO IT_LASTRO, "
		_cQuery += "        Z04_CAMADA IT_CAMADA, "
		_cQuery += "        Z04_ADICIO IT_ADICIO, "
		_cQuery += "        Z04_QTDPAL Z04_QTDPAL, "
		_cQuery += "        Z04_SEQKIT Z29_SEQKIT, "
		_cQuery += "        Z04_CODKIT Z29_CODKIT, "
		_cQuery += "        Z04_LOTCTL LOTE_CTL, "
		_cQuery += "        Z04_QTSEGU D1_QTSEGUM, "
		_cQuery += "        '.F.'     IT_ALT,  "
		_cQuery += "        '.F.'     IT_DEL "
		// dados da nota relacionado ao CESV
		_cQuery += "  FROM  "+RetSqlTab("Z04")+" (nolock) "
		_cQuery += " WHERE  "+RetSqlCond("Z04")
		_cQuery += "   AND  Z04_CESV = '"+SZZ->ZZ_CESV+"' "

		// ordem dos dados
		_cQuery += " ORDER BY Z29_CODKIT, F1_DOC, F1_SERIE, D1_ITEM "

		//Tipo de Vinculo da Nota Fiscal 3-Devolução de Mercadoria Sem Documento Fiscal
	ElseIf (mvTipVin $ "3")

		// monta a query
		If (_lEdtDados)
			_cQuery := "SELECT DB2_DOC F1_DOC, DB2_SERIE F1_SERIE, DB1_TIPONF F1_TIPO, DB3_ITEM D1_ITEM,'' D1_NUMSEQ, DB3_CODPRO D1_COD,B1_DESC D1_DESCRIC,DB1_ZLOCAL D1_LOCAL, "
			_cQuery += "  (SELECT DISTINCT D1_UM FROM " + RetSqlTab("SD1") + " (nolock)  WHERE " + RetSqlCond("SD1") + " AND D1_DOC = DB2_DOC AND D1_SERIE = DB2_SERIE AND D1_ITEM = DB3_ITEM AND D1_COD =  DB3_CODPRO) D1_UM, "
			// calcula o saldo disponivel
			_cQuery += "DB3_QUANT - "
			_cQuery += "(SELECT ISNULL(SUM(Z04_QUANT),0) FROM "+RetSqlName("Z04")+" (nolock)  WHERE Z04_FILIAL = DB1_FILIAL AND D_E_L_E_T_ = '' AND Z04_CLIENT = DB1_CLIFOR AND Z04_LOJA = DB1_LOJA AND Z04_TIPONF = DB1_TIPONF "
			_cQuery += "AND Z04_NF = DB2_DOC AND Z04_SERIE = DB2_SERIE AND Z04_ITEMNF = DB3_ITEM AND Z04_PROD = DB3_CODPRO) D1_QUANT, "
			// quantidade para operacao
			If _lLotAtivo
				_cQuery += "DB3_QUANT - "
				_cQuery += "(SELECT ISNULL(SUM(Z04_QUANT),0) FROM "+RetSqlName("Z04")+" (nolock)  WHERE Z04_FILIAL = DB1_FILIAL AND D_E_L_E_T_ = '' AND Z04_CLIENT = DB1_CLIFOR AND Z04_LOJA = DB1_LOJA AND Z04_TIPONF = DB1_TIPONF "
				_cQuery += "AND Z04_NF = DB2_DOC AND Z04_SERIE = DB2_SERIE AND Z04_ITEMNF = DB3_ITEM AND Z04_PROD = DB3_CODPRO) IT_SALDO, "
			Else
				_cQuery += "0 IT_SALDO, "
			EndIf
			// lastro, camada e adicional
			_cQuery += "ISNULL(Z20_LASTRO,0) IT_LASTRO, "
			_cQuery += "ISNULL(Z20_CAMADA,0) IT_CAMADA, "
			_cQuery += "ISNULL(Z20_ADICIO,0) IT_ADICIO, "
			_cQuery += "0                    Z04_QTDPAL, "
			// cria coluna em branco para controle de Kit
			_cQuery += "'' Z29_SEQKIT, "
			_cQuery += "'' Z29_CODKIT, "
			_cQuery += "'' LOTE_CTL, "
			_cQuery += "0 D1_QTSEGUM, "
			_cQuery += "'.T.' IT_ALT, "
			// controle de item deletado
			_cQuery += "'.F.' IT_DEL "
			// AVISO DE RECEBIMENTO DE CARGA
			_cQuery += " FROM "+RetSqlTab("DB1")+" (nolock) "
			// CABECALHO DOC DE RECEBIMENTO
			_cQuery += " INNER JOIN "+RetSqlTab("DB2")+"  (nolock) ON "+RetSqlCond("DB2")+" AND DB1_NRAVRC = DB2_NRAVRC "

			// ITENS DO DOC DE RECEBIMENTO
			_cQuery += " INNER JOIN "+RetSqlTab("DB3")+"  (nolock) ON "+RetSqlCond("DB3")+" AND DB1_NRAVRC = DB3_NRAVRC "

			// Produtos
			_cQuery += " INNER JOIN "+RetSqlTab("SB1")+"  (nolock) ON "+RetSqlCond("SB1")+" AND B1_COD = DB3_CODPRO "

			// novo cadastro de lastro e camada
			_cQuery += " LEFT  JOIN "+RetSqlTab("Z20")+"  (nolock) ON "+RetSqlCond("Z20")+" AND Z20_CODPRO = DB3_CODPRO AND Z20_LOCAL = DB1_ZLOCAL "

			// filtro RECEBIMENTO DE CARGA
			_cQuery += "WHERE "+RetSqlCond("DB1")+" "
			_cQuery += "AND DB1_TIPONF IN ('B','D') "
			// cliente
			_cQuery += "AND DB1_CLIFOR = '"+SZZ->ZZ_CLIENTE+"' AND DB1_LOJA = '"+SZZ->ZZ_LOJA+"' "

			// programacao
			_cQuery += "AND DB1_ZPROGR = '"+SZZ->ZZ_PROCES+"' "

			// somente com saldo
			_cQuery += "AND (DB3_QUANT - "
			_cQuery += "(SELECT ISNULL(SUM(Z04_QUANT),0) FROM "+RetSqlName("Z04")+" (nolock)  WHERE Z04_FILIAL = DB1_FILIAL AND D_E_L_E_T_ = '' AND Z04_CLIENT = DB1_CLIFOR AND Z04_LOJA = DB1_LOJA AND Z04_TIPONF = DB1_TIPONF "
			_cQuery += "AND Z04_NF = DB2_DOC AND Z04_SERIE = DB2_SERIE AND Z04_ITEMNF = DB3_ITEM AND Z04_PROD = DB3_CODPRO)) > 0 "

			// agruapado de query
			_cQuery += "UNION ALL "

		EndIf

		// inclui dados definidos anteriormente
		_cQuery += "SELECT Z04_NF     F1_DOC, "
		_cQuery += "       Z04_SERIE  F1_SERIE, "
		_cQuery += "       Z04_TIPONF F1_TIPO, "
		_cQuery += "       Z04_ITEMNF D1_ITEM, "
		_cQuery += "       Z04_NUMSEQ D1_NUMSEQ, "
		_cQuery += "       Z04_PROD   D1_COD, "
		_cQuery += "       CASE "
		_cQuery += "         WHEN ( ( Z04_SEQKIT = '' ) OR  ( Z04_SEQKIT != '' AND Z04_NUMSEQ != '' ) ) THEN (SELECT B1_DESC FROM "+RetSqlTab("SB1")+" (nolock)  WHERE SB1.D_E_L_E_T_ = '' AND B1_COD = Z04_PROD) "
		_cQuery += "         WHEN ( (Z04_SEQKIT != '' AND Z04_NUMSEQ = '') ) THEN (SELECT DISTINCT Z29_DSCKIT FROM "+RetSqlTab("Z29")+" (nolock)  WHERE "+RetSqlCond("Z29")+" AND Z29_CODKIT = Z04_CODKIT) "
		_cQuery += "       END        D1_DESCRIC, "
		_cQuery += "       Z04_LOCAL  D1_LOCAL, "
		_cQuery += "       (SELECT DISTINCT D1_UM FROM " + RetSqlTab("SD1") + " (nolock)  WHERE " + RetSqlCond("SD1") + " AND D1_DOC = Z04_NF AND D1_SERIE = Z04_SERIE AND D1_NUMSEQ = Z04_NUMSEQ ) D1_UM, "
		_cQuery += "       Z04_QUANT  D1_QUANT, "
		_cQuery += "       Z04_QUANT  IT_SALDO, "
		_cQuery += "       Z04_LASTRO IT_LASTRO, "
		_cQuery += "       Z04_CAMADA IT_CAMADA, "
		_cQuery += "       Z04_ADICIO IT_ADICIO, "
		_cQuery += "       Z04_QTDPAL Z04_QTDPAL, "
		_cQuery += "       Z04_SEQKIT Z29_SEQKIT, "
		_cQuery += "       Z04_CODKIT Z29_CODKIT, "
		_cQuery += "       Z04_LOTCTL LOTE_CTL, "
		_cQuery += "       Z04_QTSEGU D1_QTSEGUM, "
		_cQuery += "       '.F.'      IT_ALT,  "
		_cQuery += "       '.F.'      IT_DEL "
		// dados da nota relacionado ao CESV
		_cQuery += "  FROM  "+RetSqlTab("Z04")+" (nolock) "
		_cQuery += " WHERE  "+RetSqlCond("Z04")
		_cQuery += "   AND  Z04_CESV = '"+SZZ->ZZ_CESV+"' "

		// ordem dos dados
		_cQuery += "ORDER BY Z29_CODKIT, F1_DOC, F1_SERIE, D1_ITEM "

	EndIf

	memowrit("c:\query\twmsa009_sfMercCarga.txt",_cQuery)

	// adiciona o conteudo da query para um array
	_aColsDet := U_SqlToVet(_cQuery)

	// verifica se ha notas fiscais disponiveis
	If (Len(_aColsDet) == 0)
		// mensagem
		U_FtWmsMsg("Não há notas fiscais disponíveis!","ATENCAO")
		// restaura areas iniciais
		RestOrd(_aAreaIni,.t.)
		RestArea(_aArea)
		Return(.f.)
	EndIf

	// define todos os campos do header
	aAdd(_aHeadDet,{"Doc. Fiscal"    ,"F1_DOC"    , PesqPict("SF1","F1_DOC")     , TamSx3("F1_DOC")[1]    , 0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Serie"          ,"F1_SERIE"  , PesqPict("SF1","F1_SERIE")   , TamSx3("F1_SERIE")[1]  , 0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Tipo NF"        ,"F1_TIPO"   , PesqPict("SF1","F1_TIPO")    , TamSx3("F1_TIPO")[1]   , 0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Item"           ,"D1_ITEM"   , PesqPict("SD1","D1_ITEM")    , TamSx3("D1_ITEM")[1]   , 0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Num Seq"        ,"D1_NUMSEQ" , ""                           , TamSx3("D1_NUMSEQ")[1] , 0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Produto"        ,"D1_COD"    , PesqPict("SD1","D1_COD")     , TamSx3("D1_COD")[1]    , 0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Descrição"      ,"D1_DESCRIC", PesqPict("SD1","D1_DESCRIC") , TamSx3("D1_DESCRIC")[1], 0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Armazém"        ,"D1_LOCAL"  , PesqPict("SD1","D1_LOCAL")   , TamSx3("D1_LOCAL")[1]  , 0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"U.M."           ,"D1_UM"     , PesqPict("SD1","D1_UM")      , TamSx3("D1_UM")[1]     , 0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Saldo Disp."    ,"D1_QUANT"  , PesqPict("SD1","D1_QUANT")   , TamSx3("D1_QUANT")[1]  , TamSx3("D1_QUANT")[2]  ,Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Quant. Selec."  ,"IT_SALDO"  , PesqPict("SD1","D1_QUANT")   , TamSx3("D1_QUANT")[1]  , TamSx3("D1_QUANT")[2]  ,"U_WMSA009A()",Nil,"N",Nil,"R",,,'.T.' })
	aAdd(_aHeadDet,{"Lastro"         ,"IT_LASTRO" , PesqPict("Z20","Z20_LASTRO") , TamSx3("Z20_LASTRO")[1], TamSx3("Z20_LASTRO")[2],"Positivo() .And. StaticCall(TWMSA009,sfVaLPaLxC,1)"  ,Nil,"N",Nil,"R",,,'IIf(_oBrwDetVincNf:aCols[n,aScan(_oBrwDetVincNf:aHeader,{|x| AllTrim(x[2])=="IT_ALT"})] .And. (_oBrwDetVincNf:aCols[n,aScan(_oBrwDetVincNf:aHeader,{|x| AllTrim(x[2])=="Z04_QTDPAL"})] == 0 ),.T.,.F.)' })
	aAdd(_aHeadDet,{"Camada"         ,"IT_CAMADA" , PesqPict("Z20","Z20_CAMADA") , TamSx3("Z20_CAMADA")[1], TamSx3("Z20_CAMADA")[2],"Positivo() .And. StaticCall(TWMSA009,sfVaLPaLxC,1)"  ,Nil,"N",Nil,"R",,,'IIf(_oBrwDetVincNf:aCols[n,aScan(_oBrwDetVincNf:aHeader,{|x| AllTrim(x[2])=="IT_ALT"})] .And. (_oBrwDetVincNf:aCols[n,aScan(_oBrwDetVincNf:aHeader,{|x| AllTrim(x[2])=="Z04_QTDPAL"})] == 0 ),.T.,.F.)' })
	aAdd(_aHeadDet,{"Adicional"      ,"IT_ADICIO" , PesqPict("Z20","Z20_ADICIO") , TamSx3("Z20_ADICIO")[1], TamSx3("Z20_ADICIO")[2],"Positivo() .And. StaticCall(TWMSA009,sfVaLPaLxC,1)"  ,Nil,"N",Nil,"R",,,'IIf(_oBrwDetVincNf:aCols[n,aScan(_oBrwDetVincNf:aHeader,{|x| AllTrim(x[2])=="IT_ALT"})] .And. (_oBrwDetVincNf:aCols[n,aScan(_oBrwDetVincNf:aHeader,{|x| AllTrim(x[2])=="Z04_QTDPAL"})] == 0 ),.T.,.F.)' })
	aAdd(_aHeadDet,{"Quant. palete"  ,"Z04_QTDPAL", PesqPict("Z04","Z04_QTDPAL") , TamSx3("Z04_QTDPAL")[1], TamSx3("Z04_QTDPAL")[2],"Positivo() .And. StaticCall(TWMSA009,sfVaLPaLxC,2)"  ,Nil,"N",Nil,"R",,,'IIf(_oBrwDetVincNf:aCols[n,aScan(_oBrwDetVincNf:aHeader,{|x| AllTrim(x[2])=="IT_ALT"})] .And. ( (_oBrwDetVincNf:aCols[n,aScan(_oBrwDetVincNf:aHeader,{|x| AllTrim(x[2])=="IT_LASTRO"})] == 0 ) .And. (_oBrwDetVincNf:aCols[n,aScan(_oBrwDetVincNf:aHeader,{|x| AllTrim(x[2])=="IT_CAMADA"})] == 0 ) .And. (_oBrwDetVincNf:aCols[n,aScan(_oBrwDetVincNf:aHeader,{|x| AllTrim(x[2])=="IT_ADICIO"})] == 0 ) ),.T.,.F.)' })
	aAdd(_aHeadDet,{"Seq do Kit"     ,"Z29_SEQKIT", ""                           , 3                      , 0                      ,Nil           ,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDet,{"Codigo do Kit"  ,"Z29_CODKIT", PesqPict("Z29","Z29_CODKIT") , TamSx3("Z29_CODKIT")[1], TamSx3("Z29_CODKIT")[2],Nil           ,Nil,"C",Nil,"R",,,".F.",,,,.f. })
	aAdd(_aHeadDet,{"Lote"           ,"Z04_LOTCTL", PesqPict("Z04","Z04_LOTCTL") , TamSx3("Z04_LOTCTL")[1], TamSx3("Z04_LOTCTL")[2],Nil           ,Nil,"C",Nil,"R",,,".F.",,,,.f. })
	aAdd(_aHeadDet,{"Qtd.Seg.UM"     ,"D1_QTSEGUM", PesqPict("SD1","D1_QTSEGUM") , TamSx3("D1_QTSEGUM")[1], TamSx3("D1_QTSEGUM")[2],Nil           ,Nil,"N",Nil,"R",,,".T.",,,,.f. })
	aAdd(_aHeadDet,{"Edita"          ,"IT_ALT"    , ""                           , 1                      , 0                      ,Nil           ,Nil,"C",Nil,"R",,,".F.",,,,.f. })

	//Rotina Chamada do Coletor de Dados
	If mvTela
		// definicao da tela
		_oDlgDetalhes := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"Vincular documento fiscal",,,.F.,,,,,,.T.,,,.T. )
		_oDlgDetalhes:lEscClose := .F.
	Else
		// definicao da tela
		_oDlgDetalhes := MSDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"Vincular documento fiscal",,,.F.,,,,,,.T.,,,.T. )
		_oDlgDetalhes:lMaximized := .T.
	EndIf

	// cria o panel do cabecalho - botoes
	_oPnlCabec1 := TPanel():New(000,000,nil,_oDlgDetalhes,,.F.,.F.,,,000,030,.T.,.F. )
	_oPnlCabec1:Align:= CONTROL_ALIGN_TOP

	//Rotina Chamada do Coletor de Dados
	If mvTela
		// botao todos
		If (_lEdtDados)
			_oBtnTodos := TBtnBmp2():New(000,000,040,040,"ANALITICO",,,,{|| sfVincTodos(_oBrwDetVincNf) },_oPnlCabec1,"Todos",,.T. )
			_oBtnTodos:Align := CONTROL_ALIGN_LEFT
		EndIf
		// botao para selecionar os Kit
		If (_lEdtDados) .And. (_lUsaKit)
			_oBtnSelKit := TBtnBmp2():New(000,000,040,040,"AVGBOX1",,,,{|| sfSelecKit(@_cSeqKit) },_oPnlCabec1,"Seleciona Kit",,.T. )
			_oBtnSelKit:Align := CONTROL_ALIGN_LEFT
		EndIf

		// -- botao Sair
		_oBtn01Fechar := TBtnBmp2():New(000,((_aSizeDlg[1]/2)-  50),040,040,"FINAL",,,,{|| _oDlgDetalhes:End() },_oPnlCabec1,"Sair",,.T. )
		_oBtn01Fechar:Align := CONTROL_ALIGN_RIGHT

		// botao confirmar
		If (_lEdtDados)
			// -- CONFIRMACAO
			_oBtn01Confir := TBtnBmp2():New(000,((_aSizeDlg[1]/2)- 100),040,040,"OK",,,,{|| sfConfVincNf() },_oPnlCabec1,"Ok",,.T.)
			_oBtn01Confir:Align := CONTROL_ALIGN_RIGHT
		EndIf
	Else
		// botao todos
		If (_lEdtDados)
			_oBtnTodos := TButton():New(010,010,"Todos",_oPnlCabec1,{|| sfVincTodos(_oBrwDetVincNf) },045,012,,,,.T.,,"",,,,.F. )
		EndIf
		// botao para selecionar os Kit
		If (_lEdtDados) .And. (_lUsaKit)
			_oBtnSelKit := TButton():New(010,060,"Seleciona Kit" ,_oPnlCabec1,{|| sfSelecKit(@_cSeqKit) } ,045,012,,,,.T.,,"",,,,.F. )
		EndIf

		// botão para excluir vínculo (Z04)
		If ( ! _lEdtDados )
			_oBtn01Excluir := TButton():New(010,((_aSizeWnd[5]/2)- 100),"Excluir" ,_oPnlCabec1,{|| IIF (sfExclVincNf(),_oDlgDetalhes:End(),Nil)  },045,012,,,,.T.,,"",,,,.F. )
		EndIf

		// botao confirmar
		If (_lEdtDados)
			_oBtn01Confir := TButton():New(010,((_aSizeWnd[5]/2)- 100),"Confirmar" ,_oPnlCabec1,{|| sfConfVincNf() },045,012,,,,.T.,,"",,,,.F. )
		EndIf
		// botao cancelar
		_oBtn01Fechar := TButton():New(010,((_aSizeWnd[5]/2)-  50),"Fechar"  ,_oPnlCabec1,{|| _oDlgDetalhes:End() },045,012,,,,.T.,,"",,,,.F. )

	EndIf

	// monta o browse
	_oBrwDetVincNf := MsNewGetDados():New(000,000,400,400,IIf(_lEdtDados,GD_UPDATE+GD_DELETE,Nil),'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDet),'AllwaysTrue()','','AllwaysTrue()',_oDlgDetalhes,_aHeadDet,_aColsDet)
	_oBrwDetVincNf:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa o dialogo
	_oDlgDetalhes:Activate(,,,.T.,,, )

Return

// ** Função que realiza a troca do tipo de calculo do Produto(Lastro X Camada - Qtd. Pelete)
Static Function sfVaLPaLxC(mvCampo)

	Local _lRet := .T.

	If mvCampo == 1
		_oBrwDetVincNf:aCols[n,aScan(_oBrwDetVincNf:aHeader,{|x| AllTrim(x[2])=="Z04_QTDPAL"})]  := 0
	Else
		_oBrwDetVincNf:aCols[n,aScan(_oBrwDetVincNf:aHeader,{|x| AllTrim(x[2])=="IT_LASTRO"})]  := 0
		_oBrwDetVincNf:aCols[n,aScan(_oBrwDetVincNf:aHeader,{|x| AllTrim(x[2])=="IT_CAMADA"})]  := 0
		_oBrwDetVincNf:aCols[n,aScan(_oBrwDetVincNf:aHeader,{|x| AllTrim(x[2])=="IT_ADICIO"})]  := 0
	EndIF

Return(_lRet)

// ** funcao que valida a quantidade informada
User Function WMSA009A
	// header do Browse
	local _aHeadBrw := aClone(_oBrwDetVincNf:aHeader)
	// variavel de retorno
	local _lRet := .t.
	// posicao dos campos
	local _nPosSaldo  := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="D1_QUANT"})   // saldo disponivel
	local _nPosCodKit := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="Z29_CODKIT"}) // cod do kit
	// saldo disponivel
	local _nSaldoDisp := _oBrwDetVincNf:aCols[_oBrwDetVincNf:nAt][_nPosSaldo]
	// codigo do kit
	local _cCodKit := IIf((_lUsaKit) .And. (_nPosCodKit > 0), _oBrwDetVincNf:aCols[_oBrwDetVincNf:nAt][_nPosCodKit], "")

	// compara quantidade com o saldo
	If ( M->IT_SALDO > _nSaldoDisp )
		MsgStop("A quantidade não pode ser superior ao saldo disponível.")
		_lRet := .f.
	EndIf

	// valida alteracao em quantidade de kit
	If (_lUsaKit) .And. ( ! Empty(_cCodKit))
		MsgStop("Não é permitido alteração da quantidade do Kit.")
		_lRet := .f.
	EndIf

Return(_lRet)

// ** funcao que grava os itens da nota
Static Function sfConfVincNf()
	// variavel de retorno
	local _lRet := .f.
	// variaveis temporarias
	local _nItem
	// header do Browse
	local _aHeadBrw := aClone(_oBrwDetVincNf:aHeader)
	// posicao dos campos no browse
	local _nPosTipoNf := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="F1_TIPO"})    // tipo nf
	local _nPosDoc    := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="F1_DOC"})     // nota fiscal
	local _nPosSerie  := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="F1_SERIE"})   // serie
	local _nPosItem   := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="D1_ITEM"})    // serie
	local _nPosProd   := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="D1_COD"})     // serie
	local _nPosLocal  := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="D1_LOCAL"})   // local/armazem
	local _nPosSaldo  := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="D1_QUANT"})   // saldo disponivel
	local _nPosQuant  := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="IT_SALDO"})   // quantidade
	local _nPosNumSeq := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="D1_NUMSEQ"})  // num seq
	local _nPosLastro := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="IT_LASTRO"})  // lastro
	local _nPosCamada := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="IT_CAMADA"})  // camada
	local _nPosAdicio := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="IT_ADICIO"})  // adicional
	local _nPosQtdPal := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="Z04_QTDPAL"}) // Quantidade de Palete
	local _nPosSeqKit := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="Z29_SEQKIT"}) // seq do kit
	local _nPosCodKit := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="Z29_CODKIT"}) // cod do kit
	local _nPosEdita  := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="IT_ALT"})     // permite editar conteudo
	local _nPosLote   := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="Z04_LOTCTL"}) // lote
	local _nPosQtSeg  := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="D1_QTSEGUM"}) // quantidade segunda unidade de medida

	// controle de validacao da linha, conforme regra de kit
	local _lVldLinha := .f.

	// armazem/local atual
	local _cArmzAtual := CriaVar("BE_LOCAL",.f.)

	// Tipo Contrato para cotacao
	local cPLTPADR := SuperGetMV('TC_PLTPADR',.F.,"000001")

	// inicia transacao
	BEGIN TRANSACTION

		// busca o armazem padrao por cliente
		_cArmzAtual := U_FtWmsParam("WMS_ARMAZEM_POR_CLIENTE","C","A1",.f.,Nil, SZZ->ZZ_CLIENTE, SZZ->ZZ_LOJA, Nil, Nil)

		// varre todos os itens do browse
		For _nItem := 1 to Len(_oBrwDetVincNf:aCols)

			// verifica se o item nao esta excluido e se tem saldo
			If ( ! _oBrwDetVincNf:aCols[_nItem,Len(_aHeadBrw)+1] ) .And. (_oBrwDetVincNf:aCols[_nItem,_nPosQuant] > 0)

				// controle de validacao da linha, conforme regra de kit
				_lVldLinha := .f.

				// verifica se o Item não esta Bloqueado para realizar alteração.
				If (_oBrwDetVincNf:aCols[_nItem,_nPosEdita])

					// valida sempre, quando nao usa kit
					If ( ! _lUsaKit )
						_lVldLinha := .t.

					ElseIf (_lUsaKit)
						// verifica sequencia do kit / e nf em branco
						If (( ! Empty(_oBrwDetVincNf:aCols[_nItem,_nPosSeqKit])) .And. (Empty(_oBrwDetVincNf:aCols[_nItem,_nPosDoc]))).or.((Empty(_oBrwDetVincNf:aCols[_nItem,_nPosSeqKit])) .And. ( ! Empty(_oBrwDetVincNf:aCols[_nItem,_nPosDoc])))
							_lVldLinha := .t.
						EndIf
					EndIf

					// valida se lastro/camada ou quantidade de pallets estão preenchidos (se todos não estão zerados)
					If (_lVldLinha) .And. ((_oBrwDetVincNf:aCols[_nItem,_nPosLastro] == 0).or.(_oBrwDetVincNf:aCols[_nItem,_nPosCamada] == 0)) .And. (_oBrwDetVincNf:aCols[_nItem,_nPosQtdPal] == 0)
						// mensagem
						U_FtWmsMsg("Favor verificar (lastro e camada) ou Quantidade de Palete do produto. Item: "+_oBrwDetVincNf:aCols[_nItem,_nPosItem],"ATENÇÃO")
						// rollback na transacao
						_lRet := .F.
						DisarmTransaction()
						Break
					EndIf

					// valida se foi informado apenas o campo "adicional" e se lastro/camada ficaram em branco
					If (_lVldLinha) .And. (_oBrwDetVincNf:aCols[_nItem,_nPosAdicio] > 0) .And. ( (_oBrwDetVincNf:aCols[_nItem,_nPosLastro] == 0).or.(_oBrwDetVincNf:aCols[_nItem,_nPosCamada] == 0) )
						// mensagem
						U_FtWmsMsg("Favor verificar o adicional de lastro e camada do produto. Item: "+_oBrwDetVincNf:aCols[_nItem,_nPosItem],"ATENÇÃO")
						// rollback na transacao
						_lRet := .F.
						DisarmTransaction()
						Break
					EndIf

					//Se Produto Tem Lastro e Camada
					If (_lVldLinha) .And. ((_oBrwDetVincNf:aCols[_nItem,_nPosLastro] > 0) .And. (_oBrwDetVincNf:aCols[_nItem,_nPosCamada] > 0))

						// cad. de lastro e camada do produto por filial
						dbSelectArea("Z20")
						Z20->(dbOrderNickName("Z20_CODPRO")) // Z20_FILIAL, Z20_CODPRO, Z20_LOCAL, Z20_UNITIZ
						If ! Z20->(dbSeek( xFilial("Z20")+_oBrwDetVincNf:aCols[_nItem,_nPosProd] ))
							// quando estiver zerado, atualiza os campos
							RecLock("Z20",.t.)
							Z20->Z20_FILIAL := xFilial("Z20")
							Z20->Z20_CODPRO := _oBrwDetVincNf:aCols[_nItem,_nPosProd]
							Z20->Z20_LOCAL  := _cArmzAtual
							Z20->Z20_UNITIZ := cPLTPADR
							Z20->Z20_LASTRO := _oBrwDetVincNf:aCols[_nItem,_nPosLastro]
							Z20->Z20_CAMADA := _oBrwDetVincNf:aCols[_nItem,_nPosCamada]
							Z20->Z20_ADICIO := _oBrwDetVincNf:aCols[_nItem,_nPosAdicio]
							Z20->(MsUnLock())
						EndIf
					EndIf

					// tratamento para validar o campo que pode ser utilizado para as quantidades
					// utilizadas para conferência/recebimento de acordo com o permitido (redmine #167)
					If (_lVldLinha) .And. (_cQtdCESV != "TODAS")

						//se configurado para permitir apenas informar quantidade de pallets
						If  (_cQtdCESV == "PALLETS") .And. ( (_oBrwDetVincNf:aCols[_nItem,_nPosLastro] != 0) .OR. (_oBrwDetVincNf:aCols[_nItem,_nPosCamada] != 0))
							// mensagem de erro
							MsgStop("Cliente configurado para permitir informar apenas quantidade de pallets." + CRLF + CRLF ;
							+ "Remova lastro/camada do item: " + _oBrwDetVincNf:aCols[_nItem,_nPosItem],;
							"ATENÇÃO")

							// rollback na transacao
							_lRet := .F.
							DisarmTransaction()
							Break
						ElseIf (_cQtdCESV == "LASTRO") .And. ( (_oBrwDetVincNf:aCols[_nItem,_nPosQtdPal] != 0) )
							//se configurado para permitir apenas informar lastro/camada

							//mensagem de erro
							MsgStop("Cliente configurado para permitir informar apenas lastro/camada/adicional." + CRLF + CRLF ;
							+ "Remova quantidade de pallets do item: " + _oBrwDetVincNf:aCols[_nItem,_nPosItem],;
							"ATENÇÃO")

							// rollback na transacao
							_lRet := .F.
							DisarmTransaction()
							Break
						EndIf
					EndIf

					// insere nota fiscal
					dbSelectArea("Z04")
					RecLock("Z04",.T.)
					Z04->Z04_FILIAL  := xFilial("Z04")
					Z04->Z04_CESV    := SZZ->ZZ_CESV
					Z04->Z04_CLIENT  := SZZ->ZZ_CLIENTE
					Z04->Z04_LOJA    := SZZ->ZZ_LOJA
					Z04->Z04_TIPONF  := _oBrwDetVincNf:aCols[_nItem,_nPosTipoNf]
					Z04->Z04_NF      := _oBrwDetVincNf:aCols[_nItem,_nPosDoc]
					Z04->Z04_SERIE   := _oBrwDetVincNf:aCols[_nItem,_nPosSerie]
					Z04->Z04_ITEMNF  := _oBrwDetVincNf:aCols[_nItem,_nPosItem]
					Z04->Z04_NUMSEQ  := _oBrwDetVincNf:aCols[_nItem,_nPosNumSeq]
					Z04->Z04_PROD    := _oBrwDetVincNf:aCols[_nItem,_nPosProd]
					Z04->Z04_LOCAL   := _oBrwDetVincNf:aCols[_nItem,_nPosLocal]
					Z04->Z04_QUANT   := _oBrwDetVincNf:aCols[_nItem,_nPosQuant]
					Z04->Z04_PROCES  := SZZ->ZZ_PROCES
					Z04->Z04_LASTRO  := _oBrwDetVincNf:aCols[_nItem,_nPosLastro]
					Z04->Z04_CAMADA  := _oBrwDetVincNf:aCols[_nItem,_nPosCamada]
					Z04->Z04_ADICIO  := _oBrwDetVincNf:aCols[_nItem,_nPosAdicio]
					Z04->Z04_QTDPAL  := _oBrwDetVincNf:aCols[_nItem,_nPosQtdPal]
					// dados especifico para uso de kit
					Z04->Z04_SEQKIT := _oBrwDetVincNf:aCols[_nItem,_nPosSeqKit]
					Z04->Z04_CODKIT := _oBrwDetVincNf:aCols[_nItem,_nPosCodKit]
					// se eh o produto principal
					If ( ! Empty(_oBrwDetVincNf:aCols[_nItem,_nPosNumSeq]) .And. (Empty(_oBrwDetVincNf:aCols[_nItem,_nPosSeqKit])))
						Z04->Z04_PRDPAI := "S"
					ElseIf ( Empty(_oBrwDetVincNf:aCols[_nItem,_nPosNumSeq]) .And. ( ! Empty(_oBrwDetVincNf:aCols[_nItem,_nPosSeqKit])))
						Z04->Z04_PRDPAI := "S"
					Else
						Z04->Z04_PRDPAI := "N"
					EndIf
					Z04->Z04_LOTCTL := _oBrwDetVincNf:aCols[_nItem,_nPosLote]
					Z04->Z04_QTSEGU := _oBrwDetVincNf:aCols[_nItem,_nPosQtSeg]
					Z04->(MsUnLock())

					// atualiza variavel de retorno
					_lRet := .t.

				EndIf
			EndIf
		Next _nItem

		// verifica se o relacionamento de notas fiscais estava ok
		If (_lRet)

			// insere o log
			U_FtGeraLog(cFilAnt, "SZZ", xFilial("SZZ")+SZZ->ZZ_CESV, "Definida mercadorias por veículo. (Status "+SZZ->ZZ_STATUS+" para 06)", "WMS")

			// atualiza as informacoes das tabelas
			dbSelectArea("SZZ")
			RecLock("SZZ")
			SZZ->ZZ_STATUS := "06" // 06-EM PLANEJAMENTO
			SZZ->(MsUnLock())

		EndIf

		// final transacao
	END TRANSACTION

	// fecha a tela de relacionar itens da nota
	_oDlgDetalhes:End()

Return(_lRet)

// ** funcao para impressao de etiquetas
User Function WMSA009C(mvNumos)
	// area inicial
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"SZZ"})
	// controle da confirmacao da tela
	local _lOk := .f.
	local _cTipoEtiq := ""
	local _cOperEtiq := ""

	// tela para selecionar o tipo da etiqueta
	_oDlgSelEtq := MSDialog():New(000,000,080,200,"Tipos de Etiquetas",,,.F.,,,,,,.T.,,,.T. )
	_oCBxTpEtiq := TComboBox():New( 004,004,{|u| If(PCount()>0,_cTipoEtiq:=u,_cTipoEtiq)},{"01-Produto","04-Volumes"},092,010,_oDlgSelEtq,,,,,,.T.,,"",,,,,,,_cTipoEtiq )
	_oBtnEtqOk  := SButton():New( 018,040,1,{ || _lOk := .t. , _oDlgSelEtq:End() },_oDlgSelEtq,,"", )
	_oBtnEtqCan := SButton():New( 018,068,2,{ || _oDlgSelEtq:End() },_oDlgSelEtq,,"", )

	_oDlgSelEtq:Activate(,,,.T.)

	If (_lOk)

		// posiciono na OS
		dbSelectArea("Z05")
		Z05->(dbSetOrder(1)) //1-Z05_FILIAL, Z05_NUMOS
		Z05->(dbSeek( xFilial("Z05")+mvNumos ))

		If ( ! Z05->(Found()) )
			U_FtWmsMsg("OS não encontrada!")
			Return (.F.)
		EndIf

		// registro do CESV
		dbSelectArea("SZZ")
		SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
		SZZ->(dbSeek( xFilial("SZZ")+Z05->Z05_CESV ))

		If ( ! SZZ->(Found()))
			U_FtWmsMsg("CESV não encontrada!")
			Return (.F.)
		EndIf

		// valida a operação a ser executada
		_cOperEtiq := U_FtMultRet("Imprimir. Etiq", "Excluir. Etiq", "imprime", "exclui", "Etiquetas", "Escolha a opção desejada:")

		// se for só impressão, segue rotina padrão
		If (_cOperEtiq == "imprime")
			// 01-produtos
			If (Left(_cTipoEtiq,2) == "01")

				If (_cOperEtiq == "imprime")
					// rotina para impressao das etiquetas de produtos conforme movimentacao do veiculo
					U_TWMSR008(SZZ->ZZ_CLIENTE,SZZ->ZZ_LOJA,;
					SZZ->ZZ_CESV,;
					Nil )
				EndIf

				// 04-Volumes
			ElseIf (Left(_cTipoEtiq,2) == "04")

				If (_cOperEtiq == "imprime")
					// rotina para impressao das etiquetas de volumes conforme movimentacao do veiculo
					U_TWMSR013(;
					SZZ->ZZ_CLIENTE,;
					SZZ->ZZ_LOJA   ,;
					1              ,;
					SZZ->ZZ_CESV   ,;
					"  "           ,;
					"ZZ"           ,;
					Nil            ,;
					1               )

				EndIf
			EndIf
			// se for pra excluir, chama a rotina responsável
		ElseIf (_cOperEtiq == "exclui")

			// questiona o usuario
			If (U_FtYesNoMsg("Deseja excluir as etiquetas da OS "+Z05->Z05_NUMOS+"?"))
				MsgRun("Analisando dados...", "Aguarde", {|| _lRet := U_WMSA009J(Z05->Z05_NUMOS, SZZ->ZZ_CESV, Left(_cTipoEtiq,2)) })
			EndIf
		EndIf
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni,.t.)
	RestArea(_aArea)

Return(.t.)

// ** funcao para gerar o mapa de separacao de mercadoria / apanhe
Static Function sfMapaApanhe(mvMapaApanhe, mvCtrVolume)
	// variavel de retorno
	local _lMapaComple := .t.

	// data e hora de emissao
	local _dDtEmissao := Date()
	local _cHrEmissao := Time()

	// endereco de servico
	local _cEndServ
	// endereco de origem
	local _cEndOrig
	// endereco de transicao
	local _cEndTran
	// endereco de destino
	local _cEndDest
	//Variavel temporaria For
	Local _nRetEnder
	// tipo de endereço de origem
	local _cTpOri := ""

	// codigo do status
	local _cTpStatus := ""

	// gera plano de armazenagem
	For _nRetEnder := 1 to Len(mvMapaApanhe)

		// estrutura _aMapaApanhe
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

		// define endereco de servico
		_cEndServ := mvMapaApanhe[_nRetEnder][3]
		// define endereco de origem
		_cEndOrig := mvMapaApanhe[_nRetEnder][3]
		// define endereco de destino
		_cEndDest := mvMapaApanhe[_nRetEnder][5]

		// valida tipo de endereço de origem
		_cTpOri := sfRetTpEnd( _cEndOrig, mvMapaApanhe[_nRetEnder][2] )

		// se a origem não for bloco, preenche a transação
		If ( _cTpOri != "4" )
			// define a rua de transação
			_cEndTran := SubStr(mvMapaApanhe[_nRetEnder][3],1,2)
		EndIf

		// somente para mapa de onda de separacao, sem endereco de retirada
		If (Empty(_cEndOrig + _cEndDest))
			_cTpStatus := "O"
		Else
			_cTpStatus := "P"
		EndIf

		// inclui o item da OS
		dbSelectArea("Z08")
		RecLock("Z08",.t.)
		Z08->Z08_FILIAL := xFilial("Z08")
		Z08->Z08_NUMOS  := Z06->Z06_NUMOS
		Z08->Z08_SEQOS	:= Z06->Z06_SEQOS
		Z08->Z08_LOCAL  := mvMapaApanhe[_nRetEnder][2]
		Z08->Z08_SERVIC := Z06->Z06_SERVIC
		Z08->Z08_TAREFA := Z06->Z06_TAREFA
		Z08->Z08_ENDSRV := _cEndServ
		Z08->Z08_ENDORI := _cEndOrig
		Z08->Z08_ENDTRA := _cEndTran
		Z08->Z08_ENDDES := _cEndDest
		Z08->Z08_DTEMIS := _dDtEmissao
		Z08->Z08_HREMIS := _cHrEmissao
		Z08->Z08_STATUS := _cTpStatus // P-Planejado / R-Realizado / M-Movimento / E-Erro / O-Onda Separacao
		Z08->Z08_PRODUT := mvMapaApanhe[_nRetEnder][ 1]
		Z08->Z08_QUANT  := mvMapaApanhe[_nRetEnder][ 4]
		Z08->Z08_PRIOR  := "99"
		Z08->Z08_PALLET	:= mvMapaApanhe[_nRetEnder][ 6]
		Z08->Z08_FRAPLT := mvMapaApanhe[_nRetEnder][ 7]
		Z08->Z08_SERIE  := mvMapaApanhe[_nRetEnder][ 8]
		Z08->Z08_DOC    := mvMapaApanhe[_nRetEnder][ 9]
		Z08->Z08_ITEMNF := mvMapaApanhe[_nRetEnder][10]
		Z08->Z08_SEQUEN := mvMapaApanhe[_nRetEnder][11]
		Z08->Z08_TPOPER := Z05->Z05_TPOPER
		Z08->Z08_NUMSEQ := mvMapaApanhe[_nRetEnder][12]
		Z08->Z08_LOCDES := mvMapaApanhe[_nRetEnder][ 2] // está fixo baseado no local de origem
		Z08->Z08_LOTCTL := mvMapaApanhe[_nRetEnder][14]
		Z08->Z08_QTSEGU := IIf((mvMapaApanhe[_nRetEnder][16] != 0), mvMapaApanhe[_nRetEnder][16], ConvUM(mvMapaApanhe[_nRetEnder][ 1], mvMapaApanhe[_nRetEnder][ 4], mvMapaApanhe[_nRetEnder][ 4], 2))
		Z08->Z08_TPESTO := mvMapaApanhe[_nRetEnder][15]

		// 16-Quantidade Seg Unid
		Z08->(MsUnLock())

	Next _nRetEnder

Return(_lMapaComple)

// ** funcao para definir a doca de destino do pedido
Static Function sfDefDocaDest(mvCarga, mvOndaSep)
	// variavel de retorno
	local _lRet := .f.

	// variaveis do browse
	local _aHeadDoca := {}
	local _aColsDoca := {}
	local _cQuery := ""

	// monta a query
	_cQuery := " SELECT BE_LOCAL, BE_LOCALIZ, "
	// controle de recno e item deletado
	_cQuery += " SBE.R_E_C_N_O_ SBERECNO, '.F.' IT_DEL "
	// cad. de enderecos
	_cQuery += " FROM " + RetSqlTab("SBE") + " (nolock) "
	// cad. estrutura fisica - tipo box/doca
	_cQuery += " INNER JOIN " + RetSqlTab("DC8") + "  (nolock) ON " + RetSqlCond("DC8") + " AND DC8_TPESTR = '5' AND DC8_CODEST = BE_ESTFIS "
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("SBE")
	// status do endereco
	_cQuery += " AND BE_STATUS NOT IN ('3','I') "
	// ordem dos dados
	_cQuery += " ORDER BY BE_LOCAL, BE_LOCALIZ"

	// adiciona o conteudo da query para um array
	_aColsDoca := U_SqlToVet(_cQuery)

	memowrit("c:\query\twmsa009_sfDefDoca.txt",_cQuery)

	// caso nao tenha enderecos disponiveis
	If (Len(_aColsDoca) == 0)
		MsgStop("Não há docas disponíveis.")
		Return(.f.)
	EndIf

	// define todos os campos do header
	aAdd(_aHeadDoca,{"Armazém"  ,"BE_LOCAL"   ,""                          ,TamSx3("BE_LOCAL")[1]  ,0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDoca,{"Endereço" ,"BE_LOCALIZ" ,PesqPict("SBE","BE_LOCALIZ"),TamSx3("BE_LOCALIZ")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadDoca,{"Recno"    ,"SBERECNO"   ,""                          ,10                     ,0,Nil,Nil,"N",Nil,"R",,,".F." })

	// definicao da tela
	_oDlgDefDoca := MSDialog():New(000,000,300,250,"Define Doca de Operação",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlCabec1 := TPanel():New(000,000,nil,_oDlgDefDoca,,.F.,.F.,,,000,030,.T.,.F. )
	_oPnlCabec1:Align:= CONTROL_ALIGN_TOP

	// botoes da operacao
	_oBtnConfDoca := TButton():New(010,010,"Confirmar",_oPnlCabec1,{|| sfConfDefDoca(mvCarga, mvOndaSep) , _lRet := .t.},050,012,,,,.T.,,"",,,,.F. )
	_oBtnCancDoca := TButton():New(010,065,"Fechar"   ,_oPnlCabec1,{|| _oDlgDefDoca:End() },050,012,,,,.T.,,"",,,,.F. )

	// monta o browse
	_oBrwDefDoca := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsDoca),'AllwaysTrue()','','AllwaysTrue()',_oDlgDefDoca,_aHeadDoca,_aColsDoca)
	_oBrwDefDoca:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa o dialogo
	_oDlgDefDoca:Activate(,,,.T.,,, )

Return(_lRet)

// ** funcao para confirmar a definicao da doca
Static Function sfConfDefDoca(mvCarga, mvOndaSep)
	// retorna o RECNO
	local _nRecnoSBE := _oBrwDefDoca:aCols[_oBrwDefDoca:nAt][Len(_oBrwDefDoca:aHeader)]
	local _cSeekSC6

	// posiciono no registro da agenda
	dbSelectArea("SBE")
	SBE->(dbGoTo(_nRecnoSBE))

	// itens do pedido de venda
	dbSelectArea("SC6")
	SC6->(dbSetOrder(1)) //1-C6_FILIAL, C6_NUM, C6_ITEM, C6_PRODUTO
	SC6->(dbSeek( _cSeekSC6 := xFilial("SC6") + mvCarga ))

	// atualiza todos os itens do pedido
	While SC6->(!Eof()) .And. (SC6->(C6_FILIAL+C6_NUM) == _cSeekSC6)

		// atualiza as informacoes da tabela
		dbSelectArea("SC6")
		RecLock("SC6")
		SC6->C6_LOCALIZ := SBE->BE_LOCALIZ
		SC6->(MsUnLock())

		// proximo item
		SC6->(dbSkip())
	EndDo

	// fecha tela
	_oDlgDefDoca:End()

	// refresh dos dados
	sfRfrDados(.f.)

Return(.t.)

// ** funcao para inclusao dos recuros necessarios para operacao
Static Function sfAddRecurso(mvCodSrv, mvCodTrf, mvSeqOS, mvCodCli, mvLojCli, mvTpOper, mvAddPlanej, mvAddRecAut)
	// variavel de retorno
	local _lRet := .t.
	// recursos humanos funcoes
	local _aRecHum := {}
	// recursos fisicos/equiapamentos
	local _aEquipamen := {}
	// recursos humanos anetriores
	local _aRecHumAnt := {}

	// variaveis temporarias
	local _nX, _nY
	local _cTmpCodOpe

	// query
	local _cQuery

	// verifica se deve atribuir os recursos planejados
	If (mvAddPlanej)

		// validação dos tipo de serviços gerados
		If ( Empty(mvCodSrv) )
			MsgStop("Código do Serviço não informado. Rotina TWMSA009->sfAddRecurso")
			Return (.F.)
		Else
			Do Case
				// 001-EXPEDIÇÃO
				Case mvCodSrv == "001"
				_aRecHum := { {"001","WMS03"}, {"001","WMS04"}, {"002","WMS02"}, {"003","WMS02"} }
				_aEquipamen := { {"001","PE1"}, {"001","TE1"}, {"001","EE1"}, {"001","EG1"} }

				// 002-CARREGAMENTO
				Case mvCodSrv == "002"
				_aRecHum := { {"001", "WMS02"} }

				// 003-RECEBIMENTO | T03-CANCELAMENTO DE PEDIDOS | T04-DEVOLUÇÃO | 015 - PRE CONFERENCIA
				Case ( (mvCodSrv == "003") .OR. (mvCodSrv == "T03") .OR. (mvCodSrv == "T04") .OR. (mvCodSrv == "015"))
				_aRecHum := { {"001","WMS02"}, {"002","WMS03"}, {"002","WMS04"} }
				_aEquipamen := { {"002","PE1"}, {"002","TE1"}, {"002","EE1"}, {"002","EG1"} }

				// 014-TRANSFERÊNCIA
				Case mvCodSrv == "014"
				_aRecHum := { {"001","WMS03"}, {"001","WMS04"} }
				_aEquipamen := { {"001","PE1"}, {"001","TE1"}, {"001","EE1"}, {"001","EG1"}, {"001","ER1"} }

				// T02-INVENTÁRIO
				Case mvCodSrv == "T02"
				_aRecHum := { {"001","WMS01"},{"001","WMS02"} }

				// T05-RETRABALHO
				Case mvCodSrv == "T05"
				_aRecHum := { {"001","WMS03"}, {"001","WMS04"}, {"002","WMS02"},  {"003","WMS03"}, {"003","WMS04"} }
				_aEquipamen := { {"001","PE1"}, {"001","TE1"}, {"001","EE1"}, {"001","EG1"}, {"003","PE1"}, {"003","TE1"}, {"003","EE1"}, {"003","EG1"} }

				// T06-SELEÇÃO DE PALLETS
				Case mvCodSrv == "T06"
				_aRecHum := { {"001","WMS01"},{"001","WMS02"} }

				// caso não encontre, avisa o usuário
				Otherwise
				MsgStop("Código do Serviço não encontrado. Rotina TWMSA009->sfAddRecurso")
				Return (.F.)
			EndCase
		EndIf

		// gera todos os recursos humanos que serão utilizados por aquele serviço
		For _nX := 1 to Len(_aRecHum)
			dbSelectArea("Z18")
			RecLock("Z18",.t.)
			Z18->Z18_FILIAL := xFilial("Z18")
			Z18->Z18_NUMOS  := Z05->Z05_NUMOS
			Z18->Z18_SEQOS  := _aRecHum[_nX][1]
			Z18->Z18_FUNCAO := _aRecHum[_nX][2]
			Z18->Z18_CATEG  := "O" // O=Operadores
			Z18->Z18_STATUS := "P" // P=Planejado / R=Realizado / B=Bloqueado
			Z18->(MsUnLock())
		Next _nX

		// gera todos recursos fisicos/equipamentos que serão utilizados por aquele serviço
		For _nX := 1 to Len(_aEquipamen)
			dbSelectArea("Z18")
			RecLock("Z18",.t.)
			Z18->Z18_FILIAL	:= xFilial("Z18")
			Z18->Z18_NUMOS  := Z05->Z05_NUMOS
			Z18->Z18_SEQOS  := _aEquipamen[_nX][1]
			Z18->Z18_TPEQUI := _aEquipamen[_nX][2]
			Z18->Z18_QUANT  := 1
			Z18->Z18_CATEG  := "E" // E=Equipamentos
			Z18->Z18_STATUS := "P" // P=Planejado / R=Realizado / B=Bloqueado
			Z18->(MsUnLock())
		Next _nX
	EndIf

	// verifica se deve atribuir automaticamente os usuarios atribuidos anteriormente (30 dias)
	If (mvAddRecAut)

		// prepara query
		_cQuery := " SELECT Z18_OPERAD                         COD_OPER, "
		_cQuery += "        Z06_SERVIC                         COD_SERVICO, "
		_cQuery += "        Z06_TAREFA                         COD_TAREFA, "
		_cQuery += "        Count(Z18_NUMOS)                   QTD_OS, "
		_cQuery += "        Sum(QTD_CONF + QTD_MOV + QTD_INVE) QTD_REG "
		// sub-query
		_cQuery += " FROM   (SELECT Z18_OPERAD, "
		_cQuery += "                Z06_SERVIC, "
		_cQuery += "                Z06_TAREFA, "
		_cQuery += "                Z18_NUMOS, "
		// conferencias (entrada e saida)
		_cQuery += "                (SELECT Count(*) "
		_cQuery += "                 FROM   " + RetSqlTab("Z07") + " (nolock) "
		_cQuery += "                 WHERE  " + RetSqlCond("Z07")
		_cQuery += "                        AND Z07_NUMOS = Z05_NUMOS "
		_cQuery += "                        AND Z07_USUARI = Z18_OPERAD) QTD_CONF, "
		// movimentacao de mercadoria
		_cQuery += "                (SELECT Count(*) "
		_cQuery += "                 FROM   " + RetSqlTab("Z17") + " (nolock) "
		_cQuery += "                 WHERE  " + RetSqlCond("Z17")
		_cQuery += "                        AND Z17_NUMOS = Z05_NUMOS "
		_cQuery += "                        AND Z17_OPERAD = Z18_OPERAD) QTD_MOV, "
		// inventarios
		_cQuery += "                (SELECT Count(*)
		_cQuery += "                 FROM   " + RetSqlTab("Z19") + " (nolock) "
		_cQuery += "                 WHERE  " + RetSqlCond("Z19")
		_cQuery += "                        AND Z19_IDENT = Z05_NUMOS "
		_cQuery += "                        AND Z19_USER = Z18_OPERAD)   QTD_INVE "
		// servicos da ordem de servico
		_cQuery += "         FROM   " + RetSqlTab("Z06")
		// cab. ordem de servico
		_cQuery += "                INNER JOIN " + RetSqlTab("Z05") + " (nolock) "
		_cQuery += "                        ON " + RetSqlCond("Z05")
		_cQuery += "                           AND Z05_NUMOS = Z06_NUMOS "
		_cQuery += "                           AND Z05_CLIENT = '" + mvCodCli + "' "
		_cQuery += "                           AND Z05_LOJA = '" + mvLojCli + "' "
		_cQuery += "                           AND Z05_TPOPER = '" + mvTpOper + "' "
		// recursos ja atribuidos
		_cQuery += "                INNER JOIN " + RetSqlTab("Z18") + " (nolock) "
		_cQuery += "                        ON " + RetSqlCond("Z18")
		_cQuery += "                           AND Z18_NUMOS = Z06_NUMOS "
		_cQuery += "                           AND Z18_SEQOS = Z06_SEQOS "
		_cQuery += "                           AND Z18_STATUS = 'R' "
		// filtro padrao
		_cQuery += "         WHERE  " + RetSqlCond("Z06")
		// ultimos 30 dias
		_cQuery += "                AND Z06_DTEMIS >= CONVERT(VARCHAR(8), Dateadd(DAY, -30, Getdate()), 112) "
		// servico
		_cQuery += "                AND Z06_SERVIC = '" + mvCodSrv + "' "
		// tarefa
		_cQuery += "                AND Z06_TAREFA = '" + mvCodTrf + "') ORDENS_SERVICO "
		// agrupa dados
		_cQuery += " GROUP  BY Z18_OPERAD, "
		_cQuery += "           Z06_SERVIC, "
		_cQuery += "           Z06_TAREFA "
		// apresenta somente as que realizaram movimentacao
		_cQuery += " HAVING Sum(QTD_CONF + QTD_MOV + QTD_INVE) != 0 "
		// ordem
		_cQuery += " ORDER  BY 1 "

		// atualiza dados no vetor
		_aRecHumAnt := U_SqlToVet(_cQuery)

		// varre todos os operadores
		For _nY := 1 to Len(_aRecHumAnt)

			// codigo do recurso humano
			_cTmpCodOpe := _aRecHumAnt[_nY][1]

			// verifica se o operador esta cadastrado e não é monitor
			dbSelectArea("DCD")
			DCD->(dbSetOrder(1)) //1-DCD_FILIAL, DCD_CODFUN
			If ( ! DCD->(dbSeek( xFilial("DCD") + _cTmpCodOpe )))
				// loop do FOR
				Loop
			EndIf

			// verifica status / bloqueado
			If (DCD->DCD_STATUS != "1") .Or. (DCD->DCD_MSBLQL == "1")
				// loop do FOR
				Loop
			EndIf

			// caso não tenha usuário com esse registro, insere uma nova linha
			dbSelectArea("Z18")
			Z18->(dbSetOrder(1)) // 1 - Z18_FILIAL, Z18_NUMOS, Z18_SEQOS, Z18_OPERAD
			If ! Z18->(dbSeek( _cSeekZ18 := xFilial("Z18") + Z05->Z05_NUMOS + mvSeqOS + _cTmpCodOpe ))

				// insere uma nova linha
				dbSelectArea("Z18")
				RecLock("Z18", .T.)
				Z18->Z18_FILIAL	:= xFilial("Z18")
				Z18->Z18_NUMOS  := Z05->Z05_NUMOS
				Z18->Z18_SEQOS  := mvSeqOS
				Z18->Z18_STATUS := "R" // P=Planejado / R=Realizado / B=Bloqueado
				Z18->Z18_USUARI := __cUserId
				Z18->Z18_OPERAD := _cTmpCodOpe
				Z18->Z18_CATEG  := DCD->DCD_ZCATEG
				Z18->(MsUnLock())

				// insere o log
				U_FtGeraLog(cFilAnt, "Z18", xFilial("Z18") + Z05->Z05_NUMOS + mvSeqOS, "Definido Operador " + _cCodOper, "WMS", "")

			EndIf

		Next _nY

	EndIf

Return(_lRet)

// ** funcao para vincular todos os produtos da nota
Static Function sfVincTodos(mvObjBrowse)
	// header do Browse
	local _aHeadBrw := aClone(mvObjBrowse:aHeader)
	// posicao dos campos
	local _nPosSaldo  := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="D1_QUANT"})   // saldo disponivel
	local _nPosQuant  := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="IT_SALDO"})   // quantidade
	local _nPosCodKit := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="Z29_CODKIT"}) // cod kit
	// variaveis temporarias
	local _nItem

	// varre todos os itens
	For _nItem := 1 to Len(mvObjBrowse:aCols)
		// verifica se compos kit
		If (Empty(mvObjBrowse:aCols[_nItem][_nPosCodKit]))
			// atualiza a quantidade
			mvObjBrowse:aCols[_nItem][_nPosQuant] := mvObjBrowse:aCols[_nItem][_nPosSaldo]
		EndIf
	Next _nItem

	// refresh
	mvObjBrowse:Refresh()

Return(.t.)

// ** funcao para atualizar dados da tela de planejamento
Static Function sfDadosPla(mvObjBrwPlanej,mvFirst)
	// query
	local _cQryPla := ""
	// area inicial do TRB
	local _aAreaTRB := If(mvFirst,Nil,(_cAlTrPlanej)->(GetArea()))

	// limpa o conteudo do TRB
	dbSelectArea(_cAlTrPlanej)
	__DbZap()

	// busca as movimentacoes
	_cQryPla := "SELECT DISTINCT "
	_cQryPla += "  ZZ_OPERACA, "
	_cQryPla += "  CASE WHEN ZZ_OPERACA = '01' THEN 'RECEBIMENTO' ELSE '' END IT_OPERACA, "
	_cQryPla += "  ZZ_CESV, "
	_cQryPla += "  ZZ_DTENT, "
	_cQryPla += "  ZZ_PROCES IT_PROCES, "
	_cQryPla += "  ZZ_ITPROC IT_ITPROC, "
	_cQryPla += "  ZZ_CARGA, "
	_cQryPla += "  ZZ_CLIENTE, "
	_cQryPla += "  ZZ_LOJA, "
	_cQryPla += "  A1_NOME, "
	_cQryPla += "  ZZ_DOCA, "
	_cQryPla += "  ZZ_LOCAL, "
	_cQryPla += "  ZZ_STATUS, "
	_cQryPla += "  ZZ_PLACA1, "
	_cQryPla += "  ZZ_CNTR01, "
	_cQryPla += "  '' DAK_COD, "
	_cQryPla += "  '' Z57_CODIGO "
	// registro de entrada do caminhao
	_cQryPla += " FROM "+RetSqlTab("SZZ")+" (nolock) "
	// cad. do cliente
	//	_cQryPla += " INNER JOIN "+RetSqlTab("SA1")+" ON "+RetSqlCond("SA1")+" AND A1_COD = ZZ_CLIENTE AND A1_LOJA = ZZ_LOJA AND ZZ_OPWMS != 'N'"
	_cQryPla += " INNER JOIN "+RetSqlTab("SA1")+" (nolock)  ON "+RetSqlCond("SA1")+" AND A1_COD = ZZ_CLIENTE AND A1_LOJA = ZZ_LOJA"
	// filtro padrao
	_cQryPla += " WHERE " + RetSqlCond("SZZ")
	// somente caminhao liberado para entrada
	_cQryPla += " AND ZZ_DTENT <> ' ' "
	// status
	_cQryPla += " AND ZZ_STATUS NOT IN ('01','08','09','10') "
	// cliente
	_cQryPla += " AND ZZ_CLIENTE BETWEEN '" + mvCliDe + "' AND '" + mvCliAte + "' "

	// cargas montadas
	_cQryPla += "UNION ALL "

	_cQryPla += "SELECT "
	_cQryPla += "  DISTINCT "
	_cQryPla += "  ISNULL(ZZ_OPERACA,'02') ZZ_OPERACA, "
	_cQryPla += "  'EXPEDICAO' IT_OPERACA, "
	_cQryPla += "  ISNULL(ZZ_CESV,'') ZZ_CESV, "
	_cQryPla += "  ISNULL(ZZ_DTENT,'') ZZ_DTENT, "
	_cQryPla += "  '' IT_PROCES, "
	_cQryPla += "  '' IT_ITPROC, "
	_cQryPla += "  ISNULL(ZZ_CARGA,DAK_COD) ZZ_CARGA, "
	_cQryPla += "  C9_CLIENTE ZZ_CLIENTE, "
	_cQryPla += "  C9_LOJA ZZ_LOJA, "
	_cQryPla += "  A1_NOME, "
	_cQryPla += "  ISNULL(ZZ_DOCA,'') ZZ_DOCA, "
	_cQryPla += "  ISNULL(ZZ_LOCAL,'') ZZ_LOCAL, "
	_cQryPla += "  ISNULL(ZZ_STATUS,'') ZZ_STATUS, "
	_cQryPla += "  DAK_CAMINH ZZ_PLACA1, "
	_cQryPla += "  '' ZZ_CNTR01, "
	_cQryPla += "  DAK_COD, "
	_cQryPla += "  '' Z57_CODIGO "

	// cadastro de cargas
	_cQryPla += " FROM " + RetSqlTab("DAK") + " (nolock) "

	// itens liberados dos pedidos e relacionados na carga
	_cQryPla += " INNER JOIN " + RetSqlTab("SC9") + " (nolock)  ON " + RetSqlCond("SC9") + " AND C9_CARGA = DAK_COD "
	_cQryPla += " AND C9_CLIENTE BETWEEN '" + mvCliDe + "' AND '" + mvCliAte + "' "
	// cad. cliente
	_cQryPla += " INNER JOIN "+RetSqlTab("SA1")+" (nolock)  ON "+RetSqlCond("SA1")+" AND A1_COD = C9_CLIENTE AND A1_LOJA = C9_LOJA "
	// registro de entrada do caminhao
	//	_cQryPla += " LEFT  JOIN "+RetSqlTab("SZZ")+" ON "+RetSqlCond("SZZ")+" AND ZZ_CARGA = C9_CARGA AND ZZ_OPWMS != 'N' "
	_cQryPla += " LEFT  JOIN "+RetSqlTab("SZZ")+" (nolock)  ON "+RetSqlCond("SZZ")+" AND ZZ_CARGA = C9_CARGA "

	// tabela de vinculo de varias cargas no mesmo CESV
	_cQryPla += "LEFT  JOIN "+RetSqlTab("Z43")+" (nolock)  ON "+RetSqlCond("Z43")+" AND Z43_CARGA = DAK_COD "

	// filtro padrao da carga
	_cQryPla += "WHERE "+RetSqlCond("DAK")
	// somente carga pendente/disponivel
	_cQryPla += "AND (ZZ_STATUS IS NULL OR ZZ_STATUS <> '10') "
	_cQryPla += "AND (Z43_STATUS = 'C' OR Z43_CESV IS NULL ) "

	// ordem dos dados
	_cQryPla += "ORDER BY ZZ_CESV, DAK_COD"

	memowrit("c:\query\twmsa009_sfPlanejamento.txt", _cQryPla)

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQryPla,_aStPlanej,(_cAlTrPlanej))

	// abre o arquivo de trabalho
	dbSelectArea(_cAlTrPlanej)
	If (mvFirst)
		dbSelectArea(_cAlTrPlanej)
		(_cAlTrPlanej)->(dbGoTop())
	ElseIf (!mvFirst)
		// area inicial do TRB
		RestArea(_aAreaTRB)
	EndIf

	// atualizacao do browse
	If (mvObjBrwPlanej <> nil)
		mvObjBrwPlanej:oBrowse:Refresh()
	EndIf

Return

// -- Rotina para geração de OS de Transferência

// grupo de perguntas para OS
Static Function sfGeraParTrf()

	// grupo de perguntas
	Local _cPergOS := PadR("TWMSA00901",10)
	// lista de pergunta (parametros)
	Local _vPergOS := {}

	// grupo de perguntas
	aAdd(_vPergOS,{"Cliente:"                ,"C",TamSx3("A1_COD")[1] ,0,"G",,"SA1", {{"X1_VALID","U_FtStrZero()"}} })  // mv_par01
	aAdd(_vPergOS,{"Loja:"                   ,"C",TamSx3("A1_LOJA")[1],0,"G",,""   , {{"X1_VALID","U_FtStrZero()"}} }) // mv_par02
	aAdd(_vPergOS,{"Tipo de Movto:"          ,"N",1,0,"C",{"Movto Entre End.","Devol de Mercadoria","Movto Livre"},""}) // mv_par03
	aAdd(_vPergOS,{"Armazém Origem:"         ,"C",TamSx3("BE_LOCAL")[1],0,"G",,""}) // mv_par04
	aAdd(_vPergOS,{"Rua Origem De:"          ,"C",2,0,"G",,""}) // mv_par05
	aAdd(_vPergOS,{"Rua Origem Até:"         ,"C",2,0,"G",,""}) // mv_par06
	aAdd(_vPergOS,{"Prédio Origem De:"       ,"C",2,0,"G",,""}) // mv_par07
	aAdd(_vPergOS,{"Prédio Origem Até:"      ,"C",2,0,"G",,""}) // mv_par08
	aAdd(_vPergOS,{"Lado Origem:"            ,"N",1,0,"C",{"Ambos","A","B"},""}) // mv_par09
	aAdd(_vPergOS,{"Nível Origem De:"        ,"C",2,0,"G",,""}) // mv_par10
	aAdd(_vPergOS,{"Nível Origem Até:"       ,"C",2,0,"G",,""}) // mv_par11
	aAdd(_vPergOS,{"Endereço Origem:"        ,"C",TamSx3("BE_LOCALIZ")[1],0,"G",,"SBE"}) // mv_par12
	aAdd(_vPergOS,{"Carga (devolução):"      ,"C",TamSx3("Z05_CARGA")[1],0,"G",,""}) // mv_par13
	aAdd(_vPergOS,{"Armazém Destino:"        ,"C",TamSx3("BE_LOCAL")[1],0,"G",,""}) // mv_par14
	aAdd(_vPergOS,{"Rua Destino De:"         ,"C",2,0,"G",,""}) // mv_par15
	aAdd(_vPergOS,{"Rua Destino Até:"        ,"C",2,0,"G",,""}) // mv_par16
	aAdd(_vPergOS,{"Prédio Destino De:"      ,"C",2,0,"G",,""}) // mv_par17
	aAdd(_vPergOS,{"Prédio Destino Até:"     ,"C",2,0,"G",,""}) // mv_par18
	aAdd(_vPergOS,{"Lado Destino:"           ,"N",1,0,"C",{"Ambos","A","B"},""}) // mv_par19
	aAdd(_vPergOS,{"Nível Destino De:"       ,"C",2,0,"G",,""}) // mv_par20
	aAdd(_vPergOS,{"Nível Destino Até:"      ,"C",2,0,"G",,""}) // mv_par21
	aAdd(_vPergOS,{"Endereço Destino:"       ,"C",TamSx3("BE_LOCALIZ")[1],0,"G",,"SBE"}) // mv_par22

	// cria grupo de perguntas
	U_FtCriaSX1( _cPergOS,_vPergOS)

	// cria os parametros
	If ! Pergunte(_cPergOS,.T.)
		Return ()
	EndIf

	// caso escolha tipo "devolução de mercadoria"
	// desabilitado em 29/11/18 por Luiz Poleza - não faz sentido e deve ser utilizada rotina de cancelamento de pedido
	// código mantido por compatibilidade de legado neste momento
	// TODO -- remover este tipo de transferência caso realmente não seja necessário ou nenhum usuário reclame
	If (mv_par03 == 2)
		Help( Nil, Nil, 'TWMSA009.F04.002', Nil, "Tipo de transferência DEVOLUÇÃO DE MERCADORIA está desabilitada.", 1, 0, Nil, Nil, Nil, Nil, Nil, {"Utilize a rotina de cancelamento de pedidos."})
		Return ( .F. )
	EndIf

	// validação para o armazém de origem
	If ( Empty(mv_par04) )
		MsgStop("O armazém de origem precisa ser preencido!")
		Return
	EndIf

	Processa({ || sfGeraOsTrf(mv_par01, mv_par02, mv_par03, mv_par04, mv_par05, mv_par06, mv_par07, mv_par08, mv_par09, mv_par10, mv_par11, mv_par12, mv_par13, mv_par14, mv_par15, mv_par16, mv_par17, mv_par18, mv_par19, mv_par20, mv_par21, mv_par22) },"Gerando informações...",,.T.)

Return()

// browse com as informações informadas e geração da OS
Static Function sfGeraOsTrf(mvCli, mvLj, mvTp, mvArm, mvRuaOriDe, mvRuaOriAte, mvPrdOriDe, mvPrdOriAte, mvLdOri, mvNvlOrDe, mvNvlOrAte, mvEndOri, mvCarga, mvArmDes, mvRuaDesDe, mvRuaDesAte, mvPrdDesDe, mvPrdDesAte, mvLdDes, mvNvlDesD, mvNvlDesAte, mvEndDes)

	Local _cQryOri      := "" 		 	// query de Origem (captação dos dados)
	Local _cQryDes      := "" 		 	// query de Destino (para onde os dados serão transferidos)
	Local _nX           := 0  		 	// variavel de controle do FOR
	Local _aEstrTrb     := {} 		 	// estrutura do arquivo de trabalho
	Local _aHeadBrw     := {} 		 	// cabeçalho do arquivo de trabalho
	Local _cArqOsTrf				 	// aux estrutura do TRB
	Local _aBrowse      := {}        	// array do browse
	Local _oBrowse					 	// objeto do browse
	Local _aSizeDlg     := MsAdvSize()  // tamanho da tela
	Local _cEndDes   	:= ""			// endereço de destino
	Local _aTotEndDis  	:= {}			// array com todos os endereços de destino
	local _cCESVZ04		:= ""			// informacao do CESV para consulta da quantidade por pallet
	local _nQtdPlt		:= 0			// quantidade total por pallet
	local _cPallet      := ""			// controle de endereço por pallet
	local _nEndPlan     := 0
	local _cEndPlan     := ""
	// quant palete cheio
	local _nQtdPltChe := 0
	// quant palete fracionado
	local _nQtdPltFra := 0
	// variavel de controle de registros
	local _nAuxQtd := 0
	local _cAuxEnd := ""

	// guarda as estruturas fisicas onde pode armazenar os produtos da transferencia
	local _cEstFis := ""

	private _cAlTrbMov := GetNextAlias()
	private _cMarca    := GetMark()	// variavel que preenche o mark do browse

	// valida codigo do cliente
	If (Empty(mvCli)).or.(Empty(mvLj))
		// mensagem de alerta
		MsgAlert("É obrigatório informar o cliente para esta operação!")
		// retorno
		Return(.f.)
	EndIf

	// quando for movimentacao livre, solcita confirmacao
	If (mvTp == 3)

		// valida se cliente/loja está configurado para permitir OS do tipo transferência livre
		IF !(U_FTVldSrv(mvCli, mvLj, "014", "T08"))
			MsgAlert("Cliente " + mvCli + "/" + mvLj + " não configurado para utilizar transferência livre!")
			Return (.F.)
		EndIf

		// validação para o usuário
		If ( ! MsgYesNo("Deseja Gerar OS de transferência com movimentação livre ?"))
			Return (.F.)
		EndIf

		// gera ordem de servico
		sfGeraTrf(mvCli, mvLj, mvArm, Nil, .t.)

		// retorno
		Return(.t.)

	EndIf

	// monta o arquivo de trabalho
	aAdd(_aEstrTrb,{"IT_OK"     ,"C", 2,0})
	aAdd(_aEstrTrb,{"ENDORI"    ,"C", TamSX3("BE_LOCALIZ")[1], 0                    })
	aAdd(_aEstrTrb,{"ENDTRA"    ,"C", TamSX3("BE_LOCAL")[1]  , 0                    })
	aAdd(_aEstrTrb,{"ENDDES"    ,"C", TamSX3("BE_LOCALIZ")[1], 0                    })
	aAdd(_aEstrTrb,{"MUDALADO"  ,"C", 1                      , 0                    })
	aAdd(_aEstrTrb,{"DISTANCIA" ,"N", 10                     , 2                    })
	aAdd(_aEstrTrb,{"PALLET"    ,"C", TamSX3("Z11_CODETI")[1], 0                    })
	aAdd(_aEstrTrb,{"ETQ_PROD"  ,"C", TamSX3("Z11_CODETI")[1], 0                    })
	aAdd(_aEstrTrb,{"CODPRO"    ,"C", TamSX3("BF_PRODUTO")[1], 0                    })
	aAdd(_aEstrTrb,{"QUANT"     ,"N", TamSX3("Z08_QUANT")[1] ,TamSX3("Z08_QUANT")[2]})
	aAdd(_aEstrTrb,{"ARM"       ,"C", TamSX3("BF_LOCAL")[1]  , 0                    })
	aAdd(_aEstrTrb,{"ARMDES"    ,"C", TamSX3("BF_LOCAL")[1]  , 0                    })
	aAdd(_aEstrTrb,{"NUMSEQ"    ,"C", TamSX3("D1_NUMSEQ")[1] , 0                    })

	// query que trará as opções para o supervisor/gerador da OS
	/*********************** Query Origem ****************************/

	_lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.F.,.F.,Nil, mvCli, mvLj, Nil, Nil)

	_cEstFis := StrTran( AllTrim(U_FtWmsParam("WMS_AREA_ARMAZENAGEM_POR_CLIENTE", "C", "", .F., Nil, mvCli, mvLj, Nil, Nil)) , "/", "','")

	// caso o tipo solicitado seja devolução de mercadoria
	If (mvTp == 2)
		_cQryOri := " SELECT '"+_cMarca+"' IT_OK, "
		_cQryOri += " ' ' MUDALADO, "
		_cQryOri += " '          ' DISTANCIA, "
		_cQryOri += " ' ' ENDDES, "
		_cQryOri += " '"+mvArmDes+"' ARMDES, "
		_cQryOri += " Z08_PALLET PALLET, "
		_cQryOri += " Z08_PRODUT CODPRO, "
		_cQryOri += " Z08_QUANT QUANT, "
		_cQryOri += " Z08_ENDDES ENDORI, "
		_cQryOri += " Z08_LOCAL ARM, "
		_cQryOri += " Z08_NUMSEQ NUMSEQ "
		_cQryOri += " FROM "+RetSqlName("Z08")+" Z08 (nolock)  "
		_cQryOri += " INNER JOIN "+RetSqlName("Z05")+" Z05  (nolock) ON "+RetSqlCond("Z05")
		_cQryOri += " AND Z05_NUMOS = Z08_NUMOS "
		_cQryOri += " WHERE "+RetSqlCond("Z08")
		_cQryOri += " AND Z08_TPOPER = 'S' "
		_cQryOri += " AND Z08_LOCAL = '"+mvArm+"' "
		_cQryOri += " AND Z05_CARGA = '"+mvCarga+"' "
		_cQryOri += " ORDER BY Z08_PALLET "
	Else
		// se o endereço de origem for DOCA/BLOCADO/RETRABALHO tem tratamento especial direto pela Z16
		If ( sfVldTpEnd(mvEndOri) )
			_cQryOri := " SELECT '"+_cMarca+"' IT_OK, "
			_cQryOri += "	' ' MUDALADO,"
			_cQryOri += "	'          ' DISTANCIA,"
			_cQryOri += "	' ' ENDDES,"
			_cQryOri += "   '"+mvArmDes+"' ARMDES, "
			_cQryOri += "	Z16_ETQPAL PALLET,"
			If ( ! _lCtrVolume )
				_cQryOri += "	Z16_ETQPRD ETQ_PROD,"
			EndIf
			_cQryOri += "	Z16_CODPRO CODPRO,"
			_cQryOri += "	Z16_SALDO QUANT,"
			_cQryOri += "	Z16_ENDATU ENDORI,"
			_cQryOri += "	Z16_LOCAL ARM, "
			_cQryOri += "	Z16_NUMSEQ NUMSEQ "
			_cQryOri += " FROM "+RetSqlName("Z16")+" Z16 (nolock)  "
			_cQryOri += " WHERE "+RetSqlCond("Z16")
			_cQryOri += " AND Z16_LOCAL = '"+mvArm+"' "
			_cQryOri += " AND Z16_ENDATU = '"+mvEndOri+"' "
			_cQryOri += " AND Z16_TPESTO IN ('', '000001') "
			_cQryOri += " AND Z16_SALDO > 0 "
			// descarta reservas
			_cQryOri += " AND Z16_ENDATU NOT IN (SELECT Z08_ENDDES FROM " + RetSqlTab("Z08") + " (nolock)  WHERE " + RetSqlCond("Z08") + " AND Z08_ENDDES = Z16_ENDATU AND Z08_STATUS != 'R' )  "
			_cQryOri += " AND Z16_ENDATU NOT IN (SELECT Z08_ENDORI FROM " + RetSqlTab("Z08") + " (nolock)  WHERE " + RetSqlCond("Z08") + " AND Z08_ENDORI = Z16_ENDATU AND Z08_STATUS != 'R' )  "
			_cQryOri += " ORDER BY Z16_ETQPAL "
		Else
			// movimentação entre endereços (transferência)
			_cQryOri := " SELECT '"+_CMARCA+"' IT_OK, "
			_cQryOri += " 	' ' MUDALADO, "
			_cQryOri += " 	'          ' DISTANCIA, "
			_cQryOri += " 	' ' ENDDES, "
			_cQryOri += "   '"+mvArmDes+"' ARMDES, "
			_cQryOri += " 	Z16_ETQPAL PALLET, "
			If ( ! _lCtrVolume )
				_cQryOri += "	Z16_ETQPRD ETQ_PROD,"
			EndIf
			_cQryOri += "   Z16_CODPRO CODPRO, "
			_cQryOri += " 	SUM(Z16_SALDO) QUANT, "
			_cQryOri += " 	BE_LOCALIZ ENDORI, "
			_cQryOri += " 	BE_LOCAL ARM, "
			_cQryOri += "	Z16_NUMSEQ NUMSEQ, "
			_cQryOri += " 	BE_FILIAL "
			_cQryOri += "  FROM   "+RetSqlName("SBE")+" SBE (NOLOCK)"
			_cQryOri += "  LEFT JOIN "+RetSqlName("Z16")+" Z16 (NOLOCK) ON Z16_FILIAL = BE_FILIAL "
			_cQryOri += " 	                               AND Z16.D_E_L_E_T_ = '' "
			_cQryOri += " 	                               AND Z16_LOCAL = BE_LOCAL "
			_cQryOri += " 	                               AND Z16_ENDATU = BE_LOCALIZ "
			_cQryOri += " 	                               AND Z16_TPESTO IN ('', '000001') "
			_cQryOri += " 	                               AND Z16_SALDO > 0 "
			_cQryOri += "  LEFT JOIN "+RetSqlName("SBF")+" SBF (NOLOCK) ON BF_FILIAL = BE_FILIAL "
			_cQryOri += "   	                           AND SBF.D_E_L_E_T_ = '' "
			_cQryOri += " 	                               AND BF_LOCAL = BE_LOCAL "
			_cQryOri += " 	                               AND BF_LOCALIZ = BE_LOCALIZ "
			_cQryOri += " 	                               AND BF_PRODUTO = Z16_CODPRO "
			_cQryOri += " 	WHERE  "+RetSqlCond("SBE")
			_cQryOri += " 	  AND BE_STATUS = 2 "
			_cQryOri += "	  AND BF_PRODUTO = Z16_CODPRO " // somente o que for igual na BF
			_cQryOri += "	  AND BF_LOCAL = '"+mvArm+"' "

			// caso o usuário não tenha solicitado um endereço exclusivo
			If (Empty(mvEndOri))
				_cQryOri += " AND SUBSTRING(SBE.BE_LOCALIZ,1,2) BETWEEN '"+mvRuaOriDe+"' AND '"+mvRuaOriAte+"' "    // Rua

				// 1 = TODOS
				If ( ! mvLdOri == 1)
					// definição do lado escolhido
					If (mvLdOri == 2)
						_cQryOri += " AND SUBSTRING(SBE.BE_LOCALIZ,3,1) = 'A' "   // Lado
					Else
						_cQryOri += " AND SUBSTRING(SBE.BE_LOCALIZ,3,1) = 'B' "   // Lado
					EndIf
				EndIf

				// predio de origem
				_cQryOri += " AND SUBSTRING(SBE.BE_LOCALIZ,4,2) BETWEEN '"+mvPrdOriDe+"' AND '"+mvPrdOriAte+"' "

				// nível de origem
				_cQryOri += " AND SUBSTRING(SBE.BE_LOCALIZ,6,2) BETWEEN '"+mvNvlOrDe+"' AND '"+mvNvlOrAte+"' "

			Else
				_cQryOri += " AND SBE.BE_LOCALIZ = '"+mvEndOri+"' "
			EndIf

			// validação dos registros que existem em movimentação na Z08 (para não conflitar)

			// descarca enderecos que estao no plano de enderecamento
			_cQryOri += " AND BE_LOCALIZ NOT IN ("
			_cQryOri += "   SELECT DISTINCT Z08_ENDDES FROM " +RetSqlTab("Z08")+" (nolock) "
			_cQryOri += "   WHERE " + RetSqlCond("Z08") + " AND Z08_STATUS IN ('P','M') AND Z08_LOCAL = BE_LOCAL "
			_cQryOri += " ) "

			// descarca enderecos que estao no plano de expedicao
			_cQryOri += " AND BE_LOCALIZ NOT IN ("
			_cQryOri += "   SELECT DISTINCT Z08_ENDORI FROM " + RetSqlTab("Z08") + " (nolock) "
			_cQryOri += "   WHERE " + RetSqlCond("Z08") + " AND Z08_STATUS IN ('P','M') AND Z08_LOCAL = BE_LOCAL "
			_cQryOri += " ) "

			// validação de cliente X endereço
			_cQryOri += " AND SBE.BE_ZCODCLI = '"+mvCli+"' "

			// agrupo por causa do MAX
			_cQryOri += " GROUP BY Z16_CODPRO, Z16_ETQPAL, BE_LOCALIZ, BE_LOCAL, Z16_ETQPRD, BE_FILIAL, Z16_NUMSEQ "
			// finalizo a query
			_cQryOri += " ORDER BY PALLET

		EndIF

	EndIf

	/*************************** FIM *********************************/
	// gero a query em txt para debug se necessário
	memowrit("C:\query\twmsa009_sfGeraOsTrf.txt",_cQryOri)

	// fecha alias do TRB
	If (Select((_cAlTrbMov))<>0)
		dbSelectArea(_cAlTrbMov)
		dbCloseArea()
	EndIf

	// cria arquivo de trabalho
	_cArqOsTrf := FWTemporaryTable():New( _cAlTrbMov )
	_cArqOsTrf:SetFields( _aEstrTrb )
	_cArqOsTrf:Create()

	// adiciona o conteudo da query para o arquivo de trabalho
	U_SqlToTrb(_cQryOri,_aEstrTrb,(_cAlTrbMov) )

	// abre o arquivo de trabalho
	dbSelectArea(_cAlTrbMov)
	(_cAlTrbMov)->(dbGoTop())

	// pra contar quantos registros e comparar com os endereços de destino
	While ( ! (_cAlTrbMov)->(EoF()))
		// caso o endereço de destino não seja o
		If (_cEndPlan <> (_cAlTrbMov)->ENDORI)
			_nEndPlan++
		EndIf
		// gravo o endereço de destino
		_cEndPlan := (_cAlTrbMov)->ENDORI

		// próximo valor
		(_cAlTrbMov)->(dbSkip())
	EndDo

	// volto para o top
	(_cAlTrbMov)->(dbGoTop())

	// se o arquivo de trabalho estiver vazio
	If ((_cAlTrbMov)->(Eof()))
		Help( Nil, Nil, 'TWMSA009.F04.001', Nil, "Nenhum endereço válido/apto a transferência foi encontrado para os parâmetros informados.", 1, 0, Nil, Nil, Nil, Nil, Nil, {"Informe outros endereços ou verifique se não há bloqueio ou reserva em outras OS."})
		Return (.F.)
	EndIf

	// defino as colunas
	aAdd(_aHeadBrw,{"IT_OK"   ,""," "              , "" })
	aAdd(_aHeadBrw,{"CODPRO"  ,"","Produto"        , "@!" })
	aAdd(_aHeadBrw,{"ARM"     ,"","Armazém Origem" , "" })
	aAdd(_aHeadBrw,{"PALLET"  ,"","Pallet"         , PesqPict("Z11","Z11_CODETI") })
	aAdd(_aHeadBrw,{"ETQ_PROD","","Etq.Produto"    , PesqPict("Z11","Z11_CODETI") })
	aAdd(_aHeadBrw,{"ENDORI"  ,"","Origem"         , "" })
	aAdd(_aHeadBrw,{"ENDTRA"  ,"","Trans"          , "" })
	aAdd(_aHeadBrw,{"ENDDES"  ,"","Destino"        , "" })
	aAdd(_aHeadBrw,{"ARMDES"  ,"","Armazém Destino", ""})

	// Valida para mostrar ou não o Muda Lado e a Distância
	If ( ! sfVldTpEnd( (_cAlTrbMov)->ENDDES) ).Or.( ! sfVldTpEnd( (_cAlTrbMov)->ENDORI) )
		aAdd(_aHeadBrw,{"MUDALADO"   ,"","Muda Lado?"})
		aAdd(_aHeadBrw,{"DISTANCIA"  ,"","Distância"})
	EndIf

	// pego os endereços que vão ser usados
	_cQryDes := "  SELECT BE_LOCALIZ ENDORI "
	_cQryDes += "	 FROM   "+RetSqlName("SBE")+" SBE (NOLOCK)"
	_cQryDes += "	WHERE  "+RetSqlCond("SBE")
	_cQryDes += "	  AND SBE.BE_ESTFIS IN ( '" + _cEstFis + "' )  "
	_cQryDes += "	  AND SBE.BE_LOCAL = '"+mvArmDes+"'  "

	// caso não tenha definido um endereço, leva em conta os demais campos
	If (Empty(mvEndDes))
		// filtro por rua
		_cQryDes += " AND SUBSTRING(SBE.BE_LOCALIZ,1,2) BETWEEN '"+mvRuaDesDe+"' AND '"+mvRuaDesAte+"' "    // Rua

		// somente quando for porta pallet é que entra na condição de status
		_cQryDes += "	  AND SBE.BE_STATUS = '1'  "

		// 1 = TODOS
		If ( ! mvLdDes == 1)
			// definição do lado escolhido
			If (mvLdDes == 2)
				_cQryDes += " AND SUBSTRING(SBE.BE_LOCALIZ,3,1) = 'A' "   // Lado
			Else
				_cQryDes += " AND SUBSTRING(SBE.BE_LOCALIZ,3,1) = 'B' "   // Lado
			EndIf
		EndIf

		// predio de destino
		_cQryDes += " AND SUBSTRING(SBE.BE_LOCALIZ,4,2) BETWEEN '"+mvPrdDesDe+"' AND '"+mvPrdDesAte+"' "

		// nível de destino
		_cQryDes += " AND SUBSTRING(SBE.BE_LOCALIZ,6,2) BETWEEN '"+mvNvlDesD+"' AND '"+mvNvlDesAte+"' "

		// caso tenha escolhido um endereço, busca por ele e pelo ARM
	Else
		_cQryDes += " AND SBE.BE_LOCALIZ = '"+mvEndDes+"' "

		// somente quando for porta pallet é que entra na condição de status
		_cQryDes += " AND SBE.BE_STATUS " + IIF( sfVldTpEnd(mvEndDes), " <> '3' ", " = '1' " ) + "  "
	EndIf

	// validação para não transferir para endereços que estejam com regra cadastrada
	_cQryDes += " AND SBE.BE_CODPRO = '' "

	// validação dos registros que existem em movimentação na Z08 (para não conflitar)
	// somente para porta palete. Se for blocado aceita.
	If (Empty(mvEndDes)).or.( ! sfVldTpEnd(mvEndDes) )
		// descarca enderecos que estao no plano de enderecamento
		_cQryDes += " AND BE_LOCALIZ NOT IN ("
		_cQryDes += "   SELECT DISTINCT Z08_ENDDES FROM " +RetSqlTab("Z08") + " (NOLOCK)"
		_cQryDes += "   WHERE " + RetSqlCond("Z08") + " AND Z08_STATUS != 'R' AND (Z08_LOCDES = BE_LOCAL OR Z08_LOCAL = BE_LOCAL) "
		_cQryDes += " ) "

		// descarca enderecos que estao no plano de expedicao
		_cQryDes += " AND BE_LOCALIZ NOT IN ("
		_cQryDes += "   SELECT DISTINCT Z08_ENDORI FROM " + RetSqlTab("Z08") + " (NOLOCK)"
		_cQryDes += "   WHERE " + RetSqlCond("Z08") + " AND Z08_STATUS != 'R' AND (Z08_LOCDES = BE_LOCAL OR Z08_LOCAL = BE_LOCAL) "
		_cQryDes += " ) "
	EndIf

	// permite transferir somente para endereço do cliente
	_cQryDes += " AND SBE.BE_ZCODCLI = '" + mvCli + "' "

	// agrupamento de dados
	_cQryDes += "	GROUP  BY SBE.BE_LOCALIZ "
	// ordem dos dados
	_cQryDes += "	ORDER  BY SUBSTRING(SBE.BE_LOCALIZ,8,5) "

	memowrit("C:\query\twmsa009_end_dispo.txt",_cQryDes)

	// variavel que recebe os dados da query pra comparação
	_aTotEndDis := U_SqlToVet(_cQryDes)

	// valido se existe endereços suficientes
	If (Empty(mvEndDes))
		If (len(_aTotEndDis)) < (_cAlTrbMov)->(RecCount()) .And. ( ! _lCtrVolume)
			alert("Não existe quantidade de endereços suficientes para armazenar conforme os parâmetros informados.")
			Return()
		ElseIf (Len(_aTotEndDis) < _nEndPlan)
			alert("Não existe quantidade de endereços suficientes para armazenar conforme os parâmetros informados.")
			Return()
		EndIf
	Else
		// pelo menos um registro ele precisa ter encontrado
		If (len(_aTotEndDis) <= 0)
			alert("O endereço informado não está vazio, não existe ou há regra de picking cadastrada. Check os parâmetros.")
			Return()
		EndIf
	EndIf

	// reclock pra gravar arquivo
	RecLock((_cAlTrbMov),.F.)

	// vou varrer o arquivo de trabalho
	For _nX := 1 to (_cAlTrbMov)->(RecCount() )

		// validação para contorle de duplicação de endereço
		If ((_cAlTrbMov)->PALLET == _cPallet)
			(_cAlTrbMov)->ENDDES := _cEndDes
		Else
			// valido se vai pra um endereço único, tipo DOCA ou BLOCADO
			If (len(_aTotEndDis) == 1) .And. (! Empty(mvEndDes))
				(_cAlTrbMov)->ENDDES := _aTotEndDis[1] // jogo o valor único do array na variável se tiver apenas um endereço
			Else
				(_cAlTrbMov)->ENDDES := _aTotEndDis[_nX] // valor dinâmico dos endereços
			EndIf

			// endereço para controle
			_cEndDes := (_cAlTrbMov)->ENDDES
		EndIf

		// pallet para controle de endereços duplicados devido a mais de um produto no mesmo endereço
		_cPallet := (_cAlTrbMov)->PALLET

		// validações para preencher o endereço de transação
		// importante para realizar operações diretamente pelo paleteiro

		// 1ª validação = Endereço de Origem
		If ( sfVldTpEnd( (_cAlTrbMov)->ENDORI ) )
			// valido se o endereço de destino não é outra doca ou blocado
			If ( sfVldTpEnd( (_cAlTrbMov)->ENDORI ) )
				(_cAlTrbMov)->ENDTRA := ""
			Else
				(_cAlTrbMov)->ENDTRA := SUBSTR((_cAlTrbMov)->ENDDES,1,2)
			EndIf
			// 2ª validação = Endereço de Destino
		Else
			(_cAlTrbMov)->ENDTRA := SUBSTR((_cAlTrbMov)->ENDORI,1,2)
		EndIf

		// avalia se precisa mudar de lado (demonstrativo)
		If (SUBSTR((_cAlTrbMov)->ENDORI, 3,1) !=  SUBSTR((_cAlTrbMov)->ENDDES,3,1))
			// se muda de lado ou não
			(_cAlTrbMov)->MUDALADO := "S"
		Else
			// se muda de lado ou não
			(_cAlTrbMov)->MUDALADO := "N"
		EndIf

		// pego a distância baseada nas ruas
		(_cAlTrbMov)->DISTANCIA := ABS(Val(SUBSTR((_cAlTrbMov)->ENDORI,1,2)) - Val(SUBSTR((_cAlTrbMov)->ENDDES,1,2)))

		// próximo valor
		(_cAlTrbMov)->(dbSkip())
	Next _nX

	// finalizo o reclock
	MsUnlock()

	// vai para o primeiro registro
	(_cAlTrbMov)->(dbGoTop())

	// monta o dialogo
	_oDlgBro := MSDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"OS Interna - Transferências",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do rodape
	_oPnlRodape := TPanel():New(000,000,nil,_oDlgBro,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlRodape:Align := CONTROL_ALIGN_BOTTOM

	// cria botões rodape
	// marcar todos
	//_oBtMarkAll := TButton():New( 010, 010,"Marcar/Desmarcar Todos",_oPnlBottom,{|| sfMarkAll(_oBrwEnd) }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 006, 006,"Marcar/Desmarcar Todos",_oPnlRodape,{|| sfMarkAllTrb(_oBrowse) }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 006, 100, "Gerar OS" , _oPnlRodape,{|| Processa({ || Iif(sfVldSelec(), { sfGeraTrf(mvCli, mvLj, mvArm, mvArmDes, .f.), _oDlgBro:END() }, Nil) },"Gerando OS Interna...",,.T.) },60,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 006, 174, "Cancelar" , _oPnlRodape,{|| _oDlgBro:END() },60,010,,,.F.,.T.,.F.,,.F.,,,.F. )

	// browse com a listagem da endereços
	_oBrowse := MsSelect():New((_cAlTrbMov),"IT_OK",,_aHeadBrw,,_cMarca,{15,1,183,373},,,,,,)
	_oBrowse:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	// ativa a tela
	ACTIVATE MSDIALOG _oDlgBro CENTERED

	_cArqOsTrf:Delete()

Return(.t.)

// ** função pra validar se algum registro foi selecionado ** //
Static Function sfVldSelec()

	// variavel de retorno
	local _lRet     := .T.
	local _nItSelec := 0

	// vou varrer o arquivo de trabalho pra verificar se algum registro foi solicitado
	While (_cAlTrbMov)->(!Eof())
		// valido se algum registro foi selecionado
		If ( ! Empty((_cAlTrbMov)->IT_OK))
			_nItSelec ++
		EndIf

		// próximo valor
		(_cAlTrbMov)->(dbSkip())
	EndDo

	// se nada foi selecionado, avisa
	If (_nItSelec <= 0)
		MsgAlert("É preciso selecionar pelo menos um registro para geração da OS!")
		_lRet := .F.
	EndIf

	// vai pro primeiro registro
	(_cAlTrbMov)->(dbGoTop())

Return _lRet

// ** funcao que gera a OS com os detalhes das movimentacoes de transferencia
Static Function sfGeraTrf(mvCli, mvLj, mvArm, mvArmDes, mvMovLivre)
	Local _lRet    := .F.
	Local _cNumId  := ""
	local _nSeq    := 0
	local _aRecHum := {} // array para convocação recursos humanos
	local _aRecEqu := {} // array para convocação recursos equipamento
	//Variavel temporaria For
	Local _nX,_nZ

	// valor padrao
	Default mvArm    := CriaVar("BE_LOCAL",.f.)
	Default mvArmDes := CriaVar("BE_LOCAL",.f.)

	// movimentação/armazenamento por volume
	_lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME","L",.F.,.F.,Nil, mvCli, mvLj, Nil, Nil)

	// inicio a transação para ter um rollback em caso de erro
	BEGIN TRANSACTION

		dbSelectArea("Z05")
		_cNumId := GetSXENum("Z05","Z05_NUMOS", xFilial("Z05"))

		// crio a Z05
		dbSelectArea("Z05")
		RECLOCK("Z05", .T.)
		Z05->Z05_FILIAL   := xFilial("Z05")
		Z05->Z05_NUMOS    := _cNumId
		Z05->Z05_DTEMIS   := DATE()
		Z05->Z05_HREMIS   := TIME()
		Z05->Z05_TPOPER   := "I"
		Z05->Z05_CLIENT   := mvCli
		Z05->Z05_LOJA     := mvLj
		MSUNLOCK()     // Destrava o registro

		// crio a Z06
		dbSelectArea("Z06")
		RECLOCK("Z06", .T.)
		Z06->Z06_FILIAL   := xFilial("Z06")
		Z06->Z06_NUMOS    := _cNumId
		Z06->Z06_SEQOS    := "001"
		Z06->Z06_SERVIC   := "014"
		Z06->Z06_TAREFA   := IIf(mvMovLivre, "T08", "013")
		Z06->Z06_DTEMIS   := DATE()
		Z06->Z06_HREMIS   := TIME()
		Z06->Z06_USRINC   := __cUserId
		Z06->Z06_STATUS   := "AG"
		Z06->Z06_PRIOR    := "99"
		Z06->Z06_LOCAL    := mvArm
		Z06->Z06_ATUEST   := "S"
		Z06->Z06_ENDSRV   := "ZZZ"
		MSUNLOCK()     // Destrava o registro

		// quando nao for movimentacao livre, grava o mapa conforme arquivo de trabalho
		If ( ! mvMovLivre )

			// posiciona no primeiro registro
			(_cAlTrbMov)->(DbGoTop())

			// vou varrer o arquivo de trabalho
			While (_cAlTrbMov)->(!Eof())
				// se estiver flagado
				If (!Empty((_cAlTrbMov)->IT_OK))

					// incremente da variável
					_nSeq := _nSeq + 1

					// para movimentos simples, gera apenas um registro na Z08

					// 16/06/2015 - David
					//If ((_cAlTrbMov)->DISTANCIA == 0).Or.( sfVldTpEnd((_cAlTrbMov)->ENDORI) ).Or.( sfVldTpEnd((_cAlTrbMov)->ENDDES) )

					// alterado até decisão da equipe TECADI para a SAMSONITE
					If (_lCtrVolume).Or.((_cAlTrbMov)->DISTANCIA  == 0).Or.(sfVldTpEnd((_cAlTrbMov)->ENDORI)).Or.(sfVldTpEnd((_cAlTrbMov)->ENDDES)).Or.((_cAlTrbMov)->ARM != mvArmDes)
						// crio a Z08
						dbSelectArea("Z08")
						RECLOCK("Z08", .T.)
						Z08->Z08_FILIAL  := xFilial("Z08")
						Z08->Z08_NUMOS   := _cNumId
						Z08->Z08_SEQOS   := "001"
						Z08->Z08_LOCAL   := (_cAlTrbMov)->ARM
						Z08->Z08_LOCDES  := mvArmDes
						Z08->Z08_SERVIC  := "014"
						Z08->Z08_TAREFA  := "013"
						Z08->Z08_ENDSRV  := (_cAlTrbMov)->ENDORI
						Z08->Z08_ENDORI  := (_cAlTrbMov)->ENDORI
						Z08->Z08_ENDTRA  := (_cAlTrbMov)->ENDTRA
						Z08->Z08_ENDDES  := (_cAlTrbMov)->ENDDES
						Z08->Z08_DTEMIS  := Date()
						Z08->Z08_HREMIS  := Time()
						Z08->Z08_STATUS  := "P" // P-Planejado / R-Realizado / M-Movimento / E-Erro
						Z08->Z08_PRODUT  := (_cAlTrbMov)->CODPRO
						Z08->Z08_QUANT   := (_cAlTrbMov)->QUANT
						Z08->Z08_PRIOR   := "99"
						Z08->Z08_PALLET  := (_cAlTrbMov)->PALLET
						Z08->Z08_FRAPLT  := "N"
						Z08->Z08_SEQUEN  := STRZERO(_nSeq,4)
						Z08->Z08_TPOPER  := "I"
						Z08->Z08_CLIENT  := mvCli
						Z08->Z08_LOJA    := mvLj
						Z08->Z08_ENDRET  := "TRANSF"
						Z08->(MsUnLock())
						// paleteiro e trilateral - crio dois registros na Z08
					Else

						// crio a Z08 - MOV 1
						dbSelectArea("Z08")
						RECLOCK("Z08", .T.)
						Z08->Z08_FILIAL  := xFilial("Z08")
						Z08->Z08_NUMOS   := _cNumId
						Z08->Z08_SEQOS   := "001"
						Z08->Z08_LOCAL   := (_cAlTrbMov)->ARM
						Z08->Z08_LOCDES  := mvArmDes
						Z08->Z08_SERVIC  := "014"
						Z08->Z08_TAREFA  := "013"
						//Z08->Z08_ATIVID := "006"
						Z08->Z08_ENDSRV  := (_cAlTrbMov)->ENDORI
						Z08->Z08_ENDORI  := (_cAlTrbMov)->ENDORI
						Z08->Z08_ENDTRA  := IIF(sfVldTpEnd((_cAlTrbMov)->ENDDES),"",(_cAlTrbMov)->ENDTRA)
						Z08->Z08_ENDDES  := IIF(sfVldTpEnd((_cAlTrbMov)->ENDDES),SUBSTR((_cAlTrbMov)->ENDORI,1,2),SUBSTR((_cAlTrbMov)->ENDDES,1,2)) // RUA
						Z08->Z08_DTEMIS  := Date()
						Z08->Z08_HREMIS  := Time()
						Z08->Z08_STATUS  := "P" // P-Planejado / R-Realizado / M-Movimento / E-Erro
						Z08->Z08_PRODUT  := (_cAlTrbMov)->CODPRO
						Z08->Z08_QUANT   := (_cAlTrbMov)->QUANT
						Z08->Z08_PRIOR   := "99"
						Z08->Z08_PALLET  := (_cAlTrbMov)->PALLET
						Z08->Z08_FRAPLT  := "N"
						Z08->Z08_SEQUEN  := STRZERO(_nSeq,4)
						Z08->Z08_TPOPER  := "I"
						Z08->Z08_CLIENT  := mvCli
						Z08->Z08_LOJA    := mvLj
						Z08->Z08_ENDRET  := "TRANSF"
						Z08->(MsUnLock())

						// crio a Z08 - MOV 2
						dbSelectArea("Z08")
						RECLOCK("Z08", .T.)
						Z08->Z08_FILIAL := xFilial("Z08")
						Z08->Z08_NUMOS  := _cNumId
						Z08->Z08_SEQOS  := "001"
						Z08->Z08_LOCAL  := (_cAlTrbMov)->ARM
						Z08->Z08_LOCDES  := mvArmDes
						Z08->Z08_SERVIC := "014"
						Z08->Z08_TAREFA := "013"
						//Z08->Z08_ATIVID := "006"
						Z08->Z08_ENDSRV := IIF(sfVldTpEnd((_cAlTrbMov)->ENDDES),SUBSTR((_cAlTrbMov)->ENDORI,1,2),SUBSTR((_cAlTrbMov)->ENDDES,1,2)) // RUA
						Z08->Z08_ENDORI := IIF(sfVldTpEnd((_cAlTrbMov)->ENDDES),SUBSTR((_cAlTrbMov)->ENDORI,1,2),SUBSTR((_cAlTrbMov)->ENDDES,1,2)) // RUA
						Z08->Z08_ENDTRA := ""
						Z08->Z08_ENDDES := (_cAlTrbMov)->ENDDES
						Z08->Z08_DTEMIS := Date()
						Z08->Z08_HREMIS := Time()
						Z08->Z08_STATUS := "P" // P-Planejado / R-Realizado / M-Movimento / E-Erro
						Z08->Z08_PRODUT := (_cAlTrbMov)->CODPRO
						Z08->Z08_QUANT  := (_cAlTrbMov)->QUANT
						Z08->Z08_PRIOR  := "99"
						Z08->Z08_PALLET := (_cAlTrbMov)->PALLET
						Z08->Z08_FRAPLT := "N"
						Z08->Z08_SEQUEN := STRZERO(_nSeq,4)
						Z08->Z08_TPOPER := "I"
						Z08->Z08_CLIENT  := mvCli
						Z08->Z08_LOJA    := mvLj
						Z08->Z08_ENDRET  := "TRANSF"
						Z08->(MsUnLock())

					EndIf

				EndIf

				// próximo valor
				(_cAlTrbMov)->(dbSkip())
			EndDo

		EndIf

		// Sempre preencho o paleteiro, para os casos onde existe endereço primeiro nível
		_aRecHum := {{"O","WMS04"},{"O","WMS03"}}
		_aRecEqu := {{"E","TE1"}, {"E","ER1"}, {"E","EG1"}, {"E","EE1"}, {"E","PE1"}}

		// criar registro na Z18 para convocação recurso humano
		For _nX :=1 to Len(_aRecHum)
			dbSelectArea("Z18")
			RECLOCK("Z18", .T.)
			Z18->Z18_FILIAL   := xFilial("Z06")
			Z18->Z18_NUMOS    := _cNumId
			Z18->Z18_SEQOS    := "001"
			Z18->Z18_CATEG    := "O"
			Z18->Z18_STATUS   := "P"
			Z18->Z18_FUNCAO   := _aRecHum[_nX][2]
			Z18->Z18_QUANT    := 0
			MSUNLOCK()     // Destrava o registro
		Next

		// criar registro na Z18 para convocação recurso humano
		For _nZ:=1 to len(_aRecEqu)
			dbSelectArea("Z18")
			RECLOCK("Z18", .T.)
			Z18->Z18_FILIAL   := xFilial("Z06")
			Z18->Z18_NUMOS    := _cNumId
			Z18->Z18_SEQOS    := "001"
			Z18->Z18_CATEG    := "E"
			Z18->Z18_STATUS   := "P"
			Z18->Z18_TPEQUI   := _aRecEqu[_nZ][2]
			Z18->Z18_QUANT    := 1
			MSUNLOCK()     // Destrava o registro
		Next

		// confirma auto-increment
		ConfirmSX8()

		_lRet := .T.

	END TRANSACTION

	If (_lRet)
		U_FtWmsMsg("OS de Transferência gerada com sucesso. Nº: "+_cNumId+"","Aviso")
		Return (.T.)
	Else
		U_FtWmsMsg("OS de Transferência não foi gerada. Tenta novamente!","Atenção")
		Return (.F.)
	EndIf

Return()

// ** funcao para selecionar os Kit disponiveis para os produtos da nota
Static Function sfSelecKit(mvSeqKit)
	// objetos da tela
	local _oDlgMntKit
	local _oPnlCabec1, _oPnlCabec2
	local _oPnlKit, _oPnlKitDisp, _oPnlKitComp
	local _oPnlKitMont
	// browse
	local _oBrwKitDisp, _oBrwKitComp, _oBrwKitMontado, _oBrwCompReserv
	// botoes
	local _oBtnConfirma, _oBtnCancela
	local _oBtnGeraKit
	// labels/texto
	local _oSayQtdKit
	// get
	local _oGetQtdKit

	// controle de confirmacao da tela
	local _lConfOk := .f.

	// header do Browse
	local _aHeadBrw := aClone(_oBrwDetVincNf:aHeader)
	// posicao dos campos no browse
	local _nPosTipoNf := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="F1_TIPO"})   // tipo nf
	local _nPosDoc    := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="F1_DOC"})    // nota fiscal
	local _nPosSerie  := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="F1_SERIE"})  // serie
	local _nPosItem   := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="D1_ITEM"})   // item
	local _nPosProd   := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="D1_COD"})    // cod produto
	local _nPosLocal  := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="D1_LOCAL"})  // local/armazem
	local _nPosSaldo  := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="D1_QUANT"})  // saldo disponivel
	local _nPosQuant  := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="IT_SALDO"})  // quantidade
	local _nPosNumSeq := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="D1_NUMSEQ"}) // num seq
	local _nPosLastro := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="IT_LASTRO"}) // lastro
	local _nPosCamada := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="IT_CAMADA"}) // camada
	local _nPosAdicio := aScan(_aHeadBrw,{|x| AllTrim(x[2])=="IT_ADICIO"}) // adicional
	// variaveis temporarias
	local _nItKitMnt

	// itens da nota
	local _aItensNf := aClone(_oBrwDetVincNf:aCols)

	// campos do browse dos kits disponiveis
	local _aHdKitDisp   := {}
	local _cAlTrKitDisp := GetNextAlias()

	// browse com os componentes o kit selecionado
	local _aHeadComp := {}
	local _aColsComp := {}

	// browse com os kit montados
	local _aHeadMont := {}
	local _aColsMont := {}

	// browse com os componentes reservados para o kit montado
	local _aHeadReserv := {}
	local _aColsReserv := {}

	// codigos dos produtos da nota
	local _cCodProdNf := ""

	// quantidade maxima para montar por kit
	local _nQtdMontar := 0

	// armazem/local atual
	local _cArmzKit := CriaVar("BE_LOCAL", .F.)

	// controle de componente
	Local _nComp

	// define campos do browse de componente de kit
	aAdd(_aHeadComp,{"Produto"    ,"Z29_PRODUT", PesqPict("Z29","Z29_PRODUT") ,TamSx3("Z29_PRODUT")[1], TamSx3("Z29_PRODUT")[2],Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadComp,{"Descrição"  ,"B1_DESC"   , PesqPict("SB1","B1_DESC")    ,TamSx3("B1_DESC")[1]   , TamSx3("B1_DESC")[2]   ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadComp,{"Quantidade" ,"Z29_QUANT" , PesqPict("Z29","Z29_QUANT")  ,TamSx3("Z29_QUANT")[1] , TamSx3("Z29_QUANT")[2] ,Nil,Nil,"N",Nil,"R",,,".F." })

	// define campos do browse de kit montados
	aAdd(_aHeadMont,{"Seq"           ,"Z29_SEQKIT", ""                           , 3                     , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadMont,{"Codigo do Kit" ,"Z29_CODKIT", PesqPict("Z29","Z29_CODKIT") ,TamSx3("Z29_CODKIT")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadMont,{"Descrição"     ,"Z29_DSCKIT", PesqPict("Z29","Z29_DSCKIT") ,TamSx3("Z29_DSCKIT")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadMont,{"Quantidade"    ,"Z29_QUANT" , PesqPict("Z29","Z29_QUANT")  ,TamSx3("Z29_QUANT")[1] , TamSx3("Z29_QUANT")[2] ,Nil,Nil,"N",Nil,"R",,,".F." })

	// define campos do browse de componente reservados para montar os kits
	aAdd(_aHeadReserv,{"Seq"        ,"Z29_SEQKIT", ""                           , 3                     , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadReserv,{"Produto"    ,"Z29_PRODUT", PesqPict("Z29","Z29_PRODUT") ,TamSx3("Z29_PRODUT")[1], TamSx3("Z29_PRODUT")[2],Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadReserv,{"Descrição"  ,"B1_DESC"   , PesqPict("SB1","B1_DESC")    ,TamSx3("B1_DESC")[1]   , TamSx3("B1_DESC")[2]   ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadReserv,{"Quantidade" ,"Z29_QUANT" , PesqPict("Z29","Z29_QUANT")  ,TamSx3("Z29_QUANT")[1] , TamSx3("Z29_QUANT")[2] ,Nil,Nil,"N",Nil,"R",,,".F." })
	aAdd(_aHeadReserv,{"Doc. Fiscal","F1_DOC"    , ""                           ,TamSx3("F1_DOC")[1]    , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadReserv,{"Serie"      ,"F1_SERIE"  , ""                           ,TamSx3("F1_SERIE")[1]  , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadReserv,{"Tipo NF"    ,"F1_TIPO"   , ""                           ,TamSx3("F1_TIPO")[1]   , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadReserv,{"Item"       ,"D1_ITEM"   , ""                           ,TamSx3("D1_ITEM")[1]   , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadReserv,{"NumSeq"     ,"D1_NUMSEQ" , ""                           ,TamSx3("D1_NUMSEQ")[1] , 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })

	// armazena os codigos dos produtos (com saldo)
	aEval(_aItensNf,{|_xItensNf| IIf(_xItensNf[_nPosSaldo] > 0, _cCodProdNf += _xItensNf[_nPosProd] + "|", Nil) })

	// busca os kit disponiveis conforme relacao de produtos
	sfSelKitDisp(_cAlTrKitDisp, @_aHdKitDisp, _cCodProdNf)

	// definicao da tela
	_oDlgMntKit := MSDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"Montagem de Kit de Produtos",,,.F.,,,,,,.T.,,,.T. )
	_oDlgMntKit:lMaximized := .T.

	// cria o panel do cabecalho - botoes
	_oPnlCabec1 := TPanel():New(000,000,nil,_oDlgMntKit,,.F.,.F.,,,000,030,.T.,.F. )
	_oPnlCabec1:Align:= CONTROL_ALIGN_TOP

	// botao confirmar
	_oBtnConfirma := TButton():New(010,((_aSizeWnd[5]/2)- 100),"Confirmar" ,_oPnlCabec1,{|| IIf(_lConfOk := sfConfMntKit(), _oDlgMntKit:End(), Nil) },045,012,,,,.T.,,"",,,,.F. )
	// botao cancelar
	_oBtnCancela  := TButton():New(010,((_aSizeWnd[5]/2)-  50),"Cancelar"  ,_oPnlCabec1,{|| _oDlgMntKit:End() },045,012,,,,.T.,,"",,,,.F. )

	// cria panel para incluir 2 novos panels
	_oPnlKit := TPanel():New(000,000,nil,_oDlgMntKit,,.F.,.F.,,,000,080,.T.,.F. )
	_oPnlKit:Align:= CONTROL_ALIGN_TOP

	// cria panel com os Kit de produtos disponiveis
	_oPnlKitDisp := TPanel():New(000,000,nil,_oPnlKit,,.F.,.F.,,,240,080,.T.,.F. )
	_oPnlKitDisp:Align:= CONTROL_ALIGN_LEFT

	// browse com as opcoes de kit
	_oBrwKitDisp := MsSelect():New((_cAlTrKitDisp),,,_aHdKitDisp,,,{001,001,400,1000},,,_oPnlKitDisp,,)
	_oBrwKitDisp:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwKitDisp:oBrowse:bChange := {|| sfBuscaEstru((_cAlTrKitDisp)->KIT_CODIGO, @_aColsComp, @_oBrwKitComp, _aItensNf, .t., @_nQtdMontar, @_oGetQtdKit ) }

	// cria panel com componentes do Kit de produto selecionado
	_oPnlKitComp := TPanel():New(000,000,nil,_oPnlKit,,.F.,.F.,,,000,080,.T.,.F. )
	_oPnlKitComp:Align:= CONTROL_ALIGN_ALLCLIENT

	// monta o browse com os componentes do kit selecionado
	_oBrwKitComp := MsNewGetDados():New(000,000,400,400,,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsComp),'AllwaysTrue()','','AllwaysTrue()',_oPnlKitComp,_aHeadComp,_aColsComp)
	_oBrwKitComp:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// cria o panel do cabecalho - botoes
	_oPnlCabec2 := TPanel():New(000,000,nil,_oDlgMntKit ,,.F.,.F.,,CLR_LIGHTGRAY,000,030,.T.,.F. )
	_oPnlCabec2:Align:= CONTROL_ALIGN_TOP

	// quantidade possivel para montar o kit selecionado
	_oSayQtdKit := TSay():New(010,003,{||"Quantidade"},_oPnlCabec2,,,.F.,.F.,.F.,.T.)
	// quantidade maxima por kit selecionado
	_oGetQtdKit := tSpinBox():new(008, 050, _oPnlCabec2, {|x| _nQtdMontar := x }, 045, 012)

	// botao gerar kit
	_oBtnGeraKit := TButton():New(008,100,"Gerar Kit" ,_oPnlCabec2,{|| sfMontaKit((_cAlTrKitDisp)->KIT_CODIGO, (_cAlTrKitDisp)->KIT_DESCR, @_nQtdMontar, @_oGetQtdKit, @_aItensNf, @mvSeqKit, @_oBrwKitMontado, @_oBrwCompReserv) },045,012,,,,.T.,,"",,,,.F. )

	// cria panel com os Kit ja montados
	_oPnlKitMont := TPanel():New(000,000,nil,_oDlgMntKit,,.F.,.F.,,,240,900,.T.,.F. )
	_oPnlKitMont:Align:= CONTROL_ALIGN_LEFT

	// monta o browse com a lista dos kit montados
	_oBrwKitMontado := MsNewGetDados():New(000,000,400,400,,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsMont),'AllwaysTrue()','','AllwaysTrue()',_oPnlKitMont,_aHeadMont,_aColsMont)
	_oBrwKitMontado:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwKitMontado:oBrowse:bChange := {|| sfFiltraReserv(_oBrwKitMontado:aCols[_oBrwKitMontado:nAt][1], @_oBrwCompReserv) }

	// monta o browse com a lista dos componentes resercados dos kit montados
	_oBrwCompReserv := MsNewGetDados():New(000,000,400,400,,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsReserv),'AllwaysTrue()','','AllwaysTrue()',_oDlgMntKit,_aHeadReserv,_aColsReserv)
	_oBrwCompReserv:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa o dialogo
	_oDlgMntKit:Activate(,,,.T.,,, )

	// atualiza dados ao confirmar a tela
	If (_lConfOk)

		// atualiza variaveis
		_aColsMont   := aClone(_oBrwKitMontado:aCols)
		_aColsReserv := aClone(_oBrwCompReserv:aCols)

		// busca o armazem padrao por cliente
		_cArmzKit := U_FtWmsParam("WMS_ARMAZEM_POR_CLIENTE","C","A1",.f.,Nil, SZZ->ZZ_CLIENTE, SZZ->ZZ_LOJA, Nil, Nil)

		// varre todos os kit montados
		For _nItKitMnt := 1 to Len(_aColsMont)

			// valida se ha dados
			If ( ! Empty(_aColsMont[_nItKitMnt][1]) )

				// adiciona kit
				aAdd(_aItensNf,{"",; // doc
				"",; // serie
				"",; // tipo nf
				"",; // item nf
				"",; // num seq
				_aColsMont[_nItKitMnt][2],; // cod kit
				_aColsMont[_nItKitMnt][3],; // descricao kit
				_cArmzKit,; // armazem
				"", ; // UM
				_aColsMont[_nItKitMnt][4],; // saldo
				_aColsMont[_nItKitMnt][4],; // quantidade
				0 ,; // lastro
				0 ,; // camada
				0 ,; // adicional
				0 ,; // quantidade de paletes
				_aColsMont[_nItKitMnt][1],; // seq kit
				_aColsMont[_nItKitMnt][2],; // cod kit
				'' ,; // lote
				0 ,; // seg unid medida
				.t.,; // permite editar
				.f. })

				// adiciona componentes do kit
				For _nComp := 1 to Len(_aColsReserv)
					// valida o codigo da sequencia do kit
					If (_aColsReserv[_nComp][1] == _aColsMont[_nItKitMnt][1])
						aAdd(_aItensNf,{_aColsReserv[_nComp][5] ,; // doc
						_aColsReserv[_nComp][6]  ,; // serie
						_aColsReserv[_nComp][7]  ,; // tipo nf
						_aColsReserv[_nComp][8]  ,; // item nf
						_aColsReserv[_nComp][9]  ,; // num seq
						_aColsReserv[_nComp][2]  ,; // cod produto
						_aColsReserv[_nComp][3]  ,; // descricao produto
						_cArmzKit,; // armazem
						Posicione("SB1", 1, xFilial("SB1") + _aColsReserv[_nComp][2], "B1_UM"),; //UM
						_aColsReserv[_nComp][4]  ,; // saldo
						_aColsReserv[_nComp][4]  ,; // quantidade
						0 ,; // lastro
						0 ,; // camada
						0 ,; // adicional
						0 ,; // quantidade de paletes
						_aColsMont[_nItKitMnt][1],; // seq kit
						_aColsMont[_nItKitMnt][2],; // cod kit
						'' ,; // lote
						0 ,; // seg unid medida
						.t.,; // permite editar
						.f. })
					EndIf
				Next _nComp
			EndIf

		Next _nItKitMnt

		// atualiza browse das notas
		_oBrwDetVincNf:aCols := aClone(_aItensNf)
		_oBrwDetVincNf:oBrowse:Refresh()

	EndIf

Return(.t.)

// ** funcao que destaca a cor da linha do grid
Static Function sfDestCor(mvBrwCols, mvLinPos, mvSeqKit)
	// cor padrao
	local _nCorRet := CLR_WHITE
	// cor destaque
	Local _nCorDestaque := CLR_YELLOW

	// verifica se atende a condicao solicitada
	If ( ! Empty(mvBrwCols[mvLinPos][1])) .And. (mvBrwCols[mvLinPos][1] == mvSeqKit)
		_nCorRet := _nCorDestaque
	Endif

Return(_nCorRet)

// ** funcao que busca os kit disponiveis conforme produtos
Static Function sfSelKitDisp(mvAlTrKitDisp, mvHdKitDisp, mvCodProdNf)
	// arquivo temporario
	local _aStKitDisp   := {}
	local _cTrKitDisp   := ""
	// query
	local _cQuery := ""

	// abre tabela do cadastro de Kit
	dbSelectArea("Z29")

	// monta a estrutura do arquivo de trabalho
	aAdd(_aStKitDisp,{"KIT_OK"      ,"C", 2,0})
	aAdd(_aStKitDisp,{"KIT_CODIGO"  ,"C", TamSx3("Z29_CODKIT")[1],0})   ; aAdd(mvHdKitDisp,{"KIT_CODIGO"  ,"","Codigo Kit",""})
	aAdd(_aStKitDisp,{"KIT_DESCR"   ,"C", TamSx3("Z29_DSCKIT")[1],0})   ; aAdd(mvHdKitDisp,{"KIT_DESCR"   ,"","Descrição" ,""})

	// fecha alias do TRB
	If (Select(mvAlTrKitDisp)<>0)
		dbSelectArea(mvAlTrKitDisp)
		dbCloseArea()
	EndIf

	// cria arquivo de trabalho
	_cTrKitDisp := FWTemporaryTable():New( mvAlTrKitDisp )
	_cTrKitDisp:SetFields( _aStKitDisp )
	_cTrKitDisp:Create()

	// busca kit disponiveis conforme produtos
	_cQuery := "SELECT DISTINCT '' IT_OK, Z29_CODKIT KIT_CODIGO, Z29_DSCKIT KIT_DESCR "
	// cad. de Kit
	_cQuery += "FROM "+RetSqlName("Z29")+" Z29 (nolock)  "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z29")
	// codigo de produtos
	_cQuery += "AND Z29_PRODUT IN "+FormatIn(mvCodProdNf,"|")+" "
	// ordem dos dados
	_cQuery += "ORDER BY Z29_CODKIT"

	memowrit("c:\query\twmsa009_sfSelKitDisp.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQuery,_aStKitDisp,(mvAlTrKitDisp))

	// abre o arquivo de trabalho
	dbSelectArea(mvAlTrKitDisp)
	(mvAlTrKitDisp)->(dbGoTop())

Return

// ** funcao que busca a estrutura do kit selecionado
Static Function sfBuscaEstru(mvCodKit, mvColsComp, mvBrwKitComp, mvItensNf, mvAtuBrw, mvQtdMontar, mvGetQtdKit)
	// Query
	local _cQuery

	// busca componentes do kit selecionado
	_cQuery := "SELECT Z29_PRODUT, B1_DESC, Z29_QUANT, '.F.' IT_DEL "
	// cad. de Kit
	_cQuery += "FROM "+RetSqlName("Z29")+" Z29 (nolock)  "
	// cad. de produtos
	_cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON "+RetSqlCond("SB1")+" AND B1_COD = Z29_PRODUT "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z29")
	// codigo do kit
	_cQuery += "AND Z29_CODKIT = '"+mvCodKit+"' "
	// ordem dos dados
	_cQuery += "ORDER BY B1_DESC"

	// atualiza variavel
	mvColsComp := U_SqlToVet(_cQuery)

	// verifica se atualiza browse
	If (mvAtuBrw)

		// calcula quantidade de kit que podem ser montados
		sfCalcEstru(mvCodKit, mvColsComp, mvItensNf, @mvQtdMontar, @mvGetQtdKit)

		// atualiza browse
		mvBrwKitComp:aCols := aClone(mvColsComp)
		mvBrwKitComp:oBrowse:Refresh()

	EndIf

Return(.t.)

// ** funcao para montar a estrutura, conforme componentes disponiveis
Static Function sfCalcEstru(mvCodKit, mvColsComp, mvItensNf, mvQtdMontar, mvGetQtdKit)
	// variaveis temporarias
	local _nComp
	local _nItNf

	// maior quantidade informada no componente
	local _nMaxQuant := 0
	// quantidade maxima do kit selecionado
	local _nQtdKit := 0
	local _nMaxMntKit := 0
	local _nMinMntKit := 0
	// quantidade disponivel
	local _nQtdDisp := 0

	// kit completo
	local _lKitOk := .t.

	// varre todos os componentes, para buscar a quantidade maxima por componente
	For _nComp := 1 to Len(mvColsComp)
		// calcula quantidade maxima
		If (mvColsComp[_nComp][3] > _nMaxQuant)
			_nMaxQuant := mvColsComp[_nComp][3]
		EndIf
	Next _nComp

	// varre todos os componentes novamente para buscar a quantidade por produto
	For _nComp := 1 to Len(mvColsComp)

		// se nao ha saldo, fecha a rotina
		If ( ! _lKitOk)
			Exit
		EndIf

		// zera variaveis
		_nQtdDisp := 0

		// varre todos os itens da nota para validar quantidade disponivel para montar o kit
		For _nItNf := 1 to Len(mvItensNf)
			// verifica se o componente esta na lista
			If (mvItensNf[_nItNf][6] == mvColsComp[_nComp][1])
				// calcula quantidade disponivel
				_nQtdDisp += (mvItensNf[_nItNf][10] - mvItensNf[_nItNf][11])
			EndIf
		Next _nItNf

		// calcula quantidade de KIT
		_nQtdKit := Int(_nQtdDisp / _nMaxQuant)
		// seta valor minimo
		If (_nQtdKit > 0)
			_nMinMntKit := 1
		EndIf

		// se nao tem quantidade disponivel, kit nao sera completo
		If (_nQtdKit <= 0)
			_lKitOk     := .f.
			_nMinMntKit := 0
			_nMaxMntKit := 0
			Exit
		EndIf

		// armazena a quantidade maxima de kit possiveis
		If (_nMaxMntKit == 0)
			_nMaxMntKit	:= _nQtdKit
		ElseIf (_nMaxMntKit > 0) .And. (_nQtdKit < _nMaxMntKit)
			_nMaxMntKit	:= _nQtdKit
		EndIf

	Next _nComp

	// variavel local
	mvQtdMontar := _nMaxMntKit
	// atualiza Get
	mvGetQtdKit:SetRange(_nMinMntKit,_nMaxMntKit)
	mvGetQtdKit:SetValue(_nMaxMntKit)
	mvGetQtdKit:Refresh()

Return (_lKitOk)

// ** funcao que monta kit temporario
Static Function sfMontaKit(mvCodKit, mvDescKit, mvQtdMontar, mvGetQtdKit, mvItensNf, mvSeqKit, mvBrwKitMontado, mvBrwCompReserv)
	// variaveis temporarias
	local _nComp
	local _nItNf
	// componentes do kit selecionado
	local _aCompKit := {}
	// quantidade de reserva do componente
	local _nQtdReser := 0

	// quantidade disponivel
	local _nQtdDisp := 0

	// retorno de kit completo
	local _lKitOk := .t.

	// itens do browse de kit ja montados
	local _aKitMontado := aClone(mvBrwKitMontado:aCols)

	// itens ja reservados para os kits motnados
	local _aCompReserv := aClone(mvBrwCompReserv:aCols)

	// Nota Que sera montada o Kit
	Local _cNotaKit := _oBrwDetVincNf:Acols[ Ascan(_oBrwDetVincNf:Acols,{|x| (x[18] == .t.) }) ][1]

	// valida quantidade selecionada
	If (mvQtdMontar <= 0)
		MsgStop("É obrigatório informar a quantidade de Kit´s.")
		Return(.f.)
	EndIf

	//Verifica se Kit ja foi escolhido. Pode ser selecionado apenas 1 vez.
	If  (Ascan(_aKitMontado,{|x| Alltrim(x[2]) == Alltrim(mvCodKit) }) > 0)
		MsgStop("kit Ja escolhido nesta seleção de nota.")
		Return(.f.)
	EndIf

	//Verifica se Kit ja foi escolhido. Pode ser selecionado apenas 1 vez.
	For _nComp := 1 To Len(_oBrwDetVincNf:Acols)
		//Se a coluna referente a nota estiver em Branco é um Kit.Então fasso a validação.
		If Empty(_oBrwDetVincNf:Acols[_nComp][1])
			If (Alltrim(_oBrwDetVincNf:Acols[_nComp][6]) == Alltrim(mvCodKit)) .And. (Alltrim(_oBrwDetVincNf:Acols[_nComp+1][1]) == Alltrim(_cNotaKit))
				MsgStop("kit Ja escolhido nesta seleção de nota.")
				Return(.f.)
			EndIf
		EndIf
	Next _nComp

	// funcao que retorna os componentes do kit selecionado
	sfBuscaEstru(mvCodKit, @_aCompKit, Nil, Nil , .f. )

	// varre todos os componentes do kit
	For _nComp := 1 to Len(_aCompKit)

		// quantidade necessaria
		_nQtdReser := (_aCompKit[_nComp][3] * mvQtdMontar)

		// pesquisa o componente nos itens disponiveis da nota
		For _nItNf := 1 to Len(mvItensNf)
			// valida codigo do produto
			If (mvItensNf[_nItNf][6] == _aCompKit[_nComp][1])
				// calcula quantidade disponivel
				_nQtdDisp := (mvItensNf[_nItNf][10] - mvItensNf[_nItNf][11])

				// valida quantidade
				If (_nQtdDisp > 0) .And. (_nQtdDisp >= _nQtdReser)

					// deleta linha em branco
					If (Empty(_aCompReserv[1][1]))
						_aCompReserv := {}
					EndIf

					// codigo do kit
					//mvItensNf[_nItNf][15] := mvCodKit

					// atualiza reserva de mercadoria para o kit
					aAdd(_aCompReserv,{mvSeqKit ,;
					mvItensNf[_nItNf][6] ,;
					mvItensNf[_nItNf][7] ,;
					_nQtdReser           ,;
					mvItensNf[_nItNf][1] ,; // doc
					mvItensNf[_nItNf][2] ,; // serie
					mvItensNf[_nItNf][3] ,; // tipo nf
					mvItensNf[_nItNf][4] ,; // item
					mvItensNf[_nItNf][5] ,; // num seq
					.f. })

					// atualiza saldo (diminui a quantidade disponivel)
					mvItensNf[_nItNf][10] -= _nQtdReser
					// controle da quantidade de reserva
					_nQtdReser            -= _nQtdReser

					// sai do segundo loop
					Exit

				Else
					_lKitOk := .f.
				EndIf
			EndIf
		Next _nItNf

		// valida geracao completa do kit
		If (_nQtdReser != 0)
			_lKitOk := .f.
		EndIf

	Next _nComp

	// valida se o kit foi montado corretamente
	If (_lKitOk)

		// deleta linha em branco
		If (Empty(_aKitMontado[1][1]))
			_aKitMontado := {}
		EndIf

		// adiciona novo kit
		aAdd(_aKitMontado,{mvSeqKit,;
		mvCodKit   ,;
		mvDescKit  ,;
		mvQtdMontar,;
		.f. })

		// atualiza sequencia de kit
		mvSeqKit := Soma1(mvSeqKit)

		// atualiza dados do browse
		mvBrwKitMontado:aCols := aClone(_aKitMontado)
		mvBrwKitMontado:oBrowse:Refresh()
		mvBrwKitMontado:oBrowse:GoBottom()

		// atualiza browse com as reservas
		mvBrwCompReserv:aCols := aClone(_aCompReserv)
		mvBrwCompReserv:oBrowse:Refresh()

		// refaz a quantidade de kit que podem ser montados
		sfCalcEstru(mvCodKit, _aCompKit, mvItensNf, @mvQtdMontar, @mvGetQtdKit)

	EndIf

Return(_lKitOk)

// ** funcao que valida a geracao dos novos kit
Static Function sfConfMntKit()
	// variavel de retorno
	local _lRetOk := .t.
Return(_lRetOk)

// ** funcao que filtra os itens reservados conforme kit selecionado
Static Function sfFiltraReserv(mvSeqKit, mvBrwCompReserv)

	mvBrwCompReserv:oBrowse:SetBlkBackColor({|| sfDestCor(mvBrwCompReserv:aCols ,mvBrwCompReserv:nAt, mvSeqKit )})
	mvBrwCompReserv:oBrowse:Refresh()

Return

// ** funcao de entrada para realizar o cancelamento de carregamento/pedido
User Function WMSA009E()
	// query
	Local _cQuery   := ""
	// variaveis temporarias
	local _aRetSQL  := {}
	//Estrutura da tabela temporaria
	Local _aEstTrb  := {}
	Local _aHeadBrw := {}

	Local _cArqTrb
	Local aSzBrow	  :={01,01,100,250}
	Private _cTrbPedi := GetNextAlias()
	Private _cMark	  := "OK"
	Private _lInverte  := .F.
	Private _oBrwPedido

	// define a estrutura do TRB
	aAdd(_aEstTrb,{"C5_OK"      ,"C", 2                      ,0})
	aAdd(_aEstTrb,{"C5_NUM"     ,"C",TamSx3("C5_NUM")[1]     ,0})
	aAdd(_aEstTrb,{"Z05_NUMOS"  ,"C",TamSx3("Z05_NUMOS")[1]  ,0})
	aAdd(_aEstTrb,{"C5_CLIENTE" ,"C",TamSx3("C5_CLIENTE")[1] ,0})
	aAdd(_aEstTrb,{"C5_LOJACLI" ,"C",TamSx3("C5_LOJACLI")[1] ,0})
	aAdd(_aEstTrb,{"A1_NOME"    ,"C",TamSx3("A1_NOME")[1]    ,0})
	aAdd(_aEstTrb,{"C6_LOCAL"   ,"C",TamSx3("C6_LOCAL")[1]   ,0})
	aAdd(_aEstTrb,{"C6_LOCALIZ" ,"C",TamSx3("C6_LOCALIZ")[1] ,0})
	aAdd(_aEstTrb,{"DAI_COD"    ,"C",TamSx3("DAI_COD")[1]    ,0})

	// define o header do browse
	aAdd(_aHeadBrw,{"C5_OK"      ,"@!" ,"  "          })
	aAdd(_aHeadBrw,{"C5_NUM"     ,"@!" ,"Pedido"      })
	aAdd(_aHeadBrw,{"Z05_NUMOS"  ,"@!" ,"OS expedição"})
	aAdd(_aHeadBrw,{"C5_CLIENTE" ,"@!" ,"Cliente"     })
	aAdd(_aHeadBrw,{"C5_LOJACLI" ,"@!" ,"Loja"        })
	aAdd(_aHeadBrw,{"A1_NOME"    ,"@!" ,"Nome Cliente"})
	aAdd(_aHeadBrw,{"C6_LOCALIZ" ,"@!" ,"Endereço"    })
	aAdd(_aHeadBrw,{"DAI_COD"    ,"@!" ,"Carga"       })

	If Select(_cTrbPedi) <> 0
		(_cTrbPedi)->(DBCLOSEAREA())
	EndIF

	// cria arquivo de trabalho
	_cArqTrb := FWTemporaryTable():New( _cTrbPedi )
	_cArqTrb:SetFields( _aEstTrb )
	_cArqTrb:Create()

	// busca Pedidos.
	_cQuery := " SELECT C5_NUM, "
	_cQuery += "        Z05_NUMOS, "
	_cQuery += "        C5_CLIENTE, "
	_cQuery += "        C5_LOJACLI, "
	_cQuery += "        A1_NOME, "
	_cQuery += "        C6_LOCAL, "
	_cQuery += "        C6_LOCALIZ, "
	_cQuery += "        Sum(BF_QUANT) BF_QUANT, "
	_cQuery += "        DAI_COD "
	// pedido de venda
	_cQuery += " FROM   "+RetSqlTab("SC5")+" (nolock) "
	// cad. cliente
	_cQuery += "        INNER JOIN "+RetSqlTab("SA1") + " (NOLOCK) "
	_cQuery += "                ON "+RetSqlCond("SA1")
	_cQuery += "                   AND A1_COD = C5_CLIENTE "
	_cQuery += "                   AND A1_LOJA = C5_LOJACLI "
	// itens do pedido de venda
	_cQuery += "        INNER JOIN "+RetSqlTab("SC6") + " (NOLOCK) "
	_cQuery += "                ON "+RetSqlCond("SC6")
	_cQuery += "                   AND SC5.C5_NUM = SC6.C6_NUM "
	//Pedido separado na Doca/stage
	_cQuery += "                   AND C6_LOCALIZ IN (SELECT BE_LOCALIZ "
	_cQuery += "                                      FROM   "+RetSqlTab("SBE")+" (NOLOCK) "
	_cQuery += "                                             INNER JOIN "+RetSqlTab("DC8")+" (NOLOCK) "
	_cQuery += "                                                     ON "+RetSqlCond("DC8")
	_cQuery += "                                                        AND DC8_TPESTR = '5' "
	_cQuery += "                                                        AND DC8_CODEST = BE_ESTFIS "
	_cQuery += "                                      WHERE  "+RetSqlCond("SBE")
	_cQuery += "                                             AND BE_LOCAL = C6_LOCAL) "
	// itens liberados do pedido de venda
	_cQuery += "        INNER JOIN "+RetSqlTab("SC9")+" (NOLOCK) "
	_cQuery += "                ON "+RetSqlCond("SC9")
	_cQuery += "                   AND SC5.C5_NUM = SC9.C9_PEDIDO "
	_cQuery += "                   AND SC6.C6_ITEM = SC9.C9_ITEM "
	// itens sem bloqueio de estoque
	_cQuery += "                   AND SC9.C9_BLEST = '  ' "
	// itens sem bloqueio de Credito
	_cQuery += "                   AND SC9.C9_BLCRED = '  ' "
	// itens não esta faturado.
	_cQuery += "                   AND SC9.C9_NFISCAL = '  ' "
	// saldo por endereço
	_cQuery += "        INNER JOIN " + RetSqlTab("SBF") + " (NOLOCK) "
	_cQuery += "                ON " + RetSqlCond("SBF")
	_cQuery += "                   AND C6_PRODUTO = BF_PRODUTO "
	_cQuery += "                   AND C6_LOCALIZ = BF_LOCALIZ "
	_cQuery += "                   AND C6_LOCAL = BF_LOCAL "
	//Verifica se tem saldo no local
	_cQuery += "                   AND SBF.BF_QUANT >= SC9.C9_QTDLIB "
	// ordem de serviço original de expedição
	_cQuery += "   INNER JOIN " + RetSqlTab("Z05") + " (nolock) "
	_cQuery += "              ON " + RetSqlCond("Z05")
	_cQuery += "                 AND Z05_CLIENT = SC5.C5_CLIENTE AND Z05_LOJA = SC5.C5_LOJACLI"
	_cQuery += "                 AND Z05_TPOPER = 'S'"
	_cQuery += "                 AND ((Z05_CARGA = SC5.C5_ZCARGA AND SC5.C5_ZONDSEP = '') OR (Z05_ONDSEP = SC5.C5_ZONDSEP AND SC5.C5_ZONDSEP != ''))"
	// carga
	_cQuery += "   INNER JOIN " + RetSqlTab("DAI") + " (NOLOCK) "
	_cQuery += "              ON " + RetSqlCond("DAI")
	_cQuery += "                 AND DAI_COD = SC5.C5_ZCARGA"
	// sequencias da OS
	_cQuery += " INNER JOIN " + RetSQLTab("Z06") + " (NOLOCK) "
	_cQuery += "       ON " + RetSqlCond("Z06")
	_cQuery += "       AND Z06_NUMOS = Z05.Z05_NUMOS"
	// com as sequencias que não são carregamentos já finalizadas
	_cQuery += "       AND ( ( Z06_TAREFA != '004' AND Z06_STATUS = 'FI' )                               "
	// e a tarefa de carregamento aguardando ou planejada
	_cQuery += "          OR ( Z06_TAREFA = '004' AND ( Z06_STATUS = 'AG' OR Z06_STATUS = 'PL' ) ) ) "
	// filtro padrao
	_cQuery += " WHERE  " + RetSqlCond("SC5")
	// sem nota fiscal
	_cQuery += "        AND C5_NOTA = ' ' "
	// somente pedido de produtos
	_cQuery += "        AND C5_TIPOOPE = 'P' "
	// com processo de montagem de volumes/pedido já concluído
	_cQuery += "        AND C5_ZMNTVOL = 'S' "
	// filtro de cliente, conforme já informado na abertura da tela do monitor de serviços
	_cQuery += "        AND C5_CLIENTE BETWEEN '" + mvCliDe + "' AND '" + mvCliAte + "' "
	// agrupa dados
	_cQuery += " GROUP  BY C5_NUM, "
	_cQuery += "           Z05_NUMOS, "
	_cQuery += "           C5_CLIENTE, "
	_cQuery += "           C5_LOJACLI, "
	_cQuery += "           A1_NOME, "
	_cQuery += "           C6_LOCAL, "
	_cQuery += "           C6_LOCALIZ, "
	_cQuery += "           DAI_COD "

	memowrit("c:\query\WMSA009E.txt", _cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQuery,_aEstTrb,_cTrbPedi)

	//Se resultado da consulta SQL for 0 sai do programa.
	If ((_cTrbPedi)->(RecCount())==0)
		// mensagem
		MsgStop("Não há pedidos/carregamentos aptos para serem cancelados.")
		// retorno
		Return()
	EndIf

	_oTelaDev := MSDialog():New(  092,232,592,1000,"Cancelamento de Carregamento",,,.F.,,,,,,.T.,,,.T. )

	_oPnlTop := TPanel():New(000,000,nil,_oTelaDev,,.F.,.F.,,,000,030,.T.,.F. )
	_oPnlBut := TPanel():New(000,000,nil,_oTelaDev,,.F.,.F.,,,000,030,.T.,.F. )

	_oPnlTop:Align := CONTROL_ALIGN_ALLCLIENT
	_oPnlBut:Align := CONTROL_ALIGN_BOTTOM

	// Confirma
	_oBmpOK       := TBtnBmp2():New(001,001,040,040,"OK",,,,{|| Processa({|| sfRecCarga(_cTrbPedi,_cMark,_aHeadBrw),_oTelaDev:End() } , "Cancelamento de carregamento", "Processando...", .F.)} ,_oPnlBut,"Confirmar",,.T. )

	_oBmpOK:Align := CONTROL_ALIGN_LEFT

	//Sair
	_oBmpCanc := TBtnBmp2():New(001,001,040,040,"FINAL",,,,{|| _oTelaDev:End() },_oPnlBut,"Sair",,.T. )
	_oBmpCanc:Align := CONTROL_ALIGN_RIGHT

	_oBrwPedido                  := MsSelect():New(_cTrbPedi    ,"C5_OK",  ,_aHeadBrw,@_lInverte,@_cMark,aSzBrow,,,_oPnlTop)
	_oBrwPedido:bMark            := {| | sfSeleReg(_cTrbPedi,_cMark)}
	_oBrwPedido:oBrowse:lAllMark := .T.
	_oBrwPedido:oBrowse:Align    := CONTROL_ALIGN_ALLCLIENT

	// abre o arquivo de trabalho
	dbSelectArea(_cTrbPedi)
	(_cTrbPedi)->(dbGoTop())

	// atualizacao do browse
	If (_oBrwPedido <> nil)
		_oBrwPedido:oBrowse:Gotop()
		_oBrwPedido:oBrowse:Refresh()
	EndIf

	_oTelaDev:Activate(,,,.T.)

	_cArqTrb:Delete()

Return()

// ** Marcar e desmarcar pedidos.
Static Function sfSeleReg(mvAlias,_cMark)
	Local _nReg := (mvAlias)->(Recno())

	(mvAlias)->(dbGoTop())
	While (mvAlias)->(!Eof())
		RecLock(mvAlias,.F.)
		(mvAlias)->C5_OK := ""
		(mvAlias)->(MsUnLock())
		(mvAlias)->(dbSkip())
	Enddo

	(mvAlias)->(dbGoto(_nReg))

	RecLock(mvAlias,.F.)
	(mvAlias)->C5_OK := _cMark
	(mvAlias)->(MsUnLock())
	_oBrwPedido:oBrowse:Refresh()
Return()

// ** funcao que faz o cancelamento de carregamento.
Static Function sfRecCarga(mvAlias,cMarca,_aHeadBrw)

	Local oWindow,oConfirm,oSair,oPanel1,oPanel2,oSelect, oSayAviso := nil
	Local oSize       := FwDefSize():New(.F.)
	Local _cCliFor    := (mvAlias)->C5_CLIENTE        //.. Codigo do cliente ou fornecedor
	Local _cLoja      := (mvAlias)->C5_LOJACLI        //.. numero da loja
	Local _cTipoNF    := "B"                          //.. tipo da nota //N-> Pedidos Normais.
	Local _cDoc       := (mvAlias)->C5_NUM            //.. numero do documento (pedido de venda que está sendo cancelado)
	Local _cCodArmz   := (mvAlias)->C6_LOCAL
	Local _cLocaliz   := (mvAlias)->C6_LOCALIZ
	Local _cOSCanc    := (mvAlias)->Z05_NUMOS         //OS antiga, a que está sendo cancelada
	Local _cCargaOld  := (mvAlias)->DAI_COD           //carga antiga, a que foi selecionada e está atrelada ao pedido que está sendo cancelado
	Local _cNovaOS    := CriaVar("Z05_NUMOS", .F. )   //Número da nova OS gerada durante o processamento (para processar a devolução para o estoque)

	Local _nLastro  := 0
	Local _nCamada  := 0
	Local _nAdicio  := 0

	local _lRet     := .F.
	local _lFecha   := .F.

	//variáveis para tela de escolha da programação
	Local _aRetPg   := {}
	Local _lRetPg   := .F.

	//Variaveis para controle de inclusão de registro. (Tratamento para vários pedidos)
	LOCAL lOS := .F.
	LOCAL nSZZ:=0
	LOCAL nQtPed := 0
	LOCAL nTotPed:= 0
	// seek
	Local _cSeekSC6

	LOCAL aZ04   := {}
	LOCAL nPosZ04:= 0

	PRIVATE lMsHelpAuto := .F.
	PRIVATE lMsErroAuto := .F.

	DbSelectArea("SC6")
	DbSelectArea("SC5")
	DbSelectArea("Z06")
	dbSelectArea("SZZ")
	dbSelectArea("Z04")
	DBSelectArea("Z07")
	DBSelectArea("Z43")
	SC5->(dbSetOrder(1)) // 1-C5_FILIAL, C5_NUM
	SC6->(dbSetOrder(1)) // 1- C6_FILIAL, C6_NUM, C6_ITEM, C6_PRODUTO

	//Trata o arquivo de trabalho para conter apenas a OS contemplada na seleção e seus pedidos.
	//Preparando para montar a tela de escolha parcial de pedidos a serem cancelados.
	(mvAlias)->(DBGoTop())
	Do While !(mvAlias)->(Eof())
		If (_cOSCanc != (mvAlias)->Z05_NUMOS)
			RecLock(mvAlias, .F.)
			(mvAlias)->(DBDelete())
			MSUnLock()
		Else
			nTotPed++
			nQtPed:= nTotPed    //Contador do total de pedidos na OS
		EndIf
		(mvAlias)->(DBSkip())
	EndDo

	//Tela de seleção dos pedidos a serem cancelados na OS.
	If (nTotPed > 1)
		nQtPed := 0//Contador da quantidade de pedidos selecionados para cancelamento.
		(mvAlias)->(DBGoTop())
		oWindow := MSDialog():New(oSize:aWindSize[1],oSize:aWindSize[2],oSize:aWindSize[3],oSize:aWindSize[4],OemToAnsi("Seleção de Pedidos."),,,.F.,,,,,,.T.,,,.T. )
		oWindow:lMaximized := .T.

		oPanel1 := TPanel():New(005,050,,oWindow,_oFnt04,.F.,.F.,,,26,26,.T.,.F. )
		oPanel1:Align := CONTROL_ALIGN_TOP

		oConfirm := TButton():New(010,005,"CONFIRMAR",oPanel1,{|| oWindow:End()  },050,100,,,,.T.,,"",,,,.F. )
		oConfirm:Align := CONTROL_ALIGN_LEFT
		oSayAviso := TSay():New(020,035,{|| "A OS : "+(mvAlias)->Z05_NUMOS+" possui múltiplos pedidos. Selecione os pedidos que deseja cancelar. ATENÇÃO: só é possível executar UMA vez o cancelamento!" },oPanel1,,_oFnt04,.F.,.F.,.F.,.T.,CLR_RED)
		oSayAviso:Align := CONTROL_ALIGN_LEFT
		oSair := TButton():New(010,005,"CANCELAR",oPanel1,{|| _lFecha:= .T. , oWindow:End()  },050,100,,,,.T.,,"",,,,.F. )
		oSair:Align := CONTROL_ALIGN_RIGHT

		oPanel2 := TPanel():New(000,000,"",oWindow,,.F.,.F.,,,120,250,.T.,.F. )
		oPanel2:Align := CONTROL_ALIGN_TOP

		oSelect := MsSelect():New((mvAlias),"C5_OK",,_aHeadBrw,,cMarca,{000,000,2000,2000},,,oPanel2,,{/*legenda*/})
		oSelect:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
		oWindow:lCentered := .T.
		oWindow:Activate()

		//Calcula quantos pedidos foram selecionados.
		if (_lFecha)
			Return( _lRet )
		Else
			DBSelectArea(mvAlias)
			DBGoTop()
			DbEval({ || Iif((C5_OK == cMarca), nQtPed++,NIL)  })
		EndIf
	EndIf

	// se a OS selecionada possui mais de um pedido e nenhum foi selecionado
	If (nQtPed == 0 .AND. nTotPed > 1)
		MsgStop("Nenhum pedido selecionado para cancelamento. Processo abortado.","TWMSA009 - Cancelamento de carregamento")
		Return( _lRet )
	EndIf

	//1ª confirmação, para prevenir cancelamento acidental
	IF ( !MsgYesNo("Tem certeza que deseja cancelar *DEFINITIVAMENTE* o carregamento do pedido de venda " + _cDoc + "?" + CRLF + CRLF + "Esta operação é IRREVERSÍVEL!", "TWMSA009 - sfRecCarga") )
		Return( _lRet )
	EndIf

	//2ª confirmação, pede senha de usuario fodão
	If ( !StaticCall(TWMSA010, sfVldUser, "G|A") )
		MsgAlert("É necessária senha de gerente/account para cancelar o(s) pedido(s)!","Sem permissão")
		Return( _lRet )
	EndIf

	//3ª confirmação, captcha
	_nCaptcha := Randomize(1,32766)
	_cCaptcha := "Insira o número validador " + Str(_nCaptcha)

	If ( _nCaptcha != Val(FWInputBox(_cCaptcha,"")) )
		MsgAlert("Falha na verificação do CAPTCHA. Repita a operação e informe o número corretamente","Erro na validação do CAPTCHA")
		Return( _lRet )
	EndIf

	//passou nas validações, inicia processamento da rotina
	ProcRegua(7)

	// inicia transacao
	BEGIN TRANSACTION

		// abre a tela com a lista de programacoes
		_aRetPg := U_FtLstPrg(_cCliFor, _cLoja)
		_lRetPg := _aRetPg[1]

		//se não escolheu ou cancelou a programação
		If (!_lRetPg)
			MsgStop("É necessário indicar uma programação para receber a devolução/cancelamento.")
			_lRet := .F.
			DisarmTransaction()
			Break
		EndIf

		//Tratamento para contemplar o cancelamento de OS com vários pedidos relacionados.
		lOS := .F.
		(mvAlias)->(DBGoTop())
		Do While !(mvAlias)->(Eof())
			If _cOSCanc == (mvAlias)->Z05_NUMOS .And. (mvAlias)->C5_OK==cMarca
				_cDoc       := (mvAlias)->C5_NUM
				_cCliFor    := (mvAlias)->C5_CLIENTE
				_cLoja      := (mvAlias)->C5_LOJACLI
				_cOSCanc    := (mvAlias)->Z05_NUMOS
				_cCargaOld  := (mvAlias)->DAI_COD

				//Posiciona no item do pedido para buscar o local e a localização.
				If SC6->(dbSeek( _cSeekSC6 := xFilial("SC6") + _cDoc ))
					// atualiza armazem e endereco de servico
					_cCodArmz := SC6->C6_LOCAL
					_cLocaliz := SC6->C6_LOCALIZ

					If Empty(nSZZ)
						// 1ª etapa - Gera novo CESV para o recebimento (re-entrada)
						IncProc("Gerando novo CESV...")
						RecLock("SZZ", .T. )
						SZZ->ZZ_FILIAL	:= xFilial("SZZ")
						SZZ->ZZ_CESV	:= GetSxeNum("SZZ","ZZ_CESV", xFilial("SZZ"))
						SZZ->ZZ_DTCHEG	:= Date()
						SZZ->ZZ_HRCHEG	:= Left(Time(),5)
						SZZ->ZZ_DTENT	:= Date()
						SZZ->ZZ_HRENT	:= Left(Time(),5)
						SZZ->ZZ_CLIENTE	:= _cCliFor
						SZZ->ZZ_LOJA	:= _cLoja
						SZZ->ZZ_STATUS	:= "06" // 06-EM PLANEJAMENTO
						SZZ->ZZ_TRANSP	:= ""	//_cCodTransp
						SZZ->ZZ_MOTORIS	:= ""	//_cCodMotor
						SZZ->ZZ_PLACA1	:= ""	//_cPlaca1
						SZZ->ZZ_PLACA2	:= ""	//_cPlaca2
						SZZ->ZZ_OBS		:= "Cancelamento de Carregamento - Ref OS: " + _cOSCanc +" / Pedido Tecadi: " + _cDoc
						SZZ->ZZ_USRINC	:= __cUserId
						SZZ->ZZ_CNTR01	:= ""
						SZZ->ZZ_CNTR02	:= ""
						SZZ->ZZ_OPERACA	:= "05" // 05-Devolução de mercadoria.
						SZZ->ZZ_LOCAL   := _cCodArmz
						SZZ->ZZ_DOCA    := _cLocaliz
						SZZ->ZZ_PROCES  := _aRetPg[2]   //programação escolhida na janela anterior
						SZZ->ZZ_OPWMS   := "S"
						SZZ->ZZ_TIPO    := "04"         //04 - cancelamento de carregamento/pedido
						SZZ->(MsUnLock())
						nSZZ := SZZ->(Recno())
						// confirma a sequencia
						ConfirmSx8()
					Else
						SZZ->(DBGoTo(nSZZ))
						RecLock("SZZ",.F.)
						SZZ->ZZ_OBS := AllTrim(SZZ->ZZ_OBS)+","+_cDoc
						SZZ->(MsUnLock())
					EndIf

					//2ª etapa - Gera automaticamente tabela Z04 com base nos itens do pedido de venda original, para confrontar a nova conferência
					IncProc("Gerando vínculo do novo CESV para etapa de conferência...")

					// varre todos os itens do pedido de venda
					While SC6->( ! Eof() ) .And. (SC6->(C6_FILIAL + C6_NUM) == _cSeekSC6)

						// zera variaveis
						_nLastro := _nCamada := _nAdicio := 0

						// funcao que retorna lastro e camada do produto
						U_FtWmsNorma(SC6->C6_PRODUTO, SC6->C6_LOCAL, @_nLastro, @_nCamada, @_nAdicio, Nil, SC6->C6_IDENTB6)

						//Agrupa a gravação da Z04 por Produto+Local+Lote. (Redmine #498)
						If (nPosZ04 := aScan(aZ04,{|x| x[10] == SC6->C6_PRODUTO .And. x[11] == SC6->C6_LOCAL .And. x[17] == SC6->C6_LOTECTL }) ) == 0

							aAdd(aZ04,{xFilial("Z04"),;//01 - Z04_FILIAL
							SZZ->ZZ_CESV,;//02 - Z04_CESV
							SZZ->ZZ_CLIENTE,;//03 - Z04_CLIENT
							SZZ->ZZ_LOJA,;//04 - Z04_LOJA
							"B",;//05 - Z04_TIPONF
							_cDoc,;//06 - Z04_NF
							"DV1",;//07 - Z04_SERIE
							Str(Len(aZ04)+1),;//08 - Z04_ITEMNF -- pega o valor atual do array e soma um (sendo inserido)
							"",;//09 - Z04_NUMSEQ
							SC6->C6_PRODUTO,;//10 - Z04_PROD
							SC6->C6_LOCAL,;//11 - Z04_LOCAL
							SC6->C6_QTDVEN,;//12 - Z04_QUANT
							SZZ->ZZ_PROCES,;//13 - Z04_PROCES
							_nLastro,;//14 - Z04_LASTRO
							_nCamada,;//15 - Z04_CAMADA
							_nAdicio,;//16 - Z04_ADICIO
							SC6->C6_LOTECTL,;//17 - Z04_LOTCTL
							SC6->C6_UNSVEN})//18 - Z04_QTSEGU
						Else
							aZ04[nPosZ04][12] += SC6->C6_QTDVEN
							aZ04[nPosZ04][18] += SC6->C6_UNSVEN
						EndIf

						// posiciona no pedido de venda original (cancelado)
						SC5->(dbSeek( xFilial("SC5") + _cDoc ))

						// e então executa funcao customizada para eliminacao de residuos
						IF (! U_FtFatRes( .T. ) )
							//se deu erro
							DisarmTransaction()
							MsgStop("Erro ao realizar o estorno da liberação do pedido : " + _cDoc )
							_lRet := .F.
							Break
						EndIf

						// funcao padrao da TOTVS para atualizar status do pedido
						SC6->(MaLiberOk({SC5->C5_NUM},.T.))

						// proximo item do pedido
						SC6->(dbSkip())
					EndDo
				Else
					//se deu erro
					DisarmTransaction()
					MsgStop("Erro ao gerar vinculo do CESV de entrada")
					_lRet := .F.
					Break
				EndIF

				//3ª etapa - limpa etiquetas da OS original com base no pedido
				IncProc("Limpando etiquetas (zerando saldo) da OS original...")

				Z07->(DbSetOrder(1))   //Z07_FILIAL, Z07_NUMOS, Z07_SEQOS, R_E_C_N_O_, D_E_L_E_T_
				If (! Z07->( DBSeek(xFilial("Z07") + _cOSCanc  )) )
					//se não achou a conferência da OS cancelada, aborta o processo
					DisarmTransaction()
					MsgStop("Processo abortado: erro ao realizar a limpeza das etiquetas da OS : " + _cOSCanc ,"Erro TWMSA009 - sfRecCarga - ETQ 01")
					_lRet := .F.
					Break
				Else                    //achou a OS
					// zera saldo das etiquetas utilizadas na conferencia/montagem do pedido
					_cQryZ16 := "UPDATE " + RetSqlName("Z16") + " SET Z16_SALDO = 0 WHERE Z16_FILIAL = " + xFilial("Z16") + " AND D_E_L_E_T_ = '' AND Z16_PEDIDO = '" + _cDoc + "' "

					//executa update
					_nStsSQL := TcSQLExec(_cQryZ16)

					//se deu erro
					if (_nStsSQL < 0)
						// grava log do sql para debug
						DisarmTransaction()
						MsgStop("Processo abortado: erro ao realizar a limpeza das etiquetas da OS : " + _cOSCanc ,"Erro TWMSA009 - sfRecCarga - ETQ 02")
						MemoWrit("c:\query\TWMSA009_sfRecCarga_cQryZ16.txt", _cQryZ16)
						_lRet := .F.
						Break
					EndIf
				EndIF

				//4ª etapa - Limpa vínculo CESV antigo com pedido cancelado
				IncProc("Limpando vínculo pedido/CESV anterior...")

				Z43->( DbSetOrder(3) )   //Z43_FILIAL, Z43_NUMOS, Z43_CARGA, Z43_PEDIDO, Z43_CESV, R_E_C_N_O_, D_E_L_E_T_
				//se chegou a gerar vínculo
				If ( Z43->(DbSeek(xFilial("Z43") + _cOSCanc + _cCargaOld + _cDoc)) )
					// marca como cancelado
					RecLock("Z43",.F.)
					Z43->Z43_STATUS := "C"
					Z43->(MsUnLock())
				EndIf
			EndIf
			(mvAlias)->(DBSkip())
		EndDo

		// 5ª etapa - cria vinculo do CESV com nota fiscal de entrada (neste caso, cancelamento de pedido/carregamento)
		For nFor:= 1 To Len(aZ04)
			RecLock("Z04",.T.)
			Z04->Z04_FILIAL  := aZ04[nFor][01]
			Z04->Z04_CESV    := aZ04[nFor][02]
			Z04->Z04_CLIENT  := aZ04[nFor][03]
			Z04->Z04_LOJA    := aZ04[nFor][04]
			Z04->Z04_TIPONF  := aZ04[nFor][05]
			Z04->Z04_NF      := aZ04[nFor][06]                  //pedido de venda que foi cancelado
			Z04->Z04_SERIE   := aZ04[nFor][07]
			Z04->Z04_ITEMNF  := aZ04[nFor][08]
			Z04->Z04_NUMSEQ  := aZ04[nFor][09]
			Z04->Z04_PROD    := aZ04[nFor][10]
			Z04->Z04_LOCAL   := aZ04[nFor][11]
			Z04->Z04_QUANT   := aZ04[nFor][12]
			Z04->Z04_PROCES  := aZ04[nFor][13]
			Z04->Z04_LASTRO  := aZ04[nFor][14]
			Z04->Z04_CAMADA  := aZ04[nFor][15]
			Z04->Z04_ADICIO  := aZ04[nFor][16]
			Z04->Z04_LOTCTL  := aZ04[nFor][17]
			Z04->Z04_QTSEGU  := aZ04[nFor][18]
			Z04->(MsUnLock())
		Next

		//6ª etapa - gera a nova ordem de servico
		IncProc("Gerando nova ordem de serviço...")

		IF (!lOS .And. ! (lOS:=U_WMSA009B(SZZ->ZZ_CESV, "01", Nil, _cLocaliz, Nil, .T., "T03", _cCliFor, _cLoja, .F. , SZZ->ZZ_OBS, _cOSCanc )) )
			//se deu erro
			DisarmTransaction()
			_lRet := .F.
			Break
		Endif

		//guarda nova OS gerada
		If Empty(_cNovaOS)
			_cNovaOS := Z05->Z05_NUMOS
		EndIF

		//7ª etapa - efetua os procedimentos de cancelamento da OS original
		IncProc("Encerrando OS anterior e limpando etiquetas originais...")

		If nSZZ >0 //Valida se operações anteriores foram executadas.
			If nQtPed == nTotPed//Somente cancela a OS se houve a seleção de todos os pedidos da OS.
				Z06->(dbSetOrder(1) )  // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
				Z06->(DBSeek(xFilial("Z06") + _cOSCanc))
				// varre todos os itens da ordem de servico e finaliza os mesmos
				While  Z06->( ! Eof() ) .And. (Z06->(Z06_FILIAL + Z06_NUMOS) == xFilial("Z06") + _cOSCanc )
					// atualiza o status de cada sequencia da OS original (a que foi cancelada)
					U_FtWmsSta(Z06->Z06_STATUS, "CA", Z06->Z06_NUMOS, Z06->Z06_SEQOS)

					//proxima sequencia da OS
					Z06->(dbSkip())
				EndDo
			EndIf
		Else
			DisarmTransaction()
			MsgStop("Processo abortado: Erro ao executar o cancelamento da OS " + _cOSCanc ,"Erro TWMSA009 - sfRecCarga - ETQ 01")
			_lRet := .F.
			Break
		EndIf
		//se tudo deu certo, gera log da operação de cancelamento
		U_FtGeraLog(cFilAnt,;
		"Z06",;
		xFilial("Z06") + _cOSCanc,;
		"OS " + _cOSCanc + " encerrada através do processo de cancelamento de carregamento (v3). Nova OS: " + _cNovaOS,;
		"WMS")

		// seta retorno como sucesso
		_lRet := .T.

	END TRANSACTION

	If (_lRet)
		// mensagem de sucesso
		MsgInfo("Cancelamento do pedido " + _cDoc + " concluído com sucesso!" + CRLF + "Nova OS gerada:" + _cNovaOS,;
		"sfRecCarga - Cancelamento de carregamento (pedido)")
	Endif

Return( _lRet )

// ** funcao que faz o complemento de uma TFAA.
User Function WMSA009F(mvCESV)
	local _aCpoEnch := {}
	Local _nOpcG    := 4
	Local _cSeekZ42
	Local _nLin      := 0

	Private _aHeader  := {}
	Private _aCols    := {}
	Private _aSizeDlg := MsAdvSize()

	// campos que permite alteracao
	private _aAlterEnch := {}
	private	_nPosPRO
	private	_nPosOBS
	private	_nPosAVA
	private	_nPosITE

	// Campos que irão para o Cabeçalho
	aadd(_aCpoEnch,"NOUSER" )
	aadd(_aCpoEnch,"Z41_CODIGO" )
	aadd(_aCpoEnch,"Z41_DTEMIS")
	aadd(_aCpoEnch,"Z41_HREMIS")
	aadd(_aCpoEnch,"Z41_USREMI")
	aadd(_aCpoEnch,"Z41_NUMOS")
	aadd(_aCpoEnch,"Z41_CESV")

	// campos que podem ser alterados
	_aAlterEnch     := aclone(_aCpoEnch)

	dbSelectArea("Z05")
	Z05->(dbOrderNickName("Z05_CESV"))
	If Z05->(dbSeek( xFilial("Z05") + mvCESV ))

		dbSelectArea("Z41")
		Z41->(dbsetorder(1))//Z41_FILIAL+Z41_CODIGO
		If Z41->(dbSeek( xFilial("Z41") + Z05->Z05_TFAA ))

			dbSelectArea("Z42")
			Z42->(dbsetorder(1))//Z42_FILIAL+Z42_CODIGO+Z42_ITEM
			Z42->(dbSeek(_cSeekZ42 := xFilial("Z42") + Z05->Z05_TFAA ))

			// atualiza variaveis da memoria
			Regtomemory("Z41",.F.)
			_nOpcG := GD_UPDATE

			// cria tela principal
			_oTela            := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Complemento de TFAA.",,,.F.,,,,,,.T.,,,.T. )
			_oTela:bInit      := {||EnchoiceBar(_oTela,{|| sfProcessa() },{||(_oTela:End())},.F.,{})}
			_oPanelTop        := TPanel():New( 016,008,"",_oTela,,.F.,.F.,,,280,060,.T.,.F. )
			_oPanelCen        := TPanel():New( 080,008,"",_oTela,,.F.,.F.,,,280,104,.T.,.F. )
			_oPanelTop:Align  := CONTROL_ALIGN_TOP
			_oPanelCen:Align  := CONTROL_ALIGN_ALLCLIENT

			//Criar o vetor aHeader, que é o vetor que tem as caracteristicas para os campos da Getdados
			_aHeader :={}
			Aadd(_aHeader,{"Item TFAA","Z42_ITEM","@!",3,0,"","","C","",""})
			Aadd(_aHeader,{"Produto","Z42_PROD","@!",30,0,"","","C","",""})
			Aadd(_aHeader,{"Observacao","Z42_OBS","@!",120,0,"","","C","",""})
			Aadd(_aHeader,{"Cod Avaria","Z42_CODAVA","@!",3,0,"","","C","",""})

			//Verifica posição dos campos na Grid
			_nPosITE := GDFIELDPOS("Z42_ITEM"   , _aHeader )
			_nPosPRO := GDFIELDPOS("Z42_PROD"   , _aHeader )
			_nPosOBS := GDFIELDPOS("Z42_OBS"    , _aHeader )
			_nPosAVA := GDFIELDPOS("Z42_CODAVA" , _aHeader )

			// cria enchoice (cabecalho)
			_oEnchoice := MsMGet():New("Z41",,2,,,,_aCpoEnch,{0,0,0,0}  ,_aAlterEnch,,,,,_oPanelTop,,.T.)
			_oEnchoice:oBox:Align := CONTROL_ALIGN_ALLCLIENT

			// cria browse
			_oGetDados := MsNewGetDados():New(1,1,1,1,_nOpcG,,,,,0,99,,,,_oPanelCen,_aHeader,_aCols )
			_oGetDados:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

			//Popular Grid com os produtos do TFAA.
			While Z42->(!Eof()) .And. ((Z42->Z42_FILIAL + Z42->Z42_CODIGO) == _cSeekZ42 )

				// incremento da linha de controle
				_nLin++

				// cria nova linha no vetor
				Aadd(_aCols,Array(Len(_aHeader)+1))
				// atualiza os dados do novo registro
				_aCols[_nLin][_nPosITE]        := Z42->Z42_ITEM
				_aCols[_nLin][_nPosPRO]        := Z42->Z42_PROD
				_aCols[_nLin][_nPosOBS]        := Z42->Z42_OBS
				_aCols[_nLin][_nPosAVA]        := Z42->Z42_CODAVA
				_aCols[_nLin][Len(_aHeader)+1] := .F.

				// proximo produto
				Z42->(dbSkip())
			EndDo

			// atualizar dados no Browse
			_oGetDados:SetArray(_aCols ,.T. )
			_oGetDados:ForceRefresh()
			_oGetDados:GoTop()

			// ativa a tela
			_oTela:Activate(,,,.T.)
		EndIf
	EndIf

Return()

// ** Função para gravar na Base de dados Tabela Z42 WMS - TFAA (ITENS)
Static Function sfProcessa()

	Local _i         := 0

	Begin Transaction

		For _i := 1 To Len(_oGetDados:Acols)
			// pesquisa pelo kit/agrupadora
			If (Z42->(dbseek(xFilial("Z42") + Z05->Z05_TFAA + _oGetDados:Acols[_i,_nPosITE])))
				RecLock("Z42",.F.)
				// atualiza campos
				Z42->Z42_OBS      := _oGetDados:Acols[_i,_nPosOBS]
				Z42->Z42_CODAVA   := _oGetDados:Acols[_i,_nPosAVA]
				Z29->(msUnLock())
			EndIf
		Next _i
		// fecha a tela
		_oTela:End()

	End Transaction
	Alert("Dados Atualizados! ")
Return()

// ** função para geração da OS de abastecimento de picking
User Function WMSA009G(mvScheduler)

	// variavel de controle de transação
	local _lRet := .F.
	// query para consulta dos dados na tabela
	local _cQuery := ""
	// grupo de perguntas
	local _cPerg := PadR("WMSA009G", 10)
	// lista de pergunta (parametros)
	Local _vPerg := {}

	// valor padrao
	Default mvScheduler := .F.

	// lista de perguntas (parametros)
	aAdd(_vPerg,{"Cliente"     ,"C",TamSX3("A1_COD")[1],0,"G",,"SA1"})
	aAdd(_vPerg,{"Loja"        ,"C",TamSX3("A1_LOJA")[1],0,"G",,"SA1"})
	aAdd(_vPerg,{"Rua De?"     ,"C",2,0,"G",,""})
	aAdd(_vPerg,{"Rua Até?"    ,"C",2,0,"G",,""})
	aAdd(_vPerg,{"Lado:"       ,"N",1,0,"C",{"Ambos","A","B"},,})
	aAdd(_vPerg,{"Prédio De?"  ,"C",2,0,"G",,""})
	aAdd(_vPerg,{"Prédio Até?" ,"C",2,0,"G",,""})
	aAdd(_vPerg,{"Produto De?" ,"C",TamSX3("BF_PRODUTO")[1],0,"G",,"SB1"})
	aAdd(_vPerg,{"Produto Até?","C",TamSX3("BF_PRODUTO")[1],0,"G",,"SB1"})

	// cria grupo de perguntas
	U_FtCriaSX1( _cPerg,_vPerg )

	// chama tela com parametros
	If ( ! mvScheduler )
		// apresenta perguntas na tela
		If ( ! Pergunte(_cPerg,.T.) )
			Return
		EndIf
	EndIf

	// chama a função que filtra os dados
	Processa({ || sfRetEndPicking(mv_par01, mv_par02 ,mv_par03 ,mv_par04 ,mv_par05 ,mv_par06 ,mv_par07 ,mv_par08, mv_par09, mvScheduler) },"Analisando informações...",,.T.)

Return (.T.)

// ** função que retorna os endereços que precisam de abastecimento
Static Function sfRetEndPicking(mvCli, mvLj, mvRuaDe, mvRuaAte, mvLado, mvPredioDe, mvPredioAte, mvProdDe, mvProdAte, mvScheduler)

	// variavel que receberá a query de análise
	local _cQryPicking := ""
	local _cQryPulmao:= ""
	// variavel de controle de transação
	local _lRet := .T.
	// array que vai receber os endereços que precisam ser reabastecidos
	local _aEndPicking := {}
	// array que vai receber os endereços com mercadoria para reabastecer os demais
	local _aEndPulmao  := {}
	// variavel temporária para preencher a variavel acima
	local _aEndAux     := {}
	local _nPick := 0
	// controle do for
	local _nX,_nPul := 0
	// variavel auxiliar para endereço de destino
	local _cEndPrd  := ""
	// variavel pra controle de endereços repetidos
	local _nPrdSldZero := 0
	// variavel de log
	local cMsgInfo := ""

	// enderecos selecionados apra geracao da ordem de servico (RotAuto)
	local _aAutEndSel := {}

	// cliente e loja
	private _cCodCli := mvCli
	private _cLjCli  := mvLj

	// busca o armazem da operação
	private _cArmzOpe := U_FtWmsParam("WMS_ARMAZEM_POR_CLIENTE","C","02",.f.,Nil, mvCli, mvLj, Nil, Nil)

	// parametro para verificar se o abastecimento de picking será somente transferindo pallet cheio
	private _lPickComp := U_FtWmsParam("WMS_PICKING_PALLET_COMPLETO_POR_CLIENTE", "L", .f., .f., Nil, mvCli, mvLj, Nil, Nil)

	// se for agendamento, prepara mensagem do email
	If (mvScheduler)

		// mensagens no console
		cMsgInfo := "Cliente    : " + mv_par01 + "/" + mv_par02 + " - " + AllTrim(Posicione("SA1", 1, xFilial("SA1") + mv_par01 + mv_par02, "A1_NOME"))+CRLF
		cMsgInfo += "Rua(s)     : De " + mv_par03 + " a " + mv_par04+CRLF
		cMsgInfo += "Lado       : " + IIf(mv_par05 == 1, "A", IIf(mv_par05 == 2, "B", "Ambos"))+CRLF
		cMsgInfo += "Prédio(s)  : De " + mv_par06 + " a " + mv_par07+CRLF
		cMsgInfo += "Produto De : " + mv_par08+CRLF
		cMsgInfo += "Produto Até: " + mv_par09

		FWLogMsg('INFO',, 'SIGAWMS', FunName(), '', '01',cMsgInfo , 0, 0, {})

	EndIf

	// consulto os endereços baseado nas informações repassadas
	_cQryPicking := " SELECT DISTINCT 'LBOK' IT_OK, PRODUTO, "
	_cQryPicking += " ENDERECO, "
	_cQryPicking += " ESTATUAL, "
	_cQryPicking += " ESTMIN,  "
	_cQryPicking += " ESTMAX, "
	_cQryPicking += " '' ENDPULMAO, "
	_cQryPicking += " 0 QTDPULMAO, "
	_cQryPicking += " '' PLTPULMAO, LOCAL,
	_cQryPicking += " (ESTMAX - ESTATUAL) DIF, '.F.' IT_DEL "
	_cQryPicking += " FROM ( "

	/*Query Auxiliar*/
	_cQryPicking += " SELECT BE_LOCALIZ ENDERECO, "
	_cQryPicking += " BE_ZESTMIN ESTMIN, "
	_cQryPicking += " BE_ZESTMAX ESTMAX, "
	_cQryPicking += " ISNULL(BF_QUANT,0) ESTATUAL, "
	_cQryPicking += " BE_CODPRO PRODUTO, BE_LOCAL LOCAL "

	// cad. enderecos
	_cQryPicking += " FROM " + RetSqlTab("SBE") + " (NOLOCK)"

	/* Estoque Atual */
	_cQryPicking += " LEFT JOIN " + RetSqlTab("SBF") + " (NOLOCK)"
	_cQryPicking += " ON BF_LOCAL = BE_LOCAL AND BF_LOCALIZ = BE_LOCALIZ AND BF_ESTFIS = BE_ESTFIS"
	_cQryPicking += " AND " + RetSqlCond("SBF")

	/*Cadastro de Clientes*/
	_cQryPicking += " INNER JOIN " + RetSqlTab("SA1") + " (NOLOCK)"
	_cQryPicking += " ON A1_COD = '"+mvCli+"' AND A1_LOJA = '"+mvLj+"' "
	_cQryPicking += " AND " + RetSqlCond("SA1")
	_cQryPicking += " AND A1_SIGlA = SUBSTRING(BE_CODPRO, 1,4) "

	// filtro padrao cad. enderecos
	_cQryPicking += " WHERE " + RetSqlCond("SBE")
	// endereço não pode estar bloqueado
	_cQryPicking += " AND BE_STATUS != '3' "
	// somente com codigo de produto definido
	_cQryPicking += " AND BE_CODPRO != '' "
	//armazém padrão
	_cQryPicking += " AND BE_LOCAL = '" + _cArmzOpe + "' "
	// validação do cliente X endereço
	_cQryPicking += " AND BE_ZCODCLI = '" + mvCli + "' "
	// somente enderecos varios, ou que o estoque seja o mesmo da configuracao
	_cQryPicking += " AND ( ( BE_CODPRO = BF_PRODUTO ) OR BF_PRODUTO IS NULL ) "
	// somente 2-Picking
	_cQryPicking += " AND BE_ESTFIS IN "
	/* Valida se existe o tipo de estrutura PICKING */
	_cQryPicking += " (SELECT DC8_CODEST FROM " + RetSqlName("DC8")+" DC8 (NOLOCK)"
	_cQryPicking += " WHERE " + RetSqlCond("DC8")+" "
	_cQryPicking += " AND DC8_TPESTR = '2')) ENDE "

	/*Somente registros que entrarem na condição abaixo serão mostrados*/

	// valida para incluir somente pallets completos para abastecer
	If ( _lPickComp )
		_cQryPicking += " WHERE ESTATUAL = 0 "
	Else
		_cQryPicking += " WHERE ESTATUAL <= ESTMIN "
	EndIf

	// somente endereços com estoque maximo definido
	_cQryPicking += " AND ESTMAX > 0 "

	/*Buscas por produtos específicos*/
	_cQryPicking += " AND PRODUTO BETWEEN '"+mvProdDe+"' AND '"+mvProdAte+"' "
	/*Buscas por ruas específicas*/
	_cQryPicking += " AND SUBSTRING(ENDERECO,1,2) BETWEEN '"+mvRuaDe+"' AND '"+mvRuaAte+"' "

	// se o lado foi preenchido, pesquisa pela lado também
	If (mvLado != 1)
		_cQryPicking += " AND SUBSTRING(ENDERECO,3,1) = '"+IIF(mvLado==2, "A", "B")+"' "
	EndIf

	/*Buscas por predios específicos*/
	_cQryPicking += " AND SUBSTRING(ENDERECO,4,2) BETWEEN '"+mvPredioDe+"' AND '"+mvPredioAte+"' "

	// não pode haver OS em aberto para aquele endereço de origem
	_cQryPicking += " AND NOT EXISTS (SELECT * FROM " + RetSqlTab("Z08") + " (NOLOCK) WHERE " + RetSqlCond("Z08") + " AND Z08_LOCAL = LOCAL AND Z08_ENDORI = ENDERECO AND Z08_STATUS <> 'R') "

	// não pode haver OS em aberto para aquele endereço de destino
	_cQryPicking += " AND NOT EXISTS (SELECT * FROM " + RetSqlTab("Z08") + " (NOLOCK) WHERE " + RetSqlCond("Z08") + " AND Z08_LOCAL = LOCAL AND Z08_ENDDES = ENDERECO AND Z08_STATUS <> 'R') "

	// endereço não pode estar sob inventario
	_cQryPicking += " AND ENDERECO NOT IN (SELECT Z21_LOCALI FROM " + RetSqlTab("Z21") + " (NOLOCK) WHERE " + RetSqlCond("Z21") + " AND Z21_LOCAL = LOCAL AND Z21_IDENT IN (SELECT Z06_NUMOS FROM " + RetSqlTab("Z06") + " (NOLOCK) WHERE Z06_FILIAL = Z21_FILIAL AND Z06_NUMOS = Z21_IDENT AND D_E_L_E_T_ = '' AND Z06_STATUS NOT IN ('FI','CA'))) "

	memowrit("C:\query\wmsa009g_query_01.txt",_cQryPicking)

	// jogo os endereços no array
	_aEndPicking := U_SqlToVet(_cQryPicking)

	// valido se o array possui registros
	If (_lRet) .And. (len(_aEndPicking) <= 0)
		If ( ! mvScheduler )
			// mensagem
			Help( Nil, Nil, 'Abastecimento de Picking', Nil, "Não foram encontrados endereços-picking com os parâmetros informados. Verifique os parâmetros e tente novamente!", 1, 0 )
		Else

			// mensagem de log no console
			FWLogMsg('INFO',, 'SIGAWMS', FunName(), '', '01',"Não foram encontrados endereços-picking com os parâmetros informados" , 0, 0, {})

		EndIf
		// variavel de controle
		_lRet := .F.
	EndIf

	// continua o processo se encontrou dados/endereços/pallets para reabastecer o picking
	If (_lRet)
		// varro todo o array pra realizar as movimentações necessárias
		For _nPick := 1 to Len(_aEndPicking)

			// vou pegar todos os endereços com saldo para comparação
			_cQryPulmao := " SELECT ISNULL(SUM(Z16_SALDO),0) Z16_SALDO, Z16_CODPRO, Z16_ETQPAL, Z16_ENDATU "
			_cQryPulmao += " FROM " + RetSqlTab("Z16") + " (nolock) "

			// valida se endereço existe, não está bloqueado e é de estrutura porta pallet (pulmão)
			_cQryPulmao += " INNER JOIN " + RetSqlTab("SBE") + " (NOLOCK) "
			_cQryPulmao += "               ON " + RetSqlCond("SBE")
			_cQryPulmao += "                  AND BE_LOCAL = Z16_LOCAL                       "
			_cQryPulmao += "                  AND BE_LOCALIZ = Z16_ENDATU                    "
			_cQryPulmao += "                  AND BE_STATUS = 2                              "
			_cQryPulmao += "                  AND BE_ESTFIS IN (SELECT DC8_CODEST            "
			_cQryPulmao += "                        FROM   " + RetSqlTab("DC8") + " (NOLOCK) "
			_cQryPulmao += "                                    WHERE " + RetSqlCond("DC8")
			_cQryPulmao += "                                    AND DC8_TPESTR = '1')        "
			_cQryPulmao += "			                                                     "
			_cQryPulmao += " WHERE " + RetSqlCond("Z16")

			// produto a ser pesquisa
			_cQryPulmao += " AND Z16_CODPRO = '" + _aEndPicking[_nPick][2] + "' "

			// aramzém padrão
			_cQryPulmao += " AND Z16_LOCAL = '" + _cArmzOpe + "' "

			// desconsidera os endereços abaixo
			_cQryPulmao += " AND SUBSTRING(Z16_ENDATU,6,2) > '01' "
			_cQryPulmao += " AND SUBSTRING(Z16_ENDATU,1,5)  != ('STAGE') "
			_cQryPulmao += " AND SUBSTRING(Z16_ENDATU,1,10) != ('RETRABALHO') "
			_cQryPulmao += " AND SUBSTRING(Z16_ENDATU,1,6)  != ('PORTAO') "
			_cQryPulmao += " AND SUBSTRING(Z16_ENDATU,1,5)  != ('BLOCO') "
			_cQryPulmao += " AND SUBSTRING(Z16_ENDATU,1,5)  != ('QUADRA') "
			_cQryPulmao += " AND SUBSTRING(Z16_ENDATU,1,4)  != ('DOCA') "
			_cQryPulmao += " AND Z16_SALDO > 0 "

			// valida para incluir somente pallets completos para abastecer
			If ( _lPickComp )
				_cQryPulmao += " AND Z16_SALDO <= " +  CVALTOCHAR( _aEndPicking[_nPick][6] ) + " "
			EndIf

			// tipo de estoque disponível
			_cQryPulmao += " AND Z16_TPESTO IN ('', '000001') "
			// armazém
			_cQryPulmao += " AND Z16_LOCAL = '" + _cArmzOpe + "' "
			// somente pallet com 1 SKU
			_cQryPulmao += "    AND (SELECT COUNT(DISTINCT Z16_CODPRO) "
			_cQryPulmao += "         FROM  " + RetSqlName("Z16") + " QTDPRD WITH (NOLOCK, INDEX (Z16010_ENDATU) ) "
			_cQryPulmao += "         WHERE  QTDPRD.Z16_FILIAL = Z16.Z16_FILIAL "
			_cQryPulmao += "         AND QTDPRD.D_E_L_E_T_ = '' "
			_cQryPulmao += "         AND QTDPRD.Z16_SALDO > 0"
			_cQryPulmao += "         AND QTDPRD.Z16_LOCAL = Z16.Z16_LOCAL"
			_cQryPulmao += "         AND QTDPRD.Z16_ENDATU = Z16.Z16_ENDATU) = 1"
			// endereço não pode estar sob inventario
			_cQryPulmao += " AND Z16_ENDATU NOT IN (SELECT Z21_LOCALI FROM " + RetSqlTab("Z21") + " (NOLOCK) WHERE " + RetSqlCond("Z21") + " AND Z21_LOCAL = Z16_LOCAL AND Z21_IDENT IN (SELECT Z06_NUMOS FROM " + RetSqlTab("Z06") + " (NOLOCK) WHERE Z06_FILIAL = Z21_FILIAL AND Z06_NUMOS = Z21_IDENT AND D_E_L_E_T_ = '' AND Z06_STATUS NOT IN ('FI','CA'))) "
			// valida se o endereço já está em outro mapa - end origem
			_cQryPulmao += "        AND NOT EXISTS (SELECT * "
			_cQryPulmao += "                        FROM   " +RetSqlTab("Z08")+ " WITH(INDEX(" +RetSqlName("Z08")+ "4)) "
			_cQryPulmao += "                        WHERE  "+RetSqlCond("Z08")
			_cQryPulmao += "                               AND Z08_LOCAL = Z16_LOCAL "
			_cQryPulmao += "                               AND Z08_ENDORI = Z16_ENDATU "
			_cQryPulmao += "                               AND Z08_STATUS <> 'R' "
			_cQryPulmao += "                               AND Z08_TPOPER IN ( 'I', 'S' )) "
			// valida se o endereço já está em outro mapa - end destino
			_cQryPulmao += "        AND NOT EXISTS (SELECT * "
			_cQryPulmao += "                        FROM   " +RetSqlTab("Z08")+ " WITH(INDEX(" +RetSqlName("Z08")+ "2)) "
			_cQryPulmao += "                        WHERE  "+RetSqlCond("Z08")
			_cQryPulmao += "                               AND Z08_LOCAL = Z16_LOCAL "
			_cQryPulmao += "                               AND Z08_ENDDES = Z16_ENDATU "
			_cQryPulmao += "                               AND Z08_STATUS <> 'R' "
			_cQryPulmao += "                               AND Z08_TPOPER IN ( 'I', 'S' )) "
			// valida se o endereço não está bloqueado e se é daquele cliente
			_cQryPulmao += " AND EXISTS (SELECT * FROM " + RetSqlName("SBE") + " SBE (NOLOCK) WHERE "+RetSqlCond("SBE")+" AND SBE.BE_LOCAL = Z16.Z16_LOCAL AND BE_LOCALIZ = Z16_ENDATU AND BE_STATUS = '2' AND BE_ZCODCLI = '"+mvCli+"') "
			// valida se o endereço possui saldo na SBF
			_cQryPulmao += " AND EXISTS (SELECT * FROM " + RetSqlName("SBF") + " SBF (NOLOCK) WHERE "+RetSqlCond("SBF")+" AND SBF.BF_LOCAL = Z16.Z16_LOCAL AND BF_LOCALIZ = Z16_ENDATU AND BF_PRODUTO = Z16_CODPRO "
			// e se o saldo é maior ou igual o que marca tendo na etiqueta
			_cQryPulmao += " AND BF_QUANT >= (SELECT SUM(Z16_SALDO) FROM " + RetSqlName("Z16") + " Z16A  (nolock) WHERE Z16A.Z16_FILIAL = " + xFilial("Z16") + " AND Z16A.D_E_L_E_T_ = '' AND SBF.BF_LOCAL = Z16A.Z16_LOCAL AND BF_LOCALIZ = Z16A.Z16_ENDATU AND BF_PRODUTO = Z16A.Z16_CODPRO AND Z16A.Z16_ETQPAL = Z16.Z16_ETQPAL AND Z16A.Z16_TPESTO = Z16.Z16_TPESTO)) "
			_cQryPulmao += " GROUP BY Z16_CODPRO, Z16_ETQPAL, Z16_ENDATU "

			// ordena pela quantidade, quando buscar por pallet completo
			If ( _lPickComp )
				_cQryPulmao += " ORDER BY Z16_SALDO DESC "
			Else
				_cQryPulmao += " ORDER BY Z16_ETQPAL "
			EndIf

			memowrit("C:\query\wmsa009g_query_02.txt",_cQryPulmao)

			// jogo os dados pro vetor
			_aEndAux := U_SqlToVet(_cQryPulmao)

			// jogo pro vetor que vai ser usado na comparação
			If (Len(_aEndAux) > 0)
				// vetor principal de picking/endereços a abastecer
				For _nX := 1 to Len(_aEndAux)
					// valores sendo adicionados de acordo com o que são encontrados
					aAdd(_aEndPulmao, {_aEndAux[_nX][1],_aEndAux[_nX][2], _aEndAux[_nX][3], _aEndAux[_nX][4]})
				Next _nX
			EndIf

			// se em algum momento deu false, sai do loop
			If( ! _lRet)
				Exit
			EndIf

		Next _nPick

	EndIf

	// valido se o array com os resultados do pulmao possui registros caso seja scheduler
	If (_lRet) .And. (len(_aEndPulmao) <= 0) .AND. (mvScheduler)
		// mensagem de log no console
		FWLogMsg('INFO',, 'SIGAWMS', FunName(), '', '01',"Não foram encontrados endereços no pulmão para reabastecimento do picking", 0, 0, {})

		// variavel de controle
		_lRet := .F.
	EndIf

	If (_lRet)
		// para cada registro de solicitação
		For _nPick := 1 to Len(_aEndPicking)

			// para cada registro já encontrado no pulmão na listagem de endereços disponíveis
			For	_nPul := 1 to Len(_aEndPulmao)

				// se for do mesmo produto e estejam em endereços distintos
				If (_aEndPulmao[_nPul][2] == _aEndPicking[_nPick][2]) .And. ( ! _aEndPulmao[_nPul][4] $ _cEndPrd)
					_aEndPicking[_nPick][7] := _aEndPulmao[_nPul][4] // endereço
					_aEndPicking[_nPick][8] := _aEndPulmao[_nPul][1] // saldo
					_aEndPicking[_nPick][9] := _aEndPulmao[_nPul][3] // pallet
					// controle de produto + endereço já utilizados
					_cEndPrd += _aEndPulmao[_nPul][4] + "/"
					Exit
				EndIf
				// próximo registro do Pulmão
			Next _nPul
			// próximo registro do picking
		Next _nPick

		// para cada registro de solicitação valida se tudo foi atendido
		For _nPick := 1 to Len(_aEndPicking)
			// produtos sem saldo para abastecimento aparecem zerados
			If (_aEndPicking[_nPick][8] == 0)
				// produtos sem saldo para abastecimento
				// não mostra selecionado
				_aEndPicking[_nPick][1] := "LBNO"

				// deixa como deletado
				_aEndPicking[_nPick][12] := .T.

				// pra ver quantos estão zeraddos
				_nPrdSldZero++
			EndIf
		Next _nPick

		// produtos com saldo zerado
		If (_nPrdSldZero > 0) .And. ( ! mvScheduler )
			// mensagem
			Help( Nil, Nil, 'Abastecimento de Picking', Nil, "Existem produtos sem saldo para abastecimento ou com OS pendente para o endereço correspondente. Verifique!", 1, 0 )
		EndIf

		// abre a tela com as informações
		If ( ! mvScheduler )
			sfTelaAbaste(_aEndPicking)
		ElseIf ( mvScheduler )
			// usa funcao da rotina (Tela) para atualizar enderecos selecioanados
			If ( sfSelecEnd(_aEndPicking, @_aAutEndSel, mvScheduler) )
				// utiliza funcao para gerar ordem de servico
				If ( sfGeraOS(_aAutEndSel, mvScheduler) )
					// mensagem de log no console
					FWLogMsg('INFO',, 'SIGAWMS', FunName(), '', '01',"Final: " + Time() , 0, 0, {})
				EndIf
			EndIf
		EndIf
	EndIf

Return(_lRet)

// ** função que apresenta os dados pro usuário
Static Function sfTelaAbaste(mvDados)

	// objetos locais
	local _oBrwEnd, _oBrwSelec, _oDlgEnd, _oPnlRight, _oPnlLeft, _oPnlBottom, _oBtReserv, _oBtRemov, _oBtGera, _oBtSair, _oBtGExc, _oBtMarkAll
	// arrays do browse
	private _aHeadEnd := {}, _aHeadRes := {}
	private _aColsEnd := aClone(mvDados), _aColsRes := aClone(sfBrwZerado(Nil, .T.))

	// monta a tela
	_oDlgEnd := MSDialog():New(_aSizeWnd[7],000,_aSizeWnd[6],_aSizeWnd[5],"Endereços Para Reabastecimento",,,.F.,,,,,,.T.,,,.T. )
	_oDlgEnd:lMaximized := .T.

	// cria o panel da esquerda com as opções para abastecimento
	_oPnlLeft := TPanel():New(000,000,nil,_oDlgEnd,,.F.,.F.,,,(_aSizeWnd[5]/4),(_aSizeWnd[5]/4),.T.,.F. )
	_oPnlLeft:Align := CONTROL_ALIGN_LEFT

	// cria o panel da direita com as opções para abastecimento já escolhidas
	_oPnlRight := TPanel():New(_aSizeWnd[7],000,nil,_oDlgEnd,,.F.,.F.,,,(_aSizeWnd[5]/4),(_aSizeWnd[5]/4),.T.,.F. )
	_oPnlRight:Align := CONTROL_ALIGN_RIGHT

	// cria o panel da direita com as opções para abastecimento já escolhidas
	_oPnlBottom := TPanel():New(000,000,nil,_oDlgEnd,,.F.,.F.,,,000,030,.T.,.F. )
	_oPnlBottom:Align := CONTROL_ALIGN_BOTTOM

	/* Browse dos Endereços A Abastecer */
	// header do browse de endereços a abastecer
	aAdd(_aHeadEnd,{"Selecionar" ,'IT_OK'    ,'@BMP'                      ,4                      ,0, Nil, Nil, "C", Nil,"R" })
	aAdd(_aHeadEnd,{"Produto"    ,"PRODUTO"  ,PesqPict("SB1","B1_COD")    ,TamSx3("B1_COD")[1]    ,0, Nil, Nil, "C", Nil,"R" })
	aAdd(_aHeadEnd,{"End.Picking","ENDERECO" ,PesqPict("SBE","BE_LOCALIZ"),TamSx3("BE_LOCALIZ")[1],0, Nil, Nil, "C", Nil,"R" })
	aAdd(_aHeadEnd,{"Est.Atual"  ,"ESTATUAL" ,PesqPict("SBF","BF_QUANT")  ,TamSx3("BF_QUANT")[1]  ,0, Nil, Nil, "C", Nil,"R" })
	aAdd(_aHeadEnd,{"Est.Minimo" ,"ESTMIN"   ,PesqPict("SBE","BE_ZESTMIN"),TamSx3("BE_ZESTMIN")[1],0, Nil, Nil, "C", Nil,"R" })
	aAdd(_aHeadEnd,{"Est.Máximo" ,"ESTMAX"   ,PesqPict("SBE","BE_ZESTMAX"),TamSx3("BE_ZESTMAX")[1],0, Nil, Nil, "C", Nil,"R" })
	aAdd(_aHeadEnd,{"End.Pulmão" ,"ENDPULMAO",PesqPict("SBE","BE_LOCALIZ"),TamSx3("BE_LOCALIZ")[1],0, Nil, Nil, "C", Nil,"R" })
	aAdd(_aHeadEnd,{"Qtd.Pulmão" ,"QTDPULMAO",PesqPict("SBF","BF_QUANT")  ,TamSx3("BF_QUANT")[1]  ,0, Nil, Nil, "C", Nil,"R" })
	aAdd(_aHeadEnd,{"Plt.Pulmão" ,"PLTPULMAO",PesqPict("Z16","Z16_ETQPAL"),TamSx3("Z16_ETQPAL")[1],0, Nil, Nil, "C", Nil,"R" })
	aAdd(_aHeadEnd,{"Armazém"    ,"LOCAL"    ,PesqPict("SBE","BE_LOCAL")  ,TamSx3("BE_LOCAL")[1]  ,0, Nil, Nil, "C", Nil,"R" })

	// browse com os detalhes dos endereços a abastercer
	_oBrwEnd := MsNewGetDados():New(000,000,999,999,GD_UPDATE,'AllwaysTrue()','AllwaysTrue()','',,,,'AllwaysTrue()','','AllwaysTrue()',_oPnlLeft,_aHeadEnd,_aColsEnd)
	_oBrwEnd:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwEnd:oBrowse:bLDblClick := {|| IIF( _aColsEnd[_oBrwEnd:nAt,12] == .F.,_oBrwEnd:aCOLS[_oBrwEnd:nAt,1] := IIF(_oBrwEnd:aCOLS[_oBrwEnd:nAt,1]=='LBOK','LBNO','LBOK'), Nil)}

	/* Browse dos Endereços Selecionados */
	// header do browse de endereços selecionados
	aAdd(_aHeadRes,{"Produto"    ,"PRODUTO"   ,PesqPict("SB1","B1_COD")    ,TamSx3("B1_COD")[1]    , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadRes,{"End.Picking","ENDERECO"  ,PesqPict("SBE","BE_LOCALIZ"),TamSx3("BE_LOCALIZ")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadRes,{"Est.Atual"  ,"ESTATUAL"  ,PesqPict("SBF","BF_QUANT")  ,TamSx3("BF_QUANT")[1]  , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadRes,{"Est.Minimo" ,"ESTMIN"    ,PesqPict("SBE","BE_ZESTMIN"),TamSx3("BE_ZESTMIN")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadRes,{"Est.Máximo" ,"ESTMAX"    ,PesqPict("SBE","BE_ZESTMAX"),TamSx3("BE_ZESTMAX")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadRes,{"End.Pulmão" ,"ENDPULMAO" ,PesqPict("SBE","BE_LOCALIZ"),TamSx3("BE_LOCALIZ")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadRes,{"Qtd.Pulmão" ,"QTDPULMAO" ,PesqPict("SBF","BF_QUANT")  ,TamSx3("BF_QUANT")[1]  , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadRes,{"Plt.Pulmão" ,"PLTPULMAO" ,PesqPict("Z16","Z16_ETQPAL"),TamSx3("Z16_ETQPAL")[1], 0, Nil, Nil, "C", Nil,"R" })
	aAdd(_aHeadRes,{"Armazém"    ,"LOCAL"     ,PesqPict("SBE","BE_LOCAL")  ,TamSx3("BE_LOCAL")[1]  , 0, Nil, Nil, "C", Nil,"R" })

	// browse com os detalhes dos endereços a abastercer
	_oBrwSelec := MsNewGetDados():New(000,000,999,999,Nil,'AllwaysTrue()','AllwaysTrue()','',,,,'AllwaysTrue()','','AllwaysTrue()',_oPnlRight,_aHeadRes,_aColsRes)
	_oBrwSelec:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// marcar todos
	_oBtMarkAll := TButton():New( 010, 010,"Marcar/Desmarcar Todos",_oPnlBottom,{|| sfMarkAll(_oBrwEnd, Len(_aHeadEnd)+2) }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// botão que irá reservar os endereços
	_oBtReserv := TButton():New( 010, 092,"Selec. Endereços",_oPnlBottom,{|| sfSelecEnd(_oBrwEnd, _oBrwSelec, .F.) }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// botão que irá 'desreservar' os endereços
	_oBtRemov := TButton():New( 010, 174,"Remov. Endereços",_oPnlBottom,{||  IIF(MsgYesNo("Desejar Remover os Endereços Selecionados?"), sfBrwZerado(_oBrwSelec,.F.), Nil) }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// botão que irá gerar a OS para alimentar os endereços
	_oBtGera := TButton():New( 010, 256,"Gerar OS",_oPnlBottom,{|| IIF (sfGeraOS(_oBrwSelec, .F.), _oDlgEnd:END(),Nil) }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// botão que irá gerar excel com os endereços selecionados
	_oBtGExc := TButton():New( 010, 338,"Gerar Excel",_oPnlBottom, {|| DlgToExcel({ {"GETDADOS", "Exportacao para o Excel", _aHeadRes, _oBrwSelec:aCols} }) }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// botão que irá sair da rotina
	_oBtSair := TButton():New( 010, 420,"Cancelar",_oPnlBottom,{|| IIF(MsgYesNo("Desejar Sair?"), _oDlgEnd:END(), Nil) }, 80,10,,,.F.,.T.,.F.,,.F.,,,.F. )

	// ativacao da tela
	_oDlgEnd:Activate(,,,.T.,)

Return ()

// ** função para selecionar ou deselecionar todos os endereços ** //
Static Function sfMarkAll(mvBrw, mvPosDel)

	// variavel que recebe posição do campo deletado
	local _nPosDel := mvPosDel // esse mais dois é devido o retorno da query ter

	// usei o aEval pra 'economizar' código
	aEval(mvBrw:aCOLS, {|x| IIF( x[_nPosDel] == .F., x[1] := IIF( x[1]=='LBOK', 'LBNO', 'LBOK'), Nil)})

	// atualizo o browse
	If (mvBrw <> nil)
		mvBrw:oBrowse:Refresh()
	EndIf
Return

// ** função que seleciona os endereços para geração da OS
Static Function sfSelecEnd(mvBrwEnd, mvBrwSelec, mvScheduler)

	// array para salvar dados do browse de endereços
	local _aBrwEnd := {}
	// controle do loop
	local _nX := 0
	// saldo a ser abastecido
	local _nSaldo := 0

	// variaveis para controle
	local _aTmpEndPick := IIf(mvScheduler, mvBrwEnd, mvBrwEnd:aCols)

	// varro o browse pra poder atualizar
	For _nX := 1 to len(_aTmpEndPick)
		If(_aTmpEndPick[_nX,1] == 'LBOK') .And. ( ! _aTmpEndPick[_nX,12] )
			// valido a informação da quantidade atual
			If ( _aTmpEndPick[_nX,11] > _aTmpEndPick[_nX,8])
				_nSaldo := _aTmpEndPick[_nX,8]
			Else
				_nSaldo := _aTmpEndPick[_nX,11] // saldo
			EndIf

			// incluo os dados com as informações do browse
			aAdd(_aBrwEnd,{;
			_aTmpEndPick[_nX, 2], ;
			_aTmpEndPick[_nX, 3], ;
			_aTmpEndPick[_nX, 4], ;
			_aTmpEndPick[_nX, 5], ;
			_aTmpEndPick[_nX, 6], ;
			_aTmpEndPick[_nX, 7], ;
			_nSaldo             , ;
			_aTmpEndPick[_nX, 9], ;
			_aTmpEndPick[_nX,10], ;
			.F. })
		EndIf
	Next _nX

	// se tem algum registro no array atualiza o browse
	If (len(_aBrwEnd) > 0)
		// atualizo o browse
		If ( ! mvScheduler )
			mvBrwSelec:aCols := aClone(_aBrwEnd)
			// refresh do browse
			If (mvBrwSelec <> nil)
				mvBrwSelec:oBrowse:Refresh()
			EndIf
		Else
			mvBrwSelec := aClone(_aBrwEnd)
		EndIf
	EndIf

Return( .T. )

// ** função para remover os endereços selecionados
Static Function sfBrwZerado(mvBrwSelec, mvFirst)

	// array para salvar dados do browse de endereços
	local _aBrwSelec := {}
	// incluo os dados zerados para limpar o browse
	aAdd(_aBrwSelec, {"", "", 0, 0, 0, "", 0, "", "",.F.} )
	// se for a primeira vez, preenche o aCols sem atualizar
	If (mvFirst)
		Return(_aBrwSelec)
	Else
		// atualizo o browse
		mvBrwSelec:aCols := aClone(_aBrwSelec)
		// refresh do browse
		If (mvBrwSelec <> Nil)
			mvBrwSelec:oBrowse:Refresh()
		EndIf
	EndIf

Return (.T.)

// ** função que gera a OS de abastecimento
Static Function sfGeraOS(mvBrwSelec, mvScheduler)

	Local _lRet    := .F.
	Local _cNumId  := ""
	local _aRecHum := {} // array para convocação recursos humanos
	local _aRecEqu := {} // array para convocação recursos equipamento
	local _nX      := 0 // controle do for
	local _nZ      := 0 // controle do for
	local _nY      := 0 // controle do for
	local _nSeq    := 1 // sequencia da OS
	local _cEndTra := ""
	local _cQuery

	// mensagem de confirmacao
	local _cHtml

	// relacao de enderecos selecionados para emissao da ordem de servico
	local _aTmpEndSel := IIf(mvScheduler, mvBrwSelec, mvBrwSelec:aCols)

	// controle se deve atribuir automaticamente os recursos humanos
	local _lAddRecAut := .T.

	// validação para o usuário
	If ( ! mvScheduler ) .And. ( ! MsgYesNo("Deseja Gerar OS para os Endereços Selecionados?") )
		Return (.F.)
	EndIf

	// permite validação por volumes
	_lCtrVolume := U_FtWmsParam("WMS_CONTROLE_POR_VOLUME", "L", .F., .F., Nil, _cCodCli, _cLjCli, Nil, Nil)

	// controle se deve atribuir automaticamente os recursos humanos
	_lAddRecAut := U_FtWmsParam("WMS_ATRIBUI_RECURSOS_HUMANOS_AUTOMATICAMENTE", "L", .F., .T., "", _cCodCli, _cLjCli, Nil, Nil)

	// valido se foi escolhido algum endereço
	If ( ! mvScheduler ) .And. (len(_aTmpEndSel) <= 1) .And. (Empty(_aTmpEndSel[1][1]))
		MsgStop("É necessário selecionar ao menos um endereço para geração da OS.")
		Return (.F.)
	EndIf

	// inicio a transação para ter um rollback em caso de erro
	BEGIN TRANSACTION

		dbSelectArea("Z05")
		_cNumId := GetSXENum("Z05","Z05_NUMOS", xFilial("Z05"))

		// crio a Z05
		dbSelectArea("Z05")
		RECLOCK("Z05", .T.)
		Z05->Z05_FILIAL   := xFilial("Z05")
		Z05->Z05_NUMOS    := _cNumId
		Z05->Z05_DTEMIS   := DATE()
		Z05->Z05_HREMIS   := TIME()
		Z05->Z05_TPOPER   := "I"
		Z05->Z05_CLIENT   := _cCodCli
		Z05->Z05_LOJA     := _cLjCli
		MSUNLOCK()     // Destrava o registro

		// crio a Z06
		dbSelectArea("Z06")
		RECLOCK("Z06", .T.)
		Z06->Z06_FILIAL   := xFilial("Z06")
		Z06->Z06_NUMOS    := _cNumId
		Z06->Z06_SEQOS    := "001"
		Z06->Z06_SERVIC   := "014"
		Z06->Z06_TAREFA   := "013"
		Z06->Z06_DTEMIS   := DATE()
		Z06->Z06_HREMIS   := TIME()
		Z06->Z06_USRINC   := __cUserId
		Z06->Z06_STATUS   := "AG"
		Z06->Z06_PRIOR    := "99"
		Z06->Z06_LOCAL    := _aTmpEndSel[1][9] // armazém
		Z06->Z06_ATUEST   := "S"
		Z06->Z06_ENDSRV   := "ZZZ"
		MSUNLOCK()     // Destrava o registro

		// inclusao do PLAJENAMENTO e ATRIBUICAO de recursos necessarios para operacao com base no serviço informado
		sfAddRecurso(Z06->Z06_SERVIC, Z06->Z06_TAREFA, Z06->Z06_SEQOS, Z05->Z05_CLIENT, Z05->Z05_LOJA, Z05->Z05_TPOPER, .T., _lAddRecAut)

		// prepara mensagem para envio por email
		If (mvScheduler)
			_cHtml := '<table width="860px" align="center">'
			_cHtml += '   <tr>'
			_cHtml += '      <td>'
			_cHtml += '         <table style="border-collapse: collapse;" border="1" width="100%" cellpadding="3" cellspacing="0" align="center">'
			_cHtml += '            <tr>'
			_cHtml += '               <td height="30" colspan="9" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Geração Automática de Ordens de Serviço</td>'
			_cHtml += '            </tr>'
			_cHtml += '            <tr>'
			_cHtml += '               <td width="20%" style="font-family: Tahoma; font-size: 12px;">Empresa:</td>'
			_cHtml += '               <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;' + AllTrim(Upper(SM0->M0_NOMECOM)) + '</td>'
			_cHtml += '            </tr>'
			_cHtml += '            <tr>'
			_cHtml += '               <td width="20%" style="font-family: Tahoma; font-size: 12px;">Filial:</td>'
			_cHtml += '               <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;' + AllTrim(Upper(SM0->M0_FILIAL)) + '</td>'
			_cHtml += '            </tr>'
			_cHtml += '            <tr>'
			_cHtml += '               <td width="20%" style="font-family: Tahoma; font-size: 12px;">Serviço:</td>'
			_cHtml += '               <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;Reabastecimento de Picking</td>'
			_cHtml += '            </tr>'
			_cHtml += '            <tr>'
			_cHtml += '               <td width="20%" style="font-family: Tahoma; font-size: 12px;">Número:</td>'
			_cHtml += '               <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;' + _cNumId + '</td>'
			_cHtml += '            </tr>'
			_cHtml += '            <tr>'
			_cHtml += '               <td width="20%" style="font-family: Tahoma; font-size: 12px;">Data e Hora de Emissão:</td>'
			_cHtml += '               <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;' + DtoC(Z06->Z06_DTEMIS) + ' as ' + Z06->Z06_HREMIS + 'h</td>'
			_cHtml += '            </tr>'
			_cHtml += '            <tr>'
			_cHtml += '               <td width="20%" style="font-family: Tahoma; font-size: 12px;">Cliente/Loja - Nome:</td>'
			_cHtml += '               <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;' + _cCodCli + '/' + _cLjCli + ' - ' + AllTrim(Posicione("SA1", 1, xFilial("SA1") + _cCodCli + _cLjCli, "A1_NOME")) + '</td>'
			_cHtml += '            </tr>'
			_cHtml += '            <tr>'
			_cHtml += '               <td width="20%" style="font-family: Tahoma; font-size: 12px;">Ruas:</td>'
			_cHtml += '               <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;De ' + mv_par03 + ' a ' + mv_par04 + '</td>'
			_cHtml += '            </tr>'
			_cHtml += '            <tr>'
			_cHtml += '               <td width="20%" style="font-family: Tahoma; font-size: 12px;">Lado:</td>'
			_cHtml += '               <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;' + IIf(mv_par05 == 1, "A", IIf(mv_par05 == 2, "B", "Ambos")) + '</td>'
			_cHtml += '            </tr>'
			_cHtml += '            <tr>'
			_cHtml += '               <td width="20%" style="font-family: Tahoma; font-size: 12px;">Prédio</td>'
			_cHtml += '               <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;De ' + mv_par06 + ' a ' + mv_par07 + '</td>'
			_cHtml += '            </tr>'
			_cHtml += '            <tr>'
			_cHtml += '               <td width="20%" style="font-family: Tahoma; font-size: 12px;">Produto:</td>'
			_cHtml += '               <td width="80%" style="font-family: Tahoma; font-size: 12px;">&nbsp;De ' + AllTrim(mv_par08) + ' até ' + AllTrim(mv_par09) + '</td>'
			_cHtml += '            </tr>'
			_cHtml += '         </table>'
			_cHtml += '         <br>'
			_cHtml += '         <table style="border-collapse: collapse;" border="1" width="100%" cellpadding="3" cellspacing="0" align="center">'
			_cHtml += '            <tr>'
			_cHtml += '               <td colspan="9" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="120" align="center">Detalhes da Movimentação</td>'
			_cHtml += '            </tr>'
			_cHtml += '            <tr>'
			_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="30">Armazém</td>'
			_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="90">Endereço</td>'
			_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="90">Produto</td>'
			_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="120">Descrição</td>'
			_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="80">Quantidade Atual</td>'
			_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="80">Estoque Mínimo</td>'
			_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="90">Estoque Máximo</td>'
			_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="120">Endereço Pulmão</td>'
			_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="80">Quantidade</td>'
			_cHtml += '            </tr>'
		EndIf

		// vou varrer o array do browse
		For _nX := 1 To len(_aTmpEndSel)

			/** Movimento entre blocados **/
			// não preenche a variável
			If ( sfVldTpEnd(_aTmpEndSel[_nX][6]) ) .or. ( sfVldTpEnd(_aTmpEndSel[_nX][2]) )

				// rua do endereço de origem
				_cEndTra := ""
			EndIf

			/** Origem Blocado e Destino Porta Pallet **/
			If ( sfVldTpEnd(_aTmpEndSel[_nX][6]) ) .or. ( ! sfVldTpEnd(_aTmpEndSel[_nX][2]) )

				// endereço de transação é a rua do destino
				_cEndTra := Substr( _aTmpEndSel[_nX][2], 1, 2 )
			EndIf

			/** Origem Porta Pallet e Destino Blocado **/
			If ( ! sfVldTpEnd(_aTmpEndSel[_nX][6]) ) .or. ( sfVldTpEnd(_aTmpEndSel[_nX][2]) )

				// endereço de transação é a rua da origem
				_cEndTra := Substr( _aTmpEndSel[_nX][6], 1, 2 )
			EndIf

			// crio a Z08
			dbSelectArea("Z08")
			RECLOCK("Z08", .T.)
			Z08->Z08_FILIAL := xFilial("Z08")
			Z08->Z08_NUMOS  := _cNumId
			Z08->Z08_SEQOS  := "001"
			Z08->Z08_LOCAL  := _aTmpEndSel[_nX][9] // armazém
			Z08->Z08_SERVIC := "014"
			Z08->Z08_TAREFA := "013"
			Z08->Z08_CLIENT := _cCodCli
			Z08->Z08_LOJA   := _cLjCli
			Z08->Z08_ENDSRV := _aTmpEndSel[_nX][6]
			Z08->Z08_ENDORI := _aTmpEndSel[_nX][6]
			Z08->Z08_ENDTRA := _cEndTra
			Z08->Z08_ENDDES := _aTmpEndSel[_nX][2]
			Z08->Z08_DTEMIS := Date()
			Z08->Z08_HREMIS := Time()
			Z08->Z08_STATUS := "P" // P-Planejado / R-Realizado / M-Movimento / E-Erro
			Z08->Z08_PRODUT := _aTmpEndSel[_nX][1]
			Z08->Z08_QUANT  := _aTmpEndSel[_nX][7]
			Z08->Z08_PRIOR  := "99"
			Z08->Z08_PALLET := _aTmpEndSel[_nX][8]
			Z08->Z08_FRAPLT := "N"
			Z08->Z08_SEQUEN := STRZERO(_nSeq,4)
			Z08->Z08_TPOPER := "I"
			Z08->Z08_LOCDES := _aTmpEndSel[_nX][9] // armazém
			Z08->(MsUnLock())

			// sequencia da OS
			_nSeq ++

			// detalhes da ordem de servico
			If (mvScheduler)
				_cHtml += '            <tr>'
				_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="30" align="center">' + Z08->Z08_LOCAL + '</td>'
				_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="90">' + AllTrim(Z08->Z08_ENDDES)+ '</td>'
				_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="90">' + AllTrim(Z08->Z08_PRODUT) + '</td>'
				_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="170">' + AllTrim(Posicione("SB1", 1, xFilial("SB1") + Z08->Z08_PRODUT, "B1_DESC"))+ '</td>'
				_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="90" align="center">' + AllTrim(Transf(_aTmpEndSel[_nX][3],PesqPict('SBF','BF_QUANT'))) + '</td>'
				_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="90" align="center">' + AllTrim(Transf(_aTmpEndSel[_nX][4],PesqPict('SBF','BF_QUANT'))) + '</td>'
				_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="90" align="center">' + AllTrim(Transf(_aTmpEndSel[_nX][5],PesqPict('SBF','BF_QUANT'))) + '</td>'
				_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="120" >' + AllTrim(Z08->Z08_ENDORI)+ '</td>'
				_cHtml += '               <td style="font-family: Tahoma; font-size: 12px; color: #000000;" width="80" align="center">' + AllTrim(Transf(Z08->Z08_QUANT,PesqPict('SBF','BF_QUANT'))) + '</td>'
				_cHtml += '            </tr>'
			EndIf

		Next _nX

		// confirma auto-increment
		ConfirmSX8()

		_lRet := .T.

		// finaliza mensagem da ordem de servico
		If (mvScheduler)
			_cHtml += '         </table>'
			_cHtml += '      </td>'
			_cHtml += '   </tr>'
			_cHtml += '</table>'
		EndIf

	END TRANSACTION

	If (_lRet)
		If( ! mvScheduler )
			U_FtWmsMsg("OS de Reabastecimento gerada com sucesso. Nº: " + _cNumId, "Aviso")
		Else
			// mensagem de email
			U_FtMail(_cHtml, "Agendamento - TWMSW002 - Reabastecimento de Picking", "operacoes103@tecadi.com.br")

			// mensagem no console do server
			FWLogMsg('INFO',, 'SIGAWMS', FunName(), '', '01',"OS de Reabastecimento gerada com sucesso. Nº: " + _cNumId , 0, 0, {})
		EndIF
	Else
		U_FtWmsMsg("OS de Reabastecimento não foi gerada. Tenta novamente!","Atenção")
	EndIf

Return (_lRet)

// ** validação do endereço de destino para saber se é endereço de transação ou destino
Static Function sfVldTpEnd(mvEnd)

	local _cQuery := ""
	local _lRet   := .F.

	_cQuery := "  SELECT COUNT(*) "
	_cQuery += "  FROM "+RetSqlName("SBE")+" SBE (nolock)  "
	_cQuery += "  WHERE "+RetSqlCond("SBE")
	_cQuery += "  AND BE_LOCALIZ = '"+mvEnd+"'
	_cQuery += "  AND EXISTS ( "
	_cQuery += "  SELECT * FROM "+RetSqlName("DC8")+" DC8 (nolock)  "
	_cQuery += "  WHERE DC8_CODEST = BE_ESTFIS "
	_cQuery += "  AND DC8_TPESTR IN ('4','5') "
	_cQuery += "  AND "+RetSqlCond("DC8") + " )"

	memowrit("C:\query\TWMSA011_sfVldTpEnd.txt",_cQuery)

	// caso encontre algum registro ele retorna verdadeiro
	If (U_FtQuery(_cQuery) >= 1)
		_lRet := .T.
	EndIf

Return(_lRet)

//Função que chama tela para aplicar filtros nas OS apresentadas na tela Principal.
Static Function sfFilDados()

	// dimensoes da tela
	Local _aSizeAut := MsAdvSize()

	// montagem da tela de filtros
	_oTelaFil := MSDialog():New( _aSizeAut[7],000,_aSizeAut[6],_aSizeAut[5],"Filtros",,,.F.,,,,,,.T.,,,.T. )

	//Paineis Tela Principal
	// Alinha painel ao topo.
	oPanelTop:= tPanel():New(0,0,"",_oTelaFil,,,,,,00,030)
	oPanelTop:align:= CONTROL_ALIGN_TOP
	// Alinha painel preenchendo toda a área.
	oPanelAll:= tPanel():New(0,0,"",_oTelaFil,,,,,,00,030)
	oPanelAll:align:= CONTROL_ALIGN_ALLCLIENT

	//Botões
	// botao confirmar
	_oBtnOK := TBtnBmp2():New(001,001,040,040,"PCOFXOK",,,,{|| SfApliFilt() },oPanelTop,"Confirmar",,.T. )
	_oBtnOK:Align := CONTROL_ALIGN_LEFT
	// botao Limpar Filtro
	_oBtnOK := TBtnBmp2():New(001,001,040,040,"SDUZAP",,,,{||IIF(MsgYesNo("Desejar Limpar os filtros aplicados?"), SfLimpFilt() , Nil)},oPanelTop,"Limpa Filtro",,.T. )
	_oBtnOK:Align := CONTROL_ALIGN_LEFT
	// botao cancelar/Fechar Tela
	_oBtnSai := TBtnBmp2():New(001,001,040,040,"FINAL",,,,{|| IIF(MsgYesNo("Desejar Sair?"), _oTelaFil:END(), Nil)},oPanelTop,"Sair",,.T. )
	_oBtnSai:Align := CONTROL_ALIGN_RIGHT

	//Folder
	//Folder cada folder sera um tipo de filtro.
	_oFlder      := TFolder():New( 036,004,{"OS Finalizadas","Operador","Maquina/Equipamento","Ruas","Pedido De Venda","Pedido Cliente","Agrupadora/DLN","Tipo Operação"},{},oPanelAll,,,,.T.,.F.,500,3000,)
	_oFlder:align:= CONTROL_ALIGN_ALLCLIENT

	//Paineis folder
	// Painel topo.
	//oPanelT01:= tPanel():New(0,0,"",_oFlder:aDialogs[1],,,,,,00,020)
	//oPanelT01:align:= CONTROL_ALIGN_TOP
	oPanelT02:= tPanel():New(0,0,"",_oFlder:aDialogs[2],,,,,,00,030)
	oPanelT02:align:= CONTROL_ALIGN_TOP
	oPanelT03:= tPanel():New(0,0,"",_oFlder:aDialogs[3],,,,,,00,030)
	oPanelT03:align:= CONTROL_ALIGN_TOP
	oPanelT04:= tPanel():New(0,0,"",_oFlder:aDialogs[4],,,,,,00,030)
	oPanelT04:align:= CONTROL_ALIGN_TOP
	oPanelT05:= tPanel():New(0,0,"",_oFlder:aDialogs[5],,,,,,00,030)
	oPanelT05:align:= CONTROL_ALIGN_TOP
	oPanelT06:= tPanel():New(0,0,"",_oFlder:aDialogs[6],,,,,,00,030)
	oPanelT06:align:= CONTROL_ALIGN_TOP
	oPanelT07:= tPanel():New(0,0,"",_oFlder:aDialogs[7],,,,,,00,030)
	oPanelT07:align:= CONTROL_ALIGN_TOP
	// Painel área.
	oPanelA01:= tPanel():New(0,0,"",_oFlder:aDialogs[1],,,,,,3000,3000)
	oPanelA01:align:= CONTROL_ALIGN_ALLCLIENT
	oPanelA02:= tPanel():New(0,0,"",_oFlder:aDialogs[2],,,,,,3000,3000)
	oPanelA02:align:= CONTROL_ALIGN_ALLCLIENT
	oPanelA03:= tPanel():New(0,0,"",_oFlder:aDialogs[3],,,,,,3000,3000)
	oPanelA03:align:= CONTROL_ALIGN_ALLCLIENT
	oPanelA04:= tPanel():New(0,0,"",_oFlder:aDialogs[4],,,,,,3000,3000)
	oPanelA04:align:= CONTROL_ALIGN_ALLCLIENT
	oPanelA05:= tPanel():New(0,0,"",_oFlder:aDialogs[5],,,,,,3000,3000)
	oPanelA05:align:= CONTROL_ALIGN_ALLCLIENT
	oPanelA06:= tPanel():New(0,0,"",_oFlder:aDialogs[6],,,,,,3000,3000)
	oPanelA06:align:= CONTROL_ALIGN_ALLCLIENT
	oPanelA07:= tPanel():New(0,0,"",_oFlder:aDialogs[7],,,,,,3000,3000)
	oPanelA07:align:= CONTROL_ALIGN_ALLCLIENT
	oPanelA08:= tPanel():New(0,0,"",_oFlder:aDialogs[8],,,,,,3000,3000)
	oPanelA08:align:= CONTROL_ALIGN_ALLCLIENT

	//Botões Marca Todos / Desmarca Todos
	// Botão Marca Todos
	_oBtnMar02 := TBtnBmp2():New(001,001,040,040,"SELECTALL",,,,{||sfSelAll(2)  },oPanelT02,"Marcar Todos",,.T. )
	_oBtnMar02:Align := CONTROL_ALIGN_LEFT
	_oBtnMar03 := TBtnBmp2():New(001,001,040,040,"SELECTALL",,,,{||sfSelAll(3)  },oPanelT03,"Marcar Todos",,.T. )
	_oBtnMar03:Align := CONTROL_ALIGN_LEFT
	_oBtnMar04 := TBtnBmp2():New(001,001,040,040,"SELECTALL",,,,{||sfSelAll(4)  },oPanelT04,"Marcar Todos",,.T. )
	_oBtnMar04:Align := CONTROL_ALIGN_LEFT
	_oBtnMar05 := TBtnBmp2():New(001,001,040,040,"SELECTALL",,,,{||sfSelAll(5)  },oPanelT05,"Marcar Todos",,.T. )
	_oBtnMar05:Align := CONTROL_ALIGN_LEFT
	_oBtnMar06 := TBtnBmp2():New(001,001,040,040,"SELECTALL",,,,{||sfSelAll(6)  },oPanelT06,"Marcar Todos",,.T. )
	_oBtnMar06:Align := CONTROL_ALIGN_LEFT
	_oBtnMar07 := TBtnBmp2():New(001,001,040,040,"SELECTALL",,,,{||sfSelAll(7)  },oPanelT07,"Marcar Todos",,.T. )
	_oBtnMar07:Align := CONTROL_ALIGN_LEFT

	// Botão Desmarca Todos
	_oBtnDes02 := TBtnBmp2():New(001,001,040,040,"UNSELECTALL",,,,{||sfUnsAll(2)},oPanelT02,"Desmarca Todos",,.T. )
	_oBtnDes02:Align := CONTROL_ALIGN_LEFT
	_oBtnDes03 := TBtnBmp2():New(001,001,040,040,"UNSELECTALL",,,,{||sfUnsAll(3)},oPanelT03,"Desmarca Todos",,.T. )
	_oBtnDes03:Align := CONTROL_ALIGN_LEFT
	_oBtnDes04 := TBtnBmp2():New(001,001,040,040,"UNSELECTALL",,,,{||sfUnsAll(4)},oPanelT04,"Desmarca Todos",,.T. )
	_oBtnDes04:Align := CONTROL_ALIGN_LEFT
	_oBtnDes05 := TBtnBmp2():New(001,001,040,040,"UNSELECTALL",,,,{||sfUnsAll(5)},oPanelT05,"Desmarca Todos",,.T. )
	_oBtnDes05:Align := CONTROL_ALIGN_LEFT
	_oBtnDes06 := TBtnBmp2():New(001,001,040,040,"UNSELECTALL",,,,{||sfUnsAll(6)},oPanelT06,"Desmarca Todos",,.T. )
	_oBtnDes06:Align := CONTROL_ALIGN_LEFT
	_oBtnDes07 := TBtnBmp2():New(001,001,040,040,"UNSELECTALL",,,,{||sfUnsAll(7)},oPanelT07,"Desmarca Todos",,.T. )
	_oBtnDes07:Align := CONTROL_ALIGN_LEFT

	//MsNewGetDados
	// browse 01 - Filtro para OS finalizadas
	_oBrwEsq01 := MsNewGetDados():New(000,000,3000,3000,Nil,'AllwaysTrue()','AllwaysTrue()','',,,99,'AllwaysTrue()','','AllwaysTrue()',oPanelA01,_aHeadOSF,_aColsOSF)
	_oBrwEsq01:oBrowse:bLDblClick := {|| SfMarca() }
	_oBrwEsq01:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	// browse 02 - Filtro para Operadores
	_oBrwEsq02 := MsNewGetDados():New(000,000,3000,3000,Nil,'AllwaysTrue()','AllwaysTrue()','',,,99,'AllwaysTrue()','','AllwaysTrue()',oPanelA02,_aHdRecHum,_aItRecHum)
	_oBrwEsq02:oBrowse:bLDblClick := {|| _aItRecHum[_oBrwEsq02:nAt,_nPosMARK] := IIf(_aItRecHum[_oBrwEsq02:nAt,_nPosMARK]=='LBOK', 'LBNO', 'LBOK') ,_oBrwEsq02:SetArray(_aItRecHum,.f.), _oBrwEsq02:Refresh(.t.) }
	_oBrwEsq02:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	// browse 03 - Filtro para Equipamentos e Maquinas
	_oBrwEsq03 := MsNewGetDados():New(000,000,3000,3000,Nil,'AllwaysTrue()','AllwaysTrue()','',,,99,'AllwaysTrue()','','AllwaysTrue()',oPanelA03,_aHdMaqEqu,_aItMaqEqu)
	_oBrwEsq03:oBrowse:bLDblClick := {|| _aItMaqEqu[_oBrwEsq03:nAt,_nPosMARK] := IIf(_aItMaqEqu[_oBrwEsq03:nAt,_nPosMARK]=='LBOK', 'LBNO', 'LBOK') ,_oBrwEsq03:SetArray(_aItMaqEqu,.f.), _oBrwEsq03:Refresh(.t.) }
	_oBrwEsq03:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	// browse 04 - Filtro para Ruas
	_oBrwEsq04 := MsNewGetDados():New(000,000,3000,3000,Nil,'AllwaysTrue()','AllwaysTrue()','',,,99,'AllwaysTrue()','','AllwaysTrue()',oPanelA04,_aHdRua,_aItRua)
	_oBrwEsq04:oBrowse:bLDblClick := {|| _aItRua[_oBrwEsq04:nAt,_nPosMARK] := IIf(_aItRua[_oBrwEsq04:nAt,_nPosMARK]=='LBOK', 'LBNO', 'LBOK') ,_oBrwEsq04:SetArray(_aItRua,.f.), _oBrwEsq04:Refresh(.t.) }
	_oBrwEsq04:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	// browse 05 - Filtro para Pedido de Venda
	_oBrwEsq05 := MsNewGetDados():New(000,000,3000,3000,Nil,'AllwaysTrue()','AllwaysTrue()','',,,99,'AllwaysTrue()','','AllwaysTrue()',oPanelA05,_aHdPedVen,_aItPedVen)
	_oBrwEsq05:oBrowse:bLDblClick := {|| _aItPedVen[_oBrwEsq05:nAt,_nPosMARK] := IIf(_aItPedVen[_oBrwEsq05:nAt,_nPosMARK]=='LBOK', 'LBNO', 'LBOK') ,_oBrwEsq05:SetArray(_aItPedVen,.f.), _oBrwEsq05:Refresh(.t.) }
	_oBrwEsq05:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	// browse 06 - Filtro para Pedido Cliente
	_oBrwEsq06 := MsNewGetDados():New(000,000,3000,3000,Nil,'AllwaysTrue()','AllwaysTrue()','',,,99,'AllwaysTrue()','','AllwaysTrue()',oPanelA06,_aHdPedCli,_aItPedCli)
	_oBrwEsq06:oBrowse:bLDblClick := {|| _aItPedCli[_oBrwEsq06:nAt,_nPosMARK] := IIf(_aItPedCli[_oBrwEsq06:nAt,_nPosMARK]=='LBOK', 'LBNO', 'LBOK') ,_oBrwEsq06:SetArray(_aItPedCli,.f.), _oBrwEsq06:Refresh(.t.) }
	_oBrwEsq06:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	// browse 07 - Filtro para Agrupadora
	_oBrwEsq07 := MsNewGetDados():New(000,000,3000,3000,Nil,'AllwaysTrue()','AllwaysTrue()','',,,99,'AllwaysTrue()','','AllwaysTrue()',oPanelA07,_aHdIdAgru,_aItIdAgru)
	_oBrwEsq07:oBrowse:bLDblClick := {|| _aItIdAgru[_oBrwEsq07:nAt,_nPosMARK] := IIf(_aItIdAgru[_oBrwEsq07:nAt,_nPosMARK]=='LBOK', 'LBNO', 'LBOK') ,_oBrwEsq07:SetArray(_aItIdAgru,.f.), _oBrwEsq07:Refresh(.t.) }
	_oBrwEsq07:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	// browse 08 - Filtro para Tipo de Operacoes
	_oBrwEsq08 := MsNewGetDados():New(000,000,3000,3000,Nil,'AllwaysTrue()','AllwaysTrue()','',,,99,'AllwaysTrue()','','AllwaysTrue()',oPanelA08,_aHdTpOper,_aItTpOper)
	_oBrwEsq08:oBrowse:bLDblClick := {|| _aItTpOper[_oBrwEsq08:nAt,_nPosMARK] := IIf(_aItTpOper[_oBrwEsq08:nAt,_nPosMARK]=='LBOK', 'LBNO', 'LBOK') ,_oBrwEsq08:SetArray(_aItTpOper,.f.), _oBrwEsq08:Refresh(.t.) }
	_oBrwEsq08:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	//Seta array do aCols do Objeto MsNewGetDados
	_oBrwEsq01:SetArray (_aColsOSF)
	ASORT(_aItRecHum, , , { | x,y | x[3] < y[3] } )
	_oBrwEsq02:SetArray (_aItRecHum)
	_oBrwEsq03:SetArray (_aItMaqEqu)
	ASORT(_aItRua, , , { | x,y | x[2] < y[2] } )
	_oBrwEsq04:SetArray (_aItRua)
	ASORT(_aItPedVen, , , { | x,y | x[2] < y[2] } )
	_oBrwEsq05:SetArray (_aItPedVen)
	ASORT(_aItPedCli, , , { | x,y | x[2] < y[2] } )
	_oBrwEsq06:SetArray (_aItPedCli)
	ASORT(_aItIdAgru, , , { | x,y | x[2] < y[2] } )
	_oBrwEsq07:SetArray (_aItIdAgru)
	_oBrwEsq08:SetArray (_aItTpOper)
	//Refresh no browse do MsNewGetDados
	_oBrwEsq01:ForceRefresh()
	_oBrwEsq02:ForceRefresh()
	_oBrwEsq03:ForceRefresh()
	_oBrwEsq04:ForceRefresh()
	_oBrwEsq05:ForceRefresh()
	_oBrwEsq06:ForceRefresh()
	_oBrwEsq07:ForceRefresh()
	_oBrwEsq08:ForceRefresh()

	// ativa a tela
	_oTelaFil:Activate(,,,.T.)
Return()

// ** Função para marcar todos os Itens da Grid.
Static Function sfSelAll(mvFolder)
	Local _wxy
	Default mvFolder := 0

	If mvFolder == 2
		// Operadores
		For _wxy := 1 To Len(_aItRecHum)
			_aItRecHum[_wxy,_nPosMARK]:= 'LBOK'
		Next _wxy
		_oBrwEsq02:SetArray (_aItRecHum,.T.)
		_oBrwEsq02:ForceRefresh()
	ElseIf mvFolder == 3
		//Equipamentos
		For _wxy := 1 To Len(_aItMaqEqu)
			_aItMaqEqu[_wxy,_nPosMARK]:= 'LBOK'
		Next _wxy
		_oBrwEsq03:SetArray (_aItMaqEqu,.T.)
		_oBrwEsq03:ForceRefresh()
	ElseIf mvFolder == 4
		//Ruas
		For _wxy := 1 To Len(_aItRua)
			_aItRua[_wxy,_nPosMARK]:= 'LBOK'
		Next _wxy
		_oBrwEsq04:SetArray (_aItRua,.T.)
		_oBrwEsq04:ForceRefresh()
	ElseIf mvFolder == 5
		//Pedido De Venda
		For _wxy := 1 To Len(_aItPedVen)
			_aItPedVen[_wxy,_nPosMARK]:= 'LBOK'
		Next _wxy
		_oBrwEsq05:SetArray (_aItPedVen,.T.)
		_oBrwEsq05:ForceRefresh()
	ElseIf mvFolder == 6

		//Pedido Cliente
		For _wxy := 1 To Len(_aItPedCli)
			_aItPedCli[_wxy,_nPosMARK]:= 'LBOK'
		Next _wxy
		_oBrwEsq06:SetArray (_aItPedCli,.T.)
		_oBrwEsq06:ForceRefresh()
	ElseIf mvFolder == 7
		//Agrupadora/DLN
		For _wxy := 1 To Len(_aItIdAgru)
			_aItIdAgru[_wxy,_nPosMARK]:= 'LBOK'
		Next _wxy
		_oBrwEsq07:SetArray (_aItIdAgru,.T.)
		_oBrwEsq07:ForceRefresh()
	EndIf

Return()

// ** Função para Desmarcar todos os Itens da Grid.
Static Function sfUnsAll(mvFolder)
	Local _wxy
	Default mvFolder := 0

	If mvFolder == 2
		// Operadores
		For _wxy := 1 To Len(_aItRecHum)
			_aItRecHum[_wxy,_nPosMARK]:= 'LBNO'
		Next _wxy
		_oBrwEsq02:SetArray (_aItRecHum,.T.)
		_oBrwEsq02:ForceRefresh()
	ElseIf mvFolder == 3
		//Equipamentos
		For _wxy := 1 To Len(_aItMaqEqu)
			_aItMaqEqu[_wxy,_nPosMARK]:= 'LBNO'
		Next _wxy
		_oBrwEsq03:SetArray (_aItMaqEqu,.T.)
		_oBrwEsq03:ForceRefresh()
	ElseIf mvFolder == 4
		//Ruas
		For _wxy := 1 To Len(_aItRua)
			_aItRua[_wxy,_nPosMARK]:= 'LBNO'
		Next _wxy
		_oBrwEsq04:SetArray (_aItRua,.T.)
		_oBrwEsq04:ForceRefresh()
	ElseIf mvFolder == 5
		//Pedido De Venda
		For _wxy := 1 To Len(_aItPedVen)
			_aItPedVen[_wxy,_nPosMARK]:= 'LBNO'
		Next _wxy
		_oBrwEsq05:SetArray (_aItPedVen,.T.)
		_oBrwEsq05:ForceRefresh()
	ElseIf mvFolder == 6
		//Pedido Cliente
		For _wxy := 1 To Len(_aItPedCli)
			_aItPedCli[_wxy,_nPosMARK]:= 'LBNO'
		Next _wxy
		_oBrwEsq06:SetArray (_aItPedCli,.T.)
		_oBrwEsq06:ForceRefresh()
	ElseIf mvFolder == 7
		//Agrupadora/DLN
		For _wxy := 1 To Len(_aItIdAgru)
			_aItIdAgru[_wxy,_nPosMARK]:= 'LBNO'
		Next _wxy
		_oBrwEsq07:SetArray (_aItIdAgru,.T.)
		_oBrwEsq07:ForceRefresh()
	EndIf

Return()

// ** Função acionada no Duplo Click da grid de OS finalizada(_oBrwEsq01) realiza a marcação da linha.
Static Function SfMarca()
	Local _Iy

	For _Iy := 1 To Len(_oBrwEsq01:aCOLS)
		If (_Iy == _oBrwEsq01:nAt ) // é a linha selecionada
			_aColsOSF[_Iy,_nPosMARK] := 'LBOK'
		Else
			_aColsOSF[_Iy,_nPosMARK] := 'LBNO'
		EndIf
		//		_aColsOSF[_Iy,_nPosMARK] := Iif(_aColsOSF[_Iy,_nPosMARK]=='LBOK','LBNO','LBOK')
	Next _Iy

	//Seta array do aCols do Objeto
	_oBrwEsq01:SetArray(_aColsOSF,.f.)
	// Refresh no browse
	_oBrwEsq01:Refresh( .T. )

Return()

// ** Função para limpar todos os itens selecionados para filtro.
Static Function SfLimpFilt()

	Local _wxy

	_aColsOSF[1,_nPosMARK] := 'LBOK'
	_aColsOSF[2,_nPosMARK] := 'LBNO'
	_aColsOSF[3,_nPosMARK] := 'LBNO'

	// Operadores
	For _wxy := 1 To Len(_aItRecHum)
		_aItRecHum[_wxy,_nPosMARK]:= 'LBNO'
	Next _wxy

	//Equipamentos
	For _wxy := 1 To Len(_aItMaqEqu)
		_aItMaqEqu[_wxy,_nPosMARK]:= 'LBNO'
	Next _wxy

	//Ruas
	For _wxy := 1 To Len(_aItRua)
		_aItRua[_wxy,_nPosMARK]:= 'LBNO'
	Next _wxy

	//Pedido De Venda
	For _wxy := 1 To Len(_aItPedVen)
		_aItPedVen[_wxy,_nPosMARK]:= 'LBNO'
	Next _wxy

	//Pedido Cliente
	For _wxy := 1 To Len(_aItPedCli)
		_aItPedCli[_wxy,_nPosMARK]:= 'LBNO'
	Next _wxy

	//Agrupadora/DLN
	For _wxy := 1 To Len(_aItIdAgru)
		_aItIdAgru[_wxy,_nPosMARK]:= 'LBNO'
	Next _wxy

	// deixa invisível a frase que tem filtros aplicados
	_oSayRoda2:lVisible := .F.

	//Seta array do aCols do Objeto MsNewGetDados
	_oBrwEsq01:SetArray (_aColsOSF,.T.)
	_oBrwEsq02:SetArray (_aItRecHum,.T.)
	_oBrwEsq03:SetArray (_aItMaqEqu,.T.)
	_oBrwEsq04:SetArray (_aItRua,.T.)
	_oBrwEsq05:SetArray (_aItPedVen,.T.)
	_oBrwEsq06:SetArray (_aItPedCli,.T.)
	_oBrwEsq07:SetArray (_aItIdAgru,.T.)
	//Refresh no browse do MsNewGetDados
	_oBrwEsq01:ForceRefresh()
	_oBrwEsq02:ForceRefresh()
	_oBrwEsq03:ForceRefresh()
	_oBrwEsq04:ForceRefresh()
	_oBrwEsq05:ForceRefresh()
	_oBrwEsq06:ForceRefresh()
	_oBrwEsq07:ForceRefresh()

Return()

// ** Função para aplicar os filtros selecionados pelo usurio.
Static Function SfApliFilt()
	// Filtro para não mostrar OS finalizadas conforme parametro.
	Local _cFiltro := ".T."
	local _cFltTpOpe := ""
	// Variavel para armazenar os numeros da OS que deverão ser filtradas.
	Local _cFilOS   := ""
	// Aplica filtro da OS Sim|Não
	Local _lFilOS   := .F.
	//Variaveis para o For
	Local _wxy,_wxx := 0
	//Controle de numeração da OS
	Local _aNumOS   := {}
	//Variavel temporaria.
	Local _nPos     := 0

	// Operadores
	//Percorre a Grid dos Operadores pegando os marcados adicionando as OS que estão vinculados para aplicar no filtro.
	For _wxy := 1 To Len(_aItRecHum)

		If _aItRecHum[_wxy,_nPosMARK]=='LBOK'
			// deixa visível a frase que tem filtros aplicados
			_oSayRoda2:lVisible := .T.

			For _wxx := 1 To Len(_aOsRecHum)

				If _aItRecHum[_wxy,2] == _aOsRecHum[_wxx,1]
					// verifica se o OS ja esta na lista
					_nPos := aScan(_aNumOS,_aOsRecHum[_wxx,3])
					// Adiciona OS na variavel
					If (_nPos == 0)
						Aadd(_aNumOS,_aOsRecHum[_wxx,3])
						_cFilOS +=  Alltrim(_aOsRecHum[_wxx,3]) + ","
						_lFilOS := .T.
					EndIf
				EndIf
			Next _wxx
		EndIf
	Next _wxy

	//Equipamentos
	//Percorre a Grid dos Equipamentos pegando os marcados e adicionando as OS que estão vinculados para aplicar no filtro.
	For _wxy := 1 To Len(_aItMaqEqu)

		If _aItMaqEqu[_wxy,_nPosMARK]=='LBOK'
			// deixa visível a frase que tem filtros aplicados
			_oSayRoda2:lVisible := .T.
			For _wxx := 1 To Len(_aOsMaqEqu)

				If _aItMaqEqu[_wxy,2] == _aOsMaqEqu[_wxx,1]
					// verifica se o OS ja esta na lista
					_nPos := aScan(_aNumOS,_aOsMaqEqu[_wxx,3])
					// Adiciona OS na variavel

					If (_nPos == 0)
						Aadd(_aNumOS,_aOsMaqEqu[_wxx,3])
						_cFilOS +=  Alltrim(_aOsMaqEqu[_wxx,3]) + ","
						_lFilOS := .T.
					EndIf
				EndIf
			Next _wxx
		EndIf
	Next _wxy

	//Ruas
	//Percorre a Grid das Ruas pegando os marcados e adicionando as OS que estão vinculados para aplicar no filtro.
	For _wxy := 1 To Len(_aItRua)

		If _aItRua[_wxy,_nPosMARK]=='LBOK'
			// deixa visível a frase que tem filtros aplicados
			_oSayRoda2:lVisible := .T.
			For _wxx := 1 To Len(_aOsRua)

				If _aItRua[_wxy,2] == _aOsRua[_wxx,1]
					// verifica se o OS ja esta na lista
					_nPos := aScan(_aNumOS,_aOsRua[_wxx,2])
					// Adiciona OS na variavel

					If (_nPos == 0)
						Aadd(_aNumOS,_aOsRua[_wxx,2])
						_cFilOS +=  Alltrim(_aOsRua[_wxx,2]) + ","
						_lFilOS := .T.
					EndIf
				EndIf
			Next _wxx
		EndIf
	Next _wxy

	//Pedido De Venda
	//Percorre a Grid dos Pedido De Venda pegando os marcados e adicionando as OS que estão vinculadas para aplicar no filtro.
	For _wxy := 1 To Len(_aItPedVen)

		If _aItPedVen[_wxy,_nPosMARK]=='LBOK'
			// deixa visível a frase que tem filtros aplicados
			_oSayRoda2:lVisible := .T.
			For _wxx := 1 To Len(_aOsPedVen)

				If _aItPedVen[_wxy,2] == _aOsPedVen[_wxx,1]
					// verifica se o OS ja esta na lista
					_nPos := aScan(_aNumOS,_aOsPedVen[_wxx,2])
					// Adiciona OS na variavel

					If (_nPos == 0)
						Aadd(_aNumOS,_aOsPedVen[_wxx,2])
						_cFilOS +=  Alltrim(_aOsPedVen[_wxx,2]) + ","
						_lFilOS := .T.
					EndIf
				EndIf
			Next _wxx
		EndIf
	Next _wxy

	//Pedido Cliente
	//Percorre a Grid dos Pedido Do cliente pegando os marcados e adicionando as OS que estão vinculadas para aplicar no filtro.
	For _wxy := 1 To Len(_aItPedCli)

		If _aItPedCli[_wxy,_nPosMARK]=='LBOK'
			// deixa visível a frase que tem filtros aplicados
			_oSayRoda2:lVisible := .T.
			For _wxx := 1 To Len(_aOsPedCli)

				If _aItPedCli[_wxy,2] == _aOsPedCli[_wxx,1]
					// verifica se o OS ja esta na lista
					_nPos := aScan(_aNumOS,_aOsPedCli[_wxx,2])
					// Adiciona OS na variavel

					If (_nPos == 0)
						Aadd(_aNumOS,_aOsPedCli[_wxx,2])
						_cFilOS +=  Alltrim(_aOsPedCli[_wxx,2]) + ","
						_lFilOS := .T.
					EndIf
				EndIf
			Next _wxx
		EndIf
	Next _wxy

	//Agrupadora/DLN
	//Percorre a Grid das Agrupadora pegando os marcados e adicionando as OS que estão vinculadas para aplicar no filtro.
	For _wxy := 1 To Len(_aItIdAgru)

		If _aItIdAgru[_wxy,_nPosMARK]=='LBOK'
			// deixa visível a frase que tem filtros aplicados
			_oSayRoda2:lVisible := .T.
			For _wxx := 1 To Len(_aOsIdAgru)

				If _aItIdAgru[_wxy,2] == _aOsIdAgru[_wxx,1]
					// verifica se o OS ja esta na lista
					_nPos := aScan(_aNumOS,_aOsIdAgru[_wxx,2])
					// Adiciona OS na variavel

					If (_nPos == 0)
						Aadd(_aNumOS,_aOsIdAgru[_wxx,2])
						_cFilOS +=  Alltrim(_aOsIdAgru[_wxx,2]) + ","
						_lFilOS := .T.
					EndIf
				EndIf
			Next _wxx
		EndIf
	Next _wxy

	//Atualiza a variavel com as OS para aplicar no filtro.
	If (_lFilOS)
		// deixa visível a frase que tem filtros aplicados
		_oSayRoda2:lVisible := .T.
		_cFilOS := SubStr(_cFilOS,1,Len(_cFilOS)-1)
	EndIf

	// incrementa filtro de OS finalziada
	If (_oBrwEsq01:aCOLS[2,_nPosMARK] == 'LBOK')   // NÃO
		// deixa visível a frase que tem filtros aplicados
		_oSayRoda2:lVisible := .T.

		_cFiltro += ".And.(_cAlTrOrdServ)->Z06_STATUS <> 'FI'"
		_cFiltro += ".And.(_cAlTrOrdServ)->Z06_STATUS <> 'CA'"
	Elseif (_oBrwEsq01:aCOLS[3,_nPosMARK] == 'LBOK')  // Apenas finalizadas
		// deixa visível a frase que tem filtros aplicados
		_oSayRoda2:lVisible := .T.

		_cFiltro += ".And.(_cAlTrOrdServ)->Z06_STATUS == 'FI'"
	EndIf

	// varre tipos de operacoes
	For _wxy := 1 to Len(_oBrwEsq08:aCOLS)
		// verifica se esta selecionado
		If (_aItTpOper[_wxy][_nPosMARK]=='LBOK')
			_cFltTpOpe += AllTrim(_aItTpOper[_wxy][2])+"/"
		EndIf
	Next _wxy

	If ( ! Empty(_cFltTpOpe) )
		// deixa visível a frase que tem filtros aplicados
		_oSayRoda2:lVisible := .T.

		_cFiltro += ".And.AllTrim((_cAlTrOrdServ)->DSC_OPER) $ '"+_cFltTpOpe+"'"
	EndIf

	If (_lFilOS)
		MsgRun("Aplicando Filtros no Monitor de Serviços...", "Aguarde...", {|| CursorWait(), sfSelDados(.f.,_cFilOS), CursorArrow()})
	Else
		MsgRun("Aplicando Filtros no Monitor de Serviços...", "Aguarde...", {|| CursorWait(), sfSelDados(.f.), CursorArrow()})
	EndIf

	//Aplica Filtro conforme parametro.
	(_cAlTrOrdServ)->(dbSetFilter({|| &(_cFiltro) },_cFiltro))
	(_cAlTrOrdServ)->(dbGoTop())

	// atualiza browse
	_oBrwOrdServ:oBrowse:Refresh()

	// atualiza contador do rodapé
	_nQtdRoda1 := 0
	While (_cAlTrOrdServ)->(!EoF())
		_nQtdRoda1++
		(_cAlTrOrdServ)->(DbSkip())
	Enddo
	(_cAlTrOrdServ)->(dbGoTop())
	_oSayRoda1:Refresh()

	// fecha tela de filtros
	_oTelaFil:END()

Return()

// ** função para executar a exclusão de OS ** //
Static Function sfDelOS(mvNumos)

	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"Z05", "Z06", "Z07", "Z08", "Z09", "Z11", "Z18", "SZZ", "Z57"})

	// variavel de controle
	local _lRet := .T.
	// variaveis para seek
	local _cSeekZ06 := ""
	local _cSeekZ07 := ""
	local _cSeekZ08 := ""
	local _cSeekZ09 := ""
	local _cSeekZ18 := ""
	local _cSeekZ43 := ""

	// número da OS
	local _cNumos   := ""
	// tipo da OS
	local _cTpOper  := ""
	// log de erros
	local _cLog := ""
	// cesv
	local _cCesv := ""
	// onda de separacao
	local _cNrOndSep := ""
	local _cStAtOnda := ""

	// preparo as informações das tabelas envolvidas
	// OS

	dbSelectArea("Z05")
	Z05->( dbSetOrder(1) ) //1-Z05_FILIAL+Z05_NUMOS
	If Z05->( dbSeek( xFilial("Z05") + mvNumos) )
		// atualiza variavel com base na OS encontrada
		_cTpOper   := Z05->Z05_TPOPER
		_cCesv     := Z05->Z05_CESV
		_cNrOndSep := Z05->Z05_ONDSEP
	Else
		// mensagem para usuario
		MsgInfo("OS não encontrada no sistema. Comunique o setor de TI! Info: OS não encontrada na tabela Z05")
		// variavel de controle
		_lRet := .F.
		// retorno
		Return (_lRet)
	EndIf

	// validacao de opcao para exclusao
	If ( _cTpOper == "S" ) .And. ( ! Empty(Z05->Z05_CARGA) )
		// mensagem para usuario
		Help( ,, 'TWMSA009.F03.001',, "Não é possível a exclusão desta Ordem de Serviço. Utilize a opção de estorno na rotina de geração de mapa de expedição.", 1, 0 )
		// variavel de controle
		_lRet := .F.
		// retorno
		Return (_lRet)
	EndIf

	// se tiver a SZZ valida as informações para estornar
	If ( ! Empty(Z05->Z05_CESV) )
		dbSelectArea( "SZZ" )
		SZZ->( dbSetOrder(1) ) // ZZ_FILIAL, ZZ_CESV, R_E_C_N_O_, D_E_L_E_T_
		If ( SZZ->( dbSeek( xFilial( "SZZ") + Z05->Z05_CESV ) ) )
			// valida status do CESV
			If (SZZ->ZZ_STATUS == "10") // 10-REGISTRO DE SAIDA
				// mensagem de aviso
				_cLog += "IMPEDIMENTO: CESV " + Z05->Z05_CESV + " com saída realizada" + CRLF
				_cLOG += "SOLUÇÃO: Estorne a saída do CESV " + CRLF
				// atualiza variável de controle
				_lRet := .F.
			EndIf
		EndIf
	EndIf

	// validacao de opcao para exclusao
	If ( _cTpOper == "S" ) .And. ( ! Empty(Z05->Z05_CESV) )

		// programacao de carregamento
		dbSelectArea( "Z43" )
		Z43->( dbSetOrder(3) ) // 3 - Z43_FILIAL, Z43_NUMOS, Z43_CARGA, Z43_PEDIDO, Z43_CESV
		Z43->( dbSeek( _cSeekZ43 := xFilial( "Z43") + mvNumos ) )

		// analisa todas as linhas do planejamento
		While Z43->( ! Eof() ) .And. ((Z43->Z43_FILIAL + Z43->Z43_NUMOS) == _cSeekZ43)

			// verifica se foi realizada
			If (Z43->Z43_STATUS == "R")
				// mensagem de aviso
				_cLog += "IMPEDIMENTO: CESV " + Z05->Z05_CESV + " com carregamento realizado" + CRLF
				_cLOG += "SOLUÇÃO: Estorne o carregamento da CESV " + CRLF
				// atualiza variável de controle
				_lRet := .F.
			EndIf

			// proximo item
			Z43->( dbSkip() )
		EndDo

	EndIf

	// DADOS DA OS
	dbSelectArea("Z06")
	Z06->( dbSetOrder(1) ) //1-Z06_FILIAL+Z06_NUMOS
	Z06->(dbSeek( _cSeekZ06 := xFilial("Z06") + mvNumos ))

	// varre todos os itens da ordem de servico
	While Z06->( ! Eof() ) .And. ((Z06->Z06_FILIAL + Z06->Z06_NUMOS) == _cSeekZ06)
		// status FI-Finalizada
		If (Z06->Z06_STATUS == "FI")
			// mensagem de aviso
			_cLog += "A sequência "+Z06->Z06_SEQOS+" da OS já foi finalizada" + CRLF
			_cLog += CRLF
			// atualiza variável de controle
			_lRet := .F.
			// sai do loop
			Exit
		EndIf

		// para servico T03-Cancelamento de Carregamento
		If (Z06->Z06_SERVIC == "T03")        //se for cancelamento de carregamento
			// mensagem de aviso
			_cLog += "Não é permitido excluir uma OS de cancelamento de carregamento "
			_cLog += CRLF
			// atualiza variável de controle
			_lRet := .F.
			// sai do loop
			Exit
		EndIF

		// proximo item
		Z06->(dbSkip())
	EndDo

	// validações para OS de Recebimento
	If (_cTpOper == "E")

		// query para pesquisa de etiquetas já impressas
		_cQuery := " SELECT COUNT(*) IT_ETQ FROM " + RetSqlTab("Z11") + " (nolock) "
		_cQuery += " WHERE " + RetSqlCond("Z11")
		_cQuery += " AND Z11_CESV = '" + _cCesv + "' "

		memowrit("C:\query\TWMSA009_sfDelOS_etiquetas_z11.txt",_cQuery)

		// se encontrou algum registro, não deixa prosseguir
		If (U_FtQuery(_cQuery) > 0)
			_cLog += "IMPEDIMENTO: Foram encontradas etiquetas impressas para essa OS" + CRLF
			_cLOG += "SOLUÇÃO: Exclua as etiquetas para a OS informada" + CRLF
			_cLog += CRLF
			// atualiza variável de controle
			_lRet := .F.
		EndIf

	EndIf

	// validações para OS de Recebimento
	If (_cTpOper == "E")

		// CONFERÊNCIA
		dbSelectArea("Z07")
		Z07->( dbSetOrder(1) ) //1-Z07_FILIAL+Z07_NUMOS
		If (Z07->( _cSeekZ07 := dbSeek( xFilial("Z07") + mvNumos )))

			// mensagem de aviso
			_cLog += "IMPEDIMENTO: Foram encontrados itens conferidos nessa OS" + CRLF
			_cLOG += "SOLUÇÃO: Estorne os itens conferidos na OS informada" + CRLF
			_cLog += CRLF
			// atualiza variável de controle
			_lRet := .F.
		EndIf
	EndIf

	// validações de mapa de armazenagem / expedicao
	dbSelectArea("Z08")
	Z08->( dbSetOrder(1) ) //1-Z08_FILIAL+Z08_NUMOS
	If (Z08->( dbSeek( _cSeekZ08 := xFilial("Z08")+mvNumos )))

		// para OS de Entrada valida se há mapa gerado
		If (_cTpOper == "E")

			// mensagem de aviso
			_cLog += "IMPEDIMENTO: Foi encontrado Mapa de Armazenagem referente a essa OS" + CRLF
			_cLog += "SOLUÇÃO: Estorne o Mapa de Armazenagem dessa OS" + CRLF
			_cLog += CRLF
			// atualiza variável de controle
			_lRet := .F.

		ElseIf (_cTpOper $ "I/S") // para OS Interna ou Expedicao (por onda), valida se algum movimento já foi realizado na OS
			// prepara query
			_cQuery := "SELECT COUNT(Z08_PALLET) AS QTD "
			_cQuery += " FROM " + RetSqlTab("Z08") + " (nolock) "
			_cQuery += " WHERE " + RetSqlCond("Z08")
			_cQuery += " AND Z08_NUMOS = '" + mvNumos + "' "
			_cQuery += " AND ( Z08_DTINIC != '' OR Z08_HRINIC != '' OR Z08_USUARI != '' OR Z08_STATUS NOT IN ('P','O') )"

			If (U_FTQuery(_cQuery) != 0)
				// mensagem de aviso
				_cLog += "IMPEDIMENTO: Movimentos já iniciados para essa OS" + CRLF + CRLF

				// atualiza variável de controle
				_lRet := .F.
			Endif

		EndIf
	EndIf

	// passou da validação, deleta os registros
	If (_lRet)

		// starto a transação
		BeginTran()

		// deleto a Z05
		dbSelectArea("Z05")
		Z05->( dbSetOrder(1) ) //1-Z05_FILIAL+Z05_NUMOS
		If ( Z05->( dbSeek( xFilial("Z05") + mvNumos) ) )
			RecLock("Z05",.F.)
			Z05->(dbDelete())
			MsUnlock()
		EndIf

		// deleto a Z06
		dbSelectArea("Z06")
		Z06->( dbSetOrder(1) ) //1-Z06_FILIAL+Z06_NUMOS
		If ( Z06->(dbSeek( _cSeekZ06 := xFilial("Z06") + mvNumos )) )
			// varre todos os itens da ordem de servico
			While Z06->(!Eof()) .And. ((Z06->Z06_FILIAL + Z06->Z06_NUMOS) == _cSeekZ06)
				// exclui registro
				RecLock("Z06",.F.)
				Z06->(dbDelete())
				MsUnlock()
				// proximo item
				Z06->(dbSkip())
			EndDo
		EndIf

		// para ordens de servico INTERNA e EXPEDICAO (por onda)
		If (_cTpOper $ "I/S")

			// deleto a Z08
			dbSelectArea("Z08")
			Z08->( dbSetOrder(1) ) //1-Z08_FILIAL+Z08_NUMOS
			If ( Z08->( dbSeek( _cSeekZ08 := xFilial("Z08")+mvNumos ) ) )

				// varre todos os itens do mapa de armazenagem / expedicao
				While Z08->( ! Eof() ) .And. ( (Z08->Z08_FILIAL + Z08->Z08_NUMOS) == _cSeekZ08 )
					// exclui registro
					RecLock( "Z08", .F. )
					Z08->( dbDelete() )
					Z08->( MsUnlock() )
					// proximo item
					Z08->( dbSkip() )
				EndDo
			EndIf
		EndIf

		// deleto a Z09
		If ( ! Empty(_cCesv) )
			// motivos de interrpcao
			dbSelectArea("Z09")
			Z09->( dbSetOrder(1) ) //1-Z09_FILIAL+Z09_CESV
			If ( Z09->(dbSeek( _cSeekZ09 := xFilial("Z09") + _cCesv )) )
				// varre todos os itens
				While Z09->(!Eof()) .And. ((Z09->Z09_FILIAL + Z09->Z09_CESV) == _cSeekZ09)
					// exclui registro
					RecLock("Z09",.F.)
					Z09->(dbDelete())
					MsUnlock()
					// proximo item
					Z09->(dbSkip())
				EndDo
			EndIf
		EndIf

		//deleto a Z18
		dbSelectArea("Z18")
		Z18->( dbSetOrder(1) ) //1-Z18_FILIAL+Z18_NUMOS
		If ( Z18->( dbSeek( _cSeekZ18 := xFilial("Z18") + mvNumos )) )
			// varre todos os operadores
			While Z18->(!Eof()) .And. ((Z18->Z18_FILIAL + Z18->Z18_NUMOS) == _cSeekZ18)
				// exclui registro
				RecLock("Z18",.F.)
				Z18->(dbDelete())
				MsUnlock()
				// proximo item
				Z18->(dbSkip())
			EndDo
		EndIf

		// se tiver a SZZ valida as informações para estornar
		If ( ! Empty(Z05->Z05_CESV) )
			dbSelectArea( "SZZ" )
			SZZ->( dbSetOrder(1) ) // ZZ_FILIAL, ZZ_CESV, R_E_C_N_O_, D_E_L_E_T_
			If ( SZZ->( dbSeek( xFilial( "SZZ") + Z05->Z05_CESV ) ) )
				RecLock( "SZZ", .F. )
				SZZ->ZZ_STATUS := "06" // 06 - LIBERADO / NO PÁTIO
				MsUnlock()

				// insere o log do estorno na SZZ
				U_FtGeraLog(SZZ->ZZ_FILIAL, "SZZ", SZZ->ZZ_FILIAL + SZZ->ZZ_CESV, "CESV Estornado Automaticamente -> Rotina WMSA009H -> Estorno de OS", "WMS")
			EndIf
		EndIf

		// atualiza status da onda de separacao
		If ( ! Empty(_cNrOndSep) )

			// posiciona na onda de separacao selecionada
			dbSelectArea("Z57")
			Z57->(dbSetOrder(1)) // 1 - Z57_FILIAL, Z57_CODIGO
			If Z57->(dbSeek( xFilial("Z57") + _cNrOndSep ))

				// armazena status atual da onda
				_cStAtOnda := Z57->Z57_STATUS

				// atualiza campo de controle
				RecLock("Z57", .F.)
				Z57->Z57_STATUS := "02" // 02-Liberado para Integração
				Z57->(MsUnLock())

				// gera log
				U_FtGeraLog(xFilial("Z57"), "Z57", Z57->Z57_FILIAL + Z57->Z57_CODIGO, "ESTORNO MAPA - Mapa de Expedição estornada (Atual: " + _cStAtOnda + "| Novo: 02)", "WMS", "")

			EndIf
		EndIf

		// programacao de carregamento
		dbSelectArea( "Z43" )
		Z43->( dbSetOrder(3) ) // 3 - Z43_FILIAL, Z43_NUMOS, Z43_CARGA, Z43_PEDIDO, Z43_CESV
		Z43->( dbSeek( _cSeekZ43 := xFilial( "Z43") + mvNumos ) )

		// analisa todas as linhas do planejamento
		While Z43->( ! Eof() ) .And. ((Z43->Z43_FILIAL + Z43->Z43_NUMOS) == _cSeekZ43)

			// verifica se foi realizada
			If (Z43->Z43_STATUS != "R")
				// exclui registro
				RecLock("Z43", .F.)
				Z43->(dbDelete())
				MsUnlock()

			EndIf

			// proximo item
			Z43->( dbSkip() )
		EndDo

		// commita a transação
		EndTran()
	EndIf

	// mensagens de retorno
	If (_lRet)
		MsgInfo("OS excluída com sucesso!")
	Else
		_cLog += "Exclusão não permitida!"
		HS_MsgInf("LOG:" + CRLF + _cLog, "Log da Exclusão da OS","Inconsistência na Exclusão da OS " + mvNumos)
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni, .T.)
	RestArea(_aAreaAtu)

Return( _lRet )

// ** funcao que confirma o movimento de exclusão
User Function WMSA009H(mvNumos, mvRotAuto)

	// variavel de retorno
	Local _lRet := .F.

	// valores padroes
	Default mvRotAuto := .F.

	// mensagem de confirmacao
	_lRet := (MsgYesNo("Deseja Excluir a OS "+mvNumos+"?","Atenção"))

	If (_lRet)

		// mostra informação de processando para o usuário
		MsgRun("Analisando dados...", "Aguarde", {|| _lRet := sfDelOS(mvNumos) })

		// atualiza dadod do browse
		If ( ! mvRotAuto )
			sfRfrDados( .F. )
		EndIf
	EndIf

Return (_lRet)

// ** função usada para excluir etiquetas **//
User Function WMSA009J (mvNumos, mvCesv, mvTpEtiq)

	// variavel de retorno
	local _lRet := .T.
	// variavel para pesquisa
	local _cQuery := ""
	// seek na Z05
	local _cSeekZ05 := ""
	// lista de recno para deletar
	local _aRecno := {}
	// controle de loop
	local _nX := 0

	If (_lRet)
		// query para pesquisa de etiquetas já utilizadas
		_cQuery := " SELECT COUNT(*) IT_ETQ FROM "+RetSqlName("Z11")+" Z11 (nolock)  "
		_cQuery += " WHERE "+RetSqlCond("Z11")
		_cQuery += " AND Z11_TIPO = '"+mvTpEtiq+"' "
		_cQuery += " AND Z11_CESV = '"+mvCesv+"' "
		_cQuery += " AND EXISTS ( "
		_cQuery += " SELECT * FROM "+RetSqlName("Z07")+" Z07 (nolock)  "
		_cQuery += " WHERE "+RetSqlCond("Z07")
		_cQuery += " AND ( Z07_ETQPRD = Z11_CODETI OR Z07_ETQVOL = Z11_CODETI )
		_cQuery += " AND Z07_NUMOS = '"+mvNumos+"' ) "

		memowrit("C:\query\WMSA009J.txt",_cQuery)

		// se encontrou algum registro, não deixa prosseguir
		If (U_FtQuery(_cQuery) > 0)
			U_FtWmsMsg("As etiquetas já foram utilizadas em conferência! Favor estornar a conferência para poder excluir as etiquetas!","Atenção")
			_lRet := .F.
		EndIf
	EndIf

	// se passou pela validação de etiquetas utilizadas, prossegue com a exclusão
	If (_lRet)
		// pego os recno para deletar
		_cQuery := " SELECT R_E_C_N_O_ FROM "+RetSqlName("Z11")+" Z11 (nolock)  WHERE "+RetSqlCond("Z11")+" AND Z11_CESV = '"+mvCesv+"' AND Z11_TIPO = '"+mvTpEtiq+"' "

		// jogo os dados da query para o array
		_aRecno := U_SqlToVet(_cQuery)

		If (Len(_aRecno) > 0)
			// inicio a transação
			BeginTran()

			// varro array com todos os registros
			For _nX := 1 to Len(_aRecno)

				// deleto as etiquetas
				dbSelectArea("Z11")
				Z11->(dbGoTo( _aRecno[_nX] ))
				RecLock("Z11")
				Z11->(dbDelete())
				Z11->(MsUnLock())

			Next _nX

			// comita a transação
			EndTran()

			// mensagem pro usuário
			U_FtWmsMsg("Etiquetas excluídas com sucesso!","Atenção")

		Else

			// mensagem pro usuário
			U_FtWmsMsg("Não foram encontradas etiquetas com a informação da OS: "+mvNumos,"Atenção")
			// retorno da variavel
			_lRet := .F.
		EndIf

	EndIf
Return (_lRet)

// ** função usada para excluir vínculo da NF com CESV ** //
Static Function sfExclVincNf ()

	// variável de retorno
	local _lRet     := .T.
	local _cSeekZ04 := ""

	// pergunto ao user se quer excluir
	_lRet := MsgYesNo("Deseja excluir o vínculo do documento fiscal?")

	If (_lRet)
		// valido se existe OS em aberto
		dbSelectArea("Z05")
		Z05->( dbSetOrder(2) ) // FILIAL+CESV
		If ( Z05->( dbSeek( xFilial("Z05")+SZZ->ZZ_CESV ) ) )
			MsgAlert("OS "+Z05->Z05_NUMOS+" vinculada ao CESV "+SZZ->ZZ_CESV+". Favor excluir a OS antes de excluir o vínculo do documento fiscal.")
			_lRet := .F.
		EndIf
	EndIf

	If (_lRet)
		// posiciono nos registros a serem deletados
		dbSelectArea("Z04")
		Z04->( dbSetOrder(1) ) // FILIAL+CESV
		If ( Z04->( dbSeek( _cSeekZ04 := xFilial("Z04")+SZZ->ZZ_CESV ) ) )
			// starta a transação
			BeginTran()

			While Z04->(!Eof()) .And. (Z04->(Z04_FILIAL+Z04_CESV) == _cSeekZ04)

				// deleto os registros encontrados
				Reclock("Z04")
				Z04->( dbDelete() )
				MsUnlock()

				// proximo item
				Z04->(dbSkip())
			EndDo

			// corrigi o status do CESV para novo lançamento do vínculo fiscal
			Reclock("SZZ")
			SZZ->ZZ_STATUS = "02" // Veículo liberado/ No Pátio
			MsUnlock()

			// encerra a transação
			EndTran()
		Else
			// caso não encontrou nenhum vínculo
			MsgAlert("Não foram encontrados vínculos de documento fiscal para o CESV solicitado.")
			_lRet := .F.
		EndIf
	EndIf

	If (_lRet)
		MsgInfo("Vínculo(s) removido(s) com sucesso!")
	EndIf

Return (_lRet)

// ** funcao para definicao de novos parametros
Static Function sfDefParam()

	// apresenta perguntas na tela
	If ! Pergunte(_cPerg,.t.)
		Return
	EndIf

	// atualiza as variaveis
	mvDataDe   := mv_par01
	mvDataAte  := mv_par02
	mvCliDe    := mv_par03
	mvCliAte   := mv_par04
	mvNumOSDe  := mv_par05
	mvNumOSAte := mv_par06

	// atualiza os dados
	sfRfrDados(.f.)

Return

// ** função para selecionar ou deselecionar todos os endereços ** //
Static Function sfMarkAllTrb(mvBrw)

	// vou varrer o arquivo de trabalho
	While (_cAlTrbMov)->(!Eof())
		// seleciona os registros
		If (Empty((_cAlTrbMov)->IT_OK))
			(_cAlTrbMov)->IT_OK := _cMarca
		Else
			(_cAlTrbMov)->IT_OK := ""
		EndIf

		// próximo valor
		(_cAlTrbMov)->(dbSkip())
	EndDo
	// atualizo o browse
	If (mvBrw <> nil)
		mvBrw:oBrowse:Refresh()
	EndIf
	// vai pro primeiro registro
	(_cAlTrbMov)->(dbGoTop())
Return

// ** funcao que confirma o movimento de exclusão ** //
User Function WMSA009I(mvNumos, mvRotAuto)

	// variavel de retorno
	Local _lRet := .T.
	Default mvRotAuto := .F.

	If (_lRet)

		// mostra informação de processando para o usuário
		MsgRun("Analisando dados...", "Aguarde", {|| _lRet := sfTelaAbrOS(mvNumos) })

		// atualiza dados do browse
		If (mvRotAuto)
			sfRfrDados(.F.)
		EndIf
	EndIf

Return (_lRet)

// ** função para reabrir OS ** //
Static Function sfTelaAbrOS(mvNumOS)

	// variavel de retorno
	local _lRet := .t.
	// area inicial
	local _aArea := GetArea()
	// seeks
	local _cSeekZ05 := ""
	local _cSeekZ06 := ""
	// array com serviços da OS
	local _aServOSFin := {}
	// objetos locais
	local _oBrwOS, _oDlgOS, _oPnlBottom, _oBtGera, _oBtSair, _oBtMarkAll
	// controle de loop
	local _nX := 0
	local _cDescTrf := ""
	local _cDescSrv := ""
	// largura da tela
	local _nDlgLarg
	// altura da tela
	local _nDlgAltu
	// controle da tela
	local _lOk := .F.
	local _cTypScreen := "PC"

	// array que vai receber os dados
	local _aPedidos  := {}
	local _nNrPedido := {}
	// query para busca de pedidos
	local _cQuery   := ""

	// arrays do browse
	private _aHeadOS := {}
	private _aColsOS := {}

	default mvNumos := sfInfOS()

	// sai da tela, nenhuma OS foi informada
	If (Empty(mvNumos))
		Return .F.
	EndIf

	// definição do tamanho da tela
	_aSizeDlg := GetScreenRes()
	// tamanho padrão
	_nDlgLarg := 600
	_nDlgAltu := 400

	// redimensiona medidas da resolucao de tela para acesso pelo coletor
	If (_aSizeDlg[1] < 400)
		_nDlgLarg := 240
		_nDlgAltu := 320
		// tipo de tela
		_cTypScreen := "MOBILE"
	EndIf

	// posiciono no cabeçalho da OS
	dbSelectArea("Z05")
	Z05->( dbSetOrder(1) ) //FILIAL+NUMOS

	IF !(Z05->(dbSeek(_cSeekZ05 := xFilial("Z05") + mvNumOS)))
		U_FtWmsMsg("Erro crítico, OS " + mvNumOS + "não encontrada. TWMSA009 - sfTelaAbrOS")
		Return( .F. )
	EndIf

	//valida se existe TFAA / pedido de venda para a OS
	If ( ! Empty(Z05->Z05_PVTFAA) )
		U_FtWmsMsg("OS não pode ser reaberta pois possui TFAA gerado! Pedido de venda relacionado:" + Z05->Z05_PVTFAA)
		Return( .F. )
	Endif

	//só permite reabrir se for OS de entrada (E) pois não faz sentido reabrir OS que já foram expedidas (S)
	//e nem internas (I), onde neste caso, podem fazer outra para corrigir
	//	If ( ! Z05->Z05_TPOPER == "E")
	//		U_FtWmsMsg("ERRO: Só é possível reabrir OS de entrada (recebimento).")
	//		Return(.F.)
	//	Endif

	// só prossegue com
	If (_lRet)
		// posiciono nos serviços da OS
		dbSelectArea("Z06")
		Z06->( dbSetOrder(1) ) //FILIAL+NUMOS+SEQOS
		_lRet := Z06->( dbSeek( _cSeekZ06 := xFilial("Z06")+Z05->Z05_NUMOS ) )

		// para todos os registros daquela OS
		While (_lRet) .And. (Z06->( ! EoF()) ) .And. (Z06->(Z06_FILIAL+Z06_NUMOS) == _cSeekZ06)
			// valido as OS que estão finalizadas
			If (Z06->Z06_STATUS $ "FI_AN") .AND. ;
			!(Z06->Z06_STATUS == "FI" .AND. Z06->Z06_SERVIC == "015" .AND. Z06->Z06_TAREFA = "014" ) .AND.;
			!(Z06->Z06_SERVIC == "001" .AND. Z06->Z06_TAREFA = "002" ) .AND.; // não permite reabrir apanhe, não faz sentido.
			!(Z06->Z06_ATUEST == "N" .AND. Z06->Z06_SERVIC == "001")  // não permite reabrir caso já tenha expedido nota fiscal
				// descricao servico e tarefa
				_cDescTrf := POSICIONE("SX5", 1, xFilial("SX5") + "L4" + Z06->Z06_SERVIC, "X5_DESCRI")
				_cDescSrv := POSICIONE("SX5", 1, xFilial("SX5") + "L2" +  Z06->Z06_TAREFA, "X5_DESCRI")
				// adiciona os dados no array
				aAdd(_aServOSFin, { "LBOK", Z06->Z06_NUMOS, Z06->Z06_SEQOS, Z06->Z06_TAREFA , _cDescTrf, Z06->Z06_SERVIC, _cDescSrv, .F. } )
			EndIf

			// próximo serviço
			Z06->( dbSkip() )

		EndDo

		// se não encontrou nenhum registro finalizado
		If (Len(_aServOsFin) == 0)
			MsgAlert("Não foram encontradas sequências nesta OS aptas a serem reabertas!")
			_lRet := .F.
		Else
			// preenche aCols
			_aColsOS := _aServOSFin
		EndIf
	EndIf

	// mostro opções pro usuário dos serviços finalizados
	If (_lRet)

		// monta a tela
		_oDlgOS := MSDialog():New(000,000, _nDlgAltu, _nDlgLarg,"OS/Seq Finalizadas",,,.F.,,,,,,.T.,,,.T. )
		_oDlgOS:lMaximized := .F.
		// não fecha a tela com ESC
		_oDlgOS:lEscClose := .F.

		// cria o panel do rodapé
		_oPnlBottom := TPanel():New(000,000,nil,_oDlgOS,,.F.,.F.,,,000,020,.T.,.F. )
		_oPnlBottom:Align := CONTROL_ALIGN_TOP

		/* Browse dos Endereços A Abastecer */
		// header do browse de endereços a abastecer
		aAdd(_aHeadOS,{"Selecionar" ,'IT_OK'      ,'@BMP'                      ,4                      ,0, Nil, Nil, "C", Nil,"R" })
		aAdd(_aHeadOS,{"OS"         ,"Z06_NUMOS"  ,PesqPict("Z06","Z06_NUMOS") ,TamSx3("Z06_NUMOS")[1] ,0, Nil, Nil, "C", Nil,"R" })
		aAdd(_aHeadOS,{"SeqOS"      ,"Z06_SEQOS"  ,PesqPict("Z06","Z06_SEQOS") ,TamSx3("Z06_SEQOS")[1] ,0, Nil, Nil, "C", Nil,"R" })
		aAdd(_aHeadOS,{"Tarefa"     ,"Z06_TAREFA" ,PesqPict("Z06","Z06_TAREFA"),TamSx3("Z06_TAREFA")[1],0, Nil, Nil, "C", Nil,"R" })
		aAdd(_aHeadOS,{"Desc.Trf"   ,"X5_DESCRI"  ,PesqPict("SX5","X5_DESCRI") ,TamSx3("X5_DESCRI")[1] ,0, Nil, Nil, "C", Nil,"R" })
		aAdd(_aHeadOS,{"Serviço"    ,"Z06_SERVIC" ,PesqPict("Z06","Z06_SERVIC"),TamSx3("Z06_SERVIC")[1],0, Nil, Nil, "C", Nil,"R" })
		aAdd(_aHeadOS,{"Desc.Srv"   ,"X5_DESCRI"  ,PesqPict("SX5","X5_DESCRI") ,TamSx3("X5_DESCRI")[1] ,0, Nil, Nil, "C", Nil,"R" })

		// browse com os detalhes dos endereços a abastercer
		_oBrwOS := MsNewGetDados():New(000,000,999,999,,'AllwaysTrue()','AllwaysTrue()','',,,,'AllwaysTrue()','','AllwaysTrue()',_oDlgOS,_aHeadOS,_aColsOS)
		_oBrwOS:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
		_oBrwOS:oBrowse:bLDblClick := {|| IIF( _aColsOS[_oBrwOS:nAt, Len(_aHeadOS)+1] == .F.,_oBrwOS:aCOLS[_oBrwOS:nAt,1] := IIF(_oBrwOS:aCOLS[_oBrwOS:nAt,1]=='LBOK','LBNO','LBOK'), Nil)}

		// marcar todos
		_oBtMarkAll := TBtnBmp2():New(001,001,040,040,"UNSELECTALL",,,,{|| sfMarkAll(_oBrwOS, Len(_aHeadOS)+1)  }, _oPnlBottom,"Marcar/Desmarcar Todos",,.T. )
		_oBtMarkAll:Align := CONTROL_ALIGN_LEFT

		// botão que irá gerar a OS para alimentar os endereços
		_oBtGera := TBtnBmp2():New(001,001,040,040,"OK",,,,{|| _lRet := sfAbrOS(mvNumos, _oBrwOS, _cTypScreen), Iif(_lRet, {_lOk := .T., _oDlgOS:END()}, Nil) },_oPnlBottom,"Reabrir OS",,.T. )
		_oBtGera:Align := CONTROL_ALIGN_LEFT

		// botão que irá sair da rotina
		_oBtSair := TBtnBmp2():New(001,001,040,040,"FINAL",,,,{|| _lRet := .F., IiF(MsgYesNo("Desejar Sair?"), {_lOk := .T., _oDlgOS:END()}, Nil) },_oPnlBottom,"Sair",,.T. )
		_oBtSair:Align := CONTROL_ALIGN_LEFT

		// ativacao da tela
		_oDlgOS:Activate(,,,.T.,{|| _lOk })

		// se deu ok, continua na rotina
		If (_lRet)
			// varro o acols pra validar as informações
			For _nX := 1 to Len(_oBrwOS:aCols)
				// se o registro não estiver deletado
				If (_oBrwOS:aCols[_nX][Len(_aHeadOS)+1] == .F.)
					// somente os selecionados
					If (_oBrwOS:aCols[_nX][1] == "LBOK")

						// posiciono no cabecalho da ordem de servico
						dbSelectArea("Z05")
						Z05->( dbSetOrder(1) ) // 1 - Z05_FILIAL, Z05_NUMOS
						Z05->( dbSeek( _cSeekZ05 := xFilial("Z05") + _oBrwOS:aCols[_nX][2] ) )

						// posiciono no item/sequencia da ordem de servico
						dbSelectArea("Z06")
						Z06->( dbSetOrder(1) ) //FILIAL+NUMOS+SEQOS
						Z06->( dbSeek( _cSeekZ06 := xFilial("Z06")+_oBrwOS:aCols[_nX][2]+_oBrwOS:aCols[_nX][3] ) )
						// posiciono pra gravar as informações
						While Z06->( ! EoF()) .And. (Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS) == _cSeekZ06)

							// se status = FI-Finalizado
							If (Z06->Z06_STATUS == "FI") .OR. (Z06->Z06_STATUS == "AN")

								// atualiza o status do servico de FI-FINALIZADO para EX-EM EXECUCACAO
								U_FtWmsSta(;
								Z06->Z06_STATUS,;
								"EX"           ,;
								Z06->Z06_NUMOS ,;
								Z06->Z06_SEQOS  )

								// quando for servico de 007-montagem de volume/003-conferencia de expedicao, alterar flag no pedido de venda
								If (Z06->Z06_SERVIC == "001") .And. (Z06->Z06_TAREFA $ "003/007") .And. ( ! Empty(Z05->Z05_CARGA) )

									// busco os pedidos baseado na carga
									_cQuery := " SELECT DISTINCT Z07_PEDIDO "
									_cQuery += " FROM " +RetSqlTab("Z07")+" (nolock) "
									_cQuery += " WHERE " + RetSqlCond("Z07")
									_cQuery += "        AND Z07_NUMOS = '" +Z06->Z06_NUMOS+ "' "
									_cQuery += "        AND Z07_SEQOS = '" +Z06->Z06_SEQOS+ "' "

									memowrit("C:\query\twmsa009_wmsa009i_sfTelaAbrOS.txt",_cQuery)

									// jogo os dados pro array
									_aPedidos := U_SqlToVet(_cQuery)

									// atualiza status de todos os pedidos da carga
									For _nNrPedido := 1 to Len(_aPedidos)
										// posiciona no pedido
										dbSelectArea("SC5")
										SC5->(dbSetOrder(1)) // 1-C5_FILIAL, C5_NUM
										If SC5->( dbSeek( xFilial("SC5") + _aPedidos[_nNrPedido] ))
											// atualiza status de conferencia/montagem de volumes
											RecLock("SC5")
											SC5->C5_ZMNTVOL := "N"
											SC5->(MsUnLock())
										EndIf
									Next _nNrPedido

								EndIf

							EndIf

							//próximo registro
							Z06-> (dbSkip())
						EndDo
					EndIf
				EndIf
			Next _nX

			// se deu tudo certo, avisa o user
			If (_lRet)
				// de acordo com o tipo de tela informada, mostra um tipo de mensagem
				If (_cTypScreen == "PC")
					MsgInfo("OS reaberta com sucesso!")
				Else
					U_FtWmsMsg("OS reaberta com sucesso!")
				EndIf
			EndIf

		EndIf
	EndIf

	// restaura area inicial
	RestArea(_aArea)
Return (_lRet)

// ** função pra validar os dados para estorno das OS ** //
Static Function sfAbrOS (mvNumOs, mvBrw, mvScreen)

	// variavel de retorno
	local _lRet := .T.
	// log
	local _cLog := ""
	// query de análise
	local _cQuery := ""
	// controle de loop
	local _nZ := 0
	// validação de selecionados
	local _nSelc := 0

	_lRet := MsgYesNo("Deseja Reabrir a OS "+mvNumos+"?")

	If (_lRet)
		// pra validar se algum registro foi selecionado
		aEval(mvBrw:aCols, { |x| Iif(x[1] == "LBOK", _nSelc ++, Nil) } )

		// se nada foi selecionado
		If (_nSelc == 0)
			_cLog += "Inconsistência: Nenhum registro selecionado."+CRLF
			_cLog += "Solução: Selecione pelo menos um registro."+CRLF
			_lRet := .F.
		EndIf

		If (_lRet)
			// para cada registro do acols
			For _nZ := 1 to Len(mvBrw:aCols)
				// valido só o que estiver selecionado
				If (mvBrw:aCols[_nZ][1] == "LBOK")
					// valido se aquela OS possui sequência superior àquela que estão tentando reabrir
					_cQuery := "SELECT Count(*) "
					_cQuery += "	FROM   "+RetSqlName("Z06")+" Z06MAIN (nolock)  "
					_cQuery += "	WHERE  Z06MAIN.Z06_FILIAL = '"+xFilial("Z06")+"' "
					_cQuery += "	       AND Z06MAIN.D_E_L_E_T_ = '' "
					_cQuery += "	       AND Z06MAIN.Z06_NUMOS = '"+mvNumOs+"' "
					_cQuery += "	       AND Z06MAIN.Z06_SEQOS = '"+mvBrw:aCols[_nZ][3]+"' "
					_cQuery += "	       AND EXISTS (SELECT * "
					_cQuery += "	                   FROM   "+RetSqlName("Z06")+" Z06SUB (nolock)  "
					_cQuery += "	                   WHERE  Z06SUB.Z06_FILIAL = Z06MAIN.Z06_FILIAL "
					_cQuery += "	       					  AND Z06SUB.D_E_L_E_T_ = '' "
					_cQuery += "	                          AND Z06SUB.Z06_NUMOS = Z06MAIN.Z06_NUMOS "
					_cQuery += "	                          AND Z06SUB.Z06_SEQOS > Z06MAIN.Z06_SEQOS "
					_cQuery += "	                          AND Z06SUB.Z06_STATUS = 'FI') "

					// se encontrou algum registro não deixa prosseguir
					If (U_FtQuery(_cQuery) > 0)
						_cLog += "Inconsistência: Há outras sequências finalizadas para essa OS."+CRLF
						_cLog += "Solução: Selecione a última sequência primeiro."+CRLF
					EndIf
				EndIf
			Next _nZ
		EndIf

		// se encontrou alguma inconsistência
		If ( ! Empty(_cLog) )
			If (mvScreen == "PC")
				HS_MsgInf("LOG:"+CRLF+_cLog,"Log da Reabertura da OS","Inconsistência na Reabertura da OS "+mvNumos)
				_lRet := .F.
			Else
				U_FtWmsMsg(_cLog, "Log Reab. da OS")
				_lRet := .F.
			EndIf
		EndIf
	EndIf

Return (_lRet)

// ** funcao para informar a informações adicionais(Quantidade,Palete Cliente,Lote)
Static Function sfInfOS()
	// objetos
	local _oBtnFoco1, _oWndInfOS, _oGetOS, _oBmpInfOSOk, _oPnlInfOSCab, _oBmpInfOSSair, _oSayOS
	// controle para nao fechar a tela
	local _lRetOk := .f.
	local _cNumOSInf := CriaVar("Z05_NUMOS")

	// reinicia segunda unidade de medida
	_nQtdSegUM := 0

	// monta a tela para informa a quantidade
	_oWndInfOS := MSDialog():New(020,020,140,180,"Estornar OS",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlInfOSCab := TPanel():New(000,000,nil,_oWndInfOS,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlInfOSCab:Align:= CONTROL_ALIGN_TOP

	// -- CONFIRMACAO
	_oBmpInfOSOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{||_lRetOk := .T.,_oWndInfOS:End() },_oPnlInfOSCab,"Ok",,.T.)
	_oBmpInfOSOk:Align := CONTROL_ALIGN_LEFT

	// -- SAIR
	_oBmpInfOSSair := TBtnBmp2():New(000,000,030,022,"FINAL",,,,{||_lRetOk := .T.,_oWndInfOS:End() },_oPnlInfOSCab,"Sair",,.T.)
	_oBmpInfOSSair:Align := CONTROL_ALIGN_RIGHT

	_oSayOS := TSay():New(023,005,{||"Digite o número da OS:"},_oWndInfOS,,,.F.,.F.,.F.,.T.)
	_oGetOS := TGet():New(033,005,{|u| If(PCount()>0,_cNumOSInf:=u,_cNumOSInf)},_oWndInfOS,060,010,PesqPict("Z05","Z05_NUMOS"),{||},,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNumOSInf",,,,,,,,)

	// seta o foco na quantidade
	_oGetOS:SetFocus()

	// ativacao da tela com validacao
	_oWndInfOS:Activate(,,,.T.,{|| _lRetOk })

	// se foi informada o número da OS
	If ( ! Empty(_cNumOSInf))
		// posiciono no cabeçalho da OS
		dbSelectArea("Z05")
		Z05->( dbSetOrder(1) ) //FILIAL+NUMOS
		If ( ! Z05->( dbSeek( _cSeekZ05 := xFilial("Z05")+_cNumOSInf ) ))
			U_FtWmsMsg("OS não encontrada!","Atenção")
		EndIf

	EndIf

Return _cNumOSInf

// ** consulta detalhada de etiquetas ** //
User Function WMSA009K ()

	// objetos da tela
	local _oPnlTop, _oPnlBottom
	local _oGetEtiq, _oBmpPesq, _oBmpSair, _oGetTpEtq, _oBmpExcel
	// número da etiqueta pesquisada
	local _cEtiqPes := Space(12) // pode ser de endereço/volume/produto
	local _cTpEtiq  := "" // pode ser de endereço/volume/produto
	// arrays do browse
	private _aHeadPes := {}
	private _aColsPes := {}
	private _oBrwDetCons, _oWndConsEtq

	// definicao da tela de consultas
	_oWndConsEtq := MSDialog():New(000,000,400,600,"Consulta Detalhada da Etiqueta",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho - botoes
	_oPnlTop := TPanel():New(000,000,nil,_oWndConsEtq,,.F.,.F.,,,,030,.T.,.F. )
	_oPnlTop:Align:= CONTROL_ALIGN_TOP

	// etiqueta
	_oGetEtiq := TGet():New(005,005,{|u| If(PCount()>0,_cEtiqPes:=u,_cEtiqPes)},_oPnlTop,050,010,,{|| },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,,"_cEtiqPes" ,,,,,, .T. ,"Etiqueta/Endereço",1,)

	// tipo de etiqueta
	_oGetTpEtq := TGet():New(005,055,{|u| If(PCount()>0,_cTpEtiq:=u,_cTpEtiq)},_oPnlTop,80,010,,{||},,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,,"_cTpEtiq" ,,,,,, .T. ,"Tipo de Etiqueta" ,1,)
	_oGetTpEtq:Disable()

	// botão pesquisar
	_oBmpPesq := TBtnBmp2():New(016,268,040,040,"PESQUISA",,,,{|| ;
	MsgRun("Pesquisando Informações", "Aguarde...", {|| CursorWait(), sfLoadHis( _cEtiqPes, @_cTpEtiq ), CursorArrow()}) ;
	},_oPnlTop,"Pesquisar",,.T. )

	// botão exportar excel
	_oBmpExcel := TBtnBmp2():New(016,300,040,040,"BMPCPO",,,,{||U_FtExpExc( "Histórico", _aHeadPes, _aColsPes )},_oPnlTop,"Exportar para Excel",,.T. )

	// botão sair
	_oBmpSair := TBtnBmp2():New(015,110,040,040,"FINAL",,,,{|| _oWndConsEtq:End() },_oPnlTop,"Sair",,.T. )
	_oBmpSair:Align:= CONTROL_ALIGN_RIGHT

	// cria o panel do rodapé
	_oPnlBottom := TPanel():New(000,000,nil,_oWndConsEtq,,.F.,.F.,,,,015,.T.,.F. )
	_oPnlBottom:Align:= CONTROL_ALIGN_BOTTOM

	// inicio o browse
	_oBrwDetCons := MsNewGetDados():New(000,000,400,400,,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsPes),'AllwaysTrue()','','AllwaysTrue()',_oWndConsEtq,_aHeadPes,_aColsPes)
	_oBrwDetCons:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oWndConsEtq CENTERED

Return

// ** função que retornoa o histórico da etiqueta pesquisada ** //
Static Function sfLoadHis ( mvEtiqPes, mvTpEtiq )

	// variavel para auxiliar nas pesquisas
	local _cQuery := ""
	// variavel para controle de transação
	local _lRet := .t.
	// variavel apra tipo de etiqueta
	local _cTpEtiq := ""

	// posiciono no cadastro de etiquetas
	dbSelectArea("Z11")
	Z11->( dbSetOrder(1) ) // Z11_FILIAL, Z11_CODETI, R_E_C_N_O_, D_E_L_E_T_

	// se achou a etiqueta, vai identificar os dados
	If ( Z11->( dbSeek( xFilial("Z11") + mvEtiqPes ) ) )

		// valida o tipo de etiqueta
		If ( _lRet ) .And. ( ! Z11->Z11_TIPO $ "01/02/04" )

			// avisa o usuário
			MsgInfo("Tipo de Etiqueta inválida.")
			// altera o retorno
			_lRet := .f.
		Else

			// jogo o valor pra variável
			_cTpEtiq := Z11->Z11_TIPO

			// define o tipo de etiqueta
			If (  _cTpEtiq == "01" )
				mvTpEtiq := "Etiqueta de Produto"
			ElseIf (  _cTpEtiq == "02" )
				mvTpEtiq := "Etiqueta de Endereço"
				mvEtiqPes := Z11->Z11_ENDERE
			ElseIf (  _cTpEtiq == "04" )
				mvTpEtiq := "Etiqueta de Volume"
			EndIf

		EndIf
	EndIf

	// caso o tipo de etiqueta foi endereço ou não foi encontrada
	If ( _lRet ) .And. ( Empty( _cTpEtiq ) )

		// se for endereço, pega o endereço na Z11

		// verifica se não foi digitado um endereço
		dbSelectArea("SBE")
		SBE->( dbSetOrder(9) ) // BE_FILIAL, BE_LOCALIZ, R_E_C_N_O_, D_E_L_E_T_
		If ( SBE->( dbSeek( xFilial("SBE") + mvEtiqPes ) ) )

			// define o tipo de etiqueta
			mvTpEtiq := "Endereço"
			// tipo de etiqueta de endereço
			_cTpEtiq := "99"
		Else

			// avisa o usuário
			MsgInfo("Endereço Não Encontrado.")
			// altera o retorno
			_lRet := .f.
		EndIf

	EndIf

	If ( _lRet )
		// cria o header para endereço
		_aHeadPes := sfSetHead( _cTpEtiq )

		// define o acols
		_aColsPes := sfSetCols( _cTpEtiq, mvEtiqPes )

		// define o browse a cada nova operação
		_oBrwDetCons := nil
		_oBrwDetCons := MsNewGetDados():New(000,000,400,400,,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsPes),'AllwaysTrue()','','AllwaysTrue()',_oWndConsEtq,_aHeadPes,_aColsPes)
		_oBrwDetCons:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// funcão que abre os detalhes da ordem de serviço
		_oBrwDetCons:oBrowse:bLdblClick := {|| U_TWMSA023( _oBrwDetCons:aCols[_oBrwDetCons:nAt][1] ) }

		// atualiza o browse
		_oBrwDetCons:Refresh()
	EndIf

Return

// ** função que retorna o header de acordo com o tipo de etiqueta ** //
Static Function sfSetHead ( mvTpEtiq )

	// define o acols inicial
	local _aRet := {}

	// define o header
	aAdd(_aRet,{"Ordem de Serviço"  , "IT_NUMOS"    , PesqPict("Z17", "Z17_NUMOS") , TamSx3("Z17_NUMOS")[1]   , 0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aRet,{"Tp Operação"       , "IT_TPOPER"   , ""                           , 7                        , 0,Nil,Nil,"C",Nil,"R",,,".F." })

	// valida o tipo de etiqueta
	If ( mvTpEtiq $ "02/99" )
		aAdd(_aRet,{"Etiqueta"      , "IT_ETIQ"     , PesqPict("Z17", "Z17_ETQPLT"), TamSx3("Z17_ETQPLT")[1]  , 0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aRet,{"Quantidade"    , "IT_QUANT"    , PesqPict("SDB", "DB_QUANT")  , TamSx3("DB_QUANT")[1]    , 0,Nil,Nil,"N",Nil,"R",,,".F." })
	Else
		aAdd(_aRet,{"Origem"        , "Z17_ENDORI"  , PesqPict("Z17", "Z17_ENDORI"), TamSx3("Z17_ENDORI")[1]  , 0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aRet,{"Destino"       , "Z17_ENDDES"  , PesqPict("Z17", "Z17_ENDDES"), TamSx3("Z17_ENDDES")[1]  , 0,Nil,Nil,"C",Nil,"R",,,".F." })
	EndIf

	// informações padrões
	aAdd(_aRet,{"Data Operação"         , "IT_DATA"     , PesqPict("Z17", "Z17_DTINI") , TamSx3("Z17_DTINI")[1]   , 0,Nil,Nil,"C",Nil,"R",,,".F." })
Return _aRet

// ** função que retorna o acols pra preencher o browse ** //
Static Function sfSetCols ( mvTpEtiq, mvEtiq  )

	// array de retorno
	local _aRet := {}
	// variavel de controle de transação
	local _lRet := .t.
	// query
	local _cQuery := ""
	// endereço da pesquisa
	local _cEndPesq := ""

	// indica que a pesquisa foi pelo endereço
	If ( mvTpEtiq == "99" )
		_cEndPesq := SBE->BE_LOCALIZ
	EndIf

	If ( mvTpEtiq $ "01/04" )

		// pesquisa as movimentações pela etiqueta informada
		_cQuery := " SELECT DISTINCT Z17_NUMOS IT_NUMOS, "
		_cQuery += "        CASE "
		_cQuery += "         WHEN Z05_TPOPER = 'E' THEN 'Entrada' "
		_cQuery += "         WHEN Z05_TPOPER = 'S' THEN 'Saída' "
		_cQuery += "         ELSE 'Interna' "
		_cQuery += "       END IT_TPOPER, "
		_cQuery += "       Z17_ENDORI, "
		_cQuery += "       Z17_ENDDES, "
		_cQuery += "       SUBSTRING(Z17_DTINI, 7, 2) + '/' + SUBSTRING(Z17_DTINI, 5, 2) + '/' + SUBSTRING(Z17_DTINI, 1, 4) IT_DATA, '.f.' IT_DEL"
		_cQuery += " FROM   " + RetSqlTab("Z17") + " (nolock) "
		_cQuery += "       INNER JOIN " + RetSqlTab("Z05") + " (nolock) "
		_cQuery += "               ON " + RetSqlCond("Z05")
		_cQuery += "                  AND Z05_NUMOS = Z17_NUMOS
		_cQuery += "       INNER JOIN " + RetSqlTab("Z16") + " (nolock) "
		_cQuery += "               ON Z16_ETQPAL = Z17_ETQPLT
		_cQuery += "                  AND " + RetSqlCond("Z16")
		_cQuery += " WHERE  " + RetSqlCond("Z17")
		_cQuery += "       AND Z17_STATUS = 'R'
		// filtro da etiqueta
		_cQuery += "       AND '" + mvEtiq + "' IN ( Z16_ETQPRD, Z16_ETQVOL ) "
		_cQuery += " ORDER  BY Z17_NUMOS "

		// retorna o array dos movimentos da etiqueta
		_aRet := U_SqlToVet(_cQuery)

		memowrit("C:\query\wmsa009K_etiq.txt", _cQuery)
	Else

		// pesquisar pelo endereço
		_cQuery := " SELECT DISTINCT DB_ZNUMOS IT_NUMOS, "
		_cQuery += "       CASE "
		_cQuery += "         WHEN DB_TM = '499' THEN 'Inclusão' "
		_cQuery += "         WHEN DB_TM = '999' THEN 'Retirada' "
		_cQuery += "         ELSE 'Undefined' "
		_cQuery += "       END             IT_TPOPER, "
		_cQuery += "       Isnull(CASE "
		_cQuery += "                WHEN Z16_ETQVOL = '' THEN Z16_ETQPRD "
		_cQuery += "                ELSE Z16_ETQVOL "
		_cQuery += "              END, '') IT_ETIQ, "
		_cQuery += "       DB_QUANT IT_QUANT, "
		_cQuery += "       SUBSTRING(DB_DATA, 7, 2) + '/' + SUBSTRING(DB_DATA, 5, 2) + '/' + SUBSTRING(DB_DATA, 1, 4) IT_DATA, '.f.' IT_DEL "
		_cQuery += " FROM   " + RetSqlTab("SDB") + " (nolock) "
		_cQuery += "       LEFT JOIN " + RetSqlTab("Z16") + " (nolock) "
		_cQuery += "              ON Z16_ETQPAL = DB_ZPALLET "
		_cQuery += "                 AND " + RetSqlCond("Z16")
		_cQuery += " WHERE  " + RetSqlCond("Z16")
		// filtro do endereço
		_cQuery += "       AND DB_LOCALIZ = '" + Iif( Empty(_cEndPesq), mvEtiq, _cEndPesq ) + "' "
		_cQuery += "       AND DB_ESTORNO = '' "
		_cQuery += "       ORDER by DB_ZNUMOS "

		// retorna o array dos movimentos do endereço
		_aRet := U_SqlToVet(_cQuery)

		memowrit("C:\query\wmsa009K_end.txt", _cQuery)
	EndIf

	// informa o usuário
	If ( Len(_aRet) == 0 )
		MsgStop("Nenhuma informação encontrada.")
		_lRet := .f.
	EndIf

Return _aRet

// ** funcao generica para finalizar ordens de servico (force)
User Function WMSA023A(mvNumOs)

	// variavel de retorno
	local _lRet := .t.
	// seek
	local _cSeekZ06, _cSeekZ08, _cSeekZ16

	// data e hora de emissao
	local _dDtEmis := CtoD("//")
	local _cHrEmis := ""

	// local de destino/armazem
	local _cLocDest := ""

	// log da operacao
	local _cDetLog := "ORD.SERV: "+mvNumOs +CRLF

	// log de processo ok
	local _cLogOk := ""

	// saldo para baixar do palete
	local _nSldBaixar := 0

	// atualizou saldo do palete
	local _lSaldoOk := .f.

	// encontrou produto no palete
	local _lPrdPltOk := .f.

	// pasta
	local _cPastaLog := "C:\Temp\ENC_OS_"+cFilAnt+"\"

	// handle do novo arquivo
	local _nHdl

	// solicita confirmacao
	If ! MsgYesNo("Confirma encerramento OS "+mvNumOs+" ?")
		Return(.f.)
	EndIf

	// verifica se o arquivo existe
	If ! File(_cPastaLog+"log_geral.txt")
		// handle do novo arquivo
		_nHdl := fCreate(_cPastaLog+"log_geral.txt")

		// grava cabecalho
		fWrite(_nHdl,"Nr.Ord.Servico;Seq;Cod.Tarefa;Tarefa;Dt.Emissao;Status Atual;Novo Status;Usr.Fim.;Dt.Fim;"+CRLF,Len("Nr.Ord.Servico;Seq;Cod.Tarefa;Tarefa;Dt.Emissao;Status Atual;Novo Status;Usr.Fim.;Dt.Fim;"+CRLF))

	Else
		// abre o arquivo
		_nHdl := fopen(_cPastaLog+"log_geral.txt" , FO_READWRITE + FO_SHARED )
		// Posiciona no fim do arquivo
		FSeek(_nHdl, 0, FS_END)
	EndIf

	// posiciona na ordem de servico
	dbSelectArea("Z05")
	Z05->(dbSetOrder(1)) // 1-Z05_FILIAL, Z05_NUMOS
	If ( ! Z05->(dbSeek( xFilial("Z05")+mvNumOs )))
		MsgStop("Ordem de Serviço não encontrada!")
		Return(.f.)
	EndIf

	// aceita somente OS de Expedicao
	If (Z05->Z05_TPOPER <> "S")
		MsgStop("Opção disponível somente para Ord. Serviço de Expedição!")
		Return(.f.)
	EndIf

	// posiciona no item da Ordem de Servico
	dbSelectArea("Z06")
	Z06->(dbSetOrder(1)) // 1-Z06_FILIAL, Z06_NUMOS, Z06_SEQOS
	Z06->(dbSeek( _cSeekZ06 := xFilial("Z06")+mvNumOs ))

	// inicia transacao
	BeginTran()

	// varre todos os itens da OS
	While Z06->( ! Eof() ) .And. (Z06->(Z06_FILIAL+Z06_NUMOS) == _cSeekZ06)

		// com erro, sai fora do loop
		If ( ! _lRet)
			Exit
		EndIf

		// armazena dados iniciais
		If (_lRet) .And. (Empty(_dDtEmis))
			_dDtEmis := Z06->Z06_DTEMIS
			_cHrEmis := Z06->Z06_HREMIS
		EndIf

		// atualiza status da sequencia da OS
		If ((Z06->Z06_STATUS <> "FI").or.((Z06->Z06_STATUS == "FI") .And. ( Empty(Z06->Z06_USRFIM) )))

			// inclui informacao no log
			_cDetLog += "..SEQ: "+Z06->Z06_SEQOS+" / STATUS DE: "+Z06->Z06_STATUS+" -> FI - OK" +CRLF

			// log ok
			_cLogOk += mvNumOs+";"
			_cLogOk += Z06->Z06_SEQOS+";"
			_cLogOk += Z06->Z06_TAREFA+";"
			_cLogOk += AllTrim(Posicione("SX5",1, xFilial("SX5")+"L2"+Z06->Z06_TAREFA, "X5_DESCRI"))+";"
			_cLogOk += DtoC(_dDtEmis)+";"
			_cLogOk += Z06->Z06_STATUS+";"
			_cLogOk += "FI"+";"
			_cLogOk += __cUserId+";"
			_cLogOk += DtoC(_dDtEmis)+";"
			_cLogOk += CRLF

			RecLock("Z06")
			Z06->Z06_DTEMIS := _dDtEmis
			Z06->Z06_HREMIS := _cHrEmis
			Z06->Z06_DTINIC := _dDtEmis
			Z06->Z06_HRINIC := _cHrEmis
			Z06->Z06_DTFIM  := _dDtEmis
			Z06->Z06_HRFIM  := _cHrEmis
			Z06->Z06_STATUS := "FI"
			Z06->Z06_USRFIM := __cUserId
			Z06->(MsUnLock())
		Else
			// inclui informacao no log
			_cDetLog += "..SEQ: "+Z06->Z06_SEQOS+" / STATUS FI - OK" +CRLF

		EndIf

		// se for 001-Expedicao e 002-Apanhe, encerra mapa (Z08)
		If (Z06->Z06_SERVIC == "001") .And. (Z06->Z06_TAREFA == "002")
			// posiciona no item do mapa da Ordem de Servico
			dbSelectArea("Z08")
			Z08->(dbSetOrder(1)) // 1-Z08_FILIAL, Z08_NUMOS
			Z08->(dbSeek( _cSeekZ08 := xFilial("Z08")+Z06->Z06_NUMOS ))

			// varre todos os itens do mapa
			While Z08->( ! Eof() ) .And. (Z08->(Z08_FILIAL+Z08_NUMOS) == _cSeekZ08)

				// com erro, sai fora do loop
				If ( ! _lRet)
					Exit
				EndIf

				// verifica a sequencia da OS
				If (Z08->Z08_SEQOS == Z06->Z06_SEQOS)

					// atualiza datas do mapa
					If (Z08->Z08_STATUS != "R")
						RecLock("Z08")
						Z08->Z08_DTINIC := _dDtEmis
						Z08->Z08_HRINIC := _cHrEmis
						Z08->Z08_DTFINA := _dDtEmis
						Z08->Z08_HRFINA := _cHrEmis
						Z08->Z08_STATUS := "R"
						Z08->Z08_USUARI := __cUserId
						Z08->Z08_ENDSRV := Z08_ENDDES
						Z08->(MsUnLock())

						// define local destino
						If ( ! Empty(Z08->Z08_LOCDES) )
							_cLocDest := Z08->Z08_LOCDES
						Else
							_cLocDest := Z08->Z08_LOCAL
						EndIf

						// inclui informacao no log
						_cDetLog += "  MAPA "+Z08->Z08_SEQUEN+" PROD: "+AllTrim(Z08->Z08_PRODUT)+"; QUANT: "+AllTrim(Str(Z08->Z08_QUANT))+"; PALETE: "+Z08->Z08_PALLET+" - OK" +CRLF

						// atualiza o endereco do palete
						U_FtEndPlt(Z08->Z08_PALLET, Z08->Z08_ENDORI, Z08->Z08_ENDDES, _cLocDest)

					EndIf

					// atualiza saldo do palete
					dbSelectArea("Z16")
					Z16->(dbSetOrder(1)) // 1-Z16_FILIAL, Z16_ETQPAL

					If ! Z16->(dbSeek( _cSeekZ16 := xFilial("Z16")+Z08->Z08_PALLET ))

						_cDetLog += "    PALETE: "+Z08->Z08_PALLET+" NÃO ENCONTRADO - ERRO" +CRLF

						_lRet := .f.
						Exit
					EndIf

					// atualizou saldo do palete
					_lSaldoOk := .f.

					// encontrou produto no palete
					_lPrdPltOk := .f.

					// saldo para baixar do palete
					_nSldBaixar := Z08->Z08_QUANT

					// varre todos os itens do palete
					While Z16->( ! Eof() ) .And. ((Z16->Z16_FILIAL + Z16->Z16_ETQPAL) == _cSeekZ16)

						// com erro, sai fora do loop
						If ( ! _lRet)
							Exit
						EndIf

						// valida produto
						If (Z16->Z16_CODPRO == Z08->Z08_PRODUT)

							_lPrdPltOk := .t.

							// valida quantidade
							If (Z16->Z16_SALDO < Z08->Z08_QUANT)
								If (Z16->Z16_SALDO > 0) .And. ( ! MsgYesNo("Saldo Z16: "+AllTrim(Str(Z16->Z16_SALDO))+" -> Req: "+AllTrim(Str(Z08->Z08_QUANT))) )
									_cDetLog += "    PALETE: "+Z08->Z08_PALLET+" SALDO Z16: "+AllTrim(Str(Z16->Z16_SALDO))+" -> Req: "+AllTrim(Str(Z08->Z08_QUANT)) +" - ERRO" +CRLF
									_lRet := .f.
									Exit
								Else
									_nSldBaixar := Z16->Z16_SALDO
								EndIf

							EndIf

							// atualiza o SALDO
							RecLock("Z16")
							Z16->Z16_SALDO -= _nSldBaixar
							Z16->(MsUnLock())

							_cDetLog += "    PALETE: "+Z08->Z08_PALLET+" SALDO - OK" +CRLF

							// atualizou saldo
							_lSaldoOk := .t.
						ENDIF

						// proximo item do palete
						Z16->(dbSkip())
					EndDo

					If ( ! _lPrdPltOk )
						_cDetLog += "    PALETE: "+Z08->Z08_PALLET+" NÃO ENCONTROU PRODUTO "+AllTrim(Z08->Z08_PRODUT)+" - ERRO" +CRLF
						_lRet := .f.
						Exit
					EndIf

				EndIf

				// proximo item do mapa
				Z08->(dbSkip())
			EndDo

		EndIf

		// proximo item
		Z06->(dbSkip())
	EndDo

	If ( ! _lRet)
		// executa rollback
		DisarmTransaction()
		// libera todos os registros
		MsUnLockAll()
		// mensagem
		MsgStop("Ord.Serviço Não Finalizada!")
	EndIF

	// encerra/confirma transacao
	EndTran()

	// libera todos os registros
	MsUnLockAll()

	// grava log com os detalhes
	If (_lRet)
		// grava log por OS
		MemoWrit(_cPastaLog+"det_os_"+mvNumOs+".txt", _cDetLog)

		// grava/complementa log geral
		FWrite(_nHdl,_cLogOk,Len(_cLogOk))

		// mensagem
		MsgInfo("Ord.Serviço Finalizada com Sucesso!")
	EndIf

	// se houve divergencia
	If ( ! _lRet)
		HS_MsgInf("Resumo da Operação:" +CRLF+ _cDetLog ,;
		"Log de Encerramento de OS",;
		"Log de Encerramento de OS" )
	EndIf

	// fecha arquivo
	fclose(_nHdl)

Return(_lRet)

// ** retorna tipo de endereço
Static Function sfRetTpEnd(mvEnd, mvArm)
	// variaveis de controle
	local _cQuery := ""
	local _cRet   := ""

	// query que trata o tipo de endereço com dados baseados na DC8
	_cQuery := "  SELECT DC8_TPESTR "
	_cQuery += "  FROM "+RetSqlTab("SBE")+" (nolock)  "
	_cQuery += "  INNER JOIN "+RetSqlTab("DC8")+" (nolock)  ON DC8_CODEST = BE_ESTFIS AND "+RetSqlCond("DC8")+" "
	_cQuery += "  WHERE "+RetSqlCond("SBE")
	_cQuery += "  AND BE_LOCAL   = '"+mvArm+"'
	_cQuery += "  AND BE_LOCALIZ = '"+mvEnd+"'

	// informação para debug
	memowrit("C:\query\TWMSA011_sfRetTpEnd.txt",_cQuery)

	// retorno direto da query
	_cRet := U_FtQuery(_cQuery)

Return(_cRet)

// ** funcao para chamada de rotina de atribuicao de operadores para ordem de servico
User Function WMSA009L(mvNumos)

	// query com os campos e filtro padrao do coletor de dados
	local _cQuery

	// se nao ha ordem de servico selecionada
	If (Empty(mvNumos))
		// avisa usuario
		Help( ,, 'TWMSA009.F02.001',, "Nehuma ordem de serviço selecionada. Favor verificar.", 1, 0 )
		// retorno
		Return( .F. )
	EndIf

	// verifica perfil do usuario logado.
	If ( (!_lUsrGeren ) .And. ( !_lUsrSuper ) .And. ( !_lUsrLider) )
		// mensagem
		MsgAlert("Usuário sem permissão de uso desta rotina." + CRLF + "Solicite ao Gerente ou Supervisor que realize as atribuições.","Atribuição de operador")
		// retorno
		Return( .F. )
	EndIf

	// query com os campos e filtro padrao do coletor de dados (fonte TACDA002)
	_cQuery := StaticCall(TACDA002, sfMontaQuery)

	// funcao padrao do coletor de dados para atribuicao de ordem de servico
	U_ACDA002D(_cQuery, mvNumos)

Return( .T. )

// função para finalizar ordem de serviço de recebimento com mapa de armazenagem gerado pelo planejado (e não pelo real)
// assim, se possuem pallets a mais que foram rebatidos em menor quantidade OU o cadastro de lastro/camada estava incorreto
// o supervisor consegue encerrar sem depender do TI
User Function WMSA009M (mvNumOS)

	local _lRet     := .T.
	local _cQry     := ""
	local _aRetSQL  := {}

	local _cSeekZ06 := ""
	local _cSeekZ08 := ""

	//confirma execução
	If ( !MsgYesNo("Esta opção irá finalizar a sequência de endereçamento da OS " + mvNumos + " por motivos de geração de mapa de armazenagem pelo planejado. Deseja continuar?") )
		//finaliza sem fazer nada
		Return( .F. )
	EndIf

	// *** inicio validações ***

	//monta consulta com as validações
	_cQry := "SELECT Z05_NUMOS,                                "
	_cQry += "       Z05_TPOPER,                               "
	_cQry += "       (SELECT Z06_STATUS                        "
	_cQry += "        FROM " + RetSqlTab("Z06") + " (nolock) "
	_cQry += "        WHERE " + RetSqlCond("Z06")
	_cQry += "               AND Z06_NUMOS = Z05_NUMOS         "
	_cQry += "               AND Z06_SEQOS = '001') Z06_SEQ01, "
	_cQry += "       (SELECT Z06_STATUS                        "
	_cQry += "        FROM " + RetSqlTab("Z06") + " (nolock) "
	_cQry += "        WHERE " + RetSqlCond("Z06")
	_cQry += "               AND Z06_NUMOS = Z05_NUMOS         "
	_cQry += "               AND Z06_SEQOS = '002') Z06_SEQ02, "
	_cQry += "       (SELECT Count(Z07_PALLET)                 "
	_cQry += "        FROM " + RetSqlTab("Z07") + " (nolock) "
	_cQry += "        WHERE " + RetSqlCond("Z07")
	_cQry += "               AND Z07_NUMOS = Z05_NUMOS         "
	_cQry += "               AND Z07_SEQOS = '001'             "
	_cQry += "               AND Z07_STATUS != 'A') Z07_QTD    "
	_cQry += " FROM " + RetSqlTab("Z05") + " (nolock) "
	_cQry += " WHERE " + RetSqlCond("Z05")
	_cQry += "       AND Z05_NUMOS = '" + mvNumOs + "'"

	memowrit("c:\query\twmsa009_WMSA009M.txt", _cQry )

	// atualiza vetor de dados
	_aRetSQL := U_SqlToVet(_cQry)

	// valida quantidade de registros
	If (Len(_aRetSQL) == 0)
		MessageBox("Ordem de Serviço não localizada!","Erro WMSA009M - Z06",48)
		Return( .F. )
	EndIf

	/*
	Vetor retorno

	[1] = numero OS
	[2] = tipo operação
	[3] = status da sequencia 01 (conferencia)
	[4] = status da sequencia 02 (endereçamento)
	[5] = quantidade pallets não armazenados na conferência

	*/

	//verifica se a OS é de entrada
	If (_aRetSQL[1][2] != "E")
		MessageBox("A OS " + mvNumOs + " não é uma OS de entrada!","Erro WMSA009M",48)
		//finaliza sem fazer nada
		Return( .F. )
	EndIf

	//verifica se a conferência já foi concluída
	If (_aRetSQL[1][3] != "FI")
		MessageBox("A conferência da OS " + mvNumOs + " não foi finalizada!","Erro WMSA009M",48)
		//finaliza sem fazer nada
		Return( .F. )
	EndIf

	//verifica se armazenagem está num status válido
	If (_aRetSQL[1][4] != "EX")
		MessageBox("O status da armazenagem da OS " + mvNumOs + " está em um estado inválido ou já foi encerrada! Verifique!","Erro WMSA009M",48)
		//finaliza sem fazer nada
		Return( .F. )
	EndIf

	//verifica se toda a conferência já foi armazenada
	If (_aRetSQL[1][5] != 0)
		MessageBox("Ainda existem " + Str(_aRetSQL[1][5]) + " pallets conferidos e não armazenados! Verifique!","Erro WMSA009M",48)
		//finaliza sem fazer nada
		Return( .F. )
	EndIf

	//pede senha de supervisor
	If ( !StaticCall(TWMSA010, sfVldUser, "G|S|L") )
		MessageBox("É necessária senha de supervisor/lider para finalizar o endereçamento pelo planejado!","Erro WMSA009M",48)
		Return( .F. )
	EndIf

	// *** fim validações ***

	//passou nas validações, executa a finalização

	Begin Transaction

		//deleta endereços não usados na Z08

		dbSelectArea("Z08")
		Z08->( dbSetOrder(1) ) //1-Z08_FILIAL+Z08_NUMOS
		If (! Z08->( dbSeek( _cSeekZ08 := xFilial("Z08") + mvNumos )))   //se não achou
			DisarmTransaction()
			MessageBox("Erro durante o processamento","Erro WMSA009M - Z08",48)
			_lRet := .F.
			Break
		EndIf

		//exclui registros
		While Z08->(!Eof()) .And. (Z08->(Z08_FILIAL + Z08_NUMOS) == _cSeekZ08)

			//se for o registro pendente que não será realizado
			If (Z08->Z08_STATUS == "P") .And. (Z08->Z08_SEQOS == "002") .And. ( Empty(Z08->Z08_DTINIC) ) .And. ( Empty(Z08->Z08_HRINIC) )
				RecLock("Z08",.F.)
				Z08->(dbDelete())
				MsUnlock()

			EndIf

			// proximo item
			Z08->(dbSkip())

		EndDo

		//finaliza sequencia 02 na z06
		dbSelectArea("Z06")
		Z06->( dbSetOrder(1) ) //1-Z06_FILIAL + Z06_NUMOS + Z06_SEQOS
		If (! Z06->( dbSeek( _cSeekZ06 := xFilial("Z06") + mvNumos + "002" )))   //se não achou
			DisarmTransaction()
			MessageBox("Erro durante o processamento","Erro WMSA009M - Z06",48)
			_lRet := .F.
			Break
		Else             //achou o registro da sequencia 02 e posicionou
			// funcao generica de alteracao do status da ordem de servico
			U_FtWmsSta(Z06->Z06_STATUS, "FI", Z06->Z06_NUMOS, Z06->Z06_SEQOS)
		EndIf

	End Transaction

	// libera todos os registros
	MsUnLockAll()

	If _lRet
		//se chegou até aqui, deu certo
		MsgInfo("Processamento OK. Sequência de endereçamento encerrada com sucesso.")
	EndIf

Return ( _lRet )

// função para gravar informações complementares dos dados da OS gerada nos pedidos de venda (baseados na carga)
Static Function sfCompInf(mvCarga, mvOndaSep, mvTarefa, mvCesv)

	local _cQuery   := ""
	local _aPedidos := {}
	local _aAreaSC5 := SC5->(GetArea())

	// valores padores dos parametros
	Default mvCarga   := CriaVar("DAK_COD"   , .F.)
	Default mvOndaSep := CriaVar("Z57_CODIGO", .F.)
	Default mvTarefa  := CriaVar("Z06_TAREFA", .F.)
	Default mvCesv    := CriaVar("ZZ_CESV"   , .F.)

	// monta query para localizar os pedidos baseados na carga
	If ( ! Empty(mvCarga)) .And. (Empty(mvOndaSep))
		// prepara query
		_cQuery := "SELECT DAI_PEDIDO "
		_cQuery += " FROM " + RetSqlTab("DAI") + " (nolock) "
		_cQuery += " WHERE " + RetSqlCond("DAI")
		_cQuery += "       AND DAI_COD = '" + mvCarga + "'"

		// monta query para localizar os pedidos baseados na carga
	ElseIf (Empty(mvCarga)) .And. ( ! Empty(mvOndaSep) )
		// prepara query
		_cQuery := "SELECT Z58_PEDIDO "
		_cQuery += " FROM " + RetSqlTab("Z58") + " (nolock) "
		_cQuery += " WHERE " + RetSqlCond("Z58")
		_cQuery += "       AND Z58_CODIGO = '" + mvOndaSep + "'"

		// monta query para localizar os pedidos baseados no agendamento
	ElseIf ( ! Empty(mvCesv) ) .And. (Empty(mvCarga)) .And. (Empty(mvOndaSep))
		// prepara query
		_cQuery := " SELECT Z43_PEDIDO
		_cQuery += " FROM   " + RetSqlTab("Z43") + " (nolock) "
		_cQuery += " WHERE  " + RetSqlCond("Z43")
		_cQuery += "        AND Z43_STATUS IN ( 'P', 'R' ) "
		_cQuery += "        AND Z43_CESV = '" + mvCesv + "' "

	EndIf

	// atualiza vetor com pedido
	_aPedidos := U_SqlToVet(_cQuery)

	// se não encontrou registros
	If (len(_aPedidos) == 0)
		// mensagem
		MsgAlert("Erro ao gravar complemento de dados nos pedidos de venda da carga / onda de separação: " + AllTrim(mvCarga) + AllTrim(mvOndaSep) + ". Abortando processo.")
		// restaura area inicial
		RestArea(_aAreaSC5)
		// retorno
		Return ( .F. )
	EndIf

	// cab. pedido de venda
	DbSelectArea("SC5")
	SC5->( DbSetOrder(1) ) //C5_FILIAL, C5_NUM, R_E_C_N_O_, D_E_L_E_T_

	// complementa os campos no pedido de venda
	for _nPed := 1 to Len(_aPedidos)

		// pesquisa e posiciona no pedido de venda
		If SC5->(dbSeek( xFilial("SC5") + _aPedidos[_nPed] ))

			If (mvTarefa == "002")   								//002 - apanhe
				RecLock("SC5",.F.)
				SC5->C5_ZNOSSEP := Z05->Z05_NUMOS
				SC5->C5_ZDOSSEP := Z05->Z05_DTEMIS
				SC5->C5_ZHOSSEP := Z05->Z05_HREMIS
				MsUnlock()
			Elseif (mvTarefa == "003" .OR. mvTarefa == "007")   	//003 / 007 - montagem palete
				RecLock("SC5",.F.)
				SC5->C5_ZNOSMNT := Z05->Z05_NUMOS
				SC5->C5_ZDOSMNT := Z05->Z05_DTEMIS
				SC5->C5_ZHOSMNT := Z05->Z05_HREMIS
				MsUnlock()
			Elseif (mvTarefa == "004" )								//004 - carregamento
				RecLock("SC5",.F.)
				SC5->C5_ZNOSEXP := Z05->Z05_NUMOS
				SC5->C5_ZDOSEXP := Z05->Z05_DTEMIS
				SC5->C5_ZHOSEXP := Z05->Z05_HREMIS
				MsUnlock()
			Endif
		EndIf

	Next _nPed

	// restaura area inicial
	RestArea(_aAreaSC5)

Return ( .T. )

// função para o gerente autorizar (double-check) um recebimento com TFAA
// Recebe: número da OS a autorizar
// Retorna: TRUE se liberou, FALSE se não liberou/erro
Static Function sfLibTfaa (mvNumos)
	Local aAreaZ06 := Z06->(GetArea())
	Local _cOpcao := ""

	// verifica se OS está em análise
	IF 	( (_cAlTrOrdServ)->Z06_STATUS != "AN" )
		Alert("OS não é está em analise")
		Help(,, 'TWMSA009.F05.001',, "A ordem de serviço não está pendente de autorização pelo gerente (em análise).", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"Escolha uma OS válida e tente novamente"})
		RestArea(aAreaZ06)
		Return ( .F. )
	EndIf

	DbSelectArea("Z06")
	Z06->(dbSetOrder(1))   // 1 - Z06_FILIAL, Z06_NUMOS, Z06_SEQOS, R_E_C_N_O_, D_E_L_E_T_

	// se a OS não existe, sai
	IF  !(Z06->(dbSeek( xFilial("Z06") + mvNumos + "001" )))
		RestArea(aAreaZ06)
		Help(,, 'TWMSA009.F05.002',, "OS não encontrada.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"A OS selecionada não foi encontrada. Pode ter sido excluída durante a execução desta rotina. Selecione e tente novamente."})
		Return ( .F. )
	EndIf

	// valida se OS é de recebimento
	IF  ( Z06_SERVIC != "003" )
		RestArea(aAreaZ06)
		Help(,, 'TWMSA009.F05.003',, "OS não é de recebimento.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"A OS selecionada não é do tipo recebimento. Seleciona uma OS válida."})
		Return ( .F. )
	EndIf

	//valida senha de gerente
	If ( !StaticCall(TWMSA010, sfVldUser, "G") )
		Help(,, 'TWMSA009.F05.004',, "Senha de gerente inválida", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"É necessário senha de gerente para liberar a OS em análise."})
		RestArea(aAreaZ06)
		Return ( .F. )
	EndIf

	// chegou até aqui, vai trocar o status
	_cOpcao := U_FtMultRet("Finalize OS!", "Recontem!", "conf", "cancela", "Atenção gerente!", "Confirma que é um TFAA e finaliza a OS ou NÃO CONFIRMA e devolve para operação refazer?")

	U_FtWmsSta( Z06->Z06_STATUS,;
	IIF( _cOpcao == "conf", "FI", "EX"),;
	Z06->Z06_NUMOS,;
	"001" )

	// insere o log
	U_FtGeraLog(cFilAnt, "Z06", xFilial("Z06")+Z06->Z06_NUMOS+Z06->Z06_SEQOS, "TFAA " +  IIF( _cOpcao == "conf", "liberado", "negado e exigida nova contagem") +" pelo gerente:" + cUserName , "WMS")

	sfRfrDados(.f.)

	RestArea(aAreaZ06)

Return ( .T. )

// função auxiliar que verifica se o mapa de expedição tem algum produto que possui integração via barcode - Cliente Sumitomo
// Redmine #414
// Retorno --> .T. se pelo menos UM dos produtos do mapa tem integração de barcode, .F. se nenhum produto do mapa tem integração de barcode
Static Function sfTemBarcode(mvMapa)
	Local _lRet := .F.
	Local _nXX
	Local aAreaSB1 := SB1->(GetArea())
	Local _QryBar  := ""

	For _nXX := 1 to Len(mvMapa)
		// procura se o produto está com controle de barcode ativo
		If ( GetAdvFVal("SB1","B1_ZNUMSER",xFilial("SB1") + mvMapa[_nXX][1],1) == "S" )

			// produto controla barcode, então pesquisa se ao menos UMA nota fiscal origem do mapa tem recebimento de barcode
			// se tiver, significa que temos que fazer a integração EDI, então retorna .T.
			_QryBar := "SELECT R_E_C_N_O_         "
			_QryBar += "FROM " + RetSqlTab("Z56")
			_QryBar += "WHERE " + RetSqlCond("Z56")
			_QryBar += "       AND Z56_NOTA   = '" + mvMapa[_nXX][9] + "'"
			_QryBar += "	   AND Z56_SERIE  = '" + mvMapa[_nXX][8] + "'"
			_QryBar += "	   AND Z56_CODCLI = '" + _cCodCli        + "'"
			_QryBar += "	   AND Z56_LOJCLI = '" + _cLojCli        + "'"

			// voltou resultado
			If ( !Empty(U_FTQuery(_QryBar)) )
				_lRet := .T.
				Exit
			EndIf
		EndIf
	Next _nXX

	RestArea(aAreaSB1)

Return (_lRet)

// Função para validar a distribuição de saldo de endereçamento feito sem NF
Static Function sfDistrNF(mvNumOS,mvCliente,mvLoja)
	Local _lEndSemNF  := U_FtWmsParam("WMS_ENDERECAMENTO_SEM_NF", "L", .F. , .F., "", mvCliente, mvLoja, Nil, Nil)

	If !_lEndSemNF
		MsgAlert("O cliente não está configurado para efetuar distribuição de saldo sem NF.","Distribuição de saldo em endereços")
		Return
	EndIf

	If MsgYesNo("Confirma a distribuição de saldo da OS " + mvNumOS + " endereçada sem Nota Fiscal?")
		MsgRun("Distribuindo saldo OS: " + mvNumOS + "...", "Aguarde...", {|| sfExDisNF(mvNumOS,mvCliente,mvLoja)})
	Else
		Return
	EndIf

Return

// Função que executa a distribuição de saldo de endereçamento feito sem NF
Static Function sfExDisNF(mvNumOS,mvCliente,mvLoja)
	Local _aCabSDA  := {}
	Local _aItemSDB := {}
	Local _cItemDB	:= ""
	Local _lUpdate	:= .F.
	Local _cQuery   := ""
	Local _nCont	:= 1
	Local _lRet 	:= .T.

	While (_lRet .AND. _nCont <= 2)
		_cQuery := " SELECT Count(*)
		_cQuery += " FROM   " + RetSqlTab("Z08")
		_cQuery += " WHERE  " + RetSqlCond("Z08")
		_cQuery += "        AND Z08_NUMOS = '" + mvNumOS + "'
		If (_nCont > 1)
			_cQuery += "        AND Z08_STATUS != 'R'
		Endif

		MemoWrit("c:\query\sfExDisNF_" + Iif((_nCont == 1),"01","02") + ".txt",_cQuery)

		// voltou resultado
		If ( Empty(U_FTQuery(_cQuery) ) .AND. _nCont == 1)
			MsgAlert("Esta OS não possui mapa de armazenagem gerado. Verifique!","Endereçamento sem Nota Fiscal")
			_lRet := .F.
		EndIf

		// voltou resultado
		If ( !Empty(U_FTQuery(_cQuery) ) .AND. _nCont == 2)
			MsgAlert("Ainda existem movimentos na na armazenagem da OS não finalizados. Verifique!","Endereçamento sem Nota Fiscal")
			_lRet := .F.
		EndIf

		_nCont++
	Enddo

	If (_lRet)
		_cQuery := " SELECT Count(Z06_NUMOS)
		_cQuery += " FROM   " + RetSqlTab("Z06")
		_cQuery += " WHERE  " + RetSqlCond("Z06")
		_cQuery += "        AND Z06_NUMOS = '" + mvNumOS + "'
		_cQuery += "        AND Z06_SERVIC = '015'
		_cQuery += "        AND Z06_TAREFA = '009'
		_cQuery += "        AND Z06_SEQOS = '002'
		_cQuery += "        AND Z06_STATUS != 'FI'

		MemoWrit("c:\query\sfExDisNF_03.txt",_cQuery)
	Endif

	// voltou resultado
	If ( !Empty(U_FTQuery(_cQuery) ) )
		MsgAlert("Esta OS não está com a sequência de armazenagem finalizada. Verifique!","Endereçamento sem Nota Fiscal")
		_lRet := .F.
	EndIf

	If Select("tZ08") > 0
		DBSelectArea("tZ08")
		tZ08->(DBCloseArea())
	EndIf

	// Pega os produtos da OS que foram endereçados sem NF e ainda não foi feita a distribuição de saldo
	If (_lRet)
		_cQuery := " SELECT Z08_PRODUT, "
		_cQuery += "        Z08_ENDDES, "
		_cQuery += "        Sum(Z07_QUANT) Z07_QUANT, "
		_cQuery += "        Z05_CLIENT, "
		_cQuery += "        Z05_LOJA, "
		_cQuery += "        Z08_NUMOS, "
		_cQuery += "        Z08_SEQOS, "
		_cQuery += "        Z08_PALLET "
		_cQuery += " FROM   " + RetSQLName("Z08") + " Z08  (NOLOCK) "
		_cQuery += "        INNER JOIN " + RetSQLName("Z05") + " Z05 (NOLOCK) "
		_cQuery += "                ON Z05.D_E_L_E_T_ = '' "
		_cQuery += "                   AND Z05.Z05_FILIAL = Z08.Z08_FILIAL "
		_cQuery += "                   AND Z05.Z05_NUMOS = Z08.Z08_NUMOS "
		_cQuery += "        INNER JOIN " + RetSQLName("Z07") + " Z07 (NOLOCK) "
		_cQuery += "                ON Z07.Z07_FILIAL = Z08.Z08_FILIAL "
		_cQuery += "                   AND Z07.D_E_L_E_T_ = '' "
		_cQuery += "                   AND Z07.Z07_NUMOS = Z08.Z08_NUMOS "
		_cQuery += "                   AND Z07.Z07_PALLET = Z08.Z08_PALLET "
		_cQuery += "                   AND Z07.Z07_PRODUT = Z08.Z08_PRODUT "
		_cQuery += "                   AND Z07.Z07_ENDATU = Z08.Z08_ENDSRV "
		_cQuery += " WHERE  Z08.D_E_L_E_T_ = '' "
		_cQuery += "        AND Z08_FILIAL = '" + xFilial("Z08") + "' "
		_cQuery += "        AND Z08_NUMOS = '" + mvNumOS + "' "
		_cQuery += "        AND Z08_STATUS = 'R' "
		_cQuery += "        AND Rtrim(Z08_PRODUT) + Rtrim(Z08_ENDDES) NOT IN (SELECT Rtrim(DB_PRODUTO) + Rtrim(DB_LOCALIZ) "
		_cQuery += "                                                          FROM   " + RetSQLName("SDB") + " SDB (NOLOCK) "
		_cQuery += "                                                          WHERE  SDB.D_E_L_E_T_ = '' "
		_cQuery += "                                                                 AND SDB.DB_FILIAL = Z08.Z08_FILIAL "
		_cQuery += "                                                                 AND SDB.DB_CLIFOR = Z05.Z05_CLIENT "
		_cQuery += "                                                                 AND SDB.DB_LOJA = Z05.Z05_LOJA "
		_cQuery += "                                                                 AND SDB.DB_ESTORNO = '' "
		_cQuery += "                                                                 AND SDB.DB_ZNUMOS = Z08.Z08_NUMOS) "
		_cQuery += " GROUP  BY Z08_PRODUT, "
		_cQuery += "           Z08_ENDDES, "
		_cQuery += "           Z05_CLIENT, "
		_cQuery += "           Z05_LOJA, "
		_cQuery += "           Z08_NUMOS, "
		_cQuery += "           Z08_SEQOS, "
		_cQuery += "           Z08_PALLET "
		_cQuery += " ORDER  BY Z08_PRODUT, "
		_cQuery += "           Z08_ENDDES "

		TCQuery _cQuery NEW ALIAS "tZ08"

		MemoWrit("c:\query\sfExDisNF_04.txt",_cQuery)

		If 	tZ08->( EOF() )
			MsgAlert("Não existe mapa de armazenagem gerado para esta OS ou o endereçamento já foi realizado.","Endereçamento sem Nota Fiscal")
			_lRet := .F.
		Endif
	Endif

	Begin Transaction

		if !tZ08->(EOF()) .AND. _lRet
			While !tZ08->(EOF()) .AND. _lRet

				If Select("tSDA") > 0
					DBSelectArea("tSDA")
					tSDA->(DBCloseArea())
				EndIf

				// Valida e pega os dados da NF lançada posteriormente ao endereçamento sem NF
				_cQuery := " SELECT * "
				_cQuery += " FROM "+RetSQLName("SDA")+" (NOLOCK) "
				_cQuery += " WHERE D_E_L_E_T_ = '' "
				_cQuery += " AND DA_FILIAL = '"  + xFilial("SDA") + "' "
				_cQuery += " AND DA_CLIFOR = '" + tZ08->Z05_CLIENT + "' "
				_cQuery += " AND DA_LOJA = '" + tZ08->Z05_LOJA + "' "
				_cQuery += " AND DA_PRODUTO = '" + tZ08->Z08_PRODUT + "' "
				_cQuery += " AND DA_SALDO >= " + Str(tZ08->Z07_QUANT) + " "
				_cQuery += " AND DA_DOC+DA_SERIE = (SELECT F1_DOC+F1_SERIE "
				_cQuery += "                        FROM " + RetSQLName("SF1") + " (NOLOCK) "
				_cQuery += "                        WHERE D_E_L_E_T_ = '' "
				_cQuery += "                        AND F1_FILIAL = '" + xFilial("SF1") + "' "
				_cQuery += "                        AND F1_FORNECE = '" + mvCliente + "' "
				_cQuery += "                        AND F1_LOJA = '" + mvLoja + "' "
				_cQuery += "                        AND SUBSTRING(F1_ZOBS,4,6) = '" + AllTrim(mvNumOS) + "') "
				_cQuery += " ORDER BY DA_PRODUTO "

				TCQuery _cQuery NEW ALIAS "tSDA"

				MemoWrit("c:\query\sfExDisNF_05.txt",_cQuery)

				if !tSDA->(EOF())

					// Verifica se o endereço da distribuição está bloqueado e muda o Status para Desocupado
					dbSelectArea("SBE")
					dbSetOrder(1) //BE_FILIAL, BE_LOCAL, BE_LOCALIZ, BE_ESTFIS
					IF dbSeek(xFilial("SBE")+tSDA->DA_LOCAL+tZ08->Z08_ENDDES)
						If SBE->BE_STATUS == "3" // Endereço Bloqueado
							RecLock("SBE",.F.)
							SBE->BE_STATUS	:= "1" // Endereço desocupado
							MsUnLock()
						EndIf
					EndIf

					// zera variaveis
					_aCabSDA  := {}
					_aItemSDB := {}

					// cabecalho de movimentacao da mercadoria
					_aCabSDA := {{"DA_FILIAL",tSDA->DA_FILIAL ,NIL},;
					{"DA_PRODUTO"	,tSDA->DA_PRODUTO	,NIL},;
					{"DA_QTDORI"	,tSDA->DA_QTDORI	,NIL},;
					{"DA_SALDO"		,tSDA->DA_SALDO		,NIL},;
					{"DA_DATA"		,Date()				,NIL},;
					{"DA_LOTECTL"	,tSDA->DA_LOTECTL	,NIL},;
					{"DA_DOC"		,tSDA->DA_DOC		,NIL},;
					{"DA_SERIE"		,tSDA->DA_SERIE		,NIL},;
					{"DA_CLIFOR"	,tSDA->DA_CLIFOR	,NIL},;
					{"DA_LOJA"		,tSDA->DA_LOJA		,NIL},;
					{"DA_TIPONF"	,tSDA->DA_TIPONF	,NIL},;
					{"DA_NUMSEQ"	,tSDA->DA_NUMSEQ	,NIL},;
					{"DA_LOCAL"		,tSDA->DA_LOCAL		,NIL},;
					{"DA_ORIGEM"	,tSDA->DA_ORIGEM	,NIL}}

					// pesquisa a ultimo item utilizado
					_cItemDB := A265UltIt('C')
					// proximo item valido
					_cItemDB := Soma1(_cItemDB)

					// item da movimentacao da mercadoria
					Aadd(_aItemSDB,{{"DB_FILIAL",xFilial("SDB"),NIL},;
					{"DB_ITEM"		,_cItemDB			,NIL},;
					{"DB_LOCAL"		,tSDA->DA_LOCAL		,NIL},;
					{"DB_ESTORNO"	," "				,Nil},;
					{"DB_LOCALIZ"	,tZ08->Z08_ENDDES	,NIL},;
					{"DB_PRODUTO"	,tSDA->DA_PRODUTO	,NIL},;
					{"DB_DOC"		,tSDA->DA_DOC		,NIL},;
					{"DB_SERIE"		,tSDA->DA_SERIE		,NIL},;
					{"DB_NUMSEQ"	,tSDA->DA_NUMSEQ	,NIL},;
					{"DB_DATA"		,Date() 			,NIL},;
					{"DB_QUANT"		,tZ08->Z07_QUANT	,NIL},;
					{"DB_ZNUMOS"	,tZ08->Z08_NUMOS	,NIL},;
					{"DB_ZSEQOS"	,tZ08->Z08_SEQOS	,NIL},;
					{"DB_ZLOTECT"	,tSDA->DA_LOTECTL	,NIL},;
					{"DB_ZPALLET"	,tZ08->Z08_PALLET	,NIL}})

					// Atualiza arquivo de saldos em estoque
					dbSelectArea("SB2")
					SB2->(DbSetOrder(1)) // 1-B2_FILIAL, B2_COD, B2_LOCAL
					If ! SB2->(dbSeek( xFilial("SB2") + tSDA->DA_PRODUTO + tSDA->DA_LOCAL ))
						// cria registro do produto no armazem de destino
						CriaSB2(tSDA->DA_PRODUTO, tSDA->DA_LOCAL)
					EndIf

					// executa funcao padrao de distribuicao da mercadoria
					lMsErroAuto := .F.
					MSExecAuto({|x,y,z| mata265(x,y,z)},_aCabSDA,_aItemSDB,3) //Distribui

					// se ocorreu erro na rotina automatica
					If (lMsErroAuto)
						DisarmTransaction()
						MostraErro()
						_lRet := .F.
					Else
						_lUpdate := .T.
					Endif
				Endif
				tZ08->(DBSkip())
			EndDo
		Else
			MsgAlert("A Nota Fiscal desta OS não possui mais saldo para distribuição!")
			_lRet := .F.
		Endif

		If (_lRet .AND. _lUpdate)

			If Select("tZ07") > 0
				DBSelectArea("tZ07")
				tSDA->(DBCloseArea())
			EndIf

			// Valida e pega os dados da NF lançada posteriormente ao endereçamento sem NF
			_cQuery := " SELECT Z07_PALLET,Z07_ETQVOL,Z07_TPESTO,Z07_PRODUT "
			_cQuery += " FROM  " + RetSqlTab("Z07") + " (NOLOCK) "
			_cQuery += " WHERE " + RetSqlCond("Z07")
			_cQuery += " AND Z07_NUMOS = '"  + mvNumOS + "' "

			TCQuery _cQuery NEW ALIAS "tZ07"

			MemoWrit("c:\query\sfExDisNF_06.txt",_cQuery)

			DbSelectArea("Z16")
			DbSetOrder(4) // 4 - Z16_FILIAL, Z16_ETQVOL, R_E_C_N_O_, D_E_L_E_T_
			
			While !tZ07->(EOF()) .AND. _lRet

				If (MsSeek( xFilial("Z16") + tZ07->Z07_ETQVOL))
					If (Z16->Z16_CODPRO == tZ07->Z07_PRODUT .AND. Z16->Z16_TPESTO == "000023")
						RecLock("Z16",.F.)
						Z16->Z16_TPESTO	:= tZ07->Z07_TPESTO // Endereço desocupado
						MsUnLock()
					Endif
				Endif
			Enddo
		Endif
	End Transaction
	If _lRet
		MsgInfo("Nota fiscal " + tSDA->DA_DOC + "/" + tSDA->DA_SERIE + " distribuida com sucesso!","Sucesso! - Endereçamento sem NF")
	Endif
Return (_lRet)