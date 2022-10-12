
local playerMeta = FindMetaTable("Player")

function playerMeta:DropAmmo(ammoType, ammoAmount)
	local entity = ents.Create("unity_ammo")
	if not IsValid(entity) then return end
	entity:SetAmmoAmount(ammoAmount)
	entity:SetAmmoType(ammoType)
	entity:SetModel(GAMEMODE.AmmoTypeInfo[ammoType].model or "models/items/boxmrounds.mdl")
	entity:SetPos(self:GetPos() + Vector(0, 0, 50))
	entity:SetAngles(self:GetAngles())
	entity:Spawn()
	self:RemoveAmmo(ammoAmount, ammoType)

	return entity
end

function playerMeta:SetPlayerSpectating()
	timer.Simple(0.2, function()
		local alivePlayers = GAMEMODE:GetAlivePlayers()
		local target = alivePlayers[math.random(#alivePlayers)]

		if target then
			self:Spectate(OBS_MODE_CHASE)
			self:SpectateEntity(target)
		else
			self:Spectate(OBS_MODE_ROAMING)
		end
	end)
end

function GM:PlayerShouldTakeDamage(client, attacker)
	if attacker:IsPlayer() and client ~= attacker then
		return cvars.Bool("unity_playershurtplayers", true)
	end

	return true
end

function GM:GetFallDamage(client, fallSpeed)
	return (fallSpeed - 526.5) * (100 / 396) -- The Source SDK value.
end

function GM:PlayerInitialSpawn(client, transition)
	if not transition then
		client:ChatPrint("[UNITY] Press F1 for gamemode menu!")
	end
end

function GM:PlayerSpawn(client, transition)
	if client:IsBot() then
		client:SetModel(self.DefaultPlayerModels[math.random(#self.DefaultPlayerModels)])
	else
		client:SetModel(client:GetInfo("unity_playermodel"))
		client:SetPlayerColor(Vector(client:GetInfo("unity_playercolor")))
		client:SetupHands()
	end

	client:UnSpectate()

	-- Sets to the HL2 movement values.
	client:SetSlowWalkSpeed(150)
	client:SetWalkSpeed(190)
	client:SetRunSpeed(320)
	client:SetCrouchedWalkSpeed(0.33333333)

	-- Have to enable flashlight in base gamemode.
	client:AllowFlashlight(true)
	client:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)

	if cvars.Bool("unity_givegravitygun", false) and not transiton then
		client:Give("weapon_physcannon")
	end
end

function GM:DoPlayerDeath(client, attacker, dmginfo)
	client:CreateRagdoll()
	client:AddDeaths(1)

	for k, v in ipairs(player.GetAll()) do
		v:ChatPrint("[UNITY] " .. client:GetName() .. " has died!")
	end

	-- Attacker losses score for killing ally.
	if attacker:IsValid() and attacker:IsPlayer() and attacker ~= client then
		attacker:AddFrags(-5)
	end

	-- If all players are now dead on this death then begin failure state.
	if #self:GetAlivePlayers() < 1 and cvars.Bool("unity_enablehardcore", false) then
		self:GameOver()
	else
		client:SetPlayerSpectating()
	end

	-- Drop Weapons
	for k, v in ipairs(client:GetWeapons()) do
		-- Don't drop the gravity gun if we gave it for free!
		if cvars.Bool("unity_givegravitygun", false) and v == "weapon_physcannon" then continue end
		client:DropWeapon(v, nil, client:GetVelocity())
	end

	-- Drop Ammo
	for k, v in pairs(client:GetAmmo()) do
		local ammoType = string.lower(game.GetAmmoName(k) or "")
		client:DropAmmo(ammoType, v)
		client:SetAmmo(0, ammoType)
	end

	client.respawnTime = CurTime() + cvars.Number("unity_autorespawntime", 60)
end

function GM:PlayerDeathThink(client)
	if client.respawnTime and client.respawnTime < CurTime() then
		local alivePlayers = self:GetAlivePlayers()
		local target = alivePlayers[math.random(#alivePlayers)]
		client:Spawn()

		if target then
			client:SetPos(target:GetPos())
		end
	end
end

function GM:PlayerDeathSound(client)
	local model = client:GetModel():lower()

	if model:find("female") then
		client:EmitSound("vo/npc/female01/pain0" .. math.random(1, 6) .. ".wav")

		return true
	elseif model:find("male") then
		client:EmitSound("vo/npc/male01/pain0" .. math.random(1, 6) .. ".wav")

		return true
	end

	return false
end
