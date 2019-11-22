#include 'totvs.ch'
#include "rwmake.ch"
#INCLUDE "TOPCONN.CH"   

user function altped()

	Private oDlg1
	Private oPanel
	Private oSay
	Private oGet
	Private oButConfirm
	Private oButClose

	_cNomCli     := GetAdvFVal("SA1","A1_NOME",xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,1,"")
	_cCliente    := SC5->C5_CLIENTE + " - " + _cNomCli 
	_nPesoL      := SC5->C5_PESOL   //Str(SC5->C5_PESOL)
	_nPesoB      := SC5->C5_PBRUTO  //Str(SC5->C5_PBRUTO)
	_nVolume     := SC5->C5_VOLUME1 //Str(SC5->C5_VOLUME1)
	_cEspeci1    := SC5->C5_ESPECI1
	_cTransp     := SC5->C5_TRANSP
	_MsgNF       := SC5->C5_MENNOTA
	_NUMPV		 := SC5->C5_NUM
	_cMenPad	 := SC5->C5_MENPAD 
	
	_cFormPag	 := SC5->C5_CONDPAG 
	
	dDtSai		 := SC5->C5_ZDTSAI //stod('')
	
	//_cMenPad2	 := SC5->C5_MENPAD2
	//_cMenPad3	 := SC5->C5_MENPAD3


	@ 0,0 TO 400,700 DIALOG oDlg1 TITLE "Atualizacao de Dados do Pedido de Venda - "+SC5->C5_NUM

	@ 021,010 Say " Pedido de Venda: "
	@ 020,060 Get  _NUMPV     Size 064,050 When .F.
	@ 031,010 Say " Cod. do Cliente: "
	@ 030,060 Get  _cCliente  Size 205,205 When .F.
	@ 051,010 Say " Peso Liquido   : "
	@ 050,060 Get  _nPesoL    Size 050,050 Picture "@E 9999.999"
	@ 061,010 Say " Peso Bruto     : "
	@ 060,060 Get  _nPesoB    Size 050,050 Picture "@E 9999.999"
	@ 071,010 Say " Qtd. de Volumes: "
	@ 070,060 Get  _nVolume   Size 030,050 Picture "@E 9999"
	@ 081,010 Say " Especie        : "
	@ 080,060 Get  _cEspeci1  Size 070,050
	@ 101,010 Say " Transportadora : "
	@ 100,060 Get  _cTransp   Size 030,050 F3 "SA4" Valid Vazio().or.ExistCpo("SA4")
	@ 111,010 Say " Msg. Pad. 1 : "
	@ 110,060 Get  _cMenpad   Size 030,050 F3 "SM4" Valid Vazio().or.ExistCpo("SM4")
	//@ 121,010 Say " Msg. Pad. 2 : "
	//@ 120,060 Get  _cMenpad2  Size 030,050 F3 "SM4" Valid Vazio().or.ExistCpo("SM4")
	//@ 131,010 Say " Msg. Pad. 2 : "
	//@ 130,060 Get  _cMenpad3  Size 030,050 F3 "SM4" Valid Vazio().or.ExistCpo("SM4")
	@ 121,010 Say " Msg na NF Saida: "
	@ 120,060 Get  _MsgNF     Size 205,205    
	
	@ 131,010 Say " Cond Pagamento : "
	@ 130,060 Get  _cFormPag   Size 030,050 F3 "SE4" Valid Vazio().or.ExistCpo("SE4")  
	
	@ 141,010 Say " Dt de Saida   : "
	@ 140,060 Get  dDtSai    Size 070,050 
	
	       

	@ 180,130 BMPBUTTON TYPE 1 ACTION (GRAVA_C5(),Close(Odlg1))
	@ 180,170 BMPBUTTON TYPE 2 ACTION Close(oDlg1)

	ACTIVATE DIALOG oDlg1 CENTERED

return


Static FUNCTION GRAVA_C5()

Reclock("SC5",.F.)
   SC5->C5_PESOL   := _nPesoL  //Val(_nPesoL)
   SC5->C5_PBRUTO  := _nPesoB  //Val(_nPesoB)
   SC5->C5_VOLUME1 := _nVolume //Val(_nVolume)
   SC5->C5_ESPECI1 := _cEspeci1
   SC5->C5_TRANSP  := _cTransp
   SC5->C5_MENNOTA := _MsgNF  
   SC5->C5_MENPAD  := _cMenPad
   
   SC5->C5_CONDPAG  := _cFormPag 
   
   SC5->C5_ZDTSAI  := dDtSai      
   //SC5->C5_MENPAD2 := _cMenPad2
   //SC5->C5_MENPAD3 := _cMenPad3
MsUnlock()

Return