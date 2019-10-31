
/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado no final da gravacao do item!
!                  ! da nota fiscal de saida                                 !
!                  ! 1. Utilizado para gravar os campos D2_ZPESOB, D2_ZPESOL !
!                  !    e D2_ZCUBAGE                                         !
+------------------+---------------------------------------------------------+
!Retorno           ! Sem Retorno                                             !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 07/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function MSD2460()
	Reclock("SD2")
		SD2->D2_ZPESOL	:= SC6->C6_ZPESOL
		SD2->D2_ZPESOB	:= SC6->C6_ZPESOB
		SD2->D2_ZCUBAGE	:= SC6->C6_ZCUBAGE
	Msunlock()
Return