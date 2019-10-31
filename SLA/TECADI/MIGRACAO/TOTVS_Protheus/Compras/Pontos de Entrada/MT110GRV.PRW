#Include "RwMake.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! PE após a gravação da solicitação de compras            !
!                  ! 1. utilizada para enviar e-mail                         !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2012                                                 !
+------------------+--------------------------------------------------------*/

User Function MT110GRV
// area atual
local _aAreaAtu := GetArea()
local _aAreaIni := SaveOrd({"SY1"})
// posicao dos campos
local _nPosItem := aScan(aHeader,{|x| alltrim(x[2]) == 'C1_ITEM'})
// destinatarios
local _cDestin := ""

// testa exclusao
If ( ! Inclui).and.( ! Altera)
	Return
EndIf

// compara ao item posicionado para executar apenas uma vez
If (SC1->C1_ITEM == aCols[Len(aCols)][_nPosItem] )
	
	// destinatarios - solicitante
	_cDestin := AllTrim(UsrRetMail(__cUserId))+";"
	
	// solicitacao vai direto para o compras
	dbSelectArea("SY1")
	SY1->(dbGotop())
	While (! SY1->(Eof()))
		If ( ! Empty(SY1->Y1_EMAIL))
			// inclui o e-mail do comprador
			_cDestin += Alltrim(SY1->Y1_EMAIL)+";"
		Endif
		// proximo item
		dbSelectArea("SY1")
		SY1->(dbSkip())
	EndDo
	
	// envio de Email
	U_FtMailSC(SC1->C1_NUM,_cDestin)
	
Endif

// restaura a Area Inicial
RestOrd(_aAreaIni,.t.)
RestArea(_aAreaAtu)

Return
