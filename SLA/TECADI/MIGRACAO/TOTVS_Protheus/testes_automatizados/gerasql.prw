#include "totvs.ch"
#include "fileio.ch"

USER FUNCTION GERASQL(_cAlias)

Local _cSql1 := ""
Local _nI := 0 
Local _cSql3 := ""

Local _aDados := {}
Local _aQry := {}

Local _cRet := "OK"
Local nHandle1

Local _cFile1 := 'C:\TEMP\'+_cAlias+'-'+dtos(date())+'.sql'

If(!file(_cFile1) )
	nHandle1 := fcreate(_cFile1 , FO_READWRITE )
Else
	nHandle1 := fopen(_cFile1 , FO_READWRITE + FO_SHARED )
EndIf


If(nHandle1 == -1)
	_cRet := "Não foi possível abrir o arquivo "+_cFile1+CRLF
Else
	DBSELECTAREA('SX3')
	SET FILTER TO X3_ARQUIVO = _cAlias
	SX3->(DBGOTOP())
	
	_cSql1 := "SELECT 'INSERT INTO  "+retsqlname(_cAlias)+" (R_E_C_N_O_,D_E_L_E_T_,
	_cSql2 := ") VALUES ((SELECT COALESCE(MAX(B.R_E_C_N_O_),0)+1 FROM "+retsqlname(_cAlias)+" B), '''+D_E_L_E_T_+''', "
	_cSql3 := ")' FROM "+retsqlname(_cAlias)
		
	_aQry := {_cSql1,_cSql2,_cSql3}
	_nI := 0
	WHILE(!SX3->(EOF()))
		
		If(SX3->X3_CONTEXT=="V")
			SX3->(DBSKIP())
			loop
		EndIf
		
		If(_nI != 0)
			_cSql1 += ","
		EndIf
		_cSql1 += ""+ALLTRIM(SX3->X3_CAMPO)+""
		
		_nI++
		If((_nI % 5) == 0)
			fwrite(nHandle1,_cSql1)
			_cSql1 := ""
		EndIf
		
		SX3->(DBSKIP())
	ENDDO
		
	fwrite(nHandle1,_cSql1)
	
	SX3->(DBGOTOP())
	_nI := 0
	WHILE(!SX3->(EOF()))
		
		If(SX3->X3_CONTEXT=="V")
			SX3->(DBSKIP())
			loop
		EndIf
		
			
		If(_nI != 0)
			_cSql2 += ","
		EndIf
		
		
		If(SX3->X3_TIPO=="N")
			_cSql2 += "'+CAST("+ALLTRIM(SX3->X3_CAMPO)+" AS VARCHAR)+'"
		ElseIf(SX3->X3_TIPO=="D")
			_cSql2 += "'''+"+ALLTRIM(SX3->X3_CAMPO)+"+'''"
		ElseIf(SX3->X3_TIPO=="M")
			_cSql2 += "'''+COALESCE(REPLACE(CONVERT(VARBINARY(8000),"+ALLTRIM(SX3->X3_CAMPO)+"),CHAR(0),''''''),'''''')+'''"
		Else
			_cSql2 += "'''+"+ALLTRIM(SX3->X3_CAMPO)+"+'''"
		EndIf
		
		_nI++
		If((_nI % 5) == 0)
			fwrite(nHandle1,_cSql2)
			_cSql2 := ""
		EndIf
		
		SX3->(DBSKIP())
	ENDDO	
	
	fwrite(nHandle1,_cSql2)
	fwrite(nHandle1,_cSql3)
	
	SET FILTER TO
	SX3->(DBGOTOP())

EndIf

If(nHandle1 != -1)
	fClose(nHandle1)
EndIf


RETURN (_cRet)

