#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada é executado para inicializar a TES de  !
!                  ! Entrada.                                                !
+------------------+---------------------------------------------------------+
!Retorno           ! _cTes                                                   !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe José Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function M145HTES()

	// TES da Nota Fiscal de Entrada
	Local _cTes  := PARAMIXB

	// notas fiscais de cliente para armazenagem
	If (DB1->DB1_TIPONF $ "B/D")
		// limpa a variavel com a informação da TES, forçando a criação de uma Pré-Nota.
		_cTes := Space(Len(_cTes))
	EndIf

Return(_cTes)