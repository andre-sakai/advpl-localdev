#INCLUDE "rwmake.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �MT250TOK  � Autor � Marcelo J. Santos  � Data �  24/03/06   ���
�������������������������������������������������������������������������͹��
���Descricao � Ponto de Entrada para validar a tela de Apontamento de Pro-���
���          � ducao                                                      ���
�������������������������������������������������������������������������͹��
���Uso       � Especifico para Arteplas                                   ���
���          � Para evitar que sejam apontadas producoes com quantidade 0 ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/


User Function MT250TOK()

If M->D3_QUANT = 0
	MsgBox("O Campo QUANTIDADE esta com conteudo 0 (zero)! Corrija.","Atencao","STOP")	
	Return(.F.)
Endif

If Empty(M->D3_DTPROD)
	MsgBox("O Campo DATA DE PRODU��O esta em branco! Corrija.","Atencao","STOP")	
	Return(.F.)
Endif

If Empty(M->D3_TURNO)
	MsgBox("O Campo TURNO esta em branco! Corrija.","Atencao","STOP")	
	Return(.F.)
Endif

If M->D3_QUANT <> 0 .and. !Empty(M->D3_DTPROD) .and. !Empty(M->D3_TURNO)
	Return(.T.)
Endif