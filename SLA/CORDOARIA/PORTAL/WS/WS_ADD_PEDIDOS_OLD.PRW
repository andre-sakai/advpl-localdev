#Include 'Protheus.ch'
#Include 'apwebsrv.ch'
#Include 'TbiConn.ch'


/*/
зддддддддддбдддддддддддддддддддддддбдддддбддддддддддддддддддддбдддддбдддддддддд©
ЁWSSTRUCT  ЁtAddPedidoDet        
цддддддддддедддддддддддддддддддддддадддддаддддддддддддддддддддадддддадддддддддд╢
ЁDescri┤┘o ЁEstrutura dos Detalhes de Inclusao de Pedidos                      Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁSintaxe   Ё<vide parametros formais>              Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁParametrosЁ<vide parametros formais>                 Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁUso       ЁWebService Pedido                            Ё
юддддддддддаддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды/*/

WSSTRUCT tAddPedidoDet

	WSDATA ProdutoPedido		AS String	//C6_PRODUTO
	WSDATA PrecoVendaProduto	AS Float	//C6_PRCVEN
	WSDATA QuantidadeProduto	AS Float	//C6_QTDVEN  
//	WSDATA NumeroProduto        AS Float	//C6_XITEMDW 
	
ENDWSSTRUCT

/*/
зддддддддддбдддддддддддддддддддддддбдддддбддддддддддддддддддддбдддддбдддддддддд©
ЁWSSTRUCT  ЁtAddPedidoCab        
цддддддддддедддддддддддддддддддддддадддддаддддддддддддддддддддадддддадддддддддд╢
ЁDescri┤┘o ЁEstrutura do Cabecalho de Inclusao de Pedidos                      Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁSintaxe   Ё<vide parametros formais>              Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁParametrosЁ<vide parametros formais>                 Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁUso       ЁWebService Pedido                            Ё
юддддддддддаддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды/*/

WSSTRUCT tAddPedidoCab

	WSDATA Transportadora			AS String	//C5_TRANSP
	WSDATA Redespacho				AS String	//C5_REDESP
	WSDATA CondicaoPagamento		AS String	//C5_CONDPAG
	WSDATA TabelaPreco				AS String	//C5_TABELA
	WSDATA DataEntrega				As Date		//C5_ENTREG
	WSDATA PedidoCliente			AS String	//C5_PEDCLI
	WSDATA TipoFrete				As String	//C5_TPFRETE
	WSDATA Operacao					As String	// ITENS - C6_OPER
	WSDATA CodigoVendedor			As String	//C5_VEND1
	//WSDATA Banco					AS String	//C5_BANCO   
	WSDATA FilialCodigo				As String	//C5_FILIAL
	WSDATA Observacao				As String	OPTIONAL	//C5_OBS
	WSDATA MensagemNotaFiscal		As String	OPTIONAL	//C5_MENNOTA
	WSDATA PedidoDW					AS String	//C5_XPEDDW

	WSDATA tzItensDoPedido			AS Array Of tAddPedidoDet
	
ENDWSSTRUCT


/*/
зддддддддддбдддддддддддддддддддддддбдддддбддддддддддддддддддддбдддддбдддддддддд©
ЁWSSERVICE ЁTEXW006    
цддддддддддедддддддддддддддддддддддадддддаддддддддддддддддддддадддддадддддддддд╢
ЁDescri┤┘o ЁServiГo de consulta e atualizaГЦo dos pedidos de venda Pedido    Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁSintaxe   Ё<vide parametros formais>              Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁParametrosЁ<vide parametros formais>                 Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁUso       ЁWebService Pedido                            Ё
юддддддддддаддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды/*/

WSSERVICE U_WANW001 DESCRIPTION "ServiГo de atualizaГЦo dos pedidos de venda" // NAMESPACE "http://local.com.br/" 

	//--> Recebe
	WSDATA CNPJ				AS String
	WSDATA tAddPedido		AS tAddPedidoCab
	
	//--> Retorno
	WSDATA NumeroDoPedido	AS String
	WSDATA WsStrDel			AS String
    
	//--> Metodos
	WSMETHOD AddPedidoPeca      DESCRIPTION "MИtodo de InclusЦo do Pedido de Venda"
	//WSMETHOD DelPedidoPeca      DESCRIPTION "MИtodo de exclusЦo do pedido de venda"

ENDWSSERVICE

/*/
зддддддддддбдддддддддддддддддддддддбдддддбддддддддддддддддддддбдддддбдддддддддд©
ЁWSMETHOD  ЁAddPedidoPeca    
цддддддддддедддддддддддддддддддддддадддддаддддддддддддддддддддадддддадддддддддд╢
ЁDescri┤┘o ЁAdicionar Pedido de Peca             Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁSintaxe   Ё<vide parametros formais>              Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁParametrosЁ<vide parametros formais>                 Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁUso       ЁWebService Pedido                            Ё
юддддддддддаддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды/*/

WSMETHOD AddPedidoPeca WSRECEIVE CNPJ, tAddPedido WSSEND NumeroDoPedido WSSERVICE U_WANW001

	Local aArea		:=	{}
	Local aAreaA1	:=	{}
	Local aAreaB1	:=	{}
	Local aAreaC5	:=	{}
	Local aAreaC6	:=	{}
	Local aAreaC9	:=	{}
	
	Local aCab		:= {}
	Local aItens	:= {}
	Local aErros	:= {}

	Local cStrErro		:= ""
	Local cSC5Filial	:= ""
	Local cSA1Filial	:= ""

	Local cLojaCliente	:= ""
	Local cCodigoCliente:= ""

	Local lReturn		:= .T.

	Local nErro		:= 0
	Local nErros	:= 0

	PRIVATE lMsErroAuto     := .F.
	PRIVATE lAutoErrNoFile	:= .T.

	//зддддддддддддддддддддддддддддддддддд©
	//Ё Estabelece conexao com o Protheus Ё
	//юддддддддддддддддддддддддддддддддддды
	cEmpWel := "03"			   				//-> Empresa
	cFilWel := ::tAddPedido:FilialCodigo	//-> Filial
	//cFilWel := "01"	//-> Filial
	RpcSetType(3) //-> Nao consome licenca de uso
	If !RPCSetEnv(cEmpWel,cFilWel,,,"FAT",,{"SA1","SA3","SB1","SC5","SC6","SC9"},.F.,.F.)	//-> Set novo ambiente
		cMsgErro 	:=	"[U_WSFDV001] Erro ao tentar estabelecer conexao com a unidade: "+cEmpWel+cFilWel
		cObsWS 		:=	AllTrim(U_xDatAt()+" [ERRO] "+cMsgErro)
		SetSoapFault(ProcName(),cObsWS)
		ConOut(cObsWS)
		
		::NumeroDoPedido := "Erro ao realizar a inclusao do pedido. " + cObsWS
		lRet := .F.
	
		DelClassIntf() //-> Exclui todas classes de interface da thread
		RPCClearEnv()
		RESET ENVIRONMENT
		Return(lRet)
	Else
		lAuto	:=	.T.
	EndIf
	
	//здддддддддддддддддддддддддддддддд©
	//Ё Tratamento de variaveis locais Ё
	//юдддддддддддддддддддддддддддддддды
	aArea	:=	GetArea()
	aAreaA1	:=	SA1->(GetArea())
	aAreaB1	:=	SB1->(GetArea())
	aAreaC5	:=	SC5->(GetArea())
	aAreaC6	:=	SC6->(GetArea())
	aAreaC9	:=	SC9->(GetArea())
	
	BEGIN SEQUENCE
    
		IF Empty(::CNPJ)
			lReturn := .F.
			SetSoapFault( "AddPedidoPeca" , "Cliente invАlido" )

			BREAK
		EndIF
 
		::CNPJ := UnMaskCNPJ( ::CNPJ )

		cSA1Filial   := xFilial( "SA1" )
 
		SA1->( dbSetOrder( RetOrder( "SA1" , "A1_FILIAL+A1_CGC" ) ) )

		IF SA1->( !dbSeek( cSA1Filial + ::CNPJ , .F. ) )

			lReturn := .F.
			SetSoapFault( "AddPedidoPeca" , "CNPJ InvАlido" + " " + cSA1Filial + " " +::CNPJ  ) //"CNPJ invаlido"

			BREAK
		EndIF
		
		SA1->( dbSetOrder( RetOrder( "SA1" , "A1_FILIAL+A1_COD+A1_LOJA" ) ) )

		cLojaCliente  	:= SA1->A1_LOJA
		cCodigoCliente  := SA1->A1_COD

		SC5->( dbSetOrder( RetOrder( "SC5" , "C5_FILIAL+C5_NUM" ) ) )

		cSC5Filial := xFilial( "SC5" )
 
		SC5->( MsGoto( 0 ) )
 
		/*/
		здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
		ЁAtualiacao do cabecalho do pedido de venda                              Ё
		юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды/*/
		lReturn := PutPvHead( ::tAddPedido , @aCab , @cCodigoCliente , @cLojaCliente )

		IF !( lReturn )
			SetSoapFault( "AddPedidoPeca" , "Problema no cabeГalho do Pedido" )

			BREAK
		EndIF

		/*/
		здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
		ЁAtualiacao dos itens do pedido de venda                                 Ё
		юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды/*/
		lReturn := PutPvItem( @::tAddPedido , @::tAddPedido:tzItensDoPedido , @aItens )

		IF !( lReturn )
			SetSoapFault( "AddPedidoPeca" , "Problema nos Itens do Pedido" )

			BREAK
		EndIF

		/*/
		здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
		Ё Efetiva a Inclusao do Pedido            Ё
		юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды/*/
		lMsErroAuto := .F.
		MSExecAuto({|x,y,z| MATA410(x,y,z)},aCab,aItens,3) //-> 3=Inclusao; 4=Alteracao; 5=Exclusao

		/*/
		здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
		Ё Verifica a ocorrencia de Erros na Inclusao do Pedido      Ё
		юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды/*/
		If lMsErroAuto
			aAutoErro := GETAUTOGRLOG()
			_cObs := alltrim(xDatAt()+"[U_WSFDV001] [ERRO]"+XCONVERRLOG(aAutoErro))
			SetSoapFault( "AddPedidoPeca" , _cObs )
			conout(_cObs)
			
			::NumeroDoPedido := "Erro ao realizar a inclusao do pedido. " + _cObs
			
			lReturn := .F.
			BREAK     
			
		EndIF

   		//зддддддддддддддддддддддддддддддддддддддддддддддд©
		//Ё Verifica se o registro foi realmente incluido Ё
		//юддддддддддддддддддддддддддддддддддддддддддддддды
		SC5->(dbSetOrder(RetOrder("SC5","C5_FILIAL+C5_NUM")))
		If SC5->(dbSeek(SC5->C5_FILIAL+SC5->C5_NUM))
			//зддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
			//Ё Alimenta Retorno do WS com a Filial e Numero do Pedido. Ё
			//Ё Indicando que a integracao foi realizada com sucesso!   Ё
			//юддддддддддддддддддддддддддддддддддддддддддддддддддддддддды
			::NumeroDoPedido := SC5->C5_NUM //SC5->C5_FILIAL+SC5->C5_NUM
			//::NumeroDoPedido := "123456"

			ConOut("[U_WSFDV001] Pedido incluido com sucesso!")
			ConOut("[U_WSFDV001] Filial: "+SC5->C5_FILIAL+" Pedido: "+SC5->C5_NUM)
		Else
			cMsgErro 	:= "[U_WSFDV001] Pedido nao localizado apos a inclusao"
			cObsWS 		:= AllTrim(U_xDatAt()+" [ERRO] "+cMsgErro)
			SetSoapFault(ProcName(),cObsWS)
			ConOut(cObsWS)
				
			::NumeroDoPedido := "Erro ao realizar a inclusao do pedido. " + cObsWS
			lRet := .F.
			
			Break
			
		EndIf

	END SEQUENCE

	RestArea(aArea)
	RestArea(aAreaA1)
	RestArea(aAreaB1)
	RestArea(aAreaC5)
	RestArea(aAreaC6)
	RestArea(aAreaC9)

	If lAuto
		DelClassIntf() //-> Exclui todas classes de interface da thread
		RpcClearEnv()
		RESET ENVIRONMENT
	EndIf

Return( lReturn )

/*/
зддддддддддбдддддддддддддддддддддддбдддддбддддддддддддддддддддбдддддбдддддддддд©
ЁFunction  ЁPutPvHead        
цддддддддддедддддддддддддддддддддддадддддаддддддддддддддддддддадддддадддддддддд╢
ЁDescri┤┘o ЁGrava e/ou Altera o Cabecalho do Pedido de Venda                   Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁSintaxe   Ё<vide parametros formais>              Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁParametrosЁ<vide parametros formais>                 Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁUso       ЁWebService Pedido                            Ё
юддддддддддаддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды/*/

Static Function PutPvHead( oObj , aCab , cCodigoCliente , cLojaCliente )

	Local aArea 	:= GetArea()
	Local aAreaSA4 	:= SA4->(GetArea())
	Local lReturn	:= .T.
	Local cCondPag	:= PadR(oObj:CondicaoPagamento,TamSX3("E4_CODIGO")[1])
	Local cMsgNF	:= ""
	Local cRedesp	:= PadR(oObj:Redespacho,TamSX3("C5_REDESP")[1])
	
	//--> Mensagem Nota Fiscal p/ Redespacho
	If !Empty(cRedesp)
		dbSelectArea("SA4")
		dbSetOrder(1)
		If SA4->(dbSeek(xFilial("SA4")+cRedesp))
			cMsgNF += "REDESPACHO (FOB): "+AllTrim(SA4->A4_NOME)+" CNPJ/CPF: "+TransForm(SA4->A4_CGC,"@R 99.999.999/9999-99")+;
			" I.E.: "+SA4->A4_INSEST+" End.: "+AllTrim(SA4->A4_END)+IIf(!Empty(SA4->A4_COMPLEM),", Complemento: "+AllTrim(SA4->A4_COMPLEM)," ")+;
			" Bairro: "+AllTrim(SA4->A4_BAIRRO)+" CEP: "+TransForm(SA4->A4_CEP,"@R 99999-999")+" "+AllTrim(SA4->A4_MUN)+" / "+SA4->A4_EST+"  |  "
		EndIf
	EndIf
	//--> Mensagem Nota Fiscal DW
	cMsgNF += AllTrim(oObj:MensagemNotaFiscal)
	 
	/*/
	здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
	ЁAtualiacao do cabecalho do pedido de venda                              Ё
	юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды/*/
	// Campos fixos 
	aAdd( aCab , { "C5_FILIAL"	, xFilial("C5_FILIAL")				, NIL } )
	aAdd( aCab , { "C5_EMISSAO"	, dDataBase      	   				, NIL } )
	aAdd( aCab , { "C5_TIPO"	, "N"				  				, NIL } )
	// Campos de variaveis
	aAdd( aCab , { "C5_CLIENTE"	, cCodigoCliente	 				, NIL } )
	aAdd( aCab , { "C5_LOJACLI"	, cLojaCliente		  				, NIL } )
	aAdd( aCab , { "C5_CLIENT"	, cCodigoCliente	  				, NIL } )
	aAdd( aCab , { "C5_LOJAENT"	, cLojaCliente		   				, NIL } )
	// Campos do WS
	aAdd( aCab , { "C5_TABELA"	, AllTrim(oObj:TabelaPreco)			, NIL } )
	aAdd( aCab , { "C5_CONDPAG"	, AllTrim(oObj:CondicaoPagamento)	, NIL } )
	aAdd( aCab , { "C5_VEND1"	, AllTrim(oObj:CodigoVendedor) 		, NIL } )
	aAdd( aCab , { "C5_TPFRETE"	, Upper(oObj:TipoFrete)		   		, NIL } )
	aAdd( aCab , { "C5_TRANSP"	, AllTrim(oObj:Transportadora)		, NIL } )
	aAdd( aCab , { "C5_REDESP"	, AllTrim(oObj:Redespacho)	 		, NIL } )
	//aAdd( aCab , { "C5_ENTREG"	, AllTrim(oObj:DataEntrega)	 	, NIL } ) // verificar
	aAdd( aCab , { "C5_PEDCLI"	, AllTrim(oObj:PedidoCliente)		, NIL } )
	aAdd( aCab , { "C5_MENNOTA"	, cMsgNF				  			, NIL } )
	If SC5->(FieldPos("C5_OBS")) > 0
		aAdd( aCab , { "C5_OBS"		, FwNoAccent(oObj:Observacao)	, NIL } ) // Campo customizado do cliente
	EndIf
	If SC5->(FieldPos("C5_XPEDDW")) > 0
		aAdd( aCab , { "C5_XPEDDW"	, AllTrim(oObj:PedidoDW)		, NIL } )
	EndIf	
	
	/*/
	здддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
	Ё Preenche a tab. de preco de acordo com o cad. de cliente Ё
	юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддды/*/
	/*
	SA1->( dbSetOrder( RetOrder( "SA1" , "A1_FILIAL+A1_COD+A1_LOJA" ) ) )
	IF SA1->( dbSeek( xFilial( "SA1" ) + cCodigoCliente + cLojaCliente , .F. ) )
		IF !Empty( SA1->A1_TABELA )
			aAdd( aCab , { "C5_TABELA" , SA1->A1_TABELA , NIL } )
		Else
			aAdd( aCab , { "C5_TABELA" , NIL    , NIL } )
		EndIF
		IF !Empty(SA1->A1_DESC)
			aAdd( aCab , { "C5_DESC1" , SA1->A1_DESC  , NIL } )
		Else
			aAdd( aCab , { "C5_DESC1" , 0    , NIL } )
		EndIF
	EndIF
	*/
	//aAdd( aCab , { "C5_MOEDA" , 1  , NIL } )

	aCab := WsAutoOpc( @aCab )
	
	RestArea( aAreaSA4 )
	RestArea( aArea )

Return( lReturn )


/*/
зддддддддддбдддддддддддддддддддддддбдддддбддддддддддддддддддддбдддддбдддддддддд©
ЁFunction  ЁPutPvItem      
цддддддддддедддддддддддддддддддддддадддддаддддддддддддддддддддадддддадддддддддд╢
ЁDescri┤┘o ЁGrava e/ou Altera os Itens do Pedido de Venda                      Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁSintaxe   Ё<vide parametros formais>              Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁParametrosЁ<vide parametros formais>                 Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁUso       ЁWebService Pedido                            Ё
юддддддддддаддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды/*/
Static Function PutPvItem( oObjSC5 , oObjSC6 , aItens )

	Local aArea 	:= GetArea()
	Local aAreaDA0	:= DA0->(GetArea())
	Local aItem 	:= {}
	Local cItemSeq  := Replicate( "0" , GetSx3Cache( "C6_ITEM" , "X3_TAMANHO" ) )
	Local lReturn 	:= .T.
	Local nItem		:= 0
	Local nItens 	:= 0
	Local cTabPrc	:=	AllTrim(oObjSC5:TabelaPreco)
	Local nComis1	:=	0
    
    //--> Pego o percentual de comissao informado na tabela de precos
    //--> Campo customizado pelo cliente
	If !Empty(cTabPrc)
		dbSelectArea("DA0")
		dbSetOrder(1)
		If DA0->(dbSeek(xFilial("DA0")+cTabPrc))
			If DA0->(FieldPos("DA0_COMIS1")) > 0
				nComis1 := DA0->DA0_COMIS1
			Endif
		EndIf
	EndIf

	nItens := Len( oObjSC6 )


	For nItem := 1 To nItens
		If !Empty(oObjSC6[nItem]:ProdutoPedido)
			cItemSeq := Soma1( cItemSeq )
			aAdd( aItem , { "C6_ITEM"  		, cItemSeq      					, NIL } )
			aAdd( aItem , { "C6_PRODUTO" 	, oObjSC6[nItem]:ProdutoPedido 		, NIL } )
			aAdd( aItem , { "C6_PRCVEN"  	, oObjSC6[nItem]:PrecoVendaProduto	, NIL } )
			aAdd( aItem , { "C6_QTDVEN"  	, oObjSC6[nItem]:QuantidadeProduto 	, NIL } )
			aAdd( aItem , { "C6_OPER"  		, "01" /*oObjSC5:Operacao*/			, NIL } ) 
			aAdd( aItem , { "C6_ENTREG"		, dDataBase				   			, NIL } )  // Verificar com o cliente depois			
			aAdd( aItem , { "C6_COMIS1"		, nComis1				   			, NIL } )
//			aAdd( aItem , { "C6_XITEMDW" 	, oObjSC6[nItem]:NumeroProduto 		, NIL } )
			aItem := WsAutoOpc( aItem , .T. )
			aAdd( aItens , aItem )
			aItem := {}
		EndIf
	Next nItem

	RestArea( aAreaDA0 )
	RestArea( aArea )

Return ( lReturn )


/*/
зддддддддддбдддддддддддддддддддддддбдддддбддддддддддддддддддддбдддддбдддддддддд©
ЁWSMETHOD  ЁDelPedidoPeca  
цддддддддддедддддддддддддддддддддддадддддаддддддддддддддддддддадддддадддддддддд╢
ЁDescri┤┘o ЁExcluir Pedido de Peca                 Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁSintaxe   Ё<vide parametros formais>              Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁParametrosЁ<vide parametros formais>                 Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁUso       ЁWebService Pedido                            Ё
юддддддддддаддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды/*/
/*
WSMETHOD DelPedidoPeca WSRECEIVE CNPJ, NumeroDoPedido WSSEND WsStrDel WSSERVICE U_WANW001

	Local aCab		:= {}
	Local aItens	:= {}
	Local aErros	:= {}
	Local cStrErro	:= ""
	Local cSA1Filial:= ""
	Local lReturn	:= .T.
	Local nErro		:= 0
	Local nErros	:= 0
	Local cCNPJ		:= ""
    
	//RpcSetType(3)
	//IF FindFunction("WfPrepEnv")
		//WfPrepEnv("01","01")
	//Else
		//PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01"
	//EndIF
	
	PRIVATE lMsErroAuto    := .F.
	PRIVATE lAutoErrNoFile := .T.

	BEGIN SEQUENCE
		IF Empty(::CNPJ)
			lReturn := .F.
			SetSoapFault( "DelPedidoPeca" , "Cliente invаlido" )
			BREAK
		EndIF
		cCNPJ	:= ::CNPJ
		::CNPJ     := UnMaskCNPJ( ::CNPJ )
		cSA1Filial   := xFilial( "SA1" )
		SA1->( dbSetOrder( RetOrder( "SA1" , "A1_FILIAL+A1_CGC" ) ) )
		IF SA1->( !dbSeek( cSA1Filial + ::CNPJ , .F. ) )
			lReturn := .F.
			SetSoapFault( "DelPedidoPeca" , "CNPJ InvАlido" + " " + cSA1Filial + " " + ::CNPJ  )
			BREAK
		EndIF
		aAdd( aCab , { "C5_NUM" , ::NumeroDoPedido , NIL } )
		lMsErroAuto := .F.
		MSExecAuto({|x,y,z| MATA410(x,y,z)},aCab,aItens,5) //-> 3=Inclusao; 4=Alteracao; 5=Exclusao

		If lMsErroAuto
			aAutoErro := GETAUTOGRLOG()
			_cObs := alltrim(xDatAt()+"[U_WSFDV001] [ERRO]"+XCONVERRLOG(aAutoErro))
			SetSoapFault( "AddPedidoPeca" , _cObs )
			conout(_cObs)
			
			lReturn := .F.
			BREAK
		EndIF
 
		SC5->( dbSetOrder( RetOrder( "SC5" , "C5_FILIAL+C5_NUM" ) ) )
		IF SC5->( dbSeek( xFilial( "SC5" ) + ::NumeroDoPedido , .F. ) )
			lReturn := .F.
			BREAK
		EndIF
 
		::WsStrDel := "O pedido de nЗmero: " + ::NumeroDoPedido

		::WsStrDel += " "
		::WsStrDel += "Da Empresa CNPJ : " + cCNPJ

		::WsStrDel += " "
		::WsStrDel += "Foi excluido com sucesso"


	END SEQUENCE

	//RESET ENVIRONMENT

Return( lReturn )
  */
/*/
зддддддддддбдддддддддддддддддддддддбдддддбддддддддддддддддддддбдддддбдддддддддд©
ЁFuncao    ЁUnMaskCNPJ     
цддддддддддедддддддддддддддддддддддадддддаддддддддддддддддддддадддддадддддддддд╢
ЁDescri┤┘o ЁLimpar o Conteudo do CNPJ             Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁSintaxe   Ё<vide parametros formais>              Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁParametrosЁ<vide parametros formais>                 Ё
цддддддддддеддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд╢
ЁUso       ЁWebService Pedido                            Ё
юддддддддддаддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды/*/

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

/*
+-------------------------------------------------------------------------------+
!Funcao/Metodo     	! xConverLog												!
+-------------------+-----------------------------------------------------------+
!Descricao			! Converte Log retirando informaаies desnecess╥rias e deixa	!
!					! apresentavel ao usu╥rio									!
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