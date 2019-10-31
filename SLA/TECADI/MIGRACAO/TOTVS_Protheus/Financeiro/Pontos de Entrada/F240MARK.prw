#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela de      !
!                  ! montagem de bordero de pagamentos para alterar a ordem  !
!                  ! de apresentacao dos campos                              !
!                  ! 1. Ordena os campos conforme definicao do cliente       !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 11/2016 !
+------------------+--------------------------------------------------------*/

User Function F240MARK
	// variaveis temporarias
	Local _nX
	// ordem dos campos
	Local _aOrdCampos := {}
	// campos atuais
	Local _aCampos := ParamIxb
	// nova ordem dos campos
	Local _aNewCampos := {}

	// ordem dos campo definida pelo cliente
	_aOrdCampos := {;
		"E2_OK"     ,;
		"E2_NUM"    ,;
		"E2_PORTADO",;
		"E2_FORNECE",;
		"E2_NOMFOR" ,;
		"E2_VENCREA",;
		"E2_VALOR"  ,;
		"E2_HIST"   ,;
		"E2_CODBAR"  }

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
		If ( aScan(_aNewCampos,{|x| (AllTrim(x[1]) == AllTrim(_aCampos[_nX][1]))} ) == 0)
			// variavel de retorno
			aAdd(_aNewCampos,{_aCampos[_nX][1], Nil, _aCampos[_nX][3], _aCampos[_nX][4]})
		EndIf
	Next _nX

Return(_aNewCampos)