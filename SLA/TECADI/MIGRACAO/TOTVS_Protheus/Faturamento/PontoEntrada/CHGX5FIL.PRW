
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na rotina de escolha da     !
!                  ! serie/numeracao da nota fiscal (SX5NOTA)                !
!                  ! 1. Utilizado para definir o codigo da filial de pesquisa!
!                  !    do registro da tabela 01 no SX5, quando o SX5 for    !
!                  !    compartilhado e a numeracao da nota exclusiva        !
+------------------+---------------------------------------------------------+
!Autor             ! TSC195-Gustavo Schepp                                   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 03/2011                                                 !
+------------------+---------------------------------------------------------+
!   ATUALIZACOES                                                             !
+-------------------------------------------+-----------+-----------+--------+
!   Descricao detalhada da atualizacao      !Nome do    ! Analista  !Data da !
!                                           !Solicitante! Respons.  !Atualiz.!
+-------------------------------------------+-----------+-----------+--------+
!                                           !           !           !        !
!                                           !           !           !        !
+-------------------------------------------+-----------+-----------+-------*/

User Function CHGX5FIL
Return(xFilial("SF2"))