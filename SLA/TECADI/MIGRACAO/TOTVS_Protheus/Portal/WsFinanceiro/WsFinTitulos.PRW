#Include "APWEBSRV.CH"
#Include "PROTHEUS.CH"

// criacao do Web Service
WSSERVICE WsFinTitulos DESCRIPTION "Web Service Fin Relação de Títulos"

	// variaveis de envio
	WSDATA RecUsrPortal       AS String
	WSDATA RecIdSessionPortal AS String
	WSDATA RecCodFilial       AS String
	WSDATA RecCodCli          AS String
	WSDATA RecLojCli          AS String
	WSDATA RecDataEmissaoDe   AS Date
	WSDATA RecDataEmissaoAte  AS Date
	WSDATA RecDataVenctoDe    AS Date
	WSDATA RecDataVenctoAte   AS Date
	WSDATA RecSituacaoTitulo  AS String
	
	// variaveis de retorno
	WSDATA RetTituloReceber     AS ARRAY OF StListaTituloReceber
	
	// declaracao dos metodos
	WSMETHOD FinListaTituloReceber         DESCRIPTION "Listar titulos a receber por Cliente"

ENDWSSERVICE

// criacao do metodo
WSMETHOD FinListaTituloReceber WSRECEIVE RecUsrPortal, RecIdSessionPortal, RecCodFilial, RecCodCli, RecLojCli, RecDataEmissaoDe, RecDataEmissaoAte, RecDataVenctoDe, RecDataVenctoAte, RecSituacaoTitulo WSSEND RetTituloReceber WSSERVICE WsFinTitulos

Local _cQuery
local _aDados
local _nDados
local _nItem

local _oWsLogin := WSWSCFGLOGIN():New()

// valores padroes
Default ::RecDataEmissaoDe  := CtoD("01/01/2000")
Default ::RecDataEmissaoAte := Date()
Default ::RecDataVenctoDe   := CtoD("01/01/2000")
Default ::RecDataVenctoAte  := Date() + 60
Default ::RecSituacaoTitulo := "A" // A-Em Aberto

// valida tipos de variaveis
If ValType(::RecUsrPortal) != 'C'      ; setSoapFault("TITULOS A RECEBER","Formato do parâmetro RecUsrPortal inválido (expected C)")      ; Return .F.; EndIf
If ValType(::RecIdSessionPortal) != 'C'; setSoapFault("TITULOS A RECEBER","Formato do parâmetro RecIdSessionPortal inválido (expected C)"); Return .F.; EndIf
If ValType(::RecCodFilial) != 'C'      ; setSoapFault("TITULOS A RECEBER","Formato do parâmetro RecCodFilial inválido (expected C)")      ; Return .F.; EndIf
If ValType(::RecCodCli) != 'C'         ; setSoapFault("TITULOS A RECEBER","Formato do parâmetro RecCodCli inválido (expected C)")         ; Return .F.; EndIf
If ValType(::RecLojCli) != 'C'         ; setSoapFault("TITULOS A RECEBER","Formato do parâmetro RecLojCli inválido (expected C)")         ; Return .F.; EndIf
If ValType(::RecDataEmissaoDe) != 'D'  ; setSoapFault("TITULOS A RECEBER","Formato do parâmetro RecDataEmissaoDe inválido (expected D)")  ; Return .F.; EndIf
If ValType(::RecDataEmissaoAte) != 'D' ; setSoapFault("TITULOS A RECEBER","Formato do parâmetro RecDataEmissaoAte inválido (expected D)") ; Return .F.; EndIf
If ValType(::RecDataVenctoDe) != 'D'   ; setSoapFault("TITULOS A RECEBER","Formato do parâmetro RecDataVenctoDe inválido (expected D)")   ; Return .F.; EndIf
If ValType(::RecDataVenctoAte) != 'D'  ; setSoapFault("TITULOS A RECEBER","Formato do parâmetro RecDataVenctoAte inválido (expected D)")  ; Return .F.; EndIf
If ValType(::RecSituacaoTitulo) != 'C' ; setSoapFault("TITULOS A RECEBER","Formato do parâmetro RecSituacaoTitulo inválido (expected C)") ; Return .F.; EndIf

// valores padroes		
::RecDataEmissaoDe  := IIf(Empty(::RecDataEmissaoDe) , CtoD("01/01/2000"), ::RecDataEmissaoDe )
::RecDataEmissaoAte := IIf(Empty(::RecDataEmissaoAte), Date()            , ::RecDataEmissaoAte)
::RecDataVenctoDe   := IIf(Empty(::RecDataVenctoDe)  , CtoD("01/01/2000"), ::RecDataVenctoDe  )
::RecDataVenctoAte  := IIf(Empty(::RecDataVenctoAte) , Date() + 60       , ::RecDataVenctoAte )
::RecSituacaoTitulo := IIf(Empty(::RecSituacaoTitulo), "A"               , ::RecSituacaoTitulo)

// valida session
If ! _oWsLogin:CFGVALIDSESSION(::RecUsrPortal, ::RecIdSessionPortal)
	setSoapFault("TITULOS A RECEBER","Sessão inválida ou Sessão Expirou!")
	Return(.f.)
EndIf

// obrigatorio informar o codigo da filial
If Empty(::RecCodFilial)
	setSoapFault("TITULOS A RECEBER","Campo filial é obrigatório.")
	Return(.f.)
EndIf

// obrigatorio informar o codigo do cliente
If (Empty(::RecCodCli)).or.(Empty(::RecLojCli))
	setSoapFault("TITULOS A RECEBER","Campos código e loja do cliente são obrigatórios.")
	Return(.f.)
EndIf

// padroniza conteudo
::RecSituacaoTitulo := AllTrim(Upper(::RecSituacaoTitulo))

// valida opcoes
If ( ! ::RecSituacaoTitulo $ "A\P\T")
	setSoapFault("TITULOS A RECEBER","Situação do título inválida.")
	Return(.f.)
EndIf


// valida se os dados estao corretos para o login
If ( ! U_FtPrtLgn(::RecUsrPortal, ::RecCodCli, ::RecLojCli, Nil, Nil))
	setSoapFault("TITULOS A RECEBER","Dados não permitidos para o login informado.")
	Return(.f.)
EndIf


// monta a query para filtra os titulos do cliente
_cQuery := "SELECT E1_FILIAL, E1_PREFIXO, E1_NUM, E1_VALOR, E1_EMISSAO, E1_VENCREA, E1_SALDO, E1_BAIXA "
// _cQuery += "E1_PORTADO,E1_HIST,E1_PORCJUR,E1_TIPO,E1_PARCELA,"                                
_cQuery += "FROM "+RetSqlName("SE1")+" SE1 "
_cQuery += "WHERE "
_cQuery += "SE1.E1_FILIAL   = '"+::RecCodFilial+"' AND "
_cQuery += "SE1.E1_CLIENTE  = '"+::RecCodCli+"' AND "
_cQuery += "SE1.E1_LOJA     = '"+::RecLojCli+"' AND "
// trata data de emissao
If ( ! Empty(::RecDataEmissaoDe)).and.( ! Empty(::RecDataEmissaoAte))
	_cQuery += "SE1.E1_EMISSAO BETWEEN '"+DtoS(::RecDataEmissaoDe)+"' AND '"+DtoS(::RecDataEmissaoAte)+"' AND "
EndIf
// trata data de vencimento
If ( ! Empty(::RecDataVenctoDe)).and.( ! Empty(::RecDataVenctoAte))
	_cQuery += "SE1.E1_VENCREA BETWEEN '"+DtoS(::RecDataVenctoDe)+"'  AND '"+DtoS(::RecDataVenctoAte)+"' AND "
EndIf
// trata situacao do titulo
If (::RecSituacaoTitulo == "A")
	_cQuery += "SE1.E1_SALDO > 0 AND "
ElseIf (::RecSituacaoTitulo == "P")
	_cQuery += "SE1.E1_SALDO = 0 AND "
EndIf
// filtra tipos de titulos
_cQuery += "SE1.E1_TIPO NOT IN "+FormatIn(MV_CRNEG+"/"+MVRECANT+"/"+MVABATIM,"/")+" AND "
_cQuery += "SE1.D_E_L_E_T_ = ' ' "
// ordem dos dados
_cQuery += "ORDER BY E1_FILIAL, E1_PREFIXO, E1_NUM "

// atualiza os dados no vetor
_aDados := U_SqlToVet(_cQuery,{"E1_EMISSAO","E1_VENCREA","E1_BAIXA"})

If (Len(_aDados) == 0)
	setSoapFault("TITULOS A RECEBER","Não há dados com esses parâmetros")
	Return(.f.)
EndIf

// prepara a estrutura com o retorno dos dados	
For _nDados := 1 to Len(_aDados)

	aAdd(::RetTituloReceber,WSClassNew("StListaTituloReceber"))
	_nItem := Len(::RetTituloReceber)

	::RetTituloReceber[_nItem]:cTitFilial  := _aDados[_nDados][1]
	::RetTituloReceber[_nItem]:cTitPrefixo := _aDados[_nDados][2]
	::RetTituloReceber[_nItem]:cTitNumRps  := _aDados[_nDados][3]
	::RetTituloReceber[_nItem]:nTitValor   := _aDados[_nDados][4]
	::RetTituloReceber[_nItem]:dTitEmissao := _aDados[_nDados][5]
	::RetTituloReceber[_nItem]:dTitVencto  := _aDados[_nDados][6]
	::RetTituloReceber[_nItem]:nTitSaldo   := _aDados[_nDados][7]
	If ( ! Empty(_aDados[_nDados][8]))
		::RetTituloReceber[_nItem]:dTitBaixa := _aDados[_nDados][8]
	EndIf
	
Next _nDados
	
// retorno TRUE deu certo / FALSE deu errado	
Return(.t.)

// estrutura retorno dos titulos a receber
WSSTRUCT StListaTituloReceber
	WSDATA cTitFilial  As String
	WSDATA cTitPrefixo As String
	WSDATA cTitNumRps  As String
	WSDATA nTitValor   As float
	WSDATA dTitEmissao As Date
	WSDATA dTitVencto  As Date
	WSDATA nTitSaldo   As float
	WSDATA dTitBaixa   As Date   Optional
ENDWSSTRUCT