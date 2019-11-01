#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para atualizar o numero da nota fiscal no aviso  !
!                  ! de recebimento de cargas (devolucao de cliente)         !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe José Limas         ! Data de Criacao   ! 04/2015 !
+------------------+---------------------------------------------------------+
!Observacoes       ! Chamada do PE MTA145MNU                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSA025()

	Private _cNotaAtu   := CriaVar("DB2_DOC",.f.)
	Private _cNotaNov   := CriaVar("DB2_DOC",.f.)
	Private _cSerieAtu  := CriaVar("DB2_SERIE",.f.)
	Private _cSerieNov  := CriaVar("DB2_SERIE",.f.)
	Private	_oFont1
	Private	_oDlg_Tela
	Private	oPanel_Esq
	Private	oPanel_Dir
	Private	oTit_Esq
	Private	oTit_Dir
	Private	oGet_cNatu
	Private	oGet_cSatu
	Private	oGet_cNnov
	Private	oGet_cSnov
	Private	oBtn_OK
	Private	oBtn_Cance

	// CABECALHO DOC DE RECEBIMENTO
	dbSelectArea("DB2")
	DB2->(dbSetOrder(2)) //DB2_FILIAL+DB2_NRAVRC+DB2_ITEM
	//Pocisiona na Tabela DB2
	DB2->(dbSeek( xFilial("DB2")+ DB1->DB1_NRAVRC))

	//Se ja foi atualizado a nota não permitir fazer uma nova atualização.
	If (DB2->DB2_ZSUBNF == 'S')
		MsgStop("Este Recebimento ja foi informado um Doc Fiscal !")
		Return()
	EndIF

	// armazena numero da nota e serie
	_cNotaAtu  := DB2->DB2_DOC
	_cSerieAtu := DB2->DB2_SERIE

	_oFont1     := TFont():New( "MS Sans Serif",0,-13,,.T.,0,,700,.F.,.F.,,,,,, )

	_oDlg_Tela  := MSDialog():New( 124,363,372,790,"Substituir Nota Fiscal",,,.F.,,,,,,.T.,,,.T. )

	oPanel_Esq := TPanel():New( 000,000,"",_oDlg_Tela,,.F.,.F.,,,095,116,.T.,.F. )
	oPanel_Dir := TPanel():New( 000,095,"",_oDlg_Tela,,.F.,.F.,,,112,116,.T.,.F. )
	oPanel_Esq:align:= CONTROL_ALIGN_LEFT
	oPanel_Dir:align:= CONTROL_ALIGN_RIGHT

	oTit_Esq      := TSay():New( 004,004,{||"Valor Atual"}         ,oPanel_Esqu,,_oFont1,.F.,.F.,.F.,.T.,,,085,012)
	oTit_Dir      := TSay():New( 004,004,{||"Valor para Atualizar"},oPanel_Dire,,_oFont1,.F.,.F.,.F.,.T.,,,085,012)

	oGet_cNatu     := TGet():New( 027,004,{|u| If(PCount()>0,_cNotaAtu:=u,_cNotaAtu)}  ,oPanel_Esqu,060,008,'',,,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"",_cNotaAtu  ,,,,,, .T. ,"Nota" , 1 )
	oGet_cSatu     := TGet():New( 050,004,{|u| If(PCount()>0,_cSerieAtu:=u,_cSerieAtu)},oPanel_Esqu,060,008,'',,,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"",_cSerieAtu ,,,,,, .T. ,"Série", 1 )
	oGet_cNnov     := TGet():New( 027,008,{|u| If(PCount()>0,_cNotaNov:=u,_cNotaNov)}  ,oPanel_Dire,060,008,'',{|| U_FtStrZero() },,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNotaNov",,,,,, .T. ,"Nota" , 1 )
	oGet_cSnov     := TGet():New( 050,008,{|u| If(PCount()>0,_cSerieNov:=u,_cSerieNov)},oPanel_Dire,060,008,'',,,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"",_cSerieNov ,,,,,, .T. ,"Série", 1 )

	oGet_cNatu:Disable()
	oGet_cSatu:Disable()

	oBtn_OK    := TButton():New( 083,013,"Confirma",oPanel_Dire,{||sfAtuaNota()}      ,037,012,,,,.T.,,"",,,,.F. )
	oBtn_Cance := TButton():New( 083,061,"Cancela" ,oPanel_Dire,{||_oDlg_Tela:End() } ,037,012,,,,.T.,,"",,,,.F. )

	_oDlg_Tela:Activate(,,,.T.)

Return

// ** funcao para atualizar o numero da nota
Static Function sfAtuaNota()

	// Seek
	Local _cSeekZ04
	Local _cSeekSD2
	Local _cSeekZ07
	Local _cSeekZ05
	Local _cNumOrdSrv
	// Query
	local _cQryZ07
	// variaveis temporarias
	local _aTmpRecno := {}
	local _nX

	// CABECALHO DAS NF DE ENTRADA
	dbSelectArea("SF1")
	SF1->(dbSetOrder(1)) // 1-F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
	//Verifica se ja existe a nota Fiscal
	If( ! SF1->(dbSeek(xFilial("SF1") + _cNotaNov + _cSerieNov + DB1->DB1_CLIFOR + DB1->DB1_LOJA + DB1->DB1_TIPONF)))

		MsgStop("Nota Fiscal informada não existe na Base de dados !")
		Return()

		//Se não existir atualiza a nota fiscal nas tabelas envolvidas no Processo(DB2,Z04,Z07,Z16).
	Else

		// inicia transacao
		BEGIN TRANSACTION

			RecLock("DB2",.f.)

			DB2->DB2_ZSUBNF := 'S'
			DB2->DB2_DOC    := _cNotaNov
			DB2->DB2_SERIE  := _cSerieNov

			DB2->(MsUnLock())

			// WMS - MERCADORIAS DA CARGA
			dbSelectArea("Z04")
			Z04->(dbSetOrder(3)) // 3-Z04_FILIAL+Z04_CLIENT+Z04_LOJA+Z04_TIPONF+Z04_NF+Z04_SERIE
			// Verifica se ja registro na tabela Z04 para este recebimento.
			Z04->(dbSeek( _cSeekZ04 := xFilial("Z04") + DB1->DB1_CLIFOR + DB1->DB1_LOJA + DB1->DB1_TIPONF + _cNotaAtu + _cSerieAtu ))

			// WMS - ORDEM DE SERVICO
			dbSelectArea("Z05")
			Z05->(dbSetOrder(2)) // 2-Z05_FILIAL+Z05_CESV
			Z05->(dbSeek( _cSeekZ05 := xFilial("Z05") + Z04->Z04_CESV ))
			_cNumOrdSrv := Z05->Z05_NUMOS

			// varre todos os itens amarrados a uma CESV
			While Z04->( ! Eof() ).and.(Z04->(Z04_FILIAL+Z04_CLIENT+Z04_LOJA+Z04_TIPONF+Z04_NF+Z04_SERIE) == _cSeekZ04)

				// ITENS DAS NF DE ENTRADA
				dbSelectArea("SD1")
				SD1->(dbSetOrder(1)) // 1-D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
				SD1->(dbSeek( _cSeekSD2 := xFilial("SD1") + _cNotaNov + _cSerieNov + DB1->DB1_CLIFOR + DB1->DB1_LOJA + Z04->Z04_PROD ))

				// atualiza os campos
				RecLock("Z04")

				Z04->Z04_NF     := _cNotaNov
				Z04->Z04_SERIE  := _cSerieNov
				Z04->Z04_NF     := _cNotaAtu
				Z04->Z04_SERIE  := _cSerieAtu
				Z04->Z04_ITEMNF := SD1->D1_ITEM
				Z04->Z04_NUMSEQ := SD1->D1_NUMSEQ

				Z04->(MsUnLock())

				// monta SQL para Buscar RECNO tabelas Z07 E Z16
				_cQryZ07 := "SELECT Z07.R_E_C_N_O_ Z07RECNO, ISNULL(Z16.R_E_C_N_O_,0) Z16RECNO "
				// itens em conferencia
				_cQryZ07 += "FROM "+RetSqlName("Z07")+" Z07 "
				// composicao do palete
				_cQryZ07 += "LEFT JOIN "+RetSqlName("Z16")+" Z16 ON "+RetSqlCond("Z16")+" AND Z16_ETQPAL = Z07_PALLET "
				_cQryZ07 += "     AND Z16_ETQVOL = Z07_ETQVOL AND Z16_ETQPRD = Z07_ETQPRD AND Z16_CODBAR = Z07_CODBAR "
				_cQryZ07 += "     AND Z16_CODPRO = Z07_PRODUT AND Z16_ENDATU = Z07_ENDATU "
				// filtro padrao
				_cQryZ07 += "WHERE "+RetSqlCond("Z07")+" "
				// filtro por OS
				_cQryZ07 += "AND Z07_NUMOS  = '"+_cNumOrdSrv+"'"
				// cliente e loja
				_cQryZ07 += "AND Z07_CLIENT = '"+DB1->DB1_CLIFOR+"'  AND Z07_LOJA  = '"+DB1->DB1_LOJA+"' "
				_cQryZ07 += "AND Z07_PRODUT = '"+Z04->Z04_PROD+"' "
				// alimenta o vetor
				_aTmpRecno := U_SqlToVet(_cQryZ07)

				// varre todos os recno
				For _nX := 1 to Len(_aTmpRecno)

					// posiciona no registro real - conferencia
					dbSelectArea("Z07")
					Z07->(dbGoTo( _aTmpRecno[_nX][1] ))

					RecLock("Z07")
					Z07->Z07_NUMSEQ := SD1->D1_NUMSEQ
					Z07->(MsUnLock())

					// posiciona no registro real - estrutura do palete
					If (_aTmpRecno[_nX][2] > 0)
						dbSelectArea("Z16")
						Z16->(dbGoTo( _aTmpRecno[_nX][2] ))

						RecLock("Z16")
						Z16->Z16_NUMSEQ := SD1->D1_NUMSEQ
						Z16->(MsUnLock())
					EndIf

				Next _nX

				// proximo item
				Z04->(dbSkip())
			EndDo

			// finaliza transacao
		END TRANSACTION

	EndIf

	// mensagem de confirmacao
	ApMsgAlert("Informações Atualizadas")

	// fecha tela principal
	_oDlg_Tela:End()
Return()