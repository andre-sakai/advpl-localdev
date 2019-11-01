#Include "Totvs.ch"
#Include "TopConn.ch"
#Include "Ap5Mail.ch"
#Include "TbiConn.ch"
#Include "shell.ch"

/*-----------------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                              !
+------------------+-----------------------------------------------------------------+
!Descricao         ! Funcoes Genericas utilizadas em todo sistema                    !
!                  ! 1. Monta Grupo de Perguntas (SX1)                               !
!                  ! 2. Executa Query e retorna o resultado de 1 campo               !
!                  ! 3. Funcao que executa Query retorna em forma de Array           !
!                  !    (vetor)                                                      !
!                  ! 4. Envio de mensagens por e-mail FTMAIL (eap)                   !
!                  ! 5. Retorna Descricao de Campos ComboIBox                        !
!                  ! 6. Retorna FILIAL e MATRICULA do funcionario) do usuario        !
!                  ! 7. Pesquisar Arquivos (filtro de extensao) em pastas            !
!                  ! 8. Funcao que retorna a RIC de Saida                            !
!                  ! 9. Funcao para geracao de log customizado (SZN)                 !
!                  ! 10. Funcao para consultar/visualizar Log customizado            !
!                  ! 11. Funcao que atualiza os registros do arquivo temporario      !
!                  !     conforme resultado da Query                                 !
!                  ! 12. Funcao que preenche de zeros a esquerda de numero           !
!                  ! 13. Funcao que troca RPO quente                                 !
!                  ! 14. Funcao que Retorna a pasta do Desktop do Usuário            !
!                  ! 16. Envio de mensagens por e-mail (eap)                         !
!                  ! 17. funcao que salva parametros atuais do grupo de perguntas    !
!                  ! 18. funcao que restaura parametros atuais do grupo de perguntas !
+------------------+-----------------------------------------------------------------+
!Data de Criacao   ! 09/2011                                                         !
+------------------+----------------------------------------------------------------*/

// ** 1. Função que Monta o Grupo de Perguntas
User Function FtCriaSX1(mvPerg,vList,lDel)
	/*
	Função excluída pois não pode mais haver criação de perguntas na SX1 direto por fontes.
	Conforme orientação da TOTVS, as perguntas devem ser criadas via configurador.
	*/

Return

// ** 2. Funcao que executa Query passada como parametro e retorna o conteudo do campo CAMPO
User Function FtQuery(mvQuery)
	Local cAliasX := Alias()
	Local aAreaAtu := GetArea()
	Local cCampo := ""

	If Select("QRYTMP") <> 0
		QRYTMP->(DbCloseArea())
	EndIf
	TcQuery mvQuery New Alias "QRYTMP"

	DbSelectArea("QRYTMP")
	QRYTMP->(DbGoTop())

	// define campo de retorno
	cCampo := QRYTMP->(FieldName(1))
	// conteudo do retorno
	xRetorno := QRYTMP->(&cCampo)

	// fecha query
	QRYTMP->(DbCloseArea())

	If !Empty(cAliasX)
		DbSelectArea(cAliasX)
		RestArea(aAreaAtu)
	EndIf

Return(xRetorno)

// ** 3. Funcao que executa Query retorna em forma de Array (vetor)
User Function SqlToVet(mvQuery,mvCpoData,_aStruQry)
	Local aAreaAtu := GetArea()
	//Local _aStruQry := {}
	Local aRet := {}
	Local nX := 1
	Local cAliasTMP := GetNextAlias()
	Local lUnqCol := .f.
	Local cContCmp

	If (Select(cAliasTMP)!=0)
		dbSelectArea(cAliasTMP)
		dbCloseArea()
	EndIf

	// campos do tipo data
	Default mvCpoData := {}

	// zera variavel
	_aStruQry := {}

	// executa a query
	dbUseArea(.T., "TOPCONN", TcGenQry(,,mvQuery), cAliasTMP, .F., .T.)
	// estrutura da query
	_aStruQry := (cAliasTMP)->(DbStruct())
	// verifica se é apenas uma coluna
	lUnqCol := (Len(_aStruQry)==1)

	dbSelectArea(cAliasTMP)
	(cAliasTMP)->(dbGoTop())

	While (cAliasTMP)->(!Eof())

		// adiciona uma linha
		If (lUnqCol)
			// pega o conteudo do campo
			cContCmp := (cAliasTMP)->(FieldGet((cAliasTMP)->(FieldPos(_aStruQry[nX,1]))))
			// verifica se é campo logico/boleano
			If (Upper(AllTrim(cContCmp))==".T.").or.(Upper(AllTrim(cContCmp))==".F.")
				cContCmp := (Upper(AllTrim(cContCmp))==".T.")
				// campo tipo data
			ElseIf (aScan(mvCpoData,AllTrim(_aStruQry[nX,1]))>0)
				cContCmp := StoD(cContCmp)
			EndIf
			// atualiza variavel de retorno
			aAdd(aRet,cContCmp)
		Else
			aAdd(aRet, Array(Len(_aStruQry)))
			// atualiza o conteudo dos campos
			For nX := 1 to Len(_aStruQry)
				// pega o conteudo do campo
				cContCmp := (cAliasTMP)->(FieldGet((cAliasTMP)->(FieldPos(_aStruQry[nX,1]))))
				// verifica se é campo logico/boleano
				If (Upper(AllTrim(cContCmp))==".T.").or.(Upper(AllTrim(cContCmp))==".F.")
					cContCmp := (Upper(AllTrim(cContCmp))==".T.")
					// campo tipo data
				ElseIf (aScan(mvCpoData,AllTrim(_aStruQry[nX,1]))>0)
					cContCmp := StoD(cContCmp)
				EndIf
				// atualiza variavel de retorno
				aRet[Len(aRet),nX] := cContCmp
			Next nX
		EndIf

		// proximo item
		(cAliasTMP)->(dbSkip())
	EndDo
	// fecha o alias
	dbSelectArea(cAliasTMP)
	dbCloseArea()

	// restaura area atual
	RestArea(aAreaAtu)

Return(aRet)

// ** 4. Cria e-mail e coloca na fila de envio
User Function FtMail(mvMensagem, mvTitulo, mvDestinat, mvArquivos, mvMailFrom, mvMailPass, mvMailCont)

	Local _cAccount  := GetMV("MV_RELFROM")
	Local _cPassword := GetMV("MV_RELPSW")
	Local _cEnvia    := GetMV("MV_RELACNT")
	Local _nX
	Local _cTmpArq    := "" // nome do arquivo
	Local _cTmpExt    := "" // extensao do arquivo
	Local _cArquivos  := "" //arquivos anexos
	Local _cControl   := ""
	Local _cLocalArq  := ""

	// pastas necessarias
	local _aTmpPastas := {}
	local _cTmpPastas := ""

	// copia oculta
	local _cMailBCC    := ""
	// defalut
	Default mvArquivos := {}
	Default mvMailFrom := ""
	Default mvMailPass := ""
	Default mvMailCont := ""

	// se tentar gerar um e-mail sem destinatário, cancela a operação
	If ( Empty(mvDestinat) )
		Return(.F.)
	EndIf

	// geracao do controle de numeracao de mensagens
	_cControl := GetSX8Num("Z46","Z46_NCONTR")
	Z46->(ConfirmSX8())

	// define o local de armazenagem de anexos
	_cLocalArq	:= "\mail\anexos\"+cEmpAnt+"\"+AllTrim(_cControl)+"\"
	// organiza as pastas necessarias
	_aTmpPastas := Separa(_cLocalArq, "\", .f.)

	// verifica se foi informado outra conta de email para envio
	If (!Empty(mvMailFrom)).and.(!Empty(mvMailPass)).and.(!Empty(mvMailCont))
		_cAccount  := mvMailFrom
		_cPassword := mvMailPass
		_cEnvia    := mvMailCont
	EndIf

	// quando for nota fiscal de servicos eletronica, manda email oculto
	If (("NFS-E" $ AllTrim(Upper(mvTitulo))).Or.("FATURA" $ AllTrim(Upper(mvTitulo)))).and.(AllTrim(Upper(_cAccount))==AllTrim("NFSE@TECADI.COM.BR"))
		// agora pega o email via parâmetro
		_cMailBCC := SUPERGETMV("TC_BCCNFSE",.f.,"ti@tecadi.com.br")
	EndIf

	// verifica se tem anexos
	If (Len(mvArquivos)>0)
		// cria a pasta servidor, pois soh pode anexar arquivos que estao no server
		For _nX := 1 to Len(_aTmpPastas)
			// prepara barra de endereco
			_cTmpPastas += "\"+_aTmpPastas[_nX]
			// cria pasta/caminho
			MakeDir(_cTmpPastas)
		Next _nX

		// copia os arquivos do remote pro servidor
		For _nX := 1 to Len(mvArquivos)
			// verifica se deve copiar o arquivo para o servidor PROTHEUS
			If (Left(mvArquivos[_nX],1) != "\")
				// copia os arquivos para a pasta do servidor
				CpyT2S(mvArquivos[_nX],_cLocalArq,.f.)
				// copia o arquivo dentro do servidor PROTHEUS
			Else
				// extrai informacoes do arquivo
				// ex: SplitPath ( < cArquivo>, [ @cDrive], [ @cDiretorio], [ @cNome], [ @cExtensao] )
				SplitPath(mvArquivos[_nX],,,@_cTmpArq,@_cTmpExt)
				// copia o arquivo pra pasta de anexos dos emails
				__COPYFILE(mvArquivos[_nX],_cLocalArq+_cTmpArq+_cTmpExt)
			EndIf
		Next _nX
		// retorna a lista de arquivos do diretorio Do Email
		mvArquivos := Directory(_cLocalArq+"*.*")
		// Adiciona um attach
		For _nX := 1 to Len(mvArquivos)
			// atualiza variavel com o caminho dos arquivos
			_cArquivos +='||'+_cLocalArq+mvArquivos[_nX,1]
		Next _nX
	Endif

	// insere Registro na Tabela de Mensagens.
	Dbselectarea("Z46")
	Reclock("Z46",.T.)
	Z46->Z46_FILIAL := xFilial("Z46")
	Z46->Z46_NCONTR := _cControl               //CONTROLE DE ENVIO
	Z46->Z46_USUARI := __cUserId               //USUARIO
	Z46->Z46_DTMSG  := date()                  //Data da geraçao da Mensagem
	Z46->Z46_HRMSG  := time()                  //hora
	Z46->Z46_ROTINA := Funname()               //funcao q gerou
	Z46->Z46_TITMSG := mvTitulo                //titulo
	Z46->Z46_DESTIN := mvDestinat              //emaildest
	Z46->Z46_CCOPIA := _cMailBCC               //com copia
	Z46->Z46_MENSAG := mvMensagem              //mensagem
	Z46->Z46_ANEXOS := _cArquivos              //arquivos anexados
	Z46->Z46_MAILDE := _cAccount               //conta
	Z46->Z46_CONTAE := _cEnvia                 //email de envio
	Z46->Z46_SENHA  := Embaralha(_cPassword,0) //senha conta
	Z46->(MsUnlock())

	// gera log
	U_FtGeraLog(xFilial("Z46"),"Z46", _cControl, "E-mail gerado com sucesso", "CFG", "")

Return (.T.)

// 5. Retorna Descricao de Campos ComboBox
// PARAMENTROS
// mvCampo		= CAMPO CHAVE
// mvConteudo	= CONTEUDO DO CAMPO
// mvPesq		= INDICE DE PESQUISA (1,2,3)
// mvRet		= INDICE DE RETORNO (1,2,3)
User Function FtX3CBox(mvCampo,mvConteudo,mvPesq,mvRet)
	Local _aAreaSX3 := SX3->(GetArea())
	// retorno em array
	// 1 -> S=Sim
	// 2 -> S
	// 3 -> Sim
	Local _aCbox := RetSx3Box(Posicione('SX3',2,mvCampo,'X3CBox()'),,,TamSx3(mvCampo)[1])
	Local _nPos  := aScan( _aCbox , {|x| x[mvPesq] == mvConteudo } )
	Local _cRet  := If(_nPos>0,_aCbox[_nPos,mvRet],"")
	// restaura area inicial
	RestArea(_aAreaSX3)
Return(_cRet)

// 6. Funcao que retornar o a FILIAL e MATRICULA (funcionario) do usuario
User Function FtRetMat(mvCodUser)
	// variavel de retorno
	// 1. Filial
	// 2. Matricula
	local _aRet := {CriaVar("RA_FILIAL",.f.),;
	CriaVar("RA_MAT",.f.)}
	// area inicial
	local _aAreaAtu := GetArea()
	// variaveis temporarias
	local _cTmpRet
	local _nPosInic := 1
	// tamanho do campo EMPRESA
	local _nTamEmp := Len(SM0->M0_CODIGO)
	// tamanho do campo FILIAL
	local _nTamFil := TamSx3("RA_FILIAL")[1]
	// tamanho do campo MATRICULA
	local _nTamMat := TamSx3("RA_MAT")[1]

	// ordem de pesquisa por 1-Codigo
	PswOrder(1)
	// pesquisa o usuario
	If (PswSeek(mvCodUser))
		// retorna Empresa + Filial + Matricula
		_cTmpRet := PswRet(1)[1][22]
		// define a proxima posicao inicial de pesquisa
		_nPosInic += _nTamEmp
		// retorna o campo filial
		_aRet[1] := SubStr(_cTmpRet,_nPosInic,_nTamFil)
		// define a proxima posicao inicial de pesquisa
		_nPosInic += _nTamFil
		// retorna o campo matricula
		_aRet[2] := SubStr(_cTmpRet,_nPosInic,_nTamMat)
	EndIf

	// restaura area
	RestArea(_aAreaAtu)
Return(_aRet)

// 7. Funcao para pesquisar Arquivos (filtro de extensao) em pastas
User Function FtOpFile(mvExtensao,mvDefPath,mvMudaDir,mvLocal,mvNetWork,mvServidor)
	// opcoes de local
	local _nOpcoes := 0
	// path de retorno do arquivo
	local _cNewPathArq := ""
	// variavel temporaria
	local _cTmpVar := AllTrim(ReadVar())
	// local padrao
	Default mvExtensao := "Arquivos|*.*"
	Default mvDefPath  := "c:\"
	Default mvMudaDir  := .f.
	Default mvLocal    := .f.
	Default mvNetWork  := .f.
	Default mvServidor := .f.

	// define opcoes de pastas
	If (!mvMudaDir)
		_nOpcoes += GETF_NOCHANGEDIR
	EndIf
	If (mvLocal)
		_nOpcoes += GETF_LOCALHARD
	EndIf
	If (mvNetWork)
		_nOpcoes += GETF_NETWORKDRIVE
	EndIf
	// abertura do arquivo
	_cNewPathArq := cGetFile(mvExtensao,"Abrir Arquivo...",nil,mvDefPath,.T.,_nOpcoes,mvServidor)

	// verifica se encontou o arquivo
	If (!Empty(_cNewPathArq))
		// atualiza a variavel
		&(_cTmpVar) := _cNewPathArq
	EndIf

Return(.t.)

// 8. Funcao que retorna a RIC de Saida
User Function FtRetRIC(mvRIC,mvFilial)
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSZ3 := SZ3->(GetArea())
	// variaveis temporarias
	local _cQrySZ3
	// variavel de retorno
	local _cRetRIC := CriaVar("Z3_RIC",.f.)

	// valor padrao da filial
	Default mvFilial := xFilial("SZ3")

	// pesquisa a RIC recebida como parametro
	dbSelectArea("SZ3")
	SZ3->(dbOrderNickName("Z3_RIC")) // 4-Z3_FILIAL, Z3_RIC
	If SZ3->(dbSeek( mvFilial+mvRIC ))
		// se for movimento de ENTRADA, pesquisa a SAIDA
		If (SZ3->Z3_TPMOVIM=="E").and.(!Empty(SZ3->Z3_DTSAIDA))
			// monta a query
			_cQrySZ3 := "SELECT Z3_RIC FROM "+RetSqlName("SZ3")+" SZ3 (nolock)  "
			_cQrySZ3 += "WHERE Z3_FILIAL = '"+mvFilial+"' AND SZ3.D_E_L_E_T_ = ' ' "
			_cQrySZ3 += "AND Z3_PROGRAM = '"+SZ3->Z3_PROGRAM+"' AND Z3_ITEPROG = '"+SZ3->Z3_ITEPROG+"' "
			_cQrySZ3 += "AND Z3_CONTAIN = '"+SZ3->Z3_CONTAIN+"' "
			_cQrySZ3 += "AND Z3_DTMOVIM = '"+DtoS(SZ3->Z3_DTSAIDA)+"' "
			_cQrySZ3 += "AND Z3_HRMOVIM = '"+SZ3->Z3_HRSAIDA+"'
			_cQrySZ3 += "AND Z3_TPMOVIM = 'S'"
			// executa a query
			_cRetRIC := U_FtQuery(_cQrySZ3)

			// se for movimento de SAIDA, pesquisa a ENTRADA
		ElseIf (SZ3->Z3_TPMOVIM=="S")
			// monta a query
			_cQrySZ3 := "SELECT Z3_RIC FROM "+RetSqlName("SZ3")+" SZ3 (nolock)  "
			_cQrySZ3 += "WHERE Z3_FILIAL = '"+mvFilial+"' AND SZ3.D_E_L_E_T_ = ' ' "
			_cQrySZ3 += "AND Z3_PROGRAM = '"+SZ3->Z3_PROGRAM+"' AND Z3_ITEPROG = '"+SZ3->Z3_ITEPROG+"' "
			_cQrySZ3 += "AND Z3_CONTAIN = '"+SZ3->Z3_CONTAIN+"' "
			_cQrySZ3 += "AND Z3_DTSAIDA = '"+DtoS(SZ3->Z3_DTMOVIM)+"' "
			_cQrySZ3 += "AND Z3_HRSAIDA = '"+SZ3->Z3_HRMOVIM+"'
			_cQrySZ3 += "AND Z3_TPMOVIM = 'E'"
			// executa a query
			_cRetRIC := U_FtQuery(_cQrySZ3)

		EndIf

	EndIf

	// restaura area inicial
	RestArea(_aAreaSZ3)
	RestArea(_aAreaAtu)

Return(_cRetRIC)

// ** 9. Grava LOG (SZN) - Funcao para geracao de log customizado
User Function FtGeraLog(mvFilExt, mvTabela, mvChave, mvDescri, mvDepto, mvProcesso, mvCodUser)
	// area inicial
	local _aAreaAtu := GetArea()
	// codigo e nome do usuario
	local _cCodUser := ""
	local _cNomUser := ""

	// usuário padrao
	Default mvCodUser := __cUserID

	// define codigo e nome do usuario
	_cCodUser := IIf( (Empty(mvCodUser)), "000000"  , mvCodUser )
	_cNomUser := IIf( (Empty(mvCodUser)), "WorkFlow", UsrFullName(mvCodUser) )

	// insere registro
	DBSelectArea("SZN")
	RecLock("SZN",.T.)
	SZN->ZN_FILIAL := mvFilExt
	SZN->ZN_TABELA := mvTabela
	SZN->ZN_CHAVE  := mvChave
	SZN->ZN_DATA   := Date()
	SZN->ZN_HORA   := Time()
	SZN->ZN_IDUSER := _cCodUser
	SZN->ZN_NOME   := _cNomUser
	SZN->ZN_DESCRI := mvDescri
	SZN->ZN_PROCES := mvProcesso
	SZN->ZN_DEPTO  := mvDepto
	SZN->ZN_NMCOMP := GetComputerName()
	SZN->ZN_IPCOMP := GetClientIP()
	SZN->ZN_MODULO := cModulo
	MsUnLock("SZN")

	// restaura area inicial
	RestArea(_aAreaAtu)
Return(.t.)

// ** 10. Consulta Log (SZN) - Funcao para visualizar Log customizado
User Function FtConsLog(mvFilExt, mvTabela, mvChave)
	// area inicial
	local _aAreaAtu := GetArea()
	local _cQrySZN
	local _aLogHead := {}
	local _aLogCols := {}
	// variaveis da tela
	local _oDlgDetLog, _oPnlCabec
	// fontes utilizadas
	Private _oFnt01 := TFont():New("Tahoma",,18,,.t.)

	// abre tabela de LOG
	dbSelectArea("SZN")

	// monta a query
	_cQrySZN := "SELECT ZN_DATA, ZN_HORA, ZN_NOME, ZN_DESCRI, '.F.' IT_DEL "
	_cQrySZN += "FROM "+RetSQLName("SZN")+" SZN (nolock)  "
	// filtro
	_cQrySZN += "WHERE ZN_FILIAL = '" +mvFilExt+ "' AND SZN.D_E_L_E_T_ <> '*' "
	_cQrySZN += "AND ZN_TABELA = '" +mvTabela+ "' "
	_cQrySZN += "AND ZN_CHAVE  = '" +mvChave+ "' "
	// ordem dos dados
	_cQrySZN += "ORDER BY ZN_DATA, ZN_HORA, SZN.R_E_C_N_O_"

	memoWrit("c:\query\ftconslog.txt",_cQrySZN)

	// adiciona o conteudo da query para um array
	_aLogCols := U_SqlToVet(_cQrySZN,{"ZN_DATA"})

	// mensagem quando nao houver LOG
	If (Len(_aLogCols)==0)
		// apresenta a mensagem na tela
		Aviso(	"TCFGX001 -> FtConsLog -> "+AllTrim(FunName()),;
		"Não há dados disponíveis no LOG"+CRLF+CRLF+CRLF+;
		"Filial: "+mvFilExt+" / Tabela: "+mvTabela+CRLF+;
		"Chave: "+mvChave,;
		{"Fechar"},3)

		// restaura area inicial
		RestArea(_aAreaAtu)
		Return(.f.)
	EndIf

	// define todos os campos do header
	aAdd(_aLogHead,{"Data"      ,"ZN_DATA"   ,PesqPict("SZN","ZN_HORA")   ,TamSx3("ZN_DATA")[1]  , 0,Nil,Nil,"D",Nil,"R" })
	aAdd(_aLogHead,{"Hora"      ,"ZN_HORA"   ,PesqPict("SZN","ZN_HORA")	  ,TamSx3("ZN_HORA")[1]  , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aLogHead,{"Usuário"   ,"ZN_NOME"   ,PesqPict("SZN","ZN_NOME")   ,TamSx3("ZN_NOME")[1]  , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aLogHead,{"Descrição" ,"ZN_DESCRI" ,PesqPict("SZN","ZN_DESCRI") ,TamSx3("ZN_DESCRI")[1], 0,Nil,Nil,"C",Nil,"R" })

	// monta a tela com os detalhes do LOG
	_oDlgDetLog := MSDialog():New(000,000,400,700,"Detalhes do Log",,,.F.,,,,,,.T.,,,.T. )
	//_oDlgDetLog:lMaximized := .T.

	// cria o panel com o titulo
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgDetLog,,.F.,.F.,,,022,022,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// titulo
	_oSayDetTit  := TSay():New(006,010,{||"Consulta de LOG's"},_oPnlCabec,,_oFnt01,.F.,.F.,.F.,.T.,CLR_GREEN)
	// botao para fechar a tela
	_oBtnFechar := TButton():New(004,300,"Fechar",_oPnlCabec,{|| _oDlgDetLog:End() },030,015,,_oFnt01,,.T.,,"",,,,.F. )

	// browse com os detalhes do LOG
	_oBrwDetLog := MsNewGetDados():New(000,000,1000,1000,Nil,'AllwaysTrue()','AllwaysTrue()','',,,,'AllwaysTrue()','','AllwaysTrue()',_oDlgDetLog,_aLogHead,_aLogCols)
	_oBrwDetLog:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativacao da tela
	_oDlgDetLog:Activate(,,,.T.,)

	// restaura area inicial
	RestArea(_aAreaAtu)

Return

// ** 11. Funcao que atualiza os registros do arquivo temporario conforme resultado da Query
User Function SqlToTrb(mvQuery, mvStruTmp, mvAliasTmp)
	Local _nI,_nJ
	Local _aStruQry := {}

	// fecha alias
	If Select("_QRYTMP") <> 0
		DbSelectArea("_QRYTMP")
		_QRYTMP->(DbCloseArea())
	EndIf

	// executa query
	dbUseArea(.T., "TOPCONN", TCGenQry(,,mvQuery),"_QRYTMP", .F., .T.)

	// retorna a estrutura da QUERY
	_aStruQry := _QRYTMP->(DbStruct())

	// atualiza as tabelas do TOP
	For _nJ := 1 to Len(mvStruTmp)
		// verifica o tipo do campo, e se existe na estrutura da query
		If ( ! (mvStruTmp[_nJ,2] $ 'CM') ).and.(aScan(_aStruQry, {|x| AllTrim(x[1]) == AllTrim(mvStruTmp[_nJ,1]) } ) > 0)
			TCSetField("_QRYTMP", mvStruTmp[_nJ,1], mvStruTmp[_nJ,2], mvStruTmp[_nJ,3], mvStruTmp[_nJ,4])
		EndIf
	Next _nJ

	// varre todos os registros, atualizando o TRB
	_QRYTMP->(DbGoTop())
	While ! _QRYTMP->(Eof())
		// atualiza todos os campos
		(mvAliasTmp)->(DbAppend())
		For _nI := 1 To Len(_aStruQry)
			If ((mvAliasTmp)->(FieldPos(_aStruQry[_nI,1])) > 0).and.(_aStruQry[_nI,2] <> 'M')
				(mvAliasTmp)->(FieldPut(FieldPos(_aStruQry[_nI,1]),_QRYTMP->(FieldGet(_QRYTMP->(FieldPos(_aStruQry[_nI,1]))))))
			Endif
		Next _nI
		_QRYTMP->(DbSkip())
	End
	// fecha alias da QUERY
	_QRYTMP->(dbCloseArea())
	// seleciona o TRB
	DbSelectArea(mvAliasTmp)

Return Nil

// ** 12. funcao q preenche de zeros a esquerda de numero (incluir como validação de campo)
User Function FtStrZero(mvTamanho, mvConteudo)
	local mvVariavel := ReadVar()
	local mvContVar  := &(mvVariavel)
	local _nX  := 0
	local _lOk := .f.

	// valor padrao
	Default mvTamanho  := Len(mvContVar)
	Default mvConteudo := Nil

	// atualiza variavel
	If ( ! Empty(mvVariavel) )
		mvConteudo := mvContVar
	EndIf

	// somente se for caracter (texto)
	If (ValType(mvConteudo)=="C").and.( ! Empty(mvConteudo) )

		// remove todos os espacos em branco
		mvConteudo := StrTran(mvConteudo," ","")
		// verifica se contem somente numeros
		For _nX := 1 to Len(mvConteudo)
			// valida caracteres
			If (SubStr(mvConteudo,_nX,1)<"0").or.(SubStr(mvConteudo,_nX,1)>"9")
				Return(.t.)
			EndIf
			// status de informacao ok
			_lOk := .t.
		Next _nX

		// se tiver tudo correto, executa funcao para completar de zeros a esquerda
		If (_lOk)
			mvConteudo := StrZero(Val(mvConteudo),mvTamanho)
		EndIf

		// se tem variavel, atualiza
		If ( ! Empty(mvVariavel) )
			&mvVariavel := mvConteudo
		EndIf

	EndIf

Return(.t.)

// ** 13. troca RPO quente
User Function FtChgRpo()
	// local APO compilar
	local _cLocalComp := "E:\TOTVS11\Microsiga\Protheus\apo\00compilar\"
	// local APO producao
	local _cLocalProd := "E:\TOTVS11\Microsiga\Protheus\apo\01tecadi\"
	// pastas disponiveis
	local _aPastasAPO := {}
	local _cPastasAPO := ""
	// base do BIN
	local _cBaseBIN := "E:\TOTVS11\Microsiga\Protheus\bin\"
	// configuracao dos LOADs habilitados
	local _aCfgServer := {{"MASTER",_cBaseBIN+"appserver_master"},;
	{"SLAVE1",_cBaseBIN+"appserver_slave1"},;
	{"SLAVE2",_cBaseBIN+"appserver_slave2"},;
	{"SLAVE3",_cBaseBIN+"appserver_slave3"},;
	{"SLAVE4",_cBaseBIN+"appserver_slave4"},;
	{"SLAVE5",_cBaseBIN+"appserver_slave5"} }
	// APO atual
	local _cAPOAtual := GetPvProfString('TECADI','SourcePath','ErroGeral',_aCfgServer[1][2]+'\appserver.ini')

	// variaveis temporarias
	local _nRpo
	local _cTmpRpo

	// verifica possibilidade de pastas
	For _nRpo := 1 to 9
		// define caminho
		_cTmpRpo := _cLocalProd+"apo_"+Str(_nRpo,1)

		// verifica se a pasta existe
		If ExistDir(_cTmpRpo)
			// atualiza lista
			aAdd(_aPastasAPO,_cTmpRpo)
		EndIf
	Next _nRpo

	// seta o ambiente com a empresa 01 filial 101
	RpcSetEnv("01","101")

	// monta o dialogo
	_oWndIntegr := MSDialog():New(000,000,400,600,"Troca de RPO",,,.F.,,,,,,.T.,,,.T. )

	// panel para os botoes de comando
	_oPnlBtnOpr := TPanel():New(000,000,Nil,_oWndIntegr,,.F.,.F.,,,26,26,.T.,.F. )
	_oPnlBtnOpr:Align := CONTROL_ALIGN_TOP

	// -- botao Lançamentos
	_oBtnConfInt := TButton():New(005,005,"Lançamento Manual",_oPnlBtnOpr,{|| sflancMa(),_oBrwSRC:oBrowse:Refresh() },070,015,,,,.T.,,"",,,,.F. )

	// -- botao Confirmar
	_oBtnConfInt := TButton():New(005,085,_cAPOATual,_oPnlBtnOpr,{|| sfGeraLan() },070,015,,,,.T.,,"",,,,.F. )

	_oCmbBlqRecHum := TComboBox():New(043,020,{|u| If(PCount()>0,_cPastasAPO:=u,_cPastasAPO)},_aPastasAPO,210,010,_oWndIntegr,,,,,,.T.,,"",,{|| .t. },,,,,_cPastasAPO)

	// ativa a tela
	ACTIVATE MSDIALOG _oWndIntegr CENTERED

	//Limpa o ambiente, liberando a licença e fechando as conexões
	RpcClearEnv()

Return

// ** 14. retorno caminho desktop do usuario
User Function FtGetFld(mvTpRet)
	// variavel de retorno
	local _cRetDesk := "c:\"
	// retorna a pasta temporaria da maquina
	local _cPathTemp := AllTrim(GetTempPath())
	local _aPathTemp := Separa(_cPathTemp,"\")
	// nome do usuario logado
	local _cLogUser := LogUserName()
	local _cArqCompl := ""

	// retorno da pasta do usuario
	If (mvTpRet == "0")
		// unidade
		_cRetDesk := _aPathTemp[1] + "\"
		// pasta usuarios/users
		_cRetDesk += _aPathTemp[2] + "\"
		// pasta nome do usuario
		_cRetDesk += _cLogUser

	EndIf

Return(_cRetDesk)

// ** 16. Envio de mensagens por e-mail (eap), seja chamando do SCHedulle ou rotina do sistema
User Function FtSendMail( mvRecnZ46 )

	local _cQuery :=''
	Local _oMail, _oMessage
	Local _nErro := 0
	Local _cErro := ""
	Local _cAccount  := ' '
	local _cPassword := ' '

	// valores padrao.
	local _cTmpServer := GetMV( "MV_RELSERV",,"smtp.gmail.com:465"     )
	local _aTmpServer := Separa(_cTmpServer,":")
	Local _cAccPad    := GetMV( "MV_RELACNT",,"workflow@tecadi.com.br" )
	Local _cSenPad    := GetMV( "MV_RELPSW" ,,"T3c4d1./"               )
	Local _cServer    := AllTrim(_aTmpServer[1])
	Local _nPort      := Val(_aTmpServer[2])

	Local _lUseTLS   := GetMv("MV_RELTLS" ,,.t.)	//Define se o envio e recebimento de E-Mail na rotina  utilizara conexao segura (TLS)
	Local _lUseSSL   := GetMv("MV_RELSSL" ,,.t.)	//Define se o envio e recebimento de E-Mail na rotina  utilizara conexao segura (SSL)
	Local _lAuth     := GetMv("MV_RELAUTH",,.t.)	//Servidor de E-Mail necessita de Autenticacao? Determina se o Servidor necessita de Autenticacao
	Local _nX := 0

	local _nEmail := 0
	local _aRecnoZ46 :={}
	// anexos
	local _aAnexo := {}

	// para servidor IMAP
	Local _cSrvImap := ' '
	Local _nPrtImap := 0

	// valida conexao
	local _lConectou := .f.

	// caso envie um unico registro para mandar o email
	Default mvRecnZ46 := 0

	// log da conexao
	FWLogMsg('INFO',, 'SIGACOM', FunName(), '', '01',"FtSendMail: "+DtoC(Date())+" "+Time()+" - Emp/Fil: "+cEmpAnt+"/"+cFilAnt , 0, 0, {})

	If (mvRecnZ46 == 0)
		// prepara query
		_cQuery :=  " SELECT Z46.R_E_C_N_O_ Z46RECNO "
		// cad. de mensagens/emails
		_cQuery +=  " FROM " + RetSqlTab("Z46") + " (nolock) "
		// filtro padrao
		_cQuery +=  " WHERE" + RetSqlCond("Z46")
		// filtra somente emails sem flag de envio
		_cQuery +=  " AND Z46.Z46_OK = '' "
		// ordem dados
		_cQuery +=  " ORDER BY Z46.Z46_NCONTR "
		// executa query e atualiza vetor
		_aRecnoZ46 := U_SqlToVet(_cQuery)
	Else
		Dbselectarea("Z46")
		_aRecnoZ46 := { mvRecnZ46 }
	Endif

	// varre todas os registro da query
	For _nEmail := 1 To Len(_aRecnoZ46)

		// gera mensagem da quantidade de e-mails
		If (_nEmail == 1)
			FWLogMsg('INFO',, 'SIGACOM', FunName(), '', '01',"FtSendMail: "+DtoC(Date())+" "+Time()+" - Emp/Fil: "+cEmpAnt+"/"+cFilAnt+" - Quantidade de Mensagens: " + AllTrim(Str(Len(_aRecnoZ46))) , 0, 0, {})
		EndIf

		// abre tabela das mensagens de email
		Dbselectarea("Z46")
		Dbgoto(_aRecnoZ46[_nEmail])

		// verifica se tem destinatario
		If (Empty(Z46->Z46_DESTIN))
			// loop da rotina
			Loop
		EndIf

		// realiza tentativa de reservar o registro
		If ( ! MsrLock() )
			// gera log
			FWLogMsg('INFO',, 'SIGACOM', FunName(), '', '01',"FtSendMail (Reg.Bloq.): "+DtoC(Date())+" "+Time()+" - Emp/Fil: "+cEmpAnt+"/"+cFilAnt+" - Nr Mensagem: " + Z46->Z46_NCONTR , 0, 0, {})
			// retorno
			Return
		EndIf

		// bloqueia registro
		SoftLock("Z46")

		//Conexao Com Servidor.
		If (ALLTRIM(Z46->Z46_CONTAE) <> ALLTRIM(_cAccount)) //caso diferente
			// atualiza a conta que sera utilizada para envio da mensagem
			_cAccount	:= AllTrim(Z46->Z46_CONTAE)
			// atualiza senha da conta que sera utilizada para envio da mensagem
			_cPassword	:= alltrim(if(ALLTRIM(_cAccount) == ALLTRIM(_cACCPAD),_cSenPad,Embaralha(ALLTRIM(Z46->Z46_SENHA),1))) //pega senha padrao

			// prepara o objeto para conexao
			_oMail := TMailManager():New()
			// define SSL
			_oMail:SetUseSSL(_lUseSSL)
			// define TLS
			_oMail:SetUseTLS(_lUseTLS)
			// inicia conexao
			_oMail:Init(_cSrvImap, _cServer, _cAccount, _cPassword, _nPrtImap, _nPort)
			// define timeout
			_oMail:SetSmtpTimeOut(120)
			// realiza conexao
			_nErro := _oMail:SmtpConnect()

			// se deu erro de conexao, grava log e sai da rotina
			If (_nErro <> 0)
				// retorna a mensagem de erro
				_cErro := alltrim(_oMail:GetErrorString(_nErro ))
				// gera mensagem de log no console do server
				FWLogMsg('INFO',, 'SIGACOM', FunName(), '', '01',"FtSendMail: "+DtoC(Date())+" "+Time()+" - Emp/Fil: "+cEmpAnt+"/"+cFilAnt+" - SmtpConnect: " + _cErro , 0, 0, {})
				// gera log
				U_FtGeraLog(xFilial("Z46"),"Z46", Z46->Z46_NCONTR, "Erro na tentativa de conexão ao servidor "+_cErro,"CFG", "")
				// atualiza registro que nao conseguiu enviar
				Dbselectarea("Z46")
				Reclock("Z46",.F.)
				Z46->Z46_OK := "N"
				Z46->(Msunlock())
				// sai do Loop
				Exit
			Endif

			// valida se precisa autenticacao
			If (_lAuth)
				// autentica conexao
				_nErro := _oMail:SmtpAuth( _cAccount,_cPassword )

				// se deu erro de autenticacao, grava log e sai da rotina
				If (_nErro <> 0)
					// retorna a mensagem de erro
					_cErro := alltrim(_oMail:GetErrorString(_nErro ))
					// gera mensagem de log no console do server
					FWLogMsg('INFO',, 'SIGACOM', FunName(), '', '01',"FtSendMail: "+DtoC(Date())+" "+Time()+" - Emp/Fil: "+cEmpAnt+"/"+cFilAnt+" - SmtpAuth: " + _cErro , 0, 0, {})
					// gera log
					U_FtGeraLog(xFilial("Z46"), "Z46", Z46->Z46_NCONTR, "Erro na tentativa de autenticação no servidor "+_cErro,"CFG", "")
					// atualiza registro que nao conseguiu enviar
					Dbselectarea("Z46")
					Reclock("Z46",.F.)
					Z46->Z46_OK := "N"
					Z46->(Msunlock())
					// sai do Loop
					Exit
				Endif
			EndIf

			// atualiza variavel de conexao
			_lConectou := .t.

		Endif

		// explode anexo array linha em array
		_aAnexo := Separa(Z46->Z46_ANEXOS,"||",.T.)

		// Cria objeto da mensagem+
		_oMessage := tMailMessage():new()
		_oMessage:clear()
		_oMessage:cFrom    := Z46->Z46_MAILDE
		_oMessage:cTo      := Z46->Z46_DESTIN
		_oMessage:cCc      := Z46->Z46_CCOPIA
		_oMessage:cSubject := Z46->Z46_TITMSG
		_oMessage:cBody    := Z46->Z46_MENSAG

		// anexa arquivos
		For _nX := 1 to Len(_aAnexo)
			// adiciona um anexo, nesse caso a imagem esta no root
			_oMessage:AttachFile(alltrim(_aAnexo[_nX]))
		Next _nX

		// tentativa de envio da mensagem
		_nErro := _oMessage:Send( _oMail )

		// se deu erro no envio, grava log e sai da rotina
		If (_nErro <> 0)
			// retorna a mensagem de erro
			_cErro := alltrim(_oMail:GetErrorString(_nErro ))
			// gera mensagem de log no console do server
			FWLogMsg('INFO',, 'SIGACOM', FunName(), '', '01',"FtSendMail: "+DtoC(Date())+" "+Time()+" - Emp/Fil: "+cEmpAnt+"/"+cFilAnt+" - Send: " + _cErro , 0, 0, {})
			// gera log
			U_FtGeraLog(xFilial("Z46"), "Z46", Z46->Z46_NCONTR, "Erro na tentativa de envio do e-mail "+_cErro, "CFG", "")
			// atualiza registro que nao conseguiu enviar
			Dbselectarea("Z46")
			Reclock("Z46",.F.)
			Z46->Z46_OK := "N"
			Z46->(MsUnLock())
			// sai do Loop
			Exit
		Endif

		// atualiza registro de confirmacao de envio
		Dbselectarea("Z46")
		Reclock("Z46",.F.)
		Z46->Z46_OK     := "S"
		Z46->Z46_DTENVI := Date()
		Z46->Z46_HRENVI := TIME()
		Z46->(MsUnlock())

		// log de email enviado
		FWLogMsg('INFO',, 'SIGACOM', FunName(), '', '01',"FtSendMail: "+DtoC(Date())+" "+Time()+" - Emp/Fil: "+cEmpAnt+"/"+cFilAnt+" - Nr Mensagem: " + Z46->Z46_NCONTR , 0, 0, {})

		// gera log
		U_FtGeraLog(xFilial("Z46"), "Z46", Z46->Z46_NCONTR, "E-mail enviado com sucesso!", "CFG", "")

	Next _nEmail

	// desconecta do servidor
	If (_lConectou)
		_oMail:SMTPDisconnect()
	EndIf

Return

// ** 17. funcao que salva parametros atuais do grupo de perguntas
User Function FtSavSx1(mvQtdPar)
	// variavel de retorno
	local _aRet := {}
	// variaveis temporarias
	local _nPar
	local _cTmpVar

	// quantidade default
	Default mvQtdPar := 40

	// 30 perguntas
	For _nPar := 1 to mvQtdPar

		// variavel
		_cTmpVar := "mv_par"+StrZero(_nPar,2)
		// adiciona no vetor
		aAdd(_aRet,{_cTmpVar, &(_cTmpVar) })

	Next _nPar

Return(_aRet)

// ** 18. funcao que restaura parametros atuais do grupo de perguntas
User Function FtResSx1(mvAtuParam)
	// variaveis temporarias
	local _nPar
	local _cTmpVar

	// 30 perguntas
	For _nPar := 1 to Len(mvAtuParam)

		// variavel
		_cTmpVar := mvAtuParam[_nPar][1]
		// atualiza variavel
		&(_cTmpVar) := mvAtuParam[_nPar][2]

	Next _nPar

Return(.t.)

// ** 19. funcao que Retorna o erro da Rotina Automatica
User Function FtAchaErro(mvTela)

	// variveis de controle
	Local _cStartPath := GetSrvProfString("Startpath","")
	Local _cFileLog   := Alltrim(_cStartPath) + Alltrim(NomeAutoLog())

	// variavel de retorno
	Local _cRetLog := ""

	// variavel Temp. For
	Local _nPos := 0

	//Pega o Conteudo do Arquivo Texto do LOG
	Local _cContErro := MemoRead( _cFileLog )
	local _aContErro := {}

	Default mvTela := .F.

	If ("HELP: OBRIGAT" $ _cContErro)
		_cRetLog := StrTran(_cContErro,CRLF," ")
	Else
		// separa o conteudo em linhas, de acordo com quebra de linha (enter)
		_aContErro := Separa(_cContErro,CRLF)

		For _nPos := 1 to Len(_aContErro)
			If (_nPos == 1).or.(_nPos == 2)
				_cRetLog += _aContErro[_nPos] + " "
			ElseIf ("< -- Invalido" $ _aContErro[_nPos])
				_cRetLog += _aContErro[_nPos] +" "
			ElseIf ("Mensagem do erro" $ _aContErro[_nPos] )
				_cRetLog += _aContErro[_nPos] +" "
			EndIf
		Next _nPos

	EndIf

	// se parâmetro de mostrar mensagem em tela está ativo
	If (mvTela)
		MostraErro()
	EndIf

	// exclui o arquivo
	fErase(_cFileLog)

Return(_cRetLog)

// ** funcao para extrair patch de arquivos compactados
User Function FtExtPat() // u_FtExtPat()
	// pasta com o local dos arquivos
	local _cDirPatch := cGetFile("Patch TOTVS|*.ZIP", "Selecione arquivo...", ,"c:\temp\", .t., GETF_LOCALHARD+GETF_RETDIRECTORY, .f.)
	// arquivos do diretorio selecionado
	local _aArqZIP := {}
	local _cArqZIP := ""
	// arquivos descompactados
	local _aArqDesc := {}
	local _cArqDesc := ""
	local _cArqData := ""
	// variaveis temporarias
	local _nArqZIP
	local _nArqDesc
	local _cDirTemp := "temporario"
	local _cDirNewPatch := "patch_ok"
	local _nRetRename
	local _cTmpBat
	// linha de comando
	local _cCommand := ""
	// nome arquivo atual
	local _cArqAtual := ""
	// nome do novo arquivo
	local _cArqNovo  := ""

	// testa se ha patch para versao
	local _lPatchOk := .f.

	// valida se foi selecionada alguma pasta
	If Empty(_cDirPatch)
		Alert("Nenhuma Pasta Selecionada!")
		Return
	EndIf

	// retorna a lista de arquivos do diretorio Do Email
	_aArqZIP := Directory(_cDirPatch+"*.ZIP")

	// valida quantidade de arquivos
	If (Len(_aArqZIP) == 0)
		Alert("Nenhuma Pasta Selecionada!")
		Return
	EndIf

	// valida se a pasta existe
	If ( ! ExistDir( _cDirPatch + "\" + _cDirTemp ) )
		// cria o diretorio temporario
		MakeDir(_cDirPatch + "\" + _cDirTemp)
	EndIf

	// valida se a pasta existe
	If ( ! ExistDir( _cDirPatch + "\" + _cDirNewPatch ) )
		// cria o diretorio temporario
		MakeDir(_cDirPatch + "\" + _cDirNewPatch)
	EndIf

	// varre todos os arquivos disponiveis
	For _nArqZIP := 1 to Len(_aArqZIP)

		// atualiza variavel o nome de cada arquivo
		_cArqZIP := _aArqZIP[_nArqZIP, 1]

		// prepara linha de comando
		_cCommand := "7z x " + _cDirPatch + AllTrim(_cArqZIP)+" -y -o" + _cDirPatch + _cDirTemp

		// define o arquivo .BAT para execucao da impressao da etiqueta
		_cTmpBat := _cDirPatch+"extai_patch.bat"
		// grava o arquivo .BAT
		MemoWrit(_cTmpBat, _cCommand)

		// executa comando
		//ShellExecute("Open", _cTmpBat,"",_cDirPatch, 5)
		WaitRun(_cTmpBat, 0)

		// lista todos os arquivos descompactados
		_aArqDesc := Directory(_cDirPatch + _cDirTemp + "\" + "*.*")

		// reinicia variavel
		_lPatchOk := .f.

		// varre todos os arquivos
		For _nArqDesc := 1 to Len(_aArqDesc)

			// atualiza variavel o nome de cada arquivo
			_cArqDesc := _aArqDesc[_nArqDesc, 1]
			// extrai a data do arquivo
			_cArqData := GravaData(_aArqDesc[_nArqDesc, 3], .f., 4)
			_cArqData := SubStr(_cArqData,1,2)+"-"+SubStr(_cArqData,3,2)+"-"+SubStr(_cArqData,5,2)+"-"

			// descarta arquivos de outras versoes
			If ("TTTP110.PTM" $ AllTrim(Upper(_cArqDesc))).or.("LIB_LABEL" $ AllTrim(Upper(_cArqDesc)))

				// nome arquivo atual
				_cArqAtual := _cDirPatch + _cDirTemp + "\" + _cArqDesc
				// nome do novo arquivo
				If ! ("LIB_LABEL" $ AllTrim(Upper(_cArqDesc)))
					_cArqNovo := _cDirPatch
					_cArqNovo += _cDirNewPatch + "\"
					_cArqNovo += _cArqData
					_cArqNovo += StrTran(Upper(_cArqZIP), ".ZIP", "")
					_cArqNovo += ".ptm"
				Else
					_cArqNovo := _cDirPatch
					_cArqNovo += _cDirNewPatch + "\"
					_cArqNovo += _cArqData
					_cArqNovo += _cArqDesc

				EndIf

				// renomeia o arquivo e copia para outra pasta
				_nRetRename := fRename(_cArqAtual, _cArqNovo)

				// valida se ocorreu corretamente
				If (_nRetRename == 0)
					_lPatchOk := .t.
				EndIf

			Else
				// exclui arquivo
				FErase(_cDirPatch + _cDirTemp + "\" + _cArqDesc)

			EndIf

		Next _nArqDesc

		// valida se o patch foi gerado corretamente
		If ( ! _lPatchOk )
			MSgStop("Verificar arquivo: " + AllTrim(_cArqZIP))
		EndIf

	Next _nArqZIP

	MsgInfo("Processamento Ok", "Processamento")

Return

// ** funcao para extrair imagens do RPO
User Function FtExtImg()

	// array com todas as imagens do RPO
	local _aImgRPO := GetResArray("*.*")
	// variaveis temporarias
	local _nImg
	// pasta destino
	local _cDirDest := "\imagens\"

	// varre todas as imagens
	For _nImg := 1 to Len(_aImgRPO)

		// descarta extensoes de traducao (v12)
		If (_aImgRPO[_nImg] $ ".tres")
			Loop
		EndIf

		// Salva uma imagem do repositório em um arquivo no disco a partir do rootpath do ambiente no servidor
		RESOURCE2FILE(_aImgRPO[_nImg], _cDirDest + _aImgRPO[_nImg]  )

	Next _nImg

Return

// ** funcao que gera caracteres aleatorios para chave de verificacao
User Function FtChvVld(mvQtd, mvOnlyChar)
	// variavel de retorno
	local _cChvRet := ""
	local _cListaLet := "ABCDEFGHIJLMNOPQRSTUVXZKWY"
	local _cListaNum := "0123456789"
	local _cListaCom

	// variaveis de controle
	local _nChar
	local _nPosChar
	local _cChar

	// valores padroes
	Default mvQtd      := 4
	Default mvOnlyChar := .f.

	// define todos caracteres aceitaveis
	_cListaCom := _cListaLet
	_cListaCom += IIf(mvOnlyChar, "", _cListaNum)

	// embaralha caracteres
	_cListaCom := Embaralha(_cListaCom, 0)

	// loop da quantidade de caracteres
	For _nChar := 1 to mvQtd

		// numero random
		_nPosChar := Randomize(1, Len(_cListaCom))

		// incrementa caracter
		_cChvRet += SubStr(_cListaCom, _nPosChar, 1)

	Next _nChar

Return(_cChvRet)