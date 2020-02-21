#Include 'Protheus.ch'
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "RPTDEF.CH"
#INCLUDE "topconn.ch"
#INCLUDE "SHELL.CH"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ ped_ven    ³ Autor ³ Rubem Cerqueira             ³ Data ³ 29/07/17 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Impressão Pedido de Venda                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/
User Function Ped_Ven()
	***********************
	
	Local lAdjustToLegacy := .F.
	Local lDisableSetup  := .T.
	Local nConta
	Local x, p
	Local y, v, h, n
	
	
	Local aArqs    := {"SC5","SC6","SF2","SD2"}
	Local aPar := {"","01","0101"}
	
	If Select("SX6") == 0
		lJob := .T.
		xEmp := aPar[2]
		xFil := aPar[3]
		RPCSetType(3)
		RpcSetEnv (xEmp,xFil,,,,,aArqs)
	Endif
	
	
	Private nHor
	Private nVer
	Private oBrush1
	Private cBmp := GetSrvProfString('Startpath','')+"LOGOCEK.jpg"
	Private cNomeRel := "ped_venda.pdf"
	Private nTopoBox := 25
	Private nEsquerda := 5
	Private nDireita := 555
	Private nFimBox := 100
	Private nMeio := 275
	Private nIt
	Private nTot
	Private nCondp
	Private nCondc
	Private nEL8 := 9
	Private nPosBox := 20
	Private aAreaSC6 := SC6->(GetArea())
	Private cPed
	Private nTopoIt := 230
	Private cDesc
	
	Private cFrom
	Private cTo
	Private cCC
	Private cSubject
	Private cMsg
	Private cAttach
	Private cPedido
	Private cNFor := ""

	Private nValICM := 0
	Private nValIPI := 0
	Private nTOTICM := 0
	Private nTOTIPI := 0
	 
	Private nValSOL := 0
	Private nTOTSOL := 0
	Private nPrcUniSol := 0
	
	Private nValFrete := 0
	Private nTotal := 0
	Private nQtdOpc := 0
	Private aItens := {}
	Private aItAux := {}
	Private aItEst := {}
	Private oPrinter
	Private nPaginas := 0
	Private nPasso1 := 0
	Private nPasso2 := 0
	Private lnoItens := .F.
	
	Private cDir := "C:\PEDIDO\"
	Private cNCli := ""
	Private cPedido := SC5->C5_NUM
	
	//cPedido := SC5->C5_NUM
	//cPedido := "000004"
	
	dbSelectArea("SC6")
	SC6->(dbsetorder(1))
	SC6->(dbseek(xFilial("SC6")+cPedido))
	
	If !(SC5->C5_TIPO='D' .OR. SC5->C5_TIPO='B')
		
		dbSelectArea("SA1")
		SA1->(dbsetorder(1))
		SA1->(dbseek(xFilial("SA1")+SC6->C6_CLI+SC6->C6_LOJA))
		cNCli := strtran(alltrim(substr(SA1->A1_NOME,1,15)),".","_")
		cNomeRel := ALLTRIM(SC6->C6_NUM)+"_"+cNCli+".pdf"
		
	Else
		dbSelectArea("SA2")
		SA2->(dbsetorder(1))
		SA2->(dbseek(xFilial("SA2")+SC6->C6_CLI+SC6->C6_LOJA))
		cNCli := strtran(alltrim(substr(SA2->A2_NOME,1,15)),".","_")
		cNomeRel := ALLTRIM(SC6->C6_NUM)+"_"+cNCli+".pdf"
		
	EndIf
	
	oFont7  	:= TFont():New("Arial",9,7 ,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont8  	:= TFont():New("Arial",9,8 ,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont82  	:= TFont():New("Arial",9,8 ,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont09 	:= TFont():New("Arial",9,9,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont10 	:= TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont10n 	:= TFont():New("Arial",9,10,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont14		:= TFont():New("Arial",9,14,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont14n	:= TFont():New("Arial",9,13,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont16 	:= TFont():New("Arial",9,16,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont16n	:= TFont():New("Arial",9,16,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont20		:= TFont():New("Arial",9,20,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont24 	:= TFont():New("Arial",9,24,.T.,.T.,5,.T.,5,.T.,.F.)
	
	//Definição de objetos
	oPrinter := FWMSPrinter():New(cNomeRel, IMP_PDF, lAdjustToLegacy, , lDisableSetup,,@oPrinter,,.T.,,,.F.)
	//oBrush1 := TBrush():New( , CLR_GRAY)
	oBrush1 := TBrush():New( ,RGB(211,211,211)) //RGB(173,216,230)
	
	MakeDir(cDir)
	
	// Parametrização página
	oPrinter:SetResolution(72)
	oPrinter:SetPortrait()
	oPrinter:SetPaperSize(DMPAPER_A4)
	oPrinter:SetMargin(60,60,60,60)
	oPrinter:SetViewPDF(.F.)
	oPrinter:cPathPDF := cDir
	
	// Adiciona dados e funÃ§Ã£o para inÃ­cio dos cÃ¡lculos referentes aos impostos
	MaFisIni(SC6->C6_CLI,;               	// 1-Codigo Cliente/Fornecedor
	SC6->C6_LOJA,;                         	// 2-Loja do Cliente/Fornecedor
	"C",;                         		// 3-C:Cliente , F:Fornecedor
	"N",;                         		// 4-Tipo da NF
	If(SC5->C5_TIPO='D' .OR. SC5->C5_TIPO='B',SA2->A2_TIPO,SA1->A1_TIPO),;                      // 5-Tipo do Cliente/Fornecedor
		,;   								// 6-Relacao de Impostos que suportados no arquivo
		,;                               	// 7-Tipo de complemento
		,;                               	// 8-Permite Incluir Impostos no Rodape .T./.F.
		"SB1",;               				// 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
		"MATA410")
		
		
		DbSelectArea("SC6")
		Dbsetorder(1)
		DbSeek(xFilial("SC6")+cPedido)
		
		While !SC6->(Eof()) .and. SC6->C6_NUM == cPedido
			
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+SC6->C6_PRODUTO))
			cDesc := alltrim(SB1->B1_DESC) //Alltrim(SC6->C6_PRODUTO)+" - "+alltrim(SB1->B1_DESC)
			
			// Adiciona itens a funÃ§Ã£o de cÃ¡lculo de impostos para impressÃ£o
			_nitem  := MaFisAdd(SB1->B1_COD,SC6->C6_TES, SC6->C6_QTDVEN, SC6->C6_PRCVEN, 0, "", "",, 0, 0, 0, 0, SC6->C6_VALOR, 0)
			
			nValIPI := MaFisRet(_nitem,"IT_VALIPI")
			nValICM := MaFisRet(_nitem,"IT_VALICM")
			//nValSOL := MaFisRet(_nitem,"IT_VALSOL")
			nValSol    := MaFisRet(_nitem, "IT_VALSOL")
			
			//				01				02						03					04			05			06				07            08	 	   09			10
			aadd(aItens,{SC6->C6_ITEM,Alltrim(SC6->C6_PRODUTO),alltrim(SB1->B1_DESC),SC6->C6_UM,SC6->C6_QTDVEN,SC6->C6_PRCVEN,SC6->C6_VALOR,nValIPI, SC6->C6_ENTREG, SC6->C6_OPC,nValSOL}) //,SC7->C7_VALIPI,SC7->C7_DATPRF})
			
			nTOTICM := nTOTICM + nValICM
			nTOTIPI := nTOTIPI + nValIPI
		
			nTotal := 	nTotal	+	SC6->C6_VALOR
			
			//nTOTSOL := nTOTSOL + nValSOL
			
			nTOTSOL  += nValSol
			
   
   
			If !Empty(nValSol)
				nValSol := Round( nValSol / SC6->C6_QTDVEN,2)
			Endif
			
			
			
   
   
			SC6->(dbSkip())
		End
		
		MaFisEnd()
		
		RestArea(aAreaSC6)
		
		If Len(aItens) <= 34
			nPaginas := 1
		Else
			nPasso1  := (Len(aItens) - Mod(Len(aItens),60))/60
			nPasso2  := Mod(Len(aItens),60)
			nPaginas := nPasso1
			If nPasso2 <= 34
				nPaginas += 1
			Else
				nPaginas += 2
				lnoItens := .T.
			Endif
		Endif
		
		For y := 1 to nPaginas
			
			new_cabec("PV")
			
			nConta := 0
			
			//Itens do Pedido
			nIt := 240 //160
			
			//If Len(aItens) < 40
			If y == nPaginas
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+nIt+350, nDireita, "-4")
				
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+nIt+350, nDireita, "-4")
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+nIt+350, 512, "-4")
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+nIt+350, 465, "-4")
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+nIt+350, 415, "-4")
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+nIt+350, 350, "-4")
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+nIt+350, 300, "-4")
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+nIt+350, 280, "-4")
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+nIt+350, 26, "-4")
				
			Else
				
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+740, nDireita, "-4")
				
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+740, nDireita, "-4")
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+740, 512, "-4")
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+740, 465, "-4")
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+740, 415, "-4")
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+740, 350, "-4")
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+740, 300, "-4")
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+740, 280, "-4")
				oPrinter:Box( nTopoBox+nIt, nEsquerda, nFimBox+740, 26, "-4")
				
			Endif
			
			
			oPrinter:Fillrect( {nTopoBox+nIt, nEsquerda, nFimBox-60+nIt, nDireita }, oBrush1, "-4")
			oPrinter:SayAlign( nTopoBox+nIt+3,nEsquerda+3,"Itens do Pedido",oFont8,nDireita-nEsquerda, 30, CLR_BLACK, 2, 0 )
			
			oPrinter:Box(  nTopoBox+nIt+nPosBox+nEL8-14, nEsquerda, nTopoBox+nIt+nPosBox+nEL8-1,  nDireita, "-4")
			oPrinter:Box(  nTopoBox+nIt+nPosBox+nEL8-14, nEsquerda, nTopoBox+nIt+nPosBox+nEL8-1,  512, "-4")
			oPrinter:Box(  nTopoBox+nIt+nPosBox+nEL8-14, nEsquerda, nTopoBox+nIt+nPosBox+nEL8-1,  465, "-4")
			oPrinter:Box(  nTopoBox+nIt+nPosBox+nEL8-14, nEsquerda, nTopoBox+nIt+nPosBox+nEL8-1,  415, "-4")
			oPrinter:Box(  nTopoBox+nIt+nPosBox+nEL8-14, nEsquerda, nTopoBox+nIt+nPosBox+nEL8-1,  350, "-4")
			oPrinter:Box(  nTopoBox+nIt+nPosBox+nEL8-14, nEsquerda, nTopoBox+nIt+nPosBox+nEL8-1,  300, "-4")
			oPrinter:Box(  nTopoBox+nIt+nPosBox+nEL8-14, nEsquerda, nTopoBox+nIt+nPosBox+nEL8-1,  280, "-4")
			oPrinter:Box(  nTopoBox+nIt+nPosBox+nEL8-14, nEsquerda, nTopoBox+nIt+nPosBox+nEL8-1,  26, "-4")
			
			oPrinter:Say( nTopoBox+nIt+nPosBox+nEL8-4,nEsquerda+3,"Item",oFont82)
			oPrinter:Say( nTopoBox+nIt+nPosBox+nEL8-4,nEsquerda+25,"Produto",oFont82)
			oPrinter:Say( nTopoBox+nIt+nPosBox+nEL8-4,nEsquerda+280,"UM",oFont82)
			oPrinter:Say( nTopoBox+nIt+nPosBox+nEL8-4,nEsquerda+300,"Qtde.",oFont82)
			oPrinter:Say( nTopoBox+nIt+nPosBox+nEL8-4,nEsquerda+350,"Vlr.Unit.",oFont82)
			oPrinter:Say( nTopoBox+nIt+nPosBox+nEL8-4,nEsquerda+415,"Vlr.Total",oFont82)
			oPrinter:Say( nTopoBox+nIt+nPosBox+nEL8-4,nEsquerda+465,"IPI",oFont82)
			oPrinter:Say( nTopoBox+nIt+nPosBox+nEL8-4,nEsquerda+512,"Dt. Entrega",oFont82)
			
			//aAreaSC7 := GetArea()
			
			For x := iif(y == 1,1,((y-1)*60)+1) to Iif(y*60 > Len(aItens), Len(aItens), y*60)
				nConta ++
				If !Empty(aItens[x,1])
					oPrinter:Say( (nTopoBox+nIt+nPosBox+nEL8+nEL8-4)+(nEL8*nConta)-4,nEsquerda+3,aItens[x,1],oFont82)
				Endif
				
				oPrinter:Say( (nTopoBox+nIt+nPosBox+nEL8+nEL8-4)+(nEL8*nConta)-4,nEsquerda+25,AllTrim(aItens[x,2])+If(aItens[x,1]<>""," / ","")+Substr(AllTrim(aItens[x,3]),1,45),oFont82)
				
				If !Empty(aItens[x,3])
					
					//oPrinter:Say( (nTopoBox+nIt+nPosBox+nEL8+nEL8-4)+(nEL8*nConta)-4,nEsquerda+280,aItens[x,3],oFont82)
					oPrinter:Say( (nTopoBox+nIt+nPosBox+nEL8+nEL8-4)+(nEL8*nConta)-4,nEsquerda+280,aItens[x,4],oFont82)
					oPrinter:Say( (nTopoBox+nIt+nPosBox+nEL8+nEL8-4)+(nEL8*nConta)-4,nEsquerda+300,Transform(aItens[x,5],"@E 999.999999"),oFont82)
					oPrinter:Say( (nTopoBox+nIt+nPosBox+nEL8+nEL8-4)+(nEL8*nConta)-4,nEsquerda+350,Transform(aItens[x,6],"@E 999,999.99999999"),oFont82)
					oPrinter:Say( (nTopoBox+nIt+nPosBox+nEL8+nEL8-4)+(nEL8*nConta)-4,nEsquerda+422,Transform(aItens[x,7],"@E 999,999.99"),oFont82)
					oPrinter:Say( (nTopoBox+nIt+nPosBox+nEL8+nEL8-4)+(nEL8*nConta)-4,nEsquerda+470,Transform(aItens[x,8],"@E 999,999.99"),oFont82)
					oPrinter:Say( (nTopoBox+nIt+nPosBox+nEL8+nEL8-4)+(nEL8*nConta)-4,nEsquerda+510,dToc(aItens[x,9]),oFont82)
					
				Endif
				
			Next x
			
			If y == nPaginas
				new_rodape()
			Endif
			
		Next y
		
		
		oPrinter:Print()
		
		If MsgYesNo("Deseja visualizar o Pedido ?","Visualizar")
			ShellExecute("open", oPrinter:cPathPDF+cNomeRel, "", "", SW_SHOWNORMAL )
		EndIf
		
		If MsgYesNo("Deseja enviar o Pedido por e-mail para o Cliente?","Envio de e-mail")
			
			cMsg := ""
			cMsg += "<html lang='en'> "
			cMsg += "<!DOCTYPE html>"
			cMsg += "  <body>"
			cMsg += "  <p></p>"
			cMsg += "  <p></p>"
			cMsg += "  <p>Pedido de Venda anexo. </p>"
			cMsg += "  <p></p>"
			cMsg += "  </body>"
			cMsg += "</html>"
			
			cFrom := GETMV("MV_RELFROM")
			//cTo := ALLTRIM("sidinei.nascimento@totvs.com.br")
			//cTo := ALLTRIM("financeiro@cekacessorios.com.br")
			cTo := If(!(SC5->C5_TIPO='D' .OR. SC5->C5_TIPO='B'),ALLTRIM(SA1->A1_EMAIL),ALLTRIM(SA2->A2_EMAIL))
			cSubject := "C&K - Pedido de Venda n.: "+ cPedido
			cCC := ""
			cAttach := ""
			
			CpyT2S( oPrinter:cPathPDF+cNomeRel, "\temp\" )
			
			//cAttach := "D:\pedidos de compra\"+cPedido+".pdf"
			//cAttach := "\temp\"+ALLTRIM(cPedido)+"_"+cNCli+".pdf"
			cAttach := "\temp\"+cNomeRel
			
			U_OpenSendMail(cFrom, cTo, cCC, cSubject, cMsg, cAttach)
			
			FERASE("\temp\"+cNomeRel)
			
		Endif
		
		TExcel()
		
		Return()
		
		/*
		ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
		±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
		±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
		±±³Fun‡…o    ³ new_cabec ³ Autor ³ Jaylson Ribeiro     ³ Data ³ 01/09/15  ³±±
		±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
		±±³Descri‡…o ³ Cabeçalho Pedido de Venda                                  ³±±
		±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
		±±³ Uso      ³ Alteração: 16/05/2016 - Peterson J. Savi                   ³±±
		±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
		±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
		*/
	Static Function new_cabec(cTp)
		Local nCount
		Local cQry := ""
		
		dbSelectArea("SC5")
		SC5->(dbsetorder(1))
		SC5->(dbseek(xFilial("SC5")+cPedido))
		
		dbSelectArea("SC6")
		SC6->(dbsetorder(1))
		SC6->(dbseek(xFilial("SC6")+cPedido))
		
		// Inicio dos projetos
		oPrinter:StartPage()
		//Cabeçalho
		oPrinter:Box( nTopoBox, nEsquerda, nFimBox, nDireita, "-4")
		oPrinter:SayBitmap(26,8,cBmp,120,72)
		
		oPrinter:Say(65,220,IIf(cTp="PV","PEDIDO DE VENDA: ","PICK LIST: ")+cPedido,oFont14)
		oPrinter:Say(75,230,"Data de Emissão: "+DTOC(SC5->C5_EMISSAO),oFont7)
		
		//Dados do Cliente
		If !(SC5->C5_TIPO='D' .OR. SC5->C5_TIPO='B')
			dbSelectArea("SA1")
			SA1->(dbsetorder(1))
			SA1->(dbseek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
			
			oPrinter:Box( nTopoBox+80, nEsquerda, nFimBox+80, nDireita, "-4")
			oPrinter:Fillrect( {nTopoBox+80, nEsquerda, nFimBox-60+80, nDireita }, oBrush1, "-4")
			oPrinter:SayAlign( nTopoBox+80+3,nEsquerda+3,"Dados do Cliente",oFont8,nDireita-nEsquerda, 30, CLR_BLACK, 2, 0 )
			oPrinter:Say( nTopoBox+80+nPosBox+nEL8,nEsquerda+3,"Cliente: "+Alltrim(SA1->A1_COD)+" - "+Substr(ALLTRIM(SA1->A1_NOME),1,62),oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+nEL8,350,"CNPJ: ",oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+nEL8,400,Transform(SA1->A1_CGC,"@R 99.999.999/9999-99"),oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*2),nEsquerda+3,"Endereço: "+ALLTRIM(SA1->A1_END),oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*2),350,"I.E.: ",oFont82)
			
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*2),400,ALLTRIM(SA1->A1_INSCR),oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*3),nEsquerda+3,"Bairro: "+ALLTRIM(SA1->A1_BAIRRO),oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*3),180,"Município/UF: "+ALLTRIM(SA1->A1_MUN)+"/"+SA1->A1_EST,oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*3),350,"CEP: ",oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*3),400,Transform(SA1->A1_CEP,"@R 99.999-999"),oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*4),nEsquerda+3,"Telefone: "+"("+Alltrim(SA1->A1_DDD)+") "+Transform(Alltrim(SA1->A1_TEL),"@R 9999-9999"),oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*4),180,"E-mail: "+"("+Alltrim(SA1->A1_EMAIL)+")",oFont82)
			//oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*4),180,"Fax: "+"("+Alltrim(SA1->A1_DDD)+") "+Transform(Alltrim(SA1->A1_FAX),"@R 9999-9999"),oFont82)
			
			If cTp = "PL"
				oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*5),nEsquerda+3,"Data Entrega: "+DTOC(dDatabase),oFont82)
				oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*5),180,"Orçamento: "+SC6->C6_NUMORC,oFont82)
				oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*6),nEsquerda+3,"Vendedor: "+SC5->C5_VEND1 +" - "+ Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_NOME"),oFont82)
				
			Else
				oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*5),nEsquerda+3,"Orçamento: "+SC6->C6_NUMORC,oFont82)
				oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*5),180,"Vendedor: "+SC5->C5_VEND1 +" - "+ Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_NOME"),oFont82)
			EndIf
			
			//Dados de Entrega
			cQry += " SELECT A1_COD, A1_LOJA, A1_NOME, A1_END, A1_BAIRRO, A1_EST, A1_MUN, A1_CEP, A1_CGC, A1_INSCR, A1_DDD, A1_FAX, A1_TEL, "
			cQry += " A1_ENDENT, A1_BAIRROE, A1_CEPE, A1_MUNE, A1_ESTE "
			cQry += " FROM "+RetSqlName("SA1")+" SA1 "
			cQry += " WHERE SA1.A1_FILIAL = '"+xFilial("SA1")+"' "
			cQry += " AND SA1.A1_COD = '"+SC5->C5_CLIENT+"' "
			cQry += " AND SA1.A1_LOJA = '"+SC5->C5_LOJAENT+"' "
			cQry += " AND SA1.D_E_L_E_T_ <> '*' "
			cQry := ChangeQuery(cQry)
			
			If Select("QRY") <> 0
				QRY->(dbCloseArea())
			Endif
			
			TCQuery cQry Alias QRY New
			
			oPrinter:Box( nTopoBox+160, nEsquerda, nFimBox+160, nDireita, "-4")
			oPrinter:Fillrect( {nTopoBox+160, nEsquerda, nFimBox-60+160, nDireita }, oBrush1, "-4")
			oPrinter:SayAlign( nTopoBox+160+3,nEsquerda+3,"Dados de Entrega",oFont8,nDireita-nEsquerda, 30, CLR_BLACK, 2, 0 )
			oPrinter:Say( nTopoBox+160+nPosBox+nEL8,nEsquerda+3,"Cliente: "+Alltrim(QRY->A1_COD)+" - "+Substr(Alltrim(QRY->A1_NOME),1,62),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+nEL8,350,"CNPJ: ",oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+nEL8,400,Transform(QRY->A1_CGC,"@R 99.999.999/9999-99"),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*2),nEsquerda+3,"Endereço: "+IIF(!EMPTY(QRY->A1_ENDENT),ALLTRIM(QRY->A1_ENDENT),ALLTRIM(QRY->A1_END)),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*2),350,"I.E.: ",oFont82)
			
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*2),400,ALLTRIM(QRY->A1_INSCR),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*3),nEsquerda+3,"Bairro: "+IIF(!EMPTY(QRY->A1_BAIRROE),ALLTRIM(QRY->A1_BAIRROE),ALLTRIM(QRY->A1_BAIRRO)),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*3),180,"Município/UF: "+IIF(!EMPTY(QRY->A1_MUNE),ALLTRIM(QRY->A1_MUNE),ALLTRIM(QRY->A1_MUN))+"/"+IIF(!EMPTY(QRY->A1_ESTE),ALLTRIM(QRY->A1_ESTE),ALLTRIM(QRY->A1_EST)),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*3),350,"CEP: ",oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*4),350,"Trasportadora: "+SC5->C5_TRANSP +" - "+ Posicione("SA4",1,xFilial("SA4")+SC5->C5_TRANSP,"A4_NOME"),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*3),400,IIF(!EMPTY(QRY->A1_CEPE),Transform(QRY->A1_CEPE,"@R 99.999-999"),Transform(QRY->A1_CEP,"@R 99.999-999")),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*4),nEsquerda+3,"Telefone: "+"("+Alltrim(QRY->A1_DDD)+") "+Transform(Alltrim(QRY->A1_TEL),"@R 9999-9999"),oFont82)
			
			//-- Valida tipo de frete//
			If SC5->C5_TPFRETE == "C"
				cTip:= "CIF"
			Elseif SC5->C5_TPFRETE == "F"
				cTip:= "FOB"
			Else
				cTip:="SEM FRETE"
			Endif
			
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*4),180,"Tipo Frete: "+"("+Alltrim(cTip)+") ",oFont82)
			//oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*4),180,"Fax: "+"("+Alltrim(QRY->A1_DDD)+") "+Transform(Alltrim(QRY->A1_FAX),"@R 9999-9999"),oFont82)
			If cTp = "PL"
				oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*5),nEsquerda+3,"Data Entrega: "+DTOC(dDatabase),oFont82)
			EndIf
			
		Else
			dbSelectArea("SA2")
			SA2->(dbsetorder(1))
			SA2->(dbseek(xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
			
			
			If SF2->F2_TPFRETE = "C"
				cTip:= "CIF"
			Elseif SF2->F2_TPFRETE = "F"
				cTip:= "FOB"
			Else
				cTip:="SEM FRETE"
			Endif
			
			oPrinter:Box( nTopoBox+80, nEsquerda, nFimBox+80, nDireita, "-4")
			oPrinter:Fillrect( {nTopoBox+80, nEsquerda, nFimBox-60+80, nDireita }, oBrush1, "-4")
			oPrinter:SayAlign( nTopoBox+80+3,nEsquerda+3,"Dados do Cliente",oFont8,nDireita-nEsquerda, 30, CLR_BLACK, 2, 0 )
			oPrinter:Say( nTopoBox+80+nPosBox+nEL8,nEsquerda+3,"Cliente: "+Alltrim(SA2->A2_COD)+" - "+Substr(ALLTRIM(SA2->A2_NOME),1,62),oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+nEL8,350,"CNPJ: ",oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+nEL8,400,Transform(SA2->A2_CGC,"@R 99.999.999/9999-99"),oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*2),nEsquerda+3,"Endereço: "+ALLTRIM(SA2->A2_END),oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*2),350,"I.E.: ",oFont82)
			
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*2),400,ALLTRIM(SA2->A2_INSCR),oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*3),nEsquerda+3,"Bairro: "+ALLTRIM(SA2->A2_BAIRRO),oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*3),180,"Município/UF: "+ALLTRIM(SA2->A2_MUN)+"/"+SA2->A2_EST,oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*3),350,"CEP: ",oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*3),400,Transform(SA2->A2_CEP,"@R 99.999-999"),oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*4),nEsquerda+3,"Telefone: "+"("+Alltrim(SA2->A2_DDD)+") "+Transform(Alltrim(SA2->A2_TEL),"@R 9999-9999"),oFont82)
			oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*4),180,"E-mail: "+"("+Alltrim(SA2->A2_EMAIL)+") ",oFont82)
			
			If cTp = "PL"
				oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*5),nEsquerda+3,"Data Entrega: "+DTOC(dDatabase),oFont82)
				oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*5),180,"Orçamento: "+SC6->C6_NUMORC,oFont82)
				oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*6),nEsquerda+3,"Transportadora: "+SC5->C5_TRANSP +" - "+ Posicione("SA4",1,xFilial("SA4")+SC5->C5_TRANSP,"A4_NOME"),oFont82)
			Else
				oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*5),nEsquerda+3,"Orçamento: "+SC6->C6_NUMORC,oFont82)
				oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*5),180,"Transportadora: "+SC5->C5_TRANSP +" - "+ Posicione("SA4",1,xFilial("SA4")+SC5->C5_TRANSP,"A4_NOME"),oFont82)
			EndIf
			
			//Dados de Entrega
			cQry += " SELECT A2_COD, A2_LOJA, A2_NOME, A2_END, A2_BAIRRO, A2_EST, "
			cQry += " A2_MUN, A2_CEP, A2_CGC,A2_INSCR, A2_DDD, A2_FAX, A2_TEL "
			cQry += " FROM "+RetSqlName("SA2")+" SA2 "
			cQry += " WHERE SA2.A2_FILIAL = '"+xFilial("SA2")+"' "
			cQry += " AND SA2.A2_COD = '"+SC5->C5_CLIENT+"' "
			cQry += " AND SA2.A2_LOJA = '"+SC5->C5_LOJAENT+"' "
			cQry += " AND SA2.D_E_L_E_T_ <> '*' "
			
			
			cQry := ChangeQuery(cQry)
			
			If Select("QRY") <> 0
				QRY->(dbCloseArea())
			Endif
			
			TCQuery cQry Alias QRY New
			
			
			
			
			oPrinter:Box( nTopoBox+160, nEsquerda, nFimBox+160, nDireita, "-4")
			oPrinter:Fillrect( {nTopoBox+160, nEsquerda, nFimBox-60+160, nDireita }, oBrush1, "-4")
			oPrinter:SayAlign( nTopoBox+160+3,nEsquerda+3,"Dados de Entrega",oFont8,nDireita-nEsquerda, 30, CLR_BLACK, 2, 0 )
			oPrinter:Say( nTopoBox+160+nPosBox+nEL8,nEsquerda+3,"Cliente: "+Alltrim(QRY->A2_COD)+" - "+Substr(ALLTRIM(QRY->A2_NOME),1,62),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+nEL8,350,"CNPJ: ",oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+nEL8,400,Transform(QRY->A2_CGC,"@R 99.999.999/9999-99"),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*2),nEsquerda+3,"Endereço: "+ALLTRIM(QRY->A2_END),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*2),350,"I.E.: ",oFont82)
			
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*2),400,ALLTRIM(QRY->A2_INSCR),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*3),nEsquerda+3,"Bairro: "+ALLTRIM(QRY->A2_BAIRRO),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*3),180,"Município/UF: "+ALLTRIM(QRY->A2_MUN)+"/"+ALLTRIM(QRY->A2_EST),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*3),350,"CEP: ",oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*3),400,Transform(QRY->A2_CEP,"@R 99.999-999"),oFont82)
			oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*4),nEsquerda+3,"Telefone: "+"("+Alltrim(QRY->A2_DDD)+") "+Transform(Alltrim(QRY->A2_TEL),"@R 9999-9999"),oFont82)
		    oPrinter:Say( nTopoBox+160+nPosBox+(nEL8*4),180,"Tipo Frete: "+"("+ Alltrim(cTip) + ") ",oFont82)
			If cTp = "PL"
				oPrinter:Say( nTopoBox+80+nPosBox+(nEL8*5),nEsquerda+3,"Data Entrega: "+DTOC(dDatabase),oFont82)
			EndIf
			
		EndIf
		
		
		
		Return()
		
		/*
		ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
		±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
		±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
		±±³Fun‡…o    ³ new_rodape ³ Autor ³ Jaylson Ribeiro    ³ Data ³ 01/09/15  ³±±
		±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
		±±³Descri‡…o ³ Rodape Pedido de Venda                                     ³±±
		±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
		±±³ Uso      ³ Alteração: 16/05/2016 - Peterson J. Savi                   ³±±
		±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
		±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
		*/
	Static Function new_rodape()
		
		Local m
		Private aAreaSC5 := SC5->(GetArea())
		
		dbSelectArea("SC5")
		SC5->(dbsetorder(1))
		SC5->(dbseek(xFilial("SC5")+cPedido))
		
		dbSelectArea("SC6")
		SC6->(dbsetorder(1))
		SC6->(dbseek(xFilial("SC6")+cPedido))
		
		nValFrete := SC5->C5_FRETE
		
		//Totais do Pedido
		nTot := 590
		oPrinter:Box( nTopoBox+nTot, nMeio, nFimBox+nTot, nDireita, "-4")
		oPrinter:Fillrect( {nTopoBox+nTot, nMeio, nFimBox-60+nTot, nDireita }, oBrush1, "-4")
		oPrinter:SayAlign( nTopoBox+nTot+3,nMeio+3,"Totais do Pedido",oFont8,nDireita-nMeio, 30, CLR_BLACK, 2, 0 )
		oPrinter:Say( nTopoBox+nTot+nPosBox+nEL8-6,nMeio+083,"Valor Mercadorias: ",oFont82)
		oPrinter:Say( nTopoBox+nTot+nPosBox+nEL8-6,nMeio+160,Transform(nTotal,"@E 9,999,999.99"),oFont82)
		oPrinter:Say( nTopoBox+nTot+nPosBox+(nEL8*1.5),nMeio+083,"Valor ICMS: ",oFont82)
		oPrinter:Say( nTopoBox+nTot+nPosBox+(nEL8*1.5),nMeio+160,Transform(nTOTICM,"@E 9,999,999.99"),oFont82)
		oPrinter:Say( nTopoBox+nTot+nPosBox+(nEL8*2.5),nMeio+083,"Valor ICMS-ST: ",oFont82)
		oPrinter:Say( nTopoBox+nTot+nPosBox+(nEL8*2.5),nMeio+160,Transform(nTOTSOL,"@E 9,999,999.99"),oFont82)
		oPrinter:Say( nTopoBox+nTot+nPosBox+(nEL8*3.5),nMeio+083,"Valor IPI: ",oFont82)
		oPrinter:Say( nTopoBox+nTot+nPosBox+(nEL8*3.5),nMeio+160,Transform(nTOTIPI,"@E 9,999,999.99"),oFont82)
		oPrinter:Say( nTopoBox+nTot+nPosBox+(nEL8*4.5),nMeio+083,"Valor Frete: ",oFont82)
		oPrinter:Say( nTopoBox+nTot+nPosBox+(nEL8*4.5),nMeio+160,Transform(nValFrete,"@E 9,999,999.99"),oFont82)
		oPrinter:Say( nTopoBox+nTot+nPosBox+(nEL8*5.5),nMeio+083,"Valor Total: ",oFont8)
		oPrinter:Say( nTopoBox+nTot+nPosBox+(nEL8*5.5),nMeio+160,Transform(nValFrete+nTOTSOL+nTOTIPI+nTotal,"@E 9,999,999.99"),oFont8)
		
		//Condições de Pagamento e Transporte
		nCondp := 670
		oPrinter:Box( nTopoBox+nCondp, nMeio, nFimBox+nCondp, nDireita, "-4")
		oPrinter:Fillrect( {nTopoBox+nCondp, nMeio, nFimBox-60+nCondp, nDireita }, oBrush1, "-4")
		oPrinter:SayAlign( nTopoBox+nCondp+3,nMeio+3,"Condições de Pagamento",oFont8,nDireita-nMeio, 30, CLR_BLACK, 2, 0 )
		
		dbSelectArea("SE4")
		SE4->(dbsetorder(1))
		SE4->(dbseek(xFilial("SE4")+SC5->C5_CONDPAG))
		oPrinter:Say( nTopoBox+nCondp+nPosBox+nEL8,nMeio+3,"Condição de Pagamento: "+ALLTRIM(SE4->E4_DESCRI),oFont82)
		
		//Condições Comerciais de Fornecimento Fixas
		nCondc := 740
		oPrinter:Box( nTopoBox+nCondc, nMeio, nFimBox+nCondc, nDireita, "-4")
		oPrinter:Fillrect( {nTopoBox+nCondc, nMeio, nFimBox-60+nCondc, nDireita }, oBrush1, "-4")
		oPrinter:SayAlign( nTopoBox+nCondc+3,nMeio+3,"Informações Comerciais",oFont8,nDireita-nMeio, 30, CLR_BLACK, 2, 0 )
		oPrinter:Say(nTopoBox+nCondc+nPosBox+nEL8-2,nMeio+3,SM0->M0_NOMECOM,oFont7)
		oPrinter:Say(nTopoBox+nCondc+nPosBox+(nEL8*2)-2,nMeio+3,ALLTRIM(SM0->M0_ENDCOB)+" - Bairro: "+Alltrim(SM0->M0_BAIRCOB),oFont7)
		oPrinter:Say(nTopoBox+nCondc+nPosBox+(nEL8*3)-2,nMeio+3,ALLTRIM(SM0->M0_CIDCOB)+" - "+SM0->M0_ESTCOB+"  -  "+"Telefone: "+SM0->M0_TEL,oFont7)
		oPrinter:Say(nTopoBox+nCondc+nPosBox+(nEL8*4)-2,nMeio+3,"CNPJ: "+Transform(SM0->M0_CGC,"@R 99.999.999/9999-99")+" - Insc. Est.: "+SM0->M0_INSC,oFont7)
		oPrinter:Say(nTopoBox+nCondc+nPosBox+(nEL8*5)-2,nMeio+3,"E-mail: comercial@cekacessorios.com.br",oFont7)
		oPrinter:Say(nTopoBox+nCondc+nPosBox+(nEL8*6)-2,nMeio+3,"Site: www.cekacessorios.com.br",oFont7)
		
		
		
		
		//Observações do Pedido
		oPrinter:Box( nTopoBox+nTot, nEsquerda, nFimBox+nCondc, nMeio-3, "-4")
		oPrinter:Fillrect( {nTopoBox+nTot, nEsquerda, nFimBox-60+nTot, nMeio-3 }, oBrush1, "-4")
		oPrinter:SayAlign( nTopoBox+nTot+3,nEsquerda+3,"Observações do Pedido",oFont8,nMeio-nEsquerda-3, 30, CLR_BLACK, 2, 0 )
		
		
		cObs := Alltrim(SC5->C5_XOBS)
		aString := FWTxt2Array(cObs ,62)
		
		nCondc := 540
		
		For a = 1 to len(aString)
			
			// oPrinter:Say( nLinFim,2,aString[a],oFont82)
			oPrinter:Say(nTopoBox+nCondc+nPosBox+(nEL8*6)-2,nEsquerda+3,aString[a],oFont7)
			
			nCondc += 10
		next a
		//oPrinter:Say(nTopoBox+nCondc+nPosBox+(nEL8*6)-2,nEsquerda+3,"Site: www.cekacessorios.com.br",oFont7)
		
		nCondc += 10
		oPrinter:Say(nTopoBox+nCondc+nPosBox+(nEL8*6)-2,nEsquerda+3,"Volume: "+ TRANSFORM(SC5->C5_VOLUME1,"99999"),oFont7)
		nCondc += 10
		oPrinter:Say(nTopoBox+nCondc+nPosBox+(nEL8*6)-2,nEsquerda+3,"Especie: "+ Alltrim(SC5->C5_ESPECI1),oFont7)
		nCondc += 10
		oPrinter:Say(nTopoBox+nCondc+nPosBox+(nEL8*6)-2,nEsquerda+3,"Peso Bruto: "+TRANSFORM(SC5->C5_PBRUTO,"@E 999,999.9999"),oFont7)
		
		
		//cObs := MSMM(SC5->C5_INFPV,80,,"",3,,,"SC5","C5_INFPV")
		//cObs := SC5->C5_INFPV //MSMM(SC5->C5_INFPV,,,,3)
		//cObs := ""
		
		
		oPrinter:EndPage()
		RestArea(aAreaSC5)
		
		Return()
		
		
		
	Static Function TExcel()
		
		
  
		Local oExcel
		Local cArq
		Local nArq
		Local cPath
		
		//If !ApOleClient("MSExcel")
		//	MsgAlert("Microsoft Excel não instalado!")
		//	Return
		//EndIf
		
		cArq := CriaTrab(Nil, .F.)
		//cPath := GetSrvProfString("ROOTPATH", "C:\MP8") + "\DATA\"
		//nArq := FCreate(cPath + cArq + ".CSV")
		
  
		nArq := FCreate(cDir + ALLTRIM(cPedido)+"_"+cNCli+".CSV")
		
		If nArq == -1
			MsgAlert("Nao conseguiu criar o arquivo!")
			Return
		EndIf
		
		//FWrite(nArq, "Codigo;Nome;Endereco" + Chr(13) + Chr(10))
		
		//dbSelectArea("SA1")
		//dbGoTop()
		//While !SA1->(Eof())
		//	FWrite(nArq, SA1->A1_Cod + ";" + SA1->A1_Nome + ";" + SA1->A1_End + Chr(13) + Chr(10))
		//	SA1->(dbSkip())
		//End
		
		
		For _x := 1 To Len(aItens)
			//aadd(aItens,{SC6->C6_ITEM,Alltrim(SC6->C6_PRODUTO),alltrim(SB1->B1_DESC),SC6->C6_UM,SC6->C6_QTDVEN,SC6->C6_PRCVEN,SC6->C6_VALOR,nValIPI, SC6->C6_ENTREG, SC6->C6_OPC,nValSOL}) //,SC7->C7_VALIPI,SC7->C7_DATPRF})
			//FWrite(nArq, aItens[_x,1]+";"+aItens[_x,2]+"/"+aItens[_x,3]+";"+aItens[_x,4]+";"+AllTrim(Str(aItens[_x,5]))+";"+;
				//AllTrim(Str(aItens[_x,6]))+";"+AllTrim(Str(aItens[_x,7]))  +Chr(13)+Chr(10))
			FWrite(nArq, aItens[_x,1]+";"+aItens[_x,2]+"/"+aItens[_x,3]+";"+aItens[_x,4]+";"+Transform(aItens[_x,5],"@E 999,999.99")+";"+;
				Transform(aItens[_x,6],"@E 999,999.99")+";"+Transform(aItens[_x,7],"@E 999,999.99")  +Chr(13)+Chr(10))
		Next _x
		
		FClose(nArq)
		
		oExcel := MSExcel():New()
		//oExcel:WorkBooks:Open(cPath + cArq + ".CSV")
		//oExcel:WorkBooks:Open("C:\TEMP\AAA.CSV")
		oExcel:SetVisible(.T.)
		oExcel:Destroy()
		
		//FErase(cPath + cArq + ".CSV")
		
		Return
