#Include "RwMake.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Funcoes Genericas utilizadas no modulo Financeiro       !
!                  ! 1. Retorna o saldo de titulos (utilizado em CNAB)       !
!                  ! 2. Retorna informações da Filial passada por parametro  !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 05/2012                                                 !
+------------------+--------------------------------------------------------*/

// 1. funcao que retorna o saldo de titulos (utilizado em CNAB)
User Function FtSldTit(mvCart)

	// calculo o saldo do tituto
	local _nSldTit := SaldoTit(	SE1->E1_PREFIXO, ;
	SE1->E1_NUM, ;
	SE1->E1_PARCELA, ;
	SE1->E1_TIPO, ;
	SE1->E1_NATUREZ, ;
	"R", ;
	SE1->E1_CLIENTE, ;
	1, ;
	SE1->E1_VENCREA,, ;
	SE1->E1_LOJA,, ;
	SE1->E1_TXMOEDA)

Return(_nSldTit)

// 2. funcao que retorna informações da Filial passada por parametro
User Function FtDadFil(mvEmpresa, mvFilial, mvCampo)

	// variavel de retorno
	Local _xRet
	// salvar area do SM0
	Local _aAreaSM0 := SM0->( GetArea() )

	// abrea cadatro de empresas
	dbSelectArea("SM0")
	SM0->( dbSetOrder(1) )

	// posiciona no SM0 para pegar a informação.
	If SM0->( dbSeek(  mvEmpresa + mvFilial) )

		// retorna conteudo do campo
		_xRet := &("SM0->"+Alltrim(mvCampo))

	EndIf

	// restaura a area do SM0
	RestArea(_aAreaSM0)

Return(_xRet)

//3. função para retornar a conta corrente e o digito verificador (DAC) do CNAB (para fins de compatibilidade com cadastros antigos)
//mvTipo 1 = Conta, mvTipo 2 = DAC
User Function FtDvCnab(mvTipo)

	//variavel de retorno
	Local _cRet :=  ""

	If(mvTipo = 1)			//retorna a conta
		_cRet := IIF(EMPTY(SEE->EE_DVCTA), SUBSTR(SEE->EE_CONTA,5,5), SUBSTR(SEE->EE_CONTA,6,5))
	ElseIf (mvTipo = 2)		//retorna o DAC
		_cRet := IIF(EMPTY(SEE->EE_DVCTA), SUBSTR(SEE->EE_CONTA,10,1), SEE->EE_DVCTA)
	Else					//qualquer outro tipo
		_cRet := "0"
	EndIf

Return( _cRet )


//4. função que retorna o número do documento para gerar o arquivo CNAB do banco
//retorna a nota fiscal eletronica se houver, caso contrario, encaminha o titulo do financeiro (ex: fatura de locação)
User Function FTTICNAB()

	//variavel de retorno
	Local _cRet :=  ""

	If ! Empty(SE1->E1_NFELETR)			//se a NF eletronica estiver preenchida, usa
		// valida tamanho do conteudo do campo numero da nota (depende do retorno do XML da prefeitura)
		If (Len(AllTrim(SE1->E1_NFELETR)) == 15)
			_cRet := SubStr(SE1->E1_NFELETR , 6 , 11)
		Else
			_cRet := StrZero( Val(SE1->E1_NFELETR), 10)
		EndIf
	Else								//caso contrario, usa numero do titulo no financeiro
		_cRet := StrZero( Val(SE1->E1_NUM) ,10)
	Endif

Return( _cRet )

// ** funcao que prepara a composicao dos dados para pagamentos de impostos (SISPAG ITAU)
User Function FtCnbImp(mvTipoPag, mvModelo, mvCodBarras)
	// variavel de retorno
	local _cRet := ""

	//codigo da receita
	local _cCodReceita := "2100"

	// nome do contribuinte
	local _cNomeCont := SM0->M0_NOMECOM

	// CNPJ do contribuinte
	local _cCNPJCont := SM0->M0_CGC

	// layout conforme parametros

	// DARF
	If (mvTipoPag == "22").and.(mvModelo $ "16|91")
		//Para DARF, substitui o código da receita pelo campo customizado do título
		_cCodReceita := SE2->E2_ZCODREC

		//padroniza a variavel (caracteres e zeros)
		U_FtStrZero(Len(SE2->E2_ZCODREC), @_cCodReceita)

		// IDENTIFICAÇÃO DO TRIBUTO - 018 019
		_cRet := "02" // 02=DARF
		// CÓDIGO DA RECEITA - 020 023
		_cRet += _cCodReceita
		// TIPO DE INSCRIÇÃO DO CONTRIBUINTE - 024 024 (1=CPF, 2=CNPJ)
		_cRet += "2"
		// IDENTIFICAÇÃO CNPJ/CEI/NIT/PIS DO CONTRIBUINTE - 025 038
		_cRet += PadR(SM0->M0_CGC, 14)
		// PERÍODO DE APURAÇÃO - 039 046 (DDMMAAAA)
		_cRet += GravaData((FirstDay(SE2->E2_VENCREA) - 1), .F., 5)
		// BRANCOS - NÚMERO DE REFERÊNCIA 047 063
		_cRet += Space(17)
		// VALOR PRINCIPAL - 064 077
		_cRet += StrZero((SE2->E2_SALDO * 100), 14)
		// VALOR DA MULTA - 078 091
		_cRet += StrZero((SE2->E2_MULTA * 100), 14)
		// VALOR DOS JUROS/ENCARGOS - 092 105
		_cRet += StrZero((SE2->E2_VALJUR * 100), 14)
		// VALOR TOTAL A SER PAGO - 106 119
		_cRet += StrZero((SE2->(E2_SALDO + E2_MULTA + E2_VALJUR) * 100), 14)
		// DATA DE VENCIMENTO - 120 127
		_cRet += GravaData(SE2->E2_VENCREA,.F.,5)
		// DATA DO PAGAMENTO - 128 135
		_cRet += GravaData(SE2->E2_VENCREA,.F.,5)
		// BRANCOS - COMPLEMENTO DE REGISTRO - 136 165
		_cRet += Space(30)
		// NOME DO CONTRIBUINTE - 166 195
		_cRet += PadR(_cNomeCont, 30)

		// GPS
	ElseIf (mvTipoPag == "22").and.(mvModelo == "17")

		// verifica se foi informado codigo de pagamento no titulo
		If ( ! Empty(SE2->E2_ZCODREC) )
			// uso o codigo de pgto do título
			_cCodReceita := SE2->E2_ZCODREC

			//padroniza a variavel (caracteres e zeros)
			U_FtStrZero(Len(SE2->E2_ZCODREC), @_cCodReceita)
		Else
			Alert("Borderô GPS! Título " + SE2->E2_NUM + " não possui codigo de recolhimento informado. Estou assumindo como código 2100 - Empresas em geral (CNPJ)")
			_cCodReceita := "2100"
		EndIf

		// se for codigo de retencao de impostos do fornecedor, muda o nome do contribuinte
		If (_cCodReceita == "2631")
			_cNomeCont := sfRetNomCont(SE2->E2_TITPAI)
			_cCNPJCont := sfRetCNPJ(SE2->E2_TITPAI)
		EndIf

		// IDENTIFICAÇÃO DO TRIBUTO - 018 019
		_cRet := "01" // 01=GPS
		// CÓDIGO DA RECEITA - 020 023
		_cRet += _cCodReceita
		// MÊS E ANO DA COMPETÊNCIA - 024 029 (MMAAAA)
		_cRet += SubStr(GravaData((FirstDay(SE2->E2_VENCREA) - 1), .F., 5), 3, 6)
		// IDENTIFICAÇÃO CNPJ/CEI/NIT/PIS DO CONTRIBUINTE - 030 043
		_cRet += PadR(_cCNPJCont, 14)
		// VALOR PREVISTO DO PAGAMENTO DO INSS - 044 057
		_cRet += StrZero((SE2->E2_SALDO * 100), 14)
		// VALOR DE OUTRAS ENTIDADES - 058 071
		_cRet += StrZero((SE2->E2_SDACRES * 100), 14)
		// ATUALIZAÇÃO MONETÁRIA - 072 085
		_cRet += StrZero(((SE2->E2_MULTA + SE2->E2_JUROS) * 100), 14)
		// VALOR ARRECADADO - 086 099
		_cRet += StrZero((((SE2->E2_VALOR + SE2->E2_MULTA + SE2->E2_JUROS + SE2->E2_SDACRES )-(SE2->E2_DESCONT + SE2->E2_SDDECRE)) * 100), 14)
		// DATA DA ARRECADAÇÃO/ EFETIVAÇÃO DO PAGAMENTO - 100 107
		_cRet += GravaData(SE2->E2_VENCREA,.F.,5)
		// BRANCOS - COMPLEMENTO DE REGISTRO - 108 115
		_cRet += Space(8)
		// BRANCOS - INFORMAÇÕES COMPLEMENTARES - 116 165
		_cRet += Space(50)
		// NOME DO CONTRIBUINTE - 166 195
		_cRet += PadR(_cNomeCont, 30)


	ElseIf (mvTipoPag == "22").and.(mvModelo == "35") 			// FGTS- GRF/GRRF/GRDE
		// IDENTIFICAÇÃO DO TRIBUTO - 018 019
		_cRet := "11" // 11=FGTS-GFIP
		// CÓDIGO DA RECEITA - 020 023
		_cRet += _cCodReceita
		// TIPO DE INSCRIÇÃO DO CONTRIBUINTE - 024 024 (1 = CNPJ / 2 = CEI)
		_cRet += "1"
		// CPF OU CNPJ DO CONTRIBUINTE - 025 038
		_cRet += PadR(SM0->M0_CGC, 14)
		// CODIGO DE BARRAS - 039 086
		_cRet += PadR(AllTrim(mvCodBarras),48)
		// IDENTIFICADOR DO FGTS - 087 102
		_cRet += Space(16)
		// LACRE DE CONECTIVIDADE SOCIAL - 103 111
		_cRet += Space(9)
		// DIGITO DO LACRE DE CONECTIVIDADE SOC. - 112 113
		_cRet += Space(2)
		// NOME DO CONTRIBUINTE - 114 143
		_cRet += PadR(_cNomeCont, 30)
		// DATA DO PAGAMENTO - 144 151 DDMMAAAA
		_cRet += GravaData(SE2->E2_VENCREA,.F.,5)
		// VALOR DO PAGAMENTO - 152 165
		_cRet += StrZero((SE2->E2_SALDO * 100), 14)
		// BRANCOS - COMPLEMENTO DE REGISTRO - 166 195
		_cRet += Space(30)
	EndIf

Return(_cRet)

// ** funcao que retorna o nome do fornecedor do titulo principal
Static Function sfRetNomCont(mvChaTitPai)
	// variavel de retorno
	local _cRetNome := ""
	// area inicial
	Local _aAreaSE2 := SE2->( GetArea() )

	// posiciona no titulo principal
	dbSelectArea("SE2")
	SE2->(dbSetOrder(1)) // 1-E2_FILIAL, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_FORNECE, E2_LOJA
	If SE2->(dbSeek( xFilial("SE2") + mvChaTitPai ))
		//retorna a razão social do cadastro de fornecedor
		_cRetNome := Posicione("SA2", 1, xFilial("SA2") + SE2->E2_FORNECE + SE2->E2_LOJA, "A2_NOME")
	EndIf

	// restaura area inicial
	RestArea(_aAreaSE2)

Return(_cRetNome)


// ** funcao que retorna o CNPJ do fornecedor do titulo principal
Static Function sfRetCNPJ(mvChaTitPai)
	// variavel de retorno
	local _cRetCNPJ := ""

	// salva areas
	Local _aAreaSE2 := SE2->( GetArea() )
	Local _aAreaSA2 := SA2->( GetArea() )

	// posiciona no titulo principal
	dbSelectArea("SE2")
	SE2->(dbSetOrder(1)) // 1-E2_FILIAL, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_FORNECE, E2_LOJA
	If SE2->(dbSeek( xFilial("SE2") + mvChaTitPai ))
		//retorna o CNPJ do cadastro de fornecedor
		_cRetCNPJ := Posicione("SA2", 1, xFilial("SA2") + SE2->E2_FORNECE + SE2->E2_LOJA, "A2_CGC")
	EndIf

	// restaura areas
	RestArea(_aAreaSE2)
	RestArea(_aAreaSA2)

Return(_cRetCNPJ)

// ** funcao que gera o código de barras a partir da linha digitável, utilizado através de gatilho
User Function FtFinBar(mvLinDig)

	// variavel de retorno
	local _cRetCodBar := ""

	// variaveis temporarias
	local _cSubVal := ""
	local _cValor := ""

	// remome espacos
	mvLinDig := AllTrim(mvLinDig)

	// valida tipo do codigo
	If ( ! Empty(mvLinDig) ) .And. (Len(mvLinDig)<>47)
		mvLinDig := mvLinDig + Repli('0', 47-LEN(mvLinDig))
	EndIf

	// se tiver conteudo, converte pra codigo de barras
	If ( ! Empty(mvLinDig) )
		// extrai informacoes
		_cSubVal := AllTrim(SubStr(mvLinDig,34,14))
		_cValor  := Strzero(Val(_cSubVal),14)

		// prepara variavel de retorno
		_cRetCodBar := AllTrim(SubStr(mvLinDig, 1, 3)) //Banco
		_cRetCodBar += AllTrim(SubStr(mvLinDig, 4, 1)) // Moeda
		_cRetCodBar += AllTrim(SubStr(mvLinDig,33, 1)) // Dac
		_cRetCodBar += _cValor                         // Valor
		_cRetCodBar += AllTrim(SubStr(mvLinDig, 5, 5)) // Campo Livre
		_cRetCodBar += AllTrim(SubStr(mvLinDig,11,10)) // Campo Livre
		_cRetCodBar += AllTrim(SubStr(mvLinDig,22,10)) // Campo Livre
	EndIf

Return (_cRetCodBar)

// ** funcao que gera o numero da proximo liquidacao
User Function FtFinLiq()
	// variavel de retorno
	local _cNumLiq := SuperGetMv("TC_NUMLIQ", .f., GetMv("MV_NUMFAT"))
	// variavel temporaria
	local _aTamSE1 := TamSx3("E1_NUM")

	// incrementa o sequencial
	_cNumLiq := Soma1(_cNumLiq, _aTamSE1[1])

	// grava a numeracao
	GetMv("TC_NUMLIQ")
	RecLock("SX6",.F.)
	SX6->X6_CONTEUD := _cNumLiq
	msUnlock()

Return(_cNumLiq)
