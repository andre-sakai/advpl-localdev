#include 'protheus.ch'
#include 'parmtype.ch'
#include "Fileio.ch"

user function CEKA001(_cCodigo)
	
Local _cLinha := ''
Local _cPais := ''
Local _cModelo := ''
Local _cGrupo := ''
Local _cSeq := '' 	
Local _cDv := ''
Local _cEAN := '', _nTot :=0, _nTot2 :=0
Local _nI, _nJ 	
Local nHandle
Local _lGvTodos := nil

Local _lCodn := .f.

Default _cCodigo := ''

If(Select("SX2")=0)
	RpcSetType(3)          
	RpcSetEnv("01" ,"0101", "","","","",{"SB1","SBM"})   	    	  
	_lPrepEnv := .T.
EndIf


nHandle := FCREATE("C:\ETIQUETA\LISTA_CODBAR2_"+DTOS(DATE())+'_'+STRTRAN(STRTRAN(TIME(),':','')," ","")+".txt")


If nHandle = -1
	msgalert("Erro ao criar arquivo - ferror " + Str(Ferror()))
	return
EndIf

	dbselectarea('ZB1')
	ZB1->(DBSETORDER(1))
	Count to _nI
	
	ZB1->(DBgotop())
	IF(_nI > 0)
		_lGvTodos := .F.
		conout(CVALTOCHAR(_nI)+' - .F. - 44')
	Else
		conout(CVALTOCHAR(_nI)+' - .T. - 46')
		_lGvTodos := .T.
	ENDIF


	DBSELECTAREA('SB1')
	SB1->(DBSETORDER(1))
	set filter to &("@ B1_TIPO='PA' "+IIF(!Empty(alltrim(_cCodigo)),"AND B1_COD = '"+_cCodigo+"' ",''))
	SB1->(DBGOTOP())
	
	FWrite(nHandle, 'DESCRICAO;CODIGO;GRUPO;CODBAR;CODBARCEK;CODBARNOVO' + CRLF)
	While(!SB1->(Eof()))
		
		_cLinha := ALLTRIM(SB1->B1_DESC)+';'
		_cLinha += ALLTRIM(SB1->B1_COD)+';'
		_cLinha += ALLTRIM(SB1->B1_GRUPO)+';'
		_cLinha += ALLTRIM(SB1->B1_CODBAR)+';'
		_cLinha += ALLTRIM(SB1->B1_CODBAR2)+';'
		
		IF(EMPTY(SB1->B1_CODBAR2) .OR. _lGvTodos)

			_cPais := '789'
			_nJ := 0
			_cModelo := ''
			_lCodn := .f.
			For _nI := 1 to Len(alltrim(SB1->B1_COD))
				If(substr(SB1->B1_COD,_nI,1) = ' ')
					exit
				ElseIf(substr(SB1->B1_COD,_nI,1) $ '0123456789')
					_nJ++
					If(_nJ <= 4)
						_cModelo += substr(SB1->B1_COD,_nI,1)
						
					Endif
					_lCodn :=.t.
				Else
					If(_lcodn)
						Exit
					EndIf
				EndIf
			Next
			
			_cModelo := strzero(val(_cModelo),3)
			If len(_cModelo) = 3
				If(_cModelo='***')
					_cModelo := '999'
				EndIf
			EndIf
				
			_cGrupo := strzero(val(SB1->B1_GRUPO),2)
						
			If(ZB1->(DBSEEK(xFilial('ZB1')+_cPais+_cModelo+_cGrupo)))
				RecLock('ZB1',.F.)
					_cSeq := soma1(ZB1->ZB1_SEQ)
					ZB1->ZB1_SEQ := _cSeq
				ZB1->(MSUNLOCK())
			Else
				Reclock('ZB1',.T.)
					_cSeq := '0001'
					ZB1->ZB1_FILIAL := xFilial('ZB1')
					ZB1->ZB1_PAIS 	:= _cPais
					ZB1->ZB1_MODELO := _cModelo
					ZB1->ZB1_GRUPO 	:= _cGrupo
					ZB1->ZB1_SEQ 	:= _cSeq
				ZB1->(MSUNLOCK())
			EndIf
				
			_cEAN := _cPais+ _cModelo+ _cGrupo+ _cSeq
	
	/*/
	Somando o resultado das multiplicações encontra-se o total de 73.
	O valor total da soma das multiplicações deve ser dividido por 10: (73/10 = 7.3)
	Transforme o resultado em inteiro, "arredondando" o número para baixo. (7)
	Some 1 ao resultado da divisão:  (7+1 = 8)
	Multiplique o resultado dessa soma por 10: (8*10 = 80)
	Subtraia desse resultado o valor da soma inicial das multiplicações "73": (80 - 73 = 7)
	Portanto, o digito verificador é 7. Dessa forma, o código completo é: 7891000315507.
	Se o resultado for um múltiplo de 10, o dígito verificador será 0.			
	/*/			
			//Calculo DV  EAN
			_nTot :=0
			FOR _nI := 1 to 12
				IF(Mod( _nI, 2) = 1)
					_nTot += val(substr(_cEAN,_nI,1))*1
				Else
					_nTot += val(substr(_cEAN,_nI,1))*3
				EndIf
			NEXT
			_nTot2 := ((int(_nTot/10)+1)*10) - _nTot 
			
			_cDV := substr(alltrim(cvaltochar(_nTot2)),-1,1)
			_cEAN += _cDV
			
			conout('139 produto: '+SB1->B1_COD+' - '+CVALTOCHAR(_lGvTodos)+' - '+_cEAN)
			RecLock('SB1',.F.)
				SB1->B1_CODBAR2 := _cEAN
			SB1->(MSUNLOCK())
		Else
			_cEAN := SUBSTR(SB1->B1_CODBAR2,1,13)
		endif	
			
		_cLinha += _cEAN+';'
		FWrite(nHandle, _cLinha + CRLF)
		
		
		
		SB1->(DBSKIP())
	ENDDO
	
	
    FClose(nHandle)
return


USER FUNCTION CEKA001C()
Local _cLinha := ''
Local nHandle

If(Select("SX2")=0)
	RpcSetType(3)          
	RpcSetEnv("01" ,"0101", "","","","",{"SB1","SBM"})   	    	  
	_lPrepEnv := .T.
EndIf


nHandle := FCREATE("C:\ETIQUETA\CLIENTES_"+DTOS(DATE())+'_'+STRTRAN(STRTRAN(TIME(),':','')," ","")+".txt")


If nHandle = -1
	msgalert("Erro ao criar arquivo - ferror " + Str(Ferror()))
	return
EndIf


	DBSELECTAREA('SA1')
	SA1->(DBSETORDER(1))
	set filter to 
	SA1->(DBGOTOP())
	
	_cLinha := 'A1_COD;A1_LOJA;A1_NOME;A1_NREDUZ;A1_VEND;A3_NOME;' 
	FWrite(nHandle, _cLinha + CRLF)
		
	
	WHILE (SA1->(!EOF()))
	
		_cLinha := "'"+alltrim(SA1->A1_COD)+';'
		_cLinha += "'"+alltrim(SA1->A1_LOJA)+';'
		_cLinha += "'"+alltrim(SA1->A1_NOME)+';'
		_cLinha += "'"+alltrim(SA1->A1_NREDUZ)+';'
		_cLinha += "'"+alltrim(SA1->A1_VEND)+';'
		_cLinha += "'"+alltrim(POSICIONE('SA3',1,XFILIAL('SA3')+SA1->A1_VEND,'A3_NOME'))+';'
		
		FWrite(nHandle, _cLinha + CRLF)
		SA1->(DBSKIP())		
	ENDDO


    FClose(nHandle)

RETURN

