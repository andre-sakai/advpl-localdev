#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Bot�o para cadastramento de Vendedores. Chamado a partir!
!                  ! da rotina de Cadastro de Cliente.                       !
+------------------+---------------------------------------------------------+
!Retorno           ! L�gico (.t.,.f.)                                        !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 11/2014                                                 !
+------------------+---------------------------------------------------------+
!Autor             ! David Branco                                            !
+------------------+--------------------------------------------------------*/

User Function MA030BUT()
	// Botoes a adicionar
	Local _aBtnCliente := {}

	// Populo o array com o bot�o a ser criado
	AADD(_aBtnCliente,{'Vendedores',{|| U_MA030VEND()},'Vendedores'})
Return (_aBtnCliente)

User Function MA030VEND ()
	// botao
	local _oBtnConf, _oBtnCanc
	// array do browse com os campos de vendedor e comiss�o
	Local _aHeadVend := {}
	Local _aColsVend := sfArrVend() // fun��o que retorna o array
	local _aCampos := {}

	// browse
	private _oBrwVend

	aAdd(_aHeadVend,{"C�digo"       ,"IT_COD"  ,PesqPict("SA1","A1_VEND"),TamSx3("A1_VEND")[1],0,"U_Ft030BUT(_oBrwVend)",Nil,"C","SA3","R",,,".T." })
	aAdd(_aHeadVend,{"Nome Vendedor","IT_NOME" ,"" ,TamSx3("A3_NOME")[1],0,Nil,Nil,"C",Nil,"R",,,".F." })
	aAdd(_aHeadVend,{"Comiss�o"     ,"IT_COMIS",PesqPict("SA1","A1_COMIS"),TamSx3("A1_COMIS")[1],TamSx3("A1_COMIS")[2],Nil,Nil,"N",Nil,"R",,,".T." })

	// janela
	DEFINE DIALOG _oDlgVend TITLE "Vendedores" FROM 180,180 TO 400,700 PIXEL

	// array de campos que podem ser alterados
	_aCampos := {"IT_COD"}

	// browse
	_oBrwVend:= MsNewGetDados():New(000,000,095,264,GD_INSERT + GD_UPDATE + GD_DELETE,'AllwaysTrue()','AllwaysTrue()','',_aCampos,,5,,'AllwaysTrue()','AllwaysTrue()',_oDlgVend,_aHeadVend,_aColsVend)

	// botao confirmar
	_oBtnConf := TButton():New(098, 004, "Confirmar",_oDlgVend,{|| IIF(sfConfComis(_oBrwVend:aCols),_oDlgVend:End(),"") }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	// botao cancelar
	_oBtnCanc := TButton():New(098, 054, "Cancelar",_oDlgVend,{|| _oDlgVend:End() }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	// ativa a janela
	ACTIVATE DIALOG _oDlgVend CENTERED

Return (.t.)

// fun��o pra trazer os vendedores j� cadastrados
Static Function sfArrVend()
	// array que vai receber os dados
	local _aRetVend := {}

	// valida se vendor e comiss�o est�o em branco
	If (! Empty(M->A1_VEND))
		aAdd(_aRetVend,{M->A1_VEND,Posicione("SA3",1,xFilial("SA3")+M->A1_VEND,"A3_NOME"),M->A1_COMIS,.f. })
	EndIf

	// valida se vendor e comiss�o est�o em branco
	If (! Empty(M->A1_ZVEND2))
		aAdd(_aRetVend,{M->A1_ZVEND2,Posicione("SA3",1,xFilial("SA3")+M->A1_ZVEND2,"A3_NOME"),M->A1_ZCOMIS2,.f. })
	EndIf

	// valida se vendor e comiss�o est�o em branco
	If (! Empty(M->A1_ZVEND3))
		aAdd(_aRetVend,{M->A1_ZVEND3,Posicione("SA3",1,xFilial("SA3")+M->A1_ZVEND3,"A3_NOME"),M->A1_ZCOMIS3,.f. })
	EndIf

	// valida se vendor e comiss�o est�o em branco
	If (! Empty(M->A1_ZVEND4))
		aAdd(_aRetVend,{M->A1_ZVEND4,Posicione("SA3",1,xFilial("SA3")+M->A1_ZVEND4,"A3_NOME"),M->A1_ZCOMIS4,.f. })
	EndIf

	// valida se vendor e comiss�o est�o em branco
	If (! Empty(M->A1_ZVEND5))
		aAdd(_aRetVend,{M->A1_ZVEND5,Posicione("SA3",1,xFilial("SA3")+M->A1_ZVEND5,"A3_NOME"),M->A1_ZCOMIS5,.f. })
	EndIf

	// retorno do vetor
Return _aRetVend

Static Function sfConfComis(mvArrBrowse)
	//retorno
	local _lRet 	  := .t.
	local _lErroComis := .f.
	//controle for
	local _nX   	  := 0
	//len do array
	local _nLenArray  := Len(mvArrBrowse)
	//controle de altera��s
	local _nCon       := 1
	// total por cargo e codigos de vendedor
	local _cTodVen    := ""
	local _nTotVen    := 0
	local _cTodGer    := ""
	local _nTotGer    := 0
	local _cTodDir    := ""
	local _nTotDir    := 0
	local _cTodEmp    := ""
	local _nTotEmp    := 0
	local _cCargoVen  := ""
	// variaveis temporaria para comparacao
	local _nComNew := 0 // comiss�o informada pelo usu�rio
	local _nComOK  := 0 // comiss�o correta

	// valido se as comiss�es s�o devidas
	If (_nLenArray >= 1)
		// for para identificar os cargos
		For _nX := 1 to _nLenArray
			// jogo o cargo numa variavel para compara��o
			_cCargoVen := Posicione("SA3",1,xFilial("SA3")+mvArrBrowse[_nX][1],"A3_CARGO")

			If (_cCargoVen == "000001").And.( ! mvArrBrowse[_nX][4])// vendedores - removido valida��o pois foi tratado diretamente pela aplica��o
				// incluo vendedor e valido se foi duplicado
				_cTodVen += CVALTOCHAR(mvArrBrowse[_nX][1]) + "/"
				_nTotVen++
			ElseIf (_cCargoVen == "000002").And.( ! mvArrBrowse[_nX][4]) // diretoria
				// incluo diretor
				_cTodDir += CVALTOCHAR(mvArrBrowse[_nX][1]) + "/"
				_nTotDir++
			ElseIf (_cCargoVen == "000003").And.( ! mvArrBrowse[_nX][4]) // gerencia
				// incluo gerente
				_cTodGer += CVALTOCHAR(mvArrBrowse[_nX][1]) + "/"
				_nTotGer++
			ElseIf (_cCargoVen == "000004").And.( ! mvArrBrowse[_nX][4]) // empresa
				// incluo empresa no array
				_cTodEmp += CVALTOCHAR(mvArrBrowse[_nX][1]) + "/"
				_nTotEmp++
			EndIf

		Next _nX

		// valido a quantidade de gerente para ver se a comiss�o est� correta
		If (_nTotVen >= 2).And.(_lRet)
			// mostra a mensagem pro usu�rio caso os valores estejam divergentes
			_lRet := MsgYesNo("H� mais de um vendedor para esse cliente. O sistema ir� dividir as comiss�es. Deseja Prosseguir?")
		EndIf

		// valido a quantidade de gerente para ver se a comiss�o est� correta
		If (_nTotGer >= 2).And.(_lRet)
			// verifico os registros no array
			For _nX := 1 to _nLenArray
				// se encontrou os vendedores vai analisar os valores
				If (mvArrBrowse[_nX][1] $ _cTodGer).And.(mvArrBrowse[_nX][4] == .f.)
					_nComNew := mvArrBrowse[_nX][3] // novos valores
					_nComOK  := (Posicione("SA3",1,xFilial("SA3")+mvArrBrowse[_nX][1],"A3_COMIS") / _nTotGer) // valores SA3

					// se a nova comiss�o for maior que a divis�o da comiss�o do vendedor pela quantidade de vendedores n�o deixa prosseguir
					If (round(_nComNew,2) != round(_nComOK,2))
						_lErroComis := .t.
					EndIf

				EndIf
			Next _nX

			// mostra a mensagem pro usu�rio caso os valores estejam divergentes
			If (_lErroComis)
				MsgStop("H� mais de um gerente para esse cliente. Favor dividir corretamente a comiss�o.")
				_lRet := .f.
			EndIf

		EndIf

		// valido a quantidade de diretores para ver se a comiss�o est� correta
		If (_nTotDir >= 2).And.(_lRet)
			// verifico os registros no array
			For _nX := 1 to _nLenArray
				// se encontrou os vendedores vai analisar os valores
				If (mvArrBrowse[_nX][1] $ _cTodDir).And.(mvArrBrowse[_nX][4] == .f.)
					_nComNew := mvArrBrowse[_nX][3] // novos valores
					_nComOK  := (Posicione("SA3",1,xFilial("SA3")+mvArrBrowse[_nX][1],"A3_COMIS") / _nTotDir) // valores SA3

					// se a nova comiss�o for maior que a divis�o da comiss�o do vendedor pela quantidade de vendedores n�o deixa prosseguir
					If (round(_nComNew,2) != round(_nComOK,2))
						_lErroComis := .t.
					EndIf

				EndIf
			Next _nX

			// mostra a mensagem pro usu�rio caso os valores estejam divergentes
			If (_lErroComis)
				MsgStop("H� mais de um diretor para esse cliente. Favor dividir corretamente a comiss�o.")
				_lRet := .f.
			EndIf

		EndIf

		// valido a quantidade de empresas para ver se a comiss�o est� correta
		If (_nTotEmp >= 2).And.(_lRet)
			// verifico os registros no array
			For _nX := 1 to _nLenArray
				// se encontrou os vendedores vai analisar os valores
				If (mvArrBrowse[_nX][1] $ _cTodEmp).And.(mvArrBrowse[_nX][4] == .f.)
					_nCompNew := mvArrBrowse[_nX][3] // novos valores
					_nCompOld := (Posicione("SA3",1,xFilial("SA3")+mvArrBrowse[_nX][1],"A3_COMIS") / _nTotEmp) // valores SA3

					// se a nova comiss�o for maior que a divis�o da comiss�o do vendedor pela quantidade de vendedores n�o deixa prosseguir
					If (round(_nComNew,2) != round(_nComOK,2))
						_lErroComis := .t.
					EndIf

				EndIf
			Next _nX

			// mostra a mensagem pro usu�rio caso os valores estejam divergentes
			If (_lErroComis)
				MsgStop("H� mais de uma empresa para esse cliente. Favor dividir corretamente a comiss�o.")
				_lRet := .f.
			EndIf

		EndIf

	EndIf

	// valida as comiss�es
	sfSplitComis()

	//varro o array pra verificar se tiveram altera��o
	If (_lRet)
		BEGIN TRANSACTION
			// zero as variaveis para receber os novos valores
			M->A1_VEND    := ""
			M->A1_COMIS   := 0
			M->A1_ZVEND2  := ""
			M->A1_ZCOMIS2 := 0
			M->A1_ZVEND3  := ""
			M->A1_ZCOMIS3 := 0
			M->A1_ZVEND4  := ""
			M->A1_ZCOMIS4 := 0
			M->A1_ZVEND5  := ""
			M->A1_ZCOMIS5 := 0

			// varro o array pra inserir os registros
			For _nX := 1 to _nLenArray
				// se o registro n�o estiver deletado grava as altera��es
				If (mvArrBrowse[_nX][4] == .f.)
					If (_nCon == 1)
						M->A1_VEND    := mvArrBrowse[_nX][1]
						M->A1_COMIS   := mvArrBrowse[_nX][3]
					ElseIf (_nCon == 2)
						M->A1_ZVEND2  := mvArrBrowse[_nX][1]
						M->A1_ZCOMIS2 := mvArrBrowse[_nX][3]
					ElseIf (_nCon == 3)
						M->A1_ZVEND3  := mvArrBrowse[_nX][1]
						M->A1_ZCOMIS3 := mvArrBrowse[_nX][3]
					ElseIf (_nCon == 4)
						M->A1_ZVEND4  := mvArrBrowse[_nX][1]
						M->A1_ZCOMIS4 := mvArrBrowse[_nX][3]
					ElseIf (_nCon == 5)
						M->A1_ZVEND5  := mvArrBrowse[_nX][1]
						M->A1_ZCOMIS5 := mvArrBrowse[_nX][3]
					EndIF
					// controlo as altera��es
					_nCon++
				EndIf

			Next _nX

		END TRANSACTION
	EndIf

Return _lRet

User Function Ft030BUT(mvBrwVend)
	// variavel de retorno
	local _lRet := .t.
	// controle do for
	local _nX   := 0

	// valido se o registro j� est� inserido no array para n�o duplicar
	For _nX := 1 to len(mvBrwVend:aCols)
		// se o array j� contem o n�mero do c�digo informado, ele mostra erro pro usu�rio
		If (mvBrwVend:aCols[_nX][1] == M->IT_COD).And.(mvBrwVend:aCols[_nX][4] == .f.)
			MsgStop("Vendedor j� informado para esse cliente. Verifique!")
			// variavel de retorno
			_lRet := .f.
			// sai do loop
			EXIT
		EndIf
	Next _nX

	// busco o registro do nome do vendedor
	If (_lRet)
		DbSelectArea("SA3")
		DbSetOrder(1) // filial+codigo
		If (SA3->(DbSeek(xFilial("SA3")+M->IT_COD)))
			// preencho o nome do vendedor no browse
			mvBrwVend:aCols[mvBrwVend:nAt][2] := SA3->A3_NOME
			// preencho a comiss�o do vendedor
			mvBrwVend:aCols[mvBrwVend:nAt][3] := SA3->A3_COMIS
			// caso n�o existe o c�digo informado
		Else
			MsgStop("N�o existe vendedor para o c�digo informado!")
			// variavel de retorno
			_lRet := .f.
		EndIf
	EndIf

	// atualizacao do browse
	If (mvBrwVend <> nil)
		mvBrwVend:oBrowse:Refresh()
	EndIf

Return _lRet

Static Function sfSplitComis()

	//controle for
	local _nX    := 0
	//len do array
	local _aVld  := {}
	// total por cargo e codigos de vendedor
	local _cTodVen    := ""
	local _nTotVen    := 0
	// variaveis temporaria para comparacao
	local _cCargoVen := ""
	local _nComPad   := 0

	// for para identificar os cargos
	For _nX := 1 to Len(_oBrwVend:aCols)
		// jogo o cargo numa variavel para compara��o
		_cCargoVen := Posicione("SA3",1,xFilial("SA3")+_oBrwVend:aCols[_nX][1],"A3_CARGO")
		// vendedores
		If (_cCargoVen == "000001").And.( ! _oBrwVend:aCols[_nX][4])
			_nTotVen++
		EndIf
	Next _nX

	If (_nTotVen > 0)
		For _nX := 1 to Len(_oBrwVend:aCols)
			// jogo o cargo numa variavel para compara��o
			_cCargoVen := Posicione("SA3",1,xFilial("SA3")+_oBrwVend:aCols[_nX][1],"A3_CARGO")
			_nComPad := Posicione("SA3",1,xFilial("SA3")+_oBrwVend:aCols[_nX][1],"A3_COMIS")
			// vendedores
			If (_cCargoVen == "000001").And.( ! _oBrwVend:aCols[_nX][4])
				_oBrwVend:aCols[_nX][3] := round(_nComPad / _nTotVen,2)
			EndIf
		Next _nX
	EndIf

Return .T.
