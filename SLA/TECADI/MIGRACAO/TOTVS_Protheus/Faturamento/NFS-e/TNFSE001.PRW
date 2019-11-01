#INCLUDE "TopConn.ch"
#INCLUDE "Rwmake.ch"
#INCLUDE "Protheus.ch"
#INCLUDE "FILEIO.CH"

// impressão de notas fiscais de serviço


// ** funcao para impressao das notas fiscais
User Function NFSE001D
	// grupo de perguntas
	local _aPerg := {}
	// define o tamanho do grupo de perguntas
	Local _aParam := {Space(Len(SF2->F2_SERIE)),Space(Len(SF2->F2_DOC)),Space(Len(SF2->F2_DOC))}
	local _cParImp := SM0->M0_CODIGO+SM0->M0_CODFIL+"NFSE001D"
	// query para filtro das notas
	local _cQrySF2
	// cria alias da query
	local _cAliasSF2 := GetNextAlias()
	// arquivo gerado
	local _cArqHtml

	aadd(_aPerg,{1,"Serie da Nota Fiscal",_aParam[01],"",".T.","",".T.",30,.F.})
	aadd(_aPerg,{1,"Nota fiscal inicial",_aParam[02],"",".T.","",".T.",30,.T.})
	aadd(_aPerg,{1,"Nota fiscal final",_aParam[03],"",".T.","",".T.",30,.T.})

	_aParam[01] := ParamLoad(_cParImp,_aPerg,1,_aParam[01])
	_aParam[02] := ParamLoad(_cParImp,_aPerg,2,_aParam[02])
	_aParam[03] := ParamLoad(_cParImp,_aPerg,3,_aParam[03])

	// chama tela de parametros
	If ParamBox(_aPerg,"Impressão NFS-e",@_aParam,,,,,,,_cParImp,.T.,.T.)
		// monta a query
		_cQrySF2 := "SELECT SF2.R_E_C_N_O_ SF2RECNO "
		// notas fiscais de saida
		_cQrySF2 += "FROM "+RetSqlName("SF2")+" SF2 "
		// filtro padrao
		_cQrySF2 += "WHERE "+RetSqlCond("SF2")+" "
		_cQrySF2 += "AND F2_SERIE = '"+mv_par01+"' "
		_cQrySF2 += "AND F2_DOC   BETWEEN '"+mv_par02+"' AND '"+mv_par03+"' "
		// somente notas autorizadas
		_cQrySF2 += "AND F2_FIMP  = 'S' "
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

			// chama a funcao para imprimir a nota/html
			_cArqHtml := U_NFSE001F(.t.,.f.)

			// abre o navegador
			ShellExecute("open",_cArqHtml,"","",5)

			// proximo registro
			dbSelectArea(_cAliasSF2)
			dbSkip()
		EndDo

		// fecha a query
		dbSelectArea(_cAliasSF2)
		dbCloseArea()

	EndIf

Return(.t.)

// ** funcao que gera o HTML da nota
User Function NFSE001F(mvAbreArq,mvGeraXML)

	// mensagens e erros do Parser no XML
	local _cErro := ""
	local _cAviso := ""

	// endereco
	local _cEndEmit := ""
	local _cEndToma := ""

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

	// numero da Rps e Numero Nfse
	local _cNroRps
	local _cNroNfse

	// Arquivo html template utilizado para montagem da nota
	local _cHtmlMod := "\workflow\nfse\"+SM0->M0_ESTCOB+"\mun_"+SM0->M0_CODMUN+"\nfse.html"

	// XML da nota posicionada
	local _cXmlNfse

	// imagem do logo da prefeitura
	local _cImgLogPref := "nfse_logoprefeitura"

	// array para pegar a descricao do servico
	local _aServDesc := {}

	// objeto com a estrutura do retorno
	private _oXmlRetNfse := Nil

	// verifica qual XML deve usar
	If (Empty(SF2->F2_ZXMLNFS))
		// retorna o XML da nota posicionada - TSS
		_cXmlNfse := sfDetSchema( SF2->(F2_SERIE+F2_DOC), 2, .f.)

	ElseIf ( ! Empty(SF2->F2_ZXMLNFS))
		// retorna o XML da nota posicionada - Customizado
		_cXmlNfse := SF2->F2_ZXMLNFS

	EndIf


	// cria objeto com a estrutura do retorno
	_oXmlRetNfse := XmlParser(_cXmlNfse,"_",@_cErro,@_cAviso)


	// remove o inicio do XML (repetido)
	// verifica o metodo do XML de retorno
	If (Type("_oXmlRetNfse:_CONSULTARNFSERESPOSTA")=="O")
		_oXmlRetNfse := _oXmlRetNfse:_CONSULTARNFSERESPOSTA:_LISTANFSE:_COMPNFSE:_NFSE
	Elseif (Type("_oXmlRetNfse:_CONSULTARNFSERPSRESPOSTA")=="O") // Itajaí
		_oXmlRetNfse := _oXmlRetNfse:_CONSULTARNFSERPSRESPOSTA:_COMPNFSE:_NFSE
	ElseIf (Type("_oXmlRetNfse:_GERARNFSERESPOSTA")=="O")
		_oXmlRetNfse := _oXmlRetNfse:_GERARNFSERESPOSTA:_LISTANFSE:_COMPNFSE:_NFSE
	ElseIf (Type("_oXmlRetNfse:_CONSULTARLOTERPSRESPOSTA")=="O")
		If ( SM0->M0_CODMUN == "4211306")
			_oXmlRetNfse := _oXmlRetNfse:_CONSULTARLOTERPSRESPOSTA:_LISTANFSE:_COMPLNFSE:_NFSE  // Navegantes
		Else
			_oXmlRetNfse := _oXmlRetNfse:_CONSULTARLOTERPSRESPOSTA:_LISTANFSE:_COMPNFSE:_NFSE   // Itajai
		EndIf
	ElseIf (Type("_oXmlRetNfse:_CONSULTARLOTERPSRESULT")=="O")
		_oXmlRetNfse := _oXmlRetNfse:_CONSULTARLOTERPSRESULT:_LISTANFSE:_COMPNFSE:_TCCOMPNFSE:_NFSE
	EndIf

	// se for Curitiba, complementa o arquivo da logo
	If (SM0->M0_CODMUN == "4106902")
		_cImgLogPref += "_curitiba"
	Elseif ( SM0->M0_CODMUN == "4211306")
		_cImgLogPref += "_navegantes"
	Elseif ( SM0->M0_CODMUN == "4125506")
		_cImgLogPref += "_sjp"
	EndIf

	// Inicialize a classe TWFProcess e instacia o objeto oProcess:
	_oProcWF := TWFProcess():New("000001", "")

	// formata o endereco do emitente
	IF ( SM0->M0_CODMUN == "4125506")  // SJP
		_cEndEmit := AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_PRESTADORSERVICO:_NS2_ENDERECO:_NS2_ENDERECO:TEXT)
		_cEndEmit += " - " + AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_PRESTADORSERVICO:_NS2_ENDERECO:_NS2_COMPLEMENTO:TEXT)
		_cEndEmit += ", " + AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_PRESTADORSERVICO:_NS2_ENDERECO:_NS2_NUMERO:TEXT)
	Else
		_cEndEmit := AllTrim(_oXmlRetNfse:_INFNFSE:_PRESTADORSERVICO:_ENDERECO:_ENDERECO:TEXT)
		If (Type("_oXmlRetNfse:_INFNFSE:_PRESTADORSERVICO:_ENDERECO:_COMPLEMENTO:TEXT")=="C")
			_cEndEmit += " - "+AllTrim(_oXmlRetNfse:_INFNFSE:_PRESTADORSERVICO:_ENDERECO:_COMPLEMENTO:TEXT)
		EndIf
		_cEndEmit += ", "+AllTrim(_oXmlRetNfse:_INFNFSE:_PRESTADORSERVICO:_ENDERECO:_NUMERO:TEXT)
	EndIf

	// crie uma tarefa
	_oProcWF:NewTask("", _cHtmlMod)

	// atualiza as logomarcas (imagens)
	_oProcWF:oHtml:ValByName("logoPref"		,'<img src="http://tecadi.com.br/site/imgs/'+_cImgLogPref+'.jpeg" width="75" height="96" align="middle" />')
	_oProcWF:oHtml:ValByName("logoprestador",'<img src="http://tecadi.com.br/site/imgs/nfse_logotecadi.png" width="100" height="100"/>')

	// informações do cabeçalho
	IF ( SM0->M0_CODMUN == "4125506")  // SJP
		_cNroRps := AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_IDENTIFICACAORPS:_NS2_NUMERO:TEXT)
		_oProcWF:oHtml:ValByName("cRps"		,_cNroRps)
		_oProcWF:oHtml:ValByName("cSerieRps", AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_IDENTIFICACAORPS:_NS2_SERIE:TEXT) )
		_oProcWF:oHtml:ValByName("cEmissao" ,sfCtoD( _oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_DATAEMISSAO:TEXT,"D"))
	Else
		_cNroRps := AllTrim(_oXmlRetNfse:_INFNFSE:_IDENTIFICACAORPS:_NUMERO:TEXT)
		_oProcWF:oHtml:ValByName("cRps"		,_cNroRps)
		_oProcWF:oHtml:ValByName("cSerieRps",AllTrim(_oXmlRetNfse:_INFNFSE:_IDENTIFICACAORPS:_SERIE:TEXT))
		_oProcWF:oHtml:ValByName("cEmissao" ,sfCtoD(_oXmlRetNfse:_INFNFSE:_DATAEMISSAORPS:TEXT,"D"))
	EndIf

	If (SM0->M0_CODMUN == "4208203") // Itajai
		_cNroNfse := AllTrim(SubS(_oXmlRetNfse_oXmlRetNfse:_INFNFSE:_NUMERO:TEXT,6))
		_oProcWF:oHtml:ValByName("cNota"	,_cNroNfse +" / A1")
	ElseIf ( (SM0->M0_CODMUN == "4106902") .OR. ( SM0->M0_CODMUN == "4211306")) // Curitiba ou Navegantes
		_cNroNfse := AllTrim(_oXmlRetNfse_oXmlRetNfse:_INFNFSE:_NUMERO:TEXT)
		_oProcWF:oHtml:ValByName("cNota"	,_cNroNfse)
	ElseIf ( SM0->M0_CODMUN == "4125506")  // SJP
		_cNroNfse := AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_NUMERO:TEXT)
		_oProcWF:oHtml:ValByName("cNota"	,_cNroNfse)
	EndIf

	// data e hora emissão
	If ( SM0->M0_CODMUN == "4125506")  // SJP
		_oProcWF:oHtml:ValByName("cDataEmi" ,sfCtoD(AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_DATAEMISSAO:TEXT),"D"))
		_oProcWF:oHtml:ValByName("cHoraEmi" ,sfCtoD(AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_DATAEMISSAO:TEXT),"H"))
	Else
		_oProcWF:oHtml:ValByName("cDataEmi" ,sfCtoD(_oXmlRetNfse:_INFNFSE:_DATAEMISSAO:TEXT,"D"))
		_oProcWF:oHtml:ValByName("cHoraEmi" ,sfCtoD(_oXmlRetNfse:_INFNFSE:_DATAEMISSAO:TEXT,"H"))
	EndIf

	// codigo de verificação (autenticidade)
	If ( (SM0->M0_CODMUN == "4208203") .OR. ( SM0->M0_CODMUN == "4211306")) // Itajai ou Navegantes
		_oProcWF:oHtml:ValByName("cCodVerif", AllTrim(_oXmlRetNfse:_INFNFSE:_CODIGOVERIFICACAO:TEXT) )
	ElseIf (SM0->M0_CODMUN == "4106902") // Curitiba
		_oProcWF:oHtml:ValByName("cCodVerif",Transform( AllTrim(_oXmlRetNfse:_INFNFSE:_CODIGOVERIFICACAO:TEXT), "@R AAAA-AAAA"))
	ElseIf ( SM0->M0_CODMUN == "4125506")  // SJP
		_oProcWF:oHtml:ValByName("cCodVerif",AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_CODIGOVERIFICACAO:TEXT))
	EndIf

	// informações do prestador de serviço
	If ( SM0->M0_CODMUN == "4125506")  // SJP
		_oProcWF:oHtml:ValByName("cCnpjEmi" ,AllTrim(Transform(AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_PRESTADORSERVICO:_NS2_IDENTIFICACAOPRESTADOR:_NS2_CNPJ:TEXT),"@R 99.999.999/9999-99")))
		_oProcWF:oHtml:ValByName("cIMEmi"	,AllTrim(AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_PRESTADORSERVICO:_NS2_IDENTIFICACAOPRESTADOR:_NS2_INSCRICAOMUNICIPAL:TEXT)))
	Else
		_oProcWF:oHtml:ValByName("cCnpjEmi" ,AllTrim(Transform(_oXmlRetNfse:_INFNFSE:_PRESTADORSERVICO:_IDENTIFICACAOPRESTADOR:_CNPJ:TEXT,"@R 99.999.999/9999-99")))
		_oProcWF:oHtml:ValByName("cIMEmi"	,AllTrim(_oXmlRetNfse:_INFNFSE:_PRESTADORSERVICO:_IDENTIFICACAOPRESTADOR:_INSCRICAOMUNICIPAL:TEXT))
	EndIf

	// razao social e nome fantasia
	If ( SM0->M0_CODMUN == "4125506")  // SJP
		_oProcWF:oHtml:ValByName("cNomeEmi"	,AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_PRESTADORSERVICO:_NS2_RAZAOSOCIAL:TEXT))
		_oProcWF:oHtml:ValByName("cNomeEmi"	,AllTrim("TECADI"))
	Else  // outras empresas
		If (Type("_oXmlRetNfse:_INFNFSE:_PRESTADORSERVICO:_RAZAOSOCIAL:TEXT")=="C")
			_oProcWF:oHtml:ValByName("cNomeEmi"	,AllTrim(_oXmlRetNfse:_INFNFSE:_PRESTADORSERVICO:_RAZAOSOCIAL:TEXT))
		Else
			_oProcWF:oHtml:ValByName("cNomeEmi"	,AllTrim(_oXmlRetNfse:_INFNFSE:_PRESTADORSERVICO:_NOMEFANTASIA:TEXT))
		EndIf
	EndIf


	// informações de endereço do prestador de serviço
	If ( SM0->M0_CODMUN == "4125506")  // SJP
		_oProcWF:oHtml:ValByName("cEndEmi"	,FwNoAccent( AllTrim(_cEndEmit)) )
		_oProcWF:oHtml:ValByName("cCepEmi"	,AllTrim(Transform(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_PRESTADORSERVICO:_NS2_ENDERECO:_NS2_CEP:TEXT,"@R 99999-999")))
		_oProcWF:oHtml:ValByName("cBaiEmi"	,FwNoAccent( AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_PRESTADORSERVICO:_NS2_ENDERECO:_NS2_BAIRRO:TEXT)))
		_oProcWF:oHtml:ValByName("cMunEmi"	,sfRetMunic(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_PRESTADORSERVICO:_NS2_ENDERECO:_NS2_CODIGOMUNICIPIO:TEXT,""))
		_oProcWF:oHtml:ValByName("cUfEmi"	,sfRetMunic(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_PRESTADORSERVICO:_NS2_ENDERECO:_NS2_CODIGOMUNICIPIO:TEXT,"UF"))
	else
		_oProcWF:oHtml:ValByName("cEndEmi"	,AllTrim(_cEndEmit))
		_oProcWF:oHtml:ValByName("cCepEmi"	,AllTrim(Transform(_oXmlRetNfse:_INFNFSE:_PRESTADORSERVICO:_ENDERECO:_CEP:TEXT,"@R 99999-999")))
		_oProcWF:oHtml:ValByName("cBaiEmi"	,AllTrim(_oXmlRetNfse:_INFNFSE:_PRESTADORSERVICO:_ENDERECO:_BAIRRO:TEXT))
		_oProcWF:oHtml:ValByName("cMunEmi"	,sfRetMunic(_oXmlRetNfse:_INFNFSE:_PRESTADORSERVICO:_ENDERECO:_CODIGOMUNICIPIO:TEXT,""))
		_oProcWF:oHtml:ValByName("cUfEmi"	,sfRetMunic(_oXmlRetNfse:_INFNFSE:_PRESTADORSERVICO:_ENDERECO:_CODIGOMUNICIPIO:TEXT,"UF"))
	Endif

	// CNPJ do tomador do servico
	If ( SM0->M0_CODMUN == "4125506")  // SJP
		_cCNPJTom := Transform(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_TOMADORSERVICO:_NS2_IDENTIFICACAOTOMADOR:_NS2_CPFCNPJ:_NS2_CNPJ:TEXT,"@R 99.999.999/9999-99")
	Else
		If (ValType(_oXmlRetNfse:_INFNFSE:_TOMADORSERVICO:_IDENTIFICACAOTOMADOR:_CPFCNPJ:_CNPJ:TEXT)=="C")
			_cCNPJTom := Transform(_oXmlRetNfse:_INFNFSE:_TOMADORSERVICO:_IDENTIFICACAOTOMADOR:_CPFCNPJ:_CNPJ:TEXT,"@R 99.999.999/9999-99")
		ElseIf (ValType(_oXmlRetNfse:_INFNFSE:_TOMADORSERVICO:_IDENTIFICACAOTOMADOR:_CPFCNPJ:_CPF:TEXT)=="C")
			_cCNPJTom := Transform(_oXmlRetNfse:_INFNFSE:_TOMADORSERVICO:_IDENTIFICACAOTOMADOR:_CPFCNPJ:_CPF:TEXT,"@R 999.999.999-99")
		EndIf
	EndIf

	// dados do endereço do tomador de serviço
	If ( SM0->M0_CODMUN == "4125506")  // SJP
		_cEndToma := AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_TOMADORSERVICO:_NS2_ENDERECO:_NS2_ENDERECO:TEXT)
		_cEndToma += ", " + AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_TOMADORSERVICO:_NS2_ENDERECO:_NS2_NUMERO:TEXT)
	Else
		_cEndToma := AllTrim(_oXmlRetNfse:_INFNFSE:_TOMADORSERVICO:_ENDERECO:_ENDERECO:TEXT)
		If (Type("_oXmlRetNfse:_INFNFSE:_TOMADORSERVICO:_ENDERECO:_COMPLEMENTO:TEXT")=="C")
			_cEndToma += " - "+AllTrim(_oXmlRetNfse:_INFNFSE:_TOMADORSERVICO:_ENDERECO:_COMPLEMENTO:TEXT)
		EndIf
		_cEndToma += ", "+AllTrim(_oXmlRetNfse:_INFNFSE:_TOMADORSERVICO:_ENDERECO:_NUMERO:TEXT)
	EndIF

	// demais dados do tomador do serviço
	If ( SM0->M0_CODMUN == "4125506")  // SJP
		_oProcWF:oHtml:ValByName("cCnpjDest",AllTrim(_cCNPJTom))
		_oProcWF:oHtml:ValByName("cIMDest"	,"")
		_oProcWF:oHtml:ValByName("cNomeDest",AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_TOMADORSERVICO:_NS2_RAZAOSOCIAL:TEXT))
		_oProcWF:oHtml:ValByName("cEndDest"	,_cEndToma)
		_oProcWF:oHtml:ValByName("cCepDest"	,AllTrim(Transform(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_TOMADORSERVICO:_NS2_ENDERECO:_NS2_CEP:TEXT,"@R 99999-999")))
		_oProcWF:oHtml:ValByName("cMunDest"	,sfRetMunic(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_TOMADORSERVICO:_NS2_ENDERECO:_NS2_CODIGOMUNICIPIO:TEXT,""))
		_oProcWF:oHtml:ValByName("cUfDest"	,sfRetMunic(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_TOMADORSERVICO:_NS2_ENDERECO:_NS2_CODIGOMUNICIPIO:TEXT,"UF"))
	Else
		_oProcWF:oHtml:ValByName("cCnpjDest",AllTrim(_cCNPJTom))
		//_oProcWF:oHtml:ValByName("cIMDest"	,AllTrim(SA1->A1_INSCRM))
		_oProcWF:oHtml:ValByName("cIMDest"	,"")
		_oProcWF:oHtml:ValByName("cNomeDest",AllTrim(_oXmlRetNfse:_INFNFSE:_TOMADORSERVICO:_RAZAOSOCIAL:TEXT))
		_oProcWF:oHtml:ValByName("cEndDest"	,_cEndToma)
		_oProcWF:oHtml:ValByName("cCepDest"	,AllTrim(Transform(_oXmlRetNfse:_INFNFSE:_TOMADORSERVICO:_ENDERECO:_CEP:TEXT,"@R 99999-999")))
		_oProcWF:oHtml:ValByName("cMunDest"	,sfRetMunic(_oXmlRetNfse:_INFNFSE:_TOMADORSERVICO:_ENDERECO:_CODIGOMUNICIPIO:TEXT,""))
		_oProcWF:oHtml:ValByName("cUfDest"	,sfRetMunic(_oXmlRetNfse:_INFNFSE:_TOMADORSERVICO:_ENDERECO:_CODIGOMUNICIPIO:TEXT,"UF"))
	EndIf

	// discriminacao dos servicos
	If ( SM0->M0_CODMUN == "4211306")  // se for Navegantes, o retorno da descrição é um array
		_aServDesc := StrTokArr( _oXmlRetNfse:_INFNFSE:_SERVICO:_DISCRIMINACAO:TEXT, "[]")
		_oProcWF:oHtml:ValByName("cDescServicos", Substr(_aServDesc[2],11))   // trunca a parte descrita "Descricao=" e pega somente o a descriçao do serviço
	ElseIf ( SM0->M0_CODMUN == "4125506")  // SJP
		_oProcWF:oHtml:ValByName("cDescServicos", StrTran( AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_SERVICO:_NS2_DISCRIMINACAO:TEXT), Chr(10), "<BR>"))
	Else 
		_oProcWF:oHtml:ValByName("cDescServicos", StrTran(AllTrim(_oXmlRetNfse:_INFNFSE:_SERVICO:_DISCRIMINACAO:TEXT),Chr(10),"<br>"))
	EndIf

	// total da nota
	If ( SM0->M0_CODMUN == "4125506")  // SJP
		_oProcWF:oHtml:ValByName("cTotalNota",AllTrim(Transform(Val(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_SERVICO:_NS2_VALORES:_NS2_VALORSERVICOS:TEXT)	,"@E 999,999,999.99")))
	Else
		_oProcWF:oHtml:ValByName("cTotalNota",AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORSERVICOS:TEXT)	,"@E 999,999,999.99")))
	EndIf

	// codigo do servico
	If ( SM0->M0_CODMUN == "4125506")  // SJP
		If (AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_SERVICO:_NS2_ITEMLISTASERVICO:TEXT)=="11.04")
			_oProcWF:oHtml:ValByName("cCodServ"	,EncodeUtf8("11.04 - Armazenamento, depósito, carga, descarga, arrumação e guarda de bens de qualquer espécie"))
		Else
			_oProcWF:oHtml:ValByName("cCodServ"	,EncodeUtf8(AllTrim(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_SERVICO:_NS2_ITEMLISTASERVICO:TEXT) + " - " + AllTrim(Tabela("60",_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_SERVICO:_NS2_ITEMLISTASERVICO:TEXT))))
		EndIf
	Else
		If (AllTrim(_oXmlRetNfse:_INFNFSE:_SERVICO:_ITEMLISTASERVICO:TEXT)=="1104")
			_oProcWF:oHtml:ValByName("cCodServ"	,EncodeUtf8("11.04 - Armazenamento, depósito, carga, descarga, arrumação e guarda de bens de qualquer espécie"))
		Else
			_oProcWF:oHtml:ValByName("cCodServ"	,EncodeUtf8(AllTrim(_oXmlRetNfse:_INFNFSE:_SERVICO:_ITEMLISTASERVICO:TEXT)+" - "+AllTrim(Tabela("60",_oXmlRetNfse:_INFNFSE:_SERVICO:_ITEMLISTASERVICO:TEXT))))
		EndIf
	EndIf

	// impostos e total da nota
	If ( SM0->M0_CODMUN == "4125506")  // SJP
		_oProcWF:oHtml:ValByName("cVlServico",AllTrim(Transform(Val(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_SERVICO:_NS2_VALORES:_NS2_VALORSERVICOS:TEXT)  			,"@E 999,999,999.99")))
		_oProcWF:oHtml:ValByName("cBaseCalc" ,AllTrim(Transform(Val(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_SERVICO:_NS2_VALORES:_NS2_BASECALCULO:TEXT)				,"@E 999,999,999.99")))
		_oProcWF:oHtml:ValByName("cAliqIss"	 ,AllTrim(Transform(Val(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_SERVICO:_NS2_VALORES:_NS2_ALIQUOTA:TEXT)		   			,"@E 999.99")))
		If (_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_SERVICO:_NS2_VALORES:_NS2_ISSRETIDO:TEXT == "1") // tem retenção de ISS
			_oProcWF:oHtml:ValByName("cVlIssRet" , AllTrim(Transform(Val(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_SERVICO:_NS2_VALORES:_NS2_VALORISSRETIDO:TEXT)			,"@E 999.99")))
		Else  // não tem retenção de ISS
			_oProcWF:oHtml:ValByName("cVlIssRet", "0.00")
		EndIf

		_oProcWF:oHtml:ValByName("cVlIss"	 ,AllTrim(Transform(Val(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_SERVICO:_NS2_VALORES:_NS2_VALORISS:TEXT)					,"@E 999,999,999.99")))
		//		_oProcWF:oHtml:ValByName("cDescInco" ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_DESCONTOINCONDICIONADO:TEXT)	,"@E 999,999,999.99")))
		//		_oProcWF:oHtml:ValByName("cDescCond" ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_DESCONTOCONDICIONADO:TEXT)		,"@E 999,999,999.99")))
		//		_oProcWF:oHtml:ValByName("cPis"		 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORPIS:TEXT)					,"@E 999,999,999.99")))
		//		_oProcWF:oHtml:ValByName("cCofins"	 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORCOFINS:TEXT)				,"@E 999,999,999.99")))
		//		_oProcWF:oHtml:ValByName("cInss"	 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORINSS:TEXT)	   			,"@E 999,999,999.99")))
		//		_oProcWF:oHtml:ValByName("cIr"		 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORIR:TEXT)		 			,"@E 999,999,999.99")))
		//		_oProcWF:oHtml:ValByName("cCsll"	 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORCSLL:TEXT)	  			,"@E 999,999,999.99")))
		//		_oProcWF:oHtml:ValByName("cOutRet"	 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_OUTRASRETENCOES:TEXT)			,"@E 999,999,999.99")))
		_oProcWF:oHtml:ValByName("cLiqNFSE"	 ,AllTrim(Transform(Val(_oXmlRetNfse:_NS1_CONSULTARLOTERPSRESPOSTA:_NS1_LISTANFSE:_NS1_COMPNFSE:_NS2_NFSE:_NS2_INFNFSE:_NS2_SERVICO:_NS2_VALORES:_NS2_VALORLIQUIDONFSE:TEXT)			,"@E 999,999,999.99")))
		//		_oProcWF:oHtml:ValByName("cVlDeducao",AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORDEDUCOES:TEXT)			,"@E 999,999,999.99")))
	Else
		_oProcWF:oHtml:ValByName("cVlServico",AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORSERVICOS:TEXT)  			,"@E 999,999,999.99")))
		_oProcWF:oHtml:ValByName("cBaseCalc" ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_BASECALCULO:TEXT)				,"@E 999,999,999.99")))
		_oProcWF:oHtml:ValByName("cAliqIss"	 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_ALIQUOTA:TEXT)		   			,"@E 999.99")))
		If ( SM0->M0_CODMUN != "4211306")
			_oProcWF:oHtml:ValByName("cVlIssRet" ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORISSRETIDO:TEXT)			,"@E 999.99")))
		Else
			//		_oProcWF:oHtml:ValByName("cVlIssRet" ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_ISSRETIDO:TEXT)			    ,"@E 999.99")))
		EndIf
		_oProcWF:oHtml:ValByName("cVlIss"	 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORISS:TEXT)					,"@E 999,999,999.99")))
		_oProcWF:oHtml:ValByName("cDescInco" ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_DESCONTOINCONDICIONADO:TEXT)	,"@E 999,999,999.99")))
		_oProcWF:oHtml:ValByName("cDescCond" ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_DESCONTOCONDICIONADO:TEXT)		,"@E 999,999,999.99")))
		If ( SM0->M0_CODMUN != "4211306")
			_oProcWF:oHtml:ValByName("cPis"		 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORPIS:TEXT)					,"@E 999,999,999.99")))
			_oProcWF:oHtml:ValByName("cCofins"	 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORCOFINS:TEXT)				,"@E 999,999,999.99")))
			_oProcWF:oHtml:ValByName("cInss"	 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORINSS:TEXT)	   			,"@E 999,999,999.99")))
			_oProcWF:oHtml:ValByName("cIr"		 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORIR:TEXT)		 			,"@E 999,999,999.99")))
			_oProcWF:oHtml:ValByName("cCsll"	 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORCSLL:TEXT)	  			,"@E 999,999,999.99")))
			_oProcWF:oHtml:ValByName("cOutRet"	 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_OUTRASRETENCOES:TEXT)			,"@E 999,999,999.99")))
			_oProcWF:oHtml:ValByName("cLiqNFSE"	 ,AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORLIQUIDONFSE:TEXT)			,"@E 999,999,999.99")))
		EndIf
		_oProcWF:oHtml:ValByName("cVlDeducao",AllTrim(Transform(Val(_oXmlRetNfse:_INFNFSE:_SERVICO:_VALORES:_VALORDEDUCOES:TEXT)			,"@E 999,999,999.99")))
	EndIf

	// mensagens adicionais
	If (Type("_oXmlRetNfse:_INFNFSE:_OUTRASINFORMACOES:TEXT")=="C")
		_oProcWF:oHtml:ValByName("cOutrasInf",EncodeUtf8(AllTrim(_oXmlRetNfse:_INFNFSE:_OUTRASINFORMACOES:TEXT)))
	Else
		_oProcWF:oHtml:ValByName("cOutrasInf","")
	EndIf

	// define o titulo do documento com o seguinte padrão: "RPSXXXXX NFSeXXXXXXXX" facilitando ao salvar o arquivo
	_oProcWF:oHtml:ValByName("cTitDocum","RPS" + _cNroRps + " NFSe" + _cNroNfse)

	// gera a nota, grava o html na pasta e retorna a identificação do processo
	_cRetID := _oProcWF:Start("\tecadi\nfse\")

	// define o nome do arquivo de retorno
	_cArqRet := "\tecadi\nfse\"
	// empresa e filial
	_cArqRet += "emp"+cEmpAnt+"\"+cFilAnt+"\"
	// informacoes do cliente
	_cArqRet += "cli_"+SF2->F2_CLIENTE+"_"+SF2->F2_LOJA+"_nfse_"+SF2->F2_DOC+"_serie_"+SF2->F2_SERIE+".htm"

	// verifica se o arquivo existe
	If (File(_cArqRet))
		// apaga o arquivo
		fErase(_cArqRet)
	EndIf

	// renomeia o arquivo gerado e muda de pasta
	fRename("\tecadi\nfse\"+_cRetID+".htm",_cArqRet)

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

	// gera arquivo XML
	If (mvGeraXML).and.(!Empty(_cXmlNfse))
		MemoWrit(StrTran(_cArqRet,".htm",".xml"),_cXmlNfse)
	EndIf

Return(_cArqRet)

// ** funcao para converte data (site) em formato data (protheus)
// ex site: 1984-12-12T00:00:00
Static Function sfCtoD(mvData,mvTipo)
	local _xRet
	// quando for tipo DATA
	If (mvTipo=="D")
		// extrai somente a data (10 primeiros) - resultado: 1984-12-12
		mvData := SubStr(mvData,1,10)
		// remove os separadores '-' (resultado: 19841212)
		mvData := StrTran(mvData,"-","")
		// converte String para Data (resultado: 12/12/1984)
		_xRet := StoD(mvData)
		// quando for tipo HORA
	ElseIf (mvTipo=="H")
		// extrai somente a hora (a partir da 12 posicao) - resultado: 00:00:00
		_xRet := SubS(mvData,12)
	EndIf
Return(_xRet)

// ** funcao para retornar o estado e municipio
Static Function sfRetMunic(mvCodIBGE,mvTipo)
	// area inicial
	local _aAreaIni := SaveOrd({"CC2"})
	// vetor com a UF e seus codigos
	local _aUF := {}
	// codigo da UF
	local _cCodUF := Left(mvCodIBGE,2)
	// codigo do municipio
	local _cCodMunic := SubS(mvCodIBGE,3)
	// variavel de retorno
	local mvRet := ""

	// alimenta o array com a UF
	aadd(_aUF,{"RO","11"})
	aadd(_aUF,{"AC","12"})
	aadd(_aUF,{"AM","13"})
	aadd(_aUF,{"RR","14"})
	aadd(_aUF,{"PA","15"})
	aadd(_aUF,{"AP","16"})
	aadd(_aUF,{"TO","17"})
	aadd(_aUF,{"MA","21"})
	aadd(_aUF,{"PI","22"})
	aadd(_aUF,{"CE","23"})
	aadd(_aUF,{"RN","24"})
	aadd(_aUF,{"PB","25"})
	aadd(_aUF,{"PE","26"})
	aadd(_aUF,{"AL","27"})
	aadd(_aUF,{"MG","31"})
	aadd(_aUF,{"ES","32"})
	aadd(_aUF,{"RJ","33"})
	aadd(_aUF,{"SP","35"})
	aadd(_aUF,{"PR","41"})
	aadd(_aUF,{"SC","42"})
	aadd(_aUF,{"RS","43"})
	aadd(_aUF,{"MS","50"})
	aadd(_aUF,{"MT","51"})
	aadd(_aUF,{"GO","52"})
	aadd(_aUF,{"DF","53"})
	aadd(_aUF,{"SE","28"})
	aadd(_aUF,{"BA","29"})
	aadd(_aUF,{"EX","99"})

	// busca a sigla do estado
	mvRet := _aUF[aScan(_aUF,{|x| (x[2] == _cCodUF)})][01]

	// se for retorno somente do Municipio
	If (mvTipo != "UF")
		// carrega a descricao do municipio
		dbSelectArea("CC2")
		CC2->(dbSetOrder(1)) // 1-CC2_FILIAL, CC2_EST, CC2_CODMUN
		If CC2->(dbSeek( xFilial("CC2")+mvRet+_cCodMunic ))
			// descricao
			mvRet := AllTrim(CC2->CC2_MUN)
		EndIf
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni)

Return(mvRet)

// ** funcao para realizar o cancelamento da nota fiscal de servico eletronica
User Function NFSE001E()
	Local _aPerg := {}
	Local _cParMnt := SM0->M0_CODIGO+SM0->M0_CODFIL+"NFSE001E"
	Local _aParam := {Space(Len(SF2->F2_SERIE)),Space(Len(SF2->F2_DOC)),Space(Len(SF2->F2_DOC)),ctod("//"),ctod("//"),Space(4)}
	Local _cNotasOk := ""


	// define o grupo de perguntas
	aadd(_aPerg,{1,"Serie da Nota Fiscal",_aParam[01],"",".T.","",".T.",30,.F.})
	aadd(_aPerg,{1,"Nota fiscal inicial",_aParam[02],"",".T.","",".T.",30,.T.})
	aadd(_aPerg,{1,"Nota fiscal final",_aParam[03],"",".T.","",".T.",30,.T.})
	aadd(_aPerg,{1,"Data Inicial",_aParam[04],"",".T.","",".T.",50,.T.})
	aadd(_aPerg,{1,"Data Final",_aParam[05],"",".T.","",".T.",50,.T.})
	aadd(_aPerg,{1,"Motivo de Cancelamento",_aParam[06],"",".T.","W1",".T.",30,.T.})

	// carrega as ultimas configuracoes
	_aParam[01] := ParamLoad(_cParMnt,_aPerg,1,_aParam[01])
	_aParam[02] := ParamLoad(_cParMnt,_aPerg,2,_aParam[02])
	_aParam[03] := ParamLoad(_cParMnt,_aPerg,3,_aParam[03])
	_aParam[04] := ParamLoad(_cParMnt,_aPerg,4,_aParam[04])
	_aParam[05] := ParamLoad(_cParMnt,_aPerg,5,_aParam[05])
	_aParam[06] := ParamLoad(_cParMnt,_aPerg,6,_aParam[06])

	// apresenta o grupo de perguntas
	If ParamBox(_aPerg," Cancelamento NFS-e",@_aParam,,,,,,,_cParMnt,.T.,.T.)

		Processa( {|| sfCancNfse(@_cNotasOk,mv_par06)}, "Aguarde...","(1/2) Verificando dados...", .T. )

		If Empty(_cNotasOk)
			Aviso("NFS-e","Nenhuma Nota foi Cancelada.",{"Ok"},3)
		Else
			Aviso("NFS-e","Notas Canceladas:" +CRLF+ _cNotasOk,{"Ok"},3)
		EndIf

	EndIf

Return

// ** funcao que realiza o cancelamento das notas selecionadas
Static Function sfCancNfse(_cNotasOk,mvMotCanc)
	local _cQrySF2
	local _cAliasSF2 := GetNextAlias()
	local _cChaveNFSe := ""

	// monta a query
	_cQrySF2 := "SELECT SF2.R_E_C_N_O_ SF2RECNO "
	// notas fiscais de saida
	_cQrySF2 += "FROM "+RetSqlName("SF2")+" SF2 "
	// filtro padrao
	_cQrySF2 += "WHERE "+RetSqlCond("SF2")+" "
	_cQrySF2 += "AND F2_SERIE   = '"+mv_par01+"' "
	_cQrySF2 += "AND F2_DOC     BETWEEN '"+mv_par02+"' AND '"+mv_par03+"' "
	// data de emssao
	_cQrySF2 += "AND F2_EMISSAO BETWEEN '"+DtoS(mv_par04)+"' AND '"+DtoS(mv_par05)+"' "
	// somente notas autorizadas
	_cQrySF2 += "AND F2_FIMP  = 'S' "
	// ordem dos dados
	_cQrySF2 += "ORDER BY F2_DOC"

	// executa a query
	DbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQrySF2),(_cAliasSF2),.F.,.F.)
	dbSelectArea(_cAliasSF2)

	// processa cada registro
	While (_cAliasSF2)->(!Eof())

		// posiciona no registro real da tabela
		dbSelectArea("SF2")
		SF2->(dbGoTo( (_cAliasSF2)->SF2RECNO ))

		// rotina para chamada do metodo de Cancelar Nfse
		_aRetWS := U_FtNfseWS("CancelarNfse", { SF2->F2_ZNFSE ,mvMotCanc} )

		// se for retorno valido, atualiza o status da nota
		If (_aRetWS[1])
			// funcao que atualiza o ultimo status da nota fiscal
			U_NFSE001C("C", .t., SF2->F2_FILIAL, SF2->F2_DOC, SF2->F2_SERIE, SF2->F2_CLIENTE, SF2->F2_LOJA, _aRetWS[2], _aRetWS[3], mvMotCanc)
			// atualiza cancelamento da nota
			_cNotasOk += SF2->F2_DOC+" / "+SF2->F2_SERIE

			// gera mensagem de erro de processamento
		ElseIf (!_aRetWS[1])
			// funcao que atualiza o ultimo status da nota fiscal
			U_NFSE001C(" ", .f., SF2->F2_FILIAL, SF2->F2_DOC, SF2->F2_SERIE, SF2->F2_CLIENTE, SF2->F2_LOJA, _aRetWS[2], _aRetWS[3], mvMotCanc)

		EndIf

		// proximo registro
		dbSelectArea(_cAliasSF2)
		dbSkip()
	EndDo

	// fecha a query
	dbSelectArea(_cAliasSF2)
	dbCloseArea()

Return

// ** funcao para apresentar a leganda
User Function NFSE001L()
	Local _aLegenda := {}

	Aadd(_aLegenda, {"ENABLE"    ,"NF autorizada"})
	Aadd(_aLegenda, {"DISABLE"   ,"NF não transmitida"})
	Aadd(_aLegenda, {"BR_AZUL"   ,"NF Transmitida"})
	Aadd(_aLegenda, {"BR_PRETO"  ,"NF nao autorizada"})
	Aadd(_aLegenda, {"BR_CINZA"  ,"NF Uso Denegado"})
	Aadd(_aLegenda, {"BR_LARANJA","NF Cancelada"})

	BrwLegenda(cCadastro,"Legenda",_aLegenda)

Return(.T.)

// ** funcao que detalha o Schema do XML da nota fiscal
Static Function sfDetSchema(mvIdNfse, mvTipo, mvVldSchema)
	// codigo do municipio
	Local _cCodMun := SM0->M0_CODMUN
	// URL do TSS
	Local _cURL := PadR(GetNewPar("MV_SPEDURL","http://"),250)
	// objeto de execucao do WebService
	Local _oWsNfse
	// xml de retorno
	Local _cXmlRet := ""

	// conteudo padrao
	DEFAULT mvTipo      := 1
	DEFAULT mvIdNfse    := ""
	DEFAULT mvVldSchema := .f.

	// caso executado do menu, a variável cIdEnt não passou pelo TSS e não existe, então obtenho o ID da entidade para continuar
	If type("cIdEnt") == "U"
		cIdEnt := RetIdEnti()
	EndIf
	
	// metodo para conectar no WebService
	_oWsNfse := WsNFSE001():New()
	_oWsNfse:cUSERTOKEN            := "TOTVS"
	_oWsNfse:cID_ENT               := cIdEnt
	_oWsNfse:cCodMun               := _cCodMun
	_oWsNfse:_URL                  := AllTrim(_cURL)+"/NFSE001.apw"
	_oWsNfse:nDIASPARAEXCLUSAO     := 0
	_oWsNfse:OWSNFSEID:OWSNOTAS    := NFSe001_ARRAYOFNFSESID1():New()

	aadd(_oWsNfse:OWSNFSEID:OWSNOTAS:OWSNFSESID1,NFSE001_NFSES1():New())
	_oWsNfse:OWSNFSEID:OWSNOTAS:OWSNFSESID1[1]:CCODMUN        := _cCodMun
	_oWsNfse:OWSNFSEID:OWSNOTAS:OWSNFSESID1[1]:cID            := mvIdNfse
	_oWsNfse:OWSNFSEID:OWSNOTAS:OWSNFSESID1[1]:cXML           := " "
	_oWsNfse:OWSNFSEID:OWSNOTAS:OWSNFSESID1[1]:CNFSECANCELADA := " "

	// executa metodo de retorno de informacoes da Nfs-e - RETORNANFSE
	If ExecWSRet(_oWsNfse,"RETORNANFSE")
		// verifica se ha informacoes do retorno
		If ( Len(_oWsNfse:oWsRetornaNfseResult:OWSNOTAS:OWSNFSES5) > 0 )
			// tipo validacao de cancelamento
			If (mvTipo == 1)
				Do Case
					Case _oWsNfse:oWsRetornaNfseResult:OWSNOTAS:OWSNFSES5[1]:oWSNFECANCELADA <> Nil
					Aviso("NFSE",_oWsNfse:oWsRetornaNfseResult:OWSNOTAS:OWSNFSES5[1]:oWSNFECANCELADA:cXML,{"Neste momento o Totvs Services SPED, está operando com a seguinte configuração: "},3)
					OtherWise
					Aviso("NFSE",_oWsNfse:oWsRetornaNfseResult:OWSNOTAS:OWSNFSES5[1]:oWSNFE:cXMLERP,{"Neste momento o Totvs Services SPED, está operando com a seguinte configuração: "},3)
				EndCase
				// tratamento de verificacao de notas validas
			Else
				// XML de retorno
				If (mvVldSchema)
					_cXmlRet := AllTrim(_oWsNfse:oWsRetornaNfseResult:OWSNOTAS:OWSNFSES5[1]:oWSNFE:cXMLERP)
				ElseIf ( ! mvVldSchema)
					_cXmlRet := AllTrim(_oWsNfse:oWsRetornaNfseResult:OWSNOTAS:OWSNFSES5[1]:oWSNFE:CXMLPROT)
				EndIf

				// apresenta mensagem ao validar o XML
				If ( ! Empty(_cXmlRet)).and.(mvVldSchema)

					Aviso("NFSE",@_cXmlRet,{"ok"},3,/*cCaption2*/,/*nRotAutDefault*/,/*cBitmap*/,.T.)
					_oWsNfse := WsNFSE001():New()
					_oWsNfse:cUSERTOKEN     := "TOTVS"
					_oWsNfse:cID_ENT        := cIdEnt
					_oWsNfse:cCodMun        := _cCodMun

					_oWsNfse:oWsNF:oWSNOTAS:=  NFSE001_ARRAYOFNF001():New()
					aadd(_oWsNfse:oWsNF:oWSNOTAS:OWSNF001,NFSE001_NF001():New())

					_oWsNfse:oWsNF:oWSNOTAS:oWSNF001[1]:CID  := mvIdNfse
					_oWsNfse:oWsNF:oWSNOTAS:oWSNF001[1]:Cxml := EncodeUtf8(_cXmlRet)
					_oWsNfse:_URL                            := AllTrim(_cURL)+"/NFSE001.apw"

					// executa metodo que valida Schema
					If ExecWSRet(_oWsNfse,"SchemaX")
						If Empty(_oWsNfse:OWSSCHEMAXRESULT:OWSNFSES4[1]:cMENSAGEM)
							Aviso("NFSE","Schema valido",{"Ok"})
						Else
							Aviso("NFSE",IIF(Empty(_oWsNfse:OWSSCHEMAXRESULT:OWSNFSES4[1]:cMENSAGEM),"Schema valido",_oWsNfse:OWSSCHEMAXRESULT:OWSNFSES4[1]:cMENSAGEM),{"Ok"},3)
						EndIf
					Else
						Aviso("NFSE",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"Ok"},3)
					EndIf
				EndIf
			EndIf
		EndIf
	Else
		Aviso("NFSE",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"Ok"},3)
	EndIf

Return(EncodeUtf8(_cXmlRet))
