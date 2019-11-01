#Include "Totvs.ch"
#INCLUDE "XMLXFUN.CH"
#INCLUDE "FWMVCDef.ch"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "Protheus.ch"
#INCLUDE "TopConn.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para importação de Notas Fiscais de Entrada,     !
!                  ! utilizando como origem o XML da Nota Eletronica         !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 02/2011 !
+------------------+--------------------------------------------------------*/

User Function TWMSA006()

	// objetos da tela
	local _oPnlTop, _oPnlItens
	local _oBtnVldXml, _oBtnFile, _oBtnItDup, _oBtnCompl

	Local _cArquivo	:= ""
	Local _aCampos	:= {}
	Local _aGets	:= {}
	Local _aCpoBrw	:= {{"IT_SELEC"	,, " "," "},;
	{"D1_ITEM"	,, "Item","@!"},;
	{"IT_STATUS",, "Status","@!"}}

	// variavel para controle do markbrow
	local cMarca := GetMark()

	Private _bConfirma := {|| MsAguarde({|| fGeraNF(_aCampos, _cArquivo)},"Gerando Pre-NF...")}
	Private _bVldXml   := {|| MsAguarde({|| fValXML(_cArquivo,@_aCampos, @_aGets) },"Validando dados...")}
	Private _bCancel   := {|| _oDlgXML:End()}
	Private _oXML
	// nome do arquivo TRB
	Private _cNomArq
	Private _TRBSD1 := GetNextAlias()
	// controle se o arquivo esta Ok para importacao
	private _lCliForOk := .f.
	private _lItensOk := .f.
	// controle se eh cliente/fornecedor novo
	private _lNewClieFor := .f.
	// controle da estrutura do XML
	// 1. Versao 1.10 : _oXML:_NFEPROC:_NFE:_INFNFE
	// 2. Versao 2.00 : _oXML:_NFE:_INFNFE
	private _cBaseXML := ""

	// tipo do produto - padrão ME
	Private _cDflTipo	:= "ME"
	// armazem padrao
	Private _cDflLocPad	:= CriaVar("B1_LOCPAD")

	// cliente optante pelo simples
	private _lOptSimples := .f.

	// tipo da nota
	private _cTipoNota := IIf(cModulo=="COM", "N", "B")

	// valida se o WMS esta ativo por cliente
	private _lWmsAtivo := .f.

	// Valita controle de lote ativo.
	Private _lLotAtivo := .F.

	// verifica se o lote eh obrigatorio na entrada da nota
	Private _lLotObrEnt := .f.
	private _lEditLote  := .t.

	// codido e item da programacao
	Private _cCodProg := ""
	Private _cIteProg := ""

	// valida o controle de uso de grupo de estoque ativo
	private _lUsoGrpEst := .f.

	// valida se usa arquivo complementar da nota fiscal
	private _lUsaArqComp := .f.
	private _lArqCompOk  := .f.

	// informacoes do arquivo complementar
	// ex estrutura _aInfArqComp
	// 1-Seq Item
	// 2-Cod Produto
	// 3-Desc Produto
	// 4-Lote
	// 5-Quant
	// 6-Vlr Unit
	// 7-Vlr Total
	// 8-Saldo da Quant
	private _aInfArqComp := {}

	// diretorio local padrao
	private _cDirLocPdr := U_FtGetFld("0")

	// atualiza codigo de barras/ean com XML de entrada
	private _lAtuCodBar := .t.

	// controle se aceita importar notas de exportacao/exterior
	private _lXmlVndExt := .f.

	// controle se a nota eh de exportacao/venda exterior
	private _lXmlNfExt := .f.

	// valida o controle de uso de segunda unidade de medida
	private _lUsoSegUM := .f.

	// valida o controle de uso de fator de conversao da segunda unidade de medida
	private _lUsoFatConv := .f.

	// formato de obtenção das informações do lote do produto
	private _cParamLot := ""

	// valida identificacao do produto
	private _cTpIdEtiq := ""

	// controle de validacao geral
	private _lVldGeral := .T.

	// cliente possui controle de número de série ativo
	Private _lSerieAtv := .F.

	// flag para identificar se o cliente utiliza etapa de pré-conferencia (sem documento fiscal)
	private _lPreConf := .F.
	private _cNumos := CriaVar("Z05_NUMOS", .F.)

	// tabela temporária para validações cliente Midea
	Private _cTabPc		:= GetNextAlias()
	Private _cTrBArqPC

	// Array que recebe os produtos novos
	Private _aPrdNovo := {}
	// Log produtos novos
	Private _cLogPrdNv := ""

	// campos do arquivo de trabalho
	aadd(_aCampos,{"A1_COD"     ,CriaVar("A1_COD",.F.)    })  ; NPCODCLI := Len(_aCampos)
	aadd(_aCampos,{"A1_LOJA"    ,CriaVar("A1_LOJA",.F.)   })  ; NPLOJCLI := Len(_aCampos)
	aadd(_aCampos,{"A1_NOME"    ,CriaVar("A1_NOME",.F.)   })  ; NPNOMCLI := Len(_aCampos)
	aadd(_aCampos,{"A1_SIGLA"   ,CriaVar("A1_SIGLA",.F.)  })  ; NPSIGLA  := Len(_aCampos)
	aadd(_aCampos,{"TR_ADIC"    ,CriaVar("F1_ZINFADI",.F.)})  ; NPADICNF := Len(_aCampos)
	aadd(_aCampos,{"TR_DOC"     ,CriaVar("F1_DOC",.F.)    })  ; NPNDOCNF := Len(_aCampos)
	aadd(_aCampos,{"TR_SERIE"   ,CriaVar("F1_SERIE",.F.)  })  ; NPSERINF := Len(_aCampos)
	aadd(_aCampos,{"F1_PLIQUI"  ,CriaVar("F1_PLIQUI",.F.) })  ; NPPLIQUI := Len(_aCampos)
	aadd(_aCampos,{"F1_PBRUTO"  ,CriaVar("F1_PBRUTO",.F.) })  ; NPPBRUTO := Len(_aCampos)
	aadd(_aCampos,{"F1_VOLUME1" ,CriaVar("F1_VOLUME1",.F.)})  ; NPVOLUM1 := Len(_aCampos)
	aadd(_aCampos,{"F1_CHVNFE"  ,CriaVar("F1_CHVNFE",.F.) })  ; NPCHVNFE := Len(_aCampos)
	aadd(_aCampos,{"F1_PROGRAM" ,CriaVar("F1_PROGRAM",.F.)})  ; NPPROGRA := Len(_aCampos)
	aadd(_aCampos,{"Z05_NUMOS"  ,CriaVar("Z05_NUMOS" ,.F.)})  ; NPNUMOS  := Len(_aCampos)

	_aGets := Array(Len(_aCampos))

	// realiza a leitura das coordenadas da tela
	oMainWnd:ReadClientCoords()
	_oDlgXML := MsDialog():New(oMainWnd:nTop,oMainWnd:nLeft,oMainWnd:nBottom,oMainWnd:nRight,"Geração Pré-NF Entrada XML",,,.F.,,,,,oMainWnd,.T.,,,.F.)
	_oDlgXML:lMaximized := .T.

	// cabecalho
	_oPnlTop := TPanel():New(000,000,,_oDlgXML,,.T.,.F.,,,020,020,,)
	_oPnlTop:Align := CONTROL_ALIGN_TOP

	// selecao do arquivo XML
	_oSayArqXML := TSay():New(007,005,{||"Arquivo XML:"},_oPnlTop,,,,,,.T.,,,040,30)
	// get com o local do arquivo XML
	_oGetFile := TGet():New(005,050,bSetGet(_cArquivo),_oPnlTop,230,10,"@!",,,,,,,.T.,,,{|| .F.})
	// botao para selecao do arquivo XML
	_oBtnFile := TButton():New(005,290, OemToAnsi("&Xml") ,_oPnlTop , {|| fGetFile(@_cArquivo, @_aCampos, @_aGets) }, 40,12,,,,.T.)
	// funcao para validar os dados do XML
	_oBtnVldXml := TButton():New(005,340, OemToAnsi("&Validar Dados") ,_oPnlTop,{||Eval(_bVldXml)},40,12,,,,.T.)

	// detalhes do cabecalho da Nota
	_oPnlCenter := TPanel():New(1,1,,_oDlgXML,,.T.,.F.,,,1,120,.T.,)
	_oPnlCenter:Align := CONTROL_ALIGN_TOP
	// dados do cliente/fornecedor
	_oSayCliFor := TSay():New(012,002,{|| "Cliente/Fornecedor: "},_oPnlCenter,,,,,,.T.,,,040,30)
	_aGets[NPCODCLI] := TGet():New(010,050,bSetGet(_aCampos[NPCODCLI][2]),_oPnlCenter,040,10,"@!",,,,,,,.T.,,,{|| .F.})
	_aGets[NPLOJCLI] := TGet():New(010,095,bSetGet(_aCampos[NPLOJCLI][2]),_oPnlCenter,030,10,"@!",,,,,,,.T.,,,{|| .F.})
	_aGets[NPNOMCLI] := TGet():New(010,130,bSetGet(_aCampos[NPNOMCLI][2]),_oPnlCenter,150,10,"@!",,,,,,,.T.,,,{|| .F.})
	// sigla
	_oSaySigla := TSay():New(012,290,{|| "Sigla:"},_oPnlCenter,,,,,,.T.,,,)
	_aGets[NPSIGLA ] := TGet():New(010,330,bSetGet(_aCampos[NPSIGLA ][2]),_oPnlCenter,030,10,"@!",,,,,,,.T.,,,{|| .F.})
	// numero/serie
	_oSayNumNf := TSay():New(027,002,{|| "Nota/Serie: "},_oPnlCenter,,,,,,.T.,,,040,30)
	_aGets[NPNDOCNF] := TGet():New(025,050,bSetGet(_aCampos[NPNDOCNF][2]),_oPnlCenter,040,10,"@!",,,,,,,.T.,,,{|| .F.})
	_aGets[NPSERINF] := TGet():New(025,095,bSetGet(_aCampos[NPSERINF][2]),_oPnlCenter,030,10,"@!",,,,,,,.T.,,,{|| .F.})
	//Programação
	_aGets[NPPROGRA] := TGet():New(025,130,bSetGet(_aCampos[NPPROGRA][2]),_oPnlCenter,040,10,"@!",,,,,,,.T.,,,{|| .F.},,,,,,,,,,,,,,"Programação",,,,)
	// Número da OS vinculada
	_aGets[NPNUMOS]    := TGet():New(025,210,bSetGet(_aCampos[NPNUMOS][2])   ,_oPnlCenter,040,10,"@!",,,,,,,.T.,,,{|| .F.},,,,,,,,,,,,,,"OS: ",,,,)
	// tipo do produto
	_oSayTipo := TSay():New(027,290,{|| "Tipo:"},_oPnlCenter,,,,,,.T.,,,)
	_oGetTipo := TGet():New(025,330,bSetGet(_cDflTipo),_oPnlCenter,030,10,"@!",{||Vazio().or.ExistCpo("SX5","02"+_cDflTipo)},,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"02","_cDflTipo",,)
	// dados adicionais
	_oSayAdic   := TSay():New(040,002,{|| "Adicionais: "},_oPnlCenter,,,,,,.T.,,,040,30)
	_aGets[nPADICNF] := TMultiget():Create(_oPnlCenter,{||_aCampos[nPADICNF][2]},040,050,230,040,,,,,,.T.,,,{|| .F. },,,)
	// local padrao (armazem)
	_oSayLocPad := TSay():New(040,290,{|| "Armazém:"},_oPnlCenter,,,,,,.T.,,,)
	_oGetLocPad := TGet():New(038,330,bSetGet(_cDflLocPad),_oPnlCenter,030,10,"@!",{|| Vazio().or.ExistCpo("Z12") },,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"Z12","_cDflLocPad",,)

	// peso liquido / peso bruto / volumes
	_oSayPesoLiq := TSay():New(087,002,{|| "Peso Liquido:"},_oPnlCenter,,,,,,.T.,,,)
	_aGets[NPPLIQUI ] := TGet():New(085,050,bSetGet(_aCampos[NPPLIQUI ][2]),_oPnlCenter,050,10,PesqPict("SF1","F1_PLIQUI"),,,,,,,.T.,,,{||.T.})
	_oSayPesoBru := TSay():New(087,110,{|| "Peso Bruto:"},_oPnlCenter,,,,,,.T.,,,)
	_aGets[NPPBRUTO ] := TGet():New(085,140,bSetGet(_aCampos[NPPBRUTO ][2]),_oPnlCenter,050,10,PesqPict("SF1","F1_PBRUTO"),,,,,,,.T.,,,{||.T.})
	_oSayPesoLiq := TSay():New(087,200,{|| "Volumes:"},_oPnlCenter,,,,,,.T.,,,)
	_aGets[NPVOLUM1 ] := TGet():New(085,230,bSetGet(_aCampos[NPVOLUM1 ][2]),_oPnlCenter,050,10,PesqPict("SF1","F1_VOLUME1"),,,,,,,.T.,,,{||.T.})

	// chave da NFe
	_oSayChvNfe := TSay():New(102,002,{|| "Chave NF-e:"},_oPnlCenter,,,,,,.T.,,,)
	_aGets[NPCHVNFE ] := TGet():New(100,050,bSetGet(_aCampos[NPCHVNFE ][2]),_oPnlCenter,230,10,"@!",,,,,,,.T.,,,{||.T.})

	// cria o arquivo de trabalho dos itens
	fCriaTrb(@_aCpoBrw,.t.)

	// panel antes do browse
	_oPnlItens := TPanel():New(000,000,,_oDlgXML,,.T.,.F.,,CLR_LIGHTGRAY,020,020,,)
	_oPnlItens:Align := CONTROL_ALIGN_TOP

	// botao para agrupar itens duplicador
	_oBtnItDup := TButton():New(005,010, "Agrupa Itens" ,_oPnlItens , {|| sfAgrItens() }, 050,12,,,,.T.)

	// botao para complementar os detalhes do produto
	_oBtnCompl := TButton():New(005,070, "Detalhes" ,_oPnlItens , {|| fComplProd() }, 050,12,,,,.T.)

	// monta o browse com os itens da nota
	_oBrwItens := MsSelect():New(_TRBSD1,"IT_SELEC",,_aCpoBrw,,cMarca,{1,1,1,1},,,,,;
	{{"Empty((_TRBSD1)->IT_OK)","DISABLE"},{"!(Empty((_TRBSD1)->IT_OK))","ENABLE"}})
	_oBrwItens:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	Activate MSDialog _oDlgXML On Init (_oDlgXML,BarraTools(_oDlgXML)) Centered

	// apaga tabela temporária
	If Valtype(_cNomArq) == "O"
		_cNomArq:Delete()
	EndIf
Return

// ** funcao para Gera pre-nota fiscal a partir do XML
Static Function fGeraNF(_aCampos,_cArquivo)

	Local _aCabAuto	  := {}
	Local _aIteAuto	  := {}
	Local _aLinha	  := {}
	Local _cNumDoc    := ""
	Local _cSerie     := ""
	Local _lRet       := .T.
	// posicao inicial do browse
	Local _aAreaTRB   := (_TRBSD1)->(GetArea())
	// nome do arquivo
	Local _cArqImport := ""
	// data emissao da nota
	local _cDtEmis    := ""
	// variável para instrução SQL de update
	local _cUpdate := ""

	Local _cBkp := ""  // caminho do arquivo de informações complementares para ser renomeado e movido para pasta backup

	// definicao padrao se a quantidade do produto devera ser informada manualmente
	local _lInfQtdMan := .t.

	// flag se tem um produto novo na importação da nota fiscal
	Local lProdNovo := .F.
	// variável que recebe a msg html para enviar e-mail de produtos novos
	Local _cHtml := ""
	// variavel controle de repetição
	Local _nItem := 0

	// numero e serie da NF
	_cNumDoc := _aCampos[NPNDOCNF][2]
	_cSerie  := _aCampos[NPSERINF][2]

	// valida a Programação da nota fiscal
	If (_cTipoNota=="B").and.(Empty(_aCampos[NPPROGRA][2]))
		Aviso("TWMSA006 -> fGeraNF","Programação da nota fiscal não informada ou inválida.",{"Fechar"})
		Return(.F.)
	EndIf

	// verifica peso bruto, liquido e volumes
	If (_aCampos[NPPLIQUI][2]==0).or.(_aCampos[NPPBRUTO][2]==0).or.(_aCampos[NPVOLUM1][2]==0)
		Aviso("TWMSA006 -> fGeraNF","É obrigatório informar o peso bruto, peso liquido e volume desta nota.",{"Fechar"})
		Return(.F.)
	EndIf

	// verifica se o peso bruto eh maior que o peso liquido
	If (_aCampos[NPPBRUTO][2] < _aCampos[NPPLIQUI][2])
		Aviso("TWMSA006 -> fGeraNF","O peso bruto não pode ser inferior ao peso liquido.",{"Fechar"})
		Return(.F.)
	EndIf

	// valida a chave da nota fiscal
	If (Empty(_aCampos[NPCHVNFE][2])).or.(Len(AllTrim(_aCampos[NPCHVNFE][2])) < TamSx3("F1_CHVNFE")[1])
		Aviso("TWMSA006 -> fGeraNF","Chave da nota fiscal não informada ou inválida.",{"Fechar"})
		Return(.F.)
	EndIf

	// verifica se ha divergencias na nota
	If (!_lCliForOk).or.(!_lItensOk)
		Aviso("TWMSA006 -> fGeraNF","Existem inconsistências nas informações da nota. Favor corrigir os dados para prosseguir com a importação.",{"Fechar"})
		Return(.F.)
	EndIf

	// valida duplicidade de itens por valor
	If (_cTipoNota=="B").and.( ! sfItensDupl() )
		Aviso("TWMSA006 -> fGeraNF","Nota fiscal com itens duplicados (código x valor unitário). Favor corrigir os dados para prosseguir com a importação.",{"Fechar"})
		Return(.F.)
	EndIf

	// verifica se foi utilizado os dados do arquivo complementar
	If (_cTipoNota=="B").and.(_lUsaArqComp).and.( ! _lArqCompOk )
		Aviso("TWMSA006 -> fGeraNF","O cliente "+AllTrim(_aCampos[NPNOMCLI][2])+" utiliza os dados do arquivo complementar, porém este arquivo não foi validado.",{"Fechar"})
		Return(.F.)
	EndIf

	// inconsistencia geral, nao permite importacao
	If (_cTipoNota=="B") .And. ( ! _lVldGeral )
		Aviso("TWMSA006 -> fGeraNF","Houve inconsistência na validação GERAL dos dados e a importação não será permitida.",{"Fechar"})
		Return(.F.)
	EndIf

	// INICIO DA TRANSACAO
	BEGIN TRANSACTION

		// funcao para incluir novos cliente/fornecedor
		If (_lNewClieFor)
			// funcao para cadastrar o cliente
			If (_cTipoNota == "B")
				If !(sfAddCliente(_aCampos))
					// rollback na transacao
					_lRet := .F.
					DisarmTransaction()
					Break
				EndIf
				// funcao para cadastrar o fornecedor
			ElseIf (_cTipoNota == "N")
				If !(sfAddFornece(_aCampos))
					// rollback na transacao
					_lRet := .F.
					DisarmTransaction()
					Break
				EndIf
			EndIf
		EndIf

		//Verifica se a nota fiscal já está digitada no sistema
		dbSelectArea("SF1")
		SF1->(dbSetOrder(1)) //1-F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO
		If SF1->(dbSeek( xFilial("SF1")+_cNumDoc+_cSerie+_aCampos[NPCODCLI][2]+_aCampos[NPLOJCLI][2]+_cTipoNota ))
			Aviso("Atenção","Nota Fiscal já está cadastrada no sistema!",{"Cancelar"})
			// rollback na transacao
			_lRet := .F.
			DisarmTransaction()
			Break
		EndIf

		// validação para a nova informação da NFE 3.0
		If (TYPE(_cBaseXML+"_INFNFE:_IDE:_DHEMI:TEXT") == "C") // 3.0
			_cDtEmis := &(_cBaseXML+"_INFNFE:_IDE:_DHEMI:TEXT")
			_cDtEmis := SUBSTR(_cDtEmis,1,10)
		ElseIf (TYPE(_cBaseXML+"_INFNFE:_IDE:_DEMI:TEXT") == "C") // 2.0
			_cDtEmis := &(_cBaseXML+"_INFNFE:_IDE:_DEMI:TEXT")
		Else
			Aviso("Atenção","Data de Emissão da NF inválida!",{"Cancelar"})
			// rollback na transacao
			_lRet := .F.
			DisarmTransaction()
			Break
		EndIf

		// dados do cabecalho da NF
		aadd(_aCabAuto,{"F1_TIPO"   , _cTipoNota                    })
		aadd(_aCabAuto,{"F1_FORMUL" , "N"                           })
		aadd(_aCabAuto,{"F1_DOC"    , _cNumDoc                      })
		aadd(_aCabAuto,{"F1_SERIE"  , _cSerie                       })
		aadd(_aCabAuto,{"F1_EMISSAO", StoD(StrTran(_cDtEmis,"-",""))})
		aadd(_aCabAuto,{"F1_FORNECE", _aCampos[NPCODCLI][2]         })
		aadd(_aCabAuto,{"F1_LOJA"   , _aCampos[NPLOJCLI][2]         })
		aadd(_aCabAuto,{"F1_ESPECIE", IIf(_lXmlNfExt, "DI", "SPED") })
		aadd(_aCabAuto,{"F1_PROGRAM", _cCodProg                     })

		(_TRBSD1)->(dbSelectArea(_TRBSD1))
		(_TRBSD1)->(dbGoTop())
		While (_TRBSD1)->(!Eof())
			// prepara vetor
			_aLinha := {}
			// alimenta os itens da NF
			aadd(_aLinha,{"D1_ITEM"		,(_TRBSD1)->D1_ITEM	 ,Nil})
			aadd(_aLinha,{"D1_COD"		,(_TRBSD1)->B1_COD	 ,Nil})
			aadd(_aLinha,{"D1_DESCRIC"	,(_TRBSD1)->B1_DESC	 ,Nil})
			aadd(_aLinha,{"D1_UM"       ,(_TRBSD1)->B1_UM      ,Nil})
			aadd(_aLinha,{"D1_SEGUM"    ,(_TRBSD1)->B1_SEGUM   ,Nil})
			aadd(_aLinha,{"D1_QUANT"	,(_TRBSD1)->D1_QUANT	 ,Nil})
			aadd(_aLinha,{"D1_VUNIT"	,(_TRBSD1)->D1_VUNIT	 ,Nil})
			aadd(_aLinha,{"D1_TOTAL"	,(_TRBSD1)->D1_TOTAL	 ,Nil})
			aadd(_aLinha,{"D1_PROGRAM"	,_cCodProg       	 ,Nil})
			aadd(_aLinha,{"D1_ITEPROG"	,_cIteProg      	 ,Nil})
			aadd(_aLinha,{"D1_LOTECTL"	,(_TRBSD1)->D1_LOTECTL ,Nil})
			aadd(_aLinha,{"D1_LOCAL"	,_cDflLocPad         ,Nil})

			// funcionalidade para cadastrar/atualizar o produto
			If (AllTrim((_TRBSD1)->IT_STATUS)=="NOVO") .OR. ((AllTrim((_TRBSD1)->IT_STATUS)=="CADASTRADO") .AND. ((_TRBSD1)->IT_ATUALI == "S"))
				// marca flag se existe ao menos um produto novo
				if (!lProdNovo) .AND. ( AllTrim((_TRBSD1)->IT_STATUS) == "NOVO")
					lProdNovo := .T.
				EndIf

				// funcao para cadastrar/atualizar o produto
				If !( sfAddProd(( AllTrim((_TRBSD1)->IT_STATUS) == "NOVO"), _aCampos ))
					// rollback na transacao
					_lRet := .F.
					DisarmTransaction()
					Break
				EndIf
			EndIf

			// atualiza vetor da rotina automatica
			aadd(_aIteAuto,_aLinha)

			// proximo item
			(_TRBSD1)->(dbSkip())
		EndDo

		_aCabAuto := FWVetByDic(_aCabAuto,'SF1',.F.)
		_aIteAuto := FWVetByDic(_aIteAuto,'SD1',.T.)

		// restaura posicao inicial do TRB
		RestArea(_aAreaTRB)

		// rotina automatica de inclusao de pre-nota
		lMsErroAuto := .F.
		dbSelectArea("SD1")
		dbSelectArea("SF1")

		MsExecAuto({|x,y,z|Mata140(x,y,z)},_aCabAuto,_aIteAuto,3)

		// operacao se deu erro
		If ( lMsErroAuto )
			// rollback na transacao
			_lRet := .F.
			DisarmTransaction()
			MostraErro()
			Break
		EndIf

		// gravo os valores depois de gerar a nota, pois na rotina padrao nao grava esses campos
		dbSelectArea("SF1")

		SF1->( dbSetOrder(1) )//F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
		If SF1->( dbSeek(xFilial("SF1") + _cNumDoc + _cSerie + _aCampos[NPCODCLI][2] + _aCampos[NPLOJCLI][2] + _cTipoNota))
			RecLock("SF1",.F.)
			SF1->F1_PLIQUI	:= _aCampos[NPPLIQUI][2]
			SF1->F1_PBRUTO	:= _aCampos[NPPBRUTO][2]
			SF1->F1_VOLUME1	:= _aCampos[NPVOLUM1][2]
			SF1->F1_CHVNFE	:= _aCampos[NPCHVNFE][2]
			SF1->F1_ZINFADI := _aCampos[NPADICNF][2]
			If (_lPreConf)
				SF1->F1_ZOBS    := "OS:" + _aCampos[NPNUMOS][2]
			Endif
			SF1->(MSUnlock())
		EndIf

		// Vincula Shipment ID informado nas observações adicionais da nota fiscal com a remessa de etiquetas
		If ( ExistBlock("TWMA047P") ) .AND. ( SF1->F1_FORNECE == Substr(GetNewPar("TC_SRBTI","00031601"),1,TamSX3("A1_COD")[1]) )
			// Verifica se a nota fiscal tem produtos com barcode ativo
			If ( sfTemBarcode() )
				// se não conseguiu vincular
				If !(ExecBlock("TWMA047P",.F.,.F.,_aCampos[NPADICNF][2]))
					If (lProdNovo)
						// se não conseguiu vincular e tem produto novo na NF, o arquivo de remessa foi rejeitado porque primeiro precis
						MsgAlert( "O processo irá continuar para importar a nota fiscal e cadastrar os produtos novos. Você será solicitado a vincular a remessa de etiquetas na classificação da nota fiscal",;
						"TWMSA047P - Erro ao vincular NF x Remessa de etiquetas")
					Else
						DisarmTransaction()
						Return ( .F. )
					Endif
				EndIf
			EndIf
		EndIf

		// grava a TES a Classificar depois, pois na rotina padrao nao grava esse campo
		(_TRBSD1)->(dbSelectArea(_TRBSD1))
		(_TRBSD1)->(dbGoTop())
		While (_TRBSD1)->(!Eof())
			// pesquisa o item no SD1
			dbSelectArea("SD1")
			SD1->(dbSetOrder(1)) //1-D1_FILIAL, D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_COD, D1_ITEM
			If SD1->(dbSeek( xFilial("SD1")+SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)+(_TRBSD1)->(B1_COD+D1_ITEM) ))
				RecLock("SD1",.F.)
				SD1->D1_TESACLA := (_TRBSD1)->D1_TESACLA
				SD1->(MsUnLock())
			EndIf
			// proximo item
			(_TRBSD1)->(dbSkip())
		EndDo
		// FIM DA TRANSACAO

	END TRANSACTION

	// Envia log dos produtos novos, caso cadastrados, para o e-mail ti@tecadi.com.br
	If(!Empty(_aPrdNovo))
		_cHtml := ' <html>'
		_cHtml += ' <head>'
		_cHtml += ' 	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />'
		_cHtml += ' </head>'
		_cHtml += ' <body>'
		_cHtml += ' <style type="text/css">'
		_cHtml += '     table {'
		_cHtml += '         width: 50%;'
		_cHtml += '         border-radius: 15px;'
		_cHtml += '         font-family: Verdana, Geneva, Tahoma, sans-serif;'
		_cHtml += '         font-size: 14px;}'
		_cHtml += '     thead {'
		_cHtml += '         height: 50%;'
		_cHtml += '         text-align: left;'
		_cHtml += '         vertical-align: center;'
		_cHtml += '         background-color: #4CAF50;'
		_cHtml += '         color: white;}'
		_cHtml += '     thead, td {'
		_cHtml += '         padding: 10px;'
		_cHtml += '         border-bottom: 1px solid #ddd;}'
		_cHtml += '     tbody tr:hover {background-color: #f5f5f5;}'
		_cHtml += '     tr:nth-child(even) {background-color: #f2f2f2;}'
		_cHtml += ' </style>'
		_cHtml += '     <div style="overflow-x:auto;">'
		_cHtml += '         <table>'
		_cHtml += '             <thead>'
		_cHtml += '                 <td>Cliente: ' + SF1->F1_FORNECE + ' / ' + SF1->F1_LOJA + '</td>'
		_cHtml += '             </thead>'
		_cHtml += '             <tbody>'
		For _nItem := 1 to Len(_aPrdNovo)
			_cHtml += '                 <tr>'
			_cHtml += '                     <td>' + _aPrdNovo[_nItem] + '</td>'
			_cHtml += '                 </tr>'
		Next
		_cHtml += '             </tbody>'
		_cHtml += '         </table>'
		_cHtml += '     </div>'
		_cHtml += ' </body>'
		_cHtml += ' </html>'

		MemoWrit("c:\query\TWMSA006_Mail_PrdNovo.html", _cHtml)

		U_FtMail(_cHtml,"[WMS - Tecadi] Novos produtos cadastrados","cadastro@tecadi.com.br")
	Endif

	// TODO - em tese, o próximo update deveria ser dentro da transação anterior, para em caso de erro, desfazer tudo.
	// porém segundo o Gustavo, não encontrava a tabela e/ou variáveis. *** Revisar ***

	// se o objeto da tabela temporária do EDI do cliente Midea estiver estanciada, então deve-se popular os campos da Z07 e Z16
	If (ValType(_cTrBArqPc) == "O") .AND. (_lRet)  .AND. (_aCampos[NPCODCLI][2] == "000603")
		MsUnlockAll()

		BEGIN TRANSACTION

			_cUpdate := " Update Z07 set Z07.Z07_NUMSEQ = SD1.D1_NUMSEQ,Z07.Z07_DTSERI = TMP.Z07DTSERI "
			_cUpdate += " FROM "+RetSQLName("SD1")+" SD1 "
			_cUpdate += " 	inner join "+RetSQLName("Z07")+" Z07 "
			_cUpdate += " 	on Z07.D_E_L_E_T_ = '' "
			_cUpdate += " 	and Z07_FILIAL = D1_FILIAL "
			_cUpdate += " 	and Z07_NUMOS = '"+_cNumOs+"' "
			_cUpdate += " 	and Z07_PRODUT = D1_COD "

			_cUpdate += " 	inner join "+_cTrBArqPc:GetRealName()+" TMP "
			_cUpdate += " 	on TMP.D_E_L_E_T_ = '' "
			_cUpdate += " 	and Z07FILIAL = Z07_FILIAL "
			_cUpdate += " 	and Z07PRODUT = Z07_PRODUT "
			_cUpdate += " 	and Z07NUMSER = Z07_NUMSER "

			_cUpdate += " where SD1.D_E_L_E_T_ = '' "
			_cUpdate += " and D1_FILIAL = '"+xFilial("SD1")+"' "
			_cUpdate += " and D1_DOC = '"+_cNumDoc+"' "
			_cUpdate += " and D1_SERIE = '"+_cSerie+"' "
			_cUpdate += " and D1_FORNECE = '"+_aCampos[NPCODCLI][2]+"' "
			_cUpdate += " and D1_LOJA = '"+_aCampos[NPLOJCLI][2]+"' "

			// Tenta executar o SQL na tabela Z07

			//se deu erro
			If (TcSQLExec(_cUpdate) <> 0)
				// grava logs do sql para debug
				MemoWrit("c:\query\TWMSA006_fGeraNf_UpdateZ07.txt", _cUpdate)
				MemoWrit("c:\query\TWMSA006_fGeraNf_UpdateZ07_SQL.txt", TcSQLError() )

				MsgStop("Processo abortado: erro crítico ao realizar complemento da tabela Z07. Contate TI imediatamente!" ,"Erro TWMSA006 - fGeraNf - Update Z07")
				MsgStop( TcSQLError() )

				_lRet := .F.
				DisarmTransaction()
				Break
			EndIf

			// TODO - validação de diferentes datas de numero de serie no mesmo pallet
			_cUpdate := " Update Z16 set Z16.Z16_NUMSEQ = SD1.D1_NUMSEQ,Z16.Z16_DTSERI = TMP.Z07DTSERI "
			_cUpdate += " FROM "+RetSQLName("SD1")+" SD1 "
			_cUpdate += " 	inner join "+RetSQLName("Z07")+" Z07 "
			_cUpdate += " 	on Z07.D_E_L_E_T_ = '' "
			_cUpdate += " 	and Z07_FILIAL = D1_FILIAL "
			_cUpdate += " 	and Z07_NUMOS = '" + _cNumOs + "' "
			_cUpdate += " 	and Z07_PRODUT = D1_COD "
			_cUpdate += " 	inner join "+RetSQLName("Z16")+" Z16 "
			_cUpdate += " 	on Z16.D_E_L_E_T_ = '' "
			_cUpdate += " 	and Z16_FILIAL = Z07_FILIAL "
			_cUpdate += " 	and Z16_CODPRO = Z07_PRODUT "
			_cUpdate += " 	and Z16_NUMSER = Z07_NUMSER "
			_cUpdate += " 	and Z16_ETQPRD = Z07_ETQPRD "
			_cUpdate += " 	and Z16_ETQVOL = Z07_ETQVOL "
			_cUpdate += " 	inner join " + _cTrBArqPc:GetRealName() + " TMP "
			_cUpdate += " 	on TMP.D_E_L_E_T_ = '' "
			_cUpdate += " 	and Z07FILIAL = Z07_FILIAL "
			_cUpdate += " 	and Z07PRODUT = Z07_PRODUT "
			_cUpdate += " 	and Z07NUMSER = Z07_NUMSER "
			_cUpdate += " where SD1.D_E_L_E_T_ = '' "
			_cUpdate += " and D1_FILIAL  = '" + xFilial("SD1") + "' "
			_cUpdate += " and D1_DOC     = '" + _cNumDoc + "' "
			_cUpdate += " and D1_SERIE   = '" + _cSerie  + "' "
			_cUpdate += " and D1_FORNECE = '" + _aCampos[NPCODCLI][2] + "' "
			_cUpdate += " and D1_LOJA    = '" + _aCampos[NPLOJCLI][2] + "' "
			_cUpdate += " and D1_TIPO    = 'B' "

			//se deu erro
			If (TcSQLExec(_cUpdate) <> 0)
				// grava logs do sql para debug
				MemoWrit("c:\query\TWMSA006_fGeraNf_UpdateZ16.txt", _cUpdate)
				MemoWrit("c:\query\TWMSA006_fGeraNf_UpdateZ16_SQL.txt", TcSQLError() )

				MsgStop("Processo abortado: erro crítico ao realizar complemento da tabela Z16. Contate TI imediatamente!" ,"Erro TWMSA006 - fGeraNf - Update Z16")
				MsgStop( TcSQLError() )

				_lRet := .F.
				DisarmTransaction()
				Break
			EndIf

		END TRANSACTION

		// move o arquivo complementar para pasta backup
		_cBkp := StrTran(_cArquivo, "\nf_transferencia\",  "\nf_transferencia\bkp\")  // altera caminho para pasta bkp
		_cBkp := StrTran(_cBkp , ".txt", "_" + DtoS( Date() ) + "_" + StrTran( Time(), ":" ) + ".txt")
		FRename( _cArquivo, _cBkp )

		// apaga a tabela temporária
		_cTrBArqPc:Delete()

	EndIf
	// copia o arquivo para pasta importados
	// define o nome do arquivo na seguinte estrutura:
	// tipo: CLI / FOR
	// codigo do cliente/fornecedor
	// loja do cliente/fornecedor
	// numero da nota
	// serie da nota
	// ex: CLI_000001_02_NF_0000000123_2.xml
	If (_lRet)
		_cArqImport :=	"CLI_"+;
		_aCampos[NPCODCLI][2]+"_"+;
		_aCampos[NPLOJCLI][2]+"_"+;
		"NF_"+_cNumDoc+"_"+;
		AllTrim(_cSerie)+".xml"

		// realiza a copia do arquivo
		fRename(_cArquivo,"\tecadi\xml\importados\"+_cArqImport)

		// fecha a tela
		_oDlgXML:End()
		Aviso("Sucesso!","Arquivo XML importado com sucesso!",{"Ok"})
	EndIf

Return (_lRet)

// ** funcao que monta a barra de ferramentas no topo do browse
Static Function BarraTools(mvDlgTela)
	local _oBar   := TBar():New(mvDlgTela, 040, 040, .T.)
	local _oBtOk  := TBtnBmp():NewBar("OK"    ,,,,,{|| Eval(_bConfirma)},.F.,_oBar,.F.,,"Confirmar - <Ctrl-O>",.F.,,,,"Confirmar")
	local _oBtCan := TBtnBmp():NewBar("CANCEL",,,,,{|| Eval(_bCancel)},.F.,_oBar,.F.,,"Cancelar - <Ctrl-X>" ,.F.,,,,"Cancelar")

	_oBar:bRClicked := {|| AlwaysTrue()}

	// teclas de atalho
	SetKey(15,{|| Inkey(.5), bKey := SetKey(15),Eval(_bConfirma),Setkey(15,bKey)}) //K_CTRL_O
	SetKey(24,_oBtCan:bAction) //K_CTRL_X

Return

// ** funcao para criar o arquivo de trabalho dos itens da nota
Static Function fCriaTrb(_aCpoBrw,mvNew)
	Local _aStruc	:= {}
	Local _aTamSx3	:= {}

	// arquivo novo
	If (mvNew)

		// campos especificos para controle
		_aTamSx3 := { 2,0}				; aAdd(_aStruc,{"IT_SELEC" , "C", _aTamSx3[1] , _aTamSx3[2]})
		_aTamSx3 := { 2,0}				; aAdd(_aStruc,{"IT_OK"    , "C", _aTamSx3[1] , _aTamSx3[2]})
		_aTamSx3 := {10,0}				; aAdd(_aStruc,{"IT_STATUS", "C", _aTamSx3[1] , _aTamSx3[2]})
		_aTamSx3 := {60,0}				; aAdd(_aStruc,{"IT_LOG"   , "C", _aTamSx3[1] , _aTamSx3[2]})
		_aTamSx3 := { 1,0}				; aAdd(_aStruc,{"IT_ATUALI", "C", _aTamSx3[1] , _aTamSx3[2]})
		_aTamSx3 := TamSX3("D1_ITEM")	; aAdd(_aStruc,{"D1_ITEM"  , "C", _aTamSx3[1] , _aTamSx3[2]})

		// campos obrigatorios do SB1
		aAdd(_aStruc,{"B1_GRUPO","C",4,0})
		aAdd(_aStruc,{"B1_CODCLI","C",26,0})
		aAdd(_aStruc,{"B1_COD","C",30,0})
		aAdd(_aStruc,{"B1_DESC","C",120,0})
		aAdd(_aStruc,{"B1_TIPO","C",2,0})
		aAdd(_aStruc,{"B1_UM","C",2,0})
		aAdd(_aStruc,{"B1_SEGUM","C",2,0})
		aAdd(_aStruc,{"B1_CONV","N",11,4})
		aAdd(_aStruc,{"B1_TIPCONV","C",1,0})
		aAdd(_aStruc,{"B1_LOCPAD","C",2,0})
		aAdd(_aStruc,{"B1_LOCALIZ","C",1,0})
		aAdd(_aStruc,{"B1_ORIGEM","C",1,0})
		aAdd(_aStruc,{"B1_POSIPI","C",10,0})
		aAdd(_aStruc,{"B1_ZGRPEST","C",4,0})
		aAdd(_aStruc,{"B1_CODBAR","C",30,0})
		aAdd(_aStruc,{"B1_ZTPBAR","C",1,0})
		aAdd(_aStruc,{"B1_ZNUMSER","C",1,0})

		aAdd(_aCpoBrw,{"B1_CODCLI",,"Cod Prd Clie","@!"})
		aAdd(_aCpoBrw,{"B1_DESC",,"Descricao","@!"})
		aAdd(_aCpoBrw,{"B1_UM",,"Unidade","@!"})
		aAdd(_aCpoBrw,{"B1_LOCPAD",,"Armazem Pad.","@!"})

		// campos do item da NF
		aAdd(_aCpoBrw,{"D1_QUANT",,"Quantidade",PesqPict("SD1","D1_QUANT")})
		_aTamSx3 := TamSX3("D1_QUANT")	; aAdd(_aStruc,{"D1_QUANT"  , "N", _aTamSx3[1] , _aTamSx3[2]})
		aAdd(_aCpoBrw,{"D1_VUNIT",,"Vlr.Unit.",PesqPict("SD1","D1_VUNIT")})
		_aTamSx3 := TamSX3("D1_VUNIT")	; aAdd(_aStruc,{"D1_VUNIT"  , "N", _aTamSx3[1] , _aTamSx3[2]})
		aAdd(_aCpoBrw,{"D1_TOTAL",,"Vlr.Total",PesqPict("SD1","D1_TOTAL")})
		_aTamSx3 := TamSX3("D1_TOTAL")	; aAdd(_aStruc,{"D1_TOTAL"  , "N", _aTamSx3[1] , _aTamSx3[2]})
		// campo descricao detalhada
		_aTamSx3 := TamSX3("B1_ZINFADI"); aAdd(_aStruc,{"B1_ZINFADI", "C", _aTamSx3[1] , _aTamSx3[2]})
		// campo codigo da TES
		_aTamSx3 := TamSX3("D1_TESACLA"); aAdd(_aStruc,{"D1_TESACLA", "C", _aTamSx3[1] , _aTamSx3[2]})
		// campo lote
		_aTamSx3 := TamSX3("D1_LOTECTL"); aAdd(_aStruc,{"D1_LOTECTL", "C", _aTamSx3[1] , _aTamSx3[2]})
		aAdd(_aCpoBrw,{"D1_LOTECTL",,"Lote",PesqPict("SD1","D1_LOTECTL")})
		// local
		_aTamSx3 := TamSX3("D1_LOCAL"); aAdd(_aStruc,{"D1_LOCAL", "C", _aTamSx3[1] , _aTamSx3[2]})
		aAdd(_aCpoBrw,{"D1_LOCAL",,"Armazem",PesqPict("SD1","D1_LOCAL")})

		// coloca o log na ultima posicao
		aAdd(_aCpoBrw,{"IT_LOG",,"Log","@!"})

		If Select(_TRBSD1) <> 0
			(_TRBSD1)->(dbSelectArea(_TRBSD1))
			(_TRBSD1)->(dbCloseArea())
		EndiF
		// cria o TRB
		_cNomArq := FWTemporaryTable():New( _TRBSD1 )
		_cNomArq:SetFields( _aStruc )
		_cNomArq:Create()

	EndIf

	// limpa o conteudo do TRB
	(_TRBSD1)->(dbSelectArea(_TRBSD1))
	(_TRBSD1)->(__dbZap())

Return

// ** funcao que valida Arquivo XML selecionado, Caso valide o arquivo, apresenta informações de cabecalho do xml para conferencia
Static Function fValXML(_cArquivo, _aCampos, _aGets)

	Local cError  := ""
	Local cWarning:= ""
	Local _cAdicionais
	Local _cCnpj
	Local _cNome
	Local _cNumDoc
	Local _cSerie

	// chave da NFe para consulta do status no SEFAZ
	local _cChaveNFe := ""
	// ID da empresa
	local _cIdEnt := ""

	// controle se eh cliente/fornecedor novo
	_lNewClieFor := .f.

	// optante pelo simples
	_lOptSimples := .f.

	// desabilita uso do arquivo complementar
	_lUsaArqComp := .f.

	// verifica se foi selecionado algum arquivo
	If (Empty(_cArquivo))
		Aviso("TWMSA006 -> fValXML","É obrigatório selecionar um arquivo.",{"Fechar"})
		Return(.f.)
	EndIf

	// abertura do arquivo XML e estrutura do objeto
	_oXML := XmlParserFile(_cArquivo, "_", @cError, @cWarning )

	// verifica erros no XML
	If ValType(_oXML) != "O"
		MsgStop("Falha ao gerar Objeto XML : "+cError+" / "+cWarning)
		_oXML := Nil
		Return(.f.)
	Endif

	// validacao completa do arquivo
	_lCliForOk := .t.
	_lItensOk := .t.

	// monta a base da estrutura do XML de acordo com a versao
	// versao 1.10
	If (Type("_oXML:_NFEPROC:_NFE")=="O")
		_cBaseXML := "_oXML:_NFEPROC:_NFE:"
		// versao 2.00
	ElseIf (Type("_oXML:_NFE")=="O")
		_cBaseXML := "_oXML:_NFE:"
		// erro
	Else
		MsgStop("ATENÇÃO: Erro na estrutura do arquivo XML.")
		Return(.f.)
	EndIf

	// chave da NFe para consulta do status no SEFAZ
	If (Type("_oXML:_NFEPROC:_PROTNFE:_INFPROT:_CHNFE:TEXT")=="C")
		_cChaveNFe := _oXML:_NFEPROC:_PROTNFE:_INFPROT:_CHNFE:TEXT
		// se nao encontrou no campo especifico, tenta em outro
	ElseIf (Type("_oXML:_NFE:_INFNFE:_ID:TEXT")=="C")
		_cChaveNFe := SubStr(_oXML:_NFE:_INFNFE:_ID:TEXT,4)
	EndIf

	// parametro que habilita a consulta da nota fiscal no SEFAZ
	If SuperGetMv("TC_CONSNFE",.f.,.t.)
		// nao encontrou a chave da NFe
		If (Empty(_cChaveNFe))
			If (Aviso("TWMSA006 -> fValXML","Não foi possível encontrar a chave da nota fiscal. Deseja continuar a importação sem verificar a nota?",{"Continuar","Cancelar"})==2)
				Return(.f.)
			EndIf

			// verifica o status da nota no SEFAZ
		ElseIf (!Empty(_cChaveNFe))
			// pesquisa o ID da empresa
			_cIdEnt := RetIdEnti()

			// se nao encontrou o ID da Empresa
			If (Empty(_cIdEnt))
				Aviso("TWMSA006 -> fValXML","Erro do retorno do ID da Empresa.",{"Abortar"})
				Return(.f.)
			EndIf
			// consulta o status no SEFAZ
			If (!ConsNFeChave(_cChaveNFe,_cIdEnt))
				Return(.f.)
			EndIf
		EndIf
	Else
		Aviso("TWMSA006 -> fValXML","Atenção!!! A consulta da nota fiscal eletrônica está desabilitada. Favor consultar o documento através do site da SEFAZ.",{"Ok"})
	EndIf

	// atualiza o get com a chave da NF-e
	_aCampos[NPCHVNFE][2] := _cChaveNFe

	// retorno do CNPJ
	_cCnpj	:= &(_cBaseXML+"_INFNFE:_EMIT:_CNPJ:TEXT")

	// nome do cliente/fornecedor
	_cNome	:= &(_cBaseXML+"_INFNFE:_EMIT:_XNOME:TEXT")

	// optante pelo simples
	_lOptSimples := (&(_cBaseXML+"_INFNFE:_EMIT:_CRT:TEXT")=="1")

	// prepara e padrozina o numero e serie da nota
	_cNumDoc := Padl(&(_cBaseXML+"_INFNFE:_IDE:_NNF:TEXT"),TamSx3("F1_DOC")[1],"0")
	_cSerie  := Padr(AllTrim(&(_cBaseXML+"_INFNFE:_IDE:_SERIE:TEXT")),TamSx3("F1_SERIE")[1])
	_aCampos[NPNDOCNF][2] := _cNumDoc
	_aCampos[NPSERINF][2] := _cSerie

	// dados adicionais
	// verifica se tem informacoes adicionais
	If (Type(_cBaseXML+"_INFNFE:_INFADIC")<>"U")
		oAdic := XmlChildEx(&(_cBaseXML+"_INFNFE:_INFADIC"),"_INFCPL")
		if Type("oAdic") <> 'O'
			oAdic := XmlChildEx(&(_cBaseXML+"_INFNFE:_INFADIC"),"_INFADFISCO")
		Endif
		if Type("oAdic") == 'O'
			_cAdicionais := oAdic:TEXT
			_aCampos[NPADICNF][2] := AllTrim(_cAdicionais)
		Endif
	EndIf

	// peso liquido
	If (Type(_cBaseXML+"_INFNFE:_TRANSP:_VOL:_PESOL")<>"U")
		_aCampos[NPPLIQUI][2] := Val(&(_cBaseXML+"_INFNFE:_TRANSP:_VOL:_PESOL:TEXT"))
	EndIf
	// peso bruto
	If (Type(_cBaseXML+"_INFNFE:_TRANSP:_VOL:_PESOB")<>"U")
		_aCampos[NPPBRUTO][2] := Val(&(_cBaseXML+"_INFNFE:_TRANSP:_VOL:_PESOB:TEXT"))
	EndIF
	// volumes
	If (Type(_cBaseXML+"_INFNFE:_TRANSP:_VOL:_QVOL")<>"U")
		_aCampos[NPVOLUM1][2] := Val(&(_cBaseXML+"_INFNFE:_TRANSP:_VOL:_QVOL:TEXT"))
	EndIf

	// valida os dados do cliente
	If (_cTipoNota == "B")
		If ! (sfVldCliente(@_aCampos, @_aGets, _cCnpj, _cNome))
			_lCliForOk := .F.
		EndIf
		// valida os dados do fornecedor
	ElseIf (_cTipoNota == "N")
		If ! (sfVldFornece(@_aCampos, @_aGets, _cCnpj, _cNome))
			_lCliForOk := .F.
		EndIf
	EndIf

	// verifica se o destinatario da nota esta correto
	If ( ! sfVldDest() )
		Return(.f.)
	EndIf

	// se for nota de exportacao, altera a serie para DI
	If (_lXmlNfExt)
		_cSerie               := Padr("DI", TamSx3("F1_SERIE")[1])
		_aCampos[NPSERINF][2] := _cSerie
	EndIf

	// valida uso do arquivo complementar
	If (_cTipoNota == "B").and.(_lUsaArqComp)

		// executa funcao para carregar e validar o arquivo complementar
		_lArqCompOk := sfArqCompl(_aCampos)

	EndIf

	// valida os itens da nota
	If ( ! sfVldItens(_aCampos) )
		_lItensOk := .F.
	EndIf

	// posiciona no 1o Item
	(_TRBSD1)->(dbSelectArea(_TRBSD1))
	(_TRBSD1)->(dbGoTop())

Return(.t.)

// ** funcao que valida os dados do cliente
Static Function sfVldCliente(_aCampos,_aGets,mvCnpj,mvNome)
	Local _nGets
	Local _lRet     := .t.
	Local _aRet     := {}
	Local _cContrat := ""

	If Empty(mvCnpj)
		Aviso("Inconsistência","Não foi possível localizar o CNPJ do cliente no arquivo XML! (_NFEPROC:_NFE:_INFNFE:_EMIT:_CNPJ:TEXT) ",{"Cancelar"})
		Return(.f.)
	Else
		// pesquisa o cliente
		dbSelectArea("SA1")
		SA1->(dbSetOrder(3)) //3-A1_FILIAL, A1_CGC
		If SA1->(dbSeek(xFilial("SA1") + mvCnpj ))

			// atualiza os campos
			_aCampos[NPCODCLI][2] := SA1->A1_COD
			_aCampos[NPLOJCLI][2] := SA1->A1_LOJA
			_aCampos[NPNOMCLI][2] := SA1->A1_NOME
			_aCampos[NPSIGLA ][2] := SA1->A1_SIGLA

			// se for nota fiscal de remessa de armazenagem
			If (_cTipoNota == "B")
				// abre a tela com a lista de programacoes em aberta para o cliente
				// ex: retorno
				// 1-.T. / .F. - Validacao
				// 2-Codigo da Programacao
				// 3-Item da Programacao
				_aRet     := U_FtLstPrg(SA1->A1_COD,SA1->A1_LOJA)
				_lRet     := _aRet[1]
				_cCodProg := _aRet[2]
				_cIteProg := _aRet[3]

				If (_lRet)
					// valida se a programacao esta encerrada
					dbSelectArea("SZ1")
					SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
					If (SZ1->(dbSeek( xFilial("SZ1")+ _cCodProg )))
						If ( ! Empty(SZ1->Z1_DTFINFA))
							Aviso("Tecadi: TWMSA006","A programação " + _cCodProg + " encontra-se encerrada." + CRLF + "Contate o setor de Faturamento.",{"OK"})
							Return(.F.)
						EndIf
					Else
						Aviso("Tecadi: TWMSA006","Programação " + _cCodProg + " não encontrada." + CRLF + "Contate o setor de Faturamento.",{"OK"})
						Return(.F.)
					EndIf

					// numero do contrato do cliente
					_cContrat := SZ1->Z1_CONTRT

					// valida se o contrato esta ativo
					dbSelectArea("AAM")
					AAM->(DbSetOrder(1)) // 1-AAM_FILIAL, AAM_CONTRT
					If (AAM->( DbSeek( xFilial("AAM") + _cContrat ) ) )
						// campo status 1-Ativo
						If (AAM->AAM_STATUS <> "1")
							Aviso("Tecadi: TWMSA006","Contrato " + _cContrat + " não esta ativo." + CRLF +  "Contate o setor de Faturamento.",{"OK"})
							Return(.F.)
						EndIf
					Else
						Aviso("Tecadi: TWMSA006","Contrato " + _cContrat + " não encontrado." + CRLF +  "Contate o setor de Faturamento.",{"OK"})
						Return(.F.)
					EndIf

					// atualiza codigo da programacao
					_aCampos[NPPROGRA][2] := _cCodProg

					// verifica se o WMS esta ativo
					_lWmsAtivo    := U_FtWmsParam("WMS_ATIVO_POR_CLIENTE"                             , "L", .F. , .F., Nil, SA1->A1_COD, SA1->A1_LOJA, _cContrat, Nil)
					// define o armazem padrao do cliente
					_cDflLocPad   := U_FtWmsParam("WMS_ARMAZEM_POR_CLIENTE"                           , "C", "A1", .F., Nil, SA1->A1_COD, SA1->A1_LOJA, _cContrat, Nil)
					// verifica se o controle de lote esta ativo
					_lLotAtivo    := U_FtWmsParam("WMS_CONTROLE_POR_LOTE"                             , "L", .F. , .F., Nil, SA1->A1_COD, SA1->A1_LOJA, _cContrat, Nil)
					// verifica se o lote eh obrigatorio na entrada da nota
					_lLotObrEnt   := U_FtWmsParam("WMS_LOTE_OBRIGATORIO_ENTRADA"                      , "L", .F. , .F., Nil, SA1->A1_COD, SA1->A1_LOJA, _cContrat, Nil)
					// controle de uso de grupo de estoque ativo
					_lUsoGrpEst   := U_FtWmsParam("WMS_USA_GRUPO_ESTOQUE"                             , "L", .f. , .f., Nil, SA1->A1_COD, SA1->A1_LOJA, _cContrat, Nil)
					// força a utilização de arquivo com dados complementares (geralmente lote)
					_lUsaArqComp  := U_FtWmsParam("WMS_NF_ENT_USA_ARQ_DADOS_COMPL"                    , "L", .F. , .F., Nil, SA1->A1_COD, SA1->A1_LOJA, _cContrat, Nil)
					// definicao padrao se deve atualizar o codigo de barras/ean pela informacao do XML de entrada
					_lAtuCodBar   := U_FtWmsParam("WMS_PRODUTO_EAN_XML_ENTRADA"                       , "L", .T. , .F., Nil, SA1->A1_COD, SA1->A1_LOJA, _cContrat, Nil)
					// controle se aceita importar notas de exportacao/exterior
					_lXmlVndExt   := U_FtWmsParam("WMS_IMPORTA_VENDA_EXTERIOR_XML_ENTRADA"            , "L", .F. , .F., Nil, SA1->A1_COD, SA1->A1_LOJA, _cContrat, Nil)
					// valida o controle de uso de segunda unidade de medida
					_lUsoSegUM    := U_FtWmsParam("WMS_PRODUTO_USA_SEGUNDA_UNIDADE_MEDIDA"            , "L", .F. , .F., Nil, SA1->A1_COD, SA1->A1_LOJA, _cContrat, Nil)
					// valida o controle de uso de fator de conversao da segunda unidade de medida
					_lUsoFatConv  := U_FtWmsParam("WMS_PRODUTO_USA_FATOR_CONVERSAO_SEG_UNIDADE_MEDIDA", "L", .F. , .F., Nil, SA1->A1_COD, SA1->A1_LOJA, _cContrat, Nil)
					// valida identificacao do produto
					_cTpIdEtiq    := U_FtWmsParam("WMS_PRODUTO_ETIQ_IDENT"                            , "C", "INTERNA", .f., Nil, SA1->A1_COD, SA1->A1_LOJA, _cContrat, Nil)
					// formato de obtenção das informações do lote do produto
					_cParamLot    := U_FtWmsParam("WMS_LOTE_ORIGEM_INFORMACAO"                        , "C", "INFORMA_MANUAL" , .F., Nil, SA1->A1_COD, SA1->A1_LOJA, _cContrat, Nil)
					// verifica se cliente tem sequencia de pre-conferencia ativado
					_lPreConf     := U_FTVldSrv(SA1->A1_COD, SA1->A1_LOJA, "015", "014")
					// se cliente possui controle de número de série
					_lSerieAtv    := U_FtWmsParam("WMS_CONTROLE_POR_NUMERO_SERIE"                     , "L", .F. , .F., Nil, SA1->A1_COD, SA1->A1_LOJA, _cContrat, Nil)

					IF (_lPreConf)
						// solicita escolher a ordem de serviço de pré-conferencia para vincular ao documento fiscal
						_cNumos := U_LstPConf(SA1->A1_COD, SA1->A1_LOJA, _cCodProg, _cIteProg)

						// se cancelado
						If Empty(_cNumos)
							Help(,, 'TWMSA006.sfVldCliente.001',, "Ordem de serviço não selecionada.", 1, 0,;
							NIL, NIL, NIL, NIL, NIL,;
							{"É obrigatório vincular esta nota fiscal com uma ordem de serviço de pré-conferência. Tente novamente."})
							Return(.F.)
						Else
							// atualiza número da OS
							_aCampos[NPNUMOS][2] := _cNumos
						Endif
					EndIf

				Else // se não escolheu programação
					Return(.F.)
				EndIf
			EndIf
		Else
			// cliente/fornecedor novo
			_lNewClieFor := .t.
			// definicao da sigla do cliente
			If !(sfDefSigla(_aCampos,mvCnpj,mvNome))
				Return(.f.)
			EndIf
		Endif
	EndIf

	// atualiza os gets
	For _nGets := 1 to Len(_aGets)
		_aGets[_nGets]:Refresh()
	Next _nGets

Return( .T. )

// ** funcao que valida os dados do fornecedor
Static Function sfVldFornece(_aCampos, _aGets, mvCnpj, mvNome)
	Local _nGets

	If Empty(mvCnpj)
		Aviso("Inconsistência","Não foi possível localizar o CNPJ do fornecedor no arquivo XML! (_NFEPROC:_NFE:_INFNFE:_EMIT:_CNPJ:TEXT) ",{"Cancelar"})
		Return(.f.)
	Else
		// pesquisa o cliente
		dbSelectArea("SA2")
		SA2->(dbSetOrder(3)) //3-A2_FILIAL, A2_CGC
		If SA2->(dbSeek(xFilial("SA2") + mvCnpj ))
			_aCampos[NPCODCLI][2] := SA2->A2_COD
			_aCampos[NPLOJCLI][2] := SA2->A2_LOJA
			_aCampos[NPNOMCLI][2] := SA2->A2_NOME
			_aCampos[NPSIGLA ][2] := ""
		Else
			// cliente/fornecedor novo
			_lNewClieFor := .t.
		Endif
	EndIf

	// atualiza os gets
	For _nGets := 1 to Len(_aGets)
		_aGets[_nGets]:Refresh()
	Next _nGets

Return(.t.)

// ** funcao para selecionar o arquivo XML a ser importado
Static Function fGetFile(_cArquivo, _aCampos, _aGets)
	Local _nGets

	// busca arquivo XML
	_cArquivo := cGetFile("Notas Fiscais|*.XML", ("Selecione arquivo Xml"),,_cDirLocPdr,.f.,GETF_LOCALHARD,.f.)

	// zera variaveis
	_oXML := Nil
	_aCampos[NPCODCLI][2] := CriaVar("A2_COD",.F.)
	_aCampos[NPLOJCLI][2] := CriaVar("A2_LOJA",.F.)
	_aCampos[NPNOMCLI][2] := CriaVar("A2_NOME",.F.)
	_aCampos[NPSIGLA ][2] := CriaVar("A1_SIGLA",.F.)
	_aCampos[NPADICNF][2] := CriaVar("F1_ZINFADI",.F.)
	_aCampos[NPNDOCNF][2] := CriaVar("F1_DOC",.F.)
	_aCampos[NPSERINF][2] := CriaVar("F1_SERIE",.F.)
	_aCampos[NPPLIQUI][2] := CriaVar("F1_PLIQUI",.F.)
	_aCampos[NPPBRUTO][2] := CriaVar("F1_PBRUTO",.F.)
	_aCampos[NPVOLUM1][2] := CriaVar("F1_VOLUME1",.F.)
	_aCampos[NPCHVNFE][2] := CriaVar("F1_CHVNFE",.F.)
	_aCampos[NPPROGRA][2] := CriaVar("F1_PROGRAM",.F.)

	// atualiza objetos
	For _nGets := 1 to Len(_aGets)
		_aGets[_nGets]:Refresh()
	Next _nGets

	// desabilita uso do arquivo complementar
	_lUsaArqComp := .f.

	// zera informacoes do arquivo complementar
	// ex estrutura _aInfArqComp
	// 1-Seq Item
	// 2-Cod Produto
	// 3-Desc Produto
	// 4-Lote
	// 5-Quant
	// 6-Vlr Unit
	// 7-Vlr Total
	// 8-Saldo da Quant
	_aInfArqComp := {}

	// copia o arquivo local para o servidor
	If ( ! Empty(_cArquivo) )
		sfCopiaArq(@_cArquivo)
	EndIf

	// limpa o TRB dos itens
	fCriaTrb(.f.)

Return

// ** funcao que valida os itens da nota
Static Function sfVldItens(_aCampos)
	// controle do retorno
	Local _lRet := .t.

	// item
	Local _cItem
	// codigo do produto
	Local _cCodProd, _cCodPrdCli
	local _aTmpCodProd
	// ean do produto
	Local _cCodBarCli := ""
	// descricao do produto
	Local _cDscProd
	// NCM
	Local _cCodNCM
	// quantidade
	Local _nQuant
	// valor unitario
	Local _nVlrUnit
	// valor total
	Local _nVlrTotal
	// controle se o produto ja esta cadastrado
	Local _lProdExis := .f.
	// relacao de produtos na nota
	Local _aProdutos := {}
	// unidade de medida
	Local _cUnidMed := CriaVar("B1_UM")
	// segunda unidade de medida
	Local _cSegUnid := CriaVar("B1_SEGUM")
	// conversor da seg unidade
	Local _nConver := CriaVar("B1_CONV")
	// tipo do conversor da seg unidade
	Local _cTipoConv := CriaVar("B1_TIPCONV")
	// origem do produto
	Local _cOrigem := CriaVar("B1_ORIGEM")
	// lote
	local _cLoteCtl := CriaVar("D1_LOTECTL", .f.)
	// status do produto
	Local _cStsProd := ""
	// controle do item
	Local _nItem
	// mensagem de erro
	Local _cErroLog := ""
	// informacoes complementares do produto
	local _cInfAdic := ""
	// codigo da TES
	local _cCodTES := CriaVar("D1_TESACLA")
	// controla endereco / wms ativo
	local _cCtrEnder := IIf(_lWmsAtivo, "S", "N")
	// atualiza cadastro do produto
	local _cAtuCadProd := "S"
	// Saldo do Produto
	Local _nSaldoSb2 := 0
	// seek sb2
	local _cSeekSB2
	// grupo de estoque
	local _cGrpEsto := CriaVar("B1_ZGRPEST")

	// posicao do item complementar
	local _nPosItm

	// CFOP
	local _cCFOP := ""

	// Variável auxiliar para Log Produto
	local _cPrdNovo := ""

	// lista de produtos da nota (tem q ser private pra funcionar o Type)
	Private _aItXml := {}

	// carrega array dos itens
	_aItXml := &(_cBaseXML+"_INFNFE:_DET")

	// se nao conseguiu carrega os itens corretamente
	If (ValType(_aItXml)<>'A')
		_aItXml := {}
		aAdd(_aItXml,&(_cBaseXML+"_INFNFE:_DET"))
	Endif

	// limpa os Itens do TRB
	fCriaTrb( .F. )

	// adiciona os itens no TRB
	For _nItem := 1 to Len(_aItXml)

		// lote
		_cLoteCtl    := CriaVar("D1_LOTECTL", .f.)

		// item
		_cItem       := StrZero(Val(_aItXml[_nItem]:_NITEM:TEXT),Len((_TRBSD1)->D1_ITEM))
		// codigo do produto
		_cCodPrdCli  := sfLimpaStr(_aItXml[_nItem]:_PROD:_CPROD:TEXT)

		// faz tratamento especifico para o cliente PORTOBELLO, na qual o lote esta junto no codigo do produto, somente em notas de exportacao
		If (_lLotAtivo) .AND. (_lXmlVndExt) .AND. (_lXmlNfExt)
			// separa as informacoes por " " espaco
			_aTmpCodProd := Separa(_cCodPrdCli, " ")
			// define codigo do produto
			_cCodPrdCli := PadR(_aTmpCodProd[1], TamSx3("B1_CODCLI")[1])

			// preenche lote do produto
			If (_cParamLot  == "CONCATENADO_CODIGO_PRODUTO")
				//se concatenado com o código do produto no XML, divide parte do codigo em lote
				_cLoteCtl   := PadR(_aTmpCodProd[2], TamSx3("D1_LOTECTL")[1])
				// controle de edicao de lote
				_lEditLote  := .F.
			ElseIf (_cParamLot  == "INFORMA_MANUAL")
				//deixa em branco e libera o campo edit para que o usuário digite
				_cLoteCtl := ""
				// controle de edicao de lote
				_lEditLote  := .T.
			EndIf

		EndIf

		// código EAN do produto
		_cCodBarCli  := Iif( (_lAtuCodBar).and.(AttIsMemberOf(_aItXml[_nItem]:_PROD, "_CEAN")), sfLimpaStr(_aItXml[_nItem]:_PROD:_CEAN:TEXT), CriaVar("B1_CODBAR") )
		// monta o codigo do produto (sigla + codigo do XML)
		_cCodProd    := AllTrim(_aCampos[NPSIGLA][2]) + _cCodPrdCli
		// descricao do produto
		_cDscProd    := sfLimpaStr(_aItXml[_nItem]:_PROD:_XPROD:TEXT)
		// NCM
		_cCodNCM     := IIf(AttIsMemberOf(_aItXml[_nItem]:_PROD, "_NCM"),_aItXml[_nItem]:_PROD:_NCM:TEXT,CriaVar("B1_POSIPI"))
		// quantidade
		_nQuant      := Val(_aItXml[_nItem]:_PROD:_QCOM:TEXT)
		// valor unitario
		_nVlrUnit    := Val(_aItXml[_nItem]:_PROD:_VUNCOM:TEXT)
		// valor total
		_nVlrTotal   := Val(_aItXml[_nItem]:_PROD:_VPROD:TEXT)
		// unidade de medida
		_cUnidMed    := sfPadUnid(_aItXml[_nItem]:_PROD:_UCOM:TEXT)
		// informacoes adicionais do produto
		_cInfAdic    := IIf(AttIsMemberOf(_aItXml[_nItem], "_INFADPROD"),sfLimpaStr(_aItXml[_nItem]:_INFADPROD:TEXT),CriaVar("B1_ZINFADI"))
		// CFOP
		_cCFOP       := AllTrim(_aItXml[_nItem]:_PROD:_CFOP:TEXT)
		// retorna a origem e codigo da TES
		_cOrigem	 := sfRetOrigem(_nItem, @_cCodTES, _cCFOP)
		// atualiza cadastro do produto
		_cAtuCadProd := IIf(_lWmsAtivo, "N", "S")

		// se o cliente usar o arquivo complementar, atualiza os dados
		If (_lUsaArqComp).and.(_lArqCompOk)

			// pesquisa os itens complementares para atualizar os dados
			// ex estrutura _aInfArqComp
			// 1-Seq Item
			// 2-Cod Produto
			// 3-Desc Produto
			// 4-Lote
			// 5-Quant
			// 6-Vlr Unit
			// 7-Vlr Total
			// 8-Saldo da Quant
			_nPosItm := aScan(_aInfArqComp,{|mvVetor| (AllTrim(mvVetor[2]) == AllTrim(_cCodPrdCli)).and.(mvVetor[5] == _nQuant).and.(mvVetor[6] == _nVlrUnit).and.(mvVetor[8] > 0) })

			// se nao encontrou item, inclui mensagem no log
			If (_nPosItm == 0)
				// atualiza mensagem de LOG
				_cErroLog += "Item: "+_cItem+" - Não há dados no arquivo complementar"+CRLF
				// controle do retorno
				_lRet := .f.
			EndIf

			// se tem o item, mas nao tem mais saldo
			If (_nPosItm > 0).and.(_aInfArqComp[_nPosItm][8] <= _nQuant)

				// descricao do produto
				_cDscProd := sfLimpaStr(_aInfArqComp[_nPosItm][3])
				// lote
				_cLoteCtl := UPPER(_aInfArqComp[_nPosItm][4])
				// controle de edicao de lote
				_lEditLote := .f.

				// reduz o saldo disponivel do item/lote
				_aInfArqComp[_nPosItm][8] -= _nQuant

			EndIf

		EndIf

		// verifica se a ORIGEM esta correta
		If (Empty(_cOrigem))
			// atualiza mensagem de LOG
			_cErroLog += "Item: "+_cItem+" - Origem do produto incorreto."+CRLF
			// controle do retorno
			_lRet := .f.
		EndIf

		// verifica se a TES esta correta
		If (Empty(_cCodTES))
			// atualiza mensagem de LOG
			_cErroLog += "Item: "+_cItem+" - TES para a nota fiscal/produto não encontrada no sistema. Entre em contato com o setor *finaneiro/fiscal* do Tecadi e envie a nota fiscal para análise."+CRLF
			// controle do retorno
			_lRet := .f.
		EndIf

		// padroniza o tamanho do codigo do produto
		_cCodProd := PadR(_cCodProd,Len(SB1->B1_COD))

		// verifica se o produto existe
		dbSelectArea("SB1")
		SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
		If (SB1->(dbSeek( xFilial("SB1")+_cCodProd )))
			// statuso do produto
			_cStsProd	 := "CADASTRADO"
			_lProdExis	 := .t.

			// se lote ativo e ainda não controla rastro, não deixa prosseguir
			If (_lLotAtivo).And.(SB1->B1_RASTRO != "L")
				// atualiza mensagem de LOG
				_cErroLog += "Item: "+_cItem+" - " + AllTrim(_cCodProd) + " - Produto com Controle de Lote desativado."+CRLF
				// controle do retorno
				_lRet := .f.
			EndIf

			// valida se o parametro de WMS está ativo e controle de endereçamento
			If ( _lWmsAtivo ).and.( SB1->B1_LOCALIZ != "S" )
				// atualiza mensagem de LOG
				_cErroLog += "Item: "+_cItem+" - " + AllTrim(_cCodProd) + " - Produto com Controle de Endereçamento desativado."+CRLF
				// controle do retorno
				_lRet := .f.

			EndIf

			// valida se o parametro de WMS está ativo e controle de endereçamento
			If ( ! _lWmsAtivo ).and.( SB1->B1_LOCALIZ == "S" )
				// atualiza mensagem de LOG
				_cErroLog += "Item: "+_cItem+" - " + AllTrim(_cCodProd) + " - Produto com Controle de Endereçamento Ativado."+CRLF
				// controle do retorno
				_lRet := .f.

			EndIf

			// valida se o produto tem saldo
			If (_lWmsAtivo)

				// saldo do produto por armazem
				dbSelectArea("SB2")
				SB2->(dbsetorder(1)) // 1-B2_FILIAL, B2_COD, B2_LOCAL
				SB2->(dbseek( _cSeekSB2 := xFilial("SB2") + SB1->B1_COD ))
				// varre todos os armazens do produto
				While SB2->( ! Eof() ).and.(SB2->(B2_FILIAL+B2_COD) == _cSeekSB2)

					// verifica saldo disponivel no estoque.(SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QACLASS - SB2->B2_QEMP)
					_nSaldoSb2 := SaldoSb2()

					// se tem saldo Disponivel, nao altera o cadastro
					If (_nSaldoSb2 > 0)
						_cAtuCadProd := "N"
						Exit
					EndIf

					// proximo registro de saldo
					SB2->(dbSkip())
				EndDo
			EndIf

		Else
			// controle do retorno
			//_lRet := .f.
			_lProdExis	:= .F.

			// controle se o produto esta repetido
			If (aScan(_aProdutos,_cCodProd)==0)
				aAdd(_aProdutos,_cCodProd)
				// status do produto
				_cStsProd := "NOVO"

				If (_cStsProd == "NOVO")
					_cPrdNovo := AllTrim(_cCodProd) + " - " + AllTrim(_cDscProd)
					// Add ao array de produtos novos
					aAdd(_aPrdNovo, _cPrdNovo)
				Endif
			Else
				// status do produto
				_cStsProd := "DUPLICADO"
			EndIf
		EndIf

		// pesquisa se a unidade de media esta cadastrada
		If (!_lProdExis)
			dbSelectArea("SAH")
			SAH->(dbSetOrder(1)) //1-AH_FILIAL, AH_UNIMED
			If (!SAH->(dbSeek( xFilial("SAH")+_cUnidMed )))
				// atualiza mensagem de LOG
				_cErroLog += "Item: "+_cItem+" - Unid Med: "+_cUnidMed+" não cadastrada!"+CRLF
				// zera a variavel
				_cUnidMed := CriaVar("B1_UM")
				// controle do retorno
				_lRet := .f.
			EndIf
		EndIf

		// se o produto já existe, não deixa alterar a unidade de medida
		If (_lProdExis)
			// se a unidade de medida cadastrada for diferente da unidade de medida que consta no XML
			If (SB1->B1_UM <> _cUnidMed)
				// atualiza mensagem de LOG
				_cErroLog += "Unidade de Medida do XML (UM: " + _cUnidMed + ") é diferente da Unidade de Medida cadastrada (UM: " + SB1->B1_UM + "). Item: "+_cItem+" - Produto " + AllTrim(_cCodProd) + "!"+CRLF
				_cErroLog += "Caso o produto não tenha saldo em estoque, acesse o Cadastro de Produtos e faça a alteração da Unidade de Medida!"+CRLF
				// controle do retorno
				_lRet := .f.
				// nao permite importacao, nem alteracoes
				_lVldGeral := .F.
			EndIf
		EndIf

		// pesquisa se a NCM esta cadastrada
		dbSelectArea("SYD")
		SYD->(dbSetOrder(1)) //1-YD_FILIAL, YD_TEC, YD_EX_NCM, YD_EX_NBM
		If (!SYD->(dbSeek( xFilial("SYD")+_cCodNCM )))
			// atualiza mensagem de LOG
			_cErroLog += "Item: "+_cItem+" - NCM: "+_cCodNCM+" não cadastrado!"+CRLF
			// zera a variavel
			_cCodNCM := CriaVar("B1_POSIPI")
			// controle do retorno
			_lRet := .f.
		EndIf

		// grava os dados no arquivo de trabalho
		(_TRBSD1)->(dbSelectArea(_TRBSD1))
		(_TRBSD1)->(RecLock(_TRBSD1,.t.))
		(_TRBSD1)->IT_STATUS	:= _cStsProd
		(_TRBSD1)->IT_ATUALI  := _cAtuCadProd                                            // FLAG PARA ATUALIZAR O CADASTRO DO PRODUTO
		(_TRBSD1)->D1_ITEM	:= _cItem                                                  // ITEM DA NOTA FISCAL
		(_TRBSD1)->B1_GRUPO	:= IIf(_lProdExis, SB1->B1_GRUPO  , _aCampos[NPSIGLA ][2]) // SIGLA/GRUPO
		(_TRBSD1)->B1_CODCLI	:= IIf(_lProdExis, SB1->B1_CODCLI , _cCodPrdCli)           // CODIGO DO CLIENTE
		(_TRBSD1)->B1_COD		:= IIf(_lProdExis, SB1->B1_COD    , _cCodProd)             // CODIGO DO PRODUTO
		(_TRBSD1)->B1_DESC	:= _cDscProd                                               // DESCRICAO DO PRODUTO
		(_TRBSD1)->B1_POSIPI	:= _cCodNCM                                                // POSICAO DO IPI / NCM
		(_TRBSD1)->B1_UM		:= IIf(_lProdExis, SB1->B1_UM     , _cUnidMed)             // UNIDADE DE MEDIDA
		(_TRBSD1)->B1_SEGUM	:= IIf(_lProdExis, SB1->B1_SEGUM  , _cSegUnid)             // SEGUNDA UNIDADE DE MEDIDA
		(_TRBSD1)->B1_CONV	:= IIf(_lProdExis, SB1->B1_CONV   , _nConver)              // CONVERSOR DA SEG UNIDADE DE MEDIDA
		(_TRBSD1)->B1_TIPCONV	:= IIf(_lProdExis, SB1->B1_TIPCONV, _cTipoConv)            // TIPO DO CONVERSOR DA SEG UNIDADE DE MEDIDA
		(_TRBSD1)->B1_ORIGEM	:= _cOrigem                                                // ORIGEM
		(_TRBSD1)->B1_LOCALIZ	:= IIf(_lProdExis, SB1->B1_LOCALIZ, _cCtrEnder)            // CONTROLA ENDERECAMENTO (S/N)
		(_TRBSD1)->D1_QUANT	:= _nQuant
		(_TRBSD1)->D1_VUNIT	:= _nVlrUnit
		(_TRBSD1)->D1_TOTAL	:= _nVlrTotal
		(_TRBSD1)->B1_TIPO	:= IIf(_lProdExis, SB1->B1_TIPO   , _cDflTipo)
		(_TRBSD1)->B1_LOCPAD	:= IIf(_lProdExis, SB1->B1_LOCPAD , _cDflLocPad)
		// informacao adicional do produto
		(_TRBSD1)->B1_ZINFADI	:= _cInfAdic
		// codigo da TES
		(_TRBSD1)->D1_TESACLA	:= _cCodTES
		// grupo de estoque
		(_TRBSD1)->B1_ZGRPEST := IIf(_lProdExis, SB1->B1_ZGRPEST, _cGrpEsto)
		// lote
		(_TRBSD1)->D1_LOTECTL := _cLoteCtl
		// código EAN
		(_TRBSD1)->B1_CODBAR  := IIf(_lProdExis, SB1->B1_CODBAR, IIF( Empty(_cCodBarCli), (_TRBSD1)->B1_CODCLI, _cCodBarCli )  )
		// tipo do codigo de barras
		(_TRBSD1)->B1_ZTPBAR  := sfRetTpCdBar((_TRBSD1)->B1_CODBAR)
		// controle de número de série
		(_TRBSD1)->B1_ZTPBAR  := sfRetTpCdBar((_TRBSD1)->B1_CODBAR)
		// armazem de destino da mercadoria
		(_TRBSD1)->D1_LOCAL   := _cDflLocPad
		// controle se conteudo ok
		(_TRBSD1)->IT_OK		:= sfVldObrig(@_lRet)
		// grava o registro
		(_TRBSD1)->(MsUnLock())

	Next _nItem

	// Verifica se tem produtos novos para cadastrar
	If (!Empty(_aPrdNovo))

		// adiciona os produtos ao log para informar o ususário de forma facilitada, podendo copiar e colar a informação
		For _nItem := 1 to Len(_aPrdNovo)
			_cLogPrdNv += _aPrdNovo[_nItem] + CRLF
		Next

		// 01/10/2019 - Bruno Seára: Informo o usuário que existe produto a ser cadastrado, deve informar o setor de cadastro, mas pode continuar.
		HS_MsgInf("Existem PRODUTOS NOVOS a serem cadastrados. Informe o log abaixo ao setor de Cadastro para cadastro do lastro e camada." + CRLF + CRLF + _cLogPrdNv, "Importação XML - Produto novo", "ATENÇÃO!" )
		// Retorno
		_lRet := .T.
	Endif

	// se o cliente usar o arquivo complementar, atualiza os dados
	If (_lUsaArqComp).and.(_lArqCompOk)

		// pesquisa os itens complementares para atualizar os dados
		// ex estrutura _aInfArqComp
		// 1-Seq Item
		// 2-Cod Produto
		// 3-Desc Produto
		// 4-Lote
		// 5-Quant
		// 6-Vlr Unit
		// 7-Vlr Total
		// 8-Saldo da Quant
		_nPosItm := aScan(_aInfArqComp,{|mvVetor| (mvVetor[8] <> 0) })

		// se sobrou saldo de algum item
		If (_nPosItm > 0)
			// atualiza mensagem de LOG
			_cErroLog += "Sobra de saldo do item: "+AllTrim(_aInfArqComp[_nPosItm][2])+CRLF
			// controle do retorno
			_lRet := .f.
		EndIf

	EndIf

	// caso tenha pré-conferência
	If (_lPreconf)
		_cArquivo := "\EDI\midea\nf_transferencia\NFA" + _aCampos[NPNDOCNF][2] + ".txt"
		MsgRun("Por Favor Aguarde... Validando EDI...", "Executando rotinas de validações do EDI 3.2",{|| _lRet := U_TECMID01( _cArquivo, _aCampos) })

		if !(_lRet)
			// apaga tabela temporaria de EDI
			_cTrBArqPc:Delete()
			_oDlgXML:End()
		EndIf

	EndIf

	// se ocorreu algum erro, apresenta mensagem
	If ( ! _lRet)
		HS_MsgInf("ATENÇÃO: É obrigatório cadastrar os dados complementares dos produtos novos!"+;
		IIf(Empty(_cErroLog),"",CRLF+CRLF+"LOG:"+CRLF+_cErroLog) ,;
		"Log de Importação",;
		"Log de Importação" )
	EndIf

Return(_lRet)

// ** funcao para definir o complemento do produto
Static Function fComplProd()
	// controle da confirmacao na tela
	Local _lRet := .f.
	// controle da linha dos campos
	Local _nPosCmp	:= 10
	// unidade de medida
	Private _cUnidMed	:= (_TRBSD1)->B1_UM
	// descricao
	Private _cDescri	:= (_TRBSD1)->B1_DESC
	// tipo
	Private _cTipo		:= (_TRBSD1)->B1_TIPO
	// segunda unidade de medida
	Private _cSegUnid	:= (_TRBSD1)->B1_SEGUM
	// tipo do conversor da seg unidade
	Private _cTipoConv	:= If((_TRBSD1)->B1_TIPCONV=="M", "Multiplicador", "Divisor")
	// local padrao
	Private _cLocPad	:= (_TRBSD1)->B1_LOCPAD
	// controla endereco
	Private _cLocaliz	:= If((_TRBSD1)->B1_LOCALIZ=="S","Sim","Nao")
	// origem
	Private _cOrigem	:= (_TRBSD1)->B1_ORIGEM
	// posicao do IPI / NCM
	Private _cCodNCM    := (_TRBSD1)->B1_POSIPI
	// conversor da seg unidade
	Private _nConver    := (_TRBSD1)->B1_CONV
	// valor unitario
	Private _nVlrUnit   := (_TRBSD1)->D1_VUNIT
	// grupo de estoque
	Private _cGrpEsto   := (_TRBSD1)->B1_ZGRPEST
	// código EAN
	Private _cCodBar    := (_TRBSD1)->B1_CODBAR
	// lote do produto
	Private _cLotePrd   := (_TRBSD1)->D1_LOTECTL
	// número de série
	Private _cNumSerie   := If((_TRBSD1)->B1_ZNUMSER == "S","Sim","Nao")

	// valida codigo de produto
	If ((_TRBSD1)->(Eof()))
		Aviso("TWMSA006 -> fComplProd","Não há itens para alteração.",{"Fechar"})
		Return(.f.)
	EndIf

	// tela para detalhar os dados do produto
	_oDlgDetProd := MsDialog():New(000,000,490,400,"Detalhes e Complemento do Produto",,,.F.,,,,,,.T.,,,.T. )

	// cabecalho
	_oPnlTopDet := TPanel():New(1,1,,_oDlgDetProd,,.T.,.F.,,,1,20,,)
	_oPnlTopDet:Align := CONTROL_ALIGN_TOP
	// botoes de controle de operacao
	_oBtnDetConf := TButton():New(005,005,"Confirmar",_oPnlTopDet,{||_lRet:=.t.,_oDlgDetProd:End()},060,010,,,,.T.,,"",,,,.F. )
	_oBtnDetSair := TButton():New(005,070,"Fechar",_oPnlTopDet,{||_oDlgDetProd:End()},060,010,,,,.T.,,"",,,,.F. )

	// componente scroll
	oScrollBox := TScrollBox():New(_oDlgDetProd,000,000,400,400,.T.,.T.,.T. )
	oScrollBox:Align := CONTROL_ALIGN_ALLCLIENT

	// grupo e cod cliente
	_oSayGrupo := TSay():New(_nPosCmp,005,{||"Grupo/Sigla"},oScrollBox,,,,,,.T.,CLR_HBLUE,,040,30)
	_oGetGrupo := TGet():New(_nPosCmp-2,050,bSetGet((_TRBSD1)->B1_GRUPO),oScrollBox,040,10,"@!",,,,,,,.T.,,,{||.F.})
	_oSayCodCli := TSay():New(_nPosCmp,100,{||"Cod. Cliente"},oScrollBox,,,,,,.T.,CLR_HBLUE,,040,30)
	_oGetCodCli := TGet():New(_nPosCmp-2,135,bSetGet((_TRBSD1)->B1_CODCLI),oScrollBox,060,10,"@!",,,,,,,.T.,,,{||.F.})
	_nPosCmp += 15

	// codigo do produto
	_oSayCodProd := TSay():New(_nPosCmp,005,{||"Cód. Produto"},oScrollBox,,,,,,.T.,CLR_HBLUE,,040,30)
	_oGetCodProd := TGet():New(_nPosCmp-2,050,bSetGet((_TRBSD1)->B1_COD),oScrollBox,145,10,"@!",,,,,,,.T.,,,{||.F.})
	_nPosCmp += 15

	// descricao
	_oSayDescri := TSay():New(_nPosCmp,005,{||"Descrição"},oScrollBox,,,,,,.T.,CLR_HBLUE,,040,30)
	_oGetDescri := TGet():New(_nPosCmp-2,050,bSetGet(_cDescri),oScrollBox,145,10,"@!",,,,,,,.T.,,,{||Iif(_lWmsAtivo,.T.,.F.)},.F.,.F.,,.F.,.F.,"","_cDescri",,)
	_nPosCmp += 15

	// tipo / UM
	_oSayTipo := TSay():New(_nPosCmp,005,{||"Tipo"},oScrollBox,,,,,,.T.,CLR_HBLUE,,040,30)
	_oGetTipo := TGet():New(_nPosCmp-2,050,bSetGet(_cTipo),oScrollBox,040,10,"@!",{||Vazio().or.ExistCpo("SX5","02"+_cTipo)},,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"02","_cTipo",,)
	_oSayUM := TSay():New(_nPosCmp,100,{||"U.M."},oScrollBox,,,,,,.T.,CLR_HBLUE,,030,30)
	_oGetUM := TGet():New(_nPosCmp-2,135,bSetGet(_cUnidMed),oScrollBox,060,10,"@!",{||Vazio().Or.ExistCpo("SAH")},,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"SAH","_cUnidMed",,)
	// se já existir o produto, não permite alterar
	_oGetUM:bWhen := {|| IIF(sfPrdExiste((_TRBSD1)->B1_COD), .F., .T.) }
	_nPosCmp += 15

	// Seg UM / fat. conversor
	_oSaySegUM := TSay():New(_nPosCmp,005,{||"Seg. U.M."},oScrollBox,,,,,,.T.,IIf(_lUsoSegUM, CLR_HBLUE, Nil),,040,30)
	_oGetSegUM := TGet():New(_nPosCmp-2,050,bSetGet(_cSegUnid),oScrollBox,040,10 ,"@!",{||Vazio().Or.ExistCpo("SAH")},,,,,,.T.,,,{|| _lUsoSegUM },.F.,.F.,,.F.,.F.,"SAH","_cSegUnid",,)
	_oSayConver := TSay():New(_nPosCmp,100,{||"Fator Conv."},oScrollBox,,,,,,.T.,,,030,30)
	_oGetConver := TGet():New(_nPosCmp-2,135,bSetGet(_nConver),oScrollBox,060,10,PesqPict("SB1","B1_CONV"),{||Positivo()},,,,,,.T.,  ,,{|| IIF(sfPrdExiste((_TRBSD1)->B1_COD), .F., .T.) .AND. _lUsoSegUM .AND. _lUsoFatConv },.F.,.F.,,.F.,.F.,"","_nConver",,)
	_nPosCmp += 15

	// Seg UM / fat. conversor
	_oSayTpConv := TSay():New(_nPosCmp,005,{||"Tipo de Conv"},oScrollBox,,,,,,.T.,,,040,30)
	_oGetTpConv := TComboBox():New(_nPosCmp,050,{|u| If(PCount()>0,_cTipoConv:=u,_cTipoConv)},{"Multiplicador","Divisor"},145,010,oScrollBox,,,,,,.T.,,"",,{|| IIF(sfPrdExiste((_TRBSD1)->B1_COD), .F., .T.) .AND. _lUsoSegUM .AND. _lUsoFatConv },,,,,"_cTipoConv")
	_nPosCmp += 15

	// local padrao / localizacao
	_oSayLocal := TSay():New(_nPosCmp,005,{||"Armazém Padrão"},oScrollBox,,,,,,.T.,CLR_HBLUE,,)
	_oGetLocal := TGet():New(_nPosCmp-2,050,bSetGet(_cLocPad),oScrollBox,030,10,"@!",{|| Vazio().or.ExistCpo("Z12") },,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"Z12","_cLocPad",,)
	_oSayContEnd := TSay():New(_nPosCmp,100,{||"Contr. End."},oScrollBox,,,,,,.T.,CLR_HBLUE,,040,30)
	_oGetContEnd := TComboBox():New(_nPosCmp,135,{|u| If(PCount()>0,_cLocaliz:=u,_cLocaliz)},{"Sim","Não"},060,010,oScrollBox,,,,,,.T.,,"",,{||.f.},,,,,"_cLocaliz")
	_nPosCmp += 15

	// origem / Pos IPI
	_oSayOrigem := TSay():New(_nPosCmp,005,{||"Origem"},oScrollBox,,,,,,.T.,CLR_HBLUE,,030,30)
	_oGetOrigem := TGet():New(_nPosCmp-2,050,bSetGet(_cOrigem),oScrollBox,030,10,"@!",{||Vazio().or.ExistCpo("SX5","S0"+_cOrigem)},,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"S0","_cOrigem",,)
	_oSayPosIPI := TSay():New(_nPosCmp,100,{||"Pos IPI"},oScrollBox,,,,,,.T.,CLR_HBLUE,,030,30)
	_oGetPosIPI := TGet():New(_nPosCmp-2,135,bSetGet(_cCodNCM),oScrollBox,060,10,PesqPict("SB1","B1_POSIPI"),{||Vazio().Or.ExistCpo("SYD")},,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"SYD","_cCodNCM",,)
	_nPosCmp += 20

	// quantidade
	_oSayQuant := TSay():New(_nPosCmp,005,{||"Quantidade"},oScrollBox,,,,,,.T.,CLR_HBLUE,,)
	_oGetQuant := TGet():New(_nPosCmp-2,050,bSetGet((_TRBSD1)->D1_QUANT),oScrollBox,145,10,PesqPict("SD1","D1_QUANT"),,,,,,,.T.,,,{||.F.})
	_nPosCmp += 15

	// valor unitario
	_oSayVlrUnit := TSay():New(_nPosCmp,005,{||"Valor Unitário"},oScrollBox,,,,,,.T.,CLR_HBLUE,,)
	// botao para recalcular o Vlr Unit
	_oBtnRecalc := TButton():New(_nPosCmp-2,050,"Recálculo",oScrollBox,{|| sfRecalculo() },034,011,,,,.T.,,"",,,,.F. )
	_oGetVlrUnit := TGet():New(_nPosCmp-2,090,bSetGet(_nVlrUnit),oScrollBox,105,10,PesqPict("SD1","D1_VUNIT"),,,,,,,.T.,,,{||.F.})
	_nPosCmp += 15

	// valor total
	_oSayVlrTot := TSay():New(_nPosCmp,005,{||"Valor Total"},oScrollBox,,,,,,.T.,CLR_HBLUE,,)
	_oGetVlrTot := TGet():New(_nPosCmp-2,050,bSetGet((_TRBSD1)->D1_TOTAL),oScrollBox,145,10,PesqPict("SD1","D1_TOTAL"),,,,,,,.T.,,,{||.F.})
	_nPosCmp += 15

	// grupo de estoque
	_oSayGrpEst := TSay():New(_nPosCmp,005,{||"Grupo de Estoque"},oScrollBox,,,,,,.T.,CLR_HBLUE,,)
	_oGetGrpEst := TGet():New(_nPosCmp-2,050,bSetGet(_cGrpEsto),oScrollBox,040,10,PesqPict("SB1","B1_ZGRPEST"),{||Vazio().or.ExistCpo("Z36",(_TRBSD1)->B1_GRUPO+_cGrpEsto)},,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"Z36XML","_cGrpEsto",,)
	_nPosCmp += 15

	// código EAN
	_oSayEan := TSay():New(_nPosCmp,005,{||"Cód. de Barras"},oScrollBox,,,,,,.T.,CLR_HBLUE,,)
	_oGetEan := TGet():New(_nPosCmp-2,050,bSetGet(_cCodBar),oScrollBox,100,010,PesqPict("SB1","B1_CODBAR"),,,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"","_cCodBar",,)
	_nPosCmp += 15

	// lote do produto
	_oSayLote := TSay():New(_nPosCmp,005,{||"Lote"},oScrollBox,,,,,,.T.,IIf((_lLotAtivo).and.(_lLotObrEnt), CLR_HBLUE, Nil),,)
	_oGetLote := TGet():New(_nPosCmp-2,050,bSetGet(_cLotePrd),oScrollBox,100,010,"@!",,,,,,,.T.,,,{|| (_lLotAtivo).and.(_lLotObrEnt).and.(_lEditLote) },.F.,.F.,,.F.,.F.,"","_cLotePrd",,)
	_nPosCmp += 15

	// controle de número serie
	_oSaySerie := TSay():New(_nPosCmp,005,{||"Contr. Núm. Série?"},oScrollBox,,,,,,.T., CLR_HBLUE,,)
	_oGetSerie := TComboBox():New(_nPosCmp,050,{|u| If(PCount()>0,_cNumSerie:=u,_cNumSerie)},{"Não","Sim"},060,010,oScrollBox,,,,,,.T.,,"",,{||.T.},,,,,"_cNumSerie")

	// ativa a tela
	Activate MSDialog _oDlgDetProd Centered

	// controle do Ok
	If (_lRet)

		// valida armazens WMS
		dbSelectArea("Z12")
		Z12->(dbSetOrder(1)) //1-Z12_FILIAL, Z12_CODIGO
		If ! Z12->(dbSeek( xFilial("Z12")+_cLocPad ))
			MsgStop("Erro na definição do armazém!")
			_cLocPad := Space(Len(_cLocPad))
		EndIf

		// atualiza os dados no arquivo de trabalho
		(_TRBSD1)->(dbSelectArea(_TRBSD1))
		(_TRBSD1)->((_TRBSD1)->(RecLock(_TRBSD1)))
		(_TRBSD1)->B1_DESC     := _cDescri
		(_TRBSD1)->B1_TIPO     := _cTipo
		(_TRBSD1)->B1_UM       := _cUnidMed
		(_TRBSD1)->B1_SEGUM    := _cSegUnid
		(_TRBSD1)->B1_CONV     := _nConver
		(_TRBSD1)->B1_TIPCONV  := Left(_cTipoConv,1)
		(_TRBSD1)->B1_LOCPAD   := _cLocPad
		(_TRBSD1)->B1_LOCALIZ  := Left(_cLocaliz,1)
		(_TRBSD1)->B1_ORIGEM   := _cOrigem
		(_TRBSD1)->D1_VUNIT    := _nVlrUnit
		(_TRBSD1)->B1_POSIPI   := _cCodNCM
		(_TRBSD1)->B1_ZGRPEST  := _cGrpEsto
		(_TRBSD1)->B1_CODBAR   := AllTrim(_cCodBar)
		(_TRBSD1)->B1_ZNUMSER  := Left(_cNumSerie,1)
		(_TRBSD1)->D1_LOTECTL  := AllTrim(_cLotePrd)
		(_TRBSD1)->(MsUnLock())
	EndIf

	// ** funcao que re-valida os itens apos correcao
	_lItensOk := sfReavItens()

	// refresh do browse
	_oBrwItens:oBrowse:Refresh(.t.)

Return

// ** funcao para o recalculo do Vlr Unit
Static Function sfRecalculo()
	If (MsgYesNo("Confirma o recálculo do Valor Unitário?"))
		_nVlrUnit := Round(((_TRBSD1)->D1_TOTAL / (_TRBSD1)->D1_QUANT),TamSx3("D1_VUNIT")[2])
	EndIf
Return

// ** funcao funcao para cadastrar o produto
Static Function sfAddProd(mvInclui, _aCampos)
	// dados do produto
	Local _aDadosPro := {}
	// tipos de produto de acordo com a operacao
	local _cTipoProd := If(cModulo=="COM", "C", "A") // C=Compras e Consumo / A=Armazem

	// definicao padrao se a quantidade do produto devera ser informada manualmente
	local _lInfQtdMan := U_FtWmsParam("WMS_PRODUTO_INFORMA_QUANTIDADE_MANUAL", "L", .T. , .F., Nil, _aCampos[NPCODCLI][2], _aCampos[NPLOJCLI][2], Nil, Nil)

	// cria variável para chamar rotina padrão de inclusão de produtos em formato MVC
	// necessário conforme documentação TDN - http://tdn.totvs.com/pages/releaseview.action?pageId=6087457
	Private aRotina := {}

	// valida armazens WMS
	dbSelectArea("Z12")
	Z12->(dbSetOrder(1)) //1-Z12_FILIAL, Z12_CODIGO
	If ! Z12->(dbSeek( xFilial("Z12") + (_TRBSD1)->B1_LOCPAD ))
		MsgStop("Erro na definição do armazém!")
		Return(.f.)
	EndIf

	// alimenta Vetor com os dados do produto a ser cadastrado
	aAdd(_aDadosPro,{"B1_GRUPO"  , (_TRBSD1)->B1_GRUPO         , NIL} )
	aAdd(_aDadosPro,{"B1_CODCLI" , (_TRBSD1)->B1_CODCLI        , NIL} )
	aAdd(_aDadosPro,{"B1_COD"    , (_TRBSD1)->B1_COD           , NIL} )
	aAdd(_aDadosPro,{"B1_DESC"   , (_TRBSD1)->B1_DESC          , NIL} )
	aAdd(_aDadosPro,{"B1_TIPO"   , (_TRBSD1)->B1_TIPO          , NIL} )
	aAdd(_aDadosPro,{"B1_UM"     , (_TRBSD1)->B1_UM            , NIL} )
	aAdd(_aDadosPro,{"B1_SEGUM"  , (_TRBSD1)->B1_SEGUM         , NIL} )
	aAdd(_aDadosPro,{"B1_CONV"   , (_TRBSD1)->B1_CONV          , NIL} )
	aAdd(_aDadosPro,{"B1_TIPCONV", (_TRBSD1)->B1_TIPCONV       , NIL} )
	aAdd(_aDadosPro,{"B1_LOCPAD" , (_TRBSD1)->B1_LOCPAD        , NIL} )
	aAdd(_aDadosPro,{"B1_LOCALIZ", (_TRBSD1)->B1_LOCALIZ       , NIL} )
	aAdd(_aDadosPro,{"B1_ORIGEM" , (_TRBSD1)->B1_ORIGEM        , NIL} )
	aAdd(_aDadosPro,{"B1_POSIPI" , (_TRBSD1)->B1_POSIPI        , NIL} )
	aAdd(_aDadosPro,{"B1_ZINFADI", (_TRBSD1)->B1_ZINFADI       , NIL} )
	aAdd(_aDadosPro,{"B1_ZTIPPRO", _cTipoProd                , NIL} )
	aAdd(_aDadosPro,{"B1_GARANT" , "2"                       , NIL} )
	aAdd(_aDadosPro,{"B1_ZINFQTD", IIf(_lInfQtdMan, "S", "N"), NIL} )
	aAdd(_aDadosPro,{"B1_RASTRO" , IIf(_lLotAtivo, "L", "N") , NIL} )
	aAdd(_aDadosPro,{"B1_ZGRPEST", (_TRBSD1)->B1_ZGRPEST       , NIL} )
	aAdd(_aDadosPro,{"B1_CODBAR" , (_TRBSD1)->B1_CODBAR        , NIL} )
	aAdd(_aDadosPro,{"B1_ZTPBAR" , (_TRBSD1)->B1_ZTPBAR        , NIL} )
	// força a ativação de leitura de barcodes para Sumitomo para cadastro de produtos novos que não sejam materia prima
	If ( (_TRBSD1)->B1_GRUPO == "SUMI" ) .AND. ( (_TRBSD1)->B1_ZGRPEST != "0100" ) .AND. ( (_TRBSD1)->B1_ZGRPEST != "0200" )
		aAdd(_aDadosPro,{"B1_ZNUMSER", "S" , NIL} )
	Else  // caso contrário, pega conforme informado na janela de cadastro
		aAdd(_aDadosPro,{"B1_ZNUMSER", (_TRBSD1)->B1_ZNUMSER , NIL} )
	EndIf

	// padronizao ordem dos campos
	_aDadosPro := FWVetByDic(_aDadosPro,'SB1',.F.)

	// carrega modelo MVC no objeto
	oModel := FwLoadModel ("MATA010")

	//Executa a Rotina Automatica
	lMsErroAuto := .F.

	// rotina padrao para cadastro de produtos - formato MVC
	FWMVCRotAuto( oModel, "SB1", IIF(mvInclui, MODEL_OPERATION_INSERT, MODEL_OPERATION_UPDATE ) , {{"SB1MASTER", _aDadosPro}})

	// se deu erro na inclusão
	If lMsErroAuto
		MostraErro()
		Return( .F. )
	EndIf

Return(.t.)

// ** funcao para definicao da sigla do cliente
Static Function sfDefSigla(_aCampos,mvCnpj,mvNome)
	// controle do Ok
	Local _lRet := .f.
	// codigo da sigla/grupo
	Local _cCodSigla := CriaVar("A1_SIGLA")
	// conteudo do Seek
	Local _cSeek
	// codigo para o cliente
	Local _cCodCli	:= "NOVO"
	// loja
	Local _cLoja	:= ""

	// tela para detalhar os dados do produto
	_oDlgDefSigla := MsDialog():New(000,000,210,400,"Definição da Sigla do Cliente",,,.F.,,,,,,.T.,,,.T. )

	// mensagens
	_oSayMens1 := TSay():New(010,005,{||"O Fornecedor/Cliente não esta cadastrado!"},_oDlgDefSigla,,,,,,.T.,,,)
	_oSayMens2 := TSay():New(020,005,{||"Nome: "+mvNome },_oDlgDefSigla,,,,,,.T.,,,)
	_oSayMens3 := TSay():New(030,005,{||"CNPJ: "+Transf(mvCnpj,PesqPict("SA1","A1_CGC"))},_oDlgDefSigla,,,,,,.T.,,,)
	_oSayMens3 := TSay():New(040,005,{||"Favor definir uma sigla para um novo cadastro."},_oDlgDefSigla,,,,,,.T.,,,)

	// codigo do grupo/sigla
	_oSaySigGrupo := TSay():New(060,005,{||"Sigla:"},_oDlgDefSigla,,,,,,.T.,,,)
	_oGetSigGrupo := TGet():New(058,030,bSetGet(_cCodSigla),_oDlgDefSigla,030,10,"@!",{||Vazio().or.ExistCpo("SBM")},,,,,,.T.,,,{||.T.},.F.,.F.,,.F.,.F.,"SBM","",,)

	// botoes de controle de operacao
	_oBtnSiglaConf := TButton():New(080,070,"Confirmar",_oDlgDefSigla,{||_lRet:=.t.,_oDlgDefSigla:End()},050,010,,,,.T.,,"",,,,.F. )
	_oBtnSiglaSair := TButton():New(080,130,"Fechar",_oDlgDefSigla,{||_oDlgDefSigla:End()},050,010,,,,.T.,,"",,,,.F. )

	// ativa a tela
	Activate MSDialog _oDlgDefSigla Centered

	// controle do Ok
	If (_lRet)
		// verifica se a sigla esta em uso em outro cliente
		dbSelectArea("SA1")
		SA1->(dbOrderNickName("A1_SIGLA")) // A1_FILIAL, A1_SIGLA
		SA1->(dbSeek( _cSeek := xFilial("SA1")+_cCodSigla ))
		While SA1->(!Eof()).and.(SA1->(A1_FILIAL+A1_SIGLA)==_cSeek)
			// armazena o codigo do cliente
			_cCodCli := SA1->A1_COD
			// verifica o numero da loja
			If (SA1->A1_LOJA > _cLoja)
				_cLoja := SA1->A1_LOJA
			EndIf
			// proximo registro
			SA1->(dbSkip())
		EndDo
		// define o proximo numero da loja
		If Empty(_cLoja)
			_cLoja := StrZero(1,Len(SA1->A1_LOJA))
		Else
			_cLoja := StrZero(Val(_cLoja)+1,Len(SA1->A1_LOJA))
		EndIf

		// atualiza o codigo do cliente
		_aCampos[NPCODCLI][2] := _cCodCli
		_aCampos[NPLOJCLI][2] := _cLoja
		_aCampos[NPNOMCLI][2] := mvNome
		_aCampos[NPSIGLA ][2] := _cCodSigla
	EndIf

Return(_lRet)

// ** funcao para cadastrar o cliente
Static Function sfAddCliente(_aCampos)
	// variavel com os dados do cliente
	Local _aDadosSA1 := {}
	// endereco
	Local _cEndPad   := sfLimpaStr(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_XLGR:TEXT"))
	Local _cEndereco := ""
	// numero
	Local _cNumero := AllTrim(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_NRO:TEXT"))
	// posicao da virgula no endereco
	Local _nPosVir := At(",",_cEndPad)
	// complemento
	Local _cCompl := Upper(If((Type(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_XCPL:TEXT")=="C"),&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_XCPL:TEXT"),""))

	// padroniza endereco
	_cEndereco := Left(_cEndPad,If(_nPosVir>0,_nPosVir,Len(_cEndPad)))
	// verifica se deve inserir a virgula
	If (SubStr(_cEndereco,Len(_cEndereco),1)<>",")
		_cEndereco += ","
	EndIf
	// inclui o numero
	_cEndereco += " "+_cNumero
	// inclui o complemento
	_cEndereco += " "+If(_nPosVir > 0,(SubS(_cEndPad,_nPosVir+2)),_cCompl)

	// alimenta Vetor com os dados do cliente a ser Cadastrado/atualizado
	aAdd(_aDadosSA1,{"A1_CGC"		,AllTrim(&(_cBaseXML+"_INFNFE:_EMIT:_CNPJ:TEXT"))							,NIL})	// CPF/CNPJ
	aAdd(_aDadosSA1,{"A1_SIGLA"		,_aCampos[NPSIGLA ][2]														,NIL})	// sigla
	aAdd(_aDadosSA1,{"A1_PESSOA"	,If(Len(AllTrim(&(_cBaseXML+"_INFNFE:_EMIT:_CNPJ:TEXT")))==14,"J","F")		,NIL})	// F-Fisica/J-Juridica
	aAdd(_aDadosSA1,{"A1_NOME"		,sfLimpaStr(&(_cBaseXML+"_INFNFE:_EMIT:_XNOME:TEXT"))						,NIL})	// nome
	// verifica se existe o nome fantasia/reduzido
	If (Type(_cBaseXML+"_INFNFE:_EMIT:_XFANT:TEXT")=="C")
		aAdd(_aDadosSA1,{"A1_NREDUZ",sfLimpaStr(&(_cBaseXML+"_INFNFE:_EMIT:_XFANT:TEXT"))						,NIL})	// nome fantasia
	Else
		aAdd(_aDadosSA1,{"A1_NREDUZ",sfLimpaStr(&(_cBaseXML+"_INFNFE:_EMIT:_XNOME:TEXT"))						,NIL})	// nome fantasia
	EndIf
	aAdd(_aDadosSA1,{"A1_END"		,_cEndereco																	,NIL})	// endereco
	//aAdd(_aDadosSA1,{"A1_ENDCOB"	,_cEndereco																	,NIL})	// endereco de cobranca
	aAdd(_aDadosSA1,{"A1_TIPO"		,"R"																		,NIL})	// tipo do cliente (R-Revendedor)
	aAdd(_aDadosSA1,{"A1_EST"		,&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_UF:TEXT")							,NIL})	// estado
	aAdd(_aDadosSA1,{"A1_ESTC"		,&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_UF:TEXT")							,NIL})	// estado de cobranca
	aAdd(_aDadosSA1,{"A1_COD_MUN"	,SubStr(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_CMUN:TEXT"),3,5)				,NIL})	// codigo do municipio
	aAdd(_aDadosSA1,{"A1_MUN"		,Upper(AllTrim(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_XMUN:TEXT")))			,NIL})	// descricao do municipio
	aAdd(_aDadosSA1,{"A1_MUNC"		,Upper(AllTrim(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_XMUN:TEXT")))			,NIL})	// descricao do municipio de cobranca
	aAdd(_aDadosSA1,{"A1_BAIRRO"	,Upper(AllTrim(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_XBAIRRO:TEXT")))		,NIL})	// bairro
	aAdd(_aDadosSA1,{"A1_BAIRROC"	,Upper(AllTrim(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_XBAIRRO:TEXT")))		,NIL})	// bairro de cobranca
	aAdd(_aDadosSA1,{"A1_CEP"		,&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_CEP:TEXT")							,NIL})	// CEP
	aAdd(_aDadosSA1,{"A1_CEPC"		,&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_CEP:TEXT")							,NIL})	// CEP de cobranca
	// verifica se existe o DDD e telefone
	If (Type(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_FONE:TEXT")=="C")
		aAdd(_aDadosSA1,{"A1_DDD"		,"0"+SubS(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_FONE:TEXT"),1,2)		,NIL})	// DDD
		aAdd(_aDadosSA1,{"A1_TEL"		,SubS(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_FONE:TEXT"),3)				,NIL})	// telefone
	EndIf
	aAdd(_aDadosSA1,{"A1_INSCR"		,&(_cBaseXML+"_INFNFE:_EMIT:_IE:TEXT")										,NIL})	// insc estadual
	aAdd(_aDadosSA1,{"A1_CODPAIS"	,"0"+&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_CPAIS:TEXT")					,NIL})	// pais do BACEN
	aAdd(_aDadosSA1,{"A1_EMAIL"		,"fiscal@tecadi.com.br"														,NIL})	// e-mail do cliente

	_aDadosSA1 := FWVetByDic(_aDadosSA1,'SA1',.F.)

	lMsErroAuto := .F.

	DbSelectArea("SA1")
	MSExecAuto({|x,y| mata030(x,y)},_aDadosSA1,3) // 3-Inclusao / 4-Alteracao

	If lMserroauto
		MostraErro()
		Return(.f.)
	Endif

	// se deu certo o cadastro, atualiza o codigo e loja
	_aCampos[NPCODCLI][2] := SA1->A1_COD
	_aCampos[NPLOJCLI][2] := SA1->A1_LOJA

Return(.t.)

// ** funcao para cadastrar o fornecedor
Static Function sfAddFornece(_aCampos)
	// variavel com os dados do fornecedor
	Local _aDadosSA2 := {}
	// endereco
	Local _cEndPad   := sfLimpaStr(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_XLGR:TEXT"))
	Local _cEndereco := ""
	// numero
	Local _cNumero := AllTrim(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_NRO:TEXT"))
	// posicao da virgula no endereco
	Local _nPosVir := At(",",_cEndPad)
	// complemento
	Local _cCompl := Upper(If((Type(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_XCPL:TEXT")=="C"),&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_XCPL:TEXT"),""))

	// padroniza endereco
	_cEndereco := Left(_cEndPad,If(_nPosVir>0,_nPosVir,Len(_cEndPad)))
	// verifica se deve inserir a virgula
	If (SubStr(_cEndereco,Len(_cEndereco),1)<>",")
		_cEndereco += ","
	EndIf
	// inclui o numero
	_cEndereco += " "+_cNumero
	// inclui o complemento
	_cEndereco += " "+If(_nPosVir > 0,(SubS(_cEndPad,_nPosVir+2)),_cCompl)

	// alimenta Vetor com os dados do cliente a ser Cadastrado/atualizado
	aAdd(_aDadosSA2,{"A2_CGC"		,AllTrim(&(_cBaseXML+"_INFNFE:_EMIT:_CNPJ:TEXT"))							,NIL})	// CPF/CNPJ
	aAdd(_aDadosSA2,{"A2_TIPO"		,If(Len(AllTrim(&(_cBaseXML+"_INFNFE:_EMIT:_CNPJ:TEXT")))==14,"J","F")		,NIL})	// F-Fisica/J-Juridica
	aAdd(_aDadosSA2,{"A2_NOME"		,sfLimpaStr(&(_cBaseXML+"_INFNFE:_EMIT:_XNOME:TEXT"))						,NIL})	// nome
	// verifica se existe o nome fantasia/reduzido
	If (Type(_cBaseXML+"_INFNFE:_EMIT:_XFANT:TEXT")=="C")
		aAdd(_aDadosSA2,{"A2_NREDUZ",sfLimpaStr(&(_cBaseXML+"_INFNFE:_EMIT:_XFANT:TEXT"))						,NIL})	// nome fantasia
	Else
		aAdd(_aDadosSA2,{"A2_NREDUZ",sfLimpaStr(&(_cBaseXML+"_INFNFE:_EMIT:_XNOME:TEXT"))						,NIL})	// nome fantasia
	EndIf
	aAdd(_aDadosSA2,{"A2_END"		,_cEndereco																	,NIL})	// endereco
	//aAdd(_aDadosSA2,{"A2_ENDCOB"	,_cEndereco																	,NIL})	// endereco de cobranca
	//aAdd(_aDadosSA2,{"A2_TIPO"		,"R"																		,NIL})	// tipo do cliente (R-Revendedor)
	aAdd(_aDadosSA2,{"A2_EST"		,&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_UF:TEXT")							,NIL})	// estado
	aAdd(_aDadosSA2,{"A2_ESTC"		,&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_UF:TEXT")							,NIL})	// estado de cobranca
	aAdd(_aDadosSA2,{"A2_COD_MUN"	,SubStr(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_CMUN:TEXT"),3,5)				,NIL})	// codigo do municipio
	aAdd(_aDadosSA2,{"A2_MUN"		,Upper(AllTrim(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_XMUN:TEXT")))			,NIL})	// descricao do municipio
	aAdd(_aDadosSA2,{"A2_MUNC"		,Upper(AllTrim(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_XMUN:TEXT")))			,NIL})	// descricao do municipio de cobranca
	aAdd(_aDadosSA2,{"A2_BAIRRO"	,Upper(AllTrim(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_XBAIRRO:TEXT")))		,NIL})	// bairro
	aAdd(_aDadosSA2,{"A2_BAIRROC"	,Upper(AllTrim(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_XBAIRRO:TEXT")))		,NIL})	// bairro de cobranca
	aAdd(_aDadosSA2,{"A2_CEP"		,&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_CEP:TEXT")							,NIL})	// CEP
	aAdd(_aDadosSA2,{"A2_CEPC"		,&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_CEP:TEXT")							,NIL})	// CEP de cobranca
	// verifica se existe o DDD e telefone
	If (Type(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_FONE:TEXT")=="C")
		aAdd(_aDadosSA2,{"A2_DDD"		,"0"+SubS(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_FONE:TEXT"),1,2)		,NIL})	// DDD
		aAdd(_aDadosSA2,{"A2_TEL"		,SubS(&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_FONE:TEXT"),3)				,NIL})	// telefone
	EndIf
	aAdd(_aDadosSA2,{"A2_INSCR"		,&(_cBaseXML+"_INFNFE:_EMIT:_IE:TEXT")										,NIL})	// insc estadual
	aAdd(_aDadosSA2,{"A2_CODPAIS"	,"0"+&(_cBaseXML+"_INFNFE:_EMIT:_ENDEREMIT:_CPAIS:TEXT")					,NIL})	// pais do BACEN
	aAdd(_aDadosSA2,{"A2_EMAIL"		,"fiscal@tecadi.com.br"														,NIL})	// e-mail do cliente

	_aDadosSA2 := FWVetByDic(_aDadosSA2,'SA2',.F.)

	lMsErroAuto := .F.

	DbSelectArea("SA2")
	MSExecAuto({|x,y| mata020(x,y)},_aDadosSA2,3) // 3-Inclusao / 4-Alteracao

	If lMserroauto
		MostraErro()
		Return(.f.)
	Endif

	// se deu certo o cadastro, atualiza o codigo e loja
	_aCampos[NPCODCLI][2] := SA2->A2_COD
	_aCampos[NPLOJCLI][2] := SA2->A2_LOJA

Return(.t.)

// ** funcao que padroniza a unidade de medida
Static Function sfPadUnid(mvCodigo)
	Local _cRet := Upper(AllTrim(mvCodigo))
	// tratamento para tonelada
	If (_cRet=="TN").or.(_cRet=="TON")
		_cRet := "TO"
		// tratamento para pares
	ElseIf (_cRet=="PAR")
		_cRet := "PA"
		// unidade
	ElseIf (_cRet=="UND")
		_cRet := "UN"
	Else
		_cRet := Substr(_cRet, 1, 2)
	EndIf
Return(_cRet)

// ** funcao que copia o arquivo local para o servidor
Static Function sfCopiaArq(mvArquivo)
	Local _cTmpArq	:= "" // nome do arquivo
	Local _cTmpExt	:= "" // extensao do arquivo
	local _cTmpDrv  := "" // drive do arquivo origem
	local _cTmpDir  := "" // diretorio do arquivo origem

	// cria os diretorios necessarios
	MakeDir("\tecadi")
	MakeDir("\tecadi\xml")
	MakeDir("\tecadi\xml\importados")
	// copia o arquivo do local para o servidor
	CpyT2S(mvArquivo,"\tecadi\xml",.f.)
	// ex: SplitPath ( < cArquivo>, [ @cDrive], [ @cDiretorio], [ @cNome], [ @cExtensao] )
	SplitPath(mvArquivo,@_cTmpDrv,@_cTmpDir,@_cTmpArq,@_cTmpExt)

	// atualiza pasta padrao
	_cDirLocPdr := _cTmpDrv + _cTmpDir

	// muda o caminho do arquivo para o servidor
	mvArquivo := "\tecadi\xml\"+_cTmpArq+_cTmpExt

Return(.t.)

// ** funcao que remove os acentos e caracteres especiais
Static Function sfLimpaStr(mvString,mvRemovSpc)
	Local cChar  := ""
	Local nX     := 0
	Local nY     := 0
	Local cVogal := "AEIOU"
	Local cAgudo := "ÁÉÍÓÚ"
	Local cCircu := "ÂÊÎÔÛ"
	Local cTrema := "ÄËÏÖÜ"
	Local cCrase := "ÀÈÌÒÙ"
	Local cTio   := "ÃÕ"
	Local cCecid := "Ç"

	// define o padrao para nao remover
	default mvRemovSpc := .f.

	// maiusculo
	mvString := Upper(mvString)
	// sem espacos
	mvString := AllTrim(mvString)

	// remove todos os espacos em branco
	If (mvRemovSpc)
		mvString := StrTran(mvString," ","")
	EndIf

	// varre todos os caracteres
	For nX:= 1 To Len(mvString)
		cChar:=SubStr(mvString, nX, 1)
		IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase
			nY:= At(cChar,cAgudo)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCircu)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTrema)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCrase)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTio)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr("AO",nY,1))
			EndIf
			nY:= At(cChar,cCecid)
			If nY > 0
				mvString := StrTran(mvString,cChar,SubStr("C",nY,1))
			EndIf
		Endif
	Next

	For nX:=1 To Len(mvString)
		cChar:=SubStr(mvString, nX, 1)
		If (Asc(cChar) < 32).Or.(Asc(cChar) > 123).Or.(cChar $ '&').Or.(cChar $ '"').Or.(cChar $ "'")
			mvString:=StrTran(mvString,cChar,".")
		Endif
	Next nX

Return(mvString)

// ** funcao que retorna a origem de produto e preenche a TES correta
Static Function sfRetOrigem(mvItem, mvTES, mvCFOP)
	// variavel de retorno
	local _cRet := ""
	// variaveis temporaria
	local _cSeekSX5
	local _cQuery
	local _aCodTES
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSX5 := SX5->(GetArea())
	// codigo do tributo
	local _cCodTrib
	// zera a variavel TES
	mvTES := CriaVar("D1_TESACLA")

	// varre a tabela S2 (Tipos de Tributacao) no SX5
	If ( ! _lOptSimples )

		_aSX5S2 := FWGetSX5("S2")

		For _nX := 1 To Len(_aSX5S2)
			// extrai o codigo do tributo
			_cCodTrib := AllTrim(_aSX5S2[_nX][3])
			// verifica a estrurura do XML
			If AttIsMemberOf(_aItXml[mvItem]:_IMPOSTO:_ICMS,"_ICMS"+_cCodTrib)
				// extrai a origem do produto
				_cRet     := &("_aItXml["+AllTrim(Str(mvItem))+"]:_IMPOSTO:_ICMS:_ICMS"+_cCodTrib+":_ORIG:TEXT")
				// extrai a CST correta do produto na nota (obs: pode ser diferente do da chave _ICMS40 / CST 41)
				_cCodTrib := &("_aItXml["+AllTrim(Str(mvItem))+"]:_IMPOSTO:_ICMS:_ICMS"+_cCodTrib+":_CST:TEXT")
				// encerra o While
				Exit
			EndIf
		Next _nX
		// se for optante pelo simples, varre a tabela SG (Tipos de Tributacao do Simples) no SX5
	ElseIf (_lOptSimples)

		_aSX5SG := FWGetSX5("SG")

		For _nY := 1 To Len(_aSX5SG)
			// extrai o codigo do tributo
			_cCodTrib := AllTrim(_aSX5SG[_nY][3])
			// verifica a estrurura do XML
			If AttIsMemberOf(_aItXml[mvItem]:_IMPOSTO:_ICMS,"_ICMSSN"+_cCodTrib)
				// extrai a origem do produto
				_cRet     := &("_aItXml["+AllTrim(Str(mvItem))+"]:_IMPOSTO:_ICMS:_ICMSSN"+_cCodTrib+":_ORIG:TEXT")
				// extrai a CST correta do produto na nota (obs: pode ser diferente do da chave _ICMS40 / CST 41)
				_cCodTrib := &("_aItXml["+AllTrim(Str(mvItem))+"]:_IMPOSTO:_ICMS:_ICMSSN"+_cCodTrib+":_CSOSN:TEXT")
				// encerra o While
				Exit
			EndIf
		Next _nY
	EndIf

	// caso nao tenha encontrado a origem correta, apresenta mensagem
	If (Empty(_cRet))
		Aviso("TWMSA006 -> sfRetOrigem: Origem do Produto","Não foi possível retornar a ORIGEM correta do produto. Favor verificar a estrutura do arquivo XML.",{"Cancelar"})

		// caso encontrou a ORIGEM, pesquisa a TES correta
	Else
		// prepara a query para buscar a TES correta
		_cQuery := " SELECT F4_CODIGO "
		// cadastro de TES
		_cQuery += " FROM "+RetSqlTab("SF4")+" (nolock) "
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond("SF4")
		// somente TES de entrada
		_cQuery += " AND F4_CODIGO <= '500' "
		// que o controle de poder de terceiro seja REMESSA
		_cQuery += "AND F4_PODER3 = '"+ IIF(_cTipoNota=="B", "R", "N")+"' "
		// que nao esteja BLOQUEADA
		_cQuery += "AND F4_MSBLQL <> '1' "
		// que movimenta estoque
		_cQuery += "AND F4_ESTOQUE = '"+ IIF(_cTipoNota=="B", "S", "N")+"' "

		If ( ! _lXmlNfExt )
			// que seja TRIBUTADO livro fiscal de ICMS
			_cQuery += "AND F4_LFICM <> 'N' "
			// somente remessa para armazenagem
			_cQuery += "AND SUBSTRING(F4_CF,2,3) = '"+SubStr(mvCFOP,2,3)+"' "
			// que a SIT TRIBUTARIA do ICMS seja o codigo encontrado no XML
			If ( ! _lOptSimples )
				_cQuery += "AND F4_SITTRIB = '"+_cCodTrib+"' "
				_cQuery += "AND F4_CSOSN = ' ' "
			ElseIf (_lOptSimples)
				_cQuery += "AND F4_CSOSN = '"+_cCodTrib+"' "
			EndIf
		ElseIf ( _lXmlNfExt )
			// para exportacao, usa somente a TES 49A
			_cQuery += " AND F4_CODIGO = '49A' "

		EndIf

		MemoWrit("c:\query\twmsa006_sfRetOrigem.txt", _cQuery)

		// retorno dos dados para o vetor
		_aCodTES := U_SqlToVet(_cQuery)
		// verifica se retornou mais de uma TES
		If (Len(_aCodTES)==1)
			mvTES := _aCodTES[1]
		EndIf
	EndIf

	// restaura area inicial
	RestArea(_aAreaSX5)
	RestArea(_aAreaAtu)

Return(_cRet)

// ** funcao que re-valida os itens apos correcao
Static Function sfReavItens()
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaTRB := (_TRBSD1)->(GetArea())
	// controle do retorno
	local _lRet := .t.

	(_TRBSD1)->(dbSelectArea(_TRBSD1))
	(_TRBSD1)->(dbGoTop())
	While (_TRBSD1)->(!Eof())

		// marca item com problema
		(_TRBSD1)->(RecLock(_TRBSD1))
		(_TRBSD1)->IT_OK := sfVldObrig(@_lRet)
		(_TRBSD1)->(MsUnLock())

		// proximo item
		(_TRBSD1)->(dbSkip())
	EndDo

	// restaura area incial
	RestArea(_aAreaTRB)
	RestArea(_aAreaAtu)

Return(_lRet)

// ** funcao interna padrao do SPEDNFE
// utilizada para consultar o status da NFe no SEFAZ
Static Function ConsNFeChave(cChaveNFe,cIdEnt)

	Local cURL      := PadR(GetNewPar("MV_SPEDURL","http://"),250)
	Local cMensagem := ""
	Local oWS
	local _lRet := .f.

	oWs := WsNFeSBra():New()
	oWs:cUserToken := "TOTVS"
	oWs:cID_ENT    := cIdEnt
	ows:cCHVNFE    := cChaveNFe
	oWs:_URL       := AllTrim(cURL)+"/NFeSBRA.apw"

	If oWs:ConsultaChaveNFE()

		If !Empty(oWs:oWSCONSULTACHAVENFERESULT:cVERSAO)
			cMensagem += "Versão da mensagem: "+oWs:oWSCONSULTACHAVENFERESULT:cVERSAO+CRLF
		EndIf

		cMensagem += "Ambiente: "+IIf(oWs:oWSCONSULTACHAVENFERESULT:nAMBIENTE==1,"Produção","Homologação")+CRLF
		cMensagem += "Cod.Ret.NFe: "+oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE+CRLF
		cMensagem += "Msg.Ret.NFe: "+oWs:oWSCONSULTACHAVENFERESULT:cMSGRETNFE+CRLF

		// variavel de retorno (nota valida e ambiente producao)
		_lRet := (AllTrim(oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE)=="100").and.(oWs:oWSCONSULTACHAVENFERESULT:nAMBIENTE==1)

		If !Empty(oWs:oWSCONSULTACHAVENFERESULT:cPROTOCOLO)
			cMensagem += "Protocolo: "+oWs:oWSCONSULTACHAVENFERESULT:cPROTOCOLO+CRLF
		EndIf

		Aviso("Consulta NF",cMensagem,{"Ok"},3)
	Else
		Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"Ok"},3)
	EndIf

Return(_lRet)

// ** funcao que verifica se o destinatario da nota esta correto
Static Function sfVldDest()

	// variavel de retorno
	local _lRet := .t.
	// CNPJ do destinatario
	local _cCNPJDest := ""

	// verifica se eh nota de exportacao/venda exterior
	_lXmlNfExt := (&(_cBaseXML+"_INFNFE:_DEST:_ENDERDEST:_UF:TEXT") == "EX")

	// valida se para este cliente, aceita importar XML Venda Exportacao
	If (_lXmlNfExt).and.( ! _lXmlVndExt )
		Aviso("TWMSA006 -> sfVldDest","Importação não permitida: Não é permitido uso de nota de exportação para este cliente.",{"Fechar"})
		_lRet := .f.
	EndIf

	// se nao for exportacao, valida CNPJ
	If ( ! _lXmlNfExt )
		// extrai o CNPJ
		_cCNPJDest := &(_cBaseXML+"_INFNFE:_DEST:_CNPJ:TEXT")
		// compara os CNPJ
		If (AllTrim(_cCNPJDest) <> AllTrim(SM0->M0_CGC))
			Aviso("TWMSA006 -> sfVldDest","Importação não permitida: CNPJ do destinatário da nota não é válido para esta empresa/filial.",{"Fechar"})
			_lRet := .f.
		EndIf
	EndIf

Return(_lRet)

// ** valida duplicidade de itens por valor
Static Function sfItensDupl()
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaTRB := (_TRBSD1)->(GetArea())
	// controle do retorno
	local _lRet := .t.
	// lista de produtos e valores unitarios
	local _aItensTRB := {}
	local _nItemTRB
	// controle do log
	local _cLogValor := ""

	// seleciona TRB
	(_TRBSD1)->(dbSelectArea(_TRBSD1))
	(_TRBSD1)->(dbGoTop())
	// varre todos os itens
	While (_TRBSD1)->( ! Eof() )

		// pesquisa se o item existe
		_nItemTRB := aScan(_aItensTRB,{|mvVetor| mvVetor[2] == (_TRBSD1)->B1_COD })

		// valida itens em duplicidade
		If (_nItemTRB > 0)
			// vlr. unitario - posicao 4 / lote - posicao 5
			If (_aItensTRB[_nItemTRB][4] == (_TRBSD1)->D1_VUNIT) .AND. (_aItensTRB[_nItemTRB][5] == (_TRBSD1)->D1_LOTECTL)
				// mensagens
				_cLogValor += "Itens " + _aItensTRB[_nItemTRB][1] + " e " + (_TRBSD1)->D1_ITEM +CRLF
				// retorno
				_lRet := .f.
			EndIf
		EndIf

		// adiciona item
		aAdd(_aItensTRB,{;
		(_TRBSD1)->D1_ITEM    ,;
		(_TRBSD1)->B1_COD     ,;
		(_TRBSD1)->B1_DESC    ,;
		(_TRBSD1)->D1_VUNIT   ,;
		(_TRBSD1)->D1_LOTECTL })

		// proximo item
		(_TRBSD1)->(dbSkip())
	EndDo

	// se houve divergencia
	If ( ! _lRet)
		HS_MsgInf("Duplicidade de itens. Favor analisar informações abaixo e agrupar os itens:" +CRLF+ _cLogValor ,;
		"Log de Importação",;
		"Log de Importação" )
	EndIf

	// restaura area incial
	RestArea(_aAreaTRB)
	RestArea(_aAreaAtu)

Return(_lRet)

// ** funcao para agrupar itens iguais, conforme selecao
Static Function sfAgrItens()
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaTRB := (_TRBSD1)->(GetArea())
	local _aRegBase := {}

	// controle do retorno
	local _lRet := .t.

	// lista de produtos e valores unitarios
	local _aItensTRB := {}
	local _nItemTRB

	// codigo do produto
	local _cCodProdBase := ""
	local _nRecnoPrd := 0

	// variaveis temporarias
	local _nX

	// quantidade total
	local _nTotQuant := 0
	// valor total
	local _nTotValor := 0

	// seleciona TRB
	(_TRBSD1)->(dbSelectArea(_TRBSD1))
	(_TRBSD1)->(dbGoTop())

	// varre todos os itens
	While (_TRBSD1)->( ! Eof() )

		// verifica se o item esta selecionado
		If ( Empty((_TRBSD1)->IT_SELEC) )
			// proximo item
			(_TRBSD1)->(DbSkip())
			Loop
		EndIf

		// controle de item base
		If (Len(_aRegBase) == 0)

			// guarda posicao do registro/item que ficara na relacao
			_aRegBase := (_TRBSD1)->(GetArea())
			// codigo do produto
			_cCodProdBase := (_TRBSD1)->B1_COD
			// recno do item base
			_nRecnoPrd    := (_TRBSD1)->(RecNo())
		Else

			// valida o codigo do produto
			If (_cCodProdBase != (_TRBSD1)->B1_COD)
				// mensagens
				Aviso("TWMSA006 -> sfAgrItens","Não é possível agrupar itens com características diferentes.",{"Fechar"})
				// retorno
				_lRet := .f.
				// sai do Loop
				Exit

			EndIf

		EndIf

		// pesquisa se o item existe
		_nItemTRB := aScan(_aItensTRB,{|mvVetor| mvVetor[2] == (_TRBSD1)->B1_COD })

		// valida itens em duplicidade
		If (_nItemTRB > 0)
			// vlr. unitario - posicao 5 / lote - posicao 8
			If (_aItensTRB[_nItemTRB][5] != (_TRBSD1)->D1_VUNIT).or.(_aItensTRB[_nItemTRB][8] != (_TRBSD1)->D1_LOTECTL)
				// mensagens
				Aviso("TWMSA006 -> sfAgrItens","Não é possível agrupar itens com características diferentes.",{"Fechar"})
				// retorno
				_lRet := .f.
				// sai do Loop
				Exit
			EndIf
		EndIf

		// adiciona item
		aAdd(_aItensTRB,{;
		(_TRBSD1)->D1_ITEM    ,;
		(_TRBSD1)->B1_COD     ,;
		(_TRBSD1)->B1_DESC    ,;
		(_TRBSD1)->D1_QUANT   ,;
		(_TRBSD1)->D1_VUNIT   ,;
		(_TRBSD1)->D1_TOTAL   ,;
		(_TRBSD1)->(RecNo())  ,;
		(_TRBSD1)->D1_LOTECTL })

		// quantidade total
		_nTotQuant += (_TRBSD1)->D1_QUANT
		// valor total
		_nTotValor += (_TRBSD1)->D1_TOTAL

		// proximo item
		(_TRBSD1)->(dbSkip())
	EndDo

	// se os itens estao ok, agrupa
	If (Len(_aRegBase) > 0).and.(Len(_aItensTRB) > 1).and.(_lRet)

		// atualiza itens, totalizando o item base
		For _nX := 1 to Len(_aItensTRB)

			// posiciona no registro do TRB
			(_TRBSD1)->(dbSelectArea(_TRBSD1))
			(_TRBSD1)->(DbGoTo( _aItensTRB[_nX][7] ))

			// atualiza item base
			If ((_TRBSD1)->(RecNo()) == _nRecnoPrd)
				(_TRBSD1)->(RecLock(_TRBSD1))
				(_TRBSD1)->IT_SELEC   := Space(2)
				(_TRBSD1)->D1_QUANT	:= _nTotQuant
				(_TRBSD1)->D1_TOTAL	:= _nTotValor
				(_TRBSD1)->(MsUnLock())
			Else
				(_TRBSD1)->(RecLock(_TRBSD1))
				(_TRBSD1)->(dbDelete())
				(_TRBSD1)->(MsUnLock())
			EndIf

		Next _nX

	EndIf

	// restaura area incial
	RestArea(_aAreaTRB)
	RestArea(_aAreaAtu)

Return(_lRet)

// ** funcao para atualizar as informacoes com o arquivo complementar
Static Function sfArqCompl(mvCampos)
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaTRB := (_TRBSD1)->(GetArea())

	// controle do retorno
	local _lRet := .t.

	// arquivo complementar
	local _cArqCompl := cGetFile("Arquivo Complementar|*.XML", ("Selecione arquivo Xml complementar"),,_cDirLocPdr,.f.,GETF_LOCALHARD,.f.)

	// tratamento de erro da funcao XmlParserFile
	local _cError   := ""
	local _cWarning := ""

	// nota fiscal do arquivo complementar
	local _cNotaArq := ""

	// log de processamento
	local _cLogArq := ""

	// estrutura base do arquivo XML
	local _cEstrXML := "_oXmlCompl:"

	// variaveis temporarias
	local _nX

	// campos e informacoes
	local _cItem, _cCodProd, _cDesProd, _cLoteCtl
	local _nQuant, _nVlrUnit, _nVlrTotal

	// estrutura do XML complementar
	Private _oXmlCompl
	private _aTmpItens := {}

	// OBS TI 29/01/2016
	// Em reunião com Marcio (TCD) e Caio (PTBL) não há vinculo do item entre XML (Danfe) e XML (Auxiliar)
	// Caio orientou a usar como chave CodProd + Quant + VlrUnit

	// zera informacoes do arquivo complementar
	// ex estrutura _aInfArqComp
	// 1-Seq Item
	// 2-Cod Produto
	// 3-Desc Produto
	// 4-Lote
	// 5-Quant
	// 6-Vlr Unit
	// 7-Vlr Total
	// 8-Saldo da Quant
	_aInfArqComp := {}

	// copia o arquivo local para o servidor
	If ( ! Empty(_cArqCompl) )
		sfCopiaArq(@_cArqCompl)
	EndIf

	// verifica se foi selecionado algum arquivo
	If (Empty(_cArqCompl))
		Aviso("TWMSA006 -> sfArqCompl","É obrigatório selecionar um arquivo.",{"Fechar"})
		Return(.f.)
	EndIf

	// abertura do arquivo XML e estrutura do objeto
	_oXmlCompl := XmlParserFile(_cArqCompl, "_", @_cError, @_cWarning )

	// verifica erros no XML
	If (ValType(_oXmlCompl) != "O")
		MsgStop("Falha ao gerar Objeto XML : "+_cError+" / "+_cWarning)
		_oXmlCompl := Nil
		Return(.f.)
	Endif

	// especifico cliente portobello
	_cEstrXML += "_WSHX502PB:_LIST_Q_NFF:_Q_NFF"

	// verifica erros na estrutura do XML
	If (Type(_cEstrXML) != "O")
		Aviso("TWMSA006 -> sfArqCompl","Falha ao gerar Objeto XML: "+_cError+" / "+_cWarning,{"Fechar"})
		_oXmlCompl := Nil
		Return(.f.)

	EndIf

	// nota fiscal do arquivo
	_cNotaArq := &(_cEstrXML+":_NR_NFF_REMESSA:TEXT")

	// padroniza com zeros a esquerda
	U_FtStrZero(TamSx3("F1_DOC")[1], @_cNotaArq)

	// valida numero da nota
	If (_cNotaArq <> mvCampos[NPNDOCNF][2])
		// mensagens
		_cLogArq += "Arquivo complementar não é da nota fiscal selecionada" +CRLF
		// retorno
		_lRet := .f.
	EndIf

	// carrega array dos itens
	_aTmpItens := &(_cEstrXML+":_LIST_Q_LINHA_NFF:_Q_LINHA_NFF")

	// se nao conseguiu carrega os itens corretamente
	If (ValType(_aTmpItens) <> "A")
		_aTmpItens := {}
		aAdd(_aTmpItens,&(_cEstrXML+":_LIST_Q_LINHA_NFF:_Q_LINHA_NFF"))
	Endif

	// varre todos os itens para validar informacoes
	For _nX := 1 to Len(_aTmpItens)
		// padroniza os campos
		// item
		_cItem     := StrZero(_nX,TamSx3("D1_ITEM")[1])
		// codigo do produto
		_cCodProd  := _aTmpItens[_nX]:_COD_ITEM:TEXT
		// descricao
		_cDesProd  := _aTmpItens[_nX]:_DESC_ITEM:TEXT
		// lote
		_cLoteCtl  := UPPER(_aTmpItens[_nX]:_NR_LOTE:TEXT)
		// controle de edicao de lote
		_lEditLote := .f.
		// quantidade
		_nQuant    := Val(StrTran(_aTmpItens[_nX]:_QT_FAT:TEXT,",","."))
		// valor unitario
		_nVlrUnit  := Val(StrTran(_aTmpItens[_nX]:_VLR_UNIT:TEXT,",","."))
		// valor total
		_nVlrTotal := _nQuant * _nVlrUnit

		// adiciona os dados no vetor
		aAdd(_aInfArqComp,{;
		_cItem     ,;
		_cCodProd  ,;
		_cDesProd  ,;
		_cLoteCtl  ,;
		_nQuant    ,;
		_nVlrUnit  ,;
		_nVlrTotal ,;
		_nQuant    })

	Next _nX

	// se houve divergencia
	If ( ! _lRet)
		HS_MsgInf("Divergência entre XML e Arq. Complementar" +CRLF+ _cLogArq ,;
		"Log de Importação",;
		"Log de Importação" )

	EndIf

	// restaura area incial
	RestArea(_aAreaTRB)
	RestArea(_aAreaAtu)

Return(_lRet)

// ** função pra validar se o produto já existe ** //
Static Function sfPrdExiste(mvCodProd)
	// variavel de retorno
	local _lRet     := .F.
	// salva area atual
	local _aAreaAtu := GetArea()

	dbSelectArea("SB1")
	SB1->( dbSetOrder(1) )
	// procuro o produto na tabela e se ja existir, retorna falso
	_lRet := SB1->( dbSeek( xFilial("SB1")+mvCodProd) )

	// restaura area inicial
	RestArea(_aAreaAtu)
Return _lRet

// ** funcao para validar o conteudo dos campos de cada item da nota
Static Function sfVldObrig(mvRet)
	// log da validacao
	local _cLogObr := ""
	// produto existe
	local _lProdExis := .f.

	// posiciono no produto, pra validar se ele existe
	dbSelectArea( "SB1" )
	SB1->( dbSetOrder( 1 ) ) // B1_FILIAL, B1_COD, R_E_C_N_O_, D_E_L_E_T_
	If ( SB1->( dbSeek( xFilial( "SB1") + (_TRBSD1)->B1_COD ) ) )
		_lProdExis := .t.
	EndIf

	// validação dos campos, conforme descrição ao lado (mesma validação da função sfReavItens)

	// falta descricao do produto
	If ( Empty((_TRBSD1)->B1_DESC) )
		_cLogObr := "Preencher descrição no cadastro do produto"
		mvRet := .f.
	EndIf

	// falta tipo do produto
	If ( Empty((_TRBSD1)->B1_TIPO) )
		_cLogObr := "Preencher TIPO no cadastro do produto"
		mvRet := .f.
	EndIf

	// falta unidade de medida
	If ( Empty((_TRBSD1)->B1_UM) )
		_cLogObr := "Preencher UNID. MEDIDA no cadastro do produto"
		mvRet := .f.
	EndIf

	// local/armazem padrao
	If ( Empty((_TRBSD1)->B1_LOCPAD) )
		_cLogObr := "Preencher ARMAZEM PADRÃO no cadastro do produto"
		mvRet := .f.
	EndIf

	// controle de enderecamento
	If ( Empty((_TRBSD1)->B1_LOCALIZ) )
		_cLogObr := "Verifique o CONTROLE DE ENDEREÇO no cadastro do produto"
		mvRet := .f.
	EndIf

	// origem fiscal
	If ( Empty((_TRBSD1)->B1_ORIGEM) )
		_cLogObr := "Preencher ORIGEM FISCAL no cadastro do produto"
		mvRet := .f.
	EndIf

	// ncm/posipi
	If ( Empty((_TRBSD1)->B1_POSIPI) )
		_cLogObr := "Preencher NCM no cadastro do produto"
		mvRet := .f.
	EndIf

	// falta de TES
	If ( Empty((_TRBSD1)->D1_TESACLA) )
		_cLogObr := "Preencher CÓD. DA TES no cadastro do produto"
		mvRet := .f.
	EndIf

	// se usa grupo de estoque, o grupo tem que estar preenchido
	If ( ( _lUsoGrpEst ) .and. ( Empty((_TRBSD1)->B1_ZGRPEST) ) )
		_cLogObr := "Preencher GRUPO DE ESTOQUE no cadastro do produto"
		mvRet := .f.
	EndIf

	// se controla lote e é obrigatório, precisa ter o lote preenchido na SD1
	If ( ( _lLotAtivo ) .and. ( _lLotObrEnt ) .and. ( Empty( (_TRBSD1)->D1_LOTECTL ) ) )
		_cLogObr := "Preencher LOTE do produto"
		mvRet := .f.
	EndIf

	// se controla lote o produto precisa controlar lote também
	If ( ( _lLotAtivo ) .and. ( _lProdExis ) .and. ( SB1->B1_RASTRO != "L" ) )
		_cLogObr := "Verifique se CONTROLE DE LOTE está ativo no cadastro do produto"
		mvRet := .f.
	EndIf

	// se WMS Ativo e controle de endereçamento está desativado, avisa usuário
	If ( ( _lWmsAtivo ) .and. ( (_TRBSD1)->B1_LOCALIZ != "S") )
		_cLogObr := "Verifique se CONTROLE ENDEREÇOS WMS está ativo no cadastro do produto"
		mvRet := .f.
	EndIf

	// se WMS não Ativo e controle de endereçamento está ativado, avisa usuário
	If ( ( ! _lWmsAtivo ) .and. ( (_TRBSD1)->B1_LOCALIZ == "S") )
		_cLogObr := "Verifique se o CONTROLE DE ENDEREÇAMENTO está DESATIVADO no cadastro do produto"
		mvRet := .f.
	EndIf

	// se usa segunda unidade de medida
	If (_lUsoSegUM) .and. ( Empty((_TRBSD1)->B1_SEGUM) )
		_cLogObr := "Verifique se a SEGUNDA UNID MEDIDA está preenchida no cadastro do produto"
		mvRet := .f.
	EndIf

	// se NAO usa segunda unidade de medida
	If ( ! _lUsoSegUM ) .and. ( ! Empty((_TRBSD1)->B1_SEGUM) )
		_cLogObr := "Produto não usa 2ª UNIDADE MEDIDA. Verifique o cadastro do produto"
		mvRet := .f.
	EndIf

	// se usa segunda unidade de medida, e tem que ter conversao
	If (_lUsoSegUM) .and. (_lUsoFatConv) .and. ( (_TRBSD1)->B1_CONV == 0 )
		_cLogObr := "Verifique se os valores de CONVERSÃO DA 2ª UNID MEDIDA estão preenchidos no cadastro do produto."
		mvRet := .f.
	EndIf

	// se usa segunda unidade de medida, e tem que ter conversao
	If (_lSerieAtv) .AND. ( (_TRBSD1)->B1_ZNUMSER != "S" )
		_cLogObr := "Cliente está com controle de número de série ativo, e o produto foi informado como não controla. Verifique."
		mvRet := .f.
	EndIf

	// atualiza log
	(_TRBSD1)->IT_LOG := IIf(mvRet, "", _cLogObr)

Return(IIf(mvRet, "OK", "  "))

// ** funcao que retorna o tipo de codigo de barras
Static Function sfRetTpCdBar(mvCodBar)
	// variavel de retorno
	local _cRet := ""

	// valida identificacao do produto
	If (AllTrim(_cTpIdEtiq) == "EAN").and.(Len(AllTrim(mvCodBar)) == 13)
		_cRet := "1" // EAN13
	ElseIf (AllTrim(_cTpIdEtiq) == "EAN").and.(Len(AllTrim(mvCodBar)) == 12)
		_cRet := "2" // UPC12
	ElseIf (AllTrim(_cTpIdEtiq) == "INTERNA") .or. (AllTrim(_cTpIdEtiq) == "CODE128")
		_cRet := "3" // CODE128
	EndIf

Return(_cRet)

// função auxiliar que verifica se a nota fiscal tem algum produto que possui integração via barcode - Cliente Sumitomo
// Redmine #414
// Retorno --> .T. se pelo menos UM dos produtos da nota fiscal tem integração de barcode, .F. se nenhum produto da nota fiscal tem integração de barcode
Static Function sfTemBarcode()
	Local _lRet := .F.
	Local aAreaSB1 := SB1->(GetArea())
	Local aAreaSD1 := (_TRBSD1)->( GetArea() )

	// posiciona no primeiro registro
	(_TRBSD1)->( dbGotop() )

	// percorre a tabela. Caso encontre um arquivo que peça barcode, não precisa validar o resto e sai do fluxo
	While (_TRBSD1)->( !Eof() )
		If ( GetAdvFVal("SB1","B1_ZNUMSER",xFilial("SB1") + (_TRBSD1)->B1_COD) == "S" )
			_lRet := .T.
			Exit
		EndIf

		// proximo item
		(_TRBSD1)->( DbSkip() )
	EndDo

	RestArea(aAreaSB1)
	RestArea(aAreaSD1)

Return (_lRet)