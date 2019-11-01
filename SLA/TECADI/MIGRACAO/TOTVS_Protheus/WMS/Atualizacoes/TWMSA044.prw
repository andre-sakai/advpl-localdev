#Include 'Protheus.ch'
#Include 'TopConn.ch'

//--------------------------------------------------------------------------//
// Programa: TWMSA044()  |  Autor: Gustavo Schumann / SLA | Data: 19/07/2018//
//--------------------------------------------------------------------------//
// Descrição: EDI cliente Julio Andó.										//
//--------------------------------------------------------------------------//

User Function TWMSA044()
Local oFont12n:= TFont():New('Arial',,-12,,.T.)
Local oFont12 := TFont():New('Arial',,-12,,.F.)
Private cPerg := "TWMSA044"
Private lCheck:= .F.

ValidPerg()

//=============================================================================================
oDlg	:= MSDialog():new(75,30,230,500,"EDI cliente",,,,,CLR_BLACK,CLR_WHITE,,,.t.)

oSay	:= TSay():New(015,012,{||'EDI pedido de venda gerado em TXT.'},oDlg,,oFont12n,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)
oCheck	:= TCheckBox():New(030,012,'Fazer upload para o FTP',{||lCheck},oDlg,100,210,,{|| lCheck := .T. },oFont12,,,,,.T.,,,)

oSBtn	:= SButton():New(060,135,5,{||Pergunte(cPerg,.T.)},oDlg,.T.,,)
oSBtn	:= SButton():New(060,165,1,{||TWMSA044A()},oDlg,.T.,,)
oSBtn	:= SButton():New(060,195,2,{||oDlg:End()},oDlg,.T.,,)

oDlg:Activate()
//=============================================================================================
Return
//-------------------------------------------------------------------------------------------------
Static Function ValidPerg()
Local i	:= 0
Local j	:= 0

_sAlias := Alias()
dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)
aRegs:={}

AADD(aRegs,{cPerg,"01","Numero Pedido ?","","","mv_ch1","C",06,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SC5","","","",""})
AADD(aRegs,{cPerg,"02","Numero Pedido do Cliente ?","","","mv_ch2","C",20,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
For i:=1 to Len(aRegs)
	If !dbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j <= Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next

dbSelectArea(_sAlias)

Return
//-------------------------------------------------------------------------------------------------
Static Function TWMSA044A()
Local cString := ""
Local cNomeArq:= ""
Local cTime := ""
Local cTargetDir := ""

If Select("tSC5") > 0
	DBSelectArea("tSC5")
	tSC5->(DBCloseArea())
EndIf

cQuery := ""
cQuery += " SELECT C5_FILIAL,C5_NUM,C5_CLIENTE,C5_LOJACLI,C5_ZPEDCLI,C6_PRODUTO,C6_UM,C6_QTDVEN,C5_VOLUME1 "
cQuery += " 	FROM "+RetSQLName("SC5")+" SC5 "
cQuery += " 	inner join "+RetSQLName("SC6")+" SC6 "
cQuery += " 	on SC6.D_E_L_E_T_ = '' "
cQuery += " 	and C6_FILIAL = C5_FILIAL "
cQuery += " 	and C6_NUM = C5_NUM "
cQuery += " where SC5.D_E_L_E_T_ = '' "
cQuery += " and C5_FILIAL = '"+xFilial("SC5")+"' "

If !EMPTY(MV_PAR01) .Or. !EMPTY(MV_PAR02)
	If !EMPTY(MV_PAR01) .And. EMPTY(MV_PAR02)
		cQuery += " and C5_NUM = '"+MV_PAR01+"' "
	Elseif !EMPTY(MV_PAR02) .And. EMPTY(MV_PAR01)
		cQuery += " and C5_ZPEDCLI = '"+MV_PAR02+"' "
	Else
		cQuery += " and C5_NUM = '"+MV_PAR01+"' and C5_ZPEDCLI = '"+MV_PAR02+"' "
	EndIf
Else
	MsgAlert("Atenção! Um dos parâmetros devem estar preenchido!","TWMSA044")
	Return ( .F. )
EndIf

TCQuery cQuery NEW ALIAS "tSC5"

DBSelectArea("tSC5")
tSC5->(DBGoTop())

cTime := StrTran(Time(),':','')

cNomeArq := AllTrim(tSC5->C5_FILIAL)+AllTrim(tSC5->C5_NUM)+AllTrim(tSC5->C5_ZPEDCLI)+cTime+".txt"

if !tSC5->(EOF())
	While !tSC5->(EOF())
		
		cCodProd := AllTrim(Posicione("SB1",1,xFilial("SB1")+tSC5->C6_PRODUTO,"B1_CODCLI"))
		cQtdVenda := AllTrim(Transform(tSC5->C6_QTDVEN,"@E 99999999999999999.999"))
		
		cString += AllTrim(tSC5->C5_ZPEDCLI)+";;"+cCodProd+";"+tSC5->C6_UM+";"+cQtdVenda+";;"+AllTrim(Str(tSC5->C5_VOLUME1))+CRLF
		
		tSC5->(DBSkip())
	EndDo
Else
	MsgAlert("Nenhum dado para os parâmetros informados!","TWMSA044")
EndIf

If !EMPTY(cString)
	cTargetDir:= cGetFile( '*.txt|*.txt' , 'EDI Pedido de venda', 1, 'C:\', .F., nOR(GETF_LOCALHARD, GETF_RETDIRECTORY),.F., .T. )
	If !EMPTY(cTargetDir)
		memowrite(cTargetDir+cNomeArq,cString)
		
		MsgAlert("Arquivo salvo em: "+cTargetDir+cNomeArq,"TWMSA044")
		
		If lCheck
			
			If U_FTPSend('10.3.0.211',21, 'julioando', 'vI8lbeRaza', '/EDI/', cTargetDir+cNomeArq,.T.)
				MsgAlert("Arquivo enviado para o FTP com sucesso! /EDI/"+cNomeArq,"TWMSA044")
			Else
				MsgAlert("Não foi possível enviar o arquivo para o FTP!","TWMSA044")
			EndIF
			
		EndIf
	
	EndIf
EndIf

tSC5->(DBCloseArea())

Return