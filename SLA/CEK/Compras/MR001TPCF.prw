User Function AVAITPCF()
***********************
Local cArea := GetArea()[1]

if INCLUI
	If TYPE('M->A1_COD') <> 'U'
		if !Empty(M->A1_CGC)
			If M->A1_PESSOA == 'F'
				M->A1_COD := SubStr(M->A1_CGC,1,11)
				M->A1_LOJA:= '0000'
			Else
				M->A1_COD := SubStr(M->A1_CGC,1,08)
				M->A1_LOJA:= SubStr(M->A1_CGC,9,04)
			Endif
		Endif
		
	Elseif TYPE('M->A2_COD') <> 'U'
		If !Empty(M->A2_CGC)
			If M->A2_TIPO == 'F'
				M->A2_COD := SubStr(M->A2_CGC,1,11)
				M->A2_LOJA:= '0000'
			Elseif M->A2_TIPO == 'J'
				M->A2_COD := SubStr(M->A2_CGC,1,08)
				M->A2_LOJA:= SubStr(M->A2_CGC,9,04)
			Endif
		Endif
	Endif
Endif
Return &(ReadVar())

