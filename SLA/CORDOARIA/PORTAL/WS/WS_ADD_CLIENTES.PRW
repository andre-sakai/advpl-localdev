#Include 'Protheus.ch'
#Include 'apwebsrv.ch'
#Include 'TbiConn.ch'

WSSERVICE U_WANW002 DESCRIPTION "Servi�o de atualiza��o dos Clientes"// NAMESPACE "http://local.com.br/"
	
	WSDATA CNPJ				AS String
	WSDATA RazaoSocial		AS String
	WSDATA NomeFantasia		AS String
	WSDATA Estado			AS String
	WSDATA Tipo				As String
	WSDATA InsEstadual		AS String
	WSDATA InsMunicipal		AS String OPTIONAL
	WSDATA DataNasc			AS Date
	WSDATA HomePage			AS String OPTIONAL
	WSDATA DDD				AS String
	WSDATA Telefone			AS String
	WSDATA CEP				AS String
	WSDATA Email			AS String
	WSDATA EmailNFe			AS String
	WSDATA Endereco			AS String
	WSDATA Numero			AS String
	WSDATA Bairro			AS String
	WSDATA Complemento		AS String OPTIONAL
	WSDATA CodMunicipio		AS String
	WSDATA Observacao		AS String OPTIONAL
	WSDATA Vendedor			AS String
	WSDATA DataCadastro		AS Date
	WSDATA Suframa			AS String OPTIONAL
	WSDATA InsRural			AS String OPTIONAL 
	WSDATA NumeroDW	   		AS String
	WSDATA Atividade   		AS String
	WSDATA Conta 	  		AS String
	
	// Retorno do WEBSERVICE
	WSDATA RETORNO			AS String
	
	// Metodos do WEBSERVICE
	WSMETHOD atuCliente		DESCRIPTION "Inclusao/Atualizacao de Cliente - SA1"

ENDWSSERVICE

WSMETHOD atuCliente WSRECEIVE CNPJ, RazaoSocial, NomeFantasia, Estado, Tipo, InsEstadual, InsMunicipal, DataNasc, HomePage, DDD, Telefone, CEP, Email, EmailNFe, Endereco, Numero, Bairro, Complemento, CodMunicipio, Observacao,  Vendedor,  DataCadastro,  Suframa, InsRural, NumeroDW, Atividade, Conta   WSSEND RETORNO WSSERVICE U_WANW002

	Local aVetor	:= {}
	Local cCNPJ		:= Alltrim(UnMaskCNPJ(::CNPJ))
	Local cRazao	:= Upper(Alltrim(::RazaoSocial))
	Local cNReduz	:= Upper(Alltrim(::NomeFantasia))
	Local cEstado	:= Upper(Alltrim(::Estado))
	Local cTipo		:= Upper(AllTrim(::Tipo))						// F=Cons.Final;L=Produtor Rural;R=Revendedor;S=Solidario;X=Exportacao
	Local cInsc		:= Upper(Alltrim(::InsEstadual))
	Local cInscM	:= Upper(Alltrim(::InsMunicipal))
	Local dDataNasc	:= ::DataNasc
	Local cHPage	:= ::HomePage
	Local cDDD		:= ::DDD
	Local cTel		:= Upper(Alltrim(::Telefone))
	Local cCep		:= Upper(Alltrim(::CEP))
	Local cEmail	:= Upper(Alltrim(::Email))
	Local cEmailNFe	:= Upper(Alltrim(::EmailNFe))
	Local cEnd		:= Upper(Alltrim(::Endereco))+", " + Upper(Alltrim(::Numero)) 
	Local cBairro	:= Upper(Alltrim(::Bairro))
	Local cCompl	:= Upper(Alltrim(::Complemento))
	Local cCodMun	:= Upper(Alltrim(::CodMunicipio))
	Local cObs		:= Upper(Alltrim(::Observacao))
	Local cVend		:= Upper(Alltrim(::Vendedor))
	Local dDtCadas	:= ::DataCadastro
	Local cSuframa	:= ::Suframa
	Local cInsRural	:= ::InsRural 
	Local cNumDW	:= AllTrim(::NumeroDW)
	Local cAtividad	:= AllTrim(::Atividade)
	Local cConta	:= AllTrim(::Conta)
	
	Local cCodigo	:= ""
	Local cLoja		:= ""
	Local aGetCodCli:= {}
	
	Local cRetorno	:= ""
	Local lRet		:= .T.
	Local cAlias	:= GetNextAlias()
	Local cRaizCNPJ	:= ""
	Local nTamCdCli	:= 0
	Local aTables 	:= {"SA1"}
	
	Private lMsHelpAuto		:= .T.
	Private lAutoErrNoFile	:= .T.
	Private lMsErroAuto		:= .F.
	Private aAutoErro		:= {}
                        
	//�����������������������������������Ŀ
	//� Estabelece conexao com o Protheus �
	//�������������������������������������
	cEmpWel := "03"	//-> Empresa
	cFilWel := "01"	//-> Filial
	RpcSetType(3) //-> Nao consome licenca de uso
	If !RpcSetEnv(cEmpWel,cFilWel,,,"FAT",,{"SA1"},.F.,.F.)
		cMsgErro 	:=	"[U_WANW002] Erro ao tentar estabelecer conexao com a unidade: "+cEmpWel+cFilWel
		cObsWS 		:=	U_xDatAt()+" [ERRO] "+CRLF
		cObsWS 		+=	cMsgErro
		SetSoapFault("Retorno",cObsWS)
		ConOut(cObsWS)
		
		::RETORNO := "Erro ao realizar a inclusao do cliente. " + cObsWS
		lRet := .F.
	
		DelClassIntf() //-> Exclui todas classes de interface da thread
		RpcClearEnv()
		RESET ENVIRONMENT
		Return(lRet)
	Else
		lAuto	:=	.T.
	EndIf
	
	nTamCdCli	:= TamSX3("A1_COD")[1]
	
	If !(cTipo $ "FLRSX")
		_cMsgErro	:= "[U_WANW002] Tipo do cliente nao esta dentro dos parametros esperados: F=Cons.Final;L=Produtor Rural;R=Revendedor;S=Solidario;X=Exportacao"
		_cObs := alltrim(xDatAt()+"[ERRO]"+_cMsgErro)
		SetSoapFault("Retorno",_cObs)
		conout(_cObs)
		::RETORNO := "Erro ao realizar a atualizacao do Cliente " + _cObs
		lRet := .F.
	EndIf

	// Tratamento de variaveis locais
	cPessoa		:= Iif(Len(cCNPJ) < 14,"F","J")
	cRaizCNPJ	:= SubStr(cCNPJ,1,8)
	
	// Formatacao de codigo e loja.
	// A partir daqui nao pode mais usar AllTrim em nenhuma das 2 variaveis
	aGetCodCli := GetCodCli(cCNPJ)
	cCodigo := aGetCodCli[1]
	cLoja	:= aGetCodCli[2]
	cCodigo	:= PadR(cCodigo,nTamCdCli)
	
	// Campos fixos pelo padr�o		
	cNatureza	:= "9999" //"9999"
	cTpPessoa	:= "CI"
	cPaisBacen	:= "01058"
	cPais		:= "105"
	cOptSimples	:= "2"
	cOptSimplSC	:= "2"
	
	dbSelectArea("SA1")
	SA1->(dbSetOrder(RetOrder("SA1","A1_FILIAL+A1_CGC")))
	If SA1->(dbSeek(xFilial("SA1")+cCNPJ))
		_cMsgErro	:= "[U_WANW002] Cliente ja existe na base Protheus "
		_cObs := alltrim(xDatAt()+"[ERRO]"+_cMsgErro)
		SetSoapFault("Retorno",_cObs)
		conout(_cObs)
		::RETORNO := "Erro ao realizar a atualizacao do Cliente " + _cObs
		lRet := .F.
	Else
		nOpc := 3 // Inclusao
	EndIf

	If lRet
		aAdd(aVetor,{"A1_CGC"		,cCnpj			,Nil})
		aAdd(aVetor,{"A1_COD"		,cCodigo		,Nil})
		aAdd(aVetor,{"A1_LOJA"		,cLoja			,Nil})
		aAdd(aVetor,{"A1_TIPO"		,cTipo			,Nil})
		aAdd(aVetor,{"A1_NOME"		,cRazao			,Nil})
		aAdd(aVetor,{"A1_NREDUZ"	,cNReduz		,Nil})
		aAdd(aVetor,{"A1_PESSOA"	,cPessoa		,Nil})
		aAdd(aVetor,{"A1_EST"		,cEstado		,Nil})
		aAdd(aVetor,{"A1_SATIV1"	,cAtividad		,Nil})
		aAdd(aVetor,{"A1_INSCR"		,cInsc			,Nil})
		aAdd(aVetor,{"A1_INSCRM"	,cInscM			,Nil})
		aAdd(aVetor,{"A1_DTNASC"	,dDataNasc		,Nil})
		aAdd(aVetor,{"A1_HPAGE"		,cHPage			,Nil})
		aAdd(aVetor,{"A1_DDD"		,cDDD			,Nil})
		aAdd(aVetor,{"A1_TEL"		,cTel			,Nil})
		aAdd(aVetor,{"A1_CEP"		,cCep			,Nil})
		aAdd(aVetor,{"A1_EMAIL"		,cEmail			,Nil})
		aAdd(aVetor,{"A1_EMAILNF"	,cEmailNFe		,Nil})
		aAdd(aVetor,{"A1_END"		,cEnd			,Nil})
		aAdd(aVetor,{"A1_BAIRRO"	,cBairro		,Nil})
		aAdd(aVetor,{"A1_COMPLEM"	,cCompl			,Nil})
		aAdd(aVetor,{"A1_COD_MUN"	,cCodMun		,Nil})
		aAdd(aVetor,{"A1_OBS"		,cObs			,Nil})
		aAdd(aVetor,{"A1_VEND"		,cVend			,Nil})
		aAdd(aVetor,{"A1_DTCAD"		,dDtCadas		,Nil})
		aAdd(aVetor,{"A1_SUFRAMA"	,cSuframa		,Nil})
		aAdd(aVetor,{"A1_INSCRUR"	,cInsRural		,Nil})
		aAdd(aVetor,{"A1_CONTA"		,cConta			,Nil})
		aAdd(aVetor,{"A1_NATUREZ"	,cNatureza		,Nil})
		aAdd(aVetor,{"A1_TPESSOA"	,cTpPessoa		,Nil})
		aAdd(aVetor,{"A1_CODPAIS"	,cPaisBacen		,Nil})
		aAdd(aVetor,{"A1_PAIS"		,cPais			,Nil})
		aAdd(aVetor,{"A1_SIMPNAC"	,cOptSimples	,Nil})
		aAdd(aVetor,{"A1_SIMPLES"	,cOptSimplSC	,Nil})
		aAdd(aVetor,{"A1_MSBLQL"	,"1"			,Nil}) //-> Inclui o cliente sempre bloqueado. 1=Bloqueado 2=Ativo
		aAdd(aVetor,{"A1_RESTRIC"	,"2"			,Nil}) //-> Campo especifico do cliente        
		If SA1->(FieldPos("A1_XNUMDW")) > 0
			aAdd(aVetor,{"A1_XNUMDW"	,cNumDW		,Nil}) //-> Numero Pedido DW. Campo especifico do Cliente
		EndIf
		
		MSExecAuto({|x,y| Mata030(x,y)},aVetor,nOpc) // nOpc = 3 - inclus�o, 4 - Alteracao
		
		If lMsErroAuto
			aAutoErro := GETAUTOGRLOG()
			_cObs := alltrim(xDatAt()+"[U_WANW002] [ERRO]"+XCONVERRLOG(aAutoErro))
			SetSoapFault("Retorno",_cObs)
			conout(_cObs)
			::RETORNO := "Erro ao realizar a atualizacao do Cliente " + _cObs
			lRet := .F.
		Else
			//�����������������������������������������������Ŀ
			//� Verifica se o registro foi realmente incluido �
			//�������������������������������������������������
			SA1->(dbSetOrder(RetOrder("SA1","A1_FILIAL+A1_CGC")))
			If SA1->(dbSeek(xFilial("SA1")+cCNPJ))
				//��������������������������������������������������������Ŀ
				//� Alimenta Retorno do WS com o Codigo e Loja do Cliente. �
				//� Indicando que a integracao foi realizada com sucesso!  �
				//����������������������������������������������������������
				::RETORNO := SA1->A1_COD+SA1->A1_LOJA

				ConOut("[U_WANW002] Cliente "+IIf(nOpc==4,"alterado","incluido")+" com sucesso!")
				ConOut("[U_WANW002] Codigo: "+SA1->A1_COD+" Loja: "+SA1->A1_LOJA)

				//--> Cria conta contabil
				//--> Copia do P.E. M030Inc()
				XM030Inc()
		
			Else

				cMsgErro 	:= "[U_WANW002] CNPJ nao localizado apos inclusao do cliente"+CRLF
				cMsgErro	+= "CNPJ: " + Transform(cCNPJ,IIf(Len(cCNPJ)<14,"@R 999.999.999-99","@R 99.999.999/9999-99"))
				cObsWS 		:= U_xDatAt()+" [ERRO] "+CRLF
				cObsWS 		+= cMsgErro
				SetSoapFault(ProcName(),cObsWS)
				ConOut(cObsWS)
				
				::RETORNO := "Erro ao realizar a inclusao do cliente. " + cObsWS
				lRet := .F.

			EndIf
		EndIf
	EndIf
	
Return lRet

/*
+-------------------------------------------------------------------------------+
!Funcao/Metodo     	! xConverLog												!
+-------------------+-----------------------------------------------------------+
!Descricao			! Converte Log retirando informa�ies desnecess�rias e deixa	!
!					! apresentavel ao usu�rio									!
+-------------------+-----------------------------------------------------------+
!Autor             	! TSC679 - Charles Reitz									!
+-------------------+-----------------------------------------------------------+
!Data de Criacao   	! 08/03/2013                                              	!
+-------------------+-----------------------------------------------------------+
*/
Static Function xConverrLog(aAutoErro)

	Local cRet := ""
	Local _ni   := 1

	FOR _ni := 1 to Len(aAutoErro)
		cRet += CRLF+AllTrim(aAutoErro[_ni])
	NEXT _ni

RETURN cRet

/*
+-------------------------------------------------------------------------------+
!Funcao/Metodo     	! Data e Hora Atual											!
+-------------------+-----------------------------------------------------------+
!Descricao			! Retorna data e Hora Atual Convertido em Caracter			!
+-------------------+-----------------------------------------------------------+
!Autor             	! TSC679 - Charles Reitz									!
+-------------------+-----------------------------------------------------------+
!Data de Criacao   	! 08/03/2013                                              	!
+-------------------+-----------------------------------------------------------+
*/
Static Function xDatAt()

	Local cRet	:=	""
	cRet	:=	CRLF+"("+DTOC(DATE())+" "+TIME()+")"

Return cRet

/*/
������������������������������������������������������������������������������Ŀ
�Funcao    �UnMaskCNPJ            
������������������������������������������������������������������������������Ĵ
�Descri��o �Limpar o Conteudo do CNPJ             �
������������������������������������������������������������������������������Ĵ
�Sintaxe   �<vide parametros formais>              �
������������������������������������������������������������������������������Ĵ
�Parametros�<vide parametros formais>                 �
������������������������������������������������������������������������������Ĵ
�Uso       �WebService Pedido                            �
��������������������������������������������������������������������������������/*/
Static Function UnMaskCNPJ( cCNPJ )
	Local cCNPJClear := cCNPJ

	BEGIN SEQUENCE
		IF Empty( cCNPJClear )
			BREAK
		EndIF
		cCNPJClear := StrTran( cCNPJClear , "." , "" )
		cCNPJClear := StrTran( cCNPJClear , "/" , "" )
		cCNPJClear := StrTran( cCNPJClear , "-" , "" )
		cCNPJClear := AllTrim( cCNPJClear )
	END SEQUENCE
	
Return( cCNPJClear )

/*�����������������������������������������������������������������������������
�������������������������������������������������������������������������������
���������������������������������������������������������������������������Ŀ��
���Empresa     � Corda Brasil                                               ���
���������������������������������������������������������������������������Ĵ��
���Funcao      � GetCodCli  � Autor � Welinton Martins    � Data � 09/06/17 ���
���������������������������������������������������������������������������Ĵ��
���Descricao   � Pega o proximo numero e loja do cliente.                    ���
���            �                                                            ���
���������������������������������������������������������������������������Ĵ��
���Sintaxe     � GetCodCli(cCNPJ)                                           ���
���������������������������������������������������������������������������Ĵ��
���           ATUALIZACOES SOFRIDAS DESDE A CONSTRUCAO INICIAL              ���
���������������������������������������������������������������������������Ĵ��
���Programador � Data   � Motivo da alteracao                               ���
���������������������������������������������������������������������������Ĵ��
���            �  /  /  �                                                   ���
���            �        �                                                   ���
���������������������������������������������������������������������������Ĵ��
���Uso         � Especifico Corda Brasil                                    ���
����������������������������������������������������������������������������ٱ�
�������������������������������������������������������������������������������
������������������������������������������������������������������������������*/
Static Function GetCodCli(cCNPJ)

Local aArea		:=	GetArea()
Local aAreaA1	:=	SA1->(GetArea())
Local cQuery 	:=	""
Local cLjPadrao	:=	"01"
Local cLjCnpj	:= SubStr(cCNPJ,11,2)
Local aRet		:=	{}

Default cCNPJ	:=	""

cQuery := " SELECT ISNULL(A1_COD,'') AS RESULT "
cQuery += " FROM "+RetSqlName('SA1')
cQuery += " WHERE SubString(A1_CGC,1,8) = '"+SubStr(cCNPJ,1,8)+"' "
cQuery += " AND A1_CGC <> '"+cCNPJ+"' "
cQuery += " AND D_E_L_E_T_ = ' ' "

cQuery := ChangeQuery(cQuery)

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"RES",.F.,.T.)

If Empty(RES->RESULT)

	SA1->(dbSetOrder(3))
	If !SA1->(dbSeek(xFilial("SA1") + cCNPJ))
		
		//cQuery := " SELECT ISNULL(MAX(A1_COD),0) + 1 AS CODIGO "
		cQuery := " SELECT ISNULL(MAX(REPLICATE('0',(DATALENGTH(A1_COD)-LEN(A1_COD)))+RTRIM(LTRIM(A1_COD))),0) + 1 AS CODIGO "
		cQuery += " FROM "+RetSqlName('SA1')
		cQuery += " WHERE D_E_L_E_T_ = ' ' "
		
		cQuery := ChangeQuery(cQuery)
		
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMP",.F.,.T.)
		
		aAdd(aRet,TMP->CODIGO)			//-> CODIGO
		//aAdd(aRet,cLjPadrao)			//-> LOJA
		if len(cCnpj) == 14
			aAdd(aRet,cLjCnpj)
		else
			aAdd(aRet,cLjPadrao)
		endif
	Else
		aAdd(aRet,SA1->A1_COD)			//-> CODIGO
		if len(cCnpj) == 14
			aAdd(aRet,cLjCnpj)			//-> LOJA
		else
			aAdd(aRet,cLjPadrao)		//-> LOJA
		endif
	EndIf

Else
	
	aAdd(aRet,RES->RESULT) 		//-> CODIGO
	if len(cCnpj) == 14
		aAdd(aRet,cLjCnpj)		//-> LOJA
	else
		aAdd(aRet,cLjPadrao)	//-> LOJA
	endif

	SA1->(dbSetOrder(1))
	If SA1->(dbSeek(xFilial("SA1")+aRet[1]+aRet[2]))
	
		cQuery := " SELECT ISNULL(MAX(A1_LOJA),'00') AS LOJA "
		cQuery += " FROM "+RetSqlName('SA1')
		cQuery += " WHERE A1_COD = '"+aRet[1]+"' "
		cQuery += " AND D_E_L_E_T_ = ' ' "
	
		cQuery := ChangeQuery(cQuery)
		
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMP2",.F.,.T.)

		//aRet[2] := Soma1(TMP2->LOJA)

		if len(cCnpj) == 14
			aRet[2] := cLjCnpj			//-> LOJA
		else
			aRet[2] := Soma1(TMP2->LOJA)//-> LOJA
		endif
	    
	EndIf

EndIf

If Select("RES") > 0
	dbSelectArea("RES")
	dbCloseArea()
EndIf

If Select("TMP") > 0
	dbSelectArea("TMP")
	dbCloseArea()
EndIf

If Select("TMP2") > 0
	dbSelectArea("TMP2")
	dbCloseArea()
EndIf

RestArea(aAreaA1)
RestArea(aArea)

Return(aRet)

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �M030Inc   �Autor  �Marcelo J. Santos   � Data �  21/02/06   ���
�������������������������������������������������������������������������͹��
���Desc.     � Ponto de Entrada na Funcao de Inclusao de Cliente          ���
���          � Aqui Utilizado para Incluir a Conta Contabil no Plano de   ���
���          � Contas do Cliente que estah sendo incluido                 ���
�������������������������������������������������������������������������͹��
���Uso       � Especifico para Arteplas                                  ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function XM030Inc()

If SA1->A1_EST == "EX"  // Se for Cliente Exportacao nao cria conta, mantem a conta 11201010

	RecLock("SA1",.F.)
	SA1->A1_CONTA :=  "11201010"
	MsUnlock("SA1")

Else

	CT1->(dbSetOrder(1))
	CT1->(dbSeek(xFilial("CT1")+"11201"+SA1->A1_COD,.F.))
	If CT1->(Found())

		ConOut("[U_WANW002] Ja existe essa Conta no Plano de Contas")
		ConOut("[U_WANW002] Conta     : "+Trans(CT1->CT1_CONTA,"@9.9.9.99.999999"))
		ConOut("[U_WANW002] Descricao : "+Alltrim(CT1->CT1_DESC01))

	Else
		
		RecLock("CT1",.T.)
		CT1->CT1_FILIAL		:= xFilial("CT1")
		CT1->CT1_CONTA		:= "11201"+SA1->A1_COD
		CT1->CT1_DESC01		:= SA1->A1_NOME
		CT1->CT1_CLASSE		:= "2"
		CT1->CT1_NORMAL		:= "1"
		CT1->CT1_BLOQ 		:= "2"
		CT1->CT1_CVD02		:= "1"
		CT1->CT1_CVD03		:= "1"		
		CT1->CT1_CVD04		:= "1"
		CT1->CT1_CVD05		:= "1"				
		CT1->CT1_CVC02		:= "1"
		CT1->CT1_CVC03		:= "1"		
		CT1->CT1_CVC04		:= "1"
		CT1->CT1_CVC05		:= "1"				
		CT1->CT1_CTASUP		:= "11201"
		CT1->CT1_ACITEM		:= "1"
		CT1->CT1_ACCUST		:= "1"		
		CT1->CT1_ACCLVL		:= "1"
		CT1->CT1_DTEXIS		:= CtoD("01/01/80")
		CT1->CT1_AGLSLD		:= "2"						
		CT1->CT1_CCOBRG		:= "2"		
		CT1->CT1_ITOBRG		:= "2"		
		CT1->CT1_CLOBRG		:= "2"				
		MsUnlock("CT1")

		RecLock("SA1",.F.)
		SA1->A1_CONTA := "11201"+SA1->A1_COD
		MsUnlock("SA1")

		ConOut("[U_WANW002] A Conta Contabil foi Criada com Sucesso!")
		
	EndIf

EndIf 

Return()