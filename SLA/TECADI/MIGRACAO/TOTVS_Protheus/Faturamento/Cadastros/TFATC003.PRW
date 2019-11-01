#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Cadastro de Pracas (transportes)                        !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 10/2010                                                 !
+------------------+---------------------------------------------------------+
!   ATUALIZACOES                                                             !
+-------------------------------------------+-----------+-----------+--------+
!   Descricao detalhada da atualizacao      !Nome do    ! Analista  !Data da !
!                                           !Solicitante! Respons.  !Atualiz.!
+-------------------------------------------+-----------+-----------+--------+
!                                           !           !           !        !
!                                           !           !           !        !
+-------------------------------------------+-----------+-----------+-------*/

User Function TFATC003
	Private cString := "SZB"
	dbSelectArea("SZB")
	dbSetOrder(1)
	AxCadastro(cString,"Cadastro de Pracas","U_FATC003A()","U_FATC003B()")
Return

//** funcao para validar se a praca podera ser excluida
User Function FATC003A

Return(.t.)

//** funcao para validar se ja nao existe uma praca com local padrao
User Function FATC003B
	Local _aAreaAtu := GetArea()
	Local _lRet := .t.

	// pesquisa praca com local padrao
	If (M->ZB_LOCALIZ=="S")
		dbSelectArea("SZB")
		SZB->(dbOrderNickName("ZB_LOCALIZ"))
		If SZB->(dbSeek( xFilial("SZB")+"S" ))
			If (SZB->ZB_CODIGO <> M->ZB_CODIGO)
				MsgStop("Já existe uma praça definida como local padrão. Verifica a praça código: "+SZB->ZB_CODIGO)
				_lRet := .f.
			EndIf
	    EndIf
	EndIf

	// restaura area inicial
	RestArea(_aAreaAtu)
Return(_lRet)