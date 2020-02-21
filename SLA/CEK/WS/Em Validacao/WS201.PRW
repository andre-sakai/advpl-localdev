#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"


// ##############################################################################
// Projeto  : CEK
// Autor    : ANDRE SAKAI
// Modulo   : WS
// Função   : WS201 - CADASTRO DE FORNECEDORES
// Descrição: WS PARA CONSULTA DE FORNECEDORES
// Retorno  : REST COM AS INFORMAÇÕES DA TABELA SA2
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------




WSRESTFUL WS201 DESCRIPTION "Cadastro de Fornecedores"

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 
WSDATA CDTFILTRO AS STRING OPTIONAL 

WSDATA CWSEMP AS STRING OPTIONAL 
WSDATA CWSFIL AS STRING OPTIONAL 

WSDATA CWSDIC AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta de Fornecedores" WSSYNTAX "/rest/WS201 || /rest/WS201/{doc}"
WSMETHOD POST DESCRIPTION "Inclusão de Fornecedores" WSSYNTAX "/rest/WS201"
//WSMETHOD PUT DESCRIPTION "Alteração de Clientes" WSSYNTAX "/rest/WS002/{id}"
//WSMETHOD DELETE DESCRIPTION "Exclusão de entidade" WSSYNTAX "/sample/{id}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS201

//Local _aValid := {}
Local _cVldTkn := ''
Local _lRet := .F.
Local _cDoc := ''
Local _cFiltro := '', _xFiltro := ''				
Local _nI := 0
Local _nReg := 0				
Local _lPrepEnv := .F.
Local _cAlias := ''

Private _aValid := {}

Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''	
Default SELF:CDTFILTRO 	:=''		

DEFAULT SELF:CWSEMP := '01'
DEFAULT SELF:CWSFIL := '0101' 
DEFAULT SELF:CWSDIC := 'N' 

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "","","","",{"SA1","SA2","SA3","SA4"}) 
	_lPrepEnv := .T.
EndIf


_cAlias := getnextalias()
// define o tipo de retorno do método
::SetContentType("application/json")

_cVldTkn := AllTrim(GETMV('MV_TKNREST',.T.,'123456'))

If(!EMPTY(SELF:cFiltro))
	_cFiltro := SELF:cFiltro
Else

EndIf						

If(!AllTrim(SELF:pToken) == _cVldTkn)
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
	If Len(::aURLParms) = 1
		_cDoc := padr(::aURLParms[1],tamsx3('A2_CGC')[1],' ')
		If(Empty(_cDoc))
			::SetResponse('["ID":401,"Erro":"Documento nao informado!"]')
			SetRestFault(499,'"Erro":"Documento nao informado! Verifique as informações enviadas!')
			Return _lRet
		EndIf
		
		If(Len(AllTrim(_cDoc))>8)
			_xFiltro := "  A2_CGC='"+_cDoc+"' "
		ElseIf(Len(AllTrim(_cDoc))=8)		  
			_xFiltro := " SUBSTRING(A2_CGC,1,8)='"+AllTrim(_cDoc)+"' AND LEN(RTRIM(A2_CGC))=14 "
		EndIf
		
	ElseIf Len(::aURLParms) > 1
		_cCodigo := padr(::aURLParms[1],tamsx3('A2_COD')[1],' ')
		If(Empty(_cCodigo))
			::SetResponse('["ID":401,"Erro":"Codigo nao informado!"]')
			SetRestFault(499,'"Erro":"Codigo nao informado! Verifique as informações enviadas!')
			Return _lRet
		EndIf
		
		If Len(::aURLParms) >= 2
			_cLoja := padr(::aURLParms[2],tamsx3('A2_LOJA')[1],' ')
		EndIf

		If(!Empty(_cCodigo))
			_xFiltro := " A2_COD='"+_cCodigo+"' "
		EndIf
		
		If(!Empty(_cLoja))
			_xFiltro += " AND A2_LOJA = '"+AllTrim(_cLoja)+"' "
		EndIf
		
	EndIf
		
	IF(!EMPTY(_cFiltro))
		_xFiltro += ' AND '+_cFiltro
	EndIf
	
	If(!empty(_xFiltro))
		_xFiltro := "% AND "+_xFiltro+"%"
	Else
		_xFiltro := "%%"
	EndIf
	
	if(SELECT(_cAlias)>0)
		(_cAlias)->(dbclosearea())
	endif
	
	conout('ws201 - filtro '+_xFiltro)
	
	
	BeginSql alias _cAlias
		SELECT ROW_NUMBER() OVER(ORDER BY A2_COD ASC) REG, * FROM %TABLE:SA2% SA2
		WHERE A2_FILIAL=%EXP:XFILIAL('SA2')% AND SA2.D_E_L_E_T_=' ' %EXP:_xFiltro%
		ORDER BY A2_COD
	EndSql
	
	conout('ws201 - query '+GETLASTQUERY()[2])
	
	DBSELECTAREA(_cAlias)

	(_cAlias)->(DBGoTop())
	count to _nReg 
	
	_nIni := ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO )
	_nFim := (SELF:NPAGINA * SELF:NREGISTRO)
	
	SET FILTER TO REG >= _nIni .and. REG <=_nFim
	
	(_cAlias)->(DBGoTop())
	
	
	If(!(_cAlias)->(EOF()))	
	
		::SetResponse('{"REGISTROS":[')
	
		_nJ := 1
		While((_cAlias)->(!Eof()))
			//If(_nJ >= ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO ) .AND. _nJ <= (SELF:NPAGINA * SELF:NREGISTRO ))
			
				If(_lRet)
					::SetResponse(',')			
				EndIf
				::SetResponse('{')
				::SetResponse('"REG_NUM":'+cvaltochar((_cAlias)->REG)+',')
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(noacento(&(_aValid[_nI,5])))+'"'+iif(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='M')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='O')
						//não tratado - somente para compatibilidade com outras funções
					ElseIf(_aValid[_nI,3]=='L')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='D')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+dtos(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='N')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
					EndIf
					
				Next
				::SetResponse('}')
				_lRet := .T.
			//EndIf
			
			_nJ++
			(_cAlias)->(DBSkip())
		EndDo
		::SetResponse(']')
		::SetResponse(', "QUANTIDADE":'+CVALTOCHAR(_nReg))
		::SetResponse(', "PAGINA":'+CVALTOCHAR(SELF:NPAGINA))
		IF(SELF:CWSDIC = 'S')
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
				EndIf
				::SetResponse("}")
			Next
			
			::SetResponse(']') //FIM DO DICIONARIO
		ENDIF
	ElsE
		::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado !"}')
		SetRestFault(402,'Nenhum cadastro encontrado! Verifique as informações enviadas!')
		return .f.
	EndIf
	::SetResponse('}')
	dbselectarea(_cAlias)
	SET FILTER TO		  
Else
	
	If(Select(_cAlias)>0)
		(_cAlias)->(dbclosearea())
	EndIf
	
	If(!Empty(_cFiltro))
		_xFiltro += _cFiltro
	EndIf
	
	If(!Empty(_xFiltro))
		_xFiltro := "% AND "+_xFiltro+"%"
	Else
		_xFiltro := "% %"
	EndIf
	
	conout('ws201 - filtro '+_xFiltro)
	
	
	BeginSql alias _cAlias
		SELECT ROW_NUMBER() OVER(ORDER BY A2_COD ASC) REG, * FROM %TABLE:SA2% SA2
		WHERE A2_FILIAL=%EXP:XFILIAL('SA2')% AND SA2.D_E_L_E_T_=' ' %EXP:_xFiltro%
		ORDER BY A2_COD
	EndSql
	
	conout('ws201 - query '+GETLASTQUERY()[2])
	
	DBSELECTAREA(_cAlias)

	(_cAlias)->(DBGoTop())
	count to _nReg 
	
	_nIni := ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO )
	_nFim := (SELF:NPAGINA * SELF:NREGISTRO)
	
	SET FILTER TO REG >= _nIni .and. REG <=_nFim
	
	(_cAlias)->(DBGoTop())
	
	
	If(!(_cAlias)->(EOF()))	
	
		::SetResponse('{"REGISTROS":[')
	
		_nJ := 1
		While((_cAlias)->(!Eof()))
			//If(_nJ >= ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO ) .AND. _nJ <= (SELF:NPAGINA * SELF:NREGISTRO ))
			
				If(_lRet)
					::SetResponse(',')			
				EndIf
				::SetResponse('{')
				::SetResponse('"REG_NUM":'+cvaltochar((_cAlias)->REG)+',')
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(noacento(&(_aValid[_nI,5])))+'"'+iif(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='M')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='O')
						//não tratado - somente para compatibilidade com outras funções
					ElseIf(_aValid[_nI,3]=='L')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='D')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+dtos(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='N')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
					EndIf
					
				Next
				::SetResponse('}')
				_lRet := .T.
			//EndIf
			
			_nJ++
			(_cAlias)->(DBSkip())
		EndDo
		::SetResponse(']')
		::SetResponse(', "QUANTIDADE":'+CVALTOCHAR(_nReg))
		::SetResponse(', "PAGINA":'+CVALTOCHAR(SELF:NPAGINA))
		If(SELF:CWSDIC=='S')
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
				EndIf
				::SetResponse("}")
			
			::SetResponse(']') //FIM DO DICIONARIO
		EndIf
	Else	 
		::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado ('+_cDoc+')!"}')
		SetRestFault(402,'"Erro":"Nenhum cadastro encontrado ('+_cDoc+')! Verifique as informações enviadas!')
		return .f.
	EndIf
	::SetResponse('}')
	dbselectarea(_cAlias)
	SET FILTER TO	
	
	(_cAlias)->(DBCLOSEAREA())
	
EndIf


If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return .T.
 
 
WSMETHOD POST WSSERVICE WS201
Local _lRet := .F.
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
Local _cForCod, _cForLoja, _cForFil


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

_nI := 1
While(Type('_oBody')='U' .and. _nI < 5)
	FWJsonDeserialize(_cContent,@_oBody)
	_nI++
	If(type('_oBody')!='U')
		EXIT
	EndIf
EndDo

_aValid   := U_WSCAMPOS(SELF:CTIPO,'SA2')
_aValidCo := U_WSCAMPOS('COMPLETO','SA2')
_aValidOb := U_WSCAMPOS('OBRIGATORIO','SA2')

If(Type('_oBody')== 'O')
	_cForCod  := ''
	_cForLoja := ''
	_cForFil  := ''

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

	::SetResponse('{"MENSAGEM":')
	If (Len(_aRetError) = 0)
		_oModel := FWLoadModel("MATA020")
		_cModel := "SA2MASTER"
		
		SA2->(DBSetOrder(1))
		
		If(Type('_oClient:CODIGO')<>'U' .and. Type('_oClient:LOJA')<>'U')
			SA2->(DBSetOrder(1))
			If(!SA2->(MsSeek(xFilial("SA2")+AllTrim(_oClient:CODIGO)+AllTrim(_oClient:LOJA),.T.)))
				_oModel:SetOperation(MODEL_OPERATION_INSERT)
			Else
				_oModel:SetOperation(MODEL_OPERATION_UPDATE)
			EndIf

			_oModel:Activate()	
			_cForCod  := XfILIAL('SA2')
			_cForLoja := _oClient:CODIGO
			_cForFil  := _oClient:Loja
			
			//_oModel:SetValue(_cModel,"A2_FILIAL",XfILIAL('SA2'))
			//_oModel:SetValue(_cModel,"A2_COD",_oClient:Cod)
			//_oModel:SetValue(_cModel,"A2_LOJA",_oClient:Loja)
		ElseIf(Type('_oClient:CODIGO')<>'U' .and. Type('_oClient:LOJA')=='U')
		
			If(Select(_xAlias1)!=0)
				(_xAlias1)->(DbCloseArea())
			EndIf
			
			BeginSQL ALIAS _xAlias1
				SELECT MAX(A2_LOJA) LOJA 
				FROM %TABLE:SA2% SA2 
				WHERE A2_FILIAL=%EXP:XFILIAL('SA2')% AND A2_COD=%EXP:_oClient:CODIGO% AND SA2.%NOTDEL%
			EndSQL
			
			If(!(_xAlias1)->(Eof()))
				_cForLoja := soma1((_xAlias1)->LOJA)
			Else
				_cForLoja := STRZERO(1,tamsx3('A2_LOJA')[1])
			EndIf
			
			(_xAlias1)->(DbCloseArea())
			
			_oModel:SetOperation(MODEL_OPERATION_INSERT)
			_oModel:Activate()
			
			_cForFil  := XfILIAL('SA2')
			_cForCod  := _oClient:CODIGO
			_cForLoja := _cForLoja
			//_oModel:SetValue(_cModel,"A2_FILIAL",XfILIAL('SA2'))
			//_oModel:SetValue(_cModel,"A2_COD",_oClient:Cod)	
			//_oModel:SetValue(_cModel,"A2_LOJA",_cCodLoja)	
		Else
			_oModel:SetOperation(MODEL_OPERATION_INSERT)
			_oModel:Activate()
			
			
			_cForFil  := XfILIAL('SA2')
			_cForCod  := GETSXENUM('SA2','A2_COD')
			_cForLoja := tamsx3('A2_LOJA')[1]
			
			
			//_oModel:SetValue(_cModel,"A2_FILIAL",XfILIAL('SA2'))
			//_oModel:SetValue(_cModel,"A2_COD",GETSXENUM('SA2','A2_COD'))	
			//_oModel:SetValue(_cModel,"A2_LOJA",STRZERO(1,tamsx3('A2_LOJA')[1]))	
		EndIf
		
		_nI := 1

		For _nI := 1 to Len(_aValidCo)
			If(Type('_oClient:'+_aValidCo[_nI][1])!='U' )
				if(AllTrim(_aValidCo[_nI][5]) $ 'A2_FILIAL#A2_COD#A2_LOJA#')
					If(AllTrim(_aValidCo[_nI][5]) = 'A2_FILIAL')
						_oModel:SetValue(_cModel,_aValidCo[_nI][5],_cForFil)
					ElseIf(AllTrim(_aValidCo[_nI][5]) = 'A2_COD')
						_oModel:SetValue(_cModel,_aValidCo[_nI][5],_cForCod)
					ElseIf(AllTrim(_aValidCo[_nI][5]) = 'A2_LOJA')
						_oModel:SetValue(_cModel,_aValidCo[_nI][5],_cForLoja)
					EndIf
				Else
					conout("ws201 - 504",_cModel,_aValidCo[_nI][5],&('_oClient:'+_aValidCo[_nI][1]))
					_oModel:SetValue(_cModel,_aValidCo[_nI][5],&('_oClient:'+_aValidCo[_nI][1]))
				EndIf
			EndIf				
		Next

	
		If _oModel:VldData()		
			_oModel:CommitData()	
			_cContent := '"Cadastro de Fornecedor Realizado"'
			
			_lRet := .T.
		Else	
			_lRet := .F.
			_cContent := '{Erro: '
			_cContent += _oModel:GetErrorMessage()[6]
			_cContent += '"}'
		EndIf	
			
		_oModel:DeActivate()
		_oModel:Destroy()
		_oModel:= nil
		
		//::SetResponse('["mensagem":')	
		::SetResponse(_cContent)
	Else
		If(Len(_aRetError)>0)
			Return {.f.,500,U_WS002RET(_aRetError)}
		EndIf
		
	EndIf
	
	IF(_lRet)
		::SetResponse(', "Registros":[')
		_cAlias := 'SA2'
		::SetResponse('{')
		For _nI := 1 to len(_aValid)
			If(_aValid[_nI,3]=='C')
				::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(noacento(&(_aValid[_nI,5])))+'"'+iif(_nI<len(_aValid),',',''))
			ElseIf(_aValid[_nI,3]=='M')
				::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
			ElseIf(_aValid[_nI,3]=='O')
				//não tratado - somente para compatibilidade com outras funções
			ElseIf(_aValid[_nI,3]=='L')
				::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))			
			ElseIf(_aValid[_nI,3]=='D')
				::SetResponse('"'+_aValid[_nI,1]+'":"'+dtos(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))			
			ElseIf(_aValid[_nI,3]=='N')
				::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
			EndIf
			
		Next
		::SetResponse('}')
		::SetResponse(']')
	ENDIF
	
	::SetResponse("}")
	
ElseIf(type('_oBody')== 'A')
	For _nJ :=1 to Len(_oBody)
		_cForCod  := ''
		_cForLoja := ''
		_cForFil  := ''
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

		::SetResponse('{"MENSAGEM":')
		If (Len(_aRetError) = 0)
			_oModel := FWLoadModel("MATA020")
			_cModel := "SA2MASTER"
			
			If(Type('_oClient:CODIGO')<>'U' .and. Type('_oClient:LOJA')<>'U')
				SA2->(DBSetOrder(1))
				If(!SA2->(MsSeek(xFilial("SA2")+AllTrim(_oClient:CODIGO)+AllTrim(_oClient:LOJA),.T.)))
					_oModel:SetOperation(MODEL_OPERATION_INSERT)
				Else
					_oModel:SetOperation(MODEL_OPERATION_UPDATE)
				EndIf
	
				_oModel:Activate()	
				_cForCod  := XfILIAL('SA2')
				_cForLoja := _oClient:CODIGO
				_cForFil  := _oClient:Loja
				
				//_oModel:SetValue(_cModel,"A2_FILIAL",XfILIAL('SA2'))
				//_oModel:SetValue(_cModel,"A2_COD",_oClient:Cod)
				//_oModel:SetValue(_cModel,"A2_LOJA",_oClient:Loja)
			ElseIf(Type('_oClient:CODIGO')<>'U' .and. Type('_oClient:LOJA')=='U')
			
				If(Select(_xAlias1)!=0)
					(_xAlias1)->(DbCloseArea())
				EndIf
				
				BeginSQL ALIAS _xAlias1
					SELECT MAX(A2_LOJA) LOJA 
					FROM %TABLE:SA2% SA2 
					WHERE A2_FILIAL=%EXP:XFILIAL('SA2')% AND A2_COD=%EXP:_oClient:CODIGO% AND SA2.%NOTDEL%
				EndSQL
				
				If(!(_xAlias1)->(Eof()))
					_cForLoja := soma1((_xAlias1)->LOJA)
				Else
					_cForLoja := STRZERO(1,tamsx3('A2_LOJA')[1])
				EndIf
				
				(_xAlias1)->(DbCloseArea())
				
				_oModel:SetOperation(MODEL_OPERATION_INSERT)
				_oModel:Activate()
				
				_cForFil  := XfILIAL('SA2')
				_cForCod  := _oClient:CODIGO
				_cForLoja := _cForLoja
				//_oModel:SetValue(_cModel,"A2_FILIAL",XfILIAL('SA2'))
				//_oModel:SetValue(_cModel,"A2_COD",_oClient:Cod)	
				//_oModel:SetValue(_cModel,"A2_LOJA",_cCodLoja)	
			Else
				_oModel:SetOperation(MODEL_OPERATION_INSERT)
				_oModel:Activate()
				
				
				_cForFil  := XfILIAL('SA2')
				_cForCod  := GETSXENUM('SA2','A2_COD')
				_cForLoja := tamsx3('A2_LOJA')[1]
				
				
				//_oModel:SetValue(_cModel,"A2_FILIAL",XfILIAL('SA2'))
				//_oModel:SetValue(_cModel,"A2_COD",GETSXENUM('SA2','A2_COD'))	
				//_oModel:SetValue(_cModel,"A2_LOJA",STRZERO(1,tamsx3('A2_LOJA')[1]))	
			EndIf
			
			_nI := 1
			
			For _nI := 1 to Len(_aValid)
				If(Type('_oClient:'+_aValid[_nI][1])!='U' )
					If(AllTrim(_aValid[_nI][5]) $ 'A2_FILIAL#A2_COD#A2_LOJA#')
						If(AllTrim(_aValid[_nI][5]) = 'A2_FILIAL')
							_oModel:SetValue(_cModel,_aValid[_nI][5],_cForFil)
						ElseIf(AllTrim(_aValid[_nI][5]) = 'A2_COD')
							_oModel:SetValue(_cModel,_aValid[_nI][5],_cForCod)
						ElseIf(AllTrim(_aValid[_nI][5]) = 'A2_LOJA')
							_oModel:SetValue(_cModel,_aValid[_nI][5],_cForLoja)
						EndIf
					Else
						_oModel:SetValue(_cModel,_aValid[_nI][5],&('_oClient:'+_aValid[_nI][1]))
					EndIf
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
	::SetResponse("}")
EndIf

If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return _lRet


User function ws201tst()
Local _lRet := .t.
Local _cRet := ''
//Local aDados := {}


Private _oModel,_cModel
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
EndIf
_oModel:DeActivate()
_oModel:Destroy()

Return {_lRet,_cRet}


USER FUNCTION WS000DAT()

RETURN

USER FUNCTION WS000DIC()

RETURN
