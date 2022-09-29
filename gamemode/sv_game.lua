
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
