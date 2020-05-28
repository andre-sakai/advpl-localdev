#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

// ##############################################################################
// Projeto  : INDUSBELLO
// Autor    : ANDRE SAKAI
// Modulo   : WS
// Função   : WS302 - CADASTRO DE CLIENTES
// Descrição: WS PARA CONSULTA DE CLIENTES
// Retorno  : REST COM AS INFORMAÇÕES DA TABELA SA1
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 17/03/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

WSRESTFUL WS302 DESCRIPTION "Cadastro de Clientes"

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 
WSDATA CDTFILTRO AS STRING OPTIONAL 									
WSDATA CTESTE AS STRING OPTIONAL 

WSDATA CWSEMP AS STRING OPTIONAL 
WSDATA CWSFIL AS STRING OPTIONAL 

WSDATA CWSDIC AS STRING OPTIONAL 								 
WSMETHOD GET DESCRIPTION "Consulta de Clientes" WSSYNTAX "/rest/WS302 || /rest/WS302/{doc}"
WSMETHOD POST DESCRIPTION "Inclusão de Clientes" WSSYNTAX "/rest/WS302"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS302

//Local _aValid := {}
Local _cVldTkn := ''
Local _lRet := .F.
Local _cDoc := '', _cCodigo:='', _cLoja:=''
Local _cFiltro := '', _xFiltro := '', _dFiltro := ''
Local _nI := 0
Local _nReg := 0
Local _lPrepEnv := .F.
Local _cAlias, _cContent

Private _aValid := {}
Private _oBody

Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''
Default SELF:CTESTE 	:=''

DEFAULT SELF:CWSEMP := '01'
DEFAULT SELF:CWSFIL := '01'
DEFAULT SELF:CWSDIC := 'N' 						   

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "","","","",{"SA1","SA2","SA3","SA4"}) 
	_lPrepEnv := .T.
EndIf




// define o tipo de retorno do método
::SetContentType("application/json")


_cAlias := getnextalias()

_cVldTkn := AllTrim(GETMV('MV_TKNREST',.T.,'123456'))
_cFiltro := SELF:cFiltro
_dFiltro := SELF:cDtFiltro

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
	If Len(::aURLParms) = 1
		_cDoc := padr(::aURLParms[1],tamsx3('A1_CGC')[1],' ')
		If(Empty(_cDoc))
			::SetResponse('["ID":401,"Erro":"Documento nao informado!"]')
			SetRestFault(499,'"Erro":"Documento nao informado! Verifique as informações enviadas!')
			Return _lRet
		EndIf
		
		If(Len(AllTrim(_cDoc))>8)
			_xFiltro := "  A1_CGC='"+_cDoc+"' "
		ElseIf(Len(AllTrim(_cDoc))=8)
			_xFiltro := " SUBSTRING(A1_CGC,1,8)='"+AllTrim(_cDoc)+"' AND LEN(RTRIM(A1_CGC))=14 "
		EndIf
		
	ElseIf Len(::aURLParms) > 1
		_cCodigo := padr(::aURLParms[1],tamsx3('A1_COD')[1],' ')
		If(Empty(_cCodigo))
			::SetResponse('["ID":401,"Erro":"Codigo nao informado!"]')
			SetRestFault(499,'"Erro":"Codigo nao informado! Verifique as informações enviadas!')
			Return _lRet
		EndIf
		
		If Len(::aURLParms) >= 2
			_cLoja := padr(::aURLParms[2],tamsx3('A1_LOJA')[1],' ')
		EndIf

		If(!Empty(_cCodigo))
			_xFiltro := " A1_COD='"+_cCodigo+"' "
		EndIf
		
		If(!Empty(_cLoja))
			_xFiltro += " AND A1_LOJA = '"+AllTrim(_cLoja)+"' "
		EndIf
		
	EndIf
	
 
	If(!EMPTY(_cFiltro))
		IF(!empty(_xFiltro))
			_xFiltro += " AND "
		ENDIF
		_xFiltro += ' '+_cFiltro +' '
	EndIf
	
	If(!EMPTY(_dFiltro))
		IF(!empty(_xFiltro))
			_xFiltro += " AND "
		ENDIF
		_xFiltro += " CASE WHEN A1_USERLGA = ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGI,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120) ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGA,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) END >= '"+_dFiltro+"' "
	EndIf
	
	If(!empty(_xFiltro))
		_xFiltro := "% AND "+_xFiltro+"%"
	Else
		_xFiltro := "% %"
		
	EndIf
	
	
	If(SELECT(_cAlias)>0)
		(_cAlias)->(dbclosearea())
	EndIf
	
	conout('ws302 - filtro '+_xFiltro)
	
	
	BeginSql alias _cAlias
		%NOPARSER%
		SELECT ROW_NUMBER() OVER(ORDER BY A1_COD ASC) REG, * , A1_COD+A1_LOJA AS CHAVE,REC SA1.R_E_C_N_O_,DEL SA1.R_E_C_N_O_
		FROM %TABLE:SA1% SA1
		WHERE A1_FILIAL=%EXP:XFILIAL('SA1')% AND SA1.D_E_L_E_T_=' ' %EXP:_xFiltro% 
		
		ORDER BY A1_COD
	EndSql
	
	conout('ws302 - query '+GETLASTQUERY()[2])
	
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
				::SetResponse('"DTALT":"'+(_cAlias)->DTLGA+'",')
				::SetResponse('"CHAVE":"'+(_cAlias)->(A1_COD+A1_LOJA)+'",')
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(STRTRAN(noacento(&(_aValid[_nI,5])),'"',''))+'"'+iif(_nI<len(_aValid),',',''))
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
				::SetResponse('"DELETADO":"'+(_cAlias)->DEL+'",')
				::SetResponse('"RECNO":'+CVALTOCHAR((_cAlias)->REC)+'')
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
				::SetResponse('"CAMPO_PROTHEUS":"'+_aValid[_nI,5]+'"')
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


	If(!EMPTY(_cFiltro))
		IF(!empty(_xFiltro))
			_xFiltro += " AND "
		ENDIF
		_xFiltro += ' '+_cFiltro +' '
	EndIf
	
	If(!Empty(_dFiltro))
		If(SA1->(FIELDPOS('A1_USERLGA')))
			If(!Empty(_xFiltro))
				_xFiltro += " AND "
			EndIf
			_xFiltro += " CASE WHEN A1_USERLGA = ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGI,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120) ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGA,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) END >= '"+_dFiltro+"' "
		EndIf
	EndIf
	If(!Empty(_xFiltro))
		_xFiltro := "% AND "+_xFiltro+"%"
	Else
		_xFiltro := "% %"
	EndIf
	
	conout('ws302 - filtro '+_xFiltro)
	
	If(SELF:CFILTRO = "SQL")
		::SetResponse('{"FILTRO":"'+_xFiltro+'"}')
		return .t.
	EndIf
	
	BeginSql alias _cAlias
		%NOPARSER%
		SELECT ROW_NUMBER() OVER(ORDER BY A1_COD ASC) REG, 
		CASE 	WHEN A1_USERLGA = ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGI,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
				ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGA,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) 
		END DTLGA, * , A1_COD+A1_LOJA AS CHAVE
		FROM %TABLE:SA1% SA1
		WHERE A1_FILIAL=%EXP:XFILIAL('SA1')% AND SA1.D_E_L_E_T_=' ' %EXP:_xFiltro%
		ORDER BY A1_COD
	EndSql
	
	conout('ws302 - query '+GETLASTQUERY()[2])
	
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
				If((_cAlias)->(FIELDPOS("DTLGA")))
					::SetResponse('"DTALT":"'+(_cAlias)->DTLGA+'",')	
				EndIf													   
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(STRTRAN(noacento(&(_aValid[_nI,5])),'"',''))+'"'+iif(_nI<len(_aValid),',',''))
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
			::SetResponse('"CAMPO_PROTHEUS":"'+_aValid[_nI,5]+'"')
			IF(!EMPTY(_aValid[_nI,6]))
				::SetResponse(', "OPCOES":"'+_aValid[_nI,6]+'"')
			EndIf
			::SetResponse("}")
		Next
		
		::SetResponse(']') //FIM DO DICIONARIO
		endif
	Else	 
		::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado ('+_cDoc+')!"}')
		SetRestFault(402,'Erro - Nenhum cadastro encontrado! Verifique as informações enviadas!')
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


 
WSMETHOD POST WSSERVICE WS302
Local _lRet  	:= .T.
Local _lRet2 	:= .F.
Local _nI 		:= 0
Local _nJ 		:= 0
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

	::SetResponse('{"MENSAGEM":')
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
			_cContent := '"CADASTRO REALIZADO"'
			_lRet2 := .T.
				::setresponse('{"CODIGO":"'+SA1->A1_COD+'","LOJA:"}')
			return .t.
	
		Else	
			_cContent := '"ERRO":"'
			_cContent += _oModel:GetErrorMessage()[6]
			_cContent += '"'

			::setresponse('{'+_cContent+'}')
			return .t.
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
	IF(_lRet2)
		::SetResponse(',"RESULTADO":{')

		_aValidaA1 := U_WSCAMPOS('','SA1')
			
		_aValid := _aValidaA1
		_cAlias := "SA1"
		dbselectarea(_cAlias)
	
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
				::SetResponse('"'+_aValid[_nI,1]+'":"')
				IF(TYPE(_aValid[_nI,5])='D')
					::SetResponse(dtos(&(_aValid[_nI,5]))+'"')
				ELSEIF(TYPE(_aValid[_nI,5])='C')
					::SetResponse(&(_aValid[_nI,5])+'"')
				ENDIF
				::SetResponse(iif(_nI<len(_aValid),',',''))			
			ElseIf(_aValid[_nI,3]=='N')
				::SetResponse('"'+_aValid[_nI,1]+'":'+alltrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
			EndIf
		Next
	
		::SetResponse('}')
	ENDIF
	
	::SetResponse("}")
	
EndIf

If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return _lRet

