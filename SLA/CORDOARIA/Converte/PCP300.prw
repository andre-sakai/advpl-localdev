#INCLUDE "rwmake.ch"
#include "topconn.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณPCP300    บ Autor ณ Daniel Rodrigues   บ Data ณ  23/08/05   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Planejamento Simples de Vendas - MRP                       บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Especifico para Arteplas                                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

User Function PCP300


//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Declaracao de Variaveis                                             ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

Local cDesc1         := "Este programa tem como objetivo imprimir relatorio "
Local cDesc2         := "de acordo com os parametros informados pelo usuario."
Local cDesc3         := "Relatorio por Vendas e Carteira de Pedidos"
Local cPict          := ""
Local titulo         := "Planejamento Simples de Vendas"
Local nLin         	 := 80
Local Cabec1      	 := ""
Local Cabec2       	 := ""
Local imprime      	 := .T.
Local aOrd 		     := {}
Private lEnd         := .F.
Private lAbortPrint  := .F.
Private CbTxt        := ""
Private limite       := 132
Private tamanho      := "G"
Private nomeprog     := "PCP300" // Nome do programa para impressao no cabecalho
Private nTipo        := 15
Private aReturn      := { "Zebrado", 1, "Administracao", 1, 2, 1, "", 1}
Private nLastKey     := 0
Private cbtxt      	 := Space(10)
Private cbcont     	 := 00
Private CONTFL     	 := 01
Private m_pag      	 := 01
Private wnrel      	 := "PCP200" // Nome do arquivo usado para impressao em disco

Private cString := "SB1"

dbSelectArea("SB1")
dbSetOrder(1)

cPerg := "PCP300"
nLastKey := 0
VerPerg()
If !Pergunte(cPerg,.T.) .or. (nLastKey == 27 .Or. LastKey() == 27)
	Return(.F.)
EndIf

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Monta a interface padrao com o usuario...                           ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

wnrel := SetPrint(cString,NomeProg,"",@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)

If nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
	Return
Endif

nTipo := If(aReturn[4]==1,15,18)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Processamento. RPTSTATUS monta janela com a regua de processamento. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบFuno    ณRUNREPORT บ Autor ณ AP6 IDE            บ Data ณ  22/01/04   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescrio ณ Funcao auxiliar chamada pela RPTSTATUS. A funcao RPTSTATUS บฑฑ
ฑฑบ          ณ monta a janela com a regua de processamento.               บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Programa principal                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)

Local nOrdem

nProdDia  := {0,0,0,0,0,0,0}
nTSaldo   := 0
nTProd    := {0,0,0,0,0,0,0}
nTPedidos := 0

dbSelectArea(cString)
dbSetOrder(1)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ SETREGUA -> Indica quantos registros serao processados para a regua ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

SetRegua(RecCount())

cQuerA := "SELECT SB1.B1_COD,         "
cQuerA += "       SB1.B1_DESC,        "
cQuerA += "       SB1.B1_TIPO,        "
cQuerA += "       SB1.B1_GRUPO,       "
cQuerA += "       SB1.B1_UM,          "
cQuerA += "       SB2.B2_QATU,        "
cQuerA += "       SC6.C6_QTDVEN,	     "
cQuerA += "       SC6.C6_QTDENT	     "
cQuerA += "FROM   " + RetSQLName("SB1") + " SB1, "
cQuerA += "       " + RetSQLName("SB2") + " SB2, "
cQuerA += "       " + RetSQLName("SC6") + " SC6, "
cQuerA += "       " + RetSQLName("SC5") + " SC5  "
cQuerA += "WHERE SB1.B1_ATIVOAT = 'S' AND SB1.B1_COD     BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "' "
cQuerA += "AND SB1.B1_COD    = SB2.B2_COD                        "
cQuerA += "AND SB1.B1_COD    = SC6.C6_PRODUTO                    "
cQuerA += "AND SC6.C6_NUM    = SC5.C5_NUM                        "
cQuerA += "AND SB2.B2_LOCAL   BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' "
cQuerA += "AND SB1.B1_TIPO   = 'PA'                              "
cQuerA += "AND SB1.B1_GRUPO   BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR06 + "' "
cQuerA += "AND SC5.C5_EMISSAO BETWEEN '" + DTOS(MV_PAR10) + "' AND '" + DTOS(MV_PAR11) + "'  "
cQuerA += "AND SC6.C6_ENTREG  BETWEEN '" + DTOS(MV_PAR07) + "' AND '" + DTOS(MV_PAR08) + "'  "
cQuerA += "AND SC6.C6_QTDVEN  <> SC6.C6_QTDENT                   "
cQuerA += "AND SC6.C6_BLQ = '  '      "
cQuerA += "AND SB1.D_E_L_E_T_ <> '*'  "
cQuerA += "AND SB2.D_E_L_E_T_ <> '*'  "
cQuerA += "AND SC6.D_E_L_E_T_ <> '*'  "
cQuerA += "AND SC5.D_E_L_E_T_ <> '*'  "

If MV_PAR09 = 1
	cQuerA += "ORDER BY SB1.B1_COD      "
ElseIf MV_PAR09 = 2
	cQuerA += "ORDER BY SB1.B1_DESC    "
EndIf

TcQuery cQuerA New Alias "TRA"

DbSelectArea("TRA")
TRA->(dbGoTop())

Cabec1  := "CODIGO           DESCRICAO                           TP   GRUPO   UM    SLD EM EST  PED.VENDAS     POS ATUAL  PROD. DIA-1  PROD. DIA-2  PROD. DIA-3  PROD. DIA-4  PROD. DIA-5  PROD. DIA-6  PROD. DIA-7"
//12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
//         1         2         3         4         5         6         7         8         9         10        11        12        13        14        15        16        17        18        19        20
//   -999,999.999  -999,999.99  -999,999.99  -999,999.99  -999,999.99  -999,999.99  -999,999.99  -999,999.99
While !TRA->(Eof())
	
	//VERIFICA A PRODUวรO DIมRIA DE CADA PRODUTO ATษ 7 DIAS ATRมS
	//INCLUIDO POR CLำVIS - 11/09/2007
	
	For x:=1 to 7
		
		cQuery := "SELECT SUM(D3_QUANT) AS D3_QUANT "
		cQuery += "FROM " + RetSqlName("SD3") + " SD3 "
		cQuery += "WHERE SD3.D_E_L_E_T_ <> '*' AND D3_CF = 'PR0' AND D3_ESTORNO <> 'S' "
		cQuery += "AND D3_FILIAL = '" + xFilial("SD3") + "' "
		cQuery += "AND D3_COD = '"  + TRA->B1_COD + "' "
		cQuery += "AND D3_EMISSAO = '" + DTOS(ddatabase - x) + "' "
		
		If (Select("ART") <> 0)
			dbSelectArea("ART")
			dbCloseArea()
		Endif
		
		TCQUERY cQuery NEW Alias "ART"
		
		dbSelectArea("ART")
		dbGoTop()
		
		nProdDia[x] := ART->D3_QUANT
		
	Next x
	
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Verifica o cancelamento pelo usuario...                             ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู    
	
	If lAbortPrint
		@ nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
		Exit
	Endif
	
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Impressao do cabecalho do relatorio. . .                            ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	
	If nLin > 59 // Salto de Pแgina. Neste caso o formulario tem 55 linhas...
		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
		nLin := 8
	Endif
	
	nPosAtu:= 0
	npedven:= 0
	nqtdatu:= 0
	
	If MV_PAR09 = 1
		auxcod := TRA->B1_COD
	ElseIf MV_PAR09 = 2
		auxcod := SubStr(TRA->B1_DESC,1,35)
	EndIf
	
	@ nLin,000 pSay TRA->B1_COD
	@ nLin,018 pSay SubStr(TRA->B1_DESC,1,35)
	@ nLin,055 pSay TRA->B1_TIPO
	@ nLin,059 pSay TRA->B1_GRUPO
	@ nLin,066 pSay TRA->B1_UM
	nqtdatu:= TRA->B2_QATU
	@ nLin,069 pSay nqtdatu   picture "@E 999,999.999"
	nTSaldo := nTSaldo + nqtdatu
	If MV_PAR09 = 1
		while auxcod = TRA->B1_COD
			npedven += (TRA->C6_QTDVEN - TRA->C6_QTDENT)
			TRA->(DbSkip())
		Enddo
	ElseIf MV_PAR09 = 2
		while auxcod = SubStr(TRA->B1_DESC,1,35)
			npedven += (TRA->C6_QTDVEN - TRA->C6_QTDENT)
			TRA->(DbSkip())
		Enddo
	EndIf
	@ nLin,081 pSay npedven        picture "@E 999,999.999"
	nTPedidos := nTPedidos + npedven
	nPosAtu:= (nqtdatu - npedven)
	@ nLin,97 pSay nPosAtu         picture "@E 999,999.999"
	@ nLin,111 pSay nProdDia[1]    picture "@E 999,999.99"
	nTProd[1] := nTProd[1] + nProdDia[1]
	@ nLin,124 pSay nProdDia[2]    picture "@E 999,999.99"
	nTProd[2] := nTProd[2] + nProdDia[2]
	@ nLin,137 pSay nProdDia[3]    picture "@E 999,999.99"
	nTProd[3] := nTProd[3] + nProdDia[3]
	@ nLin,150 pSay nProdDia[4]    picture "@E 999,999.99"
	nTProd[4] := nTProd[4] + nProdDia[4]
	@ nLin,163 pSay nProdDia[5]    picture "@E 999,999.99"
	nTProd[5] := nTProd[5] + nProdDia[5]
	@ nLin,176 pSay nProdDia[6]    picture "@E 999,999.99"
	nTProd[6] := nTProd[6] + nProdDia[6]
	@ nLin,189 pSay nProdDia[7]    picture "@E 999,999.99"
	nTProd[7] := nTProd[7] + nProdDia[7]
	nLin = nLin + 1
	
EndDo

@ nLin,069 pSay Replicate("-",130)
nLin++
@ nLin,056 pSay "TOTAL ->"
@ nLin,066 pSay nTSaldo   picture "@E 9,999,999.999"
@ nLin,079 pSay nTPedidos picture "@E 9,999,999.999"
@ nLin,095 pSay nTSaldo - nTPedidos picture "@E 9,999,999.999"
@ nLin,109 pSay nTProd[1] picture "@E 9,999,999.99"
@ nLin,122 pSay nTProd[2] picture "@E 9,999,999.99"
@ nLin,135 pSay nTProd[3] picture "@E 9,999,999.99"
@ nLin,148 pSay nTProd[4] picture "@E 9,999,999.99"
@ nLin,161 pSay nTProd[5] picture "@E 9,999,999.99"
@ nLin,174 pSay nTProd[6] picture "@E 9,999,999.99"
@ nLin,187 pSay nTProd[7] picture "@E 9,999,999.99"

DbSelectArea("TRA")
DbCloseArea("TRA")

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Finaliza a execucao do relatorio...                                 ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

SET DEVICE TO SCREEN

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Se impressao em disco, chama o gerenciador de impressao...          ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

If aReturn[5]==1
	dbCommitAll()
	SET PRINTER TO
	OurSpool(wnrel)
Endif
MS_FLUSH()

Return

//Verifica se existe as perguntas, se nao cria
Static Function VerPerg()
dbSelectArea("SX1")
SX1->(DbSetOrder(1))

IF !SX1->(DbSeek(cPerg+"01"))
	RecLock("SX1",.T.)
Else
	RecLock("SX1",.F.)
EndIf
SX1->X1_GRUPO   := cPerg
SX1->X1_ORDEM   := "01"
SX1->X1_PERGUNT := "Do Produto    ?"
SX1->X1_VARIAVL := "Mv_ch1"
SX1->X1_TIPO    := "C"
SX1->X1_TAMANHO := 15
SX1->X1_DECIMAL := 0
SX1->X1_GSC     := "G"
SX1->X1_VAR01   := "Mv_Par01"
SX1->X1_F3      := "SB1"
MsUnLock("SX1")
IF !SX1->(DbSeek(cPerg+"02"))
	RecLock("SX1",.T.)
Else
	RecLock("SX1",.F.)
EndIf
SX1->X1_GRUPO   := cPerg
SX1->X1_ORDEM   := "02"
SX1->X1_PERGUNT := "Ate o Produto     ?"
SX1->X1_VARIAVL := "Mv_ch2"
SX1->X1_TIPO    := "C"
SX1->X1_TAMANHO := 15
SX1->X1_DECIMAL := 0
SX1->X1_GSC     := "G"
SX1->X1_VAR01   := "Mv_Par02"
SX1->X1_F3      := "SB1"
MsUnLock("SX1")

IF !SX1->(DbSeek(cPerg+"03"))
	RecLock("SX1",.T.)
Else
	RecLock("SX1",.F.)
EndIf
SX1->X1_GRUPO   := cPerg
SX1->X1_ORDEM   := "03"
SX1->X1_PERGUNT := "Do Local    ?"
SX1->X1_VARIAVL := "Mv_ch3"
SX1->X1_TIPO    := "C"
SX1->X1_TAMANHO := 02
SX1->X1_DECIMAL := 0
SX1->X1_GSC     := "G"
SX1->X1_VAR01   := "Mv_Par03"
SX1->X1_F3      := ""
MsUnLock("SX1")
IF !SX1->(DbSeek(cPerg+"04"))
	RecLock("SX1",.T.)
Else
	RecLock("SX1",.F.)
EndIf
SX1->X1_GRUPO   := cPerg
SX1->X1_ORDEM   := "04"
SX1->X1_PERGUNT := "Ate o Local     ?"
SX1->X1_VARIAVL := "Mv_ch4"
SX1->X1_TIPO    := "C"
SX1->X1_TAMANHO := 02
SX1->X1_DECIMAL := 0
SX1->X1_GSC     := "G"
SX1->X1_VAR01   := "Mv_Par04"
SX1->X1_F3      := ""
MsUnLock("SX1")

IF !SX1->(DbSeek(cPerg+"05"))
	RecLock("SX1",.T.)
Else
	RecLock("SX1",.F.)
EndIf
SX1->X1_GRUPO   := cPerg
SX1->X1_ORDEM   := "05"
SX1->X1_PERGUNT := "Do Grupo    ?"
SX1->X1_VARIAVL := "Mv_ch5"
SX1->X1_TIPO    := "C"
SX1->X1_TAMANHO := 04
SX1->X1_DECIMAL := 0
SX1->X1_GSC     := "G"
SX1->X1_VAR01   := "Mv_Par05"
SX1->X1_F3      := "SMB"
MsUnLock("SX1")
IF !SX1->(DbSeek(cPerg+"06"))
	RecLock("SX1",.T.)
Else
	RecLock("SX1",.F.)
EndIf
SX1->X1_GRUPO   := cPerg
SX1->X1_ORDEM   := "06"
SX1->X1_PERGUNT := "Ate o Grupo     ?"
SX1->X1_VARIAVL := "Mv_ch6"
SX1->X1_TIPO    := "C"
SX1->X1_TAMANHO := 04
SX1->X1_DECIMAL := 0
SX1->X1_GSC     := "G"
SX1->X1_VAR01   := "Mv_Par06"
SX1->X1_F3      := "SMB"
MsUnLock("SX1")

IF ! SX1->(DbSeek(cPerg+"07"))
	RecLock("SX1",.T.)
Else
	RecLock("SX1",.F.)
EndIf
SX1->X1_GRUPO   := cPerg
SX1->X1_ORDEM   := "07"
SX1->X1_PERGUNT := "Data de Entrega Inicial ?"
SX1->X1_VARIAVL := "Mv_ch7"
SX1->X1_TIPO    := "D"
SX1->X1_TAMANHO := 8
SX1->X1_DECIMAL := 0
SX1->X1_GSC     := "G"
SX1->X1_VAR01   := "Mv_Par07"
SX1->X1_DEF01   := ""
SX1->X1_DEF02   := ""
SX1->X1_F3      := ""
MsUnLock("SX1")
IF ! SX1->(DbSeek(cPerg+"08"))
	RecLock("SX1",.T.)
Else
	RecLock("SX1",.F.)
EndIf
SX1->X1_GRUPO   := cPerg
SX1->X1_ORDEM   := "08"
SX1->X1_PERGUNT := "Data de Entrega Final ?"
SX1->X1_VARIAVL := "Mv_ch8"
SX1->X1_TIPO    := "D"
SX1->X1_TAMANHO := 8
SX1->X1_DECIMAL := 0
SX1->X1_GSC     := "G"
SX1->X1_VAR01   := "Mv_Par08"
SX1->X1_DEF01   := ""
SX1->X1_DEF02   := ""
SX1->X1_F3      := ""
MsUnLock("SX1")

If !dbSeek(cPerg+"09")
	RecLock("SX1",.T.)
Else
	RecLock("SX1",.f.)
EndIf
sx1->x1_grupo  :=cPerg
sx1->x1_ordem  :='09'
sx1->x1_pergunt:='Ordena็ใo ?'
sx1->x1_variavl:='mv_ch9'
sx1->x1_tipo   :='N'
sx1->x1_tamanho:=1
sx1->x1_presel :=1
sx1->x1_gsc    :='C'
sx1->x1_var01  :='mv_par09'
sx1->x1_def01  :='Codigo'
sx1->x1_def02  :='Descri็ใo'

IF ! SX1->(DbSeek(cPerg+"10"))
	RecLock("SX1",.T.)
Else
	RecLock("SX1",.F.)
EndIf
SX1->X1_GRUPO   := cPerg
SX1->X1_ORDEM   := "10"
SX1->X1_PERGUNT := "Data de Emissใo Inicial ?"
SX1->X1_VARIAVL := "Mv_chA"
SX1->X1_TIPO    := "D"
SX1->X1_TAMANHO := 8
SX1->X1_DECIMAL := 0
SX1->X1_GSC     := "G"
SX1->X1_VAR01   := "Mv_Par10"
SX1->X1_DEF01   := ""
SX1->X1_DEF02   := ""
SX1->X1_F3      := ""
MsUnLock("SX1")
IF ! SX1->(DbSeek(cPerg+"11"))
	RecLock("SX1",.T.)
Else
	RecLock("SX1",.F.)
EndIf
SX1->X1_GRUPO   := cPerg
SX1->X1_ORDEM   := "11"
SX1->X1_PERGUNT := "Data de Emissใo Final ?"
SX1->X1_VARIAVL := "Mv_chB"
SX1->X1_TIPO    := "D"
SX1->X1_TAMANHO := 8
SX1->X1_DECIMAL := 0
SX1->X1_GSC     := "G"
SX1->X1_VAR01   := "Mv_Par11"
SX1->X1_DEF01   := ""
SX1->X1_DEF02   := ""
SX1->X1_F3      := ""
MsUnLock("SX1")
Return