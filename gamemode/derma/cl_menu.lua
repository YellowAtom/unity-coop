local PANEL = {}

local GM = GM or {}
local unity = unity or {}

function PANEL:CustomizationTab( parent )
	local container = vgui.Create( "DPanel", parent )
	local client = LocalPlayer()
	local panel = self

	self.modelPanel = vgui.Create( "DModelPanel", container )
	self.modelPanel:SetSize( 200, 400 )
	self.modelPanel:Dock( RIGHT )
	self.modelPanel:SetFOV( 30 )
	self.modelPanel:SetModel( client:GetInfo("unity_playermodel") )

	function self.modelPanel:LayoutEntity( entity )
		entity:SetSequence(entity:LookupSequence("menu_walk"))
		self:RunAnimation()

		entity:SetAngles(Angle(0, 45, 0))
		entity:SetPos(Vector(0, 0, 5))
	end

	function self.modelPanel.Entity:GetPlayerColor()
		return Vector( GetConVarString( "unity_playercolor" ) )
	end

	local IconScrollPanel = vgui.Create( "DScrollPanel", container )
	IconScrollPanel:Dock( FILL )

	local ListPanel = IconScrollPanel:Add( "DIconLayout" )
	ListPanel:Dock( FILL )
	ListPanel:SetSpaceY( 2 )
	ListPanel:SetSpaceX( 2 )

	local playerModels = unity.defaultPlayerModels

	if cvars.Bool("unity_allowcustommodels", false) then
		playerModels = player_manager.AllValidModels()
	end

	for k, v in SortedPairs(playerModels) do
		local ListItem = ListPanel:Add("SpawnIcon")

		ListItem:SetSize( 65, 65 )
		ListItem:SetModel( v )
		ListItem.OnMousePressed = function()
			client:ConCommand("unity_playermodel " .. v)
			self.modelPanel:SetModel( v )

			function self.modelPanel.Entity:GetPlayerColor()
				return Vector( GetConVarString( "unity_playercolor" ) )
			end
		end
	end

	local applyButton = vgui.Create( "DButton", container)
	applyButton:SetText( "Update Model" )
	applyButton:SetIcon( "icon16/tick.png" )
	applyButton:SetTooltip( "Changes you've made are already saved, click this to apply them before next death." )
	applyButton:Dock( BOTTOM )
	applyButton:DockMargin(3, 3, 400, 3)

	function applyButton:DoClick()
		LocalPlayer():ConCommand("unity_updatemodel")
	end

	local colorButton = vgui.Create( "DButton", container)
	colorButton:SetText( "Colour Editor" )
	colorButton:SetIcon( "icon16/color_wheel.png" )
	colorButton:SetTooltip( "Opens the colour editor for your player colour." )
	colorButton:Dock( BOTTOM )
	colorButton:DockMargin(3, 3, 400, 3)

	function colorButton:DoClick()
		PANEL:ColorEditor( parent, panel )
	end

	return container
end

function PANEL:ColorEditor( parent, panel )
	local container = vgui.Create( "DFrame", parent )
	container:SetSize( 250, 200 )
	local parentX, parentY = parent:GetPos()
	container:SetPos( parentX - 280, parentY )
	container:SetTitle( "Model Colour Editor" )
	container:SetIcon("icon16/color_wheel.png")
	container:SetDraggable( true )
	container:ShowCloseButton( true )
	container:MakePopup()

	local playerColorMixer = vgui.Create("DColorMixer", container)
	playerColorMixer:Dock( FILL )
	playerColorMixer:DockMargin(0, 0, 0, 0)
	playerColorMixer:SetAlphaBar( false )
	playerColorMixer:SetPalette( false )

	playerColorMixer:SetVector( Vector( GetConVarString( "unity_playercolor" ) ) )

	function playerColorMixer:ValueChanged()
		LocalPlayer():ConCommand("unity_playercolor " .. tostring( playerColorMixer:GetVector()))
	end

	return container
end

function PANEL:SettingsTab( parent )
	local container = vgui.Create( "DPanel", parent )

	local serverConvars = {
		["unity_enablehardcore"] = "Enable Hardcore",
		["unity_playershurtplayers"] = "Enable PvP",
		["gmod_suit"] = "Enable HEV Suit",
		["unity_allowcustommodels"] = "Enable Custom Models",
		["unity_givegravitygun"] = "Give Gravity Gun"
	}

	local settingsScroll = vgui.Create( "DScrollPanel", container )
	settingsScroll:Dock( FILL )

	if LocalPlayer():IsAdmin() then
		local settingsHeader = settingsScroll:Add( "DLabel" )
		settingsHeader:SetText( "Server Settings" )
		settingsHeader:SetColor(Color(0, 0, 0))
		settingsHeader:SetAutoStretchVertical( true )
		settingsHeader:SetFont("DermaLarge")
		settingsHeader:Dock( TOP )
		settingsHeader:DockMargin(10, 10, 0, 0)

		local helpText = settingsScroll:Add( "DLabel" )
		helpText:Dock( TOP )
		helpText:DockMargin(10, 0, 0, 5)
		helpText:SetText( "Changes take effect instantly but the menu will not update until reopened." )
		helpText:SetColor( Color(0, 0, 0) )
		helpText:SetFont( "Default" )

		local difficultyConvar = GetConVar("unity_difficulty")

		local convarControlDifficulty = settingsScroll:Add( "DNumberWang" )
		convarControlDifficulty:Dock( TOP )
		convarControlDifficulty:DockMargin(10, 0, 680, 5)
		convarControlDifficulty:SetMin( 1 )
		convarControlDifficulty:SetMax( 3 )
		convarControlDifficulty:SetDecimals( 0 )
		convarControlDifficulty:SetValue( difficultyConvar:GetInt() )  
		convarControlDifficulty:SetTooltip( difficultyConvar:GetHelpText() )
		convarControlDifficulty:SetConVar( "unity_difficulty" )

		local convarControlDifficultyText = settingsScroll:Add( "DLabel" )
		convarControlDifficultyText:Dock( TOP )
		convarControlDifficultyText:DockMargin(53, -25, 0, 5)
		convarControlDifficultyText:SetText( "Difficulty" )
		convarControlDifficultyText:SetColor( Color(0, 0, 0) )

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
		convarControlRTimeText:DockMargin(53, -25, 0, 5)
		convarControlRTimeText:SetText( "Respawn Waiting Time" )
		convarControlRTimeText:SetColor( Color(0, 0, 0) )

		for k, v in SortedPairs(serverConvars) do
			local convar = GetConVar( k )

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
	end

	return container
end

function PANEL:HelpTab( parent )
	local container = vgui.Create( "DPanel", parent )

	local featuresHeader = vgui.Create( "DLabel", container )
	featuresHeader:SetText( "Information" )
	featuresHeader:SetColor(Color(0, 0, 0))
	featuresHeader:SetAutoStretchVertical( true )
	featuresHeader:SetFont("DermaLarge")
	featuresHeader:DockMargin(10, 10, 0, 5)
	featuresHeader:Dock( TOP )

	local featuresText = vgui.Create( "DLabel", container )
	featuresText:SetText( [[
The host or an admin can adjust the difficulty of the game in settings.
Hardcore Mode means when all players are dead at the same time the level resets.
When you walk over a weapon you already own you take the ammo from it's clip but leave the weapon where it is.
You can drop the ammo of the weapon you're currently holding as well as drop the weapon itself.
You cannot pick up ammo of a weapon you don't currently have.
Movement speed and jump height match Half-Life 2 instead of Garry's Mod.
Scorebaord tracks NPC Kills and resets with the level.
All weapons have the same ammo caps as Half-Life 2.]])
	featuresText:SetColor(Color(0, 0, 0))
	featuresText:SetAutoStretchVertical( true )
	featuresText:SetFont("DermaDefault")
	featuresText:DockMargin(10, 0, 0, 5)
	featuresText:Dock( TOP )

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

	local difficultyTranslation = {
		"Easy",
		"Normal",
		"Hard"
	}

	local gamemodeDetails = vgui.Create( "DLabel", container )
	gamemodeDetails:SetText( string.format("Difficulty: %s %s\nVersion: %s\nGamemode by %s", difficultyTranslation[game.GetSkillLevel()], cvars.Bool("unity_enablehardcore", false) and "(Hardcore)" or "" , GM.Version, GM.Author) )
	gamemodeDetails:SetColor( Color(0, 0, 0) )
	gamemodeDetails:SetAutoStretchVertical( true )
	gamemodeDetails:SetFont("Default")
	gamemodeDetails:Dock( BOTTOM )
	gamemodeDetails:DockMargin(5, 0, 0, 5)
	
	return container
end

function PANEL:Populate()
	local container = vgui.Create( "DFrame" )
	container:SetSize( 750, 500 )
	container:Center()
	container:SetTitle( GM.Name )
	container:SetIcon( "icon16/unitylogo.png" )
	container:SetDraggable( true )
	container:ShowCloseButton( true )
	container:MakePopup()

	local propertySheet = vgui.Create( "DPropertySheet", container )
	propertySheet:Dock( FILL )

	propertySheet:AddSheet( "Customization", self:CustomizationTab( container ), "icon16/user.png" )
	propertySheet:AddSheet( "Settings", self:SettingsTab( container ), "icon16/wrench.png" )
	propertySheet:AddSheet( "Help", self:HelpTab( container ), "icon16/help.png" )
end

vgui.Register("unityMenu", PANEL, "Panel")

concommand.Add("unity_menu", function( client ) 
    if !gui.IsGameUIVisible() then
		vgui.Create("unityMenu"):Populate()
	end
end)
