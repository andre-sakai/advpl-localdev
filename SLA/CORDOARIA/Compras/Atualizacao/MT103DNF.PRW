#Include "rwmake.ch"
#Include "topconn.ch"

// PONTO DE ENTRADA MT103DNF 
// Fun��o.: Validar CHAVE na Inclus�o de Nota Fiscal de Entrada quando NFE
// Cria��o: 28/03/2012
// Eduardo Marquetti

User Function MT103DNF()

// Local aDanfe := PARAMIXB[1]          
// Local cChave := aDanfe[13]


// If CTIPO = 'N' // NOTA FISCAL DE ENTRADA DO TIPO NORMAL
// 	If CESPECIE = 'SPED' .AND. Length(Alltrim(cChave)) < 44 // Chave Digitada no F1->CHVNFE
//		Msgbox ("Chave na NFE n�o informada -  Informa��es DANFE","Alert","Alert")
//		Return (.F.)
//	Else 
//		Return (.T.)    
//	End                                    
// End

Return (.T.)