local PANEL = {}

local GM = GM or {}
local unity = unity or {}

function PANEL:CustomizationTab( parent )
	local container = vgui.Create( "DPanel", parent )
	local client = LocalPlayer()

	self.ModelPanel = vgui.Create( "DModelPanel", container )
	self.ModelPanel:SetSize( 200, 400 )
	self.ModelPanel:Dock( RIGHT )
	self.ModelPanel:SetFOV( 30 )
	self.ModelPanel:SetModel( client:GetModel() )

	function self.ModelPanel:LayoutEntity( entity )
		if ( self.bAnimated ) then
			self:RunAnimation()
		end

		entity:SetAngles(Angle(0, 45, 0))
	end

	function self.ModelPanel.Entity:GetPlayerColor()
		return client:GetPlayerColor()
	end

	local IconScrollPanel = vgui.Create( "DScrollPanel", container )
	IconScrollPanel:Dock( FILL )

	local ListPanel = IconScrollPanel:Add( "DIconLayout" )
	ListPanel:Dock( FILL  )
	ListPanel:SetSpaceY( 2 )
	ListPanel:SetSpaceX( 2 )

	local playerModels = unity.defaultPlayerModels

	if GetConVar("unity_allowcustommodels"):GetInt() > 0 then
		playerModels = player_manager.AllValidModels()
	end

	for k, v in SortedPairs(playerModels) do
		local ListItem = ListPanel:Add("SpawnIcon")

		ListItem:SetSize( 65, 65 )
		ListItem:SetModel( v )
		ListItem.OnMousePressed = function()
			client:ConCommand("unity_setplayermodel " .. v)
			self.ModelPanel:SetModel( v )
		end
	end

	return container
end

function PANEL:SettingsTab( parent )
	local container = vgui.Create( "DPanel", parent )

	local settingsScroll = vgui.Create( "DScrollPanel", container )
	settingsScroll:Dock( FILL )

	local settingsHeader = settingsScroll:Add( "DLabel" )
	settingsHeader:SetText( "Server Settings" )
	settingsHeader:SetColor(Color(0, 0, 0))
	settingsHeader:SetAutoStretchVertical( true )
	settingsHeader:SetFont("DermaLarge")
	settingsHeader:Dock( TOP )
	settingsHeader:DockMargin(10, 10, 0, 5)

	local gamemodeConvars = {
		["unity_allowcommands"] = "Enable Commands",
		["unity_allowcustommodels"] = "Enable Custom Models",
		["unity_allowautorespawn"] = "Enable Respawning",
		["unity_givegravitygun"] = "Give Gravity Gun"
	}

	for k, v in pairs(gamemodeConvars) do
		local convar = GetConVar(k)

		local convarControl = settingsScroll:Add( "DCheckBoxLabel" )
		convarControl:SetText( v )
		convarControl:SetTooltip( convar:GetHelpText() )
		convarControl:SetTextColor(Color(0, 0, 0))
		convarControl:SetConVar( k )
		convarControl:SetValue( convar:GetBool() )
		convarControl:SizeToContents()
		convarControl:Dock( TOP )
		convarControl:DockMargin(10, 0, 0, 5)
	end

	local respawnTimeConvar = GetConVar("unity_autorespawntime")

	local convarControlRTime = settingsScroll:Add( "DNumberWang" )
	convarControlRTime:Dock( TOP )
	convarControlRTime:DockMargin(10, 0, 680, 5)
	convarControlRTime:SetMin( 0 )
	convarControlRTime:SetMax( 300 )
	convarControlRTime:SetDecimals( 0 )
	convarControlRTime:SetValue( respawnTimeConvar:GetInt() )  
	convarControlRTime:SetTooltip( respawnTimeConvar:GetHelpText() )
	convarControlRTime:SetConVar( "unity_autorespawntime" )

	local convarControlRTimeText = settingsScroll:Add( "DLabel" )
	convarControlRTimeText:Dock( TOP )
	convarControlRTimeText:DockMargin(53, -25, 0, 5) --Scuffed
	convarControlRTimeText:SetText( "Respawn Waiting Time" )
	convarControlRTimeText:SetColor( Color(0, 0, 0) )

	return container
end

function PANEL:HelpTab( parent )
	local container = vgui.Create( "DPanel", parent )

	local controlsHeader = vgui.Create( "DLabel", container )
	controlsHeader:SetText( "Controls" )
	controlsHeader:SetColor(Color(0, 0, 0))
	controlsHeader:SetAutoStretchVertical( true )
	controlsHeader:SetFont("DermaLarge")
	controlsHeader:DockMargin(10, 10, 0, 5)
	controlsHeader:Dock( TOP )

	local controlsTable = {
		"F1 - Gamemode Menu",
		"F3 - Drop Weapon",
		"F4 - Drop Ammo"
	}

	for k, v in ipairs(controlsTable) do
		local control = container:Add( "DLabel" )
		control:SetFont( "DermaDefault" )
		control:SetText("• " .. v)
		control:SetColor(Color(0, 0, 0))
		control:SetAutoStretchVertical( true )
		control:SetWrap( true )
		control:SizeToContents()
		control:DockMargin(10, 0, 0, 5)
		control:Dock( TOP )
	end

	local gamemodeDetails = vgui.Create( "DLabel", container )
	gamemodeDetails:SetText( string.format("Version: %s\nGamemode by %s", GM.Version, GM.Author) )
	gamemodeDetails:SetColor(Color(0, 0, 0))
	gamemodeDetails:SetAutoStretchVertical( true )
	gamemodeDetails:SetFont("Default")
	gamemodeDetails:Dock( BOTTOM )
	
	return container
end

function PANEL:Populate()
	local container = vgui.Create( "DFrame" )
	container:SetSize( 750, 500 )
	container:Center()
	container:SetTitle( GM.Name )
	container:SetIcon("icon16/unitylogo.png")
	container:SetDraggable( true )
	container:ShowCloseButton( true )
	container:MakePopup()

	local propertySheet = vgui.Create( "DPropertySheet", container )
	propertySheet:Dock( FILL )

	propertySheet:AddSheet( "Customization", self:CustomizationTab( container ), "icon16/user.png" )
	propertySheet:AddSheet( "Help", self:HelpTab( container ), "icon16/help.png" )

	if LocalPlayer():IsAdmin() then
		propertySheet:AddSheet( "Settings", self:SettingsTab( container ), "icon16/wrench.png" )
	end
end

vgui.Register("unityMenu", PANEL, "Panel")

concommand.Add("unity_menu", function( client ) 
    if not gui.IsGameUIVisible() then
		vgui.Create("unityMenu"):Populate()
	end
end)
