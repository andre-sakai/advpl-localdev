#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Cadastro de Complemento de Produtos para WMS            !
+------------------+---------------------------------------------------------+
!Autor             ! David Branco                                            !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 03/2015                                                 !
+------------------+---------------------------------------------------------+
!Chamada           ! Chamado a partir da rotina de Cadastro de Produtos      !
+------------------+--------------------------------------------------------*/

// ** funcao de cadastro de sku
User Function TWMSC008(mvCodProd)
	// label
	local _oCodPro, _oPnlCabec, _oPnlRodape, _oPnlGetDados, _oFldrProd
	// info tsay
	local _cCodDescPrd := ""
	// objetos
	local _oBtnConf, _oBtnCanc, _oTGetD, _oTGetC, _oTGetGrp
	// acols do browse
	Local _aColsSku := {}
	// tamanho da tela
	local _aSizeDlg := MsAdvSize()
	// pastas do FOLDER
	local _aFolders := {'Cadastro'}
	// objetos para FOLDER CADASTRO
	local _oTGetPB, _oTGetPL, _oTGetAl, _oTGetLa, _oTGetCm, _oTGetCbm
	local _nTGetPB  := CriaVar("B1_PESBRU",.f.)  // Peso Bruto
	local _nTGetPL  := CriaVar("B1_PESO",.f.)    // Peso Líquido
	local _nTGetAl  := CriaVar("B5_ALTURLC",.f.) // Altura
	local _nTGetLa  := CriaVar("B5_LARGLC",.f.)  // Largura
	local _nTGetCm  := CriaVar("B5_COMPRLC",.f.) // Cumprimento
	local _nTGetCbm := CriaVar("B1_ZCUBAGE",.f.) // Cubagem
	local _cGrpEst  := CriaVar("B1_ZGRPEST",.f.) // Grupo de Estoque
	local _cTGetDes := CriaVar("B1_DESC",.f.)    // Descrição do Produto

	// posiciono no produto - SB1
	dbSelectArea("SB1")
	SB1->(dbSetOrder(1)) // filial+codigo
	SB1->(dbSeek(xFilial("SB1")+mvCodProd))

	// valida o típo de produto
	If (SB1->B1_ZTIPPRO != "A")
		MsgStop("Não permitido para esse produto!")
		Return
	EndIf

	// preencho as informações de peso da SB1
	_nTGetPB  := SB1->B1_PESBRU  // peso bruto
	_nTGetPL  := SB1->B1_PESO    // peso liquido
	_nTGetCbm := SB1->B1_ZCUBAGE //cubagem

	// posiciono no produto - SB5
	dbSelectArea("SB5")
	SB5->(dbSetOrder(1)) // filial+codigo

	// se encontro o complemento já preenche os campos na tela
	If (SB5->(dbSeek( xFilial("SB5")+SB1->B1_COD )))
		_nTGetAl := SB5->B5_ALTURLC // Altura
		_nTGetLa := SB5->B5_LARGLC  // Largura
		_nTGetCm := SB5->B5_COMPRLC // Cumprimento
	EndIf

	// janela
	DEFINE DIALOG _oDlgSku TITLE "Complemento WMS - Produtos" FROM 000,000 TO 450,450 PIXEL

	// cria o panel topo
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgSku,,.F.,.F.,,,000,040,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// cria o panel do meio
	_oPnlGetDados := TPanel():New(000,000,nil,_oDlgSku,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlGetDados:Align := CONTROL_ALIGN_ALLCLIENT

	// pastas (folders) com as opcoes de visualizacao
	_oFldrProd := TFolder():New(000,000,_aFolders,,_oPnlGetDados,,,,.T.,,200,200)
	_oFldrProd:Align:= CONTROL_ALIGN_ALLCLIENT

	// cria o panel do rodape
	_oPnlRodape := TPanel():New(000,000,nil,_oDlgSku,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlRodape:Align := CONTROL_ALIGN_BOTTOM

	// mostra o código do produto
	_oTGetC   := TGet():New(005,006,{|| SB1->B1_COD },_oPnlCabec,096,009,"@!",,0,,,.F.,,.T.,,.F.,{||.f.},.F.,.F.,,.F.,.F.,,,,,,,,,"Código: ",2,,,, )
	// mostra a decrição do produto
	_cTGetDes := SB1->B1_DESC
	_oTGetD   := TGet():New(022,006,{|u|If(PCount()>0,_cTGetDes:=u,_cTGetDes)},_oPnlCabec,200,009,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,,,,,,,,"Descri: ",2,,,, )

	// ** FOLDER CADASTRO - INICIO ** //

	// Peso Bruto
	_oTGetPB  := TGet():New(010,006,{|u|If(PCount()>0,_nTGetPB:=u,_nTGetPB)}  ,_oFldrProd:aDialogs[1],096,009,PesqPict("SB1","B1_PESBRU"),/*validação*/,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,,"_nTGetPB",,,,,,"Peso Bruto (kg) ",1,,,, )
	// Peso Liquido
	_oTGetPL  := TGet():New(040,006,{|u|If(PCount()>0,_nTGetPL:=u,_nTGetPL)}  ,_oFldrProd:aDialogs[1],096,009,PesqPict("SB1","B1_PESO"),/*validação*/,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,,"_nTGetPL",,,,,,"Peso Líquido (kg) ",1,,,, )
	// Cubagem
	_oTGetCbm := TGet():New(070,006,{|u|If(PCount()>0,_nTGetCbm:=u,_nTGetCbm)},_oFldrProd:aDialogs[1],096,009,PesqPict("SB1","B1_ZCUBAGE"),/*validação*/,0,,,.F.,,.T.,,.F.,{||.f.},.F.,.F.,,.F.,.F.,,,"_nTGetAl",,,,,,"Cubagem (m³) ",1,,,, )
	// Comprimento
	_oTGetCm  := TGet():New(010,124,{|u|If(PCount()>0,_nTGetCm:=u,_nTGetCm)}  ,_oFldrProd:aDialogs[1],096,009,PesqPict("SB5","B5_COMPRLC"),{|| _nTGetCbm := sfRetCbm(_nTGetAl, _nTGetLa, _nTGetCm) },0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,,"_nTGetCm",,,,,,"Comprimento (m)",1,,,, )
	// Largura
	_oTGetLa  := TGet():New(040,124,{|u|If(PCount()>0,_nTGetLa:=u,_nTGetLa)}  ,_oFldrProd:aDialogs[1],096,009,PesqPict("SB5","B5_LARGLC") ,{|| _nTGetCbm := sfRetCbm(_nTGetAl, _nTGetLa, _nTGetCm) },0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,,"_nTGetLa",,,,,,"Largura (m) ",1,,,, )
	// Altura
	_oTGetAl  := TGet():New(070,124,{|u|If(PCount()>0,_nTGetAl:=u,_nTGetAl)}  ,_oFldrProd:aDialogs[1],096,009,PesqPict("SB5","B5_ALTURLC"),{|| _nTGetCbm := sfRetCbm(_nTGetAl, _nTGetLa, _nTGetCm) },0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,,"_nTGetAl",,,,,,"Altura (m)",1,,,, )
	// Grupo de Estoque
	_cGrpEst  := SB1->B1_ZGRPEST
	_oTGetGrp := TGet():New( 100,06,{|u|If(PCount()>0,_cGrpEst:=u,_cGrpEst)}  ,_oFldrProd:aDialogs[1],096,009,PesqPict("SB1","B1_ZGRPEST"),{|| sfVldGrpEst (_cGrpEst, SB1->B1_GRUPO)},0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"Z36",,"_cGrpEst",,,,,,"Grupo de Estoque",1,,,, )

	// ** FOLDER CADASTRO - FIM ** //

	// botao confirmar
	_oBtnConf := TButton():New(006, 006, "Confirmar",_oPnlRodape,{|| IIF(sfConfirma(_nTGetPB, _nTGetPL, _nTGetCbm, _nTGetAl, _nTGetLa, _nTGetCm, SB1->B1_COD, _cGrpEst, _cTGetDes),_oDlgSku:End(),"") }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	// botao cancelar
	_oBtnCanc := TButton():New(006, 062, "Cancelar",_oPnlRodape,{|| _oDlgSku:End() }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	// ativa a janela
	ACTIVATE DIALOG _oDlgSku CENTERED

Return

// ** cálculo da cubabem
Static Function sfRetCbm(mvAlt, mvLar, mvCom)

	// variavel de retorno da cubagem
	local _nCubagem := ((mvAlt)*(mvLar)*(mvCom))

	// retorno
Return (_nCubagem)

// ** função para salvar os dados
Static Function sfConfirma(mvPesoB, mvPesoL, mvCbm, mvAlt, mvLar, mvCom, mvCodProd, mvGrpEst, mvDesc)

	// log descricao
	local _lLogDesc := .f.
	local _cDescAnt := ""

	// valido se os campos de dimensões estão preenchidos pro causa da cubagem
	If (Empty(mvAlt)).or.(Empty(mvLar)).or.(Empty(mvCom)).or.(Empty(mvPesoB)).or.(Empty(mvPesoL)).or.(Empty(mvGrpEst)).or.(Empty(mvDesc))
		MsgStop("Todos os campos são obrigatórios!")
		Return(.f.)
	EndIf

	// posiciono no produto - SB1
	dbSelectArea("SB1")
	SB1->(dbSetOrder(1)) // filial+codigo

	// posiciona o produto para gravar os dados
	If (SB1->(dbSeek(xFilial("SB1")+mvCodProd)))

		// valida se deve gerar log de alteracao de descricao
		_lLogDesc := (AllTrim(SB1->B1_DESC) <> AllTrim(mvDesc))
		_cDescAnt := SB1->B1_DESC

		// faz update dos dados na SB1
		Reclock("SB1",.f.)
		SB1->B1_PESBRU  := mvPesoB
		SB1->B1_PESO    := mvPesoL
		SB1->B1_ZCUBAGE := mvCbm
		SB1->B1_ZGRPEST := mvGrpEst
		SB1->B1_DESC    := mvDesc

		// libera a transação
		MsUnlock()

		// gera log da alteracao
		If (_lLogDesc)
			// insere o log
			U_FtGeraLog(xFilial("SB1"), "SB1", xFilial("SB1")+SB1->B1_COD, "Descrição Alterada De: "+AllTrim(_cDescAnt)+" -> "+AllTrim(mvDesc), "WMS")
		EndIf
	EndIf

	// posiciono no produto - SB5
	dbSelectArea("SB5")
	SB5->(dbSetOrder(1)) // filial+codigo

	// se encontro o complemento
	If (SB5->(dbSeek(xFilial("SB5")+SB1->B1_COD)))
		// faz update dos dados na SB5
		Reclock("SB5",.f.)
		SB5->B5_CEME    := SB1->B1_DESC // descriação do produto
		SB5->B5_ALTURLC := mvAlt
		SB5->B5_LARGLC  := mvLar
		SB5->B5_COMPRLC := mvCom
		SB5->B5_ALTURA  := mvAlt
		SB5->B5_LARG    := mvLar
		SB5->B5_COMPR   := mvCom
		// libera a transação
		MsUnlock()
	Else
		// inclui registros dos dados na SB5
		Reclock("SB5",.t.)
		SB5->B5_FILIAL  := xFilial("SB5")
		SB5->B5_COD     := SB1->B1_COD  //codigo do produto
		SB5->B5_CEME    := SB1->B1_DESC // descriação do produto
		SB5->B5_ALTURLC := mvAlt
		SB5->B5_LARGLC  := mvLar
		SB5->B5_COMPRLC := mvCom
		SB5->B5_ALTURA  := mvAlt
		SB5->B5_LARG    := mvLar
		SB5->B5_COMPR   := mvCom
		// libera a transação
		MsUnlock()
	EndIf

Return (.t.)

// ** função para validar o grupo de estoque digitado
Static Function sfVldGrpEst(mvGrpEst, mvSigla)
	// variavel de retorno
	local _lRet := .f.

	// se nao foi informado
	If Empty(mvGrpEst)
		Return(.t.)
	EndIf

	// cadastro de grupos de estoque por cliente
	dbSelectArea("Z36")
	Z36->(dbSetOrder(1)) // filial+codigo

	// se encontro o complemento retorno true
	_lRet := Z36->(dbSeek( xFilial("Z36")+mvSigla+mvGrpEst ))

	// se no encontrou, apresenta mensagem
	If ( ! _lRet )
		MsgStop("Não existe Grupo de Estoque cadastrado com esse código. Verifique!")
	EndIf

Return (_lRet)