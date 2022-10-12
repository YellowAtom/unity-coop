
GM.AmmoTypeInfo = {
	["pistol"] = {
		weapon = "weapon_pistol",
		model = "models/items/boxsrounds.mdl",
		entity = "item_ammo_pistol"
	},
	["smg1"] = {
		weapon = "weapon_smg1",
		model = "models/items/boxmrounds.mdl",
		entity = "item_ammo_smg1"
	},
	["smg1_grenade"] = {
		weapon = "weapon_smg1",
		model = "models/items/ar2_grenade.mdl",
		entity = "item_ammo_smg1_grenade"
	},
	["buckshot"] = {
		weapon = "weapon_shotgun",
		model = "models/items/boxbuckshot.mdl",
		entity = "item_box_buckshot"
	},
	["ar2"] = {
		weapon = "weapon_ar2",
		model = "models/items/combine_rifle_cartridge01.mdl",
		entity = "item_ammo_ar2"
	},
	["ar2altfire"] = {
		weapon = "weapon_ar2",
		model = "models/items/combine_rifle_ammo01.mdl",
		entity = "item_ammo_ar2_altfire"
	},
	["357"] = {
		weapon = "weapon_357",
		model = "models/items/357ammo.mdl",
		entity = "item_ammo_357"
	},
	["xbowbolt"] = {
		weapon = "weapon_crossbow",
		model = "models/items/crossbowrounds.mdl",
		entity = "item_ammo_crossbow"
	},
	["rpg_round"] = {
		weapon = "weapon_rpg",
		model = "models/weapons/w_missile_closed.mdl",
		entity = "item_rpg_round"
	},
	["grenade"] = {
		weapon = "weapon_frag",
		model = "models/items/grenadeammo.mdl"
	},
	["slam"] = {
		weapon = "weapon_slam",
		model = "models/weapons/w_slam.mdl"
	}
}

GM.AmmoEntInfo = {
	["item_ammo_pistol"] = {
		model = "models/items/boxsrounds.mdl",
		ammoType = "pistol",
		ammoAmount = {
			24,
			20,
			12
		}
	},
	["item_ammo_smg1"] = {
		model = "models/items/boxmrounds.mdl",
		ammoType = "smg1",
		ammoAmount = {
			54,
			45,
			27
		}
	},
	["item_ammo_smg1_grenade"] = {
		model = "models/items/ar2_grenade.mdl",
		ammoType = "smg1_grenade",
		ammoAmount = 1
	},
	["item_box_buckshot"] = {
		model = "models/items/boxbuckshot.mdl",
		ammoType = "buckshot",
		ammoAmount = {
			24,
			20,
			12
		}
	},
	["item_ammo_ar2"] = {
		model = "models/items/combine_rifle_cartridge01.mdl",
		ammoType = "ar2",
		ammoAmount = {
			24,
			20,
			12
		}
	},
	["item_ammo_ar2_altfire"] = {
		model = "models/items/combine_rifle_ammo01.mdl",
		ammoType = "ar2altfire",
		ammoAmount = 1
	},
	["item_ammo_357"] = {
		model = "models/items/357ammo.mdl",
		ammoType = "357",
		ammoAmount = {
			7,
			6,
			3
		}
	},
	["item_ammo_crossbow"] = {
		model = "models/items/crossbowrounds.mdl",
		ammoType = "xbowbolt",
		ammoAmount = {
			7,
			6,
			3
		}
	},
	["item_rpg_round"] = {
		model = "models/weapons/w_missile_closed.mdl",
		ammoType = "weapon_rpg",
		ammoAmount = 1
	}
}

-- These weapons do not work with ammo stripping.
local STRIP_AMMO_BLACKLIST = {
	["weapon_frag"] = true,
	["weapon_slam"] = true
}

function GM:PlayerCanPickupWeapon(client, weapon)
	if client.unityWeaponPickupDelay and client.unityWeaponPickupDelay > CurTime() then return false end

	local weaponClass = weapon:GetClass()

	if client:HasWeapon(weaponClass) and not STRIP_AMMO_BLACKLIST[weaponClass] then
		client:GiveAmmo(weapon:Clip1(), weapon:GetPrimaryAmmoType())
		weapon:SetClip1(0)

		return false
	end

	return true
end

function GM:PlayerCanPickupItem(client, entity)
	if client.unityItemPickupDelay and client.unityItemPickupDelay > CurTime() then return false end

	local entClass = entity:GetClass()

	if entClass == "unity_ammo" then
		local weaponClass = self.AmmoTypeInfo[entity:GetAmmoType()].weapon

		if not client:HasWeapon(weaponClass) and not STRIP_AMMO_BLACKLIST[weaponClass] then return false end
	end

	return true
end

function GM:PlayerAmmoChanged(client, ammoID, oldCount, newCount)
	local ammoCap = game.GetAmmoMax(ammoID)
	local ammoType = string.lower(game.GetAmmoName(ammoID) or "")
	local dif = newCount - ammoCap

	if dif > 0 then
		local entity = client:DropAmmo(ammoType, dif)
		local physObj = entity:GetPhysicsObject()

		if IsValid(physObj) then
			physObj:SetVelocity(client:GetAimVector() * 200)
		end
	end
end

concommand.Add("unity_dropweapon", function(client, cmd, args, argStr)
	local weapon = client:GetActiveWeapon()

	if IsValid(weapon) then
		local weaponClass = weapon:GetClass()

		if cvars.Bool("unity_givegravitygun", false) and weaponClass == "weapon_physcannon" then return end

		local ammoType = weapon:GetPrimaryAmmoType()
		local ammoCount = client:GetAmmoCount(ammoType)

		if ammoCount > 0 then
			timer.Simple(0.1, function()
				local ammoEnt = client:DropAmmo(string.lower(game.GetAmmoName(ammoType) or ""), ammoCount)
				local ammoEntPhys = ammoEnt:GetPhysicsObject()

				if IsValid(ammoEntPhys) then
					ammoEntPhys:SetVelocity(client:GetAimVector() * 200)
				end
			end)
		end

		local entity = ents.Create(weaponClass)
		if not IsValid(entity) then return end

		client:DoAnimationEvent(ACT_GMOD_GESTURE_ITEM_DROP)
		client:StripWeapon(weaponClass)
		entity:SetPos(client:GetPos() + Vector(0, 0, 50))
		entity:Spawn()

		local physObj = entity:GetPhysicsObject()

		if IsValid(physObj) then
			physObj:SetVelocity(client:GetAimVector() * 200)
		end

		entity:SetClip1(weapon:Clip1())
		entity:SetClip2(weapon:Clip2())

		client.unityWeaponPickupDelay = CurTime() + 1.5
	end
end)

concommand.Add("unity_dropammo", function(client, cmd, args, argStr)
	local weapon = client:GetActiveWeapon()
	local bDropSecondary = (tonumber(args[1]) or 0) >= 1

	if IsValid(weapon) and weapon:GetClass() ~= "weapon_frag" then
		local ammoType = weapon:GetPrimaryAmmoType()

		if bDropSecondary then
			ammoType = weapon:GetSecondaryAmmoType()
		end

		local ammoTypeName = string.lower(game.GetAmmoName(ammoType) or "")
		local ammoCount = client:GetAmmoCount(ammoType)

		dropAmount = weapon:GetMaxClip1()

		if bDropSecondary then
			dropAmount = 1
		end

		if ammoCount < dropAmount then
			dropAmount = ammoCount
		end

		if ammoCount > 0 or dropAmount ~= 0 then
			local entity = client:DropAmmo(ammoTypeName, dropAmount)
			local physObj = entity:GetPhysicsObject()

			if IsValid(physObj) then
				physObj:SetVelocity(client:GetAimVector() * 200)
			end
		end

		client.unityItemPickupDelay = CurTime() + 1.5
	end
end)

local playerMeta = FindMetaTable("Player")

function playerMeta:DropAmmo(ammoType, ammoAmount)
	local entity = ents.Create("unity_ammo")

	if IsValid(entity) and ammoType ~= "" then
		entity:SetAmmoAmount(ammoAmount)
		entity:SetAmmoType(ammoType)
		entity:SetModel(GAMEMODE.AmmoTypeInfo[ammoType].model or "models/items/boxmrounds.mdl")
		entity:SetPos(self:GetPos() + Vector(0, 0, 50))
		entity:SetAngles(self:GetAngles())
		entity:Spawn()

		self:RemoveAmmo(ammoAmount, ammoType)
	end

	return entity
end
