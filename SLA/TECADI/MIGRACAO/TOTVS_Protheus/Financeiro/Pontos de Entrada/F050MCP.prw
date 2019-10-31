#Include 'Protheus.ch'


/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na rotina Contas a Pagar    !
!                  ! 1. Permite "destravar" campos bloqueados para altera��o !
!                  !    no t�tulo                                            !
+------------------+---------------------------------------------------------+
!Retorno           ! Array com campos a serem alterados                      !
+------------------+---------------------------------------------------------+
!Autor             ! Luiz Poleza                                             !
+------------------+---------------------------------------------------------+
! Documenta��o Totvs:                                                        !
+----------------------------------------------------------------------------+
! http://tdn.totvs.com/display/public/PROT/DT_F050MCP_Adiciona_campos_na_    !
! alteracao_do_Contas_a_pagar                                                !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 13/09/2018                                              !
+------------------+--------------------------------------------------------*/

User Function F050MCP()
	Local _aCampos := PARAMIXB
	
	// permite alterar campos do vencimento
	// chamado 17033 - Helo�sa Esp�ndola e autorizado por Viviane Kurth por e-mail
	// obs: foi avisado dos riscos no chamado, caso o t�tulo tenha impostos
	
	AADD(_aCampos,"E2_VENCTO")	
	AADD(_aCampos,"E2_VENCREA")	
Return _aCampos