#Include "RwMake.ch"
#Include "Colors.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina para impressao de etiquetas do WMS               !
!                  ! - Identificacao transportadora/motorista                !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 09/2012 !
+------------------+---------------------------------------------------------+
!Observacoes       !                                                         !
+------------------+--------------------------------------------------------*/

User Function TWMSR009(mvCESV)

Local _cLogoEmp := "\system\logo_tecadi_wms.jpg"
Local _fFont01	:= TFont():New("Arial",,10,,.T.,,,,,.f.)
Local _fFont02	:= TFont():New("Arial",,12,,.T.,,,,,.f.)
Local _fFont03	:= TFont():New("Arial",,18,,.T.,,,,,.f.)

// objeto de impressao
local oEtiq

// conteudo para geracao da etiqueta
local _aTmpConteudo := {}
local _cCodEtiq

// posiciona no registro de movimentacao do veiculo - CESV
dbSelectArea("SZZ")
SZZ->(dbSetOrder(1)) //1-ZZ_FILIAL, ZZ_CESV
If (!SZZ->(dbSeek( xFilial("SZZ")+mvCESV )))
	MsgStop("Movimentação do veículo não encontrada.")
	Return(.f.)
EndIf

//Cria o Objeto da Etiqueta
oEtiq := tMsPrinter():New("WMS - ETIQUETA - TRANSPORTADORA")
oEtiq:Setup()

// nova pagina
oEtiq:StartPage()

// logo da empresa
oEtiq:SayBitmap(0020,0040,_cLogoEmp,425,137)
// data da geracao/impressao da etiqueta
oEtiq:Say(0020,0720,"Dt.Imp.: "+DtoC(Date()),_fFont01,100)
// filial
oEtiq:Say(0070,0720,"Filial: "+AllTrim(SM0->M0_CODFIL)+"-"+AllTrim(SM0->M0_FILIAL),_fFont01,100)
// titulo
oEtiq:Say(0120,0720,"WMS.TRANSPORTADORA",_fFont01,100)
// linha separadora
oEtiq:Line(0160,0040,0160,1100)

// numero CESV
oEtiq:Say(0170,0080,"CESV: "+SZZ->ZZ_CESV,_fFont02,100)
// placa
oEtiq:Say(0170,0400,"Placa: "+Transf(SZZ->ZZ_PLACA1,PesqPict("DA3","DA3_PLACA")),_fFont02,100)
// transportadora
oEtiq:Say(0220,0080,"Transportadora: "+SZZ->ZZ_TRANSP+"-"+AllTrim(Posicione("SA4",1, xFilial("SA4")+SZZ->ZZ_TRANSP ,"A4_NOME" )),_fFont02,100)
// motorista
oEtiq:Say(0270,0080,"Motorista: "+SZZ->ZZ_MOTORIS+"-"+AllTrim(Posicione("DA4",1, xFilial("DA4")+SZZ->ZZ_MOTORIS ,"DA4_NOME" )),_fFont02,100)

// conteudo passado como parametro
_aTmpConteudo := {SZZ->ZZ_CESV,SZZ->ZZ_TRANSP,SZZ->ZZ_MOTORIS,SZZ->ZZ_PLACA1,SZZ->ZZ_PLACA2}

// gera codigo da etiqueta
_cCodEtiq := U_FtGrvEtq("06",_aTmpConteudo)

//Impressao do Codigo de Barras
MsBar3("CODE128",2.8,0.5,_cCodEtiq,oEtiq,.F.,NIL,.T.,0.060,1.5,.f.,NIL,'B',.F.)
oEtiq:Say(0540,0600,Transf(_cCodEtiq,"@R 99999-99999"),_fFont03,100,,,2)

oEtiq:EndPage()


oEtiq:Preview()
//oEtiq:Print()
oEtiq:End()

Return