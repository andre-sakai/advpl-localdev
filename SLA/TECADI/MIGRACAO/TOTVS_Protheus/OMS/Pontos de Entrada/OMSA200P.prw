#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na validacao do estorno da  !
!                  ! carga (OMS)                                             !
!                  ! 1. Verificar se existe mapa no WMS                      !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 02/2016 !
+------------------+--------------------------------------------------------*/

User Function OMSA200P()
	// area atual
	local _aAreaAtu := GetArea()
	local _aAreaDAI := DAI->(GetArea())

	// numero da carga
	Local _cCarga  := PARAMIXB[1]
	Local _cSeqCar := PARAMIXB[2]

	// seek DAI
	local _cSeekDAI

	// variavel de retorno
	Local _lRet := .t.

	// variavel para controle de mapa de expedição gerado
	local _lTemMapa := .f.

	// Verifica se o WMS esta ativo e define o endereco WMS para separacao da mercadoria
	If (_lRet).and.(cEmpAnt=="01")

		// busca os pedido da carga
		dbSelectArea("DAI")
		DAI->(dbSetOrder(1)) // 1-DAI_FILIAL, DAI_COD, DAI_SEQCAR, DAI_SEQUEN, DAI_PEDIDO
		DAI->(dbSeek( _cSeekDAI := xFilial("DAI")+_cCarga+_cSeqCar ))

		// varre todos os pedidos da carga
		While DAI->( ! Eof() ).and.(DAI->(DAI_FILIAL+DAI_COD+DAI_SEQCAR) == _cSeekDAI)

			// variavel para controle de mapa de expedição gerado
			_lTemMapa := U_FtMapExp(DAI->DAI_PEDIDO)

			// se tem mapa, bloqueia exclusao
			If (_lTemMapa)
				// mensagem
				Aviso('Tecadi: OMSA200P', 'Esta Carga não pode ser estornada porque possui Serviços de WMS Pendentes. Estorne estes Serviços para proceder com o estorno.', {'Ok'})
				// variavel de controle
				_lRet := .f.
				// sai do loop
				Exit
			EndIf

			// proximo item
			DAI->(dbSkip())
		EndDo

	EndIf

	// restaura area atual
	RestArea(_aAreaDAI)
	RestArea(_aAreaAtu)

Return(_lRet)