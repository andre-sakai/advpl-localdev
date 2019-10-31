#Include "totvs.ch"
#Include "protheus.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Agendamento de rotina de conversao de Solicitacao de    !
!                  ! Cargas em Pedido de Venda (separacao)                   !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 04/2018 !
+------------------+--------------------------------------------------------*/

User Function TWMSW003()

	// variaveis de controle do agendamento (scheduler)
	local _cLockFile := ""
	local _nHdlJob   := 0
	// controle de Loop
	local _nX

	// id da tarefa
	local _cTaskId := FWGetIDTask()

	// mensagens no console do server
//	ConOut("+" + Repl("=", 80) + "+")
//	ConOut("|" + PadC("Agendamento - TWMSW003 - Conversao Solicitacao de Cargas em Pedido de Venda", 80) + "|")
//	ConOut("+" + Repl("=", 80) + "+")
//	ConOut("|" + PadR("..Inicio   : " + Time(), 80)   + "|")
//	ConOut("|" + PadR("..Empresa  : " + cEmpAnt, 80)  + "|")
//	ConOut("|" + PadR("..Filial   : " + cFilAnt, 80)  + "|")
//	ConOut("|" + PadR("..Id Tarefa: " + _cTaskId, 80) + "|")
//	ConOut("+" + Repl("-", 80) + "+")

	// Montagem do arquivo do job principal
	_cLockFile := lower( "TWMSW003" + cEmpAnt + cFilAnt + _cTaskId ) + ".lck"

	// Verifica se a thread principal esta rodando
	For _nX := 1 To 2

		// verifica se o JOB esta em execucao
		If ( ! jobIsRunning( _cLockFile ) )

			// inicia execucao e controle do JOB
			_nHdlJob := JobSetRunning( _cLockFile, .T. )

			// se conseguiu acesso exclusivo
			If ( _nHdlJob >= 0 )
				// mensagens no console do server
//				ConOut("|" + PadC("== Iniciando o processo principal de TWMSW003 ==", 80) + "|")
//				ConOut("+" + Repl("-", 80) + "+")
				// chamada da funcao padrao de conversão de solicitacao de carga em pedido de venda
				U_WMSA038A( .T. )

			Endif

			// Libera o Lock
			JobSetRunning( _cLockFile, .F., _nHdlJob )

			// mensagens no console do server
//			ConOut("|" + PadC("== Finalizando o processo principal de TWMSW003 ==", 80) + "|")
//			ConOut("+" + Repl("=", 80) + "+")

			// sai do Loop
			Exit

		Else

			// Thread principal em Lock
			// mensagens no console do server
//			ConOut("|" + PadC(">>> Falha na inicializacao do processo de TWMSW003 <<<", 80) + "|")
//			ConOut("+" + Repl("=", 80) + "+")

			// aguarda 3 segundos
			sleep( 3000 )

		Endif

	Next _nX

Return

// ** funcao SchedDef - Retorna as perguntas definidas no schedule.
// ** aReturn         - Array com os parametros
Static Function SchedDef()
	// variavel de retorno
	Local _aParam := {}
	// grupo de perfuntas
	local _cPerg := PadR("WMSA038A", 10)

	// definicao de parametros
	_aParam := {;
	"P"   ,; // Tipo R para relatorio P para processo
	_cPerg,; // Pergunte do relatorio, caso nao use passar ParamDef
	Nil   ,; // Alias
	Nil   ,; // Array de ordens
	Nil    } // Titulo

Return(_aParam)