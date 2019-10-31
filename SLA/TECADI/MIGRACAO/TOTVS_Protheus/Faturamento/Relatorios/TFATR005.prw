#INCLUDE "PROTHEUS.CH"
#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         !Impressao de Pré - Nota                                  !
!                  !                                                         !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe Limas                                            !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 17/07/17                                                !
+------------------+--------------------------------------------------------*/

User Function TFATR005(mvRotAuto,mv_Local,mv_Arquivo,mv_Pedido,mv_data,mv_Cliente,mv_Loja)

	// grupo de perguntas (parametros)
	Local _aPerg := {}
	Local _cPerg := PadR("TFATR005",10)
	Local li         := 0 // Contador de Linhas
	Local _cQuery     := ""
	Local cChave     := ""
	Local _cDiscrNFSe     := ""
	Local nItem      := 0
	Local nTotVal    := 0
	Local nG		 := 0
	Local _nTotItens
	Local _nPagAtu
	Local _nPagTot
	Local nRegistro      := 0
	Local	oPrintSetup		:= Nil
	Private _cAliasSC5    := ""
	Private _cAliasSC6    := ""
	Private _aItemPed     := {}
	Private _aCabPed	  := {}
	Private _aDscServico  := {}
	Private _nPrinLin     := 0
	Private _nTmpLin      := 0

	// variaveis para gerenciar a criação do PDF
	Private lAdjustToLegacy		:= .T.
	Private lDisableSetup 		:= .T.
	Private lServer 			:= .T.
	Private lPDFAsPNG			:= .F.
	Private lViewPDF			:= .T.
	Private cDirPrint			:= ""
	Private cFileOP				:= ""
	Private cArqDir				:= ""
	Private cArqTemp			:= ""

	// imagem da logo
	Private _cImagem := "\"+Alltrim(CurDir())+"\logo_tecadi.jpg"

	//Parametros de entrada
	Default mv_Local   			:= ""
	Default mv_Arquivo 			:= ""
	Default mvRotAuto 			:= .F.
	Default	mv_Pedido           := ""
	Default	mv_data             := dDatabase
	Default	mv_Cliente          := ""
	Default	mv_Loja             := ""

	// criacao das Perguntas
	aAdd(_aPerg,{"Pedido de Venda De?"  ,"C",TamSx3("C5_NUM")[1],0,"G",,"SC5"}) //mv_par01
	aAdd(_aPerg,{"Pedido de Venda Até?" ,"C",TamSx3("C5_NUM")[1],0,"G",,"SC5"}) //mv_par02
	aAdd(_aPerg,{"Data Emissão De?"     ,"D",8,0,"G",,""})                      //mv_par03
	aAdd(_aPerg,{"Data Emissão Até?"    ,"D",8,0,"G",,""})                      //mv_par04
	aAdd(_aPerg,{"Cliente De?"          ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par05
	aAdd(_aPerg,{"Cliente Até?"         ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par06
	aAdd(_aPerg,{"Loja De?"             ,"C",TamSx3("A1_LOJA")[1],0,"G",,""})   //mv_par07
	aAdd(_aPerg,{"Loja Até?"            ,"C",TamSx3("A1_LOJA")[1],0,"G",,""})   //mv_par08
	aAdd(_aPerg,{"Agrupa"               ,"N",1,0,"C",{"Sim","Não"},""})         //mv_par09

	// cria grupo de perguntas
	U_FtCriaSX1( _cPerg,_aPerg )

	If mvRotAuto
		Pergunte(_cPerg,.F.)
		mv_par01 := mv_Pedido
		mv_par02 := mv_Pedido
		mv_par03 := mv_data
		mv_par04 := mv_data
		mv_par05 := mv_Cliente
		mv_par06 := mv_Cliente
		mv_par07 := mv_Loja
		mv_par08 := mv_Loja
		mv_par09 := 2
	Else
		If ! Pergunte(_cPerg,.T.)
			Return ()
		EndIf
	EndIf

	cDirPrint	:= Iif(Empty(mv_Local)  ,Alltrim(GetTempPath()),mv_Local)
	cFileOP		:= Iif(Empty(mv_Arquivo),"TFATR005"           ,mv_Arquivo)
	cArqDir		:= cDirPrint + cFileOP + ".pdf"
	cArqTemp	:= cDirPrint + cFileOP + ".rel"

	//Apaga arquivos Temporarios
	FErase(cArqDir)
	FErase(cArqTemp)

	_cAliasSC6:= _cAliasSC5:= GetNextAlias()     // retorna o próximo alias disponível

	_cQuery := "SELECT "
	If mv_par09 == 1
		_cQuery += "C5_CLIENTE,C5_LOJACLI,C5_CONDPAG,C6_PRODUTO,C6_DESCRI,C6_QTDVEN ,C6_PRCVEN ,C6_VALOR  "
		_cQuery += "FROM "
		_cQuery += RetSqlName("SC5") + " SC5 "
		// itens do pedido de venda
		_cQuery += " INNER JOIN "+RetSqlName("SC6")+" SC6 ON "+RetSqlCond("SC6")+" AND C5_NUM = C6_NUM "
	Else
		_cQuery += "C5_CLIENTE,C5_LOJACLI,C5_CONDPAG,C5_EMISSAO,C5_NUM,C5_MENNOTA"//,C6_ITEM,C6_PRODUTO,C6_DESCRI,C6_QTDVEN,C6_PRCVEN,C6_VALOR,C6_NUM"
		_cQuery += "FROM "
		_cQuery += RetSqlName("SC5") + " SC5 "
	EndIf
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond('SC5')+" "
	_cQuery += "AND C5_NUM     BETWEEN '" + mv_par01        +"' AND '" + mv_par02      +"' "
	_cQuery += "AND C5_EMISSAO BETWEEN '" + DTOS(mv_par03)  +"' AND '" + DTOS(mv_par04)+"' "
	_cQuery += "AND C5_CLIENTE BETWEEN '" + mv_par05        +"' AND '" + mv_par06      +"' "
	_cQuery += "AND C5_LOJACLI BETWEEN '" + mv_par07        +"' AND '" + mv_par08      +"' "
	_cQuery += "AND C5_NOTA = '' "
	If mv_par09 == 1
		_cQuery += "ORDER BY C5_CLIENTE, C5_LOJACLI"
	Else
		_cQuery += "ORDER BY C5_NUM"
	EndIf

	_cQuery := ChangeQuery(_cQuery)

	If Select(_cAliasSC5) <> 0
		(_cAliasSC5)->(dbCloseArea())
	EndIf

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),_cAliasSC5,.T.,.T.)

	count to nRegistro

	If (nRegistro <= 0)
		If (!mvRotAuto)
			MsgStop("Sem informações para Imprimir")
		EndIf
		//Apaga arquivos Temporarios
		FErase(oReport:cPathPDF + cFileOP + ".pdf")
		FErase(oReport:cPathPDF + cFileOP + ".rel")
		Return()
	EndIf

	// Cria Objeto para impressao Grafica
	oReport   := FWMsPrinter():New(cFileOP+".pdf",IMP_PDF,lAdjustToLegacy,cDirPrint,lDisableSetup, /*[lTReport]*/,  /*[@oPrintSetup]*/, /*[ cPrinter]*/, lServer, lPDFAsPNG, /*[ lRaw]*/, lViewPDF, /*[ nQtdCopy]*/ )
	_oFont01n := TFontEx():New(oReport,"Arial",20,20,.T.,.F.,.F.)// bold / italic / under
	_oFont02  := TFontEx():New(oReport,"Arial",15,15,.F.,.F.,.F.)// bold / italic / under
	_oFont02n := TFontEx():New(oReport,"Arial",15,15,.T.,.F.,.F.)// bold / italic / under
	oReport:nDevice  := IMP_PDF
	oReport:SetLandscape()
	oReport:SetMargin(60,60,60,60)

	IF mvRotAuto
		oReport:cPathPDF := cDirPrint
		//Impressão com o componente TMSPrinter Tela.
		oReport:GetViewPDF(.F.)
		oReport:SetViewPDF(.F.)
	Else
		oReport:Setup()
		If oReport:nModalResult == 2
			//Apaga arquivos Temporarios
			FErase(oReport:cPathPDF + cFileOP + ".pdf")
			FErase(oReport:cPathPDF + cFileOP + ".rel")
			oReport:Cancel()
			oReport:Deactivate()
			Return()
		EndIf
		oReport:GetViewPDF(.T.)
		oReport:SetViewPDF(.T.)
	EndIF
	//Apaga arquivos Temporarios
	FErase(oReport:cPathPDF + cFileOP + ".pdf")
	FErase(oReport:cPathPDF + cFileOP + ".rel")

	ProcRegua(nRegistro)

	(_cAliasSC5)->(dbGoTop())

	While !((_cAliasSC5)->(Eof()))

		cChave   := (_cAliasSC5)->C5_CLIENTE + (_cAliasSC5)->C5_LOJACLI

		_aCabPed := {}
		_aItemPed:= {}

		//Impressão Agrupada por Clientes
		If mv_par09 == 1
			IncProc()
			_aCabPed := {"",(_cAliasSC5)->C5_CLIENTE,(_cAliasSC5)->C5_LOJACLI,"",(_cAliasSC5)->C5_CONDPAG,"",""}
			_nItem := 1
			While !((_cAliasSC6)->(Eof())) .And. cChave == (_cAliasSC6)->C5_CLIENTE + (_cAliasSC6)->C5_LOJACLI
				/*
				ex: estrutura _aDscServico := {}
				1-Cod.Produto
				2-Dsc.Produto
				3-Quantidade
				4-Vlr.Unitario
				5-Vlr.Total
				*/
				// chama funcao generica para padronizacao da descricao dos servicos
				U_FtDscNfs("1",@_aDscServico,(_cAliasSC6)->C6_PRODUTO,(_cAliasSC6)->C6_QTDVEN,(_cAliasSC6)->C6_DESCRI,(_cAliasSC6)->C6_PRCVEN,(_cAliasSC6)->C6_VALOR)
				nTotVal += (_cAliasSC6)->C6_VALOR
				If cChave == (_cAliasSC6)->C5_CLIENTE + (_cAliasSC6)->C5_LOJACLI
					(_cAliasSC6)->(dbSkip())
				EndIf
			EndDo
			_cDiscrNFSe := ""
			// chama funcao generica para padronizacao da descricao dos servicos
			U_FtDscNfs("2",_aDscServico ,Nil,Nil,@_cDiscrNFSe,Nil,Nil)
			_aItemPed := StrTokArr(_cDiscrNFSe,CRLF )
			//Impressão por Pedidos..
		Else
			IncProc()
			_aCabPed := {"",(_cAliasSC5)->C5_CLIENTE,(_cAliasSC5)->C5_LOJACLI,"",(_cAliasSC5)->C5_CONDPAG,(_cAliasSC5)->C5_EMISSAO,(_cAliasSC5)->C5_NUM}
			cChave    := xFilial("SC5")+(_cAliasSC6)->(C5_NUM)
			SC6->(dbSetOrder(1)) //C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
			SC6->(dbSeek(xFilial("SC6")+(_cAliasSC6)->(C5_NUM)))
			While SC6->(!Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == cChave
				aadd(_aItemPed,{SC6->C6_ITEM,SC6->C6_PRODUTO,SC6->C6_DESCRI,SC6->C6_QTDVEN,SC6->C6_PRCVEN,SC6->C6_VALOR})
				SC6->(dbSkip())
			EndDo
			nTotVal:=0
		EndIF

		/*
		INICIO - Logica para quantidade de Paginas
		*/

		// total de itens
		_nTotItens := Len(_aItemPed)

		// divisao de pagina 15 itens por pagina.
		_nPagTot := 1

		// recalcula quantidade de itens restantes
		_nTotItens -= 20

		// quantidade de paginas adicionais
		If Int(_nTotItens / 20) > 0
			_nPagTot += Int(_nTotItens / 20)

			_nTotItens -= 20 * Int(_nTotItens / 20)
		EndIf

		If _nTotItens > 0
			_nPagTot ++
		EndIF

		//Pagina Atual
		_nPagAtu := 1
		/*
		FIM - Logica para quantidade de Paginas
		*/
		li    := 0
		SfCabecPre(_aCabPed,_nPagAtu,_nPagTot)

		nItem := 0
		For nG := 1 To Len(_aItemPed)
			nItem += 1
			IF li >= 20

				If _nPagTot <> _nPagAtu
					oReport:Line(2900,30,2900,2200)
					oReport:SayAlign(2900,030,"CONTINUA ..."               ,_oFont02n:oFont,500,200,,0)
				Else

				EndIf
				oReport:EndPage()
				_nPagAtu ++
				li    := 0
				SfCabecPre(_aCabPed,_nPagAtu,_nPagTot)

			EndIf
			SfImpItem(nItem,@li,@nTotVal)
			li++
		Next nG

		_nTmpLin += 20
		oReport:Line(_nPrinLin+_nTmpLin,30,_nPrinLin+_nTmpLin,2200)
		oReport:SayAlign(_nPrinLin+_nTmpLin,1880,"TOTAL: " + Alltrim(TransForm(nTotVal,PesqPict("SC6","C6_VALOR",16,2))),_oFont02n:oFont,300,200,,1)

		// finaliza pagina
		oReport:EndPage()
		li := 0
		If mv_par09 == 2
			(_cAliasSC5)->(dbSkip())
		EndIf
	EndDo

	oReport:Print()

	dbSelectArea(_cAliasSC5)
	(_cAliasSC5)->(dbCloseArea())
Return

//*** Impreção do cabeçalho do relatório.
Static Function SfCabecPre(_aCabPed,mvAtuPag,mvTotPag)
	Local cPictCgc  := ""
	Local _cCGCCli  := ""
	Local _cCGCEmp  := ""
	Local _cInscri  := ""
	Local _cCli  := ""
	Local _cEnd1  := ""
	Local _cEnd2  := ""
	Local nInicio   := 250

	//Posiciona registro no cliente do pedido
	dbSelectArea("SA1")
	dbSeek(xFilial("SA1") + _aCabPed[2] + _aCabPed[3])  //C5_CLIENTE + C5_LOJACLI
	cPictCgc := PesqPict("SA1","A1_CGC")

	_cCGCCli := subs(Transform(SA1->A1_CGC,PicPesFJ(RetPessoa(SA1->A1_CGC))),1,at("%",transform(SA1->A1_CGC,PicPes(RetPessoa(SA1->A1_CGC))))-1)
	_cInscri := "IE: "+SA1->A1_INSCR
	_cCGCEmp := Iif(cPaisLoc=="BRA","CGC: ",Alltrim(Posicione('SX3',2,'A1_CGC','SX3->X3_TITULO'))+":")+Transform(SM0->M0_CGC,cPictCgc)+ " " +Subs(SM0->M0_CIDCOB,1,15)

	_cCli    := Alltrim(SA1->A1_COD+"/"+SA1->A1_LOJA+" "+SA1->A1_NOME)
	_cEnd1   := "Rua: " + Alltrim(IF( !Empty(SA1->A1_ENDENT) .And. SA1->A1_ENDENT # SA1->A1_END,SA1->A1_ENDENT, SA1->A1_END ))
	_cEnd2   := "CEP: " + IF( !Empty(SA1->A1_CEPE) .And. SA1->A1_CEPE # SA1->A1_CEP,SA1->A1_CEPE, SA1->A1_CEP )+" "+;
		"Munic.: " + IF( !Empty(SA1->A1_MUNE) .And. SA1->A1_MUNE # SA1->A1_MUN,SA1->A1_MUNE, SA1->A1_MUN )+" "+;
		"UF: " + IF( !Empty(SA1->A1_ESTE) .And. SA1->A1_ESTE # SA1->A1_EST,SA1->A1_ESTE, SA1->A1_EST )

	//Cria nova Pagina
	oReport:StartPage()
	//Inicializa Linha
	_nPrinLin := nInicio

	// Box dados do cliente
	oReport:Box(_nPrinLin,0030,_nPrinLin+0750,2200)
	// Box Logo
	oReport:Box(_nPrinLin,0030,_nPrinLin+0300,2200)
	// Box Cabeçalho
	oReport:Box(_nPrinLin,0650,_nPrinLin+0300,2200)
	// coluna - antes "PRÉ - NOTA"
	// logo
	oReport:SayBitmap(_nPrinLin+10,0060,_cImagem,500,250)
	//Tiltulo
	oReport:SayAlign(_nPrinLin         ,1100,"PRÉ - NOTA"                                            ,_oFont01n:oFont,500,200,,2)
	If mv_par09 == 2
		oReport:SayAlign(_nPrinLin+100     ,0900,"(Pedido  : "+_aCabPed[7] + " / Emissão : " + Dtoc((Stod(_aCabPed[6]))) + ")",_oFont02:oFont,900,200,,2)
	EndIF
	// data e hora de impressao
	oReport:SayAlign(_nPrinLin      ,1680,"Dt Impr: "+DtoC(Date())+" "+Time(),_oFont02:oFont,500,200,,1)
	// filial
	oReport:SayAlign(_nPrinLin + 050,1680,"Filial: "+Alltrim(SM0->M0_CODFIL)+"-"+Alltrim(SM0->M0_FILIAL),_oFont02:oFont,500,200,,1)
	// controle de paginas
	oReport:SayAlign(_nPrinLin + 200,1680,"Pág.: "+Alltrim(Str(mvAtuPag))+" de "+Alltrim(Str(mvTotPag)),_oFont02:oFont,500,200,,1)

	_nPrinLin += 350
	_nTmpLin := 60

	// dados do cliente
	oReport:Say(_nPrinLin+_nTmpLin,0080,"Cliente : "+_cCli                               ,_oFont02:oFont)
	oReport:Say(_nPrinLin+_nTmpLin,0980,"CNPJ/CPF: "+Alltrim(_cCGCCli) ,_oFont02:oFont)
	_nTmpLin += 80
	oReport:Say(_nPrinLin+_nTmpLin,0080,"Endereço: "+_cEnd1                              ,_oFont02:oFont)
	oReport:Say(_nPrinLin+_nTmpLin,0980, _cInscri                      ,_oFont02:oFont)
	_nTmpLin += 80
	oReport:Say(_nPrinLin+_nTmpLin,0080,_cEnd2                                           ,_oFont02:oFont)
	_nTmpLin += 80

	If mv_par09 == 2
		If !(Empty((_cAliasSC5)->C5_MENNOTA))
			If Len(Alltrim((_cAliasSC5)->C5_MENNOTA)) > 90
				oReport:Say(_nPrinLin+_nTmpLin,0080,"MENSAGEM PARA NOTA FISCAL: " + SubStr(Alltrim((_cAliasSC5)->C5_MENNOTA),1,90),_oFont02:oFont,1000)
				_nTmpLin += 80
				oReport:Say(_nPrinLin+_nTmpLin,0080,SubStr(Alltrim((_cAliasSC5)->C5_MENNOTA),91,10),_oFont02:oFont,1000)
			Else
				oReport:Say(_nPrinLin+_nTmpLin,0080,"MENSAGEM PARA NOTA FISCAL: " + Alltrim((_cAliasSC5)->C5_MENNOTA),_oFont02:oFont,1000)
			EndIf
		EndIf
	EndIf
	_nTmpLin += 80
	_nPrinLin += 500
	If mv_par09 == 2
		oReport:SayAlign(_nPrinLin,0080,"Item"             ,_oFont02n:oFont,0300,200,,)
		oReport:SayAlign(_nPrinLin,0180,"Codigo"           ,_oFont02n:oFont,0300,200,,)
		oReport:SayAlign(_nPrinLin,0340,"Desc. do Serviço" ,_oFont02n:oFont,1000,200,,)
		oReport:SayAlign(_nPrinLin,1000,"Quant."           ,_oFont02n:oFont,0300,200,,1)
		oReport:SayAlign(_nPrinLin,1440,"Valor Unit."      ,_oFont02n:oFont,0300,200,,1)
		oReport:SayAlign(_nPrinLin,1880,"Vl.Tot."          ,_oFont02n:oFont,0300,200,,1)

		_nPrinLin += 100

	EndIf
Return()

//*** Impreção dos itens do Pedido.
Static Function SfImpItem(nItem,li,nTotVal)

	Local _cDescPro := ""

	If mv_par09 == 1
		oReport:SayAlign(_nPrinLin,0080,_aItemPed[nItem],_oFont02:oFont,1000,300,, )
	Else
		dbSelectArea("SB1")
		dbSeek(xFilial("SB1")+_aItemPed[nItem][2])  //C6_PRODUTOfelipe.limas
		_cDescPro := SUBS(IIF(Empty(_aItemPed[nItem][03]),SB1->B1_DESC, _aItemPed[nItem][03]),1,30)

		nTotVal += _aItemPed[nItem][06]				//C6_VALOR

		oReport:SayAlign(_nPrinLin,0080,_aItemPed[nItem][01]                                               ,_oFont02:oFont,0050,300,, )
		oReport:SayAlign(_nPrinLin,0180,_aItemPed[nItem][02]                                               ,_oFont02:oFont,0150,300,, )
		oReport:SayAlign(_nPrinLin,0340,_cDescPro                                                          ,_oFont02:oFont,1000,300,, )
		oReport:SayAlign(_nPrinLin,1000, Alltrim(TransForm(_aItemPed[nItem][04],PesqPictQt("C6_QTDVEN")))  ,_oFont02:oFont,0300,200,,1)
		oReport:SayAlign(_nPrinLin,1440, Alltrim(TransForm(_aItemPed[nItem][05]     ,"@E 99,999,999.9999")),_oFont02:oFont,0300,200,,1)
		oReport:SayAlign(_nPrinLin,1880, Alltrim(TransForm(_aItemPed[nItem][06]     ,"@E 99,999,999.9999")),_oFont02:oFont,0300,200,,1)
	EndIf

	_nPrinLin += 80
Return()