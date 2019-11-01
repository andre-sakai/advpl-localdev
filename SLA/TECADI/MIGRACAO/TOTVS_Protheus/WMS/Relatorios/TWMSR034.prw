#Include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para impressao de etiquetas do WMS - Livre       !
!                  ! - Numeros de Serie                                      !
+------------------+---------------------------------------------------------+
!Autor             ! Andre Sakai               ! Data de Criacao   ! 09/2019 !
+------------------+--------------------------------------------------------*/

User Function TWMSR034(mvOperacao, mvCesv1, mvCesv2, mvCesv3, mvCesv4, mvQuant, mvLayout)
	// variavel de retorno
	local _lRet := .f.
	//FWTemporaryTable
	private _TRBITENS := GetNextAlias()
	private _oAlTrb

	// valores padroes
	Default mvOperacao := 1
	Default mvCesv1     := space(20)
	Default mvCesv2     := space(20)
	Default mvCesv3     := space(20)
	Default mvCesv4     := space(20)
	Default mvQuant    := 0
	Default mvLayout   := 1

	// rotina para impressao dos dados
	Processa ({|| _lRet := sfImpressao(mvOperacao, mvCesv1, mvCesv2, mvCesv3, mvCesv4, mvLayout) },"Gerando etiquetas...")

Return(_lRet)

// ** funcao para impressao dos dados
Static Function sfImpressao(mvOperacao, mvCesv1, mvCesv2, mvCesv3, mvCesv4, mvLayout)

	// impressoras disponiveis no windows
	local _aImpWindows := U_FtRetImp()

	// objetos
	local _oWndSelImp
	local _oCBxTpEtiq
	local _oBtnEtqOk, _oBtnEtqCan

	// retorna a pasta temporaria da maquina
	local _cPathTemp := AllTrim(GetTempPath())
	local _cTmpEtiq

	local _cPerg := PadR("TWMSR034",10)
	
	local _lOk := .f.
	local _cImpSelec := U_FtImpZbr()

	// arquivos temporarios
	local _cTmpArquivo, _cTmpBat, _nTmpHdl

	// estrutura do arquivo de trabalho
	local _aEstTrb := {}
	local _aHeadBrw := {}
	local _cMarcaBrw := GetMark()

	// controle dos itens a serem impressora
	local _cImpItem := ""

	// valida o arquivo gerado
	local _lImpressOk := .f.

	// define se deve apresentar os parametros
	local _lShowParam := .T.

	//medidas das etiquetas de 4 colunas
	local nXPEtiq	:= 200
	local nXTit		:= 55
	local nXCBar	:= 155
	local nXNum		:= 185
	local aEtiAvul	:= {}
	local aEtiCESV	:= {}

	// solicita parametros
	If (_lShowParam)

		// abre os parametros
		If ! Pergunte(_cPerg, .t.)
			Return(.f.)
		EndIf

		// atualiza os parametros, quando for por rotina automatica (chamada externa)
	ElseIf ( ! _lShowParam )

		// cria os mv_par??
		Pergunte(_cPerg, .f.)

		// define conteudo
		mv_par01 := 1
		mv_par02 := mvCesv1
		mv_par03 := mvCesv2
		mv_par04 := mvCesv3
		mv_par05 := mvCesv4
		mv_par06 := 1

	EndIf

	// tela para selecionar as impressoras de etiquetas disponiveis
	_oWndSelImp := MSDialog():New(000,000,080,210,"Impressoras de etiquetas",,,.F.,,,,,,.T.,,,.T. )
	_oCBxTpEtiq := TComboBox():New( 004,004,{|u| If(PCount()>0,_cImpSelec:=u,_cImpSelec)},_aImpWindows,100,010,_oWndSelImp,,,,,,.T.,,"",,,,,,,_cImpSelec )
	_oBtnEtqOk  := SButton():New( 021,021,1,{ || _lOk := .t. , _oWndSelImp:End() },_oWndSelImp,,"", )
	_oBtnEtqCan := SButton():New( 021,055,2,{ || _oWndSelImp:End() },_oWndSelImp,,"", )

	_oWndSelImp:Activate(,,,.T.)

	If (_lOk)
		aEtiAvul:={}
		If(!Empty(mv_par02))
			aAdd(aEtiAvul,mv_par02)
		EndIf
		If(!Empty(mv_par03))
			aAdd(aEtiAvul,mv_par03)
		EndIf
		If(!Empty(mv_par04))
			aAdd(aEtiAvul,mv_par04)
		EndIf
		If(!Empty(mv_par05))
			aAdd(aEtiAvul,mv_par05)
		EndIf

		If(len(aEtiAvul) = 0)
			msgalert("Não foi informada nenhuma Etiqueta.","Atenção! - TWMSR034") 
			Return .F.
		EndIf

		// grava informacoes da impressora selecionada
		U_FtImpZbr(_cImpSelec)

		// remove texto e mantem so o caminho
		_cImpSelec := Separa(_cImpSelec,"|")[2]

		// define o arquivo temporario com o conteudo da etiqueta
		_cTmpArquivo := _cPathTemp+"wms_etiq_avulsa034.txt"

		// cria e abre arquivo texto
		_nTmpHdl := fCreate(_cTmpArquivo)

		// testa se o arquivo de Saida foi Criado Corretamente
		If (_nTmpHdl == -1)
			MsgAlert("O arquivo de nome "+_cTmpArquivo+" nao pode ser executado! Verifique os parametros.","Atencao!")
			Return(.f.)
		Endif


		//Impressao da etiqueta avulsa 4 colunas (MV_PAR06)
		If MV_PAR01 == 1 .And. MV_PAR06 == 2
			nAux := 1
			_cTmpEtiq := ""
			For nNumAv:=1 to Len(aEtiAvul)
				_lImpressOk := .t.

				If nAux == 1
					//Cabeï¿½alho etiqueta
					_cTmpEtiq += "CT~~CD,~CC^~CT~"+CRLF
					_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
					_cTmpEtiq += "^XA"+CRLF
					_cTmpEtiq += "^MMT"+CRLF
					_cTmpEtiq += "^PW900"+CRLF
					_cTmpEtiq += "^LL0350"+CRLF
					_cTmpEtiq += "^LS0"+CRLF
				EndIf
				//Corpo da etiqueta

				_cTmpEtiq += "^BY1,2,90^FT"+Str(nXCBar)+",270^BCB,,N,N^FD>:"+aEtiAvul[nNumAv]+"^FS"+CRLF
				_cTmpEtiq += "^FT"+Str(nXNum)+",285^A0B,32,32^FH\^FD"+aEtiAvul[nNumAv]+"^FS"+CRLF

				If nAux == 4
					nAux := 0
					nXTit	:= 55
					nXCBar	:= 155
					nXNum	:= 185
					_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
					//Cabeï¿½alho etiqueta
					_cTmpEtiq += "CT~~CD,~CC^~CT~"+CRLF
					_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
					_cTmpEtiq += "^XA"+CRLF
					_cTmpEtiq += "^MMT"+CRLF
					_cTmpEtiq += "^PW900"+CRLF
					_cTmpEtiq += "^LL0350"+CRLF
					_cTmpEtiq += "^LS0"+CRLF
				Else
					nXTit	+= nXPEtiq
					nXCBar	+= nXPEtiq
					nXNum	+= nXPEtiq
				EndIf

				If nNumAv == Len(aEtiAvul) .And. nAux != 4
					//Fecha a etiqueta
					_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF
				EndIf
				nAux++
			Next nNumAv
			fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))
		ElseIf(MV_PAR01 == 1)  // 1 - etiqueta na horizontal 
			_cTmpEtiq := ""

			//cabeçalho etiqueta
			For nNumAv:=1 to Len(aEtiAvul)
				_lImpressOk := .t.
				_cTmpEtiq += "CT~~CD,~CC^~CT~"+CRLF
				_cTmpEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ"+CRLF
				_cTmpEtiq += "^XA"+CRLF
				_cTmpEtiq += "^MMT"+CRLF
				_cTmpEtiq += "^PW900"+CRLF
				_cTmpEtiq += "^LL0300"+CRLF
				_cTmpEtiq += "^LS0"+CRLF

				_cTmpEtiq += "^FO 150,60^A0,B,32,32^FDTECADI - Numero de Serie^FS"+CRLF
				_cTmpEtiq += "^BY 2,2,90^"+CRLF
				_cTmpEtiq += "^FO 150,90^BC,,N,N^FD>:"+AllTrim(aEtiAvul[nNumAv])+"^FS"+CRLF
				_cTmpEtiq += "^FB 800,1,0,C^FO 0,190A0,B,40,40^FD"+AllTrim(aEtiAvul[nNumAv])+"^FS"+CRLF

				_cTmpEtiq += "^PQ1,0,1,Y^XZ"+CRLF

			Next
			fWrite(_nTmpHdl,_cTmpEtiq,Len(_cTmpEtiq))

		EndIf

		// fecha arquivo texto
		fClose(_nTmpHdl)

		// define o arquivo .BAT para execucao da impressao da etiqueta
		_cTmpBat := _cPathTemp+"wms_imp_etiq034.bat"
		// grava o arquivo .BAT
		MemoWrit(_cTmpBat,"copy "+_cTmpArquivo+" "+_cImpSelec)

		// executa o comando (.BAT) para impressao
		If (_lImpressOk)
			WinExec(_cTmpBat)
		EndIf

	EndIf

	// fecha tabela temporaria
	If ValType(_oAlTrb) == "O"
		_oAlTrb:Delete()
	EndIf

Return(.T.)