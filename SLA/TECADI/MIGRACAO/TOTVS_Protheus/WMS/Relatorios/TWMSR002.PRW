
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSR002                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Impressao dos detalhes das movimentacoes de veiculos    !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 10/12/10                                                !
+------------------+---------------------------------------------------------+
!   ATUALIZACOES                                                             !
+-------------------------------------------+-----------+-----------+--------+
!   Descricao detalhada da atualizacao      !Nome do    ! Analista  !Data da !
!                                           !Solicitante! Respons.  !Atualiz.!
+-------------------------------------------+-----------+-----------+--------+
!                                           !           !           !        !
!                                           !           !           !        !
+-------------------------------------------+-----------+-----------+-------*/

User Function TWMSR002

// declaracao de Variaveis
LOCAL cDesc1       := "Relatorio com a relacao da movimentacoes de   "
LOCAL cDesc2       := "entrada e saida de veiculos                   "
LOCAL cDesc3       := "                                              "
LOCAL titulo       := "Movimentação de Veiculos"
LOCAL Cabec1       := ""
LOCAL Cabec2       := ""
LOCAL imprime      := .T.
LOCAL aOrd         := {"Cliente + Container","Container"}

Local _aPerg := {}
Local _cPerg := PadR("TWMSR002",10)

PRIVATE lAbortPrint:= .F.
PRIVATE limite     := 80//220
PRIVATE tamanho    := "G"
PRIVATE nomeprog   := "TWMSR002"
PRIVATE nTipo      := 18                                      
PRIVATE lEnd       := .F.

PRIVATE aReturn    := { "Zebrado", 1, "Administracao", 1, 2, 1, "", 1}
PRIVATE nLastKey   := 0
PRIVATE cbtxt      := Space(10)
PRIVATE cbcont     := 00
PRIVATE CONTFL     := 01
PRIVATE m_pag      := 01
PRIVATE wnrel      := "TWMSR002"

PRIVATE cString    := "SZ3"

// criacao das Perguntas
aAdd(_aPerg,{"Cliente De?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par01
aAdd(_aPerg,{"Cliente Até?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par02
aAdd(_aPerg,{"Loja De?" ,"C",TamSx3("A1_LOJA")[1],0,"G",,""}) //mv_par03
aAdd(_aPerg,{"Loja Até?" ,"C",TamSx3("A1_LOJA")[1],0,"G",,""}) //mv_par04
aAdd(_aPerg,{"Dt. Movimto. De?" ,"D",8,0,"G",,""}) //mv_par05
aAdd(_aPerg,{"Dt. Movimto. Até?" ,"D",8,0,"G",,""}) //mv_par06
aAdd(_aPerg,{"Container De?" ,"C",TamSx3("ZC_CODIGO")[1],0,"G",,"SZC"}) //mv_par07
aAdd(_aPerg,{"Container Até?" ,"C",TamSx3("ZC_CODIGO")[1],0,"G",,"SZC"}) //mv_par08
aAdd(_aPerg,{"Tipo Movimentação?" ,"N",1,0,"C",{"Entrada","Saida","Ambos","Saldo no Pátio"},""}) //mv_par09
aAdd(_aPerg,{"Tipo de Container De?" ,"C",TamSx3("ZC_TIPO")[1],0,"G",,"ZA"}) //mv_par10
aAdd(_aPerg,{"Tipo de Container Até?" ,"C",TamSx3("ZC_TIPO")[1],0,"G",,"ZA"}) //mv_par11
aAdd(_aPerg,{"Conteúdo Carga?" ,"N",1,0,"C",{"Cheio","Vazio","Ambos"},""}) //mv_par12
aAdd(_aPerg,{"Transportadora De?" ,"C",TamSx3("A4_COD")[1],0,"G",,"SA4"}) //mv_par13
aAdd(_aPerg,{"Transportadora Até?" ,"C",TamSx3("A4_COD")[1],0,"G",,"SA4"}) //mv_par14
aAdd(_aPerg,{"Placa De?" ,"C",TamSx3("DA3_COD")[1],0,"G",,"DA3"}) //mv_par15
aAdd(_aPerg,{"Placa Até?" ,"C",TamSx3("DA3_COD")[1],0,"G",,"DA3"}) //mv_par16
aAdd(_aPerg,{"Programação De?" ,"C",TamSx3("Z1_CODIGO")[1],0,"G",,""}) //mv_par17
aAdd(_aPerg,{"Programação Até?" ,"C",TamSx3("Z1_CODIGO")[1],0,"G",,""}) //mv_par18

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

Local _cQuery
Local _nLin := 80

// controle para quebras
Local _cChave := ""
// quantidade de movimentacoes
Local _nQtdMov := 0
Local _nTotMov := 0

// titulo
If (aReturn[8]==1) // por cliente + container
	Cabec1 := OemToAnsi("Movimentação de Veiculos - Cliente + Container")
	Cabec2 := OemToAnsi("Container      Tipo             Tamanho      Data        Hora   Tp Movto  Conteudo    Mov Duplo  Programacao    Placa    Motorista              Transportadora                 Pç Origem            Pç Destino")
ElseIf (aReturn[8]==2) // por container
	Cabec1 := OemToAnsi("Movimentação de Veiculos - Container")
	Cabec2 := OemToAnsi("Data        Hora   Tp Movto  Conteudo    Mov Duplo  Programacao  Placa     Motorista          Transportadora                    Cliente                          Pç Origem              Pç Destino")
EndIf

// monta query
_cQuery := "SELECT "
// chave para ordem e quebra
If(aReturn[8]==1) // por cliente + container
	_cQuery += "Z3_CLIENTE+Z3_LOJA "
ElseIf (aReturn[8]==2) // por container
	_cQuery += "Z3_CONTAIN "	
EndIf
_cQuery += "IT_CHAVE, * "

// movimentacoes
_cQuery += "FROM "+RetSqlName("SZ3")+" SZ3 "
// filtro das movimentacoes
_cQuery += "WHERE "+RetSqlCond("SZ3")
_cQuery += "AND Z3_CLIENTE BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' "
_cQuery += "AND Z3_LOJA    BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' "
_cQuery += "AND Z3_DTMOVIM BETWEEN '"+DtoS(mv_par05)+"' AND '"+DtoS(mv_par06)+"' "
_cQuery += "AND Z3_CONTAIN BETWEEN '"+mv_par07+"' AND '"+mv_par08+"' "
// tipo de container
_cQuery += "AND Z3_TIPCONT BETWEEN '"+mv_par10+"' AND '"+mv_par11+"' "
// tipo de movimento
If (mv_par09==1) // entrada
	_cQuery += "AND Z3_TPMOVIM = 'E' "
ElseIf (mv_par09==2) // saida
	_cQuery += "AND Z3_TPMOVIM = 'S' "
EndIf

// conteudo do container
If (mv_par12==1) // cheio
	_cQuery += "AND Z3_CONTEUD = 'C' "
ElseIf (mv_par12==2)
	_cQuery += "AND Z3_CONTEUD = 'V' "
EndIf

// transportadora
_cQuery += "AND Z3_TRANSP BETWEEN '"+mv_par13+"' AND '"+mv_par14+"' "

// placa
_cQuery += "AND Z3_PLACA1 BETWEEN '"+mv_par15+"' AND '"+mv_par16+"' "

// programacao
_cQuery += "AND Z3_PROGRAM BETWEEN '"+mv_par17+"' AND '"+mv_par18+"' "

// saldo no patio (containers que entraram e nao sairam)
If (mv_par09==4)
	_cQuery += "AND Z3_TPMOVIM = 'E' AND Z3_DTSAIDA = ' ' "
EndIf
// ordem dos dados
_cQuery += "ORDER BY 1, "
// chave para ordem e quebra
If(aReturn[8]==1) // por cliente + container
	_cQuery += "Z3_CONTAIN, Z3_DTMOVIM "
ElseIf (aReturn[8]==2) // por container
	_cQuery += "Z3_DTMOVIM "	
EndIf

MemoWrit("c:\query\TWMSR002.txt",_cQuery)

If (Select("_QRYSZ3")<>0)
	dbSelectArea("_QRYSZ3")
	dbCloseArea()
EndIf

dbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_QRYSZ3",.F.,.T.)
// tratamento para campos data
TcSetField("_QRYSZ3","Z3_DTMOVIM","D")

dbSelectArea("_QRYSZ3")
_QRYSZ3->(dbGotop()) 

While _QRYSZ3->(!Eof())
	If _nLin > 58
		cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
		_nLin := 9
	EndIf

	// quebra dos dados
	If (_cChave<>_QRYSZ3->IT_CHAVE)
		// atualiza variavel do controle da quebra
		_cChave := _QRYSZ3->IT_CHAVE
		// zera contador
		_nQtdMov := 0
		// chave para ordem e quebra
		If (aReturn[8]==1) // por cliente + container
			@_nLin,000 PSAY "Cliente: "+_QRYSZ3->Z3_CLIENTE+"/"+_QRYSZ3->Z3_LOJA+": "+Left(Posicione("SA1",1,xFilial("SA1")+_QRYSZ3->(Z3_CLIENTE+Z3_LOJA),"A1_NOME"),50)
		ElseIf (aReturn[8]==2) // por container
			@_nLin,000 PSAY "Container: "+Transf(_QRYSZ3->Z3_CONTAIN,PesqPict("SZC","ZC_CODIGO")) +;
							" Tamanho: "+sfCBoxDescr("Z2_TAMCONT",_QRYSZ3->Z3_TAMCONT,2,3) +;
							" Tipo: "+PadR(Tabela("ZA",_QRYSZ3->Z3_TIPCONT),20)
		EndIf
		// proxima linha
		_nLin++
	EndIf

	// impressao dos dados da movimentacao
	If (aReturn[8]==1) // por cliente + container
		@_nLin,000 PSAY Transf(_QRYSZ3->Z3_CONTAIN,PesqPict("SZC","ZC_CODIGO")) +;
						"  "+PadR(Tabela("ZA",_QRYSZ3->Z3_TIPCONT),15)+;
						"  "+sfCBoxDescr("Z2_TAMCONT",_QRYSZ3->Z3_TAMCONT,2,3) +;
						"  "+DtoC(_QRYSZ3->Z3_DTMOVIM) +;
						"  "+_QRYSZ3->Z3_HRMOVIM +;
						"  "+If(_QRYSZ3->Z3_TPMOVIM=="E","ENTRADA","SAIDA  ") +;
						"   "+PadR(sfCBoxDescr("Z2_CONTEUD",_QRYSZ3->Z3_CONTEUD,2,3),10) +;
						"  "+If(_QRYSZ3->Z3_DUPLO=="S","SIM","NAO") +;
						"        "+_QRYSZ3->Z3_PROGRAM+"/"+_QRYSZ3->Z3_ITEPROG +;
						"      "+_QRYSZ3->Z3_PLACA1 +;
						"  "+Left(Posicione("DA4",1, xFilial("DA4")+_QRYSZ3->Z3_MOTORIS  ,"DA4_NOME"),20)+;
						"   "+Left(Posicione("SA4",1, xFilial("SA4")+_QRYSZ3->Z3_TRANSP   ,"A4_NOME") ,30)+;
						" "+Left(Posicione("SZB",1, xFilial("SZB")+_QRYSZ3->Z3_PRCORIG   ,"ZB_DESCRI") ,20)+; // praca origem
						" "+Left(Posicione("SZB",1, xFilial("SZB")+_QRYSZ3->Z3_PRCDEST   ,"ZB_DESCRI") ,20) // praca destino
						
	ElseIf (aReturn[8]==2) // por container
		@_nLin,000 PSAY DtoC(_QRYSZ3->Z3_DTMOVIM) +;
						"  "+_QRYSZ3->Z3_HRMOVIM +;
						"  "+If(_QRYSZ3->Z3_TPMOVIM=="E","ENTRADA","SAIDA  ") +;
						"   "+PadR(sfCBoxDescr("Z2_CONTEUD",_QRYSZ3->Z3_CONTEUD,2,3),10) +;
						"  "+If(_QRYSZ3->Z3_DUPLO=="S","SIM","NAO") +;
						"        "+_QRYSZ3->Z3_PROGRAM+"/"+_QRYSZ3->Z3_ITEPROG +;
						"    "+_QRYSZ3->Z3_PLACA1 +;
						"   "+Left(Posicione("DA4",1, xFilial("DA4")+_QRYSZ3->Z3_MOTORIS  ,"DA4_NOME"),15) +;
						"    "+Left(Posicione("SA4",1, xFilial("SA4")+_QRYSZ3->Z3_TRANSP   ,"A4_NOME") ,30) +;
						"    "+Left(Posicione("SA1",1,xFilial("SA1")+_QRYSZ3->(Z3_CLIENTE+Z3_LOJA),"A1_NOME"),30)+;
						"   "+Left(Posicione("SZB",1, xFilial("SZB")+_QRYSZ3->Z3_PRCORIG   ,"ZB_DESCRI") ,20)+; // praca origem
						"   "+Left(Posicione("SZB",1, xFilial("SZB")+_QRYSZ3->Z3_PRCDEST   ,"ZB_DESCRI") ,20) // praca destino
						
	EndIf
	
	// controle do contador de movimentacoes
	_nQtdMov ++
	// controle total de movimentacoes
	_nTotMov ++
    
    // proximo item
	_QRYSZ3->(dbSkip())
	_nLin++

	// rodape com sub-total
	If (_cChave<>_QRYSZ3->IT_CHAVE)
		@_nLin,000 PSAY __PrtThinLine()
		_nLin++
		@_nLin,000 PSAY "Total: "+Transf(_nQtdMov,"@E 999999")
		_nLin++		
		@_nLin,000 PSAY __PrtThinLine()
		_nLin++
	EndIf

EndDo

// totalizador
@_nLin,000 PSAY "TOTAL GERAL: "+Transf(_nTotMov,"@E 999999")
_nLin++		
@_nLin,000 PSAY __PrtThinLine()

// fecha o alias da query
dbSelectArea("_QRYSZ3")
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