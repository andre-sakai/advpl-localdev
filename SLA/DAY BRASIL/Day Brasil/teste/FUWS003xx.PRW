#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"

// ##############################################################################
// Projeto  : MADEIRANIT
// Autor    : ANDRE SAKAI
// Modulo   : WS
// Função   : FUWS001 - FUNCOES GENERICAS 
// Descrição: FUNCOES GENERICAS PARA LISTAGEM DE CAMPOS PARA OS WS
// Retorno  : CAMPOS UTILIZADOS PELO PROTHEUS
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 20/07/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------


User Function WS3CAMPOS(_cTipo,_cTabela,_lInclui)

	Local 	_aCampos 	:= {}
	Local 	_aPadrao	:= {}
	Local 	_nPos		:= 0, _nJ := 0
	
	Default _cTipo 		:= ''
	Default _cTabela 	:= ''
	
	Default _cInclui := .f.
	
	_aCampos := {}
	
	If(Empty(_cTipo))	
			
		If((_cTabela = 'SA1'))

			aAdd(_aCampos, {'FILIAL'	,.F.,'C',TAMSX3('A1_FILIAL')[1]	,'A1_FILIAL', NIL})
			aAdd(_aCampos, {'CODIGO'	,.F.,'C',TAMSX3('A1_COD')[1]	,'A1_COD', NIL})
			aAdd(_aCampos, {'LOJA'		,.F.,'C',TAMSX3('A1_LOJA')[1]	,'A1_LOJA', NIL})
			aAdd(_aCampos, {'VENCLC'	,.F.,'D',TAMSX3('A1_VENCLC')[1]	,'A1_VENCLC', NIL})
			aAdd(_aCampos, {'LIMITE'	,.F.,'N',TAMSX3('A1_LC')[1]		,'A1_LC', NIL})


		ElseIf(_cTabela = 'SC5')

			aAdd(_aCampos, {'FILIAL'	,.T.,'C',TAMSX3('C5_FILIAL')[1]		,'C5_FILIAL'		,NIL})				
			aAdd(_aCampos, {'PEDIDO'	,.T.,'C',TAMSX3('C5_NUM')[1]		,'C5_NUM'		,NIL})				
			aAdd(_aCampos, {'XVLRCRD'	,.T.,'N',TAMSX3('C5_XVLRCRD')[1]	,'C5_XVLRCRD'		,NIL})				
			aAdd(_aCampos, {'XVLRCRD'	,.T.,'N',TAMSX3('C5_XVLRCRD')[1]	,'C5_XVLRCRD'		,NIL})				
			aAdd(_aCampos, {'XDATCRD'	,.F.,'D',TAMSX3('C5_XDATCRD')[1]	,'C5_XDATCRD'		,NIL})		
			aAdd(_aCampos, {'XUSRLIB'	,.F.,'C',TAMSX3('C5_XUSRLIB')[1]	,'C5_XUSRLIB'		,NIL})
			aAdd(_aCampos, {'XHORCRD'	,.F.,'C',TAMSX3('C5_XHORCRD')[1]	,'C5_XHORCRD'		,NIL})
			aAdd(_aCampos, {'XCPGLIB'	,.F.,'C',TAMSX3('C5_XCPGLIB')[1]	,'C5_XCPGLIB'		,NIL})
			aAdd(_aCampos, {'DEPSCRD'	,.T.,'C',TAMSX3('C5_XDEPSCR')[1]	,'C5_XDEPSCR'		,NIL})
			aAdd(_aCampos, {'DEPSMOT'	,.T.,'C',TAMSX3('C5_XDEPSMT')[1]	,'C5_XDEPSMT'		,NIL})
			aAdd(_aCampos, {'INOUT'		,.T.,'L',TAMSX3('C5_XINOUT')[1]		,'C5_XINOUT'		,NIL})

		ElseIf(_cTabela = 'SC6')

			aAdd(_aCampos, {'XVLRCRD'	,.T.,'N',TAMSX3('C5_XVLRCRD')[1]	,'C5_XVLRCRD'		,NIL})				
			aAdd(_aCampos, {'XDATCRD'	,.F.,'D',TAMSX3('C5_XDATCRD')[1]	,'C5_XDATCRD'		,NIL})		
			aAdd(_aCampos, {'XUSRLIB'	,.F.,'C',TAMSX3('C5_XUSRLIB')[1]	,'C5_XUSRLIB'		,NIL})
			aAdd(_aCampos, {'XHORCRD'	,.F.,'C',TAMSX3('C5_XHORCRD')[1]	,'C5_XHORCRD'		,NIL})
			aAdd(_aCampos, {'XCPGLIB'	,.F.,'C',TAMSX3('C5_XCPGLIB')[1]	,'C5_XCPGLIB'		,NIL})
			aAdd(_aCampos, {'DEPSCRD'	,.T.,'C',TAMSX3('C5_XDEPSCR')[1]	,'C5_XDEPSCR'		,NIL})
			aAdd(_aCampos, {'DEPSMOT'	,.T.,'C',TAMSX3('C5_XDEPSMT')[1]	,'C5_XDEPSMT'		,NIL})
			aAdd(_aCampos, {'INOUT'		,.T.,'L',TAMSX3('C5_XINOUT')[1]		,'C5_XINOUT'		,NIL})

		EndIf
		
		
		//busca descrição dos campos
		SX3->(DBSETORDER(2))
		For _nJ := 1 to Len(_aCampos)
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
									SX3->X3_TIPO,;
									TAMSX3(ALLTRIM(SX3->X3_CAMPO))[1],;
									AllTrim(SX3->X3_CAMPO),;
									IIF(!EMPTY(_aPadrao[_nPos,6]),_aPadrao[_nPos,6],AllTrim(SX3->X3_CBOX)),;
									alltrim(NOACENTO(SX3->X3_DESCRIC))})

				Else
					_nAT1 := 0
					_nAT1 := At( '_', SX3->X3_CAMPO)+1
					aAdd(_aCampos, {AllTrim(SUBSTR(SX3->X3_CAMPO,_nAT1)),;
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
		_aPadrao := U_WS3CAMPOS('',_cTabela,_lInclui)
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
					_nAT1 := 0
					_nAT1 := At( '_', SX3->X3_CAMPO)+1
					aAdd(_aCampos, {AllTrim(SUBSTR(SX3->X3_CAMPO,_nAT1)),;
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
