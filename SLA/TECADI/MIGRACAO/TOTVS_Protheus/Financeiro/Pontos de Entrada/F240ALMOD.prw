#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na geração do arquivo de    !
!                  ! envio de CNAB modelo SISPAG                             !
!                  ! 1. Altera modelo do CNAB (TOTVS nao atender modelo 91)  !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 01/2017 !
+------------------+--------------------------------------------------------*/

User Function F240ALMOD()
	// modelo recebido como parametro
	local _cModelo := Paramixb[1]

	// se for 91-GNRE E TRIBUTOS COM CÓDIGO DE BARRAS, muda pra 16-DARF NORMAL
	If (_cModelo == "91")
		_cModelo := "16"
	EndIf

Return (_cModelo)