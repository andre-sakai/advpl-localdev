#INCLUDE "rwmake.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �NOVO3     � Autor � AP6 IDE            � Data �  31/10/14   ���
�������������������������������������������������������������������������͹��
���Descricao � Codigo gerado pelo AP6 IDE.                                ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function CODSB1()

Local cString := "SB1"
Local cCodigo       
Local aAreaAnt := GETAREA()
Local nLastRec := 0   
Local nx := 0

DBSELECTAREA("SB1")   
nLastRec := SB1->( LASTREC())

SB1->(DbGoTo(nLastRec))     
If !Deleted()
	cCodigo := Soma1(Alltrim(SB1->B1_COD))
Else
	For nx := 1 to 50
		SB1->(DbGoTo(nLastRec-nx))     	
		If !Deleted()
			cCodigo := Soma1(Alltrim(SB1->B1_COD))
            exit
        EndIf    
   	Next
EndIf    
RESTAREA(aAreaAnt)

Return(cCodigo)
