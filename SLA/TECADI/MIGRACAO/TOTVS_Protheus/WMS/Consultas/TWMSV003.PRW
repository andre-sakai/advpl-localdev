#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Consulta de Caminhoes Disponiveis                       !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 01/2011 !
+------------------+--------------------------------------------------------*/

User Function TWMSV003

	// tempo de refresh (segundos)
	Local _nSeconds := 30

	// objetos da tela
	local _oSayTitulo2, _oSayRefresh
	local _oPnlTit2
	local _oBrwCarreg

	// dimensoes da tela
	local _oSizeDlg

	// campos do browse (caminhoes carregando)
	Private _aHeadCarr := {}
	Private _cArqTmp2
	Private _TRBCAR := GetNextAlias()
	Private _aStrTrb2  := {} // estrutura do arquivo de trabalho

	// fontes utilizadas
	Private _oFnt01 := TFont():New("Tahoma",,18,,.t.)

	_oSizeDlg := FwDefSize():New()
	_oSizeDlg:AddObject("CABEC_02"   ,  100, 20, .T., .F. ) // Totalmente dimensionavel
	_oSizeDlg:AddObject("BROWSE_02"  ,  100, 90, .T., .T. ) // Nao dimensiona Y

	// define como Proporcional
	_oSizeDlg:lProp := .T.
	_oSizeDlg:aMargins := { 3, 3, 3, 3 } // Espaco ao lado dos objetos 0, entre eles 3

	// Dispara os calculos
	_oSizeDlg:Process()

	// alimenta os dados (1a vez)
	sfDadosCarr(.f., Nil)

	// monta o dialogo
	DEFINE MSDIALOG _oDlgConsulta TITLE "Operações no Pátio" FROM _oSizeDlg:aWindSize[1],_oSizeDlg:aWindSize[2] TO _oSizeDlg:aWindSize[3],_oSizeDlg:aWindSize[4] OF oMainWnd PIXEL

	// painel com o titulo 2
	_oPnlTit2 := TPanel():New(_oSizeDlg:GetDimension("CABEC_02","LININI"),_oSizeDlg:GetDimension("CABEC_02","COLINI"),nil,_oDlgConsulta,,.F.,.F.,,,_oSizeDlg:GetDimension("CABEC_02","XSIZE"),_oSizeDlg:GetDimension("CABEC_02","YSIZE"),.T.,.F. )
	// titulo
	_oSayTitulo2  := TSay():New(005,012,{||AllTrim(Upper(SM0->M0_FILIAL))+" - Caminhões Carregando: "+AllTrim(Str((_TRBCAR)->(RecCount())))},_oPnlTit2,,_oFnt01,.F.,.F.,.F.,.T.,CLR_GREEN)
	// refres
	_oSayRefresh := TSay():New(005,300,{||"Refresh <F5>"},_oPnlTit2,,_oFnt01,.F.,.F.,.F.,.T.,CLR_RED)
	// browse com a listagem dos containers
	_oBrwCarreg := MsSelect():New(_TRBCAR,,,_aHeadCarr,,,{_oSizeDlg:GetDimension("BROWSE_02","LININI"),_oSizeDlg:GetDimension("BROWSE_02","COLINI"),_oSizeDlg:GetDimension("BROWSE_02","LINEND"),_oSizeDlg:GetDimension("BROWSE_02","COLEND")}, Nil, Nil, _oDlgConsulta)

	// temporizador/Refresh da tela
	_oTimer := TTimer():New((_nSeconds*1000), {|| sfDadosCarr(.t., @_oBrwCarreg) } ,_oDlgConsulta)
	_oTimer:lActive := .T.

	// inclui teclas de atalho
	SetKey(VK_F5 , {|| sfDadosCarr(.t., @_oBrwCarreg) } )

	// ativa a tela
	ACTIVATE MSDIALOG _oDlgConsulta CENTERED ON INIT EnchoiceBar(_oDlgConsulta,{||_oDlgConsulta:End()},{||_oDlgConsulta:End()},.T.,{},0,'',.F.,.F.,.F.,.F.,.F.,'ID_TELA01',)

	// limpa teclas de atalho
	SetKey(VK_F5 , {|| Nil })

	// fecha a Area e elimina os arquivos temporarios
	_cArqTmp2:Delete()

Return

//** funcao para atualizar os dados dos caminhoes carregando
Static Function sfDadosCarr(mvRefresh, mvBrwCarreg)
	// query
	Local _cQuery := ""
	local _aAreaTRB  := IIf(mvRefresh, (_TRBCAR)->(GetArea()), Nil)

	// monta a estrutura do arquivo de trabalho
	If ( ! mvRefresh )
		aAdd(_aStrTrb2,{"Z3_DTMOVIM","D", TamSx3("Z3_DTMOVIM")[1],0})   ; aAdd(_aHeadCarr,{"Z3_DTMOVIM","",RetTitle("Z3_DTMOVIM")})
		aAdd(_aStrTrb2,{"Z3_HRMOVIM","C", TamSx3("Z3_HRMOVIM")[1],0})   ; aAdd(_aHeadCarr,{"Z3_HRMOVIM","",RetTitle("Z3_HRMOVIM")})
		aAdd(_aStrTrb2,{"TMP_PATIO" ,"C", 13,0})                        ; aAdd(_aHeadCarr,{"TMP_PATIO" ,"","Tempo Espera"        })
		aAdd(_aStrTrb2,{"Z1_TPMOVIM","C", 12,0})                        ; aAdd(_aHeadCarr,{"Z1_TPMOVIM","","Tp.Prog"             })
		aAdd(_aStrTrb2,{"A1_NOME"	,"C", TamSx3("A1_NOME")[1],0})      ; aAdd(_aHeadCarr,{"A1_NOME"   ,"","Cliente"             })
		aAdd(_aStrTrb2,{"Z3_PLACA1"	,"C", TamSx3("Z3_PLACA1")[1],0})    ; aAdd(_aHeadCarr,{"Z3_PLACA1" ,"",RetTitle("Z3_PLACA1") })
		aAdd(_aStrTrb2,{"A4_NOME"	,"C", TamSx3("A4_NOME")[1],0})      ; aAdd(_aHeadCarr,{"A4_NOME"   ,"",RetTitle("A4_NOME")   })
		aAdd(_aStrTrb2,{"DA4_NOME"	,"C", TamSx3("DA4_NOME")[1],0})     ; aAdd(_aHeadCarr,{"DA4_NOME"  ,"",RetTitle("DA4_NOME")  })
		aAdd(_aStrTrb2,{"Z3_PROGRAM","C", TamSx3("Z3_PROGRAM")[1],0})   ; aAdd(_aHeadCarr,{"Z3_PROGRAM","","Programação"         })
		aAdd(_aStrTrb2,{"Z3_ITEPROG","C", TamSx3("Z3_ITEPROG")[1],0})   ; aAdd(_aHeadCarr,{"Z3_ITEPROG","","Item"                })
		aAdd(_aStrTrb2,{"DA3_DESC"	,"C", TamSx3("DA3_DESC")[1],0})     ; aAdd(_aHeadCarr,{"DA3_DESC"  ,"",RetTitle("DA3_DESC")  })

		// fecha alias do TRB
		If (Select(_TRBCAR)<>0)
			dbSelectArea(_TRBCAR)
			dbCloseArea()
		EndIf

		// criar um arquivo de trabalho
		_cArqTmp2 := FWTemporaryTable():New( _TRBCAR )
		_cArqTmp2:SetFields( _aStrTrb2 )
		_cArqTmp2:Create()
		
	EndIf

	// limpa o conteudo do TRB
	(_TRBCAR)->(dbSelectArea(_TRBCAR))
	(_TRBCAR)->(__DbZap())

	// busca as movimentacoes
	_cQuery := "SELECT Z3_DTMOVIM, Z3_HRMOVIM, "
	// formula para calcular o tempo
	_cQuery += "CONVERT(VARCHAR, Abs(Datediff(SECOND, CAST(Z3_DTMOVIM+' '+Z3_HRMOVIM AS DATETIME), GETDATE()) / 60 / 60 / 24)) + 'd ' "
	_cQuery += " + RIGHT('00' + CONVERT(VARCHAR, Abs(((Datediff(SECOND, CAST(Z3_DTMOVIM+' '+Z3_HRMOVIM AS DATETIME), GETDATE()) / 60) / 60) % 24)), 2)+ ':' "
	_cQuery += " + RIGHT('00' + CONVERT(VARCHAR, Abs( (Datediff(SECOND, CAST(Z3_DTMOVIM+' '+Z3_HRMOVIM AS DATETIME), GETDATE()) / 60) % 60)), 2) + ':' "
	_cQuery += " + RIGHT('00' + CONVERT(VARCHAR, Abs(  Datediff(SECOND, CAST(Z3_DTMOVIM+' '+Z3_HRMOVIM AS DATETIME), GETDATE()) % 60)), 2) TMP_PATIO, "
	// demais campos
	_cQuery += " Z3_PROGRAM, Z3_ITEPROG, CASE WHEN Z1_TPMOVIM = 'E' THEN 'ENTRADA' WHEN Z1_TPMOVIM = 'C' THEN 'CARREGAMENTO' ELSE 'N/C' END Z1_TPMOVIM, "
	_cQuery += " A1_NOME, Z3_PLACA1, DA3_DESC, A4_NOME, DA4_NOME "

	// movimentacoes de containers/carga solta
	_cQuery += "FROM "+RetSqlTab("SZ3")+" (nolock) "
	// cad. cliente
	_cQuery += "INNER JOIN "+RetSqlTab("SA1")+" (nolock)  ON "+RetSqlCond("SA1")+" AND A1_COD  = Z3_CLIENTE AND A1_LOJA = Z3_LOJA "
	// cad. transportadora
	_cQuery += "INNER JOIN "+RetSqlTab("SA4")+" (nolock)  ON "+RetSqlCond("SA4")+" AND A4_COD  = Z3_TRANSP "
	// cad. veiculos
	_cQuery += "INNER JOIN "+RetSqlTab("DA3")+" (nolock)  ON "+RetSqlCond("DA3")+" AND DA3_COD = Z3_PLACA1 "
	// cad. motoristas
	_cQuery += "INNER JOIN "+RetSqlTab("DA4")+" (nolock)  ON "+RetSqlCond("DA4")+" AND DA4_COD = Z3_MOTORIS "
	// programações
	_cQuery += "INNER JOIN "+RetSqlTab("SZ1")+" (nolock)  ON "+RetSqlCond("SZ1")+" AND Z1_CODIGO = Z3_PROGRAM "
	// filtros
	_cQuery += "WHERE "+RetSqlCond("SZ3")
	// somente entrada
	_cQuery += "AND Z3_TPMOVIM = 'E' "
	// soh pode trazer carga solta
	_cQuery += "AND Z3_TAMCONT = 'CS' "
	// condicao para caminhoes carregando no patio
	_cQuery += "AND Z3_DTMOVIM != ' ' "
	// sem data de saida
	_cQuery += "AND Z3_DTSAIDA = ' ' "

	// ordem dos dados
	_cQuery += "ORDER BY Z3_DTMOVIM, Z3_HRMOVIM, TMP_PATIO, Z1_TPMOVIM, A1_NOME, Z3_PLACA1, A4_NOME "

	memowrit("c:\query\twmsv003_sfDadosCarr.txt",_cQuery)

	// adiciona o conteudo da query para o arquivo de trabalho
	SqlToTrb(_cQuery, _aStrTrb2, _TRBCAR)

	// reposiciona cursor no browse
	If (mvRefresh)
		// area inicial do TRB
		RestArea(_aAreaTRB)
	ElseIf ( ! mvRefresh )
		// primeiro registro
		(_TRBCAR)->(dbSelectArea(_TRBCAR))
		(_TRBCAR)->(dbGoTop())
	EndIf

	// testa e atualiza browse
	If (ValType(mvBrwCarreg) == "O")
		mvBrwCarreg:oBrowse:Refresh()
	EndIf

Return