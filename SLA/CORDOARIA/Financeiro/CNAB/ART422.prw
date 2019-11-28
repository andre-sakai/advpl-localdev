#INCLUDE "rwmake.ch"              
#INCLUDE "PROTHEUS.CH"  				

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ART422    º Autor ³ Adair de Souza     º Data ³  18/01/02   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ CALCULO DO DIGITO DO NOSSO NUMERO BRADESCO                 º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP5 IDE                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

USER Function ART422

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

cCodEmp := space(11)
cFaixa	:= space(10)
nDV     := 0
cDV     := space(1)
nSoma	:= 0
nResto  := 0
cNumBco	:= space(13)
cCampo  := 0 
nDig01  := 0
nDig02  := 0
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
nDig13  := 0
nDig14  := 0
nDig15  := 0
nDig16  := 0
nDig17  := 0
nDig18  := 0
nDig19  := 0

dbSelectArea("SEE")
 dbSetOrder(1) // EE_FILIAL+EE_CODIGO+EE_AGENCIA+EE_CONTA+EE_SUBCTA  
 dbGoTop()                               
dbSeek(xFilial("SEE")+"2377252400751731  09",.F.)      
//                     2377252400751731  09


cNumBco := "09"+"00"+Alltrim(SEE->EE_FAXATU)

nfaxatu := 0
nfaxatu := Val(SEE->EE_FAXATU)
nfaxatu := nfaxatu + 1

reclock('SEE',.f.)
  see->ee_faxatu := StrZero(nfaxatu,11)
msunlock()              

nDig01 := val(Substr(cNumBco,13,1))
nDig02 := val(Substr(cNumBco,12,1))
nDig03 := val(Substr(cNumBco,11,1))
nDig04 := val(Substr(cNumBco,10,1))
nDig05 := val(Substr(cNumBco,09,1))
nDig06 := val(Substr(cNumBco,08,1))
nDig07 := val(Substr(cNumBco,07,1))
nDig08 := val(Substr(cNumBco,06,1))
nDig09 := val(Substr(cNumBco,05,1))
nDig10 := val(Substr(cNumBco,04,1))
nDig11 := val(Substr(cNumBco,03,1))
nDig12 := val(Substr(cNumBco,02,1))
nDig13 := val(Substr(cNumBco,01,1))

nSoma := (nDig01*2) + (nDig02*3) + (nDig03*4);
       + (nDig04*5) + (nDig05*6) + (nDig06*7);
       + (nDig07*2) + (nDig08*3) + (nDig09*4);
       + (nDig10*5) + (nDig11*6) + (nDig12*7);
       + (nDig13*2)

nResto  := Int(nSoma / 11)
nCal    := Int(nResto * 11) 
nResto  := nSoma - nCal
 
nDV := 11 - nResto

If nResto == 0
   nDV := 0
endIf
   
cDV := Alltrim(STR(nDV))

If nResto == 1 
   cDV := 'P'
endIf
cCampo := Alltrim(substr(cNumBco,03,11))+Alltrim(cDv)
 
reclock("SE1",.F.)
  se1->e1_numbco := SUBSTR(cCampo,2,11)
msunlock("SE1")

Return(cCampo)