#INCLUDE "Protheus.ch"
/*/{Protheus.doc} MA410LEG

Este ponto de entrada pertence � rotina de pedidos de venda, MATA410().
Usado, em conjunto com o ponto MA410COR, para alterar os textos da legenda, que representam o
�status� do pedido.

@author administrador
@since 18/08/2018
@version undefined

@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function MA410LEG()

	Local aLegenda := PARAMIXB

	aAdd(aLegenda , {"BR_PRETO"	, "Bloqueado Estoque"})
	aAdd(aLegenda , {"BR_VIOLETA"	, "Bloqueado Pre�o"})

Return aLegenda