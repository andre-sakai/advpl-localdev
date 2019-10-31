#Include 'Protheus.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! MTFILLP3                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada executado na geração do arquivo de     !
!                  ! trabalho resultante do processamento dos registros      !
!                  ! relacionados ao poder de terceiros (SB6,SD1,SD2).       !
!                  ! Este ponto de entrada é executado para cada registro da !
!                  ! tabela SB6.                                             !
!                  ! 1. Utilizado para alterar o saldo de acordo com a       !
!                  !    reserva (tipo de estoque customizado)                !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe Jose Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 17/03/15                                                !
+------------------+--------------------------------------------------------*/

User Function MTFILLP3

	// parametros recebidos
	Local ExpA1 := PARAMIXB[1] // Contém a estrutura do arquivo de trabalho gerado pela rotina
	Local ExpC2 := PARAMIXB[2] // Contém o alias do arquivo de trabalho
	Local ExpC3 := PARAMIXB[3] // Contém o alias do arquivo SB6 em processo
	Local ExpC4 := PARAMIXB[4] // Contém o alias do arquivo SD2 em processo
	Local ExpC5 := PARAMIXB[5] // Contém o alias do arquivo SD1 em processo
	Local ExpC6 := PARAMIXB[6] // Tipo de operação E-Entrada/S-Saida

	// Seek SC0
	Local _cSeekSC0 := ""

	// Variavel para Guardar quantidade total reservada.
	Local _nReserv  := 0

	// reservas de produtos
	dbSelectArea("SC0")
	SC0->(DbOrderNickName("SC0001"))// C0_FILIAL+C0_ZIDENT

	//Verifica se tem alguma reserva desta nota especifica. E se o Registro da SB6 trata de uma entrada.
	If SC0->(dbSeek( _cSeekSC0 := xFilial("SC0") + (ExpC2)->B6_IDENT)) .And. ((ExpC3)->B6_PODER3 == "R")

		While SC0->(!Eof()).and.(SC0->(C0_FILIAL+C0_ZIDENT) == _cSeekSC0 )

			//Soma quantidade total reservada.
			_nReserv += SC0->C0_QUANT

			//proximo item da reserva
			SC0->(dbSkip())
		EndDo

		// Se tiver quantidade reservada calcula o saldo menos a reserva para pegar o real saldo disponivel.
		(ExpC2)->B6_SALDO := (ExpC2)->B6_SALDO - _nReserv
	EndIf

Return()