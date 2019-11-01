#include "Totvs.ch"

/*/{Protheus.doc} TokenAuthPortal
Classe respons�vel por gerar o token de seguran�a
de autentica��o.
@type  Class
@author Matheus Jos� da Cunha
@since 24/09/2019
/*/
Class TokenAuthPortal
    Data    token   as character 

    Method New() Constructor
    Method gerarToken()
    Method validarToken()
    Method createSession()
    Method updateSession()
    Method getToken()
EndClass

Method New() Class TokenAuthPortal
    self:token  := ""
Return

/*/{Protheus.doc} gerarToken
Gera um token em hash e salva na vari�vel
token do objeto.
@author Matheus Jos� da Cunha
@since 24/09/2019
@version version
/*/
Method gerarToken(cStr) Class TokenAuthPortal
    Local   cCodUsu as character
    Default cStr    := ""

    //Salva o c�digo do usu�rio da AI3
    cCodUsu := cStr

    //Prepara a string para gerar a Hash
    cStr += DToS(Date())
    cStr += Time()
    cStr += StrZero(ThreadId(),10)

    //Conte�do permitido na chave Hash
    self:token  := MD5(cStr)  

    //Limpa o token caso n�o consiga criar a sess�o
    If ! ::createSession(cCodUsu)
        self:token := ""
    EndIf
Return 

/*/{Protheus.doc} validarToken
Valida se h� sess�o do token criado no banco de dados
atributo token.
@author Matheus Jos� da Cunha
@since 25/09/2019
@version version
/*/
Method validarToken(cToken,cCodCli,cCodLoj) Class TokenAuthPortal
    Local   aRet        as array
    Local   aParams     as array
    Local   cQuery      as character
    Local   cAliasQry   as character
    Local   oStm        as object
    Default cToken      := ""
    Default cCodCli     := ""
    Default cCodLoj     := ""

    aRet        := {.T.,000,""}
    aParams     := {}
    cAliasQry   := getNextAlias()

    //[1] - .T. = Autenticado , .F. = N�o autenticado 
    //[2] - C�digo de retorno HTTP quando n�o autenticado 
    //[3] - Mensagem de retorno quando n�o autenticado

    aAdd(aParams,cToken)
    cQuery := " SELECT getDate() DATA_ATUAL, SESSION_EXPIRED, SESSION_LOGIN,"
	cQuery += " (CASE WHEN SESSION_EXPIRED < getDate() THEN 'EXPIROU' ELSE '' END) SESSAO"
    cQuery += " FROM PORTAL_SESSION"
    cQuery += " WHERE SESSION_ID = ?"
    oStm := FWPreparedStatement():New(cQuery)
    oStm:setParams(aParams)
    cQuery := oStm:getFixQuery()
    oStm:destroy()
    MPSysOpenQuery(cQuery,cAliasQry) 

    (cAliasQry)->(dbGoTop())

    If (cAliasQry)->( ! EoF() )
        //Valida a sess�o se est� expirada
        If (cAliasQry)->SESSAO == "EXPIROU"
            aRet[1] := .F.
            aRet[2] := 401
            aRet[3] := "Sess�o expirada."
        Else 
            //Valida a empresa de acesso com o usu�rio que est� vinculado no token
            dbSelectArea("AI4")
            AI4->(dbSetOrder(1))
            If ! AI4->(dbSeek(xFilial("AI4")+Padr(AllTrim((cAliasQry)->SESSION_LOGIN),TamSX3("AI4_CODUSU")[1])+cCodCli+cCodLoj,.T.))
                AI4->(dbCloseArea())
                aRet[1] := .F.
                aRet[2] := 400
                aRet[3] := "Acesso de empresa violado."
                Return aRet
            EndIf
            AI4->(dbCloseArea())


            //Valida��es OK, atualiza a sess�o do usu�rio
            If aRet[1] 
                ::updateSession(cToken)
                self:token := cToken
            EndIf
        EndIf
    Else 
        aRet[1] := .F.
        aRet[2] := 400
        aRet[3] := "Token de acesso inv�lido."
    EndIf

    (cAliasQry)->(dbCloseArea())
Return aRet

/*/{Protheus.doc} createSession
Cria uma sess�o com a hash que est� no 
atributo token.
@author Matheus Jos� da Cunha
@since 25/09/2019
@version version
/*/
Method createSession(cCodUsu) Class TokenAuthPortal
    Local   aParams as array
    Local   cQuery  as character
    Local   nStatus as numeric
    Local   lRet    as logical
    Local   oStm    as object
    Default cCodUsu := ""

    lRet    := .T.
    aParams := {}

    If ! Empty(self:token)
        aAdd(aParams,self:token)
        aAdd(aParams,cCodUsu)
        // gera o registro da session
        cQuery := "INSERT INTO PORTAL_SESSION ("
        cQuery += "SESSION_ID, SESSION_LOGIN, SESSION_ORIGEM, SESSION_PCNAME ) "
        cQuery += "VALUES ("
        cQuery += "?,"
        cQuery += "?,"
        cQuery += "'',"
        cQuery += "'')"
        oStm := FWPreparedStatement():New(cQuery)
        oStm:setParams(aParams)
        cQuery := oStm:getFixQuery()
        oStm:destroy()

        nStatus := TcSQLExec(cQuery)

        If nStatus < 0 
            lRet := .F.
        EndIf

    Else
        lRet := .F.
    EndIf
    
Return lRet

/*/{Protheus.doc} updateSession
Atualiza o tempo de sess�o do usu�rio
@author Matheus Jos� da Cunha
@since 25/09/2019
@param cToken, characters, token de acesso
/*/
Method updateSession(cToken) Class TokenAuthPortal
    Local   aParams as array
    Local   cQuery  as character
    Local   oStm    as object
    Default cToken  := ""

    If ! Empty(cToken)
        aParams := {}
        aAdd(aParams,cToken)
        cQuery := " UPDATE PORTAL_SESSION"
        cQuery += " SET SESSION_EXPIRED = (dateadd(minute,(10),getdate()))"
        cQuery += " WHERE SESSION_ID = ?"
        oStm := FWPreparedStatement():New(cQuery)
        oStm:setParams(aParams)
        cQuery := oStm:getFixQuery()
        TcSQLExec(cQuery)
    EndIf
    
Return 

/*/{Protheus.doc} getToken
Getter do atributo token
@author Matheus Jos� da Cunha
@since 01/10/2019
@param param_name, param_type, param_descr
@return token, characters, atributo token
/*/
Method getToken() Class TokenAuthPortal
Return self:token

