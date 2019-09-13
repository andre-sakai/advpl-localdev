#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'
#include 'topconn.ch'
#include 'tbiconn.ch'



Class TWMSA21A

Data Filial		//	as String optional
Data Locali		//	as String optional
Data Ident		//	as String optional

Data Retorno 		// Objeto com array
Data Divergencias	//	Produtos com divergencias

Method New() CONSTRUCTOR
Method BuscaDivergencia()
Method InsereCorrecao() 
Method MarcaDivergencia() 

EndClass


Method New(xFilial,xLocal,xIdent) CLASS TWMSA21A 

	self:Filial 	:= iif(!empty(xFilial),xFilial,Z06->Z06_FILIAL)
	self:Locali 	:= iif(!empty(xLocal),xLocal,Z06->Z06_LOCAL)
	self:Ident 		:= iif(!empty(xIdent),xIdent,Z06->Z06_NUMOS)
	
	self:Retorno	:= TWMSA21AR():NEW()
	
	::BuscaDivergencia()
	
Return self

Method InsereCorrecao(_item,transferencias,mensagem) CLASS TWMSA21A 





Return .t.

Method MarcaDivergencia(_xFilial,_xLocal,_xProd,_xRecno) CLASS TWMSA21A 



Return .t.


Method BuscaDivergencia() CLASS TWMSA21A 

Local aRet := {}
Local xBFilial 	:= self:Filial
Local xBLocali 	:= self:Locali
Local xBIdent	:= self:Ident
	
Local _xAlias1 := getnextalias()
Local oDivergencia := nil


//eecview('Filial: '+xBFilial+CRLF+'IDENT: '+xBIdent+CRLF,'TWMSA21A')

BeginSQL Alias _xAlias1
	%noparser%
	SELECT '  ' OK, FILIAL, CODIGO, LOCALI, ENDERECO, PRODUTO, SUM(PREVISTO) SUMPREV, SUM(REALIZADO) SUMREAL, CONTAGEM, '3' STATUS,
	(	SELECT 	COALESCE(SUM(Z16_SALDO),0)
		FROM 	Z16010 Z16A (NOLOCK) 
		WHERE 	Z16_FILIAL=FILIAL AND Z16_LOCAL=LOCALI AND Z16_ENDATU=ENDERECO AND 
				Z16_CODPRO=PRODUTO AND Z16A.D_E_L_E_T_=' '
	) SALDOZ16,
	(	SELECT COALESCE(SUM(BF_QUANT),0) 
		FROM SBF010 SBFA (NOLOCK) 
		WHERE 	BF_FILIAL=FILIAL AND BF_LOCAL=LOCALI AND BF_LOCALIZ=ENDERECO AND 
				BF_PRODUTO=PRODUTO AND SBFA.D_E_L_E_T_=' '
	) SALDOSBF
	 
	FROM (
		SELECT Z19_FILIAL FILIAL ,Z19_IDENT CODIGO,Z19_LOCAL LOCALI,Z19_ENDERE ENDERECO, 
				Z19_CODPRO PRODUTO, 0 AS PREVISTO,Z19_QUANT AS REALIZADO, Z19_CONTAG CONTAGEM 
		FROM %table:Z19% Z19 (NOLOCK)
		WHERE Z19_FILIAL = %EXP:xBFilial% AND Z19_IDENT = %EXP:xBIdent%  AND Z19.D_E_L_E_T_=' '
		AND Z19_CONTAG=COALESCE((SELECT MAX(Z19A.Z19_CONTAG) FROM %table:Z19% Z19A (NOLOCK) WHERE Z19A.Z19_FILIAL=Z19.Z19_FILIAL AND Z19A.Z19_IDENT=Z19.Z19_IDENT AND Z19A.Z19_LOCAL=Z19.Z19_LOCAL AND Z19A.Z19_ENDERE=Z19.Z19_ENDERE AND Z19A.Z19_CODPRO=Z19.Z19_CODPRO AND Z19A.D_E_L_E_T_=' ' ),'001' )
		
		UNION ALL
		
		SELECT Z21_FILIAL FILIAL ,Z21_IDENT CODIGO,Z21_LOCAL LOCALI,Z21_LOCALI ENDERECO,
				Z21_PROD PRODUTO,Z21_QUANT PREVISTO, 0 REALIADO, Z21_NRCONT CONTAGEM  
		FROM %TABLE:Z21% Z21 (NOLOCK)
		WHERE Z21_FILIAL = %EXP:xBFilial% AND Z21_IDENT = %EXP:xBIdent% AND Z21.D_E_L_E_T_=' ' 
		AND Z21_NRCONT = COALESCE((SELECT MAX(Z21_NRCONT) FROM %TABLE:Z21% Z21A (NOLOCK) WHERE Z21A.Z21_FILIAL=Z21.Z21_FILIAL AND Z21A.Z21_IDENT=Z21.Z21_IDENT AND Z21A.Z21_LOCAL=Z21.Z21_LOCAL AND Z21A.Z21_LOCALI=Z21.Z21_LOCALI AND Z21A.Z21_PROD=Z21.Z21_PROD AND Z21A.D_E_L_E_T_=' ' ),'001')
	) A
	JOIN %TABLE:Z06% Z06 (NOLOCK) ON Z06_FILIAL = FILIAL AND Z06_NUMOS=CODIGO AND Z06_STATUS NOT IN ('CA','AG') AND Z06.D_E_L_E_T_=' '
	GROUP BY FILIAL, CODIGO, LOCALI, ENDERECO, PRODUTO, CONTAGEM
	HAVING SUM(PREVISTO) <> SUM(REALIZADO)
	ORDER BY FILIAL, CODIGO, LOCALI, ENDERECO, PRODUTO,CONTAGEM
EndSQL


//eecview('sql: '+getlastquery()[2],'TWMSA21A')


If((_xAlias1)->(EOF()))
	self:Retorno:Mensagem 	:= 'Não foi encontrada nenhuma divergência'
Else
	While((_xAlias1)->(!EOF()))
		
		oDivergencia := TWMS21AD():new() //Objeto Tela Divergencias
		
		oDivergencia:OK		:= 	'  '
		oDivergencia:Filial		:= 	(_xAlias1)->FILIAL
		oDivergencia:Locali		:= (_xAlias1)->LOCALI
		oDivergencia:Ident		:= 	(_xAlias1)->CODIGO
		oDivergencia:Endereco	:= 	(_xAlias1)->ENDERECO
		oDivergencia:Produto	:= 	(_xAlias1)->PRODUTO
		oDivergencia:Previsto 	:= (_xAlias1)->SUMPREV
		oDivergencia:Realizado	:= (_xAlias1)->SUMREAL
		oDivergencia:SaldoZ16	:= (_xAlias1)->SALDOZ16
		oDivergencia:SaldoSBF	:= (_xAlias1)->SALDOSBF
		oDivergencia:Contagem	:= (_xAlias1)->CONTAGEM
		
		
		//eecview(varinfo('oDivergencia',oDivergencia),'TWMS21AD')
		
		
		
		aadd(self:Retorno:Dados,oDivergencia)

		(_xAlias1)->(DbSkip())
	EndDo
	
	(_xAlias1)->(DbCloseArea())
	
	self:Retorno:Mensagem 	:= 'Divergências encontradas'
	
EndIf
	
	//self:Retorno:Dados 		:= aRet
	//self:Retorno:Mensagem 	:= 'BuscaEtiqueta'

Return .t.
/*
Method ConsultaPxR(_xIdent,_xAliasA)


	BeginSql Alias _xAliasA
		%noparser%
		SELECT '  ' OK, FILIAL, CODIGO, LOCAL, ENDERECO, PRODUTO, SUM(COALESCE(PREVISTO,0)) SUMPREV, SUM(COALESCE(REALIZADO,0)) SUMREAL, CONTAGEM, '3' STATUS 
		FROM (
			SELECT Z19_FILIAL FILIAL ,Z19_IDENT CODIGO,Z19_LOCAL "LOCAL",Z19_ENDERE ENDERECO, 
					Z19_CODPRO PRODUTO, 0 AS PREVISTO,Z19_QUANT AS REALIZADO, Z19_CONTAG CONTAGEM 
			FROM %table:Z19% Z19 (NOLOCK)
			WHERE Z19_FILIAL = %EXP:XFILIAL('Z19')% AND Z19_IDENT = %EXP:_xIdent%  AND Z19.D_E_L_E_T_=' '
			AND Z19_CONTAG=(SELECT MAX(Z21A.Z21_NRCONT) FROM Z21010 Z21A (NOLOCK) WHERE Z21A.Z21_FILIAL=Z19.Z19_FILIAL	AND Z21A.Z21_IDENT=Z19.Z19_IDENT AND Z21A.Z21_LOCAL=Z19.Z19_LOCAL AND 	Z21A.Z21_LOCALI=Z19.Z19_ENDERE AND 	Z21A.Z21_PROD=Z19.Z19_CODPRO AND Z21A.D_E_L_E_T_=' '	)
			
			UNION
			
			SELECT Z21_FILIAL FILIAL ,Z21_IDENT CODIGO,Z21_LOCAL "LOCAL",Z21_LOCALI ENDERECO,
					Z21_PROD PRODUTO,Z21_QUANT PREVISTO, 0 REALIADO, Z21_NRCONT CONTAGEM  
			FROM %TABLE:Z21% Z21 (NOLOCK)
			WHERE Z21_FILIAL = %EXP:XFILIAL('Z21')% AND Z21_IDENT = %EXP:_xIdent% AND Z21.D_E_L_E_T_=' ' 
			AND Z21_NRCONT=(SELECT MAX(Z21_NRCONT) FROM Z21010 Z21A (NOLOCK) WHERE Z21A.Z21_FILIAL=Z21.Z21_FILIAL	AND Z21A.Z21_IDENT=Z21.Z21_IDENT AND Z21A.Z21_LOCAL=Z21.Z21_LOCAL AND 	Z21A.Z21_LOCALI=Z21.Z21_LOCALI AND 	Z21A.Z21_PROD=Z21.Z21_PROD AND Z21A.D_E_L_E_T_=' '	)
		) A
		JOIN %TABLE:Z06% Z06 (NOLOCK) ON Z06_FILIAL = FILIAL AND Z06_NUMOS=CODIGO AND Z06_STATUS NOT IN ('CA','AG') AND Z06.D_E_L_E_T_=' '
		GROUP BY FILIAL, CODIGO, LOCAL, ENDERECO, PRODUTO, CONTAGEM
		HAVING SUM(COALESCE(PREVISTO,0)) <> SUM(COALESCE(REALIZADO,0))
		ORDER BY FILIAL, CODIGO, LOCAL, ENDERECO, PRODUTO,CONTAGEM
	EndSql

Return {_xAliasA,GetLastQuery()[2]}
*/




Class TWMSA21AR

Data Dados		//	as Array
Data Mensagem		//	as String


Method New() CONSTRUCTOR

EndClass

Method New() Class TWMSA21AR
	self:Dados		:= {}
	self:Mensagem	:= ''
Return self




Class TWMS21AD // ITEM DE DIVERGÊNCIA

Data OK
Data Filial		//	as String optional
Data Locali		//	as String optional
Data Ident		//	as String optional
Data Endereco
Data Produto
Data Previsto
Data Realizado
Data Saldo
Data SaldoSBF
Data SaldoZ16
Data Contagem

Data Itens

Method New() CONSTRUCTOR

EndClass

Method New(/*xFilial,xLocal,xIdent,xEnde,xProd*/) Class TWMS21AD
	self:OK 		:= '  '
	self:Filial		:= 	''//	as String optional
	self:Locali		:= 	''	//	as String optional
	self:Ident		:= 	''	//	as String optional
	self:Endereco	:= 	''	
	self:Produto	:= 	''
	self:Previsto	:= 	0
	self:Realizado	:= 	0
	self:Saldo		:= 	0
	self:SaldoSBF	:= 	0
	self:SaldoZ16	:= 	0
	self:Contagem	:= 	'   '
Return self

Class TWMSA21AT


EndClass

