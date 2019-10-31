#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada na rotina de copia de pedidos de venda !
!                  ! - utilizado para zerar conteudo de campos customizados  !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 03/2017 !
+------------------+--------------------------------------------------------*/

User Function MT410CPY()

	// relacao dos campos para zerar conteudo
	local _aCampos := {"C5_ZCHVNFV", "C5_ZEMINFV", "C5_ZCARREG", "C5_ZMNTVOL",; 
	"C5_ZENDENT", "C5_ZUFENTR", "C5_ZCIDENT", "C5_ZCLIENT", "C5_ZAGRUPA",;
	"C5_ZCARGA",  "C5_ZSEQCAR", "C5_ZSEQENT", "C5_ZPEDCLI", "C5_ZDOCCLI",;
	"C5_ZNFVVLR", "C5_ZNUMSOL", "C5_ZNOSSEP", "C5_ZDOSSEP", "C5_ZHOSSEP",;
	"C5_ZNOSMNT", "C5_ZDOSMNT", "C5_ZHOSMNT", "C5_ZNOSEXP", "C5_ZDOSEXP",;
	"C5_ZHOSEXP", "C5_ZONDSEP", "C5_ZSEQOND", "C5_ZHRINCL",;
	"C5_ZORIGEM", "C5_ZCGCENT"}

	// variaveis temporarias
	local _nCmp
	local _cTmpCampo

	// varre todos os campos do array
	For _nCmp := 1 to Len(_aCampos)
		// nome do campo
		_cTmpCampo := _aCampos[_nCmp]

		// verifica se o campo existe na tabela
		If (SC5->(FieldPos(_cTmpCampo)) > 0)
			// pega o campo com o conteudo em memória
			//cria uma variavel em branco com os mesmo atributos e atribui
			M->(&(_cTmpCampo)) := CriaVar(_cTmpCampo, .t.)
		EndIf

	Next _nCmp

Return