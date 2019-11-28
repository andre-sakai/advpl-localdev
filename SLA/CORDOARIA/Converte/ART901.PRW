#INCLUDE "rwmake.ch"
#include "topconn.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ART901    º Autor ³ Clovis Emmendorfer º Data ³  19/03/07   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Ajuste do campo ultima compra no cadastro de clientes,     º±±
±±º          ³ conforme faturamento.                                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Especifico para Arteplas                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function ART901

Local bAcao := {|lFim| AlteraClientes(@lFim) }
Local cTitulo := 'Ultima Compra'
Local cMsg := 'Processando'
Local lAborta := .T.
PROCESSA( bAcao, cTitulo, cMsg, lAborta )
Return

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Static Function AlteraClientes(lFim)

dbSelectArea("SA1")
dbSetOrder(1)
dbGoTop()

ProcRegua(RecCount("SA1"))

dPriCom := " "
dUltCom := " "

While !EOF()
	
	If lFim
		Exit
	EndIf
	
	IncProc("Cliente: " + SA1->A1_COD)
	
	cQuery := "SELECT DISTINCT D2_EMISSAO "
	cQuery += "FROM " + RetSqlName("SD2") + " SD2, " + RetSqlName("SA1") + " SA1, "
	cQuery += " " + RetSqlName("SF4") + " SF4 "
	cQuery += "WHERE SD2.D_E_L_E_T_ <> '*' AND SA1.D_E_L_E_T_ <> '*' AND SF4.D_E_L_E_T_ <> '*' "
	cQuery += "AND D2_FILIAL = '" + xFilial("SD2") + "' "
	cQuery += "AND A1_FILIAL = '" + xFilial("SA1") + "' "
	cQuery += "AND F4_FILIAL = '" + xFilial("SF4") + "' "
	cQuery += "AND D2_TES <> '604' AND F4_DUPLIC = 'S' AND D2_TIPO = 'N' AND D2_TES = F4_CODIGO "
	cQuery += "AND D2_CLIENTE = '" + SA1->A1_COD + "' AND D2_LOJA = '" + SA1->A1_LOJA + "' "
	cQuery += "ORDER BY D2_EMISSAO "
	
	If (Select("CLE") <> 0)
		dbSelectArea("CLE")
		dbCloseArea()
	Endif
	
	TCQUERY cQuery NEW Alias "CLE"
	
	dbSelectArea("CLE")
	dbGoTop()
	
	dPriCom := CLE->D2_EMISSAO    
	
	While !EOF()
	
		dUltCom := CLE->D2_EMISSAO
		
		dbSelectArea("CLE")
		dbSkip()
		
	Enddo
	
	dbSelectArea("SA1")
	RecLock("SA1",.F.)
	SA1->A1_PRICOM := STOD(dPriCom)
	SA1->A1_ULTCOM := STOD(dUltCom)
	MsUnlock("SA1")
	
	dbSelectArea("SA1")
	dbSkip()       
	
	dPriCom := " "          
	dUltCom := " "
	
Enddo

Return
