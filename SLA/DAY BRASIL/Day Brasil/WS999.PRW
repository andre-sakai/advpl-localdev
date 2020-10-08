#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

// ##############################################################################
// Projeto  : Day-Brasil
// Autor    : ANDRE SAKAI
// Modulo   : WS
// Função   : WS000 - Validação de cadastros
// Descrição: WS PARA CONSULTA DE CADASTROS
// Retorno  : REST COM AS INFORMAÇÕES DA SX3
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

WSRESTFUL WS999 DESCRIPTION "Cadastro de Empresas - Validação"

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 
WSDATA CDTFILTRO AS STRING OPTIONAL 

WSDATA CWSEMP AS STRING OPTIONAL 
WSDATA CWSFIL AS STRING OPTIONAL 

WSDATA CWSDIC AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta de cADASTROS - Versao 01/02/2020" WSSYNTAX "/rest/WS999 || /rest/WS999"
//WSMETHOD PUT DESCRIPTION "Alteração de Clientes" WSSYNTAX "/rest/WS002/{id}"
//WSMETHOD DELETE DESCRIPTION "Exclusão de entidade" WSSYNTAX "/sample/{id}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS999

Local _aValid := {}
Local _cVldTkn := ''//ALLTRIM(GETMV('MV_TKNREST',.T.,'123456'))
Local _lRet := .F.
Local _cCod := ''
Local _nI,_nJ,_nReg
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
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "","","","",{"SA1","SA2","SA3","SA4","SE4","SE1","SE5","SC5","SF2"}) 
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

_cAlias := getnextalias()
::SetResponse('{')
  ::SetResponse('"REGISTROS":[')
  _aTab := {"SA1","SA2","SA3","SA4","SB1","SE4","SE1","SE5","SC5","SF2"}
For _nI := 1 to len (_aTab)
	_cAlias2 := _aTab[_nI]
	DBSELECTAREA(_cAlias2)
	_lReg := .f.
	
	_aValid := U_WSCAMPOS(SELF:CTIPO,_cAlias2)
	For _nJ := 1 to len(_aValid)
//		::SetResponse('{"Campo":"'+_aValid[_nJ][5]+'"},')
		If((_cAlias2)->(fieldpos(_aValid[_nJ][5])) > 0)
//			::SetResponse('{"Tabela":"'+_cAlias2+'","Campo":"'+_aValid[_nJ][5]+'","Mensagem":"Campo OK"}')
		Else
			_lReg := .t.
			::SetResponse('{"Tabela":"'+_cAlias2+'","Campo":"'+_aValid[_nJ][5]+'","Mensagem":"Campo Inválido"}')
			If(_nJ < len(_aValid))
				::SetResponse(',')
			EndIf
		EndIf
	Next _nJ
	
	If((_cAlias2)->(fieldpos(SUBSTR(_cAlias2,2,2)+'_USERLGI')) > 0)
		If(_lReg)
			::SetResponse(',')
		EndIf
		::SetResponse('{"Tabela":"'+_cAlias2+'","Campo":"'+SUBSTR(_cAlias2,2,2)+'_USERLGI'+'","Mensagem":"Campo OK"}')
		_lReg := .t.		
	Else
		If(_lReg)
			::SetResponse(',')
		EndIf
		::SetResponse('{"Tabela":"'+_cAlias2+'","Campo":"'+SUBSTR(_cAlias2,2,2)+'_USERLGI'+'","Mensagem":"Campo nao cadastrado."}')
		_lReg := .t.
	EndIf
	
	If((_cAlias2)->(fieldpos(SUBSTR(_cAlias2,2,2)+'_USERLGA')) > 0)
		::SetResponse(',{"Tabela":"'+_cAlias2+'","Campo":"'+SUBSTR(_cAlias2,2,2)+'_USERLGA'+'","Mensagem":"Campo OK"}')
	Else
		If(_lReg)
			::SetResponse(',')
		EndIf
		::SetResponse('{"Tabela":"'+_cAlias2+'","Campo":"'+SUBSTR(_cAlias2,2,2)+'_USERLGA'+'","Mensagem":"Campo nao cadastrado."}')
		_lReg := .t.
	EndIf
	
	
	If(_nI < len(_aTab) .AND. _lReg)
		::SetResponse(',')
	EndIf
	
	
Next _nI

::SetResponse(']')
::SetResponse('}')

If(_lPrepEnv)
	RpcClearEnv()   
EndIf


Return .T.

