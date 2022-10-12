DeriveGamemode("base")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_menu.lua")

include("shared.lua")
include("sv_player.lua")
include("sv_items.lua")
include("sv_game.lua")
include("sv_commands.lua")

resource.AddFile("materials/icon16/unitylogo.png")
