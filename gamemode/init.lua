DeriveGamemode("base")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("derma/cl_menu.lua")

include("shared.lua")

unity = unity or {}

function unity.GameOver()
	unity.gameending = true

	for k, v in ipairs(player.GetAll()) do
		v:ScreenFade(SCREENFADE.OUT, color_black, 6, 2) 
		v:ConCommand("play music/stingers/industrial_suspense".. math.random(1, 2) .. ".wav")
		v:StripAmmo()
		v:StripWeapons()
	end

	timer.Simple( 1, function()
		timer.Remove("UnityRespawnTimer")
	end)

	timer.Simple( 8, function() 
		game.CleanUpMap( false, {} ) 

		timer.Simple( 0.2, function() 
			for k, v in ipairs(player.GetAll()) do
				v:UnSpectate()
				v:Spawn()
			end 

			unity.gameending = nil
		end)
	end)
end

function unity.CheckAllDead()
	local deadplayers = 0
	local allPlayers = player.GetAll()

	for k, v in ipairs(allPlayers) do
		if (v:IsValid() and !v:Alive()) then
			deadplayers = deadplayers + 1 
		end
	end

	if (#allPlayers == deadplayers) then
		return true
	end

	return false
end

function unity.GetAlivePlayers()
	local alivePlayers = {}

	for k, v in ipairs(player.GetAll()) do
		if IsValid(v) and v:Alive() then
			table.insert(alivePlayers, v)
		end
	end

	return alivePlayers
end

function unity.GetNextAlivePlayer(client)
	local alivePlayers = unity.GetAlivePlayers()

	if #alivePlayers < 1 then return nil end

	local previous = nil
	local choice = nil

	if IsValid(client) then
		for k, v in ipairs(alivePlayers) do
			if previous == client then
				choice = v
			end

			previous = v
		end
	end

	if not IsValid(choice) then
		choice = alivePlayers[1]
	end

	return choice
end

function unity.SetPlayerSpectating( client )
	timer.Simple(0.5, function() 
		if(client:IsValid()) then 
			client:Spectate( OBS_MODE_ROAMING ) 
		end 
	end)

	if( GetConVar("unity_allowautorespawn"):GetInt() > 0 ) then
		timer.Create("UnityRespawnTimer", GetConVar("unity_autorespawntime"):GetInt(), 1, function()
			client:UnSpectate()
			client:Spawn()

			local alivePlayers = unity.GetAlivePlayers()
			local target = alivePlayers[math.random(#alivePlayers)]

			if( target:IsPlayer() and target:Alive()) then
				client:SetPos(target:GetPos())
			end
		end)
	end
end

// Hooks

hook.Add( "KeyPress", "SpectatingKeyPress", function( client, key )
	if( key == IN_ATTACK ) then
		if(!client:Alive() and client:GetMoveType() == MOVETYPE_OBSERVER) then
			local target = unity.GetNextAlivePlayer(client:GetObserverTarget())

			if (target:IsValid() and target:Alive()) then
				client:Spectate( OBS_MODE_CHASE )
				client:SpectateEntity(target)
			end
		end
	elseif ( key == IN_JUMP ) then
		if(!client:Alive() and client:GetObserverMode() == OBS_MODE_CHASE) then
			client:Spectate( OBS_MODE_ROAMING ) 
		end
	end
end)

hook.Add("DoPlayerDeath", "DeathDropWeapons", function(client)
	if not client:IsValid() then return end

	for k, v in ipairs(client:GetWeapons()) do
		client:DropWeapon(v, nil, client:GetVelocity())
	end
end)

hook.Add("PlayerDeath", "UnityGameOver", function()
	if (unity.CheckAllDead()) then
		unity.GameOver()
	end
end)

hook.Add("PlayerDeath", "UnitySpectating", function(client) 
	if not (unity.gameending) then
		unity.SetPlayerSpectating( client )
	end
end)

hook.Add("PlayerDeathThink", "PlayerDontSpawn", function( client )
	return false
end)

hook.Add( "PlayerUse", "unityUseGesture", function( client, entity )
	if (client:IsPlayer() and client:Alive()) then
		client:DoAnimationEvent( ACT_GMOD_GESTURE_ITEM_GIVE )
	end
end)

hook.Add("PlayerCanPickupWeapon", "unityWeaponPickupModifications", function( client, weapon )
    if ( client:HasWeapon( weapon:GetClass() ) ) then
		client:GiveAmmo(weapon:Clip1(), weapon:GetPrimaryAmmoType())
		weapon:SetClip1( 0 )

		return false
	end

	if (client.unityWeaponPickupDelay) then
		return false
	end
end)

hook.Add("PlayerCanPickupItem", "unityItemPickupModifications", function( client, entity )
	if (client.unityItemPickupDelay) then
		return false
	end
end)

// Console Commands

concommand.Add("unity_setplayermodel", function( client, cmd, args, argStr )
    if IsValid(client) then
		client:SetModel( argStr )
		client:SetNWString("unitymodel", argStr)

		client:SetupHands()
	end
end)

concommand.Add("unity_dropweapon", function( client ) 
    local weapon = client:GetActiveWeapon()

	if ( IsValid( weapon ) ) then
		local weaponClass = weapon:GetClass()

		local entity = ents.Create( weaponClass )
		if !IsValid( entity ) then return end

		client:DoAnimationEvent( ACT_GMOD_GESTURE_ITEM_DROP )

		client:StripWeapon( weaponClass )

		entity:SetPos( client:GetPos() + Vector(0, 0, 50) )
		entity:Spawn()

		local physObj = entity:GetPhysicsObject()

		if IsValid( physObj ) then
			physObj:SetVelocity( client:GetAimVector() * 200 )
		end

		entity:SetClip1( weapon:Clip1() )
		entity:SetClip2( weapon:Clip2() )

		client.unityWeaponPickupDelay = true

		timer.Create("unityWeaponPickupDelay", 1.5, 1, function() 
			client.unityWeaponPickupDelay = false
		end)
	end
end)

local ammoItemTranslation = {
	["pistol"] = "models/items/boxsrounds.mdl",
	["smg1"] = "models/items/boxmrounds.mdl",
	["buckshot"] = "models/items/boxbuckshot.mdl",
	["ar2"] = "models/items/combine_rifle_cartridge01.mdl",
	["xbowbolt"] = "models/items/crossbowrounds.mdl",
	["357"] = "models/items/357ammo.mdl",
	["grenade"] = "models/items/grenadeammo.mdl",
	["rpg_round"] = "models/weapons/w_missile_closed.mdl"
}

concommand.Add("unity_dropammo", function( client ) 
    local weapon = client:GetActiveWeapon()

	if ( IsValid( weapon ) and weapon:GetClass() != "weapon_frag" ) then
		local ammoType = weapon:GetPrimaryAmmoType()
		local ammoTypeName = string.lower(game.GetAmmoName( ammoType ) or "")
		local ammoCount = client:GetAmmoCount( ammoType )
		local dropAmount = weapon:GetMaxClip1()

		if ammoCount < dropAmount then
			dropAmount = ammoCount
		end

		if ammoCount <= 0 then return end

		client:RemoveAmmo( dropAmount, ammoType )

		local entity = ents.Create( "unity_ammo" )
		if !IsValid( entity ) then return end
		
		entity:SetAmmoAmount( dropAmount )
		entity:SetAmmoType( ammoTypeName )
		entity:SetModel( ammoItemTranslation[ammoTypeName] )

		client:DoAnimationEvent( ACT_GMOD_GESTURE_ITEM_DROP )

		entity:SetPos( client:GetPos() + Vector(0, 0, 50) )
		entity:SetAngles( client:GetAngles() )
		entity:Spawn()

		local physObj = entity:GetPhysicsObject()

		if IsValid( physObj ) then
			physObj:SetVelocity( client:GetAimVector() * 200 )
		end

		client.unityItemPickupDelay = true

		timer.Create("unityItemPickupDelay", 1.5, 1, function() 
			client.unityItemPickupDelay = false
		end)
	end
end)

// Chat Commands

--[[
	TODO:
	-Make commands support arguments.
]]

unity.command = unity.command or {}

hook.Add("PlayerSay", "UnityCommandSay", function( sender, text, teamChat)

	if (string.find(text, "/")) then
		text = string.gsub(text, "/", "")

		local command = false

		if unity.command[text] then
			command = unity.command[text]

			if command.onCanRun( sender, text, teamChat ) and GetConVar("unity_allowcommands"):GetInt() > 0 then 
				command.onRun( sender, text, teamChat ) 
			else
				unity.PlayerNotify( sender, "You cannot use this command!" )
			end

			return ""
		else
			unity.PlayerNotify( sender, "Command could not be found!" )

			return ""
		end
		
	end

end)
 
unity.command["bringall"] = {
	description = "Bring all players to your location.",
	onCanRun = function ( sender )
		return true
	end,
	onRun = function( sender )

		for _, target in ipairs(player.GetAll()) do
			if(sender != target) then
				if(target:IsPlayer() and target:Alive()) then
					target:SetPos(sender:GetPos())
				end
			end
		end

		unity.Notify(string.format("%s has brought all players to their location.", sender:GetName()))
	end
}
