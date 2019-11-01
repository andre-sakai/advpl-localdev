#Include 'Protheus.ch'
#Include 'TopConn.ch'

//------------------------------------------------------------------------------//
// Programa: TWMSC020 | Autor: Gustavo Schumann / SLA TI | Data: 31/10/2018		//
//------------------------------------------------------------------------------//
// Descrição: Altera informações dos endereços.									//
//------------------------------------------------------------------------------//

User Function TWMSC020()
	Local oGrpCab,oSay,oGetCli,oGrpProd,oSBtSav,oSBtExt,oGetQMax
	Local cCliente	:= AllTrim(SBE->BE_ZCODCLI) + ' - ' + AllTrim(Posicione("SA1",1,xFilial("SA1")+SBE->BE_ZCODCLI,"A1_NOME"))
	Local cProduto	:= SBE->BE_CODPRO
	Local nQtdMin	:= SBE->BE_ZESTMIN
	Local nQtdMax	:= SBE->BE_ZESTMAX
	Local oFont15 := TFont():New('Arial',,-12,,.F.)
	Local oFont16n:= TFont():New('Arial',,-16,,.T.)
	Local oFont18 := TFont():New('Arial',,-18,,.F.)
	Private oDlg,oGetProd,oGetQMin

	oDlg	:= MSDialog():new(1,1,265,435,'Altera informações dos endereços',,,,,CLR_BLACK,CLR_WHITE,,,.t.)
	oGrpCab	:= TGroup():Create(oDlg,003,003,18,215,,,,.T.)
	oSay	:= TSay():New(005,005,{||'Endereço ' + AllTrim(SBE->BE_LOCALIZ)},oGrpCab,,oFont18,,,,.T.,CLR_BLACK,CLR_WHITE,300,20)

	oGetCli	:= TGet():New(023,015,{|u|if(PCount()>0,cCliente:=u,cCliente)},oDlg,170,008,"@!",,CLR_BLACK,CLR_WHITE,oFont15,,,.T.,,,{||},,,{||},.T.,.F.,,'',,,,.T.,.F.,,"Cliente",2,oFont16n)
	oGetCli:Disable()

	oGrpProd := TGroup():Create(oDlg,40,003,110,215,'Dados para Picking',,,.T.)
	oGetProd := TGet():New(050,008,{|u|if(PCount()>0,cProduto:=u,cProduto)},oGrpProd,150,008,PesqPict("SB1","B1_COD"),,CLR_BLACK,CLR_WHITE,oFont15,,,.T.,,,{||},,,{||},.F.,.F.,"SB1PRD",'cProduto',,,,.T.,.F.,.T.,"Produto        ",2,oFont16n)
	oGetQMin := TGet():New(068,008,{|u|if(PCount()>0,nQtdMin:=u,nQtdMin)},oGrpProd,100,008,PesqPict("SBE","BE_ZESTMIN"),,CLR_BLACK,CLR_WHITE,oFont15,,,.T.,,,{||},,,{||},.F.,.F.,,'',,,,.T.,.F.,,"Qtd.Mínima p/ Abastecimento    ",2,oFont16n)
	oGetQMax := TGet():New(086,008,{|u|if(PCount()>0,nQtdMax:=u,nQtdMax)},oGrpProd,100,008,PesqPict("SBE","BE_ZESTMAX"),,CLR_BLACK,CLR_WHITE,oFont15,,,.T.,,,{||},,,{||},.F.,.F.,,'',,,,.T.,.F.,,"Qtd.Máxima p/ Abastecimento    ",2,oFont16n)
	oSBtSav	 := SButton():New(115,008,01,{|| GrvDados(cProduto,nQtdMin,nQtdMax) },oDlg,.T.,,)
	oSBtExt	 := SButton():New(115,180,02,{|| oDlg:End() },oDlg,.T.,,)

	oDlg:Activate()

Return
//-------------------------------------------------------------------------------------------------
Static Function GrvDados(cProduto,nQtdMin,nQtdMax)
	Local lOK		:= .T.
	Local cProdSBF	:= Posicione("SBF",1,xFilial("SBF")+SBE->BE_LOCAL+SBE->BE_LOCALIZ,"BF_PRODUTO")
	Local nSldSBF	:= Posicione("SBF",1,xFilial("SBF")+SBE->BE_LOCAL+SBE->BE_LOCALIZ,"BF_QUANT")
	Local cGrpProd	:= AllTrim(Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_GRUPO"))
	Local cSigla	:= AllTrim(Posicione("SA1",1,xFilial("SA1")+SBE->BE_ZCODCLI,"A1_SIGLA"))

	// caso tenha qualquer saldo neste endereço (tabela SBF), não deixa alterar o produto (somente os campos de quantidade)
	// mas pode zerar (tirar o produto do endereço picking e deixar sem)
	If (lOK) .And. (nSldSBF > 0)
		If ( AllTrim(cProduto) != AllTrim(cProdSBF) ) .AND. ( !Empty(cProduto) )
			MsgAlert("Erro! Foi localizado saldo fiscal neste endereço! Não é possível alterar o produto cadastrado. " + CRLF + CRLF + "Produto encontrado : " + AllTrim(cProdSBF),"TWMSC020")
			oGetProd:SetFocus()
			lOK := .F.
		EndIf
	EndIf

	// caso quantidade minima = maxima
	If (lOK) .And. (nQtdMin == nQtdMax)
		MsgAlert("Atenção! As Quantidades mínima e máxima não podem ser iguais!","TWMSC020")
		oGetQMin:SetFocus()
		lOK := .F.
	EndIf

	// caso qtd máxima menor que mínima (ou vice-versa)
	If (lOK) .And. (nQtdMin > nQtdMax)
		MsgAlert("Atenção! A quantidade mínima não pode maior que a quantidade máxima!","TWMSC020")
		oGetQMin:SetFocus()
		lOK := .F.
	EndIf

	// se produto alterado não pertencer ao cliente (validar por B1_GRUPO = A1_SIGLA)
	If (lOK) .AND. (!Empty(cProduto)) .And. (cGrpProd <> cSigla)
		MsgAlert("Atenção! O produto informado não pertence ao cliente cadastrado para o endereço!","TWMSC020")
		oGetProd:SetFocus()
		lOK := .F.
	EndIf

	If (lOK)
		RecLock("SBE",.F.)
		SBE->BE_CODPRO := cProduto
		SBE->BE_ZESTMIN:= nQtdMin
		SBE->BE_ZESTMAX:= nQtdMax
		MsUnLock()

		oDlg:End()
	EndIf

Return