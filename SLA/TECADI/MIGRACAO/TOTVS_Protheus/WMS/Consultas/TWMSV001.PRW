#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Consulta de Prog. Recebimento e Containers no Patio     !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp       ! Data de Criacao ! 01/2011 !
+------------------+--------------------------------------------------------*/

User Function TWMSV001

	// dimensoes da tela
	Local _aSizeDlg	:= MsAdvSize()
	// tempo de refresh (segundos)
	Local _nSeconds := 30

	// objetos da tela
	local _oSayTit1, _oSayTit2, _oSayRefresh
	local _oBtnLegProg, _oBtnLegCont

	// cores para o browse
	local _aCorProg := {{"((_TRBPRG)->IT_SALDO==(_TRBPRG)->Z2_QUANT)","DISABLE"},{"((_TRBPRG)->IT_SALDO<>(_TRBPRG)->Z2_QUANT)","ENABLE"}}
	local _aCorCntr := {{"((_TRBCNT)->DIAS_FREE < 0)","BR_PRETO"},{"((_TRBCNT)->DIAS_FREE >= 0).and.((_TRBCNT)->DIAS_FREE<=2)","DISABLE"},{"((_TRBCNT)->DIAS_FREE >  2).and.((_TRBCNT)->DIAS_FREE<=5)","BR_AMARELO"},{"((_TRBCNT)->DIAS_FREE > 5)","ENABLE"}}

	// campos do browse (prog recebimento)
	Private _aHeadProg := {}
	Private _cArqTmp1
	Private _TRBPRG := GetNextAlias()
	Private _aStrTrb1 := {} // estrutura do arquivo de trabalho

	// campos do browse (containers)
	Private _aHeadCont := {}
	Private _cArqTmp2
	Private _TRBCNT := GetNextAlias()
	Private _aStrTrb2 := {} // estrutura do arquivo de trabalho

	// fontes utilizadas
	Private _oFnt01 := TFont():New("Tahoma",,18,,.t.)

	// alimenta os dados (1a vez)
	sfRfrDados(.f.)

	// monta o dialogo
	_oDlgProg := MSDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Programações de Entrada e Saída",,,.F.,,,,,,.T.,,,.T. )
	_oDlgProg:lMaximized := .T.

	// painel com o titulo 1
	_oPnlTitulo1 := TPanel():New(000,000,nil,_oDlgProg,,.F.,.F.,,,16,16,.T.,.F. )
	_oPnlTitulo1:Align:= CONTROL_ALIGN_TOP
	// botao de legenda
	_oBtnLegProg := TButton():New(002,003,"Legenda",_oPnlTitulo1,{||U_WMSV001A("P")},028,012,,,,.T.,,"",,,,.F. )
	// titulo
	_oSayTit1  := TSay():New(005,040,{||AllTrim(Upper(SM0->M0_FILIAL))+" - Programações de Recebimento - Entrada"},_oPnlTitulo1,,_oFnt01,.F.,.F.,.F.,.T.,CLR_GREEN)
	_oSayRefresh := TSay():New(005,300,{||"Refresh <F5>"},_oPnlTitulo1,,_oFnt01,.F.,.F.,.F.,.T.,CLR_RED)


	// browse com a listagem das programacoes de entrada
	_oPnlBrw1 := TPanel():New(000,000,nil,_oDlgProg,,.F.,.F.,,,100,100,.T.,.F. )
	_oPnlBrw1:Align:= CONTROL_ALIGN_TOP
	// browse
	_oBrwFrete := MsSelect():New(_TRBPRG,,,_aHeadProg,,,{001,001,400,1000},,,_oPnlBrw1,,_aCorProg)
	_oBrwFrete:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// painel com o titulo 2
	_oPnlTitulo2 := TPanel():New(000,000,nil,_oDlgProg,,.F.,.F.,,,16,16,.T.,.F. )
	_oPnlTitulo2:Align:= CONTROL_ALIGN_TOP
	// botao de legenda
	_oBtnLegCont := TButton():New(002,003,"Legenda",_oPnlTitulo2,{||U_WMSV001A("C")},028,012,,,,.T.,,"",,,,.F. )
	// titulo
	_oSayTit2  := TSay():New(005,040,{||"Containers - Saída"},_oPnlTitulo2,,_oFnt01,.F.,.F.,.F.,.T.,CLR_BLUE)

	// browse com a listagem dos containers
	_oBrwCont := MsSelect():New(_TRBCNT,,,_aHeadCont,,,{001,001,400,1000},,,,,_aCorCntr)
	_oBrwCont:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT


	// temporizador/Refresh da tela
	_oTimer := TTimer():New((_nSeconds*1000), {||sfRfrDados(.t.)} ,_oDlgProg)
	_oTimer:lActive := .T.

	// inclui teclas de atalho
	SetKey(VK_F5 , {|| sfRfrDados(.t.) } )

	// ativa a tela
	ACTIVATE MSDIALOG _oDlgProg CENTERED ON INIT EnchoiceBar(_oDlgProg,{||_oDlgProg:End()},{||_oDlgProg:End()})


	// fecha arquivo de trabalho
	_cArqTmp1:Delete()

	// fecha arquivo de trabalho
	_cArqTmp2:Delete()

	// limpa teclas de atalho
	SetKey(VK_F5 , {|| Nil})

Return

//** funcao usada para atualizar os dados
Static Function sfRfrDados(mvRefresh)
	MsgRun("Atualizando dados das programações e containers", "Aguarde...", {|| CursorWait(),;
																				sfDadosProg(mvRefresh) ,;
																				sfDadosCont(mvRefresh) ,;
																				CursorArrow()})
Return

//** funcao para atualizar os dados das programacoes de recebimento
Static Function sfDadosProg(mvRefresh)
	// query
	Local _cQuery := ""

	// monta a estrutura do arquivo de trabalho
	If (!mvRefresh)
		aAdd(_aStrTrb1,{"Z1_CODIGO"	,"C", TamSx3("Z1_CODIGO")[1],0})	; aAdd(_aHeadProg,{"Z1_CODIGO"	,"",RetTitle("Z1_CODIGO")})
		aAdd(_aStrTrb1,{"Z2_DOCUMEN","C", TamSx3("Z2_DOCUMEN")[1],0})	; aAdd(_aHeadProg,{"Z2_DOCUMEN"	,"",RetTitle("Z2_DOCUMEN")})
		aAdd(_aStrTrb1,{"Z1_EMISSAO","D", TamSx3("Z1_EMISSAO")[1],0})	; aAdd(_aHeadProg,{"Z1_EMISSAO"	,"",RetTitle("Z1_EMISSAO")})
		aAdd(_aStrTrb1,{"A1_NOME"	,"C", TamSx3("A1_NOME")[1],0})		; aAdd(_aHeadProg,{"A1_NOME"	,"",RetTitle("A1_NOME")})
		aAdd(_aStrTrb1,{"Z2_QUANT"	,"N", TamSx3("Z2_QUANT")[1],0})		; aAdd(_aHeadProg,{"Z2_QUANT"	,"",RetTitle("Z2_QUANT")})
		aAdd(_aStrTrb1,{"Z2_QTDREC"	,"N", TamSx3("Z2_QTDREC")[1],0})	; aAdd(_aHeadProg,{"Z2_QTDREC"	,"",RetTitle("Z2_QTDREC")})
		aAdd(_aStrTrb1,{"IT_SALDO"	,"N", 5,0})							; aAdd(_aHeadProg,{"IT_SALDO"	,"","Saldo"})

		// fecha alias do TRB
		If (Select(_TRBPRG)<>0)
			dbSelectArea(_TRBPRG)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cArqTmp1 := FWTemporaryTable():New( _TRBPRG )
		_cArqTmp1:SetFields( _aStrTrb1 )
		_cArqTmp1:Create()
		
	EndIf

	// limpa o conteudo do TRB
	(_TRBPRG)->(dbSelectArea(_TRBPRG))
	(_TRBPRG)->(__DbZap())

	// busca as movimentacoes
	_cQuery := "SELECT Z1_CODIGO, Z2_DOCUMEN, Z1_EMISSAO, A1_NOME, Z2_QUANT, Z2_QTDREC, (Z2_QUANT - Z2_QTDREC) IT_SALDO "
	// programacoes de recebimento
	_cQuery += "FROM "+RetSqlName("SZ1")+" SZ1 (nolock) "
	// itens da programacao de recebimento
	_cQuery += "INNER JOIN "+RetSqlName("SZ2")+" SZ2 (nolock)  ON Z2_FILIAL = '"+xFilial("SZ2")+"' AND Z2_CODIGO = Z1_CODIGO AND SZ2.D_E_L_E_T_ = ' ' "
	_cQuery += "AND (Z2_QUANT - Z2_QTDREC) > 0 "
	// cadastro de clientes
	_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 (nolock)  ON A1_FILIAL = '"+xFilial("SA1")+"' AND A1_COD = Z1_CLIENTE AND A1_LOJA = Z1_LOJA AND SA1.D_E_L_E_T_ = ' ' "
	// filtros
	_cQuery += "WHERE Z1_FILIAL = '"+xFilial("SZ1")+"' AND SZ1.D_E_L_E_T_ = ' '"

memowrit("c:\query\twmsv001_prog.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQuery,_aStrTrb1,_TRBPRG)

	// abre o arquivo de trabalho
	(_TRBPRG)->(dbSelectArea(_TRBPRG))
	(_TRBPRG)->(dbGoTop())

Return


//** funcao para atualizar os dados dos containers
Static Function sfDadosCont(mvRefresh)
	// query
	Local _cQuery := ""


	// monta a estrutura do arquivo de trabalho
	If (!mvRefresh)
		aAdd(_aStrTrb2,{"Z3_DTMOVIM","D", TamSx3("Z3_DTMOVIM")[1],0})	; aAdd(_aHeadCont,{"Z3_DTMOVIM","",RetTitle("Z3_DTMOVIM")})
		aAdd(_aStrTrb2,{"Z3_HRMOVIM","C", TamSx3("Z3_HRMOVIM")[1],0})	; aAdd(_aHeadCont,{"Z3_HRMOVIM","",RetTitle("Z3_HRMOVIM")})
		aAdd(_aStrTrb2,{"Z3_TPMOVIM","C", 7,0})							; aAdd(_aHeadCont,{"Z3_TPMOVIM","","Tip.Movmto"})
		aAdd(_aStrTrb2,{"Z3_PROGRAM","C", TamSx3("Z3_PROGRAM")[1],0})	; aAdd(_aHeadCont,{"Z3_PROGRAM","",RetTitle("Z3_PROGRAM")})
		aAdd(_aStrTrb2,{"A1_NOME"	,"C", TamSx3("A1_NOME")[1],0})		; aAdd(_aHeadCont,{"A1_NOME","",RetTitle("A1_NOME")})
		aAdd(_aStrTrb2,{"Z3_CONTAIN","C", TamSx3("Z3_CONTAIN")[1],0})	; aAdd(_aHeadCont,{"Z3_CONTAIN","",RetTitle("Z3_CONTAIN")})
		aAdd(_aStrTrb2,{"Z3_CONTATU","C", TamSx3("Z3_CONTATU")[1],0})	; aAdd(_aHeadCont,{"Z3_CONTATU","","Conteúdo"})
		aAdd(_aStrTrb2,{"Z3_TAMCONT","C", TamSx3("Z3_TAMCONT")[1],0})	; aAdd(_aHeadCont,{"Z3_TAMCONT","","Tamanho"})
		aAdd(_aStrTrb2,{"Z3_TIPCONT","C", 20,0})						; aAdd(_aHeadCont,{"Z3_TIPCONT","","Tipo"})
		aAdd(_aStrTrb2,{"DIAS_FREE"	,"N", 5,0})							; aAdd(_aHeadCont,{"DIAS_FREE","","Dias Free"})

		// fecha alias do TRB
		If (Select(_TRBCNT)<>0)
			dbSelectArea(_TRBCNT)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cArqTmp2 := FWTemporaryTable():New( _TRBCNT )
		_cArqTmp2:SetFields( _aStrTrb2 )
		_cArqTmp2:Create()
		
	EndIf

	// limpa o conteudo do TRB
	(_TRBCNT)->(dbSelectArea(_TRBCNT))
	(_TRBCNT)->(__DbZap())

	// busca as movimentacoes
	_cQuery := "SELECT Z3_DTMOVIM, Z3_HRMOVIM, "
	// tipo movimentacao
	_cQuery += "CASE WHEN Z3_TPMOVIM = 'E' THEN 'ENTRADA' ELSE 'SAIDA' END Z3_TPMOVIM, "
	_cQuery += "Z3_PROGRAM, "
	_cQuery += "A1_NOME, Z3_CONTAIN, "
	_cQuery += "CASE WHEN Z3_CONTATU = 'C' THEN 'CHEIO' ELSE 'VAZIO' END Z3_CONTATU, "
	_cQuery += "Z3_TAMCONT, X5_DESCRI Z3_TIPCONT, "
	// dias free
	If (SZ1->(FieldPos('Z1_DTFREE')) > 0)
		_cQuery += "DATEDIFF(DAY,GETDATE(),CAST(Z1_DTFREE AS DATETIME))"
	Else
		_cQuery += "0"
	EndIf
	_cQuery += " DIAS_FREE "
	// movimentacoes de containers/carga solta
	_cQuery += "FROM "+RetSqlName("SZ3")+" SZ3 (nolock)  "
	_cQuery += "INNER JOIN "+RetSqlName("SZ1")+" SZ1 (nolock)  ON "
	_cQuery += "      Z1_FILIAL = '"+xFilial("SZ1")+"' AND Z1_CODIGO = Z3_PROGRAM AND SZ1.D_E_L_E_T_ = ' ' "
	_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 (nolock)  ON "
	_cQuery += "      A1_FILIAL = '"+xFilial("SA1")+"' AND A1_COD = Z3_CLIENTE AND A1_LOJA = Z3_LOJA AND SA1.D_E_L_E_T_ = ' ' "
	_cQuery += "LEFT JOIN  "+RetSqlName("SX5")+" SX5 (nolock)  ON "
	_cQuery += "      X5_FILIAL = '"+xFilial("SX5")+"' AND X5_TABELA = 'ZA' AND X5_CHAVE = Z3_TIPCONT AND SX5.D_E_L_E_T_ = ' ' "
	_cQuery += "WHERE Z3_FILIAL = '"+xFilial("SZ3")+"' AND SZ3.D_E_L_E_T_ = ' ' "
	_cQuery += "AND Z3_DTSAIDA = ' ' "
	// nao pode trazer carga solta
	_cQuery += "AND Z3_TAMCONT <> 'CS' "

memowrit("c:\query\twmsv001_cont.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQuery,_aStrTrb2,_TRBCNT)

	// abre o arquivo de trabalho
	(_TRBCNT)->(dbSelectArea(_TRBCNT))
	(_TRBCNT)->(dbGoTop())

Return

//** funcao para legendas
User Function WMSV001A(mvTipo)
	Local _aCores := {}

	// programacoes de recebimento
	If (mvTipo=="P")
		// cores
		aAdd(_aCores,{"DISABLE"	,"Não Iniciada"})
		aAdd(_aCores,{"ENABLE"	,"Saldo Parcial"})
		// legenda
		BrwLegenda("Programações de Recebimento - Entrada","Status",_aCores)
	// containers
	ElseIf (mvTipo=="C")
		// cores
		aAdd(_aCores,{"BR_PRETO"	,"Passou o prazo"})
		aAdd(_aCores,{"DISABLE"		,"Restam menos de 2 dias Free"})
		aAdd(_aCores,{"BR_AMARELO"	,"Entre 3 e 5 dias Free"})
		aAdd(_aCores,{"ENABLE"		,"Acima de 5 dias Free"})
		// legenda
		BrwLegenda("Containers - Saída","Dias Free",_aCores)
	EndIf
Return