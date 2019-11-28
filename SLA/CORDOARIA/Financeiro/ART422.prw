#INCLUDE "rwmake.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ART422    º Autor ³ EDUARDO MARQUETTI  º Data ³  14/02/01   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ CALCULO DO DIGITO DO NOSSO NUMERO BRADESCO                 º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP5 IDE                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function ART422

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

cCodEmp := space(6)
cFaixa	:= space(6)
nDV		:= 0
cDV		:= space(1)
nSoma	:= 0
nResto  := 0
cNumBco	:= space(11)
cCampo  := 0 
nDig01  := 0
nDig03  := 0
nDig04  := 0
nDig05  := 0
nDig06  := 0
nDig07  := 0
nDig08  := 0
nDig09  := 0
nDig10  := 0
nDig11  := 0
nDig12  := 0

dbSelectArea("SEE")
dbSetOrder(1)
dbGoTop()
dbSeek(xFilial("SEE")+"01237",.F.)

cNumBco := "0"+Alltrim(SEE->EE_FAXATU)

nfaxatu := 0
nfaxatu := val(SEE->EE_FAXATU)

nfaxatu := nfaxatu + 1        

//reclock('SEE',.f.)
//  see->ee_faxatu := strzero(nfaxatu,10)
//msunlock()

nDig01 := 0   //Entrar com o primeiro número da carteira
nDig02 := 9   //Entrar com o segundo númenro da carteira
nDig03 := val(Substr(cNumBco,01,1))
nDig04 := val(Substr(cNumBco,02,1))
nDig05 := val(Substr(cNumBco,03,1))
nDig06 := val(Substr(cNumBco,04,1))
nDig07 := val(Substr(cNumBco,05,1))
nDig08 := val(Substr(cNumBco,06,1))
nDig09 := val(Substr(cNumBco,07,1))
nDig10 := val(Substr(cNumBco,08,1))
nDig11 := val(Substr(cNumBco,09,1))
nDig12 := val(Substr(cNumBco,10,1))

nSoma := (nDig01*2) + (nDig02*7) + (nDig03*6);
       + (nDig04*5) + (nDig05*4) + (nDig06*3);
       + (nDig07*2) + (nDig08*7) + (nDig09*6);
       + (nDig10*5) + (nDig11*4) + (nDig12*3)

nResto  := Int(nSoma / 11)
nDV  	:= nSoma - (nResto * 11)
If nDV  := 0
	cDv := 0
Else
	nDv := 11 - nDv
EndIf

If nDV == 10
	cDV := "P"
Else
	cDV := Alltrim(STR(nDV))
EndIf
cCampo := Alltrim(cNumBco)+Alltrim(cDv)

reclock("SE1",.F.)
  se1->e1_numbco := cCampo
msunlock("SE1")

Return(cCampo)