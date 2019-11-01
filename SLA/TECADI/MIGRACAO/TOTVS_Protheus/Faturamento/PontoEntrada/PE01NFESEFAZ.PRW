#Include "protheus.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada para manipular os dados da nota fiscal !
!                  ! eletronica.                                             !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe José Limas           ! Data de Criacao ! 08/2015 !
+------------------+--------------------------------------------------------*/

User Function PE01NFESEFAZ()

	//Areas
	Local _aArea     := GetArea()	    //Pega area antes de fazer o posicionamento
	Local _aAreaSF2  := SF2->(GetArea())//Pega area antes de fazer o posicionamento
	Local _aAreaSD2  := SD2->(GetArea())//Pega area antes de fazer o posicionamento
	Local _aAreaSC5  := SC5->(GetArea())//Pega area antes de fazer o posicionamento

	// variaveis recebidas como parametro
	Local _aDadProd  := ParamIxb[ 1] //dados do produto
	Local _cMesgCli  := ParamIxb[ 2] //mensagens do cliente
	Local _cMsgFis   := ParamIxb[ 3] //mensagens fiscal
	Local _aDadDest  := ParamIxb[ 4] //dados do destinatario
	Local _aDadNota  := ParamIxb[ 5] //dados da nota fiscal
	Local _aDadItens := ParamIxb[ 6] //dados dos itens da nota fiscal
	Local _aDadTitul := ParamIxb[ 7] //dados da duplicata
	Local _aDadTrans := ParamIxb[ 8] //dados da transportadora
	Local _aDadEntre := ParamIxb[ 9] //dados da entrega
	Local _aDadRetir := ParamIxb[10] //dados da retirada
	Local _aDadVeicu := ParamIxb[11] //dados do veiculo
	Local _aDadReboq := ParamIxb[12] //dados do reboque
	Local _aNfVincRur:= ParamIxb[13] //vincula notas fiscais - rural
	Local _aEspVol   := ParamIxb[14] //especie de volumes
	Local _aNfVinc   := ParamIxb[15] //Notas vinculadas
	Local _aDetPag   := ParamIxb[16] //detalhes do pagamento
	Local _aObsCont  := ParamIxb[17] //observacoes complementares
	Local _cTipo     := ParamIxb[18] //Tipo de xml 1-Saida / 2-Entrada

	//Variavel Temporaria For
	Local _iy        := 0

	//Variaveis de composição da Chave NFE
	Local _cUF       := ""
	Local _cAAMM     := ""
	Local _cCNPJ     := ""
	Local _cMod      := ""
	Local _cSer      := ""
	Local _cNum      := ""

	// dados da nota fiscal de venda na nota fiscal de retorno
	local _lDadosNfv := .f.
	// valida chave da nf de remessa
	local _lChvNfRem := .t.

	//Nota fiscal de saida
	If (_cTipo == "1")

		// parameto para verificar se o cliente quer dados da Nfe de origem na Nfe de venda
		_lChvNfRem := U_FtWmsParam("WMS_CHAVE_NFE_REMESSA", "L", .t., .f., Nil, SF2->F2_CLIENTE, SF2->F2_LOJA, Nil, Nil)

		// se for falso, limpa o array padrão
		If ( ! _lChvNfRem )
			// limpo o array, para inserir os registros das chaves conforme cliente demanda
			_aNfVinc := {}
		EndIf

		// dados da nota fiscal de venda na nota fiscal de retorno
		_lDadosNfv := U_FtWmsParam("WMS_PEDIDO_CHAVE_NFE_VENDA", "L", .f., .f., Nil, SF2->F2_CLIENTE, SF2->F2_LOJA, Nil, Nil)

		// valida a necessidade de incluir os dados da nota fiscal de venda
		If (_lDadosNfv)

			// abre o cabecalho do pedido de venda
			DBSelectArea("SC5")
			SC5->(DbSetOrder(1)) // 1-C5_FILIAL, C5_NUM

			// varre todos os itens da nota fiscal
			For _iy := 1 To Len(_aDadItens)

				// pesquisa o pedido de venda
				If SC5->(DbSeek(xFilial("SC5") + _aDadItens[_iy][1]))

					// valida se o campo foi preenchido
					If ( ! (Empty(SC5->C5_ZCHVNFV)) )

						// verifica se a chave ja esta na lista
						If (aScan(_aNfVinc,{|_aChv| (_aChv[7] == SC5->C5_ZCHVNFV)} ) == 0)

							//vincula NFe de faturamento do cliente.
							_cUF   := SubStr(SC5->C5_ZCHVNFV, 01, 02)
							_cAAMM := SubStr(SC5->C5_ZCHVNFV, 03, 04)
							_cCNPJ := SubStr(SC5->C5_ZCHVNFV, 07, 14)
							_cMod  := Substr(SC5->C5_ZCHVNFV, 21, 02)
							_cSer  := Substr(SC5->C5_ZCHVNFV, 23, 03)
							_cNum  := Substr(SC5->C5_ZCHVNFV, 26, 09)

							// adiciona os dados da nota
							aAdd( _aNfVinc, { SC5->C5_ZEMINFV, _cSer, _cNum, _cCNPJ, _cUF, "SPED", SC5->C5_ZCHVNFV } )

						EndIf

					EndIf

				EndIf

			Next _iy

		EndIf

	EndIf

	//Retorna as Areas das tabelas envolvidas
	RestArea(_aAreaSF2)
	RestArea(_aAreaSD2)
	RestArea(_aAreaSC5)
	RestArea(_aArea)

Return {_aDadProd, _cMesgCli, _cMsgFis, _aDadDest, _aDadNota, _aDadItens, _aDadTitul, _aDadTrans, _aDadEntre, _aDadRetir, _aDadVeicu, _aDadReboq, _aNfVincRur, _aEspVol, _aNfVinc, _aDetPag, _aObsCont, _cTipo}