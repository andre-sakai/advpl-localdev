#Include "TOTVS.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela da      !
!                  ! rotina de Conciliacao bancaria, utilizado para alterar  !
!                  ! a ordem de apresentacao dos campos                      !
!                  ! 1. Ordena os campos conforme definicao do cliente       !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 08/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function F380CPOS
	// variaveis temporarias
	Local _nX
	// ordem dos campos
	Local _aOrdCampos := {}
	// campos atuais
	Local _aCampos := ParamIxb[1]
	// nova ordem dos campos
	Local _aNewCampos := {}

	// ordem dos campo definida pelo cliente
	_aOrdCampos := {"E5_OK",;
					"E5_FILIAL",;
					"E5_DTDISPO",;
					"E5_RECPAG",;
					"E5_VALOR",;
					"E5_DATA",;
					"E5_BENEF",;
					"E5_HISTOR",;
					"E5_PREFIXO",;
					"E5_NUMERO",;
					"E5_NUMCHEQ",;
					"E5_PARCELA",;
					"E5_TIPO",;
					"E5_DOCUMEN",;
					"E5_MOEDA",;
					"E5_NATUREZ",;
					"E5_CLIFOR",;
					"E5_LOJA"}

	// cria o vetor de retorno com a nova ordem
	For _nX := 1 to Len(_aOrdCampos)
		//retorna campos
		cX3Campo := GetSX3Cache(_aOrdCampos[_nX],"X3_CAMPO")
		cX3Titul := GetSX3Cache(_aOrdCampos[_nX],"X3_TITULO")
		cX3Pictu := GetSX3Cache(_aOrdCampos[_nX],"X3_PICTURE")
		
		If !Empty(cX3Campo)
			// variavel de retorno
			aAdd(_aNewCampos,{cX3Campo,"",cX3Titul,cX3Pictu})
		EndIf
	Next _nX
	
	// adiciona os campos padroes restantes
	For _nX := 1 to Len(_aCampos)
		// verifica se o campos ja esta na ordem
		If (aScan(_aNewCampos,{|x| (AllTrim(x[1])==AllTrim(_aCampos[_nX][1]))}) == 0)
			// variavel de retorno
			aAdd(_aNewCampos,{_aCampos[_nX][1],Nil,_aCampos[_nX][3]})
		EndIf
	Next _nX

Return(_aNewCampos)