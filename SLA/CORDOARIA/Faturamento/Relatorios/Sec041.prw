#include "rwmake.ch"        // incluido pelo assistente de conversao do AP5 IDE em 19/11/99
#include "TopConn.ch"        

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFUNCAO    ³SEC041    ºAutor  ³Eduardo H Rodrigues º Data ³  03/11/03   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Relatorio de Previsao de faturamento                       º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ SIGAEST - Rotina de Faturamento                            º±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function SEC041

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis                                                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

wnrel	:= ""
nOrdem  := ""
tamanho := "P"     
limite  := 80
titulo  := "PREVISAO DE FATURAMENTO"
cDesc1  := "SEC041" 
cDesc2  := ""
cDesc3  := ""
nomeprog:= "SEC041"
cString := "SC6"
cMoeda  := ""
cPerg   := "SEC041"
aReturn := { "Especial", 1,"Administracao", 1, 2, 1,"",1 }
nLastKey:= 0
wnrel   := "SEC041"
m_pag   := 1

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica as perguntas selecionadas                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

VerPerg()	
Pergunte(cPerg,.F.)
titulo  := "PREVISAO FAT. "+(mv_par03)+" A "+(mv_par04)


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis de trabalho                                               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³    Variaveis utilizadas para parametros   	                      	³
//³    Mv_Par01             // Do Produto                               ³
//³    Mv_Par02             // Ate o Produto                            ³
//³    Mv_Par03             // Da data                                  ³
//³    Mv_Par04             // Ate a data                               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.T.,,,,,.F.)

If ( nLastKey == 27 .Or. LastKey() == 27 )
	Return(.F.)
EndIf

SetDefault(aReturn,cString)
nTipo := IIF(aReturn[4]==1,15,18)

If ( nLastKey == 27 .Or. LastKey() == 27 )
	Return(.F.)
EndIf

RptStatus( {|| IMPREL()} )
Set Device To Screen

If aReturn[5] == 1
   Set Printer TO
   dbcommitAll()
   ourspool(wnrel)
Endif

MS_FLUSH()
Return

Static Function IMPREL()

   CQUERY := "SELECT C6_CLI, C6_LOJA, C6_PRODUTO, B1_DESC, B1_UM, C6_QTDVEN, C6_ENTREG, A1_NOME, "
   CQUERY += " C6_PRCVEN, C6_VALOR FROM " + RETSQLNAME("SC6") + " AS SC6, " + RETSQLNAME("SB1") + " AS SB1, " + RETSQLNAME("SA1") + " AS SA1 "
   CQUERY += " WHERE (C6_PRODUTO BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "')"
   CQUERY += "       AND (C6_ENTREG BETWEEN '" + DTOS(MV_PAR03) + "' AND '" + DTOS(MV_PAR04) + "')"
   CQUERY += "       AND C6_PRODUTO = B1_COD AND C6_QTDVEN > 0 "
   CQUERY += "       AND C6_CLI = A1_COD "
   CQUERY += "       AND C6_NOTA = '      '"        
   CQUERY += "       AND (SC6.D_E_L_E_T_ <> '*' AND SB1.D_E_L_E_T_ <> '*')"
   CQUERY += " ORDER BY C6_ENTREG, C6_CLI, C6_PRODUTO"
 
   //MemoWrite("C:\TEMP\SEC040A.SQL",cQuery)
   TcQuery cQuery New Alias "TRX"

   pnCount := 0
   DbeVal({|| pnCount:=pnCount+1},{|| .T.},{|| ! Eof()})
   
   TRX->(DbGoTop())
   SetRegua(pnCount)
   
   If pnCount = 0 
      Return
   EndIf   
  
   Cabec1 := "CODIGO          DESCRICAO             UND    QUANTIDADE    VL.UNIT.     TOTAL " 
           
   _nQtdPRVFAT  := 0.00
   
   DbSelectarea("TRX")
   lPriPag := .t.
   nLin := 99
   nTotFim := 0
   nTotF   := 0
   While !TRX->(Eof())
      dEntrega     := TRX->C6_ENTREG
      if nLin < 55
         @ pRow()+2, 000    pSay "Entrega " + dtoc(stod(dEntrega))      
      endif
      nTotDia := 0 
      nTotD   := 0
      While !TRX->(Eof()) .and. TRX->C6_ENTREG == dEntrega
         cCliente  := TRX->C6_CLI 
         cNomeCli  := TRX->A1_Nome                                                  
         nTotCli   := 0
         nTotC     := 0
         if nLin < 55
            @ pRow()+2, 000    pSay "Cliente " + cCliente  + " - " + cNomeCli            
         endif
         While !TRX->(Eof()) .and. TRX->C6_ENTREG == dEntrega .and. TRX->C6_CLI == cCliente
            _nQtdPRVFAT  := 0.00                              
            cPRODUTO     := TRX->C6_PRODUTO
            cDESCRI      := PadR(TRX->B1_DESC,30)
            cUM          := TRX->B1_UM           
            nValUni      := 0
            nValTot      := 0
            While !TRX->(Eof()) .and. TRX->C6_ENTREG == dEntrega .and. TRX->C6_CLI == cCliente .and. TRX->C6_PRODUTO == cPRODUTO
               _nQtdPRVFAT := _nQtdPRVFAT  + TRX->C6_QTDVEN
               nValUni := nValUni + TRX->C6_PRCVEN
               nValTot := nValTot + TRX->C6_VALOR 

               nTotCli := nTotCli + TRX->C6_QTDVEN
               nTotDia := nTotDia + TRX->C6_QTDVEN
               nTotFim := nTotFim + TRX->C6_QTDVEN

               nTotC   := nTotC + TRX->C6_VALOR
               nTotD   := nTotD + TRX->C6_VALOR
               nTotF   := nTotF + TRX->C6_VALOR

               TRX->(DbSkip())
            Enddo
            If nLin > 55          
               Cabec(titulo,cabec1,"",nomeprog,tamanho,nTipo)            
               @ pRow()+1, 000    pSay "Entrega " + dtoc(stod(dEntrega))
               @ pRow()+2, 000    pSay "Cliente " + cCliente + " - " + cNomeCli
            EndIf      
            @ pRow()+1, 000       pSay Padr(cPRODUTO,9)
            @ pRow()  , pCol()+1  pSay cDESCRI
            @ pRow()  , pCol()+1  pSay cUM
            @ pRow()  , pCol()+1  pSay Trans(_nQtdPRVFAT, "@e 999,999.99")
            @ pRow()  , pCol()+1  pSay Trans(nValUni, "@e 99,999.99")            
            @ pRow()  , pCol()+1  pSay Trans(nValTot, "@e 999,999.99")            
            
            nLin := pRow()
        Enddo
        @ pRow()+2  , 000 pSay "Tot.Cliente: QTDE =" + Trans(nTotCli, "@e 99,999,999.99") + "  Valor Total " + Trans(nTotC, "@e 99,999,999.99")

     Enddo       
     @ pRow()+2 , 000 pSay    "Tot.Dia: QTDE =" + Trans(nTotDia, "@e 99,999,999.99") + "  Valor Total " + Trans(nTotD, "@e 99,999,999.99")    
   Enddo
   @ pRow()+2 , 000 pSay    "Tot.GERAL: QTDE =" + Trans(nTotFim, "@e 99,999,999.99") + "  Valor Total " + Trans(nTotF, "@e 99,999,999.99")       
   
   DbSelectArea("TRX")
   DbCloseArea("TRX")

Return

//Verifica se existe as perguntas, se nao cria
Static Function VerPerg()
   SX1->(DbSetOrder(1))

   IF ! SX1->(DbSeek(cPerg+"01",.F.))
      RecLock("SX1",.T.)
      SX1->X1_GRUPO   := cPerg
      SX1->X1_ORDEM   := "01"
      SX1->X1_PERGUNT := "Do Produto         ?"
      SX1->X1_VARIAVL := "Mv_ch1"
      SX1->X1_TIPO    := "C"      
      SX1->X1_TAMANHO := 15
      SX1->X1_DECIMAL := 0 
      SX1->X1_GSC     := "G"
      SX1->X1_VAR01   := "Mv_Par01"
      SX1->X1_DEF01   := ""
      SX1->X1_DEF02   := ""
      SX1->X1_F3      := ""
      MsUnLock("SX1")
   EndIf   
   IF ! SX1->(DbSeek(cPerg+"02",.F.))
      RecLock("SX1",.T.)
      SX1->X1_GRUPO   := cPerg
      SX1->X1_ORDEM   := "02"
      SX1->X1_PERGUNT := "Ate o Produto     ?"
      SX1->X1_VARIAVL := "Mv_ch2"
      SX1->X1_TIPO    := "C"      
      SX1->X1_TAMANHO := 15
      SX1->X1_DECIMAL := 0 
      SX1->X1_GSC     := "G"
      SX1->X1_VAR01   := "Mv_Par02"
      SX1->X1_F3      := ""
      MsUnLock("SX1")
   EndIf        
   IF ! SX1->(DbSeek(cPerg+"03",.F.))
      RecLock("SX1",.T.)
      SX1->X1_GRUPO   := cPerg
      SX1->X1_ORDEM   := "03"
      SX1->X1_PERGUNT := "Da Data            ?"
      SX1->X1_VARIAVL := "Mv_ch3"
      SX1->X1_TIPO    := "D"      
      SX1->X1_TAMANHO := 8
      SX1->X1_DECIMAL := 0
      SX1->X1_GSC     := "G"
      SX1->X1_VAR01   := "Mv_Par03"
      SX1->X1_F3      := ""
      MsUnLock("SX1")
   EndIf     
   IF ! SX1->(DbSeek(cPerg+"04",.F.))
      RecLock("SX1",.T.)
      SX1->X1_GRUPO   := cPerg
      SX1->X1_ORDEM   := "04"
      SX1->X1_PERGUNT := "Ate a Data         ?"
      SX1->X1_VARIAVL := "Mv_ch4"
      SX1->X1_TIPO    := "D"      
      SX1->X1_TAMANHO := 8
      SX1->X1_DECIMAL := 0
      SX1->X1_GSC     := "G"
      SX1->X1_VAR01   := "Mv_Par04"
      SX1->X1_F3      := ""
      MsUnLock("SX1")
   EndIf     
Return
