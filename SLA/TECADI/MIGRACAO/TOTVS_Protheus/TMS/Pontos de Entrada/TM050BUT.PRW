#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Permite ao usuário incluir botões na EnchoiceBar na     !
!                  ! Inclusão de Notas-Fiscais do Cliente. Rotina:TMSA050    !
+------------------+---------------------------------------------------------+
!Uso               ! 1. Criado botão para importar informações de um XML.    !
!                  !                                                         !
+------------------+---------------------------------------------------------+
!Retorno           ! Array com os novos botões.                              !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe José Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 10/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function TM050BUT()

    Local _aBotoes:= {}
    Local nOpcx   := PARAMIXB[1]

    Aadd(_aBotoes,{'PRECO',{|| sfEscFile() },'Importar XML'}) //Adicionado um botão na EnchoiceBar

Return(_aBotoes)

//** tela para selecionar os arquivos XML.
Static Function sfEscFile()

	// lista de arquivos para importar
    private _vListaArq := {}
	// fontes utilizadas
    private _oFonte01 := TFont():New("Courier New",,16)
	// bloco executado no botao CONFIRMA
    private _bConfirma := {|| MsAguarde({|| sfPopuGrid() },"Gerando Informações ...")}

	// realiza a leitura das coordenadas da tela
    _oDlgImport := MsDialog():New(000,000,280,500,"Importar XML",,,.F.,,,,,,.T.,,,.F.)
	// selecao do arquivo
    _oSayTitulo := TSay():New(007,010,{||"Arquivos XML"},_oDlgImport,,,,,,.T.,,,040,30)
	// lista dos arquivos
    _oListArquivos := TListBox():New(017,010,,_vListaArq,230,100,,_oDlgImport,,,,.T.,,,_oFonte01,"",,,,,,, )
	// botao para selecao do arquivo
    _oBtnFile := TButton():New(122,010,"&Adiciona XML",_oDlgImport , {|| fGetFile() },40,11,,,,.T.)
	// funcao para validar os dados do XML
    _oBtnImpXml := TButton():New(122,055,"&Importar",_oDlgImport,{||Eval(_bConfirma)},40,11,,,,.T.)
	// botao para fechar a tela
    _oBtnSair := TButton():New(122,200,"&Fechar",_oDlgImport , {|| _oDlgImport:End() },40,11,,,,.T.)
	// ativa a tela

    Activate MSDialog _oDlgImport Centered

Return()

// ** funcao para selecionar o arquivo XML a ser importado
Static Function fGetFile()

	// arquivo
    local _cArquivo  := ""
	// busca arquivo
    _cArquivo        := cGetFile("Notas Fiscais|*.XML", ("Selecione arquivo..."),,,.T.,GETF_LOCALHARD,.F.)

	// copia o arquivo local para o servidor
    If ( ! Empty(_cArquivo))

        sfCopiaArq(@_cArquivo)

		// adiciona o arquivo na lista
        If (aScan(_vListaArq,_cArquivo)==0)
			// adiciona o arquivo
            aAdd(_vListaArq,_cArquivo)
			// atualiza a lista de arquivos
            _oListArquivos:SetItems(_vListaArq)
        Else
            Aviso("TM050BUT -> fGetFile","Este arquivo já consta na relação.",{"Fechar"})
        EndIf
    EndIf

Return()

// ** funcao que copia o arquivo local para o servidor
Static Function sfCopiaArq(mvArquivo)
    Local _cTmpArq	:= "" // nome do arquivo
    Local _cTmpExt	:= "" // extensao do arquivo

	// cria os diretorios necessarios
    MakeDir("\tecadi")
    MakeDir("\tecadi\XML")
    MakeDir("\tecadi\XML\TMS")
    MakeDir("\tecadi\XML\TMS\importados")
	// copia o arquivo do local para o servidor
    CpyT2S(mvArquivo,"\tecadi\XML\TMS",.f.)
	// ex: SplitPath ( < cArquivo>, [ @cDrive], [ @cDiretorio], [ @cNome], [ @cExtensao] )
    SplitPath(mvArquivo,,,@_cTmpArq,@_cTmpExt)
	// muda o caminho do arquivo para o servidor
    mvArquivo := "\tecadi\XML\TMS\"+_cTmpArq+_cTmpExt

Return(.T.)

// ** funcao para gerar as linhas com as informações do XML
Static Function sfPopuGrid()

    Local _nArqAtu   := 1
    Local nI         := 1
    Local _aTmpNotas := {}
    Local _nSeek     := 0
    Local _nPosChave := GDFIELDPOS("DTC_NFEID"  , aHeader )
    Local _nPosNuDoc := GDFIELDPOS("DTC_NUMNFC" , aHeader )
    Local _nPosSerie := GDFIELDPOS("DTC_SERNFC" , aHeader )
    Local _nPosEmiss := GDFIELDPOS("DTC_EMINFC" , aHeader )
    Local _nPosCodFi := GDFIELDPOS("DTC_CF"     , aHeader )
    Local _nPosVloum := GDFIELDPOS("DTC_QTDVOL" , aHeader )
    Local _nPosPesoB := GDFIELDPOS("DTC_PESO"   , aHeader )
    Local _nPosPesoL := GDFIELDPOS("DTC_PESLIQ" , aHeader )
    Local _nPosValNt := GDFIELDPOS("DTC_VALOR"  , aHeader )
    Local _nPosProdu := GDFIELDPOS("DTC_CODPRO" , aHeader )
    Local _nPosDescP := GDFIELDPOS("DTC_DESPRO" , aHeader )
    Local _nPosEmb   := GDFIELDPOS("DTC_CODEMB" , aHeader )
    Local _nPosDscEm := GDFIELDPOS("DTC_DESEMB" , aHeader )
    Local _cprod     := PADR(SuperGetMV("TC_PROCTRC",,""),TamSX3('B1_COD')[1])
    Local _cCodEmb   := PADR(SuperGetMV("TC_EMBCTRC",,""),TamSX3('DTC_CODEMB')[1])

	// validacao de arquivos selecionados
    If (Len(_vListaArq)==0)
        Aviso("TM050BUT -> sfPopuGrid","Nenhum arquivo selecionado para importação.",{"Fechar"})
        Return(.f.)
    EndIf

	//Se a variavel do produto não estiver vazia, realiza a validação do produto.
    If !(Empty(_cprod))
		// posiciona no produto
        dbSelectArea("SB1")
        SB1->(dbSetOrder(1)) //1-B1_FILIAL, B1_COD
        If !(SB1->(dbSeek( xFilial("SB1")+_cprod )))
            Aviso("TM050BUT -> sfPopuGrid","Produto invalido!" + CRLF + "Favor verificar parametro TC_PROCTRC",{"Fechar"})
            Return(.F.)
        EndIf
    EndIf

	// varre todos os arquivos selecionados
    For _nArqAtu := 1 to Len(_vListaArq)

		// funcao para validar as informacoes antes de importar
        MsAguarde({|| sfVldArquivo(_vListaArq[_nArqAtu],@_aTmpNotas) },"Validando dados...")

    Next _nArqAtu

	//Verificar se ja tem linha digitada Valida.
	//Se os campo de Nota,Serie,Chave estiver em branco a linha sera deletada.
	//Caso tiver apenas uma linha em branco o acols é limpo e inicia um novo.
    For _nArqAtu := 1 to Len(aCols)
        If Empty(aCols[_nArqAtu][1]) .And. Empty(aCols[_nArqAtu][2]) .And. Empty(aCols[_nArqAtu][3])
            If Len(aCols) == 1
                aDel(aCols,1)
                aSize(aCols,Len(aCols)-1)
            Else
                aCols[_nArqAtu,Len(aHeader)+1] := .T.
            EndIf
        EndIf
    Next _nArqAtu

    For _nArqAtu := 1 to Len(_aTmpNotas)

		//Verifica se a nota ja esta digitada.
        _nSeek := Ascan(aCols,{|x| !x[Len(x)] ;
            .And. PADR(x[GdFieldPos('DTC_NUMNFC')],TamSX3('DTC_NUMNFC')[1]) == PADR(_aTmpNotas[_nArqAtu][2],TamSX3('DTC_NUMNFC')[1]);
            .And. PADR(x[GdFieldPos('DTC_SERNFC')],TamSX3('DTC_SERNFC')[1]) == PADR(_aTmpNotas[_nArqAtu][3],TamSX3('DTC_SERNFC')[1]);
            .And. PADR(x[GdFieldPos('DTC_NFEID')] ,TamSX3('DTC_NFEID')[1])  == PADR(_aTmpNotas[_nArqAtu][1],TamSX3('DTC_NFEID')[1]) })

        If	_nSeek > 0
            Aviso("TM050BUT -> sfPopuGrid","Nota Fiscal " + _aTmpNotas[_nArqAtu][2] + "/" + _aTmpNotas[_nArqAtu][3]+" ja digitada!",{"Fechar"})
            LOOP
        EndIf

		//Adiciona uma linha em branco para colocar as informações do XML.
        AAdd(aCols,Array(Len(aHeader)+1))
        For nI:= 1 To Len(aHeader)
            If aHeader[nI,10] != "V"
                aCols[Len(aCols),nI]:= CriaVar(aHeader[nI,2])
            Else
                If aHeader[nI,2] == "DTC_ALI_WT"
                    aCols[Len(aCols),nI]:= "DTC"
                ElseIf aHeader[nI,2] == "DTC_REC_WT"
                    aCols[Len(aCols),nI]:= 0
                Else
                    aCols[Len(aCols),nI]:= CriaVar(aHeader[nI,2])
                EndIf
            EndIf
        Next nI

        aCols[Len(aCols),_nPosProdu] :=	_cprod
        aCols[Len(aCols),_nPosDescP] :=	Posicione("SB1",1,xFilial("SB1")+_cprod,"B1_DESC")
        aCols[Len(aCols),_nPosEmb]   := _cCodEmb
        aCols[Len(aCols),_nPosDscEm] := TABELA("MG",_cCodEmb)
        aCols[Len(aCols),_nPosChave] :=	_aTmpNotas[_nArqAtu][1]
        aCols[Len(aCols),_nPosNuDoc] :=	_aTmpNotas[_nArqAtu][2]
        aCols[Len(aCols),_nPosSerie] :=	_aTmpNotas[_nArqAtu][3]
        aCols[Len(aCols),_nPosEmiss] :=	_aTmpNotas[_nArqAtu][4]
        aCols[Len(aCols),_nPosCodFi] :=	_aTmpNotas[_nArqAtu][5]
        aCols[Len(aCols),_nPosVloum] :=	_aTmpNotas[_nArqAtu][6]
        aCols[Len(aCols),_nPosPesoB] :=	_aTmpNotas[_nArqAtu][7]
        aCols[Len(aCols),_nPosPesoL] :=	_aTmpNotas[_nArqAtu][8]
        aCols[Len(aCols),_nPosValNt] :=	_aTmpNotas[_nArqAtu][9]

        aCols[Len(aCols),Len(aHeader)+1] := .F.

    Next _nArqAtu

	// fecha a tela
    _oDlgImport:End()

Return(.T.)

// ** funcao que valida os Arquivos selecionados.
Static Function sfVldArquivo(mvArquivo, _aTmpNotas)
	// mensagens retornadas da funcao XmlParserFile
    local _cError := ""
    local _cWarning := ""
	// lista de produtos da nota (tem q ser private pra funcionar o Type)
    private _aItensNf := {}

	// verifica se foi selecionado algum arquivo
    If (Empty(mvArquivo))
        Aviso("TM050BUT -> sfVldArquivo","É obrigatório selecionar um arquivo.",{"Fechar"})
        Return(.f.)
    EndIf

	// abertura do arquivo XML e estrutura do objeto
    _oXML := XmlParserFile(mvArquivo, "_", @_cError, @_cWarning )

	// verifica erros no XML
    If (ValType(_oXML) != "O")
        Aviso("TM050BUT -> sfVldArquivo","Falha ao gerar Objeto XML : "+_cError+" / "+_cWarning,{"Fechar"})
        _oXML := Nil
        Return(.f.)
    Endif

	// monta a base da estrutura do XML de acordo com a versao
	// versao 1.10
    If (Type("_oXML:_NFEPROC:_NFE")=="O")
        _cBaseXML := "_oXML:_NFEPROC:_NFE:"
		// versao 2.00
    ElseIf (Type("_oXML:_NFE")=="O")
        _cBaseXML := "_oXML:_NFE:"
		// erro
    Else
        Aviso("TM050BUT -> sfVldArquivo","ATENÇÃO: Erro na estrutura do arquivo XML.",{"Fechar"})
        Return(.f.)
    EndIf

	// chave da NFe para consulta do status no SEFAZ
    If (Type("_oXML:_NFEPROC:_PROTNFE:_INFPROT:_CHNFE:TEXT")=="C")
        _cChaveNFe := _oXML:_NFEPROC:_PROTNFE:_INFPROT:_CHNFE:TEXT
		// se nao encontrou no campo especifico, tenta em outro
    ElseIf (Type("_oXML:_NFE:_INFNFE:_ID:TEXT")=="C")
        _cChaveNFe := SubStr(_oXML:_NFE:_INFNFE:_ID:TEXT,4)
    EndIf

	// nao encontrou a chave da NFe
    If (Empty(_cChaveNFe))
        If (Aviso("TM050BUT -> sfVldArquivo","Não foi possível encontrar a chave da nota fiscal. Deseja continuar a importação sem verificar a nota?",{"Continuar","Cancelar"})==2)
            Return(.T.)
        EndIf
    EndIf

	// prepara e padroniza o numero, serie e chave da nota
    _cChaveNFe  := PADR(_cChaveNFe,TamSX3('F1_CHVNFE')[1])
    _cTmpNota	:= PADL((&(_cBaseXML+"_INFNFE:_IDE:_NNF:TEXT"))  ,TamSX3('F1_DOC')[1],'0')
    _cTmpSerie	:= PADR((&(_cBaseXML+"_INFNFE:_IDE:_SERIE:TEXT")),TamSX3('F1_SERIE')[1])

	// data de emissao da nota importada
    If (TYPE(_cBaseXML+"_INFNFE:_IDE:_DHEMI:TEXT") == "C") // 3.0
        _dEmissNFe := &(_cBaseXML+"_INFNFE:_IDE:_DHEMI:TEXT")
        _dEmissNFe := SUBSTR(_dEmissNFe,1,10)
    ElseIf (TYPE(_cBaseXML+"_INFNFE:_IDE:_DEMI:TEXT") == "C") // 2.0
        _dEmissNFe := &(_cBaseXML+"_INFNFE:_IDE:_DEMI:TEXT")
    Else
        Aviso("TM050BUT -> sfVldArquivo","ATENÇÃO: Data de Emissão da NF inválida!",{"Fechar"})
        Return(.f.)
    EndIf
	// converte a data (Str to Date)
    _dEmissNFe := StoD(StrTran(_dEmissNFe,"-",""))

    If (TYPE(_cBaseXML+"_INFNFE:_TRANSP:_VOL:_QVOL:TEXT") == "C")
        _nVolumes := Val(StrTran(&(_cBaseXML+"_INFNFE:_TRANSP:_VOL:_QVOL:TEXT")  , ",", "." ))
    Else
        _nVolumes := 0
    EndIf

    If (TYPE(_cBaseXML+"_INFNFE:_TRANSP:_VOL:_PESOB:TEXT") == "C")
        _nPesoB   := Val(StrTran(&(_cBaseXML+"_INFNFE:_TRANSP:_VOL:_PESOB:TEXT") , ",", "." ))
    Else
        _nPesoB := 0
    EndIf

    If (TYPE(_cBaseXML+"_INFNFE:_TRANSP:_VOL:_PESOL:TEXT") == "C")
        _nPesoL   := Val(StrTran(&(_cBaseXML+"_INFNFE:_TRANSP:_VOL:_PESOL:TEXT") , ",", "." ))
    Else
        _nPesoL := 0
    EndIf

    If (TYPE(_cBaseXML+"_INFNFE:_TOTAL:_ICMSTOT:_VNF:TEXT") == "C")
        _nValNot  := Val(StrTran(&(_cBaseXML+"_INFNFE:_TOTAL:_ICMSTOT:_VNF:TEXT"), ",", "." ))
    Else
        _nValNot := 0
    EndIf

	// carrega os itens da nota
    _aItensNf := &(_cBaseXML+"_INFNFE:_DET")
	// se nao conseguiu carrega os itens corretamente
    If (ValType(_aItensNf)<>'A')
        _aItensNf := {}
        aAdd(_aItensNf,&(_cBaseXML+"_INFNFE:_DET"))
    Endif
	//Pega a CFOP do primeiro produto da Nota.
    _cCodFis := _aItensNf[1]:_PROD:_CFOP:TEXT

    If Empty(_nVolumes) .Or. Empty(_nPesoB) .Or. Empty(_nPesoL)
        Aviso("TM050BUT -> sfVldArquivo","ATENÇÃO: XML sem informações de Volume e Peso!" + CRLF + "Favor Informar",{"Fechar"})
    EndIf

	// adiciona a nota para validacao de itens
    aAdd(_aTmpNotas,{_cChaveNFe,_cTmpNota,_cTmpSerie,_dEmissNFe,_cCodFis,_nVolumes,_nPesoB,_nPesoL,_nValNot})

Return(.T.)