#INCLUDE "rwmake.ch"
/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �FC021ATRB  � Autor � Jeyson Gurek / SMS �  Data �08/10/14   ���
�������������������������������������������������������������������������͹��
���Descricao � atualizar o valor dos novos campos inclu�dos no arquivo    ���
���          � tempor�rio. Esses campos s�o criados por meio do           ���
���          � Ponto de Entrada FC021CPO.                                 ���
�������������������������������������������������������������������������͹��
���Uso       � AP11 IDE                                                   ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
User Function FC021ATRB()

Local cAliasAna  := PARAMIXB[1]  //Nome do arquivo tempor�rio Anal�tico Contas a Receber.					
Local cAliasTrb  := PARAMIXB[2]  //	Nome do arquivo de trabalho utilizado. 	
Local cCampo     := PARAMIXB[3]

(cAliasAna)->HIST := (cAliasTrb)->&(cCampo+"_HIST")                
(cAliasAna)->ORIG := 'Previsto'

Return 
