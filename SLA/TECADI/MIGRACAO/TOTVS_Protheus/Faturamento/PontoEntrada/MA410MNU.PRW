#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela do      !
!                  ! Pedido de Venda, usado para adicionais botoes           !
!                  ! 1. Botao para impressao dos detalhes do faturamento de  !
!                  !    Contratos                                            !
!                  ! 2. Opcao para importar XML e TXT para Ped. Venda        !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 02/2010 !
+------------------+--------------------------------------------------------*/

User Function MA410MNU
	// extrai as informacoes do usuario logado
	local _aUsrInfo := U_FtWmsFil()
	// se deve filtrar os pedidos por usuario
	local _lFiltrar := _aUsrInfo[1]
	// opcao de exclusao
	local _nPosExcl := AScan( aRotina, { |x| Upper(Alltrim(x[1])) == "EXCLUIR" } )
	// vetor com opcoes de exclusao
	local _aBtnExcl := IIf(_nPosExcl != 0, aClone(aRotina[_nPosExcl][2]), Nil)

	// sub-menu (faturamento)
	Local _aMenuFat := {;
	{"Det. Fat. Pedido Único"  , "U_WMSR004A(SC5->C5_NUM,SC5->C5_NUM,SC5->C5_CLIENTE,SC5->C5_CLIENTE,SC5->C5_LOJACLI,SC5->C5_LOJACLI,SC5->C5_EMISSAO,SC5->C5_EMISSAO)",0,2,0,nil },;
	{"Det. Fat. Vários Pedidos", "U_TWMSR004()",0,2,0,nil }}

	// sub-menu (wms)
	Local _aMenuWms := {;
	{ "Importar Pedido"           , "U_TFATA001()"   , 0, 3, 0, nil },;
	{ "Informações Adicionais WMS", "U_TWMSA022()"   , 0, 3, 0, nil },;
	{ "Montagem de carga"         , "OMSA200()"      , 0, 4, 0, nil },;
	{ "Gerar arquivo EDI saída   ", "U_TWMSA026(.T.)", 0, 4, 0, nil },;
	{ "Gerar Onda de Separação"   , "U_WMSA042C()"   , 0, 4, 0, nil } }

	// opcao para impressao dos detalhes do faturamento
	If ( ! _lFiltrar ) .Or. ("S" $ _aUsrInfo[2])
		aAdd(aRotina,{"Faturamento", _aMenuFat, 0, 2, 0, Nil})
	EndIf

	// opcoes especificas de WMS
	If ( ! _lFiltrar ) .Or. ("P" $ _aUsrInfo[2])
		aAdd(aRotina,{"Gestão de WMS", _aMenuWms, 0, 2, 0, Nil})
	EndIf

	// inclui funcao customizacao de exclusao de liberacao de pedidos
	If (_nPosExcl != 0) .And. (ValType(_aBtnExcl) == "A") .And. (Len(_aBtnExcl) != 0)

		// adiciona opcao cusomizada
		aAdd(_aBtnExcl, { "Excluir Liberação", "U_FtEstLib(SC5->C5_NUM, .T.)" , 0, 5, 0, NIL} )

		// atualiza menu principal
		aRotina[_nPosExcl][2] := aClone(_aBtnExcl)

	EndIf

Return
