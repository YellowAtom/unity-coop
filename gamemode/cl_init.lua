DeriveGamemode("base")

include("shared.lua")
include("cl_menu.lua")

CreateClientConVar("unity_playermodel", GM.DefaultPlayerModels[math.random(#GM.DefaultPlayerModels)], true, true, "The player's static model.")
CreateClientConVar("unity_playercolor", "0.24 0.34 0.41", true, true, "The colour used by the player's model.")

function GM:DrawDeathNotice(x, y)
	return
end
