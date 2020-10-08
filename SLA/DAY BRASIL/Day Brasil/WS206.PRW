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
// Função   : WS205 - CADASTRO DE PEDIDOS DE VENDAS
// Descrição: WS PARA CONSULTA DE VENDEDORES
// Retorno  : REST COM AS INFORMAÇÕES DA TABELA SC5,SC6
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

WSRESTFUL WS206 DESCRIPTION "Cadastro de Pedido de Venda"

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 
WSDATA CDTFILTRO AS STRING OPTIONAL 

WSDATA CWSEMP AS STRING OPTIONAL 
WSDATA CWSFIL AS STRING OPTIONAL 

WSDATA CWSDIC AS STRING OPTIONAL 

WSMETHOD GET DESCRIPTION "Consulta Pedido de Venda" WSSYNTAX "/rest/WS206 || /rest/WS206/{FILIAL}/{SERIE}/{DOC}"

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

Default _cCodFil:=''
Default _cCodPed:=''

Default SELF:cTipo :=''
Default SELF:NPAGINA := 1
Default SELF:NREGISTRO := 20
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
	_cCodFil := padr(::aURLParms[1],tamsx3('C5_FILIAL')[1])
	
	IF(LEN(::aURLParms)>=2)
		_cCodPed := padr(::aURLParms[2],tamsx3('C5_NUM')[1])
	ENDIF
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
	cQry+= " AND C5_EMISSAO >= '20180101' "

EndIf

IF(!EMPTY(SELF:CDTFILTRO))
	IF(SC5->(fieldpos('C5_USERLGI')>0))	
		cQry+= " AND CASE 	WHEN C5_USERLGA = ' ' "
		cQry+= "	THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGI,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120) "
		cQry+= "	ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGA,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) END >= '"+SELF:CDTFILTRO+"' "
	endif	
ENDIF

cQry+="%"

IF(SELECT(_cAlias2)>0)
	(_cAlias2)->(DBCLOSEAREA())
ENDIF

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


IF(SELECT(_cAlias)>0)
	(_cAlias)->(DBCLOSEAREA())
ENDIF


IF(SC5->(fieldpos('C5_USERLGI')>0))

	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		COLUMN C5_EMISSAO AS DATE
		SELECT ROW_NUMBER() OVER(ORDER BY C5_NUM ASC) REG,
				CASE 	WHEN C5_USERLGA = ' ' 
						THEN   CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGI,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGI,16,1)) - 50))), '1996-01-01') AS DATETIME),120)
						ELSE CONVERT(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGA,12,1)) - 50))+Convert(nvarchar(50),(ASCII(SUBSTRING(C5_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),120) 
				END DTLGA, 
						SELECT ROW_NUMBER() OVER(ORDER BY C5_NUM ASC) REG, 
				CASE WHEN C5_LIBEROK = '' AND C5_NOTA='' AND C5_BLQ='' AND C5_DYCANPV = ' ' THEN 'ABERTO'
				WHEN C5_NOTA != ' ' OR C5_LIBEROK='E' AND C5_BLQ='' AND C5_DYCANPV = ' ' THEN 'ENCERRADO'
				WHEN C5_LIBEROK!=' ' AND   C5_NOTA=' ' AND C5_BLQ =' ' AND C5_DYCANPV = ' ' THEN 'LIBERADO'
				WHEN C5_BLQ='1' AND C5_DYCANPV = ' ' THEN 'BLOQUEIO REGRA'
				WHEN C5_BLQ='2' AND C5_DYCANPV = ' ' THEN 'BLOQUEIO VERBA' 
				WHEN C5_BLQ='3' AND C5_DYCANPV = ' ' THEN 'PEDIDO SEM LIBERACAO DO CLIENTE' 
				WHEN C5_DYCANPV <> ' ' THEN 'PEDIDO CANCELADO' END AS SITUACAO,* 
				FROM %TABLE:SC5% SC5
		WHERE SC5.D_E_L_E_T_ != '*' %EXP:cQry%
	
	ENDSQL
ELSE

	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		COLUMN C5_EMISSAO AS DATE
		SELECT ROW_NUMBER() OVER(ORDER BY C5_NUM ASC) REG, 
		CASE WHEN C5_LIBEROK = '' AND C5_NOTA='' AND C5_BLQ='' AND C5_DYCANPV = ' ' THEN 'ABERTO'
				WHEN C5_NOTA != ' ' OR C5_LIBEROK='E' AND C5_BLQ='' AND C5_DYCANPV = ' ' THEN 'ENCERRADO'
				WHEN C5_LIBEROK!=' ' AND   C5_NOTA=' ' AND C5_BLQ =' ' AND C5_DYCANPV = ' ' THEN 'LIBERADO'
				WHEN C5_BLQ='1' AND C5_DYCANPV = ' ' THEN 'BLOQUEIO REGRA'
				WHEN C5_BLQ='2' AND C5_DYCANPV = ' ' THEN 'BLOQUEIO VERBA' 
				WHEN C5_BLQ='3' AND C5_DYCANPV = ' ' THEN 'PEDIDO SEM LIBERACAO DO CLIENTE' 
				WHEN C5_DYCANPV <> ' ' THEN 'PEDIDO CANCELADO' END AS SITUACAO, C5_LIBEROK, * 
		FROM %TABLE:SC5% SC5
		WHERE SC5.D_E_L_E_T_ != '*' %EXP:cQry%
	
	ENDSQL
ENDIF
//CONOUT(GETLASTQUERY()[2])

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


// define o tipo de retorno do método
IF(!(_cAlias)->(EOF()))
	_nJ := 1
	::SetResponse('{"REGISTROS":[')
	_nIni := ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO )
	_nFim := (SELF:NPAGINA * SELF:NREGISTRO)
	SET FILTER TO REG >= _nIni .and. REG <=_nFim
	(_cAlias)->(dbgotop())
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
			
			::SetResponse('"REG_NUM":'+cvaltochar((_cAlias)->REG)+',')
			IF((_cAlias)->(FIELDPOS("SITUACAO"))>0)
				::SetResponse('"STATUS":"'+alltrim((_cAlias)->SITUACAO)+'",')
			ENDIF
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

			IF(SELECT(_cAliasC6)>0)
				(_cAlias)->(DBCLOSEAREA())
			ENDIF	
					
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
				
				
				
				(_cAliasC6)->(DBSkip())
				IF(!(_cAliasC6)->(EOF()))
					::SetResponse(',')
				ENDIF
				
			EndDo
			(_cAliasC6)->(DBCloseArea())
			::SetResponse('],') //Fecha Itens
			
			cQry:= "% and D2_PEDIDO='"+(_cAlias)->C5_NUM+"' AND D2_FILIAL='"+_cCodFil+"' %"
			
			::SetResponse('"NF":[') //Fecha Itens
			
			if(select(_cAliasNF)>0)
				(_cAliasNF)->(dbclosearea())
			endif
			
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
						ELSEIF(TYPE(_aValid[_nI,5])='C')
							::SetResponse(&(_aValid[_nI,5])+'"')
						ENDIF
						::SetResponse(iif(_nI<len(_aValid),',',''))			
					ElseIf(_aValid[_nI,3]=='N')
						::SetResponse('"'+_aValid[_nI,1]+'":'+alltrim(cvaltochar(&(_aValid[_nI,5])))+iif(_nI<len(_aValid),',',''))
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

			cQry:= "% and D2_PEDIDO='"+(_cAlias)->C5_NUM+"' AND D2_FILIAL='"+_cCodFil+"' %"


			
			::SetResponse(',"TITULOS":[') //Fecha Itens
			
			if(select(_cAliasFN)>0)
				(_cAliasFN)->(dbclosearea())
			endif
			
			BEGINSQL ALIAS _cAliasFN
				%NOPARSER%
				COLUMN E1_EMISSAO AS DATE
				COLUMN E1_BAIXA AS DATE
				COLUMN E1_VENCTO AS DATE
				COLUMN E1_VENCREA AS DATE
			
				SELECT DISTINCT E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_VALOR,E1_SALDO,E1_EMISSAO,E1_BAIXA,
								E1_VENCTO,E1_VENCREA,E1_CLIENTE,E1_LOJA,SE1.R_E_C_N_O_ SE1REC
				FROM %TABLE:SE1% SE1
				INNER JOIN %TABLE:SD2% SD2 ON 	D2_DOC=E1_NUM AND D2_SERIE=E1_PREFIXO AND D2_CLIENTE=E1_CLIENTE AND D2_LOJA=E1_LOJA 
												AND SD2.%NOTDEL% 
				WHERE E1_FILIAL=%EXP:XFILIAL('SE1')% AND SE1.D_E_L_E_T_='' %EXP:cQry%
				ORDER BY E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO
				
			ENDSQL
			
			conout('ws206 - fin',getlastquery()[2])

			DBSELECTAREA(_cAliasFN)
						
			_aValidE1 := U_WSCAMPOS(SELF:CTIPO,'SE1')
			_aValidE5 := U_WSCAMPOS(SELF:CTIPO,'SE5')
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
						
				
				
				::SetResponse('}') //FECHA TITULO	
				(_cAliasFN)->(DBSkip())
			EndDo
			(_cAliasFN)->(DBCLOSEAREA())
			::SetResponse(']') //FECHA TITULOS	
		::SetResponse('}')//FECHA PEDIDOS   
		
					
	    //ElseIf(_nJ > (SELF:NPAGINA * SELF:NREGISTRO ))
			//exit
	    //EndIF
	    
		(_cAlias)->(DBSkip())
	EndDo
	::SetResponse('],')//FECHA PEDIDOS
	::SetResponse('"QUANTIDADE": '+cvaltochar(_nRegistros)+',')
	::SetResponse('"PAGINA": '+cvaltochar(SELF:NPAGINA)+'')
	IF(SELF:CWSDIC=='S')
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
	ENDIF
	::SetResponse('}')//FECHA PEDIDOS
	
	(_cAlias)->(DBCLOSEAREA())
	(_cAlias2)->(DBCLOSEAREA())
ELSE

	(_cAlias)->(DBCLOSEAREA())
	(_cAlias2)->(DBCLOSEAREA())
	::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado!"}')
	SetRestFault(402,'Nenhum cadastro encontrado, verifique as informações enviadas!')		
	Return _lRet

ENDIF



If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return .T.