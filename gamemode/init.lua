DeriveGamemode("base")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("derma/cl_menu.lua")

include("shared.lua")

resource.AddFile("materials/icon16/unitylogo.png")

cvars.AddChangeCallback("unity_difficulty", function( convar, oldValue, newValue )
	local difficulty = cvars.Number(convar, 2)

	math.Clamp( difficulty, 1, 3 )

	RunConsoleCommand("skill", difficulty)
	game.SetSkillLevel( difficulty )
end)

unity = unity or {}

unity.ammoTypeInfo = {
	["pistol"] = { class = "weapon_pistol", model = "models/items/boxsrounds.mdl", entity = "item_ammo_pistol" },
	["smg1"] = { class = "weapon_smg1", model = "models/items/boxmrounds.mdl", entity = "item_ammo_smg1" },
	["smg1_grenade"] = { class = "weapon_smg1", model = "models/items/ar2_grenade.mdl", entity = "item_ammo_smg1_grenade" },
	["buckshot"] = { class = "weapon_shotgun", model = "models/items/boxbuckshot.mdl", entity = "item_box_buckshot" },
	["ar2"] = { class = "weapon_ar2", model = "models/items/combine_rifle_cartridge01.mdl", entity = "item_ammo_ar2" },
	["ar2altfire"] = { class = "weapon_ar2", model = "models/items/combine_rifle_ammo01.mdl", entity = "item_ammo_ar2_altfire" },
	["357"] = { class = "weapon_357", model = "models/items/357ammo.mdl", entity = "item_ammo_357" },
	["xbowbolt"] = { class = "weapon_crossbow", model = "models/items/crossbowrounds.mdl", entity = "item_ammo_crossbow" },
	["rpg_round"] = { class = "weapon_rpg", model = "models/weapons/w_missile_closed.mdl", entity = "item_rpg_round" },
	["grenade"] = { class = "weapon_frag", model = "models/items/grenadeammo.mdl" },
	["slam"] = { class = "weapon_slam", model = "models/weapons/w_slam.mdl" }
}

// These weapons do not work with ammo stripping.
unity.stripAmmoBlacklist = {
	"weapon_frag",
	"weapon_slam"
}

function GM:PlayerShouldTakeDamage( client, attacker )
	if ( attacker:IsPlayer() and client != attacker ) then
		return cvars.Bool( "unity_playershurtplayers", true )
	end

	return true
end

function GM:GetFallDamage( client, fallSpeed )
	return ( fallSpeed - 526.5 ) * ( 100 / 396 ) // The Source SDK value.
end

function GM:DoPlayerDeath( client, attacker, dmginfo )
	client:CreateRagdoll()
	client:AddDeaths( 1 )

	unity:Announce( client:GetName() .. " has died!" )

	// Attacker losses score for killing ally.
	if ( attacker:IsValid() and attacker:IsPlayer() and attacker != client ) then
		attacker:AddFrags( -5 ) 
	end

	// If all players are now dead on this death then begin failure state.
	if ( #unity:GetAlivePlayers() < 1 and cvars.Bool("unity_enablehardcore", false) ) then
		unity:GameOver()
	else
		unity:SetPlayerSpectating( client )
	end

	// Drop Weapons
	for k, v in ipairs(client:GetWeapons()) do

		// Don't drop the gravity gun if we gave it for free!
		if cvars.Bool("unity_givegravitygun", false) and v == "weapon_physcannon" then
			continue
		end

		client:DropWeapon(v, nil, client:GetVelocity())
	end

	// Drop Ammo
	for k, v in pairs(client:GetAmmo()) do
		local ammoType = string.lower(game.GetAmmoName(k) or "")

		unity:DropAmmo( client, ammoType, v )
		client:SetAmmo( 0, ammoType )
	end

	client.respawnTime = CurTime() + cvars.Number("unity_autorespawntime", 60)
end

function GM:PlayerDeathThink( client )
	if client.respawnTime and client.respawnTime < CurTime() then		
		local alivePlayers = unity:GetAlivePlayers()
		local obsTarget = client:GetObserverTarget()
		local target = IsValid(obsTarget) and obsTarget or alivePlayers[math.random(#alivePlayers)]

		client:Spawn()

		if target then 
			client:SetPos(target:GetPos())
		end
	end
end

function GM:OnNPCKilled( npc, attacker, inflictor )
	if !attacker:IsPlayer() then return end 

	attacker:AddFrags( 1 )
end

function GM:PlayerNoClip(client, desiredNoClipState)
	if ( client:IsAdmin() or !desiredNoClipState ) and client:Alive() then
		return true 
	end

	return false
end

function GM:PlayerDeathSound( client )
	local model = client:GetModel():lower()

	if (model:find("female")) then
		client:EmitSound("vo/npc/female01/pain0" .. math.random(1, 6) .. ".wav")
		return true
	elseif (model:find("male")) then
		client:EmitSound("vo/npc/male01/pain0" .. math.random(1, 6) .. ".wav")
		return true
	end

	return false
end

function GM:PlayerCanPickupWeapon( client, weapon )
	if client.unityWeaponPickupDelay and client.unityWeaponPickupDelay > CurTime() then return false end

	local weaponClass = weapon:GetClass()

	for k, v in ipairs( unity.stripAmmoBlacklist ) do
		if weaponClass == unity.stripAmmoBlacklist then
			weaponClass = nil
		end
	end

    if client:HasWeapon( weapon:GetClass() ) then
		client:GiveAmmo( weapon:Clip1(), weapon:GetPrimaryAmmoType() )
		weapon:SetClip1( 0 )

		return false
	end

	return true
end

function GM:PlayerCanPickupItem( client, entity )
	if client.unityItemPickupDelay and client.unityItemPickupDelay > CurTime() then return false end

	local entClass = entity:GetClass()
	local weaponClass = nil

	for k, v in pairs (unity.ammoTypeInfo) do
		if v.entity == entClass then
			weaponClass = v.class
		end
	end

	if ( entClass == "unity_ammo" ) then
		weaponClass = unity.ammoTypeInfo[entity:GetAmmoType()].class
	end

	if !weaponClass or !client:HasWeapon( weaponClass ) then
		return false
	end

	return true
end

function GM:PlayerAmmoChanged( client, ammoID, oldCount, newCount )
	local ammoCap = game.GetAmmoMax( ammoID )
	local ammoType = string.lower( game.GetAmmoName( ammoID ) or "" )
	local dif = newCount - ammoCap

	if dif > 0 and not client.touchingUnityAmmo then

		local entity =  unity:DropAmmo( client, ammoType, dif )

		local physObj = entity:GetPhysicsObject()

		if IsValid( physObj ) then
			physObj:SetVelocity( client:GetAimVector() * 200 )
		end

	end
end

function GM:KeyPress( client, key )
	if (client:Alive() or !client:GetMoveType() == MOVETYPE_OBSERVER) then
		return
	end

	if ( key == IN_ATTACK ) then
		local alivePlayers = unity:GetAlivePlayers()

		if #alivePlayers < 1 then return end

		local currentTarget = client:GetObserverTarget()
		local target = nil

		if IsValid( currentTarget ) then
			for k, v in ipairs( alivePlayers ) do
				if v == currentTarget then
					target = alivePlayers[k+1]
					return // TEST THIS
				end
			end
		end

		if not IsValid( target ) then
			target = alivePlayers[math.random(#alivePlayers)]
		end

		client:Spectate( OBS_MODE_CHASE )
		client:SpectateEntity( target )
	elseif ( key == IN_JUMP ) then
		if ( client:GetObserverMode() != OBS_MODE_ROAMING) then
			client:Spectate( OBS_MODE_ROAMING ) 
		end
	end
end

// Allows for extra ammo types.
function unity:AddAmmoType( ammoType, weaponClass, entityModel, ammoEntity )
	unity.ammoTypeInfo[ammoType].class = weaponClass
	unity.ammoTypeInfo[ammoType].model = entityModel
	unity.ammoTypeInfo[ammoType].entity = ammoEntity or nil
end

function unity:DropAmmo( client, ammoType, ammoAmount )
	local entity = ents.Create( "unity_ammo" )
	if !IsValid( entity ) then return end

	entity:SetAmmoAmount( ammoAmount )
	entity:SetAmmoType( ammoType )
	entity:SetModel( unity.ammoTypeInfo[ammoType].model or "models/items/boxmrounds.mdl" )

	entity:SetPos( client:GetPos() + Vector(0, 0, 50) )
	entity:SetAngles( client:GetAngles() )
	entity:Spawn()

	client:RemoveAmmo( ammoAmount, ammoType )

	return entity
end

function unity:GameOver()
	unity.gameending = true

	// Clean up players for next game.
	for k, v in ipairs(player.GetAll()) do
		v:ScreenFade( SCREENFADE.OUT, color_black, 6, 4 ) 
		v:ConCommand( "play music/stingers/industrial_suspense".. math.random(1, 2) .. ".wav" )
		v:StripWeapons()
		v:StripAmmo()

		v.respawnTime = nil
	end

	// Wait for the screenfade to finish before cleaning up the map and stats.
	timer.Simple( 10, function() 
		game.CleanUpMap( false, {} ) 

		timer.Simple( 0.2, function() 
			for k, v in ipairs(player.GetAll()) do
				v:Spawn()

				// Maybe scoreboard shouldn't reset on failure, unsure.
				// We pause before resetting it so players can check it while
				// waiting for the level to reset.
				v:SetDeaths(0)
				v:SetFrags(0)
			end 

			unity.gameending = nil
		end)
	end)
end

function unity:GetAlivePlayers()
	local alivePlayers = {}

	for k, v in ipairs(player.GetAll()) do
		if IsValid(v) and v:Alive() then
			table.insert(alivePlayers, v)
		end
	end

	return alivePlayers
end

function unity:SetPlayerSpectating( client )
	if not IsValid( client ) then return end

	timer.Simple(0.2, function() 
		local alivePlayers = unity:GetAlivePlayers()
		local target = alivePlayers[math.random(#alivePlayers)]

		if target then
			client:Spectate( OBS_MODE_CHASE )
			client:SpectateEntity( target )
		else
			client:Spectate( OBS_MODE_ROAMING ) 
		end
	end)
end

// Console Commands

// So you don't have to suicide for model updates. 
concommand.Add("unity_updatemodel", function( client, cmd, args, argStr )
    if IsValid(client) then
		client:SetModel( client:GetInfo("unity_playermodel") )
		client:SetPlayerColor( Vector(client:GetInfo("unity_playercolor")) )
		client:SetupHands()
	end
end)

concommand.Add("unity_dropweapon", function( client ) 
    local weapon = client:GetActiveWeapon()

	if ( IsValid( weapon ) ) then
		local weaponClass = weapon:GetClass()

		if cvars.Bool("unity_givegravitygun", false) and weaponClass == "weapon_physcannon" then
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

		client.unityWeaponPickupDelay = CurTime() + 1.5
	end
end)

concommand.Add("unity_dropammo", function( client, cmd, args ) 
    local weapon = client:GetActiveWeapon()

	if ( IsValid( weapon ) and weapon:GetClass() != "weapon_frag" ) then
		local ammoType = weapon:GetPrimaryAmmoType()
		local ammoTypeName = string.lower(game.GetAmmoName( ammoType ) or "")
		local ammoCount = client:GetAmmoCount( ammoType )
		local dropAmount = tonumber( args[1] )

		if not dropAmount then
			dropAmount = weapon:GetMaxClip1()
		end

		if ammoCount < dropAmount then
			dropAmount = ammoCount
		end

		if ammoCount <= 0 or dropAmount == 0 then return end

		local entity = unity:DropAmmo( client, ammoTypeName, dropAmount )

		local physObj = entity:GetPhysicsObject()

		if IsValid( physObj ) then
			physObj:SetVelocity( client:GetAimVector() * 200 )
		end

		client.unityItemPickupDelay = CurTime() + 1.5
	end
end)
