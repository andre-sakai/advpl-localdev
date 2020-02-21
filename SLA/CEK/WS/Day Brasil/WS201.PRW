#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

// ##############################################################################
// Projeto  : Day-Brasil
// Autor    : ANDRE SAKAI
// Modulo   : WS
// Função   : WS201 - CADASTRO DE FORNECEDORES
// Descrição: WS PARA CONSULTA DE FORNECEDORES
// Retorno  : REST COM AS INFORMAÇÕES DA TABELA SA2
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

WSRESTFUL WS201 DESCRIPTION "Cadastro de Fornecedores"

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 
WSDATA CDTFILTRO AS STRING OPTIONAL 

WSDATA CWSEMP AS STRING OPTIONAL 
WSDATA CWSFIL AS STRING OPTIONAL 

WSDATA CWSDIC AS STRING OPTIONAL 								 
WSMETHOD GET DESCRIPTION "Consulta de Fornecedores - Versao 19/02/2020" WSSYNTAX "/rest/WS201 || /rest/WS201/{doc}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS201

//Local _aValid := {}
Local _cVldTkn := ''
Local _lRet := .F.
Local _cDoc := ''
Local _cFiltro := '', _xFiltro := ''					
Local _nI := 0
Local _nReg := 0				
Local _lPrepEnv := .F.
Local _cAlias := ''				   

Private _aValid := {}

Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''		
Default SELF:CDTFILTRO 	:=''		

DEFAULT SELF:CWSEMP := '01'
DEFAULT SELF:CWSFIL := '01' 
DEFAULT SELF:CWSDIC := 'N' 						   

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "","","","",{"SA1","SA2","SA3","SA4"}) 
	_lPrepEnv := .T.
EndIf


_cAlias := getnextalias()
// define o tipo de retorno do método
::SetContentType("application/json")

_cVldTkn := AllTrim(GETMV('MV_TKNREST',.T.,'123456'))

If(!EMPTY(SELF:cFiltro))
	_cFiltro := SELF:cFiltro
Else

EndIf						

If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verifique a chave!')
	Return _lRet
Else

//	CONOUT('PTOKEN',SELF:PTOKEN)
//	CONOUT('TOKEN',_cVldTkn)

EndIf

//_aValid := U_WS002SA2(SELF:CTIPO)
_aValid := U_WSCAMPOS(SELF:CTIPO,'SA2')

// verifica se recebeu parametro pela URL
// exemplo: http://localhost:8080/sample/1
If Len(::aURLParms) > 0
	// insira aqui o código para pesquisa do parametro recebido
	// consulta de cliente por documento
	If Len(::aURLParms) = 1
		_cDoc := padr(::aURLParms[1],tamsx3('A2_CGC')[1],' ')
		If(Empty(_cDoc))
			::SetResponse('["ID":401,"Erro":"Documento nao informado!"]')
			SetRestFault(499,'"Erro":"Documento nao informado! Verifique as informações enviadas!')
			Return _lRet
		EndIf
						
		If(Len(AllTrim(_cDoc))>8)																	  
			_xFiltro := "  A2_CGC='"+_cDoc+"' "
		ElseIf(Len(AllTrim(_cDoc))=8)																											
			_xFiltro := " SUBSTRING(A2_CGC,1,8)='"+AllTrim(_cDoc)+"' AND LEN(RTRIM(A2_CGC))=14 "
		EndIf
		
	ElseIf Len(::aURLParms) > 1
		_cCodigo := padr(::aURLParms[1],tamsx3('A2_COD')[1],' ')
		If(Empty(_cCodigo))
			::SetResponse('["ID":401,"Erro":"Codigo nao informado!"]')
			SetRestFault(499,'"Erro":"Codigo nao informado! Verifique as informações enviadas!')
			Return _lRet
		EndIf
		
		If Len(::aURLParms) >= 2
			_cLoja := padr(::aURLParms[2],tamsx3('A2_LOJA')[1],' ')
		EndIf

		If(!Empty(_cCodigo))
			_xFiltro := " A2_COD='"+_cCodigo+"' "
		EndIf
		
		If(!Empty(_cLoja))
			_xFiltro += " AND A2_LOJA = '"+AllTrim(_cLoja)+"' "
		EndIf
		
	EndIf
		
	IF(!EMPTY(_cFiltro))
		_xFiltro += ' AND '+_cFiltro
	EndIf
	
	If(!empty(_xFiltro))
		_xFiltro := "% AND "+_xFiltro+"%"
	Else
		_xFiltro := "%%"
	EndIf
	
	if(SELECT(_cAlias)>0)
		(_cAlias)->(dbclosearea())
	endif
	
	conout('ws201 - filtro '+_xFiltro)
	
	
	BeginSql alias _cAlias
		SELECT ROW_NUMBER() OVER(ORDER BY A2_COD ASC) REG, * FROM %TABLE:SA2% SA2
		WHERE A2_FILIAL=%EXP:XFILIAL('SA2')% AND SA2.D_E_L_E_T_=' ' %EXP:_xFiltro%
		ORDER BY A2_COD
	EndSql
	
	conout('ws201 - query '+GETLASTQUERY()[2])
	
	DBSELECTAREA(_cAlias)

	(_cAlias)->(DBGoTop())
	count to _nReg 
				 
	_nIni := ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO )
	_nFim := (SELF:NPAGINA * SELF:NREGISTRO)
	
	SET FILTER TO REG >= _nIni .and. REG <=_nFim
	
	(_cAlias)->(DBGoTop())
	
	
	If(!(_cAlias)->(EOF()))	
	
		::SetResponse('{"REGISTROS":[')
	
		_nJ := 1
		While((_cAlias)->(!Eof()))
			//If(_nJ >= ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO ) .AND. _nJ <= (SELF:NPAGINA * SELF:NREGISTRO ))
			
				If(_lRet)
					::SetResponse(',')			
				EndIf
				::SetResponse('{')
				::SetResponse('"REG_NUM":'+cvaltochar((_cAlias)->REG)+',')
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(noacento(&(_aValid[_nI,5])))+'"'+iif(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='M')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='O')
						//não tratado - somente para compatibilidade com outras funções
					ElseIf(_aValid[_nI,3]=='L')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='D')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+dtos(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='N')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
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
		IF(SELF:CWSDIC = 'S')
			::SetResponse(', "DICIONARIO":[')
			For _nI := 1 to len(_aValid)
				If(_nI != 1)
					::SetResponse(",")
				EndIf
				::SetResponse("{")
				::SetResponse('"CAMPO":"'+_aValid[_nI,1]+'",')
				::SetResponse('"TIPO":"'+_aValid[_nI,3]+'",')
				::SetResponse('"TAM":'+CVALTOCHAR(_aValid[_nI,4])+',')
				::SetResponse('"DESCRICAO":"'+_aValid[_nI,7]+'"')
				IF(!EMPTY(_aValid[_nI,6]))
					::SetResponse(', "OPCOES":"'+_aValid[_nI,6]+'"')
				EndIf
				::SetResponse("}")
			Next

			::SetResponse(']') //FIM DO DICIONARIO
		ENDIF
	ElsE
		::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado !"}')
		SetRestFault(402,'Nenhum cadastro encontrado! Verifique as informações enviadas!')
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
		_xFiltro += _cFiltro
	EndIf
	
	If(!Empty(_xFiltro))
		_xFiltro := "% AND "+_xFiltro+"%"
	Else
		_xFiltro := "% %"
	EndIf
	
	conout('ws201 - filtro '+_xFiltro)
	
	
	BeginSql alias _cAlias
		SELECT ROW_NUMBER() OVER(ORDER BY A2_COD ASC) REG, * FROM %TABLE:SA2% SA2
		WHERE A2_FILIAL=%EXP:XFILIAL('SA2')% AND SA2.D_E_L_E_T_=' ' %EXP:_xFiltro%
		ORDER BY A2_COD
	EndSql
	
	conout('ws201 - query '+GETLASTQUERY()[2])
	
	DBSELECTAREA(_cAlias)

	(_cAlias)->(DBGoTop())
	count to _nReg 

	_nIni := ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO )
	_nFim := (SELF:NPAGINA * SELF:NREGISTRO)
	
	SET FILTER TO REG >= _nIni .and. REG <=_nFim
	
	(_cAlias)->(DBGoTop())
	
	
	If(!(_cAlias)->(EOF()))	
	
		::SetResponse('{"REGISTROS":[')
	
		_nJ := 1
		While((_cAlias)->(!Eof()))
			//If(_nJ >= ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO ) .AND. _nJ <= (SELF:NPAGINA * SELF:NREGISTRO ))
			
				If(_lRet)
					::SetResponse(',')			
				EndIf
				::SetResponse('{')
				::SetResponse('"REG_NUM":'+cvaltochar((_cAlias)->REG)+',')
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(noacento(&(_aValid[_nI,5])))+'"'+iif(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='M')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='O')
						//não tratado - somente para compatibilidade com outras funções
					ElseIf(_aValid[_nI,3]=='L')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='D')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+dtos(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='N')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
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
				::SetResponse('"CAMPO":"'+_aValid[_nI,1]+'",')
				::SetResponse('"TIPO":"'+_aValid[_nI,3]+'",')
				::SetResponse('"TAM":'+CVALTOCHAR(_aValid[_nI,4])+',')
				::SetResponse('"DESCRICAO":"'+_aValid[_nI,7]+'"')
				IF(!EMPTY(_aValid[_nI,6]))
					::SetResponse(', "OPCOES":"'+_aValid[_nI,6]+'"')
				EndIf
				::SetResponse("}")
			Next

			::SetResponse(']') //FIM DO DICIONARIO
		EndIf
	Else	 
		::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado ('+_cDoc+')!"}')
		SetRestFault(402,'"Erro":"Nenhum cadastro encontrado ('+_cDoc+')! Verifique as informações enviadas!')
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
 
 