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
// Função   : WS108 - CADASTRO DE TITULOS FINANCEIRO
// Descrição: WS PARA CONSULTA DE TITULOS FINANCEIRO
// Retorno  : REST COM AS INFORMAÇÕES DA TABELA SE1,SE5
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

WSRESTFUL WS108 DESCRIPTION "Financeiro" 

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL
WSDATA CFILBX AS STRING OPTIONAL
WSDATA CTESTE AS STRING OPTIONAL
WSDATA CDTFILTRO AS STRING OPTIONAL 
WSDATA CDTFILFIM AS STRING OPTIONAL 

WSDATA CWSEMP AS STRING OPTIONAL 
WSDATA CWSFIL AS STRING OPTIONAL 

WSDATA CWSDIC AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta Financeiro - Versao 13/03/2020" WSSYNTAX "/rest/WS108 || /rest/WS108/{SERIE}/{DOC}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS108

Local _cVldTkn := ''
Local _lRet := .F.
Local _nI,_nJ,_nReg
Local _lPrepEnv := .F.
LOCAL nPrimeiro := 0
Local _cAlias
Local _cAlias2
Local _cCodFil,_cCodPed,_cCodSerie,_cCodNum,_cCodCli,_cCodLoja, _cSql


Private _aValid := {}

Default _cCodFil:=''
Default _cCodPed:=''

Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''
Default SELF:CFILBX 	:=''
Default SELF:CTESTE 	:=''
Default SELF:CDTFILTRO	:=''
Default SELF:CDTFILFIM	:=''

Default SELF:CWSEMP := '01'
Default SELF:CWSEMP := '01'
Default SELF:CWSFIL := '01'
Default SELF:CWSDIC := 'N' 					   

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "","","","",{"SA1","SA2","SA3","SA4", "SC5","SC6", "SF2","SD2", "SE1","SE2"}) 
	_lPrepEnv := .T.
EndIf
_nJ:=0

::SetContentType("application/json")

_cVldTkn := ALLTRIM(GETMV('DY_TNKDEPS',.T.,'123456'))

If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verifique a chave! '+SELF:pToken)
	Return .F.
Else
	//conout('','Token Ok')
EndIf

If Len(::aURLParms) = 0
	_cCodCli := ''
	_cCodLoja:= ''
	_cCodSerie := ''
	_cCodNum := ''
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
	SetRestFault(499,'Parametros inválidos. Favor informar Cliente/Loja ou Filial('+xFilial('SE1')+')/Serie/Numero!')
	return .f.
EndIf
_xAlias := getnextalias()
_cAlias := getnextalias()
_cAlias2 := getnextalias()

_dFiltro := SELF:cdtFiltro
_dFiltr2 := SELF:cdtFilFim
	
_nIni := ( ((SELF:NPAGINA -1) * SELF:NREGISTRO ))
_nFim := (SELF:NREGISTRO )

cQry:=''
cQry+="%"
//cQry+= " AND E1_FILIAL='"+XFILIAL('SE1')+"' "
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

If(!empty(SELF:cFiltro))
	cQry+= " AND " + SELF:cFiltro + " "
ELSE
	cQry+= " AND E1_EMISSAO >= '20180101' "

EndIf
If(!EMPTY(_dFiltro))
	if(SE1->(FIELDPOS('E1_USERLGA'))>0)
		cQry += " AND  CASE WHEN E1_USERLGA = ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGI,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120) ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGA,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) END >= '"+_dFiltro+"' "
			
		If(!EMPTY(_dFiltr2))
				cQry += " AND  CASE WHEN E1_USERLGA = ' ' THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGI,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120) ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGA,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) END <= '"+_dFiltr2+"' "
		EndIf
	ENDIF
EndIf

cQry+="%"

	if(select(_xAlias)<>0)
		(_xAlias)->(dbclosearea())
	endif

	BEGINSQL ALIAS _xAlias
		%NOPARSER%
		COLUMN E1_EMISSAO AS DATE
		SELECT COUNT(*) reg
		FROM %TABLE:SE1% SE1 WITH (NOLOCK)
		WHERE SE1.D_E_L_E_T_!='X' %EXP:cQry%
	ENDSQL
	
	conout('ws108 - consulta regs')

	if(!(_xAlias)->(eof()))
		_nReg := (_xAlias)->reg
	endif

IF(SE1->(FIELDPOS('E1_USERLGA')))
/*
	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		COLUMN E1_EMISSAO AS DATE
		SELECT ROW_NUMBER() OVER(ORDER BY E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO) REG,
				CASE 	WHEN E1_USERLGA = ' ' 
						THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGI,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
						ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGA,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) 
				END DTLGA,  SE1.*, SE1.R_E_C_N_O_ REC , SE1.D_E_L_E_T_ DEL,  ED_FILIAL, ED_CODIGO,ED_DESCRIC,ED_MSBLQL ,A1_CGC,A1_PESSOA
		FROM %TABLE:SE1% SE1 WITH (NOLOCK)
		INNER JOIN %TABLE:SA1% SA1 WITH (NOLOCK) ON A1_COD=E1_CLIENTE AND A1_LOJA=E1_LOJA AND SA1.D_E_L_E_T_=''
		INNER JOIN %TABLE:SED% SED WITH (NOLOCK) ON ED_FILIAL=%EXP:XFILIAL('SED')% AND E1_NATUREZ=ED_CODIGO  AND SED.D_E_L_E_T_=''
		WHERE SE1.D_E_L_E_T_='' %EXP:cQry%
		ORDER BY E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO
	ENDSQL
*/

	
	
	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		COLUMN E1_EMISSAO AS DATE
		SELECT ROW_NUMBER() OVER(ORDER BY E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO) REG,
				CASE 	WHEN E1_USERLGA = ' ' 
						THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGI,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
						ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGA,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(E1_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) 
				END DTLGA,  SE1.*, SE1.R_E_C_N_O_ REC , SE1.D_E_L_E_T_ DEL, A1_PESSOA, A1_CGC
		FROM %TABLE:SE1% SE1 WITH (NOLOCK)
		INNER JOIN %TABLE:SA1% SA1 ON A1_COD=E1_CLIENTE AND A1_LOJA=E1_LOJA AND SA1.D_E_L_E_T_=' '
		WHERE SE1.D_E_L_E_T_!='X' %EXP:cQry%
		ORDER BY E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO
		
		OFFSET %EXP:_nIni% rows
		FETCH next %EXP:_nFim% rows ONLY
	ENDSQL
	/*/
	,A6_FILIAL, A6_COD, A6_NOME, A6_NREDUZ, A6_AGENCIA, A6_NUMCON, A6_BLOCKED
				aAdd(_aCampos, {'FILIAL'		,.F.,'C',TAMSX3('A6_FILIAL')[1]	,'A6_FILIAL'	,NIL})
			aAdd(_aCampos, {'CODIGO'		,.T.,'C',TAMSX3('A6_COD')[1]	,'A6_COD'		,NIL})
			aAdd(_aCampos, {'DESCRICAO'		,.T.,'C',TAMSX3('A6_NOME')[1]	,'A6_NOME'		,NIL})
			aAdd(_aCampos, {'APELIDO'		,.T.,'C',TAMSX3('A6_NREDUZ')[1]	,'A6_NREDUZ'	,NIL})
			aAdd(_aCampos, {'AGENCIA'		,.T.,'C',TAMSX3('A6_AGENCIA')[1],'A6_AGENCIA'	,NIL})
			aAdd(_aCampos, {'CONTA'			,.T.,'C',TAMSX3('A6_NUMCON')[1]	,'A6_NUMCON'	,NIL})
			aAdd(_aCampos, {'BLOQUEIO'		,.T.,'C',TAMSX3('A6_BLOCKED')[1],'A6_BLOCKED'	,NIL})
	
	
				aAdd(_aCampos, {'FILIAL'		,.F.,'C',TAMSX3('ED_FILIAL')[1]	,'ED_FILIAL'	,NIL})
			aAdd(_aCampos, {'CODIGO'		,.T.,'C',TAMSX3('ED_CODIGO')[1]	,'ED_CODIGO'		,NIL})
			aAdd(_aCampos, {'DESCRICAO'		,.T.,'C',TAMSX3('ED_DESCRIC')[1],'ED_DESCRIC'	,NIL})
			aAdd(_aCampos, {'BLOQUEIO'		,.T.,'C',TAMSX3('ED_MSBLQL')[1],'ED_MSBLQL'	,NIL})
	
		LEFT JOIN %TABLE:SA6% SA6 ON A6_FILIAL=%EXP:XFILIAL('SA6')% AND A6_COD=E1_PORTADO AND E1_AGEDEP=A6_AGENCIA AND A6_NUMCON=E1_CONTA AND SA6.D_E_L_E_T_=''


		INNER JOIN SED010 SED ON ED_FILIAL='01' AND E1_NATUREZ=ED_CODIGO AND SED.D_E_L_E_T_=' '
		INNER JOIN SA6010 SA6 ON A6_FILIAL='0101' AND  A6_COD=E1_PORTADO AND E1_AGEDEP=A6_AGENCIA AND A6_NUMCON=E1_CONTA AND SA6.D_E_L_E_T_=' '
	/*/
	
	
ELSE

/*
	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		COLUMN E1_EMISSAO AS DATE
		SELECT ROW_NUMBER() OVER(ORDER BY E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO) REG,  SE1.*, SE1.R_E_C_N_O_ REC , SE1.D_E_L_E_T_ DEL,
		ED_FILIAL, ED_CODIGO,ED_DESCRIC,ED_MSBLQL,A1_CGC,A1_PESSOA
		FROM %TABLE:SE1% SE1 WITH (NOLOCK)
		INNER JOIN %TABLE:SA1% SA1 WITH (NOLOCK) ON A1_COD=E1_CLIENTE AND A1_LOJA=E1_LOJA AND SA1.D_E_L_E_T_=''
		INNER JOIN %TABLE:SED% SED WITH (NOLOCK) ON ED_FILIAL=%EXP:XFILIAL('SED')% AND E1_NATUREZ=ED_CODIGO  AND SED.D_E_L_E_T_=''
		WHERE SE1.D_E_L_E_T_='' %EXP:cQry%
		ORDER BY E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO
	ENDSQL
*/
	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		COLUMN E1_EMISSAO AS DATE
		SELECT ROW_NUMBER() OVER(ORDER BY E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO) REG,  SE1.*, SE1.R_E_C_N_O_ REC , SE1.D_E_L_E_T_ DEL, A1_PESSOA, A1_CGC
		FROM %TABLE:SE1% SE1 WITH (NOLOCK)
		INNER JOIN %TABLE:SA1% SA1 ON A1_COD=E1_CLIENTE AND A1_LOJA=E1_LOJA AND SA1.D_E_L_E_T_=' '
		WHERE SE1.D_E_L_E_T_!='X' %EXP:cQry%
		ORDER BY E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO
		
		OFFSET %EXP:_nIni% rows
		FETCH next %EXP:_nFim% rows ONLY
	ENDSQL
ENDIF
_cSql := getlastquery()[2]

conout('ws 108',_cSql)
(_cAlias)->(DBGoTop())
//count to _nReg 

	
//SET FILTER TO REG >= _nIni .and. REG <=_nFim
	
conout('ws108 - query',_cSql)
//(_cAlias)->(DBGOTOP())
_aValidE1 := U_WS2CAMPOS(SELF:CTIPO,'SE1')
_aValidE5 := U_WS2CAMPOS(SELF:CTIPO,'SE5')


// define o tipo de retorno do método
IF(!(_cAlias)->(EOF()))

	
	::SetResponse('{')
	IF(SELF:CTESTE='SQL')
		::SetResponse('"SQL":"'+STRTRAN(STRTRAN(_cSql,'	',''),'"','')+'",')
	ENDIF
	::SetResponse('"REGISTROS":[')
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
		If((_cAlias)->(fieldpos('REC')))
			::SetResponse('"RECNO":'+cvaltochar((_cAlias)->REC)+',')
		EndIf
		If((_cAlias)->(fieldpos('DEL')))
			::SetResponse('"DEL":"'+(_cAlias)->DEL+'",')
		EndIf
		If((_cAlias)->(fieldpos('DTLGA')))
			::SetResponse('"DTALT":"'+(_cAlias)->DTLGA+'",')
		EndIf
		_aValid := _aValidE1
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
		::SetResponse(', "parametrizacoesCategorias":[')


		IF((_cAlias)->(fieldpos('E1_NATUREZ')))
			::SetResponse('{')
			::SetResponse('"codigoSistemaGestao": "NAT-'+ALLTRIM((_cAlias)->E1_NATUREZ)+'",')
			::SetResponse('"nomeCategoria": "NATUREZA",')
			::SetResponse('"contaInadimplencia": 1,')
			::SetResponse('"contaPagamento": 1,')
			::SetResponse('"tipoRelacionamento": 1,')
			::SetResponse('}')	
			
			 /*
			//::SetResponse(',{"NAT":{')
			::SetResponse('{')
				::SetResponse('{"TIPO":"NAT",')
				::SetResponse('"FILIAL":"'+(_cAlias)->ED_FILIAL+'",')
				::SetResponse('"CODIGO":"'+ALLTRIM((_cAlias)->ED_CODIGO)+'",')
				::SetResponse('"DESCRICAO":"'+ALLTRIM((_cAlias)->ED_DESCRIC)+'"')
			::SetResponse('}')
			*/
		ENDIF
		IF((_cAlias)->(fieldpos('E1_PORTADO')))
			//::SetResponse('{"POR":{')
			IF(!EMPTY((_cAlias)->E1_PORTADO))
				::SetResponse(',{')
				::SetResponse('"codigoSistemaGestao": "POR-'+ALLTRIM((_cAlias)->E1_PORTADO)+'",')
				::SetResponse('"nomeCategoria": "PORTADOR",')
				::SetResponse('"contaInadimplencia": 1,')
				::SetResponse('"contaPagamento": 1,')
				::SetResponse('"tipoRelacionamento": 1,')
				::SetResponse('}')	
			ELSE
				::SetResponse(',{')
				::SetResponse('"codigoSistemaGestao": "POR-000",')
				::SetResponse('"nomeCategoria": "PORTADOR",')
				::SetResponse('"contaInadimplencia": 1,')
				::SetResponse('"contaPagamento": 1,')
				::SetResponse('"tipoRelacionamento": 1,')
				::SetResponse('}')	
			ENDIF
			/*
			IF(!EMPTY((_cAlias)->E1_PORTADO))
			::SetResponse(',{')
				::SetResponse('"TIPO":"POR",')
				::SetResponse('"FILIAL":"'+(_cAlias)->A6_FILIAL+'",')
				::SetResponse('"CODIGO":"'+ALLTRIM((_cAlias)->A6_COD)+'",')
				::SetResponse('"AGENCIA":"'+ALLTRIM((_cAlias)->A6_AGEDEP)+'",')
				::SetResponse('"CONTA":"'+ALLTRIM((_cAlias)->A6_NUMCON)+'",')
				::SetResponse('"DESCRICAO":"'+ALLTRIM((_cAlias)->A6_NOME)+'"')
			::SetResponse('}')
			ENDIF
			*/
		ELSE
			IF(!EMPTY((_cAlias)->E1_PORTADO))
				::SetResponse(',{')
				::SetResponse('"codigoSistemaGestao": "POR-'+ALLTRIM((_cAlias)->E1_PORTADO)+'",')
				::SetResponse('"nomeCategoria": "PORTADOR",')
				::SetResponse('"contaInadimplencia": 1,')
				::SetResponse('"contaPagamento": 1,')
				::SetResponse('"tipoRelacionamento": 1,')
				::SetResponse('}')	
			ELSE
				::SetResponse(',{')
				::SetResponse('"codigoSistemaGestao": "POR-000",')
				::SetResponse('"nomeCategoria": "PORTADOR",')
				::SetResponse('"contaInadimplencia": 1,')
				::SetResponse('"contaPagamento": 1,')
				::SetResponse('"tipoRelacionamento": 1,')
				::SetResponse('}')	
			ENDIF
			/*
			IF(!EMPTY((_cAlias)->E1_PORTADO))
				::SetResponse(',{"TIPO":"POR",')
				::SetResponse('"FILIAL":"'+(_cAlias)->E1_FILIAL+'",')
				::SetResponse('"CODIGO":"'+ALLTRIM((_cAlias)->E1_PORTADO)+'",')
				::SetResponse('"AGENCIA":"'+ALLTRIM((_cAlias)->E1_AGEDEP)+'",')
				::SetResponse('"CONTA":"'+ALLTRIM((_cAlias)->E1_CONTA)+'",')
				::SetResponse('"DESCRICAO":"BANCO '+ALLTRIM((_cAlias)->E1_PORTADO)+'"')
				::SetResponse('}')
			ELSE
				
				::SetResponse(',{"TIPO":"POR",')
				::SetResponse('"FILIAL":"'+(_cAlias)->E1_FILIAL+'",')
				::SetResponse('"CODIGO":"000",')
				::SetResponse('"DESCRICAO":"SEM PORTADOR"')
				::SetResponse('}')
			ENDIF
			*/
		ENDIF

		IF(!EMPTY(SELF:CWSEMP))
			::SetResponse(',{')
			::SetResponse('"codigoSistemaGestao": "EMP-'+SELF:CWSEMP+'",')
			::SetResponse('"nomeCategoria": "EMPRESA",')
			::SetResponse('"contaInadimplencia": 1,')
			::SetResponse('"contaPagamento": 1,')
			::SetResponse('"tipoRelacionamento": 1,')
			::SetResponse('}')	
		ENDIF
		IF(!EMPTY((_cAlias)->E1_FILIAL))
			::SetResponse(',{')
			::SetResponse('"codigoSistemaGestao": "FIL-'+ALLTRIM((_cAlias)->E1_FILIAL)+'",')
			::SetResponse('"nomeCategoria": "FILIAL",')
			::SetResponse('"contaInadimplencia": 1,')
			::SetResponse('"contaPagamento": 1,')
			::SetResponse('"tipoRelacionamento": 1,')
			::SetResponse('}')	
		ENDIF
		IF(!EMPTY((_cAlias)->E1_TIPO))
			::SetResponse(',{')
			::SetResponse('"codigoSistemaGestao": "ESP-'+ALLTRIM((_cAlias)->E1_TIPO)+'",')
			::SetResponse('"nomeCategoria": "ESPECIE",')
			::SetResponse('"contaInadimplencia": 1,')
			::SetResponse('"contaPagamento": 1,')
			::SetResponse('"tipoRelacionamento": 1,')
			::SetResponse('}')	
		ENDIF
		
		::SetResponse(']')
		
		IF(SELECT(_cAlias2)>0)
			(_cAlias2)->(dbclosearea())
		ENDIF
		
		::SetResponse(', "BAIXAS":[')
		
		_cQry2 := "% AND E5_PREFIXO='"+(_cAlias)->E1_PREFIXO+"' AND E5_NUMERO='"+(_cAlias)->E1_NUM+"'  AND E5_PARCELA='"+(_cAlias)->E1_PARCELA+"' AND E5_TIPO='"+(_cAlias)->E1_TIPO+"' AND E5_CLIENTE='"+(_cAlias)->E1_CLIENTE+"' AND E5_LOJA='"+(_cAlias)->E1_LOJA+"' "
		IF(EMPTY(SELF:CFILBX))
			_cQry2 += " AND NOT ( E5_TIPODOC IN " + FORMATIN( MVRECANT+"/"+MV_CRNEG,"/") +" AND E5_RECPAG != 'P' ) "
//			_cQry2 += " AND NOT ( E5_TIPODOC IN " + FORMATIN('JR/J2/TL',"/") +" ) "
			//_cQry2 += " AND E5_RECPAG = 'R' AND RTRIM(E5_DOCUMEN) != '' "
		ELSE
			_cQry2 += " AND "+SELF:CFILBX+" "
		ENDIF
		
		_cQry2 += "%"
		

		BEGINSQL ALIAS _cAlias2
			%NOPARSER%
			COLUMN E5_DATA AS DATE
			SELECT ROW_NUMBER() OVER(ORDER BY E5_PREFIXO,E5_NUMERO,E5_PARCELA,E5_TIPO ASC) REG, * ,
			CASE WHEN E5_TIPODOC IN ('VL','ES','BA') THEN (E5_VALOR + (SELECT SUM(CASE WHEN E5_TIPODOC IN ('JR','J2','MT','M2')  THEN E5_VALOR * -1  
							 								 WHEN E5_TIPODOC IN ('DC','D2')  THEN E5_VALOR * 1 ELSE 0 END)
							 				 FROM SE5010 SE52 
							 				 WHERE SE5.E5_PREFIXO=SE52.E5_PREFIXO and SE5.E5_NUMERO=SE52.E5_NUMERO AND  SE5.E5_PARCELA=SE52.E5_PARCELA AND SE5.E5_TIPO=SE52.E5_TIPO  AND SE5.E5_SEQ=SE52.E5_SEQ AND SE5.E5_RECPAG=SE52.E5_RECPAG AND SE5.E5_CLIENTE=SE52.E5_CLIENTE AND SE5.E5_LOJA=SE52.E5_LOJA AND SE52.D_E_L_E_T_=' '
							 				) )
			  ELSE E5_VALOR END VALCALC, SE5.R_E_C_N_O_ REC   

			FROM %TABLE:SE5% SE5
			WHERE SE5.D_E_L_E_T_!='X' %EXP:_cQry2%
			AND E5_DATA <> ' SAL07.19'
			ORDER BY E5_PREFIXO,E5_NUMERO,E5_PARCELA,E5_TIPO
		ENDSQL
		
		/*
			SELECT ROW_NUMBER() OVER(ORDER BY E5_PREFIXO,E5_NUMERO,E5_PARCELA,E5_TIPO ASC) REG, * , (SELECT SUM(CASE WHEN E5_TIPODOC IN ('JR','J2')  THEN E5_VALOR * -1  WHEN E5_TIPODOC IN ('DC','D2')  THEN E5_VALOR * 1 ELSE 0 END) VAL  FROM SE5010 SE52 WHERE SE5.e5_prefixo=SE52.e5_prefixo and SE5.e5_numero=SE52.e5_numero and  SE5.e5_parcela=SE52.e5_parcela and SE5.e5_tipo=SE52.e5_tipo AND SE5.E5_CLIENTE=SE52.E5_CLIENTE AND SE5.E5_LOJA=SE52.E5_LOJA AND SE52.D_E_L_E_T_=' ') 
			FROM  SE5010 SE5 WHERE SE5.D_E_L_E_T_=''    AND e5_prefixo='002' and e5_numero='006482' and e5_parcela='2' and e5_tipo='NF' 
			AND NOT ( E5_TIPODOC IN ('RA ','NCC') AND E5_RECPAG != 'P' )  
			AND NOT ( E5_TIPODOC IN ('DB') )
			AND E5_DATA <> ' SAL07.19' ORDER BY E5_PREFIXO,E5_NUMERO,E5_PARCELA,E5_TIPO
		*/
		
		_cSqlBx := ''
		_cSqlBx := getlastquery()[2]
		
			
		//Lista de itens
		While !(_cAlias2)->(Eof()) 
			::SetResponse('{')
			_aValid := _aValidE5
			DbSelectArea(_cAlias2)
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
			::SetResponse(',"VALOR_CALCULADO":'+cvaltochar((_cAlias2)->VALCALC)+'')	
			::SetResponse(',"RECNO":'+cvaltochar((_cAlias2)->REC)+',')	
			::SetResponse('}')
			(_cAlias2)->(DBSkip())
			//Verifica se continua no mesmo pedido
			If !(_cAlias2)->(Eof())
				::SetResponse(',')   
			EndIf
		EndDo
		(_cAlias2)->(DBCloseArea())
		
		::SetResponse(']') //FECHA BAIXAS
		
		IF(SELF:CTESTE='SQL')
			::SetResponse(',"SQLBX":"'+STRTRAN(STRTRAN(_cSqlBx,'	',''),'"','')+'"')
		ENDIF
		
		
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
			::SetResponse('"DESCRICAO":"'+AllTrim(STRTRAN(noacento(_aValid[_nI,7]),'"',''))+'"')
			If(!Empty(_aValid[_nI,6]))
				::SetResponse(', "OPCOES":"'+_aValid[_nI,6]+'"')
			EndIf
			::SetResponse("}")
		Next		
		::SetResponse('],')
	::SetResponse('}')//FECHA DICIONARIO
	endif
	::SetResponse('}')//FECHA PEDIDOS
	
	(_cAlias)->(DBCLOSEAREA())
Else
	::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado!"}')
	SetRestFault(402,'Nenhum cadastro encontrado, verifique as informações enviadas!'+IIF(::SELF:CTESTE='SQL',_CSQL,''))		
	Return _lRet
EndIf



If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return .T.
