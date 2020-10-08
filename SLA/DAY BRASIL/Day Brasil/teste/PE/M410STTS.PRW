#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
#include "TbiConn.ch"
#include "TbiCode.ch"
#INCLUDE "FONT.CH"
#include "topconn.ch"

// ###########################################################################################################
// Projeto  : Day-Brasil
// Autor    : Fabio Luiz Gesser
// Modulo   : Faturamento
// Função   : M410STTS
// Descrição: Grava o campo de margem de lucro do item do pedido.
//            customização se faz necessario devido a permissoes de alguns
//            vendedores. Alguns vendedores nao sera disponibilizado o campo
// Retorno  : Nenhum.
// ---------+-------------------+-----------------------------------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+-----------------------------------------------------------------------------
// 17/02/14 | Fabio Gesser      | Desenvolvimento Inicial
// ---------+-------------------+-----------------------------------------------------------------------------
// 13/05/16 | Fabio Gesser      | Ajuste para gerar SC0 somente com blest=""
// ---------+-------------------+-----------------------------------------------------------------------------
// 19/05/16 | Fabio Gesser      | Bloqueio validacao para pedido tipo P
// ---------+-------------------+-----------------------------------------------------------------------------
// 09/06/16 | Fabio Gesser      | Incluído novo imposto IT_VALFECP
// ---------+-------------------+-----------------------------------------------------------------------------
// 08/07/16 | Fabio Gesser      | Gravo o campo C9_XWEB igual ao C5_XWEB
// ---------+-------------------+-----------------------------------------------------------------------------
// 05/10/16 | Leila Koda        | Eliminado regra da checagem do crédito especifico Day-Brasil
// ---------+-------------------+-----------------------------------------------------------------------------
// 10/11/16 | Fabio Gesser      | Incluído regra para gravação do campo C5_DYFLAG
// ---------+-------------------+-----------------------------------------------------------------------------
// 11/11/16 | Fabio Gesser      | Não permitir gravar o campo C5_DYFLAG quando disparado pela reserva autoamtica
// ---------+-------------------+-----------------------------------------------------------------------------
// 11/11/16 | Fabio Gesser      | Criado parametro de limite de margem e valor pedido para gravação do D5_DYFLAG
// ---------+-------------------+-----------------------------------------------------------------------------
// 21/11/16 | Fabio Gesser      | Criado nova validacao para gravação do D5_DYFLAG = B. Quando campo novo E4_XCREDIT = S
// ---------+-------------------+-----------------------------------------------------------------------------
// 08/12/16 | Fabio Gesser      | Não grava C5_DYFLAG quando pedido = brinde ou amostra
// ---------+-------------------+-----------------------------------------------------------------------------
// 08/12/16 | Fabio Gesser      | Eliminado frete + despesas + seguro no calculo da margem
// ---------+-------------------+-----------------------------------------------------------------------------
// 09/12/16 | Fabio Gesser      | Gravo flag C5_XENVZAF quando pedido alterado ou incluído para envio ao BI
// ---------+-------------------+-----------------------------------------------------------------------------
// 22/12/16 | Fabio Gesser      | Faço a eliminação do pedido na tabela ZAF do BI e limpo flag da SC5 para reprocessar
// ---------+-------------------+-----------------------------------------------------------------------------
// 12/01/17 | Fabio Gesser      | Validação da chamada DYA450AUT junto com DYA440AUT
// ---------+-------------------+-----------------------------------------------------------------------------
// 23/03/17 | Fabio Gesser      | Eliminado geração dos itens faltantes (vassourinha)
// ---------+-------------------+-----------------------------------------------------------------------------
// 23/03/17 | Fabio Gesser      | Ajuste na gravação do campo C5_DYFLAG referente a alteracao cond.pagto.
// ---------+-------------------+-----------------------------------------------------------------------------
// 11/04/17 | Fabio Gesser      | Eliminado tratamento do campo C5_DYFLAG e incluido no PE MTA410
// ---------+-------------------+-----------------------------------------------------------------------------
// 01/06/17 | Fabio Gesser      | Eliminado gravação do campo C9_XMOTBCR pois nao é mais usado
// ---------+-------------------+-----------------------------------------------------------------------------

User Function M410STTS()

Local _aAreaSC5  := SC5->(GetArea() )
Local _aAreaSC6  := SC6->(GetArea() )
Local _cCFOP     := ""
Local _nTotPed   := 0
Local _nQtdVen   := 0
Local nValTabPrc:= 0
Local _nSICOSO   := 0
Local _cTabPad   := SuperGetMV("DY_TABPAD",,"998")

// Total impostos com frete
Local nTICM1     := 0.00
Local nTPIS1     := 0.00
Local nTCOF1     := 0.00
Local nTST1      := 0.00
Local nTIPI1     := 0.00

// Total impostos sem frete
Local nTICM2     := 0.00
Local nTPIS2     := 0.00
Local nTCOF2     := 0.00
Local nTST2      := 0.00
Local nTIPI2     := 0.00

Local nTPed      := 0.00
Local nTotTabPrc := 0.00
Local nBLQPRZD   := SuperGetMV("DY_BLQPRZD",,"999")
Local nMargVld   := SuperGetMV("DY_MARGVLD",,10)       // Margem limite para aprovação do pedido
Local nVlrTLib   := SuperGetMV("DY_VLRTLIB",,100000)   // Valor total para aprovação do pedido
Local lCredito   := .F.
Local cAliasTab  := GetNextAlias()
Local cQuery     := ""
Local nXDescont  := 0
Local nXValDesc  := 0

Local nFatorLog  := GetNewPar( "DY_FATORPV",0 )  //Fator Logistico
Local nTotICM    := 0.00
Local nTotPIS    := 0.00
Local nTotCOF    := 0.00
Local nTotST     := 0.00
Local nTotIPI    := 0.00
Local aTransp    := {"", ""}
Local nValRet1   := 0
Local nValRet2   := 0

// Total impostos com frete
Local nTotICM1   := 0.00
Local nTotPIS1   := 0.00
Local nTotCOF1   := 0.00
Local nTotST1    := 0.00
Local nTotIPI1   := 0.00

// Total impostos sem frete
Local nTotICM2   := 0.00
Local nTotPIS2   := 0.00
Local nTotCOF2   := 0.00
Local nTotST2    := 0.00
Local nTotIPI2   := 0.00

// Log cálculo da margem com e sem frete.
Local cLgMrg     := ""
Local cLgMrg1    := ""
Local cLgMrg2    := ""

// Bloqueia o pedido quando o preço de venda menor que o sugerido.
Local lBlqTab    := .F.

If IsInCallStack("u_X410Resid")
   Return
Endif

If (INCLUI .or. ALTERA)
   If !SC5->C5_TIPO $ "DBICP"  // Não checar credito quando tipo do pedido igual D/B - Gesser 18/03/15
      IF AllTrim(SC5->C5_DYLIBER) <> "" .AND. SC5->C5_DYCANPV <> '01'

         // Fabio Gesser 24/09/15
         // Gero SC9 somente da que falta a liberar porem esta quantidade estará com BLEST = 03, est acustomização se faz necessaria
         // para que esta diferença esteja totalmente na SC9. O Cliente não usa relatorio de pedidos em aberto. Eles se baseam na SC9.

         cQuery := "SELECT SC6.C6_NUM, SC6.C6_PRODUTO, SC6.C6_ITEM, SC6.C6_QTDVEN, SC6.C6_QTDENT, SUM(SC9.C9_QTDLIB) QTDLIB "
         cQuery += "FROM "+RetSqlName("SC6")+" SC6 "

         cQuery += "LEFT JOIN "+RetSqlName("SC9")+" SC9 ON SC9.C9_FILIAL  = SC6.C6_FILIAL "
         cQuery += "                                   AND SC9.C9_PEDIDO  = SC6.C6_NUM "
         cQuery += "                                   AND SC9.C9_PRODUTO = SC6.C6_PRODUTO "
         cQuery += "                                   AND SC9.C9_ITEM    = SC6.C6_ITEM "
         cQuery += "                                   AND SC9.C9_BLEST   <> '10' "
         cQuery += "                                   AND SC9.D_E_L_E_T_ <> '*' "

         cQuery += "WHERE SC6.C6_FILIAL  = '"+xFilial("SC6")+"' "
         cQuery += "AND   SC6.C6_NUM     = '"+SC5->C5_NUM+"' "
         cQuery += "AND   SC6.D_E_L_E_T_ <> '*' "

         cQuery += "GROUP BY SC6.C6_NUM, SC6.C6_PRODUTO, SC6.C6_ITEM, SC6.C6_QTDVEN, SC6.C6_QTDENT "

         If Select("TRB") > 0 ;  TRB->( dbCloseArea() ) ;  EndIf

         TcQuery cQuery New Alias "TRB"

         TcSetField("TRB","C6_QTDVEN","N",12,2)
         TcSetField("TRB","C6_QTDENT","N",12,2)
         TcSetField("TRB","QTDLIB"   ,"N",12,2)

         lRefazCrd := .F.

         DbSelectArea("SA1")
         DbSetOrder(1)
         DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)

         nTotalPedido := 0.00
         DBSELECTAREA("SC6")
         DBSETORDER(1)
         DBSEEK(XFILIAL("SC6")+M->C5_NUM)
         WHILE !EOF() .AND. xFilial("SC6") == SC6->C6_FILIAL .AND. SC6->C6_NUM == M->C5_NUM
               nTotalPedido    := nTotalPedido + SC6->C6_VALOR
               nXDescont        := SC6->C6_DESCONT
               nXValDesc        := SC6->C6_VALDESC

               If SC6->C6_DESCONT+SC6->C6_VALDESC > 0
	               RecLock("SC6",.F.)
	               SC6->C6_XDESC   := nXDescont
	               SC6->C6_XVLDESC := nXValDesc
	               SC6->C6_DESCONT := 0
	               SC6->C6_VALDESC := 0
	               MsUnlock()
               Endif

               DbSkip()
         End

         SELECT TRB
         DbGoTop()
         While !Eof()
               DBSELECTAREA("SC6")
               DBSETORDER(1)
               IF DBSEEK(XFILIAL("SC6")+TRB->C6_NUM+TRB->C6_ITEM+TRB->C6_PRODUTO)
                  IF (TRB->C6_QTDVEN-TRB->C6_QTDENT)-TRB->QTDLIB > 0.00
                     If Upper(FUNNAME()) $ "MATA410|FATA320"
                        MaLibDoFat(SC6->(RecNo()),(TRB->C6_QTDVEN-TRB->C6_QTDENT)-TRB->QTDLIB,.T.     ,.F.     ,.F.    ,.F.   ,.F.    ,.F.      ,    ,      ,          ,.F.      ,        ,        ,)
     			        MaAvalSC9("SC9",6, , ,.T., ,.T.,Nil,)
                        cBlqCred := ""
                        lCredito := MaAvalCred(SA1->A1_COD, SA1->A1_LOJA, nTotalPedido, 1, .T., @cBlqCred )

                        Select SC9
                        Reclock("SC9",.f.)
                        SC9->C9_BLCRED  := cBlqCred
                        MSUnlock()

                        If SC6->C6_QTDLIB == 0
                           lRefazCrd := .T.
                        Endif
                     Endif
                  Endif
               Endif
               Select TRB
               dbSkip()
         EndDo

         // Fim customizacao geração da diferença na SC9 - Fabio Gesser 24/09/15

      Endif
   Endif
Endif


// Gravo o campo C9_XWEB igual ao C5_XWEB
cQuery := "UPDATE "+RetSqlName("SC9")+" SET C9_XWEB = '"+SC5->C5_XWEB+"' "
cQuery += "WHERE C9_FILIAL  = '"+SC5->C5_FILIAL+"' "
cQuery += "AND   C9_PEDIDO  = '"+SC5->C5_NUM+"' "
cQuery += "AND   D_E_L_E_T_ <> '*' "

IF TCSQLEXEC(cQuery) < 0
   U_xConout("Erro Update SC9 campo C9_XWEB = C5_XWEB", ProcName())
ENDIF
// Fim - 08/07/2016


// Pega o valor total do pedido para calculo do Frete proporcinal ao item - Fabio Gesser - 08/07/2016
nTotLiq := 0.00

DBSELECTAREA("SC6")
DBSETORDER(1)
DBSEEK(XFILIAL("SC6")+M->C5_NUM)
WHILE !EOF() .AND. xFilial("SC6") == SC6->C6_FILIAL .AND. SC6->C6_NUM == M->C5_NUM
      nTotLiq := nTotLiq + SC6->C6_VALOR
      DbSkip()
End
// Fim - 08/07/2016


// Posiciona no cliente
dbSelectArea("SA1")
dbSetOrder(1)
MsSeek(xFilial("SA1")+If(!Empty(M->C5_CLIENTE),M->C5_CLIENTE,M->C5_CLIENTE)+M->C5_LOJACLI)

// Posiciono na condição de pagamento
dbSelectArea("SE4")
dbSetOrder(1)
MsSeek(xFilial("SE4")+M->C5_CONDPAG)

// Configuração de frete.
DbSelectArea("SA4")
dbSetOrder(1)  // A4_FILIAL, A4_COD.
If msSeek(xFilial("SA4") + M->C5_TRANSP, .F.)
	aTransp[1] := SA4->A4_EST
	aTransp[2] := SA4->A4_TPTRANS
Endif

DBSELECTAREA("SC6")
DBSETORDER(1)
DBSEEK(XFILIAL("SC6")+M->C5_NUM)
WHILE !EOF() .AND. xFilial("SC6") == SC6->C6_FILIAL .AND. SC6->C6_NUM == M->C5_NUM

	cLgMrg := "Pedido: "+SC6->C6_NUM+" - Produto: "+AllTrim(SC6->C6_PRODUTO)+" - Item: "+SC6->C6_ITEM+" - Data Alteração: "+dToc(dDataBase)+" - Hora: "+Time()+" - Usuário: "+AllTrim(cUserName) + Chr(13) + Chr(10)
	cLgMrg += "Conteúdo do parâmetro fator logístico: DY_FATORPV = "+AllTrim(Str(nFatorLog,12,2)) + Chr(13) + Chr(10)
	cLgMrg += "Conteúdo do parâmetro tabela padrão: DY_TABPAD = "+_cTabPad+ Chr(13) + Chr(10)

      DBSELECTAREA("DA1")
      DBSETORDER(1)
      If DbSeek(xFilial("DA1") + "999" + SC6->C6_PRODUTO)
       	 If DA1->DA1_DATVIG <= dDataBase
            nValTabPrc := DA1->DA1_PRCVEN
            cLgMrg += "Valor tabela de preço 999 do produto: "+SC6->C6_PRODUTO+" / "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
         Else
            cLgMrg += "Valor tabela de preço 999 fora de vigência do produto: "+SC6->C6_PRODUTO+" / "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
         Endif
      Else
         cLgMrg += "Tabela de preço 999 não encontrada para o produto: "+SC6->C6_PRODUTO+" / "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
      Endif

      If nValTabPrc == 0.00
	      // Busco o ultimo preco valido da tabela 998
	      cQuery := "SELECT TOP 3 DA1.DA1_PRCVEN " + CRLF
	      cQuery += "FROM "+RetSqlName("DA1")+" DA1 " + CRLF
	      cQuery += "WHERE DA1.DA1_FILIAL = '"+xFilial("DA1")+"' " + CRLF
	      cQuery += "AND   DA1.DA1_CODTAB = '"+_cTabPad+"' " + CRLF
	      cQuery += "AND   DA1.DA1_CODPRO = '"+SC6->C6_PRODUTO+"' " + CRLF
	      cQuery += "AND   DA1.DA1_DATVIG <= '"+dTos(dDatabase)+"' " + CRLF
	      cQuery += "AND   DA1.D_E_L_E_T_ = ' ' " + CRLF
	      cQuery += "ORDER BY DA1.DA1_DATVIG DESC " + CRLF

	      If Select( cAliasTab ) > 0; dbSelectArea( cAliasTab ); dbCloseArea(); EndIf

	      TCQuery cQuery new Alias (cAliasTab)
	      TcSetField(cAliasTab,"DA1_PRCVEN","N", 12, 2)

	      DbSelectArea(cAliasTab)
	      If !Eof()
             nValTabPrc := (cAliasTab)->DA1_PRCVEN
             cLgMrg += "Valor tabela de preço "+_cTabPad+" do produto: "+SC6->C6_PRODUTO+" / "+AllTrim(Str(nValTabPrc,12,2))+ Chr(13) + Chr(10)
	      Else
	      	 cLgMrg += "Tabela de preço "+_cTabPad+" não encontrada para o produto: "+SC6->C6_PRODUTO+" / "+AllTrim(Str(nValTabPrc,12,2))+ Chr(13) + Chr(10)
	      Endif
	  Else
	      cLgMrg += "Sera usado valor da tabela 999 para o produto: "+SC6->C6_PRODUTO+" / "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
      Endif

      If nValTabPrc > 0.00
         _nTotPed    := SC6->C6_VALOR
         _nQtdVen    := SC6->C6_QTDVEN

         // Retorna pergunta untilizada no momento.
         Pergunte('MTA410    ',.F.)

		 // Posiciona o produto
		 DbSelectArea("SB1")
		 dbSetOrder(1)  // B1_FILIAL, B1_COD.
		 msSeek(xFilial("SB1") + SC6->C6_PRODUTO)

		 // Posiciona na tes
		 DbSelectArea("SF4")
		 dbSetOrder(1)  // F4_FILIAL, F4_CODIGO.
		 msSeek(xFilial("SF4") + SC6->C6_TES)

          // Busca valores dos impostos com frete
		 nTotICM    := 0.00
		 nTotPIS    := 0.00
		 nTotCOF    := 0.00
		 nTotST     := 0.00
		 nTotIPI    := 0.00
         U_DYPEDImp(nTotLiq, MV_PAR04, @nTotICM, @nTotPIS, @nTotCOF, @nTotST, @nTotIPI, aTransp, .T.)
		 nTotICM1   := nTotICM
		 nTotPIS1   := nTotPIS
		 nTotCOF1   := nTotCOF
		 nTotST1    := nTotST
		 nTotIPI1   := nTotIPI

          // Busca valores dos impostos sem frete
		 nTotICM    := 0.00
		 nTotPIS    := 0.00
		 nTotCOF    := 0.00
		 nTotST     := 0.00
		 nTotIPI    := 0.00
         U_DYPEDImp(nTotLiq, MV_PAR04, @nTotICM, @nTotPIS, @nTotCOF, @nTotST, @nTotIPI, aTransp, .F.)
		 nTotICM2   := nTotICM
		 nTotPIS2   := nTotPIS
		 nTotCOF2   := nTotCOF
		 nTotST2    := nTotST
		 nTotIPI2   := nTotIPI

         _cCFOP     := Alltrim( SC6->C6_CF )

		cLgMrg      += "CFOP: "+Alltrim(SC6->C6_CF)+" do produto: "+SC6->C6_PRODUTO + Chr(13) + Chr(10)

		If !Empty( _cCFOP ) .AND. Val( Left( _cCFOP ,1 ) ) > 5 .AND. Val( Left( _cCFOP ,1 ) ) <> 7

			cLgMrg += "Grupo: "+SB1->B1_GRUPO+" do produto: "+SC6->C6_PRODUTO + Chr(13) + Chr(10)

			If !Empty(SB1->B1_GRUPO)
				dbSelectArea("SBM")
				dbSetOrder( 1 )
				If dbSeek(xFilial("SBM")+SB1->B1_GRUPO)
				   _nSICOSO := SBM->BM_DYFATOR
				EndIf

				cLgMrg  += "Sicoso: "+Str(_nSICOSO,12,2)+" do produto: "+SC6->C6_PRODUTO + Chr(13) + Chr(10)
				cLgMrg1 := cLgMrg
				cLgMrg2 := cLgMrg

				If _nSICOSO <> 0
                   IF nFatorLog <> 0
                      cLgMrg1 += "Seção 1" + Chr(13) + Chr(10)
                      cLgMrg2 += "Seção 1" + Chr(13) + Chr(10)
                      cLgMrg1 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * _nSICOSO * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
                      cLgMrg1 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ) - "+AllTrim(Str(nTotICM1,12,2))+" - "+AllTrim(Str(nTotPIS1,12,2))+" - "+AllTrim(Str(nTotCOF1,12,2))+" - "+AllTrim(Str(nTotST1,12,2))+" - "+AllTrim(Str(nTotIPI1,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nSICOSO,12,2))+" * "+AllTrim(Str(nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ))*100" + Chr(13) + Chr(10)
                      cLgMrg2 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ) - "+AllTrim(Str(nTotICM2,12,2))+" - "+AllTrim(Str(nTotPIS2,12,2))+" - "+AllTrim(Str(nTotCOF2,12,2))+" - "+AllTrim(Str(nTotST2,12,2))+" - "+AllTrim(Str(nTotIPI2,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nSICOSO,12,2))+" * "+AllTrim(Str(nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ))*100" + Chr(13) + Chr(10)

		              nValRet1 := ((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * _nSICOSO * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100
		              nValRet2 := ((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * _nSICOSO * nFatorLog)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100

                      cLgMrg1 += "nValRet1 = "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
                      cLgMrg2 += "nValRet2 = "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)

                      cLgMrg1 += "nValTabPrc :=  nValTabPrc * _nSICOSO * nFatorLog" + Chr(13) + Chr(10)
                      cLgMrg2 += "nValTabPrc :=  nValTabPrc * _nSICOSO * nFatorLog" + Chr(13) + Chr(10)
                      cLgMrg1 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(_nSICOSO,12,2))+" * "+AllTrim(Str(nFatorLog,12,2))+ Chr(13) + Chr(10)
                      cLgMrg2 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(_nSICOSO,12,2))+" * "+AllTrim(Str(nFatorLog,12,2))+ Chr(13) + Chr(10)

                      nValTabPrc :=  nValTabPrc * _nSICOSO * nFatorLog
                      cLgMrg1 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                      cLgMrg2 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                   Else
                      cLgMrg1 += "Seção 2" + Chr(13) + Chr(10)
                      cLgMrg2 += "Seção 2" + Chr(13) + Chr(10)
                      cLgMrg1 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * _nSICOSO)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
                      cLgMrg2 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * _nSICOSO * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
                      cLgMrg1 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ) - "+AllTrim(Str(nTotICM1,12,2))+" - "+AllTrim(Str(nTotPIS1,12,2))+" - "+AllTrim(Str(nTotCOF1,12,2))+" - "+AllTrim(Str(nTotST1,12,2))+" - "+AllTrim(Str(nTotIPI1,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nSICOSO,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ))*100" + Chr(13) + Chr(10)
                      cLgMrg2 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ) - "+AllTrim(Str(nTotICM2,12,2))+" - "+AllTrim(Str(nTotPIS2,12,2))+" - "+AllTrim(Str(nTotCOF2,12,2))+" - "+AllTrim(Str(nTotST2,12,2))+" - "+AllTrim(Str(nTotIPI2,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nSICOSO,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ))*100" + Chr(13) + Chr(10)

				      nValRet1 := ((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * _nSICOSO)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100
				      nValRet2 := ((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * _nSICOSO)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100

                      cLgMrg1 += "nValRet1 = "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
                      cLgMrg2 += "nValRet2 = "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)

                      cLgMrg1 += "nValTabPrc :=  nValTabPrc * _nSICOSO" + Chr(13) + Chr(10)
                      cLgMrg2 += "nValTabPrc :=  nValTabPrc * _nSICOSO" + Chr(13) + Chr(10)
                      cLgMrg1 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(_nSICOSO,12,2)) + Chr(13) + Chr(10)
                      cLgMrg2 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(_nSICOSO,12,2)) + Chr(13) + Chr(10)

                      nValTabPrc :=  nValTabPrc * _nSICOSO
                      cLgMrg1 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                      cLgMrg2 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                   Endif
				Else
                   IF nFatorLog <> 0
                      cLgMrg1 += "Seção 3" + Chr(13) + Chr(10)
                      cLgMrg2 += "Seção 3" + Chr(13) + Chr(10)
					  cLgMrg1 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
					  cLgMrg2 += "((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100" + Chr(13) + Chr(10)
					  cLgMrg1 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ) - "+AllTrim(Str(nTotICM1,12,2))+" - "+AllTrim(Str(nTotPIS1,12,2))+" - "+AllTrim(Str(nTotCOF1,12,2))+" - "+AllTrim(Str(nTotST1,12,2))+" - "+AllTrim(Str(nTotIPI1,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ))*100" + Chr(13) + Chr(10)
					  cLgMrg2 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ) - "+AllTrim(Str(nTotICM2,12,2))+" - "+AllTrim(Str(nTotPIS2,12,2))+" - "+AllTrim(Str(nTotCOF2,12,2))+" - "+AllTrim(Str(nTotST2,12,2))+" - "+AllTrim(Str(nTotIPI2,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ))*100" + Chr(13) + Chr(10)

					  nValRet1 := ((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100
					  nValRet2 := ((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100

                      cLgMrg1 += "nValRet1 = "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
                      cLgMrg2 += "nValRet2 = "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)

					  cLgMrg1 += "nValTabPrc :=  nValTabPrc * nFatorLog" + Chr(13) + Chr(10)
					  cLgMrg2 += "nValTabPrc :=  nValTabPrc * nFatorLog" + Chr(13) + Chr(10)
                      cLgMrg1 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(nFatorLog,12,2)) + Chr(13) + Chr(10)
                      cLgMrg2 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(nFatorLog,12,2)) + Chr(13) + Chr(10)

                      nValTabPrc :=  nValTabPrc * nFatorLog
                      cLgMrg1 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                      cLgMrg2 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                   Else
                      cLgMrg1 += "Seção 4" + Chr(13) + Chr(10)
                      cLgMrg2 += "Seção 4" + Chr(13) + Chr(10)
					  cLgMrg1 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
					  cLgMrg2 += "((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100" + Chr(13) + Chr(10)
					  cLgMrg1 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ) - "+AllTrim(Str(nTotICM1,12,2))+" - "+AllTrim(Str(nTotPIS1,12,2))+" - "+AllTrim(Str(nTotCOF1,12,2))+" - "+AllTrim(Str(nTotST1,12,2))+" - "+AllTrim(Str(nTotIPI1,12,2))+" - ("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ))*100" + Chr(13) + Chr(10)
					  cLgMrg2 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ) - "+AllTrim(Str(nTotICM2,12,2))+" - "+AllTrim(Str(nTotPIS2,12,2))+" - "+AllTrim(Str(nTotCOF2,12,2))+" - "+AllTrim(Str(nTotST2,12,2))+" - "+AllTrim(Str(nTotIPI2,12,2))+" - ("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ))*100" + Chr(13) + Chr(10)

					  nValRet1 := ((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100
					  nValRet2 := ((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100

                      cLgMrg1 += "nValRet1 = "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
                      cLgMrg2 += "nValRet2 = "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)
                   Endif
				EndIf
			Else
			   cLgMrg1 := cLgMrg
			   cLgMrg2 := cLgMrg

                IF nFatorLog <> 0
                   cLgMrg1 += "Seção 5" + Chr(13) + Chr(10)
                   cLgMrg2 += "Seção 5" + Chr(13) + Chr(10)
                   cLgMrg1 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
                   cLgMrg2 += "((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100" + Chr(13) + Chr(10)
                   cLgMrg1 += "((( "+AllTrim(Str(nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ) - "+AllTrim(Str(nTotICM1,12,2))+" - "+AllTrim(Str(nTotPIS1,12,2))+" - "+AllTrim(Str(nTotCOF1,12,2))+" - "+AllTrim(Str(nTotST1,12,2))+" - "+AllTrim(Str(nTotIPI1,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ))*100" + Chr(13) + Chr(10)
                   cLgMrg2 += "((( "+AllTrim(Str(nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ) - "+AllTrim(Str(nTotICM2,12,2))+" - "+AllTrim(Str(nTotPIS2,12,2))+" - "+AllTrim(Str(nTotCOF2,12,2))+" - "+AllTrim(Str(nTotST2,12,2))+" - "+AllTrim(Str(nTotIPI2,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ))*100" + Chr(13) + Chr(10)

				   nValRet1 := ((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100
				   nValRet2 := ((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100

                   cLgMrg1 += "nValRet1 = "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
                   cLgMrg2 += "nValRet2 = "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)

				   cLgMrg1 += "nValTabPrc :=  nValTabPrc * nFatorLog" + Chr(13) + Chr(10)
				   cLgMrg2 += "nValTabPrc :=  nValTabPrc * nFatorLog" + Chr(13) + Chr(10)
                   cLgMrg1 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(nFatorLog,12,2)) + Chr(13) + Chr(10)
                   cLgMrg2 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(nFatorLog,12,2)) + Chr(13) + Chr(10)

                   nValTabPrc :=  nValTabPrc * nFatorLog
                   cLgMrg1 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                   cLgMrg2 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                Else
                   cLgMrg1 += "Seção 6" + Chr(13) + Chr(10)
                   cLgMrg2 += "Seção 6" + Chr(13) + Chr(10)
				   cLgMrg1 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
				   cLgMrg2 += "((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100" + Chr(13) + Chr(10)
				   cLgMrg1 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ) - "+AllTrim(Str(nTotICM1,12,2))+" - "+AllTrim(Str(nTotPIS1,12,2))+" - "+AllTrim(Str(nTotCOF1,12,2))+" - "+AllTrim(Str(nTotST1,12,2))+" - "+AllTrim(Str(nTotIPI1,12,2))+" - ("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ))*100" + Chr(13) + Chr(10)
				   cLgMrg2 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ) - "+AllTrim(Str(nTotICM2,12,2))+" - "+AllTrim(Str(nTotPIS2,12,2))+" - "+AllTrim(Str(nTotCOF2,12,2))+" - "+AllTrim(Str(nTotST2,12,2))+" - "+AllTrim(Str(nTotIPI2,12,2))+" - ("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ))*100" + Chr(13) + Chr(10)

			       nValRet1 := ((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100
			       nValRet2 := ((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100

                   cLgMrg1 += "nValRet1 = "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
                   cLgMrg2 += "nValRet2 = "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)
                Endif
			EndIf
		 Else
			cLgMrg += "UF da empresa logada: "+SM0->M0_ESTCOB + Chr(13) + Chr(10)
		    IF SM0->M0_ESTCOB # "SP"
			   If !Empty(SB1->B1_GRUPO)
				   dbSelectArea("SBM")
				   dbSetOrder( 1 )
				   If dbSeek(xFilial("SBM")+SB1->B1_GRUPO)
				      _nSICOSO := SBM->BM_DYFATOR
				   EndIf

				   cLgMrg += "Grupo: "+SB1->B1_GRUPO+" do produto: "+SC6->C6_PRODUTO + Chr(13) + Chr(10)
				   cLgMrg += "Sicoso: "+Str(_nSICOSO,12,2)+" do produto: "+SC6->C6_PRODUTO + Chr(13) + Chr(10)

				   cLgMrg1 := cLgMrg
				   cLgMrg2 := cLgMrg

				   If _nSICOSO <> 0
                      IF nFatorLog <> 0
                         cLgMrg1 += "Seção 7" + Chr(13) + Chr(10)
                         cLgMrg2 += "Seção 7" + Chr(13) + Chr(10)
                         cLgMrg1 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * _nSICOSO * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
                         cLgMrg2 += "((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * _nSICOSO * nFatorLog)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100" + Chr(13) + Chr(10)
                         cLgMrg1 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ) - "+AllTrim(Str(nTotICM1,12,2))+" - "+AllTrim(Str(nTotPIS1,12,2))+" - "+AllTrim(Str(nTotCOF1,12,2))+" - "+AllTrim(Str(nTotST1,12,2))+" - "+AllTrim(Str(nTotIPI1,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nSICOSO,12,2))+" * "+AllTrim(Str(nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ))*100" + Chr(13) + Chr(10)
                         cLgMrg2 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ) - "+AllTrim(Str(nTotICM2,12,2))+" - "+AllTrim(Str(nTotPIS2,12,2))+" - "+AllTrim(Str(nTotCOF2,12,2))+" - "+AllTrim(Str(nTotST2,12,2))+" - "+AllTrim(Str(nTotIPI2,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nSICOSO,12,2))+" * "+AllTrim(Str(nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ))*100" + Chr(13) + Chr(10)

				         nValRet1 := ((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * _nSICOSO * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100
				         nValRet2 := ((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * _nSICOSO * nFatorLog)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100

                         cLgMrg1 += "nValRet1 = "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
                         cLgMrg2 += "nValRet2 = "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)

                         cLgMrg1 += "nValTabPrc :=  nValTabPrc * _nSICOSO * nFatorLog" + Chr(13) + Chr(10)
                         cLgMrg2 += "nValTabPrc :=  nValTabPrc * _nSICOSO * nFatorLog" + Chr(13) + Chr(10)
                         cLgMrg1 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(_nSICOSO,12,2))+" * "+AllTrim(Str(nFatorLog,12,2))+ Chr(13) + Chr(10)
                         cLgMrg2 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(_nSICOSO,12,2))+" * "+AllTrim(Str(nFatorLog,12,2))+ Chr(13) + Chr(10)

                         nValTabPrc :=  nValTabPrc * _nSICOSO * nFatorLog
                         cLgMrg1 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                         cLgMrg2 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                      Else
                         cLgMrg1 += "Seção 8" + Chr(13) + Chr(10)
                         cLgMrg2 += "Seção 8" + Chr(13) + Chr(10)
	                     cLgMrg1 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * _nSICOSO)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
	                     cLgMrg2 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * _nSICOSO * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
	                     cLgMrg1 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ) - "+AllTrim(Str(nTotICM1,12,2))+" - "+AllTrim(Str(nTotPIS1,12,2))+" - "+AllTrim(Str(nTotCOF1,12,2))+" - "+AllTrim(Str(nTotST1,12,2))+" - "+AllTrim(Str(nTotIPI1,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nSICOSO,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ))*100" + Chr(13) + Chr(10)
	                     cLgMrg2 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ) - "+AllTrim(Str(nTotICM2,12,2))+" - "+AllTrim(Str(nTotPIS2,12,2))+" - "+AllTrim(Str(nTotCOF2,12,2))+" - "+AllTrim(Str(nTotST2,12,2))+" - "+AllTrim(Str(nTotIPI2,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(_nSICOSO,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ))*100" + Chr(13) + Chr(10)

					     nValRet1 := ((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * _nSICOSO)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100
					     nValRet2 := ((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * _nSICOSO)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100

	                     cLgMrg1 += "nValRet1 = "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
	                     cLgMrg2 += "nValRet2 = "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)

	                     cLgMrg1 += "nValTabPrc :=  nValTabPrc * _nSICOSO" + Chr(13) + Chr(10)
	                     cLgMrg2 += "nValTabPrc :=  nValTabPrc * _nSICOSO" + Chr(13) + Chr(10)
	                     cLgMrg1 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(_nSICOSO,12,2)) + Chr(13) + Chr(10)
	                     cLgMrg2 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(_nSICOSO,12,2)) + Chr(13) + Chr(10)

	                     nValTabPrc :=  nValTabPrc * _nSICOSO
	                     cLgMrg1 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
	                     cLgMrg2 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                      Endif
				   Else
                      IF nFatorLog <> 0
                         cLgMrg1 += "Seção 9" + Chr(13) + Chr(10)
                         cLgMrg2 += "Seção 9" + Chr(13) + Chr(10)
                         cLgMrg1 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
                         cLgMrg2 += "((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100" + Chr(13) + Chr(10)
                         cLgMrg1 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ) - "+AllTrim(Str(nTotICM1,12,2))+" - "+AllTrim(Str(nTotPIS1,12,2))+" - "+AllTrim(Str(nTotCOF1,12,2))+" - "+AllTrim(Str(nTotST1,12,2))+" - "+AllTrim(Str(nTotIPI1,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ))*100" + Chr(13) + Chr(10)
                         cLgMrg2 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ) - "+AllTrim(Str(nTotICM2,12,2))+" - "+AllTrim(Str(nTotPIS2,12,2))+" - "+AllTrim(Str(nTotCOF2,12,2))+" - "+AllTrim(Str(nTotST2,12,2))+" - "+AllTrim(Str(nTotIPI2,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ))*100" + Chr(13) + Chr(10)

					     nValRet1 := ((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100
					     nValRet2 := ((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100

                         cLgMrg1 += "nValRet1 = "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
                         cLgMrg2 += "nValRet2 = "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)

				         cLgMrg1 += "nValTabPrc :=  nValTabPrc * nFatorLog" + Chr(13) + Chr(10)
				         cLgMrg2 += "nValTabPrc :=  nValTabPrc * nFatorLog" + Chr(13) + Chr(10)
                         cLgMrg1 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(nFatorLog,12,2)) + Chr(13) + Chr(10)
                         cLgMrg2 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(nFatorLog,12,2)) + Chr(13) + Chr(10)

                         nValTabPrc :=  nValTabPrc * nFatorLog
                         cLgMrg1 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                         cLgMrg2 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                      Else
                         cLgMrg1 += "Seção 10" + Chr(13) + Chr(10)
                         cLgMrg2 += "Seção 10" + Chr(13) + Chr(10)
                         cLgMrg1 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
                         cLgMrg2 += "((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100" + Chr(13) + Chr(10)
                         cLgMrg1 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ) - "+AllTrim(Str(nTotICM1,12,2))+" - "+AllTrim(Str(nTotPIS1,12,2))+" - "+AllTrim(Str(nTotCOF1,12,2))+" - "+AllTrim(Str(nTotST1,12,2))+" - "+AllTrim(Str(nTotIPI1,12,2))+" - ("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ))*100" + Chr(13) + Chr(10)
                         cLgMrg2 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ) - "+AllTrim(Str(nTotICM2,12,2))+" - "+AllTrim(Str(nTotPIS2,12,2))+" - "+AllTrim(Str(nTotCOF2,12,2))+" - "+AllTrim(Str(nTotST2,12,2))+" - "+AllTrim(Str(nTotIPI2,12,2))+" - ("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ))*100" + Chr(13) + Chr(10)

					     nValRet1 := ((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100
					     nValRet2 := ((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100

                         cLgMrg1 += "nValRet1 = "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
                         cLgMrg2 += "nValRet2 = "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)
                      Endif
				   EndIf
			   Else
				   cLgMrg1 := cLgMrg
				   cLgMrg2 := cLgMrg

                   IF nFatorLog <> 0
                      cLgMrg1 += "Seção 11" + Chr(13) + Chr(10)
                      cLgMrg2 += "Seção 11" + Chr(13) + Chr(10)
                      cLgMrg1 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
                      cLgMrg2 += "((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100" + Chr(13) + Chr(10)
                      cLgMrg1 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ) - "+AllTrim(Str(nTotICM1,12,2))+" - "+AllTrim(Str(nTotPIS1,12,2))+" - "+AllTrim(Str(nTotCOF1,12,2))+" - "+AllTrim(Str(nTotST1,12,2))+" - "+AllTrim(Str(nTotIPI1,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ))*100" + Chr(13) + Chr(10)
                      cLgMrg2 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ) - "+AllTrim(Str(nTotICM2,12,2))+" - "+AllTrim(Str(nTotPIS2,12,2))+" - "+AllTrim(Str(nTotCOF2,12,2))+" - "+AllTrim(Str(nTotST2,12,2))+" - "+AllTrim(Str(nTotIPI2,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ))*100" + Chr(13) + Chr(10)

				      nValRet1 := ((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100
				      nValRet2 := ((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100

                      cLgMrg1 += "nValRet1 = "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
                      cLgMrg2 += "nValRet2 = "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)

			          cLgMrg1 += "nValTabPrc :=  nValTabPrc * nFatorLog" + Chr(13) + Chr(10)
			          cLgMrg2 += "nValTabPrc :=  nValTabPrc * nFatorLog" + Chr(13) + Chr(10)
                      cLgMrg1 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(nFatorLog,12,2)) + Chr(13) + Chr(10)
                      cLgMrg2 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(nFatorLog,12,2)) + Chr(13) + Chr(10)

                      nValTabPrc :=  nValTabPrc * nFatorLog
                      cLgMrg1 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                      cLgMrg2 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                   Else
                      cLgMrg1 += "Seção 12" + Chr(13) + Chr(10)
                      cLgMrg2 += "Seção 12" + Chr(13) + Chr(10)
                      cLgMrg1 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
                      cLgMrg2 += "((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100" + Chr(13) + Chr(10)
                      cLgMrg1 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ) - "+AllTrim(Str(nTotICM1,12,2))+" - "+AllTrim(Str(nTotPIS1,12,2))+" - "+AllTrim(Str(nTotCOF1,12,2))+" - "+AllTrim(Str(nTotST1,12,2))+" - "+AllTrim(Str(nTotIPI1,12,2))+" - ("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ))*100" + Chr(13) + Chr(10)
                      cLgMrg2 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ) - "+AllTrim(Str(nTotICM2,12,2))+" - "+AllTrim(Str(nTotPIS2,12,2))+" - "+AllTrim(Str(nTotCOF2,12,2))+" - "+AllTrim(Str(nTotST2,12,2))+" - "+AllTrim(Str(nTotIPI2,12,2))+" - ("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ))*100" + Chr(13) + Chr(10)

			          nValRet1 := ((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100
			          nValRet2 := ((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100

                      cLgMrg1 += "nValRet1 = "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
                      cLgMrg2 += "nValRet2 = "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)
                   Endif
			   EndIf
		    ELSE
			   cLgMrg1 := cLgMrg
			   cLgMrg2 := cLgMrg

			   If nFatorLog <> 0
                   cLgMrg1 += "Seção 13" + Chr(13) + Chr(10)
                   cLgMrg2 += "Seção 13" + Chr(13) + Chr(10)
                   cLgMrg1 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
                   cLgMrg2 += "((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100" + Chr(13) + Chr(10)
                   cLgMrg1 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ) - "+AllTrim(Str(nTotICM1,12,2))+" - "+AllTrim(Str(nTotPIS1,12,2))+" - "+AllTrim(Str(nTotCOF1,12,2))+" - "+AllTrim(Str(nTotST1,12,2))+" - "+AllTrim(Str(nTotIPI1,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ))*100" + Chr(13) + Chr(10)
                   cLgMrg2 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ) - "+AllTrim(Str(nTotICM2,12,2))+" - "+AllTrim(Str(nTotPIS2,12,2))+" - "+AllTrim(Str(nTotCOF2,12,2))+" - "+AllTrim(Str(nTotST2,12,2))+" - "+AllTrim(Str(nTotIPI2,12,2))+" - (("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+") * "+AllTrim(Str(nFatorLog,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ))*100" + Chr(13) + Chr(10)

				   nValRet1 := ((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100
				   nValRet2 := ((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - ((nValTabPrc*_nQtdVen) * nFatorLog)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100

                   cLgMrg1 += "nValRet1 = "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
                   cLgMrg2 += "nValRet2 = "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)

	               cLgMrg1 += "nValTabPrc :=  nValTabPrc * nFatorLog" + Chr(13) + Chr(10)
		           cLgMrg2 += "nValTabPrc :=  nValTabPrc * nFatorLog" + Chr(13) + Chr(10)
                   cLgMrg1 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(nFatorLog,12,2)) + Chr(13) + Chr(10)
                   cLgMrg2 += AllTrim(Str(nValTabPrc,12,2))+" * "+AllTrim(Str(nFatorLog,12,2)) + Chr(13) + Chr(10)

                   nValTabPrc :=  nValTabPrc * nFatorLog
                   cLgMrg1 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
                   cLgMrg2 += "nValTabPrc = "+AllTrim(Str(nValTabPrc,12,2)) + Chr(13) + Chr(10)
			   Else
                   cLgMrg1 += "Seção 14" + Chr(13) + Chr(10)
                   cLgMrg2 += "Seção 14" + Chr(13) + Chr(10)
                   cLgMrg1 += "((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100" + Chr(13) + Chr(10)
                   cLgMrg2 += "((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100" + Chr(13) + Chr(10)
                   cLgMrg1 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ) - "+AllTrim(Str(nTotICM1,12,2))+" - "+AllTrim(Str(nTotPIS1,12,2))+" - "+AllTrim(Str(nTotCOF1,12,2))+" - "+AllTrim(Str(nTotST1,12,2))+" - "+AllTrim(Str(nTotIPI1,12,2))+" - ("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST1,12,2))+" + "+AllTrim(Str(nTotIPI1,12,2))+" ))*100" + Chr(13) + Chr(10)
                   cLgMrg2 += "((( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ) - "+AllTrim(Str(nTotICM2,12,2))+" - "+AllTrim(Str(nTotPIS2,12,2))+" - "+AllTrim(Str(nTotCOF2,12,2))+" - "+AllTrim(Str(nTotST2,12,2))+" - "+AllTrim(Str(nTotIPI2,12,2))+" - ("+AllTrim(Str(nValTabPrc,12,2))+"*"+AllTrim(Str(_nQtdVen,12,2))+")) / ( "+AllTrim(Str(_nTotPed,12,2))+" + "+AllTrim(Str(nTotST2,12,2))+" + "+AllTrim(Str(nTotIPI2,12,2))+" ))*100" + Chr(13) + Chr(10)

				   nValRet1 := ((( _nTotPed + nTotST1 + nTotIPI1 ) - nTotICM1 - nTotPIS1 - nTotCOF1 - nTotST1 - nTotIPI1 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST1 + nTotIPI1 ))*100
				   nValRet2 := ((( _nTotPed + nTotST2 + nTotIPI2 ) - nTotICM2 - nTotPIS2 - nTotCOF2 - nTotST2 - nTotIPI2 - (nValTabPrc*_nQtdVen)) / ( _nTotPed + nTotST2 + nTotIPI2 ))*100

                   cLgMrg1 += "nValRet1 = "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
                   cLgMrg2 += "nValRet2 = "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)
			   EndIf
			Endif
		 EndIf
      Endif

      // Margem com frete
      If nValRet1 > 999.99
         nValRet1 := 999.99
      EndIf
      If nValRet1 < -99.99
         nValRet1 := -99.99
      EndIf

      // Margem sem frete
      If nValRet2 > 999.99
         nValRet2 := 999.99
      EndIf
      If nValRet2 < -99.99
         nValRet2 := -99.99
      EndIf

      cLgMrg1 += "Margem calculada do item "+SC6->C6_ITEM+": "+AllTrim(Str(nValRet1,12,2)) + Chr(13) + Chr(10)
      cLgMrg2 += "Margem calculada do item "+SC6->C6_ITEM+": "+AllTrim(Str(nValRet2,12,2)) + Chr(13) + Chr(10)

      DbSelectArea("SC6")
      RecLock("SC6",.F.)
      SC6->C6_XMARGEM := nValRet1
      SC6->C6_XMARG   := nValRet2

      SC6->C6_XLGMRG1 := AllTrim(SC6->C6_XLGMRG1) + Chr(13) + Chr(10) + cLgMrg1
      SC6->C6_XLGMRG2 := AllTrim(SC6->C6_XLGMRG2) + Chr(13) + Chr(10) + cLgMrg2
      MsUnlock()

      // Total impostos com frete
      nTICM1   += nTotICM1
      nTPIS1   += nTotPIS1
      nTCOF1   += nTotCOF1
      nTST1    += nTotST1
      nTIPI1   += nTotIPI1

      // Total impostos sem frete
      nTICM2   += nTotICM2
      nTPIS2   += nTotPIS2
      nTCOF2   += nTotCOF2
      nTST2    += nTotST2
      nTIPI2   += nTotIPI2

      nTPed    += SC6->C6_VALOR
      nTotTabPrc += (nValTabPrc * _nQtdVen)

      Dbskip()
End

nValRet1 := ((( nTPed + nTST1 + nTIPI1 ) - nTICM1 - nTPIS1 - nTCOF1 - nTST1 - nTIPI1 - nTotTabPrc) / ( nTPed + nTST1 + nTIPI1 ))*100
nValRet2 := ((( nTPed + nTST2 + nTIPI2 ) - nTICM2 - nTPIS2 - nTCOF2 - nTST2 - nTIPI2 - nTotTabPrc) / ( nTPed + nTST2 + nTIPI2 ))*100

// Margem total com frete
If nValRet1 > 999.99
   nValRet1 := 999.99
EndIf
If nValRet1 < -99.99
   nValRet1 := -99.99
EndIf

// Margem total sem frete
If nValRet2 > 999.99
   nValRet2 := 999.99
EndIf
If nValRet2 < -99.99
   nValRet2 := -99.99
EndIf

DbSelectArea("SC5")
RecLock("SC5",.F.)
SC5->C5_XMARGEM := nValRet1
SC5->C5_XMARG   := nValRet2
//SC5->C5_XWSDTAL := dTos(DATE())+Substr(StrTran(Time(),':',''),1,6)
MsUnlock()

// Tratamento para nao flegar C5_DYFLAG quando brinde ou amostra - Fabio Gesser - 10/11/16
If INCLUI
	IF SC5->C5_XBRINDE <> '1'
	   // Tratamento da gravação do campo C5_DYFLAG - Fabio Gesser - 10/11/16
	   If !IsInCallStack("U_DYA440AUT") .And. !IsInCallStack("U_DYA450AUT") .And. !IsInCallStack("U_xA450LibMan")  // Incluído validacao chamada DYA450AUT - Fabio Gesser - 12/01/17
	      If !SM0->M0_CODIGO $ "07/09"
	         IF AllTrim(SC5->C5_DYLIBER) <> "" .AND. SC5->C5_DYCANPV <> '01'
	            If SC5->C5_XDTACT >= cTod("11/11/2016")
	               IF !SC5->C5_CLIENTE $ "049327943,084534924,013138765,023446112,029709769"
	                  DbSelectArea("SE4")
	                  DbSetOrder(1)
	                  DbSeek(xFilial("SE4")+SC5->C5_CONDPAG)

	                  IF SC5->C5_TIPO == 'N'
//	                     If SC5->C5_XMARG < nMargVld .Or. (SE4->E4_PRZMED >= nBLQPRZD .And. SA1->A1_XPRZMED <> 'S') .Or. nTotLiq > nVlrTLib
//	                     If SC5->C5_XMARGEM < nMargVld .Or. (SE4->E4_PRZMED >= nBLQPRZD .And. SA1->A1_XPRZMED <> 'S') .Or. nTotLiq > nVlrTLib .Or. nTotLiq > 500
	                     If SC5->C5_XMARGEM < nMargVld .Or. (SE4->E4_PRZMED >= nBLQPRZD .And. SA1->A1_XPRZMED <> 'S') .Or. nTotLiq > nVlrTLib
	                        If Empty(SC5->C5_DYFLAG)
                               DbSelectArea("SC5")
	                           RecLock("SC5",.F.)
	                           SC5->C5_DYFLAG := 'B'
	                           MsUnlock()
	                        Endif
	                     ElseIf SE4->E4_XCREDIT == "S"
	                        If Empty(SC5->C5_DYFLAG)
                               DbSelectArea("SC5")
	                           RecLock("SC5",.F.)
	                           SC5->C5_DYFLAG := 'B'
	                           MsUnlock()
	                        Endif
	                     ElseIf lBlqTab
	                        If Empty(SC5->C5_DYFLAG)
                               DbSelectArea("SC5")
	                           RecLock("SC5",.F.)
	                           SC5->C5_DYFLAG := 'B'
	                           MsUnlock()
	                        Endif
	                     Endif
	                  Endif
	               Endif
	            Endif
	         Endif
	      Endif
	   Endif
	Endif
ElseIf ALTERA
	IF SC5->C5_XBRINDE <> '1'
	   If !IsInCallStack("U_DYA440AUT") .And. !IsInCallStack("U_DYA450AUT") .And. !IsInCallStack("U_xA450LibMan")
	      If !SM0->M0_CODIGO $ "07/09"
	         IF AllTrim(SC5->C5_DYLIBER) <> "" .AND. SC5->C5_DYCANPV <> '01'
	            If SC5->C5_XDTACT >= cTod("11/11/2016")
	               IF !SC5->C5_CLIENTE $ "049327943,084534924,013138765,023446112,029709769"
	                  DbSelectArea("SE4")
	                  DbSetOrder(1)
	                  DbSeek(xFilial("SE4")+SC5->C5_CONDPAG)

	                  IF SC5->C5_TIPO == 'N'
	                     If SE4->E4_XCREDIT == "S"
	                        If Empty(SC5->C5_DYFLAG)
								DbSelectArea("SC5")
								RecLock("SC5",.F.)
								SC5->C5_DYFLAG := 'B'
								MsUnlock()
							Endif
                         Endif
	                  Endif
	               Endif
	            Endif
	         Endif
	      Endif
	   Endif
	Endif
Endif

// Grava flag para reenviar ao BI - Fabio Gesser - 09/12/16
If (INCLUI .or. ALTERA)
   DbSelectArea("SC5")
   RecLock("SC5",.F.)
   SC5->C5_XENVZAF := 'N'
   MsUnlock()

   // Faço a eliminação do pedido na tabela ZAF do BI e limpo flag da SC5 para reprocessar - Fabio Gesser - 22/12/16
   cQuery := "UPDATE "+RetSqlName("ZAF")+" SET D_E_L_E_T_ = '*' "
   cQuery += "WHERE ZAF_FILIAL  = '"+SC5->C5_FILIAL+"' "
   cQuery += "AND   ZAF_EMPRES  = '"+AllTrim(SM0->M0_CODIGO)+"' "
   cQuery += "AND   ZAF_PEDIDO  = '"+SC5->C5_NUM+"' "
   cQuery += "AND   D_E_L_E_T_ <> '*' "

   IF TCSQLEXEC(cQuery) < 0
      U_xConout("M410STTS - Erro update ZAF", ProcName())
   ENDIF
Endif

If Select( cAliasTab ) > 0; dbSelectArea( cAliasTab ); dbCloseArea(); EndIf

RestArea(_aAreaSC5)
RestArea(_aAreaSC6)

Return


// ###########################################################################################################
// Projeto  : Day-Brasil
// Autor    : Fabio Luiz Gesser
// Modulo   : Faturamento
// Função   : M410STTS
// Descrição: Busca valores dos impostos
// Retorno  : lVerCalc, nTotICM1, nTotPIS1, nTotCOF1, nTotST1, nTotIPI1.
// ---------+-------------------+-----------------------------------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+-----------------------------------------------------------------------------
// 17/02/14 | Fabio Gesser      | Desenvolvimento Inicial
// ---------+-------------------+-----------------------------------------------------------------------------
User Function DYPEDImp(nTotLiq, MV_PAR04, nTotICM, nTotPIS, nTotCOF, nTotST, nTotIPI, aTransp, lCalFrt)

Local lFisFunc   := MaFisFound()
Local lSaldo     := MV_PAR04 == 1 .And. !INCLUI
Local nPrcLista  := SC6->C6_VALOR
Local nAcresFin  := 0.00
Local nValMerc   := If(SC6->C6_QTDVEN==0,SC6->C6_VALOR,If(lSaldo,(SC6->C6_QTDVEN-nQtdEnt)*SC6->C6_VALOR,SC6->C6_VALOR))
Local nDesconto  := 0.00
Local VALORISS   := 0.00
Local nFreteItem := 0.00

// Inicia o cálculo de impostos.
If !lFisFunc .or. MaFisRet(, "NF_CODCLIFOR") + MaFisRet(, "NF_LOJA") <> M->(C5_CLIENTE + C5_LOJACLI)
	If lFisFunc
		MaFisEnd()  // Limpa as funções fiscais.
	Endif
Endif

MaFisIni(M->C5_CLIENTE, M->C5_LOJACLI, IIf(M->C5_TIPO$'DB',"F","C"), M->C5_TIPO, M->C5_TIPOCLI, nil, nil, nil, nil, "MATA461", nil, nil,,,,,, aTransp,,,,,,,, M->C5_TPFRETE)

If lSaldo
   nQtdEnt := IIf(!SubStr(SC6->C6_BLQ,1,1)$"RS" .And. Empty(SC6->C6_BLOQUEI),SC6->C6_QTDENT,SC6->C6_QTDVEN)
Else
   lSaldo := .F.
EndIf

// Calcula o preco de lista
If ( nPrcLista == 0 )
   nValMerc  := If(SC6->C6_QTDVEN==0,SC6->C6_VALOR,If(lSaldo,(SC6->C6_QTDVEN-nQtdEnt)*SC6->C6_VALOR,SC6->C6_VALOR))
EndIf
nAcresFin := A410Arred(SC6->C6_PRCVEN*SE4->E4_ACRSFIN/100,"D2_PRCVEN")
nValMerc  += A410Arred(nAcresFin*SC6->C6_QTDVEN,"D2_TOTAL")
nDesconto := A410Arred(nPrcLista*SC6->C6_QTDVEN,"D2_DESCON")-nValMerc
nDesconto := IIf(nDesconto==0,SC6->C6_VALDESC,nDesconto)
nDesconto := Max(0,nDesconto)
nPrcLista += nAcresFin
nValMerc  += nDesconto

MaFisAdd(SC6->C6_PRODUTO, SC6->C6_TES, SC6->C6_QTDVEN, nPrcLista, nDesconto, "", "", 0, 0, 0, 0, 0, nValMerc, 0, SB1->(RecNo()), SF4->(RecNo()))

// Calculo do ISS
If SA1->A1_INCISS == "N"
   If ( SF4->F4_ISS=="S" )
      nPrcLista := a410Arred(nPrcLista/(1-(MaAliqISS(1)/100)),"D2_PRCVEN")
      VALORISS  := nPrcLista
      nValMerc  := a410Arred(nValMerc/(1-(MaAliqISS(1)/100)),"D2_PRCVEN")
      MaFisAlt("IT_PRCUNI",nPrcLista,1)
      MaFisAlt("IT_VALMERC",nValMerc,1)
   EndIf
EndIf

If lCalFrt
	// Calculo do Frete proporcinal ao item - Fabio Gesser - 08/07/2016
	nFreteItem  := M->C5_FRETE * (SC6->C6_VALOR / nTotLiq)
	MaFisAlt("IT_FRETE",nFreteItem,1)
Endif

VALORIPI    := MaFisRet(1, "IT_VALIPI")
_VALICM     := MaFisRet(1, "IT_VALICM")
_VALPS2     := MaFisRet(1, "IT_VALPS2")
_VALCF2     := MaFisRet(1, "IT_VALCF2")
_VALFECP    := MaFisRet(1, "IT_VALFECP")   // Incluído novo imposto fundo de pobresa - 09/06/16
_VFCPDIF    := MaFisRet(1, "IT_VFCPDIF")   // Adicionado Fabio Gesser 07/07/16
_ICMSCOM    := MaFisRet(1, "IT_VALCMP")    // Adicionado Fabio Gesser 30/01/16
_DIFAL      := MaFisRet(1, "LF_DIFAL")     // Adicionado Fabio Gesser 30/01/16
ICMSSOL     := MaFisRet(1, "IT_VALSOL")

MaFisEnd()

nTotICM := _VALICM+_ICMSCOM+_DIFAL+_VALFECP+_VFCPDIF
nTotPIS := _VALPS2
nTotCOF := _VALCF2
nTotST  := ICMSSOL
nTotIPI := VALORIPI

Return()
