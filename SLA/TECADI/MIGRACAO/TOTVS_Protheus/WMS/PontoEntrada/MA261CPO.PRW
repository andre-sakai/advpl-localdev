#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada localizado na abertura da tela de      !
!                  ! transferencia de mercadorias (mod 2 MATA261)            !
!                  ! OBS: UTILIZAR EM CONJUNTO COM O PE MA261D3, MA261IN     !
!                  ! 1. Incluir campos customizados no browse                !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo Schepp                                          !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 02/2013                                                 !
+------------------+--------------------------------------------------------*/

User Function MA261CPO
// lista dos campos customizados
local _aTmpCampos := {"D3_ZNUMOS","D3_ZSEQOS","D3_ZETQPLT","D3_ZCARGA","D3_ZPEDIDO","D3_ZITPEDI"}
// variavel temporaria
local _nTmpCmp
// varre todos os campos customizados
For _nTmpCmp := 1 to Len(_aTmpCampos)

	// adiciona o campo no header
	aAdd(aHeader, {GetSx3Cache(_aTmpCampos[_nTmpCmp],"X3_TITULO"),;
	GetSx3Cache(_aTmpCampos[_nTmpCmp],"X3_CAMPO"),;
	GetSx3Cache(_aTmpCampos[_nTmpCmp],"X3_PICTURE"),;
	GetSx3Cache(_aTmpCampos[_nTmpCmp],"X3_TAMANHO"),;
	GetSx3Cache(_aTmpCampos[_nTmpCmp],"X3_DECIMAL"),;
	GetSx3Cache(_aTmpCampos[_nTmpCmp],"X3_VALID"),;
	GetSx3Cache(_aTmpCampos[_nTmpCmp],"X3_USADO"),;
	GetSx3Cache(_aTmpCampos[_nTmpCmp],"X3_TIPO"),;
	GetSx3Cache(_aTmpCampos[_nTmpCmp],"X3_ARQUIVO"),;
	''})
	
Next _nTmpCmp

Return
