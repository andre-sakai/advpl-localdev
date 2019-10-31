#Include 'Totvs.ch'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada na rotina documentos de entrada        !
!                  ! - adicionar botoes na tela de manutencao/visualizacao   !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 04/2017 !
+------------------+--------------------------------------------------------*/

User Function MA103BUT()
	// variavel de retorno
	Local _aButtons := {}

	// verifica se o campo existe
	If (SF1->(FieldPos("F1_ZINFADI")) > 0)
		// adiciona botao/opcao para visualizar as informacoes adicionais/fiscais da nota
		aadd(_aButtons, {'GACIMG32', {|| sfVisInfAd() }, 'Vis.Inform.Adicionais'})
	EndIf

Return (_aButtons)

// ** funcao para visualizar as informacoes adicionais da nota fiscal
Static Function sfVisInfAd()
	HS_MsgInf(SF1->F1_ZINFADI, "Informações Adicionais", "Informações Adicionais")
Return