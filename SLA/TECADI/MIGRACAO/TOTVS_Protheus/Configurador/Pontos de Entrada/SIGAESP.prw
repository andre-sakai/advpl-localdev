#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada para Nomear Módulos Específicos (96)   !
+------------------+---------------------------------------------------------+
!Retorno           ! Caracter                                                !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 03/2016 !
+------------------+--------------------------------------------------------*/

// ** funcao/ponto de entrada para nomear modulo customizado (codigo 96)
User Function ESP2NOME
Return( OemToAnsi( "TECADI TI - Configurador" ) )

// ** funcao/ponto de entrada para nomear modulo customizado (codigo 98)
// lastmain = SIGAESP1
User Function ESP1NOME
	// cria variavel para uso nos modulos
	public ___aPrtSigla := {}
	public ___aPrtDepos := {}
	public ___cPrtToken := ""
	// estrutura dos dados do login
	// 1 - Data
	// 2 - Hora
	// 3 - ThreadID()
	// 4 - GetComputerName()
	// 5 - Controle se deve gerar o registro da Sessao
	// 6 - Codigo do Usuario
	// 7 - User Name (nome do usuario)
	// 8 - Email do usuario
	public ___aPrtLogin := { Date(), Time(), ThreadID(), GetComputerName(), .T., "", "", "" }

	// cria um ID session
	___cPrtToken := DtoS(___aPrtLogin[1])
	___cPrtToken += ___aPrtLogin[2]
	___cPrtToken += StrZero(___aPrtLogin[3],12)

	// cript da Id Session
	___cPrtToken := Md5(___cPrtToken)

Return( OemToAnsi( "Portal do Cliente" ) )