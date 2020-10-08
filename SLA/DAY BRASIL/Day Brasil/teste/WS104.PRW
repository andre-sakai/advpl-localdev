#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

// ##############################################################################
// Projeto  : Day-Brasil
// Autor    : ANDRE SAKAI
// Modulo   : WS
// Função   : WS104 - CADASTRO DE TRANSPORTADORAS
// Descrição: WS PARA CONSULTA DE TRANSPORTADORAS
// Retorno  : REST COM AS INFORMAÇÕES DA TABELA SA4
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

WSRESTFUL WS104 DESCRIPTION "Cadastro de Transportadoras"

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
WSMETHOD GET DESCRIPTION "Consulta de Transportadoras - Versao 02/03/2020" WSSYNTAX "/rest/WS104 || /rest/WS104/{cod}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS104


Local _aValid := {}
Local _cVldTkn := ''//ALLTRIM(GETMV('MV_TKNREST',.T.,'123456'))
Local _lRet := .F.
Local _cCodigo := ''
Local _nI,_nJ,_nReg
Local _cAlias1 := 'SA4'
Local _cFiltro := '', _xFiltro := '', _dFiltro := ''
Local _lPrepEnv := .F.
Local _cAlias, _cContent

Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''
Default SELF:CDTFILTRO 	:=''
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

_nJ := 0
_cAlias1 := 'SA4'
_cContent:= ''
_xFiltro := ''

// define o tipo de retorno do método
::SetContentType("application/json")
//::SetContentType("application/html")

_cVldTkn := AllTrim(GETMV('DY_TNKDEPS',.T.,'123456'))

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
If(!Empty(SELF:cFiltro))
	cQry+= " AND " + SELF:cFiltro
EndIf
IF(!Empty(_cCodigo))
	cQry+= " AND A4_COD='" + _cCodigo + "' "
ENDIF

If(!Empty(_dFiltro))
	If(SA4->(FieldPos("A4_USERLGA")>0))
		cQry += " AND "
		cQry += " CASE WHEN A4_USERLGA = ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGI,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120) ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGA,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) END >= '"+_dFiltro+"' "
	EndIf
EndIf

cQry+="%"

If(SA4->(FieldPos("A4_USERLGA")>0))
	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		SELECT 	ROW_NUMBER() OVER(ORDER BY A4_COD ASC) REG,
				CASE 	WHEN A4_USERLGA = ' ' 
						THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGI,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
						ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGA,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(A4_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) 
				END DTLGA, *, R_E_C_N_O_ REC, D_E_L_E_T_ DEL
				FROM %TABLE:SA4% SA4  WITH (NOLOCK)
		WHERE SA4.D_E_L_E_T_!='X' %EXP:cQry%
		ORDER BY A4_COD
	ENDSQL
Else
	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		SELECT 	ROW_NUMBER() OVER(ORDER BY A4_COD ASC) REG, *, R_E_C_N_O_ REC, D_E_L_E_T_ DEL
				FROM %TABLE:SA4% SA4  WITH (NOLOCK)
		WHERE SA4.D_E_L_E_T_!='X' %EXP:cQry%
		ORDER BY A4_COD
	ENDSQL
EndIf
_cSql := getlastquery()[2]

(_cAlias)->(DBGoTop())
count to _nReg 
(_cAlias)->(DBGOTOP())


_aValidA4 := U_WS2CAMPOS(SELF:CTIPO,'SA4')

dbselectarea(_cAlias)
_nIni := ( 1 + ((SELF:NPAGINA -1) * SELF:NREGISTRO ))
_nFim := (SELF:NPAGINA * SELF:NREGISTRO)

SET FILTER TO REG >=_nIni .AND. REG <= _nFim

conout("filtro ws209 - REG BETWEEN '"+CVALTOCHAR(_nIni)+"' AND '"+CVALTOCHAR(_nFim)+"' ")
(_cAlias)->(dbgotop())



// define o tipo de retorno do método
If(!(_cAlias)->(EOF()))
	nPrimeiro :=0
	::SetResponse('{')
	If(SELF:CTESTE='SQL')
		::SetResponse('"SQL":"'+STRTRAN(STRTRAN(_cSql,'	',''),'"','')+'",')
	EndIf
	::SetResponse('"REGISTROS":[')
	Do While !(_cAlias)->(Eof())
	    
	    //Contador para inserir separador do json
	    If nPrimeiro>0
	     ::SetResponse(',')
	    EndIf
	    nPrimeiro+= 1
//		cChave:= (_cAlias)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)
		::SetResponse('{')
		::SetResponse('"REG_NUM":'+cvaltochar((_cAlias)->REG)+',')	
		IF((_cAlias)->(FIELDPOS('REC'))>0)
			::SetResponse('"RECNO":'+CVALTOCHAR((_cAlias)->REC)+',')	
		endif
		IF((_cAlias)->(FIELDPOS('DEL'))>0)
			::SetResponse('"DELETADO":"'+(_cAlias)->DEL+'",')	
		endif
		IF((_cAlias)->(FIELDPOS('DTLGA'))>0)
			::SetResponse('"DTALT":"'+(_cAlias)->DTLGA+'",')	
		ENDIF
		
		_aValid := _aValidA4
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
				ElseIf(TYPE(_aValid[_nI,5])='C')
					::SetResponse(&(_aValid[_nI,5])+'"')
				EndIf
				::SetResponse(iif(_nI<len(_aValid),',',''))			
			ElseIf(_aValid[_nI,3]=='N')
				::SetResponse('"'+_aValid[_nI,1]+'":'+alltrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
			EndIf
			
		Next
		::SetResponse('}')
		(_cAlias)->(DBSkip())
	EndDo
	
	::SetResponse(']')//FECHA rEGISTROS
	::SetResponse(',"QUANTIDADE": '+cvaltochar(_nReg)+'')
	::SetResponse(',"PAGINA": '+cvaltochar(SELF:NPAGINA)+'')
	If(SELF:CWSDIC=='S')
		::SetResponse(',"DICIONARIO":{')
			::SetResponse('"TRANSPORTADORA":[')
			_aValid := _aValidA4
			For _nI := 1 to len(_aValid)
				If(_nI != 1)
					::SetResponse(",")
				EndIf
				::SetResponse("{")
				::SetResponse('"CAMPO":"'+_aValid[_nI,1]+'"')
				::SetResponse(',"TIPO":"'+_aValid[_nI,3]+'"')
				::SetResponse(',"TAM":'+CVALTOCHAR(_aValid[_nI,4])+'')
				::SetResponse(',"DESCRICAO":"'+AllTrim(STRTRAN(noacento(_aValid[_nI,7]),'"',''))+'"')
				::SetResponse(',"CAMPO_PROTHEUS":"'+_aValid[_nI,5]+'"')
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
