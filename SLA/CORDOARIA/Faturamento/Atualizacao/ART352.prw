#INCLUDE "rwmake.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �ART352    � Autor � AP6 IDE            � Data �  24/09/08   ���
�������������������������������������������������������������������������͹��
���Descricao � Clovis Emmendorfer                                         ���
���          � Cadastro de CEP�s                                          ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function ART352


//���������������������������������������������������������������������Ŀ
//� Declaracao de Variaveis                                             �
//�����������������������������������������������������������������������

Local cVldAlt := ".T." // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
Local cVldExc := ".T." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.

Private cString := "SZ4"

dbSelectArea("SZ4")
dbSetOrder(1)

AxCadastro(cString,"Cadastro de CEP",cVldExc,cVldAlt)

Return
