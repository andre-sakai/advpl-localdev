#include "protheus.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Relatório de Detalhes de Contratos                      !
+------------------+---------------------------------------------------------+
!Autor             ! David Branco                                            !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 07/2016                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSR026()
	Private _aPergs      := {}
	Private _cRetSX1	 := ""
	Private TITULO		:= "Relatório de Detalhes de Contrato de Serviços"
	Private nomeprog	:= FunName()
	Private _oReport
	// valida se pode mostrar os valores da tarifa
	private _lMosTar  := .T.

	// definição dos dados do relatório
	_oReport := sfReportDef()

	If Valtype( _oReport ) == 'O'
		If !Empty( _oReport:uParam )
			Pergunte( _oReport:uParam, .F. )
		EndIf

		_oReport:PrintDialog()
	EndIf

	_oReport := Nil

Return

// ** função de definição de informações do relatório ** //
Static Function sfReportDef()
	Local _aArea	   	:= GetArea()
	Local _cReport		:= FunName()
	Local _cDesc		:= "Este programa irá imprimir o relatorio de contrato de serviços"
	Local _cPerg		:= PadR("TWMSR026",10)
	Local _aPerg		:= {}
	Local _lRet		 	:= .T.
	Local _cItem        := ""
	Local _cCodProd     := ""
	Local _nQuant       := 0
	Local _nVlrUnit     := 0
	Local _nVlrTot      := 0
	Local _cUM          := ""

	// extrai as informacoes do usuario logado
	local _aUsrInfo := U_FtWmsFil()

	// monta a lista de perguntas
	aAdd(_aPerg,{"Cliente De ?"          ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"})     //mv_par01
	aAdd(_aPerg,{"Cliente Até ?"         ,"C",TamSx3("A1_COD")[1],0,"G",,"SA1"})     //mv_par02
	aAdd(_aPerg,{"Loja De ?"             ,"C",TamSx3("A1_LOJA")[1],0,"G",,"SA1"})    //mv_par03
	aAdd(_aPerg,{"Loja Até ?"            ,"C",TamSx3("A1_LOJA")[1],0,"G",,"SA1"})    //mv_par04
	aAdd(_aPerg,{"Contrato De ?"         ,"C",TamSx3("AAM_CONTRT")[1],0,"G",,"AAM"}) //mv_par05
	aAdd(_aPerg,{"Contrato Até ?"        ,"C",TamSx3("AAM_CONTRT")[1],0,"G",,"AAM"}) //mv_par06
	aAdd(_aPerg,{"Status"                ,"N",1,0,"C",{"Ativo","Suspenso","Encerrado","Cancelado","Todos"},""}) //mv_par07
	aAdd(_aPerg,{"Mostra Detalhes?"      ,"N",1,0,"C",{"Sim","Não"},""})             //mv_par08
	aAdd(_aPerg,{"Produto (Serviço) De?" ,"C",TamSx3("B1_COD")[1],0,"G",,"SB1"})     //mv_par09
	aAdd(_aPerg,{"Produto (Serviço) Até?","C",TamSx3("B1_COD")[1],0,"G",,"SB1"})     //mv_par10

	// cria o grupo de perguntas
	U_FtCriaSX1(_cPerg, _aPerg)

	// só mostra a info quando for do faturamento/financeiro/comercial
	If ( _aUsrInfo[2] != "S" )
		// somente status ativo
		mv_par07 := 2
		// não mostra tarifa
		_lMosTar := .f.
	EndIf

	_oReport	:= TReport():New( _cReport, TITULO, _cPerg, { |_oReport| sfReportPrint( _oReport ) }, _cDesc )
	_oReport:SetTotalInLine( .F. )
	_oReport:EndPage( .T. )
	_oReport:SetPortrait( .T. )

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Criacao da secao utilizada pelo relatorio                               ³
	//³                                                                        ³
	//³TRSection():New                                                         ³
	//³ExpO1 : Objeto TReport que a secao pertence                             ³
	//³ExpC2 : Descricao da seçao                                              ³
	//³ExpA3 : Array com as tabelas utilizadas pela secao. A primeira tabela   ³
	//³        sera considerada como principal para a seção.                   ³
	//³ExpA4 : Array com as Ordens do relatório                                ³
	//³ExpL5 : Carrega campos do SX3 como celulas                              ³
	//³        Default : False                                                 ³
	//³ExpL6 : Carrega ordens do Sindex                                        ³
	//³        Default : False                                                 ³
	//³                                                                        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	_oSection1  := TRSection():New( _oReport, "Contrato", {"AAM","AAN"},,.F.,.F.,,,,,,,,,,.F./*AutoAjuste*/,)   //"Contrato"
	TRCell():New( _oSection1, "AAM_CONTRT"           ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/{ || AAM_CONTRT } )
	TRCell():New( _oSection1, "AAM_TITULO"           ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/{ || AAM_TITULO } )
	TRCell():New( _oSection1, "AAM_CODCLI"           ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/{ || AAM_CODCLI } )
	TRCell():New( _oSection1, "AAM_LOJA"             ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/{ || AAM_LOJA   } )
	TRCell():New( _oSection1, "A1_NOME"              ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/{ || A1_NOME    } )
	TRCell():New( _oSection1, "AAM_STATUS"           ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/ )
	TRCell():New( _oSection1, "AAM_INIVIG"           ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/{ || StoD( AAM_INIVIG ) } )
	TRCell():New( _oSection1, "AAM_FIMVIG"           ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/{ || StoD( AAM_FIMVIG ) } )
	TRCell():New( _oSection1, "A3_NOME"              ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/{ || sfRetVend(AAM_CODCLI, AAM_LOJA) } )

	_oSection2  := TRSection():New( _oReport, "Itens", {"AAM","AAN"},,.F.,.F.,,,,,,,,,,.F./*AutoAjuste*/,)   //"Itens"
	TRCell():New( _oSection2, "AAN_ITEM"             ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/ )
	TRCell():New( _oSection2, "AAN_CODPRO"           ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/ )
	TRCell():New( _oSection2, "B1_DESC"              ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/ )
	TRCell():New( _oSection2, "AAN_QUANT"            ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/ )
	TRCell():New( _oSection2, "B1_UM"                ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/ )

	// validação para mostrar ou não a tarifa
	If ( _lMosTar )
		TRCell():New( _oSection2, "AAN_VLRUNI"           ,,,/*Picture*/,, /*lPixel*/, /*CodeBlock*/ )
	EndIf

Return _oReport

// ** função que carrega dados do relatório ** //
Static Function sfReportPrint( _oReport )

	Local _cContrt		:= ""
	Local _cOldContrt	:= ""
	Local _cStatus		:= ""
	Local _oSection1 	:= _oReport:Section( 1 )
	Local _oSection2 	:= _oReport:Section( 2 )
	Local _aGetArea     := {}
	Local _cSeekSZU     := ""
	Local _aGetAtiv     := {}
	Local _nX           := 0

	Private _cItem      := ""
	Private _cCodProd   := ""
	Private _nQuant     := 0
	Private _nVlrUnit   := 0
	Private _cLogQRY	:= {}

	_cAliasQry := GetNextAlias()
	If Select( _cAliasQry ) > 0
		DbSelectArea( _cAliasQry )
		dbCloseArea()
	EndIf

	BeginSql Alias _cAliasQry

		SELECT *
		FROM %table:AAM% AAM
		LEFT JOIN %table:SA1% SA1 ON A1_FILIAL = %xfilial:SA1%
		AND A1_COD = AAM_CODCLI
		AND A1_LOJA = AAM_LOJA AND SA1.%notDel%
		WHERE 	AAM.%notDel% AND
		AAM.AAM_FILIAL = %XFILIAL:AAM% AND
		AAM.AAM_CODCLI BETWEEN %EXP:MV_PAR01% AND %EXP:MV_PAR02% AND
		AAM.AAM_LOJA BETWEEN   %EXP:MV_PAR03% AND %EXP:MV_PAR04% AND
		AAM.AAM_CONTRT BETWEEN %EXP:MV_PAR05% AND %EXP:MV_PAR06%
		ORDER BY AAM_CONTRT, AAM_CODCLI, AAM_LOJA

	EndSql

	//pega a query gerada
	_cLogQRY := GetLastQuery()

	//grava log da query para debug
	MemoWrit("c:\query\TWMSR026_sfReportPrint.txt",_cLogQRY[2])


	DbGoTop()
	DbSelectArea( _cAliasQry )

	_oReport:SetMeter( RecCount() )

	While (_cAliasQry)->( !Eof() )
		If _oReport:Cancel()
			Exit
		EndIf

		// Filtra o Status
		// MV_PÀR07 --> 1- "Ativo", 2- "Suspenso", 3- "Encerrado", 4- "Cancelado", 5-"Todos"

		//se não for filtro "todos" (5), puxa somente o selecionado no MV_PAR07
		If ( MV_PAR07 != 5 .AND. Val( (_cAliasQry)->AAM_STATUS ) != MV_PAR07)
			_oReport:IncMeter()
			(_cAliasQry)->( DbSkip() )
			Loop
		EndIf

		// Reescreve o status
		_cStatus := ""
		If (_cAliasQry)->AAM_STATUS == "1"
			_cStatus	:= "Ativo"
		ElseIf (_cAliasQry)->AAM_STATUS == "2"
			_cStatus := "Suspenso"
		ElseIf (_cAliasQry)->AAM_STATUS == "3"
			_cStatus := "Encerrado"
		ElseIf (_cAliasQry)->AAM_STATUS == "4"
			_cStatus := "Cancelado"
		EndIf

		_oSection1:Cell( "AAM_STATUS" ):SetBlock( { || _cStatus } )

		// Inicia as sessoes e imprime os registros
		_oSection1:Init()
		_oSection2:Init()

		_cContrt := (_cAliasQry)->AAM_CONTRT
		If _cContrt <> _cOldContrt
			_oSection1:PrintLine()
			_cOldContrt := _cContrt
		EndIf

		// mostra ou não mostra detalhes
		If ( MV_PAR08 == 1 )
			// Imprime sessao 2
			DbSelectArea( "AAN" )
			AAN->( DbSetOrder( 1 ) )
			AAN->( DbSeek( xFilial( "AAN" ) + (_cAliasQry)->AAM_CONTRT ) )
			While AAN->( !Eof() ) .AND. AAN->AAN_CONTRT == (_cAliasQry)->AAM_CONTRT

				// filtra codigo do produto/servico
				If (AAN->AAN_CODPRO < mv_par09).or.(AAN->AAN_CODPRO > mv_par10)
					// proximo item
					AAN->( DbSkip() )
					// loop
					Loop
				EndIf

				// define valor das variáveis antes de imprimir
				_cItem        := AAN->AAN_ITEM
				_cCodProd     := AAN->AAN_CODPRO
				_cDescric     := Iif( ! Empty(AllTrim(AAN_ZDESCR)), AllTrim(AAN_ZDESCR), AllTrim(sfGetDProd(_cCodProd))) + ;
								sfRetTpArm ( AAN->AAN_TIPOAR) + ;
								sfRetTpEsto ( (_cAliasQry)->AAM_CODCLI, AAN_ZGRPES )
				_cUM          := sfGetUMProd(_cCodProd)
				_nQuant       := AAN->AAN_QUANT
				_nVlrUnit     := AAN->AAN_VLRUNI

				_oSection2:Cell( "AAN_ITEM"   ):SetBlock( { || _cItem                        } )
				_oSection2:Cell( "AAN_CODPRO" ):SetBlock( { || AllTrim(_cCodProd)            } )
				_oSection2:Cell( "B1_DESC"    ):SetBlock( { || _cDescric                     } )
				_oSection2:Cell( "B1_UM"      ):SetBlock( { || _cUM                          } )
				_oSection2:Cell( "AAN_QUANT"  ):SetBlock( { || _nQuant                       } )

				// validação para mostrar ou não a tarifa
				If ( _lMosTar )
					_oSection2:Cell( "AAN_VLRUNI" ):SetBlock( { || _nVlrUnit                     } )
				EndIf

				_oSection2:PrintLine()

				// somente quando for pacote de serviços
				If ( AllTrim(_cCodProd) == "9000007" )

					// recebe as atividades por produto
					_aGetAtiv := sfRetGetAtiv(_cCodProd, AAN->AAN_CONTRT, AAN->AAN_ITEM, _oSection2, _lMosTar)
				EndIf

				// detalha os serviços caso tenha detalhes
				If ( AllTrim(_cCodProd) $ "9000006|9000010|9000011" )
					dbSelectArea("SZU")
					SZU->( dbSetOrder(1) ) //ZU_FILIAL, ZU_CONTRT, ZU_ITCONTR, ZU_PRODUTO, R_E_C_N_O_, D_E_L_E_T_
					SZU->( dbSeek( _cSeekSZU := xFilial("SZU") + AAN->AAN_CONTRT + AAN->AAN_ITEM ) )
					While SZU->( !Eof() ) .and. ( SZU->(ZU_FILIAL+ZU_CONTRT+ZU_ITCONTR) == _cSeekSZU )
						// define os itens encontrados
						_cItem        := " - "
						_cCodProd     := SZU->ZU_PRODUTO
						_nQuant       := 0
						_nVlrUnit     := 0

						// grava os dado
						_oSection2:Cell( "AAN_ITEM"   ):SetBlock( { || _cItem                    } )
						_oSection2:Cell( "AAN_CODPRO" ):SetBlock( { || AllTrim(_cCodProd)        } )
						_oSection2:Cell( "B1_DESC"    ):SetBlock( { || sfGetDProd(_cCodProd)     } )
						_oSection2:Cell( "B1_UM"      ):SetBlock( { || sfGetUMProd(_cCodProd)    } )
						_oSection2:Cell( "AAN_QUANT"  ):SetBlock( { || _nQuant                   } )

						// validação para mostrar ou não a tarifa
						If ( _lMosTar )
							_oSection2:Cell( "AAN_VLRUNI" ):SetBlock( { || _nVlrUnit                 } )
						EndIf
						// imprime a linha
						_oSection2:PrintLine()

						// somente quando for pacote de serviços
						If ( AllTrim(_cCodProd) == "9000007" )

							// recebe as atividades por produto
							_aGetAtiv := sfRetGetAtiv(_cCodProd, AAN->AAN_CONTRT, AAN->AAN_ITEM, _oSection2, _lMosTar)
						EndIf
					SZU->( dbSkip() )
					End

				EndIf

				// proximo item
				AAN->( DbSkip() )
			EndDo

		EndIf

		// Restaura a area para impressao da sessao 1
		DbSelectArea( _cAliasQry )

		_oReport:IncMeter()
		(_cAliasQry)->( DbSkip() )

		// Pula linha para proximo registro e atualiza a regua
		If (_cAliasQry)->AAM_CONTRT <> _cOldContrt
			_oReport:SkipLine( 2 )

			_oSection1:Finish()
			_oSection2:Finish()
		EndIf
	End

Return

// ** função que retorna os dados do produto ** //
Static Function sfGetDProd( _cCodigo )
	Local _aArea	:= GetArea()
	Local _cRet	    := ""

	DbSelectArea( "SB1" )
	SB1->( DbSetOrder( 1 ) )
	If SB1->( DbSeek( xFilial( "SB1" ) + _cCodigo ) )
		_cRet := SB1->B1_DESC
	EndIf

	RestArea( _aArea )

Return _cRet

// ** função que retorna os dados do produto ** //
Static Function sfGetUMProd( _cCodigo )
	Local _aArea	:= GetArea()
	Local _cRet	    := ""

	DbSelectArea( "SB1" )
	SB1->( DbSetOrder( 1 ) )
	If SB1->( DbSeek( xFilial( "SB1" ) + _cCodigo ) )
		_cRet  := SB1->B1_UM
	EndIf

	RestArea( _aArea )

Return _cRet

// ** função que retorna atividades por contrato e item ** //
Static Function sfRetGetAtiv ( mvCodProd, mvCont, mvItCont, mvSection, mvMosTar )

	// definição de variáveis
	local _aAtiv   := {}
	local _cQuery  := ""

	_cQuery := " SELECT DISTINCT Z9_ITEM, "
	_cQuery += "                 Z9_CODATIV, "
	_cQuery += "                 ZT_DESCRIC, "
	_cQuery += "                 Z9_VALOR, "
	_cQuery += "                 Z9_UNIDCOB "
	_cQuery += " FROM  " + RetSqlTab("SZ9")
	_cQuery += "       INNER JOIN " + RetSqlTab("SZT")
	_cQuery += "               ON ZT_CODIGO = Z9_CODATIV AND " + RetSqlCond("SZT")
	_cQuery += "       WHERE " + RetSqlCond("SZ9")
	_cQuery += "         AND Z9_CONTRAT = '" + mvCont + " '
	_cQuery += "         AND Z9_ITEM = '" + mvItCont + "'
	_cQuery += " ORDER  BY 2"

	// info para debug
	memowrit("C:\query\TWMSR026_sfretgetativ.txt", _cQuery)
	// jogo os dados pro array
	_aAtiv := U_SqlToVet(_cQuery)

	// somente quando for pacote de serviços
	If ( AllTrim(mvCodProd) == "9000007" )

		// se encontrou dados, inclui os registros
		If ( len(_aAtiv) > 0)
			// inclui todos os registros encontrados
			For _nX := 1 to len(_aAtiv)

				// definição das informações
				_cItem        := " - "
				_cCodProd     := " - "
				_nQuant       := 0
				_nVlrUnit     := _aAtiv[_nX][4]

				// grava os dado
				mvSection:Cell( "AAN_ITEM"   ):SetBlock( { || _cItem                                             } )
				mvSection:Cell( "AAN_CODPRO" ):SetBlock( { || _cCodProd                                          } )
				mvSection:Cell( "B1_DESC"    ):SetBlock( { || _aAtiv[_nX][2] +  " - " + AllTrim(_aAtiv[_nX][3])  } )
				mvSection:Cell( "B1_UM"      ):SetBlock( { || AllTrim(_aAtiv[_nX][5])                            } )
				mvSection:Cell( "AAN_QUANT"  ):SetBlock( { || _nQuant                                            } )

				// validação para mostrar ou não a tarifa
				If ( mvMosTar )
					mvSection:Cell( "AAN_VLRUNI" ):SetBlock( { || _nVlrUnit                                      } )
				EndIf

				// imprime a linha
				mvSection:PrintLine()
			Next _nX
		EndIf
	EndIf

Return

// ** função que retorna os vendedores por cliente ** //
Static Function sfRetVend( mvCodCli, mvLoja )

	Local _cRet    := ""
	Local _cQuery  := ""
	Local _aRetQry := {}
	Local _nX      := 0

	// definição de vendedores por cliente
	_cQuery := " SELECT A1_VEND, A1_ZVEND2, A1_ZVEND3, A1_ZVEND4, A1_ZVEND5 "
	_cQuery += " FROM " + RetSqlTab("SA1")
	_cQuery += " WHERE A1_COD = '" + mvCodCli + "'
	_cQuery += " AND A1_LOJA = '" + mvLoja + "' "

	memowrit("C:\query\twmsr026_sfretvend.txt", _cQuery)

	_aRetQry := U_SqlToVet(_cQuery)

	If ( len(_aRetQry) > 0 )
		For _nX := 1 to 5
			If ( ! Empty(_aRetQry[1][_nX]))
				_cRet += AllTrim(Posicione("SA3", 1, xFilial("SA3")+_aRetQry[1][_nX], "A3_NOME")) + " / "
			EndIf
		Next _nX
	EndIf

	_cRet := Substr(AllTrim(_cRet), 1, Len(AllTrim(_cRet))-1)

Return _cRet

// ** função que retorna o tipo de armazenagem ** //
Static Function sfRetTpArm ( mvTipo )

	Local _cRet := ""

	Do Case
	Case mvTipo == "1"
		_cRet := " - Cubagem"
	Case mvTipo == "2"
		_cRet := " - Peso Bruto"
	Case mvTipo == "3"
		_cRet := " - Posição Pallet"
	Case mvTipo == "4"
		_cRet := " - Unitário"
	Case mvTipo == "5"
		_cRet := " - Peso Líquido"
	OtherWise
		_cRet := ""
	EndCase

Return _cRet

// ** função que retorna o tipo de estoque ** //
Static Function sfRetTpEsto ( mvCodCli, mvTipo )

	Local _aArea	:= GetArea()
	Local _cRet	    := ""
	Local _cSigla   := ""

	DbSelectArea( "SA1" )
	SA1->( DbSetOrder( 1 ) )
	If SA1->( DbSeek( xFilial( "SA1" ) + mvCodCli ) )
		_cSigla  := SA1->A1_SIGLA
	EndIf

	DbSelectArea("Z36")
	Z36->( dbSetOrder(1))
	If ( Z36->( dbSeek( xFilial("Z36") + _cSigla + mvTipo)) )
		_cRet := " - " + Z36->Z36_DESCRI
	EndIf

	RestArea( _aArea )

Return _cRet

