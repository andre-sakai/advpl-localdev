#include "PROTHEUS.CH"   
#include "TOPCONN.CH"  
#include "RWMAKE.CH"
#include "TbiConn.ch"
#include "TbiCode.ch"

// ###########################################################################################################
// Projeto  : Day-Brasil
// Autor    : Fabio Luiz Gesser
// Modulo   : Faturamento
// Função   : M410STTS
// Descrição: Grava os campos de margem do cabecalho e item da nota F2_MARGEM e D2_XMARGEM
// Retorno  : Nenhum.
// ---------+-------------------+-----------------------------------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+-----------------------------------------------------------------------------
// 17/02/16 | Fabio Gesser      | Desenvolvimento Inicial
// ---------+-------------------+-----------------------------------------------------------------------------
// 13/05/16 | Fabio Gesser      | Ajuste para gravar campo E1_DYFLAG1 
// ---------+-------------------+-----------------------------------------------------------------------------
// 09/06/16 | Fabio Gesser      | Incluído novo imposto D2_VFCPDIF
// ---------+-------------------+-----------------------------------------------------------------------------
// 13/07/16 | Fabio Gesser      | Gravo Portador WEB na SE1 
// ---------+-------------------+-----------------------------------------------------------------------------
// 22/12/16 | Fabio Gesser      | Faço a eliminação do pedido na tabela ZAF do BI e limpo flag da SC5 para reprocessar
// ---------+-------------------+-----------------------------------------------------------------------------

User Function M460FIM()

Local _nFatFrete  := GetNewPar( "DY_FATORPV",0 )  //Fator Logistico
Local _cTabPad    := GetNewPar("DY_TABPAD","998")
Local aAreaAT     := GetArea()
Local aAreaD2     := SD2->(GetArea())
Local aAreaSA1    := SA1->(GetArea())
Local aAreaSB1    := SB1->(GetArea())
Local _nValor     := 0.00
Local _nValTabPrc := 0.00
Local _nQtdVen    := 0.00
Local _nFatorLog  := 0.00
Local _nTotICM    := 0.00
Local _nTotPIS    := 0.00
Local _nTotCOF    := 0.00
Local _nTotST     := 0.00
Local _nTotIPI    := 0.00
Local __nTotICM   := 0.00
Local __nTotPIS   := 0.00
Local __nTotCOF   := 0.00
Local __nTotST    := 0.00
Local __nTotIPI   := 0.00
Local __nTotPed   := 0.00
Local __nTotTabPrc:= 0.00
Local cPorWeb     := GetNewPar("DY_PORWEB","PAG")           // Portador para Pedidos WEB
Local cAgeWeb     := GetNewPar("DY_AGEWEB","00000")         // Agencia para Pedidos WEB
Local cConWeb     := GetNewPar("DY_CONWEB","0000000000")    // Conta para Pedidos WEB
Local cWEB        := ""
Local cPed        := Space(06)
Local cAliasTab   := GetNextAlias()
Local cQuery      := ""
Local nNrTit      := 0
Local aTit        := {}
Local aTitAb      := {}
Local cPedMkt     := ""
Local cEntMkt     := ""
Local nX          := 0
Local cAssunto    := ""
Local cMensagem   := ""
Local cEmlTria    := SuperGetMV('DY_VTRIEML',,'fgesser@totvs.com.br;amanda.gregorio@daybrasil.com.br')  // Conta de e-mail para receber notificação pedido venda triangular
Local cUsrInc     := ""
Local cIniLMrg    := "Série: "+SF2->F2_SERIE+" / Documento: "+SF2->F2_DOC+" - Data Base: "+dToc(dDataBase) + Chr(13) + Chr(10)

cIniLMrg += "Conteúdo do parâmetro fator logístico: DY_FATORPV = "+AllTrim(Str(_nFatFrete,12,2)) + Chr(13) + Chr(10)
cIniLMrg += "Conteúdo do parâmetro tabela padrão: DY_TABPAD = "+_cTabPad+ Chr(13) + Chr(10)

Private lMsErroAuto := .F.
Private lMsHelpAuto := .T.

// Posiciono no primeiro ítem da nota.
DbSelectArea("SD2") 
DbSetOrder(3)
If DbSeek(xFilial("SD2") + SF2->F2_DOC + SF2->F2_SERIE + SF2->F2_CLIENTE + SF2->F2_LOJA)
	dbSelectArea("SC5")
	dbSetOrder(1)
	IF dbSeek(xFilial("SC5")+SD2->D2_PEDIDO)
		cWEB := SC5->C5_XWEB
	Endif

	cPed := SD2->D2_PEDIDO

	DbSelectArea("SD2") 
	While !Eof() .And. xFilial("SD2") == SD2->D2_FILIAL .And. SF2->F2_DOC + SF2->F2_SERIE == SD2->D2_DOC + SD2->D2_SERIE
		// Grava informações complementares de processos Judiciais - CDG - Gesser - 02/04/2019

		If cEmpAnt == "01"
			dbSelectArea("CDT")
			dbSetOrder(1)  // CDT_FILIAL + CDT_TPMOV + CDT_DOC + CDT_SERIE + CDT_CLIFOR + CDT_LOJA + CDT_IFCOMP
			If dbSeek(xFilial("CDT")+"S"+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)
				RecLock("CDT",.F.)
			Else
				RecLock("CDT",.T.)
				CDT->CDT_FILIAL	:= xFilial("CDT")
				CDT->CDT_TPMOV	:= "S"
				CDT->CDT_DOC	:= SF2->F2_DOC
				CDT->CDT_SERIE	:= SF2->F2_SERIE
				CDT->CDT_CLIFOR	:= SF2->F2_CLIENTE
				CDT->CDT_LOJA	:= SF2->F2_LOJA
				CDT->CDT_SDOC   := SF2->F2_SERIE
				CDT->CDT_DCCOMP := 'Processo No. 0008490-97.2015.4.03.6100"
			EndIf
			CDT->CDT_IFCOMP := "000001"
			MsUnLock()
			FkCommit()
			
			dbSelectArea("CCF")
			dbSetOrder(1)  // CCF_FILIAL + CCF_NUMERO + CCF_TIPO + CCF_INDAUT + CCF_IDITEM
			dbSeek(xFilial("CCF"))
	
			dbSelectArea("CDG")
			RecLock("CDG",.T.)
			CDG->CDG_FILIAL	:= xFilial("CDF")
			CDG->CDG_TPMOV	:= "S"
			CDG->CDG_DOC	:= SF2->F2_doc
			CDG->CDG_SERIE	:= SF2->F2_serie
			CDG->CDG_CLIFOR	:= SF2->F2_cliente
			CDG->CDG_LOJA	:= SF2->F2_loja
			CDG->CDG_IFCOMP := "000001"
			CDG->CDG_PROCES := CCF->CCF_NUMERO
			CDG->CDG_ITPROC := CCF->CCF_IDITEM
			CDG->CDG_TPPROC := CCF->CCF_TIPO
			CDG->CDG_VALOR  := SD2->D2_VALICM
			CDG->CDG_ITEM   := SD2->D2_ITEM
			CDG->CDG_SDOC   := SF2->F2_SERIE
			MsUnLock()
		Endif

		_nValRet := 0.00
		cLgMrg   := cIniLMrg
        
		DBSELECTAREA("DA1")
		DBSETORDER(1)
		If DbSeek(xFilial("DA1") + "999" + SD2->D2_COD)
			If DA1->DA1_DATVIG <= dDataBase
				_nValTabPrc := DA1->DA1_PRCVEN
				cLgMrg += "Valor tabela de preço 999 do produto: "+SD2->D2_COD+" / "+AllTrim(Str(_nValTabPrc,12,2)) + Chr(13) + Chr(10)
			Else
				cLgMrg += "Valor tabela de preço 999 fora de vigência do produto: "+SD2->D2_COD+" / "+AllTrim(Str(_nValTabPrc,12,2)) + Chr(13) + Chr(10)
			Endif
		Else
			cLgMrg += "Tabela de preço 999 não encontrada para o produto: "+SD2->D2_COD+" / "+AllTrim(Str(_nValTabPrc,12,2)) + Chr(13) + Chr(10)
		Endif

		If _nValTabPrc == 0.00
			// Busco o ultimo preco valido da tabela 998
			cQuery := "SELECT TOP 3 DA1.DA1_PRCVEN " + CRLF
			cQuery += "FROM "+RetSqlName("DA1")+" DA1 " + CRLF
			cQuery += "WHERE DA1.DA1_FILIAL = '"+xFilial("DA1")+"' " + CRLF
			cQuery += "AND   DA1.DA1_CODTAB = '"+_cTabPad+"' " + CRLF
			cQuery += "AND   DA1.DA1_CODPRO = '"+SD2->D2_COD+"' " + CRLF
			cQuery += "AND   DA1.DA1_DATVIG <= '"+dTos(dDataBase)+"' " + CRLF
			cQuery += "AND   DA1.D_E_L_E_T_ = ' ' " + CRLF
			cQuery += "ORDER BY DA1.DA1_DATVIG DESC " + CRLF
	
			If Select( cAliasTab ) > 0; dbSelectArea( cAliasTab ); dbCloseArea(); EndIf
	
			TCQuery cQuery new Alias (cAliasTab)
			TcSetField(cAliasTab,"DA1_PRCVEN","N", 12, 2)
	
			DbSelectArea(cAliasTab)
	
			If !Eof()
				_nValTabPrc := (cAliasTab)->DA1_PRCVEN
				cLgMrg += "Valor tabela de preço "+_cTabPad+" do produto: "+SD2->D2_COD+" / "+AllTrim(Str(_nValTabPrc,12,2))+ Chr(13) + Chr(10)
			Else
				cLgMrg += "Tabela de preço "+_cTabPad+" não encontrada para o produto: "+SD2->D2_COD+" / "+AllTrim(Str(_nValTabPrc,12,2))+ Chr(13) + Chr(10)
			Endif
		Else
			cLgMrg += "Sera usado valor da tabela 999 para o produto: "+SD2->D2_COD+" / "+AllTrim(Str(_nValTabPrc,12,2)) + Chr(13) + Chr(10)
		Endif

		If _nValTabPrc > 0.00
			_nValor     := SD2->D2_TOTAL
			_nQtdVen    := SD2->D2_QUANT
			_nFatorLog  := _nFatFrete
			_nTotICM    := SD2->D2_VALICM + (SD2->D2_DIFAL+SD2->D2_ICMSCOM+SD2->D2_VFCPDIF)   // Incluído soma dos impostos 30/01/16 - Em 07/06/16, voltei o calculo.
			_nTotPIS    := SD2->D2_VALIMP6
			_nTotCOF    := SD2->D2_VALIMP5
			_nTotST     := SD2->D2_ICMSRET
			_nTotIPI    := SD2->D2_VALIPI

			cLgMrg += "CFOP: "+Alltrim(SD2->D2_CF)+" do produto: "+SD2->D2_COD + Chr(13) + Chr(10)

			If !Empty( Alltrim(SD2->D2_CF) ) .AND. Val( Left( Alltrim(SD2->D2_CF) ,1 ) ) > 5 .AND. Val( Left( Alltrim(SD2->D2_CF) ,1 ) ) <> 7
				DBSELECTAREA("SB1")
				DBSETORDER(1)
				DBSEEK(xFilial("SB1")+SD2->D2_COD)

				cLgMrg += "Grupo: "+SB1->B1_GRUPO+" do produto: "+SD2->D2_COD + Chr(13) + Chr(10)

				If !Empty(SB1->B1_GRUPO)
					dbSelectArea("SBM")
					dbSetOrder( 1 )
					//Procura no SBM se o campo de fator contem valor para calculo da margem
					If dbSeek(xFilial("SBM")+SB1->B1_GRUPO)
						_nSICOSO := SBM->BM_DYFATOR
					EndIf
					cLgMrg += "Sicoso: "+Str(_nSICOSO,12,2)+" do produto: "+SD2->D2_COD + Chr(13) + Chr(10)

					If _nSICOSO <> 0
						IF _nFatorLog <> 0
							cLgMrg += "Sequência 1 " + Chr(13) + Chr(10)
							cLgMrg += "((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nSICOSO * _nFatorLog)) / ( _nValor + _nTotST + _nTotIPI ))*100"+Chr(13) + Chr(10)
							cLgMrg += "((( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ) - "+AllTrim(Str(_nTotICM,12,2))+" - "+AllTrim(Str(_nTotPIS,12,2))+" - "+AllTrim(STr(_nTotCOF,12,2))+" - "+AllTrim(Str(_nTotST,12,2))+" - "+AllTrim(Str(_nTotIPI,12,2))+" - (("+AllTrim(Str(_nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nSICOSO,12,2))+" * "+AllTrim(Str(_nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ))*100"+Chr(13) + Chr(10)

							_nValRet:= ((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nSICOSO * _nFatorLog)) / ( _nValor + _nTotST + _nTotIPI ))*100
							cLgMrg += "_nValRet "+AllTrim(Str(_nValRet,12,2))+Chr(13) + Chr(10)

							cLgMrg += "_nValTabPrc * _nSICOSO * _nFatorLog"	        							// TNU Release 23
							cLgMrg += AllTrim(Str(_nValTabPrc,12,2))+" * "+AllTrim(Str(_nSICOSO,12,2))+" * "+AllTrim(Str(_nFatorLog,12,2))
							_nValTabPrc :=  _nValTabPrc * _nSICOSO * _nFatorLog 
							cLgMrg += "_nValTabPrc "+AllTrim(Str(_nValTabPrc,12,2))+Chr(13) + Chr(10)
						Else
							cLgMrg += "Sequência 2 " + Chr(13) + Chr(10)
							cLgMrg += "((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nSICOSO)) / ( _nValor + _nTotST + _nTotIPI ))*100"+Chr(13) + Chr(10)
							cLgMrg += "((( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ) - "+AllTrim(Str(_nTotICM,12,2))+" - "+AllTrim(Str(_nTotPIS,12,2))+" - "+AllTrim(Str(_nTotCOF,12,2))+" - "+AllTrim(Str(_nTotST,12,2))+" - "+AllTrim(Str(_nTotIPI,12,2))+" - (("+AllTrim(Str(_nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nSICOSO,12,2))+")) / ( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ))*100"+Chr(13) + Chr(10)
							_nValRet:= ((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nSICOSO)) / ( _nValor + _nTotST + _nTotIPI ))*100
							cLgMrg += "_nValRet "+AllTrim(Str(_nValRet,12,2))+Chr(13) + Chr(10)

							cLgMrg += "_nValTabPrc * _nSICOSO "+Chr(13) + Chr(10)
							cLgMrg += AllTrim(Str(_nValTabPrc,12,2))+" * "+AllTrim(Str(_nSICOSO,12,2))+" )"+Chr(13) + Chr(10)

							_nValTabPrc :=  _nValTabPrc * _nSICOSO 
							cLgMrg += "_nValTabPrc "+AllTrim(Str(_nValTabPrc,12,2))+Chr(13) + Chr(10)
						Endif
					Else
						IF _nFatorLog <> 0
							cLgMrg += "Sequência 3 " + Chr(13) + Chr(10)
							cLgMrg += "((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nFatorLog)) / ( _nValor + _nTotST + _nTotIPI ))*100"+Chr(13) + Chr(10)
							cLgMrg += "((( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ) - "+AllTrim(Str(_nTotICM,12,2))+" - "+AllTrim(Str(_nTotPIS,12,2))+" - "+AllTrim(Str(_nTotCOF,12,2))+" - "+AllTrim(Str(_nTotST,12,2))+" - "+AllTrim(Str(_nTotIPI,12,2))+" - (("+AllTrim(Str(_nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nFatorLog,12,2))+")) / ("+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ))*100"+Chr(13) + Chr(10)
							_nValRet:= ((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nFatorLog)) / ( _nValor + _nTotST + _nTotIPI ))*100
							cLgMrg += "_nValRet "+AllTrim(Str(_nValRet,12,2))+Chr(13) + Chr(10)

							cLgMrg += "_nValTabPrc * _nFatorLog"+Chr(13) + Chr(10)
							cLgMrg += AllTrim(Str(_nValTabPrc,12,2))+" * "+AllTrim(Str(_nFatorLog,12,2))+Chr(13) + Chr(10)

							_nValTabPrc :=  _nValTabPrc * _nFatorLog
							cLgMrg += "_nValTabPrc "+AllTrim(Str(_nValTabPrc,12,2))+Chr(13) + Chr(10)
						Else
							cLgMrg += "Sequência 4 " + Chr(13) + Chr(10)
							cLgMrg += "((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - (_nValTabPrc*_nQtdVen)) / ( _nValor + _nTotST + _nTotIPI ))*100"+Chr(13) + Chr(10)
							cLgMrg += "((( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ) - "+AllTrim(Str(_nTotICM,12,2))+" - "+AllTrim(Str(_nTotPIS,12,2))+" - "+AllTrim(Str(_nTotCOF,12,2))+" - "+AllTrim(Str(_nTotST,12,2))+" - "+AllTrim(Str(_nTotIPI,12,2))+" - ("+AllTrim(Str(_nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ))*100"+Chr(13) + Chr(10)
							_nValRet:= ((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - (_nValTabPrc*_nQtdVen)) / ( _nValor + _nTotST + _nTotIPI ))*100

							cLgMrg += "_nValRet "+AllTrim(Str(_nValRet,12,2))+Chr(13) + Chr(10)
						Endif
					EndIf
				Else
					IF _nFatorLog <> 0
						cLgMrg += "Sequência 5 " + Chr(13) + Chr(10)
						cLgMrg += "((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nFatorLog)) / ( _nValor + _nTotST + _nTotIPI ))*100"+Chr(13) + Chr(10)
						cLgMrg += "((( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ) - "+AllTrim(Str(_nTotICM,12,2))+" - "+AllTrim(Str(_nTotPIS,12,2))+" - "+AllTrim(Str(_nTotCOF,12,2))+" - "+AllTrim(Str(_nTotST,12,2))+" - "+AllTrim(Str(_nTotIPI,12,2))+" - (("+AllTrim(Str(_nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ))*100"+Chr(13) + Chr(10)
						_nValRet:= ((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nFatorLog)) / ( _nValor + _nTotST + _nTotIPI ))*100
						cLgMrg += "_nValRet "+AllTrim(Str(_nValRet,12,2))+Chr(13) + Chr(10)

						cLgMrg += "_nValTabPrc * _nFatorLog"+Chr(13) + Chr(10)
						cLgMrg += AllTrim(Str(_nValTabPrc,12,2))+" * "+AllTrim(Str(_nFatorLog,12,2))+Chr(13) + Chr(10)

						_nValTabPrc :=  _nValTabPrc * _nFatorLog
						cLgMrg += "_nValTabPrc "+AllTrim(Str(_nValTabPrc,12,2))+Chr(13) + Chr(10)
					Else
						cLgMrg += "Sequência 6 " + Chr(13) + Chr(10)
						cLgMrg += "((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - (_nValTabPrc*_nQtdVen)) / ( _nValor + _nTotST + _nTotIPI ))*100"+Chr(13) + Chr(10)
						cLgMrg += "((( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ) - "+AllTrim(Str(_nTotICM,12,2))+" - "+AllTrim(Str(_nTotPIS,12,2))+" - "+AllTrim(Str(_nTotCOF,12,2))+" - "+AllTrim(Str(_nTotST,12,2))+" - "+AllTrim(Str(_nTotIPI,12,2))+" - ("+AllTrim(Str(_nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ))*100"+Chr(13) + Chr(10)
						_nValRet:= ((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - (_nValTabPrc*_nQtdVen)) / ( _nValor + _nTotST + _nTotIPI ))*100

						cLgMrg += "_nValRet "+AllTrim(Str(_nValRet,12,2))+Chr(13) + Chr(10)
					Endif
				EndIf
			Else
				cLgMrg += "UF da empresa logada: "+SM0->M0_ESTCOB + Chr(13) + Chr(10)
				IF SM0->M0_ESTCOB # "SP"
					DBSELECTAREA("SB1")
					DBSETORDER(1)
					DBSEEK(xFilial("SB1")+SD2->D2_COD)

					cLgMrg += "Grupo: "+SB1->B1_GRUPO+" do produto: "+SD2->D2_COD + Chr(13) + Chr(10)

					If !Empty(SB1->B1_GRUPO)
						dbSelectArea("SBM")
						dbSetOrder( 1 )
						If dbSeek(xFilial("SBM")+SB1->B1_GRUPO)
							_nSICOSO := SBM->BM_DYFATOR
						EndIf
						cLgMrg += "Sicoso: "+Str(_nSICOSO,12,2)+" do produto: "+SD2->D2_COD + Chr(13) + Chr(10)

						If _nSICOSO <> 0
							IF _nFatorLog <> 0
								cLgMrg += "Sequência 7 " + Chr(13) + Chr(10)
								cLgMrg += "((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nSICOSO * _nFatorLog)) / ( _nValor + _nTotST + _nTotIPI ))*100"+Chr(13) + Chr(10)
								cLgMrg += "((( "+Str(_nValor,12,2)+" + "+Str(_nTotST,12,2)+" + "+Str(_nTotIPI,12,2)+" ) - "+Str(_nTotICM,12,2)+" - "+Str(_nTotPIS,12,2)+" - "+STr(_nTotCOF,12,2)+" - "+Str(_nTotST,12,2)+" - "+Str(_nTotIPI,12,2)+" - (("+Str(_nValTabPrc,12,2)+"*"+Str(_nQtdVen,12,2)+") * "+Str(_nSICOSO,12,2)+" * "+Str(_nFatorLog,12,2)+")) / ( "+Str(_nValor,12,2)+" + "+Str(_nTotST,12,2)+" + "+Str(_nTotIPI,12,2)+" ))*100"+Chr(13) + Chr(10)
								_nValRet:= ((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nSICOSO * _nFatorLog)) / ( _nValor + _nTotST + _nTotIPI ))*100

								cLgMrg += "_nValTabPrc * _nSICOSO * _nFatorLog"+Chr(13) + Chr(10)
								cLgMrg += Str(_nValTabPrc,12,2)+" * "+Str(_nSICOSO,12,2)+" * "+Str(_nFatorLog,12,2)+Chr(13) + Chr(10)
								_nValTabPrc :=  _nValTabPrc * _nSICOSO * _nFatorLog 
								cLgMrg += "_nValTabPrc "+AllTrim(Str(_nValTabPrc,12,2))+Chr(13) + Chr(10)
							Else
								cLgMrg += "Sequência 8 " + Chr(13) + Chr(10)
								cLgMrg += "((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nSICOSO)) / ( _nValor + _nTotST + _nTotIPI ))*100"+Chr(13) + Chr(10)
								cLgMrg += "((( "+Str(_nValor,12,2)+" + "+Str(_nTotST,12,2)+" + "+Str(_nTotIPI,12,2)+" ) - "+Str(_nTotICM ,12,2)+"- "+Str(_nTotPIS,12,2)+" - "+Str(_nTotCOF,12,2)+" - "+Str(_nTotST,12,2)+" - "+Str(_nTotIPI,12,2)+" - (("+Str(_nValTabPrc,12,2)+"*"+Str(_nQtdVen,12,2)+") * "+Str(_nSICOSO,12,2)+")) / ( "+Str(_nValor,12,2)+" + "+Str(_nTotST,12,2)+" + "+Str(_nTotIPI,12,2)+" ))*100"+Chr(13) + Chr(10)
								_nValRet:= ((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nSICOSO)) / ( _nValor + _nTotST + _nTotIPI ))*100
								cLgMrg += "_nValRet "+AllTrim(Str(_nValRet,12,2))+Chr(13) + Chr(10)

								cLgMrg += "_nValTabPrc * _nSICOSO "+Chr(13) + Chr(10)
								cLgMrg += Str(_nValTabPrc,12,2)+" * "+Str(_nSICOSO,12,2)+" )"+Chr(13) + Chr(10)
								_nValTabPrc :=  _nValTabPrc * _nSICOSO 
								cLgMrg += "_nValTabPrc "+AllTrim(Str(_nValTabPrc,12,2))+Chr(13) + Chr(10)
							Endif
						Else
							IF _nFatorLog <> 0
								cLgMrg += "Sequência 9 " + Chr(13) + Chr(10)
								cLgMrg += "((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nFatorLog)) / ( _nValor + _nTotST + _nTotIPI ))*100"+Chr(13) + Chr(10)
								cLgMrg += "((( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ) - "+AllTrim(Str(_nTotICM,12,2))+" - "+AllTrim(Str(_nTotPIS,12,2))+" - "+AllTrim(Str(_nTotCOF,12,2))+" - "+AllTrim(Str(_nTotST,12,2))+" - "+AllTrim(Str(_nTotIPI,12,2))+" - (("+AllTrim(Str(_nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ))*100"+Chr(13) + Chr(10)
								_nValRet:= ((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nFatorLog)) / ( _nValor + _nTotST + _nTotIPI ))*100
								cLgMrg += "_nValRet "+AllTrim(Str(_nValRet,12,2))+Chr(13) + Chr(10)

								cLgMrg += "_nValTabPrc * _nFatorLog"+Chr(13) + Chr(10)
								cLgMrg += AllTrim(Str(_nValTabPrc,12,2))+" * "+AllTrim(Str(_nFatorLog,12,2))+Chr(13) + Chr(10)
								_nValTabPrc :=  _nValTabPrc * _nFatorLog
								cLgMrg += "_nValTabPrc "+AllTrim(Str(_nValTabPrc,12,2))+Chr(13) + Chr(10)
							Else
								cLgMrg += "Sequência 10 " + Chr(13) + Chr(10)
								cLgMrg += "((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - (_nValTabPrc*_nQtdVen)) / ( _nValor + _nTotST + _nTotIPI ))*100"+Chr(13) + Chr(10)
								cLgMrg += "((( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ) - "+AllTrim(Str(_nTotICM,12,2))+" - "+AllTrim(Str(_nTotPIS,12,2))+" - "+AllTrim(Str(_nTotCOF,12,2))+" - "+AllTrim(Str(_nTotST,12,2))+" - "+AllTrim(Str(_nTotIPI,12,2))+" - ("+AllTrim(Str(_nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ))*100"+Chr(13) + Chr(10)
								_nValRet:= ((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - (_nValTabPrc*_nQtdVen)) / ( _nValor + _nTotST + _nTotIPI ))*100
								cLgMrg += "_nValRet"+AllTrim(Str(_nValRet,12,2))+Chr(13) + Chr(10)
							Endif
						EndIf
					Else
						IF _nFatorLog <> 0
							cLgMrg += "Sequência 11 " + Chr(13) + Chr(10)
							cLgMrg += "((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nFatorLog)) / ( _nValor + _nTotST + _nTotIPI ))*100"+Chr(13) + Chr(10)
							cLgMrg += "((( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ) - "+AllTrim(Str(_nTotICM,12,2))+" - "+AllTrim(Str(_nTotPIS,12,2))+" - "+AllTrim(Str(_nTotCOF,12,2))+" - "+AllTrim(Str(_nTotST,12,2))+" - "+AllTrim(Str(_nTotIPI,12,2))+" - (("+AllTrim(Str(_nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ))*100"+Chr(13) + Chr(10)
							_nValRet:= ((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nFatorLog)) / ( _nValor + _nTotST + _nTotIPI ))*100
							cLgMrg += "_nValRet "+AllTrim(Str(_nValRet,12,2))+Chr(13) + Chr(10)

							cLgMrg += "_nValTabPrc * _nFatorLog"+Chr(13) + Chr(10)
							cLgMrg += AllTrim(Str(_nValTabPrc,12,2))+" * "+AllTrim(Str(_nFatorLog,12,2))+Chr(13) + Chr(10)

							_nValTabPrc :=  _nValTabPrc * _nFatorLog
							cLgMrg += " _nValTabPrc "+AllTrim(Str(_nValTabPrc,12,2))+Chr(13) + Chr(10)
						Else
							cLgMrg += "Sequência 12 " + Chr(13) + Chr(10)
							cLgMrg += "((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - (_nValTabPrc*_nQtdVen)) / ( _nValor + _nTotST + _nTotIPI ))*100"+Chr(13) + Chr(10)
							cLgMrg += "((( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ) - "+AllTrim(Str(_nTotICM,12,2))+" - "+AllTrim(Str(_nTotPIS,12,2))+" - "+AllTrim(Str(_nTotCOF,12,2))+" - "+AllTrim(Str(_nTotST,12,2))+" - "+AllTrim(Str(_nTotIPI,12,2))+" - ("+AllTrim(Str(_nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ))*100"+Chr(13) + Chr(10)
							_nValRet:= ((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - (_nValTabPrc*_nQtdVen)) / ( _nValor + _nTotST + _nTotIPI ))*100
							cLgMrg += "_nValRet "+AllTrim(Str(_nValRet,12,2))+Chr(13) + Chr(10)
						Endif
					EndIf
				Else
					If _nFatorLog <> 0
						cLgMrg += "Sequência 13 " + Chr(13) + Chr(10)
						cLgMrg += "((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nFatorLog)) / ( _nValor + _nTotST + _nTotIPI ))*100"+Chr(13) + Chr(10)
						cLgMrg += "((( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ) - "+AllTrim(Str(_nTotICM,12,2))+" - "+AllTrim(Str(_nTotPIS,12,2))+" - "+AllTrim(Str(_nTotCOF,12,2))+" - "+AllTrim(Str(_nTotST,12,2))+" - "+AllTrim(Str(_nTotIPI,12,2))+" - (("+AllTrim(Str(_nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ))*100"+Chr(13) + Chr(10)
						_nValRet:= ((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - ((_nValTabPrc*_nQtdVen) * _nFatorLog)) / ( _nValor + _nTotST + _nTotIPI ))*100
						cLgMrg += " _nValRet "+AllTrim(Str(_nValRet,12,2))+Chr(13) + Chr(10)

						cLgMrg += "_nValTabPrc * _nFatorLog"+Chr(13) + Chr(10)
						cLgMrg += AllTrim(Str(_nValTabPrc,12,2))+" * "+AllTrim(Str(_nFatorLog,12,2))+Chr(13) + Chr(10)

						_nValTabPrc :=  _nValTabPrc * _nFatorLog
						cLgMrg += "_nValTabPrc "+AllTrim(Str(_nValTabPrc,12,2))+Chr(13) + Chr(10)
					Else
						cLgMrg += "Sequência 14 " + Chr(13) + Chr(10)
						cLgMrg += "((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - (_nValTabPrc*_nQtdVen)) / ( _nValor + _nTotST + _nTotIPI ))*100"+Chr(13) + Chr(10)
						cLgMrg += "((( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ) - "+AllTrim(Str(_nTotICM,12,2))+" - "+AllTrim(Str(_nTotPIS,12,2))+" - "+AllTrim(Str(_nTotCOF,12,2))+" - "+AllTrim(Str(_nTotST,12,2))+" - "+AllTrim(Str(_nTotIPI,12,2))+" - ("+AllTrim(Str(_nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nValor,12,2))+" + "+AllTrim(Str(_nTotST,12,2))+" + "+AllTrim(Str(_nTotIPI,12,2))+" ))*100"+Chr(13) + Chr(10)

						_nValRet:= ((( _nValor + _nTotST + _nTotIPI ) - _nTotICM - _nTotPIS - _nTotCOF - _nTotST - _nTotIPI - (_nValTabPrc*_nQtdVen)) / ( _nValor + _nTotST + _nTotIPI ))*100
						cLgMrg += "_nValRet "+AllTrim(Str(_nValRet,12,2))+Chr(13) + Chr(10)
					EndIf
				Endif
			EndIf
			__nTotICM   := __nTotICM    + _nTotICM
			__nTotPIS   := __nTotPIS    + _nTotPIS
			__nTotCOF   := __nTotCOF    + _nTotCOF
			__nTotST    := __nTotST     + _nTotST
			__nTotIPI   := __nTotIPI    + _nTotIPI
			__nTotPed   := __nTotPed    + _nValor
			__nTotTabPrc:= __nTotTabPrc + (_nValTabPrc * _nQtdVen)
		Else
			cLgMrg += "Preço base não encontrado para cálculo da margem do produto "+SD2->D2_COD+" / "+AllTrim(Str(_nValTabPrc,12,2)) + Chr(13) + Chr(10)
		EndIf
		If _nValRet > 999.99
			_nValRet := 999.99
		EndIf
		If _nValRet < -99.99
			_nValRet := -99.99
		EndIf

		cLgMrg += "Margem calculada do item "+SD2->D2_ITEM+": "+AllTrim(Str(_nValRet,12,2)) + Chr(13) + Chr(10)

		// Grava campos especificos DAY
		DbSelectArea("SD2")
		RecLock("SD2",.F.)
		SD2->D2_XMARGEM := _nValRet
		SD2->D2_XLGMRG  := cLgMrg
		MsUnLock()

		DbSkip()
	End
Endif

__nValRet:= ((( __nTotPed + __nTotST + __nTotIPI ) - __nTotICM - __nTotPIS - __nTotCOF - __nTotST - __nTotIPI - __nTotTabPrc) / ( __nTotPed + __nTotST + __nTotIPI ))*100

If __nValRet > 999.99
    __nValRet := 999.99
EndIf

If __nValRet < -99.99
    __nValRet := -99.99
EndIf

DBSELECTAREA("SA3")
DBSETORDER(1)
DBSEEK(xFilial("SA3")+SF2->F2_VEND1)

DBSELECTAREA("SF2")
RecLock("SF2",.F.)
SF2->F2_XMARGEM := __nValRet
SF2->F2_CANAL   := SA3->A3_DYCANAL
SF2->F2_REGIO   := SA3->A3_DYREGIO
MsUnLock()


// 13/05/16 - Gravar campo E1_DYFLAG1 = N - Fabio Gesser
DbSelectArea("SE1")
DbSetOrder(1)
DbSeek(xFilial("SE1")+SF2->F2_PREFIXO+SF2->F2_DOC)
While !Eof() .And. xFilial("SE1") == SE1->E1_FILIAL .And. SF2->F2_PREFIXO == SE1->E1_PREFIXO .AND. SF2->F2_DOC == SE1->E1_NUM      
	RecLock("SE1",.F.)    	
	SE1->E1_DYFLAG1 := "N"    		
	MsUnlock()   	          
	DbSkip()    
End 	    


If cWEB == "S" .AND. Alltrim(cEmpAnt) == "01" //validacao da empresa incluido por leila em 15/10/18
   // Gravo portador WEB - Fabio Gesser - 13/07/16
   DbSelectArea("SE1")
   DbSetOrder(1)
   DbSeek(xFilial("SE1")+SF2->F2_PREFIXO+SF2->F2_DOC)
   While !Eof() .And. xFilial("SE1") == SE1->E1_FILIAL .And. SF2->F2_PREFIXO == SE1->E1_PREFIXO .AND. SF2->F2_DOC == SE1->E1_NUM      

         RecLock("SE1",.F.)    	
         SE1->E1_PORTADO :=cPorWeb
         SE1->E1_AGEDEP  :=cAgeWeb	
         SE1->E1_CONTA   :=cConWeb	
         MsUnlock()   	          

         DbSkip()    
   End 	    
   // Fim gravação portador WEB - 13/07/16
Endif


// Faço a eliminação do pedido na tabela ZAF do BI e limpo flag da SC5 para reprocessar scheduler - Fabio Gesser - 22/12/16
If !Empty(cPed)

   DbSelectArea("SC5")
   DbSetOrder(1)
   If DbSeek(xFilial("SC5") + cPed )
      Reclock("SC5",.F.)
      SC5->C5_XENVZAF := "N"
      MSUnlock()
   Endif

   cQuery := "UPDATE "+RetSqlName("ZAF")+" SET D_E_L_E_T_ = '*' "
   cQuery += "WHERE ZAF_FILIAL  = '"+SC5->C5_FILIAL+"' "
   cQuery += "AND   ZAF_EMPRES  = '"+AllTrim(SM0->M0_CODIGO)+"' "
   cQuery += "AND   ZAF_PEDIDO  = '"+cPed+"' "
   cQuery += "AND   D_E_L_E_T_ <> '*' "

   IF TCSQLEXEC(cQuery) < 0
//	  ConOut("M460FIM - "+SF2->F2_DOC + SF2->F2_SERIE+" - Erro update ZAF")					// TNU Release 23
	  U_xConout("M460FIM - "+SF2->F2_DOC + SF2->F2_SERIE+" - Erro update ZAF", ProcName())  // TNU Release 23
   ENDIF
Endif

If Select( cAliasTab ) > 0; dbSelectArea( cAliasTab ); dbCloseArea(); EndIf

// Criação dos titulos AB- para empresa INOVAKASA
If SM0->M0_CODIGO == '09' .OR. (SM0->M0_CODIGO == '01' .AND. SM0->M0_CODFIL == '11' ) //regra filial 11 incluido por leila em 23/10/18

	// Posiciono no pedido
	DbSelectArea("SC5")
	DbSetOrder(1)  // C5_FILIAL + C5_NUM
	DbSeek(xFilial("SC5")+cPed)

	// Pego o numero do pedido do cliente
	DbSelectArea("SC6")
	DbSetOrder(1)  // C6_FILIAL + C6_NUM + C6_ITEM
	DbSeek(xFilial("SC6")+cPed)
	While !Eof() .And. xFilial("SC6") == SC6->C6_FILIAL .And. SC6->C6_NUM == cPed
		If !Empty(SC6->C6_PEDCLI)
			cPedMkt := SC6->C6_PEDCLI
			cEntMkt := SC6->C6_XENTMKT
			Exit
		Endif
		DbSkip()
	End

	// Busco a condição de pagamento para saber se a mesma é de adiantamento
	dbSelectArea("SE4")
	DbSetOrder(1)  // E4_FILIAL + E4_CODIGO
	DbSeek(xFilial("SE4") + SC5->C5_CONDPAG)

	// Gravo parcela 001 quando a mesma for em branco e quando existir somente 1 parcela somente para pedidos sem adiantamento
	IF SE4->E4_CTRADT <> "1"
		DbSelectArea("SE1")
		DbSetOrder(1)  // E1_FILIAL + E1_PREFIXO + E1_NUM
		DbSeek(xFilial("SE1")+SF2->F2_PREFIXO+SF2->F2_DOC)
		While !Eof() .And. xFilial("SE1") == SE1->E1_FILIAL .And. SF2->F2_PREFIXO == SE1->E1_PREFIXO .AND. SF2->F2_DOC == SE1->E1_NUM
			If Empty(SE1->E1_PARCELA)
				Reclock("SE1",.F.)
				SE1->E1_PARCELA := '001'
				MSUnlock()
			Endif
			Exit
		End
	Endif

	// Busco o vendedor no cadastro de custos marketplace
	DbSelectArea("ZAK")
	DbSetOrder(1)  // ZAK_FILIAL + ZAK_VEND
	If DbSeek(xFilial("ZAK") + SF2->F2_VEND1)
		// Busco o numero de parcelas e monto array contendo os titulos para geração do AB-
		DbSelectArea("SE1")
		DbSetOrder(1)  // E1_FILIAL + E1_PREFIXO + E1_NUM
		DbSeek(xFilial("SE1")+SF2->F2_PREFIXO+SF2->F2_DOC)
		While !Eof() .And. xFilial("SE1") == SE1->E1_FILIAL .And. SF2->F2_PREFIXO == SE1->E1_PREFIXO .AND. SF2->F2_DOC == SE1->E1_NUM
			aAdd(aTitAb,{SE1->E1_PREFIXO,;
						SE1->E1_NUM,;
						SE1->E1_PARCELA,;
						SE1->E1_NATUREZ,;
						SE1->E1_CLIENTE,;
						SE1->E1_LOJA,;
						SE1->E1_VENCTO,;
						SE1->E1_VENCREA})
	
			nNrTit += 1

			If !Empty(ZAK->ZAK_PORTAD)
				// Gravo portador quando existir.
				Reclock("SE1",.F.)
				SE1->E1_PORTADO := ZAK->ZAK_PORTAD
				If AllTrim(SE1->E1_TIPO) == "NF"
					SE1->E1_PEDMKP := cPedMkt
					SE1->E1_ENTMKP := cEntMkt
				Endif
				MSUnlock()
			Endif
			DbSkip()
		End

		// Gero título AB- somente quando houver comissão cadastrada na tabela ZAK.
		If ZAK->ZAK_COMIS > 0
			// Calculo o valor do titulo AB- a ser gerado
			nVlrTit := ((SF2->F2_VALFAT * ZAK->ZAK_COMIS) / 100) / nNrTit
			
			If nVlrTit > 0.00
				For nX:=1 to Len(aTitAb)
					aTit := {{ "E1_PREFIXO", aTitAb[nX][1],  Nil },;
							 { "E1_NUM",     aTitAb[nX][2],  Nil },;
						 	 { "E1_PARCELA", aTitAb[nX][3],  Nil },;
						 	 { "E1_TIPO",    "AB-",          Nil },;
						 	 { "E1_NATUREZ", aTitAb[nX][4],  Nil },;
						 	 { "E1_CLIENTE", aTitAb[nX][5],  Nil },;
						 	 { "E1_LOJA",    aTitAb[nX][6],  Nil },;
						 	 { "E1_VENCTO",  aTitAb[nX][7],  Nil },;
						 	 { "E1_VENCREA", aTitAb[nX][8],  Nil },; 
						 	 { "E1_VALOR",   nVlrTit,        Nil },;
						 	 { "E1_PORTADO", ZAK->ZAK_PORTAD,Nil },;
						 	 { "E1_NATUREZ", ZAK->ZAK_NATURE,Nil },;
						 	 { "E1_CCC",     ZAK->ZAK_CC,    Nil } }

					If SE4->E4_CTRADT <> "1"
						MSExecAuto( { |x,y| Fina040( x, y ) }, aTit, 3 ) //Inclusao
						If lMsErroAuto  
							MsgInfo("Ocorreu um erro ao incluir o titulo AB-. Por favor contate o administrador do sistema.", "Erro")
							MostraErro()
						Endif
					Endif
				Next nX
			Endif
		Endif
	Endif
Endif

// Posiciono no pedido
DbSelectArea("SC5")
DbSetOrder(1)  // C5_FILIAL + C5_NUM
DbSeek(xFilial("SC5")+cPed)

// Envia e-mail para venda triangular
If SC5->C5_XVNDTRI == "S"
	DbSelectArea("SA1")
	DbSetOrder(1)  // A1_FILIAL + A1_COD _ A1_LOJA
	DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+AllTrim(SC5->C5_LOJACLI))

	DbSelectArea("SA3")
	DbSetOrder(1)  // A3_FILIAL + A3_COD
	DbSeek(xFilial("SA3") + SC5->C5_VEND1)

	cUsrInc := Substr(SC5->C5_USERLGI,11,1)+Substr(SC5->C5_USERLGI,15,1)+Substr(SC5->C5_USERLGI,2,1)+Substr(SC5->C5_USERLGI,6,1)+; 
               Substr(SC5->C5_USERLGI,10,1)+Substr(SC5->C5_USERLGI,14,1)+Substr(SC5->C5_USERLGI,1,1)+Substr(SC5->C5_USERLGI,5,1)+;
               Substr(SC5->C5_USERLGI,9,1)+Substr(SC5->C5_USERLGI,13,1)+Substr(SC5->C5_USERLGI,17,1)+Substr(SC5->C5_USERLGI,4,1)+; 
               Substr(SC5->C5_USERLGI,8,1)                       

	IF SM0->M0_CODIGO == "01"
		cAssunto := "Day Brasil - Pedido "+SC5->C5_NUM+" venda triangular - Faturado"
	ElseIF SM0->M0_CODIGO == "04"
		cAssunto := "Plastape - Pedido "+SC5->C5_NUM+" venda triangular - Faturado"
	ElseIF SM0->M0_CODIGO == "07"
		cAssunto := "DBCI - Pedido "+SC5->C5_NUM+" venda triangular - Faturado"
	ElseIF SM0->M0_CODIGO == "08"
		cAssunto := "Baueco - Pedido "+SC5->C5_NUM+" venda triangular - Faturado"
	ElseIF SM0->M0_CODIGO == "09"
		cAssunto := "INOVAKASA - Pedido "+SC5->C5_NUM+" venda triangular - Faturado"
	Else
		cAssunto := "Day Brasil - Pedido "+SC5->C5_NUM+" venda triangular - Faturado"
	Endif

	cMensagem := "<i>Prezado, <br> <br>" + CRLF
	cMensagem += "O pedido abaixo foi faturado como venda triangular: <br>" + CRLF
	cMensagem += "Empresa: "+SM0->M0_CODIGO+", Filial: "+SM0->M0_CODFIL+" <br>" + CRLF
	cMensagem += "Nr Pv.: "+SC5->C5_NUM+" <br>" + CRLF
	cMensagem += "Nr e Série NF: "+SF2->F2_DOC+"/"+SF2->F2_SERIE+" <br>" + CRLF
	cMensagem += "Cliente: "+SA1->A1_NOME+" <br>" + CRLF
	cMensagem += "Vendedor: "+SA3->A3_NOME+" <br>" + CRLF
	cMensagem += "Usuário de inclusão: "+AllTrim(UsrRetName(cUsrInc))+" <br> <br>" + CRLF
	cMensagem += "Atenciosamente, <br> <br>"+CRLF
	cMensagem += "<b>Day Brasil S/A</b> </i> <br> <br> <br> <br>" + CRLF
	cMensagem += "NÃO RESPONDER ESTA MENSAGEM, POIS FOI GERADA AUTOMATICAMENTE! <br>" + CRLF

	U_DYENVMAIL("M460FIM", cEmlTria, "", cAssunto, cMensagem, "")
Endif

RestArea(aAreaAT)
RestArea(aAreaD2)
RestArea(aAreaSA1)
RestArea(aAreaSB1)

Return Nil
