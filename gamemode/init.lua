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

// Console Commands

concommand.Add("unity_setplayermodel", function( client, cmd, args, argStr )
    if IsValid(client) then
		client:SetModel( argStr )
		client:SetNWString("unitymodel", argStr)
	end
end)

concommand.Add("unity_dropweapon", function( client ) 
    local weapon = client:GetActiveWeapon()

	if ( IsValid( weapon ) ) then
		client:DropWeapon(weapon, client:GetEyeTrace().EndPos)
	end
end)

concommand.Add("unity_dropammo", function( client ) 
    local weapon = client:GetActiveWeapon()

	if ( IsValid( weapon ) ) then
		local maxClip = weapon:GetMaxClip1()
		local ammoType = weapon:GetPrimaryAmmoType()

		if client:GetAmmoCount( ammoType ) >= maxClip then
			client:RemoveAmmo( maxClip, ammoType )

			local ent = ents.Create( "item_ammo_" .. game.GetAmmoName( ammoType ) ) --Potentially exploitable if ammo clip isn't the same as an ammo box.

			if !IsValid( ent ) then return end 
			ent:SetPos( client:GetPos() + ( client:GetAimVector() * Vector(100, 0, 0) ) ) 
			ent:Spawn()
		end
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
