
// Retorna o nome reduzido do cliente no Browse
User Function GetNomeCli(cTipo, cCliente, cLoja)

Local cRet := ""


If (cTipo=="D")
	cRet := Posicione("SA2", 1, XFILIAL("SA2")+cCliente+cLoja, "A2_NREDUZ")

Else
	cRet := Posicione("SA1", 1, XFILIAL("SA1")+cCliente+cLoja, "A1_NREDUZ")

Endif

Return (cRet)


// Retorna o nome reduzido do fornecedor no Browse
User Function GetNomeFor(cTipo, cFornecedor, cLoja)

Local cRet := ""
	cRet := Posicione("SA1", 1, XFILIAL("SA1")+cFornecedor+cLoja, "A1_NREDUZ")

If (cTipo=="D")

Else
	cRet := Posicione("SA2", 1, XFILIAL("SA2")+cFornecedor+cLoja, "A2_NREDUZ")

Endif


Return (cRet)
