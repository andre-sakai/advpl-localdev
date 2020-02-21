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
// Função   : WS205 - CADASTRO DE NOTAS FISCAIS
// Descrição: WS PARA CONSULTA DE NOTAS FISCAIS
// Retorno  : REST COM AS INFORMAÇÕES DA TABELA SF2,SD2
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------


WSRESTFUL WS207 DESCRIPTION "Faturamento"									 

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 
WSDATA CDTFILTRO AS STRING OPTIONAL 
WSDATA CPEDIDO AS STRING OPTIONAL 

WSDATA CWSEMP AS STRING OPTIONAL 
WSDATA CWSFIL AS STRING OPTIONAL 

WSDATA CWSDIC AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta Faturamento - Mercos" WSSYNTAX "/rest/WS207 || /rest/WS207/{pedido}"
//WSMETHOD POST DESCRIPTION "Inclusão de Pedido de Venda" WSSYNTAX "/rest/WS207"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS207

Local _cVldTkn := ''
Local _lRet := .F.
Local _cCod := ''
Local _nI,_nJ,_nReg
Local _lPrepEnv := .F.
LOCAL cQuery := ""
LOCAL cChave := ""
LOCAL nPrimeiro := 0
Local _cAlias
Local _cCodFil,_cCodPed
Local _aValidf2 := {},_aValidd2 := {}
Local _cAlias

Private _aValid := {}

Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''
Default SELF:CDTFILTRO 	:=''
Default SELF:cPedido := '' 
Default _cCodFil:=''
Default _cCodPed:=SELF:cPedido

DEFAULT SELF:CWSEMP := '01'
DEFAULT SELF:CWSFIL := '0101'
DEFAULT SELF:CWSDIC := 'N'

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
	// insira aqui o código para pesquisa do parametro recebido
	// consulta de cliente por documento
	_cCodFil := padr(::aURLParms[1],tamsx3('F2_FILIAL')[1])
	
	IF(LEN(::aURLParms)>=2)
		_cCodPed := padr(::aURLParms[2],tamsx3('C5_NUM')[1])
	ENDIF
EndIf

_cAlias := getnextalias()

cQry:=''
cQry+="%"
If(!empty(_cCodFil))
	cQry+= " AND F2_FILIAL='"+_cCodFil+"' "
Else
	cQry+= " AND F2_FILIAL='"+XFILIAL('SF2')+"' "
EndIf
If(!empty(_cCodPed))
	cQry+= " AND D2_PEDIDO='"+_cCodPed+"' "
EndIf
If(!empty(SELF:cFiltro))
	cQry+= SELF:cFiltro
ELSE
	cQry+= " AND F2_EMISSAO >= '20190101' "

EndIf
cQry+="%"

BEGINSQL ALIAS _cAlias
	%NOPARSER%
	COLUMN F2_EMISSAO AS DATE

	SELECT * FROM %TABLE:SF2% SF2
	INNER JOIN %TABLE:SD2% SD2 ON D2_FILIAL=F2_FILIAL AND D2_DOC=F2_DOC AND F2_SERIE=D2_SERIE 
							AND F2_EMISSAO = D2_EMISSAO AND SD2.%NOTDEL% 
	WHERE SF2.D_E_L_E_T_='' %EXP:cQry%
	ORDER BY D2_SERIE,D2_DOC,D2_ITEM
	
ENDSQL

///CONOUT(GETLASTQUERY()[2])

/*
cQuery:= " SELECT * FROM "+RetSQLName("SC5")+ " SC5 "
cQuery+= " SELECT * FROM "+RetSQLName("SC5")+ " SC5 "
cQuery+= " INNER JOIN "+RetSQLName("SC6")+ " SC6 ON C5_FILIAL = C6_FILIAL AND C5_NUM =  C6_NUM  AND SC6.D_E_L_E_T_ != '*' "
cQuery+= " WHERE "
If(!empty(_cCodFil))
	cQuery+= " C5_FILIAL='"+_cCodFil+"' AND "
Else
	cQuery+= " C5_FILIAL='"+XFILIAL('SC5')+"' AND "
EndIf
If(!empty(_cCodPed))
	cQuery+= " C5_NUM='"+_cCodPed+"' AND "
EndIf
cQuery+= " C5_EMISSAO >= '20191101' AND  "
cQuery+= " SC5.D_E_L_E_T_ != '*'"
If Select(_cAlias) <> 0
   DBSelectArea(_cAlias)
   (_cAlias)->(DBCloseArea())
EndIf
DBUseArea(.T.,"TOPCONN",TCGenQry(NIL,NIL,cQuery),_cAlias,.F.,.T.)*/
(_cAlias)->(DBGOTOP())
_aValidF2 := U_WSCAMPOS(SELF:CTIPO,'SF2')
_aValidD2 := U_WSCAMPOS(SELF:CTIPO,'SD2')


// define o tipo de retorno do método
IF(!(_cAlias)->(EOF()))

	::SetResponse('{"REGISTROS":[')
	Do While !(_cAlias)->(Eof())
	    
	    //Contador para inserir separador do json
	    If nPrimeiro>0
	     ::SetResponse(',')
	    EndIf
	    nPrimeiro+= 1
		cChave:= (_cAlias)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)
		::SetResponse('{')
		_aValid := _aValidF2
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
				
		::SetResponse('", ITENS":[')			
		//Lista de itens
		Do While !(_cAlias)->(Eof()) .And. ;
		  cChave == (_cAlias)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)		
			::SetResponse('{')
			_aValid := _aValidD2
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
			
			(_cAlias)->(DBSkip())
			//Verifica se continua no mesmo pedido
			If !(_cAlias)->(Eof()) .And.  cChave == (_cAlias)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)
				::SetResponse(',')    
			Else
				::SetResponse(']')
			EndIf
		EndDo
		::SetResponse('}') //FECHA PEDIDO
		//(_cAlias)->(DBSkip())
	EndDo
	::SetResponse('"QUANTIDADE":,')
	::SetResponse('"PAGINA":,')
	::SetResponse('"DICIONARIO":{')
		::SetResponse('"NOTA":[')
		_aValid := _aValidF2
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
		::SetResponse('],')
		::SetResponse('"ITENS":[')
		_aValid := _aValidD2
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
		::SetResponse(']')
	::SetResponse('}')//FECHA DICIONARIO
	::SetResponse('}')//FECHA PEDIDOS
	
	(_cAlias)->(DBCLOSEAREA())
ELSE
	::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado!"}')
	SetRestFault(402,'Nenhum cadastro encontrado, verifique as informações enviadas!')		
	Return _lRet

ENDIF



If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return .T.
 
/*/
WSMETHOD POST WSSERVICE WS207
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