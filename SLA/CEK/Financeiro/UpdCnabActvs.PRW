#include "protheus.ch"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³UpdCnabActvs³ Autor ³ ACTVS               ³ Data ³10/01/2013³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa de atualizacao de ambiente para utilizacao        ³±±
±±³          ³ do projeto CNAB/Boletos Actvs                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Protheus                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function UpdCnabActvs()

cArqEmp := "SigaMat.Emp"
nModulo		:= 06
__cInterNet := Nil
PRIVATE cMessage
PRIVATE aArqUpd	 := {}
PRIVATE aREOPEN	 := {}
PRIVATE oMainWnd


#IFDEF TOP
	TCInternal(5,'*OFF') //-- Desliga Refresh no Lock do Top
#ENDIF

Set Dele On

OpenSm0()
DbGoTop()

If Aviso("Atualização do Dicionário - Projeto CNAB Actvs - Release 10-01-2013"  ,;
	"Esta rotina tem o objetivo de efetuar a atualização do dicionário, para utilização do CNAB/Boleto padrão Actvs."+CHR(13)+CHR(10)+;
	"Para maior segurança, é importante realizar um backup completo dos dicionários e base de dados do sistema antes da "+;
	"execução desta rotina. Esta rotina deverá será executada no modo exclusivo.",{"Continuar","Sair"})==1

	lEmpenho	:= .F.
	lAtuMnu		:= .F.

	DEFINE WINDOW oMainWnd FROM 0, 0 TO 1, 1 TITLE "Efetuando Atualização do Dicionário"

	ACTIVATE WINDOW oMainWnd ICONIZED ON INIT (OpenSm0Excl(),lHistorico := MsgYesNo("Sistema em modo exclusivo - Ok !"+;
			CHR(13)+CHR(10)+"Deseja continuar com a atualizacao do Dicionario neste momento ? ", "Atenção"),;
			If(lHistorico,(Processa({|lEnd| UpdProc(@lEnd)},"Processando Atualizações";
			,"Aguarde, processando preparacao dos arquivos",.F.) , oMainWnd:End()),oMainWnd:End()))
EndIf																		

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³Proc      ³ Autor ³ ACTVS               ³ Data ³10/01/2013³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Funcao de processamento da gravacao dos arquivos           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Implantacao                                                ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function UpdProc(lEnd)
Local cTexto   := ''
Local cFile    :=""
Local cMask    := "Arquivos Texto (*.TXT) |*.txt|"
Local cCodigo  := "DM"
Local nRecno   := 0
Local nX       :=0

ProcRegua(1)
IncProc("Verificando integridade dos dicionarios....")

dbSelectArea("SM0")
dbGotop()
While !Eof()
	RpcSetType(2)
	RpcSetEnv(SM0->M0_CODIGO, SM0->M0_CODFIL)
	SM0->(dbSkip())
	nRecno := SM0->(Recno())
	SM0->(dbSkip(-1))
	RpcClearEnv()
	OpenSm0Excl()
	SM0->(DbGoTo(nRecno))
EndDo
IncProc("Verificando integridade dos dicionarios....")

dbSelectArea("SM0")
dbGotop()
While !Eof()
		RpcSetType(2)
		RpcSetEnv(SM0->M0_CODIGO, SM0->M0_CODFIL)
		cTexto += Replicate("-",128)+CHR(13)+CHR(10)
		cTexto += "Empresa : "+SM0->M0_CODIGO+" Filial : "+SM0->M0_CODFIL+"-"+SM0->M0_NOME+CHR(13)+CHR(10)

		ProcRegua(3)
			
		// atualiza SX3 - dicionario de dados
		IncProc("[" + AllTrim(SM0->M0_CODIGO) + "/" + AllTrim(SM0->M0_CODFIL) + "] " + ;
		        "Atualizando dicionario de dados...")		        
		cTexto += ActAtuSX3()
		
		// atualiza SX6 - parametros
		IncProc("[" + AllTrim(SM0->M0_CODIGO) + "/" + AllTrim(SM0->M0_CODFIL) + "] " + ;
		        "Atualizando parametros...")		        
		cTexto += ActAtuSX6()

		// atualiza SXB - consultas padroes
		IncProc("[" + AllTrim(SM0->M0_CODIGO) + "/" + AllTrim(SM0->M0_CODFIL) + "] " + ;
		        "Atualizando consultas padroes...")		        
		ActAtuSXB()

		ProcRegua(Len(aArqUpd))
		__SetX31Mode(.F.)
		For nX := 1 To Len(aArqUpd)
			IncProc("Atualizando estruturas. Aguarde... ["+aArqUpd[nx]+"]"+"Empresa : "+SM0->M0_CODIGO+" Filial : "+SM0->M0_CODFIL+"-"+SM0->M0_NOME)
			If Select(aArqUpd[nx])>0
				dbSelecTArea(aArqUpd[nx])
				dbCloseArea()
			EndIf
			X31UpdTable(aArqUpd[nx])
			If __GetX31Error()
				Alert(__GetX31Trace())
				Aviso("Atencao!","Ocorreu um erro desconhecido durante a atualizacao da tabela : "+ aArqUpd[nx] + ". Verifique a integridade do dicionario e da tabela.",{"Continuar"},2)
				cTexto += "Ocorreu um erro desconhecido durante a atualizacao da estrutura da tabela : "+aArqUpd[nx] +CHR(13)+CHR(10)
			EndIf
		Next nX		
	
		SM0->(dbSkip())
		nRecno := SM0->(Recno())
		SM0->(dbSkip(-1))
		RpcClearEnv()
		OpenSm0Excl()
		SM0->(DbGoTo(nRecno))
EndDo

dbSelectArea("SM0")
dbGotop()
RpcSetEnv(SM0->M0_CODIGO, SM0->M0_CODFIL,,,,, { "AE1" })

cTexto := "Log da atualizacao "+CHR(13)+CHR(10)+cTexto
__cFileLog := MemoWrite(Criatrab(,.f.)+".LOG",cTexto)
DEFINE FONT oFont NAME "Mono AS" SIZE 5,12   //6,15
DEFINE MSDIALOG oDlg TITLE "Atualizacao concluida." From 3,0 to 340,417 PIXEL
@ 5,5 GET oMemo  VAR cTexto MEMO SIZE 200,145 OF oDlg PIXEL 
oMemo:bRClicked := {||AllwaysTrue()}
oMemo:oFont:=oFont

DEFINE SBUTTON  FROM 153,175 TYPE 1 ACTION oDlg:End() ENABLE OF oDlg PIXEL //Apaga
DEFINE SBUTTON  FROM 153,145 TYPE 13 ACTION (cFile:=cGetFile(cMask,""),If(cFile="",.T.,MemoWrite(cFile,cTexto))) ENABLE OF oDlg PIXEL 


ACTIVATE MSDIALOG oDlg CENTER


Return(.T.)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ActAtuSX3 ³ Autor ³ ACTVS               ³ Data ³10/01/2013  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Funcao de processamento da gravacao do SX3                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Implantacao                                                ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function ActAtuSX3()
//	X3_ARQUIVO X3_ORDEM   X3_CAMPO   X3_TIPO    X3_TAMANHO X3_DECIMAL X3_TITULO  X3_TITSPA  X3_TITENG
//  X3_DESCRIC X3_DESCSPA X3_DESCENG X3_PICTURE X3_VALID   X3_USADO   X3_RELACAO X3_F3      X3_NIVEL
//  X3_RESERV  X3_CHECK   X3_TRIGGER X3_PROPRI  X3_BROWSE  X3_VISUAL  X3_CONTEXT X3_OBRIGAT X3_VLDUSER
//  X3_CBOX    X3_CBOXSPA X3_CBOXENG X3_PICTVAR X3_WHEN    X3_INIBRW  X3_GRPSXG  X3_FOLDER

Local aSX3   := {}
Local cOrdem
Local aEstrut:= {}
Local i      := 0
Local j      := 0
Local lSX3	 := .F.
Local cTexto := ''
Local cAlias := ''
Local nPosSXG := 0
Local nPosTam := 0
Local nTamParc := TamSX3("E2_PARCELA")[1]
Local aLetNu   := {{'A9','B0'},{'B9','C0'},{'C9','D0'},{'D9','E0'},;
                   {'E9','F0'},{'F9','G0'},{'G9','H0'},{'H9','I0'},;
                   {'I9','J0'},{'J9','K0'},{'K9','L0'},{'L9','M0'},;
                   {'M9','N0'},{'N9','O0'},{'O9','P0'},{'P9','Q0'},;
                   {'Q9','R0'},{'R9','S0'},{'S9','T0'},{'T9','U0'}}

//Formatacao para X3_RESERV, X3_OBRIGAT e X3_USADO
//	_SetOwnerPrvt("X3_OBRIGATORIO","€")
//	_SetOwnerPrvt("X3_X3OBRIG","€")
//	_SetOwnerPrvt("X3_OBRIGAT_RESERV","A€")
//	_SetOwnerPrvt("X3_NAOUSADO_RESERV","€€")
//	_SetOwnerPrvt("X3_USADO_RESERV","þÀ")
//	_SetOwnerPrvt("X3_NAOALTERA_USADO","€€€€€€€€€€€€€€°")
//	_SetOwnerPrvt("X3_NAOUSADO_USADO","€€€€€€€€€€€€€€€")
//	_SetOwnerPrvt("X3_EMUSO_USADO","€€€€€€€€€€€€€€ ")
//	_SetOwnerPrvt("X3_BITMAP_USADO", "ÿÿïýÿð€€€€€€ƒ€")
//	_SetOwnerPrvt("X3_BITMAP_RESERV", "€A"	)

aEstrut := {"X3_ARQUIVO","X3_ORDEM","X3_CAMPO","X3_TIPO","X3_TAMANHO","X3_DECIMAL","X3_TITULO","X3_TITSPA","X3_TITENG","X3_DESCRIC","X3_DESCSPA","X3_DESCENG","X3_PICTURE","X3_VALID","X3_USADO","X3_RELACAO","X3_F3","X3_NIVEL","X3_RESERV","X3_CHECK","X3_TRIGGER","X3_PROPRI","X3_BROWSE","X3_VISUAL","X3_CONTEXT","X3_OBRIGAT","X3_VLDUSER","X3_CBOX","X3_CBOXSPA","X3_CBOXENG","X3_PICTVAR","X3_WHEN","X3_INIBRW","X3_GRPSXG","X3_FOLDER","X3_PYME","X3_CONDSQL","X3_CHKSQL"}
//                                                                   123456789012    123456789012    1234567890123456789012345    1234567890123456789012345    1234567890123456789012345
aAdd(aSX3, {"SEA", "", "EA_SUBCTA" , "C",  3,  0, "Sub Conta"	, "", "", "Sub Conta"					, "",   "",        "","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_CODPROD", "C",  4,  0, "Cod Prod Cob", "", "", "Cod Produto Cobrança BB  "	, "",   "",        "","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_CARTEIR", "C",  3,  0, "Carteira"	, "", "", "Código da carteira"			, "",   "",        "","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_VARIACA", "C",  3,  0, "Variacao C."	, "", "", "Num Variacao Carteira"		, "",   "",        "","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_DIASPRO", "C",  2,  0, "Dias p/ Prot", "", "", "Dias p/ Protesto         "	, "",   "",        "","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_TXJUROS", "N",  13, 2, "Taxa Juros"	, "", "", "Taxa de Juros"				, "",   "",        "@E 9,999,999,999.99","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_LOCPAG" , "C",  80, 0, "Local Pagam.", "", "", "Local Pagamento"				, "",   "",        "","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_VALCIP" , "C",  3,  0, "CIP"			, "", "", "CIP"							, "",   "",        "","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_MSG1"   , "C", 80,  0, "Msg Boleto 1", "", "", "Mensagem Boleto 1"			, "",   "",        "","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_MSG2"   , "C", 80,  0, "Msg Boleto 2", "", "", "Mensagem Boleto 2"			, "",   "",        "","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_MSG3"   , "C", 80,  0, "Msg Boleto 3", "", "", "Mensagem Boleto 3"			, "",   "",        "","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_ESPDOC" , "C",  2,  0, "Especie Doc" , "", "", "Especie Doc"					, "",   "",        "","","€€€€€€€€€€€€€€ ","'DM'","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_ACEITE" , "C",  1,  0, "Aceite" 		, "", "", "Aceite"						, "",   "",        "","","€€€€€€€€€€€€€€ ","'N'","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_TAM_NN" , "N",  2,  0, "Tam.Nosso Nº", "", "", "Tamanho do Nosso Numero"		, "",   "",        "99","","€€€€€€€€€€€€€€ ","10","",0,"","","","","S","A","R","€","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_BOLETO" , "C",  1,  0, "Boleto ?" 	, "", "", "Quem emite o Boleto"			, "",   "",        "","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","1=Banco Emite;2=Cliente Emite","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_SITUACA", "C",  1,  0, "Sit.Carteira", "", "", "Situacao da Carteira"		, "",   "",        "","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})

aAdd(aSX3, {"SEE", "", "EE_BANCORR", "C",  3,  0, "Ban. Corres."	, "", "", "Banco correspondente"			, "",   "",        "","","€€€€€€€€€€€€€€ ","","SA6",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_AGECORR", "C",  5,  0, "Age. Corres."	, "", "", "Agencia correspondente"			, "",   "",        "","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})
aAdd(aSX3, {"SEE", "", "EE_CONCORR", "C",  10,  0, "Con. Corres."	, "", "", "Conta correspondente"			, "",   "",        "","","€€€€€€€€€€€€€€ ","","",0,"","","","","S","A","R","","","","","","","","","","","S","",""})

// Ajusta tamanhos dos campos que pertencem ao SXG
nPosSXG := Ascan( aEstrut, {|e| Alltrim(e) == "X3_GRPSXG" } )
nPosTam := Ascan( aEstrut, {|e| Alltrim(e) == "X3_TAMANHO"} )
If ( nPosSXG > 0 ) .And. ( nPosTam > 0 )
	dbSelectArea("SXG")
	dbSetOrder(1)
	For i:= 1 To Len(aSX3)
		If !Empty( aSX3[i][nPosSXG] )
			If dbSeek( aSX3[i][nPosSXG] )
				aSX3[i][nPosTam] := SXG->XG_SIZE
			Endif
		Endif
	Next i
Endif

ProcRegua(Len(aSX3))

dbSelectArea("SX3")
dbSetOrder(2)

For i:= 1 To Len(aSX3)
	If !Empty(aSX3[i][1])
		If !dbSeek(aSX3[i,3])	
			dbSelectArea("SX3")
			dbSetOrder(1)
			dbSeek(aSX3[i,1]+"ZZ",.T.)
			If SX3->X3_ARQUIVO+SX3->X3_ORDEM == aSX3[i,1]+"ZZ"
				cOrdem := "ZZ"
			Else
				dbSkip(-1)
				If SX3->X3_ARQUIVO == aSX3[i,1]
					cUlOrd := SX3->X3_ORDEM
				    nPosOrd := aSCAN(aLetNu,{|x| x[1] == cUlOrd})
				    If nPosOrd > 0
				      cOrdem := aLetNu[nPosOrd,2]
				    ElseIf cUlOrd = '99'
				      cOrdem := "A0"
				    Else
				      cOrdem := If(FindFunction("Soma1Old"),PADL(Soma1Old(cUlOrd),2),;
				                                            PADL(Soma1(cUlOrd),2))
				    Endif
				Else
					cOrdem := "01"
				EndIf
			EndIf
			dbSelectArea("SX3")
			dbSetOrder(2)
			lSX3	:= .T.
			If !(aSX3[i,1]$cAlias)
				cAlias += aSX3[i,1]+"/"
				aAdd(aArqUpd,aSX3[i,1])
			EndIf
			
			RecLock("SX3",.T.)
			For j:=1 To Len(aSX3[i])		
				If FieldPos(aEstrut[j])>0
					FieldPut(FieldPos(aEstrut[j]),aSX3[i,j])
				EndIf
			Next j
			SX3->X3_ORDEM := cOrdem
			dbCommit()        
			MsUnLock()
			
			cTexto += "Criado " + aSx3[i][1] + " - " + aSx3[i][3] + Chr(13) + Chr(10)
		Else
			RecLock("SX3",.F.)
			For j:=4 To Len(aSX3[i])		
				If FieldPos(aEstrut[j])>0
					FieldPut(FieldPos(aEstrut[j]),aSX3[i,j])
				EndIf
			Next j
			dbCommit()        
			MsUnLock()
			cTexto += "O campo "  + aSx3[i][3] + " ja existe em " + aSx3[i][1] + " e somente foi atualizado." + Chr(13) + Chr(10)
		EndIf
	EndIf
Next i

cTexto := "Tabelas atualizadas : " + cAlias + Chr(13) + Chr(10) + cTexto

Return cTexto

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ActAtuSX6 ³ Autor ³ ACTVS               ³ Data ³10/01/2013  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Funcao de processamento da gravacao do SX6                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Implantacao                                                ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function ActAtuSX6()
//  X6_FIL   X6_VAR     X6_TIPO    X6_DESCRIC X6_DSCSPA  X6_DSCENG  X6_DESC1 X6_DSCSPA1 X6_DSCENG1
//  X6_DESC2 X6_DSCSPA2 X6_DSCENG2 X6_CONTEUD X6_CONTSPA X6_CONTENG X6_PROPRI

Local aSX6   := {}                                       
Local aEstrut:= {}
Local i      := 0
Local j      := 0
Local lSX6	 := .F.
Local cTexto := ''
Local cAlias := ''
              
aEstrut := {"X6_FIL","X6_VAR","X6_TIPO","X6_DESCRIC","X6_DSCSPA","X6_DSCENG","X6_DESC1","X6_DSCSPA1","X6_DSCENG1","X6_DESC2","X6_DSCSPA2","X6_DSCENG2","X6_CONTEUD","X6_CONTSPA","X6_CONTENG","X6_PROPRI","X6_PYME"}
aAdd(aSx6,{"  ", "MV_XBOLNF", "C", "Indica se deve emitir boleto após a geração das",  "", "", " notas fiscais de faturamento. Informar S ou N",  "", "", "", "","","N","N","N","S","S"})

ProcRegua(Len(aSX6))

dbSelectArea("SX6")
dbSetOrder(1)
For i:= 1 To Len(aSX6)
	If !Empty(aSX6[i][2])
		If !dbSeek("  "+aSX6[i,2]) .And. !dbSeek(cFilAnt+aSX6[i,2])
			lSX6	:= .T.
			If !(aSX6[i,2]$cAlias)
				cAlias += aSX6[i,2] //+ ":"+aSX6[i,4]+aSX6[i,7]+aSX6[i,10]+CHR(13)+CHR(10)
			EndIf
			RecLock("SX6",.T.)
			For j:=1 To Len(aSX6[i])
				If !Empty(FieldName(FieldPos(aEstrut[j])))
					FieldPut(FieldPos(aEstrut[j]),aSX6[i,j])
				EndIf
			Next j
	  
			dbCommit()        
			MsUnLock()
			cTexto += "Incluido o parametro " + aSX6[i,2] + Chr(13) + Chr(10)			
		Else
			cTexto += "O parametro " + aSX6[i,2] + " ja existe e nao foi alterado." + Chr(13) + Chr(10)
		EndIf
		
	EndIf
Next i

cTexto := 'Incluidos novos parametros. Verifique as suas configuracoes e funcionalidades : '+ Chr(13) + Chr(10) + cTexto + Chr(13) + Chr(10)

Return cTexto

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ActAtuSXB ³ Autor ³ ACTVS               ³ Data ³10/01/2013  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Funcao de processamento da gravacao do SXB                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Implantacao                                                ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function ActAtuSXB()
//  XB_ALIAS XB_TIPO XB_SEQ XB_COLUNA XB_DESCRI XB_DESCSPA XB_DESCENG XB_CONTEM 

Local aSXB   := {}                                       
Local aEstrut:= {}
Local i      := 0
Local j      := 0

aEstrut:= {"XB_ALIAS","XB_TIPO","XB_SEQ","XB_COLUNA","XB_DESCRI","XB_DESCSPA","XB_DESCENG","XB_CONTEM"}

aAdd( aSXB , {"SEEBOL" , "1" , "01", "DB", "Parametros Banco", "","", "SEE"} )
aAdd( aSXB , {"SEEBOL" , "2" , "01", "01", "Banco", "","", ""} )
aAdd( aSXB , {"SEEBOL" , "4" , "01", "01", "Codigo", "","", "EE_CODIGO"} )
aAdd( aSXB , {"SEEBOL" , "4" , "01", "02", "Agencia", "","", "EE_AGENCIA"} )
aAdd( aSXB , {"SEEBOL" , "4" , "01", "03", "Conta", "","", "EE_CONTA"} )
aAdd( aSXB , {"SEEBOL" , "4" , "01", "04", "Sub Conta", "","", "EE_SUBCTA"} )
aAdd( aSXB , {"SEEBOL" , "4" , "01", "05", "Operacao", "","", "EE_OPER"} )
aAdd( aSXB , {"SEEBOL" , "5" , "01", "  ", " ", "","", "SEE->EE_CODIGO"} )
aAdd( aSXB , {"SEEBOL" , "5" , "02", "  ", " ", "","", "SEE->EE_AGENCIA"} )
aAdd( aSXB , {"SEEBOL" , "5" , "03", "  ", " ", "","", "SEE->EE_CONTA"} )
aAdd( aSXB , {"SEEBOL" , "5" , "04", "  ", " ", "","", "SEE->EE_SUBCTA"} )

aAdd( aSXB , {"SEESUB" , "1" , "01", "DB", "Sub Conta", "","", "SEE"} )
aAdd( aSXB , {"SEESUB" , "2" , "01", "01", "Banco", "","", ""} )
aAdd( aSXB , {"SEESUB" , "4" , "01", "01", "Sub Conta", "","", "EE_SUBCTA"} )
aAdd( aSXB , {"SEESUB" , "4" , "01", "02", "Operacao", "","", "EE_OPER"} )
aAdd( aSXB , {"SEESUB" , "5" , "01", "  ", " ", "","", "SEE->EE_SUBCTA"} )
aAdd( aSXB , {"SEESUB" , "6" , "01", "  ", "  ", "","", "SEE->EE_CODIGO == mv_par01 .And. SEE->EE_AGENCIA == mv_par02 .And. SEE->EE_CONTA == mv_par03"} )

ProcRegua(Len(aSXB))

dbSelectArea("SXB")
dbSetOrder(1)
For i:= 1 To Len(aSXB)
	If !Empty(aSXB[i][1])
		If !dbSeek(aSXB[i,1]+aSXB[i,2]+aSXB[i,3]+aSXB[i,4])	
			RecLock("SXB",.T.)
	   
			For j:=1 To Len(aSXB[i])		
				If !Empty(FieldName(FieldPos(aEstrut[j])))
					FieldPut(FieldPos(aEstrut[j]),aSXB[i,j])
				EndIf
			Next j
	  
			dbCommit()        
			MsUnLock()
		EndIf
	EndIf
Next i

Return(.T.)
