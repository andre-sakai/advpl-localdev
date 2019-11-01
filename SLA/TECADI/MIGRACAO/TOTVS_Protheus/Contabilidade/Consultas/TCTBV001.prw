#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Consulta saldo atual do estoque em valor                !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 12/2016 !
+------------------+--------------------------------------------------------*/

User Function TCTBV001()

	// browse com o saldo dos produtos
	local _aHeadSaldo := {}
	local _aColsSaldo := {}

	// objetos da tela
	local _oDlgConsSaldo
	local _oPnlCabec
	local _oSayData
	local _oGetData
	local _oBrwConsSaldo
	local _oBtnAtualiza, _oBtnFechar, _oBtnExpExcel

	// fontes utilizadas
	local _oFnt01 := TFont():New("Tahoma",,18,,.t.)

	// dimensoes da tela
	local _aSizeDlg := MsAdvSize()

	// data de referencia
	private _dDataRef := LastDay(dDataBase)

	// monta o header dos servicos do pacote logistico
	aAdd(_aHeadSaldo,{"Filial"     ,"B6_FILIAL" , PesqPict("SB6","B6_FILIAL") , TamSx3("B6_FILIAL")[1] , 0                     , Nil,Nil,"C",Nil,"R",,,".F."  })
	aAdd(_aHeadSaldo,{"Cód.Cliente","B6_CLIFOR" , PesqPict("SB6","B6_CLIFOR") , TamSx3("B6_CLIFOR")[1] , 0                     , Nil,Nil,"C",Nil,"R",,,".F."  })
	aAdd(_aHeadSaldo,{"Loja"       ,"B6_LOJA"   , PesqPict("SB6","B6_LOJA")   , TamSx3("B6_LOJA")[1]   , 0                     , Nil,Nil,"C",Nil,"R",,,".F."  })
	aAdd(_aHeadSaldo,{"Cliente"    ,"A1_NOME"   , PesqPict("SA1","A1_NOME")   , TamSx3("A1_NOME")[1]   , 0                     , Nil,Nil,"C",Nil,"R",,,".F."  })
	aAdd(_aHeadSaldo,{"Produto"    ,"B6_PRODUTO", PesqPict("SB6","B6_PRODUTO"), TamSx3("B6_PRODUTO")[1], 0                     , Nil,Nil,"C",Nil,"R",,,".F."  })
	aAdd(_aHeadSaldo,{"Prc.Unit"   ,"B6_PRUNIT" , PesqPict("SB6","B6_PRUNIT") , TamSx3("B6_PRUNIT")[1] , TamSx3("B6_PRUNIT")[2], Nil,Nil,"N",Nil,"R",,,".F."  })
	aAdd(_aHeadSaldo,{"Saldo Quant","QTD_SALDO" , PesqPict("SB6","B6_SALDO")  , TamSx3("B6_SALDO")[1]  , TamSx3("B6_SALDO")[2] , Nil,Nil,"N",Nil,"R",,,".F."  })
	aAdd(_aHeadSaldo,{"Saldo Valor","VLR_SALDO" , PesqPict("SB6","B6_PRUNIT") , TamSx3("B6_PRUNIT")[1] , TamSx3("B6_PRUNIT")[2], Nil,Nil,"N",Nil,"R",,,".F."  })

	// monta a tela com os dados de todos os servicos do pacote logitico
	_oDlgConsSaldo := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Consulta Saldo Estoque em Valor",,,.F.,,,,,,.T.,,,.T. )
	_oDlgConsSaldo:lMaximized := .T.

	// painel com o titulo
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgConsSaldo,,.F.,.F.,,,24,24,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// data de referencia
	_oSayData := TSay():New(007,005,{||"Data Limite:"},_oPnlCabec,,_oFnt01,.F.,.F.,.F.,.T.)
	_oGetData := TGet():New(005,055,{|u| If(PCount()>0,_dDataRef:=u,_dDataRef)},_oPnlCabec,080,012, Nil, Nil,,,_oFnt01,,,.T.,"",,{|| .t. },.F.,.F.,,.F.,.F.,"","_dDataRef",,)

	// botao consultar
	_oBtnAtualiza := TButton():New(005,145,"Atualizar",_oPnlCabec,{|| sfSelDados(@_oBrwConsSaldo) },040,015,,_oFnt01,,.T.,,"",,,,.F. )

	// botao consultar
	_oBtnExpExcel := TButton():New(005,190,"Exp.Excel",_oPnlCabec,{|| U_FtExpExc("Saldo em "+DtoC(_dDataRef), _aHeadSaldo, _oBrwConsSaldo:aCols) },040,015,,_oFnt01,,.T.,,"",,,,.F. )

	// botao fechar
	_oBtnFechar := TButton():New(005,((_aSizeDlg[5]/2)-35),"Fechar",_oPnlCabec,{|| _oDlgConsSaldo:End() },030,015,,_oFnt01,,.T.,,"",,,,.F. )

	// browse com os dados da consulta
	_oBrwConsSaldo := MsNewGetDados():New(000,000,1000,1000,Nil,'AllwaysTrue()','AllwaysTrue()','',,,,'AllwaysTrue()','','AllwaysTrue()', _oDlgConsSaldo, _aHeadSaldo, _aColsSaldo, Nil)
	_oBrwConsSaldo:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativacao da tela
	_oDlgConsSaldo:Activate(,,,.T.,)

Return

// ** funcao que carrega os dados da consulta
Static Function sfSelDados(mvBrwConsSaldo)

	MsgRun("Atualizando informacoes...", "Aguarde...", {||	CursorWait(),;
		sfAtuDados(@mvBrwConsSaldo),;
		CursorArrow()})

Return

// ** funcao que atualiza os dados do browse conforme parametros
Static Function sfAtuDados(mvBrwConsSaldo)
	// variaveis da query
	local _cQrySaldo
	// valor total
	local _nVlrTotal := 0

	// monta query para busca o saldo
	_cQrySaldo := "SELECT B6_FILIAL, "
	_cQrySaldo += "       B6_CLIFOR, "
	_cQrySaldo += "       B6_LOJA, "
	_cQrySaldo += "       A1_NOME, "
	_cQrySaldo += "       B6_PRODUTO, "
	_cQrySaldo += "       B6_PRUNIT, "
	_cQrySaldo += "       Round(( QTD_ENTRADA - QTD_SAIDA ), 4)                       QTD_SALDO, "
	_cQrySaldo += "       Round(B6_PRUNIT * Round(( QTD_ENTRADA - QTD_SAIDA ), 4), 2) VLR_SALDO, "
	_cQrySaldo += "       '.F.' IT_DELETE "
	_cQrySaldo += "FROM   (SELECT SB6ENT.B6_FILIAL, "
	_cQrySaldo += "               SB6ENT.B6_CLIFOR, "
	_cQrySaldo += "               SB6ENT.B6_LOJA, "
	_cQrySaldo += "               A1_NOME, "
	_cQrySaldo += "               SB6ENT.B6_PRODUTO, "
	_cQrySaldo += "               SB6ENT.B6_PRUNIT, "
	_cQrySaldo += "               SB6ENT.B6_QUANT                               QTD_ENTRADA, "
	_cQrySaldo += "               (SELECT Isnull(Sum(SB6SAI.B6_QUANT), 0) "
	_cQrySaldo += "                FROM   "+RetSqlName("SB6")+" SB6SAI "
	_cQrySaldo += "                WHERE  SB6SAI.B6_FILIAL = SB6ENT.B6_FILIAL "
	_cQrySaldo += "                       AND SB6SAI.D_E_L_E_T_ = ' ' "
	_cQrySaldo += "                       AND SB6SAI.B6_IDENT = SB6ENT.B6_IDENT "
	_cQrySaldo += "                       AND SB6SAI.B6_PODER3 = 'D' "
	_cQrySaldo += "                       AND SB6SAI.B6_DTDIGIT <= '"+DtoS(_dDataRef)+"') QTD_SAIDA, "
	_cQrySaldo += "					   B6_SALDO "
	_cQrySaldo += "        FROM   "+RetSqlName("SB6")+" SB6ENT "
	_cQrySaldo += "               INNER JOIN "+RetSqlName("SA1")+" SA1 "
	_cQrySaldo += "                       ON "+RetSqlCond("SA1")
	_cQrySaldo += "                          AND A1_COD = SB6ENT.B6_CLIFOR "
	_cQrySaldo += "                          AND A1_LOJA = SB6ENT.B6_LOJA "
	_cQrySaldo += "        WHERE  SB6ENT.D_E_L_E_T_ = ' ' "
	_cQrySaldo += "               AND SB6ENT.B6_FILIAL != '999' "
	_cQrySaldo += "               AND SB6ENT.B6_PODER3 = 'R' "
	_cQrySaldo += "               AND B6_SERIE != 'DI' "
	_cQrySaldo += "               AND SB6ENT.B6_DTDIGIT <= '"+DtoS(_dDataRef)+"') AS TABELA_SALDOS "
	_cQrySaldo += "WHERE  QTD_SAIDA < QTD_ENTRADA "
	_cQrySaldo += "ORDER  BY B6_FILIAL, "
	_cQrySaldo += "          B6_CLIFOR "

	// alimenta o acols com o resultado do SQL
	_aColsSaldo := U_SqlToVet(_cQrySaldo)

	// valida se tem dados
	If (Len(_aColsSaldo) == 0)
		MsgInfo("Não há dados para gerar a consulta")
		Return(.f.)
	EndIf

	// atualiza total
	aEval(_aColsSaldo,{|_nX| _nVlrTotal += _nX[8] })

	// inclui linha totalizadora
	aAdd(_aColsSaldo,{"", "", "", "VALOR TOTAL", "", 0, 0, _nVlrTotal, .F.})

	// atualiza browse
	mvBrwConsSaldo:aCols := aClone(_aColsSaldo)

Return