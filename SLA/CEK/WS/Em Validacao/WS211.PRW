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
// Função   : WS205 - CADASTRO DE TABELA DE PRECO
// Descrição: WS PARA CONSULTA DE TABELA DE PRECO
// Retorno  : REST COM AS INFORMAÇÕES DA TABELA DA0,DA1
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

WSRESTFUL WS211 DESCRIPTION "TABELA DE PRECO - ITEM" 


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

WSMETHOD GET DESCRIPTION "Consulta Tabela de Preço - Item" WSSYNTAX "/rest/WS211 || /rest/WS211/{codigo}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS211

Local _cVldTkn := ''
Local _lRet := .F.
Local _nI := 0,_nReg := 0,_nIni := 0,_nFim := 0
Local _lPrepEnv := .F.
Local nPrimeiro := 0
Local _cAlias
Local _cCodigo,_cCodPro, _cSql
Local _aValid, _aValidD1
Local _dFiltro

Private _aValid := {}

Default _cCodigo:=''
Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''
Default SELF:CDTFILTRO 	:=''
Default SELF:CTESTE 	:=''

DEFAULT SELF:CWSEMP := '01'
DEFAULT SELF:CWSFIL := '0101'
DEFAULT SELF:CWSDIC := 'N'

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "","","","",{"SB1"}) 
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
	_cCodigo := padr(::aURLParms[1],tamsx3('DA0_CODTAB')[1])
	If Len(::aURLParms) >= 2
		_cCodPro := padr(::aURLParms[2],tamsx3('DA1_CODPRO')[1])
	EndIf
Else
	_cCodigo := ''
EndIf
_cAlias := getnextalias()

_dFiltro :=SELF:CDTFILTRO

cQry:=''
cQry+="%"
cQry+= " AND DA1_FILIAL='"+XFILIAL('DA1')+"' "
If(!empty(SELF:cFiltro))
	cQry+= " AND " + SELF:cFiltro
EndIf
IF(!EMPTY(_cCodigo))
	cQry+= " AND DA1_CODTAB='" + _cCodigo + "' "
ENDIF
IF(!EMPTY(_cCodPro))
	cQry+= " AND DA1_CODPRO='" + _cCodPro + "' "
ENDIF
	
If(!EMPTY(SELF:CDTFILTRO))
	IF(!empty(cQry))
		cQry += " AND "
	ENDIF
	cQry += " CASE WHEN DA1_USERGA != ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(DA1_USERGA,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(DA1_USERGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) WHEN DA1_USERGI != ' ' THEN CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(DA1_USERGI,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(DA1_USERGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120) ELSE '          ' END >= '"+SELF:CDTFILTRO+"' "
EndIf

cQry+="%"

BEGINSQL ALIAS _cAlias
	%NOPARSER%
	SELECT 	ROW_NUMBER() OVER(ORDER BY DA1_CODTAB,DA1_ITEM ASC) REG,* ,
			CASE WHEN DA1_USERGA != ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(DA1_USERGA,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(DA1_USERGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
				WHEN DA1_USERGI != ' ' THEN CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(DA1_USERGI,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(DA1_USERGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
				ELSE '          ' END DTLGA
	FROM %TABLE:DA1% DA1
	INNER JOIN %TABLE:DA0% DA0 ON DA1_CODTAB=DA0_CODTAB AND DA1_FILIAL=DA0_FILIAL AND DA0.D_E_L_E_T_=''
	WHERE DA1.D_E_L_E_T_='' %EXP:cQry%
	ORDER BY DA1_CODTAB,DA1_ITEM
ENDSQL
/*/
ROW_NUMBER() OVER(ORDER BY A1_COD ASC) REG, 
		CASE WHEN A1_USERGA = ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERGI,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
		ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERGA,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) END DTLGA, 
		A1_WSDTALT DTWSALT, *
/*/

(_cAlias)->(DBGoTop())
count to _nReg 
(_cAlias)->(DBGOTOP())


_aValidD1 := U_WSCAMPOS(SELF:CTIPO,'DA1')

dbselectarea(_cAlias)
_nIni := ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO )
_nFim := (SELF:NPAGINA * SELF:NREGISTRO)

SET FILTER TO REG >=_nIni .AND. REG <= _nFim

conout("filtro ws211 - REG BETWEEN '"+CVALTOCHAR(_nIni)+"' AND '"+CVALTOCHAR(_nFim)+"' ")
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
		IF((_cAlias)->(FIELDPOS("DTALT")>0))
			::SetResponse('"DTALT":"'+(_cAlias)->DTLGA+'",')
		ENDIF
		IF((_cAlias)->(FIELDPOS("DTWSALT")>0))
			::SetResponse('"DTHALT":"'+(_cAlias)->DTWSALT+'",')
		ENDIF
		_aValid := _aValidD1
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
			::SetResponse('"TABELA_ITEM":[')
			_aValid := _aValidD1
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
	EndIf
	::SetResponse('}')//FECHA PRODUTOS
	
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

