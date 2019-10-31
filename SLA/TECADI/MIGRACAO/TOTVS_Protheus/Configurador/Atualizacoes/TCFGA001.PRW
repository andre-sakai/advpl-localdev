#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Controle de mensagens de e-mail                         !
+------------------+---------------------------------------------------------+
!Autor             ! Emerson (EAP)                                           !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 10/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function TCFGA001()

	Local _aCores  := {{ " Z46_OK == 'S' ",'ENABLE' },{ " Z46_OK <> 'S' ",'DISABLE' }}

	Private cCadastro := "[TCFGA001] - Controle de Emails Tecadi "
	Private aRotina   := {{ "Pesquisa","AxPesqui", 0 , 1},;
		{ "Visualizar"    , "AxVisual"   , 0 , 2 },;
		{ "Reenvia  Msg." , "U_CFGA001A" , 0 , 4 },;
		{ "Cons.Log Msg." , "U_CFGA001B" , 0 , 4 } }

	//tabela de Emails
	Dbselectarea('Z46')
	//mostra a tabela Z46
	mBrowse(6, 1, 22, 75, "Z46",,,,,,_aCores )

Return

// envio do EMAIL Posicionado
User Function CFGA001A
	// area atual
	local _aAreaZ46 := Z46->(GetArea())

	// mensagem de confirmacao
	If ! MsgYesNo("Confirma o re-envio desta mensagem?")
		Return(.f.)
	EndIf

	// regrava a informação como não Enviado
	Dbselectarea('Z46')
	Reclock("Z46",.F.)
	Z46->Z46_OK     := ' '
	Z46->Z46_DTENVI := CTOD('')
	Z46->Z46_HRENVI := ' '
	Z46->(msunlock())

	// rotina Generica de Envio do Email
	msAguarde({|| U_FTSendMail( Z46->(Recno()) )},"[TCFGA001] - Aguarde ","Re-enviando o E-mail ...")

	// restaura area
	RestArea(_aAreaZ46)

	// mostra o log apos reenvio
	U_FTConsLog(Z46->Z46_FILIAL,'Z46', Z46->Z46_NCONTR)

Return

// consulta LOG Do Registro de Email
User Function CFGA001B()
	U_FTConsLog(Z46->Z46_FILIAL,'Z46', Z46->Z46_NCONTR) //Mostra os logs Do Registro
Return