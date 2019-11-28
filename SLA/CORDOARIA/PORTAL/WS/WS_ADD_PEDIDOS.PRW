#INCLUDE "APWEBSRV.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"  
#INCLUDE "topconn.ch"  

/*/
ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿
³WSSTRUCT  ³tAddPedidoDet        
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´
³Descri‡…o ³Estrutura dos Detalhes de Inclusao de Pedidos                      ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Sintaxe   ³<vide parametros formais>              ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Parametros³<vide parametros formais>                 ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Uso       ³WebService Pedido                            ³
ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ/*/


WSSTRUCT tAddPedidoDet
	WSDATA Numero				AS Float	//C6_PRODUTO
	WSDATA ProdutoPedido		AS String	//C6_PRODUTO
	WSDATA PrecoVendaProduto	AS Float	//C6_PRCVEN
	WSDATA QuantidadeProduto	AS Float	//C6_QTDVEN
	WSDATA ComissaoProduto		AS Float	//C6_COMIS1 
ENDWSSTRUCT

/*/
ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿
³WSSTRUCT  ³tAddPedidoCab        
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´
³Descri‡…o ³Estrutura do Cabecalho de Inclusao de Pedidos                      ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Sintaxe   ³<vide parametros formais>              ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Parametros³<vide parametros formais>                 ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Uso       ³WebService Pedido                            ³
ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ/*/

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
ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿
³WSSERVICE ³TEXW006    
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´
³Descri‡…o ³Serviço de consulta e atualização dos pedidos de venda Pedido    ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Sintaxe   ³<vide parametros formais>              ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Parametros³<vide parametros formais>                 ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Uso       ³WebService Pedido                            ³
ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ/*/


WSSERVICE U_WANW001 DESCRIPTION "Serviço de atualização dos pedidos de venda" 

	//-->RECEBE		 
	WSDATA CNPJ				AS String
	WSDATA tAddPedido		AS tAddPedidoCab
	//-->RETORNO		  
	WSDATA NumeroDoPedido	AS String
	WSDATA WsStrDel			AS String

	//-->METODOS
	WSMETHOD AddPedidoPeca      DESCRIPTION "Modo de Inclusão do Pedido de Venda"
	
ENDWSSERVICE

/*/
ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿
³WSMETHOD  ³AddPedidoPeca    
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´
³Descri‡…o ³Adicionar Pedido de Peca             ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Sintaxe   ³<vide parametros formais>              ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Parametros³<vide parametros formais>                 ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Uso       ³WebService Pedido                            ³
ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ/*/

WSMETHOD AddPedidoPeca WSRECEIVE CNPJ, tAddPedido WSSEND NumeroDoPedido WSSERVICE U_WANW001

Local aArea			:= {}
Local aCab			:= {}

Local aItens		:= {}
Local aErros    	:= {}
Local cStrErro		:= ""
Local cSC5Filial	:= ""
Local cSA1Filial	:= ""
Local cLojaCliente	:= ""
Local cCodigoCliente:= "" 
Local cCondPag		:= ""
Local cDesconto 	:= ""
Local cTrasport		:= ""
Local cVendedor		:= ""
Local cTipCli 		:= ""
Local lReturn  		:= .T.
Local lValidaCad	:= .T.
Local lValidaPed	:= .T.
Local lRetCab		:= .T.
Local lRetIte		:= .T.
Local nErro    		:= 0
Local nErros   		:= 0 
Local cPedRepet		:= ""        
local cPportal 		:= ""
local nPportal 		:= 0
Local lGeraPed		:= .T.
Local nQtdItem		:= 0
Local aRetIte		:= {}

Private cNumpedDW 		:= ::tAddPedido:PedidoDW
Private cCnpj			:= UnMaskCNPJ( ::CNPJ )

PRIVATE lMsErroAuto     	:= .F.
PRIVATE lAutoErrNoFile		:= .T.
PRIVATE _nSeq				:= 0
PRIVATE _cNumPed	:= ""
					  
aArea	:= GetArea()

lValidaPed := .T.

BEGIN SEQUENCE
	// VALIDACOES GERAIS
	
	IF Empty(::CNPJ)
		conout("Pedido DW " + cNumpedDW + " - Cliente do CNPJ " + ::CNPJ  + " invalido.")
		lValidaCad := .F.
		SetSoapFault( "AddPedidoPeca" , "Pedido DW " + cNumpedDW + " - Cliente do CNPJ " + ::CNPJ  + " invalido" )
		RestArea(aArea)
		Return(lValidaCad)
	EndIF 

	IF Empty(tAddPedido:tabelaPreco)
		conout("Pedido DW " + cNumpedDW + " esta sem TABELA DE PRECO.")
		lValidaCad := .F.
		SetSoapFault( "AddPedidoPeca" , "Pedido DW " + cNumpedDW + " esta sem TABELA DE PRECO." )
		RestArea(aArea)
		Return(lValidaCad)
	EndIF 

	if lValidaCad
		cSA1Filial   := xFilial( "SA1" )
		SA1->(dbSetOrder(03)) // A1_FILIAL+A1_CGC                                                                                                                                                
		IF SA1->(!dbSeek(cSA1Filial + cCnpj))
			conout("Pedido DW " + cNumpedDW + " - Cliente do CNPJ " + cCnpj  + " invalido ou nao encontrado.")
			lValidaCad := .F.
			SetSoapFault( "AddPedidoPeca" , "Pedido DW " + cNumpedDW + " - Cliente do CNPJ " + cCnpj  + " invalido ou nao encontrado."  ) //"CNPJ invalido"
			RestArea(aArea)
			Return(lValidaCad)
			
		else
			cLojaCliente  	:= SA1->A1_LOJA
			cCodigoCliente  := SA1->A1_COD
			
			if SA1->A1_MSBLQL == "1"
				conout("Pedido DW " + cNumpedDW + " - Cliente do CNPJ " + cCnpj  + " esta com cadastro CANCELADO.")
				lValidaCad := .F.
				lReturn := .F.
				SetSoapFault( "AddPedidoPeca" , "Pedido DW " + cNumpedDW + " - Cliente do CNPJ " + cCnpj  + " esta com cadastro CANCELADO.") //"CNPJ invalido"
			endif			
			
			if !lReturn
				return(lReturn)
			endif
		endif
	endIf					

	if (lValidaPed) .and. (lValidaCad)
		aRetIte := WSGRPED(::tAddPedido , @aCab , @cCodigoCliente , @cLojaCliente, @::tAddPedido, @::tAddPedido:tzItensDoPedido , @aItens)
		
		if aRetIte[01]
			::NumeroDoPedido := alltrim(_cNumPed)

			conout("--------------------------------------------------------------------------------------------------------")
			conout("Pedido DW " + cNumpedDW  + " - Pedido(s) Protheus: " + alltrim(_cNumPed) + " incluido(s) com sucesso - Data: " + dtoc(date()) + " - Hora: " + time())
			conout("--------------------------------------------------------------------------------------------------------")

		else
			conout(aRetIte[02])
			SetSoapFault( "AddPedidoPeca" ,aRetIte[02])
			RestArea(aArea)
			lReturn := .F.
		
		endif
	else
		conout("Pedido DW " + cNumpedDW + " - Problema nos itens do pedido do cliente " + cCodigoCliente  + ".")
		SetSoapFault( "AddPedidoPeca" , "Pedido DW " + cNumpedDW + " - Problema nos itens do pedido do cliente " + cCodigoCliente  + ". Existe quantidade fracionada em um dos itens" )
		RestArea(aArea)
		lReturn := .F.
	endif
	
END SEQUENCE


RestArea(aArea)

//RESET ENVIRONMENT

Return( lReturn )

/*/
ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿
³Funcao    ³UnMaskCNPJ     
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´
³Descri‡…o ³Limpar o Conteudo do CNPJ             ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Sintaxe   ³<vide parametros formais>              ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Parametros³<vide parametros formais>                 ³
ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
³Uso       ³WebService Pedido                            ³
ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ/*/

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
!Descricao			! Converte Log retirando informa?es desnecess?ias e deixa	!
!					! apresentavel ao usu?io									!
+-------------------+-----------------------------------------------------------+
!Autor             	! 															!
+-------------------+-----------------------------------------------------------+
!Data de Criacao   	!                                                        	!
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

//---------------------------------------------------------------------------------------------------------------------------------------
// Função que gera o pedido de vendas

static function WSGRPED(oObj , aCab , cCodigoCliente , cLojaCliente,oObjSC5 , oObjSC6 , aItens)

Local aArea 		:= GetArea()
Local lRetPv		:= .T.
Local cQuery 		:= "" 
Local dDtPrev		:= date()
Local aItem     	:= {}
Local cItemSeq	:= Replicate( "0" , GetSx3Cache( "C6_ITEM" , "X3_TAMANHO" ) )
Local nItem     := 0
Local nItens  	:= 0
Local nLimite	:= 999 // supergetmv("MV_NUMITEN",.F.,150)
Local _aDevol	:= {}
local nItemPed	:= 0
Local _nPrcVen	:= 0
Local _nPrcSc6	:= 0
Local _cTabPrc	:= oObj:TabelaPreco
Local _nDesc01	:= 0
Local _nDesc02	:= 0
Local _nDesc03	:= 0
Local _nDesc04	:= 0
Local _nDesc05	:= 0
Local lZero		:= .T.
Local cTabPrc	:=	AllTrim(oObjSC5:TabelaPreco)
Local aAreaDA0	:= DA0->(GetArea())

Private cPedido 	:= ""
Private lRetItem  	:= .T.
Private _cDevol		:= ""
Private cOperC5 	:= alltrim(oObjSC5:Operacao)
Private cOper		:= alltrim(oObjSC5:Operacao)

Private aCab 		:= {}
Private aItem		:= {}
Private aItens		:= {}

/*
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
*/

nItens := Len( oObjSC6 )

For nItem := 1 To nItens
	// gero os itens do pedido de vendas
	If !Empty(oObjSC6[nItem]:ProdutoPedido)
		
		cItemSeq := Soma1( cItemSeq )
		_nValPed := oObjSC6[nItem]:QuantidadeProduto * oObjSC6[nItem]:PrecoVendaProduto
		nComis1 := oObjSC6[nItem]:ComissaoProduto

		aAdd( aItem , { "C6_FILIAL"		, xFilial("SC6")	, NIL } )
		aAdd( aItem , { "C6_ITEM"  		, cItemSeq      	, NIL } )
		aAdd( aItem , { "C6_PRODUTO" 	, oObjSC6[nItem]:ProdutoPedido  , NIL } )
		aAdd( aItem , { "C6_QTDVEN"  	, oObjSC6[nItem]:QuantidadeProduto	, NIL } )
		aAdd( aItem , { "C6_PRCVEN" 	, oObjSC6[nItem]:PrecoVendaProduto	, NIL } )
		aAdd( aItem , { "C6_TOTAL"  	, _nValPed	, NIL } )
		aAdd( aItem , { "C6_OPER"  		, "01"    			, NIL } )
		aAdd( aItem , { "C6_ENTREG"		, dDataBase				   			, NIL } )  // Verificar com o cliente depois			
		aAdd( aItem , { "C6_COMIS1"		, nComis1				   			, NIL } )
		aAdd( aItem , { "C6_XITEMDW" 	, oObjSC6[nItem]:Numero	 			, NIL } )
		aItem := WsAutoOpc( aItem , .T. )

		aAdd( aItens , aItem )
		aItem := {}
		nItemPed := nItemPed + 1
	EndIf
	
	// se o número do item lido + 1 for maior que o parametrizado, gero o cabe?lho do pedido de vendas
	if nItemPed + 1 > nLimite
		_nSeq := _nSeq + 1  
		PutPvHead(oObj,cCodigoCliente , cLojaCliente,aItens)	
		cItemSeq	:= Replicate( "0" , GetSx3Cache( "C6_ITEM" , "X3_TAMANHO" ) )
		nItemPed := 0
		aCab 	:= {}
		aItens 	:= {}
	endif
	
Next nItem

//pego o que sobrou para não ficar nada de fora
if len(aItens) > 0 
	_nSeq := _nSeq + 1
	PutPvHead(oObj,cCodigoCliente , cLojaCliente,aItens)	
endif
	

// Envio o número do pedido para o DW
cQuery := " Select count(C5_NUM) QUANT, C5_NUM, C5_XPEDDW "
cQuery += " from " + retSqlName("SC5") + " SC5 "
cQuery += " where SC5.D_E_L_E_T_ <> '*' "
cQuery += " and C5_XPEDDW = '" + cNumpedDW + " ' " 
cQuery += " and C5_FILIAL = '" + xFilial("SC5") + "' "
cQuery += " group by C5_XPEDDW,C5_NUM " 
	  	                     
TCQuery cQuery NEW ALIAS "WSPED1"           

if WSPED1->QUANT > 0
	while WSPED1->(!EOF())
		_cNumPed := alltrim(WSPED1->C5_NUM)
		 WSPED1->(dbSkip())
	enddo
endif

WSPED1->(dbCloseArea())

RestArea( aAreaDA0 )
restarea(aArea)

aadd(_aDevol, lRetItem)
aadd(_aDevol, _cDevol)
	
Return ( _aDevol )

//---------------------------------------------------------------------------------------------------------------------------------------------
// geração do cabeçalho do pedido de vendas

Static Function PutPvHead(oObj,cCodigoCliente , cLojaCliente, aItens)

Local aAreaSA4 	:= SA4->(GetArea())

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

// zero o aCab
aCab 	:= {}

dbselectarea("SC5")
SC5->(dbSetOrder(1))
While (.T.)
	cPedido := GETSXENUM("SC5","C5_NUM")
	conout(cPedido)	
	If !SC5->(dbSeek(xFilial("SC5") + cPedido))
		SC5->(rollbackSx8())
		Exit
	Endif
	SC5->(ConfirmSX8())
Enddo

aAdd( aCab , { "C5_FILIAL"	, xFilial("C5_FILIAL")	      		, NIL } )
aAdd( aCab , { "C5_NUM"		, cPedido	      					, NIL } )
aAdd( aCab , { "C5_EMISSAO"	, dDataBase      					, NIL } )
aAdd( aCab , { "C5_TIPO"	, "N"								, NIL } ) 
aAdd( aCab , { "C5_TPFRETE"	, Upper(oObj:TipoFrete)				, NIL } )
aAdd( aCab , { "C5_CLIENTE"	, cCodigoCliente					, NIL } )
aAdd( aCab , { "C5_LOJACLI"	, cLojaCliente						, NIL } )
aAdd( aCab , { "C5_CLIENT"	, cCodigoCliente					, NIL } )
aAdd( aCab , { "C5_LOJAENT"	, cLojaCliente						, NIL } )
aAdd( aCab , { "C5_VEND1"	, AllTrim(oObj:CodigoVendedor)	   	, NIL } )
aAdd( aCab , { "C5_TRANSP"	, AllTrim(oObj:Transportadora)		, NIL } )
aAdd( aCab , { "C5_CONDPAG"	, AllTrim(oObj:CondicaoPagamento)	, NIL } ) 
aAdd( aCab , { "C5_TABELA"	, AllTrim(oObj:TabelaPreco)			, NIL } )
aAdd( aCab , { "C5_REDESP"	, AllTrim(oObj:Redespacho)	 		, NIL } )
aAdd( aCab , { "C5_PEDCLI"	, AllTrim(oObj:PedidoCliente)		, NIL } )
aAdd( aCab , { "C5_MENNOTA"	, cMsgNF				  			, NIL } )
If SC5->(FieldPos("C5_OBS")) > 0
	aAdd( aCab , { "C5_OBS"		, FwNoAccent(oObj:Observacao)	, NIL } ) // Campo customizado do cliente
EndIf
If SC5->(FieldPos("C5_XPEDDW")) > 0
	aAdd( aCab , { "C5_XPEDDW"	, AllTrim(oObj:PedidoDW)		, NIL } )
EndIf	


aCab := WsAutoOpc( @aCab )

// geração do pedido de vendas
if len(aCab) > 0 .and. len(aItens) > 0
	conout ("Inicio - Montando pedido " + cPedido)
	begintran()
	
	MsExecAuto({|x,y,z|MATA410(x,y,z)},aCab,aItens,3)
	conout ("Final - Montando pedido " + cPedido)
	
	If lMsErroAuto
		aAutoErro := GETAUTOGRLOG()
		_cDevol := alltrim(xDatAt()+"[ERRO]"+XCONVERRLOG(aAutoErro))
		conout(_cDevol)
		u_ADDXEML(_cDevol,AllTrim(oObj:PedidoDW))
		lRetItem := .F.
	else

		// Zero as variáveis temporárias
		cItemSeq	:= Replicate( "0" , GetSx3Cache( "C6_ITEM" , "X3_TAMANHO" ) )
		nItemPed := 0
		aCab 	:= {}
		aItens 	:= {}
	EndIF
	endtran()
else
	if len(aCab) == 0
		conout("Pedido DW " + cNumpedDW + " - Problema no cabeçalho do pedido do cliente " + cCodigoCliente  + ".")
		_cDevol := "Pedido DW " + cNumpedDW + " - Problema no cabeçalho do pedido do cliente " + cCodigoCliente  + "."
		lRetItem := .F. 
	elseif len(aItens) == 0
		conout("Pedido DW " + cNumpedDW + " - Problema nos itens do pedido do cliente " + cCodigoCliente  + ".")
		_cDevol :=  "Pedido DW " + cNumpedDW + " - Problema nos itens do pedido do cliente " + cCodigoCliente  + "."
		lRetItem := .F.
	endif
endif 	

RestArea( aAreaSA4 )
																																 
return()																																 

//=========================================================================================================================
// Envio de email de alteração cadastral

User Function ADDXEML(_xMsgErr,_xPedido)

Local _cBody     	:= "" 
Local cItens	 	:= ""
Local _cSerMail		:= ALLTRIM(GetMV("MV_RELSERV"))
Local _cConta  		:= ALLTRIM(GetMV("MV_RELACNT"))
Local _cSenha		:= ALLTRIM(GetMV("MV_RELPSW"))
Local _cCtaAuth		:= alltrim(GetMV("MV_RELAUSR"))
Local _cPassAut		:= alltrim(GetMV("MV_RELAPSW"))
Local _nTimeOut  	:= GetMv("MV_RELTIME")
Local _cFrom		:= alltrim(GetMV("MV_RELFROM"))
Local _cDest    	:= "tadeu@sla.inf.br"

Local _cTit			:= "Inconsistência Importação de Pedidos do pedido "
LOcal _cUserDw		:= "Webservice Protheus X DW"
Local _lEnviado		:= .F.
Local _lConectou 	:= .F.
Local _cMailError	:= ""
Local _cDestcco  	:= "" 
Local i 
Local _cCor			:= "white" 
Local cAmbiente 	:= GetEnvServer() 
	
_cBody += "<p align=left><b><font face=Verdana size=3 color=#336699>" 
_cBody += + _cTit + " " + _xPedido + "                     
_cBody += "</b></font><br><br><br>"                                                 

_cBody += "<p align=left><b><font face=Verdana size=1 color=#336699>"  
_cBody += "USU?IO: "  
_cBody += "<font face=Verdana size=1 color=#000080>"
_cBody += + UPPER(ALLTRIM(_cUserDw)) + " 

_cBody += "<p align=left><b><font face=Verdana size=1 color=#336699>"  
_cBody += "DATA E HORA: "  
_cBody += "<font face=Verdana size=1 color=#000080>"
_cBody += + DTOC(date()) + " - " + TIME() 

_cBody += "<p align=left><b><font face=Verdana size=1,5 color=#000080>" 
_cBody += "<br><br>ERRO CONSOLIDA?O DE PEDIDO DW X PROTHEUS"  
_cBody += "</b></font><br><br>"	
	
_cBody += _xMsgErr

CONNECT SMTP SERVER _cSerMail ACCOUNT _cConta PASSWORD _cSenha TIMEOUT _nTimeOut Result _lConectou 
MailAuth(_cCtaAuth,_cPassAut) 

if !(_lConectou)
	GET MAIL ERROR _cMailError
	conout(_cMailError)
else 
	_cTit := _cTit + " " + _xPedido +  " - Usu?io: " + upper(alltrim(_cUserDw)) + ". 
	SEND MAIL FROM _cFrom;
	To alltrim(_cDest) ;
	SUBJECT	ALLTRIM(_cTit) ;
	Body _cBody FORMAT TEXT RESULT _lEnviado
		
	if !(_lEnviado)
		GET MAIL ERROR _cMailError 
		alert(_cMailError)
	endif
	
	DISCONNECT SMTP SERVER

endif 

Return(.T.) 
