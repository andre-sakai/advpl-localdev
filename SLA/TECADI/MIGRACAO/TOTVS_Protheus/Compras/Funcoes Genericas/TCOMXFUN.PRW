#include "TOTVS.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Funcoes Genericas utilizadas no modulo COM-Compras      !
!                  ! 1. Consulta padrao do cadastro de produtos (FtF3_SB1)   !
!                  ! 2. Funcao para enviar Email de aviso de inclusao de     !
!                  !    solicitacoes de compras                              !
!                  ! 4. Total do mês corrente de solicitações bloqueadas e   !
!                  ! aprovadas                                               !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2012                                                 !
+------------------+--------------------------------------------------------*/

// ** 1. Consulta padrao do cadastro de produtos (FtF3_SB1)
User Function FtF3_SB1
	// Traz o conteudo do campo digitado no campo codigo produto
	Local cVarTmp := AllTrim(ReadVar())

	Local nX := 1

	// campo para digitar o texto da pesquisa
	Private cChvPesq := PadR(&cVarTmp, TamSx3("B1_DESC")[1])
	Private aTipoPes := {"Inicia com...","Contém a expressão..."}
	Private cTipoPes := "Contém a expressão..."

	// variaveis do browse
	Private aBrwItens := {}
	Private fCourie10 := TFont():New("Courier New",,14)
	// campos mostrados na consulta
	Private aCmpVisual := {"B1_COD", "B1_DESC", "B1_PRV1"}
	Private aCmpTitulo := sfRetInfCmp("X3_TITULO")
	Private aCmpLargC := sfRetInfCmp("X3_TAMANHO")

	Private cEvalDados := ""
	Private cEvalProc := sfEvalProc()
	// campos usados para filtrar
	Private lCbCodigo := .t.
	Private lCbDescri := .t.
	// variavel de retorno
	Private cRetCodSb1 := &(ReadVar())

	// monta o dialogo
	DEFINE MSDIALOG oDlgPesSB1 TITLE "Pesquisa Padrão - Cadastro de Produtos" FROM 000,000 TO 400,700 OF GetWndDefault() Pixel

	// cria o panel do cabecalho (opcoes da pesquisa)
	oPnlCabec := TPanel():New(000,000,nil,oDlgPesSB1,,.F.,.F.,,,000,030,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// opcoes de pesquisa
	oSayTpPesq := TSay():New(004,010,{||"Tipo da Pesquisa"},oPnlCabec,,,.F.,.F.,.F.,.T.,)
	oCmbTpPesq := TComboBox():New(012,010,{|u| If(PCount()>0,cTipoPes:=u,cTipoPes)},aTipoPes,090,010,oPnlCabec,,,,,,.T.,,"",,,,,,,cTipoPes)
	// campo para digitar o texto da pesquisa
	oCbCodigo := TCheckBox():New(003,105,"Código", {|u| If(PCount()>0,lCbCodigo:=u,lCbCodigo)}, oPnlCabec,48,8,,,,,,,,.T.,"",, )
	oCbDescri := TCheckBox():New(003,135,"Descrição",{|u| If(PCount()>0,lCbDescri:=u,lCbDescri)}, oPnlCabec,48,8,,,,,,,,.T.,"",, )
	// campo para digitar o texto da pesquisa
	oGetChave := TGet():New(012,105,{ |U| IF( PCOUNT()==0,cChvPesq,cChvPesq:=U ) },oPnlCabec,120,008 ,"@!S30",,nil,nil,nil,nil,nil,.T.,nil,.F.,nil,.F.,nil,nil,.F.,nil,nil,"cChvPesq")

	// botao que executa a pesquisa
	oBtnPesq := TButton():New(010,230,"Pesquisar",oPnlCabec,{||sfPesquisar()},040,012,,,,.T.,,"",,,,.F. )

	// browse com o resultado da pesquisa
	oBrowse := TWBrowse():New(000,000,700,700,,aCmpTitulo,aCmpLargC,oDlgPesSB1,,,,,,,,,,,,.F.,,.T.,,.F.,,, )
	oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oBrowse:oFont := fCourie10

	// atualiza o conteudo inicial do browse
	aBrwItens := Array(1,Len(aCmpTitulo))
	oBrowse:SetArray(aBrwItens)
	oBrowse:bLine := {|| &cEvalProc }

	// inclui funcao do duplo-click
	oBrowse:BlDblClick := {||	If(	oBrowse:aArray[1][1]==nil,;
	cRetCodSb1,;
	cRetCodSb1 := oBrowse:AARRAY[oBrowse:nAt,1] ),;
	oDlgPesSB1:End() }

	// cria painel inferior (rodape) com o botoes
	oPnlRodape := TPanel():New(000,000,nil,oDlgPesSB1,,.F.,.F.,,,000,030,.T.,.F. )
	oPnlRodape:Align:= CONTROL_ALIGN_BOTTOM

	// botao que executa a pesquisa
	oBtnOk := TButton():New(010,010,"Ok",oPnlRodape,{||If(	oBrowse:aArray[1][1]==nil,;
	cRetCodSb1,;
	cRetCodSb1 := oBrowse:AARRAY[oBrowse:nAt,1] ),;
	oDlgPesSB1:End()} ,040,012,,,,.T.,,"",,,,.F. )

	// seta o foco no campo de pesquisa
	oGetChave:SetFocus()

	ACTIVATE MSDIALOG oDlgPesSB1 Centered

	// posiciona no registro do cadastro de protutos
	dbSelectArea("SB1")
	SB1->(dbSetOrder(1)) // filial + codigo
	SB1->(dbSeek( xFilial("SB1")+cRetCodSb1 ))

Return (!Empty(cRetCodSb1))


// ** funcao que retorna o titulo dos campo do browse
Static Function sfRetInfCmp(mvProprie)
	Local aRet := {}
	Local nX := 0

	For nX := 1 to Len(aCmpVisual)
		// adiciona conteudo
		aAdd(aRet, AllTrim(GetSx3Cache(aCmpVisual[nX],mvProprie)) )
	Next nX
Return aRet


// ** funcao que monta a variavel para a macro substituicao dos campos
Static Function sfEvalProc()
	Local cRet := "{"
	Local nX := 0
	// inicializa variavel
	cEvalDados := "{"

	For nX := 1 to Len(aCmpVisual)
		// adiciona conteudo (ex: "{aBrwItens[oBrowse:nAt,01],aBrwItens[oBrowse:nAt,02]}")
		cRet += "aBrwItens[oBrowse:nAt,"+AllTrim(Str(nX)) +"]"+ If(nX==Len(aCmpVisual),"}",",")
		// adiciona o conteudo, sera utilizado na rotina sfPesquisar()
		// se for preco de venda entao formata
		If AllTrim(aCmpVisual[nX]) == "B1_PRV1"
			cEvalDados += "Transform(QRYSB1->B1_PRV1, '@E 999,999.99') " + If(nX==Len(aCmpVisual),"}",",")
			// se for a descricao filtra apenas 66 caracteres para nao estourar o tamanho da grade
		ElseIf AllTrim(aCmpVisual[nX]) == "B1_DESC"
			cEvalDados += "SUBSTR(QRYSB1->"+AllTrim(aCmpVisual[nX]) + ", 1, 66) "  + If(nX==Len(aCmpVisual),"}",",")
		Else
			cEvalDados += "QRYSB1->"+AllTrim(aCmpVisual[nX]) + If(nX==Len(aCmpVisual),"}",",")
		EndIf
	Next nX
Return cRet


// ** funcao executada para filtrar os dados
Static Function sfPesquisar()
	Local cQuery := ""
	Local nX := 0
	Local aPalavras := Separa(AllTrim(cChvPesq)," ")

	// monta a query de pesquisa
	cQuery := "SELECT "
	// adiciona os campos de retorno
	For nX := 1 to Len(aCmpVisual)
		// inclui o campo
		cQuery += AllTrim(aCmpVisual[nX])
		// inclui a virgula
		cQuery += If(nX==Len(aCmpVisual)," ",", ")
	Next nX
	// tabela a ser pesquisada
	cQuery += "FROM "+RetSqlName("SB1")+" SB1 "
	// filtro padrao
	cQuery += "WHERE "+RetSqlCond("SB1")+" "
	// filtro por grupo de produtos
	cQuery += "AND B1_GRUPO BETWEEN '0000' AND '9999' "
	// tipo do produtos (C-Compras/Consumo)
	cQuery += "AND B1_ZTIPPRO = 'C' "

	If (lCbCodigo).or.(lCbDescri)

		If Len(aPalavras)<1
			MsgStop("Digite pelo menos uma palavra para pesquisar !")
			oGetChave:SetFocus()
			return .t.
		EndIf

		cQuery+= If(Len(aPalavras)>0,"AND (","")

		// filtro no campo codigo
		If lCbCodigo
			// forma de pesquisa (1-inicia com, 2-contem a expressao)
			If oCmbTpPesq:nAt==1
				cQuery += "B1_COD LIKE '"+AllTrim(cChvPesq)+"%'"
			ElseIf oCmbTpPesq:nAt==2
				For nX := 1 to Len(aPalavras)
					cQuery += "B1_COD LIKE '%"+AllTrim(aPalavras[nX])+"%'"+If(nX==Len(aPalavras),""," AND ")
				Next nX
			EndIf
		EndIf

		// filtro para o campo descricao
		If lCbDescri
			cQuery += If(lCbCodigo," OR ","")
			// forma de pesquisa (1-inicia com, 2-contem a expressao)
			If oCmbTpPesq:nAt==1
				cQuery += "B1_DESC LIKE '"+AllTrim(cChvPesq)+"%'"

			ElseIf oCmbTpPesq:nAt==2
				For nX := 1 to Len(aPalavras)
					cQuery += "B1_DESC LIKE '%"+AllTrim(aPalavras[nX])+"%'"+If(nX==Len(aPalavras),""," AND ")
				Next nX
			EndIf
		EndIf
		cQuery+= If(Len(aPalavras)>0, ") ", "")
	EndIf
	// ordena dados
	cQuery += "ORDER BY B1_COD"

	//memowrit("C:\TESTV001.TXT",cQuery)

	// fecha o alias caso esteja aberto
	If Select("QRYSB1") <> 0
		dbSelectArea("QRYSB1")
		dbCloseArea()
	EndIf
	dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),"QRYSB1",.F.,.T.)

	dbSelectArea("QRYSB1")

	QRYSB1->(dbGoTop())

	If QRYSB1->(Eof())
		aBrwItens := Array(1,Len(aCmpTitulo))
		MsgStop("Não foi encontrado nenhum registro !")
		oGetChave:SetFocus()
	Else
		// zera variavel
		aBrwItens := {}
		// precorre todos os itens
		While QRYSB1->(!Eof())
			// adiciona o item
			aAdd(aBrwItens, &cEvalDados )
			// proximo registro
			QRYSB1->(dbSkip())
		EndDo
	EndIf
	//aBrwItens := Array(1,Len(aCmpTitulo))
	oBrowse:SetArray(aBrwItens)
	oBrowse:bLine := {|| &cEvalProc }
	oBrowse:aColSizes := {15,50,15}
	oBrowse:Refresh()

Return .t.


// ** 2. funcao para enviar Email de aviso de inclusao de solicitacoes de compras
User Function FtMailSC(mvNumSC1, mvDestin)
	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"SC1"})

	Local _cHtml := ""
	Local _cUsrSolic := ""
	Local _dDtSolic := CtoD("//")
	local _aTmpRecno := {}
	local _nTmpRecno

	// monta query para buscar os itens
	_cQrySC1 := "SELECT SC1.R_E_C_N_O_ SC1RECNO FROM "+RetSqlName("SC1")+" SC1 (nolock) "
	// filtro padrao
	_cQrySC1 += "WHERE "+RetSqlCond("SC1")+" "
	// numero da solicitacao
	_cQrySC1 += "AND C1_NUM = '"+mvNumSC1+"' "
	// atualiza os recno
	_aTmpRecno := U_SqlToVet(_cQrySC1)

	// verifica se ha itens a processar
	If (Len(_aTmpRecno) > 0)

		// posiciona no registro real da tabela
		dbSelectArea("SC1")
		SC1->(dbGoTo(_aTmpRecno[1]))

		// dados do cabecalho da solicitacao
		_cUsrSolic := AllTrim(UsrFullName(SC1->C1_USER))
		_dDtSolic  := SC1->C1_EMISSAO

		// inicia html
		_cHtml := '<table width="780px" align="center"> '
		_cHtml +='  	<tr> '
		_cHtml +=' 		<td> '
		_cHtml +='<table border="0" width="100%"> '
		_cHtml +='  	<tr> '
		_cHtml +='<td align="center" width="40%"> '
		_cHtml +='		<img src="http://tecadi.com.br/images/res/logo.png"></img> '
		_cHtml +='</td> '
		_cHtml +='<td align="center" width="60%" style="font-family: Tahoma; font-size: 20px; font-weight: bold; color: #1B5A8F;"> '
		//Título
		_cHtml +='SOLICITAÇÃO DE COMPRA - '+AllTrim(SM0->M0_CODFIL)+"/"+mvNumSC1+' </td></tr></table> '

		_cHtml +='<table border="1" width="780px" cellpadding="3" cellspacing="0" align="center"> '
		_cHtml +='<tr><td height="30" colspan="2" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">DADOS DA SOLICITAÇÃO DE COMPRA</td></tr> '

		_cHtml +='<tr> '
		_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Empresa:</td>'
		_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;'+AllTrim(SM0->M0_NOMECOM)+'</td> '
		_cHtml +='</tr> '

		_cHtml +='<tr> '
		_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Filial:</td>'
		_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;'+AllTrim(SM0->M0_CODFIL)+"-"+AllTrim(SM0->M0_FILIAL)+'</td> '
		_cHtml +='</tr> '

		_cHtml +='<tr> '
		_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Número:</td>'
		_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;'+mvNumSC1+'</td> '
		_cHtml +='</tr> '

		_cHtml +='<tr> '
		_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Solicitante:</td>'
		_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;'+_cUsrSolic+'</td> '
		_cHtml +='</tr> '

		_cHtml +='<tr> '
		_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Data de Emissão:</td>'
		_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;'+DtoC(_dDtSolic)+'</td> '
		_cHtml +='</tr> '

		_cHtml +='<tr> '
		_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Centro de Custo:</td>'
		_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;'+sfRetCC(mvNumSC1)+'</td> '
		_cHtml +='</tr> '

		_cHtml += '<tr>'
		_cHtml += '	<td style="font-family: Tahoma; font-size: 12px;">Status:</td>'
		_cHtml += '	<td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;"><font color="#FF0000">&nbsp;Aguardando Geração do Pedido de Compras</font></td>'
		_cHtml += '</tr>'
		_cHtml +='</table> '

		_cHtml +='<br> '
		_cHtml +='<table border="1" width="100%" cellpadding="3" cellspacing="0" align="center"> '
		_cHtml +='	<tr><td height="30" colspan="10" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">ITENS DA SOLICITAÇÃO DE COMPRA - '+AllTrim(SM0->M0_CODFIL)+"/"+mvNumSC1+'</td></tr> '

		_cHtml += '                  <tr>'
		_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="30">Item</td>'
		_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="80">Codigo</td>'
		_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="300">Descrição</td>'
		_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="80">Inf.Adic.Produto</td>'
		_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="20">UM</td>'
		_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="70" align="right">Quantidade</td>'
		_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="80" align="right">Preço Unit. Aproximado</td>'
		_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="80" align="right">Valor Total Aproximado</td>'
		_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="190">Observações</td>'
		_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="60">Item Contábil</td>'
		_cHtml += '                  </tr>'

		// varre todos os itens da solicitacao
		For _nTmpRecno := 1 to Len(_aTmpRecno)

			// posiciona no registro real da tabela
			dbSelectArea("SC1")
			SC1->(dbGoTo(_aTmpRecno[_nTmpRecno]))

			_cHtml += '                  <tr>'
			_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="30" align="center">'+SC1->C1_ITEM+'</td>'
			_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="80"  >'+AllTrim(SC1->C1_PRODUTO)+'</td>'
			_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="300" >'+AllTrim(SC1->C1_DESCRI)+'</td>'
			_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="80"  >'+If(Empty(SC1->C1_ZINFADI),'&nbsp;',AllTrim(SC1->C1_ZINFADI))+'</td>'
			_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="20" align="center">'+SC1->C1_UM+'</td>'
			_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="70" align="right">'+TransForm(SC1->C1_QUANT,PesqPict("SC1","C1_QUANT"))+'</td>'
			_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="80" align="right">'+TransForm(SC1->C1_ZPRECO,PesqPict("SC1","C1_ZPRECO"))+'</td>'
			_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="80" align="right">'+TransForm(SC1->C1_ZTOTAL,PesqPict("SC1","C1_ZTOTAL"))+'</td>'
			_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="190" >'+If(Empty(SC1->C1_OBS),'&nbsp;',AllTrim(SC1->C1_OBS))+'</td>'
			_cHtml += '                     <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="60" >'+AllTrim(SC1->C1_ITEMCTA)+"-"+AllTrim(Posicione("CTD",1,xFilial("CTD")+SC1->C1_ITEMCTA,"CTD_DESC01"))+'</td>'
			_cHtml += '                  </tr>'

			// proximo item
		Next _nTmpRecno

		// rodape do e-mail
		_cHtml +='</table> '

		_cHtml +='</br>'
		_cHtml +='<hr width="80%" noshade="noshade" align="center">'
		_cHtml +='<div align="center"><span style="font-family: Tahoma; font-size: 11px; background-color: #FFFFFF; color: #000000;">Não responda este E-mail - Mensagem automática utilizando o serviço de Workflow TECADI - Proudly Made by TECADI Technology</span> </div>'
		_cHtml +='  </td>'
		_cHtml +='  </tr>'
		_cHtml +='</table>'
		_cHtml +='</table>'

		memowrit("c:\temp\ftmailsc.html", _cHtml)

		// envia o Email
		U_FtMail(_cHtml, "Solicitação de Compras - Nr. "+AllTrim(SM0->M0_CODFIL)+"/"+mvNumSC1, mvDestin)

	EndIf

	// restaura a Area Inicial
	RestOrd(_aAreaIni,.t.)
	RestArea(_aAreaAtu)

Return


// 3. funcao para enviar Email de aviso de aprovação ou recusa de itens de pedidos de compras
User Function FtMailPC(mvNumSC7, mvCenCusto, mvItemCtbl, mvUsrSolic, mvObsRecusa)
	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"SC7"})

	Local _cHtml := ""
	Local _cUsrSolic := ""
	Local _dDtSolic := CtoD("//")

	// recno SC7
	local _aTmpRecno := {}
	local _nTmpRecno

	// dados contabeis
	Local _cCenCusto, _cItCtba, _cConCtba

	// status do pedido/aprovacao
	Local _cStPedido  := ""
	Local _cStAprova  := ""
	local _cCorStatus := ""

	// grupo de informacoes
	local _aTmpAgrup := {}
	local _nTmpAgrup

	// controle de cabecalho gerado
	local _lCabecOk := .f.

	// calendario
	local _cAnoCalend

	// destinatarios
	local _cEndDest
	local _aEndDest := {}
	local _nTmpDest

	// fornecedor / loja / descrição
	local _cCodForn  := ""
	local _cLjForn   := ""
	local _cNomeForn := ""

	// valores padroes
	Default mvCenCusto := CriaVar("C7_CC", .f.)
	Default mvItemCtbl := CriaVar("C7_ITEMCTA", .f.)
	Default mvUsrSolic := CriaVar("C7_ZUSRSC", .f.)

	// Monta query para buscar os itens
	_cQrySC7 := " SELECT "
	_cQrySC7 += "        C7_NUM, "
	_cQrySC7 += "        C7_APROV, "
	_cQrySC7 += "        C7_ZUSRSC, "
	_cQrySC7 += "        C7_CONAPRO, "
	_cQrySC7 += "        C7_ZALCAPR, "
	_cQrySC7 += "        C7_ZCONTAL, "
	_cQrySC7 += "        C7_ZALCRAP, "
	_cQrySC7 += "        C7_ZNIVRAP, "
	_cQrySC7 += "        C7_ZNIVAPR, "
	_cQrySC7 += "        C7_ZUSRAPR, "
	_cQrySC7 += "        C7_CC, "
	_cQrySC7 += "        C7_ITEMCTA, "
	_cQrySC7 += "        Sum(C7_TOTAL) C7_TOTAL, "
	_cQrySC7 += "        Count(*) QTD_ITENS "
	// ped. compras / cad. TES
	_cQrySC7 += " FROM "+RetSqlTab("SC7,SF4")
	// filtro padrao
	_cQrySC7 += " WHERE "+RetSqlCond("SC7,SF4")
	// numero do pedido
	_cQrySC7 += " AND C7_NUM = '"+mvNumSC7+"' "
	// TES / Gera Financeiro
	_cQrySC7 += " AND C7_TES = F4_CODIGO AND F4_DUPLIC = 'S' "
	// quantidade ja entregue
	_cQrySC7 += " AND C7_QUJE < C7_QUANT "
	// eliminado por residuo
	_cQrySC7 += " AND ((C7_RESIDUO = ' ') OR (C7_RESIDUO <> '' AND C7_ZCONTAL = 'X')) "
	// filtra por centro de custo
	If ( ! Empty(mvCenCusto) )
		_cQrySC7 += " AND C7_CC = '"+mvCenCusto+"' "
	EndIf
	// filtra por item contabil
	If ( ! Empty(mvItemCtbl) )
		_cQrySC7 += " AND C7_ITEMCTA = '"+mvItemCtbl+"' "
	EndIf
	// filtra por usuario solicitante
	If ( ! Empty(mvUsrSolic) )
		_cQrySC7 += " AND C7_ZUSRSC = '"+mvUsrSolic+"' "
	EndIf

	// agrupamento de dados
	_cQrySC7 += " GROUP  BY C7_NUM, "
	_cQrySC7 += "           C7_APROV, "
	_cQrySC7 += "           C7_ZUSRSC, "
	_cQrySC7 += "           C7_CONAPRO, "
	_cQrySC7 += "           C7_ZALCAPR, "
	_cQrySC7 += "           C7_ZCONTAL, "
	_cQrySC7 += "           C7_ZALCRAP, "
	_cQrySC7 += "           C7_ZNIVRAP, "
	_cQrySC7 += "           C7_ZNIVAPR, "
	_cQrySC7 += "           C7_ZUSRAPR, "
	_cQrySC7 += "           C7_CC, "
	_cQrySC7 += "           C7_ITEMCTA "

	//Grava arquivo TXT com sql gerada
	MemoWrit("c:\query\ftmailpc_1.txt",_cQrySC7)

	// Gera array para trabalho
	_aTmpAgrup := U_SqlToVet(_cQrySC7)

	// varre todos os itens
	For _nTmpAgrup := 1 to Len(_aTmpAgrup)

		// busca dados detalhados conforme agrupamento
		_cQrySC7 := "SELECT SC7.R_E_C_N_O_ SC7RECNO "
		// ped. compras / cad. TES
		_cQrySC7 += " FROM "+RetSqlTab("SC7,SF4")
		// filtro padrao
		_cQrySC7 += " WHERE "+RetSqlCond("SC7,SF4")
		// numero do pedido
		_cQrySC7 += " AND C7_NUM = '"+mvNumSC7+"' "
		// TES / Gera Financeiro
		_cQrySC7 += " AND C7_TES = F4_CODIGO AND F4_DUPLIC = 'S' "
		// quantidade ja entregue
		_cQrySC7 += " AND C7_QUJE < C7_QUANT "
		// eliminado por residuo
		_cQrySC7 += " AND ((C7_RESIDUO = ' ') OR (C7_RESIDUO <> '' AND C7_ZCONTAL = 'X')) "

		// demais campos agrupados
		_cQrySC7 += " AND C7_APROV   = '"+_aTmpAgrup[_nTmpAgrup][ 2]+"' "
		_cQrySC7 += " AND C7_ZUSRSC  = '"+_aTmpAgrup[_nTmpAgrup][ 3]+"' "
		_cQrySC7 += " AND C7_CONAPRO = '"+_aTmpAgrup[_nTmpAgrup][ 4]+"' "
		_cQrySC7 += " AND C7_ZALCAPR = '"+_aTmpAgrup[_nTmpAgrup][ 5]+"' "
		_cQrySC7 += " AND C7_ZCONTAL = '"+_aTmpAgrup[_nTmpAgrup][ 6]+"' "
		_cQrySC7 += " AND C7_ZALCRAP = '"+_aTmpAgrup[_nTmpAgrup][ 7]+"' "
		_cQrySC7 += " AND C7_ZNIVRAP = '"+_aTmpAgrup[_nTmpAgrup][ 8]+"' "
		_cQrySC7 += " AND C7_ZNIVAPR = '"+_aTmpAgrup[_nTmpAgrup][ 9]+"' "
		_cQrySC7 += " AND C7_ZUSRAPR = '"+_aTmpAgrup[_nTmpAgrup][10]+"' "
		_cQrySC7 += " AND C7_CC      = '"+_aTmpAgrup[_nTmpAgrup][11]+"' "
		_cQrySC7 += " AND C7_ITEMCTA = '"+_aTmpAgrup[_nTmpAgrup][12]+"' "

		//Grava arquivo TXT com sql gerada
		MemoWrit("c:\query\ftmailpc_2.txt",_cQrySC7)

		// armazena os RECNOs no vetor
		_aTmpRecno := U_SqlToVet(_cQrySC7)

		// controle de cabecalho gerado
		_lCabecOk := .f.

		// varre todos os itens encontrados na condicao
		For _nTmpRecno := 1 to Len(_aTmpRecno)

			// posiciona no registro real da tabela
			dbSelectArea("SC7")
			SC7->(dbGoTo(_aTmpRecno[_nTmpRecno]))

			// prepara o cabecalho do corpo do E-mail
			If ( ! _lCabecOk )

				// dados contabeis
				_cCenCusto  := SC7->C7_CC
				_cItCtba    := SC7->C7_ITEMCTA
				_cConCtba   := SC7->C7_CONTA

				// fornecedor / loja / nome
				_cCodForn  := SC7->C7_FORNECE
				_cLjForn   := SC7->C7_LOJA
				_cNomeForn := Posicione("SA2", 1, xFilial("SA2") + _cCodForn + _cLjForn, "A2_NOME")

				// calendario
				_cAnoCalend := SubStr(DtoS(_dDtSolic),1,4)
				
				// dados do cabecalho da solicitacao
				_cUsrSolic  := Posicione("Z26", 3, xFilial("Z26") + _cAnoCalend + SC7->C7_ZUSRSC, "Z26_GERENT") 
				_dDtSolic   := SC7->C7_EMISSAO

				// define destinatarios - solicitante
				_cEndDest := AllTrim(UsrRetMail(SC7->C7_ZUSRSC))+";"
				// define destinatarios - comprador
				_cEndDest += AllTrim(UsrRetMail(SC7->C7_USER))+";"

				// status - L-Liberado Automatico
				If (SC7->C7_CONAPRO == "L").and.(Empty(SC7->C7_ZUSRAPR))
					_cStPedido  := "Aprovado"
					_cStAprova  := "Pedido/Item Liberado - Valor(es) dentro da Alçada/Orçamento"
					_cCorStatus := "#088A08"

					// status - L-Liberado Manual
				ElseIf (SC7->C7_CONAPRO == "L").and.( ! Empty(SC7->C7_ZUSRAPR) )

					// posiciona no ID da Alcada Aprovadora
					dbSelectArea("Z26")
					Z26->(dbSetOrder(1)) // 1-Z26_FILIAL, Z26_CALEND, Z26_PERFID
					Z26->(dbSeek( xFilial("Z26")+_cAnoCalend+SC7->C7_ZALCAPR ))

					_cStPedido  := "Aprovado"
					_cStAprova  := "Pedido/Item Aprovado por "+SC7->C7_ZALCAPR+" / "+SC7->C7_ZNIVAPR+" - "+AllTrim(Upper(Z26->Z26_GERENT))
					_cCorStatus := "#088A08"

					// busca todos os perfis acima do usuario solicitante
					_aEndDest := sfRetAcima(_cAnoCalend, SC7->C7_ZIDALCA, "C")
					// varre todos os perfis, e define email
					For _nTmpDest := 1 to Len(_aEndDest)
						_cEndDest += AllTrim(UsrRetMail(_aEndDest[_nTmpDest][2]))+";"
					Next _nTmpDest

					// status - B-Bloqueado / Aguardando analise
				ElseIf (SC7->C7_CONAPRO == "B").and.(SC7->C7_ZCONTAL <> "X")

					// posiciona no ID da Alcada Aprovadora
					dbSelectArea("Z26")
					Z26->(dbSetOrder(1)) // 1-Z26_FILIAL, Z26_CALEND, Z26_PERFID
					Z26->(dbSeek( xFilial("Z26")+_cAnoCalend+SC7->C7_ZALCRAP ))

					// atualiza informacoes
					_cStPedido  := "Aguardando Análise"
					_cStAprova  := SC7->C7_ZALCRAP+" / "+SC7->C7_ZNIVRAP+" - "+AllTrim(Upper(Z26->Z26_GERENT))
					_cCorStatus := "#FF0000"

					// define destinatarios - aprovador
					_cEndDest += AllTrim(UsrRetMail(Z26->Z26_CODUSU))+";"

					// status - B-Bloqueado / Recusado
				ElseIf (SC7->C7_CONAPRO == "B").and.(SC7->C7_ZCONTAL == "X").and.(SC7->C7_RESIDUO == "S")

					// posiciona no ID da Alcada Aprovadora
					dbSelectArea("Z26")
					Z26->(dbSetOrder(1)) // 1-Z26_FILIAL, Z26_CALEND, Z26_PERFID
					Z26->(dbSeek( xFilial("Z26")+_cAnoCalend+SC7->C7_ZALCAPR ))

					// atualiza informacoes
					_cStPedido  := "Recusado"
					_cStAprova  := SC7->C7_ZALCAPR+" / "+SC7->C7_ZNIVAPR+" - "+AllTrim(Upper(Z26->Z26_GERENT))
					_cCorStatus := "#FF0000"

					// busca todos os perfis acima do usuario solicitante
					_aEndDest := sfRetAcima(_cAnoCalend, SC7->C7_ZIDALCA, "C")
					// varre todos os perfis, e define email
					For _nTmpDest := 1 to Len(_aEndDest)
						_cEndDest += AllTrim(UsrRetMail(_aEndDest[_nTmpDest][2]))+";"
					Next _nTmpDest

					// aprovador
					_cEndDest += AllTrim(UsrRetMail(Z26->Z26_CODUSU))+";"

				EndIf

				// inicia corpo do e-mail
				_cHtml :='<table width="780px" align="center"> '
				_cHtml +='  <tr> '
				_cHtml +=' 		<td> '

				_cHtml +='<table border="0" width="100%"> '
				_cHtml +='  	<tr> '
				_cHtml +='<td align="center" width="40%"> '
				_cHtml +='		<img src="http://tecadi.com.br/images/res/logo.png"></img> '
				_cHtml +='</td> '
				_cHtml +='<td align="center" width="60%" style="font-family: Tahoma; font-size: 20px; font-weight: bold; color: #1B5A8F;"> '

				_cHtml +='PEDIDO DE COMPRA - '+AllTrim(SM0->M0_CODFIL)+"/"+mvNumSC7+' </td></tr>'
				_cHtml +='</table> '

				_cHtml +='<table border="1" width="100%" cellpadding="3" cellspacing="0" align="center"> '
				_cHtml +='<tr><td height="30" colspan="2" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">DADOS DO PEDIDO DE COMPRA</td></tr> '

				_cHtml +='<tr> '
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Empresa:</td>'
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;'+AllTrim(SM0->M0_NOMECOM)+'</td> '
				_cHtml +='</tr> '

				_cHtml +='<tr> '
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Filial:</td>'
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;'+AllTrim(SM0->M0_CODFIL)+"-"+AllTrim(SM0->M0_FILIAL)+'</td> '
				_cHtml +='</tr> '

				_cHtml +='<tr> '
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Número:</td>'
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;'+mvNumSC7+'</td> '
				_cHtml +='</tr> '

				_cHtml +='<tr> '
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Fornecedor/Loja - Nome:</td>'
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;' + _cCodForn + '/' + _cLjForn + ' - ' + AllTrim(_cNomeForn) + '</td> '
				_cHtml +='</tr> '

				_cHtml +='<tr> '
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Solicitante:</td>'
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;'+_cUsrSolic+'</td> '
				_cHtml +='</tr> '

				_cHtml +='<tr> '
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Data de Emissão:</td>'
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;'+DtoC(_dDtSolic)+'</td> '
				_cHtml +='</tr> '

				_cHtml +='<tr> '
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Centro de Custo:</td>'
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;'+Alltrim(_cCenCusto)+" - "+AllTrim(Posicione("CTT",1, xFilial("CTT")+_cCenCusto ,"CTT_DESC01"))+'</td> '
				_cHtml +='</tr> '

				_cHtml +='<tr> '
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Item Contábil:</td>'
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;'+Alltrim(_cItCtba)+" - "+AllTrim(Posicione("CTD",1, xFilial("CTD")+_cItCtba ,"CTD_DESC01"))+'</td> '
				_cHtml +='</tr> '

				_cHtml +='<tr> '
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Conta Contábil:</td>'
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">&nbsp;'+Alltrim(_cConCtba)+" - "+AllTrim(Posicione("CT1",1, xFilial("CT1")+_cConCtba ,"CT1_DESC01"))+'</td> '
				_cHtml +='</tr> '

				_cHtml +='<tr> '
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Status:</td>'
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;"><font color="'+_cCorStatus+'">&nbsp;'+_cStPedido+'</font></td> '
				_cHtml +='</tr> '

				// se foi recusado, coloca o motivo no email
				If (AllTrim(Upper(_cStPedido)) == "RECUSADO")
					_cHtml +='<tr> '
					_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Motivo Recusa:</td>'
					_cHtml +='<td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;"><font color="'+_cCorStatus+'">&nbsp;'+mvObsRecusa+'</font></td> '
					_cHtml +='</tr> '
				EndIf

				_cHtml +='<tr> '
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px;">Analisador:</td>'
				_cHtml +='<td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;"><font color="'+_cCorStatus+'">&nbsp;'+_cStAprova+'</font></td> '
				_cHtml +='</tr> '
				_cHtml +='</table> '

				_cHtml +='<br> '
				_cHtml +='<table border="1" width="100%" cellpadding="3" cellspacing="0" align="center"> '
				_cHtml +='	<tr><td height="30" colspan="11" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">ITENS ANALISADOS DO PEDIDO DE COMPRA - '+AllTrim(SM0->M0_CODFIL)+"/"+mvNumSC7+'</td></tr> '

				_cHtml += '  <tr> '
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="30">Item</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="50">Codigo</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="300">Descrição</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="190">Inf.Adic.Produto</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="20">UM</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="70" align="right">Quantidade</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="70" align="right">Valor</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="20">Necessidade</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="60">Observações</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="30">Número SC</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="30">Item SC</td>'
				_cHtml += '  </tr>'

				// status do cabecalho ok
				_lCabecOk := .t.

			EndIf

			// inclusao dos itens
			_cHtml +='  <tr> '
			_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="30" align="center">'+SC7->C7_ITEM+'</td>'
			_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="50" >'+AllTrim(SC7->C7_PRODUTO)+'</td>'
			_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="300">'+AllTrim(SC7->C7_DESCRI)+'</td>'
			_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="190" >'+If(Empty(SC7->C7_ZINFADI),'&nbsp;',AllTrim(SC7->C7_ZINFADI))+'</td>'
			_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="20" align="center">'+SC7->C7_UM+'</td>'
			_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="70" align="right">'+TransForm(SC7->C7_QUANT,PesqPict("SC7","C7_QUANT"))+'</td>'
			_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="70" align="right">'+TransForm(SC7->C7_TOTAL,PesqPict("SC7","C7_TOTAL"))+'</td>'
			_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="20">'+DTOC(SC7->C7_DATPRF)+'</td>'
			_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="80" >'+If(Empty(SC7->C7_OBS),'&nbsp;',SC7->C7_OBS)+'</td>'
			_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="30" align="center">'+SC7->C7_NUMSC+'</td>'
			_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="20" align="center">'+SC7->C7_ITEMSC+'</td>'
			_cHtml +='  </tr> '

			// proximo item
		Next _nTmpRecno

		// rodape do e-mail
		_cHtml +='</table> '

		_cHtml +='</br>'
		_cHtml +='<hr width="80%" noshade="noshade" align="center">'
		_cHtml +='<div align="center"><span style="font-family: Tahoma; font-size: 11px; background-color: #FFFFFF; color: #000000;">Não responda este E-mail - Mensagem automática utilizando o serviço de Workflow TECADI - Proudly Made by TECADI Technology</span> </div>'
		_cHtml +='  </td>'
		_cHtml +='  </tr>'
		_cHtml +='</table>'
		_cHtml +='</table>'

		memowrit("c:\temp\ftmailpc.html", _cHtml)

		// envia o Email
		U_FtMail(_cHtml, "Pedido de Compras - Nr. "+AllTrim(SM0->M0_CODFIL)+"/"+mvNumSC7, _cEndDest)

		// proximo item agrupado
	Next _nTmpAgrup

	// restaura a Area Inicial
	RestOrd(_aAreaIni,.t.)
	RestArea(_aAreaAtu)

Return

User Function FtTstSch()
	U_FtPendPC({Nil,Nil,Nil,"01","101",Nil,Nil})
Return

// ** funcao para enviar Email avisando sobre os pedidos de compra pendentes
User Function FtPendPC(mvParamIxb)

	// area atual
	Local _cHtml := ""
	Local _cUsrSolic := ""
	Local _dDtSolic := CtoD("//")
	local _cCodNatur := ""
	local _aTmpRecno := {}
	local _nTmpRecno := 0
	Local _cCodCon 	:= ""
	Local _cStPedido 	:= ""
	Local _cAnaSc	 	:= ""
	Local _cQrySC7		:= ""
	Local _cCodcc	:= ""
	Local _cCodIc		:= ""

	// tamanho do vetor
	Local _nTamVet := 0
	// codido da empresa
	local _cCodEmp := ""
	// codigo da filial
	local _cCodFil := ""

	// valor padrao
	Default mvParamIxb := {}

	// log da conexao
	FWLogMsg('INFO',, 'SIGACOM', FunName(), '', '01',"FtPendPC: 1. Início" , 0, 0, {})

	// define valores
	_nTamVet := Len(mvParamIxb)

	// verifica se ha algum ambiente ativo
	If (Select("SM0") == 0)

		// log da conexao
		FWLogMsg('INFO',, 'SIGACOM', FunName(), '', '01',"FtPendPC: 2. Limpa Environment" , 0, 0, {})

		// limpa qualquer ambiente
		RpcClearEnv()

		// se tamanho do vetor estiver correto
		If (_nTamVet >= 4)

			// codigo da empresa
			_cCodEmp := mvParamIxb[_nTamVet - 3]

			// codigo da filial
			_cCodFil := mvParamIxb[_nTamVet - 2]

			// log da conexao
			FWLogMsg('INFO',, 'SIGACOM', FunName(), '', '01',"FtPendPC: 3. Prepara Execução em "+DtoC(Date())+" "+Time()+" - Emp/Fil: "+_cCodEmp+"/"+_cCodFil , 0, 0, {})

			// prepara ambiente
			RpcSetEnv(_cCodEmp, _cCodFil,,,,,{"Z46", "SA1", "AKD", "CT4", "CTI"})

			// Monta query para buscar os itens
			_cQrySC7 := "SELECT C7_FILIAL, C7_NUM, C7_ITEMCTA, Case When DCD_NOMFUN IS NULL Then 'Cadastrar ID no WMS: '+C7_ZUSRSC Else DCD_NOMFUN End as Nome, C7_DATPRF, C7_CC, SUM(C7_TOTAL) AS TOTAL_PC "
			_cQrySC7 += " FROM "+RetSqlName("SC7")+" SC7 (nolock) "
			_cQrySC7 += " Left join "+RetSqlName("DCD")+" DCD (nolock) "
			_cQrySC7 += " on DCD.D_E_L_E_T_ = '' "
			_cQrySC7 += " and DCD_CODFUN = C7_ZUSRSC "
			// filtro padrao
			_cQrySC7 += "WHERE SC7.D_E_L_E_T_ = ' ' "
			// Número da solicitação
			_cQrySC7 += "AND C7_CONAPRO = 'B' "
			// Código do Centro de Custo
			_cQrySC7 += "AND C7_ZCONTAL >= 'A' "
			// Código do item contábil
			_cQrySC7 += "GROUP BY C7_FILIAL, C7_NUM, C7_ITEMCTA, DCD_NOMFUN, C7_ZUSRSC, C7_DATPRF, C7_CC "
			// Código do item contábil
			_cQrySC7 += "ORDER BY C7_FILIAL, TOTAL_PC "

			memowrit("c:\temp\FtPendPC.txt", _cQrySC7)

			// Gera array para trabalho
			_aTmpRecno := U_SqlToVet(_cQrySC7)

			// Verifica se ha itens a processar
			If (Len(_aTmpRecno) > 0)

				// Monta corpo do E-mail
				_cHtml :='<table width="780px" align="center"> '
				_cHtml +='  	<tr> '
				_cHtml +=' 		<td> '
				_cHtml +='<table border="0" width="100%"> '
				_cHtml +='  	<tr> '
				_cHtml +='<td align="center" width="40%"> '
				_cHtml +='		<img src="http://tecadi.com.br/images/res/logo.png"></img> '
				_cHtml +='</td> '
				_cHtml +='<td align="center" width="60%" style="font-family: Tahoma; font-size: 20px; font-weight: bold; color: #1B5A8F;"> '

				_cHtml +='LISTA DE PEDIDOS DE COMPRA PENDENTES</td></tr></table> '

				_cHtml +='<br> '
				_cHtml +='<table border="1" width="100%" cellpadding="3" cellspacing="0" align="center"> '
				_cHtml +='	<tr><td height="30" colspan="7" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">RELAÇÃO DOS PEDIDOS DE COMPRA</td></tr> '

				_cHtml += '  <tr> '
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="05">Filial</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="05">Número</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="10">Necessidade</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="30">Centro de Custo</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="30">Item contábil</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="10">Usuário</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="10">Valor</td>'

				_cHtml += '  </tr>'

				// varre todos os itens da solicitacao
				For _nTmpRecno := 1 to Len(_aTmpRecno)
					_cCodcc	:=	_aTmpRecno[_nTmpRecno][6]+" - "+Posicione("CTT",1,XFILIAL("CTT")+_aTmpRecno[_nTmpRecno][6],"CTT_DESC01")
					_cCodIc	:=	_aTmpRecno[_nTmpRecno][3]+" - "+Posicione("CTD",1,XFILIAL("CTD")+_aTmpRecno[_nTmpRecno][3],"CTD_DESC01")
					_cHtml +='  <tr> '
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="05" align="center">'+_aTmpRecno[_nTmpRecno][1]+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="05" >'+AllTrim(_aTmpRecno[_nTmpRecno][2])+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="10">'+dtoc(Stod(_aTmpRecno[_nTmpRecno][5]))+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="30">'+AllTrim(_cCodCc)+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="30" >'+AllTrim(_cCodIc)+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="10" >'+AllTrim(_aTmpRecno[_nTmpRecno][4])+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="10" align="right">'+TransForm(_aTmpRecno[_nTmpRecno][7],PesqPict("SC7","C7_TOTAL"))+'</td>'
					_cHtml +='  </tr> '

					// proximo item
				Next _nTmpRecno

				// rodape do e-mail
				_cHtml +='</table> '

				_cHtml +='</br>'
				_cHtml +='<hr width="80%" noshade="noshade" align="center">'
				_cHtml +='<div align="center"><span style="font-family: Tahoma; font-size: 11px; background-color: #FFFFFF; color: #000000;">Não responda este E-mail - Mensagem automática utilizando o serviço de Workflow TECADI - Proudly Made by TECADI Technology</span> </div>'
				_cHtml +='  </td>'
				_cHtml +='  </tr>'
				_cHtml +='</table>'
				_cHtml +='</table> '

				memowrit("c:\temp\FtPendPC.html", _cHtml)

				// envia o Email
				//U_FtMail(_cHtml,"Pedidos de Compra Pendentes", SuperGetMV("TC_MAILPAP",,"suporte@tecadi.com.br")  )

			EndIf

			// limpa qualquer ambiente
			RpcClearEnv()

		EndIf
	EndIf

Return

// ** Funcao para enviar Email avisando sobre as solicitacoes de compras pendentes
User Function FtPendSC(mvParamIxb)

	// area atual
	Local _cHtml := ""
	Local _cUsrSolic := ""
	Local _dDtSolic := CtoD("//")
	local _cCodNatur := ""
	local _aTmpRecno := {}
	local _nTmpRecno := 0
	Local _cCodCon 	:= ""
	Local _cStPedido 	:= ""
	Local _cAnaSc	 	:= ""
	Local _cQrySC7		:= ""
	Local _cCodcc	:= ""
	Local _cCodIc		:= ""

	// tamanho do vetor
	Local _nTamVet := 0
	// codido da empresa
	local _cCodEmp := ""
	// codigo da filial
	local _cCodFil := ""

	// valor padrao
	Default mvParamIxb := {}

	// log da conexao
	FWLogMsg('INFO',, 'SIGACOM', FunName(), '', '01',"FtSendMail: "+DtoC(Date())+" "+Time()+" - Emp/Fil: "+cEmpAnt+"/"+cFilAnt  , 0, 0, {})

	// define valores
	_nTamVet := Len(mvParamIxb)

	// verifica se ha algum ambiente ativo
	If (Select("SM0") == 0)

		// limpa qualquer ambiente
		RpcClearEnv()

		// se tamanho do vetor estiver correto
		If (_nTamVet >= 4)

			// codigo da empresa
			_cCodEmp := mvParamIxb[_nTamVet - 3]

			// codigo da filial
			_cCodFil := mvParamIxb[_nTamVet - 2]

			// prepara ambiente
			RpcSetEnv(_cCodEmp, _cCodFil,,,,,{"Z46", "SA1", "AKD", "CT4", "CTI"})
			
			// Monta query para buscar os itens
			_cQrySC1 := "SELECT C1_FILIAL, C1_NUM, C1_ITEMCTA, Case When DCD_NOMFUN IS NULL Then 'Cadastrar ID no WMS: '+C1_USER Else DCD_NOMFUN End as Nome, C1_DATPRF, C1_CC, C1_PRODUTO, C1_DESCRI, C1_ZINFADI, C1_OBS, C1_QUANT  FROM "+RetSqlName("SC1")+" SC1 (nolock) "
			_cQrySC1 += " Left join "+RetSqlName("DCD")+" DCD (nolock) "
			_cQrySC1 += " on DCD.D_E_L_E_T_ = '' "
			_cQrySC1 += " and DCD_CODFUN = C1_USER "
			// filtro padrao
			_cQrySC1 += "WHERE SC1.D_E_L_E_T_ = '' "
			// Número da solicitação
			_cQrySC1 += "AND C1_PEDIDO = '' AND C1_DATPRF > '20131001' "
			// Código do item contábil
			_cQrySC1 += "GROUP BY C1_FILIAL, C1_NUM, C1_ITEMCTA, DCD_NOMFUN, C1_USER, C1_DATPRF, C1_CC, C1_PRODUTO, C1_DESCRI, C1_ZINFADI, C1_OBS, C1_QUANT "
			// Código do item contábil
			_cQrySC1 += "ORDER BY C1_FILIAL, C1_DATPRF, C1_NUM "
			// Gera array para trabalho
			_aTmpRecno := U_SqlToVet(_cQrySC1)

			// Verifica se ha itens a processar
			If (Len(_aTmpRecno) > 0)

				// Monta corpo do E-mail
				_cHtml := '<html><style> '
				_cHtml += '.topo { font-family: Tahoma; font-size: 20px; font-weight: bold; color: #1B5A8F; } '
				_cHtml += '.cabec { font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF; } '
				_cHtml += '.item { font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;} '
				_cHtml += '.dados_solic { font-family: Tahoma; font-size: 12px; } '
				_cHtml += '.rodape { font-family: Tahoma; font-size: 11px; background-color: #FFFFFF; color: #000000;} '
				_cHtml += '</style>'

				_cHtml +='<body> '
				_cHtml +='  	<tr> '
				_cHtml +=' 		<td> '
				_cHtml +='<table border="0" width="400px" align="center"> '
				_cHtml +='  	<tr> '
				_cHtml +='<td align="center" width="40%"> '
				_cHtml +='		<img src="http://tecadi.com.br/images/res/logo.png"></img> '
				_cHtml +='</td> '
				_cHtml +='<td align="center" width="60%" style="font-family: Tahoma; font-size: 20px; font-weight: bold; color: #1B5A8F;"> '

				_cHtml +='LISTA DE SOLICITAÇÕES DE COMPRA PENDENTES</td></tr></table> '

				_cHtml +='<br> '
				_cHtml +='<table border="1" width="780" cellpadding="3" cellspacing="0" align="center"> '
				_cHtml +='	<tr><td height="30" colspan="7" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">RELAÇÃO DOS SOLICITAÇÕES DE COMPRA</td></tr> '

				_cHtml += '  <tr> '
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="05">Filial</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="05">Número</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="10">Necessidade</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="30">Centro de Custo</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="30">Item contábil</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="10">Usuário</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="10">Quantidade</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="10">Produto</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="10">Descrição</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="10">Informação</td>'
				_cHtml += '    <td style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" width="10">Observação</td>'

				_cHtml += '  </tr>'

				// varre todos os itens da solicitacao
				For _nTmpRecno := 1 to Len(_aTmpRecno)
					_cCodcc	:=	_aTmpRecno[_nTmpRecno][6]+" - "+Posicione("CTT",1,XFILIAL("CTT")+_aTmpRecno[_nTmpRecno][6],"CTT_DESC01")
					_cCodIc	:=	_aTmpRecno[_nTmpRecno][3]+" - "+Posicione("CTD",1,XFILIAL("CTD")+_aTmpRecno[_nTmpRecno][3],"CTD_DESC01")
					_cHtml +='  <tr> '
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="02" align="center">'+_aTmpRecno[_nTmpRecno][1]+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="04" >'+AllTrim(_aTmpRecno[_nTmpRecno][2])+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="10">'+dtoc(Stod(_aTmpRecno[_nTmpRecno][5]))+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="15">'+AllTrim(_cCodCc)+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="15" >'+AllTrim(_cCodIc)+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="10" >'+AllTrim(_aTmpRecno[_nTmpRecno][4])+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="10" align="right">'+TransForm(_aTmpRecno[_nTmpRecno][11],PesqPict("SC1","C1_QUANT"))+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="02" >'+AllTrim(_aTmpRecno[_nTmpRecno][7])+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="04" >'+AllTrim(_aTmpRecno[_nTmpRecno][8])+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="15" >'+AllTrim(_aTmpRecno[_nTmpRecno][9])+'</td>'
					_cHtml +='    <td style="font-family: Tahoma; font-size: 12px; background-color: #FFFFFF; color: #000000;" width="15" >'+AllTrim(_aTmpRecno[_nTmpRecno][10])+'</td>'
					_cHtml +='  </tr> '

					// proximo item
				Next _nTmpRecno

				// rodape do e-mail
				_cHtml +='</table> '

				_cHtml +='</br>'
				_cHtml +='<hr width="80%" noshade="noshade" align="center">'
				_cHtml +='<div align="center"><span style="font-family: Tahoma; font-size: 11px; background-color: #FFFFFF; color: #000000;">Não responda este E-mail - Mensagem automática utilizando o serviço de Workflow TECADI - Proudly Made by TECADI Technology</span> </div>'
				_cHtml +='  </td>'
				_cHtml +='  </tr>'
				_cHtml +='</table>'
				_cHtml +='</body> '
				_cHtml +='</html> '

				// envia o Email
				U_FtMail(_cHtml,"Solicitações de Compra Pendentes",SuperGetMV("TC_MAILPES",,"suporte@tecadi.com.br"))

			EndIf

			// limpa qualquer ambiente
			RpcClearEnv()

		EndIf
	EndIf

Return


// ** funcao que retornar todos os centros de custos da solicitacao
Static Function sfRetCC(mvNumSol)
	local _cQuery
	local _aTmpDados
	local _nX
	// variavel de retorno
	local _cRet := ""

	_cQuery := "SELECT DISTINCT RTRIM(C1_CC)+'-'+RTRIM(CTT_DESC01) DSC_CUSTO "
	// solicitacoes de compras
	_cQuery += "FROM "+RetSqlName("SC1")+" SC1 (nolock) "
	// cad. centro de custo
	_cQuery += "INNER JOIN "+RetSqlName("CTT")+" CTT (nolock) ON CTT_CUSTO = C1_CC "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SC1")+" "
	// filtro pela solicitacao
	_cQuery += "AND C1_NUM = '"+mvNumSol+"' "

	// retorna os dados para o vetor
	_aTmpDados := U_SqlToVet(_cQuery)

	For _nX := 1 to Len(_aTmpDados)
		_cRet += If(Empty(_cRet),"","<br>&nbsp;")+_aTmpDados[_nX]
	Next _nX

Return(_cRet)




/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina que valida se usuário pode fazer solicitações de !
!                  ! compras de COMPRAS TECADI                               !
+------------------+---------------------------------------------------------+
!Autor             ! Odair                                                   !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 09/2013                                                 !
+------------------+--------------------------------------------------------*/

User Function FTCOM01A()

	Local _cQryPesCv := ""
	// variavel de retorno
	Local _lRet := .f.
	//variavel que captura codigo do usuario
	Local _cUserSc := Alltrim(__cUserID)

	// monta a query para verificar se usuario pode criar solicitacoes de compra
	_cQryPesCv := "SELECT Z26_CODUSU "
	// itens da ordem de servico
	_cQryPesCv += "FROM "+RetSqlName("Z26")+" Z26 "
	// insere o filtro padrao de filial
	_cQryPesCv += "WHERE  "+RetSqlCond("Z26")+" "
	// insere o filtro padrao de filial
	_cQryPesCv += "AND Z26_CODUSU = '"+Subs(_cUserSC,1,6)+"' "
	// insere o filtro padrao de filial
	_cQryPesCv += "AND Z26_MSBLQL <> '1' "

	memowrit("c:\query\FTCOM01A.txt",_cQryPesCv)
	If (Select("_QRYZ26")<>0)
		dbSelectArea("_QRYZ26")
		dbCloseArea()
	EndIf
	DbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQryPesCv),"_QRYZ26",.F.,.F.)
	dbSelectArea("_QRYZ26")
	// posiciona no primeiro registro
	dbSelectArea("_QRYZ26")
	_QRYZ26->(dbGoTop())
	// valida se tem dados
	_lRet := _QRYZ26->(!Eof())

Return( _lRet )


/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Verifica o nível do usuário                             !
+------------------+---------------------------------------------------------+
!Autor             ! Odair                                                   !
+------------------+---------------------------------------------------------+
!Parâmetro         ! vazio()                                                 !
+------------------+---------------------------------------------------------+
!Retorno           ! CARACTER - Codigo do Nivel                              !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 10/2013                                                 !
+------------------+--------------------------------------------------------*/

User function FTCOM06A(mvCodUsrSol, mvDtRef)
	// query
	Local _cQryPesCv := ""

	// variavel nivel do usuário
	Local _cNivUsrSol := CriaVar("Z26_NIVEL", .f.)

	// em branco , data atual
	default mvDtRef := dDataBase

	//Somente lista usuário superior da alçada.
	_cQryPesCv := "SELECT Z26_NIVEL "
	// seleciona tabela de perfis
	_cQryPesCv += "FROM "+RetSqlName("Z26")+" Z26 "
	// insere o filtro padrao de filial
	_cQryPesCv += "WHERE  "+RetSqlCond("Z26")+" "
	// posiciona o usuário logado com o registro do perfil
	_cQryPesCv += "AND Z26_CODUSU = '"+mvCodUsrSol+"' "
	// somente registros desbloqueados
	_cQryPesCv += "AND Z26_MSBLQL <> '1' "
	// qual calendario
	_cQryPesCv += "AND Z26_CALEND = '"+StrZero(Year(mvDtRef),4)+"' "
	// somente registros desbloqueados
	_cQryPesCv += "ORDER BY Z26_NIVEL  "

	memowrit("c:\query\FTCOM06A.txt",_cQryPesCv)

	// atualiza variavel de retorno
	_cNivUsrSol := U_FtQuery(_cQryPesCv)

Return( _cNivUsrSol )


/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Consulta e retorna limite ou saldo para operação        !
+------------------+---------------------------------------------------------+
!Autor             ! Odair                                                   !
+------------------+---------------------------------------------------------+
!Parâmetro         ! Nr pedido de compra SC7                                 !
+------------------+---------------------------------------------------------+
!Retorno           ! Numérico - SALDO                                        !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 11/2013                                                 !
+------------------+--------------------------------------------------------*/

User Function FTCOM08A(mvUsrSolic, mvNivUsrSol, mvTipoInf, mvCenCusto, mvItemCtbl, mvDataRef)
	// area inicial
	Local aArea	:= GetArea()
	Local _cQryPesCv := ""
	// variavel de retorno
	Local _lRet := .f.
	// variavel para Saldo ou limite
	Local _nValRef := 0
	// variavel para totalizador do mes para centro de custo e item contábil
	Local _nTotMes := 0
	// variavel para obter o limite da alçada cadastrada
	Local _nLimAlc := 0

	// limite da alçada
	if	( ! Empty(mvItemCtbl) .and. ! Empty(mvCenCusto) )
		_cQryPesCv := "SELECT Z27_LIMITE LIMITE "
	Else
		_cQryPesCv := "SELECT SUM(Z27_LIMITE) LIMITE "
	EndIf
	//Seleciona tabela de alçadas
	_cQryPesCv += " FROM "+RetSqlTab("Z26,Z27") "
	//Indica a filial corrente e somente registros não deletados
	_cQryPesCv += " WHERE  "+RetSqlCond("Z26,Z27")
	//Seleciona o centro de custo
	if	( ! Empty(mvCenCusto) )
		_cQryPesCv += " AND Z27_CC = '"+mvCenCusto+"' "
	EndIf
	//Seleciona o Item Contábil
	if	( ! Empty(mvItemCtbl) )
		_cQryPesCv += " AND Z27_ITEMC = '"+mvItemCtbl+"' "
	EndIf
	//somente registro ativos
	_cQryPesCv += " AND Z27_MSBLQL <> '1' AND Z26_MSBLQL <> '1' "
	//codigo do usuário solicitante
	if	( ! Empty(mvUsrSolic) )
		_cQryPesCv += " AND Z26_CODUSU = '"+mvUsrSolic+"' "
	EndIf
	// qual calendario
	_cQryPesCv += " AND Z26_CALEND = '"+SubStr(DtoS(mvDataRef),1,4)+"' "
	// Equipara calendario
	_cQryPesCv += " AND Z26_CALEND = Z27_CALEND "
	// nivel do usuario
	if	( ! Empty(mvNivUsrSol) )
		_cQryPesCv += " AND Z26_NIVEL = '"+mvNivUsrSol+"' "
	EndIf
	//Compara id do perfil
	_cQryPesCv += " AND Z27_PERFIL = Z26_PERFID "
	//Verifica o tipo de periodicidade do limite, anual, mensal, diária
	_cQryPesCv += " AND SUBSTRING(Z27_DATAIN,1,6) = '"+SubStr(DtoS(mvDataRef),1,6)+"' "

	memowrit("c:\query\FTCOM008A.txt",_cQryPesCv)

	If (Select("_QRYZ26G")<>0)
		dbSelectArea("_QRYZ26G")
		dbCloseArea()
	EndIf
	DbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQryPesCv),"_QRYZ26G",.F.,.F.)
	dbSelectArea("_QRYZ26G")

	// posiciona no primeiro registro
	_QRYZ26G->(dbGoTop())
	// valida se possui dados
	_lRet := _QRYZ26G->(!Eof())
	IF ( _lRet )
		_nLimAlc := _QRYZ26G->LIMITE
	Else
		_nLimAlc := 0
	EndIf

	//Se parâmetro recebido é S=Saldo, calcula e retorna saldo
	if	( mvTipoInf == "S" )
		// Emerson - EAP 11/2015 alterada chamada para inserir a data de analise,
		_nTotMes := U_FTVALPC(mvCenCusto, mvItemCtbl, mvDataRef)
	EndIf

	if	( _lRet )
		//Reduz do limite, o valor total utilizado no mês.
		_nValRef := _nLimAlc - _nTotMes
	Else
		_nValRef := 0
	EndIf

	if	( _nValRef < 0 )
		_nValRef := 0
	EndIf

	//Fechamento da tabela
	dbSelectArea("_QRYZ26G")
	dbCloseArea()

	RestArea(aArea)

Return( _nValRef )

//-- Retorna Codigo do Perfil do Cadastro de Alçadas
User Function FtComAlcada(mvCentroCus, mvItContab, mvDatRef, mvCodUser)

	// objetos da tela
	local _oWndOpcAlc, _oPnlCabec
	local _oBmpBtnOk
	local _oBrwOpcAlc

	// controle de confirmacao da tela
	local _lTelaOk := .f.

	// query
	local _cQuery
	// variaveis do browse
	local _aHeadBrw := {}
	// vetor com os dados
	local _aOpcoesAlc := {}

	// retorna o RECNO
	local _nRecnoZ26 := 0

	// variavel de retorno (codigo da alcada)
	local _cRetCodAlc := CriaVar("Z26_PERFID",.f.)

	// parametros recebidos na funcao
	Default mvCentroCus := CriaVar("CTT_CUSTO",.f.)
	Default mvItContab  := CriaVar("CTD_ITEM",.f.)
	Default mvDatRef    := Date()
	Default mvCodUser   := __cUserId

	// detalhes do cadastro de alcadas
	_cQuery := "SELECT Z26_PERFID, Z26_SETOR, Z26_NIVEL, Z26.R_E_C_N_O_ Z26RECNO, '.F.' IT_DEL " "
	// cad. de alcadas
	_cQuery += "FROM "+RetSqlName("Z26")+" Z26 (nolock) "

	// cad. de itens da alcada
	_cQuery += "INNER JOIN "+RetSqlName("Z27")+" Z27 (nolock) ON "+RetSqlCond("Z27")+" AND Z27_CALEND = Z26_CALEND "
	// codigo do perfil
	_cQuery += "AND Z27_PERFIL = Z26_PERFID "
	// centro de custo
	_cQuery += "AND Z27_CC = '"+mvCentroCus+"' "
	// item contabil
	_cQuery += "AND Z27_ITEMC = '"+mvItContab+"' "
	// periodo
	_cQuery += "AND '"+DtoS(mvDatRef)+"' BETWEEN Z27_DATAIN AND Z27_DATAFM "

	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("Z26")+" "
	// calendarios
	_cQuery += "AND Z26_CALEND = '"+SubStr(DtoS(mvDatRef),1,4)+"' ""
	// codigo do usuario solicitante
	_cQuery += "AND Z26_CODUSU = '"+mvCodUser+"'
	// sem ser bloqueado
	_cQuery += "AND Z26_MSBLQL <> '1' "
	// ordem dos dados
	_cQuery += "ORDER BY Z26_NIVEL "

	memowrit("c:\query\tcomxfun_ftcomalcada.txt",_cQuery)

	// alimenta array conforme resultado do select
	_aOpcoesAlc := U_SqlToVet(_cQuery)

	// caso não encontre amarracoes
	If (Len(_aOpcoesAlc) == 0)
		Aviso("Tecadi: TCOMXFUN","Não há cadastro de alçadas disponíveis para o centro de custo "+AllTrim(mvCentroCus)+", item contábil "+AllTrim(mvItContab)+" e usuário "+AllTrim(UsrFullName(mvCodUser)),{"OK"})

	ElseIf (Len(_aOpcoesAlc) == 1)
		// posiciona no registro do cadastro de alcada
		dbSelectArea("Z26")
		Z26->(dbGoTo( _aOpcoesAlc[1][4] ))

		// atualiza variavel de retorno
		_cRetCodAlc := Z26->Z26_PERFID

	ElseIf (Len(_aOpcoesAlc) > 1)
		// define todos os campos do header
		aAdd(_aHeadBrw,{"Código", "Z26_PERFID", "", TamSx3("Z26_PERFID")[1], 0, Nil, Nil, "C", Nil, "R",,,".F." })
		aAdd(_aHeadBrw,{"Setor" , "Z26_SETOR" , "", TamSx3("Z26_SETOR")[1] , 0, Nil, Nil, "C", Nil, "R",,,".F." })
		aAdd(_aHeadBrw,{"Nível" , "Z26_NIVEL" , "", TamSx3("Z26_NIVEL")[1] , 0, Nil, Nil, "C", Nil, "R",,,".F." })
		aAdd(_aHeadBrw,{"Recno" , "Z26RECNO"  , "", 10                     , 0, Nil, Nil, "N", Nil, "R",,,".F." })

		// monta o dialogo
		_oWndOpcAlc := MSDialog():New(000,000,400,660,"Opções de Perfil no Cadastro de Alçada",,,.F.,,,,,,.T.,,,.T. )
		_oWndOpcAlc:lEscClose := .F.

		// cria o panel do cabecalho - botoes
		_oPnlCabec := TPanel():New(000,000,nil,_oWndOpcAlc,,.F.,.F.,,,022,022,.T.,.F. )
		_oPnlCabec:Align:= CONTROL_ALIGN_TOP

		// -- CONFIRMACAO
		_oBmpBtnOk := TBtnBmp2():New(000,000,030,022,"OK",,,,{|| _lTelaOk := .t., _nRecnoZ26 := _oBrwOpcAlc:aCols[_oBrwOpcAlc:nAt][Len(_oBrwOpcAlc:aHeader)], _oWndOpcAlc:End() },_oPnlCabec,"Ok",,.T.)
		_oBmpBtnOk:Align := CONTROL_ALIGN_LEFT

		// monta o browse com as opcoes de perfil do cadastro de alcada
		_oBrwOpcAlc := MsNewGetDados():New(000,000,400,400,NIL,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aOpcoesAlc),'AllwaysTrue()','','AllwaysTrue()',_oWndOpcAlc,_aHeadBrw,_aOpcoesAlc)
		_oBrwOpcAlc:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// ativa o dialogo
		_oWndOpcAlc:Activate(,,,.T.,{|| _lTelaOk },,)

		// posiciona no registro da conta contabil
		dbSelectArea("Z26")
		Z26->(dbGoTo( _nRecnoZ26 ))

		// atualiza variavel de retorno
		_cRetCodAlc := Z26->Z26_PERFID

	EndIf

Return(_cRetCodAlc)


// ** Total do mês corrente de solicitações de compras
//Emerson - EAP 11/2015 CriaDA Funcao Para analise de Solicitacão
//Seleciona a tabela SC1 - Solicitacaode compra
User Function FTvalSC( _cCeCsto, _cItemCtbl, _cAlacada, _cConSc,_dDtBase)

	Local _cQryPesSC 	:= ""
	Local aArea	:= GetArea()

	//Se passar em branco , data atual
	default _dDtBase := ddtabase

	// Seleciona os campos para montagem de array de Informacao da SC ou para totalização de SC sem PC dentro do mês
	_cQryPesSC := "SELECT SUM(C1_ZTOTAL) TOTAL "
	//Seleciona a tabela SC1 - Solicitacaode compra
	_cQryPesSC += "FROM "+RetSqlName("SC1")+" SC1 "
	//Indica a filial corrente e somente registros não deletados
	_cQryPesSC += "WHERE  "+RetSqlCond("SC1")+"  "
	//Se a consulta não trouxe um numero de pedido especifico para consulta, então deve ter enviado o Centro de custo, item e usuário
	//O item contábil específico
	_cQryPesSC += "AND C1_ITEMCTA = '"+_cItemCtbl+"' "
	//O centro de custo específico
	_cQryPesSC += "AND C1_CC = '"+_cCeCsto+"' "
	//Compara o usuário e sua alcada
	_cQryPesSC += "AND C1_ZIDALCA = '"+_cAlacada+"' "
	//Filtra somente itens de SCs Não Entregues,se já IGNORA,Pois estará no total de PC
	_cQryPesSC += "AND C1_PEDIDO =  ' ' "
	//nao considero o numero DA SC em analise, pois se for alteração pode duplicar o valor da analise.
	if	( !Empty(_cConSc) )
		_cQryPesSC += "AND C1_NUM <>  '"+_cConSc+"' "
	EndIf
	//_data de Previsao de entrega via parametro "
	_cQryPesSC += "AND (SUBSTRING(C1_DATPRF,1,6) = '"+SUBS(dtos(_dDtBase),1,6)+"' )  "
	//Grava arquivo TXT com sql gerada
	MemoWrit("c:\query\FTVALSC1_Total_Mes.txt",_cQryPesSC)
	//Converte em array devolvendo para rotina chamadora

	If (Select("_QRYSC1G")<>0)
		dbSelectArea("_QRYSC1G")
		dbCloseArea()
	EndIf
	DbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQryPesSC),"_QRYSC1G",.F.,.F.)
	dbSelectArea("_QRYSC1G")
	// posiciona no primeiro registro
	_QRYSC1G->(dbGoTop())
	_lRet := _QRYSC1G->(!Eof())
	//Caso verdadeiro carrega a variável
	IF	 ( _lRet )
		_nTotMes := _QRYSC1G->TOTAL
	Else
		_nTotMes := 0
	EndIf

	//Fechamento da tabela
	dbSelectArea("_QRYSC1G")
	dbCloseArea()

	//Retorna o total do mês corrente
Return ( _nTotMes )

//Emerson EAP Tecnologia - 11/2015
//Busca a alçada superior com saldo para amarrar nivel e superior do usuario atual
//centro de custo,itemcontabil, data base,Valor PC/SC

Static Function sfVldSup(_cCenCusto, _cItemCtbl, _dDtaBase, _nValpcsc, _cUserSC, _cPcScnum)

	// codigo do usuario
	local _cIdUsuario := ""
	local _cIdPerfil  := ""  // codigo do perfil
	Local _cNomeGeren := ""  // nome do gerente
	//codigo do superior
	local _cIdSuper   := U_FtComAlcada(_cCenCusto, _cItemCtbl, _dDtaBase, _cUserSC)
	local _cSetor     := ""  // SETOR
	local _nTotAprov  := 0   // valor aprovado

	// loop para buscar dados
	local _lBusSupe   := .t.

	// dados da alcada superior
	local _aRetAlcSup := {}

	// variaveis temporarias
	Local _aTmpRecno := {}

	// pode vir vazio ai analisa todos
	default _cPcScnum:= ' '

	// TOTAL PC já aprovado dentro do MES DE REFERENFICA
	_nTotAprov := U_FTVALPC(_cCenCusto, _cItemCtbl, _dDtaBase, _cPcScnum)

	//soma com o valor atual da SC/PC
	_nTotAprov += _nValPcSc

	//enquanto não for verdadeiro é pq não achou ainda
	Do While ( _lBusSupe )

		// monta a query para verificar se usuario tem superior,caso não sera ele
		_cQryPesCv := " SELECT Z26.R_E_C_N_O_ Z26RECNO "
		// cad. de alcadas
		_cQryPesCv += " FROM "+RetSqlTab("Z26")+" (nolock) "

		// cad. de itens da alcada
		_cQryPesCv += " INNER JOIN "+RetSqlTab("Z27")+" (nolock) ON "+RetSqlCond("Z27")+" AND Z27_CALEND = Z26_CALEND "
		// codigo do perfil
		_cQryPesCv += " AND Z27_PERFIL = Z26_PERFID "
		// centro de custo
		_cQryPesCv += " AND Z27_CC = '"+_cCenCusto+"' "
		// item contabil
		_cQryPesCv += " AND Z27_ITEMC = '"+_cItemCtbl+"' "
		// periodo
		_cQryPesCv += " AND '"+DtoS(_dDtaBase)+"' BETWEEN Z27_DATAIN AND Z27_DATAFM "

		// filtro padrao
		_cQryPesCv += " WHERE "+RetSqlCond("Z26")
		// calendarios
		_cQryPesCv += " AND Z26_CALEND = '"+SubStr(DtoS(_dDtaBase),1,4)+"' ""
		// codigo do perfil superior
		_cQryPesCv += " AND Z26_PERFID  = '"+_cIdSuper+"' "
		///sem ser bloqueado
		_cQryPesCv += " AND Z26_MSBLQL <> '1' "

		memowrit("c:\query\sfVldSup"+_cIdSuper+".txt",_cQryPesCv)

		// atualiza vetor temporario
		_aTmpRecno := U_SqlToVet(_cQryPesCv)

		// verifica se ha itens a processar
		If (Len(_aTmpRecno) > 0)
			// posiciona no registro real da tabela
			dbSelectArea("Z26")
			Z26->(dbGoTo(_aTmpRecno[1]))

			// atualiza variaveis de controle
			_cIdUsuario := Z26->Z26_CODUSU
			_cIdPerfil  := Z26->Z26_PERFID // Codigo do Perfil do Cadastro de Alçadas
			_cIdSuper   := Z26->Z26_PERSUP
			_cNomeGeren := Z26->Z26_GERENT
			_cSetor     := Z26->Z26_SETOR
			_cNivUsCo 	:= Z26->Z26_NIVEL  // Nível do usuário

		Else //NAO ACHOU ??
			_cNomeGeren := 'SEM ALCADA SUPERIOR'
			_cIdUsuario := 'SEMALC'
			_cIdPerfil  := 'SEMALC'
			_cNivUsCo  	:= 'X'
			_lBusSupe   := .f.
			Exit
		Endif

		// limite do Aprovador em analise MES DE REFERENCIA
		_nVlrSld := U_FTCOM08A(_cIdUsuario, _cNivUsCo, "L", _cCenCusto, _cItemCtbl, _dDtaBase)

		//se o valor do Saldo menos o aprovado+SC, MENOR QUE ZERO  para o usuario SOLICITANTE É O APROVADOR
		_lBusSupe := IIf(_nVlrSLd - _nTotAprov  < 0, .t., .f.)

		// se for usuario nivel "A" Força a saida / ou sem superrior
		IF ((_lBusSupe).and.(_cNivUsCo == 'A')).or.(Empty(_cIdSuper))
			_lBusSupe := .f.
		Endif
	End DO

	// atualiza vetor de retorno
	aAdd(_aRetAlcSup,{_cIdUsuario, _cIdPerfil, _cNivUsCo, _cNomeGeren, _cSetor})

Return(_aRetAlcSup)

//busca o id da alçada para impressão de dados
USER FUNCTION FTALCID(_cAlcada,_cCC,_cItemc,_dDtaBase,lName)

	//Posiciona na tabela de ALCADAS SUPERIOR,RETIRADA DA FUNCAO FTCOMALCADA
	// monta a query para verificar se usuario tem superior,caso não sera ele
	_cQryPesCv := "SELECT Z26.R_E_C_N_O_  Z26RECNO "
	// cad. de alcadas
	_cQryPesCv += "FROM "+RetSqlName("Z26")+" Z26 (nolock)  "
	// cad. de itens da alcada
	_cQryPesCv += "INNER JOIN "+RetSqlName("Z27")+" Z27 (nolock)  ON "+RetSqlCond("Z27")+" AND Z27_CALEND = Z26_CALEND "
	// codigo do perfil
	_cQryPesCv += "AND Z27_PERFIL = Z26_PERFID "
	// centro de custo
	_cQryPesCv += "AND Z27_CC = '"+_cCC+"' "
	// item contabil
	_cQryPesCv += "AND Z27_ITEMC = '"+_cItemC+"' "
	// periodo
	_cQryPesCv += "AND '"+DtoS(_dDtaBase)+"' BETWEEN Z27_DATAIN AND Z27_DATAFM "
	// filtro padrao
	_cQryPesCv += "WHERE "+RetSqlCond("Z26")+" "
	// calendarios
	_cQryPesCv += "AND Z26_CALEND = '"+SubStr(DtoS(_dDtaBase),1,4)+"' ""
	// codigo do alcada do usuario
	_cQryPesCv += "AND Z26_PERFID  = '"+_cAlcada+"' " //CODIGO DO PERFIL
	// sem ser bloqueado
	_cQryPesCv += "AND Z26_MSBLQL <> '1' "

	memowrit("c:\query\FTALCID.txt",_cQryPesCv)

	_aTmpRecno := U_SqlToVet(_cQryPesCv)

	// verifica se ha itens a processar
	If (Len(_aTmpRecno) > 0)
		// posiciona no registro real da tabela
		dbSelectArea("Z26")
		Z26->(dbGoTo(_aTmpRecno[1]))
		_cIduSuario :=  IIF(lName,UsrFullName(Z26->Z26_CODUSU),Z26->Z26_CODUSU)
		_cPerfuso 	:=  Z26->Z26_PERFID
		_cPerfSUP   :=  Z26->Z26_PERSUP
		_cNomeGeren :=  Z26->Z26_GERENT
		_cSetor     :=  Z26->Z26_SETOR
		_cPerfuso 	:=  Z26->Z26_PERFID 	//-- Codigo do Perfil do Cadastro de Alçadas
		_cNivUsCo 	:=  Z26->Z26_NIVEL //Verifica o nível do usuário
	Else //NAO ACHOU ??
		_cNomeGeren :=  'SEM ALCADA SUPERIOR'
		_cIduSuario :=  'SEMALC'
		_cPerfuso   :=  'SEMALC'
	Endif
Return(_cIduSuario)


//EMERSON - EAP TECNOLOGIA 11/2015
//Funcao para demonstrar resumo dados do PC/SC
//antes de gravar
//CHAMADA NAS FUNCOES MT110TOK() -- SC / MT120OK -- PC

user Function FTMORPC(mvTpPcSc, _aCCSld, _cUser, mvPcScNum, mvRetDados, mvDadosRet)

	// area atual
	Local _aAreaAtu := GetArea()

	local _aHoBrwCC	 := {}   //CENTRO CUSTO
	local _aHoBrwSUP := {}   //SUPERIOR POR CC
	Local _oFont1    := TFont():New( "MS Sans Serif",0,-11,,.T.,0,,700,.F.,.F.,,,,,, )

	Local _oBrwCC //browse cc
	Local _oBrwSU //browse usu

	Local _oSBtno  //botao
	Local _oSBtnC  //botao
	Local _aCores := {}

	Local _ctext := ""

	// objetos da tela
	local _oBmpOk, _oBmpRec
	local _oSayOk, _oSayRec, _oSayTitCC, _oSayTitSup
	Local _oBtnExtrato
	Local _oBrwAlcSup

	PRIVATE _aHoBrwCC:={}  //browse principal resumido
	PRIVATE _aCoBrwCC:={}
	PRIVATE _aTabCC:={}  //browse CC com dados
	PRIVATE _aTabCC:={}  //browse GERENTE com dados
	//Tabela das scs
	Private _cTabSC := GetNextAlias()
	//Tabela dos PCS
	Private _cTabPC := GetNextAlias()
	//tabela CC
	Private _cTabCC
	//TABELA SUP
	Private _cTabSUP
	//Tabela das alçadas
	Private _aLisSc := {}  //array com os dados da SCPC
	Private _oVermelho := LoadBitMap(GetResources(), "BR_VERMELHO") // excedido
	Private _oVerde    := LoadBitMap(GetResources(), "BR_VERDE")    // liberados
	Private _oBranco   := LoadBitMap(GetResources(), "BR_BRANCO")   // limite
	Private _oAzul     := LoadBitMap(GetResources(), "BR_AZUL")     // bloqueados
	Private _oPreto    := LoadBitMap(GetResources(), "BR_PRETO")    // atual
	Private _oStaCl

	Private _lcontinua := .F.  //controle de saida ou não
	Private _oDlgCC  //dialogo
	// Alias da area de trabalho Cntro custo
	Private _cAliasCC:= "CCTRB"
	// Fecha area de trabalho
	Private _cAliasSUP:= "CCSUP"

	// valores padrao
	Default mvPcScNum  := ' '
	Default mvRetDados := .f.
	Default mvDadosRet := {}

	If Select(_cAliasCC) <> 0
		(_cAliasCC)->(dbCloseArea())
	EndIf
	If Select(_cAliasSUP) <> 0
		(_cAliasSUP)->(dbCloseArea())
	EndIf

	// cores da legenda
	aAdd(_aCores,{"CCTRB->T_OK  == 'Y'","BR_VERDE"})
	aAdd(_aCores,{"CCTRB->T_OK  == 'X'","BR_VERMELHO"})

	// browse centro de custo
	Aadd(_aHoBrwCC,{"T_CODCC" ,,"Centro Custo"  ,'@!'})
	Aadd(_aHoBrwCC,{"T_ITCTA" ,,"Item Cta"      ,'@!'})
	Aadd(_aHoBrwCC,{"T_DATREF",,"Periodo"       ,'@!'})
	Aadd(_aHoBrwCC,{"T_ORCADO",,"Orcamento"     ,PesqPict("SC1","C1_ZTOTAL")})
	Aadd(_aHoBrwCC,{"T_SLDPC" ,,"Pedidos Aprov.",PesqPict("SC1","C1_ZTOTAL")})
	IF (mvTpPcSc == 'SC')
		Aadd(_aHoBrwCC,{"T_SLDSC",,"Solicitacoes",PesqPict("SC1","C1_ZTOTAL")}) //somente na CC
	Endif
	Aadd(_aHoBrwCC,{"T_SLDSCA" ,,"Atual"             ,PesqPict("SC1","C1_ZTOTAL")})
	Aadd(_aHoBrwCC,{"T_VLREXC" ,,"Excedido"          ,PesqPict("SC1","C1_ZTOTAL")})
	Aadd(_aHoBrwCC,{"T_VLRSLD" ,,"Saldo"             ,PesqPict("SC1","C1_ZTOTAL")})
	Aadd(_aHoBrwCC,{"T_DESCC"  ,,"Descr Centro Custo",'@!'})
	Aadd(_aHoBrwCC,{"T_DESCCTA",,"Descr It Conta"    ,'@!'})
	Aadd(_aHoBrwCC,{"T_ALCADA" ,,"Alçada usuario"    ,'@!'})

	// browse alcada superior
	Aadd(_aHoBrwSUP,{"S_DATREF",,"Periodo",'@!'})
	Aadd(_aHoBrwSUP,{"S_CODCC" ,,"Centro Custo",'@!'})
	Aadd(_aHoBrwSUP,{"S_ITCTA" ,,"Item Cta",'@!'})
	Aadd(_aHoBrwSUP,{"S_USRSUP",,"Cod. Usuario",'@!'})
	Aadd(_aHoBrwSUP,{"S_PERSUP",,"Perfil ",'@!'})
	Aadd(_aHoBrwSUP,{"S_NIVSUP",,"Nivel",'@!'})
	Aadd(_aHoBrwSUP,{"S_NOMSUP",,"Nome Aprovador",'@!'})
	Aadd(_aHoBrwSUP,{"S_SETSUP",,"Setor",'@!'})

	IF (mvTpPcSc == 'SC')
		_ctext := 'Possível '
	Endif

	// Monta tabela para mostrar em browse
	mBrwCC(_aCCSld, mvTpPcSc)
	// para mostrar os gerentes para aprovaçoes
	mBrwSUP(_aCCSld, mvPcScNum, @mvDadosRet) //Monta tabela para mostrar em browse

	// se for rotina automatica para retornar dados
	If (mvRetDados)
		If Select(_cAliasCC) <> 0
			(_cAliasCC)->(dbCloseArea())
		EndIf
		If Select(_cAliasSUP) <> 0
			(_cAliasSUP)->(dbCloseArea())
		EndIf
		// restaura area atual
		RestArea(_aAreaAtu)
		// retorno da funcao
		_lcontinua := .t.
		// return
		Return(_lcontinua)
	EndIf

	// posiciona no primeiro registro dos arquivos de trabalho
	(_cAliasCC)->(dbGoTop())
	(_cAliasSUP)->(dbGoTop())

	// monta tela com os detalhes
	_oDlgCC := MSDialog():New(142,233,650,1151,"[FTcmSCPC] - Análise de Centro de Custos para Aprovação ",,,.F.,,,,,,.T.,,,.T. )

	// legenda
	_oBmpOk  := TBitmap():New(010,010,020,020,,"BR_VERDE",.T.,_oDlgCC,Nil,,.F.,.F.,,,.F.,,.T.,,.F.)
	_oSayOk  := TSay():New(010,020,{||"Limite Ok"},_oDlgCC,,,.F.,.F.,.F.,.T.,,,070,008)
	_oBmpRec := TBitmap():New(022,010,020,020,,"BR_VERMELHO",.T.,_oDlgCC,Nil,,.F.,.F.,,,.F.,,.T.,,.F.)
	_oSayRec := TSay():New(022,020,{||"Encaminhado para Análise"},_oDlgCC,,,.F.,.F.,.F.,.T.,,,070,008)

	// titulos
	_oSayCC := TSay():New( 016,138,{||"Resumo de Valores Por Centro de Custos x  Valores para Aprovação"},_oDlgCC,,_oFont1,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,300,008)

	// browse com os detallhes do centro de custo
	_oBrwCC := MsSelect():New( _cAliasCC ,"","",_aHoBrwCC,.F.,,{036,004,130,452},,, _oDlgCC,,_acores)
	_oBrwCC:oBrowse:bChange := {|| sfFilSUP((_cAliasCC)->T_CODCC, (_cAliasCC)->T_ITCTA, @_oBrwAlcSup, @_oBrwCC, @_oDlgCC) }

	// detalhes das alcadas superiores
	_oSayTitSup := TSay():New(138,138,{||_cText+"Alçada que ira aprovar  do Pedido de Compras "},_oDlgCC,,_oFont1,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,200,008)

	// browse com os detalhes da alcada superior
	_oBrwAlcSup := MsSelect():New( _cAliasSUP,"","",_aHoBrwSUP,.F.,,{150,004,232,452},,, _oDlgCC )

	// extrato
	_oBtnExtrato := TButton():New(236,054,"Extrato Saldo",_oDlgCC,{|| sfExtSCPC(mvTpPcSc, _cUser, mvPcScNum) },044,012,,,,.T.,,"",,,,.F. )
	_oSBtnok    := SButton():New(236,250,1,{||_lcontinua:=.T.,_oDlgCC:End()},_oDlgCC,,"",)
	_oSBtnCan   := SButton():New(236,300,2,{||_lcontinua:=.F.,_oDlgCC:End()},_oDlgCC,,"",)
	_oDlgCC:Activate(,,,.T.)

	// Fecha area de trabalho
	_cTabCC:Delete()
	_cTabSUP:Delete()

Return(_lcontinua)

// FILTRA APROVADOR DO CC
Static Function sfFilSUP(_cCodcc, _cCodItca, mvBrwAlcSup, _oBrwCC, _oDlgCC)
	// filtra SUPERIOR
	dbSelectArea(_cAliasSUP)
	IndRegua((_cAliasSUP),(_cTabSup),"S_USRSUP",,(_cAliasSUP)+'->S_CODCC == "'+_cCodcc+'" .AND. '+(_cAliasSUP)+'->S_ITCTA  == "'+_cCodItca+'"',"Selecionando Registros...")
	(_cAliasSUP)->(dbGoTop())

	// atualiza browse Centro de Custo
	_oBrwCC:oBrowse:Refresh()
	// atualiza browse Alc Superior
	mvBrwAlcSup:oBrowse:Refresh()
	// atualiza tela
	_oDlgCC:Refresh()

Return

// ** funcao para demonstrar o resultado da analise por Centro de Custo + Item Contabil
Static Function mBrwCC(_aCCSld, mvTpPcSc)

	local  aTam:={}
	local _nPos:=0
	Local _aTabCC:={}
	Local _nValdif:=0

	aTam:= TamSX3("C1_ITEM")
	aAdd(_aTabCC,{"T_OK",aTam[3],1,aTam[2]})
	aTam:= TamSX3("C1_CC")
	aAdd(_aTabCC,{"T_CODCC",aTam[3],aTam[1],aTam[2]})
	aTam:= TamSX3("CTT_DESC01")
	aAdd(_aTabCC,{"T_DESCC",aTam[3],aTam[1],aTam[2]})
	aTam:= TamSX3("CTD_ITEM")
	aAdd(_aTabCC,{"T_ITCTA",aTam[3],aTam[1],aTam[2]})
	aTam := {7,0,"C"}
	aAdd(_aTabCC,{"T_DATREF",aTam[3],aTam[1],aTam[2]})
	aTam:= TamSX3("CTD_DESC01")
	aAdd(_aTabCC,{"T_DESCCTA",aTam[3],aTam[1],aTam[2]})
	aTam:= TamSX3("C1_ZTOTAL")
	aAdd(_aTabCC,{"T_ORCADO",aTam[3],aTam[1],aTam[2]})
	aTam:= TamSX3("C1_ZTOTAL")
	aAdd(_aTabCC,{"T_SLDPC",aTam[3],aTam[1],aTam[2]})
	IF (mvTpPcSc == 'SC')
		aTam:= TamSX3("C1_ZTOTAL")
		aAdd(_aTabCC,{"T_SLDSC",aTam[3],aTam[1],aTam[2]})
	Endif
	aTam:= TamSX3("C1_ZTOTAL")
	aAdd(_aTabCC,{"T_SLDSCA",aTam[3],aTam[1],aTam[2]})
	aTam:= TamSX3("C1_ZTOTAL")
	aAdd(_aTabCC,{"T_VLREXC",aTam[3],aTam[1],aTam[2]})
	aTam:= TamSX3("C1_ZTOTAL")
	aAdd(_aTabCC,{"T_VLRSLD",aTam[3],aTam[1],aTam[2]})
	aTam:= TamSX3("C1_ZIDALCA")
	aAdd(_aTabCC,{"T_ALCADA",aTam[3],aTam[1],aTam[2]})

	If (Select(_cAliasCC)<>0)
		dbSelectArea(_cAliasCC)
		dbCloseArea()
	EndIf
	
	_cTabCC := FWTemporaryTable():New( _cAliasCC )
	_cTabCC:SetFields( _aTabCC )
	_cTabCC:Create()

	For _nPos:= 1 to Len(_aCCSld)

		// estrutura: _aCCSld
		// 1-CC
		// 2-Itemctb
		// 3-Periodo Referencia (ANO + MES)
		// 4-Valor Limite
		// 5-ValorPC Aprovado
		// 6-ValorSC
		// 7-Total PC/SC Atual
		// 8-ID Alcada Usr Solicitante
		// 9-Cod Usr Solicitante
		_nValdif := (_aCCSld[_nPos][5] + _aCCSld[_nPos][6] + _aCCSld[_nPos][7]) - _aCCSld[_nPos][4]

		RecLock(_cAliasCC,.T.)
		T_CODCC   := _aCCSld[_nPos][1]  //codigo do CC
		T_DESCC   := GETADVFVAl("CTT","CTT_DESC01",xFilial("CTT")+_aCCSld[_nPos][1]) //DESC CC
		T_ITCTA   := _aCCSld[_nPos][2]	//CODIGO ITEMCTA
		T_DESCCTA := GETADVFVAl("CTD","CTD_DESC01",xFilial("CTT")+_aCCSld[_nPos][2])  //DESC ITEMCTA
		T_ORCADO  := _aCCSld[_nPos][4]	 //limite
		T_SLDPC   := _aCCSld[_nPos][5]	 //valor pc
		IF (mvTpPcSc == 'SC')
			T_SLDSC := _aCCSld[_nPos][6] //valor sc
		Endif
		T_SLDSCA  := _aCCSld[_nPos][7]	// valor SC ATUAL
		T_VLREXC  := IIf(_nValdif > 0, _nValdif      ,0)  //DIF
		T_VLRSLD  := IIf(_nValdif < 0, (-1)*_nValdif ,0)  //DIF
		T_DATREF  := Substring(_aCCSld[_nPos][3],5,2)+'/'+Substring(_aCCSld[_nPos][3],1,4)
		T_ALCADA  := _aCCSld[_nPos][8] //Alacada
		// X-Excedeu Limite / Y-Limite Ok
		T_OK      := IIf(_nValdif > 0,"X","Y")
		(_cAliasCC)->(MsUnlock())

	Next _nPos

Return

// ** funcao para demonstrar o resultado da analise da alcada superior
Static Function mBrwSUP(_aCCSld, mvPcScNum, mvDadosRet)

	local  aTam := {}
	local _nPos := 0
	Local _aTabCC := {}    //ARRAY para tabela temporaria
	Local _nValdif := 0    //calculos
	Local _aRetAlcSup := {}  //RETORNO DO SUPERIOR
	local  _ddtabase := ddatabase //data gerenciamento

	// ID da Alcada Superior
	local _cIdAlcSup := CriaVar("Z26_PERFID", .f.)

	// pedido/item liberado
	local _cPedLibOk := "S"

	aTam := TamSX3("C1_CC")
	aAdd(_aTabCC,{"S_CODCC",aTam[3],aTam[1],aTam[2]})
	aTam := TamSX3("CTD_ITEM")
	aAdd(_aTabCC,{"S_ITCTA",aTam[3],aTam[1],aTam[2]})
	aTam := TamSX3("Z26_PERSUP")
	aAdd(_aTabCC,{"S_USRSUP",aTam[3],aTam[1],aTam[2]})
	aTam := TamSX3("Z26_PERSUP")
	aAdd(_aTabCC,{"S_PERSUP",aTam[3],aTam[1],aTam[2]})
	aTam := TamSX3("Z26_NIVEL")
	aAdd(_aTabCC,{"S_NIVSUP",aTam[3],aTam[1],aTam[2]})
	aTam := TamSX3("Z26_GERENT")
	aAdd(_aTabCC,{"S_NOMSUP",aTam[3],aTam[1],aTam[2]})
	aTam := {7,0,"C"}
	aAdd(_aTabCC,{"S_DATREF",aTam[3],aTam[1],aTam[2]})
	aTam:= TamSX3("Z26_SETOR")
	aAdd(_aTabCC,{"S_SETSUP",aTam[3],aTam[1],aTam[2]})

	If (Select(_cTabPc)<>0)
		dbSelectArea(_cTabPc)
		dbCloseArea()
	EndIf
	
	_cTabSUP := FWTemporaryTable():New( _cAliasSUP )
	_cTabSUP:SetFields( _aTabCC )
	_cTabSUP:Create()

	For _nPos:= 1 to Len(_aCCSld)

		// zera variaveis
		_cIdAlcSup := Space(Len(_cIdAlcSup))
		_cPedLibOk := "S"

		// estrutura: _aCCSld
		// 1-CC
		// 2-Itemctb
		// 3-Periodo Referencia (ANO + MES)
		// 4-Valor Limite
		// 5-ValorPC Aprovado
		// 6-ValorSC
		// 7-Total PC/SC Atual
		// 8-ID Alcada Usr Solicitante
		// 9-Cod Usr Solicitante
		_nValdif  := (_aCCSld[_nPos][5] + _aCCSld[_nPos][6] + _aCCSld[_nPos][7]) - _aCCSld[_nPos][4]

		// se valor execeu, apresenta superior
		If (_nValdif > 0)

			// data de referencia
			_ddtabase := ctod('01/'+Substring(_aCCSld[_nPos][3],5,2)+'/'+Substring(_aCCSld[_nPos][3],1,4))

			// busca quem ira aprovar o PC
			// parametros
			// 1-CC
			// 2-ITEMCTA
			// 3-DATAREF
			// 4-VALOR EM PEDIDO/SOLICITACAO - PASSAR 0
			// 5-USUARIO SOLICITANTE
			// 6-NUMERO DO PEDIDO
			_aRetAlcSup := sfVldSup(_aCCSld[_nPos][1], _aCCSld[_nPos][2], _ddtabase, _aCCSld[_nPos][7], _aCCSld[_nPos][9], mvPcScNum)

			// inclui o item no arquivo de trabalho
			RecLock(_cAliasSUP,.T.)
			S_DATREF := Substring(_aCCSld[_nPos][3],5,2)+'/'+Substring(_aCCSld[_nPos][3],1,4)
			S_CODCC  := _aCCSld[_nPos][1]  // centro de custo
			S_ITCTA  := _aCCSld[_nPos][2]  // item contabil
			S_USRSUP := _aRetAlcSup[1][1]  // codigo usuario superior
			S_PERSUP := _aRetAlcSup[1][2]  // ID do perfil
			S_NIVSUP := _aRetAlcSup[1][3]  // nivel do perfil
			S_NOMSUP := _aRetAlcSup[1][4]  // nome do responsavel
			S_SETSUP := _aRetAlcSup[1][5]  // setor
			(_cAliasSup)->(MsUnlock())

			// alcada superior
			_cIdAlcSup := (_cAliasSUP)->S_PERSUP

			// pedido enviado para analise
			_cPedLibOk := "N"

		Else
			RecLock(_cAliasSUP,.T.)
			S_CODCC  := _aCCSld[_nPos][1]  // centro de custo
			S_ITCTA  := _aCCSld[_nPos][2]  // item contabil
			S_NOMSUP := "LIMITE OK"        // nome do responsavel
			(_cAliasSup)->(MsUnlock())

		EndIf

		// adiciona os dados no vetor de retorno
		// estrutura
		// 1-CC
		// 2-Item Contabil
		// 3-Valor Limite
		// 4-Saldo PC
		// 5-Saldo SC
		// 6-Periodo Referencia (Mes/Ano)
		// 7-Codigo/ID Alcada Solicitante
		// 8-Aprovado (S-Sim. N-Enviado para superior)
		// 9-ID Alcada Superior
		aAdd(mvDadosRet,{;
		_aCCSld[_nPos][ 1] ,;
		_aCCSld[_nPos][ 2] ,;
		_aCCSld[_nPos][ 4] ,;
		_aCCSld[_nPos][ 5] ,;
		_aCCSld[_nPos][ 6] ,;
		_aCCSld[_nPos][ 3] ,;
		_aCCSld[_nPos][ 8] ,;
		_cPedLibOk         ,;
		_cIdAlcSup         })

	Next _nPos

Return

// ** funcao para apresentar o extrato do controle de alcadas
static Function sfExtSCPC(mvTpPcSc,_cUser,_cPCscNUM)

	Local aArea	:= GetArea()
	Local _aFolders := {}
	local _aSizeDlg := MsAdvSize()
	Local aButtons	:= {}
	Local oListBox
	Local _oFont1
	Local _oBSTe02
	Local _oStaCl
	Local _nI    	:= 0 //VARIAVEL PARA controle de Posicao
	Local _nTotSCA		:= 0 //Vlores  de SC Atual *tela

	//Carrega variáveis principais para localização dos registros
	Local _cCodCc 	    := (_cAliasCC)->T_CODCC   //centro custo
	local _cCodItem 	:= (_cAliasCC)->T_ITCTA   //item contabil
	Local _cDataRef     := substr((_cAliasCC)->T_DATREF,4,4) + substr((_cAliasCC)->T_DATREF,1,2)  //mesanoreferencia
	local _cAlcada   	:= (_cAliasCC)->T_ALCADA   //ALCADA
	local _nOrcado 		:= (_cAliasCC)->T_ORCADO   //limite
	local _nTotPC	    := (_cAliasCC)->T_SLDPC   	 //valor SC
	local _ntotSC		:= if(mvTpPcSc == 'SC',(_cAliasCC)->T_SLDSC,0)   	 //valor PC
	local _nSldSCA		:= (_cAliasCC)->T_SLDSCA  	// valor SC ATUAL
	local _nSldExc		:= (_cAliasCC)->T_VLREXC    //DIF
	local _nSaldo       := (_cAliasCC)->T_ORCADO
	_aLisSC:={}

	//tela de browse
	aAdd(_aLisSC,{"LIM","Orcado","","","","","","",0,0,_nOrcado,"","","","","","","","","",_oBranco,0,"",""})
	//tela do PC
	IF (mvTpPcSc == 'PC')
		Mbrwsc7(_cCodCc,_cCodItem,_cDataRef,_cAlcada,_cUser,_cPCscNUM) //CARREGA DADOS SC7
		aAdd(_aLisSC,{"PCA","PCAtuaL","","","","","","",0,0,_nSldSCA,"","","","","","","","","",Iif(_nSldExc == 0,_oVerde,_oVermelho),0,"",""})
	Endif
	//TELA DA SC
	IF (mvTpPcSc == 'SC')
		Mbrwsc7(_cCodCc,_cCodItem,_cDataRef,_cAlcada,_cUser,' ') //CARREGA DADOS SC7
		Mbrwsc1(_cCodCc,_cCodItem,_cDataRef,_cAlcada,_cUser,_cPCscNUM) //CARREGA DADOS SC1
		aAdd(_aLisSC,{"SCA","SCAtuaL","","","","","","",0,0,_nSldSCA,"","","","","","","","","",if(_nSldExc == 0,_oVerde,_oVermelho),0,"",""})
	Endif

	For _ni:= 1 to len(_aLisSC)
		if _aLisSC[_NI][1] <> 'LIM'
			_nSaldo := _nSaldo - _aLisSC[_NI][11]
		Endif
		_aLisSC[_NI][22]:=_nSaldo
		IF _nSaldo < 0
			_aLisSC[_NI][21]:=_oVermelho
		Endif
	Next _ni


	//Prepara folders
	_aFolders := {"Extrato CC / Item  - "+_cCodCc+' / '+_cCodiTEM}
	_oFont1     	:= TFont():New( "Arial",0,-13,,.F.,0,,400,.F.,.F.,,,,,, )
	_oFont2     	:= TFont():New( "Arial",0,-15,,.F.,0,,400,.F.,.F.,,,,,, )

	DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD
	DEFINE MSDIALOG _oDlgC FROM _aSizeDlg[7],000 TO _aSizeDlg[6],_aSizeDlg[5] TITLE "Extrato de Solicitações e Pedidos de Compra" Of oMainWnd PIXEL

	// pastas (Folders) com as opcoes de visualizacao
	_oFolCo := TFolder():New(080,000,_aFolders,,_oDlgC,,,,.T.,,750,215)
	_oFolCo:Align:= CONTROL_ALIGN_ALLCLIENT

	// painel com o rodape
	_oPnlRd1 := TPanel():New(000,000,nil,_oFolCo:aDialogs[1],,.F.,.F.,,,22,22,.T.,.F. )
	_oPnlRd1 :Align:= CONTROL_ALIGN_BOTTOM


	//Solicitação de Compra e Pedido
	_oLiPC := TWBrowse():New(020,020,500,200,,{" ","Tipo" ,"Saldo", "Documento"  ,"Item" , "Produto" ,"Descrição" ,"UM.","Qtde","Vlr Unit.","Total Item" ,"Necessidade"  ,"Emissão"   ,"Solicitante","Solicitação","Item Solicitação","Fornecedor","Loja" ,"Nome ","Inf.Adicionais","Alçada Resp PC","Alçada Liberou PC"},,_oFolco:aDialogs[1],,,,,,,,/*fore*/,/*back*/,,,.F.,,.T.,,.F.,,,)
	_oLiPC:Align := CONTROL_ALIGN_ALLCLIENT
	_oLiPC:SetArray(_aLisSC)
	_oLiPC:bLine		:= {|| {_aLisSC[_oLiPC:nAT][21],_aLisSC[_oLiPC:nAT][1],Transform(_aLisSC[_oLiPC:nAT][22],"@e 999,999,999.99"),_aLisSC[_oLiPC:nAT][2]    , _aLisSC[_oLipC:nAT][3],_aLisSC[_oLiPC:nAT][4]  ,_aLisSC[_oLiPC:nAT][5],_aLisSC[_oLiPC:nAT][8],Transform(_aLisSC[_oLiPC:nAT][9],"@e 999,999.99"),Transform(_aLisSC[_oLiPC:nAT][10],"@e 9,999,999.99"),Transform(_aLisSC[_oLiPC:nAT][11],"@e 9,999,999.99"),_aLisSC[_oLiPC:nAT][12]  ,_aLisSC[_oLiPC:nAT][13],_aLisSC[_oLiPC:nAT][14],_aLisSC[_oLiPC:nAT][15]    ,_aLisSC[_oLiPC:nAT][16]       ,_aLisSC[_oLiPC:nAT][17],_aLisSC[_oLiPC:nAT][18],_aLisSC[_oLiPC:nAT][19],_aLisSC[_oLiPC:nAT][20],_aLisSC[_oLiPC:nAT][23],_aLisSC[_oLiPC:nAT][24]}}
	_oLiPC:Refresh()
	_oLiPC:bLdblClick := {|| sfVisuPc(_aLisSC[_oLiPC:nAT][21],aLisPc[_oLiPC:nAT][2]) }

	@ 010, 005 Say "Limite : " of _oPnlRd1 PIXEL FONT oBold
	@ 010, 050 MSGET _nOrcado Picture PesqPict("SC7","C7_TOTAL") When .F. of _oPnlRd1 PIXEL SIZE 70,9 FONT oBold
	IF (mvTpPcSc == 'SC')
		@ 010, 150 Say "SCs : " of _oPnlRd1 PIXEL FONT oBold
		@ 010, 170 MSGET _nTotSc Picture PesqPict("SC7","C7_TOTAL") When .F. of _oPnlRd1 PIXEL SIZE 70,9 FONT oBold
	Endif
	@ 010, 250 Say "Pcs : " of _oPnlRd1 PIXEL FONT oBold
	@ 010, 280 MSGET _nTotPc Picture PesqPict("SC7","C7_TOTAL") When .F. of _oPnlRd1 PIXEL SIZE 70,9 FONT oBold
	@ 010, 370 Say "Atual : " of _oPnlRd1 PIXEL FONT oBold
	@ 010, 400 MSGET _nSldSCA Picture PesqPict("SC7","C7_TOTAL") When .F. of _oPnlRd1 PIXEL SIZE 70,9 FONT oBold
	@ 010, 487 Say "Excedido : " of _oPnlRd1 PIXEL FONT oBold
	@ 010, 520 MSGET _nSldExc Picture PesqPict("SC7","C7_TOTAL") When .F. of _oPnlRd1 PIXEL SIZE 70,9 FONT oBold

	ACTIVATE MSDIALOG _oDlgC ON INIT EnchoiceBar(_oDlgC,{||_oDlgC:End()},{||_oDlgC:End()},,aButtons) CENTERED
Return

//Montagem da tabela de Solicitação de Compras
static Function Mbrwsc1(_cCodCc,_cCodItem,_cDataRef,_calcada,_cUser,_cPcScnum)

	//Variáveis locais

	local _cQryPesSc:= ''
	Local _cTrBArqSc
	Local _aTabCC:={}  //browse SC1

	//Monta tabela para solicitações
	aAdd(_aTabCC,{"C1_FILIAL" 	 	,"C", TamSx3("C1_FILIAL")[1],0})
	aAdd(_aTabCC,{"C1_NUM"   		,"C", TamSx3("C1_NUM")[1],0})
	aAdd(_aTabCC,{"C1_ITEM"       	,"C", TamSx3("C1_ITEM")[1],0})
	aAdd(_aTabCC,{"C1_PRODUTO"    	,"C", TamSx3("C1_PRODUTO")[1],0})
	aAdd(_aTabCC,{"C1_DESCRI"    	,"C", TamSx3("C1_DESCRI")[1],0})
	aAdd(_aTabCC,{"C1_CC"    		,"C", TamSx3("C1_CC")[1],0})
	aAdd(_aTabCC,{"C1_ITEMCTA"    	,"C", TamSx3("C1_ITEMCTA")[1],0})
	aAdd(_aTabCC,{"C1_UM"   	 	,"C", TamSx3("C1_UM")[1],0})
	aAdd(_aTabCC,{"C1_QUANT"   		,"N", TamSx3("C1_QUANT")[1],TamSx3("C1_QUANT")[2]})
	aAdd(_aTabCC,{"C1_ZPRECO"    	,"C", TamSx3("C1_ZPRECO")[1],0})
	aAdd(_aTabCC,{"C1_ZTOTAL"  		,"N", TamSx3("C1_ZTOTAL")[1],TamSx3("C1_ZTOTAL")[2]})
	aAdd(_aTabCC,{"C1_DATPRF"      	,"C", 10,0})
	aAdd(_aTabCC,{"C1_EMISSAO"    	,"C", 10,0})
	aAdd(_aTabCC,{"C1_SOLICIT"    	,"C", TamSx3("C1_SOLICIT")[1],0})
	aAdd(_aTabCC,{"C1_PEDIDO"   	,"C", TamSx3("C1_PEDIDO")[1],0})
	aAdd(_aTabCC,{"C1_ITEMPED"  	,"C", TamSx3("C1_ITEMPED")[1],0})
	aAdd(_aTabCC,{"C1_FORNECE"    	,"C", TamSx3("C1_FORNECE")[1],0})
	aAdd(_aTabCC,{"C1_LOJA"     	,"C", TamSx3("C1_LOJA")[1],0})
	aAdd(_aTabCC,{"C1_ZINFADI"    	,"C", TamSx3("C1_ZINFADI")[1],0})

	// fecha alias da solicitação de compra
	If (Select(_cTabSC)<>0)
		dbSelectArea(_cTabSC)
		dbCloseArea()
	EndIf
	
	// criar um arquivo de trabalho principal
	_cTrBArqSc := FWTemporaryTable():New( _cTabSC )
	_cTrBArqSc:SetFields( _aTabCC )
	_cTrBArqSc:Create()

	//SELECT DOS CAMPOS
	_cQryPesSc := "SELECT C1_FILIAL,C1_NUM,C1_ITEM,C1_PRODUTO, C1_DESCRI,C1_CC,C1_ITEMCTA,C1_UM,C1_QUANT,C1_ZTOTAL,"
	_cQryPesSc += " SUBSTRING(C1_DATPRF,7,2)+'/'+SUBSTRING(C1_DATPRF,5,2)+'/'+SUBSTRING(C1_DATPRF,1,4) C1_DATPRF, "
	_cQryPesSc += " SUBSTRING(C1_EMISSAO,7,2)+'/'+SUBSTRING(C1_EMISSAO,5,2)+'/'+SUBSTRING(C1_EMISSAO,1,4) C1_EMISSAO, "
	_cQryPesSc += "C1_SOLICIT,C1_PEDIDO,C1_ITEMPED,C1_FORNECE,C1_LOJA,C1_ZINFADI "
	_cQryPesSC += "FROM "+RetSqlName("SC1")+" SC1 "
	//Indica a filial corrente e somente registros não deletados
	_cQryPesSC += "WHERE  "+RetSqlCond("SC1")+"  "
	//O item contábil específico
	_cQryPesSC += "AND C1_ITEMCTA = '"+_cCodItem+"' "
	//O centro de custo específico
	_cQryPesSC += "AND C1_CC = '"+_cCodCc+"' "
	//Compara o usuário e sua alcada
	_cQryPesSC += "AND C1_ZIDALCA = '"+_cAlcada+"' "
	//Filtra somente itens de SCs Não Entregues,se já IGNORA,Pois estará no total de PC
	_cQryPesSC += "AND C1_PEDIDO =  ' ' "
	//nao considero o numero DA SC em analise, pois se for alteração pode duplicar o valor da analise.
	_cQryPesSC += "AND C1_NUM <>  '"+_cPcScnum+"' "
	//_data de Previsao de entrega via parametro "
	_cQryPesSC += "AND (SUBSTRING(C1_DATPRF,1,6) = '"+_cDataRef+"' )  "
	//ORDEM
	_cQryPesSC += "ORDER BY C1_NUM "

	//Grava arquivo TXT com sql gerada
	MemoWrit("c:\query\SCSmes.txt",_cQryPesSC)
	//Converte em array devolvendo para rotina chamadora

	// verifica se o TRB existe
	If (Select(_cTabSc) <> 0)
		dbSelectArea(_cTabSc)
		__DbZap()
	EndIf

	//	 atualiza dados do TRB
	U_SqlToTrb(_cQryPesSC,_aTabCC,(_cTabSC))

	//  abre o arquivo de trabalho
	dbSelectArea(_cTabSc)
	(_cTabSc)->(dbGoTop())
	While !(_cTabSc)->(Eof())
		aAdd(_aLisSc, {"SC",(_cTabsc)->C1_NUM,(_cTabsc)->C1_ITEM,(_cTabsc)->C1_PRODUTO,(_cTabsc)->C1_DESCRI,(_cTabsc)->C1_CC,(_cTabsc)->C1_ITEMCTA,(_cTabsc)->C1_UM,(_cTabsc)->C1_QUANT,(_cTabsc)->C1_ZPRECO,(_cTabsc)->C1_ZTOTAL,(_cTabsc)->C1_DATPRF,(_cTabsc)->C1_EMISSAO,(_cTabsc)->C1_SOLICIT,(_cTabsc)->C1_PEDIDO,(_cTabsc)->C1_ITEMPED,(_cTabsc)->C1_FORNECE,(_cTabsc)->C1_LOJA,Posicione("SA2",1,Xfilial("SA2")+(_cTabsc)->C1_FORNECE+(_cTabsc)->C1_LOJA,"A2_NOME"),(_cTabsc)->C1_ZINFADI,_oVerde,0,"",""} )
		(_cTabSc)->(dbSkip())
	EndDo
	_cTrBArqSc:Delete()
Return

//Visualiza pedido de compra
Static Function sfVisuPc(_cTipo,_cPed)
	//Variaveis locais
	Local _lRet 	:= .f. //Inicializa com Falso (Nao aprova).
	local _aAreaAtu := GetArea()
	local _aAreaIsc1 := SaveOrd({"SC1"})
	local _aAreaIsc7 := SaveOrd({"SC7"})

	if _ctipo == 'PC'
		DbSelectArea("SC7")
		DbSetOrder(1)
		If 	MsSeek(xFilial("SC7")+Substr(_cPed,1,len(SC7->C7_NUM)))
			Mata120(NIL,NIL,NIL,2)
		EndIf
	Endif
	if _ctipo == 'SC'
		DbSelectArea("SC1")
		DbSetOrder(1)
		If 	MsSeek(xFilial("SC1")+Substr(_cPed,1,len(SC7->C7_NUM)))
			Mata110(NIL,NIL,NIL,2)
		EndIf
	Endif
	RestOrd(_aAreaIsc1,.t.)
	RestOrd(_aAreaIsc7,.t.)
	RestArea(_aAreaAtu)
Return

//Montagem da tabela de Pedido de compras
Static Function Mbrwsc7(_cCodCc,_cCodItem,_cDataRef,_cAlcada,_cUser,_cPCscNUM)

	//Variáveis locais
	local _cTabPc := GetNextAlias()
	Local _aPcCamp 	:= {}
	local _cQryPesCv := '' //query
	Local _cTrBArqPC  //campospc
	local _cAnaLB:=''  //liberacao alcada
	local _cAnaSC:=''  //analise alcada

	aAdd(_aPcCamp,{"C7_FILIAL" 	 	,"C", TamSx3("C7_FILIAL")[1] ,0})
	aAdd(_aPcCamp,{"C7_NUM"   		,"C", TamSx3("C7_NUM")[1]    ,0})
	aAdd(_aPcCamp,{"C7_ITEM"       	,"C", TamSx3("C7_ITEM")[1]   ,0})
	aAdd(_aPcCamp,{"C7_PRODUTO"    	,"C", TamSx3("C7_PRODUTO")[1],0})
	aAdd(_aPcCamp,{"C7_DESCRI"    	,"C", TamSx3("C7_DESCRI")[1] ,0})
	aAdd(_aPcCamp,{"C7_CC"    		,"C", TamSx3("C7_CC")[1]     ,0})
	aAdd(_aPcCamp,{"C7_ITEMCTA"    	,"C", TamSx3("C7_ITEMCTA")[1],0})
	aAdd(_aPcCamp,{"C7_UM"   	 	,"C", TamSx3("C7_UM")[1]     ,0})
	aAdd(_aPcCamp,{"C7_QUANT"   	,"N", TamSx3("C7_QUANT")[1]  ,0})
	aAdd(_aPcCamp,{"C7_PRECO"   	,"N", TamSx3("C7_PRECO")[1]  ,TamSx3("C7_PRECO")[2]})
	aAdd(_aPcCamp,{"C7_TOTAL"   	,"N", TamSx3("C7_TOTAL")[1]  ,TamSx3("C7_TOTAL")[2]})
	aAdd(_aPcCamp,{"C7_DATPRF"     	,"D", TamSx3("C7_DATPRF")[1] ,0})
	aAdd(_aPcCamp,{"C7_EMISSAO"    	,"D", TamSx3("C7_EMISSAO")[1],0})
	aAdd(_aPcCamp,{"C7_ZUSRSC"    	,"C", TamSx3("C7_ZUSRSC")[1] ,0})
	aAdd(_aPcCamp,{"C7_NUMSC"    	,"C", TamSx3("C7_NUMSC")[1]  ,0})
	aAdd(_aPcCamp,{"C7_ITEMSC"    	,"C", TamSx3("C7_ITEMSC")[1] ,0})
	aAdd(_aPcCamp,{"C7_FORNECE"    	,"C", TamSx3("C7_FORNECE")[1],0})
	aAdd(_aPcCamp,{"C7_LOJA"     	,"C", TamSx3("C7_LOJA")[1]   ,0})
	aAdd(_aPcCamp,{"C7_ZINFADI"    	,"C", TamSx3("C7_ZINFADI")[1],0})
	aAdd(_aPcCamp,{"C7_CONAPRO"    	,"C", TamSx3("C7_CONAPRO")[1],0})
	aAdd(_aPcCamp,{"C7_ZALCRAP"    	,"C", TamSx3("C7_ZALCRAP")[1],0})
	aAdd(_aPcCamp,{"C7_ZNIVRAP"    	,"C", TamSx3("C7_ZNIVRAP")[1],0})
	aAdd(_aPcCamp,{"C7_ZALCAPR"    	,"C", TamSx3("C7_ZALCAPR")[1],0})
	aAdd(_aPcCamp,{"C7_ZNIVAPR"    	,"C", TamSx3("C7_ZNIVAPR")[1],0})
	aAdd(_aPcCamp,{"C7_NOME"    	,"C", TamSx3("DCD_NOMFUN")[1],0})

	// fecha alias da solicitação de compra
	If (Select(_cTabPc)<>0)
		dbSelectArea(_cTabPc)
		dbCloseArea()
	EndIf
	// criar um arquivo de trabalho principal
	_cTrBArqPc := FWTemporaryTable():New( _cTabPc )
	_cTrBArqPc:SetFields( _aPcCamp )
	_cTrBArqPc:Create()
	
	_cQryPesCv := " SELECT C7_FILIAL, C7_NUM, C7_ITEM, C7_PRODUTO, C7_DESCRI, C7_CC, C7_ITEMCTA, C7_UM, C7_QUANT, C7_PRECO, C7_TOTAL, "
	_cQryPesCv += " C7_DATPRF, C7_EMISSAO, "
	_cQryPesCv += " Case When DCD_NOMFUN IS NULL Then 'Cadastrar ID no WMS: '+C7_ZUSRSC Else DCD_NOMFUN End as C7_NOME, "
	_cQryPesCv += " C7_NUMSC, C7_ITEMSC, C7_FORNECE, C7_LOJA, C7_ZINFADI, C7_CONAPRO, C7_ZALCRAP, C7_ZNIVRAP, C7_ZALCAPR, C7_ZNIVAPR "
	_cQryPesCv += " FROM "+RetSQLName("SC7")+" SC7 (nolock) "
	
	_cQryPesCv += " Inner join "+RetSQLName("SF4")+" SF4 (nolock) "
	_cQryPesCv += " on SF4.D_E_L_E_T_ = '' "
	_cQryPesCv += " and F4_FILIAL = '"+xFilial("SF4")+"' "
	// codigo da TES / com financeiro
	_cQryPesCv += "	AND C7_TES = SF4.F4_CODIGO AND SF4.F4_DUPLIC = 'S' "
	
	_cQryPesCv += " Left join "+RetSQLName("DCD")+" DCD (nolock) "
	_cQryPesCv += " on DCD.D_E_L_E_T_ = '' "
	_cQryPesCv += " and DCD_CODFUN = C7_ZUSRSC "
	
	// fitro padrao
	_cQryPesCv += " WHERE SC7.D_E_L_E_T_ = '' "
	// controle de alcadas e eliminados por resido
	_cQryPesCv += "	AND C7_ZCONTAL <> 'X' AND C7_RESIDUO <> 'S' "
	// centro de custo
	_cQryPesCv += " AND C7_CC = '"+_cCodCc+"' "
	// item contabil
	_cQryPesCv += " AND C7_ITEMCTA = '"+_cCodItem+"' "
	_cQryPesCv += " AND C7_NUM <> '"+_cPCscNUM+"' "
	// data de referencia
	_cQryPesCv += " AND SUBSTRING(C7_DATPRF,1,6) = '"+_cdataRef+"' "
	// ordem dos dados
	_cQryPesCv += " ORDER BY C7_ZNIVRAP DESC, C7_DATPRF, C7_NUM"

	memowrit("c:\query\FTMBRWSC7_"+_cUser+".txt",_cQryPesCv)

	If (Select(_cTabPC) <> 0)
		dbSelectArea(_cTabPc)
		__DbZap()
	EndIf

	// atualiza dados do TRB
	U_SqlToTrb(_cQryPesCv,_aPcCamp,(_cTabPc))

	//  abre o arquivo de trabalho
	DbSelectArea(_cTabPc)
	(_cTabPc)->(dbGotop())
	While (_cTabPc)->( ! Eof() )

		_cAnaSC:=''
		_cAnaLB:=''

		if !empty((_cTabPc)->C7_ZALCRAP)
			_cIdAlcada := u_FTALCID((_cTabPc)->C7_ZALCRAP, (_cTabPc)->C7_CC, (_cTabPc)->C7_ITEMCTA, (_cTabPc)->C7_DATPRF ,.T.)
			_cAnaSC    := (_cTabPc)->C7_ZALCRAP+"-"+(_cTabPc)->C7_ZNIVRAP+" / "+ALLTRIM(upper(_cIdalcada))
		Endif
		if !empty((_cTabPc)->C7_ZALCAPR)
			_cIdAlcada := u_FTALCID((_cTabPc)->C7_ZALCAPR, (_cTabPc)->C7_CC, (_cTabPc)->C7_ITEMCTA, (_cTabPc)->C7_DATPRF,.T.)
			_cAnaLB    := (_cTabPc)->C7_ZALCAPR+"-"+(_cTabPc)->C7_ZNIVAPR+" / "+ALLTRIM(upper(_cIdalcada))
		Endif

		// inclui registro no browse
		aAdd(_aLisSC, {;
		"PC",;
		(_cTabPc)->C7_NUM,;
		(_cTabPc)->C7_ITEM,;
		(_cTabPc)->C7_PRODUTO,;
		(_cTabpc)->C7_DESCRI,;
		(_cTabPc)->C7_CC,;
		(_cTabPc)->C7_ITEMCTA,;
		(_cTabPc)->C7_UM,;
		(_cTabPc)->C7_QUANT,;
		(_cTabPc)->C7_PRECO,;
		(_cTabPc)->C7_TOTAL,;
		(_cTabPc)->C7_DATPRF,;
		(_cTabPc)->C7_EMISSAO,;
		AllTrim((_cTabPc)->C7_NOME),;
		(_cTabPc)->C7_NUMSC,;
		(_cTabPc)->C7_ITEMSC,;
		(_cTabPc)->C7_FORNECE,;
		(_cTabPc)->C7_LOJA,;
		Posicione("SA2",1,Xfilial("SA2")+(_cTabPc)->C7_FORNECE+(_cTabPc)->C7_LOJA,"A2_NOME"),;
		(_cTabPc)->C7_ZINFADI,;
		iif((_cTabPc)->C7_CONAPRO == 'B',_oAzul,_oVerde),;
		0,;
		_cAnaSC,;
		_cAnaLB})

		// proximo item
		(_cTabPc)->(dbSkip())
	EndDo

	if Len(_aLisSC) < 1
		aAdd(_aLisSC,{"","","","","","","","",0,0,"","","","","","","","","","",_oVermelho,0,"",""})
	EndIf
	_cTrBArqPc:Delete()
Return

// ** funcao que retorna o valor total de pedidos dentro do periodo
User Function FtValPC(mvCenCusto, mvItemCtbl, mvDataRef, mvNrPedCom, mvOnlyPedLib)
	// query
	Local _cQryPesCv

	// retorno do total do mes
	local _nTotMes := 0

	//Se passar em branco , data atual
	default mvDataRef    := dDataBase
	defauLt mvNrPedCom   := ' '
	default mvOnlyPedLib := .f.

	// inicial
	_cQryPesCv := " SELECT ISNULL(SUM(C7_TOTAL),0) "
	// pedido de compras / cad. TES
	_cQryPesCv += " FROM "+RetSqlTab("SC7,SF4")
	// filtro padrao
	_cQryPesCv += " WHERE "+RetSqlCond("SC7,SF4")
	// controle de alcadas e eliminados por resido
	_cQryPesCv += "	AND C7_ZCONTAL <> 'X' AND C7_RESIDUO <> 'S' "
	// codigo da TES / com financeiro
	_cQryPesCv += "	AND C7_TES = SF4.F4_CODIGO AND SF4.F4_DUPLIC = 'S' "
	// centro de custo
	_cQryPesCv += " AND C7_CC = '"+mvCenCusto+"' "
	// item contabil
	_cQryPesCv += " AND C7_ITEMCTA = '"+mvItemCtbl+"' "
	// pedidos diferentes do pedido atual
	_cQryPesCv += " AND C7_NUM <> '"+mvNrPedCom+"' "
	// data de referencia
	_cQryPesCv += " AND SUBSTRING(C7_DATPRF,1,6) = '"+SubStr(DtoS(mvDataRef),1,6)+"'"
	// somente pedidos liberados
	If (mvOnlyPedLib)
		_cQryPesCv += " AND C7_CONAPRO <> 'B' "
	EndIf

	memowrit("c:\query\tcomxfun_FTvalPC_CC_"+AllTrim(mvCenCusto)+"_IC_"+AllTrim(mvItemCtbl)+"_DATA_"+DtoS(mvDataRef)+".txt",_cQryPesCv)

	// atualiza os dados
	_nTotMes := U_FtQuery(_cQryPesCv)

Return(_nTotMes)

// ** funcao para analise dos itens do pedido, chamada no PE MT120GOK
User Function FTCOM02C(mvNumPC)

	// Salva area
	Local _aAreaAtu := GetArea()
	Local _aAreaSC7 := SC7->(GetArea())
	Local _aAreaZ26 := Z26->(GetArea())

	// retorno dos dados para liberar/bloquear os itens do pedido
	local _aDadosRes := {}
	local _nDadosRes

	// query
	local _cQryPesCv

	// chama funcao padrao para analise das aprovacoes/limites
	// Estrutura retorno 2o parametro
	// estrutura
	// 1-CC
	// 2-Item Contabil
	// 3-Valor Limite
	// 4-Saldo PC
	// 5-Saldo SC
	// 6-Periodo Referencia (Mes/Ano)
	// 7-Codigo/ID Alcada Solicitante
	// 8-Aprovado (S-Sim. N-Enviado para Analise/superior)
	// 9-ID Alcada Superior
	local _lRet := U_FtAvaAlc(mvNumPC, @_aDadosRes, .t.)

	// dados temporarios
	local _cCenCusto, _cItCtbl, _cIdAlcSol, _cPedLibOk
	local _cIdAlcApr, _cNivAlcApr, _cUsrAlcApr

	// calendario
	local _cAnoCalend

	// dados/recno do pedido
	local _aRecnoSC7
	local _nRecnoSC7

	// controle de estorno de liberacoes
	local _lEstornoOk := .f.

	// valor total bloqueado
	local _nVlrTotBloq := 0

	// varre todos os itens para atualizacao de dados
	For _nDadosRes := 1 to len(_aDadosRes)

		// atualiza variaveis
		_cCenCusto  := _aDadosRes[_nDadosRes][ 1]
		_cItCtbl    := _aDadosRes[_nDadosRes][ 2]
		_cIdAlcSol  := _aDadosRes[_nDadosRes][ 7]
		_cPedLibOk  := _aDadosRes[_nDadosRes][ 8]

		// calendario
		_cAnoCalend := SubStr(_aDadosRes[_nDadosRes][6],1,4)

		// id alcada aprovadora
		_cIdAlcApr := _aDadosRes[_nDadosRes][ 9]


		// prepara query para buscar os itens do pedido de acordo com o CC + Item + Id Alcada
		_cQryPesCv := "SELECT SC7.R_E_C_N_O_ SC7RECNO "
		// pedido de compras / cad. TES
		_cQryPesCv += "FROM "+RetSqlTab("SC7,SF4")
		// filtro padrao
		_cQryPesCv += " WHERE "+RetSqlCond("SC7,SF4")
		// numero Pedido de compra
		_cQryPesCv += "AND C7_NUM = '"+mvNumPC+"' "
		// codigo da TES / com financeiro
		_cQryPesCv += "	AND C7_TES = SF4.F4_CODIGO AND SF4.F4_DUPLIC = 'S' "
		// Centro de custo
		_cQryPesCv += " AND C7_CC = '"+_cCenCusto+"' "
		// Item contábil
		_cQryPesCv += " AND C7_ITEMCTA = '"+_cItCtbl+"' "
		//nao liberado
		_cQryPesCv += "	AND C7_QUJE < C7_QUANT "
		// filtro para residuos / recusados
		_cQryPesCv += "	AND C7_RESIDUO <> 'S' "
		// id da alcada
		_cQryPesCv += " AND C7_ZIDALCA = '"+_cIdAlcSol+"' "

		//Grava arquivo TXT com sql gerada
		MemoWrit("c:\query\mt120gok_FTCOM02C_PC"+mvNumPC+".txt",_cQryPesCv)

		// Converte em array devolvendo para rotina chamadora
		_aRecnoSC7 := U_SqlToVet(_cQryPesCv)

		// varre os itens/recno para atualizar conforme atualizacao
		For _nRecnoSC7 := 1 to Len(_aRecnoSC7)

			// posiciona no registro da tabela
			Dbselectarea("SC7")
			SC7->( DbGoTo(_aRecnoSC7[_nRecnoSC7]) )

			// estorna todas as liberacoes
			If ( ! _lEstornoOk )
				// estorno padrao de documentos
				MaAlcDoc({SC7->C7_NUM,if(nTipoPed == 1,"PC","AE"),SC7->C7_TOTAL,,,SC7->C7_APROV,,SC7->C7_MOEDA,SC7->C7_TXMOEDA,SC7->C7_EMISSAO},SC7->C7_EMISSAO,3)
				// status estorno ok
				_lEstornoOk := .t.
			EndIf

			// se o pedido estiver liberado/aprovado
			If (_cPedLibOk == "S")

				// atualiza campos de controle / customizado
				Reclock("SC7",.F.)
				SC7->C7_CONAPRO := 'L'             // L-Liberado
				SC7->C7_ZCONTAL := SC7->C7_ZNIVALC // nivel da alcada solicitante/aprovadora
				SC7->C7_ZALCRAP := SC7->C7_ZIDALCA // id alcada aprovador
				SC7->C7_ZNIVRAP := SC7->C7_ZNIVALC // nivel da alcada solicitante/aprovadora
				SC7->C7_ZALCAPR := SC7->C7_ZIDALCA // id alcada aprovador
				SC7->C7_ZNIVAPR := SC7->C7_ZNIVALC // nivel alcada aprovador
				SC7->C7_ZUSRAPR := CriaVar("C7_ZUSRAPR", .f.)
				Msunlock("SC7")

				// gera log conforme detalhes da analise
				U_FtGeraLog(cFilAnt, "SC7", SC7->(C7_FILIAL+C7_NUM+C7_ITEM), "Pedido/Item Liberado - Valores dentro da Alçada/Orçamento", "COM", "")

				// se o pedido estiver NÃO liberado/aprovado
			ElseIf (_cPedLibOk == "N")

				// posiciona no ID da Alcada Aprovadora
				dbSelectArea("Z26")
				Z26->(dbSetOrder(1)) // 1-Z26_FILIAL, Z26_CALEND, Z26_PERFID
				Z26->(dbSeek( xFilial("Z26")+_cAnoCalend+_cIdAlcApr ))

				// nivel da alcada aprovadora
				_cNivAlcApr := Z26->Z26_NIVEL

				// usuario responsavel pela aprovacao
				_cUsrAlcApr := IIF(EMPTY(AllTrim(Posicione("DCD",1,xFilial("DCD")+Z26->Z26_CODUSU,"DCD_NOMFUN"))),'Cadastrar ID no WMS: '+Z26->Z26_CODUSU,AllTrim(Posicione("DCD",1,xFilial("DCD")+Z26->Z26_CODUSU,"DCD_NOMFUN")))

				// atualiza campos de controle / customizado
				Reclock("SC7",.F.)
				SC7->C7_CONAPRO := 'B'         // B-Bloqueado
				SC7->C7_ZCONTAL := _cNivAlcApr // nivel da alcada solicitante/aprovadora
				SC7->C7_ZALCRAP := _cIdAlcApr  // id alcada aprovador
				SC7->C7_ZNIVRAP := _cNivAlcApr // nivel da alcada solicitante/aprovadora
				SC7->C7_ZALCAPR := CriaVar("C7_ZALCAPR", .f.)
				SC7->C7_ZNIVAPR := CriaVar("C7_ZNIVAPR", .f.)
				SC7->C7_ZUSRAPR := CriaVar("C7_ZUSRAPR", .f.)
				Msunlock("SC7")

				// valor total bloqueado
				_nVlrTotBloq += SC7->C7_TOTAL

				// gera log conforme detalhes da analise
				U_FtGeraLog(cFilAnt, "SC7", SC7->(C7_FILIAL+C7_NUM+C7_ITEM), "Pedido/Item em Análise - Usuário Responsável: "+_cUsrAlcApr, "COM", "")

			EndIf

		Next _nRecnoSC7

	Next _nDadosRes

	// reprocessa liberacao de documentos
	MaAlcDoc({SC7->C7_NUM,if(nTipoPed == 1,"PC","AE"),_nVlrTotBloq,,,SC7->C7_APROV,,SC7->C7_MOEDA,SC7->C7_TXMOEDA,SC7->C7_EMISSAO},,1)

	// envia email com so detalhes do pedido de venda
	U_FtMailPC(mvNumPC, Nil, Nil, Nil, Nil)

	// restaura area inicial
	RestArea(_aAreaZ26)
	RestArea(_aAreaSC7)
	RestArea(_aAreaAtu)

Return

// ** funcao padrao para analise de valores/limites/aprovacoes do compras
User Function FtAvaAlc(mvPcScNum, mvDadosRet, mvRetDados)

	// variavel para salvar estado das variáveis de memória
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"SC7"})

	// variavel de retorno
	Local _lRet := .t.

	// posicao dos campos
	local _nPosNec    := IIf(mvRetDados, 0, aScan(aHeader,{|x| alltrim(x[2]) == 'C7_DATPRF' }))
	local _nPosUsrSol := IIf(mvRetDados, 0, aScan(aHeader,{|x| alltrim(x[2]) == 'C7_ZUSRSC' })) // usuario responsavel pela solicitacao
	local _nPosCC     := IIf(mvRetDados, 0, aScan(aHeader,{|x| alltrim(x[2]) == 'C7_CC'     }))
	local _nPosITc    := IIf(mvRetDados, 0, aScan(aHeader,{|x| alltrim(x[2]) == 'C7_ITEMCTA'}))
	local _nPosTOT    := IIf(mvRetDados, 0, aScan(aHeader,{|x| alltrim(x[2]) == 'C7_TOTAL'  })) //VLR TOTAL DA SC
	local _nPosALC    := IIf(mvRetDados, 0, aScan(aHeader,{|x| alltrim(x[2]) == 'C7_ZIDALCA'})) //ALCADA DO USUARIO
	local _nPostes    := IIf(mvRetDados, 0, aScan(aHeader,{|x| alltrim(x[2]) == 'C7_TES'    })) //USUARIO/ALCADA DO USUARIO
	local _nPosDel    := IIf(mvRetDados, 0, (Len(aHeader) + 1)                                )

	// TES controla financeiro
	local _cGeraFin := 'N'
	// variaveis temporarias
	local _nPos
	//Saldo Total
	Local _nSaltot := 0
	// Valor  no mes SC7/PC
	Local _nTotApPC := 0
	// Valor no mes SC1/SC
	Local _nTotApsc := 0
	// valor limite aprovação
	Local _nVlrLimite  := 0
	// valor Anterior da SC
	Local _nVlrASC  := 0
	//nivel do usuario solicitante
	local _cNivUsrSol := CriaVar("Z26_NIVEL", .f.)

	// Array contendo as informações dos centros de custos  / saldo para serem analisados
	// 1-CC
	// 2-Itemctb
	// 3-Periodo Referencia (ANO + MES)
	// 4-Valor Limite
	// 5-ValorPC Aprovado
	// 6-ValorSC
	// 7-Total PC/SC Atual
	// 8-ID Alcada Usr Solicitante
	// 9-Cod Usr Solicitante
	local _aCCSld := {}

	// total de solicitacoes de compras aprovadas
	local _nTotASC := 0

	// total de pedidos de compras aprovadas
	local _nTotAPC := 0

	// variavel mostra a tela OU não
	local _lMostra := .F.

	// posicao dos valores do vetor que acumula saldo da analise
	local _nPosCCSLD := 0

	// periodo de referencia (ANO + MES)
	local _cPerRefer := ""

	// usuario responsavel pela solicitacao/pedido de compras
	local _cUsrSolic := ""

	// variavel com os dados para analise
	local _aDadosAna := {}

	// query
	local _cQuery

	// valores padroes
	Default mvDadosRet := {}

	// se for analise de dados, busca dados ja gravados
	If (mvRetDados)

		// define posicao dos campos
		_nPosCC     := 2
		_nPosITc    := 3
		_nPosUsrSol := 4
		_nPosTOT    := 5
		_nPosNec    := 6
		_nPosALC    := 7
		_nPostes    := 8
		_nPosDel    := 9

		// prepara query
		_cQuery := " SELECT C7_NUM, C7_CC, C7_ITEMCTA, C7_ZUSRSC, SUM(C7_TOTAL) TOTAL, C7_DATPRF, C7_ZIDALCA, C7_TES, '.F.' IT_DEL "
		// pedido de compras / cad. TES
		_cQuery += " FROM "+RetSqlTab("SC7,SF4")
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("SC7,SF4")
		// numero do pedido
		_cQuery += " AND C7_NUM = '"+mvPcScNum+"' "
		// codigo da TES / com financeiro
		_cQuery += " AND C7_TES = SF4.F4_CODIGO AND SF4.F4_DUPLIC = 'S' "
		// somente itens Sem aprovação ou entregues
		_cQuery += " AND C7_QUJE < C7_QUANT "
		// filtro para residuos / recusados
		_cQuery += " AND C7_RESIDUO <> 'S' "
		// agrupa dados
		_cQuery += " GROUP BY C7_NUM, C7_CC, C7_ITEMCTA, C7_ZUSRSC, C7_DATPRF, C7_ZIDALCA, C7_TES "

		//Grava arquivo TXT com sql gerada
		MemoWrit("c:\query\tcomxfun_FtAvaAlc.txt",_cQuery)

		// Converte em array devolvendo para rotina chamadora
		_aDadosAna := U_SqlToVet(_cQuery,{"C7_DATPRF"})

	ElseIf ( ! mvRetDados )
		_aDadosAna := aClone(aCols)

	EndIf

	// Efetua a busca pelos itens dO pc
	For _nPos := 1 to Len(_aDadosAna)

		// valida se a linha esta deletada
		If ( _aDadosAna[_nPos][_nPosDel] )
			Loop
		EndIf

		// verifica o controle financeiro da TES
		_cGeraFin := GETADVFVAL("SF4","F4_DUPLIC",xFilial("SF4")+_aDadosAna[_nPos][_nPosTEs])

		// extrai o periodo de referencia
		_cPerRefer := SubStr(DtoS(_aDadosAna[_nPos][_nPosNec]),1,6)

		// se controla financeiro
		If (_cGeraFin == 'S')

			// define controle para mostrar a tela
			_lMostra := .t.

			// usuario Resposanvel pela SC
			_cUsrSolic := _aDadosAna[_nPos][_nPosUsrSol]

			// verifica o nível do usuário solicitante
			_cNivUsrSol := U_FTCOM06A(_cUsrSolic, _aDadosAna[_nPos][_nPosNec])

			// verifica se já foi analisado o CC se sim somente soma o valor para analise
			// 1-CC
			// 2-Itemctb
			// 3-Periodo Referencia (ANO + MES)
			// 4-Valor Limite
			// 5-ValorPC Aprovado
			// 6-ValorSC
			// 7-Total PC/SC Atual
			// 8-ID Alcada Usr Solicitante
			// 9-Cod Usr Solicitante
			_nPosCCSLD := aScan(_aCCSld,{|x| (alltrim(x[1]+x[2]+x[3])) == (alltrim(_aDadosAna[_nPos][_nPosCC] + _aDadosAna[_nPos][_nPosITc] + _cPerRefer)) })

			// se ja tem saldo analisado, incrementa
			If (_nPosCCSLD > 0)
				//soma na analise atual
				_aCCSld[_nPosCCSLD][7] += _aDadosAna[_nPos][_nPosTOT]
				Loop
			Endif

			// Limite de aprovacao usuario MES DE REFERENFICA
			_nVlrLimite := U_FtCom08A(_cUsrSolic, _cNivUsrSol, "L", _aDadosAna[_nPos][_nPosCC], _aDadosAna[_nPos][_nPosITc], _aDadosAna[_nPos][_nPosNec])

			//TOTAL APROVADO - PC MES DE REFERENFICA
			// 1-CC
			// 2-Item Contabil
			// 3-Periodo Referencia
			// 4-Num Pedido Atual
			_nTotAPC := U_FtValPC(_aDadosAna[_nPos][_nPosCC], _aDadosAna[_nPos][_nPosITc], _aDadosAna[_nPos][_nPosNec], mvPcScNum, .t.)

			// estrutura
			// 1-CC
			// 2-Itemctb
			// 3-Periodo Referencia (ANO + MES)
			// 4-Valor Limite
			// 5-ValorPC Aprovado
			// 6-ValorSC
			// 7-Total PC/SC Atual
			// 8-ID Alcada Usr Solicitante
			// 9-Cod Usr Solicitante
			aAdd(_aCCSld,{;
			_aDadosAna[_nPos][_nPosCC] ,;
			_aDadosAna[_nPos][_nPosITc],;
			_cPerRefer                 ,;
			_nVlrLimite                ,;
			_nTotAPC                   ,;
			_nTotASC                   ,;
			_aDadosAna[_nPos][_nPosTOT],;
			_aDadosAna[_nPos][_nPosAlc],;
			_cUsrSolic                 })

		Endif

	Next _nPos

	// verifica de deve apresentar a tela de resumo/extrato da analise
	If (_lMostra).and.(Len(_aCCSld) > 0)
		// apos preparada a analise verifico se o valor do limite da alçada extrapolou e mostro a informaçao para o usuario
		_lRet := U_FTMORPC("PC", _aCCSld, _cUsrSolic, mvPcScNum, mvRetDados, @mvDadosRet)
	Endif

	// restaura a Area Inicial
	RestOrd(_aAreaIni,.t.)
	RestArea(_aAreaAtu)

Return( _lRet )

// ** funcao que retorna todos os perfis abaixo do ID informado no parametro
Static Function sfRetAcima(mvCalend, mvIdAtual, mvIdNivel)
	// area atual
	local _aAreaZ26 := Z26->(GetArea())
	// variavel de controle do Loop
	local _lBusca := .t.
	// controle de ID
	local _aTmpIdPesq := {mvIdAtual}
	local _aIdPesq := {}
	local _nIdPesq
	// seek
	local _cSeekZ26
	// id selecioados
	local _aIdPrfSel := {}

	// calendario
	Default mvCalend  := SubS(DtoS(dDatabase),1,4)
	Default mvIdNivel := "Z"

	While (_lBusca)

		// zera variaveis
		_aIdPesq    := aClone(_aTmpIdPesq)
		_aTmpIdPesq := {}

		// varre todos os id para pesquisa
		For _nIdPesq := 1 to Len(_aIdPesq)

			// pesquisa ID atual
			dbSelectArea("Z26")
			Z26->(dbSetOrder(1)) // 1-Z26_FILIAL, Z26_CALEND, Z26_PERFID
			If ! Z26->(dbSeek( _cSeekZ26 := xFilial("Z26") + mvCalend + _aIdPesq[_nIdPesq] ))
				_lBusca := .f.
				Loop
			EndIf

			// se nao tem perfil superior
			If (Empty(Z26->Z26_PERSUP))
				_lBusca := .f.
				Loop
			EndIf

			// se encontrou, atualiza variaveis
			While Z26->( ! Eof() ).and.(Z26->(Z26_FILIAL + Z26_CALEND + Z26_PERFID) == _cSeekZ26)
				// valida o nivel, e adiciona no vetor de retorno
				If (Z26->Z26_NIVEL <= mvIdNivel)
					aAdd(_aIdPrfSel , {Z26->Z26_PERFID, Z26->Z26_CODUSU, Z26->Z26_NIVEL, Z26->Z26_PERSUP})
				EndIf
				// controle temporario
				aAdd(_aTmpIdPesq, Z26->Z26_PERSUP)
				// proximo item
				Z26->(dbSkip())
			EndDo

		Next _nIdPesq

	EndDo

	// restaura area atual
	RestArea(_aAreaZ26)

Return(_aIdPrfSel)