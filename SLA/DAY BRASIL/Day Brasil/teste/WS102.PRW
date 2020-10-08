#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

// ##############################################################################
// Projeto  : Day-Brasil
// Autor    : ANDRE SAKAI
// Modulo   : WS
// Função   : WS102 - CADASTRO DE CLIENTES
// Descrição: WS PARA CONSULTA DE CLIENTES
// Retorno  : REST COM AS INFORMAÇÕES DA TABELA SA1
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

WSRESTFUL WS102 DESCRIPTION "Cadastro de Clientes"

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
WSMETHOD GET DESCRIPTION "Consulta de Clientes - Versao 18/09/2020 a" WSSYNTAX "/rest/WS102 || /rest/WS102/{doc}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS102

//Local _aValid := {}
Local _cVldTkn := ''
Local _lRet := .F.
Local _cDoc := '', _cCodigo:='', _cLoja:='', _cSql :=''
Local _cFiltro := '', _xFiltro := '', _dFiltro := ''
Local _nI := 0
Local _nReg := 0
Local _lPrepEnv := .F.
Local _cAlias

Private _aValid := {}
Private _oBody

Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''
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




// define o tipo de retorno do método
::SetContentType("application/json")


_cAlias := getnextalias()

_cVldTkn := AllTrim(SUPERGETMV('DY_TNKDEPS',.T.,'123456'))
_cFiltro := SELF:cFiltro
_dFiltro := SELF:cdtFiltro

If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verIfique a chave!')
	Return _lRet
Else

//	CONOUT('PTOKEN',SELF:PTOKEN)
//	CONOUT('TOKEN',_cVldTkn)

EndIf

_aValid := U_WS2CAMPOS(SELF:CTIPO,'SA1')

// verIfica se recebeu parametro pela URL
// exemplo: http://localhost:8080/sample/1
If Len(::aURLParms) > 0
	// insira aqui o código para pesquisa do parametro recebido
	// consulta de cliente por documento
	If Len(::aURLParms) = 1
		_cDoc := padr(::aURLParms[1],tamsx3('A1_CGC')[1],' ')
		If(Empty(_cDoc))
			::SetResponse('["ID":401,"Erro":"Documento nao informado!"]')
			SetRestFault(499,'"Erro":"Documento nao informado! VerIfique as informações enviadas!')
			Return _lRet
		EndIf
		
		If(Len(AllTrim(_cDoc))>8)
			_xFiltro := "  A1_CGC='"+_cDoc+"' "
		ElseIf(Len(AllTrim(_cDoc))=8)
			_xFiltro := " SUBSTRING(A1_CGC,1,8)='"+AllTrim(_cDoc)+"' AND LEN(RTRIM(A1_CGC))=14 "
		EndIf
		
	ElseIf Len(::aURLParms) > 1
		_cCodigo := padr(::aURLParms[1],tamsx3('A1_COD')[1],' ')
		If(Empty(_cCodigo))
			::SetResponse('["ID":401,"Erro":"Codigo nao informado!"]')
			SetRestFault(499,'"Erro":"Codigo nao informado! VerIfique as informações enviadas!')
			Return _lRet
		EndIf
		
		If Len(::aURLParms) >= 2
			_cLoja := padr(::aURLParms[2],tamsx3('A1_LOJA')[1],' ')
		EndIf

		If(!Empty(_cCodigo))
			_xFiltro := " A1_COD='"+_cCodigo+"' "
		EndIf
		
		If(!Empty(_cLoja))
			_xFiltro += " AND A1_LOJA = '"+AllTrim(_cLoja)+"' "
		EndIf
		
	EndIf
	
 
	If(!Empty(_cFiltro))
		If(!Empty(_xFiltro))
			_xFiltro += " AND "
		EndIf
		_xFiltro += ' '+_cFiltro +' '
	EndIf
	
	If(!Empty(_dFiltro))
		If(!Empty(_xFiltro))
			_xFiltro += " AND "
		EndIf
		_xFiltro += " CASE WHEN A1_USERLGA <> ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGA,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) WHEN A1_USERGI <> '' THEN CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGI,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120) ELSE '        ' END >= '"+_dFiltro+"' "
	EndIf
	
	If(!Empty(_xFiltro))
		_xFiltro := "% AND "+_xFiltro+"%"
	Else
		_xFiltro := "% %"
		
	EndIf
	
	
	If(SELECT(_cAlias)>0)
		(_cAlias)->(dbclosearea())
	EndIf
	
	conout('WS102 - filtro '+_xFiltro)
	
	/*
SELECT ROW_NUMBER() OVER(ORDER BY SA1.A1_COD ASC) REG, ZAB_CLICOL, ZAB_LOJCOL, SA12.A1_NOME COLIGADA,
		CASE 	WHEN SA1.A1_USERLGA = ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(SA1.A1_USERLGI,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(SA1.A1_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
				ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(SA1.A1_USERLGA,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(SA1.A1_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) 
		END DTLGA, SA1.* , SA1.A1_COD+SA1.A1_LOJA AS CHAVE, SA1.R_E_C_N_O_ REC, SA1.D_E_L_E_T_ DEL
		FROM SA1010 SA1 (NOLOCK)
LEFT JOIN ZAB010 ZAB (NOLOCK) ON ZAB_CLIENT = A1_COD AND ZAB_LOJA=A1_LOJA AND ZAB.D_E_L_E_T_=' '
LEFT JOIN SA1010 SA12 (NOLOCK) ON ZAB_CLICOL = SA12.A1_COD AND ZAB_LOJCOL = SA12.A1_LOJA AND SA12.D_E_L_E_T_=' '
		WHERE  SA1.D_E_L_E_T_!='X'  
		ORDER BY SA1.A1_COD
		*/
	BeginSql alias _cAlias
		%NOPARSER%
		SELECT ROW_NUMBER() OVER(ORDER BY SA1.A1_COD ASC) REG,  ZAB_CLICOL, ZAB_LOJCOL, SA12.A1_NOME COLIGADA,
		CASE 	WHEN SA1.A1_USERLGA <> ' ' THEN CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(SA1.A1_USERLGA,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(SA1.A1_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) 
				WHEN SA1.A1_USERLGI <> ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(SA1.A1_USERLGI,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(SA1.A1_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
				ELSE '        '
		END DTLGA, SA1.* , SA1.A1_COD+SA1.A1_LOJA AS CHAVE, SA1.R_E_C_N_O_ REC , SA1.D_E_L_E_T_ DEL 
		FROM %TABLE:SA1% SA1 (NOLOCK)
		LEFT JOIN %TABLE:ZAB% ZAB (NOLOCK) ON ZAB_CLIENT = SA1.A1_COD AND ZAB_LOJA=SA1.A1_LOJA AND ZAB.D_E_L_E_T_=' '
		LEFT JOIN %TABLE:SA1% SA12 (NOLOCK) ON ZAB_CLICOL = SA12.A1_COD AND ZAB_LOJCOL = SA12.A1_LOJA AND SA12.D_E_L_E_T_=' '
		WHERE A1_FILIAL=%EXP:XFILIAL('SA1')% AND SA1.D_E_L_E_T_!='X' %EXP:_xFiltro% 
		
		ORDER BY SA1.A1_COD
	EndSql
	_cSql := GETLASTQUERY()[2]
	
	DBSELECTAREA(_cAlias)

	(_cAlias)->(DBGoTop())
	count to _nReg 
	
	_nIni := ( 1 + ((SELF:NPAGINA -1) * SELF:NREGISTRO ))
	_nFim := (SELF:NPAGINA * SELF:NREGISTRO)
	
	SET FILTER TO REG >= _nIni .and. REG <=_nFim
	
	(_cAlias)->(DBGoTop())
	
	
	If(!(_cAlias)->(EOF()))	
	
		::SetResponse('{')
		If(SELF:CTESTE='SQL')
			::SetResponse('"SQL":"'+STRTRAN(STRTRAN(_cSql,'	',''),'"','')+'",')
		EndIf
		::SetResponse('"REGISTROS":[')
	
		_nJ := 1
		While((_cAlias)->(!Eof()))
			//If(_nJ >= ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO ) .AND. _nJ <= (SELF:NPAGINA * SELF:NREGISTRO ))
			
				If(_lRet)
					::SetResponse(',')			
				EndIf
				::SetResponse('{')
				::SetResponse('"REG_NUM":'+cvaltochar((_cAlias)->REG)+',')				
				If((_cAlias)->(FIELDPOS('CHAVE'))>0)
					::SetResponse('"CHAVE":"'+(_cAlias)->CHAVE+'",')		
				EndIf		
				If((_cAlias)->(FIELDPOS('REC'))>0)
					::SetResponse('"RECNO":'+CVALTOCHAR((_cAlias)->REC)+',')	
				EndIf
				If((_cAlias)->(FIELDPOS('DEL'))>0)
					::SetResponse('"DELETADO":"'+(_cAlias)->DEL+'",')	
				EndIf
				If((_cAlias)->(FIELDPOS('DTLGA'))>0)
					::SetResponse('"DTALT":"'+(_cAlias)->DTLGA+'",')	
				EndIf
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(STRTRAN(STRTRAN(noacento(&(_aValid[_nI,5])),'"',''),'	',''))+'"'+iIf(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='M')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='O')
						//não tratado - somente para compatibilidade com outras funções
					ElseIf(_aValid[_nI,3]=='L')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='D')
						::SetResponse('"'+_aValid[_nI,1]+'":"')
						If(TYPE(_aValid[_nI,5])='D')
							::SetResponse(dtos(&(_aValid[_nI,5]))+'"')
						ElseIf(TYPE(_aValid[_nI,5])='C')
							::SetResponse(&(_aValid[_nI,5])+'"')
						EndIf
						::SetResponse(iIf(_nI<len(_aValid),',',''))		
					ElseIf(_aValid[_nI,3]=='N')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))
					EndIf
					
				Next
				::SetResponse('}')
				_lRet := .T.
			//EndIf
			
			_nJ++
			(_cAlias)->(DBSkip())
		EndDo
		::SetResponse(']')
		::SetResponse(', "QUANTIDADE":'+CVALTOCHAR(_nReg))
		::SetResponse(', "PAGINA":'+CVALTOCHAR(SELF:NPAGINA))	
		If(SELF:CWSDIC=='S')
			::SetResponse(', "DICIONARIO":[')
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
			::SetResponse(']') //FIM DO DICIONARIO
		EndIf
	ElsE
		::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado !"}')
		SetRestFault(402,'Nenhum cadastro encontrado! VerIfique as informações enviadas!'+IIf(SELF:CTESTE='SQL',_cSql,''))
		return .f.
	EndIf
	::SetResponse('}')
	dbselectarea(_cAlias)
	SET FILTER TO		  
Else
	
	If(Select(_cAlias)>0)
		(_cAlias)->(dbclosearea())
	EndIf


	If(!Empty(_cFiltro))
		If(!Empty(_xFiltro))
			_xFiltro += " AND "
		EndIf
		_xFiltro += ' '+_cFiltro +' '
	EndIf
	
	If(!Empty(_dFiltro))
		If(!Empty(_xFiltro))
			_xFiltro += " AND "
		EndIf
		_xFiltro += " CASE WHEN A1_USERLGA = ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGI,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120) ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGA,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) END >= '"+_dFiltro+"' "
	EndIf
	If(!Empty(_xFiltro))
		_xFiltro := "% AND "+_xFiltro+"%"
	Else
		_xFiltro := "% %"
	EndIf
	
	conout('WS102 - filtro '+_xFiltro)
	
	
	BeginSql alias _cAlias
		%NOPARSER%
		SELECT ROW_NUMBER() OVER(ORDER BY A1_COD ASC) REG, 
		CASE 	WHEN A1_USERLGA = ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGI,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
				ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGA,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(A1_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) 
		END DTLGA, SA1.* , A1_COD+A1_LOJA AS CHAVE, SA1.R_E_C_N_O_ REC, SA1.D_E_L_E_T_ DEL
		FROM %TABLE:SA1% SA1 (NOLOCK)
		WHERE A1_FILIAL=%EXP:XFILIAL('SA1')% AND SA1.D_E_L_E_T_!='X' %EXP:_xFiltro%
		ORDER BY A1_COD
	EndSql
	_cSql := GETLASTQUERY()[2]
	
	DBSELECTAREA(_cAlias)

	(_cAlias)->(DBGoTop())
	count to _nReg 
	
	_nIni := ( 1 + ((SELF:NPAGINA -1) * SELF:NREGISTRO ))
	_nFim := (SELF:NPAGINA * SELF:NREGISTRO)
	
	SET FILTER TO REG >= _nIni .and. REG <=_nFim
	
	(_cAlias)->(DBGoTop())
	
	
	If(!(_cAlias)->(EOF()))	
	
		::SetResponse('{')
		If(SELF:CTESTE='SQL')
			::SetResponse('"SQL":"'+STRTRAN(STRTRAN(_cSql,'	',''),'"','')+'",')
		EndIf
		::SetResponse('"REGISTROS":[')
	
		_nJ := 1
		While((_cAlias)->(!Eof()))
			//If(_nJ >= ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO ) .AND. _nJ <= (SELF:NPAGINA * SELF:NREGISTRO ))
			
				If(_lRet)
					::SetResponse(',')			
				EndIf
				::SetResponse('{')
				::SetResponse('"REG_NUM":'+cvaltochar((_cAlias)->REG)+',')
				If((_cAlias)->(FIELDPOS('CHAVE'))>0)
					::SetResponse('"CHAVE":"'+(_cAlias)->CHAVE+'",')		
				EndIf		
				If((_cAlias)->(FIELDPOS('REC'))>0)
					::SetResponse('"RECNO":'+CVALTOCHAR((_cAlias)->REC)+',')	
				EndIf
				If((_cAlias)->(FIELDPOS('DEL'))>0)
					::SetResponse('"DELETADO":"'+(_cAlias)->DEL+'",')	
				EndIf
				If((_cAlias)->(FIELDPOS('DTLGA'))>0)
					::SetResponse('"DTALT":"'+(_cAlias)->DTLGA+'",')	
				EndIf											   
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(STRTRAN(STRTRAN(noacento(&(_aValid[_nI,5])),'"',''),'	',''))+'"'+iIf(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='M')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='O')
						//não tratado - somente para compatibilidade com outras funções
					ElseIf(_aValid[_nI,3]=='L')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='D')
						::SetResponse('"'+_aValid[_nI,1]+'":"')
						If(TYPE(_aValid[_nI,5])='D')
							::SetResponse(dtos(&(_aValid[_nI,5]))+'"')
						ElseIf(TYPE(_aValid[_nI,5])='C')
							::SetResponse(&(_aValid[_nI,5])+'"')
						EndIf
						::SetResponse(iIf(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='N')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))
					EndIf
					
				Next
				::SetResponse('}')
				_lRet := .T.
			//EndIf
			
			_nJ++
			(_cAlias)->(DBSkip())
		EndDo
		::SetResponse(']')
		::SetResponse(', "QUANTIDADE":'+CVALTOCHAR(_nReg))
		::SetResponse(', "PAGINA":'+CVALTOCHAR(SELF:NPAGINA))	
		If(SELF:CWSDIC=='S')
		::SetResponse(', "DICIONARIO":[')
		For _nI := 1 to len(_aValid)
			If(_nI != 1)
				::SetResponse(",")
			EndIf
			::SetResponse("{")
			::SetResponse('"CAMPO":"'+_aValid[_nI,1]+'"')
			::SetResponse(',"TIPO":"'+_aValid[_nI,3]+'"')
			::SetResponse(',"TAM":'+CVALTOCHAR(_aValid[_nI,4])+'')
			::SetResponse(',"DESCRICAO":"'+_aValid[_nI,7]+'"')
			::SetResponse(',"CAMPO_PROTHEUS":"'+_aValid[_nI,5]+'"')
			If(!Empty(_aValid[_nI,6]))
				::SetResponse(', "OPCOES":"'+_aValid[_nI,6]+'"')
			EndIf
			::SetResponse("}")
		Next
		
		::SetResponse(']') //FIM DO DICIONARIO
		EndIf
	Else	 
		::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado ('+_cDoc+')!"}')
		SetRestFault(402,'Erro - Nenhum cadastro encontrado! VerIfique as informações enviadas!')
		return .f.
	EndIf
	::SetResponse('}')
	dbselectarea(_cAlias)
	SET FILTER TO	
	
	(_cAlias)->(DBCLOSEAREA())
	
EndIf


If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return .T.
