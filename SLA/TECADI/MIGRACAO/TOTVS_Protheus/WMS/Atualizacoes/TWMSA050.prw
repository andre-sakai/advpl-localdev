#Include 'Protheus.ch'
#INCLUDE 'FWMVCDEF.CH'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
! Descricao        ! Rotinas para integração entre os sistemas GWS (Sumitomo)!
!                  ! e Totvs, conforme projeto de integração 2019 fase 1     !
!                  !                                                         !
+------------------+---------------------------------------------------------+
! Sub-descrição    ! Tela de log e monitoramento das integrações             !
+------------------+---------------------------------------------------------+
! Autor            ! Luiz Fernando Berti - SLA Consultoria                   !
! Data de criação  ! 06/2019                                                 !
+------------------+---------------------------------------------------------+
! Redmine          ! 414                     ! Chamado           !           !
+------------------+--------------------------------------------------------*/

/*/{Protheus.doc} TWMSA050
Tela de log de integração Sumitomo.
@type function
@author Luiz Fernando Berti
@since 12/06/2019
@version 1.0
/*/
User Function TWMSA050()
	LOCAL oTabela:= nil
	LOCAL aHeader := {}
	PRIVATE aStruct := {}
	PRIVATE cAlias  := GetNextAlias()
	PRIVATE oBrowse := FWMBrowse():New()
	oTabela := FWTemporaryTable():New(cAlias)

	DBSelectArea("SZN")
	aStruct := DBSTruct()
	oTabela:SetFields(aStruct)
	oTabela:Create()

	//Popula arquivo temporário.
	Processa({|| U_TWMS050D() },"Processamento","...")

	//Popula campos para cabeçalho do grid.
	aEval(aStruct,{|aLinha| IIf(AllTrim(aLinha[01]) $ "ZN_FILIAL,ZN_DATA,ZN_HORA,ZN_DESCRI", aAdd(aHeader,{FWX3Titulo(aLinha[01]),aLinha[01],"C",TamSx3(aLinha[01])[1],0,""}), NIL) })

	//Mosta Grid de dados.
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias(cAlias)
	oBrowse:SetFields(aHeader )
	oBrowse:SetDescription("Log de Integração Sumitomo.")
	oBrowse:SetTemporary(.T.)
	oBrowse:Activate()

	oTabela:Delete()
Return

Static Function MenuDef()
	Local aRotina := {;
	{"Pesquisar"            ,"PesqBrw"         ,0,1 },;
	{"Visualizar"           ,"Processa({|| U_TWMS50V()})",0,2 },;
	{"Importar"             ,'Processa({|| U_TWMSA047(),U_TWMS050D(), oBrowse:GoTop() },"Processamento","...")',0,3 },;
	{"Reimportar"           ,'Processa({|| U_TWMSA501(),U_TWMS050D(), oBrowse:GoTop() },"Processamento","...")',0,4 },;
	{"Filtrar"              ,'Processa({|| U_TWMS050D(.T.), oBrowse:GoTop() },"Processamento","...")'          ,0,5 },;
	{"Relatório"            ,'Processa({|| U_TWMS048R()},"Processamento","...")'                               ,0,8 },;
	{"Exportar manualmente" ,'Processa({|| U_TWMS050E(), oBrowse:GoTop() },"Exportação de arquivo","...")'     ,0,2 } }

Return aRotina

//-------------------------------------------------------------------
Static Function ModelDef()

	Local oStruct
	Local oModel
	Local cDesc := "Log de importação Sumitomo"

	oStruct := getModelStruct()//FWFormStruct(1, cAlias,  { |x| ALLTRIM(x) $ "ZN_FILIAL,ZN_DATA,ZN_HORA,ZN_DESCRI" } )
	//+-------------------------------------------------------------------------------------+
	//! Define o modelo e uma função de pós-validação                                       !
	//+-------------------------------------------------------------------------------------+
	oModel  := MPFormModel():New("MODELO")
	oModel:SetDescription("teste")
	//+-------------------------------------------------------------------------------------+
	//! Adiciona os campos conforme a estrutura e adiciona também a chave da tabela         !
	//+-------------------------------------------------------------------------------------+
	oModel:AddFields("CAMPOS1", , oStruct)
	oModel:SetPrimaryKey({"ZN_DATA"})

Return oModel

//-------------------------------------------------------------------
Static Function ViewDef()

	Local oStruct
	Local oModel
	Local oView
	Local nOperation := 0
	//+-------------------------------------------------------------------------------------+
	//! Criação da estrutura, carga do modelo e inicialização da view                       !
	//+-------------------------------------------------------------------------------------+
	oModel := ModelDef()

	oStruct:= getViewStruct()//FWFormStruct(2, cAlias, { |x| ALLTRIM(x) $ "ZN_FILIAL,ZN_DATA,ZN_HORA,ZN_DESCRI" })
	oView  := FWFormView():New()
	//+-------------------------------------------------------------------------------------+
	//! Configura o modelo e adiciona seus campos conforme a estrutura criada               !
	//+-------------------------------------------------------------------------------------+
	oView:SetModel(oModel)
	oView:AddField("FORMULARIO1", oStruct,'CAMPOS1')
	oView:CreateHorizontalBox( 'BOXFORM1', 100)
	oView:SetOwnerView('FORMULARIO1','BOXFORM1')

Return oView

/*/{Protheus.doc} TWMSA501
Tela para reimportar um arquivo.
@type function
@author Usuário
@since 28/06/2019
/*/
User Function TWMSA501()

	LOCAL oDlg,oList1,oBtSair,oBrowse,oBtnPrimeiro,oBtnUltimo,oBtConfirm := nil
	LOCAL oFont  := TFont():New('Courier new',,16,.T.)
	LOCAL nAcao  := 0
	LOCAL nItem  := 0
	LOCAL nForTo := 0
	LOCAL nFor   := 0
	LOCAL cTipo  := ""
	LOCAL cMsg   := ""
	LOCAL cCodigo:= ""
	LOCAL cArqTxt:= ""
	LOCAL aItems := Directory("\sumitomo\erro\*.csv",,,,3)//Busca arquivos ordenado por data descendente. (Limite do componente 10.000 arqs).
	LOCAL bOrder    := {|x,y| (DToS(x[3])+x[1]) > (DToS(y[3])+y[1])   }//Ordena pela Data+Nome do Arquivo.
	LOCAL bPrimeiro := {|| oBrowse:GoTop(),oBrowse:setFocus()}
	LOCAL bUltimo   := {|| oBrowse:GoBottom(),oBrowse:setFocus() }

	If Len(aItems)==0
		Aviso("Seleção de Arquivos.","Não há arquivos para reimportar.",{"Prosseguir"})
		Return
	EndIf

	//Ordena os arquivos pelo nome do arquivo. A função Directory com parâmetro "3", ordena por data e tamanho do arquivo.
	aItems:= AClone(ASort(aItems,,,bOrder))

	For nArq:= 1 To Len(aItems)
		cArqTxt:= "\sumitomo\erro\"+aItems[nArq][01]
		If File(cArqTxt)
			oFile := FWFileReader():New(cArqTxt)//"TMSB707_TI_22_0000000013.csv"
			If (oFile:Open())
				aLinhas:= oFile:getAllLines()
				oFile:Close()
				aDados:= {}
				If Len(aLinhas) >0
					nForTo := 1
				EndIf
				For nFor:= 1 To nForTo
					cLinha:= aLinhas[nFor]
					If !Empty(cLinha)
						AADD(aDados,Separa(cLinha,CHR(9),.T.))
						cTipo := AllTrim(aDados[01][03])//EX_ACTION_CLASS
						Do Case
							Case cTipo $ "11,22"
							cCodigo:= aDados[01][10]
							Case cTipo $ "01,04,05"
							cCodigo:= aDados[01][06]
							Case cTipo == "41"
							cCodigo:= ""
						EndCase
					EndIf
				Next
			endif
		EndIf
		aItems[nArq][05]:= cCodigo
	Next

	oDlg := MSDialog():New(100,100,430,700,"Transferência de Arquivos",,,,,CLR_BLACK,/*nClrBack*/,,,.T.,,,,,)
	oDlg:lEscClose := .T.
	oPanel1:= tPanel():New(001,005,"Escolha um arquivo para Reimportar:",oDlg,oFont,,,CLR_BLACK,/*nClrBack*/,290,145,.F.,.T.)

	oBrowse := TCBrowse():New( 010 , 005, 280, 125,, {'Nome','Tamanho','Data','Hora','Código'},{20,50,50,50}, oPanel1,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
	oBrowse:SetArray(aItems)
	oBrowse:bLine := {||{ aItems[oBrowse:nAt,01],aItems[oBrowse:nAt,02],aItems[oBrowse:nAt,03],aItems[oBrowse:nAT,04],aItems[oBrowse:nAT,05] }}
	oBtnPrimeiro:= TButton():New(150, 110, "Primeiro Arquivo" , oDlg,bPrimeiro, 40, 010,,,.F.,.T.,.F.,,.F.,,,.F.)
	oBtnUltimo  := TButton():New(150, 160, "Último Arquivo", oDlg, bUltimo ,40,010,,,.F.,.T.,.F.,,.F.,,,.F.)
	oBtConfirm  := TButton():New(150, 210, "Confirmar"	,oDlg,{|| nAcao:= 1, nItem:=oBrowse:nAt ,oDlg:End()}	,40,10,,,.F.,.T.,.F.,,.F.,,,.F.)
	oBtSair     := TButton():New(150, 260, "Sair",oDlg,{|| oDlg:End()},30,10,,,.F.,.T.,.F.,,.F.,,,.F.)

	oDlg:lCentered := .T.
	oDlg:Activate()

	If nAcao == 1
		If (Aviso("Move Arquivo?","Deseja realmente mover o arquivo "+aItems[nItem,01]+"?",{"Sim","Não"},3))==1
			If nItem >0
				__CopyFile("\sumitomo\erro\"+aItems[nItem,01],"\sumitomo\"+"RI_"+aItems[nItem,01])
				cMsg:= "IMPORTAÇÃO SUMITOMO - TRANSFERENCIA ARQUIVO - DE - "+"\sumitomo\erro\"+aItems[nItem,01]+" - PARA - "+"\sumitomo\"+"RI_"+aItems[nItem,01]+" - TWMSA050 (TWMSA501) "
				U_FtGeraLog(cFilAnt, "", "", cMsg, "001", "", "000000")

				//Apaga o arquivo da pasta erro, por ser movido para a pasta raiz.
				If FErase("\sumitomo\erro\"+aItems[nItem,01]) == -1
					cMsg:= "IMPORTAÇÃO SUMITOMO - TRANSFERENCIA ARQUIVO - Erro ao apagar arquivo: \sumitomo\erro\"+aItems[nItem,01]+" - "+FERROR()
					U_FtGeraLog(cFilAnt, "", "", cMsg, "001", "", "000000")
				EndIf

				//Chama a rotina de importação.
				If ExistBlock("TWMSA047")
					ExecBlock("TWMSA047",.F.,.F.)
				Else
					Alert("ERRO - Função não compilada (TWMSA047). Contate o Administrador.")
				EndIf
			Else
				Aviso("Seleção de Arquivos.","Selecione um arquivo para reimportar.",{"Prosseguir"})
			EndIf
		EndIf
	EndIf
Return

/*/{Protheus.doc} U_TWMS050D
Função auxiliar para atualização do arquivo temporário.
@type function
@author Luiz Fernando Berti
@since 25/07/2019
@version 1.0
@param lFiltra, ${boolean}, (Indica se haverá filtro definido pelo usuário.)
@return ${return}, ${nil}
/*/
Function U_TWMS050D(lFiltra)

	LOCAL aButtons:= {}
	LOCAL aSays   := {}
	LOCAL cQuery := ""
	LOCAL cWhere := ""
	LOCAL cOrder := ""
	LOCAL cCab   := "Filtro de Log."
	LOCAL cPerg  := "TWMSA050  "
	LOCAL nCount := 0
	DEFAULT lFiltra := .F.
	Pergunte(cPerg,.F.)

	If lFiltra
		aadd(aSays,"Selecione um filtro para realizar a busca no Log.")
		aadd(aSays,"Ao utilizar a pesquisa por descrição ou um range de parâmetros muito extenso, ")
		aadd(aSays,"a consulta pode se tornar demorada.")
		aadd(aButtons, { 5,.T.,{|| Pergunte(cPerg,.T. ) } } )
		aadd(aButtons, { 1,.T.,{|| lFiltra:= .T., FechaBatch() }} )
		aadd(aButtons, { 2,.T.,{|| lFiltra:= .F., FechaBatch() }} )
		FormBatch( cCab, aSays, aButtons,, 160 )
		If lFiltra
			cWhere:= " AND ZN_FILIAL >='"+MV_PAR01+"'"
			cWhere+= " AND ZN_FILIAL <='"+MV_PAR02+"'"
			cWhere+= " AND ZN_DATA >='"+DToS(MV_PAR03)+"'"
			cWhere+= " AND ZN_DATA <='"+DToS(MV_PAR04)+"'"
			If !Empty(MV_PAR05)
				cWhere+= " AND ZN_DESCRI LIKE ('%"+AllTrim(MV_PAR05)+"%') "
			Else
				cWhere+= " AND (SUBSTRING(ZN_DESCRI,0,5) = 'ERRO' OR SUBSTRING(ZN_DESCRI,0,5) = '|ERR')"
			EndIf
		EndIf
	EndIf

	//Limpa o arquivo temporário.
	(cAlias)->(__DBZap())

	//Filtro SQL para browse
	cQuery:= "SELECT * FROM "+RetSQLName("SZN")
	cQuery+= " WHERE "
	cQuery+= " ZN_DEPTO IN ('001','002') "
	If !lFiltra
		cWhere:= " AND ZN_DATA >= '"+DToS(dDataBase-3)+"' "
		cWhere+= " AND ZN_FILIAL = '"+xFilial("SZN")+"' "
		cWhere+= " AND (SUBSTRING(ZN_DESCRI,0,5) = 'ERRO' OR SUBSTRING(ZN_DESCRI,0,5) = '|ERR') "
	EndIf
	cWhere+= " AND D_E_L_E_T_ != '*' "
	cOrder:= " ORDER BY ZN_FILIAL, ZN_DATA, ZN_HORA"
	If Select("TRBSZN")<>0
		DBSelectArea("TRBSZN")
		DBCloseArea()
	EndIf
	DBUseArea(.T., "TOPCONN", TCGenQry(NIL,NIL,ChangeQuery(cQuery+cWhere+cOrder)), "TRBSZN" , .F., .T. )
	AEval(aStruct, { |aLin|   IIf(aLin[02]<> "C",TcSetField("TRBSZN",aLin[01],aLin[02],aLin[03],aLin[04]), NIL)    })
	Do While !TRBSZN->(Eof())
		IncProc()
		nCount++
		(cAlias)->(DBAppend(.F.))
		aEval(aStruct, {|aLinha|  (cAlias)->&(aLinha[1]):= TRBSZN->&(aLinha[1]) } )
		(cAlias)->(DBCommit())
		TRBSZN->(DBSkip())
	EndDo
	(cAlias)->(DBGoTop())
	If Select("TRBSZN")<>0
		DBSelectArea("TRBSZN")
		DBCloseArea()
	EndIf

	//Quando não houver informações com o filtro padrão, pergunta ao usuário se deseja inserir outros filtros.
	If nCount == 0 .And. (Aviso("Consulta","A consulta do Log não trouxe informações, deseja alterar o filtro?",{"Sim","Não"})==1)
		U_TWMS050D(.T.)
	EndIf

Return

/*/{Protheus.doc} U_TWMS50V
Função temporária para visualização do Log, pois, no MVC é preciso alterar para a tabela temporária.
@type function
@author Luiz Fernando
@since 25/07/2019
@version 1.0
@return ${return}, ${nil}
/*/
Function U_TWMS50V()

	LOCAL oFont    := TFont():New("Arial",,-12,.T.)
	LOCAL nColSay  := 01
	LOCAL nColGet  := 40
	LOCAL nColSay2 := 120
	LOCAL nColGet2 := 160
	LOCAL nLinha   := 010
	LOCAL cFilSZN  := (cAlias)->ZN_FILIAL
	LOCAL dData    := (cAlias)->ZN_DATA
	LOCAL cHora    := (cAlias)->ZN_HORA
	LOCAL cDescri  := (cAlias)->ZN_DESCRI

	oDlg := MSDialog():New(000,000,305,705, "Log",,,,,,,,,.T.)
	oDlg:lEscClose := .T.
	oSay    := TSay():New(nLinha,nColSay,{||"Filial: "},oDlg,,oFont,,,,.T.,CLR_BLUE,CLR_WHITE,100,90)
	oGetOS  := TGet():New(nLinha,nColGet,{|u| (cAlias)->ZN_FILIAL }, oDlg,60,9,'',{ ||  },,,,,,.T.,,, {|| .F. } ,,,,(.F.),,"","cNumOs")

	nLinha+=15
	oSay    := TSay():New(nLinha,nColSay,{||"Data: "},oDlg,,oFont,,,,.T.,CLR_BLUE,CLR_WHITE,100,90)
	oGetOS  := TGet():New(nLinha,nColGet,{|u| if(PCount()>0,dData:=u,dData) }, oDlg,60,9,'',{ ||  },,,,,,.T.,,, {|| .F. } ,,,,(.F.),,"","dData")

	nLinha+=15
	oSay    := TSay():New(nLinha,nColSay,{||"Hora: "},oDlg,,oFont,,,,.T.,CLR_BLUE,CLR_WHITE,100,90)
	oGetOS  := TGet():New(nLinha,nColGet,{|u| if(PCount()>0,cHora:=u,cHora) }, oDlg,60,9,'',{ ||  },,,,,,.T.,,, {|| .F. } ,,,,(.F.),,"","cHora")

	nLinha+=15
	oSay    := TSay():New(nLinha,nColSay,{||"Descrição: "},oDlg,,oFont,,,,.T.,CLR_BLUE,CLR_WHITE,100,90)
	oGetOS  := TGet():New(nLinha,nColGet,{|u| if(PCount()>0,cDescri:=u,cDescri) }, oDlg,300,9,'',{ ||  },,,,,,.T.,,, {|| .T. } ,,,,(.F.),,"","cDescri")

	nLinha+=15
	oBtSair   := TButton():New(nLinha, nColSay, "Sair",oDlg,{|| oDlg:End()},30,10,,,.F.,.T.,.F.,,.F.,,,.F.)

	oDlg:lCentered := .T.
	oDlg:Activate()
Return

/*/{Protheus.doc} U_TWMS048R
Relatório gernérico para conferencia de arquivos importados.
@author Luiz Fernando
@type function
@since 07/08/2019
@version 1.0
@return ${return}, ${return_description}

/*/
Function U_TWMS048R()

	Local oReport

	oReport := ReportDef()
	oReport	:PrintDialog()

Return

/*/{Protheus.doc} ReportDef
Cria a estrutura do relatorio
@author Usuário
@type function
@since 07/08/2019
@version 1.0
@return ${return}, ${return_description}
/*/
Static Function ReportDef()

	Local cAlias	 := ""
	Local cTitle	 := OemToAnsi ("Arquivos Importados.")
	Local oReport
	Local oSection1
	Local oBreak
	Local cOrdem	 := ""
	Local cQuebra    := ""
	Private cHelp	 := OemToAnsi ("Relata de Arquivos Importados.")

	cAlias  			   := GetNextAlias()
	oReport				:= TReport():New("TWMS048R",cTitle, ,{|oReport|ReportPrint(oReport)},cHelp)
	oReport:SetLandscape()
	oReport:HideParamPage()

	oSection1:= TRSection():New(oReport,"TWMS048R")

	//Seção 1
	TRCell():New(oSection1,	"FILIAL"	, "", "Filial"            ,"@!", 12)
	TRCell():New(oSection1,	"DTIMPO"	, "", "Data"            ,"@!", 12)
	TRCell():New(oSection1,	"HORA"	, "", "Hora"      	     , "@!", 12)
	TRCell():New(oSection1,	"ARQUIVO"	, "", "Arquivo"       		 ,"@!" , 25)
	TRCell():New(oSection1,	"TEXTO"	, "", "Texto"       		 ,"@!" , 200)

Return(oReport)

/*/{Protheus.doc} ReportPrint
Alimenta o reltatório.
@author Luiz Fernando
@since 07/08/2019
@version 1.0
@return ${return}, ${return_description}
@param oReport, object, (Objeto do relatório)
@type function
/*/

Static Function ReportPrint(oReport)

	LOCAL oSection1b := oReport:Section(1)
	LOCAL cQuery := ""
	LOCAL aDados := {}
	LOCAL cPerg  := "TWMSA050  "
	LOCAL cChave := UPPER("\sumitomo\")
	LOCAL cString:= "Alltrim(TRBSZN->ZN_DESCRI)"
	LOCAL nIni,nFim := 0

	Pergunte(cPerg,.T.)
	//Busca os dados dos arquivos importados.
	cQuery:= "SELECT * FROM "+RetSQLName("SZN")
	cQuery+= " WHERE ""
	cQuery+= "  D_E_L_E_T_ != '*' "
	cQuery+= " AND ZN_DEPTO = '001'"
	cQuery+= " AND ZN_FILIAL >='"+MV_PAR01+"'"
	cQuery+= " AND ZN_FILIAL <='"+MV_PAR02+"'"
	cQuery+= " AND ZN_DATA >='"+DToS(MV_PAR03)+"'"
	cQuery+= " AND ZN_DATA <='"+DToS(MV_PAR04)+"'"
	If !Empty(MV_PAR05)
		cQuery+= " AND ZN_DESCRI LIKE ('%"+AllTrim(MV_PAR05)+"%') "
	EndIf
	cQuery+= "  AND ZN_DESCRI like '%\sumitomo\%'"
	cQuery+= "  ORDER BY ZN_FILIAL, ZN_DATA, ZN_HORA"
	If Select("TRBSZN")<>0
		DBSelectArea("TRBSZN")
		DbCloseArea()
	EndIf
	DBUseArea(.T., "TOPCONN", TCGenQry(NIL,NIL,cQuery), "TRBSZN" , .F., .T. )
	TcSetField("TRBSZN","ZN_DATA","D",8,0)

	Do While !TRBSZN->(Eof())

		//Busca pelo nome do arquivo na descrição do LOG.
		cString:= Alltrim(TRBSZN->ZN_DESCRI)
		nIni    := AT(cChave, Upper(cString))
		cString := AllTrim(Substr(cString,nIni+Len(cChave)))
		nFim    := AT("CSV", Upper(cString))
		nFim    := IIf(nFim == 0,Len(cString), nFim - 1)
		cString := Subs(cString,1,nFim+3)

		If (nPos := aScan(aDados,{|x| AllTrim(x[03]) == Alltrim(cString)})) ==0
			aadd(aDados, {TRBSZN->ZN_DATA, TRBSZN->ZN_HORA, cString,TRBSZN->ZN_DESCRI,TRBSZN->ZN_FILIAL })
		EndIf
		TRBSZN->(DBSkip())
	EndDo
	If Select("TRBSZN")<>0
		DBSelectArea("TRBSZN")
		DbCloseArea()
	EndIf

	oReport:SetMeter(Len(aDados))
	oSection1b:Init()

	For nCount := 1 To Len(aDados)
		oReport:IncMeter()
		oSection1b:Cell("FILIAL"):SetValue( aDados[nCount][05])
		oSection1b:Cell("DTIMPO"):SetValue( aDados[nCount][01])
		oSection1b:Cell("HORA"):SetValue( aDados[nCount][02])
		oSection1b:Cell("ARQUIVO"):SetValue( aDados[nCount][03])
		oSection1b:Cell("TEXTO"):SetValue( aDados[nCount][04])
		oSection1b:PrintLine()
	Next
	oSection1b:Finish()
Return

// funçao para permitir gerar novo arquivo de exportação
User Function TWMS050E()

	Local _cPerg := PadR("TWMSA050E",10)
	Local _aAreaZ05 := Z05->(GetArea())

	If !Pergunte(_cPerg, .T.)

		//localiza a OS para pegar dados do cliente e saber se é entrada ou saída
		DbSelecArea("Z05")
		Z05->(DbSetOrder(1)) // 1 - Z05_FILIAL, Z05_NUMOS, R_E_C_N_O_, D_E_L_E_T_
		If Z05->(dbSeek( xFilial("Z05") + MV_PAR01))
			//executa a exportação
			ExecBlock("TWMSA048",.F.,.F.,;
			{Z05->Z05_TPOPER,;
			Z05->Z05_NUMOS,;
			IIF(Z05->Z05_TPOPER == "S","003", "001"),;
			Z05->Z05_CLIENT,;
			Z05->Z05_LOJA})
		Else
			MsgAlert("Ordem de serviço não encontrada", "Erro TWMS050E")
		EndIf
	EndIf

	RestArea(_aAreaZ05)
Return
