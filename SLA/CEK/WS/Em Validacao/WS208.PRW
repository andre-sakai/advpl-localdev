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

WSRESTFUL WS208 DESCRIPTION "Financeiro" 									 

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 
WSDATA CDTFILTRO AS STRING OPTIONAL 

WSDATA CWSEMP AS STRING OPTIONAL 
WSDATA CWSFIL AS STRING OPTIONAL 

WSDATA CWSDIC AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta Financeiro" WSSYNTAX "/rest/WS208 || /rest/WS208/{FILIAL}/{PREFIXO}/{NUMERO} || /rest/WS208/{FILIAL}/{SERIE}/{NOTA}"
//WSMETHOD POST DESCRIPTION "Inclusão de Pedido de Venda" WSSYNTAX "/rest/WS208"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS208

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
Local _cCodFil,_cCodPed,_cCodSerie,_cCodNum,_cCodCli,_cCodLoja, _cSql
Local _aValidf2 := {},_aValidd2 := {}


Private _aValid := {}


Default _cCodFil:=''
Default _cCodPed:=''

Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''
Default SELF:CDTFILTRO	:=''

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

If Len(::aURLParms) = 0

ElseIf Len(::aURLParms) = 2

	_cCodCli := padr(::aURLParms[1],tamsx3('E1_CLIENTE')[1])
	
	IF(LEN(::aURLParms)>=2)
		_cCodLoja := padr(::aURLParms[2],tamsx3('E1_LOJA')[1])
	ENDIF
	
ElseIf Len(::aURLParms) = 3
	// insira aqui o código para pesquisa do parametro recebido
	// consulta de cliente por documento
	_cCodFil := padr(::aURLParms[1],tamsx3('E1_FILIAL')[1])
	
	IF(LEN(::aURLParms)>=2)
		_cCodSerie := padr(::aURLParms[2],tamsx3('E1_PREFIXO')[1])
	ENDIF
	IF(LEN(::aURLParms)>=3)
		_cCodNum := padr(::aURLParms[3],tamsx3('E1_NUM')[1])
	ENDIF
Else
		
	::SetResponse('WS208 - Parametros inválidos, deve ser informado Cliente e Loja ou Filial serie e Nota')
	SetRestFault(499,'WS208 - Parametros inválidos, deve ser informado Cliente e Loja ou Filial serie e Nota')		
	Return .F.
EndIf
_cAlias := getnextalias()
_cAlias2 := getnextalias()

cQry:=''
cQry+="%"
cQry+= " AND E1_FILIAL='"+XFILIAL('SE1')+"' "
If(!empty(_cCodSerie))
	cQry+= " AND E1_PREFIXO='"+_cCodSerie+"' "
EndIf
If(!empty(_cCodNUM))
	cQry+= " AND E1_NUM='"+_cCodNUM+"' "
EndIf
If(!empty(_cCodCli))
	cQry+= " AND E1_CLIENTE='"+_cCodCli+"' "
EndIf
If(!empty(_cCodLoja))
	cQry+= " AND E1_LOJA='"+_cCodLoja+"' "
EndIf
If(!empty(SELF:cFiltro))
	cQry+= " AND " + SELF:cFiltro + " "
ELSE
	cQry+= " AND E1_EMISSAO >= '20180101' "

EndIf
cQry+="%"
conout('ws208')

IF(SE1->(FIELDPOS('E1_USERLGA')))
	
	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		COLUMN E1_EMISSAO AS DATE
		SELECT ROW_NUMBER() OVER(ORDER BY E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO) REG,
				CASE 	WHEN E1_USERLGA = ' ' 
						THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGI,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
						ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGA,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) 
				END DTLGA,  *,
				SE1.R_E_C_N_O_ RECSE1  FROM %TABLE:SE1% SE1
		WHERE SE1.D_E_L_E_T_='' %EXP:cQry%
		ORDER BY E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO
	ENDSQL
ELSE


	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		COLUMN E1_EMISSAO AS DATE
		SELECT ROW_NUMBER() OVER(ORDER BY E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO) REG,
				 *,
				SE1.R_E_C_N_O_ RECSE1  FROM %TABLE:SE1% SE1
		WHERE SE1.D_E_L_E_T_='' %EXP:cQry%
		ORDER BY E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO
	ENDSQL
ENDIF
_cSql := getlastquery()[2]

(_cAlias)->(DBGoTop())
count to _nReg 
	
_nIni := ( 1 + ((SELF:NPAGINA -1) * SELF:NREGISTRO ))
_nFim := (SELF:NPAGINA * SELF:NREGISTRO)
	
SET FILTER TO REG >= _nIni .and. REG <=_nFim
	
conout('ws208 - query',_cSql)
(_cAlias)->(DBGOTOP())
_aValidE1 := U_WSCAMPOS(SELF:CTIPO,'SE1')
_aValidE5 := U_WSCAMPOS(SELF:CTIPO,'SE5')


// define o tipo de retorno do método
IF(!(_cAlias)->(EOF()))

	::SetResponse('{"REGISTROS":[')
	Do While !(_cAlias)->(Eof())
	    dbselectarea(_cAlias)
	    //Contador para inserir separador do json
	    If nPrimeiro>0
	     ::SetResponse(',')
	    EndIf
	    nPrimeiro+= 1
//		cChave:= (_cAlias)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)
		::SetResponse('{')
		::SetResponse('"REG_NUM":'+cvaltochar((_cAlias)->REG)+',')
		::SetResponse('"CHAVE_CLIENTE":"'+cvaltochar((_cAlias)->E1_CLIENTE+E1_LOJA)+'",')
		::SetResponse('"CHAVE":"'+(_cAlias)->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)+'",')
		If((_cAlias)->(fieldpos('RECSE1')))
			::SetResponse('"RECNO":'+cvaltochar((_cAlias)->RECSE1)+',')
		EndIf
		If((_cAlias)->(fieldpos('DTALT')))
			::SetResponse('"DTALT":"'+(_cAlias)->DTLGA+'",')
		EndIf

		_aValid := _aValidE1
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
		
		IF(SELECT(_cAlias2)>0)
			(_cAlias2)->(dbclosearea())
		ENDIF

		::SetResponse(',"BAIXAS":[')
		
		_cQry2 := "% AND E5_PREFIXO='"+(_cAlias)->E1_PREFIXO+"' AND E5_NUMERO='"+(_cAlias)->E1_NUM+"'  AND E5_PARCELA='"+(_cAlias)->E1_PARCELA+"' AND E5_TIPO='"+(_cAlias)->E1_TIPO+"' AND E5_CLIENTE='"+(_cAlias)->E1_CLIENTE+"' AND E5_LOJA='"+(_cAlias)->E1_LOJA+"' %"

		BEGINSQL ALIAS _cAlias2
			%NOPARSER%
			COLUMN E5_DATA AS DATE
			SELECT ROW_NUMBER() OVER(ORDER BY E5_PREFIXO,E5_NUMERO,E5_PARCELA,E5_TIPO ASC) REG, * FROM %TABLE:SE5% SE5
			WHERE SE5.D_E_L_E_T_='' %EXP:_cQry2%
			ORDER BY E5_PREFIXO,E5_NUMERO,E5_PARCELA,E5_TIPO
		ENDSQL
			
		//Lista de itens
		While !(_cAlias2)->(Eof()) 
			::SetResponse('{')
			_aValid := _aValidE5
			DbSelectArea(_cAlias2)
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
					::SetResponse('"'+_aValid[_nI,1]+'":"'+dtos(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))			
				ElseIf(_aValid[_nI,3]=='N')
					::SetResponse('"'+_aValid[_nI,1]+'":'+alltrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
				EndIf
				
			Next		
			::SetResponse('}')
			(_cAlias2)->(DBSkip())
			//Verifica se continua no mesmo pedido
			If !(_cAlias2)->(Eof())
				::SetResponse(',')   
			EndIf
		EndDo
		(_cAlias2)->(DBCloseArea())
		
		::SetResponse(']') //FECHA BAIXAS
		::SetResponse('}') //FECHA PEDIDO
		
		(_cAlias)->(DBSkip())
	EndDo
	::SetResponse(']') //FECHA rEGISTROS
	::SetResponse(', "QUANTIDADE":'+CVALTOCHAR(_nReg))
	::SetResponse(', "PAGINA":'+CVALTOCHAR(SELF:NPAGINA))
	If(SELF:CWSDIC=='S')
	::SetResponse(',"DICIONARIO":{')
		::SetResponse('"TITULO":[')
		_aValid := _aValidE1
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
		::SetResponse('"BAIXAS":[')
		_aValid := _aValidE5
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
	endif
	::SetResponse('}')//FECHA PEDIDOS
	
	(_cAlias)->(DBCLOSEAREA())
Else
	::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado!"}')
	SetRestFault(402,'Nenhum cadastro encontrado, verifique as informações enviadas!')		
	Return _lRet

EndIf



If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return .T.