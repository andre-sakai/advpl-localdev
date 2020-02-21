#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

WSRESTFUL WS103 DESCRIPTION "Codigo de Barras"

WSDATA PTOKEN AS STRING OPTIONAL

WSMETHOD GET DESCRIPTION "gera codbar2" WSSYNTAX "/rest/WS103 || /rest/WS103/{CODPRO}"
WSMETHOD POST DESCRIPTION "ATT CLIENTE" WSSYNTAX "/rest/WS103 || /rest/WS103/{CODPRO}"

END WSRESTFUL 

WSMETHOD GET WSSERVICE WS103

Local _aValid := {}
Local _nI := 0, _nJ := 0
Local _cPais, _cModelo, _cGrupo, _cSeq, _cDV
LOCAL _lPrepEnv := .F.
Local _cCod := ''
Local _cEAN := ''
Local _nTot := 0

If(Select("SX2")=0)
	RpcSetType(3)          
	RpcSetEnv("01" ,"0101", "","","","",{"SB1","SBM"})   	    	  
	_lPrepEnv := .T.
EndIf

// define o tipo de retorno do método
::SetContentType("PLAIN/TEXT")

  
// verifica se recebeu parametro pela URL
// exemplo: http://localhost:8080/sample/1
If Len(::aURLParms) > 0
	// insira aqui o código para pesquisa do parametro recebido
	// exemplo de retorno de um objeto JSON
   
    DBSELECTAREA('ZB1')
	DBSETORDER(1)
	
	DBSELECTAREA('SB1')
	DBSETORDER(1)
	set filter to &("@ B1_TIPO='PA'")
	DBGOTOP()
		::SetResponse("DESCRICAO;CODIGO;GRUPO;CODBAR;CODBARCEK;CODBARNOVO")
		::SetResponse(CRLF)
		
		_cCod := ::aURLParms[1]
		_cCod := padr(_cCod,tamsx3('B1_COD')[1])
		
	If(DBSEEK(XFilial('SB1')+_cCod))
		
			::SetResponse(''+ALLTRIM(SB1->B1_DESC)+';')
			::SetResponse(''+ALLTRIM(SB1->B1_COD)+';')
			::SetResponse(''+ALLTRIM(SB1->B1_GRUPO)+';')
			::SetResponse(''"+ALLTRIM(SB1->B1_CODBAR)+''+';')
			::SetResponse(''+ALLTRIM(SB1->B1_CODBAR2)+''+';')
			
			_cPais := '789'
			_nJ := 0
			_cModelo := ''
			_lcodn :=.f.
			FOR _nI := 1 to tamsx3('B1_COD')[1]
				conout(_nI)
				IF(substr(SB1->B1_COD,_nI,1) = ' ')
					exit
				ELSEif(substr(SB1->B1_COD,_nI,1) $ '0123456789')
					_nJ++
					IF(_nJ <= 4)
						_cModelo += substr(SB1->B1_COD,_nI,1)
						
					endif
					_lcodn :=.t.
				else
					if(_lcodn)
						exit
					endif
				endif
			NEXT
			_cModelo := strzero(val(_cModelo),3)
			if len(_cModelo) = 3
				if(_cModelo='***')
					_cModelo := '999'
				endif
			endif
			
			_cGrupo := strzero(val(SB1->B1_GRUPO),2)
			
			IF(ZB1->(DBSEEK(xFilial('ZB1')+_cPais+_cModelo+_cGrupo)))
				reclock('ZB1',.F.)
					_cSeq := soma1(ZB1->ZB1_SEQ)
					ZB1->ZB1_SEQ := _cSeq
				ZB1->(MSUNLOCK())
			Else
				reclock('ZB1',.T.)
					_cSeq := '0001'
					ZB1->ZB1_FILIAL := xFilial('ZB1')
					ZB1->ZB1_PAIS 	:= _cPais
					ZB1->ZB1_MODELO := _cModelo
					ZB1->ZB1_GRUPO 	:= _cGrupo
					ZB1->ZB1_SEQ 	:= _cSeq
				ZB1->(MSUNLOCK())
			EndIf
			
			_cDV:='0'
			
			::SetResponse(''+_cPais+ _cModelo+ _cGrupo+ _cSeq+ _cDV+';')
			::SetResponse(CRLF)
		
		
	EndIf
Else
	// as propriedades da classe receberão os valores enviados por querystring
	// exemplo: http://localhost:8080/sample?startIndex=1&count=10
	
	
	// exemplo de retorno de uma lista de objetos JSON	
    DBSELECTAREA('ZB1')
	DBSETORDER(1)
	
	DBSELECTAREA('SB1')
	DBSETORDER(1)
	set filter to B1_TIPO='PA'
	DBGOTOP()
		::SetResponse('DESCRICAO;CODIGO;GRUPO;CODBAR;CODBARCEK;CODBARNOVO')
		::SetResponse(CRLF)
		
	WHILE(!SB1->(EOF()))
		
			::SetResponse(''+ALLTRIM(SB1->B1_DESC)+';')
			::SetResponse(''+ALLTRIM(SB1->B1_COD)+';')
			::SetResponse(''+ALLTRIM(SB1->B1_GRUPO)+';')
			::SetResponse(''+ALLTRIM(SB1->B1_CODBAR)+''+';')
			::SetResponse(''+ALLTRIM(SB1->B1_CODBAR2)+''+';')
			_cPais := '789'
			_nJ := 0
			_cModelo := ''
			_lcodn := .f.
			FOR _nI := 1 to LEN(alltrim(SB1->B1_COD))
				IF(substr(SB1->B1_COD,_nI,1) = ' ')
					exit
				ELSEif(substr(SB1->B1_COD,_nI,1) $ '0123456789')
					_nJ++
					IF(_nJ <= 4)
						_cModelo += substr(SB1->B1_COD,_nI,1)
						
					endif
					_lcodn :=.t.
				else
					if(_lcodn)
						exit
					endif
				endif
			NEXT
			_cModelo := strzero(val(_cModelo),3)
			if len(_cModelo) = 3
				if(_cModelo='***')
					_cModelo := '999'
				endif
			endif
			
			_cGrupo := strzero(val(SB1->B1_GRUPO),2)
			
			IF(ZB1->(DBSEEK(xFilial('ZB1')+_cPais+_cModelo+_cGrupo)))
				reclock('ZB1',.F.)
					_cSeq := soma1(ZB1->ZB1_SEQ)
					ZB1->ZB1_SEQ := _cSeq
				ZB1->(MSUNLOCK())
			Else
				reclock('ZB1',.T.)
					_cSeq := '0001'
					ZB1->ZB1_FILIAL := xFilial('ZB1')
					ZB1->ZB1_PAIS 	:= _cPais
					ZB1->ZB1_MODELO := _cModelo
					ZB1->ZB1_GRUPO 	:= _cGrupo
					ZB1->ZB1_SEQ 	:= _cSeq
				ZB1->(MSUNLOCK())
			EndIf
			
			_cEAN := _cPais+ _cModelo+ _cGrupo+ _cSeq
			//Validação EAN
			//Adicione todos os dígitos das posições ímpares (dígitos na posição 1, 3, 5, 7, 9 e 11)
			//Multiplique por 3.
			//Adicione todos os dígitos das posições pares (dígitos na posição 2, 4, 6, 8 e 10).
			//Some os resultados das etapas 3 e 2.
			//Determine o número que deve ser adicionado ao resultado do passo 4 para criar um múltiplo de 10.			
			
			//Calculo DV  EAN
			_nTot :=0
			FOR _nI := 1 to 12
				IF(Mod( _nI, 2) = 1)
					_nTot += val(substr(_cEAN,_nI,1))*3
				Else
					_nTot += val(substr(_cEAN,_nI,1))
				EndIf
			NEXT
			
			_cDV := 10 - Mod( _nTot, 10)
			
			::SetResponse(''+_cPais+ _cModelo+ _cGrupo+ _cSeq+ _cDV+';')
		
		SB1->(DBSKIP())
		IF(!SB1->(EOF()))
			::SetResponse(CRLF)
		ENDIF
	ENDDO
	
EndIf


If(_lPrepEnv)
	RpcClearEnv()   
EndIf


Return .T.

