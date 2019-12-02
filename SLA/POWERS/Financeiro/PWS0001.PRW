#Include "protheus.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! STR06A04                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Cadastro e Manutencao de Simulacoes do Fluxo de Caixa   !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 03/03/10                                                !
+------------------+---------------------------------------------------------+
!Arq. Utilizados   ! \FLUXO.SIM                                              !
+------------------+---------------------------------------------------------+
!   ATUALIZACOES                                                             !
+-------------------------------------------+-----------+-----------+--------+
!   Descricao detalhada da atualizacao      !Nome do    ! Analista  !Data da !
!                                           !Solicitante! Respons.  !Atualiz.!
+-------------------------------------------+-----------+-----------+--------+
!                                           !           !           !        !
!                                           !           !           !        !
+-------------------------------------------+-----------+-----------+-------*/

#DEFINE _USADO CHR(0)+CHR(0)+CHR(1)
#DEFINE _CRLF  CHR(13)+CHR(10)

User Function PWS0001()
	// controle do Ok
	Local _nOpca := 0
	// dimensoes da tela
	Local _aSizeDlg := MsAdvSize()
	// arquivo texto com informacoes das simulacoes
	Private _cFileSim	:= "\FLUXO.SIM"
	// variaveis utilizadas no browse
	Private _aColsSim := {}
	Private _aHeadSim := {}
	
	// alimenta os _aColsSim com os dados das simulacoes
	sfMntDados()
	
	// define a tela
	_oDlgSimulacoes := MsDialog():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],"Fluxo de Caixa - Simulação",,,.F.,,,,,,.T.,,,.F.)
	_oDlgSimulacoes:lMaximized := .T.

	// browse com os detalhes da simulacao
	_oBrwSim := MsNewGetDados():New(_aSizeDlg[7],000,_aSizeDlg[6],_aSizeDlg[5],(GD_INSERT+GD_UPDATE+GD_DELETE),'AllwaysTrue()','AllwaysTrue()','',,,Nil,'AllwaysTrue()','','AllwaysTrue()',_oDlgSimulacoes,_aHeadSim,_aColsSim)
	_oBrwSim:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// ativa a tela
	ACTIVATE MSDIALOG _oDlgSimulacoes ON INIT EnchoiceBar(_oDlgSimulacoes,;
														 {||_nOpca:=1,If(_oBrwSim:TudoOk(),_oDlgSimulacoes:End(),_nOpca := 0)},;
														 {||_nOpca:=0,_oDlgSimulacoes:End()} ) CENTER

	// se foi confirmado
	If (_nOpca==1)
		// grava os dados da simulacao
		sfGravaSim()
	EndIf
Return

//** funcao que alimenta o TRB com os dados das simulacoes
Static Function sfMntDados()
	Local _vLinhaTmp := {}

	// Utilizada na simulacao
	_aHeadSim := {}
	Aadd(_aHeadSim,{"Data"       , "_SI_DATA"  , ""	 ,  8, 0, ".T.", _USADO, "D",, "V" } )
	Aadd(_aHeadSim,{"Histórico"  , "_SI_HISTOR", "@!", 40, 0, ".T.", _USADO, "C",, "V" } )
	Aadd(_aHeadSim,{"Rec./Desp." , "_SI_TIPO"  , "@!",  3, 0, ".T.", _USADO, "C",, "V" ,"001=Tit. Receber;002=Tit. Pagar;003=Ped. Compras;004=Ped. Venda"} )
	Aadd(_aHeadSim,{"Valor"      , "_SI_VALOR" , "@E 999,999,999.99", 15, 2, ".T.", _USADO, "N",, "V" } )
	Aadd(_aHeadSim,{"Natureza"   , "_SI_NAT"   , "@!", TamSx3("ED_CODIGO")[1], 0, "ExistCpo('SED')", _USADO, "C","SED", "V" } )
	Aadd(_aHeadSim,{"Cent.Custo" , "_SI_CC"    , "@!", TamSx3("CTT_CUSTO")[1], 0, "ExistCpo('CTT')", _USADO, "C","CTT", "V" } )
	
	// verifica se o arquivo existe
	If File(_cFileSim)
		// abre arquivo de simulacoes
		FT_FUse(_cFileSim)
		FT_FGoTop()
		// varre todas as linhas do arquivo
		While (!FT_FEof())
			// monta o vetor com os dados da linha
			_vLinhaTmp := Separa(FT_FReadln(),"^")
			// alimenta o aCols com os dados
			aAdd(_aColsSim,{CtoD(_vLinhaTmp[1]) ,;	// data
							_vLinhaTmp[2] ,;		// historico
							_vLinhaTmp[3] ,;		// tipo (pag/rec)
							Val(_vLinhaTmp[4]) ,;	// valor
							_vLinhaTmp[5] ,;		// natureza
							_vLinhaTmp[6] ,;		// centro de custo
							.f. })					// deletado
			// proxima linha
			FT_FSkip()
		EndDo
		// Fecha o arquivo
		FT_FUse()
	EndIf
Return

//** funcao que monta o arquivo TXT com os dados da simulacao
Static Function sfGravaSim()
	// conteudo do TXT
	Local _cConteudo := ""
	// linha do _aColsSim
	Local _nLin
	// colunas
	Local _nCol
	
	// joga os dados do objeto para a variavel inicial
	_aColsSim := aClone(_oBrwSim:aCols)
	
	For _nLin := 1 to Len(_aColsSim)
		// verifica se a linha esta deletada
		If (_aColsSim[_nLin][Len(_aHeadSim)+1])
			Loop
		EndIf

		// varre todas as colunas
		For _nCol := 1 to Len(_aHeadSim)
			// data
			If (_aHeadSim[_nCol][ 8]=="D")
				_cConteudo += DtoC(_aColsSim[_nLin][_nCol]) +"^"
			// valor
			ElseIf (_aHeadSim[_nCol][ 8]=="N")
				_cConteudo += Str(_aColsSim[_nLin][_nCol],14,2) +"^"
			// texto
			ElseIf (_aHeadSim[_nCol][ 8]=="C")
				_cConteudo += _aColsSim[_nLin][_nCol] +"^"
			EndIf
		Next _nCol
		// finaliza a linha (ENTER)
		_cConteudo += _CRLF
	Next _nLin
	// gera o arquivo texto
	MemoWrit(_cFileSim,_cConteudo)

Return(.t.)