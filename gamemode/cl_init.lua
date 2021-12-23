DeriveGamemode("base")

include("shared.lua")
include("derma/cl_menu.lua")

unity = unity or {}

CreateClientConVar("unity_playermodel", unity.defaultPlayerModels[math.random(#unity.defaultPlayerModels)], true, true, "The players model.")
CreateClientConVar("unity_playercolor", "0.24 0.34 0.41", true, true, "The players model colour.")
