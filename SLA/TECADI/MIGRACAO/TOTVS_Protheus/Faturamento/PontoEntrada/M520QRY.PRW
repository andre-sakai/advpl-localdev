
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada antes da exclusao da Nota Fiscal de    !
!                  ! Saida, utilizado para montar filtro de dados            !
!                  ! Obs: Utilizado em conjunto com o PE M520FIL             !
!                  ! 1. Filtrar somente notas que não foram contabilizadas   !
+------------------+---------------------------------------------------------+
!Retorno           ! Script Sql                                              !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 02/2014                                                 !
+------------------+---------------------------------------------------------!
!Data de Alteração ! 12/2014                                                 !
+---------------------------------------------------------------------------*/

User Function M520QRY
// recebe a query completa como parametro
local _cQuery  := ParamIxb[1]
// controle de exclusão chamando a rotina padrão
// se TRUE = não pode alterar
// se FALSE = pode alterar
local _lDataOk := CtVlDTMoed(mv_par03,mv_par04,Nil,Nil,.f.) //[3]dtInicial e [4]dtFinal para pesquisa

// pode alterar
If ( ! _lDataOk)
	// retorno parte da query pra buscar contabilizados e não contabilizados
	// somente pode alterar Notas de Serviço
	_cQuery += " AND ((F2_ESPECIE = 'NFS') OR ((F2_ESPECIE != 'NFS') AND (F2_DTLANC = ''))) "

// não pode alterar
Else
	Help(,, 'M520QRY.F01.001',, "O período (parâmetros) informado não permite exclusão da nota fiscal.", 1, 0,;
		NIL, NIL, NIL, NIL, NIL,;
		{"Escolha outras datas/períodos ou solicite reabertura dos calendários contábeis e/ou estorno de contabilização para o setor de contabilidade."}) 
	// retorno uma query qualquer para não poder alterar
	_cQuery += " AND F2_SERIE = 'XXX' " // série inexistente
EndIf

// retorno a query
Return(_cQuery)