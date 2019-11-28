//PONTO DE ENTRADA NA GRAVA��O DOS �TENS DA NOTA FISCAL DE SA�DA (SD2)

#include "rwmake.ch" 

User Function MSD2460()

RecLock("SD2",.F.)
	SD2->D2_VEND1 := SF2->F2_VEND1                 
	SD2->D2_SAIDA  := SC6->C6_SAIDA  // Incu�do para Controlar os Faturamenteos Antecipados
	SD2->D2_QTDSAI := SC6->C6_QDTSAI // Incu�do para Controlar os Faturamenteos Antecipados

MsUnlock("SD2")      

//Incluido por Cl�vis - 14/02/07
//Inclui o nro da carga no item da NF. Utilizado no relatorio de montagem de cargas.

dbSelectArea("SC5")
dbSetOrder(1)
dbGoTop()

dbSeek(xFilial("SC5")+SD2->D2_PEDIDO,.T.)

RecLock("SD2",.F.)
	SD2->D2_CARGA := SC5->C5_CARGA
MsUnlock("SD2")      

Return