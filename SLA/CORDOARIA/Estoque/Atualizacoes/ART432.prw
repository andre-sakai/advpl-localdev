#INCLUDE "rwmake.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  ART432    � Eduardo Marquetti           � Data �  04/06/18   ���
�������������������������������������������������������������������������͹��
���Descricao � Baixar Etiquetas MP e PI                                   ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       �                                                            ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function ART432()


//���������������������������������������������������������������������Ŀ
//� Declaracao de Variaveis                                             �
//�����������������������������������������������������������������������

Private cPerg   := "01"
Private cCadastro := "Baixar Etiquetas de Consumo/Apontamento -  MP / PI"
//���������������������������������������������������������������������Ŀ
//� Array (tambem deve ser aRotina sempre) com as definicoes das opcoes �
//� que apareceram disponiveis para o usuario. Segue o padrao:          �
//� aRotina := { {<DESCRICAO>,<ROTINA>,0,<TIPO>},;                      �
//�              {<DESCRICAO>,<ROTINA>,0,<TIPO>},;                      �
//�              . . .                                                  �
//�              {<DESCRICAO>,<ROTINA>,0,<TIPO>} }                      �
//� Onde: <DESCRICAO> - Descricao da opcao do menu                      �
//�       <ROTINA>    - Rotina a ser executada. Deve estar entre aspas  �
//�                     duplas e pode ser uma das funcoes pre-definidas �
//�                     do sistema (AXPESQUI,AXVISUAL,AXINCLUI,AXALTERA �
//�                     e AXDELETA) ou a chamada de um EXECBLOCK.       �
//�                     Obs.: Se utilizar a funcao AXDELETA, deve-se de-�
//�                     clarar uma variavel chamada CDELFUNC contendo   �
//�                     uma expressao logica que define se o usuario po-�
//�                     dera ou nao excluir o registro, por exemplo:    �
//�                     cDelFunc := 'ExecBlock("TESTE")'  ou            �
//�                     cDelFunc := ".T."                               �
//�                     Note que ao se utilizar chamada de EXECBLOCKs,  �
//�                     as aspas simples devem estar SEMPRE por fora da �
//�                     sintaxe.                                        �
//�       <TIPO>      - Identifica o tipo de rotina que sera executada. �
//�                     Por exemplo, 1 identifica que sera uma rotina de�
//�                     pesquisa, portando alteracoes nao podem ser efe-�
//�                     tuadas. 3 indica que a rotina e de inclusao, por�
//�                     tanto, a rotina sera chamada continuamente ao   �
//�                     final do processamento, ate o pressionamento de �
//�                     <ESC>. Geralmente ao se usar uma chamada de     �
//�                     EXECBLOCK, usa-se o tipo 4, de alteracao.       �
//�����������������������������������������������������������������������



//���������������������������������������������������������������������Ŀ
//� Monta um aRotina proprio                                            �
//�����������������������������������������������������������������������

Private aRotina := {{"Pesquisar","AxPesqui",0,1} ,;
             		{"Visualizar","AxVisual",0,2} ,;
             		{"Incluir","AxInclui",0,3} ,;
             		{"Alterar","AxAltera",0,4} ,;
             		{"Excluir","AxDeleta",0,5} ,;
                 	{"Apontar","U_Aponta",0,6} }

//���������������������������������������������������������������������Ŀ
//� Monta array com os campos para o Browse                             �
//�����������������������������������������������������������������������

Private aCampos := {{"FILIAL" ,"ZJ_FILIAL" ,"",00,00,"@!"} ,;
           			{"DATA"   ,"ZJ_DATA"   ,"",00,00,""} ,;
		   			{"SERIE"  ,"ZJ_SERIE"  ,"",00,00,"@!"} ,;
           			{"DOC"    ,"ZJ_DOC"	   ,"",00,00,"@!"} ,;
           			{"FORNECE","ZJ_FORNECE","",00,00,""} ,;
           			{"LOJA"   ,"ZJ_LOJA"   ,"",00,00,""} ,;
           			{"MP"     ,"ZJ_CODPRO" ,"",00,00,""} ,;
           			{"QUANT"  ,"ZJ_QUANT"  ,"",00,00,"@E 9,999,999,999.99"} ,;
           			{"CODBAR" ,"ZJ_CODBAR" ,"",00,00,""} ,;
		   			{"CARTAO" ,"ZJ_CARTAO" ,"",00,00,"@E 999"} ,;
		   			{"OBS"    ,"ZJ_OBS"    ,"",00,00,""} ,;
           			{"ID"     ,"ZJ_ID"     ,"",00,00,""} }

Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock

Private cString := "SZJ"

dbSelectArea("SZJ")
dbSetOrder(1)

cPerg   := "01"

Pergunte(cPerg,.F.)
SetKey(123,{|| Pergunte(cPerg,.T.)}) // Seta a tecla F12 para acionamento dos parametros

dbSelectArea(cString)
mBrowse( 6,1,22,75,cString,aCampos,)

Set Key 123 To // Desativa a tecla F12 do acionamento dos parametros
                   
Return	

Static Function _Aponta()
**************************

	Local aRot650 := {}
	Local nOpc     := 3 // inclusao
	Private lMsHelpAuto := .T.  // se .t. direciona as mensagens de help
	Private lMsErroAuto := .F. //necessario a criacao, pois sera
	//atualizado quando houver
	//alguma incosistencia nos parametros

	Sele TRB
	DbSetOrder(1)

//	cProd:=GetSx8Num("")                              
//	cProd:= GetSxENum("SC2")      
	
	cProd  := " "
	cAliasOld:=Alias()
	dbSelectArea("SC2")
	aAreaSC2:=GetArea()
	dbSetOrder(1)
	cProd := NextNumero("SC2",1,"C2_NUM",.T.)
	cProd := A261RetINV(cProd)	
	
	
	cItem:="01"
	cSequen:= "001"
	Sele SB1
	DbSetOrder(5)
	DbSeek(xFilial("SB1")+TRB->Produto)
	dFim := dDatabase // + 1
	Begin Transaction
	aRot650 := {{"C2_FILIAL"	,xFilial("SC2"),NIL},;
	{"C2_NUM"     ,cProd            ,NIL},;	
	{"C2_ITEM"    ,cItem           	,NIL},;
	{"C2_SEQUEN"  ,cSequen         	,NIL},;
	{"C2_PRODUTO" ,SB1->B1_COD  	,.F.},;
	{"C2_LOCAL"   ,SB1->B1_LOCPAD  	,NIL},;
	{"C2_CC"      ,"120300"		  	,NIL},;	
	{"C2_QUANT"   ,TRB->Quantid    	,NIL},;
	{"C2_UM"      ,SB1->B1_UM      	,NIL},;
	{"C2_DATPRI"  ,dDatabase       	,NIL},;
	{"C2_DATPRF"  ,dFim		       	,NIL},;
	{"C2_EMISSAO" ,dDatabase       	,NIL},;
	{"C2_PRIOR"  ,"500"		       	,NIL},;
	{"C2_STATUS" ,"N"		       	,NIL},;
	{"C2_TPOP"   ,"F"         		,NIL}} 

	MSExecAuto({|x,y| Mata650(x,y)},aRot650,nOpc)
	If lMsErroAuto
		DisarmTransaction()
		break
	EndIf
	ConfirmSx8()
	End Transaction

	If lMsErroAuto
	TONE(400,9)
		Mostraerro()
		Return .F.
	EndIf
Return