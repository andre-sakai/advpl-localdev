#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"






WSRESTFUL WS000 DESCRIPTION "Cadastro de Empresas"

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta de Empresas" WSSYNTAX "/rest/WS000 || /rest/WS000/{doc}"
//WSMETHOD PUT DESCRIPTION "Alteração de Clientes" WSSYNTAX "/rest/WS002/{id}"
//WSMETHOD DELETE DESCRIPTION "Exclusão de entidade" WSSYNTAX "/sample/{id}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS000

//Local _aValid := {}
Local _cVldTkn := ''
Local _lRet := .F.
Local _cDoc := ''
Local _cFiltro := ''					
Local _nI := 0
Local _nReg := 0				
Local _lPrepEnv := .F.
Local _aArea := NIL

Private _aValid := {}

Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''		 



CONOUT('OPENSM0')
IF(Select('SM0')<=0)

OPENSM0()
ENDIF

	_aArea :=SM0->(GETAREA())
	SM0->(DBSETORDER(1))
	SM0->(DBGOTOP())

	::SetContentType("application/json")
	
	WHILE(!SM0->(EOF()))


		IF(SM0->M0_CODIGO <> '99')
			If(_lRet == .T.)
				::SetResponse(', ')
			EndIf
			::SetResponse('{')
			::SetResponse('"CODEMP":"'+SM0->M0_CODIGO+'",')
			::SetResponse('"CODFIL":"'+SM0->M0_CODFIL+'",')
			::SetResponse('"NOMEMP":"'+ALLTRIM(NOACENTO(SM0->M0_NOME	))+'",')
			::SetResponse('"NOMFIL":"'+ALLTRIM(NOACENTO(SM0->M0_FILIAL	))+'",')
			::SetResponse('"CGC":"'+SM0->M0_CGC+'"')
			::SetResponse('}')
			
			
			_lRet := .T.
			
		ENDIF
		SM0->(DBSKIP())
	ENDDO
	
	RestArea(_aArea)

If(!_lRet)
	Return {.f.,402,'Grupo de Empresas nao encontrado!'}
EndIf


Return _lRet
 