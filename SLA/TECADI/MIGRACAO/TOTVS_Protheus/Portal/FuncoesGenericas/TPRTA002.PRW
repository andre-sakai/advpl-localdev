#Include "Totvs.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Geracao da Senha Inicial do usuario do portal           !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 05/2014                                                 !
+------------------+--------------------------------------------------------*/

User Function TPRTA002
// controle de senhas
local _cNewPsw
local _cNewPswCript
// tamanho da senha aleatorio
local _nTamSenha := Randomize(6,10)

// valida se eh primeira senha
If ( ! ("AGUARDANDO" $ AI3->AI3_PSW))
	MsgStop("Não é possível gerar 1a senha de usuários com senha própria definida!")
	Return(.f.)
EndIf

// confirma a geracao
If MsgYesNo("Confirma a geração e envio por e-mail ("+AllTrim(AI3->AI3_EMAIL)+") da 1a senha ? ","ATENÇÃO")
	// gera nova senha
	_cNewPsw      := U_FtGeraPsw(_nTamSenha)
	// criptografa a senha
	_cNewPswCript := Md5(_cNewPsw)
	
	// atualiza os dados no cadastro
	RecLock("AI3")
	AI3->AI3_ZPSW := _cNewPsw
	AI3->AI3_PSW  := _cNewPswCript
	AI3->(MsUnLock())
	
	// aviso por email
	U_FtMail("Senha de primeiro acesso de "+AllTrim(AI3->AI3_NOME)+" gerada com sucesso!"+CRLF+;
	"Acesse: http://portal.tecadi.com.br"+CRLF+;
	"Login: "+AllTrim(AI3->AI3_LOGIN)+CRLF+;
	"Senha: "+_cNewPsw, "Portal Tecadi - Cadastro de Usuário",AllTrim(Lower(AI3->AI3_EMAIL)))
	
	// gera log
	U_FtGeraLog(xFilial("AI3"), "AI3", xFilial("AI3")+AI3->AI3_CODUSU , "Geração da 1a senha de acesso. Email para "+AllTrim(AI3->AI3_EMAIL), "PRT", "")
	
	// mensagem de confirmacao
	MsgInfo("SUCESSO: 1a senha gerada e enviada por e-mail!","1a senha")
	
EndIf

Return(.t.)
