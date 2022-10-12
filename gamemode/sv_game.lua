
GAME_ENDING = false

cvars.AddChangeCallback("unity_difficulty", function(convar, oldValue, newValue)
	convar = GetConVar(convar)
	newValue = tonumber(newValue)

	if newValue > 3 then
		convar:SetInt(3)
	elseif newValue < 1 then
		convar:SetInt(1)
	end
end)

function GM:InitPostEntity()
	for _, v in ipairs(ents.GetAll()) do
		local info = self.AmmoEntInfo[v:GetClass()]

		if info then
			local model = v:GetModel()
			local pos = v:GetPos()
			local angles = v:GetAngles()

			SafeRemoveEntity(v)

			local entity = ents.Create("unity_ammo")
			entity:SetModel(model)
			entity:SetPos(pos)
			entity:SetAngles(angles)
			entity:SetAmmoType(info.ammoType)
			entity:SetAmmoAmount(istable(info.ammoAmount) and info.ammoAmount[cvars.Number("unity_difficulty", 2)] or info.ammoAmount)
			entity:Spawn()
		end
	end
end

function GM:OnEntityCreated(entity)
	local info = self.AmmoEntInfo[entity:GetClass()]

	if info and IsValid(entity) then
		timer.Simple(0.25, function()
			local model = entity:GetModel()
			local pos = entity:GetPos()
			local angles = entity:GetAngles()
			local velocity = entity:GetVelocity()

			SafeRemoveEntity(entity)

			local entity = ents.Create("unity_ammo")
			entity:SetModel(model)
			entity:SetPos(pos)
			entity:SetAngles(angles)
			entity:SetVelocity(velocity)
			entity:SetAmmoType(info.ammoType)
			entity:SetAmmoAmount(istable(info.ammoAmount) and info.ammoAmount[cvars.Number("unity_difficulty", 2)] or info.ammoAmount)
			entity:Spawn()
		end)

	end
end

function GM:OnNPCKilled(npc, attacker, inflictor)
	if attacker:IsPlayer() then
		attacker:AddFrags(1)
	end
end

function GM:PlayerNoClip(client, desiredNoClipState)
	if (client:IsAdmin() or not desiredNoClipState) and client:Alive() then return true end

	return false
end

function GM:KeyPress(client, key)
	if not client:Alive() and client:GetMoveType() == MOVETYPE_OBSERVER then
		if key == IN_ATTACK then
			local alivePlayers = self:GetAlivePlayers()
			if #alivePlayers < 1 then return end
			local currentTarget = client:GetObserverTarget()
			local target = nil

			if IsValid(currentTarget) then
				for k, v in ipairs(alivePlayers) do
					if v == currentTarget then
						target = k == #alivePlayers and alivePlayers[1] or alivePlayers[k + 1]
					end
				end
			end

			if not IsValid(target) then
				target = alivePlayers[math.random(#alivePlayers)]
			end

			client:Spectate(OBS_MODE_CHASE)
			client:SpectateEntity(target)
		end

		if key == IN_JUMP and client:GetObserverMode() ~= OBS_MODE_ROAMING then
			client:Spectate(OBS_MODE_ROAMING)
		end
	end
end

function GM:GetAlivePlayers()
	local alivePlayers = {}

	for k, v in ipairs(player.GetAll()) do
		if IsValid(v) and v:Alive() then
			table.insert(alivePlayers, v)
		end
	end

	return alivePlayers
end

local DAMAGE_TAKE_SCALE = {
	[1] = 0.5,
	[2] = 1.0,
	[3] = 1.5
}

local DAMAGE_INFLICT_SCALE = {
	[1] = 1.5,
	[2] = 1.0,
	[3] = 0.75
}

function GM:EntityTakeDamage(target, dmgInfo)
	local attacker = dmgInfo:GetAttacker()
	local difficulty = cvars.Number("unity_difficulty", 2)

	if target:IsPlayer() and attacker:IsNPC() then
		dmgInfo:ScaleDamage(DAMAGE_TAKE_SCALE[difficulty])
	end

	if target:IsNPC() and attacker:IsPlayer() then
		dmgInfo:ScaleDamage(DAMAGE_INFLICT_SCALE[difficulty])
	end
end

function GM:GameOver()
	GAME_ENDING = true

	-- Clean up players for next game.
	for k, v in ipairs(player.GetAll()) do
		v:ScreenFade(SCREENFADE.OUT, color_black, 6, 4)
		v:ConCommand("play music/stingers/industrial_suspense" .. math.random(1, 2) .. ".wav")
		v:StripWeapons()
		v:StripAmmo()

		v.respawnTime = nil
	end

	-- Wait for the screenfade to finish before cleaning up the map and stats.
	timer.Simple(10, function()
		game.CleanUpMap(false, {})

		timer.Simple(0.2, function()
			for k, v in ipairs(player.GetAll()) do
				v:Spawn()

				-- Maybe scoreboard shouldn't reset on failure, unsure.
				-- We pause before resetting it so players can check it while
				-- waiting for the level to reset.
				v:SetDeaths(0)
				v:SetFrags(0)
			end

			GAME_ENDING = nil
		end)
	end)
end

-- Gamemode Controls
function GM:ShowHelp(client)
	client:ConCommand("unity_menu")
end

function GM:ShowTeam(client)
end

function GM:ShowSpare1(client)
	client:ConCommand("unity_dropweapon")
end

function GM:ShowSpare2(client)
	client:ConCommand("unity_dropammo")
end
