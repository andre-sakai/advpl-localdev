#Include "Totvs.ch"
#Include "Colors.ch"
#INCLUDE "TOPCONN.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Manutencao de Ordem de Serviço Entrada/Saida			 !
+------------------+---------------------------------------------------------+
!Autor             ! TSC149-Percio Alexandre de Oliveira                     !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2010                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSA002

	Local _aBrwCores := {{"Z6_STATUS=='A'","ENABLE"},{"Z6_STATUS='F'","BR_AZUL"},{"Z6_STATUS='P'","DISABLE"}}
	// fontes utilizadas
	Private oFntVerd15 := TFont():New("Verdana",,15,,.T.)
	Private oFntCour18 := TFont():New("Courier New",,18,,.T.)

	// variavel para controle da seleção de atividades por tipo de estoque
	Private _lAtvGrpEst := .F.

	// variável para controle se a geração de OS é em massa
	Private _lEmMassa := .F.

	// browse principal
	Private _oBrwAtividade

	dbSelectArea("SZ6")

	// variaveis internas de controle de validacao de campo
	Private _lInclui
	Private _lAltera

	Private cCadastro := "Ordem de Serviço Tecadi"

	// opcoes disponiveis no menu
	Private aRotina := MenuDef()

	DbSelectArea("SZ6")
	SZ6->(DbSetOrder(1))
	mBrowse(6,1,22,75,"SZ6",,,,,,_aBrwCores)

Return

// ** funcao que Monta a Legenda
User Function WMSA002L()

	BrwLegenda(cCadastro, "Status Ordem de Serviço",;
	{{"ENABLE", "Aberta"},;
	{"BR_AZUL", "Finalizada"},;
	{"DISABLE", "Com pedido gerado"} })

Return .T.

// ** funcao para EXCLUIR uma Ordem de Servico
User Function WMSA002X(mvRotAuto)
	// Seek do SZ7
	local _cSeekSZ7
	// usuario com permissao de exclusao
	local _lUsrExcluir := (__cUserId $ AllTrim(SuperGetMv("TC_USEXCOS",.f.,"")))

	// define valor padrao do parametro
	Default mvRotAuto := .f.

	// verifica se o usuario pode executar o estorno
	
	/* -- DESATIVADO EM 18/06/18 - LUIZ POLEZA - POR ORDEM DANIEL KENIG, PARA DEIXAR LIBERADO A TODOS OS ATENDENTES
	If ( ! _lUsrExcluir )
		MsgStop("Usuário sem permissão de exclusão.")
		Return(.f.)
	EndIf
	*/

	If SZ6->Z6_STATUS <> "A"
		Alert("Ordem de Servico não pode ser excluída pois ela já foi finalizada ou faturada!")
		Return(.f.)
	EndIf

	// valida se a programacao esta encerrada
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	If SZ1->(dbSeek( xFilial("SZ1")+SZ6->Z6_CODIGO ))
		If ( ! Empty(SZ1->Z1_DTFINFA))
			MsgStop("Programação " + SZ6->Z6_CODIGO + " encontra-se encerrada. Contate o setor de Faturamento.")
			Return(.f.)
		EndIf
	EndIf

	// mensagem para confirmacao
	If (mvRotAuto).or.(MsgYesNo("Tem certeza que deseja excluir a O.S.: " + AllTrim(SZ6->Z6_NUMOS) + " ?"))

		// INICIA TRANSACAO
		BEGIN Transaction

			// primeiro, exclui os itens da OS
			dbSelectArea("SZ7")
			SZ7->(dbSetOrder(1)) //1-Z7_FILIAL, Z7_NUMOS, Z7_CODATIV
			SZ7->(dbSeek( _cSeekSZ7 := xFilial("SZ7")+SZ6->Z6_NUMOS ))
			While SZ7->(!Eof()).and.(SZ7->(Z7_FILIAL+Z7_NUMOS)==_cSeekSZ7)
				// exclui o item
				dbSelectArea("SZ7")
				Reclock("SZ7")
				SZ7->(dbDelete())
				MsUnlock()
				// proximo item da OS
				SZ7->(dbSkip())
			EndDo

			// depois exclui os apontamento de recursos da OS
			sfExcRecur(SZ6->Z6_NUMOS)

			// depois exclui os apontamento de equipamentos/maquinas da OS
			sfExcEquip(SZ6->Z6_NUMOS)

			// depois exclui os apontamento de mao de obra da OS
			sfExcMaoObr(SZ6->Z6_NUMOS)

			// por ultimo, exclui o cabecalho
			dbSelectArea("SZ6")
			Reclock("SZ6",.F.)
			SZ6->(dbDelete())
			MsUnlock()

			// gera log
			U_FtGeraLog(xFilial("SZ6"),"SZ6", SZ6->Z6_FILIAL + SZ6->Z6_NUMOS,;
			"Registro " + SZ6->Z6_FILIAL + SZ6->Z6_NUMOS + " excluído.",;
			"WMS", "")

			// FINALIZA TRANSACAO
		END Transaction

	EndIf

Return(.t.)

// ** funcao para EXCLUIR OS em massa
User Function WMSA002H(mvOSIni, mvOSFim)
	// Seek do SZ7
	local _cSeekSZ7
	// usuario com permissao de exclusao
	local _lUsrExcluir := (__cUserId $ AllTrim(SuperGetMv("TC_USEXCOS",.f.,"")))
	//perguntas
	Local cPerg := PadR("WMSA002",10)

	// verifica se o usuario pode executar o estorno
	
	/* -- DESATIVADO EM 18/06/18 - LUIZ POLEZA - POR ORDEM DANIEL KENIG, PARA DEIXAR LIBERADO A TODOS OS ATENDENTES
	If ( ! _lUsrExcluir )
		MsgStop("Usuário sem permissão para excluir ordem de serviço.")
		Return(.f.)
	EndIf
	*/

	// cria o grupo de perguntas
	CriaPg01(cPerg)

	// verifica se deve perguntar os parametros de OS inicial e final
	If ( Empty(mvOSIni) .OR. Empty(mvOSFim))
		If ! Pergunte(cPerg)
			Return(.F.)  //sem false tava
		EndIf

		// atualiza variaveis
		mvOSIni := MV_PAR01
		mvOSFim := MV_PAR02
	EndIf

	//SZ6
	dbSelectArea("SZ6")
	SZ6->(dbSetOrder(1))	 //Z6_FILIAL, Z6_NUMOS, Z6_CLIENTE, Z6_LOJA, R_E_C_N_O_, D_E_L_E_T_

	//SZ1
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1))     //1-Z1_FILIAL, Z1_CODIGO

	//valida se OS inicial existe
	If ( !SZ6->(dbSeek(xFilial("SZ6") + mvOSIni)))
		Alert("Ordem de Servico inicial " + mvOsIni + " inválida ou inexistente")
		Return(.f.)
	EndIf

	//validações iterando as OS
	While (SZ6->(!Eof()) .AND. SZ6->Z6_FILIAL = xFilial("SZ6") .AND. SZ6->Z6_NUMOS >= mvOSIni .AND. SZ6->Z6_NUMOS <= mvOSFim )
		//valida se alguma OS está com status diferente de aberto "A")
		If SZ6->Z6_STATUS <> "A"
			Alert("Ordem de Servico " + SZ6->Z6_NUMOS + " nao pode ser excluida pois ela ja foi finalizada ou faturada!")
			Return(.f.)
		EndIf

		// valida se a programacao esta encerrada
		If SZ1->(dbSeek(xFilial("SZ1") + SZ6->Z6_CODIGO))
			If ( !Empty(SZ1->Z1_DTFINFA) )
				MsgStop("Programação encontra-se encerrada. Contate o setor de Faturamento.")
				Return(.f.)
			EndIf
		EndIf

		//proxima OS
		SZ6->(DBSkip())
	EndDo

	// se chegou até aqui, passou nas validações e vamos prosseguir com a exclusão
	//mensagem para confirmacao
	If (MsgYesNo("Tem certeza que deseja excluir em massa as O.S.: " + mvOSIni + " até " + mvOSFim + " ?"))

		//contador
		_nCont :=0

		// INICIA TRANSACAO
		BEGIN Transaction
			//posiciona na primeira OS
			SZ6->(dbSeek(xFilial("SZ6") + mvOSIni))

			While (SZ6->(!Eof()) .AND. SZ6->Z6_FILIAL = xFilial("SZ6") .AND. SZ6->Z6_NUMOS >= mvOSIni .AND. SZ6->Z6_NUMOS <= mvOSFim)
				// primeiro, exclui os itens da OS
				dbSelectArea("SZ7")
				SZ7->(dbSetOrder(1)) //1-Z7_FILIAL, Z7_NUMOS, Z7_CODATIV
				SZ7->(dbSeek( _cSeekSZ7 := xFilial("SZ7")+SZ6->Z6_NUMOS ))
				While SZ7->(!Eof()) .AND. (SZ7->(Z7_FILIAL+Z7_NUMOS) == _cSeekSZ7)
					// exclui o item
					dbSelectArea("SZ7")
					Reclock("SZ7")
					SZ7->(dbDelete())
					MsUnlock()
					// proximo item da OS
					SZ7->(dbSkip())
				EndDo

				// depois exclui os apontamento de recursos da OS
				sfExcRecur(SZ6->Z6_NUMOS)

				// depois exclui os apontamento de equipamentos/maquinas da OS
				sfExcEquip(SZ6->Z6_NUMOS)

				// depois exclui os apontamento de mao de obra da OS
				sfExcMaoObr(SZ6->Z6_NUMOS)

				// por ultimo, exclui o cabecalho
				dbSelectArea("SZ6")
				Reclock("SZ6",.F.)
				SZ6->(dbDelete())
				MsUnlock()

				// gera log do registro posicionado
				U_FtGeraLog(xFilial("SZ6"),"SZ6", SZ6->Z6_FILIAL + SZ6->Z6_NUMOS,;
				"Registro " + SZ6->Z6_FILIAL + SZ6->Z6_NUMOS + " excluído em massa. Sequências de OS: " + mvOSIni + " - " + mvOSFim,;
				"WMS", "")

				//proximo registro
				SZ6->(dbSkip())
				_nCont++
			EndDo

			// FINALIZA TRANSACAO
		END Transaction

		MsgInfo("Ordens de serviço " + mvOSIni + " até " + mvOSFim + " excluídas com sucesso. Total de OS excluídas:" + AllTrim( Str(_nCont) ) )
	EndIf

Return(.t.)

// ** funcao para ESTORNAR uma Ordem de Servico
User Function WMSA002E()
	// variavel de controle de atualizacao de dados de container
	local _lAtuCnt := .f.

	// usuario com permissao de estorno
	local _lUsrEstor := (__cUserId $ AllTrim(SuperGetMv("TC_USESTOS",.f.,"")))

	// verifica se o usuario pode executar o estorno
	/* -- DESATIVADO EM 18/06/18 - LUIZ POLEZA - POR ORDEM DANIEL KENIG, PARA DEIXAR LIBERADO A TODOS OS ATENDENTES
	If ( ! _lUsrEstor )
		MsgStop("Usuário sem permissão de estorno.")
		Return(.f.)
	EndIf
	*/

	If SZ6->Z6_STATUS == "P"
		Alert("Ordem de Servico nao pode ser estornada pois ela ja foi faturada !!")
		Return(.f.)
	EndIf

	//	// valida o tipo de movimento para considerar container e RIC na SZ3
	//	If (SZ6->Z6_TIPOMOV == "E")
	//		dbSelectArea("SZ3")
	//		SZ3->(dbOrderNickName("Z3_RIC"))
	//		If SZ3->(dbSeek( xFilial("SZ3")+SZ6->Z6_RIC ))
	//			If !Empty(SZ3->Z3_DTSAIDA)
	//				Alert("Ordem de Servico nao pode ser estornada pois a RIC de Sáida já foi gerada em "+DTOC(SZ3->Z3_DTSAIDA)+" !!")
	//				Return(.f.)
	//			EndIf
	//			// habilita atualizacao do container
	//			_lAtuCnt := .t.
	//		EndIf
	//	EndIf

	// valida se a programacao esta encerrada
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	If SZ1->(dbSeek( xFilial("SZ1")+SZ6->Z6_CODIGO ))
		If ( ! Empty(SZ1->Z1_DTFINFA))
			MsgStop("Programação encontra-se encerrada. Contate o setor de Faturamento.")
			Return(.f.)
		EndIf
	EndIf

	If (SZ6->Z6_STATUS == "F")
		If MsgYesNo("Tem certeza que deseja estornar a O.S.: "+AllTrim(SZ6->Z6_NUMOS)+". O Status da mesma irá retornar para Aberto !!")

			// INICIA TRANSACAO
			BEGIN Transaction

				// reabre a OS
				dbSelectArea("SZ6")
				Reclock("SZ6",.F.)
				SZ6->Z6_STATUS := "A"
				SZ6->Z6_DTFINAL := CTOD('')
				MsUnlock()

				If (_lAtuCnt)
					// Estornar Conteudo do Container Atual
					cQry:="UPDATE "+RetSqlName("SZ3")+" SET Z3_CONTATU = '"+SZ3->Z3_CONTEUD+"' WHERE Z3_RIC = '"+SZ6->Z6_RIC+"' "
					TCSQLExec(cQry)
				EndIf

				// exclui os apontamento de recursos da OS
				sfExcRecur(SZ6->Z6_NUMOS)

				// depois exclui os apontamento de equipamentos/maquinas da OS
				sfExcEquip(SZ6->Z6_NUMOS)

				// depois exclui os apontamento de mao de obra da OS
				sfExcMaoObr(SZ6->Z6_NUMOS)

				//Gera log
				U_FtGeraLog(cFilAnt, "SZ6", xFilial("SZ6") + SZ6->Z6_NUMOS, "Realizado estorno da ordem de serviço (status P -> A)", "WMS", "")

				// FINALIZA TRANSACAO
			END Transaction

		EndIf
	EndIf

Return(.t.)

// ** funcao para ESTORNAR em massa as ordens de serviço
User Function WMSA002J(mvOSIni, mvOSFim)
	// variavel de controle de atualizacao de dados de container
	local _lAtuCnt := .f.
	//perguntas
	Local cPerg := PadR("WMSA002",10)
	// usuario com permissao de estorno
	local _lUsrEstor := (__cUserId $ AllTrim(SuperGetMv("TC_USESTOS",.f.,"")))

	// verifica se o usuario pode executar o estorno
	/* -- DESATIVADO EM 18/06/18 - LUIZ POLEZA - POR ORDEM DANIEL KENIG, PARA DEIXAR LIBERADO A TODOS OS ATENDENTES
	If ( ! _lUsrEstor )
		MsgStop("Usuário sem permissão de estorno.")
		Return(.f.)
	EndIf
	*/

	// cria o grupo de perguntas
	CriaPg01(cPerg)

	// verifica se deve perguntar os parametros de OS inicial e final
	If ( Empty(mvOSIni) .OR. Empty(mvOSFim))
		If ! Pergunte(cPerg)
			Return(.F.)  //sem false tava
		EndIf

		// atualiza variaveis
		mvOSIni := MV_PAR01
		mvOSFim := MV_PAR02
	EndIf

	//SZ6
	dbSelectArea("SZ6")
	SZ6->(dbSetOrder(1))	 //Z6_FILIAL, Z6_NUMOS, Z6_CLIENTE, Z6_LOJA, R_E_C_N_O_, D_E_L_E_T_

	//SZ1
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1))     //1-Z1_FILIAL, Z1_CODIGO

	//valida se OS inicial existe, caso contrario nem continua o restante das validações
	If ( !SZ6->(dbSeek(xFilial("SZ6") + mvOSIni)))
		Alert("Ordem de Servico inicial " + mvOsIni + " inválida ou inexistente")
		Return(.f.)
	EndIf

	//	// valida o tipo de movimento para considerar container e RIC na SZ3
	//	If (SZ6->Z6_TIPOMOV == "E")
	//		dbSelectArea("SZ3")
	//		SZ3->(dbOrderNickName("Z3_RIC"))
	//		If SZ3->(dbSeek( xFilial("SZ3")+SZ6->Z6_RIC ))
	//			If !Empty(SZ3->Z3_DTSAIDA)
	//				Alert("Ordem de Servico nao pode ser estornada pois a RIC de Sáida já foi gerada em "+DTOC(SZ3->Z3_DTSAIDA)+" !!")
	//				Return(.f.)
	//			EndIf
	//			// habilita atualizacao do container
	//			_lAtuCnt := .t.
	//		EndIf
	//	EndIf

	//validações iterando as OS
	While (SZ6->(!Eof()) .AND. SZ6->Z6_FILIAL = xFilial("SZ6") .AND. SZ6->Z6_NUMOS >= mvOSIni .AND. SZ6->Z6_NUMOS <= mvOSFim )
		//valida se a programação está encerrada
		If SZ1->(dbSeek( xFilial("SZ1") + SZ6->Z6_CODIGO ))
			If ( ! Empty(SZ1->Z1_DTFINFA))
				MsgStop("Programação " + SZ6->Z6_CODIGO + " encontra-se encerrada. Contate o setor de Faturamento. O.S. : " + SZ6->Z6_NUMOS)
				Return(.f.)
			EndIf
		EndIf

		//valida se OS já foi faturada
		If SZ6->Z6_STATUS == "P"
			Alert("Ordem de Servico " + SZ6->Z6_NUMOS + " não pode ser estornada pois ela ja foi faturada!")
			Return(.f.)
		EndIf

		//proxima OS
		SZ6->(DBSkip())
	EndDo

	//confirma se deseja prosseguir com o estorno
	//se chegou até aqui, passou nas validações necessárias e está apto a estornar
	If MsgYesNo("Tem certeza que deseja estornar EM MASSA as O.S.: " + mvOSIni + " até " + mvOSFim + " ?. O status das O.S. irá retornar para aberto!")
		//posiciona na primeira OS
		SZ6->(dbSeek(xFilial("SZ6") + mvOSIni))

		// INICIA TRANSACAO
		BEGIN Transaction

			While (SZ6->(!Eof()) .AND. SZ6->Z6_FILIAL = xFilial("SZ6") .AND. SZ6->Z6_NUMOS >= mvOSIni .AND. SZ6->Z6_NUMOS <= mvOSFim)
				//executa o estorno apenas em OS finalizadas e que passaram nas validaçoes anteriores
				If (SZ6->Z6_STATUS == "F")
					// reabre a OS
					dbSelectArea("SZ6")
					Reclock("SZ6",.F.)
					SZ6->Z6_STATUS := "A"
					SZ6->Z6_DTFINAL := CTOD('')
					MsUnlock()

					If (_lAtuCnt)
						// Estornar Conteudo do Container Atual
						cQry:="UPDATE "+RetSqlName("SZ3")+" SET Z3_CONTATU = '"+SZ3->Z3_CONTEUD+"' WHERE Z3_RIC = '"+SZ6->Z6_RIC+"' "
						TCSQLExec(cQry)
					EndIf

					// exclui os apontamento de recursos da OS
					sfExcRecur(SZ6->Z6_NUMOS)

					// depois exclui os apontamento de equipamentos/maquinas da OS
					sfExcEquip(SZ6->Z6_NUMOS)

					// depois exclui os apontamento de mao de obra da OS
					sfExcMaoObr(SZ6->Z6_NUMOS)

					// gera log do registro posicionado
					U_FtGeraLog(cFilAnt,"SZ6", SZ6->Z6_FILIAL + SZ6->Z6_NUMOS,;
					"Registro " + SZ6->Z6_FILIAL + SZ6->Z6_NUMOS + " estornado em massa (status P -> A). Sequências de OS: " + mvOSIni + " - " + mvOSFim,;
					"WMS", "")
				EndIf

				//proximo registro
				SZ6->(dbSkip())
			EndDo

			// FINALIZA TRANSACAO
		END Transaction
	EndIf

Return(.t.)

// ** funcao para incluir uma programacao de ordem de servico (botão "programar")
User Function WMSA002P()

	// campos utilizados
	Private _aStruCnt := {}
	Private _aBrwCnt := {}
	Private _dDtApont	:= Date()
	Private _cCodCli	:= CriaVar("A1_COD",.f.)
	Private _cLojCli	:= CriaVar("A1_LOJA",.f.)
	Private _cNomCli	:= CriaVar("A1_NOME",.f.)
	Private _cTpMov		:= ""
	Private _aTpMov		:= sfCboxToArray("Z6_TIPOMOV")
	Private _cNumProg	:= CriaVar("Z6_CODIGO",.f.)
	Private _cPlaca1	:= CriaVar("Z6_PLACA1",.f.)
	Private _cIteProg	:= CriaVar("Z6_ITEM",.f.)
	Private _cNumPed	:= CriaVar("C5_NUM",.f.)
	Private _cNumPe2	:= CriaVar("C5_NUM",.f.)
	Private _cDoc		:= CriaVar("F1_DOC",.f.)
	Private _cSerie		:= CriaVar("F1_SERIE",.f.)
	Private _cObs		:= CriaVar("Z6_OBSERVA",.f.)
	Private _bAtivid	:= .F.
	Private _cMarca		:= 	GetMark ()
	Private CNT			:= GetNextAlias()
	Private _cArqCnt
	Private _cArquivo
	Private ATI			:= GetNextAlias()
	
	// limpa a variável exclusiva da sumitomo
	_lAtvGrpEst := .f.

	// apresenta mensagem com todas as OSs pendentes do usuario
	sfMsgOSPend()

	SetKey(VK_F9,{|| oBtnCancelar:Click() } )

	// definicao da tela
	oDlgOrdemServ := MSDialog():New(000,000,400,800,"Programação de Ordem de Serviço",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho
	oPnlCabec := TPanel():New(000,000,nil,oDlgOrdemServ,,.F.,.F.,,,000,083,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// data de movimentacao
	oSayDtMov := TSay():New(005,012,{||"Data da O.S."},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
	oGetCodRec := TGet():New(003,110,{|u| If(PCount()>0,_dDtApont:=u,_dDtApont)},oPnlCabec,070,010,,,,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_dDtApont",,)
	oGetCodRec:Disable()

	// tipo de movimento
	oSayTpMov := TSay():New(020,012,{||"Tipo de Movimento"},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
	oGetTpMov :=  TComboBox():New(018,110,{|u| If(PCount()>0,_cTpMov:=u,_cTpMov)},_aTpMov,080,010,oPnlCabec,,,,,,.T.,oFntVerd15,"",,,,,,,_cTpMov)
	oGetTpMov:bChange:={|| sfModOperac() }

	// dados do cliente
	oSayCliente := TSay():New(035,012,{||"Cód/Loja Cliente"},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
	oGetCodCli := TGet():New(033,110,{|u| If(PCount()>0,_cCodCli:=u,_cCodCli)},oPnlCabec,050,010,PesqPict("SA1","A1_COD"),{||Vazio().or.sfVldCliente()},,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SA1","_cCodCli",,)
	oGetLojCli := TGet():New(033,165,{|u| If(PCount()>0,_cLojCli:=u,_cLojCli)},oPnlCabec,020,010,PesqPict("SA1","A1_LOJA"),{||Vazio().or.sfVldCliente()},,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cLojCli",,)
	oGetNomCli := TGet():New(033,200,{|u| If(PCount()>0,_cNomCli:=u,_cNomCli)},oPnlCabec,180,010,PesqPict("SA1","A1_NOME"),,,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomCli",,)
	oGetNomCli:Disable()

	// numero e item da programacao
	oSayProgram := TSay():New(050,012,{||"Programação/Item"},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
	oGetNumProg := TGet():New(048,110,{|u| If(PCount()>0,_cNumProg:=u,_cNumProg)},oPnlCabec,050,010,PesqPict("SZ6","Z6_CODIGO"),{||Vazio().or.sfVldNumProg()},,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SZ2MOS","_cNumProg",,)
	oGetIteProg := TGet():New(048,165,{|u| If(PCount()>0,_cIteProg:=u,_cIteProg)},oPnlCabec,030,010,PesqPict("SZ6","Z6_ITEM"),{||Vazio().or.sfVldNumProg()},,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIteProg",,)

	// numero do pedido de venda
	oSayNumPed := TSay():New(050,012,{||"Pedido de Venda"},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
	oGetNumPed := TGet():New(048,110,{|u| If(PCount()>0,_cNumPed:=u,_cNumPed)},oPnlCabec,050,010,PesqPict("SZ6","Z6_PEDIDO"),{|| Vazio() .OR. sfVldGet1() },,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SC5ORD","_cNumPed",,)
	oGetNumPe2 := TGet():New(048,165,{|u| If(PCount()>0,_cNumPe2:=u,_cNumPe2)},oPnlCabec,050,010,PesqPict("SZ6","Z6_PEDIDO"),{|| sfVldGet2() },,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SC5ORD","_cNumPe2",,)
	oGetNumPed:Disable()
	oGetNumPe2:Disable()
	oGetNumPed:Hide()
	oGetNumPe2:Hide()
	oSayNumPed:Hide()

	// botao para selecionar pedido de venda em massa
	oBtnPedido := TButton():New(048,165,"Vários (de/até)",oPnlCabec,{|| sfPedidos() },060,014,,,,.T.,,"",,,,.F. )
	oBtnPedido:Hide()
	oBtnPedido:Disable()

	// Placa
	oSayPlaca1 := TSay():New(065,012,{||"Placa"},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
	oGetPlaca1 := TGet():New(063,110,{|u| If(PCount()>0,_cPlaca1:=u,_cPlaca1)},oPnlCabec,050,010,PesqPict("SZ6","Z6_PLACA1"),{||Vazio() .OR. ExistCpo("DA3")},,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"DA3","_cPlaca1",,)
	oGetPlaca1:Hide()
	oSayPlaca1:Hide()

	// Documento de Entrada e Serie
	oSayDocSerie := TSay():New(050,012,{||"Doc.Entrada/Serie"},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
	oGetDoc := TGet():New(048,110,{|u| If(PCount()>0,_cDoc:=u,_cDoc)},oPnlCabec,050,010,PesqPict("SF1","F1_DOC"),{||Vazio().or.sfVldDocSerie()},,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SF1BEN","_cDoc",,)
	oGetSerie := TGet():New(048,175,{|u| If(PCount()>0,_cSerie:=u,_cSerie)},oPnlCabec,030,010,PesqPict("SF1","F1_SERIE"),{||Vazio().or.sfVldDocSerie()},,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cSerie",,)
	oGetDoc:Hide()
	oGetSerie:Hide()
	oSayDocSerie:Hide()

	//Observacoes
	oSayObs := TSay():New(070,220,{||"Obs:"},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
	@ 050,240 GET oGetObs  VAR _cObs MEMO SIZE 150,027 OF oPnlCabec PIXEL

	// botoes de operacoes
	oBtnAtividade := TButton():New(005,250,"Atividades (F6)",oPnlCabec,{|| sfAtividades() },040,014,,,,.T.,,"",,,,.F. )
	oBtnAtividade:Disable()
	oBtnConfOS := TButton():New(005,300,"Confirmar (F8)",oPnlCabec,{|| sfPreConf() },040,014,,,,.T.,,"",,,,.F. )
	oBtnConfOS:Disable()
	oBtnCancelar := TButton():New(005,350,"Sair (F9)",oPnlCabec,{|| oDlgOrdemServ:End() },040,014,,,,.T.,,"",,,,.F. )

	// lista de containers
	aadd(_aStruCnt,{"CNT_OK","C",2,0})
	aadd(_aStruCnt,{"CNT_COD","C",TamSx3("Z3_CONTAIN")[1],TamSx3("Z3_CONTAIN")[2]})
	aadd(_aStruCnt,{"CNT_RIC","C",TamSx3("Z3_RIC")[1],TamSx3("Z3_RIC")[2]})
	aadd(_aStruCnt,{"CNT_CONTEU","C",10,0})
	aadd(_aStruCnt,{"CNT_TAMCON","C",TamSx3("Z3_TAMCONT")[1],TamSx3("Z3_TAMCONT")[2]})
	aadd(_aStruCnt,{"CNT_TIPCON","C",10,0})

	aadd(_aBrwCnt,{"CNT_OK",,""})
	aadd(_aBrwCnt,{"CNT_COD",,RetTitle("Z3_CONTAIN")})
	aadd(_aBrwCnt,{"CNT_RIC",,RetTitle("Z3_RIC")})
	aadd(_aBrwCnt,{"CNT_CONTEU",,RetTitle("Z3_CONTEUD")})
	aadd(_aBrwCnt,{"CNT_TAMCON",,RetTitle("Z3_TAMCONT")})
	aadd(_aBrwCnt,{"CNT_TIPCON",,RetTitle("Z3_TIPCONT")})

	If (Select(CNT)<>0)
		dbSelectArea(CNT)
		dbCloseArea()
	EndIf
	
	_cArqCnt := FWTemporaryTable():New( CNT )
	_cArqCnt:SetFields( _aStruCnt )
	_cArqCnt:AddIndex("01", {"CNT_COD"} )
	_cArqCnt:Create()

	oBrwCntr := MsSelect():New (CNT,"CNT_OK",Nil, _aBrwCnt, .F., _cMarca, {200,000,400,400})
	oBrwCntr:oBrowse:lHasMark 	:= .T.
	oBrwCntr:oBrowse:lCanAllMark	:=.T.
	oBrwCntr:oBrowse:bAllMark 	:= 	{|| MarkAll ("CNT", _cMarca, @oDlgOrdemServ)}
	oBrwCntr:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oBrwCntr:oBrowse:Disable()


	// ativa o dialogo
	oDlgOrdemServ:Activate(,,,.T.,)

	//encerra
	sfEncerra()

Return

//validação do campo get oGetNumPed
Static Function sfVldGet1()
	If ( sfVldNumPed(_cNumPed, .T. ) )   //passou nas validações
		oGetNumPed:Disable()
		oBtnPedido:Enable()		//botão varios pedidos (de/até)
		oGetNumPe2:SetFocus()
		sfAtivaBotao()			//teclas de atalho
		Return( .T. )
	EndIf
Return ( .F. )

//validação do campo get oGetNumPe2
Static Function sfVldGet2()
	If ( sfVldNumPed(_cNumPe2, .T. ) )   //passou nas validações
		oGetNumPe2:Disable()
		_lEmMassa := .T. 		//se preencheu o campo e validou o número do pedido, significa que será em massa
		Return( .T. )
	EndIf
Return ( .F. )

//ação do botão CONFIRMAR OS (oBtnConfOS)
Static Function sfPreConf()

	//variavel inicial para numero do pedido de venda
	local _cTmpPed1 := _cNumPed
	local _cTmpPed2 := _cNumPe2

	If ( _cTpMov == "S" .AND. _lEmMassa )   //se for gerar OS de saída em massa
		//_lEmMassa := .T.

		_nCont := 0

		//itera até que chegue no pedido final
		While ( _cNumPed <= _cNumPe2 )

			//posiciona no pedido
			dbSelectArea("SC5")
			SC5->( dbSetOrder(1) ) // 1-C5_FILIAL, C5_NUM
			SC5->( dbSeek(xFilial("SC5") + _cNumPed) )

			//valida individualmente cada pedido
			If ( SC5->(!EOF()) .AND. SC5->C5_FILIAL = xFilial("SC5") .AND. SC5->C5_CLIENTE = _cCodCli .AND. SC5->C5_LOJACLI = _cLojCli )
				If ( !sfConfirmarOS() )
					MsgStop("Erro: não foi possível gerar todas as ordens de serviço do intervalo solicitado pois o pedido de venda" + _cNumPed + " do intervalo não satisfez as validações.")
					MsgStop("Falha na operação total, porém foram geradas ordens de serviço em massa para " + AllTrim(Str(_nCont)) + " pedidos de venda válidos.")
					_lEmMassa := .F.

					//restaura as variaveis iniciais
					_cNumPed := _cTmpPed1
					_cNumPe2 := _cTmpPed2

					Return() 			//cancela
				Endif

				_nCont++
			EndIf

			//proximo pedido
			_cNumPed := Soma1(_cNumPed)
		EndDo

		MsgInfo("Sucesso na operação. Foram geradas ordens de serviço em massa para " + AllTrim(Str(_nCont)) + " pedidos de venda.")
	Else 	//geração única
		sfConfirmarOS()
	Endif

	//restaura as variaveis iniciais
	_cNumPed := _cTmpPed1
	_cNumPe2 := _cTmpPed2

Return( )

Static Function sfGrvProg()

	If _cTpMov == "I"
		dbSelectArea("SD1")
		dbSetOrder(1)
		If dbSeek(xFilial("SD1")+_cDoc+_cSerie+_cCodCli+_cLojCli)
			If !Empty(SD1->D1_PROGRAM)
				_cNumProg:=SD1->D1_PROGRAM
				_cIteProg:=SD1->D1_ITEPROG
			EndIf
		EndIf
	EndIf
	If _cTpMov == "S"
		cQuery:="SELECT DISTINCT D1_PROGRAM, D1_ITEPROG FROM "+RetSqlName("SC6")+" C6 (nolock) , "+RetSqlName("SD1")+" D1 (nolock)  "
		cQuery+="WHERE C6_FILIAL = D1_FILIAL AND C6_CLI = D1_FORNECE AND C6_LOJA = D1_LOJA AND C6_NFORI = D1_DOC AND "
		cQuery+="C6_SERIORI = D1_SERIE AND C6_ITEMORI = D1_ITEM AND "
		cQuery+="D1_TIPO = 'B' AND "
		cQuery+="C6_FILIAL = '"+xFilial("SC6")+"' AND C6_NUM = '"+_cNumPed+"' AND "
		cQuery+="C6.D_E_L_E_T_ <> '*' AND D1.D_E_L_E_T_ <> '*' "
		if !Empty(Select("PRO"))
			dbSelectArea("PRO")
			dbCloseArea()
		endif
		TCQuery cQuery NEW ALIAS "PRO"
		dbSelectArea("PRO")
		PRO->(dbGotop())
		While PRO->(!EOF())
			If Empty(_cNumProg)
				_cNumProg:=PRO->D1_PROGRAM
				_cIteProg:=PRO->D1_ITEPROG
			EndIf
			PRO->(dbSkip())
		EndDo
	EndIf


Return(.t.)

// ** funcao que finaliza a Ordem de Serviço
User Function WMSA002F(bEdit, mvEmMassa)

	// pastas disponiveis
	local _aFolders := {"&Dados Gerais","&Recursos Humanos","&Observações","&Equipamentos","&Mão de obra"}

	Private _cCodCli	:= SZ6->Z6_CLIENTE
	Private _cLojCli	:= SZ6->Z6_LOJA
	Private _cNomCli	:= Posicione("SA1",1,xFilial("SA1")+SZ6->Z6_CLIENTE+SZ6->Z6_LOJA,"A1_NOME")
	Private _cTpMov		:= SZ6->Z6_TIPOMOV
	Private _cCodigo	:= SZ6->Z6_CODIGO
	Private _cItem		:= SZ6->Z6_ITEM
	Private _cNumPed	:= SZ6->Z6_PEDIDO
	Private _cDocSerie	:= SZ6->Z6_DOCSERI
	Private _cContain	:= SZ6->Z6_CONTAIN
	Private _dEmissao	:= SZ6->Z6_EMISSAO
	Private _cNumOS		:= SZ6->Z6_NUMOS
	Private _nQtdMO		:= SZ6->Z6_QTDMO
	Private _cCondCarga := SZ6->Z6_CONDCAR
	Private _dDtInic	:= SZ6->Z6_DATAINI
	Private _cHoraI		:= SZ6->Z6_HORAINI
	Private _dDtFim		:= SZ6->Z6_DATAFIM
	Private _cHoraF		:= SZ6->Z6_HORAFIM
	Private _cObs		:= SZ6->Z6_OBSERVA
	Private _cRIC		:= SZ6->Z6_RIC
	Private _aCondCarga	:= sfCboxToArray("Z6_CONDCAR")
	Private _aTpMov		:= sfCboxToArray("Z6_TIPOMOV")
	Private _aHeadAtv 	:= {}
	Private _aColsAtv 	:= {}

	// controle do browse de equipamentos
	Private _aHeadEqu := {}
	Private _aColsEqu := sfRetEquip()
	
	// opcao SEM equipamentos
//	private _lSemEquip := If(bEdit,.f.,(Len(_aColsEqu)==0))
	private _lSemEquip := .T.     // alterado por solicitação Daniel 04/09/19

	// lista dos operadores
	private _vListOper := {}
	private _aOper     := {}
	// opcao SEM operadores
//	private _lSemOper := .F.
	private _lSemOper := .T.      // alterado por solicitação Daniel 04/09/19

	// lista dos conferentes
	private _vListConf := sfRetRecHum(bEdit,_cNumOS,"WMS02")
	// opcao SEM conferentes
//	private _lSemConf := If(bEdit,.f.,((Len(_vListConf)==0).or.(Empty(_vListConf[1]))))
	private _lSemConf := .T.      // alterado por solicitação Daniel 04/09/19
	
	
	
	// lista dos servicos gerais
	private _vListSrvGer := sfRetRecHum(bEdit,_cNumOS,"WMS05")
	// opcao SEM servicos gerais
//	private _lSemSrvGer := If(bEdit,.f.,((Len(_vListConf)==0).or.(Empty(_vListConf[1]))))
	private _lSemSrvGer := .T.    //  alterado por solicitação Daniel 04/09/19

	// controle do browse de mao de obra
	Private _aHeadMaoObr := {}
	private _aColsMaoObr := sfRetMaoObr()
	// opcao SEM mao de obra
//	private _lSemMaoObr := If(bEdit,.f.,(Len(_aColsMaoObr)==0))
	private _lSemMaoObr := .T.    // alterado por solicitação Daniel 04/09/19
	
	
	// codigo da tabela de mao de obra
	private _cTabMaoObr := ""
	// fornecedor da mao de obra
	private _aMoFornec := sfMoFornec()
	private _cMoFornec := ""

	// variavel que define o valor principal da OS (os primeiros 6 caracteres) para finalização em massa
	private _cPrefixOS := SUBSTR(_cNumOS,1,6)

	// variaveis do objeto listbox
	Private _oSayOper, _oLstOper

	// numero do contrato
	private _cNrContrat := CriaVar("AAM_CONTRT", .f.)

	// default do parâmetro
	Default mvEmMassa := .f.

	// valida o status da OS
	If SZ6->Z6_STATUS <> "A" .And. bEdit
		MsgStop("Ordem de Servico já esta finalizada !!")
		Return(.f.)
	EndIf

	// valida se a programacao esta encerrada
	If (bEdit)
		dbSelectArea("SZ1")
		SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
		If SZ1->(dbSeek( xFilial("SZ1")+_cCodigo ))
			If ( ! Empty(SZ1->Z1_DTFINFA))
				MsgStop("Programação encontra-se encerrada. Contate o setor de Faturamento.")
				Return(.f.)
			EndIf
		EndIf
	EndIf

	// localiza o contrato
	If (bEdit)
		dbSelectArea("AAM")
		AAM->(dbSetOrder(1)) // 1-AAM_FILIAL, AAM_CONTRT
		If ! AAM->(dbSeek( xFilial("AAM")+SZ1->Z1_CONTRT ))
			MsgStop("Contrato não encontrado. Contate o setor de Faturamento.")
			Return(.f.)
		EndIf

		// atualiza numero do contrato
		_cNrContrat := AAM->AAM_CONTRT

	EndIf

	// define teclas de atalho
	SetKey(VK_F8,{|| If(bEdit,_oBtnConfOS:Click(),nil) } )
	SetKey(VK_F9,{|| _oBtnFechar:Click() } )

	// alimenta o header
	aAdd(_aHeadAtv,{"Código",    "Z7_CODATIV", PesqPict("SZ7","Z7_CODATIV"), TamSx3("Z7_CODATIV")[1], 0                      ,"U_WMSA002V()",Nil,"C",Nil,"R",,,Iif(mvEmMassa, ".f.", ".t.") })
	aAdd(_aHeadAtv,{"Descrição", "ZT_DESCRIC", PesqPict("SZT","ZT_DESCRIC"), TamSx3("ZT_DESCRIC")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadAtv,{"UM",        "Z7_UNIDCOB", PesqPict("SZ7","Z7_UNIDCOB"), TamSx3("Z7_UNIDCOB")[1], 0                      ,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadAtv,{"Faturar",   "Z7_FATURAR", PesqPict("SZ7","Z7_FATURAR"), TamSx3("Z7_FATURAR")[1], 0                      ,Iif( mvEmMassa, "U_WMSA002Y(1, 4)", Nil),Nil,"C",Nil,"R",,,".T."})
	aAdd(_aHeadAtv,{"Quantidade","Z7_QUANT",   PesqPict("SZ7","Z7_QUANT"),   TamSx3("Z7_QUANT")[1],   TamSx3("Z7_QUANT")[2]  ,"U_WMSA002Q()",Nil,"N",Nil,"R",,,".T."})
	aAdd(_aHeadAtv,{"Operação",  "Z7_TIPOPER", PesqPict("SZ7","Z7_TIPOPER"), TamSx3("Z7_TIPOPER")[1], TamSx3("Z7_TIPOPER")[2],Nil,Nil,"C",Nil,"R",,,".F."})
	aAdd(_aHeadAtv,{"Observação","Z7_OBSERVA", PesqPict("SZ7","Z7_OBSERVA"), TamSx3("Z7_OBSERVA")[1], TamSx3("Z7_OBSERVA")[2],Iif( mvEmMassa, "U_WMSA002Y(1, 7)", Nil),Nil,"M",Nil,"R",,,".T."})
	aAdd(_aHeadAtv,{"Seq.OS",    "Z7_SEQOS",   "@!"                        , 3                      , 0                      ,Nil,Nil,"C",Nil,"R",,,".F."})

	// alimenta o acols
	_cQuery := " SELECT ZT_CODIGO, "
	_cQuery += "       ZT_DESCRIC, "
	_cQuery += "       Z7_UNIDCOB, "
	_cQuery += "       Z7_FATURAR, "
	_cQuery += "       CASE "
	_cQuery += "         WHEN Z7_UNIDCOB = 'CO' THEN 1 "
	// se estiver finalizando em massa, apresenta o total dos pedidos SC6
	If (mvEmMassa)
		_cQuery += "         ELSE ISNULL((SELECT "
		_cQuery += "                             CASE "
		_cQuery += "                               WHEN Z7_UNIDCOB = 'TO' THEN Sum(C6_ZPESOB / 1000) "
		_cQuery += "                               ELSE Sum(C6_QTDVEN) "
		_cQuery += "                             END QTD_PED_VEN "
		_cQuery += "               FROM   "+RetSqlTab("SC6")+"  (nolock)  "
		_cQuery += "                      INNER JOIN "+RetSqlTab("SD1")+" (nolock) "
		_cQuery += "                              ON D1_DOC = C6_NFORI "
		_cQuery += "                                 AND D1_SERIE = C6_SERIORI "
		_cQuery += "                                 AND D1_ITEM = C6_ITEMORI "
		_cQuery += "                                 AND D1_NUMSEQ = C6_IDENTB6 "
		_cQuery += "                                 AND D1_PROGRAM = Z6_CODIGO "
		_cQuery += "                                 AND "+RetSqlCond("SD1")

		// exclusivo pro cliente SUMITOMO - David 21/03
		If (_cCodCli == "000316")
			_cQuery += " INNER JOIN "+RetSqlName("SB1")+" SB1 (nolock)  "
			_cQuery += "             ON SB1.B1_COD = C6_PRODUTO "
			_cQuery += "                AND "+RetSqlCond("SB1")+" "
			// 080 - CARREGAMENTO COM MAO DE OBRA / FRACIONADO
			_cQuery += "                AND ( ( SZT.ZT_CODIGO = '080' AND SB1.B1_ZGRPEST IN ( '0001', '0003', '0011') ) "
			// 133 - CARREGAMENTO COM MAO DE OBRA / AROS GRANDES
			_cQuery += "                        OR ( SZT.ZT_CODIGO = '133' AND SB1.B1_ZGRPEST IN ( '0002', '0004', '0009' ) )  "
			// 128 - DESCARGA COM MÃO DE OBRA/AROS GRANDES
			_cQuery += "                        OR ( SZT.ZT_CODIGO = '128' AND SB1.B1_ZGRPEST IN ( '0100' ) ) ) "
		EndIf

		// tabela de itens do pedido
		_cQuery += "               WHERE  "+RetSqlCond("SC6")+" "
		_cQuery += "                 AND C6_NUM = Z6_PEDIDO),Z7_QUANT) "
	Else
		_cQuery += "         ELSE Z7_QUANT "
	EndIf
	_cQuery += "       END                                                          Z7_QUANT, "
	_cQuery += "       Z7_TIPOPER, "
	_cQuery += "       CONVERT(VARCHAR(8000), CONVERT(VARBINARY(8000), Z7_OBSERVA)) AS Z7_OBSERVA, "
	_cQuery += "       Substring(SZ7.Z7_NUMOS, 7, 3)                                SEQOS, "
	_cQuery += "       '.F.'                                                        IT_DEL "
	_cQuery += " FROM   "+RetSqlTab("SZ6")+", "
	_cQuery += "       "+RetSqlTab("SZ7")+", "
	_cQuery += "       "+RetSqlTab("SZT")+" "
	_cQuery += " WHERE  Z6_NUMOS = Z7_NUMOS "

	// caso a operação seja de finalização em massa utiliza o prefixo da OS
	If (mvEmMassa)
		_cQuery += "        AND SUBSTRING(Z6_NUMOS,1,6) = '"+_cPrefixOS+"' "
	Else
		_cQuery += "        AND Z6_NUMOS = '"+_cNumOs+"' "
	EndIf

	// validações e condições
	_cQuery += "        AND ZT_CODIGO = Z7_CODATIV "

	// só estiver editando/programando, só mostra as abertas
	If (bEdit)
		_cQuery += "        AND Z6_STATUS = 'A' "
	EndIf
	_cQuery += "        AND "+RetSqlCond("SZ6")+" "
	_cQuery += "        AND "+RetSqlCond("SZ7")+" "
	_cQuery += "        AND "+RetSqlCond("SZT")+" "
	_cQuery += " ORDER  BY Z7_ORDEM "

	memowrit("C:\query\twmsa002_acols.txt", _cQuery)

	// jogo o resultado da query para o array
	_aColsAtv := U_SqlToVet(_cQuery)

	// definicao da tela
	oDlgOrdemServ := MSDialog():New(000,000,550,800,"Ordem de Serviço",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho para os botoes
	oPnlCabec := TPanel():New(000,000,nil,oDlgOrdemServ,,.F.,.F.,,,000,020,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// botoes de operacoes
	// confirmar OS
	_oBtnConfOS := TButton():New(004,010,"Confirmar (F8)",oPnlCabec,{|| MsgRun("Finalizando Registro(s)...", "Aguarde...", {|| CursorWait(), sfFinalizaOS(mvEmMassa), CursorArrow()})},040,014,,,,.T.,,"",,,,.F. )
	_oBtnConfOS:bWhen := {|| bEdit }
	// fechar
	_oBtnFechar := TButton():New(004,060,"Sair (F9)",oPnlCabec,{|| oDlgOrdemServ:End() },040,014,,,,.T.,,"",,,,.F. )

	// numero da OS
	_oSayNrOS := TSay():New(006,160,{|| "Número: "+Transf(_cNumOS,PesqPict("SZ6","Z6_NUMOS")) },oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)

	// cria o panel do folder
	_oPnlFolder := TPanel():New(000,000,nil,oDlgOrdemServ,,.F.,.F.,,,000,135,.T.,.F. )
	_oPnlFolder:Align:= CONTROL_ALIGN_TOP

	// cria objeto com as pastas
	_oFolder := TFolder():New(000,000,_aFolders,,_oPnlFolder,,,,.T.,,300,1200)
	_oFolder:Align:= CONTROL_ALIGN_ALLCLIENT

	// 1a pasta - dados do cliente
	oSayCliente := TSay():New(005,010,{||"Cód/Loja Cliente"},_oFolder:aDialogs[1],,oFntVerd15,.F.,.F.,.F.,.T.)
	oGetCodCli := TGet():New(003,100,{|u| If(PCount()>0,_cCodCli:=u,_cCodCli)},_oFolder:aDialogs[1],050,010,PesqPict("SA1","A1_COD"),,,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cCodCli",,)
	oGetLojCli := TGet():New(003,155,{|u| If(PCount()>0,_cLojCli:=u,_cLojCli)},_oFolder:aDialogs[1],020,010,PesqPict("SA1","A1_LOJA"),,,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cLojCli",,)
	oGetNomCli := TGet():New(003,180,{|u| If(PCount()>0,_cNomCli:=u,_cNomCli)},_oFolder:aDialogs[1],180,010,PesqPict("SA1","A1_NOME"),,,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomCli",,)
	oGetCodCli:Disable()
	oGetLojCli:Disable()
	oGetNomCli:Disable()

	// 1a pasta - data de movimentacao
	oSayDtMov := TSay():New(020,010,{||"Data da O.S."},_oFolder:aDialogs[1],,oFntVerd15,.F.,.F.,.F.,.T.)
	oGetCodRec := TGet():New(017,100,{|u| If(PCount()>0,_dEmissao:=u,_dEmissao)},_oFolder:aDialogs[1],070,010,,,,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_dEmissao",,)
	oGetCodRec:Disable()

	// 1a pasta - tipo de movimento
	oSayTpMov := TSay():New(020,190,{||"Tipo de Movimento"},_oFolder:aDialogs[1],,oFntVerd15,.F.,.F.,.F.,.T.)
	oGetTpMov :=  TComboBox():New(017,280,{|u| If(PCount()>0,_cTpMov:=u,_cTpMov)},_aTpMov,060,010,_oFolder:aDialogs[1],,,,,,.T.,oFntVerd15,"",,,,,,,_cTpMov)
	oGetTpMov:Disable()

	// 1a pasta - numero e item da programacao
	oSayProgram := TSay():New(035,010,{||"Programação/Item"},_oFolder:aDialogs[1],,oFntVerd15,.F.,.F.,.F.,.T.)
	oGetNumProg := TGet():New(033,100,{|u| If(PCount()>0,_cCodigo:=u,_cCodigo)},_oFolder:aDialogs[1],050,010,PesqPict("SZ6","Z6_CODIGO"),,,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cCodigo",,)
	oGetIteProg := TGet():New(033,155,{|u| If(PCount()>0,_cItem:=u,_cItem)},_oFolder:aDialogs[1],020,010,PesqPict("SZ6","Z6_ITEM"),,,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cItem",,)
	oGetNumProg:Disable()
	oGetIteProg:Disable()
	If _cTpMov == "E"
		// Container
		oSayContain := TSay():New(050,010,{||"Container"},_oFolder:aDialogs[1],,oFntVerd15,.F.,.F.,.F.,.T.)
		oGetContain := TGet():New(047,100,{|u| If(PCount()>0,_cContain:=u,_cContain)},_oFolder:aDialogs[1],060,010,,,,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cContain",,)
		oGetContain:Disable()
		// RIC
		oSayRIC := TSay():New(065,010,{||"RIC"},_oFolder:aDialogs[1],,oFntVerd15,.F.,.F.,.F.,.T.)
		oGetRIC := TGet():New(062,100,{|u| If(PCount()>0,_cRIC:=u,_cRIC)},_oFolder:aDialogs[1],060,010,,,,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cRIC",,)
		oGetRIC:Disable()
	EndIf
	If _cTpMov == "S"
		oSayProgram := TSay():New(050,010,{||"Pedido de Venda"},_oFolder:aDialogs[1],,oFntVerd15,.F.,.F.,.F.,.T.)
		oGetNumProg := TGet():New(047,100,{|u| If(PCount()>0,_cNumPed:=u,_cNumPed)},_oFolder:aDialogs[1],050,010,PesqPict("SZ6","Z6_PEDIDO"),,,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNumPed",,)
		oGetNumProg:Disable()
	EndIf
	If _cTpMov == "I"
		oSayDocSerie := TSay():New(050,010,{||"Doc.Serie NF"},_oFolder:aDialogs[1],,oFntVerd15,.F.,.F.,.F.,.T.)
		oGetDocSerie := TGet():New(047,100,{|u| If(PCount()>0,_cDocSerie:=u,_cDocSerie)},_oFolder:aDialogs[1],050,010,PesqPict("SF1","F1_DOC"),,,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cDocSerie",,)
		oGetDocSerie:Disable()
	EndIf

	// traz a data atual, caso os campos não foram preenchidos ainda
	// somente trás a data se estiver na finalização para auxiliar
	If ( Empty( _dDtInic ) ) .and. ( Empty( _dDtFim ) ) .and. ( bEdit )
		_dDtInic := Date()
		_dDtFim  := Date()
	EndIf

	// 1a pasta - Hora Inicio
	_oSayHoraI := TSay():New(080,010,{||"Data/Hora Início"},_oFolder:aDialogs[1],,oFntVerd15,.F.,.F.,.F.,.T.)
	_oGetDtIni := TGet():New(078,100,{|u| If(PCount()>0,_dDtInic:=u,_dDtInic)},_oFolder:aDialogs[1],060,010,PesqPict("SZ6","Z6_DATAINI"),{|| _dDtFim := _dDtInic ,.t.},,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_dDtInic",,)
	_oGetHoraI := TGet():New(078,170,{|u| If(PCount()>0,_cHoraI:=u,_cHoraI)},_oFolder:aDialogs[1],030,010,PesqPict("SZ6","Z6_HORAINI"),{|| sfVldHora(_cHoraI) },,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cHoraI",,)
	_oGetDtIni:bWhen := {|| bEdit }
	_oGetHoraI:bWhen := {|| bEdit }

	// 1a pasta - Hora Fim
	_oSayHoraF := TSay():New(095,010,{||"Data/Hora Fim"},_oFolder:aDialogs[1],,oFntVerd15,.F.,.F.,.F.,.T.)
	_oGetDtFim := TGet():New(093,100,{|u| If(PCount()>0,_dDtFim:=u,_dDtFim)},_oFolder:aDialogs[1],060,010,PesqPict("SZ6","Z6_DATAINI"),,,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_dDtFim",,)
	_oGetHoraF := TGet():New(093,170,{|u| If(PCount()>0,_cHoraF:=u,_cHoraF)},_oFolder:aDialogs[1],030,010,PesqPict("SZ6","Z6_HORAFIM"),{|| sfVldHora(_cHoraF)},,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cHoraF",,)
	_oGetDtFim:bWhen := {|| bEdit }
	_oGetHoraF:bWhen := {|| bEdit }

	// 2a pasta - condicao carga
	oSayCondCarga := TSay():New(005,010,{||"Condição Carga"},_oFolder:aDialogs[2],,oFntVerd15,.F.,.F.,.F.,.T.)
	oGetCondCarga :=  TComboBox():New(003,080,{|u| If(PCount()>0,_cCondCarga:=u,_cCondCarga)},_aCondCarga,050,010,_oFolder:aDialogs[2],,,,,,.T.,oFntVerd15,"",,,,,,,_cCondCarga)
	oGetCondCarga:bWhen := {|| bEdit }

	// 2a pasta - Quantidade Mao de Obra
	//_oSayQtdMO := TSay():New(005,140,{||"Qtde. Mao-Obra"},_oFolder:aDialogs[2],,oFntVerd15,.F.,.F.,.F.,.T.)
	//_oGetQtdMO := TGet():New(003,210,{|u| If(PCount()>0,_nQtdMO:=u,_nQtdMO)},_oFolder:aDialogs[2],030,010,PesqPict("SZ6","Z6_QTDMO"),,,,oFntVerd15,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nQtdMO",,)
	//_oGetQtdMO:bWhen := {|| bEdit }

	// preencho a lista de operadores
	_vListOper := sfRetRecHum(bEdit,_cNumOS,"WMS03;WMS04")

	// valido se encontrou registros
	_lSemOper := .T.    // alterado por solicitação Daniel 04/09/19

	// 2a pasta - Operadores
	_oSayOper := TSay():New(020,010,{||"Operador(es)"},_oFolder:aDialogs[2],,oFntVerd15,.F.,.F.,.F.,.T.)
	_oLstOper := TListBox():New(017,080,,_vListOper,220,040,,_oFolder:aDialogs[2],,,,.T.,,{|| sfSelItem(_oLstOper) },oFntCour18,"",,,,,,, )
	_oLstOper:bWhen := {|| (bEdit).and.(!_lSemOper) }
	// 2a pasta - opcao sem operadores
	_oCbSemOper := TCheckBox():New(020,310,"Sem Operador(es)", {|u| If(PCount()>0,_lSemOper:=u,_lSemOper)},_oFolder:aDialogs[2],80,12,,,oFntVerd15,,,,,.T.,"",, )
	_oCbSemOper:bWhen := {|| bEdit }
	_oCbSemOper:bLClicked := {|| _oLstOper:Refresh() }

	// 2a pasta - Conferentes
	oSayConferente := TSay():New(065,010,{||"Conferente(s)"},_oFolder:aDialogs[2],,oFntVerd15,.F.,.F.,.F.,.T.)
	_oLstConf := TListBox():New(062,080,,_vListConf,220,040,,_oFolder:aDialogs[2],,,,.T.,,{|| sfSelItem(_oLstConf) },oFntCour18,"",,,,,,, )
	_oLstConf:bWhen := {|| (bEdit).and.(!_lSemConf) }
	// 2a pasta - opcao sem conferentes
	_oCbSemConf := TCheckBox():New(065,310,"Sem Conferentes(es)", {|u| If(PCount()>0,_lSemConf:=u,_lSemConf)},_oFolder:aDialogs[2],80,12,,,oFntVerd15,,,,,.T.,"",, )
	_oCbSemConf:bWhen := {|| bEdit }
	_oCbSemConf:bLClicked := {|| _oLstConf:Refresh() }

	// 3a pasta - Observacoes
	_oSayObs := TSay():New(005,010,{||"Observações"},_oFolder:aDialogs[3],,oFntVerd15,.F.,.F.,.F.,.T.)
	@ 003,100 GET oGetObs  VAR _cObs MEMO SIZE 190,080 OF _oFolder:aDialogs[3] PIXEL When bEdit

	// browse com a listagem das atividades
	_oBrwAtividade := MsNewGetDados():New(000,000,200,400,Iif(bEdit,Iif(mvEmMassa,GD_UPDATE,GD_INSERT+GD_UPDATE),Nil),'AllwaysTrue()','AllwaysTrue()',,,,9999,'AllwaysTrue()','','AllwaysTrue()',oDlgOrdemServ,_aHeadAtv,_aColsAtv)
	_oBrwAtividade:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// 4a pasta - equipamentos

	// browse com a listagem dos equipmentos utilizados
	_oBrwEquip := MsNewGetDados():New(000,000,200,400,Iif(bEdit,GD_INSERT+GD_UPDATE,Nil),'AllwaysTrue()','AllwaysTrue()',,,,9999,'AllwaysTrue()','','AllwaysTrue()',_oFolder:aDialogs[4],_aHeadEqu,_aColsEqu)
	_oBrwEquip:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwEquip:oBrowse:bWhen := {|| (bEdit).and.(!_lSemEquip) }

	// cria o panel para separar a lista de equipamentos
	_oPnlEquip := TPanel():New(000,000,nil,_oFolder:aDialogs[4],,.F.,.F.,,,000,016,.T.,.F. )
	_oPnlEquip:Align:= CONTROL_ALIGN_BOTTOM

	// 4a pasta - opcao sem equipamentos
	_oCbSemEquip := TCheckBox():New(005,010,"Sem Equip./Máquinas", {|u| If(PCount()>0,_lSemEquip:=u,_lSemEquip)},_oPnlEquip,090,12,,,oFntVerd15,,,,,.T.,"",, )
	_oCbSemEquip:bWhen := {|| bEdit }
	_oCbSemEquip:bLClicked := {|| _oBrwEquip:Refresh() }

	// 5a pasta - Servicos Gerais / Mao de Obra
	oSayServGerais := TSay():New(005,010,{||"Serviços Gerais"},_oFolder:aDialogs[5],,oFntVerd15,.F.,.F.,.F.,.T.)
	_oLstSrvGer := TListBox():New(003,080,,_vListSrvGer,220,040,,_oFolder:aDialogs[5],,,,.T.,,{|| sfSelItem(_oLstSrvGer) },oFntCour18,"",,,,,,, )
	_oLstSrvGer:bWhen := {|| (bEdit).and.(!_lSemSrvGer) }
	// opcao sem Servicos Gerais
	_oCbSemSrvGer := TCheckBox():New(005,310,"Sem Serviços Gerais", {|u| If(PCount()>0,_lSemSrvGer:=u,_lSemSrvGer)},_oFolder:aDialogs[5],80,12,,,oFntVerd15,,,,,.T.,"",, )
	_oCbSemSrvGer:bWhen := {|| bEdit }
	_oCbSemSrvGer:bLClicked := {|| _oLstSrvGer:Refresh() }

	// 5a pasta - opcao sem mao de obra
	_oCbSemMaoObr := TCheckBox():New(050,010,"Sem Mão de Obra 3a.", {|u| If(PCount()>0,_lSemMaoObr:=u,_lSemMaoObr)},_oFolder:aDialogs[5],090,12,,,oFntVerd15,,,,,.T.,"",, )
	_oCbSemMaoObr:bWhen := {|| bEdit }
	_oCbSemMaoObr:bLClicked := {|| _oBrwMaoObr:Refresh() }

	// fornecedor de mao de obra
	_oCbFornMaoObr := TComboBox():New(048,100,{|u| If(PCount()>0,_cMoFornec:=u,_cMoFornec)},_aMoFornec,140,010,_oFolder:aDialogs[5],,,,,,.T.,,"",,,,,,,_cMoFornec)
	_oCbFornMaoObr:bWhen := {|| bEdit }
	_oCbFornMaoObr:bLClicked := {|| _oBrwMaoObr:Refresh() }

	// 5a pasta - browse com a listagem da mao de obra utilizada
	_oBrwMaoObr := MsNewGetDados():New(060,010,116,380, Iif(bEdit, GD_INSERT+GD_UPDATE, Nil),'AllwaysTrue()','AllwaysTrue()',,,,9999,'AllwaysTrue()','','AllwaysTrue()',_oFolder:aDialogs[5],_aHeadMaoObr,_aColsMaoObr)
	_oBrwMaoObr:oBrowse:bWhen := {|| (bEdit).and.(!_lSemMaoObr) }

	// esconde abas 2, 4 e 5 (para manter o processamento por trás)
	// alterado por solicitação Daniel 04/09/19
	_oFolder:HidePage(2)
	_oFolder:HidePage(4)
	_oFolder:HidePage(5)
	_oFolder:Showpage(1)  //seta denovo a aba 1 como ativa
//	_oFolder:Refresh()

	// ativa o dialogo
	oDlgOrdemServ:Activate(,,,.T.,{|| _oBrwAtividade:TudoOK()})

	//encerra
	sfEncerraFim()

Return(.t.)

// ** funcao para validar a quantidade
User Function WMSA002Q()
	// variavel de retorno
	local _lRet := .t.
	// quantidade informada
	local _nQtdInf := M->Z7_QUANT

	// posiciona no cadastro de atividades
	dbSelectArea("SZT")
	SZT->(dbSetORder(1)) //1-ZT_FILIAL, ZT_CODIGO
	SZT->(dbSeek( xFilial("SZT")+_oBrwAtividade:aCols[_oBrwAtividade:nAt,1] ))

	// verifica se a quantidade esta dentro da Qtd Min e Max da Atividade
	If (_lRet).and.((_nQtdInf < SZT->ZT_QTDMIN).or.(_nQtdInf > SZT->ZT_QTDMAX))
		Alert("A quantidade informada deve estar dentro da quantidade mínima e máxima estipulada!!")
		_lRet := .f.
	EndIf

	// valida unidade de medida CO=Container (aceita somente 1)
	//If _oBrwAtividade:aCols[_oBrwAtividade:nAt,3] == "CO"
	//	_lRet := .F.
	//EndIf

Return(_lRet)

// ** funcao para validar o codigo da atividade
User Function WMSA002V()

	local _lRet := .t.
	local i := 0

	If _oBrwAtividade:aCols[_oBrwAtividade:nAt,6] $ "P|A"
		Alert("Esta atividade não pode ser alterada !!")
		_lRet := .F.
	EndIf

	If (_lRet)
		For i:=1 To len(_oBrwAtividade:aCols)
			If !_oBrwAtividade:aCols[i,len(_aHeadAtv)+1]
				If i <> _oBrwAtividade:nAt .AND. AllTrim(_oBrwAtividade:aCols[i,1]) == AllTrim(M->Z7_CODATIV)
					Alert("Esta atividade ja existe e não pode ser incluida novamente !!")
					_lRet := .F.
				EndIf
			EndIf
		Next i
	EndIf

	// valida se a atividade esta no contrato
	If (_lRet)
		dbSelectArea("SZ9")
		SZ9->(dbSetOrder(2)) // 2-Z9_FILIAL, Z9_CODATIV, Z9_CONTRAT
		If ( ! SZ9->(dbSeek( xFilial("SZ9") + M->Z7_CODATIV + _cNrContrat )) )
			Alert("Atividade não permitida neste contrato!")
			_lRet := .F.
		EndIf
	EndIf

	If (_lRet)
		dbSelectArea("SZT")
		dbSetOrder(1)
		If dbSeek(xFilial("SZT")+M->Z7_CODATIV)
			_oBrwAtividade:aCols[_oBrwAtividade:nAt,2] := SZT->ZT_DESCRIC
			_oBrwAtividade:aCols[_oBrwAtividade:nAt,3] := SZ9->Z9_UNIDCOB
			If (SZ9->Z9_UNIDCOB == "CO")
				_oBrwAtividade:aCols[_oBrwAtividade:nAt,5] := 1
			EndIf
		Else
			Alert("Atividade invalida !!")
			_lRet := .F.
		EndIf
	EndIf

Return(_lRet)

// ** funcao que valida e finaliza a OS
Static Function sfFinalizaOS(mvEmMassa)
	// area inicial
	local _aAreaSZ6 := SZ6->(GetArea())

	// variaveis temporarias
	local _nX, i
	local _nCol
	local _nTmpCusto
	local _cTmpObs

	// lista dos recursos humanos selecionados
	local _aRecHuman := {}
	// tempo total
	local _nTempoTot := 0
	// quantidade de carregamento
	local _nQtdCarreg := 0
	// variavel de retorno
	local _lRet := .t.

	// controle de log geral
	local _cLogGeral := ""
	local _lLogAtiv := .f.
	local _lLogMaoObr := .f.
	local _lLogQtdCarr := .f.
	local _lLogOper := .f.
	local _lLogConf := .f.
	local _lLogSrvGer := .f.
	local _lLogEquip := .f.
	local _lLogData := .f.

	// base da OS para finalizacao
	local _nQtdCaract := If(mvEmMassa,6,9)
	local _cChvNrOs   := Left(_cNumOS,_nQtdCaract)
	local _cSeqOS     := ""

	// posicao dos campos
	local _nObs   := aScan(_aHeadAtv,{|x| AllTrim(x[2])=="Z7_OBSERVA"})
	local _nFat   := aScan(_aHeadAtv,{|x| AllTrim(x[2])=="Z7_FATURAR"})
	local _nAtv   := aScan(_aHeadAtv,{|x| AllTrim(x[2])=="Z7_CODATIV"})
	local _nSeqOS := aScan(_aHeadAtv,{|x| AllTrim(x[2])=="Z7_SEQOS"})

	// variavel que contém o sufixo/sequencia da OS
	local _cSufixOS := ""
	local _lDuplCar := .f.

	// valida quantidade
	For _nX := 1 To len(_oBrwAtividade:aCols)
		// linha deletada
		If (!_oBrwAtividade:aCols[_nX,len(_aHeadAtv)+1])
			If (_oBrwAtividade:aCols[_nX,5] <= 0)
				_cLogGeral += sfAddLog("001",@_lLogAtiv,"Linha "+StrZero(_nX,3))
				_lRet := .f.
			EndIf

			// controle de atividade para carregamento
			If (_cTpMov == "S").and.(Posicione("SZT",1,xFilial("SZT")+_oBrwAtividade:aCols[_nX,1],"ZT_TIPO") $ "CT|CF")

				If ( ! Empty(_cSeqOS) ) .and. ( _cSeqOS != _oBrwAtividade:aCols[_nX,_nSeqOS] ) .and. ( ! Empty(_oBrwAtividade:aCols[_nX,_nSeqOS]))
					_nQtdCarreg := 1
				Else
					// incremento da validação
					_nQtdCarreg ++
				EndIf
				// define a sequencia da OS
				_cSeqOS := Substr(_cNumOS,7,3)
			EndIf
		EndIf
	Next _nX

	// valida campo observacao
	For _nX := 1 To len(_oBrwAtividade:aCols)
		// linha deletada
		If (!_oBrwAtividade:aCols[_nX,len(_aHeadAtv)+1])
			// remove <enter> do campo observacao para testar conteudo valido
			_cTmpObs := AllTrim(_oBrwAtividade:aCols[_nX,_nObs])
			_cTmpObs := StrTran(_cTmpObs,CRLF,"")
			// testa os campos
			If ( ! _oBrwAtividade:aCols[_nX,Len(_aHeadAtv)+1]).And.(_oBrwAtividade:aCols[_nX,_nFat] == "N").And.( Len(_cTmpObs) < 10 )
				_cLogGeral += sfAddLog("009",@_lLogAtiv,"Atividade: "+_oBrwAtividade:aCols[_nX,_nAtv]+" - Informar Motivo para NÃO faturar")
				_lRet := .f.
			EndIf
		EndIf
	Next _nX

	// valida Campos Obrigatorios - MAO DE OBRA
	If (!_lSemMaoObr)
		For _nX := 1 To len(_oBrwMaoObr:aCols)
			// linha deletada
			If (!_oBrwMaoObr:aCols[_nX,len(_aHeadMaoObr)+1])
				// varre todos os campos
				For _nCol := 1 to Len(_aHeadMaoObr)
					// testa conteudo do campo
					If (Empty(_oBrwMaoObr:aCols[_nX,_nCol]))
						_cLogGeral += sfAddLog("002",@_lLogMaoObr,"Linha "+StrZero(_nX,3)+" Campo ["+AllTrim(_aHeadMaoObr[_nCol,1])+"]")
						_lRet := .f.
					EndIf
				Next _nCol
			EndIf
		Next _nX
	EndIf

	// valida a quantidade de carregamento
	If (_cTpMov == "S").and.(_nQtdCarreg > 1)
		_cLogGeral += sfAddLog("003",@_lLogQtdCarr,"Permitido: 1 -> Quantidade informada: "+Str(_nQtdCarreg,2))
		_lRet := .f.
	EndIf

	// verifica se foi selecionado o operador
	If (!_lSemOper).and.(!sfVldRecHum(_oLstOper,@_aRecHuman))
		_cLogGeral += sfAddLog("004",@_lLogOper,"É obrigatório informar o(s) operadore(s)!")
		_lRet := .f.
	EndIf

	// verifica se foi selecionado o conferente
	If (!_lSemConf).and.(!sfVldRecHum(_oLstConf,@_aRecHuman))
		_cLogGeral += sfAddLog("005",@_lLogConf,"É obrigatório informar o(s) conferente(s)!")
		_lRet := .f.
	EndIf

	// verifica se foi selecionado os Servicos Gerais
	If (!_lSemSrvGer).and.(!sfVldRecHum(_oLstSrvGer,@_aRecHuman))
		_cLogGeral += sfAddLog("006",@_lLogSrvGer,"É obrigatório informar o(s) Serviços Gerais!")
		_lRet := .f.
	EndIf

	// verifica se foi selecionado os equipamentos
	If (!_lSemEquip).and.(Empty(_oBrwEquip:aCols[1,1]))
		_cLogGeral += sfAddLog("007",@_lLogEquip,"É obrigatório informar a(s) máquina(s)/equipamento(s)!")
		_lRet := .f.
	EndIf

	// valida datas inicial e final
	If ((Empty(_dDtInic)).OR.(Empty(_dDtFim))).or.( (_dDtInic != _dDtFim).and.(_dDtInic > _dDtFim) )
		_cLogGeral += sfAddLog("008",@_lLogData,"Dt Inicial "+DtoC(_dDtInic)+" / Dt Final "+DtoC(_dDtFim))
		_lRet := .f.
	EndIf

	// valida hora inicial e final
	If ((Empty(_cHoraI)).OR.(Empty(_cHoraF)))
		_cLogGeral += sfAddLog("008",@_lLogData,"Hora Inicial "+_cHoraI+" / Hora Final "+_cHoraF)
		_lRet := .f.
	EndIf

	// valida hora inicial e final - datas
	If (_dDtInic == _dDtFim).and.(_cHoraI >= _cHoraF)
		_cLogGeral += sfAddLog("008",@_lLogData,"Dt/Hora Inicial "+DtoC(_dDtInic)+" "+_cHoraI+" / Dt/Hora Final "+DtoC(_dDtFim)+" "+_cHoraF)
		_lRet := .f.
	EndIf

	// log geral
	If (!_lRet)
		HS_MsgInf("ATENÇÃO: favor analisar as divergências abaixo!"+;
		If(Empty(_cLogGeral),"",CRLF+CRLF+"LOG:"+CRLF+_cLogGeral) ,;
		"Finalização de Ordem de Serviço",;
		"Finalização de Ordem de Serviço" )

		// restaura area inicial
		RestArea(_aAreaSZ6)
		Return(_lRet)
	EndIf


	// calcula o tempo da operacao (retorno em centesimal)
	_nTempoTot := A680Tempo(_dDtInic, _cHoraI, _dDtFim, _cHoraF)
	// converte para horas normais
	_nTempoTot := fConvHr(_nTempoTot,"H")


	// INICIA TRANSACAO
	BEGIN Transaction

		// procuro os registros para que o while compreenda todas as seq da OS
		dbSelectArea("SZ6")
		SZ6->( dbSetOrder(1) ) // FILIAL+NUMOS
		// a variavel private _cPrefixOS é alimentada ao abrir uma OS específica
		SZ6->( dbSeek( xFilial("SZ6")+ IIF(mvEmMassa, _cPrefixOS+"001", _cChvNrOs) ) )

		// processa todas as OS's conforme While
		While SZ6->(!Eof()).and.(SZ6->Z6_FILIAL == xFilial("SZ6")).and.(Left(SZ6->Z6_NUMOS,_nQtdCaract)==_cChvNrOs)

			// valido o status da OS
			If (SZ6->Z6_STATUS != "A")
				SZ6->(dbSkip())
				Loop
			EndIf

			// atualiza variável do sufixo da OS
			_cSufixOS := Substr(SZ6->Z6_NUMOS,7,3)

			// atualiza os dados do cabeçalho da OS
			dbSelectArea("SZ6")
			Reclock("SZ6",.F.)
			SZ6->Z6_CONDCAR	:= _cCondCarga
			SZ6->Z6_QTDMO	:= _nQtdMO
			SZ6->Z6_OBSERVA	:= _cObs
			SZ6->Z6_DATAINI	:= _dDtInic
			SZ6->Z6_HORAINI	:= _cHoraI
			SZ6->Z6_DATAFIM	:= _dDtFim
			SZ6->Z6_HORAFIM	:= _cHoraF
			SZ6->Z6_HORTOT	:= _nTempoTot
			SZ6->Z6_DTFINAL	:= Date()
			SZ6->Z6_STATUS	:= "F"
			SZ6->(MsUnlock())

			// varre todo o acols pra pegar as informações
			For i:=1 To Len(_oBrwAtividade:aCols)

				dbSelectArea("SZ7")
				dbSetOrder(1)
				// busca pela OS e Serviços na Z07
				If dbSeek(xFilial("SZ7")+SZ6->Z6_NUMOS+_oBrwAtividade:aCols[i,1])
					// se for daquele prefixo, salva os dados
					If (_oBrwAtividade:aCols[i,8] == _cSufixOS)
						// se não estiver deletado, grava os registros
						If !_oBrwAtividade:aCols[i,len(_aHeadAtv)+1]
							// atualiza SZ3 com o conteudo do caminhão - Cheio ou Vazio
							sfConteudo(_oBrwAtividade:aCols[i,1])
							Reclock("SZ7",.F.)
							SZ7->Z7_QUANT	:= _oBrwAtividade:aCols[i,5]
							SZ7->Z7_SALDO	:= _oBrwAtividade:aCols[i,5]
							SZ7->Z7_FATURAR	:= _oBrwAtividade:aCols[i,4]
							SZ7->Z7_OBSERVA	:= _oBrwAtividade:aCols[i,7]
							SZ7->(MsUnlock())
						Else
							Reclock("SZ7",.F.)
							dbDelete()
							SZ7->(MsUnlock())
						EndIf
					EndIf
					// caso não há registro da OS + Serviço, vai incluir os registros
				Else
					// se for daquele prefixo, insere os dados
					// caso não foi informado o prefixo (inclusão), insere o registro
					If (_oBrwAtividade:aCols[i,8] == _cSufixOS).Or.(Empty(_oBrwAtividade:aCols[i,8]))
						If !_oBrwAtividade:aCols[i,len(_aHeadAtv)+1]
							sfConteudo(_oBrwAtividade:aCols[i,1])
							Reclock("SZ7",.T.)
							SZ7->Z7_FILIAL	:= xFilial("SZ7")
							SZ7->Z7_NUMOS	:= SZ6->Z6_NUMOS
							SZ7->Z7_CODATIV	:= _oBrwAtividade:aCols[i,1]
							SZ7->Z7_UNIDCOB	:= _oBrwAtividade:aCols[i,3]
							SZ7->Z7_QUANT	:= _oBrwAtividade:aCols[i,5]
							SZ7->Z7_SALDO	:= _oBrwAtividade:aCols[i,5]
							SZ7->Z7_FATURAR	:= _oBrwAtividade:aCols[i,4]
							SZ7->Z7_TIPOPER	:= _oBrwAtividade:aCols[i,6]
							SZ7->Z7_OBSERVA	:= _oBrwAtividade:aCols[i,7]
							SZ7->(MsUnlock())
						EndIf
					EndIf
				EndIf

				// controle se deve agrupar no pacote logistico
				// se for movimentacao de ENTRADA, sem TEM container, se a linha nao esta DELETADA e se FATURAR esta SIM
				If (SZ6->Z6_TIPOMOV == "E").and.(!Empty(SZ6->Z6_CONTAIN)).and.(!_oBrwAtividade:aCols[i,len(_aHeadAtv)+1]).and.(_oBrwAtividade:aCols[i,4]=="S")
					// rotina para agrupar a OS no pacote logistico
					sfAgrOrdSrv()

				EndIf

			Next i

			// grava os recursos humanos - operadores / conferentes
			For _nX := 1 to Len(_aRecHuman)
				// funcao que grava o recurso humano
				sfGrvRecHum(SZ6->Z6_NUMOS,;
				Date(),;
				_dDtInic,;
				_cHoraI,;
				_dDtFim,;
				_cHoraF,;
				_nTempoTot,;
				_aRecHuman[_nX,1],; // cod usuario
				_aRecHuman[_nX,2] ) // cod funcao
			Next _nX

			// grava as maquinas e equipamentos
			If (!_lSemEquip)
				For _nX := 1 to Len(_oBrwEquip:aCols)
					// verifica se o codigo foi informado
					If ( ! Empty(_oBrwEquip:aCols[_nX,1]))

						// posiciona no cadastro do equipamento
						dbSelectArea("SZQ")
						SZQ->(dbSetOrder(1)) // 1-ZQ_FILIAL, ZQ_CODIGO
						SZQ->(dbSeek( xFilial("SZQ")+_oBrwEquip:aCols[_nX,1] ))

						// realiza o calculo do custo
						//_nTmpCusto := Round( fConvHr(_oBrwEquip:aCols[_nX,5],"D") * SZQ->ZQ_CUSTHOR,2)
						_nTmpCusto := Round( fConvHr(_nTempoTot,"D") * SZQ->ZQ_CUSTHOR,2)

						// equipamentos por OS
						dbSelectArea("SZP")
						RecLock("SZP",.t.)
						SZP->ZP_FILIAL	:= xFilial("SZP")
						SZP->ZP_NUMOS	:= SZ6->Z6_NUMOS
						SZP->ZP_CODEQUI	:= _oBrwEquip:aCols[_nX,1]
						SZP->ZP_HORTOT	:= _nTempoTot
						SZP->ZP_CUSTO	:= _nTmpCusto
						SZP->(MsUnLock())
					EndIf
				Next _nX
			EndIf

			// grava mao de obra
			If (!_lSemMaoObr)
				For _nX := 1 to Len(_oBrwMaoObr:aCols)
					// verifica se o codigo foi informado
					If ( ! Empty(_oBrwMaoObr:aCols[_nX,1]))
						// mao de obra por OS
						dbSelectArea("SZX")
						RecLock("SZX",.t.)
						SZX->ZX_FILIAL	:= xFilial("SZX")
						SZX->ZX_NUMOS	:= SZ6->Z6_NUMOS
						SZX->ZX_CODTAB	:= _cTabMaoObr
						SZX->ZX_TPOPER	:= _oBrwMaoObr:aCols[_nX,1]
						SZX->ZX_ITEMTAB	:= _oBrwMaoObr:aCols[_nX,2]
						SZX->ZX_DSCOPER	:= _oBrwMaoObr:aCols[_nX,3]
						SZX->ZX_GUIA	:= _oBrwMaoObr:aCols[_nX,4]
						SZX->ZX_MERC	:= _oBrwMaoObr:aCols[_nX,5]
						SZX->ZX_FORNEC	:= Separa(_cMoFornec,"/")[1]
						SZX->ZX_LOJA	:= Separa(_cMoFornec,"/")[2]
						SZX->ZX_CUSTO	:= Posicione("SZV",1, xFilial("SZV")+_cTabMaoObr+_oBrwMaoObr:aCols[_nX,2],"ZV_VALOR") //1-ZV_FILIAL, ZV_CODIGO, ZV_ITEM
						SZX->(MsUnLock())
					EndIf
				Next _nX
			EndIf

			// proxima OS
			dbSelectArea("SZ6")
			SZ6->(dbSkip())
		EndDo

		// FINALIZA TRANSACAO
	End Transaction

	// restaura area inicial
	RestArea(_aAreaSZ6)

	// fecha a tela
	oDlgOrdemServ:End()

Return(.t.)

// ** funcao para atualizar o conteudo da movimentacao da carga
Static Function sfConteudo(mvCodAtiv)
	local _cQry
	local _cTpAtv := Posicione("SZT",1,xFilial("SZT")+mvCodAtiv,"ZT_TIPO")

	Do Case
		Case _cTpAtv = "UN"
		_cQry:="UPDATE "+RetSqlName("SZ3")+" SET Z3_CONTATU = 'C' WHERE Z3_RIC = '"+_cRIC+"' "
		TCSQLExec(_cQry)
		Case _cTpAtv = "DU"
		_cQry:="UPDATE "+RetSqlName("SZ3")+" SET Z3_CONTATU = 'V' WHERE Z3_RIC = '"+_cRIC+"' "
		TCSQLExec(_cQry)
	EndCase

Return(.t.)

Static Function sfConfirmarOS()

	// quantidade de carregamento
	local _nQtdCarreg := 0

	// variavel de controle de grupo de estoque
	local _cGrpEst := "", _cProgCli := ""
	local _cNrContra := ""
	local _cCodAtiv := ""
	local _cUnidCob := ""

	// variavel de controle de loop
	local _nX := 0

	// variavel para controle de atividades automáticas - exclusivo sumitomo
	local _aAtivSumi := {}

	// variavel para query
	local _cQuery := ""

	// valida se a programacao esta encerrada
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	If SZ1->(dbSeek( xFilial("SZ1") + _cNumProg ))
		If ( ! Empty(SZ1->Z1_DTFINFA))
			MsgStop("Programação encontra-se encerrada. Contate o setor de Faturamento.")
			Return(.f.)
		EndIf
	EndIf

	//Realiza Validacoes
	// - Containers Selecionado
	aCnt:={}

	If _cTpMov == "E"
		(CNT)->(dbGotop())
		While !(CNT)->(EOF())
			If (CNT)->CNT_OK == _cMarca
				Aadd(aCnt,{(CNT)->CNT_COD,_cTpMov,_cNumProg,_cIteProg,_cCodCli,_cLojCli,_dDtApont,"A",(CNT)->CNT_RIC,"","","",_cObs})
			EndIf
			(CNT)->(dbSkip())
		EndDo
		(CNT)->(dbGotop())
	EndIf

	If _cTpMov == "I"
		dbSelectArea("SD1")
		dbSetOrder(1)
		If dbSeek(xFilial("SD1")+_cDoc+_cSerie+_cCodCli+_cLojCli)
			If !Empty(SD1->D1_PROGRAM)
				Aadd(aCnt,{"",_cTpMov,SD1->D1_PROGRAM,SD1->D1_ITEPROG,_cCodCli,_cLojCli,_dDtApont,"A","",_cNumPed,_cDoc+_cSerie,"",_cObs})
			EndIf
		EndIf
	EndIf

	// ordem de servicos de SAIDA
	If ( _cTpMov == "S" )
		// query pra pegar os dados de carregamento
		_cQuery := " SELECT DISTINCT D1_PROGRAM, "
		_cQuery += "                 D1_ITEPROG, "

		// exclusivo pra SUMITOMO
		If ( _cCodCli == "000316" ) .and. ( _lAtvGrpEst )

			// pega informações para comparação com atividades pré-programadas
			_cQuery += " B1_ZGRPEST "
		Else
			// demais clientes e situações
			_cQuery += " '' B1_ZGRPEST "
		EndIf

		_cQuery += " FROM   " + RetSqlTab( "SC6" ) + "  (nolock) "
		_cQuery += "        INNER JOIN " + RetSqlTab("SD1") + " (nolock)  "
		_cQuery += "                ON " + RetSqlCond( "SD1" ) + " "
		_cQuery += "                   AND D1_FORNECE = C6_CLI "
		_cQuery += "                   AND D1_LOJA = C6_LOJA "
		_cQuery += "                   AND D1_DOC = C6_NFORI "
		_cQuery += "                   AND D1_SERIE = C6_SERIORI "
		_cQuery += "                   AND D1_ITEM = C6_ITEMORI "

		// exclusivo pra SUMITOMO
		If ( _cCodCli == "000316" ) .and. ( _lAtvGrpEst )

			// pego o grupo de estoque dos produtos listados
			_cQuery += "        INNER JOIN " + RetSqlTab("SB1") + " (nolock)  "
			_cQuery += "                ON " + RetSqlCond( "SB1" ) + " "
			_cQuery += "                   AND B1_COD = D1_COD "
		EndIf

		_cQuery += " WHERE  " + RetSqlCond("SC6") + " "
		_cQuery += "   AND C6_NUM = '" + _cNumPed + "' "

		// jogo registro pro txt pra debug
		memowrit("C:\query\twmsa002_confirmaos.txt", _cQuery)

		If ( ! Empty( Select ( "PRO" ) ) )
			dbSelectArea( "PRO" )
			dbCloseArea()
		EndIf

		TCQuery _cQuery NEW ALIAS "PRO"

		dbSelectArea( "PRO" )
		PRO->( dbGotop() )

		While PRO->(!EOF())
			Aadd(aCnt,{"", _cTpMov, PRO->D1_PROGRAM, PRO->D1_ITEPROG, _cCodCli, _cLojCli, _dDtApont, "A", "", _cNumPed, "", _cPlaca1, _cObs, PRO->B1_ZGRPEST })
			PRO->(dbSkip())
		EndDo

	EndIf

	// limpa a variavel
	aAtv := {}

	If len(aCnt) == 0
		MsgStop("Ordem de Servico não pode ser gerada !! Nenhum Container Selecionado ou Pedido de Venda Invalido !!")
		Return(.f.)

	EndIf

	// considera as atividades conforme grupo de estoque - david - 24/03
	If ( _cCodCli == "000316" ) .and. ( _cTpMov == "S" ) .and. ( _lAtvGrpEst ) // exclusivo sumitomo

		// limpo a variável
		_aAtivSumi := {}

		For _nX := 1 to Len(aCnt)

			// para não duplicar os itens
			If ( ! Empty(_cGrpEst) ) .and. ( aCnt[_nX][14] == _cGrpEst )
				// pra evitar duplicação, mas manter registro por programação
				If ( ! Empty(_cProgCli) ) .and. ( aCnt[_nX][3] == _cProgCli )
					loop
				EndIf
			EndIf

			// define grupo de estoque e programação pra comparação
			_cGrpEst  := aCnt[_nX][14]
			_cProgCli := aCnt[_nX][3]

			// posiciona na programacao do cliente
			dbSelectArea("SZ1")
			SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
			SZ1->(dbSeek( xFilial("SZ1")+_cProgCli ))

			// atualiza contrato do cliente
			_cNrContra := SZ1->Z1_CONTRT

			// 0001 - PNEU AROS 13 E 14     &     0003 - TBR     &     0011 - LTR   
			If ( _cGrpEst $ "0001/0003/0011" )

				// posiciona no cadastro de atividades
				dbSelectArea( "SZT" )
				SZT->( dbSetOrder( 1 ) ) // ZT_FILIAL, ZT_CODIGO, R_E_C_N_O_, D_E_L_E_T_
				SZT->( dbSeek( xFilial( "SZT" ) + "080" ) )

				// define o código da atividade
				_cCodAtiv := SZT->ZT_CODIGO
				_cUnidCob := SZT->ZT_UM

				// pesquisa se a atividade esta no contrato
				dbSelectArea("SZ9")
				SZ9->(dbSetOrder(2)) // 2-Z9_FILIAL, Z9_CODATIV, Z9_CONTRAT, Z9_ITEM
				If SZ9->(dbSeek( xFilial("SZ9")+ SZT->ZT_CODIGO + _cNrContra ))
					_cUnidCob := SZ9->Z9_UNIDCOB
				EndIf

				// 0002 - PNEU AROS 15 EM DIANTE & 0004 - PNEU TOYOTA & grupo 0009
			ElseIf ( _cGrpEst $ "0002/0004/0009" )
				// posiciona no cadastro de atividades
				dbSelectArea( "SZT" )
				SZT->( dbSetOrder( 1 ) ) // ZT_FILIAL, ZT_CODIGO, R_E_C_N_O_, D_E_L_E_T_
				SZT->( dbSeek( xFilial( "SZT" ) + "133" ) )

				// define o código da atividade
				_cCodAtiv := SZT->ZT_CODIGO
				_cUnidCob := SZT->ZT_UM

				// pesquisa se a atividade esta no contrato
				dbSelectArea("SZ9")
				SZ9->(dbSetOrder(2)) // 2-Z9_FILIAL, Z9_CODATIV, Z9_CONTRAT, Z9_ITEM
				If SZ9->(dbSeek( xFilial("SZ9")+ SZT->ZT_CODIGO + _cNrContra ))
					_cUnidCob := SZ9->Z9_UNIDCOB
				EndIf

				// 0100	- MATERIA PRIMA
			ElseIf ( _cGrpEst == "0100" )
				// posiciona no cadastro de atividades
				dbSelectArea( "SZT" )
				SZT->( dbSetOrder( 1 ) ) // ZT_FILIAL, ZT_CODIGO, R_E_C_N_O_, D_E_L_E_T_
				SZT->( dbSeek( xFilial( "SZT" ) + "128" ) )

				// define o código da atividade
				_cCodAtiv := SZT->ZT_CODIGO
				_cUnidCob := SZT->ZT_UM

				// pesquisa se a atividade esta no contrato
				dbSelectArea("SZ9")
				SZ9->(dbSetOrder(2)) // 2-Z9_FILIAL, Z9_CODATIV, Z9_CONTRAT, Z9_ITEM
				If SZ9->(dbSeek( xFilial("SZ9")+ SZT->ZT_CODIGO + _cNrContra ))
					_cUnidCob := SZ9->Z9_UNIDCOB
				EndIf

			EndIf

			// se a atividade for informada, grava os registros
			If ( ! Empty( _cCodAtiv ) )
				// adiciona a atividade no array padrão da rotina
				aAdd( _aAtivSumi, { _cCodAtiv, '', '', StrZero( _nX, 2 ), "S", "P", SZT->ZT_QTDPADR, _cProgCli, _cUnidCob } )
			EndIf

			// limpa a variável
			_cCodAtiv := ""
		Next _nX

		// caso encontre as atividades pelo grupo de estoque, informa o usuário
		If ( len( _aAtivSumi ) > 0 )
			// alimento o array com as atividades informadas
			aAtv := _aAtivSumi
		EndIf

	EndIf

	// se não encontrou nada automaticamente, continua com o processo normal
	If ( len( aAtv ) == 0 ) .and. ( _lAtvGrpEst )
		MsgStop("Ordem de Servico não pode ser gerada pois nenhuma atividade foi selecionada !!")
		Return(.f.)
	EndIf

	// se não encontrou nada automaticamente, continua com o processo normal
	If ( len( aAtv ) == 0 ) .and. ( ! _lAtvGrpEst )
		// - Atividade Selecionada
		aAtv:={}
		If Select(ATI) > 0
			(ATI)->(dbGotop())
			While !(ATI)->(EOF())
				// verifica se a atividade esta selecionada
				If ((ATI)->ATI_OK == _cMarca)
					// posiciona no cadastro de atividades
					dbSelectArea("SZT")
					SZT->(dbSetORder(1)) //1-ZT_FILIAL, ZT_CODIGO
					SZT->(dbSeek( xFilial("SZT")+(ATI)->ATI_COD ))

					// controle de atividade para carregamento
					If (_cTpMov == "S").and.(Posicione("SZT",1,xFilial("SZT")+(ATI)->ATI_COD,"ZT_TIPO") $ "CT|CF")
						_nQtdCarreg ++
					EndIf

					// adiciona a atividade
					Aadd(aAtv,{(ATI)->ATI_COD, '', '', (ATI)->ATI_ORDEM, "S", "P", SZT->ZT_QTDPADR, Nil, (ATI)->ATI_UM})

				EndIf
				// proxima atividade
				(ATI)->(dbSkip())
			EndDo
			// volta ao topo
			(ATI)->(dbGotop())
		EndIf
	EndIf

	// valida as atividades selecionadas
	If Len(aAtv) == 0
		MsgStop("Ordem de Servico não pode ser gerada pois nenhuma atividade foi selecionada !!")
		Return(.f.)
	EndIf

	// valida a quantidade de carregamento
	If (_cTpMov == "S").and.(_nQtdCarreg > 1)
		MsgStop("Não pode haver mais de um tipo de carregamento na mesma Ordem de Serviço !!")
		Return(.f.)
	EndIf

	// gera ordem de servico
	U_WMSA002I(aCnt, aAtv, _lEmMassa, ( ! _lEmMassa ))

	// fecha tela
	oDlgOrdemServ:End()

Return ( .T. )

//Geração da ordem de serviço
User Function WMSA002I(aCnt, aAtv, mvEmMassa, mvImprime)
	// numero da ordem de servico
	local _cNumOrdSrv := ""
	local _cNrOrdSrv := ""
	local _cSqOrdSrv := ""

	// para impressao
	local _cOrdSrvDe  := ""
	local _cOrdSrvAte := ""

	local j := 0
	local i := 0

	// valida o tipo de carregamento
	local _lVldTpCar := .f.
	local _cAtivCar := ""

	// obbservacoes
	local _cTmpObserv := ""

	// controle de necessidade de fotos
	local _lFoto := .f.

	// controle se deve gerar nova numeracao de OS
	local _lNewOrdSrv := .t.

	// controle de numeracao por container
	local _cTmpNrCont := ""

	// INICIA TRANSACAO
	BEGIN Transaction

		// varre todos os containeres/programacoes
		For i := 1 To len(aCnt)

			// armazena numero do container
			If (_cTmpNrCont != aCnt[i,1])
				// guarda numero de container
				_cTmpNrCont := aCnt[i,1]
				// controle para gerar nova ordem de servico
				_lNewOrdSrv := .T.
			EndIf

			// gera novo numero da ordem de servico
			If (_lNewOrdSrv)
				// numero da ordem de servico
				_cNrOrdSrv := GetSxeNum("SZ6", "Z6_NROS")
				// confirma numeracao
				ConfirmSX8()
				// sequencia da orde de servico
				_cSqOrdSrv := StrZero(1, TamSx3("Z6_SEQOS")[1])

				// controle para nao gerar nova ordem de servico
				_lNewOrdSrv := .F.
			EndIf

			// numero da ordem de servico completa
			_cNumOrdSrv := _cNrOrdSrv + _cSqOrdSrv

			// defime primera ordem de servico
			If (Empty(_cOrdSrvDe))
				_cOrdSrvDe := _cNumOrdSrv
			EndIf

			// define ultima ordem de servico
			If (_cOrdSrvAte < _cNumOrdSrv)
				_cOrdSrvAte := _cNumOrdSrv
			EndIf

			// define campo observacao
			_cTmpObserv := aCnt[i,13]

			// posiciona no pedido de venda
			If (aCnt[i,2] == "S")
				dbSelectArea("SC5")
				SC5->(dbSetOrder(1)) // 1-C5_FILIAL, C5_NUM
				SC5->(dbSeek( xFilial("SC5") + aCnt[i,10] ))
			EndIf

			// mensagens especificas para o cliente portobello
			If (aCnt[i,2] == "S") .AND. (aCnt[i,5] == "000467")   // para ENTRADA (RECEBIMENTO)

				// atividade 141-SEPARACAO FRACIONADA - EXPEDICAO
				If (aScan(aAtv,{|x| AllTrim(x[1]) == "141"}) > 0)
					// define complemento na observacao
					_cTmpObserv += IIf(Empty(_cTmpObserv),"",CRLF)+"INFORMAR MATERIAL UTILIZADO PARA FORMAÇÃO DOS PALLETS CASO NECESSÁRIO"+CRLF+"PERCURSO: "+AllTrim(SC5->C5_ZAGRUPA)+CRLF+"PV: "+SC5->C5_NUM
				EndIf

				// atividade 010-CARREGAMENTO MECANIZADO / FRACIONADO
				If (aScan(aAtv,{|x| AllTrim(x[1]) == "010"}) > 0)
					// define complemento na observacao
					_cTmpObserv += IIf(Empty(_cTmpObserv),"",CRLF)+"FOTOS DO MATERIAL NO STAGE / CAMINHÃO / ETIQUETAS"+CRLF+"PERCURSO: "+AllTrim(SC5->C5_ZAGRUPA)+CRLF+"PV: "+SC5->C5_NUM
				EndIf
				
			Elseif (aCnt[i,2] == "E") .AND. (aCnt[i,5] == "000467")  // para SAÍDA (EXPEDIÇÃO)

				// atividade 011-DESCARGA  MECANIZADA / FRACIONADA                 
				If (aScan(aAtv,{|x| AllTrim(x[1]) == "011"}) > 0)
					// define complemento na observacao
					_cTmpObserv += IIf(Empty(_cTmpObserv),"",CRLF) + "PORTOBELLO EXPORTAÇÃO" + CRLF + "INFORMAR LOCAL DE ARMAZENAGEM RUA:________ BLOCO:________"
				EndIf
			
			EndIf

			// verifica a necessidade de foto
			_lFoto := sfRetFoto(aCnt[i], aAtv)

			Reclock("SZ6",.T.)
			SZ6->Z6_FILIAL	:= xFilial("SZ6")
			SZ6->Z6_NUMOS	:= _cNumOrdSrv
			SZ6->Z6_TIPOMOV	:= aCnt[i,2]
			SZ6->Z6_CLIENTE	:= aCnt[i,5]
			SZ6->Z6_LOJA	:= aCnt[i,6]
			SZ6->Z6_CODIGO	:= aCnt[i,3]
			SZ6->Z6_ITEM	:= aCnt[i,4]
			SZ6->Z6_CONTAIN	:= aCnt[i,1]
			SZ6->Z6_EMISSAO	:= aCnt[i,7]
			SZ6->Z6_STATUS	:= aCnt[i,8]
			SZ6->Z6_RIC		:= aCnt[i,9]
			SZ6->Z6_PEDIDO	:= aCnt[i,10]
			SZ6->Z6_DOCSERI	:= aCnt[i,11]
			SZ6->Z6_PLACA1	:= aCnt[i,12]
			SZ6->Z6_OBSERVA	:= _cTmpObserv
			SZ6->Z6_FOTO    := IIf(_lFoto, "P", "N")
			If aCnt[i,8] == "F"
				SZ6->Z6_DTFINAL := Date()
			EndIf
			// usuario de inclusao
			SZ6->Z6_USRINC	:= __cUserId
			SZ6->Z6_NROS    := _cNrOrdSrv
			SZ6->Z6_SEQOS   := _cSqOrdSrv
			MsUnlock()

			// valida tipo de carregamento?
			_lVldTpCar := U_FtWmsParam("OS_VLD_TIPO_CARREGAMENTO","L",.f.,.f.,"", SZ6->Z6_CLIENTE, SZ6->Z6_LOJA, nil, nil)

			//Grava Atividades
			For j := 1 To Len(aAtv)

				// caso a operação de validar esteja ativa
				If ( _lVldTpCar )
					// valida atividades de carregamento (total ou fracionado)
					If (aCnt[i,2]=="S").and.(Posicione("SZT",1,xFilial("SZT")+aAtv[j,1],"ZT_TIPO") $ "CT|CF")
						// valida se o pedido de venda eh carregamento total ou fracionado
						_cAtivCar := sfVldCarreg(aCnt[i,3],aCnt[i,4],aCnt[i,10],aAtv[j,1],SZ6->Z6_CLIENTE,SZ6->Z6_LOJA)
						aAtv[j,1] := Iif( Empty(_cAtivCar), aAtv[j,1], _cAtivCar)
					EndIf
				EndIf

				// grava os registros por programação
				If ( SZ6->Z6_CODIGO	== aAtv[j, 8] ) .Or. ( Empty( aAtv[j, 8] ) )
					Reclock("SZ7",.T.)
					SZ7->Z7_FILIAL	:= xFilial("SZ7")
					SZ7->Z7_NUMOS	:= _cNumOrdSrv
					SZ7->Z7_CODATIV	:= aAtv[j,1]
					SZ7->Z7_CONTRT	:= aAtv[j,2]
					SZ7->Z7_ITEM	:= aAtv[j,3]
					SZ7->Z7_ORDEM	:= aAtv[j,4]
					SZ7->Z7_FATURAR	:= aAtv[j,5]
					SZ7->Z7_TIPOPER	:= aAtv[j,6]
					SZ7->Z7_QUANT	:= aAtv[j,7]
					SZ7->Z7_SALDO	:= aAtv[j,7]
					SZ7->Z7_UNIDCOB	:= aAtv[j,9]
					MsUnlock()
				EndIf
			Next j

			// proxima sequencia
			_cSqOrdSrv := Soma1(_cSqOrdSrv)

		Next i
	End Transaction

	//pergunta se deseja imprimir a O.S. recem gerada
	If ( (!mvEmMassa) .AND. (mvImprime) )
		If ( MsgYesNo("Ordem de serviço gerada com sucesso. Deseja imprimir?") )
			//chama o relatorio passando o range de OS geradas
			U_TWMSR003(_cOrdSrvDe, _cOrdSrvAte)
		EndIf
	EndIf

Return( .T. )

Static Function sfEncerraFim()

	SetKey(VK_F8,{|| Nil})
	SetKey(VK_F9,{|| Nil})

Return(.t.)

Static Function sfEncerra()

	// zera teclas de atalho
	SetKey(VK_F6,{|| Nil})
	SetKey(VK_F7,{|| Nil})
	SetKey(VK_F8,{|| Nil})
	SetKey(VK_F9,{|| Nil})

	// Limpa arquivos temporarios
	If ValType(_cArquivo) == "O"
		_cArquivo:Delete()
	EndIf
	
	If ValType(_cArqCnt) == "O"
		_cArqCnt:Delete()
	EndIf
	

Return(.t.)

// ** funcao que valida os dados do cliente
Static Function sfVldCliente()
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1)) // 1-A1_FILIAL, A1_COD, A1_LOJA
	If (!SA1->(dbSeek( xFilial("SA1")+_cCodCli+If(Empty(_cLojCli),"",_cLojCli) )))
		MsgStop("Cliente não cadastrado!")
		Return(.f.)
	EndIf
	// nome de cliente
	_cNomCli := SA1->A1_NOME

	_bAtivid 	:= .F.

	//desabilita o botão cliente (não deixa trocar) na tela de programação da ordem de serviço
	oGetTpMov:Disable()

	If ( ! Empty(_cCodCli)).and.( ! Empty(_cLojCli))
		oGetCodCli:Disable()
		oGetLojCli:Disable()

		//habilita campo do pedido de venda
		oGetNumPed:Enable()

		//habilita botão para pedidos de venda DE/ATÉ (em massa)
		oBtnPedido:Enable()

	EndIf

Return( .T. )

Static Function sfAtivaBotao()

	// define teclas de atalho
	SetKey(VK_F6,{|| oBtnAtividade:Click() } )
	SetKey(VK_F8,{|| oBtnConfOS:Click() } )

	oBtnAtividade:Enable()
	oBtnConfOS:Enable()

Return(.t.)

// ** funcao que retorna as opcoes do campo X3_CBOX
Static Function sfCboxToArray(mvCampo)
	Local _aArea    := GetArea()
	Local _aAreaSX3 := SX3->(GetArea())
	Local _cBox     := ""
	Local _aBox     := {}
	Local _nPosicao1:= 0
	Local _nPosicao2:= 0
	Local _cElem    := ""

	dbSelectArea("SX3")
	dbSetOrder(2)
	If ( MsSeek(mvCampo) )
		_cBox := x3CBox()
		While ( !Empty(_cBox) )
			_nPosicao1 := At(";",_cBox)
			If ( _nPosicao1 == 0 )
				_nPosicao1 := Len(_cBox)+1
			EndIf
			//_nPosicao2	:= At("=",_cBox)
			_cElem		:= SubStr(_cBox,1,_nPosicao1-1)
			aadd(_aBox,_cElem)
			_cBox := SubStr(_cBox,_nPosicao1+1)
		EndDo
	EndIf
	// restaura area inicial
	RestArea(_aAreaSX3)
	RestArea(_aArea)

Return(_aBox)

// ** funcao para mudar o tipo de movimento
Static Function sfModOperac()

	_cNumProg	:= CriaVar("Z6_CODIGO",.f.)
	_cIteProg	:= CriaVar("Z6_ITEM",.f.)
	_cNumPed	:= CriaVar("C5_NUM",.f.)
	_cNumPe2	:= CriaVar("C5_NUM",.f.)
	_cDoc		:= CriaVar("F1_DOC",.f.)
	_cSerie		:= CriaVar("F1_SERIE",.f.)
	_bAtivid 	:= .F.

	//saida
	If _cTpMov == "S"
		oSayNumPed:Show()
		oGetNumPed:Show()
		oBtnPedido:Show()
		oSayPlaca1:Show()
		oGetPlaca1:Show()
		oSayProgram:Hide()
		oGetNumProg:Hide()
		oGetIteProg:Hide()
		oSayDocSerie:Hide()
		oGetDoc:Hide()
		oGetSerie:Hide()
	EndIf

	//entrada
	If _cTpMov == "E"
		oSayNumPed:Hide()
		oGetNumPed:Hide()
		oGetNumPe2:Hide()
		oSayPlaca1:Hide()
		oGetPlaca1:Hide()
		oSayProgram:Show()
		oGetNumProg:Show()
		oGetIteProg:Show()
		oSayDocSerie:Hide()
		oGetDoc:Hide()
		oGetSerie:Hide()
	EndIf

	//interno
	If _cTpMov == "I"
		oSayNumPed:Hide()
		oGetNumPed:Hide()
		oGetNumPe2:Hide()
		oSayPlaca1:Hide()
		oGetPlaca1:Hide()
		oSayProgram:Hide()
		oGetNumProg:Hide()
		oGetIteProg:Hide()
		oSayDocSerie:Show()
		oGetDoc:Show()
		oGetSerie:Show()
	EndIf
	oGetTpMov:Disable()

Return

// ** funcao que valida o numero da programacao informada
Static Function sfVldNumProg()

	local _lRet := .T.

	// valida se a programacao esta encerrada
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	If ! SZ1->(dbSeek( xFilial("SZ1")+_cNumProg ))
		MsgStop("Programação de Recebimentos não encontrada!")
		_lRet := .F.
	Else
		If ( ! Empty(SZ1->Z1_DTFINFA))
			MsgStop("Programação encontra-se encerrada. Contate o setor de Faturamento.")
			_lRet := .F.
		EndIf
	EndIf

	// itens da programacao
	dbSelectArea("SZ2")
	SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM
	If (!SZ2->(dbSeek( xFilial("SZ2")+_cNumProg+If(Empty(_cIteProg),"",_cIteProg) )))
		MsgStop("Programação de Recebimentos não encontrada!")
		_lRet := .F.
	EndIf

	If (_lRet)
		oGetNumProg:Disable()
		oGetIteProg:Disable()
		oBrwCntr:oBrowse:Enable()
		sfCarregaCnt()
		If (_cTpMov <> "S") .And. ((CNT)->(RecCount()) == 0)
			MsgStop("Ordem de Serviço não pode ser gerada pois não existem containers para esta programação !")
			oDlgOrdemServ:End()
		EndIf
		sfAtivaBotao()
	Else
		_cNumProg	:= CriaVar("Z6_CODIGO",.f.)
		_cIteProg	:= CriaVar("Z6_ITEM",.f.)
	EndIf

Return(_lRet)

// ** funcao que valida o numero do documento de entrada
Static Function sfVldDocSerie()

	bRet:=.T.
	// itens da programacao
	dbSelectArea("SF1")
	SF1->(dbSetOrder(1))
	If (!SF1->(dbSeek( xFilial("SF1")+_cDoc+_cSerie )))
		MsgStop("Documento de entrada não encontrado!")
		bRet:=.F.
	EndIf

	If bRet
		oGetDoc:Disable()
		oGetSerie:Disable()
		sfAtivaBotao()
	Else
		_cDoc	:= CriaVar("F1_DOC",.f.)
		_cSerie	:= CriaVar("F1_SERIE",.f.)
	EndIf

Return(bRet)

// ** funcao que carrega os containers
Static Function sfCarregaCnt()

	local nX := 0

	_cQuery := "SELECT Z3_CONTAIN, CASE WHEN Z3_CONTEUD = 'C' THEN 'Cheio' ELSE 'Vazio' END Z3_CONTEUD, Z3_TAMCONT, Z3_TIPCONT, Z3_RIC "
	_cQuery += "FROM "+RetSqlName("SZ3")+" SZ3  (nolock) "
	_cQuery += "WHERE Z3_FILIAL = '"+xFilial("SZ3")+"' "
	_cQuery += "AND Z3_PROGRAM = '"+_cNumProg+"' AND Z3_ITEPROG = '"+_cIteProg+"' AND Z3_DTSAIDA = '' AND Z3_TPMOVIM = 'E' "
	_cQuery += "AND SZ3.D_E_L_E_T_ = ' ' "
	_cQuery += "ORDER BY Z3_CONTAIN"
	// alimenta o acols com o resultado do SQL
	_aColsProg := U_SqlToVet(_cQuery)

	For nX := 1 To Len(_aColsProg)
		(CNT)->(RecLock(CNT,.T.))
		(CNT)->CNT_OK := ""
		(CNT)->CNT_COD := AllTrim(_aColsProg[nX][01])
		(CNT)->CNT_CONTEU := AllTrim(_aColsProg[nX][02])
		(CNT)->CNT_TAMCON := AllTrim(_aColsProg[nX][03])
		(CNT)->CNT_TIPCON := Posicione("SX5",1, xFilial("SX5")+"ZA"+_aColsProg[nX][04],"X5_DESCRI")
		(CNT)->CNT_RIC := AllTrim(_aColsProg[nX][05])
		(CNT)->(MsUnLock())
	Next nX

	(CNT)->(dbGotop())
	oBrwCntr:oBrowse:Refresh()


Return(.t.)

// ** funcao que valida o numero do pedido de venda informado
Static Function sfVldNumPed(mvNumPed, mvAlerta)

	//por padrão, não é rotina automatica (então exibe alertas e interação com usuário)
	Default mvAlerta := .T.

	// itens da programacao
	dbSelectArea("SC5")
	SC5->(dbSetOrder(1))

	//valida número do pedido conforme campo digitado
	If (!SC5->(dbSeek( xFilial("SC5") + mvNumPed )))
		If ( mvAlerta )
			Aviso("TWMSA002 -> sfVldNumPed","Pedido de Venda " + mvNumPed + " não encontrado!",{"Fechar"})
		EndIf
		Return( .F. )
	EndIf

	// verifica se o pedido eh do cliente
	If (SC5->C5_CLIENTE != _cCodCli) .OR. (SC5->C5_LOJACLI != _cLojCli)
		If ( mvAlerta )
			Aviso("TWMSA002 -> sfVldNumPed","Pedido de Venda " + mvNumPed + " não pertence ao cliente informado!",{"Fechar"})
		EndIf
		Return( .F. )
	EndIf

	// verifica o tipo do pedido
	If (SC5->C5_TIPOOPE != "P")
		If ( mvAlerta )
			Aviso("TWMSA002 -> sfVldNumPed","Não é permitido o uso deste tipo de pedido de venda!",{"Fechar"})
		EndIf
		Return( .F. )
	EndIf

	// verifica se pedido de venda ja foi liberado
	If (SC5->C5_LIBEROK != "S")
		If ( mvAlerta )
			Aviso("TWMSA002 -> sfVldNumPed","Pedido de Venda " + mvNumPed + " não liberado!",{"Fechar"})
		EndIf
		Return( .F. )
	EndIf

	// soh permite para pedidos faturados ateh 15 dias antes
	If ( ! Empty(SC5->C5_NOTA)) .AND. (Posicione("SF2",1, xFilial("SF2") + SC5->(C5_NOTA+C5_SERIE+C5_CLIENTE+C5_LOJACLI) ,"F2_EMISSAO") < (_dDtApont - 15)) // 1 - F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_FORMUL, F2_TIPO
		If ( mvAlerta )
			Aviso("TWMSA002 -> sfVldNumPed","Pedido de Venda " + mvNumPed + " já foi faturado/devolvido a mais de 15 dias! Entre em contato com faturamento.",{"Fechar"})
		EndIf
		Return( .F. )
	EndIf

Return( .T. )

// ** função que habilita o usuário a selecionar vários pedidos de venda para gerar a programação
Static Function sfPedidos()
	// esconde o botao
	oBtnPedido:Hide()

	//mostra o campo para pedido ATÉ
	oGetNumPe2:Show()
	oGetNumPe2:Enable()


	//troca a descrição do campo
	oSayNumPed:SetText("Pedidos de venda (de/até)")
	oSayNumPed:CtrlRefresh()

	//volta o foco para o campo pedido até
	oGetNumPe2:SetFocus()

Return(.T.)


// ** funcao que apresenta atividades a serem realizadas pelas ordens de servico
Static Function sfAtividades()
	// campo para filtro do tipo da atividade
	local _cCmpTpAtiv := ""
	local _oBtnAtvSair

	Local _cQuery
	Local _aStruTrb := {}
	Local _aBrowse := {}
	Private _cCodAtv := CriaVar("ZT_CODIGO",.f.)
	Private _cNomAtv :=  CriaVar("ZT_DESCRIC",.f.)
	Private _aCodAtv := {}
	Private cCount	 := "01"
	Private _oCheck1, _lCheck := .F.
	Private _oBrwProgRec

	SetKey(VK_F4,{|| oBtnDefOrdemE:Click() } )
	SetKey(VK_F5,{|| oBtnZerarOrdem:Click() } )


	aadd(_aCodAtv,"Codigo")
	aadd(_aCodAtv,"Descricao")
	aadd(_aCodAtv,"Selecionados")
	aadd(_aCodAtv,"Ordem Execução")

	aadd(_aStruTrb,{"ATI_OK","C",2,0})
	aadd(_aStruTrb,{"ATI_COD","C",3,0})
	aadd(_aStruTrb,{"ATI_DESC","C",50,0})
	aadd(_aStruTrb,{"ATI_UM","C",2,0})
	aadd(_aStruTrb,{"ATI_ORDEM","C",2,0})
	aadd(_aStruTrb,{"ATI_NO","C",2,0})

	aadd(_aBrowse,{"ATI_OK",,""})
	aadd(_aBrowse,{"ATI_COD",,"Codigo"})
	aadd(_aBrowse,{"ATI_DESC",,"Descrição"})
	aadd(_aBrowse,{"ATI_UM",,"UM"})
	aadd(_aBrowse,{"ATI_ORDEM",,"Ordem"})

	If !_bAtivid

		// define o campo para filtro do tipo da atividade
		Do Case
			Case (_cTpMov == "E")
			_cCmpTpAtiv := "SZT->ZT_ENTRADA"
			Case (_cTpMov == "S")
			_cCmpTpAtiv := "SZT->ZT_SAIDA"
			Case (_cTpMov == "I")
			_cCmpTpAtiv := "SZT->ZT_INTERNA"
		EndCase

		If (Select(ATI)<>0)
			dbSelectArea(ATI)
			dbCloseArea()
		EndIf
		
		_cArquivo := FWTemporaryTable():New( ATI )
		_cArquivo:SetFields( _aStruTrb )
		_cArquivo:AddIndex("01", {"ATI_COD"} )
		_cArquivo:Create()

		sfGrvProg()

		dbSelectArea("SZ1")
		dbSetOrder(1)
		dbSeek(xFilial("SZ1")+_cNumProg+_cIteProg)
		cContTmp := SZ1->Z1_CONTRT

		//Atividades que nao estao no contrato
		dbSelectArea("SZT")
		dbSetOrder(1)
		dbGotop()
		While ! SZT->(EOF())

			// filtra atividades bloqueadas
			If (SZT->ZT_MSBLQL == "1")
				// proxima atividade
				SZT->(dbSkip())
				Loop
			EndIf

			// filtra pelo tipo de atividade
			If (&(_cCmpTpAtiv) == "1")

				// pesquisa se a atividade esta no contrato
				dbSelectArea("SZ9")
				SZ9->(dbSetOrder(2)) // 2-Z9_FILIAL, Z9_CODATIV, Z9_CONTRAT, Z9_ITEM

				If SZ9->(dbSeek( xFilial("SZ9")+ SZT->ZT_CODIGO + cContTmp ))

					dbSelectArea(ATI)
					RecLock(ATI,.T.)
					(ATI)->ATI_OK   := ""
					(ATI)->ATI_COD  := AllTrim(SZT->ZT_CODIGO)
					(ATI)->ATI_DESC := AllTrim(SZT->ZT_DESCRIC)
					(ATI)->ATI_UM   := AllTrim(SZ9->Z9_UNIDCOB)
					(ATI)->(MsUnLock())

				EndIf

			EndIf

			// proxima atividade
			SZT->(dbSkip())
		EndDo

	EndIf

	//_cArquivo:AddIndex("01", {"ATI_COD"} )
	(ATI)->(dbSetOrder(1))
	(ATI)->(dbGotop())

	_bAtivid:=.T.

	// monta o dialogo
	oDlgProgRec := MSDialog():New(000,000,400,700,"Programação de Atividades",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho
	oPnlCabec := TPanel():New(000,000,nil,oDlgProgRec,,.F.,.F.,,,000,040,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// Comentado esta parte de ordenação, pois gera erro log ao tentar criar undices adicionais para a tabela temporária...
	// precisa repensar esta funcionalidade em um segundo momento
	/*oSayAtivid := TSay():New(010,008,{||"Ordem"},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
	oGetCodAtv :=  TComboBox():New(008,042,{|u| If(PCount()>0,_cCodAtv:=u,_cCodAtv)},_aCodAtv,050,011,oPnlCabec,,,,,,.T.,oFntVerd15,"",,,,,,,_cCodAtv)
	oGetCodAtv:bChange:={|| sfModAtv() }*/

	// botao para detahes do dia
	oBtnConfirmar  := TButton():New(006,100,"Confirmar",    oPnlCabec,{|| sfVldConf( oDlgProgRec ) },045,013,,,,.T.,,"",,,,.F. )
	oBtnDefOrdemE  := TButton():New(006,150,"Ord.Exec.(F4)",oPnlCabec,{|| sfDefOrdem() },045,013,,,,.T.,,"",,,,.F. )
	oBtnZerarOrdem := TButton():New(006,200,"Zerar (F5)",   oPnlCabec,{|| sfZerar() },045,013,,,,.T.,,"",,,,.F. )
	oBtnAtvVisual  := TButton():New(006,250,"Visualizar",   oPnlCabec,{|| sfAtvVisual((ATI)->ATI_COD) },045,013,,,,.T.,,"",,,,.F. )
	_oBtnAtvSair   := TButton():New(006,300,"Cancelar",     oPnlCabec,{|| sfCancAtiv( oDlgProgRec ) },045,013,,,,.T.,,"",,,,.F. )

	// browse com a listagem dos produtos conferidos
	_oBrwProgRec := MsSelect():New (ATI,"ATI_OK",Nil, _aBrowse, .F., _cMarca, {000,000,400,300})
	_oBrwProgRec:oBrowse:lHasMark 	:= .T.
	_oBrwProgRec:oBrowse:lCanAllMark	:=.T.
	_oBrwProgRec:oBrowse:bAllMark 	:= 	{|| MarkAll ("ATI", _cMarca, @oDlgProgRec)}
	_oBrwProgRec:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// específico sumitomo para OS de saída
	If ( _cCodCli == "000316" ) .and. ( _cTpMov == "S" )
		_oCheck1 := TCheckBox():New(025,008,'Carregar Atividades Conforme Grupo de Estoque', { |u| Iif( PCount() > 0, _lAtvGrpEst := u , _lAtvGrpEst ) },oPnlCabec,400,400,,,,,,,,.T.,,,)
	EndIf

	// ativa a tela
	ACTIVATE MSDIALOG oDlgProgRec CENTERED

	SetKey(VK_F4,{|| Nil})
	SetKey(VK_F5,{|| Nil})


Return(.t.)

Static Function sfZerar()

	cCount:="01"
	dbSelectArea(ATI)
	dbGotop()
	While (ATI)->(!EOF())
		RecLock(ATI,.F.)
		(ATI)->ATI_ORDEM:=""
		MsUnlock()
		(ATI)->(dbSkip())
	EndDo
	dbGotop()

Return (.t.)

Static Function sfDefOrdem()

	If (ATI)->ATI_OK == _cMarca
		RecLock(ATI,.F.)
		(ATI)->ATI_ORDEM:=cCount
		MsUnlock()
		cCount:=Soma1(cCount)
	EndIf

Return (.t.)

// **Funcao que marca todos os itens quando clicar no header da coluna
Static Function MarkAll (cAlias, cMarca, oDlg)
	Local	_cAlias	:= &(cAlias)
	Local 	nReg	:=	(_cAlias)->(RecNo ())

	_cField:=(_cAlias)+"->"+cAlias+"_OK"

	(_cAlias)->(DbGoTop ())
	While (_cAlias)->( ! Eof() )
		(_cAlias)->(RecLock(_cAlias,.F.))
			&(_cField) := Iif (Empty(&(_cField)), cMarca, " ")
		(_cAlias)->(MsUnLock())
		(_cAlias)->(dbSkip())
	EndDo
	
	//DbEval ({|| (RecLock (_cAlias, .F.), _cField := Iif (Empty (_cField), cMarca, " "), MsUnLock ())})
	(_cAlias)->(DbGoto (nReg))
	oDlg:Refresh ()
Return (.T.)

Static Function sfModAtv()

	_cIdx:={}
	Do Case
		Case _cCodAtv == "Codigo"
		_cIdx:={"ATI_COD"}
		Case _cCodAtv == "Descricao"
		_cIdx:={"ATI_DESC","ATI_COD"}
		Case _cCodAtv == "Selecionados"
		(ATI)->(dbGotop())
		While !(ATI)->(EOF())
			_cX:=""
			If Empty((ATI)->ATI_OK)
				_cX:=_cMarca
			EndIf
			Reclock(ATI,.F.)
			(ATI)->ATI_NO:=_cX
			MsUnlock()
			(ATI)->(dbSkip())
		EndDo
		_cIdx:={"ATI_NO","ATI_COD"}
		Case _cCodAtv == "Ordem Execução"
		_cIdx:={"ATI_ORDEM","ATI_COD"}

	EndCase
	
	_cArquivo:AddIndex("01", _cIdx )
	(ATI)->(dbSetOrder(1))
	(ATI)->(dbGotop())

	_oBrwProgRec:oBrowse:Refresh()

Return(.t.)

// ** funcao que altera item da atividade para faturar sim ou nao
Static Function sfIncluir()

	If !Empty(_cCodAtv)
		dbSelectArea(ATI)
		dbSetOrder(1)
		If dbSeek(_cCodAtv)
			MsgStop("Atividade já cadastrada!")
			_cCodAtv := CriaVar("ZT_CODIGO",.f.)
			_cNomAtv :=  CriaVar("ZT_DESCRIC",.f.)
			Return(.f.)
		EndIf
		RecLock(ATI,.T.)
		(ATI)->ATI_OK := _cMarca
		(ATI)->ATI_COD := AllTrim(_cCodAtv)
		(ATI)->ATI_DESC := AllTrim(_cNomAtv)
		(ATI)->ATI_FATURA:="Sim"
		MsUnlock()
		_cCodAtv := CriaVar("ZT_CODIGO",.f.)
		_cNomAtv :=  CriaVar("ZT_DESCRIC",.f.)
		dbSelectArea(ATI)
		dbSetOrder(1)
		(ATI)->(dbGotop())
	EndIf

Return(.t.)


// ** funcao que valida os dados da atividade
Static Function sfVldAtividade()
	dbSelectArea("SZT")
	SZT->(dbSetOrder(1))
	If (!SZT->(dbSeek( xFilial("SZT")+_cCodAtv )))
		MsgStop("Atividade não cadastrado!")
		Return(.f.)
	EndIf
	// nome de cliente
	_cNomAtv := SZT->ZT_DESCRIC
	oBtnIncluir:SetFocus()
Return(.t.)

// ** funcao que monta uma tela com a relacao da programacao de recebimentos do cliente (chamada pela consulta padrao SZ2MOS)
User Function WMSA002O()
	Local _cQuery
	Local _aHeadProg := {}
	Local _aColsProg := {}
	// controle de confirmacao
	Local _lRet := .f.

	// alimenta o header
	aAdd(_aHeadProg,{"Código", "Z1_CODIGO", PesqPict("SZ1","Z1_CODIGO"), TamSx3("Z1_CODIGO")[2], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadProg,{"Item", "Z2_ITEM", PesqPict("SZ2","Z2_ITEM"), TamSx3("Z2_ITEM")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadProg,{"Documento", "Z2_DOCUMEN", PesqPict("SZ2","Z2_DOCUMEN"), TamSx3("Z2_DOCUMEN")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadProg,{"Tam.Container", "Z2_TAMCONT", PesqPict("SZ2","Z2_TAMCONT"), TamSx3("Z2_TAMCONT")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadProg,{"Tipo Container", "Z2_TIPCONT", PesqPict("SZ2","Z2_TIPCONT"), TamSx3("Z2_TIPCONT")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadProg,{"Conteúdo?", "Z2_CONTEUD", PesqPict("SZ2","Z2_CONTEUD"), TamSx3("Z2_CONTEUD")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadProg,{"Quantidade", "Z2_QUANT", PesqPict("SZ2","Z2_QUANT"), TamSx3("Z2_QUANT")[1], TamSx3("Z2_QUANT")[2],Nil,Nil,"N",Nil,"R" })
	aAdd(_aHeadProg,{"Qtd.Recebida", "Z2_QTDREC", PesqPict("SZ2","Z2_QTDREC"), TamSx3("Z2_QTDREC")[1], TamSx3("Z2_QTDREC")[2],Nil,Nil,"N",Nil,"R" })

	_cQuery := "SELECT Z1_CODIGO, Z2_ITEM, Z2_DOCUMEN, Z2_TAMCONT, Z2_TIPCONT, Z2_CONTEUD, Z2_QUANT, Z2_QTDREC, '.F.' IT_DEL "
	// programacao de recebimento
	_cQuery += "FROM "+RetSqlName("SZ1")+" SZ1 (nolock)  "
	// itens da programacao
	_cQuery += "INNER JOIN "+RetSqlName("SZ2")+" SZ2 (nolock)  ON "+RetSqlCond("SZ2")+" AND Z2_CODIGO = Z1_CODIGO "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SZ1")+" "
	// saldo
	_cQuery += "AND Z2_QTDREC > 0 "
	// cliente e loja
	_cQuery += "AND Z1_CLIENTE = '"+_cCodCli+"' AND Z1_LOJA = '"+_cLojCli+"' "
	// somente em aberto
	_cQuery += "AND Z1_DTFINFA = ' ' "
	// ordem dos dados
	_cQuery += "ORDER BY Z2_CODIGO, Z2_ITEM"
	// alimenta o acols com o resultado do SQL
	_aColsProg := U_SqlToVet(_cQuery)

	// verifica se há historicos para visualizar
	If (Len(_aColsProg)==0)
		MsgStop("Não há programações de recebimentos!")
		Return(.f.)
	EndIf

	// monta o dialogo
	oDlgProgRec := MSDialog():New(000,000,400,800,"Programação de Recebimentos",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho
	oPnlCabec := TPanel():New(000,000,nil,oDlgProgRec,,.F.,.F.,,,000,020,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// botao para detahes do dia
	oBtnConfirma := TButton():New(005,005,"Confirmar",oPnlCabec,{|| _lRet:=.t.,oDlgProgRec:End() },060,010,,,,.T.,,"",,,,.F. )
	// botao pra fechar
	oBtnSair := TButton():New(005,070,"Fechar",oPnlCabec,{||oDlgProgRec:End()},060,010,,,,.T.,,"",,,,.F. )

	// browse com a listagem dos produtos conferidos
	oBrwProgRec := MsNewGetDados():New(000,000,400,400,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsProg),'AllwaysTrue()','','AllwaysTrue()',oDlgProgRec,_aHeadProg,_aColsProg)
	oBrwProgRec:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oBrwProgRec:oBrowse:blDblClick := {|| oBtnConfirma:Click() }

	// ativa a tela
	ACTIVATE MSDIALOG oDlgProgRec CENTERED

	If (_lRet)
		dbSelectArea("SZ2")
		SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM
		SZ2->(dbSeek( xFilial("SZ2")+ oBrwProgRec:aCols[oBrwProgRec:nAt,1] + oBrwProgRec:aCols[oBrwProgRec:nAt,2] ))
	EndIf

Return(_lRet)

// ** funcao que retorna a lista dos recursos humanos, conforme funcao passada como parametro
Static Function sfRetRecHum(mvFinaliza, mvNumOS, mvFuncao)
	// variavel de retorno
	local _vRet := {}
	// variaveis temporarias
	local _cQuery

	// monta a query para buscas os Rec Humanos Cadastrados
	_cQuery := "SELECT "+IIf(!mvFinaliza,"","'[ ] '+")+"DCD_CODFUN + '-' + UPPER(DCD_NOMFUN) +'"+Space(20)+"'+ DCI_FUNCAO IT_RETORNO "
	// Cad. Rec. Humanos
	_cQuery += "FROM "+RetSqlName("DCD")+" DCD (nolock)  "
	// funcoes dos recursos humanos
	_cQuery += "INNER JOIN "+RetSqlName("DCI")+" DCI (nolock)  ON "+RetSqlCond("DCI")+" AND DCI_CODFUN = DCD_CODFUN "

	// se nao for finalizacao de OS, faz amarracao com o apontamento da OS
	If (!mvFinaliza)
		_cQuery += "INNER JOIN "+RetSqlName("SZ8")+" SZ8 (nolock)  ON "+RetSqlCond("SZ8")+" AND Z8_NUMOS = '"+mvNumOS+"' "
		_cQuery += "      AND Z8_RECHUM = DCI_CODFUN AND Z8_FUNCAO IN "+FormatIn(mvFuncao,";")+" "
	EndIf

	// filtro por funcao
	_cQuery += "AND DCI_FUNCAO IN "+FormatIn(mvFuncao,";")+" "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("DCD")+" "
	// filtra bloqueados
	_cQuery += If(mvFinaliza,"AND DCD_MSBLQL <> '1' ","")
	// ordem dos dados
	_cQuery += "ORDER BY DCD_NOMFUN "
	// retorno para vetor
	_vRet := U_SqlToVet(_cQuery)

	memowrit("C:\query\twmsa002_sfRetRecHum.txt",_cQuery)

	// informacoes anteriores (campos Z6_OPERADO e Z6_CONFERE)
	If (!mvFinaliza).and.(Len(_vRet)==0)
		// se for funcao WMS02 - Conferente
		If ("WMS02" $ mvFuncao)
			_vRet := {SZ6->Z6_CONFERE}
			// operadores (WMS03 - OP. PALETEIRA / WMS04 - OP. EMPILHADEIRA)
		ElseIf (("WMS03" $ mvFuncao).or.("WMS04" $ mvFuncao))
			_vRet := {SZ6->Z6_OPERADO}
		EndIf
	EndIf

Return(_vRet)

// ** funcao para selecionar o item dentro do ListBox
Static Function sfSelItem(mvListBox)
	// retorna os itens do objeto
	local _aItens := mvListBox:aItems
	// retorna o conteudo da linha atual
	local _cLinhaAtu := _aItens[mvListBox:nAt]
	// opcao do item atual
	local _cOpcAtu := Left(_cLinhaAtu,3)
	// nova condicao
	local _cOpcNew := If(_cOpcAtu=="[ ]","[X]","[ ]")

	// altera opcao
	mvListBox:Modify(_cOpcNew + SubStr(_cLinhaAtu,4),mvListBox:nAt)

Return

// ** funcao que valida se o Rec Humano foi informado
Static Function sfVldRecHum(mvListBox,mvRecHuman)
	// variaveis temporarias
	local _nX, _cTmpCod, _cTmpFuncao
	// variavel de retorno
	local _lRet := .f.

	// varre toda a lista verificando se ha itens selecionados
	For _nX := 1 to Len(mvListBox:aItems)
		If (SubStr(mvListBox:aItems[_nX],2,1)=="X")
			// extrai o codigo do recurso
			_cTmpCod := SubStr(mvListBox:aItems[_nX],5,Len(DCD->DCD_CODFUN))
			// extrai a funcao
			_cTmpFuncao := Right(mvListBox:aItems[_nX],Len(DCI->DCI_FUNCAO))
			// adiciona o recurso humano
			If (aScan(mvRecHuman,{|x| AllTrim(x[1])==AllTrim(_cTmpCod)})==0)
				// adiciona as informacoes
				aAdd(mvRecHuman,{_cTmpCod,_cTmpFuncao})
				// retorno valido
				_lRet := .t.
			Else
				Aviso("TWMSA002 -> sfVldRecHum","O recurso humano "+_cTmpCod+" foi informado em duplicidade.",{"Fechar"})
				// retorno invalido
				_lRet := .f.
				Exit
			EndIf
		EndIf
	Next _nX
Return(_lRet)

// ** funcao que grava os recursos humanos utilizados
Static Function sfGrvRecHum(mvNumOS,mvDtEmis,mvDtInic,mvHrInic,mvDtFim,mvHrFim,mvHorTot,mvRecHum,mvFuncao)
	// area inicial
	local _aAreaDCD := DCD->(GetArea())

	// posiciona no cadastro do recurso humano
	dbSelectArea("DCD")
	DCD->(dbSetOrder(1)) //1-DCD_FILIAL, DCD_CODFUN
	DCD->(dbSeek( xFilial("DCD")+mvRecHum ))

	// grava os recursos
	dbSelectArea("SZ8")
	RecLock("SZ8",.t.)
	SZ8->Z8_FILIAL	:= xFilial("SZ8")
	SZ8->Z8_NUMOS	:= mvNumOS
	SZ8->Z8_DTEMIS	:= mvDtEmis
	SZ8->Z8_DTINI	:= mvDtInic
	SZ8->Z8_HRINI	:= mvHrInic
	SZ8->Z8_DTFIM	:= mvDtFim
	SZ8->Z8_HRFIM	:= mvHrFim
	SZ8->Z8_HORTOT	:= mvHorTot
	SZ8->Z8_RECHUM	:= mvRecHum
	SZ8->Z8_FUNCAO	:= mvFuncao
	SZ8->Z8_CUSTO	:= Round( fConvHr(mvHorTot,"D") * DCD->DCD_CUSHR,2)
	MsUnLock()

	// restaura area inicial
	RestArea(_aAreaDCD)

Return(.t.)

// ** funcao que exclui os recursos humanos / da OS
Static Function sfExcRecur(mvNumOS)
	// seek do SZ8
	local _cSeekSZ8

	// tabela de apontamento de recursos
	dbSelectArea("SZ8")
	SZ8->(dbSetOrder(1)) //1-Z8_FILIAL, Z8_NUMOS
	SZ8->(dbSeek( _cSeekSZ8 := xFilial("SZ8")+mvNumOS ))
	While SZ8->(!Eof()).and.(SZ8->(Z8_FILIAL+Z8_NUMOS)==_cSeekSZ8)
		// exclui o item
		RecLock("SZ8")
		SZ8->(dbDelete())
		MsUnLock()
		// proximo item
		SZ8->(dbSkip())
	EndDo

Return(.t.)

// ** funcao para agrupar a OS no pacote logistico
Static Function sfAgrOrdSrv()
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSZ1 := SZ1->(GetArea())
	local _aAreaSZJ := SZJ->(GetArea())
	local _aAreaSZ9 := SZ9->(GetArea())
	// variaveis temporarias
	local _cQuery
	// informacoes temporarias
	local _aTmpInfo := {}
	// quantidade ja utilizada no pacote
	local _nQtdUtil := 0
	// saldo a utilizar
	local _nSaldo := 0
	// produto SERVICOS DIVERSOS do pacote logistico
	local _cProdSrvDiv := ""


	// posiciona no processo
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	SZ1->(dbSeek( xFilial("SZ1")+SZ6->Z6_CODIGO ))


	// verifica se ja existe algum pacote logistico faturado
	_cQuery := "SELECT SZJ.R_E_C_N_O_ SZJRECNO, SZ9.R_E_C_N_O_ SZ9RECNO, Z9_MAXPACO, ISNULL(SUM(ZL_QUANT),0) QTD_APONT "

	// pacote logistico
	_cQuery += "FROM "+RetSqlName("SZJ")+" SZJ  (nolock) "

	// atividades que compoe o item do pacote
	_cQuery += "INNER JOIN "+RetSqlName("SZ9")+" SZ9 (nolock)  ON "+RetSqlCond("SZ9")+" AND Z9_CONTRAT = ZJ_CONTRT AND Z9_ITEM = ZJ_ITCONTR "
	_cQuery += "AND Z9_CODATIV = '"+SZ7->Z7_CODATIV+"' "

	// calcula saldo ja apontado desta atividade no pacote
	_cQuery += "LEFT  JOIN "+RetSqlName("SZL")+" SZL (nolock)  ON "+RetSqlCond("SZL")+" AND ZL_PROCES = ZJ_PROCES AND ZL_ITPROC = ZJ_ITPROC "
	_cQuery += "AND ZL_CONTRT  = ZJ_CONTRT AND ZL_ITCONTR = ZJ_ITCONTR AND ZL_STATUS IN ('C','F') AND ZL_CONTAIN = ZJ_CONTAIN "
	_cQuery += "AND ZL_PACOTE  = ZJ_PACOTE AND ZL_SEQPACO = ZJ_SEQPACO "
	_cQuery += "AND ZL_CODATIV = Z9_CODATIV "

	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SZJ")+" "
	_cQuery += "AND ZJ_PROCES  = '"+SZ6->Z6_CODIGO+"'  AND ZJ_ITPROC = '"+SZ6->Z6_ITEM+"' "
	_cQuery += "AND ZJ_CLIENTE = '"+SZ6->Z6_CLIENTE+"' AND ZJ_LOJA = '"+SZ6->Z6_LOJA+"' "
	_cQuery += "AND ZJ_CONTAIN = '"+SZ6->Z6_CONTAIN+"' "
	_cQuery += "AND ZJ_RIC     = '"+SZ6->Z6_RIC+"' "
	_cQuery += "AND ZJ_CONTRT  = '"+SZ1->Z1_CONTRT+"' "
	_cQuery += "AND ZJ_STATUS IN ('C','F') "
	_cQuery += "AND ZJ_IDPROCE = ' ' "

	// agrupa os dados
	_cQuery += "GROUP BY SZJ.R_E_C_N_O_, SZ9.R_E_C_N_O_, Z9_MAXPACO "

	// alimenta o vetor
	_aTmpInfo := U_SqlToVet(_cQuery)

	// se encontrou informacoes, verifica o saldo
	If (Len(_aTmpInfo) > 0)

		// estrutura do vetor
		// 1-SZJ.R_E_C_N_O_ SZJRECNO
		// 2-SZ9.R_E_C_N_O_ SZ9RECNO
		// 3-Z9_MAXPACO
		// 4-ISNULL(SUM(ZL_QUANT),0) QTD_APONT

		// calcula o saldo disponivel (maximo menos ja utilizado)
		_nSaldo := (_aTmpInfo[1][3] - _aTmpInfo[1][4])

		// se tiver saldo permitido, relaciona o servico da OS no pacote
		If (_nSaldo > 0)

			// posiciona no item do pacote logistico
			dbSelectArea("SZJ")
			SZJ->(dbGoTo( _aTmpInfo[1][1] ))

			// posiciona na atividade no item do pacote logistico
			dbSelectArea("SZ9")
			SZ9->(dbGoTo( _aTmpInfo[1][2] ))

			// pesquisa o produto SERVICOS DIVERSOS dentro do pacote logistico
			_cQuery := "SELECT DISTINCT ZU_PRODUTO FROM "+RetSqlName("SZU")+" SZU  (nolock) "
			// cad. de produtos
			_cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 (nolock)  ON "+RetSqlCond("SB1")+" AND B1_COD = ZU_PRODUTO AND B1_TIPOSRV IN ('7') "
			// filtro padrao
			_cQuery += "WHERE "+RetSqlCond("SZU")+" "
			_cQuery += "AND ZU_CONTRT = '"+SZ1->Z1_CONTRT+"' AND ZU_ITCONTR = '"+SZJ->ZJ_ITCONTR+"' "
			// executa a query
			_cProdSrvDiv := U_FtQuery(_cQuery)


			// cria o item do pacote logistico
			dbSelectArea("SZO")
			SZO->(dbOrderNickName("ZO_PACOTE")) // 1-ZO_FILIAL, ZO_PACOTE, ZO_SEQPACO, ZO_PRODUTO
			If ! SZO->(dbSeek( xFilial("SZO")+SZJ->(ZJ_PACOTE+ZJ_SEQPACO)+_cProdSrvDiv ))
				RecLock("SZO",.t.)
				SZO->ZO_FILIAL	:= xFilial("SZO")
				SZO->ZO_PACOTE	:= SZJ->ZJ_PACOTE
				SZO->ZO_SEQPACO	:= SZJ->ZJ_SEQPACO
				SZO->ZO_PRODUTO	:= _cProdSrvDiv
				MsUnLock()
			EndIf

			// gera os dados dos servicos diversos
			dbSelectArea("SZL")
			RecLock("SZL",.t.)
			SZL->ZL_FILIAL	:= xFilial("SZL")
			SZL->ZL_PROCES	:= SZ6->Z6_CODIGO
			SZL->ZL_ITPROC	:= SZ6->Z6_ITEM
			SZL->ZL_CONTRT	:= SZ1->Z1_CONTRT
			SZL->ZL_ITCONTR	:= SZJ->ZJ_ITCONTR
			SZL->ZL_PRODUTO	:= _cProdSrvDiv
			SZL->ZL_CLIENTE	:= SZ6->Z6_CLIENTE
			SZL->ZL_LOJA	:= SZ6->Z6_LOJA
			SZL->ZL_QUANT	:= _nSaldo
			SZL->ZL_VLRUNIT	:= SZ9->Z9_VALOR
			SZL->ZL_TOTAL	:= (_nSaldo * SZ9->Z9_VALOR)
			SZL->ZL_CONTAIN	:= SZ6->Z6_CONTAIN
			SZL->ZL_DTINIOS	:= SZ6->Z6_EMISSAO
			SZL->ZL_DTFIMOS	:= SZ6->Z6_DTFINAL
			SZL->ZL_NUMOS	:= SZ7->Z7_NUMOS
			SZL->ZL_CODATIV	:= SZ7->Z7_CODATIV
			SZL->ZL_UNIDCOB	:= SZ9->Z9_UNIDCOB
			SZL->ZL_TIPOMOV	:= SZ6->Z6_TIPOMOV
			SZL->ZL_TPOPER	:= SZ7->Z7_TIPOPER
			SZL->ZL_OBS		:= SZ6->Z6_OBSERVA
			SZL->ZL_OBSITEM	:= SZ7->Z7_OBSERVA
			SZL->ZL_FATURAR	:= "S"
			SZL->ZL_STATUS	:= SZJ->ZJ_STATUS
			SZL->ZL_DTPROCE	:= SZJ->ZJ_DTPROCE
			SZL->ZL_USRPROC	:= __cUserId
			SZL->ZL_DATABAS	:= SZJ->ZJ_DATABAS
			SZL->ZL_PACOTE	:= SZJ->ZJ_PACOTE
			SZL->ZL_SEQPACO	:= SZJ->ZJ_SEQPACO
			SZL->ZL_PEDIDO	:= SZJ->ZJ_PEDIDO
			SZL->ZL_ITEMPED	:= SZJ->ZJ_ITEMPED
			MsUnLock()

			// diminui o saldo da atividade
			dbSelectArea("SZ7")
			RecLock("SZ7")
			SZ7->Z7_SALDO	-=_nSaldo
			SZ7->Z7_DTFATAT	:= SZJ->ZJ_DTPROCE
			MsUnLock()

			// atualiza os dados da OS - Cabec
			dbSelectArea("SZ6")
			RecLock("SZ6")
			SZ6->Z6_STATUS := "P" // P-Pedido
			MsUnlock()

		EndIf

	EndIf

	// restaura area inicial
	RestArea(_aAreaSZ9)
	RestArea(_aAreaSZJ)
	RestArea(_aAreaSZ1)
	RestArea(_aAreaAtu)

Return(.t.)

// ** funcao que retornar os equipamentos utilizados
Static Function sfRetEquip()
	// variavel de retorno
	local _aRet := {}
	local _cQuery

	// seleciona a tabela de equipamentos
	dbSelectArea("SZP")

	// alimenta o header dos equipamentos
	aAdd(_aHeadEqu,{"Código", "ZP_CODEQUI", PesqPict("SZP","ZP_CODEQUI"), TamSx3("ZP_CODEQUI")[1], 0,"U_WMSA002W()",Nil,"C",Nil,"R",,,".T." })
	aAdd(_aHeadEqu,{"Descrição", "ZQ_DESCRIC", PesqPict("SZQ","ZQ_DESCRIC"), TamSx3("ZQ_DESCRIC")[1], 0,Nil,Nil,"C",Nil,"R",,,".F." })
	//aAdd(_aHeadEqu,{"Horim. Inicial", "ZP_HORINI", PesqPict("SZP","ZP_HORINI"), TamSx3("ZP_HORINI")[1], 0,Nil,Nil,"N",Nil,"R",,,".t." })
	//aAdd(_aHeadEqu,{"Horim. Final", "ZP_HORFIM", PesqPict("SZP","ZP_HORFIM"), TamSx3("ZP_HORFIM")[1], 0,Nil,Nil,"N",Nil,"R",,,".t." })
	//aAdd(_aHeadEqu,{"Total Horas", "ZP_HORTOT", PesqPict("SZP","ZP_HORTOT"), TamSx3("ZP_HORTOT")[1], 0,Nil,Nil,"N",Nil,"R",,,".F." })

	// alimenta o acols
	_cQuery := "SELECT ZQ_CODIGO, ZQ_DESCRIC, "
	//_cQuery += "ZP_HORINI, ZP_HORFIM, ZP_HORTOT,
	_cQuery += "'.F.' IT_DEL "
	// equipamentos da Ord Servico
	_cQuery += "FROM "+RetSqlName("SZP")+" SZP (nolock)  "
	// cad. de equipamentos
	_cQuery += "INNER JOIN "+RetSqlName("SZQ")+" SZQ (nolock)  ON "+RetSqlCond("SZQ")+" AND ZQ_CODIGO = ZP_CODEQUI "
	// filtra itens da OS
	_cQuery += "WHERE "+RetSqlCond("SZP")+" "
	_cQuery += "AND ZP_NUMOS = '"+_cNumOS+"' "
	_cQuery += "ORDER BY ZQ_CODIGO "
	// alimenta o aCols
	_aRet := U_SqlToVet(_cQuery)

Return(_aRet)

// ** funcao para validacao do codigo de equipamento
User Function WMSA002W()
	local _nLin

	// valida duplicidade de equipamento
	For _nLin := 1 To len(_oBrwEquip:aCols)
		// valida se a linha esta deletada
		If (!_oBrwEquip:aCols[_nLin,Len(_aHeadEqu)+1])
			// duplicidade de itens
			If (_nLin <> _oBrwEquip:nAt).and.(AllTrim(_oBrwEquip:aCols[_nLin,1]) == AllTrim(M->ZP_CODEQUI))
				Alert("Este equipamento/máquina já existe e não pode ser incluida novamente !!")
				Return(.f.)
			EndIf
		EndIf
	Next _nLin

	// descricao do equipamento
	dbSelectArea("SZQ")
	SZQ->(dbSetOrder(1)) // 1-ZQ_FILIAL, ZQ_CODIGO
	If SZQ->(dbSeek( xFilial("SZQ")+M->ZP_CODEQUI )).and.(cFilAnt $ SZQ->ZQ_DISPFIL)
		// atualiza a descricao
		_oBrwEquip:aCols[_oBrwEquip:nAt,2] := SZQ->ZQ_DESCRIC
	Else
		Alert("Equipamento inválido !!")
		Return(.f.)
	EndIf

Return(.t.)

// ** funcao que exclui os equipamentos/maquinas da OS
Static Function sfExcEquip(mvNumOS)
	// seek do SZP
	local _cSeekSZP

	// tabela de apontamento de equipamento
	dbSelectArea("SZP")
	SZP->(dbSetOrder(1)) //1-ZP_FILIAL, ZP_NUMOS
	SZP->(dbSeek( _cSeekSZP := xFilial("SZP")+mvNumOS ))
	While SZP->(!Eof()).and.(SZP->(ZP_FILIAL+ZP_NUMOS)==_cSeekSZP)
		// exclui o item
		RecLock("SZP")
		SZP->(dbDelete())
		MsUnLock()
		// proximo item
		SZP->(dbSkip())
	EndDo

Return(.t.)

// ** funcao para validar e calcular as horas digitadas
User Function WMSA002Z()
	// campo
	local _cTmpCampo := AllTrim(ReadVar())
	// conteudo
	local _nTmpHora := &(_cTmpCampo)
	Local _nMinutos := Val(Right(StrZero(_nTmpHora,5,2),2))
	// hora inicial
	local _nHoraIni := If("INI" $ _cTmpCampo,_nTmpHora,_oBrwEquip:aCols[_oBrwEquip:nAt,3])
	// hora final
	local _nHoraFin := If("FIM" $ _cTmpCampo,_nTmpHora,_oBrwEquip:aCols[_oBrwEquip:nAt,4])
	// total de horas
	local _nHoraTot := Max(0,SubHoras(_nHoraFin,_nHoraIni))

	// valida os minutos da hora
	If (_nMinutos < 0).Or.(_nMinutos > 59)
		Aviso("TWMSA002 -> WMSA002Z (Vld Hora)","A hora digitada é inválida!",{"Fechar"})
		Return(.f.)
	EndIf

	// valida hora final maior que hora inicial
	If ("FIM" $ _cTmpCampo).and.(_nHoraFin <= _nHoraIni)
		Aviso("TWMSA002 -> WMSA002Z (Vld Hora)","A hora final deve ser maior que a hora inicial!",{"Fechar"})
		Return(.f.)
	EndIf

	// atualiza o total de hora
	_oBrwEquip:aCols[_oBrwEquip:nAt,5] := _nHoraTot

Return(.t.)

// ** funcao para validar a hora digitada
Static Function sfVldHora(mvHora)
	local _lRet := .t.

	// valida hora digita
	If (_lRet).and.(Len(AllTrim(mvHora))<>5)
		Aviso("TWMSA002 -> sfVldHora","A hora digitada é inválida!",{"Fechar"})
		_lRet := .f.
	EndIf

	// valida formato da hora digita
	If (_lRet).and.(!VldHora(Val(StrTran(mvHora,":","."))))
		Aviso("TWMSA002 -> sfVldHora","A hora digitada é inválida!",{"Fechar"})
		_lRet := .f.
	EndIf

Return(_lRet)

// ** funcao que retorna a mao de obra utilizada
Static Function sfRetMaoObr()
	// variavel de retorno
	local _aRet := {}
	local _cQuery

	// seleciona a tabela de mao de obra
	dbSelectArea("SZV")
	dbSelectArea("SZX")

	// alimenta o header da mao de obra
	aAdd(_aHeadMaoObr,{"Operação"  , "ZX_TPOPER" , PesqPict("SZX","ZX_TPOPER") , TamSx3("ZX_TPOPER")[1] , 0,Nil,Nil,"C",Nil,"R",,,".T." })
	aAdd(_aHeadMaoObr,{"Item"      , "ZX_ITEMTAB", PesqPict("SZX","ZX_ITEMTAB"), TamSx3("ZX_ITEMTAB")[1], 0,"U_WMSA002U()",Nil,"C",Nil,"R",,,".T." })
	aAdd(_aHeadMaoObr,{"Descrição" , "ZX_DSCOPER", PesqPict("SZX","ZX_DSCOPER"), TamSx3("ZX_DSCOPER")[1], 0,nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadMaoObr,{"Nr Guia"   , "ZX_GUIA"   , PesqPict("SZX","ZX_GUIA")   , TamSx3("ZX_GUIA")[1]   , 0,Nil,Nil,"C",Nil,"R",,,".T." })
	aAdd(_aHeadMaoObr,{"Mercadoria", "ZX_MERC"   , PesqPict("SZX","ZX_MERC")   , TamSx3("ZX_MERC")[1]   , 0,Nil,Nil,"C",Nil,"R",,,".T." })

	// alimenta o aCols
	_cQuery := "SELECT ZX_TPOPER, ZX_ITEMTAB, ZX_DSCOPER, ZX_GUIA, ZX_MERC, "
	_cQuery += "'.F.' IT_DEL "
	// mao de obra da Ord Servico
	_cQuery += "FROM "+RetSqlName("SZX")+" SZX (nolock)  "
	// filtra itens da OS
	_cQuery += "WHERE "+RetSqlCond("SZX")+" "
	_cQuery += "AND ZX_NUMOS = '"+_cNumOS+"' "
	// alimenta o aCols
	_aRet := U_SqlToVet(_cQuery)

Return(_aRet)

// ** funcao para validacao do codigo da tabela de preco da mao de obra
User Function WMSA002U()
	local _lRet := .t.
	local _nLin
	/*
	// valida duplicidade de operacao
	For _nLin := 1 To len(_oBrwMaoObr:aCols)
	// valida se a linha esta deletada
	If (!_oBrwMaoObr:aCols[_nLin,Len(_aHeadMaoObr)+1])
	// duplicidade de itens
	If (_nLin <> _oBrwMaoObr:nAt).and.(AllTrim(_oBrwMaoObr:aCols[_nLin,1]) == AllTrim(M->ZX))
	Alert("Esta operação já está informada e não pode ser incluída novamente !!")
	Return(.f.)
	EndIf
	EndIf
	Next _nLin
	*/

	// descricao da operacao da mao de obra
	If (_lRet)
		dbSelectArea("SZV")
		SZV->(dbSetOrder(1)) // 1-ZV_FILIAL, ZV_CODIGO, ZV_ITEM
		If SZV->(dbSeek( xFilial("SZV")+_cTabMaoObr+M->ZX_ITEMTAB ))
			// atualiza a descricao
			_oBrwMaoObr:aCols[_oBrwMaoObr:nAt,3] := SZV->ZV_DSCOPER
		Else
			Alert("Operação de Mão de Obra inválida!")
			_lRet := .f.
		EndIf
	EndIf

Return(_lRet)

// ** funcao que exclui a mao de obra da OS
Static Function sfExcMaoObr(mvNumOS)
	// seek do SZX
	local _cSeekSZX

	// tabela de apontamento de mao de obra
	dbSelectArea("SZX")
	SZX->(dbSetOrder(1)) //1-ZX_FILIAL, ZX_NUMOS
	SZX->(dbSeek( _cSeekSZX := xFilial("SZX")+mvNumOS ))
	While SZX->(!Eof()).and.(SZX->(ZX_FILIAL+ZX_NUMOS)==_cSeekSZX)
		// exclui o item
		RecLock("SZX")
		SZX->(dbDelete())
		MsUnLock()
		// proximo item
		SZX->(dbSkip())
	EndDo

Return(.t.)

// ** funcao para visualizar a atividade
Static Function sfAtvVisual(mvCodAtv)
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSZT := SZT->(GetArea())

	// cadastro de atividades
	dbSelectArea("SZT")
	SZT->(dbSetORder(1)) //1-ZT_FILIAL, ZT_CODIGO
	SZT->(dbSeek( xFilial("SZT")+mvCodAtv ))

	// funcao padrao de visualizacao
	AxVisual("SZT",SZT->(Recno()),2)

	// restaura area inicial
	RestArea(_aAreaSZT)
	RestArea(_aAreaAtu)
Return

// ** funcao que valida a atividade de carregamento (total ou fracionado)
Static Function sfVldCarreg(mvProces,mvItProc,mvPedido,mvCodAtv,mvCliente,mvLoja)
	local _cRetAtv := mvCodAtv
	// query
	local _cQuery := ""
	// variaveis temporarias
	local _aQtdEntSai := {0,0}

	_cQuery := "SELECT SUM(D1_QUANT) QTD_ENT, SUM(C6_QTDVEN) QTD_SAI "
	_cQuery += "FROM "+RetSqlName("SC6")+" C6 (nolock) , "+RetSqlName("SD1")+" D1 (nolock)  "
	_cQuery += "WHERE C6_FILIAL = D1_FILIAL AND C6_CLI = D1_FORNECE AND C6_LOJA = D1_LOJA AND C6_NFORI = D1_DOC AND "
	_cQuery += "C6_SERIORI = D1_SERIE AND C6_ITEMORI = D1_ITEM AND "
	_cQuery += "C6_FILIAL  = '"+xFilial("SC6")+"' AND C6_NUM = '"+mvPedido+"' AND "
	_cQuery += "D1_PROGRAM = '"+mvProces+"' AND D1_ITEPROG = '"+mvItProc+"' AND "
	_cQuery += "C6.D_E_L_E_T_ <> '*' AND D1.D_E_L_E_T_ <> '*' "
	// alimenta o vetor
	_aQtdEntSai := U_SqlToVet(_cQuery)

	// carregamento total
	If (_aQtdEntSai[1][1] == _aQtdEntSai[1][2])
		// busca atividade de carregamento total
		_cQuery := "SELECT ZT_CODIGO FROM "+RetSqlName("SZT")+" SZT (nolock)  "
		_cQuery += "WHERE "+RetSqlCond("SZT")+" "
		_cQuery += "AND ZT_SAIDA = '1' AND ZT_MSBLQL != '1' "
		_cQuery += "AND ZT_TIPO = 'CT' "
		_cQuery += " AND EXISTS (SELECT * "
		_cQuery += " FROM   "+RetSqlTab("SZ9")+" (nolock) "
		_cQuery += " WHERE  Z9_CODATIV = ZT_CODIGO
		_cQuery += "       AND "+RetSqlCond("SZ9")
		_cQuery += "       AND Z9_CONTRAT IN (SELECT AAM_CONTRT
		_cQuery += "                          FROM   "+RetSqlTab("AAM")+" (nolock) "
		_cQuery += "                          WHERE  "+RetSqlCond("AAM")
		_cQuery += "                                 AND AAM_CODCLI = '" + mvCliente + "'
		_cQuery += "                                 AND AAM_LOJA = '" + mvLoja + "'
		_cQuery += "                                 AND AAM_STATUS = '1'))
		// executa a query
		_cRetAtv := U_FtQuery(_cQuery)

		memowrit("C:\query\twmsa002_vldcarreg_CT.txt", _cQuery)

		// carregamento fracionado/parcial
	ElseIf (_aQtdEntSai[1][1] > _aQtdEntSai[1][2])
		// busca atividade de carregamento total
		_cQuery := "SELECT ZT_CODIGO FROM "+RetSqlName("SZT")+" SZT (nolock)  "
		_cQuery += "WHERE "+RetSqlCond("SZT")+" "
		_cQuery += "AND ZT_SAIDA = '1' AND ZT_MSBLQL != '1' "
		_cQuery += "AND ZT_TIPO = 'CF' "
		_cQuery += " AND EXISTS (SELECT * "
		_cQuery += " FROM   "+RetSqlTab("SZ9")+" (nolock) "
		_cQuery += " WHERE  Z9_CODATIV = ZT_CODIGO
		_cQuery += "       AND "+RetSqlCond("SZ9")
		_cQuery += "       AND Z9_CONTRAT IN (SELECT AAM_CONTRT
		_cQuery += "                          FROM   "+RetSqlTab("AAM")+" (nolock) "
		_cQuery += "                          WHERE  "+RetSqlCond("AAM")
		_cQuery += "                                 AND AAM_CODCLI = '" + mvCliente + "'
		_cQuery += "                                 AND AAM_LOJA = '" + mvLoja + "'
		_cQuery += "                                 AND AAM_STATUS = '1'))
		// executa a query
		_cRetAtv := U_FtQuery(_cQuery)

		memowrit("C:\query\twmsa002_vldcarreg_CF.txt", _cQuery)

	EndIf

Return(_cRetAtv)

// ** funcao para atualizar a lista de fornecedores de mao de obra
Static Function sfMoFornec()
	// veriavel de retorno
	local _aRet := {}
	// codigo dos prestadores ativos
	local _aFornMO := Separa(AllTrim(SuperGetMv("TC_FORNMOB",.f.,"")),";")
	// variaveis temporarias
	local _nFornMO
	local _cTmpFornec
	local _cTmpTabPre
	local _aTmpLinha

	// varre todos os prestadores
	For _nFornMO := 1 to Len(_aFornMO)
		// valida se nao esta vazio
		If ( ! Empty(_aFornMO[_nFornMO]))
			// separa os dados (cod forn / tab preco)
			_aTmpLinha := Separa(_aFornMO[_nFornMO],"/")
			// extrai o codigo do fornecedor
			_cTmpFornec := _aTmpLinha[1]
			// extrai a tabela de preco
			_cTmpTabPre := _aTmpLinha[2]

			// cad. de fornecedor
			dbSelectArea("SA2")
			SA2->(dbSetOrder(1)) //1-A2_FILIAL, A2_COD, A2_LOJA
			SA2->(dbSeek( xFilial("SA2")+_cTmpFornec ))
			// adiciona o fornecedor
			aAdd(_aRet,SA2->A2_COD+"/"+SA2->A2_LOJA+"-"+AllTrim(SA2->A2_NREDUZ))

			// define o codigo da tabela de preco de mao de obra
			_cTabMaoObr := _cTmpTabPre

		EndIf
	Next _nFornMO

Return(_aRet)

// ** funcao para adicionar LOG da finalizacao da OS
Static Function sfAddLog(mvTipo,mvStatus,mvLog)
	local _cRet := ""

	// quantidade da atividade
	If (mvTipo=="001").and.(!mvStatus)
		_cRet += "[ATIVIDADE - QUANTIDADE NÃO INFORMADA]"+CRLF
		mvStatus := .t.

		// mao de obra
	ElseIf (mvTipo=="002").and.(!mvStatus)
		_cRet += "[MÃO DE OBRA - INFORMAÇÕES OBRIGATÓRIAS]"+CRLF
		mvStatus := .t.

		// quantidade de carregamento
	ElseIf (mvTipo=="003").and.(!mvStatus)
		_cRet += "[CARREGAMENTO]"+CRLF
		mvStatus := .t.

		// operadores
	ElseIf (mvTipo=="004").and.(!mvStatus)
		_cRet += "[OPERADORES]"+CRLF
		mvStatus := .t.

		// conferentes
	ElseIf (mvTipo=="005").and.(!mvStatus)
		_cRet += "[CONFERENTES]"+CRLF
		mvStatus := .t.

		// servicos gerais
	ElseIf (mvTipo=="006").and.(!mvStatus)
		_cRet += "[SERVIÇOS GERAIS]"+CRLF
		mvStatus := .t.

		// equipamentos
	ElseIf (mvTipo=="007").and.(!mvStatus)
		_cRet += "[MÁQUINAS / EQUIPAMENTOS]"+CRLF
		mvStatus := .t.

		// horarios
	ElseIf (mvTipo=="008").and.(!mvStatus)
		_cRet += "[DATA / HORA]"+CRLF
		mvStatus := .t.

		// campo observacao
	ElseIf (mvTipo=="009").and.(!mvStatus)
		_cRet += "[ATIVIDADE - CAMPO OBSERVAÇÃO/FATURAMENTO]"+CRLF
		mvStatus := .t.

	EndIf

	// adiciona o texto
	_cRet += " - "+mvLog+CRLF

Return(_cRet)

// ** funcao para apresentar as OS pendentes do usuario
Static Function sfMsgOSPend()
	local _lRet := .t.
	local _cQrySZ6 := ""
	local _aOrdAbert
	local _nOrdAbert
	local _cMsgOS := ""
	local _cQuebraCli := ""
	local _cPictOS := PesqPict("SZ6","Z6_NUMOS")

	// valida se o processo possui ordens de servico em abero
	_cQrySZ6 := "SELECT A1_NOME, Z6_CODIGO, Z6_NUMOS, Z6_EMISSAO "
	// ordens de servico
	_cQrySZ6 += "FROM "+RetSqlName("SZ6")+" SZ6 (nolock)  "
	// cad. do cliente
	_cQrySZ6 += "INNER JOIN "+RetSqlName("SA1")+" SA1 (nolock)  ON "+RetSqlCond("SA1")+" AND A1_COD = Z6_CLIENTE AND A1_LOJA = Z6_LOJA "
	// filtro de ordens de servico em aberto
	_cQrySZ6 += "WHERE "+RetSqlCond("SZ6")+" "
	// sem data de finalizacao
	_cQrySZ6 += "AND Z6_DTFINAL = ' ' "
	// status de OS Aberta
	_cQrySZ6 += "AND Z6_STATUS  = 'A' "
	// somente do usuario logado
	_cQrySZ6 += "AND Z6_USRINC  = '"+__cUserId+"' "
	// somente antes do dia anterior
	_cQrySZ6 += "AND Z6_EMISSAO < '"+DtoS(Date())+"' "
	// ordem dos dados
	_cQrySZ6 += "ORDER BY A1_NOME, Z6_CODIGO, Z6_NUMOS "
	// executa a query
	_aOrdAbert := U_SqlToVet(_cQrySZ6,{"Z6_EMISSAO"})

	// apresenta mensagem caso tiver OS em aberto
	If (Len(_aOrdAbert) > 0)
		// varre todos os itens
		For _nOrdAbert := 1 to Len(_aOrdAbert)
			// variavel de retorno
			_lRet := .f.
			// inclui o cliente
			If (_cQuebraCli != _aOrdAbert[_nOrdAbert][1])
				// inclui mensagem
				_cMsgOS += "Cliente: "+_aOrdAbert[_nOrdAbert][1] +CRLF
				// controle de quebra
				_cQuebraCli := _aOrdAbert[_nOrdAbert][1]
			EndIf
			// complemento da mensagem
			_cMsgOS += "Processo: "+_aOrdAbert[_nOrdAbert][2]+"    Nr OS: "+Transf(_aOrdAbert[_nOrdAbert][3],_cPictOS)+"   Data Abertura: "+DtoC(_aOrdAbert[_nOrdAbert][4])+ CRLF
		Next _nOrdAbert
		// mensagem
		If (!_lRet)
			HS_MsgInf(_cMsgOS,;
			"TWMSA002 -> sfMsgOSPend",;
			"Processo possui "+AllTrim(Str(Len(_aOrdAbert)))+" ordens de serviço em aberto!" )
		EndIf
	EndIf

Return(_lRet)

// ** rotina pra validar se a OS contem todos os serviços necessários ** //
Static Function sfVldServOS( mvNumos )

	// variavel de controle de retorno
	local _lRet := .t.
	// registro da query
	local _cQuery := ""
	// variavel que recebe os grupos de estoque
	local _aGrpEst := {}
	// variavel para controle de loop
	local _nGrp := 0
	// pega area inicial
	local _aAreaInicial := GetArea()
	// seek na tabela de itens da OS
	local _cSeekSZ7 := ""
	local _nServ080 := 0, _nServ128 := 0, _nServ133 := 0
	local _lServ080 := .t., _lServ128 := .t., _lServ133 := .t.
	// variavel de log
	local _cLog := ""

	// query para identificar os grupos de estoque que deveriam constar na OS
	_cQuery := "  SELECT DISTINCT B1_ZGRPEST "
	_cQuery += "  	FROM   " + RetSqlTab( "SZ6" ) + " (nolock)  "
	_cQuery += "  	       INNER JOIN " + RetSqlTab( "SC6" ) + " (nolock)  "
	_cQuery += "	               ON C6_NUM = Z6_PEDIDO "
	_cQuery += "	                  AND C6_CLI = Z6_CLIENTE "
	_cQuery += "	                  AND C6_LOJA = Z6_LOJA "
	_cQuery += "	                  AND " + RetSqlCond( "SC6" ) + " "
	_cQuery += "	        INNER JOIN " + RetSqlTab( "SD1" ) + " (nolock)  "
	_cQuery += "	               ON D1_FORNECE = C6_CLI "
	_cQuery += "	                  AND D1_LOJA = C6_LOJA "
	_cQuery += "	                  AND D1_DOC = C6_NFORI "
	_cQuery += "	                  AND D1_SERIE = C6_SERIORI "
	_cQuery += "	                  AND D1_ITEM = C6_ITEMORI "
	_cQuery += "	                  AND D1_PROGRAM = Z6_CODIGO "
	_cQuery += "                      AND " + RetSqlCond( "SD1" ) + " "
	_cQuery += "	        INNER JOIN " + RetSqlTab( "SB1" ) + " (nolock)  ON B1_COD = D1_COD AND " + RetSqlCond( "SB1" ) + " "
	_cQuery += "	WHERE  " + RetSqlCond( "SZ6" ) + " "
	_cQuery += "	  AND Z6_NUMOS = '" + mvNumos + "' "

	// jogo os dados no vetor para comparação
	_aGrpEst := U_SqlToVet(_cQuery)

	// para possível debug, jogo a query num arquivo
	memowrit("C:\query\twmsa002_sfVldServOS.txt", _cQuery)

	// posiciono nos itens da OS, para validar se eles estão corretos
	dbSelectArea( "SZ7" )
	SZ7->( dbSetOrder( 1 ) ) // Z7_FILIAL, Z7_NUMOS, Z7_CODATIV, R_E_C_N_O_, D_E_L_E_T_
	SZ7->( dbSeek ( _cSeekSZ7 := xFilial("SZ7") + mvNumos ) )

	// para cada registro da SZ7
	While ( SZ7->( ! EoF() ) ) .and. ( SZ7->( Z7_FILIAL + Z7_NUMOS ) == _cSeekSZ7 )

		// atividade 080
		If ( SZ7->Z7_CODATIV  == "080" )
			_nServ080++
		EndIf

		// atividade 128
		If ( SZ7->Z7_CODATIV  == "128" )
			_nServ128++
		EndIf

		// atividade 080
		If ( SZ7->Z7_CODATIV  == "133" )
			_nServ133++
		EndIf

		// próx registro
		SZ7->( dbSkip() )
	EndDo

	// para cada grupo de estoque que faz parte do processo
	For _nGrp := 1 to len( _aGrpEst )

		// 0001 - AROS 13 e 14 & 0003 - TRB
		If ( _aGrpEst[_nGrp] $ "0001/0003" ) .and. ( _nServ080 == 0 )

			// altero a variável para poder mostrar ao usuário
			_lServ080 := .f.

			// 0002 - AROS 15 em diante & 0004 - PNEU TOYOTA & grupo 0009
		ElseIf ( ( _aGrpEst[_nGrp] $ "0002/0004/0009" ) ) .and. ( _nServ133 == 0 )

			// altero a variável para poder mostrar ao usuário
			_lServ133 := .f.

			// 0100 - MATERIA PRIMA
		ElseIf ( _aGrpEst[_nGrp] == "0100" ) .and. ( _nServ128 == 0 )

			// altero a variável para poder mostrar ao usuário
			_lServ128 := .f.

		EndIf

	Next _nGrp

	// prepara a mensagem para o usuário
	If ( ! _lServ080 )
		_cLog += "Inconsistência: Atividade 080 não lançada. " + CRLF
		_cLog += "Solução: É necessário lançar a atividade 080 - CARREGAMENTO COM MÃO DE OBRA/FRACIONADO. " + CRLF
	EndIf

	// prepara a mensagem para o usuário
	If ( ! _lServ128 )
		_cLog += "Inconsistência: Atividade 128 não lançada. " + CRLF
		_cLog += "Solução: É necessário lançar a atividade 128 - CARREGAMENTO. " + CRLF
	EndIf

	// prepara a mensagem para o usuário
	If ( ! _lServ133 )
		_cLog += "Inconsistência: Atividade 133 não lançada. " + CRLF
		_cLog += "Solução: É necessário lançar a atividade 133 - CARREGAMENTO COM MÃO DE OBRA/AROS GRANDES. " + CRLF
	EndIf

	// se tem informação de log, avisa o usuário
	If ( ! Empty ( _cLog ) )
		_cLog += CRLF + "A OS não será finalizada. " + CRLF

		// avisa o usuário
		HS_MsgInf("LOG:"+CRLF+_cLog,"Log da Finalização da OS","Inconsistência na Finalização da OS "+mvNumos)

		// atualiza variável de retorno
		_lRet := .f.
	EndIf

	// restaura area padrão
	RestArea(_aAreaInicial)
Return _lRet

// ** função que vai deselecionar o browse para cancelar a ação ** //
Static Function sfCancAtiv( mvDlg )

	// pergunta pro user se quer sair
	If ( MsgYesNo( "Deseja sair?" ) )

		dbSelectArea( ATI )
		(ATI)->( dbGotop() )
		While (ATI)->( ! EoF() )
			RecLock( ATI, .F. )
			(ATI)->ATI_OK := ""
			MsUnlock()

			// próx registro
			(ATI)->( dbSkip() )
		EndDo

		// volta pro início do trb
		(ATI)->( dbGotop() )

		// limpa varíavel exclusiva da sumitomo
		_lAtvGrpEst := .f.

		// fecha o browse
		mvDlg:End()
	EndIf

Return

// ** função para validar se está utilizando as atividades conforme grupo de estoque e manualmente ** //
Static Function sfVldConf( mvDlg )

	// variável de retorno
	local _lRet    := .t.
	// para controle da seleção
	local _lSigned := .f.
	// log da função
	local _cLog := ""

	// não pode deixar escolher do browse e carregar automático
	// assim, faz as validações
	// pergunta pro user se confirma
	If ( MsgYesNo( "Confirma Atividades Selecionadas?" ) )

		dbSelectArea(ATI)
		(ATI)->( dbGotop() )
		While (ATI)->( ! EoF() )
			If( ! Empty( (ATI)->ATI_OK ) )
				_lSigned := .t.
				Exit
			EndIf
			// próx registro
			(ATI)->( dbSkip() )
		EndDo

		// se foi selecionado ambas as opções
		If ( _lSigned ) .and. ( _lAtvGrpEst )
			_cLog += "Inconsistência: A opção 'Carregar Atividades Conforme Grupo de Estoque' foi selecionada. Não é permitido selecionar outras atividades!" + CRLF + CRLF
			_cLog += "Solução: Desmarque a opção 'Carregar Atividades Conforme Grupo de Estoque' ou desmarque as atividades selecionadas manualmente." + CRLF + CRLF
			_lRet := .f.
		EndIf

		// volta pro início do trb
		(ATI)->( dbGotop() )

		If ( _lRet )
			// fecha o browse
			mvDlg:End()
		Else
			// se encontrou algum log da rotina, mostra pro user
			If( ! Empty( _cLog ) )
				_cLog += CRLF + "Atividades não confirmadas. " + CRLF

				// avisa o usuário
				HS_MsgInf("LOG:"+CRLF+_cLog,"Log da Seleção de Atividades da OS","Inconsistência nas Atividades")
			EndIf
		EndIf
	EndIf

Return

// ** função para validar campos** //
User Function WMSA002Y ( mvCompField, mvPosField )

	// variável de controle de retorno
	local _lRet := .t.
	// controle de loop
	local _nZ := 0
	// campo de comparação
	local _cCompara :=  _oBrwAtividade:aCols[_oBrwAtividade:nAt, mvCompField]

	// solicita permissão para o usuário
	If ( MsgYesNo("Deseja replicar as informações para os demais serviços da mesma atividade?", "Atenção") )

		// para cada registro do acols, vou validar se o campo de comparação é igual
		For _nZ := 1 to len(_oBrwAtividade:aCols)

			// somente para a atividade que está sendo alterada
			If ( _oBrwAtividade:aCols[_nZ][mvCompField] ==  _cCompara)

				// faturar sim/não
				If ( mvPosField == 4 )
					_oBrwAtividade:aCols[_nZ][4] := M->Z7_FATURAR
					_oBrwAtividade:aCols[_nZ][7] := _oBrwAtividade:aCols[_oBrwAtividade:nAt, 7]
				EndIf
			EndIf
		Next _nX

		// refresh no browse
		_oBrwAtividade:Refresh()
	EndIf

Return _lRet

// ** funcao para definir o menu
Static Function MenuDef()
	// variavel de retorno
	local _aRetMenu := {;
	{ "Pesquisar"           ,"AxPesqui"		       , 0 , 1},;
	{ "Visualizar"          ,"U_WMSA002F(.F.,.f.)" , 0 , 2},;
	{ "Programar"           ,"U_WMSA002P()"        , 0 , 3},;
	{ "Finalizar"           ,"U_WMSA002F(.T.,.f.)" , 0 , 4},;
	{ "Finalizar em massa"  ,"U_WMSA002F(.T.,.t.)" , 0 , 4},;
	{ "Imprimir"            ,"U_TWMSR003()"        , 0 , 4},;
	{ "Estornar"            ,"U_WMSA002E()"        , 0 , 5},;
	{ "Estornar em massa"   ,"U_WMSA002J()"        , 0 , 5},;
	{ "Excluir"             ,"U_WMSA002X()"        , 0 , 5},;
	{ "Excluir em massa"    ,"U_WMSA002H()"        , 0 , 5},;
	{ "Liberar Foto"        ,"U_WMSA002G()"        , 0 , 4},;
	{ "Legenda"             ,"U_WMSA002L()"        , 0 , 2 }}
Return(_aRetMenu)

//** funcao para criar o grupo de perguntas
Static Function CriaPg01(_cPerg)

	local _aPerg := {}

	// monta a lista de perguntas
	aAdd(_aPerg,{"Da Ordem de Servico:"  ,"C",9,0,"G",,"SZ6",{{"X1_VALID","!Empty(MV_PAR01)"}}}) //mv_par01
	aAdd(_aPerg,{"Ate Ordem de Servico:" ,"C",9,0,"G",,"SZ6",{{"X1_VALID","!Empty(MV_PAR02)"}}}) //mv_par02

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg,.T.)

Return

// ** funcao que verifica a necessidade de foto por cliente e atvidade
Static Function sfRetFoto(mvCnt, mvAtv)
	// variavel de retorno
	local _lRet := .f.
	// query
	local _cQuery
	// lista de servicos/atividades
	local _cSqlAtiv := ""

	// prepara lista de servicos
	aEval(mvAtv,{|_nX| _cSqlAtiv += _nX[1] + "|" })

	// prepara query para ver se tem fotos x cliente e servico
	_cQuery := " SELECT COUNT(Z25_SERVIC) QTD_SERVIC "
	_cQuery += " FROM   " + RetSqlTab("Z25") + " (nolock) "
	_cQuery += " WHERE  " + RetSqlCond("Z25")
	_cQuery += "        AND Z25_ORIGEM = 'SZ6' "
	_cQuery += "        AND Z25_CODCLI = '" + mvCnt[5] + "' "
	_cQuery += "        AND Z25_LOJCLI = '" + mvCnt[6] + "' "
	_cQuery += "        AND Z25_SERVIC IN " + FormatIn(_cSqlAtiv, "|")

	memowrit("c:\query\twmsa002_sfRetFoto.txt", _cQuery)

	// atualiza variavel de retorno
	_lRet := (U_FtQuery(_cQuery) != 0)

Return(_lRet)

// ** funcao que forca a liberacao para capturar fotos
User Function WMSA002G
	// variavel de controle
	local _lRet := .t.
	// area atual
	local _aAreaSZ6 := SZ6->(GetArea())
	// cria vetor com informacoes da ordem de servico
	local _aCabOS := {SZ6->Z6_CONTAIN, SZ6->Z6_TIPOMOV, SZ6->Z6_CODIGO, SZ6->Z6_ITEM, SZ6->Z6_CLIENTE, SZ6->Z6_LOJA, SZ6->Z6_EMISSAO, SZ6->Z6_STATUS, "", SZ6->Z6_PEDIDO, "", SZ6->Z6_PLACA1, SZ6->Z6_OBSERVA, ""}
	local _aAtvOS := {}
	// seek
	local _cSeekSZ6
	local _cSeekSZ7
	// numero da OS, sem sequencial
	local _cNumOrdSrv := SubStr(SZ6->Z6_NUMOS, 1, 6)

	// verifica o status atual da ordem de servico
	If (_lRet) .and. (SZ6->Z6_STATUS != "A")
		// mensagem
		MsgStop("Opção disponível somente para ordens de serviço com status Em Aberto.")
		// retorno
		_lRet := .f.
	EndIf

	// verifica o status atual da foto da ordem de servico
	If (_lRet) .and. (SZ6->Z6_FOTO != "N")
		// mensagem
		MsgStop("Opção disponível somente para ordens de serviço com status de foto como N-Não Precisa. Status Atual: " + SZ6->Z6_FOTO)
		// retorno
		_lRet := .f.
	EndIf

	// verifica se tem a regra de foto por cliente e atvidade
	If (_lRet)

		// verifica as atividades da ordem de servico
		dbSelectArea("SZ7")
		SZ7->(dbSetOrder(1)) //1-Z7_FILIAL, Z7_NUMOS, Z7_CODATIV
		SZ7->(dbSeek( _cSeekSZ7 := xFilial("SZ7") + SZ6->Z6_NUMOS ))
		While SZ7->( ! Eof() ) .and. (SZ7->(Z7_FILIAL+Z7_NUMOS) == _cSeekSZ7)
			// inclui registro no vetor
			aAdd(_aAtvOS, {SZ7->Z7_CODATIV, SZ7->Z7_CONTRT, SZ7->Z7_ITEM, SZ7->Z7_ORDEM, SZ7->Z7_FATURAR, SZ7->Z7_TIPOPER, SZ7->Z7_QUANT, SZ7->Z7_UNIDCOB})
			// proximo item da OS
			SZ7->(dbSkip())
		EndDo

		// funcao que verifica se tem a regra cadastrada
		_lRet := sfRetFoto(_aCabOS, _aAtvOS)

		// verifica o status atual da ordem de servico
		If ( ! _lRet )
			// mensagem
			MsgStop("Não há regra cadastrada de fotos x serviço x cliente. Favor verificar o cadastro de regras.")
		EndIf

	EndIf

	If (_lRet)

		// posiciona na ordem de servico
		dbSelectArea("SZ6")
		SZ6->( DbSetOrder(1) ) // 1-Z6_FILIAL, Z6_NUMOS, Z6_CLIENTE, Z6_LOJA
		SZ6->( DbSeek( _cSeekSZ6 := xFilial("SZ6") + _cNumOrdSrv ))

		// varre todas as sequencias da ordem de servico
		While SZ6->( ! Eof() ) .and. (SZ6->(Z6_FILIAL + Z6_NUMOS) >= _cSeekSZ6) .and. (SZ6->(Z6_FILIAL + Z6_NUMOS) <= _cSeekSZ6 + "999")
			// atualiza campos
			RecLock("SZ6")
			SZ6->Z6_FOTO := "P" // P = PENDENTE ENVIO
			SZ6->(MsUnLock())

			// gera log
			U_FtGeraLog(xFilial("SZ6"), "SZ6", SZ6->Z6_FILIAL + SZ6->Z6_NUMOS, "AppFotos: Ordem de Serviço com Status PENDENTE ENVIO", "WMS", SZ6->Z6_CODIGO)

			// proximo item
			SZ6->(dbSkip())
		EndDo

		// restaura area inicial
		RestArea(_aAreaSZ6)

		// mensagem
		MsgInfo("Ordem de Serviço Liberada para captura de fotos. Favor acessar a rotina de Gestão de Fotos para atribuir a ordem para algum colaborador.")
	EndIf

Return(_lRet)