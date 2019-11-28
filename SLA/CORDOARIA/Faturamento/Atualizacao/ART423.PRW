#include "RWMAKE.CH"

User Function ART423()

// Alterar Representantes usando Markbrowse


  _VendAnt      := space(06)
  _VendAtu      := space(06)
  _lSelecionado := .F.       
  _UF           := space(02) 
  _Mun          := space(05) 
  
  @ 200,1 TO 350,440 DIALOG oDlg4 TITLE "Alteração do Representante no Cliente"
  @ 010,010 SAY OemToAnsi("Do Vendedor : ")
  @ 010,080 GET _VendAnt 	  			SIZE 70,50 F3 "SA3"   
  @ 025,010 SAY OemToAnsi("UF: ")
  @ 025,127 GET _UF						SIZE 10,10  F3 "12" // Tabela de Estados no SX5
  @ 040,10  SAY OemToAnsi("Cidade : ")
  @ 040,100 GET _Mun					SIZE 50,10  F3 "CC2" // Tabela de Municipios
  @ 055,010 SAY OemToAnsi("Para o Vendedor : ")
  @ 055,080 GET _VendAtu				SIZE 70,50 F3 "SA3"
  @ 010,165 BUTTON "&Ok" 				SIZE 35,15 ACTION AlteraRepSA1()
  @ 030,165 Button "&Sair"   			Size 35,15 ACTION Close(oDlg4)
  ACTIVATE DIALOG oDlg4 CENTERED      
  
Return

Static Function AlteraRepSA1()

	cMarca := GetMark()
	
	DBSelectArea("SA1")
	SA1->(DBSetOrder(1))

    SA1->(DBSetFilter( {|| (Empty(AllTrim(A1_OK)) .or. A1_OK == cMarca) .and. A1_VEND == _VendAnt .and. A1_EST == _UF .and. A1_COD_MUN == _Mun }, "(Empty(AllTrim(A1_OK)) .or. A1_OK == cMarca) .and. A1_VEND == _VendAnt   .and. A1_EST == _UF .and. A1_COD_MUN == _Mun" ))
	SA1->(DBGoTop())
	
	// Monta MarkBrow 

	aCampos := {}
           
	AADD(aCampos,{"A1_OK",      "C","",               "@!"})
	AADD(aCampos,{"A1_VEND",    "C","Vendedor",       "@!"})
	AADD(aCampos,{"A1_COD",     "C","Cod",            "@!"})
	AADD(aCampos,{"A1_LOJA",    "C","Loja",           "@!"})
	AADD(aCampos,{"A1_NOME",    "C","Cliente",        "@!"})
	AADD(aCampos,{"A1_COD_MUN", "C","CodMunicipio",   "@!"})

	cMarcados := .F.   
	cCadastro := "Marque as Planilhas e Selecione uma Opcao"
	aRotina := { { "Alterar"		,'ExecBlock("AlteraCliente",.F.,.F.)',0,1} }
              
	cCampo0 := "U_SA1_ALTERA()"
	cCampo1 := "A1_OK"
	cCampo2 := ""      

	MarkBrow("SA1",cCampo1,cCampo2,aCampos,cMarcados,cMarca,cCampo0)
	
	MarcarTitulos(.F.,'  ')  // so pra limpar os registros selecionados, caso nao tenham sido baixados
	SA1->(DBClearFilter())
	
Return


User Function AlteraCliente()
    _nContTit := 0
	SA1->(DBGoTop())

	While !SA1->(EOF())
		If SA1->A1_OK == cMarca
			_nContTit += 1
			SA1->(RecLock("SA1",.F.))
			SA1->A1_VEND := _VendAtu
	        SA1->A1_OK   := '  ' 
			SA1->(MsUnlock())
		EndIf
		SA1->(DBSkip())
	EndDo
	
	// se nenhum item foi selecionado...
	If _nContTit = 0
		MsgBox("Nenhum registro foi selecionado. Selecione pelo menos um para efetuar a alteração.")
		Return(NIL)
	EndIf
	
Return

Static Function MarcarTitulos(_lFecharDialogo, _cMarcador)

	SA1->(DBGoTop())

	While !SA1->(EOF())
		SA1->(RecLock("SA1"))
		SA1->A1_OK := _cMarcador
		SA1->(MSUnlock())                                   
		SA1->(DBSkip())
	EndDo
	
	SA1->(DBGoTop())
	
Return


User Function SA1_ALTERA()

	MarcarTitulos(.F., If(_lSelecionado,'  ', cMarca))
	_lSelecionado := .not. _lSelecionado

Return