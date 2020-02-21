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
// Função   : WS206 - CADASTRO DE PEDIDOS DE VENDAS
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

WSMETHOD GET DESCRIPTION "Consulta Pedido de Venda" WSSYNTAX "/rest/WS206 || /rest/WS206/{FILIAL}/{PEDIDO}"
WSMETHOD POST DESCRIPTION "Inclusão de Pedido de Venda" WSSYNTAX "/rest/WS206"

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
	cQry+= " AND C5_EMISSAO >= '20190101' "

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
				END DTLGA, * FROM %TABLE:SC5% SC5
		WHERE SC5.D_E_L_E_T_ != '*' %EXP:cQry%
	
	ENDSQL
ELSE

	BEGINSQL ALIAS _cAlias
		%NOPARSER%
		COLUMN C5_EMISSAO AS DATE
		SELECT ROW_NUMBER() OVER(ORDER BY C5_NUM ASC) REG, * 
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
	
	Do While !(_cAlias)->(Eof())
	    //Contador para inserir separador do json
	    
	   // If(_nJ >= ( 1 + (SELF:NPAGINA -1) * SELF:NREGISTRO ) .AND. _nJ <= (SELF:NPAGINA * SELF:NREGISTRO ))
	    	 If nPrimeiro>0
		     ::SetResponse(',')
		    EndIf 
			nPrimeiro++
			::SetResponse('{')
			_aValid := _aValidC5
			
			dbselectarea(_cAlias)
			
			::SetResponse('"REG_NUM":'+cvaltochar((_cAlias)->REG)+',')
			For _nI := 1 to len(_aValid)
				If(_aValid[_nI,3]=='C')
					::SetResponse('"'+_aValid[_nI,1]+'":"'+alltrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
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
						::SetResponse('"'+_aValid[_nI,1]+'":"'+alltrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
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
			nPrimeiro := 0
			Do While !(_cAliasNF)->(Eof())
			    
			    //Contador para inserir separador do json
			    If nPrimeiro>0
			     ::SetResponse(',')
			    EndIf
			    nPrimeiro+= 1
				cChave:= (_cAliasNF)->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)
				::SetResponse('{')
				_aValid := _aValidF2
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+alltrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
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
							::SetResponse('"'+_aValid[_nI,1]+'":"'+alltrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
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
								E1_VENCTO,E1_VENCREA,E1_CLIENTE,E1_LOJA 
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
			nPrimeiro := 0
			Do While !(_cAliasFN)->(Eof())
			    
			    //Contador para inserir separador do json
			    If nPrimeiro>0
			     ::SetResponse(',')
			    EndIf
			    nPrimeiro+= 1
				::SetResponse('{')
				_aValid := _aValidE1
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+alltrim(NOACENTO(&(_aValid[_nI,5])))+'"'+iif(_nI<len(_aValid),',',''))
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
	::SetResponse('"PAGINA": '+cvaltochar(SELF:NPAGINA)+',')
	IF(SELF:CWSDIC=='S')
		::SetResponse('"DICIONARIO":{')
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

Private _oBody
Private _oCab
Private _oItens
Private _oItem
Private lMsErroAuto
Private lAutoErrNoFile
Private cArquivo := '/data/log-ws206-'+dtos(date())+'_'+strtran(time(),':','')+'.log'

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


_cCodFil := SELF:CWSFIL

CONOUT('WS 206 - PREPAROU AMBIENTE')

_cVldTkn := ALLTRIM(GETMV('MV_TKNREST',.T.,'123456'))

If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verifique a chave! '+SELF:pToken)
	Return .F.
Else
	//conout('','Token Ok')
EndIf

_cContent  := SELF:GetContent()
FWJsonDeserialize(_cContent,@_oBody)

_nI := 1
While(type('_oBody')='U' .and. _nI < 5)
	FWJsonDeserialize(_cContent,@_oBody)
	_nI++
	If(type('_oBody')!='U')
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
	
	IF((_cAlias1)->(EOF()))
		RECLOCK('ZI0',.T.)
			ZI0->ZI0_FILIAL := XfILIAL('ZI0')
			ZI0->ZI0_WS 	:= 'Z206_POST'
			ZI0->ZI0_NUM	:= GETSXENUM('ZI0','ZI0_NUM',ZI0->ZI0_FILIAL+ZI0->ZI0_WS)
			ZI0->ZI0_JSON	:= _cContent
			ZI0->ZI0_DATA	:= date()
			ZI0->ZI0_STATUS :=' '
		ZI0->(MSUNLOCK())
	ENDIF
	*/
	CONOUT('WS 206 - ENTROU 1')
	_oCab 	:= _oBody

	_aValid := _aValidC5
	CONOUT('WS 206 - INICIO VALIDAÇÃO PEDIDO')
	For _nI := 1 to Len (_aValid) 				
		If (type('_oCab:'+_aValid[_nI][1])=="U" .AND. _aValid[_nI][2]==.T.)
			aAdd(_aRetError,{'500','Campo '+_aValid[_nI][1]+' nao foi declarado'})
		Else
			If(_aValid[_nI][3]=='D')
				If(type('_oCab:'+_aValid[_nI][1])=="C")
					&('_oCab:'+_aValid[_nI][1]) := stod(&('_oCab:'+_aValid[_nI][1]))
				EndIf
			EndIf
			If(type('_oCab:'+_aValid[_nI][1])!=_aValid[_nI][3] .AND. type('_oCab:'+_aValid[_nI][1])<>"U")
				aAdd(_aRetError,{'500','Campo '+_aValid[_nI][1]+' com Tipo: '+type('_oCab:'+_aValid[_nI][1])+' - Esperado: '+_aValid[_nI][3]})
			EndIf
		EndIf
	
	Next _nI
	CONOUT('eRROS: '+CVALTOCHAR(LEN(_aRetError)))
	CONOUT('WS 206 - fim VALIDAÇÃO PEDIDO')

	_oItens := _oBody:ITENS
	
	_aValid := _aValidC6
	For _nJ := 1 to Len(_oItens)
		CONOUT('WS 206 - INICIO VALIDAÇÃO PEDIDO - Item' + CVALTOCHAR(_nJ))
		_oItem := _oItens[_nJ]
		For _nI := 1 to Len (_aValid) 				
			If (type('_oItem:'+_aValid[_nI][1])=="U" .AND. _aValid[_nI][2]==.T.)
			aAdd(_aRetError,{'500','Item '+cvaltochar(_nJ)+' Campo '+_aValid[_nI][1]+' nao foi declarado'})
		Else
			If(_aValid[_nI][3]=='D')
				if(type('_oItem:'+_aValid[_nI][1])=="C")
					&('_oItem:'+_aValid[_nI][1]) := stod(&('_oItem:'+_aValid[_nI][1])) // muda string para data
				EndIf
			EndIf
			If(type('_oItem:'+_aValid[_nI][1])!=_aValid[_nI][3] .AND. type('_oItem:'+_aValid[_nI][1])<>"U")
				aAdd(_aRetError,{'500','Item '+cvaltochar(_nJ)+' Campo '+_aValid[_nI][1]+' com Tipo: '+type('_oItem:'+_aValid[_nI][1])+' - Esperado: '+_aValid[_nI][3]})
			EndIf
		EndIf
		
		Next _nI
		CONOUT('WS 206 - fim VALIDAÇÃO PEDIDO - Item' + CVALTOCHAR(_nJ))

	Next

	::SetResponse('{"RETORNO":{')
	If (Len(_aRetError) = 0)
		conout('Mensagens - sem erros')
		_aCabAuto := {}
		
		_aValid := U_WSCAMPOS('','SC5',.T.)
		
		_nI := 1
		For _nI := 1 to Len(_aValid)
			If(Type('_oCab:'+_aValid[_nI][1])!='U' .and. ! ALLTRIM(_aValid[_nI][5]) $ 'C5_EMISSAO#C5_NUM#')
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
				If(Type('_oItem:'+_aValid[_nI][1])!='U' .and. ! ALLTRIM(_aValid[_nI][5]) $ 'C6_ITEM#C6_FILIAL#')
					aadd(_aLinha,{ALLTRIM(_aValid[_nI][5]), &('_oItem:'+_aValid[_nI][1]), Nil})
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
			
			VARINFO('_aCabAuto 1',_aCabAuto)
			VARINFO('_aIteAuto 1',_aIteAuto)
		// rotina automatica do pedido de venda
		MsExecAuto({|x,y,z| Mata410(x,y,z)},_aCabAuto,_aIteAuto,3) // 3-inclusao

		conout('POST','563 - FIM EXECAUTO '+DTOS(DATE())+' - '+TIME())
		If !lMsErroAuto  // operacao se deu erro
			::SetResponse('"PEDIDO":{')

			_aValidC5 := U_WSCAMPOS('','SC5')
			_aValidC6 := U_WSCAMPOS('','SC6')
			
			_aValid := _aValidC5
			_cAlias := "SC5"
			dbselectarea(_cAlias)
			
			For _nI := 1 to len(_aValid)
				If(_aValid[_nI,3]=='C')
					::SetResponse('"'+_aValid[_nI,1]+'":"'+alltrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
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
			_aValid := _aValidC6
			_NiT := 0
			Do While !(_cAliasC6)->(Eof())
				::SetResponse('{')
				For _nI := 1 to len(_aValid)
					If(_aValid[_nI,3]=='C')
						::SetResponse('"'+_aValid[_nI,1]+'":"'+alltrim(&(_aValid[_nI,5]))+'"'+iif(_nI<len(_aValid),',',''))
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
			::SetResponse(']') //Fecha Itens
			::SetResponse('}') //Fecha Pedido
		Else
			_aErroAuto := GetAutoGRLog()
			cMsg:= "ERRO - PEDIDO VENDA -Arquivo: "+cArquivo
			For _nCount := 1 To Len(_aErroAuto)
				cMsg += StrTran(StrTran(StrTran(_aErroAuto[_nCount],"<",""),"-",""),"   "," ") + (" ")
			Next _nCount	
			::SetResponse('["ID":401,"Erro":"'+cMsg+'"]')
			SetRestFault(499,cMsg)
			Return _lRet				
		EndIf


	Else
		If(Len(_aRetError)>0)
			//conout(varinfo('_aRetError',_aRetError))
			::SetResponse('['+U_WS002RET(_aRetError)+']')
			
			//::SetResponse('{"ID":402,"Erro":"Nenhum cadastro encontrado ('+_cDoc+')!"}')
			//SetRestFault(402,'Erro - Nenhum cadastro encontrado! Verifique as informações enviadas!')
			

		EndIf
	
	EndIf
	::SetResponse("}}")
	
ElseIf(type('_oBody')== 'A')

	CONOUT('WS 206 - ENTROU 2')
	
	For _nJ :=1 to Len(_oBody)
		CONOUT('WS 206 - INICIO VALIDAÇÃO PEDIDO' + CVALTOCHAR(_nJ))
		
		_oCab := _oBody[_nJ]
		
		_aValid := _aValidC5
		For _nI := 1 to Len (_aValid) 				
			If (type('_oCab:'+_aValid[_nI][1])=="U" .AND. _aValid[_nI][2]==.T.)
				aAdd(_aRetError,{'500','Campo '+_aValid[_nI][1]+' nao foi declarado'})
			Else
				If(_aValid[_nI][3]=='D')
					if(type('_oCab:'+_aValid[_nI][1])=="C")
						&('_oCab:'+_aValid[_nI][1]) := stod(&('_oCab:'+_aValid[_nI][1]))
					EndIf
				EndIf
				If(type('_oCab:'+_aValid[_nI][1])!=_aValid[_nI][3] .AND. type('_oCab:'+_aValid[_nI][1])<>"U")
					aAdd(_aRetError,{'500','Campo '+_aValid[_nI][1]+' com Tipo: '+type('_oCab:'+_aValid[_nI][1])+' - Esperado: '+_aValid[_nI][3]})
				EndIf
			EndIf
		
		Next _nI
		
		_oItens := _oCab:ITENS
		
		_aValid := _aValidC6
		For _nK := 1 to Len(_oItens)
			CONOUT('WS 206 - INICIO VALIDAÇÃO PEDIDO - ITENS' + CVALTOCHAR(_nK))
			_oItem := _oItens[_nK]
			For _nI := 1 to Len (_aValid) 				
				If (type('_oItem:'+_aValid[_nI][1])=="U" .AND. _aValid[_nI][2]==.T.)
				aAdd(_aRetError,{'500','Item '+cvaltochar(_nJ)+' Campo '+_aValid[_nI][1]+' nao foi declarado'})
			Else
				If(_aValid[_nI][3]=='D')
					if(type('_oItem:'+_aValid[_nI][1])=="C")
						&('_oItem:'+_aValid[_nI][1]) := stod(&('_oItem:'+_aValid[_nI][1])) // muda string para data
					EndIf
				EndIf
				If(type('_oItem:'+_aValid[_nI][1])!=_aValid[_nI][3] .AND. type('_oItem:'+_aValid[_nI][1])<>"U")
					aAdd(_aRetError,{'500','Item '+cvaltochar(_nJ)+' Campo '+_aValid[_nI][1]+' com Tipo: '+type('_oItem:'+_aValid[_nI][1])+' - Esperado: '+_aValid[_nI][3]})
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
				If(Type('_oCab:'+_aValid[_nI][1])!='U' .and. ! ALLTRIM(_aValid[_nI][5]) $ 'C5_EMISSAO#C5_NUM#')
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
					If(Type('_oClient:'+_aValid[_nI][1])!='U' .and. ! ALLTRIM(_aValid[_nI][5]) $ 'C6_ITEM#C6_FILIAL#')
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
				Return _lRet				
			EndIf
	
		Else
			If(Len(_aRetError)>0)
				::SetResponse(U_WS002RET(_aRetError))
				Return .F.
			EndIf
		
		EndIf
		::SetResponse("]")
		
	next _nJ
	::SetResponse("]]")
EndIf

If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return _lRet

