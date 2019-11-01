#Include "Totvs.ch"
#Include "Protheus.ch"
#Include "TopConn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para Geração de OS de serviço de valor agregado  !
!                  ! - Chamada a partir da rotina TACDA002                   !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schumann            ! Data de Criacao ! 08/2019 !
+------------------+--------------------------------------------------------*/

User Function TWMSA052(mvQryUsr)
	Local _lRet			:= .F.
	Local _lFixaWnd		:= .F.
	Local _oPnInMvCb
	Local _oPnInMvCen
	Local _oBmpNew
	Local _oBmpOK
	Local _oBmpSair
	Local _cArquivo
	Private _oGetNumOS
	Private _oWndInicMov
	Private _oBrwAti
	Private _oSayCli
	Private _cCliente	:= ""
	Private _cCodCli	:= ""
	Private _cLojaCli	:= ""
	Private ATI			:= GetNextAlias()
	Private _NumOS		:= Space(TamSx3("Z6_NUMOS")[1])
	Private _aBrowse	:= {}
	Private _aStruTrb	:= {}
	Private _cMarca		:= GetMark()
	Private _oFonte30	:= TFont():New("Verdana",,30,,.T.)
	Private _oFonte15	:= TFont():New("Verdana",,15,,.F.)
	Private _oFonte17	:= TFont():New("Verdana",,17,,.T.)

	// estrutura da tabela temporária
	aadd(_aStruTrb,{"ATI_OK","C",2,0})
	aadd(_aStruTrb,{"ATI_COD","C",3,0})
	aadd(_aStruTrb,{"ATI_DESC","C",50,0})
	aadd(_aStruTrb,{"ATI_UNCOB","C",3,0})

	aadd(_aBrowse,{"ATI_OK",,"",""})
	aadd(_aBrowse,{"ATI_COD",,"Atividade",""})
	aadd(_aBrowse,{"ATI_DESC",,"Descrição",""})
	aadd(_aBrowse,{"ATI_UNCOB",,"UN Cob.",""})

	// monta o dialogo do monitor
	_oWndInicMov := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"OS de Serviço Valor Agregado",,,.F.,,,,,,.T.,,,.T. )
	_oWndInicMov:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnInMvCb := TPanel():New(000,000,nil,_oWndInicMov,,.F.,.F.,,CLR_HGRAY,20,20,.T.,.F.)
	_oPnInMvCb:Align:= CONTROL_ALIGN_TOP

	// botao para encerrar a montagem (se tudo já foi concluído)
	_oBmpOK := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| IIF(!EMPTY(_NumOS),sfConfOS(),U_FtWmsMsg("Necessário informar uma OS válida!","ATENCAO")) },_oPnInMvCb,"Confirmar",,.T.)
	_oBmpOK:Align := CONTROL_ALIGN_LEFT

	// botao para encerrar a montagem (se tudo já foi concluído)
	_oBmpNew := TBtnBmp2():New(000,000,060,022,"SDUSETDEL",,,,{|| sfEtapa1(), sfExDados(.F.) },_oPnInMvCb,"Criar OS",,.T.)
	_oBmpNew:Align := CONTROL_ALIGN_LEFT

	// -- SAIR
	_oBmpSair := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| IIf(U_FtYesNoMsg("Deseja Sair?", "ATENÇÃO"),(_lFixaWnd := .T. ,_oWndInicMov:End()),Nil) },_oPnInMvCb,"Sair",,.T.)
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// cria o panel para os campos
	_oPnInMvCen := TPanel():New(000,000,nil,_oWndInicMov,,.F.,.F.,,,110,110,.T.,.F.)
	_oPnInMvCen:Align:= CONTROL_ALIGN_TOP

	// Numero da OS de cobrança
	_oGetNumOS := TGet():New(001,001,{|u| If(PCount()>0,_NumOS:=u,_NumOS)},_oPnInMvCen,045,009,"@!",;
	{|| (Vazio()) .Or. (sfVldOS(_NumOS)) },,,_oFnt03,;
	,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_NumOS",,,,,, .T. ,"Número da OS de Faturamento", 1)

	// campo informando o nome do cliente
	_oSayCli	:= TSay():New(021,001,{||"Cliente: "+_cCliente},_oPnInMvCen,,_oFnt02,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)

	If (Select(ATI)<>0)
		dbSelectArea(ATI)
		dbCloseArea()
	EndIf

	// cria tabela temporária com os itens do contrato
	_cArquivo := FWTemporaryTable():New( ATI )
	_cArquivo:SetFields( _aStruTrb )
	_cArquivo:Create()

	// grid para seleção de atividade
	_oBrwAti := MsSelect():New (ATI,"ATI_OK",Nil, _aBrowse, .F., _cMarca, {052,001,160,120},,,_oWndInicMov)

	// foco no campo GetOS
	_oGetNumOS:SetFocus()

	// ativa a tela
	_oWndInicMov:Activate(,,,.F.,{|| _lFixaWnd },,)

	// excluir objeto ao sair
	If ValType(_cArquivo) == "O"
		_cArquivo:Delete()
	EndIf

Return(_lRet)
// efetua a validação da OS de faturamento e carrega os itens do contrato no Grid
//-------------------------------------------------------------------------------------------------
Static Function sfVldOS(_NumOS)
	Local _lRet		:= .T.
	Local _aDados	:= {}

	// valida a OS de cobrança
	dbSelectArea("SZ6")
	SZ6->(dbSetOrder(1))
	If SZ6->(dbSeek( xFilial("SZ6")+_NumOS ))

		dbSelectArea("SA1")
		dbSetOrder(1)
		dbSeek(xFilial("SA1")+SZ6->Z6_CLIENTE+SZ6->Z6_LOJA)

		_cCliente := SA1->A1_NOME
		_cCodCli  := SA1->A1_COD
		_cLojaCli := SA1->A1_LOJA

		_cQuery := " select distinct Z9_CODATIV,ZT_DESCRIC,Z9_UNIDCOB "
		_cQuery += " from "+RetSQLName("SZ6")+" SZ6 (NoLock) "

		_cQuery += "     inner join "+RetSQLName("SZ1")+" SZ1 (NoLock) "
		_cQuery += "     on SZ1.D_E_L_E_T_ = '' "
		_cQuery += "     and Z1_FILIAL = Z6_FILIAL "
		_cQuery += "     and Z1_CODIGO = Z6_CODIGO "

		_cQuery += "    inner join "+RetSQLName("AAM")+" AAM (NoLock) "
		_cQuery += "     on AAM.D_E_L_E_T_ = '' "
		_cQuery += "     and AAM_CODCLI = Z1_CLIENTE "
		_cQuery += "     and AAM_LOJA = Z1_LOJA "
		_cQuery += "     and AAM_CONTRT = Z1_CONTRT "

		_cQuery += "     inner join "+RetSQLName("SZ9")+" SZ9 (NoLock) "
		_cQuery += "     on SZ9.D_E_L_E_T_ = '' "
		_cQuery += "     and Z9_FILIAL = AAM_FILIAL "
		_cQuery += "     and Z9_CONTRAT = AAM_CONTRT "

		_cQuery += "     inner join "+RetSQLName("SZT")+" SZT (NoLock) "
		_cQuery += "     on SZT.D_E_L_E_T_ = '' "
		_cQuery += "     and ZT_FILIAL = Z9_FILIAL "
		_cQuery += "     and ZT_CODIGO = Z9_CODATIV "
		_cQuery += "     and ZT_MSBLQL <> '1' "

		_cQuery += " where SZ6.D_E_L_E_T_ = '' "
		_cQuery += " and Z6_FILIAL = '"+xFilial("SZ6")+"' "
		_cQuery += " and Z6_CLIENTE = '"+SA1->A1_COD+"' "
		_cQuery += " and Z6_LOJA = '"+SA1->A1_LOJA+"' "
		_cQuery += " and Z6_NUMOS = '"+_NumOS+"' "
		_cQuery += " order by Z9_CODATIV "

		_aDados := U_SqlToVet(_cQuery)

		memowrit("C:\query\twmsa052_sfVldOS.txt",_cQuery)

		(ATI)->(dbSelectArea(ATI))
		(ATI)->(__DbZap())

		For i:=1 To Len(_aDados)
			// inclui o registro no arquivo de trabalho
			(ATI)->(RecLock(ATI, .T.))
			(ATI)->ATI_OK	:= " "
			(ATI)->ATI_COD	:= AllTrim(_aDados[i][1])
			(ATI)->ATI_DESC	:= AllTrim(_aDados[i][2])
			(ATI)->ATI_UNCOB:= AllTrim(_aDados[i][3])
			(ATI)->(MsUnLock())
		Next i

		// após inserir os registros, da Refresh na tela para carregar os novos dados
		(ATI)->(dbGoTop())
		_oSayCli:Refresh()
		_oBrwAti:oBrowse:Refresh()
	Else
		// se não validou a OS, limpa os campos e tabela 
		(ATI)->(dbSelectArea(ATI))
		(ATI)->(__DbZap())
		_cCliente := ""
		_oSayCli:Refresh()
		_oBrwAti:oBrowse:Refresh()
		_lRet := .F.
	EndIf

Return(_lRet)
// tela para informar a quantidade de atividades realizadas no complemento de SVA
//-------------------------------------------------------------------------------------------------
Static Function sfConfOS()
	Local _lRet		:= .T.
	Local _oPnInMvCb
	Local _oPnInMvCen
	Local _oGetNVis
	Local _oBmpOK
	Local _oBmpSair
	Local _oSayCli
	Private _aDados	:= {}
	Private _oDlgConfM
	Private _oBrwConf

	// monta o dialogo do monitor
	_oDlgConfM := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"OS de Serviço Valor Agregado",,,.F.,,,,,,.T.,,,.T. )
	_oDlgConfM:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnInMvCb := TPanel():New(000,000,nil,_oDlgConfM,,.F.,.F.,,CLR_HGRAY,20,20,.T.,.F.)
	_oPnInMvCb:Align:= CONTROL_ALIGN_TOP

	// botao para incluir os itens e quantidade na OS de cobrança
	_oBmpOK := TBtnBmp2():New(000,000,060,022,"OK",,,,{|| IIf(U_FtYesNoMsg("Confirma a inclusão dos itens na OS de cobrança?", "ATENÇÃO"),(IIF(sfPrepOS(),sfExDados(.T.),Nil)),Nil) },_oPnInMvCb,"Confirmar",,.T.)
	_oBmpOK:Align := CONTROL_ALIGN_LEFT

	// -- SAIR
	_oBmpSair := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| IIf(U_FtYesNoMsg("Deseja Sair?", "ATENÇÃO"),(_oDlgConfM:End()),Nil) },_oPnInMvCb,"Sair",,.T.)
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// cria o panel para os campos
	_oPnInMvCen := TPanel():New(000,000,nil,_oDlgConfM,,.F.,.F.,,,110,110,.T.,.F.)
	_oPnInMvCen:Align:= CONTROL_ALIGN_TOP

	// Numero da OS de cobrança
	_oGetNVis := TGet():New(001,001,{|u| If(PCount()>0,_NumOS:=u,_NumOS)},_oPnInMvCen,045,009,"@!",;
	{|| (Vazio()) .Or. (sfVldOS(_NumOS)) },,,_oFnt03,;
	,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_NumOS",,,,,, .T. ,"Número da OS de Faturamento", 1)
	_oGetNVis:Disable()

	// nome do cliente
	_oSayCli	:= TSay():New(021,001,{||"Cliente: "+_cCliente},_oPnInMvCen,,_oFnt02,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)

	// carrega o array _aDados somente com os itens marcados
	(ATI)->(dbSelectArea(ATI))
	(ATI)->(dbGoTop())
	While !(ATI)->(EOF())
		If (ATI)->ATI_OK == _cMarca
			AADD(_aDados,{000.00,(ATI)->ATI_COD,(ATI)->ATI_DESC,(ATI)->ATI_UNCOB})
		EndIf
		(ATI)->(dbSkip())
	EndDo

	(ATI)->(dbGoTop())

	// monta o grid para informar a quantidade de atividades
	_oBrwConf := MsBrGetDBase():new(050,001,118,110,,,,_oDlgConfM,,,,{||},,{||},,,,,,.T.,'',.T.,{||},.T.,{||},,)

	_oBrwConf:SetArray(_aDados)
	_oBrwConf:AddColumn(TCColumn():new('Quant.'		,{|| _aDados[_oBrwConf:nAt,01]			}, '@E 999.99'	,,,"LEFT",,.F.,.T.,,,,,))
	_oBrwConf:AddColumn(TCColumn():new('Cod.'		,{|| AllTrim(_aDados[_oBrwConf:nAt,02]) }, '@!'			,,,"LEFT",,.F.,.F.,,,,,))
	_oBrwConf:AddColumn(TCColumn():new('Descricao'	,{|| AllTrim(_aDados[_oBrwConf:nAt,03]) }, '@!'			,,,"LEFT",,.F.,.F.,,,,,))
	_oBrwConf:AddColumn(TCColumn():new('UN Cob.'	,{|| AllTrim(_aDados[_oBrwConf:nAt,04]) }, '@!'			,,,"LEFT",,.F.,.F.,,,,,))
	_oBrwConf:bLDblClick := {|| sfEditBrw(@_aDados)}
	_oBrwConf:Refresh()

	// ativa a tela
	_oDlgConfM:Activate(,,,.F.,{||},,)


Return(_lRet)
// edita as células do browse
//-------------------------------------------------------------------------------------------------
Static Function sfEditBrw(aArr)

	lEditCell(@aArr, _oBrwConf, "@E 999.99", 1)

Return .T.
// valida se o usuário inseriu a quantidade de atividades e chama o cadastro de SVA
//-------------------------------------------------------------------------------------------------
Static Function sfPrepOS()
	Local _lRet := .T.
	Local _aTemp := {}

	For nX:=1 to Len(_aDados)
		If Empty(_aDados[nX][1])
			U_FtWmsMsg("Informe a quantidade de atividades realizadas em todos os itens!","ATENCAO")
			_lRet := .F.
		EndIf
	Next nX

	If _lRet
		// prepara o array _aTemp com a estrutura correta para chamar a função de cadastro
		For nX:=1 to Len(_aDados)
			// _aTemp = Cod. Atividade, UN Cob, Quantidade
			AADD(_aTemp,{_aDados[nX][2],_aDados[nX][4],_aDados[nX][1]})
		Next nX

		// cadastra novos itens de SVA
		_lRet := U_sfOSSVA(.F.,_NumOS,Nil,Nil,_cCodCli,_cLojaCli,_aTemp)
	EndIf

Return(_lRet)
// Etapa 1 DE 4 no cadastro de nova OS de SVA - Seleção de cliente
//-------------------------------------------------------------------------------------------------
Static Function sfEtapa1()
	Local _lRet			:= .T.
	Local _oPnInMvCb
	Local _oPnInMvCen
	Local _oBmpNext
	Local _oBmpSair
	Local _oSay
	Local _oSayCli
	Local _oSayNF
	Local _oSayEtapa
	Local _cArquivo
	Private _cNomeNF	:= ""
	Private _NFCli		:= ""
	Private _NFSer		:= ""
	Private _cNomeCli	:= Space(20)
	Private ACLI		:= GetNextAlias()
	Private _aClientes	:= {}
	Private _aBrwCli	:= {}
	Private _aStruCli	:= {}
	Private _oDlgCOS
	Private _oBrwCli

	// zera variáveis de clientes
	_cCodCli	:= ""
	_cLojaCli	:= ""

	// monta estrutura da tabela temporária
	aadd(_aStruCli,{"ACLI_OK","C",2,0})
	aadd(_aStruCli,{"ACLI_COD","C",9,0})
	aadd(_aStruCli,{"ACLI_NOME","C",20,0})

	aadd(_aBrwCli,{"ACLI_OK",,"",""})
	aadd(_aBrwCli,{"ACLI_COD",,"Cod/Loja",""})
	aadd(_aBrwCli,{"ACLI_NOME",,"Nome",""})

	// monta tela
	_oDlgCOS := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"OS de Serviço Valor Agregado",,,.F.,,,,,,.T.,,,.T. )
	_oDlgCOS:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnInMvCb := TPanel():New(000,000,nil,_oDlgCOS,,.F.,.F.,,CLR_HGRAY,20,20,.T.,.F.)
	_oPnInMvCb:Align:= CONTROL_ALIGN_TOP

	// botao Back Page
	_oBmpPev := TBtnBmp2():New(000,000,060,022,"PGPREV",,,,{||  },_oPnInMvCb,"Etapa Anterior",,.T.)
	_oBmpPev:Align := CONTROL_ALIGN_LEFT
	_oBmpPev:Disable()

	// botao Next Page
	_oBmpNext := TBtnBmp2():New(000,000,060,022,"PGNEXT",,,,{|| IIF(sfVldEt1(),sfEtapa2(),Nil) },_oPnInMvCb,"Proxima Etapa",,.T.)
	_oBmpNext:Align := CONTROL_ALIGN_LEFT

	// informativo do número da etapa
	_oSayEtapa	:= TSay():New(002,058,{||"1 / 4"},_oPnInMvCb,,_oFonte30,.F.,.F.,.F.,.T.,CLR_WHITE,CLR_WHITE,200,20)

	// -- SAIR
	_oBmpSair := TBtnBmp2():New(000,000,060,022,"FINAL",,,,{|| IIf(U_FtYesNoMsg("Deseja Sair?", "ATENÇÃO"),(_oDlgCOS:End()),Nil) },_oPnInMvCb,"Sair",,.T.)
	_oBmpSair:Align := CONTROL_ALIGN_RIGHT

	// cria o panel para os campos
	_oPnInMvCen := TPanel():New(000,000,nil,_oDlgCOS,,.F.,.F.,,,110,110,.T.,.F.)
	_oPnInMvCen:Align:= CONTROL_ALIGN_TOP

	// campos de informações e instruções
	_oSay	:= TSay():New(001,002,{||"Selecione"},_oPnInMvCen,,_oFonte17,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oSay	:= TSay():New(008,002,{||"o Cliente"},_oPnInMvCen,,_oFonte17,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oGroup	:= TGroup():New(00,01,20,42,Nil,_oPnInMvCen,,,.T.)
	_oGroup	:= TGroup():New(00,42,20,120,Nil,_oPnInMvCen,,,.T.)
	_oSayCli:= TSay():New(001,45,{||"Cliente: "+AllTrim(_cNomeNF)},_oPnInMvCen,,_oFonte15,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oSayNF	:= TSay():New(009,45,{||"NF: "+AllTrim(_NFCli)},_oPnInMvCen,,_oFonte15,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)

	// seleciona os clientes desbloqueados, com contratos ativos e parametros WMS_ATIVO_POR_CLIENTE = .T.
	_cQuery := " SELECT A1_COD+'/'+A1_LOJA COD,A1_NREDUZ NOME "
	_cQuery += " FROM "+RetSQLName("SA1")+" SA1 (NoLock) "
	_cQuery += "     inner join "+RetSQLName("Z30")+" Z30 (NoLock) "
	_cQuery += "     on Z30.D_E_L_E_T_ = '' "
	_cQuery += "     and Z30_FILIAL = A1_FILIAL "
	_cQuery += "     and Z30_CODCLI = A1_COD "
	_cQuery += "     and Z30_LOJCLI = A1_LOJA "
	_cQuery += "     and Z30_PARAM = 'WMS_ATIVO_POR_CLIENTE' "
	_cQuery += "     and Z30_CONTEU = '.T.' "
	_cQuery += " where SA1.D_E_L_E_T_ = '' "
	_cQuery += " and A1_MSBLQL <> '1' "
	_cQuery += " and A1_COD+A1_LOJA in ( "
	_cQuery += "     select distinct AAM_CODCLI+AAM_LOJA "
	_cQuery += "     from "+RetSQLName("AAM")+" (NoLock) "
	_cQuery += "     where D_E_L_E_T_ = '' "
	_cQuery += "     and AAM_STATUS = '1') "
	_cQuery += " order by COD "

	_aClientes := U_SqlToVet(_cQuery)

	memowrit("C:\query\twmsa052_sfEtapa1.txt",_cQuery)

	// cria a tebala temporária de clientes
	If (Select(ACLI)<>0)
		dbSelectArea(ACLI)
		dbCloseArea()
	EndIf

	_cArquivo := FWTemporaryTable():New( ACLI )
	_cArquivo:SetFields( _aStruCli )
	_cArquivo:Create()

	For i:=1 To Len(_aClientes)
		// inclui o registro no arquivo de trabalho
		(ACLI)->(RecLock(ACLI, .T.))
		(ACLI)->ACLI_OK		:= " "
		(ACLI)->ACLI_COD	:= AllTrim(_aClientes[i][1])
		(ACLI)->ACLI_NOME	:= AllTrim(_aClientes[i][2])
		(ACLI)->(MsUnLock())
	Next i

	(ACLI)->(dbGoTop())

	// grid pra seleção do cliente
	_oBrwCli := MsSelect():New (ACLI,"ACLI_OK",Nil, _aBrwCli, .F., _cMarca, {037,001,161,120},,,_oDlgCOS)
	_oBrwCli:bMark := {|| sfVldCli(),_oSayCli:Refresh() }

	// ativa a tela
	_oDlgCOS:Activate(,,,.F.,{||},,)

	// excluir objeto ao sair
	If ValType(_cArquivo) == "O"
		_cArquivo:Delete()
	EndIf

Return(_lRet)
// validar e carregar as informações do cliente selecionado
//-------------------------------------------------------------------------------------------------
Static Function sfVldCli()
	Local _aVld := {}
	Local aArea := GetArea()

	// seleciona o cliente ticado
	(ACLI)->(dbSelectArea(ACLI))
	(ACLI)->(dbGoTop())
	While !(ACLI)->(EOF())
		If (ACLI)->ACLI_OK == _cMarca
			AADD(_aVld,{_cMarca})
		EndIf
		(ACLI)->(dbSkip())
	EndDo

	RestArea(aArea)

	// efetua validações sobre o número de clientes selecionados, e carrega se for válido
	If Len(_aVld) > 1
		U_FtWmsMsg("Favor marcar somente um cliente por OS!","ATENCAO")
		(ACLI)->(RecLock(ACLI, .F.))
		(ACLI)->ACLI_OK := ""
		(ACLI)->(MsUnLock())
	ElseIf Len(_aVld) == 1
		_cNomeNF	:= SubString((ACLI)->ACLI_NOME,1,10)
		_cCodCli	:= SubString((ACLI)->ACLI_COD,1,6)
		_cLojaCli	:= SubString((ACLI)->ACLI_COD,8,2)
	ElseIf Len(_aVld) == 0
		_cNomeNF	:= ""
		_cCodCli	:= ""
		_cLojaCli	:= ""
	EndIf

Return
// validar a seleção de cliente ao avançar para a etapa 2
//-------------------------------------------------------------------------------------------------
Static Function sfVldEt1()
	Local _lRet := .T.
	Local _aVld := {}
	Local aArea := GetArea()

	// seleciona o cliente ticado
	(ACLI)->(dbSelectArea(ACLI))
	(ACLI)->(dbGoTop())
	While !(ACLI)->(EOF())
		If (ACLI)->ACLI_OK == _cMarca
			AADD(_aVld,{_cMarca})
		EndIf
		(ACLI)->(dbSkip())
	EndDo

	RestArea(aArea)

	// força a validação de seleção para somente 1 cliente, e se selecionou ao menos 1 cliente
	If Len(_aVld) > 1
		U_FtWmsMsg("Favor marcar somente um cliente!","ATENCAO")
		_lRet := .F.
	ElseIf Len(_aVld) == 0
		U_FtWmsMsg("Favor marcar um cliente antes de continuar!","ATENCAO")
		_lRet := .F.
	EndIf

Return(_lRet)
// limpa campos e tabelas ao retornar ou fechar algumas telas
//-------------------------------------------------------------------------------------------------
Static Function sfExDados(_lType)

	_NumOS := Space(TamSx3("Z6_NUMOS")[1])
	(ATI)->(dbSelectArea(ATI))
	(ATI)->(__DbZap())
	_cCliente	:= ""
	_cCodCli	:= ""
	_cLojaCli	:= ""
	_aDados		:= {}
	If _lType
		_oDlgConfM:End()
	EndIf
	_oGetNumOS:SetFocus()

Return
// Etapa 2 DE 4 no cadastro de nova OS de SVA - Seleção de nota fiscal
//-------------------------------------------------------------------------------------------------
Static Function sfEtapa2()
	Local _lRet := .T.
	Local _oPnInMvCb
	Local _oPnInMvCen
	Local _oBmpNext
	Local _oSay
	Local _oSayEtapa
	Local _oSayCli
	Local _oSayNF
	Local _cArquivo
	Private _oDlgNF
	Private _oBrwNF
	Private ANF		:= GetNextAlias()
	Private _aNF	:= {}
	Private _aBrwNF	:= {}
	Private _aStruNF:= {}

	// monta estrutura de tabela temporária
	aadd(_aStruNF,{"ANF_OK","C",2,0})
	aadd(_aStruNF,{"ANF_DOC","C",9,0})
	aadd(_aStruNF,{"ANF_EMIS","C",20,0})
	aadd(_aStruNF,{"ANF_SER","C",2,0})

	aadd(_aBrwNF,{"ANF_OK",,"",""})
	aadd(_aBrwNF,{"ANF_DOC",,"Nota Fiscal",""})
	aadd(_aBrwNF,{"ANF_EMIS",,"Emissão",""})
	aadd(_aBrwNF,{"ANF_SER",,"Serie",""})

	// monta o dialogo do monitor
	_oDlgNF := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"OS de Serviço Valor Agregado",,,.F.,,,,,,.T.,,,.T. )
	_oDlgNF:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnInMvCb := TPanel():New(000,000,nil,_oDlgNF,,.F.,.F.,,CLR_HGRAY,20,20,.T.,.F.)
	_oPnInMvCb:Align:= CONTROL_ALIGN_TOP

	// botao Back Page
	_oBmpPev := TBtnBmp2():New(000,000,060,022,"PGPREV",,,,{|| ( (ACLI)->(dbSelectArea(ACLI)), (ACLI)->(dbGoTop()), _NFCli:= "", _NFSer:="",_oDlgNF:End()) },_oPnInMvCb,"Etapa Anterior",,.T.)
	_oBmpPev:Align := CONTROL_ALIGN_LEFT

	// botao Next Page
	_oBmpNext := TBtnBmp2():New(000,000,060,022,"PGNEXT",,,,{|| sfEtapa3() },_oPnInMvCb,"Proxima Etapa",,.T.)
	_oBmpNext:Align := CONTROL_ALIGN_LEFT

	// informativo do número da etapa
	_oSayEtapa	:= TSay():New(002,058,{||"2 / 4"},_oPnInMvCb,,_oFonte30,.F.,.F.,.F.,.T.,CLR_WHITE,CLR_WHITE,200,20)

	// cria o panel para os campos
	_oPnInMvCen := TPanel():New(000,000,nil,_oDlgNF,,.F.,.F.,,,110,110,.T.,.F.)
	_oPnInMvCen:Align:= CONTROL_ALIGN_TOP

	// campos de informações e instruções
	_oSay	:= TSay():New(001,002,{||"Selecione"},_oPnInMvCen,,_oFonte17,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oSay	:= TSay():New(008,002,{||"a NF"},_oPnInMvCen,,_oFonte17,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oGroup	:= TGroup():New(00,01,20,42,Nil,_oPnInMvCen,,,.T.)
	_oGroup	:= TGroup():New(00,42,20,120,Nil,_oPnInMvCen,,,.T.)
	_oSayCli:= TSay():New(001,45,{||"Cliente: "+AllTrim(_cNomeNF)},_oPnInMvCen,,_oFonte15,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oSayNF	:= TSay():New(009,45,{||"NF: "+AllTrim(_NFCli)},_oPnInMvCen,,_oFonte15,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)

	// seleciona as notas fiscais de entrada do cliente com saldo na SB6
	_cQuery := " SELECT distinct D1_DOC DOC,CONVERT(VARCHAR(10), CONVERT(DATE, D1_EMISSAO), 103) EMISSAO,D1_SERIE SERIE  "
	_cQuery += "  FROM "+RetSQLName("SD1")+" SD1 (NoLock)  "
	_cQuery += "     inner join "+RetSQLName("SB6")+" SB6 (NoLock) "
	_cQuery += "     on SB6.D_E_L_E_T_ = '' "
	_cQuery += "     and B6_FILIAL = D1_FILIAL "
	_cQuery += "     and B6_CLIFOR = D1_FORNECE "
	_cQuery += "     and B6_LOJA = D1_LOJA "
	_cQuery += "     and B6_DOC = D1_DOC "
	_cQuery += "     and B6_SERIE = D1_SERIE "
	_cQuery += "     and B6_PRODUTO = D1_COD "
	_cQuery += "     and B6_LOCAL = D1_LOCAL "
	_cQuery += "     and B6_SALDO > 0 "
	_cQuery += "  where SD1.D_E_L_E_T_ = ''  "
	_cQuery += "  and D1_FILIAL = '"+xFilial("SD1")+"' "
	_cQuery += "  AND D1_FORNECE = '"+_cCodCli+"' "
	_cQuery += "  AND D1_LOJA = '"+_cLojaCli+"' "
	_cQuery += " and D1_TIPO IN ('B','D')  "
	_cQuery += "  order by DOC "

	_aNF := U_SqlToVet(_cQuery)

	memowrit("C:\query\twmsa052_sfEtapa2.txt",_cQuery)

	// cria tabela temporária
	If (Select(ANF)<>0)
		dbSelectArea(ANF)
		dbCloseArea()
	EndIf

	_cArquivo := FWTemporaryTable():New( ANF )
	_cArquivo:SetFields( _aStruNF )
	_cArquivo:Create()

	For i:=1 To Len(_aNF)
		// inclui o registro no arquivo de trabalho
		(ANF)->(RecLock(ANF, .T.))
		(ANF)->ANF_OK	:= " "
		(ANF)->ANF_DOC	:= AllTrim(_aNF[i][1])
		(ANF)->ANF_EMIS	:= AllTrim(_aNF[i][2])
		(ANF)->ANF_SER	:= AllTrim(_aNF[i][3])
		(ACLI)->(MsUnLock())
	Next i

	(ANF)->(dbGoTop())

	// grid para selecionar a nota fiscal
	_oBrwNF := MsSelect():New (ANF,"ANF_OK",Nil, _aBrwNF, .F., _cMarca, {037,001,161,120},,,_oDlgNF)
	_oBrwNF:bMark := {|| sfVldNF(),_oSayNF:Refresh() }

	// ativa a tela
	_oDlgNF:Activate(,,,.F.,{||},,)

	// excluir objeto ao sair
	If ValType(_cArquivo) == "O"
		_cArquivo:Delete()
	EndIf

Return(_lRet)
// valida a seleção de nota fiscal
//-------------------------------------------------------------------------------------------------
Static Function sfVldNF()
	Local _aVld := {}
	Local aArea := GetArea()

	// seleciona a NF ticada
	(ANF)->(dbSelectArea(ANF))
	(ANF)->(dbGoTop())
	While !(ANF)->(EOF())
		If (ANF)->ANF_OK == _cMarca
			AADD(_aVld,{_cMarca})
		EndIf
		(ANF)->(dbSkip())
	EndDo

	RestArea(aArea)

	// valida se marcou somente uma nota e carrega informações
	If Len(_aVld) > 1
		U_FtWmsMsg("Favor marcar somente uma Nota Fiscal!","ATENCAO")
		(ANF)->(RecLock(ANF, .F.))
		(ANF)->ANF_OK := ""
		(ANF)->(MsUnLock())
	ElseIf Len(_aVld) == 1
		_NFCli	:= (ANF)->ANF_DOC
		_NFSer	:= (ANF)->ANF_SER
	ElseIf Len(_aVld) == 0
		_NFCli	:= ""
		_NFSer	:= ""
	EndIf

Return
// Etapa 3 DE 4 no cadastro de nova OS de SVA - Seleção de itens do contrato vinculado com a NF
//-------------------------------------------------------------------------------------------------
Static Function sfEtapa3()
	Local _lRet := .T.
	Local _oPnInMvCb
	Local _oPnInMvCen
	Local _oBmpNext
	Local _oSay
	Local _oSayEtapa
	Local _oSayCli
	Local _oSayNF
	Local _cArquivo
	Private _oDlgITM
	Private _oBrwITM
	Private AITM	:= GetNextAlias()
	Private _aITM	:= {}
	Private _aBrwITM:= {}
	Private _aStruITM:= {}

	// monta estrutura para a tabela temporária
	aadd(_aStruITM,{"AITM_OK","C",2,0})
	aadd(_aStruITM,{"AITM_ATIV","C",3,0})
	aadd(_aStruITM,{"AITM_DESC","C",25,0})
	aadd(_aStruITM,{"AITM_CONT","C",16,0})
	aadd(_aStruITM,{"AITM_UNCOB","C",3,0})

	aadd(_aBrwITM,{"AITM_OK",,"",""})
	aadd(_aBrwITM,{"AITM_ATIV",,"Ativ",""})
	aadd(_aBrwITM,{"AITM_DESC",,"Descrição",""})
	aadd(_aBrwITM,{"AITM_CONT",,"Contrato",""})
	aadd(_aBrwITM,{"AITM_UNCOB",,"UN Cob.",""})

	// monta o dialogo do monitor
	_oDlgITM := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"OS de Serviço Valor Agregado",,,.F.,,,,,,.T.,,,.T. )
	_oDlgITM:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnInMvCb := TPanel():New(000,000,nil,_oDlgITM,,.F.,.F.,,CLR_HGRAY,20,20,.T.,.F.)
	_oPnInMvCb:Align:= CONTROL_ALIGN_TOP

	// botao Back Page
	_oBmpPev := TBtnBmp2():New(000,000,060,022,"PGPREV",,,,{|| ((ACLI)->(dbSelectArea(ACLI)), (ACLI)->(dbGoTop()),_oDlgITM:End()) },_oPnInMvCb,"Etapa Anterior",,.T.)
	_oBmpPev:Align := CONTROL_ALIGN_LEFT

	// botao Next Page
	_oBmpNext := TBtnBmp2():New(000,000,060,022,"PGNEXT",,,,{|| IIF(sfVsfEt3(),sfEtapa4(),Nil) },_oPnInMvCb,"Proxima Etapa",,.T.)
	_oBmpNext:Align := CONTROL_ALIGN_LEFT

	// informativo do número da etapa
	_oSayEtapa	:= TSay():New(002,058,{||"3 / 4"},_oPnInMvCb,,_oFonte30,.F.,.F.,.F.,.T.,CLR_WHITE,CLR_WHITE,200,20)

	// cria o panel para os campos
	_oPnInMvCen := TPanel():New(000,000,nil,_oDlgITM,,.F.,.F.,,,110,110,.T.,.F.)
	_oPnInMvCen:Align:= CONTROL_ALIGN_TOP

	// campos de informações e instruções
	_oSay	:= TSay():New(001,002,{||"Selecione"},_oPnInMvCen,,_oFonte17,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oSay	:= TSay():New(008,002,{||"Serviços"},_oPnInMvCen,,_oFonte17,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oGroup	:= TGroup():New(00,01,20,42,Nil,_oPnInMvCen,,,.T.)
	_oGroup	:= TGroup():New(00,42,20,120,Nil,_oPnInMvCen,,,.T.)
	_oSayCli:= TSay():New(001,45,{||"Cliente: "+AllTrim(_cNomeNF)},_oPnInMvCen,,_oFonte15,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oSayNF	:= TSay():New(009,45,{||"NF: "+AllTrim(_NFCli)},_oPnInMvCen,,_oFonte15,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)

	// seleciona atividades relacionadas ao contrato vinculado a NF seleciona na Etapa anterior
	_cQuery := " select distinct Z9_CODATIV,ZT_DESCRIC,AAM_CONTRT,Z9_UNIDCOB  "
	_cQuery += " from "+RetSQLName("SF1")+" SF1 (NoLock)  "

	_cQuery += "     inner join "+RetSQLName("SZ1")+" SZ1 (NoLock) "
	_cQuery += "     on SZ1.D_E_L_E_T_ = ''  "
	_cQuery += "     and Z1_FILIAL = F1_FILIAL  "
	_cQuery += "     and Z1_CODIGO = F1_PROGRAM "

	_cQuery += "    inner join "+RetSQLName("AAM")+" AAM (NoLock)  "
	_cQuery += "     on AAM.D_E_L_E_T_ = ''  "
	_cQuery += "     and AAM_CODCLI = Z1_CLIENTE  "
	_cQuery += "     and AAM_LOJA = Z1_LOJA  "
	_cQuery += "     and AAM_CONTRT = Z1_CONTRT  "

	_cQuery += "     inner join "+RetSQLName("SZ9")+" SZ9 (NoLock)  "
	_cQuery += "     on SZ9.D_E_L_E_T_ = ''  "
	_cQuery += "     and Z9_FILIAL = AAM_FILIAL  "
	_cQuery += "     and Z9_CONTRAT = AAM_CONTRT  "

	_cQuery += "     inner join "+RetSQLName("SZT")+" SZT (NoLock)  "
	_cQuery += "     on SZT.D_E_L_E_T_ = ''  "
	_cQuery += "     and ZT_FILIAL = Z9_FILIAL  "
	_cQuery += "     and ZT_CODIGO = Z9_CODATIV  "
	_cQuery += "     and ZT_MSBLQL <> '1'  "

	_cQuery += " where SF1.D_E_L_E_T_ = ''  "
	_cQuery += " and F1_FILIAL = '"+xFilial("SF1")+"'  "
	_cQuery += " and F1_FORNECE = '"+_cCodCli+"'  "
	_cQuery += " and F1_LOJA = '"+_cLojaCli+"'  "
	_cQuery += " and F1_DOC = '"+_NFCli+"' "
	_cQuery += " and F1_SERIE = '"+_NFSer+"' "
	_cQuery += " order by Z9_CODATIV "

	_aITM := U_SqlToVet(_cQuery)

	memowrit("C:\query\twmsa052_sfEtapa3.txt",_cQuery)

	// cria tabela temporária
	If (Select(AITM)<>0)
		dbSelectArea(AITM)
		dbCloseArea()
	EndIf

	_cArquivo := FWTemporaryTable():New( AITM )
	_cArquivo:SetFields( _aStruITM )
	_cArquivo:Create()

	For i:=1 To Len(_aITM)
		// inclui o registro no arquivo de trabalho
		(AITM)->(RecLock(AITM, .T.))
		(AITM)->AITM_OK		:= " "
		(AITM)->AITM_ATIV	:= AllTrim(_aITM[i][1])
		(AITM)->AITM_DESC	:= AllTrim(_aITM[i][2])
		(AITM)->AITM_CONT	:= AllTrim(_aITM[i][3])
		(AITM)->AITM_UNCOB	:= AllTrim(_aITM[i][4])
		(ACLI)->(MsUnLock())
	Next i

	(AITM)->(dbGoTop())

	// grid para seleção de atividades
	_oBrwITM := MsSelect():New (AITM,"AITM_OK",Nil, _aBrwITM, .F., _cMarca, {037,001,161,120},,,_oDlgITM)

	// ativa a tela
	_oDlgITM:Activate(,,,.F.,{||},,)

	// excluir objeto ao sair
	If ValType(_cArquivo) == "O"
		_cArquivo:Delete()
	EndIf

Return(_lRet)
// efetua validação da etapa 3
//-------------------------------------------------------------------------------------------------
Static Function sfVsfEt3()
	Local _lRet := .T.
	Local _aVld := {}
	Local aArea := GetArea()

	// seleciona registros ticado
	(AITM)->(dbSelectArea(AITM))
	(AITM)->(dbGoTop())
	While !(AITM)->(EOF())
		If (AITM)->AITM_OK == _cMarca
			AADD(_aVld,{_cMarca})
		EndIf
		(AITM)->(dbSkip())
	EndDo

	RestArea(aArea)

	// valida se ao menos uma atividade foi marcada para continuar o processo
	If Len(_aVld) == 0
		U_FtWmsMsg("Necessário selecionar ao menos 1 serviço para continuar!","ATENCAO")
		_lRet := .F.
	EndIf

Return(_lRet)
// Etapa 4 DE 4 no cadastro de nova OS de SVA - Informar a quantidade de atividades realizadas e cadastrar
//-------------------------------------------------------------------------------------------------
Static Function sfEtapa4()
	Local _lRet := .T.
	Local _oPnInMvCb
	Local _oPnInMvCen
	Local _oBmpNext
	Local _oBmpOK
	Local _oSay
	Local _oSayEtapa
	Local _oSayCli
	Local _oSayNF
	Private _oDlgQtd
	Private _oBrwEt4
	Private _aServ	:= {}

	// monta o dialogo do monitor
	_oDlgQtd := MSDialog():New(000,000,_aSizeDlg[2],_aSizeDlg[1],"OS de Serviço Valor Agregado",,,.F.,,,,,,.T.,,,.T. )
	_oDlgQtd:lEscClose := .F.

	// cria o panel do cabecalho - botoes de operacao
	_oPnInMvCb := TPanel():New(000,000,nil,_oDlgQtd,,.F.,.F.,,CLR_HGRAY,20,20,.T.,.F.)
	_oPnInMvCb:Align:= CONTROL_ALIGN_TOP

	// botao Back Page
	_oBmpPev := TBtnBmp2():New(000,000,060,022,"PGPREV",,,,{|| ((ACLI)->(dbSelectArea(ACLI)), (ACLI)->(dbGoTop()),_oDlgQtd:End()) },_oPnInMvCb,"Etapa Anterior",,.T.)
	_oBmpPev:Align := CONTROL_ALIGN_LEFT

	// botao Next Page
	_oBmpNext := TBtnBmp2():New(000,000,060,022,"PGNEXT",,,,{|| },_oPnInMvCb,"Proxima Etapa",,.T.)
	_oBmpNext:Align := CONTROL_ALIGN_LEFT
	_oBmpNext:Disable()

	// informativo do número da etapa
	_oSayEtapa	:= TSay():New(002,058,{||"4 / 4"},_oPnInMvCb,,_oFonte30,.F.,.F.,.F.,.T.,CLR_WHITE,CLR_WHITE,200,20)

	// confirma o cadastro de nova OS de SVA
	_oBmpOK := TBtnBmp2():New(000,000,060,022,"OK",,,,;
	{|| IIF(U_FtYesNoMsg("Confirma a inclusão de nova OS de Serviço de Valor Agregado?", "ATENÇÃO"),(IIF(sfCadSVA(), (_oDlgCOS:End(), _oDlgNF:End(), _oDlgITM:End(), _oDlgQtd:End()), Nil)),Nil) },;
	_oPnInMvCb,"Cadastrar OS SVA",,.T.)
	_oBmpOK:Align := CONTROL_ALIGN_RIGHT

	// cria o panel para os campos
	_oPnInMvCen := TPanel():New(000,000,nil,_oDlgQtd,,.F.,.F.,,,110,110,.T.,.F.)
	_oPnInMvCen:Align:= CONTROL_ALIGN_TOP

	// campos de informações e instruções
	_oSay	:= TSay():New(001,002,{||"Preencha"},_oPnInMvCen,,_oFonte17,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oSay	:= TSay():New(008,002,{||"Qtd Serv."},_oPnInMvCen,,_oFonte17,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oGroup	:= TGroup():New(00,01,20,42,Nil,_oPnInMvCen,,,.T.)
	_oGroup	:= TGroup():New(00,42,20,120,Nil,_oPnInMvCen,,,.T.)
	_oSayCli:= TSay():New(001,45,{||"Cliente: "+AllTrim(_cNomeNF)},_oPnInMvCen,,_oFonte15,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)
	_oSayNF	:= TSay():New(009,45,{||"NF: "+AllTrim(_NFCli)},_oPnInMvCen,,_oFonte15,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,20)

	// carrega o array _aServ somente com as atividades ticadas na etapa anterior
	(AITM)->(dbSelectArea(AITM))
	(AITM)->(dbGoTop())
	While !(AITM)->(EOF())
		If (AITM)->AITM_OK == _cMarca
			AADD(_aServ,{000.00,(AITM)->AITM_ATIV,(AITM)->AITM_DESC,(AITM)->AITM_CONT,(AITM)->AITM_UNCOB})
		EndIf
		(AITM)->(dbSkip())
	EndDo

	(AITM)->(dbGoTop())

	// grid para informar a quantidade de cada atividades realizadas
	_oBrwEt4 := MsBrGetDBase():new(037,001,118,122,,,,_oDlgQtd,,,,{||},,{||},,,,,,.T.,'',.T.,{||},.T.,{||},,)

	_oBrwEt4:SetArray(_aServ)
	_oBrwEt4:AddColumn(TCColumn():new('Quant.'		,{|| _aServ[_oBrwEt4:nAt,01]			}, '@E 999.99'	,,,"LEFT",,.F.,.T.,,,,,))
	_oBrwEt4:AddColumn(TCColumn():new('Ativ'		,{|| AllTrim(_aServ[_oBrwEt4:nAt,02])	}, '@!'			,,,"LEFT",,.F.,.F.,,,,,))
	_oBrwEt4:AddColumn(TCColumn():new('Descricao'	,{|| AllTrim(_aServ[_oBrwEt4:nAt,03])	}, '@!'			,,,"LEFT",,.F.,.F.,,,,,))
	_oBrwEt4:AddColumn(TCColumn():new('Contrato'	,{|| AllTrim(_aServ[_oBrwEt4:nAt,04])	}, '@!'			,,,"LEFT",,.F.,.F.,,,,,))
	_oBrwEt4:AddColumn(TCColumn():new('UN Cob.'		,{|| AllTrim(_aServ[_oBrwEt4:nAt,05])	}, '@!'			,,,"LEFT",,.F.,.F.,,,,,))
	_oBrwEt4:bLDblClick := {|| sfEditEt4(@_aServ)}
	_oBrwEt4:Refresh()

	// ativa a tela
	_oDlgQtd:Activate(,,,.F.,{||},,)

Return(_lRet)
// editar o grid Etapa 4
//-------------------------------------------------------------------------------------------------
Static Function sfEditEt4(aArr)

	lEditCell(@aArr, _oBrwEt4, "@E 999.99", 1)

Return
// valida se informou a quantidade de atividades em todos os selecionados e chama a função para efetuar o cadastro de SVA
//-------------------------------------------------------------------------------------------------
Static Function sfCadSVA()
	Local _lRet		:= .T.
	Local _aTemp	:= {}

	// valida o preenchimento de quantidade de atividades
	For i:=1 To Len(_aServ)
		If _aServ[i][1] == 0
			U_FtWmsMsg("Necessário preencher a quantidade de serviços realizados!","ATENCAO")
			_lRet := .F.
			Exit
		EndIf
	Next i

	If _lRet

		// prepara o array no padrão que será enviado para a função de cadastrar
		For nX:=1 To Len(_aServ)
			// _aTemp = Cod. Atividade, UN Cob, Quantidade
			AADD(_aTemp,{_aServ[nX][2],_aServ[nX][5],_aServ[nX][1]})
		Next nX

		// chama a função para efetuar novo cadastro de SVA
		If U_sfOSSVA(.T.,Nil,_NFCli,_NFSer,_cCodCli,_cLojaCli,_aTemp)
			U_FtWmsMsg("Cadastro efetuado!!","ATENCAO")
		EndIf
	EndIf

Return(_lRet)
// função para cadastrar nova SVA, OU complementar uma já existente
//-------------------------------------------------------------------------------------------------
User Function sfOSSVA(_lNewOrdSrv,_cNumOrdSrv,_NFCli,_NFSer,_cCodCli,_cLojaCli,_aAtv)
	Local _lRet			:= .T.
	Local _cNrOrdSrv	:= ""
	Local _cSqOrdSrv	:= ""
	Local _cOrdem		:= SOMA1(CriaVar("Z7_ORDEM",.f.))

	// se for complemento de OS e não informado para qual OS deve ser o complemente, retorna erro
	If !_lNewOrdSrv .And. Empty(_cNumOrdSrv)
		U_FtWmsMsg("Erro de entrada de dados. Para complementar uma OS de SVA deve-se informar o número da OS!","ATENCAO")
		_lRet := .F.
	EndIf

	// se não conseguiu localizar o cliente informado, retorna erro
	If _lRet
		dbSelectArea("SA1")
		dbSetOrder(1)
		IF !dbSeek(xFilial("SA1")+_cCodCli+_cLojaCli)
			U_FtWmsMsg("Erro de entrada de dados. Não foi possível localizar o cliente informado!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// se for complemento de OS, valida se a OS realmente existe e está em aberto
	If _lRet .And. !Empty(_cNumOrdSrv)
		dbSelectArea("SZ6")
		dbSetOrder(1)
		If !dbSeek(xFilial("SZ6")+_cNumOrdSrv+_cCodCli+_cLojaCli)
			U_FtWmsMsg("Erro de entrada de dados. Ordem de serviço não!","ATENCAO")
			_lRet := .F.
		Else
			If SZ6->Z6_STATUS <> "A"
				U_FtWmsMsg("Erro de entrada de dados. A ordem de serviço deve estar em aberto para complementa-la com novos serviços!","ATENCAO")
				_lRet := .F.
			EndIf
		EndIf
	EndIf

	// posiciona e valida a nota de entrada, caso seja uma nova OS
	If _lRet .And. _lNewOrdSrv
		dbSelectArea("SD1")
		dbSetOrder(1)
		If !dbSeek(xFilial("SD1")+_NFCli+PADR(_NFSer,3)+_cCodCli+_cLojaCli)
			U_FtWmsMsg("Erro de entrada de dados. Nota fiscal inválida, favor verificar!","ATENCAO")
			_lRet := .F.
		EndIf
	EndIf

	// valida se o array passado por parâmetro tem dados válidos
	If _lRet
		If Empty(_aAtv)
			U_FtWmsMsg("Erro de entrada de dados. Itens de atividades não informado!","ATENCAO")
			_lRet := .F.
		Else
			For nX:=1 To Len(_aAtv)
				If Empty(_aAtv[nX][1]) .Or. Empty(_aAtv[nX][2]) .Or. Empty(_aAtv[nX][3])
					U_FtWmsMsg("Erro de entrada de dados. Valores de Atividade, Unidade Cobrança ou Quantidade não informados!","ATENCAO")
					_lRet := .F.
					Exit
				EndIf
			Next nX
		EndIf
	EndIf

	// se for o cadastro de uma nova OS de SVA grava o cabeçalho
	If _lRet .And. _lNewOrdSrv
		// numero da ordem de servico
		_cNrOrdSrv := GetSxeNum("SZ6", "Z6_NROS")
		// confirma numeracao
		ConfirmSX8()
		// sequencia da orde de servico
		_cSqOrdSrv := StrZero(1, TamSx3("Z6_SEQOS")[1])
		// numero da ordem de servico completa
		_cNumOrdSrv := _cNrOrdSrv + _cSqOrdSrv

		// grava o cabeçalho
		Reclock("SZ6",.T.)
		SZ6->Z6_FILIAL	:= xFilial("SZ6")
		SZ6->Z6_NUMOS	:= _cNumOrdSrv
		SZ6->Z6_TIPOMOV	:= "I" // Interno
		SZ6->Z6_CLIENTE	:= _cCodCli
		SZ6->Z6_LOJA	:= _cLojaCli
		SZ6->Z6_CODIGO	:= SD1->D1_PROGRAM
		SZ6->Z6_ITEM	:= SD1->D1_ITEPROG
		SZ6->Z6_EMISSAO	:= dDatabase
		SZ6->Z6_STATUS	:= "A"
		SZ6->Z6_DOCSERI	:= _NFCli+_NFSer
		SZ6->Z6_FOTO    := "N"
		SZ6->Z6_USRINC	:= __cUserId
		SZ6->Z6_NROS    := _cNrOrdSrv
		SZ6->Z6_SEQOS   := _cSqOrdSrv
		MsUnlock()
	EndIf

	If _lRet

		For nY := 1 To Len(_aAtv)

			//Grava Itens/Atividades
			Reclock("SZ7",.T.)
			SZ7->Z7_FILIAL	:= xFilial("SZ7")
			SZ7->Z7_NUMOS	:= _cNumOrdSrv
			SZ7->Z7_ORDEM	:= _cOrdem
			SZ7->Z7_FATURAR	:= "S"
			SZ7->Z7_TIPOPER	:= "P"
			SZ7->Z7_CODATIV	:= _aAtv[nY,1]
			SZ7->Z7_UNIDCOB	:= _aAtv[nY,2]
			SZ7->Z7_QUANT	:= _aAtv[nY,3]
			SZ7->Z7_SALDO	:= _aAtv[nY,3]
			MsUnlock()

			// incremena 1 a ordem
			_cOrdem := SOMA1(_cOrdem)
		Next nY

	EndIf

Return(_lRet)