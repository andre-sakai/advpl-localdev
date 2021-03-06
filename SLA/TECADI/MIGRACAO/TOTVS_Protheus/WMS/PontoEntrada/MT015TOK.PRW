#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada no cadastro de enderecos               !
!                  ! - validacao ao alterar o produto padr�o do endere�o     !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 09/2015 !
+------------------+--------------------------------------------------------*/

User Function MT015TOK

	// variavel de retorno. ela est� sem defini��o de tipo para manter padr�o da rotina
	local _lRet
	
	// vari�vel que recebe o par�metro da rotina padr�o
	local _nOpc := ParamIxb[1]

	// vari�vel para guardar o retorno da OS de invent�rio
	local _cOSInv := CriaVar("Z05_NUMOS",.F.) 

	// se estiver alterando
	If	( _nOpc == 4 )

		// verifica se o endere�o est� sob invent�rio
		If ( U_FTEndInv(SBE->BE_LOCALIZ, SBE->BE_LOCAL, @_cOSInv) )
			U_FtWmsMsg("O endere�o est� em processo de invent�rio na OS " + _cOSInv + ". A opera��o n�o pode ser realizada!")
			_lRet := .F.
		EndIf

		//valida se existe saldo no endere�o
		IF  (_lRet) .AND. (SBE->BE_CODPRO <> FwFldGet("BE_CODPRO"))
			// caso a rotina padr�o retorne que h� saldo no endere�o
			If	FindFunction("WmsChkSBE") .And. WmsChkSBE(SBE->BE_LOCAL,NIL,NIL,SBE->BE_ESTFIS,NIL,NIL,NIL,Nil,NIL,,SBE->BE_LOCALIZ)
				// avisa o usu�rio e n�o deixa prosseguir
				Aviso("Saldo no Endere�o","O endere�o possui saldo. N�o � permitido alterar o Produto Padr�o!",{"Ok"})
				// variavel de retorno
				_lRet := .F.
			EndIf
		EndIF
	EndIf

Return(_lRet)