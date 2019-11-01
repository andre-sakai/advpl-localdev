#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela de      !
!                  ! transferencia de mercadorias (mod 2 MATA261)            !
!                  ! OBS: UTILIZAR EM CONJUNTO COM O PE MA261CPO, MA261D3    !
!                  ! 1. Incluir campos customizados no browse                !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 02/2013                                                 !
+------------------+--------------------------------------------------------*/

User Function MA261IN
// area inicial
local _aArea := GetArea()
local _aAreaIni := SaveOrd({"SD3"})
// linha atual do aCols
local _nLinAtu := Len(aCols)
// recno do SD3
local _nRecnoSD3 := If((_nLinAtu==0).or.(Empty(aCols[_nLinAtu][Len(aHeader)])),0,aCols[_nLinAtu][Len(aHeader)])
// posicao dos campos customizados no browse
local _nPosNumOs := aScan(aHeader,{|x| UPPER(Alltrim(x[2])) == "D3_ZNUMOS"})
local _nPosSeqOs := aScan(aHeader,{|x| UPPER(Alltrim(x[2])) == "D3_ZSEQOS"})
local _nPosEtqPl := aScan(aHeader,{|x| UPPER(Alltrim(x[2])) == "D3_ZETQPLT"})
local _nPosCarga := aScan(aHeader,{|x| UPPER(Alltrim(x[2])) == "D3_ZCARGA"})
local _nPosPedid := aScan(aHeader,{|x| UPPER(Alltrim(x[2])) == "D3_ZPEDIDO"})
local _nPosItPed := aScan(aHeader,{|x| UPPER(Alltrim(x[2])) == "D3_ZITPEDI"})

// valida se ha dados validos no aCols
If (_nRecnoSD3==0)
	Return
EndIf

// posiciona no registro
dbSelectArea("SD3")
SD3->(dbGoTo(_nRecnoSD3))

If (_nPosNumOs > 0)
	aCols[_nLinAtu][_nPosNumOs] := SD3->D3_ZNUMOS
EndIf
If (_nPosSeqOs > 0)
	aCols[_nLinAtu][_nPosSeqOs] := SD3->D3_ZSEQOS
EndIf
If (_nPosEtqPl > 0)
	aCols[_nLinAtu][_nPosEtqPl] := SD3->D3_ZETQPLT
EndIf
If (_nPosCarga > 0)
	aCols[_nLinAtu][_nPosCarga] := SD3->D3_ZCARGA
EndIf
If (_nPosPedid > 0)
	aCols[_nLinAtu][_nPosPedid] := SD3->D3_ZPEDIDO
EndIf
If (_nPosItPed > 0)
	aCols[_nLinAtu][_nPosItPed] := SD3->D3_ZITPEDI
EndIf

// restaura areas iniciais
RestOrd(_aAreaIni,.t.)
RestArea(_aArea)

Return
