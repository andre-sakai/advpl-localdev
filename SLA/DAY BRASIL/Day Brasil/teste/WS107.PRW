#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"
#include "tbiconn.ch"
#include "topconn.ch"

// ##############################################################################
// Projeto  : Day-Brasil
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


WSRESTFUL WS107 DESCRIPTION "Faturamento"

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 
WSDATA CTESTE AS STRING OPTIONAL 
WSDATA CDTFILTRO AS STRING OPTIONAL 
WSDATA CPEDIDO AS STRING OPTIONAL 

WSDATA CWSEMP AS STRING OPTIONAL 
WSDATA CWSFIL AS STRING OPTIONAL 

WSDATA CWSDIC AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta Faturamento - Versao 02/03/2020" WSSYNTAX "/rest/WS107 || /rest/WS107/{pedido}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS107

Local _cVldTkn := ''
Local _lRet := .F.
Local _nI,_nJ,_nReg
Local _lPrepEnv := .F.
LOCAL cChave := ""
LOCAL nPrimeiro := 0
Local _cAlias
Local _cCodFil,_cCodPed
Local _aValidf2 := {},_aValidd2 := {}

Private _aValid := {}

Default SELF:cTipo :=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''
Default SELF:CTESTE 	:=''
Default SELF:CDTFILTRO 	:=''
Default SELF:cPedido := '' 
Default _cCodFil:=''
Default _cCodPed:=SELF:cPedido

DEFAULT SELF:CWSEMP := '01'
DEFAULT SELF:CWSFIL := '01'
DEFAULT SELF:CWSDIC := 'N'

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "","","","",{"SA1","SA2","SA3","SA4", "SC5","SC6", "SF2","SD2", "SE1","SE2"}) 
	_lPrepEnv := .T.
EndIf

_nJ := 0

::SetContentType("application/json")

_cVldTkn := ALLTRIM(GETMV('DY_TNKDEPS',.T.,'123456'))

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
Else
	SetRestFault(499,'Parametros inválidos. Favor informar Filial('+xFilial('SF2')+')/Pedido!')
	Return .F.
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

	SELECT * FROM %TABLE:SF2% SF2 WITH (NOLOCK)
	INNER JOIN %TABLE:SD2% SD2 WITH (NOLOCK) ON D2_FILIAL=F2_FILIAL AND D2_DOC=F2_DOC AND F2_SERIE=D2_SERIE 
							AND F2_EMISSAO = D2_EMISSAO AND SD2.%NOTDEL% 
	WHERE SF2.D_E_L_E_T_='' %EXP:cQry%
	ORDER BY D2_SERIE,D2_DOC,D2_ITEM
	
ENDSQL

_cSql := GETLASTQUERY()[2]

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
_aValidF2 := U_WS2CAMPOS(SELF:CTIPO,'SF2')
_aValidD2 := U_WS2CAMPOS(SELF:CTIPO,'SD2')


// define o tipo de retorno do método
IF(!(_cAlias)->(EOF()))

	::SetResponse('{')
	IF(SELF:CTESTE='SQL')
		::SetResponse('"SQL":"'+STRTRAN(STRTRAN(_cSql,'	',''),'"','')+'",')
	ENDIF
	::SetResponse('"REGISTROS":[')
	Do While !(_cAlias)->(Eof())
	    
	    //Contador para inserir separador do json
	    If nPrimeiro>0
	     ::SetResponse(',')
	    EndIf
	    nPrimeiro+= 1
		cChave:= (_cAlias)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)
		::SetResponse('{')
		_aValid := _aValidF2
		If((_cAlias)->(FIELDPOS('DTLGA'))>0)
			::SetResponse('"DTALT":"'+(_cAlias)->DTLGA+'",')
		EndIf	
		For _nI := 1 to len(_aValid)
			If(_aValid[_nI,3]=='C')
				::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(STRTRAN(STRTRAN(noacento(&(_aValid[_nI,5])),'"',''),'	',''))+'"'+iif(_nI<len(_aValid),',',''))
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
				
		::SetResponse(', "ITENS":[')			
		//Lista de itens
		Do While !(_cAlias)->(Eof()) .And. ;
		  cChave == (_cAlias)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)		
			::SetResponse('{')
			_aValid := _aValidD2
			For _nI := 1 to len(_aValid)
				If(_aValid[_nI,3]=='C')
					::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(STRTRAN(noacento(&(_aValid[_nI,5])),'"',''))+'"'+iif(_nI<len(_aValid),',',''))
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
	
	::SetResponse(', "QUANTIDADE":'+CVALTOCHAR(_nReg))
	::SetResponse(', "PAGINA":'+CVALTOCHAR(SELF:NPAGINA))
	If(SELF:CWSDIC=='S')
		::SetResponse('"NOTA":[')
		_aValid := _aValidF2
		For _nI := 1 to len(_aValid)
			If(_nI != 1)
				::SetResponse(",")
			EndIf
			::SetResponse("{")
			::SetResponse(',"CAMPO":"'+_aValid[_nI,1]+'"')
			::SetResponse(',"TIPO":"'+_aValid[_nI,3]+'"')
			::SetResponse(',"TAM":'+CVALTOCHAR(_aValid[_nI,4])+'')
			::SetResponse(',"DESCRICAO":"'+AllTrim(STRTRAN(noacento(_aValid[_nI,7]),'"',''))+'"')
			If(!Empty(_aValid[_nI,6]))
				::SetResponse(', "OPCOES":"'+_aValid[_nI,6]+'"')
			EndIf
			::SetResponse("}")
		Next		
		::SetResponse(']')
		::SetResponse(',"ITENS":[')
		_aValid := _aValidD2
		For _nI := 1 to len(_aValid)
			If(_nI != 1)
				::SetResponse(",")
			EndIf
			::SetResponse("{")
			::SetResponse('"CAMPO":"'+_aValid[_nI,1]+'",')
			::SetResponse('"TIPO":"'+_aValid[_nI,3]+'",')
			::SetResponse('"TAM":'+CVALTOCHAR(_aValid[_nI,4])+',')
			::SetResponse('"DESCRICAO":"'+AllTrim(STRTRAN(noacento(_aValid[_nI,7]),'"',''))+'"')
			If(!Empty(_aValid[_nI,6]))
				::SetResponse(', "OPCOES":"'+_aValid[_nI,6]+'"')
			EndIf
			::SetResponse("}")
		Next		
		::SetResponse(']')
		::SetResponse('}')//FECHA DICIONARIO
	endif
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
