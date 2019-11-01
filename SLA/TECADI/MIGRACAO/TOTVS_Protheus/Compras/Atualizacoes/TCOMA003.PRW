#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Validacao e Filtragem para Centro de custo e item       !
!                  ! contabil por usuario.                                   !
+------------------+---------------------------------------------------------+
!Autor             ! Odair                                                   !
+------------------+---------------------------------------------------------+
!Retorno           ! .T. / .F.                                               !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 10/2013                                                 !
+------------------+--------------------------------------------------------*/

User Function TCOMA003(mvTipoCmp, mvCenCusto, mvItConta, mvTipoVld, mvDatRef, mvCodUser)

	// variavel de retorno
	Local _lRet      := .f.
	// filtro em SQL para filtragem de dados na consulta F3
	Local _cRet      := ""
	// consulta em SQL
	Local _cQryPesCv := ""
	// Array para conter os dados de itens contabeis ou centros de custo para filtragem por usuario
	Local _aColsCpo  := {}
	// Salva estado das tabelas abertas
	Local _aArea     := GetArea()
	// variavel temporaria
	local _nCpo

	// valores padroes
	Default mvCenCusto := CriaVar("CTT_CUSTO",.f.)
	Default mvItConta  := CriaVar("CTD_ITEM",.f.)
	Default mvDatRef   := dDatabase
	Default mvCodUser  := __cUserId

	// Verifica se irá validar o Centro de custo ou o Item contábil
	If (mvTipoCmp == "CC" )//Se for para centro de custo
		_cQryPesCv := "SELECT DISTINCT Z27_CC "
	ElseIf (mvTipoCmp == "IT" ) //Se for para item contabil
		_cQryPesCv := "SELECT DISTINCT Z27_ITEMC "
	EndIf

	// cadastro de alcada
	_cQryPesCv += "FROM "+RetSqlName("Z27")+" Z27 "
	// insere o filtro padrao de filial
	_cQryPesCv += "WHERE "+RetSqlCond("Z27")

	// Verifica o centro de custo
	If ( ! Empty(mvCenCusto) )
		_cQryPesCv += "AND Z27_CC = '"+mvCenCusto+"' "
	EndIf
	// Verifica o item contábil
	If ( ! Empty(mvItConta) )
		_cQryPesCv += "AND Z27_ITEMC = '"+mvItConta+"' "
	EndIf

	// Verifica se registro está ativo
	_cQryPesCv += "AND Z27_MSBLQL <> '1' "
	// Filtra os registro do usuário solicitante
	_cQryPesCv += "AND Z27_PERFIL IN ( SELECT Z26_PERFID FROM "+RetSqlName("Z26")+" Z26 WHERE "+RetSqlCond("Z26")+" AND Z26_CODUSU = '"+mvCodUser+"' AND Z26_CALEND = '"+SubStr(DtoS(mvDatRef),1,4)+"' ) "
	// Verifica o tipo de referência(dia,mes,ano).
	_cQryPesCv += "AND Z27_CALEND = '"+SubStr(DtoS(mvDatRef),1,4)+"' "
	//Filtra do mês
	_cQryPesCv += "AND '"+DtoS(mvDatRef)+"' BETWEEN Z27_DATAIN AND Z27_DATAFM "

	//gravacao da SQL montada no disco
	memowrit("c:\query\TCOMA003.txt",_cQryPesCv)

	//converte a consulta SQL em array
	_aColsCpo := U_SqlToVet(_cQryPesCv)

	// valida se a consulta possui dados
	_lRet := (Len(_aColsCpo) > 0)

	If ( mvTipoVld == "V" ) //No caso de validacao
		if	( !_lRet ) //Caso nao foi localizado nenhum dado relacionado ao usuario na tabela Z22
			if	(mvTipoCmp == "IT" ) //Se veio do campo item contabil
				Aviso("Tecadi: TCOMA003","Este Item contábil não está liberado para seu usuário. Verifique!",{"OK"})
			ElseIf (mvTipoCmp == "CC" )//Se veio do centro de custo
				Aviso("Tecadi: TCOMA003","Este Centro de Custo não está liberado para seu usuário. Verifique!",{"OK"})
			EndIf
		EndIf

	ElseIf ( mvTipoVld == "C" ) //Caso seja para efetuar a filtragem na consulta F3
		for _nCpo := 1 to Len(_aColsCpo) //Laco para montagem da string a ser usada na SQL de retorno
			IF ( Empty(_cRet) ) //se primeiro registro localizado
				_cRet+= _aColsCpo[_nCpo]
			Else
				_cRet+= "|"+_aColsCpo[_nCpo] //Delimitador mais variavel no caso de mais de um registro
			EndIf
		Next _nCpo

		if ( mvTipoCmp == "CC" ) //Montagem da sql de retorno para Centro de Custo
			_cRet := "@(CTT_CUSTO IN "+FormatIn(_cRet,"|")+")"
		Elseif ( mvTipoCmp == "IT" ) //Montagem da sql de retorno para Item contabil
			_cRet := "@(CTD_ITEM IN "+FormatIn(_cRet,"|")+")"
		EndIf
	EndIf

	//Restauracao da area das tabelas
	RestArea(_aArea)

	//Retorno logico para validacao ou string em sql para filtragem da consulta F3(sxb).
Return( IIf(mvTipoVld == "V", _lRet, _cRet) )