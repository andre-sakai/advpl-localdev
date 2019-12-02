#Include "rwmake.ch"
#Include "topconn.ch"
#Include "protheus.ch"
#Include "tbiconn.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณCEKCPYPED บAutor  ณRubem            บ Data ณ  30/07/17   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Rotina de transferencia de pedidos entre filiais do sistemaบฑฑ
ฑฑบ          ณ                                                         	   ฑฑ
ฑฑบ          ณ                                                             ฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
User Function CEKCPYPED()
	************************
	
	Local cQryDes := ""
	Local cPerg   := "CEKCPYPED"
	Local aCpoBro := {}
	Local _stru	  := {}
	Local nOpcao  := 0
	Private cNumNovoPed := ""
	Private cFilOri := ""
	Private cFilDes := ""
	Private cPedido := ""
	Private lInverte := .F.
	Private cMark	:= GetMark()
	Private oMark
	Private oSay1
	Private oFont, oTFont1
	
	AjustaSX1(cPerg)
	
	if !Pergunte(cPerg,.T.)
		Return
	Endif
	
	cFilOri := mv_par03//cFilAnt
	cFilDes := mv_par04//GetMV("MV_RPIMPEM")
	
	//Valido em que filial o usuแrio estแ logado, para garantir a integridade
	If cFilAnt <> cFilOri
		Msgstop("Favor logar na filial:" + cFilOri,"Atencao")
		Return
	EndIf
	
	If  cFilAnt == cFilDes
		MsgStop("Filial Origem / Destino iguais.")
		Return
	EndIf
	
	// Cria Fonte para visualiza็ใo
	oFont := TFont():New('Arial',,-14,.T.)
	oTFont1 := TFont():New('Arial Black',,18,.T.)
	
	//Cria um arquivo de Apoio
	AADD(_stru,{"OK"     ,		"C"	,2		,0		})
	AADD(_stru,{"FIL"    ,		"C"	,4		,0		})
	AADD(_stru,{"NUM"    ,		"C"	,6		,0		})
	AADD(_stru,{"CLI"    ,		"C"	,8		,0		})
	AADD(_stru,{"LOJA"   ,		"C"	,4		,0		})
	AADD(_stru,{"NOME"   ,		"C"	,30		,0		})
	AADD(_stru,{"EMISS"  ,		"D"	,8		,0		})
	AADD(_stru,{"CONDPG" ,		"C"	,3		,0		})
	AADD(_stru,{"VOL" ,			"N"	,5		,0		})
	AADD(_stru,{"PESLIQ",		"N"	,11		,4		})
	AADD(_stru,{"PESOBRU",		"N"	,11		,4		})
	
	cArq:=Criatrab(_stru,.T.)
	DBUSEAREA(.t.,,carq,"PRB") //Alimenta o arquivo de apoio com os registros da tabela1
	
	// Buscar dados de despesas
	cQryDes := " SELECT C5_FILIAL, C5_VOLUME1,C5_PESOL,C5_PBRUTO,C5_NUM, C5_CLIENTE, C5_LOJACLI, C5_CONDPAG, C5_EMISSAO "
	cQryDes += " FROM "+RetSqlName("SC5")+" SC5 "
	cQryDes += " WHERE SC5.C5_FILIAL = '"+mv_par03+"' "
	cQryDes += " AND SC5.C5_NUM >= '"+MV_PAR01+"' "
	cQryDes += " AND SC5.C5_NUM <= '"+MV_PAR02+"' "
	cQryDes += " AND SC5.D_E_L_E_T_ <> '*' "
	cQryDes += " ORDER BY SC5.C5_FILIAL, SC5.C5_NUM "
	
	cQryDes := ChangeQuery(cQryDes)
	
	If Select("QRY") <> 0
		QRY->(dbCloseArea())
	Endif
	
	TCQuery cQryDes Alias QRY New
	
	incProc("Buscando Informa็๕es de Pedidos...")
	
	While QRY->(!EOF())
		
		DbSelectArea("PRB")
		RecLock("PRB",.T.)
		PRB->FIL    	:=  QRY->C5_FILIAL
		PRB->NUM		:=  QRY->C5_NUM
		PRB->CLI    	:=  QRY->C5_CLIENTE
		PRB->LOJA   	:=  QRY->C5_LOJACLI
		PRB->NOME   	:=  POSICIONE("SA1",1,xfilial("SA1")+QRY->C5_CLIENTE+QRY->C5_LOJACLI,"A1_NREDUZ")
		PRB->EMISS 	:=  STOD(QRY->C5_EMISSAO)
		PRB->CONDPG	:=  QRY->C5_CONDPAG
		PRB->VOL		:=  QRY->C5_VOLUME1
		PRB->PESLIQ	:=  QRY->C5_PESOL
		PRB->PESOBRU	:=  QRY->C5_PBRUTO
		
		MsunLock()
		
		QRY->(DbSkip())
	EndDo
	
	//Define quais colunas (campos da PRB) serao exibidas na MsSelect
	aCpoBro	:= {{ "OK"			,, "Mark"           ,"@!"},;
		{ "FIL"			,, "Filial"       ,"@!"},;
		{ "NUM"			,, "Nr Pedido"    ,"@!"},;
		{ "CLI"			,, "Cod. Cliente" ,"@!"},;
		{ "LOJA"		,, "Loja Cliente" ,"@X"},;
		{ "NOME"		,, "Nome Cliente" ,"@X"},;
		{ "EMISS"		,, "Emissใo "     ,"@E"},;
		{ "CONDPG"		,, "Cond. Pagto"  ,"@!"},;
		{ "VOL"		,, "Vol"  ,"@!"},;
		{ "PESLIQ"		,, "PesoLiq"  ,"@!"},;
		{ "PESOBRU"		,, "PesoBrutoo"  ,"@!"}}
	
	
	//Cria a tela
	DEFINE MSDIALOG oDlg TITLE "Pedidos de Venda a copiar" From 0,0 To 552,1310 PIXEL
	
	//Posiciono a tabela 1
	DbSelectArea("PRB")
	PRB->(DbGotop()) //Cria a MsSelect
	
	oSay1:= TSay():New(01,02,{||'Selecione as pedidos:'},oDlg,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,100,20)
	oMark := MsSelect():New("PRB","OK","",aCpoBro,@lInverte,@cMark,{30,5,260,650},,,,,)
	oMark:bMark := {| | PRB->(DISP())} //Exibe a Dialog
	
	ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,{|| nOpcAo:=1,oDlg:End()},{|| oDlg:End()},,)
	
	If nOpcAo == 1
		Processa( {|| U_RPTEMP1() },'Salvando','Processando registros, por favor aguarde...')
	Endif
	
	//Fecha a Area e elimina os arquivos de apoio criados em disco.
	PRB->(DbCloseArea())
	Iif(File(cArq + GetDBExtension()),FErase(cArq  + GetDBExtension()) ,Nil)
	
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณDisp      บ Autor ณ Microsiga IDE      บ Data ณ  09/05/16   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Fun็ใo para marcar um registro 						      บฑฑ
ฑฑบ			 ณ 														      บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/
Static Function DISP()
	
	If PRB->(Marked("OK"))
		RecLock("PRB",.F.)
		PRB->OK := cMark
		PRB->(MSUNLOCK())
	Else
		RecLock("PRB",.F.)
		PRB->OK := ""
		PRB->(MSUNLOCK())
	Endif
	
	oMark:oBrowse:Refresh()
	
Return()

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณRPTEMP1   บ Autor ณ Microsiga IDE      บ Data ณ  05/08/16   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Fun็ใo para chamar a rotina que gravarแ os pedidos         บฑฑ
ฑฑบ			 ณ 														      บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/
User Function RPTEMP1()
	
	Private cPeds := ""
	
	DbSelectArea("PRB")
	PRB->(DbGoTop())
	While PRB->(!Eof())
		
		If Alltrim(PRB->OK) <> ''
			cPedido := PRB->NUM
			
			//Chamo a rotina que vai fazer a c๓pia do pedido atual para a filial do parโmetro.
			MsAguarde({|lEnd| U_RPDTRANS(cFilOri, cFilDes, cPedido)},"Aguarde...","Transferindo Pedido",.T.)
			
		EndIf
		PRB->(DbSkip())
	EndDo
	
	If !Empty(cPeds)
		MsgAlert("Pedido/s: "+cPeds+" criado na filial: " + cFilDes)
	EndIf
	
Return()

User Function RPDTRANS(cFilOri, cFilDes, cPedido)
	*************************************************
	
	Local _aAreaC5 := SC5->(GetArea())
	Local _aAreaC6 := SC6->(GetArea())
	Local _aAreaM0 := SM0->(GetArea())
	Local _cFlTmp  := cFilAnt
	Local cClitmp  := ""
	Local cLojtmp  := ""
	Local cQuery   := ""
	//Local cDoc	   := ""
	Local cTes	   := ""
	Local cPedant  := ""
	Local i, h, x
	Local xItem := {}
	Local xCab  := {}
	Local xItens := {}
	Local _aRet := {}
	Local _cPeds := ""
	Local _cPeds2 := ""
	Local _cPeds3 := ""
	
	
	Local nTotal 		:= 0
	
	cQuery := " SELECT * FROM " + RetSqlName("SC5") + " SC5 "
	cQuery += " WHERE "
	cQuery += " SC5.C5_FILIAL = '"+cFilOri+"' "
	//cQuery += " AND SC5.C5_TIPO = 'N' "
	cQuery += " AND SC5.C5_NUM = '"+cPedido+"' "
	cQuery += " AND SC5.D_E_L_E_T_ <> '*' "
	cQuery += " ORDER BY SC5.C5_FILIAL, SC5.C5_NUM "
	
	if Select("QRY") <> 0
		QRY->(dbCloseArea())
	Endif
	
	TCQuery cQuery Alias "QRY" New
	
	While QRY->(!EOF())
		
		DbSelectArea("SC5")
		SC5->(DbSetORder(1))
		If SC5->(DbSeek(QRY->C5_ZPEDANT))
			//If SC5->(DbSeek(QRY->C5_OBRA))
			MsgAlert("Esse pedido jแ foi copiado para outra filial. O pedido na filial destino 0201 ้ "+SC5->C5_NUM)
		Else
			xCab := {}
			SC5->(dbGoTo(QRY->R_E_C_N_O_))
			
			//Gravo todos os campos do pedido no Array xCab
			//For h := 1 to SC5->(fCount())
			//	aadd(xCab,{SC5->(FieldName(h)), &("SC5->" + SC5->(FieldName(h))), ".T."})
			//Next
			
			
			
			
			aadd(xCab,{"C5_NUM"    ,"",Nil})
			aadd(xCab,{"C5_TIPO"   ,"N",Nil})
			aadd(xCab,{"C5_CLIENTE",Substr(Posicione("SM0",1,"01"+cFilOri,"M0_CGC"),1,8),Nil})
			aadd(xCab,{"C5_CLIENT" ,Substr(Posicione("SM0",1,"01"+cFilOri,"M0_CGC"),1,8),Nil})
			aadd(xCab,{"C5_LOJACLI",Substr(Posicione("SM0",1,"01"+cFilOri,"M0_CGC"),9,4),Nil})
			aadd(xCab,{"C5_LOJAENT",Substr(Posicione("SM0",1,"01"+cFilOri,"M0_CGC"),9,4),Nil})
			aadd(xCab,{"C5_CONDPAG",QRY->C5_CONDPAG,Nil})
			//IFF(QRY->C5_CLIENTE == "08677036","019", QRY->C5_CONDPAG)
			///aadd(xCab,{"C5_CONDPAG",IFF(QRY->C5_CLIENTE == "08677036","019", QRY->C5_CONDPAG),Nil})
			//	aadd(xCab,{"C5_CONDPAG","009",Nil})
			aadd(xCab,{"C5_TABELA" ,"011",Nil})
			aadd(xCab,{"C5_MENNOTA",Alltrim("Pedido Origem: " + cPedido + " Filial: " + cFilOri +" Cliente: "+Alltrim(Posicione("SA1",1,xFilial("SA1")+QRY->C5_CLIENTE+QRY->C5_LOJACLI,"A1_NOME"))),Nil})
			aadd(xCab,{"C5_ZPEDANT",QRY->C5_FILIAL+QRY->C5_NUM,Nil})
			aadd(xCab,{"C5_VOLUME1",QRY->C5_VOLUME1,Nil})
			aadd(xCab,{"C5_PESOL",QRY->C5_PESOL,Nil})
			
			
			
			/*
			
			For i := 1 to Len(xCab)
				If xCab[i][1] == "C5_NUM"
					xCab[i][2] := ""
				EndIf
				
				//Preencho as informa็๕es do cabe็alho com o que peguei anteriormente
				If xCab[i][1] == "C5_CLIENTE" .OR. xCab[i][1] == "C5_CLIENT"
					xCab[i][2] := Substr(Posicione("SM0",1,"01"+cFilOri,"M0_CGC"),1,8)
				EndIf
				If xCab[i][1] == "C5_LOJACLI" .OR. xCab[i][1] == "C5_LOJAENT"
					xCab[i][2] := Substr(Posicione("SM0",1,"01"+cFilOri,"M0_CGC"),9,4)
				EndIf
				
				//Aqui eu escrevo nas observa็๕es do pedido a informa็ใo de onde originou o pedido. Ou seja, digo que veio do pedido tal da filial tal.
				If xCab[i][1] == "C5_ZOBS"
					xCab[i][2] += Chr(13) + Chr(10) + "Pedido Origem: " + cPedido + " Filial: " + cFilOri
				EndIf
			Next i
			*/
			xItens := {}
			//Fa็o agora a busca dos itens do pedido
			SC6->(dbSetOrder(1))
			SC6->(dbSeek(cFilOri + QRY->C5_NUM))
			While SC6->(!EOF()) .and. SC6->C6_FILIAL == cFilOri .and. SC6->C6_NUM = QRY->C5_NUM
				xItem := {}
				
				DbSelectArea("SB1")
				SB1->(DbSetOrder(1))
				If !(SB1->(DbSeek(xFilial("SB1")+SC6->C6_PRODUTO)))
					_cPeds += SC6->C6_PRODUTO+ Chr(13) + Chr(10)
				EndIf
				
				aadd(xItem,{"C6_ITEM",SC6->C6_ITEM,Nil})
				aadd(xItem,{"C6_PRODUTO",SC6->C6_PRODUTO,Nil})
				aadd(xItem,{"C6_QTDVEN",SC6->C6_QTDVEN,Nil})
				
				//aadd(xItem,{"C6_PRCVEN",SC6->C6_PRCVEN,Nil})
				//aadd(xItem,{"C6_PRUNIT",0,Nil})
				DbSelectArea("DA1")
				DA1->(DbSetOrder(1))
				If DA1->(DbSeek(xFilial("DA1")+'011'+SC6->C6_PRODUTO))
					If DA1->DA1_PRCVEN = 0
						_cPeds3 += SC6->C6_PRODUTO+ Chr(13) + Chr(10)
					Else
						aadd(xItem,{"C6_PRCVEN",DA1->DA1_PRCVEN,Nil})
						aadd(xItem,{"C6_PRUNIT",DA1->DA1_PRCVEN,Nil})
						aadd(xItem,{"C6_VALOR",SC6->C6_QTDVEN*DA1->DA1_PRCVEN,Nil})
						
						//Recebe total do pedido para condi็ใo tipo 9
						nTotal += SC6->C6_QTDVEN*DA1->DA1_PRCVEN
					
					EndIf
				Else
					_cPeds2 += SC6->C6_PRODUTO+ Chr(13) + Chr(10)
					aadd(xItem,{"C6_PRCVEN",1,Nil})
					aadd(xItem,{"C6_PRUNIT",1,Nil})
					aadd(xItem,{"C6_VALOR",SC6->C6_QTDVEN*1,Nil})
				EndIf
				aadd(xItem,{"C6_OPER","01",Nil})
				//aadd(xItem,{"C6_TES",SC6->C6_TES,Nil})
				/*
				If !Empty(cTes)
					aadd(xItem,{"C6_TES",cTes,Nil})
				Else
					MsgAlert("Tes Inteligente nใo cadastrada para a filial atual.")
					Return
				EndIf
				*/
				
				//Adicion o item no array xItens
				aAdd(xItens, xItem)
				SC6->(dbSkip())
			EndDo
			
			
			dbSelectArea("SE4")
			dbSetOrder(1)
			If MsSeek(xFilial("SE4")+QRY->C5_CONDPAG)
				If SE4->E4_TIPO =="9"
					aadd(xCab,{"C5_PARC1",nTotal,Nil})
					aadd(xCab,{"C5_DATA1",DDatabase,Nil})
				Endif
				
			Endif
			
			
			If Len(xItens) <> 0
				
				If Len(_cPeds) > 0
					MsgAlert("Os produtos nใo estใo cadastrados: "+ Chr(13) + Chr(10)+_cPeds)
					Return
				ElseIf Len(_cPeds2) > 0
					MsgAlert("Os produtos nใo estใo na tabela de pre็o: "+ Chr(13) + Chr(10)+_cPeds2)
					Return
				ElseIf Len(_cPeds3) > 0
					MsgAlert("Os produtos estใo na tabela de pre็o com valor zerado: "+ Chr(13) + Chr(10)+_cPeds3)
					Return
				EndIf
				//_aRet := startjob("u_criaped",getenvserver(),.T.,{xCab, xItens, cFilDes})
				_aRet := u_criaped({xCab, xItens, cFilDes})
				
				/*
				aArqs := {"SC5","SC6","SA1"}
				aPar := {"","01","0101"}
				
				If Select("SX6") == 0
					lJob := .T.
					xEmp := aPar[2]
					xFil := aPar[3]
					RPCSetType(3)
					RpcSetEnv (xEmp,xFil,,,,,aArqs)
				Endif
				*/
				
				RestArea(_aAreaM0)
				RestArea(_aAreaC6)
				RestArea(_aAreaC5)
				
				//Fa็o amarra็ใo do pedido anterior com o pedido atual
				If _aRet[1]
					DbSelectArea("SC5")
					SC5->(DbSetOrder(1))
					If SC5->(DbSeek(xFilial("SC5")+cPedido))
						Reclock("SC5",.F.)
						SC5->C5_ZPEDANT := cFilDes+_aRet[2]
						//SC5->C5_OBRA := cFilDes+_aRet[2]
						SC5->(MsUnlock())
					EndIf
				EndIf
			Endif
			
			
			cPeds += " "+_aRet[2]+" - "
			
		EndIf
		QRY->(dbSkip())
	EndDo
	
Return

Static Function AjustaSX1(cPerg)
	********************************
	Local aHelpPor := {}
	
	aTam := TamSX3("C5_NUM")
	aAdd(aHelpPor, "Informe os n๚meros dos pedidos de venda De:.   " )
	aAdd(aHelpPor, "Para buscar os pedidos que serใo exibidos na   " )
	aAdd(aHelpPor, "tela.		                                   " )
	PutSx1(cPerg,"01","Pedido De? ","","","mv_ch01",aTam[3],6,aTam[2],0,"G","","SC5","","","mv_par01","","","","","","","","","","","","","","","","",aHelpPor,{},{})
	
	aTam := TamSX3("C5_NUM")
	aAdd(aHelpPor, "Informe os n๚meros dos pedidos de venda Ate.   " )
	aAdd(aHelpPor, "Para buscar os pedidos que serใo exibidos na   " )
	aAdd(aHelpPor, "tela.		                                   " )
	PutSx1(cPerg,"02","Pedido Ate? ","","","mv_ch02",aTam[3],6,aTam[2],0,"G","","SC5","","","mv_par02","","","","","","","","","","","","","","","","",aHelpPor,{},{})
	
	
	aHelpPor := {}
	aTam := TamSX3("C5_FILIAL")
	aAdd(aHelpPor, "Filial De. Selecionar a  ")
	aAdd(aHelpPor, "filial de origem do pedido.")
	PutSx1(cPerg,"03","Filial De ? ","","","mv_ch03",aTam[3],aTam[1],aTam[2],0,"G","","","","","mv_par03","","","","","","","","","","","","","","","","",aHelpPor,{},{})
	
	
	aHelpPor := {}
	aTam := TamSX3("C5_FILIAL")
	aAdd(aHelpPor, "Filial Para. Selecionar a  ")
	aAdd(aHelpPor, "filial de destino do pedido.")
	PutSx1(cPerg,"04","Filial Para ? ","","","mv_ch04",aTam[3],aTam[1],aTam[2],0,"G","","","","","mv_par04","","","","","","","","","","","","","","","","",aHelpPor,{},{})
	
Return

User Function CriaPed(aParas)
	*****************************
	Local aArea := GetArea()
	
	Local cClitmp  := ""
	Local cLojtmp  := ""
	Local aCab := aParas[1]
	Local aIts := aParas[2]
	Local _cFilialDes := aParas[3]
	Local lRet := .F.
	Local cTable := "SC5"
	//RPCSetType(3)
	//RpcSetEnv( "01",_cFilialDes, "", "", "FAT", "MATA410", {'SC5','SC6','SA1'}, , , ,  )
	//PREPARE ENVIRONMENT EMPRESA '01' FILIAL '0201'; TABLES 'SC5,SC6,SA1' MODULO 'FAT'
	
	Local aArqs    := {"SC5","SC6","SA1"}
	Local aPar := {"","01",_cFilialDes}
	
	
	//RpcClearEnv()
	
	If Select("SX6") == 0
		lJob := .T.
		xEmp := aPar[2]
		xFil := aPar[3]
		RPCSetType(3)
		RpcSetEnv (xEmp,xFil,,,,,aArqs)
	Endif
	
	Private cDoc := ""
	
	cBkp := cFilAnt  // faz o backup da filial posicionada
	cFilAnt := _cFilialDes
	cDoc := GetSxeNum("SC5","C5_NUM")
	RollBackSxE()
	
	
	
	// E adiciono na C5_NUM do xCab
	For j := 1 to Len(aCab)
		If aCab[j][1] == "C5_NUM"
			aCab[j][2] := cDoc
		EndIf
		//Guardo o cliente
		If aCab[j][1] == "C5_CLIENTE"
			cClitmp := aCab[j][2]
		EndIf
		//Guardo a loja
		If aCab[j][1] == "C5_LOJACLI"
			cLojtmp := aCab[j][2]
		EndIf
		
	Next j
	/*
	For h := 1 to Len(xItens)
		If xItens[h][2][1] == "C6_PRODUTO"
			cPrd	:= xItens[h][2][2]
		EndIf
		cTes	:= MaTesInt(2,"01",Substr(Posicione("SM0",1,"01"+cFilOri,"M0_CGC"),1,8),Substr(Posicione("SM0",1,"01"+cFilOri,"M0_CGC"),9,4),"C",cPrd)
		If Empty(Alltrim(cTes))
			MsgAlert("Nใo existe Tes Intelig๊nte para o produto: "+cPrd)
			Return
		EndIf
	Next h
	*/
	Begin Transaction
		
		lMsErroAuto := .F.
		
		msExecAuto({|x,y,z|Mata410(x,y,z)},aCab,aIts,3)
		
		If lMsErroAuto
			lRet := .F.
			cDoc := ""
			
			MostraErro()
			
			//MostraErro('C:\Temp','errocopiaped.log')
			DisarmTransaction()
		Else
			ConfirmSX8()
			lRet := .T.
		EndIf
		
		
	End Transaction
	
	//RESET ENVIRONMENT
	//RpcClearEnv()
	cFilAnt := cBkp
	RestArea(aArea)
	
Return ({lRet,cDoc})
