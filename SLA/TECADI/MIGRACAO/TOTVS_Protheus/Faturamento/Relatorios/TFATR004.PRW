#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Impressao de Recibo de Locacao 						 !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 05/2014                                                 !
+------------------+--------------------------------------------------------*/

User Function TFATR004
// grupo de perguntas
local _aPerg := {}
local _cPerg := PadR("TFATR004",10)
// query para filtro das notas
local _cQrySF2
// cria alias da query
local _cAliasSF2 := GetNextAlias()
// arquivo gerado
local _cArqHtml

// monta a lista de perguntas
aAdd(_aPerg,{"Série ?"      ,"C",TamSx3("F2_SERIE")[1],0,"G",,""}) //mv_par01
aAdd(_aPerg,{"Fatura De ?"  ,"C",TamSx3("F2_DOC")[1]  ,0,"G",,""}) //mv_par02
aAdd(_aPerg,{"Fatura Até ?" ,"C",TamSx3("F2_DOC")[1]  ,0,"G",,""}) //mv_par03

// cria o grupo de perguntas
U_FtCriaSX1(_cPerg,_aPerg)

// abre os parametros
If ! Pergunte(_cPerg,.T.)
	Return
Endif


// monta a query
_cQrySF2 := "SELECT SF2.R_E_C_N_O_ SF2RECNO "
// notas fiscais de saida
_cQrySF2 += "FROM "+RetSqlName("SF2")+" SF2 "
// filtro padrao
_cQrySF2 += "WHERE "+RetSqlCond("SF2")+" "
_cQrySF2 += "AND F2_SERIE = '"+mv_par01+"' "
_cQrySF2 += "AND F2_DOC   BETWEEN '"+mv_par02+"' AND '"+mv_par03+"' "
// ordem dos dados
_cQrySF2 += "ORDER BY F2_DOC"

// executa a query
DbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQrySF2),(_cAliasSF2),.F.,.F.)
dbSelectArea(_cAliasSF2)

// processa cada registro, incluindo na relacao de notas do lote
While (_cAliasSF2)->(!Eof())

	// posiciona no registro real da tabela
	dbSelectArea("SF2")
	SF2->(dbGoTo( (_cAliasSF2)->SF2RECNO ))

	// posiciona no cadastro do cliente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1)) // 1-A1_FILIAL, A1_COD, A1_LOJA
	SA1->(dbSeek( xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA) ))

	// chama a funcao para imprimir o recibo/html
	_cArqHtml := U_FATR004A(.t.,.f.)

	// abre o navegador
	ShellExecute("open",_cArqHtml,"","",5)

	// proximo registro
	dbSelectArea(_cAliasSF2)
	dbSkip()
EndDo

// fecha a query
dbSelectArea(_cAliasSF2)
dbCloseArea()


Return(.t.)

// ** funcao que gera o HTML do recibo
User Function FATR004A(mvAbreArq)
// CNPJ/CPF do tomador de servicos
local _cCNPJTom := ""

// objeto do processo de WF
local _oProcWF

// retorno do ID do processo
local _cRetID

// local e nome do arquivo gerado
local _cArqRet := ""
// pasta temporaria
local _cPathTemp
local _cTmpNome
local _cTmpExt

// Arquivo html template utilizado para montagem dO RECIBO
local _cHtmlMod := "\workflow\fatura\"+SM0->M0_ESTCOB+"\mun_"+SM0->M0_CODMUN+"\fatura_locacao.html"

// outras informacoes
local _cOutrasInf := ""

// total do recibo
local _nTotalRec := 0

// prepara a descricao dos servicos
local _cDscServico := sfRetDscServ(@_cOutrasInf, @_nTotalRec)

// Inicialize a classe TWFProcess e instacia o objeto oProcess:
_oProcWF := TWFProcess():New("000002", "")

// crie uma tarefa
_oProcWF:NewTask("", _cHtmlMod)

// informações do cabeçalho
_oProcWF:oHtml:ValByName("cNrRecibo",StrZero(Val(SF2->F2_DOC),Len(SF2->F2_DOC)))
_oProcWF:oHtml:ValByName("cDataEmi" ,DtoC(SF2->F2_EMISSAO))
_oProcWF:oHtml:ValByName("cHoraEmi" ,SF2->F2_HORA)

// informações do prestador de serviço
_oProcWF:oHtml:ValByName("cCnpjEmi" ,AllTrim(Transform(SM0->M0_CGC,"@R 99.999.999/9999-99")))
_oProcWF:oHtml:ValByName("cIMEmi"	,AllTrim(SM0->M0_INSCM))
_oProcWF:oHtml:ValByName("cNomeEmi"	,AllTrim(SM0->M0_NOMECOM))
_oProcWF:oHtml:ValByName("cEndEmi"	,AllTrim(SM0->M0_ENDCOB))
_oProcWF:oHtml:ValByName("cCepEmi"	,AllTrim(Transform(SM0->M0_CEPCOB,"@R 99999-999")))
_oProcWF:oHtml:ValByName("cBaiEmi"	,AllTrim(SM0->M0_BAIRCOB))
_oProcWF:oHtml:ValByName("cMunEmi"	,AllTrim(SM0->M0_CIDCOB))
_oProcWF:oHtml:ValByName("cUfEmi"	,AllTrim(SM0->M0_ESTCOB))

// informacoes do tomador de servicos
If (SA1->A1_PESSOA == "F")
	_cCNPJTom := Transform(SA1->A1_CGC,"@R 999.999.999-99")
ElseIf (SA1->A1_PESSOA == "J")
	_cCNPJTom := Transform(SA1->A1_CGC,"@R 99.999.999/9999-99")
EndIf

_oProcWF:oHtml:ValByName("cCnpjDest",AllTrim(_cCNPJTom))
_oProcWF:oHtml:ValByName("cIMDest"	,AllTrim(SA1->A1_INSCRM))
_oProcWF:oHtml:ValByName("cNomeDest",AllTrim(SA1->A1_NOME))
_oProcWF:oHtml:ValByName("cEndDest"	,AllTrim(SA1->A1_END))
_oProcWF:oHtml:ValByName("cCepDest"	,AllTrim(Transform(SA1->A1_CEP,"@R 99999-999")))
_oProcWF:oHtml:ValByName("cMunDest"	,AllTrim(SA1->A1_MUN))
_oProcWF:oHtml:ValByName("cUfDest"	,AllTrim(SA1->A1_EST))

// discriminacao dos servicos
_oProcWF:oHtml:ValByName("cDescServicos",StrTran(AllTrim(_cDscServico),Chr(10),"<br>"))

// total da nota
_oProcWF:oHtml:ValByName("cTotalRecibo",AllTrim(Transform(_nTotalRec,"@E 999,999,999.99")))

// mensagens adicionais
_oProcWF:oHtml:ValByName("cOutrasInf",AllTrim(_cOutrasInf))

// gera o recibo, grava o html na pasta e retorna a identificação do processo
_cRetID := _oProcWF:Start("\tecadi\fatura\")

// define o nome do arquivo de retorno
_cArqRet := "\tecadi\fatura\"
// empresa e filial
_cArqRet += "emp"+cEmpAnt+"\"+cFilAnt+"\"
// informacoes do cliente
_cArqRet += "cli_"+SF2->F2_CLIENTE+"_"+SF2->F2_LOJA+"_fatura_"+SF2->F2_DOC+"_serie_"+SF2->F2_SERIE+".htm"

// verifica se o arquivo existe
If (File(_cArqRet))
	// apaga o arquivo
	fErase(_cArqRet)
EndIf

// renomeia o arquivo gerado e muda de pasta
fRename("\tecadi\fatura\"+_cRetID+".htm",_cArqRet)

// encerra Workflow
_oProcWF:Finish()

// verifica de deve abrir o arquivo
If (mvAbreArq)
	// retorna a pasta temporaria da maquina
	_cPathTemp := AllTrim(GetTempPath())
	// extrai informacoes do arquivo, para mudar o local padrao
	// ex: SplitPath ( < cArquivo>, [ @cDrive], [ @cDiretorio], [ @cNome], [ @cExtensao] )
	SplitPath(AllTrim(_cArqRet),nil,nil,@_cTmpNome,@_cTmpExt)
	// copia o arquivo do servidor para a maquina local
	CpyS2T(_cArqRet, _cPathTemp, .f.)
	// muda o caminho do arquivo de retorno
	_cArqRet := _cPathTemp+_cTmpNome+_cTmpExt
EndIf

Return(_cArqRet)


// ** funcao que prepara a descricao dos servicos
Static Function sfRetDscServ(mvOutrasInf, mvTotalRec)
// variavel de retorno
local _cRet := ""
// Seek SD2
local _cSeekSD2

// ** ESP. TECADI - INI
// ex: estrutura
// 1-Cod.Produto
// 2-Dsc.Produto
// 3-Quantidade
// 4-Vlr.Unitario
// 5-Vlr.Total
local _aDscServico := {}
local _nPosServico := 0
local _nTmpQuant  := 0
// aglutina varias pedidos em unica nota?
local _lAglutNFS := .f.
local _cTmpPedido := ""
// numeros dos pedidos do cliente
local _aRefPedCli := {}
local _cRefPedCli := ""
// mensagem especifica do pedido
local _cMensCli := ""

// varre os itens da nota/recibo
dbSelectArea("SD2")
SD2->(dbSetOrder(3)) // 3-D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, D2_COD, D2_ITEM
SD2->(dbSeek( _cSeekSD2 := xFilial("SD2")+SF2->(F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA) ))

While SD2->(!Eof()).and.(SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == _cSeekSD2)

	// posiciona pedido de venda
	dbSelectArea("SC5")
	SC5->(dbSetOrder(1)) // 1-C5_FILIAL, C5_NUM
	SC5->(DbSeek( xFilial("SC5")+SD2->D2_PEDIDO ))

	// mensagem especifica para o cliente
	If ! AllTrim(SC5->C5_MENNOTA) $ _cMensCli
		_cMensCli += AllTrim(SC5->C5_MENNOTA)
	EndIf

	// outras informacoes
	If !Empty(SC5->C5_MENPAD) .And. !AllTrim(FORMULA(SC5->C5_MENPAD)) $ mvOutrasInf
		mvOutrasInf += AllTrim(FORMULA(SC5->C5_MENPAD))
	EndIf

	// posiciona no item do pedido de venda
	dbSelectArea("SC6")
	SC6->(dbSetOrder(1)) // 1-C6_FILIAL, C6_NUM, C6_ITEM, C6_PRODUTO
	SC6->(DbSeek( xFilial("SC6")+SD2->D2_PEDIDO+SD2->D2_ITEMPV+SD2->D2_COD ))

	// ex: estrutura _aDscServico
	// 1-Cod.Produto
	// 2-Dsc.Produto
	// 3-Quantidade
	// 4-Vlr.Unitario
	// 5-Vlr.Total

	// armazena a quantidade
	If (AllTrim(SD2->D2_COD)=="9000005")
		_nTmpQuant := 1
	Else
		_nTmpQuant := SD2->D2_QUANT
	EndIf

	// pesquisa o produto
	_nPosServico := aScan(_aDscServico,{|x| (x[1] == SD2->D2_COD).and.(x[2] == SC6->C6_DESCRI) })

	// inclui novo servico
	If (_nPosServico == 0)

		// atualiza os dados
		aAdd(_aDscServico,{ SD2->D2_COD ,;
		SC6->C6_DESCRI                  ,;
		_nTmpQuant                      ,;
		SD2->D2_PRUNIT                  ,;
		SD2->(D2_TOTAL + D2_DESCON)     })

		// atualiza dados do servico
	ElseIf (_nPosServico > 0)

		// quantidade (só incrementa quanto a quantidade for maior que 1)
		_aDscServico[_nPosServico][3] += If(_nTmpQuant > 1,_nTmpQuant,0)
		// valor unitario
		_aDscServico[_nPosServico][4] += SD2->D2_PRUNIT
		// valor total
		_aDscServico[_nPosServico][5] += SD2->(D2_TOTAL + D2_DESCON)

	EndIf

	// aglutina varios pedidos em uma unica nota?
	If (Empty(_cTmpPedido))
		_cTmpPedido := SD2->D2_PEDIDO
	EndIf

	// verifica se sao pedidos distintos na mesma nota
	If (_cTmpPedido != SD2->D2_PEDIDO)
		_lAglutNFS := .t.
	EndIf

	// armazena numeros dos pedidos do cliente
	If (SC5->(FieldPos("C5_ZPEDCLI")) > 0).And.(!Empty(SC5->C5_ZPEDCLI))
		// verifica se o pedido ja esta na relacao
		If ( aScan(_aRefPedCli,{|xVetor| (xVetor == SC5->C5_ZPEDCLI) }) == 0)
			// adiciona pedido
			aAdd(_aRefPedCli,SC5->C5_ZPEDCLI)
		EndIf
	EndIf

	// proximo item
	SD2->(dbSkip())
EndDo

// formata descricao dos servicos
For _nPosServico := 1 to Len(_aDscServico)

	// busco a descricao do servico do pedido de vendas
	// caso ja tenha alguma informacao, inclui quebra de linha
	If ( ! Empty(_cRet) )
		_cRet += CRLF
	EndIf

	// atualiza campo temporario de quantidade
	_nTmpQuant := _aDscServico[_nPosServico][3]

	// inclui os detalhes do item
	_cRet += AllTrim(_aDscServico[_nPosServico][2])
	// abre o parenteses principal
	_cRet += " ("
	// quantidade
	If (_nTmpQuant > 1)
		_cRet += "Quantidade "+Alltrim(Str(_nTmpQuant))
		// valor unitário
		_cRet += " Valor Unitário R$ "+AllTrim(Transf(_aDscServico[_nPosServico][4],PesqPict("SD2","D2_TOTAL")))+" "
	EndIf
	// valor total
	_cRet += "Valor Total R$ "+AllTrim(Transf(_aDscServico[_nPosServico][5],PesqPict("SD2","D2_TOTAL")))+")"

	// controle de total do recibo
	mvTotalRec += _aDscServico[_nPosServico][5]

Next _nPosServico

// quando NAO for varios pedidos na mesma nota, complementa com a mensagem do processo
If ( ! _lAglutNFS)
	_cRet += If(Empty(_cMensCli),"",CRLF+CRLF)+_cMensCli
EndIf

// mensagem do pedido do cliente
If (Len(_aRefPedCli) > 0)
	// atualiza variavel com todos os pedidos, separando por virgula
	aEval(_aRefPedCli,{|mvVetor| (_cRefPedCli += If(Empty(_cRefPedCli),"",", ")+AllTrim(mvVetor)) })
	// complementa as informacoes na variavel de servicos
	_cRet += CRLF+CRLF+"SEU(S) PEDIDO(S): "+_cRefPedCli
EndIf

Return(_cRet)
