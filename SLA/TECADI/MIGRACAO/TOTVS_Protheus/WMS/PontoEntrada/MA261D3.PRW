#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na gravacao do registro SD3 !
!                  ! na transferencia de mercadorias (mod 2 MATA261)         !
!                  ! OBS: UTILIZAR EM CONJUNTO COM O PE MA261IN, MA261CPO    !
!                  ! 1. Gravar campos customizados                           !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 02/2013 !
+------------------+--------------------------------------------------------*/

User Function MA261D3

	// linha atual do browse
	local _nLinAtu := ParamIxb

	// area atual
	Local _aAreaAtu	:= GetArea()
	Local _aAreaSD3	:= SD3->(GetArea())
	Local _aAreaSDB	:= SDB->(GetArea())

	// posicao dos campos customizados no browse
	local _nPosPro   := aScan(aHeader,{|x| UPPER(Alltrim(x[2])) == "D3_COD"})
	local _nPosNumOs := aScan(aHeader,{|x| UPPER(Alltrim(x[2])) == "D3_ZNUMOS"})
	local _nPosSeqOs := aScan(aHeader,{|x| UPPER(Alltrim(x[2])) == "D3_ZSEQOS"})
	local _nPosEtqPl := aScan(aHeader,{|x| UPPER(Alltrim(x[2])) == "D3_ZETQPLT"})
	local _nPosCarga := aScan(aHeader,{|x| UPPER(Alltrim(x[2])) == "D3_ZCARGA"})
	local _nPosPedid := aScan(aHeader,{|x| UPPER(Alltrim(x[2])) == "D3_ZPEDIDO"})
	local _nPosItPed := aScan(aHeader,{|x| UPPER(Alltrim(x[2])) == "D3_ZITPEDI"})

	// chave para o dbSeek
	Local _cSeekSD3 := SD3->(D3_FILIAL + D3_DOC + D3_NUMSEQ)                     // indice 8
	Local _cSeekSDB

	// atualiza o registro - SD3
	dbSelectArea("SD3")
	SD3->(dbSetOrder(8)) // 8-D3_FILIAL, D3_DOC, D3_NUMSEQ

	// posiciona no registro desejado
	If SD3->(dbSeek( _cSeekSD3 ))

		// varre todos os registros que atende a condicao
		While SD3->( ! Eof() ).and.(SD3->(D3_FILIAL+D3_DOC+D3_NUMSEQ) == _cSeekSD3 )

			// atualiza os campos
			RecLock("SD3",.F.)

			If (_nPosNumOs > 0)
				SD3->D3_ZNUMOS  := aCols[_nLinAtu][_nPosNumOs]
			EndIf
			If (_nPosSeqOs > 0)
				SD3->D3_ZSEQOS  := aCols[_nLinAtu][_nPosSeqOs]
			EndIf
			If (_nPosEtqPl > 0)
				SD3->D3_ZETQPLT := aCols[_nLinAtu][_nPosEtqPl]
			EndIf
			If (_nPosCarga > 0)
				SD3->D3_ZCARGA  := aCols[_nLinAtu][_nPosCarga]
			EndIf
			If (_nPosPedid > 0)
				SD3->D3_ZPEDIDO := aCols[_nLinAtu][_nPosPedid]
			EndIf
			If (_nPosItPed > 0)
				SD3->D3_ZITPEDI := aCols[_nLinAtu][_nPosItPed]
			EndIf

			// confirma gravacao de dados
			SD3->(MsUnlock())


			// prepara dados para While no SDB
			_cSeekSDB := SD3->(D3_FILIAL + D3_COD + D3_LOCAL + D3_NUMSEQ + D3_DOC) // indice 1

			// atualiza os dados no movimento por lote - SDB
			dbSelectArea("SDB")
			SDB->(dbSetOrder(1)) // 1-DB_FILIAL, DB_PRODUTO, DB_LOCAL, DB_NUMSEQ, DB_DOC, DB_SERIE, DB_CLIFOR, DB_LOJA, DB_ITEM

			// posiciona no registro desejado
			If SDB->(dbSeek( _cSeekSDB ))

				// varre todos os registros que atende a condicao
				While SDB->( ! Eof() ).and.( SDB->(DB_FILIAL + DB_PRODUTO + DB_LOCAL + DB_NUMSEQ + DB_DOC ) == _cSeekSDB )

					// atualiza os campos
					RecLock("SDB",.F.)

					If (_nPosNumOs > 0)
						SDB->DB_ZNUMOS  := aCols[_nLinAtu][_nPosNumOs]
					EndIf
					If (_nPosSeqOs > 0)
						SDB->DB_ZSEQOS  := aCols[_nLinAtu][_nPosSeqOs]
					EndIf
					If (_nPosEtqPl > 0)
						SDB->DB_ZPALLET := aCols[_nLinAtu][_nPosEtqPl]
					EndIf

					// confirma gravacao de dados
					SDB->(MsUnlock())

					// proxima Linha
					SDB->(dbSkip())
				EndDo

			EndIf

			// proxima Linha
			SD3->(dbSkip())
		EndDo

	EndIf

	// restaura area atual
	RestArea(_aAreaSDB)
	RestArea(_aAreaSD3)
	RestArea(_aAreaAtu)

Return