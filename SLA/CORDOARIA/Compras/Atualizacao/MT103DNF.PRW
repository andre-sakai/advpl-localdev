#Include "rwmake.ch"
#Include "topconn.ch"

// PONTO DE ENTRADA MT103DNF 
// Função.: Validar CHAVE na Inclusão de Nota Fiscal de Entrada quando NFE
// Criação: 28/03/2012
// Eduardo Marquetti

User Function MT103DNF()

// Local aDanfe := PARAMIXB[1]          
// Local cChave := aDanfe[13]


// If CTIPO = 'N' // NOTA FISCAL DE ENTRADA DO TIPO NORMAL
// 	If CESPECIE = 'SPED' .AND. Length(Alltrim(cChave)) < 44 // Chave Digitada no F1->CHVNFE
//		Msgbox ("Chave na NFE não informada -  Informações DANFE","Alert","Alert")
//		Return (.F.)
//	Else 
//		Return (.T.)    
//	End                                    
// End

Return (.T.)