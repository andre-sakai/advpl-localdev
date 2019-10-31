#Include "Totvs.ch"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "RPTDEF.CH"
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Envio de Nota Fiscal de Serviços Eletronica - NFS-e ao  !
!                  ! cliente através de e-mail                               !
!                  ! Prefeitura de Itajai-SC (sistema: Publica informatica)  !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 03/2012                                                 !
+------------------+--------------------------------------------------------*/

User Function TNFSE002
	// grupo de perguntas
	local _aPerg := {}
	// cores do browse
	Local _aCoresBrw := {}
	// controle de filtro de browse
	Local _aIndArq := {}

	// parametro do browse
	Local cParBrw := SM0->M0_CODIGO+SM0->M0_CODFIL+"TNFSE002"

	// filtro da serie liberado da nota fiscal de servicos
	private _cRpsSerie := AllTrim(SuperGetMV('TC_RPSSERI',.F.,"ISS/IS1"))
	// condicao do filtro dos dados
	private _cCondicao := ""
	private _bFiltraBrw
	// opcoes do browse
	private aRotina := {{"Pesquisar"		,"AxPesqui",0,1,0,.F.},;
	{"Visualiza Doc."	,"Mc090Visual('SF2',SF2->(RecNo()),1)",0,2,0 ,NIL},;
	{"Enviar Dados"		,"U_NFSE002A()",0,2,0 ,NIL},;
	{"Anexar Arquivos"	,"U_NFSE002B()",0,2,0 ,NIL},;
	{"Consultar Anexos"	,"U_NFSE002C()",0,2,0 ,NIL},;
	{"Consultar Log"	,"U_NFSE002D()",0,2,0 ,NIL},;
	{"Legenda"			,"U_NFSE002L()",0,2,0 ,NIL}}

	// titulo da tela
	private cCadastro := "Envio de e-mail com os dados das NFS-e Itajaí"

	// Montagem das perguntas
	aadd(_aPerg,{2,"Tipo de NFS-e",PadR("",Len("2-Entrada")),{"1-Saída"},100,".T.",.T.,".T."})
	aadd(_aPerg,{2,"Filtra",PadR("",Len("2-Não Enviadas")),{"1-Enviadas","2-Não Enviadas","3-Ambas"},100,".T.",.T.,".T."})

	// verifica se o serviço foi configurado - Somente o Adm pode configurar
	If ParamBox(_aPerg,"NFS-e Itajaí",,,,,,,,cParBrw,.T.,.T.)

		// define as cores do browse
		_aCoresBrw := {	{"Empty(F2_ZENVNFS) ",'DISABLE'},;	//NF não enviadas ao cliente
		{"F2_ZENVNFS == 'S'",'ENABLE' },;  //NF enviadas ao cliente
		{"F2_ZENVNFS == 'F'",'BR_CANCEL' }}	

		// realiza a Filtragem
		_cCondicao := "F2_FILIAL=='"+xFilial("SF2")+"'"
		// serie
		_cCondicao += ".AND.F2_SERIE $ '"+_cRpsSerie+"'"

		// condicao da nota / 1-NF Autorizada
		_cCondicao += ".AND. ( (ALLTRIM(F2_ESPECIE) == 'NFS' .AND. F2_FIMP == 'S').OR.(ALLTRIM(F2_ESPECIE) == 'FTL') )"
		// condição para trazer os recibos (Faturas de locação)

		// condicao do envio de informacoes
		// "1-Enviadas"
		If (SubStr(MV_PAR02,1,1) == "1")
			_cCondicao += ".AND. F2_ZENVNFS == 'S' "
			// "2-Não Enviadas"
		ElseIf (SubStr(MV_PAR02,1,1) == "2")
			_cCondicao += ".AND. F2_ZENVNFS != 'S' "
		EndIf

		// monta o bloco do filtro
		_bFiltraBrw := {|| FilBrowse("SF2",@_aIndArq,@_cCondicao) }
		Eval(_bFiltraBrw)

		// demonstra os dados filtrados
		mBrowse( 6, 1,22,75,"SF2",,,,,,_aCoresBrw,/*cTopFun*/,/*cBotFun*/,/*nFreeze*/,/*bParBloco*/,/*lNoTopFilter*/,.F.,.F.,)

		// restaura a integridade da rotina
		dbSelectArea("SF2")
		RetIndex("SF2")
		dbClearFilter()
		aEval(_aIndArq,{|x| Ferase(x[1]+OrdBagExt())})

	EndIf

Return(.f.)

// ** funcao para apresentar a leganda
User Function NFSE002L()
	Local _aLegenda := {}

	Aadd(_aLegenda, {"ENABLE"    ,"NF enviada"})
	Aadd(_aLegenda, {"DISABLE"   ,"NF não enviada"})
	Aadd(_aLegenda, {"BR_CANCEL" ,"Erro ao enviar NF"})

	BrwLegenda(cCadastro,"Legenda",_aLegenda)

Return(.T.)

// ** funcao para enviar as informacoes das notas fiscais por email para o cliente
User Function NFSE002A
	// area inicial
	local _aAreaIni := SaveOrd({"SF2"})
	// grupo de perguntas
	Local _aPerg := {}
	Local _cPerg := PadR("NFSE002A",10)
	// controle da query
	local _cAliasSF2
	// path dos arquivos
	local _cPathAnexo := ""
	// anexos do email
	local _aAnexos := {}
	// mensagem
	local _cCorpoMail := ""
	//Nome do arquivo Boleto.PDF
	Local _cArquiPDF := ""
	//Arquivos do cliente para ser enviado por e-mail.
	Local _cArquiEnv := ""
	// variveis temporarios
	local _aTmpArq := {}
	local _nArq

	// arquivos anexados
	local _lAnxBol := .f.
	local _lAnxMpPed := .f.
	local _lAnxMpPro := .f.
	local _lAnxMpMov := .f.
	local _lAnxPreNf := .f.

	// retorno do envio correto do e-mail
	local _lMailOk := .f.

	// texto do Log
	local _cTextoLog

	// informacao complementar da programacao do cliente
	local _cInfCompl := ""

	// variavel de pasta
	local _cTipoArq := ""

	local _cRELPSW

	// criacao das Perguntas
	aAdd(_aPerg,{"Serie ?" ,"C",TamSx3("F2_SERIE")[1],0,"G",,""}) //mv_par01
	aAdd(_aPerg,{"Nota Fiscal De ?" ,"C",TamSx3("F2_DOC")[1],0,"G",,"SF2"}) //mv_par02
	aAdd(_aPerg,{"Nota Fiscal Até ?" ,"C",TamSx3("F2_DOC")[1],0,"G",,"SF2"}) //mv_par03
	aAdd(_aPerg,{"Cliente De ?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par04
	aAdd(_aPerg,{"Cliente Até ?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par05
	aAdd(_aPerg,{"Loja De ?" ,"C",TamSx3("A1_LOJA")[1],0,"G",,""}) //mv_par06
	aAdd(_aPerg,{"Loja Até ?" ,"C",TamSx3("A1_LOJA")[1],0,"G",,""}) //mv_par07
	aAdd(_aPerg,{"Dt. Emissão De ?" ,"D",8,0,"G",,""}) //mv_par08
	aAdd(_aPerg,{"Dt. Emissão Até ?" ,"D",8,0,"G",,""}) //mv_par09
	aAdd(_aPerg,{"Reenvio?" ,"N",1,0,"C",{"Sim","Não"},""}) //mv_par10

	// cria grupo de perguntas
	U_FtCriaSX1( _cPerg,_aPerg )

	// apresenta o grupo de perguntas
	If ! Pergunte(_cPerg,.T.)
		Return ()
	EndIf

	// cria alias da query
	_cAliasSF2 := GetNextAlias()

	_cQrySF2 := "SELECT SF2.R_E_C_N_O_ SF2RECNO "
	// notas fiscais de saida
	_cQrySF2 += "FROM "+RetSqlName("SF2")+" SF2 "
	// filtro padrao
	_cQrySF2 += "WHERE "+RetSqlCond("SF2")+" "
	_cQrySF2 += "AND F2_SERIE   = '"+mv_par01+"' "
	_cQrySF2 += "AND F2_DOC     BETWEEN '"+mv_par02+"' AND '"+mv_par03+"' "
	_cQrySF2 += "AND F2_CLIENTE BETWEEN '"+mv_par04+"' AND '"+mv_par05+"' "
	_cQrySF2 += "AND F2_LOJA    BETWEEN '"+mv_par06+"' AND '"+mv_par07+"' "
	_cQrySF2 += "AND F2_EMISSAO BETWEEN '"+DtoS(mv_par08)+"' AND '"+DtoS(mv_par09)+"' "
	// somente o que esta autorizada
	_cQrySF2 += "AND ( (F2_ESPECIE = 'NFS' AND F2_FIMP = 'S') OR (F2_ESPECIE = 'FTL') )  "
	// valida status de enviadas
	If (mv_par10 == 1)
		_cQrySF2 += "AND F2_ZENVNFS  = 'S' "
	ElseIf (mv_par10 == 2)
		_cQrySF2 += "AND F2_ZENVNFS != 'S' "
	EndIf
	// ordem dos dados
	_cQrySF2 += "ORDER BY F2_DOC"

	_cRELPSW := AllTrim(GetMV("MV_RELPSW"))

	// executa a query
	DbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQrySF2),(_cAliasSF2),.F.,.F.)
	dbSelectArea(_cAliasSF2)

	// processa cada registro, incluindo na relacao de notas do lote
	While (_cAliasSF2)->(!Eof())

		// valido de qual pasta os arquivos serão informados
		If (ALLTRIM(SF2->F2_ESPECIE) == "FTL")
			_cTipoArq := "fatura"
		ElseIf (ALLTRIM(SF2->F2_ESPECIE) == "NFS")
			_cTipoArq := "nfse"
		EndIf

		// define o caminho da pasta
		_cPathAnexo := "\tecadi\"+_cTipoArq+"\emp"+cEmpAnt+"\"+cFilAnt+"\"

		// posiciona no registro real da tabela
		dbSelectArea("SF2")
		SF2->(dbGoTo( (_cAliasSF2)->SF2RECNO ))

		//Posiciona ITENS DE VENDA DA NF
		dbSelectArea("SD2")
		SD2->(dbSetOrder(3))// 3 - D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
		SD2->(dbSeek(SF2->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA) ))

		//Posiciona CABEÇALHO PEDIDO DE VENDA
		dbSelectArea("SC5")
		SC5->(dbSetOrder(1))
		SC5->(dbSeek(SD2->(D2_FILIAL+D2_PEDIDO)))

		// zera os anexos do email
		_aAnexos := {}

		// posiciona no cadastro de cliente
		dbSelectArea("SA1")
		SA1->(dbSetOrder(1)) //1-A1_FILIAL, A1_COD, A1_LOJA
		SA1->(dbSeek( xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA) ))

		// verifica o email do cliente
		If (Empty(SA1->A1_ZNFSE))
			// apresenta mensagem de erro
			If (_cTipoArq == "nfse")
				Aviso("NFS-e","O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+AllTrim(SA1->A1_NOME)+" não possui e-mail cadastrado para recebimento de nota fiscal de serviços eletrônica.",{"Ok"},3)
			ElseIf (_cTipoArq == "fatura")
				Aviso("Fatura de Locação","O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+AllTrim(SA1->A1_NOME)+" não possui e-mail cadastrado para recebimento da Fatura de Locação (Recibo).",{"Ok"},3)
			EndIf

			dbSelectArea(_cAliasSF2)
			(_cAliasSF2)->(dbSkip())
			Loop
		EndIf

		// zera variaveis
		_lAnxBol	:= .f.
		_lAnxMpPed	:= .f.
		_lAnxMpPro	:= .f.
		_lAnxMpMov	:= .f.
		_lAnxPreNf	:= .f.
		_lMailOk	:= .f.

		If !(Empty(SA1->A1_ZTPARQU))
			_cArquiEnv := SA1->A1_ZTPARQU
		EndIf

		// gera o arquivo da nota fiscal
		// valida a espécie para diferenciar as faturas de locação
		If (_cTipoArq == 'nfse')

			U_NFSE001F(.f.,.t.)
			//_cPathAnexo := "C:\rel\"

			//Boleto Bancário
			If ("1" $ _cArquiEnv)
				//Nome do Arquivo
				_cArquiPDF:= "cli_"+SF2->F2_CLIENTE+"_"+SF2->F2_LOJA+"_"+_cTipoArq+"_"+SF2->F2_DOC+"_serie_"+SF2->F2_SERIE+"_boleto"
				//Função para geração do Boleto em PDF e salva no servidor para anexo.
				Processa({||U_TFIN001A(SF2->F2_SERIE,SF2->F2_SERIE,SF2->F2_DOC,SF2->F2_DOC,"  ","ZZ",,,,,_cPathAnexo,_cArquiPDF,.T.,.T.) },"Boleto Bancário")
			EndIf

			//Mapa Fat. por Pedido
			If ("2" $ _cArquiEnv)
				//Nome do Arquivo
				_cArquiPDF:= "cli_"+SF2->F2_CLIENTE+"_"+SF2->F2_LOJA+"_"+_cTipoArq+"_"+SF2->F2_DOC+"_serie_"+SF2->F2_SERIE+"_MAPA_PEDIDO"
				Processa({||U_WMSR004A(SD2->D2_PEDIDO,SD2->D2_PEDIDO,SF2->F2_CLIENTE,SF2->F2_CLIENTE,SF2->F2_LOJA,SF2->F2_LOJA,SC5->C5_EMISSAO,SC5->C5_EMISSAO,.T.,1,_cPathAnexo,_cArquiPDF)},"Mapa Fat. por Pedido")
			EndIf

			//Mapa Fat. por Processo
			If ("3" $ _cArquiEnv)
				//Nome do Arquivo
				_cArquiPDF:= "cli_"+SF2->F2_CLIENTE+"_"+SF2->F2_LOJA+"_"+_cTipoArq+"_"+SF2->F2_DOC+"_serie_"+SF2->F2_SERIE+"_MAPA_PROCESSO"
				Processa({||U_FATR003A(SC5->C5_ZPROCES,1,.T.,1,_cPathAnexo,_cArquiPDF)},"Mapa Fat. por Processo")
			EndIf

			//Mapa Movim. de Produto
			If ("4" $ _cArquiEnv)

				//CABECALHO MOVIMENTACAO CONTRAT
				dbSelectArea("SZR")
				SZR->(dbSetOrder(2)) // 2 - ZR_FILIAL+ZR_PEDIDO+ZR_ITEPEDI
				If (SZR->(dbSeek( xFilial("SZR") + SD2->(D2_PEDIDO) )))
					//Nome do Arquivo
					_cArquiPDF:= "cli_"+SF2->F2_CLIENTE+"_"+SF2->F2_LOJA+"_"+_cTipoArq+"_"+SF2->F2_DOC+"_serie_"+SF2->F2_SERIE+"_MAPA_MOV_PRODUTO"
					Processa({||U_TWMSR006(.T.,.T.,_cPathAnexo,_cArquiPDF,SZR->ZR_PROGRAM)},"Mapa Movim. de Produto")
				EndIf
			EndIf

			//Pré-Nota
			If ("5" $ _cArquiEnv)
				//Nome do Arquivo
				_cArquiPDF:= "cli_"+SF2->F2_CLIENTE+"_"+SF2->F2_LOJA+"_"+_cTipoArq+"_"+SF2->F2_DOC+"_serie_"+SF2->F2_SERIE+"_PRE_NOTA"
				Processa({||U_TFATR005(.T.,_cPathAnexo,_cArquiPDF,SC5->C5_NUM,SC5->C5_EMISSAO,SF2->F2_CLIENTE,SF2->F2_LOJA)},"Pré Nota")
			EndIf

		ElseIf (_cTipoArq == 'fatura')
			U_FATR004A(.f.)
		EndIf

		//MsgStop(_cPathAnexo)

		// adiciona o arquivo
		_aTmpArq := Directory(_cPathAnexo+"cli_"+SF2->F2_CLIENTE+"_"+SF2->F2_LOJA+"_"+_cTipoArq+"_"+SF2->F2_DOC+"_serie_"+SF2->F2_SERIE+"*.*")

		// anexa os arquivos
		For _nArq := 1 to Len(_aTmpArq)
			// inclui o anexo
			aAdd(_aAnexos,_cPathAnexo+_aTmpArq[_nArq,1])
			// atualiza os anexos selecionados
			If ("BOLETO" $ Upper(_aTmpArq[_nArq,1]))
				_lAnxBol := .t.
			ElseIf ("MAPA_PEDIDO" $ Upper(_aTmpArq[_nArq,1]))
				_lAnxMpPed := .t.
			ElseIf ("MAPA_PROCESSO" $ Upper(_aTmpArq[_nArq,1]))
				_lAnxMpPro := .t.
			ElseIf ("MAPA_MOV_PRODUTO" $ Upper(_aTmpArq[_nArq,1]))
				_lAnxMpMov := .t.
			ElseIf ("PRE_NOTA" $ Upper(_aTmpArq[_nArq,1]))
				_lAnxPreNf := .t.
			EndIf
		Next _nArq

		// busca informacao complementar da programacao do cliente
		_cInfCompl := sfRetInfProc(SF2->F2_CLIENTE, SF2->F2_LOJA, SF2->F2_DOC, SF2->F2_SERIE)

		// gera o email com as informacoes
		If (_cTipoArq == 'nfse')
			// monta o texto da mensagem para envio ao cliente

			_cCorpoMail := sfMontaMail(_lAnxBol, _lAnxMpPed, _lAnxMpPro, _lAnxMpMov, _lAnxPreNf, _cInfCompl, .F.)
			_lMailOk := U_FtMail( _cCorpoMail,;
			AllTrim(SM0->M0_NOMECOM)+" - RPS "+AllTrim(SF2->F2_DOC)+" / NFS-e "+AllTrim(SF2->F2_NFELETR)+IIF(mv_par10==1," (2a via)",""),;
			AllTrim(SA1->A1_ZNFSE),;
			_aAnexos,;
			"nfse@tecadi.com.br",;
			_cRELPSW,;
			"nfse@tecadi.com.br")

		ElseIf (_cTipoArq == 'fatura')

			// monta o texto da mensagem para envio ao cliente
			_cCorpoMail := sfMontaMail(_lAnxBol, _lAnxMpPed, _lAnxMpPro, _lAnxMpMov, _lAnxPreNf, _cInfCompl, .T.)

			_lMailOk := U_FtMail( _cCorpoMail,;
			AllTrim(SM0->M0_NOMECOM)+" - Fatura de Locação "+AllTrim(SF2->F2_DOC)+IIF(mv_par10==1," (2a via)",""),;
			AllTrim(SA1->A1_ZNFSE),;
			_aAnexos,;
			"nfse@tecadi.com.br",;
			_cRELPSW,;
			"nfse@tecadi.com.br")
		EndIf

		// confere o envio correto do e-mail
		If (_lMailOk)
			// atualiza o status da nota
			dbSelectArea("SF2")
			RecLock("SF2")
			SF2->F2_ZENVNFS := "S"
			MsUnLock()

			// prepara o texto do Log
			_cTextoLog := "Realizado o "+IIF(mv_par10==1,"Re","")+"envio dos arquivos de "+IIF(_cTipoArq == "nfse","Nota Fiscal, Arquivo XML","Fatura de Locação")
			_cTextoLog += If(_lAnxBol	,", Boleto Bancário","")
			_cTextoLog += If(_lAnxMpPed	,", Mapa Fat. por Pedido","")
			_cTextoLog += If(_lAnxMpPro	,", Mapa Fat. por Processo","")
			_cTextoLog += If(_lAnxMpMov	,", Mapa Movim. de Produto","")
			_cTextoLog += If(_lAnxPreNf	,", Pré-Nota","")
			_cTextoLog += " para o e-mail: "+AllTrim(SA1->A1_ZNFSE)

			// gera o Log de envio
			U_FtGeraLog(cFilAnt, "SF2", SF2->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA),_cTextoLog,"FAT","")

			// erro no envio do e-mail
		ElseIf (!_lMailOk)
			// atualiza o status da nota
			dbSelectArea("SF2")
			RecLock("SF2")
			SF2->F2_ZENVNFS := "N"
			MsUnLock()

			// gera o Log de envio
			U_FtGeraLog(cFilAnt, "SF2", SF2->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA),"Erro no envio do e-mail. Endereço: "+AllTrim(SA1->A1_ZNFSE),"FAT","")

		EndIf

		// proxima nota
		dbSelectArea(_cAliasSF2)
		(_cAliasSF2)->(dbSkip())
	EndDo

	// fecha alias da query
	dbSelectArea(_cAliasSF2)
	dbCloseArea()

	// restaura areas iniciais
	RestOrd(_aAreaIni)

Return

// ** funcao que monta o texto da mensagem para envio ao cliente
Static Function sfMontaMail(mvAnxBol, mvAnxMpPed, mvAnxMpPro, mvAnxMpMov, mvAnxPreNf, mvInfCompl, mvFatura)
	local _cRetMsg := ""
	Local _cChave := AllTrim( If( !Empty(SF2->F2_ZCODVER),SF2->F2_ZCODVER,SF2->F2_CODNFE) )

	// ajusta a chave, caso não tenha o separador para Itajaí
	If (SM0->M0_CODMUN == "4208203") .AND. ( Substr(_cChave,5,1) != "-" )
		_cChave := Transform( _cChave, "@R XXXX-XXXX")
	EndIf

	_cRetMsg := '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
	_cRetMsg += '<html xmlns="http://www.w3.org/1999/xhtml">'
	_cRetMsg += '<head>'
	_cRetMsg += '<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />'
	_cRetMsg += '<style type="text/css">'
	_cRetMsg += '<!--'
	_cRetMsg += '.titulo {'
	_cRetMsg += '	font-family: Calibri;'
	_cRetMsg += '	font-size: 14px;'
	_cRetMsg += '	font-style: normal;'
	_cRetMsg += '	font-weight: bold;'
	_cRetMsg += '	background-color: #788EA7;'
	_cRetMsg += '	color: #000000;'
	_cRetMsg += '}'
	_cRetMsg += '.sub_titulo {'
	_cRetMsg += '	font-family: Calibri;'
	_cRetMsg += '	font-size: 14px;'
	_cRetMsg += '	font-style: normal;'
	_cRetMsg += '	font-weight: bold;'
	_cRetMsg += '	background-color: #ECF0EE;'
	_cRetMsg += '	color: #000000;'
	_cRetMsg += '}'
	_cRetMsg += '.linha {'
	_cRetMsg += '	font-family: Calibri;'
	_cRetMsg += '	font-size: 14px;'
	_cRetMsg += '	font-style: normal;'
	_cRetMsg += '	color: #000000;'
	_cRetMsg += '	background-color: #F7F9F8;'
	_cRetMsg += '}'
	_cRetMsg += '.linha_branco {'
	_cRetMsg += '	font-family: Calibri;'
	_cRetMsg += '	font-size: 3px;'
	_cRetMsg += '	font-style: normal;'
	_cRetMsg += '	color: #FFFFFF;'
	_cRetMsg += '	background-color: #FFFFFF;'
	_cRetMsg += '}'
	_cRetMsg += '.rodape {'
	_cRetMsg += '	font-family: Calibri;'
	_cRetMsg += '	font-size: 10px;'
	_cRetMsg += '	font-style: normal;'
	_cRetMsg += '	font-weight: bold;'
	_cRetMsg += '	background-color: #ECF0EE;'
	_cRetMsg += '	color: #000000;'
	_cRetMsg += '}'

	_cRetMsg += '-->'
	_cRetMsg += '</style>'
	_cRetMsg += '</head>'

	_cRetMsg += '<body>'
	_cRetMsg += '<table width="600" border="1" align="center" cellpadding="2" cellspacing="1" class="linha" style="border-collapse: collapse" bordercolor="#000000">'

	// titulo da mensagem
	_cRetMsg += '  <tr>'
	_cRetMsg += '    <td class="titulo">'+IIF(mvFatura,"Fatura de Locação","Nota Fiscal de Serviços - Eletrônica")+'</td>'
	_cRetMsg += '  </tr>'

	// texto da mensagem
	_cRetMsg += '  <tr>'
	_cRetMsg += '    <td class="linha">'

	_cRetMsg += '<br>'
	_cRetMsg += 'Prezado Cliente, '+'<br>'
	_cRetMsg += '<br>'
	_cRetMsg += 'Você está recebendo informações da '+IIF(mvFatura,'Fatura de Locação número '+SF2->F2_DOC+', série '+SF2->F2_SERIE+' de '+AllTrim(SM0->M0_NOMECOM),'Nota Fiscal de Serviços - Eletrônica, RPS número '+SF2->F2_DOC+', série '+SF2->F2_SERIE+' de '+AllTrim(SM0->M0_NOMECOM))+'.<br>'
	_cRetMsg += '<br>'
	// informacoes dos anexos
	_cRetMsg += '- '+IIF(mvFatura, 'Fatura de Locação','Nota Fiscal de Serviços - Eletrônica (NFS-e)')+'<br>'
	_cRetMsg += IIF(mvFatura,'','- Arquivo XML da Nota Fiscal de Serviços - Eletrônica (NFS-e)')+'<br>'
	_cRetMsg += IIF(mvAnxBol   ,'- Boleto bancário'+'<br>','')
	_cRetMsg += IIF(mvAnxMpPed ,'- Mapa de Faturamento por Pedido'+'<br>','')
	_cRetMsg += IIF(mvAnxMpPro ,'- Mapa de Faturamento por Processo'+'<br>','')
	_cRetMsg += IIF(mvAnxMpMov ,'- Mapa de Movimentação de Produtos'+'<br>','')
	_cRetMsg += IIF(mvAnxPreNf ,'- Pré-Nota'+'<br>','')
	_cRetMsg += '<br>'

	// informacoes sobre o processo do cliente
	If ( ! Empty(mvInfCompl))
		_cRetMsg += '<strong>'+mvInfCompl+'</strong>'
		_cRetMsg += '<br><br>'
	EndIf

	// Se não for fatura, mostra os dados das NFSE
	If ( ! mvFatura)

		_cRetMsg += 'Para se certificar que esta NFS-e é válida, queira por favor consultar sua autenticidade no site da prefeitura de '
		// municipio de Itajai-SC
		If (SM0->M0_CODMUN == "4208203")
			_cRetMsg += 'Itajaí-SC (https://nfse.itajai.sc.gov.br/jsp/nfs/nfp/externo/consulta.jsp)'
			// Curitiba-PR
		ElseIf (SM0->M0_CODMUN == "4106902")
			_cRetMsg += 'Curitiba-PR (https://isscuritiba.curitiba.pr.gov.br/NotaCuritibana/NotaRPS/AutenticidadeNota)'
		EndIf
		_cRetMsg += ', utilizando os dados abaixo, ou através do link direto '

		// municipio de Itajai-SC
		If (SM0->M0_CODMUN == "4208203")
			_cRetMsg += '<a href="https://nfse.itajai.sc.gov.br/jsp/nfs/nfp/externo/consulta.jsp?numero='+SF2->F2_NFELETR+'&serie=A1&cnpj_cpf='+SM0->M0_CGC+'&chave_validacao=' + _cChave + '">clique aqui</a>' + '<br>'
			// Curitiba-PR
		ElseIf (SM0->M0_CODMUN == "4106902")
			_cRetMsg += '<a href="https://isscuritiba.curitiba.pr.gov.br/NotaCuritibana/NotaRPS/AutenticidadeNota?doc='+SM0->M0_CGC+'&num='+AllTrim(SF2->F2_NFELETR)+'&cod='+AllTrim(SF2->F2_CODNFE)+'">clique aqui</a>'+'<br>'
		EndIf

		_cRetMsg += '<br>'
		_cRetMsg += 'CPNJ: '+Transform(SM0->M0_CGC,"@R 99.999.999/9999-99")+'<br>'
		_cRetMsg += 'Número da NFS-e: '+SF2->F2_NFELETR+'<br>'
		_cRetMsg += 'Chave de Verificação: ' + _cChave + '<br>'
		_cRetMsg += '<br>'
		_cRetMsg += '<br>'
		_cRetMsg += 'Atenciosamente,'+'<br>'
		_cRetMsg += AllTrim(SM0->M0_NOMECOM)+'<br>'
		_cRetMsg += AllTrim(SM0->M0_CIDCOB)+' - '+AllTrim(SM0->M0_ESTCOB)+'<br>'
		_cRetMsg += '<br>'

	EndIf

	_cRetMsg += '    </td>'
	_cRetMsg += '  </tr>'

	// linha em branco antes do rodapé
	_cRetMsg += '  <tr>'
	_cRetMsg += '    <td class="linha_branco">&nbsp;</td>'
	_cRetMsg += '  </tr>'
	// rodape
	_cRetMsg += '  <tr>'
	_cRetMsg += '    <td class="rodape" align="center">Mensagem gerada automaticamente através do emissor de '+IIF(mvFatura,'Faturas Tecadi','NFS-e Tecadi')+', favor não responder este e-mail.</td>'
	_cRetMsg += '  </tr>'
	_cRetMsg += '</table>'
	_cRetMsg += '</body>'
	_cRetMsg += '</html>'

Return(_cRetMsg)

// ** funcao para anexar arquivos na nota fiscal
User Function NFSE002B
	// arquivo selecionado
	local _cArquivo := ""
	// opcoes
	Local _aOpcoes := {"1-Boleto","2-Mapa Faturamento por Pedido","3-Mapa Faturamento por Processo","4-Mapa de Movim. de Produtos","5-Pre-Nota"}
	Local _cOpcoes := ""
	// controle da confirmacao
	Local _lOk := .f.
	// pasta de destino
	local _cPathDest
	// arquivo de retorno
	local _cArqRet
	local _cTipoArq
	local _cNomArq
	// variveis temporarias
	local _cTmpNome := ""
	local _cTmpExt := ""
	// variavel pra verificacao de fatura ou nfse
	local _cTipoDoc := ""

	// definicao da tela
	_oDlgOpcEnt := MSDialog():New(000,000,120,300,"Opções de Documentos...",,,.F.,,,,,,.T.,,,.T. )
	// opcoes de entrada
	_oSayOpcoes := TSay():New(010,010,{||"Selecione a opção:"},_oDlgOpcEnt,,,.F.,.F.,.F.,.T.)
	_oGetOpcoes :=  TComboBox():New(020,010,{|u| If(PCount()>0,_cOpcoes:=u,_cOpcoes)},_aOpcoes,134,014,_oDlgOpcEnt,,,,,,.T.,,"",,,,,,,_cOpcoes)
	// botoes de opcoes
	_oBtnEntOk   := TButton():New(040,034,"Confirma",_oDlgOpcEnt,{|| If(_lOk:=(!Empty(_cOpcoes)),_oDlgOpcEnt:End(),nil) },050,014,,,,.T.,,"",,,,.F. )
	_oBtnEntSair := TButton():New(040,094,"Cancela",_oDlgOpcEnt,{|| _oDlgOpcEnt:End() },050,014,,,,.T.,,"",,,,.F. )

	// ativa o dialogo
	_oDlgOpcEnt:Activate(,,,.T.,)

	// se foi confirmado a tela
	If (_lOk)

		// valido de qual pasta os arquivos serão informados
		If (ALLTRIM(SF2->F2_ESPECIE) == "FTL")
			_cTipoDoc := "fatura"
		ElseIf (ALLTRIM(SF2->F2_ESPECIE) == "NFS")
			_cTipoDoc := "nfse"
		EndIf

		// pasta de destino
		_cPathDest := "\tecadi\"+_cTipoDoc+"\"
		// empresa e filial
		_cPathDest += "emp"+cEmpAnt+"\"+cFilAnt+"\"

		// define o nome do arquivo de retorno
		// informacoes do cliente
		_cNomArq := "cli_"+SF2->F2_CLIENTE+"_"+SF2->F2_LOJA
		// numero da nota e seria
		_cNomArq += "_"+_cTipoDoc+"_"+SF2->F2_DOC+"_serie_"+SF2->F2_SERIE

		// define o tipo de arquivo
		If (Left(_cOpcoes,1)=="1") // 1-boleto
			_cTipoArq := "boleto"
		ElseIf (Left(_cOpcoes,1)=="2") // 2-mapa faturamento por pedido
			_cTipoArq := "mapa_pedido"
		ElseIf (Left(_cOpcoes,1)=="3") // 3-mapa faturamento por processo
			_cTipoArq := "mapa_processo"
		ElseIf (Left(_cOpcoes,1)=="4") // 4-mapa movimentacao de produtos
			_cTipoArq := "mapa_mov_produto"
		ElseIf (Left(_cOpcoes,1)=="5") // 5-pre nota
			_cTipoArq := "pre_nota"
		EndIf

		// complementa o tipo de documento
		_cNomArq += "_"+_cTipoArq+".pdf"

		// verifica se o arquivo existe
		If (File(_cPathDest+_cNomArq))
			Aviso("NFS-e/Fatura - Anexos","O arquivo selecionado já está relacionado à nota fiscal.",{"Fechar"},3)
			Return(.f.)
		EndIf

		// abre a tela para selecao do arquivo
		_cArquivo := cGetFile("Relatórios e Boletos|*.PDF","Selecione arquivo...",,,,GETF_LOCALHARD,.f.)

		// verifica se foi selecionado algum arquivo
		If (!Empty(_cArquivo))
			// copia o arquivo do local para o servidor
			CpyT2S(_cArquivo,_cPathDest,.f.)
			// extrai informacoes do arquivo, para mudar o local padrao
			// ex: SplitPath ( < cArquivo>, [ @cDrive], [ @cDiretorio], [ @cNome], [ @cExtensao] )
			SplitPath(AllTrim(_cArquivo),nil,nil,@_cTmpNome,@_cTmpExt)
			// renomeia o arquivo enviado
			fRename( (_cPathDest+_cTmpNome+_cTmpExt) , (_cPathDest+_cNomArq) )
		EndIf

	EndIf

Return

// ** funcao para consultar os anexos de cada nota
User Function NFSE002C
	// anexos do email
	local _aAnexos 		:= {}
	local _nAnexos
	// variveis temporarios
	local _aTmpArq 		:= {}
	local _nArq
	local _cTipoDoc 	:= ""
	// path dos arquivos
	local _cPathAnexo 	:= ""
	// objetos da tela
	local _oDlgAnexos
	local _oPnlCabec
	local _oBtnFechar, _oBtnOpen, _oBtnExcluir
	local _oLstAnexos

	// valido de qual pasta os arquivos serão informados
	If (ALLTRIM(SF2->F2_ESPECIE) == "FTL")
		_cTipoDoc := "fatura"
	ElseIf (ALLTRIM(SF2->F2_ESPECIE) == "NFS")
		_cTipoDoc := "nfse"
	EndIf

	_cPathAnexo := "\tecadi\"+_cTipoDoc+"\emp"+cEmpAnt+"\"+cFilAnt+"\"

	// retorna os arquivos disponiveis para a nota
	_aTmpArq := Directory(_cPathAnexo+"cli_"+SF2->F2_CLIENTE+"_"+SF2->F2_LOJA+"_"+_cTipoDoc+"_"+SF2->F2_DOC+"_serie_"+SF2->F2_SERIE+"*.*")

	// anexa os arquivos
	For _nArq := 1 to Len(_aTmpArq)
		// nota fiscal
		If (".HTM" $ Upper(_aTmpArq[_nArq,1]))
			aAdd(_aAnexos,"NOTA FISCAL -> "+_cPathAnexo+_aTmpArq[_nArq,1])
			// XML da nota
		ElseIf (".XML" $ Upper(_aTmpArq[_nArq,1]))
			aAdd(_aAnexos,"XML NOTA FISCAL -> "+_cPathAnexo+_aTmpArq[_nArq,1])
			// boletos
		ElseIf ("BOLETO" $ Upper(_aTmpArq[_nArq,1]))
			aAdd(_aAnexos,"BOLETO -> "+_cPathAnexo+_aTmpArq[_nArq,1])
			// mapa de faturamento por pedido
		ElseIf ("MAPA_PEDIDO" $ Upper(_aTmpArq[_nArq,1]))
			aAdd(_aAnexos,"MAPA FAT. POR PEDIDO -> "+_cPathAnexo+_aTmpArq[_nArq,1])
			// mapa de faturamento por processo
		ElseIf ("MAPA_PROCESSO" $ Upper(_aTmpArq[_nArq,1]))
			aAdd(_aAnexos,"MAPA FAT. POR PROCESSO -> "+_cPathAnexo+_aTmpArq[_nArq,1])
			// mapa de movimentacao de produtos
		ElseIf ("MAPA_MOV_PRODUTO" $ Upper(_aTmpArq[_nArq,1]))
			aAdd(_aAnexos,"MAPA MOVIM. DE PRODUTO -> "+_cPathAnexo+_aTmpArq[_nArq,1])
			// pre-nota
		ElseIf ("PRE_NOTA" $ Upper(_aTmpArq[_nArq,1]))
			aAdd(_aAnexos,"PRE-NOTA -> "+_cPathAnexo+_aTmpArq[_nArq,1])
		EndIf
	Next _nArq

	// apresenta tela com os arquivos
	DEFINE DIALOG _oDlgAnexos TITLE "Anexos da NFS-e" FROM 000,000 TO 400,700 PIXEL
	// cria o panel com os botoes
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgAnexos,,.F.,.F.,,,027,027,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// botao para fechar a tela
	_oBtnFechar := TButton():New(005,005,"Fechar",_oPnlCabec,{||_oDlgAnexos:End()},045,012,,,,.T.,,"",,,,.F. )
	// botao para abrir o arquivo
	_oBtnOpen := TButton():New(005,055,"Abrir Anexo",_oPnlCabec,{|| sfAbrirArq( _oLstAnexos:AITEMS[_oLstAnexos:NAT] ) },045,012,,,,.T.,,"",,,,.F. )

	// opcao para excluir o anexo
	If (SF2->F2_ZENVNFS != "S")
		_oBtnExcluir := TButton():New(005,105,"Excluir Anexo",_oPnlCabec,{|| sfDelArq( _oLstAnexos:AITEMS[_oLstAnexos:NAT], _oDlgAnexos ) },045,012,,,,.T.,,"",,,,.F. )
	EndIf

	// Usando o New
	_oLstAnexos := TListBox():New(000,000,{|u|if(Pcount()>0,_nAnexos:=u,_nAnexos)},_aAnexos,400,700,,_oDlgAnexos,,,,.T.)
	_oLstAnexos:Align := CONTROL_ALIGN_ALLCLIENT

	ACTIVATE DIALOG _oDlgAnexos CENTERED

Return

// ** funcao para abrir o arquivo selecionado
Static Function sfAbrirArq(mvArquivo)
	// retorna a pasta temporaria da maquina
	local _cPathTemp := AllTrim(GetTempPath())
	// arquivo selecionado
	local _cArqSelec := SubS(mvArquivo,At("\",mvArquivo))
	// variaveis temporarias
	local _cTmpNome := ""
	local _cTmpExt := ""
	local _cTmpArquivo

	// extrai informacoes do arquivo, para mudar o local padrao
	// ex: SplitPath ( < cArquivo>, [ @cDrive], [ @cDiretorio], [ @cNome], [ @cExtensao] )
	SplitPath(AllTrim(_cArqSelec),nil,nil,@_cTmpNome,@_cTmpExt)
	// copia o arquivo do servidor para a maquina local
	CpyS2T(_cArqSelec, _cPathTemp, .f.)
	// muda o caminho para o arquivo da pasta temporaria
	_cTmpArquivo := _cPathTemp+_cTmpNome+_cTmpExt

	// abre o navegador
	ShellExecute("open",_cTmpArquivo,"","",5)

Return

// ** funcao para consultar o Log de envio de informacoes
User Function NFSE002D
	// consulta Log de envio
	U_FtConsLog(cFilAnt,"SF2",SF2->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA))
Return

// ** funcao para excluir o arquivo selecionado
Static Function sfDelArq(mvArquivo,mvObjTela)
	// arquivo selecionado
	local _cArqSelec := SubS(mvArquivo,At("\",mvArquivo))

	// mensagem de confirmacao
	If ( MsgYesNo("Confirma a exclusão do arquivo selecionado?"))
		// excuta exclusao do arquivo
		Ferase(_cArqSelec)
		// gera o Log de envio
		U_FtGeraLog(cFilAnt, "SF2", SF2->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA),"Exclusão do arquivo "+AllTrim(mvArquivo),"FAT","")
		// fecha a tela
		mvObjTela:End()
	EndIf

Return

// ** funcao que busca informacao complementar da programacao do cliente
Static Function sfRetInfProc(mvCodCli, mvLojCli, mvNota, mvSerie)
	// mensagem de retorno
	local _cMsgRet := ""
	// query
	local _cQuery
	// variavel temporaria
	local _aDados := {}

	// monta a query
	_cQuery := "SELECT DISTINCT C5_MENNOTA "
	// cab. pedido de venda
	_cQuery += "FROM "+RetSqlName("SC5")+" SC5 "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SC5")
	// numero do pedido
	_cQuery += "AND C5_NUM IN ("
	_cQuery += "   SELECT DISTINCT D2_PEDIDO "
	_cQuery += "     FROM "+RetSqlName("SD2")+" SD2 "
	_cQuery += "    WHERE "+RetSqlCond("SD2")
	_cQuery += "      AND D2_DOC     = '"+mvNota+"'   AND D2_SERIE = '"+mvSerie+"' "
	_cQuery += "      AND D2_CLIENTE = '"+mvCodCli+"' AND D2_LOJA  = '"+mvLojCli+"' "
	_cQuery += ")"

	// retorna os dados
	_aDados := U_SqlToVet(_cQuery)

	// somente uma informacao
	If (Len(_aDados) == 1)
		_cMsgRet := AllTrim(_aDados[1])
	EndIf

Return(_cMsgRet)