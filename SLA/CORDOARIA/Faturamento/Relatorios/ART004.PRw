#include "rwmake.ch"

User Function ART004

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de variaveis utilizadas no programa atraves da funcao    ³
//³ SetPrvt, que criara somente as variaveis definidas pelo usuario,    ³
//³ identificando as variaveis publicas do sistema utilizadas no codigo ³
//³ Incluido pelo assistente de conversao do AP5 IDE                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

SetPrvt("TAMANHO,LIMITE,TITULO,CDESC1,CDESC2,CDESC3")
SetPrvt("CSTRING,ARETURN,NLASTKEY,NPRI,NOMEPROG,CPERG1")
SetPrvt("WNREL,NCOPIA,")

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Descricao ³ MINUTA DE DESPACHO                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Especifico para ARTEPLAS uso com Rdmake                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Arquivos  ³  SA1 - SF2 - SA4 - SF4 - SB1 - SD2 - SC5                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Define Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


 cDesc1       := PADC("Este programa ira emitir as MINUTAS DE DESPACHO",74)
 cDesc2       := PADC("para Cordoaria Brasil!!!",74)
 cDesc3       := ""
 cPict        := ""
 titulo       := PADC("EMISSAO DA MINUTA DE DESPACHO",74)
 nLin         := 80
 cString      := "SF2"
 Cabec1       := ""
 Cabec2       := ""
 imprime      := .T.
 aOrd         := {}
Private lEnd       := .F.
Private lAbortPrint:= .F.
Private CbTxt      := ""
Private limite     := 80
Private tamanho    := "M"
Private nomeprog   := "ARTE04"
Private nTipo      := 18
Private aReturn    := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey   := 0
Private cPerg      := "ARTE04"
Private cbtxt      := Space(10)
Private cbcont     := 00
Private CONTFL     := 01
Private m_pag      := 01
Private wnrel      := "ARTE04"


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Salva a Integridade dos dados de Saida                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

nomeprog := "ARTE04"
cPerg1   := "ARTE04"
wnrel    := "ARTE04"

pergunte(cPerg1,.F.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis utilizadas para parametros                         ³
//³ mv_par01             // Da NF                                ³
//³ mv_par02             // Ate a NF                             ³
//³ mv_par03             // Serie                                ³
//³ mv_par04             // PRODUTO                              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Envia controle para a funcao SETPRINT                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

wnrel:=SetPrint(cString,wnrel,cPerg1,Titulo,cDesc1,cDesc2,cDesc3,.F.,"")


If LastKey() == 27 .or. nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If LastKey() == 27 .or. nLastKey == 27
	Return
Endif

nTipo := If(aReturn[4]==1,15,18)



//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Salva posicoes para movimento da regua de processamento      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

RptStatus({|| RptDetail()})
Return


Static Function RptDetail()

nCOPIA := 1
SETPRC(0,0)

dbSelectArea("SF2")
dbSetOrder(1)// filial+doc+serie     CABECALHO NFISCAL
dbGoTop()
dbSeek(xFilial("SF2")+MV_PAR01+MV_PAR03,.T.)
While !Eof() .and. SF2->F2_FILIAL == xFilial("SF2") .and. ;
	SF2->F2_DOC   <= MV_PAR02 //.and. SF2->F2_SERIE == MV_PAR03
	
	If SF2->F2_SERIE # MV_PAR03  // INCLUÍDO POR EMARQUETI EM 14/03/2011
		dbSelectArea("SF2")
		dbSkip()                 
		Loop
	EndIf
	
	nCOPIA := 1
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Confirma Teste de Impressao na Nota Fiscal                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

   // Obter o Peso Liquido
   // * Itens de Venda da Nota Fiscal
   SD2->(dbSetOrder(3))
   SD2->(dbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE))
   SD2->(dbSetOrder(1))
   // * Pedidos de Venda
   SC5->(dbSetOrder(1))
   SC5->(dbSeek(xFilial("SC5")+SD2->D2_PEDIDO))


   While !Eof() .and. nCOPIA <= MV_PAR05
		
		nLin := 2
		@ nLin,005 PSAY "CORDOARIA BRASIL INDUSTRIA E COMERCIO DE CORDAS"
		nLin++
		@ nLin,005 PSAY "Av. Adolfo Konder, 1444, Sao Vicente."
		nLin++
		@ nLin,005 PSAY "88.308-002, Itajai - SC"
		nLin++
		@ nLin,005 PSAY "CNPJ.: 09.454.624/0001-53"     
		nLin++
		@ nLin,005 PSAY "www.cordoariabrasil.com.br"     
		
		nLin += 5
		@ nLin,005 PSAY "       MINUTA DE DESPACHO"
		nLin++
		@ nLin,005 PSAY "       ------------------"
		
		If SF2->F2_TIPO $ "DB"
			
			dbSelectArea("SA2")
			dbSetOrder(1)// filial+cod para      CLIENTES
			dbGoTop()
			dbSeek(xFilial("SA2")+SF2->F2_CLIENTE+SF2->F2_LOJA,.T.)
			
			nLin += 3
			@ nLin,005  PSAY "FORNECEDOR: " + SA2->A2_COD+ AllTrim(SA2->A2_NOME)
			nLin++
			@ nLin,005  PSAY SA2->A2_END
			nLin++
			@ nLin,005  PSAY SA2->A2_CEP Picture "@R 99999-999"// CEP
			@ nLin,015  PSAY AllTrim(SA2->A2_MUN) + " - " + SA2->A2_EST
			IF LEN(ALLTRIM(SA2->A2_CGC)) == 14
				nLin++
				@ nLin,005  PSAY SA2->A2_CGC    PICTURE "@R 99.999.999/9999-99"
				nLin++
				@ nLin,005  PSAY SA2->A2_INSCR
			ENDIF
			IF LEN(ALLTRIM(SA2->A2_CGC)) == 11
				nLin++
				@ nLin,005  PSAY SA2->A2_CGC    PICTURE "@R 999.999.999-99"
			ENDIF
			
		Else
			
			dbSelectArea("SA1")
			dbSetOrder(1)// filial + cod para      CLIENTES
			dbGoTop()
			dbSeek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,.T.)
			
			nLin += 2
    		@ nLin,005  PSAY      "----------------------------------------------------------------------------"
			nLin ++
			@ nLin,005  PSAY "CLIENTE: " + SA1->A1_COD+ AllTrim(SA1->A1_NOME)
			nLin++
			@ nLin,005  PSAY SA1->A1_END
			nLin++
			@ nLin,005  PSAY SA1->A1_CEP Picture"@R 99999-999"// CEP
			@ nLin,015  PSAY AllTrim(SA1->A1_MUN)+" - "+SA1->A1_EST
			IF LEN(ALLTRIM(SA1->A1_CGC)) == 14
				nLin++
				@ nLin,005  PSAY SA1->A1_CGC    PICTURE "@R 99.999.999/9999-99"
				nLin++
				@ nLin,005  PSAY SA1->A1_INSCR
			ENDIF
			IF LEN(ALLTRIM(SA1->A1_CGC)) == 11
				nLin++
				@ nLin,005  PSAY SA1->A1_CGC    PICTURE "@R 999.999.999-99"
			ENDIF     
			nLin++
		@ nLin,005  PSAY      "----------------------------------------------------------------------------"
		Endif

		
		dbSelectArea("SA4")
		dbSetOrder(1)// Filial + Cod para      TRANSPORTADORAS
		dbGoTop()
		dbSeek(xFilial("SA4")+SF2->F2_TRANSP,.T.)
		
		nLin += 3
		@ nLin,005  PSAY "TRANSPORTADORA: "
			@ nLin,025  PSAY Alltrim(SA4->A4_NOME)
			nLin++
			@ nLin,005  PSAY "ENDERECO: "
			@ nLin,025  PSAY Alltrim(SA4->A4_END)
			nLin++
			@ nLin,025  PSAY Alltrim(SA4->A4_MUN) +"/"+ SA4->A4_EST 
			nLin++
    		@ nLin,005  PSAY "BAIRRO: " 
    		@ nLin,025  PSAY Alltrim (SA4->A4_BAIRRO)   
			nLin++
    		@ nLin,005  PSAY "CEP...: " 
    		@ nLin,025  PSAY Alltrim(SA4->A4_CEP) + If(!Empty(SA4->A4_TEL)," - FONE: "+SA4->A4_TEL,"")
			nLin++
			@ nLin,005  PSAY "CNPJ..: " 
			@ nLin,025  PSAY SA4->A4_CGC PICTURE "@R 99.999.999/9999-99"
			nLin++
    		@ nLin,005  PSAY "INSC..: " 
    		@ nLin,025  PSAY SA4->A4_INSEST  
    	 	
    	 	nLin += 2
			@ nLin,005  PSAY      "----------------------------------------------------------------------------"
			nLin += 2
		
		dbSelectArea("SA4")
		dbSetOrder(1)// filial+cod para      TRANSPORTADORAS
		dbGoTop()
		If DbSeek(xFilial("SA4")+SF2->F2_REDESP,.T.)
			@ nLin,005  PSAY "REDESPACHO: "
			@ nLin,025  PSAY Alltrim(SA4->A4_NOME)
			nLin++
			@ nLin,005  PSAY "ENDERECO: "
			@ nLin,025  PSAY Alltrim(SA4->A4_END)
			nLin++
			@ nLin,025  PSAY Alltrim(SA4->A4_MUN) +"/"+ SA4->A4_EST 
			nLin++
    		@ nLin,005  PSAY "BAIRRO: " 
    		@ nLin,025  PSAY Alltrim (SA4->A4_BAIRRO)   
			nLin++
    		@ nLin,005  PSAY "CEP...: " 
    		@ nLin,025  PSAY Alltrim(SA4->A4_CEP) + If(!Empty(SA4->A4_TEL)," - FONE: "+SA4->A4_TEL,"")
			nLin++
			@ nLin,005  PSAY "CNPJ..: " 
			@ nLin,025  PSAY SA4->A4_CGC PICTURE "@R 99.999.999/9999-99"
			nLin++
    		@ nLin,005  PSAY "INSC..: " 
    		@ nLin,025  PSAY SA4->A4_INSEST  
    		nLin++                      
		Else
			nLin += 2
		Endif
		
		nLin += 4
		@ nLin,005  PSAY      "N. FISCAL  VOLUME   ESPECIE  PEDIDO     PESO BRUTO   PESO LIQ.        VALOR"
		nLin++                                                         
		@ nLin,005  PSAY      "----------------------------------------------------------------------------"
		*                 012345678901234567890123456789012345678901234567890123456789012345678901234567890
		*                          10        20        30        40        50        60        70
		                                            
	
		nLin += 2
		@ nLin,005  PSAY SF2->F2_DOC
		@ nLin,016  PSAY SF2->F2_VOLUME1
		@ nLin,025  PSAY SF2->F2_ESPECI1
		@ nLin,034  PSAY SC5->C5_NUM  //
        @ nLin,044  PSAY SF2->F2_PBRUTO  Picture "@E@Z 999,999.99"      // Peso Bruto
        @ nLin,056  PSAY SF2->F2_PLIQUI  Picture "@E@Z 999,999.99"     // Peso Liquido
		@ nLin,067  PSAY SF2->F2_VALBRUT Picture "@E@Z 99,999,999.99"   // Valor Total NF
		
		nLin += 4
		
		If SC5->C5_TPFRETE == "C"
			@ nLin,025  PSAY "FRETE:   FOB(_) CIF(X)"
		Else
			@ nLin,025  PSAY "FRETE:   FOB(X) CIF(_)"
		Endif
		
		nLin += 4
		@ nLin,005  PSAY "DATA EMISSAO"	  
		@ nLin,025  PSAY "DATA RETIRADA"
		@ nLin,045  PSAY "TRANSPORTADORA"
		
		nLin += 3
		@ nLin,005  PSAY DTOC(SF2->F2_EMISSAO)
		@ nLin,025  PSAY "____/____/____"
		@ nLin,045  PSAY "_______________________________"
		
		
		nCOPIA := nCOPIA + 1
		dbSelectArea("SF2")
	END
	
	dbSelectArea("SF2")
	dbSkip()
END

If aReturn[5] == 1
	Set Printer TO
	dbcommitAll()
	ourspool(wnrel)
Endif

MS_FLUSH()

Return