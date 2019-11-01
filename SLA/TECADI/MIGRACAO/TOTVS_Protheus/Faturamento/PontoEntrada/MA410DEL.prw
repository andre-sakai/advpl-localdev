// #########################################################################################
// Projeto:
// Modulo :
// Fonte  : MA410DEL
// ---------+-------------------+-----------------------------------------------------------
// Data     | Autor Eliane Shoda       | P.E. na exclusao do pedido, antes de excluir a SC5
// ---------+-------------------+-----------------------------------------------------------
// 07/10/15 | TOTVS | Developer Studio | Gerado pelo Assistente de Código
// ---------+-------------------+-----------------------------------------------------------

#include "rwmake.ch"


User function MA410DEL
	
	local _aAreaAtu := GetArea()
	local _cQry				:= ""
	local _aAreaSC6 := SC6->(GetArea())

	// utilizado para excluir lotes selecionados para os itens com rastro
	_cQry:= " SELECT Z45.R_E_C_N_O_ Z45RECNO "
	_cQry+= " FROM "+RetSqlTab("Z45")
	_cQry+= " WHERE Z45_FILIAL='"+xFilial("Z45")+"'"
	_cQry+= " AND Z45_PEDIDO='"+SC5->C5_NUM+"' "
	_cQry+= " AND Z45.D_E_L_E_T_ = ' ' "

	_cQry:= ChangeQuery(_cQry)

	if Select("_QRYZ45")<>0
		_QRYZ45->(DbCloseArea())
	Endif

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,_cQry),"_QRYZ45",.T.,.T.)

	_QRYZ45->(dbGoTop())
	
	While _QRYZ45->(!eof())
		Z45->(dbGoto(_QRYZ45->Z45RECNO))
		recLock("Z45",.F.)
		Z45->(dbDelete())
		msUnlock()
		_QRYZ45->(dbSkip())
	EndDo
	
	_QRYZ45->(dbCloseArea())


	// quando for saída de produtos
	If ( SC5->C5_TIPO == "N" ) .AND. ( SC5->C5_TIPOOPE == "P" )

		// se este pedido é um TFAA e está sendo excluido, então deve também tratar o saldo que seria devolvido (em DEVMERCCLI) para a SDA novamente
		_cQryZ05 := "SELECT Z05_NUMOS FROM " + RetSqlTab("Z05") + " WHERE " + RetSqlCond("Z05") + " AND Z05_PVTFAA = '" + SC5->C5_NUM + "' "

		_cOSTfaa := U_FTQuery(_cQryZ05)

		If ( !Empty( _cOSTfaa ) )      //encontrou OS relacionada
			//chama rotina de estorno de TFAA
			If ( !U_TFATA003(_cOSTfaa) )
				MsgAlert("Erro na exclusão do TFAA do pedido de venda " + SC5->C5_NUM + ". Processo abortado.", "MA410DEL")
				Return ( .F. )
			EndIf
		EndIf

	EndIF

	RestArea(_aAreaSC6)
	RestArea(_aAreaAtu)

return ( .T. )
