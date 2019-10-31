#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada Solic.Compras para validação de tudo   !
!                  ! antes da gravação.                                      !
+------------------+---------------------------------------------------------+
!Autor             ! Odair                                                   !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 01/2014                                                 !
+------------------+--------------------------------------------------------*/
//Alterado por Emerson - EAP em 11/2015, para inserir controle de anke de alçada.

User Function MT110TOK
	// variavel de retorno
	Local _lRet := .t.
	//variavel para salvar estado das variáveis de memória
	local _aAreaAtu := GetArea()
	local _aAreaIni := SaveOrd({"SC1"})
	// posicao dos campos
	local _nPosNec  := aScan(aHeader,{|x| alltrim(x[2]) == 'C1_DATPRF'}) //DATA PREVISTA ENTREGA
	local _nPosCC   := aScan(aHeader,{|x| alltrim(x[2]) == 'C1_CC'})
	local _nPosITc  := aScan(aHeader,{|x| alltrim(x[2]) == 'C1_ITEMCTA'})
	local _nPosTOT  := aScan(aHeader,{|x| alltrim(x[2]) == 'C1_ZTOTAL'}) //VLR TOTAL DA SC
	local _nPosALC  := aScan(aHeader,{|x| alltrim(x[2]) == 'C1_ZIDALCA'}) //ALCADA DO USUARIO
	local _nPosDel  := (Len(aHeader) + 1)
	// variaveis temporarias
	local _nPos
	//Saldo Total
	Local _nSaltot := 0
	// Valor  no mes SC7/PC
	Local _nTotApPC := 0
	// Valor no mes SC1/SC
	Local _nTotApsc := 0
	// valor limite aprovação
	Local _nVlrLt  := 0
	// valor Anterior da SC
	Local _nVlrASC  := 0
	//nivel do  usuario
	local _cNivUsCo  := ""

	//Array contendo as informações dos centros de custos  / saldo para serem analisados
	// 1-CC
	// 2-Itemctb
	// 3-Periodo Referencia (ANO + MES)
	// 4-Valor Limite
	// 5-ValorPC
	// 6-ValorSC
	// 7-Total PC/SC Atual
	// 8-ID Alcada Usr Solicitante
	// 9-Cod Usr Solicitante
	local _aCCSld := {}

	//variavel para controle saldo do cc
	local _nPosSCC   := 0
	//variavel Mostra a Tela OU não
	local _lMostra := .F.
	Local _cPcSc :='SC'
	Local _cUser :=__cUserid //usuario para fitros é o mesmo na sc
	Local _cPcScnum := ca110num
	Local _nPosCCSLD:= 0 //controle para saber se já somou a SC
	//Se não for empresa 01, sai da rotina.
	If ( cEmpAnt <> "01" )
		Return ( .t. )
	EndIf

	// testa exclusao
	If ( ! Inclui).and.( ! Altera) .and. (!lCopia)
		Return
	EndIf

	// Efetua a busca pelos itens da Solicitação de compra
	For _nPos := 1 to Len(aCols)

		// valida se a linha esta deletada
		If ( aCols[_nPos][_nPosDel] )
			Loop
		EndIf

		// Data do computador do usuário
		If ( aCols[_nPos][_nPosNec] < Date() )
			Aviso("Tecadi: MT110TOK","A data de necessidade não pode ser menor que a data de emissão da Solicitação de Compra. Reavalie o(s) item(ns) da solicitação de compra.",{"OK"})
			_lRet := .f.
			Exit
		Endif

		// Valida se usuário possui alçada Por Centro de Custo e Item Contabil
		_lRet := U_TCOMA003("IT", aCols[_nPos][_nPosCC], aCols[_nPos][_nPosITc], "V", aCols[_nPos][_nPosNec], Nil)

		// Se retorno falso, não permite incluir solicitacao de compra e sai da rotina.
		If ( !_lRet )
			Exit
		EndIf

	Next _nPos

	//EMERSON - EAP 11/2015
	// Tudo ok, verifico o SALDO de aprovaçao de compras
	If _lRet
		_cNivUsCo 	:= U_FTCOM06A(_cUser) //Verifica o nível do usuário
		// Efetua a busca pelos itens da Solicitação de compra
		For _nPos := 1 to Len(aCols)
			// valida se a linha esta deletada
			If ( aCols[_nPos][_nPosDel] )
				Loop
			EndIf

			//Verifica se já foi analisado o CC se sim somente soma o valor para analise
			// 1-CC
			// 2-Itemctb
			// 3-Periodo Referencia (ANO + MES)
			// 4-Valor Limite
			// 5-ValorPC
			// 6-ValorSC
			// 7-Total PC/SC Atual
			// 8-ID Alcada Usr Solicitante
			// 9-Cod Usr Solicitante
			_nPosCCSLD := aScan(_aCCSld,{|x| alltrim(x[1]+x[2]+x[3]) == alltrim(aCols[_nPos][_nPosCC]+aCols[_nPos][_nPosITc]+Substr(dtos(aCols[_nPos][_nPosNec]),1,6))})
			IF (_nPosCCSLD > 0)
              //soma na analise atual
				_aCCSld[_nPosCCSLD][7] += aCols[_nPos][_nPosTOT]
				Loop
			Endif

			//Limite de aparovacao usuario MES DE REFERENFICA
			_nVlrLt 	:= U_FTCOM08A(_cUser,_cNivUsCo,"L",aCols[_nPos][_nPosCC], aCols[_nPos][_nPosITc], aCols[_nPos][_nPosNec])

			//TOTAL  PC  no MES DE REFERENFICA
			_nTotAPC  	:= U_FTVALPC(aCols[_nPos][_nPosCC], aCols[_nPos][_nPosITc],aCols[_nPos][_nPosNec])

			//TOTAL SC em aberto  MES DE REFERENFICA
			//CC,itewm,Usuario,sc,Dtnecessidade
			_nTotASC	:= U_FTVALSC(aCols[_nPos][_nPosCC], aCols[_nPos][_nPosITc], aCols[_nPos][_nPosAlc],_cPcScnum, aCols[_nPos][_nPosNec])

			//CC,Itemctb,anomes,valorlimite,ValorPC,ValorSC,SCatual
			// estrutura
			// 1-CC
			// 2-Itemctb
			// 3-Periodo Referencia (ANO + MES)
			// 4-Valor Limite
			// 5-ValorPC
			// 6-ValorSC
			// 7-Total PC/SC Atual
			// 8-ID Alcada Usr Solicitante
			// 9-Cod Usr Solicitante
			AADD(_aCCSld,{;
				aCols[_nPos][_nPosCC]    ,;
				aCols[_nPos][_nPosITc]   ,;
				SUBS(dtos(aCols[_nPos][_nPosNec]),1,6),;
				_nVlrLt                  ,;
				_nTotAPC                 ,;
				_nTotASC                 ,;
				aCols[_nPos][_nPosTOT]   ,;
				aCols[_nPos][_nPosAlc]   ,;
				_cUser                   })
		NEXT _nPos

		//apos preparada a analise verifico se o valor do limite da alçada extrapolou e mostro a informaçao para o usuario
		IF len(_aCCSld) > 0
			_aCCSld := aSort(_aCCSld,,,{|x,y| x[1]+x[2] < y[1]+y[2]})
			_lRet := U_FTMORPC(_cPcSc, _aCCSld, _cPcScnum)
		endif
	endif

	// restaura a Area Inicial
	RestOrd(_aAreaIni,.t.)
	RestArea(_aAreaAtu)
Return(_lRet)