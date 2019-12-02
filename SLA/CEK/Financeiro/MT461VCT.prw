#Include 'Protheus.ch'
//----------------------------------------------------------
/*/{Protheus.doc} MT461VCT
Ponto de Entrada  MT461VCT
@param
@return Array com Títulos a Receber
@author Rubem da Silva Cerqueira
@owner Totvs S/A
@obs Ponto de entrada para tratar o valor do frete+seguro na primeira parcela do titulo
@history

/*/
//----------------------------------------------------------

User Function MT461VCT ()
	
	Local aArea 			:= GetArea()
	Local aAREASF2 		:= SF2->(GetArea())
	Local aAREASe2		:= SE2->(GetArea())
	
	
	Local _aTitulo 		:= PARAMIXB[1]
	
	Local nFrete			:= 0
	Local nSeguro			:= 0
	
	Local _nFrete   	 	:= 0
	Local _nSeguro 		:= 0
	Local nCont 			:= 0
	
	nFrete					:= SF2->F2_FRETE
	nSeguro				:= SF2->F2_SEGURO
	
	
	
	If SF2->F2_TIPO == 'N' .And. (SF2->F2_TPFRETE == "C" .Or. SF2->F2_TPFRETE == "F") .And. (nFrete > 0 .Or. nSeguro > 0)
		
		
		//Trativa caso ICMS-ST seja  na primeira  parcela
		//Nessa situação a primeira parcela deve ser composto por ICMS-ST + nFrete + nSeguro
		IF 	SE4->E4_SOLID == "S" .And. SF4->F4_INCSOL == "S"  .And. SF4->F4_MKPSOL == "2"  
			
			For x = 2 to Len(_aTitulo)
				
				If Len(_aTitulo) > 1
					
					nCont += 1
					
				Endif
				
			Next x
			
			_nFrete 	 := Round(nFrete / nCont,2)
			
			_nSeguro   := Round(nSeguro / nCont,2)
			
			
			For z = 2 to Len(_aTitulo)
				
				If _nFrete > 0
					
					_aTitulo[z][2] := Round( _aTitulo[z][2] - _nFrete,2)
					
				Endif
				
				If _nSeguro > 0
					
					_aTitulo[z][2] :=  Round (_aTitulo[z][2] - _nSeguro,2)
					
				Endif
			Next x
			
			
		Else
			
			_nFrete 	 := Round(nFrete / Len(_aTitulo),2)
			
			_nSeguro   := Round(nSeguro / Len (_aTitulo),2)
			
			For x = 1 to Len(_aTitulo)
				
				If _nFrete > 0
					
					_aTitulo[x][2] := Round(_aTitulo[x][2] - _nFrete,2)
					
				Endif
				
				If _nSeguro > 0
					
					_aTitulo[x][2] -= _nSeguro
					
				Endif
			Next x
			
		Endif
	Endif
	
	//Na primeira parcela vou incluir o frete+seguro
	_aTitulo[1][2] +=  + nFrete + nSeguro
	
	
	
	RestArea(aAREASF2)
	RestArea(aAREASe2)
	RestArea(aArea)
	
Return _aTitulo

