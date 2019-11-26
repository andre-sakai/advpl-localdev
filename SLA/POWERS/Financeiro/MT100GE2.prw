/*
+---------------------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      		    !
+---------------------------------------------------------------------------------------+
!   DADOS DO PROGRAMA                                                        		    !
+------------------+--------------------------------------------------------------------+
!Tipo              ! Ponto de entrada                                                   !
+------------------+--------------------------------------------------------------------+
!Modulo            ! Faturamento        		                                        !
+------------------+--------------------------------------------------------------------+
!Nome              ! MT100GE2                 		                                    !
+------------------+--------------------------------------------------------------------+
!Descricao         ! Replicação de campos do pedido de compras                          !
+------------------+--------------------------------------------------------------------+
*/
#include "rwmake.ch"
#include "protheus.ch"   

User Function MT100GE2()   

Local aAreaSF1 := GetArea("SF1")
//SF1->(DbSelectArea("SF1"))
//SF1->(DbSetOrder(1))
//SF1->(DbGotop())
//SF1->(DbSeek())
//SF1->(DbSeek(xFilial("SF1") + SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)) )

SE2->(DbSelectArea("SE2"))
SE2->(RecLock("SE2"))
SE2->E2_ZCOND := SF1->F1_COND
SE2->(MsUnLock())
            
RestArea(aAreaSF1)
Return()  





 
