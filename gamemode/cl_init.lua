DeriveGamemode("base")

include("shared.lua")
include("cl_menu.lua")

CreateClientConVar("unity_playermodel", GM.DefaultPlayerModels[math.random(#GM.DefaultPlayerModels)], true, true, "The player's static model.")
CreateClientConVar("unity_playercolor", "0.24 0.34 0.41", true, true, "The colour used by the player's model.")

function GM:DrawDeathNotice(x, y)
	return
end

function GM:PlayerBindPress(client, bind, pressed, code)
	if bind == "gm_showhelp" then
		vgui.Create("UnityMenu")
	elseif bind == "gm_showspare1" then
		RunConsoleCommand("unity_dropweapon")
	elseif bind == "gm_showspare2" then
		RunConsoleCommand("unity_dropammo")
	end
end
