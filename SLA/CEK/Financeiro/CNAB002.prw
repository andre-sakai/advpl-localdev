#include "rwmake.ch"   

User Function CNAB002()  

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  � SEL001   � Autor � MICROSIGA              � Data � 21/02/08���
�������������������������������������������������������������������������͹��
���Descri��o � Incrementa 1 (Hum) no sequencial de linha detalhe          ���
�������������������������������������������������������������������������͹��
���Observacao� Deve ser utilizado em conjunto com o P.E. FIN150_1, para   ���
���          � que n�o seja acrescentado 2 (dois) quando mudar de t�tulo. ���
�������������������������������������������������������������������������͹��
���Uso       � Banco do Brasil                                            ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

nSeq := nSeq+1

Return(nSeq) 