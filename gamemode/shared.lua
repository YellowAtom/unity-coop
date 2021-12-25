GM.Name = "Unity Coop"
GM.Author = "Yell0wAt0m"
GM.Version = "β"

unity = unity or {}

function GM:Initialize()
	if SERVER then
		local difficulty = GetConVar("unity_difficulty"):GetInt()

		if difficulty > 3 then
			difficulty = 3
		elseif difficulty < 1 then
			difficulty = 1
		end

		RunConsoleCommand("skill", difficulty)
		game.SetSkillLevel( difficulty )
	end
end

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

function GM:PlayerSetModel(client)
	if client:IsBot() then
		client:SetModel(unity.defaultPlayerModels[math.random(#unity.defaultPlayerModels)])

		return
	end

	client:SetModel( client:GetInfo("unity_playermodel") )
	client:SetPlayerColor( Vector(client:GetInfo("unity_playercolor")) )
	client:SetupHands()
end

function GM:PlayerLoadout(client)
	client:SetWalkSpeed( 190 )
	client:SetRunSpeed( 320 )
	client:SetCrouchedWalkSpeed( 0.3333 )

	client:SetCollisionGroup( 15 )
	client:AllowFlashlight( true )

	if ( GetConVar("unity_givegravitygun"):GetInt() > 0 ) then
		client:Give("weapon_physcannon")
	end

	client:SetMoveType( MOVETYPE_WALK ) 
end

function unity.Announce( text )
	for _, v in ipairs(player.GetAll()) do
		v:ChatPrint( text )
	end
end

local playerMeta = FindMetaTable("Player")

function playerMeta:Notify( text )
	self:ChatPrint( text )
end

function GM:DrawDeathNotice( x, y )
	return
end

function GM:GetFallDamage(client, fallSpeed)
	return ( fallSpeed - 526.5 ) * ( 100 / 396 ) -- the Source SDK value
end

function GM:PlayerNoClip(client, desiredNoClipState)
	if ( client:IsAdmin() or not desiredNoClipState ) and client:Alive() then

		client:SetNoDraw( false )

		if desiredNoClipState then
			client:SetNoDraw( true )
		end

		return true 
	end

	return false
end

hook.Add("OnNPCKilled", "KillCount", function(npc, attacker, inflictor)
	if attacker:IsPlayer() then
		attacker:AddFrags( 1 )
	end
end)

hook.Add("PlayerInitialSpawn", "UnityMOTD", function(client, transition)
	if !transition then
		client:Notify( "Press F1 for the gamemode menu." )
	end
end)

function GM:PlayerDeathSound(client)
	local model = client:GetModel():lower()

	if model:find("female") or model:find("male") then
		return true
	end

	return false
end

hook.Add("PlayerDeath", "UnityDeathSounds", function(client)
	local model = client:GetModel():lower()

	if (model:find("female")) then
		client:EmitSound("vo/npc/female01/pain0" .. math.random(1, 6) .. ".wav")
	elseif (model:find("male")) then
		client:EmitSound("vo/npc/male01/pain0" .. math.random(1, 6) .. ".wav")
	end
end)

hook.Add("PlayerDeath", "UnityDeathAlert", function(client)
	unity.Announce( client:GetName() .. " has died!")
end)

hook.Add( "IsSpawnpointSuitable", "CheckSpawnPoint", function( client, spawnpointent, bMakeSuitable )
	local pos = spawnpointent:GetPos()

	-- Note that we're searching the default hull size here for a player in the way of our spawning.
	-- This seems pretty rough, seeing as our player's hull could be different.. but it should do the job.
	-- (HL2DM kills everything within a 128 unit radius)
	local entities = ents.FindInBox( pos + Vector( -16, -16, 0 ), pos + Vector( 16, 16, 72 ) )

	if ( client:Team() == TEAM_SPECTATOR or client:Team() == TEAM_UNASSIGNED ) then return true end

	local blockers = 0

	for _, v in ipairs( entities ) do
		if ( v:IsPlayer() and v:Alive() ) then
			blockers = blockers + 1

			if ( bMakeSuitable ) then
				v:Kill()
			end
		end
	end

	if ( bMakeSuitable ) then return true end
	if ( blockers > 0 ) then return false end

	return true
end)

function GM:ShowHelp(client)
	client:ConCommand("unity_menu")
end

function GM:ShowTeam(client)
	--For future use.
end

function GM:ShowSpare1(client)
	client:ConCommand("unity_dropweapon")
end

function GM:ShowSpare2(client)
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

			if command.onCanRun( sender, arguments ) and GetConVar("unity_allowcommands"):GetInt() > 0 then 
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

function unity.command.Add( name, data )
	unity.command.list[name] = data
end

unity.command.Add("bring", {
	description = "Brings the entered player to your location.",
	onCanRun = function( client )
		return true
	end,
	onRun = function( client, arguments )
		for _, target in ipairs(player.GetAll()) do
			if target:IsPlayer() and target:Alive() and target:GetName() == arguments[1] then
				target:SetPos(client:GetPos())

				unity.Announce(string.format("%s has brought %s to their location.", client:GetName(), target:GetName()))
				return
			end
		end

		client:Notify("Player not found!")
	end
})
 
unity.command.Add("bringall", {
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

		unity.Announce(string.format("%s has brought all players to their location.", client:GetName()))
	end
})
