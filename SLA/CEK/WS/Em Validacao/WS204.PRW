#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"


// ##############################################################################
// Projeto  : CEK
// Autor    : ANDRE SAKAI
// Modulo   : WS
// Função   : WS204 - CADASTRO DE TRANSPORTADORAS	
// Descrição: WS PARA CONSULTA DE TRANSPORTADORAS
// Retorno  : REST COM AS INFORMAÇÕES DA TABELA SA4
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------
WSRESTFUL WS204 DESCRIPTION "Cadastro de Transportadoras"

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 
WSDATA CDTFILTRO AS STRING OPTIONAL 

WSDATA CWSEMP AS STRING OPTIONAL 
WSDATA CWSFIL AS STRING OPTIONAL 

WSDATA CWSDIC AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta de Transportadoras" WSSYNTAX "/rest/WS204 || /rest/WS204/{cod}"
//WSMETHOD POST DESCRIPTION "Inclusão/Alteração de Transportadoras" WSSYNTAX "/rest/WS204"
//WSMETHOD PUT DESCRIPTION "Alteração de Clientes" WSSYNTAX "/rest/WS204/{id}"
//WSMETHOD DELETE DESCRIPTION "Exclusão de entidade" WSSYNTAX "/sample/{id}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS204


Local _aValid := {}
Local _cVldTkn := ''//ALLTRIM(GETMV('MV_TKNREST',.T.,'123456'))
Local _lRet := .F.
Local _cCod := ''
Local _nI,_nJ,_nReg
Local _cAlias1 := 'SA4'
Local _cFiltro := '', _xFiltro := '', _dFiltro := ''
Local _nI := 0
Local _lPrepEnv := .F.
Local _cAlias, _cContent

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

// define o tipo de retorno do método
::SetContentType("application/json")
//::SetContentType("application/html")

_cVldTkn := AllTrim(GETMV('MV_TKNREST',.T.,'123456'))

If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verifique a chave!')
	Return _lRet
Else

//	CONOUT('PTOKEN',SELF:PTOKEN)
//	CONOUT('TOKEN',_cVldTkn)

EndIf

If Len(::aURLParms) > 0
	// insira aqui o código para pesquisa do parametro recebido
	// consulta de cliente por documento
	_cCodigo := padr(::aURLParms[1],tamsx3('A4_COD')[1])
Else
	_cCodigo := ''
EndIf

_cAlias := getnextalias()

_cFiltro := SELF:cFiltro
_dFiltro := SELF:cdtFiltro

cQry:=''
cQry+="%"
cQry+= " AND A4_FILIAL='"+XFILIAL('SA4')+"' "
If(!empty(SELF:cFiltro))
	cQry+= " AND " + SELF:cFiltro
EndIf
IF(!EMPTY(_cCodigo))
	cQry+= " AND A4_COD='" + _cCodigo + "' "
ENDIF

If(!EMPTY(_dFiltro))
	cQry += " AND "
	cQry += " CASE WHEN A4_USERLGA = ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGI,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120) ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGA,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) END >= '"+_dFiltro+"' "
EndIf

cQry+="%"

BEGINSQL ALIAS _cAlias
	%NOPARSER%
	SELECT 	ROW_NUMBER() OVER(ORDER BY A4_COD ASC) REG,
			CASE 	WHEN A4_USERLGA = ' ' 
					THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGI,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
					ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGA,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) 
			END DTLGA, *,
			A4_WSDTALT DTWSALT, R_E_C_N_O_ RECSA4, D_E_L_E_T_ DELSA4 FROM %TABLE:SA4% SA4
	WHERE SA4.D_E_L_E_T_='' %EXP:cQry%
	ORDER BY A4_COD
ENDSQL

(_cAlias)->(DBGoTop())
count to _nReg 
(_cAlias)->(DBGOTOP())


_aValidA4 := U_WSCAMPOS(SELF:CTIPO,'SA4')

dbselectarea(_cAlias)
_nIni := ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO )
_nFim := (SELF:NPAGINA * SELF:NREGISTRO)

SET FILTER TO REG >=_nIni .AND. REG <= _nFim

conout("filtro ws209 - REG BETWEEN '"+CVALTOCHAR(_nIni)+"' AND '"+CVALTOCHAR(_nFim)+"' ")
(_cAlias)->(dbgotop())



// define o tipo de retorno do método
IF(!(_cAlias)->(EOF()))
	nPrimeiro :=0
	::SetResponse('{"REGISTROS":[')
	Do While !(_cAlias)->(Eof())
	    
	    //Contador para inserir separador do json
	    If nPrimeiro>0
	     ::SetResponse(',')
	    EndIf
	    nPrimeiro+= 1
//		cChave:= (_cAlias)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)
		::SetResponse('{')
		::SetResponse('"REG_NUM":'+cvaltochar((_cAlias)->REG)+',')
		::SetResponse('"DTALT_mercos":"'+(_cAlias)->DTLGA+'",')
		::SetResponse('"DTALT_cek":"'+(_cAlias)->DTWSALT+'",')
		_aValid := _aValidA4
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
		(_cAlias)->(DBSkip())
	EndDo
	
	::SetResponse('],')//FECHA rEGISTROS
	::SetResponse('"QUANTIDADE": '+cvaltochar(_nReg)+',')
	::SetResponse('"PAGINA": '+cvaltochar(SELF:NPAGINA)+'')
	If(SELF:CWSDIC=='S')
		::SetResponse(',"DICIONARIO":{')
			::SetResponse('"PRODUTO":[')
			_aValid := _aValidA4
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
				If(!Empty(_aValid[_nI,6]))
					::SetResponse(', "OPCOES":"'+_aValid[_nI,6]+'"')
				EndIf
				::SetResponse("}")
			Next		
			::SetResponse(']')
		::SetResponse('}')//FECHA DICIONARIO
	endif
	::SetResponse('}')//FECHA PRODUTOS
	
	(_cAlias)->(DBCLOSEAREA())
Else
	::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado!"}')
	SetRestFault(402,'Nenhum cadastro encontrado, verifique as informações enviadas!'+_cSql)		
	Return _lRet

EndIf



If(_lPrepEnv)
	RpcClearEnv()   
EndIf


Return .T.
 
/*/
WSMETHOD POST WSSERVICE WS204
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



If(select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv('01','0101', "","","","",{"SA1","SA2","SA3","SA4"}) 
	_lPrepEnv := .T.
EndIf


_cVldTkn := ALLTRIM(GETMV('MV_TKNREST',.T.,'123456'))


If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('{"ID":499,"Erro":"Token informado Invalido!"}')
	SetRestFault(499,'Token invalido, verifique a chave!')
	Return .F.
Else
	//conout('','Token Ok')
EndIf

_cContent  := SELF:GetContent()
FWJsonDeserialize(_cContent,@_oBody)

_nI := 1
While(type('_oBody')='U' .and. _nI < 5)
	FWJsonDeserialize(_cContent,@_oBody)
	_nI++
	If(type('_oBody')!='U')
		EXIT
	EndIf
EndDo

_aValid := U_WS002SA4()

If(Type('_oBody')== 'O')

	_oClient := _oBody

	FOR _nI := 1 to len (_aValid) 
		If (type('_oClient:'+_aValid[1])=="U" .AND. _aValid[2]==.T.)
			aAdd(_aRetError,{'500','Campo '+_aValid[1]+' obrigatorio!'})
		Else
			If(type('_oClient:'+_aValid[_nI][1])!=_aValid[_nI][3] .AND. type('_oClient:'+_aValid[_nI][1])<>"U")
				aAdd(_aRetError,{'500','Campo '+_aValid[1]+' com Tipo: '+type('_oClient:'+_aValid[1])+' - Esperado: '+_aValid[2]})
			EndIf
		EndIf
	
	NEXT

	::SetResponse('{"MENSAGEM":')
	If (Len(_aRetError) = 0)
		_oModel := FWLoadModel("MATA030")
		_cModel := "MATA030_SA1"
		//varinfo('_oModel',_oModel)
		//conout('MODEL_OPERATION_INSERT',MODEL_OPERATION_INSERT)
		//conout('MODEL_OPERATION_UPDATE',MODEL_OPERATION_UPDATE)
			
		If(Type('_oClient:CODIGO')<>'U' .and. Type('_oClient:LOJA')<>'U')
			(_cAlias1)->(DBSetOrder(1))
			If(!(_cAlias1)->(MsSeek(xFilial(_cAlias1)+ALLTRIM(_oClient:CODIGO)+ALLTRIM(_oClient:LOJA),.T.)))
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
				FROM %TABLE:(_cAlias1)% SA4 
				WHERE A1_FILIAL=%EXP:FWFILIAL(_cAlias1)% A1_COD=%EXP:_oClient:LOJA% AND SA4.%NOTDEL%
			EndSQL
			
			If(!(_xAlias1)->(EOF()))
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
			_oModel:SetValue(_cModel,"A1_COD",GETSXENUM(_cAlias1,'A1_COD'))	
			_oModel:SetValue(_cModel,"A1_LOJA","01")	
		EndIf
			
		_nI := 2
		For _nI := 2 to Len(_aValid)
			If(Type('_oClient:'+_aValid[_nI][1])!='U')
				_oModel:SetValue(_cModel,_aValid[_nI][5],&('_oClient:'+_aValid[_nI][1]))
			EndIf				
		Next
		
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

//MATA050
//- Nome do Modelo: MATA050
//- AddFields: MATA050_SA4

		::SetResponse('{"MENSAGEM":')
		If (Len(_aRetError) = 0)
			_oModel := FWLoadModel("MATA050")
			_cModel := "MATA050_SA4"
			
			If(Type('_oClient:CODIGO')<>'U' )
				(_cAlias1)->(DBSetOrder(1))
				If(!(_cAlias1)->(MsSeek(xFilial(_cAlias1)+ALLTRIM(_oClient:CODIGO)+ALLTRIM(_oClient:LOJA),.T.)))
					_oModel:SetOperation(MODEL_OPERATION_INSERT)
				Else
					_oModel:SetOperation(MODEL_OPERATION_UPDATE)
				EndIf

				_oModel:Activate()	
				_oModel:SetValue(_cModel,"A4_COD",_oClient:Codigo)
			Else
				_oModel:SetOperation(MODEL_OPERATION_INSERT)
				_oModel:Activate()
				_oModel:SetValue(_cModel,"A4_COD",GETSXENUM(_cAlias1,'A4_COD'))	
			EndIf
			
			_nI := 3
			For _nI := 3 to Len(_aValid)
				If(Type('_oClient:'+_aValid[_nI][1])!='U')
					_oModel:SetValue(_cModel,_aValid[_nI][5],&('_oClient:'+_aValid[_nI][1]))
				EndIf				
			Next
		
			If _oModel:VldData()		
				_oModel:CommitData()	
				_cContent := '{"Cadastro realizado"}'
			Else	
				_cContent := '{"Erro":"'
				_cContent += _oModel:GetErrorMessage()[6]
				_cContent += '"}'
			EndIf	
				
			_oModel:DeActivate()
			
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
/*/
