#INCLUDE "rwmake.ch"
#include "topconn.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �ART359    � Autor � CLOVIS EMMENDORFER � Data �  25/03/09   ���
�������������������������������������������������������������������������͹��
���Descricao � Codigo gerado pelo AP6 IDE.                                ���
���          � Relat�rio de comiss�es a receber                            ��
�������������������������������������������������������������������������͹��
���Uso       � MP8 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function ART359

LOCAL cDesc1       := "Este programa tem como objetivo imprimir relatorio "
LOCAL cDesc2       := "de acordo com os parametros informados pelo usuario."
LOCAL cDesc3       := "Relatorio de Comissoes"
LOCAL cPict        := ""
LOCAL titulo       := "Relatorio de Comissoes"
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
Private nomeprog   := "ART359" // Coloque aqui o nome do programa para impressao no cabecalho
Private nTipo      := 18
Private aReturn    := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey   := 0
Private cPerg      := "ART359"
Private cbtxt      := Space(10)
Private cbcont     := 00
Private CONTFL     := 01
Private m_pag      := 01
Private wnrel      := "ART359" // Coloque aqui o nome do arquivo usado para impressao em disco

cPerg := "ART359"
aRegistros := {}
AADD(aRegistros,{cPerg,"01","Representante de  ?","","","mv_ch1","C",06,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SA3","","","",""})
AADD(aRegistros,{cPerg,"02","Representante ate ?","","","mv_ch2","C",06,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SA3","","","",""})
//AADD(aRegistros,{cPerg,"03","Data de           ?","","","mv_ch3","D",08,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
//AADD(aRegistros,{cPerg,"04","Data ate          ?","","","mv_ch4","D",08,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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

nComRep    := 0 //Total de comiss�es a receber por representante
nComTot    := 0 //Total de comiss�es a receber
nComPagRep := 0 //Total de comiss�es pagas nos �ltimos 60 dias por representante
nComDevRep := 0 //Total de comiss�es devolvidas por representante
nComPagTot := 0 //Total de comiss�es pagas nos �ltimos 60 dias
nComAbeRep := 0 //Total de Comiss�es em Aberto a Receber por Representante
nComAbeTot := 0 //Total de Comiss�es em Aberto a Receber
nComDevTot := 0 //Total de Comiss�es devolvidas

aStru:={}

Aadd(aStru,{ "STATUS  ", "C", 1 , 0 } ) //A=Titulos em Aberto / B=Titulos Baixados
Aadd(aStru,{ "NUM     ", "C", 6 , 0 } )
Aadd(aStru,{ "PARCELA ", "C", 1 , 0 } )
Aadd(aStru,{ "CLIENTE ", "C", 6 , 0 } )
Aadd(aStru,{ "LOJA    ", "C", 2 , 0 } )
Aadd(aStru,{ "NOMCLI  ", "C", 20, 0 } )
Aadd(aStru,{ "EMISSAO ", "D", 8 , 0 } )
Aadd(aStru,{ "VENCREA ", "D", 8 , 0 } )
Aadd(aStru,{ "PAGTO   ", "D", 8 , 0 } )
Aadd(aStru,{ "VEND1   ", "C", 6 , 0 } )
Aadd(aStru,{ "BAIXA   ", "D", 8 , 0 } )
Aadd(aStru,{ "PEDIDO  ", "C", 6 , 0 } )
Aadd(aStru,{ "SALDO   ", "N", 17, 2 } )
Aadd(aStru,{ "COMIS1  ", "N", 8 , 4 } )
Aadd(aStru,{ "VLRCOM  ", "N", 16, 2 } )
Aadd(aStru,{ "VALOR   ", "N", 17, 2 } )
Aadd(aStru,{ "COMDEV  ", "N", 16, 2 } )//Valor da comiss�o referente devolu��es
Aadd(aStru,{ "NOME    ", "C", 40, 0 } )

cTemp := CriaTrab(aStru,.t.)
Use &cTemp. Alias TRA New
Index on VEND1 to &cTemp.

dbSelectArea("SA3")
dbSetOrder(1)
dbGoTop()

dbSeek(xFilial("SA3")+mv_par01,.t.)

While !EOF() .and. SA3->A3_COD <= mv_par02
	
	dMes := Substr(dtos(ddatabase),5,2)
	dAno := Substr(dtos(ddatabase),1,4)
	
	If StrZero(SA3->A3_DIA,2) <= Substr(dtos(ddatabase),7,2)
		
		If dMes == "12"
			dMes := "01"
			dAno := Str(Val(dAno) + 1)
		Else
			dMes := StrZero((Val(dMes) + 1),2)
		Endif
		
	Endif
	
	dDtPagto := dAno + dMes + StrZero(SA3->A3_DIA,2)
	
	Previsao()
	Comissoes()
	Devolucoes()
	
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
		//REPRESENTANTE
		//TITULO  PARCELA  CLIENTE                          EMISS�O   DT VENCTO DT BAIXA  DT PAGTO  PEDIDO  VLR TITULO  VLR BASE    %       VALOR       DEVOLU��O
		//999999  X        999999 99  XXXXXXXXXXXXXXXXXXXX  99/99/99  99/99/99  99/99/99  99/99/99  999999  999.999,99  999.999,99  999,99  999.999,99  999.999,99
		//1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234
		//         1         2         3         4         5         6         7         8         9         10        11        12        13        14        15
		@nLin,001 pSay "REPRESENTANTE"
		nLin ++
		@nLin,001 pSay "TITULO  PARCELA  CLIENTE                          EMISS�O   DT VENCTO DT BAIXA  DT PAGTO  PEDIDO  VLR TITULO  VLR BASE    %       VALOR       DEVOLU��O"
		nLin ++
		nLin ++
	Endif
	
	If cVend <> TRA->VEND1
		
		nLin ++
		@nLin,001 pSay TRA->VEND1 + " - " + TRA->NOME
		nLin ++
		nLin ++
		
		cVend := TRA->VEND1
		
	Endif
	
	@nLin,001 pSay TRA->NUM
	@nLin,009 pSay TRA->PARCELA
	@nLin,018 pSay TRA->CLIENTE
	@nLin,025 pSay TRA->LOJA
	@nLin,029 pSay TRA->NOMCLI
	@nLin,051 pSay TRA->EMISSAO
	@nLin,061 pSay TRA->VENCREA
	@nLin,071 pSay TRA->BAIXA
	@nLin,081 pSay TRA->PAGTO
	@nLin,091 pSay TRA->PEDIDO
	@nLin,099 pSay TRA->VALOR   PICTURE "@E 999,999.99"
	@nLin,111 pSay TRA->SALDO   PICTURE "@E 999,999.99"
	@nLin,123 pSay TRA->COMIS1  PICTURE "@E 999.99"
	@nLin,131 pSay TRA->VLRCOM  PICTURE "@E 999,999.99"
	@nLin,143 pSay TRA->COMDEV  PICTURE "@E 999,999.99"
	
	If TRA->STATUS == "A"
		nComAbeRep += TRA->VLRCOM
		nComAbeTot += TRA->VLRCOM
	Endif
	
	If TRA->STATUS == "B"
		If Empty(TRA->PAGTO)
			nComRep += TRA->VLRCOM
			nComTot += TRA->VLRCOM
		Else
			nComPagRep += TRA->VLRCOM
			nComPagTot += TRA->VLRCOM
		Endif
	Endif
	
	nComDevRep += TRA->COMDEV
	nComDevTot += TRA->COMDEV
	
	nLin ++
	
	dbSelectArea("TRA")
	dbSkip()
	
	If cVend <> TRA->VEND1
		
		nLin ++
		@nLin,064 pSay "COMISS�ES EM ABERTO A RECEBER       ------------>"
		@nLin,131 pSay nComAbeRep  PICTURE "@E 999,999.99"
		nLin ++
		@nLin,064 pSay "PREVISAO A RECEBER EM " + dtoc(stod(dDtPagto)) + "      ------------>"
		@nLin,131 pSay nComRep  PICTURE "@E 999,999.99"
		nLin ++
		@nLin,064 pSay "COMISS�ES PAGAS NOS ULTIMOS 60 DIAS ------------>"
		@nLin,131 pSay nComPagRep  PICTURE "@E 999,999.99"
		nLin ++
		@nLin,064 pSay "COMISS�ES ABATIDAS POR DEVOLU��O    ------------>"
		@nLin,131 pSay nComDevRep  PICTURE "@E 999,999.99"
		nLin ++
		nLin ++
		
		nComAbeRep := 0
		nComRep    := 0
		nComPagRep := 0
		nComDevRep := 0
		
	Endif
	
EndDo

@nLin,064 pSay "TOTAL COMISS�ES EM ABERTO A RECEBER       ------------>"
@nLin,131 pSay nComAbeTot  PICTURE "@E 999,999.99"
nLin ++
@nLin,064 pSay "TOTAL PREVISAO A RECEBER                  ------------>"
@nLin,131 pSay nComTot     PICTURE "@E 999,999.99"
nLin ++
@nLin,064 pSay "TOTAL COMISS�ES PAGAS NOS ULTIMOS 60 DIAS ------------>"
@nLin,131 pSay nComPagTot  PICTURE "@E 999,999.99"
nLin ++
@nLin,064 pSay "TOTAL COMISS�ES ABATIDAS POR DEVOLU��O    ------------>"
@nLin,131 pSay nComDevTot  PICTURE "@E 999,999.99"

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

Static Function Previsao //TITULOS EM ABERTO POR REPRESENTANTE - PREVIS�O DE COMISS�ES

cQuery := "SELECT E1_NUM,E1_PARCELA,E1_CLIENTE,E1_LOJA,E1_NOMCLI,E1_EMISSAO,E1_VENCREA,E1_VEND1, "
cQuery += "E1_BAIXA,E1_PEDIDO,E1_SALDO,E1_VALOR,A3_NOME "
cQuery += "FROM " + RETSQLNAME("SE1") + " SE1, " + RETSQLNAME("SA3") + " SA3 "
cQuery += "WHERE SE1.D_E_L_E_T_ <> '*' AND SA3.D_E_L_E_T_ <> '*' "
cQuery += "AND E1_FILIAL = '" + xFilial("SE1") + "' AND A3_FILIAL = '" + xFilial("SA3") + "' "
cQuery += "AND E1_VEND1 = '" + SA3->A3_COD + "' AND E1_SALDO > 0 AND E1_VEND1 = A3_COD "
cQuery += "ORDER BY E1_NUM,E1_PARCELA "

If (Select("ART") <> 0)
	dbSelectArea("ART")
	dbCloseArea()
Endif

TCQUERY cQuery NEW Alias "ART"

dbSelectArea("ART")
dbGotop()

While !EOF()
	
	nComissao := Posicione("SD2",3,xFilial("SD2")+ART->E1_NUM,"D2_COMIS1")
	
	If nComissao > 0
		
		dbSelectArea("TRA")
		RecLock("TRA",.T.)
		TRA->STATUS  := "A"
		TRA->NUM     := ART->E1_NUM
		TRA->PARCELA := ART->E1_PARCELA
		TRA->CLIENTE := ART->E1_CLIENTE
		TRA->LOJA    := ART->E1_LOJA
		TRA->NOMCLI  := ART->E1_NOMCLI
		TRA->EMISSAO := STOD(ART->E1_EMISSAO)
		TRA->VENCREA := STOD(ART->E1_VENCREA)
		TRA->VEND1   := ART->E1_VEND1
//		TRA->BAIXA   := STOD(ART->E1_BAIXA)
		TRA->PEDIDO  := ART->E1_PEDIDO
		TRA->SALDO   := ART->E1_SALDO
		TRA->COMIS1  := nComissao
		TRA->VLRCOM  := ART->E1_SALDO*(nComissao/100)
		TRA->VALOR   := ART->E1_VALOR
		TRA->NOME    := ART->A3_NOME
		msUnLock("TRA")
		
	Endif
	
	dbSelectArea("ART")
	dbSkip()
	
Enddo

Return

Static Function Comissoes //MANUTEN��O DE COMISS�ES CUSTOMIZADA

cQuery := "SELECT Z5_NOTA,Z5_DUPLIC,Z5_CODCLI,Z5_CLILOJA,A1_NREDUZ,Z5_EMISSAO,Z5_VENCTO,Z5_VEND, "
cQuery += "Z5_RECTO,E1_PEDIDO,Z5_BASECOM,Z5_PERCCOM,Z5_VALCOM,Z5_VALOR,A3_NOME,Z5_PAGTO,E1_BAIXA "
cQuery += "FROM " + RETSQLNAME("SE1") + " SE1, " + RETSQLNAME("SA3") + " SA3, " + RETSQLNAME("SZ5") + " SZ5, "
cQuery += " " + RETSQLNAME("SA1") + " SA1 "
cQuery += "WHERE SE1.D_E_L_E_T_ <> '*' AND SA3.D_E_L_E_T_ <> '*' AND SZ5.D_E_L_E_T_ <> '*' AND SA1.D_E_L_E_T_ <> '*' "
cQuery += "AND E1_FILIAL = '" + xFilial("SE1") + "' AND A3_FILIAL = '" + xFilial("SA3") + "' "
cQuery += "AND A1_FILIAL = '" + xFilial("SA1") + "' AND Z5_FILIAL = '" + xFilial("SZ5") + "' "
cQuery += "AND Z5_VEND = '" + SA3->A3_COD + "' AND (Z5_PAGTO = ' ' OR Z5_PAGTO >= '" + DTOS(DDATABASE-60) + "') AND Z5_VEND = A3_COD "
cQuery += "AND E1_PREFIXO = Z5_SERIE AND E1_NUM = Z5_NOTA AND E1_PARCELA = Z5_DUPLIC AND A1_COD = Z5_CODCLI "
cQuery += "ORDER BY Z5_NOTA,Z5_DUPLIC "

If (Select("ART") <> 0)
	dbSelectArea("ART")
	dbCloseArea()
Endif

TCQUERY cQuery NEW Alias "ART"

dbSelectArea("ART")
dbGotop()

While !EOF()
	
	dbSelectArea("TRA")
	RecLock("TRA",.T.)
	TRA->STATUS  := "B"
	TRA->NUM     := ART->Z5_NOTA
	TRA->PARCELA := ART->Z5_DUPLIC
	TRA->CLIENTE := ART->Z5_CODCLI
	TRA->LOJA    := ART->Z5_CLILOJA
	TRA->NOMCLI  := ART->A1_NREDUZ
	TRA->EMISSAO := STOD(ART->Z5_EMISSAO)
	TRA->VENCREA := STOD(ART->Z5_VENCTO)
	TRA->VEND1   := ART->Z5_VEND
	TRA->BAIXA   := STOD(ART->E1_BAIXA)
	TRA->PEDIDO  := ART->E1_PEDIDO
	TRA->SALDO   := ART->Z5_BASECOM
	TRA->COMIS1  := ART->Z5_PERCCOM
	TRA->VLRCOM  := ART->Z5_VALCOM
	TRA->VALOR   := ART->Z5_VALOR
	TRA->NOME    := ART->A3_NOME
	TRA->PAGTO   := STOD(ART->Z5_PAGTO)
	msUnLock("TRA")
	
	dbSelectArea("ART")
	dbSkip()
	
Enddo

Return

Static Function Devolucoes

dbSelectArea("TRA")
dbGoTop()

cTitulo := ""
nTotDev := 0

While !EOF()
	
	If TRA->STATUS == "A" .or. (TRA->STATUS == "B" .and. Empty(TRA->PAGTO))
		
		If cTitulo <> TRA->NUM
			
			cTitulo := TRA->NUM
			
			cQuery := "SELECT D1_NFORI,D1_FORNECE,D1_LOJA,D1_DTDIGIT,D1_TOTAL "
			cQuery += "FROM " + RETSQLNAME("SD1") + " SD1 "
			cQuery += "WHERE SD1.D_E_L_E_T_ <> '*' "
			cQuery += "AND D1_FILIAL = '" + xFilial("SD1") + "' "
			cQuery += "AND D1_NFORI = '" + TRA->NUM + "' "
			
			If (Select("DEV") <> 0)
				dbSelectArea("DEV")
				dbCloseArea()
			Endif
			
			TCQUERY cQuery NEW Alias "DEV"
			
			If !Empty(DEV->D1_NFORI)
				
				dbSelectArea("DEV")
				dbGoTop()
				
				While !EOF()
					
					nTotDev += DEV->D1_TOTAL * (TRA->COMIS1/100)
					
					dbSelectArea("DEV")
					dbSkip()
					
				Enddo
				
				dbSelectArea("TRA")
				RecLock("TRA",.F.)
				TRA->COMDEV  := nTotDev
				msUnLock("TRA")
				
				nTotDev := 0
				
			Endif
			
		Endif
		
	Endif
	
	dbSelectArea("TRA")
	dbSkip()
	
Enddo

Return
