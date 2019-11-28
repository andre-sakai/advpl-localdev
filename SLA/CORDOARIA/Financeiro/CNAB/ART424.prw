User Function ART424()          

// Retornar valor do abatimento para CNAB

Local _nValPgto, _nValImp
Local _nValImpr := ""
                                   
_nValPgto    := SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",SE1->E1_MOEDA,SE1->E1_EMISSAO,SE1->E1_CLIENTE,SE1->E1_LOJA)
_nValImp     := Alltrim(Str((SE1->E1_SALDO - _nValPgto)*100))

_nValImpr := STRZERO(_nValPgto*100,13)

Return _nValImpr