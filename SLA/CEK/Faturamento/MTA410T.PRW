#include "rwmake.ch"
#include "topconn.ch"      
#include "totvs.ch"
/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa�CEKSL01�Autor�J�niro Conte     � Data �  03/05/2017           ���
�������������������������������������������������������������������������͹��
���Descricao � Fun��o para mudar legenda no pedido de venda               ���
�������������������������������������������������������������������������͹��
���Uso       � C & K Industrial                                           ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
��������������������
���������������������������������������������������������
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
		
	Elseif SC9->C9_BLEST <> '02'
		
		DbSelectArea("SC5") 
		Reclock("SC5",.F.)	
			SC5->C5_BLQ  := ' '
			SC5->C5_ZBLQ := ' '
		Msunlock()
	
	endif
			
	SC9 -> ( Dbskip() )
	
Enddo


Return 






