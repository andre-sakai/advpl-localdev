#include "totvs.ch"
#Include "Protheus.ch"
#Include "TopConn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para integração de sistemas Datamex x TOTVS (TMS)!
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 05/2016 !
+------------------+--------------------------------------------------------*/

User Function TTMSXDAT(mvWorkFlow)

	// dimensoes da tela
	local _aSizeDlg	:= MsAdvSize()
	LOCAL oSize   := FwDefSize():New(.F.) //Sem enchoicebar

	// objetos
	local _oWndIntegr
	local _oPnlBtnOpr, _oPnlBrwCte
	local _oBrwRotinas
	local _oBtnConfInt, _oBtnVisDados, _oBtnFechar
	local _oMemoLog

	// variavel para controle de marcacao do browse
	Local _cMarcaOk

	// rotinas disponiveis
	local _aRotDisp := {}
	local _nRotDisp

	// opcoes para cancelamento
	local _aOpcCanc := {"CTE", "FAT", "NFS", "BAIXA_RODOCRED", "CF"}
	local _cOpcCanc
	local _cNrDocCanc := Space(30)

	// retorna se eh usuario administrador
	local _lUsrAdmin := .f.

	// cores da legenda
	local _aCoresLeg := {}

	// valor default dos parametros
	Default mvWorkFlow := .f.

	// se eh processamento por workflow
	private _lWorkFlow := ((Select("SX2")==0).or.(mvWorkFlow))

	// estrutura do arquivo de trabalho das rotinas
	private _cAliRotin := GetNextAlias()
	private _aStrRotin := {}
	private _aHeaRotin := {}

	// padronizacao de tamanho de campos
	private _nTamProd  := TamSx3("B1_COD")[1]
	private _nTamNota  := TamSx3("F2_DOC")[1]
	private _nTamSerie := TamSx3("F2_SERIE")[1]
	private _nTamCdCli := TamSx3("A1_COD")[1]
	private _nTamLjCli := TamSx3("A1_LOJA")[1]

	// codigo da condicao de pagamento A VISTA
	private _cCodCond  := "003"

	// natureza para novo titulo
	private _cNewNatur := PadR("01010101",TamSx3("ED_CODIGO")[1])

	// log geral
	private _cLogGeral := ""

	// log em html para email
	private _cLogHtml  := ""
	private _lDadosInt := .f.

	// nome do usuario
	private _cNomUser := IIf(_lWorkFlow, "Agendamento", AllTrim(UsrFullName(__cUserId)))

	// somente na transportadora
	If (cEmpAnt <> "03")
		MsgInfo("Rotina disponível somente para a Four Transportes!", "Acesso")
		Return(.f.)
	EndIf

	oSize:Process()

	// define as cores da legenda
	aAdd(_aCoresLeg,{" ! Empty((_cAliRotin)->ROT_COR)", "BR_VERMELHO"})
	aAdd(_aCoresLeg,{"   Empty((_cAliRotin)->ROT_COR)", "BR_VERDE"   })

	// define variavel para controle de marcacao do browse (neste local por motivos do Workflow)
	_cMarcaOk := GetMark()

	// rotinas disponiveis
	_aRotDisp := sfRetRotinas()

	// retorna se eh usuario administrador
	_lUsrAdmin := IIf(_lWorkFlow, .f., sfUsrAdmin())

	// -- monta o arquivo de trabalho das rotinas
	aAdd(_aStrRotin,{"ROT_OK"    ,"C",  2,0})
	aAdd(_aStrRotin,{"ROT_COR"   ,"C",  2,0})
	aAdd(_aStrRotin,{"ROT_COD"   ,"C",  3,0})
	aAdd(_aStrRotin,{"ROT_DESCR" ,"C", 80,0})
	aAdd(_aStrRotin,{"ROT_PATH"  ,"C",250,0})

	// fecha alias do TRB
	If (Select(_cAliRotin) <> 0)
		dbSelectArea(_cAliRotin)
		dbCloseArea()
	EndIF

	// cria o TRB
	_oAlTrb := FWTemporaryTable():New(_cAliRotin)
	_oAlTrb:SetFields(_aStrRotin)
	_oAlTrb:Create()

	// inclui relacao dos itens para importacao
	For _nRotDisp := 1 to Len(_aRotDisp)

		// inclui registro
		If (_aRotDisp[_nRotDisp][2] == "MOV")
			(_cAliRotin)->(dbSelectArea(_cAliRotin))
			(_cAliRotin)->(RecLock((_cAliRotin),.t.))
			(_cAliRotin)->ROT_OK    := _cMarcaOk
			(_cAliRotin)->ROT_COD   := _aRotDisp[_nRotDisp][1]
			(_cAliRotin)->ROT_DESCR := _aRotDisp[_nRotDisp][3]
			(_cAliRotin)->ROT_PATH  := _aRotDisp[_nRotDisp][4]
			(_cAliRotin)->(MsUnLock())
		EndIf

	Next _nRotDisp


	// define header
	aAdd(_aHeaRotin,{"ROT_OK"    ,"","  "        , ""     })
	aAdd(_aHeaRotin,{"ROT_COD"   ,"","Código"    , ""     })
	aAdd(_aHeaRotin,{"ROT_DESCR" ,"","Descrição" , ""     })


	// abre o arquivo de trabalho
	(_cAliRotin)->(dbSelectArea(_cAliRotin))
	(_cAliRotin)->(dbGoTop())

	// se for Workflow, executa processamento sem abrir telas
	If ( _lWorkFlow )

		// chama a rotina de processamento
		sfProcessa()

		// fecha arquivo de trabalho
		(_cAliRotin)->(dbSelectArea(_cAliRotin))
		(_cAliRotin)->(dbCloseArea())
		_oAlTrb:Delete
		// retorno
		Return(.t.)
	EndIf

	// monta o dialogo
	_oWndIntegr := MSDialog():New(oSize:aWindSize[1],oSize:aWindSize[2],oSize:aWindSize[3],oSize:aWindSize[4],"Integração Datamex x TOTVS",,,.F.,,,,,,.T.,,,.T. )
	_oWndIntegr:lMaximized := .T.

	// panel para os botoes de comando
	_oPnlBtnOpr := TPanel():New(000,000,Nil,_oWndIntegr,,.F.,.F.,,,26,26,.T.,.F. )
	_oPnlBtnOpr:Align := CONTROL_ALIGN_TOP

	// -- botao confirmar
	_oBtnConfInt := TButton():New(005,005,"Confirmar",_oPnlBtnOpr,{|| sfConfProc() },030,015,,,,.T.,,"",,,,.F. )

	// -- botao visualiza dados
	_oBtnVisDados := TButton():New(005,040,"Visualiza Dados",_oPnlBtnOpr,{|| sfVisDados( (_cAliRotin)->ROT_COD ) },040,015,,,,.T.,,"",,,,.F. )

	// opcoes de cancelamento
	If (_lUsrAdmin)
		_oGetCbCanc := TComboBox():New(005,120,{|u| If(PCount()>0,_cOpcCanc:=u,_cOpcCanc)},_aOpcCanc,030,025,_oPnlBtnOpr,,,,,,.T.,,"",,,,,,,_cOpcCanc)
		_oGetTpCanc := TGet():New(005,160,{|u| If(PCount()>0,_cNrDocCanc:=u,_cNrDocCanc)},_oPnlBtnOpr,070,009,"@!",{|| sfEstorno(_cOpcCanc, _cNrDocCanc) },,,,,,.T.,"Nr Doc Cancelamento",,{|| .t. },.F.,.F.,,.F.,.F.,"","_cNrDocCanc",,)
	EndIf

	// -- botao fechar
	_oBtnFechar := TButton():New(005,((oSize:aWindSize[4]/2)-35),"Fechar",_oPnlBtnOpr,{|| _oWndIntegr:End() },030,015,,,,.T.,,"",,,,.F. )


	// panel para o browse do CT-e
	_oPnlBrwCte := TPanel():New(000,000,Nil,_oWndIntegr,,.F.,.F.,,,120,120,.T.,.F. )
	_oPnlBrwCte:Align := CONTROL_ALIGN_TOP

	// browse com a listagem dos CT-e
	_oBrwRotinas := MsSelect():New((_cAliRotin),"ROT_OK",,_aHeaRotin,,_cMarcaOk,{000,000,2000,2000},,,_oPnlBrwCte,,_aCoresLeg)
	_oBrwRotinas:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwRotinas:oBrowse:bAllMark := {|| sfMarkAll((_cAliRotin),"ROT_OK",_cMarcaOk) }

	// campo memo com os detalhes do log
	_oMemoLog := tMultiget():New(000,000, {| u | IIf( pCount() > 0, _cLogGeral := u, _cLogGeral ) },_oWndIntegr,2000,2000, , , , , , .T. )
	_oMemoLog:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oWndIntegr CENTERED

	// fecha arquivo de trabalho
	(_cAliRotin)->(dbSelectArea(_cAliRotin))
	(_cAliRotin)->(dbCloseArea())
	_oAlTrb:Delete

Return

// ** funcao que marca todos os itens quando clicar no header da coluna
Static Function sfMarkAll(mvAlias, mvCampo, mvMarca)
	// area atual
	Local _aAreaAtu := (mvAlias)->(GetArea())
	// seleciona o arquivo de trabalho
	dbSelectArea(mvAlias)
	(mvAlias)->(dbGoTop())

	// atualiza o campo Ok
	DbEval({|| RecLock(mvAlias),;
	(mvAlias)->(&mvCampo) := If( Empty((mvAlias)->(&mvCampo)) ,mvMarca,Space(2) ),;
	(mvAlias)->(MsUnLock()) })

	// restaura area atual
	RestArea(_aAreaAtu)
Return(.t.)

// ** funcao para confirmacao do processamento
Static Function sfConfProc()
	// objeto de controle de processamento
	private _oProcInteg

	If ( ! _lWorkFlow ).and.( ! MsgYesNo("Confirma integração dos itens selecionados?", "Confirmação") )
		Return(.f.)
	EndIf

	// inicia processo de integracao
	_oProcInteg := MsNewProcess():New({|lEnd| sfProcessa() },"","",.F.)
	_oProcInteg:Activate()

Return(.t.)

// ** funcao para processamento de todas as funcoes
Static Function sfProcessa()
	// area incial
	local _aAreaAtu := (_cAliRotin)->(GetArea())

	// controle do processamento
	local _lContProc := .t.

	// conexao com Token Datamex através de Restful/API
	Local _oCnxRest := FwRest():New(SuperGetMv("TC_DTMXURL",,"http://tecadi.e-login.net"))
	// complemento para chamada
	local _cAddPath := ""

	// configuracao do Header
	Local _aHeadRest := {"tenantId: 99,01"}

	// dados do retorno da chamada Restful/API
	local _aRetDados
	local _cGetRes

	// controle dos dados de Parse do XML
	local _oXML
	local _cError   := ""
	local _cWarning := ""

	// inclui o campo Authorization no formato <usuario>:<senha> na base64
	Aadd(_aHeadRest, "Authorization: Basic " + Encode64(SuperGetMv("TC_DTMXUSR",,"tecadi:t3c@d1")))

	// zera variaveis
	_cLogGeral := "Data: "+DtoC(dDataBase)+CRLF+CRLF

	// log em html
	_cLogHtml := '<table width="780px" align="center">'
	_cLogHtml += '  <tr>'
	_cLogHtml += '    <td>'
	_cLogHtml += '      <table style="border-collapse: collapse;" border="1" width="100%" cellpadding="2" cellspacing="0" align="center" >'
	_cLogHtml += '        <tr>'
	_cLogHtml += '          <td height="30" colspan="2" style="font-family: Tahoma; font-size: 12px; background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Log de Integração TOTVS x Datamex</td>'
	_cLogHtml += '        </tr>'
	_cLogHtml += '        <tr>'
	_cLogHtml += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Data/Hora</td>'
	_cLogHtml += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">'+DtoC(Date())+' as '+Time()+' h</td>'
	_cLogHtml += '        </tr>'
	_cLogHtml += '        <tr>'
	_cLogHtml += '          <td width="20%" style="font-family: Tahoma; font-size: 12px;">Usuário:</td>'
	_cLogHtml += '          <td width="80%" style="font-family: Tahoma; font-size: 12px;">'+_cNomUser+'</td>'
	_cLogHtml += '        </tr>'
	_cLogHtml += '      </table>'
	_cLogHtml += '      <br>'

	// define a quantidade de funcoes a processar
	If ( ! _lWorkFlow )
		_oProcInteg:SetRegua1( (_cAliRotin)->( RecCount() ) )
	EndIf

	// varre todas as rotinas disponiveis para integracao
	dbSelectArea(_cAliRotin)
	(_cAliRotin)->(DbGoTop())
	While (_cAliRotin)->(!Eof())

		// incrementa Regua de Processamento
		If ( ! _lWorkFlow )
			_oProcInteg:IncRegua1( (_cAliRotin)->ROT_DESCR )
		EndIf

		// verifica se o item esta selecionado
		If ( ! Empty((_cAliRotin)->ROT_OK) )

			// adiciona titulo
			_cLogGeral += ":: Rotina: "+(_cAliRotin)->ROT_COD+" - "+AllTrim((_cAliRotin)->ROT_DESCR)+CRLF

			// titulo do html
			_cLogHtml += '<table style="border-collapse: collapse;" border="1" width="100%" cellpadding="2" cellspacing="0" align="center" >'
			_cLogHtml += '<tr>'
			_cLogHtml += '<td height="20" colspan="3" style="font-family: Tahoma; font-size: 12px; background-color: #87CEEB; font-weight: bold; color: #000000;" align="left">'+(_cAliRotin)->ROT_COD+" - "+AllTrim((_cAliRotin)->ROT_DESCR)+'</td>'
			_cLogHtml += '</tr>'
			_cLogHtml += "<tr>"
			_cLogHtml += '<td width="3%" style="font-family: Tahoma; font-size: 12px;">&nbsp;</td>'
			_cLogHtml += '<td width="17%" style="font-family: Tahoma; font-size: 12px;">Documento</td>'
			_cLogHtml += '<td width="80%" style="font-family: Tahoma; font-size: 12px;">Detalhes</td>'
			_cLogHtml += '</tr>'

			// complemento para chamada
			_cAddPath := sfAddPath( (_cAliRotin)->ROT_COD )

			// chamada da classe exemplo de REST com retorno de lista (XML)
			_oCnxRest:SetPath( AllTrim((_cAliRotin)->ROT_PATH)+_cAddPath )

			// executa Get do Header
			If _oCnxRest:Get(_aHeadRest)
				// atualiza dados quando conexao ok
				_cGetRes := _oCnxRest:GetResult()
				// controle de processamento
				_lContProc := .t.
			Else
				// busca mensagem de erro na busca dos dados
				_cGetRes := _oCnxRest:GetLastError()
				// controle de processamento
				_lContProc := .f.
				// mensagem
				_cLogGeral += "- Erro conexão com DATAMEX (Id: "+AllTrim(_cGetRes)+")"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml("", "Erro conexão com DATAMEX (Id: "+AllTrim(_cGetRes)+")", "ERRO")
			EndIf

			// nao ha dados
			If (_lContProc).and.(Empty(_cGetRes))
				// controle de processamento
				_lContProc := .f.
				// mensagem
				_cLogGeral += "- Não há dados para integração"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml("", "- Não há dados para integração", "ALERTA")

			EndIf

			// prepara objeto XML
			If (_lContProc)
				// parse no XML
				_oXML := XmlParser(_cGetRes, "_", @_cError, @_cWarning )

				// valida montagem/parse correta do XML
				If ( ( _oXML == Nil ) .or. ( ! Empty(_cError) ) .or. ( ! Empty(_cWarning) ) )
					// controle de processamento
					_lContProc := .f.
					// mensagem
					_cLogGeral += "FALHA NO XML EXTRAIDO DA DATAMEX " +AllTrim(_cError) +" / "+ AllTrim(_cWarning)+CRLF
					// adiciona log em html
					_cLogHtml += sfLogHtml("", "FALHA NO XML EXTRAIDO DA DATAMEX " +AllTrim(_cError) +" / "+ AllTrim(_cWarning), "ERRO")

				EndIf

			EndIf

			// executa funcoes de acordo com cada processo
			If (_lContProc)

				If ((_cAliRotin)->ROT_COD == "001") // Conhecimentos de Transporte / Documentos Válidos

					// chama funcao para integrar o CT-e selecionado
					sfGrvDocSai("CTE", _oXML, .f.)

				ElseIf ((_cAliRotin)->ROT_COD == "003") // Conhecimentos de Transporte / Cancelamentos

					// chama funcao para integrar o CT-e selecionado
					sfGrvDocSai("CTE", _oXML, .t.)

				ElseIf ((_cAliRotin)->ROT_COD == "004") // Conhecimentos de Transporte / Inutilização

					// chama funcao para integrar inutilizacao de Cte
					sfGrvInutilizacao("CTE", _oXML)

				ElseIf ((_cAliRotin)->ROT_COD == "005") // Notas Fiscais de Serviço / Documentos Válidos

					// chama funcao para integrar o NFS-e selecionado
					sfGrvDocSai("NFS", _oXML, .f.)

				ElseIf ((_cAliRotin)->ROT_COD == "006") // Notas Fiscais de Serviço / Cancelamentos

					// chama funcao para integrar o NFS-e selecionado
					sfGrvDocSai("NFS", _oXML, .t.)

				ElseIf ((_cAliRotin)->ROT_COD == "007") // Faturas de Cobrança / Dados básicos

					// chama funcao para integrar faturas a receber
					sfGrvTitRec(_oXML)

				ElseIf ((_cAliRotin)->ROT_COD == "008") // Contratos de Fretes / Pessoas Jurídicas

					// chama funcao para integrar um documento de entrada, especie NF
					sfGrvDocEnt("CF", _oXML, .f.)

				ElseIf ((_cAliRotin)->ROT_COD == "009") // Baixa de Contratos de Fretes

					// chama funcao para integrar as movimentacoes de baixa de contratos de fretes
					sfBxTitPag(_oXML, .f.)

				ElseIf ((_cAliRotin)->ROT_COD == "010") // Tarifas de Contratos de Fretes

					// chama funcao para integrar as movimentacoes tarifas de contratos de fretes
					sfBxTitPag(_oXML, .t.)

				ElseIf ((_cAliRotin)->ROT_COD == "011") // Prorrogação de Vencimento - Boletos

					// chama funcao para integrar as Prorrogações de Vencimento de Boletos
					sfAltVencto(_oXML)

				EndIf

			EndIf

			// fecha tabela do log
			_cLogHtml += '</table>'
			_cLogHtml += '<br>'

		EndIf

		// proximo item
		(_cAliRotin)->(dbSkip())
	EndDo

	// fecha tabela geral do log
	_cLogHtml += '</td>'
	_cLogHtml += '</tr>'
	_cLogHtml += '</table>'
	_cLogHtml += '</table>'

	// grava log
	MemoWrit('c:\temp\log_datamex.html', _cLogHtml)

	// restaura area incial
	RestArea(_aAreaAtu)

	// envia mensagem de email
	If (_lDadosInt)
		U_FtMail(_cLogHtml, "Log de Integração TOTVS x Datamex", AllTrim(UsrRetMail(__cUserId))+";ti@tecadi.com.br")
	EndIf

Return

// ** funcao para realizar a integracao de documentos de saida (CT-e, NFS-e, Cancelamentos...)
Static Function sfGrvDocSai(mvTipoDoc, mvXML, mvCteCanc)

	// variaveis temporaris
	local _nXML

	// valor total bruto
	local _nVlrTotal := 0
	// valor para fatura (líquido) para notas fiscais de serviço com retenção de impostos
	local _nVlrFat := 0
	// valor de frete
	local _nVlrFrete := 0
	// valor de pedagio
	local _nVlrPedagio := 0
	// valor do ICMS
	local _nVlrICMS := 0
	// base do icms
	local _nBsIcms := 0
	// aliquota do icms
	local _nAliqIcms := 0
	// incidencia de ICMS
	local _lIncIcms := .f.

	// base do ISS
	local _nBsISS := 0
	// aliquota do ISS
	local _nAliqISS := 0
	// valor do ISS
	local _nVlrISS := 0
	// incidencia de ISS
	local _lIncISS := .f.


	// quantidade de volumes
	local _nQtdVol := 0

	// pesos
	local _nPesoBr := 0
	local _nPesoLi := 0

	// cabecalho
	local _aCabSF2 := {}
	local _aItem := {}
	local _aItensSD2 := {}
	// item
	local _cItem := StrZero(1,TamSx3("D2_ITEM")[1])

	// chave do CT-e
	local _cChaveCTe := ""

	// prazo de pagamento
	local _dVectoFat := CtoD("//")
	local _dVectoRea := CtoD("//")

	// CT-e cancelado
	local _lCteCanc := .f.

	// codigo da TES utilizada
	local _cCodTES := ""

	// cfpo
	local _cCodCFOP := ""

	// situacao tributaria do ICMS
	local _cSitTrib := ""

	// tipo do frete (CIF / FOB)
	local _cTipFrete := ""

	// observacao
	local _cObsCte := ""

	// ID interno Datamex
	local _cIdDatamex := ""

	// dados ok por cte/nfse
	local _lDocSaiOk := .f.
	local _lGeraDoc  := .f.

	// controle de necessidade de inclusao do titulo a receber
	local _lIncTitRec := .f.

	// controle de necessidade de exclusao do titulo a receber
	local _lExcTitRec := .f.

	// pedagio isento icms
	local _lPedIseIcms := .f.

	// tipo do documento para Log
	local _cTpDocLog := ""

	// tipo de documento de saida
	local _lIsCte := .f.
	local _lIsNfs := .f.
	local _lNFSRet := .F.  //nfse com retenção de impostos
	local _cCodSrv := ""    //codigo do serviço (ISS)

	// controle para validar o cadastro do cliente
	local _lVldCadCli := .f.

	// seek
	local _cSeekSD2

	// variavel para rotina automatica
	local _aAutoSE1 := {}

	// valor dos juros
	local _nVlrJuros := 0

	// taxa de juros
	Local _nPerJur := SuperGetMv("MV_TXPER")

	// nome reduzido
	local _cNomReduz := ""

	// data de vencimento da fatura
	local _dDataVenc := CtoD("//")

	// log rotina automatica
	local _cLogRotAut := ""

	// natureza antiga do cadastro do cliente
	local _cTmpNat := ""

	// variaveis da rotina automatica
	Private lMsErroAuto := .F.
	private c920Tipo    := "N"
	private c920Nota    := ""
	private d920Emis    := CtoD("//")
	private c920Client  := ""
	private c920Loja    := ""
	private c920Especi  := mvTipoDoc


	private _cCliEst    := ""
	private _cCliCNPJ   := ""
	private _cCliID     := ""
	private _cCliInsEst := ""
	private _cCliPais   := ""
	private _cCodCli    := ""
	private _cLojCli    := ""
	private _cCliNome   := ""
	private _cTipoCli   := "" // tipo do cliente (F-Cons. Final/X-Exportacao)

	// vetor usado no ponto de entrada MTA920C
	private _a920Dados  := {}

	// controle, quando for cancelamento de Cte, para nao limpar conteudo do campo D2_ORIGLAN, para permitir cancelamento
	private _l920Cancel := mvCteCanc

	// variaveis temporaris
	private _oXmlDocSai := mvXML:_ROOT


	/*
	NRO_FORM
	IDCte
	SERIE_CTE
	TOMADOR
	FORM_PAG
	CFOP
	DTEMISSAO
	DT_VENC
	ORIG_PREST
	DEST_PREST
	REM_DESC
	REM_ID
	REM_END
	REM_BAIRRO
	REM_MUN
	REM_CEP
	REM_CNPJ
	REM_INSC
	REM_PAIS
	REM_FONE
	DEST_DESC
	DEST_ID
	DEST_END
	DEST_BAIRRO
	DEST_MUN
	DEST_CEP
	DEST_CNPJ
	DEST_INSC
	DEST_PAIS
	DEST_FONE
	EXP_DESC
	EXP_ID
	EXP_END
	EXP_BAIRRO
	EXP_MUN
	EXP_CEP
	EXP_CNPJ
	EXP_INSC
	EXP_PAIS
	EXP_FONE
	REC_DESC
	REC_ID
	REC_END
	REC_BAIRRO
	REC_MUN
	REC_CEP
	REC_CNPJ
	REC_INSC
	REC_PAIS
	REC_FONE
	TOM_DESC
	TOM_ID
	TOM_END
	TOM_BAIRRO
	TOM_MUN
	TOM_CEP
	TOM_CNPJ
	TOM_INSC
	TOM_PAIS
	TOM_FONE
	SEGURADORA
	SEG_ID
	SEG_RESP
	SEG_APOL
	SIT_TRIB
	BASE_ICMS
	ALIQ_ICMS
	VALOR_ICMS
	RD_BC_ICMS
	MOT_DESC
	MOT_CNPJ
	MOT_ID
	MOT_FONE
	VEIC_PLACA
	VEIC_ID
	CARRETA_PL
	CARRETA_ID
	SEMIREB_PL
	SEMIREB_ID
	TAR_FINAL
	TAR_REAL
	VL_FRETE
	VL_OUTROS
	VL_PED
	VL_GRIS
	VL_DIARIA
	VL_SEGURO
	SEG_AD
	TOT_PREST
	VL_TOTAL
	VL_REC
	ICMS
	TOTQTMERC
	TOTVLNF
	TOTPSMERC
	TOTCBMERC
	CTNROMERC
	CTNROCTNR
	TOTVLCTNR
	TOTVLPROD
	OBSERV
	OBSERV_PV
	TALAO
	CHAVECTE
	DATAEDOC
	RESULTCTE
	SUBSTITUI
	*/

	// define tipo de documento para log
	If (AllTrim(mvTipoDoc) == "CTE")
		_cTpDocLog := "Ct-e"
		_lIsCte    := .t.

	ElseIf (AllTrim(mvTipoDoc) == "NFS")
		_cTpDocLog := "NFS-e"
		_lIsNfs    := .t.

	EndIf

	// caso nao for vetor, converte
	If Type("_oXmlDocSai:_LINHA") != "A"
		XmlNode2Arr(_oXmlDocSai:_LINHA, "_LINHA")
	EndIf

	// define a quantidade de itens a processar
	If ( ! _lWorkFlow )
		_oProcInteg:SetRegua2( Len(_oXmlDocSai:_LINHA) )
	EndIf

	aItens := {}    
	For _nXML := 1 To Len(_oXmlDocSai:_LINHA)

		// ID interno Datamex
		If (_lIsCte)
			_cIdDatamex := AllTrim(_oXmlDocSai:_LINHA[_nXML]:_IDCTE:TEXT)
		ElseIf (_lIsNfs)
			_cIdDatamex := AllTrim(_oXmlDocSai:_LINHA[_nXML]:_IDNFSE:TEXT)
		EndIf
		Aadd(aItens,{_cTpDocLog+"/"+AllTrim(_oXmlDocSai:_LINHA[_nXML]:_NRO_FORM:TEXT),;
		_cIdDatamex,;
		AllTrim(_oXmlDocSai:_LINHA[_nXML]:_TOM_DESC:TEXT),;
		sfExtDtHr( _oXmlDocSai:_LINHA[_nXML]:_DTEMISSAO:TEXT , "D")})	
	Next
	fTelaSel("Selecione os documentos para integração:",@aItens)

	// varre todos os registro
	For _nXML := 1 to Len(_oXmlDocSai:_LINHA)

		// reinicia variaveis
		_lDocSaiOk   := .t.
		_lPedIseIcms := .f.
		_lGeraDoc    := .t.
		_lExcTitRec  := .f.
		_lVldCadCli  := .f.
		_lIncTitRec  := .t.
		_lNFSRet     := .F.
		_cTmpNat     := ""
		_dDataVenc   := CtoD("//")
		_cCodSrv      := ""


		// atualiza os dados para rotina automatica
		c920Nota    := sfRetNum( _oXmlDocSai:_LINHA[_nXML]:_NRO_FORM:TEXT, .t., TamSx3("F2_DOC")[1] )
		c920Serie   := PadR( _oXmlDocSai:_LINHA[_nXML]:_SERIE:TEXT, TamSx3("F2_SERIE")[1] )
		d920Emis    := sfExtDtHr( _oXmlDocSai:_LINHA[_nXML]:_DTEMISSAO:TEXT , "D")
		c920Client  := ""
		c920Loja    := ""
		_cCodCli    := ""
		_cLojCli    := ""
		_cCliEst    := ""
		_cTipoCli   := ""
		_cCliCNPJ   := sfRetNum( _oXmlDocSai:_LINHA[_nXML]:_TOM_CNPJ:TEXT, .f., TamSx3("A1_CGC")[1] )
		_cCliID     := AllTrim(_oXmlDocSai:_LINHA[_nXML]:_TOM_ID:TEXT)
		_cCliInsEst := AllTrim(_oXmlDocSai:_LINHA[_nXML]:_TOM_INSC:TEXT)
		_cCliPais   := FwNoAccent(AllTrim(_oXmlDocSai:_LINHA[_nXML]:_TOM_PAIS:TEXT))
		_cCliNome   := AllTrim(_oXmlDocSai:_LINHA[_nXML]:_TOM_DESC:TEXT)
		_cCNPJ      := AllTrim(_oXmlDocSai:_LINHA[_nXML]:_EMPRESA:TEXT)

		// data de vencimento
		If ( ! mvCteCanc )
			_dDataVenc := sfExtDtHr(_oXmlDocSai:_LINHA[_nXML]:_DT_VENC:TEXT, "D")
		EndIf


		// ID interno Datamex
		If (_lIsCte)
			_cIdDatamex := AllTrim(_oXmlDocSai:_LINHA[_nXML]:_IDCTE:TEXT)
		ElseIf (_lIsNfs)
			_cIdDatamex := AllTrim(_oXmlDocSai:_LINHA[_nXML]:_IDNFSE:TEXT)
		EndIf

		//Ignora itens não selecionados na tela.
		If (aScan(aItens,{|x| x[02] == _cIdDatamex})) == 0
			Loop
		EndIf
		//Verifica se está importando o registro para a filial correta
		If (_cCNPJ != SM0->M0_CGC)
			_cLogGeral += "Filial corrente divergente do especificado na integração. Documento " + _cTpDocLog + " / " + AllTrim(c920Nota) + " (id: " + _cIdDatamex + ") / Filial " + _cCNPJ + " não integrado." + CRLF
			//proximo item a integrar
			Loop
		EndIF

		// mensagem solicitando confirmacao
		//		If ( ! _lWorkFlow ) /*.and.( ! MsgYesno("Confirma integração do(a) "+_cTpDocLog+" número "+AllTrim(c920Nota)+" (id: "+_cIdDatamex+") ?", "Confirmação") )*/
		//			Loop
		//		EndIf

		// mensagem
		_cLogGeral += "  :: "+_cTpDocLog+" "+c920Nota+CRLF

		// incrementa Segunda Regua
		If ( ! _lWorkFlow )
			_oProcInteg:IncRegua2( _cTpDocLog+" "+c920Nota )
		EndIf

		// Verifica se a nota fiscal/cte já está digitada no sistema
		dbSelectArea("SF2")
		SF2->(dbSetOrder(1)) // 1-F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_FORMUL, F2_TIPO
		If SF2->(dbSeek( xFilial("SF2")+c920Nota+c920Serie ))

			// flag para nao gerar DOC, pois ja esta registrado
			_lGeraDoc := .f.

			// controle de necessidade de exclusao do titulo a receber
			If (mvCteCanc).and.( ! Empty(SF2->F2_DUPL) )
				_lExcTitRec := .t.
			EndIf

		EndIf

		If (_lDocSaiOk)

			// controle para validar/atualizar o cadastro do cliente
			If (_lGeraDoc)
				_lVldCadCli := .f. // realiza alteracao/inclusao de cadastro
			Else
				_lVldCadCli := .t. // soh valida se o cadastro existe (sem alteracoes)
			EndIf

			// funcao que valida o cliente
			If ( ! sfVldCliente(_cCliID, _lVldCadCli, _cCliInsEst, _cCliPais) )
				// dados ok por cte/nfse
				_lDocSaiOk := .f.
			EndIf
		EndIf

		If (_lDocSaiOk).and.( ! _lGeraDoc )
			// verifica necessidade de gerar titulos a receber
			dbSelectArea("SE1")
			SE1->(dbSetOrder(2)) // 2-E1_FILIAL, E1_CLIENTE, E1_LOJA, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO
			If SE1->(dbseek( xFilial("SE1")+SF2->F2_CLIENTE+SF2->F2_LOJA+SF2->F2_SERIE+SF2->F2_DOC ))
				_lIncTitRec := .f.
			EndIf
		EndIf

		If (_lDocSaiOk).and.((_lGeraDoc).or.(mvCteCanc)).and.(_lIsCte) // somente para CT-e

			// base do icms
			_nBsIcms     := Val(_oXmlDocSai:_LINHA[_nXML]:_BASE_ICMS:TEXT)
			// aliquota do icms
			_nAliqIcms   := Val(_oXmlDocSai:_LINHA[_nXML]:_ALIQ_ICMS:TEXT)

			// valor total
			_nVlrTotal   := Val(_oXmlDocSai:_LINHA[_nXML]:_VL_TOTAL:TEXT)
			//valor faturado
			_nVlrFat     := _nVlrTotal
			// valor de pedagio
			_nVlrPedagio := Val(_oXmlDocSai:_LINHA[_nXML]:_VL_PED:TEXT)
			// define se o pedagio tem tributacao diferente
			_lPedIseIcms := ((_nBsIcms > 0).and.(_nVlrPedagio > 0).and.(_nBsIcms <> _nVlrTotal))
			// valor de frete
			_nVlrFrete   := _nVlrTotal - IIf(_lPedIseIcms, _nVlrPedagio, 0)
			// valor do ICMS
			_nVlrICMS    := Val(_oXmlDocSai:_LINHA[_nXML]:_VALOR_ICMS:TEXT)
			// incidencia de ICMS
			_lIncIcms    := (_nVlrICMS > 0)

			// chave do CT-e
			_cChaveCTe   := _oXmlDocSai:_LINHA[_nXML]:_CHAVECTE:TEXT

			// tipo do frete (1-CIF / 2-FOB)
			_cTipFrete   := IIF(AllTrim(Upper(_oXmlDocSai:_LINHA[_nXML]:_FORM_PAG:TEXT))=="PAGO", "1", "2")

			// observacao do CT-e
			_cObsCte     := _oXmlDocSai:_LINHA[_nXML]:_OBSERV:TEXT

			// quantidade de volumes
			_nQtdVol     := Val(_oXmlDocSai:_LINHA[_nXML]:_TOTQTMERC:TEXT)

			// pesos
			_nPesoBr     := Val(_oXmlDocSai:_LINHA[_nXML]:_TOTPSMERC:TEXT)
			_nPesoLi     := Val(_oXmlDocSai:_LINHA[_nXML]:_TOTPSMERC:TEXT)


			// zera variaveis
			_aCabSF2   := {}
			_aItem     := {}
			_aItensSD2 := {}
			// utilizado no PE MTA920C
			_a920Dados := {}


			// cfpo
			_cCodCFOP  := sfRetCFOP(_oXmlDocSai:_LINHA[_nXML]:_CFOP:TEXT)

			// situacao tributaria do ICMS
			_cSitTrib  := sfRetSitTrib(_oXmlDocSai:_LINHA[_nXML]:_SIT_TRIB:TEXT)

			// item
			_cItem     := StrZero(1,TamSx3("D2_ITEM")[1])
		EndIf

		If (_lDocSaiOk).and.((_lGeraDoc).or.(mvCteCanc)).and.(_lIsNfs) // somente para NFS-e

			// valida se codigo do ISS está configurado para integração
			If !(_oXmlDocSai:_LINHA[_nXML]:_COD_ATIVIDADE:TEXT $ ("1102/1104/1601/1602") )
				// mensagem
				_cLogGeral += c920Nota + " - Erro ao integrar pois esta nota fiscal possui um código de atividade de ISS (" + _oXmlDocSai:_LINHA[_nXML]:_COD_ATIVIDADE:TEXT + ")" + " não configurado para integração. Contate a --> contabilidade e o gerente financeiro <-- e informe esta situação" + CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(c920Nota, "- Erro ao integrar pois esta nota fiscal possui um código de atividade de ISS (" + _oXmlDocSai:_LINHA[_nXML]:_COD_ATIVIDADE:TEXT + ")" + " não configurado para integração. Contate a contabilidade e o gerente financeiro e informe esta situação", "ERRO")
				// marca como falso para integrar
				_lDocSaiOk := .F.
			EndIf

			If (_oXmlDocSai:_LINHA[_nXML]:_COD_ATIVIDADE:TEXT == "1102")
				alert("Integrando nota fiscal de escolta armada. Valide os impostos e financeiro!")
				_lNFSRet := .T.
			EndIf

			// base do ISS
			_nBsISS    := Val(_oXmlDocSai:_LINHA[_nXML]:_BASE_ISS:TEXT)
			// aliquota do ISS
			_nAliqISS  := Val(_oXmlDocSai:_LINHA[_nXML]:_ALIQUOTA:TEXT)
			// aliquota do ISS
			_nVlrISS   := Val(_oXmlDocSai:_LINHA[_nXML]:_ISS:TEXT)
			// incidencia de ISS
			_lIncISS   := (_nVlrISS > 0)

			// valor total da NF de serviço
			// se for com retenção, então é o valor bruto (com impostos), caso contrário
			// utiliza o campo valor total
			if (_lNFSRet) .AND. (_lGeraDoc)
				_nVlrTotal   := Val(_oXmlDocSai:_LINHA[_nXML]:_VL_BRUTO:TEXT)
				_nVlrFat     := Val(_oXmlDocSai:_LINHA[_nXML]:_VL_LIQUIDO:TEXT)
			else
				_nVlrTotal   := Val(_oXmlDocSai:_LINHA[_nXML]:_VL_TOTAL:TEXT)
				_nVlrFat     := _nVlrTotal
			EndIf

			// zera variaveis
			_aCabSF2   := {}
			_aItem     := {}
			_aItensSD2 := {}
			// utilizado no PE MTA920C
			_a920Dados := {}

			// cfpo
			_cCodCFOP  := sfRetCFOP(_oXmlDocSai:_LINHA[_nXML]:_CFOP:TEXT)

			// item
			_cItem     := StrZero(1,TamSx3("D2_ITEM")[1])
		EndIf

		If (_lDocSaiOk).and.((_lGeraDoc).or.(mvCteCanc))
			// define o cabecalho do CT-e
			_aCabSF2 := { ;
			{"F2_DOC"     ,c920Nota   ,NIL},;
			{"F2_SERIE"   ,c920Serie  ,NIL},;
			{"F2_CLIENTE" ,c920Client ,NIL},;
			{"F2_LOJA"    ,c920Loja   ,NIL},;
			{"F2_TIPO"    ,c920Tipo   ,NIL},;
			{"F2_EMISSAO" ,d920Emis   ,NIL},;
			{"F2_ESPECIE" ,c920Especi ,NIL},;
			{"F2_VALBRUT" ,_nVlrTotal ,NIL},;
			{"F2_DESCONT" ,0          ,NIL},;
			{"F2_FRETE"   ,0          ,NIL},;
			{"F2_SEGURO"  ,0          ,NIL},;
			{"F2_DESPESA" ,0          ,NIL},;
			{"F2_CHVNFE"  ,_cChaveCTe ,NIL} }

			// adiciona dados complementares, nao suportado pela rotina automatica
			aAdd(_a920Dados,{"F2_CLIENT" , c920Client })
			aAdd(_a920Dados,{"F2_LOJENT" , c920Loja   })
			aAdd(_a920Dados,{"F2_TIPOCLI", _cTipoCli  })
			aAdd(_a920Dados,{"F2_VOLUME1", _nQtdVol   })
			aAdd(_a920Dados,{"F2_PLIQUI" , _nPesoLi   })
			aAdd(_a920Dados,{"F2_PBRUTO" , _nPesoBr   })
			aAdd(_a920Dados,{"F2_FIMP"   , "T"        })
			aAdd(_a920Dados,{"F2_VALFAT" , _nVlrFat   })
			aAdd(_a920Dados,{"F2_ZIDDTMX", _cIdDatamex})

			// valor do frete
			If (_nVlrFrete > 0).and.(_lIsCte)

				// codigo da TES utilizada
				_cCodTES := sfRetTES(_cCodCFOP, _cSitTrib, _lIncIcms, @_lDocSaiOk, _lIsCte, _lNFSRet)

				// inclui o item do valor de frete
				_aItem := {;
				{"D2_ITEM"   , _cItem      , NIL},;
				{"D2_COD"    , "2001000001", NIL},;
				{"D2_QUANT"  , 1           , NIL},;
				{"D2_PRCVEN" , _nVlrFrete  , NIL},;
				{"D2_PRUNIT" , _nVlrFrete  , NIL},;
				{"D2_TOTAL"  , _nVlrFrete  , NIL},;
				{"D2_TES"    , _cCodTES    , NIL},;
				{"D2_CF"     , _cCodCFOP   , NIL},;
				{"D2_PICM"   , _nAliqIcms  , NIL},;
				{"D2_VALICM" , _nVlrIcms   , NIL},;
				{"D2_EST"    , _cCliEst    , NIL},;
				{"D2_LOCAL"  , '01'        , NIL},;
				{"D2_ZIDDTMX", _cIdDatamex , NIL},;
				{"AUTDELETA" , "N"         , NIL} }

				// inclui o item
				aAdd(_aItensSD2,_aItem)
				// controle do item
				_cItem := Soma1(_cItem)
			EndIf

			// valor do pegagio, quando tem tributacao diferente
			If (_lPedIseIcms).and.(_nVlrPedagio > 0).and.(_lIsCte)

				// codigo da TES utilizada
				_cCodTES := sfRetTES(_cCodCFOP, _cSitTrib, .f., @_lDocSaiOk, _lIsCte, _lNFSRet)

				// inclui o item do valor de pedagio
				_aItem := {;
				{"D2_ITEM"   , _cItem      , NIL},;
				{"D2_COD"    , "2001000001", NIL},;
				{"D2_QUANT"  , 1           , NIL},;
				{"D2_PRCVEN" , _nVlrPedagio, NIL},;
				{"D2_PRUNIT" , _nVlrPedagio, NIL},;
				{"D2_TOTAL"  , _nVlrPedagio, NIL},;
				{"D2_TES"    , _cCodTES    , NIL},;
				{"D2_CF"     , _cCodCFOP   , NIL},;
				{"D2_EST"    , _cCliEst    , NIL},;
				{"D2_LOCAL"  , '01'        , NIL},;
				{"D2_ZIDDTMX", _cIdDatamex , NIL},;
				{"AUTDELETA" , "N"         , NIL} }

				// inclui o item
				aAdd(_aItensSD2,_aItem)
				// controle do item
				_cItem := Soma1(_cItem)
			EndIf

			// valor do servico
			If (_nVlrTotal > 0).and.(_lIsNfs)

				_cCodTES := sfRetTES(_cCodCFOP, _cSitTrib, _lIncISS, @_lDocSaiOk, _lIsCte, _lNFSRet)

				If (_oXmlDocSai:_LINHA[_nXML]:_COD_ATIVIDADE:TEXT == "1602") .AND. (cFilAnt != "104")
					_cCodSrv := "9001751"
				ElseIf (_oXmlDocSai:_LINHA[_nXML]:_COD_ATIVIDADE:TEXT == "1602") .AND. (cFilAnt == "104")
					_cCodSrv := "9001752"                                              
				Elseif (_lNFSRet)
					_cCodSrv := "9001000004"
				Else
					_cCodSrv := "9001000002"
				EndIf

				// inclui o item do valor de frete
				_aItem := {;
				{"D2_ITEM"   , _cItem      , NIL},;
				{"D2_COD"    , _cCodSrv    , NIL},;
				{"D2_QUANT"  , 1           , NIL},;
				{"D2_PRCVEN" , _nVlrTotal  , NIL},;
				{"D2_PRUNIT" , _nVlrTotal  , NIL},;
				{"D2_TOTAL"  , _nVlrTotal  , NIL},;
				{"D2_TES"    , _cCodTES    , NIL},;
				{"D2_CF"     , _cCodCFOP   , NIL},;
				{"D2_PICM"   , _nAliqISS   , NIL},;
				{"D2_VALICM" , _nVlrISS    , NIL},;
				{"D2_EST"    , _cCliEst    , NIL},;
				{"D2_LOCAL"  , '01'        , NIL},;
				{"D2_ZIDDTMX", _cIdDatamex , NIL},;
				{"AUTDELETA" , "N"         , NIL} }

				// inclui o item
				aAdd(_aItensSD2,_aItem)
				// controle do item
				_cItem := Soma1(_cItem)
			EndIf

		EndIf

		If (_lDocSaiOk).and.(_lGeraDoc)

			// posiciona no cadastro do cliente
			dbselectarea("SA1")
			SA1->(dbsetorder(1))
			SA1->(dbseek( xfilial("SA1")+c920Client+c920Loja ))

			// caso documento seja com impostos retidos, então altera temporariamente a natureza no cadastro do cliente
			// para uma que calcule com retenção. Isto é necessário pois o sistema OU pega a natureza do cadastro
			// do cliente OU do pedido de venda, que neste caso, não existe pois está gerando direto doc. saída
			If (_lNFSRet)
				_cTmpNat := SA1->A1_NATUREZ  // guarda a natureza anterior do cliente (padrão)
				// altera a natureza
				RecLock("SA1")
				SA1->A1_NATUREZ := "01010113"   // Venda de serviço com retenção de TODOS os impostos
				SA1->(MsUnLock())
			EndIf

			// atualiza nome reduzido do cliente
			_cNomReduz := SA1->A1_NREDUZ

			// reinicia variaveis
			lMsErroAuto := .f.

			// rotina automatica de inclusao de nota fiscal de saida manual
			MSExecAuto({|x,y,z| MATA920(x,y,z)}, _aCabSF2, _aItensSD2, 3) // 3-Inclusao

			// quando gerar erro/validacao na rotina automatica
			If (lMsErroAuto)
				// log rotina automatica
				_cLogRotAut := U_FtAchaErro(.T.)
				// mensagem
				_cLogGeral += "   - Erro ao gerar "+_cTpDocLog+" "+SF2->F2_DOC+" (Id.Erro: "+AllTrim(_cLogRotAut)+")"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(c920Nota, "- Erro ao gerar "+_cTpDocLog+" "+SF2->F2_DOC+" (Id.Erro: "+AllTrim(_cLogRotAut)+")", "ERRO")
				// dados ok por cte/nfse
				_lDocSaiOk := .f.
			EndIf
		EndIf

		If (_lDocSaiOk).and.( ! mvCteCanc ).and.((_lGeraDoc).or.(_lIncTitRec)).and.(Empty(_dDataVenc))
			// mensagem
			_cLogGeral += "   - Data de Vencimento não definida para o título do CT-e "+c920Nota+CRLF
			// adiciona log em html
			_cLogHtml += sfLogHtml(c920Nota, "- Data de Vencimento não definida para o título do CT-e "+c920Nota, "ERRO")
			// dados ok por cte/nfse
			_lDocSaiOk := .f.
		EndIf

		// gera os títulos no contas a receber
		// 01/04/2019 - se for nota fiscal com retenção de impostos (_lNFSRet) então não gera
		// pois a fatura será de valor diferente (com realação ao bruto - impostos), e há tratativa especial quando integrar a fatura
		// que irá gerar o título já com o valor dos impostos descontados
		If (_lDocSaiOk) .AND. ( ! mvCteCanc ) .AND. ( (_lGeraDoc) .OR. (_lIncTitRec) ) .AND. !(_lNFSRet) 

			// reposiciona na nota fiscal
			dbSelectArea("SF2")
			SF2->(dbSetOrder(1)) // 1-F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_FORMUL, F2_TIPO
			SF2->(MsSeek( xFilial("SF2") + c920Nota + c920Serie + c920Client + c920Loja ))

			// reinicia variaveis
			_aAutoSE1 := {}

			// valor dos juros
			_nVlrJuros := Round(SF2->F2_VALBRUT * (_nPerJur / 100),2)

			//Inclui contas a Receber
			AAdd(_aAutoSE1,{"E1_PREFIXO" , SF2->F2_SERIE             , Nil})
			AAdd(_aAutoSE1,{"E1_SERIE"   , SF2->F2_DOC               , Nil})
			AAdd(_aAutoSE1,{"E1_NUM"     , SF2->F2_DOC               , Nil})
			AAdd(_aAutoSE1,{"E1_PARCELA" , CriaVar("E1_PARCELA", .f.), Nil})
			AAdd(_aAutoSE1,{"E1_TIPO"    , "NF"                      , Nil})
			AAdd(_aAutoSE1,{"E1_NATUREZ" , IIf(_lNFsRet, "01010113", _cNewNatur)                , Nil})
			AAdd(_aAutoSE1,{"E1_CLIENTE" , SF2->F2_CLIENTE           , Nil})
			AAdd(_aAutoSE1,{"E1_LOJA"    , SF2->F2_LOJA              , Nil})
			AAdd(_aAutoSE1,{"E1_NOMCLI"  , _cNomReduz                , Nil})
			AAdd(_aAutoSE1,{"E1_EMISSAO" , SF2->F2_EMISSAO           , Nil})
			AAdd(_aAutoSE1,{"E1_VENCTO"  , _dDataVenc                , Nil})
			AAdd(_aAutoSE1,{"E1_VALOR"   , SF2->F2_VALBRUT           , Nil})
			AAdd(_aAutoSE1,{"E1_PORCJUR" , _nPerJur                  , Nil})
			AAdd(_aAutoSE1,{"E1_VALJUR"  , _nVlrJuros                , Nil})
			AAdd(_aAutoSE1,{"E1_FLUXO"   , "S"                       , Nil})
			AAdd(_aAutoSE1,{"E1_TIPODES" , "1"                       , Nil})

			// ordena o vetor conforme dicionario de dados
			_aAutoSE1 := FWVetByDic(_aAutoSE1, 'SE1', .F.)

			// executa rotina automatica de geracao de titulos
			lMsErroAuto = .F.
			MSExecAuto({|x,y| Fina040(x,y)}, _aAutoSE1, 3) // 3-Incluir

			// erro na rotina automatica
			If (lMsErroAuto)
				// log rotina automatica
				_cLogRotAut := U_FtAchaErro(.T.)
				// mensagem
				_cLogGeral += "   - Erro ao gerar titulo do "+_cTpDocLog+" "+SF2->F2_DOC+" (Id.Erro: "+AllTrim(_cLogRotAut)+")"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(c920Nota, "- Erro ao gerar titulo do "+_cTpDocLog+" "+SF2->F2_DOC+" (Id.Erro: "+AllTrim(_cLogRotAut)+")", "ERRO")
				// dados ok por cte/nfse
				_lDocSaiOk := .f.

			EndIf

			If (_lDocSaiOk)

				// atualiza dados do titulo no documento de saida (cte E/OU nfse)
				dbSelectArea("SF2")
				RecLock("SF2")
				SF2->F2_DUPL    := SF2->F2_DOC
				SF2->F2_PREFIXO := SF2->F2_SERIE
				SF2->(MsUnLock())

			EndIf

		EndIf

		If (_lDocSaiOk).and.(mvCteCanc)

			// posiciona no cadastro do cliente
			dbselectarea("SA1")
			SA1->(dbsetorder(1))
			SA1->(dbseek( xfilial("SA1")+c920Client+c920Loja ))

			// realiza a exclusao
			If (_lExcTitRec)

				// reinicia variaveis
				_aAutoSE1 := {}

				// posiciona no titulo a receber
				dbSelectArea("SE1")
				SE1->( dbSetOrder(2) ) // 2-E1_FILIAL, E1_CLIENTE, E1_LOJA, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO
				SE1->( dbSeek( xFilial("SE1") + SA1->A1_COD + SA1->A1_LOJA + c920Serie + c920Nota ) )

				// atualiza variavel para exclusao contas a Receber
				AAdd(_aAutoSE1,{"E1_PREFIXO", SE1->E1_PREFIXO, Nil})
				AAdd(_aAutoSE1,{"E1_SERIE"  , SE1->E1_SERIE  , Nil})
				AAdd(_aAutoSE1,{"E1_NUM"    , SE1->E1_NUM    , Nil})
				AAdd(_aAutoSE1,{"E1_PARCELA", SE1->E1_PARCELA, Nil})
				AAdd(_aAutoSE1,{"E1_TIPO"   , SE1->E1_TIPO   , Nil})
				AAdd(_aAutoSE1,{"E1_NATUREZ", SE1->E1_NATUREZ, Nil})
				AAdd(_aAutoSE1,{"E1_CLIENTE", SE1->E1_CLIENTE, Nil})
				AAdd(_aAutoSE1,{"E1_LOJA"   , SE1->E1_LOJA   , Nil})
				AAdd(_aAutoSE1,{"E1_NOMCLI" , SE1->E1_NOMCLI , Nil})
				AAdd(_aAutoSE1,{"E1_EMISSAO", SE1->E1_EMISSAO, Nil})
				AAdd(_aAutoSE1,{"E1_VENCTO" , SE1->E1_VENCTO , Nil})
				AAdd(_aAutoSE1,{"E1_VALOR"  , SE1->E1_VALOR  , Nil})

				// ordena o vetor conforme dicionario de dados
				_aAutoSE1 := FWVetByDic(_aAutoSE1, 'SE1', .F.)

				// executa rotina automatica de geracao de titulos
				lMsErroAuto = .F.
				MSExecAuto({|x,y| Fina040(x,y)}, _aAutoSE1, 5) // 5-Excluir

				// quando gerar erro/validacao na rotina automatica
				If (lMsErroAuto)
					// log rotina automatica
					_cLogRotAut := U_FtAchaErro(.T.)
					// mensagem
					_cLogGeral += "   - Erro ao excluir titulo do "+_cTpDocLog+" "+SF2->F2_DOC+" (Id.Erro: "+AllTrim(_cLogRotAut)+")"+CRLF
					// adiciona log em html
					_cLogHtml += sfLogHtml(c920Nota, "- Erro ao excluir titulo do "+_cTpDocLog+" "+SF2->F2_DOC+" (Id.Erro: "+AllTrim(_cLogRotAut)+")", "ERRO")
					// dados ok por cte/nfse
					_lDocSaiOk := .f.
				EndIf

			EndIf

			// atualiza a flag de controle de emissao de notas fiscais atraves do modulo livros fiscais (verificar PE MT920IT)
			dbSelectArea("SD2")
			SD2->(dbSetOrder(3)) // 3-D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, D2_COD, D2_ITEM
			SD2->(dbSeek( _cSeekSD2 := xFilial("SD2") + c920Nota + c920Serie + SA1->A1_COD + SA1->A1_LOJA  ) )

			// varre todos os itens da nota fiscal
			While SD2->( ! Eof() ).and.(SD2->(D2_FILIAL + D2_DOC + D2_SERIE + D2_CLIENTE + D2_LOJA) == _cSeekSD2)
				// atualiza campo de controle
				RecLock("SD2")
				SD2->D2_ORIGLAN := "LF"
				SD2->(MsUnLock())
				// proximo item
				SD2->(dbSkip())
			EndDo

			// rotina automatica de exclusao de nota fiscal de saida manual
			lMsErroAuto := .F.
			MSExecAuto({|x,y,z| MATA920(x,y,z)}, _aCabSF2, _aItensSD2, 5) // 5-Exclusao

			// quando gerar erro/validacao na rotina automatica
			If (lMsErroAuto)
				// log rotina automatica
				_cLogRotAut := U_FtAchaErro(.T.)
				// mensagem
				_cLogGeral += "   - Erro ao excluir "+_cTpDocLog+" "+SF2->F2_DOC+" (Id.Erro: "+AllTrim(_cLogRotAut)+")"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(c920Nota, "- Erro ao excluir "+_cTpDocLog+" "+SF2->F2_DOC+" (Id.Erro: "+AllTrim(_cLogRotAut)+")", "ERRO")
				// dados ok por cte/nfse
				_lDocSaiOk := .f.
			EndIf
		EndIf

		// importacao de documentos validos
		If (_lDocSaiOk).and.( ! mvCteCanc )
			// log geral
			_cLogGeral += "   - "+_cTpDocLog+" integrado com sucesso"+CRLF
			// adiciona log em html
			_cLogHtml += sfLogHtml(c920Nota, "- "+_cTpDocLog+" integrado com sucesso", "OK")

			// realiza bloqueio de integracao
			If ! sfFlagInt(mvTipoDoc, _cIdDatamex, .t., Nil, .f.)
				// log geral
				_cLogGeral += "   - Erro no bloqueio de integração. Contate TI. ("+mvTipoDoc+"/id: "+AllTrim(_cIdDatamex)+")"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(c920Nota, "- Erro no bloqueio de integração. Contate TI. ("+mvTipoDoc+"/id: "+AllTrim(_cIdDatamex)+")", "ERRO")

			EndIf

		EndIf

		// importacao de documentos cancelados
		If (_lDocSaiOk).and.( mvCteCanc )
			// log geral
			_cLogGeral += "   - "+_cTpDocLog+" cancelado com sucesso"+CRLF
			// adiciona log em html
			_cLogHtml += sfLogHtml(c920Nota, "- "+_cTpDocLog+" cancelado com sucesso", "OK")

			// realiza bloqueio de integracao
			If ! sfFlagInt(mvTipoDoc, _cIdDatamex, .t., Nil, .t.)
				// log geral
				_cLogGeral += "   - Erro no bloqueio de integração. Contate TI. ("+mvTipoDoc+"/id: "+AllTrim(_cIdDatamex)+")"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(c920Nota, "- Erro no bloqueio de integração. Contate TI. ("+mvTipoDoc+"/id: "+AllTrim(_cIdDatamex)+")", "ERRO")

			EndIf

		EndIf

		// libera todos os registros
		MsUnLockAll()

		// se nota fiscal com retenção de impostos
		If (_lNFSRet)
			U_FtMail("NF de escolta armada com retenção integrada: " + c920Nota + "/" + c920Serie + CRLF + "Nat antiga: " + _cTmpNat + "/" + " nat usada: " + SA1->A1_NATUREZ,;
			"Four - Integração datamex com retenção",;
			"ti@tecadi.com.br")

			// retorna a natureza do cliente
			RecLock("SA1")
			SA1->A1_NATUREZ := _cTmpNat
			SA1->( MsUnLock() )

		EndIf

		// proximo CTe
	Next _nXML

Return(.t.)

// ** funcao que padroniza o numero do CT-e
Static Function sfRetNum(mvNumCTe, mvStrZero, mvTamPadr)
	// variavel de retorno
	local _cRet := ""
	// variaveis temporarias
	local _nX

	// caso venha como "integer", convert para "String"
	If (ValType(mvNumCTe) == "N")
		mvNumCTe := AllTrim(Str(mvNumCTe,mvTamPadr,0))
	EndIf

	// remove espacos
	mvNumCTe := AllTrim(mvNumCTe)

	// varre a string para remover caracter "nao" numericos
	For _nX := 1 to Len(mvNumCTe)

		// valida caracter
		If (SubStr(mvNumCTe,_nX,1) >= "0").and.(SubStr(mvNumCTe,_nX,1) <= "9")
			_cRet += SubStr(mvNumCTe,_nX,1)
		EndIf

	Next _nX

	// verifica necessidade de zeros a esquerda
	If (mvStrZero)
		_cRet := StrZero(Val(_cRet),mvTamPadr)
	EndIf

	// padroniza o tamanho da variavel
	_cRet := PadR(_cRet, mvTamPadr)

Return(_cRet)

// ** funcao que valida/cadastra o cliente
Static Function sfVldCliente(mvCliID, mvVldCad, mvInscEst, mvCliPais)

	// area atual
	local _aAreaSA1 := SA1->(GetArea())

	// variavel com os dados do cliente
	Local _aDadosSA1 := {}

	// variavel de retorno
	local _lProcOk := .t.

	// flag para inclusao de cliente
	local _lIncCliente := .t.
	local _lJaCad      := .f.
	local _nOpcMnu     := 3

	// cnpj
	local _cCnpjCli := ""
	// Juridica / Fisica
	local _cTpPessoa := ""
	// razao social
	local _cNomeCli := ""
	// endereco
	Local _cEndereco := ""
	// estado (UF)
	local _cEstado := ""
	// cidade
	local _cMunicipio := ""
	// Verifica código do IBGE
	local _cCodIBGE := ""
	// bairro
	local _cBairro := ""
	// CEP
	local _cCEP := ""
	// inscr estadual
	local _cInscEst := IIF((ValType(mvCliPais) == "C").and.(AllTrim(Upper(mvCliPais)) == "BRASIL"), mvInscEst, "ISENTO")
	// pais
	local _cPaisBac := ""
	local _cCodPais := ""
	// email
	local _cEmailCte := ""
	// codigo da regiao
	local _cCodReg := ""

	// conexao com Token Datamex através de Restful/API
	Local _oCnxRest := FwRest():New(SuperGetMv("TC_DTMXURL",,"http://tecadi.e-login.net"))

	// configuracao do Header
	Local _aHeadRest := {"tenantId: 99,01"}

	// dados do retorno da chamada Restful/API
	local _aRetDados
	local _cGetRes

	// controle dos dados de Parse do XML
	local _oXML
	local _cError   := ""
	local _cWarning := ""

	// log rotina automatica
	local _cLogRotAut := ""

	// inclui o campo Authorization no formato <usuario>:<senha> na base64
	Aadd(_aHeadRest, "Authorization: Basic " + Encode64(SuperGetMv("TC_DTMXUSR",,"tecadi:t3c@d1")))

	// chamada da classe exemplo de REST com retorno de lista (XML)
	_oCnxRest:SetPath( sfRetRotinas("C01")[1][4]+mvCliID )

	// executa Get do Header
	If _oCnxRest:Get(_aHeadRest)
		// atualiza dados quando conexao ok
		_cGetRes := _oCnxRest:GetResult()
		// controle de processamento
		_lProcOk := .t.
	Else
		// busca mensagem de erro na busca dos dados
		_cGetRes := _oCnxRest:GetLastError()
		// controle de processamento
		_lProcOk := .f.
		// mensagem
		_cLogGeral += "   - Erro na conexão da API do Cliente ID: "+AllTrim(mvCliID)+" (Id.Erro: "+AllTrim(_cGetRes)+")"+CRLF
		// adiciona log em html
		_cLogHtml += sfLogHtml(c920Nota, "- Erro na conexão da API do Cliente ID: "+AllTrim(mvCliID)+" (Id.Erro: "+AllTrim(_cGetRes)+")", "ERRO")

	EndIf

	// prepara objeto XML
	If (_lProcOk)
		// parse no XML
		_oXML := XmlParser(_cGetRes, "_", @_cError, @_cWarning )

		// valida montagem/parse correta do XML
		If ( ( _oXML == Nil ) .or. ( ! Empty(_cError) ) .or. ( ! Empty(_cWarning) ) )
			// controle de processamento
			_lProcOk := .f.
			// mensagem
			_cLogGeral += "   - Erro conversão do XML Cliente ID: "+AllTrim(mvCliID)+" (Id.Erro: "+AllTrim(_cError)+" / "+AllTrim(_cWarning)+")"+CRLF
			// adiciona log em html
			_cLogHtml += sfLogHtml(c920Nota, "- Erro conversão do XML Cliente ID: "+AllTrim(mvCliID)+" (Id.Erro: "+AllTrim(_cError)+" / "+AllTrim(_cWarning)+")", "ERRO")

		EndIf

	EndIf

	/*
	CODIGO
	NOME
	LOGRAD
	NUMERO
	COMPL
	BAIRRO
	CIDADE
	CODIBGE
	ESTADO
	CEP
	TELEFONE
	EMAIL
	DT_NASC
	INSC_INSS
	RG_NUMERO
	RG_ORG_EMI
	RG_DT_EMI
	RG_EST_EMI
	CPF
	NUM_DEP
	FIL_MAE
	RAZ_SOCIAL
	*/

	// atualiza variaveis
	If (_lProcOk)
		// cnpj
		_cCnpjCli := AllTrim(Upper(_oXML:_ROOT:_LINHA:_CPF:TEXT))
	EndIf

	// pesquisa se o cliente ja esta cadastrado
	If (_lProcOk)
		// pesquisa o cliente
		dbSelectArea("SA1")
		SA1->(dbSetOrder(3)) //3-A1_FILIAL, A1_CGC
		If SA1->(dbSeek(xFilial("SA1") + _cCnpjCli ))
			// controle para alteracao
			_lIncCliente := .f.
			// atualiza variaveis de retorno
			c920Client := SA1->A1_COD
			c920Loja   := SA1->A1_LOJA
			_cCodCli   := SA1->A1_COD
			_cLojCli   := SA1->A1_LOJA
			_cCliEst   := SA1->A1_EST
			_cTipoCli  := SA1->A1_TIPO
			// codigo da regiao
			_cCodReg   := SA1->A1_CDRDES
			// cliente ja cadastrado
			_lJaCad    := .t.
			// opcao para alterar
			_nOpcMnu   := 4

		EndIf
	EndIf

	// se for soh validacao
	If (mvVldCad)
		Return( _lJaCad )
	EndIf

	// atualiza variaveis
	If (_lProcOk)

		// tipo do cliente
		_cTpPessoa  := IIf(Len(AllTrim(_cCnpjCli))==14, "J", "F")
		// razao social
		_cNomeCli   := FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_RAZ_SOCIAL:TEXT)))
		// se campo RAZAO SOCIAL nao for informado
		_cNomeCli   := IIf( ! Empty(_cNomeCli), _cNomeCli, FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_NOME:TEXT))))
		// endereco
		_cEndereco  := FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_LOGRAD:TEXT)))+", "
		_cEndereco  += FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_NUMERO:TEXT)))+" "
		_cEndereco  += FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_COMPL:TEXT)))+" "
		// estado (UF)
		_cEstado    := FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_ESTADO:TEXT)))
		// cidade
		_cMunicipio := FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_CIDADE:TEXT)))
		// Verifica código do IBGE
		_cCodIBGE   := SubStr(AllTrim(Upper(_oXML:_ROOT:_LINHA:_CODIBGE:TEXT)),3,5)
		// bairro
		_cBairro    := FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_BAIRRO:TEXT)))
		// CEP
		_cCEP       := AllTrim(StrTran(_oXML:_ROOT:_LINHA:_CEP:TEXT,"-",""))
		// email
		_cEmailCte  := AllTrim(_oXML:_ROOT:_LINHA:_EMAIL:TEXT)
		_cEmailCte  := IIf(Empty(_cEmailCte), ".", _cEmailCte)
		// pais
		_cPaisBac   := sfRetPais(mvCliPais, "BACEN")
		_cCodPais   := sfRetPais(mvCliPais, "")
		// tipo do cliente (F-Cons. Final/X-Exportacao)
		_cTipoCli   := IIf(_cEstado == "EX", "X", "F")
		// codigo da regiao
		_cCodReg    := (_cEstado+"GERA")
	EndIf

	// atualiza variaveis
	If (_lProcOk)

		// alimenta Vetor com os dados do cliente a ser Cadastrado/atualizado
		aAdd(_aDadosSA1,{"A1_CGC"     , PadR(_cCnpjCli  , TamSx3("A1_CGC")[1]    ) , NIL}) // CPF/CNPJ
		aAdd(_aDadosSA1,{"A1_PESSOA"  , PadR(_cTpPessoa , TamSx3("A1_PESSOA")[1] ) , NIL}) // F-Fisica/J-Juridica
		aAdd(_aDadosSA1,{"A1_NOME"    , PadR(_cNomeCli  , TamSx3("A1_NOME")[1]   ) , NIL}) // nome
		aAdd(_aDadosSA1,{"A1_NREDUZ"  , PadR(_cNomeCli  , TamSx3("A1_NREDUZ")[1] ) , NIL}) // nome fantasia
		aAdd(_aDadosSA1,{"A1_END"     , PadR(_cEndereco , TamSx3("A1_END")[1]    ) , NIL}) // endereco
		aAdd(_aDadosSA1,{"A1_TIPO"    , PadR(_cTipoCli  , TamSx3("A1_TIPO")[1]   ) , NIL}) // tipo do cliente (F-Cons. Final/X-Exportacao)
		aAdd(_aDadosSA1,{"A1_EST"     , PadR(_cEstado   , TamSx3("A1_EST")[1]    ) , NIL}) // estado
		aAdd(_aDadosSA1,{"A1_ESTC"    , PadR(_cEstado   , TamSx3("A1_ESTC")[1]   ) , NIL}) // estado de cobranca
		aAdd(_aDadosSA1,{"A1_COD_MUN" , PadR(_cCodIBGE  , TamSx3("A1_COD_MUN")[1]) , NIL}) // codigo do municipio
		aAdd(_aDadosSA1,{"A1_MUN"     , PadR(_cMunicipio, TamSx3("A1_MUN")[1]    ) , NIL}) // descricao do municipio
		aAdd(_aDadosSA1,{"A1_MUNC"    , PadR(_cMunicipio, TamSx3("A1_MUNC")[1]   ) , NIL}) // descricao do municipio de cobranca
		aAdd(_aDadosSA1,{"A1_BAIRRO"  , PadR(_cBairro   , TamSx3("A1_BAIRRO")[1] ) , NIL}) // bairro
		aAdd(_aDadosSA1,{"A1_BAIRROC" , PadR(_cBairro   , TamSx3("A1_BAIRROC")[1]) , NIL}) // bairro de cobranca
		aAdd(_aDadosSA1,{"A1_CEP"     , PadR(_cCEP      , TamSx3("A1_CEP")[1]    ) , NIL}) // CEP
		aAdd(_aDadosSA1,{"A1_CEPC"    , PadR(_cCEP      , TamSx3("A1_CEPC")[1]   ) , NIL}) // CEP de cobranca
		aAdd(_aDadosSA1,{"A1_INSCR"   , PadR(_cInscEst  , TamSx3("A1_INSCR")[1]  ) , NIL}) // insc estadual
		aAdd(_aDadosSA1,{"A1_PAIS"    , PadR(_cCodPais  , TamSx3("A1_PAIS")[1]   ) , NIL}) // pais
		aAdd(_aDadosSA1,{"A1_CODPAIS" , PadR(_cPaisBac  , TamSx3("A1_CODPAIS")[1]) , NIL}) // pais do BACEN
		aAdd(_aDadosSA1,{"A1_EMAIL"   , PadR(_cEmailCte , TamSx3("A1_EMAIL")[1]  ) , NIL}) // e-mail do cliente
		aAdd(_aDadosSA1,{"A1_ZNFSE"   , PadR(_cEmailCte , TamSx3("A1_ZNFSE")[1]  ) , NIL}) // e-mail nfs-e do cliente
		aAdd(_aDadosSA1,{"A1_COND"    , PadR(_cCodCond  , TamSx3("A1_COND")[1]   ) , NIL}) // condicao de pagamento
		aAdd(_aDadosSA1,{"A1_CDRDES"  , PadR(_cCodReg   , TamSx3("A1_CDRDES")[1] ) , NIL}) // regiao do cliente
		aAdd(_aDadosSA1,{"A1_NATUREZ" , PadR("01010101" , TamSx3("A1_NATUREZ")[1] ) , NIL}) // natureza financeira padrão
		aAdd(_aDadosSA1,{"A1_RECINSS" , PadR("S"        , TamSx3("A1_RECINSS")[1] ) , NIL}) // flag para recolher inss
		aAdd(_aDadosSA1,{"A1_RECCOFI" , PadR("S"        , TamSx3("A1_RECCOFI")[1] ) , NIL}) // flag para recolher cofins
		aAdd(_aDadosSA1,{"A1_RECCSLL" , PadR("S"        , TamSx3("A1_RECCSLL")[1] ) , NIL}) // flag para recolher CSLL
		aAdd(_aDadosSA1,{"A1_RECPIS"  , PadR("S"        , TamSx3("A1_RECPIS")[1] )  , NIL}) // flag para recolher PIS
		aAdd(_aDadosSA1,{"A1_RECIRRF" , PadR(1          , TamSx3("A1_RECIRRF")[1] ) , NIL}) // flag para recolher IRRF

		// se for alteracao, inclui campos codigo e loja
		If ( ! _lIncCliente )
			aAdd(_aDadosSA1,{"A1_COD"  , _cCodCli                             , NIL}) // codigo
			aAdd(_aDadosSA1,{"A1_LOJA" , _cLojCli                             , NIL}) // loja
		EndIf

		// padroniza dicionario de dados
		_aDadosSA1 := FWVetByDic(_aDadosSA1, 'SA1', .F.)

		// variavel padrao
		lMsErroAuto := .F.

		// reposiciona no registro
		DbSelectArea("SA1")
		SA1->(dbSetOrder(1)) // 1-A1_FILIAL, A1_COD, A1_LOJA

		// rotina automatica de cadastro de cliente
		MSExecAuto({|x,y| MATA030(x,y)}, _aDadosSA1, _nOpcMnu ) // 3-Inclusao / 4-Alteracao

		// erro de rotina automatica
		If (lMsErroAuto)
			// log rotina automatica
			_cLogRotAut := U_FtAchaErro(.T.)
			// mensagem
			_cLogGeral += "   - Erro rotina automática Cadastro de Cliente "+AllTrim(_cCliNome)+" (Id.Pessoa: "+mvCliID+" / Id.Erro: "+AllTrim(_cLogRotAut)+")"+CRLF
			// adiciona log em html
			_cLogHtml += sfLogHtml(c920Nota, "- Erro rotina automática Cadastro de Cliente "+AllTrim(_cCliNome)+" (Id.Pessoa: "+mvCliID+" / Id.Erro: "+AllTrim(_cLogRotAut)+")", "ERRO")
			// controle de processamento
			_lProcOk := .f.
		Endif

	EndIf

	// dados Ok
	If (_lProcOk)

		// atualiza variaveis de retorno
		c920Client  := SA1->A1_COD
		c920Loja    := SA1->A1_LOJA
		_cCliEst    := SA1->A1_EST

	EndIf

Return(_lProcOk)

// ** funcao que retorna e define as rotinas disponiveis de integracao
Static Function sfRetRotinas(mvCodigo, mvFormato)
	// variavel de retorno
	local _aRet := {}

	// valor padrao
	Default mvCodigo  := ""
	Default mvFormato := "XML"

	// CONHECIMENTOS DE TRANSPORTE:
	// Conhecimentos de transporte / Dados básicos
	// URL: tecadi.e-login.net/scripts/?cmd=ambiente.consultasSQL&t=$6$KdNvWfq/$ZxJ/58M3G5g2YqT11HwGaZ0Rk1AqqLRo6t..z/&f=XML
	If ((nModulo == 43).or.(_lWorkFlow)).and.((Empty(mvCodigo)).or.(mvCodigo == "001"))
		aAdd(_aRet,{"001", "MOV", "Conhecimentos de Transporte / Documentos Válidos","/scripts/?cmd=ambiente.consultasSQL&t=$6$KdNvWfq/$ZxJ/58M3G5g2YqT11HwGaZ0Rk1AqqLRo6t..z/&f="+mvFormato})
	EndIf

	// Conhecimentos de Transporte / Cancelamentos
	// URL: tecadi.e-login.net/scripts/?cmd=ambiente.consultasSQL&t=$6$Acy1X5ne$zY60uIG22Ij.i2U6/JoCHZ64vJ5MRnPeYMLjE8&f=XML&param_DataHoraInicio=09/05/2016 00:00:00&param_DataHoraFim=09/05/2016 23:59:59
	If ((nModulo == 43).or.(_lWorkFlow)).and.((Empty(mvCodigo)).or.(mvCodigo == "003"))
		aAdd(_aRet,{"003", "MOV", "Conhecimentos de Transporte / Cancelamentos","/scripts/?cmd=ambiente.consultasSQL&t=$6$Acy1X5ne$zY60uIG22Ij.i2U6/JoCHZ64vJ5MRnPeYMLjE8&f="+mvFormato})
	EndIf

	// Conhecimentos de transporte / Inutilização
	// URL: tecadi.e-login.net/scripts/?cmd=ambiente.consultasSQL&t=_CT__Inutilizacao_$6$cF3bJ6wP$wrwhqG5p/8XLDK5vp9l2i3X2PZfo1g9Wd2e7WHv.J1sQM/ZlLYamvwTjZJWBIuMNnfUOw7CU5Ba1gfSV8p1Wu1&formato=HTML
	If ((nModulo == 43).or.(_lWorkFlow)).and.((Empty(mvCodigo)).or.(mvCodigo == "004"))
		aAdd(_aRet,{"004", "MOV", "Conhecimentos de Transporte / Inutilização","/scripts/?cmd=ambiente.consultasSQL&t=_CT__Inutilizacao_$6$cF3bJ6wP$wrwhqG5p/8XLDK5vp9l2i3X2PZfo1g9Wd2e7WHv.J1sQM/ZlLYamvwTjZJWBIuMNnfUOw7CU5Ba1gfSV8p1Wu1&f="+mvFormato})
	EndIf

	// Notas Fiscais de Serviço / Documentos Válidos
	// URL: http://tecadi.e-login.net/scripts/?cmd=ambiente.consultasSQL&t=$6$N0laYUqX$9O7cYuBUFJGg3jBP.y93NjGBq5urpZCxs/FjTn&f=HTML
	If ((nModulo == 43).or.(_lWorkFlow)).and.((Empty(mvCodigo)).or.(mvCodigo == "005"))
		aAdd(_aRet,{"005", "MOV", "Notas Fiscais de Serviço / Documentos Válidos","/scripts/?cmd=ambiente.consultasSQL&t=$6$N0laYUqX$9O7cYuBUFJGg3jBP.y93NjGBq5urpZCxs/FjTn&formato="+mvFormato})
	EndIf

	// Notas Fiscais de Serviço / Cancelamentos
	// URL: http://tecadi.e-login.net/scripts/?cmd=ambiente.consultasSQL&t=$6$K7E3o4zU$qy7xyCEP3Y0lc/6J7epYrsk2n/zXgLlWhki6ZL&f=HTML
	If ((nModulo == 43).or.(_lWorkFlow)).and.((Empty(mvCodigo)).or.(mvCodigo == "006"))
		aAdd(_aRet,{"006", "MOV", "Notas Fiscais de Serviço / Cancelamentos","/scripts/?cmd=ambiente.consultasSQL&t=$6$K7E3o4zU$qy7xyCEP3Y0lc/6J7epYrsk2n/zXgLlWhki6ZL&f="+mvFormato})
	EndIf

	// FATURAS DE COBRANÇA
	// Faturas de Cobrança / Dados básicos
	// URL:	tecadi.e-login.net/scripts/?cmd=ambiente.consultasSQL&t=$6$3y0KdQfb$SzTBz3o5kbLO2jBCcirr92n6wk8PbdaQGzdC34&f=XML&param_DataEmissaoFatura=20/05/2016
	If ((nModulo == 43).or.(_lWorkFlow)).and.((Empty(mvCodigo)).or.(mvCodigo == "007"))
		aAdd(_aRet,{"007", "MOV", "Faturas de Cobrança / Dados básicos","/scripts/?cmd=ambiente.consultasSQL&t=$6$3y0KdQfb$SzTBz3o5kbLO2jBCcirr92n6wk8PbdaQGzdC34&f="+mvFormato})
	EndIf

	// CONTRATOS DE FRETES - PJ
	// Contratos de Fretes / Pessoas Jurídicas
	// URL:	tecadi.e-login.net/scripts/?cmd=ambiente.consultasSQL&t=_CF__Dados_basicos_-_Pessoas_Juridicas_$6$l5IcVBJu$5Uvm5laGr8tuwJ.ZUmSQ1GdmrxvLMHnMIMx6BNHN12BebnqvbxIo7aom/5P22gW8i0JZyV0KLhUhe9FsLyrKS0&f=HTML
	If ((nModulo == 6).or.(_lWorkFlow)).and.((Empty(mvCodigo)).or.(mvCodigo == "008"))
		aAdd(_aRet,{"008", "MOV", "Contratos de Fretes / Pessoas Jurídicas","/scripts/?cmd=ambiente.consultasSQL&t=_CF__Dados_basicos_-_Pessoas_Juridicas_$6$l5IcVBJu$5Uvm5laGr8tuwJ.ZUmSQ1GdmrxvLMHnMIMx6BNHN12BebnqvbxIo7aom/5P22gW8i0JZyV0KLhUhe9FsLyrKS0&f="+mvFormato})
	EndIf

	// BAIXA DE CONTRATOS DE FRETE - PF e PJ
	// Baixa de Contratos de Fretes
	// URL:	tecadi.e-login.net/scripts/?cmd=ambiente.consultasSQL&t=$6$B/eeXEYN$xFc3w6bHmHoQz9Ig8waGq3GcMUdF0Wtr4xI7Ry&f=HTML
	If ((nModulo == 6).or.(_lWorkFlow)).and.((Empty(mvCodigo)).or.(mvCodigo == "009"))
		aAdd(_aRet,{"009", "MOV", "Baixa de Contratos de Fretes","/scripts/?cmd=ambiente.consultasSQL&t=$6$B/eeXEYN$xFc3w6bHmHoQz9Ig8waGq3GcMUdF0Wtr4xI7Ry&f="+mvFormato})
	EndIf

	// TARIFAS DE CONTRATOS DE FRETE - PF e PJ
	// Tarifas de Contratos de Fretes por Dia (anterior)
	// URL:	tecadi.e-login.net/scripts/?cmd=ambiente.consultasSQL&t=$6$B/eeXEYN$xFc3w6bHmHoQz9Ig8waGq3GcMUdF0Wtr4xI7Ry&f=HTML
	If ((nModulo == 6).or.(_lWorkFlow)).and.((Empty(mvCodigo)).or.(mvCodigo == "010"))
		aAdd(_aRet,{"010", "MOV", "Tarifas de Contratos de Fretes por Dia","/scripts/?cmd=ambiente.consultasSQL&t=$6$B/eeXEYN$xFc3w6bHmHoQz9Ig8waGq3GcMUdF0Wtr4xI7Ry&f="+mvFormato})
	EndIf

	// PRORROGACAO DE VENCIMENTO - BOLETOS
	// Prorrogação de Vencimento - Boletos
	// URL:	tecadi.e-login.net/scripts/?cmd=ambiente.consultasSQL&t=_BOL__Boletos_$6$u10uIrnZ$aDQDoYETG1JM5VOO4ZocTY1PdCuZJQO5aOC1PgRMxwef7jMOxG2ThVSzpfrWPRPBtE4Z2xnZvRsBf4KdQAyWH1&f=html
	If ((nModulo == 6).or.(_lWorkFlow)).and.((Empty(mvCodigo)).or.(mvCodigo == "011"))
		aAdd(_aRet,{"011", "MOV", "Prorrogação de Vencimento - Boletos","/scripts/?cmd=ambiente.consultasSQL&t=_BOL__Boletos_$6$u10uIrnZ$aDQDoYETG1JM5VOO4ZocTY1PdCuZJQO5aOC1PgRMxwef7jMOxG2ThVSzpfrWPRPBtE4Z2xnZvRsBf4KdQAyWH1&f="+mvFormato})
	EndIf

	// PESSOAS
	// URL:	tecadi.e-login.net/scripts/?cmd=ambiente.consultasSQL&t=$6$tBTFSfih$IhwnPaeMdj9WF1F2Wnn3juoMObLlopunu6YNJJ&f=XML&param_PESSOA=21
	If ((Empty(mvCodigo)).or.(mvCodigo == "C01"))
		aAdd(_aRet,{"C01", "CAD", "Pessoas","/scripts/?cmd=ambiente.consultasSQL&t=$6$tBTFSfih$IhwnPaeMdj9WF1F2Wnn3juoMObLlopunu6YNJJ&f="+mvFormato+"&param_PESSOA="})
	EndIf

	// Faturas de Cobrança / Conhecimentos vinculados:
	// URL:	tecadi.e-login.net/scripts/?cmd=ambiente.consultasSQL&t=$6$WnuUdZmR$fDJw22IxIPoDwQJ/rT8xs70NdlUtu1q6pVImm6&f=XML&param_Fatura=12
	If ((Empty(mvCodigo)).or.(mvCodigo == "V01"))
		aAdd(_aRet,{"V01", "VIN", "Faturas de Cobrança / Conhecimentos vinculados","/scripts/?cmd=ambiente.consultasSQL&t=$6$WnuUdZmR$fDJw22IxIPoDwQJ/rT8xs70NdlUtu1q6pVImm6&f="+mvFormato+"&param_Fatura="})
	EndIf

	// Faturas de Cobrança / Boletos emitidos:
	// URL:	tecadi.e-login.net/scripts/?cmd=ambiente.consultasSQL&t=$6$xOWi7zna$.N5irZPXj0zfTGBG7W.2Z3dndcHZeUHwgKQgEB&f=XML&param_Fatura=12
	If ((Empty(mvCodigo)).or.(mvCodigo == "V02"))
		aAdd(_aRet,{"V02", "VIN", "Faturas de Cobrança / Boletos emitidos","/scripts/?cmd=ambiente.consultasSQL&t=$6$xOWi7zna$.N5irZPXj0zfTGBG7W.2Z3dndcHZeUHwgKQgEB&f="+mvFormato+"&param_Fatura="})
	EndIf

Return(_aRet)

//** funcao para converte data (site) em formato data (protheus)
// ex site: 28/12/1972 16:42:21
Static Function sfExtDtHr(mvData, mvRet)
	// variavel de retorno
	Local _xRet

	// valida o formado da data (ex: 1972-12-28 16:42:21)
	If (At("-", mvData) > 0)
		// remove ps hifens (ex: 19721228 16:42:21)
		mvData := StrTran(mvData, "-", "")
		// extrai somente a data 19721228
		mvData := SubStr(mvData, 1, 8)
		// converte em data (ex: 28/12/1972)
		mvData := StoD(mvData)
		// converte em caracter (ex: 28/12/1972)
		mvData := DtoC(mvData)

	EndIf

	If (mvRet == "D") // data
		// extrai somente a data (10 primeiros) - resultado: 28/12/1972
		mvData := SubStr(mvData,1,10)
		// converte Caracter para Data (resultado: 28/12/1972)
		_xRet := CtoD(mvData)

	ElseIf (mvRet == "H") // hora
		// extrai somente a hora inicia na 12, 8 caracter) - resultado: 16:42:21
		mvData := SubStr(mvData,12,8)
		// atualiza variavel de retorno
		_xRet := mvData

	EndIf

Return(_xRet)

// ** funcao que retorna a CFOP
// conteudo recebido: 5352 - Prest. de Serviço de Transp. Estab. industrial
Static Function sfRetCFOP(mvDscCFOP)
	// variavel de retorno
	local _cRetCFOP := mvDscCFOP
	// variaveis de controle
	local _nPosIni := 1
	local _nPosHif := 0

	// busca posicao do higen (-)
	_nPosHif := At("-",_cRetCFOP)

	// extrai texto
	_cRetCFOP := SubStr(_cRetCFOP, _nPosIni, _nPosHif-1)

	// padroniza retorno
	_cRetCFOP := AllTrim(_cRetCFOP)
	_cRetCFOP := PadR(_cRetCFOP,TamSx3("D2_CF")[1])

Return(_cRetCFOP)

// ** funcao que retorna a Situacao Tributaria
// conteudo recebido: 040 - ICMS Isenção
Static Function sfRetSitTrib(mvDscSitTrib)
	// variavel de retorno
	local _cRetSitTrib := mvDscSitTrib
	// variaveis de controle
	local _nPosIni := 1
	local _nPosHif := 0

	// busca posicao do higen (-)
	_nPosHif := At("-",_cRetSitTrib)

	// extrai texto
	_cRetSitTrib := SubStr(_cRetSitTrib, _nPosIni, _nPosHif-1)

	// padroniza retorno
	_cRetSitTrib := AllTrim(_cRetSitTrib)
	_cRetSitTrib := PadR(_cRetSitTrib,TamSx3("D2_CLASFIS")[1])

Return(_cRetSitTrib)

// ** funcao que retorno o codigo do pais
Static Function sfRetPais(mvCliPais, mvTipo)
	// variavel de retorno
	local _cRetCod := ""
	// posicao inicial das tabelas
	local _aArea := GetArea()
	local _aAreaIni := SaveOrd({"CCH","SYA"})

	// codigo bacen
	If (mvTipo == "BACEN")
		dbSelectArea("CCH")
		CCH->(dbSetOrder(2)) // 2-CCH_FILIAL, CCH_PAIS
		If CCH->(dbSeek( xFilial("CCH")+mvCliPais ))
			_cRetCod := CCH->CCH_CODIGO
		EndIf
	Else
		dbSelectArea("SYA")
		SYA->(dbSetOrder(2)) // 2-YA_FILIAL, YA_DESCR, R_E_C_N_O_, D_E_L_E_T_
		If SYA->(dbSeek( xFilial("SYA")+mvCliPais ))
			_cRetCod := SYA->YA_CODGI
		EndIf
	EndIf

	// restaura areas iniciais
	RestOrd(_aAreaIni,.t.)
	RestArea(_aArea)

Return(_cRetCod)

// ** funcao que retorna a TES da operacao
Static Function sfRetTES(mvCfop, mvSitTrib, mvIncImp, mvCteOk, mvIsCte, mvNFSRet)

	// area inicial
	local _aAreaAtu := GetArea()

	// variavel de retorno
	local _cCodRet := CriaVar("D2_TES")

	// variaveis temporaria
	local _cQuery
	local _aCodTES
	// codigo do tributo
	local _cCodTrib

	// tipo do imposto
	local _cTmpImp := IIf(mvIsCte, "ICMS", "ISS")

	// prepara a query para buscar a TES correta
	_cQuery := " SELECT F4_CODIGO "
	// cadastro de TES
	_cQuery += " FROM "+RetSqlTab("SF4")
	// filtro padrao
	_cQuery += " WHERE "+RetSqlCond("SF4")
	// somente TES de saida
	_cQuery += " AND F4_CODIGO > '500' "
	// TES especifica para integracoes
	If (mvIsCte)
		_cQuery += " AND substring(F4_CODIGO,1,2) = '54' "
	EndIf
	// que nao esteja BLOQUEADA
	_cQuery += " AND F4_MSBLQL <> '1' "
	// que movimenta estoque
	_cQuery += " AND F4_ESTOQUE = 'N' "
	// que gera duplicatas
	//	_cQuery += " AND F4_DUPLIC = 'S' "
	// TES especifica para integracoes
	_cQuery += " AND F4_AGREG = 'S' "

	If (mvIsCte)
		// incidencia de icms
		_cQuery += " AND F4_ICM = '"+IIf(mvIncImp, "S", "N")+"' "
		_cQuery += " AND F4_ISS = 'N' "
		// que seja TRIBUTADO livro fiscal de ICMS
		_cQuery += " AND F4_LFICM <> 'N' "
		// situacao tributaria do ICMS
		_cQuery += " AND F4_SITTRIB = '"+SubStr(mvSitTrib,2,2)+"' "

	Else
		// incidencia de ISS
		_cQuery += " AND F4_ICM = 'N' "
		_cQuery += " AND F4_ISS = '"+IIf(mvIncImp, "S", "N")+"' "
		// que NAO seja TRIBUTADO livro fiscal de ICMS
		_cQuery += " AND F4_LFICM = 'N' "

	EndIF

	If (mvNFSRet)
		// nota fiscal com retenção de impostos PIS COFINS CSLL IR INSS
		_cQuery += " AND F4_PISCRED = '3' "
	Else
		_cQuery += " AND F4_PISCRED = '2' "
	EndIf

	// somente remessa para armazenagem
	_cQuery += " AND SUBSTRING(F4_CF,2,3) = '"+SubStr(mvCfop,2,3)+"' "

	memowrit("c:\query\ttmsxdat_sfRetTES.txt", _cQuery)

	// retorno dos dados para o vetor
	_aCodTES := U_SqlToVet(_cQuery)

	// verifica se retornou mais de uma TES
	If (Len(_aCodTES)==1)
		_cCodRet := _aCodTES[1]
	Else
		// controle de processamento
		mvCteOk := .f.
		// log geral
		_cLogGeral += "    - Não foi possível definir a TES para operação CFOP: "+mvCfop+" Sit.Trib: "+mvSitTrib+" Inc."+_cTmpImp+": "+IIf(mvIncImp,"SIM","NÃO")+CRLF
		// adiciona log em html
		_cLogHtml += sfLogHtml(c920Nota, "- Não foi possível definir a TES para operação CFOP: "+mvCfop+" Sit.Trib: "+mvSitTrib+" Inc."+_cTmpImp+": "+IIf(mvIncImp,"SIM","NÃO"), "ERRO")

	EndIf

	// restaura area inicial
	RestArea(_aAreaAtu)

Return(_cCodRet)

// ** funcao para integrar faturas a receber
Static Function sfGrvTitRec(mvXML)

	// variaveis temporaris
	local _nFat

	// numero fatura
	local _cNumFat   := ""
	local _cIdFat    := ""
	local _nTotFat   := 0
	local _nVlrAcre  := 0
	local _nVlrDesc  := 0
	local _nTmpTotal := 0

	// numero do cte
	local _cNumCte := ""
	local _cSerCte := ""
	local _nCte

	// cliente e loja
	local _cCliId   := ""
	local _cCnpjCli  := ""
	local _cNomReduz := ""

	// dados ok por fatura
	local _lFatOk := .f.

	// conexao com Token Datamex através de Restful/API
	Local _oCnxRest := FwRest():New(SuperGetMv("TC_DTMXURL",,"http://tecadi.e-login.net"))

	// configuracao do Header
	Local _aHeadRest := {"tenantId: 99,01"}

	// dados do retorno da chamada Restful/API
	local _aRetDados
	local _cGetRes

	// controle dos dados de Parse do XML
	local _cError   := ""
	local _cWarning := ""

	// controle para gerar faturas
	local _lGeraFat := .f.

	// data de vencimento da fatura
	local _dDataVenc := CtoD("//")

	// data de emissao da fatura
	local _dDtEmisFat := CtoD("//")

	// recno dos CTe
	local _aRecnoSF2 := {}
	local _nRecnoSF2

	// recno dos titulos
	local _aRecnoSE1 := {}
	local _nRecnoSE1

	// variavel para rotina automatica
	local _aAutoSE1 := {}

	// controle de necessidade de inclusao do titulo a receber
	local _lIncTitRec := .f.

	// taxa de juros
	Local _nPerJur := SuperGetMv("MV_TXPER")

	// valor dos juros
	local _nVlrJuros := 0

	// numero da liquidacao
	Local _cNumNewFat
	local _cPrefFat := PadR("TMS", TamSx3("E1_PREFIXO")[1])
	local _cParcFat := StrZero(1 , TamSx3("E1_PARCELA")[1])
	local _cTipoFat := PadR("FT" , TamSx3("E1_TIPO")[1]   )

	// cabecalho e itens com dados da fatura
	Local _aCabFat := {}
	Local _aIteFat := {}

	// filtro dos dados que irao integrar a fatura (liquidacao)
	Local _cFltFat := ""
	local _cTmpNum

	// dados do boleto
	local _lTemBolet := .f.
	local _cBolBanco := ""
	local _cBolAgenc := ""
	local _cBolConta := ""
	local _cBolNosNr := ""

	// id da fatura para usar como referencia (ID CNAB)
	local _cIdCnab   := ""

	// controle da variavel dDataBase para emissao de faturas
	local _dDtBsAtual

	// log rotina automatica
	local _cLogRotAut := ""

	// areas
	local _aArea, _aAreaSE1, _aAreaSA6, _aAreaSF2

	// objeto com os detalhes
	private _oXmlCteFat
	private _oXmlBolFat

	// relacao de todas as faturas disponiveis
	private _oXmlRelFat := mvXML:_ROOT

	// variaveis usadas na funcao sfVldCliente
	private _cCodCli    := ""
	private _cLojCli    := ""
	private _cCliNome   := ""
	private _cTipoCli   := "" // tipo do cliente (F-Cons. Final/X-Exportacao)

	private INCLUI := .T.
	// inclui o campo Authorization no formato <usuario>:<senha> na base64
	Aadd(_aHeadRest, "Authorization: Basic " + Encode64(SuperGetMv("TC_DTMXUSR",,"tecadi:t3c@d1")))

	/*
	IDFat
	Numero
	Dt_emissao
	Dt_venc
	Dt_pagt
	Cli_Desc
	ID_Cli
	Dt_ent
	Tipo
	RefCli
	Conv_id
	Valor
	Agrup_id
	quitado
	situacao
	bloqueio
	VLACRDESC
	*/

	// caso nao for vetor, converte
	If (Type("_oXmlRelFat:_LINHA") != "A")
		XmlNode2Arr(_oXmlRelFat:_LINHA, "_LINHA")
	EndIf

	// define a quantidade de itens a processar
	If ( ! _lWorkFlow )
		_oProcInteg:SetRegua2( Len(_oXmlRelFat:_LINHA) )
	EndIf


	aItens := {}
	For _nFat:= 1 To Len(_oXmlRelFat:_LINHA)
		Aadd(aItens,{AllTrim(_oXmlRelFat:_LINHA[_nFat]:_Numero:TEXT),;
		AllTrim(_oXmlRelFat:_LINHA[_nFat]:_IDFAT:TEXT),;
		AllTrim(_oXmlRelFat:_LINHA[_nFat]:_Cli_Desc:TEXT),;
		sfExtDtHr(_oXmlRelFat:_LINHA[_nFat]:_Dt_emissao:TEXT, "D")})
	Next
	fTelaSel("Selecione as Faturas para integração:",@aItens)

	// varre todos os Cte no XML
	For _nFat := 1 to Len(_oXmlRelFat:_LINHA)

		// reinicia variaveis
		_lFatOk    := .t.
		_nTmpTotal := 0
		_aRecnoSF2 := {}
		_aRecnoSE1 := {}
		_lTemBolet := .f.
		_nVlrAcre  := 0
		_nVlrDesc  := 0

		// dados do boleto
		_cBolBanco := ""
		_cBolAgenc := ""
		_cBolConta := ""

		_aArea := GetArea()
		_aAreaSE1 := SE1->(GetArea())
		_aAreaSA6 := SA6->(GetArea())
		_aAreaSF2 := SF2->(GetArea())

		// controle para gerar faturas
		_lGeraFat := .f.

		// numero da fatura no Datamex
		_cNumFat    := AllTrim(_oXmlRelFat:_LINHA[_nFat]:_Numero:TEXT)

		// atualiza os dados para rotina automatica
		_cIdFat     := AllTrim(_oXmlRelFat:_LINHA[_nFat]:_IDFAT:TEXT)

		//Ignora itens não selecionados na tela.
		If (aScan(aItens,{|x| x[02] == _cIdFat})) == 0
			Loop
		EndIf

		// valor do acrescimo
		If ( Val(_oXmlRelFat:_LINHA[_nFat]:_VLACRDESC:TEXT) > 0 )
			_nVlrAcre   := Val(_oXmlRelFat:_LINHA[_nFat]:_VLACRDESC:TEXT)
		EndIf

		// valor do desconto (o valor esta negativo)
		If ( Val(_oXmlRelFat:_LINHA[_nFat]:_VLACRDESC:TEXT) < 0 )
			_nVlrDesc   := Val(_oXmlRelFat:_LINHA[_nFat]:_VLACRDESC:TEXT) * (-1)
		EndIf

		// valor total da fatura (necessario reduzir o valor do acrescimo)
		_nTotFat    := Val(_oXmlRelFat:_LINHA[_nFat]:_Valor:TEXT) - (_nVlrAcre) + (_nVlrDesc)

		// define o numero do titulo a gerar
		_cNumNewFat := sfRetNum( _cNumFat, .t., TamSx3("E1_NUM")[1] )

		// id do cliente no Datamex
		_cCliID     := AllTrim(_oXmlRelFat:_LINHA[_nFat]:_ID_Cli:TEXT)

		// nome do cliente
		_cCliNome   := AllTrim(_oXmlRelFat:_LINHA[_nFat]:_Cli_Desc:TEXT)

		// data de vencimento
		_dDataVenc  := sfExtDtHr(_oXmlRelFat:_LINHA[_nFat]:_Dt_venc:TEXT, "D")

		// controle se a cobranco eh por boleto
		_lTemBolet := ( AllTrim(_oXmlRelFat:_LINHA[_nFat]:_Conv_id:TEXT) == "2" )

		// data de emissao da fatura
		_dDtEmisFat := sfExtDtHr(_oXmlRelFat:_LINHA[_nFat]:_Dt_emissao:TEXT, "D")

		//CNPJ do registro
		_cCNPJ      := AllTrim(_oXmlRelFat:_LINHA[_nFat]:_EMPRESA:TEXT)

		//Verifica se está importando o registro para a filial correta
		If (_cCNPJ != SM0->M0_CGC)
			_cLogGeral += "Filial corrente divergente do especificado na integração. Fatura " + AllTrim(_cNumFat) + " / (id: " + _cIdFat + ") / Filial " + _cCNPJ + " não integrado." + CRLF
			//proximo item a integrar
			Loop
		EndIF

		// mensagem solicitando confirmacao
		//		If ( ! _lWorkFlow ) /*.and.( ! MsgYesno("Confirma integração da Fatura "+AllTrim(_cNumFat)+" (id: "+_cIdFat+") ?", "Confirmação") )*/
		//			Loop
		//		EndIf

		// incrementa Segunda Regua
		If ( ! _lWorkFlow )
			_oProcInteg:IncRegua2( "Fatura "+AllTrim(_cNumFat) )
		EndIf

		// chamada da classe exemplo de REST com retorno de lista (XML)
		_oCnxRest:SetPath( sfRetRotinas("V01")[1][4]+_cIdFat )

		// mensagem
		_cLogGeral += "  :: FATURA "+_cNumFat+CRLF

		// executa Get do Header
		If _oCnxRest:Get(_aHeadRest)
			// atualiza dados quando conexao ok
			_cGetRes := _oCnxRest:GetResult()
			// controle de processamento
			_lFatOk := .t.
		Else
			// busca mensagem de erro na busca dos dados
			_cGetRes := _oCnxRest:GetLastError()
			// controle de processamento
			_lFatOk := .f.
			// mensagem
			_cLogGeral += "   - Falha na Conexão com Datamex (Ct-e da Fatura) -> "+AllTrim(_cGetRes)+CRLF
			// adiciona log em html
			_cLogHtml += sfLogHtml(_cNumFat, "- Falha na Conexão com Datamex (Ct-e da Fatura) -> "+AllTrim(_cGetRes), "ERRO")
		EndIf

		// prepara objeto XML
		If (_lFatOk)
			// parse no XML
			_oXmlCteFat := XmlParser(_cGetRes, "_", @_cError, @_cWarning )

			// valida montagem/parse correta do XML
			If ( ( _oXmlCteFat == Nil ) .or. ( ! Empty(_cError) ) .or. ( ! Empty(_cWarning) ) )
				// controle de processamento
				_lFatOk := .f.
				// mensagem
				_cLogGeral += "   - Falha no XML Extraído dos Dados Da Fatura -> "+AllTrim(_cError)+" / "+AllTrim(_cWarning)+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(_cNumFat, "- Falha no XML Extraído dos Dados Da Fatura -> "+AllTrim(_cError)+" / "+AllTrim(_cWarning), "ERRO")

			EndIf

		EndIf

		// valida se existe os Ct-e
		If (_lFatOk)

			// caso nao for vetor, converte
			If ValType(_oXmlCteFat:_ROOT:_LINHA) != "A"
				XmlNode2Arr(_oXmlCteFat:_ROOT:_LINHA, "_LINHA")
			EndIf

			// verifica a quantidade de Ct-e na fatura
			_lGeraFat := (Len(_oXmlCteFat:_ROOT:_LINHA) > 1)

			// varre todos os Ct-e vinculados a fatura
			For _nCte := 1 to Len(_oXmlCteFat:_ROOT:_LINHA)

				/*
				ID_Conhec
				Nro_Conhec
				serie
				*/

				// padroniza informacoes do numero e serie do Ct-e
				_cNumCte := sfRetNum( _oXmlCteFat:_ROOT:_LINHA[_nCte]:_Nro_Conhec:TEXT, .t., TamSx3("F2_DOC")[1] )
				_cSerCte := Padr( _oXmlCteFat:_ROOT:_LINHA[_nCte]:_serie:TEXT,TamSx3("F2_SERIE")[1])

				// Verifica se a nota fiscal/cte já está digitada no sistema
				dbSelectArea("SF2")
				SF2->(dbSetOrder(1)) // 1-F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_FORMUL, F2_TIPO
				If ! SF2->(dbSeek( xFilial("SF2")+_cNumCte+_cSerCte ))
					// mensagem
					_cLogGeral += "   - Ct-e "+_cNumCte+" não registrado no sistema"+CRLF
					// adiciona log em html
					_cLogHtml += sfLogHtml(_cNumFat, "- Ct-e "+_cNumCte+" não registrado no sistema", "ERRO")

					// controle de processamento
					_lFatOk := .f.

				EndIf

				// adiciona o recno
				If (_lFatOk)
					aAdd(_aRecnoSF2, SF2->(RecNo()) )
				EndIf

			Next _nCte

		EndIf

		// valida cliente da fatura
		If (_lFatOk)

			// funcao que valida o cliente
			If ( ! sfVldCliente(_cCliID, .t., Nil, Nil) )
				// mensagem
				_cLogGeral += "   - Erro ao cadastrar/atualizar dados do cliente "+AllTrim(_cCliNome)+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(_cNumFat, "- Erro ao cadastrar/atualizar dados do cliente "+AllTrim(_cCliNome), "ERRO")
				// dados ok por cte
				_lFatOk := .f.
			EndIf

		EndIf

		// verifica se a fatura ja existe no sistema
		If (_lFatOk)
			//dbSelectArea("SE1")
			//SE1->(dbSetOrder(2)) // 2-E1_FILIAL, E1_CLIENTE, E1_LOJA, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO
			//If SE1->(dbSeek( xFilial("SE1")+_cCodCli+_cLojCli+_cPrefFat+_cNumNewFat+_cParcFat+_cTipoFat ))

			//Gustavo, SLA, 27/09/2018, alterado DBSeek para Query para não interferir no FINA460
			If Select("tSE1E") > 0
				DBSelectArea("tSE1E")
				tSE1E->(DBCloseArea())
			EndIf

			cQuery := ""
			cQuery += " SELECT E1_NUM "
			cQuery += " FROM "+RetSQLName("SE1")+" "
			cQuery += " where D_E_L_E_T_ = '' "
			cQuery += " and E1_FILIAL = '"+xFilial("SE1")+"' "
			cQuery += " and E1_CLIENTE = '"+_cCodCli+"' "
			cQuery += " and E1_LOJA = '"+_cLojCli+"' "
			cQuery += " and E1_PREFIXO = '"+_cPrefFat+"' "
			cQuery += " and E1_NUM = '"+_cNumNewFat+"' "
			cQuery += " and E1_PARCELA = '"+_cParcFat+"' "
			cQuery += " and E1_TIPO = '"+_cTipoFat+"' "

			TCQuery cQuery NEW ALIAS "tSE1E"

			DBSelectArea("tSE1E")
			tSE1E->(DBGoTop())

			if !tSE1E->(EOF())
				// mensagem de log
				_cLogGeral += "   - Fatura já registrada, prefixo "+_cPrefFat+" número "+_cNumNewFat+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(_cNumFat, "- Fatura já registrada, prefixo "+_cPrefFat+" número "+_cNumNewFat, "ERRO")
				// dados ok por fatura
				_lFatOk := .f.
			EndIf

			If Select("tSE1E") > 0
				DBSelectArea("tSE1E")
				tSE1E->(DBCloseArea())
			EndIf
		EndIf

		// gera titulos de acordo com os CTe
		If (_lFatOk)

			// varre todos os CTe da fatura
			For _nRecnoSF2 := 1 to Len(_aRecnoSF2)

				// controle de necessidade de inclusao do titulo a receber
				_lIncTitRec := .f.

				// posiciona no registro do cte
				dbSelectArea("SF2")
				SF2->(dbGoTo( _aRecnoSF2[_nRecnoSF2] ))

				// controle de saldo total da fatura
				_nTmpTotal += SF2->F2_VALFAT

				// posiciona no cadastro do cliente
				dbselectarea("SA1")
				SA1->(dbsetorder(1))
				SA1->(dbseek( xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA ))

				// atualiza nome reduzido do cliente
				_cNomReduz := SA1->A1_NREDUZ

				// verifica se o titulo ja existe
				//dbselectarea("SE1")
				//SE1->(dbsetorder(2)) // 2-E1_FILIAL, E1_CLIENTE, E1_LOJA, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, R_E_C_N_O_, D_E_L_E_T_
				//If ! SE1->(dbseek( xFilial("SE1")+SF2->F2_CLIENTE+SF2->F2_LOJA+SF2->F2_SERIE+SF2->F2_DOC ))

				//Gustavo, SLA, 27/09/2018, alterado DBSeek para Query para não interferir no FINA460
				If Select("tSE1F") > 0
					DBSelectArea("tSE1F")
					tSE1F->(DBCloseArea())
				EndIf

				cQuery := ""
				cQuery += " SELECT R_E_C_N_O_ RECNO_ "
				cQuery += " FROM "+RetSQLName("SE1")+" "
				cQuery += " where D_E_L_E_T_ = '' "
				cQuery += " and E1_FILIAL = '"+xFilial("SE1")+"' "
				cQuery += " and E1_CLIENTE = '"+SF2->F2_CLIENTE+"' "
				cQuery += " and E1_LOJA = '"+SF2->F2_LOJA+"' "
				cQuery += " and E1_PREFIXO = '"+SF2->F2_SERIE+"' "
				cQuery += " and E1_NUM = '"+SF2->F2_DOC+"' "

				TCQuery cQuery NEW ALIAS "tSE1F"

				DBSelectArea("tSE1F")
				tSE1F->(DBGoTop())

				if tSE1F->(EOF())
					// flag para gerar titulo a receber
					_lIncTitRec := .t.
				Else
					// armazena recno para gerar fatura
					aAdd(_aRecnoSE1, tSE1F->RECNO_ )
				EndIf

				If Select("tSE1F") > 0
					DBSelectArea("tSE1F")
					tSE1F->(DBCloseArea())
				EndIf

				// prepara dados dos titulo a receber
				If (_lFatOk).and.(_lIncTitRec)

					// reinicia variaveis
					_aAutoSE1 := {}

					// valor dos juros
					_nVlrJuros := Round(SF2->F2_VALBRUT * (_nPerJur / 100),2)

					//Inclui contas a Receber
					AAdd(_aAutoSE1,{"E1_PREFIXO" , SF2->F2_SERIE             , Nil})
					AAdd(_aAutoSE1,{"E1_SERIE"   , SF2->F2_DOC               , Nil})
					AAdd(_aAutoSE1,{"E1_NUM"     , SF2->F2_DOC               , Nil})
					AAdd(_aAutoSE1,{"E1_PARCELA" , CriaVar("E1_PARCELA", .f.), Nil})
					AAdd(_aAutoSE1,{"E1_TIPO"    , "NF"                      , Nil})
					AAdd(_aAutoSE1,{"E1_NATUREZ" , _cNewNatur                , Nil})
					AAdd(_aAutoSE1,{"E1_CLIENTE" , SF2->F2_CLIENTE           , Nil})
					AAdd(_aAutoSE1,{"E1_LOJA"    , SF2->F2_LOJA              , Nil})
					AAdd(_aAutoSE1,{"E1_NOMCLI"  , _cNomReduz                , Nil})
					AAdd(_aAutoSE1,{"E1_EMISSAO" , SF2->F2_EMISSAO           , Nil})
					AAdd(_aAutoSE1,{"E1_VENCTO"  , _dDataVenc                , Nil})
					AAdd(_aAutoSE1,{"E1_VALOR"   , SF2->F2_VALFAT            , Nil})
					AAdd(_aAutoSE1,{"E1_PORCJUR" , _nPerJur                  , Nil})
					AAdd(_aAutoSE1,{"E1_VALJUR"  , _nVlrJuros                , Nil})
					AAdd(_aAutoSE1,{"E1_FLUXO"   , "S"                       , Nil})
					AAdd(_aAutoSE1,{"E1_TIPODES" , "1"                       , Nil})
					AAdd(_aAutoSE1,{"E1_ZIDDTMX" , _cIdFat                   , Nil})

					// ordena o vetor conforme dicionario de dados
					_aAutoSE1 := FWVetByDic(_aAutoSE1,'SE1',.F.)

					BEGIN TRANSACTION


						// executa rotina automatica de geracao de titulos
						lMsErroAuto = .F.
						MSExecAuto({|x,y| Fina040(x,y)}, _aAutoSE1, 3) // 3-Incluir

						// erro na rotina automatica
						If (lMsErroAuto)
							// log rotina automatica
							_cLogRotAut := U_FtAchaErro(.T.)
							// mensagem
							_cLogGeral += "   - Erro ao gerar titulo do CT-e "+SF2->F2_DOC+" (Id.Erro: "+AllTrim(_cLogRotAut)+")"+CRLF
							// adiciona log em html
							_cLogHtml += sfLogHtml(_cNumFat, "- Erro ao gerar titulo do CT-e "+SF2->F2_DOC+" (Id.Erro: "+AllTrim(_cLogRotAut)+")", "ERRO")
							// dados ok por cte
							_lFatOk := .f.
						EndIf

						// armazena recno para gera fatura
						If (_lFatOk)
							aAdd(_aRecnoSE1, SE1->(RecNo()) )
						EndIf

					END TRANSACTION

					// atualiza dados do titulo no documento de saida (cte E/OU nfse)
					dbSelectArea("SF2")
					RecLock("SF2")
					SF2->F2_DUPL    := SF2->F2_DOC
					SF2->F2_PREFIXO := SF2->F2_SERIE
					SF2->(MsUnLock())

				EndIf

				// proximo cte
			Next _nRecnoSF2

			// valida se o total de titulos confere com total previsto da fatura
			If (_lFatOk)
				If (_nTotFat <> _nTmpTotal)
					// mensagem de log
					_cLogGeral += "   - Total da fatura (" + Str(_nTotFat) + ") diferente do total dos documentos (" + Str(_nTmpTotal) + ")" + CRLF
					// adiciona log em html
					_cLogHtml += sfLogHtml(_cNumFat, "   - Total da fatura (" + Str(_nTotFat) + ") diferente do total dos documentos (" + Str(_nTmpTotal) + ")", "ERRO")
					// controle de processamento
					_lFatOk := .f.
				EndIf
			EndIf

			// apos geracao da fatura, quando for cobranca por boleto, atualiza dados do boleto
			If (_lFatOk).and.(_lTemBolet)

				// chamada da classe exemplo de REST com retorno de lista (XML)
				_oCnxRest:SetPath( sfRetRotinas("V02")[1][4]+_cIdFat )

				// executa Get do Header
				If _oCnxRest:Get(_aHeadRest)
					// atualiza dados quando conexao ok
					_cGetRes := _oCnxRest:GetResult()
					// controle de processamento
					_lFatOk := .t.
				Else
					// busca mensagem de erro na busca dos dados
					_cGetRes := _oCnxRest:GetLastError()
					// controle de processamento
					_lFatOk := .f.
					// mensagem
					_cLogGeral += "   - Erro conexão com DATAMEX (Id: "+AllTrim(_cGetRes)+")"+CRLF
					// adiciona log em html
					_cLogHtml += sfLogHtml(_cNumFat, "- Erro conexão com DATAMEX (Id: "+AllTrim(_cGetRes)+")", "ERRO")

				EndIf

			EndIf

			// prepara objeto XML
			If (_lFatOk).and.(_lTemBolet)
				// parse no XML
				_oXmlBolFat := XmlParser(_cGetRes, "_", @_cError, @_cWarning )

				// valida montagem/parse correta do XML
				If ( ( _oXmlBolFat == Nil ) .or. ( ! Empty(_cError) ) .or. ( ! Empty(_cWarning) ) )
					// controle de processamento
					_lFatOk := .f.
					// mensagem
					_cLogGeral += "   - Erro XML Boleto DATAMEX (Erro: "+AllTrim(_cError)+" / "+AllTrim(_cWarning)+")"+CRLF
					// adiciona log em html
					_cLogHtml += sfLogHtml(_cNumFat, "- Erro XML Boleto DATAMEX (Erro: "+AllTrim(_cError)+" / "+AllTrim(_cWarning)+")", "ERRO")

				EndIf

			EndIf

			// atualiza os dados do boleto
			If (_lFatOk).and.(_lTemBolet)

				/*
				ID_DUP
				status
				Cli_Desc
				Tipo
				Numero
				Conv_Desc
				Nro_bol
				Nro_bolfrm
				DtCobranca
				DtVenc
				Valor
				Nro_rem
				FEBRABAN
				AGENCIA
				CC
				msgRet
				user_id
				*/

				// extrai dados
				_cBolBanco := AllTrim(_oXmlBolFat:_ROOT:_LINHA:_FEBRABAN:TEXT)
				_cBolAgenc := AllTrim(_oXmlBolFat:_ROOT:_LINHA:_AGENCIA:TEXT)
				_cBolConta := sfRetNum(AllTrim(_oXmlBolFat:_ROOT:_LINHA:_CC:TEXT), .t., TamSx3("A6_NUMCON")[1])
				_cBolNosNr := AllTrim(_oXmlBolFat:_ROOT:_LINHA:_Nro_bolfrm:TEXT)
				_cIdCnab   := AllTrim(_oXmlBolFat:_ROOT:_LINHA:_ID_DUP:TEXT)

				// padroniza tamanho dos campos
				_cBolBanco := PadR(_cBolBanco, TamSx3("A6_COD")[1]    )
				_cBolAgenc := PadR(_cBolAgenc, TamSx3("A6_AGENCIA")[1])
				_cBolConta := PadR(_cBolConta, TamSx3("A6_NUMCON")[1] )
				_cBolNosNr := PadR(_cBolNosNr, TamSx3("E1_NUMBCO")[1] )
				_cIdCnab   := PadR(_cIdCnab  , TamSx3("E1_IDCNAB")[1] )

				// pesquisa se o banco esta cadastrado
				dbSelectArea("SA6")
				SA6->(dbSetOrder(1)) // 1-A6_FILIAL, A6_COD, A6_AGENCIA, A6_NUMCON
				If ! SA6->(dbSeek( xFilial("SA6")+_cBolBanco+_cBolAgenc+_cBolConta ))
					// controle de processamento
					_lFatOk := .f.
					// log geral
					_cLogGeral += "   - Banco não cadastrado (Cod: "+_cBolBanco+" / Ag: "+_cBolAgenc+" / CC: "+_cBolConta+")"+CRLF
					// adiciona log em html
					_cLogHtml += sfLogHtml(_cNumFat, "- Banco não cadastrado (Cod: "+_cBolBanco+" / Ag: "+_cBolAgenc+" / CC: "+_cBolConta+")", "ERRO")

				EndIf

			EndIf

			// gera fatura
			If (_lFatOk).and.(Len(_aRecnoSE1) > 0)

				// zera variaveis
				_aCabFat := {}
				_aIteFat := {}
				_cFltFat := ""

				cRecno := ""

				// varre os titulos para gerar a fatura no TOTVS
				For _nRecnoSE1 := 1 to Len(_aRecnoSE1)
					cRecno += Str(_aRecnoSE1[_nRecnoSE1])+","
					// proximo titulo
				Next _nRecnoSE1

				//Gustavo, SLA, 27/09/2018, alterado DBSeek para Query para não interferir no FINA460
				_cTmpNum := ""

				If Select("tSE1R") > 0
					DBSelectArea("tSE1R")
					tSE1R->(DBCloseArea())
				EndIf

				cQuery := ""
				cQuery += " SELECT E1_NUM "
				cQuery += " FROM "+RetSQLName("SE1")+" "
				cQuery += " where D_E_L_E_T_ = '' "
				cQuery += " and R_E_C_N_O_ in ("+SubStr(cRecno,1,Len(cRecno)-1)+") "

				TCQuery cQuery NEW ALIAS "tSE1R"

				DBSelectArea("tSE1R")
				tSE1R->(DBGoTop())

				if !tSE1R->(EOF())
					While !tSE1R->(EOF())

						_cTmpNum += tSE1R->E1_NUM+"|"

						tSE1R->(DBSkip())
					EndDo
				EndIf

				If Select("tSE1R") > 0
					DBSelectArea("tSE1R")
					tSE1R->(DBCloseArea())
				EndIf

				// prepara o filtro para fatura
				_cFltFat := "E1_FILIAL=='"+xFilial("SE1")+"' "
				_cFltFat += ".And.E1_CLIENTE=='"+_cCodCli+"'.And.E1_LOJA=='"+_cLojCli+"'"
				_cFltFat += ".And.E1_SITUACA$'0FG'.And.E1_SALDO>0"
				_cFltFat += ".And.Empty(E1_NUMLIQ)"
				_cFltFat += ".And.(!(E1_TIPO$MVABATIM))"
				_cFltFat += '.And.(!(E1_TIPO$"'+MVPROVIS+"/"+MVRECANT+"/"+MV_CRNEG+'"))'
				// parenteses para filtro de numero do titulo, usando OR
				_cFltFat += ".And.(E1_NUM$ '" + _cTmpNum + "')"

				// Array do processo automatico (aAutoCab)
				_aCabFat := { ;
				{"cCondicao", _cCodCond  },;
				{"cNatureza", _cNewNatur },;
				{"E1_TIPO"  , _cTipoFat  },;
				{"cCLIENTE" , _cCodCli   },;
				{"cLOJA"    , _cLojCli   },;
				{"nMoeda"   , 1          } }

				// Dados das parcelas a serem geradas
				aAdd(_aIteFat,{;
				{"E1_PREFIXO" , _cPrefFat   },;
				{"E1_BCOCHQ"  , "."         },;
				{"E1_AGECHQ"  , "."         },;
				{"E1_CTACHQ"  , "."         },;
				{"E1_NUM"     , _cNumNewFat },;
				{"E1_EMITCHQ" , _cNomReduz  },;
				{"E1_PARCELA" , _cParcFat   },;
				{"E1_VENCTO"  , _dDataVenc  },;
				{"E1_VLCRUZ"  , _nTotFat    },;
				{"E1_ACRESC"  , _nVlrAcre   },;
				{"E1_DECRESC" , _nVlrDesc   }})

				lMsErroAuto := .f.

				// controle da variavel dDataBase para emissao de faturas
				_dDtBsAtual := dDataBase
				dDataBase   := _dDtEmisFat

				BEGIN TRANSACTION

					INCLUI := .T.

					// executa rotina automatica
					FINA460(Nil, _aCabFat, _aIteFat, 3, _cFltFat) // 3-Inclusao

					// apos gerar a fatura, restaura database
					dDataBase := _dDtBsAtual

					// quando gerar erro/validacao na rotina automatica
					If (lMsErroAuto)
						// log rotina automatica
						_cLogRotAut := U_FtAchaErro(.T.)
						// mensagem
						_cLogGeral += "   - Erro ao gravar dados da fatura "+_cNumNewFat+" (Id.Erro: "+AllTrim(_cLogRotAut)+")"+CRLF
						// adiciona log em html
						_cLogHtml += sfLogHtml(_cNumFat, "- Erro ao gravar dados da fatura "+_cNumNewFat+" (Id.Erro: "+AllTrim(_cLogRotAut)+")", "ERRO")
						// dados ok por cte
						_lFatOk := .f.
					EndIf

				END TRANSACTION

			EndIf

			// atualiza os dados do Id Datamex
			If (_lFatOk)

				// reposiciona no registro da fatura gerado para atualziar os dados
				dbSelectArea("SE1")
				SE1->(dbSetOrder(2)) // 2-E1_FILIAL, E1_CLIENTE, E1_LOJA, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO
				If ! SE1->(dbSeek( xFilial("SE1")+_cCodCli+_cLojCli+_cPrefFat+_cNumNewFat+_cParcFat+_cTipoFat ))
					Final()
				EndIf

				// atualiza dados
				RecLock("SE1")
				SE1->E1_ZIDDTMX := _cIdFat
				SE1->(MsUnLock())

			EndIf

			// atualiza os dados no titulo
			If (_lFatOk).and.(_lTemBolet)

				// posiciona no banco cadastrado
				dbSelectArea("SA6")
				SA6->(dbSetOrder(1)) // 1-A6_FILIAL, A6_COD, A6_AGENCIA, A6_NUMCON
				SA6->(dbSeek( xFilial("SA6")+_cBolBanco+_cBolAgenc+_cBolConta ))

				// atualiza dados do boleto
				dbSelectArea("SE1")
				RecLock("SE1")
				SE1->E1_SITUACA := "1" // 1-Cobranca Simples
				SE1->E1_PORTADO := SA6->A6_COD
				SE1->E1_AGEDEP  := SA6->A6_AGENCIA
				SE1->E1_CONTA   := SA6->A6_NUMCON
				SE1->E1_NUMBCO  := _cBolNosNr
				SE1->E1_IDCNAB  := _cIdCnab
				SE1->(MsUnLock())

				// realiza bloqueio de integracao
				If ! sfFlagInt("BOL", _cIdCnab, .t., Nil, .f.)

				EndIf

			EndIf

		EndIf

		// dados importados
		If (_lFatOk)
			// log geral
			_cLogGeral += "   - Dados integrados com sucesso"+CRLF
			// adiciona log em html
			_cLogHtml += sfLogHtml(_cNumFat, "- Dados integrados com sucesso", "OK")

			// realiza bloqueio de integracao
			If ! sfFlagInt("FAT", _cIdFat, .t., Nil, .f.)
				// log geral
				_cLogGeral += "   - Erro no bloqueio de integração. Contate TI. (id: "+AllTrim(_cIdFat)+")"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(_cNumFat, "- Erro no bloqueio de integração. Contate TI. (id: "+AllTrim(_cIdFat)+")", "ERRO")

			EndIf
		EndIf

		// libera todos os registros
		MsUnLockAll()

		DBCommitAll()

		// restaura areas
		RestArea(_aArea)
		RestArea(_aAreaSE1)
		RestArea(_aAreaSA6)
		RestArea(_aAreaSF2)

		// proxima fatura
	Next _nFat

Return(.t.)

// ** funcao para visualizar dados no browse/navegado
Static Function sfVisDados( mvCodRot )
	// URL completa
	local _cUrlComp := ""
	// variaveis temporarias
	local _aTmpAuth := Separa(SuperGetMv("TC_DTMXUSR",,"tecadi:t3c@d1"),":")
	local _cTmpUsr  := _aTmpAuth[1]
	local _cTmpPsw  := _aTmpAuth[2]

	// base da URL
	_cUrlComp := SuperGetMv("TC_DTMXURL",,"http://tecadi.e-login.net")
	// script
	_cUrlComp += sfRetRotinas(mvCodRot, "HTML")[1][4]
	// parametro adicional
	_cUrlComp += sfAddPath( mvCodRot )

	// mensagem com senha
	HS_MsgInf("ATENÇÃO: Informar usuário e senha"+CRLF+"Usuário: "+_cTmpUsr+CRLF+"Senha: "+_cTmpPsw ,;
	"Autenticação",;
	"Autenticação" )

	// abre o navegador
	ShellExecute("open",_cUrlComp,"","",5)

Return

// ** funcao para complementar parametros das URLs
Static Function sfAddPath( mvCodRot )
	// variavel de retorno
	local _cRetAdd := ""

	// CTE
	If (mvCodRot == "001")
		//_cRetAdd := "&param_DataEnvioSefaz="+DtoC(dDataBase)
	EndIf

	// Cancelamento de CTE
	If (mvCodRot == "003")
		//_cRetAdd := "&param_DataHoraInicio="+DtoC(dDataBase)+" 00:00:00&param_DataHoraFim="+DtoC(dDataBase)+" 23:59:59"
	EndIf

	// Faturas de Cobrança / Dados básicos
	If (mvCodRot == "007")
		//_cRetAdd := "&param_DataEmissaoFatura="+DtoC(dDataBase)
	EndIf

	// Contratos de Frete / Dados básicos
	If (mvCodRot == "008")
		//_cRetAdd := "&param_DtHrIniOpCred="+DtoC(dDataBase)+" 00:00:00&param_DtHrFimOpCred="+DtoC(dDataBase)+" 23:59:59"
	EndIf

Return(_cRetAdd)

// ** funcao para marcar item/registro como importado
Static Function sfFlagInt(mvChave, mvIdValor, mvIntOk, mvResult, mvDocCanc)

	// conexao com Token Datamex através de Restful/API
	local _oCnxRest := FwRest():New(SuperGetMv("TC_DTMXURL",,"http://tecadi.e-login.net"))

	// configuracao do Header
	local _aHeadRest := {}

	// comando do post
	local _cCmdPost := ""

	// parametros do POST
	local _cHttpPost := ""

	// variavel de retorno
	local _lOk := .f.

	// usuario para gerar o log
	local _cUserLog := ""

	// valor padrao
	Default mvResult := ""

	// verifica se a variavel existe
	If (Type("_lWorkFlow") == "L").and.(_lWorkFlow)
		_cUserLog := _cNomUser
	Else
		_cUserLog := AllTrim(UsrRetName(__cUserId))
	EndIf

	// integracao de cte/nota/fatura
	If (mvChave $ "CTE|CF|NFS|FAT|BAIXA_RODOCRED|INUTILIZADO|BOL")
		// inclusao de complemento para cancelamento
		If (mvDocCanc)
			// para Cte
			If (mvChave == "CTE")
				mvChave += "%20CANCELADO"
			ElseIf (mvChave == "NFS")
				mvChave += "%20CANCELADA"
			EndIf
		EndIF

		// define comando do post
		_cCmdPost := IIf(mvIntOk, "guardavalor", "apagavalor")
		// parametros do POST
		_cHttpPost := "p=ambiente&f="+_cCmdPost+"&chave="+AllTrim(mvChave)+"&valor="+AllTrim(mvIdValor)+"&observ="+_cUserLog

	ElseIf (mvChave $ "BAIXA_FAT")
		// define comando do post
		_cCmdPost := IIf(mvIntOk, "quitaFatura", "desfazQuitacaoFatura")
		// parametros do POST
		_cHttpPost := "p=transporte&f="+_cCmdPost+"&id="+AllTrim(mvIdValor) + IIf(mvIntOk,"&motivo=Fatura%20quitada%20totalmente","")

	EndIf

	// inclui o campo Authorization no formato <usuario>:<senha> na base64
	Aadd(_aHeadRest, "Authorization: Basic " + Encode64(SuperGetMv("TC_DTMXUSR",,"tecadi:t3c@d1")))
	Aadd(_aHeadRest, "cache-control: no-cache")
	Aadd(_aHeadRest, "content-type: application/x-www-form-urlencoded")

	// seta o patch do WebService
	_oCnxRest:SetPath( "/ws/" )

	// seta parametros o POST
	_oCnxRest:SetPostParams(_cHttpPost)

	// executa POST
	If _oCnxRest:Post(_aHeadRest)
		// variavel com detalhes de retorno
		mvResult := _oCnxRest:GetResult()

		//grava log com o retorno
		memowrit("C:\query\datamex_rest.txt",mvResult)

		// variavel de retorno
		_lOk := .t.
	Else
		// variavel com detalhes de retorno
		mvResult := _oCnxRest:GetLastError()

		//grava log com o retorno
		memowrit("C:\query\datamex_rest.txt",mvResult)

		// variavel de retorno
		_lOk := .f.
	EndIf

Return(_lOk)

// ** funcao para incluir log html
Static Function sfLogHtml(mvDoc, mvDscLog, mvStatus)
	// variavel de retorno
	local _cRet := ""
	// cor do log
	local _cCorLog

	// define cor da legenda
	If (mvStatus == "OK")
		_cCorLog := '#006400'
	ElseIf (mvStatus == "ERRO")
		_cCorLog := '#FF6347'
	ElseIf (mvStatus == "ALERTA")
		_cCorLog := '#FFD700'
	EndIf

	_cRet := '<tr>'
	_cRet += '<td width="3%" style="font-family: Tahoma; font-size: 12px; background-color: '+_cCorLog+';">&nbsp;</td>'
	_cRet += '<td width="17%" style="font-family: Tahoma; font-size: 12px;">'+mvDoc+'</td>'
	_cRet += '<td width="80%" style="font-family: Tahoma; font-size: 12px;">'+mvDscLog+'</td>'
	_cRet += '</tr>'

	// define que ha dados integrados
	_lDadosInt := .t.

Return(_cRet)

// ** funcao para estorno da integracao
Static Function sfEstorno(mvOpcCanc, mvNrDocCanc)

	// detalhes do processamento
	local _cDetProc := ""

	// mensagem de confirmacao
	If ( ! Empty(mvNrDocCanc)).and.(MsgYesNo("Confirmar o estorno da integração do "+mvOpcCanc+" Id = "+AllTrim(mvNrDocCanc)+" ?", "Estorno"))
		// rotina para cancelamento de integracao
		If ! sfFlagInt(mvOpcCanc, mvNrDocCanc, .f., @_cDetProc, .f.)
			MsgStop("Erro ao estornar cancelamento: "+AllTrim(_cDetProc))
		Else
			MsgInfo("Estorno realizado com sucesso!", "Estorno")
		EndIf
	EndIf

Return

// ** funcao que retorna se o usuario logado eh do grupo admin
Static Function sfUsrAdmin()
	// varivel de retorno
	local _lRet := .f.
	// retorna os grupos do usuario logado
	local _aGrupos := FWSFUsrGrps(__cUserId)
	// variaveis temporarias
	local _nX

	// varre todos os grupos e retornar descrição do grupo
	For _nX := 1 to Len(_aGrupos)

		// grupo de administradores
		If (Upper(_aGrupos[_nX]) $ "000000")
			// variavel de retorno
			_lRet := .t.
			// sai do loop
			Exit
		EndIf
	Next _nX

Return(_lRet)

// ** funca para integrar inutilizacao de Cte
Static Function sfGrvInutilizacao(mvTipoDoc, mvXML)

	// variaveis temporaris
	local _nXML
	local _nNrDoc

	// seek SF3
	local _cSeekSF3

	// numeracao inicial e final
	local _nDocIni
	local _nDocFim

	// dados do codigo e loja do cliente
	local _cTmpCodCli := SuperGetMV("MV_INUTCLI", .F., "")

	// codigo do produto
	Local _cCodProd := SuperGetMV("MV_INUTPRO", .F., "")

	// codigo da TES utilizada
	local _cCodTES := SuperGetMV("MV_INUTTES", .F., "")

	// ID interno Datamex
	local _cIdDatamex := ""


	// valor total
	local _nVlrTotal := 0
	// valor de frete
	local _nVlrFrete := 0
	// valor de pedagio
	local _nVlrPedagio := 0
	// base do icms
	local _nBsIcms := 0
	// aliquota do icms
	local _nAliqIcms := 0
	// incidencia de ICMS
	local _lIncIcms := .f.

	// base do ISS
	local _nBsISS := 0
	// aliquota do ISS
	local _nAliqISS := 0
	// valor do ISS
	local _nVlrISS := 0
	// incidencia de ISS
	local _lIncISS := .f.


	// quantidade de volumes
	local _nQtdVol := 0

	// pesos
	local _nPesoBr := 0
	local _nPesoLi := 0

	// cabecalho
	local _aCabSF2 := {}
	local _aItem := {}
	local _aItensSD2 := {}
	// item
	local _cItem := StrZero(1,TamSx3("D2_ITEM")[1])

	// dados ok por cte/nfse
	local _lDocSaiOk := .f.

	// tipo do documento para Log
	local _cTpDocLog := ""

	// tipo de documento de saida
	local _lIsCte := .f.
	local _lIsNfs := .f.

	// flag para controle de integracao
	local _cFlagInt := ""

	// variaveis da rotina automatica
	Private lMsErroAuto := .F.
	private c920Tipo    := "N"
	private c920Nota    := ""
	private d920Emis    := CtoD("//")
	private c920Client  := ""
	private c920Loja    := ""
	private c920Especi  := mvTipoDoc

	// vetor usado no ponto de entrada MTA920C
	private _a920Dados  := {}

	// controle, quando for cancelamento de Cte, para nao limpar conteudo do campo D2_ORIGLAN, para permitir cancelamento
	private _l920Cancel := .t.

	// variaveis temporaris
	private _oXmlDocInu := mvXML:_ROOT

	/*
	Nota_id
	usuario_id
	Inu_data
	serie
	nroInicio
	nroFim
	arquivo
	ID_INUT
	*/

	// define tipo de documento para log
	If (AllTrim(mvTipoDoc) == "CTE")
		_cTpDocLog := "Ct-e"
		_lIsCte    := .t.
		_cFlagInt  := "INUTILIZADO"

	ElseIf (AllTrim(mvTipoDoc) == "NFS")
		_cTpDocLog := "NFS-e"
		_lIsNfs    := .t.
		_cFlagInt  := "INUTILIZADO"

	EndIf

	// verifica se o cliente esta cadastrado corretamente
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1)) // 1-A1_FILIAL, A1_COD, A1_LOJA
	If ! SA1->(dbSeek(xFilial("SA1") + _cTmpCodCli ))
		// mensagem
		_cLogGeral += "   - Cliente "+_cTmpCodCli+" não cadastrado. Informar setor de TI. Parâmetro MV_INUTCLI"+CRLF
		// adiciona log em html
		_cLogHtml += sfLogHtml("", " - Cliente "+_cTmpCodCli+" não cadastrado. Informar setor de TI. Parâmetro MV_INUTCLI", "ERRO")
		// retorno
		Return(.f.)
	EndIf

	// atualiza variaveis de retorno
	c920Client := SA1->A1_COD
	c920Loja   := SA1->A1_LOJA

	// caso nao for vetor, converte
	If (Type("_oXmlDocInu:_LINHA") != "A")
		XmlNode2Arr(_oXmlDocInu:_LINHA, "_LINHA")
	EndIf

	// define a quantidade de itens a processar
	If ( ! _lWorkFlow )
		_oProcInteg:SetRegua2( Len(_oXmlDocInu:_LINHA) )
	EndIf

	aItens := {}    
	For _nXML := 1 To Len(_oXmlDocSai:_LINHA)

		_nDocIni := Val(_oXmlDocInu:_LINHA[_nXML]:_nroInicio:TEXT)
		_nDocFim := Val(_oXmlDocInu:_LINHA[_nXML]:_nroFim:TEXT)
		_cIdDatamex := AllTrim(_oXmlDocInu:_LINHA[_nXML]:_ID_INUT:TEXT)

		For _nNrDoc := _nDocIni to _nDocFim
			c920Nota    := AllTrim(sfRetNum( _nNrDoc, .t., TamSx3("F2_DOC")[1] ))
			c920Serie   := PadR( _oXmlDocInu:_LINHA[_nXML]:_serie:TEXT, TamSx3("F2_SERIE")[1] )
			Aadd(aItens,{(c920Serie+c920Nota),;
			_cIdDatamex,;
			"",;
			sfExtDtHr( _oXmlDocInu:_LINHA[_nXML]:_Inu_data:TEXT , "D")})
		Next	
	Next
	fTelaSel("Selecione Inutilizações para integração:",@aItens)	

	// varre todos os registros de numeracao para integrar
	For _nXML := 1 to Len(_oXmlDocInu:_LINHA)

		// documento inicial
		_nDocIni := Val(_oXmlDocInu:_LINHA[_nXML]:_nroInicio:TEXT)
		// documento final
		_nDocFim := Val(_oXmlDocInu:_LINHA[_nXML]:_nroFim:TEXT)

		// ID interno Datamex
		_cIdDatamex := AllTrim(_oXmlDocInu:_LINHA[_nXML]:_ID_INUT:TEXT)


		// varre "range" de numeração
		For _nNrDoc := _nDocIni to _nDocFim

			// reinicia variaveis
			_lDocSaiOk := .t.

			// atualiza os dados para rotina automatica
			c920Nota    := sfRetNum( _nNrDoc, .t., TamSx3("F2_DOC")[1] )
			c920Serie   := PadR( _oXmlDocInu:_LINHA[_nXML]:_serie:TEXT, TamSx3("F2_SERIE")[1] )
			d920Emis    := sfExtDtHr( _oXmlDocInu:_LINHA[_nXML]:_Inu_data:TEXT , "D")
			_cCNPJ      := AllTrim(_oXmlDocInu:_LINHA[_nXML]:_EMPRESA:TEXT)

			//Verifica se foi selecionado para integração.
			If (aScan(aItens,{|x| x[02] == _cIdDatamex .And. x[01] == (c920Serie+AllTrim(c920Nota)) })) == 0
				Loop
			EndIf

			//Verifica se está importando o registro para a filial correta
			If (_cCNPJ != SM0->M0_CGC)
				_cLogGeral += "Filial corrente divergente do especificado na integração. Inutilização " + _cTpDocLog + " / " + AllTrim(c920Nota) + " (id: " + _cIdDatamex + ") / Filial " + _cCNPJ + " não integrado." + CRLF
				//proximo item a integrar
				Loop
			EndIF

			// mensagem solicitando confirmacao
			//			If ( ! _lWorkFlow )/* .and.( ! MsgYesno("Confirma integração da inutilização do(a) "+_cTpDocLog+" número "+AllTrim(c920Nota)+" ?", "Confirmação") )*/
			//			Loop
			//		EndIf

			// mensagem
			_cLogGeral += "  :: "+_cTpDocLog+" "+c920Nota+CRLF

			// incrementa Segunda Regua
			If ( ! _lWorkFlow )
				_oProcInteg:IncRegua2( _cTpDocLog+" "+c920Nota )
			EndIf

			// Verifica se a nota fiscal/cte já está digitada no sistema
			DBSelectArea("SF3")
			SF3->(DBSetOrder(6)) // 6-F3_FILIAL, F3_NFISCAL, F3_SERIE
			If SF3->(DBSeek( _cSeekSF3 := xFilial("SF3") + c920Nota + c920Serie ))

				// varre todas as notas com a mesma numeracao
				While SF3->( ! Eof() ).and.( SF3->(F3_FILIAL+F3_NFISCAL+F3_SERIE) == _cSeekSF3 )
					// notas de entrada com formulario proprio
					If (SubStr(SF3->F3_CFO,1,1) $ "1,2,3").and.(AllTrim(SF3->F3_ESPECIE) == AllTrim(c920Especi)).and.(SF3->F3_FORMUL == 'S')
						// mensagem
						_cLogGeral += "   - "+_cTpDocLog+" já registrado no sistema"+CRLF
						// adiciona log em html
						_cLogHtml += sfLogHtml(c920Nota, " - "+_cTpDocLog+" já registrado no sistema", "ERRO")

						// dados ok por cte/nfse
						_lDocSaiOk := .f.

						// notas de saida
					ElseIf (SubStr(SF3->F3_CFO,1,1) $ "5,6,7").and.(AllTrim(SF3->F3_ESPECIE) == AllTrim(c920Especi))
						// mensagem
						_cLogGeral += "   - "+_cTpDocLog+" já registrado no sistema"+CRLF
						// adiciona log em html
						_cLogHtml += sfLogHtml(c920Nota, " - "+_cTpDocLog+" já registrado no sistema", "ERRO")

						// dados ok por cte/nfse
						_lDocSaiOk := .f.

					EndIf

					// proximo registro
					SF3->(dbSkip())
				EndDo
			EndIf

			If (_lDocSaiOk)

				// zera variaveis
				_aCabSF2   := {}
				_aItem     := {}
				_aItensSD2 := {}
				_cItem     := StrZero(1,TamSx3("D2_ITEM")[1])

				// utilizado no PE MTA920C
				_a920Dados := {}

				// define o cabecalho do CT-e
				_aCabSF2 := { ;
				{"F2_DOC"     ,c920Nota   ,NIL},;
				{"F2_SERIE"   ,c920Serie  ,NIL},;
				{"F2_CLIENTE" ,c920Client ,NIL},;
				{"F2_LOJA"    ,c920Loja   ,NIL},;
				{"F2_TIPO"    ,c920Tipo   ,NIL},;
				{"F2_EMISSAO" ,d920Emis   ,NIL},;
				{"F2_ESPECIE" ,c920Especi ,NIL},;
				{"F2_FORMUL"  ," "        ,NIL},;
				{"F2_DESCONT" ,0          ,NIL},;
				{"F2_FRETE"   ,0          ,NIL},;
				{"F2_SEGURO"  ,0          ,NIL},;
				{"F2_DESPESA" ,0          ,NIL} }


				// inclui o item
				_aItem := {;
				{"D2_ITEM"   , _cItem      , NIL},;
				{"D2_COD"    , _cCodProd   , NIL},;
				{"D2_QUANT"  , 1           , NIL},;
				{"D2_PRCVEN" , 1           , NIL},;
				{"D2_PRUNIT" , 1           , NIL},;
				{"D2_TOTAL"  , 1           , NIL},;
				{"D2_TES"    , _cCodTES    , NIL},;
				{"AUTDELETA" , "N"         , NIL} }

				// inclui o item
				aAdd(_aItensSD2,_aItem)


				// posiciona no cadastro do cliente
				dbselectarea("SA1")
				SA1->(dbsetorder(1))
				SA1->(dbseek( xfilial("SA1")+c920Client+c920Loja ))

				// rotina automatica de inclusao de nota fiscal de saida manual
				MSExecAuto({|x,y,z| MATA920(x,y,z)}, _aCabSF2, _aItensSD2, 3) // 3-Inclusao

				// quando gerar erro/validacao na rotina automatica
				If (lMsErroAuto)
					// log rotina automatica
					_cLogRotAut := U_FtAchaErro(.T.)
					// mensagem
					_cLogGeral += "   - Erro ao gerar "+_cTpDocLog+" inutilizado "+SF2->F2_DOC+" (Id.Erro: "+AllTrim(_cLogRotAut)+")"+CRLF
					// adiciona log em html
					_cLogHtml += sfLogHtml(c920Nota, "- Erro ao gerar "+_cTpDocLog+" inutilizado "+SF2->F2_DOC+" (Id.Erro: "+AllTrim(_cLogRotAut)+")", "ERRO")
					// dados ok por cte/nfse
					_lDocSaiOk := .f.
				EndIf
			EndIf

			If (_lDocSaiOk)

				// posiciona no cadastro do cliente
				dbselectarea("SA1")
				SA1->(dbsetorder(1))
				SA1->(dbseek( xfilial("SA1")+c920Client+c920Loja ))

				// rotina automatica de exclusao de nota fiscal de saida manual
				MSExecAuto({|x,y,z| MATA920(x,y,z)}, _aCabSF2, _aItensSD2, 5) // 5-Exclusao

				// quando gerar erro/validacao na rotina automatica
				If (lMsErroAuto)
					// log rotina automatica
					_cLogRotAut := U_FtAchaErro(.T.)
					// mensagem
					_cLogGeral += "   - Erro ao excluir "+_cTpDocLog+" inutilizado "+SF2->F2_DOC+" (Id.Erro: "+AllTrim(_cLogRotAut)+")"+CRLF
					// adiciona log em html
					_cLogHtml += sfLogHtml(c920Nota, "- Erro ao excluir "+_cTpDocLog+" inutilizado "+SF2->F2_DOC+" (Id.Erro: "+AllTrim(_cLogRotAut)+")", "ERRO")
					// dados ok por cte/nfse
					_lDocSaiOk := .f.
				EndIf
			EndIf

			// importacao de documentos validos
			If (_lDocSaiOk)
				// log geral
				_cLogGeral += "   - "+_cTpDocLog+" integrado com sucesso"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(c920Nota, "- "+_cTpDocLog+" integrado com sucesso", "OK")

				// realiza bloqueio de integracao
				If ! sfFlagInt(_cFlagInt, _cIdDatamex, .t., Nil, .f.)
					// mensagem
					_cLogGeral += "   - Erro no bloqueio de integração. Contate TI. ("+mvTipoDoc+"/id: "+AllTrim(_cIdDatamex)+")"+CRLF
					// adiciona log em html
					_cLogHtml += sfLogHtml(c920Nota, "- Erro no bloqueio de integração. Contate TI. ("+mvTipoDoc+"/id: "+AllTrim(_cIdDatamex)+")", "ERRO")

				EndIf

			EndIf

			// proxima numeracao do range
		Next _nNrDoc

		// proximo CTe
	Next _nXML

Return

// ** funcao para realizar a integracao de documentos de entrada (NF)
Static Function sfGrvDocEnt(mvTipoDoc, mvXML, mvCteCanc)

	// variaveis temporaris
	local _nXML

	// tipo do documento para Log
	local _cTpDocLog := ""

	// ID interno Datamex
	local _cIdDatamex := ""

	// dados ok por nfe
	local _lDocEntOk := .f.

	// controle para validar o cadastro do fornecedor
	local _lVldCadFor := .f.

	// variaveis para uso na rotina automatica
	Local _aDadCabec := {}
	Local _aDadItens := {}
	Local _aItemSd1  := {}
	// item
	local _cItem := StrZero(1,TamSx3("D1_ITEM")[1])

	// codigo da TES utilizada
	local _cCodTES := "091"

	// condicao de pagamento
	local _cCondPag := ""

	// parcelas de pagamento
	local _aVencTit := {}
	local _nVencTit

	// numero e serie da nota fiscal
	local _cNumDocEnt := ""
	local _cSerDocEnt := PadR("U", TamSx3("F2_SERIE")[1] )

	// especie nota entrada
	local _cEspecNF := ""

	// data de emissao
	local _dEmissao := CtoD("//")

	// dados do Fornecedor
	local _cForCod  := ""
	local _cForLoj  := ""
	local _cCnpjFor := ""
	local _cForID   := ""
	local _cForNome := ""
	local _cTpForne := ""
	local _cForUf   := ""

	// operadora de crédito
	local _cOperado := ""

	// valor de frete
	local _nVlrFrete := 0

	// historico da viagem
	local _cDscViagem := ""

	// seek
	local _cSeekSE2

	// variaveis da rotina automatica
	Private lMsErroAuto := .F.

	// variaveis temporaris
	private _oXmlDocEnt := mvXML:_ROOT

	/*
	TERC_CNPJ
	TERC_ID
	TERC_DESC
	RAZ_SOCIAL
	IDCF
	DT_OPER
	VL_OPER
	SIT_PIS
	BASE_PIS
	ALIQ_PIS
	VL_PIS
	SIT_COF
	BS_COF
	ALIQ_COF
	VL_COF
	DOC_OPER
	CTR_OPER
	PREV_PGTO
	CANCELADO
	PARC01
	VLPARC01
	VCPARC01
	PARC02
	VLPARC02
	VCPARC02
	EMPRESA
	OPERADORA
	*/

	// define tipo de documento para log
	If (AllTrim(mvTipoDoc) == "CF")
		_cTpDocLog := "Contrato de Frete PJ"
		_cEspecNF  := "NF"
	EndIf

	// caso nao for vetor, converte
	If Type("_oXmlDocEnt:_LINHA") != "A"
		XmlNode2Arr(_oXmlDocEnt:_LINHA, "_LINHA")
	EndIf

	// define a quantidade de itens a processar
	If ( ! _lWorkFlow )
		_oProcInteg:SetRegua2( Len(_oXmlDocEnt:_LINHA) )
	EndIf

	// varre todos os registros disponiveis
	For _nXML := 1 to Len(_oXmlDocEnt:_LINHA)

		// reinicia variaveis
		_lDocEntOk   := .t.
		_lVldCadFor  := .f.
		_cCondPag    := ""
		_aVencTit    := {}

		// atualiza os dados para rotina automatica
		_cNumDocEnt := sfRetNum( _oXmlDocEnt:_LINHA[_nXML]:_DOC_OPER:TEXT, .t., TamSx3("F2_DOC")[1] )
		_dEmissao   := sfExtDtHr( _oXmlDocEnt:_LINHA[_nXML]:_DT_OPER:TEXT , "D")
		_cCnpjFor   := sfRetNum( _oXmlDocEnt:_LINHA[_nXML]:_TERC_CNPJ:TEXT, .f., TamSx3("A2_CGC")[1] )
		_cForID     := AllTrim(_oXmlDocEnt:_LINHA[_nXML]:_TERC_ID:TEXT)
		_cForNome   := AllTrim(_oXmlDocEnt:_LINHA[_nXML]:_TERC_DESC:TEXT)
		_cOperado   := AllTrim(_oXmlDocEnt:_LINHA[_nXML]:_OPERADORA:TEXT)
		_cDscViagem := _cOperado + " - " + AllTrim(_oXmlDocEnt:_LINHA[_nXML]:_CTR_OPER:TEXT)
		_cCNPJ      := AllTrim(_oXmlDocEnt:_LINHA[_nXML]:_EMPRESA:TEXT)

		// valor do frete
		_nVlrFrete  := Val(_oXmlDocEnt:_LINHA[_nXML]:_VL_OPER:TEXT)

		// ID interno Datamex
		_cIdDatamex := AllTrim(_oXmlDocEnt:_LINHA[_nXML]:_IDCF:TEXT)

		// define vencimento e valores das parcelas a pagar
		If ( Val(_oXmlDocEnt:_LINHA[_nXML]:_VLPARC01:TEXT) > 0 )

			// adiciona data e valor do adiantamento
			aAdd(_aVencTit, { ;
			sfExtDtHr( _oXmlDocEnt:_LINHA[_nXML]:_VCPARC01:TEXT , "D"),;
			Val(_oXmlDocEnt:_LINHA[_nXML]:_VLPARC01:TEXT) })
		EndIf

		If ( Val(_oXmlDocEnt:_LINHA[_nXML]:_VLPARC02:TEXT) > 0 )
			// adiciona data e valor do saldo final
			aAdd(_aVencTit, { ;
			sfExtDtHr( _oXmlDocEnt:_LINHA[_nXML]:_VCPARC02:TEXT , "D"),;
			Val(_oXmlDocEnt:_LINHA[_nXML]:_VLPARC02:TEXT) })
		EndIf

		// condicao de pagamento
		_cCondPag := IIf((Len(_aVencTit)==1), "003", "029")

		//Verifica se está importando o registro para a filial correta
		If (_cCNPJ != SM0->M0_CGC)
			_cLogGeral += "Filial corrente divergente do especificado na integração. Documento " + _cTpDocLog + " / " + AllTrim(_cNumDocEnt) + " (id: " + _cIdDatamex + ") / Filial " + _cCNPJ + " não integrado." + CRLF
			//proximo item a integrar
			Loop
		EndIF

		// mensagem solicitando confirmacao
		If ( ! _lWorkFlow ).and.( ! MsgYesno("Confirma integração do(a) "+_cTpDocLog+" número "+AllTrim(_cNumDocEnt)+" (id: "+_cIdDatamex+") ?", "Confirmação") )
			Loop
		EndIf

		// mensagem
		_cLogGeral += "  :: "+_cTpDocLog+" "+_cNumDocEnt+CRLF

		// incrementa Segunda Regua
		If ( ! _lWorkFlow )
			_oProcInteg:IncRegua2( _cTpDocLog+" "+_cNumDocEnt )
		EndIf

		// valida fornecedor
		If (_lDocEntOk)

			// funcao que valida o fornecedor
			If ( ! sfVldFornece(_cNumDocEnt, _cForID, @_cForCod, @_cForLoj, @_cForNome, @_cTpForne, .f., @_cForUf) )
				// mensagem
				_cLogGeral += "   - Erro ao cadastrar/atualizar dados do fornecedor "+AllTrim(_cForNome)+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(_cNumDocEnt, "- Erro ao cadastrar/atualizar dados do fornecedor "+AllTrim(_cForNome), "ERRO")

				// dados ok por nf
				_lDocEntOk := .f.
			EndIf
		EndIf

		// Verifica se a nota fiscal já está digitada no sistema
		dbSelectArea("SF1")
		SF1->(dbSetOrder(1)) // 1-F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO
		If SF1->(dbSeek( xFilial("SF1")+_cNumDocEnt+_cSerDocEnt+_cForCod+_cForLoj+"N" ))

			// mensagem
			_cLogGeral += "   - "+_cTpDocLog+" "+_cNumDocEnt+" já registrado no sistema Totvs"+CRLF
			// adiciona log em html
			_cLogHtml += sfLogHtml(_cNumDocEnt, "- "+_cTpDocLog+" "+_cNumDocEnt+" já registrado no sistema Totvs", "ERRO")

			// dados ok por nf
			_lDocEntOk := .f.
		EndIf

		// gera documento de entrada
		If (_lDocEntOk)

			// zera variaveis
			_aDadCabec := {}
			_aDadItens := {}
			_aItemSd1  := {}

			// define o cabecalho do Documento de Entrada
			_aDadCabec := { ;
			{"F1_TIPO"	 , "N"        , Nil},;
			{"F1_FORMUL" , "N"        , Nil},;
			{"F1_DOC"    , _cNumDocEnt, Nil},;
			{"F1_SERIE"  , _cSerDocEnt, Nil},;
			{"F1_EMISSAO", _dEmissao  , Nil},;
			{"F1_FORNECE", _cForCod   , Nil},;
			{"F1_LOJA"   , _cForLoj   , Nil},;
			{"F1_ESPECIE", _cEspecNF  , Nil},;
			{"E2_NATUREZ", "02010518" , Nil},;
			{"F1_COND"   , _cCondPag  , Nil},;
			{"F1_EST"    , _cForUf    , Nil} }

			// adiciona a linha
			_aItemSd1 := { ;
			{"D1_ITEM"  , _cItem      , Nil},;
			{"D1_COD"   , "9001000001", Nil},;
			{"D1_QUANT" , 1           , Nil},;
			{"D1_VUNIT" , _nVlrFrete  , Nil},;
			{"D1_TOTAL" , _nVlrFrete  , Nil},;
			{"D1_TES"   , _cCodTES    , Nil},;
			{"AUTDELETA", "N"         , Nil} }

			// adiciona o item na relacao de itens da nota
			aAdd(_aDadItens,aClone(_aItemSd1))


			// posiciona no cadastro do fornecedor
			dbselectarea("SA2")
			SA2->(dbsetorder(1)) // 1-A2_FILIAL, A2_COD, A2_LOJA
			SA2->(dbseek( xFilial("SA2")+_cForCod+_cForLoj ))

			// reinicia variaveis
			lMsErroAuto := .f.

			// rotina automatica de inclusao de documento de entrada
			MsExecAuto({|x,y,z| MATA103(x,y,z)}, _aDadCabec, _aDadItens, 3) // 3-inclusao

			// quando gerar erro/validacao na rotina automatica
			If (lMsErroAuto)
				// log rotina automatica
				_cLogRotAut := U_FtAchaErro(.T.)
				// mensagem
				_cLogGeral += "   - Erro ao gerar documento de entrada "+_cNumDocEnt+" (Id.Erro: "+AllTrim(_cLogRotAut)+")"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(_cNumDocEnt, "- Erro ao gerar documento de entrada "+_cNumDocEnt+" (Id.Erro: "+AllTrim(_cLogRotAut)+")", "ERRO")
				// dados ok por nfe
				_lDocEntOk := .f.
			EndIf
		EndIf

		// atualiza historico do titulo a pagar
		If (_lDocEntOk)

			// reinicia parcelas
			_nVencTit := 1

			// posiciona no titulo gerado
			dbSelectArea("SE2")
			SE2->(dbSetOrder(6)) // 6-E2_FILIAL, E2_FORNECE, E2_LOJA, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO
			SE2->(dbSeek( _cSeekSE2 := xFilial("SE2")+_cForCod+_cForLoj+_cSerDocEnt+_cNumDocEnt ))
			While SE2->( ! Eof() ).and.(SE2->(E2_FILIAL + E2_FORNECE + E2_LOJA + E2_PREFIXO + E2_NUM) == _cSeekSE2)

				// atualiza dados
				RecLock("SE2")
				SE2->E2_HIST    := _cDscViagem
				SE2->E2_VENCTO  := _aVencTit[_nVencTit][1]
				SE2->E2_VENCREA := _aVencTit[_nVencTit][1]
				SE2->E2_VENCORI := _aVencTit[_nVencTit][1]
				SE2->E2_VALOR   := _aVencTit[_nVencTit][2]
				SE2->E2_SALDO   := _aVencTit[_nVencTit][2]
				SE2->E2_VLCRUZ  := _aVencTit[_nVencTit][2]
				SE2->(MsUnLock())

				// incrementa titulos
				_nVencTit ++

				// proxima parcela
				SE2->(dbSkip())
			EndDo
		EndIf

		// importacao de documentos validos
		If (_lDocEntOk).and.( ! mvCteCanc )
			// log geral
			_cLogGeral += "   - "+_cTpDocLog+" integrado com sucesso (Contrato: "+AllTrim(_cDscViagem)+")"+CRLF
			// adiciona log em html
			_cLogHtml += sfLogHtml(_cNumDocEnt, "- "+_cTpDocLog+" integrado com sucesso (Contrato: "+AllTrim(_cDscViagem)+")", "OK")

			// realiza bloqueio de integracao
			If ! sfFlagInt(mvTipoDoc, _cIdDatamex, .t., Nil, .f.)
				// log geral
				_cLogGeral += "   - Erro no bloqueio de integração. Contate TI. ("+mvTipoDoc+"/id: "+AllTrim(_cIdDatamex)+")"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(_cNumDocEnt, "- Erro no bloqueio de integração. Contate TI. ("+mvTipoDoc+"/id: "+AllTrim(_cIdDatamex)+")", "ERRO")

			EndIf

		EndIf

		// libera todos os registros
		MsUnLockAll()

		// proximo CTe
	Next _nXML

Return(.t.)

// ** funcao que valida/cadastra o fornecedor
Static Function sfVldFornece(mvNumDocEnt, mvForID, mvForCod, mvForLoj, mvForNome, mvTpForne, mvVldCad, mvForUf)

	// area atual
	local _aAreaSA2 := SA2->(GetArea())

	// variavel com os dados do fornecedor
	Local _aDadosSA2 := {}

	// variavel de retorno
	local _lProcOk := .t.

	// flag para inclusao de fornecedor
	local _lIncFornece := .t.
	local _lJaCad      := .f.
	local _nOpcMnu     := 3

	// cnpj
	local _cCnpjFor := ""
	// Juridica / Fisica
	local _cTpPessoa := ""
	// razao social
	local _cNomeFor := ""
	// endereco
	Local _cEndereco := ""
	// estado (UF)
	local _cEstado := ""
	// cidade
	local _cMunicipio := ""
	// Verifica código do IBGE
	local _cCodIBGE := ""
	// bairro
	local _cBairro := ""
	// CEP
	local _cCEP := ""
	// email
	local _cEmailCte := ""

	// pais
	local _cPaisBac := ""
	local _cCodPais := ""

	// conexao com Token Datamex através de Restful/API
	Local _oCnxRest := FwRest():New(SuperGetMv("TC_DTMXURL",,"http://tecadi.e-login.net"))

	// configuracao do Header
	Local _aHeadRest := {"tenantId: 99,01"}

	// dados do retorno da chamada Restful/API
	local _aRetDados
	local _cGetRes

	// controle dos dados de Parse do XML
	local _oXML
	local _cError   := ""
	local _cWarning := ""

	// log rotina automatica
	local _cLogRotAut := ""

	// inclui o campo Authorization no formato <usuario>:<senha> na base64
	Aadd(_aHeadRest, "Authorization: Basic " + Encode64(SuperGetMv("TC_DTMXUSR",,"tecadi:t3c@d1")))

	// chamada da classe exemplo de REST com retorno de lista (XML)
	_oCnxRest:SetPath( sfRetRotinas("C01")[1][4]+mvForID )

	// executa Get do Header
	If _oCnxRest:Get(_aHeadRest)
		// atualiza dados quando conexao ok
		_cGetRes := _oCnxRest:GetResult()
		// controle de processamento
		_lProcOk := .t.
	Else
		// busca mensagem de erro na busca dos dados
		_cGetRes := _oCnxRest:GetLastError()
		// controle de processamento
		_lProcOk := .f.
		// mensagem
		_cLogGeral += "   - Erro na conexão da API do Fornecedor ID: "+AllTrim(mvForID)+" (Id.Erro: "+AllTrim(_cGetRes)+")"+CRLF
		// adiciona log em html
		_cLogHtml += sfLogHtml(mvNumDocEnt, "- Erro na conexão da API do Fornecedor ID: "+AllTrim(mvForID)+" (Id.Erro: "+AllTrim(_cGetRes)+")", "ERRO")

	EndIf

	// prepara objeto XML
	If (_lProcOk)
		// parse no XML
		_oXML := XmlParser(_cGetRes, "_", @_cError, @_cWarning )

		// valida montagem/parse correta do XML
		If ( ( _oXML == Nil ) .or. ( ! Empty(_cError) ) .or. ( ! Empty(_cWarning) ) )
			// controle de processamento
			_lProcOk := .f.
			// mensagem
			_cLogGeral += "   - Erro conversão do XML Fornecedor ID: "+AllTrim(mvForID)+" (Id.Erro: "+AllTrim(_cError)+" / "+AllTrim(_cWarning)+")"+CRLF
			// adiciona log em html
			_cLogHtml += sfLogHtml(mvNumDocEnt, "- Erro conversão do XML Fornecedor ID: "+AllTrim(mvForID)+" (Id.Erro: "+AllTrim(_cError)+" / "+AllTrim(_cWarning)+")", "ERRO")
		EndIf

	EndIf

	/*
	CODIGO
	NOME
	LOGRAD
	NUMERO
	COMPL
	BAIRRO
	CIDADE
	CODIBGE
	ESTADO
	CEP
	TELEFONE
	EMAIL
	DT_NASC
	INSC_INSS
	RG_NUMERO
	RG_ORG_EMI
	RG_DT_EMI
	RG_EST_EMI
	CPF
	NUM_DEP
	FIL_MAE
	RAZ_SOCIAL
	*/

	// atualiza variaveis
	If (_lProcOk)
		// cnpj
		_cCnpjFor := AllTrim(Upper(_oXML:_ROOT:_LINHA:_CPF:TEXT))
		// nomer
		mvForNome := AllTrim(Upper(_oXML:_ROOT:_LINHA:_RAZ_SOCIAL:TEXT))
	EndIf

	// pesquisa se o fornecedor ja esta cadastrado
	If (_lProcOk)
		// pesquisa o fornecedor
		dbSelectArea("SA2")
		SA2->(dbSetOrder(3)) //3-A2_FILIAL, A2_CGC
		If SA2->(dbSeek( xFilial("SA2") + _cCnpjFor ))
			// controle para alteracao
			_lIncFornece := .f.
			// atualiza variaveis de retorno
			mvForCod  := SA2->A2_COD
			mvForLoj  := SA2->A2_LOJA
			// tipo de pessoa
			mvTpForne := SA2->A2_TIPO
			// UF do fornecedor
			mvForUf   := SA2->A2_EST
			// fornecedor ja cadastrado
			_lJaCad   := .t.
			// opcao para alterar
			_nOpcMnu  := 4

		EndIf
	EndIf

	// se for soh validacao
	If (mvVldCad)
		Return( _lJaCad )
	EndIf

	// atualiza variaveis
	If (_lProcOk)

		// tipo do cliente
		_cTpPessoa  := IIf(Len(AllTrim(_cCnpjFor))==14, "J", "F")
		// razao social
		_cNomeFor   := FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_RAZ_SOCIAL:TEXT)))
		// endereco
		_cEndereco  := FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_LOGRAD:TEXT)))+", "
		_cEndereco  += FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_NUMERO:TEXT)))+" "
		_cEndereco  += FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_COMPL:TEXT)))+" "
		// estado (UF)
		_cEstado    := FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_ESTADO:TEXT)))
		// cidade
		_cMunicipio := FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_CIDADE:TEXT)))
		// Verifica código do IBGE
		_cCodIBGE   := SubStr(AllTrim(Upper(_oXML:_ROOT:_LINHA:_CODIBGE:TEXT)),3,5)
		// bairro
		_cBairro    := FwNoAccent(AllTrim(Upper(_oXML:_ROOT:_LINHA:_BAIRRO:TEXT)))
		// CEP
		_cCEP       := AllTrim(StrTran(_oXML:_ROOT:_LINHA:_CEP:TEXT,"-",""))
		// email
		_cEmailCte  := AllTrim(_oXML:_ROOT:_LINHA:_EMAIL:TEXT)
		_cEmailCte  := IIf(Empty(_cEmailCte), ".", _cEmailCte)
		// pais
		_cPaisBac   := sfRetPais(AllTrim(_oXML:_ROOT:_LINHA:_PAIS:TEXT), "BACEN")
		_cCodPais   := sfRetPais(AllTrim(_oXML:_ROOT:_LINHA:_PAIS:TEXT), "")

	EndIf

	// atualiza variaveis
	If (_lProcOk) .AND. (!_lJaCad)

		// alimenta Vetor com os dados do fornecedor a ser Cadastrado/atualizado
		aAdd(_aDadosSA2,{"A2_CGC"    , PadR(_cCnpjFor  , TamSx3("A2_CGC")[1]    ) , NIL}) // CPF/CNPJ
		aAdd(_aDadosSA2,{"A2_NOME"   , PadR(_cNomeFor  , TamSx3("A2_NOME")[1]   ) , NIL}) // nome
		aAdd(_aDadosSA2,{"A2_NREDUZ" , PadR(_cNomeFor  , TamSx3("A2_NREDUZ")[1] ) , NIL}) // nome fantasia
		aAdd(_aDadosSA2,{"A2_END"    , PadR(_cEndereco , TamSx3("A2_END")[1]    ) , NIL}) // endereco
		aAdd(_aDadosSA2,{"A2_BAIRRO" , PadR(_cBairro   , TamSx3("A2_BAIRRO")[1] ) , NIL}) // bairro
		aAdd(_aDadosSA2,{"A2_EST"    , PadR(_cEstado   , TamSx3("A2_EST")[1]    ) , NIL}) // estado
		aAdd(_aDadosSA2,{"A2_COD_MUN", PadR(_cCodIBGE  , TamSx3("A2_COD_MUN")[1]) , NIL}) // codigo do municipio
		aAdd(_aDadosSA2,{"A2_MUN"    , PadR(_cMunicipio, TamSx3("A2_MUN")[1]    ) , NIL}) // descricao do municipio
		aAdd(_aDadosSA2,{"A2_CEP"    , PadR(_cCEP      , TamSx3("A2_CEP")[1]    ) , NIL}) // CEP
		aAdd(_aDadosSA2,{"A2_TIPO"   , PadR(_cTpPessoa , TamSx3("A2_TIPO")[1]   ) , NIL}) // F-Fisica/J-Juridica
		aAdd(_aDadosSA2,{"A2_EMAIL"  , PadR(_cEmailCte , TamSx3("A2_EMAIL")[1]  ) , NIL}) // e-mail do cliente
		aAdd(_aDadosSA2,{"A2_CODPAIS", PadR(_cPaisBac  , TamSx3("A2_CODPAIS")[1]) , NIL}) // pais do BACEN

		// se for alteracao, inclui campos codigo e loja
		If ( ! _lIncFornece )
			aAdd(_aDadosSA2,{"A2_COD" , mvForCod, NIL}) // codigo
			aAdd(_aDadosSA2,{"A2_LOJA", mvForLoj, NIL}) // loja
		EndIf

		// padroniza dicionario de dados
		_aDadosSA2 := FWVetByDic(_aDadosSA2, 'SA2', .F.)

		// variavel padrao
		lMsErroAuto := .F.

		// reposiciona no registro
		DbSelectArea("SA2")
		SA2->(dbSetOrder(1)) // 1-A2_FILIAL, A2_COD, A2_LOJA

		// rotina automatica de cadastro de fornecedor
		MSExecAuto({|x,y| MATA020(x,y)}, _aDadosSA2, _nOpcMnu ) // 3-Inclusao / 4-Alteracao

		// erro de rotina automatica
		If (lMsErroAuto)
			// log rotina automatica
			_cLogRotAut := U_FtAchaErro(.T.)
			// mensagem
			_cLogGeral += "   - Erro rotina automática Cadastro de fornecedor " + AllTrim(_cNomeFor) + " (Id.Pessoa:" + mvForID + " / Id.Erro: " + AllTrim(_cLogRotAut) + ")"+CRLF
			// adiciona log em html
			_cLogHtml += sfLogHtml(mvNumDocEnt, "- Erro rotina automática Cadastro de fornecedor  " + AllTrim(_cNomeFor) + " (Id.Pessoa:" + mvForID + " / Id.Erro: " + AllTrim(_cLogRotAut) + ")", "ERRO")
			// controle de processamento
			_lProcOk := .f.
		Endif

	EndIf

	// dados Ok
	If (_lProcOk)

		// atualiza variaveis de retorno
		mvForCod  := SA2->A2_COD
		mvForLoj  := SA2->A2_LOJA
		// tipo de pessoa
		mvTpForne := SA2->A2_TIPO
		// UF do fornecedor
		mvForUf   := SA2->A2_EST

	EndIf

Return(_lProcOk)

// ** funcao para integrar as movimentacoes de baixa de contratos de fretes
Static Function sfBxTitPag(mvXML, mvIsTarifa)

	// variaveis temporaris
	local _nXML
	local _cQuery

	// ID interno Datamex
	local _cIdDatamex := ""

	// data do lancamento
	local _dDtLancto := CtoD("//")

	// tipo do documento
	local _cTipoDoc := ""

	// valor do lancamento
	local _nVlrLancto := 0

	// dados ok por nfe
	local _lDocEntOk := .f.

	// controle de pesquisa do titulo a pagar
	local _lAchouTit := .f.

	// controle se ja ocorreu a movimentacao de baixa (manual)
	local _lAchouMov := .f.

	// dados do Fornecedor
	local _cForCod  := ""
	local _cForLoj  := ""
	local _cForID   := ""
	local _cForNome := ""
	local _cTpForne := ""
	local _cForUf   := ""

	// numero e serie da nota fiscal / contrato de frete
	local _cNumDocEnt := ""
	local _cSerDocEnt := ""

	// historico da viagem
	local _cDscViagem := ""

	// numero do titulo a pagar (pode ser diferente, se for lancamento manual)
	local _cPrfTitPag := ""
	local _cNumTitPag := ""
	local _cParTitPag := ""
	local _nRecnoSE2  := 0
	local _aRecnoSE2  := {}
	local _lParcUnic  := .f.
	local _cSeqParce  := ""
	local _cTpFormPgt := ""

	// variáveis da operadora de credito
	local _cOperadora := ""
	Local _cCdAdmCred := ""
	Local _cLjAdmCred := ""
	local _cBanTitPA  := ""
	local _cAgeTitPA  := ""
	local _cConTitPA  := ""

	// Codigo e Loja da Prestadora de Credito (Rodocred/DbTrans)
	local _cCdAdmRodo := "000394"
	local _cLjAdmRodo := "02"

	// Codigo e Loja da Prestadora de Credito (Repom)
	local _cCdAdmRepo := "002290"
	local _cLjAdmRepo := "01"

	// natureza PA
	local _cNatTitPA  := "03010803"
	// numero da PA
	local _cNumTitPA  := ""

	// banco, agencia e conta do PA - RODOCRED
	local _cBanTitRC  := PadR("000"       , Len(SE5->E5_BANCO)  )
	local _cAgeTitRC  := PadR("0000"      , Len(SE5->E5_AGENCIA))
	local _cConTitRC  := PadR("0000832271", Len(SE5->E5_CONTA)  )

	// banco, agencia e conta do PA - REPOM
	local _cBanTitRE  := PadR("341"       , Len(SE5->E5_BANCO)  )
	local _cAgeTitRE  := PadR("1145"      , Len(SE5->E5_AGENCIA))
	local _cConTitRE  := PadR("26712"     , Len(SE5->E5_CONTA)  )

	// titulo PA ok
	local _lTitPAOk   := .f.

	// estrutura do vetor
	// 1-IdBaixa
	// 2-Data
	// 3-Valor
	local _aTarifas   := {}
	local _nTarifa    := 0
	local _aTotPorDia := {}
	local _nTarPorDia := 0
	local _nVlrTotDia := 0

	// titulo ja existe
	local _lTitExiste := .f.

	// variaveis para uso na geracao de titulo de pagamento antecipado
	Local _aArraySE2 := {}

	// variaveis para uso na movimentacao da baixa a pagar
	local _aBaixaPag := {}

	// seek
	local _cSeekSE5
	local _cSeekSE2

	// gera log da tarifa
	local _lLogTarifa := .f.

	// log rotina automatica
	local _cLogRotAut := ""

	// tamanho campo parcela
	local _nTamParc := TamSx3("E2_PARCELA")[1]

	// sim para todos
	local _lSimTodos := .f.
	local _nOpcSelec := 0

	// data base atual
	local _dDtBasAtu := dDataBase

	// variaveis da rotina automatica
	Private lMsErroAuto := .F.

	// variaveis temporaris
	private _oXmlBaiPag := mvXML:_ROOT

	/*
	IDBAIXA
	ITEMBAIXA
	TP_DOC
	VL_LANC
	VL_ACRES
	VL_DESC
	VL_PAGO
	NAOFATURAR
	DOC_ID
	HISTORICO
	SERIE
	NUMERO
	CTR_OPER
	DT_EMISSAO
	PESSOA
	FATURA_ID
	DT_LANC
	ID_TERC
	DESC_TERC
	RAZ_TERC
	CHAVEBAIXA
	QTPARC
	OPERADORA
	*/

	// caso nao for vetor, converte
	If Type("_oXmlBaiPag:_LINHA") != "A"
		XmlNode2Arr(_oXmlBaiPag:_LINHA, "_LINHA")
	EndIf

	// define a quantidade de itens a processar
	If ( ! _lWorkFlow )
		_oProcInteg:SetRegua2( Len(_oXmlBaiPag:_LINHA) )
	EndIf

	// varre todas as movimentacoes de baixas
	For _nXML := 1 to Len(_oXmlBaiPag:_LINHA)

		// reinicia variaveis
		_lDocEntOk  := .t.
		_lAchouTit  := .f.
		_lAchouMov  := .f.
		_cNumDocEnt := sfRetNum( _oXmlBaiPag:_LINHA[_nXML]:_NUMERO:TEXT, .t., TamSx3("F1_DOC")[1] )
		_cForCod    := ""
		_cForLoj    := ""
		_cTpForne   := ""
		_cForID     := AllTrim(_oXmlBaiPag:_LINHA[_nXML]:_ID_TERC:TEXT)
		_cForNome   := AllTrim(_oXmlBaiPag:_LINHA[_nXML]:_DESC_TERC:TEXT)
		_cDscViagem := AllTrim(_oXmlBaiPag:_LINHA[_nXML]:_CTR_OPER:TEXT)
		_lLogTarifa := .f.
		_lParcUnic  := (Val(_oXmlBaiPag:_LINHA[_nXML]:_QTPARC:TEXT) == 1)
		_cTpFormPgt := AllTrim(_oXmlBaiPag:_LINHA[_nXML]:_SERIE:TEXT)
		_cOperadora := AllTrim(_oXmlBaiPag:_LINHA[_nXML]:_OPERADORA:TEXT)
		///		_cCNPJ      := AllTrim(_oXmlBaiPag:_LINHA[_nXML]:_EMPRESA:TEXT)

		// substitui a variável com os dados bancários de acordo com a operadora de crédito
		If ( _cOperadora == "REPOM" )
			_cCdAdmCred := _cCdAdmRepo
			_cLjAdmCred := _cLjAdmRepo
			_cBanTitPA  := _cBanTitRE
			_cAgeTitPA  := _cAgeTitRE
			_cConTitPA  := _cConTitRE
		ElseIf  ( _cOperadora == "RODOCRED" )
			_cCdAdmCred := _cCdAdmRodo
			_cLjAdmCred := _cLjAdmRodo
			_cBanTitPA  := _cBanTitRC
			_cAgeTitPA  := _cAgeTitRC
			_cConTitPA  := _cConTitRC
		EndIf

		// dados titulo a pagar
		_cPrfTitPag := ""
		_cNumTitPag := ""
		_cParTitPag := ""
		_cSeqParce  := ""
		_nRecnoSE2  := 0
		_aRecnoSE2  := {}

		// ID interno Datamex
		_cIdDatamex := AllTrim(_oXmlBaiPag:_LINHA[_nXML]:_CHAVEBAIXA:TEXT)

		// data do lancamento
		_dDtLancto  := sfExtDtHr( _oXmlBaiPag:_LINHA[_nXML]:_DT_LANC:TEXT , "D")

		// tipo do documento
		_cTipoDoc   := AllTrim(_oXmlBaiPag:_LINHA[_nXML]:_TP_DOC:TEXT)

		// valor do lancamento
		_nVlrLancto := Val(_oXmlBaiPag:_LINHA[_nXML]:_VL_PAGO:TEXT)

		// verifica se processa todos ou nao
		If ( ! _lWorkFlow ).and.( ! mvIsTarifa ).and.( ! _lSimTodos )

			//			//Verifica se está importando o registro para a filial correta
			//			If (_cCNPJ != SM0->M0_CGC)
			//				_cLogGeral += "Filial corrente divergente do especificado na integração. Baixa contrato frente " + AllTrim(_cNumDocEnt) + " / (id: " + _cIdDatamex + ") / Filial " + _cCNPJ + " não integrado." + CRLF
			//				//proximo item a integrar
			//				Loop
			//			EndIF

			// mensagem solicitando confirmacao
			_nOpcSelec := Aviso("Confirmação", "Confirma integração da Baixa de Contrato de Frete número "+AllTrim(_cNumDocEnt)+" (id: "+_cIdDatamex+") ?", {"Sim","Sim - Todos","Não","Não - Todos"}, 3)

			// cancelar/interromper
			If (_nOpcSelec == 0).or.(_nOpcSelec == 4)
				Return
			ElseIf (_nOpcSelec == 3)
				Loop
			ElseIf (_nOpcSelec == 2)
				_lSimTodos := .t.
			EndIf
		EndIf

		// agreda total de tarifas
		If (mvIsTarifa).and.(_cTipoDoc == "R")

			// adiciona o registro tarifa
			// estrutura do vetor
			// 1-IdBaixa
			// 2-Data
			// 3-Valor
			// 4-Operadora
			aAdd(_aTarifas,{;
			_cIdDatamex ,;
			_dDtLancto  ,;
			_nVlrLancto ,;
			_cOperadora })

		EndIf

		// valida se o cadastro do fornecedor esta ok
		If ( ! mvIsTarifa ).and.(_lDocEntOk)
			// funcao que valida o fornecedor
			If ( ! sfVldFornece(_cNumDocEnt, _cForID, @_cForCod, @_cForLoj, @_cForNome, @_cTpForne, .t., @_cForUf) )
				// mensagem
				_cLogGeral += "   - Erro ao cadastrar/atualizar dados do fornecedor "+AllTrim(_cForNome)+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(_cNumDocEnt, "- Erro ao cadastrar/atualizar dados do fornecedor "+AllTrim(_cForNome), "ERRO")
				// dados ok por nf
				_lDocEntOk := .f.
			EndIf
		EndIf

		// tentativa de pesquisa de titulos atraves do numero do contrato de frete (ex: 14636/ CF. TERC)
		If ( ! mvIsTarifa ).and.(_lDocEntOk).and.( ! _lAchouTit )

			// define a serie do documento para pesquisa
			_cSerDocEnt := IIf(_cTpForne == "F", "GPE", "U")
			// padroniza tamanho do campo
			_cSerDocEnt := PadR(_cSerDocEnt, TamSx3("F2_SERIE")[1] )

			// define forma de pesquisa da parcela
			If (_lParcUnic)
				_cSeqParce := Space(_nTamParc)
			ElseIf ( ! _lParcUnic).and.(_cTpFormPgt == "ADT")
				_cSeqParce := StrZero(1,_nTamParc)
			ElseIf ( ! _lParcUnic).and.(_cTpFormPgt == "SAL")
				_cSeqParce := StrZero(2,_nTamParc)
			EndIf

			// pesquisa o titulos a pagar
			dbSelectArea("SE2")
			SE2->(dbSetOrder(6)) // 6-E2_FILIAL, E2_FORNECE, E2_LOJA, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO
			SE2->(dbSeek( _cSeekSE2 := xFilial("SE2")+_cForCod+_cForLoj+_cSerDocEnt+_cNumDocEnt+_cSeqParce ))
			If SE2->( ! Eof() ).and.( _cSeekSE2 == SE2->(E2_FILIAL + E2_FORNECE + E2_LOJA + E2_PREFIXO + E2_NUM + E2_PARCELA) )
				// variavel de controle
				_lAchouTit := .t.
				// dados titulos a apgar
				_cPrfTitPag := SE2->E2_PREFIXO
				_cNumTitPag := SE2->E2_NUM
				_cParTitPag := SE2->E2_PARCELA
				_nRecnoSE2  := SE2->(RecNo())
			EndIf

		EndIf

		// tentativa de pesquisa de titulos atraves do contrato de frete (ex: 72084.2016.3568)
		If ( ! mvIsTarifa ).and.(_lDocEntOk).and.( ! _lAchouTit )

			// query para pesquisa o titulos a pagar
			_cQuery := " SELECT SE2.R_E_C_N_O_ SE2RECNO "
			// titlos a pagar
			_cQuery += " FROM   "+RetSqlTab("SE2")
			// filtro padrao
			_cQuery += " WHERE  "+RetSqlCond("SE2")
			// fornecedor
			_cQuery += "        AND E2_FORNECE = '"+_cForCod+"' AND E2_LOJA = '"+_cForLoj+"' "
			// prefixo
			_cQuery += "        AND E2_PREFIXO = '"+_cSerDocEnt+"' "
			// tipo do documento
			_cQuery += "        AND E2_TIPO = '"+ IIf(_cTpForne == "F", "RPA", "NF") +"' "
			// historico
			_cQuery += "        AND E2_HIST LIKE '%" + _cOperadora + "-" + _cDscViagem + "' "

			// atualiza dados
			_aRecnoSE2 := U_SqlToVet(_cQuery)

			// se encontrou apenas um registro
			If (Len(_aRecnoSE2) == 1)
				// posiciona no registro do titulo
				dbSelectArea("SE2")
				SE2->(dbGoTo( _aRecnoSE2[1] ))
				// variavel de controle
				_lAchouTit := .t.
				// dados titulos a apgar
				_cPrfTitPag := SE2->E2_PREFIXO
				_cNumTitPag := SE2->E2_NUM
				_cParTitPag := SE2->E2_PARCELA
				_nRecnoSE2  := SE2->(RecNo())
			EndIf

			// se nao encontrou titulo
			If ( ! _lAchouTit )
				// mensagem
				_cLogGeral += "   - Contrato de Frete "+_cNumDocEnt+" não encontrado ("+AllTrim(_cDscViagem)+")"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(_cNumDocEnt, "- Contrato de Frete "+_cNumDocEnt+" não encontrado ("+AllTrim(_cDscViagem)+")", "ERRO")
			EndIf

		EndIf

		// verifica se a baixa ja foi realizada, para atualizar a flag de integracap
		If ( ! mvIsTarifa ).and.(_lDocEntOk).and.( _lAchouTit )

			// posiciona no registro do titulo a pagar
			dbSelectArea("SE2")
			SE2->(dbGoTo( _nRecnoSE2 ))

			// pesquisa as baixas do titulo
			dbSelectArea("SE5")
			SE5->(dbSetOrder(7)) // 7-E5_FILIAL, E5_PREFIXO, E5_NUMERO, E5_PARCELA, E5_TIPO, E5_CLIFOR, E5_LOJA, E5_SEQ
			SE5->(dbSeek( _cSeekSE5 := xFilial("SE5")+SE2->E2_PREFIXO+SE2->E2_NUM+SE2->E2_PARCELA+SE2->E2_TIPO+SE2->E2_FORNECE+SE2->E2_LOJA ))

			// varre todas as movimentacoes de baixa, compara data e valor
			While SE5->( ! Eof() ).and.(SE5->(E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA) == _cSeekSE5)
				// verifica se tem saldo, ou, compara data e valor
				If (SE2->E2_SALDO == 0).or.((SE5->E5_RECPAG == "P").and.(SE5->E5_DATA == _dDtLancto).and.(SE5->E5_VALOR == _nVlrLancto))
					// controle que ja ocorreu a movimentacao de baixa, somente para atualizar flag de integracao
					_lAchouMov := .t.
				EndIf
				// proximo item
				SE5->(dbSkip())
			EndDo

		EndIf

		// quando nao ocorreu a baixa (manual), realiza a movimentacao da baixa
		If ( ! mvIsTarifa ).and.(_lDocEntOk).and.(SE2->E2_SALDO != 0).and.(_lAchouTit).and.( ! _lAchouMov )

			// posiciona no registro do titulo a pagar
			dbSelectArea("SE2")
			SE2->(dbGoTo( _nRecnoSE2 ))

			// prepara dados para movimentacao da baixa a pagar
			_aBaixaPag := {;
			{"E2_FILIAL"   , SE2->E2_FILIAL , NIL},;
			{"E2_PREFIXO"  , SE2->E2_PREFIXO, NIL},;
			{"E2_NUM"      , SE2->E2_NUM    , NIL},;
			{"E2_PARCELA"  , SE2->E2_PARCELA, NIL},;
			{"E2_TIPO"     , SE2->E2_TIPO   , NIL},;
			{"E2_FORNECE"  , SE2->E2_FORNECE, NIL},;
			{"E2_LOJA"     , SE2->E2_LOJA   , NIL},;
			{"AUTMOTBX"    , "DEB"          , Nil},;
			{"AUTBANCO"    , _cBanTitPA     , Nil},;
			{"AUTAGENCIA"  , _cAgeTitPA     , Nil},;
			{"AUTCONTA"    , _cConTitPA     , Nil},;
			{"AUTDTBAIXA"  , _dDtLancto     , Nil},;
			{"AUTDTCREDITO", _dDtLancto     , Nil},;
			{"AUTVLRPG"    , _nVlrLancto    , Nil} }

			// reinicia variaveis da rotina automatica
			lMsErroAuto := .f.
			// troca data base
			_dDtBasAtu := dDataBase
			dDataBase  := _dDtLancto

			// executa rotina automatica para lancamento do titulo a pagar, como pagamento antecipado
			MSExecAuto({|x,y| FINA080(x,y)}, _aBaixaPag, 3) // 3 - Inclusao, 4 - Alteração, 5 - Exclusão

			// retorna data base
			dDataBase := _dDtBasAtu

			// em caso de falha apresenta erro
			If (lMsErroAuto)
				// log rotina automatica
				_cLogRotAut := U_FtAchaErro(.T.)
				// mensagem
				_cLogGeral += "   - Erro ao gerar a baixa do pagamento antecipado - "+AllTrim(_cDscViagem)+" (Id.Erro: "+AllTrim(_cLogRotAut)+")"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(_cNumDocEnt, "- Erro ao gerar a baixa do pagamento antecipado - "+AllTrim(_cDscViagem)+" (Id.Erro: "+AllTrim(_cLogRotAut)+")", "ERRO")
			Else
				// controle de processamento
				_lAchouMov := .t.

			EndIf

		EndIf

		// atualiza flag de integracao
		If ( ! mvIsTarifa ).and.(_lDocEntOk).and.(_lAchouTit).and.(_lAchouMov)

			// log geral
			_cLogGeral += "   - Data "+DtoC(_dDtLancto)+" Fornecedor "+AllTrim(_cForNome)+" Valor R$ "+AllTrim(Transf(_nVlrLancto,PesqPict("SE2","E2_VALOR")))+" Contrato "+AllTrim(_cDscViagem)+" integrado com sucesso"+CRLF
			// adiciona log em html
			_cLogHtml += sfLogHtml(_cNumDocEnt, "- Data "+DtoC(_dDtLancto)+" Fornecedor "+AllTrim(_cForNome)+" Valor R$ "+AllTrim(Transf(_nVlrLancto,PesqPict("SE2","E2_VALOR")))+" Contrato "+AllTrim(_cDscViagem)+" integrado com sucesso", "OK")

			// realiza bloqueio de integracao
			If ! sfFlagInt("BAIXA_RODOCRED", _cIdDatamex, .t., Nil, .f.)
				// log geral
				_cLogGeral += "   - Erro no bloqueio de integração de Baixas Rodocred. Contate TI. (id: "+AllTrim(_cIdDatamex)+")"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml("", "- Erro no bloqueio de integração de Baixas Rodocred. Contate TI. (id: "+AllTrim(_cIdDatamex)+")", "ERRO")

			EndIf
		EndIf

	Next _nXML

	// lancamento de Pagamento Antecipado de Tarifas
	If (mvIsTarifa) .AND. (Len(_aTarifas) > 0)

		// reinicia variaveis
		_aTotPorDia := {}
		_dDtLancto  := CtoD("//")
		_nVlrTotDia := 0
		_cOperadora := ""

		// organiza os dados por data + operadora
		// estrutura do vetor
		// 1-IdBaixa
		// 2-Data
		// 3-Valor
		// 4-Operadora
		aSort(_aTarifas,,,{|x,y| DtoS(x[2]) + x[4] < DtoS(y[2]) + y[4] })

		// varre todos os lancamento do dia para totalizar
		For _nTarifa := 1 to Len(_aTarifas)

			// somente tarifas de dias anteriores (periodo fechado)
			If (_aTarifas[_nTarifa][2] == Date())
				Loop
			EndIf

			// valida data e operadora
			If (_dDtLancto != _aTarifas[_nTarifa][2]) .OR. (_cOperadora != _aTarifas[_nTarifa][4])

				// se o dia possui valor, inclui no array de totais por dia
				If (_nVlrTotDia > 0)
					// total por dia
					aAdd(_aTotPorDia,{;
					_dDtLancto  ,;
					_nVlrTotDia ,;
					_cOperadora})
				EndIf

				// atualiza data de lancamento para controle
				_dDtLancto  := _aTarifas[_nTarifa][2]

				// atualiza operadora de crédito para controle
				_cOperadora := _aTarifas[_nTarifa][4]

				// zera total do dia
				_nVlrTotDia := 0
			EndIf

			// incrementa valor total
			_nVlrTotDia += _aTarifas[_nTarifa][3]

		Next _nTarifa

		// verifica se tem valor para lancar no dia
		If (_nVlrTotDia > 0)
			// total por dia
			aAdd(_aTotPorDia,{;
			_dDtLancto  ,;
			_nVlrTotDia ,;
			_cOperadora})
		EndIf

		// verifica se ha dados para lancamentos
		For _nTarPorDia := 1 to Len(_aTotPorDia)

			// reinicia variaveis
			_lTitExiste := .f.
			_aArraySE2  := {}
			_lTitPAOk   := .f.
			_aBaixaPag  := {}

			// substitui a variável com os dados bancários de acordo com a operadora de crédito
			If ( _aTotPorDia[_nTarPorDia][3] == "REPOM" )
				_cOperadora := "REPOM"
				_cCdAdmCred := _cCdAdmRepo
				_cLjAdmCred := _cLjAdmRepo
				_cBanTitPA  := _cBanTitRE
				_cAgeTitPA  := _cAgeTitRE
				_cConTitPA  := _cConTitRE
			ElseIf  ( _aTotPorDia[_nTarPorDia][3] == "RODOCRED" )
				_cOperadora := "RODOCRED"
				_cCdAdmCred := _cCdAdmRodo
				_cLjAdmCred := _cLjAdmRodo
				_cBanTitPA  := _cBanTitRC
				_cAgeTitPA  := _cAgeTitRC
				_cConTitPA  := _cConTitRC
			EndIf

			// atualiza data de lancamento
			_dDtLancto  := _aTotPorDia[_nTarPorDia][1]
			// total do dia
			_nVlrTotDia := _aTotPorDia[_nTarPorDia][2]

			// verificar se existe lancamento, para baixar movimentacoes anteriores
			_lTitExiste := sfVldTitPA(_dDtLancto, _nVlrTotDia, _cCdAdmCred, _cLjAdmCred)

			// pergunta se deve lancar
			If ( ! _lWorkFlow ).and.( ! _lTitExiste ).and.( MsgYesno("Gerar Pagamento Antecipado, Data "+DtoC(_dDtLancto)+" Valor Total R$ "+AllTrim(Transf(_nVlrTotDia,PesqPict("SE2","E2_VALOR")))+ " / Operadora" + _cOperadora + " ?", "Confirmação") )

				// numero da PA
				_cNumTitPA := "0"
				_cNumTitPA += StrZero(Day(_dDtLancto)  , 2)
				_cNumTitPA += StrZero(Month(_dDtLancto), 2)
				_cNumTitPA += StrZero(Year(_dDtLancto) , 4)

				// prepara dados para emissao do titulo de pagamento antecipado
				_aArraySE2 := {;
				{"E2_PREFIXO", CriaVar("E2_PREFIXO", .f.) , NIL },;
				{"E2_NUM"    , _cNumTitPA                 , NIL },;
				{"E2_TIPO"   , "PA"                       , NIL },;
				{"E2_NATUREZ", _cNatTitPA                 , NIL },;
				{"E2_FORNECE", _cCdAdmCred                , NIL },;
				{"E2_LOJA"   , _cLjAdmCred                , NIL },;
				{"E2_EMISSAO", _dDtLancto                 , NIL },;
				{"E2_VENCTO" , _dDtLancto                 , NIL },;
				{"E2_VENCREA", DataValida(_dDtLancto)     , NIL },;
				{"E2_VALOR"  , _nVlrTotDia                , NIL },;
				{"AUTBANCO"  , _cBanTitPA                 , NIL },;
				{"AUTAGENCIA", _cAgeTitPA                 , NIL },;
				{"AUTCONTA"  , _cConTitPA                 , NIL }}

				// reinicia variaveis da rotina automatica
				lMsErroAuto := .f.

				// executa rotina automatica para lancamento do titulo a pagar, como pagamento antecipado
				MsExecAuto( { |x,y,z| FINA050(x,y,z)}, _aArraySE2,, 3) // 3 - Inclusao, 4 - Alteração, 5 - Exclusão

				// em caso de falha apresenta erro
				If (lMsErroAuto)
					// controle de processamento
					_lTitPAOk := .f.
					// log rotina automatica
					_cLogRotAut := U_FtAchaErro(.T.)
					// mensagem
					_cLogGeral += "   - Erro ao gerar pagamento antecipado ("+AllTrim(_cDscViagem)+" (Id.Erro: "+AllTrim(_cLogRotAut)+")"+CRLF
					// adiciona log em html
					_cLogHtml += sfLogHtml(_cNumTitPA, "- Erro ao gerar pagamento antecipado ("+AllTrim(_cDscViagem)+" (Id.Erro: "+AllTrim(_cLogRotAut)+")", "ERRO")
				Else
					// controle de processamento
					_lTitPAOk := .t.

				EndIf
			EndIf

			// se gerou titulo PA, baixa todas as movimentacoes do Datamex
			If (_lTitPAOk).or.(_lTitExiste)

				// mensagem
				If (_lTitExiste)
					MsgInfo("Título PA já existe, e todos as movimentações de tarifas serão marcadas no Datamex como integradas.", "Títulos")
				EndIf

				// varre novamente todas as tarifas, para baixar somente as da data movimentada
				For _nTarifa := 1 to Len(_aTarifas)

					// estrutura do vetor
					// 1-IdBaixa
					// 2-Data
					// 3-Valor
					If (_aTarifas[_nTarifa][2] == _dDtLancto)

						// gera log da tarifa
						_lLogTarifa := .t.

						// realiza bloqueio de integracao
						If ! sfFlagInt("BAIXA_RODOCRED", _aTarifas[_nTarifa][1], .t., Nil, .f.)
							// log geral
							_cLogGeral += "   - Erro no bloqueio de integração de Baixas Operadora de crédito. Contate TI. (id: "+AllTrim(_aTarifas[_nTarifa][1])+")"+CRLF
							// adiciona log em html
							_cLogHtml += sfLogHtml("", "- Erro no bloqueio de integração de Baixas Operadora de crédito. Contate TI. (id: "+AllTrim(_aTarifas[_nTarifa][1])+")", "ERRO")

						EndIf
					EndIf

				Next _nTarifa

				// gera log da tarifa
				If (_lLogTarifa)
					// log geral
					_cLogGeral += "   - Data "+DtoC(_dDtLancto)+" Tarifa no Valor R$ "+AllTrim(Transf(_nVlrTotDia,PesqPict("SE2","E2_VALOR")))+" integrado com sucesso"+CRLF
					// adiciona log em html
					_cLogHtml += sfLogHtml("", "- Data "+DtoC(_dDtLancto)+" Tarifa no Valor R$ "+AllTrim(Transf(_nVlrTotDia,PesqPict("SE2","E2_VALOR")))+" integrado com sucesso", "OK")
				EndIf

			EndIf

		Next _nTarPorDia

	EndIf

Return

// ** funcao que verifica se existe lancamento, para baixar movimentacoes anteriores
Static Function sfVldTitPA(mvDtLancto, mvVlrTotDia, mvCdAdmCred, mvLjAdmCred)
	// variavel de retorno
	local _lRet := .f.
	// query
	local _cQuery

	// prepara query para consultar se o titulo existe
	_cQuery := " SELECT Count(*) QTD_REG "
	// titulos a pagar
	_cQuery += " FROM   "+RetSqlTab("SE2")
	// filtro padrao
	_cQuery += " WHERE  "+RetSqlCond("SE2")
	// tipo (pagamento antecipado)
	_cQuery += "        AND E2_TIPO = 'PA' "
	// emissao
	_cQuery += "        AND E2_EMISSAO = '"+DtoS(mvDtLancto)+"' "
	// valor
	_cQuery += "        AND E2_VALOR = "+AllTrim(Str(mvVlrTotDia))
	// fornecedor e loja
	_cQuery += "        AND E2_FORNECE = '"+mvCdAdmCred+"' AND E2_LOJA = '"+mvLjAdmCred+"' "

	// atualiza variavel de retorno
	_lRet := (U_FtQuery(_cQuery) == 1)

Return(_lRet)

// ** funcao para agendamento da rotina em schedule
User Function TMSXDATW(mvParamIxb)

	// tamanho do vetor
	Local _nTamVet := 0
	// codido da empresa
	local _cCodEmp := ""
	// codigo da filial
	local _cCodFil := ""

	// valor padrao
	Default mvParamIxb := {"","","","03","101","",""}

	// define valores
	_nTamVet := Len(mvParamIxb)

	// verifica se ha algum ambiente ativo
	If (Select("SM0") == 0)

		// limpa qualquer ambiente
		RpcClearEnv()

		// se tamanho do vetor estiver correto
		If (_nTamVet >= 4)

			// codigo da empresa
			_cCodEmp := mvParamIxb[_nTamVet - 3]

			// codigo da filial
			_cCodFil := mvParamIxb[_nTamVet - 2]

			// prepara ambiente
			RpcSetEnv(_cCodEmp, _cCodFil,,,"TMS",,{"DT6","DTC","SE1","SE2","SE5"})

			// executa funcao
			U_TTMSXDAT(.t.)

			// limpa qualquer ambiente
			RpcClearEnv()

		EndIf
	EndIf

Return

// ** funcao para integrar as Prorrogações de Vencimento de Boletos
Static Function sfAltVencto(mvXML)

	// variaveis temporaris
	local _nXML
	local _cQuery

	// seek
	local _cSeekSE1

	// dados da fatura
	Local _cNrFatura := ""
	local _cPrefFat  := PadR("TMS", TamSx3("E1_PREFIXO")[1])
	local _cParcFat  := StrZero(1 , TamSx3("E1_PARCELA")[1])
	local _cTipoFat  := PadR("FT" , TamSx3("E1_TIPO")[1]   )
	local _dDtVencto := CtoD("//")

	// ID interno Datamex
	local _cIdDatamex := ""

	// controle de pesquisa do titulo a receber
	local _lAchouTit := .f.

	// controle se ja ocorreu alteracao do vencimento
	local _lVenctoOk := .f.

	// id do cliente datamex
	local _cCliID

	// dados ok por fatura
	local _lFatOk := .f.

	// tipo do boleto
	local _cTpBoleto := ""

	// variaveis usadas na funcao sfVldCliente
	private _cCodCli    := ""
	private _cLojCli    := ""
	private _cCliNome   := ""
	private _cTipoCli   := "" // tipo do cliente (F-Cons. Final/X-Exportacao)

	// variaveis temporaris
	private _oXmlAltVen := mvXML:_ROOT

	/*
	ID_DUP
	IDFAT
	VL_JM
	status
	ID_CLI
	Cli_Desc
	Tipo
	Numero
	Conv_Desc
	Nro_bol
	Nro_bolfrm
	DtCobranca
	DtVenc
	Valor
	Nro_rem
	FEBRABAN
	AGENCIA
	CC
	user_id
	TPBOLETO
	*/

	// caso nao for vetor, converte
	If Type("_oXmlAltVen:_LINHA") != "A"
		XmlNode2Arr(_oXmlAltVen:_LINHA, "_LINHA")
	EndIf

	// define a quantidade de itens a processar
	If ( ! _lWorkFlow )
		_oProcInteg:SetRegua2( Len(_oXmlAltVen:_LINHA) )
	EndIf

	// varre todas as movimentacoes de baixas
	For _nXML := 1 to Len(_oXmlAltVen:_LINHA)

		// reinicia variaveis
		_lFatOk     := .t.
		_lAchouTit  := .f.
		_lVenctoOk  := .f.
		_cNrFatura  := sfRetNum( _oXmlAltVen:_LINHA[_nXML]:_NUMERO:TEXT, .t., TamSx3("E1_NUM")[1] )
		_dDtVencto  := sfExtDtHr(_oXmlAltVen:_LINHA[_nXML]:_DtVenc:TEXT, "D")
		_cCliID     := AllTrim(_oXmlAltVen:_LINHA[_nXML]:_ID_CLI:TEXT)
		_cIdDatamex := AllTrim(_oXmlAltVen:_LINHA[_nXML]:_ID_DUP:TEXT)
		_cTpBoleto  := AllTrim(_oXmlAltVen:_LINHA[_nXML]:_TPBOLETO:TEXT)
		//		_cCNPJ      := AllTrim(_oXmlAltVen:_LINHA[_nXML]:_EMPRESA:TEXT)

		// valida se o boleto eh do tipo A-Alterado
		If (_cTpBoleto != "A")
			Loop
		EndIf

		//		//Verifica se está importando o registro para a filial correta
		//		If (_cCNPJ != SM0->M0_CGC)
		//			_cLogGeral += "Filial corrente divergente do especificado na integração. Prorrogação " + _cNrFatura + " / " + _dDtVencto + " (id: " + _cIdDatamex + ") / Filial " + _cCNPJ + " não integrado." + CRLF
		//			//proximo item a integrar
		//			Loop
		//		EndIF

		// funcao que valida o cliente
		If ( ! sfVldCliente(_cCliID, .t., Nil, Nil) )
			// mensagem
			_cLogGeral += "   - Erro ao cadastrar/atualizar dados do cliente "+AllTrim(_cCliNome)+CRLF
			// adiciona log em html
			_cLogHtml += sfLogHtml(_cNrFatura, "- Erro ao cadastrar/atualizar dados do cliente "+AllTrim(_cCliNome), "ERRO")
			// dados ok por cte
			_lFatOk := .f.
		EndIf

		// verifica se a fatura existe no sistema
		If (_lFatOk)
			dbSelectArea("SE1")
			SE1->(dbSetOrder(2)) // 2-E1_FILIAL, E1_CLIENTE, E1_LOJA, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO
			If SE1->(dbSeek( _cSeekSE1 := xFilial("SE1")+_cCodCli+_cLojCli+_cPrefFat+_cNrFatura+_cParcFat+_cTipoFat ))
				// mensagem de log
				_cLogGeral += "   - Fatura não registrada no ERP TOTVS, prefixo "+_cPrefFat+" número "+_cNrFatura+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(_cNrFatura, "- Fatura não registrada no ERP TOTVS, prefixo "+_cPrefFat+" número "+_cNrFatura, "ERRO")
				// dados ok por fatura
				_lFatOk := .f.
			EndIf
		EndIf

		// verifica o saldo
		If (_lFatOk)
			If (SE1->E1_SALDO == 0)
				// mensagem de log
				_cLogGeral += "   - Fatura já quitada, prefixo "+_cPrefFat+" número "+_cNrFatura+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(_cNrFatura, "- Fatura já quitada, prefixo "+_cPrefFat+" número "+_cNrFatura, "ALERTA")
				// vencimento ok por fatura
				_lVenctoOk := .t.
			EndIf
		EndIf

		// valida o vencimento
		If (_lFatOk)
			If (_dDtVencto == SE1->E1_VENCREA)
				// mensagem de log
				_cLogGeral += "   - Fatura com Data de Vencimento já alterada, prefixo "+_cPrefFat+" número "+_cNrFatura+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(_cNrFatura, "- Fatura com Data de Vencimento já alterada, prefixo "+_cPrefFat+" número "+_cNrFatura, "ALERTA")
				// vencimento ok por fatura
				_lVenctoOk := .t.
			EndIf
		EndIf

		// altera o vencimento
		If (_lFatOk).and.( ! _lVenctoOk )

			// altera o vencimento da fatura
			dbSelectArea("SE1")
			RecLock("SE1")
			SE1->E1_VENCTO  := _dDtVencto
			SE1->E1_VENCREA := _dDtVencto
			SE1->(MsUnLock())

			// mensagem de log
			_cLogGeral += "   - Data de Vencimento alterada com sucesso, prefixo "+_cPrefFat+" número "+_cNrFatura+CRLF
			// adiciona log em html
			_cLogHtml += sfLogHtml(_cNrFatura, "- Data de Vencimento alterada com sucesso, prefixo "+_cPrefFat+" número "+_cNrFatura, "OK")
			// vencimento ok por fatura
			_lVenctoOk := .t.

		EndIf

		// realiza bloqueio de integracao
		If (_lFatOk).and.(_lVenctoOk)

			// realiza bloqueio de integracao
			If ! sfFlagInt("BOL", _cIdDatamex, .t., Nil, .f.)
				// log geral
				_cLogGeral += "   - Erro no bloqueio de integração. Contate TI. (BOL/id: "+AllTrim(_cIdDatamex)+")"+CRLF
				// adiciona log em html
				_cLogHtml += sfLogHtml(_cNrFatura, "- Erro no bloqueio de integração. Contate TI. (BOL/id: "+AllTrim(_cIdDatamex)+")", "ERRO")
			EndIf

		EndIf

	Next _nXML

Return

/*/{Protheus.doc} fTelaSel
Função auxiliar para tela com opção de escolha com itens a serem integrados.
@type function
@author Luiz Fernando Berti
@since 03/07/2019
@version 1.0
/*/
Static Function fTelaSel(cTitulo,aItens)

	LOCAL oWindow,oConfirm,oClose,oPanel1,oPanel2,oSelect := nil
	LOCAL nFor,nOpc:= 0
	LOCAL oSize   := FwDefSize():New(.F.) //Sem enchoicebar
	LOCAL cAlias  := GetNextAlias()
	LOCAL aHeader := {}
	LOCAL aStruct := {}
	LOCAL cMarca  := GetMark()
	LOCAL aAux    := {}
	LOCAL oTable  := FWTemporaryTable():New(cAlias)
	oSize:Process()

	//Estrutura para temporary table.
	aAdd(aStruct,{"OK"     ,"C",  2,0})
	aAdd(aStruct,{"CODIGO" ,"C",  30,0})
	aAdd(aStruct,{"ID"     ,"C",  30,0})
	aAdd(aStruct,{"NOME"   ,"C",  TamSX3("A1_NOME")[01],0})
	aAdd(aStruct,{"DATA1"  ,"D",  8,0})

	oTable:SetFields(aStruct)
	oTable:Create()

	// Header para MSSelect
	aAdd(aHeader,{"OK"    ,"","  "        , ""     })
	aAdd(aHeader,{"CODIGO"   ,"","Código"    , ""     })
	aAdd(aHeader,{"ID" ,"","ID Datamex" , ""     })
	aAdd(aHeader,{"NOME" ,"","Nome" , ""     })
	aAdd(aHeader,{"DATA1" ,"","Data" , ""     })

	//Preenche a tabela temporária.
	For nFor:= 1 To Len(aItens)
		RecLock(cAlias,.T.)
		(cAlias)->OK     := cMarca
		(cAlias)->CODIGO := aItens[nFor][01]
		(cAlias)->ID     := aItens[nFor][02]
		(cAlias)->NOME   := aItens[nFor][03]
		(cAlias)->DATA1  := aItens[nFor][04]
		MSUnLock()
	Next
	(cAlias)->(DBGoTop())

	oWindow := MSDialog():New(oSize:aWindSize[1],oSize:aWindSize[2],oSize:aWindSize[3],oSize:aWindSize[4],cTitulo,,,.F.,,,,,,.T.,,,.T. )
	oWindow:lMaximized := .T.

	oPanel1 := TPanel():New(000,000,cTitulo,oWindow,,.F.,.F.,,,26,26,.T.,.F. )
	oPanel1:Align := CONTROL_ALIGN_TOP
	oConfirm := TButton():New(010,005,"Confirmar",oPanel1,{||nOpc := 1,oWindow:End()  },030,015,,,,.T.,,"",,,,.F. )
	oClose   := TButton():New(010,((oSize:aWindSize[4]/2)-35),"Fechar",oPanel1,{|| oWindow:End() },030,015,,,,.T.,,"",,,,.F. )

	oPanel2 := TPanel():New(000,000,cTitulo,oWindow,,.F.,.F.,,,120,250,.T.,.F. )
	oPanel2:Align := CONTROL_ALIGN_TOP

	oSelect := MsSelect():New((cAlias),"OK",,aHeader,,cMarca,{000,000,2000,2000},,,oPanel2,,{/*legenda*/})
	oSelect:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oSelect:oBrowse:bAllMark := {|| sfMarkAll((cAlias),"OK",cMarca) }

	ACTIVATE MSDIALOG oWindow CENTERED

	If nOpc == 1
		DBSelectArea(cAlias)
		(cAlias)->(DBGoTop())
		Do While !(cAlias)->(Eof())
			If (cAlias)->OK == cMarca
				aAdd(aAux, {AllTrim((cAlias)->CODIGO),;
				AllTrim((cAlias)->ID)}) 
			EndIf
			(cAlias)->(DBSkip())
		EndDo
	EndIf
	aItens:= AClone(aAux) 

	//Fecha arquivo temporário.
	If Select(cAlias) <> 0
		DBSelectArea(cAlias)
		(cAlias)->(dbCloseArea())
	EndIf
	oTable:Delete()

Return
