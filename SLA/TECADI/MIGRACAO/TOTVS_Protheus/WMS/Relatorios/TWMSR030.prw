#include 'protheus.ch'
#include 'parmtype.ch'


/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para impressao de etiquetas padr�o Leroy Merlin  !
!                  ! para cliente Danuri / Luminatti                         !
+------------------+---------------------------------------------------------+
!Autor             ! Luiz Poleza                 ! Data de Cria��o ! 07/2018 !
+------------------+--------------------------------------------------------*/


user function TWMSR030()

	// perguntas
	local _cPerg := PadR("TWMSR030",10)
	local _aPerg := {}

	// monta a lista de perguntas

	aAdd(_aPerg,{"Pedido Tecadi:"     , "C", TamSx3("C9_PEDIDO")[1] ,0,"G",,"SC5"   }) //mv_par01
	aAdd(_aPerg,{"N�mero da loja:"    , "C", 02                     ,0,"G",,""      }) //mv_par02
	aAdd(_aPerg,{"Nome da loja:"      , "C", 40                     ,0,"G",,""      }) //mv_par03
	aAdd(_aPerg,{"C�digo de Barras:"  , "C", 10                     ,0,"G",,""      }) //mv_par04

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// abre os parametros
	If ! Pergunte(_cPerg,.T.)
		Return(.f.)
	EndIf

	If ( Empty(MV_PAR01) ) .OR. ( Empty(MV_PAR02) ) .OR. ( Empty(MV_PAR03) ) .OR. ( Empty(MV_PAR04) ) 
		MsgAlert("Um ou mais par�metros est�o em branco. Preencha todos e tente gerar novamente.","Erro TWMSR030 - 002")
		Return( .F. )
	EndIf

	// chama a fun��o de processamento
	U_WMSR030A(mv_par01, mv_par02, mv_par03, mv_par04)

return

User Function WMSR030A (mvNumped, mvNumLoja, mvNomeLoja, mvCodbar)

	// variavel de retorno
	local _lRet := .f.

	// objetos
	local _oDlgSelImp, _oCBxTpEtiq, _oBtnEtqOk, _oBtnEtqCan

	// impressoras zebra dispon�veis no windows
	local _aImpWindows := U_FtRetImp()

	// arquivos temporarios
	local _cTmpArquivo := ""
	local _cTmpBat     := ""
	local _nTmpHdl

	// retorna a pasta temporaria da maquina
	local _cPathTemp := AllTrim(GetTempPath())

	local _cQuery := ""
	local _aRet   := {}

	local _cEtiq := ""          // conte�do da etiqueta a ser enviada para impressora imprimir
	local _nQtd  := 0           // quantidade de etiquetas

	// impressora selecionada
	local _cImpSelec := U_FtImpZbr()

	// controle de la�o
	local _nX := 0
	
	

	// tela para selecionar as impressoras de etiquetas disponiveis
	_oDlgSelImp := MSDialog():New(000,000,080,300,"Impressoras de etiquetas",,,.F.,,,,,,.T.,,,.T. )
	_oCBxTpEtiq := TComboBox():New( 004,004,{|u| If(PCount()>0,_cImpSelec:=u,_cImpSelec)},_aImpWindows,142,010,_oDlgSelImp,,,,,,.T.,,"",,,,,,,_cImpSelec )
	_oBtnEtqOk  := SButton():New( 018,100,1,{ || _lRet := .t. , _oDlgSelImp:End() },_oDlgSelImp,,"", )
	_oBtnEtqCan := SButton():New( 018,128,2,{ || _oDlgSelImp:End() },_oDlgSelImp,,"", )

	_oDlgSelImp:Activate(,,,.T.)

	// se alguma impressora foi selecionada continua
	If (_lRet)

		// grava informacoes da impressora selecionada
		U_FtImpZbr(_cImpSelec)

		// remove texto e mantem s� o caminho
		_cImpSelec := Separa(_cImpSelec,"|")[2]
		// define o arquivo temporario com o conteudo da etiqueta
		_cTmpArquivo := _cPathTemp+"wms_etiq_danuri_leroy.txt"

		// cria e abre arquivo texto
		_nTmpHdl := fCreate(_cTmpArquivo)

		// testa se o arquivo de Saida foi Criado Corretamente
		If (_nTmpHdl == -1)
			MsgAlert("O arquivo tempor�rio para gerar as etiquetas "+_cTmpArquivo+" nao p�ode ser criado! Verifique as permiss�es.","Erro TWMSR030 - 003")
			Return( .F. )
		Endif

		// monta consulta
		_cQuery := "SELECT C5_NUM,                                     "   // 1
		_cQuery += "       C5_ZPEDCLI,                                 "   // 2
		_cQuery += "       C5_ZDOCCLI,                                 "   // 3
		_cQuery += "       C5_ZMNTVOL,                                 "   // 4
		_cQuery += "       C5_ZONDSEP,                                 "   // 5
		_cQuery += "       Z05_NUMOS,                                  "   // 6
		_cQuery += "       (SELECT COUNT(DISTINCT Z07_ETQVOL)          "   
		_cQuery += "        FROM " + RetSqlTab("Z07")
		_cQuery += "        WHERE " + RetSqlCond("Z07")
		_cQuery += "               AND Z07_NUMOS = Z06_NUMOS) QTD_VOL  "   // 7
		_cQuery += "FROM " + RetSqlTab("SC5")
		_cQuery += "       INNER JOIN " + RetSqlTab("Z05")
		_cQuery += "               ON " + RetSqlCond("Z05")
		_cQuery += "                  AND Z05_ONDSEP = C5_ZONDSEP      "
		_cQuery += "                  AND Z05_ONDSEP != ''             "
		_cQuery += "       INNER JOIN " + RetSqlTab("Z06")
		_cQuery += "               ON " + RetSqlCond("Z06")
		_cQuery += "                  AND Z06_NUMOS = Z05_NUMOS        "
		_cQuery += "                  AND Z06_SEQOS = '002'            "  // montagem de volumes
		_cQuery += "                  AND Z06_STATUS = 'FI'            "  // somente finalizados
		_cQuery += "WHERE " + RetSqlCond("SC5")
		_cQuery += "       AND C5_NUM = '" + mvNumped + "'"

		_aRet := U_SQLToVet(_cQuery)

		If ( len(_aRet) == 0 )  // n�o encontrou dados
			MsgAlert("N�o foram encontrados dados para gerar as etiquetas. Verifique se a montagem de volumes do pedido " + mvNumped + " j� foi finalizada", "Erro TWMSR030 - 001" )
			Return
		EndIf

		// quantidade de volumes que retornou no SQL
		_nQtd := _aRet[1][7]

		// quantidade total da regua de prcessamento
		ProcRegua( _nQtd )

		// gera as etiquetas de acordo com a quantidade
		For _nX := 1 to _nQtd
			// cabe�alho
			_cEtiq += "CT~~CD,~CC^~CT~" + CRLF
			_cEtiq += "^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ " + CRLF
			_cEtiq += "^XA " + CRLF
			_cEtiq += "^MMT" + CRLF
			_cEtiq += "^PW799" + CRLF
			_cEtiq += "^LL0480" + CRLF
			_cEtiq += "^LS0" + CRLF
			// dados da etiqueta
			_cEtiq += "^FT178,76^A0N,56,57^FB404,1,0,C^FH\^FDLOJA " + mvNumLoja + "^FS" + CRLF
			_cEtiq += "^FT178,147^A0N,56,57^FB404,1,0,C^FH\^FD" + AllTrim(mvNomeLoja) + "^FS" + CRLF
			_cEtiq += "^FT0,218^A0N,56,57^FB760,1,0,C^FH\^FDNota fiscal " + AllTrim(_aRet[1][3]) + "^FS  " + CRLF
			_cEtiq += "^BY4,3,160^FT208,425^BCN,,Y,N" + CRLF
			_cEtiq += "^FD" + AllTrim(mvCodbar) + "^FS" + CRLF
			_cEtiq += "^PQ1,0,1,Y^XZ" + CRLF
		Next _nX


		// grava a Linha no Arquivo Texto
		fWrite(_nTmpHdl, _cEtiq)

		// fecha arquivo texto
		fClose(_nTmpHdl)

		// define o arquivo .BAT para execucao da impressao da etiqueta
		_cTmpBat := _cPathTemp + "wms_imp_etiq.bat"

		// grava o arquivo .BAT
		MemoWrit(_cTmpBat,"copy " + _cTmpArquivo + " " + _cImpSelec)

		// executa o comando (.BAT) para impressao

		WinExec(_cTmpBat)
		Sleep(1000)
	EndIf

Return