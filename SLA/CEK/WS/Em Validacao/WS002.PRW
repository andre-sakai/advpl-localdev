#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

WSRESTFUL WS002 DESCRIPTION "Cadastro de Clientes 2"

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta de Clientes" WSSYNTAX "/rest/WS002 || /rest/WS002/{doc}"
WSMETHOD POST DESCRIPTION "Inclusão de Clientes" WSSYNTAX "/rest/WS002"
//WSMETHOD PUT DESCRIPTION "Alteração de Clientes" WSSYNTAX "/rest/WS002/{id}"
//WSMETHOD DELETE DESCRIPTION "Exclusão de entidade" WSSYNTAX "/sample/{id}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS002

//Local _aValid := {}
Local _cVldTkn := ''
Local _lRet := .F.
Local _cDoc := ''
Local _cFiltro := ''
Local _nI := 0
Local _nReg := 0
Local _lPrepEnv := .F.

Private _aValid := {}

Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''
Default SELF:CTESTE 	:=''

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv('01','0101', "","","","",{"SA1","SA2","SA3","SA4"}) 
	_lPrepEnv := .T.
EndIf


// define o tipo de retorno do método
::SetContentType("application/json")

_cVldTkn := AllTrim(GETMV('MV_TKNREST',.T.,'123456'))
_cFiltro := SELF:cFiltro

If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verifique a chave!')
	Return _lRet
Else

//	CONOUT('PTOKEN',SELF:PTOKEN)
//	CONOUT('TOKEN',_cVldTkn)

EndIf

_aValid := U_WSCAMPOS(SELF:CTIPO,'SA1')

// verifica se recebeu parametro pela URL
// exemplo: http://localhost:8080/sample/1
If Len(::aURLParms) > 0
	// insira aqui o código para pesquisa do parametro recebido
	// consulta de cliente por documento
	_cDoc := padr(::aURLParms[1],tamsx3('A1_CGC')[1],' ')
	
	If(Empty(_cDoc))
		::SetResponse('["ID":401,"Erro":"Documento nao informado!"]')
		SetRestFault(499,'Documento nao informado, verifique as informações enviadas!')
		Return _lRet
	EndIf
   
	DBSelectArea('SA1')
	SA1->(DBSetOrder(3))
	
	_xFiltro := ''	
	If(Len(AllTrim(_cDoc))>8)
		SET FILTER TO &("@  A1_CGC='"+_cDoc+"' " +IIF(!EMPTY(_cFiltro),' AND '+_cFiltro,''))
		_xFiltro := "@  A1_CGC='"+_cDoc+"' " +IIF(!EMPTY(_cFiltro),' AND '+_cFiltro,'')
	ElseIf(Len(AllTrim(_cDoc))=8)
		SET FILTER TO &("@  SUBSTRING(A1_CGC,1,8)='"+AllTrim(_cDoc)+"' AND LENGTH(RTRIM(CGC))=14 " +IIF(!EMPTY(_cFiltro),' AND '+_cFiltro,''))
		_xFiltro := "@  SUBSTRING(A1_CGC,1,8)='"+AllTrim(_cDoc)+"' AND LENGTH(RTRIM(CGC))=14 " +IIF(!EMPTY(_cFiltro),' AND '+_cFiltro,'')
	EndIf
	
	SA1->(DBGoTop())
	count to _nReg 
	SA1->(DBGoTop())
	
	If(!SA1->(EOF()))
		::SetResponse('{"REGISTROS":[')
		_nJ := 1
		While(SA1->(!Eof()))
			IF(_nJ >= ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO ) .AND. _nJ <= (SELF:NPAGINA * SELF:NREGISTRO ))
				
				If(_lRet)
					::SetResponse(',')			
				EndIf
				::SetResponse('{')
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+alltrim(noacento(&(_aValid[_nI,5])))+'"'+iif(_nI<len(_aValid),',',''))
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
			Else
				
			EndIf
			
			_nJ++
			SA1->(DBSkip())
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
			IF(!EMPTY(_aValid[_nI,6]))
				::SetResponse(', "OPCOES":"'+_aValid[_nI,6]+'"')
			ENDIF
			::SetResponse("}")
		Next
		::SetResponse(']') // FIM DO ARRAY DE DICIONARIO
		::SetResponse(']') //FIM DO RETORNO
	Else
		::SetResponse('["ID":402,"Erro":"Nenhum cadastro encontrado ('+_cDoc+')!"]')
		SetRestFault(402,'Nenhum cadastro encontrado, verifique as informações enviadas!')
		
	EndIf
	
	dbselectarea('SA1')
	SET FILTER TO
	
Else

	DBSelectArea('SA1')
	SA1->(DBSetOrder(1))

	SA1->(DBGoTop())
	IF(!EMPTY(_cFiltro))
		SET FILTER TO &("@ "+_cFiltro)
	ENDIF
	SA1->(DBGoTop())
	count to _nReg 
	SA1->(DBGoTop())
	
	::SetResponse('["REGISTROS":[')
	_nI := 1	
	_nJ := 1	
	While(!SA1->(EOF()))
		If(_nJ >= ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO ) .AND. _nJ <= (SELF:NPAGINA * SELF:NREGISTRO ))
			If(_lRet)
				::SetResponse(',')
			EndIf
			::SetResponse('{')
			For _nI := 1 to len(_aValid)
				If(_aValid[_nI,3]=='C')
					::SetResponse('"'+_aValid[_nI,1]+'":"'+alltrim(noacento(&(_aValid[_nI,5])))+'"'+iif(_nI<len(_aValid),',',''))
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
		SA1->(DBSKIP())
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
	::SetResponse(']') //FIM DO RETORNO
	
	dbselectarea('SA1')
	SET FILTER TO
	
EndIf


If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return .T.
 
 
WSMETHOD POST WSSERVICE WS002
Local _lRet := .T.
Local _nI := 0, _nJ := 0
//Local _nMaxReg := 30
Local _oModel
Local _cContent := ''
Local _aRetError := {}
Local _aValid := {}
Local _cVldTkn := ''
Local _xAlias1 := getnextalias()
Local _lPrepEnv := .F.

Private _oBody


Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''
Default SELF:CTESTE 	:=''

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv('01','0101', "","","","",{"SA1","SA2","SA3","SA4"}) 
	_lPrepEnv := .T.
EndIf

_cVldTkn := AllTrim(GETMV('MV_TKNREST',.T.,'123456'))

If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verifique a chave!')
	Return .F.
Else
	//conout('','Token Ok')
EndIf

_cContent  := SELF:GetContent()
FWJsonDeserialize(_cContent,@_oBody)

If (SELF:CTESTE = "SIM")
	::SetResponse(VARINFO('Body',_oBody,,.F.))
	Return .T.
EndIf

_nI := 1
While(Type('_oBody')='U' .and. _nI < 5)
	FWJsonDeserialize(_cContent,@_oBody)
	_nI++
	If(type('_oBody')!='U')
		EXIT
	EndIf
EndDo

_aValid := U_WSCAMPOS(SELF:CTIPO,'SA1')

If(Type('_oBody')== 'O')

	_oClient := _oBody

	For _nI := 1 to Len (_aValid) 				
	If (type('_oClient:'+_aValid[_nI][1])=="U" .AND. _aValid[_nI][2]==.T.)
			aAdd(_aRetError,{'500','Campo '+_aValid[_nI][1]+' nao foi declarado'})
		Else
			If(type('_oClient:'+_aValid[_nI][1])!=_aValid[_nI][3] .AND. type('_oClient:'+_aValid[_nI][1])<>"U")
				aAdd(_aRetError,{'500','Campo '+_aValid[_nI][1]+' com Tipo: '+type('_oClient:'+_aValid[_nI][1])+' - Esperado: '+_aValid[_nI][3]})
			EndIf
		EndIf
	
	Next _nI

	::SetResponse('["MENSAGEM":[')
	If (Len(_aRetError) = 0)
		_oModel := FWLoadModel("MATA030")
		_cModel := "MATA030_SA1"
		
		If(Type('_oClient:CODIGO')<>'U' .and. Type('_oClient:LOJA')<>'U')
			SA1->(DBSetOrder(1))
			If(!SA1->(MsSeek(xFilial("SA1")+AllTrim(_oClient:CODIGO)+AllTrim(_oClient:LOJA),.T.)))
				_oModel:SetOperation(MODEL_OPERATION_INSERT)
			Else
				_oModel:SetOperation(MODEL_OPERATION_UPDATE)
			EndIf

			_oModel:Activate()	
			_oModel:SetValue(_cModel,"A1_COD",_oClient:Codigo)
			_oModel:SetValue(_cModel,"A1_LOJA",_oClient:Loja)
		ElseIf(Type('_oClient:CODIGO')<>'U' .and. Type('_oClient:LOJA')=='U')
		
			If(Select(_xAlias1)!=0)
				(_xAlias1)->(DbCloseArea())
			EndIf
			
			BeginSQL ALIAS _xAlias1
				SELECT MAX(A1_LOJA) LOJA 
				FROM %TABLE:SA1% SA1 
				WHERE A1_FILIAL=%EXP:FWFILIAL('SA1')% AND A1_COD=%EXP:_oClient:CODIGO% AND SA1.%NOTDEL%
			EndSQL
			
			If(!(_xAlias1)->(Eof()))
				_cCodLoja := soma1((_xAlias1)->LOJA)
			Else
				_cCodLoja := STRZERO(1,tamsx3('A1_LOJA')[1])
			EndIf
			
			(_xAlias1)->(DbCloseArea())
			
			_oModel:SetOperation(MODEL_OPERATION_INSERT)
			_oModel:Activate()
			_oModel:SetValue(_cModel,"A1_COD",_oClient:Codigo)	
			_oModel:SetValue(_cModel,"A1_LOJA",_cCodLoja)	
		Else
			_oModel:SetOperation(MODEL_OPERATION_INSERT)
			_oModel:Activate()
			_oModel:SetValue(_cModel,"A1_COD",GETSXENUM('SA1','A1_COD'))	
			_oModel:SetValue(_cModel,"A1_LOJA","01")	
		EndIf
		
		_nI := 1
		For _nI := 1 to Len(_aValid)
			If(Type('_oClient:'+_aValid[_nI][1])!='U' .and. ! ALLTRIM(_aValid[_nI][5]) $ 'A1_COD#A1_LOJA#')
				_oModel:SetValue(_cModel,_aValid[_nI][5],&('_oClient:'+_aValid[_nI][1]))
			EndIf				
		Next
	
		If _oModel:VldData()		
			_oModel:CommitData()	
			_cContent := '{"CADASTRO REALIZADO"}'
		Else	
			_cContent := '{"ERRO":"'
			_cContent += _oModel:GetErrorMessage()[6]
			_cContent += '"}'
		EndIf	
			
		_oModel:DeActivate()
		_oModel:Destroy()
		_oModel:= nil
		
		::SetResponse(_cContent)
	Else
		If(Len(_aRetError)>0)
			Return {.f.,500,U_WS002RET(_aRetError)}
		EndIf
		
	EndIf
	::SetResponse("]")
	
ElseIf(type('_oBody')== 'A')
	For _nJ :=1 to Len(_oBody)
		_oClient := _oBody[_nJ]
		
		For _nI := 1 to Len (_aValid) 				
			If (type('_oClient:'+_aValid[_nI][1])=="U" .AND. _aValid[_nI][2]==.T.)
				aAdd(_aRetError,{'500','Campo '+_aValid[_nI][1]+' nao foi declarado'})
			Else
				If(type('_oClient:'+_aValid[_nI][1])!=_aValid[_nI][3] .AND. type('_oClient:'+_aValid[_nI][1])<>"U")
					aAdd(_aRetError,{'500','Campo '+_aValid[_nI][1]+' com Tipo: '+type('_oClient:'+_aValid[_nI][1])+' - Esperado: '+_aValid[_nI][3]})
				EndIf
			EndIf
		
		Next _nI

		::SetResponse('["MENSAGEM":[')
		If (Len(_aRetError) = 0)
			_oModel := FWLoadModel("MATA030")
			_cModel := "MATA030_SA1"
			
			If(Type('_oClient:CODIGO')<>'U' .and. Type('_oClient:LOJA')<>'U')
				SA1->(DBSetOrder(1))
				If(!SA1->(MsSeek(xFilial("SA1")+AllTrim(_oClient:CODIGO)+AllTrim(_oClient:LOJA),.T.)))
					_oModel:SetOperation(MODEL_OPERATION_INSERT)
				Else
					_oModel:SetOperation(MODEL_OPERATION_UPDATE)
				EndIf

				_oModel:Activate()	
				_oModel:SetValue(_cModel,"A1_COD",_oClient:Codigo)
				_oModel:SetValue(_cModel,"A1_LOJA",_oClient:Loja)
			ElseIf(Type('_oClient:CODIGO')<>'U' .and. Type('_oClient:LOJA')=='U')
			
				If(Select(_xAlias1)!=0)
					(_xAlias1)->(DbCloseArea())
				EndIf
				
				BeginSQL ALIAS _xAlias1
					SELECT MAX(A1_LOJA) LOJA 
					FROM %TABLE:SA1% SA1 
					WHERE A1_FILIAL=%EXP:FWFILIAL('SA1')% AND A1_COD=%EXP:_oClient:CODIGO% AND SA1.%NOTDEL%
				EndSQL
				
				If(!(_xAlias1)->(Eof()))
					_cCodLoja := soma1((_xAlias1)->LOJA)
				Else
					_cCodLoja := STRZERO(1,tamsx3('A1_LOJA')[1])
				EndIf
				
				(_xAlias1)->(DbCloseArea())
				
				_oModel:SetOperation(MODEL_OPERATION_INSERT)
				_oModel:Activate()
				_oModel:SetValue(_cModel,"A1_COD",_oClient:Codigo)	
				_oModel:SetValue(_cModel,"A1_LOJA",_cCodLoja)	
			Else
				_oModel:SetOperation(MODEL_OPERATION_INSERT)
				_oModel:Activate()
				_oModel:SetValue(_cModel,"A1_COD",GETSXENUM('SA1','A1_COD'))	
				_oModel:SetValue(_cModel,"A1_LOJA","01")	
			EndIf
			
			_nI := 1
			For _nI := 1 to Len(_aValid)
				If(Type('_oClient:'+_aValid[_nI][1])!='U' .and. ! ALLTRIM(_aValid[_nI][5]) $ 'A1_COD#A1_LOJA#')
					_oModel:SetValue(_cModel,_aValid[_nI][5],&('_oClient:'+_aValid[_nI][1]))
				EndIf				
			Next
		
			If _oModel:VldData()		
				_oModel:CommitData()	
				_cContent := '{"CADASTRO REALIZADO"}'
			Else	
				_cContent := '{"ERRO":"'
				_cContent += _oModel:GetErrorMessage()[6]
				_cContent += '"}'
			EndIf	
				
			_oModel:DeActivate()
			_oModel:Destroy()
			_oModel:= nil
			
			::SetResponse(_cContent)
			If(_nJ <Len(_oBody))
				::SetResponse(',')
			EndIf	
		Else
			If(Len(_aRetError)>0)
				Return {.f.,500,U_WS002RET(_aRetError)}
			EndIf
			
		EndIf
		
	Next _nJ
	::SetResponse("]]")
EndIf

If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return _lRet

