#Include "Totvs.ch"
#INCLUDE "TOPCONN.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Descricao         ! Gatilho para cadastro de produto                        !
+------------------+---------------------------------------------------------+
!Autor             ! TSC149-Percio A. de Oliveira                            !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 12/2010                                                 !
+------------------+--------------------------------------------------------*/

User Function TWMSG001
local _cRet := ""
local _cQry
local _cGrp := M->B1_GRUPO

// servicos prestados
If (Left(M->B1_ZTIPPRO,1) == "S")
	
	_cQry := "SELECT MAX(B1_COD) CODIGO FROM "+RetSqlName("SB1")+" SB1 "
	_cQry += "WHERE "+RetSqlCond("SB1")+" "
	_cQry += "  AND B1_GRUPO = '"+_cGrp+"' "
	// padroniza o codigo de retorno
	_cRet := U_FtQuery(_cQry)
	_cRet := Val(StrTran(_cRet,_cGrp,""))
	_cRet := Iif(_cRet==0,1,_cRet+1)
	_cRet := StrZero(_cRet,3)

// compras/consumo
ElseIf (Left(M->B1_ZTIPPRO,1) == "C")
	
	_cQry := "SELECT MAX(SUBSTRING(B1_COD,5,6)) CODIGO FROM "+RetSqlName("SB1")+" SB1 "
	_cQry += "WHERE "+RetSqlCond("SB1")+" "
	_cQry += "  AND SUBSTRING(B1_COD,1,4) <> 'TECA' "
	_cQry += "  AND B1_ZTIPPRO = 'C' "
	// padroniza o codigo de retorno
	_cRet := U_FtQuery(_cQry)
	_cRet := Val(_cRet)
	_cRet := Iif(_cRet==0,1,_cRet+1)
	_cRet := StrZero(_cRet,6)
	
EndIf

Return(_cRet)
