#INCLUDE "rwmake.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na validacao da linha no    !
!                  ! do Contrato de Prestacao de Servicos (TECA250)          !
!                  ! 1. Utilizado para validar informacoes necessarias para  !
!                  !    contratos dos Armazens e Adm de Bens                 !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp              ! Data de Criacao ! 10/2011 !
+------------------+--------------------------------------------------------*/

User Function AT250LOK
	// tipo do contrato
	local _nTipoCont := ParamIxb[1]
	// novos metodos para controle de modelo de cadastro com MVC
	local _oModelPad  := FwModelActive()
	local _oModelGrid := _oModelPad:GetModel("MdGridIAAN")
	// recria variaveis do browse (modelo antigo)
	local _nLinAtu := _oModelGrid:nLine

	// variavel de retorno
	local _bRet := .T.

	// tipo de servico
	local _cTpSrv

	// variaveis para uso na funcao
	local _cCodProd  := _oModelGrid:GetValue('AAN_CODPRO', _nLinAtu)
	local _nQuant    := _oModelGrid:GetValue('AAN_QUANT' , _nLinAtu)
	local _cTpArmaz  := _oModelGrid:GetValue('AAN_TIPOAR', _nLinAtu)
	local _cCodPraca := _oModelGrid:GetValue('AAN_PRACA' , _nLinAtu)
	local _cTabPreco := _oModelGrid:GetValue('AAN_TABELA', _nLinAtu)

	// nao executa para a 03-Transportes
	If (cEmpAnt $ "03") .or. (_nTipoCont > 1)
		Return(_bRet)
	EndIf

	// posiciona no cadastro do produto
	dbSelectArea("SB1")
	SB1->(dbSetOrder(1))
	SB1->(dbSeek(xFilial( "SB1" ) + _cCodProd))
	// tipo do servico
	_cTpSrv := SB1->B1_TIPOSRV

	// valida se campos estao preenchidos
	If ( ! _oModelGrid:IsDeleted() )
		// 1-Armazenagem de Container e 2-Produto
		If (_cTpSrv == "1") .OR. (_cTpSrv == "2")
			If (_nQuant == 0)
				Alert("Obrigatório informar a quantidade de dias que um periodo de armazenagem possui !!")
				_bRet:=.F.
			EndIf
			If (Empty(_cTpArmaz)) .And. (_cTpSrv == "2") .And. (_bRet)
				Alert("Obrigatório informar o tipo de armazenamentode produto que será utilizado para cobrança  !!")
				_bRet:=.F.
			EndIf
		EndIf

		// 3-pacote logistico
		If (_cTpSrv == "3")
			If (Empty(_cCodPraca))
				Alert("Obrigatório informar a praca do Pacote Logístico que será utilizado para cobrança !!")
				_bRet := .F.
			EndIf
		EndIf

		// 4-transf. interna / frete
		If (_cTpSrv == "4")
			If (Empty(_cTabPreco))
				Alert("Obrigatório informar a tabela de preço do frete que será utilizado para cobrança  !!")
				_bRet := .F.
			EndIf
		EndIf

		// 5-seguro
		If (_cTpSrv == "5")
			If (_nQuant == 0)
				Alert("Obrigatório informar o período de cobrança !!")
				_bRet := .F.
			EndIf
		EndIf

	EndIf

Return(_bRet)
