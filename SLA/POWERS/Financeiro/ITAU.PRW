#include 'protheus.ch'

// Fonte usado na montagem do valor do título que será exibido no CNAB do ITAU.
user function ITAU()
	
local _nValor 	:= SE1->E1_VALOR
local _nAbat 	:= SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",1,,SE1->E1_CLIENTE,SE1->E1_LOJA)
local _nTotal 	:= 0

_nTotal = _nValor - _nAbat 

return(_nTotal)