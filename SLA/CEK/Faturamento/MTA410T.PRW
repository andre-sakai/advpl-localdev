#include "rwmake.ch"
#include "topconn.ch"      
#include "totvs.ch"
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma³CEKSL01ºAutor³Júniro Conte     º Data ³  03/05/2017           º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Função para mudar legenda no pedido de venda               ¹±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ C & K Industrial                                           º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßß
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

USER FUNCTION MTA410T()


Dbselectarea("SC9")
Dbsetorder(1)
SC9->(Dbseek(SC5->(C5_FILIAL+C5_NUM))) 

WHILE SC9-> ( !EOF() ) .AND. SC9->C9_PEDIDO == SC5->C5_NUM  .and.  SC9->C9_FILIAL == SC5->C5_FILIAL
	
	IF SC9->C9_BLEST == '02' //SE ESTIVER BLOQUEADO POR ESTOQUE MUDA A LEGENDA
		DbSelectArea("SC5") 
		Reclock("SC5",.F.)	
			SC5->C5_ZBLQ := '1'
			SC5->C5_BLQ  := '1'
		Msunlock()
	Endif
	
	IF SC9->C9_BLCRED == '01' //SE ESTIVER BLOQUEADO POR CREDITO.
		DbSelectArea("SC5") 
		Reclock("SC5",.F.)	
			SC5->C5_BLQ  := '1'
			SC5->C5_ZBLQ := '2'
		Msunlock()
	Endif
			
	SC9 -> ( Dbskip() )
	
Enddo


Return 






