#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �F050MDVC   � Autor � Kellin / SMS �  Data �12/11/14         ���
�������������������������������������������������������������������������͹��
���Descricao � Tratamento para data de vencimento dos impostos,           ���
���          � ISS/INSS/IRRF/PIS/COFINS/CSLL.                             ���
�������������������������������������������������������������������������͹��
���Uso       � AP11 IDE                                                   ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/


USER FUNCTION F050MDVC
Local dVencPR := ParamIXB[1]
Local cImposto := ParamIXB[2]
Local dEmissao := ParamIXB[3]
Local dEmis1 := ParamIXB[4]
Local dVencRea := ParamIXB[5]



/*ISS (notas de entrada e de saida): dia 15 do mes seguinte;
CONTRIBUI��ES RETIDAS (emiss�o em 01-15 do mes): dia 31 do mesmo mes;
CONTRIBUI��ES RETIDAS (emiss�o 16-31 do mes): dia 15 do mes seguinte;
IRRF: dia 20 do mes seguinte;
INSS: dia 20 do mes seguinte;*/

If AllTrim(Upper(cImposto)) == 'IRRF'
dDtVenc := MsSomaMes(dEmissao,1,.T.)
dDtVenc := CtoD('20/'+StrZero(Month(dDtVenc),2)+'/'+Str(Year(dDtVenc),4))
ElseIf	AllTrim(Upper(cImposto)) == 'INSS'
dDtVenc := MsSomaMes(dEmissao,1,.T.)
dDtVenc := CtoD('20/'+StrZero(Month(dDtVenc),2)+'/'+Str(Year(dDtVenc),4))
ElseIf	AllTrim(Upper(cImposto)) $ 'CSLL*PIS*COFINS'
If Day2Str(dEmissao) <= '15'
dDtVenc := Lastday(dEmissao,0)
Else
dDtVenc := MsSomaMes(dEmissao,1,.T.)
dDtVenc := CtoD('15/'+StrZero(Month(dDtVenc),2)+'/'+Str(Year(dDtVenc),4))
Endif
ElseIf	AllTrim(Upper(cImposto)) == 'ISS'
alert ("ISS")
dDtVenc := MsSomaMes(dEmissao,1,.T.)
dDtVenc := CtoD('15/'+StrZero(Month(dDtVenc),2)+'/'+Str(Year(dDtVenc),4))

If Dow(dDtVenc) == 1
dDtVenc := dDtVenc+1
dDtVenc := DataValida(dDtVenc)
ElseIf Dow(dDtVenc) == 7
dDtVenc := dDtVenc+2
dDtVenc := DataValida(dDtVenc)
Endif

Endif

// Tratamento da Data para N�o Cair aos Sabados, Domingos e Feriados
//O ISS quando o dia 15 do mes seguinte � no fim de semana, o pagamento � posterior,
//j� para os demais impostos, quando a data de vencimento � no fim de semana, o pagamento antecipa.


If Dow(dDtVenc) == 1 .And. AllTrim(Upper(cImposto)) $ 'CSLL*PIS*COFINS*INSS*IRRF'
dDtVenc := dDtVenc-2
dDtVenc := DataValida(dDtVenc)
ElseIf Dow(dDtVenc) == 7 .And. AllTrim(Upper(cImposto)) $ 'CSLL*PIS*COFINS*INSS*IRRF'
dDtVenc := dDtVenc-1
dDtVenc := DataValida(dDtVenc)
Endif


RETURN dDtVenc