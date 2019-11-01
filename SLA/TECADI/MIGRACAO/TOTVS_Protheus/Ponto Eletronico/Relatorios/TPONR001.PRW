#Include 'Protheus.ch'
#Include "RwMake.ch"
#INCLUDE 'TOPCONN.CH'

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Relatorio Espelho Ponto x Banco de Horas                !
+------------------+---------------------------------------------------------+
!Autor             ! Ricardo Mendes (Dataroute)! Data de Criacao   ! 06/2015 !
+------------------+---------------------------------------------------------+
!Observacoes       !                                                         !
+------------------+--------------------------------------------------------*/

#define DMPAPER_A4 9

User function TPONR001

	private _cPerg := "TPONR001"

	//Chama as perguntas
	sfPergunte(_cPerg)

	If Pergunte(_cPerg,.T.)
		oReport := ReportDef()
		oReport:PrintDialog()
	EndIf

Return .T.

Static Function ReportDef()

	Private oReport
	//Montando o objeto oReport
	oReport := TReport():NEW("TPONR001", "Relatório de Espelho de Ponto de Funcionário", _cPerg, {|oReport|PrintReport(oReport)}, "Espelho ponto dos funcionários.")
	oReport:lParamPage := .F. //Nao imprimir a pagina de parametros
	oReport:SetLandscape(.T.) //Imprimir em Paisagem
	oReport:lHeaderVisible	:= .F. // Desabilita a impressao do Cabecalho
	oReport:lFooterVisible	:= .F. // Desabilita a impressao do Rodape
	//oReport:GetOrientation(2) // 1 - Retrato | 2 - Paisagem
	oReport:SetTotalInLine(.F.) // .T. - Linha Totalizadora | .F. - Nao mostrar linha totalizadora
	oReport:nFontBody	:= 8// Define o tamanho da fonte.
	oReport:nLineHeight	:= 40 // Define a altura da linha.
	oReport:CFONTBODY:="Courier New"
	oReport:SetLeftMargin(2)

	_oSec1:= TRSection():new(oReport,"APONTAMENTOS",{""},,,,,,,,,,,.F.)

	TRCELL():NEW(_oSec1,"DATA"  	,,"Data"		,,13	,,,"LEFT"   ,,"LEFT"  ,,,,,,.F.)
	TRCELL():NEW(_oSec1,"1E"  		,,"1E"			,,08	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"1S"  		,,"1S"			,,08	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"2E"  		,,"2E"			,,08	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"2S"  		,,"2S"			,,08	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"3E"  		,,"3E"			,,08	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"3S"  		,,"3S"			,,08	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"4E"  		,,"4E"			,,08	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"4S"  		,,"4S"          ,,08	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"OBS"  		,,"Obs."        ,,20	,,,"LEFT"   ,,"LEFT"  ,,,,,,.F.)
	TRCELL():NEW(_oSec1,"HEXTRA"	,,"Ext.60%"     ,,10	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"HEX100"	,,"Ext.100%"    ,,10	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"ADNOT"  	,,"Ad.Not."     ,,10	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"ATRASO"  	,,"Atrasos"     ,,10	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"FALTA"  	,,"Faltas"		,,10	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"ABONO"  	,,"Abonos"		,,10	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"BHCRE"  	,,"BH-Cred"     ,,10	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"BHDEB"  	,,"BH-Deb"      ,,10	,,,"CENTER" ,,"CENTER",,,,,,.F.)
	TRCELL():NEW(_oSec1,"TOTBH"  	,,"Total"       ,,10	,,,"CENTER" ,,"CENTER",,,,,,.F.)

Return(oReport)

Static Function PrintReport(oReport)

	msAguarde({|| sfMonta()},"Aguarde...pesquisando...")

Return oReport

// funcao para buscar marcacoes e imprimir
Static Function sfMonta

	local _cQry	:= ""
	local _cSitua	:= ""
	local _nX		:= 0
	local _cCateg := ""
	local _cArqTmp:= GetNextAlias()

	local _cMvPon	:= Alltrim(GETMV("MV_PONMES"))
	local _aPeriodo	:= Separa(_cMvPon,"/")

	local _nSaldo:=0

	Private _oSec1	:= oReport:Section(1)
	Private _aImp		:= {}

	private _nAntBHDe	:= 0
	private _nAntBHCr	:= 0
	private _nMesBHDe	:= 0
	private _nMesBHCr	:= 0

	private _aVisColu	:= {}
	private _aTotColu	:= {}

	// remove os asteriscos
	_cSitua := StrTran(mv_par11,"*","")
	// formata como IN de SQL
	_cSitua := FormatIn(_cSitua,,1)

	// remove os asteriscos
	_cCateg := StrTran(mv_par12,"*","")
	// formata como IN de SQL
	_cCateg := FormatIn(_cCateg,,1)

	_cQry := " SELECT SRA.R_E_C_N_O_ SRARECNO "
	_cQry += " FROM "+RetSqlTab("SRA")+" (NOLOCK) "
	_cQry += " WHERE SRA.D_E_L_E_T_ = ' ' "
	_cQry += " AND RA_FILIAL BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' "
	_cQry += " AND RA_MAT BETWEEN '"+mv_par07+"'AND '"+mv_par08+"' "
	_cQry += " AND RA_CC BETWEEN '"+mv_par03+"'AND '"+mv_par04+"' "
	_cQry += " AND RA_TNOTRAB BETWEEN '"+mv_par05+"'AND '"+mv_par06+"' "
	_cQry += " AND RA_NOME BETWEEN '"+mv_par09+"'AND '"+mv_par10+"' "
	_cQry += " AND RA_SITFOLH IN "+_cSitua+" "
	_cQry += " AND RA_CATFUNC IN "+_cCateg+" "
	_cQry += " AND RA_REGRA <> ' ' "
	_cQry += " ORDER BY RA_FILIAL, RA_MAT "

	If Select(_cArqTmp) <> 0
		(_cArqTmp)->(DBCLOSEAREA())
	EndIF

	_cQry := ChangeQuery(_cQry)

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,_cQry),_cArqTmp,.F.,.T.)

	(_cArqTmp)->(dbGoTop())

	while (_cArqTmp)->(!eof())
		SRA->(dbGoto((_cArqTmp)->SRARECNO))

		_nAntBHCr := 0
		_nAntBHDe := 0
		_nMesBHCr := 0
		_nMesBHDe := 0

		// busca apontamentos do funcionario
		sfBuscaAp(@_nAntBHDe,@_nAntBHCr,@_nMesBHDe,@_nMesBHCr)

		if Len(_aImp)==0
			(_cArqTmp)->(dbSkip())
			Loop
		endif

		sfCabec(oReport)

		_oSec1:Init()

		//Ocultar todas as colunas
		IF !_aVisColu[1]
			_oSec1:Cell("1E"):Disable()
		Else
			_oSec1:Cell("1E"):Enable()
		EndIF
		IF !_aVisColu[2]
			_oSec1:Cell("1S"):Disable()
		Else
			_oSec1:Cell("1S"):Enable()
		EndIF
		IF !_aVisColu[3]
			_oSec1:Cell("2E"):Disable()
		Else
			_oSec1:Cell("2E"):Enable()
		EndIF
		IF !_aVisColu[4]
			_oSec1:Cell("2S"):Disable()
		Else
			_oSec1:Cell("2S"):Enable()
		EndIF
		IF !_aVisColu[5]
			_oSec1:Cell("3E"):Disable()
		Else
			_oSec1:Cell("3E"):Enable()
		EndIF
		IF !_aVisColu[6]
			_oSec1:Cell("3S"):Disable()
		Else
			_oSec1:Cell("3S"):Enable()
		EndIF
		IF !_aVisColu[7]
			_oSec1:Cell("4E"):Disable()
		Else
			_oSec1:Cell("4E"):Enable()
		EndIF
		IF !_aVisColu[8]
			_oSec1:Cell("4S"):Disable()
		Else
			_oSec1:Cell("4S"):Enable()
		EndIF

		_nSaldo:=0

		For _nX:=1 to Len(_aImp)
			_oSec1:Cell("DATA"):SetValue(_aImp[_nX,1])
			For _nY:=2 to 18
				if _nY <= 9  // impressao do ponto
					if !Empty(_aImp[_nX,_nY])
						//_cHora := StrTran(StrTran(str(_aImp[_nX,_nY],5,2),".",":")," ","0")
						_cHora := StrTran(str(_aImp[_nX,_nY],5,2),".",":")
						_cHora := IIF(_aImp[_nX,_nY] > 0,_cHora,"")
					else
						_cHora := "-----"
					endif
				elseif _nY > 10  // impressao das marcacoes e banco
					// transforma em centesimal para somar
					_nHora :=fConvHr(_aImp[_nX,_nY],'D')

					if mv_par15==2
						_cHora := Transform(_nHora,"@E 99.99")
						_cHora := IIF(_nHora > 0,_cHora,"-----")
					else
						//_cHora := StrTran(StrTran(str(_aImp[_nX,_nY],5,2),".",":")," ","0")
						_cHora := StrTran(str(_aImp[_nX,_nY],5,2),".",":")
						_cHora := IIF(_aImp[_nX,_nY] > 0,_cHora,"-----")
					endif
				endif

				do Case
					Case _nY==2
					_oSec1:Cell("1E"):SetValue(_cHora)
					Case _nY==3
					_oSec1:Cell("1S"):SetValue(_cHora)
					Case _nY==4
					_oSec1:Cell("2E"):SetValue(_cHora)
					Case _nY==5
					_oSec1:Cell("2S"):SetValue(_cHora)
					Case _nY==6
					_oSec1:Cell("3E"):SetValue(_cHora)
					Case _nY==7
					_oSec1:Cell("3S"):SetValue(_cHora)
					Case _nY==8
					_oSec1:Cell("4E"):SetValue(_cHora)
					Case _nY==9
					_oSec1:Cell("4S"):SetValue(_cHora)
					Case _nY==11
					_oSec1:Cell("HEXTRA"):SetValue(_cHora)
					_nSaldo:=__TimeSum(_nSaldo,_aImp[_nX,11])
					Case _nY==12
					_oSec1:Cell("ADNOT"):SetValue(_cHora)
					Case _nY==13
					_oSec1:Cell("ATRASO"):SetValue(_cHora)
					Case _nY==14
					_oSec1:Cell("FALTA"):SetValue(_cHora)
					Case _nY==15
					_oSec1:Cell("ABONO"):SetValue(_cHora)
					Case _nY==16
					_oSec1:Cell("BHCRE"):SetValue(_cHora)
					_nSaldo:=__TimeSum(_nSaldo,_aImp[_nX,16])
					Case _nY==17
					_oSec1:Cell("BHDEB"):SetValue(_cHora)
					_nSaldo:=__TimeSub(_nSaldo,_aImp[_nX,17])
					Case _nY==18
					_oSec1:Cell("HEX100"):SetValue(_cHora)
					_nSaldo:=__TimeSum(_nSaldo,_aImp[_nX,18])
				endCase
			Next

			_oSec1:Cell("OBS"):SetValue(_aImp[_nX,10])

			if mv_par15==1
					//_cHora := StrTran(StrTran(str(_nSaldo,6,2),".",":")," ","0")
					_cHora := StrTran(str(_nSaldo,6,2),".",":")
					_oSec1:Cell("TOTBH"):SetValue(_cHora)
			else
					_nHora := fConvHr(_nSaldo,'D')
					_oSec1:Cell("TOTBH"):SetValue(Transform(_nHora,"@E 9999.99"))
			endif

			_oSec1:PrintLine()

		Next

		_oSec1:Finish()

		oReport:SkipLine(1)
		oReport:PrintText(repl("-",200),oReport:Row())

		oReport:SkipLine(1)
		oReport:PrintText("Saldo Mês Ant.:",oReport:Row(),_oSec1:Cell('OBS'):ColPos())


		if mv_par15==1  // sexa
			//_cHora := StrTran(StrTran(str(_nAntBHCr,6,2),".",":")," ","0")
			_cHora := StrTran(str(_nAntBHCr,6,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('BHCRE'):ColPos())
			//_cHora := StrTran(StrTran(str(_nAntBHDe,6,2),".",":")," ","0")
			_cHora := StrTran(str(_nAntBHDe,6,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('BHDEB'):ColPos())

			// total BH sexagenal
			_nSaldo:=0
			_nSaldo:=__TimeSum(_nSaldo,_nAntBHCr)
			_nSaldo:=__TimeSub(_nSaldo,_nAntBHDe)

			//_cHora := StrTran(StrTran(str(_nSaldo,6,2),".",":")," ","0")
			_cHora := StrTran(str(_nAntBHDe,6,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('TOTBH'):ColPos())

		else // centesimal
			_nSaldo:=0
			_nSaldo:=__TimeSum(_nSaldo,_nAntBHCr)
			_nSaldo:=__TimeSub(_nSaldo,_nAntBHDe)

			_nHora := fConvHr(_nAntBHCr,'D')
			oReport:PrintText(Transform(_nHora,"@E 999.99"),oReport:Row(),_oSec1:Cell('BHCRE'):ColPos())

			_nHora := fConvHr(_nAntBHDe,'D')
			oReport:PrintText(Transform(_nHora,"@E 999.99"),oReport:Row(),_oSec1:Cell('BHDEB'):ColPos())

			_nHora := fConvHr(_nSaldo,'D')
			oReport:PrintText(Transform(_nHora,"@E 999.99"),oReport:Row(),_oSec1:Cell('TOTBH'):ColPos())
		endif

		oReport:SkipLine(1)
		oReport:PrintText("Total de Horas Mês:",oReport:Row(),_oSec1:Cell('OBS'):ColPos())

		if mv_par15==1
			_nHora := _aTotColu[1]
			//_cHora := StrTran(StrTran(str(_nHora,5,2),".",":")," ","0")
			_cHora := StrTran(str(_nHora,5,2),".",":")
			_cHora := IIF(_nHora > 0,_cHora,"0:00")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('HEXTRA'):ColPos())

			// inclusao impressao horas extras 100%
			_nHora := _aTotColu[6]
			_cHora := StrTran(str(_nHora,5,2),".",":")
			_cHora := IIF(_nHora > 0,_cHora," 0:00")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('HEX100'):ColPos())

			_nHora := _aTotColu[2]
			//_cHora := StrTran(StrTran(str(_nHora,5,2),".",":")," ","0")
			_cHora := StrTran(str(_nHora,5,2),".",":")
			//_cHora := IIF(_nHora > 0,_cHora," 0:00")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('ADNOT'):ColPos())

			_nHora := _aTotColu[3]
			//_cHora := StrTran(StrTran(str(_nHora,5,2),".",":")," ","0")
			_cHora := StrTran(str(_nHora,5,2),".",":")
			//_cHora := IIF(_nHora > 0,_cHora," 0:00")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('ATRASO'):ColPos())

			_nHora := _aTotColu[4]
			//_cHora := StrTran(StrTran(str(_nHora,5,2),".",":")," ","0")
			_cHora := StrTran(str(_nHora,5,2),".",":")
			//_cHora := IIF(_nHora > 0,_cHora," 0:00")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('FALTA'):ColPos())

			_nHora := _aTotColu[5]
			//_cHora := StrTran(StrTran(str(_nHora,5,2),".",":")," ","0")
			_cHora := StrTran(str(_nHora,5,2),".",":")
			//_cHora := IIF(_nHora > 0,_cHora," 0:00")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('ABONO'):ColPos())

			//_cHora := StrTran(StrTran(str(_nMesBHCr,6,2),".",":")," ","0")
			_cHora := StrTran(str(_nMesBHCr,6,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('BHCRE'):ColPos())

			//_cHora := StrTran(StrTran(str(_nMesBHDe,6,2),".",":")," ","0")
			_cHora := StrTran(str(_nMesBHDe,6,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('BHDEB'):ColPos())

			_nSaldo:=0
			_nSaldo:=__TimeSum(_nSaldo,_aTotColu[1])
			//inclusao soma de horas 100%
			_nSaldo:=__TimeSum(_nSaldo,_aTotColu[6])
			_nSaldo:=__TimeSum(_nSaldo,_nMesBHCr)
			_nSaldo:=__TimeSub(_nSaldo,_nMesBHDe)

			//_cHora := StrTran(StrTran(str(_nSaldo,6,2),".",":")," ","0")
			_cHora := StrTran(str(_nSaldo,6,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('TOTBH'):ColPos())

		else
			_nHora := fConvHr(_aTotColu[1],'D')
			//oReport:PrintText(IIF(_nHora <> 0, Transform(_nHora,"@E 99.99"),"") ,oReport:Row(),_oSec1:Cell('HEXTRA'):ColPos())
			oReport:PrintText(Transform(_nHora,"@E 99.99") ,oReport:Row(),_oSec1:Cell('HEXTRA'):ColPos())
			// incluida impressao horas extras 100%
			_nHora := fConvHr(_aTotColu[6],'D')
			//oReport:PrintText(IIF(_nHora <> 0, Transform(_nHora,"@E 99.99"),"") ,oReport:Row(),_oSec1:Cell('HEX100'):ColPos())
			oReport:PrintText(Transform(_nHora,"@E 99.99") ,oReport:Row(),_oSec1:Cell('HEX100'):ColPos())
			_nHora := fConvHr(_aTotColu[2],'D')
			//oReport:PrintText(IIF(_nHora <> 0, Transform(_nHora,"@E 99.99"),"") ,oReport:Row(),_oSec1:Cell('ADNOT'):ColPos())
			oReport:PrintText(Transform(_nHora,"@E 99.99") ,oReport:Row(),_oSec1:Cell('ADNOT'):ColPos())
			_nHora := fConvHr(_aTotColu[3],'D')
			//oReport:PrintText(IIF(_nHora <> 0, Transform(_nHora,"@E 99.99"),"") ,oReport:Row(),_oSec1:Cell('ATRASO'):ColPos())
			oReport:PrintText(Transform(_nHora,"@E 99.99") ,oReport:Row(),_oSec1:Cell('ATRASO'):ColPos())
			_nHora := fConvHr(_aTotColu[4],'D')
			//oReport:PrintText(IIF(_nHora <> 0, Transform(_nHora,"@E 99.99"),"") ,oReport:Row(),_oSec1:Cell('FALTA'):ColPos())
			oReport:PrintText(Transform(_nHora,"@E 99.99"),oReport:Row(),_oSec1:Cell('FALTA'):ColPos())
			_nHora := fConvHr(_aTotColu[5],'D')
			//oReport:PrintText(IIF(_nHora <> 0, Transform(_nHora,"@E 99.99"),"") ,oReport:Row(),_oSec1:Cell('ABONO'):ColPos())
			oReport:PrintText(Transform(_nHora,"@E 99.99"),oReport:Row(),_oSec1:Cell('ABONO'):ColPos())
			_nHora := fConvHr(_nMesBHCr,'D')
			oReport:PrintText( Transform(_nHora,"@E 999.99"),oReport:Row(),_oSec1:Cell('BHCRE'):ColPos())
			_nHora := fConvHr(_nMesBHDe,'D')
			oReport:PrintText( Transform(_nHora,"@E 999.99"),oReport:Row(),_oSec1:Cell('BHDEB'):ColPos())

			_nSaldo:=0
			_nSaldo:=__TimeSum(_nSaldo,_aTotColu[1])
			//inclusao soma de horas 100%
			_nSaldo:=__TimeSum(_nSaldo,_aTotColu[6])
			_nSaldo:=__TimeSum(_nSaldo,_nMesBHCr)
			_nSaldo:=__TimeSub(_nSaldo,_nMesBHDe)

			_nHora := fConvHr(_nSaldo,'D')
			oReport:PrintText( Transform(_nHora,"@E 999.99"),oReport:Row(),_oSec1:Cell('TOTBH'):ColPos())

		endif

		oReport:SkipLine(1)
		oReport:PrintText("Saldo Total.:",oReport:Row(),_oSec1:Cell('OBS'):ColPos())

		if mv_par15==1
			//_cHora := StrTran(StrTran(str(_aTotColu[1] ,5,2),".",":")," ","0")
			_cHora := StrTran(str(_aTotColu[1] ,5,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('HEXTRA'):ColPos())

			// inclusao impressao total horas extras 100%
			_cHora := StrTran(str(_aTotColu[6] ,5,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('HEX100'):ColPos())

			//_cHora := StrTran(StrTran(str(_aTotColu[2],5,2),".",":")," ","0")
			_cHora := StrTran(str(_aTotColu[2] ,5,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('ADNOT'):ColPos())

			//_cHora := StrTran(StrTran(str(_aTotColu[3]  ,5,2),".",":")," ","0")
			_cHora := StrTran(str(_aTotColu[3] ,5,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('ATRASO'):ColPos())

			//_cHora := StrTran(StrTran(str(_aTotColu[4],5,2),".",":")," ","0")
			_cHora := StrTran(str(_aTotColu[4] ,5,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('FALTA'):ColPos())

			//_cHora := StrTran(StrTran(str(_aTotColu[5]  ,5,2),".",":")," ","0")
			_cHora := StrTran(str(_aTotColu[5] ,5,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('ABONO'):ColPos())

			_nSaldo:=0
			_nSaldo:=__TimeSum(_nSaldo,_nAntBHCr)
			_nSaldo:=__TimeSum(_nSaldo,_nMesBHCr)
			//_cHora := StrTran(StrTran(str(_nSaldo,6,2),".",":")," ","0")
			_cHora := StrTran(str(_nSaldo,6,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('BHCRE'):ColPos())

			_nSaldo:=0
			_nSaldo:=__TimeSub(_nSaldo,_nAntBHDe)
			_nSaldo:=__TimeSub(_nSaldo,_nMesBHDe)
			//_cHora := StrTran(StrTran(str(_nSaldo,6,2),".",":")," ","0")
			_cHora := StrTran(str(_nSaldo,6,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('BHDEB'):ColPos())

			_nSaldo:=0
			_nSaldo:=__TimeSum(_nSaldo,_aTotColu[1])
			//inclusao soma de horas 100%
			_nSaldo:=__TimeSum(_nSaldo,_aTotColu[6])

			_nSaldo:=__TimeSum(_nSaldo,_nAntBHCr)
			_nSaldo:=__TimeSum(_nSaldo,_nMesBHCr)
			_nSaldo:=__TimeSub(_nSaldo,_nAntBHDe)
			_nSaldo:=__TimeSub(_nSaldo,_nMesBHDe)
			//_cHora := StrTran(StrTran(str(_nSaldo,6,2),".",":")," ","0")
			_cHora := StrTran(str(_nSaldo,6,2),".",":")
			oReport:PrintText(_cHora,oReport:Row(),_oSec1:Cell('TOTBH'):ColPos())

		else
			_nHora := fConvHr(_aTotColu[1],'D')
			oReport:PrintText( Transform(_nHora,"@E 99.99") ,oReport:Row(),_oSec1:Cell('HEXTRA'):ColPos())
			// inclusao impressao horas extras 100%
			_nHora := fConvHr(_aTotColu[6],'D')
			oReport:PrintText( Transform(_nHora,"@E 99.99") ,oReport:Row(),_oSec1:Cell('HEX100'):ColPos())

			_nHora := fConvHr(_aTotColu[2],'D')
			oReport:PrintText( Transform(_nHora,"@E 99.99") ,oReport:Row(),_oSec1:Cell('ADNOT'):ColPos())
			_nHora := fConvHr(_aTotColu[3],'D')
			oReport:PrintText( Transform(_nHora,"@E 99.99") ,oReport:Row(),_oSec1:Cell('ATRASO'):ColPos())
			_nHora := fConvHr(_aTotColu[4],'D')
			oReport:PrintText( Transform(_nHora,"@E 99.99") ,oReport:Row(),_oSec1:Cell('FALTA'):ColPos())
			_nHora := fConvHr(_aTotColu[5],'D')
			oReport:PrintText( Transform(_nHora,"@E 99.99") ,oReport:Row(),_oSec1:Cell('ABONO'):ColPos())

			_nSaldo:=0
			_nSaldo:=__TimeSum(_nSaldo,_nAntBHCr)
			_nSaldo:=__TimeSum(_nSaldo,_nMesBHCr)
			oReport:PrintText(Transform(fConvHr(_nSaldo,'D'),"@E 999.99"),oReport:Row(),_oSec1:Cell('BHCRE'):ColPos())

			_nSaldo:=0
			_nSaldo:=__TimeSub(_nSaldo,_nAntBHDe)
			_nSaldo:=__TimeSub(_nSaldo,_nMesBHDe)


			_nHora	:= fConvHr(_nSaldo,'D')

			oReport:PrintText( Transform(_nHora,"@E 999.99"),oReport:Row(),_oSec1:Cell('BHDEB'):ColPos())

			_nSaldo:=0
			_nSaldo:=__TimeSum(_nSaldo,_aTotColu[1])

			// somar horas extras 100%
			_nSaldo:=__TimeSum(_nSaldo,_aTotColu[6])

			_nSaldo:=__TimeSum(_nSaldo,_nAntBHCr)
			_nSaldo:=__TimeSum(_nSaldo,_nMesBHCr)
			_nSaldo:=__TimeSub(_nSaldo,_nAntBHDe)
			_nSaldo:=__TimeSub(_nSaldo,_nMesBHDe)
			oReport:PrintText(Transform(fConvHr(_nSaldo,'D'),"@E 999.99"),oReport:Row(),_oSec1:Cell('TOTBH'):ColPos())

		endif

		oReport:SkipLine(1)
		oReport:PrintText(repl("-",200),oReport:Row())
		oReport:SkipLine(1)
		//Imprimir Rodape
		_cImp:="Reconheço a exatidão das horas constantes de acordo com minha frequência neste intervalo "+DTOC(MV_PAR13)+" a  "+DTOC(MV_PAR14)+". Nos termos da portaria MTB N. 3626 "
		oReport:PrintText(_cImp,oReport:Row())
		oReport:SkipLine(1)
		_cImp:="de 13/11/91 artigo 13, o presente cartão ponto substitui o quadro de horário de trabalho. Inclusive ficha de horário de trabalho externo."
		oReport:PrintText(_cImp,oReport:Row())

		oReport:SkipLine(4)
		oReport:PrintText(space(80)+repl("_",50),oReport:Row())
		oReport:SkipLine(1)
		oReport:PrintText(space(80)+PADR(Alltrim(SRA->RA_Nome),80),oReport:Row())

		oReport:EndPage()

		(_cArqTmp)->(dbSkip())
	enddo

	(_cArqTmp)->(DBCLOSEAREA())

return

Static Function sfCabec(oReport)

	local _aTurno	:= {}
	local _nX		:= 0
	Local _nSeqTur	:= 0
	Private _cComp	:= ""

	oReport:StartPage()
	oReport:SkipLine(1)

	_cImp:=	PADC("CARTÃO PONTO     -------  DE "+DTOC(MV_PAR13)+" ATÉ "+DTOC(MV_PAR14),200)
	oReport:PrintText(_cImp,oReport:Row())
	oReport:SkipLine(1)

	_cImp:=	PADR("Empresa",10,".")+PADR(SM0->M0_NomeCom, 80)+"Horário de Trabalho"
	oReport:PrintText(_cImp,oReport:Row())
	oReport:SkipLine(1)

	_aTurno :=  sfTurno(SRA->RA_TNOTRAB)
	_nSeqTur:= Len(_aTurno)

	_cImp:=	PADR("CNPJ",10,".")+PADR(Transform(SM0->M0_CGC,'@R ##.###.###/####-##'),80)
	_cImp+= IIF(_nSeqTur > 0, "Segunda á Sexta: "+_aTurno[1,2],"")

	oReport:PrintText(_cImp,oReport:Row())
	oReport:SkipLine(1)

	_cImp:=	PADR("Matrícula: "+Alltrim(SRA->RA_MAT)+PADR(" Nome: ",7)+Alltrim(SRA->RA_Nome),90)
	_cImp+= IIF(_nSeqTur > 1, "Sábado: "+_aTurno[2,2],IIF(Empty(_cComp), "",_cComp))
	oReport:PrintText(_cImp,oReport:Row())
	oReport:SkipLine(1)

	_cImp:=	PADR("Data Admissão: "+DTOC(SRA->RA_ADMISSA)+" N.PIS: "+SRA->RA_PIS,80)
	oReport:PrintText(_cImp,oReport:Row())
	oReport:SkipLine(1)

	_cImp	:=	PADR("Função: "+Alltrim(Posicione("SRJ",1,xFilial("SRJ")+SRA->RA_CODFUNC,"RJ_DESC")),80)
	oReport:PrintText(_cImp,oReport:Row())
	oReport:SkipLine(1)

return

// funcao para buscar espelho do ponto x banco de horas
Static Function sfBuscaAp(_nAntBHDe,_nAntBHCr,_nMesBHDe,_nMesBHCr)

	local _cArqApo	:= GetNextAlias()
	local _cArqHrs	:= GetNextAlias()
	local _cArqBH	:= GetNextAlias()

	local _lAfastper:= .F.
	local aAfasta 	:= {}   // variavel passada por referencia na rotina padrao

	local _cQry		:= ""
	local _nPos		:= 0
	local _nX		:= 0
	local _nHoras	:= 0
	local _cData	:= ""
	local _nDebito	:= 0
	local _nCredit	:= 0

	_aImp      		:= {}
	_aVisColu		:= {.F.,.F.,.F.,.F.,.F.,.F.,.F.,.F.}

	// incluida coluna 6=total horas extras 100%
	_aTotColu		:= {0,0,0,0,0,0}

	// periodo fechado
	_cQry := " SELECT PG_DATA P8_DATA, "
	_cQry += " PG_DATAAPO P8_DATAAPO, "
	_cQry += " PG_HORA P8_HORA, "
	_cQry += " PG_TPMARCA P8_TPMARCA, "
	_cQry += " PG_ORDEM P8_ORDEM "
	_cQry += " FROM "+RetSqlTab("SPG")+" (NOLOCK) "
	_cQry += " WHERE SPG.D_E_L_E_T_ = ' ' "
	_cQry += " AND PG_FILIAL = '"+SRA->RA_FILIAL+"' "
	_cQry += " AND PG_MAT = '"+SRA->RA_MAT+"' "
	_cQry += " AND PG_DATAAPO BETWEEN '"+dtos(mv_par13)+"'AND '"+dtos(mv_par14)+"' "
	_cQry += " AND PG_APONTA <> 'N' "

	_cQry += " UNION "

	// periodo aberto
	_cQry += " SELECT P8_DATA, P8_DATAAPO, P8_HORA, P8_TPMARCA, P8_ORDEM "
	_cQry += " FROM "+RetSqlTab("SP8")+" (NOLOCK) "
	_cQry += " WHERE SP8.D_E_L_E_T_ = ' ' "
	_cQry += " AND P8_FILIAL = '"+SRA->RA_FILIAL+"' "
	_cQry += " AND P8_MAT = '"+SRA->RA_MAT+"' "
	_cQry += " AND P8_DATAAPO BETWEEN '"+dtos(mv_par13)+"'AND '"+dtos(mv_par14)+"' "
	_cQry += " AND P8_APONTA <> 'N' "

	If Select(_cArqApo) <> 0
		(_cArqApo)->(DBCLOSEAREA())
	EndIF

	_cQry := ChangeQuery(_cQry)

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,_cQry),_cArqApo,.F.,.T.)

	(_cArqApo)->(dbGoTop())

	// inicializa apontamentos para mostrar todos os dias
	// inclusao da posicao 18=horas extras 100%
	For _nX:=mv_par13 to mv_par14
		aAdd(_aImp, {_nX,"","","","","","","","","",0,0,0,0,0,0,0,0 } )
	Next

	while (_cArqApo)->(!eof())
		_nPos := aScan(_aImp,{|x| Dtos(x[1]) == (_cArqApo)->P8_DATAAPO } )
		do Case
			Case (_cArqApo)->P8_TPMARCA=="1E" .and. Empty(_aImp[_nPos,2])
			_aImp[_nPos,2] := (_cArqApo)->P8_HORA
			_aVisColu[1]:= .T.
			Case (_cArqApo)->P8_TPMARCA=="1S" .and. Empty(_aImp[_nPos,3])
			_aImp[_nPos,3] := (_cArqApo)->P8_HORA
			_aVisColu[2]:= .T.
			Case (_cArqApo)->P8_TPMARCA=="2E" .and. Empty(_aImp[_nPos,4])
			_aImp[_nPos,4] := (_cArqApo)->P8_HORA
			_aVisColu[3]:= .T.
			Case (_cArqApo)->P8_TPMARCA=="2S" .and. Empty(_aImp[_nPos,5])
			_aImp[_nPos,5] := (_cArqApo)->P8_HORA
			_aVisColu[4]:= .T.
			Case (_cArqApo)->P8_TPMARCA=="3E" .and. Empty(_aImp[_nPos,6])
			_aImp[_nPos,6] := (_cArqApo)->P8_HORA
			_aVisColu[5]:= .T.
			Case (_cArqApo)->P8_TPMARCA=="3S" .and. Empty(_aImp[_nPos,7])
			_aImp[_nPos,7] := (_cArqApo)->P8_HORA
			_aVisColu[6]:= .T.
			Case (_cArqApo)->P8_TPMARCA=="4E" .and. Empty(_aImp[_nPos,8])
			_aImp[_nPos,8] := (_cArqApo)->P8_HORA
			_aVisColu[7]:= .T.
			Case (_cArqApo)->P8_TPMARCA=="4S" .and. Empty(_aImp[_nPos,9])
			_aImp[_nPos,9] := (_cArqApo)->P8_HORA
			_aVisColu[8]:= .T.
			otherwise   // nao gravou qual ordem da marcacao ou estÃ¡ repetido porque foi incluido manualmente
			for _nx:=2 to 9
				if empty(_aImp[_nPos,_nX])
					_aImp[_nPos,_nX] := (_cArqApo)->P8_HORA
					_aVisColu[_nX-1]:= .T.
					exit
				endif
			next
		endCase

		(_cArqApo)->(dbSkip())
	enddo

	(_cArqApo)->(DBCLOSEAREA())

	// busca horas extras/adicionais/abonos nas tabelas de marcacoes
	// o evento so ocorre uma vez em cada dia
	_cQry := " SELECT PH_DATA DATA, PH_QTABONO QTABONO, "
	_cQry += " ( CASE WHEN PH_QUANTI > 0 THEN PH_QUANTI ELSE PH_QUANTC END ) QTDHORAS, "
	_cQry += " ( CASE WHEN PH_PDI <> ' ' THEN PH_PDI ELSE PH_PD END ) EVENTO "
	_cQry += " FROM "+RetSqlTab("SPH")+" (NOLOCK) "
	_cQry += " WHERE SPH.D_E_L_E_T_ = ' ' "
	_cQry += " AND PH_FILIAL = '"+SRA->RA_FILIAL+"' "
	_cQry += " AND PH_MAT = '"+SRA->RA_MAT+"' "
	_cQry += " AND PH_DATA BETWEEN '"+dtos(mv_par13)+"'AND '"+dtos(mv_par14)+"' "
	_cQry += " AND ( ( PH_PD IN ('203','204','208','209','222','290','300') AND PH_PDI = ' ' ) "
	_cQry += " 	OR ( PH_PDI IN ('203','204','208','209','222','290','300') ) ) "

	_cQry += " UNION "

	_cQry += " SELECT PC_DATA DATA, PC_QTABONO QTABONO, "
	_cQry += " ( CASE WHEN PC_QUANTI > 0 THEN PC_QUANTI ELSE PC_QUANTC END ) QTDHORAS, "
	_cQry += " ( CASE WHEN PC_PDI <> ' ' THEN PC_PDI ELSE PC_PD END ) EVENTO "
	_cQry += " FROM "+RetSqlTab("SPC")+" (NOLOCK) "
	_cQry += " WHERE SPC.D_E_L_E_T_ = ' ' "
	_cQry += " AND PC_FILIAL = '"+SRA->RA_FILIAL+"' "
	_cQry += " AND PC_MAT = '"+SRA->RA_MAT+"' "
	_cQry += " AND PC_DATA BETWEEN '"+dtos(mv_par13)+"'AND '"+dtos(mv_par14)+"' "
	_cQry += " AND ( ( PC_PD IN ('203','204','208','209','222','290','300') AND PC_PDI = ' ' ) "
	_cQry += " 	OR ( PC_PDI IN ('203','204','208','209','222','290','300') ) ) "

	If Select(_cArqHrs) <> 0
		(_cArqHrs)->(DBCLOSEAREA())
	EndIF

	_cQry := ChangeQuery(_cQry)

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,_cQry),_cArqHrs,.F.,.T.)

	(_cArqHrs)->(dbGoTop())

	while (_cArqHrs)->(!eof())
		_nPos := aScan(_aImp,{|x| Dtos(x[1]) == (_cArqHrs)->DATA } )

		do Case
			Case (_cArqHrs)->EVENTO $ "290"	// H.E.60%
			_aImp[_nPos,11] := (_cArqHrs)->QTDHORAS
			_aTotColu[1]:= __TimeSum(_aTotColu[1],(_cArqHrs)->QTDHORAS)

			Case (_cArqHrs)->EVENTO $ "203_222"	// ADICIONAL NOTURNO
			_aImp[_nPos,12] := (_cArqHrs)->QTDHORAS
			_aTotColu[2]:= __TimeSum(_aTotColu[2],(_cArqHrs)->QTDHORAS)

			Case (_cArqHrs)->EVENTO $ "209"	// ATRASO NAO AUTORIZADO
			_aImp[_nPos,13] := (_cArqHrs)->QTDHORAS
			_aTotColu[3]:= __TimeSum(_aTotColu[3],(_cArqHrs)->QTDHORAS)

			Case (_cArqHrs)->EVENTO $ "204_208"	// FALTA NAO AUTORIZADA
			_aImp[_nPos,14] := (_cArqHrs)->QTDHORAS
			_aTotColu[4]:= __TimeSum(_aTotColu[4],(_cArqHrs)->QTDHORAS)

			Case (_cArqHrs)->EVENTO $ "300"	// H.E.100%
			_aImp[_nPos,18] := (_cArqHrs)->QTDHORAS
			_aTotColu[6]:= __TimeSum(_aTotColu[6],(_cArqHrs)->QTDHORAS)

		endCase

		_aImp[_nPos,15] := (_cArqHrs)->QTABONO
		_aTotColu[5]:= __TimeSum(_aTotColu[5],(_cArqHrs)->QTABONO)

		(_cArqHrs)->(dbSkip())
	enddo
	(_cArqHrs)->(DBCLOSEAREA())

	// busca banco de horas

	_nAntBHDe := 0
	_nAntBHCr	:= 0
	_cData		:= ""
	_nDebito	:= 0
	_nCredit	:= 0

	_cQry := " SELECT PI_DATA, PI_PD, PI_QUANTV, P9_TIPOCOD "
	_cQry += " FROM "+RetSqlTab("SPI")+" (NOLOCK) "
	_cQry += " INNER JOIN "+RetSqlTab("SP9")+" (NOLOCK) "
	_cQry += " ON ( P9_FILIAL = '"+xFilial("SP9")+"' "
	_cQry += " 	 AND P9_CODIGO = PI_PD ) "
	_cQry += " WHERE SPI.D_E_L_E_T_ = ' ' "
	_cQry += " AND SP9.D_E_L_E_T_ = ' ' "
	_cQry += " AND PI_FILIAL = '"+SRA->RA_FILIAL+"' "
	_cQry += " AND PI_MAT = '"+SRA->RA_MAT+"' "
	_cQry += " AND PI_DATA <= '"+dtos(mv_par14)+"' "
	_cQry += " AND PI_STATUS <> 'B' "
	_cQry += " AND PI_DTBAIX = ' ' "
	_cQry += " ORDER BY PI_DATA, PI_PD "

	If Select(_cArqBH) <> 0
		(_cArqBH)->(DBCLOSEAREA())
	EndIF

	_cQry := ChangeQuery(_cQry)

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,_cQry),_cArqBH,.F.,.T.)

	(_cArqBH)->(dbGoTop())

	while (_cArqBH)->(!eof())
		if (_cArqBH)->PI_DATA < dtos(mv_par13)
				if (_cArqBH)->P9_TIPOCOD $ "1*3"
						_nAntBHCr := __TimeSum(_nAntBHCr,(_cArqBH)->PI_QUANTV)
				else
						_nAntBHDe := __TimeSum(_nAntBHDe,(_cArqBH)->PI_QUANTV)
				endif

			(_cArqBH)->(dbSkip())
			Loop
		endif

		if _cData <> (_cArqBH)->PI_DATA
			if !Empty(_cData)
				_nPos := aScan(_aImp,{|x| Dtos(x[1]) == _cData } )
				_aImp[_nPos,16] := 	_nCredit	//fConvHr(_nCredit,'H')
				_aImp[_nPos,17] := _nDebito		//fConvHr(_nDebito,'H')
			endif
			_cData	:= (_cArqBH)->PI_DATA
			_nDebito	:= 0
			_nCredit	:= 0
		endif

			If (_cArqBH)->P9_TIPOCOD $ "1*3"
				_nCredit := __TimeSum(_nCredit,(_cArqBH)->PI_QUANTV)
				_nMesBHCr := __TimeSum(_nMesBHCr,(_cArqBH)->PI_QUANTV)
			else
				_nDebito := __TimeSum(_nDebito,(_cArqBH)->PI_QUANTV)
				_nMesBHDe := __TimeSum(_nMesBHDe,(_cArqBH)->PI_QUANTV)
			endif

		(_cArqBH)->(dbSkip())
	enddo

	if !Empty(_cData)
		_nPos := aScan(_aImp,{|x| Dtos(x[1]) == _cData } )
		_aImp[_nPos,16] := _nCredit    // fConvHr(_nCredit,'H')
		_aImp[_nPos,17] := _nDebito    //fConvHr(_nDebito,'H')
	endif

	(_cArqBH)->(dbCloseArea())

	// ordena por data
	_aImp := aSort(_aImp,,,{|x,y| x[1] < y[1]} )

	// consiste afastamentos/feriados/etc
	For _nX:=1 to len(_aImp)
		// se tiver apontamento desconsidera
		if !empty(_aImp[_nx,2])
			Loop
		endif

		_nPos := aScan(_aImp,{|x| dTos(x[1]) == dTos(_aImp[_nx,1]) } )

		if SRA->RA_SITFOLH $ 'D_T' .and. dTos(_aImp[_nx,1]) > dtos(SRA->RA_DEMISSA)
			_cTipAfas	:= fDemissao(SRA->RA_SITFOLH, SRA->RA_RESCRAI)
			_cDescAfas	:= fDescAfast(_cTipAfas, Nil, Nil, .T. )
			_aImp[_nPos,10] := _cDescAfas
			Loop
		endif

		// verifica se funcionario estava afastado na data
		aAfasta := {}
		SR8->(dbSetOrder(1))
		_lAfastper := fAfastaPer( @aAfasta , _aImp[_nx,1] , _aImp[_nx,1] , SRA->RA_FILIAL , SRA->RA_MAT )

		if _lAfastper
			_cTipAfas	:= aAfasta[Len(aAfasta),3]
			_cDescAfas	:= fDescAfast(_cTipAfas, Nil, Nil, .T. )
			_aImp[_nPos,10] := _cDescAfas
			Loop
		endif

		// verifica feriado
		SP3->(dbSetOrder(1))
		if SP3->(dbSeek(SRA->RA_FILIAL+dtos(_aImp[_nx,1])))
			_aImp[_nPos,10] := SP3->P3_DESC
			Loop
		endif

		//-- Se a Data da marcacao for Posterior a Admissao
		IF dtos(_aImp[_nx,1]) >= dtos(SRA->RA_ADMISSA)
			_cTipDia := Posicione("SPJ",1,xfilial("SPJ")+SRA->RA_TNOTRAB+"01"+str(Dow(_aImp[_nx,1]),1),"PJ_TPDIA")

			//-- Se Dia Trabalhado e Nao fez Marcacao
			If _cTipDia == 'S' .and. Empty(_aImp[_nx,2])
				_aImp[_nPos,10] := '** Ausente **'
			ElseIf _cTipDia == 'D'
				_aImp[_nPos,10] := '** D.S.R. **'
			ElseIf _cTipDia == 'C'
				_aImp[_nPos,10] := '** Compensado **'
			ElseIf _cTipDia == 'N'
				_aImp[_nPos,10] := '** Não Trabalhado **'
			EndIf
		endif
	Next

return

Static Function sfPergunte(_cPerg)
	Local _aHelpPor	:= {}
	Local _aTam		:= {}

	_aHelpPor := {}
	_aTam := TamSX3("RA_FILIAL")
	Aadd( _aHelpPor,   'Informe a filial inicial ')
	PutSx1(_cPerg,"01","Filial De"," "," ","mv_ch1",_aTam[3],_aTam[1],_aTam[2],0,"G","","SM0","","","MV_PAR01","","","","","","","","","","","","","","","","",_aHelpPor,{},{})

	_aHelpPor := {}
	_aTam := TamSX3("RA_FILIAL")
	Aadd( _aHelpPor,   'Informe a filial Final ')
	PutSx1(_cPerg,"02","Filial Ate"," "," ","mv_ch2",_aTam[3],_aTam[1],_aTam[2],0,"G","","SM0","","","MV_PAR02","","","","","","","","","","","","","","","","",_aHelpPor,{},{})

	_aTam := TamSX3("RA_CC")
	_aHelpPor := {}
	aAdd(_aHelpPor,    "Centro de Custo de?")
	PutSx1(_cPerg,"03","Centro de Custo de","","","mv_ch03",_aTam[3],_aTam[1],_aTam[2],0,"G","","CTT","","","mv_par03","","","","","","","","","","","","","","","","",_aHelpPor,{},{})

	_aHelpPor := {}
	aAdd(_aHelpPor,    "Centro de Custo ate?")
	PutSx1(_cPerg,"04","Centro de Custo ate","","","mv_ch04",_aTam[3],_aTam[1],_aTam[2],0,"G","","CTT","","","mv_par04","","","","","","","","","","","","","","","","",_aHelpPor,{},{})

	_aTam := TamSX3("RA_TNOTRAB")
	_aHelpPor := {}
	aAdd(_aHelpPor,    "Turno de?")
	PutSx1(_cPerg,"05","Turno de ","","","mv_ch05",_aTam[3],_aTam[1],_aTam[2],0,"G","","SR6","","","mv_par05","","","","","","","","","","","","","","","","",_aHelpPor,{},{})

	_aHelpPor := {}
	aAdd(_aHelpPor,    "Turno ate?")
	PutSx1(_cPerg,"06","Turno ate ","","","mv_ch06",_aTam[3],_aTam[1],_aTam[2],0,"G","","SR6","","","mv_par06","","","","","","","","","","","","","","","","",_aHelpPor,{},{})


	_aTam := TamSX3("RA_MAT")
	_aHelpPor := {}
	aAdd(_aHelpPor,    "Matricula de?")
	PutSx1(_cPerg,"07","Matricula de ","","","mv_ch07",_aTam[3],_aTam[1],_aTam[2],0,"G","","SRA","","","mv_par07","","","","","","","","","","","","","","","","",_aHelpPor,{},{})

	_aHelpPor := {}
	aAdd(_aHelpPor,    "Matricula ate?")
	PutSx1(_cPerg,"08","Matricula ate ","","","mv_ch08",_aTam[3],_aTam[1],_aTam[2],0,"G","","SRA","","","mv_par08","","","","","","","","","","","","","","","","",_aHelpPor,{},{})

	_aTam := TamSX3("RA_NOME")
	_aHelpPor := {}
	aAdd(_aHelpPor,    "Nome de?")
	PutSx1(_cPerg,"09","Nome de ","","","mv_ch09",_aTam[3],_aTam[1],_aTam[2],0,"G","","","","","mv_par09","","","","","","","","","","","","","","","","",_aHelpPor,{},{})

	_aHelpPor := {}
	aAdd(_aHelpPor,    "Nome ate?")
	PutSx1(_cPerg,"10","Nome ate ","","","mv_ch10",_aTam[3],_aTam[1],_aTam[2],0,"G","","","","","mv_par10","","","","","","","","","","","","","","","","",_aHelpPor,{},{})

	_aHelpPor := {}
	aAdd(_aHelpPor,    "Situacao?")
	PutSx1(_cPerg,"11","Situacao ","","","mv_ch11","C",5	,0,0,"G","fSituacao()","","","","mv_par11","","","","","","","","","","","","","","","","",_aHelpPor,{},{})

	_aHelpPor := {}
	aAdd(_aHelpPor,    "Categoria?")
	PutSx1(_cPerg,"12","Categoria ","","","mv_ch12","C",12,0,0,"G","fCategoria()","","","","mv_par12","","","","","","","","","","","","","","","","",_aHelpPor,{},{})

	_aHelpPor := {}
	_aTam := TamSX3("P8_DATA")
	Aadd( _aHelpPor, 'Data Inicial')
	PutSx1(_cPerg,"13","Data de"," "," ","mv_ch13",_aTam[3],_aTam[1],_aTam[2],0,"G","","","","","MV_PAR13","","","","","","","","","","","","","","","","",_aHelpPor,{},{})

	_aHelpPor := {}
	_aTam := TamSX3("P8_DATA")
	Aadd( _aHelpPor, 'Data Final')
	PutSx1(_cPerg,"14","Data Ate"," "," ","mv_ch14",_aTam[3],_aTam[1],_aTam[2],0,"G","","","","","MV_PAR14","","","","","","","","","","","","","","","","",_aHelpPor,{},{})

	_aHelpPor := {}
	aAdd( _aHelpPor,   "Horas em:")
	aAdd( _aHelpPor,   "1 - Sexagenal")
	aAdd( _aHelpPor,   "2 - Centesimal")
	PutSx1(_cPerg,"15","Horas em","","","mv_ch15","N",1,0,0,"C","","","","","mv_par15","Sexagenal","Sexagenal","Sexagenal","Sexagenal","Centesimal","Centesimal","Centesimal","","","","","","","","","","",_aHelpPor,{},{})

Return

//Função para retornar o valor do intervalo do turno
Static Function sfTurno(_cTurno)
	Local _cQry			:= ""
	local _aTurno 		:= {}
	local _aTmpTurno 	:= GetNextAlias()
	Local _cTmp01		:= ""
	Local _cTmp02		:= ""
	Local _cTempo		:= ""
	Local _nQtde		:= 0
	Local _lInclui		:= .T.

	_cQry:="select PJ_DIA, PJ_TPDIA, PJ_ENTRA1,PJ_SAIDA1,PJ_ENTRA2,PJ_SAIDA2,PJ_ENTRA3,PJ_SAIDA3,PJ_ENTRA4,PJ_SAIDA4 "
	_cQry+=" FROM "+RetSqlTab("SPJ")
	_cQry+=" WHERE SPJ.D_E_L_E_T_ = ' ' "
	_cQry+=" AND PJ_FILIAL = '"+xFilial("SPJ")+"' "
	_cQry+=" AND PJ_TURNO =  '"+_cTurno+"' "
	_cQry+=" AND PJ_SEMANA = '01' "
	_cQry+=" ORDER BY PJ_DIA DESC "
	_cQry := ChangeQuery(_cQry)

	If Select(_aTmpTurno) <> 0
		(_aTmpTurno)->(DBCLOSEAREA())
	EndIF

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,_cQry),_aTmpTurno,.F.,.T.)

	(_aTmpTurno)->(dbGoTop())

	while (_aTmpTurno)->(!eof())
		IF (_aTmpTurno)->PJ_TPDIA == "S"
			_cTempo	:= ""
			_cTmp01 := iif((_aTmpTurno)->PJ_ENTRA1 > 0,Padr(StrTran(StrTran(str((_aTmpTurno)->PJ_ENTRA1,5,2),".",":")," ","0"),8),"")
			_cTmp02 := iif((_aTmpTurno)->PJ_SAIDA1 > 0,Padr(StrTran(StrTran(str((_aTmpTurno)->PJ_SAIDA1,5,2),".",":")," ","0"),8),"")

			IF !Empty(_cTmp01) .AND. !Empty(_cTmp02)
				_cTempo+= Alltrim( _cTmp01) +" às "+Alltrim(_cTmp02)
			ENDIF

			_cTmp01 := iif((_aTmpTurno)->PJ_ENTRA2 > 0,Padr(StrTran(StrTran(str((_aTmpTurno)->PJ_ENTRA2,5,2),".",":")," ","0"),8),"")
			_cTmp02 := iif((_aTmpTurno)->PJ_SAIDA2 > 0,Padr(StrTran(StrTran(str((_aTmpTurno)->PJ_SAIDA2,5,2),".",":")," ","0"),8),"")

			IF !Empty(_cTmp01) .AND. !Empty(_cTmp02)
				_cTempo+= " / "+ Alltrim( _cTmp01) +" às "+Alltrim(_cTmp02)
			ENDIF

			_cTmp01 := iif((_aTmpTurno)->PJ_ENTRA3 > 0,Padr(StrTran(StrTran(str((_aTmpTurno)->PJ_ENTRA3,5,2),".",":")," ","0"),8),"")
			_cTmp02 := iif((_aTmpTurno)->PJ_SAIDA3 > 0,Padr(StrTran(StrTran(str((_aTmpTurno)->PJ_SAIDA3,5,2),".",":")," ","0"),8),"")

			IF !Empty(_cTmp01) .AND. !Empty(_cTmp02)
				_cTempo+= " / "+ Alltrim( _cTmp01) +" às "+Alltrim(_cTmp02)
			ENDIF

			_cTmp01 := iif((_aTmpTurno)->PJ_ENTRA4 > 0,Padr(StrTran(StrTran(str((_aTmpTurno)->PJ_ENTRA4,5,2),".",":")," ","0"),8),"")
			_cTmp02 := iif((_aTmpTurno)->PJ_SAIDA4 > 0,Padr(StrTran(StrTran(str((_aTmpTurno)->PJ_SAIDA4,5,2),".",":")," ","0"),8),"")

			IF !Empty(_cTmp01) .AND. !Empty(_cTmp02)
				_cTempo+= " / "+ Alltrim( _cTmp01) +" às "+Alltrim(_cTmp02)
			ENDIF

			IF (_aTmpTurno)->PJ_DIA $ '2_3_4_5_6' .AND. _nQtde = 0
				aadd(_aTurno,{1,_cTempo})
				_nQtde+=1
			ElseIF (_aTmpTurno)->PJ_DIA == "7"
				aadd(_aTurno,{2,_cTempo})
			EndIF
		EndIF

		IF (_aTmpTurno)->PJ_TPDIA == "C" // .AND. (_aTmpTurno)->PJ_DIA == "7"
			Do Case
			Case (_aTmpTurno)->PJ_DIA == "1"
				_cComp:= "Domingo: Compensado"
			Case (_aTmpTurno)->PJ_DIA == "2"
				_cComp:= "Segunda: Compensado"
			Case (_aTmpTurno)->PJ_DIA == "3"
				_cComp:= "Terça: Compensado"
			Case (_aTmpTurno)->PJ_DIA == "4"
				_cComp:= "Quarta: Compensado"
			Case (_aTmpTurno)->PJ_DIA == "5"
				_cComp:= "Quinta: Compensado"
			Case (_aTmpTurno)->PJ_DIA == "6"
				_cComp:= "Sexta: Compensado"
			Case (_aTmpTurno)->PJ_DIA == "7"
				_cComp:= "Sábado: Compensado"
			otherwise
				_cComp:= ""
			EndCase
		ENDIF
		(_aTmpTurno)->(dbSkip())
	enddo

	(_aTmpTurno)->(dbCloseArea())

	aSort(_aTurno, , , {|x,y|x[1] < y[1]})

Return(_aTurno)