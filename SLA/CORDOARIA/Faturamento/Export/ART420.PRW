#INCLUDE "rwmake.ch"
#include "topconn.ch"

User Function ART420
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑฺฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฟฑฑ
ฑฑณFunฦo    ณ ART420 ณ Autor ณ Eduardo Marquetti       ณ Data ณ 21/08/14 ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณDescriฦo ณ Exporta Pedidos Rainha da Paz para Arquivo TXT cfe Layout  ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณ Uso      ณ Especifico Arteplas/Rainha da Paz                          ณฑฑ
ฑฑภฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤูฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/


//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Declaracao de Variaveis                                             ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

Private oGeraTxt

dDATAI :=CTOD("  /  /  ")

MV_PAR01 := " "
MV_PAR02 := " "
MV_PAR03 := " "

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Montagem da tela de processamento.                                  ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

@ 200,1 TO 380,380 DIALOG oGeraTxt TITLE OemToAnsi("Gera็ใo de Arquivo Texto")
@ 02,10 TO 080,190
@ 10,018 Say " Este programa ira gerar um arquivo texto, conforme os parame- "
@ 18,018 Say " tros definidos pelo usuario,  com os registros dos Pedidos    "
@ 26,018 Say " de Venda.                 "
@ 39,018 SAY OemToAnsi("Informe Data")       Size 80,8
@ 39,018 GET dDataI SIZE 40,12//pict "@D" 
@ 70,128 BMPBUTTON TYPE 01 ACTION OkGeraTxt()
@ 70,158 BMPBUTTON TYPE 02 ACTION Close(oGeraTxt)

Activate Dialog oGeraTxt Centered

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบFuno    ณ OKGERATXTบ Autor ณ AP5 IDE            บ Data ณ  21/01/09   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescrio ณ Funcao chamada pelo botao OK na tela inicial de processamenบฑฑ
ฑฑบ          ณ to. Executa a geracao do arquivo texto.                    บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Programa principal                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

Static Function OkGeraTxt

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Cria o arquivo texto                                                ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

Private cArqTxt := "C:\PEDIDOS"+cValToChar(Val(DtoS(dDataI)))+".TXT" 
Private nHdl    := fCreate(cArqTxt)

Private cEOL    := "CHR(13)+CHR(10)"
If Empty(cEOL)
    cEOL := CHR(13)+CHR(10)
Else
    cEOL := Trim(cEOL)
    cEOL := &cEOL
Endif

If nHdl == -1
    MsgAlert("O arquivo de nome "+cArqTxt+" nao pode ser executado! Verifique os parametros.","Atencao!")
    Return
Endif

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Inicializa a regua de processamento                                 ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

Processa({|| RunCont() },"Processando...")
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบFuno    ณ RUNCONT  บ Autor ณ AP5 IDE            บ Data ณ  21/01/09   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescrio ณ Funcao auxiliar chamada pela PROCESSA.  A funcao PROCESSA  บฑฑ
ฑฑบ          ณ monta a janela com a regua de processamento.               บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Programa principal                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

Static Function RunCont

Local nTamLin, cLin, cCpo
                            
MV_PAR01 := DtoS(dDataI)

cQry := " SELECT "
cQry += " CASE A1_LOJARP "
cQry += " 	WHEN ' ' THEN '0' "
cQry += " 	WHEN '0' THEN '0' "
cQry += " 	WHEN '1' THEN '1' "
cQry += " END   AS EMPRESA, 
cQry += " REPLICATE('0', ( 15 - Len(CAST(C6_NUM As Varchar))))+ CAST(C6_NUM As Varchar)As PEDIDO, "
cQry += " CASE A1_PESSOA "
cQry += " 	WHEN 'J' THEN REPLICATE('0', ( 14 - Len(CAST(A1_CGC As Varchar))))+ CAST(A1_CGC As Varchar)  "
cQry += "   WHEN 'F' THEN REPLICATE(' ', ( 14 - Len(CAST(A1_CGC As Varchar))))+ CAST(A1_CGC As Varchar)  "
cQry += " END As CNPJ_CPF , "
cQry += " SUBSTRING(C5_EMISSAO,7,2)+SUBSTRING(C5_EMISSAO,5,2) +SUBSTRING(C5_EMISSAO,1,4)  AS DATAEMISSAO, "
cQry += " SUBSTRING(C6_ENTREG,7,2)+SUBSTRING(C6_ENTREG,5,2)   +SUBSTRING(C6_ENTREG,1,4)  AS DATAPREVISTA, "
cQry += " CAST(C5_CONDPAG AS INT) AS CONDPAG, "
cQry += " CASE WHEN C5_CONDPAG = '00' "
cQry += "      then '000' "
cQry += "      else '001' "
cQry += " END AS FORMPAG, "
cQry += " C5_VEND1   AS VENDEDOR, "
cQry += " CAST(rtrim(C6_PRODUTO) AS INT) AS CODIGOITEM, "
cQry += " C6_CF      AS CODMOVTO, "
cQry += " REPLICATE('0', ( 18 - Len(CAST(C6_UNSVEN As DECIMAL(10,3))))) + replace(CAST(CAST(C6_UNSVEN AS DECIMAL(10, 3))AS VARCHAR),'.',',') as PESO, "
cQry += " REPLICATE('0', ( 10 - Len(CAST(C6_QTDVEN/B5_QE1 As Varchar)))) + replace(CAST(C6_QTDVEN/B5_QE1 AS varchar),'.',',') As QUANTIDADE, "
cQry += " REPLICATE('0', ( 15 - Len(CAST(C6_PRCVEN*B5_QE1 As DECIMAL(10,2))))) + replace(CAST(CAST(C6_PRCVEN*B5_QE1 AS DECIMAL(10, 2))AS VARCHAR),'.',',') as PRECOUNITARIO, "
cQry += " REPLICATE('0', ( 15 - Len(CAST(C6_VALOR As DECIMAL(10,2))))) + replace(CAST(CAST(C6_VALOR AS DECIMAL(10, 2))AS VARCHAR),'.',',') as VALORTOTAL "
cQry += " FROM SC6010,SC5010,SA1010,SB5010 "
cQry += " WHERE "
cQry += " SC6010.D_E_L_E_T_ = ' ' AND SA1010.D_E_L_E_T_ = ' ' AND SC5010.D_E_L_E_T_ = '  ' AND SB5010.D_E_L_E_T_ = '  '"
cQry += " AND A1_FILIAL = '  ' AND C6_FILIAL = '01' AND C5_FILIAL = '01' AND B5_FILIAL = '01' "
cQry += " AND C6_CLI = A1_COD AND C6_LOJA = A1_LOJA "
cQry += " AND C5_NUM = C6_NUM AND C5_CLIENTE = C6_CLI AND C5_LOJACLI = C6_LOJA "
cQry += " AND C6_PRODUTO = B5_COD "
cQry += " AND C6_TES IN ('547','586') "
cQry += " AND C5_EMISSAO =  '" + MV_PAR01 + "' "
cQry += " ORDER BY C6_NUM " 
	

If (Select("CLE") <> 0)
	dbSelectArea("CLE")
	dbCloseArea()
Endif
	
TCQUERY cQry NEW Alias "CLE"

ProcRegua(RecCount("CLE")) // Numero de registros a processar

dbGoTop()

While !EOF()

    //ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
    //ณ Incrementa a regua                                                  ณ
    //ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

    IncProc()

    //ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
    //บ Lay-Out do arquivo Texto gerado:                                บ
    //ฬออออออออออออออออัออออออออัอออออออออออออออออออออออออออออออออออออออน
    //บCampo           ณ Inicio ณ Tamanho                               บ
    //วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ	
	
	// EMPRESA			03	01
	// PEDIDO			05	20
	// CNPJ_CPF			26	14
	// DATAEMISSAO		41	08
	// DATAPREVISTA		50  08
	// CONDPAG			60	02
	// FORMPAG			63	03
	// VENDEDOR			67	04
	// CODIGOITEM		72	09
	// CODMOVTO			83	04
	// PESO				89	18
	// QUANTIDADE		109	10
	// PRECOUNITARIO	121	15
	// VALORTOTAL		138	15
	

    nTamLin := 152
    cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

    //ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
    //ณ Substitui nas respectivas posicioes na variavel cLin pelo conteudo  ณ
    //ณ dos campos segundo o Lay-Out. Utiliza a funcao STUFF insere uma     ณ
    //ณ string dentro de outra string.                                      ณ
    //ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

    cCpo := PADR(CLE->EMPRESA,03)  
    cLin := Stuff(cLin,01,03,cCpo)
    cCpo := PADR(CLE->PEDIDO,20)
    cLin := Stuff(cLin,05,20,cCpo)
    cCpo := PADR(CLE->CNPJ_CPF,14)
    cLin := Stuff(cLin,26,14,cCpo)
    cCpo := PADR(CLE->DATAEMISSAO,08)
    cLin := Stuff(cLin,41,08,cCpo)
    cCpo := PADR(CLE->DATAPREVISTA,08)
    cLin := Stuff(cLin,50,08,cCpo)
	cCpo := PADR(CLE->CONDPAG,03)
    cLin := Stuff(cLin,60,03,cCpo)
	cCpo := PADR(CLE->FORMPAG,03)
    cLin := Stuff(cLin,63,03,cCpo)
	cCpo := PADR(CLE->VENDEDOR,04)
    cLin := Stuff(cLin,67,04,cCpo)
	cCpo := PADR(CLE->CODIGOITEM,08)
    cLin := Stuff(cLin,73,09,cCpo)
	cCpo := PADR(CLE->CODMOVTO,04)
    cLin := Stuff(cLin,83,04,cCpo)
	cCpo := PADR(CLE->PESO,18)
    cLin := Stuff(cLin,89,18,cCpo)	
	cCpo := PADR(CLE->QUANTIDADE,10)
    cLin := Stuff(cLin,109,10,cCpo)
	cCpo := PADR(CLE->PRECOUNITARIO,15)
    cLin := Stuff(cLin,121,15,cCpo)
	cCpo := PADR(CLE->VALORTOTAL,15)
    cLin := Stuff(cLin,138,15,cCpo)
		
   
    //ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
    //ณ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ณ
    //ณ linha montada.                                                      ณ
    //ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

    If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
        If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
            Exit
        Endif   
    Endif
    	
    dbSkip()
    
EndDo

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ O arquivo texto deve ser fechado, bem como o dialogo criado na fun- ณ
//ณ cao anterior.                                                       ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

fClose(nHdl)
Close(oGeraTxt)

MsgBox('O arquivo '+cArqTxt+', foi gerado com sucesso!', 'Arquivo Gerado', 'INFO')

Return