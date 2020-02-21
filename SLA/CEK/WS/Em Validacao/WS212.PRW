#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"
#include "tbiconn.ch"
#include "topconn.ch"


// ##############################################################################
// Projeto  : CEK
// Autor    : ANDRE SAKAI
// Modulo   : WS
// Função   : WS205 - CADASTRO DE TITULOS FINANCEIRO
// Descrição: WS PARA CONSULTA DE TITULOS FINANCEIRO
// Retorno  : REST COM AS INFORMAÇÕES DA TABELA SE1,SE5
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

WSRESTFUL WS212 DESCRIPTION "Financeiro - Resumo" 									 

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 
WSDATA CDTFILTRO AS STRING OPTIONAL 

WSDATA CWSEMP AS STRING OPTIONAL 
WSDATA CWSFIL AS STRING OPTIONAL 

WSDATA CWSDIC AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta Financeiro - Versao 200219.001" WSSYNTAX "/rest/WS212 || /rest/WS212/{FILIAL}/{Cliente}/{Loja} "
//WSMETHOD POST DESCRIPTION "Inclusão de Pedido de Venda" WSSYNTAX "/rest/WS208"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS212

Local _cVldTkn := ''
Local _lRet := .F.
Local _cCod := ''
Local _nI,_nJ,_nReg
Local _lPrepEnv := .F.
LOCAL cQuery := ""
LOCAL cChave := ""
LOCAL nPrimeiro := 0
Local _cAlias
Local _cAlias2
Local _cCodCli,_cCodLoja
Local _cCodFil,_cCodPed,_cCodSerie,_cCodNum, _cSql
Local _aValidf2 := {},_aValidd2 := {}


Private _aValid := {}

Default SELF:cTipo :=''
Default SELF:cFiltro := '' 

Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''
Default SELF:CDTFILTRO 	:=''

Default SELF:CWSEMP := '01'
Default SELF:CWSFIL := '0101'
Default SELF:CWSDIC := 'N'

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "","","","",{"SA1","SA2","SA3","SA4", "SC5","SC6", "SF2","SD2", "SE1","SE2"}) 
	_lPrepEnv := .T.
EndIf



::SetContentType("application/json")

_cVldTkn := ALLTRIM(GETMV('MV_TKNREST',.T.,'123456'))

If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verifique a chave! '+SELF:pToken)
	Return .F.
Else
	//conout('','Token Ok')
EndIf

If Len(::aURLParms) > 0

	If(Len(::aURLParms) = 2)
		_cCodCli 	:= padr(::aURLParms[1],tamsx3('E1_CLIENTE')[1])
		_cCodLoja	:= padr(::aURLParms[2],tamsx3('E1_LOJA')[1])
	Else
		// insira aqui o código para pesquisa do parametro recebido
		// consulta de cliente por documento
		_cCodFil := padr(::aURLParms[1],tamsx3('E1_FILIAL')[1])
		
		If(Len(::aURLParms)>=2)
			_cCodSerie := padr(::aURLParms[2],tamsx3('E1_PREFIXO')[1])
		EndIf
		If(Len(::aURLParms)>=3)
			_cCodNum := padr(::aURLParms[3],tamsx3('E1_NUM')[1])
		EndIf	
	EndIf

EndIf
_cAlias := getnextalias()
_cAlias2 := getnextalias()

cQry:=''
cQry+="%"
cQry+= " AND E1_FILIAL='"+XFILIAL('SE1')+"' "
If(!Empty(_cCodSerie))
	cQry+= " AND E1_PREFIXO='"+_cCodSerie+"' "
EndIf
If(!Empty(_cCodNUM))
	cQry+= " AND E1_NUM='"+_cCodNUM+"' "
EndIf
If(!Empty(_cCodCli) .and. !empty(_cCodLoja))
	cQry+= " AND E1_CLIENTE='"+_cCodCli+"' AND E1_LOJA='"+_cCodLoja+"'"
EndIf
If(!Empty(SELF:cFiltro))
	cQry+= SELF:cFiltro
ELSE
	cQry+= " AND E1_EMISSAO >= '20180101' "

EndIf
cQry+="%"

_cDataAt := dtos(date())

BEGINSQL ALIAS _cAlias
	%NOPARSER%
	SELECT 	SUM( CASE WHEN E1_VENCREA <  %EXP:_cDataAt% THEN E1_SALDO ELSE 0 END) ATRASADOS,
			SUM (CASE WHEN E1_VENCREA >= %EXP:_cDataAt% THEN E1_SALDO ELSE 0 END) FUTUROS,
			SUM (CASE WHEN E1_SALDO >0 THEN E1_SALDO ELSE 0 END) ABERTOS, E1_CLIENTE, E1_LOJA
	FROM %TABLE:SE1% SE1
	WHERE SE1.D_E_L_E_T_='' %EXP:cQry%
	GROUP BY E1_CLIENTE, E1_LOJA
	ORDER BY E1_CLIENTE, E1_LOJA
ENDSQL

_cSql := getlastquery()[2]
CONOUT('WS012',_cSql)
(_cAlias)->(DBGOTOP())
_aValidRF := U_WSCAMPOS(SELF:CTIPO,'RES_FIN_REC')


// define o tipo de retorno do método
IF(!(_cAlias)->(EOF()))

	::SetResponse('{"REGISTROS":{')
	Do While !(_cAlias)->(Eof())
	    DBSELECTAREA(_cAlias)
	    //Contador para inserir separador do json
	    If nPrimeiro>0
	     ::SetResponse(',')
	    EndIf
	    nPrimeiro+= 1
//		cChave:= (_cAlias)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)
		::SetResponse('{')
		_aValid := _aValidRF
		For _nI := 1 to len(_aValid)
			If(_aValid[_nI,3]=='C')
				::SetResponse('"'+_aValid[_nI,1]+'":"'+alltrim(NOACENTO(&(_aValid[_nI,5])))+'"'+iif(_nI<len(_aValid),',',''))
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
		::SetResponse('}') //FECHA PEDIDO
		
		(_cAlias)->(DBSkip())
	EndDo
	::SetResponse('}')//FECHA PEDIDOS
	
	(_cAlias)->(DBCLOSEAREA())
Else
	::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado!"}')
	SetRestFault(402,noacento('Nenhum cadastro encontrado, verifique as informações enviadas!')+_cSql)		
	Return _lRet

EndIf



If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return .T.
 
 /*/
WSMETHOD POST WSSERVICE WS208
Local _lRet := .T.
Local _nI,_nJ,_nReg
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
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verifique a chave! '+SELF:pToken)
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

_aValid := U_WS002SA1()

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

	::SetResponse('["mensagem":[')
	If (Len(_aRetError) = 0)
		_oModel := FWLoadModel("MATA030")
		_cModel := "MATA030_SA1"
		//varinfo('_oModel',_oModel)
		//conout('MODEL_OPERATION_INSERT',MODEL_OPERATION_INSERT)
		//conout('MODEL_OPERATION_UPDATE',MODEL_OPERATION_UPDATE)
			
		If(Type('_oClient:CODIGO')<>'U' .and. Type('_oClient:LOJA')<>'U')
			SA1->(DBSetOrder(1))
			If(!SA1->(MsSeek(xFilial("SA1")+ALLTRIM(_oClient:CODIGO)+ALLTRIM(_oClient:LOJA),.T.)))
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
				WHERE A1_FILIAL=%EXP:FWFILIAL('SA1')% A1_COD=%EXP:_oClient:LOJA% AND SA1.%NOTDEL%
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
			_oModel:SetValue(_cModel,"A1_COD",GETSXENUM('SA1','A1_COD'))	
			_oModel:SetValue(_cModel,"A1_LOJA","01")	
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
			_oModel := FWLoadModel("MATA030")
			_cModel := "MATA030_SA1"
			
			If(Type('_oClient:CODIGO')<>'U' .and. Type('_oClient:LOJA')<>'U')
				SA1->(DBSetOrder(1))
				If(!SA1->(MsSeek(xFilial("SA1")+ALLTRIM(_oClient:CODIGO)+ALLTRIM(_oClient:LOJA),.T.)))
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
	::SetResponse("]]")
EndIf

If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return _lRet

/*/