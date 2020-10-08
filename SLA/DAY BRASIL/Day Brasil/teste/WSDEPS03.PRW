#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "Protheus.ch"
#INCLUDE "tbiconn.ch" 


// ##############################################################################
// Projeto  : DAYBRASIL
// Autor    : ANDRE SAKAI
// Modulo   : WS
// Função   : WSDEPS03 - CADASTRO DE PEDIDOS
// Descrição: WS PARA CONSULTA DE PEDIDOS - ALTERACAO DE PEDIDOS / CREDITO
// Retorno  : REST COM AS INFORMACOES DA TABELA SC5/SC6
// ---------+-------------------+------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+------------------------------------------------
// 17/03/20 | André Sakai       | Desenvolvimento Inicial.
// ---------+-------------------+------------------------------------------------

WSRESTFUL WSDEPS03 DESCRIPTION "Cadastro de Clientes"

WSDATA PTOKEN AS STRING 
WSDATA CTIPO AS STRING OPTIONAL 
WSDATA NPAGINA AS INTEGER OPTIONAL 
WSDATA NREGISTRO AS INTEGER OPTIONAL 
WSDATA CFILTRO AS STRING OPTIONAL 
WSDATA CDTFILTRO AS STRING OPTIONAL 									
WSDATA CTESTE AS STRING OPTIONAL 

WSDATA CWSEMP AS STRING OPTIONAL 
WSDATA CWSFIL AS STRING OPTIONAL 

WSDATA CWSDIC AS STRING OPTIONAL 								 
WSMETHOD POST DESCRIPTION "Cadastro de Pedidos - Credito 20200916 - 22:08" WSSYNTAX "/rest/WSDEPS03/{filial}/{pedido}"

END WSRESTFUL



WSMETHOD POST WSSERVICE WSDEPS03
Local _lRet  	:= .T.
Local _nI 		:= 0
Local _nJ := 0
//Local _nMaxReg := 30
Local _cContent := ''
Local _aRetError := {}
Local _aValid := {}
Local _lPrepEnv := .F.

Local _cCodFil, _cCodPed

Private _oBody
Private lMsErroAuto
Private lAutoErrNoFile
Private cArquivo := '/temp/log-WSDEPS03-'+dtos(date())+'_'+strtran(time(),':','')+'.log'
Private _cWSname := 'WS206'
Private _aCabec,_aItens, _aItem


Default SELF:cTipo 		:=''
Default SELF:NPAGINA 	:=1
Default SELF:NREGISTRO 	:=20
Default SELF:CFILTRO 	:=''
Default SELF:CTESTE 	:=''


If(Select("SX2")<>0)
	IF(cEmpAnt <> SELF:CWSEMP)
		RpcClearEnv()   
	ElseIF(SELF:CWSFIL <> CFILANT)
		CFILANT := SELF:CWSFIL
	ENDIF
EndIf

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv(SELF:CWSEMP,SELF:CWSFIL, "SLA.CREDITO","SLA","FAT","",{"SA1","SA2","SA3","SA4"}) 
	_lPrepEnv := .T.
EndIf


::SetContentType("application/json")

_cVldTkn := AllTrim(GETMV('DY_TNKDEPS',.T.,'123456'))

If(!AllTrim(SELF:pToken) == _cVldTkn)
	::SetResponse('["ID":499,"Erro":"Token informado Invalido!"]')
	SetRestFault(499,'Token invalido, verifique a chave!')
	Return .F.
Else
	//conout('','Token Ok')
EndIf

_cContent  := SELF:GetContent()
FWJsonDeserialize(_cContent,@_oBody)

If (SELF:CTESTE = "SIM")
	::SetResponse(VARINFO('Body',_oBody,,.F.))
	Return .T.
EndIf

//::setresponse("antes dos campos")
//return .t.
_aValid := U_WS3CAMPOS('','SC5')
_aValid2 := U_WS3CAMPOS('','SC6')

_aValid := FWVetByDic(_aValid,'SC5',.f.,5)
_aValid2 := FWVetByDic(_aValid2,'SC6',.f.,5)

//::setresponse("depois dos campos")
//return .t.
If(Type('_oBody')== 'O')

	_oCab 	:= _oBody
	

	For _nI := 1 to Len (_aValid) 				
		If (type('_oCab:'+_aValid[_nI][1])=="U" .AND. _aValid[_nI][2]==.T.)
			aAdd(_aRetError,{'500','Campo '+_aValid[_nI][1]+' nao foi declarado'})
		Else
			If(type('_oCab:'+_aValid[_nI][1])=="C" .AND. _aValid[_nI][3]=="D")
				If(_aValid[_nI][1] = "XDATCRD")
					_oCab:XDATCRD := stod(&('_oCab:'+_aValid[_nI][1]))	
				EndIf
			EndIf
			
			If(type('_oCab:'+_aValid[_nI][1])!=_aValid[_nI][3] .AND. type('_oCab:'+_aValid[_nI][1])<>"U")
				aAdd(_aRetError,{'500','Campo '+_aValid[_nI][1]+' com Tipo: '+type('_oCab:'+_aValid[_nI][1])+' - Esperado: '+_aValid[_nI][3]})
			EndIf
		EndIf
	
	Next _nI
		


	If (Len(_aRetError) = 0)
	
		_aCabec := {}
		_aItem  := {}
		_aItens := {}
		
		
		
		_aValidC5 :=  U_WS3CAMPOS("COMPLETO",'SC5',.T.)
		_aValidC5 := FWVetByDic(_aValidC5,'SC5',.f.,5)
		
		_aValidC6 :=  U_WS3CAMPOS("COMPLETO",'SC6',.T.)
		_aValidC6 := FWVetByDic(_aValidC6,'SC6',.f.,5)
		
		_nI := 0
/*
			aAdd(_aCampos, {'FILIAL'	,.T.,'N',TAMSX3('C5_FILIAL')[1]		,'C5_FILIAL'		,NIL})				
			aAdd(_aCampos, {'NUMERO'	,.T.,'N',TAMSX3('C5_NUM')[1]		,'C5_NUM'		,NIL})				
			aAdd(_aCampos, {'XVLRCRD'	,.T.,'N',TAMSX3('C5_XVLRCRD')[1]	,'C5_XVLRCRD'		,NIL})				
			aAdd(_aCampos, {'XDATCRD'	,.F.,'D',TAMSX3('C5_XDATCRD')[1]	,'C5_XDATCRD'		,NIL})		
			aAdd(_aCampos, {'XUSRLIB'	,.F.,'C',TAMSX3('C5_XUSRLIB')[1]	,'C5_XUSRLIB'		,NIL})
			aAdd(_aCampos, {'XHORCRD'	,.F.,'C',TAMSX3('C5_XHORCRD')[1]	,'C5_XHORCRD'		,NIL})
			aAdd(_aCampos, {'XCPGLIB'	,.F.,'C',TAMSX3('C5_XCPGLIB')[1]	,'C5_XCPGLIB'		,NIL})
			aAdd(_aCampos, {'DEPSCRD'	,.T.,'C',TAMSX3('C5_XDEPSCR')[1]	,'C5_XDEPSCR'		,NIL})
			aAdd(_aCampos, {'DEPSMOT'	,.T.,'C',TAMSX3('C5_XDEPSMT')[1]	,'C5_XDEPSMT'		,NIL})
			aAdd(_aCampos, {'INOUT'		,.T.,'L',TAMSX3('C5_XINOUT')[1]		,'C5_XINOUT'		,NIL})
*/
		_cCodFil := &('_oCab:FILIAL')
		_cCodPed := &('_oCab:PEDIDO')


		SC5->(DBSETORDER(1))
		SC6->(DBSETORDER(1))
		If(SC5->(DBSEEK(_cCodFil+_cCodPed)))

			For _nI := 1 to Len(_aValidC5)
				If(alltrim(_aValidC5[_nI][5]) $ "C5_XVLRCRD#C5_XDATCRD#C5_XHORCRD#C5_XUSRLIB#C5_XCPGLIB#C5_DEPSCRD#C5_DEPSMOT#C5_INOUT#")
					If(Type('_oCab:'+_aValidC5[_nI][1])!='U' .and. ! ALLTRIM(_aValidC5[_nI][5]) $ 'C5_FILIAL#C5_NUM#')
						aadd(_aCabec,{_aValidC5[_nI][5]	,&('_oCab:'+_aValidC5[_nI][1]) , nil})
					EndIf		
				ElseIf(! ALLTRIM(_aValidC5[_nI][5]) $ 'C5_FILIAL#C5_NUM#' .AND. SUBSTR(_aValidC5[_nI][5],1,3)='C5_')
					aadd(_aCabec,{_aValidC5[_nI][5]	,SC5->(&(_aValidC5[_nI][5])) , nil})
				EndIf				
			Next _nI

			SC6->(DBSEEK(_cCodFil+_cCodPed))

			WHILE (!SC6->(EOF()) .AND. SC6->(C6_FILIAL+C6_NUM) =  _cCodFil+_cCodPed)
				For _nJ := 1 to Len(_aValidC6)
					If(ALLTRIM(_aValidC6[_nJ][5]) $ 'C6_QTDLIB')
						aadd(_aItem,{_aValidC6[_nJ][5]	,SC6->(C6_QTDVEN-C6_QTDENT) , nil})
					ElseIF(SUBSTR(_aValidC6[_nJ][5],1,3)='C6_')
						aadd(_aItem,{_aValidC6[_nJ][5]	,SC6->(&(_aValidC6[_nJ][5])) , nil})
					EndIf
				Next

				aadd(_aItens,_aItem)
				SC6->(DBSKIP())
			ENDDO
		Else
			conout('wsdeps03','pedido '+_cCodFil+'/'+_cCodPed+' nao encontrado!')


		EndIf

		//grava informações no pedido - campos customizados


		//
		SC5->(DBGOTOP())
		conout('wsdeps03 - pesquisa pedido '+_cCodFil+_cCodPed+' para excluir liberacao.')
		If(SC5->(DBSEEK(_cCodFil+_cCodPed)))
			conout('pedido encontrado')
			DbSelectArea('SC5')
			SC5->(DbSetOrder(1)) //C5_FILIAL + C5_NUM
	
			DbSelectArea('SC6')
			SC6->(DbSetOrder(1)) //C6_FILIAL + C6_NUM + C6_ITEM
			SC6->(DbGoTop())
		
			DbSelectArea('SC9')
			SC9->(DbSetOrder(1)) //C9_FILIAL + C9_PEDIDO + C9_ITEM
			SC9->(DbGoTop())
		
			//Se conseguir posicionar no pedido
		
			//INICIO DO ESTORNO
			CONOUT('verifica liberações')
			If SC6->(DbSeek(SC5->(C5_FILIAL+C5_NUM)))
				
				
				//Percorre todos os itens
				While ! SC6->(EoF()) .And. SC6->(C6_FILIAL+C6_NUM) = SC5->(C5_FILIAL+C5_NUM)
					//Posiciona na liberaï¿½ï¿½o do item do pedido e estorna a liberaï¿½ï¿½o
					If(SC9->(DbSeek(SC6->(C6_FILIAL+C6_NUM+C6_ITEM))))
					
						While  (!SC9->(Eof())) .AND. SC9->(C9_FILIAL+C9_PEDIDO+C9_ITEM) == SC6->(C6_FILIAL+C6_NUM+C6_ITEM)
							CONOUT('ACHOU ITEM LIB  '+C9_FILIAL+C9_PEDIDO+C9_ITEM)
						
							SC9->(a460Estorna(.T.))
							CONOUT('FIM LIB  '+C9_FILIAL+C9_PEDIDO+C9_ITEM)
							SC9->(DbSkip())
						EndDo
					else
					conout('sem liberaï¿½ï¿½o')
					EndIf
			
					SC6->(DbSkip())
				EndDo
				CONOUT('FIM ITEM '+SC6->C6_ITEM)
				
			EndIf
	   
		else
			conout('pedido nao encontrado '+_cCodFil+_cCodPed)
		EndIf									 
		CONOUT('FIM ESTORNO')
					 

	
	 
		DbSelectArea('SCV')
		SCV->(DbSetOrder(1)) //C9_FILIAL + C9_PEDIDO + C9_ITEM




		varinfo('_aCabec',_aCabec)
		varinfo('_aItens',_aItens)


		
//		::SetResponse("FIM)")
		lMsErroAuto := .F.
		lAutoErrNoFile := .T.
		_lRet := .T.
		conout('POST','wsdeps03 - INICIO EXECAUTO '+DTOS(DATE())+' - '+TIME())
			
		
		// rotina automatica do pedido de venda
		MsExecAuto({|x,y,z| Mata410(x,y,z)},_aCabec,_aItens,4) // 3-inclusao

		conout('POST','wsdeps03 - FIM EXECAUTO '+DTOS(DATE())+' - '+TIME())
		If !lMsErroAuto  // operacao se deu erro		
			conout('Pedido Alterado')
			::SetResponse('{"Mensagem":"Pedido Alterado"}')
		//	SetRestFault(401,formatjson(cMsg))
		//	return .f.

			Return _lRet	
		Else	
			conout('Erro ao alterar pedido')
			_aErroAuto := GetAutoGRLog()
			cMsg:= "ERRO - PEDIDO VENDA -Arquivo: "+cArquivo
			For _nI := 1 To Len(_aErroAuto)
				cMsg += StrTran(StrTran(StrTran(StrTran(_aErroAuto[_nI],"<",""),"-",""),"   "," "),chr(13),'') + (" ")
			Next _nI	
			//SetRestFault(401,'Erro: '+cMsg+'.')

			::SetResponse('{"ID":401,"Erro":"'+formatjson(cMsg)+'"}')

		//	SetRestFault(401,formatjson(cMsg))
		//	return .f.

			Return _lRet	
		EndIf	
			
	Else

		If(Len(_aRetError)>0)
			//
			
			SetRestFault(405,U_WS002RET(_aRetError))
			return .f.
			
		EndIf
		
	EndIf
	
EndIf

If(_lPrepEnv)
	RpcClearEnv()   
EndIf

Return _lRet

user function xcampos()

Local _nX := 0
Local _aTab   := {'SA1'}
Local _aCam   := {}

Private _cAliasSX3 := getnextalias()

If(Select("SX2")=0)
	RpcSetType(3)          
	//RpcSetEnv("07" ,"01", "","","","",{"SRA","CTT"})   	    	  
	RpcSetEnv('01','09', "","","","",{"SA1","SA2","SA3","SA4"}) 
	_lPrepEnv := .T.
EndIf

OpenDic()
conout('campos sa1')
FOR _nX := 1 to len(_aTab)
    (_cAliasSX3)->(DBSEEK(_aTab[_nX]))
    While( (_cAliasSX3)->X3_ARQUIVO = _aTab[_nX] .AND. !_cAliasSX3->(EOF()) )
        aadd(_aCam,(_cAliasSX3)->(X3_CAMPO))
        (_cAliasSX3)->(DBSKIP())
    EndDo
next _nI

return

Static Function OpenDic()
    Local lOpen   := .F.                                             // VALIDAÇÃO DE ABERTURA DE TABELA
    Local cFilter 

    cFilter := _cAliasSX3 + "->" + "X3_ARQUIVO" + " == " + "'DIC'" // FILTRO PARA A TABELA SX3

    // ABERTURA DO DICIONÁRIO SX3
    lOpen := Select(_cAliasSX3) > 0
	iF(!lOpen)
    OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, _cAliasSX3, "SX3", NIL, .F.)
	EndIf
    lOpen := Select(_cAliasSX3) > 0

    // CASO ABERTO FILTRA O ARQUIVO PELO X3_ARQUIVO "DIC",
    // DEFINE COMO TABELA CORRENTE E POSICIONA NO TOPO
    If (lOpen)
        DbSelectArea(_cAliasSX3)
        //DbSetFilter({|| &(cFilter)}, cFilter)
        DbGoTop()
    EndIf
Return (lOpen)



static function formatjson(_ctexto)

_ctexto := STRTRAN(_ctexto,"\","\\")
_ctexto := STRTRAN(STRTRAN(noacento(_ctexto),'"',''),'	','')
_ctexto := STRTRAN(_ctexto,chr(13),'')
_ctexto := STRTRAN(_ctexto,chr(10),'')
_ctexto := REPLACE(_ctexto,CRLF,'')
_ctexto := ALLTRIM(_ctexto)

return _ctexto
