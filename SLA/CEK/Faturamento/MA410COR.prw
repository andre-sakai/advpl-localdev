#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"


//+-----------------------------------------------------------------------------------//
//|Empresa...: C&K
//|Programa..: MA410COR()
//|Autor.....: Júnior Conte 
//|Data......: 21 de junho de 2018
//|Uso.......: SIGAEST 
//|Versao....: Protheus 12    
//|Descricao.: Ponto de entrada
//|			   Regras para adicionar legenda no Pedido de venda.
//|Observação:
//+-----------------------------------------------------------------------------------//



user function MA410COR()
	aCores := { { "C5_BLPRECO == 'X'",'BR_VIOLETA'},; //Especifico C&K (Pedido cancelado)
				{"Empty(C5_LIBEROK).And.Empty(C5_NOTA) .And. Empty(C5_BLQ)",'ENABLE' },;		//Pedido em Aberto
  				{ "!Empty(C5_NOTA).Or.C5_LIBEROK=='E' .And. Empty(C5_BLQ)" ,'DISABLE'},;		   	//Pedido Encerrado
   				{ "!Empty(C5_LIBEROK).And.Empty(C5_NOTA).And. Empty(C5_BLQ)",'BR_AMARELO'},;
				{ "C5_BLQ == '1'",'BR_AZUL'},;	//Pedido Bloquedo por regra
				{ "C5_BLQ == '2'",'BR_LARANJA'}}	//Pedido Bloquedo por verba
return(aCores)