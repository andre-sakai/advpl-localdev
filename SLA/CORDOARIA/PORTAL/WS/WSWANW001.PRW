#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWEBSRV.CH"

/* ===============================================================================
WSDL Location    http://192.168.1.3:9093/U_WANW001.apw?WSDL
Gerado em        09/27/18 19:51:04
Observações      Código-Fonte gerado por ADVPL WSDL Client 1.120703
                 Alterações neste arquivo podem causar funcionamento incorreto
                 e serão perdidas caso o código-fonte seja gerado novamente.
=============================================================================== */

User Function _VFSLCJP ; Return  // "dummy" function - Internal Use 

/* -------------------------------------------------------------------------------
WSDL Service WSU_WANW001
------------------------------------------------------------------------------- */

WSCLIENT WSU_WANW001

	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD RESET
	WSMETHOD CLONE
	WSMETHOD ADDPEDIDOPECA

	WSDATA   _URL                      AS String
	WSDATA   _HEADOUT                  AS Array of String
	WSDATA   _COOKIES                  AS Array of String
	WSDATA   cCNPJ                     AS string
	WSDATA   oWSTADDPEDIDO             AS U_WANW001_TADDPEDIDOCAB
	WSDATA   cADDPEDIDOPECARESULT      AS string

	// Estruturas mantidas por compatibilidade - NÃO USAR
	WSDATA   oWSTADDPEDIDOCAB          AS U_WANW001_TADDPEDIDOCAB

ENDWSCLIENT

WSMETHOD NEW WSCLIENT WSU_WANW001
::Init()
If !FindFunction("XMLCHILDEX")
	UserException("O Código-Fonte Client atual requer os executáveis do Protheus Build [7.00.131227A-20171107 NG] ou superior. Atualize o Protheus ou gere o Código-Fonte novamente utilizando o Build atual.")
EndIf
Return Self

WSMETHOD INIT WSCLIENT WSU_WANW001
	::oWSTADDPEDIDO      := U_WANW001_TADDPEDIDOCAB():New()

	// Estruturas mantidas por compatibilidade - NÃO USAR
	::oWSTADDPEDIDOCAB   := ::oWSTADDPEDIDO
Return

WSMETHOD RESET WSCLIENT WSU_WANW001
	::cCNPJ              := NIL 
	::oWSTADDPEDIDO      := NIL 
	::cADDPEDIDOPECARESULT := NIL 

	// Estruturas mantidas por compatibilidade - NÃO USAR
	::oWSTADDPEDIDOCAB   := NIL
	::Init()
Return

WSMETHOD CLONE WSCLIENT WSU_WANW001
Local oClone := WSU_WANW001():New()
	oClone:_URL          := ::_URL 
	oClone:cCNPJ         := ::cCNPJ
	oClone:oWSTADDPEDIDO :=  IIF(::oWSTADDPEDIDO = NIL , NIL ,::oWSTADDPEDIDO:Clone() )
	oClone:cADDPEDIDOPECARESULT := ::cADDPEDIDOPECARESULT

	// Estruturas mantidas por compatibilidade - NÃO USAR
	oClone:oWSTADDPEDIDOCAB := oClone:oWSTADDPEDIDO
Return oClone

// WSDL Method ADDPEDIDOPECA of Service WSU_WANW001

WSMETHOD ADDPEDIDOPECA WSSEND cCNPJ,oWSTADDPEDIDO WSRECEIVE cADDPEDIDOPECARESULT WSCLIENT WSU_WANW001
Local cSoap := "" , oXmlRet

BEGIN WSMETHOD

cSoap += '<ADDPEDIDOPECA xmlns="http://192.168.1.3:9093/">'
cSoap += WSSoapValue("CNPJ", ::cCNPJ, cCNPJ , "string", .T. , .F., 0 , NIL, .F.,.F.) 
cSoap += WSSoapValue("TADDPEDIDO", ::oWSTADDPEDIDO, oWSTADDPEDIDO , "TADDPEDIDOCAB", .T. , .F., 0 , NIL, .F.,.F.) 
cSoap += "</ADDPEDIDOPECA>"

oXmlRet := SvcSoapCall(	Self,cSoap,; 
	"http://192.168.1.3:9093/ADDPEDIDOPECA",; 
	"DOCUMENT","http://192.168.1.3:9093/",,"1.031217",; 
	"http://192.168.1.3:9093/U_WANW001.apw")

::Init()
::cADDPEDIDOPECARESULT :=  WSAdvValue( oXmlRet,"_ADDPEDIDOPECARESPONSE:_ADDPEDIDOPECARESULT:TEXT","string",NIL,NIL,NIL,NIL,NIL,NIL) 

END WSMETHOD

oXmlRet := NIL
Return .T.


// WSDL Data Structure TADDPEDIDOCAB

WSSTRUCT U_WANW001_TADDPEDIDOCAB
	WSDATA   cCODIGOVENDEDOR           AS string
	WSDATA   cCONDICAOPAGAMENTO        AS string
	WSDATA   dDATAENTREGA              AS date
	WSDATA   cFILIALCODIGO             AS string
	WSDATA   cMENSAGEMNOTAFISCAL       AS string OPTIONAL
	WSDATA   cOBSERVACAO               AS string OPTIONAL
	WSDATA   cOPERACAO                 AS string
	WSDATA   cPEDIDOCLIENTE            AS string
	WSDATA   cPEDIDODW                 AS string
	WSDATA   cREDESPACHO               AS string
	WSDATA   cTABELAPRECO              AS string
	WSDATA   cTIPOFRETE                AS string
	WSDATA   cTRANSPORTADORA           AS string
	WSDATA   oWSTZITENSDOPEDIDO        AS U_WANW001_ARRAYOFTADDPEDIDODET
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPSEND
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT U_WANW001_TADDPEDIDOCAB
	::Init()
Return Self

WSMETHOD INIT WSCLIENT U_WANW001_TADDPEDIDOCAB
Return

WSMETHOD CLONE WSCLIENT U_WANW001_TADDPEDIDOCAB
	Local oClone := U_WANW001_TADDPEDIDOCAB():NEW()
	oClone:cCODIGOVENDEDOR      := ::cCODIGOVENDEDOR
	oClone:cCONDICAOPAGAMENTO   := ::cCONDICAOPAGAMENTO
	oClone:dDATAENTREGA         := ::dDATAENTREGA
	oClone:cFILIALCODIGO        := ::cFILIALCODIGO
	oClone:cMENSAGEMNOTAFISCAL  := ::cMENSAGEMNOTAFISCAL
	oClone:cOBSERVACAO          := ::cOBSERVACAO
	oClone:cOPERACAO            := ::cOPERACAO
	oClone:cPEDIDOCLIENTE       := ::cPEDIDOCLIENTE
	oClone:cPEDIDODW            := ::cPEDIDODW
	oClone:cREDESPACHO          := ::cREDESPACHO
	oClone:cTABELAPRECO         := ::cTABELAPRECO
	oClone:cTIPOFRETE           := ::cTIPOFRETE
	oClone:cTRANSPORTADORA      := ::cTRANSPORTADORA
	oClone:oWSTZITENSDOPEDIDO   := IIF(::oWSTZITENSDOPEDIDO = NIL , NIL , ::oWSTZITENSDOPEDIDO:Clone() )
Return oClone

WSMETHOD SOAPSEND WSCLIENT U_WANW001_TADDPEDIDOCAB
	Local cSoap := ""
	cSoap += WSSoapValue("CODIGOVENDEDOR", ::cCODIGOVENDEDOR, ::cCODIGOVENDEDOR , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("CONDICAOPAGAMENTO", ::cCONDICAOPAGAMENTO, ::cCONDICAOPAGAMENTO , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("DATAENTREGA", ::dDATAENTREGA, ::dDATAENTREGA , "date", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("FILIALCODIGO", ::cFILIALCODIGO, ::cFILIALCODIGO , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("MENSAGEMNOTAFISCAL", ::cMENSAGEMNOTAFISCAL, ::cMENSAGEMNOTAFISCAL , "string", .F. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("OBSERVACAO", ::cOBSERVACAO, ::cOBSERVACAO , "string", .F. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("OPERACAO", ::cOPERACAO, ::cOPERACAO , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("PEDIDOCLIENTE", ::cPEDIDOCLIENTE, ::cPEDIDOCLIENTE , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("PEDIDODW", ::cPEDIDODW, ::cPEDIDODW , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("REDESPACHO", ::cREDESPACHO, ::cREDESPACHO , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("TABELAPRECO", ::cTABELAPRECO, ::cTABELAPRECO , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("TIPOFRETE", ::cTIPOFRETE, ::cTIPOFRETE , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("TRANSPORTADORA", ::cTRANSPORTADORA, ::cTRANSPORTADORA , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("TZITENSDOPEDIDO", ::oWSTZITENSDOPEDIDO, ::oWSTZITENSDOPEDIDO , "ARRAYOFTADDPEDIDODET", .T. , .F., 0 , NIL, .F.,.F.) 
Return cSoap

// WSDL Data Structure ARRAYOFTADDPEDIDODET

WSSTRUCT U_WANW001_ARRAYOFTADDPEDIDODET
	WSDATA   oWSTADDPEDIDODET          AS U_WANW001_TADDPEDIDODET OPTIONAL
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPSEND
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT U_WANW001_ARRAYOFTADDPEDIDODET
	::Init()
Return Self

WSMETHOD INIT WSCLIENT U_WANW001_ARRAYOFTADDPEDIDODET
	::oWSTADDPEDIDODET     := {} // Array Of  U_WANW001_TADDPEDIDODET():New()
Return

WSMETHOD CLONE WSCLIENT U_WANW001_ARRAYOFTADDPEDIDODET
	Local oClone := U_WANW001_ARRAYOFTADDPEDIDODET():NEW()
	oClone:oWSTADDPEDIDODET := NIL
	If ::oWSTADDPEDIDODET <> NIL 
		oClone:oWSTADDPEDIDODET := {}
		aEval( ::oWSTADDPEDIDODET , { |x| aadd( oClone:oWSTADDPEDIDODET , x:Clone() ) } )
	Endif 
Return oClone

WSMETHOD SOAPSEND WSCLIENT U_WANW001_ARRAYOFTADDPEDIDODET
	Local cSoap := ""
	aEval( ::oWSTADDPEDIDODET , {|x| cSoap := cSoap  +  WSSoapValue("TADDPEDIDODET", x , x , "TADDPEDIDODET", .F. , .F., 0 , NIL, .F.,.F.)  } ) 
Return cSoap

// WSDL Data Structure TADDPEDIDODET

WSSTRUCT U_WANW001_TADDPEDIDODET
	WSDATA   nNumero	        		AS float
	WSDATA   nPRECOVENDAPRODUTO        AS float
	WSDATA   cPRODUTOPEDIDO            AS string
	WSDATA   nQUANTIDADEPRODUTO        AS float
	WSDATA   nCOMISSAOPRODUTO        AS float
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPSEND
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT U_WANW001_TADDPEDIDODET
	::Init()
Return Self

WSMETHOD INIT WSCLIENT U_WANW001_TADDPEDIDODET
Return

WSMETHOD CLONE WSCLIENT U_WANW001_TADDPEDIDODET
	Local oClone := U_WANW001_TADDPEDIDODET():NEW()
	oClone:nNUMERO   			:= ::nNUMERO
	oClone:nPRECOVENDAPRODUTO   := ::nPRECOVENDAPRODUTO
	oClone:cPRODUTOPEDIDO       := ::cPRODUTOPEDIDO
	oClone:nQUANTIDADEPRODUTO   := ::nQUANTIDADEPRODUTO
	oClone:nCOMISSAOPRODUTO   := ::nCOMISSAOPRODUTO
		
Return oClone

WSMETHOD SOAPSEND WSCLIENT U_WANW001_TADDPEDIDODET
	Local cSoap := ""
	cSoap += WSSoapValue("NUMERO", ::nNUMERO, ::nNUMERO , "float", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("PRECOVENDAPRODUTO", ::nPRECOVENDAPRODUTO, ::nPRECOVENDAPRODUTO , "float", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("PRODUTOPEDIDO", ::cPRODUTOPEDIDO, ::cPRODUTOPEDIDO , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("QUANTIDADEPRODUTO", ::nQUANTIDADEPRODUTO, ::nQUANTIDADEPRODUTO , "float", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += WSSoapValue("COMISSAOPRODUTO", ::nCOMISSAOPRODUTO, ::nCOMISSAOPRODUTO , "float", .T. , .F., 0 , NIL, .F.,.F.) 

Return cSoap


