#INCLUDE "PROTHEUS.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "FONT.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "RPTDEF.CH"
//#INCLUDE "ISAMQry.ch"
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Impressao do Mapa da Movimentacao                       !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2010                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSR006(mvRotAuto,mvTipImp,mv_Local,mv_Arquivo,mvProgra)
	// grupo de perguntas
	local _aPerg := {}
	local _cPerg := PadR("TWMSR006",10)

	// pagina atual
	Private _nPagAtu := 1

	// Cria Objeto para impressao Grafica
	private _oPrn

	// fontes utilizadas
	private _oFont01n
	private _oFont02
	private _oFont02n

	// total de pagina
	private _nPagTot := 1

	// quantidade total de linhas
	private _nTotLinha := 0
	// controle da linha
	private _nLin := 0
	// imagem da logo
	private _cImagem := "\"+AllTrim(CurDir())+"\logo_tecadi.jpg"

	// controle de seek (para while)
	private _cSeekSF1
	// analitico
	private _lAnalitico := .f.
	// subtotal das entradas (quantidade, peso e cubagem) por nota
	private _aSubTotEnt := {}
	// subtotal das entradas (quantidade, peso e cubagem) por nota
	private _aSubTotSai := {}
	// numero maximo de linhas por pagina
	private	_nMaxLinPg := 25
	// controle de linhas ja impressas por pagina
	private _nLinImpres := 0
	// controle da posicao da nota de entrada ja impressa
	private _nPosNfEnt := 1
	// controle da posicao da nota de saida ja impressa
	private _nPosNfSai := 1
	// controle se finalizou a impressao dos itens (analitico)
	private _lSaiImpAn := .f.
	// total quantidade saida
	private _nTotQuant := 0
	// total peso saida
	private _nTotPesoB := 0
	// total cubagem saida
	private _nTotCubag := 0
	// controle do item ja impresso
	private _nItProd := 1
	// arquivos TRB
	private _cTmpEnt, _cTmpSai

	// variaveis para gerenciar a criação do PDF
	Private lAdjustToLegacy		:= .T.
	Private lDisableSetup 		:= .T.
	Private lServer 			:= .T.
	Private lPDFAsPNG			:= .F.
	Private lViewPDF			:= .T.
	Private cDirPrint			:= ""
	Private cFileOP				:= ""
	Private cArqDir				:= ""
	Private cArqTemp			:= ""

	//Tipo de Impressão
	Private lFWMS := .F.

	// valores default
	Default mvRotAuto  := .f.
	//Parametro recebe (.T. Impressão PDF | .F. Impressão em TELA)
	Default mvTipImp   := .f.
	Default mv_Local   := ""
	Default mv_Arquivo := ""


	// criacao das Perguntas
	aAdd(_aPerg,{"Programação?"        ,"C",TamSx3("Z1_CODIGO")[1],0,"G",                         ,"SZ1",{{"X1_VALID","U_FtStrZero()"}}}) //mv_par01
	aAdd(_aPerg,{"Data de Referencia?" ,"D",8                     ,0,"G",                         ,""   ,                              }) //mv_par02
	aAdd(_aPerg,{"Layout?"             ,"N",1                     ,0,"C",{"Sintético","Analítico"},""   ,                              })//mv_par03

	// cria grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// se for chamado por outra rotina, nao apresenta os parametros
	If (!mvRotAuto)
		If ! Pergunte(_cPerg,.T.)
			Return ()
		EndIf
		//Desabilitado Opção de mpressão pelo TMSPrinter
		mvTipImp := .t.//(mv_par04==1)
	Else
		Pergunte(_cPerg,.F.)
		mv_par01 := mvProgra
		mv_par02 := dDataBase
		//Analitico
		mv_par03 := 2
	EndIf

	cDirPrint	:= Iif(Empty(mv_Local)  ,AllTrim(GetTempPath()),mv_Local)
	cFileOP		:= Iif(Empty(mv_Arquivo),"TWMSR006"            ,mv_Arquivo)
	cArqDir		:= cDirPrint + cFileOP + ".pdf"
	cArqTemp	:= cDirPrint + cFileOP + ".rel"

	//Apaga arquivos Temporarios
	FErase(cArqDir)
	FErase(cArqTemp)

	//Variavel responsavel pelo tipo de Impressão (.T. = FWMsPrinter PDF, .F. = TMSPrinter Tela)
	lFWMS := mvTipImp

	// Cria Objeto para impressao Grafica
	_oPrn := IIF(lFWMS,FWMsPrinter():New(cFileOP+".pdf",IMP_PDF,lAdjustToLegacy,cDirPrint,lDisableSetup, /*[lTReport]*/, /*[@oPrintSetup]*/, /*[ cPrinter]*/, lServer, lPDFAsPNG, /*[ lRaw]*/, lViewPDF, /*[ nQtdCopy]*/ ),TMSPrinter():New("Mapa de Movimentação"))

	//Impressão com o componente FWMsPrinter PDF
	If lFWMS
		//Fontes utilizadas
		_oFont01n := TFontEx():New(_oPrn,"Arial",20,20,.T.,.F.,.F.)// bold / italic / under
		_oFont02  := TFontEx():New(_oPrn,"Arial",15,15,.F.,.F.,.F.)// bold / italic / under
		_oFont02n := TFontEx():New(_oPrn,"Arial",15,15,.T.,.F.,.F.)// bold / italic / under
		_oPrn:nDevice  := IMP_PDF
		_oPrn:SetLandscape()
		_oPrn:SetMargin(60,60,60,60)
		_oPrn:cPathPDF := cDirPrint
		IF mvRotAuto
			//Impressão com o componente TMSPrinter Tela.
			_oPrn:GetViewPDF(.F.)
			_oPrn:SetViewPDF(.F.)
		Else
			_oPrn:Setup()
			If _oPrn:nModalResult == 2
				//Apaga arquivos Temporarios
				FErase(_oPrn:cPathPDF + cFileOP + ".pdf")
				FErase(_oPrn:cPathPDF + cFileOP + ".rel")
				_oPrn:Cancel()
				_oPrn:Deactivate()
				Return()
			EndIf
			_oPrn:GetViewPDF(.T.)
			_oPrn:SetViewPDF(.T.)
		EndIF

		//Apaga arquivos Temporarios
		FErase(_oPrn:cPathPDF + cFileOP + ".pdf")
		FErase(_oPrn:cPathPDF + cFileOP + ".rel")

	Else
		//Fontes utilizadas
		_oFont01n := TFontEx():New(_oPrn,"Tahoma",14,14,.T.,.F.,.F.)// bold / italic / under
		_oFont02  := TFontEx():New(_oPrn,"Arial Narrow",12,12,.F.,.F.,.F.)// bold / italic / under
		_oFont02n := TFontEx():New(_oPrn,"Arial Narrow",12,12,.T.,.F.,.F.)// bold / italic / under
		// chama a rotina de Configuracao da impressao
		_oPrn:Setup()
		// define como paisagem
		_oPrn:SetLandscape()
	EndIF

	// define o tipo de relatorio
	_lAnalitico := (mv_par03==2)

	// pesquisa a programacao
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	If !SZ1->(dbSeek( xFilial("SZ1")+mv_par01 ))
		If (!mvRotAuto)
			Aviso("Tecadi: TWMSR006","Programação número "+mv_par01+" não encontrada!",{"Ok"})
		EndIf
		Return(.f.)
	EndIf

	// pesquisa as notas fiscais de entrada
	dbSelectArea("SF1")
	SF1->(dbOrderNickName("PROGRAM")) // F1_FILIAL, F1_PROGRAM
	If !SF1->(dbSeek( _cSeekSF1 := xFilial("SF1")+mv_par01 ))
		If (!mvRotAuto)
			Aviso("Tecadi: TWMSR006","Nota fiscal de entrada não encontrada para a programação número "+mv_par01+".",{"Ok"})
		EndIf
		Return(.f.)
	EndIf

	If (!mvRotAuto)
		// mensagem de validacao da data
		If (mv_par02 <> Date()).and.(Aviso("TWMSR006","A data de referência está diferenta da data atual. Deseja continuar?",{"Sim","Não"}) <> 1)
			Return(.f.)
		EndIf
	EndIf

	// funcao que calcula saldo (quantidade, peso e cubagem) e retorna os itens da nota
	sfRetDetalhes()

	// ordena as informacoes das notas de entrada
	aSort(_aSubTotEnt,,,{|x,y| (x[1]+x[2])<(y[1]+y[2]) })

	// ordena as informacoes das notas de saida
	aSort(_aSubTotSai,,,{|x,y| (x[1]+x[2])<(y[1]+y[2]) })

	// calcula o total de linhas
	// cabecalhos (ent + sai)
	_nTotLinha := 2
	// notas de entrada
	_nTotLinha += Len(_aSubTotEnt)
	// itens da nota de entrada
	_nTotLinha += If(_lAnalitico,_TRBENT->(RecCount()),0)
	// notas de saida
	_nTotLinha += Len(_aSubTotSai)
	// itens da nota de saida
	_nTotLinha += If(_lAnalitico,_TRBSAI->(RecCount()),0)
	// linhas do totalizador
	_nTotLinha += 2

	// calcula a quantidade de paginas
	_nPagTot := Int(_nTotLinha/_nMaxLinPg)
	// resto da divisao
	If (Mod(_nTotLinha,_nMaxLinPg) > 0)
		_nPagTot ++
	EndIf

	If (Len(_aSubTotEnt) <= 0) .And. (Len(_aSubTotSai) <= 0)
		If (!mvRotAuto)
			MsgStop("Sem informações para Imprimir")
			//Apaga arquivos Temporarios
			FErase(_oPrn:cPathPDF + cFileOP + ".pdf")
			FErase(_oPrn:cPathPDF + cFileOP + ".rel")
		EndIf
		Return()
	EndIf

	// impressao dos dados
	For _nPagAtu := 1 to _nPagTot
		// zera o controle de linhas ja impressas por pagina
		_nLinImpres := 0
		// impressao do cabecalho
		sfCabec()
		// impressao dos detalhes
		sfDetalhes()
		// impressao do rodape
		sfRodape()
	Next _nPagAtu

	_oPrn:Print()

Return

//** funcao para impressao do cabecalho
Static Function sfCabec()
	// controle temporario da linha
	local _nTmpLin := 0

	// cria nova Pagina
	_oPrn:StartPage()

	If lFWMS
		_nLin := 250
		// primeira linha - box
		_oPrn:Box(_nLin,0030,_nLin+350,2200)
		// logo
		_oPrn:SayBitmap(_nLin+10,0060,_cImagem,500,250)
		// coluna - antes "MAPA DE MOVIMENTAÇÃO"
		_oPrn:Line(_nLin,0650,_nLin+350,0650)

		// titulo
		_oPrn:Say(_nLin+0150,0900,"MAPA DE MOVIMENTAÇÃO - PROGRAMAÇÃO: " + Alltrim(mv_par01),_oFont01n:oFont,,,)
		// data de referencia
		_oPrn:Say(_nLin+0250,1200,"Data de Referência: " + Alltrim(DtoC(mv_par02)),_oFont02:oFont,,,)
		// data e hora de impressao
		_oPrn:SayAlign(_nLin      ,1680,"Dt Impr: "+DtoC(Date())+" "+Time(),_oFont02:oFont,500,200,,1)
		// filial
		_oPrn:SayAlign(_nLin + 050,1680,"Filial: "+AllTrim(SM0->M0_CODFIL)+"-"+AllTrim(SM0->M0_FILIAL),_oFont02:oFont,500,200,,1)
		// controle de paginas
		_oPrn:SayAlign(_nLin + 250,1680,"Pág.: "+AllTrim(Str(_nPagAtu))+" de "+AllTrim(Str(_nPagTot)),_oFont02:oFont,500,200,,1)

		_nLin += 350

		// segunda linha - box - dados do cliente
		_oPrn:Box(_nLin,0030,_nLin+130,2200)
		_nTmpLin := 60

		// dados do cliente
		_oPrn:Say(_nLin+_nTmpLin,0080,"Cliente:",_oFont02:oFont)
		_oPrn:Say(_nLin+_nTmpLin,0300,SZ1->Z1_CLIENTE+"/"+SZ1->Z1_LOJA+" - "+Posicione("SA1",1, xFilial("SA1")+SZ1->Z1_CLIENTE+SZ1->Z1_LOJA ,"A1_NOME") ,_oFont02n:oFont)
		_nTmpLin += 80

		// controle da linha
		_nLin += _nTmpLin
		_nLin += 40

		// cabecalhos
		_oPrn:SayAlign(_nLin ,0300,"Data de Emissão" ,_oFont02:oFont,500,200,,)
		_oPrn:SayAlign(_nLin ,0310,"Quant Entrada"   ,_oFont02:oFont,500,200,,1)
		_oPrn:SayAlign(_nLin ,0600,"Quant Devolvida" ,_oFont02:oFont,500,200,,1)
		_oPrn:SayAlign(_nLin ,0820,"Saldo"           ,_oFont02:oFont,500,200,,1)
		_oPrn:SayAlign(_nLin ,1030,"Peso Total"      ,_oFont02:oFont,500,200,,1)
		_oPrn:SayAlign(_nLin ,1230,"Saldo do Peso"   ,_oFont02:oFont,500,200,,1)
		_oPrn:SayAlign(_nLin ,1400,"Cubagem"         ,_oFont02:oFont,500,200,,1)
		_oPrn:SayAlign(_nLin ,1650,"Saldo Cubagem"   ,_oFont02:oFont,500,200,,1)
		// controle da linha
		_nLin += 150
	Else
		_nLin := 70
		// primeira linha - box
		_oPrn:Box(_nLin,0060,_nLin+260,3320)
		// logo
		_oPrn:SayBitmap(_nLin+10,0150,_cImagem,744.8,239.4)
		// coluna - antes "MAPA DE MOVIMENTAÇÃO"
		_oPrn:Line(_nLin,0980,_nLin+260,0980)
		// data e hora de impressao
		_oPrn:Say(_nLin+10,3280,"Dt Impr: "+DtoC(Date())+" "+Time(),_oFont02:oFont,,,,1)
		// filial
		_oPrn:Say(_nLin+60,3280,"Filial: "+AllTrim(SM0->M0_CODFIL)+"-"+AllTrim(SM0->M0_FILIAL),_oFont02:oFont,,,,1)
		// titulo
		_oPrn:Say(_nLin+90,2160,"MAPA DE MOVIMENTAÇÃO - PROGRAMAÇÃO: "+mv_par01,_oFont01n:oFont,,,,2)
		// data de referencia
		_oPrn:Say(_nLin+165,2160,"Data de Referência: "+DtoC(mv_par02),_oFont02:oFont,,,,2)
		// controle de paginas
		_oPrn:Say(_nLin+200,3280,"Pág.: "+AllTrim(Str(_nPagAtu))+" de "+AllTrim(Str(_nPagTot)),_oFont02:oFont,,,,1)
		_nLin += 260

		// segunda linha - box - dados do cliente
		_oPrn:Box(_nLin,0060,_nLin+130,3320)
		_nTmpLin := 40

		// dados do cliente
		_oPrn:Say(_nLin+_nTmpLin,0080,"Cliente:",_oFont02:oFont)
		_oPrn:Say(_nLin+_nTmpLin,0300,SZ1->Z1_CLIENTE+"/"+SZ1->Z1_LOJA+" - "+Posicione("SA1",1, xFilial("SA1")+SZ1->Z1_CLIENTE+SZ1->Z1_LOJA ,"A1_NOME") ,_oFont02n:oFont)
		_nTmpLin += 80

		// controle da linha
		_nLin += _nTmpLin
		_nLin += 40

		// cabecalhos
		_oPrn:Say(_nLin,0400,"Data de Emissão",_oFont02:oFont)
		// quantidade original da nota
		_oPrn:Say(_nLin,1000,"Quant Entrada",_oFont02:oFont,,,,1)
		// quantidade já devolvida
		_oPrn:Say(_nLin,1300,"Quant Devolvida",_oFont02:oFont,,,,1)
		// saldo restante a devolver
		_oPrn:Say(_nLin,1650,"Saldo",_oFont02:oFont,,,,1)
		// peso total
		_oPrn:Say(_nLin,2100,"Peso Total",_oFont02:oFont,,,,1)
		// saldo do peso
		_oPrn:Say(_nLin,2400,"Saldo do Peso",_oFont02:oFont,,,,1)
		// cubagem total
		_oPrn:Say(_nLin,2700,"Cubagem",_oFont02:oFont,,,,1)
		// saldo da cubagem
		_oPrn:Say(_nLin,3040,"Saldo Cubagem",_oFont02:oFont,,,,1)
		// controle da linha
		_nLin += 70
	EndIf
Return

//** funcao para impressao dos detalhes
Static Function sfDetalhes()
	// variavel temporaria
	Local _nNfEnt, _nNfSai
	// controle temporario da linha
	Local _nTmpLin := 0

	// coloca apenas uma vez a descricao do cabecalho - entrada
	If (_nPosNfEnt==1)
		// primeira linha - notas de entrada
		_oPrn:Say(_nLin,0080,"NOTAS FISCAIS DE ENTRADA",_oFont02n:oFont)
		// linha separadora
		_oPrn:Line(_nLin + 30, 0080, _nLin + 30, 2200,,"-4")
		// controle das linhas
		_nLin += 65

		// linha ja impressa por pagina
		_nLinImpres ++
		// verifica se eh necessario nova pagina
		If (_nLinImpres == _nMaxLinPg)
			Return
		EndIf
	EndIf

	// impressao de todas as notas de entrada para a programacao
	For _nNfEnt := _nPosNfEnt to Len(_aSubTotEnt)

		If lFWMS
			// numero da nota
			_oPrn:SayAlign(_nLin+_nTmpLin ,0080,AllTrim(_aSubTotEnt[_nNfEnt][1])+"/"+_aSubTotEnt[_nNfEnt][2] ,_oFont02:oFont,500,200,,)
			// data de emissao
			_oPrn:SayAlign(_nLin+_nTmpLin ,0300,DtoC(_aSubTotEnt[_nNfEnt][9])      ,_oFont02:oFont,500,200,,)
			// quantidade original da nota
			_oPrn:SayAlign(_nLin+_nTmpLin ,0310,Transf(_aSubTotEnt[_nNfEnt][3],PesqPict("SD1","D1_QUANT"))   ,_oFont02:oFont,500,200,,1)
			// quantidade já devolvida
			_oPrn:SayAlign(_nLin+_nTmpLin ,0600,Transf((_aSubTotEnt[_nNfEnt][3] - _aSubTotEnt[_nNfEnt][4]),PesqPict("SD1","D1_QUANT")) ,_oFont02:oFont,500,200,,1)
			// saldo restante a devolver
			_oPrn:SayAlign(_nLin+_nTmpLin ,0820,Transf(_aSubTotEnt[_nNfEnt][4],PesqPict("SD1","D1_QUANT"))   ,_oFont02:oFont,500,200,,1)
			// peso total
			_oPrn:SayAlign(_nLin+_nTmpLin ,1030,Transf(_aSubTotEnt[_nNfEnt][5],PesqPict("SD1","D1_ZPESOB"))  ,_oFont02:oFont,500,200,,1)
			// saldo do peso
			_oPrn:SayAlign(_nLin+_nTmpLin ,1230,Transf(_aSubTotEnt[_nNfEnt][6],PesqPict("SD1","D1_ZPESOB"))  ,_oFont02:oFont,500,200,,1)
			// cubagem total
			_oPrn:SayAlign(_nLin+_nTmpLin ,1400,Transf(_aSubTotEnt[_nNfEnt][7],PesqPict("SF1","F1_CUBAGEM")) ,_oFont02:oFont,500,200,,1)
			// saldo da cubagem
			_oPrn:SayAlign(_nLin+_nTmpLin ,1650,Transf(_aSubTotEnt[_nNfEnt][8],PesqPict("SF1","F1_CUBAGEM")) ,_oFont02:oFont,500,200,,1)
			// controle da linha
			_nTmpLin += 80
		Else
			// numero da nota
			_oPrn:Say(_nLin+_nTmpLin,0080,AllTrim(_aSubTotEnt[_nNfEnt][1])+"/"+_aSubTotEnt[_nNfEnt][2],_oFont02:oFont)
			// data de emissao
			_oPrn:Say(_nLin+_nTmpLin,0400,DtoC(_aSubTotEnt[_nNfEnt][9]),_oFont02:oFont)
			// quantidade original da nota
			_oPrn:Say(_nLin+_nTmpLin,1000,Transf(_aSubTotEnt[_nNfEnt][3],PesqPict("SD1","D1_QUANT")),_oFont02:oFont,,,,1)
			// quantidade já devolvida
			_oPrn:Say(_nLin+_nTmpLin,1400,Transf((_aSubTotEnt[_nNfEnt][3] - _aSubTotEnt[_nNfEnt][4]),PesqPict("SD1","D1_QUANT")),_oFont02:oFont,,,,1)
			// saldo restante a devolver
			_oPrn:Say(_nLin+_nTmpLin,1930,Transf(_aSubTotEnt[_nNfEnt][4],PesqPict("SD1","D1_QUANT")),_oFont02:oFont,,,,1)
			// peso total
			_oPrn:Say(_nLin+_nTmpLin,2100,Transf(_aSubTotEnt[_nNfEnt][5],PesqPict("SD1","D1_ZPESOB")),_oFont02:oFont,,,,1)
			// saldo do peso
			_oPrn:Say(_nLin+_nTmpLin,2400,Transf(_aSubTotEnt[_nNfEnt][6],PesqPict("SD1","D1_ZPESOB")),_oFont02:oFont,,,,1)
			// cubagem total
			_oPrn:Say(_nLin+_nTmpLin,2700,Transf(_aSubTotEnt[_nNfEnt][7],PesqPict("SF1","F1_CUBAGEM")),_oFont02:oFont,,,,1)
			// saldo da cubagem
			_oPrn:Say(_nLin+_nTmpLin,3040,Transf(_aSubTotEnt[_nNfEnt][8],PesqPict("SF1","F1_CUBAGEM")),_oFont02:oFont,,,,1)
			// controle da linha
			_nTmpLin += 70
		EndIf

		// linha ja impressa por pagina
		_nLinImpres ++
		// verifica se eh necessario nova pagina
		If (_nLinImpres == _nMaxLinPg)
			Return
		EndIf

		// quando nao for analitico, controla as notas de entrada ja impressas
		If ( ! _lAnalitico)
			_nPosNfEnt ++

			// se for analitico, imprime os itens da nota
		ElseIf (_lAnalitico)
			dbSelectArea("_TRBENT")
			While _TRBENT->(!Eof()).and.(_TRBENT->(D1_DOC+D1_SERIE)==_aSubTotEnt[_nNfEnt][1]+_aSubTotEnt[_nNfEnt][2])
				// impressao de todos os campos somente na sequencia 001
				If (_TRBENT->IT_SEQ=="001")
					If lFWMS
						// item da nota
						_oPrn:SayAlign(_nLin+_nTmpLin,0120,_TRBENT->D1_ITEM,_oFont02:oFont,500,50,,)
						// codigo do produto
						_oPrn:SayAlign(_nLin+_nTmpLin,0200,_TRBENT->D1_COD,_oFont02:oFont,500,50,,)
						// descricao do produto
						_oPrn:SayAlign(_nLin+_nTmpLin,0550,_TRBENT->B1_DESC,_oFont02:oFont,900,50,,)
					Else
						// item da nota
						_oPrn:Say(_nLin+_nTmpLin,0120,_TRBENT->D1_ITEM,_oFont02:oFont)
						// codigo do produto
						_oPrn:Say(_nLin+_nTmpLin,0200,_TRBENT->D1_COD,_oFont02:oFont)
						// descricao do produto
						_oPrn:Say(_nLin+_nTmpLin,0750,_TRBENT->B1_DESC,_oFont02:oFont)
					EndIf
				EndIF
				// impressao de todos os campos somente na sequencia 001
				If (_TRBENT->IT_SEQ=="001")
					If lFWMS
						// quantidade
						_oPrn:SayAlign(_nLin+_nTmpLin ,1200,Transf(_TRBENT->D1_QUANT,PesqPict("SD1","D1_QUANT"))   ,_oFont02:oFont,500,200,,1)
						// Unidade de Medida
						_oPrn:SayAlign(_nLin+_nTmpLin ,1300,_TRBENT->D1_UM   ,_oFont02:oFont,500,200,,1)
						// titulo do saldo
						_oPrn:SayAlign(_nLin+_nTmpLin ,1450,"Saldo: "  ,_oFont02:oFont,500,200,,1)
						// saldo do produto
						_oPrn:SayAlign(_nLin+_nTmpLin ,1650,Transf(_TRBENT->IT_QTDSLD,PesqPict("SD1","D1_QUANT"))  ,_oFont02:oFont,500,200,,1)
					Else
						// quantidade
						_oPrn:Say(_nLin+_nTmpLin,2400,Transf(_TRBENT->D1_QUANT,PesqPict("SD1","D1_QUANT")),_oFont02:oFont,,,,1)
						// Unidade de Medida
						_oPrn:Say(_nLin+_nTmpLin,2410,_TRBENT->D1_UM,_oFont02:oFont)
						// titulo do saldo
						_oPrn:Say(_nLin+_nTmpLin,2500,"Saldo: ",_oFont02:oFont)
						// saldo do produto
						_oPrn:Say(_nLin+_nTmpLin,2880,Transf(_TRBENT->IT_QTDSLD,PesqPict("SD1","D1_QUANT")),_oFont02:oFont,,,,1)

					EndIf
				EndIf

				// controle da linha
				_nTmpLin += 70
				// linha ja impressa por pagina
				_nLinImpres ++

				// proximo item
				_TRBENT->(dbSkip())

				// controla as notas de entrada ja impressas
				If ( (_TRBENT->(D1_DOC+D1_SERIE)) != (_aSubTotEnt[_nNfEnt][1]+_aSubTotEnt[_nNfEnt][2]) )
					_nPosNfEnt ++
				EndIf

				// verifica se eh necessario nova pagina
				If (_nLinImpres == _nMaxLinPg)
					Return
				EndIf

			EndDo
		EndIf

	Next _nNfEnt

	// acerta o contador da linha
	_nLin += _nTmpLin

	// coloca apenas uma vez a descricao do cabecalho - saida
	If (_nPosNfSai == 1).and.(!_lSaiImpAn)
		// acerta o contador da linha
		_nLin += 80
		// primeira linha - notas de entrada
		_oPrn:Say(_nLin,0080,"NOTAS FISCAIS DE RETORNO",_oFont02n:oFont)
		// linha separadora
		_oPrn:Line(_nLin + 30, 0080, _nLin + 30, 2200,,"-4")
		// controle da linha
		_nLin += 65
		_nTmpLin := 0
		// linha ja impressa por pagina
		_nLinImpres ++
		// verifica se eh necessario nova pagina
		If (_nLinImpres == _nMaxLinPg)
			Return
		EndIf

	EndIf

	// impressao de todas as notas de saida para a programacao
	For _nNfSai := _nPosNfSai to Len(_aSubTotSai)
		// verifica se deve imprimir o cabecalho da nota
		If (!_lSaiImpAn)

			If lFWMS
				// numero da nota
				_oPrn:SayAlign(_nLin+_nTmpLin ,0080,AllTrim(_aSubTotSai[_nNfSai][1])+"/"+_aSubTotSai[_nNfSai][2],_oFont02:oFont,500,200,,)
				// data de emissao
				_oPrn:SayAlign(_nLin+_nTmpLin ,0300,DtoC(_aSubTotSai[_nNfSai][6]) ,_oFont02:oFont,500,200,,)
				// quantidade original da nota
				_oPrn:SayAlign(_nLin+_nTmpLin ,0310,Transf(_aSubTotSai[_nNfSai][3],PesqPict("SD2","D2_QUANT"))   ,_oFont02:oFont,500,200,,1)
				// peso total
				_oPrn:SayAlign(_nLin+_nTmpLin ,1030,Transf(_aSubTotSai[_nNfSai][4],PesqPict("SF1","F1_PBRUTO"))  ,_oFont02:oFont,500,200,,1)
				// cubagem total
				_oPrn:SayAlign(_nLin+_nTmpLin ,1400,Transf(_aSubTotSai[_nNfSai][5],PesqPict("SF1","F1_CUBAGEM")) ,_oFont02:oFont,500,200,,1)
			Else
				// numero da nota
				_oPrn:Say(_nLin+_nTmpLin,0080,AllTrim(_aSubTotSai[_nNfSai][1])+"/"+_aSubTotSai[_nNfSai][2],_oFont02:oFont)
				// data de emissao
				_oPrn:Say(_nLin+_nTmpLin,0400,DtoC(_aSubTotSai[_nNfSai][6]),_oFont02:oFont)
				// quantidade original da nota
				_oPrn:Say(_nLin+_nTmpLin,1000,Transf(_aSubTotSai[_nNfSai][3],PesqPict("SD2","D2_QUANT")),_oFont02:oFont,,,,1)
				// peso total
				_oPrn:Say(_nLin+_nTmpLin,2100,Transf(_aSubTotSai[_nNfSai][4],PesqPict("SF1","F1_PBRUTO")),_oFont02:oFont,,,,1)
				// cubagem total
				_oPrn:Say(_nLin+_nTmpLin,2700,Transf(_aSubTotSai[_nNfSai][5],PesqPict("SF1","F1_CUBAGEM")),_oFont02:oFont,,,,1)
			EndIf

			// total quantidade saida
			_nTotQuant += _aSubTotSai[_nNfSai][3]
			// total peso saida
			_nTotPesoB += _aSubTotSai[_nNfSai][4]
			// total cubagem saida
			_nTotCubag += _aSubTotSai[_nNfSai][5]

			// controle da linha
			_nTmpLin += 70

			// linha ja impressa por pagina
			_nLinImpres ++

			// se for analitico, marca pra imprimir os itens analitico
			If (_lAnalitico)
				_lSaiImpAn := .t.
			EndIf

			// verifica se eh necessario nova pagina
			If (_nLinImpres == _nMaxLinPg)
				// se nao for analitico, controla a pagina
				If (!_lAnalitico)
					// controle das notas de saida ja impressas
					_nPosNfSai ++
				EndIf
				Return
			EndIf

		EndIf

		If ! lFWMS
			// controle da linha
			_nTmpLin += 70
		EndIf

		// se for analitico, imprime os itens da nota
		If (_lAnalitico)
			dbSelectArea("_TRBSAI")
			While _TRBSAI->(!Eof()).and.(_TRBSAI->(D2_DOC+D2_SERIE)==_aSubTotSai[_nNfSai][1]+_aSubTotSai[_nNfSai][2])
				// impressao de todos os campos somente na sequencia 001
				If (_TRBSAI->IT_SEQ=="001")
					If lFWMS
						// item da nota
						_oPrn:SayAlign(_nLin+_nTmpLin,0120,_TRBSAI->D2_ITEM,_oFont02:oFont,500,50,,)
						// codigo do produto
						_oPrn:SayAlign(_nLin+_nTmpLin,0200,_TRBSAI->D2_COD,_oFont02:oFont,500,50,,)
						// descricao do produto
						_oPrn:SayAlign(_nLin+_nTmpLin,0550,_TRBSAI->B1_DESC,_oFont02:oFont,900,50,,)
						// quantidade
						_oPrn:SayAlign(_nLin+_nTmpLin ,1200,Transf(_TRBSAI->D2_QUANT,PesqPict("SD1","D1_QUANT"))   ,_oFont02:oFont,500,200,,1)
						// Unidade de Medida
						_oPrn:SayAlign(_nLin+_nTmpLin ,1300,_TRBSAI->D2_UM,_oFont02:oFont,500,200,,1)

					Else
						// item da nota
						_oPrn:Say(_nLin+_nTmpLin,0120,_TRBSAI->D2_ITEM,_oFont02:oFont)
						// codigo do produto
						_oPrn:Say(_nLin+_nTmpLin,0200,_TRBSAI->D2_COD,_oFont02:oFont)
						// descricao do produto
						_oPrn:Say(_nLin+_nTmpLin,0750,_TRBSAI->B1_DESC,_oFont02:oFont)
						// quantidade
						_oPrn:Say(_nLin+_nTmpLin,2400,Transf(_TRBSAI->D2_QUANT,PesqPict("SD2","D2_QUANT")),_oFont02:oFont,,,,1)
						// unidade de medida
						_oPrn:Say(_nLin+_nTmpLin,2410,_TRBSAI->D2_UM,_oFont02:oFont)

					EndIf
				EndIf

				// controle da linha
				_nTmpLin += 70

				// linha ja impressa por pagina
				_nLinImpres ++

				// proximo item
				_TRBSAI->(dbSkip())

				// se for outra nota, reinicia impressao
				_lSaiImpAn := (_TRBSAI->(D2_DOC+D2_SERIE) == _aSubTotSai[_nNfSai][1]+_aSubTotSai[_nNfSai][2])

				// verifica se eh necessario nova pagina
				If (_nLinImpres == _nMaxLinPg)
					// se for outra nota, altera a posicao do vetor
					If (!_lSaiImpAn)
						// controle das notas de saida ja impressas
						_nPosNfSai ++
					EndIf
					// acerta o contador de linha
					_nLin += (_nTmpLin + 40)
					// encerra a funcao
					Return
				EndIf

			EndDo
		EndIf

		// controle das notas de saida ja impressas
		_nPosNfSai ++

		// verifica se eh necessario nova pagina
		If (_nLinImpres == _nMaxLinPg)
			Return
		EndIf

		If (_lAnalitico)
			_nLin += 10
		EndIf

	Next _nNfSai

	// acerta o contador de linha
	_nLin += (_nTmpLin + 40)

	// linha ja impressa por pagina
	_nLinImpres ++

Return

//** funcao para impressao do rodape
Static Function sfRodape()
	// na ultima pagina imprime os totais
	If (_nPagAtu == _nPagTot)
		If lFWMS
			// quantidade original da nota
			_oPrn:SayAlign(_nLin ,0310,Transf(_nTotQuant,PesqPict("SD2","D2_QUANT"))   ,_oFont02:oFont,500,200,,1)
			// peso total
			_oPrn:SayAlign(_nLin ,1030,Transf(_nTotPesoB,PesqPict("SF1","F1_PBRUTO"))  ,_oFont02:oFont,500,200,,1)
			// cubagem total
			_oPrn:SayAlign(_nLin ,1400,Transf(_nTotCubag,PesqPict("SF1","F1_CUBAGEM")) ,_oFont02:oFont,500,200,,1)
		Else
			// quantidade total das notas
			_oPrn:Say(_nLin,1400,Transf(_nTotQuant,PesqPict("SD2","D2_QUANT")),_oFont02n:oFont,,,,1)
			// peso total das notas
			_oPrn:Say(_nLin,2000,Transf(_nTotPesoB,PesqPict("SF1","F1_PBRUTO")),_oFont02n:oFont,,,,1)
			// cubagem total das notas
			_oPrn:Say(_nLin,2600,Transf(_nTotCubag,PesqPict("SF1","F1_CUBAGEM")),_oFont02n:oFont,,,,1)
		EndIf
	EndIf

	// finaliza pagina
	_oPrn:EndPage()

Return

//** funcao que monta arquivos temporarios com os detalhes de entrada e saida
Static Function sfRetDetalhes()
	// variavel de retorno
	local _aRet := {}
	// area inicial
	local _aAreaSF1 := SF1->(GetArea())
	local _aAreaSD1 := SD1->(GetArea())
	local _aAreaSB6 := SB6->(GetArea())
	local _aAreaSB1 := SB1->(GetArea())
	local _aAreaSD2 := SD2->(GetArea())
	// Seek dos itens
	local _cSeekSD1, _cSeekSB6, _cSeekSD2
	// saldo do produto na entrada (somente quantidade)
	local _aSaldoPd3 := {}
	// saldo atual (em quantidade, peso e cubagem)
	local _aSaldoAtu := {}
	// variaveis temporarias
	local _nPosEnt, _nPosSai
	local _aTrbEnt := {}
	local _aTrbSai := {}
	// descricao do produto para quebra de linha
	local _aTmpDescr := {}
	local _nLinDescr := 0
	local _nMaxDescr := 65

	// zera o subtotal das notas
	_aSubTotEnt := {}
	_aSubTotSai := {}

	// monta o arquivo de trabalho dos itens das notas de ENTRADA
	aAdd(_aTrbEnt,{"D1_DOC"    ,"C",TamSx3("D1_DOC")[1],0})
	aAdd(_aTrbEnt,{"D1_SERIE"  ,"C",TamSx3("D1_SERIE")[1],0})
	aAdd(_aTrbEnt,{"D1_ITEM"   ,"C",TamSx3("D1_ITEM")[1],0})
	aAdd(_aTrbEnt,{"D1_COD"    ,"C",TamSx3("D1_COD")[1],0})
	aAdd(_aTrbEnt,{"IT_SEQ"    ,"C",3,0})
	//aAdd(_aTrbEnt,{"B1_DESC"   ,"C",TamSx3("B1_DESC")[1],0})
	aAdd(_aTrbEnt,{"B1_DESC"   ,"C",65,0})
	aAdd(_aTrbEnt,{"D1_QUANT"  ,"N",TamSx3("D1_QUANT")[1],TamSx3("D1_QUANT")[2]})
	aAdd(_aTrbEnt,{"D1_UM"     ,"C",TamSx3("D1_UM")[1],0})
	aAdd(_aTrbEnt,{"IT_QTDSLD" ,"N",TamSx3("D1_QUANT")[1],TamSx3("D1_QUANT")[2]})
	aAdd(_aTrbEnt,{"D1_ZPESOB" ,"N",TamSx3("D1_ZPESOB")[1],TamSx3("D1_ZPESOB")[2]})
	aAdd(_aTrbEnt,{"IT_PESOSLD","N",TamSx3("D1_ZPESOB")[1],TamSx3("D1_ZPESOB")[2]})
	aAdd(_aTrbEnt,{"F1_CUBAGEM","N",TamSx3("F1_CUBAGEM")[1],TamSx3("F1_CUBAGEM")[2]})
	aAdd(_aTrbEnt,{"IT_CUBSLD" ,"N",TamSx3("F1_CUBAGEM")[1],TamSx3("F1_CUBAGEM")[2]})
	aAdd(_aTrbEnt,{"F1_EMISSAO","D",TamSx3("F1_EMISSAO")[1],0})

	If (Select("_TRBENT")<>0)
		dbSelectArea("_TRBENT")
		DbCloseArea()
	EndIf
	_cTmpEnt := CriaTrab(_aTrbEnt,.T.)
	dbUseArea(.T.,,_cTmpEnt,"_TRBENT",.F.,.F.)
	IndRegua("_TRBENT",_cTmpEnt,"D1_DOC+D1_SERIE+D1_ITEM",,,"Selecionando registros...")

	// monta o arquivo de trabalho dos itens das notas de SAIDA
	aAdd(_aTrbSai,{"D2_DOC"    ,"C",TamSx3("D2_DOC")[1],0})
	aAdd(_aTrbSai,{"D2_SERIE"  ,"C",TamSx3("D2_SERIE")[1],0})
	aAdd(_aTrbSai,{"D2_ITEM"   ,"C",TamSx3("D2_ITEM")[1],0})
	aAdd(_aTrbSai,{"D2_COD"    ,"C",TamSx3("D2_COD")[1],0})
	aAdd(_aTrbSai,{"IT_SEQ"    ,"C",3,0})
	//aAdd(_aTrbSai,{"B1_DESC"   ,"C",TamSx3("B1_DESC")[1],0})
	aAdd(_aTrbSai,{"B1_DESC"   ,"C",65,0})
	aAdd(_aTrbSai,{"D2_QUANT"  ,"N",TamSx3("D2_QUANT")[1],TamSx3("D2_QUANT")[2]})
	aAdd(_aTrbSai,{"D2_UM"     ,"C",TamSx3("D2_UM")[1],0})
	aAdd(_aTrbSai,{"D2_ZPESOB" ,"N",TamSx3("D2_ZPESOB")[1],TamSx3("D2_ZPESOB")[2]})
	aAdd(_aTrbSai,{"D2_ZCUBAGE","N",TamSx3("D2_ZCUBAGE")[1],TamSx3("D2_ZCUBAGE")[2]})
	aAdd(_aTrbSai,{"D2_EMISSAO","D",TamSx3("D2_EMISSAO")[1],0})

	If (Select("_TRBSAI")<>0)
		dbSelectArea("_TRBSAI")
		DbCloseArea()
	EndIf
	_cTmpSai := CriaTrab(_aTrbSai,.T.)
	dbUseArea(.T.,,_cTmpSai,"_TRBSAI",.F.,.F.)
	IndRegua("_TRBSAI",_cTmpSai,"D2_DOC+D2_SERIE+D2_ITEM",,,"Selecionando registros...")


	// posiciona nas notas de entrada da programacao
	dbSelectArea("SF1")
	While SF1->(!Eof()).and.(SF1->(F1_FILIAL+F1_PROGRAM)==_cSeekSF1)
		// filtra nota pela data de digitacao (entrada da nota na tecadi)
		If (SF1->F1_DTDIGIT > mv_par02)
			SF1->(dbSkip())
			Loop
		EndIf

		// pesquisa os itens da nota
		dbSelectArea("SD1")
		SD1->(dbSetOrder(1)) //1-D1_FILIAL, D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_COD, D1_ITEM
		SD1->(dbSeek( _cSeekSD1 := xFilial("SD1")+SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) ))
		While SD1->(!Eof()).and.(SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA)==_cSeekSD1)
			// calcula o saldo do produto
			_aSaldoPd3 := CalcTerc(	SD1->D1_COD,;
				SD1->D1_FORNECE,;
				SD1->D1_LOJA,;
				SD1->D1_IDENTB6,;
				SD1->D1_TES,,,mv_par02)

			// descricao do produto
			_aTmpDescr := QbTexto( AllTrim(Posicione("SB1",1, xFilial("SB1")+SD1->D1_COD ,"B1_DESC")) ,_nMaxDescr," ")

			// insere o registro no TRB de entrada, conforme o tamanho da descricao
			For _nLinDescr := 1 to Len(_aTmpDescr)
				dbSelectArea("_TRBENT")
				RecLock("_TRBENT",.t.)
				_TRBENT->D1_DOC		:= SD1->D1_DOC
				_TRBENT->D1_SERIE	:= SD1->D1_SERIE
				_TRBENT->D1_ITEM	:= SD1->D1_ITEM
				_TRBENT->D1_COD		:= SD1->D1_COD
				_TRBENT->IT_SEQ		:= StrZero(_nLinDescr,3)
				_TRBENT->B1_DESC	:= _aTmpDescr[_nLinDescr]
				_TRBENT->D1_QUANT	:= _aSaldoPd3[6]
				_TRBENT->D1_UM		:= SD1->D1_UM
				_TRBENT->IT_QTDSLD	:= _aSaldoPd3[1]
				_TRBENT->D1_ZPESOB	:= SD1->D1_ZPESOB
				_TRBENT->IT_PESOSLD	:= 0
				_TRBENT->F1_CUBAGEM	:= 0
				_TRBENT->IT_CUBSLD	:= 0
				//_TRBENT->F1_EMISSAO	:= SF1->F1_EMISSAO ### ver aki a data... data de emissao e data de digitacao... qual usar ???? tem q mudar o faturamento
				MsUnLock()
			Next _nLinDescr

			// vetor com o subtotal por nota de entrada
			If ((_nPosEnt := aScan(_aSubTotEnt,{|x| x[1]+x[2] == SD1->D1_DOC+SD1->D1_SERIE})) == 0)
				// adiciona o item
				Aadd(_aSubTotEnt,{SD1->D1_DOC,;		//1-documento
				SD1->D1_SERIE,;	//2-serie
				SD1->D1_QUANT,;	//3-quant
				_aSaldoPd3[1],;	//4-saldo
				SD1->D1_ZPESOB,;	//5-peso bruto
				SD1->D1_ZPESOB,;	//6-saldo peso bruto
				SD1->D1_ZCUBAGE,;	//7-cubagem
				SD1->D1_ZCUBAGE,;	//8-saldo cubagem
				SF1->F1_EMISSAO})	//9-dt emissao
			Else
				_aSubTotEnt[_nPosEnt,3] += SD1->D1_QUANT
				_aSubTotEnt[_nPosEnt,4] += _aSaldoPd3[1]
				_aSubTotEnt[_nPosEnt,5] += SD1->D1_ZPESOB
				_aSubTotEnt[_nPosEnt,6] += SD1->D1_ZPESOB
				_aSubTotEnt[_nPosEnt,7] += SD1->D1_ZCUBAGE
				_aSubTotEnt[_nPosEnt,8] += SD1->D1_ZCUBAGE
			EndIf

			// verifico todas as notas de saida (retorno)
			dbSelectArea("SD2")
			SD2->(dbOrderNickName("D2_IDENTB6")) //D2_FILIAL, D2_CLIENTE, D2_LOJA, D2_NFORI, D2_SERIORI, D2_ITEMORI, D2_COD, D2_IDENTB6
			SD2->(dbSeek( _cSeekSD2 := xFilial("SD2")+SD1->(D1_FORNECE+D1_LOJA+D1_DOC+D1_SERIE+D1_ITEM+D1_COD+D1_IDENTB6) ))
			While SD2->(!Eof()).And.(SD2->(D2_FILIAL+D2_CLIENTE+D2_LOJA+D2_NFORI+D2_SERIORI+D2_ITEMORI+D2_COD+D2_IDENTB6)==_cSeekSD2)
				// filtra registros de acordo com a data de referencia
				If (SD2->D2_EMISSAO > mv_par02)
					SD2->(dbSkip())
					Loop
				Endif

				// descricao do produto
				_aTmpDescr := QbTexto( AllTrim(Posicione("SB1",1, xFilial("SB1")+SD2->D2_COD ,"B1_DESC")) ,_nMaxDescr," ")

				// insere o registro no TRB de saidas, conforme o tamanho da descricao
				For _nLinDescr := 1 to Len(_aTmpDescr)
					dbSelectArea("_TRBSAI")
					RecLock("_TRBSAI",.t.)
					_TRBSAI->D2_DOC		:= SD2->D2_DOC
					_TRBSAI->D2_SERIE	:= SD2->D2_SERIE
					_TRBSAI->D2_ITEM	:= SD2->D2_ITEM
					_TRBSAI->D2_COD		:= SD2->D2_COD
					_TRBSAI->IT_SEQ		:= StrZero(_nLinDescr,3)
					_TRBSAI->B1_DESC	:= _aTmpDescr[_nLinDescr]
					_TRBSAI->D2_QUANT	:= SD2->D2_QUANT
					_TRBSAI->D2_UM		:= SD2->D2_UM
					_TRBSAI->D2_ZPESOB	:= SD2->D2_ZPESOB
					_TRBSAI->D2_ZCUBAGE	:= SD2->D2_ZCUBAGE
					_TRBSAI->D2_EMISSAO	:= SD2->D2_EMISSAO
					MsUnLock()
				Next _nLinDescr

				// vetor com o subtotal por nota de saida
				If ((_nPosSai := aScan(_aSubTotSai,{|x| x[1]+x[2] == SD2->D2_DOC+SD2->D2_SERIE})) == 0)
					// adiciona o item
					Aadd(_aSubTotSai,{SD2->D2_DOC,;		//1-documento
					SD2->D2_SERIE,;	//2-serie
					SD2->D2_QUANT,;	//3-quantidade
					SD2->D2_ZPESOB,;	//4-peso bruto
					SD2->D2_ZCUBAGE,;	//5-cubagem
					SD2->D2_EMISSAO})	//6-data de emissao
				Else
					_aSubTotSai[_nPosSai,3] += SD2->D2_QUANT
					_aSubTotSai[_nPosSai,4] += SD2->D2_ZPESOB
					_aSubTotSai[_nPosSai,5] += SD2->D2_ZCUBAGE
				EndIf

				// nesse momento, tenho a quantidade que saiu por produto
				// atualizo a quantidade de saidas no vetor da nota de entrada
				If ((_nPosEnt := aScan(_aSubTotEnt,{|x| x[1]+x[2] == SD1->D1_DOC+SD1->D1_SERIE})) > 0)
					_aSubTotEnt[_nPosEnt,6] -= SD2->D2_ZPESOB
					_aSubTotEnt[_nPosEnt,8] -= SD2->D2_ZCUBAGE
				EndIf

				// proximo item
				SD2->(dbSkip())
			EndDo

			// proximo item da nota
			dbSelectArea("SD1")
			SD1->(dbSkip())
		EndDo

		// proxima nota
		SF1->(dbSkip())
	EndDo

	// posiciona no primeiro registro
	dbSelectArea("_TRBENT")
	_TRBENT->(dbSetOrder(1))
	_TRBENT->(dbGoTop())

	dbSelectArea("_TRBSAI")
	_TRBSAI->(dbSetOrder(1))
	_TRBSAI->(dbGoTop())

	// restaura area inicial
	RestArea(_aAreaSD2)
	RestArea(_aAreaSB1)
	RestArea(_aAreaSB6)
	RestArea(_aAreaSD1)
	RestArea(_aAreaSF1)

Return(_aRet)