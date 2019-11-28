#INCLUDE "rwmake.ch"       
#include "topconn.ch"         

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณART319    บ Autor ณ AP6 IDE            บ Data ณ  12/09/07   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Rotina para alterar data de entrega de pedidos de venda.   บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Arteplแs - Protheus 8 - Cl๓vis Emmendorfer                 บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

User Function ART319

cPedido := ""

Private oJanela

@ 10,015 TO 150,400 DIALOG oJanela TITLE "ARTEPLมS - Altera data de entrega dos pedidos de venda"

@ 010,020 SAY OemToAnsi("Essa rotina atualizarแ a data de entrega dos pedidos pendentes")
@ 020,020 SAY OemToAnsi("at้ o final do m๊s passado, para o primeiro dia do m๊s corrente.")    

@ 40,80 BMPBUTTON TYPE 1 ACTION PROCESSA( {|lFim| Confirma(@lFim) }, "Alterando Pedidos", "Processando Pedido: " + cPedido, .t. )
@ 40,110 BMPBUTTON TYPE 2 ACTION Close(oJanela)

ACTIVATE DIALOG oJanela CENTERED

Return

Static Function Confirma(lFim) 

cData    := dtos(stod(Substr(dtos(dDatabase),1,6) + "01") - 1)
dDataEnt := stod(Substr(dtos(dDatabase),1,6) + "01")

//SELECIONA PEDIDOS EM ABERTO 
cQry := "SELECT C6_NUM,C6_ITEM,C6_PRODUTO "
cQry += "FROM " + RETSQLNAME("SC6") + " SC6," + RETSQLNAME("SF4") + " SF4," + RETSQLNAME("SC5") + " SC5 "
cQry += "WHERE SC6.D_E_L_E_T_ <> '*' AND SC5.D_E_L_E_T_ <> '*' AND SF4.D_E_L_E_T_ <> '*' "
cQry += "AND C6_FILIAL = '" + xFilial("SC6") + "' "
cQry += "AND C5_FILIAL = '" + xFilial("SC5") + "' "
cQry += "AND F4_FILIAL = '" + xFilial("SF4") + "' "
cQry += "AND C6_ENTREG <= '" + cData + "' AND C5_NUM = C6_NUM AND C5_TIPO = 'N' "
cQry += "AND C6_QTDENT < C6_QTDVEN AND C6_TES = F4_CODIGO "
cQry += "AND C6_BLQ = '' "
cQry += "ORDER BY C6_NUM,C6_ITEM,C6_PRODUTO "
	
If (Select("ART") <> 0)
	dbSelectArea("ART")
	dbCloseArea()
Endif
	
TCQUERY cQry NEW Alias "ART"  

dbSelectArea("ART")
dbGoTop()
               
Procregua(RecCount("ART"))

While !EOF()

	dbSelectArea("SC6")
	dbSetOrder(1)
	dbGoTop()
	
	If dbSeek(xFilial("SC6") + ART->C6_NUM + ART->C6_ITEM + ART->C6_PRODUTO)
	
		RecLock("SC6",.F.)
			SC6->C6_ENTREG := dDataEnt
		MsUnLock("SC6")
		
	Endif
		    
	dbSelectArea("ART")	
	dbSkip()
	
	cPedido:= ART->C6_NUM
	
	IncProc("Processando Pedido: " + cPedido)
	
Enddo

Close(oJanela)
	
Return