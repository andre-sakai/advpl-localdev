

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada na tela de Monitor de Nota Fiscal      !
!                  ! Eletrônica de Serviço - NFS-e                           !
!                  ! 1. Criar botoes para enviar notas e anexos por e-mail   !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 02/2014                                                 !
+------------------+--------------------------------------------------------*/

User Function FIRSTNFSE

// sub-menu (Arquivos)
Local _aMenuArq := {{"Enviar Dados"	,"U_NFSE002A()",0,2,0 ,NIL},;
{"Anexar Arquivos"	,"U_NFSE002B()",0,2,0 ,NIL},;
{"Consultar Anexos"	,"U_NFSE002C()",0,2,0 ,NIL},;
{"Consultar Log"	,"U_NFSE002D()",0,2,0 ,NIL},;
{"Consulta Completa","U_TNFSE002()",0,2,0 ,NIL}}

// rotina cutomizada para impressao da Nfs-e
aAdd(aRotina,{"Impressão"    ,"U_NFSE001D()",0,2,0 ,NIL})
// rotina cutomizada para enviar Nfs-e por email
aAdd(aRotina,{"Anexos"       ,_aMenuArq     ,0,2,0 ,NIL})
// rotina cutomizada para impressao de boletos
aAdd(aRotina,{"Imp. Boletos" ,"U_TFIN001()" ,0,2,0 ,NIL})

Return