/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
Programa:		MT410CPY
Autor:          Eduardo Marquetti
Data:           15/02/2017
Descricao:     	Limpar campo Pedido DW (FDV) quando realizado copia de outro pedido de venda 
Responsavel:	
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
#INCLUDE "rwmake.ch"

User Function MT410CPY

// Retorna " " ('Branco') para o N�mero do Pedido de Vendas FDV
M->C5_XPEDDW := " "

Return
