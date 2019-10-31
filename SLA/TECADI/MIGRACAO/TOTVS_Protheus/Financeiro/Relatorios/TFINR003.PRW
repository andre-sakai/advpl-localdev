#include "totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Impressao de recibos                                    !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 09/2012 !
+------------------+---------------------------------------------------------+
!Observacoes       !                                                         !
+------------------+--------------------------------------------------------*/

User Function TFINR003(mvValor,mvHistor,mvBanco,mvCheque,mvBenef)
local _aPerg := {}
local _cPerg := PadR("TFINR003",Len(SX1->X1_GRUPO))

private _nNumVias := 0

// define o grupo de perguntas
aAdd(_aPerg,{"Quant. Vias" ,"N",1,0,"G",,""}) //mv_par01

// cria grupo de perguntas
U_FtCriaSX1(_cPerg,_aPerg)

If ! Pergunte(_cPerg,.T.)
	Return ()
EndIf

// define variaveis
_nNumVias := mv_par01

// impressao do recibo
sfImpRecibo(mvValor,mvHistor,mvBanco,mvCheque,mvBenef)

Return(.t.)

//** funcao responsavel pela impressao do recibo
Static Function sfImpRecibo(mvValor,mvHistor,mvBanco,mvCheque,mvBenef)
// area inicial
local _aAreaSA6 := SA6->(GetArea())

local _nVia
local _nLin
local _cValor := Extenso(Round(mvValor,2),.F.)
local _cTextoCom := ""
local _aTextoCom := {}
local _nLinTxt
local _cDscBanco := Posicione("SA6",1, xFilial("SA6")+mvBanco ,"A6_NREDUZ")
// Cria Objeto para impressao Grafica
Private _oPrn := TMSPrinter():New("Impressão de Recibo")
// fontes utilizadas
Private _oFont01n := TFontEx():New(_oPrn,"Tahoma",18,18,.T.,.F.,.F.)// bold / italic / under
Private _oFont02n := TFontEx():New(_oPrn,"Tahoma",14,14,.T.,.F.,.F.)// bold / italic / under
Private _oFont03  := TFontEx():New(_oPrn,"Tahoma",12,12,.F.,.F.,.F.)// bold / italic / under
Private _oFont04  := TFontEx():New(_oPrn,"Tahoma",10,10,.F.,.F.,.F.)// bold / italic / under
// imagem da logo
Private _cImagem := "\"+AllTrim(CurDir())+"\logo_tecadi.jpg"

// apresenta tela para alterar o beneficiario impresso no recibo
_oDlgDetAdic := MSDialog():New(000,000,080,360,"Detalhes Adicionais",,,.F.,,,,,,.T.,,,.T. )
_oSayBenef   := TSay():New( 004,004,{||"Beneficiário:"},_oDlgDetAdic,,,.F.,.F.,.F.,.T.,,,032,008)
_oGetBenef   := TGet():New( 012,004,{|u| If(PCount()>0,mvBenef:=u,mvBenef)},_oDlgDetAdic,176,008,'@!',,,,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","mvBenef",,)
_oBtnConf    := SButton():New( 024,152,1,{|| _oDlgDetAdic:End() },_oDlgDetAdic,,"", )

_oDlgDetAdic:Activate(,,,.T.)


// define como retrato
_oPrn:SetPortrait()
// chama a rotina de Configuracao da impressao
_oPrn:Setup()
// define como retrato
_oPrn:SetPortrait()


For _nVia := 1 to _nNumVias
	
	// cria nova Pagina
	_oPrn:StartPage()
	// reinicia linha
	_nLin := 100
	
	// data e hora de impressao
	_oPrn:Say(_nLin,2300,"Dt Impr: "+DtoC(Date())+" "+Time(),_oFont04:oFont,,,,1)
	_nLin += 100
	
	// logo
	_oPrn:SayBitmap(_nLin,0840,_cImagem,691.6,222.3)
	_nLin += 600
	
	// titulo
	_oPrn:Say(_nLin,1150,"R E C I B O",_oFont01n:oFont,,,,2)
	_nLin += 300
	
	// define o texto completo
	_cTextoCom := "Recebi da empresa "+AllTrim(Upper(SM0->M0_NOMECOM))+", a quantia de "
	_cTextoCom += "R$ "+AllTrim(Transf(mvValor,PesqPict("SE1","E1_VALOR")))
	_cTextoCom += " ("+_cValor+") "
	_cTextoCom += "referente pagamento "
	_cTextoCom += mvHistor
	
	// realiza a quebra de linhas
	_aTextoCom := QbTexto(_cTextoCom,65," ")
	
	For _nLinTxt := 1 to Len(_aTextoCom)
		// texto do recibo
		_oPrn:Say(_nLin,0300,_aTextoCom[_nLinTxt],_oFont02n:oFont)
		_nLin += 60
	Next _nLinTxt
	
	
	// cheques
	If (!Empty(mvCheque))
		_nLin += 60
		_oPrn:Say(_nLin,0300,"Cheque nr "+AllTrim(mvCheque)+" - "+AllTrim(_cDscBanco),_oFont02n:oFont)
		_nLin += 120
	EndIf
	
	// data
	_oPrn:Say(_nLin,2300,AllTrim(SM0->M0_CIDCOB)+", "+AllTrim(Str(Day(dDataBase)))+" de "+MesExtenso(dDataBase)+" de "+StrZero(Year(dDataBase),4),_oFont03:oFont,,,,1)
	_nLin += 500
	
	// assinatura
	_oPrn:Line(_nLin,1000,_nLin,2000)
	_nLin += 20
	_oPrn:Say(_nLin,1500,AllTrim(mvBenef),_oFont03:oFont,,,,2)
	
	// finaliza pagina
	_oPrn:EndPage()

Next _nVia

// preview
_oPrn:Preview()

// restaura area inicial
RestArea(_aAreaSA6)

Return(.t.)