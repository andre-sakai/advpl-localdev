#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

WSRESTFUL WS006 DESCRIPTION "Cadastro de Clientes"

WSDATA PTOKEN AS STRING 
WSDATA NPAGINA AS STRING OPTIONAL 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA DATADE AS DATE OPTIONAL

WSMETHOD GET DESCRIPTION "Consulta Pedido de Vendas" WSSYNTAX "/rest/WS006 || /rest/WS006/{pedido}"
WSMETHOD POST DESCRIPTION "Inclusão de Pedido de Vendas" WSSYNTAX "/rest/WS006"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS006

Local _aValid := {}
Local _cVldTkn := ''
Local _lRet := .F.
Local _cDoc := ''
Local _nI := 0
Local _lPrepEnv := .F.
LOCAL cQuery := ""
LOCAL cChave := ""
LOCAL nPrimeiro := 0

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv('01','0101', "","","","",{"SA1","SA2","SA3","SA4", "SC5","SC6"}) 
	_lPrepEnv := .T.
EndIf

Default SELF:cTipo=' '

cQuery:= "SELECT * FROM "+RetSQLName("SC5")+ " SC5, "+RetSQLName("SC6")+ " SC6"
cQuery+= " WHERE "
cQuery+= "SC5.D_E_L_E_T_ != '*' "
cQuery+= "AND SC6.D_E_L_E_T_ != '*' "
cQuery+= "AND C5_FILIAL = C6_FILIAL "
cQuery+= "AND C5_NUM =  C6_NUM "
cQuery+= "AND C5_EMISSAO >= '20191101' "
If Select("TRBPED") <> 0
   DBSelectArea("TRBPED")
   DBCloseArea()
EndIf
DBUseArea(.T.,"TOPCONN",TCGenQry(NIL,NIL,cQuery),"TRBPED",.F.,.T.)


// define o tipo de retorno do método
::SetContentType("application/json")

_cVldTkn := ALLTRIM(GETMV('MV_TKNREST',.T.,'123456'))
::SetResponse('[')
Do While !TRBPED->(Eof())
    
    //Contador para inserir separador do json
    If nPrimeiro>0
     ::SetResponse(',')
    EndIf
    nPrimeiro+= 1
    
	cChave:= TRBPED->(C5_FILIAL+C5_NUM)
	::SetResponse('{')
			::SetResponse('"C5_FILIAL":"'+TRBPED->C5_FILIAL+'",')
			::SetResponse('"C5_NUM":"'+TRBPED->C5_NUM+'",')
			::SetResponse('"C5_CLIENTE":"'+TRBPED->C5_CLIENTE+'",')
			::SetResponse('"C5_LOJACLI":"'+TRBPED->C5_LOJACLI+'",')
			::SetResponse('"C5_CLIENT":"'+TRBPED->C5_CLIENT+'",')
			::SetResponse('"C5_LOJAENT":"'+TRBPED->C5_LOJAENT+'",')
			::SetResponse('"C5_TRANSP":"'+TRBPED->C5_TRANSP+'",')
			//::SetResponse('"'+'C5_CONPAG'+'":"'+TRBPED->C5_CONPAG+'",')
			::SetResponse('"'+'C5_TABELA":"'+TRBPED->C5_TABELA+'",')
			::SetResponse('"'+'C5_VEND1":"'+TRBPED->C5_VEND1+'",')
			::SetResponse('"'+'C5_EMISSAO":"'+TRBPED->C5_EMISSAO+'",')
//			::SetResponse('"'+'C5_FRETE'+'":"'+TRBPED->C5_FRETE+'",')	
//			::SetResponse('"'+'C5_FRETE'+'":"'+TRBPED->C5_FRETE+'",')
			
			::SetResponse('"ITENS":')			
	//Lista de itens
	::SetResponse('[')
	Do While !TRBPED->(Eof()) .And. ;
	  cChave == TRBPED->(C5_FILIAL+C5_NUM)		
		::SetResponse('{')
			::SetResponse('"C6_ITEM":"'+TRBPED->C6_ITEM   +'",')
			::SetResponse('"C6_PRODUTO":"'+TRBPED->C6_PRODUTO+'"')
			::SetResponse('"C6_QTDVEN":'+cValToChar(TRBPED->C6_QTDVEN)+',')
			::SetResponse('"C6_PRCVEN":'+cValToChar(TRBPED->C6_PRCVEN) +',')
			::SetResponse('"C6_VALOR":'+cValToChar(TRBPED->C6_VALOR)+',')
			::SetResponse('"C6_QTDLIB":'+cValToChar(TRBPED->C6_QTDLIB))
		::SetResponse('}')
		
		TRBPED->(DBSkip())
		//Verifica se continua no mesmo pedido
		If !TRBPED->(Eof()) .And.  cChave == TRBPED->(C5_FILIAL+C5_NUM)
			::SetResponse(',')    
		EndIf
	EndDo
	::SetResponse(']')

	::SetResponse('}')
	//TRBPED->(DBSkip())
EndDo
::SetResponse(']')



If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return .T.
 
 
WSMETHOD POST WSSERVICE WS006
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

