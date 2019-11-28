#INCLUDE "rwmake.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �ART026 � Autor � Roger Reghin          � Data �  14/01/03   ���
�������������������������������������������������������������������������͹��
���Descricao � Informa o codigo do produto automaticamente                ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � Sigafat                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/


User Function ART126(cCodNovo)

//���������������������������������������������������������������������Ŀ
//� Declaracao de Variaveis                                             �
//�����������������������������������������������������������������������

CcODmem := M->B1_COD

nDig01 := Val(Substr(CcODmem,08,1))
nDig02 := Val(Substr(CcODmem,07,1))
nDig03 := Val(Substr(CcODmem,06,1))
nDig04 := Val(Substr(CcODmem,05,1))
nDig05 := Val(Substr(CcODmem,04,1))
nDig06 := Val(Substr(CcODmem,03,1))
nDig07 := Val(Substr(CcODmem,02,1))
nDig08 := Val(Substr(CcODmem,01,1))

nDV := Mod((nDig01*2) + (nDig02*3) + (nDig03*4)+ (nDig04*5) + (nDig05*6) + (nDig06*7)+ (nDig07*2) + (nDig08*3),11)

If nDV # 0
	nDV := 11 - nDV
EndIf

If nDV == 10
	cDV := "9"
Elseif nDV == 0
	cDV := "0"
Elseif nDV == 1
	cDV := "1"
Else
	cDV := Alltrim(STR(nDV))
Endif   

cCodNovo := AllTrim(CcODmem) + cDV

// ALERT(cCodNovo +' - Inclu�do D�gito Verificador no Produto '+ cDV)

Return(cCodNovo)
