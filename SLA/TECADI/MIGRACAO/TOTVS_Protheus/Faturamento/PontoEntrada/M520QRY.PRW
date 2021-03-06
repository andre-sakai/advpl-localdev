
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada antes da exclusao da Nota Fiscal de    !
!                  ! Saida, utilizado para montar filtro de dados            !
!                  ! Obs: Utilizado em conjunto com o PE M520FIL             !
!                  ! 1. Filtrar somente notas que n�o foram contabilizadas   !
+------------------+---------------------------------------------------------+
!Retorno           ! Script Sql                                              !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 02/2014                                                 !
+------------------+---------------------------------------------------------!
!Data de Altera��o ! 12/2014                                                 !
+---------------------------------------------------------------------------*/

User Function M520QRY
// recebe a query completa como parametro
local _cQuery  := ParamIxb[1]
// controle de exclus�o chamando a rotina padr�o
// se TRUE = n�o pode alterar
// se FALSE = pode alterar
local _lDataOk := CtVlDTMoed(mv_par03,mv_par04,Nil,Nil,.f.) //[3]dtInicial e [4]dtFinal para pesquisa

// pode alterar
If ( ! _lDataOk)
	// retorno parte da query pra buscar contabilizados e n�o contabilizados
	// somente pode alterar Notas de Servi�o
	_cQuery += " AND ((F2_ESPECIE = 'NFS') OR ((F2_ESPECIE != 'NFS') AND (F2_DTLANC = ''))) "

// n�o pode alterar
Else
	Help(,, 'M520QRY.F01.001',, "O per�odo (par�metros) informado n�o permite exclus�o da nota fiscal.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"Escolha outras datas/per�odos ou solicite reabertura dos calend�rios cont�beis e/ou estorno de contabiliza��o para o setor de contabilidade."}) 
	// retorno uma query qualquer para n�o poder alterar
	_cQuery += " AND F2_SERIE = 'XXX' " // s�rie inexistente
EndIf

// retorno a query
Return(_cQuery)