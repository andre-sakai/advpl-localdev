#INCLUDE "rwmake.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �ART016    � Autor � AP5 IDE            � Data �  29/01/02   ���
�������������������������������������������������������������������������͹��
���Descricao � Codigo gerado pelo AP5 IDE.                                ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Implant.  � Clovis - TSC048                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP5 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function ART016()


//�������������������������������������������������������e��������������Ŀ
//� Declaracao de Variaveis                                             �
//�����������������������������������������������������������������������

Private cString
cOK := "U_IncluiX6()" // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
cDel := ".T." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.


Private cAlias := "SC5"

dbSelectArea("SC5")
dbSetOrder(1)
	AxCadastro(cAlias,"Liberacao de Carga",cDel,cOK)
Return


// Incluido em 09/06/11 - Eduardo Marquetti - Gravar dados de Faturamento Antecipado
User Function IncluiX6()

	dSaida	  := C5_SAIDA      
	cNum	  := C5_NUM
	nQuant	  := 0
    dAuxSaida := M->C5_SAIDA
 

	DbSelectArea("SC6")
	DbSetOrder(1)
	DbGoTOp()
	DbSeek(xFilial("SC6")+cNum,.T.)
	While !Eof() .and. C6_FILIAL==xFilial("SC6") .AND. C6_NUM== cNum
 		RecLock("SC6",.F.)
     
    	If dAuxSaida <> CTOD(" ") // A Data de Sa�da est� estabelecida ent�o n�o � Faturamento Antecipado
			C6_QDTSAI = C6_QTDVEN
			C6_SAIDA  = dAuxSaida
		EndIf                   
		
		If dAuxSaida = CTOD(" ") // N�o h� data de Sa�da Estabelecida - FATURAMENTO ANTECIPADO   
			C6_QDTSAI = 0 
			C6_SAIDA  = CTOD(" ")
		EndIf
		MsUnLock()
		DbSkip()
	EndDo
                               
Return(.T.)
