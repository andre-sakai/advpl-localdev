#Include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para impressao de etiquetas do WMS               !
!                  ! - Identificacao de paletes                              !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 08/2012 !
+------------------+---------------------------------------------------------+
!Observacoes       !                                                         !
+------------------+--------------------------------------------------------*/

User Function TWMSR007()

	// variavel de retorno
	local _lRet := .f.

	// rotina para impressao dos dados
	Processa ({|| _lRet := sfImpressao() },"Gerando etiquetas...")

Return(_lRet)

//** funcao para impressao dos dados
Static Function sfImpressao()

	// impressoras disponiveis no windows
	local _aImpWindows := U_FtRetImp()

	// retorna a pasta temporaria da maquina
	local _cPathTemp := AllTrim(GetTempPath())
	local _cTmpEtiq
	local _aTmpEtiq := {}

	local _cTmpPallet := ""
	local _aTmpConteudo := {}

	// numero da etiqueta
	local _nNrEtiq, _nNrCopia
	local _nTotEtiq

	// grupo de perguntas
	local _aPerg := {}
	local _cPerg := PadR("TWMSR007",10)

	local _lOk := .f.
	local _cImpSelec := ""

	local _cQryEtiq

	// arquivos temporarios
	local _cTmpArquivo, _cTmpBat, _nTmpHdl

	// reimpressao
	local _lReimprime := .f.

	// monta a lista de perguntas
	aAdd(_aPerg,{"Operação ?" ,"N",1,0,"C",{"Inclusão","Reimpressão"},""}) //mv_par01
	aAdd(_aPerg,{"Unitizador ?" ,"C",TamSx3("DC1_CODUNI")[1],0,"G",,"DC1",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par02
	aAdd(_aPerg,{"Quantidade Novos?" ,"N",3,0,"G",,""}) //mv_par03
	aAdd(_aPerg,{"Etiqueta de ?" ,"C",TamSx3("Z11_CODETI")[1],0,"G",,"",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par04
	aAdd(_aPerg,{"Etiqueta Até ?" ,"C",TamSx3("Z11_CODETI")[1],0,"G",,"",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par05
	aAdd(_aPerg,{"Nr Cópia por Etiq.?" ,"N",3,0,"G",,""}) //mv_par06

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// abre os parametros
	If !Pergunte(_cPerg,.T.)
		Return(.f.)
	EndIf

	// ajusta o parametro
	_lReimprime := (mv_par01==2)
	// quantidade total de etiquetas
	_nTotEtiq := If(_lReimprime,0,mv_par03)

	// posiciona no unitizador
	If ( ! _lReimprime )
		dbSelectArea("DC1")
		DC1->(dbSetOrder(1)) // 1- DC1_FILIAL, DC1_CODUNI
		If ( ! DC1->(dbSeek( xFilial("DC1")+mv_par02 )))
			MsgStop("Código do unitizador não encontrado!")
			Return(.f.)
		EndIf
	EndIf

	// tela para selecionar as impressoras de etiquetas disponiveis
	_oDlgSelImp := MSDialog():New(000,000,080,300,"Impressoras de etiquetas",,,.F.,,,,,,.T.,,,.T. )
	_oCBxTpEtiq := TComboBox():New( 004,004,{|u| If(PCount()>0,_cImpSelec:=u,_cImpSelec)},_aImpWindows,142,010,_oDlgSelImp,,,,,,.T.,,"",,,,,,,_cImpSelec )
	_oBtnEtqOk  := SButton():New( 018,100,1,{ || _lOk := .t. , _oDlgSelImp:End() },_oDlgSelImp,,"", )
	_oBtnEtqCan := SButton():New( 018,128,2,{ || _oDlgSelImp:End() },_oDlgSelImp,,"", )

	_oDlgSelImp:Activate(,,,.T.)

	// tela confirmada
	If (_lOk)

		// remove texto e mantem só o caminho
		_cImpSelec := Separa(_cImpSelec,"|")[2]

		// define o arquivo temporario com o conteudo da etiqueta
		_cTmpArquivo := _cPathTemp+"wms_etiq_palete.txt"

		// cria e abre arquivo texto
		_nTmpHdl := fCreate(_cTmpArquivo)

		// testa se o arquivo de Saida foi Criado Corretamente
		If (_nTmpHdl == -1)
			MsgAlert("O arquivo de nome "+_cTmpArquivo+" nao pode ser executado! Verifique os parametros.","Atencao!")
			Return(.f.)
		Endif

		// reimpressao
		If (_lReimprime)
			// monta query para buscar os dados
			_cQryEtiq := "SELECT Z11_CODETI, (Z11_QTDIMP + 1) Z11_QTDIMP "
			// cadastro de etiquetas
			_cQryEtiq += "FROM "+RetSqlName("Z11")+" Z11 "
			// filtro padrao
			_cQryEtiq += "WHERE "+RetSqlCond("Z11")+" "
			// filtro das etiquetas
			_cQryEtiq += "AND Z11_CODETI BETWEEN '"+mv_par04+"' AND '"+mv_par05+"' "
			// somente tipo 03-palete
			_cQryEtiq += "AND Z11_TIPO = '03' "
			// ordem dos dados
			_cQryEtiq += "ORDER BY Z11_CODETI"

			// alimenta o vetor com as etiquetas selecionadas
			_aTmpEtiq := U_SqlToVet(_cQryEtiq)

			// atualiza a quantidade de etiquetas
			_nTotEtiq := Len(_aTmpEtiq)
		EndIf

		// define o conteudo inicial da etiqueta a ser impressa
		_cTmpEtiq := "CT~~CD,~CC^~CT~"+CRLF
		_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
		_cTmpEtiq += "~DG000.GRF,04608,036,"+CRLF
		_cTmpEtiq += ",:::::::::::::::Q0BE8,O01FIFC0,O0LFE,O017FJF80,R02FHFE0,T05FF8,K03FKFA003FE,J01FNFH01F,J07FOFC0180,J0RFC0,I03FRFE,I03FSF80,I07FTF8,I07FTFC,I0WF,H01FVFC0,H03FWF0,"+;
			"H03FWF8,H07FWFE,H07FWFE0X07FC,H0YFE0I0KF83FIFC003FHF80I0FC0H03FHFE0H03F80,01FYFJ0KF83FIFC007FHFC0I0FC0H01FIF8007F,01FYF80H0KF83FIFE01FIFE0H01FE0H03FIFE003F80,"+;
			"01FYF80H0KF83FIFC03FJFI01FF0H03FJFH03F,03FYFC0H0KF83FIFC07FJF8003FF8003FJF803F80,03FYFC0H0KF83FIFC07FC1FFC003FF8001FJF803F,07FYFE0H0KF83FEAHA0FF807FE003FF8003F83FFC03F80,"+;
			"07FHF50157FQFE0I01FC003FC0H01FF001FE007FF8001F803FC03F,07FE80J0RFE0I03FE003FC0H01FE0H0FE007FFC003F803FE03F80,07C0M07FOFE0I01FC003FC0H01FE0H0HFH07FFC001F801FE03F,"+;
			"0E0I020I07FPFJ03FE003FE0H03FE0H020H0FEFE003F801FE03F80,0C007FIFH07FPFJ01FC003FIFC3FC0L0FCFE001F800FE03F,0803FKF8FQFJ03FE003FIFC3FC0K01FCFE003F800FE03F80,"+;
			"080FLF8FQFJ01FC003FIFC3FC0K01FC7F001F800FF03F,181FLF8FQF80H03FE003FIFC3FC0K03F87F003F800FE03F80,103FLF0FMF7FHFJ01FC003FIFC3FC0K03F87F001F800FF03F,103FLF8FLFE0FHF80H03FE003FIFC3FC0K03F87F803F800FE03F80,"+;
			"H07FLF0FLFE03FF80H01FC003FC0H01FC0K07F03F801F800FE07F,087FLF1FLFE00FF80H03FE003FE0H03FE0H0HF0FF03FC03F801FE03F80,H07FLF1FLFE003F80H01FC003FC0H01FF001FE0FJFC03F801FE03F,"+;
			"H07FKFE1FLFE600F80H03FE003FC0I0HF803FE0FJFE03F803FE03F80,H07FKFE1FLFC780780H01FC003FC0I0HFC07FC1FJFE01F807FC03F,H07FKFE3FLFEFE0380H03FE003FIFE07FJFC1FJFE03FABFFC03F80,"+;
			"H07FKFE1FLFC7F0180H01FC003FIFE07FJF81FKF01FJF803F,H07FKFE3FLF8FF8180H03FE003FIFE03FJF83FKF03FJF803F80,H07FKFC3FLF8FFC080H01FC003FIFE01FIFE03FC007F01FJFH03F,"+;
			"H03FKFC3FLF8FFE080H03FE003FIFE007FHFE07F8007F83FIFE003F80,H03FKFC7FLF8FHF080H01FC003FIFE001FHFH07F8007F81FIF8003F,H03FKF87FLF8FHF080H03FE003FIFE0H0HF800FF8003F83FHFE0H03F80,"+;
			"H03FKF87FLF1FHF,H03FKF87FLF1FFE,H01FKF07FLF1FFE10,H01FKF0FMF1FFE,H01FKF0FLFE1FFC,I0KFE0FLFE3FFC,I0KFE1FLFE7FFC0gN04,I0KFC1FLFE7FF80gN08,I07FIFC1FLFC7FF80N040H04040H040L0404004040040404,"+;
			"I07FIFC3FLFE7FF80J020F9B2FAA9A302A18EBB8C3BAEBB0BBA68E2B80,I03FIF83FLFC7FF0K02105024089028201449H94130690103044A28,I03FIF83FLFCFFE0K0218D2A788A0283C24F9A9A23EA8E1ABEF8B27,"+;
			"I01FIF07FLF8FFE0K0210510088905C203C5169E430581108051F2180,J0JF07FLF8FFE0K0H2E9B2E88BA6C2I2CB6B3E329B30BA2CB3A980,J07FFC07FLF1FFC0K034706070H0C4434434542173641E071745027,"+;
			"J07FFC0FMF9FF80,J03FF80FMF1FF,J01FF01FLFE3FE,K0FE01FLFE3FC,J083803FLFE3F8,N07FLFC7F0,J080H07FLFC7E0,N0NF8F80,J080H0NF8F80,M01FMF8E,J04003FMF18,M07FMF10,J0301FMFE,K0DFNFC,K03FNFC,"+;
			"L01FMF8,M02FKFE0,O07FIFC0,P02FHF80,,::::::::::::::::::::::::::::^XA"+CRLF
		// grava a Linha no Arquivo Texto
		fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

		// executa a impressao de acordo com a quantidade de etiquetas
		For _nNrEtiq := 1 to _nTotEtiq

			// novas etiquetas
			If (!_lReimprime)
				// conteudo passado como parametro
				_aTmpConteudo := {mv_par02,""}
				// gera codigo da etiqueta
				_cTmpPallet := U_FtGrvEtq("03",_aTmpConteudo)

				// reimpressao
			ElseIf (_lReimprime)
				_cTmpPallet := _aTmpEtiq[_nNrEtiq][1]

			EndIf

			// incrementa quantidade de impressoes
			dbSelectArea("Z11")
			Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
			Z11->(dbSeek( xFilial("Z11")+_cTmpPallet ))

			// atualiza quantidade de re-impressoes
			If (_lReimprime)
				RecLock("Z11")
				Z11->Z11_QTDIMP += 1
				MsUnLock()
			EndIf

			// gera a quantidade de cópias por etiqueta
			For _nNrCopia := 1 to mv_par06

				_cTmpEtiq := "^MMT"+CRLF
				_cTmpEtiq += "^PW759"+CRLF
				_cTmpEtiq += "^LL0440"+CRLF
				_cTmpEtiq += "^LS0"+CRLF
				_cTmpEtiq += "^FT32,128^XG000.GRF,1,1^FS"+CRLF
				_cTmpEtiq += "^BY4,3,212^FT96,396^BCN,,N,N"+CRLF
				_cTmpEtiq += "^FD>:"+_cTmpPallet+"^FS"+CRLF
				_cTmpEtiq += "^FO41,105^GB704,0,1^FS"+CRLF
				_cTmpEtiq += "^FT594,140^A0N,20,19^FH\^FDC\A2pia: "+AllTrim(Str(_nNrCopia))+" de "+AllTrim(Str(mv_par06))+"^FS"+CRLF
				_cTmpEtiq += "^FT44,148^A0N,28,28^FH\^FD"+DC1->DC1_CODUNI+"-"+AllTrim(DC1->DC1_DESUNI)+"^FS"+CRLF
				_cTmpEtiq += "^FT296,424^A0N,28,28^FH\^FD"+Transf(_cTmpPallet,"@R 99999-99999")+"^FS"+CRLF
				_cTmpEtiq += "^FT315,32^A0N,23,21^FH\^FDWMS.PALETE^FS"+CRLF
				_cTmpEtiq += "^FT559,92^A0N,23,21^FH\^FDFilial: "+AllTrim(SM0->M0_CODFIL)+"-"+AllTrim(SM0->M0_FILIAL)+"^FS"+CRLF
				_cTmpEtiq += "^FT559,32^A0N,23,21^FH\^FDDt.Imp: "+DtoC(Date())+If(!_lReimprime,""," *"+AllTrim(Str(Z11->Z11_QTDIMP))+"*")+"^FS"+CRLF
				_cTmpEtiq += "^FO307,8^GB0,97,2^FS"+CRLF
				_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
				_cTmpEtiq += "^XA"+CRLF

				// grava a Linha no Arquivo Texto
				fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

			Next _nNrCopia

		Next _nNrEtiq

		// final do arquivo texto
		_cTmpEtiq := "^ID000.GRF^FS^XZ"+CRLF
		// grava a Linha no Arquivo Texto
		fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

		// fecha arquivo texto
		fClose(_nTmpHdl)

		// define o arquivo .BAT para execucao da impressao da etiqueta
		_cTmpBat := _cPathTemp+"wms_imp_etiq.bat"
		// grava o arquivo .BAT
		MemoWrit(_cTmpBat,"copy "+_cTmpArquivo+" "+_cImpSelec)

		// executa o comando (.BAT) para impressao
		WinExec(_cTmpBat)

	EndIf

Return(.t.)
