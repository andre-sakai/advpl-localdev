#Include 'Protheus.ch'
#Include 'TopConn.ch'
#include "rwmake.ch"
#include "TOTVS.CH"


/*=====================================================================*\
|	Data:		05/2015                                                 |
|	Autor :	    Júnior Conte                                            |
|	Módulo:		Financeiro                                              |
|	Tipo:		Relatório                                               |
|	Resumo:	    Relatorio Fluxo de caixa realizado                      |	                                                      |
\*=====================================================================*/


User Function KMA553()
Local aHelpPor	:= {}
Local aHelpEng	:= {}
Local aHelpSpa	:= {}     
Local vPerg		:= {}

Private aImpres := {}
Private aExcel  := {}
Private aCabec  := {}

Private cPerg	:= padr("KMA553", len(SX1->X1_GRUPO))

sfCriaSX1()



If !Pergunte(cPerg,.T.)
	Return
Endif


MsgRun( "Aguarde..." ,"Aguarde...",{|| SfGera() } )

return


Static Function SfGera()
Private aCols := {}
Private cCadastro := "Gerar Planilha"
	
	
//recebido em dinheiro
cSql := " SELECT E5_DTDISPO , SUM(E5_VALOR) E5_VALOR "
cSql += " FROM " + RetSqlName("SE5") + " SE5 "
cSql += "         INNER JOIN " + RetSqlName("SA6") + " SA6 ON SA6.A6_COD = SE5.E5_BANCO  AND SA6.A6_AGENCIA = SE5.E5_AGENCIA AND SA6.A6_NUMCON = SE5.E5_CONTA        "
cSql += "         WHERE E5_FILIAL BETWEEN  '"+MV_PAR03+"' AND '"+MV_PAR04+"' "
cSql += "         AND SE5.D_E_L_E_T_ = ' ' AND SA6.D_E_L_E_T_ = ' ' "
cSql += "         AND SA6.A6_FLUXCAI = 'S' AND SE5.E5_BANCO <> ' ' "
cSql += "         AND (  (E5_TIPODOC IN ('VL','RA') )  OR (E5_TIPODOC = 'TR' AND E5_MOTBX = 'NOR' )) " 
cSql += "         AND E5_TIPO NOT IN  " + FormatIn(MV_PAR07,",") + " " 
cSql += "         AND E5_RECPAG = 'R'  "
cSql += "         AND E5_SITUACA = ' '   "
cSql += "         AND E5_DTDISPO >= '"+DTOS(mv_par01)+"' "
cSql += "         AND (E5_DTDISPO <= '"+DTOS(mv_par02)+"' ) " 
cSql += "         AND NOT EXISTS (SELECT E5_TIPODOC FROM "  
cSql += "            " + RetSqlName("SE5") + " XE5 "
cSql += "         WHERE XE5.E5_FILIAL BETWEEN  '"+MV_PAR03+"' AND '"+MV_PAR04+"' "
cSql += "         AND D_E_L_E_T_ = ' '  " 
cSql += "         AND XE5.E5_PREFIXO = SE5.E5_PREFIXO " 
cSql += "         AND XE5.E5_NUMERO  = SE5.E5_NUMERO "
cSql += "         AND XE5.E5_PARCELA = SE5.E5_PARCELA "
cSql += "         AND XE5.E5_TIPO    = SE5.E5_TIPO "
cSql += "         AND XE5.E5_CLIFOR  = SE5.E5_CLIFOR  "
cSql += "         AND XE5.E5_LOJA    = SE5.E5_LOJA "
cSql += "         AND XE5.E5_SEQ     = SE5.E5_SEQ "
cSql += "         AND XE5.E5_TIPODOC = 'ES'  "
cSql += "         AND XE5.E5_RECPAG  = 'P' ) "
cSql += "     Group by E5_DTDISPO "
cSql += "     Order by E5_DTDISPO "


If (Select("_quer1") <> 0)
	dbSelectArea("_quer1")
	dbCloseArea()
Endif

TCQuery cSql NEW ALIAS "_quer1"
dbSelectArea("_quer1")

While _quer1 -> ( ! eof() )

	aadd(aCols, { stod(_quer1-> E5_DTDISPO) ,0,  _quer1 ->  E5_VALOR,0,0,0,0, 0})

	_quer1 -> ( dbSkip() )
Enddo



//a receber 
if mv_par09 == 1
	cSql := "SELECT E1_VENCREA, SUM(E1_VALOR) E1_VALOR "
	cSql += " FROM " + RetSqlName("SE1") +  " SE1 "
	cSql += " WHERE E1_FILIAL BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' "
	cSql += " AND SE1.D_E_L_E_T_ = ' '   "
	cSql += " AND E1_TIPO NOT IN " + FormatIn(MV_PAR05,",") + " "
	cSql += " AND E1_VENCREA BETWEEN '" + DTOS(MV_PAR01) + "' AND '" + DTOS(MV_PAR02) + "' "
	cSql += " GROUP BY E1_VENCREA "
	cSql += " ORDER BY E1_VENCREA " 
else
	cSql := "SELECT E1_VENCREA, SUM(E1_VALOR) E1_VALOR "
	cSql += " FROM " + RetSqlName("SE1") +  " SE1 "
	cSql += " WHERE E1_FILIAL BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' "
	cSql += " AND SE1.D_E_L_E_T_ = ' '    "
	cSql += " AND SE1.E1_PORTADO IN ( "
	cSql += " Select A6_COD From  " + RetSqlName("SA6") +  "  SA6 WHERE SA6.D_E_L_E_T_ = ' ' AND SA6.A6_ZFCREAL = '1' ) "
	cSql += " AND E1_TIPO NOT IN " + FormatIn(MV_PAR05,",") + " "
	cSql += " AND E1_VENCREA BETWEEN '" + DTOS(MV_PAR01) + "' AND '" + DTOS(MV_PAR02) + "' "
	cSql += " GROUP BY E1_VENCREA "
	cSql += " ORDER BY E1_VENCREA "
endif

If (Select("_quer1") <> 0)
	dbSelectArea("_quer1")
	dbCloseArea()
Endif

TCQuery cSql NEW ALIAS "_quer1"
dbSelectArea("_quer1")

While _quer1 -> ( ! eof() )
	nPos := 0
	nPos := Ascan(aCols, { |X| X[1] == stod(_quer1-> E1_VENCREA)})
	
	if nPos > 0 
		aCols[nPos][2] :=  _quer1 ->  E1_VALOR
	else
		aadd(aCols, { stod(_quer1-> E1_VENCREA) ,_quer1 ->  E1_VALOR,  0,0,0,0,0, 0})
	endif

	_quer1 -> ( dbSkip() )
Enddo



//Baixa sem movimento bancario 
cSql := " SELECT E5_DTDISPO , SUM(E5_VALOR) E5_VALOR "
cSql += " FROM " + RetSqlName("SE5") + " SE5 "
cSql += "         WHERE E5_FILIAL BETWEEN  '"+MV_PAR03+"' AND '"+MV_PAR04+"' "
cSql += "         AND D_E_L_E_T_ = ' ' "
cSql += "         AND E5_BANCO = ' ' "
//cSql += "       AND E5_TIPODOC IN ('VL','BA','V2','D2','J2','M2','CM','C2','TL','RA') " 
cSql += "         AND ( ( E5_TIPODOC IN ('CP') ) OR ( E5_TIPODOC = 'BA' AND E5_MOTBX <> 'CMP'  ) OR   ( E5_TIPODOC = 'V2' AND E5_BANCO <> ' '  )   )"
cSql += "         AND E5_TIPO NOT IN  " + FormatIn(MV_PAR07,",") + " " 
cSql += "         AND E5_RECPAG = 'R'  "
cSql += "         AND E5_SITUACA = ' '   "
cSql += "         AND E5_DTDISPO >= '"+DTOS(mv_par01)+"' "
cSql += "         AND (E5_DTDISPO <= '"+DTOS(mv_par02)+"' ) " 
cSql += "         AND NOT EXISTS (SELECT E5_TIPODOC FROM "  
cSql += "            " + RetSqlName("SE5") + " XE5 "
cSql += "         WHERE XE5.E5_FILIAL BETWEEN  '"+MV_PAR03+"' AND '"+MV_PAR04+"' "
cSql += "         AND D_E_L_E_T_ = ' '  " 
cSql += "         AND XE5.E5_PREFIXO = SE5.E5_PREFIXO " 
cSql += "         AND XE5.E5_NUMERO  = SE5.E5_NUMERO "
cSql += "         AND XE5.E5_PARCELA = SE5.E5_PARCELA "
cSql += "         AND XE5.E5_TIPO    = SE5.E5_TIPO "
cSql += "         AND XE5.E5_CLIFOR  = SE5.E5_CLIFOR  "
cSql += "         AND XE5.E5_LOJA    = SE5.E5_LOJA "
cSql += "         AND XE5.E5_SEQ     = SE5.E5_SEQ "
cSql += "         AND XE5.E5_TIPODOC = 'ES'  "
cSql += "         AND XE5.E5_RECPAG  = 'P' ) "
cSql += "     Group by E5_DTDISPO "
cSql += "     Order by E5_DTDISPO "


/*

cSql += "		 AND ( ( XE5.E5_TIPODOC = 'ES'  "
cSql += "		 AND XE5.E5_RECPAG  = 'P') OR (XE5.E5_RECPAG = 'R' AND XE5.E5_MOTBX = 'CMP' AND XE5.E5_TIPO IN ('RA', 'NCC')) ) ) "

cSql += "		 AND ( ( XE5.E5_TIPODOC = 'ES'  "
cSql += "		 AND XE5.E5_RECPAG  = 'R') OR (XE5.E5_RECPAG = 'P' AND XE5.E5_MOTBX = 'CMP' AND XE5.E5_TIPO IN ('PA', 'NDF')) )  ) "

*/

If (Select("_quer1") <> 0)
	dbSelectArea("_quer1")
	dbCloseArea()
Endif

TCQuery cSql NEW ALIAS "_quer1"
dbSelectArea("_quer1")

While _quer1 -> ( ! eof() )

	nPos := 0
	nPos := Ascan(aCols, { |X| X[1] == stod(_quer1-> E5_DTDISPO)})
	
	if nPos > 0 
		aCols[nPos][4] :=  _quer1 ->  E5_VALOR
	else
		aadd(aCols, { stod(_quer1-> E5_DTDISPO) ,0,  0,_quer1 ->  E5_VALOR,0,0,0, 0})
	endif

	_quer1 -> ( dbSkip() )
Enddo



//pago em dinheiro
cSql := " SELECT E5_DTDISPO , SUM(E5_VALOR) E5_VALOR "
cSql += " FROM " + RetSqlName("SE5") + " SE5 "
cSql += "         INNER JOIN " + RetSqlName("SA6") + " SA6 ON SA6.A6_COD = SE5.E5_BANCO  AND SA6.A6_AGENCIA = SE5.E5_AGENCIA AND SA6.A6_NUMCON = SE5.E5_CONTA        "
cSql += "         WHERE E5_FILIAL BETWEEN  '"+MV_PAR03+"' AND '"+MV_PAR04+"' "
cSql += "         AND SE5.D_E_L_E_T_ = ' ' AND SA6.D_E_L_E_T_ = ' ' "
cSql += "         AND SA6.A6_FLUXCAI = 'S' AND SE5.E5_BANCO <> ' ' "
//cSql += "       AND E5_TIPODOC IN ('VL','BA','V2','D2','J2','M2','CM','C2','TL','PA') " 
cSql += "         AND E5_TIPODOC IN ('VL','CH','PA') "
cSql += "         AND E5_TIPO NOT IN  " + FormatIn(MV_PAR08,",") + " " 
cSql += "         AND E5_RECPAG = 'P'  "
cSql += "         AND E5_SITUACA = ' '   "
cSql += "         AND E5_DTDISPO >= '"+DTOS(mv_par01)+"' "
cSql += "         AND (E5_DTDISPO <= '"+DTOS(mv_par02)+"' ) " 
cSql += "         AND NOT EXISTS (SELECT E5_TIPODOC FROM "  
cSql += "            " + RetSqlName("SE5") + " XE5 "
cSql += "         WHERE XE5.E5_FILIAL BETWEEN  '"+MV_PAR03+"' AND '"+MV_PAR04+"' "
cSql += "         AND D_E_L_E_T_ = ' '  " 
cSql += "         AND XE5.E5_PREFIXO = SE5.E5_PREFIXO " 
cSql += "         AND XE5.E5_NUMERO  = SE5.E5_NUMERO "
cSql += "         AND XE5.E5_PARCELA = SE5.E5_PARCELA "
cSql += "         AND XE5.E5_TIPO    = SE5.E5_TIPO "
cSql += "         AND XE5.E5_CLIFOR  = SE5.E5_CLIFOR  "
cSql += "         AND XE5.E5_LOJA    = SE5.E5_LOJA "
cSql += "         AND XE5.E5_SEQ     = SE5.E5_SEQ "
cSql += "         AND XE5.E5_TIPODOC = 'ES'  "
cSql += "         AND XE5.E5_RECPAG  = 'R' ) "
cSql += "     Group by E5_DTDISPO "
cSql += "     Order by E5_DTDISPO "


If (Select("_quer1") <> 0)
	dbSelectArea("_quer1")
	dbCloseArea()
Endif

TCQuery cSql NEW ALIAS "_quer1"
dbSelectArea("_quer1")

While _quer1 -> ( ! eof() )

	nPos := 0
	nPos := Ascan(aCols, { |X| X[1] == stod(_quer1-> E5_DTDISPO)})
	
	if nPos > 0 
		aCols[nPos][6] :=  _quer1 ->  E5_VALOR
	else
		aadd(aCols, { stod(_quer1-> E5_DTDISPO) ,0,  0,0,0,_quer1 ->  E5_VALOR,0, 0})
	endif


	_quer1 -> ( dbSkip() )
Enddo


//a pagar
cSql := "SELECT E2_VENCREA, SUM(E2_VALOR) E2_VALOR "
cSql += " FROM " + RetSqlName("SE2")
cSql += " WHERE E2_FILIAL BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' "
cSql += " AND D_E_L_E_T_ = ' ' "
cSql += " AND E2_TIPO NOT IN " + FormatIn(MV_PAR06,",") + " "
cSql += " AND E2_VENCREA BETWEEN '" + DTOS(MV_PAR01) + "' AND '" + DTOS(MV_PAR02) + "' "
cSql += " GROUP BY E2_VENCREA "
cSql += " ORDER BY E2_VENCREA "

If (Select("_quer1") <> 0)
	dbSelectArea("_quer1")
	dbCloseArea()
Endif

TCQuery cSql NEW ALIAS "_quer1"
dbSelectArea("_quer1")

While _quer1 -> ( ! eof() )
	nPos := 0
	nPos := Ascan(aCols, { |X| X[1] == stod(_quer1-> E2_VENCREA)})
	
	if nPos > 0 
		aCols[nPos][5] :=  _quer1 ->  E2_VALOR
	else
		aadd(aCols, { stod(_quer1-> E2_VENCREA) ,0,  0,0,_quer1 ->  E2_VALOR,0,0, 0})
	endif

	_quer1 -> ( dbSkip() )
Enddo

//pagamento sem movimento bancario 
cSql := " SELECT E5_DTDISPO , SUM(E5_VALOR) E5_VALOR "
cSql += " FROM " + RetSqlName("SE5") + " SE5 "
cSql += "         WHERE E5_FILIAL BETWEEN  '"+MV_PAR03+"' AND '"+MV_PAR04+"' "
cSql += "         AND D_E_L_E_T_ = ' ' "
cSql += "         AND E5_BANCO = ' ' "
cSql += "         AND (  ( E5_TIPODOC = 'CP' AND E5_MOTBX = 'CMP'  ) OR   ( E5_TIPODOC = 'BA' AND E5_MOTBX <> 'CMP'   )   )"
cSql += "         AND E5_TIPO NOT IN  " + FormatIn(MV_PAR08,",") + " " 
cSql += "         AND E5_RECPAG = 'P'  "
cSql += "         AND E5_SITUACA = ' '   "
cSql += "         AND E5_DTDISPO >= '"+DTOS(mv_par01)+"' "
cSql += "         AND (E5_DTDISPO <= '"+DTOS(mv_par02)+"' ) " 
cSql += "         AND NOT EXISTS (SELECT E5_TIPODOC FROM "  
cSql += "            " + RetSqlName("SE5") + " XE5 "
cSql += "         WHERE XE5.E5_FILIAL BETWEEN  '"+MV_PAR03+"' AND '"+MV_PAR04+"' "
cSql += "         AND D_E_L_E_T_ = ' '  " 
cSql += "         AND XE5.E5_PREFIXO = SE5.E5_PREFIXO " 
cSql += "         AND XE5.E5_NUMERO  = SE5.E5_NUMERO "
cSql += "         AND XE5.E5_PARCELA = SE5.E5_PARCELA "
cSql += "         AND XE5.E5_TIPO    = SE5.E5_TIPO "
cSql += "         AND XE5.E5_CLIFOR  = SE5.E5_CLIFOR  "
cSql += "         AND XE5.E5_LOJA    = SE5.E5_LOJA "
cSql += "         AND XE5.E5_SEQ     = SE5.E5_SEQ "
cSql += "         AND XE5.E5_TIPODOC = 'ES'  "
cSql += "         AND XE5.E5_RECPAG  = 'R' ) "
cSql += "     Group by E5_DTDISPO "
cSql += "     Order by E5_DTDISPO "

If (Select("_quer1") <> 0)
	dbSelectArea("_quer1")
	dbCloseArea()
Endif

TCQuery cSql NEW ALIAS "_quer1"
dbSelectArea("_quer1")

While _quer1 -> ( ! eof() )

	nPos := 0
	nPos := Ascan(aCols, { |X| X[1] == stod(_quer1-> E5_DTDISPO)})
	
	if nPos > 0 
		aCols[nPos][7] :=  _quer1 ->  E5_VALOR
	else
		aadd(aCols, { stod(_quer1-> E5_DTDISPO) ,0,  0,0,0,0,_quer1 ->  E5_VALOR, 0})
	endif

	_quer1 -> ( dbSkip() )
Enddo

Processa( {|| GerarArq( aCols  ) }, cCadastro, "Processando arquivo, aguarde...", .F. )

return


//Cria grupo de perguntas.
Static Function sfCriaSX1()
***************************

// Help dos parametros.
Local aHelpPor := {}


PutSx1(cPerg,"01","Data Inicial ?        	","","","mv_ch1","D",TamSx3("E5_DTDISPO")[1],0,0,"G","","",,   ,"mv_par01","","","","","","","","","","","","","","","","",aHelpPor,{},{})
PutSx1(cPerg,"02","Data Final ?	         	","","","mv_ch2","D",TamSx3("E5_DTDISPO")[1],0,0,"G","","",,   ,"mv_par02","","","","","","","","","","","","","","","","",aHelpPor,{},{})
PutSx1(cPerg,"03","Filial de  ?	         	","","","mv_ch3","C",TamSx3("E5_FILIAL")[1] ,0,0,"G","","SM0",,,"mv_par03","","","","","","","","","","","","","","","","",aHelpPor,{},{})
PutSx1(cPerg,"04","Filial ate ?	         	","","","mv_ch4","C",TamSx3("E5_FILIAL")[1] ,0,0,"G","","SM0",,,"mv_par04","","","","","","","","","","","","","","","","",aHelpPor,{},{})
PutSx1(cPerg,"05","Descons. Tipos a Receber      ","","","mv_ch5","C",60                     ,0,0,"G","","",,   ,"mv_par05","","","","","","","","","","","","","","","","",aHelpPor,{},{})
PutSx1(cPerg,"06","Descons. Tipos a Pagar        ","","","mv_ch6","C",60                     ,0,0,"G","","",,   ,"mv_par06","","","","","","","","","","","","","","","","",aHelpPor,{},{})

PutSx1(cPerg,"07","Descons. Tipos Recebido       ","","","mv_ch7","C",60                     ,0,0,"G","","",,   ,"mv_par07","","","","","","","","","","","","","","","","",aHelpPor,{},{})
PutSx1(cPerg,"08","Descons. Tipos Pagos          ","","","mv_ch8","C",60                     ,0,0,"G","","",,   ,"mv_par08","","","","","","","","","","","","","","","","",aHelpPor,{},{})


PutSx1(cPerg,"09","Considera CR c/Portador   ?	","","","mv_ch9","N",1                       ,0,0,"C","","",,   ,"mv_par09","Nao","","","","Sim","","","","","","","","","","","",aHelpPor,{},{})


return



//gera planilha
Static Function GerarArq( aCols )
   Local oFwMsEx := NIL
   Local cArq := ""
   Local cDir := GetSrvProfString("Startpath","")
   Local cWorkSheet := ""
   Local cTable := ""
   Local cDirTmp := GetTempPath()
   Local aPages := {}
   Local aTitles := {}
   Local xheader := {}
   Local aLinha := {}
   
   
   AADD(aPages,"Fluxo de Caixa Realizado")			        
   AADD(aTitles,"Fluxo de Caixa Realizado")	

//   Aadd( xheader, { "Vencimento", "Vencimento"                     ,                    , 8 ,  , ".F.", .t., "D",, "V" } ) 
//   Aadd( xheader, { "A Receber R$ " , "A Receber R$" 		       , "@R 999.999.999,99", 14, 2, ".F.", .t., "N",, "V" } )  
 //  Aadd( xheader, { "Recebido R$ " , "Recebido R$" 		           , "@R 999.999.999,99", 14, 2, ".F.", .t., "N",, "V" } ) 
//   Aadd( xheader, { "Bx S/Mov  (CR) R$ " , "Bx S/Mov  (CR) R$" 	   , "@R 999.999.999,99", 14, 2, ".F.", .t., "N",, "V" } )  
 //  Aadd( xheader, { "A Pagar R$ " , "A Pagar R$" 		           , "@R 999.999.999,99", 14, 2, ".F.", .t., "N",, "V" } )  
 //  Aadd( xheader, { "Pago R$    " , "Pago R$   " 		           , "@R 999.999.999,99", 14, 2, ".F.", .t., "N",, "V" } )
 //  Aadd( xheader, { "Bx S/Mov  (CP) R$" , "Bx S/Mov  (CP) R$" 	   , "@R 999.999.999,99", 14, 2, ".F.", .t., "N",, "V" } )	
 //  Aadd( xheader, { "Saldo R$    " , "Saldo R$   " 		           , "@R 999.999.999,99", 14, 2, ".F.", .t., "N",, "V" } )
 
   aCols := aSort(aCols,,,{|x,y| x[1] < y[1]})
 
   Aadd( xheader, { "           " ,  "          " 		           , , 9 , , ".F.", .t., "C",, "V" } )		    
   For n:= 1 to len(aCols)
   		Aadd( xheader, { dtoc(aCols[n][1]) ,  dtoc(aCols[n][1] )		           , "@R 999.999.999,99", 14, 2, ".F.", .t., "N",, "V" } )	
   Next
   
   Aadd( xheader, { "Total" ,  "Total"		           , "@R 999.999.999,99", 14, 2, ".F.", .t., "N",, "V" } )	
   
   aAdd(aLinha, Array(Len(xheader)))
   aAdd(aLinha, Array(Len(xheader)))
   aAdd(aLinha, Array(Len(xheader)))
   aAdd(aLinha, Array(Len(xheader)))
   aAdd(aLinha, Array(Len(xheader)))
   aAdd(aLinha, Array(Len(xheader)))
   aAdd(aLinha, Array(Len(xheader)))
   //aAdd(aLinha, Array(Len(xheader)))
   
 
   
   aLinha[1][1] := "A Receber      R$ "
   aLinha[2][1] := "Recebido 	   R$ "
   aLinha[3][1] := "Bx S/Mov  (CR) R$ "
   aLinha[4][1] := "A Pagar 	   R$ "
   aLinha[5][1] := "Pago		   R$ "
   aLinha[6][1] := "Bx S/Mov  (CP) R$ "
   aLinha[7][1] := "Saldo          R$ "
   
   //for nx := 1 to len(aLinha)
   aLinha[1][Len(xheader)] := 0
   aLinha[2][Len(xheader)] := 0
   aLinha[3][Len(xheader)] := 0
   aLinha[4][Len(xheader)] := 0
   aLinha[5][Len(xheader)] := 0
   aLinha[6][Len(xheader)] := 0
   aLinha[7][Len(xheader)] := 0
   
	for ny := 1 to len(aCols)
	   aLinha[1][ny + 1 ] 	   := aCols[ny][2]
	   aLinha[1][Len(xheader)] += aCols[ny][2]	   
	   
	   aLinha[2][ny + 1 ]      := aCols[ny][3]
	   aLinha[2][Len(xheader)] += aCols[ny][3]
	   		
	   aLinha[3][ny + 1 ] 		:= aCols[ny][4]
	   aLinha[3][Len(xheader) ] += aCols[ny][4]
	   
	   aLinha[4][ny + 1 ] := aCols[ny][5]
	   aLinha[4][Len(xheader)] += aCols[ny][5]
	   
	   aLinha[5][ny + 1 ] := aCols[ny][6]
	   aLinha[5][Len(xheader) ] += aCols[ny][6]
	   
	   aLinha[6][ny + 1 ] := aCols[ny][7]	
	   aLinha[6][Len(xheader) ] += aCols[ny][7]	
	      
	   aLinha[7][ny + 1 ] := ( aCols[ny][3] + aCols[ny][4] ) - ( aCols[ny][6] +  aCols[ny][7] )
	   aLinha[7][Len(xheader) ] += ( aCols[ny][3] + aCols[ny][4] ) - ( aCols[ny][6] +  aCols[ny][7] )
	next   		
   //next
   
   
   oFwMsEx := FWMsExcel():New()
   
  
	 
	//for xyz := 1 to len(aPages)

	  
	
	   cWorkSheet := "Fluxo de Caixa Realizado" 
	   
	 
	    cTable     := "Fluxo de Caixa Realizado" 
	  
	   	  	   
	   ProcRegua(0)
	   	   
	   oFwMsEx:AddWorkSheet( cWorkSheet )
	   oFwMsEx:AddTable( cWorkSheet, cTable )	
	   	   
	   for yy := 1 to len(xheader)
				oFwMsEx:AddColumn( cWorkSheet, cTable , xheader[yy][1]   , 1,1)			
	   next 
	   
	   for yz := 1 to len(aLinha)			
			IncProc()
			aTab := {}	
			oFwMsEx:AddRow( cWorkSheet, cTable, aLinha[yz] )					 	
		next		 
	   
								
		
		oFwMsEx:Activate()
		
		cArq := CriaTrab( NIL, .F. ) + ".xml"
		LjMsgRun( "Gerando o arquivo, aguarde...", cCadastro, {|| oFwMsEx:GetXMLFile( cArq ) } )
		If __CopyFile( cArq, cDirTmp + cArq )
		
				oExcelApp := MsExcel():New()
				oExcelApp:WorkBooks:Open( cDirTmp + cArq )
				oExcelApp:SetVisible(.T.)
		
				MsgInfo( "Arquivo " + cArq + " gerado com sucesso no diretório " + cDir )
			
		Else
			MsgInfo( "Arquivo não copiado para temporário do usuário." )
		Endif

	

Return

