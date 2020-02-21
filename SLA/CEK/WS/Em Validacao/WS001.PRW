#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

WSRESTFUL WS001 DESCRIPTION "Cadastro de Fornecedores"

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta de Fornecedores" WSSYNTAX "/rest/WS001 || /rest/WS001/{doc}"
WSMETHOD POST DESCRIPTION "Inclusão de Fornecedores" WSSYNTAX "/rest/WS001"
//WSMETHOD PUT DESCRIPTION "Alteração de Clientes" WSSYNTAX "/rest/WS002/{id}"
//WSMETHOD DELETE DESCRIPTION "Exclusão de entidade" WSSYNTAX "/sample/{id}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS001

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

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv('01','0101', "","","","",{"SA1","SA2","SA3","SA4"}) 
	_lPrepEnv := .T.
EndIf

// define o tipo de retorno do método
::SetContentType("application/json")

_cVldTkn := ALLTRIM(GETMV('MV_TKNREST',.T.,'123456'))
_cFiltro := SELF:cFiltro						

If(!ALLTRIM(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verifique a chave!')
	Return _lRet
Else

//	CONOUT('PTOKEN',SELF:PTOKEN)
//	CONOUT('TOKEN',_cVldTkn)

EndIf

//_aValid := U_WS002SA2(SELF:CTIPO)
_aValid := U_WSCAMPOS(SELF:CTIPO,'SA2')

// verifica se recebeu parametro pela URL
// exemplo: http://localhost:8080/sample/1
If Len(::aURLParms) > 0
	// insira aqui o código para pesquisa do parametro recebido
	// consulta de cliente por documento
	_cDoc := padr(::aURLParms[1],tamsx3('A2_CGC')[1],' ')
	
	If(Empty(_cDoc))
		::SetResponse('["ID":401,"Erro":"Documento nao informado!"]')
		SetRestFault(499,'Documento nao informado, verifique as informações enviadas!')
		Return _lRet
	EndIf
   
	DBSelectArea('SA2')
	SA2->(DBSetOrder(3))
	
	_xFiltro := ''	
	If(Len(AllTrim(_cDoc))>8)
		SET FILTER TO &("@  A2_CGC='"+_cDoc+"' " +IIF(!EMPTY(_cFiltro),' AND '+_cFiltro,''))
		_xFiltro := "@  A2_CGC='"+_cDoc+"' " +IIF(!EMPTY(_cFiltro),' AND '+_cFiltro,'')
	ElseIf(Len(AllTrim(_cDoc))=8)
		SET FILTER TO &("@  SUBSTRING(A2_CGC,1,8)='"+AllTrim(_cDoc)+"' AND LENGTH(RTRIM(CGC))=14 " +IIF(!EMPTY(_cFiltro),' AND '+_cFiltro,''))
		_xFiltro := "@  SUBSTRING(A2_CGC,1,8)='"+AllTrim(_cDoc)+"' AND LENGTH(RTRIM(CGC))=14 " +IIF(!EMPTY(_cFiltro),' AND '+_cFiltro,'')
	EndIf
	
	SA2->(DBGoTop())
	count to _nReg 
	SA2->(DBGoTop())
	
	If(!SA2->(EOF()))	
	
		::SetResponse('{"REGISTROS":[')
	
		_nJ := 1
		While(SA2->(!Eof()))
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
			Else
				
			EndIf
			
			_nJ++
			SA2->(DBSkip())
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
	::SetResponse(']')
	dbselectarea('SA2')
	SET FILTER TO		  
Else

	DBSelectArea('SA2')
	SA2->(DBSetOrder(1))

	SA2->(DBGoTop())
	If(!EMPTY(_cFiltro))
		SET FILTER TO &("@ "+_cFiltro)
	EndIf
	SA2->(DBGoTop())
	count to _nReg 
	SA2->(DBGoTop())
	
	::SetResponse('["REGISTROS":[')
	_nI := 1	
	_nJ := 1	  
	While(!SA2->(EOF()))
		If(_nJ >= ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO ) .AND. _nJ <= (SELF:NPAGINA * SELF:NREGISTRO ))																							 
			If(_lRet)
				::SetResponse(',')
				::SetResponse('{')
			EndIf
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
		SA2->(DBSKIP())
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
	
	dbselectarea('SA2')
	SET FILTER TO
EndIf


If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return .T.
 
 
WSMETHOD POST WSSERVICE WS001
Local _lRet := .T.
Local _nI := 0, _nJ := 0
//Local _nMaxReg := 30
Local _oModel
Local _cModel := 'SA2MASTER'
Local _cContent := ''
Local _aRetError := {}
Local _aValid := {}
Local _cVldTkn := ''
Local _xAlias1 := getnextalias()
Local _lPrepEnv := .F.


Private _oBody



If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv('01','0101', "","","","",{"SA1","SA2","SA3","SA4"}) 
	_lPrepEnv := .T.
EndIf

//_aRetError := u_ws001tst()

//::SetResponse('["ID":200,"msg":"'+_aRetError[2]+'"]')

//return _aRetError[1]



_cVldTkn := ALLTRIM(GETMV('MV_TKNREST',.T.,'123456'))

If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verifique a chave!')
	Return .F.
Else
	//conout('','Token Ok')
EndIf

_cContent  := SELF:GetContent()
FWJsonDeserialize(_cContent,@_oBody)

_nI := 1
While(Type('_oBody')='U' .and. _nI < 5)
	FWJsonDeserialize(_cContent,@_oBody)
	_nI++
	If(type('_oBody')!='U')
		EXIT
	EndIf
EndDo

_aValid := U_WSCAMPOS(SELF:CTIPO,'SA2')

If(Type('_oBody')== 'O')

	_oClient := _oBody

	For _nI := 1 to len (_aValid) 
		If (type('_oClient:'+_aValid[1])=="U" .AND. _aValid[2]==.T.)
			aAdd(_aRetError,{'500','Campo '+_aValid[1]+' obrigatorio!'})
		Else
			If(type('_oClient:'+_aValid[_nI][1])!=_aValid[_nI][3] .AND. type('_oClient:'+_aValid[_nI][1])<>"U")
				aAdd(_aRetError,{'500','Campo '+_aValid[1]+' com Tipo: '+type('_oClient:'+_aValid[1])+' - Esperado: '+_aValid[2]})
			EndIf
		EndIf
	
	Next _nI

	::SetResponse('["mensagem":[')
	If (Len(_aRetError) = 0)
		_oModel := FWLoadModel("MATA020")
		_cModel := "SA2MASTER"
		//varinfo('_oModel',_oModel)
		//conout('MODEL_OPERATION_INSERT',MODEL_OPERATION_INSERT)
		//conout('MODEL_OPERATION_UPDATE',MODEL_OPERATION_UPDATE)
			
		If( Type('_oClient:COD')<>'U' .AND. Type('_oClient:LOJA')<>'U')
			SA2->(DBSetOrder(1))
			If(!SA2->(MsSeek(xFilial("SA2")+ALLTRIM(_oClient:COD)+ALLTRIM(_oClient:LOJA),.T.)))
				_oModel:SetOperation(MODEL_OPERATION_INSERT)
			Else
				_oModel:SetOperation(MODEL_OPERATION_UPDATE)
			EndIf
			_oModel:Activate()	
			_oModel:SetValue(_cModel,"A2_COD",_oClient:Codigo)	
			_oModel:SetValue(_cModel,"A2_LOJA",_oClient:Loja)	
		ElseIf(Type('_oClient:COD')<>'U' .and. Type('_oClient:LOJA')=='U')
		
			If(Select(_xAlias1)!=0)
				(_xAlias1)->(DbCloseArea())
			EndIf
			
			BeginSQL ALIAS _xAlias1
				SELECT MAX(A2_LOJA) LOJA 
				FROM %TABLE:SA2% SA2 
				WHERE A2_FILIAL=%EXP:FWFILIAL('SA2')% A2_COD=%EXP:_oClient:LOJA% AND SA2.%NOTDEL%
			EndSQL
			
			If(!(_xAlias1)->(EOF()))
				_cCodLoja := soma1((_xAlias1)->LOJA)
			Else
				_cCodLoja := STRZERO(1,tamsx3('A2_LOJA')[1])
			EndIf
			
			(_xAlias1)->(DbCloseArea())
			
			_oModel:SetOperation(MODEL_OPERATION_INSERT)
			_oModel:Activate()
			_oModel:SetValue(_cModel,"A2_COD",_oClient:Cod)	
			_oModel:SetValue(_cModel,"A2_LOJA",_cCodLoja)	
		Else
			_oModel:SetOperation(MODEL_OPERATION_INSERT)
			_oModel:Activate()
			_oModel:SetValue(_cModel,"A2_COD",GETSXENUM('SA2','A2_COD'))	
			_oModel:SetValue(_cModel,"A2_LOJA","01")	
		EndIf
			
		_nI := 3
		For _nI := 1 to Len(_aValid)
			If(Type('_oClient:'+_aValid[_nI][1])!='U' .and. !(_aValid[_nI][1] $ 'A2_COD#A2_LOJA'))
				_oModel:SetValue(_cModel,_aValid[_nI][5],&('_oClient:'+_aValid[_nI][1]))
			EndIf				
		Next
		CONOUT('ANTES DA VALIDAÇÃO')
		If _oModel:VldData()		
			_oModel:CommitData()	
			_cContent := '{"Cadastro realizado"}'
		Else	
			_cContent := '{"Erro":"'
			_cContent += _oModel:GetErrorMessage()[6]
			_cContent += '"}'
			VarInfo("ERRO["+CVALTOCHAR(_nJ)+"]",_oModel:GetErrorMessage())	
		EndIf	
				
		_oModel:DeActivate()		
			
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

		::SetResponse('["mensagem":[')
		If (Len(_aRetError) = 0)
			_oModel := FWLoadModel("MATA020")
			_cModel := "SA2MASTER"
			
			If(Type('_oClient:COD')<>'U' .and. Type('_oClient:LOJA')<>'U')
				SA2->(DBSetOrder(1))
				If(!SA2->(MsSeek(xFilial("SA2")+ALLTRIM(_oClient:COD)+ALLTRIM(_oClient:LOJA),.T.)))
					_oModel:SetOperation(MODEL_OPERATION_INSERT)
				Else
					_oModel:SetOperation(MODEL_OPERATION_UPDATE)
				EndIf

				_oModel:Activate()	
				_oModel:SetValue(_cModel,"A2_COD",_oClient:Cod)
				_oModel:SetValue(_cModel,"A2_LOJA",_oClient:Loja)
			ElseIf(Type('_oClient:COD')<>'U' .and. Type('_oClient:LOJA')=='U')
			
				If(Select(_xAlias1)!=0)
					(_xAlias1)->(DbCloseArea())
				EndIf
				
				BeginSQL ALIAS _xAlias1
					SELECT MAX(A2_LOJA) LOJA 
					FROM %TABLE:SA2% SA2 
					WHERE A2_FILIAL=%EXP:XFILIAL('SA2')% AND A2_COD=%EXP:_oClient:COD% AND SA2.%NOTDEL%
				EndSQL
				
				If(!(_xAlias1)->(Eof()))
					_cCodLoja := soma1((_xAlias1)->LOJA)
				Else
					_cCodLoja := STRZERO(1,tamsx3('A2_LOJA')[1])
				EndIf
				
				(_xAlias1)->(DbCloseArea())
				
				_oModel:SetOperation(MODEL_OPERATION_INSERT)
				_oModel:Activate()
				_oModel:SetValue(_cModel,"A2_COD",_oClient:Cod)	
				_oModel:SetValue(_cModel,"A2_LOJA",_cCodLoja)	
			Else
				_oModel:SetOperation(MODEL_OPERATION_INSERT)
				_oModel:Activate()
				_oModel:SetValue(_cModel,"A2_COD",GETSXENUM('SA2','A2_COD'))	
				_oModel:SetValue(_cModel,"A2_LOJA","01")	
			EndIf
			
			_nI := 1
			For _nI := 1 to Len(_aValid)
				If(Type('_oClient:'+_aValid[_nI][1])!='U' .AND.  !ALLTRIM(_aValid[_nI][1]) $ 'A1_COD#A1_LOJA')
					_oModel:SetValue(_cModel,_aValid[_nI][5],&('_oClient:'+_aValid[_nI][1]))
				EndIf				
			Next
		
			If _oModel:VldData()		
				_oModel:CommitData()	
				_cContent := '{"Cadastro de Fornecedor Realizado"}'
			Else	
				_cContent := '{"Erro":"'
				_cContent += _oModel:GetErrorMessage()[6]
				_cContent += '"}'
			EndIf	
				
			_oModel:DeActivate()
			_oModel:Destroy()
			_oModel:= nil
			
			//::SetResponse('["mensagem":')	
			::SetResponse(_cContent)
			If(_nJ <Len(_oBody))
				::SetResponse(',')
			EndIf	
		Else
			If(Len(_aRetError)>0)
				Return {.f.,500,U_WS002RET(_aRetError)}
			EndIf
			
		EndIf
		
	next _nJ
	::SetResponse("]]")
EndIf

If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return _lRet


user function WS001tst()
Local _lRet := .t.
Local _cRet := ''
//Local aDados := {}


private _oModel,_cModel
//private lMvcMata020 := nil

SA2->(DBSetOrder(1))

//A020AjInteg()

//lMvcMata020 := IIF(ValType(lMvcMata020) == "L",lMvcMata020, TableInDic( "G3Q", .F. ))


//conout('lMvcMata020',type('lMvcMata020'),lMvcMata020)


_oModel := FWLoadModel("MATA020")	
_cModel := "SA2MASTER"
_oModel:SetOperation(MODEL_OPERATION_UPDATE)
			

_oModel:Activate()	
SA2->(DBSETORDER(1))
IF(SA2->(DBSEEK(XFILIAL('SA2')+'07783926'+'0002')))


_oModel:SetValue(_cModel,"A2_COD",'07783926')
_oModel:SetValue(_cModel,"A2_LOJA",'0002')


_oModel:SetValue(_cModel,"A2_TIPO",'j')

_oModel:SetValue(_cModel,"A2_BAIRRO",'ZONA INDUSTRIAL')	
/*    {
        "TIPO": "J",
        "CGC": "07783926000220",
        "COD": "07783926",
        "LOJA": "0002",
        "NOME": "PERFIMEC S/A CENTRO DE SERVICOS EM ACO",
        "NREDUZ": "PERFIMEC S/A CENTRO DE SERVICO",
        "END": "RODOVIA BR 280, 1605",
        "BAIRRO": "ITINGA",
        "EST": "SC",
        "COD_MUN": "09102",
        "MUN": "JOINVILLE",
        "CEP": "89245000",
        "INSCR": "255719191",
        "NATUREZ": "201001",
        "EMAIL": "tamata.lima@perfimec.com.br",
        "CODPAIS": "01058"
    },
{
        "TIPO": "X",
        "CGC": "00000000000",
        "COD": "00000000",
        "LOJA": "0001",
        "NOME": "CELESC - CENTRAIS ELETRICAS DE SANTA CATARINA",
        "NREDUZ": "CELESC",
        "END": "RU RAIMUNDO WELTER, 180",
        "BAIRRO": "ZONA INDL",
        "EST": "SC",
        "COD_MUN": "09102",
        "MUN": "JOINVILLE",
        "CEP": "89219780",
        "INSCR": "ISENTO",
        "NATUREZ": "204021",
        "EMAIL": ".",
        "CODPAIS": "01058"
    }
*/
If _oModel:VldData()		
	_oModel:CommitData()	
	_cRet := '{"Cadastro de Fornecedor Realizado"}'
Else	
	_cRet := '{"Erro":"'
	_cRet += _oModel:GetErrorMessage()[6]
	_cRet += '"}'
	//VARINFO('ERRO',_oModel:GetErrorMessage())
EndIf	
eNDiF
_oModel:DeActivate()
_oModel:Destroy()

return {_lRet,_cRet}


