#INCLUDE "PROTHEUS.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE 'RWMAKE.CH'
#INCLUDE 'FONT.CH'
#INCLUDE 'COLORS.CH'
#INCLUDE "RPTDEF.CH"
#Include 'ISAMQry.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Impressao de Boletos de Cobranca                        !
+------------------+---------------------------------------------------------+
!Autor             ! Diana                                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2010                                                 !
+------------------+--------------------------------------------------------*/

User Function TFIN001()

	// define o grupo de perguntas
	local _aPerg := {}
	local _cPerg := PadR('TFIN001',Len(SX1->X1_GRUPO))

	//Tipo de Impressão (.T. = PDF , .F. = TELA)
	Local _lImpPdf  := .F.

	// define o grupo de perguntas
	aAdd(_aPerg,{"De  Prefixo?"   ,"C",TamSx3("E1_PREFIXO")[1],0,"G",,""})    //mv_par01
	aAdd(_aPerg,{"Ate Prefixo?"   ,"C",TamSx3("E1_PREFIXO")[1],0,"G",,""})    //mv_par02
	aAdd(_aPerg,{"De  Numero?"    ,"C",TamSx3("E1_NUM")[1]    ,0,"G",,""})    //mv_par03
	aAdd(_aPerg,{"Ate Numero?"    ,"C",TamSx3("E1_NUM")[1]    ,0,"G",,""})    //mv_par04
	aAdd(_aPerg,{"De  Parcela?"   ,"C",TamSx3("E1_PARCELA")[1],0,"G",,""})    //mv_par05
	aAdd(_aPerg,{"Ate Parcela?"   ,"C",TamSx3("E1_PARCELA")[1],0,"G",,""})    //mv_par06
	aAdd(_aPerg,{"Tipo do Titulo?","C",TamSx3("E1_TIPO")[1]   ,0,"G",,"05"})  //mv_par07
	aAdd(_aPerg,{"Banco?"         ,"C",TamSx3("A6_COD")[1]    ,0,"G",,"SA6"}) //mv_par08
	aAdd(_aPerg,{"Agencia?"       ,"C",TamSx3("A6_AGENCIA")[1],0,"G",,""})    //mv_par09
	aAdd(_aPerg,{"Conta?"         ,"C",TamSx3("A6_NUMCON")[1] ,0,"G",,""})    //mv_par10

	// cria grupo de perguntas
	U_FtCriaSX1( _cPerg,_aPerg )

	If (!Pergunte(_cPerg,.t.))
		Return
	EndIf

	//Desabilitado Opção de impressão pelo TMSPrinter
	_lImpPdf := .T.

	// processa a impressao do boleto
	Processa({|lEnd| U_TFIN001A(mv_par01, mv_par02, mv_par03, mv_par04, mv_par05, mv_par06, mv_par07, mv_par08, mv_par09 ,mv_par10,,,_lImpPdf,.F.) })

Return

//** rotina para impressao das informacoes, conform parametros
User Function TFIN001A(mvPrefDe, mvPrefAte, mvNumDe, mvNumAte, mvParcDe, mvParcAte, mvTpTit, mvBanco, mvAgencia, mvConta, mvDirPadr, mvNomeArq, mvImpPdf, mvRotAut)

	// Percentual de multa para os titulos em atraso
	local _nPerMulta := SuperGetMV("MV_LJMULTA", NIL, 0)

	LOCAL _oPrint
	Local _cNroDoc :=  " "


	LOCAL _aDadosEmp := { SM0->M0_NOMECOM                                       ,; //[1]Nome da Empresa
	SM0->M0_ENDCOB																,; //[2]Endereo
	AllTrim(SM0->M0_BAIRCOB)+" - "+AllTrim(SM0->M0_CIDCOB)+" - "+SM0->M0_ESTCOB	,; //[3]Complemento
	"CEP: "+Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)				,; //[4]CEP
	"FONE: "+AllTrim(SM0->M0_TEL)+"  FAX: "+AllTrim(SM0->M0_FAX)				,; //[5]Telefones
	"CNPJ: "+Subs(SM0->M0_CGC,1,2)+"."+Subs(SM0->M0_CGC,3,3)+"."+				;  //[6]
	Subs(SM0->M0_CGC,6,3)+"/"+Subs(SM0->M0_CGC,9,4)+"-"+						;  //[6]
	Subs(SM0->M0_CGC,13,2)														,; //[6]CGC
	"I.E.: "+Subs(SM0->M0_INSC,1,3)+"."+Subs(SM0->M0_INSC,4,3)+"."+				;  //[7]
	Subs(SM0->M0_INSC,7,3)+"."+Subs(SM0->M0_INSC,10,3)							}  //[7]I.E

	LOCAL _aDadosTit
	LOCAL _aDadosBanco
	LOCAL _aDatSacado
	LOCAL _aBolText := {"Após o vencimento cobrar multa de "+Str(_nPerMulta,5,2)+" % " ,;
		"Após o vencimento, mora dia R$ "                                              ,;
		"Sr. Caixa não conceder desconto no titulo "                                   ,;
		"Protesto em cinco dias. DEPÓSITO NÃO QUITA BOLETO "                            }

	LOCAL aCB_RN_NN    := {}

	// valor do boleto (saldo + acrescimos)
	local _nVlrBoleto := 0

	// query
	Local _cQuery := ""

	// opcao para reimpressao de boleto (1-Fechar, 2-2a Via)
	// opcao para gerar novo boleto
	private _lNewBoleto := .t.

	// fixa sub-conta 001 pra todos os bancos
	private cSubConta := "001"
	// imagem da logo
	private _cImagem := "\"+AllTrim(CurDir())+"\logo_tecadi.jpg"

	//Parametros recebidos por Rotina automatica.
	Default mvRotAut    := .F.
	Default mvTpTit    := "NF"
	Default mvBanco    := SuperGetmv("TC_BANCO",,"")
	Default mvAgencia  := SuperGetmv("TC_AGENCIA",,"")
	Default mvConta    := SuperGetmv("TC_CONTA",,"")
	Default mvDirPadr   := ""
	Default mvNomeArq := ""

	// monta a query para filtrar os titulos
	_cQuery := "SELECT E1_PREFIXO, E1_NUM, R_E_C_N_O_ SE1RECNO "
	// titulos a receber
	_cQuery += "FROM "+RetSqlTab("SE1")
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SE1")+" AND "
	// prefixo
	_cQuery += "E1_PREFIXO BETWEEN '"+mvPrefDe+"' AND '"+mvPrefAte+"' AND "
	// numero do titulo
	_cQuery += "E1_NUM BETWEEN '"+mvNumDe+"' AND '"+mvNumAte+"' AND "
	// prcela
	_cQuery += "E1_PARCELA BETWEEN '"+mvParcDe+"' AND '"+mvParcAte+"' AND "
	// tipo do titulo
	_cQuery += "E1_TIPO = '"+mvTpTit+"' AND "
	// saldo
	_cQuery += "E1_SALDO > 0 AND "
	// tipo do titulo
	_cQuery += "E1_TIPO NOT IN "+FormatIN(MVRECANT+MVPROVIS+MV_CRNEG+StrTran(MVABATIM,"|",""),,3)+" "
	// ordem dos dados
	_cQuery += "ORDER BY E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA "

	memowrit("c:\query\TFIN001.txt",_cQuery)

	If (Select("_QRYSE1") <> 0)
		dbSelectArea("_QRYSE1")
		dbCloseArea()
	EndIf

	// executa a query
	TCQUERY _cQuery NEW ALIAS "_QRYSE1"
	dbSelectArea("_QRYSE1")

	//Quando nao houver dados
	If _QRYSE1->(Eof())
		// fecha a query
		dbSelectArea("_QRYSE1")
		dbCloseArea()
		// mensagem
		If AllTrim(FunName())=="TFIN001"
			MsgStop("Nao ha dados para Impressão!")
		EndIf
		Return .f.
	EndIf

	//Tipo de impressão.
	Private lFWMS := mvImpPdf

	// variaveis para gerenciar a criação do PDF
	Private lAdjustToLegacy		:= .T.
	Private lDisableSetup 		:= .T.
	Private lServer 			:= .T.
	Private lPDFAsPNG			:= .F.
	Private lViewPDF			:= .T.
	Private cDirPrint			:= Iif(Empty(mvDirPadr)  ,AllTrim(GetTempPath()),mvDirPadr)
	Private cFileOP				:= Iif(Empty(mvNomeArq),"TFIN001"               ,mvNomeArq)
	Private cArqDir				:= cDirPrint + cFileOP + ".pdf"
	Private cArqTemp			:= cDirPrint + cFileOP + ".rel"

	//Apaga arquivos Temporarios
	FErase(cArqDir)
	FErase(cArqTemp)

	// prepara objeto de impressa
	If (lFWMS)
		_oPrint := FWMsPrinter():New(cFileOP+".pdf",IMP_PDF,lAdjustToLegacy,cDirPrint,lDisableSetup, /*[lTReport]*/, /*[@_oPrintSetup]*/, /*[ cPrinter]*/, lServer, lPDFAsPNG, /*[ lRaw]*/, lViewPDF, /*[ nQtdCopy]*/ )
	Else
		_oPrint := TMSPrinter():New( "Boleto Laser" )
	EndIf

	//Impressão com o componente FWMsPrinter PDF
	If lFWMS
		_oPrint:SetResolution(78) //Tamanho estipulado para a Danfe
		_oPrint:SetPortrait()
		_oPrint:SetPaperSize(DMPAPER_A4)
		_oPrint:nDevice := IMP_PDF
		_oPrint:cPathPDF := cDirPrint
		If 	(!mvRotAut)
			_oPrint:Setup()
			If _oPrint:nModalResult == 2
				//Apaga arquivos Temporarios
				FErase(_oPrint:cPathPDF + cFileOP + ".pdf")
				FErase(_oPrint:cPathPDF + cFileOP + ".rel")
				_oPrint:Cancel()
				_oPrint:Deactivate()
				Return()
			EndIf
			_oPrint:GetViewPDF(.T.)
			_oPrint:SetViewPDF(.T.)
		Else
			_oPrint:GetViewPDF(.F.)
			_oPrint:SetViewPDF(.F.)
		EndIf
		//Impressão com o componente TMSPrinter.
	Else
		_oPrint:SetPortrait()
	EndIF

	//Apaga arquivos Temporarios
	FErase(_oPrint:cPathPDF + cFileOP + ".pdf")
	FErase(_oPrint:cPathPDF + cFileOP + ".rel")

	dbSelectArea("_QRYSE1")
	_QRYSE1->(dbGoTop())

	While (_QRYSE1->(!Eof()))

		// posiciona no registro da tabela SE1
		dbSelectArea("SE1")
		SE1->(dbGoTo(_QRYSE1->SE1RECNO))

		// define se eh novo boleto
		_lNewBoleto	:= (Empty(SE1->E1_NUMBCO))









		// se for novo boleto
		If (_lNewBoleto)
			DbSelectArea("SA6")
			DbSetOrder(1)
			If !(DbSeek(xFilial("SA6")+mvBanco+mvAgencia+mvConta))
				Msgbox(xFilial("SA6")+mvBanco+mvAgencia+mvConta+' - Conta Invalida')
				return(.f.)
			EndIf

			// ** DEFINICAO DO NOSSO NUMERO
			// posiciona nos Parametros do Banco
			dbSelectArea("SEE")
			SEE->(dbSetorder(1))
			If (!SEE->(dbSeek( xFilial("SEE")+mvBanco+mvAgencia+mvConta+cSubConta )))
				MsgStop("Parametros do banco não cadastrado!")
				Return(.f.)
			EndIf

			// se for segunda via do boleto
		ElseIf (!_lNewBoleto)
			DbSelectArea("SA6")
			DbSetOrder(1)
			If !(DbSeek( xFilial("SA6")+SE1->(E1_PORTADO+E1_AGEDEP+E1_CONTA) ))
				Msgbox(xFilial("SA6")+SE1->(E1_PORTADO+E1_AGEDEP+E1_CONTA)+' - Conta Invalida')
				return(.f.)
			EndIf

			// ** DEFINICAO DO NOSSO NUMERO
			// posiciona nos Parametros do Banco
			dbSelectArea("SEE")
			SEE->(dbSetorder(1))
			If (!SEE->(dbSeek( xFilial("SEE")+SE1->(E1_PORTADO+E1_AGEDEP+E1_CONTA)+cSubConta )))
				MsgStop("Parametros do banco não cadastrado!")
				Return(.f.)
			EndIf

		EndIf

		// atualiza variaveis
		sBcoBco		:= SA6->A6_COD
		sBcoAge		:= SA6->A6_AGENCIA
		sBcoCon		:= SA6->A6_NUMCON
		cCart		:= If(sBcoBco=="341","1","")+AllTrim(SEE->EE_CODCOBE)

		// valida as informacoes do nosso numero
		If (_lNewBoleto)
			If ((Empty(SEE->EE_FAXINI)).or.(Empty(SEE->EE_FAXFIM)).or.(Empty(SEE->EE_FAXATU)))
				MsgStop("Erro na definicao da faixa Inicial, Final e Atual dos Parametros do banco!")
				Return(.f.)
			EndIf
		EndIf

		// quantidade de caracteres para o nosso numero
		_nTamNosNum := Len(AllTrim(SEE->EE_FAXINI))

		// verifica a situacao do boleto
		If (!_lNewBoleto)
			//Se não for por rotina automatica não chama pergunta.
			If (!mvRotAut)
				// opcao para reimpressao de boleto (1-Fechar, 2-2a Via)
				If ( Aviso("Boletos...","Boleto gerado anteriormente. Selecione a opção desejada...",{"Fechar","2a Via"} ) <= 1)
					dbSelectArea("_QRYSE1")
					_QRYSE1->(DbSkip())
					Loop
				EndIf
			EndIF
		EndIf

		// se for novo boleto, pega a proxima numeracao
		If (_lNewBoleto)
			// incrementa o sequencial no nosso numero
			// verifica se o sequencial nao é maior q o permitido
			If (Val(SEE->EE_FAXATU)+1 > Val(SEE->EE_FAXFIM))
				// reinicia o sequencial
				Reclock("SEE",.f.)
				SEE->EE_FAXATU := SEE->EE_FAXINI
				Msunlock("SEE")
			Else
				Reclock("SEE",.f.)
				SEE->EE_FAXATU := StrZero(Val(Left(SEE->EE_FAXATU,_nTamNosNum))+1,_nTamNosNum)
				Msunlock("SEE")
			EndIf

			// utiliza a sequencia do nosso numero
			_cNroDoc := Left(SEE->EE_FAXATU,_nTamNosNum)

			// se for segunda via, utiliza o numero gerado anteriormente
		ElseIf (!_lNewBoleto)

			// utiliza a sequencia do nosso numero
			_cNroDoc := SubStr(SE1->E1_NUMBCO,Len(cCart)+1,_nTamNosNum)

		EndIf

		// armazena os dados do banco
		_aDadosBanco := {SA6->A6_COD    ,; // [1] Numero do Banco
		SA6->A6_NOME                    ,; // [2] Nome do Banco
		SUBSTR(SA6->A6_AGENCIA, 1, 4)   ,; // [3] Agencia
		IIF(Empty(SA6->A6_DVCTA),substr(SA6->A6_NUMCON,5,5),substr(SA6->A6_NUMCON,6,5) )     ,; // [4] Conta Corrente
		IIF(Empty(SA6->A6_DVCTA),substr(SA6->A6_NUMCON,10,1),SA6->A6_DVCTA),; // [5] Digito da conta corrente
		cCart                           ,; // [6] Codigo da Carteira
		AllTrim(SEE->EE_CODEMP)          } // [7] Codigo da Empresa (Cedente)

		//Posiciona o SA1 (Cliente)
		DbSelectArea("SA1")
		SA1->(DbSetOrder(1))
		SA1->(DbSeek( xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA ))

		If Empty(SA1->A1_ENDCOB)
			_aDatSacado   := {AllTrim(SA1->A1_NOME)           ,; // [1]Razo Social
			AllTrim(SA1->A1_COD )+"-"+SA1->A1_LOJA            ,; // [2]Cdigo
			AllTrim(SA1->A1_END )+"-"+AllTrim(SA1->A1_BAIRRO) ,; // [3]Endereo
			AllTrim(SA1->A1_MUN )                             ,; // [4]Cidade
			SA1->A1_EST                                       ,; // [5]Estado
			SA1->A1_CEP                                       ,; // [6]CEP
			SA1->A1_CGC                                       ,; // [7]CGC
			SA1->A1_PESSOA                                     } // [8]PESSOA
		Else
			_aDatSacado   := {AllTrim(SA1->A1_NOME)              ,; // [1]Razo Social
			AllTrim(SA1->A1_COD )+"-"+SA1->A1_LOJA               ,; // [2]Cdigo
			AllTrim(SA1->A1_ENDCOB)+"-"+AllTrim(SA1->A1_BAIRROC) ,; // [3]Endereo
			AllTrim(SA1->A1_MUNC)                                ,; // [4]Cidade
			SA1->A1_ESTC                                         ,; // [5]Estado
			SA1->A1_CEPC                                         ,; // [6]CEP
			SA1->A1_CGC                                          ,; // [7]CGC
			SA1->A1_PESSOA                                        } // [8]PESSOA
		Endif

		DbSelectArea("SE1")

		// calculo o valor do boleto
		_nVlrBoleto := SaldoTit(SE1->E1_PREFIXO, ;
			SE1->E1_NUM     ,;
			SE1->E1_PARCELA ,;
			SE1->E1_TIPO    ,;
			SE1->E1_NATUREZ ,;
			"R"             ,;
			SE1->E1_CLIENTE ,;
			1               ,;
			SE1->E1_VENCREA,,;
			SE1->E1_LOJA   ,,;
			SE1->E1_TXMOEDA  )

		// monta codigo de barras
		dbSelectArea("SE1")




		// prepara as informacoes do codigo de barras
		// Ret_cBarra(cBanco,cAgencia,cConta,cDacCC,_cNroDoc,nValor,dVencto)
		aCB_RN_NN := Ret_cBarra(_aDadosBanco[1],;
			_aDadosBanco[3],;
			_aDadosBanco[4],;
			_aDadosBanco[5],;
			_cNroDoc       ,;
			_nVlrBoleto    ,;
			SE1->E1_VENCTO  )


		// dados do titulas
		_aDadosTit	:= {StrZero(	Val(Alltrim(SE1->E1_NUM)),8)+AllTrim(SE1->E1_PARCELA)		,;  // [1] Nmero do ttulo
		SE1->E1_EMISSAO    ,;  // [2] Data da emisso do ttulo
		dDataBase          ,;  // [3] Data da emisso do boleto
		SE1->E1_VENCTO     ,;  // [4] Data do vencimento
		_nVlrBoleto        ,;  // [5] Valor do titulo // (SE1->E1_SALDO - nVlrAbat)
		aCB_RN_NN[3]       ,;  // [6] Nosso nmero (Ver frmula para calculo)
		SE1->E1_PREFIXO    ,;  // [7] Prefixo da NF
		"DS"               ,;  // [8] Tipo do Titulo
		SE1->E1_VALJUR     ,;  // [9] Valor de Juros/Dia (E1_VALJUR)
		SE1->E1_NFELETR    }   // [10] Número da nota fiscal eletrônica


		// realiza a impressao das informacoes
		sfImpress(_oPrint, _aDadosEmp, _aDadosTit, _aDadosBanco, _aDatSacado, _aBolText, aCB_RN_NN)

		// finaliza a pagina
		_oPrint:EndPage()

		dbSelectArea("_QRYSE1")
		_QRYSE1->(dbSkip())
	EndDo

	_oPrint:Print()

Return()

/*/
Programa    Impress  Autor  Microsiga              Data  13/10/03
Descrio  	IMPRESSAO DO BOLETO LASER DO ITAU COM CODIGO DE BARRAS
Uso			Especifico para Clientes Microsiga
/*/
Static Function sfImpress(_oPrint,_aDadosEmp,_aDadosTit,_aDadosBanco,_aDatSacado,_aBolText,aCB_RN_NN)

	LOCAL oFont8
	LOCAL oFont11c
	LOCAL oFont10
	LOCAL oFont14
	LOCAL oFont16n
	LOCAL oFont15
	LOCAL oFont14n
	LOCAL oFont24
	LOCAL nI := 0

	LOCAL _cNrDoc := ""		//numero do documento no boleto


	// pesquisa a nota fiscal (RPS) e retorna a NFS-e
	local _cNumNFSe := Posicione("SF2",1, xFilial("SF2")+SE1->(E1_NUM+E1_PREFIXO+E1_CLIENTE+E1_LOJA) ,"F2_NFELETR" )


	//preenche o numero do documento, que sera utilizado na impressão no campo homônimo mais abaixo no código
	If ! Empty(_aDadosTit[10]) //se o titulo tiver NF eletronica usa o número dela
		// valida tamanho do conteudo do campo numero da nota (depende do retorno do XML da prefeitura)
		If (Len(AllTrim(_aDadosTit[10])) == 15)
			_cNrDoc := SubStr(_aDadosTit[10], 5, 11)
		Else
			_cNrDoc := StrZero( Val(_aDadosTit[10]), 10)
		EndIf
	Else //caso contrario, usa numero do titulo no financeiro
		_cNrDoc := StrZero( Val(Substr( _aDadosTit[1],0,9 )) , 10)
	Endif

	//Parametros de TFont.New()
	//1.Nome da Fonte (Windows)
	//3.Tamanho em Pixels
	//5.Bold (T/F)
	oFont8  := TFont():New("Arial",9,8,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont11c := TFont():New("Courier New",9,11,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont10  := TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont14  := TFont():New("Arial",9,14,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont20  := TFont():New("Arial",9,20,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont21  := TFont():New("Arial",9,21,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont16n := TFont():New("Arial",9,16,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont15  := TFont():New("Arial",9,15,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont15n := TFont():New("Arial",9,15,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont14n := TFont():New("Arial",9,14,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont24  := TFont():New("Arial",9,24,.T.,.T.,5,.T.,5,.T.,.F.)

	_oPrint:StartPage()   // Inicia uma nova pgina
	//Escolhido o componente FWMsPrinter impressão em PDF.
	If lFWMS

		///* PRIMEIRA PARTE
		nRow1 := 0
		//_oPrint:SayBitmap(0100, 100,"tecadi_.bmp",855,380 )
		_oPrint:SayBitmap(0100,100,_cImagem,744.8,239.4)
		_oPrint:Say  (nRow1+0150,1060,AllTrim(_aDadosEmp[1]),oFont15)
		_oPrint:Say  (nRow1+0250,1060,AllTrim(_aDadosEmp[2])+" - "+AllTrim(_aDadosEmp[3]),oFont10)
		_oPrint:Say  (nRow1+0350,1060,AllTrim(_aDadosEmp[4])+" / "+AllTrim(_aDadosEmp[5]),oFont10)
		// segunda via
		If (!_lNewBoleto)
			_oPrint:Say (nRow1+0150,2100,"(2a Via)",oFont10)
		EndIf

		///* SEGUNDA PARTE

		nRow2 :=  - 200

		//Pontilhado separador
		For nI := 100 to 2300 step 50
			_oPrint:Line(nRow2+0580, nI,nRow2+0580, nI+30)
		Next nI

		_oPrint:Line (nRow2+0710,100,nRow2+0710,2300)
		_oPrint:Line (nRow2+0710,500,nRow2+0630, 500)
		_oPrint:Line (nRow2+0710,710,nRow2+0630, 710)

		_oPrint:Say  (nRow2+0705,100,_aDadosBanco[2],oFont14 )		// [2]Nome do Banco
		If (_aDadosBanco[1]=="341") //341-Itau
			_oPrint:Say  (nRow2+0705,513,_aDadosBanco[1]+"-7",oFont21 )	// [1]Numero do Banco
		ElseIf (_aDadosBanco[1]=="237") //237-Bradesco
			_oPrint:Say  (nRow2+0705,513,_aDadosBanco[1]+"-2",oFont21 )	// [1]Numero do Banco
		EndIf
		_oPrint:Say  (nRow2+0705,1800,"Recibo do Pagador",oFont10)


		_oPrint:Line (nRow2+0810,100,nRow2+0810,2300 )
		_oPrint:Line (nRow2+0910,100,nRow2+0910,2300 )
		_oPrint:Line (nRow2+0980,100,nRow2+0980,2300 )
		_oPrint:Line (nRow2+1050,100,nRow2+1050,2300 )

		_oPrint:Line (nRow2+0910,500,nRow2+1050,500)
		_oPrint:Line (nRow2+0980,750,nRow2+1050,750)
		_oPrint:Line (nRow2+0910,1000,nRow2+1050,1000)
		_oPrint:Line (nRow2+0910,1300,nRow2+0980,1300)
		_oPrint:Line (nRow2+0910,1480,nRow2+1050,1480)

		_oPrint:Say  (nRow2+0730,100 ,"Local de Pagamento",oFont8)
		If (_aDadosBanco[1]=="341") //341-Itau
			_oPrint:Say  (nRow2+0765,0150 ,"Até o vencimento, preferencialmente no Itaú. Após o vencimento, somente no Itaú",oFont10)
		ElseIf (_aDadosBanco[1]=="237") //237-Bradesco
			_oPrint:Say  (nRow2+0765,0200 ,"PAGÁVEL PREFERENCIALMENTE NA REDE BRADESCO OU BRADESCO EXPRESSO",oFont10)
		EndIf

		_oPrint:Say  (nRow2+0730,1810,"Vencimento"                                     ,oFont8)
		cString	:= StrZero(Day(_aDadosTit[4]),2) +"/"+ StrZero(Month(_aDadosTit[4]),2) +"/"+ Right(Str(Year(_aDadosTit[4])),4)
		nCol := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow2+0765,nCol,cString,oFont11c)

		_oPrint:Say  (nRow2+0830,100 ,"Beneficiário"                                        ,oFont8)
		_oPrint:Say  (nRow2+0870,100 ,_aDadosEmp[1]+"     - "+_aDadosEmp[6]	,oFont10) //Nome + CNPJ
		_oPrint:Say  (nRow2+0900,100,AllTrim(_aDadosEmp[2])+" - "+AllTrim(_aDadosEmp[3]),oFont10) //endereço

		_oPrint:Say  (nRow2+0830,1810,"Agencia/Codigo Beneficiário",oFont8)
		cString := Alltrim(_aDadosBanco[3]+"/"+_aDadosBanco[4]+"-"+_aDadosBanco[5])
		nCol := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow2+0870,nCol,cString,oFont11c)

		_oPrint:Say  (nRow2+0930,100 ,"Data do Documento"                              ,oFont8)
		_oPrint:Say  (nRow2+0960,100, StrZero(Day(_aDadosTit[2]),2) +"/"+ StrZero(Month(_aDadosTit[2]),2) +"/"+ Right(Str(Year(_aDadosTit[2])),4),oFont10)

		_oPrint:Say  (nRow2+0930,505 ,"Nro.Documento"                                  ,oFont8)
//		_oPrint:Say  (nRow2+0960,605 ,_aDadosTit[7]+_aDadosTit[1]						,oFont10) //Prefixo +Numero+Parcela
		_oPrint:Say  (nRow2+0960,605 ,_cNrDoc						,oFont10) //Número do documento

		_oPrint:Say  (nRow2+0930,1005,"Especie Doc."                                   ,oFont8)
		_oPrint:Say  (nRow2+0960,1050,_aDadosTit[8]										,oFont10) //Tipo do Titulo

		_oPrint:Say  (nRow2+0930,1305,"Aceite"                                         ,oFont8)
		_oPrint:Say  (nRow2+0960,1400,"N"                                             ,oFont10)

		_oPrint:Say  (nRow2+0930,1485,"Data do Processamento"                          ,oFont8)
		_oPrint:Say  (nRow2+0960,1550,StrZero(Day(_aDadosTit[3]),2) +"/"+ StrZero(Month(_aDadosTit[3]),2) +"/"+ Right(Str(Year(_aDadosTit[3])),4),oFont10) // Data impressao

		_oPrint:Say  (nRow2+0930,1810,"Nosso Numero"                                   ,oFont8)
		If (_aDadosBanco[1]=="341") //341-Itau
			cString := Alltrim(Substr(_aDadosTit[6],1,3) + "/" + Substr(_aDadosTit[6],4))
		ElseIf (_aDadosBanco[1]=="237") //237-Bradesco
			//cString := _aDadosTit[6]
			cString := Left(_aDadosTit[6],2) + "/" + SubStr(_aDadosTit[6],3)
		EndIf
		nCol := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow2+0960,nCol,cString,oFont11c)

		_oPrint:Say  (nRow2+1000,100 ,"Uso do Banco"                                   ,oFont8)

		_oPrint:Say  (nRow2+1000,505 ,"Carteira"                                       ,oFont8)
		_oPrint:Say  (nRow2+1030,555 ,_aDadosBanco[6]                                  	,oFont10)

		_oPrint:Say  (nRow2+1000,755 ,"Especie"                                        ,oFont8)
		_oPrint:Say  (nRow2+1030,805 ,"R$"                                             ,oFont10)

		_oPrint:Say  (nRow2+1000,1005,"Quantidade"                                     ,oFont8)
		_oPrint:Say  (nRow2+1000,1485,"Valor"                                          ,oFont8)

		_oPrint:Say  (nRow2+1000,1810,"Valor do Documento"                          	,oFont8)
		cString := Alltrim(Transform(_aDadosTit[5],"@E 99,999,999.99"))
		nCol := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow2+1030,nCol,cString ,oFont11c)

		_oPrint:Say  (nRow2+1070,100 ,"Instruçoes (Todas informaçoes deste bloqueto são de exclusiva responsabilidade do beneficiário)",oFont8)

		// impressao dos dados da NFS-e
		If (!Empty(_cNumNFSe))
			_oPrint:Say  (nRow2+1150,100 ,"Ref. NFS-e: "+_cNumNFSe,oFont10)
		EndIf

		_oPrint:Say  (nRow2+1200,100 ,_aBolText[1]     ,oFont10)
		_oPrint:Say  (nRow2+1250,100 ,_aBolText[2]+" "+AllTrim(Transform(_aDadosTit[9],"@E 99,999.99"))  ,oFont10)
		_oPrint:Say  (nRow2+1300,100 ,_aBolText[3]                                        ,oFont10)
		_oPrint:Say  (nRow2+1350,100 ,_aBolText[4]                                        ,oFont10)

		_oPrint:Say  (nRow2+1070,1810,"(-)Desconto/Abatimento"                         ,oFont8)
		_oPrint:Say  (nRow2+1150,1810,"(-)Outras Deduçoes"                             ,oFont8)
		_oPrint:Say  (nRow2+1210,1810,"(+)Mora/Multa"                                  ,oFont8)
		_oPrint:Say  (nRow2+1280,1810,"(+)Outros Acrescimos"                           ,oFont8)
		_oPrint:Say  (nRow2+1350,1810,"(=)Valor Cobrado"                               ,oFont8)

		_oPrint:Say  (nRow2+1420,100 ,"Pagador"                                         ,oFont8)
		_oPrint:Say  (nRow2+1450,400 ,_aDatSacado[1]+" ("+_aDatSacado[2]+")"             ,oFont10)
		_oPrint:Say  (nRow2+1503,400 ,_aDatSacado[3]                                    ,oFont10)
		_oPrint:Say  (nRow2+1556,400 ,_aDatSacado[6]+"    "+_aDatSacado[4]+" - "+_aDatSacado[5],oFont10) // CEP+Cidade+Estado

		If _aDatSacado[8] = "J"
			_oPrint:Say  (nRow2+1609,400 ,"CNPJ: "+TRANSFORM(_aDatSacado[7],"@R 99.999.999/9999-99"),oFont10) // CGC
		Else
			_oPrint:Say  (nRow2+1609,400 ,"CPF: "+TRANSFORM(_aDatSacado[7],"@R 999.999.999-99"),oFont10) 	// CPF
		EndIf

		_oPrint:Say  (nRow2+1609,1850,Substr(_aDadosTit[6],1,3)+Substr(_aDadosTit[6],4)  ,oFont10)

		_oPrint:Say  (nRow2+1609,100 ,"Pagador/Avalista",oFont8)
		_oPrint:Say  (nRow2+1660,1500,"Autenticao Mecnica",oFont8)

		_oPrint:Line (nRow2+0710,1800,nRow2+1400,1800 )
		_oPrint:Line (nRow2+1120,1800,nRow2+1120,2300 )
		_oPrint:Line (nRow2+1190,1800,nRow2+1190,2300 )
		_oPrint:Line (nRow2+1260,1800,nRow2+1260,2300 )
		_oPrint:Line (nRow2+1330,1800,nRow2+1330,2300 )
		_oPrint:Line (nRow2+1400,100 ,nRow2+1400,2300 )
		_oPrint:Line (nRow2+1640,100 ,nRow2+1640,2300 )

		///* TERCEIRA PARTE

		nRow3 := -600

		For nI := 100 to 2300 step 50
			_oPrint:Line(nRow3+2270, nI, nRow3+2270, nI+30)
		Next nI

		_oPrint:Line (nRow3+2390,100,nRow3+2390,2300)
		_oPrint:Line (nRow3+2390,500,nRow3+2310, 500)
		_oPrint:Line (nRow3+2390,710,nRow3+2310, 710)

		_oPrint:Say  (nRow3+2380,100,_aDadosBanco[2],oFont14 )		// 	[2]Nome do Banco
		If (_aDadosBanco[1]=="341") //341-Itau
			_oPrint:Say  (nRow3+2380,513,_aDadosBanco[1]+"-7",oFont21 )	// 	[1]Numero do Banco
		ElseIf (_aDadosBanco[1]=="237") //237-Bradesco
			_oPrint:Say  (nRow3+2380,513,_aDadosBanco[1]+"-2",oFont21 )	// 	[1]Numero do Banco
		EndIf
		_oPrint:Say  (nRow3+2380,755,aCB_RN_NN[2],oFont15n)			//		Linha Digitavel do Codigo de Barras

		_oPrint:Line (nRow3+2490,100,nRow3+2490,2300 )
		_oPrint:Line (nRow3+2590,100,nRow3+2590,2300 )
		_oPrint:Line (nRow3+2660,100,nRow3+2660,2300 )
		_oPrint:Line (nRow3+2730,100,nRow3+2730,2300 )

		_oPrint:Line (nRow3+2590,500 ,nRow3+2730,500 )
		_oPrint:Line (nRow3+2660,750 ,nRow3+2730,750 )
		_oPrint:Line (nRow3+2590,1000,nRow3+2730,1000)
		_oPrint:Line (nRow3+2590,1300,nRow3+2660,1300)
		_oPrint:Line (nRow3+2590,1480,nRow3+2730,1480)

		_oPrint:Say  (nRow3+2410,100 ,"Local de Pagamento",oFont8)

		If (_aDadosBanco[1]=="341") //341-Itau
			_oPrint:Say  (nRow3+2455,0200 ,"PAGAVEL EM QUALQUER BANCO ATE O VENCIMENTO",oFont10)
		ElseIf (_aDadosBanco[1]=="237") //237-Bradesco
			_oPrint:Say  (nRow3+2455,0200 ,"PAGÁVEL PREFERENCIALMENTE NA REDE BRADESCO OU BRADESCO EXPRESSO",oFont10)
		EndIf

		_oPrint:Say  (nRow3+2410,1810,"Vencimento",oFont8)
		cString := StrZero(Day(_aDadosTit[4]),2) +"/"+ StrZero(Month(_aDadosTit[4]),2) +"/"+ Right(Str(Year(_aDadosTit[4])),4)
		nCol	 	 := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow3+2455,nCol,cString,oFont11c)

		_oPrint:Say  (nRow3+2510,100 ,"Beneficiário",oFont8)
		_oPrint:Say  (nRow3+2550,100 ,_aDadosEmp[1]+"                  - "+_aDadosEmp[6]	,oFont10) //Nome + CNPJ
		_oPrint:Say  (nRow3+2580,100,AllTrim(_aDadosEmp[2])+" - "+AllTrim(_aDadosEmp[3]),oFont10) //endereço

		_oPrint:Say  (nRow3+2510,1810,"Agencia/Codigo Beneficiário",oFont8)
		cString := Alltrim(_aDadosBanco[3]+"/"+_aDadosBanco[4]+"-"+_aDadosBanco[5])
		nCol 	 := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow3+2560,nCol,cString ,oFont11c)


		_oPrint:Say  (nRow3+2610,100 ,"Data do Documento"                              ,oFont8)
		_oPrint:Say (nRow3+2640,100, StrZero(Day(_aDadosTit[2]),2) +"/"+ StrZero(Month(_aDadosTit[2]),2) +"/"+ Right(Str(Year(_aDadosTit[2])),4), oFont10)


		_oPrint:Say  (nRow3+2610,505 ,"Nro.Documento"                                  ,oFont8)
//		_oPrint:Say  (nRow3+2640,605 ,_aDadosTit[7]+_aDadosTit[1]						,oFont10) //Prefixo +Numero+Parcela
		_oPrint:Say  (nRow3+2640,605 ,_cNrDoc						,oFont10)  //Número documento

		_oPrint:Say  (nRow3+2610,1005,"Especie Doc."                                   ,oFont8)
		_oPrint:Say  (nRow3+2640,1050,_aDadosTit[8]										,oFont10) //Tipo do Titulo

		_oPrint:Say  (nRow3+2610,1305,"Aceite"                                         ,oFont8)
		_oPrint:Say  (nRow3+2640,1400,"N"                                             ,oFont10)

		_oPrint:Say  (nRow3+2610,1485,"Data do Processamento"                          ,oFont8)
		_oPrint:Say  (nRow3+2640,1550,StrZero(Day(_aDadosTit[3]),2) +"/"+ StrZero(Month(_aDadosTit[3]),2) +"/"+ Right(Str(Year(_aDadosTit[3])),4)                               ,oFont10) // Data impressao


		_oPrint:Say  (nRow3+2610,1810,"Nosso Numero"                                   ,oFont8)

		If (_aDadosBanco[1]=="341") //341-Itau
			cString := Alltrim(Substr(_aDadosTit[6],1,3)+"/"+Substr(_aDadosTit[6],4))
		ElseIf (_aDadosBanco[1]=="237") //237-Bradesco
			cString := Left(_aDadosTit[6],2)+"/"+SubStr(_aDadosTit[6],3)
		EndIf

		nCol 	 := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow3+2640,nCol,cString,oFont11c)

		_oPrint:Say  (nRow3+2680,100 ,"Uso do Banco"                                   ,oFont8)

		_oPrint:Say  (nRow3+2680,505 ,"Carteira"                                       ,oFont8)
		_oPrint:Say  (nRow3+2710,555 ,_aDadosBanco[6]                                  	,oFont10)

		_oPrint:Say  (nRow3+2680,755 ,"Especie"                                        ,oFont8)
		_oPrint:Say  (nRow3+2710,805 ,"R$"                                             ,oFont10)

		_oPrint:Say  (nRow3+2680,1005,"Quantidade"                                     ,oFont8)
		_oPrint:Say  (nRow3+2680,1485,"Valor"                                          ,oFont8)

		_oPrint:Say  (nRow3+2680,1810,"Valor do Documento"                          	,oFont8)
		cString := Alltrim(Transform(_aDadosTit[5],"@E 99,999,999.99"))
		nCol 	 := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow3+2710,nCol,cString,oFont11c)

		_oPrint:Say  (nRow3+2750,100 ,"Instruçoes (Todas informaçoes deste bloqueto são de exclusiva responsabilidade do beneficiário)",oFont8)

		// impressao dos dados da NFS-e
		If (!Empty(_cNumNFSe))
			_oPrint:Say  (nRow3+2800,100 ,"Ref. NFS-e: "+_cNumNFSe ,oFont10)
		EndIf

		_oPrint:Say  (nRow3+2850,100 ,_aBolText[1]      ,oFont10)
		_oPrint:Say  (nRow3+2900,100 ,_aBolText[2]+" "+AllTrim(Transform(_aDadosTit[9],"@E 99,999.99"))  ,oFont10)
		_oPrint:Say  (nRow3+2950,100 ,_aBolText[3]                                        ,oFont10)
		_oPrint:Say  (nRow3+3000,100 ,_aBolText[4]                                        ,oFont10)

		_oPrint:Say  (nRow3+2750,1810,"(-)Desconto/Abatimento"                         ,oFont8)
		_oPrint:Say  (nRow3+2820,1810,"(-)Outras Deduçoes"                             ,oFont8)
		_oPrint:Say  (nRow3+2890,1810,"(+)Mora/Multa"                                  ,oFont8)
		_oPrint:Say  (nRow3+2960,1810,"(+)Outros Acrescimos"                           ,oFont8)
		_oPrint:Say  (nRow3+3030,1810,"(=)Valor Cobrado"                               ,oFont8)

		_oPrint:Say  (nRow3+3100,100 ,"Pagador"                                         ,oFont8)
		_oPrint:Say  (nRow3+3110,400 ,_aDatSacado[1]+" ("+_aDatSacado[2]+")"             ,oFont10)

		if _aDatSacado[8] = "J"
			_oPrint:Say  (nRow3+3110,1750,"CNPJ: "+TRANSFORM(_aDatSacado[7],"@R 99.999.999/9999-99"),oFont10) // CGC
		Else
			_oPrint:Say  (nRow3+3110,1750,"CPF: "+TRANSFORM(_aDatSacado[7],"@R 999.999.999-99"),oFont10) 	// CPF
		EndIf

		_oPrint:Say  (nRow3+3150,400 ,_aDatSacado[3]                                    ,oFont10)
		_oPrint:Say  (nRow3+3200,400 ,_aDatSacado[6]+"    "+_aDatSacado[4]+" - "+_aDatSacado[5],oFont10) // CEP+Cidade+Estado
		_oPrint:Say  (nRow3+3200,1750,Substr(_aDadosTit[6],1,3)+Substr(_aDadosTit[6],4)  ,oFont10)

		_oPrint:Say  (nRow3+3200,100 ,"Pagador/Avalista"                               ,oFont8)
		_oPrint:Say  (nRow3+3260,1530,"Autenticao Mecanica - Ficha de Compensacao"      ,oFont8)

		_oPrint:Line (nRow3+2390,1800,nRow3+3080,1800 )
		_oPrint:Line (nRow3+2800,1800,nRow3+2800,2300 )
		_oPrint:Line (nRow3+2870,1800,nRow3+2870,2300 )
		_oPrint:Line (nRow3+2940,1800,nRow3+2940,2300 )
		_oPrint:Line (nRow3+3010,1800,nRow3+3010,2300 )
		_oPrint:Line (nRow3+3080,100 ,nRow3+3080,2300 )

		_oPrint:Line (nRow3+3240,100,nRow3+3240,2300  )

		_oPrint:fwmsbar("INT25", 64.5 , 1.0 , aCB_RN_NN[1] ,_oPrint,.F.,Nil,Nil, 0.0292 , 1.5 ,Nil,Nil,"A",.F.,,3)

		//Escolhido o componente TMSPrinter impressão em tela.
	Else

		nRow1 := 0
		_oPrint:SayBitmap(0100,100,_cImagem,744.8,239.4)

		_oPrint:Say  (nRow1+0150,1060,AllTrim(_aDadosEmp[1]),oFont15)
		_oPrint:Say  (nRow1+0250,1060,AllTrim(_aDadosEmp[2])+" - "+AllTrim(_aDadosEmp[3]),oFont10)
		_oPrint:Say  (nRow1+0350,1060,AllTrim(_aDadosEmp[4])+" / "+AllTrim(_aDadosEmp[5]),oFont10)

		// segunda via
		If (!_lNewBoleto)
			_oPrint:Say (nRow1+0150,2100,"(2a Via)",oFont10)
		EndIf

		///* SEGUNDA PARTE

		nRow2 := 300

		//Pontilhado separador
		For nI := 100 to 2300 step 50
			_oPrint:Line(nRow2+0580, nI,nRow2+0580, nI+30)
		Next nI

		_oPrint:Line (nRow2+0710,100,nRow2+0710,2300)
		_oPrint:Line (nRow2+0710,500,nRow2+0630, 500)
		_oPrint:Line (nRow2+0710,710,nRow2+0630, 710)

		_oPrint:Say  (nRow2+0644,100,_aDadosBanco[2],oFont14 )		// [2]Nome do Banco
		If (_aDadosBanco[1]=="341") //341-Itau
			_oPrint:Say  (nRow2+0635,513,_aDadosBanco[1]+"-7",oFont21 )	// [1]Numero do Banco
		ElseIf (_aDadosBanco[1]=="237") //237-Bradesco
			_oPrint:Say  (nRow2+0635,513,_aDadosBanco[1]+"-2",oFont21 )	// [1]Numero do Banco
		EndIf
		_oPrint:Say  (nRow2+0644,1800,"Recibo do Pagador",oFont10)

		_oPrint:Line (nRow2+0810,100,nRow2+0810,2300 )
		_oPrint:Line (nRow2+0910,100,nRow2+0910,2300 )
		_oPrint:Line (nRow2+0980,100,nRow2+0980,2300 )
		_oPrint:Line (nRow2+1050,100,nRow2+1050,2300 )

		_oPrint:Line (nRow2+0910,500,nRow2+1050,500)
		_oPrint:Line (nRow2+0980,750,nRow2+1050,750)
		_oPrint:Line (nRow2+0910,1000,nRow2+1050,1000)
		_oPrint:Line (nRow2+0910,1300,nRow2+0980,1300)
		_oPrint:Line (nRow2+0910,1480,nRow2+1050,1480)

		_oPrint:Say  (nRow2+0710,100 ,"Local de Pagamento",oFont8)
		If (_aDadosBanco[1]=="341") //341-Itau
			_oPrint:Say  (nRow2+0765,0200 ,"PAGAVEL EM QUALQUER BANCO ATE O VENCIMENTO",oFont10)
		ElseIf (_aDadosBanco[1]=="237") //237-Bradesco
			_oPrint:Say  (nRow2+0765,0200 ,"PAGÁVEL PREFERENCIALMENTE NA REDE BRADESCO OU BRADESCO EXPRESSO",oFont10)
		EndIf

		_oPrint:Say  (nRow2+0710,1810,"Vencimento"                                     ,oFont8)
		cString	:= StrZero(Day(_aDadosTit[4]),2) +"/"+ StrZero(Month(_aDadosTit[4]),2) +"/"+ Right(Str(Year(_aDadosTit[4])),4)
		nCol := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow2+0750,nCol,cString,oFont11c)

		_oPrint:Say  (nRow2+0810,100 ,"Beneficiário"                                        ,oFont8)
		_oPrint:Say  (nRow2+0850,100 ,_aDadosEmp[1]+"                  - "+_aDadosEmp[6]	,oFont10) //Nome + CNPJ
		_oPrint:Say  (nRow2+0890,100,AllTrim(_aDadosEmp[2])+" - "+AllTrim(_aDadosEmp[3]),oFont10) //endereço

		_oPrint:Say  (nRow2+0810,1810,"Agencia/Codigo Beneficiário",oFont8)
		cString := Alltrim(_aDadosBanco[3]+"/"+_aDadosBanco[4]+"-"+_aDadosBanco[5])
		nCol := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow2+0850,nCol,cString,oFont11c)

		_oPrint:Say  (nRow2+0910,100 ,"Data do Documento"                              ,oFont8)
		_oPrint:Say  (nRow2+0940,100, StrZero(Day(_aDadosTit[2]),2) +"/"+ StrZero(Month(_aDadosTit[2]),2) +"/"+ Right(Str(Year(_aDadosTit[2])),4),oFont10)

		_oPrint:Say  (nRow2+0910,505 ,"Nro.Documento"                                  ,oFont8)
//		_oPrint:Say  (nRow2+0940,605 ,_aDadosTit[7]+_aDadosTit[1]						,oFont10) //Prefixo +Numero+Parcela
		_oPrint:Say  (nRow2+0940,605 ,_cNrDoc						,oFont10) 			//Numero do documento

		_oPrint:Say  (nRow2+0910,1005,"Especie Doc."                                   ,oFont8)
		_oPrint:Say  (nRow2+0940,1050,_aDadosTit[8]										,oFont10) //Tipo do Titulo

		_oPrint:Say  (nRow2+0910,1305,"Aceite"                                         ,oFont8)
		_oPrint:Say  (nRow2+0940,1400,"N"                                             ,oFont10)

		_oPrint:Say  (nRow2+0910,1485,"Data do Processamento"                          ,oFont8)
		_oPrint:Say  (nRow2+0940,1550,StrZero(Day(_aDadosTit[3]),2) +"/"+ StrZero(Month(_aDadosTit[3]),2) +"/"+ Right(Str(Year(_aDadosTit[3])),4),oFont10) // Data impressao

		_oPrint:Say  (nRow2+0910,1810,"Nosso Numero"                                   ,oFont8)
		If (_aDadosBanco[1]=="341") //341-Itau
			cString := Alltrim(Substr(_aDadosTit[6],1,3)+"/"+Substr(_aDadosTit[6],4))
		ElseIf (_aDadosBanco[1]=="237") //237-Bradesco
			//cString := _aDadosTit[6]
			cString := Left(_aDadosTit[6],2)+"/"+SubStr(_aDadosTit[6],3)
		EndIf
		nCol := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow2+0940,nCol,cString,oFont11c)

		_oPrint:Say  (nRow2+0980,100 ,"Uso do Banco"                                   ,oFont8)

		_oPrint:Say  (nRow2+0980,505 ,"Carteira"                                       ,oFont8)
		_oPrint:Say  (nRow2+1010,555 ,_aDadosBanco[6]                                  	,oFont10)

		_oPrint:Say  (nRow2+0980,755 ,"Especie"                                        ,oFont8)
		_oPrint:Say  (nRow2+1010,805 ,"R$"                                             ,oFont10)

		_oPrint:Say  (nRow2+0980,1005,"Quantidade"                                     ,oFont8)
		_oPrint:Say  (nRow2+0980,1485,"Valor"                                          ,oFont8)

		_oPrint:Say  (nRow2+0980,1810,"Valor do Documento"                          	,oFont8)
		cString := Alltrim(Transform(_aDadosTit[5],"@E 99,999,999.99"))
		nCol := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow2+1010,nCol,cString ,oFont11c)

		_oPrint:Say  (nRow2+1050,100 ,"Instruçoes (Todas informaçoes deste bloqueto são de exclusiva responsabilidade do Beneficiário)",oFont8)

		// impressao dos dados da NFS-e
		If (!Empty(_cNumNFSe))
			_oPrint:Say  (nRow2+1100,100 ,"Ref. NFS-e: "+_cNumNFSe,oFont10)
		EndIf

		_oPrint:Say  (nRow2+1150,100 ,_aBolText[1]     ,oFont10)
		_oPrint:Say  (nRow2+1200,100 ,_aBolText[2]+" "+AllTrim(Transform(_aDadosTit[9],"@E 99,999.99"))  ,oFont10)
		_oPrint:Say  (nRow2+1250,100 ,_aBolText[3]                                        ,oFont10)
		_oPrint:Say  (nRow2+1300,100 ,_aBolText[4]                                        ,oFont10)

		_oPrint:Say  (nRow2+1050,1810,"(-)Desconto/Abatimento"                         ,oFont8)
		_oPrint:Say  (nRow2+1120,1810,"(-)Outras Deduçoes"                             ,oFont8)
		_oPrint:Say  (nRow2+1190,1810,"(+)Mora/Multa"                                  ,oFont8)
		_oPrint:Say  (nRow2+1260,1810,"(+)Outros Acrescimos"                           ,oFont8)
		_oPrint:Say  (nRow2+1330,1810,"(=)Valor Cobrado"                               ,oFont8)

		_oPrint:Say  (nRow2+1400,100 ,"Pagador"                                         ,oFont8)
		_oPrint:Say  (nRow2+1430,400 ,_aDatSacado[1]+" ("+_aDatSacado[2]+")"             ,oFont10)
		_oPrint:Say  (nRow2+1483,400 ,_aDatSacado[3]                                    ,oFont10)
		_oPrint:Say  (nRow2+1536,400 ,_aDatSacado[6]+"    "+_aDatSacado[4]+" - "+_aDatSacado[5],oFont10) // CEP+Cidade+Estado

		if _aDatSacado[8] = "J"
			_oPrint:Say  (nRow2+1589,400 ,"CNPJ: "+TRANSFORM(_aDatSacado[7],"@R 99.999.999/9999-99"),oFont10) // CGC
		Else
			_oPrint:Say  (nRow2+1589,400 ,"CPF: "+TRANSFORM(_aDatSacado[7],"@R 999.999.999-99"),oFont10) 	// CPF
		EndIf

		_oPrint:Say  (nRow2+1589,1850,Substr(_aDadosTit[6],1,3)+Substr(_aDadosTit[6],4)  ,oFont10)

		_oPrint:Say  (nRow2+1605,100 ,"Pagador/Avalista",oFont8)
		_oPrint:Say  (nRow2+1645,1500,"Autenticao Mecnica",oFont8)

		_oPrint:Line (nRow2+0710,1800,nRow2+1400,1800 )
		_oPrint:Line (nRow2+1120,1800,nRow2+1120,2300 )
		_oPrint:Line (nRow2+1190,1800,nRow2+1190,2300 )
		_oPrint:Line (nRow2+1260,1800,nRow2+1260,2300 )
		_oPrint:Line (nRow2+1330,1800,nRow2+1330,2300 )
		_oPrint:Line (nRow2+1400,100 ,nRow2+1400,2300 )
		_oPrint:Line (nRow2+1640,100 ,nRow2+1640,2300 )

		///* TERCEIRA PARTE

		nRow3 := -200

		For nI := 100 to 2300 step 50
			_oPrint:Line(nRow3+2270, nI, nRow3+2270, nI+30)
		Next nI
		////

		_oPrint:Line (nRow3+2390,100,nRow3+2390,2300)
		_oPrint:Line (nRow3+2390,500,nRow3+2310, 500)
		_oPrint:Line (nRow3+2390,710,nRow3+2310, 710)

		_oPrint:Say  (nRow3+2324,100,_aDadosBanco[2],oFont14 )		// 	[2]Nome do Banco
		If (_aDadosBanco[1]=="341") //341-Itau
			_oPrint:Say  (nRow3+2315,513,_aDadosBanco[1]+"-7",oFont21 )	// 	[1]Numero do Banco
		ElseIf (_aDadosBanco[1]=="237") //237-Bradesco
			_oPrint:Say  (nRow3+2315,513,_aDadosBanco[1]+"-2",oFont21 )	// 	[1]Numero do Banco
		EndIf
		_oPrint:Say  (nRow3+2324,755,aCB_RN_NN[2],oFont15n)			//		Linha Digitavel do Codigo de Barras

		_oPrint:Line (nRow3+2490,100,nRow3+2490,2300 )
		_oPrint:Line (nRow3+2590,100,nRow3+2590,2300 )
		_oPrint:Line (nRow3+2660,100,nRow3+2660,2300 )
		_oPrint:Line (nRow3+2730,100,nRow3+2730,2300 )

		_oPrint:Line (nRow3+2590,500 ,nRow3+2730,500 )
		_oPrint:Line (nRow3+2660,750 ,nRow3+2730,750 )
		_oPrint:Line (nRow3+2590,1000,nRow3+2730,1000)
		_oPrint:Line (nRow3+2590,1300,nRow3+2660,1300)
		_oPrint:Line (nRow3+2590,1480,nRow3+2730,1480)

		_oPrint:Say  (nRow3+2390,100 ,"Local de Pagamento",oFont8)

		If (_aDadosBanco[1]=="341") //341-Itau
			_oPrint:Say  (nRow3+2445,0200 ,"PAGAVEL EM QUALQUER BANCO ATE O VENCIMENTO",oFont10)
		ElseIf (_aDadosBanco[1]=="237") //237-Bradesco
			_oPrint:Say  (nRow3+2445,0200 ,"PAGÁVEL PREFERENCIALMENTE NA REDE BRADESCO OU BRADESCO EXPRESSO",oFont10)
		EndIf

		_oPrint:Say  (nRow3+2390,1810,"Vencimento",oFont8)
		cString := StrZero(Day(_aDadosTit[4]),2) +"/"+ StrZero(Month(_aDadosTit[4]),2) +"/"+ Right(Str(Year(_aDadosTit[4])),4)
		nCol	 	 := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow3+2430,nCol,cString,oFont11c)

		_oPrint:Say  (nRow3+2490,100 ,"Beneficiário",oFont8)
		_oPrint:Say  (nRow3+2530,100 ,_aDadosEmp[1]+"                  - "+_aDadosEmp[6]	,oFont10) //Nome + CNPJ
		_oPrint:Say  (nRow3+2560,100,AllTrim(_aDadosEmp[2])+" - "+AllTrim(_aDadosEmp[3]),oFont10) //endereço

		_oPrint:Say  (nRow3+2490,1810,"Agencia/Codigo Beneficiário",oFont8)
		cString := Alltrim(_aDadosBanco[3]+"/"+_aDadosBanco[4]+"-"+_aDadosBanco[5])
		nCol 	 := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow3+2530,nCol,cString ,oFont11c)


		_oPrint:Say  (nRow3+2590,100 ,"Data do Documento"                              ,oFont8)
		_oPrint:Say (nRow3+2620,100, StrZero(Day(_aDadosTit[2]),2) +"/"+ StrZero(Month(_aDadosTit[2]),2) +"/"+ Right(Str(Year(_aDadosTit[2])),4), oFont10)


		_oPrint:Say  (nRow3+2590,505 ,"Nro.Documento"                                  ,oFont8)
//		_oPrint:Say  (nRow3+2620,605 ,_aDadosTit[7]+_aDadosTit[1]						,oFont10) //Prefixo +Numero+Parcela
		_oPrint:Say  (nRow3+2620,605 ,_cNrDoc						,oFont10) 			//Número do documento

		_oPrint:Say  (nRow3+2590,1005,"Especie Doc."                                   ,oFont8)
		_oPrint:Say  (nRow3+2620,1050,_aDadosTit[8]										,oFont10) //Tipo do Titulo

		_oPrint:Say  (nRow3+2590,1305,"Aceite"                                         ,oFont8)
		_oPrint:Say  (nRow3+2620,1400,"N"                                             ,oFont10)

		_oPrint:Say  (nRow3+2590,1485,"Data do Processamento"                          ,oFont8)
		_oPrint:Say  (nRow3+2620,1550,StrZero(Day(_aDadosTit[3]),2) +"/"+ StrZero(Month(_aDadosTit[3]),2) +"/"+ Right(Str(Year(_aDadosTit[3])),4)                               ,oFont10) // Data impressao


		_oPrint:Say  (nRow3+2590,1810,"Nosso Numero"                                   ,oFont8)
		If (_aDadosBanco[1]=="341") //341-Itau
			cString := Alltrim(Substr(_aDadosTit[6],1,3)+"/"+Substr(_aDadosTit[6],4))
		ElseIf (_aDadosBanco[1]=="237") //237-Bradesco
			//cString := _aDadosTit[6]
			cString := Left(_aDadosTit[6],2)+"/"+SubStr(_aDadosTit[6],3)
		EndIf
		nCol 	 := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow3+2620,nCol,cString,oFont11c)


		_oPrint:Say  (nRow3+2660,100 ,"Uso do Banco"                                   ,oFont8)

		_oPrint:Say  (nRow3+2660,505 ,"Carteira"                                       ,oFont8)
		_oPrint:Say  (nRow3+2690,555 ,_aDadosBanco[6]                                  	,oFont10)

		_oPrint:Say  (nRow3+2660,755 ,"Especie"                                        ,oFont8)
		_oPrint:Say  (nRow3+2690,805 ,"R$"                                             ,oFont10)

		_oPrint:Say  (nRow3+2660,1005,"Quantidade"                                     ,oFont8)
		_oPrint:Say  (nRow3+2660,1485,"Valor"                                          ,oFont8)

		_oPrint:Say  (nRow3+2660,1810,"Valor do Documento"                          	,oFont8)
		cString := Alltrim(Transform(_aDadosTit[5],"@E 99,999,999.99"))
		nCol 	 := 1810+(374-(len(cString)*22))
		_oPrint:Say  (nRow3+2690,nCol,cString,oFont11c)

		_oPrint:Say  (nRow3+2730,100 ,"Instruçoes (Todas informaçoes deste bloqueto são de exclusiva responsabilidade do beneficiário)",oFont8)

		// impressao dos dados da NFS-e
		If (!Empty(_cNumNFSe))
			_oPrint:Say  (nRow3+2780,100 ,"Ref. NFS-e: "+_cNumNFSe ,oFont10)
		EndIf

		_oPrint:Say  (nRow3+2830,100 ,_aBolText[1]      ,oFont10)
		_oPrint:Say  (nRow3+2880,100 ,_aBolText[2]+" "+AllTrim(Transform(_aDadosTit[9],"@E 99,999.99"))  ,oFont10)
		_oPrint:Say  (nRow3+2930,100 ,_aBolText[3]                                        ,oFont10)
		_oPrint:Say  (nRow3+2980,100 ,_aBolText[4]                                        ,oFont10)

		_oPrint:Say  (nRow3+2730,1810,"(-)Desconto/Abatimento"                         ,oFont8)
		_oPrint:Say  (nRow3+2800,1810,"(-)Outras Deduçoes"                             ,oFont8)
		_oPrint:Say  (nRow3+2870,1810,"(+)Mora/Multa"                                  ,oFont8)
		_oPrint:Say  (nRow3+2940,1810,"(+)Outros Acrescimos"                           ,oFont8)
		_oPrint:Say  (nRow3+3010,1810,"(=)Valor Cobrado"                               ,oFont8)

		_oPrint:Say  (nRow3+3080,100 ,"Pagador"                                         ,oFont8)
		_oPrint:Say  (nRow3+3090,400 ,_aDatSacado[1]+" ("+_aDatSacado[2]+")"             ,oFont10)

		if _aDatSacado[8] = "J"
			_oPrint:Say  (nRow3+3090,1750,"CNPJ: "+TRANSFORM(_aDatSacado[7],"@R 99.999.999/9999-99"),oFont10) // CGC
		Else
			_oPrint:Say  (nRow3+3090,1750,"CPF: "+TRANSFORM(_aDatSacado[7],"@R 999.999.999-99"),oFont10) 	// CPF
		EndIf

		_oPrint:Say  (nRow3+3143,400 ,_aDatSacado[3]                                    ,oFont10)
		_oPrint:Say  (nRow3+3196,400 ,_aDatSacado[6]+"    "+_aDatSacado[4]+" - "+_aDatSacado[5],oFont10) // CEP+Cidade+Estado
		_oPrint:Say  (nRow3+3196,1750,Substr(_aDadosTit[6],1,3)+Substr(_aDadosTit[6],4)  ,oFont10)

		_oPrint:Say  (nRow3+3205,100 ,"Pagador/Avalista"                               ,oFont8)
		_oPrint:Say  (nRow3+3245,1530,"Autenticao Mecnica - Ficha de Compensao"                        ,oFont8)

		_oPrint:Line (nRow3+2390,1800,nRow3+3080,1800 )
		_oPrint:Line (nRow3+2800,1800,nRow3+2800,2300 )
		_oPrint:Line (nRow3+2870,1800,nRow3+2870,2300 )
		_oPrint:Line (nRow3+2940,1800,nRow3+2940,2300 )
		_oPrint:Line (nRow3+3010,1800,nRow3+3010,2300 )
		_oPrint:Line (nRow3+3080,100 ,nRow3+3080,2300 )

		_oPrint:Line (nRow3+3240,100,nRow3+3240,2300  )
		MSBAR("INT25",26.5,1.0,aCB_RN_NN[1],_oPrint,.F.,Nil,Nil,0.0292,1.5,Nil,Nil,"A",.F.)
	EndIf

	_oPrint:EndPage() // Finaliza a pgina

Return Nil

/*/
Programa   Modulo10  Autor  Microsiga              Data  13/10/03
Descrio  IMPRESSAO DO BOLETO LASE DO ITAU COM CODIGO DE BARRAS
Uso        Especifico para Clientes Microsiga
/*/
Static Function Modulo10(cData)
	LOCAL L,D,P := 0
	LOCAL B     := .F.
	L := Len(cData)
	B := .T.
	D := 0
	While L > 0
		P := Val(SubStr(cData, L, 1))
		If (B)
			P := P * 2
			If P > 9
				P := P - 9
			End
		End
		D := D + P
		L := L - 1
		B := !B
	End
	D := 10 - (Mod(D,10))
	If D = 10
		D := 0
	End
Return(D)

/*/
Programa   Modulo11  Autor  Microsiga              Data  13/10/03
Descrio  IMPRESSAO DO BOLETO LASER DO ITAU COM CODIGO DE BARRAS
Uso        Especifico para Clientes Microsiga
/*/
Static Function Modulo11(cData)
	LOCAL L, D, P := 0
	L := Len(cdata)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		End
		L := L - 1
	End
	D := 11 - (mod(D,11))
	If (D == 0 .Or. D == 1 .Or. D == 10 .Or. D == 11)
		D := 1
	End
Return(D)

/*/
Programa  Ret_cBarra Autor  Microsiga              Data  13/10/03
Descrio  IMPRESSAO DO BOLETO LASE DO ITAU COM CODIGO DE BARRAS
Uso        Especifico para Clientes Microsiga
/*/
Static Function Ret_cBarra(cBanco,cAgencia,cConta,cDacCC,_cNroDoc,nValor,dVencto)

	LOCAL cValorFinal := strzero((nValor*100),10)
	LOCAL nDvnn			:= 0
	LOCAL nDvcb			:= 0
	LOCAL nDv			:= 0
	LOCAL cNN			:= ''
	LOCAL cRN			:= ''
	LOCAL cCB			:= ''
	LOCAL cS				:= ''
	LOCAL cFator      := strzero(dVencto - ctod("07/10/97"),4)

	// variaveis para o banco 237-Bradesco
	Local cCampoLivre
	Local _cCampo1, _cCampo2, _cCampo3, _cCampo4, _cCampo5

	// definicao do digito verificador do nosso numero
	If (cBanco=="341") // 341-Itau
		cConta	:= Alltrim(cConta)
		cS		:= cAgencia + cConta + cCart + _cNroDoc

		nDvnn	:= modulo10(cS) // digito verifacador Agencia + Conta + Carteira + Nosso Num
		cNN		:= cCart + _cNroDoc + '-' + AllTrim(Str(nDvnn))

	ElseIf (cBanco=="237") // 237-Bradesco
		nDvnn	:= sfCalcDV_NN(cCart,_cNroDoc)
		cNN		:= cCart + _cNroDoc + '-' + nDvnn
	EndIf

	// se for novo boleto
	If (_lNewBoleto)
		DbSelectArea("SE1")
		RecLock("SE1",.f.)
		SE1->E1_NUMBCO 	:= cNN
		SE1->E1_PORTADO	:= sBcoBco
		SE1->E1_AGEDEP	:= sBcoAge
		SE1->E1_CONTA	:= sBcoCon
		MsUnlock()

		cNumBor	:= ""
		DbSelectAreA("SEA")
		DBOrderNickName("SEA_A")
		//				DbSetOrdeR(3) //indice personalizado - EA_FILIAL+EA_PORTADO+EA_AGEDEP+EA_NUMCON+EA_CART+EA_DATABOR
		if DbSeek(xFilial("SEA")+sBcoBco+sBcoAge+sBcoCon+"R"+dtos(ddatabase))
			If SEA->EA_TRANSF<>"S"
				cNumBor	:= SEA->EA_NUMBOR
			EndIf
		endif

		If Empty(cNumBor)
			cNumBor := Soma1(GetMV("MV_NUMBORR"),6)
			cNumBor := Replicate("0",6-Len(Alltrim(cNumBor)))+Alltrim(cNumBor)
			SETMV("MV_NUMBORR",cNumBor)
		EndIf


		RecLock("SE1",.F.)
		Replace SE1->E1_NUMBOR	with cNumBor
		Replace SE1->E1_DATABOR	with ddatabase
		MsUnLock()

		IF SE1->E1_SITUACA=="0"
			RecLock("SE1",.F.)
			Replace SE1->E1_SITUACA with "1"
			MsUnLock()
		ENDIF

		IF EMPTY(SE1->E1_OCORREN)
			RecLock("SE1",.F.)
			Replace SE1->E1_OCORREN	with "01"
			MsUnLock()
		ENDIF

		// Inclui registro na tabela SEA (Titulos enviados a bancos)
		dbSelectArea("SEA")
		dbSetOrder(1) // EA_FILIAL+EA_NUMBOR+EA_PREFIXO+EA_NUM+EA_PARCELA+EA_TIPO+EA_FORNECE+EA_LOJA
		dbSeek(XFILIAL("SEA")+cNumBor+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO)
		IF !FOUND()
			RecLock("SEA",.T.)
			Replace SEA->EA_FILIAL	with XFILIAL("SEA")
			Replace SEA->EA_PREFIXO	with SE1->E1_PREFIXO
			Replace SEA->EA_NUM		with SE1->E1_NUM
			Replace SEA->EA_PARCELA	with SE1->E1_PARCELA
			Replace SEA->EA_PORTADO	with cBanco
			Replace SEA->EA_AGEDEP	with sBcoAge
			Replace SEA->EA_NUMBOR	with cNumBor
			Replace SEA->EA_DATABOR	with dDataBase
			Replace SEA->EA_TIPO	with SE1->E1_TIPO
			Replace SEA->EA_CART	with "R"
			Replace SEA->EA_NUMCON	with sBcoCon
			Replace SEA->EA_SITUACA	with "1"
			Replace SEA->EA_SITUANT	with "0"
			MsUnLock()
		ENDIF
	EndIf

	//----------------------------------
	//	 Definicao do CODIGO DE BARRAS
	//----------------------------------
	If (cBanco=="341") // 341-Itau
		cS		:= cBanco +"9"+ cFator +  cValorFinal + Subs(cNN,1,11) + Subs(cNN,13,1) + cAgencia + cConta + cDacCC + '000'
		nDvcb	:= modulo11(cS)
		cCB		:= SubStr(cS, 1, 4) + AllTrim(Str(nDvcb)) + SubStr(cS,5,26) + SubStr(cS,31)
		nDvnn	:= Val(SubS(cS,30, 1))
	ElseIf (cBanco=="237") // 237-Bradesco
		// montagem do Codntudo do Campo Livre (Utilizado no Codigo de Barras)
		cCampoLivre	:= Left(sBcoAge,4)			//Agencia do Beneficiário
		cCampoLivre	+= cCart					//Carteira
		cCampoLivre	+= _cNroDoc					//Nosso Numero (sem carteira e sem DV)
		// 30.09 - Toni - Troca de Codigo do Beneficiário por Numero da conta (sem DV)
		cCampoLivre	+= SubStr(sBcoCon,3,7)		// numero da conta (sem DV) - 	// cCampoLivre	+= Left(SEE->EE_CODEMP,7)	//Codigo do Cendente sem DV
		cCampoLivre	+= "0"						//Zero

		cCB	:= cBanco		//Codigo do Banco
		cCB	+= "9"			//Moeda (9-Real)
		cCB	+= cFator		//Fator de Vencimento
		cCB	+= cValorFinal	//Valor do Titulo
		cCB	+= cCampoLivre	//Campo Livre

		// geracao do digito verificado do codigo de barras
		cCB := sfDVCodBarras(cCB)
	EndIf

	//-------- Definicao da LINHA DIGITAVEL (Representacao Numerica)
	//	Campo 1			Campo 2			Campo 3			Campo 4		Campo 5
	//	AAABC.CCDDX		DDDDD.DDFFFY	FGGGG.GGHHHZ	K			UUUUVVVVVVVVVV

	If (cBanco=="341") // 341-Itau
		// 	CAMPO 1:
		//	AAA	= Codigo do banco na Camara de Compensacao
		//	  B = Codigo da moeda, sempre 9
		//	CCC = Codigo da Carteira de Cobranca
		//	 DD = Dois primeiros digitos no nosso numero
		//	  X = DAC que amarra o campo, calculado pelo Modulo 10 da String do campo

		cS    := cBanco +"9"+ cCart + SubStr(_cNroDoc,1,2)
		nDv   := modulo10(cS)
		cRN   := SubStr(cS, 1, 5) + '.' + SubStr(cS, 6, 4) + AllTrim(Str(nDv)) + '  '

		// 	CAMPO 2:
		//	DDDDDD = Restante do Nosso Numero
		//	     E = DAC do campo Agencia/Conta/Carteira/Nosso Numero
		//	   FFF = Tres primeiros numeros que identificam a agencia
		//	     Y = DAC que amarra o campo, calculado pelo Modulo 10 da String do campo

		cS :=Subs(cNN,6,6) + Alltrim(Str(nDvnn))+ Subs(cAgencia,1,3)


		nDv:= modulo10(cS)
		cRN := Subs(cBanco,1,3) + "9" + Subs(cCart,1,1)+'.'+ Subs(cCart,2,3) + Subs(cNN,4,2) + SubStr(cRN,11,1)+ ' '+  Subs(cNN,6,5) +'.'+ Subs(cNN,11,1) + Alltrim(Str(nDvnn))+ Subs(cAgencia,1,3) +Alltrim(Str(nDv)) + ' '

		// 	CAMPO 3:
		//	     F = Restante do numero que identifica a agencia
		//	GGGGGG = Numero da Conta + DAC da mesma
		//	   HHH = Zeros (Nao utilizado)
		//	     Z = DAC que amarra o campo, calculado pelo Modulo 10 da String do campo
		cS    := Subs(cAgencia,4,1) + Left(cConta,5)+Alltrim(cDacCC)+'000'
		nDv   := modulo10(cS)
		cRN   := cRN + Subs(cAgencia,4,1) + Left(cConta,4) +'.'+ Right(cConta,1)+Alltrim(cDacCC)+'000'+ Alltrim(Str(nDv))

		//	CAMPO 4:
		//	     K = DAC do Codigo de Barras
		cRN   := cRN + ' ' + AllTrim(Str(nDvcb)) + '  '

		// 	CAMPO 5:
		//	      UUUU = Fator de Vencimento
		//	VVVVVVVVVV = Valor do Titulo
		cRN   := cRN + cFator + StrZero((nValor * 100),14-Len(cFator))

	ElseIf (cBanco=="237") // 237-Bradesco

		_cCampo1	:= cBanco					//Codigo do Banco
		_cCampo1	+= "9"						//Moeda (9-Real)
		_cCampo1 	+= SubS(cCampoLivre,1,5)	//Posicao 1 a 5 do Campo Livre
		_cCampo1 	+= sfDvDac(_cCampo1)		//Gera digito Verificado para o Campo 1


		_cCampo2	:= SubS(cCampoLivre,6,10)	//Posicao 6 a 15 do Campo Livre
		_cCampo2	+= sfDvDac(_cCampo2)		//Gera digito Verificado para o Campo 2


		_cCampo3	:= SubS(cCampoLivre,16,10)	//Posicao 16 a 25 do Campo Livre
		_cCampo3	+= sfDvDac(_cCampo3)		//Gera digito Verificado para o Campo 3

		_cCampo4	:= SubS(cCB,5,1)			//Digito Verificado do Codigo de Barras (5a Posicao)

		_cCampo5	:= cFator					//Fator de Vencimento
		_cCampo5	+= StrZero(nValor*100,10)	//Valor do Titulo

		// representacao numerica (linha digitavel)
		cRN	:= SubS(_cCampo1,1,5)+"."
		cRN	+= SubS(_cCampo1,6,5)+" "
		cRN	+= SubS(_cCampo2,1,5)+"."
		cRN	+= SubS(_cCampo2,6,6)+" "
		cRN	+= SubS(_cCampo3,1,5)+"."
		cRN	+= SubS(_cCampo3,6,6)+" "
		cRN	+= _cCampo4+" "
		cRN	+= _cCampo5
	EndIf

Return({cCB,cRN,cNN})

//========================================================================
// CDIGITONOSS0
//========================================================================
Static Function CDigitoNosso()
	******************************
	cDvn := ""

	nSoma1 := val(subs("09",01,1))       *2
	nSoma2 := val(subs("09",02,1))       *7
	nSoma3 := val(subs(Cnossonum,01,1))   *6
	nSoma4 := val(subs(Cnossonum,02,1))   *5
	nSoma5 := val(subs(Cnossonum,03,1))   *4
	nSoma6 := val(subs(Cnossonum,04,1))   *3
	nSoma7 := val(subs(Cnossonum,05,1))   *2
	nSoma8 := val(subs(Cnossonum,06,1))   *7
	nSoma9 := val(subs(Cnossonum,07,1))   *6
	nSomaA := val(subs(Cnossonum,08,1))   *5
	nSomaB := val(subs(Cnossonum,09,1))   *4
	nSomaC := val(subs(Cnossonum,10,1))   *3
	nSomaD := val(subs(Cnossonum,11,1))   *2

	cDigito := mod(nSoma1+nSoma2+nSoma3+nSoma4+nSoma5+nSoma6+nSoma7+nSoma8+nSoma9+nSomaA+nSomaB+nSomaC+nSomaD,11)

	cDvn := iif(cDigito == 1, "P", iif(cDigito == 0 , "0", strzero(11-cDigito,1)))

return(cDvn)

// Calculo do DV para o Nosso Numero para o Bradesco (modulo 11 com base 7)
Static Function sfCalcDV_NN(mvCart,mvNossoNum)
	Local cRet		:= ""
	Local cDigito	:= ""
	Local cLinCal	:= mvCart + mvNossoNum
	Local cMod11B7	:= "2765432765432"
	Local nTotal	:= 0
	Local nPos

	For nPos := 1 to Len(cLinCal)
		nTotal += Val(Subs(cLinCal,nPos,1)) * Val(SubS(cMod11B7,nPos,1))
	Next nPos

	cDigito := Mod(nTotal,11)

	cRet := If(cDigito == 1, "P", If(cDigito == 0 , "0", StrZero(11-cDigito,1)))

Return(cRet)

//Geracao do Digito Verificador do Conteudo do Codigo de Barras
Static Function sfDVCodBarras(mvCodBar)
	Local cLinha 	:= mvCodBar
	Local cMod11B9	:= "4329876543298765432987654329876543298765432"
	Local nTotal	:= 0
	Local nResto	:= 0
	Local nDigito	:= 0
	Local cDigito	:= ""
	Local _cRet		:= ""
	Local nPos

	For nPos := Len(cLinha) to 1 Step -1
		nTotal += Val(SubStr(cLinha,nPos,1)) * Val(SubStr(cMod11B9,nPos,1))
	Next nPos

	//Divisao por 11
	nResto := Mod(nTotal,11)

	//Subtrai o resto de 11
	nDigito	:= 11 - nResto

	If nDigito == 0 .or. nDigito == 1 .or. nDigito > 9
		cDigito	:= "1"
	Else
		cDigito	:= AllTrim(Str(nDigito))
	EndIf

	//Preenche a Quinta Posicao com o Digito Verificador
	_cRet	:= SubStr(mvCodBar,1,4) + cDigito + SubStr(mvCodBar,5,39)

Return(_cRet)

//Funcao que gera o Digito Verificador do Conteudo da Linha Digitavel
Static Function sfDvDac( cCampoDig )
	Local cRet		:= ""
	Local cMod10	:= If(Len(cCampoDig)==10,"1212121212","212121212")
	Local nTotal	:= 0
	Local nVlrTot	:= 0
	Local cValor	:= ""
	Local nResto	:= 0
	Local nPos

	For nPos := Len(cCampoDig) to 1 Step -1

		nVlrTot	:= Val(SubS(cCampoDig,nPos,1)) * Val(SubS(cMod10,nPos,1))

		If nVlrTot > 9
			cValor	:= AllTrim(Str(nVlrTot))
			nVlrTot	:= Val(SubS(cValor,1,1)) + Val(SubS(cValor,2,1))
		EndIf

		nTotal	+= nVlrTot

	Next nPos

	nResto	:= Mod( nTotal , 10 )

	//Se a Divisao for Exata nao Incrementa valor do Multiplicador
	nResto	:= Int(nTotal / 10) + If(nResto > 0, 1 ,0)

	nMultip	:= nResto * 10
	cRet	:= AllTrim(Str( nMultip - nTotal ))

Return cRet