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
// Função   : WS205 - CADASTRO DE PRODUTOS
// Descrição: WS PARA CONSULTA DE PRODUTOS
// Retorno  : REST COM AS INFORMAÇÕES DA TABELA SE1,SE5
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

WSRESTFUL WS209 DESCRIPTION "PRODUTOS" 

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 
WSDATA CDTFILTRO AS STRING OPTIONAL 

WSDATA CWSEMP AS STRING OPTIONAL 
WSDATA CWSFIL AS STRING OPTIONAL 

WSDATA CWSDIC AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta Produtos" WSSYNTAX "/rest/WS209 || /rest/WS209/{codigo}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS209

Local _cVldTkn := ''
Local _lRet := .F.
Local _cCodigo := ''
Local _nI := 0, _nReg := 0, _nIni := 0, _nFim := 0
Local _lPrepEnv := .F.
LOCAL nPrimeiro := 0
Local _cAlias
Local _cSql

Private _aValid := {}

Default _cCodigo:=''

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
	_cCodigo := padr(::aURLParms[1],tamsx3('B1_COD')[1])
Else
	_cCodigo := ''
EndIf
_cAlias := getnextalias()

cQry:=''
cQry+="%"
cQry+= " AND B1_FILIAL='"+XFILIAL('SB1')+"' "
If(!empty(SELF:cFiltro))
	cQry+= " AND " + SELF:cFiltro
EndIf
IF(!EMPTY(_cCodigo))
	cQry+= " AND B1_COD='" + _cCodigo + "' "
ENDIF
	cQry+= " AND B1_TIPO='PA' "
cQry+="%"

BEGINSQL ALIAS _cAlias
	%NOPARSER%
	SELECT ROW_NUMBER() OVER(ORDER BY B1_COD ASC) REG,* 
		,SB1.R_E_C_N_O_ REC ,SB1.D_E_L_E_T_ DEL FROM %TABLE:SB1% SB1
	INNER JOIN %TABLE:SBM% SBM ON B1_GRUPO=BM_GRUPO AND SBM.D_E_L_E_T_=''
	LEFT JOIN %TABLE:SB2% SB2 ON B2_FILIAL=%exp:xfilial('SB2')% AND B2_LOCAL in ('02','04') AND B2_COD=B1_COD AND SB2.D_E_L_E_T_=''
	WHERE SB1.D_E_L_E_T_='' %EXP:cQry%
	ORDER BY B1_COD
ENDSQL

_cSql := getlastquery()[2]

(_cAlias)->(DBGoTop())
count to _nReg 
(_cAlias)->(DBGOTOP())


_aValidB1 := U_WSCAMPOS(SELF:CTIPO,'SB1')

dbselectarea(_cAlias)
_nIni := ( 1 + ((SELF:NPAGINA -1) * SELF:NREGISTRO ))
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
		::SetResponse('"ESTOQUE":[')
		::SetResponse('{')
		IF((_cAlias)->(B2_QATU-B2_QPEDVEN-B2_RESERVA) > 0)
		::SetResponse('"SALDO":'+CVALTOCHAR((_cAlias)->(B2_QATU-B2_QPEDVEN-B2_RESERVA)))	
		ELSE
		::SetResponse('"SALDO":0')
		ENDIF
		::SetResponse(',"QUANTIDADE":'+CVALTOCHAR((_cAlias)->B2_QATU))	
		::SetResponse(',"PEDIDO":'+CVALTOCHAR((_cAlias)->B2_QPEDVEN))
		::SetResponse(',"RESERVA":'+CVALTOCHAR((_cAlias)->B2_RESERVA))
		::SetResponse('}')
		::SetResponse('],')
		_aValid := _aValidB1
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
		::SetResponse(',"DELETADO":"'+(_cAlias)->DEL+'"')
		::SetResponse(',"RECNO":'+CVALTOCHAR((_cAlias)->REC)+'')
		::SetResponse('}')
		(_cAlias)->(DBSkip())
	EndDo
	
	::SetResponse('],')//FECHA rEGISTROS
	::SetResponse('"QUANTIDADE": '+cvaltochar(_nReg)+',')
	::SetResponse('"PAGINA": '+cvaltochar(SELF:NPAGINA)+'')
	If(SELF:CWSDIC=='S')
		::SetResponse(',"DICIONARIO":{')
			::SetResponse('"PRODUTO":[')
			_aValid := _aValidB1
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

