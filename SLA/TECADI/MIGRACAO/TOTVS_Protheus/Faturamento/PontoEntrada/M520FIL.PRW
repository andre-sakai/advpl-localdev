
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada antes da exclusao da Nota Fiscal de    !
!                  ! Saida, utilizado para montar filtro de dados            !
!                  ! Obs: Utilizado em conjunto com o PE M520QRY             !
!                  ! 1. Filtrar somente notas que n�o foram contabilizadas   !
+------------------+---------------------------------------------------------+
!Retorno           ! Condicao AdvPl                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 02/2014                                                 !
+------------------+---------------------------------------------------------!
!Data de Altera��o ! 12/2014                                                 !
+---------------------------------------------------------------------------*/

User Function M520FIL
// variavel de retorno
local _cFilSF2 := ""
// controle de exclus�o chamando a rotina padr�o
// se TRUE = n�o pode alterar
// se FALSE = pode alterar
local _lDataOk := CtVlDTMoed(mv_par03,mv_par04,Nil,Nil,.f.) //[3]dtInicial e [4]dtFinal para pesquisa

// pode alterar
If ( ! _lDataOk)
	// retorno parte da condicao pra buscar contabilizados e n�o contabilizados
	// somente pode alterar Notas de Servi�o
	_cFilSF2 += " ((ALLTRIM(F2_ESPECIE) == 'NFS') .Or. ((ALLTRIM(F2_ESPECIE) != 'NFS') .And. (Empty(F2_DTLANC)))) "

// nao pode alterar
Else
	// retorno um comando qualquer para n�o poder alterar
	_cFilSF2 += " F2_SERIE == 'XXX' " // serie inexistente
EndIf

// retorno a condi��o
Return(_cFilSF2)