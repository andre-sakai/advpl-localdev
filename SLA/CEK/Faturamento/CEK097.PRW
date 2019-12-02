#INCLUDE "RWMAKE.CH"

/*/
=============================================================
Programa     : CEK097()
Data         : 18/07/2017
Alterado por : 
Data         : 
-------------------------------------------------------------
Descricao    : Atualiza peso no cabeçalho do pedido de venda.                                    
Módulo (Uso) : SIGAFAT
=============================================================
/*/    

User Function CEK097(cPar01)
	Local	aArea	:= GetArea()
	Local	nB1Peso	:= 0
	Private	nPeso	:= 0
	Private nQtdVol := 0

	dbSelectArea("SC6")
	dbgotop()
	dbSetOrder(1)
	dbSeek(XFILIAL()+cPar01)
	While !EOF() .AND. SC6->C6_FILIAL+SC6->C6_NUM==xFilial("SC5")+cPar01
		nB1Peso	:= Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_PESBRU")
		
		nPeso += nB1Peso * SC6->C6_QTDVEN

		nQtdVol  += SC6->C6_QTDVEN
		
		dbSelectArea("SC6")
		dbSkip()
	Enddo

	RecLock("SC5",.F.)
		SC5->C5_PBRUTO	:= nPeso
		SC5->C5_VOLUME1 := nQtdVol  
	MsUnLock("SC5")

	RestArea(aArea)

Return