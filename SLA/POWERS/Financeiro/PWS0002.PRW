#Include "protheus.ch"
 
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! STR06C02                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Consulta para Visualizar o Fluxo de Caixa               !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 03/03/10                                                !
+------------------+---------------------------------------------------------+
!Arq. Utilizados   ! \FLUXO.SIM                                              !
+------------------+---------------------------------------------------------+
!   ATUALIZACOES                                                             !
+-------------------------------------------+-----------+-----------+--------+
!   Descricao detalhada da atualizacao      !Nome do    ! Analista  !Data da !
!                                           !Solicitante! Respons.  !Atualiz.!
+-------------------------------------------+-----------+-----------+--------+
!                                           !           !           !        !
!                                           !           !           !        !
+-------------------------------------------+-----------+-----------+-------*/

User Function PWS0002
	// dimensoes da tela
	Private _aSizeDlg := MsAdvSize()
	
	//Arquivo de Trabalhos (para Exportar pro Excel)
	Private cArqFlx	:= ""
	Private cArqPC	:= ""
	Private cArqSim	:= ""
	Private cArqTit	:= ""
	
	// filtro do SE1
	Private _cWhereSE1	:= ""
	// filtro do SE2
	Private _cWhereSE2	:= ""

	// vetores com os Dados Detalhados
	Private _vDtSimula	:= {}
	Private _vDtPedCom	:= {}
	Private _vDtPedVen	:= {}
	Private _vDtConRec	:= {}
	Private _vDtConPag	:= {}
	
	//Fontes
	Private fFonte1	:= TFont():New("Courier New",,14)
	Private fFonte2	:= TFont():New("Tahoma",,26,,.T.)

	Private _vPeriod	:= {"01-Diário","07-Semanal","15-Quinzenal","30-Mensal"}
	Private _vDatas		:= {}
	Private _cTrbData	:= ""
	// campos usados para os detalhes dos titulos
	Private _aBrwDetTit	:= {}
	Private _aEsrDetTit	:= {}
	Private _cTrbDetTit	:= ""
	// campos usados para os detalhes dos pedidos de venda
	Private _cTrbDetPV	:= ""
	
	//Totais da Tela Principal
	Private nTotRec	:= 0
	Private nTotPag	:= 0
	Private nTotSld	:= 0

	Private cPerg	:= PadR("STR06C02",Len(SX1->X1_GRUPO))
	Private vPerg	:= {}
	
	// Arquivo Texto com Informacoes das Simulacoes de Usuarios
	Private _cFileSim	:= "\FLUXO.SIM"

	// abatimentos
	Private _cTpAbatim	:= MV_CRNEG+"|"+MV_CPNEG+"|"+MVIRABT+"|"+MVCSABT+"|"+MVCFABT+"|"+MVPIABT+"|"+MVABATIM
	Private _cQryAbatim	:= FormatIn(_cTpAbatim,"|")
	
	// monta o grupo de perguntas	
	aAdd(vPerg,{"Data Inicial?","D",8,0,"G",,""})//mv_par01
	aAdd(vPerg,{"Data Final?","D",8,0,"G",,""})//mv_par02
	aAdd(vPerg,{"Periodicidade?","N",1,0,"C",{"01-Diário","07-Semanal","15-Quinzenal","30-Mensal"},""})//mv_par03
	aAdd(vPerg,{"Contas a Pagar?","N",1,0,"C",{"Sim","Não"},""})//mv_par04
	aAdd(vPerg,{"Contas a Receber?","N",1,0,"C",{"Sim","Não"},""})//mv_par05
	aAdd(vPerg,{"Pedidos de Compra?","N",1,0,"C",{"Sim","Não"},""})//mv_par06
	aAdd(vPerg,{"Pedidos de Venda?","N",1,0,"C",{"Sim","Não"},""})//mv_par07
	aAdd(vPerg,{"Simulações?","N",1,0,"C",{"Sim","Não"},""})//mv_par08
	aAdd(vPerg,{"Visão?","N",1,0,"C",{"Natureza"},""})//mv_par09
	aAdd(vPerg,{"Saldo Bancário?","N",1,0,"C",{"Sim","Não"},""})//mv_par10
	aAdd(vPerg,{"Titulos em Atraso?","N",1,0,"C",{"Sim","Não"},""})//mv_par11
	// rotina para criar o grupo de perguntas	
	sfCriaSX1( cPerg,vPerg )

	If ! Pergunte( cPerg , .T. )
		Return
	EndIf
	
	Private _dDtIni		:= mv_par01 						// Data Inicial
	Private _dDtFim		:= mv_par02							// Data Final
	Private _nPeriod	:= Val(Left(_vPeriod[mv_par03],2))	// Peridiocidade (dia, semana, quinzena, mensal)
	Private _lConPag	:= (mv_par04==1)					// Contas a Pagar
	Private _lConRec	:= (mv_par05==1)					// Contas a Receber
	Private _lPedCom	:= (mv_par06==1)					// Pedidos de Compras
	Private _lPedVend	:= (mv_par07==1)					// Pedidos de Venda
	Private _lSimula	:= (mv_par08==1)					// Simulacoes
	Private _nVisao		:= mv_par09							// Visao (1-Natureza/2-CC)
	Private _lSldBanco	:= (mv_par10==1)					// saldo bancario (1-Sim/2-Nao)
	Private _lTitAtraso	:= (mv_par11==1)					// titulos atrasado (1-Sim/2-Nao)
	//Private nSaldos	:= mv_par09 						//Saldos

	// saldo em conta
	Private _nSldBanco	:= 0
	// saldo em caixa
	Private _nSldCaixa	:= 0
	// titulos a pagar vencidos
	Private _nAtrPagar	:= 0
	// titulos a receber vencidos
	Private _nAtrReceb	:= 0
	
	// função que separa as Datas conforme parametros
	sfSepPeriodo()
	
	// alimenta o saldo das contas/caixas
	If (_lSldBanco)
		sfSldConta()
	EndIf
	
	//Monta Arquivo de Trabalho para Visualizar os dados
	sfMontaTRB()

	// inicia processo que alimenta o arquivo de trabalho com as Informações, conforme paramentros
	oProc := MsNewProcess():New({|lEnd| sfMontaDados() },"","",.F.)
	oProc:Activate()
	
	//Monta a Tela para Mostrar as Informações do Fluxo
	sfDlgFluxo()
	
Return

//Monta a tela Principal com os dados do Fluxo de Caixa
Static Function sfDlgFluxo()
	Local aButtons := {}
	// campos do browse
	Local _aBrwFlx := {}

	// define as colunas a serem apresentada
	aAdd(_aBrwFlx,{"FLX_DESCRI"	,,"Descrição","@!"  } )
	//aAdd(_aBrwFlx,{"FLX_OPERAD"	,,"Operador","@!" } )
	//aAdd(_aBrwFlx,{"FLX_TOTALI"	,,"Totaliza","@!" } )
	//aAdd(_aBrwFlx,{"FLX_GRUPO"		,,"Grupo","@!" } )
	//aAdd(_aBrwFlx,{"FLX_TIPO"	,,"Tipo","@!" } )
	//aAdd(_aBrwFlx,{"FLX_CODIGO"	,,"Cod Tópico","@!" } )
	// inclui as colunas das datas
	For nData := 1 to Len(_vDatas)
		aAdd(_aBrwFlx, {_vDatas[nData,1],,_vDatas[nData,4],"@E 999,999,999.99"} )
	Next nData
	// coluna do total
	aAdd(_aBrwFlx, {"FLX_VLRTOT",,"Total","@E 999,999,999.99"} )
	
	// adiciona o botao para exportar os dados para o excel
	Aadd(aButtons,{ PmsBExcel()[1] ,;
					{||	MsgRun("Favor Aguardar.....", "Exportando os Registros para o Excel",{|| sfExpExcel("_TRBFLX",_aBrwFlx,"FLUXO DE CAIXA") })} ,;
					"Exportar pro Excel" ,;
					"Exp. Excel" ,;
					{|| .T.}} )

	// leitura das coordenadas da tela principal
	_oDlgFluxo := MsDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Fluxo de Caixa",,,.F.,,,,,,.T.,,,.F.)
	_oDlgFluxo:lMaximized := .T.

	// cabecalho
	_oPnlTop:= TPanel():New(1,1,,_oDlgFluxo,,.T.,.F.,,,1,40,,)
	_oPnlTop:Align := CONTROL_ALIGN_TOP

	// saldos em banc/caixa
	_oGrpSaldo	:= TGroup():New(002,004,037,108,"Saldos",_oPnlTop,,,.T.,.F. )
	_oSayCaixa	:= TSay():New( 012,008,{||"Em Caixa"},_oGrpSaldo,,,.F.,.F.,.F.,.T.,,,032,008)
	_oGetCaixa	:= TGet():New( 010,040,{|u| If(PCount()>0,_nSldCaixa:=u,_nSldCaixa)},_oGrpSaldo,060,008,PesqPict("SA6","A6_SALATU"),{||sfSldFinal(.t.)},,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nSldCaixa",,)
	_oSayBanco	:= TSay():New( 024,008,{||"Em Banco"},_oGrpSaldo,,,.F.,.F.,.F.,.T.,,,032,008)
	_oGetBanco  := TGet():New( 023,040,{|u| If(PCount()>0,_nSldBanco:=u,_nSldBanco)},_oGrpSaldo,060,008,PesqPict("SA6","A6_SALATU"),{||sfSldFinal(.t.)},,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nSldBanco",,)

	// titulos em atraso
	_oGrpAtras	:= TGroup():New(002,118,037,226,"Titulos Atrasados",_oPnlTop,,,.T.,.F. )
	_oSayCaixa	:= TSay():New( 012,126,{||"A Pagar"},_oGrpAtras,,,.F.,.F.,.F.,.T.,,,032,008)
	_oGetCaixa	:= TGet():New( 010,158,{|u| If(PCount()>0,_nAtrPagar:=u,_nAtrPagar)},_oGrpAtras,060,008,PesqPict("SA6","A6_SALATU"),{||sfSldFinal(.t.)},,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nAtrPagar",,)
	_oSayBanco	:= TSay():New( 024,126,{||"A Receber"},_oGrpAtras,,,.F.,.F.,.F.,.T.,,,032,008)
	_oGetBanco  := TGet():New( 023,158,{|u| If(PCount()>0,_nAtrReceb:=u,_nAtrReceb)},_oGrpAtras,060,008,PesqPict("SA6","A6_SALATU"),{||sfSldFinal(.t.)},,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nAtrReceb",,)

	// titulo da janela
	_oSayTitulo := TSay():New(005,235,{||"Fluxo de Caixa - Visão por "+If(_nVisao==1,"Natureza","Centro de Custo")},_oPnlTop,,fFonte2,,,,.T.,CLR_GREEN,,)

	// browse com os detalhes do fluxo de caixa
	_oBrwFluxo := MsSelect():New("_TRBFLX",,,_aBrwFlx,,,{15,1,183,373})
	_oBrwFluxo:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwFluxo:oBrowse:oFont := fFonte1
	//_oBrwFluxo:oBrowse:nFreeze := 1
	_oBrwFluxo:oBrowse:blDblClick := {|| Processa( {|| sfDetalhes() ,"Aguarde..." } ) }

	// muda a cor da linha definida
	//_oBrwFluxo:oBrowse:aColumns[1]:bClrBack := {|SETVAL| If(FLX_TOTALI=="S", CLR_HGRAY , If(FLX_TOTALI=="T", CLR_HGREEN ,  ) )}

	// define o foco do objeto
	_oBrwFluxo:oBrowse:SetFocus()

	Activate Dialog _oDlgFluxo On Init EnchoiceBar(_oDlgFluxo,{||_oDlgFluxo:End()},{||_oDlgFluxo:End()},,@aButtons) Centered

Return

//** funcao que Separa as datas conforme Parametros
Static Function sfSepPeriodo()
	Local _dDtIniTmp	:= _dDtIni
	Local _dDtFimTmp	:= CtoD("//")
    Local _cTipoData	:= ""
	// estrutura do arquivo TRB
	Local _aStrData := {}    

    If (_nPeriod==1)
    	_cTipoData := "DIA001"
    ElseIf (_nPeriod==7)
    	_cTipoData := "SEM001"
    ElseIf (_nPeriod==15)
    	_cTipoData := "QUI001"
    ElseIf (_nPeriod==30)
	    _cTipoData := "MES001"
    EndIf

	// zera vetor
	_vDatas	:= {}
    
    // define a estrutura do TRB
	aAdd(_aStrData,{"DT_OK"   ,"C", 2,0})
	aAdd(_aStrData,{"DT_COD"  ,"C", 6,0})
	aAdd(_aStrData,{"DT_DESC" ,"C",20,0})
	aAdd(_aStrData,{"DT_INI"  ,"D", 8,0})
	aAdd(_aStrData,{"DT_FIM"  ,"D", 8,0})

	If (Select("_TRBDATA")<>0)
		dbSelectArea("_TRBDATA")
		dbCloseArea()
	EndIf
	// cria o arquivo
	_cTrbData := CriaTrab(_aStrData,.t.)
	dbUseArea(.T.,,_cTrbData,"_TRBDATA",NIL,.F. )
    


	While _dDtIniTmp <= _dDtFim

		If (_dDtIniTmp + (_nPeriod-1)) > _dDtFim
			_dDtFimTmp := _dDtFim
		Else
			If _nPeriod == 7 //Semanal

				_dDtFimTmp := _dDtIniTmp + (_nPeriod-1)

				lSemana := .F.
				While ! lSemana
					
					If Dow(_dDtFimTmp) == 7
						lSemana := .T.
					Else
						_dDtFimTmp --
					EndIf

				EndDo
			ElseIf _nPeriod == 30 //Mensal
				_dDtFimTmp := LastDay(_dDtIniTmp)
			Else
				_dDtFimTmp := _dDtIniTmp + (_nPeriod-1)
			EndIf

		EndIf
		
		//Monta Titulo das Colunas para o Browse
		If Left(_cTipoData,3) == "DIA"
			cTitulo := "Dia " + Left(DtoC(_dDtIniTmp),5)
		ElseIf Left(_cTipoData,3) == "SEM" .or. Left(_cTipoData,3) == "QUI"
			cTitulo := Left(DtoC(_dDtIniTmp),5) + " a " + Left(DtoC(_dDtFimTmp),5)
		ElseIf Left(_cTipoData,3) == "MES"
			cTitulo := AllTrim(MesExtenso(Month(_dDtIniTmp))) + " (" + AllTrim(Str(Day(_dDtIniTmp))) + " a " + AllTrim(Str(Day(_dDtFimTmp))) + ")"
		EndIf
		
		// adiciona as informacoes
		aAdd(_vDatas,{_cTipoData,_dDtIniTmp,_dDtFimTmp,cTitulo})
		// alimenta o TRB
		dbSelectArea("_TRBDATA")
		RecLock("_TRBDATA",.t.)
			_TRBDATA->DT_OK   := Space(2)
			_TRBDATA->DT_COD  := _cTipoData
			_TRBDATA->DT_DESC := cTitulo
			_TRBDATA->DT_INI  := _dDtIniTmp
			_TRBDATA->DT_FIM  := _dDtFimTmp
		MsUnLock()
		// controle de variaveis
		_dDtIniTmp := _dDtFimTmp + 1
		_cTipoData := Soma1(_cTipoData)
	EndDo
Return

//** funcao que monta o arquivo de trabalho (TRB), com a estrutura da visao
Static Function sfMontaTRB
	Local vEstFlx	:= {}

	aAdd(vEstFlx,{"FLX_TOTALI"	,"C", 1,0})
	aAdd(vEstFlx,{"FLX_GRUPO"	,"C", 3,0})
	aAdd(vEstFlx,{"FLX_TIPO"	,"C", 1,0})
	aAdd(vEstFlx,{"FLX_CODIGO"	,"C",TamSx3(If(_nVisao==1,"ED_CODIGO","CTT_CUSTO"))[1],0})
	aAdd(vEstFlx,{"FLX_OPERAD"	,"C", 1,0})
	aAdd(vEstFlx,{"FLX_DESCRI"	,"C",TamSx3(If(_nVisao==1,"ED_DESCRIC","CTT_DESC01"))[1],0})
	
	For nData := 1 to Len(_vDatas)
		aAdd(vEstFlx,{ _vDatas[nData,1] , "N" ,14, 2 } )
	Next nData
	
	aAdd(vEstFlx,{"FLX_VLRTOT"	, "N",14,2})

	If (Select("_TRBFLX")<>0)
		dbSelectArea("_TRBFLX")
		dbCloseArea()
	EndIf

	cArqFlx := CriaTrab(vEstFlx,.t.)

	dbUseArea (.T.,,cArqFlx,"_TRBFLX",NIL,.F.)
	// define o indice
	IndRegua("_TRBFLX", cArqFlx,"FLX_GRUPO+FLX_TIPO+FLX_CODIGO",,,"Selecionando registros...")

Return

//Função que Busca as informações conforme parametro e alimenta Arquivo de Trabalho
Static Function sfMontaDados

	// define a quantidade itens a processar
	oProc:SetRegua1( 7 )

	// titulos a pagar vencidos
	oProc:IncRegua1("Titulos em Atraso a Pagar...")
	If (_lTitAtraso)
		_nAtrPagar := sfRetVencido("SE2")
	EndIf

	// titulos a receber vencidos
	oProc:IncRegua1("Titulos em Atraso a Receber...")
	If (_lTitAtraso)
		_nAtrPagar := sfRetVencido("SE1")
	EndIf

	// contas a receber
	oProc:IncRegua1("Contas a Receber...")
	If (_lConRec) 
		// executa rotina
		sfContaRec()
	EndIf

	// contas a Pagar	
	oProc:IncRegua1("Contas a Pagar...")
	If (_lConPag) 
		// executa rotina
		sfContaPag()
	EndIf
	
	// Pedidos de Compras
	oProc:IncRegua1("Pedidos de Compras...")
	If (_lPedCom) 
		// executa rotina
		sfPedCompra()
	EndIf

	// pedidos de venda
	oProc:IncRegua1("Pedidos de Vendas...")
	If (_lPedVend) 
		// executa rotina
		sfPedVenda()
	EndIf

	// simulacoes
	oProc:IncRegua1("Carregando Simulacoes...")
	If (_lSimula)
		// executa rotina
		sfSimula()
	EndIf

	// atualiza o saldo acumulado
	sfSldFinal(.f.)
		
	DBSelectArea("_TRBFLX")
	_TRBFLX->( DBGoTop() )
	
Return

//** Funcao que busca os Dados das Contas a Receber
Static Function sfContaRec()
	Local _nSaldoTit := 0
	Local _cQuery
	Local _nData
	Local _cCampo
	// quantidade de registros a processar
	Local _nQtdReg
	// controle do group by
	Local _cQryGroup := ""

	// inclui uma linha com o titulo de contas a receber
	dbSelectArea("_TRBFLX")
	RecLock("_TRBFLX",.T.)
		_TRBFLX->FLX_GRUPO	:= "001"
		_TRBFLX->FLX_TIPO	:= "0"
		_TRBFLX->FLX_DESCRI	:= "..CONTAS A RECEBER"
	MsUnLock()

	_cQuery := "SELECT "
	// visao por natureza
	If (_nVisao==1)
		_cQuery    += "E1_NATUREZ IT_TOPICO, "
		_cQryGroup += "E1_NATUREZ, "
	// visao por Centro de Custo
	ElseIf (_nVisao==2)
		_cQuery    += "CASE WHEN (SUBSTRING(F2_ZCC,1,5)='01004')OR(F2_ZCC IN ('0100204','0100208')) THEN '01004' ELSE F2_ZCC END IT_TOPICO, "
		_cQryGroup += "CASE WHEN (SUBSTRING(F2_ZCC,1,5)='01004')OR(F2_ZCC IN ('0100204','0100208')) THEN '01004' ELSE F2_ZCC END, "
	EndIf
	_cQuery    += "E1_VENCREA, SUM(E1_SALDO * (CASE WHEN E1_TIPO IN "+_cQryAbatim+" THEN -1 ELSE 1 END)) E1_SALDO "
	_cQryGroup += "E1_VENCREA "
	// tabela de titulos a receber
	_cQuery += "FROM "+RetSQLName("SE1")+" SE1 "
	// visao por Centro de Custo, busca os dados da nota
	If (_nVisao==2)
		_cQuery += "LEFT JOIN "+RetSQLName("SF2")+" SF2 ON F2_FILIAL = E1_FILORIG AND SF2.D_E_L_E_T_ = ' ' "
		_cQuery += "AND F2_DUPL = E1_NUM AND F2_PREFIXO = E1_PREFIXO "
		_cQuery += "AND F2_CLIENTE = E1_CLIENTE AND F2_LOJA = E1_LOJA "
	EndIf
	// filtros
	_cWhereSE1 := "WHERE E1_FILIAL = '" +xFilial("SE1")+ "' AND SE1.D_E_L_E_T_ <> '*' "
	_cWhereSE1 += "AND E1_SALDO <> 0 "
	_cWhereSE1 += "AND E1_FLUXO <> 'N' "
	// adiciona na query padrao
	_cQuery += _cWhereSE1
	_cQuery += "AND E1_VENCREA >= '" +DtoS(_dDtIni)+ "' AND E1_VENCREA <= '" +DtoS(_dDtFim)+ "' "
	
	_cQuery += "GROUP BY "+_cQryGroup
	
	// padroniza a query
	_cQuery := ChangeQuery(_cQuery)

	memowrit("c:\query\conrec.txt",_cQuery)

	If (Select("_QRYREC")<>0)
		dbSelectArea("_QRYREC")
		dbCloseArea()
	EndIf

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),"_QRYREC",.T.,.T.)
	TcSetField("_QRYREC","E1_VENCREA","D")
	// armazena a quantidade de registro da query
	Count to _nQtdReg

	DBSelectArea("_QRYREC")
	_QRYREC->( DBGoTop() )

	// seta tamanho da regua de processamento
	oProc:SetRegua2(_nQtdReg)

	DBSelectArea("_QRYREC")
	// varre todos os registros
	While _QRYREC->(!Eof())

		// controle da regua de processamento
		oProc:IncRegua2()

		For _nData := 1 to Len(_vDatas)
			If (_QRYREC->E1_VENCREA >= _vDatas[_nData,2]).and.(_QRYREC->E1_VENCREA <= _vDatas[_nData,3])
				_cCampo := _vDatas[_nData, 1]
				Exit
			EndIf
		Next _nData

		// posiciona no SE1 para Buscar o Saldo do Titulo
		//SE1->(DBGoTo(_QRYREC->SE1RECNO))
		
		_nSaldoTit := _QRYREC->E1_SALDO
/*		
		// busca Saldo dos Titulos
		_nSaldoTit := SaldoTit(	SE1->E1_PREFIXO, ;
								SE1->E1_NUM, ;
								SE1->E1_PARCELA, ;
								SE1->E1_TIPO, ;
								SE1->E1_NATUREZ, ;
								"R", ;
								SE1->E1_CLIENTE, ;
								1, ;
								SE1->E1_VENCREA,, ;
							 	SE1->E1_LOJA,, ;
								SE1->E1_TXMOEDA)
*/
/*
		// adiciona dados ao vetor dos dados analiticos
		aAdd(_vDtConRec, {	_QRYREC->IT_TOPICO ,;
							SE1->E1_PREFIXO ,;
							SE1->E1_NUM ,;
							SE1->E1_PARCELA ,;
							SE1->E1_TIPO ,;
							SE1->E1_CLIENTE ,;
							SE1->E1_LOJA ,;
							Posicione("SA1",1, xFilial("SA1")+SE1->(E1_CLIENTE+E1_LOJA) ,"A1_NREDUZ") ,;
							SE1->E1_VENCREA ,;
							_nSaldoTit } )
*/							

		// adiciona informações no Fluxo
		sfAddFluxo(_QRYREC->IT_TOPICO, "001", _cCampo, _nSaldoTit, .f.)

		// proximo registro
		_QRYREC->(dbSkip())
	EndDo
	// fecha o alias da query
	dbSelectArea("_QRYREC")
	dbCloseArea()

Return

//** funcao que busca os Dados das Contas a Pagar
Static Function sfContaPag()
	Local _nSaldoTit := 0
	Local _cQuery
	Local _nData
	Local _cCampo
	// quantidade de registros a processar
	Local _nQtdReg
	// controle do group by
	Local _cQryGroup := ""

	// inclui uma linha com o titulo de contas a pagar
	dbSelectArea("_TRBFLX")
	RecLock("_TRBFLX",.T.)
		_TRBFLX->FLX_GRUPO	:= "002"
		_TRBFLX->FLX_TIPO	:= "0"
		_TRBFLX->FLX_DESCRI	:= "..CONTAS A PAGAR"
	MsUnLock()
    
	_cQuery := "SELECT "
	// visao por natureza
	If (_nVisao==1)
		_cQuery    += "E2_NATUREZ IT_TOPICO, "
		_cQryGroup += "E2_NATUREZ, "
	// visao por Centro de Custo
	ElseIf (_nVisao==2)
		_cQuery    += "CASE WHEN (SUBSTRING(E2_CCD,1,5)='01004')OR(E2_CCD IN ('0100204','0100208')) THEN '01004' ELSE E2_CCD END IT_TOPICO, "
		_cQryGroup += "CASE WHEN (SUBSTRING(E2_CCD,1,5)='01004')OR(E2_CCD IN ('0100204','0100208')) THEN '01004' ELSE E2_CCD END, "
	EndIf
	//_cQuery += "E2_VENCREA, SE2.R_E_C_N_O_ SE2RECNO "
	_cQuery    += "E2_VENCREA, SUM(E2_SALDO) E2_SALDO "
	_cQryGroup += "E2_VENCREA"
	// tabela de titulos a pagar
	_cQuery += "FROM "+RetSqlName("SE2")+" SE2 "
	// filtros
	_cWhereSE2 := "WHERE E2_FILIAL = '"+xFilial("SE2")+"' AND SE2.D_E_L_E_T_ != '*' "
	_cWhereSE2 += "AND E2_SALDO <> 0 "
	_cWhereSE2 += "AND E2_FLUXO <> 'N' "
	// adiciona na query padrao
	_cQuery += _cWhereSE2
	_cQuery += "AND E2_VENCREA >= '"+DtoS(_dDtIni)+"' AND E2_VENCREA <= '"+DtoS(_dDtFim)+"' "
	//_cQuery += "AND E2_TIPO NOT IN "+FormatIn(MVRECANT+MVPAGANT,,3)+" "

	// agrpamento de dados
	_cQuery += "GROUP BY "+_cQryGroup

	// padroniza a query
	_cQuery := ChangeQuery(_cQuery)

	If (Select("_QRYPAG") <> 0)
		dbSelectArea("_QRYPAG")
		dbCloseArea()
	EndIf	

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),"_QRYPAG",.T.,.T.)
	TcSetField("_QRYPAG","E2_VENCREA","D")
	// armazena a quantidade de registro da query
	Count to _nQtdReg

	DBSelectArea("_QRYPAG")
	_QRYPAG->(dbGoTop())

	// seta tamanho da regua de processamento
	oProc:SetRegua2(_nQtdReg)

	// varre todos os registros
	While _QRYPAG->(!Eof())

		// controle da regua de processamento
		oProc:IncRegua2()

		For _nData := 1 to Len(_vDatas)
			If (_QRYPAG->E2_VENCREA >= _vDatas[_nData,2]).and.(_QRYPAG->E2_VENCREA <= _vDatas[_nData,3])
				_cCampo := _vDatas[_nData,1]
				Exit
			EndIf
		Next _nData
		
		_nSaldoTit := _QRYPAG->E2_SALDO

/*		
		// posiciona no SE2 para Buscar o Saldo do Titulo
		SE2->(dbGoTo(_QRYPAG->SE2RECNO))
		// busca Saldo dos Titulos
		_nSaldoTit := SaldoTit(	SE2->E2_PREFIXO, ;
								SE2->E2_NUM, ;
								SE2->E2_PARCELA, ;
								SE2->E2_TIPO, ;
								SE2->E2_NATUREZ, ;
								"P", ;
								SE2->E2_FORNECE, ;
								1, ;
								SE2->E2_VENCREA,, ;
								SE2->E2_LOJA )
*/

/*
		// adiciona dados ao vetor dos dados analiticos
		aAdd(_vDtConPag, {	_QRYPAG->IT_TOPICO ,;
							SE2->E2_PREFIXO ,;
							SE2->E2_NUM ,;
							SE2->E2_PARCELA ,;
							SE2->E2_TIPO ,;
							SE2->E2_FORNECE ,;
							SE2->E2_LOJA ,;
							Posicione("SA2",1, xFilial("SA2")+SE2->(E2_FORNECE+E2_LOJA) ,"A2_NREDUZ") ,;
							SE2->E2_VENCREA ,;
							_nSaldoTit } )
*/			
		// adiciona informações no Fluxo
		sfAddFluxo(_QRYPAG->IT_TOPICO, "002", _cCampo, _nSaldoTit, .f.)
		
		// proximo registro
		_QRYPAG->( DBSkip() )
	EndDo
	// fecha o alias da query
	dbSelectArea("_QRYPAG")
	dbCloseArea()
	
Return

//** funcao que Busca os Dados dos Pedidos de Compras
Static Function sfPedCompra()
	Local _cQuery
	Local _cQryGroup
	Local _nPrc
	Local _nData
	Local _cTmpCampo
	// quantidade de registro da query
	Local _nQtdReg	:= 0
	// parcelas de vencimentos
	Local _aParcela	:= {}
	Local _dDtPgto	:= CtoD("//")
	Local _nVlrParc	:= 0

	// inclui uma linha com o titulo de contas a receber
	dbSelectArea("_TRBFLX")
	RecLock("_TRBFLX",.T.)
		_TRBFLX->FLX_GRUPO	:= "003"
		_TRBFLX->FLX_TIPO	:= "0"
		_TRBFLX->FLX_DESCRI	:= "..PEDIDOS DE COMPRA"
	MsUnLock()


	_cQuery := "SELECT "
	// visao por natureza
	If (_nVisao==1)
		// nao tem campo natureza
		_cQuery    += "' ' IT_TOPICO, "
		_cQryGroup := ""
	// visao por Centro de Custo
	ElseIf (_nVisao==2)
		_cQuery    += "CASE WHEN (SUBSTRING(C7_CC,1,5)='01004')OR(C7_CC IN ('0100204','0100208')) THEN '01004' ELSE C7_CC END IT_TOPICO, "
		_cQryGroup := "CASE WHEN (SUBSTRING(C7_CC,1,5)='01004')OR(C7_CC IN ('0100204','0100208')) THEN '01004' ELSE C7_CC END, "
	EndIf
	_cQuery    += "C7_NUM, C7_COND, C7_FORNECE, C7_LOJA, C7_DATPRF, SUM(C7_TOTAL) C7_TOTAL "
	_cQryGroup += "C7_NUM, C7_COND, C7_FORNECE, C7_LOJA, C7_DATPRF "
	// tabela de pedidos de compras	
	_cQuery += "FROM "+RetSqlName("SC7")+" SC7 "
	// verifica se TES se gera financeiro
	_cQuery += "INNER JOIN "+RetSqlName("SF4")+" SF4 ON F4_FILIAL = '"+xFilial("SF4")+"' AND F4_CODIGO = C7_COND AND SF4.D_E_L_E_T_ = ' ' "
	_cQuery += "AND F4_DUPLIC = 'S' "
	// filtros
	_cQuery += "WHERE C7_FILIAL = '"+xFilial("SC7")+"' AND SC7.D_E_L_E_T_ <> '*' "
	_cQuery += "AND (C7_QUANT - C7_QUJE) <> 0 "
	_cQuery += "AND C7_RESIDUO <> 'S' "
	_cQuery += "GROUP BY "+_cQryGroup
	_cQuery += "ORDER BY C7_NUM"

	// padroniza a query
	_cQuery := ChangeQuery(_cQuery)
	
	MemoWrit("c:\query\ped_compras.txt",_cQuery)

	If (Select("_QRYSC7")<>0)
		dbSelectArea("_QRYSC7")
		dbCloseArea()
	EndIf

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),"_QRYSC7",.T.,.T.)
	TcSetField("_QRYSC7","C7_DATPRF","D")
	// armazena a quantidade de registro da query
	Count to _nQtdReg

	DBSelectArea("_QRYSC7")
	_QRYSC7->(dbGoTop())

	// seta tamanho da regua de processamento
	oProc:SetRegua2(_nQtdReg)

	While _QRYSC7->(!Eof())

		// controle da regua de processamento
		oProc:IncRegua2()

		// conforme a data prevista de entrega, utiliza a condicao de pagamento para gerar as parcelas
		_aParcela := Condicao(_QRYSC7->C7_TOTAL, _QRYSC7->C7_COND,, _QRYSC7->C7_DATPRF)
		
		For _nPrc := 1 to Len(_aParcela)
			// data Vencimento
			_dDtPgto  := _aParcela[_nPrc,1]
			// valor da parcela
			_nVlrParc := _aParcela[_nPrc,2] 
            
			If (_dDtPgto>=_dDtIni).and.(_dDtPgto<=_dDtFim)
				For _nData := 1 to Len(_vDatas)
					If (_dDtPgto >= _vDatas[_nData,2]).and.(_dDtPgto <= _vDatas[_nData,3])
						_cTmpCampo := _vDatas[_nData,1]
						Exit
					EndIf
				Next _nData
				
				// adiciona informações no Fluxo
				sfAddFluxo( If(_QRYSC7->(FieldPos("IT_TOPICO"))>0,_QRYSC7->IT_TOPICO,""),;
							"003", _cTmpCampo, _nVlrParc, .f.)
				
				// alimenta Vetor com os Dados Detalhados dos Pedidos de Compras
				aAdd(_vDtPedCom, {	If(_QRYSC7->(FieldPos("IT_TOPICO"))>0,_QRYSC7->IT_TOPICO,""),;
									_QRYSC7->C7_NUM ,;
									Posicione("SA2",1, xFilial("SA2")+_QRYSC7->(C7_FORNECE+C7_LOJA) ,"A2_NREDUZ") ,;
									_dDtPgto ,;
									_nVlrParc })
			EndIf
		
		Next _nPrc

		_QRYSC7->(dbSkip())
	EndDo
Return

//** funcao que inclui as informacoes no fluxo e Atualiza os Saldos
// parametros:
// 1-Codigo (topico) - Naureza ou Centro de Custo
// 2-Grupo (001-Receber / 002-Pagar / 003-Pedidos de Compras / 004-Pedidos de Venda)
// 3-Campo (nome da coluna do mes/dia do periodo)
// 4-Valor
// ex: sfAddFluxo("101001", "001", "MES001", 10.88 ,.f.)
Static Function sfAddFluxo(mvTopico, mvGrupo, mvCampo, mvValor, mvSimula)

	Local _cOperad	:= ""
	Local _cDescri	:= ""
	Local _cTotaliz := ""
	Local _cCodPai	:= ""
	Local _cSubTot	:= "ZZZZZZ"
	Local _cDscSbTo	:= ""
	Local _cTpDetal	:= If(mvSimula,"8","1")
	
    // visao por natureza
    If (_nVisao==1)
    	dbSelectArea("SED")
    	SED->(dbSetOrder(1)) //1-ED_FILIAL, ED_CODIGO
    	If SED->(dbSeek( xFilial("SED")+mvTopico ))
			_cDescri := AllTrim(SED->ED_DESCRIC) + If(mvSimula," (*)","")
    	Else
			_cDescri := "SEM CADASTRO" + If(mvSimula," (*)","")
    	EndIf
    // visao por centro de custo
    ElseIf (_nVisao==2)
    	dbSelectArea("CTT")
    	CTT->(dbSetOrder(1)) //1-CTT_FILIAL, CTT_CUSTO
    	If CTT->(dbSeek( xFilial("CTT")+mvTopico ))
			_cDescri := AllTrim(CTT->CTT_DESC01) + If(mvSimula," (*)","")
    	Else
			_cDescri := "SEM CADASTRO" + If(mvSimula," (*)","")
    	EndIf
    EndIf
   
	// define o operador
	// 2-Grupo (001-Receber / 002-Pagar / 003-Pedidos de Compras / 004-Pedidos de Venda)
	If (mvGrupo $ "002/003")
		cOperad   := "-"
	ElseIf (mvGrupo$"001/004")
		cOperad   := "+"
	EndIf
	
	// define o titulo do sub-total
	If (mvGrupo=="001")
		_cDscSbTo := "A RECEBER"
	ElseIf (mvGrupo=="002")
		_cDscSbTo := "A PAGAR"
	ElseIf (mvGrupo=="003")
		_cDscSbTo := "DE PEDIDOS DE COMPRA"
	ElseIf (mvGrupo=="004")
		_cDscSbTo := "DE PEDIDOS DE VENDA"
	EndIf

	// atualiza valores no TRB
	DBSelectArea("_TRBFLX")
	_TRBFLX->( DBSetOrder(1) )

	// inclui as informacoes dos detalhes
	If _TRBFLX->( DBSeek( mvGrupo+_cTpDetal+mvTopico ) )
		RecLock("_TRBFLX",.F.)
			// atualiza a descricao toda vez, para casos de simulacoes
			_TRBFLX->FLX_DESCRI	:= "...."+_cDescri
			_TRBFLX->&mvCampo	+= mvValor
			_TRBFLX->FLX_VLRTOT	+= mvValor
		_TRBFLX->( MsUnLock() )
	Else
		RecLock("_TRBFLX",.T.)
			_TRBFLX->FLX_GRUPO	:= mvGrupo
			_TRBFLX->FLX_TIPO	:= _cTpDetal // 1-detalhe / 8-Simulacao
			_TRBFLX->FLX_CODIGO	:= mvTopico
			_TRBFLX->FLX_OPERAD	:= cOperad
			_TRBFLX->FLX_DESCRI	:= "...."+_cDescri
			_TRBFLX->FLX_TOTALI := _cTotaliz
			_TRBFLX->&mvCampo	+= mvValor
			_TRBFLX->FLX_VLRTOT	+= mvValor
		_TRBFLX->( MsUnLock() )
	EndIf
	
	// atualiza Sub-Total do Saldo por Categoria
	If _TRBFLX->(dbSeek( mvGrupo+"9"+_cSubTot ))
		RecLock("_TRBFLX",.F.)
			_TRBFLX->&mvCampo	+= mvValor
			_TRBFLX->FLX_VLRTOT	+= mvValor
		_TRBFLX->( MsUnLock() )
	Else
		RecLock("_TRBFLX",.T.)
			_TRBFLX->FLX_GRUPO	:= mvGrupo
			_TRBFLX->FLX_TIPO	:= "9" // 9-Total
			_TRBFLX->FLX_CODIGO	:= _cSubTot
			_TRBFLX->FLX_OPERAD	:= "="
			_TRBFLX->FLX_DESCRI	:= "..SUB-TOTAL "+_cDscSbTo
			_TRBFLX->FLX_TOTALI := "N"
			_TRBFLX->&mvCampo	+= mvValor
			_TRBFLX->FLX_VLRTOT	:= mvValor
		_TRBFLX->( MsUnLock() )
	EndIf
			
	// atualiza a Linha de Saldos do dia
	If _TRBFLX->(dbSeek( "999"+"9"+"000000" ))
		RecLock("_TRBFLX",.f.)
			If cOperad == "-"
				_TRBFLX->&mvCampo	-= mvValor
				_TRBFLX->FLX_VLRTOT	-= mvValor
			ElseIf cOperad == "+"
				_TRBFLX->&mvCampo	+= mvValor
				_TRBFLX->FLX_VLRTOT	+= mvValor
			EndIf
		_TRBFLX->( MsUnLock() )
	Else
		RecLock("_TRBFLX",.T.)
			_TRBFLX->FLX_GRUPO	:= "999"
			_TRBFLX->FLX_TIPO	:= "9" // 9-Total
			_TRBFLX->FLX_CODIGO	:= "000000"
			_TRBFLX->FLX_OPERAD	:= "="
			_TRBFLX->FLX_DESCRI	:= "SALDO DO DIA"
			_TRBFLX->FLX_TOTALI	:= "S"
			If cOperad == "-"
				_TRBFLX->&mvCampo	-= mvValor
				_TRBFLX->FLX_VLRTOT	-= mvValor
			ElseIf cOperad == "+"
				_TRBFLX->&mvCampo	+= mvValor
				_TRBFLX->FLX_VLRTOT	+= mvValor
			EndIf
		_TRBFLX->( MsUnLock() )
	EndIf

Return

//** funcao que Detalha os dados do Fluxo de Caixa (duplo click)
Static Function sfDetalhes()
	
	// so executa o detalhe para linha com o tipo 1-Detalhe/8-Simulacao
	If (!(_TRBFLX->FLX_TIPO $ "1/8"))
		MsgStop("Opção de detalhe não disponível para este registro.")
		Return(.f.)
	EndIf
	
	// detalhes de contas a pagar e receber
	If (_TRBFLX->FLX_TIPO=="1").and.(_TRBFLX->FLX_GRUPO$"001/002")
		Processa({|| sfDtTitulos() },"Detalhes das Contas a Receber/Pagar...") 
	// detalhes dos pedidos de compra
	ElseIf (_TRBFLX->FLX_TIPO=="1").and.(_TRBFLX->FLX_GRUPO=="003")
		Processa({|| sfDtPedCom( _TRBFLX->FLX_CODIGO ) },"Detalhes dos Pedidos de Compras...") 
	// detalhes dos pedidos de venda
	ElseIf (_TRBFLX->FLX_TIPO=="1").and.(_TRBFLX->FLX_GRUPO=="004")
		Processa({|| sfDtPedVen( _TRBFLX->FLX_CODIGO ) },"Detalhes dos Pedidos de Venda...") 
	// detalhes das simulacoes
	ElseIf (_TRBFLX->FLX_TIPO=="8")
		Processa({|| sfDtSimula() },"Detalhes das Simulacoes...") 
	EndIf
	
	DBSelectArea("_TRBFLX")

Return

//** funcao para escolha do periodo
Static Function sfSelData(mvCmpFiltro,mvQryVencto)
	Local _aBrwData := {}
	Local _cMarcaOk := GetMark()
	Local _lRet := .f.
	
	// inicia a query
	mvQryVencto := If(_nPeriod==1,mvCmpFiltro+" IN (","")

	// define as colunas
	aAdd(_aBrwData,{"DT_OK"  ,," ","@!"})
	aAdd(_aBrwData,{"DT_DESC",,"Descrição","@!"})
	
	dbSelectArea("_TRBDATA")
	_TRBDATA->(dbGoTop())

	// monta a tela	
	_oDlgDatas := MSDialog():New(000,000,400,300,"Selecione o período desejado...",,,.F.,,,,,,.T.,,,.T. )
	// cabecalho
	_oPnlTop:= TPanel():New(1,1,,_oDlgDatas,,.T.,.F.,,,1,20,,)
	_oPnlTop:Align := CONTROL_ALIGN_TOP
	// botao para detahes do dia
	_oBtnOk   := TButton():New(005,005,"Confirmar",_oPnlTop,{|| _lRet:=.t.,_oDlgDatas:End() },060,010,,,,.T.,,"",,,,.F. )
	// botao pra fechar
	_oBtnSair := TButton():New(005,070,"Fechar",_oPnlTop,{||_oDlgDatas:End()},060,010,,,,.T.,,"",,,,.F. )
	// browse
	_oBrwDatas := MsSelect():New("_TRBDATA","DT_OK",,_aBrwData,,_cMarcaOk,{15,1,183,373})
	_oBrwDatas:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwDatas:oBrowse:lHasMark 	:= .T.
	_oBrwDatas:oBrowse:lCanAllMark	:=.T.  
	_oBrwDatas:oBrowse:bAllMark 	:= 	{|| sfMarkAll(_cMarcaOk, @_oDlgDatas)}
	// ativa a tela
	_oDlgDatas:Activate(,,,.T.)
	
	If (_lRet)
		dbSelectArea("_TRBDATA")
		_TRBDATA->(dbGoTop())
		While _TRBDATA->(!Eof())
			// descarta itens nao selecionados
			If (_TRBDATA->DT_OK <> _cMarcaOk)
				_TRBDATA->(dbSkip())
				Loop
			EndIf
			// detalhado por dia
			If (_nPeriod==1)
				mvQryVencto += "'"+DtoS(_TRBDATA->DT_INI)+"',"
			Else
				mvQryVencto += "("+mvCmpFiltro+" >= '"+DtoS(_TRBDATA->DT_INI)+"' AND "+mvCmpFiltro+" <= '"+DtoS(_TRBDATA->DT_FIM)+"') OR "
			EndIf
			// proximo item
			_TRBDATA->(dbSkip())
		EndDo
		// remove a ultima virgula ou o OR
		If (_nPeriod==1)
			mvQryVencto := Left(mvQryVencto,Len(mvQryVencto)-1)+")"
		Else
			mvQryVencto := Left(mvQryVencto,Len(mvQryVencto)-4)
		EndIf
	EndIf

	If Empty(mvQryVencto)
		MsgStop("Nenhum período selecionado...")
		Return(.f.)
	EndIf

Return(_lRet)

//** funcao que monta a Tela com os Detalhes das Contas a Receber/Pagar
Static Function sfDtTitulos()
	// filtro da qery por periodo
	Local _cQryVencto := ""
	// query dos titulos
	Local _cQuery := ""
	
	// chama tela para selecionar os periodos (datas)
	If (!sfSelData(If(_TRBFLX->FLX_GRUPO=="001","E1_VENCREA","E2_VENCREA"),@_cQryVencto))
		Return(.f.)
	EndIf

	// cria arquivo de trabalho
	sfArqTrbTit()
	
	// monta a query com os titulos
	_cQuery := "SELECT "
	If (_TRBFLX->FLX_GRUPO=="001") // receber
		_cQuery += "E1_PREFIXO IT_PREFIXO, "
		_cQuery += "E1_NUM     IT_NUM, "
		_cQuery += "E1_PARCELA IT_PARCELA, "
		_cQuery += "E1_TIPO    IT_TIPO, "
		_cQuery += "E1_NOMCLI  IT_CLI_FOR, "
		_cQuery += "E1_VENCREA IT_VENCREA, "
		_cQuery += "E1_SALDO   IT_VALOR "
		// titulos a receber
		_cQuery += "FROM "+RetSqlName("SE1")+" SE1 "
		// visao por Centro de Custo, busca os dados da nota
		If (_nVisao==2)
			_cQuery += "LEFT JOIN "+RetSQLName("SF2")+" SF2 ON F2_FILIAL = E1_FILORIG AND SF2.D_E_L_E_T_ = ' ' "
			_cQuery += "AND F2_DUPL = E1_NUM AND F2_PREFIXO = E1_PREFIXO "
			_cQuery += "AND F2_CLIENTE = E1_CLIENTE AND F2_LOJA = E1_LOJA "
		EndIf
		// filtros
		_cQuery += _cWhereSE1
		// detalhado por dia
		If (_nPeriod==1)
			_cQuery += "AND "+_cQryVencto+" "
		Else
			_cQuery += "AND ( "
			_cQuery += _cQryVencto
			_cQuery += " ) "
		EndIf
		// filtro por topico
		If (_nVisao==1) // por natureza
			_cQuery += "AND E1_NATUREZ = '"+_TRBFLX->FLX_CODIGO+"' " 
		ElseIf (_nVisao==2) // por centro de custo
			// tramento especifico para o CC de Obras
			If (AllTrim(_TRBFLX->FLX_CODIGO)=="01004")
				_cQuery += "AND (SUBSTRING(F2_ZCC,1,5)='01004') OR (F2_ZCC IN ('0100204','0100208')) "
			// em branco ou Nulo
			ElseIf Empty(_TRBFLX->FLX_CODIGO)
				_cQuery += "AND (F2_ZCC IN (' ') OR F2_ZCC IS NULL) "
			// restante dos CC
			Else
				_cQuery += "AND F2_ZCC = '"+_TRBFLX->FLX_CODIGO+"' "
			EndIf
		EndIf

	ElseIf (_TRBFLX->FLX_GRUPO=="002") // pagar
		_cQuery += "E2_PREFIXO IT_PREFIXO, "
		_cQuery += "E2_NUM     IT_NUM, "
		_cQuery += "E2_PARCELA IT_PARCELA, "
		_cQuery += "E2_TIPO    IT_TIPO, "
		_cQuery += "E2_NOMFOR  IT_CLI_FOR, "
		_cQuery += "E2_VENCREA IT_VENCREA, "
		_cQuery += "E2_SALDO   IT_VALOR "
		// titulos a pagar
		_cQuery += "FROM "+RetSqlName("SE2")+" SE2 "
		// filtros
		_cQuery += _cWhereSE2
		// detalhado por dia
		If (_nPeriod==1)
			_cQuery += "AND "+_cQryVencto+" "
		Else
			_cQuery += "AND ( "
			_cQuery += _cQryVencto
			_cQuery += " ) "
		EndIf

		// filtro por topico
		If (_nVisao==1) // por natureza
			_cQuery += "AND E2_NATUREZ = '"+_TRBFLX->FLX_CODIGO+"' " 
		ElseIf (_nVisao==2) // por centro de custo
			// tramento especifico para o CC de Obras
			If (AllTrim(_TRBFLX->FLX_CODIGO)=="01004")
				_cQuery += "AND (SUBSTRING(E2_CCD,1,5)='01004') OR (E2_CCD IN ('0100204','0100208')) "
			// restante dos CC
			Else
				_cQuery += "AND E2_CCD = '"+_TRBFLX->FLX_CODIGO+"' "
			EndIf
		EndIf
	EndIf

	// padroniza a query
	_cQuery := ChangeQuery(_cQuery)
	
	memowrit("c:\query\sfDtTitulos"+_TRBFLX->FLX_GRUPO+".txt",_cQuery)

	// alimenta o TRB com os dados do SELECT
	SqlToTrb(_cQuery,_aEsrDetTit,"_TRBDETTIT")

	If _TRBDETTIT->(RecCount()) == 0
		Aviso("Detalhes...","Este tópico não contém informações analíticas.",{"OK"})
		Return
	EndIf

	dbSelectArea("_TRBDETTIT")
	_TRBDETTIT->(dbGoTop())

	// monta a tela com os detalhes
	_oDlgDetTitulos	:= MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Detalhes dos Titulos...",,,.F.,,,,,,.T.,,,.T. )
	_oDlgDetTitulos:lMaximized := .T.
	
	// cria o panel do cabecalho (opcoes da pesquisa)
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgDetTitulos,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// botao para fechar
	_oBtnOk   := TButton():New(005,005,"Fechar",_oPnlCabec,{|| _oDlgDetTitulos:End() },050,010,,,,.T.,,"",,,,.F. )
	// botao para exportar para o excel
	_oBtnSair := TButton():New(005,060,"Exp. Excel",_oPnlCabec,{|| MsgRun("Favor Aguardar.....", "Exportando os Registros para o Excel",{|| sfExpExcel("_TRBDETTIT",_aBrwDetTit,"DETALHES DE TITULOS") }) },050,010,,,,.T.,,"",,,,.F. )
	// botao para visualizar o titulo
	_oBtnVisualizar := TButton():New(005,115,"Visualizar",_oPnlCabec,{|| },050,010,,,,.T.,,"",,,,.F. )

	// browse
	_oBrwDetTit := MsSelect():New("_TRBDETTIT",,,_aBrwDetTit,,,{15,1,183,373})
	_oBrwDetTit:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	ACTIVATE MSDIALOG _oDlgDetTitulos CENTERED

Return


//** monta arquivo de Trabalho para os Dados das Contas a Receber/PAgar
Static Function sfArqTrbTit()
	If (Len(_aEsrDetTit)==0)
		aAdd(_aEsrDetTit,{"IT_PREFIXO"	,"C",03,0})	; aAdd(_aBrwDetTit,{"IT_PREFIXO"	,,"Prefixo","@!"})
		aAdd(_aEsrDetTit,{"IT_NUM"		,"C",09,0})	; aAdd(_aBrwDetTit,{"IT_NUM"		,,"Numero" ,"@!"})
		aAdd(_aEsrDetTit,{"IT_PARCELA"	,"C",01,0})	; aAdd(_aBrwDetTit,{"IT_PARCELA"	,,"Parcela","@!"})
		aAdd(_aEsrDetTit,{"IT_TIPO"		,"C",03,0})	; aAdd(_aBrwDetTit,{"IT_TIPO"		,,"Tipo"   ,"@!"})
		aAdd(_aEsrDetTit,{"IT_CLI_FOR"	,"C",40,0})	; aAdd(_aBrwDetTit,{"IT_CLI_FOR"	,,"Cliente","@!"})
		aAdd(_aEsrDetTit,{"IT_VENCREA"	,"D",08,0})	; aAdd(_aBrwDetTit,{"IT_VENCREA"	,,"Vencto" ,"@!"})
		aAdd(_aEsrDetTit,{"IT_VALOR"	,"N",14,2})	; aAdd(_aBrwDetTit,{"IT_VALOR"		,,"Saldo"  ,PesqPict("SE1","E1_SALDO")})

		If (Select("_TRBDETTIT")<>0)
			dbSelectArea("_TRBDETTIT")
			dbCloseArea()
		EndIf
		// cria o arquivo TRB
		_cTrbDetTit := CriaTrab(_aEsrDetTit,.t.)
		dbUseArea(.T.,,_cTrbDetTit,"_TRBDETTIT",.f.,.F.)
	Else
		// apaga o conteudo do TRB
		dbSelectArea("_TRBDETTIT")
		__DbZap()
	EndIf
Return

//** funcao que Carrega as Simulacoes Criadas Por Usuarios
Static Function sfSimula()
	// vetor linha temporaria
	Local _aTmpLinha := {}
	// data de vencimento da simulacao
	Local _dDtVncto	:= CtoD("//")
	// coluna do valor
	Local _cColuna := ""
	// variaveis temporaria
	Local _nData
	
	// estrutura do arquivo TXT
	// 1-Data
	// 2-Historico
	// 3-Tipo (002/001) 1-Rec/2-Pag
	// 4-Valor
	// 5-Natureza
	// 6-Centro de Custo
	
	If !File(_cFileSim)
		MsgStop("Arquivo de simulações de fluxo não encontrado!")
		Return(.f.)
	EndIf

	// abre o arquivo
	FT_FUse(_cFileSim)
	FT_FGoTop()

	// seta tamanho da regua de processamento
	oProc:SetRegua2(FT_FLastRec())

	FT_FGoTop()

	While !FT_FEof()

		// controle da regua de processamento
		oProc:IncRegua2()

		// separa os dados da linha
		_aTmpLinha := Separa(FT_FReadln(),"^")

		// retorna a data de referencia
		_dDtVncto := CtoD( _aTmpLinha[1] )
        
		If (_dDtVncto >= _dDtIni).and.(_dDtVncto <= _dDtFim)
			For _nData := 1 to Len(_vDatas)
				If (_dDtVncto >= _vDatas[_nData,2]).and.(_dDtVncto <= _vDatas[_nData,3])
					_cColuna := _vDatas[ _nData , 1]
					Exit
				EndIf
			Next _nData
		Else
			FT_FSkip()
			Loop
		EndIf

		// adiciona os detalhes da simulacao no fluxo		
		sfAddFluxo(	_aTmpLinha[If(_nVisao==1,5,6)] ,; // topico
					_aTmpLinha[3] ,; // grupo
					_cColuna ,; //coluna do periodo
					Val(_aTmpLinha[4]) ,; // valor
					.t. ) // simulacao
		
		//Alimenta Vetor com os Dados Detalhados das Simulacoes
		aAdd(_vDtSimula,{CtoD(_aTmpLinha[1]) ,; 	// data
						 _aTmpLinha[2] ,; 			// descricao
						 _aTmpLinha[3] ,; 			// grupo
						 Val(_aTmpLinha[4]) ,; 	// valor
						 _aTmpLinha[5] } ) 			// topico

		FT_FSkip()
	EndDo
	FT_FUse() // Fecha o arquivo

Return(.t.)

//** funcao que Monta uma Tela com os Detalhes das Simulacoes
Static Function sfDtSimula()
	Local _vBrwDtSim := {}
	Local _cQryVencto := ""
	Private _nSim

	aAdd(_vBrwDtSim,{"SM_TOPICO"	,,"Topico" ,""} )
	aAdd(_vBrwDtSim,{"SM_DESCRI"	,,"Descrição", ""} )
	aAdd(_vBrwDtSim,{"SM_VENCTO"	,,"Dt Vencto" ,""} )
	aAdd(_vBrwDtSim,{"SM_VALOR"		,,"Valor" , "@E 999,999,999.99" } )

	// chama tela para selecionar os periodos (datas)
	If (!sfSelData("DtoS(_vDtSimula[_nSim,1])",@_cQryVencto))
		Return(.f.)
	EndIf
	
	// para filtro em arquivo em arquivo DBF, substituir:
	// IN por =
	_cQryVencto := StrTran(_cQryVencto," IN "," $ ")
	// OR  por .OR.
	_cQryVencto := StrTran(_cQryVencto," OR "," .OR. ")
	// AND por .AND.
	_cQryVencto := StrTran(_cQryVencto," AND "," .AND. ")
	
	// monta Arquivo de Trabalho com os Dados das Simulacoes
	sfArqTrbSim()
	
	//Alimenta o Arquivo de Trabalho com os Dados Detalhados das Simulacoes
	For _nSim := 1 to Len(_vDtSimula)
		// estrurura: _vDtSimula
		// 1-Data
		// 2-Descricao
		// 3-Grupo
		// 4-Valor
		// 5-Topico
		// compara grupo e topico
		If (_vDtSimula[_nSim, 3]==_TRBFLX->FLX_GRUPO).and.(AllTrim(_vDtSimula[_nSim, 5])==AllTrim(_TRBFLX->FLX_CODIGO)).AND.(&_cQryVencto)
			DBSelectArea("_TRBSIM")
			RecLock("_TRBSIM",.T.)
				_TRBSIM->SM_TOPICO	:= _vDtSimula[_nSim, 5]
				_TRBSIM->SM_DESCRI	:= _vDtSimula[_nSim, 2]
				_TRBSIM->SM_VENCTO	:= _vDtSimula[_nSim, 1]
				_TRBSIM->SM_VALOR	:= _vDtSimula[_nSim, 4]
			_TRBSIM->(MsUnLock())
		EndIf
	Next _nSim
	
	DBSelectArea("_TRBSIM")
	_TRBSIM->(dbGoTop())

	If _TRBSIM->(RecCount()) == 0
		Aviso("Detalhes...","Este tópico não contém informações analíticas.",{"OK"})
		Return
	EndIf

	// monta a tela com os detalhes
	_oDlgDtSimul := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Detalhes das Simulações...",,,.F.,,,,,,.T.,,,.T. )
	_oDlgDtSimul:lMaximized := .T.
	
	// cria o panel do cabecalho
	_oPnlCabSim := TPanel():New(000,000,nil,_oDlgDtSimul,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlCabSim:Align:= CONTROL_ALIGN_TOP

	// botao para fechar
	_oBtnOk   := TButton():New(005,005,"Fechar",_oPnlCabSim,{|| _oDlgDtSimul:End() },050,010,,,,.T.,,"",,,,.F. )
	// botao para exportar para o excel
	_oBtnSair := TButton():New(005,060,"Exp. Excel",_oPnlCabSim,{|| MsgRun("Favor Aguardar.....", "Exportando os Registros para o Excel",{|| sfExpExcel("_TRBSIM",_vBrwDtSim,"SIMULACOES") }) },050,010,,,,.T.,,"",,,,.F. )

	// browse
	_oBrwSimula := MsSelect():New("_TRBSIM",,,_vBrwDtSim,,,{15,1,183,373})
	_oBrwSimula:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	ACTIVATE MSDIALOG _oDlgDtSimul CENTERED

Return

//Funcao que monta a Tela com os Detalhes dos Pedidos de Compras
Static Function SFDtPedCom( mvTopExt )
	Local _cQryVencto := ""
	Local _aBrwPedCom := {}
	Private _nPC

	// monta o browse com os dados dos pedidos de compras
	aAdd(_aBrwPedCom,{"NUM_PED"	,, "Num Pedido"	,"@!"})
	aAdd(_aBrwPedCom,{"FORNECE"	,, "Fornecedor"	,"@!"})
	aAdd(_aBrwPedCom,{"VENCTO"	,, "Vencimento"	,"" })
	aAdd(_aBrwPedCom,{"VALOR"	,, "Valor"		,"@E 999,999,999.99"})

	// chama tela para selecionar os periodos (datas)
	If (!sfSelData("DtoS(_vDtPedCom[_nPC,4])",@_cQryVencto))
		Return(.f.)
	EndIf
	
	// para filtro em arquivo em arquivo DBF, substituir:
	// IN por =
	_cQryVencto := StrTran(_cQryVencto," IN "," $ ")
	// OR  por .OR.
	_cQryVencto := StrTran(_cQryVencto," OR "," .OR. ")
	// AND por .AND.
	_cQryVencto := StrTran(_cQryVencto," AND "," .AND. ")
	
	//Monta Arquivo de Trabalho
	SFArqTrbPC()
	
	For _nPC := 1 to Len(_vDtPedCom)
		If (AllTrim(_vDtPedCom[_nPC][1])==AllTrim(mvTopExt)).AND.(&_cQryVencto)
			DBSelectArea("_TRBPC")
			RecLock("_TRBPC",.T.)
				_TRBPC->NUM_PED	:= _vDtPedCom[_nPC][2]
				_TRBPC->FORNECE	:= _vDtPedCom[_nPC][3]
				_TRBPC->VENCTO	:= _vDtPedCom[_nPC][4]
				_TRBPC->VALOR	:= _vDtPedCom[_nPC][5]
			_TRBPC->(MsUnLock())
		EndIf
	Next _nPC
	
	If _TRBPC->(RecCount()) == 0
		Aviso("Detalhes...","Este tópico não contém informações analíticas.",{"OK"})
		Return
	EndIf

	_TRBPC->( DBGoTop() )

	// monta a tela com os detalhes
	_oDlgDetCom	:= MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Detalhes Pedidos de Compras...",,,.F.,,,,,,.T.,,,.T. )
	_oDlgDetCom:lMaximized := .T.
	
	// cria o panel do cabecalho (opcoes da pesquisa)
	_oPnlDetPedCom := TPanel():New(000,000,nil,_oDlgDetCom,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlDetPedCom:Align:= CONTROL_ALIGN_TOP

	// botao para fechar
	_oBtnOk   := TButton():New(005,005,"Fechar",_oPnlDetPedCom,{|| _oDlgDetCom:End() },050,010,,,,.T.,,"",,,,.F. )
	// botao para exportar para o excel
	_oBtnSair := TButton():New(005,060,"Exp. Excel",_oPnlDetPedCom,{|| MsgRun("Favor Aguardar.....", "Exportando os Registros para o Excel",{|| sfExpExcel("_TRBPC",_aBrwPedCom,"PEDIDOS DE COMPRA") }) },050,010,,,,.T.,,"",,,,.F. )
	// botao para visualizar o titulo
	_oBtnVisualizar := TButton():New(005,115,"Visualizar",_oPnlDetPedCom,{|| SFVisPedCom() },050,010,,,,.T.,,"",,,,.F. )

	// browse
	_oBrwPedCom := MsSelect():New("_TRBPC",,,_aBrwPedCom,,,{15,1,183,373})
	_oBrwPedCom:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	ACTIVATE MSDIALOG _oDlgDetCom CENTERED

Return

//Funcao para Visualizar Pedidos de Compras
Static Function SFVisPedCom()
	Private cCadastro	:= "Pedidos de Compras"
	Private aRotina		:= {{ "Pesquisar"	, "AxPesqui" , 0 , 1},;
							{ "Visualizar"	, "AxVisual" , 0 , 2}}
	//Variaveis necessarias para Usar a Funcao A120Pedido
	l120Auto := .f.
	nTipoPed := 1
	Inclui   := .f.
	Altera   := .f.

	DBSelectArea("SC7")
	SC7->( DBSetOrder( 1 ) ) //1-C7_FILIAL, C7_NUM, C7_ITEM, C7_SEQUEN
	SC7->( DBSeek(xFilial("SC7")+ _TRBPC->NUM_PED ) )
	A120Pedido( "SC7" , SC7->( RecNo() ) , 2 )

Return

//** funcao que monta arquivo de Trabalho para os Dados dos Pedidos de Compras
Static Function SFArqTrbPC
	Local vEstPC := {}

	aAdd(vEstPC,{ "NUM_PED"	,"C", 06, 0 } )
	aAdd(vEstPC,{ "FORNECE"	,"C", 40, 0 } )
	aAdd(vEstPC,{ "VENCTO"	,"D", 08, 0 } )
	aAdd(vEstPC,{ "VALOR"	,"N", 14, 2 } )

	If Select("_TRBPC") <> 0
		_TRBPC->( DBCloseArea() )
	EndIf
	cArqPC := CriaTrab(vEstPC,.t.)
	dbUseArea ( .T.,, cArqPC, "_TRBPC", NIL, .F. )
	//IndRegua("_TRBPC", cArqPC,"NUM_PED",,,"Selecionando registros...")
Return

//Funcao: Monta o Arquivo HTML para Exportar para o Excel
Static Function sfExpExcel(mvAlias,mvHeader,mvTitulo)
	// caminho temporario
	Local _cDirDocs	:= MsDocPath() 
	Local _cPath	:= AllTrim(GetTempPath())
	Local _cArquivo	:= CriaTrab(,.F.)
	Local _nHandle
	Local _cBuffer
	Local _cTmpCampo
	Local _aAreaAtu

	// verifica se o excel esta instalado
	If (!ApOleClient("MsExcel"))
		MsgStop("Microsoft Excel nao instalado.")
		Return
	EndIf
	
	// define a extensao do arquivo
	_cArquivo += ".xls"
	
	// inicia a escrita do arquivo
	_nHandle := FCreate(_cDirDocs+"\"+_cArquivo)
	// verifica se foi possivel criar o arquivo
	If (_nHandle == -1)
		MsgStop("Erro na criacao do arquivo na estacao local. Contate o administrador do sistema")
		Return(.f.)
	EndIf

	// inicia o html e cria a tabela Principal do html
	_cBuffer := "<html><body>"
	_cBuffer += "<table width='100%' border='1' cellpadding='1' cellspacing='1' bordercolor='#000000'>"
	FWrite(_nHandle,_cBuffer)

	// insere Linha com o Titulo da Planilha
	_cBuffer := "  <tr>"
    _cBuffer += "    <td colspan='"+AllTrim(Str(Len(mvHeader)))+"'>"+mvTitulo+"</td>"
	_cBuffer += "  </tr>"
	FWrite(_nHandle,_cBuffer)

	// linha em branco
	_cBuffer := "  <tr>"
    _cBuffer += "    <td colspan='"+AllTrim(Str(Len(mvHeader)))+"'>&nbsp;</td>"
	_cBuffer += "  </tr>"
	FWrite(_nHandle,_cBuffer)

	//Inicio Linha com Os Titulos das Colunas
	_cBuffer := "  <tr>"
	For nTit := 1 to Len(mvHeader)
	    _cBuffer += "    <td>"+mvHeader[nTit,3]+"</td>"
	Next nTit
	_cBuffer += "  </tr>"
	FWrite(_nHandle,_cBuffer)
	//Fim Linha com Os Titulos das Colunas

	// varre todos os campos da tabela
	dbSelectArea(mvAlias)
	// armazena a area atual
	_aAreaAtu := GetArea()
	// primeiro registro
	dbGoTop()
	
	While (!Eof())
		
		//Insere a Linha
		_cBuffer := "  <tr>"
		For nTit := 1 to Len(mvHeader)
		    
		    //Busca o Nome do Campo a ser Inserido
		    _cTmpCampo := mvHeader[nTit,1]
		    
		    If ValType((mvAlias)->&_cTmpCampo) == "D"
		    	_cBuffer += "<td>"+DtoC((mvAlias)->&_cTmpCampo)+"</td>"
		    ElseIf ValType((mvAlias)->&_cTmpCampo) == "N"
		    	_cBuffer += "<td align='right'>"+Transform((mvAlias)->&_cTmpCampo,"@E 99,999,999.99")+"</td>"
		    Else
		    	_cBuffer += "<td>"+(mvAlias)->&_cTmpCampo+"</td>"
		    EndIf

		Next nTit
		_cBuffer += "  </tr>"
		// grava a linha
		FWrite(_nHandle,_cBuffer)

		(mvAlias)->(dbSkip())
	EndDo

	//Finaliza o Html
	_cBuffer := "</table>"
	_cBuffer += "</body>"
	_cBuffer += "</html>"
	FWrite(_nHandle,_cBuffer)
	
	// fecha o arquivo
	FClose(_nHandle)

	// restaura area atual
	RestArea(_aAreaAtu)

	// copia o arquivo do servidor para o remote
	CpyS2T(_cDirDocs+"\"+_cArquivo,_cPath,.T.)

	// executa a abertura do arquivo
	oExcelApp := MsExcel():New()
	oExcelApp:WorkBooks:Open(_cPath+_cArquivo)
	oExcelApp:SetVisible(.T.)
	oExcelApp:Destroy()
	
Return(.t.)

//** funcao para criar o grupo de perguntas
Static Function sfCriaSX1(mvPerg,vList,lDel)
	Local aArea := GetArea()
	Local cSeq := "1"
	Local _Lin := 0
	Local nAdic := 0
	Local nTamOrd := Len(SX1->X1_ORDEM)
	Local cOrdPerg := ""
	Local cCpoTmp := ""
	
	// abre arquivo de perguntas
	DBSelectArea("SX1")
	SX1->( DBSetOrder(1) )

	// padroniza tamanho do cPerg
	mvPerg := PadR(mvPerg,Len(SX1->X1_GRUPO))

	//verifica se deve recriar as perguntas
	If lDel
		SX1->( DBSeek(mvPerg) )
		//Apaga todo o grupo de Perguntas
		While SX1->( !Eof() ) .and. SX1->X1_GRUPO == mvPerg
			RecLock("SX1",.F.)
				SX1->( DbDelete() )
			MsUnLock("SX1")
			SX1->(DbSkip())
		EndDo
	EndIf
	
	// verifica se todas os parametros existem
	For _Lin := 1 to Len(vList)
		// cria a variavel Ordem
		cOrdPerg := StrZero(_Lin,nTamOrd)

		// pesquisa pelo parametro
		SX1->( DBSeek(mvPerg+cOrdPerg) )
		
		// operacao (alteracao ou inclusao)
		RecLock("SX1",SX1->(Eof()))
			SX1->X1_GRUPO	:= mvPerg
			SX1->X1_ORDEM	:= cOrdPerg
			SX1->X1_PERGUNT	:= vList[_Lin,1]
			SX1->X1_PERSPA	:= vList[_Lin,1]
			SX1->X1_PERENG	:= vList[_Lin,1]
			SX1->X1_VARIAVL	:= "mv_ch" + cSeq
			SX1->X1_TIPO	:= vList[_Lin,2]
			SX1->X1_TAMANHO	:= vList[_Lin,3]
			SX1->X1_DECIMAL	:= vList[_Lin,4]
			SX1->X1_GSC		:= vList[_Lin,5]
			//Lista de Opções
			If vList[_Lin,5] = "C"
				For _LisOpc := 1 to Len(vList[_Lin,6])
					cCpoTmp := "X1_DEF" + StrZero(_LisOpc,2)
					SX1->&cCpoTmp := vList[_Lin,6,_LisOpc]
				Next _LisOpc
			Else
				SX1->X1_F3 := vList[_Lin,7]
			EndIf
			SX1->X1_VAR01 := "mv_par" + StrZero(_Lin,2)
			
			// verifica se tem informacoes de campos adicionais
			If (Len(vList[_Lin])==8).and.(ValType(vList[_Lin,8])=="A")
				// grava informacoes adicionais
				For nAdic := 1 to Len(vList[_Lin,8])
					// grava campo
					SX1->&(vList[_Lin,8][nAdic,1]) := vList[_Lin,8][nAdic,2]
				Next nAdic
			EndIf
			
		SX1->(MsUnlock())

		//Atualiza Seq
		cSeq := Soma1(cSeq)
	Next _Lin

	// restaura area inicial
	RestArea(aArea)

Return

//** funcao que implementa controle de saldo inicial e saldo acumulado
Static Function sfSldFinal(mvRefresh)
	// variaveis temporarias
	Local _nData
	// nome da coluna
	Local _cTmpCol := _vDatas[1,1]
	// valor acumulado
	Local _nValor := (_nSldBanco + _nSldCaixa) - (_nAtrPagar - _nAtrReceb)
	// area inicial
	Local _aAreaTRB := _TRBFLX->(GetArea())
    
	// registro do saldo inicial
	dbSelectArea("_TRBFLX")
	If (!_TRBFLX->(dbSeek("000"+"9"+"000000")))
		RecLock("_TRBFLX",.T.)
			_TRBFLX->FLX_GRUPO	:= "000"
			_TRBFLX->FLX_TIPO	:= "9" // 9-Total
			_TRBFLX->FLX_CODIGO	:= "000000"
			_TRBFLX->FLX_DESCRI	:= "SALDO INICIAL"
			_TRBFLX->FLX_TOTALI	:= "T"
		MsUnLock()
	EndIf

	// registro do saldo acululado	
	If (!_TRBFLX->(dbSeek("999"+"9"+"999999")))
		RecLock("_TRBFLX",.T.)
			_TRBFLX->FLX_GRUPO	:= "999"
			_TRBFLX->FLX_TIPO	:= "9" // 9-Total
			_TRBFLX->FLX_CODIGO	:= "999999"
			_TRBFLX->FLX_DESCRI	:= "SALDO ACUMULADO"
			_TRBFLX->FLX_TOTALI	:= "T"
		MsUnLock()
	EndIf

	// atualiza todos os valores
	For _nData := 1 to Len(_vDatas)

		// define o nome da coluna
		_cTmpCol := _vDatas[_nData,1]

		// atualiza o saldo inicial do periodo
		dbSelectArea("_TRBFLX")
		_TRBFLX->(dbSeek("000"+"9"+"000000"))
		RecLock("_TRBFLX")
			_TRBFLX->&_cTmpCol := _nValor
		MsUnLock()

		// atualiza saldo final do periodo
		dbSelectArea("_TRBFLX")
		_TRBFLX->(dbSeek("999"+"9"+"000000"))
		RecLock("_TRBFLX")
			_nValor += _TRBFLX->&_cTmpCol
		MsUnLock()

		// atualiza saldo acumulado do periodo
		dbSelectArea("_TRBFLX")
		_TRBFLX->(dbSeek("999"+"9"+"999999"))
		RecLock("_TRBFLX")
			_TRBFLX->&_cTmpCol := _nValor
		MsUnLock()

	Next _nData

	// restaura area inicial
	RestArea(_aAreaTRB)
	
	If (mvRefresh)
		_oBrwFluxo:oBrowse:Refresh()
		_oDlgFluxo:Refresh()
	EndIf

Return(.t.)

//** funcao que retorna o saldo de titulos vencidos
Static Function sfRetVencido(mvAlias)
	// valor do retorno
	Local _nRet		:= 0
	Local _cCampo	:= Right(mvAlias,2)
	Local _cQuery	:= ""

	_cQuery := "SELECT SUM("
	_cQuery += "           "+_cCampo+"_SALDO + "
	_cQuery += "           ("+_cCampo+"_SDACRES - "
	_cQuery += "            "+_cCampo+"_SDDECRE) "
	_cQuery += "           ) VLR_ATRASO "	
	_cQuery += "FROM "+RetSqlName(mvAlias)+" "+mvAlias+" "
	_cQuery += "WHERE "
	_cQuery += _cCampo+"_FILIAL = '"+xFilial(mvAlias)+"' AND "
	_cQuery += _cCampo+"_VENCREA <= '"+DtoS(_dDtIni-1)+"' AND "
	_cQuery += _cCampo+"_SALDO > 0 AND "
	_cQuery += _cCampo+"_FLUXO <> 'N' AND "
	_cQuery += _cCampo+"_TIPO NOT IN "+FormatIn(MVRECANT+MVPAGANT,,3)+" AND "
	If (mvAlias=="SE1")
		_cQuery += _cCampo+"_SITUACA NOT IN ('2','7') AND "
	Endif
	_cQuery += mvAlias + ".D_E_L_E_T_=' ' "

	If (Select("_QRYATR")<>0)
		dbSelectArea("_QRYATR")
		dbCloseArea()
	EndIf
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),"_QRYATR",.T.,.T.)
	// retorno
	_nRet := _QRYATR->VLR_ATRASO

	dbSelectArea("_QRYATR")
	dbCloseArea()

Return(_nRet)

//** funcao que marca todos os itens quando clicar no header da coluna
Static Function sfMarkAll(mvMarca, mvDlg)
	// area atual
	Local _aAreaAtu := _TRBDATA->(GetArea())
	
	dbSelectArea("_TRBDATA")
	_TRBDATA->(dbGoTop())
	// atualiza o campo Ok
	DbEval ({|| (RecLock ("_TRBDATA", .F.), _TRBDATA->DT_OK := If(Empty(_TRBDATA->DT_OK),mvMarca,Space(2)), MsUnLock ())})
	// restaura area atual
	RestArea(_aAreaAtu)
	// refresh na tela
	mvDlg:Refresh ()
Return(.t.)

//** funcao que cria o arquivo de trabalho
Static Function sfArqTrbSim
	// vetor com a estrutura do arquivo de trabalho
	Local _vEstSim := {}
	// define os campos do arquivo de trabalho
	aAdd(_vEstSim,{"SM_TOPICO"	,"C", TamSx3(If(_nVisao==1,"ED_CODIGO","CTT_CUSTO"))[1], 0 } )
	aAdd(_vEstSim,{"SM_DESCRI"	,"C", 50, 0 } )
	aAdd(_vEstSim,{"SM_VENCTO"	,"D", 08, 0 } )
	aAdd(_vEstSim,{"SM_VALOR"	,"N", 14, 2 } )

	If (Select("_TRBSIM") <>0)
		dbSelectArea("_TRBSIM")
		dbCloseArea()
	EndIf
	// cria o arquivo de trabalho
	_cArqTrb := CriaTrab(_vEstSim,.t.)
	dbUseArea ( .T.,,_cArqTrb,"_TRBSIM",NIL,.F.)
Return

//** funcao que prepara as informacoes dos pedidos de vendas
Static Function sfPedVenda()
	Local _cQuery
	Local _cQryGroup
	Local _nPrc
	Local _nData
	Local _cTmpCampo
	// quantidade de registro da query
	Local _nQtdReg	:= 0
	// parcelas de vencimentos
	Local _aParcela	:= {}
	Local _dDtPgto	:= CtoD("//")
	Local _nVlrParc	:= 0	

	// inclui uma linha com o titulo do pedido de venda
	dbSelectArea("_TRBFLX")
	RecLock("_TRBFLX",.T.)
		_TRBFLX->FLX_GRUPO	:= "004"
		_TRBFLX->FLX_TIPO	:= "0"
		_TRBFLX->FLX_DESCRI	:= "..PEDIDOS DE VENDA"
	MsUnLock()

	_cQuery := "SELECT "
	// visao por natureza
	If (_nVisao==1)
		_cQuery    += "C5_NATUREZ IT_TOPICO, "
		_cQryGroup := "C5_NATUREZ, "
	// visao por Centro de Custo
	ElseIf (_nVisao==2)
		_cQuery    += "CASE WHEN (SUBSTRING(C5_ZCC,1,5)='01004')OR(C5_ZCC IN ('0100204','0100208')) THEN '01004' ELSE C5_ZCC END IT_TOPICO, "
		_cQryGroup := "CASE WHEN (SUBSTRING(C5_ZCC,1,5)='01004')OR(C5_ZCC IN ('0100204','0100208')) THEN '01004' ELSE C5_ZCC END, "
	EndIf
	_cQuery    += "C9_PEDIDO, C9_CLIENTE, C9_LOJA, C6_ENTREG, C5_CONDPAG, SUM(C9_QTDLIB * C9_PRCVEN) C6_VALOR "
	_cQryGroup += "C9_PEDIDO, C9_CLIENTE, C9_LOJA, C6_ENTREG, C5_CONDPAG "

	// itens liberados do pedido
	_cQuery += "FROM "+RetSqlName("SC9")+" SC9 "
	// cabecalho do pedido
	_cQuery += "INNER JOIN "+RetSqlName("SC5")+" SC5 ON C5_FILIAL = '"+xFilial("SC5")+"' AND C5_NUM = C9_PEDIDO AND SC5.D_E_L_E_T_ = ' ' "
	// itens do pedido
	_cQuery += "INNER JOIN "+RetSqlName("SC6")+" SC6 ON C6_FILIAL = '"+xFilial("SC6")+"' AND C6_NUM = C9_PEDIDO AND SC6.D_E_L_E_T_ = ' ' "
	// verifica se TES se gera financeiro
	_cQuery += "INNER JOIN "+RetSqlName("SF4")+" SF4 ON F4_FILIAL = '"+xFilial("SF4")+"' AND F4_CODIGO = C5_CONDPAG AND SF4.D_E_L_E_T_ = ' ' "
	_cQuery += "AND F4_DUPLIC = 'S'
	// filtro de pedidos liberados sem nota gerada
	_cQuery += "WHERE C9_FILIAL = '"+xFilial("SC9")+"' AND SC9.D_E_L_E_T_ = ' ' "
	_cQuery += "AND C9_NFISCAL = ' ' "
	// agrupa os dados
	_cQuery += "GROUP BY "+_cQryGroup

	// padroniza a query
	_cQuery := ChangeQuery(_cQuery)
	
	MemoWrit("c:\query\ped_venda.txt",_cQuery)

	If (Select("_QRYSC9")<>0)
		dbSelectArea("_QRYSC9")
		dbCloseArea()
	EndIf

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),"_QRYSC9",.T.,.T.)
	TcSetField("_QRYSC9","C6_ENTREG","D")
	// armazena a quantidade de registro da query
	Count to _nQtdReg

	DBSelectArea("_QRYSC9")
	_QRYSC9->(dbGoTop())

	// seta tamanho da regua de processamento
	oProc:SetRegua2(_nQtdReg)

	While _QRYSC9->(!Eof())

		// controle da regua de processamento
		oProc:IncRegua2()

		// conforme a data prevista de entrega, utiliza a condicao de pagamento para gerar as parcelas
		_aParcela := Condicao(_QRYSC9->C6_VALOR, _QRYSC9->C5_CONDPAG,, _QRYSC9->C6_ENTREG)
		
		For _nPrc := 1 to Len(_aParcela)
			// data Vencimento
			_dDtPgto  := _aParcela[_nPrc,1]
			// valor da parcela
			_nVlrParc := _aParcela[_nPrc,2] 
            
			If (_dDtPgto>=_dDtIni).and.(_dDtPgto<=_dDtFim)
				For _nData := 1 to Len(_vDatas)
					If (_dDtPgto >= _vDatas[_nData,2]).and.(_dDtPgto <= _vDatas[_nData,3])
						_cTmpCampo := _vDatas[_nData,1]
						Exit
					EndIf
				Next _nData
				
				// adiciona informações no Fluxo
				sfAddFluxo(_QRYSC9->IT_TOPICO, "004", _cTmpCampo, _nVlrParc, .f.)
				
				// alimenta Vetor com os Dados Detalhados dos Pedidos venda
				aAdd(_vDtPedVen, {	_QRYSC9->IT_TOPICO ,;
									_QRYSC9->C9_PEDIDO ,;
									Posicione("SA1",1, xFilial("SA1")+_QRYSC9->(C9_CLIENTE+C9_LOJA) ,"A1_NREDUZ") ,;
									_dDtPgto ,;
									_nVlrParc })

			EndIf
		Next _nPrc
		// proximo item
		_QRYSC9->(dbSkip())
	EndDo
Return

//** funcao que monta a Tela com os Detalhes dos Pedidos de Vendas
Static Function sfDtPedVen(mvTopExt)
	Local _cQryVencto := ""
	Local _vBrwPedVen := {}
	Private _nPV

	// alimenta vetor com os campos para o Browse
	aAdd(_vBrwPedVen,{"C9_PEDIDO"	,,"Num Pedido"})
	aAdd(_vBrwPedVen,{"A1_NREDUZ"	,,"Cliente"})
	aAdd(_vBrwPedVen,{"C6_ENTREG"	,,"Vencimento"})
	aAdd(_vBrwPedVen,{"C6_VALOR"	,,"Vlr Parcela", PesqPict("SC6","C6_VALOR")})

	// chama tela para selecionar os periodos (datas)
	If (!sfSelData("DtoS(_vDtPedVen[_nPV,4])",@_cQryVencto))
		Return(.f.)
	EndIf
	
	// para filtro em arquivo em arquivo DBF, substituir:
	// IN por =
	_cQryVencto := StrTran(_cQryVencto," IN "," $ ")
	// OR  por .OR.
	_cQryVencto := StrTran(_cQryVencto," OR "," .OR. ")
	// AND por .AND.
	_cQryVencto := StrTran(_cQryVencto," AND "," .AND. ")

	// monta Arquivo de Trabalho para o pedido de venda
	sfArqTrbPV(_vBrwPedVen)
	
	For _nPV := 1 to Len(_vDtPedVen)
		// verifica o codigo do tipo
		If (AllTrim(_vDtPedVen[_nPV,1])==AllTrim(mvTopExt)).AND.(&_cQryVencto)
			DBSelectArea("_TRBSC9")
			RecLock("_TRBSC9",.T.)
				_TRBSC9->C9_PEDIDO	:= _vDtPedVen[_nPV][2]
				_TRBSC9->A1_NREDUZ	:= _vDtPedVen[_nPV][3]
				_TRBSC9->C6_ENTREG	:= _vDtPedVen[_nPV][4]
				_TRBSC9->C6_VALOR	:= _vDtPedVen[_nPV][5]
			_TRBSC9->( MsUnLock() )
		EndIf
	Next _nPV
	
	DBSelectArea("_TRBSC9")
	_TRBSC9->(dbGoTop())

	If _TRBSC9->(RecCount()) == 0
		Aviso("Detalhes...","Este tópico não contém informações analíticas.",{"OK"})
		Return
	EndIf

	// monta a tela com os detalhes
	_oDlgDtPedVen := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Detalhes dos Pedidos de Venda...",,,.F.,,,,,,.T.,,,.T. )
	_oDlgDtPedVen:lMaximized := .T.
	
	// cria o panel do cabecalho
	_oPnlCabPV := TPanel():New(000,000,nil,_oDlgDtPedVen,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlCabPV:Align:= CONTROL_ALIGN_TOP

	// botao para fechar
	_oBtnOk   := TButton():New(005,005,"Fechar",_oPnlCabPV,{|| _oDlgDtPedVen:End() },050,010,,,,.T.,,"",,,,.F. )
	// botao para exportar para o excel
	_oBtnSair := TButton():New(005,060,"Exp. Excel",_oPnlCabPV,{|| MsgRun("Favor Aguardar.....", "Exportando os Registros para o Excel",{|| sfExpExcel("_TRBSC9",_vBrwPedVen,"PEDIDOS DE VENDA") }) },050,010,,,,.T.,,"",,,,.F. )
	// botao para visualizar o titulo
	_oBtnVisualizar := TButton():New(005,115,"Visualizar",_oPnlCabPV,{|| sfVisPedVen() },050,010,,,,.T.,,"",,,,.F. )

	// browse
	_oBrwDtPedVen := MsSelect():New("_TRBSC9",,,_vBrwPedVen,,,{15,1,183,373})
	_oBrwDtPedVen:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	ACTIVATE MSDIALOG _oDlgDtPedVen CENTERED

Return

//** funcao que monta arquivo de Trabalho para os Dados dos Pedidos de Vendas
Static Function sfArqTrbPV(mvCampos)
	Local _aEstrPV := {}
	Local _nCmp
	Local _aAreaSX3 := SX3->(GetArea())
	
	For _nCmp := 1 to Len(mvCampos)
		dbSelectArea("SX3")
		SX3->(dbSetOrder(2)) //2-X3_CAMPO
		If SX3->(dbSeek( mvCampos[_nCmp][1] ))
			// alimenta vetor
			aAdd(_aEstrPV,{	SX3->X3_CAMPO,;
							SX3->X3_TIPO,;
							SX3->X3_TAMANHO,;
							SX3->X3_DECIMAL } )
		EndIf
	Next _nCmp
	// restaura area inicial
	RestArea(_aAreaSX3)

	If (Select("_TRBSC9")<>0)
		dbSelectArea("_TRBSC9")
		dbCloseArea()
	EndIf
	// cria o arquivo
	_cTrbDetPV := CriaTrab(_aEstrPV,.t.)
	dbUseArea(.T.,,_cTrbDetPV,"_TRBSC9",NIL,.F. )

Return

//** funcao para Visualizar Pedidos de Vendas
Static Function sfVisPedVen()
	Private aRotina	:= {{ "Pesquisar"	, "AxPesqui" , 0 , 1},;
						{ "Visualizar"	, "AxVisual" , 0 , 2}}

	DBSelectArea("SC5")
	SC5->(dbSetOrder(1)) //1-C5_FILIAL, C5_NUM
	SC5->(DBSeek( xFilial("SC5")+_TRBSC9->C9_PEDIDO ))
	// funcao padrao de visualizacao de pedido
	a410Visual("SC5",SC5->(RecNo()),2)

Return

//** funcao que retorna o saldo bancario/caixa
Static Function sfSldConta()
	Local _cQuery
	// codigo de banco caixa
	Local _cBcoCaixa := GetMV("MV_CARTEIR")
	// area atual
	Local _aAreaAtu := GetArea()
	
	// monta a query para buscar os saldos em banco/caixa
	_cQuery := "SELECT A6_COD, A6_AGENCIA, A6_NUMCON "
	// cadastro de bancos/caixas
	_cQuery += "FROM "+RetSqlName("SA6")+" SA6 "
	// somente contas disponives pro fluxo de caixa
	_cQuery += "WHERE A6_FILIAL = '"+xFilial("SA6")+"' AND SA6.D_E_L_E_T_ = ' ' "
	_cQuery += "AND A6_FLUXCAI <> 'N' "
	
	If (Select("_QRYSA6")<>0)
		dbSelectArea("_QRYSA6")
		dbCloseArea()
	EndIf
	// excuta a query
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),"_QRYSA6",.T.,.T.)
	dbSelectArea("_QRYSA6")

	While _QRYSA6->(!Eof())
		// busca o saldo por conta
//		_cQuery := "SELECT TOP 1 E8_SALATUA " alterado por Gabriel Mastrascusa, para POSTGRE
			_cQuery := "SELECT E8_SALATUA "  
		_cQuery += "FROM "+RetSqlName("SE8")+" SE8 "
		_cQuery += "WHERE E8_FILIAL = '"+xFilial("SE8")+"' AND SE8.D_E_L_E_T_ = ' ' "
		_cQuery += "AND E8_BANCO = '"+_QRYSA6->A6_COD+"' AND E8_AGENCIA = '"+_QRYSA6->A6_AGENCIA+"' AND E8_CONTA = '"+_QRYSA6->A6_NUMCON+"' "
		_cQuery += "AND E8_DTSALAT < '"+DtoS(_dDtIni)+"' "
		_cQuery += "ORDER BY E8_DTSALAT DESC "
		//_cQuery += ") WHERE ROWNUM = 1 "

		If (Select("_QRYSE8")<>0)
			dbSelectArea("_QRYSE8")
			dbCloseArea()
		EndIf
		// excuta a query
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),"_QRYSE8",.T.,.T.)
		dbSelectArea("_QRYSE8")

		// se for caixa
		If (Left(_QRYSA6->A6_COD,2)=="CX").or.(Left(_QRYSA6->A6_COD,3) $ _cBcoCaixa)
			_nSldCaixa += _QRYSE8->E8_SALATUA
		// saldo de conta bancaria
		Else
			_nSldBanco += _QRYSE8->E8_SALATUA
		EndIf
		// fecha alias
		dbSelectArea("_QRYSE8")
		dbCloseArea()

		// proximo banco
		dbSelectArea("_QRYSA6")
		_QRYSA6->(dbSkip())
	EndDo

	// fecha o alias
	dbSelectArea("_QRYSA6")
	dbCloseArea()
	
	// restaura area atual
	RestArea(_aAreaAtu)

Return(.t.)