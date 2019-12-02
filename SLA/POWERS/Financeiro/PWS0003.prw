User Function PWS0003()

Local nValAbat := 0
Local nValTit  := 0
Local cValTit  := ""

nValAbat := SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",SE1->E1_MOEDA,dDataBase,SE1->E1_CLIENTE,SE1->E1_LOJA)
nValTit  := SE1->E1_VALOR - nValAbat
cValTit  := STRZERO((ROUND(nValTit,2)*100),13) 

Return(cValTit)