#INCLUDE "rwmake.ch"
#include "topconn.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณART183    บ Autor ณ Eduardo Marquetti  บ Data ณ  04/07/13   บฑฑ
ฑฑบAltera็ใo: 					                                          บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Relatorio de Pedidos com Pendencia de Produ็ใo             บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Especifico para Arteplas                                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

User Function ART183


//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Declaracao de Variaveis                                             ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

Local cDesc1         	:= "Este programa tem como objetivo imprimir relatorio "
Local cDesc2         	:= "de acordo com os parametros informados pelo usuario."
Local cDesc3         	:= ""
Local cPict          	:= ""
Local titulo         	:= "Relatorio Sintetico de Pedidos de Venda"
Local nLin         		:= 57

Local Cabec1      		:= ""
Local Cabec2       		:= ""
Local imprime      		:= .T.
Local aOrd 				:= {}
Private lEnd         	:= .F.
Private lAbortPrint  	:= .F.
Private CbTxt        	:= ""
Private limite       	:= 220
Private cPerg           := "ART183"
Private tamanho      	:= "G"
Private nomeprog     	:= "ART183" // Nome do programa para impressao no cabecalho
Private nTipo        	:= 18
Private aReturn      	:= { "Zebrado", 1, "Administracao", 1, 2, 1, "", 1}
Private nLastKey     	:= 0
Private cbtxt      		:= Space(10)
Private cbcont     		:= 00
Private CONTFL     		:= 01
Private m_pag      		:= 01
Private wnrel      		:= "ART183" // Nome do arquivo usado para impressao em disco

cPerg := "ART183"

pergunte(cPerg,.F.)

Private cString := "SC6"

dbSelectArea("SC6")
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


cQuery := " SELECT "
cQuery += " C6_PRODUTO,B1_DESC,B1_UM,B1_BITOLA,SUM(C6_QTDVEN)AS VENDIDO,SUM(C6_QTDENT)AS ENTREGUE, SUM(C6_QTDVEN - C6_QTDENT) AS SALDO, "
cQuery += " SUM(C6_UNSVEN)VENDIDOKG,SUM(C6_QTDENT2)ENTREGUEKG, SUM(C6_UNSVEN - C6_QTDENT2) AS SALDOKG, "     
cQuery += " SUM (C6_QTDVEN * C6_PRCVEN) AS VALOR "     
cQuery += " FROM SC6030,SB1030 "
cQuery += " WHERE              "  
cQuery += " C6_FILIAL = '01' AND B1_FILIAL = '01' "
cQuery += " AND SC6030.D_E_L_E_T_ <> '*' AND SB1030.D_E_L_E_T_ <> '*' "
cQuery += " AND C6_PRODUTO = B1_COD "

cQuery += " AND (C6_NUM IN " + FormatIn(mv_par01,";") +" OR C6_NUM IN "+ FormatIn(mv_par02,";") +" OR C6_NUM IN "+ FormatIn(mv_par03,";")+ " OR C6_NUM IN "+ FormatIn(mv_par04,";")+") "

cQuery += " GROUP BY C6_PRODUTO,B1_UM,B1_DESC,B1_BITOLA   "
cQuery += " ORDER BY B1_DESC        "

TcQuery cQuery New Alias "TRB"      

//	MsgBox(cQuery)

TcSetField("TRB","C6_PRODUTO","C",35,0)

DbSelectArea("TRB")
TRB->(dbGoTop())
                                                                                                                                                                                        
	Cabec1  := "Produto      Descri็ใo                                      BT  UM         Vendido        Faturado           Saldo     Vendido(Kg)    Faturado(Kg)       Saldo(Kg)              Valor" 
	//          XXXXXXXXXX   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  XX  XX  999,999,999.99  999,999,999.99  999,999,999.99  999,999,999.99  999,999,999.99  999,999,999.99     999,999,999.99
	//          0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
	//                    10        20        30        40        50       60        70       80        90        100       110       120       130       140       150       160       170       180

nTotVendidoKg  := 0
nTotEntregueKg := 0
nTotSaldoKg    := 0
nTValor        := 0

cCodAux := ''


While !TRB->(Eof())
	_cCod := TRB->C6_PRODUTO

	While !TRB->(Eof()) .and. TRB->C6_PRODUTO == _cCod
		If nLin > 56
			Cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
			nLin := 8
		Endif

		@ nLin,000 PSay Left(TRB->C6_PRODUTO,9) //09
		@ nLin,013 PSay Left(TRB->B1_DESC,50 )  //50
		@ nLin,060 PSay transform(TRB->B1_BITOLA,"@E 99")    //02           
		@ nLin,064 PSay TRB->B1_UM    			//02                    

		@ nLin,068 PSay transform(TRB->VENDIDO ,"@E 99,999,999.99")
		@ nLin,084 PSay transform(TRB->ENTREGUE,"@E 99,999,999.99")
		@ nLin,100 PSay transform(TRB->SALDO   ,"@E 99,999,999.99")
		
		@ nLin,116 PSay transform(TRB->VENDIDOKG ,"@E 99,999,999.99")
		@ nLin,132 PSay transform(TRB->ENTREGUEKG,"@E 99,999,999.99")
		@ nLin,148 PSay transform(TRB->SALDOKG   ,"@E 99,999,999.99")
		
		@ nLin,167 PSay transform(TRB->VALOR ,"@E 99,999,999.99")
			                     
// Soma o Peso dos Produtos

		If TRB->B1_UM == "KG"
			nTotVendidoKg  += TRB->VENDIDO   
			nTotEntregueKg += TRB->ENTREGUE
			nTotSaldoKg    += TRB->SALDO
		Else
			nTotVendidoKg  += TRB->VENDIDOKG
			nTotEntregueKg += TRB->ENTREGUEKG
			nTotSaldoKg    += TRB->SALDOKG
		EndIf                                
		
		nTValor += TRB->VALOR
			  

		nLin++
		TRB->(DbSkip())
	Enddo

EndDo
	If nTotVendidoKg> 0
		nLin++
		@ nLin,000 PSay "Total Geral"
		@ nLin,116 PSay transform(nTotVendidoKg ,"@E 99,999,999.99")
		@ nLin,132 PSay transform(nTotEntregueKg,"@E 99,999,999.99")
		@ nLin,148 PSay transform(nTotSaldoKg   ,"@E 99,999,999.99")
		@ nLin,167 PSay transform(nTValor       ,"@E 99,999,999.99")
	Endif

DbSelectArea("TRB")
DbCloseArea("TRB")


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