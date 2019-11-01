#include "rwmake.ch"     

User Function lindigvl() 

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
//� Declaracao de variaveis utilizadas no programa atraves da funcao    �
//� SetPrvt, que criara somente as variaveis definidas pelo usuario,    �
//� identificando as variaveis publicas do sistema utilizadas no codigo �
//� Incluido pelo assistente de conversao do AP5 IDE                    �
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

SetPrvt("LRET,CSTR,I,NMULT,NMODULO,CCHAR")
SetPrvt("CDIGITO,CDV1,CDV2,CDV3,CCAMPO1,CCAMPO2")
SetPrvt("CCAMPO3,NVAL,NCALC_DV1,NCALC_DV2,NCALC_DV3,NREST")

/*/
└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└�
└+-----------------------------------------------------------------------+└
└쪭un裔o    � LindigVL � Autor � Vicente Sementilli    � Data � 26/02/97 └�
└+----------+------------------------------------------------------------└�
└쪫escri裔o � Calculo do modulo 11 sugerido pelo ITAU. Esta funcao       └�
└�          � somente e utilizada como validacao do campo E2_LINDIG.     └�
└�          �                                                            └�
└�          � Esta rotina tambem tranforma o codigo digitado em codigo   └�
└�          � de barras se necessario                                    └�
└�          �                                                            └�
└�          �                                                            └�
└�          � O campo E2_XLINDIG nao existe no padrao ele deve ser criado└�
└�          �                                                            └�
└�          � Nome        Tipo   Tamanho   Validacao                     └�
└�          � -----------  --     ----     ----------------------------  └�
└�          � E2_XLINDIG   C       47      EXECBLOCK("LINDIGVL")         └�
└+----------+------------------------------------------------------------└�
└쪨lterado  � M�rcio e Vitor - Siga Campinas para tratamento do fator    └�
└�          � Vencimento criado a partir de 01/09/2000                   └�
└�          � Campo alterado para  47 digitos                            └�
└+-----------------------------------------------------------------------+└
└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└�
/*/
LRET := .F.

if ValType(M->E2_XLINDIG) == NIL
   Return(.t.)   
Endif

cStr := M->E2_XLINDIG

nVlrCodBar	:= Substr(cStr,38,10)
//nVlrTit		:= STRZERO(INT(ROUND(SE2->E2_SALDO*100,2)),10)
nVlrTit		:= STRZERO(INT(ROUND(IIF( !INCLUI, SE2->E2_SALDO, M->E2_VALOR ) * 100,2)),10)
If nVlrCodBar <> "0000000000" .AND. !EMPTY(M->E2_XLINDIG)
	If nVlrCodBar <> nVlrTit
		APMSGALERT("Verifique se o t�tulo digitado corresponde ao fornecedor.","AVISO VALOR TITULO")
	EndIf
EndIF

i := 0
nMult := 2
nModulo := 0
cChar := SPACE(1)
cDigito := SPACE(1)

If len(AllTrim(cStr)) < 44 .OR. len(AllTrim(cStr)) == 47
   
   cDV1    := SUBSTR(cStr,10, 1) 
   cDV2    := SUBSTR(cStr,21, 1) 
   cDV3    := SUBSTR(cStr,32, 1) 
   
   cCampo1 := SUBSTR(cStr, 1, 9)
   cCampo2 := SUBSTR(cStr,11,10)
   cCampo3 := SUBSTR(cStr,22,10)

   /*/
   └└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└�
   └+-----------------------------------------------------------------------+└
   └쪫escri裔o � Calculo do modulo 10 sugerido pelo ITAU. Esta funcao       └�
   └�          � somente e utilizada como validacao do campo E2_IPTE.     └�
   └�          � Verifica a digitacao do codigo de barras                   └�
   └+-----------------------------------------------------------------------+└
   └└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└�
   /*/
   //
   // Calcula DV1
   //
   nMult := 2
   nModulo := 0
   nVal := 0
   
	For i := Len(cCampo1) to 1 Step -1
   	cChar := Substr(cCampo1,i,1)
      if isAlpha(cChar)
			Help(" ", 1, "ONLYNUM")
	  		Return(.f.)   
      endif
		nModulo := Val(cChar)*nMult
		If nModulo >= 10
			nVal := NVAL + 1
			nVal := nVal + (nModulo-10)
		Else
			nVal := nVal + nModulo	
		EndIf	
		nMult:= if(nMult==2,1,2)
   Next        
   nCalc_DV1 := 10 - (nVal % 10)
   nCalc_DV1 := IIF(nCalc_DV1==10,0,nCalc_DV1)
	
   //
   // Calcula DV2
   //
   nMult := 2
   nModulo := 0
	nVal := 0
   
	For i := Len(cCampo2) to 1 Step -1
   	cChar := Substr(cCampo2,i,1)
     	if isAlpha(cChar)
			Help(" ", 1, "ONLYNUM")
			Return(.f.) 
		endif        
		nModulo := Val(cChar)*nMult
		If nModulo >= 10
			nVal := nVal + 1
			nVal := nVal + (nModulo-10)
		Else
			nVal := nVal + nModulo	
		EndIf	
		nMult:= if(nMult==2,1,2)
   Next        
   nCalc_DV2 := 10 - (nVal % 10)
   nCalc_DV2 := IIF(nCalc_DV2==10,0,nCalc_DV2)

   //
   // Calcula DV3
   //
   nMult := 2
   nModulo := 0
	nVal := 0
   
   For i := Len(cCampo3) to 1 Step -1
		cChar := Substr(cCampo3,i,1)
		if isAlpha(cChar)
			Help(" ", 1, "ONLYNUM")
			Return(.f.) 
		endif        
		nModulo := Val(cChar)*nMult
		If nModulo >= 10
			nVal := nVal + 1
			nVal := nVal + (nModulo-10)
		Else
			nVal := nVal + nModulo	
		EndIf	
		nMult:= if(nMult==2,1,2)
   Next        
   nCalc_DV3 := 10 - (nVal % 10)
   nCalc_DV3 := IIF(nCalc_DV3==10,0,nCalc_DV3)

   if !(nCalc_DV1 == Val(cDV1) .and. nCalc_DV2 == Val(cDV2) .and. nCalc_DV3 == Val(cDV3) )
      Help(" ",1,"INVALCODBAR")
      lRet := .f.
   else         
      lRet := .t.
   endif                
   
Else
   cDigito := SUBSTR(cStr,5, 1)
   cStr    := SUBSTR(cStr,1, 4)+ ;
              SUBSTR(cStr,6,39)

   /*/
   └└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└�
   └+-----------------------------------------------------------------------+└
   └쪫escri裔o � Calculo do modulo 11 sugerido pelo ITAU. Esta funcao       └�
   └�          � somente e utilizada como validacao do campo E2_IPTE.     └�
   └�          � Verifica o codigo de barras grafico (Atraves de leitor)    └�
   └+-----------------------------------------------------------------------+└
   └└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└└�
   /*/

   cStr := AllTrim(cStr)

   if Len(cStr) < 43
      Help(" ", 1, "FALTADG")
	  Return(.f.)   
   Endif

   For i := Len(cStr) to 1 Step -1
        cChar := Substr(cStr,i,1)
        if isAlpha(cChar)
           Help(" ", 1, "ONLYNUM")
           Return(.f.)  
        endif        
        nModulo := nModulo + Val(cChar)*nMult
        nMult:= if(nMult==9,2,nMult+1)
   Next        
   nRest := 11 - (nModulo % 11)
   nRest := if(nRest==10 .or. nRest==11,1,nRest)  
   if nRest <> Val(cDigito)
      Help(" ",1,"DgSISPAG")
      lRet := .f.
   else         
      lRet := .t.
   endif                

Endif

Return(lRet)  
