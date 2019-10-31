#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
! Descricao        ! Rotinas para integração entre os sistemas GWS (Sumitomo)!
!                  ! e Totvs, conforme projeto de integração 2019 fase 1     !
!                  !                                                         !
+------------------+---------------------------------------------------------+
! Sub-descrição    ! EDI/Integracões de IMPORTAÇÃO                           !
+------------------+---------------------------------------------------------+
! Autor            ! Luiz Fernando Berti - SLA Consultoria                   !
! Data de criação  ! 06/2019                                                 !
+------------------+---------------------------------------------------------+
! Redmine          ! 414                     ! Chamado           !           !
+------------------+--------------------------------------------------------*/


/*/{Protheus.doc} MSUM001
Função auxiliar para Integração SUMITOMO
Chamada por agendamento.
@author Luiz Fernando Berti
@since 02/05/2019
/*/
User function TWMA047J() 

	LOCAL cMsg      := ""

	OpenSM0()
	If RpcSetEnv( "01","105",,,,"TWMSA047",,,,, )
		FWLogMsg('INFO',, 'SIGATMS', "TWMA047J", '', '01',"Iniciando o processo principal de TWMA047J" , 0, 0, {})
		cMsg:= PadR("| INICIO JOB SUMITOMO - TWMSA047 - "+FWTimeStamp(1,Date(),Time()),103)+"|"
		U_FtGeraLog(cFilAnt, "", "", cMsg, "001", "", "000000")
		TWMS047I()
		cMsg:= PadR("| FIM JOB SUMITOMO -  TWMSA047 - "+FWTimeStamp(1,Date(),Time()),103)+"|"
		U_FtGeraLog(cFilAnt, "", "", cMsg, "001", "", "000000")
		FWLogMsg('INFO',, 'SIGATMS', "TWMA047J", '', '01',"Finalizando o processo principal TWMA047J" , 0, 0, {})
		RpcClearEnv()
		Sleep(1000)		
	EndIf

Return

/*/{Protheus.doc} TWMSA047
Função para importação de etiquetas do cliente.
@type function
@author Luiz Fernando
@since 07/05/2019
/*/
User Function TWMSA047()

	TWMS047I()

Return

/*/{Protheus.doc} TWMS047I
Função auxiliar para ler o arquivo e importar.
@type function
@author Usuário
@since 17/05/2019
@see (links_or_references)
/*/
Static Function TWMS047I(cArquivo)

	LOCAL nHdl        := 0
	LOCAL cMsg        := ""
	LOCAL cLinha      := ""
	LOCAL aCampos     := {}
	LOCAL aDados      := {}
	LOCAL cArqTxt     := ""//cArquivo
	LOCAL cDirSum     := "\sumitomo\"
	LOCAL lPrim       := .T.
	LOCAL nFor        := 0
	LOCAL lOK         := .T.
	LOCAL cTipo       := ""
	LOCAL cLockFile   := lower("TWMSA047")+".lck"
	LOCAL bOrder      := {|x,y| Subs(x[1],16,10) < Subs(y[1],16,10)   }//Ordena pela sequencia do arquivo. 
	LOCAL nHdlJob

	cMsg:= "INICIO Importação SUMITOMO "+FWTimeStamp(1,Date(),Time())
	U_FtGeraLog(cFilAnt, "", "", cMsg, "001", "", "000000")	

	/*Foi necessario implementar controle de execuções, por algum motivo, quando a execução
	do programa é por JOB, ocorre a chamada da função em duplicidade, ocorrendo erro 
	interferindo na correta execução da função. 
	Esse recurso previne também, que no mesmo momento 2 processos estejam importando o mesmo arquivo.
	*/
	If !jobIsRunning(cLockFile)

		nHdlJob := JobSetRunning( cLockFile, .T. )
		If nHdlJob >= 0 

			//Criação dos diretorios. 
			If !ExistDir( "\sumitomo\" )
				MakeDir( "\sumitomo\" )
			EndIf
			If !ExistDir( "\sumitomo\processado\" )
				MakeDir( "\sumitomo\processado\" )
			EndIf
			If !ExistDir( "\sumitomo\erro\" )
				MakeDir( "\sumitomo\erro\" )
			EndIf

			//Busca os arquivos e ordena pelo nome do arquivo.
			aArqs := Directory(cDirSum+"*.csv")
			aArqs:= AClone(ASort(aArqs,,,bOrder))

			For nArq:= 1 To Len(aArqs)
				lOK    := .T.
				cArqTxt:= cDirSum+aArqs[nArq][01]
				//Leitura do arquivo 
				If File(cArqTxt)
					oFile := FWFileReader():New(cArqTxt)//"TMSB707_TI_22_0000000013.csv"
					If (oFile:Open())
						aLinhas:= oFile:getAllLines()
						oFile:Close()
						aDados:= {}
						For nFor:= 1 To Len(aLinhas)
							cLinha:= aLinhas[nFor]
							If !Empty(cLinha)
								AADD(aDados,Separa(cLinha,CHR(9),.T.))    
							EndIf
						Next
					endif
				Else
					cMsg:= "ERRO - Não foi possível encontrar o arquivo para leitura. "+cArqTxt+" - TWMSA047"
					U_FtGeraLog(cFilAnt, "", "", cMsg, "001", "", "000000")
					lOK:= .F.
				EndIf

				//Localiza o Tipo de Importação
				cTipo := ""
				If Len(aDados)>0
					cTipo := AllTrim(aDados[01][03])//EX_ACTION_CLASS
				Else 
					lOK := .F.
				EndIf

				Do Case 
					Case cTipo == "11" //Integração Etiquetas de Produtos (Z55/Z56)
					aRetorno := fImpProd(aCampos,aDados,cArqTxt)
					If !(lOK:= aRetorno[1])
						cMsg := aRetorno[2]
						// libera todos os registros
						MsUnLockAll()	
						U_FtGeraLog(cFilAnt, "001", "", cMsg, "001", "", "000000")
					EndIf

					Case cTipo == "01"//Integração importação de pedidos de vendas.
					//aRetorno := fImpPed(aCampos,aDados,cArqTxt)
					aRetorno := fAtuPed(aDados,cArqTxt)
					For  nFor:=1 to Len(aRetorno)//[01]lOK,[2]Mensagem[3]tabela,[4]Chave

						U_FtGeraLog(cFilAnt, aRetorno[nFor][03],aRetorno[nFor][04],aRetorno[nFor][02], "001", "", "000000")
						If lOK
							lOK := aRetorno[nFor][01]
						EndIf
					Next

					Case cTipo == "04"//Integração Exclusão de Etiquetas de produtos.
					aRetorno := fImpCanc(aCampos,aDados,cArqTxt)
					If !(lOK:=aRetorno[1])
						cMsg := aRetorno[2]
						// libera todos os registros
						MsUnLockAll()	
						U_FtGeraLog(cFilAnt, "001", "", cMsg, "001", "", "000000")
					EndIf

					Case cTipo == "05"//Bloqueio de separação
					lOK := .T.
					aRetorno:= AClone(fImpBlDes(aDados,cArqTxt))
					For nFor:= 1 To Len(aRetorno)//[01]lOK,[2]Mensagem[3]tabela,[4]Chave
						U_FtGeraLog(cFilAnt, aRetorno[nFor][3], aRetorno[nFor][4], aRetorno[nFor][2], "001", "", "000000")
						If lOK
							lOK := aRetorno[nFor][01]
						EndIf
					Next

					Case cTipo == "41"////Bloqueio/Desbloqueio de Estoque
					lOK := .T.
					aRetorno:= AClone(fBlqEst(aDados,cArqTxt))
					For nFor:= 1 To Len(aRetorno)//[01]lOK,[2]Mensagem[3]tabela,[4]Chave
						U_FtGeraLog(cFilAnt, aRetorno[nFor][3], aRetorno[nFor][4], aRetorno[nFor][2], "001", "", "000000")
						If lOK
							lOK := aRetorno[nFor][01]
						EndIf
					Next

					Case cTipo == "22" 
					lOK := .T.
					aRetorno:= AClone(fMovBack(aDados,cArqTxt))
					For nFor:= 1 To Len(aRetorno)//[01]lOK,[2]Mensagem[3]tabela,[4]Chave
						U_FtGeraLog(cFilAnt, aRetorno[nFor][3], aRetorno[nFor][4], aRetorno[nFor][2], "001", "", "000000")
						If lOK
							lOK := aRetorno[nFor][01]
						EndIf
					Next

					Otherwise
					cMsg:= "ERRO ***ACTION CLASS não esperada para a importação."+cTipo+ " - Arquivo:"+cArquivo+ " - TWMS047I "
					U_FtGeraLog(cFilAnt, "001", "", cMsg, "001", "", "000000")
					lOK:= .F.
				EndCase

				If lOK
					//Tratamento para renomear o arquivo quando o mesmo ja foi importado anteriormente.
					If (FRename( cDirSum+aArqs[nArq][01], cDirSum+"\processado\"+aArqs[nArq][01])) <> 0
						FRename( cDirSum+aArqs[nArq][01], cDirSum+"\processado\"+FWTimeStamp(1,Date(),Time())+"_"+aArqs[nArq][01])
					EndIf
				Else		  
					If (FRename( cDirSum+aArqs[nArq][01], cDirSum+"\erro\"+aArqs[nArq][01])) <> 0
						FRename( cDirSum+aArqs[nArq][01], cDirSum+"\erro\"+FWTimeStamp(1,Date(),Time())+"_"+aArqs[nArq][01]) 
					EndIf  
				EndIf

				//Tratamento para quando o mesmo arquivo (importado anteriormente) vier para a pasta de raíz, vindo de aplicação externa.
				If File(cArqTxt)
					__CopyFile(cDirSum+aArqs[nArq][01],cDirSum+"\erro\")		   
					If FErase(cArqTxt) == -1
						cMsg:= "IMPORTAÇÃO SUMITOMO Erro ao apagar arquivo: "+cDirSum+aArqs[nArq][01]+" - "+FERROR()
						U_FtGeraLog(cFilAnt, "", "", cMsg, "001", "", "000000")		    	
					EndIf			   
				Endif 
			Next

			JobSetRunning( cLockFile, .F., nHdlJob )	
		EndIf
	Else
		cMsg:= "IMPORTAÇÃO SUMITOMO Processo em execução por outro usuário "+cLockFile+" "+FWTimeStamp(1,Date(),Time())
		U_FtGeraLog(cFilAnt, "", "", cMsg, "001", "", "000000")	
	EndIf
Return lOK

/*/{Protheus.doc} fimpProd
Função auxiliar para importação de etiquetas de produtos.
@type function
@author Luiz Fernando
@since 02/05/2019
/*/
Static Function fimpProd(aCampos,aDados,cArquivo)

	LOCAL _aCabEtique := {}
	LOCAL _aItmEtique := {}
	LOCAL _aTmpEtique := {}
	LOCAL aItmEtique  := {}
	LOCAL cChaveSA1   := ""
	LOCAL cPedCli     := ""
	LOCAL nHdl        := 0
	LOCAL cMsg        := ""
	LOCAL nFor        := 0
	LOCAL _nEtiqAtu   := 0 
	LOCAL _cCliCod    := ""
	LOCAL _cCliLoj    := ""
	LOCAL _cCliSigla  := ""
	LOCAL _cCliNome   := ""
	LOCAL cFilArq     := ""
	LOCAL cFilBkp     := cFilAnt
	LOCAL lRetOk      := .F.
	LOCAL nIF_SEQ     := 1//IF_SEQ
	LOCAL nBRANCH_NO  := 2//BRANCH_NO
	LOCAL nACTION     := 3//EX_ACTION_CLASS
	LOCAL nFrom    	  := 4//SEND_FROM
	LOCAL nDestino    := 5//SEND_DESTINATION
	LOCAL nTire    	  := 6//TIRE_BC
	LOCAL nStore      := 7//STORE_YEAR_WEEK
	LOCAL nStoreCD    := 8//STOREHOUSE_CD
	LOCAL nTicket     := 9//TICKET_NO
	LOCAL nShipp      := 10//SHIPPING_INS_NO
	LOCAL nMARKET     := 11//MARKET
	LOCAL nSTATUS     := 12//STATUS
	LOCAL nFact4      := 13//FACTORY_PART_NO4"
	LOCAL nFact6      := 14//FACTORY_PART_NO6" //Código do produto
	LOCAL nCONICITY   := 15//CONICITY
	LOCAL nProdClas   := 16//PRODUCT_PROTO_CLASS
	LOCAL nCNT    	  := 17//CNT
	LOCAL nProdFab    := 18//PRODUCT_YEAR_WEEK
	LOCAL nLoteN      := 19//LOT_NO
	LOCAL nBefSta     := 20//BEFORE_STATUS
	LOCAL nLINE   	  := 21//LINE
	LOCAL nTireBC     := 22//TIRE_BC_FLG
	LOCAL nWrapp      := 23//WRAPPING_FLG
	LOCAL nBuffFl     := 24//BUFF_FLG
	LOCAL nSEALO1     := 25//SEAL_NO1
	LOCAL nSEALO2     := 26//SEAL_NO2
	LOCAL nSEALO3     := 27//SEAL_NO3
	LOCAL nSEALO4     := 28//SEAL_NO4
	LOCAL nSEALO5     := 29//SEAL_NO5
	LOCAL nContNo     := 30//CONTAINNER_NO
	LOCAL nLoaDt      := 31//LOADING_FINISH_DATE

	If Len(aDados) >0 .And. AllTrim(aDados[01][nACTION]) <> "11"
		cMsg := "ERRO - Arquivo sem dados ou não se refere a importacao de etiquetas (Ação 11). - "+cArquivo+" - TWMSA047"
		Return{.F.,cMsg,""}
	EndIf

	DBSelectArea("SA1")
	dbSelectArea("Z55")
	dbSelectArea("Z56")
	SA1->(DBSetOrder(01))//A1_FILIAL+A1_COD+A1_LOJA
	For nFor := 1 To Len(aDados) 

		//Localiza o cliente com base na filial de armazenagem.   
		If Empty(cChaveSA1:= fEmpFil(AllTrim(aDados[nFor][nDestino])))
			cMsg:= "ERRO - Filial não esperada na importação Código: "+aDados[nFor][nDestino]+" - Arquivo: "+cArquivo+" - TWMSA047"
			Return{.F.,cMsg,AllTrim(aDados[nFor][nShipp])}   
		EndIf

		cPedCli:= AllTrim(aDados[nFor][nShipp])
		//Verifica se ja existe importação para o pedido.
		Z55->(DBSetOrder(02))//Z55_FILIAL+Z55_PEDCLI
		If Z55->(MsSeek(xFilial("Z55")+cPedCli))
			cMsg:="ERRO - Pedido do cliente já Cadastrado: "+cPedCli+" - Arquivo: "+cArquivo+" - TWMSA047"
			Return{.F.,cMsg,cPedCli}
		EndIf

		//Tratamento para buscar o código do cliente.
		dbSelectArea("SA1")
		SA1->(dbSetOrder(1)) // FIlial+Codigo+Loja
		If ( ! SA1->(dbSeek( xFilial("SA1") + cChaveSA1)) )
			cMsg:="ERRO - Cliente " + cChaveSA1 + " não disponível ou não cadastrado para operação. - "+cArquivo+" - TWMSA047"
			Return{.F.,cMsg,cPedCli}
		EndIf

		_cCliCod   := SA1->A1_COD
		_cCliLoj   := SA1->A1_LOJA
		_cCliSigla := SA1->A1_SIGLA
		_cCliNome  := SA1->A1_NOME

		// define conteudo para rotina automatica
		//Informacao do cabecalho da importação
		aAdd(_aCabEtique, {"Z55_CODCLI", _cCliCod , Nil})
		aAdd(_aCabEtique, {"Z55_LOJCLI", _cCliLoj , Nil})
		aAdd(_aCabEtique, {"Z55_ARQUIV", cArquivo, Nil})
		aAdd(_aCabEtique, {"Z55_FORENT", "2"      , Nil}) // 2 - Integracao
		aAdd(_aCabEtique, {"Z55_PEDCLI",  AllTrim(aDados[nFor][nShipp])     , Nil}) //SHIPPING_INS_NO
		//aAdd(_aCabEtique, {"Z55_SUMI", "1", Nil})//1-SIM;2-NAO - Informa se a importação é sumitomo.



		_nEtiqAtu    := 0
		_aTmpEtique  := {}
		_aItmEtique  := {}

		For nFor1:= nFor To Len(aDados)		
			If AllTrim(aDados[nFor][nShipp]) <> AllTrim(aDados[nFor1][nShipp])
				Exit
			EndIf 
			//Defincao dos itens da importação
			_cPrdCodCli := AllTrim(aDados[nFor1][nFact6])//FACTORY_PART_NO6 - Codigo do produto do cliente. 
			_cPrdCodigo := ""
			_cArmNfNum  := ""
			_cArmNfSer  := ""
			_cArmNfItm  := ""
			_nPrdQtdEtq := 1
			_lCtrlLote  := .F.
			_dDtValid   := CtoD("//")
			_dDtFabric  := CtoD("//")
			_cInfCompl  := ""	
			//Localiza o código do produto do cliente para inclusão nos itens - Codigo do produto = Juncao Cod Cliente com a Siga cadastrada no Cd Cliente.
			//_cPrdCodCli := _cPrdCodCli	
			_cPrdCodigo := PadR((AllTrim(_cCliSigla)+_cPrdCodCli), TamSx3("B1_COD")[1])

			// verifica se o produto existe
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1)) // 1-B1_FILIAL, B1_COD
			If (!SB1->(dbSeek( xFilial("SB1")+_cPrdCodigo)))
				cMsg:= "ERRO - Produto " + AllTrim(_cPrdCodCli)+ " não cadastrado - Arquivo: "+cArquivo+" - TWMSA047"
				Return{.F.,cMsg}
			EndIf

			_nEtiqAtu+=1
			_aTmpEtique := {}
			aAdd(_aTmpEtique, {"Z56_SEQUEN", StrZero(_nEtiqAtu, TamSx3("Z56_SEQUEN")[1]), Nil })
			aAdd(_aTmpEtique, {"Z56_ETQCLI", AllTrim(aDados[nFor1][nTire]), Nil})//TIRE_BC - Codigo da Etiqueta
			aAdd(_aTmpEtique, {"Z56_NOTA", _cArmNfNum, Nil})
			aAdd(_aTmpEtique, {"Z56_SERIE", _cArmNfSer, Nil})
			aAdd(_aTmpEtique, {"Z56_ITEMNF", _cArmNfItm, Nil})				
			aAdd(_aTmpEtique, {"Z56_CODPRO", _cPrdCodigo, Nil })
			aAdd(_aTmpEtique, {"Z56_QUANT", _nPrdQtdEtq, Nil})
			aAdd(_aTmpEtique, {"Z56_DTVALI", _dDtValid, Nil})
			aAdd(_aTmpEtique, {"Z56_DTFABR", _dDtFabric, Nil})
			aAdd(_aTmpEtique, {"Z56_INFCOM", _cInfCompl, Nil})		
			aAdd(_aTmpEtique, {"Z56_TICKET",  AllTrim(aDados[nFor1][nTicket])     , Nil}) //TICKET_NO
			aAdd(_aTmpEtique, {"Z56_FAC4",  AllTrim(aDados[nFor1][nFact4])     , Nil}) //FACTORY_PART_NO4
			aAdd(_aTmpEtique, {"Z56_STORE", AllTrim(aDados[nFor1][nStore])     , Nil})//
			aAdd(_aTmpEtique, {"Z56_TIPO", AllTrim(aDados[nFor1][nCONICITY])     , Nil})//CONICITY\		

			aAdd(_aItmEtique, _aTmpEtique)
		Next
		nFor := nFor1 -1
		// padroniza dicionario de dados
		aItmEtique := AClone(FWVetByDic(_aItmEtique, 'Z56', .T.))				

		lMsErroAuto := .F.
		lAutoErrNoFile := .T.

		// chama rotina automatica para geracao da integração de etiqueta
		MSExecAuto({|x,y,z| U_TWMSA040(x,y,z)}, _aCabEtique, aItmEtique, 3)

		If ( ! lMsErroAuto)
			cMsg:= "SUCESSO - Importado Remessa: "+Z55->Z55_REMESS+" Arquivo: "+cArquivo+" - TWMSA047"
			U_FtGeraLog(cFilAnt, "Z55", Z55->(Z55_FILIAL+Z55_REMESS), cMsg, "001", "", "000000")
		Else
			// captura dados detalhados da rotina automatica
			//MostraErro()
			_aErroAuto := GetAutoGRLog()
			cMsg:= "ERRO - Arquivo: "+cArquivo
			For _nCount := 1 To Len(_aErroAuto)
				cMsg += StrTran(StrTran(StrTran(_aErroAuto[_nCount],"<",""),"-",""),"   "," ") + (" ")
			Next _nCount
			cMsg+= " - TWMSA047 - execauto: TWMSA040"
			Return{.F.,cMsg,cPedCli}
		EndIf
	Next

Return{.T.,"",""}


/*/{Protheus.doc} fImpCanc
Função para importação de cancelamento da etiqueta
@type function
@author Luiz Fernando
@since 07/05/2019
/*/
Static Function fImpCanc(aCampos,aDados,cArquivo)

	LOCAL nFor        := 0
	LOCAL _aCabEtique := {}
	LOCAL _aTmpEtique := {}
	LOCAL _aItmEtique := {}
	LOCAL nACTION     := 03//EX_ACTION_CLASS
	LOCAL nDestino    := 05//SEND_DESTINATION
	LOCAL nShipp      := 06//SHIPPING_INS_NO
	LOCAL cRemessa    := ""
	LOCAL lSepara     := .F.
	LOCAL lNF         := .F.
	LOCAL lOK         := .T.

	If Len(aDados) >0 .And. Upper(AllTrim(aDados[01][nACTION])) <> "04"
		cMsg := "ERRO - EXCLUSÃO REMESSA - Arquivo sem dados ou não se refere a importacao de Exclusão de Etiquetas (Ação C). - "+cArquivo+" - TWMSA047(fImpCanc)"
		Return{.F.,cMsg}
	EndIf

	dbSelectArea("Z55")
	dbSelectArea("Z56")

	For nFor := 1 To Len(aDados) 

		lSepara:= .F.
		lNF    := .F.
		//Localiza o cliente com base na filial de armazenagem.   
		If Empty(cChaveSA1:= fEmpFil(AllTrim(aDados[nFor][nDestino])))
			cMsg:= "ERRO - EXCLUSÃO REMESSA - Filial não esperada na importação Código: "+aDados[nFor][nDestino]+" - Arquivo: "+cArquivo+" - TWMSA047(fImpCanc)"
			Return{.F.,cMsg,AllTrim(aDados[nFor][nShipp])}
		EndIf

		Z55->(DBSetOrder(02))//Z55_FILIAL+Z55_PEDCLI
		Z55->(DBGoTop())
		If !(lOK:= Z55->(MsSeek(xFilial("Z55")+AllTrim(aDados[nFor][nShipp]))))
			cMsg:="ERRO - EXCLUSÃO REMESSA - Pedido do cliente não Cadastrado: "+AllTrim(aDados[nFor][nShipp])+" para cancelamento da etiqueta - Arquivo: "+cArquivo+" - TWMSA047(fImpCanc)"
			Return{.F.,cMsg}
		EndIf

		If lOK
			_aCabEtique:= {}
			aAdd(_aCabEtique, {"Z55_FILIAL", Z55->Z55_FILIAL , Nil})
			aAdd(_aCabEtique, {"Z55_REMESS", Z55->Z55_REMESS , Nil})
			aAdd(_aCabEtique, {"Z55_CODCLI", Z55->Z55_CODCLI , Nil})
			aAdd(_aCabEtique, {"Z55_LOJCLI", Z55->Z55_LOJCLI , Nil})
			aAdd(_aCabEtique, {"Z55_ARQUIV", Z55->Z55_ARQUIV, Nil})
			aAdd(_aCabEtique, {"Z55_FORENT", "2"      , Nil}) // 2 - Integracao
			aAdd(_aCabEtique, {"Z55_PEDCLI", Z55->Z55_PEDCLI     , Nil}) //SHIPPING_INS_NO
			cRemessa:= 	Z55->Z55_REMESS
		EndIf
		//Localiza os itens do pedido.
		Z56->(DBSetOrder(01))//Z56_FILIAL+Z56_REMESS+Z56_SEQUEN
		Z56->(DBGoTop())
		_aTmpEtique := {}
		_aItmEtique  := {}

		If !Z56->(MsSeek(Z55->(Z55_FILIAL+Z55_REMESS))).And.lOK
			cMsg:="ERRO - EXCLUSÃO REMESSA - Etiqueta do cliente sem itens. Etiqueta:"+Z55->Z55_REMESS+" para cancelamento - Arquivo: "+cArquivo+" - TWMSA047(fImpCanc)"
			U_FtGeraLog(cFilAnt, "Z55", Z55->(Z55_FILIAL+Z55_REMESS), cMsg, "001", "", "000000")
			Return{.F.,cMsg}		
		EndIf

		Do While !Z56->(Eof()) .And. Z55->(Z55_FILIAL+Z55_REMESS) == Z56->(Z56_FILIAL+Z56_REMESS).And.lOK 

			If (lSepara:= (Z56->Z56_OK_ENT == "S" .Or. Z56->Z56_OK_SAI == "S" .Or. !Empty(Z56->Z56_CODETI)))
				Exit
			EndIf

			If (lNF:= (!Empty(Z56->Z56_NOTA)))
				Exit
			EndIf	

			aAdd(_aTmpEtique, {"Z56_FILIAL", Z56->Z56_FILIAL, Nil })
			aAdd(_aTmpEtique, {"Z56_REMESS", Z55->Z55_REMESS , Nil})
			aAdd(_aTmpEtique, {"Z56_CODCLI", Z55->Z55_CODCLI, Nil})
			aAdd(_aTmpEtique, {"Z56_LOJCLI", Z55->Z55_LOJCLI, Nil})	
			aAdd(_aTmpEtique, {"Z56_SEQUEN", Z56->Z56_SEQUEN, Nil })
			aAdd(_aTmpEtique, {"Z56_ETQCLI", Z56->Z56_ETQCLI, Nil})//TIRE_BC - Codigo da Etiqueta
			aAdd(_aTmpEtique, {"Z56_NOTA",   Z56->Z56_NOTA, Nil})
			aAdd(_aTmpEtique, {"Z56_SERIE",  Z56->Z56_SERIE, Nil})
			aAdd(_aTmpEtique, {"Z56_ITEMNF", Z56->Z56_ITEMNF, Nil})				
			aAdd(_aTmpEtique, {"Z56_CODPRO", Z56->Z56_CODPRO, Nil })
			aAdd(_aTmpEtique, {"Z56_QUANT",  Z56->Z56_QUANT, Nil})
			aAdd(_aTmpEtique, {"Z56_DTVALI", Z56->Z56_DTVALI, Nil})
			aAdd(_aTmpEtique, {"Z56_DTFABR", Z56->Z56_DTFABR, Nil})
			aAdd(_aTmpEtique, {"Z56_INFCOM", Z56->Z56_INFCOM, Nil})		
			aAdd(_aTmpEtique, {"Z56_TICKET", Z56->Z56_TICKET     , Nil}) //TICKET_NO
			aAdd(_aTmpEtique, {"Z56_FAC4",   Z56->Z56_FAC4     , Nil}) //FACTORY_PART_NO4
			aAdd(_aItmEtique, _aTmpEtique)

			Z56->(DBSkip())
		EndDo
		_aItmEtique := AClone(FWVetByDic(_aItmEtique, 'Z56', .T.))

		lMsErroAuto := .F.
		lAutoErrNoFile := .T.

		If !lSepara .And. !lNF .And. lOK
			// chama rotina automatica para geracao da integração de etiqueta
			MSExecAuto({|x,y,z| U_TWMSA040(x,y,z)}, _aCabEtique, _aItmEtique, 5)
			If ( ! lMsErroAuto)
				cMsg:= "SUCESSO - EXCLUSÃO REMESSA - Excluído Remessa: "+cRemessa+" Arquivo: "+cArquivo+" - TWMSA047(fImpCanc)"
				U_FtGeraLog(cFilAnt, "", cRemessa, cMsg, "001", "", "000000")
			Else
				// captura dados detalhados da rotina automatica
				_aErroAuto := GetAutoGRLog()
				cMsg:= "ERRO - EXCLUSÃO REMESSA -Arquivo: "+cArquivo
				For _nCount := 1 To Len(_aErroAuto)
					cMsg += StrTran(StrTran(StrTran(_aErroAuto[_nCount],"<",""),"-",""),"   "," ") + (" ")
				Next _nCount
				cMsg+= " - TWMSA047 - execauto: TWMSA040"
				U_FtGeraLog(cFilAnt, "", "", cMsg, "001", "", "000000")
				Return{.F.,cMsg}
			EndIf		
		Else
			If lSepara
				cMsg:= "ERRO - EXCLUSÃO REMESSA - Remessa:"+cRemessa+" não pode ser excluída, existe separação realizada. Arquivo: "+cArquivo+" - TWMSA047(fImpCanc)"
			ElseIf lNF
				cMsg:= "ERRO - EXCLUSÃO REMESSA - Remessa:"+cRemessa+" não pode ser excluída, existe Nota Fiscal Lançada. Arquivo: "+cArquivo+" - TWMSA047(fImpCanc)"
			EnDIf
			U_FtGeraLog(cFilAnt, "001", "", cMsg, "001", "", "000000")
			Return{.F.,cMsg}		
		EndIf		
	Next
Return{.T.,""}


/*/{Protheus.doc} fAtuPed
Função para alimentar o número do pedido do cliente no Pedido de Vendas.
1- Na posição: 07 - ORG_SHIPPING_INS_NO, será enviado número do pedido TECADI.
2- A OS sequecia 001 será gerada como bloqueada e ao importar o arquivo irá desbloquear
3- Faz a conferência dos itens do pedido com os Itens x Itens do Arquivo.
Action Class 01.
@type function
@author Usuário
@since 31/07/2019
@version 1.0
@param aDados, array, (Linhas do arquivo de integração.)
@param cArquivo, character, (Nome do arquivo de integração.)
/*/
Static Function fAtuPed(aDados,cArquivo)

	LOCAL nIF_SEQ     := 01//IF_SEQ
	LOCAL nBRANCH_NO  := 02//BRANCH_NO
	LOCAL nACTION     := 03//EX_ACTION_CLASS
	LOCAL nFrom    	  := 04//SEND_FROM
	LOCAL nDestino    := 05//SEND_DESTINATION
	LOCAL nPedCli     := 06//SHIPPING_INS_NO
	LOCAL nPedAnt     := 07//ORG_SHIPPING_INS_NO //Convencionado que será o número do pedido TECADI (C5_NUM)
	LOCAL nActCl      := 08//ACTION_CLASS
	LOCAL nProd       := 09//FACTORY_PART_NO6
	LOCAL nCNPJEnt    := 12//CONSIGNEE_CD
	LOCAL nNomeEnt    := 13//CONSIGNEE_Name
	LOCAL nShiDt      := 14//SHIPPING_PLAN_DATE//C5_DTENT DATA DE ENTREGA *****
	LOCAL nQtde       := 15//SHIPPING_INS_CNT
	LOCAL cMsg        := ""
	LOCAL cChaveSA1   := ""
	LOCAL nFor,nFor1,nLin:= 0
	LOCAL cCodProd    := ""
	LOCAL cQuery      := ""
	LOCAL cPedCli     := ""
	LOCAL lOK         := .T. 
	LOCAL aConfere    := {}//[01]-Produto;[02]-Qtde.Pedido;[03]-Qtde.Arq;[04]-Diferença

	DBSelectArea("SA1")
	DBselectArea("SB1")
	DBSelectArea("SC5")
	DBSelectArea("Z06")
	Z06->(DBsetOrder(01))//Z06_FILIAL+Z06_NUMOS+Z06_SEQOS
	SB1->(DBSetOrder(01))//B1_FILIAL+B1_COD
	SA1->(DBSetOrder(01))//A1_FILIAL+A1_COD+A1_LOJA
	SC5->(DBSetOrder(01))//C5_FILIAL+C5_NUM

	For nFor:= 1 To Len(aDados)

		If AllTrim(aDados[nFor][nActCl]) == "C"//Exclusão/Cancelamento de Pedido
			cMsg:= "ERRO - PEDIDO VENDA - Integração não contempla Exclusão de Pedido de Vendas. "+AllTrim(aDados[nFor][nPedCli])+" - Arquivo: "+cArquivo+" - TWMSA047(fAtuPed)"
			Return {{.F.,cMsg,"",AllTrim(aDados[nFor][nPedCli])}}	
		EndIf

		//Localiza o cliente com base na filial de armazenagem.
		If Empty(cChaveSA1:= fEmpFil(AllTrim(aDados[nFor][nDestino])))
			cMsg:= "ERRO - PEDIDO VENDA - Filial não esperada na importação Código: "+aDados[nFor][nDestino]+" - Arquivo: "+cArquivo+" - TWMSA047(fAtuPed)"
			Return {{.F.,cMsg,"",AllTrim(aDados[nFor][nPedCli])}}
		EndIf

		If !(SA1->(MSSeek(xFilial("SA1")+cChaveSA1)))
			cMsg:= "ERRO - PEDIDO VENDA - Cliente não localizado para importação: "+cChaveSA1+" - Arquivo: "+cArquivo+" - TWMSA047(fAtuPed)"
			Return {{.F.,cMsg,"SA1",cChaveSA1}}
		EndIf	

		//Localiza pelo pedido de vendas. Será enviado no arquivo o pedido de vendas tecadi (C5_NUM).
		If !SC5->(MSSeek(xFilial("SC5")+AllTrim(aDados[nFor][nPedAnt]) ))
			cMsg:= "ERRO - PEDIDO VENDA - Pedido não localizado "+AllTrim(aDados[nFor][nPedAnt])+" - Arquivo: "+cArquivo+" - TWMSA047(fAtuPed)"
			Return {{.F.,cMsg,"SC5",AllTrim(aDados[nFor][nPedAnt])}}
		EndIf
		cPedCli := AllTrim(aDados[nFor][nPedCli])

		//Busca as quantidades do pedido para comparar com o arquivo.
		cQuery:= "SELECT C6_PRODUTO, SUM(C6_QTDVEN) AS QUANTIDADE "
		cQuery+= " FROM "+RetSQLName("SC6")
		cQuery+= " WHERE "
		cQuery+= " C6_FILIAL = '"+SC5->C5_FILIAL+"' "
		cQuery+= " AND C6_NUM  = '"+SC5->C5_NUM+"' "
		cQuery+= " AND D_E_L_E_T_ != '*' "
		cQuery+= " GROUP BY C6_PRODUTO "
		If Select("TRBSC6") <> 0 
			DBSelectArea("TRBSC6")
			DBCloseArea()
		EndIf
		DBUseArea(.T.,"TOPCONN",TCGenQry(NIL,NIL,cQuery),"TRBSC6",.F.,.T.)
		Do While !TRBSC6->(Eof())
			aAdd(aConfere,{TRBSC6->C6_PRODUTO,TRBSC6->QUANTIDADE,0})
			TRBSC6->(DBSkip())
		EndDo

		//Alimenta quantidade para conferência.
		For nFor1:= 1 To Len(aDados)
			cCodProd:= SA1->A1_SIGLA+AllTrim(aDados[nFor1][nProd])
			If !(SB1->(MSSeek(xFilial("SB1")+cCodProd)))
				cMsg:= "ERRO - PEDIDO VENDA - Produto do cliente não localizado: "+cCodProd+" Ped.Cli.: "+AllTrim(aDados[nFor][nPedCli])+" - Arquivo: "+cArquivo+" - TWMSA047(fAtuPed)"
				Return {{.F.,cMsg,"SC5",SC5->(C5_FILIAL+C5_NUM)  }}
			EndIf

			If (nItm:= AScan(aConfere, {|x| AllTrim(x[01])==AllTrim(cCodProd)} )) > 0
				aConfere[nItm][03] += Val(aDados[nFor1][nQtde])
			Else
				aAdd(aConfere,{cCodProd,0,Val(aDados[nFor1][nQtde])})
			EndIf
		Next
		nFor:= nFor1

		//Confere os itens divergentes para alimentar o Log.
		cMsg:= ""
		lOK:= .T.
		For nFor1:=1 To Len(aConfere)	
			If !Empty((aConfere[nFor1][02]-aConfere[nFor1][03]))
				If Empty(cMsg)
					cMsg := "ERRO - PEDIDO VENDA - Divergencia entre arquivo e pedido Pedido do cliente: "+cPedCli+" Produtos: "
				EndIf
				cMsg+= AllTrim(aConfere[nFor1][01])+" Ped. "+cValToChar(aConfere[nFor1][02])+" - Arq.: "+cValToChar(aConfere[nFor1][03])+Space(01)
				lOK := .F.
			EndIf
		Next
		cMsg+= " - Arquivo: "+cArquivo+" - TWMSA047(fAtuPed)"
		If !lOK
			Return {{.F.,cMsg,"SC5",SC5->(C5_FILIAL+C5_NUM)}}
		EndIf

		//Desbloqueia a OS Sequencia 001, a mesma na inclusão do pedido será criada como Bloqueada.
		If !Empty(SC5->C5_ZNOSSEP) .And. Z06->(MSSeek(xFilial("Z06")+SC5->C5_ZNOSSEP+"001"))
			//Desbloqueia a OS
			If (Z06->Z06_STATUS == "AN")
				U_FtWmsSta(Z06->Z06_STATUS, "AG", Z06->Z06_NUMOS, Z06->Z06_SEQOS)
			EndIf
		EndIf

		//Atualiza a Origem no pedido de vendas, para que seja retornado como Action Class 31 (TWMSA048).
		RecLock("SC5",.F.)	
		SC5->C5_ZORIGEM := "02"//Muda a origem do pedido para Improtado.
		SC5->C5_ZPEDCLI := cPedCli//Atualiza o número do pedido do cliente no Pedido de Vendas.
		MSUnLock()
		cMsg:= "SUCESSO - PEDIDO VENDAS - Pedido do cliente atualizado.: "+cPedCli+"  "
		cMsg+= " - Arquivo: "+cArquivo+" - TWMSA047(fAtuPed)"
		Return {{.T.,cMsg,"SC5",SC5->(C5_FILIAL+C5_NUM)}}
	Next

Return {{.F.,"ERRO","",""}}

/*/{Protheus.doc} fImpPed
Importação pedido de vendas
**31.07.2019 - Função descontinuada devido a alteração de regra de negócio.
@type function
@author Usuário
@since 08/05/2019
/*/
Static Function fImpPed(aCampos,aDados,cArquivo)

	LOCAL nFor        := 0
	LOCAL nFor1       := 0
	LOCAL cItem       := 0
	LOCAL _nQtdSolic  := 0
	LOCAL _nQuant     := 0 
	LOCAL _cTes       := ""
	LOCAL _aNotasEnt  := {}
	LOCAL _aLinha     := {} 
	LOCAL _aIteAuto   := {}
	LOCAL cCNPJCl     := ""
	LOCAL nVolumes    := 0 
	LOCAL cEspecie    := ""
	LOCAL nPosVol     := 0
	LOCAL aPedCli     :={}
	LOCAL nIF_SEQ     := 01//IF_SEQ
	LOCAL nBRANCH_NO  := 02//BRANCH_NO
	LOCAL nACTION     := 03//EX_ACTION_CLASS
	LOCAL nFrom    	  := 04//SEND_FROM
	LOCAL nDestino    := 05//SEND_DESTINATION
	LOCAL nPedCli     := 06//SHIPPING_INS_NO
	LOCAL nPedAnt     := 07//ORG_SHIPPING_INS_NO //Número do pedido anterior
	LOCAL nActCl      := 08//ACTION_CLASS
	LOCAL nProd       := 09//FACTORY_PART_NO6
	LOCAL nCNPJEnt    := 12//CONSIGNEE_CD
	LOCAL nNomeEnt    := 13//CONSIGNEE_Name
	LOCAL nShiDt      := 14//SHIPPING_PLAN_DATE//C5_DTENT DATA DE ENTREGA *****
	LOCAL nQtde       := 15//SHIPPING_INS_CNT
	LOCAL _aCabAuto   := {}
	LOCAL aRetorno    := {}//[01]lOK,[2]Mensagem[3]tabela,[4]Chave
	LOCAL nOpcPed     := 0//3- Inclusão/4- Alteração/5- Exclusão
	LOCAL cCliPed     := ""
	LOCAL cLojaPed    := ""
	LOCAL nSaldoPed   := 0
	PRIVATE lMsErroAuto := .F.

	If Len(aDados) >0 .And. Upper(AllTrim(aDados[01][nACTION])) <> "01"
		cMsg := "ERRO - PEDIDO VENDAS - Arquivo sem dados ou não se refere a importacao de Pedido de Vendas (Ação 01). - "+cArquivo+" - TWMSA047(fImpPed)"
		Return{{.F.,cMsg,"",""}}
	EndIf

	DBSelectArea("SA1")
	DBselectArea("SB1")
	DBSelectArea("SC5")
	SB1->(DBSetOrder(01))//B1_FILIAL+B1_COD
	SA1->(DBSetOrder(01))//A1_FILIAL+A1_COD+A1_LOJA

	For nFor:= 1 To Len(aDados)

		//Localiza o cliente com base na filial de armazenagem.
		If Empty(cChaveSA1:= fEmpFil(AllTrim(aDados[nFor][nDestino])))
			cMsg:= "ERRO - PEDIDO VENDA - Filial não esperada na importação Código: "+aDados[nFor][nDestino]+" - Arquivo: "+cArquivo+" - TWMSA047(fImpPed)"
			Return {{.F.,cMsg,"",AllTrim(aDados[nFor][nPedCli])}}
		EndIf	

		//Verifica o tipo de operação enviado no arquivo.
		Do Case
			Case AllTrim(aDados[nFor][nActCl]) == "A"//Inclusão de Pedido
			nOpcPed := 3 
			Case AllTrim(aDados[nFor][nActCl]) == "C"//Exclusão/Cancelamento de Pedido
			nOpcPed := 5 
		EndCase


		_aCabAuto := {}
		cItem     := ""
		nVolumes  := 0
		cEspecie  := ""
		_nQuant   := 0
		_cTes     := ""
		_aIteAuto := {}
		_aLinha   := {}		
		lOK       := .T.
		nSaldoPed := 0
		//Verifica se passou pelo pedido, para nao incluir pedido parcialmente.
		If (aScan(aPedCli,{ |x| ALLTRIM(x) == AllTrim(aDados[nFor][nPedCli])})) >0
			Loop
		Else
			AAdd(aPedCli, AllTrim(aDados[nFor][nPedCli]))
		EndIf

		//Inclusão de Pedido
		If nOpcPed == 3

			/*
			A regra é, quando vier a informação de um pedido anterior, o sistema deve excluir o pedido 
			informado e incluir um novo.
			*/
			If !Empty(aDados[nFor][nPedAnt])
				aRetorno:= aClone(fExclPed(aDados[nFor][nPedAnt]))
				If Len(aRetorno)>0 .And. !aRetorno[01][01]
					lOK:= .F.
					cMsg := aRetorno[01][02]
				EndIf 
			EndIf

			If lOK .And. !(SA1->(MSSeek(xFilial("SA1")+cChaveSA1)))
				lOK := .F.
				cMsg:= "ERRO - PEDIDO VENDA - Cliente não localizado para importação: "+cChaveSA1+" - Arquivo: "+cArquivo+" - TWMSA047(fImpPed)"
			EndIf

			SC5->(DbOrderNickName("SC50000001")) // C5_FILIAL+C5_ZPEDCLI
			If lOK .And. SC5->(MSSeek(xFilial("SC5")+AllTrim(aDados[nFor][nPedCli]) ))
				lOK := .F.
				cMsg:= "ERRO - PEDIDO VENDA - Pedido do cliente já está no sistema: "+AllTrim(aDados[nFor][nPedCli])+" - Arquivo: "+cArquivo+" - TWMSA047(fImpPed)"
			EndIf

			If lOK		
				_cMensPadr := U_FtWmsParam("WMS_PEDIDO_MENSAGEM_PADRAO_FORMULA", "C", _cMensPadr, .F., "", SA1->A1_COD, SA1->A1_LOJA, Nil, Nil)
				_cTpFrete := U_FtWmsParam("WMS_PEDIDO_TIPO_FRETE_PADRAO", "C", _cTpFrete, .F., "", SA1->A1_COD, SA1->A1_LOJA, Nil, Nil)// define o tipo de frete padrao para o cliente

				nVolumes:= 1
				_nCliVolum := U_FtWmsParam("WMS_PEDIDO_VOLUME_QUANTIDADE", "N", nVolumes, .F., "", SA1->A1_COD, SA1->A1_LOJA, Nil, Nil)
				_cCliCodEsp := U_FtWmsParam("WMS_PEDIDO_VOLUME_ESPECIE", "C", cEspecie, .F., "",SA1->A1_COD, SA1->A1_LOJA, Nil, Nil)
				_cCliEspec  := Tabela("CL",_cCliCodEsp)

				cCNPJCl := StrTran(AllTrim(aDados[nFor][nCNPJEnt]),"-","")
				cCNPJCl := StrTran(cCNPJCl,"/","")
				cCNPJCl := StrTran(cCNPJCl,".","")

				// dados do cabecalho do pedido de venda
				aadd(_aCabAuto,{"C5_TIPO"	,"N"                 , nil}) // Tipo do Pedido - N-Normal
				aadd(_aCabAuto,{"C5_CLIENTE",SA1->A1_COD         , nil}) // Cod. Cliente
				aadd(_aCabAuto,{"C5_LOJACLI",SA1->A1_LOJA        , nil}) // Loja
				aadd(_aCabAuto,{"C5_CLIENT"	,SA1->A1_COD         , nil}) // Cod. Cliente Ent
				aadd(_aCabAuto,{"C5_LOJAENT",SA1->A1_LOJA        , nil}) // Loja Ent
				aadd(_aCabAuto,{"C5_TIPOCLI",SA1->A1_TIPO        , nil}) // Tipo do Cliente
				aadd(_aCabAuto,{"C5_CONDPAG","001"               , nil}) // Condicao de Pagamento (padrao 001)
				aadd(_aCabAuto,{"C5_TIPOOPE","P"                 , nil}) // tipo da operacao: P-Produto / S-Servido
				aadd(_aCabAuto,{"C5_EMISSAO",Date()              , nil}) // data de emissao			

				aadd(_aCabAuto,{"C5_VOLUME1",IIF(Empty(_nCliVolum),0,_nCliVolum)           , nil}) //** volumes ??
				aadd(_aCabAuto,{"C5_ZCDESP1",IIf(Empty(_cCliCodEsp),"62",_cCliCodEsp)         , nil}) //** codigo da especie do volume ??
				aadd(_aCabAuto,{"C5_ESPECI1",IIf(Empty(_cCliCodEsp),"VOLUMES",_cCliEspec)           , nil}) //** descricao especie do volume ??

				aadd(_aCabAuto,{"C5_MENPAD"	,_cMensPadr          , nil}) // codigo da mensagem padrao
				aadd(_aCabAuto,{"C5_ZPEDCLI",AllTrim(aDados[nFor][nPedCli]) , nil}) // numero do pedido do cliente
				//aadd(_aCabAuto,{"C5_ZAGRUPA",(_TRBSC6)->C5_ZAGRUPA , nil}) //** Agrupadora **Ver se utiliza
				aadd(_aCabAuto,{"C5_TPFRETE",_cTpFrete           , nil}) // tipo de frete			
				aadd(_aCabAuto,{"C5_ZCGCENT",cCNPJCl ,nil}) // CGC do cliente de entrega
				aadd(_aCabAuto,{"C5_ZCLIENT",UPPER(AllTrim(aDados[nFor][nNomeEnt])) ,nil}) // Nome do cliente de entrega			
				aadd(_aCabAuto,{"C5_ZORIGEM","02" ,nil}) //Informa 02- registro oriundo de importação.		


			EndIf

			nPosVol := aScan(_aCabAuto,{|x| (AllTrim(x[1]) == "C5_VOLUME1") })
			cItem := StrZero(1,TamSx3("C6_ITEM")[1])

			//Varre os itens do pedido de vendas no arquivo
			For nFor1:= nFor to Len(aDados)

				If AllTrim(aDados[nFor][nPedCli]) <> AllTrim(aDados[nFor1][nPedCli])
					Exit
				EndIf 

				//Armazena o saldo para validar se todos os itens foram atendidos.
				nSaldoPed+= Val(aDados[nFor1][nQtde])

				If !lOK 
					Loop
				EndIf

				//Valida Código do Produto
				cCodProd:= SA1->A1_SIGLA+AllTrim(aDados[nFor1][nProd])
				If !(lOK:= SB1->(MSSeek(xFilial("SB1")+cCodProd)))
					cMsg:= "ERRO - PEDIDO VENDA - Produto do cliente não localizado: "+cCodProd+" Ped.Cli.: "+AllTrim(aDados[nFor][nPedCli])+" - Arquivo: "+cArquivo+" - TWMSA047(fImpPed)"
					nFor1++
					Exit
				EndIf

				_aNotasEnt := fBuscaNFE(SA1->A1_COD,SA1->A1_LOJA,SB1->B1_COD )
				// 1-B6_DOC
				// 2-B6_SERIE
				// 3-D1_ITEM
				// 4-(B6_SALDO - B6_QULIB)
				// 5-D1_VUNIT
				// 6-D1_TES
				// 7-C6_IDENTB6
				// 8-B6_PRODUTO
				// 9-D1_DESCRIC
				//10-local/armazem
				//11-D1_LOTECTL
				//12-D1_QUANT
				//13-D1_TOTAL
				//Caso nao retorne notas para algum item, não incluí o pedido de vendas.
				If Len(_aNotasEnt) == 0
					lOK := .F.
					cMsg:= "ERRO - PEDIDO VENDA - Saldo Insuficiente do produto: "+cCodProd+" Ped.Cli.: "+AllTrim(aDados[nFor][nPedCli])+" - Arquivo: "+cArquivo+" - TWMSA047(fImpPed)"
					Loop
				EndIf	
				_nQtdSolic := Val(aDados[nFor1][nQtde])

				For _nItNota := 1 To Len(_aNotasEnt)
					If (_aNotasEnt[_nItNota][4] <= 0)//Verifica se a NF tem saldo.
						Loop
					EndIf

					// verifica o cadastro de TES
					_cTes := Posicione("SF4", 1, xFilial("SF4") + _aNotasEnt[_nItNota][6], "F4_TESDV")
					If ( Posicione("SF4", 1, xFilial("SF4") + _cTes, "F4_MSBLQL") == "1" )
						// variavel de retorno
						lOK := .F.
						cMsg:= "ERRO - PEDIDO VENDA - TES Bloqueada para uso: "+SF4->F4_CODIGO+" Ped.Cli.: "+AllTrim(aDados[nFor][nPedCli])+"- Arquivo: "+cArquivo+" - TWMSA047(fImpPed)"			
						Loop
					EndIf		

					// se for igual ou menor que o saldo da nota
					If (_nQtdSolic <= _aNotasEnt[_nItNota][4])
						_nQuant := _nQtdSolic
					Else
						_nQuant := _aNotasEnt[_nItNota][4]
					EndIf		

					//Quando não informado o volume, insere a quantidade.
					If Empty(_nCliVolum)
						_aCabAuto[nPosVol][2] += _nQuant
					EndIf

					nSaldoPed-=_nQuant

					_aLinha := {}
					aadd(_aLinha,{"C6_ITEM"   , cItem             , Nil})
					aadd(_aLinha,{"C6_PRODUTO", _aNotasEnt[_nItNota][ 8], Nil})
					aadd(_aLinha,{"C6_DESCRI" , _aNotasEnt[_nItNota][ 9] , Nil})
					aadd(_aLinha,{"C6_QTDVEN" , _nQuant , Nil})
					aadd(_aLinha,{"C6_PRCVEN" , _aNotasEnt[_nItNota][5] , Nil})	

					// tratamento para arredondamento do valor total (conforme cada cliente) - devolucao total
					If (_nQuant == _aNotasEnt[_nItNota][12] )// quantidade total da nota de entrada
						aadd(_aLinha,{"C6_VALOR" , _aNotasEnt[_nItNota][13] , Nil})
					EndIf
					aadd(_aLinha,{"C6_TES"    , SF4->F4_CODIGO    , Nil})
					aadd(_aLinha,{"C6_NFORI"  , _aNotasEnt[_nItNota][ 1]  , Nil})
					aadd(_aLinha,{"C6_SERIORI", _aNotasEnt[_nItNota][ 2], Nil})
					aadd(_aLinha,{"C6_ITEMORI", _aNotasEnt[_nItNota][ 3], Nil})
					aadd(_aLinha,{"C6_IDENTB6", _aNotasEnt[_nItNota][ 7], Nil})
					aadd(_aLinha,{"C6_LOCAL"  , _aNotasEnt[_nItNota][10]  , Nil})
					//aadd(_aLinha,{"C6_LOTECTL", (_TRBSC6)->C6_LOTECTL, Nil})???? Controla Lote?
					aadd(_aLinha,{"C6_ZTPESTO", "000001"           , Nil})
					aadd(_aLinha,{"C6_PEDCLI" , AllTrim(aDados[nFor][nPedCli]), Nil})
					//				aadd(_aLinha,{"C6_ZQTDVOL", (_TRBSC6)->C6_ZQTDVOL, Nil})
					//				aadd(_aLinha,{"C6_ZQTDPLT", (_TRBSC6)->C6_ZQTDPLT, Nil})
					aadd(_aLinha,{"AUTDELETA" , "N"                , Nil})

					//controle da quantidade atendida
					_nQtdSolic -= _nQuant
					// diminui o saldo da nota
					_aNotasEnt[_nItNota][4] -= _nQuant
					cItem := SomaIt(cItem)
					// atualiza vetor da rotina automatica
					aadd(_aIteAuto,_aLinha)	

					// se o saldo da quantidade solicitada foi atendido
					If (_nQtdSolic==0)
						Exit
						// se nao tem saldo suficiente para atender a quandidade solicitada
					ElseIf (_nQtdSolic > 0) .and. (Len(_aNotasEnt) == _nItNota)
						lOK := .F.
						//cMsg += "Inconsistência: Item: "+_cItem+" - Saldo Insuficiente do produto: " + AllTrim(_cCodProd) + CRLF + CRLF
						cMsg:= "ERRO - PEDIDO VENDA - Saldo Insuficiente do produto: "+_aNotasEnt[_nItNota][ 8]+"  Ped.Cli.: "+AllTrim(aDados[nFor][nPedCli])+" - Arquivo: "+cArquivo+" - TWMSA047(fImpPed)"
						Exit
					EndIf

				Next//Next notas de entrada
			Next//Next Itens do pedido
			nFor := (nFor1-1)

			If lOK .And. nSaldoPed >0
				lOK := .F.
				cMsg:= "ERRO - PEDIDO VENDA - Não localizado saldo em estoque para atender o pedido total ou parcialmente. Arquivo: "+cArquivo		
			EndIf

			If lOK 
				lMsErroAuto := .F.
				lAutoErrNoFile := .T.

				// rotina automatica do pedido de venda
				MsExecAuto({|x,y,z| Mata410(x,y,z)},_aCabAuto,_aIteAuto,3) // 3-inclusao

				If !lMsErroAuto  // operacao se deu erro
					cMsg := "SUCESSO - PEDIDO VENDA - Incluído Pedido de vendas:"+SC5->C5_NUM+" na Filial "+SC5->C5_FILIAL
					cMsg += " - Arquivo: "+cArquivo
					cMsg+= " - TWMSA047 - execauto: Mata410"

					AAdd(aRetorno,{.T.,cMsg,"SC5",SC5->(C5_FILIAL+C5_NUM)})

					//Cria carga para o pedido.
					fCarga(3,SC5->C5_NUM,SA1->A1_COD,SA1->A1_LOJA)
				Else
					//mostraerro()
					_aErroAuto := GetAutoGRLog()
					cMsg:= "ERRO - PEDIDO VENDA -Arquivo: "+cArquivo
					For _nCount := 1 To Len(_aErroAuto)
						cMsg += StrTran(StrTran(StrTran(_aErroAuto[_nCount],"<",""),"-",""),"   "," ") + (" ")
					Next _nCount
					cMsg+= " - TWMSA047 - execauto: Mata410"
					// rollback na transacao
					//DisarmTransaction()
					AAdd(aRetorno,{.F.,cMsg,"",AllTrim(aDados[nFor][nPedCli])})		
				EndIf			
			Else
				AAdd(aRetorno,{lOK,cMsg,"",AllTrim(aDados[nFor][nPedCli])})
			EndIf
		EndIf//If inclusão


		//Exclui o pedido de vendas conforme instrução.
		If nOpcPed == 5 
			aRetorno:= aClone(fExclPed(aDados[nFor][nPedCli]))
		EndIf
	Next

Return aRetorno

/*/{Protheus.doc} fExclPed
Função para excluir o pedido de vendas.
@type function
@author Usuário
@since 05/06/2019
/*/
Static Function fExclPed(cPedCli)

	LOCAL aRetorno := {}

	LOCAL cNumPed     := ""
	LOCAL cCliPed     := ""
	LOCAL cLojaPed    := ""
	LOCAL lOK:= .T.

	DBSelectArea("Z06")
	Z06->(DBsetOrder(01))//Z06_FILIAL+Z06_NUMOS+Z06_SEQOS
	SC5->(DbOrderNickName("SC50000001")) // C5_FILIAL+C5_ZPEDCLI

	If !SC5->(MSSeek(xFilial("SC5")+AllTrim(cPedCli)))
		lOK := .F.
		cMsg:= "ERRO - EXCLUSAO PEDIDO VENDA - Pedido do cliente não localizado: "+AllTrim(cPedCli)+" - TWMSA047(fImpPed)"
	EndIf
	//C5_ZCARGA
	If !Empty(SC5->C5_ZNOSSEP) .Or. !Empty(SC5->C5_ZCARREG) .Or. !Empty(SC5->C5_NOTA)
		lOK := .F.
		cMsg:= "ERRO - EXCLUSAO PEDIDO VENDA - Existe OS, Carregamento ou Nota Gerada para o cliente. Pedido Cliente: "+AllTrim(cPedCli)+" - TWMSA047(fImpPed)"


		If !Empty(SC5->C5_ZNOSSEP) .And. Z06->(MSSeek(xFilial("Z06")+SC5->C5_ZNOSSEP))
			Do While !Z06->(Eof()).And. Z06->(Z06_FILIAL+Z06_NUMOS) == SC5->(C5_FILIAL+C5_ZNOSSEP)
				//Bloqueia a OS
				If !(Z06->Z06_STATUS $ "BL,FI")
					U_FtWmsSta(Z06->Z06_STATUS, "BL", Z06->Z06_NUMOS, Z06->Z06_SEQOS)
				EndIf
				Z06->(DBSkip())
			EndDo
		EndIf
	EndIf 


	//Exclusão da liberação do pedido
	If lOK .And. !u_FtEstLib(SC5->C5_NUM, .F.)
		lOK := .F.
		cMsg:= "ERRO - EXCLUSAO PEDIDO VENDA - Não foi possível excluir a liberação do pedido do cliente: "+AllTrim(cPedCli)+" - TWMSA047(fImpPed)"
	EndIf
	If lOK
		cNumPed:= SC5->C5_NUM
		cCliPed     := SC5->C5_CLIENTE
		cLojaPed    := SC5->C5_LOJACLI

		// dados do cabecalho do pedido de venda
		_aCabAuto:= {}
		_aIteAuto:= {}
		aadd(_aCabAuto,{"C5_FILIAL"	,SC5->C5_FILIAL                 , nil}) 
		aadd(_aCabAuto,{"C5_NUM"	,SC5->C5_NUM                 , nil}) 		
		aadd(_aCabAuto,{"C5_TIPO"	,SC5->C5_TIPO                 , nil}) 
		aadd(_aCabAuto,{"C5_CLIENTE",SC5->C5_CLIENTE         , nil}) 
		aadd(_aCabAuto,{"C5_LOJACLI",SC5->C5_LOJACLI        , nil}) 
		aadd(_aCabAuto,{"C5_CLIENT"	,SC5->C5_CLIENT         , nil}) 
		aadd(_aCabAuto,{"C5_LOJAENT",SC5->C5_LOJAENT        , nil}) 
		aadd(_aCabAuto,{"C5_TIPOCLI",SC5->C5_TIPOCLI        , nil}) 

		SC6->(DBSetOrder(01))//C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
		If SC6->(MSSeek(SC5->(C5_FILIAL+C5_NUM)))
			Do While !SC6->(Eof()).And.SC5->(C5_FILIAL+C5_NUM) == SC6->(C6_FILIAL+C6_NUM)

				_aLinha := {}
				aadd(_aLinha,{"C6_NUM"    , SC6->C6_NUM    , Nil})
				aadd(_aLinha,{"C6_ITEM"   , SC6->C6_ITEM   , Nil})
				aadd(_aLinha,{"C6_PRODUTO", SC6->C6_PRODUTO, Nil})
				aadd(_aLinha,{"C6_DESCRI" , SC6->C6_DESCRI , Nil})
				aadd(_aLinha,{"C6_QTDVEN" , SC6->C6_QTDVEN , Nil})
				aadd(_aLinha,{"C6_PRCVEN" , SC6->C6_QTDVEN , Nil})	
				aadd(_aLinha,{"C6_VALOR"  , SC6->C6_VALOR , Nil})
				aadd(_aIteAuto,_aLinha)			    
				SC6->(DBSkip())
			EndDo  		
		EndIf

		lMsErroAuto := .F.
		lAutoErrNoFile := .T.

		// rotina automatica do pedido de venda
		MsExecAuto({|x,y,z| Mata410(x,y,z)},_aCabAuto,_aIteAuto,5) // 5-Exclusão

		If !lMsErroAuto  //
			cMsg := "SUCESSO - EXCLUSAO PEDIDO VENDA - Excluído Pedido de vendas:"+cNumPed+" na Filial "+SC5->C5_FILIAL
			cMsg += " - Arquivo: "
			cMsg+= " - TWMSA047 - execauto: Mata410"

			AAdd(aRetorno,{.T.,cMsg,"",AllTrim(cPedCli)})
		Else
			_aErroAuto := GetAutoGRLog()
			cMsg:= "ERRO - EXCLUSAO PEDIDO VENDA - "
			For _nCount := 1 To Len(_aErroAuto)
				cMsg += StrTran(StrTran(StrTran(_aErroAuto[_nCount],"<",""),"-",""),"   "," ") + (" ")
			Next _nCount
			cMsg+= " - TWMSA047 - execauto: Mata410"
			// rollback na transacao
			//DisarmTransaction()
			AAdd(aRetorno,{.F.,cMsg,"SC5",SC5->(C5_FILIAL+C5_NUM)})
		EndIf
	Else
		AAdd(aRetorno,{.F.,cMsg,"",AllTrim(cPedCli)})		
	EndIf

Return aRetorno

/*/{Protheus.doc} fBuscaNFE
Busca as Notas Fiscais de entrada para devolução.
@type function
@author Luiz Fernando
@since 08/05/2019
/*/
Static Function fBuscaNFE(_cCodCli,_cLojaCli,cProduto )

	LOCAL _cQuery   := ""
	LOCAL mvNotasEnt:= {}
	LOCAL cCdProdRel := ""

	//Busca por produtos relacionados.
	_cQuery := " SELECT A7_PRODUTO "
	_cQuery += " FROM "+RetSqlTab("SA7")
	_cQuery += " WHERE "+RetSqlCond("SA7")
	_cQuery += " AND A7_CLIENTE = '"+_cCodCli+"' AND A7_LOJA = '"+_cLojaCli+"' "
	_cQuery += " AND A7_CODCLI = '"+cProduto+"' "
	// executa a query
	cCdProdRel := U_FtQuery(_cQuery)

	//Busca pelas Notas de Entrada
	_cQuery := "SELECT B6_DOC, B6_SERIE, D1_ITEM, "
	_cQuery += "(B6_SALDO - B6_QULIB "
	_cQuery += " - Isnull((SELECT Sum(C0_QUANT) FROM " +RetSqlTab("SC0")+ " WHERE SB6.B6_IDENT = C0_ZIDENT AND SB6.B6_DOC = C0_ZNOTA AND SB6.B6_SERIE = C0_ZSERIE AND "+RetSqlCond("SC0")+"),0) "
	_cQuery += " - Isnull((SELECT Sum(DA_SALDO) FROM " +RetSqlTab("SDA")+ " WHERE SB6.B6_IDENT = DA_NUMSEQ AND SB6.B6_DOC = DA_DOC AND SB6.B6_SERIE = DA_SERIE AND "+RetSqlCond("SDA")+"),0)) B6_SALDO,   "
	_cQuery += "D1_VUNIT, D1_TES, B6_IDENT, B6_PRODUTO, D1_DESCRIC, B6_LOCAL, D1_LOTECTL, D1_QUANT, D1_TOTAL "
	// saldo poder de terceiros
	_cQuery += "FROM "+RetSqlName("SB6")+" SB6 "
	// dados dos itens das notas de entrada
	_cQuery += "INNER JOIN "+RetSqlName("SD1")+" SD1 ON D1_FILIAL = B6_FILIAL AND SD1.D_E_L_E_T_ = ' ' "
	_cQuery += "      AND D1_DOC = B6_DOC AND D1_SERIE = B6_SERIE AND D1_FORNECE = B6_CLIFOR AND D1_LOJA = B6_LOJA "
	_cQuery += "      AND D1_COD = B6_PRODUTO AND D1_IDENTB6 = B6_IDENT "
	_cQuery += "      AND D1_TIPO = 'B' "
	// filtro do poder de terceiros
	_cQuery += "WHERE B6_FILIAL = '"+xFilial("SB6")+"' AND SB6.D_E_L_E_T_ = ' ' "
	_cQuery += "AND B6_CLIFOR = '"+_cCodCli+"' AND B6_LOJA = '"+_cLojaCli+"' "
	_cQuery += "AND ("
	_cQuery += "     B6_PRODUTO = '"+cProduto+"' "
	If ( ! Empty(cCdProdRel))
		_cQuery += " OR B6_PRODUTO = '"+cCdProdRel+"' "
	EndIf
	_cQuery += ") "
	// tipo (Cliente ou Fornecedor)
	_cQuery += "AND B6_TPCF = 'C' "
	// poder de 3o - REMESSA
	_cQuery += "AND B6_PODER3 = 'R' "
	// somente com saldo
	_cQuery += "AND (B6_SALDO - B6_QULIB - Isnull((SELECT Sum(C0_QUANT) FROM " +RetSqlName("SC0")+ " SC0 WHERE SB6.B6_IDENT = C0_ZIDENT AND SB6.B6_DOC = C0_ZNOTA AND SB6.B6_SERIE = C0_ZSERIE AND "+RetSqlCond("SC0")+"),0)) > 0 "

	// ordem por data de digitacao de documentos
	_cQuery += "ORDER BY B6_DTDIGIT, B6_SERIE, B6_DOC "

	MemoWrit("c:\query\tfata001_sfVldNfEnt.txt", _cQuery)

	// converte resultado para ARRAY
	mvNotasEnt := U_SqlToVet(_cQuery)

	// estrutura do vetor _aNotasEnt
	// 1-B6_DOC
	// 2-B6_SERIE
	// 3-D1_ITEM
	// 4-(B6_SALDO - B6_QULIB)
	// 5-D1_VUNIT
	// 6-D1_TES
	// 7-C6_IDENTB6
	// 8-B6_PRODUTO
	// 9-D1_DESCRIC
	//10-local/armazem
	//11-D1_LOTECTL
	//12-D1_QUANT
	//13-D1_TOTAL

Return mvNotasEnt

/*/{Protheus.doc} fImpBlDes
Importação para Desbloqueio de despacho.
@type function
@author Luiz Fernando
@since 15/05/2019
/*/
Static Function fImpBlDes(aDados,cArquivo)


	LOCAL nIF_SEQ     := 01//IF_SEQ
	LOCAL nBRANCH_NO  := 02//BRANCH_NO
	LOCAL nACTION     := 03//EX_ACTION_CLASS
	LOCAL nFrom    	  := 04//SEND_FROM
	LOCAL nDestino    := 05//SEND_DESTINATION
	LOCAL nPedCli     := 06//SHIPPING_INS_NO
	LOCAL nFor        := 0
	LOCAL aRet        := {}//[1]lOK[2]Mensagen,[3]Tabela,[4]Chave

	If Len(aDados) >0 .And. Upper(AllTrim(aDados[01][nACTION])) <> "05"
		cMsg := "ERRO - DESBLOQUEIO DESPACHO - Arquivo sem dados ou não se refere a importacao de Pedido de Vendas (Ação 05). - "+cArquivo+" - TWMSA047(fImpBlDes)"
		Return{{.F.,cMsg,""}}
	EndIf

	DBSelectArea("SC5")
	DBSelectArea("Z06")
	Z06->(DBsetOrder(01))//Z06_FILIAL+Z06_NUMOS+Z06_SEQOS
	SC5->(DbOrderNickName("SC50000001")) // C5_FILIAL+C5_ZPEDCLI

	If Z06->(FieldPos("Z06_STATAN")) == 0
		cMsg := "ERRO - DESBLOQUEIO DESPACHO - Campo Z06_STATAN faltante na base de dados. - "+cArquivo+" - TWMSA047(fImpBlDes)"
		Return{{.F.,cMsg,"",""}}	
	EndIf

	For nFor:=1 To Len(aDados)
		//Localiza o cliente com base na filial de armazenagem.
		If Empty(cChaveSA1:= fEmpFil(AllTrim(aDados[nFor][nDestino])))
			cMsg:= "ERRO - DESBLOQUEIO DESPACHO - Filial não esperada na importação Código: "+aDados[nFor][nDestino]+" - Arquivo: "+cArquivo+" - TWMSA047 - fImpBlDes"
			Return{{.F.,cMsg,"",AllTrim(aDados[nFor][nPedCli])}}
		EndIf

		//Localiza pedido pelo número do pedido cliente
		If !SC5->(MSSeek(xFilial("SC5")+AllTrim(aDados[nFor][nPedCli]) ))
			cMsg:= "ERRO - DESBLOQUEIO DESPACHO - Pedido do cliente não localizado: "+AllTrim(aDados[nFor][nPedCli])+" - Arquivo: "+cArquivo+" - TWMSA047(fImpBlDes)"
			aAdd(aRet,{.F.,cMsg,"001",AllTrim(aDados[nFor][nPedCli])})
		Else	
			//Regra para Desbloqueio, sempre busca a sequencia "003", que equivale ao carregamento. 
			//Neste momento a OS deve ter bloqueio (Z06_STATUS == "BL"). A rotian fará o desbloqueio da OS para permitir o carregamento.
			If !Empty(SC5->C5_ZNOSSEP)//.And. Empty(SC5->C5_ZCARREG)
				If Z06->(MSSeek(xFilial("Z06")+SC5->C5_ZNOSSEP+"003"))
					Do While !Z06->(Eof()).And. Z06->(Z06_FILIAL+Z06_NUMOS) == SC5->(C5_FILIAL+C5_ZNOSSEP)
						//Bloqueia a OS
						If Z06->Z06_STATUS == "BL"
							If U_FtWmsSta(Z06->Z06_STATUS, "AG", Z06->Z06_NUMOS, Z06->Z06_SEQOS)
								cMsg:="SUCESSO - DESBLOQUEIO DESPACHO - Pedido do cliente "+AllTrim(aDados[nFor][nPedCli])+" OS: "+Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)+" - Arquivo: "+cArquivo+" - TWMSA047(fImpBlDes)"
								aAdd(aRet,{.T.,cMsg,"Z06",Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)})
							Else
								cMsg:="ERRO - DESBLOQUEIO DESPACHO - Não foi possível desbloquear a OS. Pedido do cliente "+AllTrim(aDados[nFor][nPedCli])+" OS: "+Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)+" - Status atual: "+Z06->Z06_STATUS+" - Arquivo: "+cArquivo+" - TWMSA047(fImpBlDes)"
								aAdd(aRet,{.F.,cMsg,"Z06",Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)})				    
							EndIf
						Else	  	
							cMsg:="ERRO - DESBLOQUEIO DESPACHO - Não foi possível desbloquear a OS. Pedido do cliente "+AllTrim(aDados[nFor][nPedCli])+" OS: "+Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)+" - Status atual: "+Z06->Z06_STATUS+" - Arquivo: "+cArquivo+" - TWMSA047(fImpBlDes)"
							aAdd(aRet,{.F.,cMsg,"Z06",Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)})				    
						EndIf
						Z06->(DBSkip())
					EndDo
				Else
					cMsg:="ERRO - DESBLOQUEIO DESPACHO - Não localizado OS para o Pedido do cliente "+AllTrim(aDados[nFor][nPedCli])+" OS: "+Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)+" - Arquivo: "+cArquivo+" - TWMSA047(fImpBlDes)"
					aAdd(aRet,{.F.,cMsg,"Z06",Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)})	  				
				EndIf
			Else
				cMsg:= "ERRO - DESBLOQUEIO DESPACHO - Não localizado OS relacionada ao pedido de vendas - Pedido Cliente "+AllTrim(aDados[nFor][nPedCli])+" - Arquivo: "+cArquivo+" - TWMSA047(fImpBlDes)"
				aAdd(aRet,{.F.,cMsg,"001",AllTrim(aDados[nFor][nPedCli])})
			EndIf
		EndIf
	Next

Return aRet

/*/{Protheus.doc} fBlqEst
Função que faz o bloqueio de estoque.
@type function
@author Usuário
@since 16/05/2019
/*/
Static function fBlqEst(aDados,cArquivo)

	LOCAL cCodBlq     := GetNewPar("TC_SUMCDBL","000007")
	LOCAl cCodLib     := GetNewPar("TC_SUMCDLB","000001")
	LOCAL nFor        := 0
	LOCAL nIF_SEQ     := 01//IF_SEQ
	LOCAL nBRANCH_NO  := 02//BRANCH_NO
	LOCAL nACTION     := 03//EX_ACTION_CLASS
	LOCAL nFrom    	  := 04//SEND_FROM
	LOCAL nDestino    := 05//SEND_DESTINATION" })
	LOCAL nTire       := 06//TIRE_BC
	LOCAL nStatus     := 12//STATUS
	LOCAL nProduto    := 14//FACTORY_PART_NO6
	LOCAL _aCabAuto   := {}
	LOCAL cStatus     := ""//10-Estoque Normal;54-Parar Despacho
	LOCAL aRetorno    := {}//[01]lOK,[2]Mensagem[3]tabela,[4]Chave
	LOCAL cCodPro     := ""
	LOCAL lOK         := .T.
	LOCAL cQuery      := ""
	LOCAL nQtde       := 0
	LOCAL aMail       := {}//Informações do log para envio via e-mail.

	DBSelectArea("SA1")
	DBSelectArea("Z56")
	DBSelectArea("SB1")
	DBSelectArea("Z16")
	Z16->(DBSetOrder(02))//Z16_FILIAL+Z16_ETQPRD
	SB1->(DBSetOrder(01))//B1_FILIAL+B1_COD
	Z56->(DBSetOrder(02))//Z56_FILIAL+Z56_ETQCLI+Z56_CODCLI+Z56_LOJCLI
	SA1->(DBSetOrder(01))//A1_FILIAL+A1_COD+A1_LOJA

	For nFor:= 1 To Len(aDados)

		//Localiza o cliente com base na filial de armazenagem.
		If Empty(cChaveSA1:= fEmpFil(AllTrim(aDados[nFor][nDestino])))
			cMsg:= "ERRO - Filial não esperada na importação Código: "+aDados[nFor][nDestino]+" - Arquivo: "+cArquivo+" - TWMSA047"
			Return{{.F.,cMsg,"",AllTrim(aDados[nFor][nTire])} }  
		EndIf

		lOK:= .T.

		If lOK .And. !(SA1->(MSSeek(xFilial("SA1")+cChaveSA1)))
			cMsg:= "ERRO - BLOQUEIO PRODUTO - Cliente não esperado na importação Código: "+cChaveSA1+" - Arquivo: "+cArquivo+" - TWMSA047 - fBlqEst"
			aAdd(aRetorno,{.F.,cMsg,"001",""})
			Return aRetorno
		EndIf

		cCodPro:= PadR((AllTrim(SA1->A1_SIGLA)+AllTrim(aDados[nFor][nProduto])), TamSx3("B1_COD")[1])
		If !SB1->(MSSeek(xFilial("SB1")+cCodPro))
			cMsg:= "ERRO - BLOQUEIO PRODUTO - Filial não esperada na importação Código: "+cChaveSA1+" - Arquivo: "+cArquivo+" - TWMSA047 - fBlqEst"
			lOK := .F.
		EndIf		

		cStatus:= AllTrim(AllTrim(aDados[nFor][nStatus]))//Ação enviada no arquivo:10-Estoque Normal;54-Parar Despacho		
		cEtqCli := PadR(AllTrim(aDados[nFor][nTire]),TamSX3("Z56_ETQCLI")[01])

		//Localiza a etiqueta do produto.
		If lOk .And. Z56->(MSSeek(xFilial("Z56")+cEtqCli+SA1->(A1_COD+A1_LOJA)))
			//Z56->Z56_ETQCLI
			//Z56_CODETI //Etiqueta Tecadi
			/*
			Alteração conceitual, antes bloqueava todo o endereço da SBE.
			Agora, bloqueia a etiqueta na Z16, conforme campo: Z16_TPESTO.  
			24.07.2019 - Luiz Fernando
			*/
			If Z16->(MSSeek(Z56->(Z56_FILIAL+Z56_CODETI)))		 
				If Z16->Z16_SALDO >0
					Do Case 
						Case cStatus == "10" //Muda para Estoque Normal
						If Z16->Z16_TPESTO <> cCodLib
							RecLock("Z16",.F.)
							Z16->Z16_TPESTO := cCodLib//Desbloqueia o Produto.
							MSUnlock()
							cMsg:= "SUCESSO - BLOQUEIO PRODUTO - DESBLOQUEADO - endereço("+Z16->Z16_ENDATU+") do produto, Etiqueta do Cliente: "+AllTrim(aDados[nFor][nTire])+" - Arquivo: "+cArquivo+" - TWMSA047 - fBlqEst"
							aAdd(aMail,{AllTrim(aDados[nFor][nTire]),"SUCESSO","DESBLOQUEADO endereço("+Z16->Z16_ENDATU+")" })
							aAdd(aRetorno,{.T.,cMsg,"Z16",Z16->(Z16_FILIAL+Z16_ETQPRD)})
						Else
							cMsg:= "SUCESSO - BLOQUEIO PRODUTO - DESBLOQUEADO - Anteriormente endereço("+Z16->Z16_ENDATU+") do produto, Etiqueta do Cliente: "+AllTrim(aDados[nFor][nTire])+" - Arquivo: "+cArquivo+" - TWMSA047 - fBlqEst"
							aAdd(aMail,{AllTrim(aDados[nFor][nTire]),"SUCESSO","DESBLOQUEADO Anteriormente endereço("+Z16->Z16_ENDATU+")" })
							aAdd(aRetorno,{.T.,cMsg,"Z16",Z16->(Z16_FILIAL+Z16_ETQPRD)})							   
						EndIf			   						   	    
						Case cStatus == "54" //Parar Despacho
						If Z16->Z16_TPESTO <> cCodBlq
							RecLock("Z16",.F.)
							Z16->Z16_TPESTO := cCodBlq//Bloqueia o Produto.
							MSUnlock()
							cMsg:= "SUCESSO - BLOQUEIO PRODUTO - BLOQUEADO - endereço("+Z16->Z16_ENDATU+") do produto, Etiqueta do Cliente: "+AllTrim(aDados[nFor][nTire])+" - Arquivo: "+cArquivo+" - TWMSA047 - fBlqEst"
							aAdd(aMail,{AllTrim(aDados[nFor][nTire]),"SUCESSO","BLOQUEADO endereço("+Z16->Z16_ENDATU+")" })
							aAdd(aRetorno,{.T.,cMsg,"Z16",Z16->(Z16_FILIAL+Z16_ETQPRD)})	
						Else //Produto Bloqueado.
							cMsg:= "SUCESSO - BLOQUEIO PRODUTO - BLOQUEADO - Anteriormente endereço("+Z16->Z16_ENDATU+") do produto, Etiqueta do Cliente: "+AllTrim(aDados[nFor][nTire])+" - Arquivo: "+cArquivo+" - TWMSA047 - fBlqEst"
							aAdd(aMail,{AllTrim(aDados[nFor][nTire]),"SUCESSO","BLOQUEADO anteriormente endereço("+Z16->Z16_ENDATU+")" })
							aAdd(aRetorno,{.T.,cMsg,"Z16",Z16->(Z16_FILIAL+Z16_ETQPRD)})								 
						EndIf					   	
						OtherWise
						cMsg:= "ERRO - BLOQUEIO PRODUTO - Não foi possível Bloquear/Desbloquear produto, Etiqueta do Cliente: "+AllTrim(aDados[nFor][nTire])+" - Arquivo: "+cArquivo+" - TWMSA047 - fBlqEst"
						aAdd(aMail,{AllTrim(aDados[nFor][nTire]),"ERRO","Não foi possível Bloquear/Desbloquear barcode produto" })
						lOK := .F.	
						aAdd(aRetorno,{.F.,cMsg,"Z16",Z16->(Z16_FILIAL+Z16_ETQPRD)})						
					EndCase
				Else
					cMsg:= "ERRO - BLOQUEIO PRODUTO - Produto sem Saldo: "+AllTrim(aDados[nFor][nTire])+" - Arquivo: "+cArquivo+" - TWMSA047 - fBlqEst"
					lOK := .F.	
					aAdd(aMail,{AllTrim(aDados[nFor][nTire]),"ERRO","Produto sem Saldo." })
					aAdd(aRetorno,{.F.,cMsg,"Z16",Z56->(Z56_FILIAL+Z56_CODETI)})			   		   			    		  
				EndIf
			Else
				cMsg:= "ERRO - BLOQUEIO PRODUTO - Produto não localizado na Composição do Lote: "+AllTrim(aDados[nFor][nTire])+" - Arquivo: "+cArquivo+" - TWMSA047 - fBlqEst"
				lOK := .F.	
				aAdd(aMail,{AllTrim(aDados[nFor][nTire]),"ERRO","Produto não localizado na Composição do Pallet." })
				aAdd(aRetorno,{.F.,cMsg,"Z16",Z56->(Z56_FILIAL+Z56_CODETI)})			   		   			    
			EndIf
		Else		
			cMsg:= "ERRO - BLOQUEIO PRODUTO - Etiqueta do cliente não localizada no sistema: "+AllTrim(aDados[nFor][nTire])+" - Arquivo: "+cArquivo+" - TWMSA047 - fBlqEst"
			aAdd(aMail,{AllTrim(aDados[nFor][nTire]),"ERRO","Barcode não localizado." })
			aAdd(aRetorno,{.F.,cMsg,"",AllTrim(aDados[nFor][nTire])})			   		   			    	
		EndIf			
	Next

	//Envia e-mail com a relação do log.
	If Len(aMail)>0
		fEnvMail(aMail,cArquivo)
	EndIf

Return aRetorno


/*/{Protheus.doc} fMovBack
Importação do desbloqueio da OS, para arquivos de pedidos manual.
@type function
@author Luiz Fernando
@since 18/07/2019
/*/
Static Function fMovBack(aDados,cArquivo)

	LOCAL nFor        := 0
	LOCAL nIF_SEQ     := 01//IF_SEQ
	LOCAL nBRANCH_NO  := 02//BRANCH_NO
	LOCAL nACTION     := 03//EX_ACTION_CLASS
	LOCAL nFrom    	  := 04//SEND_FROM
	LOCAL nDestino    := 05//SEND_DESTINATION" })
	LOCAL nTire       := 06//TIRE_BC
	LOCAL nStrWeek    := 07//STORE_YEAR_WEEK
	LOCAL nTicket     := 09//TICKET_NO
	LOCAL nPedCli     := 10//SHIPPING_INS_NO
	LOCAL nStatus     := 12//STATUS
	LOCAL nFack4      := 13//FACTORY_PART_NO4
	LOCAL nProduto    := 14//FACTORY_PART_NO6
	LOCAL cStatus     := ""
	LOCAL aRetorno    := {}//[01]lOK,[2]Mensagem[3]tabela,[4]Chave
	LOCAL lOK         := .T.

	DBSelectArea("SC5")
	DBSelectArea("Z06")
	Z06->(DBsetOrder(01))//Z06_FILIAL+Z06_NUMOS+Z06_SEQOS
	SC5->(DbOrderNickName("SC50000001")) // C5_FILIAL+C5_ZPEDCLI

	For nFor:=1 To Len(aDados)

		//Localiza o cliente com base na filial de armazenagem.
		If Empty(cChaveSA1:= fEmpFil(AllTrim(aDados[nFor][nDestino])))
			cMsg:= "ERRO - DESBLOQUEIO DESPACHO - Filial não esperada na importação Código: "+aDados[nFor][nDestino]+" - Arquivo: "+cArquivo+" - TWMSA047 - fMovBack"
			Return{{.F.,cMsg,"",AllTrim(aDados[nFor][nPedCli])}}
		EndIf		 

		//Localiza pedido pelo número do pedido cliente
		If !SC5->(MSSeek(xFilial("SC5")+AllTrim(aDados[nFor][nPedCli]) ))
			cMsg:= "ERRO - DESBLOQUEIO DESPACHO - Pedido do cliente não localizado: "+AllTrim(aDados[nFor][nPedCli])+" - Arquivo: "+cArquivo+" - TWMSA047(fMovBack)"
			aAdd(aRetorno,{.F.,cMsg,"SC5",AllTrim(aDados[nFor][nPedCli])})
		Else	
			//Regra para Desbloqueio, sempre busca a sequencia "003", que equivale ao carregamento. 
			//Neste momento a OS deve ter bloqueio (Z06_STATUS == "BL"). A rotian fará o desbloqueio da OS para permitir o carregamento.
			If !Empty(SC5->C5_ZNOSSEP)
				If Z06->(MSSeek(xFilial("Z06")+SC5->C5_ZNOSSEP+"003"))
					Do While !Z06->(Eof()).And. Z06->(Z06_FILIAL+Z06_NUMOS) == SC5->(C5_FILIAL+C5_ZNOSSEP)
						//Bloqueia a OS
						If Z06->Z06_STATUS == "BL"
							If U_FtWmsSta(Z06->Z06_STATUS, "AG", Z06->Z06_NUMOS, Z06->Z06_SEQOS)
								cMsg:="SUCESSO - DESBLOQUEIO DESPACHO - Pedido do cliente "+AllTrim(aDados[nFor][nPedCli])+" OS: "+Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)+" - Arquivo: "+cArquivo+" - TWMSA047(fMovBack)"
								aAdd(aRetorno,{.T.,cMsg,"Z06",Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)})
							Else
								cMsg:="ERRO - DESBLOQUEIO DESPACHO - Não foi possível desbloquear a OS. Pedido do cliente "+AllTrim(aDados[nFor][nPedCli])+" OS: "+Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)+" - Status atual: "+Z06->Z06_STATUS+" - Arquivo: "+cArquivo+" - TWMSA047(fMovBack)"
								aAdd(aRetorno,{.F.,cMsg,"Z06",Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)})				    
							EndIf
						Else	  	
							cMsg:="ERRO - DESBLOQUEIO DESPACHO - Não foi possível desbloquear a OS. Pedido do cliente "+AllTrim(aDados[nFor][nPedCli])+" OS: "+Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)+" - Status atual: "+Z06->Z06_STATUS+" - Arquivo: "+cArquivo+" - TWMSA047(fMovBack)"
							aAdd(aRetorno,{.F.,cMsg,"Z06",Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)})				    
						EndIf
						Z06->(DBSkip())
					EndDo
				Else
					cMsg:="ERRO - DESBLOQUEIO DESPACHO - Não localizado OS para o Pedido do cliente "+AllTrim(aDados[nFor][nPedCli])+" OS: "+Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)+" - Arquivo: "+cArquivo+" - TWMSA047(fMovBack)"
					aAdd(aRetorno,{.F.,cMsg,"Z06",Z06->(Z06_FILIAL+Z06_NUMOS+Z06_SEQOS)})	  				
				EndIf
			Else
				cMsg:= "ERRO - DESBLOQUEIO DESPACHO - Não localizado OS relacionada ao pedido de vendas - Pedido Cliente "+AllTrim(aDados[nFor][nPedCli])+" - Arquivo: "+cArquivo+" - TWMSA047(fMovBack)"
				aAdd(aRetorno,{.F.,cMsg,"SC5",AllTrim(aDados[nFor][nPedCli])})
			EndIf
		EndIf
		nFor:= Len(aDados)
	Next

Return aRetorno

/*/{Protheus.doc} fCarga
Função auxiliar para inclusão/exclusão de carga, relacionada ao pedido de vendas.
@type function
@author Usuário
@since 04/06/2019
/*/
Static Function fCarga(nAcao,cPedido,cCliente,cLoja)

	LOCAL aCab          := {}
	LOCAL aItem         := {}
	PRIVATE lMsHelpAuto := .T. //Variavel de controle interno do ExecAuto
	PRIVATE lMsErroAuto := .F. //Variavel que informa a ocorrência de erros no ExecAuto
	PRIVATE lAutoErrNoFile := .T.
	DBSelectArea("SA1")
	SA1->(DbSetOrder(01))

	// Posiciona no cliente do primeiro pedido
	If SA1->(DbSeek(xFilial("SA1")+cCliente+cLoja))

		If nAcao == 3//Inclusão

			aCab := {;   
			{"DAK_FILIAL", xFilial("DAK"),             Nil},;
			{"DAK_COD"   , GETSX8NUM("DAK","DAK_COD"), Nil},; //Campo com inicializador padrão para pegar GESX8NUM
			{"DAK_SEQCAR", "01",                       Nil},;
			{"DAK_ROTEIR", "999999",                   Nil},;
			{"DAK_CAMINH", "",                         Nil},;
			{"DAK_MOTORI", "",                         Nil},;
			{"DAK_PESO"  , 0,                          Nil},; // Calculado pelo OMSA200
			{"DAK_DATA"  , DATE(),                     Nil},;
			{"DAK_HORA"  , TIME(),                     Nil},;
			{"DAK_JUNTOU", "Manual",                   Nil},;
			{"DAK_ACECAR", "2",                        Nil},;
			{"DAK_ACEVAS", "2",                        Nil},;
			{"DAK_ACEFIN", "2",                        Nil},;
			{"DAK_FLGUNI", "2",                        Nil},; //Campo com inicializador padrão  - 2
			{"DAK_TRANSP", "",                         Nil};
			}

			Aadd(aItem, {;
			aCab[2,2],; // 01 - Código da carga
			"999999" ,; // 02 - Código da Rota - 999999 (Genérica)
			"999999" ,; // 03 - Código da Zona - 999999 (Genérica)
			"999999" ,; // 04-  Código do Setor - 999999 (Genérico)
			cPedido   ,; // 05 - Código do Pedido Venda
			SA1->A1_COD   ,; // 06 - Código do Cliente
			SA1->A1_LOJA  ,; // 07 - Loja do Cliente
			SA1->A1_NOME  ,; // 08 - Nome do Cliente
			SA1->A1_BAIRRO,; // 09 - Bairro do Cliente
			SA1->A1_MUN   ,; // 10 - Município do Cliente
			SA1->A1_EST   ,; // 11 - Estado do Cliente
			SC5->C5_FILIAL,; // 12 - Filial do Pedido Venda
			SA1->A1_FILIAL,; // 13 - Filial do Cliente
			0             ,; // 14 - Peso Total dos Itens
			0             ,; // 15 - Volume Total dos Itens
			"08:00"       ,; // 16 - Hora Chegada
			"0001:00"     ,; // 17 - Time Service
			Nil           ,; // 18 - Não Usado
			Date()     ,; // 19 - Data Chegada
			Date()     ,; // 20 - Data Saída
			Nil           ,; // 21 - Não Usado
			Nil           ,; // 22 - Não Usado
			0             ,; // 23 - Valor do Frete
			0             ,; // 24- Frete Autonomo
			0             ,; // 25 - Valor Total dos Itens
			0             }) // 26 - Quantidade Total dos Itens

			MSExecAuto( { |x, y, z| OMSA200(x, y, z) }, aCab, aItem, 3 )

			If lMsErroAuto
				cMsg:= "ERRO - Incluir carga para o pedido: "+cPedido
				For _nCount := 1 To Len(_aErroAuto)
					cMsg += StrTran(StrTran(StrTran(_aErroAuto[_nCount],"<",""),"-",""),"   "," ") + (" ")
				Next _nCount
				cMsg+= " - TWMSA047 - execauto: OMSA200"	

				U_FtGeraLog(cFilAnt, "", "", cMsg, "001", "", "000000")	
				DisarmTransaction()
			EndIf      

		ElseIf nAcao == 5//Exclusão

			DBSelectArea("DAI")
			DBSelectArea("DAK")
			DAK->(DBSetOrder(01))//DAK_FILIAL+DAK_COD+DAK_SEQCAR                                                                                                                                   
			DAI->(DBSetOrder(04))//DAI_FILIAL+DAI_PEDIDO+DAI_COD+DAI_SEQCAR
			If DAI->(MSSeek(xFilial("DAI")+cPedido))
				If DAK->(MSSeek(DAI->(DAI_FILIAL+DAI_COD+DAI_SEQCAR)))

					aCab := {;   
					{"DAK_FILIAL", DAK->DAK_FILIAL,             Nil},;
					{"DAK_COD"   , DAK->DAK_COD, Nil},; 
					{"DAK_SEQCAR", DAK->DAK_SEQCAR,                       Nil},;
					{"DAK_ROTEIR", DAK->DAK_ROTEIR,                   Nil},;
					}

					Aadd(aItem, {;
					DAI->DAI_COD   ,; // 01 - Código da carga
					"999999" ,; // 02 - Código da Rota - 999999 (Genérica)
					"999999" ,; // 03 - Código da Zona - 999999 (Genérica)
					"999999" ,; // 04-  Código do Setor - 999999 (Genérico)
					DAI->DAI_PEDIDO   ,; // 05 - Código do Pedido Venda
					DAI->DAI_CLIENT   ,; // 06 - Código do Cliente
					DAI->DAI_LOJA    }) // 07 - Loja do Cliente

					MSExecAuto( { |x, y, z| OMSA200(x, y, z) }, aCab, aItem, 5 )

					If lMsErroAuto					   
						_aErroAuto := GetAutoGRLog()
						cMsg:= "ERRO - Excluir carga para o pedido: "+cPedido
						For _nCount := 1 To Len(_aErroAuto)
							cMsg += StrTran(StrTran(StrTran(_aErroAuto[_nCount],"<",""),"-",""),"   "," ") + (" ")
						Next _nCount
						cMsg+= " - TWMSA047 - execauto: OMSA200"					   
						U_FtGeraLog(cFilAnt, "", "", cMsg, "001", "", "000000")	
						DisarmTransaction()
						Alert(cMsgErro)
					EndIf                   
				EndIf
			EndIf
		EndIf
	EndIf

Return

/*/{Protheus.doc} TWMA047T
Função auxiliar para relacionamento Remessas x Nota.
@type function
@author Usuário
@since 15/07/2019
@version 1.0
@return ${return}, ${return_description}
/*/
User Function TWMA047T()

	LOCAL oWindow,oConfirm,oClose,oPanel1,oPanel2,oSelect := nil
	LOCAL nFor,nOpc,nQtde:= 0
	LOCAL oSize   := FwDefSize():New(.F.) //Sem enchoicebar
	LOCAL cTabela := GetNextAlias()
	LOCAL aStruct := {}
	LOCAL cMarca  := GetMark()
	LOCAL aHeader := {}
	LOCAL cQuery  := ""
	LOCAL cTexto  := ""
	LOCAL cTitulo := "Remessas x Notas Fiscais."
	LOCAL lBarCode:= .F.
	LOCAL lLoop   := .T. 

	//Verifica se controla Barcode, para não permitir incluir o documento sem selecionar um item válido.
	cQuery:= "SELECT COUNT(1) AS QUANTIDADE FROM "+RetSQLName("SD1")+" SD1, "+RetSQLName("SB1")+" SB1 "
	cQuery+= " WHERE "
	cQuery+= " SD1.D_E_L_E_T_ != '*'"
	cQuery+= " AND SB1.D_E_L_E_T_ != '*'"
	cQuery+= " AND D1_FILIAL = '"+SF1->F1_FILIAL+"'"
	cQuery+= " AND D1_DOC = '"+SF1->F1_DOC+"'"
	cQuery+= " AND D1_SERIE  = '"+SF1->F1_SERIE+"'"
	cQuery+= " AND D1_FORNECE = '"+SF1->F1_FORNECE+"'"
	cQuery+= " AND D1_LOJA = '"+SF1->F1_LOJA+"'"
	cQuery+= " AND D1_COD = B1_COD"
	cQuery+= " AND B1_FILIAL = '"+xFilial("SB1")+"'"
	cQuery+= " AND B1_ZNUMSER = 'S'"
	If Select("TRBSD1")<> 0
		DBSelectArea("TRBSD1")
		DBCloseArea()
	EndIf
	DBUseArea(.T., "TOPCONN", TCGenQry(NIL,NIL,cQuery), "TRBSD1" , .F., .T. )
	If !TRBSD1->(Eof())
		lBarCode := TRBSD1->QUANTIDADE > 0
	EndIf
	If Select("TRBSD1")<> 0
		DBSelectArea("TRBSD1")
		DBCloseArea()
	EndIf
	If !lBarCode//Se nao tem barcode, não mostra tela
		Return
	EndIf

	DBSelectArea("SD1")
	DBSelectArea("Z55")
	DBSelectArea("Z56")
	Z56->(DBSetOrder(03))//Z56_FILIAL+Z56_NOTA+Z56_SERIE
	// se nota fiscal já vinculada, apenas avisa o usuário
	If Z56->(MsSeek(SF1->(F1_FILIAL+F1_DOC+F1_SERIE))) .And. Z56->Z56_CODCLI == SF1->F1_FORNECE .And. Z56->Z56_LOJCLI == SF1->F1_LOJA
		MsgInfo("A remessa de barcodes "+Z56->Z56_REMESS+" já está vinculada a esta nota fiscal. Este é apenas um aviso de confirmação." , "Nota fiscal já vinculada!")
		Return//Incluído tratamento para não mostrar a tela quando houver vínculo de NF. 
	EndIf
	Z56->(DBSetOrder(01))//Z56_FILIAL+Z56_REMESS+Z56_SEQUEN

	Aviso("Relacionamento de Notas x Remessa Sumitomo","A seguir serão exibidas as Remessas recebidas da Sumitomo para relacionamento com o Documento de Entrada.",{"Prosseguir"},3)

	aStruct:= Z55->(DBstruct())
	If TCCanOpen(cTabela)
		TCDelFile(cTabela)
	EndIf
	aAdd(aStruct,{"OK","C",  2,0})
	DBCreate(cTabela,aStruct,"TOPCONN")
	DBUseArea(.F., 'TOPCONN', cTabela, (cTabela), .F., .F.)

	//Campos para Header do grid
	aAdd(aHeader,{"OK"    ,"","  "        , ""     })
	aEval(aStruct,{|aLinha| Iif(aLinha[01]<>"OK", aAdd(aHeader,{aLinha[01],"",FWX3Titulo(aLinha[01]),""}),nil) })

	//Busca as Remessas de Etiquetas do WMS  sem nota vinculada.
	cQuery:= "SELECT * FROM "+RetSQLName("Z55")+" Z55 "
	cQuery+= " WHERE "
	cQuery+= " Z55_FILIAL = '"+SF1->F1_FILIAL+"'"
	cQuery+= " AND Z55_REMESS IN ( "
	cQuery+= "      SELECT DISTINCT Z56_REMESS FROM "+RetSQLName("Z56")+" Z56  "
	cQuery+= "      WHERE "
	cQuery+= "      Z56_FILIAL = Z55_FILIAL "
	cQuery+= "      AND Z55_REMESS = Z55_REMESS "
	cQuery+= "      AND Z56_NOTA = '"+Space(TamSX3("Z56_NOTA")[01])+"' "
	cQuery+= "      AND Z56.D_E_L_E_T_ != '*'"
	cQuery+= " )  "
	cQuery+= " AND Z55_CODCLI = '"+SF1->F1_FORNECE+"' "
	cQuery+= " AND Z55_LOJCLI = '"+SF1->F1_LOJA+"' "
	cQuery+= " AND Z55_PEDCLI <> '"+Space(TamSX3("Z55_PEDCLI")[01])+"' "
	cQuery+= " AND Z55.D_E_L_E_T_ != '*' "
	If Select("TRBZ55")<>0
		DBSelectArea("TRBZ55")
		DBCloseArea()
	EndIf
	DBUseArea(.T., "TOPCONN", TCGenQry(NIL,NIL,cQuery), "TRBZ55" , .F., .T. )
	TcSetField("TRBZ55","Z55_DATA","D",8,0)
	Do While !TRBZ55->(Eof())
		(cTabela)->(DBAppend(.F.))
		aEval(aStruct, {|aLinha|  (cTabela)->&(aLinha[1]):= IIf(aLinha[1]=="OK",Space(02), TRBZ55->&(aLinha[1])) } )
		(cTabela)->(DBCommit())
		TRBZ55->(DBSkip())
	EndDo
	(cTabela)->(DBGoTop())
	ProcRegua( (nQtde:= (cTabela)->(RecCount())))

	If !(lLoop:=nQtde >0) //Somente mostra a tela se houver remessa.
		MsgInfo("Não foi encontrado Remessas Sumitomo para relacionar com a Nota. Verifique!" , "TWMA047T - Não localizado remessa")	  
	EndIf

	Do While lLoop

		lLoop := lBarCode//Controle para não sair da tela sem a seleção de uma remessa válida.
		oWindow := MSDialog():New(oSize:aWindSize[1],oSize:aWindSize[2],oSize:aWindSize[3],oSize:aWindSize[4],cTitulo,,,.F.,,,,,,.T.,,,.T. )
		oWindow:lMaximized := .T.

		oPanel1 := TPanel():New(000,000,cTitulo,oWindow,,.F.,.F.,,,26,26,.T.,.F. )
		oPanel1:Align := CONTROL_ALIGN_TOP
		oConfirm := TButton():New(010,005,"Confirmar",oPanel1,{||nOpc := 1,oWindow:End()  },030,015,,,,.T.,,"",,,,.F. )
		oClose   := TButton():New(010,050,"Fechar",oPanel1,{|| nOpc:=0, oWindow:End() },030,015,,,,.T.,,"",,,,.F. )

		oPanel2 := TPanel():New(000,000,cTitulo,oWindow,,.F.,.F.,,,120,250,.T.,.F. )
		oPanel2:Align := CONTROL_ALIGN_TOP

		oSelect := MsSelect():New((cTabela),"OK",,aHeader,,cMarca,{000,000,2000,2000},,,oPanel2,,{/*legenda*/})
		oSelect:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
		oSelect:oBrowse:bAllMark := {|| fMarcacao((cTabela),"OK",cMarca) }

		oWindow:lCentered := .T.
		oWindow:Activate()

		If nOpc ==1
			(cTabela)->(DBGoTop())
			Do While !(cTabela)->(Eof())
				If (cTabela)->OK == cMarca
					Z56->(DBGoTop())
					If Z56->(MSSeek((cTabela)->(Z55_FILIAL+Z55_REMESS)));
					.And. fVldQtde(SF1->F1_FILIAL,SF1->F1_DOC,SF1->F1_SERIE,SF1->F1_FORNECE,SF1->F1_LOJA,(cTabela)->Z55_REMESS) ;
					.And. (Aviso("Vinculo de NF","Confirma o vínculo da Remessa: "+(cTabela)->Z55_REMESS+"?",{"Confirmar","Cancelar"}) == 1)
						Do While !Z56->(Eof()) .And. (cTabela)->(Z55_FILIAL+Z55_REMESS) ==  Z56->(Z56_FILIAL+Z56_REMESS)
							IncProc()
							If SD1->(MSSeek(SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)+Z56->Z56_CODPRO ))
								RecLock("Z56",.F.)
								Z56->Z56_NOTA  := SF1->F1_DOC
								Z56->Z56_SERIE := SF1->F1_SERIE
								Z56->Z56_ITEMNF:= SD1->D1_ITEM
								MSUnLock()
								lLoop := .F.
							Else
								cTexto:="ERRO - VINCULO NF - PRODUTO - "+AllTrim(Z56->Z56_CODPRO)+" - Produto na NF não localizado. NF: "+SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) 	
								U_FtGeraLog(Z56->Z56_FILIAL,"Z56",Z56->(Z56_FILIAL+Z56_REMESS+Z56_SEQUEN), cTexto, "001", "", "000000")	
							EndIf
							Z56->(DBSkip())
						EndDo
					EndIf
				EndIf
				(cTabela)->(DBSkip())
			EndDo
		EndIf

		If nQtde == 0//Valida se existe remessa para vincular.
			lLoop := .F.
		EndIf
		If lLoop
			(cTabela)->(DBGoTop())
			Aviso("Produto Controla Barcode","É necessário selecionar uma remessa válida para vínculo com a NF. Existe produto que controla Barcode.",{"OK"})
		EndIf
	EndDo

	(cTabela)->(DBCloseArea())
	TCDelFile(cTabela)
	If Select("TRBZ55")<>0
		DBSelectArea("TRBZ55")
		DBCloseArea()
	EndIf

Return

/*/{Protheus.doc} fMarcacao
Função auxiliar para marcar todos os registros.
@type function
@author Usuário
@since 15/07/2019
@version 1.0
@param cTabela, character, (Tabela temporária)
@param cCampo, character, (Campo de Marcação)
@param cMarca, character, (Marca)
/*/
Static Function fMarcacao(cTabela, cCampo, cMarca)
	Local aArea := (cTabela)->(GetArea())
	DBSelectArea(cTabela)
	DBGoTop()
	DbEval({|| RecLock(cTabela,.F.),&cCampo:= If(Empty(&cCampo),cMarca,Space(2)),MsUnLock() })
	RestArea(aArea)
Return(.T.)


/*/{Protheus.doc} fEmpFil
Função genérica para localizar a filial e o cliente para importação.
@type function
@author Usuário
@since 19/07/2019
@version 1.0
@param cDestino, character, (Filial Tecadi destino da importação.)
@return ${return}, ${Chave SA1: Cliente+Loja}
/*/
Static function fEmpFil(cDestino)

	LOCAL cCliTI      := GetNewPar("TC_SRBTI","00031601")//Cliente SRB Sta Catarina
	LOCAL cCliTP      := GetNewPar("TC_SRBTP","00031602")//Cliente SRB Parana cliente 000316  loja 02
	LOCAL cFilTTI     := GetNewPar("TC_FILTI", "103") //Filial Protheus Itajai
	LOCAL cFilTTP     := GetNewPar("TC_FILTP", "105") // Filial Protheus Parana
	LOCAL cFilTSJ     := GetNewPar("TC_FILTSJ", "106") // Filial Protheus Parana Sao Jose dos pinhais.
	LOCAL cChaveSA1   := ""
	Do Case
		Case cDestino == "TCU"
		cChaveSA1 := cCliTP
		cFilAnt   := cFilTTP
		Case cDestino == "TIT"
		cChaveSA1 := cCliTI
		cFilAnt   := cFilTTI
		Case cDestino == "TSJ"
		cChaveSA1 := cCliTP
		cFilAnt   := cFilTSJ	
	EndCase

Return cChaveSA1


/*/{Protheus.doc} TWMA047P
Função para buscar o número do pedido do cliente nos dados adicionais da NF de Entrada.
@type function
@author Luiz Fernando
@since 19/07/2019
@version 1.0
@param cString, character, (String para busca do número do pedido cliente.)
@return ${return}, ${return nil}
/*/
User Function TWMA047P() 

	LOCAL cString:= PARAMIXB
	LOCAL aArea  := GetArea()
	LOCAL cChave := Upper(GetNewPar("TC_SUMSTR","shipment_ID")) //Expressão chave para busca.
	LOCAL nIni,nFim := 0 
	LOCAL cTexto,cQuery := ""

	//Somente executa pra cliente sumitomo.
	If  !(SF1->F1_TIPO == "B" .And. SF1->F1_FORNECE == Subs(GetNewPar("TC_SRBTI","00031601"),1,TamSX3("A1_COD")[1]))
		Return ( .F. )
	EndIf

	DBSelectArea("SD1")
	DBSelectArea("Z56")
	Z56->(DBSetOrder(01))//Z56_FILIAL+Z56_REMESS+Z56_SEQUEN
	SD1->(DBSetOrder(01))//D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM

	//cString:= "Numero do Pedido: 5030; "
	//Localiza o número do pedido do cliente nos dados adicionais da NF de Entrada.
	nIni    := AT(cChave, Upper(cString))
	cString := AllTrim(Substr(cString,nIni+Len(cChave)))
	nFim    := AT(";", cString)
	nFim    := IIf(nFim == 0,Len(cString), nFim - 1)
	cString := Padl( AllTrim(Subs(cString,1,nFim)), 10, "0") // padroniza com 10 digitos

	If Empty(cString)
		cTexto := "ERRO - VINCULO NF - PEDIDO - Não localizado o Pedido do cliente na expressão enviada."
		U_FtGeraLog(SF1->F1_FILIAL,"SF1",SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA), cTexto, "001", "", "000000")
		MsgAlert(cTexto , "TWMSA047P - Erro ao vincular NF x Remessa de etiquetas")  	
		Return ( .F. )
	EndIf

	//Busca remessa para marcar o documento de entrada nos itens.
	cQuery:= " SELECT Z55_FILIAL, Z55_REMESS "
	cQuery+= " FROM "+RetSQLName("Z55")
	cQuery+= " WHERE "
	cQuery+= " Z55_FILIAL = '"+SF1->F1_FILIAL+"' "
	cQuery+= " AND Z55_CODCLI = '"+SF1->F1_FORNECE+"' "
	cQuery+= " AND Z55_LOJCLI = '"+SF1->F1_LOJA+"' "
	cQuery+= " AND Z55_PEDCLI = '"+cString+"' "
	cQuery+= " AND D_E_L_E_T_ != '*' "

	If Select("TRBZ55") <> 0
		DBSelectArea("TRBZ55")
		DBCloseArea()

	EndIf
	DBUseArea(.T., "TOPCONN", TCGenQry(NIL,NIL,cQuery), "TRBZ55" , .F., .T. )

	// procura na tabela de cabeçalho de etiquetas se já recebeu esta remessa
	If !TRBZ55->(Eof())
		//Valida se as quantidades estão corretas entre NF e Remssa.
		Z56->(DBGoTop())
		If Z56->(MSSeek(TRBZ55->(Z55_FILIAL+Z55_REMESS))).And. fVldQtde(SF1->F1_FILIAL,SF1->F1_DOC,SF1->F1_SERIE,SF1->F1_FORNECE,SF1->F1_LOJA,TRBZ55->Z55_REMESS)
			Do While !Z56->(Eof()) .And. TRBZ55->(Z55_FILIAL+Z55_REMESS) ==  Z56->(Z56_FILIAL+Z56_REMESS)
				If SD1->(MSSeek(SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)+Z56->Z56_CODPRO ))
					RecLock("Z56",.F.)
					Z56->Z56_NOTA  := SF1->F1_DOC
					Z56->Z56_SERIE := SF1->F1_SERIE
					Z56->Z56_ITEMNF:= SD1->D1_ITEM
					MSUnLock()
				Else
					cTexto:="ERRO - VINCULO NF - PRODUTO - "+AllTrim(Z56->Z56_CODPRO)+" - Produto na NF não localizado. NF: "+SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) 	
					U_FtGeraLog(Z56->Z56_FILIAL,"Z56",Z56->(Z56_FILIAL+Z56_REMESS+Z56_SEQUEN), cTexto, "001", "", "000000")	
					MsgAlert( cTexto, "TWMSA047P - Erro ao vincular NF x Remessa de etiquetas")  	
					Return ( .F. )
				EndIf
				Z56->(DBSkip())
			EndDo
		Else
			Return ( .F. )
		EndIf
	Else  // não recebeu
		cTexto := "ERRO - VINCULO NF " + CRLF +;
		"Remessa não localizada nas informações da NF "+AllTrim(SF1->F1_DOC) + CRLF +;
		"Verifique se está importando a nota fiscal enviada pelo TI da Sumitomo (manualmente)."+;
		CRLF+"Caso positivo, entre em contato e informe que não foi localizado a remessa na tag de informações complementares do XML."+;
		CRLF+"Verifique também, se as quantidades dos produdos entre a NF de entrada são as mesmas da remessa."+;
		CRLF+"Importação abortada/NF não vinculada." 	
		U_FtGeraLog(SF1->F1_FILIAL,"SF1",SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA), cTexto, "001", "", "000000")	
		MsgAlert( cTexto, "TWMSA047P - Erro ao vincular NF x Remessa de etiquetas")  	
		Return ( .F. )
	EndIf

	// fecha arquivo de trabalho
	If Select("TRBZ55") <> 0
		DBSelectArea("TRBZ55")
		DBCloseArea()
	EndIf

	//restaura area
	RestArea(aArea)

Return ( .T. )


/*/{Protheus.doc} fVldQtde
Função genérica para validar divergências entre NF de Entrada e Remessa.
@type function
@author Luiz Fernando
@since 23/07/2019
@version 1.0
@param cXFilial, character, (Filial)
@param cDoc, character, (Número da NF)
@param cSerie, character, (Série da NF)
@param cCliente, character, (Código do cliente)
@param cLoja, character, (Loja do cliente)
@param cRemessa, character, (Número da Remessa Z56)
@return ${return}, ${Retorno lógico}
/*/
Static Function fVldQtde(cXFilial,cDoc,cSerie,cCliente,cLoja,cRemessa)

	LOCAL oDlg,oList1,oBtSair,oBrowse := nil
	LOCAL oFont      := TFont():New('Courier new',,16,.T.)
	LOCAL cQuery     := ""
	LOCAL nItm,nLinha:= 0
	LOCAL cProd      := ""
	LOCAL aConfere   := {}
	LOCAL lRetorno   := .T.

	//Primeira busca de dados, para quantidades de produtos do documento de entrada.
	cQuery := " SELECT D1_COD AS PRODSD1, SUM(D1_QUANT) AS QTDESD1,  '' AS PRODZ56, 0 AS QTDEZ56 "
	cQuery += " FROM "+RetSQLName("SD1")+" SD1 (NOLOCK) "
	cQuery+= " 	INNER JOIN "+RetSQLName("SB1")+" SB1 ON "
	cQuery+= " 		D1_COD = B1_COD"
	cQuery+= " 		AND B1_FILIAL = '"+xFilial("SB1")+"'"
	cQuery+= " 		AND B1_ZNUMSER = 'S'"
	cQuery+= " 		AND SB1.D_E_L_E_T_ != '*' "
	cQuery += " WHERE "
	cQuery += " D1_FILIAL = '"+cXFilial+"' "
	cQuery += " AND D1_DOC = '"+cDoc+"' "
	cQuery += " AND D1_SERIE = '"+cSerie+"' "
	cQuery += " AND D1_FORNECE = '"+cCliente+"' "
	cQuery += " AND D1_LOJA = '"+cLoja+"' "
	cQuery += " AND SD1.D_E_L_E_T_ != '*' "
	cQuery += " GROUP BY D1_COD "

	cQuery += " UNION ALL "

	//Segunda busca de dados, para quantidades de produtos na remessa do WMS.
	cQuery += " SELECT '' AS PRODSD1, 0 AS QTDESD1,  Z56_CODPRO AS PRODZ56, SUM(Z56_QUANT) AS QTDEZ56 "
	cQuery += " FROM "+RetSQLName("Z56")+" Z56 "
	cQuery+= " 	INNER JOIN "+RetSQLName("SB1")+" SB12 ON "
	cQuery+= " 		Z56_CODPRO = B1_COD"
	cQuery+= " 		AND B1_FILIAL = '"+xFilial("SB1")+"'"
	cQuery+= " 		AND B1_ZNUMSER = 'S'"
	cQuery+= " 		AND SB12.D_E_L_E_T_ != '*' "
	cQuery += " WHERE "
	cQuery += " Z56_FILIAL = '"+cXFilial+"' "
	cQuery += " AND Z56_REMESS = '"+cRemessa+"' "
	cQuery += " AND Z56.D_E_L_E_T_ != '*' "
	cQuery += " GROUP BY Z56_CODPRO "
	If Select("TRB1") <> 0
		DBSelectArea("TRB1")
		DBCloseArea()
	EndIf
	DBUseArea(.T.,"TOPCONN",TCGenQry(NIL,NIL,cQuery),"TRB1",.F.,.T.)

	Do While !TRB1->(Eof())

		cProd := IIf(!Empty(TRB1->PRODSD1),TRB1->PRODSD1, TRB1->PRODZ56)
		If (nItm:= aScan(aConfere, {|x| x[01] == cProd})) >0
			aConfere[nItm][02] += TRB1->QTDESD1
			aConfere[nItm][03] += TRB1->QTDEZ56 
		Else 
			Aadd(aConfere,{cProd,TRB1->QTDESD1,TRB1->QTDEZ56,0 })
		EndIf
		TRB1->(DBSkip())
	EndDo

	//Calcula se há divergência entre o doc. de entrada e a remessa do WMS.
	aEval(aConfere, {|aLinha|  nLinha++, aConfere[nLinha][04]:= (aLinha[02]-aLinha[03]), Iif(lRetorno, lRetorno:= Empty(aConfere[nLinha][04]),nil )  } )

	If !lRetorno
		Aviso("Divergência NF x Remessa SUMITOMO","Existe divergência entre a Nota de Entrada e a Remessa Sumitomo.",{"Prosseguir"})

		oDlg := MSDialog():New(100,100,430,700,"Divergência de Produtos",,,,,CLR_BLACK,/*nClrBack*/,,,.T.,,,,,)
		oDlg:lEscClose := .T.
		oPanel1:= tPanel():New(001,005,"Lista de Divergências:",oDlg,oFont,,,CLR_BLACK,/*nClrBack*/,290,145,.F.,.T.)

		oBrowse := TCBrowse():New( 010 , 005, 280, 125,, {'Produto','Qtde NF','Qtde Remessa','Diferença'},{20,50,50,50}, oPanel1,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
		oBrowse:SetArray(aConfere)
		oBrowse:bLine := {||{ aConfere[oBrowse:nAt,01],aConfere[oBrowse:nAt,02],aConfere[oBrowse:nAt,03],aConfere[oBrowse:nAT,04] }}
		oBtSair     := TButton():New(150, 260, "Sair",oDlg,{|| oDlg:End()},30,10,,,.F.,.T.,.F.,,.F.,,,.F.)

		oDlg:lCentered := .T.
		oDlg:Activate()

	EndIf
	If Select("TRB1") <> 0
		DBSelectArea("TRB1")
		DBCloseArea()
	EndIf

Return lRetorno

/*/{Protheus.doc} TWMA047N
Função chamada no NFESEFAZ para incluir informações adicionais do produto.
WMS_CONTROL: Será YES quando NF incluída após a entrada em produção da integração e constar relacionada a Remessa(Z56).
Ao contrário envia NO.
Tag: infAdProd
@type function
@author Luiz Fernando
@since 29/07/2019
@version 1.0
@param cFil, character, (Filial)
@param cDoc, character, (NF Orig)
@param cSerie, character, (Série Orig.)
@param cItem, character, (Item Orig.)
@param cCliente, character, (Cliente)
@param cLoja, character, (Loja)
@param cProd, character, (Código do produto.)
@return ${return}, ${Texto para cInfAdic}
@example 
(U_TWMA047N("106","000123458","1  ","0001","000316","02","SUMI327002                    "))
/*/
User Function TWMA047N(cFil,cDoc,cSerie,cItem,cCliente,cLoja,cProd)

	LOCAL cRet   := ""
	LOCAL cQuery := ""
	LOCAL cYesNo := "NO"
	LOCAL cDtIni := GetNewPar("TC_SUMIDTNF","20190723")

	//Somente executa para cliente Sumitomo.
	If cCliente <> Subs(GetNewPar("TC_SRBTI","00031601"),1,TamSX3("A1_COD")[1])
		Return cRet 
	EndIf

	//Busca a NF relacionada(poder de 3o) para verificar a data em foi digitada.
	cQuery:= " SELECT DISTINCT D1_DTDIGIT FROM "+RetSQLName("SD1")+" SD1 "
	cQuery+= " 	INNER JOIN "+RetSQLName("Z56")+" Z56 ON "//Somente NF relacionada a remessa.
	cQuery+= " 		Z56_FILIAL = D1_FILIAL "
	cQuery+= " 		AND Z56_NOTA = D1_DOC "
	cQuery+= " 		AND Z56_SERIE = D1_SERIE "
	cQuery+= " 		AND Z56_ITEMNF = D1_ITEM "
	cQuery+= " 		AND Z56_CODCLI = D1_FORNECE "
	cQuery+= " 		AND Z56_LOJCLI = D1_LOJA "
	cQuery+= " 		AND Z56.D_E_L_E_T_ != '*' "
	cQuery+= " 	INNER JOIN "+RetSQLName("SB1")+" SB1 ON "
	cQuery+= " 		B1_FILIAL = '"+xFilial("SB1")+"' "
	cQuery+= " 		AND B1_COD = D1_COD "
	cQuery+= " 		AND B1_ZNUMSER = 'S'"//Somente produtos que controlam Barcode.
	cQuery+= " 		AND SB1.D_E_L_E_T_ != '*' "
	cQuery+= " WHERE "
	cQuery+= " D1_FILIAL = '"+cFil+"' "
	cQuery+= " AND D1_DOC = '"+cDoc+"' "
	cQuery+= " AND D1_SERIE = '"+cSerie+"' "
	cQuery+= " AND D1_FORNECE = '"+cCliente+"' "
	cQuery+= " AND D1_LOJA = '"+cLoja+"' "
	cQuery+= " AND D1_COD = '"+cProd+"' "
	cQuery+= " AND D1_ITEM = '"+cItem+"' "
	cQuery+= " AND D1_TIPO = 'B' "
	cQuery+= " AND SD1.D_E_L_E_T_ != '*' "
	//D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM - Usa índice completo para a busca.
	If Select("TRBSD1") <> 0 
		DBSelectArea("TRBSD1")
		DBCloseArea()
	EndIf
	DBUseArea(.T.,"TOPCONN",TCGenQry(NIL,NIL,cQuery),"TRBSD1",.F.,.T.)
	If !TRBSD1->(Eof())
		cYesNo := Iif(TRBSD1->D1_DTDIGIT >= cDtIni,"YES","NO")
	EndIf
	cRet := " WMS_CONTROL:"+cYesNo
	If Select("TRBSD1")<> 0
		DBSelectArea("TRBSD1")
		DBCloseArea()
	EndIf

Return cRet

/*/{Protheus.doc} fEnvMail
Função para envio de e-nmail dos Bloqueios/Desbloqueios de estoque.
@author Luiz Fernando Berti
@since 19/09/2019
@version 1.0
@param aDados, array, Registros integrados.
@param cArquivo, characters, Nome do Arquivo para Integração.
@type function
@return ${return}, ${return_description}
/*/
Static Function fEnvMail(aDados,cArquivo)

	LOCAL cHTML:= ""
	LOCAL nFor := 0
	LOCAL cEndM:= GetNewPar("TC_MAILSU","ti@tecadi.com.br")

	//Montagem do corpo do e-mail.
	cHTML:= '<table width="780px" align="center">'
	cHTML+= '   <tr>'
	cHTML+= '      <td>'
	cHTML+= '         <table style="border-collapse: collapse;font-family: Tahoma; font-size: 12px;" border="1" width="100%" cellpadding="2" cellspacing="0" align="center" >'
	cHTML+= '            <tr>'
	cHTML+= '               <td height="30" colspan="2" style="background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Resumo do Processamento de Arquivo.</td>'
	cHTML+= '            </tr>'
	cHTML+= '            <tr>'
	cHTML+= '               <td width="20%" >Filial</td>'
	cHTML+= '               <td width="80%" >' + AllTrim(SM0->M0_CODFIL) + "-" + AllTrim(SM0->M0_FILIAL) + '</td>'
	cHTML+= '            </tr>'
	cHTML+= '            <tr>'
	cHTML+= '               <td width="20%" >Data/Hora</td>'
	cHTML+= '               <td width="80%" >'+DtoC(Date())+' / '+Time()+' h</td>'
	cHTML+= '            </tr>'
	cHTML+= '         </table>'
	cHTML+= '         <br>'
	cHTML+= '         <table style="border-collapse: collapse;font-family: Tahoma; font-size: 12px;" border="1" width="100%" cellpadding="2" cellspacing="0" align="center" >'
	cHTML+= '            <tr>'
	cHTML+= '               <td height="20" colspan="5" style="background-color: #1B5A8F; font-weight: bold; color: #FFFFFF;" align="center">Resumo do processamento do arquivo: '+cArquivo+'</td>'
	cHTML+= '            </tr>'
	cHTML+= '            <tr style="background-color: #87CEEB;">'
	cHTML+= '               <td width="20%" >Barcode</td>'
	cHTML+= '               <td width="20%" >Status</td>'
	cHTML+= '               <td width="60%" >Descrição</td>'
	cHTML+= '            </tr>'
	For nFor:= 1 To Len(aDados)
		cHTML+= '<tr>'
		cHTML+= '	<td width="20%" >' + aDados[nFor][01] + '</td>'
		cHTML+= '	<td width="20%" >' + aDados[nFor][02] + '</td>'
		cHTML+= '	<td width="60%" >' + aDados[nFor][03] + '</td>'
		cHTML+= '</tr>'
	Next 

	cHTML+= '      </table>'
	cHTML+= '   <br>'
	cHTML+= '   </td>'
	cHTML+= '  </tr>'
	cHTML+= '</table>'

	U_FtMail(cHTML, "TECADI - Action Class 41 - Log Integração - " + DtoC(Date()), cEndM)

Return
