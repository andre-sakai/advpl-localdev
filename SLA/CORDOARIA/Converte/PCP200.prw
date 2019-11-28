#INCLUDE "rwmake.ch"
#include "topconn.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³PCP200    º Autor ³ Luciano Henrique   º Data ³  02/05/05   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Planejamento de Vendas - MRP                               º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Especifico para Arteplas                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±ºAlteracoes³ Alterado em 30/01/06 por Marcelo J. Santos (Reconstruida a º±±
±±º          ³ Query para Melhora de Performance)                         º±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function PCP200


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Local cDesc1		:= "Este programa tem como objetivo imprimir relatorio "
Local cDesc2		:= "de acordo com os parametros informados pelo usuario."
Local cDesc3        := "Relatorio por Vendas e Carteira de Pedidos"
Local cPict         := ""
Local titulo        := "Planejamento de Producao"
Local nLin         	:= 80
Local Cabec1      	:= ""
Local Cabec2       	:= ""
Local imprime      	:= .T.
Local aOrd 			:= {}
Private lEnd        := .F.
Private lAbortPrint	:= .F.
Private CbTxt       := ""
Private limite      := 132
Private tamanho     := "G"
Private nomeprog    := "PCP200" // Nome do programa para impressao no cabecalho
Private nTipo       := 15
Private aReturn     := { "Zebrado", 1, "Administracao", 1, 2, 1, "", 1}
Private nLastKey    := 0
Private cbtxt      	:= Space(10)
Private cbcont     	:= 00
Private CONTFL     	:= 01
Private m_pag      	:= 01
Private wnrel      	:= "PCP200" // Nome do arquivo usado para impressao em disco
Private cString 	:= "SB1"
Private cPerg       := "PCP200"

cPerg := "PCP200"
aRegistros := {}
AADD(aRegistros,{cPerg,"01","Produto de      ?","","","mv_ch1","C",15,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SB1","","","","",""})
AADD(aRegistros,{cPerg,"02","Produto ate     ?","","","mv_ch2","C",15,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SB1","","","","",""})
AADD(aRegistros,{cPerg,"03","Local de        ?","","","mv_ch3","C",02,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"04","Local ate       ?","","","mv_ch4","C",02,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"05","Grupo de        ?","","","mv_ch5","C",04,0,0,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","SBM","","","","",""})
AADD(aRegistros,{cPerg,"06","Grupo ate       ?","","","mv_ch6","C",04,0,0,"G","","mv_par06","","","","","","","","","","","","","","","","","","","","","","","","","SBM","","","","",""})
AADD(aRegistros,{cPerg,"07","Data Entrega de ?","","","mv_ch7","D",08,0,0,"G","","mv_par07","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"08","Data Entrega ate?","","","mv_ch8","D",08,0,0,"G","","mv_par08","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"09","Ordenação       ?","","","mv_ch9","N",01,0,0,"C","","mv_par09","Codigo","","","","","Descrição","","","","","Grupo","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"10","Unid. Medida de ?","","","mv_cha","C",02,0,0,"G","","mv_par10","","","","","","","","","","","","","","","","","","","","","","","","","SAH","","","","",""})
AADD(aRegistros,{cPerg,"11","Unid. Medida ate?","","","mv_chb","C",02,0,0,"G","","mv_par11","","","","","","","","","","","","","","","","","","","","","","","","","SAH","","","","",""})

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

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

pergunte(cPerg,.F.)

dbSelectArea("SB1")

SB1->(DbSetOrder(1))                                   
                                                      
nLastKey := 0

If !Pergunte(cPerg,.T.) .or. (nLastKey == 27 .Or. LastKey() == 27)
	Return(.F.)
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta a interface padrao com o usuario...                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

wnrel := SetPrint(cString,NomeProg,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)

If nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
   Return
Endif

nTipo := If(aReturn[4]==1,15,18)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Processamento. RPTSTATUS monta janela com a regua de processamento. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFun‡„o    ³RUNREPORT º Autor ³ AP6 IDE            º Data ³  22/01/04   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescri‡„o ³ Funcao auxiliar chamada pela RPTSTATUS. A funcao RPTSTATUS º±±
±±º          ³ monta a janela com a regua de processamento.               º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Programa principal                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)

Local nOrdem

dbSelectArea("SB1")
SB1->(DbSetOrder(1))

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ SETREGUA -> Indica quantos registros serao processados para a regua ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

cQuerA := "SELECT COUNT(*) AS REGISTROS "
cQuerA += "FROM   " + RetSQLName("SB1") + " SB1 "
cQuerA += "WHERE  SB1.B1_ATIVOAT = 'S' AND SB1.B1_COD BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'  "
cQuerA += "AND    SB1.B1_GRUPO BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR06 + "'  "
cQuerA += "AND    SB1.B1_UM BETWEEN '" + MV_PAR10 + "' AND '" + MV_PAR11 + "'  "
cQuerA += "AND    SB1.D_E_L_E_T_ <> '*' "
cQuerA += "AND    SB1.B1_FILIAL = '"+xFilial("SB1")+"' "
TcQuery cQuerA New Alias "TRA"
DbSelectArea("TRA")
TRA->(dbGoTop())

SetRegua(TRA->REGISTROS)
DbSelectArea("TRA")
DbCloseArea("TRA")
         
cQuerA := "SELECT B1_COD, B1_DESC, B1_TIPO, B1_GRUPO, B1_UM, B1_LOCPAD "
cQuerA += "FROM   " + RetSQLName("SB1") + " SB1 "
cQuerA += "WHERE  SB1.B1_ATIVOAT = 'S' AND SB1.B1_COD BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'  "
cQuerA += "AND    SB1.B1_GRUPO BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR06 + "'  "
cQuerA += "AND    SB1.B1_UM BETWEEN '" + MV_PAR10 + "' AND '" + MV_PAR11 + "'  "
cQuerA += "AND    SB1.D_E_L_E_T_ <> '*' "
cQuerA += "AND    SB1.B1_FILIAL = '"+xFilial("SB1")+"' "
If MV_PAR09 = 1 // Em Ordem de Codigo
	cQuerA += "ORDER BY B1_COD  "
Else
	If MV_PAR09 = 2  // Em Ordem de Descricao do Produto
		cQuerA += "ORDER BY B1_DESC "
	Else
		If MV_PAR09 = 3 //Ordem de grupo
			cQuerA += "ORDER BY B1_GRUPO,B1_DESC "
		Endif
	Endif
Endif
TcQuery cQuerA New Alias "TRA"

DbSelectArea("TRA")
TRA->(dbGoTop())
        

Cabec1  := "CODIGO            DESCRICAO                            TP  GRUPO  UM          ESTOQUE   SLD.PED.VENDAS         POS ATUAL       SLD.PED.MES + 1     SLD.PED.MES + 2       POS. FINAL          FAT.MES      PED.TRIM. ANT."
		  //                                                                       999,999.999    999,999.999     999,999.999         999,999.999        999,999.999    999,999.999    999,999.999       999,999.999
          //12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
          //         10        20        30        40        50        60        70        80        90       100       110       120       130       140       150       160       170       180       190        200
cDiaIni		:= ''
cMesIni		:= ''
cMesAux		:= ''
cAnoIni		:= ''
cDiaFin		:= ''
cMesFin		:= ''
cAnoFin		:= ''
cDtSegIni 	:= ''
cDtSegIni1	:= ''
cDtSegFin 	:= ''
cDtSegFin1	:= ''                    
nAnoIni		:= 0
nAnoFin		:= 0
nTEstoque   := 0
nTPedidos   := 0
nTPed1      := 0
nTPed2      := 0
nTPedMes    := 0
nTPedTri    := 0

TRA->(DbGoTop())
While !TRA->(Eof())                  
  
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica o cancelamento pelo usuario...                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lAbortPrint
	  @ nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
	  Exit
	Endif

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Impressao do cabecalho do relatorio. . .                            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If nLin > 59 // Salto de Página. Neste caso o formulario tem 55 linhas...
	  Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
	  nLin := 8
	Endif   
	nPosAtu:= 0

	//Cabec1  := "CODIGO            DESCRICAO                                   TP  GRUPO  UM  SLD EM EST  PED.VENDAS      POS ATUAL   PEDIDOS MES SEGUINTE   PEDIDOS MES + 1   POSIÇÃO FINAL"
	            //0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
	            //         1         2         3         4         5         6         7         8         9         0         1         2         3         4         5         6
	@ nLin,000 pSay TRA->B1_COD
	@ nLin,018 pSay SubStr(TRA->B1_DESC,1,35)
	@ nLin,055 pSay TRA->B1_TIPO
	@ nLin,059 pSay TRA->B1_GRUPO
	@ nLin,066 pSay TRA->B1_UM
	@ nLin,072 pSay Posicione("SB2",1,xFilial("SB2")+TRA->B1_COD+TRA->B1_LOCPAD,"B2_QATU")  picture "@E 9,999,999.999"

	nTEstoque := nTEstoque + Posicione("SB2",1,xFilial("SB2")+TRA->B1_COD+TRA->B1_LOCPAD,"B2_QATU")

	cQuerB := "SELECT SUM(C6_QTDVEN - C6_QTDENT) AS PED_VENDA "
	cQuerB += "FROM   " + RetSQLName("SC6") + " SC6, "
	cQuerB += RetSQLName("SF4") + " SF4  "
	cQuerB += "WHERE  SC6.C6_PRODUTO = '" + TRA->B1_COD + "'  "
	cQuerB += "AND    SC6.C6_ENTREG BETWEEN '" + DtoS(MV_PAR07) + "' AND '" + DtoS(MV_PAR08) + "'  "
	cQuerB += "AND    C6_BLQ = ' ' "
	cQuerB += "AND    SC6.D_E_L_E_T_ <> '*' "
	cQuerB += "AND    SC6.C6_FILIAL = '"+xFilial("SC6")+"' "
	cQuerB += "AND    SF4.D_E_L_E_T_ <> '*' "	
	cQuerB += "AND    SF4.F4_FILIAL = '"+xFilial("SF4")+"' "
	cQuerB += "AND    SF4.F4_CODIGO = SC6.C6_TES "		
	cQuerB += "AND    SF4.F4_ESTOQUE= 'S' "			
	
	TcQuery cQuerB New Alias "TRB"
	
	DbSelectArea("TRB")
	TRB->(DbGoTop())
	
	@ nLin,089 pSay TRB->PED_VENDA picture "@E 9,999,999.999"
	
	nTPedidos := nTPedidos + TRB->PED_VENDA

	nPosAtu:= Posicione("SB2",1,xFilial("SB2")+TRA->B1_COD+TRA->B1_LOCPAD,"B2_QATU") - TRB->PED_VENDA
	
	DbSelectArea("TRB")
	DbCloseArea("TRB")		
	
	@ nLin,107 pSay nPosAtu         picture "@E 9,999,999.999"
	
	_MesAtu   := Month(dDataBase) 
	_MesSeg   := Month(dDataBase) + 1
	_AnoSeg   := Year(dDataBase)
	_AnoSeg1  := Year(dDataBase)	
	
	If _MesSeg > 12
		_MesSeg := _MesSeg - 12
		_AnoSeg := 	Year(dDataBase) + 1
	Endif
	_dMesAtu  := StrZero(Year(dDataBase),4) + StrZero(_MesAtu,2)	
	_dMesSeg  := StrZero(_AnoSeg,4) + StrZero(_MesSeg,2)
	_MesSeg1  := Month(dDataBase) + 2
	If _MesSeg1 > 12
		_MesSeg1 := _MesSeg1 - 12
		_AnoSeg1 :=	Year(dDataBase) + 1
	Endif	
	_dMesSeg1 := StrZero(_AnoSeg1,4) + StrZero(_MesSeg1,2)	
	
	cQuerB := "SELECT SUM(C6_QTDVEN - C6_QTDENT) AS MES_SEG "
	cQuerB += "FROM   " + RetSQLName("SC6") + " SC6, "
	cQuerB += RetSQLName("SF4") + " SF4  "
	cQuerB += "WHERE  SC6.C6_PRODUTO = '" + TRA->B1_COD + "'  "
	cQuerB += "AND    Substring(SC6.C6_ENTREG,1,6) = '" + _dMesSeg + "'  "
	cQuerB += "AND    C6_BLQ = ' ' "
	cQuerB += "AND    SC6.D_E_L_E_T_ <> '*' "
	cQuerB += "AND    SC6.C6_FILIAL = '"+xFilial("SC6")+"' "
	cQuerB += "AND    SF4.D_E_L_E_T_ <> '*' "	
	cQuerB += "AND    SF4.F4_FILIAL = '"+xFilial("SF4")+"' "
	cQuerB += "AND    SF4.F4_CODIGO = SC6.C6_TES "		
	cQuerB += "AND    SF4.F4_ESTOQUE= 'S' "			
	
	TcQuery cQuerB New Alias "TRB"
	
	DbSelectArea("TRB")
	TRB->(DbGoTop())
	
	@ nLin,129 pSay TRB->MES_SEG   picture "@E 9,999,999.999"
	
	nTPed1 := nTPed1 + TRB->MES_SEG

	cQuerC := "SELECT SUM(C6_QTDVEN - C6_QTDENT) AS MES_SEG1 "
	cQuerC += "FROM   " + RetSQLName("SC6") + " SC6, "
	cQuerC += RetSQLName("SF4") + " SF4  "
	cQuerC += "WHERE  SC6.C6_PRODUTO = '" + TRA->B1_COD + "'  "
	cQuerC += "AND    Substring(SC6.C6_ENTREG,1,6) = '" + _dMesSeg1 + "'  "
	cQuerC += "AND    C6_BLQ = ' ' "
	cQuerC += "AND    SC6.D_E_L_E_T_ <> '*' "
	cQuerC += "AND    SC6.C6_FILIAL = '"+xFilial("SC6")+"' "
	cQuerC += "AND    SF4.D_E_L_E_T_ <> '*' "	
	cQuerC += "AND    SF4.F4_FILIAL = '"+xFilial("SF4")+"' "
	cQuerC += "AND    SF4.F4_CODIGO = SC6.C6_TES "		
	cQuerC += "AND    SF4.F4_ESTOQUE= 'S' "			
	
	TcQuery cQuerC New Alias "TRC"
	
	DbSelectArea("TRB")
	TRB->(DbGoTop())
	
	@ nLin,150 pSay TRC->MES_SEG1  picture "@E 9,999,999.999"    
	
	nTPed2 := nTPed2 + TRC->MES_SEG1
	nPosFin:= (nPosAtu - TRB->MES_SEG - TRC->MES_SEG1)
	
	@ nLin,167 pSay nPosFin picture "@E 9,999,999.999"       
	
	DbSelectArea("TRB")
	DbCloseArea("TRB")		
	DbSelectArea("TRC")
	DbCloseArea("TRC")				
		
	cQuerB := "SELECT DISTINCT SUM(C6_QTDVEN - C6_QTDENT) AS QTDE_MES "
	cQuerB += "FROM   " + RetSQLName("SC6") + " SC6, "
	cQuerB += RetSQLName("SF4") + " SF4  "
	cQuerB += "WHERE  SC6.C6_PRODUTO = '" + TRA->B1_COD + "'  "
	cQuerB += "AND    Substring(SC6.C6_ENTREG,1,6) = '" + _dMesAtu + "'  "
	cQuerB += "AND    SC6.D_E_L_E_T_ <> '*' "
	cQuerB += "AND    C6_BLQ = ' ' "
	cQuerB += "AND    SC6.C6_FILIAL = '"+xFilial("SC6")+"' "
	cQuerB += "AND    SF4.D_E_L_E_T_ <> '*' "	
	cQuerB += "AND    SF4.F4_FILIAL = '"+xFilial("SF4")+"' "
	cQuerB += "AND    SF4.F4_CODIGO = SC6.C6_TES "		
	cQuerB += "AND    SF4.F4_ESTOQUE= 'S' "			
	
	TcQuery cQuerB New Alias "TRB"
	
	DbSelectArea("TRB")
	TRB->(DbGoTop())

	// Faturado no Mês	
	cQuerC := "SELECT DISTINCT SUM(D2_QUANT) AS QTDE_MES "
	cQuerC += "FROM   " + RetSQLName("SD2") + " SD2, "
	cQuerC += RetSQLName("SF4") + " SF4  "
	cQuerC += "WHERE  SD2.D2_COD = '" + TRA->B1_COD + "'  "
	cQuerC += "AND    Substring(SD2.D2_EMISSAO,1,6) = '" + _dMesAtu + "'  "
	cQuerC += "AND    SD2.D_E_L_E_T_ <> '*' "
	cQuerC += "AND    SD2.D2_FILIAL = '"+xFilial("SD2")+"' "
	cQuerC += "AND    SF4.D_E_L_E_T_ <> '*' "	
	cQuerC += "AND    SF4.F4_FILIAL = '"+xFilial("SF4")+"' "
	cQuerC += "AND    SF4.F4_CODIGO = SD2.D2_TES "		
	cQuerC += "AND    SF4.F4_ESTOQUE= 'S' "			
	
	TcQuery cQuerC New Alias "TRC"
	
	DbSelectArea("TRC")
	TRC->(DbGoTop())	
	
// 	@ nLin,184 pSay (TRB->QTDE_MES+TRC->QTDE_MES) picture "@E 9,999,999.999"
	@ nLin,184 pSay (TRC->QTDE_MES) picture "@E 9,999,999.999"
	
	nTPedMes := nTPedMes + TRB->QTDE_MES + TRC->QTDE_MES
	
	DbSelectArea("TRB")
	DbCloseArea("TRB")	
	DbSelectArea("TRC")
	DbCloseArea("TRC")		
                                                                                
	_dMesTrimIni := Month(dDataBase) - 3                                        
	_dAnoTrimIni := Year(dDataBase)
	If _dMesTrimIni < 1
		_dMesTrimIni := _dMesTrimIni + 12
		_dAnoTrimIni := Year(dDataBase)	- 1
	Endif
	_dTrimIni := StrZero(_dAnoTrimIni,4)+StrZero(_dMesTrimIni,2)                   
	_dMesTrimFim := Month(dDataBase) - 1                                           
	_dAnoTrimFim := Year(dDataBase)                                                
	If _dMesTrimFim < 1                                    
		_dMesTrimFim := _dMesTrimFim + 12                                          
		_dAnoTrimFim := Year(dDataBase)	- 1                                        
	Endif
	_dTrimFim := StrZero(_dAnoTrimFim,4)+StrZero(_dMesTrimFim,2)

	cQuerB := "SELECT SUM(D2_QUANT) AS QTDE_TRIMANT "
	cQuerB += "FROM   " + RetSQLName("SD2") + " SD2, "
	cQuerB += RetSQLName("SF4") + " SF4  "
	cQuerB += "WHERE  SD2.D2_COD = '" + TRA->B1_COD + "'  "
	cQuerB += "AND    Substring(SD2.D2_EMISSAO,1,6) BETWEEN '" + _dTrimIni + "' AND '" + _dTrimFim + "'  "
	cQuerB += "AND    SD2.D_E_L_E_T_ <> '*' "
	cQuerB += "AND    SD2.D2_FILIAL = '"+xFilial("SD2")+"' "
	cQuerB += "AND    SF4.D_E_L_E_T_ <> '*' "	
	cQuerB += "AND    SF4.F4_FILIAL = '"+xFilial("SF4")+"' "
	cQuerB += "AND    SF4.F4_CODIGO = SD2.D2_TES "		
	cQuerB += "AND    SF4.F4_ESTOQUE= 'S' "			                                                         
	
	TcQuery cQuerB New Alias "TRB"
	
	DbSelectArea("TRB")
	TRB->(DbGoTop())
	
	@ nLin,204 pSay Round((TRB->QTDE_TRIMANT/3),0) picture "@E 9,999,999.999"
	
	nTPedTri := nTPedTri + Round((TRB->QTDE_TRIMANT/3),0)
	
	DbSelectArea("TRB")
	DbCloseArea("TRB")		
	nLin = nLin + 1
	TRA->(DbSkip())      
    IncRegua()
    
EndDo

@ nLin,072 pSay Replicate("-",130)
nLin++
@ nLin,060 pSay "TOTAL ->"
@ nLin,072 pSay nTEstoque 								  picture "@E 9,999,999.999"
@ nLin,089 pSay nTPedidos 								  picture "@E 9,999,999.999"
@ nLin,107 pSay nTEstoque - nTPedidos					  picture "@E 9,999,999.999"
@ nLin,129 pSay nTPed1 									  picture "@E 9,999,999.999"
@ nLin,150 pSay nTPed2								      picture "@E 9,999,999.999"    
@ nLin,167 pSay (nTEstoque - nTPedidos) - nTPed1 - nTPed2 picture "@E 9,999,999.999"    
@ nLin,184 pSay nTPedMes  								  picture "@E 9,999,999.999"
@ nLin,204 pSay nTPedTri								  picture "@E 9,999,999.999"

DbSelectArea("TRA")
DbCloseArea("TRA")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Finaliza a execucao do relatorio...                                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

SET DEVICE TO SCREEN

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Se impressao em disco, chama o gerenciador de impressao...          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If aReturn[5]==1
   dbCommitAll()
   SET PRINTER TO
   OurSpool(wnrel)
Endif
MS_FLUSH()

Return