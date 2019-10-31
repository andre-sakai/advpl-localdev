#INCLUDE "Totvs.ch"
#Define _CRLF Chr(13)+Chr(10)

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Cadastro de Tabela de Preco de Mao de Obra              !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/2012                                                 !
+------------------+--------------------------------------------------------*/

User Function TFATC008

// cabecalho
dbSelectArea("SZV")

// variaveis internas de controle de validacao de campo
Private _lInclui
Private _lAltera

Private cCadastro := "Tabela de Preço de Frete"

Private aRotina := { { "Pesquisar"	,"AxPesqui"		,0,1,0,.f.},;
{ "Visualizar" ,"U_FATC008B(2)",0,2,0,Nil},;
{ "Incluir" ,"U_FATC008B(3)",0,3,0,Nil},;
{ "Alterar" ,"U_FATC008B(4)",0,4,0,Nil},;
{ "Excluir" ,"U_FATC008B(5)",0,5,0,Nil} }

DbSelectArea("SZV")
SZV->(DbSetOrder(1))
mBrowse(6,1,22,75,"SZV")

Return

// ** funcao de Cadastro do Cabecalho e Itens
User Function FATC008B(nOpcx)
Local aAcho      := {"NOUSER"} //Campos de usuario nao serao exibidos na enchoice.
Local cCampo     := ''
Local cSeek      := ''
Local nOrdem     := 0
Local nCntFor    := 0
Local nOpca      := 0
Local oDlg
Local oGetD
Local aObjects   := {}
Local aPosObj    := {}
Local aInfo      := {}
Local aSize      := {}
Local aEncBtns   := {}
Local l030Visual := .F.
Local l030Inclui := .F.
Local l030Altera := .F.
Local l030Deleta := .F.
Local aNoFields  := {'ZV_CODIGO','ZV_DESCRIC','ZV_FORNEC','ZV_LOJA'} // Nao aparecer na MSGetDados
Local bBeforeCols:= {|| Aadd(aEstrutAnt,DC3->DC3_TPESTR ),.T.}
Local cSeekDC3   := ""
Local cWhile     := ""
Private _cCodTabela := ""
Private _cDscTabela := ""
Private _cCodFornec := ""
Private _cLojFornec := ""


Private aTela[0][0]
Private aGets[0]
Private aHeader[0]
Private aCols     := {}
Private aEstrutAnt:= {}

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Define a funcao utilizada ( Incl.,Alt.,Visual.,Exclu.)  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If	nOpcx == 2
	l030Visual := .T.
ElseIf nOpcx == 3
	l030Inclui := .T.
ElseIf nOpcx == 4
	l030Altera := .T.
ElseIf nOpcx == 5
	l030Deleta := .T.
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Configura Variaveis da Enchoice                                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

//If	dbSeek('SZV', .F.)
	
	aX3SZV := FWSX3Util():GetAllFields( "SZV" )
	For nX := 1 to Len(aX3SZV)
		
		lUsado	  := X3Uso(GetSX3Cache(aX3SZV[Nx],"X3_USADO"))
		cX3Nivel  := GetSX3Cache(aX3SZV[Nx],"X3_NIVEL")
		cCampo := GetSX3Cache(aX3SZV[Nx],"X3_CAMPO")
		
		If lUsado .and. cNivel >= cX3Nivel
			If	GetSX3Cache(aX3SZV[Nx],"X3_CONTEXT")=='V' .Or. Inclui
				M->&(cCampo) := CriaVar(cCampo)
			Else
				M->&(cCampo) := SZV->(FieldGet(FieldPos(cCampo)))
			EndIf
			
			If (AllTrim(cCampo)$'ZV_CODIGO|ZV_DESCRIC|ZV_FORNEC|ZV_LOJA')
				aAdd(aAcho,cCampo)
			EndIf
			
			If	AllTrim(cCampo) == 'ZV_CODIGO'.And. !Empty(_cCodTabela)
				M->ZV_CODIGO := _cCodTabela
			EndIf
			
			If	AllTrim(cCampo) == 'ZV_DESCRIC'.And. !Empty(_cDscTabela)
				M->ZV_DESCRIC := _cDscTabela
			EndIf
			
			If	AllTrim(cCampo) == 'ZV_FORNEC'.And. !Empty(_cCodFornec)
				M->ZV_FORNEC := _cCodFornec
			EndIf
			
			If	AllTrim(cCampo) == 'ZV_LOJA'.And. !Empty(_cLojFornec)
				M->ZV_LOJA := _cLojFornec
			EndIf
			
		EndIf
		
	Next nX
//Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Montagem do AHEADER e ACOLS para GetDados  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If	l030Inclui
	//-- Sintaxe da FillGetDados(/*nOpcX*/,/*Alias*/,/*nOrdem*/,/*cSeek*/,/*bSeekWhile*/,/*uSeekFor*/,/*aNoFields*/,/*aYesFields*/,/*lOnlyYes*/,/*cQuery*/,/*bMontCols*/,/*lEmpty*/,/*aHeaderAux*/,/*aColsAux*/,/*bAfterCols*/)
	FillGetDados(nOpcx,'SZV',1,,,,aNoFields,,,,,.T.,,,)
	nOrdem := aScan(aHeader,{|x| Trim(x[2])=="ZV_ITEM"})
	aCols[1][nOrdem] := StrZero(1,Len(SZV->ZV_ITEM))
Else
	cSeekSZV := xFilial('SZV')+M->ZV_CODIGO
	cWhile   := 'SZV->ZV_FILIAL+SZV->ZV_CODIGO'
	//-- Sintaxe da FillGetDados(/*nOpcX*/,/*Alias*/,/*nOrdem*/,/*cSeek*/,/*bSeekWhile*/,/*uSeekFor*/,/*aNoFields*/,/*aYesFields*/,/*lOnlyYes*/,/*cQuery*/,/*bMontCols*/,/*lEmpty*/,/*aHeaderAux*/,/*aColsAux*/,/*bAfterCols*/)
	FillGetDados(nOpcx,'SZV',1,cSeekSZV,{|| &cWhile },,aNoFields,,,,,,,,,bBeforeCols)
	nOrdem := aScan(aHeader,{|x| Trim(x[2])=="ZV_ITEM"})
	aSort(aCols,,,{|x,y| x[nOrdem]<y[nOrdem]})
EndIf

//-- Dimensoes padroes
aSize := MsAdvSize()
aAdd(aObjects, {100, 032, .T., .T.})
aAdd(aObjects, {100, 100, .T., .T.})
aInfo := {aSize[1], aSize[2], aSize[3], aSize[4], 5, 5}
aPosObj := MsObjSize(aInfo, aObjects,.T.)

Inclui := ((l030Inclui).Or.(l030Altera)) //-- Impede que a Descrição apaceca na inclusão de itens durante a alteracao

DEFINE MSDIALOG oDlg TITLE cCadastro FROM aSize[7],00 TO aSize[6],aSize[5] OF oMainWnd PIXEL

//-- Sintaxe da Enchoice(/*cAlias*/,/*nReg*/,/*nOpc*/,/*aCRA*/,/*cLetra*/,/*cTexto*/,/*aAcho*/,/*aPos*/,/*aCpos*/,/*nModelo*/,/*nColMens*/,/*cMensagem*/,/*cTudoOk*/,/*oWns*/,/*lF3*/,/*lMemoria*/,/*lColumn*/,/*caTela*/,/*lNoFolder*/,/*lProperty*/)³
EnChoice("SZV", , nOpcx, , , , aAcho, aPosObj[1], If(nOpcx==4,{'SZV_REABAS'},Nil), 3, , , , , , .T.)
//              (nT, nL, nB , nR , nOpc , cLinhaOk    , cTudoOk     , cIniCpos    , lDeleta, aAlter, nFreeze, lEmpty, nMax, cFieldOk, cSuperDel, aTeclas, cDelOk, oWnd)
oGetD := MSGetDados():New(aPosObj[2,1],aPosObj[2,2],aPosObj[2,3],aPosObj[2,4], nOpcx, 'U_FATC008C()','AllWaysTrue', '+ZV_ITEM', .T.)

ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,{||If(U_FATC008D(nOpcx),(nOpca:= 1,oDlg:End()),.T.)},{||oDlg:End()},,aEncBtns)

If	nOpca == 1 .And. !l030Visual
	sfGravaDados(nOpcx)
EndIf

Return(nOpca)

// ** funcao que retorna os itens da tabela de preco
Static Function sfRetItens(mvCodTab)
Local _vRetItens := {}
Local _nX
// chave de pesquisa
Local _cSeek

dbSelectArea("SZV")
SZV->(dbSetOrder(1)) //1-ZV_FILIAL, ZV_CODIGO, ZV_ITEM

If (_cOpcao=="INCLUIR").or.(!SZV->(dbSeek( _cSeek:=xFilial("SZV")+mvCodTab )))
	// cria a linha de acordo com os campos do Header
	_vRetItens := Array(1,Len(aHeader)+1)
	// cria as variaveis
	For _nX := 1 to Len(aHeader)
		_vRetItens[1,_nX] := CriaVar(aHeader[_nX,2],.t.)
	Next _nX
	// trata item deletado
	_vRetItens[Len(_vRetItens),Len(aHeader)+1] := .F.
Else
	// inclui todos os itens da programacao
	While SZV->(!Eof()).and.(SZV->(ZV_FILIAL+ZV_CODIGO)==_cSeek)
		// cria a linha de acordo com os campos do Header
		aAdd(_vRetItens,Array(Len(aHeader)+1))
		// atualiza o conteudo de acordo com cada campo
		For _nX := 1 to Len(aHeader)
			// se for campo virtual, executa inic. padrao
			If (aHeader[_nX][10]=="V")
				_vRetItens[Len(_vRetItens),_nX] := &(aHeader[_nX][13])
			Else
				_vRetItens[Len(_vRetItens),_nX] := FieldGet(FieldPos(aHeader[_nX,2]))
			EndIf
		Next _nX
		// trata item deletado
		_vRetItens[Len(_vRetItens),Len(aHeader)+1] := .F.
		// proximo item
		SZV->(dbSkip())
	EndDo
EndIf

Return(_vRetItens)

Static Function sfGravaDados(nOpcx)
Local aAreaAnt   := GetArea()
Local aAreaSZV   := SZV->(GetArea())
Local lAdd       := .F.
Local lDel       := .F.
Local lRet       := .F.
Local nCntFor    := 0
Local nCntFo1    := 0
Local nPosCpo    := 0
Local nItem      := 0
Local nTamCpo    := Len(SZV->ZV_ITEM)

Begin Transaction
If	nOpcx == 3 .Or. nOpcx == 4
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inclui ou Altera Picking                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	nItem   := 0
	nPosCpo := aScan(aHeader,{|x|AllTrim(x[2])=='ZV_ITEM'})
	dbSelectArea('SZV')
	dbSetOrder(1)
	For nCntFor := 1 To Len(aCols)
		If	!GDDeleted(nCntFor)
			If	MsSeek(xFilial('SZV')+M->ZV_CODIGO+aCols[nCntFor,nPosCpo], .F.)
				lRet := .T.
				RecLock('SZV',.F.)
			Else
				lRet := .T.
				lAdd := .T.
				RecLock('SZV',.T.)
				Replace ZV_FILIAL  With xFilial('SZV')
				Replace ZV_CODIGO  With M->ZV_CODIGO
				Replace ZV_DESCRIC With M->ZV_DESCRIC
			EndIf
			
			nItem ++
			For nCntFo1 := 1 To Len(aHeader)
				If	AllTrim(aHeader[nCntFo1,2])=='ZV_ITEM'
					Replace ZV_ITEM With StrZero(nItem,nTamCpo)
				ElseIf !(aHeader[nCntFo1,10]=='V')
					FieldPut(FieldPos(aHeader[nCntFo1,2]), aCols[nCntFor,nCntFo1])
				EndIf
			Next nCntFo1
			MsUnLock()
		Else
			If	MsSeek(xFilial('SZV')+M->ZV_CODIGO+aCols[nCntFor,nPosCpo], .F.)
				lRet := .T.
				lDel := .T.
				RecLock('SZV',.F.)
				dbDelete()
				MsUnLock()
			EndIf
		EndIf
	Next nCntFor
ElseIf nOpcx == 5
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Exclui Picking                                                            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea('SZV')
	dbSetOrder(1)
	Do While (dbSeek(xFilial('SZV')+M->ZV_CODIGO, .F.))
		lRet := .T.
		lDel := .T.
		RecLock('SZV', .F.)
		dbDelete()
		MsUnLock()
	EndDo
EndIf

End Transaction

If	lDel .Or. lAdd
	aAreaSZV[3] := SZV->(Recno())
	If	aAreaAnt[1] == "SZV"
		aAreaAnt[3] := SZV->(Recno())
	EndIf
EndIf

RestArea(aAreaSZV)
RestArea(aAreaAnt)
Return lRet

// ** funcao para validar a linha
User Function FATC008C()
Local _cCodTabela   := M->ZV_CODIGO
Local cTPEstrDC8 := ""
Local cTpEstrAnt := ""
Local cEstrutFis := ""
Local lRet       := .T.
Local nLinhaOK   := 0
Local nPosTpOper  := aScan(aHeader, {|x|AllTrim(x[2])=="ZV_TPOPER"})
Local nPosDscOper  := aScan(aHeader, {|x|AllTrim(x[2])=="ZV_DSCOPER"})

If	Empty(_cCodTabela)
	Help(' ', 1, 'OBRIGAT')
	lRet := .F.
EndIf

//-- Nao avalia linhas deletadas
If	lRet .And. !GDdeleted(n)
	//-- Analisa se ha itens duplicados na GetDados.
	lRet := GDCheckKey({"ZV_ITEM"},4)
	
	//³ Verifica se todos os Campos Obrigat¢rios foram Preenchidos
	If	(nPosDscOper==0.Or.(nPosDscOper>0.And.Empty(aCols[n,nPosDscOper]))) .Or. ;
		(nPosTpOper==0.Or.(nPosTpOper>0.And.Empty(aCols[n,nPosTpOper])))
		Help(' ', 1, 'OBRIGAT')
		lRet := .F.
	EndIf
	
EndIf

Return lRet

// ** funcao para validacao geral (TudoOk)
User Function FATC008D(nOpcx)
Local aAreaAnt   := GetArea()
Local aEstrutFis := {}
Local aTPEstr    := {}
Local _cCodTabela := M->ZV_CODIGO
Local _cTipoOper := ''
Local cTPEstrDC8 := ''
Local cTpEstrAnt := ''
Local lRet       := .T.
Local nX         := 0
Local SaldoSBF   := 0
Local nPosNorma  := aScan(aHeader, {|x|AllTrim(x[2])=='DC3_CODNOR'})

If	Empty(_cCodTabela)
	Help(' ', 1, 'OBRIGAT')
	lRet := .F.
EndIf

If	lRet
	For nX := 1 to Len(aCols)
		_cTipoOper := GdFieldGet('ZV_TPOPER',nX)
		If	_cTipoOper == NIL .Or. Empty(_cTipoOper)
			Help(' ', 1, 'OBRIGAT')
			lRet := .F.
			Exit
		EndIf
		If	!GDDeleted( nX ) .And. nOpcx <> 5
			/*
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Verifica se todos os Campos Obrigat¢rios foram Preenchidos                ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If (nPosNorma==0.Or.(nPosNorma>0.And.Empty(aCols[nX,nPosNorma])))
			Help(' ', 1, 'OBRIGAT')
			lRet := .F.
			Exit
			EndIf
			*/
		EndIf
	Next nX
EndIf
RestArea(aAreaAnt)
Return lRet

// ** funcao que retorna a lista de operacoes de mao de obra
User Function FATC008A
local _cOpcoes := ""

_cOpcoes += "01=CAIXAS;"
_cOpcoes += "02=CARVÃO;"
_cOpcoes += "03=FIO / LINHA;"
_cOpcoes += "04=PNEU GRANDE;"
_cOpcoes += "05=PNEU MÉDIO;"
_cOpcoes += "06=PNEU PEQUENO;"
_cOpcoes += "07=ROLO DE TECIDO;"
_cOpcoes += "08=SACARIA LEVE;"
_cOpcoes += "09=SACARIA PESADA;"
_cOpcoes += "99=GERAL"

Return(_cOpcoes)
