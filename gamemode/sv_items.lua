
GM.AmmoTypeInfo = {
	["pistol"] = { 
		class = "weapon_pistol", 
		model = "models/items/boxsrounds.mdl", 
		entity = "item_ammo_pistol" 
	},
	["smg1"] = { 
		class = "weapon_smg1", 
		model = "models/items/boxmrounds.mdl", 
		entity = "item_ammo_smg1" 
	},
	["smg1_grenade"] = { 
		class = "weapon_smg1", 
		model = "models/items/ar2_grenade.mdl", 
		entity = "item_ammo_smg1_grenade" 
	},
	["buckshot"] = { 
		class = "weapon_shotgun", 
		model = "models/items/boxbuckshot.mdl", 
		entity = "item_box_buckshot" 
	},
	["ar2"] = { 
		class = "weapon_ar2", 
		model = "models/items/combine_rifle_cartridge01.mdl", 
		entity = "item_ammo_ar2" 
	},
	["ar2altfire"] = { 
		class = "weapon_ar2", 
		model = "models/items/combine_rifle_ammo01.mdl", 
		entity = "item_ammo_ar2_altfire" 
	},
	["357"] = { 
		class = "weapon_357", 
		model = "models/items/357ammo.mdl", 
		entity = "item_ammo_357" 
	},
	["xbowbolt"] = { 
		class = "weapon_crossbow", 
		model = "models/items/crossbowrounds.mdl", 
		entity = "item_ammo_crossbow" 
	},
	["rpg_round"] = { 
		class = "weapon_rpg", 
		model = "models/weapons/w_missile_closed.mdl", 
		entity = "item_rpg_round" 
	},
	["grenade"] = { 
		class = "weapon_frag", 
		model = "models/items/grenadeammo.mdl" 
	},
	["slam"] = { 
		class = "weapon_slam", 
		model = "models/weapons/w_slam.mdl" 
	}
}

// These weapons do not work with ammo stripping.
local STRIP_AMMO_BLACKLIST = {
	["weapon_frag"] = true,
	["weapon_slam"] = true
}

function GM:PlayerCanPickupWeapon( client, weapon )
	if client.unityWeaponPickupDelay and client.unityWeaponPickupDelay > CurTime() then return false end

	local weaponClass = weapon:GetClass()

    if (client:HasWeapon(weaponClass) and !STRIP_AMMO_BLACKLIST[weaponClass]) then
		client:GiveAmmo( weapon:Clip1(), weapon:GetPrimaryAmmoType() )
		weapon:SetClip1( 0 )

		return false
	end

	return true
end

function GM:PlayerCanPickupItem( client, entity )
	if (client.unityItemPickupDelay and client.unityItemPickupDelay > CurTime()) then return false end

	local entClass = entity:GetClass()

	for k, v in pairs(self.AmmoTypeInfo) do
		if (v.entity == entClass) then
			if (!client:HasWeapon(v.class) and !STRIP_AMMO_BLACKLIST[v.class]) then
				return false
			end
		end
	end

	if (entClass == "unity_ammo") then
		local weaponClass = self.AmmoTypeInfo[entity:GetAmmoType()].class

		if (!client:HasWeapon(weaponClass) and !STRIP_AMMO_BLACKLIST[weaponClass]) then
			return false
		end
	end

	return true
end

function GM:PlayerAmmoChanged( client, ammoID, oldCount, newCount )
	local ammoCap = game.GetAmmoMax( ammoID )
	local ammoType = string.lower( game.GetAmmoName( ammoID ) or "" )
	local dif = newCount - ammoCap

	if (dif > 0) then
		local entity = client:DropAmmo( ammoType, dif )
		local physObj = entity:GetPhysicsObject()

		if IsValid( physObj ) then
			physObj:SetVelocity( client:GetAimVector() * 200 )
		end
	end
end

// Allows for extra ammo types.
function GM:AddAmmoType( ammoType, weaponClass, entityModel, ammoEntity )
	self.AmmoTypeInfo[ammoType].class = weaponClass
	self.AmmoTypeInfo[ammoType].model = entityModel
	self.AmmoTypeInfo[ammoType].entity = ammoEntity or nil
end

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

		local entity = client:DropAmmo( ammoTypeName, dropAmount )

		local physObj = entity:GetPhysicsObject()

		if IsValid( physObj ) then
			physObj:SetVelocity( client:GetAimVector() * 200 )
		end

		client.unityItemPickupDelay = CurTime() + 1.5
	end
end)
