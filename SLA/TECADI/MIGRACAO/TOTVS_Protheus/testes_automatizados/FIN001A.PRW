#include "totvs.ch"

User Function FIN001A(_cRotina)

Local _lRet     := .T.
Local _cHtml    := ''
Local _cCsv     :=''

Local _tIni		:= Time()
Local _tFim 	:= ''

Local _cCod 	:= ''
Local _lAchou 	:= ''
Local _xAlias 	:= ''

Private lMsErroAuto := .F.

//Cadastro de Produto
if(_cRotina == 'MATA010')

/*
SELECT B1_GRUPO, B1_CODCLI, B1_COD, B1_DESC, B1_TIPO, B1_UM, B1_SEGUM, B1_CONV, B1_TIPCONV, B1_LOCPAD,
       B1_LOCALIZ, B1_ORIGEM, B1_POSIPI, B1_ZINFADI, B1_ZTIPPRO, B1_GARANT, B1_ZINFQTD, B1_RASTRO, B1_ZGRPEST, B1_CODBAR, B1_ZTPBAR
FROM   TOTVS.dbo.sb1010
WHERE  B1_COD = 'JULI9138'
ORDER  BY r_e_c_n_o_ DESC 
*/
	_cCod := 'JULI9138'
	_cCod := PADR(_cCod,TamSx3("B1_COD")[1],' ')
	
	_xAlias := 'SB1'
	
	dbselectarea(_xAlias)
	(_xAlias)->(DBSETORDER(1))
	_lAchou := (_xAlias)->(dbSeek(FWFILIAL(_xAlias)+_cCod))
	
	_aDados := {}
	lMsErroAuto := .f.
	if(!_lAchou)
		aAdd(_aDados,{"B1_GRUPO"  , 'JULI'    , NIL} )
		aAdd(_aDados,{"B1_CODCLI" , '9138'  , NIL} )
		aAdd(_aDados,{"B1_COD"    , _cCod        , NIL} )
		aAdd(_aDados,{"B1_DESC"   , 'CABO CAMBIO TRAS 1.2MM-1900MM 19 FIOS'      , NIL} )
		aAdd(_aDados,{"B1_TIPO"   , 'ME'      , NIL} )
		aAdd(_aDados,{"B1_UM"     , 'CT'          , NIL} )
		aAdd(_aDados,{"B1_SEGUM"  , '  '    , NIL} )
		aAdd(_aDados,{"B1_CONV"   , 0, NIL} )
		aAdd(_aDados,{"B1_TIPCONV", 'M', NIL} )
		aAdd(_aDados,{"B1_LOCPAD" , '01', NIL} )
		aAdd(_aDados,{"B1_LOCALIZ", 'S', NIL} )
		aAdd(_aDados,{"B1_ORIGEM" , '1', NIL} )
		aAdd(_aDados,{"B1_POSIPI" , '87149990  ', NIL} )
		aAdd(_aDados,{"B1_ZINFADI", ''                            , NIL} )
		aAdd(_aDados,{"B1_ZTIPPRO", 'A'					, NIL} )
		aAdd(_aDados,{"B1_GARANT" , '2', NIL} )
		aAdd(_aDados,{"B1_ZINFQTD", 'S', NIL} )
		aAdd(_aDados,{"B1_RASTRO" , 'N', NIL} )
		aAdd(_aDados,{"B1_ZGRPEST", '', NIL} )
		aAdd(_aDados,{"B1_CODBAR" , '9138'                                , NIL} )
		aAdd(_aDados,{"B1_ZTPBAR" , '', NIL} )
		
		_nOpc := 3
		// TEMPO 4S
	Else
		aAdd(_aDados,{"B1_COD"    , _cCod        , NIL} )
		aAdd(_aDados,{"B1_DESC"   , 'CABO CAMBIO TRAS 1.2MM-1900MM 19 FIOS ALT'      , NIL} )
		
		_nOpc := 4
		//TEMPO 1S
	EndIf
	
	_aDados := FWVetByDic(_aDados,'SB1',.F.)
	MSExecAuto({|x,y| MATA010(x,y)}, _aDados, _nOpc) // 3-Inclusao/4-Alteracao
	
	_tFim := Time()
	
	If (lMsErroAuto)
		_cMsg := MostraErro(,,.f.)
	Else
		_cMsg := 'MATA010 - EXECAUTO OK'
	EndIf
	
	eecview('<HTML>MATA010 '+iif(_lAchou,'altera','inclui')+'<BR> TEMPO DE EXECUCAO:'+ELAPTIME(_tIni,_tFim)+'<br>'+_cMsg,'MATA010')
	
	if(_nopc = 4 .and. _lAchou .AND. 1==2)
		_tIni := time()
		_nOpc := 5
		lMsErroAuto := .f.
		MSExecAuto({|x,y| MATA010(x,y)}, _aDados, _nOpc) // 3-Inclusao/4-Alteracao
		_tFim := time()
		
		If (lMsErroAuto)
			_cMsg := MostraErro(,,.f.)
		Else
			_cMsg := 'MATA010 - EXECAUTO OK'
		EndIf
		eecview('<HTML>MATA010 exclui<BR> TEMPO DE EXECUCAO:'+ELAPTIME(_tIni,_tFim)+'<br>'+_cMsg,'MATA010')
		//TEMPO > 1 MIN
	EndIf

ElseIf(_cRotina =='MATA020')		//MATA020 - fornecedor

/*
SELECT B1_GRUPO, B1_CODCLI, B1_COD, B1_DESC, B1_TIPO, B1_UM, B1_SEGUM, B1_CONV, B1_TIPCONV, B1_LOCPAD,
       B1_LOCALIZ, B1_ORIGEM, B1_POSIPI, B1_ZINFADI, B1_ZTIPPRO, B1_GARANT, B1_ZINFQTD, B1_RASTRO, B1_ZGRPEST, B1_CODBAR, B1_ZTPBAR
FROM   TOTVS.dbo.sb1010
WHERE  B1_COD = 'JULI9138'
ORDER  BY r_e_c_n_o_ DESC 
*/
	_aDados := {}
	_cCod := '00279501'
	_xAlias := 'SA2'
	_cCod := PADR(_cCod,TamSx3("A2_COD")[1],' ')
	
	
	dbselectarea(_xAlias)
	(_xAlias)->(DBSETORDER(1))
	_lAchou := (_xAlias)->(dbSeek(FWFILIAL(_xAlias)+_cCod))
	
	_aDados := {}
	lMsErroAuto := .f.
	if(!_lAchou)
		//CONSULTORIA MORGANA HANSEN ME
		/*
		A2_CGC, A2_TIPO, A2_NOME, A2_NREDUZ, A2_END, A2_EST, A2_ESTC, A2_COD_MUN, A2_MUN,A2_MUNC,
		A2_CEP, A2_CEPC, A2_DDD, A2_TEL, A2_INSCR, A2_CODPAIS, A2_EMAIL
		*/ 
		// alimenta Vetor com os dados do cliente a ser Cadastrado/atualizado
		aAdd(_aDados,{"A2_COD"		,'002795', NIL})	// CPF/CNPJ
		aAdd(_aDados,{"A2_LOJA"		,"01"/*,"F"*/, NIL})	// F-Fisica/J-Juridica
		aAdd(_aDados,{"A2_CGC"		,'35003736000106', NIL})	// CPF/CNPJ
		aAdd(_aDados,{"A2_TIPO"		,"J"/*,"F"*/, NIL})	// F-Fisica/J-Juridica
		aAdd(_aDados,{"A2_NOME"		,'CONSULTORIA MORGANA HANSEN ME           ', NIL})	// nome
		// verifica se existe o nome fantasia/reduzido
		aAdd(_aDados,{"A2_NREDUZ",'MORGANA HANSEN DE SO'						,NIL})	// nome fantasia
		aAdd(_aDados,{"A2_END"		,'R MANOEL VIEIRA GARCAO, 77              '																	,NIL})	// endereco
		aAdd(_aDados,{"A2_EST"		,'SC'							,NIL})	// estado
		aAdd(_aDados,{"A2_COD_MUN"	,'08203',NIL})	// codigo do municipio
		aAdd(_aDados,{"A2_MUN"		,'08203',NIL})	// descricao do municipio
		aAdd(_aDados,{"A2_BAIRRO"	,'CENTRO'		,NIL})	// bairro
		aAdd(_aDados,{"A2_CEP"		,'88301425',NIL})	// CEP
		aAdd(_aDados,{"A2_DDD"		,'047',NIL})	// DDD
		aAdd(_aDados,{"A2_TEL"		,'                                                  ',NIL})	// telefone
		aAdd(_aDados,{"A2_INSCR"		,'                  ',NIL})	// insc estadual
		aAdd(_aDados,{"A2_CODPAIS"	,"01058",NIL})	// pais do BACEN
		aAdd(_aDados,{"A2_EMAIL"		,"CONTABILIDADEMAGNUS@GMAIL.COM",NIL})	// e-mail do cliente
		_nOpc := 3    
	Else
		_nOpc := 4    
		aAdd(_aDados,{"A2_COD"		,'002795', NIL})	// CPF/CNPJ
		aAdd(_aDados,{"A2_LOJA"		,'01'/*,"F"*/, NIL})	// F-Fisica/J-Juridica
		aAdd(_aDados,{"A2_NOME"		,'CONSULTORIA MORGANA HANSEN ME ALT          ', NIL})	// nome
	EndIf

	_aDados := FWVetByDic(_aDados,'SA2',.F.)

	lMsErroAuto := .F.

	DbSelectArea("SA2")
	MSExecAuto({|x,y| mata020(x,y)},_aDados,_nOpc) // 3-Inclusao / 4-Alteracao

	_tFim := Time()
	
	If lMserroauto
		_cMsg := MostraErro(,,.f.)
	Else
		_cMsg := 'MATA020 - EXECAUTO OK'
	EndIf
	eecview('<HTML>MATA020 '+iif(_lAchou,'altera','inclui')+'<BR> TEMPO DE EXECUCAO:'+ELAPTIME(_tIni,_tFim)+'<br>'+_cMsg,'MATA020')
ElseIf(_cRotina =='MATA030')		// mata030 - cliente
	_aDados := {}
	_cCod := '68483899272'
	_xAlias := 'SA1'
	_cCod := PADR(_cCod,TamSx3("A2_CGC")[1],' ')

///*u_fin001a('MATA030')*/existfunc('tmsao15')
//erro tmsa015 variavel não existe
	aAdd(_aDados,{"A1_CGC"     , PadR('68483899272'  , TamSx3("A1_CGC")[1]    ) , NIL}) // CPF/CNPJ
	aAdd(_aDados,{"A1_PESSOA"  , PadR('F' , TamSx3("A1_PESSOA")[1] ) , NIL}) // F-Fisica/J-Juridica
	aAdd(_aDados,{"A1_NREDUZ"  , PadR('ANDRE TESTE'  , TamSx3("A1_NREDUZ")[1] ) , NIL}) // nome fantasia
	aAdd(_aDados,{"A1_END"     , PadR('RUA TANCREDO NEVES, 4040                ' , TamSx3("A1_END")[1]    ) , NIL}) // endereco
	aAdd(_aDados,{"A1_TIPO"    , PadR('F'  , TamSx3("A1_TIPO")[1]   ) , NIL}) // tipo do cliente (F-Cons. Final/X-Exportacao)
	aAdd(_aDados,{"A1_EST"     , PadR('SC'   , TamSx3("A1_EST")[1]    ) , NIL}) // estado
	aAdd(_aDados,{"A1_ESTC"    , PadR('SC', TamSx3("A1_ESTC")[1]   ) , NIL}) // estado de cobranca
	aAdd(_aDados,{"A1_COD_MUN" , PadR('04301', TamSx3("A1_COD_MUN")[1]) , NIL}) // codigo do municipio
	aAdd(_aDados,{"A1_MUN"     , PadR('CONCORDIA                     ', TamSx3("A1_MUN")[1]    ) , NIL}) // descricao do municipio
	aAdd(_aDados,{"A1_MUNC"    , PadR(' ', TamSx3("A1_MUNC")[1]   ) , NIL}) // descricao do municipio de cobranca
	aAdd(_aDados,{"A1_BAIRRO"  , PadR(UPPER('Sao Cristovao')   , TamSx3("A1_BAIRRO")[1] ) , NIL}) // bairro
	aAdd(_aDados,{"A1_BAIRROC" , PadR(UPPER('Sao Cristovao'), TamSx3("A1_BAIRROC")[1]) , NIL}) // bairro de cobranca
	aAdd(_aDados,{"A1_CEP"     , PadR('89700001'      , TamSx3("A1_CEP")[1]    ) , NIL}) // CEP
	aAdd(_aDados,{"A1_CEPC"    , PadR('89700001'      , TamSx3("A1_CEPC")[1]   ) , NIL}) // CEP de cobranca
	aAdd(_aDados,{"A1_INSCR"   , PadR('ISENTO'  , TamSx3("A1_INSCR")[1]  ) , NIL}) // insc estadual
	aAdd(_aDados,{"A1_PAIS"    , PadR(' '  , TamSx3("A1_PAIS")[1]   ) , NIL}) // pais
	aAdd(_aDados,{"A1_CODPAIS" , PadR('01058'  , TamSx3("A1_CODPAIS")[1]) , NIL}) // pais do BACEN
	aAdd(_aDados,{"A1_EMAIL"   , PadR('.' , TamSx3("A1_EMAIL")[1]  ) , NIL}) // e-mail do cliente
	aAdd(_aDados,{"A1_ZNFSE"   , PadR('.', TamSx3("A1_ZNFSE")[1]  ) , NIL}) // e-mail nfs-e do cliente
	aAdd(_aDados,{"A1_COND"    , PadR(' ', TamSx3("A1_COND")[1]   ) , NIL}) // condicao de pagamento
	aAdd(_aDados,{"A1_CDRDES"  , PadR(' ', TamSx3("A1_CDRDES")[1] ) , NIL}) // regiao do cliente
	aAdd(_aDados,{"A1_NATUREZ" , PadR("01010101" , TamSx3("A1_NATUREZ")[1] ) , NIL}) // natureza financeira padrão
	aAdd(_aDados,{"A1_RECINSS" , PadR("S"        , TamSx3("A1_RECINSS")[1] ) , NIL}) // flag para recolher inss
	aAdd(_aDados,{"A1_RECCOFI" , PadR("S"        , TamSx3("A1_RECCOFI")[1] ) , NIL}) // flag para recolher cofins
	aAdd(_aDados,{"A1_RECCSLL" , PadR("S"        , TamSx3("A1_RECCSLL")[1] ) , NIL}) // flag para recolher CSLL
	aAdd(_aDados,{"A1_RECPIS"  , PadR("S"        , TamSx3("A1_RECPIS")[1] )  , NIL}) // flag para recolher PIS
	aAdd(_aDados,{"A1_RECIRRF" , PadR(1          , TamSx3("A1_RECIRRF")[1] ) , NIL}) // flag para recolher IRRF
	aAdd(_aDados,{"A1_SIGLA" , PadR('VALD' , TamSx3("A1_SIGLA")[1] ) , NIL}) // flag para recolher IRRF

	aAdd(_aDados,{"A1_DDD" , PadR('047' , TamSx3("A1_DDD")[1] ) , NIL}) // flag para recolher IRRF
	aAdd(_aDados,{"A1_TEL" , PadR('99999999' , TamSx3("A1_DDD")[1] ) , NIL}) // flag para recolher IRRF

	// se for alteracao, inclui campos codigo e loja
	dbselectarea(_xAlias)
	(_xAlias)->(DBSETORDER(3))
	_lAchou := (_xAlias)->(dbSeek(FWFILIAL(_xAlias)+_cCod))
	
	If ( _lAchou )
		aAdd(_aDados,{"A1_COD"  , SA1->A1_COD                             , NIL}) // codigo
		aAdd(_aDados,{"A1_LOJA" , SA1->A1_LOJA, NIL}) // loja
		aAdd(_aDados,{"A1_NOME"  , PadR(ALLTRIM(SA1->A1_NOME + ' ALT') , TamSx3("A1_NOME")[1] ) , NIL})
		_nOpc := 4
	Else
		aAdd(_aDados,{"A1_NOME"    , PadR('ANDRE', TamSx3("A1_NOME")[1]   ) , NIL}) // nome
		_nOpc := 3
	
	EndIf

	// padroniza dicionario de dados
	_aDados := FWVetByDic(_aDados, 'SA1', .F.)

	// variavel padrao
	lMsErroAuto := .F.

	// reposiciona no registro
	DbSelectArea("SA1")
	SA1->(dbSetOrder(1)) // 1-A1_FILIAL, A1_COD, A1_LOJA

	// rotina automatica de cadastro de cliente
	MSExecAuto({|x,y| MATA030(x,y)}, _aDados, _nOpc ) // 3-Inclusao / 4-Alteracao

	_tFim := Time()
	
	If lMserroauto
		_cMsg := MostraErro(,,.f.)
	Else
		_cMsg := 'MATA030 - EXECAUTO OK'
	EndIf
	eecview('<HTML>MATA030 '+iif(_lAchou,'altera','inclui')+'<BR> TEMPO DE EXECUCAO:'+ELAPTIME(_tIni,_tFim)+'<br>'+_cMsg,'MATA030')
	//tempo 2s
ElseIf(_cRotina =='MATA050')//mata050 - transportadora
	_aDados := {}
	_cCod := '08640510000135'
	_xAlias := 'SA4'
	_cCod := PADR(_cCod,TamSx3("A4_CGC")[1],' ')
	
	dbselectarea(_xAlias)
	(_xAlias)->(DBSETORDER(3))
	_lAchou := (_xAlias)->(dbSeek(FWFILIAL(_xAlias)+_cCod))
	
	aAdd(_aDados, {"A4_NREDUZ" , PadR('TECADI', TamSx3("A4_NREDUZ")[1] ) , nil})
	aAdd(_aDados, {"A4_END"    , PadR('RUA FRANCISCO REIS, 750, SALA 01' , TamSx3("A4_END")[1] ) , nil})
	aAdd(_aDados, {"A4_BAIRRO" , PadR("CENTRO", TamSx3("A4_BAIRRO")[1] ) , nil})
	aAdd(_aDados, {"A4_EST"    , PadR('SC' , TamSx3("A4_EST")[1] ) , nil})
	aAdd(_aDados, {"A4_COD_MUN", PadR('08203', TamSx3("A4_COD_MUN")[1] ), nil})
	aAdd(_aDados, {"A4_MUN"    , PadR('ITAJAI' , TamSx3("A4_MUN")[1] ) , nil})
	aAdd(_aDados, {"A4_CGC"    , PadR('08640510000135'  , TamSx3("A4_CGC")[1] ) , nil})
	aAdd(_aDados, {"A4_CODPAIS", PadR("01058" , TamSx3("A4_CODPAIS")[1] ) , nil})

	If ( _lAchou )
		aAdd(_aDados,{"A4_COD"  , SA4->A4_COD                             , NIL}) // codigo
		aAdd(_aDados,{"A4_NOME"  , PadR(ALLTRIM(SA4->A4_NOME + ' ALT') , TamSx3("A1_NOME")[1] ) , NIL})
		_nOpc := 4
	Else
		_nOpc := 3
		aAdd(_aDados, {"A4_NOME"   , PadR('TECADI', TamSx3("A4_NOME")[1] ) , nil})
	
	EndIf
	
	// padronizao ordem dos campos
	_aDados := FWVetByDic(_aDados, "SA4", .F.)

	// rotina automatica de cadastro de transportadoras
	MSExecAuto({|x,y| Mata050(x,y)}, _aDados, _nOpc) // 3-Incluir

	_tFim := Time()
	
	If lMserroauto
		_cMsg := MostraErro(,,.f.)
	Else
		_cMsg := 'MATA050 - EXECAUTO OK'
	EndIf
	eecview('<HTML>MATA050 '+iif(_lAchou,'altera','inclui')+'<BR> TEMPO DE EXECUCAO:'+ELAPTIME(_tIni,_tFim)+'<br>'+_cMsg,'MATA050')
	//execução em 1s

ElseIf(_cRotina == 'MATA242')

ElseIf(_cRotina == 'MATA261')

ElseIf(_cRotina == 'MATA265')

ElseIf(_cRotina == 'FINA040')
	
EndIf

/*
Mata242 - desmontagem
mata261 - transferencia
mata265 - endereçamento
mata410 - pedido de venda
MATA920 - nota manual de saida ????
Fina040 - contas a receber
FINA050 - CONTAS A PAGAR
*/



//testes de validação de nota de entrada



//criar solicitação de compra

//criar pedido de compra

//aprovação de pedido de compra

//efetivação de documento de entrada

//Compensação de NF com PA

//compensação de PA com NF -> validação de baixa de valor dos impostos para verificar se sobra saldo

//abrir posição do título

//descompensar

//gerar fatura de 2 títulos

//tela de rastrei rastreio dentro de visualizar título

//gerar cnab de pagamento

//gerar retorno fake do pagamento


//transferencia de estoque


/*
MATA010 - produto

*/


/*


mata050 - transportadora
MATA103 - documento de entrada
Mata140 - pre nota
Mata242 - desmontagem
mata261 - transferencia
mata265 - endereçamento
mata410 - pedido de venda
MATA920 - nota manual de saida ????
Fina040 - contas a receber
FINA050 - CONTAS A PAGAR
*/

//TICFG001.PRW
//215: MsExecAuto({|x,y|MATA261(x,y)},_aItemSD3,3) // 3-transferencia 

//TFATA001.PRW
//485: MsExecAuto({|x,y,z| Mata410(x,y,z)},_aCabAuto,_aIteAuto,3) // 3-inclusao  
//2.252: MSExecAuto({|x,y| Mata050(x,y)}, _aDadosSA4, 3) // 3-Incluir  

//TFATA002.PRW
//3.318: MSExecAuto({|x,y,z|Mata410(x,y,z)},_aPedCabec,_aPedItens,3)  
//4.007: MSExecAuto({|x,y,z|Mata410(x,y,z)},{{"C5_NUM",(_TRBGERAL)->IT_NUMPED,Nil}},{},5)  

//TFATA003.PRW
//120: MSExecAuto({|x,y,z| mata265(x,y,z)}, _aCabSDA, _aItemSDB, 4)     //4-Estorno   

//TFINA003.prw
//569: MSExecAuto({|x,y,z| FINA050(x,y,z)},_aDadTitPag,,3) // 3-Inclusao 

//TTMSXDAT.prw F2, _aItensSD2, 3) // 3-Inclusao 
//1.189: MSExecAuto({|x,y| Fina040(x,y)}, _aAutoSE1, 3) // 3-Incluir 
//1.254: MSExecAuto({|x,y| Fina040(x,y)}, _aAutoSE1, 5) // 5-Excluir 
//1.287: MSExecAuto({|x,y,z| MATA920(x,y,z)}, _aCabSF2, _aItensSD2, 5) // 5-Exclusao 
//1.645: MSExecAuto({|x,y| MATA030(x,y)}, _aDados, _nOpcMnu ) // 3-Inclusao / 4-Alteracao 
//2.457: MSExecAuto({|x,y| Fina040(x,y)}, _aAutoSE1, 3) // 3-Incluir 
//3.295: MSExecAuto({|x,y,z| MATA920(x,y,z)}, _aCabSF2, _aItensSD2, 3) // 3-Inclusao 
//3.318: MSExecAuto({|x,y,z| MATA920(x,y,z)}, _aCabSF2, _aItensSD2, 5) // 5-Exclusao 
//3.615: MsExecAuto({|x,y,z| MATA103(x,y,z)}, _aDadCabec, _aDadItens, 3) // 3-inclusao 
//3.913: MSExecAuto({|x,y| MATA020(x,y)}, _aDadosSA2, _nOpcMnu ) // 3-Inclusao / 4-Alteracao 
//4.354: MSExecAuto({|x,y| FINA080(x,y)}, _aBaixaPag, 3) // 3 - Inclusao, 4 - Alteração, 5 - Exclusão 
//4.519: MsExecAuto( { |x,y,z| FINA050(x,y,z)}, _aArraySE2,, 3) // 3 - Inclusao, 4 - Alteração, 5 - Exclusão 

//TWMSA006.PRW (3 correspondências)
//436: MsExecAuto({|x,y,z|Mata140(x,y,z)},_aCabAuto,_aIteAuto,3)  
//1.978: MSExecAuto({|x,y| mata030(x,y)},_aDados,3) // 3-Inclusao / 4-Alteracao  
//2.052: MSExecAuto({|x,y| mata020(x,y)},_aDadosSA2,3) // 3-Inclusao / 4-Alteracao  

//TWMSA009.PRW
//8.614: MSExecAuto({|x,y,z| mata265(x,y,z)},_aCabSDA,_aItemSDB,3) //Distribui  

//TWMSA010.PRW (2 correspondências)
//3.528: MSExecAuto({|x,y,z| mata265(x,y,z)},_aCabSDA,_aItemSDB,3) //Distribui  
//3.726: MsExecAuto({|x,y,z| Mata410(x,y,z)}, _aCabSC5, _aItensSC6, 3)


//TWMSA011.PRW (4 correspondências)
//1.701: MSExecAuto({|x,y,z| mata265(x,y,z)},_aCabSDA,_aItemSDB,3) //3-Distribui  
//1.759: MSExecAuto({|x,y,z| mata265(x,y,z)},_aCabSDA,_aItemSDB,3) //3-Distribui  
//1.843: MsExecAuto({|x,y|MATA261(x,y)},_aItemSD3,3) // 3-transferencia  
//1.948: MsExecAuto({|x,y|MATA261(x,y)},_aItemSD3,3) // 3-transferencia  

//TWMSA015.PRW (5 correspondências)
//1.315: MSExecAuto( { |x,y| mata261(x,y) }, _aItemSD3, 6 ) // 6-estorno  
//1.400: MSExecAuto({|x,y,z| mata265(x,y,z)}, _aCabSDA, _aItemSDB, 4) //4-Estorno  
//1.464: MSExecAuto( { |x,y| mata261(x,y) }, _aItemSD3, 6 ) // 6-estorno  
//1.867: // ordenar o vetor conforme o dicionário para uso de rotinas via MSExecAuto  
//1.873: MSExecAuto({|v,x,y,z| Mata242(v,x,y,z)}, _aAutoCab, _aAutoItens, 5, .T.) //5-ESTORNO  


//TWMSA019.PRW (2 correspondências)
//1.085: MsExecAuto({|x,y|MATA261(x,y)}, _aItemSD3, 3) // 3-transferencia  
//3.837: MSExecAuto({|x,y| mata261(x,y)},_aItemSD3,6) // 6-estorno  

//TWMSA021.PRW (5 correspondências)
//3.444: Descricao: execauto de transferência,   
//3.555: MSExecAuto({|x,y| mata261(x,y)},aAuto,nOpcAuto)  
//3.558: //msgalert('erro','execauto mata261')  
//3.564: //msgalert('ok','execauto mata261')  
//3.593: MSExecAuto({|x,y| mata261(x,y)},aAuto,nOpcAuto)  

//TWMSA033.prw
//1.033: MsExecAuto({|x,y| MATA261(x,y) },_aItemSD3,3) // 3-transferencia 

//TWMSA038.prw (2 correspondências)
//469: MsExecAuto({|x,y,z| Mata410(x,y,z)}, _aCabAuto, _aIteAuto, 3) // 3-inclusao 
//500: MemoWrit("c:\query\TWMSA038_erro_execauto_" + Z50->Z50_NUMSOL + ".txt", U_FTAchaErro() ) 

//TWMSA042.prw (2 correspondências)
//682: MSExecAuto({|x,y,z| U_TWMSA042(x,y,z)}, _aCabOndSep, _aItmOndSep, 3) 
//800: MSExecAuto({|x,y,z| U_TWMSA042(x,y,z)}, _aCabOndSep, _aItmOndSep, 3) 

//TWMSA047.prw (16 correspondências)
//399: MSExecAuto({|x,y,z| U_TWMSA040(x,y,z)}, _aCabEtique, aItmEtique, 3) 
//525: MSExecAuto({|x,y,z| U_TWMSA040(x,y,z)}, _aCabEtique, _aItmEtique, 5) 
//981: MsExecAuto({|x,y,z| Mata410(x,y,z)},_aCabAuto,_aIteAuto,3) // 3-inclusao 
//1.102: MsExecAuto({|x,y,z| Mata410(x,y,z)},_aCabAuto,_aIteAuto,5) // 5-Exclusão 
//1.557: MSExecAuto( { |x, y, z| OMSA200(x, y, z) }, aCab, aItem, 3 ) 
//1.595: MSExecAuto( { |x, y, z| OMSA200(x, y, z) }, aCab, aItem, 5 ) 

//TWMSA051.prw
//206: MSExecAuto({|x,y,z| mata265(x,y,z)},aCabSDA,aItemSDB,3) //Distribui 

//TWMSA053.prw (4 correspondências)
//377: MSExecAuto({|x,y,z| mata265(x,y,z)}, aCabSDA, aItemSDB, 3) // 3 - Distribui 
//454: MsExecAuto({|x,y|MATA261(x,y)}, _aItemSD3, 3) // 3 - transferencia 
//460: Alert("Erro Execauto transferencia entre armazens - " + Alltrim(SDA->DA_PRODUTO) ) 
//517: MSExecAuto({|x,y,z| mata265(x,y,z)}, aCabSDA, aItemSDB, 3) // 3 - Distribui 

//TWMSA054.prw (2 correspondências)
//340: MsExecAuto({|x,y|MATA261(x,y)}, _aItemSD3, 3) // 3 - transferencia 

//TEDI002.prw
//539: MSExecAuto({|x,y| MATA010(x,y)}, aDadosPro, 3) //Inclusao 


//TWMSXFU2.prw
//2.161: MSExecAuto({|x,y| MATA010(x,y)}, _aDados, 3) // 3-Inclusao/4-Alteracao 
//3.529: MsExecAuto({|x,y|MATA261(x,y)}, _aItemSD3, 3) // 3 - transferencia   

//MTA265I.prw (2 correspondências)
//88: //Ordenar o vetor conforme o dicionário para uso de rotinas via MSExecAuto. 
//92: MSExecAuto({|v,x,y,z| Mata242(v,x,y,z)},_aAutoCab,_aAutoItens,3,.T.) // 3-Inclusao 
  
Return


Static Function geralog(_cRotina,_cMsg,_cTipo,_cFile)

	If(Empty(_cFile))
		_xEndFile :=  '/tecadi/'
		if(!isdir(_xEndFile))
		
		else
			if(!isdir(_xEndFile))
			
			else
					
			endif		
		endif
		_cFile := '/tecadi/'
	EndIf
	
	

Return