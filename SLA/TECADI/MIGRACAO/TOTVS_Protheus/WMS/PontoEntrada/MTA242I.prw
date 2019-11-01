#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                         FICHA TECNICA DO PROGRAMA                          !
+------------------+---------------------------------------------------------+
!Descricao         ! PE apos a gravacao do item na movimentacao interna de   !
!                  ! desmontagem de produtos (MATA242)                       !
!                  ! OBS: UTILIZAR EM CONJUNTO COM O PE MT242CPO             !
!                  ! 1. Gravar campos customizados                           !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 03/2016 !
+------------------+--------------------------------------------------------*/

User Function MTA242I
	// area atual
	local _aAreaSD3 := SD3->(GetArea())

	// conteudo atual dos campos
	local _cDocSD3   := SD3->D3_DOC
	local _dEmissao  := SD3->D3_EMISSAO
	local _cNumSeq   := SD3->D3_NUMSEQ
	local _cNumOs    := SD3->D3_ZNUMOS
	local _cSeqOs    := SD3->D3_ZSEQOS
	local _cIdPalete := SD3->D3_ZETQPLT
	local _cSerieNf  := SD3->D3_ZSERIE
	local _cOrigNS   := SD3->D3_ZORIGNS

	// seek
	local _cSeekSD3

	// busca registros com referencia no SD3
	dbSelectArea("SD3")
	SD3->(dbSetOrder(4)) // 4-D3_FILIAL, D3_NUMSEQ, D3_CHAVE, D3_COD
	SD3->(dbSeek( _cSeekSD3 := xFilial("SD3")+_cNumSeq ))

	// atualiza movimento inverso do destino
	While SD3->( ! Eof() ).and.( SD3->(D3_FILIAL + D3_NUMSEQ) == _cSeekSD3)

		// valida demais campos
		If (SD3->D3_DOC != _cDocSD3).or.(SD3->D3_EMISSAO != _dEmissao).Or.(SD3->D3_ESTORNO == "S").or.( ! Empty(SD3->D3_ZNUMOS) )
			// proximo item
			SD3->(dbSkip())
			// loop
			Loop
		EndIf

		// atualiza campos customizados
		RecLock("SD3")
		SD3->D3_ZNUMOS  := _cNumOs
		SD3->D3_ZSEQOS  := _cSeqOs
		SD3->D3_ZETQPLT := _cIdPalete
		SD3->D3_ZSERIE  := _cSerieNf
		SD3->D3_ZORIGNS := _cOrigNS
		SD3->(MsUnLock())

		// proximo item
		SD3->(dbSkip())
	EndDo
	// restaura area
	RestArea(_aAreaSD3)
Return