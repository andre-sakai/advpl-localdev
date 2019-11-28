#Include "rwmake.ch"
#Include "TOPCONN.CH"

User Function ART414()

SetPrvt("xCta,xFuncao")

cCta	 := ' '
/*
Programa..: ART414
Autor.....: EDUARDO MARQUETTI
Data......: 14/09/2012
Descricao.: Gatilho para Preencher Conta conforme Centro de Custo informado.
Parametro.:
Retorno...:
Modulo....: SIGAEST - Estoque/Custos

*/

xFuncao	:= Funname()

// VERIFICA UR E FORNECE CONTA CONTABIL CORRETA.
// MOVIMENTACOES INTERNAS MATA241

If xFuncao = "MATA241"
	cCcusto	:= M->CCC
	cForma	:= " "            
	cCta:= CriaVar("D3_CONTA")
	cProduto := M->D3_COD

	DbSelectArea("SB1")
	DbSetOrder(1)
	DbGoTop()
	DbSeek(Xfilial("SB1")+cProduto)
	cTipo := B1_TIPO



	If cTipo = 'ML' // Material de Limpesa
  	 	If Substr(cCcusto,1,2) == '13'
			cCta:= '41204012'
		Else
			cCta:= '42203006'
		EndIf
	EndIf


	If cTipo = 'ME' // Material de Expediente
  	 	If Substr(cCcusto,1,2) == '13'
			cCta:= '41204051'
		Else
			cCta:= '42203004'
		EndIf
	EndIf
	     
	If cTipo = 'ES' // Equipamento de Segurança
		cCta:= '41204031'
	EndIf

	If cTipo = 'MC' // Material de Consumo
		cCta:= '41204033'
	EndIf
	
	If cTipo = 'FR' // Ferramentas
		cCta:= '41204021' // Bens de Pequeno Valor
	EndIf
	If cTipo = 'MM' // manutenção de Maquinas
		cCta:= '41204015'
	EndIf               
	
	If cTipo = 'EM' // Embalagem
		cCta:= '41202003' 
	EndIf               
	
	If cTipo = 'MS' // Material Secundario
		cCta:= '41202002' 
	EndIf               

	If cTipo = 'MP' // Materia Prima
		cCta:= '41202001' 
	EndIf               
	
EndIf



//PRODUCOES MATA250
If xFuncao = "MATA250"
	cCcusto	 := D3_CC
	cProduto := D3_COD

	DbSelectArea("SB1")
	DbSetOrder(1)
	DbGoTop()
	DbSeek(Xfilial("SB1")+cProduto)
	cCta := B1_CONTA
EndIf

Return (cCta)      
