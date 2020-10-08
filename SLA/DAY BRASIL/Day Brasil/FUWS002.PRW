#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

// ##############################################################################
// Projeto  : Day-Brasil
// Autor    : ANDRE SAKAI
// Modulo   : WS
// Função   : FUWS002 - FUNCOES GENERICAS 
// Descrição: FUNCOES GENERICAS PARA LISTAGEM DE CAMPOS PARA OS WS
// Retorno  : REST COM AS INFORMAÇÕES DA TABELA SE1,SE5
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 31/01/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

User Function WS002SA1(_cTipo)
 
//local varJson := { "teste" : { "var1" : "oioi", "var2": "oioi2", "var3": "oioi3" }}
Local _aCampos := {}
Local _cAlias1 := 'SA1'
 
Default _cTipo := ''

If(Empty(_cTipo))	
	aAdd(_aCampos, {'CODIGO'	,.F.,'C',TAMSX3('A1_COD')[1]	,'A1_COD', NIL})
	aAdd(_aCampos, {'LOJA'		,.F.,'C',TAMSX3('A1_LOJA')[1]	,'A1_LOJA', NIL})
	aAdd(_aCampos, {'NOME'		,.T.,'C',TAMSX3('A1_NOME')[1]	,'A1_NOME', NIL})
	aAdd(_aCampos, {'NREDUZ'	,.T.,'C',TAMSX3('A1_NREDUZ')[1]	,'A1_NREDUZ', NIL})
	aAdd(_aCampos, {'PESSOA'	,.T.,'C',TAMSX3('A1_PESSOA')[1]	,'A1_PESSOA', NIL})
	aAdd(_aCampos, {'TIPO'		,.T.,'C',TAMSX3('A1_TIPO')[1]	,'A1_TIPO', NIL})
	aAdd(_aCampos, {'END'		,.T.,'C',TAMSX3('A1_END')[1]	,'A1_END', NIL})
	aAdd(_aCampos, {'COMPLEM'	,.T.,'C',TAMSX3('A1_COMPLEM')[1],'A1_COMPLEM', NIL})
	aAdd(_aCampos, {'BAIRRO'	,.T.,'C',TAMSX3('A1_BAIRRO')[1]	,'A1_BAIRRO', NIL})
	aAdd(_aCampos, {'CEP'		,.T.,'C',TAMSX3('A1_CEP')[1]	,'A1_CEP', NIL})
	aAdd(_aCampos, {'UF'		,.T.,'C',TAMSX3('A1_EST')[1]	,'A1_EST', NIL})
	aAdd(_aCampos, {'IBGE'		,.T.,'C',TAMSX3('A1_COD_MUN')[1],'A1_COD_MUN', NIL})
	aAdd(_aCampos, {'CIDADE'	,.T.,'C',TAMSX3('A1_MUN')[1]	,'A1_MUN', NIL})
	aAdd(_aCampos, {'DDD'		,.F.,'C',TAMSX3('A1_DDD')[1]	,'A1_DDD', NIL})
	aAdd(_aCampos, {'TEL'		,.F.,'C',TAMSX3('A1_TEL')[1]	,'A1_TEL', NIL})
	aAdd(_aCampos, {'CONTATO'	,.F.,'C',TAMSX3('A1_CONTATO')[1],'A1_CONTATO', NIL})
	aAdd(_aCampos, {'DOC'		,.T.,'C',TAMSX3('A1_CGC')[1]	,'A1_CGC', NIL})
//	aAdd(_aCampos, {'PAIS'		,.F.,'N',TAMSX3('A1_PAIS')[1]	,'A1_PAIS', NIL})
	aAdd(_aCampos, {'INSCR'		,.F.,'C',TAMSX3('A1_INSCR')[1]	,'A1_INSCR', NIL})
	aAdd(_aCampos, {'PFISICA'	,.F.,'C',TAMSX3('A1_PFISICA')[1],'A1_PFISICA', NIL})
	aAdd(_aCampos, {'INSCRM'	,.F.,'C',TAMSX3('A1_INSCRM')[1]	,'A1_INSCRM', NIL})
	aAdd(_aCampos, {'VENDEDOR'	,.F.,'C',TAMSX3('A1_VEND')[1]	,'A1_VEND', NIL})
	aAdd(_aCampos, {'TRANSP'	,.F.,'C',TAMSX3('A1_TRANSP')[1]	,'A1_TRANSP', NIL})
	aAdd(_aCampos, {'COND'		,.F.,'C',TAMSX3('A1_COND')[1]	,'A1_COND', NIL})
	aAdd(_aCampos, {'TPFRET'	,.F.,'C',TAMSX3('A1_TPFRET')[1]	,'A1_TPFRET', NIL})
	aAdd(_aCampos, {'TABELA'	,.F.,'C',TAMSX3('A1_TABELA')[1]	,'A1_TABELA', NIL})
	aAdd(_aCampos, {'DTNASC'	,.F.,'d',TAMSX3('A1_DTNASC')[1]	,'A1_DTNASC', NIL})
	aAdd(_aCampos, {'TPESSOA'	,.F.,'C',TAMSX3('A1_TPESSOA')[1],'A1_TPESSOA', NIL})
	aAdd(_aCampos, {'EMAIL'		,.T.,'C',TAMSX3('A1_EMAIL')[1]	,'A1_EMAIL', NIL})
	aAdd(_aCampos, {'RISCO'		,.F.,'C',TAMSX3('A1_RISCO')[1]	,'A1_RISCO', NIL})
	aAdd(_aCampos, {'BLOQUEADO'	,.F.,'C',TAMSX3('A1_MSBLQL')[1]	,'A1_MSBLQL', NIL})
ElseIf(Upper(_cTipo)= 'COMPLETO')	
	SX3->(DBSETORDER(1))
	SX3->(DBSEEK(_cAlias1))
	While(!SX3->(Eof()) .AND. SX3->X3_ARQUIVO=_cAlias1)
		If(X3USO(SX3->X3_USADO) .AND. SX3->X3_CONTEXT!='V')
			aAdd(_aCampos, {AllTrim(SUBSTR(SX3->X3_CAMPO,4)),X3OBRIGAT(SX3->X3_CAMPO),SX3->X3_TIPO,TAMSX3(SX3->X3_CAMPO)[1],AllTrim(SX3->X3_CAMPO),ALLTRIM(SX3->X3_CBOX)})
		EndIf

		SX3->(DBSKIP())
	EndDo
Elseif(Upper(_cTipo)= 'OBRIGATORIO')

	SX3->(DBSETORDER(1))
	SX3->(DBGOTOP())
	SX3->(DBSEEK(_cTabela))
	While(!SX3->(EOF()) .AND. SX3->X3_ARQUIVO=_cTabela)
		If(X3USO(SX3->X3_USADO) .AND. SX3->X3_CONTEXT!='V' .AND. X3OBRIGAT(SX3->X3_CAMPO))
			aAdd(_aCampos, {AllTrim(SUBSTR(SX3->X3_CAMPO,4)),X3OBRIGAT(SX3->X3_CAMPO),SX3->X3_TIPO,TAMSX3(SX3->X3_CAMPO)[1],AllTrim(SX3->X3_CAMPO),ALLTRIM(SX3->X3_CBOX)})
		EndIf
	
		SX3->(DBSKIP())
	EndDo
EndIf

Return _aCampos

User Function WS002SA2(_cTipo)
 
//local varJson := { "teste" : { "var1" : "oioi", "var2": "oioi2", "var3": "oioi3" }}
Local _aCampos := {}
Local _cAlias1 := 'SA2' 
 
Default _cTipo := ''

If(Empty(_cTipo))	
	aAdd(_aCampos, {'CODIGO'	,.F.,'C',TAMSX3('A2_COD')[1]	,'A2_COD'	, NIL})
	aAdd(_aCampos, {'LOJA'		,.F.,'C',TAMSX3('A2_LOJA')[1]	,'A2_LOJA'	, NIL})
	aAdd(_aCampos, {'NOME'		,.T.,'C',TAMSX3('A2_NOME')[1]	,'A2_NOME'	, NIL})
	aAdd(_aCampos, {'APELIDO'	,.T.,'C',TAMSX3('A2_NREDUZ')[1]	,'A2_NREDUZ', NIL})
	aAdd(_aCampos, {'TIPO'		,.T.,'C',TAMSX3('A2_TIPO')[1]	,'A2_TIPO'	, NIL})
	aAdd(_aCampos, {'ENDERECO'	,.T.,'C',TAMSX3('A2_END')[1]	,'A2_END'	, NIL})
	aAdd(_aCampos, {'COMPLEMENTO',.T.,'C',TAMSX3('A2_COMPLEM')[1],'A2_COMPLEM', NIL})
	aAdd(_aCampos, {'BAIRRO'	,.T.,'C',TAMSX3('A2_BAIRRO')[1]	,'A2_BAIRRO', NIL})
	aAdd(_aCampos, {'UF'		,.T.,'C',TAMSX3('A2_EST')[1]	,'A2_EST'	, NIL})
	aAdd(_aCampos, {'CEP'		,.T.,'C',TAMSX3('A2_CEP')[1]	,'A2_CEP'	, NIL})
	aAdd(_aCampos, {'COD_MUN'	,.T.,'C',TAMSX3('A2_COD_MUN')[1],'A2_COD_MUN', NIL})
	aAdd(_aCampos, {'CIDADE'	,.T.,'C',TAMSX3('A2_MUN')[1]	,'A2_MUN'	, NIL})
	aAdd(_aCampos, {'DDD'		,.F.,'C',TAMSX3('A2_DDD')[1]	,'A2_DDD'	, NIL})
	aAdd(_aCampos, {'TEL'		,.F.,'C',TAMSX3('A2_TEL')[1]	,'A2_TEL'	, NIL})
	aAdd(_aCampos, {'CONTATO'	,.F.,'C',TAMSX3('A2_CONTATO')[1],'A2_CONTATO', NIL})
	aAdd(_aCampos, {'DOC'		,.T.,'C',TAMSX3('A2_CGC')[1]	,'A2_CGC'	, NIL})
//	aAdd(_aCampos, {'PAIS'		,.F.,'N',TAMSX3('A2_PAIS')[1]	,'A2_PAIS'})
	aAdd(_aCampos, {'INSCR'		,.F.,'C',TAMSX3('A2_INSCR')[1]	,'A2_INSCR'	, NIL})
	aAdd(_aCampos, {'INSCRM'	,.F.,'C',TAMSX3('A2_INSCRM')[1]	,'A2_INSCRM', NIL})
//	aAdd(_aCampos, {'NATUREZA'	,.T.,'C',TAMSX3('A2_NATUREZ')[1],'A2_NATUREZ', NIL,'100001 cek'})
//	aAdd(_aCampos, {'TRANSP'	,.F.,'C',TAMSX3('A2_TRANSP')[1]	,'A2_TRANSP', NIL})
//	aAdd(_aCampos, {'CONDICAO'	,.F.,'C',TAMSX3('A2_COND')[1]	,'A2_COND'	, NIL})
//	aAdd(_aCampos, {'TPFRET'	,.F.,'C',TAMSX3('A2_TPFRET')[1]	,'A2_TPFRET', NIL})
//	aAdd(_aCampos, {'TABELA'	,.F.,'C',TAMSX3('A2_TABELA')[1]	,'A2_TABELA', NIL})
//	aAdd(_aCampos, {'DTNASC'	,.F.,'d',TAMSX3('A2_DTNASC')[1]	,'A2_DTNASC', NIL})
//	aAdd(_aCampos, {'TPESSOA'	,.F.,'C',TAMSX3('A2_TPESSOA')[1],'A2_TPESSOA', ''})
	aAdd(_aCampos, {'EMAIL'		,.T.,'C',TAMSX3('A2_EMAIL')[1]	,'A2_EMAIL'	, NIL})
	aAdd(_aCampos, {'BLOQUEADO'	,.F.,'C',TAMSX3('A2_MSBLQL')[1]	,'A2_MSBLQL', '1=Bloqueado, 2=Liberado'})
Elseif(Upper(_cTipo)= 'COMPLETO')
	SX3->(DBSETORDER(1))
	SX3->(DBSEEK(_cAlias1))
	While(!SX3->(Eof()) .AND. SX3->X3_ARQUIVO=_cAlias1)
		If(X3USO(SX3->X3_USADO) .AND. SX3->X3_CONTEXT!='V')
			aAdd(_aCampos, {AllTrim(SUBSTR(SX3->X3_CAMPO,4)),X3OBRIGAT(SX3->X3_CAMPO),SX3->X3_TIPO,TAMSX3(SX3->X3_CAMPO)[1],AllTrim(SX3->X3_CAMPO),ALLTRIM(SX3->X3_CBOX)})
		EndIf
		SX3->(DBSKIP())
	EndDo
Elseif(Upper(_cTipo)= 'OBRIGATORIO')
	SX3->(DBSETORDER(1))
	SX3->(DBGOTOP())
	SX3->(DBSEEK(_cTabela))
	While(!SX3->(EOF()) .AND. SX3->X3_ARQUIVO=_cTabela)
		If(X3USO(SX3->X3_USADO) .AND. SX3->X3_CONTEXT!='V' .AND. X3OBRIGAT(SX3->X3_CAMPO))
			aAdd(_aCampos, {AllTrim(SUBSTR(SX3->X3_CAMPO,4)),X3OBRIGAT(SX3->X3_CAMPO),SX3->X3_TIPO,TAMSX3(SX3->X3_CAMPO)[1],AllTrim(SX3->X3_CAMPO),ALLTRIM(SX3->X3_CBOX)})
		EndIf
	
		SX3->(DBSKIP())
	EndDo
Endif

Return _aCampos

User Function WS003RET(_aErros)


Return U_WS002RET(_aErros)


User Function WS002RET(_aErros)
 
//    Local _cJson 
    Local _nI := 0
    Local _cRet := ''
    
    For _nI := 1 to Len(_aErros)
	    if(_nI > 1)
	    	_cRet += CRLF+','
	    endif
    	_cRet += '{"Erro":"'+_aErros[_nI,2]+'"}'
    Next _nI
    
Return _cRet


User Function WS103SA3(_cTipo)


Return u_WS002SA3(_cTipo)

User Function WS002SA3(_cTipo)

Local _aCampos := ''
Local _cAlias1 := 'SA3'

Default _cTipo := ''

If(Empty(_cTipo))	
	_aCampos := {}
	aAdd(_aCampos, {'CODIGO'	,.F.,'C',TAMSX3('A3_COD')[1]	,'A3_COD',NIL})
	aAdd(_aCampos, {'NOME'		,.T.,'C',TAMSX3('A3_NOME')[1]	,'A3_NOME',NIL})
	aAdd(_aCampos, {'APELIDO'	,.T.,'C',TAMSX3('A3_NREDUZ')[1]	,'A3_NREDUZ',NIL})
	aAdd(_aCampos, {'ENDERECO'	,.T.,'C',TAMSX3('A3_END')[1]	,'A3_END',NIL})
	aAdd(_aCampos, {'BAIRRO'	,.T.,'C',TAMSX3('A3_BAIRRO')[1]	,'A3_BAIRRO',NIL})
	aAdd(_aCampos, {'CIDADE'	,.T.,'C',TAMSX3('A3_MUN')[1]	,'A3_MUN',NIL})
	aAdd(_aCampos, {'ESTADO'	,.T.,'C',TAMSX3('A3_EST')[1]	,'A3_EST',NIL})
	aAdd(_aCampos, {'CEP'		,.F.,'C',TAMSX3('A3_CEP')[1]	,'A3_CEP',NIL})
	aAdd(_aCampos, {'DDD'		,.F.,'C',TAMSX3('A3_DDDTEL')[1]	,'A3_DDDTEL',NIL})
	aAdd(_aCampos, {'TELEFONE'	,.F.,'C',TAMSX3('A3_TEL')[1]	,'A3_TEL',NIL})
	aAdd(_aCampos, {'CELULAR'	,.F.,'C',TAMSX3('A3_CEL')[1]	,'A3_CEL',NIL})	
	aAdd(_aCampos, {'TIPO'		,.F.,'C',TAMSX3('A3_TIPO')[1]	,'A3_TIPO','I=Interno, E=Externo, P=Parceiro'})
	aAdd(_aCampos, {'DOC'		,.F.,'C',TAMSX3('A3_CGC')[1]	,'A3_CGC',NIL})
	aAdd(_aCampos, {'INSCR_EST'	,.F.,'C',TAMSX3('A3_INSCR')[1]	,'A3_INSCR',NIL})
	aAdd(_aCampos, {'INSCR_MUN'	,.F.,'C',TAMSX3('A3_INSCRM')[1]	,'A3_INSCRM',NIL})
	aAdd(_aCampos, {'BANCO'		,.F.,'C',TAMSX3('A3_BCO1')[1]	,'A3_BCO1',NIL})
	aAdd(_aCampos, {'FORNECEDOR',.F.,'C',TAMSX3('A3_FORNECE')[1],'A3_FORNECE',NIL})
	aAdd(_aCampos, {'LOJA'		,.F.,'C',TAMSX3('A3_LOJA')[1]	,'A3_LOJA',NIL})
	aAdd(_aCampos, {'MATRICULA'	,.F.,'C',TAMSX3('A3_NUMRA')[1]	,'A3_NUMRA',NIL})
	aAdd(_aCampos, {'PAGAMENTO'	,.F.,'C',TAMSX3('A3_GERASE2')[1],'A3_GERASE2',NIL})
	aAdd(_aCampos, {'BLOQUEIO'	,.F.,'C',TAMSX3('A3_MSBLQL')[1]	,'A3_MSBLQL','1=Bloqueado, 2=Liberado, " "=Liberado'})
Elseif(Upper(_cTipo)= 'COMPLETO')
	SX3->(DBSETORDER(1))
	SX3->(DBSEEK(_cAlias1))
	While(!SX3->(Eof()) .AND. SX3->X3_ARQUIVO=_cAlias1)
		If(X3USO(SX3->X3_USADO) .AND. SX3->X3_CONTEXT!='V')
			aAdd(_aCampos, {AllTrim(SUBSTR(SX3->X3_CAMPO,4)),X3OBRIGAT(SX3->X3_CAMPO),SX3->X3_TIPO,TAMSX3(SX3->X3_CAMPO)[1],AllTrim(SX3->X3_CAMPO),ALLTRIM(SX3->X3_CBOX)})
		EndIf
		SX3->(DBSKIP())
	EndDo
Elseif(Upper(_cTipo)= 'OBRIGATORIO')
	SX3->(DBSETORDER(1))
	SX3->(DBGOTOP())
	SX3->(DBSEEK(_cTabela))
	While(!SX3->(EOF()) .AND. SX3->X3_ARQUIVO=_cTabela)
		If(X3USO(SX3->X3_USADO) .AND. SX3->X3_CONTEXT!='V' .AND. X3OBRIGAT(SX3->X3_CAMPO))
			aAdd(_aCampos, {AllTrim(SUBSTR(SX3->X3_CAMPO,4)),X3OBRIGAT(SX3->X3_CAMPO),SX3->X3_TIPO,TAMSX3(SX3->X3_CAMPO)[1],AllTrim(SX3->X3_CAMPO),ALLTRIM(SX3->X3_CBOX)})
		EndIf
	
		SX3->(DBSKIP())
	EndDo
Endif
//	conout('WS002SA3 - CAMPOS')
//	varinfo('_aCampos',_aCampos)

Return _aCampos



User Function WS002SA4(_cTipo)
 
   Local _aCampos := {}
   Local _cAlias1 := 'SA4'
   Default _cTipo := ''
    
   
If(Empty(_cTipo))	
	aAdd(_aCampos, {'CODIGO'	,.F.,'C',TAMSX3('A4_COD')[1]	,'A4_COD',NIL})
	aAdd(_aCampos, {'NOME'		,.T.,'C',TAMSX3('A4_NOME')[1]	,'A4_NOME',NIL})
	aAdd(_aCampos, {'APELIDO'	,.T.,'C',TAMSX3('A4_NREDUZ')[1]	,'A4_NREDUZ',NIL})
	aAdd(_aCampos, {'VIA'		,.F.,'C',TAMSX3('A4_VIA')[1]	,'A4_VIA',NIL})
Elseif(Upper(_cTipo)= 'COMPLETO')
	SX3->(DBSETORDER(1))
	SX3->(DBSEEK(_cAlias1))
	While(!SX3->(Eof()) .AND. SX3->X3_ARQUIVO=_cAlias1)
		If(X3USO(SX3->X3_USADO) .AND. SX3->X3_CONTEXT!='V')
			aAdd(_aCampos, {AllTrim(SUBSTR(SX3->X3_CAMPO,4)),X3OBRIGAT(SX3->X3_CAMPO),SX3->X3_TIPO,TAMSX3(SX3->X3_CAMPO)[1],AllTrim(SX3->X3_CAMPO),ALLTRIM(SX3->X3_CBOX)})
		EndIf
		SX3->(DBSKIP())
	EndDo
Elseif(Upper(_cTipo)= 'OBRIGATORIO')
	SX3->(DBSETORDER(1))
	SX3->(DBGOTOP())
	SX3->(DBSEEK(_cTabela))
	While(!SX3->(EOF()) .AND. SX3->X3_ARQUIVO=_cTabela)
		If(X3USO(SX3->X3_USADO) .AND. SX3->X3_CONTEXT!='V' .AND. X3OBRIGAT(SX3->X3_CAMPO))
			aAdd(_aCampos, {AllTrim(SUBSTR(SX3->X3_CAMPO,4)),X3OBRIGAT(SX3->X3_CAMPO),SX3->X3_TIPO,TAMSX3(SX3->X3_CAMPO)[1],AllTrim(SX3->X3_CAMPO),ALLTRIM(SX3->X3_CBOX)})
		EndIf
	
		SX3->(DBSKIP())
	EndDo
Endif
//	conout('WS002SA3 - CAMPOS')
//	varinfo('_aCampos',_aCampos)

Return _aCampos



User Function WSCAMPOS(_cTipo,_cTabela,_lInclui)

	Local 	_aCampos 	:= {}
	Local 	_aPadrao	:= {}
	Local 	_nPos		:= 0
	Local 	_nJ			:= ''
	
	Default _cTipo 		:= ''
	Default _cTabela 	:= ''
	
	Default _cInclui := .f.
	
	_aCampos := {}
	
	If(Empty(_cTipo))	
		If(_cTabela = 'SE4')
			aAdd(_aCampos, {'CODIGO'	,.T.,'C',TAMSX3('E4_CODIGO')[1]	,'E4_CODIGO',NIL,NIL})
			aAdd(_aCampos, {'TIPO'		,.T.,'C',TAMSX3('E4_TIPO')[1]	,'E4_TIPO',NIL,NIL})
			aAdd(_aCampos, {'COND'		,.T.,'C',TAMSX3('E4_COND')[1]	,'E4_COND',NIL,NIL})
			aAdd(_aCampos, {'DESCRICAO'	,.T.,'C',TAMSX3('E4_DESCRI')[1]	,'E4_DESCRI',NIL,NIL})
			
		ElseIf((_cTabela = 'SA1'))

			aAdd(_aCampos, {'CHAVE'		,.F.,'C',TAMSX3('A1_COD')[1]+TAMSX3('A1_LOJA')[1]	,'CHAVE', NIL})
			aAdd(_aCampos, {'CODIGO'	,.F.,'C',TAMSX3('A1_COD')[1]	,'A1_COD', NIL})
			aAdd(_aCampos, {'LOJA'		,.F.,'C',TAMSX3('A1_LOJA')[1]	,'A1_LOJA', NIL})
			aAdd(_aCampos, {'NOME'		,.T.,'C',TAMSX3('A1_NOME')[1]	,'A1_NOME', NIL})
			aAdd(_aCampos, {'NREDUZ'	,.T.,'C',TAMSX3('A1_NREDUZ')[1]	,'A1_NREDUZ', NIL})
			aAdd(_aCampos, {'PESSOA'	,.T.,'C',TAMSX3('A1_PESSOA')[1]	,'A1_PESSOA', NIL})
			aAdd(_aCampos, {'TIPO'		,.T.,'C',TAMSX3('A1_TIPO')[1]	,'A1_TIPO', NIL})
			aAdd(_aCampos, {'END'		,.T.,'C',TAMSX3('A1_END')[1]	,'A1_END', NIL})
			aAdd(_aCampos, {'COMPLEM'	,.T.,'C',TAMSX3('A1_COMPLEM')[1],'A1_COMPLEM', NIL})
			aAdd(_aCampos, {'BAIRRO'	,.T.,'C',TAMSX3('A1_BAIRRO')[1]	,'A1_BAIRRO', NIL})
			aAdd(_aCampos, {'CEP'		,.T.,'C',TAMSX3('A1_CEP')[1]	,'A1_CEP', NIL})
			aAdd(_aCampos, {'UF'		,.T.,'C',TAMSX3('A1_EST')[1]	,'A1_EST', NIL})
			aAdd(_aCampos, {'IBGE'		,.T.,'C',TAMSX3('A1_COD_MUN')[1],'A1_COD_MUN', NIL})
			aAdd(_aCampos, {'CIDADE'	,.T.,'C',TAMSX3('A1_MUN')[1]	,'A1_MUN', NIL})
			aAdd(_aCampos, {'DDD'		,.F.,'C',TAMSX3('A1_DDD')[1]	,'A1_DDD', NIL})
			aAdd(_aCampos, {'TEL'		,.F.,'C',TAMSX3('A1_TEL')[1]	,'A1_TEL', NIL})
			aAdd(_aCampos, {'CONTATO'	,.F.,'C',TAMSX3('A1_CONTATO')[1],'A1_CONTATO', NIL})
			aAdd(_aCampos, {'DOC'		,.T.,'C',TAMSX3('A1_CGC')[1]	,'A1_CGC', NIL})
		//	aAdd(_aCampos, {'PAIS'		,.F.,'N',TAMSX3('A1_PAIS')[1]	,'A1_PAIS', NIL})
			aAdd(_aCampos, {'INSCR'		,.F.,'C',TAMSX3('A1_INSCR')[1]	,'A1_INSCR', NIL})
			aAdd(_aCampos, {'PFISICA'	,.F.,'C',TAMSX3('A1_PFISICA')[1],'A1_PFISICA', NIL})
			aAdd(_aCampos, {'INSCRM'	,.F.,'C',TAMSX3('A1_INSCRM')[1]	,'A1_INSCRM', NIL})
			aAdd(_aCampos, {'VENDEDOR'	,.F.,'C',TAMSX3('A1_VEND')[1]	,'A1_VEND', NIL})
			aAdd(_aCampos, {'TRANSP'	,.F.,'C',TAMSX3('A1_TRANSP')[1]	,'A1_TRANSP', NIL})
			aAdd(_aCampos, {'COND'		,.F.,'C',TAMSX3('A1_COND')[1]	,'A1_COND', NIL})
			aAdd(_aCampos, {'TPFRET'	,.F.,'C',TAMSX3('A1_TPFRET')[1]	,'A1_TPFRET', NIL})
			aAdd(_aCampos, {'TABELA'	,.F.,'C',TAMSX3('A1_TABELA')[1]	,'A1_TABELA', NIL})
			aAdd(_aCampos, {'DTNASC'	,.F.,'d',TAMSX3('A1_DTNASC')[1]	,'A1_DTNASC', NIL})
			aAdd(_aCampos, {'TPESSOA'	,.F.,'C',TAMSX3('A1_TPESSOA')[1],'A1_TPESSOA', NIL})
			aAdd(_aCampos, {'SUFRAMA'	,.F.,'C',TAMSX3('A1_SUFRAMA')[1],'A1_SUFRAMA', NIL})
			aAdd(_aCampos, {'EMAIL'		,.T.,'C',TAMSX3('A1_EMAIL')[1]	,'A1_EMAIL', NIL})
			aAdd(_aCampos, {'RISCO'		,.F.,'C',TAMSX3('A1_RISCO')[1]	,'A1_RISCO', NIL})
			aAdd(_aCampos, {'LIMITE'	,.F.,'N',TAMSX3('A1_LC')[1]		,'A1_LC', NIL})
			aAdd(_aCampos, {'SALDO_TIT'	,.F.,'N',TAMSX3('A1_SALDUP')[1]	,'A1_SALDUP', NIL})
			aAdd(_aCampos, {'BLOQUEADO'	,.F.,'C',TAMSX3('A1_MSBLQL')[1]	,'A1_MSBLQL', NIL})
		ElseIf((_cTabela = 'SA2'))
			aAdd(_aCampos, {'CODIGO'	,.F.,'C',TAMSX3('A2_COD')[1]	,'A2_COD'	, NIL})
			aAdd(_aCampos, {'LOJA'		,.F.,'C',TAMSX3('A2_LOJA')[1]	,'A2_LOJA'	, NIL})
			aAdd(_aCampos, {'NOME'		,.T.,'C',TAMSX3('A2_NOME')[1]	,'A2_NOME'	, NIL})
			aAdd(_aCampos, {'APELIDO'	,.T.,'C',TAMSX3('A2_NREDUZ')[1]	,'A2_NREDUZ', NIL})
			aAdd(_aCampos, {'TIPO'		,.T.,'C',TAMSX3('A2_TIPO')[1]	,'A2_TIPO'	, NIL})
			aAdd(_aCampos, {'ENDERECO'	,.T.,'C',TAMSX3('A2_END')[1]	,'A2_END'	, NIL})
			aAdd(_aCampos, {'COMPLEMENTO',.T.,'C',TAMSX3('A2_COMPLEM')[1],'A2_COMPLEM', NIL})
			aAdd(_aCampos, {'BAIRRO'	,.T.,'C',TAMSX3('A2_BAIRRO')[1]	,'A2_BAIRRO', NIL})
			aAdd(_aCampos, {'UF'		,.T.,'C',TAMSX3('A2_EST')[1]	,'A2_EST'	, NIL})
			aAdd(_aCampos, {'CEP'		,.T.,'C',TAMSX3('A2_CEP')[1]	,'A2_CEP'	, NIL})
			aAdd(_aCampos, {'COD_MUN'	,.T.,'C',TAMSX3('A2_COD_MUN')[1],'A2_COD_MUN', NIL})
			aAdd(_aCampos, {'CIDADE'	,.T.,'C',TAMSX3('A2_MUN')[1]	,'A2_MUN'	, NIL})
			aAdd(_aCampos, {'DDD'		,.F.,'C',TAMSX3('A2_DDD')[1]	,'A2_DDD'	, NIL})
			aAdd(_aCampos, {'TEL'		,.F.,'C',TAMSX3('A2_TEL')[1]	,'A2_TEL'	, NIL})
			aAdd(_aCampos, {'CONTATO'	,.F.,'C',TAMSX3('A2_CONTATO')[1],'A2_CONTATO', NIL})
			aAdd(_aCampos, {'DOC'		,.T.,'C',TAMSX3('A2_CGC')[1]	,'A2_CGC'	, NIL})
		//	aAdd(_aCampos, {'PAIS'		,.F.,'N',TAMSX3('A2_PAIS')[1]	,'A2_PAIS'})
			aAdd(_aCampos, {'INSCR'		,.F.,'C',TAMSX3('A2_INSCR')[1]	,'A2_INSCR'	, NIL})
			aAdd(_aCampos, {'INSCRM'	,.F.,'C',TAMSX3('A2_INSCRM')[1]	,'A2_INSCRM', NIL})
			aAdd(_aCampos, {'NATUREZA'	,.T.,'C',TAMSX3('A2_NATUREZ')[1],'A2_NATUREZ', NIL})
		//	aAdd(_aCampos, {'TRANSP'	,.F.,'C',TAMSX3('A2_TRANSP')[1]	,'A2_TRANSP', NIL})
		//	aAdd(_aCampos, {'CONDICAO'	,.F.,'C',TAMSX3('A2_COND')[1]	,'A2_COND'	, NIL})
		//	aAdd(_aCampos, {'TPFRET'	,.F.,'C',TAMSX3('A2_TPFRET')[1]	,'A2_TPFRET', NIL})
		//	aAdd(_aCampos, {'TABELA'	,.F.,'C',TAMSX3('A2_TABELA')[1]	,'A2_TABELA', NIL})
		//	aAdd(_aCampos, {'DTNASC'	,.F.,'d',TAMSX3('A2_DTNASC')[1]	,'A2_DTNASC', NIL})
		//	aAdd(_aCampos, {'TPESSOA'	,.F.,'C',TAMSX3('A2_TPESSOA')[1],'A2_TPESSOA', ''})
			aAdd(_aCampos, {'EMAIL'		,.T.,'C',TAMSX3('A2_EMAIL')[1]	,'A2_EMAIL'	, NIL})
			aAdd(_aCampos, {'BLOQUEADO'	,.F.,'C',TAMSX3('A2_MSBLQL')[1]	,'A2_MSBLQL', '1=Bloqueado, 2=Liberado'})
		ElseIf((_cTabela = 'SA3'))
			aAdd(_aCampos, {'CODIGO'	,.F.,'C',TAMSX3('A3_COD')[1]	,'A3_COD',NIL})
			aAdd(_aCampos, {'NOME'		,.T.,'C',TAMSX3('A3_NOME')[1]	,'A3_NOME',NIL})
			aAdd(_aCampos, {'APELIDO'	,.T.,'C',TAMSX3('A3_NREDUZ')[1]	,'A3_NREDUZ',NIL})
			aAdd(_aCampos, {'ENDERECO'	,.T.,'C',TAMSX3('A3_END')[1]	,'A3_END',NIL})
			aAdd(_aCampos, {'BAIRRO'	,.T.,'C',TAMSX3('A3_BAIRRO')[1]	,'A3_BAIRRO',NIL})
			aAdd(_aCampos, {'CIDADE'	,.T.,'C',TAMSX3('A3_MUN')[1]	,'A3_MUN',NIL})
			aAdd(_aCampos, {'ESTADO'	,.T.,'C',TAMSX3('A3_EST')[1]	,'A3_EST',NIL})
			aAdd(_aCampos, {'CEP'		,.F.,'C',TAMSX3('A3_CEP')[1]	,'A3_CEP',NIL})
			aAdd(_aCampos, {'DDD'		,.F.,'C',TAMSX3('A3_DDDTEL')[1]	,'A3_DDDTEL',NIL})
			aAdd(_aCampos, {'TELEFONE'	,.F.,'C',TAMSX3('A3_TEL')[1]	,'A3_TEL',NIL})
			aAdd(_aCampos, {'CELULAR'	,.F.,'C',TAMSX3('A3_CEL')[1]	,'A3_CEL',NIL})	
			aAdd(_aCampos, {'TIPO'		,.F.,'C',TAMSX3('A3_TIPO')[1]	,'A3_TIPO','I=Interno, E=Externo, P=Parceiro'})
			aAdd(_aCampos, {'DOC'		,.F.,'C',TAMSX3('A3_CGC')[1]	,'A3_CGC',NIL})
			aAdd(_aCampos, {'INSCR_EST'	,.F.,'C',TAMSX3('A3_INSCR')[1]	,'A3_INSCR',NIL})
			aAdd(_aCampos, {'INSCR_MUN'	,.F.,'C',TAMSX3('A3_INSCRM')[1]	,'A3_INSCRM',NIL})
			aAdd(_aCampos, {'BANCO'		,.F.,'C',TAMSX3('A3_BCO1')[1]	,'A3_BCO1',NIL})
			aAdd(_aCampos, {'FORNECEDOR',.F.,'C',TAMSX3('A3_FORNECE')[1],'A3_FORNECE',NIL})
			aAdd(_aCampos, {'LOJA'		,.F.,'C',TAMSX3('A3_LOJA')[1]	,'A3_LOJA',NIL})
			aAdd(_aCampos, {'MATRICULA'	,.F.,'C',TAMSX3('A3_NUMRA')[1]	,'A3_NUMRA',NIL})
			aAdd(_aCampos, {'PAGAMENTO'	,.F.,'C',TAMSX3('A3_GERASE2')[1],'A3_GERASE2',NIL})
			aAdd(_aCampos, {'BLOQUEIO'	,.F.,'C',TAMSX3('A3_MSBLQL')[1]	,'A3_MSBLQL','1=Bloqueado, 2=Liberado, " "=Liberado'})
		ElseIf((_cTabela = 'SA4'))
			aAdd(_aCampos, {'CODIGO'	,.F.,'C',TAMSX3('A4_COD')[1]	,'A4_COD',NIL})
			aAdd(_aCampos, {'NOME'		,.T.,'C',TAMSX3('A4_NOME')[1]	,'A4_NOME',NIL})
			aAdd(_aCampos, {'APELIDO'	,.T.,'C',TAMSX3('A4_NREDUZ')[1]	,'A4_NREDUZ',NIL})
			aAdd(_aCampos, {'VIA'		,.F.,'C',TAMSX3('A4_VIA')[1]	,'A4_VIA',NIL})
		ElseIf(_cTabela = 'SC5')
			if(!_lInclui)
				aAdd(_aCampos, {'NUMERO'		,.T.,'C',TAMSX3('C5_NUM')[1]		,'C5_NUM'			,NIL})
			EndIf
			aAdd(_aCampos, {'TIPO'			,.T.,'C',TAMSX3('C5_TIPO')[1]		,'C5_TIPO'			,NIL})
			aAdd(_aCampos, {'CLIENTE'		,.T.,'C',TAMSX3('C5_CLIENTE')[1]	,'C5_CLIENTE'		,NIL})
			aAdd(_aCampos, {'LOJA'			,.T.,'C',TAMSX3('C5_LOJACLI')[1]	,'C5_LOJACLI'		,NIL})
			aAdd(_aCampos, {'TRANSPORTADORA',.T.,'C',TAMSX3('C5_TRANSP')[1]		,'C5_TRANSP'		,NIL})
			aAdd(_aCampos, {'TIPOCLIENTE'	,.T.,'C',TAMSX3('C5_TIPOCLI')[1]	,'C5_TIPOCLI'		,NIL})
			aAdd(_aCampos, {'TABELA'		,.T.,'C',TAMSX3('C5_TABELA')[1]		,'C5_TABELA'		,NIL})
			aAdd(_aCampos, {'COND_PAG'		,.T.,'C',TAMSX3('C5_CONDPAG')[1]	,'C5_CONDPAG'		,NIL})
			aAdd(_aCampos, {'DESCONTO'		,.F.,'N',TAMSX3('C5_DESC1')[1]		,'C5_DESC1'			,NIL})
			if(!_lInclui)
				aAdd(_aCampos, {'EMISSAO'		,.T.,'D',TAMSX3('C5_EMISSAO')[1]	,'C5_EMISSAO'		,NIL})
			EndIf
			aAdd(_aCampos, {'TIPOFRETE'		,.T.,'C',TAMSX3('C5_TPFRETE')[1]	,'C5_TPFRETE'		,NIL})
			aAdd(_aCampos, {'FRETE'			,.T.,'N',TAMSX3('C5_FRETE')[1]		,'C5_FRETE'			,NIL})
			aAdd(_aCampos, {'PESOLIQ'		,.F.,'N',TAMSX3('C5_PESOL')[1]		,'C5_PESOL'			,NIL})
			aAdd(_aCampos, {'PESOBRUT'		,.F.,'N',TAMSX3('C5_PBRUTO')[1]		,'C5_PBRUTO'		,NIL})
			aAdd(_aCampos, {'VOLUME'		,.F.,'N',TAMSX3('C5_VOLUME1')[1]	,'C5_VOLUME1'		,NIL})
			aAdd(_aCampos, {'VOLUME_TIPO'	,.F.,'C',TAMSX3('C5_ESPECI1')[1]	,'C5_ESPECI1'		,NIL})
			aAdd(_aCampos, {'MENSAGEM_NOTA'	,.F.,'C',TAMSX3('C5_MENNOTA')[1]	,'C5_MENNOTA'		,NIL})
/*/			If(SC5->(FIELDPOS())>0)
				
			EndIf
/*/			
//			aAdd(_aCampos, {'BLEMAIL'		,.F.,'C',TAMSX3('C5_BLEMAIL')[1]	,'C5_BLEMAIL'		,NIL})
		ElseIf(_cTabela = 'SB1')
			aAdd(_aCampos, {'PRODUTO'		,.T.,'C',TAMSX3('B1_COD')[1]		,'B1_COD'		,NIL})
			aAdd(_aCampos, {'DESCRICAO'		,.T.,'C',TAMSX3('B1_DESC')[1]		,'B1_DESC'	,NIL})
			aAdd(_aCampos, {'UNIDADE_MEDIDA',.T.,'C',TAMSX3('B1_UM')[1]			,'B1_UM'		,NIL})
			aAdd(_aCampos, {'TIPO'			,.T.,'C',TAMSX3('B1_TIPO')[1]		,'B1_TIPO'		,NIL})
			aAdd(_aCampos, {'GRUPO'			,.T.,'C',TAMSX3('B1_GRUPO')[1]		,'B1_GRUPO'		,NIL})
			aAdd(_aCampos, {'GRUPO_DESC'	,.F.,'C',TAMSX3('BM_DESC')[1]		,'BM_DESC'		,NIL})
			aAdd(_aCampos, {'NCM'			,.T.,'C',TAMSX3('B1_POSIPI')[1]		,'B1_POSIPI'	,NIL})
			aAdd(_aCampos, {'ORIGEM'		,.T.,'C',TAMSX3('B1_ORIGEM')[1]		,'B1_ORIGEM'	,NIL})

			aAdd(_aCampos, {'PRECO_VENDA'	,.T.,'N',TAMSX3('B1_PRV1')[1]		,'B1_PRV1'	,NIL})
		ElseIf(_cTabela = 'SC6')
			if(!_lInclui)
				aAdd(_aCampos, {'NUM'			,.T.,'C',TAMSX3('C6_NUM')[1]		,'C6_NUM'		,NIL})
				aAdd(_aCampos, {'ITEM'			,.T.,'C',TAMSX3('C6_ITEM')[1]		,'C6_ITEM'		,NIL})
			ENDIF
			aAdd(_aCampos, {'PRODUTO'		,.T.,'C',TAMSX3('C6_PRODUTO')[1]	,'C6_PRODUTO'	,NIL})
			aAdd(_aCampos, {'PRC_TABELA'	,.F.,'N',TAMSX3('C6_PRUNIT')[1]		,'C6_PRUNIT'	,NIL})
			aAdd(_aCampos, {'QUANTIDADE'	,.T.,'N',TAMSX3('C6_QTDVEN')[1]		,'C6_QTDVEN'	,NIL})
			aAdd(_aCampos, {'PRECO_VENDA'	,.T.,'N',TAMSX3('C6_PRCVEN')[1]		,'C6_PRCVEN'	,NIL})
			aAdd(_aCampos, {'VALOR'			,.F.,'N',TAMSX3('C6_VALOR')[1]		,'C6_VALOR'		,NIL})
			aAdd(_aCampos, {'OPERACAO'		,.T.,'C',TAMSX3('C6_OPER')[1]		,'C6_OPER'		,NIL})
			if(!_lInclui)
				aAdd(_aCampos, {'TIPO_SAIDA'	,.F.,'C',TAMSX3('C6_TES')[1]		,'C6_TES'		,NIL})
			ENDIF
			aAdd(_aCampos, {'QTD_LIBERADA'	,.F.,'N',TAMSX3('C6_QTDLIB')[1]		,'C6_QTDLIB'	,NIL})
			aAdd(_aCampos, {'NOTA_NUMERO'	,.F.,'C',TAMSX3('C6_NOTA')[1]		,'C6_NOTA'		,NIL})
			aAdd(_aCampos, {'NOTA_SERIE'	,.F.,'C',TAMSX3('C6_SERIE')[1]		,'C6_SERIE'		,NIL})			
			//aAdd(_aCampos, {'QTD_LIBERADA'	,.F.,'C',TAMSX3('C6_QTDLIB')[1]		,'C6_QTDLIB'	,NIL})
			
		ElseIf(_cTabela = 'SE1')
			aAdd(_aCampos, {'PREFIXO'			,.T.,'C',TAMSX3('E1_PREFIXO')[1]	,'E1_PREFIXO'	,NIL})
			aAdd(_aCampos, {'NUMERO'			,.T.,'C',TAMSX3('E1_NUM')[1]		,'E1_NUM'		,NIL})
			aAdd(_aCampos, {'PARCELA'			,.T.,'C',TAMSX3('E1_PARCELA')[1]	,'E1_PARCELA'	,NIL})
			aAdd(_aCampos, {'TIPO'				,.T.,'C',TAMSX3('E1_TIPO')[1]		,'E1_TIPO'		,NIL})
			aAdd(_aCampos, {'EMISSAO'			,.T.,'D',TAMSX3('E1_EMISSAO')[1]	,'E1_EMISSAO'	,NIL})
			aAdd(_aCampos, {'VENCIMENTO'		,.T.,'D',TAMSX3('E1_VENCTO')[1]		,'E1_VENCTO'	,NIL})
			aAdd(_aCampos, {'VENC_REAL'			,.T.,'D',TAMSX3('E1_VENCREA')[1]	,'E1_VENCREA'	,NIL})
			aAdd(_aCampos, {'VALOR'				,.T.,'N',TAMSX3('E1_VALOR')[1]		,'E1_VALOR'		,NIL})
			aAdd(_aCampos, {'SALDO'				,.T.,'N',TAMSX3('E1_SALDO')[1]		,'E1_SALDO'		,NIL})
//			aAdd(_aCampos, {'NEGOCIADO'			,.T.,'C',TAMSX3('E1_TIPO')[1]		,'E1_TIPO'		,NIL})
		
		ElseIf(_cTabela = 'SE2')
		
		ElseIf(_cTabela = 'SE5')
			aAdd(_aCampos, {'PREFIXO'			,.T.,'C',TAMSX3('E5_PREFIXO')[1]	,'E5_PREFIXO'	,NIL})
			aAdd(_aCampos, {'NUMERO'			,.T.,'C',TAMSX3('E5_NUMERO')[1]		,'E5_NUMERO'	,NIL})
			aAdd(_aCampos, {'PARCELA'			,.T.,'C',TAMSX3('E5_PARCELA')[1]	,'E5_PARCELA'	,NIL})
			aAdd(_aCampos, {'TIPO'				,.T.,'C',TAMSX3('E5_TIPO')[1]		,'E5_TIPO'		,NIL})
			aAdd(_aCampos, {'DATA'				,.T.,'D',TAMSX3('E5_DATA')[1]		,'E5_DATA'		,NIL})
			aAdd(_aCampos, {'VALOR'				,.T.,'N',TAMSX3('E5_VALOR')[1]		,'E5_VALOR'		,NIL})
			aAdd(_aCampos, {'RECPAG'			,.F.,'C',TAMSX3('E5_RECPAG')[1]		,'E5_RECPAG'	,NIL})
			aAdd(_aCampos, {'CANCELADO'			,.F.,'C',TAMSX3('E5_SITUACA')[1]	,'E5_SITUACA'	,NIL})
			aAdd(_aCampos, {'MOTIVO'			,.F.,'C',TAMSX3('E5_MOTBX')[1]		,'E5_MOTBX'		,NIL})
			aAdd(_aCampos, {'HISTORICO'			,.F.,'C',TAMSX3('E5_HISTOR')[1]		,'E5_HISTOR'		,NIL})
			aAdd(_aCampos, {'SEQUENCIA'			,.F.,'C',TAMSX3('E5_SEQ')[1]		,'E5_SEQ'		,NIL})
//			aAdd(_aCampos, {'MOTIVO'			,.T.,'N',TAMSX3('E5_MOTBX')[1]		,'E5_MOTBX'		,NIL})
		
		ElseIf(_cTabela = 'SF1')
		
		ElseIf(_cTabela = 'SD1')
		
		ElseIf(_cTabela = 'SF2')
			aAdd(_aCampos, {'NUMERO'			,.T.,'C',TAMSX3('F2_DOC')[1]	,'F2_DOC'		,NIL})
			aAdd(_aCampos, {'SERIE'				,.T.,'C',TAMSX3('F2_SERIE')[1]	,'F2_SERIE'		,NIL})
			aAdd(_aCampos, {'CODIGO'			,.T.,'C',TAMSX3('F2_CLIENTE')[1],'F2_CLIENTE'	,NIL})
			aAdd(_aCampos, {'LOJA'				,.T.,'C',TAMSX3('F2_LOJA')[1]	,'F2_LOJA'		,NIL})
			aAdd(_aCampos, {'COND_PAGAMENTO'	,.F.,'C',TAMSX3('F2_COND')[1]	,'F2_COND'		,NIL})
			aAdd(_aCampos, {'DUPLICATA'			,.F.,'C',TAMSX3('F2_DUPL')[1]	,'F2_DUPL'		,NIL})
			aAdd(_aCampos, {'EMISSAO'			,.T.,'D',TAMSX3('F2_EMISSAO')[1],'F2_EMISSAO'	,NIL})
			aAdd(_aCampos, {'ESTADO'			,.T.,'C',TAMSX3('F2_EST')[1]	,'F2_EST'		,NIL})
			aAdd(_aCampos, {'VALOR_FRETE'		,.F.,'N',TAMSX3('F2_FRETE')[1]	,'F2_FRETE'		,NIL})
			aAdd(_aCampos, {'CALOR_SEGURO'		,.F.,'N',TAMSX3('F2_SEGURO')[1]	,'F2_SEGURO'	,NIL})
			aAdd(_aCampos, {'TIPO_CLIENTE'		,.F.,'C',TAMSX3('F2_TIPOCLI')[1],'F2_TIPOCLI'	,NIL})
			aAdd(_aCampos, {'VALOR_BRUTO'		,.F.,'N',TAMSX3('F2_VALBRUT')[1],'F2_VALBRUT'	,NIL})
			aAdd(_aCampos, {'ICMS_BASE'			,.F.,'N',TAMSX3('F2_BASEICM')[1],'F2_BASEICM'	,NIL})
			aAdd(_aCampos, {'ICMS_VALOR'		,.F.,'N',TAMSX3('F2_VALICM')[1]	,'F2_VALICM'	,NIL})
			aAdd(_aCampos, {'IPI_BASE'			,.F.,'N',TAMSX3('F2_BASEIPI')[1],'F2_BASEIPI'	,NIL})
			aAdd(_aCampos, {'IPI_VALOR'			,.F.,'N',TAMSX3('F2_VALIPI')[1]	,'F2_VALIPI'	,NIL})
			aAdd(_aCampos, {'TIPO_NOTA'			,.F.,'C',TAMSX3('F2_TIPO')[1]	,'F2_TIPO'		,NIL})
			aAdd(_aCampos, {'CHAVE_NFE'			,.F.,'C',TAMSX3('F2_CHVNFE')[1]	,'F2_CHVNFE'	,NIL})
		ElseIf(_cTabela = 'SD2')
			aAdd(_aCampos, {'ITEM'			,.T.,'C',TAMSX3('D2_ITEM')[1]	,'D2_ITEM'		,NIL})
			aAdd(_aCampos, {'PRODUTO'		,.T.,'C',TAMSX3('D2_COD')[1]	,'D2_COD'		,NIL})
			aAdd(_aCampos, {'UNIDADE_MEDIDA',.T.,'C',TAMSX3('D2_UM')[1]		,'D2_UM'		,NIL})
			aAdd(_aCampos, {'QUANTIDADE'	,.T.,'N',TAMSX3('D2_QUANT')[1]	,'D2_QUANT'		,NIL})
			aAdd(_aCampos, {'PRECO_VENDA'	,.T.,'N',TAMSX3('D2_PRCVEN')[1]	,'D2_PRCVEN'	,NIL})
			aAdd(_aCampos, {'TOTAL'			,.T.,'N',TAMSX3('D2_TOTAL')[1]	,'D2_TOTAL'		,NIL})
			aAdd(_aCampos, {'TES'			,.T.,'C',TAMSX3('D2_TES')[1]	,'D2_TES'		,NIL})
			aAdd(_aCampos, {'CF'			,.T.,'C',TAMSX3('D2_CF')[1]		,'D2_CF'		,NIL})
			aAdd(_aCampos, {'ARMAZEM'		,.T.,'C',TAMSX3('D2_LOCAL')[1]	,'D2_LOCAL'		,NIL})
			aAdd(_aCampos, {'CLASSIFICACAO'	,.T.,'C',TAMSX3('D2_CLASFIS')[1],'D2_CLASFIS'	,NIL})	
			aAdd(_aCampos, {'PEDIDO'		,.T.,'C',TAMSX3('D2_PEDIDO')[1]	,'D2_PEDIDO'	,NIL})
			aAdd(_aCampos, {'PEDIDO_ITEM'	,.T.,'C',TAMSX3('D2_ITEMPV')[1]	,'D2_ITEMPV'	,NIL})	
		ElseIf(_cTabela = 'DA0')
			aAdd(_aCampos, {'TABELA'		,.T.,'C',TAMSX3('DA0_CODTAB')[1]	,'DA0_CODTAB'	,NIL})	
			aAdd(_aCampos, {'DESCRICAO'		,.T.,'C',TAMSX3('DA0_DESCRI')[1]	,'DA0_DESCRI'	,NIL})	
			aAdd(_aCampos, {'ATIVO'			,.T.,'C',TAMSX3('DA0_ATIVO' )[1]	,'DA0_ATIVO'	,NIL})	
			aAdd(_aCampos, {'DATA_INI'		,.T.,'C',TAMSX3('DA0_DATDE' )[1]	,'DA0_DATDE'	,NIL})	
			aAdd(_aCampos, {'DATA_FIM'		,.T.,'C',TAMSX3('DA0_DATATE')[1]	,'DA0_DATATE'	,NIL})	
			aAdd(_aCampos, {'HORA_INI'		,.T.,'C',TAMSX3('DA0_HORADE' )[1]	,'DA0_HORADE'	,NIL})	
			aAdd(_aCampos, {'HORA_FIM'		,.T.,'C',TAMSX3('DA0_HORATE')[1]	,'DA0_HORATE'	,NIL})	
		ElseIf(_cTabela = 'DA1')
			aAdd(_aCampos, {'TABELA'		,.T.,'C',TAMSX3('DA1_CODTAB')[1]	,'DA1_CODTAB'	,NIL})	
			aAdd(_aCampos, {'ITEM'			,.T.,'C',TAMSX3('DA1_ITEM'  )[1]	,'DA1_ITEM'		,NIL})	
			aAdd(_aCampos, {'PRODUTO'		,.T.,'C',TAMSX3('DA1_CODPRO')[1]	,'DA1_CODPRO'	,NIL})	
			aAdd(_aCampos, {'PRECO'			,.T.,'N',TAMSX3('DA1_PRCVEN')[1]	,'DA1_PRCVEN'	,NIL})	
			aAdd(_aCampos, {'ATIVO'			,.T.,'N',TAMSX3('DA1_ATIVO' )[1]	,'DA1_ATIVO'	,NIL})	
		ElseIf(_cTabela = 'RES_FIN_REC')
			aAdd(_aCampos, {'ATRASADOS'		,.T.,'N',TAMSX3('E1_VALOR')[1]	,'ATRASADOS'	,NIL})	
			aAdd(_aCampos, {'FUTUROS'		,.T.,'N',TAMSX3('E1_VALOR'  )[1],'FUTUROS'		,NIL})	
			aAdd(_aCampos, {'ABERTOS'		,.T.,'N',TAMSX3('E1_VALOR'  )[1],'ABERTOS'		,NIL})	
		Else
		
		EndIf
		
		
		//busca descrição dos campos
		SX3->(DBSETORDER(2))
		For _nJ := 1 to Len(_aCampos)
			CONOUT(_nJ)
			SX3->(DBGOTOP())
			If(SX3->(dbSeek(padr(_aCampos[_nJ][5],10))))
				If(Empty(_aCampos[_nJ][6]) .AND. !EMPTY(SX3->X3_CBOX))
					_aCampos[_nJ][6] := AllTrim(SX3->X3_CBOX)
				EndIf
				
				If(Len(_aCampos[_nJ])=6)
					aAdd(_aCampos[_nJ],AllTrim(SX3->X3_DESCRIC))
				ElseIF(Len(_aCampos[_nJ])>=7)
					_aCampos[_nJ][7] := AllTrim(NOACENTO(SX3->X3_DESCRIC))
				EndIf
			EndIf
		Next
		
	EndIf
	
	If(Upper(_cTipo)= 'COMPLETO')
		_aPadrao := U_WSCAMPOS('',_cTabela,_lInclui)
		SX3->(DBSETORDER(1))
		SX3->(DBSEEK(_cTabela))
		While(!SX3->(Eof()) .AND. SX3->X3_ARQUIVO=_cTabela)
			If(X3USO(SX3->X3_USADO) .AND. SX3->X3_CONTEXT!='V')
				_nPos := aScan(_aPadrao,{|x| x[5] == AllTrim(SX3->X3_CAMPO) })
				If(_nPos)
					aAdd(_aCampos, {_aPadrao[_nPos,1],;
									_aPadrao[_nPos,2],;
									SX3->X3_TIPO,,;
									TAMSX3(ALLTRIM(SX3->X3_CAMPO))[1],;
									AllTrim(SX3->X3_CAMPO),;
									IIF(!EMPTY(_aPadrao[_nPos,6]),_aPadrao[_nPos,6],AllTrim(SX3->X3_CBOX)),;
									alltrim(NOACENTO(SX3->X3_DESCRIC))})

				Else
					aAdd(_aCampos, {AllTrim(SUBSTR(SX3->X3_CAMPO,4)),;
									X3OBRIGAT(SX3->X3_CAMPO),;
									SX3->X3_TIPO,;
									TAMSX3(ALLTRIM(SX3->X3_CAMPO))[1],;
									AllTrim(SX3->X3_CAMPO),;
									AllTrim(SX3->X3_CBOX),;
									AllTrim(NOACENTO(SX3->X3_DESCRIC))})
				EndIf
			EndIf
	
			SX3->(DBSKIP())
		EndDo
	ElseIf(Upper(_cTipo)= 'OBRIGATORIO')
		_aPadrao := U_WSCAMPOS('',_cTabela,_lInclui)
		SX3->(DBSETORDER(1))
		SX3->(DBGOTOP())
		SX3->(DBSEEK(_cTabela))
		While(!SX3->(EOF()) .AND. SX3->X3_ARQUIVO=_cTabela)
			If(X3USO(SX3->X3_USADO) .AND. SX3->X3_CONTEXT!='V' .AND. X3OBRIGAT(SX3->X3_CAMPO))
				_nPos := aScan(_aPadrao,{|x| x[5] == AllTrim(SX3->X3_CAMPO) })
				If(_nPos)
					aAdd(_aCampos, {_aPadrao[_nPos,1],;
									_aPadrao[_nPos,2],;
									SX3->X3_TIPO,;
									TAMSX3(SX3->X3_CAMPO)[1],;
									AllTrim(SX3->X3_CAMPO),;
									IIF(!EMPTY(_aPadrao[_nPos,6]),_aPadrao[_nPos,6],AllTrim(SX3->X3_CBOX)),;
									alltrim(SX3->X3_DESCRIC)})
				Else
					aAdd(_aCampos, {AllTrim(SUBSTR(SX3->X3_CAMPO,4)),;
									X3OBRIGAT(SX3->X3_CAMPO),;
									SX3->X3_TIPO,;
									TAMSX3(SX3->X3_CAMPO)[1],;
									AllTrim(SX3->X3_CAMPO),;
									AllTrim(SX3->X3_CBOX),;
									AllTrim(NOACENTO(SX3->X3_DESCRIC))})
				EndIf
						
			EndIf
		
			SX3->(DBSKIP())
		EndDo
	Endif	

Return _aCampos
