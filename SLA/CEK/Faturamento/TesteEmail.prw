#Include 'Protheus.ch'
#Include 'Protheus.ch'
#Include "RWMAKE.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "rptdef.ch"
#INCLUDE "fwprintsetup.ch"
#INCLUDE 'Ap5Mail.ch'

User Function TesteEmail()
	
	
	local oServer  := Nil
	local oMessage := Nil
	local nErr     := 0
	local cPopAddr  := "pop.example.com"      // Endereco do servidor POP3
	local cSMTPAddr := "smtp.zoho.com"     // Endereco do servidor SMTP
	local cPOPPort  := 110                    // Porta do servidor POP
	local cSMTPPort := 465                   // Porta do servidor SMTP
	local cUser     := "financeiro2@cekacessorios.com.br"     // Usuario que ira realizar a autenticacao
	local cPass     := "CeK#finan02"             // Senha do usuario
	local nSMTPTime := 60                     // Timeout SMTP
	
	
	

	// Instancia um novo TMailManager
	oServer := tMailManager():New()
	
	// Usa SSL na conexao
	oServer:setUseSSL(.T.)
	
	// Inicializa
	oServer:init(cPopAddr, cSMTPAddr, cUser, cPass, cPOPPort, cSMTPPort)
	
	// Define o Timeout SMTP
	if oServer:SetSMTPTimeout(nSMTPTime) != 0
		conout("[ERROR]Falha ao definir timeout")
		return .F.
	endif
	
	// Conecta ao servidor
	nErr := oServer:smtpConnect()
	if nErr <> 0
		conOut("[ERROR]Falha ao conectar: " + oServer:getErrorString(nErr))
		oServer:smtpDisconnect()
		return .F.
	endif
	
	// Realiza autenticacao no servidor
	nErr := oServer:smtpAuth(cUser, cPass)
	if nErr <> 0
		conOut("[ERROR]Falha ao autenticar: " + oServer:getErrorString(nErr))
		oServer:smtpDisconnect()
		return .F.
	endif
	
	// Cria uma nova mensagem (TMailMessage)
	oMessage := tMailMessage():new()
	oMessage:clear()
	oMessage:cFrom    := "financeiro2@cekacessorios.com.br"
	oMessage:cTo      := "rubem.mn2@gmail.com"
	//oMessage:cTo      := "inspecao@forjabahia.com.br;vendas@forjabahia.com.br;qualidade@forjabahia.com.br"
	//oMessage:cCC      := "cpd@forjabahia.com.br"
	//oMessage:cBCC     := "cpd@forjabahia.com.br"
	oMessage:cSubject := "Rubem"
	//oMessage:cSubject := "SOLICITAÇÃO DE CERTIFICADO DE CONTEÚDO LOCAL Ped. Cliente .: " + AllTrim(SC6->C6_PEDCLI) + " - NFe .: " + AllTrim(SC6->C6_NOTA)
	oMessage:cBody    := "TEstando"
	
	// Envia a mensagem
	nErr := oMessage:send(oServer)
	if nErr <> 0
		conout("[ERROR]Falha ao enviar: " + oServer:getErrorString(nErr))
		oServer:smtpDisconnect()
		return .F.
	endif
	
	// Disconecta do Servidor
	oServer:smtpDisconnect()
	
	
Return .T.


