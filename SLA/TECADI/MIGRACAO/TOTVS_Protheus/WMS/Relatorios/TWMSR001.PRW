
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSR001                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Impressao dos detalhes das movimentacoes de containers  !
!                  ! baseados nas programacoes                               !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 20/10/10                                                !
+------------------+--------------------------------------------------------*/

User Function TWMSR001

// declaracao de Variaveis
LOCAL cDesc1       := "Relatorio com a relacao da movimentacoes de   "
LOCAL cDesc2       := "entrada e saida de containers relacionadas    "
LOCAL cDesc3       := "à progrmacao de recebimentos                  "
LOCAL titulo       := "Programação de Recebimentos"
LOCAL Cabec1       := OemToAnsi("Dados da Programação")
LOCAL Cabec2       := OemToAnsi("  Seq Dt Entrada Hora  [Nr. Container  ]  RIC Entrada             Dt Saida   Hora  RIC Saida        Placa")
LOCAL imprime      := .T.
LOCAL aOrd         := {}

Local _aPerg := {}
Local _cPerg := PadR("TWMSR001",10)

PRIVATE lAbortPrint:= .F.
PRIVATE limite     := 80//220
PRIVATE tamanho    := "G"
PRIVATE nomeprog   := "TWMSR001"
PRIVATE nTipo      := 18
PRIVATE lEnd       := .F.

PRIVATE aReturn    := { "Zebrado", 1, "Administracao", 1, 2, 1, "", 1}
PRIVATE nLastKey   := 0
PRIVATE cbtxt      := Space(10)
PRIVATE cbcont     := 00
PRIVATE CONTFL     := 01
PRIVATE m_pag      := 01
PRIVATE wnrel      := "TWMSR001"

PRIVATE cString    := "SZ3"

// criacao das Perguntas
aAdd(_aPerg,{"Programação De?" ,"C",TamSx3("Z1_CODIGO")[1],0,"G",,"SZ1"}) //mv_par01
aAdd(_aPerg,{"Programação Até?" ,"C",TamSx3("Z1_CODIGO")[1],0,"G",,"SZ1"}) //mv_par02
aAdd(_aPerg,{"Cliente De?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par03
aAdd(_aPerg,{"Cliente Até?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par04
aAdd(_aPerg,{"Loja De?" ,"C",TamSx3("A1_LOJA")[1],0,"G",,""}) //mv_par05
aAdd(_aPerg,{"Loja Até?" ,"C",TamSx3("A1_LOJA")[1],0,"G",,""}) //mv_par06
aAdd(_aPerg,{"Dt. Emissão De?" ,"D",8,0,"G",,""}) //mv_par07
aAdd(_aPerg,{"Dt. Emissão Até?" ,"D",8,0,"G",,""}) //mv_par08
aAdd(_aPerg,{"Dt. Receb. De?" ,"D",8,0,"G",,""}) //mv_par09
aAdd(_aPerg,{"Dt. Receb. Até?" ,"D",8,0,"G",,""}) //mv_par10
aAdd(_aPerg,{"Status Program.?" ,"N",1,0,"C",{"Abertas","Iniciadas","Saldo Atendido","Finalizadas","Todas"},""}) //mv_par11
aAdd(_aPerg,{"Notas Fiscais?" ,"N",1,0,"C",{"Não Imprime","Imprime Cabec","Imprime Itens"},""}) //mv_par12
aAdd(_aPerg,{"Movimentacoes?" ,"N",1,0,"C",{"Imprime","Não Imprime"},""}) //mv_par13
aAdd(_aPerg,{"Tipo de Container De?" ,"C",TamSx3("ZC_TIPO")[1],0,"G",,"ZA"}) //mv_par14
aAdd(_aPerg,{"Tipo de Container Até?" ,"C",TamSx3("ZC_TIPO")[1],0,"G",,"ZA"}) //mv_par15

// cria grupo de perguntas
U_FtCriaSX1( _cPerg,_aPerg )

If ! Pergunte(_cPerg,.T.)
	Return ()
EndIf

wnrel:=SetPrint(cString,wnrel,_cPerg,@Titulo,cDesc1,cDesc2,cDesc3,.F.,aOrd,.F.,Tamanho)

If nLastKey == 27
	Set Filter to
	Return
Endif

SetDefault (aReturn, cString)

If nLastKey == 27
	Set Filter to
	Return
Endif

nTipo := IIF(aReturn[4]==1,15,18)

RptStatus({|| sfImprimir(wnRel,tamanho,titulo,Cabec1,Cabec2,nTipo)},titulo)

Return ()

//** funcao para impressao dos dados
Static Function sfImprimir(WnRel,tamanho,titulo,Cabec1,Cabec2,nTipo)

Local _cQuery, _cQrySF1, _cQrySZ3
Local _nLin := 80

// controle para quebras
Local _cCodProg	:= ""
Local _cNumNf	:= ""

_cQuery := "SELECT Z1_CODIGO, Z1_CLIENTE, Z1_LOJA, Z1_EMISSAO, A1_NOME, "
_cQuery += "Z2_ITEM, Z2_TAMCONT, Z2_TIPCONT, Z2_CONTEUD, Z2_QUANT, Z2_QTDREC, Z2_DOCUMEN "
// programacao de recebimento
_cQuery += "FROM "+RetSqlName("SZ1")+" SZ1 "
// cadastro de clientes
_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 ON A1_FILIAL = '"+xFilial("SA1")+"' AND A1_COD = Z1_CLIENTE AND A1_LOJA = Z1_LOJA AND SA1.D_E_L_E_T_ = ' ' "
// itens da programacao
_cQuery += "INNER JOIN "+RetSqlName("SZ2")+" SZ2 ON Z2_FILIAL = '"+xFilial("SZ2")+"' AND Z2_CODIGO = Z1_CODIGO AND SZ2.D_E_L_E_T_ = ' ' "
// filtro por tipo de container/carga solta
_cQuery += "AND Z2_TIPCONT BETWEEN '"+mv_par14+"' AND '"+mv_par15+"' "

// saldo atendido
If (mv_par11==3)
	_cQuery += "AND Z2_QUANT = Z2_QTDREC "
EndIf
// filtro da programcao
_cQuery += "WHERE Z1_FILIAL = '"+xFilial("SZ1")+"' AND SZ1.D_E_L_E_T_ = ' ' "
_cQuery += "AND Z1_CODIGO BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' "
// INI - sub-consulta para filtrar pela data de recebimento
If (mv_par13==1).and.(!Empty(mv_par09)).and.(!Empty(mv_par10))
	_cQuery += "AND Z1_CODIGO IN ("
	_cQuery += "    SELECT DISTINCT Z3_PROGRAM FROM "+RetSqlName("SZ3")+" SZ3 "
	_cQuery += "    WHERE Z3_FILIAL = Z1_FILIAL "
	_cQuery += "    AND Z3_PROGRAM BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' "
	_cQuery += "    AND Z3_DTMOVIM BETWEEN '"+DtoS(mv_par09)+"' AND '"+DtoS(mv_par10)+"' "
	_cQuery += "    AND Z3_TPMOVIM = 'E' "
	_cQuery += "    AND Z3_TIPCONT BETWEEN '"+mv_par14+"' AND '"+mv_par15+"' "
	_cQuery += "    AND D_E_L_E_T_ = ' ' "
	_cQuery += "                 ) "
EndIf
// FIM - sub-consulta para filtrar pela data de recebimento
_cQuery += "AND Z1_CLIENTE BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' "
_cQuery += "AND Z1_LOJA BETWEEN '"+mv_par05+"' AND '"+mv_par06+"' "
_cQuery += "AND Z1_EMISSAO BETWEEN '"+DtoS(mv_par07)+"' AND '"+DtoS(mv_par08)+"' "
// filtra somente as programacoes em aberto
If (mv_par11==1)
	_cQuery += "AND Z1_DTABERT = ' ' "
	// programacao iniciada
ElseIf (mv_par11==2)
	_cQuery += "AND Z1_DTABERT != ' ' AND Z1_DTFECHA = ' ' "
	// programacoes finalizadas
ElseIf (mv_par11==4)
	_cQuery += "AND Z1_DTABERT != ' ' AND Z1_DTFECHA != ' ' "
EndIf

_cQuery += "ORDER BY Z1_CODIGO

MEMOWRIT("C:\QUERY\TWMSR001.TXT",_cQuery)

If (Select("_QRYSZ1")<>0)
	dbSelectArea("_QRYSZ1")
	dbCloseArea()
EndIf

dbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_QRYSZ1",.F.,.T.)
// tratamento para campos data
TcSetField("_QRYSZ1","Z1_EMISSAO","D")

dbSelectArea("_QRYSZ1")
_QRYSZ1->(dbGotop())

While _QRYSZ1->(!Eof())
	If _nLin > 58
		cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
		_nLin := 9
	EndIf
	
	// quebra por recurso
	If (_cCodProg<>_QRYSZ1->Z1_CODIGO)
		_cCodProg := _QRYSZ1->Z1_CODIGO
		@_nLin,000 PSAY "Programação: "+_cCodProg
		@_nLin,020 PSAY "Cliente: "+_QRYSZ1->Z1_CLIENTE +"/"+_QRYSZ1->Z1_LOJA +": "+_QRYSZ1->A1_NOME
		@_nLin,100 PSAY "Emissão: "+DtoC(_QRYSZ1->Z1_EMISSAO)
		_nLin++
		// impressao dos dados do item
		@_nLin,002 PSAY "|..Item: "+_QRYSZ1->Z2_ITEM +;
		" NF/DI: "+_QRYSZ1->Z2_DOCUMEN +;
		" Tamanho: " +PadR(sfCBoxDescr("Z2_TAMCONT",_QRYSZ1->Z2_TAMCONT,2,3), 3) +;
		" Tipo: "    +PadR(Tabela("ZA",_QRYSZ1->Z2_TIPCONT),15) +;
		" Conteúdo: "+PadR(sfCBoxDescr("Z2_CONTEUD",_QRYSZ1->Z2_CONTEUD,2,3),10) +;
		" Qtd Programada: "+Transform(_QRYSZ1->Z2_QUANT,PesqPict("SZ2","Z2_QUANT"))+;
		" Qtd Recebida: "+Transform(_QRYSZ1->Z2_QTDREC,PesqPict("SZ2","Z2_QTDREC"))
		_nLin++
	EndIf
	
	// informacoes das notas fiscais
	If (mv_par12 > 1)
		_cQrySF1 := "SELECT F1_DOC, F1_SERIE, F1_EMISSAO "
		// qtd de itens na nota
		If (mv_par12==2)
			_cQrySF1 += ", (COUNT(*)) QTD_ITENS "
		ElseIf (mv_par12==3)
			_cQrySF1 += ", D1_COD "
		EndIf
		// cabecalho da nota
		_cQrySF1 += "FROM "+RetSqlName("SF1")+" SF1 "
		// itens da nota
		_cQrySF1 += "INNER JOIN "+RetSqlName("SD1")+" SD1 ON D1_FILIAL = '"+xFilial("SD1")+"' AND D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE "
		_cQrySF1 += "      AND D1_FORNECE = F1_FORNECE AND D1_LOJA = F1_LOJA "
		_cQrySF1 += "      AND D1_PROGRAM = '"+_QRYSZ1->Z1_CODIGO+"' AND D1_ITEPROG = '"+_QRYSZ1->Z2_ITEM+"' "
		// filtro da nota fiscal
		_cQrySF1 += "WHERE F1_FILIAL = '"+xFilial("SF1")+"' AND SF1.D_E_L_E_T_ = ' ' "
		_cQrySF1 += "AND F1_FORNECE = '"+_QRYSZ1->Z1_CLIENTE+"' AND F1_LOJA = '"+_QRYSZ1->Z1_LOJA+"' "
		// agrupamento dos dados
		If (mv_par12==2)
			_cQrySF1 += "GROUP BY F1_DOC, F1_SERIE, F1_EMISSAO "
		EndIf
		
		If (Select("_QRYNFE")<>0)
			dbSelectArea("_QRYNFE")
			dbCloseArea()
		EndIf
		
		dbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQrySF1),"_QRYNFE",.F.,.T.)
		dbSelectArea("_QRYNFE")
		_QRYNFE->(dbGotop())
		
		// tratamento para campos data
		TcSetField("_QRYNFE","F1_EMISSAO","D")
		
		While _QRYNFE->(!Eof())
			If _nLin > 58
				cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
				_nLin := 9
			EndIf
			// impressao dos dados da nota fiscal
			If (_cNumNf <> (_QRYNFE->(F1_DOC+F1_SERIE)))
				@_nLin,004 PSAY "|..Nota Fiscal: "+_QRYNFE->F1_DOC+;
				" Serie: "+_QRYNFE->F1_SERIE +;
				" Emissão: "+DtoC(_QRYNFE->F1_EMISSAO) +;
				" "+If(mv_par12==2,"Qtd Itens: "+Str(_QRYNFE->QTD_ITENS,3),"")
				_nLin++
				// controle de quebra
				_cNumNf := (_QRYNFE->(F1_DOC+F1_SERIE))
			EndIf
			
			// verifica a necessidade de impressao dos itens
			If (mv_par12==3)
				@_nLin,001 PSAY "    |..Produto: "+_QRYNFE->D1_COD+"-"+Posicione("SB1",1, xFilial("SB1")+_QRYNFE->D1_COD ,"B1_DESC")
				_nLin++
			EndIf
			
			// proximo item
			_QRYNFE->(dbSkip())
		EndDo
		// fecha alias da query
		dbSelectArea("_QRYNFE")
		dbCloseArea()
	EndIf
	
	// movimentacoes de container do item
	If (mv_par13==1)
		_cQrySZ3 := "SELECT Z3_SEQUENC, Z3_DTMOVIM, Z3_HRMOVIM, Z3_CONTAIN, Z3_DTSAIDA, Z3_HRSAIDA, Z3_RIC Z3_RICENT, "
		
		// busca o registro da RIC de saida
		_cQrySZ3 += "CASE WHEN Z3_DTSAIDA = ' ' THEN ' ' ELSE "
		_cQrySZ3 += "(SELECT Z3_RIC "
		_cQrySZ3 += "FROM "+RetSqlName("SZ3")+" "
		_cQrySZ3 += "WHERE Z3_FILIAL = SZ3.Z3_FILIAL AND D_E_L_E_T_ = ' ' "
		_cQrySZ3 += "AND Z3_PROGRAM = SZ3.Z3_PROGRAM AND Z3_ITEPROG = SZ3.Z3_ITEPROG "
		_cQrySZ3 += "AND Z3_CONTAIN = SZ3.Z3_CONTAIN "
		_cQrySZ3 += "AND Z3_TPMOVIM = 'S' "
		_cQrySZ3 += "AND Z3_DTMOVIM = SZ3.Z3_DTSAIDA AND Z3_HRMOVIM = SZ3.Z3_HRSAIDA "
		// tratar placa, somente para Carga Solta
		If (_QRYSZ1->Z2_TAMCONT == "CS")
			_cQrySZ3 += "AND Z3_PLACA1 = SZ3.Z3_PLACA1 "
		EndIf
		_cQrySZ3 += ") END Z3_RICSAI, "
		// placa
		_cQrySZ3 += "Z3_PLACA1 "
		
		// movimentacoes de containers
		_cQrySZ3 += "FROM "+RetSqlName("SZ3")+" SZ3 "
		_cQrySZ3 += "WHERE Z3_FILIAL = '"+xFilial("SZ3")+"' AND SZ3.D_E_L_E_T_ = ' ' "
		_cQrySZ3 += "AND Z3_PROGRAM = '"+_QRYSZ1->Z1_CODIGO+"' AND Z3_ITEPROG = '"+_QRYSZ1->Z2_ITEM+"' "
		_cQrySZ3 += "AND Z3_TPMOVIM = 'E' "
		// ordem dos dados
		_cQrySZ3 += "ORDER BY Z3_SEQUENC "
		
		If (Select("_QRYNFE")<>0)
			dbSelectArea("_QRYNFE")
			dbCloseArea()
		EndIf
		
		dbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQrySZ3),"_QRYNFE",.F.,.T.)
		dbSelectArea("_QRYNFE")
		_QRYNFE->(dbGotop())
		
		// tratamento para campos data
		TcSetField("_QRYNFE","Z3_DTMOVIM","D")
		TcSetField("_QRYNFE","Z3_DTSAIDA","D")
		
		While _QRYNFE->(!Eof())
			If _nLin > 58
				cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
				_nLin := 9
			EndIf
			// impressao dos dados da movimentacao
			@_nLin,002 PSAY _QRYNFE->Z3_SEQUENC +;
			" "+PadR(DtoC(_QRYNFE->Z3_DTMOVIM),10) +;
			" "+_QRYNFE->Z3_HRMOVIM +;
			" [ "+Transf(_QRYNFE->Z3_CONTAIN,PesqPict("SZ3","Z3_CONTAIN"))+" ]" +;
			"  RIC: "+_QRYNFE->Z3_RICENT +;
			"  -->>  "+;
			" "+PadR(DtoC(_QRYNFE->Z3_DTSAIDA),10) +;
			" "+_QRYNFE->Z3_HRSAIDA +;
			" RIC: "+_QRYNFE->Z3_RICSAI+;
			"  "+Transf(_QRYNFE->Z3_PLACA1,PesqPict("SZ3","Z3_PLACA1"))
			
			
			/*			DESABILITADO
			// informacoes do movimento de saida
			If (_QRYNFE->MOV_SAIDA > 0)
			// posiciona no registro d
			dbSelectArea("SZ3")
			SZ3->(dbGoTo(_QRYNFE->MOV_SAIDA))
			@_nLin,060 PSAY DtoC(_QRYNFE->Z3_DTMOVIM)
			@_nLin,075 PSAY _QRYNFE->Z3_HRMOVIM
			
			EndIf
			*/
			_nLin++
			
			// proximo item
			_QRYNFE->(dbSkip())
		EndDo
		// fecha alias da query
		dbSelectArea("_QRYNFE")
		dbCloseArea()
	EndIf
	
	
	// proximo item
	_QRYSZ1->(dbSkip())
	_nLin++
	
	// rodape com sub-total
	If (_cCodProg<>_QRYSZ1->Z1_CODIGO)
		@_nLin,000 PSAY __PrtThinLine()
		_nLin++
	EndIf
	
EndDo

// fecha o alias da query
dbSelectArea("_QRYSZ1")
dbCloseArea()


SET DEVICE TO SCREEN
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Se impressao em disco, chama o gerenciador de impressao...          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If aReturn[5]==1
	dbCommitAll()
	SET PRINTER TO
	OurSpool(wnrel)
ENDIF

MS_FLUSH()

Return

//** funcao que retorna a descricao de campo combobox
Static Function sfCBoxDescr(mvCampo,mvConteudo,mvPesq,mvRet)
Local _aAreaSX3 := SX3->(GetArea())
// retorno em array
// 1 -> S=Sim
// 2 -> S
// 3 -> Sim
Local _aCbox := RetSx3Box(Posicione('SX3',2,mvCampo,'X3CBox()'),,,TamSx3(mvCampo)[1])
Local _nPos  := aScan( _aCbox , {|x| x[mvPesq] == mvConteudo } )
Local _cRet  := If(_nPos>0,_aCbox[_nPos,mvRet],"")
// restaura area inicial
RestArea(_aAreaSX3)
Return(_cRet)
