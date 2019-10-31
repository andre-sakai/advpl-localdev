#Include "totvs.ch"
#Include "protheus.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Agendamento de rotina para envio de mensagens de email  !
!                  ! em massa, gerado por demais rotinas do sistema          !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                     ! Data de Criacao ! 04/2018 !
+------------------+--------------------------------------------------------*/

User Function TCFGW001

	// variaveis de controle do agendamento (scheduler)
	local _cLockFile := ""
	local _nHdlJob   := 0
	// controle de Loop
	local _nX

	// id da tarefa
	local _cTaskId := FWGetIDTask()

	// Montagem do arquivo do job principal
	_cLockFile := lower( "TCFGW001" + cEmpAnt ) + ".lck"

	// Verifica se a thread principal esta rodando
	For _nX := 1 To 2

		// verifica se o JOB esta em execucao
		If ( ! JobIsRunning( _cLockFile ) )

			// inicia execucao e controle do JOB
			_nHdlJob := JobSetRunning( _cLockFile, .T. )

			// se conseguiu acesso exclusivo
			If ( _nHdlJob >= 0 )
				// executa funcao
				U_FtSendMail()

			Endif

			// Libera o Lock
			JobSetRunning( _cLockFile, .F., _nHdlJob )

			// sai do Loop
			Exit

		Else

			// Thread principal em Lock
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

	// definicao de parametros
	_aParam := {;
	"P"   ,; // Tipo R para relatorio P para processo
	"TCFGW001  ",; // Pergunte do relatorio, caso nao use passar ParamDef
	Nil   ,; // Alias
	Nil   ,; // Array de ordens
	Nil    } // Titulo

Return(_aParam)
