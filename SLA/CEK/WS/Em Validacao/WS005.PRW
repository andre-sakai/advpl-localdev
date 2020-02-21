#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

WSRESTFUL WS005 DESCRIPTION "Cadastro de Condicao de Pagamento"

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta de Condicao de Pagamento" WSSYNTAX "/rest/WS005 || /rest/WS005/{cod}"


END WSRESTFUL

WSMETHOD GET WSSERVICE WS005

Local _aValid := {}
Local _cVldTkn := ''//ALLTRIM(GETMV('MV_TKNREST',.T.,'123456'))
Local _lRet := .F.
Local _cCod := ''
Local _nI,_nJ,_nReg
Local _cAlias1 := 'SE4'
Local _CFILTRO := ''

Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv('01','0101', "","","","",{"SA1","SA2","SA3","SA4"}) 
	_lPrepEnv := .T.
EndIf

// define o tipo de retorno do método
::SetContentType("application/json")
//::SetContentType("application/html")

_cVldTkn := ALLTRIM(GETMV('MV_TKNREST',.T.,'123456'))

If(!ALLTRIM(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verifique a chave!')
	Return _lRet
Else

//	CONOUT('PTOKEN',SELF:PTOKEN)
//	CONOUT('TOKEN',_cVldTkn)

EndIf
_cAlias1 := 'SE4'
_aValid := U_WSCAMPOS(SELF:CTIPO,'SE4')

// verifica se recebeu parametro pela URL
// exemplo: http://localhost:8080/sample/1
If Len(::aURLParms) > 0
	// insira aqui o código para pesquisa do parametro recebido
	// consulta de cliente por documento
	_cCod := padr(::aURLParms[1],tamsx3('E4_CODIGO')[1])
	
	If(Empty(_cCod))
		::SetResponse('{"ID":401,"Erro":"Codigo nao informado!"}')
		SetRestFault(499,'Documento nao informado, verifique as informações enviadas!')
		Return _lRet
	EndIf
   
	DBSelectArea(_cAlias1)
	(_cAlias1)->(DBSetOrder(1))
	(_cAlias1)->(DBGoTop())
	If((_cAlias1)->(DBSeek(xFilial(_cAlias1)+_cCod)))
		::SetResponse('{"REGISTROS":[')
		_nI := 1
		
		::SetResponse('{')
		For _nI := 1 to len(_aValid)
			If(_aValid[_nI,3]=='C')
				::SetResponse('"'+_aValid[_nI,1]+'":"'+alltrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
			ElseIf(_aValid[_nI,3]=='M')
				::SetResponse('"'+_aValid[_nI,1]+'":"'+alltrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
			ElseIf(_aValid[_nI,3]=='O')
				//não tratado - somente para compatibilidade com outras funções
			ElseIf(_aValid[_nI,3]=='L')
				::SetResponse('"'+_aValid[_nI,1]+'":'+alltrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))			
			ElseIf(_aValid[_nI,3]=='D')
				::SetResponse('"'+_aValid[_nI,1]+'":"'+dtos(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))			
			ElseIf(_aValid[_nI,3]=='N')
				::SetResponse('"'+_aValid[_nI,1]+'":'+alltrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
			EndIf
			
		Next
		::SetResponse('}')
		::SetResponse("]")
		
		::SetResponse(', "QUANTIDADE":'+CVALTOCHAR(1))
		::SetResponse(', "PAGINA":'+CVALTOCHAR(SELF:NPAGINA))
		::SetResponse(', "DICIONARIO":[')
		For _nI := 1 to len(_aValid)
			If(_nI != 1)
				::SetResponse(",")
			EndIf
			::SetResponse("{")
			::SetResponse('"CAMPO":"'+_aValid[_nI,1]+'",')
			::SetResponse('"TIPO":"'+_aValid[_nI,3]+'",')
			::SetResponse('"TAM":'+CVALTOCHAR(_aValid[_nI,4])+',')
			If(LEN(_aValid[_nI])>=7)
				::SetResponse('"DESCRICAO":"'+CVALTOCHAR(_aValid[_nI,7])+'"')
			EndIf
			If(!Empty(_aValid[_nI,6]))
				::SetResponse(', "OPCOES":"'+_aValid[_nI,6]+'"')
			EndIf
			::SetResponse("}")
		Next
		::SetResponse("]")// FIM DO ARRAY DE DICIONARIO
		::SetResponse('}') //FIM DO RETORNO
				
		_lRet := .T.
	Else
		::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado!"}')
		SetRestFault(402,'Nenhum cadastro encontrado! verifique as informações enviadas!')		
		Return _lRet
	EndIf
Else

	::SetResponse('{"REGISTROS":[')
	_nI := 1	
	_nJ := 1	
	While(!(_cAlias1)->(EOF()))
		If(_nJ >= ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO ) .AND. _nJ <= (SELF:NPAGINA * SELF:NREGISTRO ))
			If(_lRet)
				::SetResponse(',')
			EndIf
			::SetResponse('{')
			For _nI := 1 to len(_aValid)
				If(_aValid[_nI,3]=='C')
					::SetResponse('"'+_aValid[_nI,1]+'":"'+alltrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
				ElseIf(_aValid[_nI,3]=='M')
					::SetResponse('"'+_aValid[_nI,1]+'":"'+alltrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
				ElseIf(_aValid[_nI,3]=='O')
					//não tratado - somente para compatibilidade com outras funções
				ElseIf(_aValid[_nI,3]=='L')
					::SetResponse('"'+_aValid[_nI,1]+'":'+alltrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))			
				ElseIf(_aValid[_nI,3]=='D')
					::SetResponse('"'+_aValid[_nI,1]+'":"'+dtos(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))			
				ElseIf(_aValid[_nI,3]=='N')
					::SetResponse('"'+_aValid[_nI,1]+'":'+alltrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
				EndIf
			Next
			::SetResponse('}')
			_lRet := .T.
		EndIf	
		_nJ++		
		(_cAlias1)->(DBSKIP())
	EndDo
	::SetResponse(']')
	::SetResponse(', "QUANTIDADE":'+CVALTOCHAR(_nReg))
	::SetResponse(', "PAGINA":'+CVALTOCHAR(SELF:NPAGINA))
	::SetResponse(', "DICIONARIO":[')
	For _nI := 1 to len(_aValid)
		If(_nI != 1)
			::SetResponse(",")
		EndIf
		::SetResponse("{")
		::SetResponse('"CAMPO":"'+_aValid[_nI,1]+'",')
		::SetResponse('"TIPO":"'+_aValid[_nI,3]+'",')
		::SetResponse('"TAM":'+CVALTOCHAR(_aValid[_nI,4])+',')
		::SetResponse('"DESCRICAO":"'+_aValid[_nI,7]+'"')
		If(!Empty(_aValid[_nI,6]))
			::SetResponse(', "OPCOES":"'+_aValid[_nI,6]+'"')
		EndIf
		::SetResponse("}")
	Next
	::SetResponse(']') // FIM DO ARRAY DE DICIONARIO
	::SetResponse('}') //FIM DO RETORNO
	
	dbselectarea(_cAlias1)
	SET FILTER TO
	
EndIf

If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return .T.
 
 