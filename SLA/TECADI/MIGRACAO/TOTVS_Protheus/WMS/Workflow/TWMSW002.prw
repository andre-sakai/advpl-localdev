#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Agendamento de rotina para automatizar reabastecimento  !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 01/2018 !
+------------------+--------------------------------------------------------*/

User Function TWMSW002()

	// mensagens no console do server
//	ConOut(Repl("-", 80))
//	ConOut(PadC("Agendamento - TWMSW002 - Reabastecimento de Picking", 80))
//	ConOut(PadC("Inicio: " + Time(), 80))
//	ConOut(Repl("-", 80))

	// chamada da funcao padrao de geracao de ordem de servivo de reabastecimento
	U_WMSA009G( .T. )

Return

// ** funcao SchedDef - Retorna as perguntas definidas no schedule.
// ** aReturn         - Array com os parametros
Static Function SchedDef()
	// variavel de retorno
	Local _aParam := {}
	// grupo de perfuntas
	local _cPerg := PadR("WMSA009G",10)

	// definicao de parametros
	_aParam := {;
	"P"   ,; // Tipo R para relatorio P para processo
	_cPerg,; // Pergunte do relatorio, caso nao use passar ParamDef
	Nil   ,; // Alias
	Nil   ,; // Array de ordens
	Nil    } // Titulo

Return(_aParam)