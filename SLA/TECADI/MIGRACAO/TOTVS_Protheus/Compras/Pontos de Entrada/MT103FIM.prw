#include "protheus.ch"
#include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de Entrada disparado ap�s a finaliza��o da        !
!------------------! grava��o da nota fiscal de entrada                      !
! O ponto de entrada MT103FIM encontra-se no final da fun��o A103NFISCAL.    ! 
! Ap�s o destravamento de todas as tabelas envolvidas na grava��o do         !
! documento de entrada, depois de fechar a opera��o realizada neste.         !
! � utilizado para realizar alguma opera��o ap�s a grava��o da NFE.          !
!----------------------------------------------------------------------------!
! http://tdn.totvs.com/pages/releaseview.action?pageId=6085406               !
+------------------+---------------------------------------------------------+
!Retorno           ! Nil                                                     !
+------------------+---------------------------------------------------------+
!Autor             ! Luiz Poleza                 ! Data de Criacao ! 06/2019 !
+------------------+--------------------------------------------------------*/

User Function MT103FIM() 
	Local nOpcao := PARAMIXB[1]      // Op��o Escolhida pelo usuario no aRotina 
	Local nConfirma := PARAMIXB[2]   // Se o usuario confirmou a opera��o de grava��o da NFECODIGO DE APLICA��O DO USUARIO

	local _cUpdate := ""

	// se classificando nota, confirmou e a NF � vinculada a uma OS de pr�-recebimento
	If (nOpcao == 4 .AND. nConfirma == 1 .AND. SubStr(SF1->F1_ZOBS,1,2) = 'OS') 

		BEGIN TRANSACTION
			
			// atualiza NUMSEQ na OS de pr�-confer�ncia, pois o NUMSEQ muda ap�s a classifica��o da nota
			// e o NUMSEQ da Z07 neste momento � o da digita��o da NF
			
			_cUpdate := " Update Z07 set Z07.Z07_NUMSEQ = SD1.D1_NUMSEQ "
			_cUpdate += " FROM " + RetSQLTab("SD1")
			_cUpdate += " 	inner join "+RetSQLName("Z07")+" Z07 "
			_cUpdate += " 	on " + RetSqlCond("Z07")
			_cUpdate += " 	and Z07_NUMOS = '" + SubStr(SF1->F1_ZOBS,4,6) + "' "
			_cUpdate += " 	and Z07_SEQOS = '001' "
			_cUpdate += " 	and Z07_PRODUT = D1_COD "
			_cUpdate += " where " + RetSqlCond("SD1")
			_cUpdate += " and D1_DOC = '"+SF1->F1_DOC+"' "
			_cUpdate += " and D1_SERIE = '"+SF1->F1_SERIE+"' "
			_cUpdate += " and D1_FORNECE = '"+SF1->F1_FORNECE +"' "
			_cUpdate += " and D1_LOJA = '"+SF1->F1_LOJA+"' "
			_cUpdate += " and D1_TIPO = 'B' "

			// Tenta executar o SQL na tabela Z07

			//se deu erro
			If (TcSQLExec(_cUpdate) <> 0)
				// grava logs do sql para debug
				MemoWrit("c:\query\MT103FIM_UpdateZ07.txt", _cUpdate)
				MemoWrit("c:\query\MT103FIM_UpdateZ07_SQL.txt", TcSQLError() )

				MsgStop("Processo abortado: erro cr�tico ao realizar complemento da tabela Z07. Contate TI imediatamente!" ,"Erro MT103FIM - Update Z07")
				MsgStop( TcSQLError() )

				DisarmTransaction()
				Break
			EndIf

			_cUpdate := " Update Z16 set Z16.Z16_NUMSEQ = SD1.D1_NUMSEQ "
			_cUpdate += " FROM " + RetSQLTab("SD1")
			_cUpdate += " 	INNER JOIN " + RetSQLTab("Z07")
			_cUpdate += " 	on " + RetSqlCond("Z07")
			_cUpdate += " 	and Z07_NUMOS = '" + SubStr(SF1->F1_ZOBS,4,6) + "' "
			_cUpdate += " 	and Z07_SEQOS = '001' "
			_cUpdate += " 	and Z07_PRODUT = D1_COD "

			_cUpdate += " 	inner join " + RetSQLTab("Z16")
			_cUpdate += " 	on " + RetSqlCond("Z16")
			_cUpdate += " 	and Z16_CODPRO = Z07_PRODUT "
			_cUpdate += " 	and Z16_NUMSER = Z07_NUMSER "
			_cUpdate += " 	and Z16_ETQPRD = Z07_ETQPRD "
			_cUpdate += " 	and Z16_ETQVOL = Z07_ETQVOL "

			_cUpdate += " where  " + RetSqlCond("SD1")
			_cUpdate += " and D1_DOC = '"+SF1->F1_DOC+"' "
			_cUpdate += " and D1_SERIE = '"+SF1->F1_SERIE+"' "
			_cUpdate += " and D1_FORNECE = '"+SF1->F1_FORNECE +"' "
			_cUpdate += " and D1_LOJA = '"+SF1->F1_LOJA+"' "
			_cUpdate += " and D1_TIPO = 'B' "

			//se deu erro
			If (TcSQLExec(_cUpdate) <> 0)
				// grava logs do sql para debug
				MemoWrit("c:\query\MT103FIM_UpdateZ16.txt", _cUpdate)
				MemoWrit("c:\query\MT103FIM_UpdateZ16_SQL.txt", TcSQLError() )

				MsgStop("Processo abortado: erro cr�tico ao realizar complemento da tabela Z16. Contate TI imediatamente!" ,"Erro MT103FIM - Update Z16")
				MsgStop( TcSQLError() )

				DisarmTransaction()
				Break
			EndIf
			
			// atualiza status da sequencia 001 da OS de pr�-confer�ncia, que est� bloqueada (em an�lise - STATUS = AN)
			U_FtWmsSta( "AN", "FI", SubStr(SF1->F1_ZOBS,4,6), "001" )  

		END TRANSACTION
	EndIf

Return (NIL)