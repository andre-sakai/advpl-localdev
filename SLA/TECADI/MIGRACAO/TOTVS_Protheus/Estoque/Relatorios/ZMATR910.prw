#INCLUDE "MATR910.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ MATR910  ³ Autor ³ Nereu Humberto Junior ³ Data ³ 11.07.06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Kardex fisico - financeiro                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Kardex Por dia com coluna pedido cliente                !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schumann (SLA Consultoria)  ! Data    ! 07/2018 !
+------------------+---------------------------------------------------------+
!Observacoes       ! Customizaçao do relatório padrão Totvs para exibir a    !
!                  ! coluna customizada "Pedido cliente", pois o relatório   !
!                  ! original não possui seção com vínculo na tabela de      !
!                  ! pedidos de venda                                        !
+------------------+--------------------------------------------------------*/


User Function zMATR910()
Local oReport
If TRepInUse()
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Interface de impressao                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oReport:= ReportDef()
	oReport:PrintDialog()
Else
	U_MATR910R3()
EndIf

Return
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ReportDef ³ Autor ³Nereu Humberto Junior  ³ Data ³11.07.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³A funcao estatica ReportDef devera ser criada para todos os ³±±
±±³          ³relatorios que poderao ser agendados pelo usuario.          ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ExpO1: Objeto do relatorio                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Nenhum                                                      ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ReportDef()

Local oReport 
Local oSection1
Local oSection2
Local oSection3
Local oCell         
Local aOrdem    := {}
Local aSB1Cod   := {}
Local aSB1Ite   := {}
Local aTabelas	:= {"SB2"}
Local cPicB2Tot := PesqPictQt("B2_VATU1",18)
Local cTamB2Tot := TamSX3('B2_VATU1')[1]
Local cPicB2Qt  := PesqPictQt("B2_QATU" ,18)
Local cTamB2Qt  := TamSX3('B2_QATU')[1]
Local cPicB2Cust:= PesqPict("SB2","B2_CM1",18)
Local cTamB2Cust:= TamSX3('B2_CM1')[1]
Local cPicD1Qt  := PesqPict("SD1","D1_QUANT" ,18)
Local cTamD1Qt  := TamSX3('D1_QUANT')[1]
Local cPicD1Cust:= PesqPict("SD1","D1_CUSTO",18)
Local cTamD1Cust:= TamSX3('D1_CUSTO')[1]
Local cPicD2Qt  := PesqPict("SD2","D2_QUANT" ,18)
Local cTamD2Qt  := TamSX3('D2_QUANT')[1]
LOCAL cPicD2Cust:= PesqPict("SD2","D2_CUSTO1",18)
Local cTamD2Cust:= TamSX3('D2_CUSTO1')[1]
Local lVEIC 	:= UPPER(GETMV("MV_VEICULO"))=="S"
Local nTamSX1 	:= Len(SX1->X1_GRUPO)
Local cTamD1CF  := TamSX3('D1_CF')[1]
Local nTamData 	:= IIF(__SetCentury(),10,8)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se utiliza custo unificado por Empresa/Filial       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local lCusUnif := A330CusFil()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Criacao do componente de impressao                                      ³
//³                                                                        ³
//³TReport():New                                                           ³
//³ExpC1 : Nome do relatorio                                               ³
//³ExpC2 : Titulo                                                          ³
//³ExpC3 : Pergunte                                                        ³
//³ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao  ³
//³ExpC5 : Descricao                                                       ³
//³                                                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oReport:= TReport():New("MATR910",STR0003,"MTR910", {|oReport| ReportPrint(oReport,oSection1)},STR0001+" "+STR0002) //"Kardex Fisico-Financeiro (DIA)"##"Este programa emitir  uma rela‡„o com as movimenta‡”es"##"dos produtos Selecionados,Ordenados por Dia."
oReport:SetLandscape()    
oReport:SetTotalInLine(.F.)

Pergunte("MTR910",.F.)

Aadd( aOrdem, STR0004 ) // " Codigo Produto "
Aadd( aOrdem, STR0005 ) // " Tipo do Produto"
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Definicao da Secao 1 - Dados do Produto                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//-- So adiciona SB1 no personalizavel quando nao compartilhado ou sem gestao de empresas
//-- Isto para habilitar o recurso de impressao em N filiais (botao Gestao de Empresas)
If FWModeAccess("SB1",1) == "E" .Or. (At("E",FWSM0Layout()) == 0 .And. At("U",FWSM0Layout()) == 0)
	oSection1 := TRSection():New(oReport,STR0062,{"SB1","SB2"},aOrdem) //"Produto (Parte 1)"
Else
	oSection1 := TRSection():New(oReport,STR0062,{"SB2"},aOrdem) //"Produto (Parte 1)"
EndIf
oSection1 :SetTotalInLine(.F.)
oSection1 :SetReadOnly()
oSection1 :SetLineStyle()

If lVeic
	TRCell():New(oSection1,"B1_CODITE","SB1",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
Endif
TRCell():New(oSection1,"cProduto","   ",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
oSection1:Cell("cProduto"):GetFieldInfo("B1_COD")
TRCell():New(oSection1,"B1_DESC"	,"SB1",/*Titulo*/	,/*Picture*/,30			,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"B1_UM"		,"SB1",STR0056		,/*Picture*/,3			,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"cTipo"		,"   ",STR0057		,"@!"		,3			,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"B1_GRUPO"	,"SB1",STR0058		,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"nCusMed"	,"   ",STR0059		,cPicB2Cust	,cTamB2Cust	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"nQtdSal"	,"   ",STR0054		,cPicB2Qt	,cTamB2Qt	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"nVlrSal"	,"   ",STR0055		,cPicB2Tot	,cTamB2Tot	,/*lPixel*/,/*{|| code-block de impressao }*/)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Definicao da Secao 2 - Cont. dos dados do Produto            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//-- So adiciona SB1 e NNR no personalizavel quando nao compartilhado ou sem gestao de empresas
//-- Isto para habilitar o recurso de impressao em N filiais (botao Gestao de Empresas)
If FWModeAccess("SB1",1) == "E" .Or. (At("E",FWSM0Layout()) == 0 .And. At("U",FWSM0Layout()) == 0)
	aAdd(aTabelas,"SB1")
EndIf
If FWModeAccess("NNR",1) == "E" .Or. (At("E",FWSM0Layout()) == 0 .And. At("U",FWSM0Layout()) == 0)
	aAdd(aTabelas,"NNR")
EndIf

oSection2 := TRSection():New(oSection1,STR0063,aTabelas) //"Produto (Parte 2)"
oSection2 :SetTotalInLine(.F.)
oSection2 :SetReadOnly()
oSection2 :SetLineStyle()

If lVeic
	TRCell():New(oSection2,"cProduto","   ",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	oSection2:Cell("cProduto"):GetFieldInfo("B1_COD")
	TRCell():New(oSection2,"B1_UM"		,"SB1",STR0056,/*Picture*/	,/*Tamanho*/	,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"cTipo"		,"   ",STR0057,"@!"			,2,/*lPixel*/	,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"B1_GRUPO"	,"SB1",STR0058,/*Picture*/	,/*Tamanho*/	,/*lPixel*/,/*{|| code-block de impressao }*/)
Endif	
If cPaisLoc<>"CHI"
	TRCell():New(oSection2,"B1_POSIPI","SB1",STR0060,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| SB1->B1_POSIPI })
Endif	

TRCell():New(oSection2,"NNR_DESCRI","NNR",STR0061,/*Picture*/,/*Tamanho*/,/*lPixel*/, {|| If(lCusUnif , MV_PAR08 , Posicione("NNR",1,xFilial("NNR")+MV_PAR08,"NNR_DESCRI")) })
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Definicao da Secao 3 - Movimentos                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oSection3 := TRSection():New(oSection2,STR0064,{"SD1","SD2","SD3"}) //"Movimentação dos Produtos"
oSection3 :SetHeaderPage()
oSection3 :SetTotalInLine(.F.)
oSection3 :SetTotalText(STR0017) //"T O T A I S  :"
oSection3 :SetReadOnly()

TRCell():New(oSection3,"dDtMov"		,"   ",STR0038+CRLF+STR0039,/*Picture*/		,nTamData	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"cTES"		,"   ",STR0040				,"@!"			,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"cCF"		,"   ",STR0041				,"@!"			,cTamD1CF	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"cDoc"		,"   ",STR0042+CRLF+STR0043	,"@!"			,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

TRCell():New(oSection3,"cPedCli"		,"   ","PEDIDO DO"+CRLF+"CLIENTE"	,"@!"			,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

TRCell():New(oSection3,"nENTQtd"	,"   ",STR0044+CRLF+STR0045	,cPicD1Qt		,cTamD1Qt	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"nENTCus"	,"   ",STR0044+CRLF+STR0046	,cPicD1Cust		,cTamD1Cust	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"nCusMov"	,"   ",STR0047+CRLF+STR0048	,cPicB2Cust		,cTamB2Cust	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"nSAIQtd"	,"   ",STR0049+CRLF+STR0045	,cPicD2Qt		,cTamD2Qt	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"nSAICus"	,"   ",STR0049+CRLF+STR0046	,cPicD2Cust		,cTamD2Cust	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"nSALDQtd"	,"   ",STR0050+CRLF+STR0045	,cPicB2Qt		,cTamB2Qt	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"nSALDCus"	,"   ",STR0050+CRLF+STR0051	,cPicB2Tot		,cTamB2Cust	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"cCCPVPJOP"	,"   ",STR0052+CRLF+STR0053	,"@!"			,26			,/*lPixel*/,/*{|| code-block de impressao }*/)

//Definir o formato Data.
oSection3:Cell("dDtMov"):SetType("D")

// Definir o formato de valores negativos (para o caso de devolucoes)
oSection3:Cell("nENTQtd"):SetNegative("PARENTHESES")
oSection3:Cell("nENTCus"):SetNegative("PARENTHESES")
oSection3:Cell("nSAIQtd"):SetNegative("PARENTHESES")
oSection3:Cell("nSAICus"):SetNegative("PARENTHESES")

TRFunction():New(oSection3:Cell("nENTQtd")	,NIL,"SUM"		,/*oBreak*/,"",cPicD1Qt		,{|| oSection3:Cell("nENTQtd"):GetValue(.T.) },.T.,.F.) 
TRFunction():New(oSection3:Cell("nENTCus")	,NIL,"SUM"		,/*oBreak*/,"",cPicD1Cust	,{|| oSection3:Cell("nENTCus"):GetValue(.T.) },.T.,.F.) 

TRFunction():New(oSection3:Cell("nSAIQtd")	,NIL,"SUM"		,/*oBreak*/,"",cPicD2Qt		,{|| oSection3:Cell("nSAIQtd"):GetValue(.T.) },.T.,.F.) 
TRFunction():New(oSection3:Cell("nSAICus")	,NIL,"SUM"		,/*oBreak*/,"",cPicD2Cust	,{|| oSection3:Cell("nSAICus"):GetValue(.T.) },.T.,.F.) 

TRFunction():New(oSection3:Cell("nSALDQtd"),NIL,"ONPRINT"	,/*oBreak*/,"",cPicB2Qt		,{|| oSection3:Cell("nSALDQtd"):GetValue(.T.) },.T.,.F.) 
TRFunction():New(oSection3:Cell("nSALDCus"),NIL,"ONPRINT"	,/*oBreak*/,"",cPicB2Tot	,{|| oSection3:Cell("nSALDCus"):GetValue(.T.) },.T.,.F.) 

oSection3:SetNoFilter("SD1")
oSection3:SetNoFilter("SD2")
oSection3:SetNoFilter("SD3")
Return(oReport)

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ReportPrin³ Autor ³Nereu Humberto Junior  ³ Data ³21.06.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³A funcao estatica ReportDef devera ser criada para todos os ³±±
±±³          ³relatorios que poderao ser agendados pelo usuario.          ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpO1: Objeto Report do Relatório                           ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ReportPrint(oReport,oSection)

Static lIxbConTes := NIL
Local oSection1 := oReport:Section(1) 
Local oSection2 := oReport:Section(1):Section(1)  
Local oSection3 := oReport:Section(1):Section(1):Section(1)  
Local nOrdem    := oReport:Section(1):GetOrder() 
Local cSelectD1 := '', cWhereD1 := ''
Local cSelectD2 := '', cWhereD2 := ''
Local cSelectD3 := '', cWhereD3 := ''
Local cSelectVe := '', cUnion := '%%'
Local aDadosTran:={},lContinua := .F.
Local cProdAnt  := ""
Local cLocalAnt := ""
Local nCusMed   := 0
Local lFirst1   := .T.
Local aSalAtu   := { 0,0,0,0,0,0,0 }
Local aSalAlmox := {}
Local nGEntrada := 0, nGSaida :=0
Local nRec1,nRec2,nRec3,nSavRec,dCntData
Local cPicB2Cust:= PesqPict("SB2","B2_CM"+Str(mv_par11,1),18)
Local cPicD1Cust:= PesqPict("SD1","D1_CUSTO"+IIF(mv_par11 == 1 ,"",Str(mv_par11,1)),18)
Local cPicD2Cust:= PesqPict("SD2","D2_CUSTO"+Str(mv_par11,1),18)
Local cPicB2Tot := PesqPictQt("B2_VATU1",18)
Local cPicB2Qt  := PesqPictQt("B2_QATU" ,18)
Local cPicB2Qt2 := PesqPictQt("B2_QTSEGUM" ,18)
Local cCusto, lImpLivro, lImpTermos, cCond1, cCond2
Local nAcho,i,aGrupos:={},cAlias
Local cTRBSD1	:= CriaTrab(,.f.)
Local cTRBSD2	:= Subs(cTrbSD1,1,7)+"A"
Local cTRBSD3	:= Subs(cTrbSD1,1,7)+"B"
Local nInd,cIndice	:="",cCampo1,cCampo2,cCampo3,cCampo4
Local cNumSeqTr := "" , nRegTr := 0
Local cSeqIni 	:= Replicate("z",6)
Local nTotRegs  := 0
Local nTamSX1 := Len(SX1->X1_GRUPO)
// Indica se esta listando relatorio do almox. de processo
Local lLocProc:= mv_par08 == GetMv("MV_LOCPROC")
// Indica se deve imprimir movimento invertido (almox. de processo)
Local lInverteMov :=.F.
Local lPriApropri :=.T.
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se existe ponto de entrada                          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local lTesNEst := .F.
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Codigo do produto importado - NAO DEVE SER LISTADO           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local cProdImp := GETMV("MV_PRODIMP")
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis tipo Local para SIGAVEI, SIGAPEC e SIGAOFI         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local cArq1    := ""
Local nInd1    := 0

Local nRecTrf1 := 0
Local nRecTrf2 := 0
Local aRecTRF  := {}

Local cWhereB1A:= " " 
Local cWhereB1B:= " " 
Local cWhereB1C:= " " 
Local cWhereB1D:= " " 

Local cQueryB1A:= " " 
Local cQueryB1B:= " " 
Local cQueryB1C:= " " 
Local cQueryB1D:= " " 
Local bBloco  := { |nV,nX| Trim(nV)+IIf(Valtype(nX)='C',"",Str(nX,1)) }
Local lVEIC := UPPER(GETMV("MV_VEICULO"))=="S"
Local lImpSMov := .F.
Local lImpS3   := .F.
Local cFilUser := oSection:GetAdvplExp()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variavel utilizada para inicar a pagina do relatorio³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local n_pag     := mv_par12   
Local cAliasTop := ""
Local cProdMNT := GetMv("MV_PRODMNT")
Local cProdTER := GetMv("MV_PRODTER")
Local aProdsMNT := {}
Local nX
Local lWmsNew	:= SuperGetMv("MV_WMSNEW",.F.,.F.)
Local lD3Servi	:= IIF(lWmsNew,.F.,GetMV('MV_D3SERVI',.F.,'N')=='N')

cProdMNT := cProdMNT + Space(15-Len(cProdMNT))
cProdTER := cProdTER  + Space(15-Len(cProdTER))

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se utiliza custo unificado por Empresa/Filial       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Private lCusUnif := A330CusFil()
lCusUnif:=lCusUnif .And. mv_par08 == Repl("*",TamSX3("B2_LOCAL")[1])
Private lDev := .F. // Flag que indica se nota ‚ devolu‡ao (.T.) ou nao (.F.)
Private aDriver := ReadDriver()
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Impressao de Termo / Livro                                   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Do Case
	Case mv_par15==1 ; lImpLivro:=.t. ; lImpTermos:=.f.
	Case mv_par15==2 ; lImpLivro:=.t. ; lImpTermos:=.t.
	Case mv_par15==3 ; lImpLivro:=.f. ; lImpTermos:=.t.
EndCase
oReport:SetPageNumber(n_pag)     
oReport:SetTitle(STR0013+mv_par08)
If nOrdem == 1
	oReport:SetTitle( oReport:Title()+Alltrim(STR0014+STR0004+STR0015+AllTrim(GetMv("MV_SIMB"+Ltrim(Str(mv_par11))))+")"))
Else
	oReport:SetTitle( oReport:Title()+Alltrim(STR0014+STR0005+STR0015+AllTrim(GetMv("MV_SIMB"+Ltrim(Str(mv_par11))))+")"))	
Endif	
oReport:SetTitle( oReport:Title()+AllTrim(IIf(mv_par16==1,OemToAnsi(STR0030),OemToAnsi(STR0031))))

If lVeic
	oSection1:Cell("cProduto"):Disable()
	oSection1:Cell("B1_UM"):Disable()
	oSection1:Cell("cTipo"):Disable()
	oSection1:Cell("B1_GRUPO"):Disable()
Endif

dbSelectArea("SD1")   // Itens de Entrada
nTotRegs += LastRec()

dbSelectArea("SD2")   // Itens de Saida
nTotRegs += LastRec()

dbSelectArea("SD3")   // movimentacoes internas (producao/requisicao/devolucao)
nTotRegs += LastRec()

dbSelectArea("SB2")  // Saldos em estoque
dbSetOrder(1)
nTotRegs += LastRec()

lIxbConTes := IF(lIxbConTes == NIL,ExistBlock("MTAAVLTES"),lIxbConTes)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Filtragem do relatório                                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
MakeSqlExpr(oReport:uParam)
cAliasTop := GetNextAlias()    

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Query do relatório da secao 1                                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oReport:Section(1):BeginQuery()	

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Complemento do SELECT da tabela SD1                                     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cSelectD1 := "% D1_CUSTO"
If mv_par11 > 1
	cSelectD1 += Str(mv_par11,1,0) // Coloca a Moeda do Custo
EndIf
cSelectD1 += " CUSTO,"
cSelectD1 += "%"
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Complemento do SELECT da tabela SB1 para MV_VEICULO                     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	
cSelectVe := "%" 
cSelectVe += ","
IF lVEIC
	cSelectVe += "SB1.B1_CODITE B1_CODITE,"	
ENDIF
cSelectVe += "%" 
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Complemento do Where da tabela SD1                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	
cWhereD1 := "%" 
cWhereD1 += "AND" 
If !lCusUnif
	cWhereD1 += " D1_LOCAL = '" + mv_par08 + "' AND"
EndIf
cWhereD1 += "%" 
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Complemento do SELECT da tabela SD2                                     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
    cSelectD2 := "% D2_CUSTO"
cSelectD2 += Str(mv_par11,1,0) // Coloca a Moeda do Custo
cSelectD2 += " CUSTO,"
    cSelectD2 += "%"	
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Complemento do Where da tabela SD1                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	
cWhereD2 := "%" 
cWhereD2 += "AND" 
If !lCusUnif
	cWhereD2 += " D2_LOCAL = '" + mv_par08 + "' AND"
EndIf
cWhereD2 += "%"    
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Complemento do SELECT da tabelas SD3                                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cSelectD3 := "% D3_CUSTO"
cSelectD3 += Str(mv_par11,1,0) // Coloca a Moeda do Custo
cSelectD3 +=	" CUSTO," 
cSelectD3 += "%"    
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Complemento do WHERE da tabela SD3                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
    cWhereD3 := "%"
If SuperGetMV('MV_D3ESTOR', .F., 'N') == 'N'
	cWhereD3 += " D3_ESTORNO <> 'S' AND"
EndIf
If lD3Servi .And. IntDL()
	cWhereD3 += " ( (D3_SERVIC = '   ') OR (D3_SERVIC <> '   ' AND D3_TM <= '500')  "
	cWhereD3 += " OR  (D3_SERVIC <> '   ' AND D3_TM > '500' AND D3_LOCAL ='"+SuperGetMV('MV_CQ', .F., '98')+"') ) AND"
EndIf
If !lCusUnif .And. !lLocProc
	cWhereD3 += " D3_LOCAL = '"+mv_par08+"' AND" 
EndIf
If	!lVEIC
	cWhereD3+= " SB1.B1_COD >= '"+mv_par01+"' AND SB1.B1_COD <= '"+mv_par02+"' AND"
Else
	cWhereD3+= " SB1.B1_CODITE >= '"+mv_par01+"' AND SB1.B1_CODITE <= '"+mv_par02+"' AND"
EndIf	
cWhereD3 += " SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_TIPO >= '"+mv_par03+"' AND SB1.B1_TIPO <= '"+mv_par04+"' AND"
cWhereD3 += " SB1.B1_GRUPO >= '"+mv_par18+"' AND SB1.B1_GRUPO <= '"+mv_par19+"' AND SB1.B1_COD <> '"+cProdimp+"' AND "
cWhereD3 += " SB1.D_E_L_E_T_=' ' AND"
cWhereD3 += "%"	
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Complemento do WHERE da tabela SB1 para todos os selects                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cWhereB1A:= "%" 
   	cWhereB1B:= "%" 
    cWhereB1C:= "%" 
    cWhereB1D:= "%" 	
If	!lVEIC
	cWhereB1A+= " AND SB1.B1_COD >= '"+mv_par01+"' AND SB1.B1_COD <= '"+mv_par02+"'"
	cWhereB1B+= " AND SB1.B1_COD = SB1EXS.B1_COD"
	cWhereB1C+= " SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_TIPO >= '"+mv_par03+"' AND SB1.B1_TIPO <= '"+mv_par04+"' AND"
	cWhereB1D+= " SB1EXS.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1EXS.B1_COD >= '"+mv_par01+"' AND SB1EXS.B1_COD <= '"+mv_par02+"' AND SB1EXS.B1_TIPO >= '"+mv_par03+"' AND SB1EXS.B1_TIPO <= '"+mv_par04+"' AND"
Else
	cWhereB1A+= " AND SB1.B1_CODITE >= '"+mv_par01+"' AND SB1.B1_CODITE <= '"+mv_par02+"'"
	cWhereB1B+= " AND SB1.B1_COD = SB1EXS.B1_COD"
	cWhereB1C+= " SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_TIPO >= '"+mv_par03+"' AND SB1.B1_TIPO <= '"+mv_par04+"' AND"
	cWhereB1D+= " SB1EXS.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1EXS.B1_CODITE >= '"+mv_par01+"' AND SB1EXS.B1_CODITE <= '"+mv_par02+"' AND SB1EXS.B1_TIPO >= '"+mv_par03+"' AND SB1EXS.B1_TIPO <= '"+mv_par04+"' AND"
EndIf	
cWhereB1C += " SB1.B1_GRUPO >= '"+mv_par18+"' AND SB1.B1_GRUPO <= '"+mv_par19+"' AND SB1.B1_COD <> '"+cProdimp+"' AND "
cWhereB1C += " SB1.D_E_L_E_T_=' '"
cWhereB1D += " SB1EXS.B1_GRUPO >= '"+mv_par18+"' AND SB1EXS.B1_GRUPO <= '"+mv_par19+"' AND SB1EXS.B1_COD <> '"+cProdimp+"' AND "
cWhereB1D += " SB1EXS.D_E_L_E_T_=' '"	

cQueryB1A:= Subs(cWhereB1A,2)
cQueryB1B:= Subs(cWhereB1B,2)
cQueryB1C:= Subs(cWhereB1C,2)
cQueryB1D:= Subs(cWhereB1D,2)

cWhereB1A+= "%" 
   	cWhereB1B+= "%" 
    cWhereB1C+= "%" 
    cWhereB1D+= "%" 	
 	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ So inclui as condicoes a seguir qdo lista produtos sem ³
//³ movimento                                              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cQueryD1 := " FROM "
cQueryD1 += RetSqlName("SB1") + " SB1"
cQueryD1 += (", " + RetSqlName("SD1")+ " SD1 ")
cQueryD1 += (", " + RetSqlName("SF4")+ " SF4 ")
cQueryD1 += " WHERE SB1.B1_COD = D1_COD"
cQueryD1 += (" AND D1_FILIAL = '"+xFilial("SD1")+"'")
cQueryD1 += (" AND F4_FILIAL = '" + xFilial("SF4") + "'")
cQueryD1 += (" AND SD1.D1_TES = F4_CODIGO AND F4_ESTOQUE = 'S'")
cQueryD1 += (" AND D1_DTDIGIT >= '" + DTOS(mv_par05) + "'")
cQueryD1 += (" AND D1_DTDIGIT <= '" + DTOS(mv_par06) + "'")
cQueryD1 +=  " AND D1_ORIGLAN <> 'LF'"
If !lCusUnif
	cQueryD1 += " AND D1_LOCAL = '" + mv_par08 + "'"
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Não imprimir o produto MANUTENCAO (MV_PRDMNT) qdo integrado com MNT.       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If MTR910IsMNT() 
	aProdsMNT := aClone(NGProdMNT())
	For nX := 1 To Len(aProdsMNT)
		cQueryD1 += " AND SB1.B1_COD <> '" + aProdsMNT[nX] + "'"
	Next nX
EndIf	
cQueryD1 += " AND SD1.D_E_L_E_T_=' ' AND SF4.D_E_L_E_T_=' '"

cQueryD2 := " FROM "
cQueryD2 += RetSqlName("SB1") + " SB1 , "+ RetSqlName("SD2")+ " SD2 , "+ RetSqlName("SF4")+" SF4 "
cQueryD2 += " WHERE SB1.B1_COD = D2_COD AND D2_FILIAL = '"+xFilial("SD2")+"'"
cQueryD2 += " AND F4_FILIAL = '"+xFilial("SF4")+"' AND SD2.D2_TES = F4_CODIGO AND F4_ESTOQUE = 'S'"
cQueryD2 += " AND D2_EMISSAO >= '"+DTOS(mv_par05)+"' AND D2_EMISSAO <= '"+DTOS(mv_par06)+"'"
cQueryD2 += " AND D2_ORIGLAN <> 'LF'"
If !lCusUnif
	cQueryD2 += " AND D2_LOCAL = '"+mv_par08+"'"
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Não imprimir o produto MANUTENCAO (MV_PRDMNT) qdo integrado com MNT.       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If MTR910IsMNT() 
	aProdsMNT := aClone(NGProdMNT())
	For nX := 1 To Len(aProdsMNT)
		cQueryD2 += " AND SB1.B1_COD <> '" + aProdsMNT[nX] + "'"
	Next nX
EndIf	
cQueryD2 += " AND SD2.D_E_L_E_T_=' ' AND SF4.D_E_L_E_T_=' '"	

cQueryD3 := " FROM "
cQueryD3 += RetSqlName("SB1") + " SB1 , "+ RetSqlName("SD3")+ " SD3 "
cQueryD3 += " WHERE SB1.B1_COD = D3_COD AND D3_FILIAL = '"+xFilial("SD3")+"' "
cQueryD3 += " AND D3_EMISSAO >= '"+DTOS(mv_par05)+"' AND D3_EMISSAO <= '"+DTOS(mv_par06)+"'"
If SuperGetMV('MV_D3ESTOR', .F., 'N') == 'N'
	cQueryD3 += " AND D3_ESTORNO <> 'S'"
EndIf
If lD3Servi .And. IntDL()
	cQueryD3 += " AND ( (D3_SERVIC = '   ') OR (D3_SERVIC <> '   ' AND D3_TM <= '500')  "
	cQueryD3 += " OR  (D3_SERVIC <> '   ' AND D3_TM > '500' AND D3_LOCAL ='"+SuperGetMV('MV_CQ', .F., '98')+"') )"
EndIf					
If !lCusUnif .And. !lLocProc
	cQueryD3 += " AND D3_LOCAL = '"+mv_par08+"'"
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Nao imprimir o produto MANUTENCAO (MV_PRDMNT) qdo integrado com MNT. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If MTR910IsMNT() 
	aProdsMNT := aClone(NGProdMNT())
	For nX := 1 To Len(aProdsMNT)
		cQueryD3 += " AND SB1.B1_COD <> '" + aProdsMNT[nX] + "'"
	Next nX
EndIf	
cQueryD3 += " AND SD3.D_E_L_E_T_=' '"	

cQuerySub:= "SELECT 1 "

If mv_par07 == 1
	cQuery2 := " AND NOT EXISTS (" + cQuerySub + cQueryD1
	cQuery2 += cQueryB1B
	cQuery2 += " AND "
	cQuery2 += cQueryB1C
	cQuery2 += ") AND NOT EXISTS ("
	cQuery2 += cQuerySub + cQueryD2
	cQuery2 += cQueryB1B
	cQuery2 += " AND "
	cQuery2 += cQueryB1C
	cQuery2 += ") AND NOT EXISTS ("
	cQuery2 += cQuerySub + cQueryD3
	cQuery2 += cQueryB1B
	cQuery2 += " AND "
	cQuery2 += cQueryB1C + ")"
        
	cUnion := "%"
	cUnion += " UNION SELECT 'SB1'"		// 01
	cUnion += ", SB1EXS.B1_COD"			// 02
	cUnion += ", SB1EXS.B1_TIPO"		// 03
	cUnion += ", SB1EXS.B1_UM"			// 04
	cUnion += ", SB1EXS.B1_GRUPO"		// 05
	cUnion += ", SB1EXS.B1_DESC"		// 06
	cUnion += ", SB1EXS.B1_POSIPI"		// 07
	cUnion += ", ''"					// 08
	cUnion += ", ''"					// 09
	cUnion += ", ''"					// 10
	cUnion += ", ''"					// 11
	cUnion += ", ''"					// 12
	cUnion += ", ''"					// 13
	cUnion += ", ''"					// 14
	cUnion += ", 0"						// 15
	cUnion += ", 0"						// 16
	cUnion += ", ''"					// 17
	cUnion += ", ''"					// 18
	cUnion += ", ''"					// 19
	cUnion += ", ''"					// 20
	cUnion += ", ''"					// 21
	cUnion += ", ''"					// 22
	cUnion += ", ''"					// 23
	cUnion += ", ''"					// 24
	cUnion += ", 0"						// 25
	cUnion += ", ''"					// 26
	If lVEIC
		cUnion += ", SB1EXS.B1_CODITE CODITE"	// 27
	EndIf
	cUnion += ", ''"					// 28
	cUnion += ", 0"						// 29
	cUnion += " FROM "+RetSqlName("SB1") + " SB1EXS WHERE"
	cUnion += cQueryB1D
	cUnion += cQuery2
	cUnion += "%"
EndIf

cOrder := "%"
If nOrdem == 1
	If ! lVEIC
		cOrder += " 2,9,"
	Else
		cOrder += " 27, 9,"
	EndIf	
ElseIf nOrdem == 2
	If ! lVEIC
		cOrder += " 3,2,9,"
	Else
		cOrder += " 3, 27, 9,"
	EndIf	
EndIf
If mv_par16 == 1
//		cOrder += "17,12"+IIf(lVEIC,',29',',28')
	cOrder += "12"+IIf(lVEIC,',29',',28')
Else
	If lCusUnif
		cOrder += "8,12"+IIf(lVEIC,',29',',28')
	Else
//			cOrder += "17,8,12"+IIf(lVEIC,',29',',28')
		cOrder += "8"+IIf(lVEIC,',29',',28')
	EndIf
EndIf	
cOrder += "%"

BeginSql Alias cAliasTop

	SELECT 	'SD1' ARQ, 				//-- 01 ARQ
			 SB1.B1_COD PRODUTO, 	//-- 02 PRODUTO
			 SB1.B1_TIPO TIPO, 		//-- 03 TIPO
			 SB1.B1_UM,   			//-- 04 UM
			 SB1.B1_GRUPO,      	//-- 05 GRUPO
			 SB1.B1_DESC,      		//-- 06 DESCR
		     SB1.B1_POSIPI, 		//-- 07
		     D1_SEQCALC SEQCALC,    //-- 08
			 D1_DTDIGIT DATA,		//-- 09 DATA
			 D1_TES TES,			//-- 10 TES
			 D1_CF CF,				//-- 11 CF
			 D1_NUMSEQ SEQUENCIA,	//-- 12 SEQUENCIA
			 D1_DOC DOCUMENTO,		//-- 13 DOCUMENTO
			 D1_SERIE SERIE,		//-- 14 SERIE
			 D1_QUANT QUANTIDADE,	//-- 15 QUANTIDADE
			 D1_QTSEGUM QUANT2UM,	//-- 16 QUANT2UM
			 D1_LOCAL ARMAZEM,		//-- 17 ARMAZEM
             ' ' PROJETO,			//-- 18 PROJETO
			 ' ' OP,				//-- 19 OP
			 ' ' CC,				//-- 20 OP
			 D1_FORNECE FORNECEDOR,	//-- 21 FORNECEDOR
			 D1_LOJA LOJA,			//-- 22 LOJA
			 ' ' PEDIDO,            //-- 23 PEDIDO
			 D1_TIPO TIPONF,		//-- 24 TIPO NF
			 %Exp:cSelectD1%		//-- 25 CUSTO 
			 ' ' TRT 				//-- 26 TRT
			 %Exp:cSelectVe%        //-- 27 CODITE
			 D1_LOTECTL LOTE, 	    //-- 28 LOTE					 
			 SD1.R_E_C_N_O_ NRECNO  //-- 29 RECNO

	FROM %table:SB1% SB1,%table:SD1% SD1,%table:SF4% SF4
	
	WHERE SB1.B1_COD     =  SD1.D1_COD		AND  	SD1.D1_FILIAL  =  %xFilial:SD1%		AND
		  SF4.F4_FILIAL  =  %xFilial:SF4%  	AND 	SD1.D1_TES     =  SF4.F4_CODIGO		AND
		  SF4.F4_ESTOQUE =  'S'				AND 	SD1.D1_DTDIGIT >= %Exp:mv_par05%   AND
		  SD1.D1_DTDIGIT <= %Exp:mv_par06%	AND		SD1.D1_ORIGLAN <> 'LF'				   
		  %Exp:cWhereD1%
		  SD1.%NotDel%						AND 	SF4.%NotDel%                           
		  %Exp:cWhereB1A%                   AND
		  %Exp:cWhereB1C%

    UNION
    
	SELECT 'SD2',	     			
			SB1.B1_COD,	        	
			SB1.B1_TIPO,		    
			SB1.B1_UM,				
			SB1.B1_GRUPO,		    
			SB1.B1_DESC,		    
			SB1.B1_POSIPI,
			D2_SEQCALC,
			D2_EMISSAO,				
			D2_TES,					
			D2_CF,					
			D2_NUMSEQ,				
			D2_DOC,					
			D2_SERIE,				
			D2_QUANT,				
			D2_QTSEGUM,				
			D2_LOCAL,				
			' ',					
			' ',					
			' ',					
			D2_CLIENTE,				
			D2_LOJA,				
			D2_PEDIDO,
			D2_TIPO,				
			%Exp:cSelectD2%			
			' ' 					
			%Exp:cSelectVe%
			D2_LOTECTL,
		    SD2.R_E_C_N_O_ SD2RECNO 	// 29

	FROM %table:SB1% SB1,%table:SD2% SD2,%table:SF4% SF4
	
	WHERE	SB1.B1_COD     =  SD2.D2_COD		AND	SD2.D2_FILIAL  = %xFilial:SD2%		AND
			SF4.F4_FILIAL  = %xFilial:SF4% 		AND	SD2.D2_TES     =  SF4.F4_CODIGO		AND
			SF4.F4_ESTOQUE =  'S'				AND	SD2.D2_EMISSAO >= %Exp:mv_par05%	AND
			SD2.D2_EMISSAO <= %Exp:mv_par06%	AND	SD2.D2_ORIGLAN <> 'LF'				   
			%Exp:cWhereD2%
			SD2.%NotDel%						AND SF4.%NotDel%						   
			%Exp:cWhereB1A%                     AND
		  	%Exp:cWhereB1C%

	UNION		

	SELECT 	'SD3',	    			
			SB1.B1_COD,	    	    
			SB1.B1_TIPO,		    
			SB1.B1_UM,				
			SB1.B1_GRUPO,	     	
			SB1.B1_DESC,		    
			SB1.B1_POSIPI,
			D3_SEQCALC,
			D3_EMISSAO,				
			D3_TM,					
			D3_CF,					
			D3_NUMSEQ,				
			D3_DOC,					
			' ',					
			D3_QUANT,				
			D3_QTSEGUM,				
			D3_LOCAL,				
			D3_PROJPMS,
			D3_OP,					
			D3_CC,
			' ',					
			' ',					
			' ',					
			' ',									
			%Exp:cSelectD3%			
			D3_TRT 
			%Exp:cSelectVe%
			D3_LOTECTL,
			SD3.R_E_C_N_O_ SD3RECNO 	// 29

	FROM %table:SB1% SB1,%table:SD3% SD3

	WHERE	SB1.B1_COD     =  SD3.D3_COD 		AND SD3.D3_FILIAL  =  %xFilial:SD3%		AND
			SD3.D3_EMISSAO >= %Exp:mv_par05%	AND	SD3.D3_EMISSAO <= %Exp:mv_par06%	AND
			%Exp:cWhereD3% 	
			SD3.%NotDel% 

			
	%Exp:cUnion%			

	ORDER BY %Exp:cOrder%

EndSql 

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Metodo EndQuery ( Classe TRSection )                                    ³
//³                                                                        ³
//³Prepara o relatório para executar o Embedded SQL.                       ³
//³                                                                        ³
//³ExpA1 : Array com os parametros do tipo Range                           ³
//³                                                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oReport:Section(1):EndQuery(/*Array com os parametros do tipo Range*/)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inicio da impressao do fluxo do relatório                               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea(cAliasTop)
oReport:SetMeter(nTotRegs)

TcSetField(cAliasTop,DATA ,"D", TamSx3("D1_DTDIGIT")[1], TamSx3("D1_DTDIGIT")[2] )

While !oReport:Cancel() .And. !(cAliasTop)->(Eof()) .And. lImpLivro

	If oReport:Cancel()
		Exit
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Considera filtro escolhido                                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !Empty(cFilUser) .And. SUBSTR(cFilUser,2,2) == "B1"
		dbSelectArea("SB1")
		SB1->(dbSetOrder(1))
	    SB1->(dbSeek(xFilial("SB1")+(cAliasTop)->PRODUTO))
	    If !(&(cFilUser))
  			   dbSelectArea(cAliasTop)	 	    
	       dbSkip()
    	   Loop
    	EndIf  
    ElseIf !Empty(cFilUser) .And. SUBSTR(cFilUser,2,2) == "B2"
   			dbSelectArea("SB2")
		SB2->(dbSetOrder(1))
	    SB2->(dbSeek(xFilial("SB2")+(cAliasTop)->PRODUTO))
	    If !(&(cFilUser))
  			   dbSelectArea(cAliasTop)	 	    
	       dbSkip()
    	   Loop
    	EndIf    
	EndIf

	dbSelectArea(cAliasTop)
	oReport:IncMeter()
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Se nao encontrar no arquivo de saldos ,nao lista ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("SB2")
	If !dbSeek(xFilial("SB2")+(cAliasTop)->PRODUTO+If(lCusUnif,"",mv_par08))
		dbSelectArea(cAliasTop)
		dbSkip()
		Loop
	EndIf
	// Nao lista de saldo for igual a zero
	If mv_par20 == 2 .And. SB2->B2_QATU == 0
		dbSelectArea(cAliasTop)
		dbSkip()
		Loop
	EndIf
	// Nao lista de saldo for negativo
	If mv_par21 == 2 .And. SB2->B2_QATU < 0
		dbSelectArea(cAliasTop)
		dbSkip()
		Loop
	EndIf

	dbSelectArea(cAliasTop)
	cProdAnt  := (cAliasTop)->PRODUTO
	cLocalAnt := SB2->B2_LOCAL
	lFirst:=.F.

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calcula o Saldo Inicial do Produto             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lCusUnif
		aArea:=GetArea()
		aSalAtu  := { 0,0,0,0,0,0,0 }
		dbSelectArea("SB2")
		dbSetOrder(1)
		MsSeek(cSeek:=xFilial("SB2")+(cAliasTOP)->PRODUTO)
		While !Eof() .And. B2_FILIAL+B2_COD == cSeek
			aSalAlmox := CalcEst((cAliasTOP)->PRODUTO,SB2->B2_LOCAL,mv_par05)
			For i:=1 to Len(aSalAtu)
				aSalAtu[i] += aSalAlmox[i]
			Next i
			dbSkip()
		End
		RestArea(aArea)
	Else
		aSalAtu := CalcEst((cAliasTOP)->PRODUTO,mv_par08,mv_par05)
	EndIf

	If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
		aGrupos[nAcho][4] += aSalAtu[mv_par11+1]
	Else
		AADD(aGrupos,{(cAliasTOP)->TIPO,0,0,aSalAtu[mv_par11+1]})
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calcula o Custo Medio do Produto               ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If AsalAtu[1] > 0
		nCusmed := aSalAtu[mv_par11+1]/aSalAtu[1]
	ElseIf AsalAtu[1] == 0 .and. AsalAtu[mv_par11+1] == 0
		nCusMed := 0
	Else
		SB2->(dbSeek(xFilial("SB2") + (cAliasTOP)->PRODUTO + (cAliasTOP)->ARMAZEM))
		nCusmed := &("SB2->B2_CM" + Str(mv_par11,1))
	EndIf
	MR910ImpS1(aSalAtu,nCusMed,cAliasTop,lVEIC,lCusUnif,oSection1,oSection2)
	lFirst1 := .F.

	oSection3:Init() 
	While !oReport:Cancel() .And. !(cAliasTop)->(Eof()) .And. (cAliasTop)->PRODUTO = cProdAnt
		oReport:IncMeter()
		lContinua := .F.
		lImpSMov  := .F.
		lImpS3    := .F.
		If Alltrim((cAliasTop)->ARQ) $ "SD1/SD2"
			lFirst:=.T.
			SF4->(dbSeek(xFilial("SF4")+(cAliasTop)->TES))
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Despreza Notas Fiscais Lancadas Pelo Modulo do Livro Fiscal  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Executa ponto de entrada para verificar se considera TES que ³
			//³ NAO ATUALIZA saldos em estoque.                              ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If lIxbConTes .And. SF4->F4_ESTOQUE != "S"
				lTesNEst := ExecBlock("MTAAVLTES",.F.,.F.)
				lTesNEst := If(ValType(lTesNEst) # "L",.F.,lTesNEst)
			EndIf
			If SF4->F4_ESTOQUE != "S" .And. !lTesNEst
				dbSkip()
				Loop
			EndIf
		ElseIf Alltrim((cAliasTop)->ARQ) == "SD3"
			lFirst:=.T.
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Quando movimento ref apropr. indireta, so considera os         ³
			//³ movimentos com destino ao almoxarifado de apropriacao indireta.³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			lInverteMov:=.F.
			If (cAliasTop)->ARMAZEM != cLocalAnt .Or. lCusUnif
				If !(Substr((cAliasTop)->CF,3,1) == "3")
					If !lCusUnif
						dbSkip()
						Loop
					EndIf
				ElseIf lPriApropri
					lInverteMov:=.T.
				EndIf
			EndIf
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Caso seja uma transferencia de localizacao verifica se lista   ³
			//³ o movimento ou nao                                             ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If mv_par17 == 2 .And. Substr((cAliasTop)->CF,3,1) == "4"
				cNumSeqTr := (cAliasTOP)->(PRODUTO+SEQUENCIA+ARMAZEM)
				aDadosTran:={(cAliasTOP)->TES,(cAliasTOP)->QUANTIDADE,(cAliasTOP)->CUSTO,(cAliasTOP)->QUANT2UM,(cAliasTOP)->TIPO,;
					(cAliasTOP)->DATA,(cAliasTOP)->CF,(cAliasTOP)->SEQUENCIA,(cAliasTOP)->DOCUMENTO,(cAliasTOP)->PRODUTO,;
					(cAliasTOP)->OP,(cAliasTOP)->PROJETO,(cAliasTOP)->CC,(cAliasTOP)->ARQ}
				dbSkip()
				If (cAliasTOP)->(PRODUTO+SEQUENCIA+ARMAZEM) == cNumSeqTr
					dbSkip()
					Loop
				Else
					lContinua := .T.
					If lFirst
						oSection3:Cell("dDtMov"):SetValue(STOD(aDadosTran[6]))			
						oSection3:Cell("cTES"):SetValue(aDadosTran[1])										
						If ( cPaisLoc=="BRA" )
							oSection3:Cell("cCF"):Show()
							oSection3:Cell("cCF"):SetValue(aDadosTran[7])
							/*
							If	lInverteMov
								@Li , 018 PSay "*"
							EndIf
							*/
						Else
							oSection3:Cell("cCF"):Hide()
							oSection3:Cell("cCF"):SetValue("   ")
						EndIf
						If mv_par09 $ "Ss"
							oSection3:Cell("cDoc"):SetValue(aDadosTran[8])			
						Else
							oSection3:Cell("cDoc"):SetValue(aDadosTran[9])			
						Endif
					EndIf
					If aDadosTran[1] <= "500"
						oSection3:Cell("nENTQtd"):Show()
						oSection3:Cell("nENTCus"):Show()
						oSection3:Cell("nCusMov"):Show()

						oSection3:Cell("nENTQtd"):SetValue(aDadosTran[2])			
						oSection3:Cell("nENTCus"):SetValue(aDadosTran[3])			
						oSection3:Cell("nCusMov"):SetValue(aDadosTran[3] / aDadosTran[2])			
						
						oSection3:Cell("nSAIQtd"):Hide()
						oSection3:Cell("nSAICus"):Hide()
						oSection3:Cell("nSAIQtd"):SetValue(0)			
						oSection3:Cell("nSAICus"):SetValue(0)			
                            
						aSalAtu[1] += aDadosTran[2]
						aSalAtu[mv_par11+1] += aDadosTran[3]
						aSalAtu[7] += aDadosTran[4]
						
						If (nAcho := ASCAN(aGrupos,{|x| aDadosTran[5] == x[1]})) > 0
							aGrupos[nAcho][2]+=aDadosTran[3]
							aGrupos[nAcho][4]+=aDadosTran[3]
						Else
							AADD(aGrupos,{aDadosTran[5],aDadosTran[3],0,aSalAtu[mv_par11+1]})
						EndIf
					Else
						oSection3:Cell("nENTQtd"):Hide()
						oSection3:Cell("nENTCus"):Hide()
						oSection3:Cell("nENTQtd"):SetValue(0)
						oSection3:Cell("nENTCus"):SetValue(0)
						
						oSection3:Cell("nCusMov"):Show()
						oSection3:Cell("nSAIQtd"):Show()
						oSection3:Cell("nSAICus"):Show()

						oSection3:Cell("nCusMov"):SetValue(aDadosTran[3] / aDadosTran[2])			
						oSection3:Cell("nSAIQtd"):SetValue(aDadosTran[2])			
						oSection3:Cell("nSAICus"):SetValue(aDadosTran[3])			

						aSalAtu[1] -= aDadosTran[2]
						aSalAtu[mv_par11+1] -= aDadosTran[3]
						aSalAtu[7] -= aDadosTran[4]
						If (nAcho := ASCAN(aGrupos,{|x| aDadosTran[5] == x[1]})) > 0
							aGrupos[nAcho][3]+=aDadosTran[3]
							aGrupos[nAcho][4]-=aDadosTran[3]
						Else
							AADD(aGrupos,{aDadosTran[5],0,aDadosTran[3],-(aSalAtu[mv_par11+1])})
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf	
		If lFirst .And. !lContinua
			oSection3:Cell("dDtMov"):SetValue(STOD(DATA))			
			oSection3:Cell("cTES"):SetValue(TES)														
			If ( cPaisLoc=="BRA" )
				oSection3:Cell("cCF"):Show()
				oSection3:Cell("cCF"):SetValue(CF)					
				/*
				If	lInverteMov
					@Li , 018 PSay "*"
				EndIf
				*/
			Else
				oSection3:Cell("cCF"):Hide()
				oSection3:Cell("cCF"):SetValue("   ")				
			EndIf
			If mv_par09 $ "Ss"
				oSection3:Cell("cDoc"):SetValue(SEQUENCIA)			
			Else
				oSection3:Cell("cDoc"):SetValue(DOCUMENTO)						
			Endif	
		EndIf

		Do Case
			Case Alltrim((cAliasTop)->ARQ) == "SD1" .And. !lContinua
				oSection3:Cell("cPedCli"):Hide()
				oSection3:Cell("cPedCli"):SetValue(0)
				lDev:=MTR910Dev(cAliasTop)
				If (cAliasTOP)->TES <= "500" .And. !lDev
					If (cAliasTOP)->TIPONF != "C"
						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)
						oSection3:Cell("nCusMov"):Show()
					Else
						oSection3:Cell("nCusMov"):SetValue(0)
						oSection3:Cell("nCusMov"):Hide()
					EndIf
					
					oSection3:Cell("nENTQtd"):Show()
					oSection3:Cell("nENTCus"):Show()
					
					oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
					oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO)			
					
					oSection3:Cell("nSAIQtd"):Hide()
					oSection3:Cell("nSAICus"):Hide()						
					oSection3:Cell("nSAIQtd"):SetValue(0)
					oSection3:Cell("nSAICus"):SetValue(0)
					
					aSalAtu[1] += (cAliasTOP)->QUANTIDADE
					aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
					aSalAtu[7] += (cAliasTOP)->QUANT2UM
					If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
						aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
						aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
					Else
						AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
					EndIf
				Else
					If (cAliasTOP)->TIPONF != "C"
						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nCusMov"):Show()
					Else
						oSection3:Cell("nCusMov"):SetValue(0)									
						oSection3:Cell("nCusMov"):Hide()
					EndIf

					oSection3:Cell("nENTQtd"):Hide()
					oSection3:Cell("nENTCus"):Hide()
					oSection3:Cell("nENTQtd"):SetValue(0)
					oSection3:Cell("nENTCus"):SetValue(0)
						
					oSection3:Cell("nSAIQtd"):Show()
					oSection3:Cell("nSAICus"):Show()

					If lDev

						oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE * -1)
						oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO * -1)
						
						aSalAtu[1] += (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
						aSalAtu[7] += (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][3]-=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,0,-((cAliasTOP)->CUSTO),aSalAtu[mv_par11+1]})
						EndIf
					Else
						oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO)																
						
						aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
						aSalAtu[7] -= (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
						EndIf
					EndIf
				EndIf
			Case Alltrim((cAliasTop)->ARQ) = "SD2" .And. !lContinua
				
				If Select("tSC5") > 0
					DBSelectArea("tSC5")
					tSC5->(DBCloseArea())
				EndIf
				
				//Gustavo, SLA, inclusão da numeração do pedido do cliente
				cQuery := ""
				cQuery += " SELECT C5_ZPEDCLI "
				cQuery += " FROM " + RetSQLTab("SC5")
				cQuery += " WHERE " + RetSqlCond("SC5")
				cQuery += " AND C5_NOTA  = '" + (cAliasTop)->DOCUMENTO + "'"
				cQuery += " AND C5_SERIE = '" + (cAliasTop)->SERIE     + "'"
				
				TCQuery cQuery NEW ALIAS "tSC5"
				DBSelectArea("tSC5")
				tSC5->(DBGoTop())
				
				if !tSC5->(EOF())
					oSection3:Cell("cPedCli"):Show()
					oSection3:Cell("cPedCli"):SetValue(tSC5->C5_ZPEDCLI)
				EndIf
				
				If Select("tSC5") > 0
					DBSelectArea("tSC5")
					tSC5->(DBCloseArea())
				EndIf
				
				lDev:=MTR910Dev(cAliasTop)
				If (cAliasTOP)->TES <= "500" .Or. lDev
					If lDev
						
						oSection3:Cell("nENTQtd"):Show()
						oSection3:Cell("nENTCus"):Show()

						oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE * -1)
						oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO * -1)
						
						aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
						aSalAtu[7] -= (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][2]-=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,-((cAliasTOP)->CUSTO),0,-(aSalAtu[mv_par11+1])})
						EndIf
					Else
						oSection3:Cell("nENTQtd"):Show()
						oSection3:Cell("nENTCus"):Show()
						
						oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO)										
						
						aSalAtu[1] += (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
						aSalAtu[7] += (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
						EndIf
					EndIf

					If (cAliasTOP)->TIPONF != "C"
						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)																
						oSection3:Cell("nCusMov"):Show()
					Else
						oSection3:Cell("nCusMov"):SetValue(0)
						oSection3:Cell("nCusMov"):Hide()
					EndIf
					oSection3:Cell("nSAIQtd"):Hide()
					oSection3:Cell("nSAICus"):Hide()
					oSection3:Cell("nSAIQtd"):SetValue(0)
					oSection3:Cell("nSAICus"):SetValue(0)
				Else
					If (cAliasTOP)->TIPONF != "C"
						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)																
						oSection3:Cell("nCusMov"):Show()
					Else
						oSection3:Cell("nCusMov"):SetValue(0)																						
						oSection3:Cell("nCusMov"):Hide()
					EndIf						
					
					oSection3:Cell("nENTQtd"):Hide()
					oSection3:Cell("nENTCus"):Hide()
					oSection3:Cell("nENTQtd"):SetValue(0)
					oSection3:Cell("nENTCus"):SetValue(0)

					oSection3:Cell("nSAIQtd"):Show()
					oSection3:Cell("nSAICus"):Show()
					
					oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
					oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO)																						
					
					aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
					aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
					aSalAtu[7] -= (cAliasTOP)->QUANT2UM
					If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
						aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
						aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
					Else
						AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
					EndIf
				EndIf
			Case Alltrim((cAliasTop)->ARQ) == "SD3" .And. !lContinua
				lDev := .F.
				If	lInverteMov
					If (cAliasTOP)->TES > "500"

						oSection3:Cell("nENTQtd"):Show()
						oSection3:Cell("nENTCus"):Show()
						oSection3:Cell("nCusMov"):Show()

						oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO)			
						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)										
						
						oSection3:Cell("nSAIQtd"):Hide()
						oSection3:Cell("nSAICus"):Hide()							
						oSection3:Cell("nSAIQtd"):SetValue(0)
						oSection3:Cell("nSAICus"):SetValue(0)														
						
						aSalAtu[1] += (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
						aSalAtu[7] += (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
						EndIf
					Else
						oSection3:Cell("nENTQtd"):Hide()
						oSection3:Cell("nENTCus"):Hide()
						oSection3:Cell("nENTQtd"):SetValue(0)
						oSection3:Cell("nENTCus"):SetValue(0)
						
						oSection3:Cell("nCusMov"):Show()
						oSection3:Cell("nSAIQtd"):Show()
						oSection3:Cell("nSAICus"):Show()
						
						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO)										
						
						aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
						aSalAtu[7] -= (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
						EndIf
					EndIf 
					If lCusUnif
						lPriApropri:=.F.
					EndIf
				Else
					If (cAliasTOP)->TES <= "500"

						oSection3:Cell("nENTQtd"):Show()
						oSection3:Cell("nENTCus"):Show()
						oSection3:Cell("nCusMov"):Show()

						oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO)			
						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)																	
						
						oSection3:Cell("nSAIQtd"):Hide()
						oSection3:Cell("nSAICus"):Hide()							
						oSection3:Cell("nSAIQtd"):SetValue(0)
						oSection3:Cell("nSAICus"):SetValue(0)
						
						aSalAtu[1] += (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
						aSalAtu[7] += (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
						EndIf
					Else

						oSection3:Cell("nENTQtd"):Hide()
						oSection3:Cell("nENTCus"):Hide()
						oSection3:Cell("nENTQtd"):SetValue(0)
						oSection3:Cell("nENTCus"):SetValue(0)
						
						oSection3:Cell("nCusMov"):Show()
						oSection3:Cell("nSAIQtd"):Show()
						oSection3:Cell("nSAICus"):Show()

						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO)																	
						
						aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
						aSalAtu[7] -= (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
						EndIf
					EndIf
					If lCusUnif
						lPriApropri:=.T.
					EndIf
				EndIf
		EndCase
		If lFirst
			oSection3:Cell("nSALDQtd"):SetValue(aSalAtu[1])			
			oSection3:Cell("nSALDCus"):SetValue(aSalAtu[mv_par11+1])			
		EndIf
		Do Case
			Case Alltrim((cAliasTop)->ARQ) == "SD3" .And. !lContinua
				If Empty((cAliasTOP)->OP) .And. Empty((cAliasTOP)->PROJETO)
					oSection3:Cell("cCCPVPJOP"):SetValue('CC'+(cAliasTOP)->CC)			
				ElseIf !Empty((cAliasTOP)->PROJETO)
					oSection3:Cell("cCCPVPJOP"):SetValue('PJ'+(cAliasTOP)->PROJETO)
				ElseIf !Empty((cAliasTOP)->OP)
					oSection3:Cell("cCCPVPJOP"):SetValue('OP'+(cAliasTOP)->OP)
				EndIf
			Case Alltrim((cAliasTop)->ARQ) == "SD1" .And. !lContinua
				oSection3:Cell("cCCPVPJOP"):SetValue('F-'+(cAliasTOP)->FORNECEDOR)
			Case Alltrim((cAliasTop)->ARQ) == "SD2" .And. !lContinua
				oSection3:Cell("cCCPVPJOP"):SetValue('P-'+(cAliasTOP)->PEDIDO)					
			Case lContinua .And. aDadosTran[14] == "SD3"
				If Empty(aDadosTran[11]) .And. Empty(aDadosTran[12])
					oSection3:Cell("cCCPVPJOP"):SetValue('CC'+aDadosTran[13])	
				ElseIf !Empty(aDadosTran[12])
					oSection3:Cell("cCCPVPJOP"):SetValue('PJ'+aDadosTran[12])
				ElseIf !Empty(aDadosTran[11])
					oSection3:Cell("cCCPVPJOP"):SetValue('OP'+aDadosTran[11])
				EndIf
		EndCase
            
		If lFirst
			oSection3:PrintLine()
		Endif	

		If !lInverteMov .Or. (lInverteMov .And. lPriApropri)
			If !lContinua //Acerto para utilizar o Array aDadosTran[]
				dbSkip()
			EndIf
		EndIf
	EndDo

	If lFirst
		oReport:PrintText(STR0018+TransForm(aSalAtu[7],cPicB2Qt2),,oSection3:Cell('nSAICus'):ColPos()) //"QTD. NA SEGUNDA UM: "											
		lImpS3 := .T.
	Else
		If !MTR910IsMNT()
			oReport:PrintText(STR0019)	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
			oReport:ThinLine()
			lImpSMov := .T.
		Else
			aProdsMNT := aClone(NGProdMNT())
			If aScan(aProdsMNT, {|x| AllTrim(x) == AllTrim(SB1->B1_COD) }) == 0
				oReport:PrintText(STR0019)	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
				oReport:ThinLine()
				lImpSMov := .T.
			EndIf
		EndIf	
	EndIf

	oSection1:Finish()
	oSection2:Finish()
	If !lImpSMov .And. lImpS3
		oSection3:Finish()				
	Endif	
EndDo
dbSelectArea(cAliasTop)

If !Empty(aGrupos)
	oReport:SkipLine()    
	oReport:PrintText(STR0020) //"R E S U M O"
	oReport:SkipLine()    
	dbSelectArea("SX5")
	For i:=1 to Len(aGrupos)
		dbSeek(xFilial("SX5")+"02"+aGrupos[i][1])
		oReport:PrintText(X5Descri(),oReport:Row())
		oReport:PrintText(TransForm(aGrupos[i][2],cPicD1Cust),oReport:Row(),oSection3:Cell('nENTCus'):ColPos())														
		oReport:PrintText(TransForm(aGrupos[i][3],cPicD2Cust),oReport:Row(),oSection3:Cell('nSAICus'):ColPos())
		oReport:PrintText(TransForm(aGrupos[i][4],cPicB2Tot ),oReport:Row(),oSection3:Cell('nSALDCus'):ColPos())			
		oReport:SkipLine()    
	Next i
EndIf	

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Impressao de Termos Abertura e Encerramento                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lImpTermos // Impressao dos Termos

	If !lImpLivro 
		oReport:HideHeader() 
		oReport:HideFooter() 
		oReport:HideParamPage()
	Endif

	cArqAbert:=GetMv("MV_LMOD3AB")
	cArqEncer:=GetMv("MV_LMOD3EN")

	dbSelectArea("SM0")
	aVariaveis:={}

	For i:=1 to FCount()
		If FieldName(i)=="M0_CGC"
			AADD(aVariaveis,{FieldName(i),Transform(FieldGet(i),"@R 99.999.999/9999-99")})
		Else
			If FieldName(i)=="M0_NOME"
				Loop
			EndIf
			AADD(aVariaveis,{FieldName(i),FieldGet(i)})
		EndIf
	Next

	dbSelectArea("SX1")
	dbSeek(PADR("MTR910",nTamSX1)+"01")

	While SX1->X1_GRUPO==PADR("MTR910",nTamSX1)
		AADD(aVariaveis,{Rtrim(Upper(X1_VAR01)),&(X1_VAR01)})
		dbSkip()
	EndDo

	If !File(cArqAbert)
		aSavSet:=__SetSets()
		//Editor de Termos de Livros
		cArqAbert:=CFGX024(,OemToAnsi(STR0021))		//" Edi‡„o do Termo de Abertura "
		__SetSets(aSavSet)
		Set(24,Set(24),.t.)
	EndIf

	If !File(cArqEncer)
		aSavSet:=__SetSets()
		// Editor de Termos de Livros
		cArqEncer:=CFGX024(,OemToAnsi(STR0022)) 		//" Edi‡„o do Termo de Encerramento "
		__SetSets(aSavSet)
		Set(24,Set(24),.t.)
	EndIf

	cDriver:=aDriver[4]
    oReport:HideHeader()
	If cArqAbert#NIL
		oReport:EndPage()
		ImpTerm(cArqAbert,aVariaveis,&cDriver,,,.T.,oReport)
	EndIf

	If cArqEncer#NIL
		oReport:EndPage()
		ImpTerm(cArqEncer,aVariaveis,&cDriver,,,.T.,oReport)
	EndIf

EndIf

Return NIL
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³MATR910R3 ³ Autor ³ Paulo Boschetti       ³ Data ³ 11.11.92 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Kardex fisico - financeiro (Antigo)                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³         ATUALIZACOES SOFRIDAS DESDE A CONSTRU€AO INICIAL.             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Programador ³ Data   ³ BOPS ³  Motivo da Alteracao                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Rodrigo     ³24/06/98³XXXXXX³Acerto no tamanho do documento para 12    ³±±
±±³            ³        ³      ³posicoes                                  ³±±
±±³Rodrigo Sart³05/11/98³XXXXXX³ Acerto p/ Bug Ano 2000                   ³±±
±±³Bruno Sobies³18/12/98³Melhor³Exclucao impressao do CF nas localizacoes ³±±
±±³Rodrigo Sart³18/01/99³08994A³Inclusao da pergunta Lista p/ NumSeq/Calc ³±±
±±³Cesar       ³25/03/99³20051A³Alteracao do Lay-Out p/ Sair #OP Completa ³±±
±±³Patricia Sal|24/11/99³25325A³Acerto das pictures.                      ³±±
±±³Paulo August³07/12/99³Melhor³Acerto do Lay-Out para o Chile            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Marcos Hirak³17/05/04³XXXXXX³Imprimir B1_CODITE quando for gestao de   ³±±
±±³            ³        ³      ³Concessionarias ( MV_VEICULO = "S").      ³±±
±±³            ³        ³      ³                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function Matr910R3()
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Define Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
LOCAL cDesc1    := STR0001	//"Este programa emitir  uma rela‡„o com as movimenta‡”es"
LOCAL cDesc2    := STR0002	//"dos produtos Selecionados,Ordenados por Dia."
LOCAL cDesc3    := ""
LOCAL titulo    := OemToAnsi(STR0003)	//"Kardex Fisico-Financeiro (DIA)"
LOCAL wnrel     := "MATR910"
LOCAL Tamanho   := "G"
LOCAL cString   := "SB1"
LOCAL lRet		:= .T.
LOCAL nTamSX1   := Len(SX1->X1_GRUPO)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis tipo Local para SIGAVEI, SIGAPEC e SIGAOFI         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
LOCAL aArea1	:= Getarea()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis tipo Private para SIGAVEI, SIGAPEC e SIGAOFI       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PRIVATE lVEIC   := UPPER(GETMV("MV_VEICULO"))=="S"
PRIVATE aSB1Cod := {}
PRIVATE aSB1Ite := {}
PRIVATE nCOL1	:= 0

PRIVATE aOrd    := {OemToAnsi(STR0004),OemToAnsi(STR0005)}		//" Codigo Produto "###" Tipo do Produto"
PRIVATE aReturn := { OemToAnsi(STR0006), 1,OemToAnsi(STR0007), 1, 2, 1, "",1 }		//"Zebrado"###"Administracao"
PRIVATE aLinha  := { },nLastKey := 0
PRIVATE cPerg   := "MTR910"
PRIVATE bBloco  := { |nV,nX| Trim(nV)+IIf(Valtype(nX)='C',"",Str(nX,1)) }
PRIVATE aDriver := ReadDriver()
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se utiliza custo unificado por Empresa/Filial       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PRIVATE lCusUnif := A330CusFil()

Pergunte("MTR910",.F.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis utilizadas para parametros                         ³
//³ mv_par01        // Do produto                                ³
//³ mv_par02        // Ate o produto                             ³
//³ mv_par03        // Do tipo                                   ³
//³ mv_par04        // Ate o tipo                                ³
//³ mv_par05        // Da data                                   ³
//³ mv_par06        // Ate a data                                ³
//³ mv_par07        // Lista produtos s/movim                    ³
//³ mv_par08        // Qual Local (almoxarifado)                 ³
//³ mv_par09        // (D)ocumento/(S)equencia                   ³
//³ mv_par10        // Saldo a considerar : Atual / Fechamento   ³
//³ mv_par11        // Moeda Selecionada (1 a 5)                 ³
//³ mv_par12        // Pagina Inicial                            ³
//³ mv_par13        // Qtd de Paginas                            ³
//³ mv_par14        // Nr do Livro                               ³
//³ mv_par15        // Livro/Livro+termos/Termos                 ³
//³ mv_par16        // Seq.de Digitacao /Calculo                 ³
//³ mv_par17        // Lista Transf Locali (Sim/Nao)             ³
//³ mv_par18        // Do Grupo                                  ³
//³ mv_par19        // Ate o Grupo                               ³
//³ mv_par20        // Prods com Saldo Zero - (Lista/Nao Lista)  ³
//³ mv_par21        // Prods com Saldo Neg. - (Lista/Nao Lista)  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Envia controle para a funcao SETPRINT                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

wnrel:=SetPrint(cString,wnrel,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.F.,aOrd,.f.,Tamanho)

If nLastKey = 27
	dbClearFilter()
	lRet := .F.
EndIf

If lRet

	SetDefault(aReturn,cString)

	If nLastKey = 27
		dbClearFilter()
		lRet := .F.
	EndIf
    
	If lRet
		RptStatus({|lEnd| R910Imp(@lEnd,wnRel,tamanho,titulo)},titulo)
	EndIf

EndIf		

Return NIL

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ R910IMP  ³ Autor ³ Rodrigo de A. Sartorio³ Data ³ 16.11.95 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Chamada do Relatorio                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ R910Imp(ExpL1,ExpC1,ExpC2,ExpC3)		                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpL1 = var. p/ controle de interrupcao pelo usuario 	    ³±±
±±³          ³ ExpC1 = codigo do relatorio                                ³±±
±±³          ³ ExpC2 = codigo ref. ao tamanho do relatorio (P/M/G)        ³±±
±±³          ³ ExpC3 = titulo do relatorio                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATR910			                                              ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function R910Imp(lEnd,WnRel,tamanho,titulo)
Static lIxbConTes   := NIL
LOCAL aDadosTran:={},lContinua := .F.
LOCAL nTipo     := 0
LOCAL nTam      :=18
LOCAL cProdAnt  := ""
LOCAL cLocalAnt := ""
LOCAL nCusMed   := 0
LOCAL lFirst1   := .T.
LOCAL aSalAtu   := { 0,0,0,0,0,0,0 }
Local aSalAlmox := {}
LOCAL nEntrada  := 0, nSaida  :=0
LOCAL nCEntrada := 0, nCSaida :=0
LOCAL nGEntrada := 0, nGSaida :=0
LOCAL nRec1,nRec2,nRec3,nSavRec,dCntData
LOCAL cPicB2Qt  := PesqPictQt("B2_QATU" ,18)
LOCAL cPicB2Qt2 := PesqPictQt("B2_QTSEGUM" ,18)
LOCAL cPicD1Qt  := PesqPict("SD1","D1_QUANT" ,18)
LOCAL cPicD2Qt  := PesqPict("SD2","D2_QUANT" ,18)
LOCAL cPicD3Qt  := PesqPict("SD3","D3_QUANT" ,18)
LOCAL cPicB2Tot := PesqPictQt("B2_VATU1",18)
LOCAL cPicB2Cust:= PesqPict("SB2","B2_CM"+Str(mv_par11,1),18)
LOCAL cPicD1Cust:= PesqPict("SD1","D1_CUSTO"+IIF(mv_par11 == 1 ,"",Str(mv_par11,1)),18)
LOCAL cPicD2Cust:= PesqPict("SD2","D2_CUSTO"+Str(mv_par11,1),18)
LOCAL cPicD3Cust:= PesqPict("SD3","D3_CUSTO"+Str(mv_par11,1),18)
LOCAL lDev  // Flag que indica se nota ‚ devolu‡ao (.T.) ou nao (.F.)
LOCAL cCusto, lImpLivro, lImpTermos, cCond1, cCond2
LOCAL nAcho,i,aGrupos:={},cAlias
LOCAL cTRBSD1	:= CriaTrab(,.f.)
LOCAL cTRBSD2	:= Subs(cTrbSD1,1,7)+"A"
LOCAL cTRBSD3	:= Subs(cTrbSD1,1,7)+"B"
LOCAL nInd,cIndice	:="",cCampo1,cCampo2,cCampo3,cCampo4
LOCAL cNumSeqTr := "" , nRegTr := 0
LOCAL cSeqIni 	:= Replicate("z",6)
LOCAL nTotRegs  := 0
// Indica se esta listando relatorio do almox. de processo
LOCAL lLocProc:= mv_par08 == GetMv("MV_LOCPROC")
// Indica se deve imprimir movimento invertido (almox. de processo)
LOCAL lInverteMov :=.F.
LOCAL lPriApropri :=.T.

Local nTamSX1 := Len(SX1->X1_GRUPO)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se existe ponto de entrada                          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
LOCAL lTesNEst := .F.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Codigo do produto importado - NAO DEVE SER LISTADO           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
LOCAL cProdImp := GETMV("MV_PRODIMP")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis tipo Local para SIGAVEI, SIGAPEC e SIGAOFI         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
LOCAL cArq1 := ""
LOCAL nInd1 := 0

LOCAL cAliasTop:="KARDEXSQL"

LOCAL nRecTrf1 := 0
LOCAL nRecTrf2 := 0
LOCAL aRecTRF  := {}

LOCAL cQueryB1A:= "" 
LOCAL cQueryB1B:= "" 
LOCAL cQueryB1C:= "" 
LOCAL cQueryB1D:= "" 

LOCAL cProdMNT := GetMv("MV_PRODMNT")
LOCAL cProdTER := GetMv("MV_PRODTER")
Local aProdsMNT := {}
Local nX
Local lWmsNew	:= SuperGetMv("MV_WMSNEW",.F.,.F.)
Local lD3Servi	:= IIF(lWmsNew,.F.,GetMV('MV_D3SERVI',.F.,'N')=='N')

cProdMNT := cProdMNT + Space(15-Len(cProdMNT))
cProdTER := cProdTER + Space(15-Len(cProdTER))

If	!lVEIC
	cQueryB1A:= " AND SB1.B1_COD >= '"+mv_par01+"' AND SB1.B1_COD <= '"+mv_par02+"'"
	cQueryB1B:= " AND SB1.B1_COD = SB1EXS.B1_COD"
	cQueryB1C:= " SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_TIPO >= '"+mv_par03+"' AND SB1.B1_TIPO <= '"+mv_par04+"' AND"
	cQueryB1D:= " SB1EXS.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1EXS.B1_COD >= '"+mv_par01+"' AND SB1EXS.B1_COD <= '"+mv_par02+"' AND SB1EXS.B1_TIPO >= '"+mv_par03+"' AND SB1EXS.B1_TIPO <= '"+mv_par04+"' AND"
Else
	cQueryB1A:= " AND SB1.B1_CODITE >= '"+mv_par01+"' AND SB1.B1_CODITE <= '"+mv_par02+"'"
	cQueryB1B:= " AND SB1.B1_COD = SB1EXS.B1_COD"
	cQueryB1C:= " SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_TIPO >= '"+mv_par03+"' AND SB1.B1_TIPO <= '"+mv_par04+"' AND"
	cQueryB1D:= " SB1EXS.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1EXS.B1_CODITE >= '"+mv_par01+"' AND SB1EXS.B1_CODITE <= '"+mv_par02+"' AND SB1EXS.B1_TIPO >= '"+mv_par03+"' AND SB1EXS.B1_TIPO <= '"+mv_par04+"' AND"
EndIf	

cQueryB1C      += " SB1.B1_GRUPO >= '"+mv_par18+"' AND SB1.B1_GRUPO <= '"+mv_par19+"' AND SB1.B1_COD <> '"+cProdimp+"' AND "
cQueryB1C      += " SB1.D_E_L_E_T_=' '"
cQueryB1D      += " SB1EXS.B1_GRUPO >= '"+mv_par18+"' AND SB1EXS.B1_GRUPO <= '"+mv_par19+"' AND SB1EXS.B1_COD <> '"+cProdimp+"' AND "
cQueryB1D      += " SB1EXS.D_E_L_E_T_=' '"

lIxbConTes := IF(lIxbConTes == NIL,ExistBlock("MTAAVLTES"),lIxbConTes)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se utiliza custo unificado por empresa              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
lCusUnif:=lCusUnif .And. mv_par08 == Repl("*",TamSX3("B2_LOCAL")[1])

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis utilizadas para Impressao do Cabecalho e Rodape    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PRIVATE cbtxt := SPACE(10)
PRIVATE cbcont:= 0
PRIVATE li    := 80
PRIVATE m_pag := mv_par12

PRIVATE cabec1  := STR0008+IIF(mv_par09 $ "Dd", STR0009,STR0010) +iif(cPaisLoc<>"CHI",STR0011,STR0033)		//"    OPERACAO      "###"   DOCUMENTO   "###"   SEQUENCIA   "###" |               E  N  T  R  A  D  A  S             |         CUSTO MEDIO   |                  S  A  I  D  A  S                |                   S   A   L   D   O             |P.V.,FOR,"
PRIVATE cabec2  := IIF(cPaisLoc == "CHI",STR0032,STR0012)
titulo  := STR0013+mv_par08		//"KARDEX FISICO-FINANCEIRO (DIA) L O C A L :"

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Inicializa os codigos de caracter Comprimido/Normal da impressora ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
nTipo  := IIF(aReturn[4]==1,15,18)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Adiciona a ordem escolhida ao titulo do relatorio          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If Type("NewHead")#"U"
	NewHead += STR0014+AllTrim(aOrd[aReturn[8]])+STR0015+AllTrim(GetMv("MV_SIMB"+Ltrim(Str(mv_par11))))+")"		//" (Por "###" ,em "
Else
	Titulo  += STR0014+AllTrim(aOrd[aReturn[8]])+STR0015+AllTrim(GetMv("MV_SIMB"+Ltrim(Str(mv_par11))))+")"		//" (Por "###" ,em "
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Adiciona seq de impressao escolhida ao titulo do relatorio ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
titulo  +=IIf(mv_par16==1,OemToAnsi(STR0030),OemToAnsi(STR0031))	// "(SEQUENCIA)"###"(CALCULO)"

dbSelectArea("SB2")
dbSetOrder(1)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Impressao de Termo / Livro                                   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Do Case
	Case mv_par15==1 ; lImpLivro:=.t. ; lImpTermos:=.f.
	Case mv_par15==2 ; lImpLivro:=.t. ; lImpTermos:=.t.
	Case mv_par15==3 ; lImpLivro:=.f. ; lImpTermos:=.t.
EndCase

If lImpLivro

	dbSelectArea("SD1")           // Itens de Entrada
	nTotRegs += LastRec()

	dbSelectArea("SD2")           // Itens de Saida
	nTotRegs += LastRec()

	dbSelectArea("SD3")           // movimentacoes internas (producao/requisicao/devolucao)
	nTotRegs += LastRec()

	dbSelectArea("SB2")			  // Saldos em estoque
	dbSetOrder(1)
	nTotRegs += LastRec()

	//                            1,                 2,               3,        4,           5,          6,            7,                 8,              9,        10,      11,                 12,              13,            14,                 15,                 16,              17,   18,   19                    20,          21,       22,            23,      24
	// cQueryD1:= "SELECT 'SD1' ARQ,SB1.B1_COD PRODUTO,SB1.B1_TIPO TIPO,SB1.B1_UM,SB1.B1_GRUPO,SB1.B1_DESC,SB1.B1_POSIPI,D1_SEQCALC SEQCALC,D1_DTDIGIT DATA,D1_TES TES,D1_CF CF,D1_NUMSEQ SEQUENCIA,D1_DOC DOCUMENTO,D1_SERIE SERIE,D1_QUANT QUANTIDADE,D1_QTSEGUM QUANT2UM,D1_LOCAL ARMAZEM,'' PROJETO,'' OP,'' CC,D1_FORNECE FORNECEDOR,D1_LOJA LOJA,'' PEDIDO,D1_TIPO TIPONF,D1_CUSTO"

	cQuerySub:= "SELECT 1 "

	cQueryD1P := "SELECT 'SD1' ARQ"				// 01
	cQueryD1P += ", SB1.B1_COD PRODUTO"			// 02
	cQueryD1P += ", SB1.B1_TIPO TIPO"			// 03
	cQueryD1P += ", SB1.B1_UM"					// 04
	cQueryD1P += ", SB1.B1_GRUPO"				// 05
	cQueryD1P += ", SB1.B1_DESC"				// 06
	cQueryD1P += ", SB1.B1_POSIPI"				// 07
	cQueryD1P += ", D1_SEQCALC SEQCALC"			// 08
	cQueryD1P += ", D1_DTDIGIT DATA"			// 09
	cQueryD1P += ", D1_TES TES"					// 10
	cQueryD1P += ", D1_CF CF"					// 11
	cQueryD1P += ", D1_NUMSEQ SEQUENCIA"		// 12
	cQueryD1P += ", D1_DOC DOCUMENTO"			// 13
	cQueryD1P += ", D1_SERIE SERIE"				// 14
	cQueryD1P += ", D1_QUANT QUANTIDADE"		// 15
	cQueryD1P += ", D1_QTSEGUM QUANT2UM"		// 16
	cQueryD1P += ", D1_LOCAL ARMAZEM"			// 17
	cQueryD1P += ", '' PROJETO"					// 18
	cQueryD1P += ", '' OP"						// 19
	cQueryD1P += ", '' CC"						// 20
	cQueryD1P += ", D1_FORNECE FORNECEDOR"		// 21
	cQueryD1P += ", D1_LOJA LOJA"				// 22
	cQueryD1P += ", '' PEDIDO"					// 23
	cQueryD1P += ", D1_TIPO TIPONF"				// 24
	cQueryD1P += ", D1_CUSTO"					// 25
	// COLOCA A MOEDA DO CUSTO
	If mv_par11 > 1
		cQueryD1P += Str(mv_par11,1,0)			// 25
	EndIf
	cQueryD1P += " CUSTO"
	cQueryD1P += ", '' TRT" 					// 26
	IF lVEIC
		cQueryD1P += ", SB1.B1_CODITE B1_CODITE"	// 27
	ENDIF
	cQueryD1P += ", D1_LOTECTL LOTE"	    	// 28
	cQueryD1P += ", SD1.R_E_C_N_O_ NRECNO"		// 29

	cQueryD1 := " FROM "
	// cQueryD1 += RetSqlName("SB1") + " SB1 , "+ RetSqlName("SD1")+ " SD1 , "+ RetSqlName("SF4")+" SF4 "
	cQueryD1 += RetSqlName("SB1") + " SB1"
	cQueryD1 += (", " + RetSqlName("SD1")+ " SD1 ")
	cQueryD1 += (", " + RetSqlName("SF4")+ " SF4 ")
	cQueryD1 += " WHERE SB1.B1_COD = D1_COD"
	cQueryD1 += (" AND D1_FILIAL = '"+xFilial("SD1")+"'")
	// cQueryD1 += " AND F4_FILIAL = '"+xFilial("SF4")+"' AND SD1.D1_TES = F4_CODIGO AND F4_ESTOQUE = 'S'"
	cQueryD1 += (" AND F4_FILIAL = '" + xFilial("SF4") + "'")
	cQueryD1 += (" AND SD1.D1_TES = F4_CODIGO AND F4_ESTOQUE = 'S'")
	// cQueryD1 += " AND D1_DTDIGIT >= '"+DTOS(mv_par05)+"' AND D1_DTDIGIT <= '"+DTOS(mv_par06)+"'"
	cQueryD1 += (" AND D1_DTDIGIT >= '" + DTOS(mv_par05) + "'")
	cQueryD1 += (" AND D1_DTDIGIT <= '" + DTOS(mv_par06) + "'")
	cQueryD1 +=  " AND D1_ORIGLAN <> 'LF'"
	If !lCusUnif
		cQueryD1 += " AND D1_LOCAL = '" + mv_par08 + "'"
	EndIf
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Não imprimir o produto MANUTENCAO (MV_PRDMNT) qdo integrado com MNT.       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If MTR910IsMNT() 
		aProdsMNT := aClone(NGProdMNT())
		For nX := 1 To Len(aProdsMNT)
			cQueryD1 += " AND SB1.B1_COD <> '" + aProdsMNT[nX] + "'"
		Next nX
	EndIf	
	cQueryD1 += " AND SD1.D_E_L_E_T_=' ' AND SF4.D_E_L_E_T_=' '"

	// cQueryD2 := " SELECT 'SD2',SB1.B1_COD,SB1.B1_TIPO,SB1.B1_UM,SB1.B1_GRUPO,SB1.B1_DESC,SB1.B1_POSIPI,D2_SEQCALC,D2_EMISSAO,D2_TES,D2_CF,D2_NUMSEQ,D2_DOC,D2_SERIE,D2_QUANT,D2_QTSEGUM,D2_LOCAL,'','',D2_CLIENTE,D2_LOJA,D2_PEDIDO,D2_TIPO,D2_CUSTO"
	cQueryD2P := " SELECT 'SD2'"
	cQueryD2P += ", SB1.B1_COD"
	cQueryD2P += ", SB1.B1_TIPO"
	cQueryD2P += ", SB1.B1_UM"
	cQueryD2P += ", SB1.B1_GRUPO"
	cQueryD2P += ", SB1.B1_DESC"
	cQueryD2P += ", SB1.B1_POSIPI"
	cQueryD2P += ", D2_SEQCALC"
	cQueryD2P += ", D2_EMISSAO"
	cQueryD2P += ", D2_TES"
	cQueryD2P += ", D2_CF"
	cQueryD2P += ", D2_NUMSEQ"
	cQueryD2P += ", D2_DOC"
	cQueryD2P += ", D2_SERIE"
	cQueryD2P += ", D2_QUANT"
	cQueryD2P += ", D2_QTSEGUM"
	cQueryD2P += ", D2_LOCAL"
	cQueryD2P += ", ''"
	cQueryD2P += ", ''"
	cQueryD2P += ", ''"
	cQueryD2P += ", D2_CLIENTE"
	cQueryD2P += ", D2_LOJA"
	cQueryD2P += ", D2_PEDIDO"
	cQueryD2P += ", D2_TIPO"
	cQueryD2P += ", D2_CUSTO"
	// COLOCA A MOEDA DO CUSTO
	cQueryD2P += Str(mv_par11,1,0)
	cQueryD2P += ", ''"
	If lVEIC
		cQueryD2P += ", SB1.B1_CODITE"	
	EndIf
	cQueryD2P += ", D2_LOTECTL"	
	cQueryD2P += ", SD2.R_E_C_N_O_ SD2RECNO"	// 29

	cQueryD2 := " FROM "
	cQueryD2 += RetSqlName("SB1") + " SB1 , "+ RetSqlName("SD2")+ " SD2 , "+ RetSqlName("SF4")+" SF4 "
	cQueryD2 += " WHERE SB1.B1_COD = D2_COD AND D2_FILIAL = '"+xFilial("SD2")+"'"
	cQueryD2 += " AND F4_FILIAL = '"+xFilial("SF4")+"' AND SD2.D2_TES = F4_CODIGO AND F4_ESTOQUE = 'S'"
	cQueryD2 += " AND D2_EMISSAO >= '"+DTOS(mv_par05)+"' AND D2_EMISSAO <= '"+DTOS(mv_par06)+"'"
	cQueryD2 += " AND D2_ORIGLAN <> 'LF'"
	If !lCusUnif
		cQueryD2 += " AND D2_LOCAL = '"+mv_par08+"'"
	EndIf
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Não imprimir o produto MANUTENCAO (MV_PRDMNT) qdo integrado com MNT.       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If MTR910IsMNT() 
		aProdsMNT := aClone(NGProdMNT())
		For nX := 1 To Len(aProdsMNT)
			cQueryD2 += " AND SB1.B1_COD <> '" + aProdsMNT[nX] + "'"
		Next nX
	EndIf	
	cQueryD2 += " AND SD2.D_E_L_E_T_=' ' AND SF4.D_E_L_E_T_=' '"

	// cQueryD3 := " SELECT 'SD3',SB1.B1_COD,SB1.B1_TIPO,SB1.B1_UM,SB1.B1_GRUPO,SB1.B1_DESC,SB1.B1_POSIPI,D3_SEQCALC,D3_EMISSAO,D3_TM,D3_CF,D3_NUMSEQ,D3_DOC,'',D3_QUANT,D3_QTSEGUM,D3_LOCAL,D3_OP,D3_CC,'','','','',D3_CUSTO"
	cQueryD3P := " SELECT 'SD3'"
	cQueryD3P += ", SB1.B1_COD"
	cQueryD3P += ", SB1.B1_TIPO"
	cQueryD3P += ", SB1.B1_UM"
	cQueryD3P += ", SB1.B1_GRUPO"
	cQueryD3P += ", SB1.B1_DESC"
	cQueryD3P += ", SB1.B1_POSIPI"
	cQueryD3P += ", D3_SEQCALC"
	cQueryD3P += ", D3_EMISSAO"
	cQueryD3P += ", D3_TM"
	cQueryD3P += ", D3_CF"
	cQueryD3P += ", D3_NUMSEQ"
	cQueryD3P += ", D3_DOC"
	cQueryD3P += ", ''"
	cQueryD3P += ", D3_QUANT"
	cQueryD3P += ", D3_QTSEGUM"
	cQueryD3P += ", D3_LOCAL"
	cQueryD3P += ", D3_PROJPMS"
	cQueryD3P += ", D3_OP"
	cQueryD3P += ", D3_CC"
	cQueryD3P += ", ''"
	cQueryD3P += ", ''"
	cQueryD3P += ", ''"
	cQueryD3P += ", ''"
	cQueryD3P += ", D3_CUSTO"
	// COLOCA A MOEDA DO CUSTO
	cQueryD3P += Str(mv_par11,1,0)
	cQueryD3P += ", D3_TRT"
	If lVEIC
		cQueryD3P += ", SB1.B1_CODITE"	
	EndIf
	cQueryD3P += ", D3_LOTECTL"	
	cQueryD3P += ", SD3.R_E_C_N_O_ SD3RECNO"		// 29

	cQueryD3 := " FROM "
	cQueryD3 += RetSqlName("SB1") + " SB1 , "+ RetSqlName("SD3")+ " SD3 "
	cQueryD3 += " WHERE SB1.B1_COD = D3_COD AND D3_FILIAL = '"+xFilial("SD3")+"' "
	cQueryD3 += " AND D3_EMISSAO >= '"+DTOS(mv_par05)+"' AND D3_EMISSAO <= '"+DTOS(mv_par06)+"'"
	If SuperGetMV('MV_D3ESTOR', .F., 'N') == 'N'
		cQueryD3 += " AND D3_ESTORNO <> 'S'"
	EndIf
	If lD3Servi .And. IntDL()
		cQueryD3 += " AND ( (D3_SERVIC = '   ') OR (D3_SERVIC <> '   ' AND D3_TM <= '500')  "
		cQueryD3 += " OR  (D3_SERVIC <> '   ' AND D3_TM > '500' AND D3_LOCAL ='"+SuperGetMV('MV_CQ', .F., '98')+"') )"
	EndIf					
	If !lCusUnif .And. !lLocProc
		cQueryD3 += " AND D3_LOCAL = '"+mv_par08+"'"
	EndIf
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Não imprimir o produto MANUTENCAO (MV_PRDMNT) qdo integrado com MNT.       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If MTR910IsMNT() 
		aProdsMNT := aClone(NGProdMNT())
		For nX := 1 To Len(aProdsMNT)
			cQueryD3 += " AND SB1.B1_COD <> '" + aProdsMNT[nX] + "'"
		Next nX
	EndIf	
	cQueryD3 += " AND SD3.D_E_L_E_T_=' '"

	// cQuery := cQueryD1 + cQueryB1A + " AND " + cQueryB1C + " UNION " + cQueryD2 + cQueryB1A + " AND " + cQueryB1C+" UNION "+cQueryD3+cQueryB1A+" AND "+cQueryB1C
	cQuery := cQueryD1P + cQueryD1
	cQuery += cQueryB1A
	cQuery += " AND "
	cQuery += cQueryB1C
	cQuery += " UNION "
	cQuery += cQueryD2P + cQueryD2
	cQuery += cQueryB1A
	cQuery += " AND "
	cQuery += cQueryB1C
	cQuery += " UNION "
	cQuery += cQueryD3P + cQueryD3
	cQuery += cQueryB1A
	cQuery += " AND "
	cQuery += cQueryB1C
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ So inclui as condicoes a seguir qdo lista produtos sem ³
	//³ movimento                                              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If mv_par07 == 1
		// cQuery2:= cQueryD1+cQueryB1B+" AND "+cQueryB1C+" UNION "+cQueryD2+cQueryB1B+" AND "+cQueryB1C+" UNION "+cQueryD3+cQueryB1B+" AND "+cQueryB1C
		cQuery2 := " AND NOT EXISTS (" + cQuerySub + cQueryD1
		cQuery2 += cQueryB1B
		cQuery2 += " AND "
		cQuery2 += cQueryB1C
		cQuery2 += ") AND NOT EXISTS ("
		cQuery2 += cQuerySub + cQueryD2
		cQuery2 += cQueryB1B
		cQuery2 += " AND "
		cQuery2 += cQueryB1C
		cQuery2 += ") AND NOT EXISTS ("
		cQuery2 += cQuerySub + cQueryD3
		cQuery2 += cQueryB1B
		cQuery2 += " AND "
		cQuery2 += cQueryB1C + ")"
		//                                       1,            2,             3,           4,              5,             6,               7, 8, 9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24
		// cQuery += " UNION SELECT 'SB1',SB1EXS.B1_COD,SB1EXS.B1_TIPO,SB1EXS.B1_UM,SB1EXS.B1_GRUPO,SB1EXS.B1_DESC,SB1EXS.B1_POSIPI,'','','','','','','',0 , 0,'','','','','','','',0 "
		cQuery += " UNION SELECT 'SB1'"		// 01
		cQuery += ", SB1EXS.B1_COD"			// 02
		cQuery += ", SB1EXS.B1_TIPO"		// 03
		cQuery += ", SB1EXS.B1_UM"			// 04
		cQuery += ", SB1EXS.B1_GRUPO"		// 05
		cQuery += ", SB1EXS.B1_DESC"		// 06
		cQuery += ", SB1EXS.B1_POSIPI"		// 07
		cQuery += ", ''"					// 08
		cQuery += ", ''"					// 09
		cQuery += ", ''"					// 10
		cQuery += ", ''"					// 11
		cQuery += ", ''"					// 12
		cQuery += ", ''"					// 13
		cQuery += ", ''"					// 14
		cQuery += ", 0"						// 15
		cQuery += ", 0"						// 16
		cQuery += ", ''"					// 17
		cQuery += ", ''"					// 18
		cQuery += ", ''"					// 19
		cQuery += ", ''"					// 20
		cQuery += ", ''"					// 21
		cQuery += ", ''"					// 22
		cQuery += ", ''"					// 23
		cQuery += ", ''"					// 24
		cQuery += ", 0"						// 25
		cQuery += ", ''"					// 26
		If lVEIC
			cQuery += ", SB1EXS.B1_CODITE CODITE"	// 27
		EndIf
		cQuery += ", ''"					// 28
		cQuery += ", 0"						// 29

		cQuery += " FROM "+RetSqlName("SB1") + " SB1EXS WHERE"
		cQuery += cQueryB1D
		cQuery += cQuery2
	EndIf
	If aReturn[8]==1
		If ! lVEIC
			cQuery += " ORDER BY 2,9,"
		Else
			cQuery += " ORDER BY 27, 9,"
		EndIf	
	ElseIf aReturn[8] == 2
		If ! lVEIC
			cQUery += " ORDER BY 3,2,9,"
		Else
			cQuery += " ORDER BY 3, 27, 9,"
		EndIf	
	EndIf
	If mv_par16 == 1
//				cQuery += "17,12"+IIf(lVEIC,',29',',28')
		cQuery += "12"+IIf(lVEIC,',29',',28')
	Else
		If lCusUnif
			cQuery+="8,12"+IIf(lVEIC,',29',',28')
		Else
//					cQuery+="17,8,12"+IIf(lVEIC,',29',',28')
			cQuery+="8"+IIf(lVEIC,',29',',28')
		EndIf
	EndIf
	cQuery:=ChangeQuery(cQuery)
	MsAguarde({|| dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cAliasTOP,.F.,.T.)},STR0029)
	dbSelectArea(cAliasTop)
	SetRegua(nTotRegs)
	While !Eof()
		If lEnd
			@PROW()+1,001 PSay STR0016		//"CANCELADO PELO OPERADOR"
			Exit
		EndIf
		IncRegua()
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Se nao encontrar no arquivo de saldos ,nao lista ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("SB2")
		If !dbSeek(xFilial("SB2")+(cAliasTop)->PRODUTO+If(lCusUnif,"",mv_par08))
			dbSelectArea(cAliasTop)
			dbSkip()
			Loop
		EndIf
		// Nao lista de saldo for igual a zero
		If mv_par20 == 2 .And. SB2->B2_QATU == 0
			dbSelectArea(cAliasTop)
			dbSkip()
			Loop
		EndIf
		// Nao lista de saldo for negativo
		If mv_par21 == 2 .And. SB2->B2_QATU < 0
			dbSelectArea(cAliasTop)
			dbSkip()
			Loop
		EndIf

		dbSelectArea(cAliasTop)
		cProdAnt  := (cAliasTop)->PRODUTO
		cLocalAnt := SB2->B2_LOCAL
		nEntrada:=nSaida:=0
		nCEntrada:=nCSaida:=0
		lFirst:=.F.

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Filtra Registros de Acordo com a Pasta  Filtro da Janela de Impressao  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !Empty(aReturn[7])
			dbSelectArea("SB1")
			dbSetOrder(1)
			If dbSeek(xFilial("SB1")+alltrim(cProdAnt))
				If !&(aReturn[7])
					dbSelectArea(cAliasTop)
					(cAliasTop)->(dbSkip())
					Loop
				EndIf
			Else
				dbSelectArea(cAliasTop)
				(cAliasTop)->(dbSkip())
				Loop
			EndIf
			dbSelectArea(cAliasTop)
		EndIf

		If li > 58
			cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Calcula o Saldo Inicial do Produto             ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If lCusUnif
			aArea:=GetArea()
			aSalAtu  := { 0,0,0,0,0,0,0 }
			dbSelectArea("SB2")
			dbSetOrder(1)
			MsSeek(cSeek:=xFilial("SB2")+(cAliasTOP)->PRODUTO)
			While !Eof() .And. B2_FILIAL+B2_COD == cSeek
				aSalAlmox := CalcEst((cAliasTOP)->PRODUTO,SB2->B2_LOCAL,mv_par05)
				For i:=1 to Len(aSalAtu)
					aSalAtu[i] += aSalAlmox[i]
				Next i
				dbSkip()
			End
			RestArea(aArea)
		Else
			aSalAtu := CalcEst((cAliasTOP)->PRODUTO,mv_par08,mv_par05)
		EndIf

		If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
			aGrupos[nAcho][4] += aSalAtu[mv_par11+1]
		Else
			AADD(aGrupos,{(cAliasTOP)->TIPO,0,0,aSalAtu[mv_par11+1]})
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Calcula o Custo Medio do Produto               ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If AsalAtu[1] > 0
			nCusmed := aSalAtu[mv_par11+1]/aSalAtu[1]
		ElseIf AsalAtu[1] == 0 .and. AsalAtu[mv_par11+1] == 0
			nCusMed := 0
		Else
			SB2->(dbSeek(xFilial("SB2") + (cAliasTOP)->PRODUTO + (cAliasTOP)->ARMAZEM))
			nCusmed := &("SB2->B2_CM" + Str(mv_par11,1))
		EndIf
		MR910ImpCb(aSalAtu,nCusMed,@Li,cPicB2Qt,cPicB2Cust, cAliasTop)
		lFirst1 := .F.

		While !Eof() .And. (cAliasTop)->PRODUTO = cProdAnt
			IncRegua()
			lContinua := .F.
			If Alltrim((cAliasTop)->ARQ) $ "SD1/SD2"
				lFirst:=.T.
				SF4->(dbSeek(xFilial("SF4")+(cAliasTop)->TES))
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Despreza Notas Fiscais Lancadas Pelo Modulo do Livro Fiscal  ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Executa ponto de entrada para verificar se considera TES que ³
				//³ NAO ATUALIZA saldos em estoque.                              ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If lIxbConTes .And. SF4->F4_ESTOQUE != "S"
					lTesNEst := ExecBlock("MTAAVLTES",.F.,.F.)
					lTesNEst := If(ValType(lTesNEst) # "L",.F.,lTesNEst)
				EndIf
				If SF4->F4_ESTOQUE != "S" .And. !lTesNEst
					dbSkip()
					Loop
				EndIf
			ElseIf Alltrim((cAliasTop)->ARQ) == "SD3"
				lFirst:=.T.
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Quando movimento ref apropr. indireta, so considera os         ³
				//³ movimentos com destino ao almoxarifado de apropriacao indireta.³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				lInverteMov:=.F.
				If (cAliasTop)->ARMAZEM != cLocalAnt .Or. lCusUnif
					If !(Substr((cAliasTop)->CF,3,1) == "3")
						If !lCusUnif
							dbSkip()
							Loop
						EndIf
					ElseIf lPriApropri
						lInverteMov:=.T.
					EndIf
				EndIf
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Caso seja uma transferencia de localizacao verifica se lista   ³
				//³ o movimento ou nao                                             ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If mv_par17 == 2 .And. Substr((cAliasTop)->CF,3,1) == "4"
					cNumSeqTr := (cAliasTOP)->(PRODUTO+SEQUENCIA+ARMAZEM)
					aDadosTran:={(cAliasTOP)->TES,(cAliasTOP)->QUANTIDADE,(cAliasTOP)->CUSTO,(cAliasTOP)->QUANT2UM,(cAliasTOP)->TIPO,;
						(cAliasTOP)->DATA,(cAliasTOP)->CF,(cAliasTOP)->SEQUENCIA,(cAliasTOP)->DOCUMENTO,(cAliasTOP)->PRODUTO,;
						(cAliasTOP)->OP,(cAliasTOP)->PROJETO,(cAliasTOP)->CC,(cAliasTOP)->ARQ}
					dbSkip()
					If (cAliasTOP)->(PRODUTO+SEQUENCIA+ARMAZEM) == cNumSeqTr
						dbSkip()
						Loop
					Else
						lContinua := .T.
						If li > 58
							cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
						EndIf
						If lFirst
							@Li ,000 PSay STOD(aDadosTran[6])
							@Li ,011 PSay aDadosTran[1]
							If ( cPaisLoc=="BRA" )
								@Li ,015 PSay allTrim(aDadosTran[7])
								If	lInverteMov
									@Li , 018 PSay "*"
								EndIf
							EndIf
							@Li , 020 PSay PadR(IIf(mv_par09 $ "Ss",aDadosTran[8],aDadosTran[9]),12)+" |"
						EndIf
						If aDadosTran[1] <= "500"
							@Li ,038 PSay aDadosTran[2] Picture cPicD3Qt
							@Li ,062 PSay aDadosTran[3] Picture cPicD3Cust
							@Li ,083 PSay "|"
							@Li ,085 PSay aDadosTran[3] / aDadosTran[2] Picture cPicB2Cust
							@Li ,104 PSay "|"
							nEntrada	  += aDadosTran[2]
							aSalAtu[1] += aDadosTran[2]
							nCEntrada  += aDadosTran[3]
							aSalAtu[mv_par11+1] += aDadosTran[3]
							aSalAtu[7] += aDadosTran[4]
							If (nAcho := ASCAN(aGrupos,{|x| aDadosTran[5] == x[1]})) > 0
								aGrupos[nAcho][2]+=aDadosTran[3]
								aGrupos[nAcho][4]+=aDadosTran[3]
							Else
								AADD(aGrupos,{aDadosTran[5],aDadosTran[3],0,aSalAtu[mv_par11+1]})
							EndIf
						Else
							@Li ,083 PSay "|"
							@Li ,085 PSay aDadosTran[3] / aDadosTran[2] Picture cPicB2Cust
							@Li ,104 PSay "|"
							@Li ,108 PSay aDadosTran[2] Picture cPicD3Qt
							@Li ,132 PSay aDadosTran[3] Picture cPicD3Cust
							nSaida	  += aDadosTran[2]
							aSalAtu[1] -= aDadosTran[2]
							nCSaida	  += aDadosTran[3]
							aSalAtu[mv_par11+1] -= aDadosTran[3]
							aSalAtu[7] -= aDadosTran[4]
							If (nAcho := ASCAN(aGrupos,{|x| aDadosTran[5] == x[1]})) > 0
								aGrupos[nAcho][3]+=aDadosTran[3]
								aGrupos[nAcho][4]-=aDadosTran[3]
							Else
								AADD(aGrupos,{aDadosTran[5],0,aDadosTran[3],-(aSalAtu[mv_par11+1])})
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf	
			If li > 58 .And. !lContinua
				cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
			EndIf
			If lFirst .And. !lContinua
				@Li ,000 PSay STOD(DATA)
				@Li ,011 PSay TES
				If ( cPaisLoc=="BRA" )
					@Li ,015 PSay allTrim(CF)
					If	lInverteMov
						@Li , 018 PSay "*"
					EndIf
				EndIf
				@Li , 020 PSay PadR(IIF(mv_par09 $ "Ss",SEQUENCIA,DOCUMENTO),12)+" |"
			EndIf

			Do Case
				Case Alltrim((cAliasTop)->ARQ) == "SD1" .And. !lContinua
					lDev:=MTR910Dev(cAliasTop)
					If (cAliasTOP)->TES <= "500" .And. !lDev
						@Li ,038 PSay (cAliasTOP)->QUANTIDADE Picture cPicD1Qt
						@Li ,062 PSay (cAliasTOP)->CUSTO Picture cPicD1Cust
						@Li ,083 PSay "|"
						If (cAliasTOP)->TIPONF != "C"
							@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
						EndIf
						@Li ,104 PSay "|"
						nEntrada   += (cAliasTOP)->QUANTIDADE
						aSalAtu[1] += (cAliasTOP)->QUANTIDADE
						nCEntrada  += (cAliasTOP)->CUSTO
						aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
						aSalAtu[7] += (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
						EndIf
					Else
						@Li ,083 PSay "|"
						If (cAliasTOP)->TIPONF != "C"
							@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
						EndIf
						@Li ,104 PSay "|"
						If lDev
							@Li ,108 PSay Space((nTam-1)-Len(Alltrim(Transform((cAliasTOP)->QUANTIDADE,cPicD1Qt))))+"("+Alltrim(Transform((cAliasTOP)->QUANTIDADE,cPicD1Qt))+")"
							cCusto:=Transform((cAliasTOP)->CUSTO,cPicD1Cust)
							@Li ,132 PSay Space((nTam-1)-Len(Alltrim(cCusto)))+"("+Alltrim(cCusto)+")"
							nSaida 	  -= (cAliasTOP)->QUANTIDADE
							aSalAtu[1] += (cAliasTOP)->QUANTIDADE
							nCSaida	  -=(cAliasTOP)->CUSTO
							aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
							aSalAtu[7] += (cAliasTOP)->QUANT2UM
							If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
								aGrupos[nAcho][3]-=(cAliasTOP)->CUSTO
								aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
							Else
								AADD(aGrupos,{(cAliasTOP)->TIPO,0,-((cAliasTOP)->CUSTO),aSalAtu[mv_par11+1]})
							EndIf
						Else
							@Li	,108 PSay (cAliasTOP)->QUANTIDADE Picture cPicD1Qt
							@Li ,132 PSay (cAliasTOP)->CUSTO Picture cPicD1Cust
							nSaida 	  += (cAliasTOP)->QUANTIDADE
							aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
							nCSaida	  +=(cAliasTOP)->CUSTO
							aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
							aSalAtu[7] -= (cAliasTOP)->QUANT2UM
							If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
								aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
								aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
							Else
								AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
							EndIf
						EndIf
					EndIf
				Case Alltrim((cAliasTop)->ARQ) = "SD2" .And. !lContinua
					lDev:=MTR910Dev(cAliasTop)
					If (cAliasTOP)->TES <= "500" .Or. lDev
						If lDev
							@Li ,038 PSay Space((nTam-1)-Len(Alltrim(Transform((cAliasTOP)->QUANTIDADE,cPicD2Qt))))+"("+Alltrim(Transform((cAliasTOP)->QUANTIDADE,cPicD2Qt))+")"
							cCusto:=Transform((cAliasTOP)->CUSTO,cPicD2Cust)
							@Li ,062 PSay Space((nTam-1)-Len(Alltrim(cCusto)))+"("+Alltrim(cCusto)+")"
							nEntrada   -= (cAliasTOP)->QUANTIDADE
							aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
							nCEntrada  -= (cAliasTOP)->CUSTO
							aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
							aSalAtu[7] -= (cAliasTOP)->QUANT2UM
							If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
								aGrupos[nAcho][2]-=(cAliasTOP)->CUSTO
								aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
							Else
								AADD(aGrupos,{(cAliasTOP)->TIPO,-((cAliasTOP)->CUSTO),0,-(aSalAtu[mv_par11+1])})
							EndIf
						Else
							@Li ,038 PSay (cAliasTOP)->QUANTIDADE Picture cPicD2Qt
							@Li ,062 PSay (cAliasTOP)->CUSTO Picture cPicD2Cust
							nEntrada   += (cAliasTOP)->QUANTIDADE
							aSalAtu[1] += (cAliasTOP)->QUANTIDADE
							nCEntrada  += (cAliasTOP)->CUSTO
							aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
							aSalAtu[7] += (cAliasTOP)->QUANT2UM
							If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
								aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
								aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
							Else
								AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
							EndIf
						EndIf
						@Li ,083 PSay "|"
						If (cAliasTOP)->TIPONF != "C"
							@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
						EndIf
						@Li ,104 PSay "|"
					Else
						@Li ,083 PSay "|"
						If (cAliasTOP)->TIPONF != "C"
							@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
						EndIf
						@Li ,104 PSay "|"
						@Li ,108 PSay (cAliasTOP)->QUANTIDADE Picture cPicD2Qt
						@Li ,132 PSay (cAliasTOP)->CUSTO Picture cPicD2Cust
						nSaida     += (cAliasTOP)->QUANTIDADE
						aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
						nCSaida	  +=  (cAliasTOP)->CUSTO
						aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
						aSalAtu[7] -= (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
						EndIf
					EndIf
				Case Alltrim((cAliasTop)->ARQ) == "SD3" .And. !lContinua
					If	lInverteMov
						If (cAliasTOP)->TES > "500"
							@Li ,038 PSay (cAliasTOP)->QUANTIDADE Picture cPicD3Qt
							@Li ,062 PSay (cAliasTOP)->CUSTO Picture cPicD3Cust
							@Li ,083 PSay "|"
							@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
							@Li ,104 PSay "|"
							nEntrada  += (cAliasTOP)->QUANTIDADE
							aSalAtu[1] += (cAliasTOP)->QUANTIDADE
							nCEntrada  +=  (cAliasTOP)->CUSTO
							aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
							aSalAtu[7] += (cAliasTOP)->QUANT2UM
							If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
								aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
								aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
							Else
								AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
							EndIf
						Else
							@Li ,083 PSay "|"
							@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
							@Li ,104 PSay "|"
							@Li ,108 PSay (cAliasTOP)->QUANTIDADE Picture cPicD3Qt
							@Li ,132 PSay (cAliasTOP)->CUSTO Picture cPicD3Cust
							nSaida	  += (cAliasTOP)->QUANTIDADE
							aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
							nCSaida	  += (cAliasTOP)->CUSTO
							aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
							aSalAtu[7] -= (cAliasTOP)->QUANT2UM
							If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
								aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
								aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
							Else
								AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
							EndIf
						EndIf 
						If lCusUnif
							lPriApropri:=.F.
						EndIf
					Else
						If (cAliasTOP)->TES <= "500"
							@Li ,038 PSay (cAliasTOP)->QUANTIDADE Picture cPicD3Qt
							@Li ,062 PSay (cAliasTOP)->CUSTO Picture cPicD3Cust
							@Li ,083 PSay "|"
							@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
							@Li ,104 PSay "|"
							nEntrada	  += (cAliasTOP)->QUANTIDADE
							aSalAtu[1] += (cAliasTOP)->QUANTIDADE
							nCEntrada  +=  (cAliasTOP)->CUSTO
							aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
							aSalAtu[7] += (cAliasTOP)->QUANT2UM
							If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
								aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
								aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
							Else
								AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
							EndIf
						Else
							@Li ,083 PSay "|"
							@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
							@Li ,104 PSay "|"
							@Li ,108 PSay (cAliasTOP)->QUANTIDADE Picture cPicD3Qt
							@Li ,132 PSay (cAliasTOP)->CUSTO Picture cPicD3Cust
							nSaida	  += (cAliasTOP)->QUANTIDADE
							aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
							nCSaida	  += (cAliasTOP)->CUSTO
							aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
							aSalAtu[7] -= (cAliasTOP)->QUANT2UM
							If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
								aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
								aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
							Else
								AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
							EndIf
						EndIf
						If lCusUnif
							lPriApropri:=.T.
						EndIf
					EndIf
			EndCase
			If lFirst
				@ Li,153 PSay "|"
				@ Li,157 PSay aSalAtu[1] Picture cPicB2Qt
				@ Li,177 PSay aSalAtu[mv_par11+1] Picture cPicB2Tot
				@ Li,195 PSay "|"
			EndIf
			Do Case
				Case Alltrim((cAliasTop)->ARQ) == "SD3" .And. !lContinua
					If Empty((cAliasTOP)->OP) .And. Empty((cAliasTOP)->PROJETO)
						@ LI,197 PSay 'CC'+(cAliasTOP)->CC
					ElseIf !Empty((cAliasTOP)->PROJETO)
						@ LI,197 PSay 'PJ'+(cAliasTOP)->PROJETO
					ElseIf !Empty((cAliasTOP)->OP)
						@ LI,207 PSay 'OP'+(cAliasTOP)->OP
					EndIf
				Case Alltrim((cAliasTop)->ARQ) == "SD1" .And. !lContinua
					@ LI,207 PSay 'F-'+(cAliasTOP)->FORNECEDOR
				Case Alltrim((cAliasTop)->ARQ) == "SD2" .And. !lContinua
					@ LI,207 PSay 'P-'+(cAliasTOP)->PEDIDO
				Case lContinua .And. aDadosTran[14] == "SD3"
					If Empty(aDadosTran[11]) .And. Empty(aDadosTran[12])
						@ LI,197 PSay 'CC'+aDadosTran[13]
					ElseIf !Empty(aDadosTran[12])
						@ LI,197 PSay 'PJ'+aDadosTran[12]
					ElseIf !Empty(aDadosTran[11])
						@ LI,207 PSay 'OP'+aDadosTran[11]
					EndIf
			EndCase
			Li++

			If !lInverteMov .Or. (lInverteMov .And. lPriApropri)
				If !lContinua //Acerto para utilizar o Array aDadosTran[]
					dbSkip()
				EndIf
			EndIf
		EndDo

		If lFirst
			Li ++
			@ li,000 PSay STR0017	//"T O T A I S  :"
			@ Li,038 PSay nEntrada	Picture cPicD1Qt
			@ Li,062 PSay nCEntrada	Picture cPicD1Cust
			@ Li,108 PSay nSaida	Picture cPicD2Qt
			@ Li,132 PSay nCSaida	Picture cPicD2Cust
			@ Li,157 PSay aSalAtu[1] Picture cPicB2Qt
			@ Li,177 PSay aSalAtu[mv_par11+1] Picture cPicB2Tot
			Li++
			@ Li,135 PSay STR0018	//"QTD. NA SEGUNDA UM: "
			@ Li,157 PSay aSalAtu[7] Picture cPicB2Qt2
			Li++
			@Li ,  0 PSay __PrtThinLine()
			Li++
		Else
			If !MTR910IsMNT()
				Li--
				@Li ,  0 PSay STR0019	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
				Li++
				@Li ,  0 PSay __PrtThinLine()
				Li++
			Else
				aProdsMNT := aClone(NGProdMNT())
				If aScan(aProdsMNT, {|x| AllTrim(x) == AllTrim(SB1->B1_COD) }) == 0
					Li--
					@Li ,  0 PSay STR0019	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
					Li++
					@Li ,  0 PSay __PrtThinLine()
					Li++
				EndIf
			EndIf	
		EndIf
	EndDo
	dbSelectArea(cAliasTop)
	dbCloseArea()

	If !Empty(aGrupos)
		Li++
		@ Li,005 PSay STR0020		//"R E S U M O"
		Li++
		Li++
		dbSelectArea("SX5")
		For i:=1 to Len(aGrupos)
			If li > 53
				cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
			EndIf
			dbSeek(xFilial("SX5")+"02"+aGrupos[i][1])
			@ Li,000 PSay X5Descri()
			@ Li,063 PSay aGrupos[i][2] Picture cPicD1Cust
			@ Li,132 PSay aGrupos[i][3] Picture cPicD2Cust
			@ Li,177 PSay aGrupos[i][4] Picture cPicB2Tot
			Li++
		Next i
	EndIf
EndIf // lImpLivro

If li != 80 .and. lImpLivro
	roda(cbcont,cbtxt,Tamanho)
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Impressao de Termos Abertura e Encerramento                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If lImpTermos // Impressao dos Termos

	cArqAbert:=GetMv("MV_LMOD3AB")
	cArqEncer:=GetMv("MV_LMOD3EN")

	dbSelectArea("SM0")
	aVariaveis:={}

	For i:=1 to FCount()
		If FieldName(i)=="M0_CGC"
			AADD(aVariaveis,{FieldName(i),Transform(FieldGet(i),"@R 99.999.999/9999-99")})
		Else
			If FieldName(i)=="M0_NOME"
				Loop
			EndIf
			AADD(aVariaveis,{FieldName(i),FieldGet(i)})
		EndIf
	Next

	dbSelectArea("SX1")
	dbSeek(PADR("MTR910",nTamSX1)+"01")

	While SX1->X1_GRUPO==PADR("MTR910",nTamSX1)
		AADD(aVariaveis,{Rtrim(Upper(X1_VAR01)),&(X1_VAR01)})
		dbSkip()
	EndDo

	If !File(cArqAbert)
		aSavSet:=__SetSets()
		//Editor de Termos de Livros
		cArqAbert:=CFGX024(,OemToAnsi(STR0021))		//" Edi‡„o do Termo de Abertura "
		__SetSets(aSavSet)
		Set(24,Set(24),.t.)
	EndIf

	If !File(cArqEncer)
		aSavSet:=__SetSets()
		// Editor de Termos de Livros
		cArqEncer:=CFGX024(,OemToAnsi(STR0022)) 		//" Edi‡„o do Termo de Encerramento "
		__SetSets(aSavSet)
		Set(24,Set(24),.t.)
	EndIf

	cDriver:=aDriver[4]
	If cArqAbert#NIL
		ImpTerm(cArqAbert,aVariaveis,&cDriver)
	EndIf

	If cArqEncer#NIL
		ImpTerm(cArqEncer,aVariaveis,&cDriver)
	EndIf

EndIf

dbSelectArea("SB1")
dbClearFilter()
If !Empty(cArq1) .AND. File(cArq1 + OrdBagExt())
	RetIndex('SB1')
	FERASE(cArq1 + OrdBagExt())
EndIf
dbSetOrder(1)

dbSelectArea("SB2")
dbSetOrder(1)

dbSelectArea("SD1")
If mv_par16 == 2 .Or. lCusUnif
	RetIndex("SD1")
	Ferase(cTrbSD1+OrdBagExt())
EndIf
dbSetOrder(1)

dbSelectArea("SD2")
If mv_par16 == 2 .Or. lCusUnif
	RetIndex("SD2")
	Ferase(cTrbSD2+OrdBagExt())
EndIf
dbSetOrder(1)

dbSelectArea("SD3")
If mv_par16 == 2 .Or. lCusUnif
	RetIndex("SD3")
	Ferase(cTrbSD3+OrdBagExt())
EndIf
dbSetOrder(1)

If aReturn[5] = 1
	Set Printer To
	dbCommitAll()
	ourspool(wnrel)
EndIf

MS_FLUSH()
RETURN

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³MR910ImpCb³ Autor ³ Eveli Morasco         ³ Data ³ 28/11/92 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Imprime o cabecalho do item                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ MR910ImpCb(ExpA1,ExpN1,@ExpN2)                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpA1 = Array com informacoes do saldo inicial do item     ³±±
±±³          ³   [1] = Saldo inicial em quantidade                        ³±±
±±³          ³   [2] = Saldo inicial em valor                             ³±±
±±³          ³   [3] = Saldo inicial na 2a unidade de medida              ³±±
±±³          ³ ExpN1 = Custo medio do item                                ³±±
±±³          ³ ExpN2 = Numero da linha corrente de impressao              ³±±
±±³          ³ ExpN3 = Picture Do Campo                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATR910                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function MR910ImpCb(aSalAtu,nCusMed,Li,cPicB2Qt,cPicB2Cust, cAliasTop,cPicB2Tot) 

Default cPicB2Tot := PesqPictQt("B2_VATU1",18)

If ! lVEIC
	@ Li,000 PSay (cAliasTop)->PRODUTO
	@ Li,019 PSay SubStr((cAliasTop)->B1_DESC,1,30)
	@ Li,056 PSay STR0023+(cAliasTop)->B1_UM			//"UM : "
	@ Li,068 PSay STR0024+(cAliasTop)->TIPO	   		//"TIPO : "
	@ Li,083 PSay STR0025+(cAliasTop)->B1_GRUPO		//"GRUPO : "
	@ Li,115 PSay STR0026								//"Custo Medio : "
	@ Li,132 PSay nCusMed	Picture cPicB2Cust
	@ Li,157 PSay aSalAtu[1] Picture cPicB2Qt
	@ Li,177 PSay aSalAtu[mv_par11+1] Picture cPicB2Tot
	Li++
	If cPaisLoc<>"CHI"
		@ Li,000 PSay STR0027						//"Posicao IPI : "
		@ Li,015 PSay (cAliasTop)->B1_POSIPI Picture "@R 9999.9999.99"
	EndIf

	dbSelectArea("SB2")
	dbSeek(xFilial("SB2")+(cAliasTop)->PRODUTO+If(lCusUnif,"",mv_par08))
	@ Li,035 PSay STR0028+ If(lCusUnif , MV_PAR08 , Posicione("NNR",1,xFilial("NNR")+MV_PAR08,"NNR_DESCRI")) //"Localizacao : "
Else
	@ Li,000 PSay (cAliasTop)->B1_CODITE
	@ Li,PCOL() + 2 PSay SubStr((cAliasTop)->B1_DESC,1,30)	// SB1->B1_DESC
	@ Li,115 PSay STR0026									//"Custo Medio : "
	@ Li,132 PSay nCusMed	Picture cPicB2Cust
	@ Li,157 PSay aSalAtu[1] Picture cPicB2Qt
	@ Li,177 PSay aSalAtu[mv_par11+1] Picture cPicB2Tot
	Li++
	@ Li,000 PSay (cAliasTop)->PRODUTO // SB1->B1_COD
	@ Li,PCOL() + 2 PSay STR0023 + (cAliasTop)->B1_UM	 	// SB1->B1_UM			//"UM : "
	@ Li,PCOL() + 2 PSay STR0024 + (cAliasTop)->TIPO     	// SB1->B1_TIPO			//"TIPO : "
	@ Li,PCOL() + 2 PSay STR0025 + (cAliasTop)->B1_GRUPO 	// SB1->B1_GRUPO		//"GRUPO : "
	If cPaisLoc<>"CHI"
		@ Li,PCOL() + 2 PSay STR0027						//"Posicao IPI : "
		@ Li,PCOL() + 2 PSay (cAliasTop)->B1_POSIPI /* SB1->B1_POSIPI */ Picture "@R 9999.9999.99"
	EndIf
	@ Li,PCOL() + 2 PSay STR0028+ If(lCusUnif , MV_PAR08 , Posicione("NNR",1,xFilial("NNR")+MV_PAR08,"NNR_DESCRI")) //"Localizacao : " 
EndIf

dbSelectArea(cAliasTop)

Li += 2
RETURN

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ MTR910val³ Autor ³ Paulo Boschetti       ³ Data ³ 22.12.92 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function Mtr910val()
Local lRet := .T.

If mv_par09 $ "dsDS"
	lRet := .T.
Else
	lRet := .F.
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ MTR910Dev³ Autor ³ Rodrigo de A. Sartorio³ Data ³ 25.04.96 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Avalia se item pertence a uma nota de devolu‡ao             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATR910                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function MTR910Dev(cAliasTop)
Static lListaDev := NIL
LOCAL lRet:=.F.

// Identifica se lista dev. na mesma coluna
lListaDev := If(ValType(lListaDev)#"L",GetMV("MV_LISTDEV"),lListaDev)


If lListaDev .And. (cAliasTop)->ARQ == "SD1"
	dbSelectArea("SF1")
	If dbSeek(xFilial("SF1")+(cAliasTop)->DOCUMENTO+(cAliasTop)->SERIE+(cAliasTop)->FORNECEDOR+(cAliasTop)->LOJA) .And. (cAliasTop)->TIPONF == "D"
		lRet:=.T.
	EndIf
ElseIf lListaDev .And. (cAliasTop)->ARQ == "SD2"
	dbSelectArea("SF2")
	If dbSeek(xFilial("SF2")+(cAliasTop)->DOCUMENTO+(cAliasTop)->SERIE+(cAliasTop)->FORNECEDOR+(cAliasTop)->LOJA) .And. (cAliasTop)->TIPONF == "D"
		lRet:=.T.
	EndIf
EndIf
dbSelectArea(cAliasTop)


Return lRet


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³MTR910VAlm ³ Autor ³Rodrigo de A. Sartorio ³ Data ³26/06/00 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Valida Almoxarifado do KARDEX com relacao a custo unificado ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T. / .F.                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATR910                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function MTR910V2()
LOCAL lRet:=.T.
LOCAL cConteudo:=&(ReadVar())
LOCAL nOpc:=2
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se utiliza custo unificado por Empresa/Filial       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
LOCAL lCusUnif := A330CusFil()
If lCusUnif .And. cConteudo != Repl("*",TamSX3("B2_LOCAL")[1])
	nOpc := Aviso(STR0034,STR0035,{STR0036,STR0037})	//"Aten‡„o"###"Ao alterar o almoxarifado o custo medio unificado sera desconsiderado."###"Confirma"###"Abandona"
	If nOpc == 2
		lRet:=.F.
	EndIf
EndIf
Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³MR910ImpS1³ Autor ³ Nereu Humberto Junior ³ Data ³ 12/07/06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Imprime secoes 1 e 2 (Dados do produto)                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ MR910ImpS1(ExpA1,ExpN1,ExpC1,ExpL1,ExpL2,ExpO1,ExpO2)	  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpA1 = Array com informacoes do saldo inicial do item     ³±±
±±³          ³   [1] = Saldo inicial em quantidade                        ³±±
±±³          ³   [2] = Saldo inicial em valor                             ³±±
±±³          ³   [3] = Saldo inicial na 2a unidade de medida              ³±±
±±³          ³ ExpN1 = Custo medio do item                                ³±±
±±³          ³ ExpC1 = Alias                                              ³±±
±±³          ³ ExpL1 = Veiculo                                            ³±±
±±³          ³ ExpL2 = Custo Unificado                                    ³±±
±±³          ³ ExpO1 = Secao 1                                            ³±±
±±³          ³ ExpO2 = Secao 2                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATR910                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function MR910ImpS1(aSalAtu,nCusMed,cAliasTop,lVEIC,lCusUnif,oSection1,oSection2)

Local aArea := GetArea()

oSection1:Init()
oSection2:Init()

oSection1:Cell("nCusMed"):SetValue(nCusMed)
oSection1:Cell("nQtdSal"):SetValue(aSalAtu[1])
oSection1:Cell("nVlrSal"):SetValue(aSalAtu[mv_par11+1])			

oSection1:Cell("cProduto"):SetValue((cAliasTop)->PRODUTO)			
oSection1:Cell("cTipo"):SetValue((cAliasTop)->TIPO	)
If lVEIC
	oSection2:Cell("cProduto"):SetValue((cAliasTop)->PRODUTO)			
	oSection2:Cell("cTipo"):SetValue((cAliasTop)->TIPO	)
Endif
oSection2:Cell("B1_POSIPI"):SetValue((cAliasTop)->B1_POSIPI)
dbSelectArea("SB2")
MsSeek(xFilial("SB2")+(cAliasTop)->PRODUTO+If(lCusUnif,"",mv_par08))
oSection1:PrintLine()
oSection2:PrintLine()

RestArea(aArea)

RETURN


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³MTR910IsMNT³ Autor ³ Lucas                ³ Data ³ 03.10.06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verifica se há integração com o modulo SigaMNT/NG          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATR910                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function MTR910IsMNT()
Local aArea     := {}
Local aAreaSB1  := {}
Local aProdsMNT := {}
Local nX        := 0
Local lIntegrMNT:= .F.

//Esta funcao encontra-se no modulo Manutencao de Ativos (NGUTIL05.PRX), e retorna os produtos (pode ser MAIS de UM), dos parametros de
//Manutencao - "M" (MV_PRODMNT) / Terceiro - "T" (MV_PRODTER) / ou Ambos - "*" ou em branco
aProdsMNT := aClone(NGProdMNT("M"))
If Len(aProdsMNT) > 0
	aArea	 := GetArea()
	aAreaSB1 := SB1->(GetArea())
	SB1->(dbSelectArea( "SB1" ))
	SB1->(dbSetOrder(1))
	For nX := 1 To Len(aProdsMNT)
		If SB1->(dbSeek( xFilial("SB1") + aProdsMNT[nX] ))
			lIntegrMNT := .T.
			Exit
		EndIf 
	Next nX
	RestArea(aAreaSB1)
	RestArea(aArea)
EndIf
Return( lIntegrMNT )