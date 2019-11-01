#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada após a gravação de todos os arquivos na!
!                  ! Distribuição do Produto, este Ponto de Entrada pode ser !
!                  ! utilizado para gravar arquivos ou campos do usuário,    !
!                  ! complementando a inclusão.                              !
+------------------+---------------------------------------------------------+
!Retorno           ! Nil(nulo)                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Felipe José Limas                                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 08/2015                                                 !
+------------------+--------------------------------------------------------*/

User Function MTA265I()

	// posicao da linha no acols
	Local _nLinha := ParamIxb[1]

	// variaveis para uso na rotina automatica
	Local _aAutoCab   := {}
	Local _aAutoItens := {}

	// posicao dos campos no cabeçalho
	Local _nQuant    := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="DB_QUANT"  })
	Local _nQuantS   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="DB_QTSEGUM"})
	Local _nLotectl  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="DB_LOTECTL"})
	Local _nNumlote  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="DB_NUMLOTE"})
	Local _nNumSeri  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="DB_NUMSERI"})
	Local _nLocaliz  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="DB_LOCALIZ"})
	Local _nSerie    := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="DB_SERIE"  })
	Local _nLoteNov  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="DB_ZLOTECT"})
	local _nVldLotNv := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="DB_ZVLDLOT"})
	local _nP_NumOs  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="DB_ZNUMOS" })
	local _nP_SeqOs  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="DB_ZSEQOS" })
	local _nP_IdPlt  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="DB_ZPALLET"})

	// Variavel pera verificar se o Produto tem controle de Lote
	Local _lRastro := Rastro(SDA->DA_PRODUTO)

	// variável de controle para verificar se o lote foi modificado posteriormente ao lote gerado automático pelo sistema
	// acontece em casos de dar entrada em produto com lote, sem saber qual é, e depois, com coletor, substituir pelo lote bipado
	local _lLoteDif := aCols[_nLinha][_nLoteNov] != SDB->DB_LOTECTL
	
	// variaveis para uso na rotina automatica
	Private lMsErroAuto := .F.
	
	// Se o produto ter controle de lote e o campo Lote for diferente de Branco
	// Faz a desmontagem do Produto com o lote real informado.
	// Se não contemplar a logica sera feito o processo padrão do Protheus utilizando o lote gerado pelo sistema.
	If (_lRastro) .AND. ( ! Empty(aCols[_nLinha][_nLoteNov]) ) .AND. _lLoteDif

		dbSelectArea("SB8")
		SB8->(dbGoTop())
		SB8->(dbSetOrder(3))//B8_FILIAL+B8_PRODUTO+B8_LOCAL+B8_LOTECTL+B8_NUMLOTE+DTOS(B8_DTVALID)
		SB8->(dbSeek(xFilial("SB8") + SDA->DA_PRODUTO + SDA->DA_LOCAL + SDA->DA_LOTECTL + SDA->DA_NUMLOTE ))

		_aAutoCab := {{"cProduto" , SDA->DA_PRODUTO  , Nil},;
			{"cLocOrig"   , SDA->DA_LOCAL	         , Nil},;
			{"nQtdOrig"   , aCols[_nLinha][_nQuant]  , Nil},;
			{"nQtdOrigSe" , aCols[_nLinha][_nQuantS] , Nil},;
			{"cDocumento" , SDA->DA_DOC              , Nil},;
			{"cNumLote"   , SDA->DA_NUMLOTE		     , Nil},;
			{"cLoteDigi"  , SDA->DA_LOTECTL		     , Nil},;
			{"dDtValid"   , SB8->B8_DTVALID		     , Nil},;
			{"nPotencia"  , SB8->B8_POTENCI		     , Nil},;
			{"cLocaliza"  , aCols[_nLinha][_nLocaliz], Nil},;
			{"cNumSerie"  , aCols[_nLinha][_nNumSeri], Nil} }

		aAdd(_aAutoItens,{{"D3_COD" ,SDA->DA_PRODUTO   ,NIL},;
			{"D3_LOCAL"	  , SDA->DA_LOCAL              ,NIL},;
			{"D3_QUANT"	  , aCols[_nLinha][_nQuant]    ,NIL},;
			{"D3_QTSEGUM" , aCols[_nLinha][_nQuantS]   ,NIL},;
			{"D3_RATEIO"  , 100                        ,NIL},;
			{"D3_NUMLOTE" , SDA->DA_NUMLOTE            ,NIL},;
			{"D3_DTVALID" , aCols[_nLinha][_nVldLotNv] ,NIL},;
			{"D3_LOTECTL" , aCols[_nLinha][_nLoteNov]  ,NIL},;
			{"D3_LOCALIZ" , aCols[_nLinha][_nLocaliz]  ,NIL},;
			{"D3_ZNUMOS"  , aCols[_nLinha][_nP_NumOs]  ,NIL},;
			{"D3_ZSEQOS"  , aCols[_nLinha][_nP_SeqOs]  ,NIL},;
			{"D3_ZETQPLT" , aCols[_nLinha][_nP_IdPlt]  ,NIL},;
			{"D3_ZORIGNS" , SDA->DA_NUMSEQ             ,NIL},;
			{"D3_ZSERIE"  , SDA->DA_SERIE              ,NIL}})

  		//Ordenar o vetor conforme o dicionário para uso de rotinas via MSExecAuto.
		_aAutoItens := FWVetByDic(_aAutoItens,'SD3',.T.)

		//Chama Rotina Automática de Desmontagem de Produtos
		MSExecAuto({|v,x,y,z| Mata242(v,x,y,z)},_aAutoCab,_aAutoItens,3,.T.) // 3-Inclusao

		If lMsErroAuto
			//Mostraerro()
		Else
			//U_FtWmsMsg("Mata242 - OK.","ATENCAO")
		EndIf

	EndIf

Return