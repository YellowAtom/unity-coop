DeriveGamemode("base")

include("shared.lua")
include("derma/cl_menu.lua")

unity = unity or {}

CreateClientConVar("unity_playermodel", unity.defaultPlayerModels[math.random(#unity.defaultPlayerModels)], true, true, "The player's static model.")
CreateClientConVar("unity_playercolor", "0.24 0.34 0.41", true, true, "The colour used by the player's model.")
CreateClientConVar("unity_vignette", "1", true, true, "Adds a vignette for atmosphere.")

local vignette = Material("materials/gui/unityvignette.png")

hook.Add( "HUDPaintBackground", "Vignette", function()
	if cvars.Bool("unity_vignette", true) then
		surface.SetDrawColor(0, 0, 0, 175)
		surface.SetMaterial(vignette)
		surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
	end
end)
