#INCLUDE "rwmake.ch"


User Function SMSPWR01()
  
Local cTexto := ""

cTexto := "Esta rotina tem por finalidade o ajuste de informações incorretas na movimentação bancária. "+CHR(13)+CHR(10)
cTexto += "Após os ajustes feitos é obrigatório o recálculo dos saldos bancários." +CHR(13)+CHR(10) 
cTexto += "As movimentações alteradas por esta rotina não podem ser recuperadas sem um backup." +CHR(13)+CHR(10)
cTexto += "Deseja prosseguir?" 
  
if Aviso("Ajuste de movimentação",cTexto,{"Continuar","Sair"}) == 1
	SMSSE5()

endif




return()

//-----------------------------------------------------------------------------------------------------------------------------------------------------
Static Function SMSSE5()

Local cCondicao := ""

Private cCadastro := "Ajuste de Movimentação"
Private aRotina := { 	{"Pesquisar"	,"AxPesqui",0,1} ,;
             			{"Visualizar"	,"AxVisual",0,2} ,;
             			{"Alterar"		,"AxAltera",0,4} ,;
             			{"Excluir"		,"AxDeleta",0,5} }

Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock
Private cString := "SE5"
Private cFilter	:= ""

If !Empty(cCondicao) .Or. cPaisLoc == "BRA"
	If ExistBlock("F100FBRW")
		cCondicao := ExecBlock("F100FBRW",.F.,.F.,{cCondicao})
	EndIf		                                               
	cFilter := cCondicao
EndIf

dbSelectArea("SE5")
dbSetOrder(1)


dbSelectArea(cString)
mBrowse( 6, 1,22,75,"SE5",,,,,,SMSLegenda(),,,,,,,,cFilter)

Return()

//---------------------------------------------------------------------------------------------------------------------------------------------------------

Static Function SMSLegenda(nReg)

Local aLegenda := { 	{"BR_VERDE"		, "Movimento Bancario - Receber" 	},;		//"Movimento Bancario - Receber"
						{"BR_AZUL"		, "Movimento Bancario - Pagar" 		},;		//"Movimento Bancario - Pagar"
						{"BR_AMARELO"	, "Movimento Bancario - Cancelado" 	},;		//"Movimento Bancario - Cancelado"
						{"BR_VERMELHO"	, "Movimento Bancario - Excluido" 	} }	//"Movimento Bancario - Excluido"
Local uRetorno := .T.

If nReg = Nil	// Chamada direta da funcao onde nao passa, via menu Recno eh passado
	uRetorno := {}
	Aadd(uRetorno, { 'E5_RECPAG = "R" .and. Empty(E5_SITUACA)', aLegenda[1][1] } )
	Aadd(uRetorno, { 'E5_RECPAG = "P" .and. Empty(E5_SITUACA)', aLegenda[2][1] } )
	Aadd(uRetorno, { 'E5_SITUACA $ "X/E"', aLegenda[3][1] } )
	Aadd(uRetorno, { 'E5_SITUACA = "C"', aLegenda[4][1] } )
Else
	BrwLegenda(cCadastro, "Legenda", aLegenda) // "Legenda"
Endif

Return uRetorno


