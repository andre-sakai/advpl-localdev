#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

// ##############################################################################
// Projeto  : Day-Brasil
// Autor    : ANDRE SAKAI
// Modulo   : WS
// Função   : WS105 - CADASTRO DE INFORMACOES COMPLEMENTARES
// Descrição: WS PARA CONSULTA DE INFORMACOES COMPLEMENTARES
// Retorno  : REST COM AS INFORMAÇÕES DA TABELAS DIVERSAS (SED,SA6)
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

WSRESTFUL WS115 DESCRIPTION "Cadastro de Informacoes Complementares"

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

WSMETHOD GET DESCRIPTION "Consulta de Informacoes Complementares - Versao 15/03/2020" WSSYNTAX "/rest/WS115"


END WSRESTFUL

WSMETHOD GET WSSERVICE WS115


Local _cVldTkn := ''//ALLTRIM(GETMV('MV_TKNREST',.T.,'123456'))
Local _lRet := .F.
Local _nReg
Local _cFiltro := '',  _dFiltro := ''
Local _lPrepEnv := .F.
Local _cAlias

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
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "","","","",{"SA1","SA2","SA3","SA4","SE4","SED"}) 
	_lPrepEnv := .T.
EndIf

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
	_cCodigo := padr(::aURLParms[1],tamsx3('ED_CODIGO')[1])
Else
	_cCodigo := ''
EndIf

_cAlias := getnextalias()

_cFiltro := SELF:cFiltro
_dFiltro := SELF:cdtFiltro

cQry:=''
cQry+="%"
//cQry+= " AND ED_FILIAL='"+XFILIAL('SED')+"' "
If(!Empty(SELF:cFiltro))
	cQry+= " AND " + SELF:cFiltro
EndIf
If(!EMPTY(_cCodigo))
	cQry+= " AND CODIGO='" + _cCodigo + "' "
EndIf

If(!EMPTY(_dFiltro))
	IF(SED->(FIELDPOS("ED_USERLGA"))>0)
		cQry += " AND DTLGA >= '"+_dFiltro+"' "
	EndIf
EndIf

cQry+="%"


	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		SELECT '{ "codigoSistemaGestao": "POR-'+CASE WHEN (RTRIM(POR))='' THEN '000' ELSE POR END +'", "nome": "'+case when (rtrim(POR))='' then '000' else por end +'", "nomeCategoria": "PORTADOR", "contaInadimplencia": 1, "contaPagamento": 1, "tipoRelacionamento": 1 } ' INFO, 'POR' TIPO
		FROM
		(SELECT DISTINCT E1_PORTADO POR FROM %TABLE:SE1% SE1 (NOLOCK) WHERE SE1.D_E_L_E_T_=' ') A
		
		UNION ALL
		
		SELECT '{ "codigoSistemaGestao": "NAT-'+RTRIM(COD)+'", "nome": "'+rtrim(DESCRI) +'", "nomeCategoria": "NATUREZA", "contaInadimplencia": 1, "contaPagamento": 1, "tipoRelacionamento": 1 }  '  INFO, 'NAT' TIPO FROM 
		(SELECT RTRIM(E1_NATUREZ) COD, RTRIM(ED_DESCRIC) DESCRI from %TABLE:SE1% SE1 (NOLOCK) JOIN %TABLE:SED% SED (NOLOCK) ON ED_CODIGO=E1_NATUREZ AND SED.D_E_L_E_T_=' '
		WHERE SE1.D_E_L_E_T_=' ' GROUP BY E1_NATUREZ,ED_DESCRIC ) B 
	ENDSQL


_cSql := getlastquery()[2]

if(SELF:CTESTE = 'CONSULTA')
	::SetResponse('{"SQL":"'+STRTRAN(STRTRAN(_cSql,'	',''),'"','')+'"}')
	RETURN .T.
ENDIF

(_cAlias)->(DBGoTop())
count to _nReg 
(_cAlias)->(DBGOTOP())


_aValidED := U_WS2CAMPOS(SELF:CTIPO,'INF_COMP')

dbselectarea(_cAlias)
_nIni := ( 1 + ((SELF:NPAGINA -1) * SELF:NREGISTRO ))
_nFim := (SELF:NPAGINA * SELF:NREGISTRO)

//SET FILTER TO REG >=_nIni .AND. REG <= _nFim

conout("filtro ws209 - REG BETWEEN '"+CVALTOCHAR(_nIni)+"' AND '"+CVALTOCHAR(_nFim)+"' ")
(_cAlias)->(dbgotop())



// define o tipo de retorno do método
IF(!(_cAlias)->(EOF()))
	nPrimeiro :=0
	::SetResponse('{')
	IF(SELF:CTESTE='SQL')
		::SetResponse('"SQL":"'+STRTRAN(STRTRAN(_cSql,'	',''),'"','')+'",')
	ENDIF
	::SetResponse('"parametrizacoesCategorias": [ ')
	Do While !(_cAlias)->(Eof())
	    ::SetResponse((_cAlias)->INFO)
		(_cAlias)->(DBSkip())
		If(!(_cAlias)->(Eof()))
			 ::SetResponse(',')
		EndIf
	EndDo
	
	::SetResponse(']')//FECHA rEGISTROS
	::SetResponse(',"QUANTIDADE": '+cvaltochar(_nReg)+'')
	::SetResponse(',"PAGINA": '+cvaltochar(SELF:NPAGINA)+'')
	
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
