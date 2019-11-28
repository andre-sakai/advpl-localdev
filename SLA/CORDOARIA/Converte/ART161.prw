#INCLUDE "rwmake.ch"
#include "topconn.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณART161    บ Autor ณ Sidney Gama        บ Data ณ  16/03/05   บฑฑ
ฑฑบAltera็ใo: Luciano Henrique                       บ Data ณ  30/03/05   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Relatorio dos Apontamentos de Produ็ใo                     บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Especifico para Arteplas                                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

User Function ART161


//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Declaracao de Variaveis                                             ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

Local cDesc1         	:= "Este programa tem como objetivo imprimir relatorio "
Local cDesc2         	:= "de acordo com os parametros informados pelo usuario."
Local cDesc3         	:= "Relatorio de Apontamento de Produ็ใo"
Local cPict          	:= ""
Local titulo         	:= "Apontamentos de Produ็ใo"
Local nLin         		:= 57

Local Cabec1      		:= ""
Local Cabec2       		:= ""
Local imprime      		:= .T.
Local aOrd 				:= {}
Private lEnd         	:= .F.
Private lAbortPrint  	:= .F.
Private CbTxt        	:= ""
Private limite       	:= 160
Private cPerg           := "ART161"
Private tamanho      	:= "G"
Private nomeprog     	:= "ART161" // Nome do programa para impressao no cabecalho
Private nTipo        	:= 18
Private aReturn      	:= { "Zebrado", 1, "Administracao", 1, 2, 1, "", 1}
Private nLastKey     	:= 0
Private cbtxt      		:= Space(10)
Private cbcont     		:= 00
Private CONTFL     		:= 01
Private m_pag      		:= 01
Private wnrel      		:= "ART161" // Nome do arquivo usado para impressao em disco

cPerg := "ART161"
aRegistros := {}
AADD(aRegistros,{cPerg,"01","Produto de        ?","","","mv_ch1","C",15,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SB1","","","","",""})
AADD(aRegistros,{cPerg,"02","Produto ate       ?","","","mv_ch2","C",15,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SB1","","","","",""})
AADD(aRegistros,{cPerg,"03","Data de           ?","","","mv_ch3","D",08,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"04","Data ate          ?","","","mv_ch4","D",08,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"05","Centro Custo de   ?","","","mv_ch5","C",09,0,0,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","CTT","","","","",""})
AADD(aRegistros,{cPerg,"06","Centro Custo ate  ?","","","mv_ch6","C",09,0,0,"G","","mv_par06","","","","","","","","","","","","","","","","","","","","","","","","","CTT","","","","",""})
AADD(aRegistros,{cPerg,"07","Armazem de        ?","","","mv_ch7","C",02,0,0,"G","","mv_par07","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"08","Armazem ate       ?","","","mv_ch8","C",02,0,0,"G","","mv_par08","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"09","Analitico/Sintetico?","","","mv_ch9","N",01,0,0,"C","","mv_par09","Analitico","","","","","Sintetico","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"10","Usuario de        ?","","","mv_cha","C",15,0,0,"G","","mv_par10","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"11","Usuario ate       ?","","","mv_chb","C",15,0,0,"G","","mv_par11","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"12","Imprime Resumo    ?","","","mv_chc","N",01,0,0,"C","","mv_par12","Sim","","","","","Nao","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"13","Grupo de          ?","","","mv_chd","C",04,0,0,"G","","mv_par13","","","","","","","","","","","","","","","","","","","","","","","","","SBM","","","","",""})
AADD(aRegistros,{cPerg,"14","Grupo ate         ?","","","mv_che","C",04,0,0,"G","","mv_par14","","","","","","","","","","","","","","","","","","","","","","","","","SBM","","","","",""})
AADD(aRegistros,{cPerg,"15","Turno             ?","","","mv_chf","N",01,0,0,"C","","mv_par15","1o Turno","","","","","2o Turno","","","","","3o Turno","","","","","Todos","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"16","Considera Data    ?","","","mv_chg","N",01,0,0,"C","","mv_par16","Apontamento","","","","","Producao","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"17","Controla Etiqueta ?","","","mv_chg","N",01,0,0,"C","","mv_par17","S","","","","","N","","","","","","","","","","","","","","","","","","","","","","","",""})

dbSelectArea("SX1")
dbSeek(cPerg)
If !Found()
	dbSeek(cPerg)
	While SX1->X1_GRUPO==cPerg.and.!Eof()
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock("SX1")
		dbSkip()
	End
	For i:=1 to Len(aRegistros)
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			FieldPut(j,aRegistros[i,j])
		Next
		MsUnlock("SX1")
	Next
Endif

pergunte(cPerg,.F.)

Private cString := "SC2"

dbSelectArea("SC2")
dbSetOrder(1)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Monta a interface padrao com o usuario...                           ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

wnrel := SetPrint(cString,NomeProg,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)

If nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
	Return
Endif

nTipo := If(aReturn[4]==1,15,18)
nTipo := 15
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

dbSelectArea(cString)
dbSetOrder(1)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ SETREGUA -> Indica quantos registros serao processados para a regua ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

SetRegua(RecCount())

If MV_PAR09 = 1  // Analitico
	cQuery := "SELECT "
	cQuery += " D3_TM, D3_COD, D3_UM, D3_QUANT, D3_OP, D3_LOCAL, D3_EMISSAO, D3_CC, D3_PARCTOT, D3_ESTORNO, D3_SEGUM, "
	cQuery += " D3_QTSEGUM, D3_USUARIO, B1_DESC, B1_TIPO, B1_GRUPO, D3_DTPROD "
	cQuery += "  FROM " + RetSqlName("SD3") + " SD3, " + RetSqlName("SB1") + " SB1 "
	cQuery += " WHERE SD3.D_E_L_E_T_ <> '*' AND SB1.D_E_L_E_T_ <> '*'  AND D3_TM = '003' AND D3_ESTORNO <> 'S' "
	cQuery += "      AND D3_FILIAL = '" + xFilial("SD3") + "' "
	cQuery += "      AND B1_FILIAL = '" + xFilial("SB1") + "' "
	cQuery += "      AND B1_GRUPO   BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "' "
	cQuery += "      AND D3_COD    = B1_COD "
	cQuery += "      AND D3_COD     BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' "
	If mv_par16 == 1
		cQuery += " AND D3_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	Else
		cQuery += " AND D3_DTPROD BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	Endif
	If mv_par15 <> 4
		cQuery += " AND D3_TURNO = '" + StrZero(mv_par15,1) + "' "
	Endif
	cQuery += "      AND D3_CC      BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
	cQuery += "      AND D3_LOCAL   BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "' "
	cQuery += "      AND D3_USUARIO BETWEEN '" + mv_par10 + "' AND '" + mv_par11 + "' "
	If mv_par17 == 1
		QCqUERY+= "AND B1_CONTETQ = 'S' "
	EndIf
	If mv_par16 == 1
		cQuery += "ORDER BY D3_COD, D3_EMISSAO "
	Else
		cQuery += "ORDER BY D3_COD, D3_DTPROD "
	Endif
Else
	cQuery := "SELECT "
	cQuery += " D3_COD, B1_DESC, D3_UM, SUM(D3_QUANT) AS D3_QUANT, SUM(D3_QTSEGUM) AS D3_QTSEGUM, B1_GRUPO "
	cQuery += "  FROM " + RetSqlName("SD3") + " SD3, " + RetSqlName("SB1") + " SB1 "
	cQuery += " WHERE SD3.D_E_L_E_T_ <> '*' AND SB1.D_E_L_E_T_ <> '*'  AND D3_TM = '003' AND D3_ESTORNO <> 'S' "
	cQuery += "      AND D3_FILIAL = '" + xFilial("SD3") + "' "
	cQuery += "      AND B1_FILIAL = '" + xFilial("SB1") + "' "
	cQuery += "      AND B1_GRUPO   BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "' "
	cQuery += "      AND D3_COD    = B1_COD "
	cQuery += "      AND D3_COD     BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' "
	If mv_par16 == 1
		cQuery += " AND D3_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	Else
		cQuery += " AND D3_DTPROD BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	Endif
	If mv_par15 <> 4
		cQuery += " AND D3_TURNO = '" + StrZero(mv_par15,1) + "' "
	Endif
	If mv_par17 == 1
		QCqUERY+= "AND B1_CONTETQ = 'S' "
	EndIf
	cQuery += "      AND D3_CC      BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
	cQuery += "      AND D3_LOCAL   BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "' "
	cQuery += "      AND D3_USUARIO BETWEEN '" + mv_par10 + "' AND '" + mv_par11 + "' "
	cQuery += " GROUP BY B1_GRUPO,D3_COD, B1_DESC, D3_UM "
	cQuery += " ORDER BY B1_GRUPO,D3_COD "
EndIf

TcQuery cQuery New Alias "TRB"

If mv_par16 == 1
	TcSetField("TRB","D3_EMISSAO","D",8,0)
Else
	TcSetField("TRB","D3_DTPROD","D",8,0)
Endif

DbSelectArea("TRB")
TRB->(dbGoTop())

If MV_PAR09 = 1  // Analitico
	Cabec1  := "Produto           Descri็ใo                       TP GR    UM    Quantidade     UM Pad  Quant. 1a UM     Ord.Produ็ใo   ARM  Emissใo        C.Custo    P/T  EST   Usuแrio"
	//          0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345
	//                    10        20        30        40        50        60        70        80        90       100        110      120       130        140       150       160       170       180       190
	//                                                                        99,999,999.99     XX     99,999,999.99     XXXXXXXXXXX    XX   XX/XX/XXXX     XXXXXXXX    X    X    XX          XXXXXXXXXXXXXXX
Else
	Cabec1  := "Grupo Descricao                       Produto           Descri็ใo                                       Quantidade     UM Padrao      Quant. 1a UM                                         "
	//          XXXX  XXXXXXXXXXXXXXXXXXXXXXXXXXXXX   XXXXXXXXXXXXXXX   XXXXXXXXXXXXXXXXXXXXXXXXXXXXX                99,999,999.99     XX            99,999,999.99
	//          0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345
	//                    10        20        30        40        50        60        70        80        90       100        110      120       130        140       150       160       170       180       190
EndIf

nTOTQTD := 0
nTOTVLR := 0
nTOTVLR2:= 0
nTOTGRUP:= 0
cCodAux := ''
cGrupo  := TRB->B1_GRUPO

While !TRB->(Eof())
//	nTOTVLR := 0
	_cCod := TRB->D3_COD
	While !TRB->(Eof()) .and. TRB->D3_COD == _cCod
		If nLin > 56
			Cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
			nLin := 8
		Endif
		If MV_PAR09 = 1  // Analitico
			@ nLin,000 PSay TRB->D3_COD     //15
			@ nLin,018 PSay Left(TRB->B1_DESC,30)    //30
			@ nLin,050 PSay TRB->B1_TIPO    //2
			@ nLin,053 PSay TRB->B1_GRUPO   //4

			If TRB->D3_UM == "KG"
				@ nLin,059 PSay TRB->D3_UM      //2
				@ nLin,062 PSay transform(TRB->D3_QUANT,"@E 99,999,999.99")
				nTOTVLR += TRB->D3_QUANT
				nTOTVLR2+= TRB->D3_QUANT
			Else
				@ nLin,059 PSay TRB->D3_SEGUM      //2
				@ nLin,062 PSay transform(TRB->D3_QTSEGUM,"@E 99,999,999.99")
				@ nLin,080 PSay TRB->D3_UM       //2
				@ nLin,087 PSay transform(TRB->D3_QUANT,"@E 99,999,999.99")
				nTOTVLR += TRB->D3_QTSEGUM
				nTOTVLR2+= TRB->D3_QTSEGUM
			Endif
			
			@ nLin,105 PSay TRB->D3_OP         // 13
			@ nLin,120 PSay TRB->D3_LOCAL      //2

			If mv_par16 == 1
				@ nLin,125 PSay TRB->D3_EMISSAO    //8
			Else
				@ nLin,125 PSay TRB->D3_DTPROD
			Endif
			@ nLin,140 PSay TRB->D3_CC        // 9
			@ nLin,152 PSay TRB->D3_PARCTOT     //1
			@ nLin,157 PSay TRB->D3_ESTORNO    //1
			@ nLin,162 PSay TRB->D3_USUARIO     //15

		ElseIf MV_PAR09 = 2   // Sintetico
			If cCodAux <> TRB->B1_GRUPO+TRB->D3_COD
				@ nLin,000 PSay TRB->B1_GRUPO   //4
				@ nLin,006 PSay Left(Posicione("SBM",1,xFilial("SBM")+TRB->B1_GRUPO,"BM_DESC"),30)    //30
				@ nLin,038 PSay TRB->D3_COD     //15
				@ nLin,056 PSay Left(TRB->B1_DESC,30)    //30
			  
					If TRB->D3_UM == "KG"
					@ nLin,101 PSay transform(TRB->D3_QUANT,"@E 99,999,999.99")
					nTOTVLR += TRB->D3_QUANT
					nTOTVLR2+= TRB->D3_QUANT
					nTOTGRUP+= TRB->D3_QUANT
				Else
					@ nLin,101 PSay transform(TRB->D3_QTSEGUM,"@E 99,999,999.99")
					@ nLin,119 PSay TRB->D3_UM       //2
					@ nLin,133 PSay transform(TRB->D3_QUANT,"@E 99,999,999.99")				
					nTOTVLR += TRB->D3_QTSEGUM
					nTOTVLR2+= TRB->D3_QTSEGUM
					nTOTGRUP+= TRB->D3_QTSEGUM
				EndIf       
				
				cCodAux:= TRB->B1_GRUPO+TRB->D3_COD
			EndIf
		EndIf
		nLin++
		TRB->(DbSkip())
		If TRB->B1_GRUPO <> cGrupo
			@ nLin,000 PSay "Total do Grupo "+cGrupo+" - "+Left(Posicione("SBM",1,xFilial("SBM")+cGrupo,"BM_DESC"),30)+Repli("-",45)+">"
			@ nLin,101 PSay transform(nTOTGRUP,"@E 99,999,999.99")
			nTOTGRUP:= 0
			cGrupo  := TRB->B1_GRUPO
			nLin++
			nLin++
		Endif
	Enddo

	If MV_PAR09 = 1  // Analitico
		@ nLin,062 Psay "-------------"
		nLin++
		@ nLin,018 PSay "Total do Produto"
		@ nLin,062 PSay transform(nTOTVLR,"@E 99,999,999.99")
		nLin++
		nLin++
	EndIf
EndDo
If MV_PAR09 = 1 // Analitico
	If nTOTVLR > 0
		nLin++
		@ nLin,018 PSay "Total Geral"
		@ nLin,062 PSay transform(nTOTVLR2,"@E 99,999,999.99")
	Endif
Else 		// Sint้tico
	If nTOTVLR > 0
		nLin++
		@ nLin,000 PSay "Total Geral"
		@ nLin,101 PSay transform(nTOTVLR2,"@E 99,999,999.99")
	Endif
Endif
DbSelectArea("TRB")
DbCloseArea("TRB")

If mv_par12 == 1  // Imprime Folha de Resumo
	titulo  := "Resumo dos Apontamentos de Produ็ใo"
	Cabec1  := "Tipo  Descricao                          Quantidade         Padrao      "
	//          XXXX  XXXXXXXXXXXXXXXXXXXXXXXXXXXXX   99,999,999.99     999,999.99
	//          0123456789012345678901234567890123456789012345678901234567890123456789012
	//                    10        20        30        40        50        60        70
	Cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
	nLin := 8
	
	// Query com o Resumo por CORDA
	cQuery := " SELECT "
	cQuery += " D3_COD, SUM(D3_QTSEGUM) AS D3_QTSEGUM, SUM(D3_QUANT) AS D3_QUANT, B1_TIPOCOR "
	cQuery += " FROM SD3010 SD3, SB1010 SB1 "
	cQuery += " WHERE SD3.D_E_L_E_T_ <> '*' AND SB1.D_E_L_E_T_ <> '*'  AND D3_TM = '003' AND D3_ESTORNO <> 'S' "
	cQuery += " AND D3_COD    = B1_COD "
	cQuery += " AND B1_GRUPO   BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "' "
	cQuery += " AND D3_COD     BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' "
	If mv_par16 == 1
		cQuery += " AND D3_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	Else
		cQuery += " AND D3_DTPROD BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	Endif
	If mv_par15 <> 4
		cQuery += " AND D3_TURNO = '" + StrZero(mv_par15,1) + "' "
	Endif
	cQuery += " AND D3_CC      BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
	cQuery += " AND D3_LOCAL   BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "' "
	cQuery += " AND D3_USUARIO BETWEEN '" + mv_par10 + "' AND '" + mv_par11 + "' AND D3_GRUPO BETWEEN 'A' AND 'FZZZ' "
	cQuery += " GROUP BY B1_TIPOCOR,D3_COD "
	cQuery += " ORDER BY B1_TIPOCOR "
	TcQuery cQuery New Alias "TRB1"
	
	// Query com o Resumo por FIO
	cQuery := " SELECT "
	cQuery += " D3_COD, SUM(D3_QTSEGUM) AS D3_QTSEGUM, SUM(D3_QUANT) AS D3_QUANT, B1_TIPOFIO "
	cQuery += " FROM SD3010 SD3, SB1010 SB1 "
	cQuery += " WHERE SD3.D_E_L_E_T_ <> '*' AND SB1.D_E_L_E_T_ <> '*'  AND D3_TM = '003' AND D3_ESTORNO <> 'S' "
	cQuery += " AND D3_COD    = B1_COD "
	cQuery += " AND B1_GRUPO   BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "' "
	cQuery += " AND D3_COD     BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' "
	If mv_par16 == 1
		cQuery += " AND D3_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	Else
		cQuery += " AND D3_DTPROD BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	Endif
	If mv_par15 <> 4
		cQuery += " AND D3_TURNO = '" + StrZero(mv_par15,1) + "' "
	Endif
	cQuery += " AND D3_CC      BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
	cQuery += " AND D3_LOCAL   BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "' "
	cQuery += " AND D3_USUARIO BETWEEN '" + mv_par10 + "' AND '" + mv_par11 + "' AND B1_GRUPO BETWEEN 'A' AND 'FZZZ' "
	cQuery += " GROUP BY B1_TIPOFIO,D3_COD "
	cQuery += " ORDER BY B1_TIPOFIO "
	TcQuery cQuery New Alias "TRB2"
	
	//Query com o Resumo dos Produtos FORA DE PESO (B1_FORAPES="S")
	cQuery := " SELECT "
	cQuery += " SUM(D3_QUANT) AS D3_QUANT "
	cQuery += " FROM SD3010 SD3, SB1010 SB1 "
	cQuery += " WHERE SD3.D_E_L_E_T_ <> '*' AND SB1.D_E_L_E_T_ <> '*'  AND D3_TM = '003' AND D3_ESTORNO <> 'S' "
	cQuery += " AND D3_COD    = B1_COD "
	cQuery += " AND B1_FORAPES = 'S' "
	cQuery += " AND B1_GRUPO   BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "' "
	cQuery += " AND D3_COD     BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' "
	If mv_par16 == 1
		cQuery += " AND D3_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	Else
		cQuery += " AND D3_DTPROD BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	Endif
	If mv_par15 <> 4
		cQuery += " AND D3_TURNO = '" + StrZero(mv_par15,1) + "' "
	Endif
	cQuery += " AND D3_CC      BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
	cQuery += " AND D3_LOCAL   BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "' "
	cQuery += " AND D3_USUARIO BETWEEN '" + mv_par10 + "' AND '" + mv_par11 + "' "
	TcQuery cQuery New Alias "TRB3"
	
		// Query com o Resumo por MATERIAL
	cQuery := " SELECT "
	cQuery += " D3_COD, SUM(D3_QTSEGUM) AS D3_QTSEGUM, SUM(D3_QUANT) AS D3_QUANT, B1_MP "
	cQuery += " FROM SD3010 SD3, SB1010 SB1 "
	cQuery += " WHERE SD3.D_E_L_E_T_ <> '*' AND SB1.D_E_L_E_T_ <> '*'  AND D3_TM = '003' AND D3_ESTORNO <> 'S' "
	cQuery += " AND D3_COD    = B1_COD "
	cQuery += " AND B1_GRUPO   BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "' "
	cQuery += " AND D3_COD     BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' "
	If mv_par16 == 1
		cQuery += " AND D3_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	Else
		cQuery += " AND D3_DTPROD BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	Endif
	If mv_par15 <> 4
		cQuery += " AND D3_TURNO = '" + StrZero(mv_par15,1) + "' "
	Endif
	cQuery += " AND D3_CC      BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
	cQuery += " AND D3_LOCAL   BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "' "
	cQuery += " AND D3_USUARIO BETWEEN '" + mv_par10 + "' AND '" + mv_par11 + "' AND B1_GRUPO BETWEEN 'A' AND 'FZZZ' "
	cQuery += " GROUP BY B1_MP,D3_COD "
	cQuery += " ORDER BY B1_MP "
	TcQuery cQuery New Alias "TRB4"
	
		// Query com o Resumo por GRUPO (FIOS, FIBRAS, GRรOS)
	cQuery := " SELECT SUM(D3_QUANT) AS D3_QUANT, D3_GRUPO "
	cQuery += " FROM SD3010 SD3 "
	cQuery += " WHERE SD3.D_E_L_E_T_ <> '*' AND D3_TM = '003' AND D3_ESTORNO <> 'S' "
	cQuery += " AND D3_GRUPO   BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "' "
	cQuery += " AND D3_COD     BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' "
	If mv_par16 == 1
		cQuery += " AND D3_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	Else
		cQuery += " AND D3_DTPROD BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
	Endif
	If mv_par15 <> 4
		cQuery += " AND D3_TURNO = '" + StrZero(mv_par15,1) + "' "
	Endif
	cQuery += " AND D3_CC      BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
	cQuery += " AND D3_LOCAL   BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "' "
	cQuery += " AND D3_USUARIO BETWEEN '" + mv_par10 + "' AND '" + mv_par11 + "' AND D3_GRUPO BETWEEN 'G' AND 'IZZZ' "
	cQuery += " GROUP BY D3_GRUPO "
	cQuery += " ORDER BY D3_GRUPO "
	TcQuery cQuery New Alias "TRB5"
	
	
	DbSelectArea("TRB1")
	TRB1->(DbGoTop())
	cCodAux := ''
	While !TRB1->(Eof())
		_nTotProd 	:= 0
		_nTotMult	:= 0
		_cCod 		:= TRB1->B1_TIPOCOR
		While !TRB1->(Eof()) .and. TRB1->B1_TIPOCOR == _cCod
			If nLin > 56
				Cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
				nLin := 8
			Endif
			If Posicione("SB1",1,xFilial("SB1")+TRB1->D3_COD,"B1_UM") == "KG"
				_nTotProd := _nTotProd + TRB1->D3_QUANT
//				_nTotMult := _nTotMult + (TRB1->D3_QUANT*Val(Posicione("SB1",1,xFilial("SB1")+TRB1->D3_COD,"B1_BITOLA"))) --Bitola nใo ้ mais Alfanumerico
				_nTotMult := _nTotMult + (TRB1->D3_QUANT*(Posicione("SB1",1,xFilial("SB1")+TRB1->D3_COD,"B1_BITOLA")))
			Else
				_nTotProd := _nTotProd + TRB1->D3_QTSEGUM
//				_nTotMult := _nTotMult + (TRB1->D3_QTSEGUM*Val(Posicione("SB1",1,xFilial("SB1")+TRB1->D3_COD,"B1_BITOLA"))) --Bitola nใo ้ mais Alfanumerico
				_nTotMult := _nTotMult + (TRB1->D3_QTSEGUM*(Posicione("SB1",1,xFilial("SB1")+TRB1->D3_COD,"B1_BITOLA")))
			Endif
			TRB1->(DbSkip())
		Enddo
		_nPadrao := _nTotMult / _nTotProd
		_cTIPOCOR := _cCod
		If _cTIPOCOR = "TOR"
			_cDESCCOR := "TORCIDA"
		Elseif _cTIPOCOR = "TRA"
			_cDESCCOR := "TRANCADA"
		Elseif _cTIPOCOR = "FIO"
			_cDESCCOR := "FIO"
		Elseif _cTIPOCOR = "FIB"
			_cDESCCOR := "FIBRA"
		Elseif _cTIPOCOR = "TRR"
			_cDESCCOR := "TORCIDA RETORCIDA"
		Else
			_cDESCCOR := "OUTROS"
		Endif
		@ nLin,000 PSay _cTIPOCOR
		@ nLin,006 PSay _cDESCCOR
		@ nLin,038 PSay _nTotProd picture "@E 99,999,999.99"
		@ nLin,056 PSay _nPadrao picture "@E 999,999.99"
		nLin := nLin + 1
	EndDo
	DbSelectArea("TRB1")
	DbCloseArea("TRB1")
	nLin := nLin + 1
	
	DbSelectArea("TRB2")
	TRB2->(DbGoTop())
	cCodAux := ''
	While !TRB2->(Eof())
		_nTotProd 	:= 0
		_nTotMult	:= 0
		_cCod 		:= TRB2->B1_TIPOFIO
		While !TRB2->(Eof()) .and. TRB2->B1_TIPOFIO == _cCod
			If nLin > 56
				Cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
				nLin := 8
			Endif
			If Posicione("SB1",1,xFilial("SB1")+TRB2->D3_COD,"B1_UM") == "KG"
				_nTotProd := _nTotProd + TRB2->D3_QUANT
				_nTotMult := _nTotMult + (TRB2->D3_QUANT*(Posicione("SB1",1,xFilial("SB1")+TRB2->D3_COD,"B1_BITOLA")))
			Else
				_nTotProd := _nTotProd + TRB2->D3_QTSEGUM
				_nTotMult := _nTotMult + (TRB2->D3_QTSEGUM*(Posicione("SB1",1,xFilial("SB1")+TRB2->D3_COD,"B1_BITOLA")))
			Endif
			TRB2->(DbSkip())
		Enddo
		_nPadrao	:= _nTotMult / _nTotProd
		_cTIPOFIO := _cCod
		If _cTIPOFIO = "MONOF"
			_cDESCFIO := "MONOFILAMENTO"
		Elseif _cTIPOFIO = "MULTI"
			_cDESCFIO := "MULTIFILAMENTO"
		Elseif _cTIPOFIO = "POLIE"
			_cDESCFIO := "POLIETILENO"
		Else
			_cDESCFIO := "OUTROS"
		Endif
		If Empty(_cTIPOFIO)
			@ nLin,000 PSay "OUTRO"
		Else
			@ nLin,000 PSay _cTIPOFIO
		Endif
		@ nLin,006 PSay _cDESCFIO
		@ nLin,038 PSay _nTotProd picture "@E 99,999,999.99"
		@ nLin,056 PSay _nPadrao picture "@E 999,999.99"
		nLin := nLin + 1
	EndDo
	DbSelectArea("TRB2")
	DbCloseArea("TRB2")
	nLin := nLin + 1
	
	DbSelectArea("TRB4")
	TRB4->(DbGoTop())
	cCodAux := ''
	While !TRB4->(Eof())
		_nTotProd 	:= 0
		_nTotMult	:= 0
		_cCod 		:= TRB4->B1_MP
		While !TRB4->(Eof()) .and. TRB4->B1_MP == _cCod
			If nLin > 56
				Cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
				nLin := 8
			Endif
			If Posicione("SB1",1,xFilial("SB1")+TRB4->D3_COD,"B1_UM") == "KG"
				_nTotProd := _nTotProd + TRB4->D3_QUANT
				_nTotMult := _nTotMult + (TRB4->D3_QUANT*(Posicione("SB1",1,xFilial("SB1")+TRB4->D3_COD,"B1_BITOLA")))
			Else
				_nTotProd := _nTotProd + TRB4->D3_QTSEGUM
				_nTotMult := _nTotMult + (TRB4->D3_QTSEGUM*(Posicione("SB1",1,xFilial("SB1")+TRB4->D3_COD,"B1_BITOLA")))
			Endif
			TRB4->(DbSkip())
		Enddo
		_nPadrao	:= _nTotMult / _nTotProd
		_cMP := Alltrim(_cCod)
		If _cMP = "PET"
			_cDESCFIO := "POLIESTER"
		Elseif _cMP = "PP"
			_cDESCFIO := "POLIPROPILENO"
		Elseif _cMP = "PE"
			_cDESCFIO := "POLIETILENO"
		Else
			_cDESCFIO := "OUTROS"
		Endif
		If Empty(_cMP)
			@ nLin,000 PSay "OUTRO"
		Else
			@ nLin,000 PSay _cMP
		Endif
		@ nLin,006 PSay _cDESCFIO
		@ nLin,038 PSay _nTotProd picture "@E 99,999,999.99"
		@ nLin,056 PSay _nPadrao picture "@E 999,999.99"
		nLin := nLin + 1
	EndDo
	DbSelectArea("TRB4")
	DbCloseArea("TRB4")
	nLin := nLin + 1
	
	DbSelectArea("TRB5")
	TRB5->(DbGoTop())
	cCodAux := ''
	While !TRB5->(Eof())
		_nTotProd 	:= 0
		_nTotMult	:= 0
		_cCod 		:= Substr(TRB5->D3_GRUPO,1,1)
		While !TRB5->(Eof()) .and. Substr(TRB5->D3_GRUPO,1,1) == _cCod
			If nLin > 56
				Cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
				nLin := 8
			Endif
			_nTotProd := _nTotProd + TRB5->D3_QUANT
			TRB5->(DbSkip())
		Enddo
		_nPadrao := 0
		_cGRUPO := _cCod
		If _cGRUPO = "G"
			_cDESCFIO := "GRรOS"
		Elseif _cGRUPO = "H"
			_cDESCFIO := "FIBRAS"
		Elseif _cGRUPO = "PE"
			_cDESCFIO := "FIOS"
		Else
			_cDESCFIO := "OUTROS"
		Endif
		If Empty(_cGRUPO)
			@ nLin,000 PSay "OUTRO"
		Else
			@ nLin,000 PSay _cGRUPO
		Endif
		@ nLin,006 PSay _cDESCFIO
		@ nLin,038 PSay _nTotProd picture "@E 99,999,999.99"
		@ nLin,056 PSay _nPadrao picture "@E 999,999.99"
		nLin := nLin + 1
	EndDo
	DbSelectArea("TRB5")
	DbCloseArea("TRB5")
	nLin := nLin + 1
	
	DbSelectArea("TRB3")
	TRB3->(DbGoTop())
	If TRB3->(Bof()) .and. TRB3->(Eof()) // Query nao retornou nenhum registro
		_cVAR := " "
	Else
		@ nLin,000 PSay "FP"
		@ nLin,006 PSay "FORA DE PESO"
		@ nLin,038 PSay TRB3->D3_QUANT picture "@E 99,999,999.99"
		nLin := nLin + 1
	Endif
	DbSelectArea("TRB3")
	DbCloseArea("TRB3")
	
Endif

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