#INCLUDE 'Protheus.ch'
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Cadastro de Lastro e Camada de Produtos                 !
+------------------+---------------------------------------------------------+
!Autor             ! Gustavo                   ! Data de Criacao   ! 03/2017 !
+------------------+--------------------------------------------------------*/

User Function TWMSC015

	// objeto browse
	Local _oBrwLastro

	// botoes da rotina
	Private aRotina	:= MenuDef()

	// cria objeto do browse
	_oBrwLastro:= FWMBrowse():New()
	_oBrwLastro:SetAlias("Z20")
	_oBrwLastro:SetDescription( "Cadastro de lastro e camada dos produtos para WMS" )
	_oBrwLastro:DisableDetails()
	_oBrwLastro:DisableConfig()
	_oBrwLastro:DisableLocate()

	// filtro padrao
	_oBrwLastro:SetFilterDefault(" Z20_FILIAL == cFilAnt ")

	// ativa browse/objeto
	_oBrwLastro:Activate()

Return

// menus da rotina - MVC
Static Function MenuDef()
	Local aRotina := {;
	{"Pesquisar"         ,"PesqBrw"         ,0,1 },;
	{"Visualizar"        ,"VIEWDEF.TWMSC015",0,2 },;
	{"Incluir"           ,"VIEWDEF.TWMSC015",0,3 },;
	{"Alterar"           ,"VIEWDEF.TWMSC015",0,4 },;
	{"Excluir"           ,"VIEWDEF.TWMSC015",0,5 },;
	{"Imprimir"          ,"VIEWDEF.TWMSC015",0,8 },;
	{"Log de alterações" ,"U_TWMSC015A()"   ,0,2 } }
Return (aRotina)

// definições do modelo - MVC
Static Function ModelDef()
	// Cria o objeto do Modelo de Dados
	Local oModel // Modelo de dados que será construído

	// Cria a estrutura a ser usada no Modelo de Dados
	Local oStruZ20 := FWFormStruct( 1, "Z20" , /*bAvalCampo*/,/*lViewUsado*/ )
	oModel := MPFormModel():New("ModelLastroCamada", /*bPreValid*/,/*bPostValid*/, { |oModel| bCommit(oModel) })

	// Adiciona a descrição do Modelo de Dados
	oModel:SetDescription("Modelo de dados - Cadastro de lastro e camada")

	// Adiciona ao modelo um componente de formulário
	oModel:AddFields( "Z20MASTER", /*cOwner*/, oStruZ20)

	//Define a chave primaria utilizada pelo modelo
	oModel:SetPrimaryKey({"Z20_FILIAL", "Z20_CODPRO", "Z20_LOCAL", "Z20_UNITIZ" })

	// Adiciona a descrição do Componente do Modelo de Dados
	oModel:GetModel("Z20MASTER"):SetDescription( "Lastro e camada de produtos WMS" )

Return (oModel)

// definições da tela - MVC
Static Function ViewDef()
	// Interface de visualização construída
	Local oView

	// Cria um objeto de Modelo de dados baseado no ModelDef() do fonte informado
	Local oModel := ModelDef()

	// Cria a estrutura a ser usada na View
	Local oStruZ20 := FWFormStruct( 2, "Z20" )

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado na View
	oView:SetModel( oModel )

	// Adiciona no nosso View um controle do tipo formulário (antiga Enchoice)
	oView:AddField( "VIEW_Z20", oStruZ20, "Z20MASTER" )

	// Criar um "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( "TELA" , 100 )

	// Relaciona o identificador (ID) da View com o "box" para exibição
	oView:SetOwnerView( "VIEW_Z20","TELA" )
	oView:EnableTitleView("VIEW_Z20","LastroCamada" )
	oView:SetViewProperty("VIEW_Z20",'SETCOLUMNSEPARATOR', {10})

	//Força o fechamento da janela na confirmação
	oView:SetCloseOnOk({||.T.})
Return (oView)

// visualiza log do registro corrente
Static Function TWMSC015A
	// chama visualização de log padrão
	U_FtConsLog(xFilial("Z20"), "Z20", Z20->Z20_FILIAL + Z20->Z20_LOCAL + Z20->Z20_UNITIZ + Z20->Z20_CODPRO )

Return ( Nil )

// validações do botão CONFIRMAR
Static Function bCommit(oModel)
	Local _oMdl := oModel:GetModel("Z20MASTER")
	local _nOperation := oModel:GetOperation()

	Local _cFilial := cFilAnt
	Local _cLocal  := _oMdl:GetValue("Z20_LOCAL")
	Local _cUnitiz := _oMdl:GetValue("Z20_UNITIZ")
	Local _cCodpro := _oMdl:GetValue("Z20_CODPRO")
	Local _nLastro := _oMdl:GetValue("Z20_LASTRO")
	Local _nCamada := _oMdl:GetValue("Z20_CAMADA")
	Local _nAdicio := _oMdl:GetValue("Z20_ADICIO")

	// variavel de retorno
	local _lTudoOk := .T.
	
	Local _aAreaZ20 := Z20->(GetArea())

	// valida se o cadastro está duplicado
	Z20->(dbSetOrder(1))  // 1 - Z20_FILIAL, Z20_LOCAL, Z20_UNITIZ, Z20_CODPRO, R_E_C_N_O_, D_E_L_E_T_
	If (Z20->( dbSeek( _cFilial + _cLocal + _cUnitiz + _cCodPro) ) .AND. _nOperation == MODEL_OPERATION_INSERT)
		_lTudoOk := .F.
		// avisa usuario
		Help( ,, "TWMSC015.bCommit.001",, "Cadastro já existente para estes dados!", 1, 0 )
	EndIf
	
	// reposiciona tabela Z20
	RestArea(_aAreaZ20)
	
	// se passou nas validações
	If (_lTudoOk)
		// ações
		If (_nOperation == MODEL_OPERATION_INSERT)  // ao inserir
			//gera log
			U_FtGeraLog(xFilial("Z20"), "Z20", _cFilial + _cLocal + _cUnitiz + _cCodPro,;
			"Incluído lastro/camada do produto: " + AllTrim(_cCodPro)+". L:" + AllTrim(Str(_nLastro)) + "/C:" + AllTrim(Str(_nCamada)) + "/A:" + AllTrim(Str(Z20->Z20_ADICIO)) + ".",;
			"WMS", "", cUsername)
		ElseIf _nOperation == MODEL_OPERATION_DELETE  // ao excluir
			//gera log
			U_FtGeraLog(xFilial("Z20"), "Z20", _cFilial + _cLocal + _cUnitiz + _cCodPro,;
			"Excluído lastro/camada do produto: " + AllTrim(_cCodPro) + ". L:" + AllTrim(Str(_nLastro)) + "/C:" + AllTrim(Str(_nCamada)) + "/A:" + AllTrim(Str(Z20->Z20_ADICIO)) + ".",;
			"WMS", "", cUsername)
		ElseIf _nOperation == MODEL_OPERATION_UPDATE  // ao alterar
			//gera log
			U_FtGeraLog(xFilial("Z20"), "Z20", _cFilial + Z20->Z20_LOCAL + Z20->Z20_UNITIZ + Z20->Z20_CODPRO,;
			"Alterado lastro/camada do produto: " + AllTrim(Z20->Z20_CODPRO) + ". Novos dados --> L:" + AllTrim(Str(_nLastro)) + "/C:" + AllTrim(Str(_nCamada)) + "/A:" + AllTrim(Str(Z20->Z20_ADICIO)) + "/Local:"+AllTrim(_cLocal)+".",;
			"WMS", "", cUsername)
		EndIf

		// grava alterações
		_lTudoOk := FWFormCommit(oModel)

	EndIf
	
Return ( _lTudoOk )