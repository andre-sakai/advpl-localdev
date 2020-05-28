#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"
#include "tbiconn.ch"
#include "topconn.ch"


// ##############################################################################
// Projeto  : CEK
// Autor    : ANDRE SAKAI
// Modulo   : WS
// Funcao   : WS206 - CADASTRO DE PEDIDOS DE VENDAS
// Descricao: WS PARA CONSULTA DE VENDEDORES
// Retorno  : REST COM AS INFORMACOES DA TABELA SC5,SC6
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | Andre Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

WSRESTFUL WS206 DESCRIPTION "Cadastro de Pedido de Venda"
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

WSMETHOD GET DESCRIPTION "Consulta Pedido de Venda" WSSYNTAX "/rest/WS206 || /rest/WS206/{FILIAL}/{PEDIDO}"
WSMETHOD POST DESCRIPTION "Inclus�o de Pedido de Venda" WSSYNTAX "/rest/WS206"
WSMETHOD PUT DESCRIPTION "Atualiza��o em teste" WSSYNTAX "/rest/WS206/{Filial}/{Pedido}"
WSMETHOD DELETE DESCRIPTION "Exclus�o em teste" WSSYNTAX "/rest/WS206/{Filial}/{Pedido}"

END WSRESTFUL

WSMETHOD GET WSSERVICE WS206

Local _cVldTkn := ''
Local _lRet := .F.
Local _cCod := ''
Local _nI,_nJ,_nReg, _nIni, _nFim
Local _lPrepEnv := .F.			  
Local nPrimeiro := 0
Local _cAlias, _cAlias2, _cAliasC6, _cAliasNF
Local _cCodFil,_cCodPed
Local _aValidc5 := {},_aValidc6 := {}
Local _nRegistros := 0

Private _aValid := {}
Private _cWSName := 'WS206'

Default _cCodFil:=''
Default _cCodPed:=''

Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''
Default SELF:CTESTE 	:=''
Default SELF:CDTFILTRO 	:=''

DEFAULT SELF:CWSEMP := '01'
DEFAULT SELF:CWSFIL := '0101'
DEFAULT SELF:CWSDIC := 'N'

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "","","","",{"SA1","SA2","SA3","SA4", "SC5","SC6", "SF2","SD2", "SE1","SE2"}) 
	_lPrepEnv := .T.
EndIf


::SetContentType("application/json")

_cVldTkn := AllTrim(GETMV('MV_TKNREST',.T.,'123456'))

If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verIfique a chave! '+SELF:pToken)
	Return .F.
Else
	//conout('','Token Ok')
EndIf

If Len(::aURLParms) > 0
	// insira aqui o codigo para pesquisa do parametro recebido
	// consulta de cliente por documento
	_cCodFil := padr(::aURLParms[1],tamsx3('C5_FILIAL')[1])
	
	If(LEN(::aURLParms)>=2)
		_cCodPed := padr(::aURLParms[2],tamsx3('C5_NUM')[1])
	EndIf
Else
	_cCodFil := SELF:CWSFIL
EndIf

_cAlias 	:= getnextalias()
_cAlias2 	:= getnextalias()
_cAliasC6 	:= getnextalias()
_cAliasNF 	:= getnextalias()
_cAliasFN 	:= getnextalias()

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
	cQry+= " AND C5_EMISSAO >= '20190101' "

EndIf

If(!EMPTY(SELF:CDTFILTRO))
	If(SC5->(fieldpos('C5_USERLGI')>0))	
		cQry+= " AND CASE 	WHEN C5_USERLGA = ' ' "
		cQry+= "	THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGI,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120) "
		cQry+= "	ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGA,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) END >= '"+SELF:CDTFILTRO+"' "
	EndIf	
EndIf

cQry+="%"

If(Select(_cAlias2)>0)
	(_cAlias2)->(DBCLOSEAREA())
EndIf

BEGINSQL ALIAS _cAlias2
	%NOPARSER%
	SELECT count(*) nReg FROM %TABLE:SC5% SC5
	WHERE SC5.D_E_L_E_T_ != '*' %EXP:cQry%
ENDSQL

If((_cAlias2)->(!EOF()))
	_nRegistros := (_cAlias2)->nReg
Else
	_nRegistros := 0
EndIf


If(SELECT(_cAlias)>0)
	(_cAlias)->(DBCLOSEAREA())
EndIf


_nIni := (((SELF:NPAGINA -1) * SELF:NREGISTRO ))
_nFim := SELF:NREGISTRO

If(SC5->(fieldpos('C5_USERLGI')>0))
/*
aAdd(aCores,{" Empty(SC5->C5_LIBEROK) .And.  Empty(SC5->C5_NOTA)  .And. Empty(SC5->C5_BLQ) .And. Empty(SC5->C5_DYCANPV) ", 'ENABLE',     "Pedido em Aberto"})
aAdd(aCores,{"!Empty(SC5->C5_NOTA)    .Or.   SC5->C5_LIBEROK=='E' .And. Empty(SC5->C5_BLQ) .And. Empty(SC5->C5_DYCANPV) ", 'DISABLE',    "Pedido Encerrado"})
aAdd(aCores,{"!Empty(SC5->C5_LIBEROK) .And.  Empty(SC5->C5_NOTA)  .And. Empty(SC5->C5_BLQ) .And. Empty(SC5->C5_DYCANPV) ", 'BR_AMARELO', "Pedido Liberado"})
aAdd(aCores,{"SC5->C5_BLQ == '1' .And. Empty(SC5->C5_DYCANPV)",                                                            'BR_AZUL',    "Pedido Bloquedo por regra"})
aAdd(aCores,{"SC5->C5_BLQ == '2' .And. Empty(SC5->C5_DYCANPV)",                                                            'BR_LARANJA', "Pedido Bloquedo por verba"})
aAdd(aCores,{"SC5->C5_BLQ == '3' .And. Empty(SC5->C5_DYLIBER) .And. Empty(SC5->C5_DYCANPV)",                               'BR_BRANCO',  "Pedido sem liberacao do cliente"})
aAdd(aCores,{"!Empty(SC5->C5_DYCANPV)",                                                                                    'BR_PRETO',   "Pedido Cancelado"})


*/
	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		COLUMN C5_EMISSAO AS DATE
		SELECT ROW_NUMBER() OVER(ORDER BY C5_FILIAL, C5_NUM ASC) REG,
				CASE 	WHEN C5_USERLGA = ' ' 
						THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGI,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
						ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGA,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) 
				END DTLGA, 
				CASE WHEN C5_LIBEROK = '' AND C5_NOTA='' AND C5_BLQ=''  THEN 'ABERTO'
				WHEN C5_NOTA != ' ' OR C5_LIBEROK='E' AND C5_BLQ=''  THEN 'ENCERRADO'
				WHEN C5_LIBEROK!=' ' AND   C5_NOTA=' ' AND C5_BLQ =' '  THEN 'LIBERADO'
				WHEN C5_BLQ='1'  THEN 'BLOQUEIO REGRA'
				WHEN C5_BLQ='2' THEN 'BLOQUEIO VERBA' END AS SITUACAO, * 
				FROM %TABLE:SC5% SC5
		WHERE SC5.D_E_L_E_T_ != '*' %EXP:cQry%
		ORDER BY C5_FILIAL, C5_NUM
		
		OFFSET %EXP:_nIni% rows
		FETCH next %EXP:_nFim% rows ONLY
	
	ENDSQL
ELSE

	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		COLUMN C5_EMISSAO AS DATE
		SELECT ROW_NUMBER() OVER(ORDER BY C5_FILIAL, C5_NUM ASC) REG, 
				CASE WHEN C5_LIBEROK = '' AND C5_NOTA='' AND C5_BLQ=''  THEN 'ABERTO'
				WHEN C5_NOTA != ' ' OR C5_LIBEROK='E' AND C5_BLQ=''  THEN 'ENCERRADO'
				WHEN C5_LIBEROK!=' ' AND   C5_NOTA=' ' AND C5_BLQ =' '  THEN 'LIBERADO'
				WHEN C5_BLQ='1'  THEN 'BLOQUEIO REGRA'
				WHEN C5_BLQ='2' THEN 'BLOQUEIO VERBA' END AS SITUACAO, * 
		FROM %TABLE:SC5% SC5
		INNER JOIN %TABLE:SE4% SE4 ON E4_FILIAL=%EXP:xFilial('SE4')% and E4_CODIGO=C5_CONDPAG AND SE4.D_E_L_E_T_=' '
		WHERE SC5.D_E_L_E_T_ != '*' %EXP:cQry%
		ORDER BY C5_FILIAL, C5_NUM
		
		OFFSET %EXP:_nIni% rows
		FETCH next %EXP:_nFim% rows ONLY
	
	ENDSQL
EndIf
_cSql := GETLASTQUERY()[2]

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
_aValidC5 := U_WSCAMPOS(SELF:CTIPO,'SC5')
_aValidC6 := U_WSCAMPOS(SELF:CTIPO,'SC6')


// define o tipo de retorno do metodo
If(!(_cAlias)->(EOF()))
	_nJ := 1
	::SetResponse('{')
	If(SELF:CTESTE='SQL')
		::SetResponse('"SQL":"'+STRTRAN(STRTRAN(_cSql,'	',''),'"','')+'",')
	EndIf
	
	::SetResponse('"REGISTROS":[')	
	/*
	_nIni := ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO )
	_nFim := (SELF:NPAGINA * SELF:NREGISTRO)
	SET FILTER TO REG >= _nIni .and. REG <=_nFim
	(_cAlias)->(dbgotop())
	*/
	Do While !(_cAlias)->(Eof())
	    //Contador para inserir separador do json
	    
	   // If(_nJ >= ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO ) .AND. _nJ <= (SELF:NPAGINA * SELF:NREGISTRO ))
			::SetResponse('{')
			_aValid := _aValidC5
			
			dbselectarea(_cAlias)
			
			::SetResponse('"REG_NUM":'+cvaltochar((_cAlias)->REG)+',')
			::SetResponse('"INF_ADICIONAIS":"'+WSPEDVEN((_cAlias)->C5_NUM,_cAlias)+'",')
			If((_cAlias)->(FIELDPOS("SITUACAO"))>0)
				::SetResponse('"STATUS":"'+AllTrim((_cAlias)->SITUACAO)+'",')
			EndIf
			If((_cAlias)->(FIELDPOS("E4_COND"))>0)
				::SetResponse('"COND_PAG_DIAS":"'+AllTrim((_cAlias)->E4_COND)+'",')
			EndIf
			If((_cAlias)->(FIELDPOS("DTALT"))>0)
				::SetResponse('"DTALT":"'+AllTrim((_cAlias)->DTALT)+'",')
			EndIf
			If((_cAlias)->(FIELDPOS("C5_WSDTALT"))>0)
				::SetResponse('"DTHALT":"'+AllTrim((_cAlias)->C5_WSDTALT)+'",')
			EndIf
			
			dbselectarea(_cAlias)
			
			For _nI := 1 to len(_aValid)
				If(_aValid[_nI,3]=='C')
					::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
				ElseIf(_aValid[_nI,3]=='M')
					::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
				ElseIf(_aValid[_nI,3]=='O')
					//nao tratado - somente para compatibilidade com outras funcoes
				ElseIf(_aValid[_nI,3]=='L')
					::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))			
				ElseIf(_aValid[_nI,3]=='D')
					::SetResponse('"'+_aValid[_nI,1]+'":"')
					If(Type(_aValid[_nI,5])='D')
						::SetResponse(dtos(&(_aValid[_nI,5]))+'"')
					ElseIf(Type(_aValid[_nI,5])='C')
						::SetResponse(&(_aValid[_nI,5])+'"')
					EndIf
					::SetResponse(iIf(_nI<len(_aValid),',',''))			
				ElseIf(_aValid[_nI,3]=='N')
					::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))
				EndIf
			Next

			If(SELECT(_cAliasC6)>0)
				(_cAlias)->(DBCLOSEAREA())
			EndIf
					
			BEGINSQL ALIAS _cAliasC6
				%NOPARSER%
				COLUMN C6_DATFAT AS DATE
				SELECT  * FROM %TABLE:SC6% SC6
				WHERE C6_FILIAL=%EXP:_cCodFil% AND C6_NUM=%EXP:(_cAlias)->C5_NUM% AND SC6.D_E_L_E_T_ != '*'
			
			ENDSQL
			
			_cSqlIt := getlastquery()[2]
			If(SELF:CTESTE='SQL')
				::SetResponse(',"SQL_ITENS":"'+STRTRAN(STRTRAN(_cSqlIt,'	',''),'"','')+'"')
			EndIf
			dbselectarea(_cAliasC6)
			cQry := ''
			::SetResponse(', "ITENS":[')
			//Lista de itens
			Do While !(_cAliasC6)->(Eof())	
				::SetResponse('{')
				_aValid := _aValidC6
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='M')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='O')
						//nao tratado - somente para compatibilidade com outras funcoes
					ElseIf(_aValid[_nI,3]=='L')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='D')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+dtos(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='N')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))
					EndIf
					
				Next		
				::SetResponse('}')
				
				
				
				(_cAliasC6)->(DBSkip())
				If(!(_cAliasC6)->(EOF()))
					::SetResponse(',')
				EndIf
				
			EndDo
			(_cAliasC6)->(DBCloseArea())
			::SetResponse('],') //Fecha Itens
			
			cQry:= "% and D2_PEDIDO='"+(_cAlias)->C5_NUM+"' AND D2_FILIAL='"+_cCodFil+"' %"
			
			::SetResponse('"NF":[') //Fecha Itens
			
			If(Select(_cAliasNF)>0)
				(_cAliasNF)->(dbclosearea())
			EndIf
			
			BEGINSQL ALIAS _cAliasNF
				%NOPARSER%
				COLUMN E1_EMISSAO AS DATE
				COLUMN E1_VENCTO  AS DATE
				COLUMN E1_VENCREA AS DATE
			
				SELECT * FROM %TABLE:SF2% SF2
				INNER JOIN %TABLE:SD2% SD2 ON D2_FILIAL=F2_FILIAL AND D2_DOC=F2_DOC AND F2_SERIE=D2_SERIE 
										AND F2_EMISSAO = D2_EMISSAO AND SD2.%NOTDEL%
				WHERE SF2.D_E_L_E_T_='' %EXP:cQry%
				ORDER BY D2_SERIE,D2_DOC,D2_ITEM
				
			ENDSQL

			DBSELECTAREA(_cAliasNF)
						
			_aValidF2 := U_WSCAMPOS(SELF:CTIPO,'SF2')
			_aValidD2 := U_WSCAMPOS(SELF:CTIPO,'SD2')
			nPNot := 0
			Do While !(_cAliasNF)->(Eof())
			    
			    //Contador para inserir separador do json
			    If nPNot>0
			     ::SetResponse(',')
			    EndIf
			    nPNot+= 1
				cChave:= (_cAliasNF)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)
				::SetResponse('{')
				_aValid := _aValidF2
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='M')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='O')
						//nao tratado - somente para compatibilidade com outras funcoes
					ElseIf(_aValid[_nI,3]=='L')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='D')
						::SetResponse('"'+_aValid[_nI,1]+'":"')
						If(Type(_aValid[_nI,5])='D')
							::SetResponse(dtos(&(_aValid[_nI,5]))+'"')
						ElseIf(Type(_aValid[_nI,5])='C')
							::SetResponse(&(_aValid[_nI,5])+'"')
						EndIf
						::SetResponse(iIf(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='N')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))
					EndIf
					
				Next
						
				::SetResponse(', ')	
				::SetResponse('"NF_ITENS":[')			
				//Lista de itens
				Do While !(_cAliasNF)->(Eof()) .And. ;
				  cChave == (_cAliasNF)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)		
					::SetResponse('{')
					_aValid := _aValidD2
					For _nI := 1 to len(_aValid)
						If(_aValid[_nI,3]=='C')
							::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
						ElseIf(_aValid[_nI,3]=='M')
							::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
						ElseIf(_aValid[_nI,3]=='O')
							//nao tratado - somente para compatibilidade com outras funcoes
						ElseIf(_aValid[_nI,3]=='L')
							::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))			
						ElseIf(_aValid[_nI,3]=='D')
							::SetResponse('"'+_aValid[_nI,1]+'":"'+dtos(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))			
						ElseIf(_aValid[_nI,3]=='N')
							::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))
						EndIf
						
					Next		
					::SetResponse('}')
					
					(_cAliasNF)->(DBSkip())
					//VerIfica se continua no mesmo ITEM
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

			cQry:= "% and D2_PEDIDO='"+(_cAlias)->C5_NUM+"' AND D2_FILIAL='"+_cCodFil+"' %"



			
			::SetResponse(',"TITULOS":[') //Fecha Itens
			
			If(Select(_cAliasFN)>0)
				(_cAliasFN)->(dbclosearea())
			EndIf
			
			BEGINSQL ALIAS _cAliasFN
				%NOPARSER%
				COLUMN E1_EMISSAO AS DATE
				COLUMN E1_BAIXA AS DATE
				COLUMN E1_VENCTO AS DATE
				COLUMN E1_VENCREA AS DATE
			
				SELECT DISTINCT E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_VALOR,E1_SALDO,E1_SALDO,E1_BAIXA,
								E1_VENCTO,E1_VENCREA,E1_CLIENTE,E1_LOJA,SE1.R_E_C_N_O_ SE1REC
				FROM %TABLE:SE1% SE1
				INNER JOIN %TABLE:SD2% SD2 ON 	D2_DOC=E1_NUM AND D2_SERIE=E1_PREFIXO AND D2_CLIENTE=E1_CLIENTE AND D2_LOJA=E1_LOJA 
												AND SD2.%NOTDEL% 
				WHERE E1_FILIAL=%EXP:XFILIAL('SE1')% AND SE1.D_E_L_E_T_='' %EXP:cQry%
				ORDER BY E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO
				
			ENDSQL
			
			_cSqlFin := getlastquery()[2]
			If(SELF:CTESTE='SQL')
				::SetResponse(',"SQL_FIN":"'+STRTRAN(STRTRAN(_cSqlFin,'	',''),'"','')+'"')
			endif
			DBSELECTAREA(_cAliasFN)
						
			_aValidE1 := U_WSCAMPOS(SELF:CTIPO,'SE1')
			_aValidE5 := U_WSCAMPOS(SELF:CTIPO,'SE5')
			nPFin := 0
			Do While !(_cAliasFN)->(Eof())
			    
			    //Contador para inserir separador do json
			    If nPFin>0
			     ::SetResponse(',')
			    EndIf
			    nPFin+= 1
				::SetResponse('{')
				_aValid := _aValidE1
				DBSELECTAREA('SE1')
				SE1->(DBGOTO((_cAliasFN)->SE1REC))
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(NOACENTO(&(_aValid[_nI,5])))+'"'+iIf(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='M')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='O')
						//nao tratado - somente para compatibilidade com outras funcoes
					ElseIf(_aValid[_nI,3]=='L')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='D')
						::SetResponse('"'+_aValid[_nI,1]+'":"')
						If(Type(_aValid[_nI,5])='D')
							::SetResponse(dtos(&(_aValid[_nI,5]))+'"')
						ElseIf(Type(_aValid[_nI,5])='C')
							::SetResponse(&(_aValid[_nI,5])+'"')
						EndIf
						::SetResponse(iIf(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='N')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))
					EndIf
					
				Next
						
				
				
				::SetResponse('}') //FECHA TITULO	
				(_cAliasFN)->(DBSkip())
			EndDo
			(_cAliasFN)->(DBCLOSEAREA())
			::SetResponse(']') //FECHA TITULOS	
			
			// mensagens de gravacao ZW0
			dbselectarea("ZW0")
			ZW0->(dbsetorder(1))
			SET FILTER TO &("@ ZW0_CHAVE = '"+(_cAlias)->(C5_FILIAL+C5_NUM)+"' AND ZW0_TABELA='WS206' ")
			ZW0->(dbGOBOTTOM())
			
			_cNumProt := ''
			If(!ZW0->(BOF()))
				::SetResponse(',"LOG_ALTERACAO":[') //FECHA TITULOS	
				While(!ZW0->(BOF()))
					::SetResponse(AllTrim(ZW0->ZW0_MENRET))
					if(empty(_cNumProt) .and. !EMPTY(ZW0->ZW0_PROTOC))
						_cNumProt := '"PROTOCOLO":"'+ALLTRIM(ZW0->ZW0_PROTOC)+'"'
					endif
					ZW0->(dbskip(-1))
					If(!ZW0->(BOF()))
						::SetResponse(',')
					EndIf
				ENDDO
				::SetResponse(']') //FECHA TITULOS	
			EndIf
			IF(!EMPTY(_cNumProt))
				::SetResponse(','+_cNumProt)
			ENDIF
		::SetResponse('}')//FECHA PEDIDOS   
		
					
	    //ElseIf(_nJ > (SELF:NPAGINA * SELF:NREGISTRO ))
			//exit
	    //EndIf
	    
		(_cAlias)->(DBSkip())
		If !(_cAlias)->(EOF())
			::SetResponse(',')
		EndIf 
		
	EndDo
	::SetResponse('],')//FECHA PEDIDOS
	::SetResponse('"QUANTIDADE": '+cvaltochar(_nRegistros)+',')
	::SetResponse('"PAGINA": '+cvaltochar(SELF:NPAGINA)+'')
	If(SELF:CWSDIC=='S')
		::SetResponse(',"DICIONARIO":{')
			::SetResponse('"PEDIDO":[')
			_aValid := _aValidC5
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
			
			::SetResponse('"ITENS":[')
			_aValid := _aValidC6
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
	EndIf
	::SetResponse('}')//FECHA PEDIDOS
	
	(_cAlias)->(DBCLOSEAREA())
	(_cAlias2)->(DBCLOSEAREA())
	
	_lRet := .t.
ELSE

	(_cAlias)->(DBCLOSEAREA())
//	(_cAlias2)->(DBCLOSEAREA())
	::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado!"}')
	SetRestFault(402,'Nenhum cadastro encontrado, verIfique as informa��es enviadas!')		
	Return _lRet

EndIf

//RpcClearEnv()


Return _lRet
 
 
WSMETHOD POST WSSERVICE WS206
Local _lRet := .T.
Local _nI,_nJ
//Local _nMaxReg := 30
Local _cContent 	:= ''
Local _aRetError 	:= {}
Local _aValid 		:= {}
Local _aValidC5 	:= {}
Local _aValidC6 	:= {}
Local _cVldTkn 		:= ''
Local _lPrepEnv 	:= .F.
Local _cAliasC6 	:= getnextalias()
Local _cCodTran := ''

Private _oBody
Private _oCab
Private _oItens
Private _oItem
Private lMsErroAuto
Private lAutoErrNoFile
Private cArquivo := '/data/log-ws206-'+dtos(date())+'_'+strtran(time(),':','')+'.log'
Private _cWSname := 'WS206'

Default SELF:cTipo :=''
Default SELF:cFiltro := '' 
Default SELF:CWSEMP := '01'
Default SELF:CWSFIL := '0101'
Default SELF:CWSDIC := 'S'
Default SELF:NPAGINA := 1
Default SELF:NREGISTRO := 20

If(select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "","","","",{"SA1","SA2","SC5","SC6","SC9","SF1","SF2","SD1","SD2"}) 
	_lPrepEnv := .T.
EndIf


::SetContentType("application/json")


_cCodFil := SELF:CWSFIL

CONOUT('WS 206 - PREPAROU AMBIENTE')

_cVldTkn := AllTrim(GETMV('MV_TKNREST',.T.,'123456'))

If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verIfique a chave! '+SELF:pToken)
	Return .F.
Else
	//conout('','Token Ok')
EndIf

_cContent  := SELF:GetContent()
FWJsonDeserialize(_cContent,@_oBody)

_nI := 1
While(Type('_oBody')='U' .and. _nI < 5)
	FWJsonDeserialize(_cContent,@_oBody)
	_nI++
	If(Type('_oBody')!='U')
		EXIT
	EndIf
EndDo

_aValidC5 := U_WSCAMPOS('','SC5',.T.)
_aValidC6 := U_WSCAMPOS('','SC6',.T.)


//::SetContentType("TEXT/HTML")
//::SetResponse(varinfo('_A',_oBody))
If(Type('_oBody')== 'O')
	/*
	_cAlias1 := getnextalias()
	DBSELECTAREA('ZI0')
	DBSETORDER(1)
	
	BEGINSQL ALIAS_cAlias1
		SELECT * FROM %TABLE:ZI0% ZI0 WHERE D_E_L_E_T_=' ' AND ZI0_WS = 'WS206_POST'
		AND CONVERT(VARCHAR(MAX),CONVERT(varbinary(MAX),ZI0_JSON))= %EXP:_cContent%
		AND ZI0_FILIAL=%EXP:SELF:CWSFIL%
	ENDSQL
	
	If((_cAlias1)->(EOF()))
		RECLOCK('ZI0',.T.)
			ZI0->ZI0_FILIAL := XfILIAL('ZI0')
			ZI0->ZI0_WS 	:= 'Z206_POST'
			ZI0->ZI0_NUM	:= GETSXENUM('ZI0','ZI0_NUM',ZI0->ZI0_FILIAL+ZI0->ZI0_WS)
			ZI0->ZI0_JSON	:= _cContent
			ZI0->ZI0_DATA	:= date()
			ZI0->ZI0_STATUS :=' '
		ZI0->(MSUNLOCK())
	EndIf
	*/
	CONOUT('WS 206 - ENTROU 1')
	_oCab 	:= _oBody

	_aValid := _aValidC5
	CONOUT('WS 206 - INICIO VALIDACAO PEDIDO')
	For _nI := 1 to Len (_aValid) 	
		If(AllTrim(_aValid[_nI][5]) = 'A1_TRANSP' )
			
		EndIf
		If (Type('_oCab:'+_aValid[_nI][1])=="U" .AND. _aValid[_nI][2]==.T.)
			aAdd(_aRetError,{'500','Campo '+_aValid[_nI][1]+' nao foi declarado'})
		Else
			If(_aValid[_nI][3]=='D')
				If(Type('_oCab:'+_aValid[_nI][1])=="C")
					&('_oCab:'+_aValid[_nI][1]) := stod(&('_oCab:'+_aValid[_nI][1]))
				EndIf
			EndIf
			If(Type('_oCab:'+_aValid[_nI][1])!=_aValid[_nI][3] .AND. Type('_oCab:'+_aValid[_nI][1])<>"U")
				aAdd(_aRetError,{'500','Campo '+_aValid[_nI][1]+' com Tipo: '+Type('_oCab:'+_aValid[_nI][1])+' - Esperado: '+_aValid[_nI][3]})
			EndIf
		EndIf
	
	Next _nI
	CONOUT('eRROS: '+CVALTOCHAR(LEN(_aRetError)))
	CONOUT('WS 206 - fim VALIDACAO PEDIDO')

	_oItens := _oBody:ITENS
	
	_aValid := _aValidC6
	For _nJ := 1 to Len(_oItens)
		CONOUT('WS 206 - INICIO VALIDACAO PEDIDO - Item' + CVALTOCHAR(_nJ))
		_oItem := _oItens[_nJ]
		For _nI := 1 to Len (_aValid) 	
			If (Type('_oItem:'+_aValid[_nI][1])=="U" .AND. _aValid[_nI][2]==.T.)
			aAdd(_aRetError,{'500','Item '+cvaltochar(_nJ)+' Campo '+_aValid[_nI][1]+' nao foi declarado'})
		Else
			If(_aValid[_nI][3]=='D')
				If(Type('_oItem:'+_aValid[_nI][1])=="C")
					&('_oItem:'+_aValid[_nI][1]) := stod(&('_oItem:'+_aValid[_nI][1])) // muda string para data
				EndIf
			EndIf
			If(Type('_oItem:'+_aValid[_nI][1])!=_aValid[_nI][3] .AND. Type('_oItem:'+_aValid[_nI][1])<>"U")
				aAdd(_aRetError,{'500','Item '+cvaltochar(_nJ)+' Campo '+_aValid[_nI][1]+' com Tipo: '+Type('_oItem:'+_aValid[_nI][1])+' - Esperado: '+_aValid[_nI][3]})
			EndIf
		EndIf
		
		Next _nI
		CONOUT('WS 206 - fim VALIDACAO PEDIDO - Item' + CVALTOCHAR(_nJ))

	Next

	::SetResponse('{"RETORNO":')
	If (Len(_aRetError) = 0)
		conout('Mensagens - sem erros')
		_aCabAuto := {}
		
		_aValid := U_WSCAMPOS('','SC5',.T.)
		
		_nI := 1
		For _nI := 1 to Len(_aValid)
			If(Type('_oCab:'+_aValid[_nI][1])!='U' .and. ! AllTrim(_aValid[_nI][5]) $ 'C5_EMISSAO#C5_NUM#')
				If(AllTrim(_aValid[_nI][5]) $ 'C5_CLIENTE')
					_cCodCli := &('_oCab:'+_aValid[_nI][1])
				ElseIf(AllTrim(_aValid[_nI][5]) $ 'C5_LOJA')
					_cCodLoja := &('_oCab:'+_aValid[_nI][1])
				ElseIf(AllTrim(_aValid[_nI][5]) $ 'C5_TRANP')
					If(AllTrim(&('_oCab:'+_aValid[_nI][1]))='')
						SA1->(DBSETORDER(1))
						If(SA1->(DBSEEK(XFILIAL('SA1')+PADR(_cCodCli,TAMSX3('A1_COD')[1])+PADR(_cCodLoja,TAMSX3('A1_LOJA')[1]))))
							_cCodTran := SA1->A1_TRANSP
						EndIf
					EndIf
				EndIf
				aadd(_aCabAuto,{_aValid[_nI][5]	,&('_oCab:'+_aValid[_nI][1]) , nil})
			EndIf				
		Next
	
	
		_aIteAuto := {}
		conout('itens: '+cvaltochar(Len (_oItens)))
		For nFor:= 1 To Len (_oItens)
			_oItem := _oItens[nFor]
			
			_aLinha := {}
			_cFor := strzero(nFor,tamsx3('C6_ITEM')[1]) 
			aadd(_aLinha,{"C6_FILIAL", XFILIAL('SC6'), Nil})
			aadd(_aLinha,{"C6_ITEM", _cFor, Nil})
			
			_nI := 1
			
			_aValid := U_WSCAMPOS('','SC6',.T.)
			
			For _nI := 1 to Len(_aValid)
				conout('ws 206 567',Type('_oItem:'+_aValid[_nI][1])!='U')
				If(Type('_oItem:'+_aValid[_nI][1])!='U' .and. ! AllTrim(_aValid[_nI][5]) $ 'C6_ITEM#C6_FILIAL#')
					aadd(_aLinha,{AllTrim(_aValid[_nI][5]), &('_oItem:'+_aValid[_nI][1]), Nil})
					//_oModel:SetValue(_cModel,_aValid[_nI][5],&('_oClient:'+_aValid[_nI][1]))
				EndIf				
			Next

		    //aadd(_aLinha,{"C6_PEDCLI" , oCorpo:ITENS[nFor]:C6_PEDCLI, Nil})
			//aadd(_aLinha,{"AUTDELETA" , "N"                , Nil})
		
			Aadd(_aIteAuto,_aLinha)
		Next

		lMsErroAuto := .F.
		lAutoErrNoFile := .T.
		conout('POST','563 - INICIO EXECAUTO '+DTOS(DATE())+' - '+TIME())
			
		//	VARINFO('_aCabAuto 1',_aCabAuto)
		//	VARINFO('_aIteAuto 1',_aIteAuto)
		// rotina automatica do pedido de venda
		MsExecAuto({|x,y,z| Mata410(x,y,z)},_aCabAuto,_aIteAuto,3) // 3-inclusao

		conout('POST','563 - FIM EXECAUTO '+DTOS(DATE())+' - '+TIME())
		If !lMsErroAuto  // operacao se deu erro

			::SetResponse('{')
			::SetResponse('"PEDIDO":{')

			_aValidC5 := U_WSCAMPOS('','SC5')
			_aValidC6 := U_WSCAMPOS('','SC6')
			
			_aValid := _aValidC5
			_cAlias := "SC5"
			dbselectarea(_cAlias)
			
			For _nI := 1 to len(_aValid)
				If(_aValid[_nI,3]=='C')
					::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
				ElseIf(_aValid[_nI,3]=='M')
					::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
				ElseIf(_aValid[_nI,3]=='O')
					//n�o tratado - somente para compatibilidade com outras fun��es
				ElseIf(_aValid[_nI,3]=='L')
					::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))			
				ElseIf(_aValid[_nI,3]=='D')
					::SetResponse('"'+_aValid[_nI,1]+'":"')
					If(Type(_aValid[_nI,5])='D')
						::SetResponse(dtos(&(_aValid[_nI,5]))+'"')
					ElseIf(Type(_aValid[_nI,5])='C')
						::SetResponse(&(_aValid[_nI,5])+'"')
					EndIf
					::SetResponse(iIf(_nI<len(_aValid),',',''))			
				ElseIf(_aValid[_nI,3]=='N')
					::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))
				EndIf
			Next
			If(Select(_cAliasC6)>0)
				(_cAlias)->(DBCLOSEAREA())
			EndIf	
					
			BEGINSQL ALIAS _cAliasC6
				%NOPARSER%
				COLUMN C6_DATFAT AS DATE
				SELECT  * FROM %TABLE:SC6% SC6
				WHERE C6_FILIAL=%EXP:_cCodFil% AND C6_NUM=%EXP:(_cAlias)->C5_NUM% AND SC6.D_E_L_E_T_ != '*'
			
			ENDSQL
			
			dbselectarea(_cAliasC6)
			cQry := ''
			::SetResponse(', "ITENS":[')
			//Lista de itens
			_aValid := _aValidC6
			_NiT := 0
			Do While !(_cAliasC6)->(Eof())
				::SetResponse('{')
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='M')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
					ElseIf(_aValid[_nI,3]=='O')
						//n�o tratado - somente para compatibilidade com outras fun��es
					ElseIf(_aValid[_nI,3]=='L')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='D')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+dtos(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='N')
						::SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))
					EndIf
					
				Next		
				::SetResponse('}')

				(_cAliasC6)->(DBSkip())
				If(!(_cAliasC6)->(EOF()))
					::SetResponse(',')
				EndIf
				
			EndDo
			::SetResponse(']') //Fecha Itens
			::SetResponse('}') //Fecha Pedido
			::SetResponse('}') //Fecha Pedido
		Else
			_aErroAuto := GetAutoGRLog()
			cMsg:= "ERRO - PEDIDO VENDA -Arquivo: "+cArquivo
			For _nCount := 1 To Len(_aErroAuto)
				cMsg += StrTran(StrTran(StrTran(_aErroAuto[_nCount],"<",""),"-",""),"   "," ") + (" ")
			Next _nCount	
			::SetResponse('["Erro":"'+formatjson(cMsg)+'"]')
			
			SetRestFault(401,'Erro: '+formatjson(cMsg)+'.')
			_lRet := .f.				
		EndIf


	Else
		::SetResponse('[') //Fecha Itens
		If(Len(_aRetError)>0)
			//conout(varinfo('_aRetError',_aRetError))
			::SetResponse(U_WS002RET(_aRetError))
			
			//::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado ('+_cDoc+')!"}')
			//SetRestFault(402,'Erro - Nenhum cadastro encontrado! VerIfique as informa��es enviadas!')
			

		EndIf
		::SetResponse(']') //Fecha Itens
	
	EndIf
	::SetResponse("}")
	
ElseIf(Type('_oBody')== 'A')

	CONOUT('WS 206 - ENTROU 2')
	
	For _nJ :=1 to Len(_oBody)
		CONOUT('WS 206 - INICIO VALIDACAO PEDIDO' + CVALTOCHAR(_nJ))
		
		_oCab := _oBody[_nJ]
		
		_aValid := _aValidC5
		For _nI := 1 to Len (_aValid) 				
			If (Type('_oCab:'+_aValid[_nI][1])=="U" .AND. _aValid[_nI][2]==.T.)
				aAdd(_aRetError,{'500','Campo '+_aValid[_nI][1]+' nao foi declarado'})
			Else
				If(_aValid[_nI][3]=='D')
					If(Type('_oCab:'+_aValid[_nI][1])=="C")
						&('_oCab:'+_aValid[_nI][1]) := stod(&('_oCab:'+_aValid[_nI][1]))
					EndIf
				EndIf
				If(Type('_oCab:'+_aValid[_nI][1])!=_aValid[_nI][3] .AND. Type('_oCab:'+_aValid[_nI][1])<>"U")
					aAdd(_aRetError,{'500','Campo '+_aValid[_nI][1]+' com Tipo: '+Type('_oCab:'+_aValid[_nI][1])+' - Esperado: '+_aValid[_nI][3]})
				EndIf
			EndIf
		
		Next _nI
		
		_oItens := _oCab:ITENS
		
		_aValid := _aValidC6
		For _nK := 1 to Len(_oItens)
			CONOUT('WS 206 - INICIO VALIDACAO PEDIDO - ITENS' + CVALTOCHAR(_nK))
			_oItem := _oItens[_nK]
			For _nI := 1 to Len (_aValid) 				
				If (Type('_oItem:'+_aValid[_nI][1])=="U" .AND. _aValid[_nI][2]==.T.)
				aAdd(_aRetError,{'500','Item '+cvaltochar(_nJ)+' Campo '+_aValid[_nI][1]+' nao foi declarado'})
			Else
				If(_aValid[_nI][3]=='D')
					If(Type('_oItem:'+_aValid[_nI][1])=="C")
						&('_oItem:'+_aValid[_nI][1]) := stod(&('_oItem:'+_aValid[_nI][1])) // muda string para data
					EndIf
				EndIf
				If(Type('_oItem:'+_aValid[_nI][1])!=_aValid[_nI][3] .AND. Type('_oItem:'+_aValid[_nI][1])<>"U")
					aAdd(_aRetError,{'500','Item '+cvaltochar(_nJ)+' Campo '+_aValid[_nI][1]+' com Tipo: '+Type('_oItem:'+_aValid[_nI][1])+' - Esperado: '+_aValid[_nI][3]})
				EndIf
			EndIf
			
			Next _nI
	
		Next _nK

		::SetResponse('["mensagem":[')
		If (Len(_aRetError) = 0)
	
			_aCabAuto := {}
			_aValid := _aValidC5
			_nI := 1
			For _nI := 1 to Len(_aValid)
				If(Type('_oCab:'+_aValid[_nI][1])!='U' .and. ! AllTrim(_aValid[_nI][5]) $ 'C5_EMISSAO#C5_NUM#')
					aadd(_aCabAuto,{_aValid[_nI][5]	,&('_oCab:'+_aValid[_nI][1]) , nil})
				EndIf				
			Next
			_aIteAuto := {}	
			
			_aValid := _aValidC6
			For nFor:= 1 To Len (_oItens)
				_oItem := _oItens[_nJ]
				
				_aLinha := {}
				_cFor := strzero(nFor,tamsx3('C6_ITEM')[1]) 
				aadd(_aLinha,{"C6_FILIAL", XFILIAL('SC6'), Nil})
				aadd(_aLinha,{"C6_ITEM", _cFor, Nil})
				
				_nI := 1
				For _nI := 1 to Len(_aValid)
					If(Type('_oClient:'+_aValid[_nI][1])!='U' .and. ! AllTrim(_aValid[_nI][5]) $ 'C6_ITEM#C6_FILIAL#')
						aadd(_aLinha,{_aValid[_nI][5], &('_oClient:'+_aValid[_nI][1]), Nil})
						//_oModel:SetValue(_cModel,_aValid[_nI][5],&('_oClient:'+_aValid[_nI][1]))
					EndIf				
				Next
	
			    //aadd(_aLinha,{"C6_PEDCLI" , oCorpo:ITENS[nFor]:C6_PEDCLI, Nil})
				//aadd(_aLinha,{"AUTDELETA" , "N"                , Nil})
			
				Aadd(_aIteAuto,_aLinha)
			Next
	
			lMsErroAuto := .F.
			lAutoErrNoFile := .T.
			
			VARINFO('_aCabAuto',_aCabAuto)
			VARINFO('_aIteAuto',_aIteAuto)
	
			// rotina automatica do pedido de venda
			MsExecAuto({|x,y,z| Mata410(x,y,z)},_aCabAuto,_aIteAuto,3) // 3-inclusao
	
			If !lMsErroAuto  // operacao se deu erro
				::SetResponse('{["PEDIDO":"'+SC5->C5_NUM+'"]}')
			Else
				_aErroAuto := GetAutoGRLog()
				cMsg:= "ERRO - PEDIDO VENDA -Arquivo: "+cArquivo
				For _nCount := 1 To Len(_aErroAuto)
					cMsg += StrTran(StrTran(StrTran(_aErroAuto[_nCount],"<",""),"-",""),"   "," ") + (" ")
				Next _nCount	
				::SetResponse('{"ID":401,"Erro":"'+cMsg+'"]}')
				SetRestFault(499,cMsg)
				Return .f.				
			EndIf
	
		Else
			If(Len(_aRetError)>0)
				::SetResponse(U_WS002RET(_aRetError))
				Return .F.
			EndIf
		
		EndIf
		::SetResponse("]")
		
	next _nJ
	::SetResponse("]}")
EndIf

If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return _lRet

STATIC FUNCTION WSPEDVEN(cPedido,_cAlias)

Local _cInfAdic := ''
 
Private nIt
Private nTot
Private nCondp
Private nCondc
Private aAreaSC6 := SC6->(GetArea())
Private aAreaSC5 := SC5->(GetArea())
Private cPed
Private cDesc

Private cNFor := ""

Private nValICM := 0
Private nValIPI := 0
Private nTOTICM := 0
Private nTOTIPI := 0
Private nTOTSOL := 0
Private nValSOL := 0

Private nValFrete := 0
Private nTotal := 0
Private nQtdOpc := 0
Private aItens := {}
Private aItAux := {}
Private aItEst := {}
Private lnoItens := .F.

dbSelectArea("SC6")
SC6->(dbsetorder(1))
SC6->(dbseek(xFilial("SC6")+cPedido))

If !((_cAlias)->C5_TIPO='D' .OR. (_cAlias)->C5_TIPO='B')
	
	dbSelectArea("SA1")
	SA1->(dbsetorder(1))
	SA1->(dbseek(xFilial("SA1")+SC6->C6_CLI+SC6->C6_LOJA))
	
Else
	dbSelectArea("SA2")
	SA2->(dbsetorder(1))
	SA2->(dbseek(xFilial("SA2")+SC6->C6_CLI+SC6->C6_LOJA))
	
EndIf




// Adiciona dados e função para início dos cálculos referentes aos impostos
MaFisIni(SC6->C6_CLI,;               	// 1-Codigo Cliente/Fornecedor
SC6->C6_LOJA,;                         	// 2-Loja do Cliente/Fornecedor
"C",;                         		// 3-C:Cliente , F:Fornecedor
"N",;                         		// 4-Tipo da NF
IIf((_cAlias)->C5_TIPO='D' .OR. (_cAlias)->C5_TIPO='B',SA2->A2_TIPO,SA1->A1_TIPO),;                      // 5-Tipo do Cliente/Fornecedor
,;   								// 6-Relacao de Impostos que suportados no arquivo
,;                               	// 7-Tipo de complemento
,;                               	// 8-Permite Incluir Impostos no Rodape .T./.F.
"SB1",;               				// 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
"MATA410")


DbSelectArea("SC6")
Dbsetorder(1)
DbSeek(xFilial("SC6")+cPedido)
While !SC6->(Eof()) .and. SC6->C6_NUM == cPedido
	
	dbSelectArea("SB1")
	SB1->(dbSetOrder(1))
	SB1->(dbSeek(xFilial("SB1")+SC6->C6_PRODUTO))
	cDesc := AllTrim(SB1->B1_DESC) //AllTrim(SC6->C6_PRODUTO)+" - "+AllTrim(SB1->B1_DESC)
			
	// Adiciona itens a função de cálculo de impostos para impressão
	_nitem  := MaFisAdd(SB1->B1_COD,SC6->C6_TES, SC6->C6_QTDVEN, SC6->C6_PRCVEN, 0, "", "",, 0, 0, 0, 0, SC6->C6_VALOR, 0)
			
	nValIPI := MaFisRet(_nitem,"IT_VALIPI")
	nValICM := MaFisRet(_nitem,"IT_VALICM")
	//nValSOL := MaFisRet(_nitem,"IT_VALSOL")
	nValSol    := MaFisRet(_nitem, "IT_VALSOL")
			
	//				01				02						03					04			05			06				07            08	 	   09			10
	aadd(aItens,{SC6->C6_ITEM,AllTrim(SC6->C6_PRODUTO),AllTrim(SB1->B1_DESC),SC6->C6_UM,SC6->C6_QTDVEN,SC6->C6_PRCVEN,SC6->C6_VALOR,nValIPI, SC6->C6_ENTREG, SC6->C6_OPC,nValSOL}) //,SC7->C7_VALIPI,SC7->C7_DATPRF})
	
	nTOTICM := nTOTICM + nValICM
	nTOTIPI := nTOTIPI + nValIPI
		
	nTotal := 	nTotal	+	SC6->C6_VALOR
			
	//nTOTSOL := nTOTSOL + nValSOL
			
	nTOTSOL  += nValSol
			
   
   
	If !Empty(nValSol)
		nValSol := Round( nValSol / SC6->C6_QTDVEN,2)
	EndIf
			
	SC6->(dbSkip())
EndDo

_cInfAdic := " "
_cInfAdic += "Totais do Pedido \r\n "
_cInfAdic += "Valor Mercadorias: " + Transform(nTotal,"@E 9,999,999.99")+" \r\n "
If(nTOTICM>0)
_cInfAdic += "Valor ICMS: " + Transform(nTOTICM,"@E 9,999,999.99")+" \r\n "
EndIf
If(nTOTSOL>0)
	_cInfAdic += "Valor ICMS-ST: "+ Transform(nTOTSOL,"@E 9,999,999.99")+" \r\n "
EndIf
If(nTOTIPI>0)
_cInfAdic += "Valor IPI: "+ Transform(nTOTIPI,"@E 9,999,999.99")+" \r\n "
EndIf
If(nValFrete>0)
_cInfAdic += "Valor Frete: "+ Transform(nValFrete,"@E 9,999,999.99")+" \r\n "
EndIf
_cInfAdic += "Valor Total: " + Transform(nValFrete+nTOTSOL+nTOTIPI+nTotal,"@E 9,999,999.99")+" \r\n "
		


RestArea(aAreaSC5)
RestArea(aAreaSC6)

RETURN _cInfAdic

WSMETHOD PUT WSSERVICE WS206

Local _cVldTkn := ''
Local _lRet := .F.
Local _cCod := ''
Local _nI,_nJ,_nReg, _nIni, _nFim, nFor
Local _lPrepEnv := .F.			  
Local nPrimeiro := 0
Local _cAlias, _cAlias2, _cAliasC6, _cAliasNF
Local _cCodFil,_cCodPed
Local _aValidc5 := {},_aValidc6 := {}
Local _nRegistros := 0

Local _DDATAWS := DTOS(DATE())
Local _ChORAws := TIME()

Private _aValid := {}
Private lMsErroAuto := .T.
Private lAutoErrNoFile := .T.
Private cArquivo := '/data/log-ws206-'+dtos(date())+'_'+strtran(time(),':','')+'.log'
Private _cWSname := 'WS206'
Private _oBody,_oItens,_oCab,_oItem

Default _cCodFil:=''
Default _cCodPed:=''

Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''
Default SELF:CDTFILTRO 	:=''

DEFAULT SELF:CWSEMP := '01'
DEFAULT SELF:CWSFIL := '0101'
DEFAULT SELF:CWSDIC := 'N'

RESET ENVIRONMENT
If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "","","","",{"SA1","SA2","SA3","SA4", "SC5","SC6", "SF2","SD2", "SE1","SE2"}) 
	_lPrepEnv := .T.
EndIf

::SetContentType("application/json")

_cVldTkn := AllTrim(GETMV('MV_TKNREST',.T.,'123456'))

If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verIfique a chave! '+SELF:pToken)
	Return .F.
Else
	//conout('','Token Ok')
EndIf

conout('altera��o de pedido - ws 206')

_cContent  := SELF:GetContent()
FWJsonDeserialize(_cContent,@_oBody)

_nI := 1
While(Type('_oBody')='U' .and. _nI < 5)
	FWJsonDeserialize(_cContent,@_oBody)
	_nI++
	If(Type('_oBody')!='U')
		EXIT
	EndIf
EndDo

_aValidC5 := U_WSCAMPOS('','SC5',.f.)
_aValidC6 := U_WSCAMPOS('','SC6',.f.)

If Len(::aURLParms) = 2
	// insira aqui o c�digo para pesquisa do parametro recebido
	// consulta de cliente por documento
	_cCodFil := padr(::aURLParms[1],tamsx3('C5_FILIAL')[1])
	
	If(LEN(::aURLParms)>=2)
		_cCodPed := padr(::aURLParms[2],tamsx3('C5_NUM')[1])
	EndIf
Else
	SetRestFault(401,'Erro: Deve ser informado os parametros Filial e Pedido!')
	Return .F.
EndIf

_cAliasC6 := GETNEXTALIAS()

SC5->(DBSETORDER(1))
If(SC5->(DBSEEK(_cCodFil+_cCodPed)))

conout('altera��o de pedido - ws 206 - pedido encontrado'+SC5->C5_NUM)

	//Pedido Encontrado
	//valida��o de datas
	_oCab := _oBody
		
	_aValid := _aValidC5
	For _nI := 1 to Len (_aValid) 				
		If(_aValid[_nI][3]=='D')
			If(Type('_oCab:'+_aValid[_nI][1])=="C")
				&('_oCab:'+_aValid[_nI][1]) := stod(&('_oCab:'+_aValid[_nI][1]))
			EndIf
		EndIf
	Next _nI
	
	_oItens := _oCab:ITENS
	
	_aValid := _aValidC6
	For _nK := 1 to Len(_oItens)
		_oItem := _oItens[_nK]
		For _nI := 1 to Len (_aValid) 				
			If(_aValid[_nI][3]=='D')
				If(Type('_oItem:'+_aValid[_nI][1])=="C")
					&('_oItem:'+_aValid[_nI][1]) := stod(&('_oItem:'+_aValid[_nI][1])) // muda string para data
				EndIf
			EndIf
		
		Next _nI

	Next _nK
	
	
	_aCabec := {}
	_aValid := _aValidC5
	_nI := 1
	For _nI := 1 to Len(_aValid)
		If(Type('_oCab:'+_aValid[_nI][1])!='U' .and. ! AllTrim(_aValid[_nI][5]) $ 'C5_EMISSAO')
			aadd(_aCabec,{_aValid[_nI][5]	,&('_oCab:'+_aValid[_nI][1]) , nil})
		EndIf				
	Next

	_aItens :={}		
	_aValid := _aValidC6
	For nFor:= 1 To Len (_oItens)
		_oItem := _oItens[nFor]
		
		_aLinha := {}

		aadd(_aLinha,{"C6_FILIAL", XFILIAL('SC6'), Nil})
		aadd(_aLinha,{"LINPOS","C6_ITEM", _oItem:ITEM})
		_nI := 1
		For _nI := 1 to Len(_aValid)
			If(Type('_oItem:'+_aValid[_nI][1])!='U' .and. ! AllTrim(_aValid[_nI][5]) $ 'C6_FILIAL#')
				aadd(_aLinha,{_aValid[_nI][5], &('_oItem:'+_aValid[_nI][1]), Nil})
				//_oModel:SetValue(_cModel,_aValid[_nI][5],&('_oClient:'+_aValid[_nI][1]))
			EndIf				
		Next

	    //aadd(_aLinha,{"C6_PEDCLI" , oCorpo:ITENS[nFor]:C6_PEDCLI, Nil})
	    If(Type('_oItem:DELETADO') = "C")
	    	If(_oItem:DELETADO = 'S')
	    		aadd(_aLinha,{"AUTDELETA" , "S"                , Nil})
	    	Else
	    		aadd(_aLinha,{"AUTDELETA","N",Nil})  
	    	EndIf
	    EndIf
	    
		Aadd(_aItens,_aLinha)
	Next
	
	//VerIficar campos que podem ser alterados
	//transportadora
	//condi��o de pagamento
	///tabela de pre�o
	lMsErroAuto := .f.
	/*
	SC6->(DBSETORDER(1))
	If(SC6->(DBSEEK(_cCodFil+_cCodPed)))
		_cChave := _cCodFil+_cCodPed
		while (SC6->(C6_FILIAL+C6_NUM) = _cChave .AND. !SC6->(EOF()))
		
			nVlrCred := 0
			nQtdLib:=0
			lCredito:=.F.
			lEstoque:=.F.
			lLiber:=.F.
			lTransf:=.F.
			nQtdLib:=0
			nQtdLib2:=0
			conout('ws 206 put'+SC6->(C6_ITEM),MaLibDoFat(SC6->(RecNo()),nQtdLib,@lCredito,@lEstoque,.T.,.T.,lLiber,lTransf,NIL,NIL,NIL,NIL,NIL,NIL,nQtdLib2))			
			SC6->(DBSKIP())
		ENDDO
	EndIf
	*/

	DbSelectArea('SC5')
	SC5->(DbSetOrder(1)) //C5_FILIAL + C5_NUM
 
	DbSelectArea('SC6')
	SC6->(DbSetOrder(1)) //C6_FILIAL + C6_NUM + C6_ITEM
	SC6->(DbGoTop())
	 
	DbSelectArea('SC9')
	SC9->(DbSetOrder(1)) //C9_FILIAL + C9_PEDIDO + C9_ITEM
	SC9->(DbGoTop())
	 
	//Se conseguir posicionar no pedido
	
	If SC6->(DbSeek(SC5->(C5_FILIAL+C5_NUM)))
			aAreaAux := SC6->(GetArea())
			//CONOUT('ACHOU ITEM '+SC6->(C6_FILIAL+'_'+C6_NUM+'_'+C6_ITEM))
			//MaAvalSC6("SC6",4,"SC5",Nil,Nil,Nil,Nil,Nil,Nil)
			
			
			//Percorre todos os itens
			While ! SC6->(EoF()) .And. SC6->(C6_FILIAL+C6_NUM) = SC5->(C5_FILIAL+C5_NUM)
				//Posiciona na libera��o do item do pedido e estorna a libera��o
				If(SC9->(DbSeek(SC6->(C6_FILIAL+C6_NUM+C6_ITEM))))
				
					While  (!SC9->(Eof())) .AND. SC9->(C9_FILIAL+C9_PEDIDO+C9_ITEM) == SC6->(C6_FILIAL+C6_NUM+C6_ITEM)
						CONOUT('ACHOU ITEM LIB  '+C9_FILIAL+C9_PEDIDO+C9_ITEM)
					
						SC9->(a460Estorna(.T.))
						CONOUT('FIM LIB  '+C9_FILIAL+C9_PEDIDO+C9_ITEM)
						SC9->(DbSkip())
					EndDo
				else
				conout('sem libera��o')
				EndIf
		 
				SC6->(DbSkip())
			EndDo
			CONOUT('FIM ITEM '+SC6->C6_ITEM)
			
		EndIf

	CONOUT('FIM ESTORNO')

	
	 
	DbSelectArea('SCV')
	SCV->(DbSetOrder(1)) //C9_FILIAL + C9_PEDIDO + C9_ITEM

	CONOUT("INICIO ALTERACAO") 
	
	
	CONOUT("ordena vetores")
	_aCabec := FWVetByDic(_aCabec,'SC5',.F.)
	_aItens := FWVetByDic(_aItens,'SC6',.T.)
	
		
	MsExecAuto({|x,y,z| Mata410(x,y,z)},_aCabec,_aItens,4) // 3-inclusao; 4-altera��o
	
	CONOUT("FIM ALTERACAO  - execauto"+cvaltochar(lMsErroAuto)) 
	If !lMsErroAuto  // operacao se deu erro
				
		_cRetMsg := '{'
		_cRetMsg += '"NUMERO":"'+SC5->C5_NUM+'"'
		IF(TYPE('_oCab:PROTOCOLO')<>"U")
			_cRetMsg += ',"PROTOCOLO":"'+_oCab:PROTOCOLO+'"'
		ENDIF
		_cRetMsg += ',"MENSAGEM":"PEDIDO ALTERADO"'
		_cRetMsg += ',"DATA":"'+_dDataWS+'"'
		_cRetMsg += ',"HORA":"'+_cHoraWS+'"'
		_cRetMsg += '}'
		
		RECLOCK("ZW0",.T.)
			ZW0->ZW0_FILIAL := XFILIAL("ZW0")
			ZW0->ZW0_TABELA := PADR("WS206",TAMSX3("ZW0_TABELA")[1])
			ZW0->ZW0_CHAVE  := SC5->(C5_FILIAL+C5_NUM)
			ZW0->ZW0_SEQ	:= GETSXENUM("ZW0","ZW0_SEQ","ZW0_SEQ"+ZW0->(ZW0_FILIAL+ZW0_TABELA+ZW0_CHAVE))
			ZW0->ZW0_DATA	:= STOD(_dDataWS)
			ZW0->ZW0_HORA	:= _cHoraWS
			IF(TYPE('_oCab:PROTOCOLO')<>"U")
				ZW0->ZW0_PROTOC	:= _oCab:PROTOCOLO
			ENDIF
			ZW0->ZW0_JSON 	:= _cContent
			ZW0->ZW0_MENRET := _cRetMsg
		ZW0->(MSUNLOCK())
		
		
		CONOUT("PASSOU LOG")
		CONFIRMSX8()

		SELF:SetResponse('{')
		SELF:SetResponse('"ALTERACAO":'+_cRetMsg)		
		SELF:SetResponse('"PEDIDO":{')

		_aValidC5 := U_WSCAMPOS('','SC5')
		_aValidC6 := U_WSCAMPOS('','SC6')
		
		
		CONOUT("Dados do pedido")
		_aValid := _aValidC5
		_cAlias := "SC5"
		dbselectarea(_cAlias)
		
		For _nI := 1 to len(_aValid)
			If(_aValid[_nI,3]=='C')
				SELF:SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
			ElseIf(_aValid[_nI,3]=='M')
				SELF:SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
			ElseIf(_aValid[_nI,3]=='O')
				//n�o tratado - somente para compatibilidade com outras fun��es
			ElseIf(_aValid[_nI,3]=='L')
				SELF:SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))			
			ElseIf(_aValid[_nI,3]=='D')
				SELF:SetResponse('"'+_aValid[_nI,1]+'":"')
				If(Type(_aValid[_nI,5])='D')
					SELF:SetResponse(dtos(&(_aValid[_nI,5]))+'"')
				ElseIf(Type(_aValid[_nI,5])='C')
					SELF:SetResponse(&(_aValid[_nI,5])+'"')
				EndIf
				SELF:SetResponse(iIf(_nI<len(_aValid),',',''))			
			ElseIf(_aValid[_nI,3]=='N')
				SELF:SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))
			EndIf
		Next
		
		
		If(SELECT(_cAliasC6)>0)
			(_cAliasC6)->(DBCLOSEAREA())
		EndIf	
				
		BEGINSQL ALIAS _cAliasC6
			%NOPARSER%
			COLUMN C6_DATFAT AS DATE
			SELECT  * FROM %TABLE:SC6% SC6
			WHERE C6_FILIAL=%EXP:_cCodFil% AND C6_NUM=%EXP:(_cAlias)->C5_NUM% AND SC6.D_E_L_E_T_ != '*'
		
		ENDSQL
		
		dbselectarea(_cAliasC6)
		cQry := ''
		SELF:SetResponse(', "ITENS":[')
		//Lista de itens
		_aValid := _aValidC6
		_NiT := 0
		Do While !(_cAliasC6)->(Eof())
			SELF:SetResponse('{')
			For _nI := 1 to len(_aValid)
				If(_aValid[_nI,3]=='C')
					SELF:SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
				ElseIf(_aValid[_nI,3]=='M')
					SELF:SetResponse('"'+_aValid[_nI,1]+'":"'+AllTrim(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))
				ElseIf(_aValid[_nI,3]=='O')
					//n�o tratado - somente para compatibilidade com outras fun��es
				ElseIf(_aValid[_nI,3]=='L')
					SELF:SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))			
				ElseIf(_aValid[_nI,3]=='D')
					SELF:SetResponse('"'+_aValid[_nI,1]+'":"'+dtos(&(_aValid[_nI,5]))+'"'+iIf(_nI<len(_aValid),',',''))			
				ElseIf(_aValid[_nI,3]=='N')
					SELF:SetResponse('"'+_aValid[_nI,1]+'":'+AllTrim(cvaltochar(&(_aValid[_nI,5])))+iIf(_nI<len(_aValid),',',''))
				EndIf
				
			Next		
			SELF:SetResponse('}')

			(_cAliasC6)->(DBSkip())
			If(!(_cAliasC6)->(EOF()))
				SELF:SetResponse(',')
			EndIf
			
		EndDo
		SELF:SetResponse(']') //Fecha Itens
		SELF:SetResponse('}') //Fecha Pedido
		SELF:SetResponse('}') //Fecha Pedido
		
		
	Else
		conout("entrou erro")
		_aErroAuto := GetAutoGRLog()
		cMsg:= ""//"ERRO - PEDIDO VENDA - " //" -Arquivo: "+cArquivo
		//cMsg:= "ERRO - PEDIDO VENDA -  "+MostraErro()
		For _nCount := 1 To Len(_aErroAuto)
			cMsg += StrTran(StrTran(StrTran(_aErroAuto[_nCount],"<",""),"-",""),"   "," ") + (" ")
		Next _nCount	
		
		::SetResponse('Erro: '+cMsg+'"]}')
		
		
		//_cRetMsg := '"MENSAGEM":"ERRO AO ALTERAR PEDIDO - "'+cMsg+'"'
		//_cRetMsg := cMsg
		
		_cRetMsg := '{'
		_cRetMsg += '"NUMERO":"'+SC5->C5_NUM+'"'
		IF(TYPE('_oCab:PROTOCOLO')<>"U")
			_cRetMsg += ',"PROTOCOLO":"'+_oCab:PROTOCOLO+'"'
		ENDIF
		_cRetMsg += ',"MENSAGEM":"ERRO AO ALTERAR PEDIDO - '+formatjson(cMsg)+'"'
		_cRetMsg += ',"DATA":"'+_dDataWS+'"'
		_cRetMsg += ',"HORA":"'+_cHoraWS+'"'
		_cRetMsg += '}'		
		
		
		RECLOCK("ZW0",.T.)
			ZW0->ZW0_FILIAL := XFILIAL("ZW0")
			ZW0->ZW0_TABELA := PADR("WS206",TAMSX3("ZW0_TABELA")[1])
			ZW0->ZW0_CHAVE  := SC5->(C5_FILIAL+C5_NUM)
			ZW0->ZW0_SEQ	:= GETSXENUM("ZW0","ZW0_SEQ","ZW0_SEQ"+ZW0_FILIAL+ZW0_TABELA+ZW0_CHAVE)
			ZW0->ZW0_DATA	:= STOD(_dDataWS)
			ZW0->ZW0_HORA	:= _cHoraWS
			IF(TYPE('_oCab:PROTOCOLO')<>"U")
				ZW0->ZW0_PROTOC	:= _oCab:PROTOCOLO
			ENDIF
			ZW0->ZW0_JSON 	:= _cContent
			ZW0->ZW0_MENRET := _cRetMsg
		ZW0->(MSUNLOCK())
		
		CONFIRMSX8()
		
		SetRestFault(499,cMsg)
		
		Return _lRet				
	EndIf
	
	
	//itens
	//pre�o
	//quantidade
	
	//verIficar se ja existe nota para a linha - se sim n�o alterar e retornar erro
	
	
	
	
	

Else

	conout('alteracao de pedido - ws 206 - pedido encontrado')
	::setResponse('{"Resultado: {"Mensagem":"Pedido nao encontrado '+_cCodFil+" - "+_cCodPed+'"}"}')
	SetRestFault(401,'Erro: Pedido nao encontrado '+_cCodFil+" - "+_cCodPed+'!')
	_lRet := .f.
EndIf

RESET ENVIRONMENT

return _lRet




WSMETHOD DELETE WSSERVICE WS206

Local _cVldTkn := ''
Local _lRet := .F.
Local _cCod := ''
Local _nI,_nJ,_nReg, _nIni, _nFim, nFor
Local _lPrepEnv := .F.			  
Local nPrimeiro := 0
Local _cAlias, _cAlias2, _cAliasC6, _cAliasNF
Local _cCodFil,_cCodPed, _cContent
Local _aValidc5 := {},_aValidc6 := {}
Local _nRegistros := 0

Private _aValid := {}
Private lMsErroAuto := .T.
Private lAutoErrNoFile := .T.
Private cArquivo := '/data/log-ws206-'+dtos(date())+'_'+strtran(time(),':','')+'.log'
Private _cWSname := 'WS206'
Private _oBody,_oItens,_oCab,_oItem

Default _cCodFil:=''
Default _cCodPed:=''

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
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "","","","",{"SA1","SA2","SA3","SA4", "SC5","SC6", "SF2","SD2", "SE1","SE2"}) 
	_lPrepEnv := .T.
EndIf


::SetContentType("application/json")

_cVldTkn := AllTrim(GETMV('MV_TKNREST',.T.,'123456'))

If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verIfique a chave! '+SELF:pToken)
	Return .F.
Else
	//conout('','Token Ok')
EndIf

conout('altera��o de pedido - ws 206')

_cContent  := SELF:GetContent()
FWJsonDeserialize(_cContent,@_oBody)

_nI := 1
While(Type('_oBody')='U' .and. _nI < 5)
	FWJsonDeserialize(_cContent,@_oBody)
	_nI++
	If(Type('_oBody')!='U')
		EXIT
	EndIf
EndDo

_aValidC5 := U_WSCAMPOS('','SC5',.f.)
_aValidC6 := U_WSCAMPOS('','SC6',.f.)

If Len(::aURLParms) = 2
	// insira aqui o c�digo para pesquisa do parametro recebido
	// consulta de cliente por documento
	_cCodFil := padr(::aURLParms[1],tamsx3('C5_FILIAL')[1])
	
	If(LEN(::aURLParms)>=2)
		_cCodPed := padr(::aURLParms[2],tamsx3('C5_NUM')[1])
	EndIf
Else
	SetRestFault(401,'Erro: Deve ser informado os parametros Filial e Pedido!')
	Return .F.
EndIf


SC5->(DBSETORDER(1))
If(SC5->(DBSEEK(_cCodFil+_cCodPed)))


conout('EXCLUSAO de pedido - ws 206 - pedido encontrado '+SC5->C5_NUM)

	//Pedido Encontrado
	//valida��o de datas
	_oCab := _oBody
	
	_oItens := _oCab:ITENS
		
	SA1->(DBSETORDEr(1))
	SA1->(DBSEEK(XFILIAL('SA1')+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
	
	_aValid := _aValidC5
	For _nI := 1 to Len (_aValid) 				
		If(_aValid[_nI][3]=='D')
			If(Type('_oCab:'+_aValid[_nI][1])=="C")
				&('_oCab:'+_aValid[_nI][1]) := stod(&('_oCab:'+_aValid[_nI][1]))
			EndIf
		EndIf
	Next _nI
	
	
	
	_aCabec := {}
	_aValid := _aValidC5
	_nI := 1
	For _nI := 1 to Len(_aValid)
		If(Type('_oCab:'+_aValid[_nI][1])!='U' .and. ! AllTrim(_aValid[_nI][5]) $ 'C5_EMISSAO')
			aadd(_aCabec,{_aValid[_nI][5]	,&('_oCab:'+_aValid[_nI][1]) , nil})
		EndIf				
	Next

	_aItens :={}		
	_aValid := _aValidC6
	For nFor:= 1 To Len (_oItens)
		_oItem := _oItens[nFor]
		
		_aLinha := {}

		aadd(_aLinha,{"C6_FILIAL", XFILIAL('SC6'), Nil})
		aadd(_aLinha,{"C6_ITEM", _oItem:ITEM, Nil})
		
		_nI := 1
		For _nI := 1 to Len(_aValid)
			If(Type('_oItem:'+_aValid[_nI][1])!='U' .and. ! AllTrim(_aValid[_nI][5]) $ 'C6_FILIAL#')
				aadd(_aLinha,{_aValid[_nI][5], &('_oItem:'+_aValid[_nI][1]), Nil})
				//_oModel:SetValue(_cModel,_aValid[_nI][5],&('_oClient:'+_aValid[_nI][1]))
			EndIf				
		Next

	    //aadd(_aLinha,{"C6_PEDCLI" , oCorpo:ITENS[nFor]:C6_PEDCLI, Nil})
	    If(Type('_oItem:DELETADO') = "C")
	    	If(_oItem:DELETADO = 'S')
	    		aadd(_aLinha,{"AUTDELETA" , "S"                , Nil})
	    	EndIf
	    EndIf
	    
		Aadd(_aItens,_aLinha)
	Next
	
	//VerIficar campos que podem ser alterados
	//transportadora
	//condi��o de pagamento
	///tabela de pre�o

	DbSelectArea('SC5')
	SC5->(DbSetOrder(1)) //C5_FILIAL + C5_NUM
 
	DbSelectArea('SC6')
	SC6->(DbSetOrder(1)) //C6_FILIAL + C6_NUM + C6_ITEM
	SC6->(DbGoTop())
	 
	DbSelectArea('SC9')
	SC9->(DbSetOrder(1)) //C9_FILIAL + C9_PEDIDO + C9_ITEM
	SC9->(DbGoTop())
	

	//Se conseguir posicionar no pedido
	
	

	
	//Se conseguir posicionar no pedido
	CONOUT('INICIO ESTORNO')
	
	If SC6->(DbSeek(SC5->(C5_FILIAL+C5_NUM)))
		CONOUT('ACHOU ITEM '+SC6->(C6_FILIAL+C6_NUM+C6_ITEM))
		//MaAvalSC6("SC6",4,"SC5",Nil,Nil,Nil,Nil,Nil,Nil)
			
			
			//Percorre todos os itens
			While ! SC6->(EoF()) .And. SC6->(C6_FILIAL+C6_NUM) = SC5->(C5_FILIAL+C5_NUM)
				//Posiciona na libera��o do item do pedido e estorna a libera��o
				If(SC9->(DbSeek(SC6->(C6_FILIAL+C6_NUM+C6_ITEM))))
				
					While  (!SC9->(Eof())) .AND. SC9->(C9_FILIAL+C9_PEDIDO+C9_ITEM) == SC6->(C6_FILIAL+C6_NUM+C6_ITEM)
						CONOUT('ACHOU ITEM LIB  '+C9_FILIAL+C9_PEDIDO+C9_ITEM)
					
						SC9->(a460Estorna(.T.))
						CONOUT('FIM LIB  '+C9_FILIAL+C9_PEDIDO+C9_ITEM)
						SC9->(DbSkip())
					EndDo
				EndIf
		 
				SC6->(DbSkip())
			EndDo
			CONOUT('FIM ITEM '+SC6->C6_ITEM)
			
		EndIf

	CONOUT('FIM ESTORNO')


	lMsErroAuto := .f.
	CONOUT("INICIO EXCLUSAO")
	MsExecAuto({|x,y,z| Mata410(x,y,z)},_aCabec,_aItens,5) // 3-inclusao; 4-altera��o
	CONOUT("FIM EXCLUSAO")
	_dDataWS := dtos(date())
	_cHoraWS := time()
	DBSELECTAREA("ZW0")
	
	If !lMsErroAuto  // operacao se nao deu erro

		
		_cRetMsg := '{'
		
		_cRetMsg += '"NUMERO":"'+SC5->C5_NUM+'"'
		_cRetMsg += ',"MENSAGEM":"PEDIDO EXCLUIDO"'
		_cRetMsg += ',"DATA":"'+_dDataWS+'"'
		_cRetMsg += ',"HORA":"'+_cHoraWS+'"'
		IF(TYPE('_oCab:PROTOCOLO')<>"U")
			_cRetMsg += ',"PROTOCOLO":"'+_oCab:PROTOCOLO+'"'
		ENDIF
		_cRetMsg += '}'
		
		::SetResponse(_cRetMsg)
		
		
		
		//pedido exclu�do
		//gravar log
		
		RECLOCK("ZW0",.T.)
			ZW0->ZW0_FILIAL := XFILIAL("ZW0")
			ZW0->ZW0_TABELA := PADR("WS206",TAMSX3("ZW0_TABELA")[1])
			ZW0->ZW0_CHAVE  := SC5->(C5_FILIAL+C5_NUM)
			ZW0->ZW0_SEQ	:= GETSXENUM("ZW0","ZW0_SEQ","ZW0_SEQ+ZW0_FILIAL+ZW0_TABELA+ZW0_CHAVE")
			ZW0->ZW0_DATA	:= STOD(_dDataWS)
			ZW0->ZW0_HORA	:= _cHoraWS
			ZW0->ZW0_JSON 	:= _cContent
			IF(TYPE('_oCab:PROTOCOLO')<>"U")
				ZW0->ZW0_PROTOC	:= _oCab:PROTOCOLO
			ENDIF
			ZW0->ZW0_MENRET := _cRetMsg
		ZW0->(MSUNLOCK())
		
		confirmsx8()
		
	Else
		_aErroAuto := GetAutoGRLog()
		//cMsg:= "ERRO - PEDIDO VENDA - " //" -Arquivo: "+cArquivo
		cMsg:= "" //" -Arquivo: "+cArquivo
		//cMsg:= "ERRO - PEDIDO VENDA -  "+MostraErro()
		For _nCount := 1 To Len(_aErroAuto)
			cMsg += StrTran(StrTran(StrTran(_aErroAuto[_nCount],"<",""),"-",""),"   "," ") + (" ")
		Next _nCount	
		
		_cRetMsg := '{'
		
		_cRetMsg += '"NUMERO":"'+SC5->C5_NUM+'"'
		_cRetMsg += ',"MENSAGEM":"ERRO AO EXCLUIR PEDIDO - '+cMsg+'"'
		_cRetMsg += ',"DATA":"'+_dDataWS+'"'
		_cRetMsg += ',"HORA":"'+_cHoraWS+'"'
		IF(TYPE('_oCab:PROTOCOLO')<>"U")
			_cRetMsg += ',"PROTOCOLO":"'+_oCab:PROTOCOLO+'"'
		ENDIF
		_cRetMsg += '}'
		
		RECLOCK("ZW0",.T.)
			ZW0->ZW0_FILIAL := XFILIAL("ZW0")
			ZW0->ZW0_TABELA := PADR("WS206",TAMSX3("ZW0_TABELA")[1])
			ZW0->ZW0_CHAVE  := SC5->(C5_FILIAL+C5_NUM)
			ZW0->ZW0_SEQ	:= GETSXENUM("ZW0","ZW0_SEQ","ZW0_SEQ"+ZW0_FILIAL+ZW0_TABELA+ZW0_CHAVE)
			ZW0->ZW0_DATA	:= STOD(_dDataWS)
			ZW0->ZW0_HORA	:= _cHoraWS
			ZW0->ZW0_JSON 	:= _cContent
			IF(TYPE('_oCab:PROTOCOLO')<>"U")
				ZW0->ZW0_PROTOC	:= _oCab:PROTOCOLO
			ENDIF
			ZW0->ZW0_MENRET := _cRetMsg
		ZW0->(MSUNLOCK())
		
		confirmsx8()

		
		//::SetResponse('Erro: '+cMsg+'')
		SetRestFault(499,cMsg)
		
		Return _lRet				
	EndIf
	
	
	//itens
	//pre�o
	//quantidade
	
	//verIficar se ja existe nota para a linha - se sim n�o alterar e retornar erro
	
	
	
	
	

Else

	conout('alteracao de pedido - ws 206 - pedido encontrado')
	::setResponse('{"Resultado: {"Mensagem":"Pedido nao encontrado '+_cCodFil+" - "+_cCodPed+'"}"}')
	SetRestFault(401,'Erro: Pedido nao encontrado '+_cCodFil+" - "+_cCodPed+'!')
	_lRet := .f.
EndIf


return _lRet

static function formatjson(_ctexto)

_ctexto := strtran(_ctexto,"\","\\")
_ctexto := STRTRAN(STRTRAN(noacento(_ctexto),'"',''),'	','')

return _ctexto
