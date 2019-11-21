#include 'protheus.ch'
#include 'parmtype.ch'

user function MA410MNU() 

	SetKey(VK_F8, {||U_libped()})
	aadd(aRotina,{"Lib. Preco","U_libped" , 0 , 4,0,NIL})
	
	SetKey(VK_F9, {||U_altped()})
	aadd(aRotina,{"Alt. Pedido","U_altped" , 0 , 4,0,NIL})
	
	SetKey(VK_F10, {||U_Ped_Ven()})
	aadd(aRotina,{'Imprime PV CeK ','U_Ped_Ven()',0,1,0,NIL})

	SetKey(VK_F11, {||U_CEKCPYPED()})
	aadd(aRotina,{"Copia PV Indus.","U_CEKCPYPED" , 0 , 4,0,NIL})
		
return