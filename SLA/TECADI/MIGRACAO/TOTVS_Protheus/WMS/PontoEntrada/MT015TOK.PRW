#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada no cadastro de enderecos               !
!                  ! - validacao ao alterar o produto padrão do endereço     !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 09/2015 !
+------------------+--------------------------------------------------------*/

User Function MT015TOK

	// variavel de retorno. ela está sem definição de tipo para manter padrão da rotina
	local _lRet
	
	// variável que recebe o parâmetro da rotina padrão
	local _nOpc := ParamIxb[1]

	// variável para guardar o retorno da OS de inventário
	local _cOSInv := CriaVar("Z05_NUMOS",.F.) 

	// se estiver alterando
	If	( _nOpc == 4 )

		// verifica se o endereço está sob inventário
		If ( U_FTEndInv(SBE->BE_LOCALIZ, SBE->BE_LOCAL, @_cOSInv) )
			U_FtWmsMsg("O endereço está em processo de inventário na OS " + _cOSInv + ". A operação não pode ser realizada!")
			_lRet := .F.
		EndIf

		//valida se existe saldo no endereço
		IF  (_lRet) .AND. (SBE->BE_CODPRO <> FwFldGet("BE_CODPRO"))
			// caso a rotina padrão retorne que há saldo no endereço
			If	FindFunction("WmsChkSBE") .And. WmsChkSBE(SBE->BE_LOCAL,NIL,NIL,SBE->BE_ESTFIS,NIL,NIL,NIL,Nil,NIL,,SBE->BE_LOCALIZ)
				// avisa o usuário e não deixa prosseguir
				Aviso("Saldo no Endereço","O endereço possui saldo. Não é permitido alterar o Produto Padrão!",{"Ok"})
				// variavel de retorno
				_lRet := .F.
			EndIf
		EndIF
	EndIf

Return(_lRet)