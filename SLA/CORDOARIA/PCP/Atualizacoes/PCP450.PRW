#Include "TOTVS.ch"
#Include "FWMVCDEF.ch"

/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina geracao da OS de Expedicao                       !
+------------------+---------------------------------------------------------+
!Autor             ! Andre Sakai                 ! Data de Criacao ! 01/2013 !
+------------------+--------------------------------------------------------*/

User Function PCP450()

	// objeto browse
	Private oBrowse

	// botoes da rotina
	Private aRotina	:= MenuDef()

	// variaveis necessarias para funcao padrao AxCadastro
	private cCadastro := "Acerto de Ordem de Produção"
/*
	// cria objeto do browse
	_oBrwAcOP:= FWMBrowse():New()
	_oBrwAcOP:SetAlias("SC2")
	_oBrwAcOP:SetDescription( OemToAnsi(cCadastro) )
	_oBrwAcOP:DisableDetails()
	_oBrwAcOP:DisableConfig()
	_oBrwAcOP:DisableLocate()

	// filtro padrao
//	_oBrwAcOP:SetFilterDefault("@(C2_EMISSAO BETWEEN '20191101' AND '20191131')")

	// define cores do browse
	_oBrwAcOP:AddLegend("A650DefLeg(1)", "BR_AMARELO" ) //"Prevista"
//	_oBrwAcOP:AddLegend("A650DefLeg(2)", "BR_VERDE" ) //"Em aberto"
//	_oBrwAcOP:AddLegend("A650DefLeg(3)", "BR_LARANJA" ) //"Iniciada"
//	_oBrwAcOP:AddLegend("A650DefLeg(4)", "BR_CINZA" ) //"Ociosa"
//	_oBrwAcOP:AddLegend("A650DefLeg(5)", "BR_AZUL" ) //"Encerrada parcialmente"

	// cria um filtro fixo para todos
	_oBrwAcOP:AddFilter("Prevista"    	, "A650DefLeg(1)", .f., .f., "SC2", .f., {}, "ID_PREVISTA"  )
	_oBrwAcOP:AddFilter("Em aberto"		, "A650DefLeg(2)", .f., .f., "SC2", .f., {}, "ID_ABERTA"  )
	_oBrwAcOP:AddFilter("Iniciada"    	, "A650DefLeg(3)", .f., .f., "SC2", .f., {}, "ID_INCIADA"  )
	_oBrwAcOP:AddFilter("Ociosa"      	, "A650DefLeg(4)", .f., .f., "SC2", .f., {}, "ID_OCIOSA"  )
	_oBrwAcOP:AddFilter("Enc Parc"    	, "A650DefLeg(5)", .f., .f., "SC2", .f., {}, "ID_P_ENCERRADA"  )

	// ativa browse/objeto
	_oBrwAcOP:Activate()
*/

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('SC2')
	oBrowse:SetDescription( OemToAnsi(cCadastro) )
	oBrowse:DisableDetails()
	oBrowse:DisableConfig()
	oBrowse:DisableLocate()
	oBrowse:SetMenuDef("PCP450") // Nome do fonte onde esta a função MenuDef
	oBrowse:SetDescription( cCadastro ) //"Operações da Ordem"
	oBrowse:Activate()


Return

Static Function MenuDef()

	// variavel de retorno
	local _aRetMenu := {}

	ADD OPTION _aRetMenu TITLE 'Visualizar' 		ACTION 'VIEWDEF.PCP450'	OPERATION MODEL_OPERATION_VIEW   ACCESS 0
	ADD OPTION _aRetMenu TITLE 'Alterar Empenho'    ACTION 'VIEWDEF.PCP450'	OPERATION MODEL_OPERATION_UPDATE ACCESS 0
	ADD OPTION _aRetMenu TITLE 'Legenda'    		ACTION 'U_pCP450E()'	OPERATION MODEL_OPERATION_UPDATE ACCESS 0

Return (_aRetMenu)

// ModelDef - Modelo padrao para MVC
Static Function ModelDef()

	// variaveis para modelo
	Local _oModel  := Nil
	Local _oStrSC2 := FWFormStruct( 1, 'SC2', /*bAvalCampo*/,/*lViewUsado*/ )
	Local _oStrSD4 := FWFormStruct( 1, 'SD4', /*bAvalCampo*/,/*lViewUsado*/ )
	
	_oModel := MPFormModel():New('PCP450', /*bPreValidacao*/, /*{|oModel| VldOk210(oModel) }*/, /*bCommit*/, /*bCancel*/ )

	// Adiciona ao modelo uma estrutura de formulário de edição por campo
	_oModel:AddFields( 'SC2MASTER', /*cOwner*/, _oStrSC2, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )
	_oModel:AddGrid( 'SD4DETAIL', 'SC2MASTER', _oStrSD4, /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

	_oModel:SetRelation( 'SD4DETAIL', { { 'D4_FILIAL', 'xFilial( "SD4" )' }, { 'D4_OP', 'C2_NUM+C2_ITEM+C2_SEQUEN+C2_ITEMGRD'} }, SD4->(IndexKey(2)) )
	
	_oModel:GetModel( 'SC2MASTER' ):SetDescription( 'ORDENS DE PRODUCAO' ) //"Ordens de Operação"
	_oModel:GetModel( 'SD4DETAIL' ):SetDescription( 'APONTAMENTOS' ) //"Operações da Ordem"
	
	


Return (_oModel)


Static Function ViewDef()
	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local _oModelo     := FWLoadModel( 'PCP450' )
	// Cria a estrutura a ser usada na View
	Local _oStrSC2 := FWFormStruct( 2, 'SC2' )
	Local _oStrSD4 := FWFormStruct( 2, 'SD4' ) 
	
	// Cria o objeto de View
	_oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	_oView:SetModel( _oModelo )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	_oView:AddField( 'VIEW_SC2', _oStrSC2, 'SC2MASTER' )
	_oView:AddGrid(  'VIEW_SD4', _oStrSD4, 'SD4DETAIL' )

	// Criar um "box" horizontal para receber algum elemento da view
	_oView:CreateHorizontalBox( 'SUPERIOR', 60 )
	_oView:CreateHorizontalBox( 'INFERIOR', 40 )

	// Relaciona o ID da View com o "box" para exibicao
	_oView:SetOwnerView( 'VIEW_SC2', 'SUPERIOR' )
	_oView:SetOwnerView( 'VIEW_SD4', 'INFERIOR' )
	
	_oStrSC2:RemoveField("C2_FILIAL")
	_oStrSD4:RemoveField("D4_FILIAL")
	_oStrSD4:RemoveField("D4_OP")

Return _oView

User Function PCP450E()

	// funcao padrao para lengendas
	BrwLegenda(cCadastro,;
	"Status " + cCadastro,{;
	{"BR_AMARELO" , "Prevista" },;
	{"BR_VERDE"   , "Em aberto"         },;
	{"BR_LARANJA", "Iniciada"     },;
	{"BR_CINZA"   , "Ociosa"         },;
	{"BR_AZUL"    , "Parcialmente Fechada"       }})

Return .T.

