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
// Função   : WS106 - CADASTRO DE PEDIDOS DE VENDAS
// Descrição: WS PARA CONSULTA DE VENDEDORES
// Retorno  : REST COM AS INFORMAÇÕES DA TABELA SC5,SC6
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

WSRESTFUL WS106 DESCRIPTION "Cadastro de Pedido de Venda"

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 
WSDATA CTESTE AS STRING OPTIONAL 
WSDATA CDTFILTRO AS STRING OPTIONAL 

WSDATA CWSEMP AS STRING OPTIONAL 
WSDATA CWSFIL AS STRING OPTIONAL 

WSDATA CWSDIC AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta Pedido de Venda - 02/03/2020" WSSYNTAX "/rest/WS106 || /rest/WS106/{FILIAL}/{SERIE}/{DOC}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS106

Local _cVldTkn := ''
Local _lRet := .F.
Local _nI,_nJ,_nP, _nIni, _nFim
Local _lPrepEnv := .F.
Local _cAlias, _cAlias2, _cAliasC6, _cAliasNF
Local _cCodFil,_cCodPed
Local _aValidc5 := {},_aValidc6 := {}
Local _nRegistros := 0		
Local _nValFat, _nValFDC, _nValTot, _nPedTot
Local aParc

Private _aValid := {}

Default _cCodFil:=''
Default _cCodPed:=''

Default SELF:cTipo :=''
Default SELF:NPAGINA := 1
Default SELF:NREGISTRO := 20
Default SELF:CFILTRO 	:=''
Default SELF:CTESTE 	:=''
Default SELF:CDTFILTRO 	:=''

DEFAULT SELF:CWSEMP := '01'
DEFAULT SELF:CWSFIL := '01'
DEFAULT SELF:CWSDIC := 'N'


If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "","","","",{"SA1","SA2","SA3","SA4", "SC5","SC6", "SF2","SD2", "SE1","SE2"}) 
	_lPrepEnv := .T.
EndIf


::SetContentType("application/json")

_cVldTkn := ALLTRIM(SUPERGETMV('DY_TNKDEPS',.T.,'123456'))

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
	_cCodFil := padr(::aURLParms[1],tamsx3('C5_FILIAL')[1])
	
	IF(LEN(::aURLParms)>=2)
		_cCodPed := padr(::aURLParms[2],tamsx3('C5_NUM')[1])
	EndIf
Else
	_cCodFil := SELF:CWSFIL
EndIf

_cAlias 	:= GetNextAlias()
_cAlias2 	:= GetNextAlias()
_cAliasC6 	:= GetNextAlias()
_cAliasNF 	:= GetNextAlias()
_cAliasFN 	:= GetNextAlias()
_cAliasA3 	:= GetNextAlias()

cQry:=''
cQry+="%"
If(!empty(_cCodFil))
	cQry+= " AND C5_FILIAL='"+_cCodFil+"' "
Else
	cQry+= " AND C5_FILIAL='"+XFILIAL('SC5')+"' "
EndIf
If(!empty(_cCodPed))
	cQry+= " AND C5_NUM='"+_cCodPed+"' "
EndIf
If(!empty(SELF:cFiltro))
	cQry+= SELF:cFiltro
ELSE
	cQry+= " AND C5_EMISSAO >= '20180101' "

EndIf

If(!Empty(SELF:CDTFILTRO))
	If(SC5->(FIELDPOS('C5_USERLGI')>0))	
		cQry+= " AND CASE 	WHEN C5_USERLGA = ' ' "
		cQry+= "	THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGI,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120) "
		cQry+= "	ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGA,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) END >= '"+SELF:CDTFILTRO+"' "
	EndIf	
EndIf

cQry+="%"

If(Select(_cAlias2)>0)
	(_cAlias2)->(DBCLOSEAREA())
EndIf

BEGINSQL ALIAS _cAlias2
	%NOPARSER%
	SELECT count(*) nReg FROM %TABLE:SC5% SC5
	WHERE SC5.D_E_L_E_T_ != 'X' %EXP:cQry%

ENDSQL

If((_cAlias2)->(!EOF()))
	_nRegistros := (_cAlias2)->nReg
Else
	_nRegistros := 0
EndIf


If(Select(_cAlias)>0)
	(_cAlias)->(DBCLOSEAREA())
EndIf

_nIni := (((SELF:NPAGINA -1) * SELF:NREGISTRO ))
_nFim := SELF:NREGISTRO

If(SC5->(FIELDPOS('C5_USERLGI')>0))

	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		COLUMN C5_EMISSAO AS DATE
		SELECT ROW_NUMBER() OVER(ORDER BY C5_FILIAL, C5_NUM ASC) REG,
				CASE 	WHEN C5_USERLGA = ' ' 
						THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGI,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
						ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGA,12,1)) - 50))*100+Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) 
				END DTLGA, 
				CASE WHEN C5_LIBEROK = '' AND C5_NOTA='' AND C5_BLQ='' AND C5_DYCANPV = ' ' THEN 
					(SELECT TOP 1 CASE WHEN C9_SEQUEN>'01' THEN 'FATURADO PARCIAL' ELSE 'ABERTO' END AS RET
					FROM %TABLE:SC9% SC92 (NOLOCK) WHERE C9_FILIAL = C5_FILIAL AND C9_PEDIDO=C5_NUM AND SC92.D_E_L_E_T_=' '
							AND C9_BLEST<>'10' and C9_BLCRED<>'10'
					ORDER BY C9_FILIAL,C9_PEDIDO,C9_SEQUEN DESC)
				WHEN (C5_NOTA <> ' ' OR C5_LIBEROK='E' AND C5_BLQ='') AND C5_DYCANPV = ' ' THEN 'FATURADO'
				WHEN (C5_NOTA <> ' ' OR C5_LIBEROK='E' AND C5_BLQ='') AND C5_DYCANPV = ' ' THEN 'FATURADO'
				/* WHEN C5_LIBEROK<>' ' AND   C5_NOTA=' ' AND C5_BLQ =' ' AND C5_DYCANPV = ' ' THEN 'LIBERADO' */
				/* WHEN C5_NOTA <> ' ' OR C5_LIBEROK IN (' ','S') AND C5_BLQ='' AND C5_DYCANPV = ' ' THEN 'FATURADO PARCIAL'*/
				WHEN C5_BLQ='1' AND C5_DYCANPV = ' ' THEN 'AGUARDANDO LIBERACAO'
				WHEN C5_BLQ='3' AND C5_DYCANPV = ' ' THEN 'PEDIDO SEM LIBERACAO DO CLIENTE' 
				WHEN C5_DYCANPV <> ' ' THEN 'PEDIDO CANCELADO' 
				WHEN C5_DYCANPV = ' ' 
				THEN (
					SELECT 	TOP 1 COALESCE(CASE
							WHEN C9_BLCRED != '  ' AND C9_BLCRED NOT IN ('09','10','ZZ') THEN 'AGUARDANDO LIBERACAO CREDITO'
							WHEN C9_BLCRED='09' THEN 'CREDITO BLOQUEADO' 
							WHEN C9_BLCRED = '  ' AND C9_BLEST = '  ' AND C9_BLTMS = '  ' THEN 'LIBERADO CREDITO'
							WHEN C9_BLCRED IN ('10','ZZ') AND C9_BLEST IN( '10','ZZ') THEN 'FATURADO'
							ELSE 'AGUARDANDO FATURAMENTO'
							END,'SEM LIBERACAO') AS LIB
					FROM %TABLE:SC9% SC9 (NOLOCK) WHERE C9_FILIAL = C5_FILIAL AND C9_PEDIDO=C5_NUM AND SC9.D_E_L_E_T_=' '
							AND C9_BLEST<>'10' and C9_BLCRED<>'10'
					ORDER BY C9_FILIAL,C9_PEDIDO,C9_BLCRED DESC,C9_BLEST DESC,C9_BLTMS DESC,C9_BLWMS DESC
				)					
				END AS SITUACAO
				, SC5.* , A1_CGC, A1_PESSOA, E4_CODIGO, E4_DESCRI
		FROM %TABLE:SC5% SC5 (NOLOCK)
		INNER JOIN %TABLE:SA1% SA1 (NOLOCK) ON A1_COD=C5_CLIENTE AND A1_LOJA=C5_LOJACLI AND SA1.D_E_L_E_T_=' '
		LEFT JOIN %TABLE:SE4% SE4 (NOLOCK) ON E4_CODIGO = C5_CONDPAG AND SE4.D_E_L_E_T_=' '
		WHERE SC5.D_E_L_E_T_ != 'X' %EXP:cQry%
		ORDER BY C5_FILIAL, C5_NUM
		
		OFFSET %EXP:_nIni% rows
		FETCH Next %EXP:_nFim% rows ONLY
	
	ENDSQL
Else

	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		COLUMN C5_EMISSAO AS DATE
		SELECT ROW_NUMBER() OVER(ORDER BY C5_FILIAL, C5_NUM ASC) REG, 
				CASE WHEN C5_LIBEROK = '' AND C5_NOTA='' AND C5_BLQ='' AND C5_DYCANPV = ' ' THEN 'ABERTO'
				WHEN (C5_NOTA <> ' ' OR C5_LIBEROK='E' AND C5_BLQ='') AND C5_DYCANPV = ' ' THEN 'FATURADO'
				WHEN C5_LIBEROK<>' ' AND   C5_NOTA=' ' AND C5_BLQ =' ' AND C5_DYCANPV = ' ' THEN 'LIBERADO'
				/* WHEN C5_NOTA <> ' ' OR C5_LIBEROK IN (' ','S') AND C5_BLQ='' AND C5_DYCANPV = ' ' THEN 'FATURADO PARCIAL'*/
				WHEN C5_BLQ='1' AND C5_DYCANPV = ' ' THEN 'AGUARDANDO LIBERACAO'
				WHEN C5_BLQ='2' AND C5_DYCANPV = ' ' 
				THEN (
					SELECT 	TOP 1 COALESCE(CASE
							WHEN C9_BLCRED != '  ' AND C9_BLCRED NOT IN ('09','10','ZZ') THEN 'AGUARDANDO LIBERACAO CREDITO'
							WHEN C9_BLCRED='09' THEN 'CREDITO BLOQUEADO' 
							WHEN C9_BLCRED = '  ' AND C9_BLEST = '  ' AND C9_BLTMS = '  ' THEN 'LIBERADO CREDITO'
							WHEN C9_BLCRED IN ('10','ZZ') AND C9_BLEST IN( '10','ZZ') THEN 'FATURADO'
							ELSE 'AGUARDANDO FATURAMENTO'
							END,'SEM LIBERACAO') AS LIB
					FROM %TABLE:SC9% SC9 (NOLOCK) WHERE C9_FILIAL = C5_FILIAL AND C9_PEDIDO=C5_NUM AND SC9.D_E_L_E_T_=' '
							AND C9_BLEST<>'10' and C9_BLCRED<>'10'
					ORDER BY C9_FILIAL,C9_PEDIDO,C9_BLCRED DESC,C9_BLEST DESC,C9_BLTMS DESC,C9_BLWMS DESC
				)					
				WHEN C5_BLQ='3' AND C5_DYCANPV = ' ' THEN 'PEDIDO SEM LIBERACAO DO CLIENTE' 
				WHEN C5_DYCANPV <> ' ' THEN 'PEDIDO CANCELADO' END AS SITUACAO, 
				SC5.* , A1_CGC, A1_PESSOA, E4_CODIGO, E4_DESCRI
				, SC5.D_E_L_E_T_ DEL			 
				, SC5.R_E_C_N_O_ REC			 
		FROM %TABLE:SC5% SC5 WITH (NOLOCK)
		INNER JOIN %TABLE:SA1% SA1 ON A1_COD=C5_CLIENTE AND A1_LOJA=C5_LOJACLI AND SA1.D_E_L_E_T_=' '
		LEFT JOIN %TABLE:SE4% SE4 ON E4_CODIGO = C5_CONDPAG AND SE4.D_E_L_E_T_=' '
		WHERE SC5.D_E_L_E_T_ != 'X' %EXP:cQry%
		ORDER BY C5_FILIAL, C5_NUM
		
		OFFSET %EXP:_nIni% rows
		FETCH NEXT %EXP:_nFim% rows ONLY
	
	ENDSQL
EndIf
_cSQl := GETLASTQUERY()[2]

/*
cQuery:= " SELECT * FROM "+RetSQLName("SC5")+ " SC5 "
cQuery+= " SELECT * FROM "+RetSQLName("SC5")+ " SC5 "
cQuery+= " INNER JOIN "+RetSQLName("SC6")+ " SC6 ON C5_FILIAL = C6_FILIAL AND C5_NUM =  C6_NUM  AND SC6.D_E_L_E_T_ != '*' "
cQuery+= " WHERE "
If(!empty(_cCodFil))
	cQuery+= " C5_FILIAL='"+_cCodFil+"' AND "
Else
	cQuery+= " C5_FILIAL='"+XFILIAL('SC5')+"' AND "
EndIf
If(!empty(_cCodPed))
	cQuery+= " C5_NUM='"+_cCodPed+"' AND "
EndIf
cQuery+= " C5_EMISSAO >= '20191101' AND  "
cQuery+= " SC5.D_E_L_E_T_ != '*'"
If Select(_cAlias) <> 0
   DBSelectArea(_cAlias)
   (_cAlias)->(DBCloseArea())
EndIf
DBUseArea(.T.,"TOPCONN",TCGenQry(NIL,NIL,cQuery),_cAlias,.F.,.T.)*/
(_cAlias)->(DBGOTOP())
_aValidC5 := U_WS2CAMPOS(SELF:CTIPO,'SC5')
_aValidC6 := U_WS2CAMPOS(SELF:CTIPO,'SC6')


// define o tipo de retorno do método
If(!(_cAlias)->(EOF()))
	_nJ := 1	
	::SetResponse('{')
	If(SELF:CTESTE='SQL')
		::SetResponse('"SQL":"'+STRTRAN(STRTRAN(_cSql,'	',''),'"','')+'",')
	EndIf
	::SetResponse('"REGISTROS":[')
//	SET FILTER TO REG >= _nIni .and. REG <=_nFim
//	(_cAlias)->(dbgotop())
	nPA := 0
	Do While !(_cAlias)->(Eof())
	    //Contador para inserir separador do json
	    
	   // If(_nJ >= ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO ) .AND. _nJ <= (SELF:NPAGINA * SELF:NREGISTRO ))
	    	If nPA>0
		     ::SetResponse(',')
		    EndIf 
			nPA++
			::SetResponse('{')
			_aValid := _aValidC5
			
			dbselectarea(_cAlias)
			
			_nPedTot := 0
			_nValTot := 0
			_nValFat := 0
			_nValFDC := 0
			_nValIPI := 0
			_nValICR := 0
			
			::SetResponse('"REG_NUM":'+cvaltochar((_cAlias)->REG)+',')			
			If((_cAlias)->(FIELDPOS("SITUACAO"))>0)
				::SetResponse('"STATUS":"'+alltrim((_cAlias)->SITUACAO)+'",')
			EndIf	
			If((_cAlias)->(FIELDPOS('DTLGA'))>0)
				::SetResponse('"DTALT":"'+(_cAlias)->DTLGA+'",')
			EndIf	
			If((_cAlias)->(FIELDPOS('C5_XWSDTAL'))>0)
				::SetResponse('"DTHALT":"'+(_cAlias)->C5_XWSDTAL+'",')
			EndIf	
			If((_cAlias)->(FIELDPOS('REC'))>0)
				::SetResponse('"RECNO":'+CVALTOCHAR((_cAlias)->REC)+',')
			EndIf
			If((_cAlias)->(FIELDPOS('DEL'))>0)
				::SetResponse('"DELETADO":'+CVALTOCHAR((_cAlias)->DEL)+',')
			EndIf
			::SetResponse('"EMPRESA":"'+SELF:CWSEMP+'",')
			If((_cAlias)->(FIELDPOS('E4_DESCRI'))>0)
				::SetResponse('"COND_PAG_DESCRICAO":"'+(_cAlias)->E4_DESCRI+'",')
			EndIf


			IF((_cAlias)->(FIELDPOS("C5_XICMST"))>0)
				_nValICR += (_cAlias)->C5_XICMST
			ENDIF


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
					If(Type(_aValid[_nI,5])='D')
						::SetResponse(Dtos(&(_aValid[_nI,5]))+'"')
					ElseIf(Type(_aValid[_nI,5])='C')
						::SetResponse(&(_aValid[_nI,5])+'"')
					EndIf
					::SetResponse(iif(_nI<len(_aValid),',',''))
				ElseIf(_aValid[_nI,3]=='N')
					::SetResponse('"'+_aValid[_nI,1]+'":'+alltrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
				EndIf
			Next

			If(Select(_cAliasC6)>0)
				(_cAlias)->(DBCLOSEAREA())
			EndIf	
					
			_vPedido := 0		
			
			BEGINSQL ALIAS _cAliasC6
				%NOPARSER%
				COLUMN C6_DATFAT AS DATE
				SELECT  * FROM %TABLE:SC6% SC6 (NOLOCK)
				WHERE C6_FILIAL=%EXP:_cCodFil% AND C6_NUM=%EXP:(_cAlias)->C5_NUM% AND SC6.D_E_L_E_T_ != 'X'
			
			ENDSQL
			
			dbselectarea(_cAliasC6)
			cQry := ''
			::SetResponse(', "ITENS":[')
			//Lista de itens
			Do While !(_cAliasC6)->(Eof())	
				::SetResponse('{')
				_aValid := _aValidC6
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
						::SetResponse('"'+_aValid[_nI,1]+'":"'+dtos(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='N')
						::SetResponse('"'+_aValid[_nI,1]+'":'+alltrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
					EndIf
					
				Next		
				::SetResponse('}')
				
				If((_cAliasC6)->C6_QTDENT < (_cAliasC6)->C6_QTDVEN .and. (_cAliasC6)->C6_BLOQUEI=' ')
					_nPedTot += (_cAliasC6)->C6_PRCVEN * (C6_QTDVEN - C6_QTDENT)
				EndIf
							
				IF((_cAliasC6)->(FIELDPOS("C6_ICMSRET"))>0)
					_nValICR += (_cAliasC6)->C6_ICMSRET
				ENDIF	
				IF((_cAliasC6)->(FIELDPOS("C6_DYVLIPI"))>0)
					_nValIPI += (_cAliasC6)->C6_DYVLIPI
				ENDIF
				_nValTot += (_cAliasC6)->C6_VALOR
				(_cAliasC6)->(DBSkip())
				IF(!(_cAliasC6)->(EOF()))
					::SetResponse(',')
				EndIf
				
			EndDo
			(_cAliasC6)->(DBCloseArea())
			::SetResponse('],') //Fecha Itens
			
			cQry:= "% and D2_PEDIDO='"+(_cAlias)->C5_NUM+"' %"
			
			::SetResponse('"NF":[') //Fecha Itens
			
			If(Select(_cAliasNF)>0)
				(_cAliasNF)->(dbclosearea())
			EndIf
			
			BEGINSQL ALIAS _cAliasNF
				%NOPARSER%			
				SELECT * FROM %TABLE:SF2% SF2 WITH (NOLOCK)
				INNER JOIN %TABLE:SD2% SD2 WITH (NOLOCK) ON D2_FILIAL=F2_FILIAL AND D2_DOC=F2_DOC AND F2_SERIE=D2_SERIE 
										AND F2_EMISSAO = D2_EMISSAO AND SD2.%NOTDEL%
				WHERE SF2.D_E_L_E_T_!='X' %EXP:cQry%
				ORDER BY D2_SERIE,D2_DOC,D2_ITEM
	
			ENDSQL

			DBSELECTAREA(_cAliasNF)
			
			_aValidF2 := U_WS2CAMPOS(SELF:CTIPO,'SF2')
			_aValidD2 := U_WS2CAMPOS(SELF:CTIPO,'SD2')
			nPB := 0
			Do While !(_cAliasNF)->(Eof())
			    
			    //Contador para inserir separador do json
			    If nPB>0
			     ::SetResponse(',')
			    EndIf
			    nPB++
				cChave:= (_cAliasNF)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)
				::SetResponse('{')
				_aValid := _aValidF2
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
						ElseIf(TYPE(_aValid[_nI,5])='C')
							::SetResponse(&(_aValid[_nI,5])+'"')
						EndIf
						::SetResponse(iif(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='N')
						::SetResponse('"'+_aValid[_nI,1]+'":'+alltrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
					EndIf
					
				Next
				_nValFat += (_cAliasNF)->F2_VALFAT
				_nValFDC := (_cAliasNF)->F2_DESCONT
						
				::SetResponse(', ')	
				::SetResponse('"NF_ITENS":[')			
				//Lista de itens
				Do While !(_cAliasNF)->(Eof()) .And. ;
					cChave == (_cAliasNF)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)		
					::SetResponse('{')
					_aValid := _aValidD2
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
							ElseIf(TYPE(_aValid[_nI,5])='C')
								::SetResponse(&(_aValid[_nI,5])+'"')
							EndIf
							::SetResponse(iif(_nI<len(_aValid),',',''))	
						ElseIf(_aValid[_nI,3]=='N')
							::SetResponse('"'+_aValid[_nI,1]+'":'+alltrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
						EndIf
						
					Next		
					::SetResponse('}')
					
					(_cAliasNF)->(DBSkip())
					//Verifica se continua no mesmo ITEM
					If !(_cAliasNF)->(Eof()) .And.  cChave == (_cAliasNF)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)
						::SetResponse(',')    
					Else
						::SetResponse(']') //FECHA ITEM nf
					EndIf
				EndDo
				
				
				::SetResponse('}') //FECHA ITENS	
				//(_cAliasNF)->(DBSkip())
			EndDo
			(_cAliasNF)->(DBCLOSEAREA())
			::SetResponse(']') //FECHA NOTAS	

			cQry:= "% and D2_PEDIDO='"+(_cAlias)->C5_NUM+"' AND D2_CLIENTE='"+(_cAlias)->C5_CLIENTE+"' and D2_LOJA='"+(_cAlias)->C5_LOJACLI+"' %"


			
			If(Select(_cAliasFN)>0)
				(_cAliasFN)->(dbclosearea())
			EndIf
			
			BEGINSQL ALIAS _cAliasFN
				%NOPARSER%
				COLUMN E1_EMISSAO AS DATE
				COLUMN E1_BAIXA AS DATE
				COLUMN E1_VENCTO AS DATE
				COLUMN E1_VENCREA AS DATE
			
				SELECT DISTINCT E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_VALOR,E1_SALDO,E1_EMISSAO,E1_BAIXA,
								E1_VENCTO,E1_VENCREA,E1_CLIENTE,E1_LOJA,SE1.R_E_C_N_O_ SE1REC
				FROM %TABLE:SE1% SE1 (NOLOCK)
				INNER JOIN %TABLE:SD2% SD2  (NOLOCK) ON 	D2_DOC=E1_NUM AND D2_SERIE=E1_PREFIXO AND D2_CLIENTE=E1_CLIENTE AND D2_LOJA=E1_LOJA 
												AND SD2.%NOTDEL% 
				WHERE SE1.D_E_L_E_T_!='X' %EXP:cQry%
				ORDER BY E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_CLIENTE,E1_LOJA
				
			ENDSQL
			_cSqlFin :=''
			_cSqlFin := getlastquery()[2]

			DBSELECTAREA(_cAliasFN)
					
			IF(SELF:CTESTE='SQL')
				::SetResponse(',"SQL_TITULOS":"'+_cSqlFin+'"')
			EndIf
			::SetResponse(',"TITULOS":[') //Fecha Itens
				
			_aValidE1 := U_WS2CAMPOS(SELF:CTIPO,'SE1')
			_aValidE5 := U_WS2CAMPOS(SELF:CTIPO,'SE5')
			nPC := 0
			Do While !(_cAliasFN)->(Eof())
			    
			    //Contador para inserir separador do json
			    If nPC>0
			     ::SetResponse(',')
			    EndIf
			    nPC++
				::SetResponse('{')
				_aValid := _aValidE1
				DBSELECTAREA('SE1')
				SE1->(DBGOTO((_cAliasFN)->SE1REC))
				For _nI := 1 to len(_aValid)
					IF((_cAliasFN)->(FIELDPOS(_aValid[_nI,5]))>0)
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
							ElseIf(TYPE(_aValid[_nI,5])='C')
								::SetResponse(&(_aValid[_nI,5])+'"')
							EndIf
							::SetResponse(iif(_nI<len(_aValid),',',''))			
						ElseIf(_aValid[_nI,3]=='N')
							::SetResponse('"'+_aValid[_nI,1]+'":'+alltrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
						EndIf
					EndIf
					
				Next
						
				
				
				::SetResponse('}') //FECHA TITULO	
				(_cAliasFN)->(DBSkip())
			EndDo
			(_cAliasFN)->(DBCLOSEAREA())
			::SetResponse(']') //FECHA TITULOS	


			If(Select(_cAliasA3)>0)
				(_cAlias)->(DBCLOSEAREA())
			EndIf	
					
			_vPedido := 0		
			
			_aValidA3 := U_WS2CAMPOS(SELF:CTIPO,'SC3')
			BEGINSQL ALIAS _cAliasA3
				%NOPARSER%
				COLUMN C6_DATFAT AS DATE
				SELECT  * FROM %TABLE:SA3% SA3 (NOLOCK)
				WHERE A3_COD=%EXP:(_cAlias)->C5_VEND1% AND SA3.D_E_L_E_T_ = ' '
			
			ENDSQL
			
			dbselectarea(_cAliasA3)
			cQry := ''
			::SetResponse(', "VENDEDOR_DADOS":[')
			//Lista de itens
			Do While !(_cAliasA3)->(Eof())	
				::SetResponse('{')
				_aValid := _aValidA3
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
						::SetResponse('"'+_aValid[_nI,1]+'":"'+dtos(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='N')
						::SetResponse('"'+_aValid[_nI,1]+'":'+alltrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
					EndIf
					
				Next		
				::SetResponse('}')

				(_cAliasA3)->(DBSkip())
				IF(!(_cAliasA3)->(EOF()))
					::SetResponse(',')
				EndIf
				
			EndDo
			(_cAliasA3)->(DBCloseArea())
			::SetResponse(']') //Fecha Itens



		::SetResponse(',"VALOR_TOTAL": '+CVALTOCHAR(_nValTot+_nValIPI+_nValICR))
		::SetResponse(',"VALOR_VLIPI": '+CVALTOCHAR(_nValIPI))
		::SetResponse(',"VALOR_VLICR": '+CVALTOCHAR(_nValICR))
		::SetResponse(',"VALOR_TOTFT": '+CVALTOCHAR(_nValFat))
		::SetResponse(',"VALOR_TOTDC": '+CVALTOCHAR(_nValFDC))
		If(_nPedTot > 0)
			aParc := {}
			aParc := Condicao(_nPedTot,(_CaLIAS)->C5_CONDPAG,,dDataBase)
				
	
			::SetResponse(',"CONDICAO_PAG_DEPS_ABERTO":[')
			For _nP :=1 to Len(aParc)
				If(_nP > 1)
					::SetResponse(',')
				EndIf
				::SetResponse('{')
				::SetResponse('"Parcela":'+cvaltochar(_nP)+'')
				::SetResponse(',"Valor":'+cvaltochar(aParc[_nP,2])+'')
				::SetResponse(',"Vencimento":"'+DTOS(aParc[_nP,1])+'"')
				::SetResponse(',"Dias":'+CVALTOCHAR(datediffday(date(),aParc[_nP,1]))+'')
				::SetResponse('}')
			Next
			::SetResponse(']')
		EndIf
		If(_nValTot > 0)
			aParc := {}
			aParc := Condicao(_nValTot,(_CaLIAS)->C5_CONDPAG,,dDataBase)
				
	
			::SetResponse(',"CONDICAO_PAG_DEPS_TOTAL":[')
			For _nP :=1 to len(aParc)
				If(_nP > 1)
					::SetResponse(',')
				EndIf
				::SetResponse('{')
				::SetResponse('"Parcela":'+cvaltochar(_nP)+'')
				::SetResponse(',"Valor":'+cvaltochar(aParc[_nP,2])+'')
				::SetResponse(',"Vencimento":"'+DTOS(aParc[_nP,1])+'"')
				::SetResponse(',"Dias":'+CVALTOCHAR(datediffday(date(),aParc[_nP,1]))+'')
				::SetResponse('}')
			Next
			::SetResponse(']')
		EndIf		
		::SetResponse('}')//FECHA PEDIDOS   
		
					
	    //ElseIf(_nJ > (SELF:NPAGINA * SELF:NREGISTRO ))
			//exit
	    //EndIf
	    
		(_cAlias)->(DBSkip())
	EndDo
	::SetResponse(']')//FECHA PEDIDOS
	::SetResponse(',"QUANTIDADE": '+cvaltochar(_nRegistros)+'')
	::SetResponse(',"PAGINA": '+cvaltochar(SELF:NPAGINA)+'')
	If(SELF:CWSDIC=='S')
		::SetResponse(',"DICIONARIO":{')
			::SetResponse('"PEDIDO":[')
			_aValid := _aValidC5
			For _nI := 1 to len(_aValid)
				If(_nI != 1)
					::SetResponse(",")
				EndIf
				::SetResponse("{")
				::SetResponse('"CAMPO":"'+_aValid[_nI,1]+'"')
				::SetResponse(',"TIPO":"'+_aValid[_nI,3]+'"')
				::SetResponse(',"TAM":'+CVALTOCHAR(_aValid[_nI,4])+'')
				::SetResponse(',"DESCRICAO":"'+AllTrim(STRTRAN(noacento(_aValid[_nI,7]),'"',''))+'"')
				If(!Empty(_aValid[_nI,6]))
					::SetResponse(', "OPCOES":"'+_aValid[_nI,6]+'"')
				EndIf
				::SetResponse("}")
			Next		
			::SetResponse('],')
			
			::SetResponse('"ITENS":[')
			_aValid := _aValidC6
			For _nI := 1 to len(_aValid)
				If(_nI != 1)
					::SetResponse(",")
				EndIf
				::SetResponse("{")
				::SetResponse('"CAMPO":"'+_aValid[_nI,1]+'"')
				::SetResponse(',"TIPO":"'+_aValid[_nI,3]+'"')
				::SetResponse(',"TAM":'+CVALTOCHAR(_aValid[_nI,4])+'')
				::SetResponse(',"DESCRICAO":"'+AllTrim(STRTRAN(noacento(_aValid[_nI,7]),'"',''))+'"')
				If(!Empty(_aValid[_nI,6]))
					::SetResponse(',"OPCOES":"'+_aValid[_nI,6]+'"')
				EndIf
				::SetResponse("}")
			Next		
			::SetResponse(']')
			
		::SetResponse('}')//FECHA DICIONARIO
	EndIf
	::SetResponse('}')//FECHA PEDIDOS
	
	(_cAlias)->(DBCLOSEAREA())
	(_cAlias2)->(DBCLOSEAREA())
Else

	(_cAlias)->(DBCLOSEAREA())
	(_cAlias2)->(DBCLOSEAREA())
	::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado!"}')
	SetRestFault(402,'Nenhum cadastro encontrado, verifique as informações enviadas!')		
	Return _lRet

EndIf



If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return .T.
