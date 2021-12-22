DeriveGamemode("base")

include("shared.lua")
include("derma/cl_menu.lua")

unity = unity or {}

CreateClientConVar("unity_playermodel", unity.defaultPlayerModels[math.random(#unity.defaultPlayerModels)], true, true, "The players model.")
