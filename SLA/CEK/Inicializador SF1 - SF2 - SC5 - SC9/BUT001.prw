#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"

/*
FUNCAO PARA RETORNAR O NOME DO CLIENTE OU FORNECEDOR NO BROWSE DO PEDIDO DE VENDAS. 
UTILIZADO NO INICIALIZADOR PADRAO DO CAMPO C5_NOMCLI - Inicializador Browser - EXECBLOCK("BUT001",.T.,.T.)
*/

User Function BUT001

_lRet := ""

If SC5->C5_TIPO $'NCIP'
	_lRet := POSICIONE("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME")
Else
    _lRet := POSICIONE("SA2",1,xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A2_NOME")
EndIf    

//IIF(SC5->C5_TIPO$'NCIP',POSICIONE("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME"),POSICIONE("SA2",1,xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A2_NOME"))

Return(_lRet)