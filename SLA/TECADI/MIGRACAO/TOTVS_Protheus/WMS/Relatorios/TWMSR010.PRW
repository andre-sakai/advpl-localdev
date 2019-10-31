#Include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para impressao de etiquetas do WMS               !
!                  ! - Identificacao do endereco                             !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 09/2012 !
+------------------+---------------------------------------------------------+
!Observacoes       !                                                         !
+------------------+--------------------------------------------------------*/

User Function TWMSR010(mvEndereco)

	// perguntas
	local _cPerg := PadR("TWMSR010",10)
	local _aPerg := {}

	// default do parametro
	default mvEndereco := {}

	// monta a lista de perguntas
	aAdd(_aPerg,{"Armazém De ?"      ,"C",TamSx3("BE_LOCAL")[1],0,"G",,"Z12"}) //mv_par01
	aAdd(_aPerg,{"Armazém Até ?"     ,"C",TamSx3("BE_LOCAL")[1],0,"G",,"Z12"}) //mv_par02
	aAdd(_aPerg,{"Endereço De ?"     ,"C",TamSx3("BE_LOCALIZ")[1],0,"G",,"SBE"}) //mv_par03
	aAdd(_aPerg,{"Endereço Até ?"    ,"C",TamSx3("BE_LOCALIZ")[1],0,"G",,"SBE"}) //mv_par04
	aAdd(_aPerg,{"Etiqueta De ?"     ,"C",TamSx3("Z11_CODETI")[1],0,"G",,"",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par05
	aAdd(_aPerg,{"Etiqueta Até ?"    ,"C",TamSx3("Z11_CODETI")[1],0,"G",,"",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par06
	aAdd(_aPerg,{"Ordem Impressão ?" ,"N",1,0,"C",{"Lado+Predio+Andar","Lado+Predio+Posicao"},""}) //mv_par07
	aAdd(_aPerg,{"Rua De?"           ,"C",2,0,"G",,""}) //mv_par08
	aAdd(_aPerg,{"Rua Até?"          ,"C",2,0,"G",,""}) //mv_par09
	aAdd(_aPerg,{"Lado:"             ,"N",1,0,"C",{"Ambos","A","B"},,}) //mv_par10
	aAdd(_aPerg,{"Prédio De?"        ,"C",2,0,"G",,""}) //mv_par11
	aAdd(_aPerg,{"Prédio Até?"       ,"C",2,0,"G",,""}) //mv_par12
	aAdd(_aPerg,{"Andar De?"         ,"C",2,0,"G",,""}) //mv_par13
	aAdd(_aPerg,{"Andar Até?"        ,"C",2,0,"G",,""}) //mv_par14

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// abre os parametros
	If ! Pergunte(_cPerg, .t.)
		Return(.f.)
	EndIf

	// processa a impressao do boleto
	Processa({|lEnd| U_WMSR010A(mv_par01,mv_par02,mv_par03,mv_par04,mv_par05,mv_par06,mv_par07,mv_par08,mv_par09,mv_par10,mv_par11,mv_par12, mv_par13, mv_par14) })

Return

User Function WMSR010A(mvLocDe, mvLocAte, mvEndDe, mvEndAte, mvEtiqDe, mvEtiqAte, mvFiltro, mvRuaDe, mvRuaAte, mvLado, mvPredioDe, mvPredioAte, mvAndarDe, mvAndarAte)

	// controle de transação
	local _oDlgSelImp, _oCBxTpEtiq, _oBtnEtqOk, _oBtnEtqCan
	// impressoras disponiveis no windows
	local _aImpWindows := U_FtRetImp()
	// retorna a pasta temporaria da maquina
	local _cPathTemp := AllTrim(GetTempPath())
	local _cTmpEtiq
	local _cQryEtiq := ""
	local _nQtdReg := 0
	// quantidade de etiquetas
	local _nQtdTotal := 0
	local _nEtiq := 0
	// codigo da etiqueta
	local _cCodEtiq := ""
	local _lOk := .f.
	local _cImpSelec := U_FtImpZbr()
	// variaveis temporarias da estrutura do endereco
	local _cTmpLocal, _cTmpDescri, _cTmpRua, _cTmpLado, _cTmpPredio, _cTmpAndar, _cTmpPosicao
	// arquivos temporarios
	local _cTmpArquivo, _cTmpBat, _nTmpHdl
	// valida o arquivo gerado
	local _lImpressOk := .f.
	// tipo da estrutura
	local _cTpEstFis := ""

	// tela para selecionar as impressoras de etiquetas disponiveis
	_oDlgSelImp := MSDialog():New(000,000,080,300,"Impressoras de etiquetas",,,.F.,,,,,,.T.,,,.T. )
	_oCBxTpEtiq := TComboBox():New( 004,004,{|u| If(PCount()>0,_cImpSelec:=u,_cImpSelec)},_aImpWindows,142,010,_oDlgSelImp,,,,,,.T.,,"",,,,,,,_cImpSelec )
	_oBtnEtqOk  := SButton():New( 018,100,1,{ || _lOk := .t. , _oDlgSelImp:End() },_oDlgSelImp,,"", )
	_oBtnEtqCan := SButton():New( 018,128,2,{ || _oDlgSelImp:End() },_oDlgSelImp,,"", )

	_oDlgSelImp:Activate(,,,.T.)

	If (_lOk)

		// grava informacoes da impressora selecionada
		U_FtImpZbr(_cImpSelec)

		// remove texto e mantem só o caminho
		_cImpSelec := Separa(_cImpSelec,"|")[2]

		// define o arquivo temporario com o conteudo da etiqueta
		_cTmpArquivo := _cPathTemp+"wms_etiq_endereco.txt"

		// cria e abre arquivo texto
		_nTmpHdl := fCreate(_cTmpArquivo)

		// testa se o arquivo de Saida foi Criado Corretamente
		If (_nTmpHdl == -1)
			MsgAlert("O arquivo de nome "+_cTmpArquivo+" nao pode ser executado! Verifique os parametros.","Atencao!")
			Return(.f.)
		Endif

		// monta query para buscar os dados
		_cQryEtiq := "SELECT BE_LOCAL, BE_LOCALIZ, BE_ZIDETIQ, SBE.R_E_C_N_O_ SBERECNO, DC8_TPESTR "
		// cadastro de enderecos
		_cQryEtiq += "FROM "+RetSqlName("SBE")+" SBE "
		// cad. estrutura fisica
		_cQryEtiq += "LEFT JOIN "+RetSqlName("DC8")+" DC8 ON "+RetSqlCond("DC8")+" AND DC8_CODEST = BE_ESTFIS "
		// filtro padrao
		_cQryEtiq += "WHERE "+RetSqlCond("SBE")+" "
		// armazem
		_cQryEtiq += "AND BE_LOCAL   BETWEEN '"+mvLocDe+"' AND '"+mvLocAte+"' "
		// endereco
		_cQryEtiq += "AND BE_LOCALIZ BETWEEN '"+mvEndDe+"' AND '"+mvEndAte+"' "
		// codigo da etiqueta
		_cQryEtiq += "AND BE_ZIDETIQ BETWEEN '"+mvEtiqDe+"' AND '"+mvEtiqAte+"' "
		// filtro de rua De-Ate
		_cQryEtiq += "AND SUBSTRING(BE_LOCALIZ, 1, 2) BETWEEN '"+mvRuaDe+"' AND '"+mvRuaAte+"' "
		// se o lado não for selecionado, a opção AMBOS é escolhida
		If (mvLado == 2)
			_cQryEtiq += "AND SUBSTRING(BE_LOCALIZ, 3, 1) = 'A'  "
		ElseIf (mvLado == 3)
			_cQryEtiq += "AND SUBSTRING(BE_LOCALIZ, 3, 1) = 'B'  "
		EndIf
		// predio De-Ate
		_cQryEtiq += " AND SUBSTRING(BE_LOCALIZ, 4, 2) BETWEEN '"+mvPredioDe+"' AND '"+mvPredioAte+"' "
		// andar De-Ate
		_cQryEtiq += " AND SUBSTRING(BE_LOCALIZ, 6, 2) BETWEEN '"+mvAndarDe+"' AND '"+mvAndarAte+"' "
		// ordem dos dados
		If (mvFiltro==1) // lado + predio + andar
			_cQryEtiq += "ORDER BY BE_LOCAL, BE_LOCALIZ "
		ElseIf (mvFiltro==2) // lado + predio + posicao
			_cQryEtiq += "ORDER BY BE_LOCAL, SUBSTRING(BE_LOCALIZ,1,5), SUBSTRING(BE_LOCALIZ,8,5) "
		EndIf

		memowrit("c:\query\twmsr010.txt",_cQryEtiq)

		If Select("_QRYETIQ") <> 0
			dbSelectArea("_QRYETIQ")
			dbCloseArea()
		EndIf

		// executa a query
		dbUseArea(.T.,'TOPCONN',TCGENQRY(,,_cQryEtiq),"_QRYETIQ",.F.,.T.)
		dbSelectArea("_QRYETIQ")

		If _QRYETIQ->(Eof())
			MsgStop("Não há etiquetas para impressão.")
			Return(.f.)
		EndIf

		// calculo da quantidade total
		dbEval({|| _nQtdReg += 1 })

		// quantidade total da regua de prcessamento
		ProcRegua(_nQtdReg)

		dbSelectArea("_QRYETIQ")
		_QRYETIQ->(dbGoTop())

		// define o conteudo inicial da etiqueta a ser impressa
		_cTmpEtiq := "CT~~CD,~CC^~CT~"+CRLF
		_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
		_cTmpEtiq += "~DG000.GRF,04608,016,"+CRLF
		_cTmpEtiq += ",::::::::::::::::::::::::::O0MA8026,O0MF802F,O0MF8029,O0MF8049,O0MF8032,O0MF80,O0MF803F,O040H04,Y02,Y0E,X03E,X064,X03C,R050K07,Q0IF80I02,P03FHFE0H0H1,P0KF8002A,O01FJFC0H0C,"+;
			"O03FJFE0028,O03FJFE007F,O07FKFI0A,O07FE03FF0H01,O0HF800FF802B,O0FE0H07F8009,O0FE0H03F8028,O0FE0H03F8039,O0FE0H03F803A,O0FC0H01F80,O0FC0H03F802E,O0FC0H01F8023,O0FC0H03F802B,O0FC0H01F8041,"+;
			"O0MF802A,O0MF801C,O0MF80,::O0MF8026,O0BAHABAA802B,X049,X029,X0H3,X0H2,,U03803E,T01F8006,T0HF8038,S03FF8035,S0IF802A,R07FHF80,Q03FIF802B,Q0KF0149,P0KF800A8,O01FJF8003F,O03FJF8003F,O0JF9F8,"+;
			"O0IF81F80020,O0HFC01F80031,O0HFE01F8002B,O0IFC1F80047,O0JF9F80H02,O03FJF80H03,P0KF80H0E,P01FIFC0034,Q03FIF802C,R0JF801E,R03FHF8003,S07FF80,S03FF803E,T07F8030,U0F802E,U038007,V08038,Q04020I03F,"+;
			"P03C0380H0H2,P07C03E0I01,P0FC03F8003A,O01FC03F80H0C,O03FE03FE0028,O07FC03FE003F,O0HFC03FE002A,O0HFH01FF0H01,O0FE0H0HFI03,N01FE0H07F001C,N01FC0H03F8024,N01FC0H03F8034,N01F80H03F800E,N01F80H03F8001,"+;
			"N01F80H03F80,:N01F80H03F8022,N01FC0H07F8049,O0FE0H0HF8028,O0HFH01FF0H09,O0HFE03FE003F,O07FJFE,O03FJFC,:O01FJF8,P0KFJ07,P03FHFC0H01E,P01FHFJ024,Q03FA0I03A,Y07,,:O0H2I03F8022,O0FC1F83F8041,O0FE1F83F8023,"+;
			"O0FC1F83F8036,O0FE1F83F800A,O0FC1F83F80,O0FE1F83F803E,O0FC1F83F80,O0FE1F83F8020,O0FC1F83F8040,O0FE1F83F803E,O0FC1F83F80,O0FE3FA3F8020,O0MF80,O0MF802E,O0MF8029,O0MF802B,O0MF803B,O0MF8022,O0MF80,O0MF803A,,"+;
			"Y08,X026,X02B,X041,O0FE0L0H2,O0FE0L03E,O0FE0,O0FE0L01C,O0FE0L02A,O0FE0L021,O0FEAJA8023,O0MF8023,O0MF802A,O0MF801C,O0MF8002,O0MF8001,O0MF80,O0MF8001,O0FEAJA803F,O0FE0,:::::,::::::::::"+;
			"R02FHF80,Q03FHF810,P03FHFE0,P0JFC0,O03FIF80,O07FIF01C0,N03FJF03F8,N03FIFE07FF,N07FIFE0FHFE0,N0KFC1FIF0,N0KFC3FIFE,M01FJF83FJF,M01FJF87FJF80,M03FJF07FJFC0,M03FJF0FKFE0,M07FJF0FLF0,M0KFE02FKF8,M0LFI07FIFC,"+;
			"M0MFA003FHFE,M0NFH01FHFE,L09FNF800FHF80,K019FOF801FF80,K0H3QFA03FC0,K0H3RF807C0,K073FQFE81E0,K073FRFC030,K0E3FSF8,K0E7FSFE,J01E7FTFC0,J01E7FUF0,J03E7FUF8,J03CFVFE,J03CFWF,:J038FWF80,J07CFWFC0,J078FWFE0,"+;
			"J079FWFE0,::J0F9FWFE0,J071FWFE0,J0FBFWFE0,J0F1FWFE0,J0F3FWFE0,::J073FWFE0,J0F3FJF8FQFE0,J073FJF803FOFC0,J073FJF8002FNFE0,J073FJF80H01FMFC0,J063FJF8E80H0MFC0,J073FJF0FF0H01FKFC0,J023FJF0FHF8003FJFC0,"+;
			"J023FJF0FIFI07FIFC0,J023FIFE0FIFE0H0JF80,K03FJF1FJFC003FHF80,K03FIFE1FKFI0IF80,K03FJF1FKFE007FF80,K03FIFE1FLF801FF80,K03FJF1FLFE007F,K03FIFE1FLFE003F80,K03FIFE1FMF801F,K03FIFE1FMFC00F,K03FIFE1FMFE00F,"+;
			"K03FIFE3FNFH06,K03FIFE1FNFH06,K03FIFE1FNF806,K03FJF1FNF806,K03FIFE1FNF802,K01FJF1FNFH04,K01FIFE1FNFH04,K01FJF1FMFE008,L0KF1FMFC008,L0KF1FMF8020,L07FIF8FLFE0A80,L03FIF0FLFC,L03FIF8FLF8,M0JF87FJFE0,"+;
			"M03FHF87FJF80,M01FHF83FIFC,N0IF81FHFE0,N03FFC07FC,O0HFC,O07FC,P0FE,P03F,Q03E2,R038,,::::::^XA"+CRLF
		// grava a Linha no Arquivo Texto
		fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

		// varre todos os itens
		While _QRYETIQ->(!Eof())

			// incremento da regua
			IncProc()

			// tipo da estrutura
			_cTpEstFis := _QRYETIQ->DC8_TPESTR

			// posiciona no cadastro
			dbSelectArea("SBE")
			SBE->(DbGoTo( _QRYETIQ->SBERECNO ))

			// armazena o codigo da etiqueta
			_cCodEtiq := SBE->BE_ZIDETIQ

			// se nao ha codigo de etiqueta, gera novo
			If (Empty(_cCodEtiq))
				// conteudo passado como parametro
				_aTmpConteudo := {SBE->BE_LOCAL, SBE->BE_LOCALIZ}
				// gera codigo da etiqueta
				_cCodEtiq := U_FtGrvEtq("02",_aTmpConteudo)
				// atualiza o cadastro
				dbSelectArea("SBE")
				RecLock("SBE")
				SBE->BE_ZIDETIQ := _cCodEtiq
				SBE->(MsUnLock())
			EndIf

			// reinicia variaveis temporarias da estrutura do endereco
			_cTmpLocal   := SBE->BE_LOCAL
			_cTmpDescri  := AllTrim(SBE->BE_DESCRIC)
			_cTmpRua     := SubStr(SBE->BE_LOCALIZ,1,2)
			_cTmpLado    := SubStr(SBE->BE_LOCALIZ,3,1)
			_cTmpPredio  := SubStr(SBE->BE_LOCALIZ,4,2)
			_cTmpAndar   := SubStr(SBE->BE_LOCALIZ,6,2)
			_cTmpPosicao := SubStr(SBE->BE_LOCALIZ,8,5)

			// define o conteudo da etiqueta
			_cTmpEtiq := "^MMT"+CRLF
			_cTmpEtiq += "^PW480"+CRLF
			_cTmpEtiq += "^LL1055"+CRLF
			_cTmpEtiq += "^LS0"+CRLF
			_cTmpEtiq += "^FT0,1024^XG000.GRF,1,1^FS"+CRLF
			_cTmpEtiq += "^BY6,3,166^FT434,963^BCB,,N,N"+CRLF
			_cTmpEtiq += "^FD>:"+_cCodEtiq+"^FS"+CRLF
			_cTmpEtiq += "^FO144,20^GB0,992,1^FS"+CRLF
			_cTmpEtiq += "^FO105,19^GB0,993,1^FS"+CRLF
			_cTmpEtiq += "^FT92,737^A0B,23,21^FH\^FDARMZ: "+_cTmpLocal+"^FS"+CRLF
			_cTmpEtiq += "^FT467,638^A0B,37,36^FH\^FD"+Transf(_cCodEtiq,"@R 99999-99999")+"^FS"+CRLF
			_cTmpEtiq += "^FT32,736^A0B,23,21^FH\^FDWMS.LOCALIZA\80\C7O^FS"+CRLF

			If (cFilAnt == "105")
				_cTmpEtiq += "^FT95,183^A0B,23,21^FH\^FDFilial: "+AllTrim(SM0->M0_CODFIL)+"-"+AllTrim(SubS(SM0->M0_FILIAL,8))+"^FS"+CRLF
			Else
				_cTmpEtiq += "^FT95,183^A0B,23,21^FH\^FDFilial: "+AllTrim(SM0->M0_CODFIL)+"-"+AllTrim(SM0->M0_FILIAL)+"^FS"+CRLF
			EndIf

			_cTmpEtiq += "^FO8,743^GB97,0,2^FS"+CRLF
			// 1-Porta Palete / 2-Picking
			If (_cTpEstFis $ "1/2")
				_cTmpEtiq += "^FT138,319^A0B,28,28^FH\^FDPOSI\80\C7O^FS"+CRLF
				_cTmpEtiq += "^FT138,618^A0B,28,28^FH\^FDANDAR^FS"+CRLF
				_cTmpEtiq += "^FT138,765^A0B,28,28^FH\^FDPR\90DIO^FS"+CRLF
				_cTmpEtiq += "^FT239,483^A0B,93,177^FH\^FD"+_cTmpPosicao+"^FS"+CRLF
				_cTmpEtiq += "^FT241,620^A0B,93,91^FH\^FD"+_cTmpAndar+"^FS"+CRLF
				_cTmpEtiq += "^FT241,764^A0B,93,91^FH\^FD"+_cTmpPredio+"^FS"+CRLF
				_cTmpEtiq += "^FT241,1016^A0B,93,91^FH\^FD"+_cTmpRua+"^FS"+CRLF
				_cTmpEtiq += "^FT241,879^A0B,93,91^FH\^FD"+_cTmpLado+"^FS"+CRLF
				_cTmpEtiq += "^FT138,997^A0B,28,28^FH\^FDRUA^FS"+CRLF
				_cTmpEtiq += "^FT138,883^A0B,28,28^FH\^FDLADO^FS"+CRLF
				// Demais
			Else
				_cTmpEtiq += "^FT241,1016^A0B,93,91^FH\^FD"+_cTmpDescri+"^FS"+CRLF
			EndIf

			_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
			_cTmpEtiq += "^XA"+CRLF

			// grava a Linha no Arquivo Texto
			fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

			// define conteudo no arquivo
			_lImpressOk := .t.

			// incrementa quantidade de impressoes
			dbSelectArea("Z11")
			Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
			Z11->(dbSeek( xFilial("Z11")+_cCodEtiq ))
			RecLock("Z11")
			Z11->Z11_QTDIMP += 1
			MsUnLock()

			// proximo produto
			_QRYETIQ->(dbSkip())

		EndDo

		// final do arquivo texto
		_cTmpEtiq := "ID000.GRF^FS^XZ"+CRLF
		// grava a Linha no Arquivo Texto
		fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

		// fecha arquivo texto
		fClose(_nTmpHdl)

		// define o arquivo .BAT para execucao da impressao da etiqueta
		_cTmpBat := _cPathTemp+"wms_imp_etiq.bat"
		// grava o arquivo .BAT
		MemoWrit(_cTmpBat,"copy "+_cTmpArquivo+" "+_cImpSelec)

		// executa o comando (.BAT) para impressao
		If (_lImpressOk)
			WinExec(_cTmpBat)
		EndIf

	EndIf

Return(.t.)
