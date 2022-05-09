GM.Name = "Unity Coop"
GM.Author = "Yell0wAt0m"
GM.Version = "β"

unity = unity or {}

unity.defaultPlayerModels = {
	"models/player/group03/male_01.mdl",
	"models/player/group03/male_02.mdl",
	"models/player/group03/male_03.mdl",
	"models/player/group03/male_04.mdl",
	"models/player/group03/male_05.mdl",
	"models/player/group03/male_05.mdl",
	"models/player/group03/male_06.mdl",
	"models/player/group03/male_07.mdl",
	"models/player/group03/male_08.mdl",
	"models/player/group03/male_09.mdl",
	"models/player/group03/female_01.mdl",
	"models/player/group03/female_02.mdl",
	"models/player/group03/female_03.mdl",
	"models/player/group03/female_04.mdl",
	"models/player/group03/female_05.mdl",
	"models/player/group03/female_06.mdl",

	"models/player/group03m/male_01.mdl",
	"models/player/group03m/male_02.mdl",
	"models/player/group03m/male_03.mdl",
	"models/player/group03m/male_04.mdl",
	"models/player/group03m/male_05.mdl",
	"models/player/group03m/male_05.mdl",
	"models/player/group03m/male_06.mdl",
	"models/player/group03m/male_07.mdl",
	"models/player/group03m/male_08.mdl",
	"models/player/group03m/male_09.mdl",
	"models/player/group03m/female_01.mdl",
	"models/player/group03m/female_02.mdl",
	"models/player/group03m/female_03.mdl",
	"models/player/group03m/female_04.mdl",
	"models/player/group03m/female_05.mdl",
	"models/player/group03m/female_06.mdl"
}

function GM:Initialize()
	if SERVER then
		local difficulty = cvars.Number("unity_difficulty", 2)

		math.Clamp( difficulty, 1, 3 )

		RunConsoleCommand("skill", difficulty)
		game.SetSkillLevel( difficulty )
	end
end

function GM:PlayerInitialSpawn( client, transition )
	if !transition then
		client:Notify( "Press F1 for gamemode menu!" )
	end
end

function GM:PlayerSpawn( client, transition )
	player_manager.OnPlayerSpawn( client, transiton )
	player_manager.RunClass( client, "Spawn" )

	if client:IsBot() then
		client:SetModel(unity.defaultPlayerModels[math.random(#unity.defaultPlayerModels)])
	else
		client:SetModel( client:GetInfo( "unity_playermodel" ) )
		client:SetPlayerColor( Vector( client:GetInfo( "unity_playercolor" )))
		client:SetupHands()
	end

	client:UnSpectate()

	// Sets all the HL2 movement values.
	client:SetSlowWalkSpeed( 150 ) // Walk Speed
	client:SetWalkSpeed( 190 ) // Norm Speed
	client:SetRunSpeed( 320 ) // Sprint Speed
	client:SetCrouchedWalkSpeed( 0.33333333 ) // Crouch Modifier from Norm Speed

	// Have to enable flashlight in base gamemode.
	client:AllowFlashlight( true )

	// This makes players non-solid only to each other, this feels like it could have unforeseen consequences though.
	client:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )

	if cvars.Bool("unity_givegravitygun", false) and !transiton then
		client:Give("weapon_physcannon")
	end
end

function unity:Announce( text )
	for _, v in ipairs(player.GetAll()) do
		v:ChatPrint( "[UNITY] " .. text )
	end
end

local playerMeta = FindMetaTable("Player")

function playerMeta:Notify( text )
	self:ChatPrint( "[UNITY] " .. text )
end

// Gamemode Controls

function GM:ShowHelp( client )
	client:ConCommand("unity_menu")
end

function GM:ShowTeam( client )
	// For future use.
end

function GM:ShowSpare1( client )
	client:ConCommand("unity_dropweapon")
end

function GM:ShowSpare2( client )
	client:ConCommand("unity_dropammo")
end

// Chat Commands

unity.command = unity.command or {}
unity.command.list = unity.command.list or {}

hook.Add("PlayerSay", "UnityCommandSay", function( sender, text, teamChat)
	if (string.sub(text, 1, 1) == "/") then
		text = string.gsub(text, "/", "")

		local postText = string.Explode(" ", text)
		local arguments = {}

		for i = 2, #postText do
			arguments[#arguments + 1] = postText[i]
		end

		local commandName = string.lower(postText[1])

		if unity.command.list[commandName] then
			local command = unity.command.list[commandName]

			if command.onCanRun( sender, arguments ) and cvars.Bool("unity_allowcommands", true) then 
				command.onRun( sender, arguments ) 
			else
				sender:Notify( "You cannot use this command!" )
			end

			return ""
		else
			sender:Notify( "Command could not be found!" )

			return ""
		end
	end
end)

function unity.command:Add( name, data )
	unity.command.list[name] = data
end

unity.command:Add("bring", {
	description = "Brings the entered player to your location.",
	onCanRun = function( client )
		return true
	end,
	onRun = function( client, arguments )
		for _, target in ipairs(player.GetAll()) do
			if target:IsPlayer() and target:Alive() and target:GetName() == arguments[1] then
				target:SetPos(client:GetPos())

				unity:Announce(string.format("%s has brought %s to their location.", client:GetName(), target:GetName()))
				return
			end
		end

		client:Notify( "Player not found!" )
	end
})
 
unity.command:Add("bringall", {
	description = "Brings all players to your location.",
	onCanRun = function ( client )
		return true
	end,
	onRun = function( client, arguments )

		for _, target in ipairs(player.GetAll()) do
			if(client != target) then
				if(target:IsPlayer() and target:Alive()) then
					target:SetPos(client:GetPos())
				end
			end
		end

		unity:Announce(string.format("%s has brought all players to their location.", client:GetName()))
	end
})
