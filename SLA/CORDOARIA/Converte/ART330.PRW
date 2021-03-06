#INCLUDE "rwmake.ch"
#include "topconn.ch"

/*/
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北 Programa  盇RT330    � Autor � CLOVIS EMMENDORFER � Data �  11/02/08   罕�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北 Descricao � VENDAS REPRESENTANTE X CLIENTES                            罕�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北 Uso       � Especifico para Arteplas                                   罕�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
/*/

User Function ART330()

LOCAL cDesc1       := "Este programa tem como objetivo imprimir relatorio "
LOCAL cDesc2       := "de acordo com os parametros informados pelo usuario."
LOCAL cDesc3       := "Relatorio quantidade de clientes atendidos por representante."
LOCAL cPict        := ""
LOCAL titulo       := "Clientes atendidos por representantes"
LOCAL nLin         := 80
LOCAL cString      := ""
LOCAL Cabec1       := ""
LOCAL Cabec2       := ""
LOCAL imprime      := .T.
LOCAL aOrd         := {}
Private lEnd       := .F.
Private lAbortPrint:= .F.
Private CbTxt      := ""
Private limite     := 132
Private tamanho    := "P"
Private nomeprog   := "ART330"
Private nTipo      := 18
Private aReturn    := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey   := 0
Private cPerg      := "ART330"
Private cbtxt      := Space(10)
Private cbcont     := 00
Private CONTFL     := 01
Private m_pag      := 01
Private wnrel      := "ART330"

cPerg := "ART330"
aRegistros := {}
AADD(aRegistros,{cPerg,"01","Data de     ?","","","mv_ch1","D",8,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegistros,{cPerg,"02","Data ate    ?","","","mv_ch2","D",8,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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

//谀哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�
//� Declaracao de Variaveis                                             �
//滥哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�

pergunte(cPerg,.F.)

//谀哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�
//� Monta a interface padrao com o usuario...                           �
//滥哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�

wnrel := SetPrint(cString,NomeProg,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)

If nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
	Return
Endif

nTipo := If(aReturn[4]==1,15,18)

//谀哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�
//� Processamento. RPTSTATUS monta janela com a regua de processamento. �
//滥哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�

RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)
Return

/*/
苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北赏屯屯屯屯脱屯屯屯屯屯送屯屯屯淹屯屯屯屯屯屯屯屯屯退屯屯屯淹屯屯屯屯屯屯槐�
北篎un噭o    砇UNREPORT � Autor � AP6 IDE            � Data �  29/11/06   罕�
北掏屯屯屯屯拓屯屯屯屯屯释屯屯屯贤屯屯屯屯屯屯屯屯屯褪屯屯屯贤屯屯屯屯屯屯贡�
北篋escri噭o � Funcao auxiliar chamada pela RPTSTATUS. A funcao RPTSTATUS 罕�
北�          � monta a janela com a regua de processamento.               罕�
北掏屯屯屯屯拓屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯贡�
北篣so       � Programa principal                                         罕�
北韧屯屯屯屯拖屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯急�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌�
/*/

Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)

dbSelectArea("SA3")
dbSetOrder(1)
dbGoTop()

While !EOF()
	
	If Alltrim(SA3->A3_COD) = '9000' //AVULSO - VENDAS INTERNAS
		dbSkip()
		Loop
	Endif
	
	cQry := "SELECT DISTINCT D2_CLIENTE,D2_LOJA "
	cQry += "FROM " + RETSQLNAME("SD2") + " SD2, "
	cQry += " " + RETSQLNAME("SF4") + " SF4 "
	cQry += "WHERE SD2.D_E_L_E_T_ <> '*' AND "
	cQry += "SF4.D_E_L_E_T_ <> '*' AND "
	cQry += "D2_FILIAL = '" + xFilial("SD2") + "' AND "
	cQry += "F4_FILIAL = '" + xFilial("SF4") + "' AND "
	cQry += "D2_EMISSAO BETWEEN '" + DTOS(mv_par01) + "' AND '" + DTOS(mv_par02) + "' AND "
	cQry += "F4_CODIGO = D2_TES AND D2_VEND1 = '" + SA3->A3_COD + "' AND "
	cQry += "F4_DUPLIC = 'S' AND D2_TIPO = 'N' AND D2_TES <> '604' "
	
	If (Select("ART") <> 0)
		dbSelectArea("ART")
		dbCloseArea()
	Endif
	
	TCQUERY cQry NEW Alias "ART"
	
	nOcorrenc := 0
	
	dbSelectArea("ART")
	dbGoTop()
	
	While !EOF()
		
		nOcorrenc++
		
		dbSkip()
		
	Enddo
	
	cQry := "SELECT A1_COD,A1_LOJA "
	cQry += "FROM " + RETSQLNAME("SA1") + " SA1 "
	cQry += "WHERE SA1.D_E_L_E_T_ <> '*' AND "
	cQry += "A1_FILIAL = '" + xFilial("SA1") + "' AND "
	cQry += "A1_VEND = '" + SA3->A3_COD + "' "
	
	If (Select("CLI") <> 0)
		dbSelectArea("CLI")
		dbCloseArea()
	Endif
	
	TCQUERY cQry NEW Alias "CLI"
	
	nClientes := 0
	
	dbSelectArea("CLI")
	dbGoTop()
	
	While !EOF()
		
		nClientes++
		
		dbSkip()
		
	Enddo
	
	If nOcorrenc > 0 .or. nClientes > 0
		
		//12345678901234567890123456789012345678901234567890123456789012345678901234567890
		//         1         2         3         4         5         6         7         8
		//REPRESENTANTE                                    QTDE CLIENTES  QTDE CLIENTES
		//                                                 ATENDIDOS      CADASTRADOS
		//99999  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  99999          9999
		//
		
		If nLin > 55
			Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
			nLin := 6
			@nLin,01 pSay "REPRESENTANTE                                    QTDE CLIENTES  QTDE CLIENTES"
			nLin++
			@nLin,01 pSay "                                                 ATENDIDOS      CADASTRADOS"
			nLin++
			@nLin,01 pSay "============================================================================="
			nlin++
			nLin++
		Endif
		
		@nLin,01 pSay SA3->A3_COD + " - " + SA3->A3_NOME
		@nLin,50 pSay nOcorrenc Picture "@E 99999"
		@nLin,65 pSay nClientes Picture "@E 99999"
		
		nLin++
		
	Endif
	
	dbSelectArea("SA3")
	dbSkip()
	
Enddo

DbCloseArea("ART")

//谀哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�
//� Finaliza a execucao do relatorio...                                 �
//滥哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�

SET DEVICE TO SCREEN

//谀哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�
//� Se impressao em disco, chama o gerenciador de impressao...          �
//滥哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�

If aReturn[5]==1
	dbCommitAll()
	SET PRINTER TO
	OurSpool(wnrel)
Endif

MS_FLUSH()

Return
