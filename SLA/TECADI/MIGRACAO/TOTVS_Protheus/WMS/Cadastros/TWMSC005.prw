#INCLUDE "PROTHEUS.CH"

/*
+----------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! TWMSC005                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Axcadastro tabela Z31 Tipo de Embalagem                 !
!                  !                                                         !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe Jose Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 11/03/15                                                !
+------------------+---------------------------------------------------------+
!   ATUALIZACOES                                                             !
+-------------------------------------------+-----------+-----------+--------+
!   Descricao detalhada da atualizacao      !Nome do    ! Analista  !Data da !
!                                           !Solicitante! Respons.  !Atualiz.!
+-------------------------------------------+-----------+-----------+--------+
!                                           !           !           !        !
!                                           !           !           !        !
+-------------------------------------------+-----------+-----------+--------+
!                                           !           !           !        !
!                                           !           !           !        !
+-------------------------------------------+-----------+-----------+--------+
*/

User Function TWMSC005()

	local _cVldAlt := ".T."
	local _cVldExc := "StaticCall(TWMSC005,sfValidDel)"

	chkFile("Z31")
	dbSelectArea("Z31")
	Z31->(dbGoTop())
	Z31->(DbSetOrder(1))
	axCadastro("Z31","Cadastro de Tipo de Embalagem",_cVldExc,_cVldAlt,,,{||StaticCall(TWMSC005,sfGeralog)})

Return

//** Função para verificar se o código ja foi utilizado na conferencia
Static Function sfValidDel()
	Local _lRet := .T.
/*
	Z07->(dbgotop())
	Z07->(dbsetorder())//Definir Indice
	If Z07->(dbseek(xFilial("Z07")+M->Z31_CODIGO))
		_lRet := .F.
		MsgStop("Embalagem ja utilizada em uma conferencia","TWMSC005 - Exclusão não Permitida")
	EndIf
*/	
Return(_lRet)

//** Função para gerar log na manuntenção de Linha(Inclusão/Alteração/Exclusão)
Static Function sfGeralog()

	Local _lRet := .T.
	Local _cdescri:= ""
	Local _lAlt := .F.
	
	If Inclui
		_cdescri:="Inclusão de Registro"
		U_FtGeraLog(cfilAnt,"Z31",xFilial("Z31")+M->Z31_CODIGO,_cdescri,"","")
	ElseIf Altera

		If M->Z31_DESCRI <> Z31->Z31_DESCRI
			_lAlt := .T.
			_cdescri+="Alterado Campo Z31_DESCRI = De " + Alltrim(Z31->Z31_DESCRI) + " Para " + Alltrim(M->Z31_DESCRI) + CRLF
		EndIf
		
		If M->Z31_ALTURA <> Z31->Z31_ALTURA
			_lAlt := .T.
			_cdescri+="Alterado Campo Z31_ALTURA = De " + Alltrim(Str(Z31->Z31_ALTURA)) + " Para " + Alltrim(Str(M->Z31_ALTURA)) + CRLF
		EndIf
		
		If M->Z31_LARGUR <> Z31->Z31_LARGUR
			_lAlt := .T.
			_cdescri+="Alterado Campo Z31_LARGUR = De " + Alltrim(Str(Z31->Z31_LARGUR)) + " Para " + Alltrim(Str(M->Z31_LARGUR)) + CRLF
		EndIf
		
		If M->Z31_COMPRI <> Z31->Z31_COMPRI
			_lAlt := .T.
			_cdescri+="Alterado Campo Z31_COMPRI = De " + Alltrim(Str(Z31->Z31_COMPRI)) + " Para " + Alltrim(Str(M->Z31_COMPRI)) + CRLF
		EndIf
		
		If M->Z31_CUBAGE <> Z31->Z31_CUBAGE
			_lAlt := .T.
			_cdescri+="Alterado Campo Z31_CUBAGE = De " + Alltrim(Str(Z31->Z31_CUBAGE)) + " Para " + Alltrim(Str(M->Z31_CUBAGE)) + CRLF
		EndIf
		
		If M->Z31_PESO   <> Z31->Z31_PESO
			_lAlt := .T.
			_cdescri+="Alterado Campo Z31_PESO = De " + Alltrim(Str(Z31->Z31_PESO)) + " Para " + Alltrim(Str(M->Z31_PESO)) + CRLF
		EndIf
		
		If M->Z31_SIGLA  <> Z31->Z31_SIGLA
			_lAlt := .T.
			_cdescri+="Alterado Campo Z31_SIGLA = De " + Alltrim(Z31->Z31_SIGLA) + " Para " + Alltrim(M->Z31_SIGLA) + CRLF
		EndIf
		If _lAlt
			U_FtGeraLog(cfilAnt,"Z31",xFilial("Z31")+M->Z31_CODIGO,_cdescri,"","")
		EndIf
	Else
		_cdescri:="Exclusão de Registro"
		U_FtGeraLog(cfilAnt,"Z31",xFilial("Z31")+Z31->Z31_CODIGO,_cdescri,"","")
	EndIf
 
Return(_lRet)