#INCLUDE "rwmake.ch"
#include "topconn.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �ART375    � Autor � CLOVIS EMMENDORFER � Data �  12/02/10   ���
�������������������������������������������������������������������������͹��
���Descricao � Faturamento com comiss�es a receber por representante      ���
�������������������������������������������������������������������������͹��
���Uso       � MP8 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function ART375

LOCAL cDesc1       := "Este programa tem como objetivo imprimir relatorio "
LOCAL cDesc2       := "de acordo com os parametros informados pelo usuario."
LOCAL cDesc3       := "Faturamento e Comissoes por Representante"
LOCAL cPict        := ""
LOCAL titulo       := "Faturamento e Comissoes por Representante"
LOCAL cString      := ""
LOCAL Cabec1       := ""
LOCAL Cabec2       := ""
LOCAL imprime      := .T.
LOCAL aOrd         := {}
LOCAL nLin         := 80
Private lEnd       := .F.
Private lAbortPrint:= .F.
Private CbTxt      := ""
Private limite     := 80
Private tamanho    := "G"
Private nomeprog   := "ART375" // Coloque aqui o nome do programa para impressao no cabecalho
Private nTipo      := 18
Private aReturn    := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey   := 0
Private cPerg      := "ART375"
Private cbtxt      := Space(10)
Private cbcont     := 00
Private CONTFL     := 01
Private m_pag      := 01
Private wnrel      := "ART375" // Coloque aqui o nome do arquivo usado para impressao em disco

cPerg := "ART375"
aRegistros := {}
AADD(aRegistros,{cPerg,"01","Representante de  ?","","","mv_ch1","C",06,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SA3","","","",""})
AADD(aRegistros,{cPerg,"02","Representante ate ?","","","mv_ch2","C",06,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SA3","","","",""})
AADD(aRegistros,{cPerg,"03","Data de           ?","","","mv_ch3","D",08,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"04","Data ate          ?","","","mv_ch4","D",08,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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

//���������������������������������������������������������������������Ŀ
//� Declaracao de Variaveis                                             �
//�����������������������������������������������������������������������

pergunte(cPerg,.F.)

//���������������������������������������������������������������������Ŀ
//� Monta a interface padrao com o usuario...                           �
//�����������������������������������������������������������������������

wnrel := SetPrint(cString,NomeProg,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)

If nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
	Return
Endif

nTipo := If(aReturn[4]==1,15,18)

//���������������������������������������������������������������������Ŀ
//� Processamento. RPTSTATUS monta janela com a regua de processamento. �
//�����������������������������������������������������������������������

RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)
Return

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Fun��o    �RUNREPORT � Autor � AP6 IDE            � Data �  29/11/06   ���
�������������������������������������������������������������������������͹��
���Descri��o � Funcao auxiliar chamada pela RPTSTATUS. A funcao RPTSTATUS ���
���          � monta a janela com a regua de processamento.               ���
�������������������������������������������������������������������������͹��
���Uso       � Programa principal                                         ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

dbCloseArea("TRA")

Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)

nTotFat := 0
nTotCom := 0
nVendas := 0
nTPC    := 0
nTPE    := 0
nTRF    := 0
nDevol  := 0
nComi   := 0
nQtde   := 0
nQtdeDev:= 0
nComDev := 0
cVend   := ""
cNome   := ""
nComAux := 0
nPesoAux:= 0

aStru:={}

Aadd(aStru,{ "REPRES   ", "C", 06 , 0 } )
Aadd(aStru,{ "NOME     ", "C", 40 , 0 } )
Aadd(aStru,{ "VENDAS   ", "N", 13 , 2 } )
Aadd(aStru,{ "TIPOC    ", "N", 10 , 2 } )
Aadd(aStru,{ "TIPOE    ", "N", 10 , 2 } )
Aadd(aStru,{ "TRF      ", "N", 10 , 2 } )
Aadd(aStru,{ "DEVOL    ", "N", 10 , 2 } )
Aadd(aStru,{ "COMDEB   ", "N", 10 , 2 } ) //COMISS�ES DEBITADAS POR FRETE, AMOSTRAS, ETC
Aadd(aStru,{ "COMISSAO ", "N", 10 , 2 } )
Aadd(aStru,{ "COMDEV   ", "N", 10 , 2 } )
Aadd(aStru,{ "QTDE     ", "N", 10 , 2 } )
Aadd(aStru,{ "QTDEDEV  ", "N", 10 , 2 } )
Aadd(aStru,{ "PRCMEDIO ", "N", 08 , 2 } )
Aadd(aStru,{ "COMCRED  ", "N", 10 , 2 } ) //COMISS�ES CREDITADAS

cTemp := CriaTrab(aStru,.t.)
Use &cTemp. Alias TRA New
Index on REPRES to &cTemp.

dbSelectArea("SA3")
dbSetOrder(1)
dbGoTop()

dbSeek(xFilial("SA3")+mv_par01,.t.)

While !EOF() .and. SA3->A3_COD <= mv_par02
	
	cQry := "SELECT D2_TOTAL,D2_QUANT,C5_TIPC,D2_QTSEGUM,D2_VALIPI, "
	cQry += "D2_IPI,B1_CONV,D2_DOC,D2_SERIE,D2_COD, "
	cQry += "D2_VEND1,A3_NOME,D2_SEGUM,D2_UM,D2_PESO,D2_COMIS1,D2_ICMSRET "
	cQry += "FROM " + RETSQLNAME("SB1") + " SB1, "
	cQry += " " + RETSQLNAME("SD2") + " SD2, "
	cQry += " " + RETSQLNAME("SF4") + " SF4, "
	cQry += " " + RETSQLNAME("SA3") + " SA3, "
	cQry += " " + RETSQLNAME("SC5") + " SC5 "
	cQry += "WHERE SB1.D_E_L_E_T_ <> '*' AND "
	cQry += "SD2.D_E_L_E_T_ <> '*' AND "
	cQry += "SF4.D_E_L_E_T_ <> '*' AND "
	cQry += "SA3.D_E_L_E_T_ <> '*' AND "
	cQry += "SC5.D_E_L_E_T_ <> '*' AND "
	cQry += "B1_FILIAL = '" + xFilial("SB1") + "' AND "
	cQry += "D2_FILIAL = '" + xFilial("SD2") + "' AND "
	cQry += "F4_FILIAL = '" + xFilial("SF4") + "' AND "
	cQry += "A3_FILIAL = '" + xFilial("SA3") + "' AND "
	cQry += "C5_FILIAL = '" + xFilial("SC5") + "' AND "
	cQry += "D2_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' AND "
	cQry += "D2_VEND1 = '" + SA3->A3_COD + "' AND "
	cQry += "B1_COD = D2_COD AND F4_CODIGO = D2_TES AND A3_COD = D2_VEND1 AND "
	cQry += "F4_DUPLIC = 'S' AND (D2_TIPO = 'N' OR D2_TIPO = 'C') AND C5_NUM = D2_PEDIDO "
	cQry += "ORDER BY D2_VEND1"
	
	If (Select("FAT") <> 0)
		dbSelectArea("FAT")
		dbCloseArea()
	Endif
	
	TCQUERY cQry NEW Alias "FAT"
	
	dbSelectArea("FAT")
	dbGoTop()
	
	cVend := FAT->D2_VEND1
	cNome := FAT->A3_NOME
	
	If !empty(FAT->D2_VEND1)
		
		While !EOF()
			
			If FAT->C5_TIPC == 'S'
				nTPC   += FAT->D2_TOTAL
			Else
				If FAT->C5_TIPC == 'E'
					nTPE   += FAT->D2_TOTAL * 80 / 20
				Endif
			Endif
			
			If FAT->D2_SERIE == 'TRF'
				nTRF   += FAT->D2_TOTAL
			Else
				nVendas += FAT->D2_TOTAL + FAT->D2_ICMSRET
			Endif
			
			nComi += (FAT->D2_TOTAL + FAT->D2_ICMSRET) * (FAT->D2_COMIS1 / 100)
			
			If FAT->D2_UM == 'KG'
				nQtde += FAT->D2_QUANT
			Else
				If FAT->D2_SEGUM == 'KG'
					nQtde += FAT->D2_QTSEGUM
				Else
					If FAT->D2_UM <> 'KG' .and. FAT->D2_SEGUM <> 'KG'
						nQtde += FAT->D2_QUANT * FAT->D2_PESO
					Endif
				Endif
			Endif
			
			dbSelectArea("FAT")
			dbSkip()
			
		Enddo
		
		//BUSCA AS DEVOLU�OES DO PER�ODO
		cQuery := "SELECT DISTINCT D1_DOC,D1_SERIE,D1_FORNECE,D1_LOJA,D1_COD,D1_ITEM,D1_NFORI,D1_TOTAL,"
		cQuery += "D1_QUANT,D1_QTSEGUM,D1_VALIPI,D1_UM,D1_SEGUM,D1_SERIORI,D2_PEDIDO "
		cQuery += "FROM " + RETSQLNAME("SD1") + " SD1, " + RETSQLNAME("SD2") + " SD2 "
		cQuery += "WHERE SD1.D_E_L_E_T_ <> '*' AND SD2.D_E_L_E_T_ <> '*' "
		cQuery += "AND D1_FILIAL = '" + xFilial("SD1") + "' "
		cQuery += "AND D2_FILIAL = '" + xFilial("SD2") + "' "
		cQuery += "AND D1_NFORI = D2_DOC AND D1_TIPO = 'D' "
		cQuery += "AND D1_SERIORI = D2_SERIE "
		cQuery += "AND D2_VEND1 = '" + SA3->A3_COD + "' "
		cQuery += "AND D1_DTDIGIT BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' AND SUBSTRING(D1_CF,2,1) <> '9' "
		
		If (Select("DEV") <> 0)
			dbSelectArea("DEV")
			dbCloseArea()
		Endif
		
		TCQUERY cQuery NEW Alias "DEV"
		
		dbSelectArea("DEV")
		dbGoTop()
		
		While !EOF()
			
			If Posicione("SC5",1,XFILIAL("SC5")+DEV->D2_PEDIDO,"C5_TIPC") == 'S'
				nDevol += DEV->D1_TOTAL
			Else
				If Posicione("SC5",1,XFILIAL("SC5")+DEV->D2_PEDIDO,"C5_TIPC") == 'E'
					nDevol += DEV->D1_TOTAL * 80 / 20
				Endif
			Endif
			
			If FAT->D2_SERIE == 'TRF'
				nDevol += DEV->D1_TOTAL
			Else
				nDevol += DEV->D1_TOTAL
			Endif
			
			nComAux  := Posicione("SD2",3,xFilial("SD2") + DEV->D1_NFORI + DEV->D1_SERIORI + DEV->D1_FORNECE + DEV->D1_LOJA + DEV->D1_COD,"D2_COMIS1")
			nComDev  += DEV->D1_TOTAL * (nComAux / 100)
			nPesoAux := Posicione("SB1",1,xFilial("SB1") + DEV->D1_COD,"B1_PESO")
			
			If DEV->D1_UM == 'KG'
				nQtdeDev += DEV->D1_QUANT
			Else
				If DEV->D1_SEGUM == 'KG'
					nQtdeDev += DEV->D1_QTSEGUM
				Else
					If DEV->D1_UM <> 'KG' .and. DEV->D1_SEGUM <> 'KG'
						nQtdeDev += DEV->D1_QUANT * nPesoAux
					Endif
				Endif
			Endif
			
			dbSelectArea("DEV")
			dbSkip()
			
		Enddo
		
		//BUSCA OS ABATIMENTOS DE COMISS�O
		cQuery := "SELECT SUM(E3_COMIS) AS DEBITOS "
		cQuery += "FROM " + RETSQLNAME("SE3") + " SE3 "
		cQuery += "WHERE SE3.D_E_L_E_T_ <> '*' "
		cQuery += "AND E3_FILIAL = '" + xFilial("SE3") + "' "
		cQuery += "AND E3_VEND = '" + SA3->A3_COD + "' AND E3_SERIE = 'DEB' "
		cQuery += "AND E3_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
		
		If (Select("DEB") <> 0)
			dbSelectArea("DEB")
			dbCloseArea()
		Endif
		
		TCQUERY cQuery NEW Alias "DEB"
		
		dbSelectArea("DEB")
		dbGoTop()
		
		//BUSCA OS B�NUS DE COMISS�O
		cQuery := "SELECT SUM(E3_COMIS) AS CREDITOS "
		cQuery += "FROM " + RETSQLNAME("SE3") + " SE3 "
		cQuery += "WHERE SE3.D_E_L_E_T_ <> '*' "
		cQuery += "AND E3_FILIAL = '" + xFilial("SE3") + "' "
		cQuery += "AND E3_VEND = '" + SA3->A3_COD + "' AND E3_SERIE = 'CRE' "
		cQuery += "AND E3_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "' "
		
		If (Select("CRE") <> 0)
			dbSelectArea("CRE")
			dbCloseArea()
		Endif
		
		TCQUERY cQuery NEW Alias "CRE"
		
		dbSelectArea("CRE")
		dbGoTop()
		
		dbSelectArea("TRA")
		RecLock("TRA",.T.)
		TRA->REPRES   := cVend
		TRA->NOME     := cNome
		TRA->VENDAS   := nVendas
		TRA->TIPOC    := nTPC
		TRA->TIPOE    := nTPE
		TRA->TRF      := nTRF
		TRA->DEVOL    := nDevol
		TRA->COMDEB   := DEB->DEBITOS * -1
		TRA->COMCRED  := CRE->CREDITOS
		TRA->COMISSAO := nComi
		TRA->COMDEV   := nComDev
		TRA->QTDE     := nQtde
		TRA->QTDEDEV  := nQtdeDev
		TRA->PRCMEDIO := nVendas / nQtde
		msUnLock("TRA")
		
		nVendas := 0
		nTPC    := 0
		nTPE    := 0
		nTRF    := 0
		nDevol  := 0
		nComi   := 0
		nComDev := 0
		nQtde   := 0
		nQtdeDev:= 0
		
	Endif
	
	dbSelectArea("SA3")
	dbSkip()
	
Enddo

//Impress�o
dbSelectArea("TRA")
dbGotop()

SetRegua(RecCount("TRA"))

cVend := ""

While !EOF()
	
	IncRegua()
	
	If lAbortPrint
		@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
		Exit
	Endif
	
	If nLin > 55
		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
		nLin := 6
		//12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
		//         1         2         3         4         5         6         7         8         9         10        11        12        13        14
		//FATURAMENTO COM COMISS�O - Per�odo: 99/99/9999 a 99/99/9999
		//                                    (MV_PAR03)   (MV_PAR04)
		//999999 - xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		//(D2_VEND1) - (A3_NOME)
		//VENDAS          TP.C         TP.E         TRF          DEVOLU��ES   COM.DEBITADAS   COM.CREDITADAS  COMISS�ES    KG           QTDE DEVOLV.   PR� M�DIO
		//99,999,999.99   999,999.99   999,999.99   999,999.99   999,999.99   999,999.99      999,999.99      999,999.99   999,999.99   999,999.99     9,999.99
		//
		//TOTAL FATURAMENTO: 999,999,999.99    TOTAL COMISS�ES: 9,999,999.99    TOTAL KG: 9,999,999.99   PRE�O M�DIO: 9,999.99
		@nLin,001 pSay "FATURAMENTO COM COMISS�O - Per�odo: " + dtoc(mv_par03) + " a " + dtoc(mv_par04)
		nLin ++
	Endif
	
	If cVend <> TRA->REPRES
		
		nLin ++
		@nLin,001 pSay TRA->REPRES + " - " + TRA->NOME
		nLin ++
		nLin ++
		@nLin,001 pSay "VENDAS          TP.C         TP.E         TRF          DEVOLU��ES   COM.DEBITADAS   COM.CREDITADAS  COMISS�ES    KG           QTDE DEVOLV.   PR� M�DIO"
		nLin ++
		nLin ++
		
		cVend := TRA->REPRES
		
	Endif
	
	@nLin,001 pSay TRA->VENDAS   PICTURE "@E 99,999,999.99"
	@nLin,017 pSay TRA->TIPOC    PICTURE "@E 999,999.99"
	@nLin,030 pSay TRA->TIPOE    PICTURE "@E 999,999.99"
	@nLin,043 pSay TRA->TRF      PICTURE "@E 999,999.99"
	@nLin,056 pSay TRA->DEVOL    PICTURE "@E 999,999.99"
	@nLin,069 pSay TRA->COMDEB   PICTURE "@E 999,999.99"
	@nLin,085 pSay TRA->COMCRED  PICTURE "@E 999,999.99"
	@nLin,101 pSay TRA->COMISSAO PICTURE "@E 999,999.99"
	@nLin,114 pSay TRA->QTDE     PICTURE "@E 999,999.99"
	@nLin,127 pSay TRA->QTDEDEV  PICTURE "@E 999,999.99"
	@nLin,142 pSay TRA->PRCMEDIO PICTURE "@E 9,999.99"
	
	nLin ++
	nLin ++
	
	nTotFat := TRA->VENDAS + TRA->TIPOC + TRA->TIPOE - TRA->DEVOL
	nTotCom := TRA->COMISSAO - TRA->COMDEV  - TRA->COMDEB + TRA->COMCRED
	
	@nLin,001 pSay "TOTAL FATURAMENTO:"
	@nLin,020 pSay nTotFat                                PICTURE "@E 999,999,999.99"
	@nLin,038 pSay "TOTAL COMISS�ES:"
	@nLin,055 pSay nTotCom                                PICTURE "@E 999,999,999.99"
	@nLin,071 pSay "TOTAL KG:"
	@nLin,081 pSay TRA->QTDE - TRA->QTDEDEV               PICTURE "@E 9,999,999.99"
	@nLin,096 pSay "PRE�O M�DIO:"
	@nLin,109 pSay nTotFat / (TRA->QTDE - TRA->QTDEDEV)   PICTURE "@E 9,999.99"
	
	nLin++
	
	@nLin,001 pSay Replicate("-",130)
	
	nLin++
	
	dbSelectArea("TRA")
	dbSkip()
	
	nTotFat := 0
	nTotCom := 0
	
EndDo

dbCloseArea("ART")
If (Select("TRA") <> 0)
	dbSelectArea("TRA")
	dbCloseArea()
Endif

//���������������������������������������������������������������������Ŀ
//� Finaliza a execucao do relatorio...                                 �
//�����������������������������������������������������������������������

SET DEVICE TO SCREEN

//���������������������������������������������������������������������Ŀ
//� Se impressao em disco, chama o gerenciador de impressao...          �
//�����������������������������������������������������������������������

If aReturn[5]==1
	dbCommitAll()
	SET PRINTER TO
	OurSpool(wnrel)
Endif

MS_FLUSH()

Return
