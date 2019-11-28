#INCLUDE 'PROTHEUS.CH' 
#INCLUDE 'FWMVCDEF.CH'  
#INCLUDE 'FWADAPTEREAI.CH' 
//#INCLUDE 'PCP450.CH'

//------------------------------------------------------------------
/*/{Protheus.doc} PCP450A
Operações das Ordens - SD4

@author Ezequiel Marques Ramos
@since 04/04/2014
@version P11

/*/
//------------------------------------------------------------------
USER Function PCP450A()
	Private oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('SC2')
	oBrowse:SetMenuDef("PCP450A") // Nome do fonte onde esta a função MenuDef
	oBrowse:SetDescription( 'TESTE' ) //"Operações da Ordem"
	oBrowse:Activate()
Return NIL

//---------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Menu de Operações MVC

@author Ezequiel Marques Ramos
@since 04/04/2014
@version 1.0
/*/
//---------------------------------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina := {}

	aAdd(aRotina,{'Visualizar'                 , 'VIEWDEF.PCP450A', 0, 2, 0, Nil })
	aAdd(aRotina,{'Alterar Empenho'            , 'VIEWDEF.PCP450A', 0, 4, 0, Nil })

//	ADD OPTION aRotina TITLE 'VISUALIZAR' ACTION 'VIEWDEF.PCP450A' OPERATION 2 ACCESS 0  //"Visualizar"
Return aRotina

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Funcao generica MVC do model

@return oModel - Objeto do Modelo MVC

@author Ezequiel Marques Ramos
@since 04/04/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ModelDef()
	// Cria a estrutura a ser usada no Modelo de Dados
	Local oStructSC2 := FWFormStruct( 1, 'SC2', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oStructSD4 := FWFormStruct( 1, 'SD4', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oModel := MPFormModel():New('MP_PCP450A', /*bPreValidacao*/, /*{|oModel| VldOk210(oModel) }*/, /*bCommit*/, /*bCancel*/ )

	// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields( 'SC2MASTER', /*cOwner*/, oStructSC2, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )
	oModel:AddGrid( 'SD4DETAIL', 'SC2MASTER', oStructSD4, /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

	oModel:SetRelation( 'SD4DETAIL', { { 'D4_FILIAL', 'xFilial( "SD4" )' }, { 'D4_OP', 'C2_NUM+C2_ITEM+C2_SEQUEN+C2_ITEMGRD'} }, SD4->(IndexKey(1)) )
	
	oModel:GetModel( 'SC2MASTER' ):SetDescription( 'OP' ) //"Ordens de Operação"
	oModel:GetModel( 'SD4DETAIL' ):SetDescription( 'OPERS' ) //"Operações da Ordem"

Return oModel

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Funcao generica MVC do View

@return oView - Objeto da View MVC

@author Ezequiel Marques Ramos
@since 04/04/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ViewDef()
	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oModel     := FWLoadModel( 'PCP450A' )
	// Cria a estrutura a ser usada na View
	Local oStructSC2 := FWFormStruct( 2, 'SC2' )
	Local oStructSD4 := FWFormStruct( 2, 'SD4' ) 
	
	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	oView:SetModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_SC2', oStructSC2, 'SC2MASTER' )
	oView:AddGrid(  'VIEW_SD4', oStructSD4, 'SD4DETAIL' )

	// Criar um "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR', 60 )
	oView:CreateHorizontalBox( 'INFERIOR', 40 )

	// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView( 'VIEW_SC2', 'SUPERIOR' )
	oView:SetOwnerView( 'VIEW_SD4', 'INFERIOR' )
	
	oStructSD4:RemoveField("D4_OP")

Return oView
