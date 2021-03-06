#include "rwmake.ch"   
#include "TOPCONN.CH"
#include "PRTOPDEF.CH"

User Function ART394() 

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
//� Declaracao de variaveis utilizadas no programa atraves da funcao    �
//� SetPrvt, que criara somente as variaveis definidas pelo usuario,    �
//� identificando as variaveis publicas do sistema utilizadas no codigo �
//� Incluido pelo assistente de conversao do AP5 IDE                    �
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

SetPrvt("CBTXT,CBCONT,NORDEM,ALFA,M_PAG,Z")
SetPrvt("M,TAMANHO,TITULO,CDESC1,CDESC2,CDESC3")
SetPrvt("CABEC1,CABEC2,ARETURN,NOMEPROG,CPERG,NLASTKEY")
SetPrvt("LCONTINUA,LI,NTOTAL,WNREL,CCONTA,NVAL")
SetPrvt("CPNUM,X,ASTRU,ARQTRAB,CSTRING,NTOTACRESC,NTOTDECRESC,NTOTIRRF,NTOTINSS,Ntot,PER01,PER02")
SetPrvt("cp_user,cp_solicit")

/*
複複複複複複複複複複複複複複複複複複複複複複複複複複複複複複複複複複複複複複�
굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇�
굇旼컴컴컴컴컴컴쩡컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴엽�
굇쿎liente      � ARTEPLAS                                                 낢�
굇쳐컴컴컴컴컴컴탠컴컴컴컴컴컴컴컴컫컴컴컴컴컴컴컫컴컴컴컴컴컴컴컴컴컴컴컴눙�
굇쿛rograma     � ART394.PRW       � Responsavel � EDUARDO MARQUETTI      낢�
굇쳐컴컴컴컴컴컴탠컴컴컴컴컴컴컴컴컨컴컴컴컴컴컴컨컴컴컴컴컴컴컴컴컴컴컴컴눙�
굇쿏escri뇙o    � Faturamento por Tipo de Sa�da (TES)                     낢�
굇쳐컴컴컴컴컴컴탠컴컴컴컴컴컴컴컴컫컴컴컴컴컴컴컫컴컴컴컴컴컴컴컴컴컴컴컴눙�
굇� Data        � 02/05/11         � Implantacao �                        낢�
굇쳐컴컴컴컴컴컴탠컴컴컴컴컴컴컴컴컨컴컴컴컴컴컴컨컴컴컴컴컴컴컴컴컴컴컴컴눙�
굇� Programador � Eduardo Marquetti                                       낢�
굇쳐컴컴컴컴컴컴탠컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴눙�
굇� Indices     �                                                         낢�
굇쳐컴컴컴컴컴컴탠컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴눙�
굇� Parametros  �                                                         낢�
굇쳐컴컴컴컴컴컴탠컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴눙�
굇� Observacoes �                                                         낢�
굇쳐컴컴컴컴컴컴탠컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴눙�
굇� Cuidados na �                                                         낢�
굇� Atualizacao �                                                         낢�
굇� de versao   �                                                         낢�
굇읕컴컴컴컴컴컴좔컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴袂�
굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇�
賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽�
*/

CbTxt   := ""
CbCont  := 0
nOrdem  := 0
Alfa    := 0
m_pag   := 1
Z       := 0
M       := 0
titulo  := "Faturamento por Tipo de Saida (TES)"
cDesc1  := PADC("Relat�rio Sint�tico de Faturamento por TES - Somente TES que geram Financeiro.",74)
cDesc2  := ""
cDesc3  := ""
//                  012345678901234567890123456789012345678901234567890123456789012345678901234567890"
//                  0        10        20        30        40        50        60        70        80"
cabec1          := "Tipo de Saida (TES)                                         VALOR"
//                  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                             999.999.999,99  
cabec2          := ""
aReturn         := { "Zebrado", 1, "Administracao", 1, 2, 1, "", 1}
nomeprog        :="ART394"
cPerg           :="ART394"
nLastKey        := 0     
cbtxt           := Space(10)
lContinua       := .T.
li              := 80
limite          := 80 //189
tamanho         := "P"     
nTipo           := 12
nTotal          := 0
wnrel           := "ART394"
aStru           := {}

nTotal			:= 0

Aadd(aStru,{"TOTAL   ","N",15,2})
Aadd(aStru,{"VALIPI  ","N",15,2})
Aadd(aStru,{"DESPESA ","N",15,2})
Aadd(aStru,{"ICMSRET ","N",15,2})
Aadd(aStru,{"SEGURO  ","N",15,2})       
Aadd(aStru,{"FRETE   ","N",15,2})
ArqTrab := criatrab(aStru,.t.)
dbUseArea(.T.,,ArqTrab,"TRBD2",.F.,.F.)

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//� Variaveis utilizadas para parametros                         �
//� mv_par01             // Data Inicial                         � 
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//� Verifica as perguntas selecionadas, busca o padrao           �
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸

Pergunte(cPerg,.F.)               // Pergunta no SX1
cString := "SD2"

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//� Envia controle para a funcao SETPRINT                        �
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸

SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.T.)

If nLastKey == 27
	    Return
Endif

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//� Verifica Posicao do Formulario na Impressora                 �          
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
SetDefault(aReturn,cString)

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//�                                                              �
//� Inicio do Processamento da Relatorio                         �
//�                                                              �
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸

RptStatus({|| RptDetail()})// Substituido pelo assistente de conversao do AP5 IDE em 14/06/00 ==> 	RptStatus({|| Execute(RptDetail)})
Return
Static Function RptDetail()

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//� Salva posicoes para movimento da regua de processamento      �
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸

Sele SD2
DbSetOrder(01) // SD2 ...
dbgotop()
setregua(reccount())


cQuery := "SELECT D2_TES AS TES,SUBSTRING(F4_DESC,1,30) AS NOMTES, SUM(D2_TOTAL+D2_VALIPI+D2_SEGURO+D2_VALFRE) AS TOTAL "
cQuery += "FROM " + RETSQLNAME("SD2") +" SD2"  +","+ RETSQLNAME("SF4") + " SF4 " "
cQuery += "WHERE SD2.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' AND "
cQuery += "D2_FILIAL = '" + xFilial("SD2") + "' AND "
cQuery += "D2_TES = F4_CODIGO AND "
cQuery += "D2_EMISSAO BETWEEN '" + DTOS(mv_par01) + "' AND '" + DTOS(mv_par02) + "' AND "
cQuery += "(D2_TIPO = 'N' OR D2_TIPO = 'C') AND F4_DUPLIC = 'S' "
cQuery += "GROUP BY D2_TES,F4_DESC "
cQuery += "ORDER BY D2_TES "
cQuery := ChangeQuery(cQuery) 
                                                                                               
If Select("TRB") <> 0
   dbSelectarea("TRB")      
   dbCloseArea("TRB")      
End   

TCQUERY cQuery ALIAS TRB NEW

// Datas e Valores

TCSETFIELD("TRB","TOTAL   ","N",15,2)
Sele TRB
dbGoTop()
SetRegua(reccount())         

While !EOF("TRB") 
	If li >= 60
    	Cabec(titulo,cabec1,cabec2,nomeprog,tamanho,15)
    Endif
    
    @ li , 000 Psay TRB->TES
    @ li , 005 pSay TRB->NOMTES
    @ li , 057 Psay TRB->TOTAL picture "@E 999,999,999.99"
    li := li + 1
    nTotal := Ntotal + TRB->TOTAL

    If li >= 60
    	Cabec(titulo,cabec1,cabec2,nomeprog,tamanho,15)
    Endif

    Sele TRB
    Incregua()
    Skip                
End  

@ li , 000 Psay "------------------------------"  
li := li + 1     
@ li , 000 Psay "Total"  
@ li , 057 Psay nTotal picture "@E 999,999,999.99" 
li := li + 1     
@ li , 000 Psay "Periodo: " + DTOC(MV_PAR01) + " a " + DTOC(MV_PAR02)
li := li + 1

If li >= 60
   Cabec(titulo,cabec1,cabec2,nomeprog,tamanho,15)
Endif

li:= 60

Roda(cBCONT,cBTXT,"M")
dbSelectArea("TRBD2")
Use

If aReturn[5] == 1
   Set Printer TO 
   dbcommitAll()
   ourspool(wnrel)
Endif

ms_flush()
Return