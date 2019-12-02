User Function PWS0004()

Local nValPgto := 0
Local nValImp  := 0
Local nValImpr := ""
                                   
nValPgto := SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",SE1->E1_MOEDA,SE1->E1_EMISSAO,SE1->E1_CLIENTE,SE1->E1_LOJA)
nValImp  := Alltrim(Str((nValPgto)*100))

nValImpr := STRZERO(val(nValImp),13)

Return (nValImpr)