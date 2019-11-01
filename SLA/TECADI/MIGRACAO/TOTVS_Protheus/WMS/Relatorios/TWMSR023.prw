#Include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para impressao de etiquetas do WMS               !
!                  ! - Identificacao do endereco por armazem, rua e predio   !
+------------------+---------------------------------------------------------+
!Autor             ! Odair                     ! Data de Criacao   ! 08/2013 !
!Autor             ! David                     ! Data de Edicao    ! 07/2014 !
+------------------+---------------------------------------------------------+
!Observacoes       !                                                         !
+------------------+--------------------------------------------------------*/

User Function TWMSR023(mvEndereco)
	// variavel de retorno
	local _lRet := .f.

	// impressoras disponiveis no windows
	local _aImpWindows := U_FtRetImp()

	// retorna a pasta temporaria da maquina
	local _cPathTemp := AllTrim(GetTempPath())
	local _cTmpEtiq := "" // arquivo para criação da etiqueta

	// query da etiqueta
	local _cQryEtiq := ""
	local _nQtdReg := 0

	// quantidade de etiquetas
	local _nQtdTotal := 0
	local _nEtiq := 0

	// perguntas
	local _cPerg := PadR("TWMSR023",10)
	local _aPerg := {}

	// codigo da etiqueta
	local _cCodEtiq := ""

	// controle de transação
	local _lOk := .f.
	local _cImpSelec := ""

	// variaveis temporarias da estrutura do endereco
	local _cTmpLocal, _cTmpRua, _cTmpLado, _cTmpPredio, _cTmpAndar, _cTmpPosicao

	// arquivos temporarios
	local _cTmpArquivo, _cTmpBat, _nTmpHdl

	// valida o arquivo gerado
	local _lImpressOk := .f.

	// array pra comparar o prédio
	//local _nTotPred  := 0
	local _nSomaPred := 0

	// variavel de controle
	local _lValSeta := .f.

	// controle de andar
	local _nMaxAndar := 0
	local _nAndarAtu := 0

	// controle de impressão
	local _nEtqImpres := 1

	// arquivo da logo
	local _cEtiqLogo := ""

	// variavel da direção da seta
	local _cLadoSeta:= ""
	
	private _nTotPred  := 0
	
	// monta a lista de perguntas
	aAdd(_aPerg,{"Armazém    :" ,"C",TamSx3("BE_LOCAL")[1],0,"G",,/*"Z12"*/}) //mv_par01
	aAdd(_aPerg,{"Rua        :" ,"C",TamSx3("BE_LOCAL")[1],0,"G",,/*"Z12"*/}) //mv_par02
	aAdd(_aPerg,{"Prédio De  :" ,"C",TamSx3("BE_LOCAL")[1],0,"G",,/*"Z12"*/}) //mv_par03
	aAdd(_aPerg,{"Prédio Até :" ,"C",TamSx3("BE_LOCAL")[1],0,"G",,/*"Z12"*/}) //mv_par04
	aAdd(_aPerg,{"Lado(A/B)  :" ,"C",1                    ,0,"G",,/*"Z12"*/}) //mv_par05
	aAdd(_aPerg,{"Imprime    :" ,"N",1,0,"C",{"1 Total","2 Parcial"},/*"Z12"*/}) //mv_par06

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// abre os parametros
	If !Pergunte(_cPerg,.T.)
		Return(.f.)
	EndIf

	// tela para selecionar as impressoras de etiquetas disponiveis
	_oDlgSelImp := MSDialog():New(000,000,080,300,"Impressoras de etiquetas",,,.F.,,,,,,.T.,,,.T. )
	_oCBxTpEtiq := TComboBox():New( 004,004,{|u| If(PCount()>0,_cImpSelec:=u,_cImpSelec)},_aImpWindows,142,010,_oDlgSelImp,,,,,,.T.,,"",,,,,,,_cImpSelec )
	_oBtnEtqOk  := SButton():New( 018,100,1,{ || _lOk := .t. , _oDlgSelImp:End() },_oDlgSelImp,,"", )
	_oBtnEtqCan := SButton():New( 018,128,2,{ || _oDlgSelImp:End() },_oDlgSelImp,,"", )

	_oDlgSelImp:Activate(,,,.T.)

	If (_lOk)
		// remove texto e mantem só o caminho
		_cImpSelec := Separa(_cImpSelec,"|")[2]
		// define o arquivo temporario com o conteudo da etiqueta
		_cTmpArquivo := _cPathTemp+"wms_etiq_endereco2.txt"

		// monta query para buscar os dados
		_cQryEtiq := "SELECT BE_LOCAL, BE_LOCALIZ, BE_ZIDETIQ, SBE.R_E_C_N_O_ SBERECNO, "
		// orientacao da seta
		_cQryEtiq += "CASE "
		_cQryEtiq += "  WHEN BE_ZSETA = 'D' THEN 'G000' "
		_cQryEtiq += "  WHEN BE_ZSETA = 'E' THEN 'G002' "
		_cQryEtiq += "  WHEN BE_ZSETA = 'C' THEN 'G003' "
		_cQryEtiq += "ELSE ' ' END BE_ZSETA  "
		// cadastro de enderecos
		_cQryEtiq += "FROM "+RetSqlName("SBE")+" SBE "
		// filtro padrao
		_cQryEtiq += "WHERE "+RetSqlCond("SBE")+" "
		// armazem
		_cQryEtiq += "AND BE_LOCAL   = '"+mv_par01+"'  "
		// Rua
		_cQryEtiq += "AND SUBSTRING(BE_LOCALIZ,1,2) = '"+mv_par02+"'  "
		// Prédio
		_cQryEtiq += "AND SUBSTRING(BE_LOCALIZ,4,2) BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' "
		// Lado
		_cQryEtiq += "AND SUBSTRING(BE_LOCALIZ,3,1) = '"+mv_par05+"'  "
		// Tipo de Endereço = Pulmao e Porta Palete
		_cQryEtiq += "AND BE_ESTFIS IN (SELECT DC8_CODEST FROM "+RetSqlName("DC8")+" DC8 WHERE "+RetSqlCond("DC8")+" AND DC8_TPESTR IN ('1','2')) "
		// Situação do Endereço / 1: Livre / 2: Ocupado / 3: Bloqueado
		_cQryEtiq += "AND BE_STATUS IN ('1','2')  "
		// codigo da etiqueta
		_cQryEtiq += "ORDER BY BE_LOCAL, SUBSTRING(BE_LOCALIZ,1,5), SUBSTRING(BE_LOCALIZ,8,5)  "

		memowrit("c:\query\TWMSR023_query.txt",_cQryEtiq)

		// jogo o conteudo da query para um array
		_aImpEtq := U_SqlToVet(_cQryEtiq)

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
		dbEval({|| _nQtdReg += 1, _nMaxAndar := Max(Val(SubStr(_QRYETIQ->BE_LOCALIZ,6,2)),_nMaxAndar)  })

		// pego o total de endereços por predios
		_nTotPred = _nMaxAndar

		// quantidade total da regua de prcessamento
		ProcRegua(_nQtdReg)
		dbSelectArea("_QRYETIQ")
		_QRYETIQ->(dbGoTop())

		// inicia montagem da etiqueta
		_cTmpEtiq := "CT~~CD,~CC^~CT~"+CRLF
		_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF

		_cEtiqLogo := "~DG001.GRF,02688,028,"+CRLF
		_cEtiqLogo += ",::::::::::::::::P03FHFC0,O01FJF8,O0MF,R07FHFC0,T0IF0,L01FJFE007F8,K01FMFC07C,K03FNFC07,K07FOFC080,K0RFC,J01FRF80,J03FSF0,J07FSFC,J07FTF,J0VF80,I01FUFC0,I01FUFE0,I03FVF0,"+;
			"I03FVFI07FIFCFIF8007F80H01F0H07FF0H03FI07FVFI07FIFCFIF801FFE0H01F8007FHFH03FI07FVF8007FIFCFIF807FHFI03F8007FHF803FI0XF8007FIFCFIF81FIFC003FC007FHFE03FI0XFC007FIFCFIF81FIFE007FC007FIF03"+;
			"FI0XFC007FIFCFIF83FIFE007FC007FIF03FH01FFC0I07FOFC0I0FE00FIF87FC1FF007FE007E0FF83FH01F80K03FNFE0I0FE00FE0H07F807F80FFE007E07F83FH01C003F8003FNFE0I0FE00FE0H07F003F80FHFH07E03FC3FH03807F"+;
			"IFE3FNFE0I0FE00FE0H0FE003F80FHFH07E01FC3FH0303FJFE3FNFE0I0FE00FIF8FE0J01FBF007E01FC3FH0207FJFE3FNFE0I0FE00FIF8FC0J01F9F807E01FC3FH020FKFE3FOFJ0FE00FIF8FC0J03F9F807E00FC3FH020FKFE7FKF9F"+;
			"HFJ0FE00FIF8FC0J03F1FC07E00FC3FH021FKFC7FKF83FF0I0FE00FIF8FE0J07F0FC07E01FC3FH021FKFC7FKFH0HFJ0FE00FIF8FE0J07F0FE07E01FC3FH0H1LFC7FKFH03F0I0FE00FE0H0FE003F87E0FE07E01FC3FI09FKFC7FKF301"+;
			"F0I0FE00FE0H07F003F8FIFE07E03FC3FI01FKFCFLF3E0F0I0FE00FE0H07F807F8FIFE07E07F83FI01FKF8FLF7F870I0FE00FIF87FC1FF1FJF07E0FF83FI01FKF8FLF7FC30I0FE00FIF83FIFE1FJF07FIF03FI01FKF8FKFE7FE30I0F"+;
			"E00FIF81FIFE1FJF87FIF03FJ0LF0FKFE7FF10I0FE00FIF80FIFC3F803F87FHFE03FJ0LF1FKFE7FF10I0FE00FIF807FHF83F803F87FHFC03FJ0LF1FKFEFHF10I0FE00FIF801FFE07F001FC7FHFH03FJ0LF1FKFCFHF10I0FE00FIF800"+;
			"7F007F001FC7FE0H03FJ0KFE3FKFCFHF2,J07FIFE3FKFCFFE4,J07FIFE3FKFCFFE0,J07FIFC3FKF9FFE0,J03FIFC7FKF9FFC0gL03C,J03FIF87FKF9FFC0gL060,J03FIF87FKFBFF80gL04067913CJ01FIF0FLF3FF80gL040449136K0"+;
			"JF0FLF3FF0gM046489122K0IFE0FLF3FE0gM0464C9122K07FFE1FKFE7FE0gM076459B36K03FFC1FKFE7FC0gM018030C28K03FF83FKFE7F80gS020K01FF83FKFCFF0gT020L0HF07FKFCFF0,K047E07FKFCFE0,K040H0MF9FC0,"+;
			"K040H0MF9F80,K04001FLF1F,K04003FLF3C,K02007FKFE38,K0300FLFE60,K0181FLFC,L0OFC,L03FMF8,M03FLF0,N01FJFE0,P0JFC0,Q01FF80,,:::::^XA"+CRLF

		// direita
		_cEtiqLogo += "~DG000.GRF,04096,032,"+CRLF
		_cEtiqLogo += ",:::::::::::::::::::::::hG01,hG01C0,hG01F0,hG01FC,hG01FF,hG01FFC0,hG01FHF8,hG01FHFC,hG01FIF80,hG01FIFE0,hG01FJF8,hG01FJFE,hG01FKF80,hG01FKFE0,hG01FLF8,hG01FMF,hG01FMFC0,"+;
			"hG01FNF0,hG01FNFC,T0gXF,T0gXFC0,T0gYF0,T0gYFC,T0hF,T0hFC0,T0hGF8,T0hGFE,T0hHF80,T0hHFE0,T0hIF8,T0hIFE,:T0hIF8,T0hHFE0,T0hHF80,T0hGFE,T0hGF8,T0hFE0,T0hFC0,T0hF,T0gYFC,T0gYF0,T0gXFC0,T0gXF,"+;
			"T0gWFC,T0gWF0,hG01FMFE0,hG01FMF80,hG01FLFE,hG01FLF8,hG01FKFE0,hG01FKF80,hG01FJFE,hG01FJF8,hG01FIFE0,hG01FIFC0,hG01FIF,hG01FHFC,hG01FHF0,hG01FFC0,hG01FF,hG01FC,hG01F0,hG01E0,hG0180,,"+;
			"::::::::::::::::::::::::::::::::::::::"+CRLF

		// esquerda
		_cEtiqLogo += "~DG002.GRF,04096,032,"+CRLF
		_cEtiqLogo += ",:::::::::::::::::::::::::gI03,gI0F,gH01F,gH07F,gG01FF,gG07FF,g01FHF,g03FHF,g0JF,Y03FIF,X01FJF,X03FJF,X0LF,W03FKF,W0MF,V03FLF,V07FLF,U01FMF,U07FgTF8,T01FgUF8,T07FgUF8,S01FgVF8,"+;
			"S07FgVF8,R01FgWF8,R07FgWF8,R0gYF8,Q03FgXF8,Q0hF8,P03FgYF8,P0hGF8,O03FhF8,O0hHF8,N03FhGF8,N01FhGF8,O07FhF8,O01FhF8,P07FgYF8,P01FgYF8,Q07FgXF8,Q01FgXF8,R07FgWF8,S0gXF8,S03FgVF8,T0gWF8,T03FNF,"+;
			"U0OF,U03FMF,V0NF,V03FLF,W0MF,W03FKF,X07FJF,X01FJF,Y07FIF,Y01FIF,g07FHF,g01FHF,gG07FF,gG01FF,gH07F,gH01F,gI03,,:::::::::::::::::::::::::::::::::::::::"+CRLF

		// cima
		_cEtiqLogo += "~DG003.GRF,02048,016,"+CRLF
		_cEtiqLogo += ",:::::::::::::::::::::::::U02,U06,U0F80,T01FC0,T03FE0,T07FF0,T0IF8,S01FHFC,S03FHFE,S07FIF,S0KF80,R01FJFC0,R03FJFE0,R07FKF0,R0MF8,Q01FLFC,Q03FLFE,Q07FMF,Q0OF80,Q0OFC0,P03FNFE0,"+;
			"P03FOF0,P0QF8,P0QFC,O03FPFE,O01FMFE0,R03FJFE0,::::::::::::::::::::::::::::::,::::::::::::::::::::::::::::::::::::::::::::^XA"+CRLF

		// defino a logo e jogo no arquivo da etiqueta
		_cTmpEtiq += _cEtiqLogo

		// laço para ver todos os registros
		While _QRYETIQ->(!Eof())

			if ( !_lImpressOk )
				// cria e abre arquivo texto
				_nTmpHdl := fCreate(_cTmpArquivo)
				// testa se o arquivo de Saida foi Criado Corretamente
				If (_nTmpHdl == -1)
					MsgAlert("O arquivo de nome "+_cTmpArquivo+" nao pode ser executado! Verifique os parametros.","Atencao!")
					Return(.f.)
				Endif
			Endif

			// posiciona no cadastro
			dbSelectArea("SBE")
			SBE->(DbGoTo( _QRYETIQ->SBERECNO ))

			// armazena o codigo da etiqueta
			_cCodEtiq := SBE->BE_ZIDETIQ

			// numero do andar
			_nAndarAtu := Val(SubStr(SBE->BE_LOCALIZ,6,2))

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
			_cTmpRua     := SubStr(SBE->BE_LOCALIZ,1,2)
			_cTmpLado    := SubStr(SBE->BE_LOCALIZ,3,1)

			// dados padrao da etiqueta
			If (_nEtqImpres == 1)
				// config da etiqueta
				_cTmpEtiq += "^MMT"+CRLF
				_cTmpEtiq += "^PW599"+CRLF
				_cTmpEtiq += "^LL1159"+CRLF
				_cTmpEtiq += "^LS0"+CRLF

				// defino o lado da etiqueta
				_cLadoSeta := _QRYETIQ->BE_ZSETA

				// valida se foi definido corretamente o cadastro da direcao da seta
				If (Empty(_cLadoSeta))
					MsgStop("Erro no cadastro do endereço "+SBE->BE_LOCALIZ+". Direção da Seta não definida!")
					// fecha arquivo texto
					fClose(_nTmpHdl)
					Return(.f.)
				EndIf

				// seta
				_cTmpEtiq += "^FT320,224^X"+_cLadoSeta+".GRF,1,1^FS"+CRLF

				// logo
				_cTmpEtiq += "^FT32,96^XG001.GRF,1,1^FS"+CRLF

				// defino prédio
				_cTmpEtiq += "^FT235,183^A0N,31,31^FH\^FD"+SubStr(_QRYETIQ->BE_LOCALIZ,4,2)+"^FS"+CRLF
			EndIf

			// inclui os código de barras pra cada etiqueta
			sfRetCodBarras(@_cTmpEtiq, _cCodEtiq, _QRYETIQ->BE_LOCALIZ, @_nEtqImpres)

			// incrementa quantidade de impressoes
			dbSelectArea("Z11")
			Z11->(dbSetOrder(1)) //1-Z11_FILIAL, Z11_CODETI
			Z11->(dbSeek( xFilial("Z11")+_cCodEtiq ))
			RecLock("Z11")
			Z11->Z11_QTDIMP += 1
			MsUnLock()

			// controle da impressão
			_lImpressOk := .t.

			// zera a variável pra continuar a próxima etiqueta e finaliza os dados
			If (_nEtqImpres == 0).or.(_nAndarAtu == _nMaxAndar) // caso já atingiu o máximo das etiquetas
				// zero a variável
				_nEtqImpres := 1

				// incluo final da etiqueta
				_cTmpEtiq += "^FO302,2^GB0,97,2^FS"+CRLF
				_cTmpEtiq += "^FO8,194^GB586,0,1^FS"+CRLF
				_cTmpEtiq += "^FO12,107^GB579,0,1^FS"+CRLF
				_cTmpEtiq += "^FT46,143^A0N,28,28^FH\^FDRUA^FS"+CRLF
				_cTmpEtiq += "^FT343,63^A0N,23,21^FH\^FDARMZ: "+_cTmpLocal+"^FS"+CRLF
				_cTmpEtiq += "^FT118,143^A0N,28,28^FH\^FDLADO^FS"+CRLF
				_cTmpEtiq += "^FT345,35^A0N,23,21^FH\^FDWMS.LOCALIZA\80\C7O^FS"+CRLF
				_cTmpEtiq += "^FT345,91^A0N,23,21^FH\^FDFilial: "+xFilial("SBE")+"^FS"+CRLF
				_cTmpEtiq += "^FT205,143^A0N,28,28^FH\^FDPR\90DIO^FS"+CRLF
				_cTmpEtiq += "^FT142,181^A0N,31,31^FH\^FD"+_cTmpLado+"^FS"+CRLF
				_cTmpEtiq += "^FT57,182^A0N,31,31^FH\^FD"+_cTmpRua+"^FS"+CRLF
				_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
				_cTmpEtiq += "^XA"+CRLF

			EndIf

			// proximo endereço
			_QRYETIQ->(dbSkip())

		EndDo

		// complementa a etiqueta com as imagens
		_cTmpEtiq += "^XA^ID000.GRF^FS^XZ"+CRLF
		_cTmpEtiq += "^XA^ID001.GRF^FS^XZ"+CRLF
		_cTmpEtiq += "^XA^ID002.GRF^FS^XZ"+CRLF
		
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
			Sleep(1000)
		EndIf

		// apaga o arquivo temporário
		//Ferase(_cTmpArquivo)
		_lImpressOk := .f.

	EndIf

Return(.t.)

/// função que irá inserir os código de barras na etiqueta
Static Function sfRetCodBarras(mvArqEtiq, mvCodEtiq, mvEndere, mvQtdImp)

	// variável de controle
	local _lOk := .f.

	/* cada etiqueta tem no máximo 6 endereços*/
	
	If mv_par06 == 1
	
		//Imprime todas as etiquetas de 1 a 6
		If _nTotPred == 6
			// Primeiro cod de barras
			If (mvQtdImp == 1).and.(!_lOk)
				mvArqEtiq += "^BY3,3,100^FT110,1070^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT231,1095^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT22,1050^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT37,1020^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
				
				// incremento do controle
				mvQtdImp += 1
				_lOk := .t.
			EndIf
	
			// Segundo cod de barras
			If (mvQtdImp == 2).and.(!_lOk)
				mvArqEtiq += "^BY3,3,100^FT110,918^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT231,942^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT22,900^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT37,870^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
				
				// incremento do controle
				mvQtdImp += 1
				_lOk := .t.
			EndIf
	
			// Terceiro cod de barras
			If (mvQtdImp == 3).and.(!_lOk)
				mvArqEtiq += "^BY3,3,100^FT110,780^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT231,800^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT22,770^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT37,740^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
				
				// incremento do controle
				mvQtdImp += 1
				_lOk := .t.
			EndIf
	
			// Quarto cod de barras
			If (mvQtdImp == 4).and.(!_lOk)
				mvArqEtiq += "^BY3,3,100^FT112,635^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT233,655^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT24,620^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT38,590^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
				
				// incremento do controle
				mvQtdImp += 1
				_lOk := .t.
			EndIf
	
			// Quinto cod de barras
			If (mvQtdImp == 5).and.(!_lOk)
				mvArqEtiq += "^BY3,3,100^FT113,495^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT234,518^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT25,485^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT40,455^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
				
				// incremento do controle
				mvQtdImp += 1
				_lOk := .t.
			EndIf
			
			// Sexto cod de barras
			If (mvQtdImp == 6).and.(!_lOk)
				mvArqEtiq += "^BY3,3,100^FT113,360^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT234,380^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT25,335^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT40,300^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
				
				// incremento do controle
				mvQtdImp := 0
				_lOk := .t.
			EndIf
		Else
			//Imprime todas as etiquetas de 1 a 5
			// Primeiro cod de barras
			If (mvQtdImp == 1).and.(!_lOk)
				mvArqEtiq += "^BY3,3,129^FT110,1065^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT231,1095^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT22,1040^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT37,987^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
	
				// incremento do controle
				mvQtdImp += 1
				_lOk := .t.
			EndIf
	
			// Segundo cod de barras
			If (mvQtdImp == 2).and.(!_lOk)
				mvArqEtiq += "^BY3,3,129^FT110,894^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT231,924^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT22,868^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT37,815^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
	
				// incremento do controle
				mvQtdImp += 1
				_lOk := .t.
			EndIf
	
			// Terceiro cod de barras
			If (mvQtdImp == 3).and.(!_lOk)
				mvArqEtiq += "^BY3,3,129^FT110,722^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT231,752^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT22,697^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT37,644^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
	
				// incremento do controle
				mvQtdImp += 1
				_lOk := .t.
			EndIf
	
			// Quarto cod de barras
			If (mvQtdImp == 4).and.(!_lOk)
				mvArqEtiq += "^BY3,3,129^FT112,550^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT233,581^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT24,525^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT38,472^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
	
				// incremento do controle
				mvQtdImp += 1
				_lOk := .t.
			EndIf
	
			// Quinto cod de barras
			If (mvQtdImp == 5).and.(!_lOk)
				mvArqEtiq += "^BY3,3,129^FT113,378^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT234,409^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT25,353^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT40,300^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
	
				// incremento do controle
				mvQtdImp := 0
				_lOk := .t.
			EndIf
		EndIf
		//Inicia a impressão a partir da 3ª Posição.
	Else
		If _nTotPred == 6
			
			// Terceiro cod de barras
			If (mvQtdImp == 3).and.(!_lOk)
				mvArqEtiq += "^BY3,3,129^FT110,1065^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT231,1095^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT22,1040^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT37,987^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
			EndIf
	
			// Quarto cod de barras
			If (mvQtdImp == 4).and.(!_lOk)
				mvArqEtiq += "^BY3,3,129^FT110,840^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT231,870^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT22,830^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT37,780^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
			EndIf
	
			// Quinto cod de barras
			If (mvQtdImp == 5).and.(!_lOk)
				mvArqEtiq += "^BY3,3,129^FT113,600^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT234,630^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT25,590^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT40,540^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
			EndIf
			
			// Sexto cod de barras
			If (mvQtdImp == 6).and.(!_lOk)
				mvArqEtiq += "^BY3,3,129^FT113,360^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT234,390^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT25,350^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT40,300^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
				
				// incremento do controle
				mvQtdImp := 0
				_lOk := .t.
			EndIf
		Else
			// Terceiro cod de barras
			If (mvQtdImp == 3).and.(!_lOk)
				mvArqEtiq += "^BY3,3,129^FT110,1065^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT231,1095^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT22,1040^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT37,987^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
			EndIf
	
			// Quarto cod de barras
			If (mvQtdImp == 4).and.(!_lOk)
				mvArqEtiq += "^BY3,3,129^FT110,722^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT231,752^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT22,697^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT37,644^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
			EndIf
	
			// Quinto cod de barras
			If (mvQtdImp == 5).and.(!_lOk)
				mvArqEtiq += "^BY3,3,129^FT113,378^BCN,,N,N"+CRLF
				mvArqEtiq += "^FD>:"+mvCodEtiq+"^FS"+CRLF
				// dados para colocar embaixo do código de barras
				mvArqEtiq += "^FT234,409^A0N,28,28^FH\^FD"+Transf(mvCodEtiq,"@R 99999-99999")+"^FS"+CRLF
				mvArqEtiq += "^FT25,353^A0N,28,28^FH\^FD"+SubStr(mvEndere,8,5)+"^FS"+CRLF // posição
				mvArqEtiq += "^FT40,300^A0N,45,43^FH\^FD"+SubStr(mvEndere,6,2)+"^FS"+CRLF // andar
				// incremento do controle
				mvQtdImp := 0
				_lOk := .t.
				Return(_lOk)
			EndIf
		EndIf
		
		// incremento do controle
		mvQtdImp += 1
		_lOk := .t.
	EndIf
Return(_lOk)