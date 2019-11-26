#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"
/*
+----------------------------------------------------------------------------+
!                          FICHA TECNICA DO PROGRAMA
+----------------------------------------------------------------------------+
!   DADOS DO PROGRAMA
+------------------+---------------------------------------------------------+
!Tipo              ! Atualização
+------------------+---------------------------------------------------------+
!Modulo            ! Estoque
+------------------+---------------------------------------------------------+
!Nome              ! TOEXCELA
+------------------+---------------------------------------------------------+
!Descricao         ! Este programa gera planilhas para o Excel.
+------------------+---------------------------------------------------------+
!Autor             ! 
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 13/11/2016
+------------------+---------------------------------------------------------+
!   ATUALIZACOES
+-------------------------------------------+-----------+-----------+--------+
!   Descricao detalhada da atualizacao      !Nome do    ! Analista  !Data da !
!                                           !Solicitante! Respons.  !Atualiz.!
+-------------------------------------------+-----------+-----------+--------+
!
+-------------------------------------------+-----------+-----------+--------+
*/
User Function TOEXCELA(cTitulo,aStru2,aDados)
	/*
	Parametros
	1-Array de Dados
	2-Array de Estrutura (Cabecalho) //parametro opcional
	*/
	Local cPathExc 	:= "C:\temp\"  
	Local cFileExc	:= ""	
	Private cArq	:= ""

	/*cPathExc := cGetFile( "Selecione o Diretorio | " , OemToAnsi( "Selecione Diretorio para gravar a planilha do Excel" ) , 0,"",.F.,GETF_LOCALHARD+GETF_RETDIRECTORY+GETF_OVERWRITEPROMPT)
	
	IF Empty( cPathExc )
		MsgInfo( OemToAnsi( "Não foi possível encontrar o diretório para gravar a planilha!" ) )
		Return
	EndIf*/

//	If ! ApOleClient( 'MsExcel' )
//		MsgInfo( 'Como você não possui o Microsoft Excel o arquivo a ser gerado deve ser aberto manualmente,' + CRLF +;
//				' na pasta em que foi salvo.' )
//		MsgStop( 'MsExcel não instalado!' )
//		Return 
//	EndIf

	cFileExc := FPOPEXCEL(aDados,aStru2,cPathExc,cTitulo)
	
	If !Empty(cFileExc)
		/*msgInfo("Arquivo criado com sucesso!" + ;
		Chr(13) + Chr(10) + ;
		Chr(13) + Chr(10) + ;
		cArq + ".CSV","Aviso")*/

		If ApOleClient( 'MsExcel' )
			oExcelApp := MsExcel():New()
			oExcelApp:WorkBooks:Open(cFileExc) // Abre a planilha
			oExcelApp:SetVisible(.T.)
		Else
			nRet := WinExec("C:\relatorio\necessidade.exe " + cFileExc)
			If nRet <> 0
				MsgInfo('Arquivo salvo em: ' + cFileExc)
			EndIf
		EndIf
	EndIf
Return   

/*
+------------+--------------+---------+---------------------+--------+----------------+
! Funcao     ! FPOPEXCEL    ! Autor   ! Alessandro Smaha    ! Data   ! 23/11/2011       
+------------+--------------+---------+---------------------+--------+----------------+
! Parametros ! aDadosEx -> itens da planilha
!		   	 ! aStruEx	-> cabeçalho da planilha
!			 ! cPathEx  -> caminho para o arquivo Excel                                                                       
+------------+------------------------------------------------------------------------+
! Descricao  ! Cria e Popula a planilha do Excel...                                                                         
+------------+------------------------------------------------------------------------+
*/
Static Function FPOPEXCEL(aDadosEx, aStruEx, cPathEx, cTitulo)	
	Local cBuffer	:= "" 
	Local nCount	:= 0
	Local nX		:= 0
	Local nY		:= 0

	//Valida se o array contém os itens para inserir na planilha
	If !Len(aDadosEx) > 0
		MsgAlert(	"Planilha não foi criada!" + ;
					Chr(13) + Chr(10) + ;
					Chr(13) + Chr(10) + ;
		 			"Não tem itens para inserir na planilha!","Atenção")
		Return ""	
	EndIf

	cArq  := CriaTrab(Nil, .F.)
	nArq  := FCreate(cPathEx + cArq + ".CSV")

	If nArq == -1
		MsgAlert("Não conseguiu criar o arquivo!")
		Return
	EndIf

	//Grava título do relatório na primeira célula
	FWrite(nArq, cTitulo+";"+Chr(13) + Chr(10))

	// Carrega o cabeçalho no excel...
	For nX := 1 to Len(aStruEx) 
		cBuffer += aStruEx[nX][1]
		nCount	+= 1
		If (nX <> Len(aStruEx))
			cBuffer += ";"		
		EndIf
	Next nX

	//Insere o cabeçalho na planilha
	FWrite(nArq, cBuffer + Chr(13) + Chr(10)) 

	cBuffer := ""

	//Insere os itens do array na planilha...
	For nX := 1 to Len(aDadosEx)
		For nY := 1 to nCount
			// Verifica o tipo do campo para concatenar na string para adicinar o item...
			If ValType(aDadosEx[nX][nY]) == "C" 
				cBuffer += AllTrim(aDadosEx[nX][nY])
			ElseIf ValType(aDadosEx[nX][nY]) == "D"
				If DTOC(aDadosEx[nX][nY]) <> "  /  /  "
					cBuffer += DTOC(aDadosEx[nX][nY])
				EndIf			
			ElseIf ValType(aDadosEx[nX][nY]) == "N" 
				If (aStruEx[nY][3] == 14)
					cBuffer += Transform( aDadosEx[nX][nY], "@E 999,999,999.9999" ) 
				Else
					cBuffer += Transform( aDadosEx[nX][nY], "@E 999,999,999.9999" ) 
				EndIf										
			EndIf			

			If (nY <> nCount) 
				cBuffer += ";"			
			EndIf					
		Next nY 

		FWrite(nArq, cBuffer + Chr(13) + Chr(10))

		cBuffer := ""

	Next nX

	FClose(nArq)		

Return cPathEx + cArq + ".CSV"
