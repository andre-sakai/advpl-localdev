#Include "Totvs.ch"
#Include "Colors.ch"
#INCLUDE "topconn.ch"
#Define _CRLF Chr(13)+Chr(10)

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Faturamento dos Contratos WMS							 !
+------------------+---------------------------------------------------------+
!Autor             ! TSC149-Percio Alexandre de Oliveira                     !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2010                                                 !
+------------------+---------------------------------------------------------+
!   ATUALIZACOES                                                             !
+-------------------------------------------+-----------+-----------+--------+
!   Descricao detalhada da atualizacao      !Nome do    ! Analista  !Data da !
!                                           !Solicitante! Respons.  !Atualiz.!
+-------------------------------------------+-----------+-----------+--------+
!                                           !           !           !        !
!                                           !           !           !        !
+-------------------------------------------+-----------+-----------+-------*/

User Function TWMSA004()
	// grupo de perguntas
	local _aPerg := {}
	private _cPerg := PadR("TWMSA004",10)

	// monta a lista de perguntas
	aAdd(_aPerg,{"Contrato de ?" ,"C",TamSx3("AAM_CONTRT")[1],0,"G",,"AAM"}) //mv_par01
	aAdd(_aPerg,{"Contrato Até ?" ,"C",TamSx3("AAM_CONTRT")[1],0,"G",,"AAM"}) //mv_par02
	aAdd(_aPerg,{"Cliente de ?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par03
	aAdd(_aPerg,{"Cliente Até ?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par04
	aAdd(_aPerg,{"Processo de ?" ,"C",TamSx3("Z1_CODIGO")[1],0,"G",,"SZ1"}) //mv_par05
	aAdd(_aPerg,{"Processo Até ?" ,"C",TamSx3("Z1_CODIGO")[1],0,"G",,"SZ1"}) //mv_par06
	aAdd(_aPerg,{"Mostra Faturados ?" ,"N",1,0,"C",{"Sim","Não"},""}) //mv_par07
	aAdd(_aPerg,{"Tipo de Serviço ?" ,"C",2,0,"G",,"T0"}) //mv_par08
	aAdd(_aPerg,{"Status do Processo ?" ,"N",1,0,"C",{"Aberto","Encerrado","Ambos"},""}) //mv_par09

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg,_aPerg)

	// abre os parametros
	if !Pergunte(_cPerg,.T.)
		Return
	endif

Processa({ || U_WMSA004P() },"Gerando P.Vendas por Contrato",,.T. ) //"Gerando P.Vendas por Contrato"

Return NIL

User Function WMSA004X()
	// desabilitado
	If (!_lBtnParam)
		Aviso("TWMSA004 -> WMSA004X","Opção desabilitida para este processo.",{"Fechar"})
		Return(.t.)
	EndIf

	if Pergunte(_cPerg,.T.)
		(_TRBMOV)->(dbSelectArea(_TRBMOV))
		(_TRBMOV)->(dbGotop())
		While !EOF()
			(_TRBMOV)->(RecLock(_TRBMOV,.F.))
			(_TRBMOV)->(dbDelete())
			(_TRBMOV)->(MsUnlock())
			(_TRBMOV)->(dbSkip())
		EndDo

		_bMostraFat	:= (mv_par07 == 1)
		aMovContr	:= {}

		sfProcContrato()

		(_TRBMOV)->(dbSelectArea(_TRBMOV))
		(_TRBMOV)->(dbGotop())
	endif

Return(.t.)

//Static Function WMSA004P()
User Function WMSA004P(mvParam)

Local _aEstrTrb		:= {}

Default mvParam := .t.

Private _TRBMOV		:= GetNextAlias()
Private _cArqTmp

Private dProcesso 	:= dDatabase
Private dProcIni	:= CTOD('')
Private aMovContr	:= {}
Private oFntVerd15 	:= TFont():New("Verdana",,15,,.T.)
Private _bMostraFat	:= (mv_par07 == 1)
// pesmite utilizar o botao de parametros (desabilitado qdo executado pela consulta de programacoes TWMSV004)
private _lBtnParam  := mvParam

aAdd(_aEstrTrb,{"IT_OK"		,"C", 2,0})
aAdd(_aEstrTrb,{"Z2_CODIGO"	,"C", TamSx3("Z2_CODIGO")[1],0})
aAdd(_aEstrTrb,{"Z2_ITEM"	,"C", TamSx3("Z2_ITEM")[1],0})
aAdd(_aEstrTrb,{"A1_COD"	,"C", TamSx3("A1_COD")[1],0})
aAdd(_aEstrTrb,{"A1_LOJA"	,"C", TamSx3("A1_LOJA")[1],0})
aAdd(_aEstrTrb,{"A1_NREDUZ"	,"C", TamSx3("A1_NREDUZ")[1],0})
aAdd(_aEstrTrb,{"AAN_CODPRO","C", TamSx3("AAN_CODPRO")[1],0})
aAdd(_aEstrTrb,{"B1_DESC"	,"C", 30,0})
aAdd(_aEstrTrb,{"AAN_QUANT"	,"N", TamSx3("AAN_QUANT")[1],TamSx3("AAN_QUANT")[2]})
aAdd(_aEstrTrb,{"AAN_VLRUNI","N", TamSx3("AAN_VLRUNI")[1],TamSx3("AAN_VLRUNI")[2]})
aAdd(_aEstrTrb,{"AAN_VALOR"	,"N", TamSx3("AAN_VALOR")[1],TamSx3("AAN_VALOR")[2]})
aAdd(_aEstrTrb,{"C6_NUM"	,"C", TamSx3("C6_NUM")[1],0})
aAdd(_aEstrTrb,{"C6_ITEM"	,"C", TamSx3("C6_ITEM")[1],0})
aAdd(_aEstrTrb,{"AAN_CONTRT","C", TamSx3("AAN_CONTRT")[1],0})
aAdd(_aEstrTrb,{"AAN_ITEM"	,"C", TamSx3("AAN_ITEM")[1],0})
aAdd(_aEstrTrb,{"B1_TIPOSRV","C", TamSx3("B1_TIPOSRV")[1],0})
aAdd(_aEstrTrb,{"AAN_DATA"	,"D", TamSx3("AAN_DATA")[1],0})

// fecha alias do TRB
If (Select(_TRBMOV)<>0)
	dbSelectArea(_TRBMOV)
	dbCloseArea()
EndIf

// criar um arquivo de trabalho
_cArqTmp := FWTemporaryTable():New( _TRBMOV )
_cArqTmp:SetFields( _aEstrTrb )
_cArqTmp:AddIndex("01", {"A1_COD", "A1_LOJA", "Z2_CODIGO", "Z2_ITEM", "AAN_CODPRO", "AAN_CONTRT", "AAN_ITEM"} )
_cArqTmp:Create()




//Processa todos os contratos de acordo com parametros iniciais
sfProcContrato()

//Apresenta Tela para Usuario com itens a serem faturados e suas movimentacoes para validacao e ajustes se necessario
sfValidaFatura()

// fecha arquivo de trabalho
(_TRBMOV)->(dbSelectArea(_TRBMOV))
(_TRBMOV)->(dbCloseArea())
_cArqTmp:Delete()

Return(.t.)

//** funcao que processa todos os contratos
Static Function sfProcContrato()
	// itens para NAO faturar
	local _cNaoFatur := If((AAM->(FieldPos("AAM_ZNAOFA"))>0),AAM->AAM_ZNAOFA,"")
	// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
	private _nStsProc	:= mv_par09

	DbSelectArea("AAM")
	DbSetOrder(1)
	dbGotop()

	ProcRegua(RecCount())

	While AAM->(!Eof()) .And. AAM_FILIAL == xFilial("AAM")

		// Verifica apenas contratos dentro da faixa selecionada
		If AAM->AAM_CONTRT < MV_PAR01 .OR. AAM->AAM_CONTRT > MV_PAR02
			AAM->(dbSkip())
			Loop
		EndIf

		// Verifica apenas contratos dentro da faixa de clientes selecionada
		If AAM->AAM_CODCLI < MV_PAR03 .OR. AAM->AAM_CODCLI > MV_PAR04
			AAM->(dbSkip())
			Loop
		EndIf

		// Verifica apenas contratos dentro da faixa de vigencia da database
		If	dProcesso < AAM->AAM_INIVIG .OR. dProcesso > AAM->AAM_FIMVIG
			AAM->(dbSkip())
			Loop
		EndIf

		// Verifica apenas contratos com status ativos
		If AAM->AAM_STATUS <> "1"
			AAM->(dbSkip())
			Loop
		EndIf

		IncProc("Processando Contrato Nro: "+AllTrim(AAM->AAM_CONTRT))

		AAN->(DbSetOrder(1))
		cSeekAAN := xFilial("AAN") + AAM->AAM_CONTRT
		AAN->( DbSeek( cSeekAAN ) )

		// reinicia as variaveis
		bArmP := bArmC := bFret := bSegu := bOutr := .F.

		// processa todos os itens do contrato
		While AAN->(!Eof() .And. AAN->AAN_FILIAL + AAN->AAN_CONTRT == cSeekAAN )

			dbSelectArea("SB1")
			dbSetOrder(1)
			dbSeek(xFilial("SB1")+AAN->AAN_CODPRO)

			// Verifica se condicao de pagamento do item do contrato e na data do faturamento
			bFat:=.F.
			If Day(dDatabase) >= AAN->AAN_DIAFAT .OR. AAN->AAN_DIAFAT == 0
				bFat:=.T.
			EndIf

			//Caso seja servico fixo verificar se ja nao foi faturado nesta data
			If bFat .And. SB1->B1_TIPOSRV == '8'
				dbSelectArea("SZR")
				dbSetOrder(1)
				If dbSeek(xFilial("SZR")+Space(8)+AAN->AAN_CONTRT+AAN->AAN_ITEM)
					If Month(SZR->ZR_DATA) == Month(dDatabase)
						bFat:=.F.
					EndIf
				EndIf
			EndIf

			// Verifica data inicial caso haja contrato
			dProcIni := AAM->AAM_INIVIG

			If bFat

				Do Case
					Case (SB1->B1_TIPOSRV=='1').and.(mv_par08 $ "01|09")
						sfArmzContainer(AAN->AAN_ITEM)
						bArmC := .T.

					Case (SB1->B1_TIPOSRV=='2').and.(mv_par08 $ "02|09")
						sfArmzProduto(AAN->AAN_ITEM)
						bArmP := .T.

					Case (SB1->B1_TIPOSRV=='3').and.(mv_par08 $ "03|04|07|09")
						sfPacote(AAN->AAN_ITEM)

					Case (SB1->B1_TIPOSRV=='4').and.(mv_par08 $ "03|04|09")
						sfFrete(AAN->AAN_ITEM)
						bFret := .T.

					Case (SB1->B1_TIPOSRV=='5').and.(mv_par08 $ "05|09")
						sfSeguro(AAN->AAN_ITEM)
						bSegu := .T.

					Case (SB1->B1_TIPOSRV=='7').and.(mv_par08 $ "03|07|09")
						sfOutrosServicos(AAN->AAN_ITEM)
						bOutr := .T.

					Case (SB1->B1_TIPOSRV=='8').and.(mv_par08 $ "08|09")
						sfFixo(AAN->AAN_ITEM)
				EndCase
			EndIf

			AAN->(DbSkip())

		EndDo

		// verifica se faturar outros servicos
		If (!bOutr).and.(mv_par08 $ "03|07|09").and.((!("3" $ _cNaoFatur)).or.(!("7" $ _cNaoFatur)))
			sfOutrosServicos(Space(2))
		EndIf
		// verifica se deve faturar fretes
		If (!bFret).and.(mv_par08 $ "03|04|09").and.((!("3" $ _cNaoFatur)).or.(!("4" $ _cNaoFatur)))
			sfFrete(Space(2))
		EndIf
		// verifica se deve faturar seguros
		If (!bSegu).and.(mv_par08 $ "05|09").and.(!("5" $ _cNaoFatur))
			sfSeguro(Space(2))
		EndIf
		// verifica se deve faturar armazenagem de produtos
		If (!bArmP).and.(mv_par08 $ "02|09").and.(!("2" $ _cNaoFatur))
			sfArmzProduto(Space(2))
		EndIf
		// verifica se deve faturar armazenagem de containers
		If (!bArmC).and.(mv_par08 $ "01|09").and.(!("1" $ _cNaoFatur))
			sfArmzContainer(Space(2))
		EndIf

		// proximo contrato
		AAM->(DbSkip())

	EndDo

	// alimenta os pedidos ja faturados
	If (_bMostraFat)

		cQuery:="SELECT ZR.* FROM "+RetSqlName("SZR")+" ZR (nolock) , "+RetSqlName("SB1")+" B1 (nolock)  WHERE ZR_CODSRV = B1_COD AND ZR_FILIAL = '"+xFilial("SZR")+"' AND ZR.D_E_L_E_T_ = '' AND B1.D_E_L_E_T_ = '' AND ZR_CONTRT BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' "
		cQuery+="AND ZR_CODCLI BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"' AND ZR_PROGRAM BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' "
		If mv_par08 <> "09"
			cQuery+="AND B1_TIPOSRV = '"+AllTrim(STR(Val(mv_par08)))+"'"
		EndIf
		If Select("QRY") <> 0
		   dbSelectArea("QRY")
		   dbCloseArea("QRY")
		EndIf

		cQuery:=ChangeQuery(cQuery)
		TCQUERY cQuery Alias "QRY" New

		dbSelectArea("QRY")
		dbGoTop()
		While QRY->(!Eof())

	    	(_TRBMOV)->(RecLock(_TRBMOV,.T.))
			(_TRBMOV)->IT_OK := ""
			(_TRBMOV)->Z2_CODIGO := QRY->ZR_PROGRAM
			(_TRBMOV)->Z2_ITEM := QRY->ZR_ITEPROG
			(_TRBMOV)->A1_COD := QRY->ZR_CODCLI
			(_TRBMOV)->A1_LOJA := QRY->ZR_LOJCLI
			(_TRBMOV)->A1_NREDUZ := AllTrim(Posicione("SA1",1,xFilial("SA1")+QRY->ZR_CODCLI+QRY->ZR_LOJCLI,"A1_NREDUZ"))
			(_TRBMOV)->AAN_CODPRO := QRY->ZR_CODSRV
			(_TRBMOV)->B1_DESC := QRY->ZR_DESCRI
			(_TRBMOV)->AAN_QUANT	:= QRY->ZR_QUANT
			(_TRBMOV)->AAN_VLRUNI	:= QRY->ZR_VLRUNI
			(_TRBMOV)->AAN_VALOR := QRY->ZR_VALOR
			(_TRBMOV)->C6_NUM := QRY->ZR_PEDIDO
			(_TRBMOV)->C6_ITEM := QRY->ZR_ITEPEDI
			(_TRBMOV)->AAN_CONTRT := QRY->ZR_CONTRT
			(_TRBMOV)->AAN_ITEM := QRY->ZR_ITEM
			(_TRBMOV)->AAN_DATA := STOD(QRY->ZR_DATA)
			(_TRBMOV)->B1_TIPOSRV := Posicione("SB1",1,xFilial("SB1")+QRY->ZR_CODSRV,"B1_TIPOSRV")
			(_TRBMOV)->(MsUnlock())

			dbSelectArea("SZS")
			dbSetOrder(2)
			dbSeek(xFilial("SZS")+QRY->ZR_PEDIDO+QRY->ZR_ITEPEDI)
			While SZS->(!EOF()) .AND. SZS->ZS_PEDIDO+SZS->ZS_ITEPEDI==QRY->ZR_PEDIDO+QRY->ZR_ITEPEDI

				aTmpMovIt := 	{	SZS->ZS_PROGRAM,;  		// 1 - Numero da Programacao / Pedido de Venda
						 			SZS->ZS_ITEPROG,;       // 2 - Item da Programacao
						 			SZS->ZS_CONTRT,;      	// 3 - Numero do Contrato
					     			SZS->ZS_ITEM,;        	// 4 - Item do Contrato
					     			SZS->ZS_CODSRV,;     	// 5 - Codigo do Produto Servico
					     			SZS->ZS_CODCLI,; 		// 6 - Codigo do Cliente
						 			SZS->ZS_LOJCLI,;     	// 7 - Loja do Cliente
						 			SZS->ZS_QTDE,; 			// 8 - Quantidade
					     			SZS->ZS_TARIFA,;   		// 9 - Tarifa
								  	SZS->ZS_TOTAL,;		    // 10 - Total
								   	SZS->ZS_DATAI,;     	// 11 - Data de Processamento Inicial
								   	SZS->ZS_DATAF,;       	// 12 - Data de Processamento Final
								    SZS->ZS_CONTAIN,;       // 13 - Container
								    SZS->ZS_QTDPERI,;		// 14 - Quantidade de Periodos
					     			SZS->ZS_PERIODO,;       // 15 - Periodicidade
								    SZS->ZS_DATA1,;  		// 16 - Data 1 (Data de Remessa)
						 			SZS->ZS_DATA2,;			// 17 - Data 2 (Data de Devolucao)
						 			SZS->ZS_NUMOS,;			// 18 - Numero da OS
						 			SZS->ZS_CODATIV,;      	// 19 - Codigo da Atividade
						 			SZS->ZS_FATURAR,;		// 20 - Faturar Atividade (S/N)
					     			SZS->ZS_TIPMOV,;      	// 21 - Tipo de Movimento
					     			SZS->ZS_OPERACA,;		// 22 - Operacao
					     			SZS->ZS_DAYFREE,;		// 23 - Quantidade de Dias Free
								    SZS->ZS_TIPARMA,;     	// 24 - Tipo de Armazenagem
								    SZS->ZS_RICENTR,;		// 25 - RIC de Entrada
						 			SZS->ZS_RICSAID,;		// 26 - RIC de Saida
						 			SZS->ZS_PRCORIG,;		// 27 - Praca de Origem
			 						SZS->ZS_PRCDEST,;		// 28 - Praca de Destino
			 						SZS->ZS_CONTEUD,;		// 29 - Conteudo do Container
			 						SZS->ZS_TAMCONT,;		// 30 - Tamanho do Contaier
			 						SZS->ZS_TRANSP,;		// 31 - Transportadora
			 						SZS->ZS_OBSERVA,;		// 32 - Observacoes
			 						SZS->ZS_PEDIDO+SZS->ZS_ITEPEDI,;// 33 - Pedido+Item
			 						SZS->ZS_VLRDOC,;		// 34 - Valor Total da Nota
				 					SZS->ZS_DOCREM,;		// 35 - Nota de Remessa
				 					SZS->ZS_DOCDEV,;		// 36 - Nota de Devolucao
				 					SZS->ZS_PACCONT,;    	// 37 - Numero do Contrato Pacote Logistico
		     						SZS->ZS_PACITEM,;      	// 38 - Item do Contrato Pacote Logistico
		     						SZS->ZS_PACPROD,;      	// 39 - Produto do Pacote Logistico
		     						.F.,;					// 40 - Linha Deletada .T. / .F.
			     				}

				Aadd(aMovContr,aTmpMovIt)

				SZS->(dbSkip())
			EndDo

			QRY->(dbSkip())
	    EndDo

	EndIf

Return(.t.)

//** funcao para faturamento de pacote logistico
Static Function sfPacote(cItem)

Private aTmpMovIt	:= {}
Private aTmpMovTo	:= {}
Private cPrdServico	:= CriaVar("B1_COD")
Private nTarifa		:= 0
Private cPraca		:= CriaVar("AAN_PRACA")
Private cTipoCa		:= CriaVar("AAN_TIPOCA")

// Verifica dados do contrato se houver
dbSelectArea("AAN")
dbSetOrder(1)
If dbSeek(xFilial("AAN")+AAM->AAM_CONTRT+cItem)
	nTarifa		:= AAN->AAN_VLRUNI
	cPrdServico	:= AAN->AAN_CODPRO
	cPraca		:= AllTrim(AAN->AAN_PRACA)
	cTipoCa		:= AAN->AAN_TIPOCA
EndIf
cItem:=IIf(Empty(cItem),"Z"+"3",cItem)

// MOVIMENTACOES DE ENTRADA
cQuery:="SELECT Z3_DTMOVIM, Z3_CONTAIN, Z3_PROGRAM, Z3_ITEPROG, Z3_RIC, Z3_TPMOVIM, Z3_PRCORIG, Z3_PRCDEST, Z3_CONTEUD, Z3_TAMCONT, Z3_TRANSP "
cQuery+="FROM "+RetSqlName("SZ3")+" Z3 (nolock) , "+RetSqlName("SZ1")+" Z1 (nolock)  "
cQuery+="WHERE Z3_FILIAL = '"+xfilial("SZ3")+"' AND Z3_FILIAL = Z1_FILIAL AND Z3_PROGRAM = Z1_CODIGO AND Z3_TPMOVIM = 'E' "
cQuery+="AND Z3_PRCORIG IN ("+sfTxtPrc(cPraca)+") "
cQuery+="AND Z3_DTFATPA = '' "
cQuery+="AND Z3_DTMOVIM BETWEEN '"+dtos(dProcIni)+"' AND '"+dtos(ddatabase -1)+"' "
cQuery+="AND Z3_CLIENTE = '"+AAM->AAM_CODCLI+"' "
cQuery+="AND Z3_LOJA = '"+AAM->AAM_LOJA+"' "
cQuery+="AND Z1_CONTRT = '"+AAM->AAM_CONTRT+"' "
// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
If (_nStsProc==1) // aberto
	cQuery+="AND Z1_DTFINFA = ' ' "
ElseIf (_nStsProc==2) // encerrado
	cQuery+="AND Z1_DTFINFA != ' ' "
EndIf

cQuery+="AND Z3_PROGRAM BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' "
If !Empty(cTipoCa)
	cQuery+="AND Z1_TIPOCAR = '"+cTipoCa+"' "
EndIf
// 26.08 - cnfe orientacao do Toni, soh pode ser transportadora tecadi
cQuery+="AND Z3_TRANSP = '000023' "
// deletados
cQuery+="AND Z3.D_E_L_E_T_ = ' ' AND Z1.D_E_L_E_T_ = ' ' "
// ordem dos dados
cQuery+="ORDER BY Z3_PROGRAM, Z3_ITEPROG "

//cQuery := ChangeQuery(cQuery)

If (Select("TRB2") != 0)
	dbSelectArea("TRB2")
	dbCloseArea()
Endif
TCQuery cQuery NEW ALIAS "TRB2"

DbSelectArea("TRB2")
dbgotop()
While TRB2->(!EOF())

	aTmpMovIt := 	{	TRB2->Z3_PROGRAM,;  		// 1 - Numero da Programacao / Pedido de Venda
			 			TRB2->Z3_ITEPROG,;       	// 2 - Item da Programacao
			 			AAM->AAM_CONTRT,;      		// 3 - Numero do Contrato
		     			cItem,;		        		// 4 - Item do Contrato
		     			cPrdServico,;	     		// 5 - Codigo do Produto Servico
		     			AAM->AAM_CODCLI,; 			// 6 - Codigo do Cliente
			 			AAM->AAM_LOJA,;     		// 7 - Loja do Cliente
			 			1,; 						// 8 - Quantidade
		     			nTarifa,;   				// 9 - Tarifa
					  	nTarifa,;		      		// 10 - Total
					   	dProcIni,;     				// 11 - Data de Processamento Inicial
					   	ddatabase-1,;       		// 12 - Data de Processamento Final
					    TRB2->Z3_CONTAIN,;        	// 13 - Container
					    0,;		         			// 14 - Quantidade de Periodos
		     			0,;        					// 15 - Periodicidade
					    STOD(TRB2->Z3_DTMOVIM),;  	// 16 - Data 1 (Data de Remessa)
			 			CTOD(''),;			 		// 17 - Data 2 (Data de Devolucao)
			 			'',;						// 18 - Numero da OS
			 			'',;      					// 19 - Codigo da Atividade
			 			'S',;				     	// 20 - Faturar Atividade (S/N)
		     			TRB2->Z3_TPMOVIM,;          // 21 - Tipo de Movimento
		     			'',;						// 22 - Operacao
		     			0,;				  			// 23 - Quantidade de Dias Free
					    '',;     					// 24 - Tipo de Armazenagem
					    TRB2->Z3_RIC,;				// 25 - RIC de Entrada
			 			'',;						// 26 - RIC de Saida
			 			TRB2->Z3_PRCORIG,;			// 27 - Praca de Origem
			 			TRB2->Z3_PRCDEST,;			// 28 - Praca de Destino
			 			TRB2->Z3_CONTEUD,;			// 29 - Conteudo do Container
			 			TRB2->Z3_TAMCONT,;			// 30 - Tamanho do Contaier
			 			TRB2->Z3_TRANSP,;			// 31 - Transportadora
			 			'',;						// 32 - Observacoes
			 			Space(8),;					// 33 - Pedido+Item
			 			0,;							// 34 - Valor Total da Nota
				 		'',;						// 35 - Nota de Remessa
				 		'',;						// 36 - Nota de Devolucao
				 		'',;			    		// 37 - Numero do Contrato Pacote Logistico
		     			'',;		        		// 38 - Item do Contrato Pacote Logistico
		     			'',;		        		// 39 - Produto do Pacote Logistico
		     			.F.,;						// 40 - Linha Deletada .T. / .F.
		     		}

	Aadd(aMovContr,aTmpMovIt)
	Aadd(aTmpMovTo,aTmpMovIt)

	TRB2->(DBSKIP())

ENDDO

sfCarregaTRB(aTmpMovTo,.F.,'','3')

Return(.t.)

Static Function sfTxtPrc(cTxt)

	cRet:=""
	cRet:="'"+cTxt+"'"
	cRet:=StrTran(cRet,";","','")

Return cRet

Static Function sfFrete(cItem)

Private aTmpMovIt	:= {}
Private aTmpMovTo	:= {}
Private cPrdServico	:= CriaVar("B1_COD")

// Verifica dados do contrato se houver
dbSelectArea("AAN")
dbSetOrder(1)
If dbSeek(xFilial("AAN")+AAM->AAM_CONTRT+cItem)
	cPrdServico:=AAN->AAN_CODPRO
EndIf
cItem:=IIf(Empty(cItem),"Z"+"4",cItem)

// MOVIMENTACOES DE FRETE
cQuery:="SELECT Z3_DTMOVIM, Z3_CONTAIN, Z3_PROGRAM, Z3_ITEPROG, Z3_RIC, Z3_TPMOVIM, Z3_PRCORIG, Z3_PRCDEST, Z3_CONTEUD, Z3_TAMCONT, Z3_TRANSP "
cQuery+="FROM "+RetSqlName("SZ3")+" Z3 (nolock) , "+RetSqlName("SZ1")+" Z1 (nolock)  "
cQuery+="WHERE Z3_FILIAL = '"+xfilial("SZ3")+"' AND Z3_FILIAL = Z1_FILIAL AND Z3_PROGRAM = Z1_CODIGO AND ((Z3_TPMOVIM = 'E' AND Z3_TRACONT = '000023') OR (Z3_TPMOVIM = 'S' AND Z3_TRANSP = '000023')) "
cQuery+="AND Z3_DTFATFR = '' "
cQuery+="AND Z3_DTMOVIM BETWEEN '"+dtos(dProcIni)+"' AND '"+dtos(ddatabase -1)+"' "
cQuery+="AND Z3_CLIENTE = '"+AAM->AAM_CODCLI+"' "
cQuery+="AND Z3_LOJA = '"+AAM->AAM_LOJA+"' "
cQuery+="AND Z1_CONTRT = '"+AAM->AAM_CONTRT+"' "
// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
If (_nStsProc==1) // aberto
	cQuery+="AND Z1_DTFINFA = ' ' "
ElseIf (_nStsProc==2) // encerrado
	cQuery+="AND Z1_DTFINFA != ' ' "
EndIf

cQuery+="AND Z3_PROGRAM BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' "
cQuery+="AND Z3.D_E_L_E_T_ = '' AND Z1.D_E_L_E_T_ = '' "
//NAO FATURAR FRETES DE SAIDA QUANDO O FRETE DE ENTRADA DO CONTAINER JA FOI FATURADO PELO PACOTE LOGISTICO - DANIEL 15/03
//O OBJETIVO DESTE FILTRO E ELIMINAR OS FRETES DE SAIDA ONDE A ENTRADA DO MESMO JA TENHO SIDO FATURADO ANTES DA DATA DE SAIDA
cQuery+="AND CASE WHEN Z3_TPMOVIM = 'S' THEN (SELECT COUNT(*) FROM "+RetSqlName("SZ3")+" Z3T (nolock)  WHERE Z3T.Z3_FILIAL = Z3.Z3_FILIAL AND Z3T.Z3_PROGRAM = Z3.Z3_PROGRAM AND Z3T.Z3_ITEPROG = Z3.Z3_ITEPROG AND Z3T.Z3_CONTAIN = Z3.Z3_CONTAIN AND Z3T.Z3_TPMOVIM = 'E' AND Z3T.D_E_L_E_T_ = '' AND Z3T.Z3_DTFATPA = '') ELSE 1 END > 0 "
cQuery+="ORDER BY Z3_PROGRAM, Z3_ITEPROG, Z3_RIC "

//cQuery := ChangeQuery(cQuery)

If (Select("TRB2") != 0)
	dbSelectArea("TRB2")
	dbCloseArea()
Endif
TCQuery cQuery NEW ALIAS "TRB2"

DbSelectArea("TRB2")
dbgotop()
While TRB2->(!EOF())

	cCt:=AAM->AAM_CONTRT
	cIt:=cItem
	cPrd:=Space(30)

	nTarifa := sfTarifaFrete(@cCt, @cIt, @cPrd, TRB2->Z3_RIC, 'S')

	aTmpMovIt := 	{	TRB2->Z3_PROGRAM,;  		// 1 - Numero da Programacao / Pedido de Venda
			 			TRB2->Z3_ITEPROG,;       	// 2 - Item da Programacao
			 			AAM->AAM_CONTRT,;    		// 3 - Numero do Contrato
		     			cItem,;		        		// 4 - Item do Contrato
		     			cPrdServico,;	     		// 5 - Codigo do Produto Servico
		     			AAM->AAM_CODCLI,; 			// 6 - Codigo do Cliente
			 			AAM->AAM_LOJA,;     		// 7 - Loja do Cliente
			 			1,; 						// 8 - Quantidade
		     			nTarifa,;   				// 9 - Tarifa
					  	nTarifa,;		      		// 10 - Total
					   	dProcIni,;     				// 11 - Data de Processamento Inicial
					   	ddatabase-1,;       		// 12 - Data de Processamento Final
					    TRB2->Z3_CONTAIN,;        	// 13 - Container
					    0,;		         			// 14 - Quantidade de Periodos
		     			0,;        					// 15 - Periodicidade
					    STOD(TRB2->Z3_DTMOVIM),;  	// 16 - Data 1 (Data de Remessa)
			 			CTOD(''),;			 		// 17 - Data 2 (Data de Devolucao)
			 			'',;						// 18 - Numero da OS
			 			'',;      					// 19 - Codigo da Atividade
			 			'S',;				     	// 20 - Faturar Atividade (S/N)
		     			TRB2->Z3_TPMOVIM,;          // 21 - Tipo de Movimento
		     			'',;						// 22 - Operacao
		     			0,;				  			// 23 - Quantidade de Dias Free
					    '',;     					// 24 - Tipo de Armazenagem
					    TRB2->Z3_RIC,;				// 25 - RIC de Entrada
			 			'',;						// 26 - RIC de Saida
			 			TRB2->Z3_PRCORIG,;			// 27 - Praca de Origem
			 			TRB2->Z3_PRCDEST,;			// 28 - Praca de Destino
			 			TRB2->Z3_CONTEUD,;			// 29 - Conteudo do Container
			 			TRB2->Z3_TAMCONT,;			// 30 - Tamanho do Contaier
			 			TRB2->Z3_TRANSP,;			// 31 - Transportadora
			 			'',;						// 32 - Observacoes
			 			Space(8),;					// 33 - Pedido+Item
			 			0,;							// 34 - Valor Total da Nota
				 		'',;						// 35 - Nota de Remessa
				 		'',;						// 36 - Nota de Devolucao
				 		cCt,;			    		// 37 - Numero do Contrato Pacote Logistico
		     			cIt,;		        		// 38 - Item do Contrato Pacote Logistico
		     			cPrd,;		        		// 39 - Produto do Pacote Logistico
		     			.F.,;						// 40 - Linha Deletada .T. / .F.
		     		}

	Aadd(aMovContr,aTmpMovIt)
	Aadd(aTmpMovTo,aTmpMovIt)

	TRB2->(DBSKIP())

ENDDO

sfCarregaTRB(aTmpMovTo,.F.,'','4')

Return(.t.)

Static Function sfOutrosServicos(cItem)

Private aTmpMovIt:= {}
Private aTmpMovTo:= {}
Private cPrdServico	:= CriaVar("B1_COD")

// Verifica dados do contrato se houver
dbSelectArea("AAN")
dbSetOrder(1)
If dbSeek(xFilial("AAN")+AAM->AAM_CONTRT+cItem)
	cPrdServico:=AAN->AAN_CODPRO
EndIf
cItem:=IIf(Empty(cItem),"Z"+"7",cItem)


// MOVIMENTACOES DE ORDEM DE SERVICO
cQuery:="SELECT Z6_DTFINAL, Z6_CONTAIN, Z6_CODIGO, Z6_ITEM, Z7_NUMOS, Z6_TIPOMOV, Z7_CODATIV, Z7_QUANT, Z7_FATURAR, Z7_TIPOPER, CONVERT(VarChar(8000), CONVERT(VarBinary(8000), Z7_OBSERVA)) AS  Z7_OBSERVA, Z6_RIC "
cQuery+="FROM "+RetSqlName("SZ6")+" Z6, "+RetSqlName("SZ7")+" Z7 (nolock) , "+RetSqlName("SZ1")+" Z1 (nolock)  "
cQuery+="WHERE Z6_FILIAL = '"+xfilial("SZ6")+"' AND Z6_FILIAL = Z7_FILIAL AND Z1_FILIAL = Z6_FILIAL AND Z6_NUMOS = Z7_NUMOS AND Z6_CODIGO = Z1_CODIGO "
cQuery+="AND Z6_DTFINAL BETWEEN '"+dtos(dProcIni)+"' AND '"+dtos(ddatabase -1)+"' AND Z6_STATUS IN ('F','P') "
cQuery+="AND Z7_DTFATAT = ' ' "
cQuery+="AND Z6_CLIENTE = '"+AAM->AAM_CODCLI+"' "
cQuery+="AND Z6_LOJA = '"+AAM->AAM_LOJA+"' "
cQuery+="AND Z1_CONTRT = '"+AAM->AAM_CONTRT+"' "
// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
If (_nStsProc==1) // aberto
	cQuery+="AND Z1_DTFINFA = ' ' "
ElseIf (_nStsProc==2) // encerrado
	cQuery+="AND Z1_DTFINFA != ' ' "
EndIf

cQuery+="AND Z6_CODIGO BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' "
cQuery+="AND Z6.D_E_L_E_T_ = ' ' AND Z7.D_E_L_E_T_ = ' ' AND Z1.D_E_L_E_T_ = ' ' "
cQuery+="ORDER BY Z6_CODIGO, Z6_ITEM "

//cQuery := ChangeQuery(cQuery)

If (Select("TRB2") != 0)
	dbSelectArea("TRB2")
	dbCloseArea()
Endif
TCQuery cQuery NEW ALIAS "TRB2"

DbSelectArea("TRB2")
dbgotop()
While TRB2->(!EOF())

	cCt:=AAM->AAM_CONTRT
	cIt:=cItem
	cPrd:=Space(30)

	nQtde	:= TRB2->Z7_QUANT
	nTarifa	:= sfTarifaAtv(@cCt, @cIt, @cPrd, TRB2->Z7_CODATIV, TRB2->Z7_FATURAR, TRB2->Z6_RIC, TRB2->Z6_CODIGO, TRB2->Z6_ITEM)

	aTmpMovIt :=	{	TRB2->Z6_CODIGO,;  		// 1 - Numero da Programacao / Pedido de Venda
				 		TRB2->Z6_ITEM,;       	// 2 - Item da Programacao
				 		AAM->AAM_CONTRT,;      	// 3 - Numero do Contrato
			     		cItem,;      		  	// 4 - Item do Contrato
			     		cPrdServico,;     		// 5 - Codigo do Produto Servico
			     		AAM->AAM_CODCLI,; 		// 6 - Codigo do Cliente
				 		AAM->AAM_LOJA,;     	// 7 - Loja do Cliente
				 		nQtde,;         		// 8 - Quantidade
			     		nTarifa,;   			// 9 - Tarifa
			     		nQtde * nTarifa,;      	// 10 - Total
			     		dProcIni,;     			// 11 - Data de Processamento Inicial
			     		ddatabase-1,;       	// 12 - Data de Processamento Final
			     		TRB2->Z6_CONTAIN,;      // 13 - Container
			     		0,;         			// 14 - Quantidade de Periodos
			     		0,;		                // 15 - Periodicidade
				 		STOD(TRB2->Z6_DTFINAL),;// 16 - Data 1 (Data do Movimento)
				 		CTOD(''),;			 	// 17 - Data 2 ()
				 		TRB2->Z7_NUMOS,;		// 18 - Numero da OS
				 		TRB2->Z7_CODATIV,;      // 19 - Codigo da Atividade
				 		TRB2->Z7_FATURAR,;     	// 20 - Faturar Atividade (S/N)
			     		TRB2->Z6_TIPOMOV,;      // 21 - Tipo de Movimento
			     		TRB2->Z7_TIPOPER,;		// 22 - Operacao
			     		0,;			  			// 23 - Quantidade de Dias Free
						'',;     				// 24 - Tipo de Armazenagem
						'',;					// 25 - RIC de Entrada
				 		'',;					// 26 - RIC de Saida
				 		'',;					// 27 - Praca de Origem
			 			'',;					// 28 - Praca de Destino
			 			'',;					// 29 - Conteudo do Container
			 			'',;					// 30 - Tamanho do Contaier
			 			'',;					// 31 - Transportadora
			 			TRB2->Z7_OBSERVA,;		// 32 - Observacoes
			 			Space(8),;				// 33 - Pedido+Item
			 			0,;						// 34 - Valor Total da Nota
				 		'',;					// 35 - Nota de Remessa
				 		'',;					// 36 - Nota de Devolucao
				 		cCt,;			    	// 37 - Numero do Contrato Pacote Logistico
		     			cIt,;		        	// 38 - Item do Contrato Pacote Logistico
		     			cPrd,;		        	// 39 - Produto do Pacote Logistico
		     			.F.,;					// 40 - Linha Deletada .T. / .F.
			   		}


	Aadd(aMovContr,aTmpMovIt)
	Aadd(aTmpMovTo,aTmpMovIt)

	TRB2->(DBSKIP())

ENDDO

sfCarregaTRB(aTmpMovTo,.F.,'','7')

Return (.t.)

Static Function sfTarifaFrete(cContrt,cItem, cPrd, cRIC, cFatura)

	aAreAAN:=AAN->(GetArea())

	nPreco:=0

	dbSelectArea("SZ3")
	SZ3->(dbOrderNickName("Z3_RIC"))
	SZ3->(dbSeek( xFilial("SZ3")+cRIC ))

	dbSelectArea("AAN")
	dbSetOrder(1)
	If dbSeek(xFilial("AAN")+cContrt+cItem)

		dbSelectArea("SZ5")
		dbSetOrder(1)
		dbSeek(xFilial("SZ5")+AAN->AAN_TABELA)
		While SZ5->(!EOF()) .And. SZ5->Z5_CODIGO == AAN->AAN_TABELA
		    If ((SZ5->Z5_PRCORIG == SZ3->Z3_PRCORIG .And. SZ5->Z5_PRCDEST == SZ3->Z3_PRCDEST) .Or. (SZ5->Z5_PRCORIG == SZ3->Z3_PRCDEST .And. SZ5->Z5_PRCDEST == SZ3->Z3_PRCORIG)) .And. SZ5->Z5_CONTEUD == SZ3->Z3_CONTEUD
		    	nPreco:=SZ5->Z5_VALOR
		    	Exit
		    EndIf
			SZ5->(dbSkip())
		EndDo
	EndIf

	If cFatura == "N"
		nPreco:=0
	EndIf


	dbSelectArea("SZ1")
 	dbSetOrder(1)
    dbSeek(xFilial("SZ1")+SZ3->Z3_PROGRAM)

	dbSelectArea("SZU")
	dbSetOrder(1)
	dbSeek(xFilial("SZU")+cContrt)
	While SZU->(!EOF()) .And. SZU->ZU_CONTRT == cContrt
	    If Posicione("SB1",1,xFilial("SB1")+SZU->ZU_PRODUTO,"B1_TIPOSRV") == "4"
	    	cPraca:=AllTrim(Posicione("AAN",1,xFilial("AAN")+SZU->ZU_CONTRT+SZU->ZU_ITCONTR,"AAN_PRACA"))
	    	cTpCar:=AllTrim(Posicione("AAN",1,xFilial("AAN")+SZU->ZU_CONTRT+SZU->ZU_ITCONTR,"AAN_TIPOCA"))
	    	If ((SZ3->Z3_PRCORIG $ cPraca .OR. SZ3->Z3_PRCDEST $ cPraca) .AND. SZ1->Z1_TIPOCAR == cTpCar) .OR. SZ3->Z3_TPMOVIM == "S"
	    		bCont:=.F.
	    		If SZ3->Z3_TPMOVIM == "S"
	    			nPos:=aScan(aMovContr,{|x| x[1]+x[2]+x[3]+x[4]+x[13] ==SZ3->Z3_PROGRAM+SZ3->Z3_ITEPROG+SZU->ZU_CONTRT+SZU->ZU_ITCONTR+SZ3->Z3_CONTAIN})
					If nPos > 0
						bCont:=.T.
					EndIf
				Else
					bCont:=.T.
				EndIf
				If bCont
		    		nPreco:=0
		    		cContrt:=SZU->ZU_CONTRT
		    		cItem:=SZU->ZU_ITCONTR
		    		cPrd:=SZU->ZU_PRODUTO
		    		RestArea(aAreAAN)
		    		Return(nPreco)
		  		EndIf
	    	EndIf
		EndIf
		SZU->(dbSkip())
	EndDo
    cContrt:=Space(15)
	cItem:=Space(2)

	RestArea(aAreAAN)

Return(nPreco)

Static Function sfTarifaAtv(cContrt, cItem, cPrd, cCodAtv, cFatura, cRic, mvNumProg, mvIteProg )
	// area inicial
	Local _aAreaSZ1 := SZ1->(GetArea())
	// praca da programacao
	Local _cPrcProg := ""
	// praca do pacote logistico
	Local _cPrcPacot := ""
	// seek do SZU
	local _cSeekSZU

	aAreAAN:=AAN->(GetArea())

	nPreco:=0
	dbSelectArea("SZ9")
	dbSetOrder(1)
	If dbSeek(xFilial("SZ9")+cContrt+cItem+cCodAtv)
		nPreco:=SZ9->Z9_VALOR
	Else
		dbSelectArea("SZT")
		dbSetOrder(1)
		dbSeek(xFilial("SZT")+cCodAtv)
		nPreco:=SZT->ZT_VALOR
	EndIf
	If cFatura == "N"
		nPreco:=0
	EndIf

	dbSelectArea("SZ1")
 	dbSetOrder(1)
    dbSeek(xFilial("SZ1")+mvNumProg)

	// pesquisa se faz parte dos itens do pacote logistico
	dbSelectArea("SZU")
	dbSetOrder(1) // 1-ZU_FILIAL, ZU_CONTRT, ZU_ITCONTR, ZU_PRODUTO
	// 08.11.11 - Gustavo - Pesquisa contrato + Item (antes não havia o item)
	dbSeek( _cSeekSZU := xFilial("SZU")+cContrt+cItem )
	// varre os itens do pacote logistico
	While SZU->(!EOF()).and.(SZU->(ZU_FILIAL+ZU_CONTRT+ZU_ITCONTR)==_cSeekSZU)
	    If Posicione("SB1",1,xFilial("SB1")+SZU->ZU_PRODUTO,"B1_TIPOSRV") == "7"
			// praca do pacote logistico (contrato)
			_cPrcPacot	:= AllTrim(Posicione("AAN",1,xFilial("AAN")+SZU->ZU_CONTRT+SZU->ZU_ITCONTR,"AAN_PRACA"))
			_cTpCar	:= AllTrim(Posicione("AAN",1,xFilial("AAN")+SZU->ZU_CONTRT+SZU->ZU_ITCONTR,"AAN_TIPOCA"))
			// pesquisa no item da programacao, para pegar a praca
			_cPrcProg	:= Posicione("SZ2",1,xFilial("SZ2")+mvNumProg+mvIteProg,"Z2_PRCORIG")

			If (_cPrcProg $ _cPrcPacot)  .AND. SZ1->Z1_TIPOCAR == _cTpCar
				dbSelectArea("SZ9")
				dbSetOrder(1)
				If dbSeek(xFilial("SZ9")+SZU->ZU_CONTRT+SZU->ZU_ITCONTR+cCodAtv)
		    		nPreco	:= 0
		    		cContrt	:= SZU->ZU_CONTRT
		    		cItem	:= SZU->ZU_ITCONTR
		    		cPrd	:= SZU->ZU_PRODUTO
		    		RestArea(aAreAAN)
		    		Return(nPreco)
				EndIf
			EndIf
		EndIf
		SZU->(dbSkip())
	EndDo
    cContrt:=Space(15)
	cItem:=Space(2)

	RestArea(aAreAAN)

Return(nPreco)

Static Function sfFixo(cItem)

If Empty(MV_PAR05)
	sfCarregaTRB({},.T.,cItem,'8')
EndIf

Return(.t.)

//** funcao para calculo da armazenagem de container
Static Function sfArmzContainer(cItem)

Private aTmpMovIt:= {}
Private aTmpMovTo:= {}
Private nFormula1 	:= nFormula2 := 0
Private nTarifa		:= 0
Private nPeriodo	:= 1
Private nDayFre		:= 0
Private cTamCont	:= CriaVar("AAN_TAMCON")
Private cPrdServico	:= CriaVar("B1_COD")

// Verifica dados do contrato se houver
dbSelectArea("AAN")
dbSetOrder(1)
If dbSeek(xFilial("AAN")+AAM->AAM_CONTRT+cItem)
	cPrdServico	:= AAN->AAN_CODPRO
	nTarifa		:= AAN->AAN_VLRUNI
	nPeriodo	:= AAN->AAN_QUANT
	nDayFre		:= AAN->AAN_DAYFRE
	cTamCont	:= AAN->AAN_TAMCON
EndIf
cItem:=IIf(Empty(cItem),"Z"+"1",cItem)

// MOVIMENTACOES DE CONTAINER COM DEVOLUCAO
cQuery:="SELECT Z3_DTSAIDA DTDEV, CASE WHEN Z3_DTFATAR <> '' THEN Z3_DTFATAR ELSE Z3_DTMOVIM END DTREM, Z3_CONTAIN, Z3_PROGRAM, Z3_ITEPROG, Z3_RIC, Z3_TAMCONT, Z3_DTFATAR "
cQuery+="FROM "+RetSqlName("SZ3")+" Z3 (nolock) , "+RetSqlName("SZ1")+" Z1 (nolock)  "
cQuery+="WHERE Z3_FILIAL = '"+xfilial("SZ3")+"' AND Z3_FILIAL = Z1_FILIAL AND Z3_PROGRAM = Z1_CODIGO AND Z3_TPMOVIM = 'E' "
cQuery+="AND Z3_DTSAIDA BETWEEN '"+dtos(dProcIni)+"' AND '"+dtos(ddatabase -1)+"' AND (Z3_DTSAIDA > Z3_DTFATAR) "
cQuery+="AND Z3_CLIENTE = '"+AAM->AAM_CODCLI+"' "
cQuery+="AND Z3_LOJA = '"+AAM->AAM_LOJA+"' "
cQuery+="AND Z1_CONTRT = '"+AAM->AAM_CONTRT+"' "
// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
If (_nStsProc==1) // aberto
	cQuery+="AND Z1_DTFINFA = ' ' "
ElseIf (_nStsProc==2) // encerrado
	cQuery+="AND Z1_DTFINFA != ' ' "
EndIf

If !Empty(cTamCont)
	cQuery+="AND Z3_TAMCONT = '"+cTamCont+"' "
EndIf
cQuery+="AND Z3_PROGRAM BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' "
cQuery+="AND Z3.D_E_L_E_T_ = '' AND Z1.D_E_L_E_T_ = '' "

//cQuery := ChangeQuery(cQuery)

If (Select("TRB2") != 0)
	dbSelectArea("TRB2")
	dbCloseArea()
Endif
TCQuery cQuery NEW ALIAS "TRB2"

DbSelectArea("TRB2")
dbgotop()
While TRB2->(!EOF())

	nDayFre		:= IIF(!Empty(TRB2->Z3_DTFATAR),0,AAN->AAN_DAYFRE)

	nFormula1 	:= fPeriodo(STOD(TRB2->DTDEV),STOD(TRB2->DTREM)+nDayFre,nPeriodo)
	nFormula2 	:= fPeriodo(dProcIni-1,STOD(TRB2->DTREM)+nDayFre,nPeriodo)
	nQtde 		:= nFormula1 - nFormula2

	nValPed := nQtde * nTarifa

	If nQtde > 0

		aTmpMovIt := 	{	TRB2->Z3_PROGRAM,;  		// 1 - Numero da Programacao / Pedido de Venda
				 			TRB2->Z3_ITEPROG,;       	// 2 - Item da Programacao
				 			AAM->AAM_CONTRT,;      		// 3 - Numero do Contrato
			     			cItem,;		        		// 4 - Item do Contrato
			     			cPrdServico,;	     		// 5 - Codigo do Produto Servico
			     			AAM->AAM_CODCLI,; 			// 6 - Codigo do Cliente
				 			AAM->AAM_LOJA,;     		// 7 - Loja do Cliente
				 			nQtde,; 					// 8 - Quantidade
			     			nTarifa,;   				// 9 - Tarifa
						  	nQtde * nTarifa,;      		// 10 - Total
						   	dProcIni,;     				// 11 - Data de Processamento Inicial
						   	ddatabase-1,;       		// 12 - Data de Processamento Final
						    TRB2->Z3_CONTAIN,;        	// 13 - Container
						    nQtde,;         			// 14 - Quantidade de Periodos
			     			nPeriodo,; 			       	// 15 - Periodicidade
						    STOD(TRB2->DTREM),;      	// 16 - Data 1 (Data de Remessa)
				 			STOD(TRB2->DTDEV),; 		// 17 - Data 2 (Data de Devolucao)
				 			'',;						// 18 - Numero da OS
				 			'',;      					// 19 - Codigo da Atividade
				 			'S',;				     	// 20 - Faturar Atividade (S/N)
			     			'',;			            // 21 - Tipo de Movimento
			     			'',;						// 22 - Operacao
			     			nDayFre,;		  			// 23 - Quantidade de Dias Free
						    '5',;						// 24 - Tipo de Armazenagem
						    TRB2->Z3_RIC,;				// 25 - RIC de Entrada
				 			'',;						// 26 - RIC de Saida
				 			'',;						// 27 - Praca de Origem
				 			'',;						// 28 - Praca de Destino
				 			'',;						// 29 - Conteudo do Container
				 			TRB2->Z3_TAMCONT,;			// 30 - Tamanho do Contaier
				 			'',;						// 31 - Transportadora
				 			'',;						// 32 - Observacoes
				 			Space(8),;					// 33 - Pedido+Item
			 				0,;							// 34 - Valor Total da Nota
				 			'',;						// 35 - Nota de Remessa
				 			'',;						// 36 - Nota de Devolucao
				 			'',;			    		// 37 - Numero do Contrato Pacote Logistico
		     				'',;		        		// 38 - Item do Contrato Pacote Logistico
		     				'',;			        	// 39 - Produto do Pacote Logistico
		     				.F.,;						// 40 - Linha Deletada .T. / .F.
			     		}

			Aadd(aMovContr,aTmpMovIt)
			Aadd(aTmpMovTo,aTmpMovIt)

	EndIf

	TRB2->(DBSKIP())

ENDDO

// MOVIMENTOS DE CONTAINER NAO DEVOLVIDOS
cQuery:="SELECT Z3_DTSAIDA DTDEV, CASE WHEN Z3_DTFATAR <> '' THEN Z3_DTFATAR ELSE Z3_DTMOVIM END DTREM, Z3_CONTAIN, Z3_PROGRAM, Z3_ITEPROG, Z3_RIC, Z3_TAMCONT, Z3_DTFATAR "
cQuery+="FROM "+RetSqlName("SZ3")+" Z3 (nolock) , "+RetSqlName("SZ1")+" Z1 (nolock)  "
cQuery+="WHERE Z3_FILIAL = '"+xfilial("SZ3")+"' AND Z3_FILIAL = Z1_FILIAL AND Z3_PROGRAM = Z1_CODIGO AND Z3_TPMOVIM = 'E' AND Z3_DTSAIDA = '' "
cQuery+="AND Z3_DTMOVIM <= '"+dtos(ddatabase -1)+"' "
cQuery+="AND Z3_CLIENTE = '"+AAM->AAM_CODCLI+"' "
cQuery+="AND Z3_LOJA = '"+AAM->AAM_LOJA+"' "
cQuery+="AND Z1_CONTRT = '"+AAM->AAM_CONTRT+"' "

// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
If (_nStsProc==1) // aberto
	cQuery+="AND Z1_DTFINFA = ' ' "
ElseIf (_nStsProc==2) // encerrado
	cQuery+="AND Z1_DTFINFA != ' ' "
EndIf

If !Empty(cTamCont)
	cQuery+="AND Z3_TAMCONT = '"+cTamCont+"' "
EndIf

cQuery+="AND Z3_PROGRAM BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' "
cQuery+="AND Z3.D_E_L_E_T_ = '' AND Z1.D_E_L_E_T_ = '' "
cQuery := ChangeQuery(cQuery)
If (Select("TRB2") != 0)
	dbSelectArea("TRB2")
	dbCloseArea()
Endif
TCQuery cQuery NEW ALIAS "TRB2"

DbSelectArea("TRB2")
dbgotop()
While TRB2->(!EOF())

	nDayFre		:= IIF(!Empty(TRB2->Z3_DTFATAR),0,AAN->AAN_DAYFRE)

	nFormula1 	:= fPeriodo(ddatabase -1,STOD(TRB2->DTREM)+nDayFre,nPeriodo)
	nFormula2 	:= fPeriodo(dProcIni-1,STOD(TRB2->DTREM)+nDayFre,nPeriodo)
	nQtde 		:= nFormula1 - nFormula2

	nValPed := nQtde * nTarifa

	If nQtde > 0

		aTmpMovIt := 	{	TRB2->Z3_PROGRAM,;  		// 1 - Numero da Programacao / Pedido de Venda
				 			TRB2->Z3_ITEPROG,;       	// 2 - Item da Programacao
				 			AAM->AAM_CONTRT,;      		// 3 - Numero do Contrato
			     			cItem,;      	  			// 4 - Item do Contrato
			     			cPrdServico,;   	  		// 5 - Codigo do Produto Servico
			     			AAM->AAM_CODCLI,; 			// 6 - Codigo do Cliente
				 			AAM->AAM_LOJA,;     		// 7 - Loja do Cliente
				 			1,; 						// 8 - Quantidade
			     			nTarifa,;   				// 9 - Tarifa
						  	nQtde * nTarifa,;      		// 10 - Total
						   	dProcIni,;     				// 11 - Data de Processamento Inicial
						   	ddatabase-1,;       		// 12 - Data de Processamento Final
						    TRB2->Z3_CONTAIN,;        	// 13 - Container
						    nQtde,;         			// 14 - Quantidade de Periodos
			     			nPeriodo,;		        	// 15 - Periodicidade
						    STOD(TRB2->DTREM),;      	// 16 - Data 1 (Data de Remessa)
				 			STOD(TRB2->DTDEV),; 		// 17 - Data 2 (Data de Devolucao)
				 			'',;						// 18 - Numero da OS
				 			'',;      					// 19 - Codigo da Atividade
				 			'S',;				     	// 20 - Faturar Atividade (S/N)
			     			'',;			            // 21 - Tipo de Movimento
			     			'',;						// 22 - Operacao
			     			nDayFre,;		  			// 23 - Quantidade de Dias Free
						    '5',;		     			// 24 - Tipo de Armazenagem
						    TRB2->Z3_RIC,;				// 25 - RIC de Entrada
				 			'',;						// 26 - RIC de Saida
				 			'',;						// 27 - Praca de Origem
			 				'',;						// 28 - Praca de Destino
			 				'',;						// 29 - Conteudo do Container
			 				TRB2->Z3_TAMCONT,;			// 30 - Tamanho do Contaier
			 				'',;						// 31 - Transportadora
			 				'',;						// 32 - Observacoes
			 				Space(8),;					// 33 - Pedido+Item
			 				0,;							// 34 - Valor Total da Nota
				 			'',;						// 35 - Nota de Remessa
				 			'',;						// 36 - Nota de Devolucao
				 			'',;			    		// 37 - Numero do Contrato Pacote Logistico
		     				'',;		        		// 38 - Item do Contrato Pacote Logistico
		     				'',;			        	// 39 - Produto do Pacote Logistico
		     				.F.,;						// 40 - Linha Deletada .T. / .F.
			     		}

			Aadd(aMovContr,aTmpMovIt)
			Aadd(aTmpMovTo,aTmpMovIt)

	EndIf
	TRB2->(DBSKIP())

ENDDO

sfCarregaTRB(aTmpMovTo,.F.,'','1')

Return(.t.)

//** funcao para calculo da armazenagem de produtos
Static Function sfArmzProduto(cItem)
	// area inicial
	local _aAreaAtu := GetArea()
	// controle de validacao
	local _lRet := .t.


Private aTmpMovIt:= {}
Private aTmpMovTo:= {}
Private nFormula1 	:= nFormula2 := 0
Private nTarifa		:= 0
Private nPeriodo	:= 1
Private nDayFre		:= 0
//Private cTipoAr		:= CriaVar("AAN_TIPOAR") // desabilitado gustavo 03/02/11
Private cTipoAr		:= If(Empty(cItem),"3",CriaVar("AAN_TIPOAR"))
Private cPrdServico	:= CriaVar("B1_COD")

// Verifica dados do contrato se houver
dbSelectArea("AAN")
dbSetOrder(1)
If dbSeek(xFilial("AAN")+AAM->AAM_CONTRT+cItem)
	cPrdServico	:= AAN->AAN_CODPRO
	nTarifa		:= AAN->AAN_VLRUNI
	nPeriodo	:= AAN->AAN_QUANT
	nDayFre		:= AAN->AAN_DAYFRE
	cTipoAr		:= AAN->AAN_TIPOAR
EndIf
cItem:=IIf(Empty(cItem),"Z"+"2",cItem)

// prepara a query
cQuery := "SELECT DISTINCT F1_DTDIGIT, F1_EMISSAO, D1_DOC, D1_SERIE, D1_PROGRAM, D1_ITEPROG, F1_DTFATPR, F1_CUBAGEM, F1_PBRUTO, "
// busca a referencia da entrada de container cheio
cQuery += "(SELECT MIN(Z3_DTMOVIM) FROM "+RetSqlName("SZ3")+" (nolock)  WHERE Z3_FILIAL = D1_FILIAL AND Z3_PROGRAM = D1_PROGRAM AND Z3_ITEPROG = D1_ITEPROG "
cQuery += " AND Z3_TPMOVIM = 'E' AND D_E_L_E_T_ <> '*' "
// 08.09.11 - Toni - Somente Container Cheio
cQuery += " AND Z3_CONTEUD = 'C') AS DTREF "
// tabelas
cQuery += "FROM "+RetSqlName("SD1")+" D1 (nolock) , "+RetSqlName("SZ1")+" Z1 (nolock) , "+RetSqlName("SF1")+" F1 (nolock)  "
cQuery += "WHERE D1_FILIAL = F1_FILIAL AND D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE AND D1_LOJA = F1_LOJA AND D1_FORNECE = F1_FORNECE AND "
cQuery += "D1_FILIAL = '"+xfilial("SD1")+"' AND D1_FILIAL = Z1_FILIAL AND D1_PROGRAM = Z1_CODIGO "
cQuery += "AND D1_FORNECE = '"+AAM->AAM_CODCLI+"' "
cQuery += "AND D1_LOJA = '"+AAM->AAM_LOJA+"' "
cQuery += "AND D1_PROGRAM BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' AND D1_PROGRAM <> '' AND D1_TIPO = 'B' "
cQuery += "AND Z1_CONTRT = '"+AAM->AAM_CONTRT+"' "
// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
If (_nStsProc==1) // aberto
	cQuery+="AND Z1_DTFINFA = ' ' "
ElseIf (_nStsProc==2) // encerrado
	cQuery+="AND Z1_DTFINFA != ' ' "
EndIf

cQuery += "AND F1_DTDIGIT BETWEEN '"+dtos(dProcIni)+"' AND '"+dtos(ddatabase -1)+"' "
cQuery += "AND D1.D_E_L_E_T_ = ' ' "
cQuery += "AND Z1.D_E_L_E_T_ = ' ' "
cQuery += "AND F1.D_E_L_E_T_ = ' ' "
//cQuery := ChangeQuery(cQuery)

If (Select("_QRYARMPRD") != 0)
	dbSelectArea("_QRYARMPRD")
	dbCloseArea()
Endif
TCQuery cQuery NEW ALIAS "_QRYARMPRD"

DbSelectArea("_QRYARMPRD")
dbgotop()
While _QRYARMPRD->(!EOF())

	// define a menor data como referencia (data de digitacao da nota (F1_DTDIGIT) ou data de entrada no gate (SZ3))
	dDtRef := STOD(IIf(Empty(_QRYARMPRD->DTREF),_QRYARMPRD->F1_DTDIGIT,_QRYARMPRD->DTREF))

	// se a data de entrada da mercadoria (SZ3) for menor que a digitacao da nota
	//If (StoD(_QRYARMPRD->F1_DTDIGIT) < dDtRef) desabilitado em 05.09.11
	//	dDtRef := STOD(_QRYARMPRD->F1_DTDIGIT)
	//EndIf

	// se nao teve faturamento de armazenagem, adiciona Days Free
	If (Empty(_QRYARMPRD->F1_DTFATPR))
		dDtRef += nDayFre
	// verifica a ultima data de faturamento de armazenagem
	ElseIf (!Empty(_QRYARMPRD->F1_DTFATPR)).and.(StoD(_QRYARMPRD->F1_DTFATPR) > dDtRef)
		dDtRef := StoD(_QRYARMPRD->F1_DTFATPR)
	EndIf

/*
	dDtRef:=STOD(IIf(Empty(_QRYARMPRD->DTREF),_QRYARMPRD->F1_DTDIGIT,_QRYARMPRD->DTREF))+nDayFre
	dDtFat:=STOD(_QRYARMPRD->F1_DTFATPR)
	If !Empty(dDtFat) .AND. dDtFat > dDtRef
		dDtRef:=dDtFat
	EndIf
*/

	nT := fPeriodo(dDatabase - 1, dDtRef,nPeriodo)

	For i := 1 To nT

		dDtProx := dDtRef + (i-1) * nPeriodo

/*
		If i == 1 .And. dDtProx <= STOD(_QRYARMPRD->F1_EMISSAO)
			nSaldo := sfSaldoPrd (STOD(_QRYARMPRD->F1_EMISSAO), AAM->AAM_CODCLI,AAM->AAM_LOJA,_QRYARMPRD->D1_DOC, _QRYARMPRD->D1_SERIE, cTipoAr, _QRYARMPRD->F1_CUBAGEM, _QRYARMPRD->F1_PBRUTO,@_lRet)
		Else
			nSaldo := sfSaldoPrd  (dDtProx, AAM->AAM_CODCLI,AAM->AAM_LOJA,_QRYARMPRD->D1_DOC, _QRYARMPRD->D1_SERIE, cTipoAr, _QRYARMPRD->F1_CUBAGEM, _QRYARMPRD->F1_PBRUTO,@_lRet)
		EndIf
*/

		// busca o saldo do produto (para saldo de quant, peso ou cubagem sempre passar mvFisrt como .f.)
		nSaldo := sfSaldoValor(dDtProx, AAM->AAM_CODCLI,AAM->AAM_LOJA,_QRYARMPRD->D1_DOC, _QRYARMPRD->D1_SERIE, cTipoAr, .f., @_lRet)

		//MsgStop(nSaldo)
		//MsgStop(asdass)

		// se cancelou, encerra
		If (!_lRet)
			Return(.f.)
		EndIf

		If (dDtRef <= (dDatabase - 1)).and.(nSaldo > 0)

			aTmpMovIt := 	{	_QRYARMPRD->D1_PROGRAM,;  		// 1 - Numero da Programacao / Pedido de Venda
					 			_QRYARMPRD->D1_ITEPROG,;       	// 2 - Item da Programacao
					 			AAM->AAM_CONTRT,;      		// 3 - Numero do Contrato
				     			cItem,;		        		// 4 - Item do Contrato
				     			cPrdServico,; 	    		// 5 - Codigo do Produto Servico
				     			AAM->AAM_CODCLI,; 			// 6 - Codigo do Cliente
					 			AAM->AAM_LOJA,;     		// 7 - Loja do Cliente
					 			nSaldo,;					// 8 - Quantidade
				     			nTarifa,;   				// 9 - Tarifa
							  	If(AAM->AAM_CODCLI=="000087" , (nSaldo * nTarifa) , (nSaldo * nTarifa * nPeriodo) ),;	 	// 10 - Total
							   	STOD(IIf(Empty(_QRYARMPRD->DTREF),_QRYARMPRD->F1_DTDIGIT,_QRYARMPRD->DTREF)),;    				// 11 - Data de Processamento Inicial
							   	ddatabase-1,;       		// 12 - Data de Processamento Final
							    '',;		 		       	// 13 - Container / Produto
							    i,; 	     		  		// 14 - Quantidade de Periodos
				     			nPeriodo,;		         	// 15 - Periodicidade
							    STOD(IIf(Empty(_QRYARMPRD->DTREF),_QRYARMPRD->F1_DTDIGIT,_QRYARMPRD->DTREF)),;// 16 - Data 1 (Data de Remessa)
					 			dDtProx,;			 		// 17 - Data 2 (Data de Devolucao)
					 			'',;						// 18 - Numero da OS
					 			'',;      					// 19 - Codigo da Atividade
					 			'S',;				     	// 20 - Faturar Atividade (S/N)
				     			'',;			            // 21 - Tipo de Movimento
				     			'',;						// 22 - Operacao
				     			nDayFre,;		  			// 23 - Quantidade de Dias Free
							    cTipoAr,;					// 24 - Tipo de Armazenagem
							    '',;						// 25 - RIC de Entrada
					 			'',;						// 26 - RIC de Saida
					 			'',;						// 27 - Praca de Origem
				 				'',;						// 28 - Praca de Destino
				 				'',;						// 29 - Conteudo do Container
				 				'',;						// 30 - Tamanho do Contaier
				 				'',;						// 31 - Transportadora
				 				'',;						// 32 - Observacoes
				 				Space(8),;					// 33 - Pedido+Item
				 				0,;							// 34 - Valor Total da Nota
					 			_QRYARMPRD->D1_DOC+_QRYARMPRD->D1_SERIE,;// 35 - Nota de Remessa
					 			'',;						// 36 - Nota de Devolucao
					 			'',;			    		// 37 - Numero do Contrato Pacote Logistico
			     				'',;		        		// 38 - Item do Contrato Pacote Logistico
			     				'',;		        		// 39 - Produto do Pacote Logistico
			     				.F.,;						// 40 - Linha Deletada .T. / .F.
				     		}

				Aadd(aMovContr,aTmpMovIt)
				Aadd(aTmpMovTo,aTmpMovIt)

		EndIf

	Next i

	// proximo item
	_QRYARMPRD->(DBSKIP())

ENDDO

// fecha alias da query
dbSelectArea("_QRYARMPRD")
dbCloseArea()

// carrega valores no TRB
sfCarregaTRB(aTmpMovTo,.F.,'','2')

// restaura area inicial
RestArea(_aAreaAtu)

Return()

//** funcao responsavel pelo calculo do seguro
Static Function sfSeguro(cItem)
	// variavel para controle do primeiro faturamento de seguro
	local _lFirst := .f.

Private aTmpMovIt:= {}
Private aTmpMovTo:= {}
Private nTarifa		:= 0
Private cPrdServico	:= CriaVar("B1_COD")

// Verifica dados do contrato se houver
dbSelectArea("AAN")
dbSetOrder(1)
If dbSeek(xFilial("AAN")+AAM->AAM_CONTRT+cItem)
	nTarifa:=AAN->AAN_VLRUNI
	cPrdServico:=AAN->AAN_CODPRO
EndIf
cItem:=IIf(Empty(cItem),"Z"+"5",cItem)

cQuery:="SELECT DISTINCT F1_DTDIGIT, F1_EMISSAO, D1_DOC, D1_SERIE, D1_PROGRAM, D1_ITEPROG, F1_DTFATSE, "
cQuery+="(SELECT MIN(Z3_DTMOVIM) FROM "+RetSqlName("SZ3")+" (nolock)  WHERE Z3_FILIAL = D1_FILIAL AND Z3_PROGRAM = D1_PROGRAM AND Z3_ITEPROG = D1_ITEPROG AND Z3_TPMOVIM = 'E' AND D_E_L_E_T_ <> '*') AS DTREF "
cQuery+="FROM "+RetSqlName("SD1")+" D1 (nolock) , "+RetSqlName("SZ1")+" Z1 (nolock) , "+RetSqlName("SF1")+" F1 (nolock)  "
cQuery+="WHERE D1_FILIAL = F1_FILIAL AND D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE AND D1_LOJA = F1_LOJA AND D1_FORNECE = F1_FORNECE AND "
cQuery+="D1_FILIAL = '"+xfilial("SD1")+"' AND D1_FILIAL = Z1_FILIAL AND D1_PROGRAM = Z1_CODIGO "
cQuery+="AND D1_FORNECE = '"+AAM->AAM_CODCLI+"' "
cQuery+="AND D1_LOJA = '"+AAM->AAM_LOJA+"' "
cQuery+="AND D1_PROGRAM BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' AND D1_PROGRAM <> '' AND D1_TIPO = 'B' "
cQuery+="AND Z1_CONTRT = '"+AAM->AAM_CONTRT+"' "
// status do processo (1-Aberto, 2-Encerrado, 3-Ambos)
If (_nStsProc==1) // aberto
	cQuery+="AND Z1_DTFINFA = ' ' "
ElseIf (_nStsProc==2) // encerrado
	cQuery+="AND Z1_DTFINFA != ' ' "
EndIf

cQuery+="AND F1_DTDIGIT BETWEEN '"+dtos(dProcIni)+"' AND '"+dtos(ddatabase -1)+"' "
cQuery+="AND D1.D_E_L_E_T_ = ' ' "
cQuery+="AND Z1.D_E_L_E_T_ = ' ' "
cQuery+="AND F1.D_E_L_E_T_ = ' ' "
cQuery := ChangeQuery(cQuery)
If (Select("_QRYSEGUR") != 0)
	dbSelectArea("_QRYSEGUR")
	dbCloseArea()
Endif
TCQuery cQuery NEW ALIAS "_QRYSEGUR"

DbSelectArea("_QRYSEGUR")
dbgotop()
While _QRYSEGUR->(!EOF())

	// define a menor data como referencia (data de digitacao da nota (F1_DTDIGIT) ou data de entrada no gate (SZ3))
	dDtRef := STOD( IIf(Empty(_QRYSEGUR->DTREF),_QRYSEGUR->F1_DTDIGIT,_QRYSEGUR->DTREF) )

	// se a data de entrada da mercadoria (SZ3) for menor que a digitacao da nota
	//If (StoD(_QRYSEGUR->F1_DTDIGIT) < dDtRef) desabilitado em 05.09.11
	//	dDtRef := STOD(_QRYSEGUR->F1_DTDIGIT)
	//EndIf

	// verifica a ultima data de faturamento de seguros
	If (!Empty(_QRYSEGUR->F1_DTFATSE)).and.(StoD(_QRYSEGUR->F1_DTFATSE) > dDtRef)
		dDtRef := StoD(_QRYSEGUR->F1_DTFATSE)
	EndIf

	// define os dias que compoe o periodo de cobranca
	nPeriodo := 30

	// calcula a quantidade de periodos
	nT := fPeriodo(dDatabase - 1, dDtRef,nPeriodo)

	For i := 1 To nT

		// calcula a data de referencia
		dDtProx := dDtRef+(i-1)*nPeriodo

		// verifica se eh o primeiro faturamento do seguro
		_lFirst := (Empty(_QRYSEGUR->F1_DTFATSE)).and.(i==1)

		// calcula o saldo em aberto
		nSaldo := sfSaldoValor(dDtProx, AAM->AAM_CODCLI,AAM->AAM_LOJA,_QRYSEGUR->D1_DOC, _QRYSEGUR->D1_SERIE, 'V', _lFirst)

		// se tem saldo a faturar
		If dDtRef  <= (dDatabase - 1) .And. (nSaldo > 0)

			aTmpMovIt := 	{	_QRYSEGUR->D1_PROGRAM,;  		// 1 - Numero da Programacao / Pedido de Venda
					 			_QRYSEGUR->D1_ITEPROG,;       	// 2 - Item da Programacao
					 			AAM->AAM_CONTRT,;      		// 3 - Numero do Contrato
				     			cItem,;       		 		// 4 - Item do Contrato
				     			cPrdServico,;     			// 5 - Codigo do Produto Servico
				     			AAM->AAM_CODCLI,; 			// 6 - Codigo do Cliente
					 			AAM->AAM_LOJA,;     		// 7 - Loja do Cliente
					 			1,;							// 8 - Quantidade
				     			nTarifa,; 	// 9 - Tarifa
							  	Round((nSaldo * nTarifa)/100,2),;	// 10 - Total
							   	STOD(IIf(Empty(_QRYSEGUR->DTREF),_QRYSEGUR->F1_DTDIGIT,_QRYSEGUR->DTREF)),;     				// 11 - Data de Processamento Inicial
							   	ddatabase-1,;       		// 12 - Data de Processamento Final
							    '',;		 		       	// 13 - Container / Produto
							    i,;	    	     			// 14 - Quantidade de Periodos
				     			nPeriodo,;			        	// 15 - Periodicidade
							    STOD(IIf(Empty(_QRYSEGUR->DTREF),_QRYSEGUR->F1_DTDIGIT,_QRYSEGUR->DTREF)),;// 16 - Data 1 (Data de Remessa)
					 			dDtProx,;			 		// 17 - Data 2 (Data de Devolucao)
					 			'',;						// 18 - Numero da OS
					 			'',;      					// 19 - Codigo da Atividade
					 			'S',;				     	// 20 - Faturar Atividade (S/N)
				     			'',;			            // 21 - Tipo de Movimento
				     			'',;						// 22 - Operacao
				     			0,;				  			// 23 - Quantidade de Dias Free
							    '',;						// 24 - Tipo de Armazenagem
							    '',;						// 25 - RIC de Entrada
					 			'',;						// 26 - RIC de Saida
					 			'',;						// 27 - Praca de Origem
						 		'',;						// 28 - Praca de Destino
						 		'',;						// 29 - Conteudo do Container
						 		'',;						// 30 - Tamanho do Contaier
						 		'',;						// 31 - Transportadora
						 		'',;						// 32 - Observacoes
						 		Space(8),;					// 33 - Pedido+Item
						 		nSaldo,;		  			// 34 - Valor Total da Nota
						 		_QRYSEGUR->D1_DOC+_QRYSEGUR->D1_SERIE,;// 35 - Nota de Remessa
						 		'',;						// 36 - Nota de Devolucao
						 		'',;			    		// 37 - Numero do Contrato Pacote Logistico
					     		'',;		        		// 38 - Item do Contrato Pacote Logistico
					    		'',;		    	    	// 39 - Produto do Pacote Logistico
					     		.F.,;						// 40 - Linha Deletada .T. / .F.
				     		}

			Aadd(aMovContr,aTmpMovIt)
			Aadd(aTmpMovTo,aTmpMovIt)

		EndIf

	Next i

	_QRYSEGUR->(DBSKIP())

ENDDO

sfCarregaTRB(aTmpMovTo,.F.,'','5')

Return()


Static Function sfCarregaTRB(aMovT,bFixo,cItem,cTmpSrv)

cTxtSrv:=""
Do Case
	Case cTmpSrv == "1"
		cTxtSrv:="<< ARMAZENAGEM CONTAINER >>"
	Case cTmpSrv == "2"
		cTxtSrv:="<< ARMAZENAGEM PRODUTO >>"
	Case cTmpSrv == "3"
		cTxtSrv:="<< PACOTE LOGISTICO >>"
	Case cTmpSrv == "4"
		cTxtSrv:="<< FRETE >>"
	Case cTmpSrv == "5"
		cTxtSrv:="<< SEGURO >>"
	Case cTmpSrv == "7"
		cTxtSrv:="<< ORDEM DE SERVICO >>"
EndCase

If len(aMovT) == 0 .And. bFixo

	Private cPrdServico	:= CriaVar("B1_COD")
    Private nValPed		:= 0

	// Verifica dados do contrato se houver
	dbSelectArea("AAN")
	dbSetOrder(1)
	If dbSeek(xFilial("AAN")+AAM->AAM_CONTRT+cItem)
		nValPed:=AAN->AAN_VLRUNI
		cPrdServico:=AAN->AAN_CODPRO
		cTxtSrv:=AAN->AAN_ZDESCR
	EndIf

	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	(_TRBMOV)->(RecLock(_TRBMOV,.T.))
	(_TRBMOV)->IT_OK := ""
	(_TRBMOV)->Z2_CODIGO := Space(6)
	(_TRBMOV)->Z2_ITEM := Space(2)
	(_TRBMOV)->AAN_CONTRT := AAM->AAM_CONTRT
	(_TRBMOV)->AAN_ITEM := cItem
	(_TRBMOV)->AAN_CODPRO := cPrdServico
	(_TRBMOV)->A1_COD := AAM->AAM_CODCLI
	(_TRBMOV)->A1_LOJA := AAM->AAM_LOJA
	(_TRBMOV)->A1_NREDUZ := AllTrim(Posicione("SA1",1,xFilial("SA1")+AAM->AAM_CODCLI+AAM->AAM_LOJA,"A1_NREDUZ"))
	(_TRBMOV)->B1_DESC := cTxtSrv
	(_TRBMOV)->AAN_VALOR := nValPed
	(_TRBMOV)->C6_NUM := ""
	(_TRBMOV)->C6_ITEM := ""
	(_TRBMOV)->B1_TIPOSRV := cTmpSrv
	(_TRBMOV)->AAN_DATA := sfUltimaData(AAM->AAM_CONTRT,cItem,cPrdServico)
	(_TRBMOV)->(MsUnlock())
	Return(.t.)
EndIf

For i:=1 To Len(aMovT)

	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	(_TRBMOV)->(dbSetOrder(1))
	If Empty(aMovT[i,37])
		If !(_TRBMOV)->(dbSeek(aMovT[i,6]+aMovT[i,7]+aMovT[i,1]+aMovT[i,2]+aMovT[i,5]+aMovT[i,3]+aMovT[i,4]))
			// Verifica dados do contrato se houver
			dbSelectArea("AAN")
			dbSetOrder(1)
			If dbSeek(xFilial("AAN")+aMovT[i,3]+aMovT[i,4])
				cTxtSrv:=AAN->AAN_ZDESCR
			EndIf
			(_TRBMOV)->(RecLock(_TRBMOV,.T.))
			(_TRBMOV)->IT_OK		:= ""
			(_TRBMOV)->Z2_CODIGO	:= aMovT[i,1]
			(_TRBMOV)->Z2_ITEM	:= aMovT[i,2]
			(_TRBMOV)->AAN_CONTRT	:= aMovT[i,3]
			(_TRBMOV)->AAN_ITEM	:= aMovT[i,4]
			(_TRBMOV)->AAN_CODPRO	:= aMovT[i,5]
			(_TRBMOV)->A1_COD		:= aMovT[i,6]
			(_TRBMOV)->A1_LOJA	:= aMovT[i,7]
			(_TRBMOV)->A1_NREDUZ	:= AllTrim(Posicione("SA1",1,xFilial("SA1")+aMovT[i,6]+aMovT[i,7],"A1_NREDUZ"))
			(_TRBMOV)->B1_DESC	:= cTxtSrv
			If cTmpSrv == "3"
				(_TRBMOV)->AAN_QUANT	:= aMovT[i, 8]	// QUANTIDADE
				(_TRBMOV)->AAN_VLRUNI	:= aMovT[i, 9]	// VLR UNITARIO
				(_TRBMOV)->AAN_VALOR	:= aMovT[i,10] 	// VLR TOTAL
			Else
				(_TRBMOV)->AAN_QUANT	:= 1			// QUANTIDADE
				(_TRBMOV)->AAN_VLRUNI	:= aMovT[i,10]	// VLR UNITARIO
				(_TRBMOV)->AAN_VALOR	:= aMovT[i,10] 	// VLR TOTAL
			EndIf
			(_TRBMOV)->C6_NUM		:= ""
			(_TRBMOV)->C6_ITEM	:= ""
			(_TRBMOV)->B1_TIPOSRV := cTmpSrv
			(_TRBMOV)->AAN_DATA	:= sfUltimaData(aMovT[i,3],aMovT[i,4],aMovT[i,5])
			(_TRBMOV)->(MsUnlock())
		Else
			(_TRBMOV)->(RecLock(_TRBMOV,.F.))
			// soh atualiza (soma) quantidade, quando houver valor
			If (aMovT[i, 9]>0)
				If cTmpSrv == "3"
					(_TRBMOV)->AAN_QUANT	+= aMovT[i, 8]	// QUANTIDADE
					(_TRBMOV)->AAN_VALOR	+= aMovT[i,10] 	// VLR TOTAL
				Else
					(_TRBMOV)->AAN_VLRUNI	+= aMovT[i,10]
					(_TRBMOV)->AAN_VALOR	+= aMovT[i,10] 	// VLR TOTAL
				EndIf
			EndIf
			(_TRBMOV)->(MsUnlock())
		EndIf
	EndIf

Next i

Return(.t.)

Static Function sfUltimaData(cContrt,cIt,cPrd)

	cQuery := "SELECT MAX(ZR_DATA) DTFAT FROM "+RetSqlName("SZR")+" (nolock)  WHERE ZR_CONTRT = '"+cContrt+"' AND ZR_ITEM = '"+cIt+"' AND ZR_CODSRV = '"+cPrd+"' AND D_E_L_E_T_ <> '*' "
	if !Empty(Select("TRB"))
	   dbSelectArea("TRB")
	   dbCloseArea()
	endif
	TCQuery cQuery NEW ALIAS "TRB"
	dbSelectArea("TRB")
	dUltFat:=STOD(TRB->DTFAT)

Return(dUltFat)

Static Function sfQuantReal(nQuant,cProd)

	dbSelectArea("SB1")
	dbSetOrder(1)
	dbSeek(xFilial("SB1")+cProd)

	dbSelectArea("SB5")
	dbSetOrder(1)
	dbSeek(xFilial("SB5")+cProd)

	Do Case
		Case AAN->AAN_TIPOAR == "1"
			nQuant:=nQuant * (SB5->B5_ALTURLC*SB5->B5_LARGLC*SB5->B5_COMPRLC)
		Case AAN->AAN_TIPOAR == "2"
			nQuant:=nQuant * SB1->B1_PESBRU
		Case AAN->AAN_TIPOAR == "3"
			nQuant:=nQuant
		Case AAN->AAN_TIPOAR == "4"
			nQuant:=nQuant
			nTarifa:=0
	EndCase

Return nQuant


Static Function sfMediaArmaz(dIni,dFim,cCliente,cLoja)

Local nDias	:= dFim-dIni+1
Local nSoma	:= 0
Local nMedia	:= 0
Local dDia	:= dIni
// peso bruto total de devolucoes
local _nTotPesBru := 0
// cubagem total de devolucoes
local _nTotCubag := 0

Default dIni	:= iif(dIni = ctod("  /  /  "),AAN->AAN_INICOB,dIni)

For _n:=1 to nDias
	nSoma	+= sfSaldoArmaz(dDia,cCliente,cLoja)
	dDia	++
Next

nMedia	:= nSoma / nDias

Return(nMedia)

Static Function sfSaldoPrd(dDia,cCliente,cLoja,cnota,cserie,cTp,nCub,nPeso,mvRet)

cQuery := "SELECT * FROM "+RetSqlName("SB6")+" (nolock)  WHERE B6_FILIAL = '"+XFILIAL("SB6")+"' AND B6_DOC = '"+CNOTA+"' AND B6_SERIE = '"+CSERIE+"' AND B6_CLIFOR = '"+CCLIENTE+"' AND B6_LOJA = '"+CLOJA+"' AND "
cQuery += "B6_TIPO='D' AND B6_TPCF='C' AND B6_PODER3='R' AND D_E_L_E_T_ = '' "
cQuery := ChangeQuery(cQuery)
If Select("TRB") <> 0
	dbSelectarea("TRB")
	dbCloseArea("TRB")
End

//TCQuery Abre uma workarea com o resultado da query
TCQUERY cQuery ALIAS TRB NEW

nRes:=0
cPed:=""
nQt:=0
nQtE:=0
nSaldo:=0
dDia-=1 //Daniel 20/04 solicitou via email para considerar saldo do produto sempre do dia anterior

dbSelectarea("TRB")
dbGoTop()
While TRB->(!Eof())

	nQte 	+= TRB->B6_QUANT
	aSaldo	:= CalcTerc(TRB->B6_PRODUTO,TRB->B6_CLIFOR,TRB->B6_LOJA,TRB->B6_IDENT,TRB->B6_TES,,,dDia)
	nSaldo  += aSaldo[1]

	If cTp $ "1]2"

		dbSelectArea("SB6")
		dbSetOrder(3)
		If dbSeek(xFilial("SB6")+TRB->B6_IDENT+TRB->B6_PRODUTO+"D")
			Do While SB6->(!Eof()) .And. SB6->B6_FILIAL+SB6->B6_IDENT+SB6->B6_PRODUTO+SB6->B6_PODER3 == xFilial("SB6")+TRB->B6_IDENT+TRB->B6_PRODUTO+"D"

				If SB6->B6_EMISSAO > dDia
					SB6->(dbSkip())
					Loop
				Endif

				//Pega o total em quantidade
				dbSelectArea("SD2")
				dbSetOrder(3) //3-D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, D2_COD, D2_ITEM, R_E_C_N_O_, D_E_L_E_T_
				cXSD2 := xFilial("SB6")+SB6->(B6_DOC + B6_SERIE + B6_CLIFOR + B6_LOJA + B6_PRODUTO)

				//_nTotQt     := 0
				_nTotPesBru := 0
				_nTotCubag  := 0

				If dbSeek(cXSD2)
					Do While SD2->(!Eof()) .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD) == cXSD2

						If (SD2->(D2_NFORI + D2_SERIORI + D2_IDENTB6) == TRB->(B6_DOC + B6_SERIE + B6_IDENT))

							// mensagem informando falta de informacao de peso e cubagem
							If (SD2->D2_ZPESOB <= 0).or.(SD2->D2_ZCUBAGE <= 0)
								If (Aviso(	"TWMSA004 -> sfSaldoPrd",;
											"ATENÇÃO: Não há peso bruto OU cubagem informado nesta nota. Favor solicitar o recálculo de peso desta programação."+_CRLF+;
											"Nota: "+SD2->D2_DOC +_CRLF+;
											"Item: "+SD2->D2_ITEM +_CRLF+;
											"Nf Origem: "+SD2->D2_NFORI+" / "+SD2->D2_SERIORI ,;
											{"Fechar","Continuar"},3)==1)
									mvRet := .f.
									Return(0)
								EndIf
							EndIf

							//_nTotQt     += SD2->D2_QUANT
							// total do peso bruto devolvido
							_nTotPesBru += SD2->D2_ZPESOB
							// total de cubagem devoldio
							_nTotCubag  += SD2->D2_ZCUBAGE
							// numero do pedido
							cPed:=SD2->D2_PEDIDO
						EndIf

						SD2->(dbSkip())
					EndDo
				EndIf

				If cTp == "2"
					//nQt += (Posicione("SC5",1,xFilial("SC5")+cPed,"C5_PBRUTO") * SB6->B6_QUANT)  / _nTotQt
					nQt += _nTotPesBru
				Else
					//nQt += SB6->B6_QUANT
					nQt += _nTotCubag
				EndIf

				SB6->(dbSkip())

			EndDo

		EndIf

	EndIF

	TRB->(dbSkip())

EndDo


Do Case
	Case cTp == "1"
		//nSaldo := nQte - nQt
		//nRes   := (nSaldo * nCub ) / nQte
		nRes := nCub - nQt
	Case cTp == "2"
		nRes := nPeso - nQt
EndCase

nRes:=IIf(cTp == "2",nRes/1000,nRes)

Return(nRes)

//** funcao que calcula o saldo total da nota
Static Function sfSaldoValor(mvDia,cCliente,cLoja,cnota,cserie,mvTipo,mvFirst,mvRet)
	// area inicial
	local _aAreaAtu := GetArea()
	// variavel de retorno
	local _nRetValor := 0
	// variavel temporaria
	local _cQuery
	// campo chave para total entrada
	local _cExpEntra
	// campo chave para total saida
	local _cExpSaida

	// Daniel 20/04 solicitou via email para considerar saldo do produto sempre do dia anterior
	If (mvTipo <> "V")
		mvDia -= 1
	EndIf

	// monta a expressao de calculo do retorno
	Do Case
		Case (mvTipo == "V") // V-Valor
			_cExpEntra := "ROUND((B6_QUANT * B6_PRUNIT),2)"
			_cExpSaida := "ROUND((D2_QUANT * D2_PRCVEN),2)"

		Case (mvTipo == "1") // 1-Cubagem
			_cExpEntra := "D1_ZCUBAGE"
			_cExpSaida := "D2_ZCUBAGE"

		Case (mvTipo == "2") // 2-Peso Bruto (por TON)
			_cExpEntra := "D1_ZPESOB / 1000"
			_cExpSaida := "D2_ZPESOB / 1000"

		Case (mvTipo == "3") // 3- Quantidade
			_cExpEntra := "B6_QUANT"
			_cExpSaida := "D2_QUANT"

	EndCase

	// monta a query
	_cQuery	:= "SELECT "
	// quantidade de entrada
	_cQuery	+= " "+_cExpEntra+" IT_ENTRADA "
	// quantiade de saida
	_cQuery	+= " ,	ISNULL( ( "
	_cQuery	+= " 		SELECT SUM("+_cExpSaida+")  "
	_cQuery	+= " 		FROM "+RetSqlName("SD2")+" SD2 (nolock)  "
	_cQuery	+= " 		WHERE SD2.D2_FILIAL   = SB6ENT.B6_FILIAL AND SD2.D_E_L_E_T_ = ' ' "
	_cQuery	+= "          AND SD2.D2_CLIENTE  = SB6ENT.B6_CLIFOR AND SD2.D2_LOJA = SB6ENT.B6_LOJA "
	_cQuery	+= "          AND SD2.D2_NFORI    = SB6ENT.B6_DOC AND SD2.D2_SERIORI = SB6ENT.B6_SERIE "
	//_cQuery	+= "          AND SD2.D2_ITEMORI  = NAO USAR
	_cQuery	+= "          AND SD2.D2_COD      = SB6ENT.B6_PRODUTO "
	_cQuery	+= "          AND SD2.D2_IDENTB6  = SB6ENT.B6_IDENT "
	_cQuery	+= " 		  AND SD2.D2_EMISSAO <= '"+DtoS(mvDia)+"' "
	_cQuery	+= " 		) ,0 ) IT_SAIDA "

/*
	// se NAO for o primeiro processo, desconta as movimentacoes de SAIDA
	If (!mvFirst)
		_cQuery	+= " - "
		_cQuery	+= " 	ISNULL( ( "
		_cQuery	+= " 		SELECT SUM("+_cExpSaida+")  "
		_cQuery	+= " 		FROM "+RetSqlName("SB6")+" B6SAIDA "
		// quando for 1-PESO BRUTO ou 2-CUBAGEM, busca os valores no item da nota de ENTRADA
		If (mvTipo $ "1|2")
			_cQuery	+= "INNER JOIN "+RetSqlName("SD2")+" SD2 ON SD2.D2_FILIAL = B6SAIDA.B6_FILIAL AND SD2.D_E_L_E_T_ = ' ' "
			_cQuery	+= "      AND SD2.D2_IDENTB6 = B6SAIDA.B6_IDENT "
			_cQuery	+= "      AND SD2.D2_DOC = B6SAIDA.B6_DOC AND SD2.D2_SERIE = B6SAIDA.B6_SERIE "
			_cQuery	+= "      AND SD2.D2_CLIENTE = B6SAIDA.B6_CLIFOR AND SD2.D2_LOJA = B6SAIDA.B6_LOJA "
			_cQuery	+= "      AND SD2.D2_COD = B6SAIDA.B6_PRODUTO "
		EndIf
		_cQuery	+= " 		WHERE B6SAIDA.B6_FILIAL = SB6ENT.B6_FILIAL AND B6SAIDA.D_E_L_E_T_ = ' ' "
		_cQuery	+= " 		AND B6SAIDA.B6_IDENT = SB6ENT.B6_IDENT "
		_cQuery	+= " 		AND B6SAIDA.B6_PODER3 = 'D' "
		_cQuery	+= " 		AND B6SAIDA.B6_TPCF = 'C' "
		_cQuery	+= " 		AND B6SAIDA.B6_EMISSAO <= '"+DtoS(mvDia)+"' "
		_cQuery	+= " 		) ,0 ) "
	EndIf
*/

	// se NAO for o primeiro processo, procura itens com PESO ou CUBAGEM zerados (somente diferente de valores)
	If (!mvFirst).and.(mvTipo $ "1|2") // quando for 1-PESO BRUTO ou 2-CUBAGEM
		_cQuery  += ", D1_DOC, D1_SERIE, D1_ITEM, D1_COD, D1_PROGRAM, "
		_cQuery  += "(SELECT COUNT(*) "
		_cQuery  += "FROM "+RetSqlName("SB6")+" B6SAIDA (nolock)  "
		_cQuery	+= "INNER JOIN "+RetSqlName("SD2")+" SD2  (nolock) ON SD2.D2_FILIAL = B6SAIDA.B6_FILIAL AND SD2.D_E_L_E_T_ = ' ' "
		_cQuery	+= "      AND SD2.D2_IDENTB6 = B6SAIDA.B6_IDENT "
		_cQuery	+= "      AND SD2.D2_DOC = B6SAIDA.B6_DOC AND SD2.D2_SERIE = B6SAIDA.B6_SERIE "
		_cQuery	+= "      AND SD2.D2_CLIENTE = B6SAIDA.B6_CLIFOR AND SD2.D2_LOJA = B6SAIDA.B6_LOJA "
		_cQuery	+= "      AND SD2.D2_COD = B6SAIDA.B6_PRODUTO "
		_cQuery	+= "      AND "+If(mvTipo=="1","SD2.D2_ZPESOB","SD2.D2_ZCUBAGE")+" <= 0 "
		_cQuery	+= "WHERE B6SAIDA.B6_FILIAL = SB6ENT.B6_FILIAL AND B6SAIDA.D_E_L_E_T_ = ' ' "
		_cQuery	+= "      AND B6SAIDA.B6_IDENT = SB6ENT.B6_IDENT "
		_cQuery	+= "      AND B6SAIDA.B6_PODER3 = 'D' "
		_cQuery	+= "      AND B6SAIDA.B6_TPCF = 'C' "
		_cQuery	+= "      AND B6SAIDA.B6_EMISSAO <= '"+DtoS(mvDia)+"') QTD_ZERO "
	EndIf

	// saldo poder de terceiros
	_cQuery	+= "FROM "+RetSqlName("SB6")+" SB6ENT  (nolock) "
	// quando for 1-PESO BRUTO ou 2-CUBAGEM, busca os valores no item da nota de ENTRADA
	If (mvTipo $ "1|2")
		_cQuery	+= "INNER JOIN "+RetSqlName("SD1")+" SD1 (nolock)  ON D1_FILIAL = B6_FILIAL AND SD1.D_E_L_E_T_ = ' ' AND D1_IDENTB6 = B6_IDENT "
	EndIf
	// filtro da nota de entrada
	_cQuery	+= "WHERE SB6ENT.B6_FILIAL = '"+xFilial("SB6")+"' AND SB6ENT.D_E_L_E_T_ = ' ' "
	_cQuery	+= "AND SB6ENT.B6_DOC = '"+cNota+"' AND SB6ENT.B6_SERIE = '"+cSerie+"' "
	_cQuery	+= "AND SB6ENT.B6_CLIFOR = '"+cCliente+"' AND SB6ENT.B6_LOJA = '"+cLoja+"' "
	_cQuery	+= "AND SB6ENT.B6_TPCF = 'C' "
	_cQuery	+= "AND SB6ENT.B6_PODER3 = 'R' "

memowrit("c:\query\sfSaldoValor.txt",_cQuery)

	If Select("_QRYSLDVLR") <> 0
		dbSelectarea("_QRYSLDVLR")
		dbCloseArea()
	EndIf

	//TCQuery Abre uma workarea com o resultado da query
	TCQUERY _cQuery ALIAS _QRYSLDVLR NEW

	dbSelectarea("_QRYSLDVLR")
	While !Eof()
		// soma o valor do retorno
		_nRetValor += (_QRYSLDVLR->IT_ENTRADA - (If(!mvFirst,_QRYSLDVLR->IT_SAIDA,0)) )

		// mensagem informando falta de informacao de peso e cubagem
		If (mvTipo $ "1|2").and.(_QRYSLDVLR->QTD_ZERO > 0)
			If (Aviso(	"TWMSA004 -> sfSaldoValor",;
						"ATENÇÃO: Não há "+If(mvTipo=="1","CUBAGEM","PESO BRUTO")+" informado nesta nota. Favor solicitar o recálculo de peso desta programação."+_CRLF+;
						"Processo: "+_QRYSLDVLR->D1_PROGRAM +_CRLF+;
						"Nota Entrada: "+_QRYSLDVLR->D1_DOC+" / "+_QRYSLDVLR->D1_SERIE +_CRLF+;
						"Item: "+_QRYSLDVLR->D1_ITEM +_CRLF+;
						"Produto: "+_QRYSLDVLR->D1_COD ,;
						{"Fechar","Continuar"},3)==1)
				// zera variaveis
				_nRetValor := 0
				mvRet := .f.
				Exit
			EndIf
		EndIf

		// proximo valor
		_QRYSLDVLR->(DbSkip())
	EndDo

	// fecha alias da query
	dbSelectarea("_QRYSLDVLR")
	dbCloseArea()

	// restaura area inicial
	RestArea(_aAreaAtu)

Return(_nRetValor)

Static Function sfSaldoArmaz(dDia,cCliente,cLoja,cnota,cserie,cprod)

Local nQuant	:= 0 //quantidade em estoque no dia solicitado
Local DataB	:= dtos(dDia)
Local lNota	:= If(Empty(cNota) .or. cLoja==Nil,.f.,.t.)

cQuery	:= " "
cQuery	+= " SELECT "
cQuery	+= " (B6_QUANT - "
cQuery	+= " CASE "
cQuery	+= " 	WHEN ( "
cQuery	+= " 		SELECT SUM(B6_QUANT)  "
cQuery	+= " 		FROM "+RetSqlName("SB6")+" B6B (nolock)  "
cQuery	+= " 		WHERE B6.B6_IDENT=B6B.B6_IDENT  "
cQuery	+= " 		AND B6B.D_E_L_E_T_<>'*' "
cQuery	+= " 		AND B6B.B6_PODER3='D' "
cQuery	+= " 		AND B6B.B6_EMISSAO <= '"+DATAB+"' "
cQuery	+= " 		) IS NULL THEN 0 "
cQuery	+= " ELSE ( "
cQuery	+= " 	SELECT SUM(B6_QUANT) "
cQuery	+= " 	FROM "+RetSqlName("SB6")+" B6B (nolock)  "
cQuery	+= " 	WHERE B6.B6_IDENT=B6B.B6_IDENT  "
cQuery	+= " 	AND B6B.D_E_L_E_T_<>'*' "
cQuery	+= " 	AND B6B.B6_PODER3='D' "
cQuery	+= " 	AND B6B.B6_EMISSAO <= '"+DATAB+"' "
cQuery	+= " ) "
cQuery	+= " END) AS SALDO "
cQuery	+= " FROM "+RetSqlName("SB6")+" B6 (nolock) , "+RetSqlName("SF1")+" F1 (nolock)  "
cQuery	+= " WHERE  "
cQuery	+= " F1_DOC=B6_DOC AND F1_SERIE=B6_SERIE AND F1_FORNECE=B6_CLIFOR AND F1_LOJA=B6_LOJA AND "
cQuery	+= " B6.D_E_L_E_T_<>'*' AND B6_TIPO='D' AND B6_TPCF='C' AND B6_PODER3='R' AND "
cQuery	+= " F1.D_E_L_E_T_<>'*' AND "
cQuery	+= " F1_FILIAL='"+xFilial("SF1")+"' AND "
cQuery	+= " B6_FILIAL='"+xFilial("SB6")+"' AND "
cQuery	+= " B6_CLIFOR='"+cCliente+"' AND "
cQuery	+= " B6_LOJA='"+cLoja+"' AND "
cQuery  += " B6_PRODUTO = '"+cProd+"' AND "
cQuery	+= " F1_DTDIGIT <= '"+DATAB+"' AND "
cQuery	+= " NOT (B6_UENT <= '"+DATAB+"' AND B6_SALDO=0) "
If lNota
	cQuery	+= " AND F1_DOC='"+cNota+"' "
	cQuery	+= " AND F1_SERIE ='"+cSerie+"' "
	cQuery	+= " AND F1_FORNECE='"+cCliente+"' "
	cQuery	+= " AND F1_LOJA='"+cLoja+"' "
EndIf
cQuery	+= " ORDER BY F1_DTDIGIT "

cQuery := ChangeQuery(cQuery)
If Select("TRB") <> 0
	dbSelectarea("TRB")
	dbCloseArea("TRB")
End

//TCQuery Abre uma workarea com o resultado da query
TCQUERY cQuery ALIAS TRB NEW

dbSelectarea("TRB")
dbGoTop()
While !Eof()
	nQuant	+= TRB->SALDO
	DbSelectArea("TRB")
	DbSkip()
EndDo

Return(nQuant)

Static Function fPeriodo(dFim, dIni,nTmpPer)

If dFim < dIni
	Return 0
EndIf

nPer := dfim - dIni + 1
nRest := nPer % nTmpPer
nPer := nPer / nTmpPer
nper := IIF( nRest <> 0,int(nper) +1,nper)

Return(nPer)

Static Function sfValidaFatura()

	Local _aHeadBrw		:= {}

	Private _cMarca		:= GetMark()
	Private cCadastro	:= "Faturamento de Contrato"
	Private aRotina		:= {{ "Detalhes"			,"U_WMSA004T()", 0 , 1},;
							{ "Visualizar Pedido"	,"U_WMSA004N()", 0 , 2},;
							{ "Gera Ped Venda"		,"U_WMSA004G('F')", 0 , 2},;
							{ "Cancelar"			,"U_WMSA004G('C')", 0 , 2},;
							{ "Estornar/Cancelar"	,"U_WMSA004Y()", 0 , 2},;
							{ "Parametros"			,"U_WMSA004X()", 0 , 3},;
							{ "Totais"		   		,"U_WMSA004S()", 0 , 2},;
							{ "Legenda"				,"U_WMSA004H()", 0 , 2} }


	// inclui detalhes e titulos dos campos do browse
	aAdd(_aHeadBrw,{"IT_OK"		,,"  "			,""})
	aAdd(_aHeadBrw,{"Z2_CODIGO"	,,"Programação"	,""})
	aAdd(_aHeadBrw,{"Z2_ITEM"	,,"Item"		,""})
 	aAdd(_aHeadBrw,{"A1_COD"	,,"Cliente"		,""})
 	aAdd(_aHeadBrw,{"A1_LOJA"	,,"Loja"		,""})
 	aAdd(_aHeadBrw,{"A1_NREDUZ"	,,"Nome"		,""})
 	aAdd(_aHeadBrw,{"AAN_CODPRO",,"Cod.Serviço"	,""})
 	aAdd(_aHeadBrw,{"B1_DESC"	,,"Descrição"	,""})
 	aAdd(_aHeadBrw,{"AAN_QUANT"	,,"Quantidade"	,PesqPict("AAN","AAN_QUANT")})
 	aAdd(_aHeadBrw,{"AAN_VLRUNI",,"Vlr Unitario",PesqPict("AAN","AAN_VLRUNI")})
 	aAdd(_aHeadBrw,{"AAN_VALOR"	,,"Vlr Total"	,PesqPict("AAN","AAN_VALOR")})
 	aAdd(_aHeadBrw,{"C6_NUM"	,,"Pedido"		,""})
 	aAdd(_aHeadBrw,{"C6_ITEM"	,,"Item"		,""})
 	aAdd(_aHeadBrw,{"AAN_CONTRT",,"Contrato"	,""})
 	aAdd(_aHeadBrw,{"AAN_ITEM"	,,"Item"		,""})
 	aAdd(_aHeadBrw,{"AAN_DATA"	,,"Dt.Ult.Fat."	,""})

 	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	(_TRBMOV)->(dbGotop())

	// mark browse com os itens a faturar
	MarkBrow(_TRBMOV,"IT_OK","U_WMSA004M()",_aHeadBrw,,_cMarca,"U_WMSA004L()",,,,,,,,{{"Empty((_TRBMOV)->AAN_CODPRO)","BR_AZUL"},{"SubStr((_TRBMOV)->C6_NUM,1,1)=='C'","BR_AMARELO"},{"Empty((_TRBMOV)->C6_NUM)","ENABLE"},{"!Empty((_TRBMOV)->C6_NUM)","DISABLE"}})

Return(.t.)

User Function WMSA004S()

	cMsg:=""
	aTot:={}
	(_TRBMOV)->(DbSelectArea(_TRBMOV))
	(_TRBMOV)->(dbGoTop())
	While (_TRBMOV)->(!Eof())
		If Empty((_TRBMOV)->C6_NUM)
			cProd:=(_TRBMOV)->AAN_CODPRO
			nPos:=aScan(aTot,{|x| x[1] ==cProd})
		   	If nPos > 0
		   		aTot[nPos,2]+=(_TRBMOV)->AAN_VALOR
		   	Else
				Aadd(aTot,{cProd,(_TRBMOV)->AAN_VALOR})
			EndIf
		EndIf
		(_TRBMOV)->(DbSkip())
	EndDo

	nTot:=0
	For i:=1 To Len(aTot)
		cMsg+=IIf(Empty(aTot[i,1]),"SEM CONTRATO",AllTrim(Posicione("SB1",1,xFilial("SB1")+aTot[i,1],"B1_DESC")))+" = "+AllTrim(Transform(aTot[i,2],"@ze 9,999,999.99")) +CHR(13)+CHR(10)
		nTot+=aTot[i,2]
	Next i
	cMsg+=CHR(13)+CHR(10)+"TOTAL = "+AllTrim(Transform(nTot,"@ze 9,999,999.99"))

	Alert(cMsg)

Return(.t.)

//**Funcao que marca todos os itens quando clicar no header da coluna
User Function WMSA004L ()

Local aAreaAnt := GetArea()

(_TRBMOV)->(DbSelectArea(_TRBMOV))
(_TRBMOV)->(dbGoTop())
While (_TRBMOV)->(!Eof())
	If Empty((_TRBMOV)->C6_NUM)
		RecLock(_TRBMOV,.F.)
		(_TRBMOV)->IT_OK := If( (_TRBMOV)->IT_OK == _cMarca,"",_cMarca )
		MsUnLock()
	EndIf
	(_TRBMOV)->(DbSkip())
EndDo

MarkBRefresh()
RestArea(aAreaAnt)

Return (.T.)


User Function WMSA004M()

	Local lRet	:= .F.

	lRet	:= Empty((_TRBMOV)->C6_NUM) .AND. !Empty((_TRBMOV)->AAN_CODPRO)
	lRet := !( lRet )

Return( lRet )

User Function WMSA004T()

	Local _lFixaMain 	:= .F.
	// campos utilizados
	Private _aHeadMov 	:= {}
	Private _aColsMov 	:= {}
	Private nTarifa		:= 0
	Private cTpArmaz	:= ""
	Private nPeriod		:= 0
	Private nDaysF		:= 0
	Private dDataI		:= CTOD('')
	Private dDataF		:= CTOD('')
	Private oSim        := LoadBitmap( GetResources(), 'ENABLE')
	Private oNao        := LoadBitmap( GetResources(), 'DISABLE')
	Private oCan		:= LoadBitMap(GetResources(), "BR_AMARELO")
	Private bPac		:= Posicione("SB1",1,xFilial("SB1")+(_TRBMOV)->AAN_CODPRO,"B1_TIPOSRV")=="3"
	Private cTpSrv		:= (_TRBMOV)->B1_TIPOSRV
	Private bEdita		:= Empty((_TRBMOV)->C6_NUM) .AND. !Empty((_TRBMOV)->AAN_CODPRO) .And. !bPac
	Private _aHeadPrd 	:= {}
	Private _aColsPrd 	:= {}
	Private _oFntRoda 	:= TFont():New("Tahoma",,16,,.t.)
	Private cPrd		:= CriaVar("B1_COD")

	If bPac
		_oDlgInfVlr := MSDialog():New(000,000,250,420,"Informar servico",,,.F.,,,,,,.T.,,,.T. )
		// cria o panel do cabecalho
		oPnlCabec := TPanel():New(000,000,nil,_oDlgInfVlr,,.F.,.F.,,,000,020,.T.,.F. )
		oPnlCabec:Align:= CONTROL_ALIGN_TOP
		// botao para confirmar
		_oBtnFechar := TButton():New(005,050,"Cancelar",oPnlCabec,{|| _lFixaMain:=.f.,_oDlgInfVlr:End()},050,012,,,,.T.,,"",,,,.F. )
    	_oBtnConfirmar := TButton():New(005,130,"Confirmar",oPnlCabec,{||_lFixaMain:=.t.,_oDlgInfVlr:End()},050,012,,,,.T.,,"",,,,.F. )

		aAdd(_aHeadPrd,{"Produto", "ZU_PRODUTO", PesqPict("SZU","ZU_PRODUTO"), TamSx3("ZU_PRODUTO")[1], TamSx3("ZU_PRODUTO")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadPrd,{"Descricao", "ZU_DESCRI", PesqPict("SZU","ZU_DESCRI"), TamSx3("ZU_DESCRI")[1], TamSx3("ZU_DESCRI")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		_cQuery := "SELECT ZU_PRODUTO, B1_DESC, '.F.' IT_DEL "
		_cQuery += "FROM "+RetSqlName("SZU")+" ZU (nolock) , "+RetSqlName("SB1")+" B1 (nolock)  "
		_cQuery += "WHERE ZU_FILIAL = '"+xFilial("SZU")+"' AND ZU_FILIAL = '"+XFILIAL("SZU")+"' AND ZU_PRODUTO = B1_COD "
		_cQuery += "AND ZU_CONTRT = '"+(_TRBMOV)->AAN_CONTRT+"' AND ZU_ITCONTR = '"+(_TRBMOV)->AAN_ITEM+"' "
		_cQuery += "AND ZU.D_E_L_E_T_ = ' ' AND B1.D_E_L_E_T_ = ' ' "
		_cQuery += "ORDER BY ZU_PRODUTO"
		// alimenta o acols com o resultado do SQL
		_aColsPrd := U_SqlToVet(_cQuery)
		Aadd(_aColsPrd,{(_TRBMOV)->AAN_CODPRO,Posicione("SB1",1,xFilial("SB1")+(_TRBMOV)->AAN_CODPRO,"B1_DESC"),.F.})
		oBrwPrd := MsNewGetDados():New(000,000,300,300,Nil,'AllwaysTrue()','AllwaysTrue()','',,,99,'AllwaysTrue()','','AllwaysTrue()',_oDlgInfVlr,_aHeadPrd,_aColsPrd)
		oBrwPrd:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// ativacao da tela com validacao
		_oDlgInfVlr:Activate(,,,.T.,)

		// se foi confirmado
		If (_lFixaMain)
			cTpSrv	:= Posicione("SB1",1,xFilial("SB1")+oBrwPrd:aCols[oBrwPrd:nAt,1],"B1_TIPOSRV")
			cPrd	:= oBrwPrd:aCols[oBrwPrd:nAt,1]
		Else
			Return(.t.)
		EndIf

	EndIf

	/*
	1 - Numero da Programacao / Pedido de Venda
	2 - Item da Programacao
	3 - Numero do Contrato
	4 - Item do Contrato
	5 - Codigo do Produto Servico
	6 - Codigo do Cliente
	7 - Loja do Cliente
	8 - Quantidade
	9 - Tarifa
	10 - Total
	11 - Data de Processamento Inicial
	12 - Data de Processamento Final
	13 - Container
	14 - Quantidade de Periodos
	15 - Periodicidade
	16 - Data 1 (Data de Remessa)
	17 - Data 2 (Data de Devolucao)
	18 - Numero da OS
	19 - Codigo da Atividade
	20 - Faturar Atividade (S/N)
	21 - Tipo de Movimento
	22 - Operacao
	23 - Quantidade de Dias Free
	24 - Tipo de Armazenagem
	25 - RIC de Entrada
	26 - RIC de Saida
	27 - Praca de Origem
	28 - Praca de Destino
	29 - Conteudo do Container
	30 - Tamanho do Contaier
	31 - Transportadora
	32 - Observacoes
	33 - Pedido + Item
	34 - Valor Total da Nota
	35 - Nota de Remessa
	36 - Nota de Devolucao
	37 - Numero do Contrato Pacote Logistico
	38 - Item do Contrato Pacote Logistico
	39 - Produto do Pacote Logistico
	40 - Linha Deletada .T. / .F.
	*/

	For nX := 1 To Len(aMovContr)

		cContCH:=IIf(bPac .And. cTpSrv <> "3",aMovContr[nX][37]+aMovContr[nX][38],aMovContr[nX][3]+aMovContr[nX][4])
		cFiltCH:=IIf(bPac .And. cTpSrv <> "3",aMovContr[nX][39]==cPrd,Empty(aMovContr[nX][37]))

		If !aMovContr[nX,Len(aMovContr[nX])-1] .And. cFiltCH .And. aMovContr[nX][1]+aMovContr[nX][2]+cContCH+aMovContr[nX][33] == (_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+(_TRBMOV)->C6_NUM+(_TRBMOV)->C6_ITEM

			dDataI:=aMovContr[nX][11]
			dDataF:=aMovContr[nX][12]

			Do Case
				Case cTpSrv == "1"
					nTarifa:=aMovContr[nX][09]
					cTpArmaz:=aMovContr[nX][24]
					nPeriod:=aMovContr[nX][15]
					nDaysF:=aMovContr[nX][23]
					Aadd(_aColsMov,;
					       {aMovContr[nX][13],;
							aMovContr[nX][30],;
							aMovContr[nX][08],;
							aMovContr[nX][14],;
							aMovContr[nX][10],;
							aMovContr[nX][16],;
							aMovContr[nX][17],;
							aMovContr[nX][25],;
							aMovContr[nX][26],;
							.F.})
				Case cTpSrv == "2"
					nTarifa:=aMovContr[nX][09]
					cTpArmaz:=aMovContr[nX][24]
					nPeriod:=aMovContr[nX][15]
					nDaysF:=aMovContr[nX][23]
					Aadd(_aColsMov,;
					       {aMovContr[nX][14],;
					       	aMovContr[nX][35],;
							aMovContr[nX][09],;
							aMovContr[nX][08],;
							aMovContr[nX][10],;
							aMovContr[nX][17],;
							.F.})
				Case cTpSrv == "4"
					Aadd(_aColsMov,;
					       {aMovContr[nX][20],;
							aMovContr[nX][08],;
							aMovContr[nX][09],;
							aMovContr[nX][10],;
							aMovContr[nX][16],;
							aMovContr[nX][21],;
							aMovContr[nX][25],;
							aMovContr[nX][13],;
							aMovContr[nX][30],;
							aMovContr[nX][29],;
							Posicione("SZB",1,xFilial("SZB")+aMovContr[nX][27],"ZB_DESCRI"),;
							Posicione("SZB",1,xFilial("SZB")+aMovContr[nX][28],"ZB_DESCRI"),;
							Posicione("SA4",1,xFilial("SA4")+aMovContr[nX][31],"A4_NREDUZ"),;
							aMovContr[nX][32],;
							.F.})
				Case cTpSrv == "3"
					Aadd(_aColsMov,;
					       {aMovContr[nX][08],;
							aMovContr[nX][09],;
							aMovContr[nX][10],;
							aMovContr[nX][16],;
							aMovContr[nX][21],;
							aMovContr[nX][25],;
							aMovContr[nX][13],;
							aMovContr[nX][30],;
							aMovContr[nX][29],;
							Posicione("SZB",1,xFilial("SZB")+aMovContr[nX][27],"ZB_DESCRI"),;
							Posicione("SZB",1,xFilial("SZB")+aMovContr[nX][28],"ZB_DESCRI"),;
							Posicione("SA4",1,xFilial("SA4")+aMovContr[nX][31],"A4_NREDUZ"),;
							.F.})
				Case cTpSrv == "5"
					Aadd(_aColsMov,;
					       {aMovContr[nX][14],;
					       	aMovContr[nX][35],;
							aMovContr[nX][09],;
							aMovContr[nX][34],;
							aMovContr[nX][10],;
							aMovContr[nX][17],;
					       	.F.})
				Case cTpSrv == "7"
					Aadd(_aColsMov,;
					       {aMovContr[nX][20],;
							aMovContr[nX][19],;
					       	Posicione("SZT",1,xFilial("SZT")+aMovContr[nX][19],"ZT_DESCRIC"),;
					       	Posicione("SZT",1,xFilial("SZT")+aMovContr[nX][19],"ZT_UM"),;
							aMovContr[nX][08],;
							aMovContr[nX][09],;
							aMovContr[nX][10],;
							aMovContr[nX][13],;
							aMovContr[nX][16],;
							aMovContr[nX][21],;
							aMovContr[nX][22],;
							aMovContr[nX][18],;
							aMovContr[nX][32],;
							.F.})
			EndCase

		EndIf

	Next nX

	//Verifica se existem movimentos para este servico
	If Len(_aColsMov) == 0
		Alert("Não existem movimentos para este serviço !!")
		Return (.t.)
	EndIf

	// definicao da tela
	oDlgMovimento := MSDialog():New(000,000,400,800,"Movimentos - "+AllTrim((_TRBMOV)->B1_DESC),,,.F.,,,,,,.T.,,,.T. )
	// cria o panel do cabecalho
	oPnlCabec := TPanel():New(000,000,nil,oDlgMovimento,,.F.,.F.,,,000,030,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP

	// Periodo Inicio e Fim
	oSayTDtIni := TSay():New(005,010,{||"Data Inicio: "},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
	oSayIDtIni := TSay():New(005,060,{||DTOC(dDataI)},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
	oSayTDtFim := TSay():New(015,010,{||"Data Fim: "},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
	oSayIDtFim := TSay():New(015,060,{||DTOC(dDataF)},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)

	If cTpSrv == "1"
		aSort(_aColsMov,,,{|x,y| x[1] < y[1] })
		aAdd(_aHeadMov,{"Container", "B1_DESC", PesqPict("SB1","B1_DESC"), 30, 0,Nil,Nil,"C",Nil,"R" })
		aAdd(_aHeadMov,{"Tamanho", "AAN_TAMCON", PesqPict("AAN","AAN_TAMCON"), TamSx3("AAN_TAMCON")[1], TamSx3("AAN_TAMCON")[2],Nil,Nil,"C",Nil,"R" })
		aAdd(_aHeadMov,{"Quant.", "AAN_QUANT", PesqPict("AAN","AAN_QUANT"), TamSx3("AAN_QUANT")[1], TamSx3("AAN_QUANT")[2],Nil,Nil,"C",Nil,"R" })
		aAdd(_aHeadMov,{"Periodos", "AAN_QUANT", PesqPict("AAN","AAN_QUANT"), TamSx3("AAN_QUANT")[1], TamSx3("AAN_QUANT")[2],Nil,Nil,"C",Nil,"R" })
		aAdd(_aHeadMov,{"Total", "AAN_VALOR", PesqPict("AAN","AAN_VALOR"), TamSx3("AAN_VALOR")[1], TamSx3("AAN_VALOR")[2],Nil,Nil,"C",Nil,"R" })
		aAdd(_aHeadMov,{"Dt.Entrada", "AAN_DATA", PesqPict("AAN","AAN_DATA"), TamSx3("AAN_DATA")[1], TamSx3("AAN_DATA")[2],Nil,Nil,"C",Nil,"R" })
		aAdd(_aHeadMov,{"Dt.Saída", "AAN_DATA", PesqPict("AAN","AAN_DATA"), TamSx3("AAN_DATA")[1], TamSx3("AAN_DATA")[2],Nil,Nil,"C",Nil,"R" })
		aAdd(_aHeadMov,{"RIC Ent.", "D1_DOC", PesqPict("SD1","D1_DOC"), 10, 0,Nil,Nil,"C",Nil,"R" })
		aAdd(_aHeadMov,{"RIC Saída", "D1_DOC", PesqPict("SD1","D1_DOC"), 10, 0,Nil,Nil,"C",Nil,"R" })

		//Tarifa
		oSayTTarifa := TSay():New(005,150,{||"Tarifa:"},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
		oSayITarifa := TSay():New(005,200,{||"R$ "+AllTrim(Transform(nTarifa,"@E 9,999.99"))},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)

		oSayTDaysF := TSay():New(015,150,{||"Days Free:"},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
		oSayIDaysF := TSay():New(015,200,{||Transform(nDaysF,"@E 9999")},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)

	EndIf

	If cTpSrv == "2"

		aSort(_aColsMov,,,{|x,y| x[6] < y[6] })
		aAdd(_aHeadMov,{"Periodo", "AAN_QUANT", PesqPict("AAN","AAN_QUANT"), TamSx3("AAN_QUANT")[1], TamSx3("AAN_QUANT")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(_aHeadMov,{"NF.Remessa", "ZS_DOCREM", PesqPict("SZS","ZS_DOCREM"), TamSx3("ZS_DOCREM")[1], TamSx3("ZS_DOCREM")[2],Nil,Nil,"C",Nil,"R" })
		aAdd(_aHeadMov,{"Tarifa", "ZS_TARIFA", PesqPict("SZS","ZS_TARIFA"), TamSx3("ZS_TARIFA")[1], TamSx3("ZS_TARIFA")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(_aHeadMov,{"Saldo NF", "ZS_VLRDOC", PesqPict("SZS","ZS_VLRDOC"), TamSx3("ZS_VLRDOC")[1], TamSx3("ZS_VLRDOC")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(_aHeadMov,{"Valor", "ZS_TOTAL", PesqPict("SZS","ZS_TOTAL"), TamSx3("ZS_TOTAL")[1], TamSx3("ZS_TOTAL")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(_aHeadMov,{"Data Ref.", "F1_DTDIGIT", PesqPict("SF1","F1_DTDIGIT"), TamSx3("F1_DTDIGIT")[1], TamSx3("F1_DTDIGIT")[2],Nil,Nil,"D",Nil,"R" })


		//Days Free
		oSayTDaysF := TSay():New(005,130,{||"Days Free:"},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
		oSayIDaysF := TSay():New(005,180,{||Transform(nDaysF,"@E 9999")},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)

		//Tipo de Armazenagem
		oSayTTpArm := TSay():New(015,130,{||"Tipo Armaz.:"},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
		oSayITpArm := TSay():New(015,180,{|| sfCBoxDescr("AAN_TIPOAR",cTpArmaz,2,3)},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)

		//Periodicidade
		oSayTPeriod := TSay():New(005,250,{||"Periodicidade:"},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)
		oSayIPeriod := TSay():New(005,300,{||Transform(nPeriod,"@ze 9999")},oPnlCabec,,oFntVerd15,.F.,.F.,.F.,.T.)

		oBtnVisualNFE := TButton():New(013,360,"Visualiza NF",oPnlCabec,{|| sfVisualNFE()},035,014,,,,.T.,,"",,,,.F. )


	EndIf

	If cTpSrv == "4"

		aSort(_aColsMov,,,{|x,y| x[8]+x[6] < y[8]+y[6] })
		aAdd(_aHeadMov,{"Faturar", "Z7_FATURAR", PesqPict("SZ7","Z7_FATURAR"), TamSx3("Z7_FATURAR")[1], TamSx3("Z7_FATURAR")[2],IIf(bEdita,"U_WMSA0044()",""),Nil,"C",Nil,"R",,,IIf(bEdita,".T.",".F.") })
		aAdd(_aHeadMov,{"Qtde", "ZS_QTDE", PesqPict("SZS","ZS_QTDE"), TamSx3("ZS_QTDE")[1], TamSx3("ZS_QTDE")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadMov,{"Tarifa", "ZS_TARIFA", PesqPict("SZS","ZS_TARIFA"), TamSx3("ZS_TARIFA")[1], TamSx3("ZS_TARIFA")[2],Nil,Nil,"N",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Total", "ZS_TOTAL", PesqPict("SZS","ZS_TOTAL"), TamSx3("ZS_TOTAL")[1], TamSx3("ZS_TOTAL")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadMov,{"Data", "Z3_DTMOVIM", PesqPict("SZ3","Z3_DTMOVIM"), TamSx3("Z3_DTMOVIM")[1], TamSx3("Z3_DTMOVIM")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Tipo", "Z3_TPMOVIM", PesqPict("SZ3","Z3_TPMOVIM"), TamSx3("Z3_TPMOVIM")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"RIC", "Z3_RIC", PesqPict("SZ3","Z3_RIC"), TamSx3("Z3_RIC")[1], TamSx3("Z3_RIC")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Container", "Z3_CONTAIN", PesqPict("SZ3","Z3_CONTAIN"), TamSx3("Z3_CONTAIN")[1], TamSx3("Z3_CONTAIN")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Tamanho", "ZS_TAMCONT", PesqPict("SZS","ZS_TAMCONT"), TamSx3("ZS_TAMCONT")[1],TamSx3("ZS_TAMCONT")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Conteudo", "Z3_CONTEUD", PesqPict("SZ3","Z3_CONTEUD"), TamSx3("Z3_CONTEUD")[1], TamSx3("Z3_CONTEUD")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Praça Orig.", "ZB_DESCRI", PesqPict("SZB","ZB_DESCRI"), 20, TamSx3("ZB_DESCRI")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Praça Dest.", "ZB_DESCRI", PesqPict("SZB","ZB_DESCRI"), 20, TamSx3("ZB_DESCRI")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Transportadora", "A4_NREDUZ", PesqPict("SA4","A4_NREDUZ"), TamSx3("A4_NREDUZ")[1], TamSx3("A4_NREDUZ")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Observacoes", "ZS_OBSERVA", PesqPict("SZS","ZS_OBSERVA"), TamSx3("ZS_OBSERVA")[1], TamSx3("ZS_OBSERVA")[2],Nil,Nil,"M",Nil,"R",,,IIf(bEdita,".T.",".F.")  })

	EndIf

	If cTpSrv == "3"

		aSort(_aColsMov,,,{|x,y| x[7] < y[7] })
		aAdd(_aHeadMov,{"Qtde", "ZS_QTDE", PesqPict("SZS","ZS_QTDE"), TamSx3("ZS_QTDE")[1], TamSx3("ZS_QTDE")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadMov,{"Tarifa", "ZS_TARIFA", PesqPict("SZS","ZS_TARIFA"), TamSx3("ZS_TARIFA")[1], TamSx3("ZS_TARIFA")[2],Nil,Nil,"N",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Total", "ZS_TOTAL", PesqPict("SZS","ZS_TOTAL"), TamSx3("ZS_TOTAL")[1], TamSx3("ZS_TOTAL")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadMov,{"Data", "Z3_DTMOVIM", PesqPict("SZ3","Z3_DTMOVIM"), TamSx3("Z3_DTMOVIM")[1], TamSx3("Z3_DTMOVIM")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Tipo", "Z3_TPMOVIM", PesqPict("SZ3","Z3_TPMOVIM"), TamSx3("Z3_TPMOVIM")[1], 0,Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"RIC", "Z3_RIC", PesqPict("SZ3","Z3_RIC"), TamSx3("Z3_RIC")[1], TamSx3("Z3_RIC")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Container", "Z3_CONTAIN", PesqPict("SZ3","Z3_CONTAIN"), TamSx3("Z3_CONTAIN")[1], TamSx3("Z3_CONTAIN")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Tamanho", "ZS_TAMCONT", PesqPict("SZS","ZS_TAMCONT"), TamSx3("ZS_TAMCONT")[1],TamSx3("ZS_TAMCONT")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Conteudo", "Z3_CONTEUD", PesqPict("SZ3","Z3_CONTEUD"), TamSx3("Z3_CONTEUD")[1], TamSx3("Z3_CONTEUD")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Praça Orig.", "ZB_DESCRI", PesqPict("SZB","ZB_DESCRI"), 20, TamSx3("ZB_DESCRI")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Praça Dest.", "ZB_DESCRI", PesqPict("SZB","ZB_DESCRI"), 20, TamSx3("ZB_DESCRI")[2],Nil,Nil,"C",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Transportadora", "A4_NREDUZ", PesqPict("SA4","A4_NREDUZ"), TamSx3("A4_NREDUZ")[1], TamSx3("A4_NREDUZ")[2],Nil,Nil,"C",Nil,"R",,,".F."  })

	EndIf

	If cTpSrv == "5"

		aSort(_aColsMov,,,{|x,y| x[6] < y[6] })
		aAdd(_aHeadMov,{"Periodo", "AAN_QUANT", PesqPict("AAN","AAN_QUANT"), TamSx3("AAN_QUANT")[1], TamSx3("AAN_QUANT")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(_aHeadMov,{"NF.Remessa", "ZS_DOCREM", PesqPict("SZS","ZS_DOCREM"), TamSx3("ZS_DOCREM")[1], TamSx3("ZS_DOCREM")[2],Nil,Nil,"C",Nil,"R" })
		aAdd(_aHeadMov,{"Tarifa", "ZS_TARIFA", PesqPict("SZS","ZS_TARIFA"), TamSx3("ZS_TARIFA")[1], TamSx3("ZS_TARIFA")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(_aHeadMov,{"Saldo NF", "ZS_VLRDOC", PesqPict("SZS","ZS_VLRDOC"), TamSx3("ZS_VLRDOC")[1], TamSx3("ZS_VLRDOC")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(_aHeadMov,{"Valor Seguro", "ZS_TOTAL", PesqPict("SZS","ZS_TOTAL"), TamSx3("ZS_TOTAL")[1], TamSx3("ZS_TOTAL")[2],Nil,Nil,"N",Nil,"R" })
		aAdd(_aHeadMov,{"Data Ref.", "F1_DTDIGIT", PesqPict("SF1","F1_DTDIGIT"), TamSx3("F1_DTDIGIT")[1], TamSx3("F1_DTDIGIT")[2],Nil,Nil,"D",Nil,"R" })

		oBtnVisualNFE := TButton():New(013,360,"Visualiza NF",oPnlCabec,{|| sfVisualNFE()},035,014,,,,.T.,,"",,,,.F. )

	EndIf

	If cTpSrv == "7"
		aSort(_aColsMov,,,{|x,y| x[2] < y[2] })
		aAdd(_aHeadMov,{"Faturar", "Z7_FATURAR", PesqPict("SZ7","Z7_FATURAR"), TamSx3("Z7_FATURAR")[1], TamSx3("Z7_FATURAR")[2],IIf(bEdita,"U_WMSA0047()",""),Nil,"C",Nil,"R",,,IIf(bEdita,".T.",".F.") })
		aAdd(_aHeadMov,{"Cod.Atv.", "ZT_CODIGO", PesqPict("SZT","ZT_CODIGO"), TamSx3("ZT_CODIGO")[1], TamSx3("ZT_CODIGO")[2],Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadMov,{"Desc.Atv.", "ZT_DESCRIC", PesqPict("SZT","ZT_DESCRIC"), 20, TamSx3("ZT_DESCRIC")[2],Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadMov,{"UM", "ZT_UM", PesqPict("SZT","ZT_UM"), TamSx3("ZT_UM")[1], TamSx3("ZT_UM")[2],Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadMov,{"Qtde", "ZS_QTDE", PesqPict("SZS","ZS_QTDE"), TamSx3("ZS_QTDE")[1], TamSx3("ZS_QTDE")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadMov,{"Tarifa", "ZS_TARIFA", PesqPict("SZS","ZS_TARIFA"), TamSx3("ZS_TARIFA")[1], TamSx3("ZS_TARIFA")[2],Nil,Nil,"N",Nil,"R",,,".F."  })
		aAdd(_aHeadMov,{"Total", "ZS_TOTAL", PesqPict("SZS","ZS_TOTAL"), TamSx3("ZS_TOTAL")[1], TamSx3("ZS_TOTAL")[2],Nil,Nil,"N",Nil,"R",,,".F." })
		aAdd(_aHeadMov,{"Container", "Z3_CONTAIN", PesqPict("SZ3","Z3_CONTAIN"), TamSx3("Z3_CONTAIN")[1], TamSx3("Z3_CONTAIN")[2],Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadMov,{"Data", "Z6_DTFINAL", PesqPict("SZ6","Z6_DTFINAL"), TamSx3("Z6_DTFINAL")[1], TamSx3("Z6_DTFINAL")[2],Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadMov,{"Movimento", "Z6_TIPOMOV", PesqPict("SZ6","Z6_TIPOMOV"), TamSx3("Z6_TIPOMOV")[1], 0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadMov,{"Operação", "Z7_TIPOPER", PesqPict("SZ7","Z7_TIPOPER"), TamSx3("Z7_TIPOPER")[1], 0,Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadMov,{"O.S.", "Z6_NUMOS", PesqPict("SZ6","Z6_NUMOS"), TamSx3("Z6_NUMOS")[1], TamSx3("Z6_NUMOS")[2],Nil,Nil,"C",Nil,"R",,,".F." })
		aAdd(_aHeadMov,{"Observacoes", "ZS_OBSERVA", PesqPict("SZS","ZS_OBSERVA"), TamSx3("ZS_OBSERVA")[1], TamSx3("ZS_OBSERVA")[2],Nil,Nil,"M",Nil,"R",,,IIf(bEdita,".T.",".F.")  })
	EndIf

	oBtnConfirmar := TButton():New(013,320,"Confirmar",oPnlCabec,{|| sfConfirmar()},035,014,,,,.T.,,"",,,,.F. )

	oBrwMov := MsNewGetDados():New(000,000,400,400,IIf(cTpSrv$"4|7".And.bEdita,GD_UPDATE+GD_DELETE,Nil),IIf(bEdita,'U_WMSA004K()','AllwaysTrue()'),IIf(bEdita,'U_WMSA004Z()','AllwaysTrue()'),'',,,Len(_aColsMov),'AllwaysTrue()','','AllwaysTrue()',oDlgMovimento,_aHeadMov,_aColsMov)
	oBrwMov:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa o dialogo
	oDlgMovimento:Activate(,,,.T.,{||oBrwMov:TudoOK()})

	If (_lFixaMain)
	 	U_WMSA004T()
	EndIf

Return(.t.)

Static Function sfConfirmar()

	oDlgMovimento:End()

	If cTpSrv$"4|7"
		For i:=1 To Len(oBrwMov:aCols)
			If oBrwMov:aCols[i,Len(_aHeadMov)+1]
			EndIf
		Next i
	EndIf

Return(.t.)

User Function WMSA004Z()

	If cTpSrv $ "4|7"
		sfAtuValor()
		nFat:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="Z7_FATURAR"})
		nObs:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_OBSERVA"})
		For i:=1 To Len(oBrwMov:aCols)
			If !oBrwMov:aCols[i,Len(_aHeadMov)+1] .And. oBrwMov:aCols[i,nFat] == "N" .And. Empty(oBrwMov:aCols[i,nObs])
		    	Alert("Existem itens onde é precso informar um motivo para nao faturar no campo Observacoes !!")
		    	Return(.f.)
		    EndIf
			If cTpSrv == "4"
				nRIC:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="Z3_RIC"})
				nPos:=aScan(aMovContr,{|x| x[1]+x[2]+x[3]+x[4]+x[25] ==(_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+oBrwMov:aCols[i,nRIC]})
				If nPos > 0
					aMovContr[nPos,Len(aMovContr[nPos])-1]:=oBrwMov:aCols[i,Len(_aHeadMov)+1]
				EndIf
			EndIf
			If cTpSrv == "7"
				nAtv:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZT_CODIGO"})
				nOS:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="Z6_NUMOS"})
				nPos:=aScan(aMovContr,{|x| x[1]+x[2]+x[3]+x[4]+x[18]+x[19]==(_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+oBrwMov:aCols[i,nOS]+oBrwMov:aCols[i,nAtv]})
				If nPos > 0
					aMovContr[nPos,Len(aMovContr[nPos])-1]:=oBrwMov:aCols[i,Len(_aHeadMov)+1]
				EndIf
			EndIf
		Next i
	EndIf

Return(.t.)

User Function WMSA004K()

	If cTpSrv$"4|7"
		nFat:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="Z7_FATURAR"})
	    nObs:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_OBSERVA"})
	    If !oBrwMov:aCols[oBrwMov:nAt,Len(_aHeadMov)+1] .And. oBrwMov:aCols[oBrwMov:nAt,nFat] == "N" .And. Empty(oBrwMov:aCols[oBrwMov:nAt,nObs])
	    	Alert("É preciso informar no campo Observacoes um motivo para nao faturar este item !!")
	    	Return(.f.)
	    EndIf
	    sfGravaOBS()
	EndIf

Return(.t.)

User Function WMSA0044()

	nVlr:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_TARIFA"})
	nQtd:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_QTDE"})
	nTot:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_TOTAL"})
	nRIC:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="Z3_RIC"})

	// Atualiza Browse dos movimentos
	oBrwMov:aCols[oBrwMov:nAt,nVlr]:=sfTarifaFrete((_TRBMOV)->AAN_CONTRT, (_TRBMOV)->AAN_ITEM, '', oBrwMov:aCols[oBrwMov:nAt,nRIC], M->Z7_FATURAR)
	oBrwMov:aCols[oBrwMov:nAt,nTot]:=oBrwMov:aCols[oBrwMov:nAt,nQtd]*oBrwMov:aCols[oBrwMov:nAt,nVlr]

	// Atualiza Browse dos servicos
	sfAtuValor()

	// Atualiza array dos movimentos caso usuario click novamente
	nPos:=aScan(aMovContr,{|x| x[1]+x[2]+x[3]+x[4]+x[25] ==(_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+oBrwMov:aCols[oBrwMov:nAt,nRIC]})
	If nPos > 0
		aMovContr[nPos,09]:=oBrwMov:aCols[oBrwMov:nAt,nVlr]
		aMovContr[nPos,10]:=oBrwMov:aCols[oBrwMov:nAt,nTot]
		aMovContr[nPos,20]:=M->Z7_FATURAR
	EndIf

Return (.t.)

User Function WMSA0047()

	nVlr:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_TARIFA"})
	nQtd:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_QTDE"})
	nTot:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_TOTAL"})
	nAtv:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZT_CODIGO"})
	nOS:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="Z6_NUMOS"})

	// Atualiza Browse dos movimentos
	oBrwMov:aCols[oBrwMov:nAt,nVlr]:=sfTarifaAtv((_TRBMOV)->AAN_CONTRT, (_TRBMOV)->AAN_ITEM, '', oBrwMov:aCols[oBrwMov:nAt,nAtv], M->Z7_FATURAR, '' ,'', '')
	oBrwMov:aCols[oBrwMov:nAt,nTot]:=oBrwMov:aCols[oBrwMov:nAt,nQtd]*oBrwMov:aCols[oBrwMov:nAt,nVlr]

	// Atualiza Browse dos servicos
	sfAtuValor()

	// Atualiza array dos movimentos caso usuario click novamente
	nPos:=aScan(aMovContr,{|x| x[1]+x[2]+x[3]+x[4]+x[18]+x[19]==(_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+oBrwMov:aCols[oBrwMov:nAt,nOS]+oBrwMov:aCols[oBrwMov:nAt,nAtv]})
	If nPos > 0
		aMovContr[nPos,09]:=oBrwMov:aCols[oBrwMov:nAt,nVlr]
		aMovContr[nPos,10]:=oBrwMov:aCols[oBrwMov:nAt,nTot]
		aMovContr[nPos,20]:=M->Z7_FATURAR
	EndIf

Return (.t.)

Static Function sfAtuValor()

	// Atualiza Browse dos servicos
	nTot:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_TOTAL"})
	nTotal:=0
	For i:=1 To Len(oBrwMov:aCols)
		If !oBrwMov:aCols[i,Len(_aHeadMov)+1]
			nTotal+=oBrwMov:aCols[i,nTot]
		EndIf
	Next i
	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	(_TRBMOV)->(RecLock(_TRBMOV,.F.))
	(_TRBMOV)->AAN_VALOR:=nTotal
	(_TRBMOV)->(MsUnlock())

Return(.t.)

Static Function sfGravaOBS()

	// Atualiza array dos movimentos caso usuario click novamente
	nOBS:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_OBSERVA"})
	If cTpSrv == "4"
		nRIC:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="Z3_RIC"})
		nPos:=aScan(aMovContr,{|x| x[1]+x[2]+x[3]+x[4]+x[25] ==(_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+oBrwMov:aCols[oBrwMov:nAt,nRIC]})
	EndIf
	If cTpSrv == "7"
		nAtv:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZT_CODIGO"})
		nOS:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="Z6_NUMOS"})
		nPos:=aScan(aMovContr,{|x| x[1]+x[2]+x[3]+x[4]+x[18]+x[19]==(_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+oBrwMov:aCols[oBrwMov:nAt,nOS]+oBrwMov:aCols[oBrwMov:nAt,nAtv]})
	EndIf
	If nPos > 0
		aMovContr[nPos,32]:=oBrwMov:aCols[oBrwMov:nAt,nOBS]
	EndIf

Return(.t.)

//** funcao responsavel pela geracao do pedido de vendas
User Function WMSA004G(cTipo)

Local aTRB:=(_TRBMOV)->(GetArea())

// Cria array para agrupamento
aGrupo:={}
(_TRBMOV)->(dbSelectArea(_TRBMOV))
(_TRBMOV)->(dbGotop())
While (_TRBMOV)->(!EOF())
	If (_TRBMOV)->IT_OK = _cMarca .And. Empty((_TRBMOV)->C6_NUM)

		If cTipo == "F"
			// Verifica se algum item que sera faturado possui valores zerados
			For nX := 1 To Len(aMovContr)
				If !aMovContr[nX,Len(aMovContr[nX])-1] .And. Empty(aMovContr[nX][37]) .And. aMovContr[nX][1]+aMovContr[nX][2]+aMovContr[nX][3]+aMovContr[nX][4] == (_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM
		        	If aMovContr[nX,20] == "S" .And. aMovContr[nX,10] == 0
		        		cTx:="Programação: "+(_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+CHR(13)+CHR(10)
		        		cTx+="Servico: "+AllTrim((_TRBMOV)->B1_DESC)+CHR(13)+CHR(10)
		        		cTx+="Verificar pois este item possui movimentações para faturar sem tarifa !! "
		        		Alert(cTx)
		        		Return(.f.)
		        	EndIf
		        EndIf
		  	Next nX
		EndIf

		// Verifica se o produto do servico possui TES de Saida cadastrada
		dbSelectArea("SB1")
		SB1->(DbSetOrder(1))
		SB1->(DbSeek( xFilial("SB1") + (_TRBMOV)->AAN_CODPRO ))
		dbSelectArea("SF4")
		SF4->(DbSetOrder(1))
		If !SF4->(DbSeek( xFilial("SF4") + SB1->B1_TS ))
			cTx:="Programação: "+(_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+CHR(13)+CHR(10)
	        cTx+="Servico: "+AllTrim((_TRBMOV)->B1_DESC)+CHR(13)+CHR(10)
	        cTx+="Verificar pois este item não possui uma TES de Saída Cadastrada no Produto !! "
	  		Alert(cTx)
	    	Return(.f.)
	  	EndIf
		nPos := aScan( aGrupo,{|x| x[1]+x[2]+x[3]+x[4]==(_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->A1_COD+(_TRBMOV)->A1_LOJA})
	    If nPos == 0
	    	Aadd(aGrupo,{(_TRBMOV)->Z2_CODIGO,(_TRBMOV)->Z2_ITEM, (_TRBMOV)->A1_COD, (_TRBMOV)->A1_LOJA})
	    EndIf
	 EndIf
    (_TRBMOV)->(dbSkip())
EndDo

For j:=1 To Len(aGrupo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicio da transacao                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Begin Transaction

	cGrupo1:=aGrupo[j,1]
	cGrupo2:=aGrupo[j,2]
	cGrupo3:=aGrupo[j,3]
	cGrupo4:=aGrupo[j,4]
	aItens := {}
	aContPed := {}
	cItem    := "00"
	nVlrISS	:= 0

	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	(_TRBMOV)->(dbGotop())
    While (_TRBMOV)->(!EOF())

		If ((_TRBMOV)->IT_OK = _cMarca .And. Empty((_TRBMOV)->C6_NUM)) .And. (cGrupo1 + cGrupo2 + cGrupo3 + cGrupo4 == (_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->A1_COD+(_TRBMOV)->A1_LOJA)

			cContrt:=(_TRBMOV)->AAN_CONTRT
			cItContrt:=(_TRBMOV)->AAN_ITEM
			cProduto:=(_TRBMOV)->AAN_CODPRO
			SB1->(DbSetOrder(1))
			SB1->(DbSeek( xFilial("SB1") + cProduto ))
			If SB1->B1_TIPOSRV <> '3'
				nQuant		:= 1
				nPreco		:= (_TRBMOV)->AAN_VALOR
			Else
				nQuant		:= (_TRBMOV)->AAN_QUANT
				nPreco		:= (_TRBMOV)->AAN_VLRUNI
			EndIf
			nValor		:= (_TRBMOV)->AAN_VALOR
			cCondPV		:= Posicione("AAM",1,xFilial("AAM")+(_TRBMOV)->AAN_CONTRT,"AAM_CPAGPV")
			cCodCli		:= (_TRBMOV)->A1_COD
			cLojCli		:= (_TRBMOV)->A1_LOJA
			cDescPrd	:= (_TRBMOV)->B1_DESC


			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ O produto deve possuir TES de saida                  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			SF4->(DbSetOrder(1))
			If SF4->(DbSeek( xFilial("SF4") + SB1->B1_TS ))

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Posiciona no cliente                                 ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				SA1->( dbSetOrder( 1 ) )
				SA1->( MsSeek( xFilial( "SA1" ) + cCodCli+cLojCli) )

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Define o CFO                                         ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				aDadosCFO := {}
			 	Aadd(aDadosCfo,{"OPERNF","S"})
			 	Aadd(aDadosCfo,{"TPCLIFOR",SA1->A1_TIPO})
			 	Aadd(aDadosCfo,{"UFDEST"  ,SA1->A1_EST})
			 	Aadd(aDadosCfo,{"INSCR"   ,SA1->A1_INSCR})

				cCfo := MaFisCfo(,SF4->F4_CF,aDadosCfo)

				cItem := SomaIt( cItem )

				aLinha:={}
				aadd(aLinha,{"C6_ITEM"      ,cItem			,Nil})
				aadd(aLinha,{"C6_PRODUTO"   ,cProduto		,Nil})
				aadd(aLinha,{"C6_QTDVEN"    ,nQuant			,Nil})
				aadd(aLinha,{"C6_QTDLIB"    ,nQuant			,Nil}) // QTD LIBERADA
				aadd(aLinha,{"C6_PRUNIT"    ,nPreco			,Nil})
				aadd(aLinha,{"C6_PRCVEN"    ,nPreco			,Nil})
				aadd(aLinha,{"C6_VALOR"     ,nValor			,Nil})
				aadd(aLinha,{"C6_UM"        ,SB1->B1_UM		,Nil})
				aadd(aLinha,{"C6_TES"       ,SB1->B1_TS		,Nil})
				aadd(aLinha,{"C6_CF"        ,cCfo			,Nil})
				aadd(aLinha,{"C6_LOCAL"     ,SB1->B1_LOCPAD	,Nil})
				aadd(aLinha,{"C6_CLI"       ,cCodCli                               ,Nil})
				aadd(aLinha,{"C6_LOJA"      ,cLojCli                                   ,Nil})
				aadd(aLinha,{"C6_DESCRI"    ,cDescPrd                             ,Nil})
//				aadd(aLinha,{"C6_DESC"	    ,cDescPrd                             ,Nil})
				aadd(aLinha,{"C6_CONTRT"    ,cContrt                             ,Nil})
				aadd(aLinha,{"C6_ITCONTR"   ,cItContrt                             ,Nil})
				aadd(aLinha,{"C6_TPCONTR"   ,"1"                             ,Nil})
				aadd(aLinha,{"C6_CODISS"   	,SB1->B1_CODISS                            ,Nil})
				aadd(aLinha,{"C6_ENTREG"    ,dDataBase                              ,Nil})

				aadd(aItens,aLinha)

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Armazena os itens que geraram PV                     ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				AAdd( aContPed, { (_TRBMOV)->(RecNo()), NIL, cItem } )

				//Cobra ISS do cliente
				If SB1->B1_ALIQISS > 0
					//nTot:=nPreco*nQuant
					nTot	:= nValor
					//nVlrISS += Round(((nTot) / (1 - SB1->B1_ALIQISS/100)) - nTot,2)
					nVlrISS	+= Round(nTot * (SB1->B1_ALIQISS/100),2)
				EndIf

			EndIf

	  	EndIf

		(_TRBMOV)->(dbSkip())

	EndDo

	If	Len(aItens) > 0

		SA1->(DbSetOrder(1))
		SA1->(DbSeek( xFilial("SA1") + cCodCli + cLojCli ))

		aCabec:={}
		aadd(aCabec ,{"C5_TIPO"      	,"N"							,Nil})
		aadd(aCabec ,{"C5_TIPOOPE"     	,"S"							,Nil})
		aadd(aCabec ,{"C5_CLIENTE"      ,cCodCli						,Nil})
		aadd(aCabec ,{"C5_CLIENT"      	,cCodCli						,Nil})
		aadd(aCabec ,{"C5_LOJAENT"      ,cLojCli						,Nil})
		aadd(aCabec ,{"C5_LOJACLI"      ,cLojCli						,Nil})
		aadd(aCabec ,{"C5_TIPOCLI"      ,SA1->A1_TIPO					,Nil})
		aadd(aCabec ,{"C5_CONDPAG"      ,cCondPV						,Nil})
		aadd(aCabec ,{"C5_MENNOTA"      ,"REF. PROGRAMACAO: "+cGrupo1	,Nil})

		// Cobra ISS caso seja necessario
		If nVlrISS > 0

			cProduto:="9000009"

			dbSelectArea("SB1")
			dbSetOrder(1)
			dbSeek(xFilial("SB1")+cProduto)

			SF4->(DbSetOrder(1))
			If SF4->(DbSeek( xFilial("SF4") + SB1->B1_TS ))

				cCfo := MaFisCfo(,SF4->F4_CF,aDadosCfo)
				cItem := SomaIt( cItem )

				aLinha:={}
				aadd(aLinha,{"C6_ITEM"      ,cItem			,Nil})
				aadd(aLinha,{"C6_PRODUTO"   ,cProduto		,Nil})
				aadd(aLinha,{"C6_QTDVEN"    ,1				,Nil})
				aadd(aLinha,{"C6_QTDLIB"    ,1				,Nil}) // QTD LIBERADA
				aadd(aLinha,{"C6_PRUNIT"    ,nVlrISS		,Nil})
				aadd(aLinha,{"C6_PRCVEN"    ,nVlrISS		,Nil})
				aadd(aLinha,{"C6_VALOR"     ,nVlrISS 		,Nil})
				aadd(aLinha,{"C6_UM"        ,SB1->B1_UM		,Nil})
				aadd(aLinha,{"C6_TES"       ,SB1->B1_TS		,Nil})
				aadd(aLinha,{"C6_CF"        ,cCfo			,Nil})
				aadd(aLinha,{"C6_LOCAL"     ,SB1->B1_LOCPAD	,Nil})
				aadd(aLinha,{"C6_CLI"       ,cCodCli		,Nil})
				aadd(aLinha,{"C6_LOJA"      ,cLojCli		,Nil})
				aadd(aLinha,{"C6_DESCRI"    ,SB1->B1_DESC	,Nil})
//				aadd(aLinha,{"C6_DESC" 		,SB1->B1_DESC	,Nil})
				aadd(aLinha,{"C6_ENTREG"    ,dDataBase		,Nil})

				aadd(aItens,aLinha)

			EndIf

		EndIf

		lMSHelpAuto := .T.
		lMsErroAuto := .F.

		If cTipo == "F"

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ funcao de gravacao de pedido. Padrao                 ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			MATA410(aCabec,aItens,3)

		EndIf

		If lMsErroAuto
			Alert("Erro Na Geracao de Pedido" )
			MostraErro()
		Else
			For nLoop := 1 To Len( aContPed )
				//Caso for cancelamento o numero do pedido sera CNNNNN
				If cTipo == "F"
					aContPed[ nLoop, 2 ] := SC5->C5_NUM
				Else
					cQry:="SELECT ISNULL(MAX(ZR_PEDIDO),'C00000') FROM "+RetSqlName("SZR")+" (nolock)  WHERE D_E_L_E_T_  = '' AND LEFT(ZR_PEDIDO,1) = 'C' AND ZR_FILIAL = '"+XFILIAL("SZR")+"' "
					_cRet := U_FtQuery(cQry)
					_cRet := Soma1(_cRet)
					aContPed[ nLoop, 2 ] := _cRet
				EndIf
			Next nLoop
		EndIf

	EndIf

	// Grava dados do pedido
	For nLoop := 1 to Len( aContPed )

	    (_TRBMOV)->(dbSelectArea(_TRBMOV))
	    dbGoTo(aContPed[nLoop,1])

	    If cTipo == "F"

	    	dbSelectArea("SC6")
			dbSetOrder(1)
			dbSeek(xFilial("SC6")+aContPed[nLoop,2]+aContPed[nLoop,3])

			(_TRBMOV)->(dbSelectArea(_TRBMOV))
			(_TRBMOV)->(Reclock(_TRBMOV,.F.))
			(_TRBMOV)->C6_NUM	:= SC6->C6_NUM
			(_TRBMOV)->C6_ITEM:= SC6->C6_ITEM
			(_TRBMOV)->(MsUnlock())

		Else

			(_TRBMOV)->(dbSelectArea(_TRBMOV))
			(_TRBMOV)->(Reclock(_TRBMOV,.F.))
			(_TRBMOV)->C6_NUM	:= aContPed[nLoop,2]
			(_TRBMOV)->C6_ITEM:= aContPed[nLoop,3]
			(_TRBMOV)->(MsUnlock())

		EndIf

		sfGravaRel()

		If (!_bMostraFat)
			(_TRBMOV)->(Reclock(_TRBMOV,.F.))
			(_TRBMOV)->(dbDelete())
			(_TRBMOV)->(MsUnlock())
		EndIf

		dbSelectArea("SB1")
		dbSetOrder(1)
		dbSeek(xFilial("SB1")+(_TRBMOV)->AAN_CODPRO)
		Do Case
			Case SB1->B1_TIPOSRV == '3'
				sfBaixaFrete()
				sfBaixaOS()
				sfBaixaPacote()
			Case SB1->B1_TIPOSRV == '4'
				sfBaixaFrete()
			Case SB1->B1_TIPOSRV == '7'
				sfBaixaOS()
			Case SB1->B1_TIPOSRV == '2'
				sfBaixaProduto()
			Case SB1->B1_TIPOSRV == '1'
				sfBaixaContain()
			Case SB1->B1_TIPOSRV == '5'
				sfBaixaSeg()
		EndCase


	Next nLoop

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Final da transacao                                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	End Transaction

Next j

RestArea(aTRB)

Return(.t.)

Static Function sfGravaRel()

	// Grava Cabecalho
	dbSelectArea("SZR")
	RecLock("SZR",.T.)
	SZR->ZR_FILIAL:=XFILIAL("SZR")
	SZR->ZR_PROGRAM:=(_TRBMOV)->Z2_CODIGO
	SZR->ZR_ITEPROG:=(_TRBMOV)->Z2_ITEM
	SZR->ZR_CONTRT:=(_TRBMOV)->AAN_CONTRT
	SZR->ZR_ITEM:=(_TRBMOV)->AAN_ITEM
	SZR->ZR_CODSRV:=(_TRBMOV)->AAN_CODPRO
	SZR->ZR_CODCLI:=(_TRBMOV)->A1_COD
	SZR->ZR_LOJCLI:=(_TRBMOV)->A1_LOJA
	SZR->ZR_PEDIDO:=(_TRBMOV)->C6_NUM
	SZR->ZR_ITEPEDI:=(_TRBMOV)->C6_ITEM
	SZR->ZR_DATA:=dDatabase
	SZR->ZR_VALOR:=(_TRBMOV)->AAN_VALOR
	SZR->ZR_QUANT:=(_TRBMOV)->AAN_QUANT
	SZR->ZR_VLRUNI:=(_TRBMOV)->AAN_VLRUNI
	SZR->ZR_DESCRI:=(_TRBMOV)->B1_DESC
	MsUnlock()
	// Grava Itens
	For i:=1 To Len(aMovContr)
		If !aMovContr[i,Len(aMovContr[i])-1] .And. Empty(aMovContr[i,33]) .And. ;
			((aMovContr[i,1]+aMovContr[i,2]+aMovContr[i,3]+aMovContr[i,4] == (_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM .And. Empty(aMovContr[i,37])).OR. ;
			aMovContr[i,1]+aMovContr[i,2]+aMovContr[i,37]+aMovContr[i,38] == (_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM)
			//Armazena numero do Pedido no array de movimentacoes
			aMovContr[i,33]:=(_TRBMOV)->C6_NUM+(_TRBMOV)->C6_ITEM
			dbSelectArea("SZS")
			RecLock("SZS",.T.)
			SZS->ZS_FILIAL:=XFILIAL("SZS")
			SZS->ZS_PROGRAM:=aMovContr[i,1]
			SZS->ZS_ITEPROG:=aMovContr[i,2]
			SZS->ZS_CONTRT:=aMovContr[i,3]
			SZS->ZS_ITEM:=aMovContr[i,4]
			SZS->ZS_CODSRV:=aMovContr[i,5]
			SZS->ZS_CODCLI:=aMovContr[i,6]
			SZS->ZS_LOJCLI:=aMovContr[i,7]
			SZS->ZS_QTDE:=aMovContr[i,8]
			SZS->ZS_TARIFA:=aMovContr[i,9]
			SZS->ZS_TOTAL:=aMovContr[i,10]
			SZS->ZS_DATAI:=aMovContr[i,11]
			SZS->ZS_DATAF:=aMovContr[i,12]
			SZS->ZS_CONTAIN:=aMovContr[i,13]
			SZS->ZS_QTDPERI:=aMovContr[i,14]
			SZS->ZS_PERIODO:=aMovContr[i,15]
			SZS->ZS_DATA1:=aMovContr[i,16]
			SZS->ZS_DATA2:=aMovContr[i,17]
			SZS->ZS_NUMOS:=aMovContr[i,18]
			SZS->ZS_CODATIV:=aMovContr[i,19]
			SZS->ZS_FATURAR:=aMovContr[i,20]
			SZS->ZS_TIPMOV:=aMovContr[i,21]
			SZS->ZS_OPERACA:=aMovContr[i,22]
			SZS->ZS_DAYFREE:=aMovContr[i,23]
			SZS->ZS_TIPARMA:=aMovContr[i,24]
			SZS->ZS_RICENTR:=aMovContr[i,25]
			SZS->ZS_RICSAID:=aMovContr[i,26]
			SZS->ZS_PEDIDO:=(_TRBMOV)->C6_NUM
			SZS->ZS_ITEPEDI:=(_TRBMOV)->C6_ITEM
			SZS->ZS_PRCORIG:=aMovContr[i,27]
			SZS->ZS_PRCDEST:=aMovContr[i,28]
			SZS->ZS_CONTEUD:=aMovContr[i,29]
			SZS->ZS_TAMCONT:=aMovContr[i,30]
			SZS->ZS_TRANSP:=aMovContr[i,31]
			SZS->ZS_OBSERVA:=IIf(!Empty(aMovContr[i,32]),AllTrim(cUserName) + ": " +aMovContr[i,32],'')
			SZS->ZS_VLRDOC:=aMovContr[i,34]
			SZS->ZS_DOCREM:=aMovContr[i,35]
			SZS->ZS_DOCDEV:=aMovContr[i,36]
			SZS->ZS_PACCONT:=aMovContr[i,37]
			SZS->ZS_PACITEM:=aMovContr[i,38]
			SZS->ZS_PACPROD:=aMovContr[i,39]
			MsUnlock()

		EndIf
	Next i

Return(.t.)

Static Function sfBaixaFrete()

	// Baixa Frete
	For i:=1 To Len(aMovContr)
		If !aMovContr[i,Len(aMovContr[i])-1] .And. aMovContr[i,1]+aMovContr[i,2]+aMovContr[i,3]+aMovContr[i,4]+aMovContr[i,33] == (_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+(_TRBMOV)->C6_NUM+(_TRBMOV)->C6_ITEM
    		bAt:=.F.
    		If Posicione("SB1",1,xFilial("SB1")+aMovContr[i,05],"B1_TIPOSRV")=="4"
    			bAt:=.T.
    		EndIf
    		dbSelectArea("SZ3")
			SZ3->(dbOrderNickName("Z3_RIC"))
			If dbSeek(xFilial("SZ3")+aMovContr[i,25]) .And. bAt
				RecLock("SZ3",.F.)
				SZ3->Z3_DTFATFR:=dDatabase
				MsUnlock()
			EndIf
		EndIf
	Next i
	// Baixa Frete dos Pacote Logistico
	For i:=1 To Len(aMovContr)
		If !aMovContr[i,Len(aMovContr[i])-1] .And. aMovContr[i,1]+aMovContr[i,2]+aMovContr[i,37]+aMovContr[i,38]+aMovContr[i,33] == (_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+(_TRBMOV)->C6_NUM+(_TRBMOV)->C6_ITEM
    		bAt:=.F.
    		If Posicione("SB1",1,xFilial("SB1")+aMovContr[i,39],"B1_TIPOSRV")=="4"
    			bAt:=.T.
    		EndIf
    		dbSelectArea("SZ3")
			SZ3->(dbOrderNickName("Z3_RIC"))
			If dbSeek(xFilial("SZ3")+aMovContr[i,25]) .And. bAt
				RecLock("SZ3",.F.)
				SZ3->Z3_DTFATFR:=dDatabase
				MsUnlock()
			EndIf
		EndIf
	Next i


Return(.t.)

Static Function sfBaixaSeg()

	// Baixa Seguro
	For i:=1 To Len(aMovContr)
		If !aMovContr[i,Len(aMovContr[i])-1] .And. aMovContr[i,1]+aMovContr[i,2]+aMovContr[i,3]+aMovContr[i,4]+aMovContr[i,33] == (_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+(_TRBMOV)->C6_NUM+(_TRBMOV)->C6_ITEM
    		bAt:=.F.
    		If Posicione("SB1",1,xFilial("SB1")+aMovContr[i,05],"B1_TIPOSRV")=="5"
    			bAt:=.T.
    		EndIf
    		dbSelectArea("SF1")
			dbSetOrder(1)
			If dbSeek(xFilial("SF1")+aMovContr[i,35]+aMovContr[i,6]+aMovContr[i,7]) .And. bAt
				RecLock("SF1",.F.)
				SF1->F1_DTFATSE:=aMovContr[i,17]+aMovContr[i,15]
				SF1->F1_DIASSEG:=aMovContr[i,15]*aMovContr[i,14]
				MsUnlock()
			EndIf
		EndIf
	Next i

Return(.t.)

Static Function sfBaixaProduto()

	// Baixa Armazenagem de Produto
	For i:=1 To Len(aMovContr)
		If !aMovContr[i,Len(aMovContr[i])-1] .And. aMovContr[i,1]+aMovContr[i,2]+aMovContr[i,3]+aMovContr[i,4]+aMovContr[i,33] == (_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+(_TRBMOV)->C6_NUM+(_TRBMOV)->C6_ITEM
    		bAt:=.F.
    		If Posicione("SB1",1,xFilial("SB1")+aMovContr[i,05],"B1_TIPOSRV")=="2"
    			bAt:=.T.
    		EndIf
    		dbSelectArea("SF1")
			dbSetOrder(1)
			If dbSeek(xFilial("SF1")+aMovContr[i,35]+aMovContr[i,6]+aMovContr[i,7]) .And. bAt
				dDtAnt:=SF1->F1_DTFATPR
				RecLock("SF1",.F.)
				SF1->F1_DTFATPR:=aMovContr[i,17]+aMovContr[i,15]
				SF1->F1_DIASPRO:=aMovContr[i,15] * aMovContr[i,14]
				MsUnlock()
			EndIf
		EndIf
	Next i

Return(.t.)

Static Function sfBaixaContain()

	// Baixa Armazenagem de Container
	For i:=1 To Len(aMovContr)
		If !aMovContr[i,Len(aMovContr[i])-1] .And. aMovContr[i,1]+aMovContr[i,2]+aMovContr[i,3]+aMovContr[i,4]+aMovContr[i,33] == (_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+(_TRBMOV)->C6_NUM+(_TRBMOV)->C6_ITEM
    		bAt:=.F.
    		If Posicione("SB1",1,xFilial("SB1")+aMovContr[i,05],"B1_TIPOSRV")=="1"
    			bAt:=.T.
    		EndIf
    		dbSelectArea("SZ3")
			SZ3->(dbOrderNickName("Z3_RIC"))
			If dbSeek(xFilial("SZ3")+aMovContr[i,25]) .And. bAt
				RecLock("SZ3",.F.)
				SZ3->Z3_DTFATAR:=dDatabase
				MsUnlock()
			EndIf
		EndIf
	Next i

Return(.t.)

Static Function sfBaixaPacote()

	For i:=1 To Len(aMovContr)
		If !aMovContr[i,Len(aMovContr[i])-1] .And. aMovContr[i,1]+aMovContr[i,2]+aMovContr[i,3]+aMovContr[i,4]+aMovContr[i,33] == (_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+(_TRBMOV)->C6_NUM+(_TRBMOV)->C6_ITEM
    		bAt:=.F.
    		If Posicione("SB1",1,xFilial("SB1")+aMovContr[i,05],"B1_TIPOSRV")=="3"
    			bAt:=.T.
    		EndIf
    		dbSelectArea("SZ3")
			SZ3->(dbOrderNickName("Z3_RIC"))
			If dbSeek(xFilial("SZ3")+aMovContr[i,25]) .And. bAt
				RecLock("SZ3",.F.)
				SZ3->Z3_DTFATPA:=dDatabase
				MsUnlock()
			EndIf
		EndIf
	Next i

Return(.t.)

Static Function sfBaixaOS()

	// Baixa OS
	For i:=1 To Len(aMovContr)
		If !aMovContr[i,Len(aMovContr[i])-1] .And. aMovContr[i,1]+aMovContr[i,2]+aMovContr[i,3]+aMovContr[i,4]+aMovContr[i,33] == (_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+(_TRBMOV)->C6_NUM+(_TRBMOV)->C6_ITEM
    		dbSelectArea("SZ6")
			dbSetOrder(1)
			If dbSeek(xFilial("SZ6")+aMovContr[i,18])
				RecLock("SZ6",.F.)
				SZ6->Z6_STATUS:="P"
				MsUnlock()
			EndIf
			dbSelectArea("SZ7")
			dbSetOrder(1)
			If dbSeek(xFilial("SZ7")+aMovContr[i,18]+aMovContr[i,19])
				RecLock("SZ7",.F.)
				SZ7->Z7_DTFATAT:=dDataBase
				MsUnlock()
			EndIf
		EndIf
	Next i
	// Baixa OS do Pacote Logistico
	For i:=1 To Len(aMovContr)
		If !aMovContr[i,Len(aMovContr[i])-1] .And. aMovContr[i,1]+aMovContr[i,2]+aMovContr[i,37]+aMovContr[i,38]+aMovContr[i,33] == (_TRBMOV)->Z2_CODIGO+(_TRBMOV)->Z2_ITEM+(_TRBMOV)->AAN_CONTRT+(_TRBMOV)->AAN_ITEM+(_TRBMOV)->C6_NUM+(_TRBMOV)->C6_ITEM
    		dbSelectArea("SZ6")
			dbSetOrder(1)
			If dbSeek(xFilial("SZ6")+aMovContr[i,18])
				RecLock("SZ6",.F.)
				SZ6->Z6_STATUS:="P"
				MsUnlock()
			EndIf
			dbSelectArea("SZ7")
			dbSetOrder(1)
			If dbSeek(xFilial("SZ7")+aMovContr[i,18]+aMovContr[i,19])
				RecLock("SZ7",.F.)
				SZ7->Z7_DTFATAT:=dDataBase
				MsUnlock()
			EndIf
		EndIf
	Next i

Return(.t.)

Static Function sfVisualNFE()
	// cria variaveis internas do sistema
	private aParamAuto := {}

	nNF:=aScan(_aHeadMov,{|x| AllTrim(x[2])=="ZS_DOCREM"})
	dbSelectArea("SF1")
	dbSetOrder(1)
	If MsSeek(xFilial()+oBrwMov:aCols[oBrwMov:nAt,nNF]+(_TRBMOV)->A1_COD+(_TRBMOV)->A1_LOJA)
		A103NFiscal("SF1",SF1->(RecNo()),1)
	EndIf

Return(.t.)

User Function WMSA004N()

	dbSelectArea("SC5")
	dbSetOrder(1)
	If dbSeek(xFilial("SC5")+(_TRBMOV)->C6_NUM)
		A410Visual("SC5",SC5->(RecNo()),2)
	EndIf

Return(.t.)

User Function WMSA004Y()

	U_FATP001((_TRBMOV)->C6_NUM)

	Pergunte(_cPerg,.F.)
	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	dbGotop()
	While !EOF()
		(_TRBMOV)->(RecLock(_TRBMOV,.F.))
		(_TRBMOV)->(dbDelete())
		(_TRBMOV)->(MsUnlock())
		(_TRBMOV)->(dbSkip())
	EndDo
	_bMostraFat	:= (mv_par07 == 1)
	aMovContr	:= {}
	sfProcContrato()
	(_TRBMOV)->(dbSelectArea(_TRBMOV))
	dbGotop()

Return(.t.)

//** funcao que retorna a descricao de campo combobox
Static Function sfCBoxDescr(mvCampo,mvConteudo,mvPesq,mvRet)
Local _aAreaSX3 := SX3->(GetArea())
// retorno em array
// 1 -> S=Sim
// 2 -> S
// 3 -> Sim
Local _aCbox := RetSx3Box(Posicione('SX3',2,mvCampo,'X3CBox()'),,,TamSx3(mvCampo)[1])
Local _nPos  := aScan( _aCbox , {|x| AllTrim(x[mvPesq]) == AllTrim(mvConteudo) } )
Local _cRet  := If(_nPos>0,_aCbox[_nPos,mvRet],"")
// restaura area inicial
RestArea(_aAreaSX3)
Return(_cRet)

//** funcao responsavel pela Legenda
User Function WMSA004H
BrwLegenda(cCadastro, "Status",{{"ENABLE"	,"Apto a Faturar"},;
								{"BR_AZUL"	,"Ocorrência Sem Item no Contrato"},;
								{"BR_AMARELO","Cancelado"},;
								{"DISABLE"	,"Pedido de Venda Gerado"} })
Return

//** funcao para selecao dos itens a nao processar
User Function WMSA004A

local cCpos	:= "M->AAM_ZNAOFA"
local cVar	:= Upper( Alltrim( ReadVar() ) )

Static __cWhenLastVar__

DEFAULT __cWhenLastVar__ := "__cWhenLastVar__"

If ( cVar $ cCpos )

	IF !( __cWhenLastVar__ == cVar )
		CposInitWhen()
	EndIF

	IF ( CposInitWhen( NIL , .T. ) )
		// chama rotina padrao de opcoes
		f_Opcoes(@M->AAM_ZNAOFA,;				// variavel de retorno
				 "Opcoes para NAO faturar",;	// titulo da janela
				 nil,;							// opcoes de escolha
				 nil,;							// opcoes para retorno
				 nil,;							// nao utilizado
				 nil,;							// nao utilizado
				 .f.,;							// seleciona apenas 1 item
				 nil,;							// tamanho da chave
				 nil,;							// maximo de elementos de retorno
				 .t.,;							// botao para selecionar todos os itens
				 .t.,;							// se as opcoes vem de campo ComboBox (x3_cbox)
				 "B1_TIPOSRV")					// nome do campo

		CposInitWhen( .F. )

	EndIf
Else
	CposInitWhen()
EndIF

__cWhenLastVar__ := cVar

Return(.t.)