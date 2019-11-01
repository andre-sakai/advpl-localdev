#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Validacao dos campos do Portal                          !
!                  ! - "Periodos por Cliente"                                !
!                  ! - "Tipos de Estoque"                                    !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 06/2014                                                 !
+------------------+--------------------------------------------------------*/

User Function TPRTA003(mvTelaOpc, mvOpcao)
// conteudo atual do campo
Local _cCntAtual := ""
// opcoes (siglas) disponiveis
Local _cOpcoesDisp := ""
local _aOpcoesDisp := {}

// variavel rotina foi chamada
local _xTmpVariavel
// area atual
local _aAreaAtu := GetArea()

// variavel de retorno
local _lRet := .t.
local _aOpcoesRet := {}

// tipos de periodos
local _aPeriodos  := {{"DIA","DIARIO"},{"QUI","QUINZENAL"},{"MES","MENSAL"}}
// tipos de estoque
local _aTpEstoque := {{"CUB","CUBAGEM"},{"QTD","QUANTIDADE"},{"PBR","PESO BRUTO"},{"PLI","PESO LIQUIDO"}}

// variaveis temporarias
local _nX

// controle de abertura de tela
Static _nVezesExec := 0

// conteudo padrao
Default mvTelaOpc := .t.

// Carrega Nome da Variavel do Get em Questao
_cCntAtual    := &(Alltrim(ReadVar()))
// Iguala Nome da Variavel ao Nome variavel de Retorno
_xTmpVariavel := Alltrim(ReadVar())

// valida abertura da tela
If (mvTelaOpc)
	// para o campo "Periodos"
	If (Alltrim(_xTmpVariavel) == "M->AI3_ZPERIO") .And. (_nVezesExec = Nil .Or. _nVezesExec < 1)
		
		// adiciona os tipos de periodos
		For _nX := 1 to Len(_aPeriodos)
			// vetor de opcoes
			Aadd(_aOpcoesDisp,_aPeriodos[_nX][2])
			// variavel com as opcoes
			_cOpcoesDisp += _aPeriodos[_nX][1]
		Next _nX
		
		// controle de abertura da tela
		_nVezesExec ++
		
		// chama funcao f_Opcoes
		If ( f_Opcoes(@_cCntAtual,"Períodos por Cliente",_aOpcoesDisp,_cOpcoesDisp,Nil,Nil,.f.,3) )
			// Devolve Resultado
			&_xTmpVariavel := _cCntAtual
		EndIF
		_lRet := .F.
		
		// para o campo "Tipo de Estoque"
	ElseIf (Alltrim(_xTmpVariavel) == "M->AI3_ZTPEST") .And. (_nVezesExec = Nil .Or. _nVezesExec < 1)
		
		// adiciona os tipos de estoque
		For _nX := 1 to Len(_aTpEstoque)
			// vetor de opcoes
			Aadd(_aOpcoesDisp,_aTpEstoque[_nX][2])
			// variavel com as opcoes
			_cOpcoesDisp += _aTpEstoque[_nX][1]
		Next _nX
		
		// controle de abertura da tela
		_nVezesExec ++
		
		// chama funcao f_Opcoes
		If ( f_Opcoes(@_cCntAtual,"Tipo de Estoque por Cliente",_aOpcoesDisp,_cOpcoesDisp,Nil,Nil,.f.,3) )
			// Devolve Resultado
			&_xTmpVariavel := _cCntAtual
		EndIF
		_lRet := .F.
		
	Elseif (_nVezesExec >= 1)
		_nVezesExec := 0
		_lRet := .T.
	EndIf
ElseIf ( ! mvTelaOpc)
	// retorna vetor com opcoes
	If (mvOpcao == "PER") // periodos
		_aOpcoesRet := _aPeriodos
	ElseIf (mvOpcao == "EST") // tipos de estoque
		_aOpcoesRet := _aTpEstoque
	EndIf
EndIf

// restaura area anterior
RestArea(_aAreaAtu)

Return( If(mvTelaOpc,_lRet,_aOpcoesRet) )
