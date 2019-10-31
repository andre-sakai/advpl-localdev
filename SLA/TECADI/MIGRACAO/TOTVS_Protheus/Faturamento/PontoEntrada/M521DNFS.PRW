#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! PE Após a Exclusao dos Dados da NF de Saída             !
!                  ! 1. Utilizado para excluir o rateio das naturezas do ti- !
!                  !    tulo a receber, pois o padrao nao faz (ver orientacao!
!                  !    do chamado SDNYRZ)                                   !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 08/2011                                                 !
+------------------+--------------------------------------------------------*/

User Function M521DNFS
	// armazena area inicial
	local _aAreaAtu := GetArea()
	local _aAreaSEV := SEV->(GetArea())
	// SEEK do SEV
	local _cSeekSEV
	
	// exclusao do rateio somente quanto houver valor de duplicatas
	If (SF2->F2_VALFAT > 0)
		// realiza a exclusao do rateio das naturezas (quando houver)
		dbSelectArea("SEV")
		SEV->(dbSetOrder(1)) //1-EV_FILIAL, EV_PREFIXO, EV_NUM, EV_PARCELA, EV_TIPO, EV_CLIFOR, EV_LOJA, EV_NATUREZ
		SEV->(dbSeek( _cSeekSEV := xFilial("SEV")+SF2->(F2_PREFIXO+F2_DUPL) ))
		While SEV->(!Eof()).and.(SEV->(EV_FILIAL+EV_PREFIXO+EV_NUM)==_cSeekSEV)
			// filtro do cliente                                        /  tipo A RECEBER         /  notas fiscais
			If (SEV->(EV_CLIFOR+EV_LOJA) == SF2->(F2_CLIENTE+F2_LOJA)).and.(SEV->EV_RECPAG=="R").and.(SEV->EV_TIPO $ MVNOTAFIS)
				// exclui o item
				RecLock("SEV")
					SEV->(DbDelete())
				SEV->(MsUnLock())
			EndIf
			// proximo item
			SEV->(dbSkip())
		EndDo
	EndIf

	// restaura area inicial
	RestArea(_aAreaSEV)
	RestArea(_aAreaAtu)

Return(.t.)