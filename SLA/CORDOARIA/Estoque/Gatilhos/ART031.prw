#include "rwmake.ch" 
/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���FUNCAO    � ART031   �Autor  �Eduardo Marquetti   � Data �  27/04/11   ���
�������������������������������������������������������������������������͹��
���Desc.     � Calcula o Turno de acordo com dia da semana e Hora         ���
�������������������������������������������������������������������������͹��
���Uso       � SIGAEST - Produ��o (Gatilho D3_TURNO)                      ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function ART031()

cDiaSemana  := cdow(ddatabase)
cTurno		:= ' '     
cHora		:= time()

// Regras para Turno:
// Segunda at� Sexta (Domingo Tamb�m entra nessa Regra)
// 1 - 05:00 13:30
// 2 - 13:31 22:00
// 3 - 22:01 04:59
// S�bado
// 1 - 05:00 09:00
// 2 - 09:01 13:00


If cDiaSemana <> 'Saturday' .and. cHora >= '05:00:00' .and. cHora <='13:30:00'
	cTurno := '1'
EndIf
If cDiaSemana <> 'Saturday' .and. cHora >= '13:31:00' .and. cHora <='22:00:00'
	cTurno := '2'                                          
EndIf
If cDiaSemana <> 'Saturday' .and. cHora >= '22:01:00' .and. cHora <='04:59:59'
	cTurno := '3'  
EndIf             
If cDiaSemana = 'Saturday' .and. cHora >= '05:00:00' .and. cHora <='09:00:00'
	cTurno := '1'
EndIf
If cDiaSemana = 'Saturday' .and. cHora >= '09:01:00' .and. cHora <='13:00:00'
	cTurno := '2'                                          
EndIf

Return (cTurno)
 