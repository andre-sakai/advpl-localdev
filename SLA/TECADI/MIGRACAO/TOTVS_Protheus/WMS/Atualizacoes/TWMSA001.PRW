#Include "Totvs.ch"
#Include "Colors.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Registro de Entrada/Saida de Containers                 !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 10/2010 !
+------------------+---------------------------------------------------------+
!Observacoes       ! Necessario criar a consulta padrao SZ2MOV, com a funcao !
!                  ! de usuario WMSA001A                                     !
!                  ! Necessario criar a consulta padrao SZ3MOV, com a funcao !
!                  ! de usuario WMSA001B                                     !
+------------------+--------------------------------------------------------*/

User Function TWMSA001

	// fontes utilizadas
	Private oFntVerd18 := TFont():New("Verdana",,18,,.t.)
	Private oFntVerd13 := TFont():New("Verdana",,13,,.f.)
	// tipo de operacao
	Private _lEntrada	:= .t.
	// recebimento duplo de container
	Private _lRecDuplo	:= .f.
	// define se eh carga solta
	Private _lCargaSol	:= .f.
	// usuario com permissao de estorno
	Private _lUsrEstor := (__cUserId $ AllTrim(SuperGetMv("TC_USRESTO",.f.,"")))

	// controle de uso de chegada de veiculos
	private _lCtrlCheg := .f.

//	If ( FWInputBox("Rotina desativada em 10/09/18. Insira a senha:","") != "itajai" )
//		MsgAlert("Senha inválida. Esta rotina está desativada. Utilize a rotina de controle por CESV.")
//		Return( .F. )
//	EndIf

	// tela de opcoes
	sfDefMovim()

Return

// ** funcao para selecionar a opcao do tipo de movimento
Static Function sfDefMovim()

	// definicao da tela
	_oDlgOpcoes := MSDialog():New(000,000,200,420,"Opções de Movimentações de Veículos",,,.F.,,,,,,.T.,,,.T. )
	// opcoes de movimentacao (entrada/saida containers)
	_oBtnEntConta := TButton():New(010,010,"Entrada Containers",_oDlgOpcoes,{|| sfMovConta("E") },090,020,,oFntVerd18,,.T.,,"",,,,.F. )
	_oBtnSaiConta := TButton():New(010,110,"Saída Containers",_oDlgOpcoes,{|| sfMovConta("S") },090,020,,oFntVerd18,,.T.,,"",,,,.F. )
	// entrada/saida carga solta
	_oBtnEntCarga := TButton():New(040,010,"Entrada Carga Solta",_oDlgOpcoes,{|| sfMovSolta("E") },090,020,,oFntVerd18,,.T.,,"",,,,.F. )
	_oBtnSaiCarga := TButton():New(040,110,"Saída Carga Solta",_oDlgOpcoes,{|| sfMovSolta("S") },090,020,,oFntVerd18,,.T.,,"",,,,.F. )
	// botao para sair
	_oBtnOpSair  := TButton():New(070,110,"Sair",_oDlgOpcoes,{|| _oDlgOpcoes:End() },090,020,,oFntVerd18,,.T.,,"",,,,.F. )
	// ativa o dialogo
	_oDlgOpcoes:Activate(,,,.T.,)

Return

// ** funcao para movimentacoes de container
Static Function sfMovConta(mvTipo)
	// campos utilizados
	Private _dDtReceb	:= dDataBase // cnfe solicitacao do Daniel 25.01 -> Date()

	// dados do cliente
	Private _cCodCli	:= CriaVar("A1_COD",.f.)
	Private _cLojCli	:= CriaVar("A1_LOJA",.f.)
	Private _cNomCli	:= CriaVar("A1_NOME",.f.)

	Private _cNumProg	:= CriaVar("Z1_CODIGO",.f.)
	Private _cIteProg	:= CriaVar("Z2_ITEM",.f.)

	// praca (origem ou destino)
	Private _cCodPraca	:= CriaVar("ZB_CODIGO",.f.)
	Private _cDscPraca	:= CriaVar("ZB_DESCRI",.f.)

	// informacoes de containers
	Private _aConteudo	:= sfCboxToArray("Z2_CONTEUD",.t.)

	// container 1
	Private _cNumCont1	:= CriaVar("Z3_CONTAIN",.f.)
	Private _cTamCont1	:= ""
	Private _cTipCont1	:= ""
	Private _cConteud1	:= ""
	Private _nTara1		:= 0
	Private _cLacre1	:= CriaVar("Z3_LACRE",.f.)
	Private _aAvarias1	:= {}
	Private _aFotos1	:= {Space(300),Space(300),Space(300)}

	// container 2
	Private _cNumCont2	:= CriaVar("Z3_CONTAIN",.f.)
	Private _cTamCont2	:= ""
	Private _cTipCont2	:= ""
	Private _cConteud2	:= ""
	Private _nTara2		:= 0
	Private _cLacre2	:= CriaVar("Z3_LACRE",.f.)
	Private _aAvarias2	:= {}
	Private _aFotos2	:= {Space(300),Space(300),Space(300)}

	// transportadora do contrato
	Private _cTranContr	:= CriaVar("A4_COD",.f.)
	// transportadora da mercadoria
	Private _cCodTransp	:= CriaVar("A4_COD",.f.)
	Private _cNomTransp	:= CriaVar("A4_NOME",.f.)

	// placas
	Private _cPlaca1	:= CriaVar("DA3_COD",.f.)
	Private _cPlaca2	:= CriaVar("DA3_COD",.f.)

	// motorista
	Private _cCodMotor	:= CriaVar("DA4_COD",.f.)
	Private _cNomMotor	:= CriaVar("DA4_NOME",.f.)

	// armador
	Private _cCodArmad	:= CriaVar("ZA_CODIGO",.f.)
	Private _cNomArmad	:= CriaVar("ZA_DESCRI",.f.)

	// observacoes
	Private _cObserv	:= CriaVar("Z3_OBS",.f.)

	// RECNOs do SZ3 utilizado para apontamento de saida
	Private _aRecnoSZ3	:= {0,0}

	// tipo de operacao
	_lEntrada := (mvTipo=="E")

	// recebimento duplo de container
	_lRecDuplo := .f.

	// carga solta
	_lCargaSol := .f.

	// define teclas de atalho
	SetKey(VK_F5,{|| oBtnDuplic:Click() } )
	SetKey(VK_F7,{|| oBtnEstorno:Click() } )
	SetKey(VK_F9,{|| oBtnConfRec:Click() } )
	SetKey(VK_F10,{|| oBtnFechar:Click() } )

	// definicao da tela
	oDlgContainer := MSDialog():New(000,000,400,920,"Movimentação de Containers",,,.F.,,,,,,.T.,,,.T. )

	// data de movimentacao
	oSayDtMov := TSay():New(010,012,{||"Data de Movimentação"},oDlgContainer,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetDtMov := TGet():New(008,110,{|u| If(PCount()>0,_dDtReceb:=u,_dDtReceb)},oDlgContainer,070,011,,,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_dDtReceb",,)
	oGetDtMov:Disable()

	// dados do cliente
	oSayCliente := TSay():New(025,012,{||"Cód/Loja Cliente"},oDlgContainer,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCodCli := TGet():New(023,110,{|u| If(PCount()>0,_cCodCli:=u,_cCodCli)},oDlgContainer,050,011,PesqPict("SA1","A1_COD"),{||Vazio().or.sfVldCliente()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SA1","_cCodCli",,)
	oGetLojCli := TGet():New(023,165,{|u| If(PCount()>0,_cLojCli:=u,_cLojCli)},oDlgContainer,030,011,PesqPict("SA1","A1_LOJA"),{||Vazio().or.sfVldCliente()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cLojCli",,)
	oGetNomCli := TGet():New(023,200,{|u| If(PCount()>0,_cNomCli:=u,_cNomCli)},oDlgContainer,180,011,PesqPict("SA1","A1_NOME"),,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomCli",,)
	oGetNomCli:Disable()

	// numero e item da programacao
	oSayProgram := TSay():New(040,012,{||"Programação/Item"},oDlgContainer,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetNumProg := TGet():New(038,110,{|u| If(PCount()>0,_cNumProg:=u,_cNumProg)},oDlgContainer,050,011,PesqPict("SZ1","Z1_CODIGO"),{||Vazio().or.sfVldNumProg()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SZ2MOV","_cNumProg",,)
	oGetNumProg:BWHEN := {||_lEntrada}
	oGetIteProg := TGet():New(038,165,{|u| If(PCount()>0,_cIteProg:=u,_cIteProg)},oDlgContainer,030,011,PesqPict("SZ2","Z2_ITEM"),{||Vazio().or.sfVldNumProg()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIteProg",,)
	oGetIteProg:BWHEN := {||_lEntrada}

	// praca (origem/destino)
	oSayPraca := TSay():New(055,012,{|| "Praça de "+If(_lEntrada,"Origem","Destino")},oDlgContainer,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCodPraca := TGet():New(053,110,{|u| If(PCount()>0,_cCodPraca:=u,_cCodPraca)},oDlgContainer,050,011,PesqPict("SZB","ZB_CODIGO"),{||Vazio().or.sfVldPraca()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SZB","_cCodPraca",,)
	If (_lEntrada)
		oGetCodPraca:Disable()
	EndIf
	oGetDscPraca := TGet():New(053,165,{|u| If(PCount()>0,_cDscPraca:=u,_cDscPraca)},oDlgContainer,200,011,PesqPict("SZB","ZB_DESCRI"),,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cDscPraca",,)
	oGetDscPraca:Disable()

	// dados container 1
	oSayCont1 := TSay():New(085,012,{||"Container 1"},oDlgContainer,,oFntVerd18,.F.,.F.,.F.,.T.)
	// numero do container 1
	oSayNumCont1 := TSay():New(076,070,{||"Número"},oDlgContainer,,oFntVerd13,.F.,.F.,.F.,.T.)
	oGetNumCont1 := TGet():New(083,070,{|u| If(PCount()>0,_cNumCont1:=u,_cNumCont1)},oDlgContainer,080,011,PesqPict("SZC","ZC_CODIGO"),{||Vazio().or.sfVldNumCont() },,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SZC","_cNumCont1",,)
	// tamanho do container 1
	oSayTamCont1 := TSay():New(076,155,{||"Tamanho"},oDlgContainer,,oFntVerd13,.F.,.F.,.F.,.T.)
	oGetTamCont1 := TGet():New(083,155,{|u| If(PCount()>0,_cTamCont1:=u,_cTamCont1)},oDlgContainer,025,011,"@!",,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cTamCont1",,)
	oGetTamCont1:Disable()
	// tipo do container 1
	oSayTipCont1 := TSay():New(076,185,{||"Tipo"},oDlgContainer,,oFntVerd13,.F.,.F.,.F.,.T.)
	oGetTipCont1 := TGet():New(083,185,{|u| If(PCount()>0,_cTipCont1:=u,_cTipCont1)},oDlgContainer,050,011,"@!",,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cTipCont1",,)
	oGetTipCont1:Disable()

	// conteudo do container 1
	oSayConteud1 := TSay():New(076,240,{||"Conteúdo"},oDlgContainer,,oFntVerd13,.F.,.F.,.F.,.T.)
	oGetConteud1 :=  TComboBox():New(084,240,{|u| If(PCount()>0,_cConteud1:=u,_cConteud1)},_aConteudo,050,011,oDlgContainer,,,,,,.T.,oFntVerd18,"",,,,,,,_cConteud1)

	// tara container 1
	oSayTara1 := TSay():New(076,295,{||"Tara"},oDlgContainer,,oFntVerd13,.F.,.F.,.F.,.T.)
	oGetTara1 := TGet():New(083,295,{|u| If(PCount()>0,_nTara1:=u,_nTara1)},oDlgContainer,035,011,PesqPict("SZ3","Z3_TARA"),,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nTara1",,)
	oGetTara1:Disable()
	// lacre container 1
	oSayLacre1 := TSay():New(076,350,{||"Lacre"},oDlgContainer,,oFntVerd13,.F.,.F.,.F.,.T.)
	oGetLacre1 := TGet():New(083,350,{|u| If(PCount()>0,_cLacre1:=u,_cLacre1)},oDlgContainer,070,011,PesqPict("SZ3","Z3_LACRE"),,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cLacre1",,)
	// botao para informar as avarias
	oBtnAvar1 := TButton():New(083,426,"Avaria",oDlgContainer,{|| sfAvarias("1") },030,012,,,,.T.,,"",,,,.F. )

	// dados container 2
	oSayCont2 := TSay():New(101,012,{||"Container 2"},oDlgContainer,,oFntVerd18,.F.,.F.,.F.,.T.)
	// numero do container 2
	oGetNumCont2 := TGet():New(099,070,{|u| If(PCount()>0,_cNumCont2:=u,_cNumCont2)},oDlgContainer,080,011,PesqPict("SZC","ZC_CODIGO"),{||Vazio().or.sfVldNumCont() },,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SZC","_cNumCont2",,)
	oGetNumCont2:Disable()
	// tamanho do container 2
	oGetTamCont2 := TGet():New(099,155,{|u| If(PCount()>0,_cTamCont2:=u,_cTamCont2)},oDlgContainer,025,011,"@!",,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cTamCont2",,)
	oGetTamCont2:Disable()
	// tipo do container 2
	oGetTipCont2 := TGet():New(099,185,{|u| If(PCount()>0,_cTipCont2:=u,_cTipCont2)},oDlgContainer,050,011,"@!",,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cTipCont2",,)
	oGetTipCont2:Disable()

	// conteudo do container 2
	oGetConteud2 :=  TComboBox():New(100,240,{|u| If(PCount()>0,_cConteud2:=u,_cConteud2)},_aConteudo,050,011,oDlgContainer,,,,,,.T.,oFntVerd18,"",,,,,,,_cConteud2)

	// tara container 2
	oGetTara2 := TGet():New(099,295,{|u| If(PCount()>0,_nTara2:=u,_nTara2)},oDlgContainer,035,011,PesqPict("SZ3","Z3_TARA"),,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_nTara2",,)
	oGetTara2:Disable()
	// lacre container 2
	oGetLacre2 := TGet():New(099,350,{|u| If(PCount()>0,_cLacre2:=u,_cLacre2)},oDlgContainer,070,011,PesqPict("SZ3","Z3_LACRE"),,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cLacre2",,)
	oGetLacre2:Disable()
	// botao para informar as avarias
	oBtnAvar2 := TButton():New(099,426,"Avaria",oDlgContainer,{|| sfAvarias("2") },030,012,,,,.T.,,"",,,,.F. )

	// transportadora
	oSayTransp := TSay():New(124,012,{||"Transportadora"},oDlgContainer,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCodTransp := TGet():New(122,080,{|u| If(PCount()>0,_cCodTransp:=u,_cCodTransp)},oDlgContainer,050,011,PesqPict("SA4","A4_COD"),{||Vazio().or.sfVldTransp()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SA4","_cCodTransp",,)
	oGetNomTransp := TGet():New(122,135,{|u| If(PCount()>0,_cNomTransp:=u,_cNomTransp)},oDlgContainer,195,011,,,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomTransp",,)
	oGetNomTransp:Disable()

	// placa 1 (cavalo)
	oSayPlaca1 := TSay():New(124,340,{||"Placa 1"},oDlgContainer,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetPlaca1 := TGet():New(122,390,{|u| If(PCount()>0,_cPlaca1:=u,_cPlaca1)},oDlgContainer,050,011,PesqPict("DA3","DA3_COD"),{||Vazio().or.ExistCpo("DA3")},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"DA3","_cPlaca1",,)

	// motorista
	oSayMotor := TSay():New(139,012,{||"Motorista"},oDlgContainer,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCodMotor := TGet():New(137,080,{|u| If(PCount()>0,_cCodMotor:=u,_cCodMotor)},oDlgContainer,050,011,PesqPict("DA4","D4_COD"),{||Vazio().or.sfVldMotor()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"DA4","_cCodMotor",,)
	oGetNomMotor := TGet():New(137,135,{|u| If(PCount()>0,_cNomMotor:=u,_cNomMotor)},oDlgContainer,195,011,,,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomMotor",,)
	oGetNomMotor:Disable()

	// placa 2 (carreta)
	oSayPlaca2 := TSay():New(139,340,{||"Placa 2"},oDlgContainer,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetPlaca2 := TGet():New(137,390,{|u| If(PCount()>0,_cPlaca2:=u,_cPlaca2)},oDlgContainer,050,011,PesqPict("DA3","DA3_COD"),{||Vazio().or.ExistCpo("DA3")},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"DA3","_cPlaca2",,)

	// armador
	oSayArmador := TSay():New(154,012,{||"Armador"},oDlgContainer,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCodArmad := TGet():New(152,080,{|u| If(PCount()>0,_cCodArmad:=u,_cCodArmad)},oDlgContainer,050,011,PesqPict("DA4","D4_COD"),{||Vazio().or.sfVldArmador()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SZA","_cCodArmad",,)
	oGetCodArmad:Disable()
	oGetNomArmad := TGet():New(152,135,{|u| If(PCount()>0,_cNomArmad:=u,_cNomArmad)},oDlgContainer,195,011,,,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomArmad",,)
	oGetNomArmad:Disable()

	// observacoes
	oSayObs := TSay():New(169,012,{||"Observações"},oDlgContainer,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetObs := TGet():New(167,080,{|u| If(PCount()>0,_cObserv:=u,_cObserv)},oDlgContainer,250,011,PesqPict("SZ3","Z3_OBS"),,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cObserv",,)

	// descricao da operação
	oSayOperacao := TSay():New(184,080,{||If(_lEntrada,"ENTRADA","SAÍDA")},oDlgContainer,,oFntVerd18,.F.,.F.,.F.,.T.,CLR_GREEN)

	// botao para recebimento de container duplo
	oBtnDuplic := TButton():New(037,200,"Duplo (F5)",oDlgContainer,{|| sfRecDuplo() },050,014,,,,.T.,,"",,,,.F. )

	// botao de reimpressao
	oBtnReimpre := TButton():New(182,220,"Reimpressão RIC",oDlgContainer,{|| sfReimpres() },050,014,,,,.T.,,"",,,,.F. )

	// botao para exclusao de movimentacoes
	oBtnEstorno := TButton():New(182,280,"Estorno (F7)",oDlgContainer,{|| U_WMSA001C() },050,014,,,,.T.,,"",,,,.F. )

	// botoes de operacoes
	oBtnConfRec := TButton():New(182,340,"Confirmar (F9)",oDlgContainer,{|| U_WMSA001Z(Nil, .f., mvTipo,_lRecDuplo) },050,014,,,,.T.,,"",,,,.F. )
	// apontamento de retrabalho
	oBtnFechar := TButton():New(182,400,"Cancelar/Sair (F10)",oDlgContainer,{||oDlgContainer:End()},050,014,,,,.T.,,"",,,,.F. )

	// ativa o dialogo
	oDlgContainer:Activate(,,,.T.,)

	// zera teclas de atalho
	SetKey(VK_F5,{|| Nil})
	SetKey(VK_F7,{|| Nil})
	SetKey(VK_F9,{|| Nil})
	SetKey(VK_F10,{|| Nil})

Return

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
Return(.t.)

// ** funcao que valida o numero da programacao informada
Static Function sfVldNumProg()
	// cabecalho da programacao
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	If (!SZ1->(dbSeek( xFilial("SZ1")+_cNumProg )))
		MsgStop("Programação de Recebimentos não encontrada!")
		Return(.f.)
	EndIf

	// valida se a programacao esta encerrada
	If ( ! Empty(SZ1->Z1_DTFINFA))
		MsgStop("Programação encontra-se encerrada. Contate o setor de Faturamento.")
		Return(.f.)
	EndIf

	// itens da programacao
	dbSelectArea("SZ2")
	SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM
	If ( ! SZ2->(dbSeek( xFilial("SZ2")+_cNumProg+If(Empty(_cIteProg),"",_cIteProg) )))
		MsgStop("Programação de Recebimentos não encontrada!")
		Return(.f.)
	EndIf

	// verifica o saldo do item
	If (_lEntrada).and.(SZ2->Z2_QTDREC >= SZ2->Z2_QUANT)
		MsgStop("Não há mais Saldo à Receber deste Item da Programação!")
		Return(.f.)
	EndIf

	// valida item de carga solta
	If (_lCargaSol).and.(SZ2->Z2_TAMCONT <> "CS")
		MsgStop("O item selecionado da programação é para Containers!")
		Return(.f.)
	EndIf

	// valida item nao eh carga solta
	If (!_lCargaSol).and.(SZ2->Z2_TAMCONT=="CS")
		MsgStop("O item selecionado da programação é para Carga Solta!")
		Return(.f.)
	EndIf

	// na entrada atualiza os dados da praca
	If (_lEntrada)
		_cCodPraca := SZ2->Z2_PRCORIG
		_cDscPraca := Posicione("SZB",1, xFilial("SZB")+_cCodPraca ,"ZB_DESCRI")
	EndIf

	// atualiza informacoes da transportadora
	_cTranContr	:= SZ2->Z2_TRACONT // transportadora do contrato
	// transportadora da mercadoria
	If (_lEntrada)
		_cCodTransp := SZ2->Z2_TRANSP
		_cNomTransp := Posicione("SA4",1, xFilial("SA4")+_cCodTransp ,"A4_NOME")
	EndIf

	If (!_lCargaSol)
		oGetCodCli:Disable()
		oGetLojCli:Disable()
	EndIf

Return(.t.)

// ** funcao que retorna a descricao de campo combobox
Static Function sfCBoxDescr(mvCampo,mvConteudo,mvPesq,mvRet)
	Local _aAreaSX3 := SX3->(GetArea())
	// retorno em array
	// 1 -> S=Sim
	// 2 -> S
	// 3 -> Sim
	Local _aCbox := RetSx3Box(Posicione('SX3',2,mvCampo,'X3CBox()'),,,TamSx3(mvCampo)[1])
	Local _nPos  := aScan( _aCbox , {|x| AllTrim(x[mvPesq])==AllTrim(mvConteudo) } )
	Local _cRet  := If(_nPos>0,_aCbox[_nPos,mvRet],"")
	// restaura area inicial
	RestArea(_aAreaSX3)
Return(_cRet)

// ** funcao para ativar o recebimento duplo
Static Function sfRecDuplo()
	// ativa recebimento duplo
	_lRecDuplo := .t.
	// habilita o campo para edicao
	oGetNumCont2:Enable()
	If (_lEntrada)
		//oGetTara2:Enable()
	EndIf
	oGetLacre2:Enable()
	// replica os dados dos containers
	_cTamCont2	:= _cTamCont1
	_cTipCont2	:= _cTipCont1

Return

// ** funcao que valida os dados da transportadora
Static Function sfVldTransp()
	// cadastro de transportadora
	dbSelectArea("SA4")
	SA4->(dbSetOrder(1)) //1-A4_FILIAL, A4_COD
	If (!SA4->(dbSeek( xFilial("SA4")+_cCodTransp )))
		MsgStop("Transportadora não cadastrada!")
		Return(.f.)
	EndIf
	// nome da transportadora
	_cNomTransp := SA4->A4_NOME
Return(.t.)

// ** funcao que valida o dados do motorista
Static Function sfVldMotor()
	// cadastro de motoristas
	dbSelectArea("DA4")
	DA4->(dbSetOrder(1)) //1-DA4_FILIAL, DA4_COD
	If (!DA4->(dbSeek( xFilial("DA4")+_cCodMotor )))
		MsgStop("Motorista não cadastrado!")
		Return(.f.)
	EndIf
	// nome da transportadora
	_cNomMotor := DA4->DA4_NOME
Return(.t.)

// ** funcao que valida o armador
Static Function sfVldArmador()
	// cadastro de armadores
	dbSelectArea("SZA")
	SZA->(dbSetOrder(1)) //1-ZA_FILIAL, ZA_CODIGO
	If (!SZA->(dbSeek( xFilial("SZA")+_cCodArmad )))
		MsgStop("Armador não cadastrado!")
		Return(.f.)
	EndIf
	// nome do armador
	_cNomArmad := SZA->ZA_DESCRI
Return(.t.)

// ** funcao que valida a praca
Static Function sfVldPraca()
	// cadastro de armadores
	dbSelectArea("SZB")
	SZB->(dbSetOrder(1)) //1-ZB_FILIAL, ZB_CODIGO
	If (!SZB->(dbSeek( xFilial("SZB")+_cCodPraca )))
		MsgStop("Praça não cadastrada!")
		Return(.f.)
	EndIf

	// verifica se a praca de destino não é a localizacao padrao
	If (SZB->ZB_LOCALIZ=="S")
		MsgStop("A Praça de Destino não pode ser a Localização Padrão!")
		Return(.f.)
	EndIf

	// nome da praca
	_cDscPraca := SZB->ZB_DESCRI
Return(.t.)

// ** funcao que monta uma tela com a relacao da programacao de recebimentos do cliente (chamada pela consulta padrao SZ2MOV)
User Function WMSA001A()
	Local _cQuery
	Local _aHeadProg := {}
	Local _aColsProg := {}
	// controle de confirmacao
	Local _lRet := .f.

	// alimenta o header
	aAdd(_aHeadProg,{"Código", "Z1_CODIGO", PesqPict("SZ1","Z1_CODIGO"), TamSx3("Z1_CODIGO")[2], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadProg,{"Item", "Z2_ITEM", PesqPict("SZ2","Z2_ITEM"), TamSx3("Z2_ITEM")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadProg,{"Documento", "Z2_DOCUMEN", PesqPict("SZ2","Z2_DOCUMEN"), TamSx3("Z2_DOCUMEN")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadProg,{"Referencia", "Z1_REFEREN", PesqPict("SZ1","Z1_REFEREN"), TamSx3("Z1_REFEREN")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadProg,{"Tam.Container", "Z2_TAMCONT", PesqPict("SZ2","Z2_TAMCONT"), TamSx3("Z2_TAMCONT")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadProg,{"Tipo Container", "Z2_DSTPCON", PesqPict("SZ2","Z2_DSTPCON"), TamSx3("Z2_DSTPCON")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadProg,{"Conteúdo?", "Z2_CONTEUD", PesqPict("SZ2","Z2_CONTEUD"), TamSx3("Z2_CONTEUD")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadProg,{"Quantidade", "Z2_QUANT", PesqPict("SZ2","Z2_QUANT"), TamSx3("Z2_QUANT")[1], TamSx3("Z2_QUANT")[2],Nil,Nil,"N",Nil,"R" })
	aAdd(_aHeadProg,{"Qtd.Recebida", "Z2_QTDREC", PesqPict("SZ2","Z2_QTDREC"), TamSx3("Z2_QTDREC")[1], TamSx3("Z2_QTDREC")[2],Nil,Nil,"N",Nil,"R" })
	aAdd(_aHeadProg,{"Tipo", "Z1_TIPO", PesqPict("SZ1","Z1_TIPO"), TamSx3("Z1_TIPO")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadProg,{"Observacao", "Z1_OBS", PesqPict("SZ1","Z1_OBS"), TamSx3("Z1_OBS")[1], 0,Nil,Nil,"C",Nil,"R" })

	_cQuery := "SELECT Z1_CODIGO, Z2_ITEM, Z2_DOCUMEN, Z1_REFEREN, Z2_TAMCONT, X5_DESCRI Z2_DSTPCON, Z2_CONTEUD, Z2_QUANT, Z2_QTDREC, Z1_TIPO, Z1_OBS, '.F.' IT_DEL "
	// programacao de recebimento
	_cQuery += "FROM "+RetSqlName("SZ1")+" SZ1 (nolock) "
	// itens da programacao
	_cQuery += "INNER JOIN "+RetSqlName("SZ2")+" SZ2  (nolock) ON "+RetSqlCond("SZ2")+" AND Z2_CODIGO = Z1_CODIGO "
	// nao controla o saldo na saida da carga solta
	If (_lEntrada)
		_cQuery += "AND Z2_QTDREC < Z2_QUANT "
	EndIf
	// carga solta
	_cQuery += "AND Z2_TAMCONT "+If(_lCargaSol,"=","<>")+" 'CS' "
	// descricao do tipo de container
	_cQuery += "INNER JOIN "+RetSqlName("SX5")+" SX5  (nolock) ON "+RetSqlCond("SX5")+" AND X5_TABELA = 'ZA' AND X5_CHAVE = Z2_TIPCONT "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SZ1")+" "
	// cliente e loja
	_cQuery += "AND Z1_CLIENTE = '"+_cCodCli+"' AND Z1_LOJA = '"+_cLojCli+"' "
	// nao esteja encerrada
	_cQuery += "AND Z1_DTFINFA = ' ' "
	// ordem dos dados
	_cQuery += "ORDER BY Z2_CODIGO, Z2_ITEM"
	// alimenta o acols com o resultado do SQL
	_aColsProg := U_SqlToVet(_cQuery)

	// verifica se há programacoes para visualizar
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

// ** funcao para confirmar o recebimento
User Function WMSA001Z(mvCesv, mvRotAut, mvTpOper, mvCntDuplo)
	// quantidade de containers
	Local _nQtdCont := IIF(mvCntDuplo,2,1)
	Local _nCont, _nRIC, _nX
	Local _cTmpNrCont, _cTmpConteu, _cTmpTamanh, _cTmpTipo, _cTmpTara, _cTmpLacre, _cTmpAvari
	Local _cNumSeq := ""
	// armazena o Nr a RIC para impressao
	Local _aImpreRIC := {}
	// numero da programacao de entrada, usada para o movimento de saida
	Local _cTmpNrRec := ""
	Local _cTmpItRec := ""
	// parametro, conforme tipo de operacao
	Local _cTmpParam := IIf(_lCargaSol, "TC_NUM_CS", "TC_NUMRIC")
	// controle do numero da RIC
	Local _cNrRIC := AllTrim(GetMv(_cTmpParam))
	// controle de inclusao/alteracao
	Local _lIncluir := .t.
	// verifica se a entrada ja esta com pacote logistico faturado
	local _lFatPctLog := .f.
	// numero da RIC de entrada (utilizada para agregar o frete ao pacote logistico)
	local _cNumRicEnt := ""
	// data de faturamento de pacote e frete
	local _dDtFatPac := CtoD("//")
	local _dDtFatFre := CtoD("//")

	// containers
	local _aCnt := {}
	// atividades para geracao da OS automatica
	local _aAtv := {}
	// prefixo para pesquisa a ativicade de handling
	local _cPrfHand := ""
	
	local cPrcPadr := AllTrim(SuperGetMv("TC_PRCPADR",.f.," "))

	// valores padroes da rotina
	Default mvRotAut := .f.
	Default mvTpOper := " "
	Default mvCesv   := CriaVar("ZZ_CESV", .f.)

	// caso o parâmetro venha preenchido, respeita o mesmo
	If ( ! Empty(mvTpOper) )
		_lEntrada := (mvTpOper == "E")
	EndIf

	// -- valida se os campos foram informados

	// cliente
	If (Empty(_cCodCli)).or.(Empty(_cLojCli))
		MsgStop("Campos Obrigatórios -> Código do Cliente e Loja")
		Return(.f.)
	EndIf

	// numero da programacao
	If ( (_lEntrada).or.((!_lEntrada).and.(_lCargaSol)) ).and.( (Empty(_cNumProg)).or.(Empty(_cIteProg)) )
		MsgStop("Campos Obrigatórios -> Código da Programação e Item")
		Return(.f.)
	EndIf

	// quando saida, codigo da praca de destino
	If (!_lEntrada).and.(Empty(_cCodPraca))
		MsgStop("Campos Obrigatórios -> Praça de Destino")
		Return(.f.)
	EndIF

	// container 1 e 2
	If (!_lCargaSol).and.(Empty(_cNumCont1)).or.((_lRecDuplo).and.(Empty(_cNumCont2)))
		MsgStop("Campos Obrigatórios -> Número do Container")
		Return(.f.)
	EndIf

	// tara
	If (!_lCargaSol).and.(Empty(_nTara1)).or.((_lRecDuplo).and.(Empty(_nTara2)))
		MsgStop("Campos Obrigatórios -> Tara")
		Return(.f.)
	EndIf

	// lacre
	If (!_lCargaSol).and.(Empty(_cLacre1)).or.((_lRecDuplo).and.(Empty(_cLacre2)))
		MsgStop("Campos Obrigatórios -> Lacre")
		Return(.f.)
	EndIf

	// transportadora e motorista
	If (Empty(_cCodTransp)).or.(Empty(_cCodMotor))
		MsgStop("Campos Obrigatórios -> Transportadora e Motorista")
		Return(.f.)
	EndIf

	// placas
	If (Empty(_cPlaca1))
		MsgStop("Campos Obrigatórios -> Placa 1")
		Return(.f.)
	EndIf

	// armador
	If (!_lCargaSol).and.(Empty(_cCodArmad))
		MsgStop("Campos Obrigatórios -> Armador")
		Return(.f.)
	EndIf

	// quando saida, valida o conteudo do conteiner
	If (Empty(_cConteud1)) .or. ( (_lRecDuplo) .and. (Empty(_cConteud2)) )
		MsgStop("Campos Obrigatórios -> Conteúdo da Carga")
		Return(.f.)
	EndIF

	// posiciona na programacao
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	If SZ1->(dbSeek( xFilial("SZ1")+_cNumProg ))
		// valida se a programacao esta encerrada
		If ( ! Empty(SZ1->Z1_DTFINFA))
			MsgStop("Programação encontra-se encerrada. Contate o setor de Faturamento.")
			Return(.f.)
		EndIf
	EndIf

	// valida o saldo a receber
	If (_lEntrada)
		dbSelectArea("SZ2")
		SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM
		SZ2->(dbSeek( xFilial("SZ2")+_cNumProg+_cIteProg ))
		If ((SZ2->Z2_QTDREC+_nQtdCont) > SZ2->Z2_QUANT)
			MsgStop("Não há mais Saldo à Receber deste Item da Programação!")
			Return(.f.)
		EndIf
	EndIf

	// quando nao for rotina automatica
	If ( ! mvRotAut )
		// confirmacao dos dados
		If ( ! MsgYesNo("Confirma Movimentação ?", "Confirmação"))
			Return(.f.)
		EndIf
	EndIf

	// se for recebimento duplo, prepara NUMSEQ de relacionamento dos registros
	If (_lEntrada).and.(_lRecDuplo)
		_cNumSeq := ProxNum()
	EndIf

	// INICIA TRANSACAO
	BEGIN Transaction

		For _nCont := 1 to _nQtdCont

			// reinicia variaveis
			_lFatPctLog := .f.
			_cNumRicEnt := ""
			_dDtFatPac  := CtoD("//")
			_dDtFatFre  := CtoD("//")

			// posiciona na programacao
			dbSelectArea("SZ1")
			SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
			SZ1->(dbSeek( xFilial("SZ1")+_cNumProg ))

			// atualiza o movimento ORIGEM de entrada, definindo a data de saida
			If ( ! _lEntrada )

				// rotina padrao
				// caso seja pela rotina automatica o procedimento de saída está sendo realizado pela função sfsaida no TWMSA008
				If ( ! mvRotAut )
					dbSelectArea("SZ3")
					SZ3->(dbGoTo(_aRecnoSZ3[_nCont]))
					RecLock("SZ3")
					SZ3->Z3_DTSAIDA	:= _dDtReceb
					SZ3->Z3_HRSAIDA	:= Left(Time(),5)
					MsUnLock()

				EndIF
				// armazena o numero da programacao, para usar no Mov de Saida
				_cTmpNrRec := SZ3->Z3_PROGRAM
				_cTmpItRec := SZ3->Z3_ITEPROG
				// atualiza o faturamento de pacote logistico
				_lFatPctLog := (!Empty(SZ3->Z3_DTFATPA))
				// armazena o numero da RIC de entrada
				_cNumRicEnt := SZ3->Z3_RIC
				// armazena datas de faturamento de pacote e frete
				_dDtFatPac := SZ3->Z3_DTFATPA
				_dDtFatFre := SZ3->Z3_DTFATFR
			EndIf

			// atualiza o registro de chegada do caminhao
			If (_lEntrada) .and. (_lCargaSol) .and. (_lCtrlCheg)
				// posicao no registro de chegada
				dbSelectArea("SZ3")
				SZ3->(dbGoTo(_aRecnoSZ3[_nCont]))
				// muda a operacao para alterar
				_lIncluir := .f.
			EndIf

			// monta variaveis do container
			_cTmpNrCont := "_cNumCont"+Str(_nCont,1)
			_cTmpConteu	:= "_cConteud"+Str(_nCont,1)
			_cTmpTamanh	:= "_cTamCont"+Str(_nCont,1)
			_cTmpTipo	:= "_cTipCont"+Str(_nCont,1)
			_cTmpTara	:= "_nTara"+Str(_nCont,1)
			_cTmpLacre	:= "_cLacre"+Str(_nCont,1)
			_cTmpAvari	:= "_aAvarias"+Str(_nCont,1)

			// grava os dados da movimentacao
			dbSelectArea("SZ3")
			RecLock("SZ3",_lIncluir)
			SZ3->Z3_FILIAL	:= xFilial("SZ3")
			SZ3->Z3_DTMOVIM	:= _dDtReceb
			SZ3->Z3_HRMOVIM	:= Left(Time(),5)
			SZ3->Z3_TPMOVIM	:= IIf(_lEntrada,"E","S")
			SZ3->Z3_CLIENTE	:= _cCodCli
			SZ3->Z3_LOJA	:= _cLojCli
			SZ3->Z3_CONTAIN	:= IIf(_lCargaSol,"",&(_cTmpNrCont))
			SZ3->Z3_CONTEUD	:= sfCBoxDescr("Z2_CONTEUD",&(_cTmpConteu),3,2)
			// conteudo atual do container (sera alterado caso a mercadorias seja carregada/descarregada atraves da ord de servico)
			SZ3->Z3_CONTATU	:= SZ3->Z3_CONTEUD
			SZ3->Z3_TAMCONT	:= IIf(_lCargaSol,"CS",sfCBoxDescr("ZC_TAMANHO",&(_cTmpTamanh),3,2))
			SZ3->Z3_TIPCONT	:= IIf(_lCargaSol,"99",&(_cTmpTipo))
			SZ3->Z3_DUPLO	:= IIf(_lRecDuplo,"S","N")
			SZ3->Z3_NUMSEQ	:= _cNumSeq
			SZ3->Z3_TRACONT	:= _cTranContr
			SZ3->Z3_TRANSP	:= _cCodTransp
			SZ3->Z3_PLACA1	:= _cPlaca1
			SZ3->Z3_PLACA2	:= _cPlaca2
			SZ3->Z3_MOTORIS	:= _cCodMotor
			SZ3->Z3_TARA	:= IIf(_lCargaSol,0,&(_cTmpTara))
			SZ3->Z3_LACRE	:= IIf(_lCargaSol,"",&(_cTmpLacre))
			SZ3->Z3_OBS		:= _cObserv
			SZ3->Z3_ARMADOR	:= IIf(_lCargaSol,"",_cCodArmad)
			// numero da cesv/szz
			If ( ! Empty(mvCesv) )
				SZ3->Z3_CESV := mvCesv // CESV da SZZ
			EndIf

			// codigos das pracas de movimentacao
			If (_lEntrada)
				SZ3->Z3_PRCORIG	:= _cCodPraca
				SZ3->Z3_PRCDEST	:= cPrcPadr
				// sequencia da entrada
				SZ3->Z3_SEQUENC	:= sfRetSequen(_cNumProg,_cIteProg)
				// numero e item da programacao
				SZ3->Z3_PROGRAM	:= _cNumProg
				SZ3->Z3_ITEPROG	:= _cIteProg
			ElseIf (!_lEntrada)
				SZ3->Z3_PRCORIG	:= cPrcPadr
				SZ3->Z3_PRCDEST	:= _cCodPraca
				// sequencia da saida
				SZ3->Z3_SEQUENC	:= sfRetSequen(_cTmpNrRec,_cTmpItRec)
				// relaciona o movimento de saida com o de entrada
				SZ3->Z3_PROGRAM	:= _cTmpNrRec
				SZ3->Z3_ITEPROG	:= _cTmpItRec
				// data e hora de saida
				SZ3->Z3_DTSAIDA	:= _dDtReceb
				SZ3->Z3_HRSAIDA	:= Left(Time(),5)
			EndIf

			// atualiza o numero da RIC
			SZ3->Z3_RIC		:= _cNrRIC
			SZ3->Z3_RICIMP	:= "N" // RIC Impressa ?

			// codigo do usuario
			If (SZ3->(FieldPos('Z3_USRINCL'))>0)
				SZ3->Z3_USRINCL := __cUserId
			EndIf

			SZ3->(MsUnLock())

			// armazena o Nr da RIC para impressao da RIC
			aAdd(_aImpreRIC,_cNrRIC)

			// atualiza controle de numeracao da RIC
			PutMv(_cTmpParam,Soma1(_cNrRIC))

			// atualizados dos dados da programacao
			If (_lEntrada)
				// atualiza data de inicio
				If Empty(SZ1->Z1_DTABERT)
					RecLock("SZ1")
					SZ1->Z1_DTABERT := _dDtReceb
					MsUnLock()
				EndIf

				// controle da quantidade recebida
				dbSelectArea("SZ2")
				SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM
				SZ2->(dbSeek( xFilial("SZ2")+_cNumProg+_cIteProg ))
				// atualiza quantidade recebida
				RecLock("SZ2")
				SZ2->Z2_QTDREC += 1
				MsUnLock()
			EndIf

			// grava as informacoes das avarias
			If (!_lCargaSol).and.(Len(&_cTmpAvari) > 0)
				For _nX := 1 to Len(&_cTmpAvari)
					// inclui as avarias da RIC
					dbSelectArea("SZE")
					RecLock("SZE",.t.)
					SZE->ZE_FILIAL	:= xFilial("SZE")
					SZE->ZE_RIC		:= _cNrRIC
					SZE->ZE_CODAVAR	:= &_cTmpAvari[_nX,1]
					SZE->ZE_OBS		:= &_cTmpAvari[_nX,2]
					SZE->ZE_CONTAIN	:= &(_cTmpNrCont)
					SZE->ZE_DATA	:= _dDtReceb
					MsUnLock()
				Next _nX
			EndIf

			//Inclui Ordem de Servico para handling do container
			If (_lEntrada).and.(!_lCargaSol)
				// zera variaveis
				_aCnt := {}
				_aAtv := {}
				// adiciona os dados da movimentacao
				Aadd(_aCnt,{&(_cTmpNrCont),"E",_cNumProg,_cIteProg,_cCodCli,_cLojCli,_dDtReceb,"F",_cNrRIC,"","","",""})

				// define prefixo para handling
				If SZ1->Z1_TIPO $ "I|E"
					_cPrfHand := "HC"
				Else
					_cPrfHand := "H"+AllTrim(SZ3->Z3_CONTEUD)
				EndIf

				// varre todos os servicos
				dbSelectArea("SZT")
				dbSetOrder(1)
				dbGoTop()
				While SZT->(!EOF())
					If (SZT->ZT_TIPO == _cPrfHand)
						Exit
					EndIf
					// proximo item
					SZT->(dbSkip())
				EndDo

				// adiciona o handling
				Aadd(_aAtv,{SZT->ZT_CODIGO, "", "", "01", "S", "A", 1, "", SZT->ZT_UM})

				// se for ENTRADA, conteudo CHEIO e container tipo TANK, lança 053-ADICIONAL CARGA IMO
				If (SZ3->Z3_CONTEUD=="C").and.(SZ3->Z3_TIPCONT=="07") // 07-TANK
					// pesquisa servico
					dbSelectArea("SZT")
					SZT->(dbSetOrder(1)) // 1-ZT_FILIAL, ZT_CODIGO
					SZT->(dbSeek( xFilial("SZT")+"053" ))

					Aadd(_aAtv,{SZT->ZT_CODIGO, "", "", "02", "S", "A", 1, "", SZT->ZT_UM})
				EndIf

				// se for ENTRADA, conteudo CHEIO e armador 000042-TECADI, lança 103-OVACAO COM CNTR TECADI
				If (SZ3->Z3_CONTEUD=="C").and.(_cCodArmad=="000042")
					// pesquisa servico
					dbSelectArea("SZT")
					SZT->(dbSetOrder(1)) // 1-ZT_FILIAL, ZT_CODIGO
					SZT->(dbSeek( xFilial("SZT")+"103" ))

					Aadd(_aAtv,{SZT->ZT_CODIGO, "", "", "03", "S", "A", 1, "", SZT->ZT_UM})
				EndIf

				// rotina para geracao da OS automática
				U_WMSA002I(_aCnt, _aAtv, .F. , .F. )

			EndIf

			// geracao de OS automatica para Portobello
			If (_lEntrada) .and. (_lCargaSol) .and. (_cCodCli == "000467") .and. (SZ1->Z1_TPMOVIM == "E") .And. (SZ1->Z1_CONTRT == "000000000000802")
				// zera variaveis
				_aCnt := {}
				_aAtv := {}
				// adiciona os dados da movimentacao
				Aadd(_aCnt,{"", "E", _cNumProg, _cIteProg, _cCodCli, _cLojCli, _dDtReceb, "A" ,_cNrRIC, "", "", _cPlaca1, ""})

				// pesquisa servico
				dbSelectArea("SZT")
				SZT->(dbSetOrder(1)) // 1-ZT_FILIAL, ZT_CODIGO
				SZT->(dbSeek( xFilial("SZT")+"011" ))

				// define atividades
				Aadd(_aAtv,{SZT->ZT_CODIGO, "", "", "01", "S", "P", 1, "", SZT->ZT_UM})

				// rotina para geracao da OS automática
				U_WMSA002I(_aCnt, _aAtv, .F. , .T. )

			EndIf

			// geracao de OS automatica para Klabin (chamado #13122)
			If (_lEntrada) .and. (_lCargaSol) .and. (_cCodCli == "000449") .and. (SZ1->Z1_CONTRT $ "000000000000793/000000000000857/000000000000794/000000000000860/000000000000795/000000000000796/000000000000797")
				// zera variaveis
				_aCnt := {}
				_aAtv := {}
				// adiciona os dados da movimentacao
				Aadd(_aCnt,{"", "E", _cNumProg, _cIteProg, _cCodCli, _cLojCli, _dDtReceb, "A" ,_cNrRIC, "", "", _cPlaca1, ""})

				// pesquisa servico
				dbSelectArea("SZT")
				SZT->(dbSetOrder(1)) // 1-ZT_FILIAL, ZT_CODIGO
				SZT->(dbSeek( xFilial("SZT") + "015" )) // 015-DESCARGA MECANIZADA / CARRETA

				// define atividades
				Aadd(_aAtv,{SZT->ZT_CODIGO, "", "", "01", "S", "P", 1, "", SZT->ZT_UM})

				// rotina para geracao da OS automática
				U_WMSA002I(_aCnt, _aAtv, .F. , .T. )

			EndIf
			
			// geracao de OS automatica para Guararapes (chamado #15868 / redmine #147)
			If (_lEntrada) .and. (_lCargaSol) .and. (_cCodCli == "000557") .and. (SZ1->Z1_CONTRT == "000000000000962")
				// zera variaveis
				_aCnt := {}
				_aAtv := {}
				// adiciona os dados da movimentacao
				Aadd(_aCnt,{"", "E", _cNumProg, _cIteProg, _cCodCli, _cLojCli, _dDtReceb, "A" ,_cNrRIC, "", "", _cPlaca1, ""})

				// pesquisa servico
				dbSelectArea("SZT")
				SZT->(dbSetOrder(1)) // 1-ZT_FILIAL, ZT_CODIGO
				SZT->(dbSeek( xFilial("SZT") + "015" )) // 015-DESCARGA MECANIZADA / CARRETA

				// define atividades
				Aadd(_aAtv,{SZT->ZT_CODIGO, "", "", "01", "S", "P", 1, "", SZT->ZT_UM})

				// rotina para geracao da OS automática
				U_WMSA002I(_aCnt, _aAtv, .F. , .T. )

			EndIf
			
			// geracao de OS automatica para Eletro Aço Altona S/A (chamado #17242)
			If (_lEntrada) .and. (_lCargaSol) .and. (_cCodCli == "000009")
				// zera variaveis
				_aCnt := {}
				_aAtv := {}
				// adiciona os dados da movimentacao
				Aadd(_aCnt,{"", "E", _cNumProg, _cIteProg, _cCodCli, _cLojCli, _dDtReceb, "A" ,_cNrRIC, "", "", _cPlaca1, ""})

				// pesquisa servico
				dbSelectArea("SZT")
				SZT->(dbSetOrder(1)) // 1-ZT_FILIAL, ZT_CODIGO
				SZT->(dbSeek( xFilial("SZT") + "015" )) // 015-DESCARGA MECANIZADA / CARRETA

				// define atividades
				Aadd(_aAtv,{SZT->ZT_CODIGO, "", "", "01", "S", "P", 1, "", SZT->ZT_UM})

				// rotina para geracao da OS automática
				U_WMSA002I(_aCnt, _aAtv, .F. , .T. )

			EndIf
			
			// geracao de OS automatica para Industria de Compensados Guararapes (chamado #17242)
			If (_lEntrada) .and. (_lCargaSol) .and. (_cCodCli == "000580")
				// zera variaveis
				_aCnt := {}
				_aAtv := {}
				// adiciona os dados da movimentacao
				Aadd(_aCnt,{"", "E", _cNumProg, _cIteProg, _cCodCli, _cLojCli, _dDtReceb, "A" ,_cNrRIC, "", "", _cPlaca1, ""})

				// pesquisa servico
				dbSelectArea("SZT")
				SZT->(dbSetOrder(1)) // 1-ZT_FILIAL, ZT_CODIGO
				SZT->(dbSeek( xFilial("SZT") + "163" )) // 163 - DESCARGA DE MERCADORIA

				// define atividades
				Aadd(_aAtv,{SZT->ZT_CODIGO, "", "", "01", "S", "P", 1, "", SZT->ZT_UM})

				// rotina para geracao da OS automática
				U_WMSA002I(_aCnt, _aAtv, .F. , .T. )

			EndIf

			// na saida, verifica se deve relacionar o movimento com o pacote logistico
			If ( ! _lEntrada ) .and. (_lFatPctLog)
				// agrupa o movimento de saida com o pacote logistico
				sfAgrMovFre(_cNumRicEnt)

				// atualiza a data de faturamento no movimento de saida
				dbSelectArea("SZ3")
				RecLock("SZ3")
				SZ3->Z3_DTFATPA := _dDtFatPac
				SZ3->Z3_DTFATFR := _dDtFatFre
				SZ3->(MsUnLock())

			EndIf

		Next _nCont

		// FINALIZA TRANSACAO
	END Transaction

	// verifica se deve realizar a impressao
	If (!_lCargaSol).and.(MsgYesNo("Confirma impressão da RIC ?", "Impressão"))
		For _nRIC := 1 to Len(_aImpreRIC)
			// funcao para impressao da RIC
			U_WMSA001D(_aImpreRIC[_nRIC])
		Next _nRIC
	EndIf

	// verifica a necessidade de enviar os dados da RIC por email
	If (MsgYesNo("Confirma o envio de e-mail com as informações da RIC ?", "Envio de E-mail"))
		For _nRIC := 1 to Len(_aImpreRIC)
			// funcao para envio de email com os dados da RIC
			sfEnvMail(_aImpreRIC[_nRIC], _nRIC, mvCesv, mvRotAut, mvTpOper)
		Next _nRIC
	EndIf

	// fecha a tela de apontamento
	IIf(_lCargaSol,_oDlgCarSol:End(),oDlgContainer:End())

Return(.t.)

// ** funcao que retorna a ultima sequencia de recebimento da programacao
Static Function sfRetSequen(mvNumProg,mvIteProg)
	Local _cQuery
	Local _cRet := ""

	_cQuery := "SELECT MAX(Z3_SEQUENC) FROM "+RetSqlName("SZ3")
	_cQuery += " WHERE Z3_FILIAL = '" + xFilial("SZ3") + "' AND D_E_L_E_T_ = ' ' "
	_cQuery += " AND Z3_PROGRAM = '" + mvNumProg + "' AND Z3_ITEPROG = '" + mvIteProg + "'"
	// tipo da movimentacao
	_cQuery += " AND Z3_TPMOVIM = '" + If(_lEntrada,"E","S") + "'"

	// excuta a query
	_cRet := U_FtQuery(_cQuery)
	// prepara o retorno
	If (Empty(_cRet))
		_cRet := StrZero(1,Len(SZ3->Z3_SEQUENC))
	Else
		_cRet := Soma1(_cRet)
	EndIf
Return(_cRet)

// ** funcao que monta uma tela com a relacao de container (chamada pela consulta padrao SZ3MOV)
User Function WMSA001B(mvCodCli,mvLojCli)
	Local _cQuery
	Local _nX
	//Local _aHeadCont := {}
	Local _aColsCont := {}
	// posicao do RENCO
	Local _nPosRecno
	// controle de confirmacao
	Local _lRet := .f.

	Local _cFiltro := ""

	Default mvCodCli  := CriaVar("A1_COD",.f.)
	Default mvLojCli  := CriaVar("A1_LOJA",.f.)

	// se for entrada, nao filtra containers
	If (Type("_cCodCli")=="U").or.(_lEntrada)
		Return("@1=1")
	EndIf

	// verifica se existe campos chave
	If (Type("_cCodCli")=="C")
		mvCodCli := _cCodCli
	EndIf
	If (Type("_cLojCli")=="C")
		mvLojCli := _cLojCli
	EndIf

	_cQuery := "SELECT Z3_CONTAIN "
	// movimentacao de container
	_cQuery += "FROM "+RetSqlName("SZ3")+" SZ3  (nolock) "
	// itens da programacao
	_cQuery += "INNER JOIN "+RetSqlName("SZ1")+" SZ1 (nolock)  ON "+RetSqlCond("SZ1")+" AND Z1_CODIGO = Z3_PROGRAM "
	// nao esteja encerrada
	_cQuery += "AND Z1_DTFINFA = ' ' "
	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SZ3")+" "
	// só filtra se foi informado o conteúdo
	If (!Empty(mvCodCli)).or.(!Empty(mvLojCli))
		_cQuery += "AND Z3_CLIENTE = '"+mvCodCli+"' AND Z3_LOJA = '"+mvLojCli+"' "
	EndIf
	_cQuery += "AND Z3_DTSAIDA = ' ' "
	// alimenta o acols com o resultado do SQL
	_aColsCont := U_SqlToVet(_cQuery)

	MemoWrit("c:\query\WMSA001B.txt",_cQuery)

	// formata o texto para filtro In ($)
	For _nX := 1 to Len(_aColsCont)
		_cFiltro += _aColsCont[_nX]+"|"
	Next _nX

Return("@ZC_CODIGO IN "+FormatIn(_cFiltro,"|"))

// ** funcao para validar o numero do container na saida
Static Function sfVldNumCont()
	Local _lRet := .f.
	Local _cTmpNumero := &(AllTrim(ReadVar()))
	Local _cSeek
	// variaveis
	// container 1 ou 2
	Local _cNum := Right(AllTrim(ReadVar()),1)
	Local _cVarTam	:= "_cTamCont"+_cNum
	Local _cVarTip	:= "_cTipCont"+_cNum
	Local _cVarTara	:= "_nTara"+_cNum
	Local _cVarLacr	:= "_cLacre"+_cNum

	// verifica se o container esta cadastrado
	dbSelectArea("SZC")
	SZC->(dbSetOrder(1)) //1-ZC_FILIAL, ZC_CODIGO
	If (!SZC->(dbSeek( xFilial("SZC")+_cTmpNumero )))
		MsgStop("Container não cadastrado!")
		Return(.f.)
	EndIf

	// valida, quando recebimento duplo, se o codigo dos container sao iguais
	If (_lRecDuplo).and.(_cNumCont1==_cNumCont2)
		MsgStop("Número do container em duplicidade.")
		Return(_lRet)
	EndIf

	// atualiza dados do container 1
	&(_cVarTip)	:= SZC->ZC_TIPO+"-"+AllTrim(Tabela("ZA",SZC->ZC_TIPO))
	&(_cVarTam)	:= sfCBoxDescr("ZC_TAMANHO",SZC->ZC_TAMANHO,2,3)
	&(_cVarTara):= SZC->ZC_TARA

	// atualiza codigo do armador
	_cCodArmad := SZC->ZC_ARMADOR
	_cNomArmad := Posicione("SZA",1, xFilial("SZA")+_cCodArmad ,"ZA_DESCRI")

	// validacoes no processo de entrada
	If (_lEntrada)
		// verifica a existencia do container no interior da empresa
		dbSelectArea("SZ3")
		SZ3->(dbOrderNickName("Z3_CONTAIN")) // Z3_FILIAL, Z3_CONTAIN
		SZ3->(dbSeek( _cSeek := xFilial("SZ3")+_cTmpNumero ))
		While SZ3->(!Eof()).and.(SZ3->(Z3_FILIAL+Z3_CONTAIN)==_cSeek)
			// verifica se é possivel dar entrada da movimentacao
			If (Empty(SZ3->Z3_DTSAIDA))
				MsgStop("Este número de Container encontra-se dentro da empresa!")
				Return(_lRet)
			EndIf
			// proxima movimentacao
			SZ3->(dbSkip())
		EndDo
		// liberacao do da movimentacao de entrada
		_lRet := .t.

		// validacoes no processo de saida
	ElseIf (!_lEntrada)
		// verifica a existencia do container no interior da empresa
		dbSelectArea("SZ3")
		SZ3->(dbOrderNickName("Z3_CONTAIN")) // Z3_FILIAL, Z3_CONTAIN
		SZ3->(dbSeek( _cSeek := xFilial("SZ3")+_cTmpNumero ))
		While SZ3->(!Eof()).and.(SZ3->(Z3_FILIAL+Z3_CONTAIN)==_cSeek)
			// verifica se é possivel dar saida da movimentacao
			If (Empty(SZ3->Z3_DTSAIDA)).and.(If(Empty(_cCodCli),.t.,(SZ3->Z3_CLIENTE==_cCodCli).and.(SZ3->Z3_LOJA==_cLojCli)))
				// atualiza os dados do cliente e programacao
				_cCodCli := SZ3->Z3_CLIENTE
				_cLojCli := SZ3->Z3_LOJA
				// funcao que valida o cliente
				If (!(_lRet:=sfVldCliente()))
					Return(_lRet)
				EndIf
				// programacao
				_cNumProg := SZ3->Z3_PROGRAM
				_cIteProg := SZ3->Z3_ITEPROG
				// funcao que valida a programacao
				If (!(_lRet:=sfVldNumProg()))
					Return(_lRet)
				EndIf

				// lacre
				&(_cVarLacr):= SZ3->Z3_LACRE
				// atualiza variaveis de motorista, somente na filial que nao retira o container do veiculos
				If (cFilAnt == "105")
					// transportadora
					_cCodTransp := SZ3->Z3_TRANSP
					_cNomTransp := Posicione("SA4",1, xFilial("SA4")+_cCodTransp ,"A4_NOME")
					// placas
					_cPlaca1    := SZ3->Z3_PLACA1
					_cPlaca2    := SZ3->Z3_PLACA2
					// motorista
					_cCodMotor  := SZ3->Z3_MOTORIS
					_cNomMotor  := Posicione("DA4",1, xFilial("DA4")+_cCodMotor ,"DA4_NOME")
				EndIf
				// variavel de retorno
				_lRet := .t.
				// atualiza RECNO
				_aRecnoSZ3[Val(_cNum)] := SZ3->(RecNo())
				Exit
			EndIf
			// proxima movimentacao
			SZ3->(dbSkip())
		EndDo
	EndIf

	// container não disponível
	If (!_lRet)
		MsgStop("Número do Container não disponível!")
	EndIf

Return(_lRet)

// ** funcao que retorna as opcoes do campo X3_CBOX
Static Function sfCboxToArray(mvCampo,mvItemBrc)
	Local _aArea    := GetArea()
	Local _aAreaSX3 := SX3->(GetArea())
	Local _cBox     := ""
	Local _aBox     := {}
	Local _nPosicao1:= 0
	Local _nPosicao2:= 0
	Local _cElem    := ""

	// verifica se inclui item em branco
	If (mvItemBrc)
		aAdd(_aBox,"")
	EndIf

	dbSelectArea("SX3")
	dbSetOrder(2)
	If ( MsSeek(mvCampo) )
		_cBox := x3CBox()
		While ( !Empty(_cBox) )
			_nPosicao1 := At(";",_cBox)
			If ( _nPosicao1 == 0 )
				_nPosicao1 := Len(_cBox)+1
			EndIf
			_nPosicao2	:= At("=",_cBox)
			_cElem		:= SubStr(_cBox,_nPosicao2+1,_nPosicao1-_nPosicao2-1)
			aadd(_aBox,_cElem)
			_cBox := SubStr(_cBox,_nPosicao1+1)
		EndDo
	EndIf
	// restaura area inicial
	RestArea(_aAreaSX3)
	RestArea(_aArea)

Return(_aBox)

// ** funcao para impressao da RIC
User Function WMSA001D(mvNumRIC)

	Local _nLinForm := 36
	// controle da linha
	Local _nLin

	// data
	Local _aData
	// observacoes
	LOCAL _cObserv := ""
	Local _aObserv := {}
	Local _nObs
	// tipo de programacao (E-exp/I-imp/N-nac)
	Local _cTpProg	:= ""

	Private aOrd          := {}
	Private CbTxt         := " "
	Private cDesc1        := " "
	Private cDesc2        := " "
	Private cDesc3        := " "
	Private lEnd          := .F.
	Private lAbortPrint   := .F.
	Private limite        := 80
	Private tamanho       := "G"
	Private nomeprog      := FunName()
	Private nTipo         := 18
	Private aReturn          := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
	Private nLastKey      := 0
	Private titulo        := "Impressao de RIC"
	Private cbtxt         := Space(10)
	Private cbcont        := 00
	Private CONTFL        := 01
	Private m_pag         := 01
	Private imprime       := .T.
	Private wnrel         := FunName()

	wnrel := SetPrint("SC5",wnrel,"",@Titulo,cDesc1,cDesc2,cDesc3,.f.," ",.f.,Tamanho,.F.)

	If nLastKey == 27
		Return
	EndIf

	SetDefault(aReturn,"SC5")

	If nLastKey == 27
		Return
	EndIf

	// posiciona no registro da SZ3
	dbSelectArea("SZ3")
	SZ3->(dbOrderNickName("Z3_RIC")) // Z3_FILIAL, Z3_RIC
	If (!SZ3->(dbSeek( xFilial("SZ3")+mvNumRIC )))
		MsgStop("Numero da RIC não encontrada!")
		Return(.f.)
	EndIf


	// ** inicio da impressao dos dados

	// zera a variavel nLin (Controle de Linhas da impressao)
	_nLin := 0

	SetPrc(0,0) //START NA IMPRESSORA

	@ _nLin,000 PSay Chr(27)+"@"			// Desabilita qualquer função da memória da impressora
	//@ _nLin,000 PSay Chr(27)+Chr(15)		// 17 caracteres por polegada na coluna
	//@ _nLin,000 PSay Chr(18)				// Impressao Normal
	//@ _nLin,000 PSay CHR(27)+"k1"			// Sans Serif
	_nLin += 2

	// nr da RIC + programacao + marca de reimpressao
	@ _nLin,060 pSay SZ3->Z3_RIC +"/"+ SZ3->Z3_PROGRAM +" "+ If((SZ3->Z3_RICIMP=="S"),"*","")
	_nLin += 1

	// extrai a data
	_aData := Separa(DtoC(SZ3->Z3_DTMOVIM),"/")
	@ _nLin,071 pSay _aData[1] // dia
	@ _nLin,074 pSay _aData[2] // mes
	@ _nLin,077 pSay Right(_aData[3],2) // ano
	_nLin += 3

	// numero container
	@ _nLin,001 pSay SZ3->Z3_CONTAIN
	// tara
	@ _nLin,028 pSay Transform(SZ3->Z3_TARA,PesqPict("SZ3","Z3_TARA"))
	// tipo container
	@ _nLin,038 pSay Left(Tabela("ZA",SZ3->Z3_TIPCONT),10) // 03. Codigo
	// tipo de movimentacao
	If (SZ3->Z3_TPMOVIM=="E")
		@ _nLin,063 pSay "X"
	ElseIf (SZ3->Z3_TPMOVIM=="S")
		@ _nLin,072 pSay "X"
	EndIf
	_nLin += 2

	// navio
	//@ _nLin,001 pSay Posicione("SZD",1, xFilial("SZD")+SZ3->Z3_NAVIO ,"ZD_DESCRI")
	//@ _nLin,026 pSay "" // 07.VIAGEM (do navio) em branco
	@ _nLin,038 pSay "A DESIGNAR" // 08.PORTO

	// cheio ou vazio
	If (SZ3->Z3_CONTEUD=="C")
		@ _nLin,062 pSay "X"
	ElseIf (SZ3->Z3_CONTEUD=="V")
		@ _nLin,071 pSay "X"
	EndIf
	_nLin += 1

	// tipo (importacao / exportacao)
	_cTpProg := Posicione("SZ1",1, xFilial("SZ1")+SZ3->Z3_PROGRAM ,"Z1_TIPO")
	If (SZ3->Z3_CONTEUD=="I") // importacaos
		@ _nLin,062 pSay "X"
	ElseIf (SZ3->Z3_CONTEUD=="E") // exportacao
		@ _nLin,071 pSay "X"
	EndIf
	_nLin += 1

	// consignatario (cliente)
	@ _nLin,001 pSay AllTrim(Posicione("SA1",1, xFilial("SA1")+SZ3->(Z3_CLIENTE+Z3_LOJA) ,"A1_NOME" ))
	_nLin += 2

	// transportadora
	@ _nLin,001 pSay SubStr(Posicione("SA4",1, xFilial("SA4")+SZ3->Z3_TRANSP ,"A4_NOME"),1,23)
	@ _nLin,026 pSay Transf(SZ3->Z3_PLACA1,PesqPict("DA3","DA3_COD"))
	@ _nLin,038 pSay Posicione("DA4",1, xFilial("DA4")+SZ3->Z3_MOTORIS ,"DA4_NOME")
	_nLin += 2

	// lacres
	@ _nLin,001 pSay SZ3->Z3_LACRE
	@ _nLin,030 pSay SZ3->Z3_HRMOVIM
	_nLin += 9

	// armador
	@ _nLin,001 pSay SubStr(Posicione("SZA",1, xFilial("SZA")+SZ3->Z3_ARMADOR ,"ZA_DESCRI"),1,35)
	_nLin += 3

	// prepara campo obrservacao
	_cObserv := AllTrim(SZ3->Z3_OBS)
	// praca origem
	_cObserv += If(Empty(_cObserv),""," / ")+"ORIG "+AllTrim(Posicione('SZB',1,xFilial('SZB')+SZ3->Z3_PRCORIG ,'ZB_DESCRI'))
	// praca destino
	_cObserv += " / DEST "+AllTrim(Posicione('SZB',1,xFilial('SZB')+SZ3->Z3_PRCDEST ,'ZB_DESCRI'))
	// usuario
	_cObserv += " / USR "+AllTrim(UsrFullName(SZ3->Z3_USRINCL))

	// prepara as observacoes
	_aObserv := QbTexto(_cObserv,35," ")

	// observacoes
	For _nObs := 1 to Len(_aObserv)
		// no maximo 4 linhas
		If (_nObs>4)
			Exit
		EndIf
		// imprime a linha
		@ _nLin,001 pSay _aObserv[_nObs]
		_nLin++
	Next _nObs

	// desabilita qualquer funcao da memoria da impressora
	@ _nLinForm,000 PSay Chr(27)+"@"

	// marca a RIC como Impressa
	RecLock("SZ3")
	SZ3->Z3_RICIMP := "S" // RIC Impressa ? (S-Sim/N-Nao)
	MsUnLock()


	//IMPRESSAO DOS DADOS
	Set Device To Screen

	If aReturn[5]==1
		dbCommitAll()
		Set Printer To
		OurSpool(wnrel)
	EndIf

	//Nao Ejeta a Pagina
	SetPgEject(.f.)

	MS_FLUSH()

Return

// ** funcao para exclusão de movimentacao
User Function WMSA001C
	Local _aPerg := {}
	Local _cPerg := PadR("WMSA001C",10)
	Local _cQrySZ3
	// header e acols
	Local _aHeadSZ3 := {}
	Local _aColsSZ3 := {}
	// posicao inicial do SX3
	Local _aAreaSX3
	// controle de confirmacao
	Local _lRet := .f.
	// posicao do campo RECNO
	Local _nPosRecno

	// verifica se o usuario pode executar o estorno
	If (!_lUsrEstor)
		MsgStop("Usuário sem permissão de estorno de movimentação.")
		Return(.f.)
	EndIf

	// criacao das Perguntas
	aAdd(_aPerg,{"Programação De?" ,"C",TamSx3("Z1_CODIGO")[1],0,"G",,"SZ1"}) //mv_par01
	aAdd(_aPerg,{"Programação Até?" ,"C",TamSx3("Z1_CODIGO")[1],0,"G",,"SZ1"}) //mv_par02
	aAdd(_aPerg,{"Container De?" ,"C",TamSx3("Z3_CONTAIN")[1],0,"G",,""}) //mv_par03
	aAdd(_aPerg,{"Container Até?" ,"C",TamSx3("Z3_CONTAIN")[1],0,"G",,""}) //mv_par04
	aAdd(_aPerg,{"Cliente De?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par05
	aAdd(_aPerg,{"Cliente Até?" ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"}) //mv_par06
	aAdd(_aPerg,{"Loja De?" ,"C",TamSx3("A1_LOJA")[1],0,"G",,""}) //mv_par07
	aAdd(_aPerg,{"Loja Até?" ,"C",TamSx3("A1_LOJA")[1],0,"G",,""}) //mv_par08
	aAdd(_aPerg,{"Dt Moviment. De?" ,"D",8,0,"G",,""}) //mv_par09
	aAdd(_aPerg,{"Dt Moviment. Até?" ,"D",8,0,"G",,""}) //mv_par10
	aAdd(_aPerg,{"Tipo Movimentacao?" ,"N",1,0,"C",{"Entrada","Saida","Ambas"},""}) //mv_par11

	// cria grupo de perguntas
	U_FtCriaSX1( _cPerg,_aPerg )

	If ! Pergunte(_cPerg,.T.)
		Return ()
	EndIf
	
	aAdd(_aHeadSZ3,{ "Dt Moviment.","Z3_DTMOVIM","",8,0,Nil,Nil,"D","SZ3","R" })
	aAdd(_aHeadSZ3,{ "Tp Moviment.","Z3_TPMOVIM","",1,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{ "Cod Program.","Z3_PROGRAM","",6,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{ "Itm.Program.","Z3_ITEPROG","@!",4,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{ "Cod Cliente","Z3_CLIENTE","",6,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{ "Loja Cliente","Z3_LOJA","",2,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{ "Sequencial","Z3_SEQUENC","",3,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{ "Nr Container","Z3_CONTAIN","@!R AAAA-999999-9 ",11,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{ "Conteudo","Z3_CONTEUD","",1,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{ "Cont.Atual?","Z3_CONTATU","@!",1,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{ "Tam Contain.","Z3_TAMCONT","",2,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{ "Tipo Contai.","Z3_TIPCONT","@!",2,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{ "Mov. Dupla","Z3_DUPLO","",1,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{ "Transp.Contr","Z3_TRACONT","@!",6,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{ "Transport.","Z3_TRANSP","",6,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{ "CESV","Z3_CESV","@!",10,0,Nil,Nil,"C","SZ3","R" })
	aAdd(_aHeadSZ3,{"Recno", "SZ3RECNO", "", 10, 0,Nil,Nil,"N",Nil,"R" })
	
	// posicao do campo RECNO
	_nPosRecno := Len(_aHeadSZ3)

	// prepara query para filtro dos dados
	_cQrySZ3 := "SELECT Z3_DTMOVIM,Z3_TPMOVIM,Z3_PROGRAM,Z3_ITEPROG,Z3_CLIENTE,Z3_LOJA,Z3_SEQUENC,Z3_CONTAIN,Z3_CONTEUD,Z3_CONTATU, "
	_cQrySZ3 += " Z3_TAMCONT,Z3_TIPCONT,Z3_DUPLO,Z3_TRACONT,Z3_TRANSP,Z3_CESV,SZ3.R_E_C_N_O_ SZ3RECNO, '.F.' IT_DEL "
	// movimentacao de veiculos
	_cQrySZ3 += "FROM "+RetSqlName("SZ3")+" SZ3 (nolock)  "
	// itens da programacao
	_cQrySZ3 += "INNER JOIN "+RetSqlName("SZ1")+" SZ1  (nolock) ON "+RetSqlCond("SZ1")+" AND Z1_CODIGO = Z3_PROGRAM "
	// nao esteja encerrada
	_cQrySZ3 += "AND Z1_DTFINFA = ' ' "
	// filtro padrao
	_cQrySZ3 += "WHERE "+RetSqlCond("SZ3")+" "
	_cQrySZ3 += "AND Z3_PROGRAM BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' "
	_cQrySZ3 += "AND Z3_CONTAIN BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' "
	_cQrySZ3 += "AND Z3_CLIENTE BETWEEN '"+mv_par05+"' AND '"+mv_par06+"' "
	_cQrySZ3 += "AND Z3_LOJA    BETWEEN '"+mv_par07+"' AND '"+mv_par08+"' "
	_cQrySZ3 += "AND Z3_DTMOVIM BETWEEN '"+DtoS(mv_par09)+"' AND '"+DtoS(mv_par10)+"' "
	// tipo de movimentacao
	//_cQrySZ3 += "AND Z3_TAMCONT "+If(_lCargaSol,"=","<>')+" 'CS' "
	// nao mostra RIC com frete pago
	_cQrySZ3 += "AND Z3_DTPGTOF = ' ' "
	// nao mostra movimentacao com armazenagem faturada
	_cQrySZ3 += "AND Z3_DTFATAR = ' ' "
	// nao mostra movimentacao com frete faturado
	_cQrySZ3 += "AND Z3_DTFATFR = ' ' "
	// nao mostra movimentacao com pacte logistico faturado
	_cQrySZ3 += "AND Z3_DTFATPA = ' ' "
	If (mv_par11==1) //1-Entrada
		_cQrySZ3 += "AND Z3_TPMOVIM = 'E' "
	ElseIf (mv_par11==2)//2-Saida
		_cQrySZ3 += "AND Z3_TPMOVIM = 'S' "
	EndIf
	_cQrySZ3 += "ORDER BY Z3_DTMOVIM"

	// alimenta o acols com o resultado do SQL
	_aColsSZ3 := U_SqlToVet(_cQrySZ3,{"Z3_DTMOVIM"})

	memowrit("c:\query\twmsa001_WMSA001C_cquerySZ3.txt",_cQrySZ3)

	// verifica se tem itens
	If (Len(_aColsSZ3)==0)
		MsgStop("Não há movimentações disponíveis. Verifique os parâmetros.")
		Return(.f.)
	EndIf

	// monta o dialogo
	oDlgExclusao := MSDialog():New(000,000,400,800,"Exclusão de Movimentação",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho
	oPnlCabecEx := TPanel():New(000,000,nil,oDlgExclusao,,.F.,.F.,,,000,020,.T.,.F. )
	oPnlCabecEx:Align:= CONTROL_ALIGN_TOP
	// botao para detahes do dia
	oBtnConfirma := TButton():New(005,005,"Confirmar",oPnlCabecEx,{|| _lRet := sfConfEsto(_nPosRecno) },060,010,,,,.T.,,"",,,,.F. )
	// botao pra fechar
	oBtnSair := TButton():New(005,070,"Fechar",oPnlCabecEx,{||oDlgExclusao:End()},060,010,,,,.T.,,"",,,,.F. )

	// browse com a listagem dos produtos conferidos
	oBrwExclusao := MsNewGetDados():New(000,000,400,400,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsSZ3),'AllwaysTrue()','','AllwaysTrue()',oDlgExclusao,_aHeadSZ3,_aColsSZ3)
	oBrwExclusao:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG oDlgExclusao CENTERED

Return(_lRet)

// ** funcao para confirmar o estorno
Static Function sfConfEsto(mvPosRecno)
	Local _nRecOrig := 0
	Local _cQuery
	Local _cSeekSZE

	// posiciona no registro
	dbSelectArea("SZ3")
	SZ3->(dbGoTo(oBrwExclusao:aCols[oBrwExclusao:nAt,mvPosRecno] ))

	// valida necessidade de exclusao do CESV
	If ( ! Empty(SZ3->Z3_CESV))
		dbSelectArea("SZZ")
		SZZ->(dbSetOrder(1)) // 1-ZZ_FILIAL, ZZ_CESV
		If (SZZ->(dbSeek(xFilial("SZZ")+SZ3->Z3_CESV)))
			If (SZZ->ZZ_STATUS != "01")
				MsgStop("Não é possível excluir o CESV com status diferente de 01-CHEGADA. Status atual:"+SZZ->ZZ_STATUS+".")
				Return(.f.)
			EndIf
		EndIf
	EndIf

	// verifica se pode excluir
	If (SZ3->Z3_TPMOVIM=="E").and.(!Empty(SZ3->Z3_DTSAIDA))
		MsgStop("Não é possível excluir este movimento. Estorne o movimento de Saída!")
		Return(.f.)
	EndIf

	// quando for movimento de saida, pesquisa movimento de entrada
	If (SZ3->Z3_TPMOVIM=="S")
		_cQuery := "SELECT SZ3.R_E_C_N_O_ SZ3RECNO "
		_cQuery += "FROM "+RetSqlName("SZ3")+" SZ3 (nolock)  "
		_cQuery += "WHERE Z3_FILIAL = '"+SZ3->Z3_FILIAL+"' AND SZ3.D_E_L_E_T_ = ' ' "
		_cQuery += "AND Z3_PROGRAM = '"+SZ3->Z3_PROGRAM+"' AND Z3_ITEPROG = '"+SZ3->Z3_ITEPROG+"' "
		_cQuery += "AND Z3_CONTAIN = '"+SZ3->Z3_CONTAIN+"' "
		//_cQuery += "AND Z3_CONTEUD = '"+SZ3->Z3_CONTEUD+"' "
		_cQuery += "AND Z3_TAMCONT = '"+SZ3->Z3_TAMCONT+"' AND Z3_TIPCONT = '"+SZ3->Z3_TIPCONT+"' "
		_cQuery += "AND Z3_TPMOVIM = 'E' " // movimento de entrada
		// executa query
		_nRecOrig := U_FtQuery(_cQuery)

		If (_nRecOrig==0)
			MsgStop("Não é possível excluir este movimento, pois não há registro de entrada!")
			Return(.f.)
		EndIf
	EndIf

	If ( ! MsgYesNo("Confirma o estorno da Movimentação selecionada ?", "Estorno"))
		Return(.f.)
	EndIf

	// INICIA TRANSACAO
	BEGIN Transaction

		// controle da quantidade recebida
		If (SZ3->Z3_TPMOVIM=="E")
			dbSelectArea("SZ2")
			SZ2->(dbSetOrder(1)) //1-Z2_FILIAL, Z2_CODIGO, Z2_ITEM
			If SZ2->(dbSeek( xFilial("SZ2")+SZ3->(Z3_PROGRAM+Z3_ITEPROG) ))
				// atualiza quantidade recebida
				RecLock("SZ2")
				SZ2->Z2_QTDREC -= 1
				MsUnLock()
			EndIf
		EndIf

		// exclui as avarias
		dbSelectArea("SZE")
		SZE->(dbOrderNickName("ZE_RIC")) // 1-ZE_FILIAL, ZE_RIC, ZE_CODAVAR
		SZE->(dbSeek( _cSeekSZE := xFilial("SZE")+SZ3->Z3_RIC ))
		While SZE->(!Eof()).and.(SZE->(ZE_FILIAL+ZE_RIC)==_cSeekSZE)
			RecLock("SZE")
			SZE->(dbDelete())
			MsUnLock()
			// proxima avaria
			SZE->(dbSkip())
		EndDo

		// exclui o registro da movimentacao
		dbSelectArea("SZ3")
		RecLock("SZ3")
		SZ3->(dbDelete())
		MsUnLock()

		// exclui o CESV
		If ( ! Empty(SZ3->Z3_CESV))
			dbSelectArea("SZZ")
			Reclock("SZZ")
			SZZ->(dbDelete())
			MsUnlock()
		EndIf

		// quando for saida, limpa informacoes do movimento de entrada (origem)
		If (SZ3->Z3_TPMOVIM=="S")
			// posiciona no registro de entrada
			dbSelectArea("SZ3")
			SZ3->(dbGoTo(_nRecOrig))
			RecLock("SZ3")
			SZ3->Z3_DTSAIDA	:= CtoD("//")
			SZ3->Z3_HRSAIDA	:= ""
			MsUnLock()
		EndIf

		// INICIA TRANSACAO
	END Transaction

	// fecha a tela
	oDlgExclusao:End()

	MsgInfo("Estorno realizado com sucesso!")

Return(.t.)

// ** funcao que define as avarias do container
Static Function sfAvarias(mvNumCont)
	Local _nX
	Local _cQuery
	Local _aHeadAvar := {}
	Local _aColsAvar := {}
	// controle de confirmacao
	Local _lRet := .f.
	// monta variavel
	Local _cVarAvari := "_aAvarias"+mvNumCont
	// variavel do container
	Local _cVarConta := "_cNumCont"+mvNumCont

	// verifica se o container foi informado
	If (Empty(&_cVarConta))
		MsgStop("É obrigatório informar o número do container")
		Return(.f.)
	EndIf

	// abre alias das avarias
	dbSelectArea("SZE")

	// alimenta o header
	aAdd(_aHeadAvar,{"Código", "ZE_CODAVAR", PesqPict("SZE","ZE_CODAVAR"), TamSx3("ZE_CODAVAR")[1], 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadAvar,{"Descrição", "ZE_DSAVARI", PesqPict("SZE","ZE_DSAVARI"), TamSx3("ZE_DSAVARI")[1], 0,Nil,Nil,"C",Nil,"V" })
	aAdd(_aHeadAvar,{"Observação", "ZE_OBS", PesqPict("SZE","ZE_OBS"), TamSx3("ZE_OBS")[1], 0,Nil,Nil,"C",Nil,"R" })

	If (Len(&(_cVarAvari))==0)
		// cria linha em branco
		_aColsAvar := Array(1,Len(_aHeadAvar)+1)
		// define valor inicial
		_aColsAvar[1,1] := CriaVar("ZE_CODAVAR")
		_aColsAvar[1,2] := CriaVar("ZE_DSAVARI")
		_aColsAvar[1,3] := CriaVar("ZE_OBS")
		_aColsAvar[1,4] := .f. // linha deletada
	Else
		For _nX := 1 to Len(&(_cVarAvari))
			aAdd(_aColsAvar, {	&_cVarAvari[_nX,1] ,;
			Tabela("ZB",&_cVarAvari[_nX,1]) ,;
			&_cVarAvari[_nX,2] ,;
			.f. })
		Next _nX
	EndIf

	// monta o dialogo
	oDlgAvarias := MSDialog():New(000,000,400,800,"Avarias",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho
	oPnlCabec := TPanel():New(000,000,nil,oDlgAvarias,,.F.,.F.,,,000,020,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// botao para detahes do dia
	oBtnConfirma := TButton():New(005,005,"Confirmar",oPnlCabec,{|| _lRet:=.t.,oDlgAvarias:End() },060,010,,,,.T.,,"",,,,.F. )
	// botao pra fechar
	oBtnSair := TButton():New(005,070,"Fechar",oPnlCabec,{||oDlgAvarias:End()},060,010,,,,.T.,,"",,,,.F. )

	// numero do container
	oSayNrCont := TSay():New(005,140,{||"Número do Container: "+(&(_cVarConta))},oPnlCabec,,oFntVerd18,.F.,.F.,.F.,.T.)

	// botao para anexar fotos
	oBtnFotos := TButton():New(005,330,"Fotos",oPnlCabec,{||sfFotos(mvNumCont)},060,010,,,,.T.,,"",,,,.F. )

	// browse com a listagem das avarias
	oBrwProgRec := MsNewGetDados():New(000,000,400,400,GD_INSERT+GD_DELETE+GD_UPDATE,'AllwaysTrue()','AllwaysTrue()','',,,,'AllwaysTrue()','','AllwaysTrue()',oDlgAvarias,_aHeadAvar,_aColsAvar)
	oBrwProgRec:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG oDlgAvarias CENTERED

	If (_lRet)
		// zera as avarias
		&(_cVarAvari) := {}
		// alimenta novamente as avarias
		For _nX := 1 to Len(oBrwProgRec:aCols)
			If !(oBrwProgRec:aCols[_nX,Len(_aHeadAvar)+1]).and.(!(Empty(oBrwProgRec:aCols[_nX,1])))
				aAdd(&(_cVarAvari),{oBrwProgRec:aCols[_nX,1], ; // codigo
				oBrwProgRec:aCols[_nX,3]} ) // observacao
			EndIf
		Next _nX
	EndIf

Return

// ** funcao responsavel pelo envio de email para o cliente com as informacoes da RIC
Static Function sfEnvMail(mvNumRIC, mvNumCont, mvCesv, mvRotAut, mvTpOper)
	Local _cHtml := ""
	// monta variavel
	Local _cVarFotos := "_aFotos"+Str(mvNumCont,1)
	// vetor com os anexos
	Local _aAnexos := {}
	Local _nX
	//Variavel Temporaria
	Local _aPedCa := {}
	Local _cQuery := ""

	// tipo da carga
	local _lTmpCrgSol := .t.

	// valores padroes da rotina
	Default mvRotAut := .f.
	Default mvTpOper := " "
	Default mvCesv   := CriaVar("ZZ_CESV", .f.)

	// prepara os anexos
	If (!_lCargaSol)
		For _nX := 1 to Len(&(_cVarFotos))
			If !Empty(&(_cVarFotos)[_nX])
				aAdd(_aAnexos,&(_cVarFotos)[_nX])
			EndIf
		Next _nX
	EndIf

	// posiciona no registro da SZ3
	dbSelectArea("SZ3")
	SZ3->(dbOrderNickName("Z3_RIC")) // Z3_FILIAL, Z3_RIC
	If ( ! SZ3->(dbSeek( xFilial("SZ3")+mvNumRIC ) ))
		MsgStop("Numero da RIC não encontrada!")
		Return(.f.)
	EndIf

	// verifica os destinatarios de email
	If (Empty(SA1->A1_USRCONT))
		MsgStop("Email de recebimento de informações não cadastrado!")
		Return(.f.)
	EndIf

	// posiciona na programacao
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	SZ1->(dbSeek( xFilial("SZ1")+SZ3->Z3_PROGRAM ))

	// definicao do tipo da carga
	_lTmpCrgSol := (SZ3->Z3_TAMCONT == "CS")

	// prepara html para envio do email
	_cHtml := '<table width="780px" align="center">'
	_cHtml += '   <tr>'
	_cHtml += '      <td>'
	_cHtml += '         <table style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;" align="center" width="700">'
	_cHtml += '            <tr>'
	_cHtml += '               <td align="center">MOVIMENTAÇÃO DE VEÍCULOS</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td align="center">'+AllTrim(Upper(SM0->M0_NOMECOM))+' - '+AllTrim(Upper(SM0->M0_FILIAL))+'</td>'
	_cHtml += '            </tr>'
	_cHtml += '         </table>'
	_cHtml += '         <BR>'
	_cHtml += '         <table style="font-family: Tahoma; Font-size: 13px;color: #000000;text-decoration: none;font-weight:bold;background-color:#C2C3C5;" align="center" width="700">'
	_cHtml += '            <tr>'
	_cHtml += '               <td>Cliente: '+AllTrim(Posicione("SA1",1, xFilial("SA1")+SZ3->(Z3_CLIENTE+Z3_LOJA) ,"A1_NOME" ))+'</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td>Programação: '+AllTrim(SZ3->Z3_PROGRAM)+'</td>'
	_cHtml += '            </tr>'
	_cHtml += '            <tr>'
	_cHtml += '               <td>Referência: '+AllTrim(SZ1->Z1_REFEREN)+'</td>'
	_cHtml += '            </tr>'
	_cHtml += '         </table>'
	_cHtml += '         <BR>'

	// dados da movimentacao
	_cHtml += '<table align="center" width="700">'
	If ( ! _lTmpCrgSol )
		_cHtml += '<tr>'
		_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Protocolo</td>'
		_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+SZ3->Z3_RIC+'</td>'
		_cHtml += '</tr>'
		_cHtml += '<tr>'
		_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Número do Container</td>'
		_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+Transform(SZ3->Z3_CONTAIN,PesqPict("SZ3","Z3_CONTAIN"))+'</td>'
		_cHtml += '</tr>'
		_cHtml += '<tr>'
		_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Armador</td>'
		_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+AllTrim(Posicione("SZA",1, xFilial("SZA")+SZ3->Z3_ARMADOR ,"ZA_DESCRI"))+'</td>'
		_cHtml += '</tr>'
		_cHtml += '<tr>'
		_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Tipo do Container</td>'
		_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+AllTrim(Tabela("ZA",SZ3->Z3_TIPCONT))+'</td>'
		_cHtml += '</tr>'
		_cHtml += '<tr>'
		_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Tamanho</td>'
		_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+SZ3->Z3_TAMCONT+'</td>'
		_cHtml += '</tr>'
		_cHtml += '<tr>'
		_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Situação</td>'
		_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+IIf(SZ3->Z3_CONTEUD=="C","CHEIO","VAZIO")+'</td>'
		_cHtml += '</tr>'
	EndIf

	_cHtml += '<tr>'
	_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Sentido</td>'
	_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+IIf(SZ3->Z3_TPMOVIM=="E","Entrada","Saída")+" - "+DtoC(SZ3->Z3_DTMOVIM)+" - "+SZ3->Z3_HRMOVIM+'</td>'
	_cHtml += '</tr>'
	_cHtml += '<tr>'
	_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Origem</td>'
	_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+AllTrim(Posicione("SZB",1, xFilial("SZB")+SZ3->Z3_PRCORIG ,"ZB_DESCRI"))+'</td>'
	_cHtml += '</tr>'
	_cHtml += '<tr>'
	_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Destino</td>'
	_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+AllTrim(Posicione("SZB",1, xFilial("SZB")+SZ3->Z3_PRCDEST ,"ZB_DESCRI"))+'</td>'
	_cHtml += '</tr>'
	If ( ! _lTmpCrgSol )
		_cHtml += '<tr>'
		_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Lacres</td>'
		_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+AllTrim(SZ3->Z3_LACRE)+'</td>'
		_cHtml += '</tr>'
		_cHtml += '<tr>'
		_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Tara</td>'
		_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+Transform(SZ3->Z3_TARA,PesqPict("SZ3","Z3_TARA"))+'</td>'
		_cHtml += '</tr>'
	EndIf
	_cHtml += '<tr>'
	_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Transportador</td>'
	_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+AllTrim(Posicione("SA4",1, xFilial("SA4")+SZ3->Z3_TRACONT ,"A4_NOME"))+'</td>'
	_cHtml += '</tr>'

	_cHtml += '<tr>'
	_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Motorista/Placa</td>'
	_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+AllTrim(Posicione("DA4",1, xFilial("DA4")+SZ3->Z3_MOTORIS ,"DA4_NOME"))+" / "+Transf(SZ3->Z3_PLACA1,PesqPict("DA3","DA3_COD"))+'</td>'
	_cHtml += '</tr>'

	//Condição para adicionar informaçoes no email.
	If (_lTmpCrgSol) .And. ( ! Empty(mvCesv) ) .And. (mvRotAut) .And. (Upper(mvTpOper) == "S")

		//Inicio SQL
		_cQuery := " SELECT C5_ZPEDCLI,C5_ZDOCCLI,C5_ZAGRUPA"
		//Cabeçalho Pedido de Venda
		_cQuery += " FROM "+RetSqlName("SC5")+" SC5 (nolock)  "
		//itens liberados por pedido
		_cQuery += " INNER JOIN "+RetSqlName("SC9")+" SC9 (nolock)  ON "+RetSqlCond("SC9")+" AND SC5.C5_NUM = SC9.C9_PEDIDO"
		// cabecalho de cargas
		_cQuery += " INNER JOIN "+RetSqlName("DAK")+" DAK (nolock)  ON "+RetSqlCond("DAK")+" AND SC9.C9_CARGA = DAK.DAK_COD AND SC9.C9_SEQCAR = DAK.DAK_SEQCAR "
		//WMS - ORDEM DE SERVICO
		_cQuery += " INNER JOIN "+RetSqlName("Z05")+" Z05 (nolock)  ON "+RetSqlCond("Z05")+" AND SC9.C9_CARGA = Z05.Z05_CARGA "
		// filtro padrao
		_cQuery += " WHERE "+RetSqlCond('SC5')+" "
		//Filtro Cesv
		_cQuery += " AND Z05.Z05_CESV  = '"+mvCesv+"'"

		// carrega resultado do SQL na variavel.
		_aPedCa := U_SqlToVet(_cQuery)

		If Len(_aPedCa) > 0

			_cHtml += '<tr>'
			_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Pedido Cliente</td>'
			_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+ AllTrim(_aPedCa[1][1])+'</td>'
			_cHtml += '</tr>'

			_cHtml += '<tr>'
			_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Nota Fiscal Venda</td>'
			_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+ AllTrim(_aPedCa[1][2])+'</td>'
			_cHtml += '</tr>'

			_cHtml += '<tr>'
			_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Ref.Agrupadora</td>'
			_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+ AllTrim(_aPedCa[1][3])+'</td>'
			_cHtml += '</tr>'

		EndIf
	EndIf

	_cHtml += '<tr>'
	_cHtml += '  <td width="200" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Observações</td>'
	_cHtml += '  <td width="500" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+ AllTrim(SZ3->Z3_OBS)+'</td>'
	_cHtml += '</tr>'
	_cHtml += '</table>'
	_cHtml += '<br>'

	// relacao da avarias
	If ( ! _lTmpCrgSol )
		dbSelectArea("SZE")
		SZE->(dbOrderNickName("ZE_RIC")) // 1-ZE_FILIAL, ZE_RIC, ZE_CODAVAR
		If SZE->(dbSeek( _cSeekSZE := xFilial("SZE")+SZ3->Z3_RIC ))
			// abre tabela das avarias
			_cHtml += '<table align="center" width="700">'
			_cHtml += '<tr>'
			_cHtml += '  <td align="center" colspan="2" width="700" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Avarias</td>'
			_cHtml += '</tr>'
			_cHtml += '<tr>'
			_cHtml += '  <td width="300" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Descrição</td>'
			_cHtml += '  <td width="400" style="font-family: Tahoma; Font-size: 13px;color: #FFFFFF;text-decoration: none;font-weight:bold;background-color:#1B5A8F;">Observação</td>'
			_cHtml += '</tr>'

			While SZE->(!Eof()).and.(SZE->(ZE_FILIAL+ZE_RIC)==_cSeekSZE)
				_cHtml += '<tr>
				_cHtml += '  <td width="300" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+SZE->ZE_CODAVAR+"-"+AllTrim(Tabela("ZB",SZE->ZE_CODAVAR))+'</td>'
				_cHtml += '  <td width="400" style="font-family: Tahoma;font-size: 13px;color: #000000;text-decoration: none;font-weight: none;">'+AllTrim(SZE->ZE_OBS)+'</td>'
				_cHtml += '</tr>
				// proxima avaria
				SZE->(dbSkip())
			EndDo
			// fecha tabela das avarias
			_cHtml += '</table>'
			_cHtml += '<br>'
		EndIf
	EndIf

	// rodape
	_cHtml += '<hr width="80%" noshade="noshade" align="center">''
	_cHtml += '<div align="center"><span style="font-family: Tahoma; font-size: 11px; background-color: #FFFFFF; color: #000000;">Não responda este E-mail - Mensagem automática utilizando o serviço de Workflow TECADI - Proudly Made by TECADI Technology</span> </div>'

	// fecha corpo do email
	_cHtml += '      </td>'
	_cHtml += '   </tr>'
	_cHtml += '</table>'

	// envia o email
	MsgRun("Enviando e-mail ...", "Aguarde...", {||	CursorWait() ,;
	U_FtMail(_cHtml,"TECADI - Movimentação de Veículo",AllTrim(SA1->A1_USRCONT),_aAnexos) ,;
	CursorArrow() } )

	// envia o email para os despachantes
	If (SA1->(FieldPos('A1_ZMAILDE'))>0).and.( ! Empty(SA1->A1_ZMAILDE))
		MsgRun("Enviando e-mail ...", "Aguarde...", {||	CursorWait() ,;
		U_FtMail(_cHtml,"TECADI - Movimentação de Veículo",AllTrim(SA1->A1_ZMAILDE),_aAnexos) ,;
		CursorArrow() } )
	EndIf

Return

// ** funcao para reimpressao de RIC
Static Function sfReimpres()
	Local _nX
	Local _cQuery
	// controle de confirmacao
	Local _lRet := .f.
	// campos do browse
	Local _aBrwRIC := {}
	// estrutura do arquivo de trabalho
	Local _aTmpStruct := {}
	// nome do arquivo temporario
	Local _cTrbRIC
	// controle do item marcado
	Local _cMarca := GetMark()
	// usuario com a permissao de reimpressao
	Local _cUsrReimp := AllTrim(SuperGetMv("TC_USRREIM",.f.,""))
	
	Private _TRBRIC := GetNextAlias()

	// inclui detalhes e titulos dos campos do browse
	aAdd(_aBrwRIC,{"IT_OK"		,"@!"		,"  "})
	aAdd(_aBrwRIC,{"Z3_DTMOVIM"	,"@!"		,"Data"})
	aAdd(_aBrwRIC,{"IT_TIPOMOV"	,"@!"		,"Tp Moviment."})
	aAdd(_aBrwRIC,{"Z3_RIC"		,"@!"		,"Nr RIC"})
	aAdd(_aBrwRIC,{"Z3_CONTAIN"	,"@!"		,"Container"})
	aAdd(_aBrwRIC,{"Z3_TAMCONT"	,"@!"		,"Tamanho"})
	aAdd(_aBrwRIC,{"IT_CONTEUD"	,"@!"		,"Conteúdo"})
	aAdd(_aBrwRIC,{"Z3_TIPCONT"	,"@!"		,"Tipo"})

	// cria estrutuda dos campos
	aAdd(_aTmpStruct,{"IT_OK","C",2,0})
	aAdd(_aTmpStruct,{"Z3_RICIMP","C",TamSx3("Z3_RICIMP")[1],0})
	aAdd(_aTmpStruct,{"Z3_DTMOVIM","D",8,0})
	aAdd(_aTmpStruct,{"IT_TIPOMOV","C",8,0})
	aAdd(_aTmpStruct,{"Z3_RIC","C",TamSx3("Z3_RIC")[1],0})
	aAdd(_aTmpStruct,{"Z3_CONTAIN","C",TamSx3("Z3_CONTAIN")[1],0})
	aAdd(_aTmpStruct,{"Z3_TAMCONT","C",TamSx3("Z3_TAMCONT")[1],0})
	aAdd(_aTmpStruct,{"IT_CONTEUD","C",5,0})
	aAdd(_aTmpStruct,{"Z3_TIPCONT","C",20,0})

	// monta a query
	_cQuery := "SELECT Z3_RICIMP, Z3_DTMOVIM, "
	_cQuery += "CASE WHEN Z3_TPMOVIM = 'E' THEN 'ENTRADA' ELSE 'SAIDA' END IT_TIPOMOV, "
	_cQuery += "Z3_RIC, Z3_CONTAIN, Z3_TAMCONT, "
	_cQuery += "CASE WHEN Z3_CONTEUD = 'C' THEN 'CHEIO' ELSE 'VAZIO' END IT_CONTEUD, "
	_cQuery += "X5_DESCRI Z3_TIPCONT "
	_cQuery += "FROM "+RetSqlName("SZ3")+" SZ3 (nolock)  "
	// tipo do container
	_cQuery += "INNER JOIN "+RetSqlName("SX5")+" SX5 (nolock)  ON X5_FILIAL = '"+xFilial("SX5")+"' AND SX5.D_E_L_E_T_ = ' ' "
	_cQuery += "      AND X5_TABELA = 'ZA' AND X5_CHAVE = Z3_TIPCONT "
	_cQuery += "WHERE Z3_FILIAL = '"+xFilial("SZ3")+"' AND SZ3.D_E_L_E_T_ = ' ' "
	// verifica se o usuario pode reimprimir RIC
	If !(__cUserId $ _cUsrReimp)
		_cQuery += "AND Z3_RICIMP <> 'S' "
	EndIf
	// verifica os filtros
	If !(Empty(_cNumProg))
		_cQuery += "AND Z3_PROGRAM = '"+_cNumProg+"' "
	EndIf
	If !(Empty(_cCodCli))
		_cQuery += "AND Z3_CLIENTE = '"+_cCodCli+"' "
	EndIf
	// tipo de movimentacao
	_cQuery += "AND Z3_TPMOVIM = '"+If(_lEntrada,"E","S")+"' "
	// ordem dos dados
	_cQuery += "ORDER BY Z3_DTMOVIM "

	// cria o arquivo de trabalho
	If (Select(_TRBRIC)<>0)
		dbSelectArea(_TRBRIC)
		dbCloseArea()
	EndIf
	
	// monta arquivo de trabalho
	_cTrbRIC := FWTemporaryTable():New( _TRBRIC )
	_cTrbRIC:SetFields( _aTmpStruct )
	_cTrbRIC:Create()
	
	// apenda os dados do SQL para o TRB
	SqlToTrb(_cQuery,_aTmpStruct,_TRBRIC)

	// posiciona no primeiro registro
	(_TRBRIC)->(dbSelectArea(_TRBRIC))
	(_TRBRIC)->(dbGoTop())

	// monta o dialogo
	oDlgRIC := MSDialog():New(000,000,400,800,"Relação de RIC",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho
	oPnlCabec := TPanel():New(000,000,nil,oDlgRIC,,.F.,.F.,,,000,020,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// botao para detahes do dia
	oBtnConfirma := TButton():New(005,005,"Confirmar",oPnlCabec,{|| _lRet:=.t.,oDlgRIC:End() },060,010,,,,.T.,,"",,,,.F. )
	// botao pra fechar
	oBtnSair := TButton():New(005,070,"Fechar",oPnlCabec,{||oDlgRIC:End()},060,010,,,,.T.,,"",,,,.F. )

	// botao para detahes do dia
	oBtnEnvMail := TButton():New(005,330,"Envio de e-mail",oPnlCabec,{|| sfEnvMail((_TRBRIC)->Z3_RIC,1) },060,010,,,,.T.,,"",,,,.F. )

	// browse com a listagem das RIC que podem ser reimpressas
	oBrwRIC := MsSelect():New(_TRBRIC,"IT_OK",,_aBrwRIC,,@_cMarca,{05,05,150,355},,,,,{{"(_TRBRIC)->Z3_RICIMP=='S'","ENABLE"},{"(_TRBRIC)->Z3_RICIMP<>'S'","DISABLE"}})
	oBrwRIC:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG oDlgRIC CENTERED

	If (_lRet)

		(_TRBRIC)->(dbSelectArea(_TRBRIC))
		(_TRBRIC)->(dbGoTop())
		While (_TRBRIC)->(!Eof())
			// quando estiver selecionado imprime a RIC
			If !Empty((_TRBRIC)->IT_OK)
				// funcao para impressao da RIC
				U_WMSA001D((_TRBRIC)->Z3_RIC)
			EndIf
			// proximo item
			(_TRBRIC)->(dbSkip())
		EndDo

	EndIf
	
	_cTrbRIC:Delete()
	
Return

// ** funcao que anexa fotos na avaria
Static Function sfFotos(mvNumCont)
	// controle de confirmacao
	Local _lRet := .f.
	// monta variavel
	Local _cVarFotos := "_aFotos"+mvNumCont
	// local das fotos
	Local _cFoto1 := (&(_cVarFotos)[1])
	Local _cFoto2 := (&(_cVarFotos)[2])
	Local _cFoto3 := (&(_cVarFotos)[3])
	// local padrao para as fotos
	Private _cLcPdrAnx := "C:\"

	// monta o dialogo
	oDlgFotos := MSDialog():New(000,000,300,300,"Fotos das Avarias",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho
	oPnlCabec := TPanel():New(000,000,nil,oDlgFotos,,.F.,.F.,,,000,020,.T.,.F. )
	oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// botao para detahes do dia
	oBtnConfirma := TButton():New(005,005,"Confirmar",oPnlCabec,{|| _lRet:=.t.,oDlgFotos:End() },060,010,,,,.T.,,"",,,,.F. )
	// botao pra fechar
	oBtnSair := TButton():New(005,070,"Fechar",oPnlCabec,{||oDlgFotos:End()},060,010,,,,.T.,,"",,,,.F. )

	// foto 1
	oSayFoto1 := TSay():New(025,008,{||"Foto 1"},oDlgFotos,,,.F.,.F.,.F.,.T.)
	oGetFoto1 := TGet():New(023,028,{|u| If(PCount()>0,_cFoto1:=u,_cFoto1)},oDlgFotos,105,009,,,,,,,,.T.,"",,,.F.,.F.,,.t.,.F.,"","_cFoto1",,)
	oBtnFoto1 := TButton():New(023,138,"...",oDlgFotos,{||_cFoto1 := sfGetFotos()},010,010,,,,.T.,,"",,,,.F. )

	// foto 2
	oSayFoto2 := TSay():New(040,008,{||"Foto 2"},oDlgFotos,,,.F.,.F.,.F.,.T.)
	oGetFoto2 := TGet():New(038,028,{|u| If(PCount()>0,_cFoto2:=u,_cFoto2)},oDlgFotos,105,009,,,,,,,,.T.,"",,,.F.,.F.,,.t.,.F.,"","_cFoto2",,)
	oBtnFoto2 := TButton():New(038,138,"...",oDlgFotos,{||_cFoto2 := sfGetFotos()},010,010,,,,.T.,,"",,,,.F. )

	// foto 3
	oSayFoto3 := TSay():New(055,008,{||"Foto 3"},oDlgFotos,,,.F.,.F.,.F.,.T.)
	oGetFoto3 := TGet():New(053,028,{|u| If(PCount()>0,_cFoto3:=u,_cFoto3)},oDlgFotos,105,009,,,,,,,,.T.,"",,,.F.,.F.,,.t.,.F.,"","_cFoto3",,)
	oBtnFoto3 := TButton():New(053,138,"...",oDlgFotos,{||_cFoto3 := sfGetFotos()},010,010,,,,.T.,,"",,,,.F. )

	// ativa a tela
	ACTIVATE MSDIALOG oDlgFotos CENTERED

	If (_lRet)
		// atualiza vetor com as fotos
		&(_cVarFotos)[1] := _cFoto1
		&(_cVarFotos)[2] := _cFoto2
		&(_cVarFotos)[3] := _cFoto3
	EndIf

Return

// ** funcao para buscar as fotos
Static Function sfGetFotos()
	Local _aInfoFile := {} // array contendo as informacoes do arquivo
	Local _cMask := "Imagens JPG|*.JPG|Imagens BMP|*.BMP|"
	Local _cRet := cGetFile(_cMask,"Abrir Arquivo...",nil,_cLcPdrAnx,.T.,GETF_LOCALHARD+GETF_NETWORKDRIVE)
	Local _nTamMax := 300 // ex: 300kb
	Local _cTmpDrv	:= "" // drive
	Local _cTmpDir	:= "" // diretorio

	If !(Empty(_cRet))
		// retorna as propriedades do arquivo
		_aInfoFile := Directory( AllTrim(_cRet) )
		// valida o tamanho do arquivo
		If (Int(_aInfoFile[1][2]/1024) > _nTamMax)
			MsgStop("Tamanho máximo permitido é "+AllTrim(Str(_nTamMax))+"kb")
			_cRet := Space(300)
		EndIf
		// extrai informacoes do arquivo, para mudar o local padrao do anexo
		// ex: SplitPath ( < cArquivo>, [ @cDrive], [ @cDiretorio], [ @cNome], [ @cExtensao] )
		SplitPath(AllTrim(_cRet),@_cTmpDrv,@_cTmpDir)
		// muda o local padrao
		_cLcPdrAnx := _cTmpDrv+_cTmpDir
	EndIf

Return(_cRet)

// ** funcao para movimentacao de carga solta
Static Function sfMovSolta(mvTipo)

	// retorno da selecao
	Local _aRet := {}

	// edita informacoes
	local _lEdtDados := ( ! _lCtrlCheg )

	// campos utilizados
	Private _dDtReceb	:= dDataBase // cnfe solicitacao do Daniel 25.01 -> Date()
	// dados do cliente
	Private _cCodCli	:= CriaVar("A1_COD",.f.)
	Private _cLojCli	:= CriaVar("A1_LOJA",.f.)
	Private _cNomCli	:= CriaVar("A1_NOME",.f.)

	Private _cNumProg	:= CriaVar("Z1_CODIGO",.f.)
	Private _cIteProg	:= CriaVar("Z2_ITEM",.f.)

	// praca (origem ou destino)
	Private _cCodPraca	:= CriaVar("ZB_CODIGO",.f.)
	Private _cDscPraca	:= CriaVar("ZB_DESCRI",.f.)

	// transportadora do contrato
	Private _cTranContr	:= CriaVar("A4_COD",.f.)
	// transportadora da mercadoria
	Private _cCodTransp	:= CriaVar("A4_COD",.f.)
	Private _cNomTransp	:= CriaVar("A4_NOME",.f.)

	// placas
	Private _cPlaca1	:= CriaVar("DA3_COD",.f.)
	Private _cPlaca2	:= CriaVar("DA3_COD",.f.)

	// motorista
	Private _cCodMotor	:= CriaVar("DA4_COD",.f.)
	Private _cNomMotor	:= CriaVar("DA4_NOME",.f.)

	// informacoes de containers
	Private _aConteudo	:= sfCboxToArray("Z2_CONTEUD",.t.)
	// conteudo carga solta
	Private _cConteud1	:= ""

	// observacoes
	Private _cObserv	:= CriaVar("Z3_OBS",.f.)

	// RECNOs do SZ3 utilizado para apontamento de saida
	Private _aRecnoSZ3	:= {0,0}

	// tipo de operacao
	_lEntrada := (mvTipo=="E")

	// recebimento duplo de container
	_lRecDuplo := .f.

	// carga solta
	_lCargaSol := .t.

	// na entrada de carga solta, executa opcoes de: Chegada de Caminhao / Entrada de Caminhao
	If (_lEntrada)

		If  (_lCtrlCheg)
			// opcoes de tipo de entrada de caminhao
			// retorno 1- True/False
			//         2- 1-Chegada de Caminhão / 2-Entrada de Caminhão / 3-Estorno de Chegada
			//_aRet := sfOpcoes()

			// se for cancelado
			If ( ! _aRet[1] )
				Return
				// chegada de caminhoes
			ElseIf (_aRet[2]=="1")
				// funcao para registrar a chegada do caminhao
				sfCamChega()
				Return
				// entrada de caminhoes
			ElseIf (_aRet[2]=="2")
				// funcao para selecionar o caminhao
				If ( ! sfCaminhoes("E",.f.) )
					Return
				EndIf
				// cancelamento de chegada de caminhoes
			ElseIf (_aRet[2]=="3")
				// funcao para selecionar o caminhao
				Return(sfCaminhoes("E",.t.))
			EndIf
		EndIf

		// saida de caminhoes, seleciona o caminhao disponivel no patio
	Else
		// funcao para selecionar o caminhao
		If ( ! sfCaminhoes("S",.f.) )
			Return
		EndIf
	EndIf

	SetKey(VK_F7,{|| oBtnEstorno:Click() } )
	SetKey(VK_F9,{|| oBtnConfRec:Click() } )
	SetKey(VK_F10,{|| oBtnFechar:Click() } )

	// definicao da tela
	_oDlgCarSol := MSDialog():New(000,000,400,920,"Movimentação de Carga Solta",,,.F.,,,,,,.T.,,,.T. )

	// data de movimentacao
	oSayDtMov := TSay():New(010,012,{||"Data de Movimentação"},_oDlgCarSol,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetDtMov := TGet():New(008,110,{|u| If(PCount()>0,_dDtReceb:=u,_dDtReceb)},_oDlgCarSol,070,011,,,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_dDtReceb",,)
	oGetDtMov:Disable()

	// dados do cliente
	oSayCliente := TSay():New(025,012,{||"Cód/Loja Cliente"},_oDlgCarSol,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCodCli := TGet():New(023,110,{|u| If(PCount()>0,_cCodCli:=u,_cCodCli)},_oDlgCarSol,050,011,PesqPict("SA1","A1_COD"),{||Vazio().or.sfVldCliente()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SA1","_cCodCli",,)
	oGetCodCli:BWHEN := {|| _lEdtDados }
	oGetLojCli := TGet():New(023,165,{|u| If(PCount()>0,_cLojCli:=u,_cLojCli)},_oDlgCarSol,030,011,PesqPict("SA1","A1_LOJA"),{||Vazio().or.sfVldCliente()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cLojCli",,)
	oGetLojCli:BWHEN := {|| _lEdtDados }
	oGetNomCli := TGet():New(023,200,{|u| If(PCount()>0,_cNomCli:=u,_cNomCli)},_oDlgCarSol,180,011,PesqPict("SA1","A1_NOME"),,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomCli",,)
	oGetNomCli:Disable()

	// numero e item da programacao
	oSayProgram := TSay():New(040,012,{||"Programação/Item"},_oDlgCarSol,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetNumProg := TGet():New(038,110,{|u| If(PCount()>0,_cNumProg:=u,_cNumProg)},_oDlgCarSol,050,011,PesqPict("SZ1","Z1_CODIGO"),{||Vazio().or.sfVldNumProg()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SZ2MOV","_cNumProg",,)
	oGetNumProg:BWHEN := {|| _lEdtDados }
	oGetIteProg := TGet():New(038,165,{|u| If(PCount()>0,_cIteProg:=u,_cIteProg)},_oDlgCarSol,030,011,PesqPict("SZ2","Z2_ITEM"),{||Vazio().or.sfVldNumProg()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIteProg",,)
	oGetIteProg:BWHEN := {|| _lEdtDados }

	// praca (origem/destino)
	oSayPraca := TSay():New(055,012,{||"Praça "+If(_lEntrada,"Origem","Destino")},_oDlgCarSol,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCodPraca := TGet():New(053,110,{|u| If(PCount()>0,_cCodPraca:=u,_cCodPraca)},_oDlgCarSol,050,011,PesqPict("SZB","ZB_CODIGO"),{||Vazio().or.sfVldPraca()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SZB","_cCodPraca",,)
	oGetCodPraca:BWHEN := {|| ! _lEntrada }
	oGetDscPraca := TGet():New(053,165,{|u| If(PCount()>0,_cDscPraca:=u,_cDscPraca)},_oDlgCarSol,200,011,PesqPict("SZB","ZB_DESCRI"),,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cDscPraca",,)
	oGetDscPraca:Disable()

	// transportadora
	oSayTransp := TSay():New(070,012,{||"Transportadora"},_oDlgCarSol,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCodTransp := TGet():New(068,110,{|u| If(PCount()>0,_cCodTransp:=u,_cCodTransp)},_oDlgCarSol,050,011,PesqPict("SA4","A4_COD"),{||Vazio().or.sfVldTransp()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SA4","_cCodTransp",,)
	oGetNomTransp := TGet():New(068,165,{|u| If(PCount()>0,_cNomTransp:=u,_cNomTransp)},_oDlgCarSol,200,011,,,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomTransp",,)
	oGetNomTransp:Disable()

	// conteudo da carga solta
	oSayConteud := TSay():New(085,012,{||"Conteúdo"},_oDlgCarSol,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetConteud := TComboBox():New(083,110,{|u| If(PCount()>0,_cConteud1:=u,_cConteud1)},_aConteudo,050,011,_oDlgCarSol,,,,,,.T.,oFntVerd18,"",,,,,,,_cConteud1)

	// placa 1 (cavalo)
	oSayPlaca1 := TSay():New(100,012,{||"Placa 1"},_oDlgCarSol,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetPlaca1 := TGet():New(098,110,{|u| If(PCount()>0,_cPlaca1:=u,_cPlaca1)},_oDlgCarSol,050,011,PesqPict("DA3","DA3_COD"),{||Vazio().or.ExistCpo("DA3")},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"DA3","_cPlaca1",,)

	// placa 2 (carreta)
	oSayPlaca2 := TSay():New(115,012,{||"Placa 2"},_oDlgCarSol,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetPlaca2 := TGet():New(113,110,{|u| If(PCount()>0,_cPlaca2:=u,_cPlaca2)},_oDlgCarSol,050,011,PesqPict("DA3","DA3_COD"),{||Vazio().or.ExistCpo("DA3")},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"DA3","_cPlaca2",,)

	// motorista
	oSayMotor := TSay():New(130,012,{||"Motorista"},_oDlgCarSol,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCodMotor := TGet():New(128,110,{|u| If(PCount()>0,_cCodMotor:=u,_cCodMotor)},_oDlgCarSol,050,011,PesqPict("DA4","D4_COD"),{||Vazio().or.sfVldMotor()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"DA4","_cCodMotor",,)
	oGetNomMotor := TGet():New(128,165,{|u| If(PCount()>0,_cNomMotor:=u,_cNomMotor)},_oDlgCarSol,200,011,,,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomMotor",,)
	oGetNomMotor:Disable()

	// observacoes
	oSayObs := TSay():New(145,012,{||"Observações"},_oDlgCarSol,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetObs := TGet():New(143,110,{|u| If(PCount()>0,_cObserv:=u,_cObserv)},_oDlgCarSol,255,011,PesqPict("SZ3","Z3_OBS"),,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cObserv",,)

	// define o tipo de movimentacao
	oSayOperacao := TSay():New(184,080,{||If(_lEntrada,"ENTRADA CARGA SOLTA","SAÍDA CARGA SOLTA")},_oDlgCarSol,,oFntVerd18,.F.,.F.,.F.,.T.,CLR_GREEN)

	// botao para exclusao de movimentacoes
	oBtnEstorno := TButton():New(182,280,"Estorno (F7)",_oDlgCarSol,{|| U_WMSA001C() },050,014,,,,.T.,,"",,,,.F. )

	// botoes de operacoes
	oBtnConfRec := TButton():New(182,340,"Confirmar (F9)",_oDlgCarSol,{|| U_WMSA001Z(Nil, .f., mvTipo, _lRecDuplo)},050,014,,,,.T.,,"",,,,.F. )
	// apontamento de retrabalho
	oBtnFechar := TButton():New(182,400,"Cancelar/Sair (F10)",_oDlgCarSol,{||_oDlgCarSol:End()},050,014,,,,.T.,,"",,,,.F. )

	// ativa o dialogo
	_oDlgCarSol:Activate(,,,.T.,)

	// zera teclas de atalho
	SetKey(VK_F7,{|| Nil})
	SetKey(VK_F9,{|| Nil})
	SetKey(VK_F10,{|| Nil})

Return

// ** funcao que solicita o tipo de entrada de caminhao
Static Function sfOpcoes()
	// opcoes
	Local _aOpcoes := {"","1-Chegada de Caminhão","2-Entrada de Caminhão","3-Estorno de Chegada"}
	Local _cOpcoes := ""
	// controle da confirmacao
	Local _lOk := .f.

	// definicao da tela
	_oDlgOpcEnt := MSDialog():New(000,000,120,300,"Opções de Entrada...",,,.F.,,,,,,.T.,,,.T. )
	// opcoes de entrada
	_oSayOpcoes := TSay():New(010,010,{||"Selecione a opção:"},_oDlgOpcEnt,,oFntVerd13,.F.,.F.,.F.,.T.)
	_oGetOpcoes :=  TComboBox():New(020,010,{|u| If(PCount()>0,_cOpcoes:=u,_cOpcoes)},_aOpcoes,134,014,_oDlgOpcEnt,,,,,,.T.,oFntVerd18,"",,,,,,,_cOpcoes)
	// botoes de opcoes
	_oBtnEntOk   := TButton():New(040,034,"Confirma",_oDlgOpcEnt,{|| If(_lOk:=(!Empty(_cOpcoes)),_oDlgOpcEnt:End(),nil) },050,014,,oFntVerd18,,.T.,,"",,,,.F. )
	_oBtnEntSair := TButton():New(040,094,"Cancela",_oDlgOpcEnt,{|| _oDlgOpcEnt:End() },050,014,,oFntVerd18,,.T.,,"",,,,.F. )

	// ativa o dialogo
	_oDlgOpcEnt:Activate(,,,.T.,)

Return({_lOk,Left(_cOpcoes,1)})

// ** funcao para registrar chegada de caminhoes
Static Function sfCamChega()

	// definicao da tela
	_oDlgCheCam := MSDialog():New(000,000,300,700,"Registra Chegada do Caminhão",,,.F.,,,,,,.T.,,,.T. )

	// titulo
	_oSayTitulo := TSay():New(010,012,{||"Registro da Chegada do Caminhão"},_oDlgCheCam,,oFntVerd18 ,.F.,.F.,.F.,.T.,CLR_GREEN)

	// dados do cliente
	oSayCliente := TSay():New(025,012,{||"Código Cliente"},_oDlgCheCam,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCodCli := TGet():New(023,080,{|u| If(PCount()>0,_cCodCli:=u,_cCodCli)},_oDlgCheCam,050,011,PesqPict("SA1","A1_COD"),{||Vazio().or.sfVldCliente()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SA1","_cCodCli",,)
	oGetLojCli := TGet():New(023,135,{|u| If(PCount()>0,_cLojCli:=u,_cLojCli)},_oDlgCheCam,030,011,PesqPict("SA1","A1_LOJA"),{||Vazio().or.sfVldCliente()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cLojCli",,)
	oGetNomCli := TGet():New(023,170,{|u| If(PCount()>0,_cNomCli:=u,_cNomCli)},_oDlgCheCam,165,011,PesqPict("SA1","A1_NOME"),,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomCli",,)
	oGetNomCli:Disable()

	// numero e item da programacao
	oSayProgram := TSay():New(040,012,{||"Programação"},_oDlgCheCam,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetNumProg := TGet():New(038,080,{|u| If(PCount()>0,_cNumProg:=u,_cNumProg)},_oDlgCheCam,050,011,PesqPict("SZ1","Z1_CODIGO"),{||Vazio().or.sfVldNumProg()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SZ2MOV","_cNumProg",,)
	oGetNumProg:BWHEN := {||_lEntrada}
	oGetIteProg := TGet():New(038,135,{|u| If(PCount()>0,_cIteProg:=u,_cIteProg)},_oDlgCheCam,030,011,PesqPict("SZ2","Z2_ITEM"),{||Vazio().or.sfVldNumProg()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cIteProg",,)
	oGetIteProg:BWHEN := {||_lEntrada}

	// transportadora
	_oSayTransp := TSay():New(055,012,{||"Transportadora"},_oDlgCheCam,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCodTransp := TGet():New(053,080,{|u| If(PCount()>0,_cCodTransp:=u,_cCodTransp)},_oDlgCheCam,050,011,PesqPict("SA4","A4_COD"),{||Vazio().or.sfVldTransp()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SA4","_cCodTransp",,)
	oGetNomTransp := TGet():New(053,135,{|u| If(PCount()>0,_cNomTransp:=u,_cNomTransp)},_oDlgCheCam,200,011,,,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomTransp",,)
	oGetNomTransp:Disable()

	// placa 1 (cavalo)
	oSayPlaca1 := TSay():New(070,012,{||"Placa 1"},_oDlgCheCam,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetPlaca1 := TGet():New(068,080,{|u| If(PCount()>0,_cPlaca1:=u,_cPlaca1)},_oDlgCheCam,050,011,PesqPict("DA3","DA3_COD"),{||Vazio().or.ExistCpo("DA3")},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"DA3","_cPlaca1",,)

	// placa 2 (carreta)
	oSayPlaca2 := TSay():New(085,012,{||"Placa 2"},_oDlgCheCam,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetPlaca2 := TGet():New(083,080,{|u| If(PCount()>0,_cPlaca2:=u,_cPlaca2)},_oDlgCheCam,050,011,PesqPict("DA3","DA3_COD"),{||Vazio().or.ExistCpo("DA3")},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"DA3","_cPlaca2",,)

	// motorista
	oSayMotor := TSay():New(100,012,{||"Motorista"},_oDlgCheCam,,oFntVerd18,.F.,.F.,.F.,.T.)
	oGetCodMotor := TGet():New(098,080,{|u| If(PCount()>0,_cCodMotor:=u,_cCodMotor)},_oDlgCheCam,050,011,PesqPict("DA4","D4_COD"),{||Vazio().or.sfVldMotor()},,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"DA4","_cCodMotor",,)
	oGetNomMotor := TGet():New(098,135,{|u| If(PCount()>0,_cNomMotor:=u,_cNomMotor)},_oDlgCheCam,200,011,,,,,oFntVerd18,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","_cNomMotor",,)
	oGetNomMotor:Disable()

	// botoes de opcoes
	_oBtnCheOk   := TButton():New(130,225,"Confirma",_oDlgCheCam,{|| U_WMSA001Y(Nil, .f.)      },050,014,,oFntVerd18,,.T.,,"",,,,.F. )
	_oBtnCheSair := TButton():New(130,285,"Cancela",_oDlgCheCam, {|| _oDlgCheCam:End() },050,014,,oFntVerd18,,.T.,,"",,,,.F. )

	// ativa o dialogo
	_oDlgCheCam:Activate(,,,.T.,)

Return

// ** funcao para confirmar a chegada do caminhao
User Function WMSA001Y(mvCesv, mvRotAut)

	// valores padroes
	Default mvRotAut := .f.
	Default mvCesv   := CriaVar("ZZ_CESV", .f.)

	// cliente
	If (Empty(_cCodCli)).or.(Empty(_cLojCli))
		MsgStop("Campos Obrigatórios -> Código do Cliente e Loja")
		Return(.f.)
	EndIf

	// numero da programacao
	If (Empty(_cNumProg)).or.(Empty(_cIteProg))
		MsgStop("Campos Obrigatórios -> Código da Programação e Item")
		Return(.f.)
	EndIf

	// transportadora e motorista
	If (Empty(_cCodTransp)).or.(Empty(_cCodMotor))
		MsgStop("Campos Obrigatórios -> Transportadora e Motorista")
		Return(.f.)
	EndIf

	// placas
	If (Empty(_cPlaca1))
		MsgStop("Campos Obrigatórios -> Placa 1")
		Return(.f.)
	EndIf

	// posiciona na programacao
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	If SZ1->(dbSeek( xFilial("SZ1")+_cNumProg ))
		// valida se a programacao esta encerrada
		If ( ! Empty(SZ1->Z1_DTFINFA))
			MsgStop("Programação encontra-se encerrada. Contate o setor de Faturamento.")
			Return(.f.)
		EndIf
	EndIf

	// quando nao for rotina automatica
	If ( ! mvRotAut)
		// confirmacao dos dados
		If ( ! MsgYesNo("Confirma Chegada do Caminhão ?", "Confirmação"))
			Return(.f.)
		EndIf
	EndIf

	// grava os dados da movimentacao
	dbSelectArea("SZ3")
	RecLock("SZ3",.t.)
	SZ3->Z3_FILIAL	:= xFilial("SZ3")
	SZ3->Z3_CLIENTE	:= _cCodCli
	SZ3->Z3_LOJA	:= _cLojCli
	SZ3->Z3_PROGRAM	:= _cNumProg
	SZ3->Z3_ITEPROG	:= _cIteProg
	SZ3->Z3_DTCHEGA	:= _dDtReceb
	SZ3->Z3_HRCHEGA	:= Left(Time(),5)
	SZ3->Z3_TPMOVIM	:= If(_lEntrada,"E","S")
	SZ3->Z3_TAMCONT	:= "CS"
	SZ3->Z3_TRANSP	:= _cCodTransp
	SZ3->Z3_PLACA1	:= _cPlaca1
	SZ3->Z3_PLACA2	:= _cPlaca2
	SZ3->Z3_MOTORIS	:= _cCodMotor
	SZ3->Z3_USRINCL := __cUserId
	If ( ! Empty(mvCesv))
		SZ3->Z3_CESV := mvCesv
	EndIf
	MsUnLock()

	// quando nao for rotina automatica, fecha a tela
	If ( ! mvRotAut)
		// fecha a tela de apontamento
		_oDlgCheCam:End()
	EndIf

Return

// ** funcao funcao para selecionar o caminhao disponivel
Static Function sfCaminhoes(mvTipo,mvCancCheg)
	Local _cQuery
	// variaveis do browse
	Local _aHeadCamin := {}
	Local _aColsCamin := {}
	// controle da confirmacao
	Local _lOk := .f.
	// posicao do campo RECNO
	Local _nPosRecno := 0

	// alimenta o header
	If (_lCtrlCheg)
		aAdd(_aHeadCamin,{"Dt Chegada"		,"Z3_DTCHEGA","@!"							,TamSx3("Z3_DTCHEGA")[1] , 0,Nil,Nil,"D",Nil,"R" })
		aAdd(_aHeadCamin,{"Hr Chegada"		,"Z3_HRCHEGA",PesqPict("SZ3","Z3_HRCHEGA")	,TamSx3("Z3_HRCHEGA")[1] , 0,Nil,Nil,"C",Nil,"R" })
	EndIf
	// demais campos
	aAdd(_aHeadCamin,{"Dt Entrada"		,"Z3_DTMOVIM","@!"							,TamSx3("Z3_DTMOVIM")[1] , 0,Nil,Nil,"D",Nil,"R" })
	aAdd(_aHeadCamin,{"Hr Entrada"		,"Z3_HRMOVIM",PesqPict("SZ3","Z3_HRMOVIM")	,TamSx3("Z3_HRMOVIM")[1] , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadCamin,{"Programação"		,"Z3_PROGRAM",PesqPict("SZ3","Z3_PROGRAM")	,TamSx3("Z3_PROGRAM")[1] , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadCamin,{"Item"			,"Z3_ITEPROG",PesqPict("SZ3","Z3_ITEPROG")	,TamSx3("Z3_ITEPROG")[1] , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadCamin,{"Cliente"			,"A1_NOME"   ,PesqPict("SA1","A1_NOME")		,TamSx3("A1_NOME")[1]    , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadCamin,{"Placa"			,"Z3_PLACA1" ,PesqPict("SZ3","Z3_PLACA1")	,TamSx3("Z3_PLACA1")[1]  , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadCamin,{"Caminhão"		,"DA3_DESC"  ,PesqPict("DA3","DA3_DESC")	,TamSx3("DA3_DESC")[1]   , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadCamin,{"Transportadora"	,"A4_NOME"   ,PesqPict("SA4","A4_NOME")		,TamSx3("A4_NOME")[1]    , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadCamin,{"Motorista"		,"DA4_NOME"  ,PesqPict("DA4","DA4_NOME")	,TamSx3("DA4_NOME")[1]   , 0,Nil,Nil,"C",Nil,"R" })
	aAdd(_aHeadCamin,{"Recno SZ3"		,"SZ3RECNO"  ,""							,10   					 , 0,Nil,Nil,"N",Nil,"R" })
	// armazena a posiscao do campo recno
	_nPosRecno := Len(_aHeadCamin)

	// busca as movimentacoes
	_cQuery := "SELECT "
	If (_lCtrlCheg)
		_cQuery += "Z3_DTCHEGA, Z3_HRCHEGA, "
	EndIf
	_cQuery += "Z3_DTMOVIM, Z3_HRMOVIM, Z3_PROGRAM, Z3_ITEPROG, A1_NOME, Z3_PLACA1, DA3_DESC, A4_NOME, DA4_NOME, "
	// campos de controle
	_cQuery += "SZ3.R_E_C_N_O_ SZ3RECNO, '.F.' IT_DEL "
	// movimentacoes de containers/carga solta
	_cQuery += "FROM "+RetSqlName("SZ3")+" SZ3 (nolock)  "
	// cad. cliente
	_cQuery += "INNER JOIN "+RetSqlName("SA1")+" SA1 (nolock)  ON A1_FILIAL  = '"+xFilial("SA1")+"' AND A1_COD  = Z3_CLIENTE AND A1_LOJA = Z3_LOJA AND SA1.D_E_L_E_T_ = ' ' "
	// cad. transportadora
	_cQuery += "INNER JOIN "+RetSqlName("SA4")+" SA4 (nolock)  ON A4_FILIAL  = '"+xFilial("SA4")+"' AND A4_COD  = Z3_TRANSP  AND SA4.D_E_L_E_T_ = ' ' "
	// cad. veiculos
	_cQuery += "INNER JOIN "+RetSqlName("DA3")+" DA3 (nolock)  ON DA3_FILIAL = '"+xFilial("DA3")+"' AND DA3_COD = Z3_PLACA1  AND DA3.D_E_L_E_T_ = ' ' "
	// cad. motoristas
	_cQuery += "INNER JOIN "+RetSqlName("DA4")+" DA4 (nolock)  ON DA4_FILIAL = '"+xFilial("DA4")+"' AND DA4_COD = Z3_MOTORIS AND DA4.D_E_L_E_T_ = ' ' "
	// filtros
	_cQuery += "WHERE Z3_FILIAL = '"+xFilial("SZ3")+"' AND SZ3.D_E_L_E_T_ = ' ' "
	_cQuery += "AND Z3_TPMOVIM = 'E' "
	// soh pode trazer carga solta
	_cQuery += "AND Z3_TAMCONT = 'CS' "
	// na rotina de entrada de caminhoes
	If (mvTipo=="E")
		_cQuery += "AND Z3_DTMOVIM = ' ' "
		// na rotina de saida de caminhoes
	ElseIf (mvTipo=="S")
		_cQuery += "AND Z3_DTMOVIM != ' ' "
		_cQuery += "AND Z3_DTSAIDA = ' ' "
	EndIf

	// ordem dos dados
	_cQuery += "ORDER BY Z3_DTMOVIM, Z3_HRMOVIM "

	memowrit("c:\query\twmsv001_sfCaminhoes.txt",_cQuery)

	// alimenta o acols com o resultado do SQL
	_aColsCamin := U_SqlToVet(_cQuery,{"Z3_DTCHEGA","Z3_DTMOVIM"})

	// verifica se tem itens
	If (Len(_aColsCamin)==0)
		MsgStop("Não há movimentações disponíveis!")
		Return(.f.)
	EndIf

	// monta o dialogo do monitor
	_oDlgDetCond := MSDialog():New(000,000,400,800,"Caminhões Disponíveis",,,.F.,,,,,,.T.,,,.T. )

	// cria o panel do cabecalho (opcoes da pesquisa)
	_oPnlCabec := TPanel():New(000,000,nil,_oDlgDetCond,,.F.,.F.,,,000,020,.T.,.F. )
	_oPnlCabec:Align:= CONTROL_ALIGN_TOP
	// numero do pedido
	_oSayTitulo := TSay():New(004,010,{||"Caminhões Disponíveis" },_oPnlCabec,,oFntVerd18,.F.,.F.,.F.,.T.)
	// botao pra confirmar
	_oBtnConf := SButton():New(004,330,1,{||_lOk:=.t.,_oDlgDetCond:End()},_oPnlCabec,,"", )
	// botao pra fechar
	_oBtnSair := SButton():New(004,370,2,{||_oDlgDetCond:End()},_oPnlCabec,,"", )

	// browse com a listagem dos produtos conferidos
	_oBrwDetCond := MsNewGetDados():New(000,000,400,400,Nil,'AllwaysTrue()','AllwaysTrue()','',,,Len(_aColsCamin),'AllwaysTrue()','','AllwaysTrue()',_oDlgDetCond,_aHeadCamin,_aColsCamin)
	_oBrwDetCond:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	_oBrwDetCond:oBrowse:blDblClick := {|| _oBtnConf:Click() }

	// ativa a tela
	ACTIVATE MSDIALOG _oDlgDetCond CENTERED

	If (_lOk)
		// pesquisa o registro original
		dbSelectArea("SZ3")
		SZ3->(dbGoTo( _oBrwDetCond:aCols[_oBrwDetCond:nAt,_nPosRecno] ))

		// opcao para estorno da chegada de um caminhao
		If (mvCancCheg)
			// confirmacao do estorno
			If (MsgYesNo("Confirma Estorno da Chegada do Caminhão?", "Estorno"))
				RecLock("SZ3")
				SZ3->(dbDelete())
				MsUnLock()
			Else
				Return(.f.)
			EndIf
			// confirmacao da chegada do caminhao
		Else
			// atualiza RECNO
			_aRecnoSZ3[1] := SZ3->(RecNo())

			// atualiza as variaveis
			// cliente
			_cCodCli	:= SZ3->Z3_CLIENTE
			_cLojCli	:= SZ3->Z3_LOJA
			_cNomCli	:= Posicione("SA1",1, xFilial("SA1")+_cCodCli+_cLojCli ,"A1_NOME")
			// programacao
			_cNumProg	:= SZ3->Z3_PROGRAM
			_cIteProg	:= SZ3->Z3_ITEPROG
			// transportadora
			_cCodTransp := SZ3->Z3_TRANSP
			_cNomTransp := Posicione("SA4",1, xFilial("SA4")+_cCodTransp ,"A4_NOME")
			// placas
			_cPlaca1	:= SZ3->Z3_PLACA1
			_cPlaca2	:= SZ3->Z3_PLACA2
			// motorista
			_cCodMotor	:= SZ3->Z3_MOTORIS
			_cNomMotor	:= Posicione("DA4",1, xFilial("DA4")+_cCodMotor ,"DA4_NOME")
			// executa o validador da programacao
			_lOk := sfVldNumProg()

			// recoloca o codigo da transportadora, pois a movimentacao pode estar diferente da programacao
			_cCodTransp := SZ3->Z3_TRANSP
			_cNomTransp := Posicione("SA4",1, xFilial("SA4")+_cCodTransp ,"A4_NOME")
		EndIf
	EndIf

Return(_lOk)

// ** funcao agrupa o movimento de saida com o pacote logistico
Static Function sfAgrMovFre(mvNumRicEnt)
	// area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSZ1 := SZ1->(GetArea())
	local _aAreaSZJ := SZJ->(GetArea())
	// variaveis temporarias
	local _cQuery
	// informacoes temporarias
	local _aTmpInfo := {}


	// posiciona no processo
	dbSelectArea("SZ1")
	SZ1->(dbSetOrder(1)) //1-Z1_FILIAL, Z1_CODIGO
	SZ1->(dbSeek( xFilial("SZ1")+SZ3->Z3_PROGRAM ))


	// verifica se ja existe algum pacote logistico faturado
	_cQuery := "SELECT SZJ.R_E_C_N_O_ SZJRECNO, ZK_PRODUTO "

	// pacote logistico
	_cQuery += "FROM "+RetSqlName("SZJ")+" SZJ (nolock)  "

	// itens do frete
	_cQuery += "INNER JOIN "+RetSqlName("SZK")+" SZK (nolock)  ON "+RetSqlCond("SZK")+" "
	_cQuery += "AND ZK_PROCES  = ZJ_PROCES  AND ZK_ITPROC  = ZJ_ITPROC "
	_cQuery += "AND ZK_CLIENTE = ZJ_CLIENTE AND ZK_LOJA    = ZJ_LOJA "
	_cQuery += "AND ZK_CONTRT  = ZJ_CONTRT  AND ZK_ITCONTR = ZJ_ITCONTR "
	_cQuery += "AND ZK_CONTAIN = ZJ_CONTAIN AND ZK_RIC     = ZJ_RIC "
	_cQuery += "AND ZK_PACOTE  = ZJ_PACOTE  AND ZK_SEQPACO = ZJ_SEQPACO "

	// filtro padrao
	_cQuery += "WHERE "+RetSqlCond("SZJ")+" "
	_cQuery += "AND ZJ_PROCES  = '"+SZ3->Z3_PROGRAM+"' AND ZJ_ITPROC = '"+SZ3->Z3_ITEPROG+"' "
	_cQuery += "AND ZJ_CLIENTE = '"+SZ3->Z3_CLIENTE+"' AND ZJ_LOJA   = '"+SZ3->Z3_LOJA+"' "
	_cQuery += "AND ZJ_CONTAIN = '"+SZ3->Z3_CONTAIN+"' "
	_cQuery += "AND ZJ_RIC     = '"+mvNumRicEnt+"' "
	_cQuery += "AND ZJ_CONTRT  = '"+SZ1->Z1_CONTRT+"' "
	_cQuery += "AND ZJ_STATUS IN ('C','F') "
	_cQuery += "AND ZJ_IDPROCE = ' ' "
	_cQuery += "AND ZJ_PEDIDO <> ' ' "

	// alimenta o vetor
	_aTmpInfo := U_SqlToVet(_cQuery)

	// se encontrou o pacote logistico, aponta o frete
	If (Len(_aTmpInfo) > 0)

		// posiciona no pacote logistico
		dbSelectArea("SZJ")
		SZJ->(dbGoTo( _aTmpInfo[1][1] ))

		// inclui o item
		dbSelectArea("SZK")
		RecLock("SZK",.t.)
		SZK->ZK_FILIAL	:= xFilial("SZK")
		SZK->ZK_PROCES	:= SZ3->Z3_PROGRAM
		SZK->ZK_ITPROC	:= SZ3->Z3_ITEPROG
		SZK->ZK_CONTRT	:= SZJ->ZJ_CONTRT
		SZK->ZK_ITCONTR	:= SZJ->ZJ_ITCONTR
		SZK->ZK_PRODUTO	:= _aTmpInfo[1][2]
		SZK->ZK_CLIENTE	:= SZ3->Z3_CLIENTE
		SZK->ZK_LOJA	:= SZ3->Z3_LOJA
		SZK->ZK_VALOR	:= 0
		SZK->ZK_CONTAIN	:= SZ3->Z3_CONTAIN
		SZK->ZK_DTMOVIM	:= SZ3->Z3_DTMOVIM
		SZK->ZK_TPMOVIM	:= SZ3->Z3_TPMOVIM
		SZK->ZK_RIC		:= SZ3->Z3_RIC
		SZK->ZK_TAMCONT	:= SZ3->Z3_TAMCONT
		SZK->ZK_CONTEUD	:= SZ3->Z3_CONTEUD
		SZK->ZK_PRCORIG	:= SZ3->Z3_PRCORIG
		SZK->ZK_PRCDEST	:= SZ3->Z3_PRCDEST
		SZK->ZK_TRANSP	:= SZ3->Z3_TRANSP
		SZK->ZK_FATURAR	:= SZJ->ZJ_FATURAR
		SZK->ZK_STATUS	:= SZJ->ZJ_STATUS
		SZK->ZK_PACOTE	:= SZJ->ZJ_PACOTE
		SZK->ZK_SEQPACO	:= SZJ->ZJ_SEQPACO
		SZK->ZK_IDPROCE	:= ""
		SZK->ZK_DTPROCE	:= SZJ->ZJ_DTPROCE
		SZK->ZK_USRPROC	:= __cUserId
		SZK->ZK_PEDIDO	:= SZJ->ZJ_PEDIDO
		SZK->ZK_ITEMPED	:= SZJ->ZJ_ITEMPED
		SZK->ZK_DATABAS	:= SZJ->ZJ_DATABAS
		MsUnLock()

	EndIf

	// restaura area inicial
	RestArea(_aAreaSZJ)
	RestArea(_aAreaSZ1)
	RestArea(_aAreaAtu)

Return(.t.)