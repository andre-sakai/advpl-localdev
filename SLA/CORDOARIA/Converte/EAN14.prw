#INCLUDE "rwmake.ch"
#include "TopConn.ch"        

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³EAN14     º Autor ³ Marcelo J. Santos  º Data ³  04/10/06   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ ExecBlock chamado por gatilho do campo B5_COD para gerar   º±±
±±º          ³ Codigo de Barras padrao EAN 14 para Embalagem do Produto   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Especifico para Arteplas                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/






User Function EAN14(cCodigo)

_cRetorno := M->B5_EMB1



If MsgBox("Deseja GERAR Código de Barras para Embalagem deste Produto?","Confirme","YESNO")
	SB1->(DbSetOrder(1))
	SB1->(DbSeek(xFilial("SB1")+cCodigo,.F.))
//	alert(SB1->B1_CODBAR)
	If Substring(SB1->B1_CODBAR,1,5) <> '78970'
		If MsgBox("Este Produto ainda nao tem codigo de Barras."+CHR(13)+;
		          "Antes de gerar codigo da Embalagem é necessário gerar o codigo para o Produto."+CHR(13)+CHR(13)+;
		          "Deseja Gerar agora o Codigo para este Produto?","Confirme","YESNO")

				_Query:= "SELECT MAX(Substring(B1_CODBAR,1,12)) AS CODBAR  "
				_Query+= "FROM   " + RetSQLName("SB1") + " SB1 "
				_Query+= "WHERE SB1.D_E_L_E_T_ <> '*' "
				_Query+= "AND SB1.B1_CODBAR LIKE '78970%' "
			
				TCQUERY _Query NEW ALIAS "QRY"
			
				DBSelectArea("QRY")
				QRY->(dbGoTop())
				_nProxCodBar := Str(Val(QRY->CODBAR) + 1)
				DBSelectArea("QRY")
				DBCloseArea("QRY")
			
				_cDig := EanDigito(PADL(AllTrim(_nProxCodBar),12,"0"))
	
				MsgBox("O proximo Codigo de Barras e: "+AllTrim(_nProxCodBar)+AllTrim(_cDig),"Informacao","INFO")	
				RecLock("SB1",.F.)
				SB1->B1_CODBAR := AllTrim(_nProxCodBar)+AllTrim(_cDig)
				MsUnlock("SB1")		          
		Else
			MsgBox("Nao foi Gerado codigo para Embalagem."+CHR(13)+;
			       "E necessario gerar o codigo para o Produto antes.","Informacao","INFO")			
			Return(_cRetorno)
		Endif
	Endif
	SB1->(DbSetOrder(1))
	SB1->(DbSeek(xFilial("SB1")+cCodigo,.F.))
   _CodigoEAN14 := U_CALCEAN14(Substring(SB1->B1_CODBAR,1,12)) 

	MsgBox("O Codigo de Barras da Embalagem e: "+_CodigoEAN14,"Informacao","INFO")	
	_cRetorno := _CodigoEAN14
Else
	MsgBox("NAO foi gerado nenhum codigo de barras para a Embalagem","Informacao","INFO")			
Endif
Return(_cRetorno)


User Function CALCEAN14(_cCod)
	Local nOdd := 0
	Local nEven := 0 
	Local nI
	Local nDig  
	Local nMul := 10 
	_cEAN14 := "1"+Substr(_cCod,1,12)	
	_nSoma := 0
	_nMult:= 1
	
	
	//alert(_cCod)
	
	For nI := 1 to 13
	If (nI%2) == 0
		nEven += val(substr(_cEAN14,nI,1))
	Else
		nOdd += val(substr(_cEAN14,nI,1))
	Endif
	Next
	nDig := nEven + (nOdd*3)
	While nMul<nDig
		nMul += 10 
	Enddo
	//strzero(nMul-nDig,1)
	
	/*
	For i:= 1 to Len(AllTrim(_cEAN14))
		If _nMult == 1
			_nMult:= 3
		Else
			_nMult:= 1
		Endif
		_nSoma := _nSoma + (Val(Substr(_cEAN14,i,1)) * _nMult)
	Next
	
	//alert(_nSoma)
	If (ROUND(_nSoma,-1) - _nSoma) < 0
		_cDigEAN14 :=  Str((ROUND(_nSoma,-1)+10) - _nSoma)
		//alert("_nSoma")
	Else
		_cDigEAN14 :=  Str(NOROUND(_nSoma,-1) - _nSoma)
		//alert("_nSoma 2")
	Endif
	
	*/
	_cCodEAN14 := 	AllTrim(_cEAN14) + strzero(nMul-nDig,1) //AllTrim(_cDigEAN14)
	
	//alert(_cCodEAN14)
Return(_cCodEAN14)

