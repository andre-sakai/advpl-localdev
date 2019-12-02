#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณF050MDVC   บ Autor ณ Kellin / SMS บ  Data ณ12/11/14         บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Tratamento para data de vencimento dos impostos,           บฑฑ
ฑฑบ          ณ ISS/INSS/IRRF/PIS/COFINS/CSLL.                             บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP11 IDE                                                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/


USER FUNCTION F050MDVC
Local dVencPR := ParamIXB[1]
Local cImposto := ParamIXB[2]
Local dEmissao := ParamIXB[3]
Local dEmis1 := ParamIXB[4]
Local dVencRea := ParamIXB[5]



/*ISS (notas de entrada e de saida): dia 15 do mes seguinte;
CONTRIBUIวีES RETIDAS (emissใo em 01-15 do mes): dia 31 do mesmo mes;
CONTRIBUIวีES RETIDAS (emissใo 16-31 do mes): dia 15 do mes seguinte;
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

// Tratamento da Data para Nใo Cair aos Sabados, Domingos e Feriados
//O ISS quando o dia 15 do mes seguinte ้ no fim de semana, o pagamento ้ posterior,
//jแ para os demais impostos, quando a data de vencimento ้ no fim de semana, o pagamento antecipa.


If Dow(dDtVenc) == 1 .And. AllTrim(Upper(cImposto)) $ 'CSLL*PIS*COFINS*INSS*IRRF'
dDtVenc := dDtVenc-2
dDtVenc := DataValida(dDtVenc)
ElseIf Dow(dDtVenc) == 7 .And. AllTrim(Upper(cImposto)) $ 'CSLL*PIS*COFINS*INSS*IRRF'
dDtVenc := dDtVenc-1
dDtVenc := DataValida(dDtVenc)
Endif


RETURN dDtVenc