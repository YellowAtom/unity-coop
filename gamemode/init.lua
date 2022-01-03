DeriveGamemode("base")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("derma/cl_menu.lua")

include("shared.lua")

resource.AddFile("materials/icon16/unitylogo.png")
resource.AddFile("materials/gui/unityvignette.png")

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
				v:SetDeaths(0)
				v:SetFrags(0)

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

	if not ( GetConVar("unity_enablehardcore"):GetInt() > 0 ) then
		GetConVar("unity_allowautorespawn"):SetInt( 1 )
	end

	if GetConVar("unity_allowautorespawn"):GetInt() > 0 then
		timer.Create("UnityRespawnTimer", GetConVar("unity_autorespawntime"):GetInt(), 1, function()
			local alivePlayers = unity.GetAlivePlayers()
			local target = alivePlayers[math.random(#alivePlayers)]

			client:UnSpectate()
			client:Spawn()

			if( target and target:IsPlayer() and target:Alive()) then
				client:SetPos(target:GetPos())
			end
		end)
	end
end

// Hooks

cvars.AddChangeCallback("unity_difficulty", function(convar, oldValue, newValue)
	local difficulty = GetConVar(convar):GetInt()

	if difficulty > 3 then
		difficulty = 3
	elseif difficulty < 1 then
		difficulty = 1
	end

	if SERVER then
		RunConsoleCommand("skill", difficulty)
		game.SetSkillLevel( difficulty )
	end
end)

hook.Add( "KeyPress", "SpectatingKeyPress", function( client, key )
	if( key == IN_ATTACK ) then
		if(!client:Alive() and client:GetMoveType() == MOVETYPE_OBSERVER) then
			local target = unity.GetNextAlivePlayer(client:GetObserverTarget())

			if not target then return end

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
		if GetConVar("unity_givegravitygun"):GetInt() > 0 and v == "weapon_physcannon" then
			continue
		end

		client:DropWeapon(v, nil, client:GetVelocity())
	end
end)

hook.Add("PlayerDeath", "UnityGameOver", function()
	if unity.CheckAllDead() and GetConVar("unity_enablehardcore"):GetInt() > 0 then
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

hook.Add("PlayerCanPickupWeapon", "unityWeaponPickupModifications", function( client, weapon )
    if client:HasWeapon( weapon:GetClass() ) then
		client:GiveAmmo(weapon:Clip1(), weapon:GetPrimaryAmmoType())
		weapon:SetClip1( 0 )

		return false
	end

	if (client.unityWeaponPickupDelay) then return false end
end)

local ammoEntityTranslation = {
	["item_ammo_pistol"] = "weapon_pistol",
	["item_ammo_smg1"] = "weapon_smg1",
	["item_box_buckshot"] = "weapon_shotgun",
	["item_ammo_ar2"] = "weapon_ar2",
	["item_ammo_357"] = "weapon_357",
	["item_ammo_crossbow"] = "weapon_crossbow",
	["item_rpg_round"] = "weapon_rpg"
}

local ammoTypeTranslation = {
	["pistol"] = "weapon_pistol",
	["smg1"] = "weapon_smg1",
	["buckshot"] = "weapon_shotgun",
	["ar2"] = "weapon_ar2",
	["357"] = "weapon_357",
	["xbowbolt"] = "weapon_crossbow",
	["rpg_round"] = "weapon_rpg"
}

hook.Add("PlayerCanPickupItem", "unityItemPickupModifications", function( client, entity )
	if (client.unityItemPickupDelay) then return false end

	local entClass = entity:GetClass()
	local weaponClass = ammoEntityTranslation[entClass]

	if entClass == "unity_ammo" then
		weaponClass = ammoTypeTranslation[entity:GetAmmoType()]
	end

	if weaponClass and not client:HasWeapon( weaponClass ) then
		return false
	end
end)

local ammoItemTranslation = {
	["pistol"] = "models/items/boxsrounds.mdl",
	["smg1"] = "models/items/boxmrounds.mdl",
	["buckshot"] = "models/items/boxbuckshot.mdl",
	["ar2"] = "models/items/combine_rifle_cartridge01.mdl",
	["357"] = "models/items/357ammo.mdl",
	["xbowbolt"] = "models/items/crossbowrounds.mdl",
	["grenade"] = "models/items/grenadeammo.mdl",
	["rpg_round"] = "models/weapons/w_missile_closed.mdl"
}

hook.Add( "PlayerAmmoChanged", "AmmoCap", function( client, ammoID, oldCount, newCount )
	local ammoCap = game.GetAmmoMax(ammoID)
	local ammoTypeName = string.lower(game.GetAmmoName(ammoID) or "")
	local dif = newCount - ammoCap

	if dif > 0 and not client.touchingUnityAmmo then
		client:SetAmmo(ammoCap, ammoTypeName)

		local entity = ents.Create( "unity_ammo" )
		if !IsValid( entity ) then return end

		client:DoAnimationEvent( ACT_GMOD_GESTURE_ITEM_DROP )
		
		entity:SetAmmoAmount( dif )
		entity:SetAmmoType( ammoTypeName )
		entity:SetModel( ammoItemTranslation[ammoTypeName] )

		entity:SetPos( client:GetPos() + Vector(0, 0, 50) )
		entity:SetAngles( client:GetAngles() )
		entity:Spawn()

		local physObj = entity:GetPhysicsObject()

		if IsValid( physObj ) then
			physObj:SetVelocity( client:GetAimVector() * 200 )
		end

	end
end)

// Console Commands

concommand.Add("unity_setplayermodel", function( client, cmd, args, argStr )
    if IsValid(client) then
		client:SetModel( argStr )
		client:ConCommand( "unity_playermodel " .. argStr )
		client:SetupHands()
	end
end)

concommand.Add("unity_setplayercolor", function( client, cmd, args, argStr )
    if IsValid(client) then
		client:SetPlayerColor( Vector(argStr) )
		client:ConCommand( "unity_playercolor " .. argStr )
	end
end)

concommand.Add("unity_dropweapon", function( client ) 
    local weapon = client:GetActiveWeapon()

	if ( IsValid( weapon ) ) then
		local weaponClass = weapon:GetClass()

		if GetConVar("unity_givegravitygun"):GetInt() > 0 and weaponClass == "weapon_physcannon" then
			return
		end

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
