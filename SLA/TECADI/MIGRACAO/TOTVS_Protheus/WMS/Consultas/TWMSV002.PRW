#INCLUDE "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Consulta de Movimentacoes de Containers/Carga Solta     !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 01/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSV002

	Local _aBrwCores := {{"Z3_TPMOVIM=='E'","ENABLE"},{"Z3_TPMOVIM=='S'","DISABLE"}}

	// movimentacoes
	dbSelectArea("SZ3")

	Private cCadastro := "Movimentações de Containers / Carga Solta"

	Private aRotina := { { "Pesquisar"	,"AxPesqui"		  ,0,1},;
	{ "Visualizar"  ,"U_WMSV002B()"	  ,0,2},;
	{ "Alterar"     ,"U_WMSV002C()"   ,0,4},;
	{ "Autorizar"   ,"U_WMSV002D()"   ,0,1},;
	{ "Legenda"	    ,"U_WMSV002A()"	  ,0,1},;
	{ "Consulta Log","U_WMSV002E()"  ,0,1}}

	DbSelectArea("SZ3")
	SZ3->(DbSetOrder(1))
	mBrowse(6,1,22,75,"SZ3",,,,,,_aBrwCores)

Return

//** funcao para apresentar legenda
User Function WMSV002A
	BrwLegenda(	cCadastro,;
	"Tipo da Movimentação",;
	{{"ENABLE","Entrada"},{"DISABLE","Saída"}})
Return

//** funcao que apresenta tela com os detalhes da movimentacao
User Function WMSV002B(mvFilial,mvRIC)
	// tamanho da tela
	local _aSizeDlg := MsAdvSize()
	// area inicial
	local _aAreaSZ3 := SZ3->(GetArea())
	// dados das movimentacoes
	local _aDadosBrw := {}
	// vetor com a estrutura de apresentacao dos campos
	local _aEstrCmp := {}
	// RICs
	local _cEntRIC := ""
	local _cSaiRIC := ""
	// dados para impressao da RIC
	local _aImprRIC := {}
	// grupo de usuario que permite a impressao
	local _lBtnImpRIC := sfGrpGate()
	// variaveis temporarias
	local _nX, _nVezes
	// valores default
	Default mvFilial := SZ3->Z3_FILIAL
	Default mvRIC    := SZ3->Z3_RIC

	// prepara o vetor com a estrutura de apresentacao dos campos
	aAdd(_aEstrCmp,{"Data e Hora Movimentação"	,"DtoC(SZ3->Z3_DTMOVIM)+' '+SZ3->Z3_HRMOVIM"})
	aAdd(_aEstrCmp,{"Data e Hora Chegada"		,"DtoC(SZ3->Z3_DTCHEGA)+' '+SZ3->Z3_HRCHEGA"})
	aAdd(_aEstrCmp,{"Processo/Item"				,"SZ3->Z3_PROGRAM+' / '+SZ3->Z3_ITEPROG"})
	aAdd(_aEstrCmp,{"Cliente"					,"SZ3->Z3_CLIENTE+' / '+SZ3->Z3_LOJA+' - '+AllTrim(Posicione('SA1',1,xFilial('SA1')+SZ3->(Z3_CLIENTE+Z3_LOJA),'A1_NOME'))"})
	aAdd(_aEstrCmp,{"Container"					,"If(SZ3->Z3_TIPCONT=='99','',Transf(SZ3->Z3_CONTAIN,PesqPict('SZ3','Z3_CONTAIN')))"})
	aAdd(_aEstrCmp,{"Tamanho"					,"If(SZ3->Z3_TIPCONT=='99','',SZ3->Z3_TAMCONT)"})
	aAdd(_aEstrCmp,{"Tipo Container"			,"If(SZ3->Z3_TIPCONT=='99','',Tabela('ZA',SZ3->Z3_TIPCONT))"})
	aAdd(_aEstrCmp,{"Conteúdo Carga (original)" ,"If(SZ3->Z3_CONTEUD=='C','CHEIO','VAZIO')"})
	aAdd(_aEstrCmp,{"Conteúdo Carga (atual)"	,"If(SZ3->Z3_CONTATU=='C','CHEIO','VAZIO')"})
	aAdd(_aEstrCmp,{"Tara"						,"If(SZ3->Z3_TIPCONT=='99','',Transf(SZ3->Z3_TARA,PesqPict('SZ3','Z3_TARA')))"})
	aAdd(_aEstrCmp,{"Lacre"						,"If(SZ3->Z3_TIPCONT=='99','',SZ3->Z3_LACRE)"})
	aAdd(_aEstrCmp,{"RIC"						,"SZ3->Z3_RIC"})
	aAdd(_aEstrCmp,{"RIC Impressa?"				,"If(SZ3->Z3_TIPCONT=='99','',If(SZ3->Z3_RICIMP=='S','SIM','NÃO'))"})
	aAdd(_aEstrCmp,{"Transp. Contrato"			,"SZ3->Z3_TRACONT+' - '+AllTrim(Posicione('SA4',1,xFilial('SA4')+SZ3->Z3_TRACONT ,'A4_NOME'))"})
	aAdd(_aEstrCmp,{"Transportadora"			,"SZ3->Z3_TRANSP+' - '+AllTrim(Posicione('SA4',1,xFilial('SA4')+SZ3->Z3_TRANSP ,'A4_NOME'))"})
	aAdd(_aEstrCmp,{"Motorista"					,"SZ3->Z3_MOTORIS+' - '+AllTrim(Posicione('DA4',1,xFilial('DA4')+SZ3->Z3_MOTORIS ,'DA4_NOME'))"})
	aAdd(_aEstrCmp,{"Placas"					,"Transf(SZ3->Z3_PLACA1,PesqPict('SZ3','Z3_PLACA1'))+If(Empty(SZ3->Z3_PLACA2),'',' / '+Transf(SZ3->Z3_PLACA2,PesqPict('SZ3','Z3_PLACA2')))"})
	aAdd(_aEstrCmp,{"Praça Origem"				,"SZ3->Z3_PRCORIG+' - '+AllTrim(Posicione('SZB',1,xFilial('SZB')+SZ3->Z3_PRCORIG ,'ZB_DESCRI'))"})
	aAdd(_aEstrCmp,{"Praça Destino"				,"SZ3->Z3_PRCDEST+' - '+AllTrim(Posicione('SZB',1,xFilial('SZB')+SZ3->Z3_PRCDEST ,'ZB_DESCRI'))"})
	aAdd(_aEstrCmp,{"Navio"						,"If(SZ3->Z3_TIPCONT=='99','',SZ3->Z3_NAVIO+' - '+AllTrim(Posicione('SZD',1,xFilial('SZD')+SZ3->Z3_NAVIO ,'ZD_DESCRI')))"})
	aAdd(_aEstrCmp,{"Armador"					,"If(SZ3->Z3_TIPCONT=='99','',SZ3->Z3_ARMADOR+' - '+AllTrim(Posicione('SZA',1,xFilial('SZA')+SZ3->Z3_ARMADOR ,'ZA_DESCRI')))"})
	aAdd(_aEstrCmp,{"Despachante"				,"If(SZ3->Z3_TIPCONT=='99'.or.Empty(SZ3->Z3_CODDESP),'',SZ3->Z3_CODDESP+' / '+SZ3->Z3_LOJDESP+' - '+AllTrim(Posicione('SA2',1,xFilial('SA2')+SZ3->(Z3_CODDESP+Z3_LOJDESP) ,'A2_NOME')))"})
	aAdd(_aEstrCmp,{"Observação"				,"AllTrim(SZ3->Z3_OBS)"})
	aAdd(_aEstrCmp,{"Usuário"					,"AllTrim(UsrFullName(SZ3->Z3_USRINCL))"})
	aAdd(_aEstrCmp,{"Faturamento"				,"If((Empty(Z3_DTPGTOF)).and.(Empty(Z3_DTFATAR)).and.(Empty(Z3_DTFATFR)).and.(Empty(Z3_DTFATPA)),'NÃO','SIM')"})

	// pesquisa a RIC recebida como parametro
	dbSelectArea("SZ3")
	SZ3->(dbOrderNickName("Z3_RIC")) // 4-Z3_FILIAL, Z3_RIC
	If SZ3->(dbSeek( mvFilial+mvRIC ))
		// se for movimentacao de entrada
		If (SZ3->Z3_TPMOVIM=="E")
			// RIC Entrada
			_cEntRIC := SZ3->Z3_RIC
			// RIC Saida
			_cSaiRIC := U_FtRetRIC(SZ3->Z3_RIC,SZ3->Z3_FILIAL)

			// se for movimentacao de saida
		ElseIf (SZ3->Z3_TPMOVIM=="S")
			// RIC Entrada
			_cEntRIC := U_FtRetRIC(SZ3->Z3_RIC,SZ3->Z3_FILIAL)
			// RIC Saida
			_cSaiRIC := SZ3->Z3_RIC

		EndIf
	EndIf

	// varre 2 vezes, 1 para entrada e outra para saida
	For _nVezes := 1 to 2
		// posiciona a RIC (1-Entrada/2-Saida
		dbSelectArea("SZ3")
		SZ3->(dbOrderNickName("Z3_RIC")) // 4-Z3_FILIAL, Z3_RIC
		// pesquisa o numero da RIC
		If SZ3->(dbSeek( mvFilial+If(_nVezes==1,_cEntRIC,_cSaiRIC) ))
			// adiciona os dados para impressao da RIC
			aAdd(_aImprRIC,{SZ3->Z3_TPMOVIM, SZ3->Z3_RIC, SZ3->Z3_RICIMP})
		EndIf

		// varre toda a estrutura dos campos
		For _nX := 1 to Len(_aEstrCmp)
			// se for entrada, adiciona a linha
			If (_nVezes==1)
				aAdd(_aDadosBrw,{_aEstrCmp[_nX][1],&(_aEstrCmp[_nX][2]),"SEM MOVIMENTAÇÃO DE SAÍDA"})

				// se for saida, atualiza a linha
			ElseIf (_nVezes==2).and.(!Empty(_cSaiRIC))
				_aDadosBrw[_Nx][3] := &(_aEstrCmp[_nX][2])

			EndIf
		Next _nX
	Next _nVezes


	// define a tela para apresentar os dados
	DEFINE DIALOG _oDlgConsMov TITLE "Consulta Movimentação de Carga" FROM _aSizeDlg[7],000 TO _aSizeDlg[6],_aSizeDlg[5] pixel OF oMainWnd
	// cria o panel com os botoes
	_oPnlConsMov := TPanel():New(000,000,nil,_oDlgConsMov,,.F.,.F.,,,030,030,.T.,.F. )
	_oPnlConsMov:Align:= CONTROL_ALIGN_TOP

	// botao para impressao / reimpressão da RIC
	If (_lBtnImpRIC)
		_oBtnImpRIC := TButton():New(005,005,"Impressão RIC",_oPnlConsMov,{|| sfImpRic(_aImprRIC) },045,012,,,,.T.,,"",,,,.F. )
	EndIf

	// botao para fechar a tela
	_oBtnConsMovFechar := TButton():New(005,((_aSizeDlg[5]/2)-55),"Fechar",_oPnlConsMov,{||_oDlgConsMov:End()},045,012,,,,.T.,,"",,,,.F. )

	// define o browse
	_oBrwConsMov := TWBrowse():New(000,000,_aSizeDlg[6],_aSizeDlg[5],,{'Campo','Entrada','Saída'},{70,200,200},_oDlgConsMov,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
	_oBrwConsMov:SetArray(_aDadosBrw)
	_oBrwConsMov:bLine := {|| {_aDadosBrw[_oBrwConsMov:nAt,01],_aDadosBrw[_oBrwConsMov:nAt,02],_aDadosBrw[_oBrwConsMov:nAt,03] }}
	_oBrwConsMov:Align := CONTROL_ALIGN_ALLCLIENT
	//_oBrwConsMov:bLdblClick:= { || sfEditaCell(@_aDadosBrw, @_oBrwConsMov)}

	// ativa a tela centralizada
	ACTIVATE DIALOG _oDlgConsMov CENTERED

	// restaura area inicial
	RestArea(_aAreaSZ3)
Return

// função para solicitar alteração dos dados de entrada/saída do veículo 
// ou abrir a tela de alteração (para usuário autorizado)
User Function WMSV002C()

	// variaveis locais
	Local nOpcx := 3
	Local aAcho 	:= {"Z3_DTMOVIM","Z3_PRCORIG","Z3_PRCDEST","Z3_MOTORIS","Z3_PLACA1","Z3_TRACONT","Z3_TRANSP","Z3_CONTEUD","Z3_CONTATU","Z3_TIPCONT","Z3_LACRE"}
	Local _aObjects := {}
	Local _aPosObj  := {}
	Local _aInfo    := {}
	Local _nOpca	:= 0
	Local _cHtmlPad := ""
	Local _cHtmlMsg := ""

	// dimensoes padrao
	Local _aSizeDlg := MsAdvSize()

	// auxiliar para FOR
	Local nX := 0

	// usuario responsavel por autorizar - faturamento
	Local _aKUserFat := STRTOKARR(SUPERGETMV("TC_RESFAT"),";",.f.)
	Local _cKUserFat := SUPERGETMV("TC_RESFAT")
	// usuario responsavel por autorizar - gate
	Local _aKUserGat := STRTOKARR(SUPERGETMV("TC_RESGAT"),";",.f.)
	Local _cKUserGat := SUPERGETMV("TC_RESGAT")
	// usuario responsavel por realizar as alterações
	Local _aKUserAlt := STRTOKARR(SUPERGETMV("TC_RESALT"),";",.f.)
	Local _cKUserAlt := SUPERGETMV("TC_RESALT")
	// variavel para teste se é um usuário comum (apenas solicitante)
	Local _lUser     := !((__cUserId $ _cKUserFat ) .OR. (__cUserId $ _cKUserGat ) .OR. (__cUserId $ _cKUserAlt ))
	// variável que salvará o motivo
	Private _cMotivo := ""

	// objetos da tela
	aAdd(_aObjects, {100, 100, .T., .T.})
	_aInfo := {_aSizeDlg[1], _aSizeDlg[2], _aSizeDlg[3], _aSizeDlg[4], 5, 5}
	_aPosObj := MsObjSize(_aInfo, _aObjects,.T.)

	// verifica se for usuário "comum" e autorização ainda está pendente
	If (_lUser) .AND. (SZ3->Z3_SOLAUT == "P")
		Help(,, 'TWMSV002.F01.001',, "Aprovação já está pendente.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"Já existe uma solicitação de alteração em andamento. Aguarde a autorização/alteração dos setores de faturamento e operacional."}) 
		Return()
	EndIf

	//	// verifica se ambos os setores já aprovaram a alteração
	//	If  (SZ3->Z3_AUTFAT == "N") .OR. (SZ3->Z3_AUTGAT == "N") 
	//		Help(,, 'TWMSV002.F01.002',, "Alteração não autorizada.", 1, 0,;
	//		NIL, NIL, NIL, NIL, NIL,;
	//		{"A solicitação de alteração foi negada. Para maiores informações entre em contato com os setores de faturamento e operacional."}) 
	//		Return()
	//	EndIf

	// ****************************************
	// E-mail que será montado para enviar para o usuário autorizador
	_cHtmlPad := "<table width='300px' style='font-family:Verdana;font-size:12px;'>"
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td colspan=2><b>Solicitação de Alterações - Prog: ##program##<b></td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td colspan=2>&nbsp;</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>Usuário:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>##user##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>Filial:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>##filial##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>Programação:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>##program##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>RIC:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>##ric##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>Motivo:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>##motivo##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td colspan=2>&nbsp;</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td colspan=2>##info##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td colspan=2 style='font-size:10px;text-align:center;'>E-mail automático. Favor não responder.</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "</<table>"
	// ****************************************


	// Se o campo de solicitação estiver em branco ou já tiver finalizado uma alteração anterior
	// solicita motivo de alteração
	If ((Empty(SZ3->Z3_SOLAUT)) .OR. (SZ3->Z3_SOLAUT == "F")) .AND. (_lUser)
		// se cancelou o motivo, não continua
		If ( ! sfMotivo())
			Return()
		EndIf

		// grava solicitação de alteração
		Reclock("SZ3",.F.)
		SZ3->Z3_SOLAUT := "P"
		SZ3->Z3_AUTGAT := "A"        // aguardando
		SZ3->Z3_AUTFAT := "A"        // aguardando
		SZ3->Z3_USRSOL := __cUserId // usuário que solicitou a alteração
		MsUnlock()

		// gero log para eventual consulta
		U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC, "Solicita Alteração nos dados :" + _cMotivo, "Usr", SZ3->Z3_PROGRAM)

		// replace nos campos do HTML para cada setor
		_cHtmlMsg := STRTRAN(_cHtmlPad,"##user##"   ,UsrFullName(__cUserID),,)
		_cHtmlMsg := STRTRAN(_cHtmlMsg,"##program##",SZ3->Z3_PROGRAM,,)
		_cHtmlMsg := STRTRAN(_cHtmlMsg,"##motivo##" ,_cMotivo,,)
		_cHtmlMsg := STRTRAN(_cHtmlMsg,"##filial##" ,SZ3->Z3_FILIAL,,)
		_cHtmlMsg := STRTRAN(_cHtmlMsg,"##ric##"    ,SZ3->Z3_RIC,,)
		_cHtmlMsg := STRTRAN(_cHtmlMsg,"##info##", "Para autorizar e/ou alterar, gentileza acessar o TOTVS, módulo 42 (WMS), Menu Consultas > Movimento Entrada e Saída.")

		// envia e-mail para todos os responsáveis (gate/operacional)
		FOR nX := 1 To len(_aKUserGat)
			U_FtMail(_cHtmlMsg, "Solicitação de Alteração Gate - Prog: "+SZ3->Z3_FILIAL+" / "+SZ3->Z3_PROGRAM,UsrRetMail(_aKUserGat[nX]))
		NEXT nX

		// envia e-mail para todos os responsáveis (faturamento/financeiro)
		FOR nX := 1 To len(_aKUserFat)
			U_FtMail(_cHtmlMsg, "Solicitação de Alteração Faturamento - Prog: "+SZ3->Z3_FILIAL+" / "+SZ3->Z3_PROGRAM,UsrRetMail(_aKUserFat[nX]))
		NEXT nX

		// Avisa o usuário que o e-mail foi enviado enviado e que é para aguardar
		HS_MsgInf("Solicitação enviada. Para mais informações acesse Ações Relacionadas > Consulta Log.","Atenção","Atenção")

		Return (.T.)

	EndIf

	// se autorizado pelos setores, libera a alteração pro usuário responsável
	// só permite solicitar alteração para os usuários cadastrados no parâmetro TC_RESALT
	If ( SZ3->Z3_SOLAUT == "P") .AND. (__cUserId $ _cKUserAlt )

		// se negado pelo faturamento
		If ( SZ3->Z3_AUTFAT == "N")
			MsgStop("Registro não aprovado para alteração pelo setor de faturamento.")
			Return()
		EndIf

		// se negado pelo operacional	
		If ( SZ3->Z3_AUTGAT == "N" )
			MsgStop("Registro não aprovado para alteração pelo setor operacional.")
			Return()
		EndIf
		
		// se pendente pelo faturamento
		If ( SZ3->Z3_AUTFAT == "P")
			MsgStop("Registro pendente de aprovação pelo setor de faturamento.")
			Return()
		EndIf

		// se pendente pelo operacional	
		If ( SZ3->Z3_AUTGAT == "P" )
			MsgStop("Registro pendente de aprovação pelo setor operacional.")
			Return()
		EndIf

		// acesso a SZ3
		RegToMemory("SZ3")

		// monto o DLG
		DEFINE MSDIALOG _oDlg TITLE cCadastro FROM _aSizeDlg[7],00 TO _aSizeDlg[6],_aSizeDlg[5] OF oMainWnd PIXEL

		//-- Sintaxe da Enchoice(/*cAlias*/,/*nReg*/,/*nOpc*/,/*aCRA*/,/*cLetra*/,/*cTexto*/,/*aAcho*/,/*aPos*/,/*aCpos*/,/*nModelo*/,/*nColMens*/,/*cMensagem*/,/*cTudoOk*/,/*oWns*/,/*lF3*/,/*lMemoria*/,/*lColumn*/,/*caTela*/,/*lNoFolder*/,/*lProperty*/)³
		EnChoice("SZ3", , nOpcx, , , , aAcho, _aPosObj[1], aAcho, 3, , , , , , .T.)
		//              (nT, nL, nB , nR , nOpc , cLinhaOk    , cTudoOk     , cIniCpos    , lDeleta, aAlter, nFreeze, lEmpty, nMax, cFieldOk, cSuperDel, aTeclas, cDelOk, oWnd)

		// ativa o dialogo do ENCHOICE
		ACTIVATE MSDIALOG _oDlg ON INIT EnchoiceBar(_oDlg,{|| _nOpca := 1,_oDlg:End()},{||_oDlg:End()},,)

		// se o usuário clicar em confirmar, ele segue fazendo as alterações
		If _nOpca == 1
			// gravo as alterações
			sfGravaDados()
		EndIf
	Else
		// caso a programação não tenha sido autorizada
		HS_MsgInf("Alteração aguardando autorização ou não autorizada. Para mais informações acesse Ações Relacionadas>Consulta Log.","Atenção","Atenção")
		Return()
	EndIf

Return()

// ** função para o usuário inserir o motivo da alteração
Static Function sfMotivo()

	// variável de retorno
	Local _lRet      := .f.
	// tipo de fonte a ser mostrada
	Local _oFont
	// label
	Local _oSay
	// textbox
	Local _oTGet
	// textbox
	Local _cTGet
	// botões
	Local _oBmpSalva
	Local _oBmpCanc

	DEFINE MSDIALOG _oDlg TITLE "Motivo" FROM 180,180 TO 330,500 PIXEL

	// defino o tget para aparecer pré preenchido
	_cTGet := "Campos: "+CRLF
	_cTGet += "Motivo: "+CRLF

	// Cria Fonte para visualização
	_oFont := TFont():New('Verdana',,14,.F.)
	// label com a programação
	_oSay  := TSay():New(03,02,{||"Programação/RIC: "+SZ3->Z3_PROGRAM+"/"+SZ3->Z3_RIC},_oDlg,,_oFont,,,,.T.,,,200,20)
	// textbox para o motivo
	_oTGet := tMultiget():new(15,02,{|u|if(pCount()>0,_cTGet:=u,_cTGet)}, _oDlg,159,40, , , , , , .T. )
	// botões
	_oBmpSalva := TButton():New(60,02, "Salvar",_oDlg,{|| _lRet:=.T., _cMotivo:=_cTGet, _oDlg:END()}, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	// botão cancela para sair
	_oBmpCanc := TButton():New(60,121, "Cancelar",_oDlg,{||_oDlg:END()}, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	// ativo o dialogo
	ACTIVATE DIALOG _oDlg CENTERED

Return (_lRet)

// ** função para o usuário autorizar alteração
Static Function sfMotAuto(mvRetAutoriz)

	// variável de retorno
	Local _lRet := .f.
	// tipo de fonte a ser mostrada
	Local _oFont
	// label
	Local _oSay
	// textbox
	Local _oTGet
	// textbox
	Local _cTGet
	// botões
	Local _oBmpSalva
	Local _oBmpCanc

	DEFINE MSDIALOG _oDlg TITLE "Motivo Autorização" FROM 180,180 TO 330,500 PIXEL
	// Cria Fonte para visualização
	_oFont := TFont():New('Verdana',,14,.F.)
	// label com a programação
	_oSay  := TSay():New(03,02,{||"Programação/RIC: "+SZ3->Z3_PROGRAM+"/"+SZ3->Z3_RIC},_oDlg,,_oFont,,,,.T.,,,200,20)
	// textbox para o motivo
	_oTGet := tMultiget():new(15,02,{|u|if(pCount()>0,_cTGet:=u,_cTGet)}, _oDlg,159,40, , , , , , .T. )
	// botões
	_oBmpSalva := TButton():New(60,02, "Autorizar",_oDlg,{|| _cMotAuto:=_cTGet, _lRet := .t., mvRetAutoriz := .t., _oDlg:END()}, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	// botão cancela para sair
	_oBmpCanc := TButton():New(60,121, "Não Autorizar",_oDlg,{||_cMotAuto:=_cTGet, _lRet := .t., mvRetAutoriz := .f., _oDlg:END()}, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	// ativo o dialogo
	ACTIVATE DIALOG _oDlg CENTERED

Return (_lRet)

// ** função para autorizar ou não a solicitação de alteração nos dados
User Function WMSV002D()
	// auxiliar para FOR
	Local nX := 0
	// usuario responsavel por autorizar - faturamento
	Local _aKUserFat := STRTOKARR(SUPERGETMV("TC_RESFAT"),";",.f.)
	Local _cKUserFat := SUPERGETMV("TC_RESFAT")
	// usuario responsavel por autorizar - gate
	Local _aKUserGat := STRTOKARR(SUPERGETMV("TC_RESGAT"),";",.f.)
	Local _cKUserGat := SUPERGETMV("TC_RESGAT")
	// usuario responsavel por realizar as alterações
	Local _aKUserAlt := STRTOKARR(SUPERGETMV("TC_RESALT"),";",.f.)
	Local _cKUserAlt := SUPERGETMV("TC_RESALT")
	// variavel para teste se é um usuário comum (apenas solicitante)
	Local _lUser     := !( (__cUserId $ _cKUserFat ) .OR. (__cUserId $ _cKUserGat ) )
	// HTML
	Local _cHtmlPad := ""
	local _cHtmlMsg := ""
	// variavel que receberá a autorização
	local _lRetAuto := .f. // .T.=AUTORIZADO .F.=NÃO-AUTORIZADO
	// variável que salvará o motivo
	Private _cMotAuto := ""

	// Valida se o usuário tem acesso ao menu de autorização
	If (_lUser)
		MsgStop("Você não tem permissão para acessar o menu de autorização.")
		Return()
	EndIf

	// não deixa autorizar uma programação que não teve solicitação
	If ( SZ3->Z3_SOLAUT != "P")
		MsgStop("Registro sem solicitação de alteração.")
		Return()
	EndIf

	// se negado pelo faturamento
	If ( SZ3->Z3_AUTFAT == "N")
		MsgStop("Registro não aprovado para alteração pelo setor de faturamento.")
		Return()
	EndIf

	// se negado pelo operacional	
	If ( SZ3->Z3_AUTGAT == "N" )
		MsgStop("Registro não aprovado para alteração pelo setor operacional.")
		Return()
	EndIf

	// chama a tela para autorizar caso seja responsavel pelo operacional ou faturamento
	// e ainda esteja aguardando autorização
	If ((__cUserId $ _cKUserFat) .AND. (SZ3->Z3_AUTFAT == "A")) .OR. ((__cUserId $ _cKUserGat) .AND. (SZ3->Z3_AUTGAT == "A"))
		// tela para definir o motivo da autorizacao
		IF ( ! sfMotAuto(@_lRetAuto))
			Return()
		EndIf
	Else
		Help(,, 'TWMSV002.F02.001',, "Aprovação não permitida.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"Este registro já foi autorizado pelo seu setor ou você não possui o acesso necessário."}) 
		Return()
	EndIf

	// ****************************************
	// E-mail que será montado
	_cHtmlPad := "<table width='300px' style='font-family:Verdana;font-size:12px;'>"
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td colspan=2><b>Alterações ##auto## - Prog: ##program##<b></td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td colspan=2>&nbsp;</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>Usuário:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>##user##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>Filial:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>##filial##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>Programação:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>##program##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>RIC:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>##ric##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>Autorização:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>##motivo##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td colspan=2>&nbsp;</td> "
	_cHtmlPad += "	</tr> "

	// Se for autorizada, mostra essa parte do HTML
	If ( _lRetAuto )
		_cHtmlPad += "	<tr> "
		_cHtmlPad += "		<td colspan=2>Para realizar a alteração, gentileza acessar o TOTVS, módulo 42 (WMS), Menu Consultas > Movimento Entrada e Saída, na opção <B>Alterar</B>.</td> "
		_cHtmlPad += "	</tr> "
	EndIf

	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td colspan=2 style='font-size:10px;text-align:center;'>E-mail automático. Favor não responder.</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "</<table>"
	// ****************************************

	// se autorizado
	If ( _lRetAuto )
		// se foi autorizado pelo faturamento
		If (__cUserId $ _cKUserFat)
			// gravo o registro na SZ3 confirmando a autorização
			RecLock("SZ3",.F.)
			SZ3->Z3_AUTFAT := "S"
			MsUnlock()

			// gero log para eventual consulta
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC, "Autorizado pelo faturamento: "+_cMotAuto, "Fat", SZ3->Z3_PROGRAM)

			// replace nos campos do HTML para cada processo
			_cHtmlMsg := STRTRAN(_cHtmlPad,"##auto##","Autorizadas",,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##user##",UsrFullName(__cUserID),,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##program##",SZ3->Z3_PROGRAM,,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##motivo##",_cMotAuto,,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##filial##",SZ3->Z3_FILIAL,,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##ric##",SZ3->Z3_RIC,,)
			// envia e-mail para os resposaveis pela alteracao de dados
			FOR nX := 1 To len(_aKUserAlt)
				// envia e-mail para os resposaveis pela alteracao de dados
				U_FtMail(_cHtmlMsg, "Alterações Autorizadas Faturamento - Prog: "+SZ3->Z3_FILIAL+" / "+SZ3->Z3_PROGRAM,UsrRetMail(_aKUserAlt[nX]))
			NEXT nX

			MsgInfo("Autorização salva com sucesso.","Atenção")
		EndIf

		// se foi autorizado pelo operacional
		If (__cUserId $ _cKUserGat)

			// gravo o registro na SZ3 confirmando a autorização
			RecLock("SZ3",.F.)
			SZ3->Z3_AUTGAT := "S"
			MsUnlock()

			// gero log para eventual consulta
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC, "Autorizado pelo Operacional: "+_cMotAuto, "Gat", SZ3->Z3_PROGRAM)

			// replace nos campos do HTML para cada processo
			_cHtmlMsg := STRTRAN(_cHtmlPad,"##auto##","Autorizadas",,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##user##",UsrFullName(__cUserID),,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##program##",SZ3->Z3_PROGRAM,,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##motivo##",_cMotAuto,,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##filial##",SZ3->Z3_FILIAL,,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##ric##",SZ3->Z3_RIC,,)
			// envia e-mail para os resposaveis pela alteracao de dados
			FOR nX := 1 To len(_aKUserAlt)
				// envia e-mail para os resposaveis pela alteracao de dados
				U_FtMail(_cHtmlMsg, "Alterações Autorizadas Gate - Prog: "+SZ3->Z3_FILIAL+" / "+SZ3->Z3_PROGRAM,UsrRetMail(_aKUserAlt[nX]))
			NEXT nX

			MsgInfo("Autorização salva com sucesso.","Atenção")
		EndIf

	ElseIf ( ! _lRetAuto )  // não autorizado
		// se financeiro/faturamento
		If (__cUserId $ _cKUserFat)

			// gravo o registro na SZ3 negando a autorização
			RecLock("SZ3",.F.)
			SZ3->Z3_AUTFAT := "N" // nega a alteração
			SZ3->Z3_SOLAUT := "F" // finalizo a alteração, pois não precisa mais outro setor autorizar
			MsUnlock()

			// gero log para eventual consulta
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC, __cUserId + " - Não autorizado pelo Faturamento: "+_cMotAuto, "Fat", SZ3->Z3_PROGRAM)

			// replace nos campos do HTML para cada processo
			_cHtmlMsg := STRTRAN(_cHtmlPad,"##auto##","Não-Autorizadas",,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##user##",UsrFullName(__cUserID),,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##program##",Z3_PROGRAM,,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##motivo##",_cMotAuto,,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##filial##",Z3_FILIAL,,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##ric##",Z3_RIC,,)
			// envia e-mail para todos os responsáveis
			FOR nX := 1 To len(_aKUserFat)
				// envia e-mail para gate e responsável solicitando autorização
				U_FtMail(_cHtmlMsg, "Alterações Não-Autorizadas Faturamento - Prog: "+SZ3->Z3_PROGRAM,UsrRetMail(_aKUserFat[nX]))
			NEXT nX

			MsgInfo("Informação salva com sucesso.","Atenção")

		EndIf
		
		// se operacional
		If (__cUserId $ _cKUserGat)
			// finalizo a alteração
			RecLock("SZ3",.F.)
			SZ3->Z3_AUTGAT := "N" // nega a alteração
			SZ3->Z3_SOLAUT := "F" // finalizo a alteração, pois não precisa mais outro setor autorizar
			MsUnlock()
			
			// gero log para eventual consulta
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC, __cUserId + " - Não autorizado pelo operacional: "+_cMotAuto, "Gat", SZ3->Z3_PROGRAM)

			// replace nos campos do HTML para cada processo
			_cHtmlMsg := STRTRAN(_cHtmlPad,"##auto##","Não-Autorizadas",,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##user##",UsrFullName(__cUserID),,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##program##",SZ3->Z3_PROGRAM,,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##motivo##",_cMotAuto,,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##filial##",SZ3->Z3_FILIAL,,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##ric##",SZ3->Z3_RIC,,)
			// envia e-mail para todos os responsáveis
			FOR nX := 1 To len(_aKUserGat)
				// envia e-mail para gate e responsável solicitando autorização
				U_FtMail(_cHtmlMsg, "Alterações Não-autorizadas (operacional) - Prog: "+SZ3->Z3_PROGRAM,UsrRetMail(_aKUserGat[nX]))
			NEXT nX

			MsgInfo("Informação salva com sucesso.","Atenção")
		EndIf
	EndIf

Return ()
// ** função que salva os dados editados pelo ENCHOICE
Static Function sfGravaDados(mvHtml)
	// Query pra gravar dados que precisam de filtro
	Local _cQryUpd := ""
	// html para e-mail
	Local _cHtmlPad := ""
	local _cHtmlMsg := ""

	// varivel temporaria de conteudo De->Para
	local _xValorDe
	local _xValorPara

	// dados atualizados
	local _lDadosAtu := .f.

	// ****************************************
	// E-mail que será montado
	_cHtmlPad := "<table width='300px' style='font-family:Verdana;font-size:12px;'>"
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td colspan=2><b>Alterações Realizadas - Prog: ##program##<b></td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td colspan=2>&nbsp;</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>Usuário:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>##user##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>Filial:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>##filial##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>Programação:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>##program##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>RIC:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>##ric##</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td width='30%' style='border:1px solid gray;text-align: center;'><b>Status:</b></td> "
	_cHtmlPad += "		<td style='border:1px solid gray;text-align: left;'>Alterações realizadas conforme solicitação.</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td colspan=2>&nbsp;</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "	<tr> "
	_cHtmlPad += "		<td colspan=2 style='font-size:10px;text-align:center;'>E-mail automático. Favor não responder.</td> "
	_cHtmlPad += "	</tr> "
	_cHtmlPad += "</<table>"
	// ****************************************

	// controle de transação
	BEGIN TRANSACTION

		// se a data for diferente da data da alteração
		If ( (!Empty(M->Z3_DTMOVIM)) .and. (M->Z3_DTMOVIM != SZ3->Z3_DTMOVIM) .and. (M->Z3_DTMOVIM <= Date()) )

			// atualiza variaveis
			_xValorDe   := SZ3->Z3_DTMOVIM
			_xValorPara := M->Z3_DTMOVIM

			// gravo o novo registro
			RecLock("SZ3",.F.)
			SZ3->Z3_DTMOVIM := M->Z3_DTMOVIM
			SZ3->(MsUnlock())

			// log da transação
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC, "Alterações realizadas. Data Movimento: De: "+DTOC(_xValorDe)+", Para: "+DTOC(_xValorPara)+".", "Res", SZ3->Z3_PROGRAM)

			// dados atualizados
			_lDadosAtu := .t.

			// caso seja alteração na data de saída, é necessário alterar demais campos
			If (SZ3->Z3_TPMOVIM == "S")

				// atualiza variaveis
				_xValorDe   := SZ3->Z3_DTSAIDA
				_xValorPara := M->Z3_DTMOVIM

				// gravo a data de saída nos registros de entrada
				RecLock("SZ3",.F.)
				SZ3->Z3_DTSAIDA := M->Z3_DTMOVIM
				MsUnlock()

				// log da transação
				U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC,  "Alterações realizadas. Data Saída: De: "+DTOC(_xValorDe)+", Para: "+DTOC(_xValorPara)+".", "Res", SZ3->Z3_PROGRAM)

				// query pra atualizar o registro de entrada também
				_cQryUpd := "UPDATE "+RetSqlName("SZ3")+" SET Z3_DTSAIDA = '"+DTOS(SZ3->Z3_DTSAIDA)+"' WHERE Z3_FILIAL = '"+SZ3->Z3_FILIAL+"' AND D_E_L_E_T_ = ' ' AND Z3_CONTAIN = '"+SZ3->Z3_CONTAIN+"' AND Z3_PROGRAM = '"+SZ3->Z3_PROGRAM+"' AND Z3_TPMOVIM = 'E'"
				TcSQLExec(_cQryUpd)
			EndIF

		EndIf

		// Praça de Origem / Destino
		If ( (!Empty(M->Z3_PRCORIG)) .and. (M->Z3_PRCORIG != SZ3->Z3_PRCORIG) )

			// atualiza variaveis
			_xValorDe   := SZ3->Z3_PRCORIG
			_xValorPara := M->Z3_PRCORIG

			// gravo a nova praça
			RecLock("SZ3",.F.)
			SZ3->Z3_PRCORIG := M->Z3_PRCORIG
			MsUnlock()

			// log da transação
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC,  "Alterações realizadas. Praça de Origem: De: "+_xValorDe+", Para: "+_xValorPara+".", "Res", SZ3->Z3_PROGRAM)

			// dados atualizados
			_lDadosAtu := .t.

		EndIf

		// Praça de Origem / Destino
		If ( (!Empty(M->Z3_PRCDEST)) .and. (M->Z3_PRCDEST != SZ3->Z3_PRCDEST) )

			// atualiza variaveis
			_xValorDe   := SZ3->Z3_PRCDEST
			_xValorPara := M->Z3_PRCDEST

			// gravo a nova praça
			RecLock("SZ3",.F.)
			SZ3->Z3_PRCDEST := M->Z3_PRCDEST
			MsUnlock()

			// log da transação
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC,  "Alterações realizadas. Praça de Destino: De: "+_xValorDe+", Para: "+_xValorPara+".", "Res", SZ3->Z3_PROGRAM)

			// dados atualizados
			_lDadosAtu := .t.

		EndIf

		// Motorista
		If ( (!Empty(M->Z3_MOTORIS)) .and. (M->Z3_MOTORIS != SZ3->Z3_MOTORIS) )

			// atualiza variaveis
			_xValorDe   := SZ3->Z3_MOTORIS
			_xValorPara := M->Z3_MOTORIS

			// gravo o novo motorista
			RecLock("SZ3",.F.)
			SZ3->Z3_MOTORIS := M->Z3_MOTORIS
			MsUnlock()

			// log da transação
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC,  "Alterações realizadas. Motorista: De: "+_xValorDe+", Para: "+M->_xValorPara +".", "Res", SZ3->Z3_PROGRAM)

			// dados atualizados
			_lDadosAtu := .t.

		EndIf

		// Placa
		If ( (!Empty(M->Z3_PLACA1)) .and. (M->Z3_PLACA1 != SZ3->Z3_PLACA1) )

			// atualiza variaveis
			_xValorDe   := SZ3->Z3_PLACA1
			_xValorPara := M->Z3_PLACA1

			// gravo a nova placa
			RecLock("SZ3",.F.)
			SZ3->Z3_PLACA1 := M->Z3_PLACA1
			MsUnlock()

			// log da transação
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC,  "Alterações realizadas. Placa: De: "+_xValorDe+", Para: "+_xValorPara +".", "Res", SZ3->Z3_PROGRAM)

			// dados atualizados
			_lDadosAtu := .t.

		EndIf

		// Transportadora 1
		If ( (!Empty(M->Z3_TRACONT)) .and. (M->Z3_TRACONT != SZ3->Z3_TRACONT) )

			// atualiza variaveis
			_xValorDe   := SZ3->Z3_TRACONT
			_xValorPara := M->Z3_TRACONT

			// gravo a nova transportadora
			RecLock("SZ3",.F.)
			SZ3->Z3_TRACONT := M->Z3_TRACONT
			MsUnlock()

			// log da transação
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC,  "Alterações realizadas. Transportadora Cont.: De: "+_xValorDe+", Para: "+_xValorPara +".", "Res", SZ3->Z3_PROGRAM)

			// dados atualizados
			_lDadosAtu := .t.

		EndIf

		// Transportadora 2
		If ( (!Empty(M->Z3_TRANSP)) .and. (M->Z3_TRANSP != SZ3->Z3_TRANSP) )

			// atualiza variaveis
			_xValorDe   := SZ3->Z3_TRANSP
			_xValorPara := M->Z3_TRANSP

			// gravo a nova transportadora
			RecLock("SZ3",.F.)
			SZ3->Z3_TRANSP := M->Z3_TRANSP
			MsUnlock()

			// log da transação
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC,  "Alterações realizadas. Transportadora: De: "+_xValorDe+", Para: "+_xValorPara +".", "Res", SZ3->Z3_PROGRAM)

			// dados atualizados
			_lDadosAtu := .t.

		EndIf

		// Conteúdo do Container
		If ( (!Empty(M->Z3_CONTEUD)) .and. (M->Z3_CONTEUD != SZ3->Z3_CONTEUD) )

			// atualiza variaveis
			_xValorDe   := SZ3->Z3_CONTEUD
			_xValorPara := M->Z3_CONTEUD

			// gravo a nova transportadora
			RecLock("SZ3",.F.)
			SZ3->Z3_CONTEUD := M->Z3_CONTEUD
			MsUnlock()

			// log da transação
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC,  "Alterações realizadas. Conteúdo do Container: De: "+_xValorDe+", Para: "+_xValorPara +".", "Res", SZ3->Z3_PROGRAM)

			// dados atualizados
			_lDadosAtu := .t.

		EndIf

		// Conteúdo atual
		If ( (!Empty(M->Z3_CONTATU)) .and. (M->Z3_CONTATU != SZ3->Z3_CONTATU) )

			// atualiza variaveis
			_xValorDe   := SZ3->Z3_CONTATU
			_xValorPara := M->Z3_CONTATU

			// gravo a nova transportadora
			RecLock("SZ3",.F.)
			SZ3->Z3_CONTATU := M->Z3_CONTATU
			MsUnlock()

			// log da transação
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC,  "Alterações realizadas. Conteúdo do Container (atual): De: "+_xValorDe+", Para: "+_xValorPara +".", "Res", SZ3->Z3_PROGRAM)

			// dados atualizados
			_lDadosAtu := .t.

		EndIf

		// tipo de Container
		If ( (!Empty(M->Z3_TIPCONT)) .and. (M->Z3_TIPCONT != SZ3->Z3_TIPCONT) )

			// atualiza variaveis
			_xValorDe   := SZ3->Z3_TIPCONT
			_xValorPara := M->Z3_TIPCONT

			// gravo tipo de container
			RecLock("SZ3",.F.)
			SZ3->Z3_TIPCONT := M->Z3_TIPCONT
			MsUnlock()

			// log da transação
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC,  "Alterações realizadas. Conteúdo do Container (atual): De: "+_xValorDe+", Para: "+_xValorPara +".", "Res", SZ3->Z3_PROGRAM)

			// dados atualizados
			_lDadosAtu := .t.

		EndIf

		// LACRE
		If ( (!Empty(M->Z3_LACRE)) .AND. (M->Z3_LACRE != SZ3->Z3_LACRE) )

			// atualiza variaveis
			_xValorDe   := SZ3->Z3_LACRE
			_xValorPara := M->Z3_LACRE

			// gravo a nova transportadora
			RecLock("SZ3",.F.)
			SZ3->Z3_LACRE := M->Z3_LACRE
			MsUnlock()

			// log da transação
			U_FtGeraLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC,  "Alterações realizadas. LACRE: De: "+_xValorDe+", Para: "+_xValorPara +".", "Res", SZ3->Z3_PROGRAM)

			// dados atualizados
			_lDadosAtu := .T.

		EndIf

		// finalizo a alteração
		If (_lDadosAtu)

			RecLock("SZ3",.F.)
			SZ3->Z3_SOLAUT := "F" // finalizo a alteração
			MsUnlock()

			// message para o usuário informando que as alterações foram realizadas.
			MsgInfo("Dados alterados.","Atenção")

			// replace nos campos do HTML para cada processo
			_cHtmlMsg := STRTRAN(_cHtmlPad,"##user##",UsrFullName(__cUserID),,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##program##",SZ3->Z3_PROGRAM,,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##filial##",SZ3->Z3_FILIAL,,)
			_cHtmlMsg := STRTRAN(_cHtmlMsg,"##ric##",SZ3->Z3_RIC,,)
			U_FtMail(_cHtmlMsg, "Alterações Realizadas - Prog: "+SZ3->Z3_PROGRAM,UsrRetMail(SZ3->Z3_USRSOL))

		EndIf

	END TRANSACTION

Return()

// ** mostra a função de consulta log
User Function WMSV002E()

	// mostra a função padrão par
	U_FtConsLog(SZ3->Z3_FILIAL, "SZ3", SZ3->Z3_FILIAL+SZ3->Z3_PROGRAM+SZ3->Z3_RIC)

Return

//** funcao para impressao / reimpressao da RIC
Static Function sfImpRic(_aImprRIC)
	local _nRic
	local _cTpMovim := If(Len(_aImprRIC)==1,"E","")
	local _nOpcSel := 0
	// usuario com a permissao de reimpressao
	local _cUsrReimp := AllTrim(SuperGetMv("TC_USRREIM",.f.,""))


	// verifica se ha mais de um movimento
	If (Len(_aImprRIC) == 2)
		// solicita qual movimento devera ser impresso
		_nOpcSel := Aviso("Impressão RIC","Selecione qual movimento será impresso:",{"Entrada","Saída","Fechar"} )
		// opcao selecionada
		If (_nOpcSel == 1) // entrada
			_cTpMovim := "E"
		ElseIf (_nOpcSel == 2) // saida
			_cTpMovim := "S"
		EndIf
	EndIf

	// varre as opcoes
	For _nRic := 1 to Len(_aImprRIC)
		// estrutura do vetor _aImprRIC
		// 1-SZ3->Z3_TPMOVIM
		// 2-SZ3->Z3_RIC
		// 3-SZ3->Z3_RICIMP
		If (_aImprRIC[_nRic][1] == _cTpMovim)
			// verifica se pode imprimir
			If (_aImprRIC[_nRic][3] == "N").or.( (_aImprRIC[_nRic][3] == "S").and.(__cUserId $ _cUsrReimp) )
				// funcao para impressao da RIC
				U_WMSA001D(_aImprRIC[_nRic][2])

				// atualiza o status de impressao
				_aImprRIC[_nRic][3] := "S"

				// reimpressao sem acesso
			Else
				Aviso("Re-impressão RIC","Usuário sem permissão para re-impressão de RIC.",{"Fechar"} )
				Return(.f.)
			EndIf
		EndIf
	Next _nRic

Return(.t.)

//** funcao que verifica se eh administrador ou gate
Static Function sfGrpGate()
	// variavel de retorno
	local _lRet := (__cUserId == "000000")
	// grupos do usuario
	local _aGrupos := {}
	// variavel temporaria
	local _nX

	// verifica as condicoes o grupo, quando nao for administrador
	If (!_lRet)

		// retorna os grupos do usuario logado
		_aGrupos := FWSFUsrGrps(__cUserId)

		// varre todos os grupos e retornar descrição do grupo
		For _nX := 1 to Len(_aGrupos)
			// grupo - gate
			If ("000001" $ Upper(_aGrupos[_nX])).or.("GATE" $ Upper(GRPRetName(_aGrupos[_nX])))
				_lRet := .t.
				Exit
				// grupo - administradores
			ElseIf ("000000" $ Upper(_aGrupos[_nX])).or.("ADMIN" $ Upper(GRPRetName(_aGrupos[_nX])))
				_lRet := .t.
				Exit
			EndIf
		Next _nX
	EndIf

Return(_lRet)

