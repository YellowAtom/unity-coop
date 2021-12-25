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
	self.modelPanel:SetModel( client:GetModel() )

	function self.modelPanel:LayoutEntity( entity )
		entity:SetSequence(entity:LookupSequence("menu_walk"))
		self:RunAnimation()

		entity:SetAngles(Angle(0, 45, 0))
		entity:SetPos(Vector(0, 0, 5))
	end

	function self.modelPanel.Entity:GetPlayerColor()
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

			self.modelPanel:SetModel( v )

			function panel.modelPanel.Entity:GetPlayerColor()
				return client:GetPlayerColor()
			end
		end
	end

	local colorButton = vgui.Create( "DButton", container)
	colorButton:SetText( "Colour Editor" )
	colorButton:SetIcon( "icon16/color_wheel.png" )
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
	container:Center()
	container:SetTitle( "Colour Editor" )
	container:SetIcon("icon16/color_wheel.png")
	container:SetDraggable( true )
	container:ShowCloseButton( true )
	container:MakePopup()

	local colorPicker = vgui.Create("DRGBPicker", container)
	colorPicker:Dock( LEFT )
	colorPicker:SetSize(30, 190)

	local colorCube = vgui.Create("DColorCube", container)
	colorCube:Dock( LEFT )
	colorCube:DockMargin(5, 0, 0, 0)
	colorCube:SetSize(155, 155)

	local wangR = container:Add( "DNumberWang" )
	wangR:Dock( TOP )
	wangR:DockMargin(5, 0, 0, 3)
	wangR:SetMin( 0 )
	wangR:SetMax( 255 )
	wangR:SetDecimals( 0 )
	wangR:SetTextColor( Color(155, 0, 0) )
	wangR:HideWang()
	
	function wangR:OnValueChanged( val )
		local color = colorCube:GetRGB()
		color.r = val

		colorPicker:SetRGB( color )
		colorCube:SetColor( color )
	end

	local wangG = container:Add( "DNumberWang" )
	wangG:Dock( TOP )
	wangG:DockMargin(5, 0, 0, 3)
	wangG:SetMin( 0 )
	wangG:SetMax( 255 )
	wangG:SetDecimals( 0 )
	wangG:SetTextColor( Color(0, 155, 0) )
	wangG:HideWang()

	function wangG:OnValueChanged( val )
		local color = colorCube:GetRGB()
		color.g = val

		colorPicker:SetRGB( color )
		colorCube:SetColor( color )
	end

	local wangB = container:Add( "DNumberWang" )
	wangB:Dock( TOP )
	wangB:DockMargin(5, 0, 0, 3)
	wangB:SetMin( 0 )
	wangB:SetMax( 255 )
	wangB:SetDecimals( 0 )
	wangB:SetTextColor( Color(0, 0, 155) )
	wangB:HideWang()

	function wangB:OnValueChanged( val )
		local color = colorCube:GetRGB()
		color.b = val

		colorPicker:SetRGB( color )
		colorCube:SetColor( color )
	end

	local color = LocalPlayer():GetPlayerColor():ToColor()

	wangR:SetValue( color.r )
	wangG:SetValue( color.g )
	wangB:SetValue( color.b )

	colorPicker:SetRGB( color )
	colorCube:SetColor( color )

	function colorPicker:OnChange( color )
		local h = ColorToHSV(color)
		local _, s, v = ColorToHSV(colorCube:GetRGB())
		
		color = HSVToColor(h, s, v)
		colorCube:SetColor(color)

		wangR:SetText( color.r )
		wangG:SetText( color.g )
		wangB:SetText( color.b )
	end

	function colorCube:OnUserChanged( color ) 
		wangR:SetText( color.r )
		wangG:SetText( color.g )
		wangB:SetText( color.b )
	end

	local confirmButton = vgui.Create( "DButton", container)
	confirmButton:SetText( "Confirm" )
	confirmButton:DockMargin(5, 0, 0, 3)
	confirmButton:Dock( BOTTOM )

	function confirmButton:DoClick()
		local finalColor = colorCube:GetRGB()
		finalColor = Vector(finalColor.r / 255, finalColor.g / 255, finalColor.b / 255)

		LocalPlayer():ConCommand( "unity_setplayercolor " .. tostring(finalColor) )

		function panel.modelPanel.Entity:GetPlayerColor()
			return finalColor
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
		["unity_givegravitygun"] = "Give Gravity Gun",
		["unity_enablehardcore"] = "Enable Hardcore",
		["gmod_suit"] = "Enable HEV Suit"
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
	convarControlRTimeText:DockMargin(53, -25, 0, 5)
	convarControlRTimeText:SetText( "Respawn Waiting Time" )
	convarControlRTimeText:SetColor( Color(0, 0, 0) )

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

	local helpText = settingsScroll:Add( "DLabel" )
	helpText:Dock( TOP )
	helpText:DockMargin(10, 0, 0, 5)
	helpText:SetText( "Reopen Menu to View Changes!" )
	helpText:SetColor( Color(0, 0, 0) )
	helpText:SetFont( "Default" )

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

	local difficultyTranslation = {
		"Easy",
		"Normal",
		"Hard"
	}

	local gamemodeDetails = vgui.Create( "DLabel", container )
	gamemodeDetails:SetText( string.format("Difficulty: %s %s\nVersion: %s\nGamemode by %s", difficultyTranslation[game.GetSkillLevel()], (GetConVar("unity_enablehardcore"):GetInt() > 0) and "(Hardcore)" or "" , GM.Version, GM.Author) )
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
